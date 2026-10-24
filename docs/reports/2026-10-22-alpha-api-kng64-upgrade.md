# Closed alpha Phase 3b: NAS API upgraded to the KNG-64 build — 2026-10-21/22

**Status:** Complete. The `knk-alpha` API runs `knk-web-api:alpha-be9f4e1a` (KNG-64 included), 82 migrations, all `knk-ops` checks pass
**Last updated:** 2026-10-22
**Linear:** [KNG-227](https://linear.app/kngpandi/issue/KNG-227) (related: [KNG-64](https://linear.app/kngpandi/issue/KNG-64), [KNG-225](https://linear.app/kngpandi/issue/KNG-225); split off: [KNG-242](https://linear.app/kngpandi/issue/KNG-242))
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 3b ·
[alpha go-live](../guides/alpha-go-live.md) § 3–4
**Build files:** [`scripts/alpha-api/`](../../scripts/alpha-api/)

The developer ran every NAS command in an SSH session and the `knk-ops` checks from the PC. Claude Code (cloud session)
wrote and reviewed each block and rehearsed the build and migration in a scratch Docker host first. No secret values
were printed or recorded. The database is still the **placeholder** copy of dev; it will be replaced by the approved seed.

## 1. Starting point (2026-10-21 18:39Z)

- API `knk-web-api:alpha-17ee730a` (ID `61c7e1f6bd45…`), user `1000:1000`, healthy; MySQL 9.6.0 healthy; both on
  `knk-alpha_backend` only, no port bindings.
- Database: 136 tables, 4 triggers, 76 migrations (latest `20261010170000_SeedStatisticsStaffNodes`), 9 users / 2 active,
  **0 holder-id clashes**. No repair needed.
- Compose `5e6d516b…` (KNG-225 with `mem_limit`), Portainer stack 42 byte-identical. By the switch on 2026-10-22 the
  KNG-225 session had changed it to `46a8ab7b…`. That file was the base for this change.

## 2. Decisions (developer)

- **Build target `be9f4e1a`** (2026-10-22): the trunk head when it was packaged. `master` had moved from `2d711557` to
  `be9f4e1a` (KNG-229 seed only). It then moved again to `3658cf2b` (KNG-232 metrics, KNG-139 seeds, KNG-195; no
  migrations). The build was not re-cut for that; the newer commits are the first routine update.
- **Continue on the placeholder DB** (2026-10-22): the one-time setup (build files, UID, configuration, procedure) is
  reused by later updates. Each later API update with migrations is ~30–45 min; replacing the DB with the approved seed is
  a separate step of about the same size either way.
- **Findings A1–A6** handled as in § 6 (2026-10-22). A3 is split off to KNG-242.

## 3. Corrections found while preparing

| Item | Docs said | Actual |
|---|---|---|
| Migrations after the upgrade | 78 | **82** on `master` ≥ `2d711557`. 78 was right only for `30c5dc5`…`07fda99e`. The run applies 6: `AddRefreshTokensAndTokenVersion`, `AddDomainWorldName`, `AddHubSettings`, `AddFormFieldSelectionLimits`, `AddFormSubmissionProgressCreatedEntities`, `LocationDeleteKeepsDomain` |
| `AllowedHosts` | `app.knightsandkings.net;api;localhost` | also needs **`127.0.0.1`**: the image health check and `knk-ops api-health` send it as Host. Without it they get 400 and the container is unhealthy |
| Email provider | `Email__Provider=Log` "already set" | `appsettings.json` defaults to `Smtp`, so it must be set |
| Log levels (A5) | lower them by configuration | `Logging__LogLevel__Microsoft.EntityFrameworkCore` as an environment variable **has no effect**: the `/bin/sh` entrypoint drops variable names that contain dots. A mounted `appsettings.Production.json` works (first start 11,160 → 64 lines) |
| Builder | — | The NAS has no buildx; the legacy builder rejects `--progress`. Builds ran with the legacy builder |

## 4. Rehearsal (scratch Docker host, 2026-10-22)

Same Dockerfile, the same base-image digests and MySQL `c5df04be…`, an empty database:
- both targets build;
- the migrator applied all 82 migrations (137 tables, 4 triggers);
- the API became healthy as `2002:2002` with `cap_drop: ALL`;
- Host `127.0.0.1`/`api`/`app.knightsandkings.net` returned 200 and `evil.example` 400;
- anonymous `/api/users`, `/api/GateStructures` and `/api/Users/1/profile-summary` returned 401;
- a restart reported zero seed creates;
- no secret value appeared in the API or migrator logs.

The only test-only change was trusting the session's proxy CA during the build.

## 5. Evidence

### Source and images

| Item | Value |
|---|---|
| Source | knk-web-api `be9f4e1a5305427136ef6917072fc68a88eef559` (2026-10-22, merge KNG-229) |
| Archive | `/home/ubuntunas/docker-backups/deployment-sources/knk-web-api/be9f4e1a/knk-web-api-be9f4e1a.tar.gz`, `git archive -c core.autocrlf=false --prefix=source/` on the PC, SHA-256 `37916e02f1919cb597b6abed5f047685378f9e26a5a2e8fee1030a169a05c66a` (same on PC and NAS) |
| Build context | `/srv/docker/build/knk-web-api/be9f4e1a/`: `Dockerfile` `80e9caeb…`, `migrator-entrypoint.sh` `eddc16ad…`, `appsettings.Production.json` `eb2cf586…`, `docker-entrypoint.sh` `e872df91…` (unchanged from Phase 3.1), `.dockerignore` from Phase 3.1; logs `build-20261022T180727Z-{runtime,migrator}.log` (`cdd7dee1…`, `be7f77cc…`) |
| Runtime image | `knk-web-api:alpha-be9f4e1a`, ID `sha256:0b47f0095495e959e146d7ccdb14e6831b069d38a88fbd6dd123c0ef03f0493c`, 259,497,389 bytes, user `2002:2002`, labels revision `be9f4e1a` and archive `37916e02…` |
| Migrator image | `knk-web-api-migrator:alpha-be9f4e1a`, ID `sha256:6e7e5246931b29ab7710a16bed072a8b1e48ad3a51f86e794e6ffb0bad37a1a9`, 1,501,982,125 bytes, dotnet-ef 9.0.10 |
| Base images | SDK `sha256:ec9c0a0d…8e80`, ASP.NET `sha256:a3cd573a…cbdf` (the Phase 3.1 pins) |

The previous image `knk-web-api:alpha-17ee730a` (`61c7e1f6bd45`) stays on the NAS as the rollback image.

### Dumps

All dumps are under `/home/ubuntunas/docker-backups/minecraft/`, root-only. Each folder has a `SHA256SUMS`.

| Dump | SHA-256 | Content |
|---|---|---|
| `alpha-db-pre-kng64/20261022T154620Z/knightsandkings_alpha-pre-kng64.sql.gz` | `6462832f3942097a70c49b2cfa1776b165feb8ee73caa4cd9c50d972a2bb8d75` | 136 tables, 4 triggers, 76 migrations; contains `GTID_PURGED` (don't restore into the same server) |
| `…/knightsandkings_alpha-pre-kng64-nogtid.sql.gz` | `5188150ad3ed82f0229b74915835c0c104180fbc9173bbc3445acb3c7469363d` | same, `--set-gtid-purged=OFF` |
| `…/knightsandkings_alpha-pre-migrate.sql.gz` | `c6cb12bae9453310815601d6f24c017c6178238e13e86924d38695108aafd547` | taken with the API stopped, just before the migrator. **Rollback source** |
| `alpha-db-clean/20261022T182711Z-kng64/knightsandkings_alpha-clean.sql.gz` | `45ddfcae3c7d8abe3029a8ea8bed646627e68b6ecb18784c2943e6678d73f65c` | **new clean baseline**: 137 tables, 4 triggers, 82 migrations; `metadata.txt` `846ead6a…` |

The 2026-10-11 baseline `alpha-db-clean/20261011-004122/` (76 migrations) is kept.

### Compose

| File | SHA-256 |
|---|---|
| Before (host = Portainer stack 42), copies in `backups/20261022T181244Z/` | `46a8ab7b68c8db81f893a68d20712782fa23590e3ad5d4aa4029828fd23d69e7` |
| After (host = Portainer stack 42, byte-identical) | `2af121b65c3d68ddecc3cf2ca443bdd2e7b728226e3604e4dd8aa5f73e4d2e7a`, canonical `a5e6e7c5…` |

The diff touches only `api`:
- image → `alpha-be9f4e1a`;
- `user: "2002:2002"`;
- `AllowedHosts`, `Security__PasswordResetFrontendBaseUrl`, `…ExposeTokenInDevelopment=false`, `Security__Registration__AllowWebFirst=false`, `Security__RefreshCookie__SameSite=Lax`, `MinecraftPlugin__BaseUrl=http://minecraft:8081`, `Email__Provider=Log`;
- the read-only mount `config/api/appsettings.Production.json`.

The block is [`scripts/alpha-api/compose.api-service.yaml`](../../scripts/alpha-api/compose.api-service.yaml).

The Portainer file was overwritten with `cp`; "Update the stack" was not used. Only `api` was recreated
(`docker compose up -d --no-deps api`), and MySQL and Minecraft kept running.
`ForwardedHeaders` stays off until nginx exists (Phase 6).

### Migration (2026-10-22 ~18:20Z)

`docker compose stop api` → pre-migrate dump → one migrator run.

The migrator ran with `--rm` on `knk-alpha_backend` with `no-new-privileges`, as root in the container. It read the
MySQL root password and JWT secret from read-only file mounts. It exited with rc 0, applied exactly the six migrations
in § 3, ended with `Done.`, and logged no fail or exception lines. The log is
`backups/20261022T181244Z/migrate-be9f4e1a.log`.

`db-summary` afterwards:
- 137 tables (new: `refresh_tokens`, 0 rows), 4 triggers;
- 82 migrations, latest `20261012091824_LocationDeleteKeepsDomain`;
- 9 users / 2 active, 0 holder-id clashes;
- all other row counts unchanged.

### Acceptance (Phase 3.3 repeated)

| Check | Result |
|---|---|
| First start | healthy after ~15 s; 64 log lines; only the four known warnings (DataProtection ×2, one EF `FirstOrDefault`, `HTTP_PORTS` override); no `PluginApiKey is not set` and no `Security:Jwt:Secret` message |
| Startup seeds | every seeder 0 creates / 0 updates / 0 normalised, on first start and after restart |
| Restart | `docker restart`: healthy again after 7 s, 0 restarts, 0 fail/crit lines |
| `containers` | API `alpha-be9f4e1a` / `0b47f009…`, user `2002:2002`, healthy, `port_bindings: {}`, `knk-alpha_backend` only, `cap_drop: ALL`, `no-new-privileges`; MySQL unchanged (started 14:22:48Z, 0 restarts) |
| `api-health` | 200 / 200, healthy |
| `db-summary` | as above |
| `secret-scan` | `clean` for all four secret names and both indicators (152 API and 35 MySQL lines scanned) |
| `log-errors` (24 h) | 0 error / critical / exception in both containers; warnings 7 (API, two starts) and 6 (MySQL) |
| `compose` | `matches_recorded: true`, `files_identical: true`, `canonical_equal: true` |
| `secret-files` | dir `root:root 700`; `jwt_secret`, `mysql_app_password`, `plugin_api_key` `2002:2002 600`; `mysql_root_password` `root:root 600`; `rcon_password` `2001:2001 600`; `missing: []`, `unexpected: []`, `all_private: true` |
| `network` | `knk-alpha_backend` internal, subnet `172.27.0.0/16`, containers `knk-alpha-api`, `knk-alpha-mysql` |

## 6. Findings A1–A6 of the [2026-10-18 report](2026-10-18-nas-ops-access-and-alpha-check.md)

| # | Result |
|---|---|
| A1 | **Resolved.** The API runs as `2002:2002` (no host account; `getent` empty). Its three secrets belong to 2002, and `mysql_root_password` to root. The admin account (UID 1000) no longer owns any alpha secret |
| A2 | **Resolved.** `/srv/docker/stacks/knk-alpha/` and `secrets/` are `root:root 700`. The admin shell needs `sudo` there (bind mounts are unaffected) |
| A3 | **Open, split off to [KNG-242](https://linear.app/kngpandi/issue/KNG-242).** `root@%` is still needed by the MySQL health check, `db-summary` (TCP `127.0.0.1`) and this migrator run |
| A4 | **Resolved.** `compose.api.pending.yaml` and `compose.mysql-only.pre-api.20261011T151034Z.yaml` were moved to `backups/20261011-archive/` |
| A5 | **Resolved.** EF Core and HttpClient log at Warning (mounted `appsettings.Production.json`); the API's own Information logs stay |
| A6 | **Resolved** (developer decision 2026-10-21): the host `compose.yaml` is authoritative and is copied to stack 42. The `knk-ops compose` wrapper records `2af121b6…`; `secret-files` expects `rcon_password` (installed hashes `bd4d6f4c…`, `1c07f8ef…`, matching `scripts/nas-ops/stage-a/SHA256SUMS`) |

## 7. Rollback (not needed)

1. Restore `backups/20261022T181244Z/compose.yaml` over the host file and the stack 42 copy.
2. `chown 1000:1000` the three API secrets.
3. Restore `knightsandkings_alpha-pre-migrate.sql.gz`.
4. `sudo docker compose up -d --no-deps api` (image `alpha-17ee730a`).

## 8. Next steps

- KNG-225 Stage 2 (KnK plugin) can start against this API. The plugin key the KNG-225 session put into `config.yml`
  is the same `plugin_api_key` the API reads.
- Next API update (routine): `master` `3658cf2b` and the developer's pending schema changes, following
  [`scripts/alpha-api/README.md`](../../scripts/alpha-api/README.md) and the steps above.
- Replace the placeholder DB with the approved seed (empty DB → migrator → seed import → first start → baseline),
  timed with the world copy (production guide § 7.4).
- [KNG-242](https://linear.app/kngpandi/issue/KNG-242): read-only check account, migrator account, restrict `root@%`.
