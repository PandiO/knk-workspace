# Dev database for cloud sessions — remote access, backups and versioned environments

**Status:** Proposal (2026-10-12), not implemented. Decisions E1-E4 (§7) need the developer.
**Last updated:** 2026-10-12
**Linear:** [KNG-163](https://linear.app/kngpandi/issue/KNG-163)
**Sources:** `docs/guides/production-installation.md` §1.2 (environments), §1.5 (NAS + Cloudflare Tunnel), §5.2-5.5
(least-privilege users, migrations, backups), §7 (seed set), §10 (CI/CD); `docs/specs/alpha-hardening/IMPLEMENTATION_PLAN.md`
§3 (D10: alpha on the NAS behind Cloudflare Tunnel + Access); the cloud session's egress proxy notes
(`/root/.ccr/README.md` in a session container).

## 1. Goal

Cloud Claude Code sessions in the **"Default Correct"** environment can run the API and its tests against a real,
shared MySQL database on the NAS, reached over the internet without opening router ports. Every database environment
is backed up on a schedule, and its schema version is known and moved forward by a pipeline, not by hand.

## 2. Constraints that shape the design

- **Cloud sessions only have HTTPS egress.** All outbound traffic goes through an HTTPS `CONNECT` proxy that
  re-terminates TLS (tools must trust the proxy CA, `/root/.ccr/ca-bundle.crt`) and enforces the environment's
  allowed domains. A raw TCP connection to MySQL port 3306 is not possible. Whatever carries MySQL must ride on HTTPS
  or WebSocket-over-HTTPS.
- **The environment's settings** decide which hosts are allowed (Network access → Allowed domains) and hold the
  secrets as environment variables. Secrets never go in a repo or a chat.
- **The NAS also holds the developer's own data** and (per D10) the alpha. Cloud agents must reach exactly one
  database and nothing else on the NAS.
- **Migrations:** the API never migrates itself on startup; EF Core migrations are applied by a separate step
  (`dotnet ef database update` or the migrator image). Migration bundles and idempotent scripts don't work on this
  codebase yet (production guide §5.3, G7).

## 3. Recommended architecture

```
cloud session (Default Correct)                         NAS (Docker)
 knk-web-api / dotnet test                               ┌──────────────────────────────┐
   │ Server=127.0.0.1;Port=13306                          │ mysql-dev (own container)     │
   ▼                                                      │   schema knk_dev_cloud        │
 cloudflared access tcp ──HTTPS/WebSocket── Cloudflare ──► cloudflared (tunnel) ──► :3306 │
   (service token from env)     via agent proxy   Access  │ Docker network "devdb" only   │
                                                (service  └──────────────────────────────┘
                                                 auth)
```

1. **A separate MySQL container `mysql-dev`** on the NAS, holding one schema, `knk_dev_cloud`. Not the developer's
   `knightsandkings_dev_v2` and not the alpha database. A separate container (rather than another schema on the same
   server) means a runaway query, a bad migration or a leaked password can't touch the other databases.
2. **A least-privilege user** `knk_cloud` with `ALL PRIVILEGES ON knk_dev_cloud.*` (migrations need DDL) and nothing
   global, `MAX_USER_CONNECTIONS 20`. Its password is a long random value stored only in the environment secrets and
   the developer's password manager.
3. **Cloudflare Tunnel** (the `cloudflared` container already planned for the alpha, or a second one on its own
   Docker network) publishes `db-dev.knightsandkings.net` as a **TCP** public hostname to `tcp://mysql-dev:3306`.
   No router ports open; the home IP stays hidden.
4. **Cloudflare Access** application on that hostname with a **Service Auth** policy only: a service token
   (Client ID + Secret), no email login, no other rule. Revoking the token cuts every session off at once. Rotate it
   every 90 days.
5. **In the cloud environment:**
   - Allowed domains: `db-dev.knightsandkings.net` (plus where the setup script downloads `cloudflared` from, e.g.
     `github.com` releases or `pkg.cloudflare.com`).
   - Environment variables: `CF_ACCESS_CLIENT_ID`, `CF_ACCESS_CLIENT_SECRET`, `KNK_DEV_DB_PASSWORD`, and
     `ConnectionStrings__MySqlDbConnection=Server=127.0.0.1;Port=13306;Database=knk_dev_cloud;User=knk_cloud;Password=…;Allow User Variables=True`
     (environment variables win over user-secrets, see knk-web-api `CLAUDE.md`).
   - Setup script: install `cloudflared`, then start the local listener in the background:
     `cloudflared access tcp --hostname db-dev.knightsandkings.net --url 127.0.0.1:13306 --service-token-id "$CF_ACCESS_CLIENT_ID" --service-token-secret "$CF_ACCESS_CLIENT_SECRET"`.
6. **Spike first** (phase 1): confirm `cloudflared access tcp` works through the agent proxy (it must honour
   `HTTPS_PROXY` and trust the proxy CA, e.g. `SSL_CERT_FILE=/root/.ccr/ca-bundle.crt`). Fallbacks if it doesn't:
   - **Tailscale** in userspace mode (`tailscaled --tun=userspace-networking`, ephemeral tagged auth key, an ACL that
     allows only `mysql-dev:3306`), if its relay traffic passes the proxy.
   - **Per-session local MySQL** restored from the latest `knk_dev_cloud` snapshot downloaded over HTTPS (an
     Access-protected bucket). No shared state, but fully isolated; useful anyway for destructive tests.

**Data rule:** `knk_dev_cloud` holds test data and the authored content (forms, menus, items), **never** real player
accounts, emails or password hashes. It is filled from a scrubbed copy of the dev DB (§5.3), not from the alpha or
production.

**Session isolation (later, optional):** chains or parallel sessions that migrate the schema can step on each other.
A per-branch schema (`knk_dev_<short-branch>`) created from the snapshot and dropped after merge avoids that; the
`knk_cloud` user would then need `CREATE` on `knk_dev\_%` instead of one schema.

## 4. Backups

Reuse the production guide's backup design (§5.5) on the NAS for **every** database there (`knightsandkings_dev_v2`,
`knk_dev_cloud`, the alpha DB):

- **Nightly logical dump** per database: `mysqldump --single-transaction --routines --triggers --events
  --set-gtid-purged=OFF`, gzip, then `gunzip -t` so a truncated file fails loudly. Run from the NAS task scheduler
  or a small cron container, as a read-only backup user (`SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES`).
- **Retention (GFS):** 7 daily, 4 weekly, 6 monthly.
- **3-2-1:** the NAS volume, plus an encrypted off-site copy (restic or Hyper Backup to Backblaze B2 / Cloudflare R2).
  Encryption matters: the dev DB may still contain personal data.
- **Before every migration** the pipeline takes an extra dump (§5).
- **Restore drill, automated monthly:** restore the latest dump into a scratch schema, check
  `__EFMigrationsHistory` and a few row counts, drop it. A backup only counts once it has been restored.
- **Alerting:** each job pings a dead-man's switch (e.g. healthchecks.io, or a Discord webhook) on success; a missing
  ping means the backup didn't run.

## 5. Versioned database environments and the pipeline

### 5.1 Environments

| Environment | Database | Who changes the schema | Data |
|---|---|---|---|
| dev-local | `knightsandkings_dev_v2` (developer's PC/NAS) | the developer, `dotnet ef database update` | test data + golden authored content |
| **dev-cloud** (new) | `knk_dev_cloud` on `mysql-dev` | the pipeline, on every merge to `master` | scrubbed copy of dev-local content |
| alpha | NAS alpha DB (D10) | the release pipeline, approved | alpha testers |
| production | later (VPS) | the release pipeline, approved | players |

### 5.2 Schema version

- The **schema version is the latest applied EF Core migration** (`__EFMigrationsHistory`). Expose it with the app
  version on the API's health endpoint so any environment can be asked what it runs, and record it in the release
  manifest (production guide §10.2).
- Migrations follow **expand, then contract** (add first, remove only a release later), so the plugin and web app
  that are still running keep working during a deploy.
- A nightly **drift check** compares each environment's last migration with `master`'s and reports differences.

### 5.3 Pipeline (GitHub Actions)

1. **CI (exists):** knk-web-api's `migrations.yml` migrates a fresh MySQL, checks the model snapshot, rolls back and
   re-applies. Keep it the gate for every PR.
2. **Deploy to dev-cloud on merge to `master`:** a **self-hosted GitHub runner on the NAS** (outbound-only, in its
   own container, only for these private repos) runs: backup → migrator image (`dotnet ef database update`) →
   smoke check (`/api/health` against `knk_dev_cloud`). Failure leaves the backup to restore and turns the run red.
3. **Reset job (manual, `workflow_dispatch`):** restore dev-cloud from a named snapshot, then migrate to head. This
   gives agents and chains a known start state.
4. **Content snapshots:** after the developer authors content in dev-local, a manual job exports the content tables
   (the seed manifest, production guide §7.2), scrubs user data, tags the snapshot with the schema version
   (`content-<date>-<migration>`), and loads it into dev-cloud. With KNG-138 (FormConfiguration export/import), forms
   can also move as files.
5. **Alpha / production:** tag-driven release workflow with a GitHub environment that has the developer as required
   reviewer (production guide §10.5); backup and migrate first, then API, web app, plugin last.

## 6. Phases

1. **Spike** (½ day): `mysql-dev` container + tunnel + Access service token; prove a cloud session connects through
   the proxy; pick the fallback if not.
2. **dev-cloud live:** least-privilege user, environment secrets, setup script, scrubbed content load; the API's
   tests and a local API run against it; a short guide in `docs/guides/`.
3. **Backups:** nightly dumps for all NAS databases, GFS retention, off-site encrypted copy, monthly restore drill,
   alerting.
4. **Pipeline:** NAS runner, deploy-on-merge to dev-cloud, reset job, drift check, schema version on the health
   endpoint.
5. **Later:** per-branch schemas for parallel sessions; content snapshot job.

## 7. Decisions for the developer

| # | Question | Proposed default |
|---|---|---|
| E1 | Separate MySQL container for dev-cloud, or a new schema on the existing dev MySQL? | Separate container |
| E2 | Hostname | `db-dev.knightsandkings.net` behind Cloudflare Access (service token only) |
| E3 | What data goes into dev-cloud? | Authored content + test data; no real accounts (scrubbed) |
| E4 | A self-hosted GitHub runner on the NAS is acceptable? | Yes, in its own container, private repos only, outbound only |
