# VPS bootstrap runbook — closed alpha on a rented server

**Status:** Draft v1 (2026-10-22) — written for review, **not yet followed**. No server has been ordered.
**Last updated:** 2026-10-22
**Linear:** [KNG-241](https://linear.app/kngpandi/issue/KNG-241) (cloud VM plan and NAS-to-VPS drill)
**Companion docs:** [pre-flight checklist](vps-preflight-checklist.md) (what you provide before the agent starts) ·
[kickoff prompt](../ai-agents/handoffs/2026-10-22-vps-bootstrap-kickoff-prompt.md) (what you paste into Claude Code on the VPS)
**Builds on:** [production installation guide](production-installation.md) (host hardening, secrets, MySQL users, seed,
backups), [closed-alpha deployment runbook](closed-alpha-deployment-runbook.md) (the NAS phases this stack mirrors),
[alpha go-live](alpha-go-live.md) (KNG-64 configuration)

The ordered plan for putting the whole closed-alpha stack (MySQL, API, web app, Paper with the KnK plugin, mail relay,
backups) on one rented server, set up by Claude Code running **on that server**, then handed back to you. Where this
runbook and an older document disagree, this one wins for the VPS; § 18 lists the older documents that need a
"superseded" note.

## 1. Decisions (developer, 2026-10-22)

| # | Decision | Notes |
|---|---|---|
| V1 | **The VPS replaces the NAS for the closed alpha.** The NAS keeps hosting the dev DB (and is the off-site backup target, § 11.1). | Supersedes plan D10 ("NAS behind Cloudflare Tunnel"). The NAS `knk-alpha` stack is stopped at go-live, not deleted. |
| V2 | **OVH VPS-4, in the EU.** Testers are exclusively in the Netherlands. | The [cost report](https://github.com/PandiO/knk-workspace/blob/claude/youthful-gauss-3pj50j/docs/reports/2026-10-22-nas-vs-vps-fallback-hosting-costs.md) lists VPS-4 as 8 vCPU / 24 GB / 200 GB NVMe, from $23.37/month, anti-DDoS included (re-check at checkout; the CPU model is not listed). Choose a Western-EU datacenter at order time (§ 3). |
| V3 | **Ingress is direct: Caddy on 80/443 with Let's Encrypt, Minecraft on 25565.** | The Cloudflare Tunnel can be added later without changing the stack (§ 19). No playit.gg. |
| V4 | **No Cloudflare Access.** Gating is the KnK account system: invited accounts, via the invitations feature. | Until the invite switch-over (§ 14) the gate is the Minecraft whitelist. |
| V5 | **Claude Code sets the server up unattended, on the VPS, then is removed.** Afterwards you operate it from your PC (Claude Code over SSH). | § 15 is the teardown. |
| V6 | **The stack is the NAS `knk-alpha` topology in Docker Compose** (service DNS, nothing but Caddy and Minecraft published), not the production guide's native nginx/systemd layout. | The plugin and API settings in alpha go-live § 4–5 assume service names (`api`, `minecraft`). |

## 2. What this stack looks like

```
Tester's browser ──HTTPS 443──► caddy ── /      → web app build (static files, read-only mount)
                                    └─ /api/* → api:5000
Minecraft client ──TCP 25565──► minecraft (Paper 26.3, main + hub worlds)

VPS, Compose project knk-alpha                       networks
  caddy                                              web      (fixed subnet; caddy + api; ForwardedHeaders trusts it)
  api  ──► mysql:3306                                backend  (internal: no internet; api, mysql, minecraft, mailrelay)
  minecraft ──► http://api:5000/api  (X-API-Key)     egress   (internet: minecraft for Mojang auth, mailrelay for Gmail)
  api ──► http://minecraft:8081  (region callbacks; never published)
  api ──► mailrelay:587 ──► smtp.gmail.com:587
  migrator  (profile "migrate", run on demand)
```

Differences from the NAS runbook, so nobody ports a step blindly:

| Topic | NAS | VPS |
|---|---|---|
| Web/API ingress | Cloudflare Tunnel + nginx + Access | **Caddy**, TLS from Let's Encrypt, real client IP straight from the connection |
| Minecraft ingress | playit.gg agent | Published `25565/tcp` on the VPS IP, A record `play.knightsandkings.net` |
| Cloudflare helper containers | `cloudflared`, `cfproxy` | **None.** Keep `CloudflareAccess__SyncEnabled=false` |
| Stack authority | Portainer stack 42 *and* a host Compose file (finding A6) | **One:** `/opt/knk-alpha/compose.yaml`, root-owned |
| Secrets | files read by an entrypoint wrapper, owned by UID 1000 (finding A1) | **Root-only env files** under `/etc/knk/`, read by Compose at container creation; the API's runtime user is the image's `app` (UID 1654), which has no host account |
| MySQL root | `root@%` (finding A3) | `MYSQL_ROOT_HOST=localhost`; app and migrator accounts separate (production guide § 5.2) |
| Admin access | LAN-only `knk-ops` forced command | Key-only SSH for `knk-admin`; the agent user `knk-agent` exists only during setup |
| API logs | ~186k lines/day (finding A5) | `Logging__LogLevel__Default=Warning`, `Microsoft.EntityFrameworkCore=Warning` from the start |

## 3. Host

- **Order:** OVH VPS-4, **Ubuntu 24.04 LTS**, a Western-EU datacenter (Gravelines or Frankfurt are the closest to NL;
  the cost report could not read OVH's region list, so pick from the order page), your SSH public key at order time,
  **monthly billing** if offered (the decision is reversible: the cost report names a Hetzner dedicated server as the
  fallback if the main thread, not contention, is the limit). Enable 2FA on the OVH account.
- **Single-core risk:** a shared vCPU can tick slower than the NAS's Ryzen 5700G. Phase V9 records `lscpu` and a
  tick-time baseline so [KNG-232 § 7](performance-metrics-and-capacity.md) can answer "is this faster than the NAS?"
  with numbers.
- **Memory budget (starting values, to be measured):**

| Component | Setting |
|---|---|
| Minecraft | `MEMORY=6G`, container limit 8G (the NAS used 4G/5G) |
| MySQL 9.6 | default buffer pool, container limit 2G |
| API | container limit 1G |
| Caddy, mailrelay | under 0.3 GB together |
| OS and page cache | the remaining ~12 GB |

Start value for view/simulation distance: **10 / 6** (the dev server's 25 / 10 was already flagged as too aggressive).

## 4. Roles and rules for the agent

- The **developer** does what only they can: the purchase, the first login, DNS records, the Gmail app password, the
  Minecraft EULA, the seed and world files, and every "go" at a hold point.
- The **agent** (`knk-agent`, passwordless sudo during setup only) does everything else, in order, without asking.
- **Stop and ask the developer** (state what, why, and your recommendation) before:
  1. publishing any port other than Caddy's 80/443 and, at go-live, Minecraft's 25565;
  2. installing software this runbook does not name;
  3. deleting a volume, backup, dump or world, or running `docker system prune` / `rm -rf` outside a scratch path;
  4. **accepting the Minecraft EULA** (the developer sets `EULA=TRUE` themselves);
  5. building from a ref other than the ones recorded in the pre-flight checklist;
  6. any action outside this host: pushing to GitHub, touching DNS, contacting the NAS, calling Cloudflare;
  7. a failed acceptance check that one reasoned fix did not repair.
- **Secrets:** generate on the host (`openssl rand`), write straight to a root-only file, never print them, never put
  them in Compose, the repo, `PROGRESS.md` or the chat. Never run `cat`, `docker inspect` or `env` in a way that
  prints one. If a value is printed by accident, record that fact (not the value) in `PROGRESS.md`.
- **Evidence:** append every phase's result to `/home/knk-agent/PROGRESS.md` (versions, image digests, source
  SHA-256s, commit SHAs, acceptance results, anything unexpected). No secrets. The developer collects it at teardown and
  files it as a dated report.
- **Work list:** anything found that is out of scope goes under "To file in Linear" in `PROGRESS.md` (the agent has no
  Linear access). Do not fix it silently.

## 5. Hold points

| Hold | Before | Why | Who says "go" |
|---|---|---|---|
| **H1** | The seed import (V8) | The importer refuses a database that has users, and the plugin creates users when anyone joins. | Developer, after delivering the seed |
| **H2** | Go-live: publishing 25565 and, if DNS is not yet pointing here, the DNS switch (V10) | From here real people can reach it. | Developer |
| **H3** | Teardown (V11) | The agent loses access for good. | Developer |

Everything before H1 runs against a **scratch database and a scratch copy of the worlds** (V6–V7), so the real
database stays empty and the order *migrations → seed → first real API start* holds.

## 6. Phase V0 — before the agent starts (developer)

Complete the [pre-flight checklist](vps-preflight-checklist.md). In short: server ordered, the DNS records created,
the seed schema version known, the world and plugin files at hand, and the access items prepared.

Then, once, from your PC, logged in as the OS user OVH created (usually `ubuntu` or `root`; do not change this to
password login):

```bash
# create the setup user for the agent, with a key that exists only for this job
sudo adduser --disabled-password --gecos "" knk-agent
echo 'knk-agent ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-knk-agent && sudo chmod 440 /etc/sudoers.d/90-knk-agent
sudo -u knk-agent mkdir -m 700 /home/knk-agent/.ssh
# paste the PUBLIC half of the agent key pair from the checklist:
echo '<ssh-ed25519 AAAA… knk-agent-setup>' | sudo -u knk-agent tee /home/knk-agent/.ssh/authorized_keys
sudo chmod 600 /home/knk-agent/.ssh/authorized_keys
```

Install Claude Code for `knk-agent` per the current instructions at <https://code.claude.com/docs/en/overview>, log in with
the flow the CLI offers (it gives a URL to open on your PC), clone this repository, start `tmux`, and paste the
[kickoff prompt](../ai-agents/handoffs/2026-10-22-vps-bootstrap-kickoff-prompt.md). **Do not use SSH agent
forwarding** (`-A`): the agent must not be able to use your personal keys.

## 7. Phase V1 — host hardening (agent)

Follow [production guide § 3.1–3.2](production-installation.md#31-base-hardening-do-this-before-anything-else), with these
changes:

1. Create `knk-admin` (the developer's permanent account) with the developer's public key from the checklist; give it
   normal sudo (a password is set by the developer later; until then, passwordless is acceptable and listed in the
   teardown).
2. SSH: key-only, no root login (`PasswordAuthentication no`, `PermitRootLogin no`, `KbdInteractiveAuthentication no`),
   `AllowUsers knk-admin knk-agent`. Test a **new** session as `knk-admin` before closing the current one.
3. `unattended-upgrades` (security only, **no automatic reboot**), `fail2ban` (sshd jail), `chrony`, timezone
   `Europe/Amsterdam`.
4. Docker Engine and the Compose plugin from Docker's official apt repository. Do **not** install the distro's
   `docker.io`, nginx, certbot or Java on the host: nothing outside containers runs the stack. (`rsync`, `jq`, `git`,
   `curl` and `mysql-client` are fine.)
5. UFW: default deny incoming, allow `OpenSSH`, `80/tcp`, `443/tcp`. **Do not rely on UFW for container ports**:
   Docker publishes ports in its own iptables chains before UFW sees the traffic
   ([production guide § 3.4](production-installation.md#34-firewall)). Exposure is controlled by what Compose publishes
   and verified from outside (V10).

Acceptance: key-only login works for `knk-admin`; password login is refused; `sudo ufw status verbose` and
`sudo ss -tlnp` match the plan; `docker run --rm hello-world` works.

## 8. Phase V2 — layout and secrets (agent)

```text
/opt/knk-alpha/           compose.yaml, compose.golive.yaml, Caddyfile, .env (non-secret refs)   root:root 755, files 644
/opt/knk-alpha/web/       releases/<ref>/ and the symlink current → releases/<ref>                 root:root 755
/etc/knk/                 api.env, migrator.env, mysql_root_password, mailrelay.env, plugin_api_key root:root 700, files 600
/srv/knk/minecraft/       data/ (live), staging/ (verified sources, read-only, the rollback)       owned by UID 10002
/srv/knk/build/           source checkouts and build contexts (disposable)                          knk-agent
/var/backups/knk/         dumps and world archives                                                  root:root 700
```

Generate (never print) `mysql_root_password`, the migrator and app database passwords, `Security__Jwt__Secret`
(`openssl rand -base64 48`), `Security__PluginApiKey` (`openssl rand -hex 32`, identical in `api.env` and the plugin's
`config.yml`) and the RCON password. The mail relay's Gmail app password is **placed by the developer** into
`/etc/knk/mailrelay.env` (checklist); the agent only checks that the file exists and is mode 600.

The API reads the root-only env files through Compose's `env_file`, so no secret-file wrapper and no UID problem
(NAS finding A1). Settings are those of [production guide § 4.3](production-installation.md#43-api-configuration-file--etcknkapienv)
as updated by [alpha go-live § 4](alpha-go-live.md#4-api-configuration-for-the-alpha), with the service-DNS values:

```ini
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:5000
AllowedHosts=app.knightsandkings.net;api;localhost
ConnectionStrings__MySqlDbConnection=Server=mysql;Port=3306;Database=knightsandkings_alpha;User=knk_alpha_app;Password=…;Allow User Variables=True;
Database__MySqlServerVersion=9.6.0
Security__AllowUnauthenticatedPluginCalls=false
Security__Registration__AllowWebFirst=false
ForwardedHeaders__Enabled=true
ForwardedHeaders__KnownNetworks=172.30.0.0/24          # the fixed `web` network subnet in compose.yaml
MinecraftPlugin__BaseUrl=http://minecraft:8081
Logging__LogLevel__Default=Warning
Logging__LogLevel__Microsoft.EntityFrameworkCore=Warning
App__PublicBaseUrl=https://app.knightsandkings.net
# mail through the relay (alpha go-live § 4); drop Email__AllowLogTransport once the relay works
Email__Transport=Smtp
Email__SmtpHost=mailrelay
Email__SmtpPort=587
Email__UseStartTls=false
Email__SmtpUsername=
Email__FromAddress=knightsandkingsmc@gmail.com
CloudflareAccess__SyncEnabled=false                    # no Cloudflare in this stack; omit the other CloudflareAccess__* keys
```

The `Email__Transport` / empty-`SmtpUsername` relay mode and the `CloudflareAccess__*` keys exist only on the
invitations feature branch (KNG-206 / KNG-216). A trunk API build ignores them but needs `Email__Provider=Log` plus `Email__AllowLogTransport=true`
or the older `Email__Provider=Smtp` settings; follow whichever matches the build recorded in the checklist.

## 9. Phase V3 — builds (agent)

Build everything **on the VPS from the pinned refs** in the checklist (record each commit SHA and base-image digest).
GitHub access is a read-only token supplied by the developer.

| Artifact | How | Notes |
|---|---|---|
| `knk-web-api:alpha-<sha>` (runtime) and `knk-web-api-migrator:alpha-<sha>` | `docker build --target runtime` / `--target migrator` from the knk-web-api checkout ([production guide § 6.1](production-installation.md#61-the-container-image)) | If the repo has no Dockerfile at that ref, use the guide's text. The runtime stage must run as a user with no host account (`USER app`, UID 1654). Pin base images by digest. |
| Web app build | a `node` container: `REACT_APP_API_BASE_URL=/api REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net CI=false npm run build` ([production guide § 8.1](production-installation.md#81-build-ci-or-your-pc)); copy to `/opt/knk-alpha/web/releases/<sha>/`, point `current` at it | Use the Node version the repo declares. |
| `knk-plugin` jar | `./gradlew build -x deployToDevServer` on **JDK 25** in a container ([ACTIVE_SESSIONS KNG-232 row](../ACTIVE_SESSIONS.md) uses the same command) | Plugin `main` must be at or after `857d4b1e` (KNG-182, Paper 26.3). Other plugin jars come from the developer's manifest (checklist), verified by SHA-256. |
| Minecraft server image | `itzg/minecraft-server`, the Java 25 tag, pinned by digest | Paper 26.3 build 205 as in the NAS runbook Phase 4. |

Acceptance: all images and the web build exist; `PROGRESS.md` lists every ref, SHA and digest.

## 10. Phase V4 — the stack up, behind Caddy (agent)

Create `/opt/knk-alpha/compose.yaml` (skeleton below; validate with `docker compose config` and adapt to the images'
real behaviour). **Unverified in the skeleton:** the `itzg/minecraft-server` Java 25 tag name, the `boky/postfix`
variable names, and the API container's healthcheck (the runtime image may lack `curl`; the NAS image defined its own).
Check each against the real image before relying on it.

```yaml
name: knk-alpha
services:
  mysql:
    image: mysql:9.6.0@sha256:<digest recorded in the 2026-10-11 progress report>
    restart: unless-stopped
    command: [--character-set-server=utf8mb4, --collation-server=utf8mb4_0900_ai_ci, --log-bin-trust-function-creators=1]
    environment: { MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password, MYSQL_ROOT_HOST: localhost }
    secrets: [mysql_root_password]
    volumes: [mysql-data:/var/lib/mysql]
    networks: [backend]
    mem_limit: 2g
    healthcheck:                       # api waits for this (root@localhost only, via the container's own loopback)
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p\"$$(cat /run/secrets/mysql_root_password)\" --silent"]
      interval: 10s
      timeout: 5s
      retries: 12
  api:
    image: knk-web-api:alpha-${API_SHA}
    restart: unless-stopped
    env_file: /etc/knk/api.env
    depends_on: { mysql: { condition: service_healthy } }
    networks: [backend, web]
    mem_limit: 1g
  migrator:
    image: knk-web-api-migrator:alpha-${API_SHA}
    profiles: [migrate]
    env_file: /etc/knk/migrator.env
    networks: [backend]
  mailrelay:
    image: boky/postfix            # pin by digest; settings per docs/guides/email.md § 3 on the invitations branch
    restart: unless-stopped
    env_file: /etc/knk/mailrelay.env
    networks: [backend, egress]
  minecraft:
    image: itzg/minecraft-server:java25@sha256:<digest>
    restart: unless-stopped
    environment: { TYPE: PAPER, VERSION: "26.3", MEMORY: 6G, ONLINE_MODE: "TRUE", ENABLE_WHITELIST: "TRUE",
                   ENFORCE_WHITELIST: "TRUE", UID: "10002", GID: "10002", ENABLE_RCON: "TRUE" }   # EULA is set by the developer
    volumes: [/srv/knk/minecraft/data:/data]
    networks: [backend, egress]          # no `ports:` here: 25565 is published by compose.golive.yaml at H2
    mem_limit: 8g
  caddy:
    image: caddy:2                       # pin by digest
    restart: unless-stopped
    ports: ["80:80", "443:443"]
    volumes: [./Caddyfile:/etc/caddy/Caddyfile:ro, ./web:/srv/web:ro, caddy-data:/data, caddy-config:/config]
    networks: [web]
networks:
  backend: { internal: true }
  egress: {}
  web: { ipam: { config: [{ subnet: 172.30.0.0/24 }] } }
secrets:
  mysql_root_password: { file: /etc/knk/mysql_root_password }
volumes: { mysql-data: {}, caddy-data: {}, caddy-config: {} }
```

`/opt/knk-alpha/Caddyfile` (the web host name comes from the checklist):

```caddyfile
{
	email <ops address from the checklist>
}
app.knightsandkings.net {
	encode zstd gzip
	header {
		Strict-Transport-Security "max-age=31536000"
		X-Content-Type-Options "nosniff"
		Referrer-Policy "strict-origin-when-cross-origin"
		-Server
	}
	handle /api/* {
		reverse_proxy api:5000
	}
	handle {
		root * /srv/web/current
		try_files {path} /index.html
		file_server
	}
}
```

`/health/*` and `/metrics` are outside `/api/*`, so Caddy never proxies them. Caddy needs the DNS A record to point at the
VPS before it can obtain a certificate.

Acceptance: `docker compose ps` healthy for MySQL; `https://app.knightsandkings.net` serves a valid Let's Encrypt
certificate and the web app shell (API calls fail until V6); `nmap` from the developer's PC (checklist) shows only 22,
80 and 443 open.

## 11. Phases V5–V7 — scratch rehearsal (agent, everything except the real data)

Goal: prove the whole stack end to end **without touching the real database or worlds**, so only the data is missing
at H1.

**V5. Scratch database.** Create `knk_rehearsal` and use a *rehearsal* copy of `api.env` pointing at it. Run the migrator
([production guide § 5.3](production-installation.md#53-apply-the-migrations)): it must finish and the migration count
must equal the build's latest migration. Start the API; `/health/live` and `/health/ready` return 200; startup is
idempotent on restart; the log has no secrets and no recurring errors.

**V6. Scratch Minecraft.** Extract the verified world packages into a **scratch copy** (`/srv/knk/minecraft/rehearsal/`),
keep `staging/` untouched. Start the server with the developer's `EULA=TRUE`, whitelist on, the plugin config from alpha
go-live § 5. Paper converts the scratch copy on first start (30 s warning, one-way: this is why the sources stay in
`staging/`). Acceptance as in runbook Phase 4: stable tick rate with both worlds, the hub intact, the plugin reaches
`http://api:5000/api`, a test account joins, restart keeps everything. The test accounts land in the scratch DB only.

**V7. Mail, web and backups.**
- Mail: `/admin/email → Send test mail to me` arrives (invitations build) or a password reset arrives (trunk build). Stop
  and restart `mailrelay` and watch the retry.
- Web: log in over HTTPS from the developer's phone on mobile data; a deliberately wrong login shows the **phone's**
  IP in the API log, not `172.30.0.x` (proves `ForwardedHeaders`).
- Backups: install the nightly MySQL dump ([production guide § 5.5](production-installation.md#55-backups--set-these-up-before-the-first-player-joins),
  adapted to the `knk-alpha` project and `knightsandkings_alpha`) and a world backup (`rcon-cli save-off`, `save-all
  flush`, archive, `save-on`) into `/var/backups/knk/`, retention 14 days. Provide the NAS pull (§ 11.1).
  **Restore rehearsal:** restore the dump into a disposable MySQL container and compare table and row counts; extract the
  world archive and check each `level.dat`. Record the result.

### 11.1 Off-site backups to the NAS

The NAS has no inbound route from the internet, so the **NAS pulls**: a cron job on the NAS runs `rsync -a` over SSH
from the VPS user `knk-backup`, whose key is restricted to a read-only `rrsync` on `/var/backups/knk` (`command="rrsync -ro
/var/backups/knk",restrict`). The agent creates the VPS side and prints the NAS cron line; the developer installs it. The
OVH VPS-4's included previous-24-hour backup is an extra, not a replacement.

## 12. Phase V8 — real database and worlds (after H1)

1. **H1: stop and ask.** The developer delivers the seed folder (`seed.sql`, `manifest.txt`) and says "go".
2. Dump nothing (the database is empty). Create the real `knightsandkings_alpha` and its users
   ([production guide § 5.2](production-installation.md#52-database-and-users--least-privilege), names `knk_alpha_migrator`
   and `knk_alpha_app`). Stop the rehearsal API; delete `knk_rehearsal`.
3. **Match the seed's schema version.** `scripts/seed/import-seed.sh` refuses a database whose latest migration differs
   from `manifest.txt: schema_version`. Run the migrator to exactly that migration
   (`dotnet ef database update <schema_version>`), import, then migrate forward to the build's latest
   ([production guide § 7.6](production-installation.md#76-import-on-the-server-once-before-the-apis-first-start)).
   For the import, temporarily add a loopback-only port (`127.0.0.1:3306`) with a Compose override, and remove it afterwards.
4. Point `api.env` at the real database, start the API, repeat the V5 acceptance, and take the **clean baseline dump**
   (record its SHA-256).
5. Delete the scratch world copy; extract a fresh live copy from `staging/` into `data/`; do not start Minecraft yet.
6. **Bootstrap the first admin** ([production guide § 6.5](production-installation.md#65-bootstrap-the-first-admin)) is
   done at go-live with the developer's real Minecraft account, not by the agent.

## 13. Phase V9 — baselines (agent)

Record in `PROGRESS.md`: `lscpu`, `nproc`, `free -h`, `docker stats --no-stream` with the stack idle, Paper's tick time
and TPS with one player (from `/mspt` or the metrics once KNG-232 is merged), and the first `knk_cgroup_*`/`docker stats`
sample per [KNG-232 § 2](performance-metrics-and-capacity.md). If KNG-232's metrics are not on the built refs, say so.
This is the baseline for the "is the VPS faster than the NAS?" comparison.

## 14. Phase V10 — go-live (H2) and the invite switch-over

1. **H2: stop and ask.** The developer says "go".
2. Add `compose.golive.yaml` (publishes `25565:25565` for `minecraft`) and recreate only that service. DNS: A
   `play.knightsandkings.net` → the VPS IP (the developer's step; the agent prints the exact record). Stop and disable
   the NAS `knk-alpha` stack so two alphas never run side by side (the developer's step on the NAS; the data stays as a
   rollback).
3. From the developer's PC: `nmap -p 22,80,443,3306,5000,8081,25565,25575 <vps-ip>` shows **only 22, 80, 443 and 25565
   open**. Run [`scripts/security/alpha-probe.sh`](../../scripts/security/alpha-probe.sh) against the public URL
   ([alpha go-live § 8](alpha-go-live.md#8-security-probe)) and the [hardening smoke test](alpha-hardening-smoke-test.md).
4. The developer joins as their real account, runs `/account link`, registers on the web app, and the agent grants the
   first admin as in the production guide § 6.5 (from the server, key never leaves it).
5. **Invite switch-over** (invitations feature branch, [alpha go-live § 11.1 on that branch](https://github.com/PandiO/knk-workspace/blob/claude/player-signup-invitation-flow-f4v7ul/docs/guides/alpha-go-live.md)),
   **without step 2** (no Cloudflare list, policy, token, bypass application or `cfproxy`):
   (1) deploy behaviour-neutral, check the mail block; (3) `Security__Registration__Mode=Invite`, invite a test
   address, sign up; (4) plugin `admission.mode: invite`, restart, then whitelist off; (5) the smoke-test sections marked
   "alpha". Without Access there is no PIN step in the tester's journey: check the sign-up pages do not mention one
   (see the open items).
6. Run the teardown (§ 15, hold **H3**) and **only then** send the first tester invites, so no tester joins a server on
   which the setup agent still has sudo.

## 15. Phase V11 — teardown and handover (H3)

Developer, after the agent reports done and says H3 is next:

1. Collect `/home/knk-agent/PROGRESS.md` (`scp`), read it, and file it as `docs/reports/2026-MM-DD-vps-bootstrap.md`.
2. Confirm you can log in as `knk-admin` from your PC and run `sudo` there.
3. Remove the agent: `claude logout`, then delete the user with its home (`sudo deluser --remove-home knk-agent`), delete
   `/etc/sudoers.d/90-knk-agent`, remove its key from any `authorized_keys`, delete `/srv/knk/build/`. Revoke the Claude
   session from your Claude account's settings.
4. Revoke the GitHub token. Revoke and re-create the Gmail app password (update `/etc/knk/mailrelay.env`, restart the
   relay). Rotate any secret `PROGRESS.md` says was printed.
5. Re-run the nmap check and `sudo ss -tlnp`; confirm nothing else listens.
6. From then on: Claude Code on **your PC** over SSH as `knk-admin`, in Manual permission mode, as with the NAS.

## 16. Deploying a new build (manual, until CI exists)

Same order as the NAS runbook: **back up → migrator → API → web app → plugin**, one component at a time, with the
health checks after each. Build from the pinned ref on the VPS, tag `alpha-<sha>`, change `API_SHA` in `/opt/knk-alpha/.env`,
`docker compose up -d api`. Roll back by setting the previous tag; restore the baseline dump if a migration ran.
Per-branch deploys for testing belong to the CI work in [alpha go-live § 12](alpha-go-live.md) ("CI-built images").

## 17. Closed-alpha findings this design resolves

| NAS finding | VPS resolution |
|---|---|
| A1 secrets owned by the API's runtime UID | Root-only env files; runtime user has no host account |
| A2 stack directory owned by the admin account | `/opt/knk-alpha/` is root-owned |
| A3 `root@%` | `MYSQL_ROOT_HOST=localhost`, separate migrator/app accounts |
| A4 leftover pending Compose file | One Compose file; `compose.golive.yaml` is its only sibling |
| A5 log volume | Warning-level logging from the start |
| A6 Portainer vs host Compose | No Portainer |

## 18. Documents that need a "superseded" note

This branch does not edit them, because the invitations branch changes the same files (merge conflicts). After that
branch merges, add a one-paragraph note to: the alpha-hardening plan (D10 and § 3), [alpha go-live](alpha-go-live.md)
(§ 1 diagram, § 6, § 12), the [closed-alpha runbook](closed-alpha-deployment-runbook.md) header,
[production installation § 1.5](production-installation.md), and `docs/FEATURE_REGISTER.md` if it records the hosting.
Tracked in [KNG-241](https://linear.app/kngpandi/issue/KNG-241).

## 19. Open items

- Whether the API applies its migrations to an empty database on startup is unverified; the runbook uses the migrator.
- The `Dockerfile` that built `knk-web-api:alpha-17ee730a` lives only in the NAS build context; V3 uses the repo's or the
  production guide's. If the repo has none, that is a gap to file.
- The invitation sign-up pages may still mention a Cloudflare PIN when `CloudflareAccess__SyncEnabled=false`
  (unverified; the branch's smoke test line "the sign-up's done page says Cloudflare…" is conditional on the sync).
  If a page misleads testers, file it.
- Adding the Cloudflare Tunnel later: run `cloudflared` on the `web` network pointing at `caddy:80`, stop publishing
  80/443, and change `ForwardedHeaders` so the real client IP is taken from `CF-Connecting-IP` as in alpha go-live § 6.
  Do this deliberately, not as part of the weekend setup.
- Mail still leaves through Gmail (decision E1/E2 in the invitations plan); a domain mail provider is a pre-beta task.
- Whether OVH's VPS network allows outbound 587 is unverified; the relay needs it.
- Re-check prices, regions and CPU on the OVH order page; the cost report is a vendor "from" price snapshot.
