# Knights and Kings — production installation guide (admin)

**Status:** Draft v1 — written for review. Not yet followed on a real production host. The database, API, seed and
web-server steps were rehearsed in a scratch environment on 2026-10-07 (see [Appendix A](#appendix-a--what-was-verified-and-how)).
The Paper server steps and the CI/CD workflows are untested drafts.
**Last updated:** 2026-10-08 (security and alpha-hosting update for KNG-64)
**Applies to:** trunk only. knk-web-api `master` `1805cf9`, knk-web-app `main`, knk-plugin `main` `c7d5a1e`; 61 EF
migrations, the latest being `20261006193103_UniquePermissionGrantHolderNode`. Feature branches that haven't been
merged, such as road navigation, are not covered. Re-check § 2 and the seed table manifest after each trunk merge.
**Sources:** the three repos' code at those commits (file references inline); `docs/specs/*/…_FORMCONFIGS.md` for the
dev-DB-only content; [`scripts/seed/`](../../scripts/seed/) for the seed tooling.

This guide does two jobs. It is a **runbook**: commands in order, ending in a [first-run checklist](#11-first-run-checklist).
It is also a **primer**: each step says *why* it is done that way, because the goal is to learn how production
environments are set up in general. Boxes marked **Concept** explain the general idea. Boxes marked **KnK** explain
what is specific to this project.

> **Update 2026-10-08 — KNG-64 (closed alpha hardening).** The [KNG-63 assessment](../reports/2026-10-08-web-app-ux-assessment.md)
> found the API mostly unauthenticated (anonymous writes, public user list with emails, self-escalation, unrevocable
> sessions). The fixes are on branch `claude/ui-ux-assessment-discussion-66vc2l` in all three code repos and follow the
> [alpha hardening plan](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md). Steps marked **[KNG-64]** describe behaviour
> **after that merge**; don't expose an API built from an older commit. For the **closed alpha on the NAS behind
> Cloudflare Tunnel**, follow [alpha-go-live.md](alpha-go-live.md). This guide stays the reference for a public VPS
> (open beta and later).

---

## Contents

1. [The production picture](#1-the-production-picture)
2. [Code changes to make before go-live](#2-code-changes-to-make-before-go-live)
3. [Prepare the host](#3-prepare-the-host)
4. [Configuration and secrets](#4-configuration-and-secrets)
5. [Database (MySQL)](#5-database-mysql)
6. [API (knk-web-api)](#6-api-knk-web-api)
7. [Seed data: preparing and loading the content set](#7-seed-data-preparing-and-loading-the-content-set)
8. [Web app and the public web server](#8-web-app-and-the-public-web-server)
9. [Minecraft server (Paper + knk-plugin)](#9-minecraft-server-paper--knk-plugin)
10. [CI/CD plan](#10-cicd-plan)
11. [First-run checklist](#11-first-run-checklist)
12. [Day-2 operations](#12-day-2-operations)
- [Appendix A — what was verified and how](#appendix-a--what-was-verified-and-how)
- [Appendix B — reference files](#appendix-b--reference-files)

---

## 1. The production picture

### 1.1 Components and how they talk

```
                         Internet
       ┌───────────────────┴─────────────────────────┐
       │ HTTPS 443 (play.example.com)                │ TCP 25565 (mc.example.com)
       ▼                                             ▼
┌────────────────────┐                     ┌──────────────────────────┐
│ nginx (host)       │                     │ Paper 1.21.10 (systemd)  │
│  /      → web app  │                     │  + WorldEdit, WorldGuard │
│  /api/  → API      │                     │  + KnightsAndKings jar   │
└───────┬────────────┘                     └───┬──────────────▲───────┘
        │ http 127.0.0.1:5000                  │ REST + X-API-Key   │ http 127.0.0.1:8081
        ▼                                      ▼                    │ (region checks)
┌──────────────────────────────────────────────────────────────────┴───┐
│ knk-web-api (Docker, host network, listens on 127.0.0.1:5000)        │
└───────┬──────────────────────────────────────────────────────────────┘
        │ MySQL protocol 127.0.0.1:3306
        ▼
┌────────────────────┐
│ MySQL 8.4 (Docker) │   volume db-data   → nightly dump → off-site copy
└────────────────────┘
```

| From → to | How | Auth | Where it's configured |
|---|---|---|---|
| Browser → web app | HTTPS, static files | none | nginx |
| Browser → API | HTTPS `/api/...` (same origin) | JWT bearer + httpOnly refresh cookie | web app `src/config/appConfig.ts:11`; API `Security:Jwt:*` |
| Plugin → API | HTTP on loopback | `X-API-Key` = `Security:PluginApiKey` | plugin `api.*` in `config.yml`; API env |
| API → plugin | HTTP `127.0.0.1:8081` (`RegionHttpServer`) | **none** today (G6); `X-API-Key` and a loopback bind **[KNG-64]** | API `MinecraftPlugin:BaseUrl`; plugin `region-http.port` |
| API → MySQL | TCP loopback | DB user `knk_app` | `ConnectionStrings:MySqlDbConnection` |
| Players → Paper | TCP 25565 | Mojang (`online-mode=true`) | `server.properties` |

> **Concept — the same origin.** If the browser loads the web app from `https://play.example.com` and calls the API
> on the same host under `/api`, it treats both as one *origin*. Then there is no CORS to configure, and the refresh
> cookie is "first-party". Putting the API on a separate domain (`api.example.com`) is also common, but it needs
> CORS configuration and cross-site cookies. Here, CORS is hard-coded to localhost (§ 2), so same-origin is the
> simpler choice.

### 1.2 Environments

| Environment | Where | Purpose | Data |
|---|---|---|---|
| **dev** | your PC, `DEV_SERVER_1.21.10`, dev DB `knightsandkings_dev_v2` on 192.168.50.119 | build and try features | test data plus the **authored content** (forms, menus, items) |
| **staging** (recommended later) | a second, smaller copy of production (another VPS, or the same host with other ports) | rehearse a release (migrations, seed, plugin jar) before it reaches players | a restored copy of the production backup |
| **production** | the server(s) in this guide | the live game | real players |

> **Concept — four rules that make production boring (in a good way).**
> 1. **Build once, deploy the same artifact everywhere.** The API Docker image, web build or plugin jar that passed
>    CI is the exact file that runs in production. Nothing is recompiled on the server.
> 2. **Configuration lives in the environment, not the code** (the "12-factor" rule). The same image runs in staging
>    and production. Only environment variables and config files differ.
> 3. **Secrets are never in git.** They live in a password manager (the master copy) and in root-only files on the
>    server (the working copy).
> 4. **Every change is reversible.** Take a backup before migrating, keep the previous artifact version, and roll
>    back with one command.

### 1.3 Recommended topology: start with one Linux server

For a new community (tens of concurrent players), one virtual or dedicated server is enough and the easiest to run:

- **OS:** Ubuntu Server 24.04 LTS (or Debian 12). Production servers are almost always Linux, even when development
  happens on Windows.
- **Size:** 4 vCPU (high single-core speed matters for Minecraft), **16 GB RAM**, 100+ GB SSD/NVMe. Rough RAM budget:
  Paper heap 8–10 GB, MySQL 1–2 GB, API ~0.5 GB, OS and page cache the rest.
- **Hosting:** a VPS or dedicated box from a provider with good single-core CPUs and DDoS filtering for game traffic.
  Shared "Minecraft hosting" panels don't fit, because you also need to run Docker, MySQL and nginx.

**When to split:** move Paper to its own machine when game-server CPU usage starts to lag the web side, or when you want
to restart either without affecting the other. The design already allows this. Only `api.base-url`,
`MinecraftPlugin:BaseUrl` and the firewall rules change. Those two links then cross the network, so put them on a
private network or VPN and add TLS.

### 1.4 Why this mix of Docker and native services

| Part | Runs as | Why |
|---|---|---|
| MySQL | Docker container (`mysql:8.4`) | pinned version, the same image as CI, easy upgrades, data in a named volume |
| API | Docker container built by CI | immutable, versioned artifact; rollback = run the previous tag |
| Migrator | one-off Docker container (same build) | applies EF migrations from the exact commit being deployed (§ 5.3) |
| nginx + certbot | native (apt) | standard TLS automation; serves static files directly |
| Paper | native systemd service | Minecraft admins expect direct access to world folders, plugin jars and console/RCON; Java is a single binary |

> **Concept — Docker in one paragraph.** An *image* is a read-only snapshot of an app and everything it needs (for the
> API: the .NET runtime and the published DLLs). A *container* is a running instance of an image. *Docker Compose* is
> a YAML file that says which containers to run with which settings. `docker compose up -d` makes reality match the
> file. Data that must survive container replacement lives in a *volume*.

> **KnK — the version to deploy.** Deploy only commits that are on trunk (`master` for knk-web-api, `main` for the
> other two), are green in CI, and are tagged (§ 10.2). The developer's standing feature branches, such as
> `claude/road-navigation`, are pre-release.

### 1.5 Alternative for the closed alpha: NAS + Cloudflare Tunnel

For a small invite-only alpha, you can run the same containers on a home NAS and publish only the web origin through a
**Cloudflare Tunnel** (outbound-only, no open HTTP ports), with **Cloudflare Access** as an allow-list in front of it.
Cloudflare terminates TLS. nginx and certbot are replaced by a small web container plus `cloudflared`, and the
Minecraft port is forwarded on the router as before. The reasoning is in the
[alpha hardening plan § 3](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md#3-alpha-hosting-recommendation), and the
runbook is in [alpha-go-live.md](alpha-go-live.md). Move to the VPS topology above before an open beta.

---

## 2. Code changes to make before go-live

Reading the code and rehearsing the deployment turned up the gaps below. **Blockers** stop a working production
install. **Should-fix** items are risks you can run with for a closed beta. **Info** items are worth knowing.
Each one needs a Linear issue and a normal branch/PR. This guide works around them, and each workaround is noted
where it's used.

| # | Severity | Repo | Gap | Workaround in this guide | Proper fix |
|---|---|---|---|---|---|
| G1 | **Blocker** | web-app | API base URL hard-coded to `http://localhost:5294/api` (`src/config/appConfig.ts:11`). Nothing reads env vars. | Build with `baseUrl: '/api'` (same origin), § 8.1 | Read `process.env.REACT_APP_API_BASE_URL` with `/api` as default **— [KNG-64] fixed on branch, pending merge** |
| G2 | ~~Blocker~~ Info | web-app | `npm ci` fails **with npm 10 only**: `Missing: yaml@2.9.1 from lock file`. **Corrected 2026-10-08:** the lock file is valid for npm 11 (the developer's 11.6.2; see knk-web-app `f077570`), and regenerating it with npm 10 only churns peer flags. | Use npm 11 (`npx npm@11 ci`) | Pin Node 22 + npm 11 in CI and on build hosts (`corepack` or `npm i -g npm@11`); never regenerate the lock file with npm 10 |
| G3 | Should-fix | web-app | `CI=true npm run build` fails on ~20 existing ESLint warnings (CRA treats warnings as errors under CI) | Build with `CI=false` | Fix the warnings, then build with `CI=true` |
| G4 | Should-fix | web-api | CORS origins hard-coded to localhost (`Program.cs:131-147`) | Same origin (§ 1.1) makes CORS irrelevant | Read the allowed origins from config (`Cors:AllowedOrigins`) **— [KNG-64] fixed on branch, pending merge** |
| G5 | Should-fix | web-api | No forwarded-headers support: behind nginx every request seems to come from 127.0.0.1, so the password-reset cooldown "per email/IP" is per email only, and logs show no client IPs | Accept for beta | `app.UseForwardedHeaders()` with `KnownProxies = 127.0.0.1`, `X-Forwarded-For`/`-Proto` **— [KNG-64] fixed on branch, pending merge** |
| G6 | Should-fix | plugin | `RegionHttpServer` listens on **all interfaces, port 8081, without authentication** (`http/RegionHttpServer.java:45`) | Firewall blocks 8081 from outside (§ 3.4) | Bind to `127.0.0.1` by default and require the API key **— [KNG-64] fixed on branch, pending merge** |
| G7 | Should-fix | web-api | `dotnet ef migrations bundle` and `migrations script --idempotent` both fail: (a) the design-time host runs the startup seeds in `Program.cs` before migrating, so an empty DB crashes; (b) the idempotent script wraps triggers in procedures (`ERROR 1303`) | "Migrator" image runs `dotnet ef database update` (§ 5.3) | Add an `IDesignTimeDbContextFactory` and a fixed `ServerVersion`, and skip seeds when EF tooling runs |
| G8 | Should-fix | plugin | Bundled `config.yml` has `allow-untrusted-ssl: true` and an empty `api-key`, so the plugin **disables itself** on first start | Set both in § 9.5 | Default `allow-untrusted-ssl: false` **— [KNG-64] fixed on branch, pending merge** |
| G9 | Info | web-api | `ServerVersion.AutoDetect(...)` (`Program.cs:51`) connects to MySQL at startup and while building EF tooling, so the API can't start (or build a bundle) without a reachable DB | `depends_on: service_healthy` in Compose | `new MySqlServerVersion(new Version(8, 4))` |
| G10 | Info | web-api | `/metrics` is **not** exposed (no Prometheus exporter package); `CLAUDE.md` says otherwise. Telemetry exports OTLP to `localhost:4317` by default | `Telemetry__Enabled=false` until a collector exists | Add the exporter, or run an OTel collector (§ 12.3) |
| G11 | Info | web-api | `/health/ready` only runs a "self" check, not a DB check | Smoke test hits a DB-backed endpoint (§ 6.4) | `AddDbContextCheck<KnKDbContext>()` |
| G12 | Info | web-api | `[Authorize(Policy="RequireAdmin")]` (`AdminClientsController`) can never pass: no token carries an `Admin` role claim | none needed | Switch it to `[RequirePermission(...)]` **— [KNG-64] fixed on branch, pending merge** |
| G13 | Info | plugin | Jar is always `knk-paper-0.1.0-SNAPSHOT.jar`, `plugin.yml` says `0.1.0`; the task-claim server id is hard-coded `"localhost"` (`KnKPlugin.java:1207`) | Rename the jar on release (§ 10.4) | Take the version from the git tag in Gradle and `processResources` |
| G14 | Info | all | Each FormConfiguration (and other content authored in the web app) exists **only in the dev DB** (the `docs/specs/*/…_FORMCONFIGS.md` files say so) | The seed data set (§ 7) | The seed manifest stays the single list of shippable tables |

**Security blockers found 2026-10-08 (KNG-63 assessment, confirmed live), fixed by KNG-64.** Don't expose an API
without these, not even for a closed beta:

| # | Gap (before KNG-64) | Fix ([alpha hardening plan](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md)) |
|---|---|---|
| S1 | About 160 of 290 write endpoints have no auth attribute and there's no fallback policy. Anonymous `PUT /api/GameSettings` and anonymous create and delete of content work. | WP1: default-deny filter + a rule on every write + a reflection test (KNG-65) |
| S2 | `GET /api/Users` returns every email to anyone; permission grants are public | WP2: staff, self or plugin only; no emails in public summaries (KNG-65) |
| S3 | A moderator can grant themselves `*` | WP3: escalation guard (KNG-65) |
| S4 | A refresh token works as a bearer token; logout and password reset revoke nothing | WP4: opaque rotated refresh tokens + `TokenVersion` (KNG-66) |
| S5 | Anyone can pre-register a Minecraft name, and the real player gets attached on first join | WP5: registration needs a code from `/account link` (KNG-67) |
| S6 | No rate limiting or lockout; enumeration through `check-duplicate` and the login messages | WP6 (KNG-67) |
| S7 | Passwords and tokens logged to the browser console | WP8 (KNG-69) |
| S8 | A DB password and JWT secrets committed in `appsettings*.json` | WP7: values removed, fail-fast on placeholders (KNG-68). **Rotate the dev DB password.** |

---

## 3. Prepare the host

All commands are for Ubuntu 24.04 and run as a normal user with `sudo`. Replace `play.example.com`,
`mc.example.com` and `admin` with your own values.

### 3.1 Base hardening (do this before anything else)

> **Concept — attack surface.** A fresh public server is scanned within minutes. Use key-only SSH, deny every port
> you don't need, and patch automatically. Together these stop almost all opportunistic attacks.

```bash
# 1. A personal admin user; never work as root.
adduser admin && usermod -aG sudo admin
# Copy your SSH public key (from your PC): ssh-copy-id admin@<server-ip>

# 2. SSH: keys only, no root login.
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PasswordAuthentication no
PermitRootLogin no
KbdInteractiveAuthentication no
EOF
sudo systemctl restart ssh        # test a new SSH session BEFORE closing the current one

# 3. Automatic security updates, time sync, brute-force protection.
sudo apt update && sudo apt -y full-upgrade
sudo apt -y install unattended-upgrades fail2ban chrony
sudo dpkg-reconfigure -plow unattended-upgrades
sudo timedatectl set-timezone Europe/Amsterdam   # your own zone; only affects log times, the API stores UTC
```

### 3.2 Install the runtime software

```bash
# Docker Engine + Compose plugin (official repository, not the distro's docker.io)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update && sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# nginx + certbot (TLS), MySQL client tools (backups, seed import), Java 21 for Paper
sudo apt -y install nginx certbot python3-certbot-nginx mysql-client openjdk-21-jre-headless
```

> The Ubuntu `mysql-client` 8.0 talks to a MySQL 8.4 server without problems. Temurin 21 (adoptium.net) works as
> well as OpenJDK 21. Paper needs Java 21.

### 3.3 Directory layout

```bash
sudo mkdir -p /opt/knk /etc/knk /var/www/knk/releases /srv/minecraft /var/backups/knk
sudo useradd --system --home /srv/minecraft --shell /usr/sbin/nologin minecraft
sudo chown minecraft:minecraft /srv/minecraft
sudo chmod 700 /etc/knk /var/backups/knk
```

| Path | Holds | Owner / mode |
|---|---|---|
| `/opt/knk/compose.yaml`, `/opt/knk/.env` | Compose file; `KNK_VERSION=` the release being run | root, 644 |
| `/etc/knk/*.env`, `/etc/knk/mysql_root_password` | **secrets** (§ 4) | root, 600 |
| `/var/www/knk/releases/<version>/` + symlink `/var/www/knk/current` | web app builds | root, 755 |
| `/srv/minecraft/` | Paper server, worlds, plugins | `minecraft`, 750 |
| `/var/backups/knk/` | local DB dumps and world archives (copied off-site, § 5.5) | root, 700 |

### 3.4 Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH            # tighten later: sudo ufw allow from <your-home-ip> to any port 22
sudo ufw allow 80/tcp             # HTTP → redirected to HTTPS, and certbot renewals
sudo ufw allow 443/tcp
sudo ufw allow 25565/tcp          # Minecraft
sudo ufw enable
sudo ufw status verbose
```

Ports that must **not** be reachable from outside: 3306 (MySQL), 5000 (API, nginx proxies it), **8081** (plugin
`RegionHttpServer`, unauthenticated, G6) and 25575 (RCON).

> **Concept — Docker bypasses ufw.** A port published as `"3306:3306"` is opened by Docker's own iptables rules,
> *before* ufw sees the traffic. Always publish as `"127.0.0.1:3306:3306"`, or use host networking with a loopback
> bind, as the API does here. After setup, check from your PC (not the server) with
> `nmap -p 22,80,443,3306,5000,8081,25565,25575 <server-ip>`. Only 22, 80, 443 and 25565 may show `open`.

### 3.5 DNS

At your domain registrar: an `A` record `play.example.com → <server-ip>` (web app and API), and an `A` record
`mc.example.com → <server-ip>` (what players type). Add `AAAA` records too if the server has IPv6. Use a low TTL
(300 s) while setting up, and raise it later.

---

## 4. Configuration and secrets

### 4.1 Concepts

> **Concept — configuration vs. secrets.** *Configuration* is everything that changes between environments
> (hostnames, ports, feature toggles). *Secrets* are the subset that grant access (passwords, signing keys, API
> keys). Both stay out of the code. Secrets also stay out of git, chat, screenshots and logs.
>
> **Where secrets live (this project's scale):**
> 1. **Master copy:** a password manager (Bitwarden, 1Password or KeePassXC), in a "KnK production" vault. If the
>    server burns down, you rebuild from git + backups + this vault.
> 2. **Working copy:** root-only files on the server (`/etc/knk/*.env`, mode 600), read by Docker Compose and
>    systemd. Never in `/opt/knk/compose.yaml`, and never committed.
> 3. **CI secrets:** GitHub → repo → Settings → Secrets and variables → Actions, scoped to an *environment* named
>    `production` (§ 10.5).
>
> Bigger setups use a secrets manager (Vault, AWS/Azure secret stores, SOPS-encrypted files in git). Root-only env
> files are the accepted standard for one server.

> **KnK — how ASP.NET Core reads environment variables.** Every key in `appsettings.json` can be overridden by an
> environment variable. Replace each `:` with a double underscore `__`. `Security:Jwt:Secret` becomes
> `Security__Jwt__Secret`, and `ConnectionStrings:MySqlDbConnection` becomes `ConnectionStrings__MySqlDbConnection`.
> Environment variables take precedence over the JSON files. So the committed `appsettings.json` (which contains the
> dev LAN DB address, a placeholder JWT secret and the Gmail sender name) is harmless, provided production sets
> every key below.

### 4.2 Secret inventory

Generate each value on the server or your PC and store it in the password manager first.

| Secret | Used by | Generate with | Stored in | Rotate |
|---|---|---|---|---|
| `MYSQL_ROOT_PASSWORD` | MySQL admin only (backups, user management) | `openssl rand -base64 32` | `/etc/knk/mysql_root_password` | yearly / on staff change |
| `KNK_DB_MIGRATOR_PASSWORD` (user `knk_migrator`, DDL rights) | migrator container | `openssl rand -base64 32` | `/etc/knk/migrator.env` | yearly |
| `KNK_DB_APP_PASSWORD` (user `knk_app`, data-only rights) | API | `openssl rand -base64 32` | `/etc/knk/api.env` | yearly |
| `Security__Jwt__Secret` (≥ 32 chars, `TokenService.cs:34-46`) | API (signs every login token) | `openssl rand -base64 48` | `/etc/knk/api.env` | on suspicion; rotating it logs everyone out |
| `Security__PluginApiKey` | API **and** plugin `api.auth.api-key` (must be identical) | `openssl rand -hex 32` | `/etc/knk/api.env` + `/srv/minecraft/plugins/KnightsAndKings/config.yml` (mode 600) | on staff change; update both, then restart both |
| `Email__SmtpPassword` | API (password-reset mails) | a Gmail **app password** for the sender account (Google Account → Security → 2-Step Verification → App passwords) | `/etc/knk/api.env` | if leaked |
| RCON password | Paper console over RCON | `openssl rand -base64 24` | `/srv/minecraft/server.properties` | yearly |
| GHCR pull token (only if the images are private) | `docker login ghcr.io` on the server | GitHub fine-grained PAT, `read:packages` only | `/root/.docker/config.json` | 90 days |
| Deploy SSH key (§ 10.5) | GitHub Actions → server | `ssh-keygen -t ed25519 -C knk-deploy` | GitHub environment secret + server `authorized_keys` with a forced command | yearly |

Also keep in the vault, although they are not secrets: the server IP, registrar login, hosting-panel login (with
2FA), and the first admin's web account.

### 4.3 API configuration file — `/etc/knk/api.env`

```ini
# --- runtime ---
ASPNETCORE_ENVIRONMENT=Production
# Loopback only: nginx is the only public entrance (§ 8.3). The plugin calls it on loopback too.
ASPNETCORE_URLS=http://127.0.0.1:5000
# Host-header filter: the public name plus the loopback names the plugin and health checks use.
AllowedHosts=play.example.com;127.0.0.1;localhost

# --- database (data-only user, § 5.2) ---
ConnectionStrings__MySqlDbConnection=Server=127.0.0.1;Port=3306;Database=knk_prod;User=knk_app;Password=<KNK_DB_APP_PASSWORD>;Allow User Variables=True;

# --- auth ---
Security__Jwt__Secret=<openssl rand -base64 48>
Security__Jwt__Issuer=knk-api
Security__Jwt__Audience=knk-app
Security__PluginApiKey=<openssl rand -hex 32>
Security__AllowUnauthenticatedPluginCalls=false
Security__PasswordResetFrontendBaseUrl=https://play.example.com
Security__PasswordResetExposeTokenInDevelopment=false

# --- [KNG-64] sessions, signup, abuse protection (defaults shown; omit to keep them) ---
Security__RefreshCookie__SameSite=Lax            # same origin, so Lax; the cookie path is /api/Auth
Security__Registration__AllowWebFirst=false      # sign-up needs a code from /account link
Security__Lockout__MaxFailures=5
RateLimiting__Auth__PermitPerMinute=10
RateLimiting__Lookup__PermitPerMinute=20

# --- [KNG-64] nginx on the same host is the only proxy: trust it for the client IP ---
ForwardedHeaders__Enabled=true
ForwardedHeaders__KnownProxies=127.0.0.1

# --- mail (password reset links: https://play.example.com/auth/reset-password?token=...) ---
Email__Provider=Smtp
Email__SmtpHost=smtp.gmail.com
Email__SmtpPort=587
Email__UseStartTls=true
Email__SmtpUsername=knightsandkingsmc@gmail.com
Email__SmtpPassword=<gmail app password>
Email__FromAddress=knightsandkingsmc@gmail.com
Email__FromName=Knights & Kings

# --- game server link: API → plugin region checks (RegionHttpServer) ---
MinecraftPlugin__BaseUrl=http://127.0.0.1:8081

# --- observability: off until an OTLP collector exists (G10, § 12.3) ---
Telemetry__Enabled=false
Logging__LogLevel__Default=Information
Logging__LogLevel__Microsoft.AspNetCore=Warning
```

Notes:

- `ASPNETCORE_ENVIRONMENT=Production` matters for more than logging. In Production, Swagger is off, the
  `AllowUnauthenticatedPluginCalls` bypass is ignored, and the refresh cookie is sent `Secure; SameSite=None`
  (**[KNG-64]:** `Secure; SameSite=Lax; Path=/api/Auth`, and the API refuses to start when `Security__Jwt__Secret` is
  empty, shorter than 32 characters, or a value that was ever committed to git).
  That cookie needs HTTPS, so login "works" over plain HTTP, but staying signed in does not.
- Leave the rest at the `appsettings.json` defaults: `Security:BcryptRounds` 10, the link-code, cooldown and
  token lifetimes, `Discovery:MaxNewPerHour`, the `CurrencyMonitor:*` thresholds, and `ClientActivity`. Override one
  the same way if you need to.
- For a mail test without SMTP, `Email__Provider=Log` writes the reset link to the API log instead.

### 4.4 Migrator configuration — `/etc/knk/migrator.env`

```ini
ConnectionStrings__MySqlDbConnection=Server=127.0.0.1;Port=3306;Database=knk_prod;User=knk_migrator;Password=<KNK_DB_MIGRATOR_PASSWORD>;Allow User Variables=True;
```

`Allow User Variables=True` is required: migration `AddUserFeaturesPhase6RealTitleDataAndFreeze` uses SQL user
variables.

### 4.5 Plugin and web app configuration

- **Plugin:** the production values for `plugins/KnightsAndKings/config.yml` are in § 9.5.
- **Web app:** there is no runtime configuration. The API URL is compiled in (G1), see § 8.1.

```bash
sudo chmod 600 /etc/knk/*.env /etc/knk/mysql_root_password && sudo chown root:root /etc/knk/*
```

---

## 5. Database (MySQL)

### 5.1 Compose file — `/opt/knk/compose.yaml`

```yaml
# /opt/knk/compose.yaml — database, API and one-off migrator.
# nginx and the Paper server run directly on the host (§§ 8, 9).
name: knk

services:
  db:
    image: mysql:8.4                      # pin the patch in production, e.g. mysql:8.4.11
    restart: unless-stopped
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_0900_ai_ci
      - --log-bin-trust-function-creators=1   # the ledger-triggers migration needs it (§ 5.2)
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    secrets: [mysql_root_password]
    volumes:
      - db-data:/var/lib/mysql
    ports:
      - "127.0.0.1:3306:3306"             # loopback only: Docker port rules bypass ufw
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p\"$$(cat /run/secrets/mysql_root_password)\" --silent"]
      interval: 10s
      timeout: 5s
      retries: 12

  api:
    image: ghcr.io/pandio/knk-web-api:${KNK_VERSION:?set KNK_VERSION in /opt/knk/.env}
    restart: unless-stopped
    network_mode: host                    # reaches MySQL and the plugin (8081) on 127.0.0.1
    env_file: /etc/knk/api.env
    depends_on:
      db:
        condition: service_healthy

  migrator:
    image: ghcr.io/pandio/knk-web-api-migrator:${KNK_VERSION:?set KNK_VERSION in /opt/knk/.env}
    profiles: [migrate]                   # only runs when asked: docker compose run --rm migrator
    network_mode: host
    env_file: /etc/knk/migrator.env
    depends_on:
      db:
        condition: service_healthy

secrets:
  mysql_root_password:
    file: /etc/knk/mysql_root_password

volumes:
  db-data:
```

```bash
echo "KNK_VERSION=1.0.0" | sudo tee /opt/knk/.env     # the release tag you deploy (§ 10.2)
cd /opt/knk && sudo docker compose up -d db
sudo docker compose ps                                  # wait for db … (healthy)
```

> **Why MySQL 8.4, not 8.0?** 8.0 reached end of life in April 2026. 8.4 is the current LTS line, and the whole
> schema (61 migrations plus the ledger triggers) migrated and ran cleanly on 8.4.11 in the rehearsal. CI
> (`knk-web-api/.github/workflows/migrations.yml`) still tests `mysql:8.0`. Change that service image to the
> version production runs ("test what you ship"). The developer's dev DB should move to 8.4 too.

### 5.2 Database and users — least privilege

> **Concept — least privilege.** The running API only reads and writes rows. It never needs to create or drop
> tables. If the API is ever compromised, a data-only account can't `DROP DATABASE`. Schema changes go through a
> separate account that is only used during a deploy.

```bash
cd /opt/knk
sudo docker compose exec -T db sh -c 'mysql -uroot -p"$(cat /run/secrets/mysql_root_password)"' <<'EOF'
CREATE DATABASE knk_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Schema owner: used only by the migrator (and the seed import, § 7.5).
CREATE USER 'knk_migrator'@'%' IDENTIFIED BY '<KNK_DB_MIGRATOR_PASSWORD>';
GRANT ALL PRIVILEGES ON knk_prod.* TO 'knk_migrator'@'%';

-- Runtime: rows only.
CREATE USER 'knk_app'@'%' IDENTIFIED BY '<KNK_DB_APP_PASSWORD>';
GRANT SELECT, INSERT, UPDATE, DELETE ON knk_prod.* TO 'knk_app'@'%';
EOF
```

(`'%'` is acceptable because port 3306 is published only on loopback. With host networking the server sees the
connections as coming from 127.0.0.1.)

> **KnK — why `--log-bin-trust-function-creators=1`.** Migration `AddCurrencyLedgerImmutabilityTriggers` creates
> four triggers that make the currency ledger append-only. MySQL 8 has binary logging on by default. In that mode
> a non-`SUPER` user can only create triggers if this flag is set. Without it the migration fails with
> `You do not have the SUPER privilege and binary logging is enabled`, which happened in the rehearsal.
> Keep binary logging on: it enables point-in-time recovery (§ 5.5). Don't use the `KNK_SKIP_LEDGER_TRIGGERS`
> escape hatch in production, because the triggers are a safety feature.

### 5.3 Apply the migrations

> **Concept — migrations.** EF Core migrations (in `knk-web-api/Migrations/`) are versioned, ordered schema changes.
> `__EFMigrationsHistory` records which ones a database already has. "Migrating" means applying the missing ones in
> order. The API does **not** migrate itself on startup (no `Database.Migrate()` anywhere). This is deliberate and
> standard practice: schema changes happen in a separate, observable deploy step, after a backup.

**Use the migrator image.** It is the same commit as the API image, plus the `dotnet-ef` tool, and it runs
`dotnet ef database update`, which is exactly what CI does on every push:

```bash
cd /opt/knk
sudo docker compose run --rm migrator          # prints "Applying migration '…'" lines, then "Done."
```

To see what a release is going to change before you apply it, generate the SQL on your PC or in CI:

```bash
dotnet ef migrations script <current-prod-migration> --project knkwebapi_v2.csproj -o preview.sql
```

Read it, but don't execute it: the migrator remains the path that runs migrations.

> **KnK — why not a migration bundle or an idempotent script (the usual "best practice")?** Both were tried and both
> fail on this codebase (G7):
> - `dotnet ef migrations bundle` starts the app's `Program.cs`, which runs the startup seeds against a database
>   that has no tables yet: `Table 'knk_prod.EnchantmentDefinitions' doesn't exist`.
> - `dotnet ef migrations script --idempotent` wraps each migration in a stored procedure, and MySQL doesn't allow
>   `CREATE TRIGGER` inside one: `ERROR 1303 … Can't create a TRIGGER from within another stored routine`.
>
> Once G7 is fixed, a bundle becomes the cleaner option (a small, self-contained executable, with no SDK in the image).

### 5.4 Character set and time

The database is created as `utf8mb4` / `utf8mb4_0900_ai_ci` (full Unicode, including the emoji players put in chat or
names). The API stores timestamps in UTC. Leave the MySQL time zone at its default.

### 5.5 Backups — set these up before the first player joins

> **Concept — 3-2-1 and the restore test.** Keep **3** copies of the data, on **2** different kinds of storage,
> **1** of them off-site. A backup only counts once you have restored it. Schedule a restore drill (§ 12.4).

**Nightly logical dump** (consistent, no downtime; `--single-transaction` works because every table is InnoDB):

```bash
sudo tee /usr/local/bin/knk-db-backup >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ts=$(date +%Y%m%d-%H%M%S)
out=/var/backups/knk/db-$ts.sql.gz
cd /opt/knk
docker compose exec -T db sh -c 'mysqldump -uroot -p"$(cat /run/secrets/mysql_root_password)" \
  --single-transaction --routines --triggers --events --set-gtid-purged=OFF --databases knk_prod' | gzip > "$out"
gunzip -t "$out"                                          # fail loudly on a truncated file
find /var/backups/knk -name 'db-*.sql.gz' -mtime +14 -delete
echo "backup ok: $out"
EOF
sudo chmod 700 /usr/local/bin/knk-db-backup
echo '15 4 * * * root /usr/local/bin/knk-db-backup >> /var/log/knk-backup.log 2>&1' | sudo tee /etc/cron.d/knk-db-backup
```

**Off-site copy:** copy `/var/backups/knk` to object storage (Backblaze B2, Hetzner Storage Box, S3, …) with `restic`
or `rclone`. restic also encrypts the backups, so a leaked bucket doesn't leak player data. World backups (§ 9.8)
go to the same place.

**Point-in-time recovery** (optional, later): the binary logs, kept for `binlog_expire_logs_seconds` (30 days by
default), can replay changes made after the last dump. Learn this once the basics run.

---

## 6. API (knk-web-api)

### 6.1 The container image

This Dockerfile belongs in the knk-web-api repo root (with the `.dockerignore` below). CI builds it (§ 10.4). For
the very first install you can also build it on your PC and push it yourself.

```dockerfile
# syntax=docker/dockerfile:1
# knk-web-api/Dockerfile — three targets: build (internal), migrator, runtime.

# ---- build: restore, compile, publish ----
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY knkwebapi_v2.csproj ./
RUN dotnet restore knkwebapi_v2.csproj            # cached layer: only re-runs when the csproj changes
COPY . .
RUN dotnet build knkwebapi_v2.csproj -c Release --no-restore \
 && dotnet publish knkwebapi_v2.csproj -c Release -o /app/publish --no-build

# ---- migrator: the same build plus dotnet-ef; runs "database update" once per deploy ----
FROM build AS migrator
RUN dotnet tool install --global dotnet-ef --version 9.0.10   # matches Microsoft.EntityFrameworkCore.Design
ENV PATH="$PATH:/root/.dotnet/tools"
ENTRYPOINT ["dotnet", "ef", "database", "update", "--no-build", "--project", "knkwebapi_v2.csproj", "--configuration", "Release"]

# ---- runtime: only the published output, non-root ----
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://0.0.0.0:5000
EXPOSE 5000
USER app
ENTRYPOINT ["dotnet", "knkwebapi_v2.dll"]
```

```gitignore
# knk-web-api/.dockerignore
bin/
obj/
Tests/
.git
.vscode
```

```bash
# Manual build and push (from the knk-web-api checkout at the release tag):
docker build --target runtime  -t ghcr.io/pandio/knk-web-api:1.0.0 .
docker build --target migrator -t ghcr.io/pandio/knk-web-api-migrator:1.0.0 .
echo <PAT with write:packages> | docker login ghcr.io -u PandiO --password-stdin
docker push ghcr.io/pandio/knk-web-api:1.0.0 && docker push ghcr.io/pandio/knk-web-api-migrator:1.0.0
```

> **KnK — things the image takes care of.** The `Data/` JSON catalogs (Minecraft materials and enchantments) are
> copied into the publish output by the Web SDK, and `WORKDIR /app` makes the content root resolve them. (The
> material catalog is found relative to the *working directory*, so a non-Docker install needs
> `WorkingDirectory=` set to the publish folder.) The `Tests/` folder is excluded both by `.dockerignore` and by
> `DefaultItemExcludes` in the csproj. The ASP.NET "DataProtection keys not persisted" warning at startup is
> harmless here: authentication uses JWTs, not data-protection cookies.

### 6.2 Start it

```bash
cd /opt/knk
sudo docker compose up -d api
sudo docker compose logs -f api     # Ctrl-C to stop following
```

A healthy first start logs one line per startup seed: `Canonical seed complete`, `ItemBlueprint example catalog seed
complete`, `MenuTemplate seed complete`, `Kit seed complete`, `ItemBlueprintV1Seed complete`, `EnchantBookSeed
complete`, `LootboxSeed complete`, `SiegeLobby seed: …`. Then `Currency monitor started`. There should be **no**
`Security:PluginApiKey is not set` warning.

### 6.3 Health endpoints

| Endpoint | Meaning | Exposed publicly? |
|---|---|---|
| `GET /health/live` | the process is up | no (`deny` in nginx; use from the host) |
| `GET /health/ready` | readiness. Today only a "self" check, no DB (G11) | no |
| `GET /api/health` | used by the plugin's `/knk health` | yes (harmless: status + version) |

```bash
curl -s http://127.0.0.1:5000/health/ready
curl -s http://127.0.0.1:5000/api/health
```

### 6.4 Smoke test with the database

`/health/ready` doesn't touch the DB, so test an endpoint that does. A registration does, and it is also the first
admin's account (§ 6.5).

### 6.5 Bootstrap the first admin

> **[KNG-64] changed.** `POST /api/Users` now needs the plugin key or staff rights, and web registration needs a
> code from the game. After the merge, the owner's bootstrap is:
> 1. Join the Minecraft server (`online-mode=true`). The plugin creates your account with your real UUID.
> 2. Run `/account link` in game and note the 8-character code.
> 3. Register at `https://play.example.com/auth/register` with the code, your email and a password. You're logged in.
> 4. Grant yourself `*` with the plugin key (step 2 below). To find your id, call
>    `curl -s -H "X-API-Key: $KEY" http://127.0.0.1:5000/api/Users/uuid/<your-uuid>`.
>
> The curl registration in step 1 below still works if you add `-H "X-API-Key: $KEY"`, but then the account has no
> Minecraft link. Prefer the flow above.

> **KnK — how admin rights work.** Permissions are nodes (`knk.admin.user.perm`, `knk.siege.admin.manage`, …),
> granted to a *permission holder*, which is a user or a group (`PermissionGrant`, resolved by
> `PermissionResolutionService`). A grant of `*` matches every node. The migrations seed the groups `Default`,
> `Noble`, `Royal` and `Dragon Blood`, all with player nodes only: **no admin exists on a fresh database**, and
> `LootboxSeed` says "Admin nodes are never seeded" on purpose. The one key that can grant the first admin node is
> the plugin API key, because `PermissionGrantsController` accepts `X-API-Key` in place of an admin login.

1. Register your own account in the web app (once § 8 is up), or call the API directly. **[KNG-64]** `POST /api/Users`
   needs the plugin key (or `knk.admin.user.manage`, which nobody holds yet), so run it on the server:

   ```bash
   KEY=$(sudo grep '^Security__PluginApiKey=' /etc/knk/api.env | cut -d= -f2-)
   curl -s -X POST http://127.0.0.1:5000/api/Users \
     -H "X-API-Key: $KEY" -H 'Content-Type: application/json' \
     -d '{"Username":"<your MC name>","Email":"<you@…>","Password":"<strong>","PasswordConfirmation":"<strong>"}'
   ```

   Note the returned `"id"`. Users and groups share one id space, so after a seed import your id is higher than
   the highest group id (`7` in the rehearsal).

2. Grant yourself `*` with the plugin key, from the server so the key never leaves it (same shell, so `$KEY` is set):

   ```bash
   curl -s -X PUT http://127.0.0.1:5000/api/PermissionGrants/by-node \
     -H "X-API-Key: $KEY" -H 'Content-Type: application/json' \
     -d '{"holderId":<your id>,"node":"*","value":true}'
   # → {"id":…,"holderId":<your id>,"holderType":"User","node":"*","value":true,"expiresAt":null}
   ```

3. Log out and back in to the web app. The admin pages now work. Later, set up a **Staff** group with
   specific nodes for moderators instead of handing out `*`. Keep `*` for the owner (and a second owner account
   kept in the vault for emergencies).

4. Link your Minecraft account: in game run `/account link`, then enter the code on the web app's Account page.

> **Equivalent SQL** (if the API isn't up yet):
> `INSERT INTO permission_grants (HolderId, Node, Value, ExpiresAt) VALUES (<id>, '*', 1, NULL);`, run as
> `knk_migrator`. The API route is preferred because it writes an audit-log entry.

---

## 7. Seed data: preparing and loading the content set

### 7.1 What "seeding" means here

> **Concept — kinds of data.** Each one has its own path into production:
>
> | Kind | Example in KnK | How it gets to production |
> |---|---|---|
> | **Schema** | tables, indexes, the ledger triggers | EF migrations (§ 5.3) |
> | **Reference data** | title brackets Serf → "One of the Seven", groups Default/Noble/Royal/Dragon Blood, currency policies, discovery reward rules | inside the migrations (`InsertData`/`Sql`) |
> | **Canonical content in code** | enchantments and abilities, kits, ~150 item blueprints, menu templates, lootbox types, the example siege lobby | startup seeds in `Program.cs:204-238`, create-only by key (except `AbilityDefinition`, which upserts its display fields on every start) |
> | **Authored content** | every **FormConfiguration** (forms, steps, fields, validations, display conditions), DisplayConfigurations, edits to items/menus/kits/lootboxes, extra permission groups (e.g. Staff), game settings | exists **only in the dev DB** → the **seed data set** below |
> | **Runtime data** | users, balances and the currency ledger, item instances, claims, discoveries, audit/PM logs, siege matches | never seeded; it's what players create |
>
> Authored content is the tricky part. Without it the web app's create and edit forms are empty: a fresh database
> has `FormConfigurations` = 0. The project has deliberately kept it "data, not code" (the `docs/specs/*/…_FORMCONFIGS.md`
> files), so production gets it as a data export from the dev DB.

### 7.2 The table manifest

[`scripts/seed/seed-tables.sh`](../../scripts/seed/seed-tables.sh) sorts **every** table into one of four lists:

- `CONTENT_TABLES`: always exported.
- `GROUP_FILTERED_TABLES`: `permission_holders` and `permission_grants`, exported **for groups only**. Users and
  groups share these tables (table-per-type inheritance), and no user or user grant may leave the dev DB.
- `WORLD_TABLES`: data tied to one specific Minecraft world (§ 7.4).
- `RUNTIME_TABLES`: never exported.

`export-seed.sh` refuses to run while any table in the database is missing from the manifest. When a migration adds a
table, the export forces someone to decide which kind of data it is. **Updating the manifest is part of any PR that
adds a table.**

### 7.3 Prepare the dev DB (the "golden" source)

1. **Finish and freeze.** The seed is a snapshot of the dev DB at one schema version. Merge the release's features to
   trunk, run `dotnet ef database update` on the dev DB from that trunk commit, and stop authoring while you export.
2. **Re-create content that only exists in session databases.** Some `…_FORMCONFIGS.md` files say their payloads were
   authored in a temporary sandbox DB and still need re-creating in the dev DB. `docs/specs/items/PHASE_2_FORMCONFIGS.md`
   is one example. Go through each of them:
   `docs/specs/items/PHASE_2_FORMCONFIGS.md`, `kits/PHASE_3_FORMCONFIGS.md`, `lootboxes/PHASE_4_FORMCONFIGS.md`,
   `siege-minigame/PHASE_3_FORMCONFIGS.md`, `teleport/KNG41_FORMCONFIGS.md` (plus the Street "Road" step from
   `navigation/IMPLEMENTATION_PLAN.md` once road navigation is merged).
3. **Review the content as if players will see it, because they will.** Look for test items, "asdf" kits,
   enabled debug lootboxes, joke titles and test permission groups. Delete or fix them in the web app, not with
   SQL, so the API's own rules apply.
4. **Check the defaults.** Each entity type needs exactly one default FormConfiguration. Check Game Settings
   (spawn, join message), and whether each seeded lootbox type, kit and the example siege lobby should be enabled.
5. **Back up the dev DB** before and after (`mysqldump`, as in § 5.5).

### 7.4 World-coupled data: decide which world production starts with

Rows in `WORLD_TABLES` hold coordinates and WorldGuard region ids, and only make sense with the matching world files:
domains, towns, districts, structures, streets, locations, gates with their block snapshots, siege scenarios, lobbies,
clans/banners, lootbox spawn areas.

| Choice | Do this |
|---|---|
| **A. New, empty production world** (e.g. a fresh map) | Export **without** `--with-world`. Towns, gates, etc. are created on the production server through the normal in-game/web flows. |
| **B. Copy the dev build world** (the dev map is the real map) | Export **with** `--with-world`, **and** copy the world folders (`world`, `world_nether`, `world_the_end` and any custom worlds) **plus** `plugins/WorldGuard/worlds/` from the dev server, taken at the same moment as the export. Mismatched regions and rows give "region not found" errors and broken gates. |

Mixing the two (world rows without the world, or the reverse) is the one combination that will break.

### 7.5 Export (on your PC, against the dev DB)

Create a read-only MySQL user for exports (once, as root on the dev DB), and a MySQL option file so the password is
never typed on the command line:

```sql
CREATE USER 'knk_seed_reader'@'%' IDENTIFIED BY '<password>';
GRANT SELECT ON knightsandkings_dev_v2.* TO 'knk_seed_reader'@'%';
```

```ini
# ~/.knk-dev.cnf  (chmod 600; on Windows keep it in your user profile)
[client]
host=192.168.50.119
user=knk_seed_reader
password=<password>
```

```bash
# Git Bash or WSL; the MySQL 8 client tools (mysql, mysqldump) on PATH.
cd knk-workspace
scripts/seed/export-seed.sh --defaults-file ~/.knk-dev.cnf --database knightsandkings_dev_v2 \
    --out seed/2026-10-07            # add --with-world for choice B
```

The result is `seed/<date>/seed.sql` (data only, one consistent snapshot) and `manifest.txt`, which holds the
schema version, the row count per table and a SHA-256 of the dump. Keep both together. **Don't commit them to
git:** they are a release artifact, so store them with the backups or attach them to the release (§ 10.2). Review
the row counts in `manifest.txt` before you move on. A suspicious count (500 lootbox types?) means test data
slipped in.

### 7.6 Import (on the server, once, before the API's first start)

Order matters: **migrations → seed import → first API start.** The import refuses to run on a database that already
has users, or whose schema version differs from the seed's. It also checks the SHA-256 and runs in a single
transaction, so a failure leaves nothing half-done.

```bash
# copy the seed folder to the server, e.g. scp -r seed/2026-10-07 admin@server:/tmp/
sudo tee /root/.knk-migrator.cnf >/dev/null <<'EOF'
[client]
host=127.0.0.1
user=knk_migrator
password=<KNK_DB_MIGRATOR_PASSWORD>
EOF
sudo chmod 600 /root/.knk-migrator.cnf

git clone https://github.com/PandiO/knk-workspace.git ~/knk-workspace   # for scripts/seed
sudo ~/knk-workspace/scripts/seed/import-seed.sh \
     --defaults-file /root/.knk-migrator.cnf --database knk_prod --seed /tmp/2026-10-07
# → Seed 2026-10-07T… imported into knk_prod (schema 20261006193103_…). Start the API next.
```

What the import does, in one transaction: it clears the content tables (removing the reference rows the migrations
inserted, which the dev DB has too, with the same ids), loads the dump, and clears the two user-reference columns
(`currency_policies.UpdatedByUserId`, `lootbox_spawn_areas.CreatedByUserId`, which point at dev users). It then
compares the row counts with the manifest **before committing**: a mismatch prints the table and rolls the whole
import back.

On the API's first start after the import, every create-only startup seed finds its rows and creates nothing. In the
rehearsal this read `Kit seed complete. Created: nothing`. The first real account then gets the `Default` group and
the 250 coins / 50 gems signup grant, exactly as on dev.

### 7.7 Later releases

The seed is a **one-time bootstrap**. After launch, production is the source of truth for its own content, and the
import refuses to run anyway once users exist. Content changes after launch reach production in one of two ways:

- **Code-owned content** (startup seeds, migration `InsertData`) arrives with the release automatically.
- **Authored content** (a new FormConfiguration for a new feature) is re-done on production through the web app's
  FormConfigBuilder, or replayed with the payloads recorded in that feature's `…_FORMCONFIGS.md`. That record is
  why those files exist. If this becomes frequent, the next step up is an export/import feature for single
  FormConfigurations in the API: ask for it as a feature, don't hand-edit production SQL.

---

## 8. Web app and the public web server

### 8.1 Build (CI or your PC)

```bash
# knk-web-app at the release tag
CYPRESS_INSTALL_BINARY=0 npm install          # npm ci once G2 is fixed; skip the Cypress binary on servers/CI
# G1 workaround: same-origin API path. Do this in CI, never by editing a prod server.
sed -i "s#baseUrl: 'http://localhost:5294/api'#baseUrl: '/api'#" src/config/appConfig.ts
grep -n "baseUrl" src/config/appConfig.ts      # must show: baseUrl: '/api',
CI=false npm run build                         # G3: CI=true fails on existing lint warnings
# [KNG-64] after the merge: no sed needed, the URL comes from the environment:
#   REACT_APP_API_BASE_URL=/api REACT_APP_MC_SERVER_ADDRESS=mc.example.com CI=false npm run build
tar -C build -czf knk-web-app-1.0.0.tar.gz .
```

Node 20 or newer is required (react-router 7 declares `engines.node >=20`). The example workflow in `TESTING.md`
uses Node 18, which is outdated.

### 8.2 Install a release (atomic switch, instant rollback)

```bash
ver=1.0.0
sudo mkdir -p /var/www/knk/releases/$ver
sudo tar -C /var/www/knk/releases/$ver -xzf knk-web-app-$ver.tar.gz
sudo ln -sfn /var/www/knk/releases/$ver /var/www/knk/current      # rollback = point it at the previous version
```

### 8.3 nginx site — `/etc/nginx/sites-available/knk`

```nginx
# One public origin: the SPA at /, the API at /api.
server {
    listen 80;
    server_name play.example.com;

    root /var/www/knk/current;           # the web app's build/ output (§ 8.2)
    index index.html;

    # The API: same origin, so no CORS and the refresh cookie stays first-party.
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 10m;
    }

    # Health probes stay private: monitor them from the host, not the internet.
    location /health/ { deny all; }

    # Hashed build assets never change: cache for a year.
    # (Only "expires" here, no add_header: an add_header inside a location
    # drops every add_header inherited from the server block.)
    location /static/ {
        expires 1y;
        try_files $uri =404;
    }

    # BrowserRouter deep links (/auth/reset-password?token=…, /admin/...) fall back to the SPA.
    location / {
        expires -1;                      # index.html: always revalidate
        try_files $uri /index.html;
    }

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header X-Frame-Options DENY always;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/knk /etc/nginx/sites-enabled/knk
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

> **KnK — why the SPA fallback.** The app uses `BrowserRouter` (`src/App.tsx:1`), so `/auth/reset-password` is a
> client-side route with no file on disk. Without `try_files … /index.html`, password-reset links from email return
> 404.

### 8.4 TLS (HTTPS) with Let's Encrypt

```bash
sudo certbot --nginx -d play.example.com --redirect -m <your email> --agree-tos
sudo certbot renew --dry-run          # renewal runs automatically via a systemd timer
```

certbot edits the server block: it adds `listen 443 ssl`, the certificate paths and an HTTP → HTTPS redirect.
Once HTTPS works, add HSTS to the 443 server block: `add_header Strict-Transport-Security "max-age=31536000" always;`.

> **Concept — why HTTPS isn't optional.** Without it, passwords and tokens cross the network in plain text, and
> this API's refresh cookie (`Secure; SameSite=None` in Production; `Secure; SameSite=Lax` with **[KNG-64]**) is never
> sent, so "remember me" silently fails.

> **Third-party assets:** the app loads the Inter font from Google Fonts (`src/index.css:5`) and the logo from a
> Dropbox link (`src/components/Navigation.tsx:218`). Moving the logo into `public/` before launch is cheap
> insurance against a broken image if that link expires.

---

## 9. Minecraft server (Paper + knk-plugin)

*Untested in the rehearsal. Follow it on staging first.*

### 9.1 Install Paper 1.21.10

```bash
sudo -u minecraft -s
cd /srv/minecraft
# Latest stable 1.21.10 build from PaperMC's download API (v3; the old v2 API returns 410):
curl -s -H "User-Agent: knk-admin (<your email>)" \
  https://fill.papermc.io/v3/projects/paper/versions/1.21.10/builds/latest > build.json
url=$(python3 -c 'import json;print(json.load(open("build.json"))["downloads"]["server:default"]["url"])')
sha=$(python3 -c 'import json;print(json.load(open("build.json"))["downloads"]["server:default"]["checksums"]["sha256"])')
curl -fsSL -o paper.jar "$url" && echo "$sha  paper.jar" | sha256sum -c -     # must print: paper.jar: OK
```

On 2026-10-07 that resolved to `paper-1.21.10-130.jar` (build 130, channel STABLE). Pin a build and upgrade
deliberately; don't auto-update.

### 9.2 Dependencies

- **WorldGuard** (`depend`) and **WorldEdit** (`softdepend`, but used directly by ~10 classes): install both.
- **Use the exact jar versions running on `DEV_SERVER_1.21.10`.** The build compiles against WorldEdit 7.2.13 and
  WorldGuard 7.0.10 APIs, but the runtime jars must be versions that support 1.21.10, which the dev server already
  proves. Copy them from the dev server's `plugins/` folder, or download the same versions from EngineHub /
  Modrinth, and record the versions in the release manifest (§ 10.2).
- No Vault, LuckPerms, ProtocolLib or Citizens. **Don't install a permissions plugin:** permissions come from the web
  API (`KnkPermissible`), and a second system would conflict with it.

### 9.3 First start, EULA and `server.properties`

```bash
java -Xms2G -Xmx2G -jar paper.jar --nogui     # generates files, then stops at the EULA
# Read https://aka.ms/MinecraftEULA, then:
sed -i 's/eula=false/eula=true/' eula.txt
```

Production values in `server.properties`:

| Key | Value | Why |
|---|---|---|
| `online-mode` | `true` | **Critical.** Player identity in the API is the Mojang UUID. Offline mode lets anyone join as anyone, including you. |
| `enforce-secure-profile` | `true` | signed chat (vanilla default) |
| `white-list` / `enforce-whitelist` | `true` during closed beta | invite-only until you're confident |
| `server-port` | `25565` | |
| `enable-rcon` | `true` | console access without attaching to the process |
| `rcon.port` / `rcon.password` | `25575` / `<from the vault>` | port blocked by ufw (§ 3.4), use only from the host |
| `motd`, `max-players`, `view-distance` (8–10), `simulation-distance` (6–8), `spawn-protection` (0; WorldGuard does this) | your choice | performance and look |
| `level-name` | `world` | the main world. The plugin uses the **first loaded world** as the main world (spawn, playerdata) |

**Ops:** make only the owner an operator (`op <you>` in the console). Ops pass every `knk.*` check. Everyone else,
staff included, gets nodes through the web API (§ 6.5 and the in-game `/knk user <player> group|perm …` commands).

### 9.4 Run Paper as a systemd service

```ini
# /etc/systemd/system/minecraft.service
[Unit]
Description=Knights and Kings Paper server
After=network-online.target docker.service
Wants=network-online.target

[Service]
User=minecraft
WorkingDirectory=/srv/minecraft
# Aikar's flags (standard G1GC tuning for Paper); heap 8G on a 16 GB host, Xms = Xmx.
ExecStart=/usr/bin/java -Xms8G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
  -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper.jar --nogui
# Paper saves worlds and disables plugins on SIGTERM; give it time.
TimeoutStopSec=180
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl enable --now minecraft
journalctl -u minecraft -f                      # the server log
sudo apt -y install mcrcon                      # or build from github.com/Tiiffi/mcrcon
mcrcon -H 127.0.0.1 -P 25575 -p '<rcon password>' "list"   # console commands over RCON
```

### 9.5 Install the KnightsAndKings plugin

1. Put the released jar in `plugins/`. Remove any older `knk-paper-*.jar`, because two copies conflict.
2. Start once so `plugins/KnightsAndKings/config.yml` is created. With the default config the plugin then
   **disables itself** (empty `api-key`, G8). That is expected.
3. Set the production values (and leave the other sections at their defaults for the first run):

   ```yaml
   api:
     base-url: "http://127.0.0.1:5000/api"     # loopback to the API; the /api suffix is required
     debug-logging: false
     allow-untrusted-ssl: false                 # G8: the shipped file says true
     auth:
       type: apikey
       api-key: "<Security__PluginApiKey from /etc/knk/api.env>"
       api-key-header: "X-API-Key"
     timeouts: { connect: 10, read: 10, write: 10 }
   region-http:
     bind-address: "127.0.0.1"                 # [KNG-64] loopback only; requires X-API-Key once api-key is set
   web:
     public-url: "https://play.example.com"    # [KNG-64] shown in the /account link message
   # region-http.port is not in the file; the default 8081 matches MinecraftPlugin__BaseUrl.
   ```

   ```bash
   sudo chmod 600 /srv/minecraft/plugins/KnightsAndKings/config.yml   # it holds the API key
   ```

4. Start the API **before** Paper. When the API is down at plugin start, the menu-template check blocks the main
   thread until it times out. The plugin still enables, but several features start degraded. The systemd unit
   orders Paper after Docker, but that doesn't wait for the API to be healthy, so check § 6.3 after a reboot.

5. In the console, check:
   - `KnightsAndKings` is enabled, with no "Failed to initialize plugin" and no stack traces.
   - `/knk health` in game, or over RCON, reports the API as up.
   - `/knk cache refresh` succeeds.
   - Managed-region startup repair runs about 5 s after start, with no errors (only relevant with a copied world).

### 9.6 The world

- **Choice A (new world, § 7.4):** let Paper generate it, or drop in a prepared map. Set the spawn in the web app's
  Game Settings. Create towns, districts and gates through the normal flows.
- **Choice B (copied dev world):** stop the dev server, or run `save-off` + `save-all flush`. Then copy the world
  folders and `plugins/WorldGuard/worlds/` at the same moment as `export-seed.sh --with-world`. Delete
  `<world>/playerdata`, `stats` and `advancements` from the copy: those are dev testers' inventories.

### 9.7 Plugin runtime state worth knowing

The plugin keeps some state on local disk under `plugins/KnightsAndKings/`, which is why the world backup in § 9.8
includes the whole server directory:

- `siege-vault/<uuid>.yml`: player inventories that get restored after a siege.
- `siege-vault/pending-results/`: match results not yet sent.
- `siege-vault/world-blocks.yml`: placed siege blocks.
- `discovery-spool/` and `private-messages-spool.jsonl`: queued writes that are replayed when the API is back.
- `logs/private-messages-*.log`: 30-day retention.

### 9.8 World backups

```bash
# /usr/local/bin/knk-world-backup (root, cron nightly after the DB dump)
#!/usr/bin/env bash
set -euo pipefail
rc() { mcrcon -H 127.0.0.1 -P 25575 -p "$(cat /etc/knk/rcon_password)" "$@"; }
ts=$(date +%Y%m%d-%H%M%S)
rc "save-off" "save-all flush"
trap 'rc "save-on"' EXIT                       # always re-enable saving, even if tar fails
tar -C /srv -czf /var/backups/knk/minecraft-$ts.tar.gz --exclude='minecraft/logs' --exclude='minecraft/cache' minecraft
find /var/backups/knk -name 'minecraft-*.tar.gz' -mtime +7 -delete
```

(Put the RCON password in `/etc/knk/rcon_password`, mode 600.) Time the world and DB backups close together, so a
restore gives a world and database that match.

---

## 10. CI/CD plan

### 10.1 Concepts

> **CI (continuous integration):** every push and PR is built and tested automatically, so trunk always works. This
> project already has CI in part: knk-plugin's `build.yml` runs the build and the unit tests, and knk-web-api's
> `migrations.yml` migrates a fresh MySQL, checks the model snapshot, rolls everything back and re-applies it.
>
> **CD (continuous delivery):** a tagged release automatically produces deployable **artifacts**: the API images, a
> web build tarball and the plugin jar. Deploying them is a deliberate, approved step. "Continuous *deployment*",
> where every merge goes live with no human in between, is a later option and not recommended for a live game with
> one developer.
>
> **Pipeline:** `PR → CI green → merge to trunk → tag vX.Y.Z → release workflow builds artifacts → deploy workflow (with approval) → smoke test`.

Roll it out in three stages. Each one is useful on its own.

### 10.2 Versioning and the release manifest

- **Semantic versioning per repo:** `vMAJOR.MINOR.PATCH`. Tag on trunk only: `git tag -a v1.0.0 -m "…" && git push origin v1.0.0`.
- **A release manifest** in knk-workspace, as a dated record: `docs/reports/<yyyy-mm-dd>-release-<version>.md`.
  The three repos must deploy together and in the right order, so the manifest pins what belongs together:

  ```markdown
  # Release 1.0.0 — 2026-11-01
  | Component | Version | Commit | Artifact |
  |---|---|---|---|
  | knk-web-api | v1.0.0 | 1805cf9 | ghcr.io/pandio/knk-web-api:1.0.0 (+ -migrator) |
  | knk-web-app | v1.0.0 | …       | knk-web-app-1.0.0.tar.gz (release asset) |
  | knk-plugin  | v1.0.0 | c7d5a1e | knk-paper-1.0.0.jar (release asset) |
  | Paper / WorldEdit / WorldGuard | 1.21.10-130 / … / … | | |
  | Schema | 20261006193103_UniquePermissionGrantHolderNode | | |
  | Seed (first install only) | 2026-10-07 | | sha256 … |
  Deploy notes: migrations in this release, config keys added, manual steps (FormConfigurations to re-create).
  ```

### 10.3 Stage 1 — CI on every push and PR (do this first)

**knk-web-app** has no CI at all yet. Draft `.github/workflows/ci.yml` (after G2 is fixed):

```yaml
name: CI
on: { push: { branches: ['**'] }, pull_request: {}, workflow_dispatch: {} }
jobs:
  build-test:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    env: { CYPRESS_INSTALL_BINARY: '0' }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run test:ci
      - run: npm run build
        env: { CI: 'false' }          # until G3 is fixed; then remove this line
```

**knk-web-api**: keep `migrations.yml` and add a unit-test job. The tests tagged `requires-mysql` need a database,
so filter them out, or run them in the existing MySQL job with `KNK_TEST_MYSQL` set:

```yaml
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: 8.0.x }
      - run: dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter "Category!=requires-mysql"
```

Also change `migrations.yml`'s service image to `mysql:8.4` (§ 5.1).

**knk-plugin:** `build.yml` already does this stage.

**Then protect trunk:** GitHub → Settings → Branches → a rule for `master`/`main` that requires the CI checks to pass
before merging.

### 10.4 Stage 2 — release artifacts on a tag

**knk-web-api** — `.github/workflows/release.yml` (needs the Dockerfile from § 6.1 in the repo):

```yaml
name: Release
on: { push: { tags: ['v*'] } }
permissions: { contents: read, packages: write }
jobs:
  images:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: v
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"
      - uses: docker/login-action@v3
        with: { registry: ghcr.io, username: '${{ github.actor }}', password: '${{ secrets.GITHUB_TOKEN }}' }
      - uses: docker/build-push-action@v6
        with:
          context: .
          target: runtime
          push: true
          tags: ghcr.io/pandio/knk-web-api:${{ steps.v.outputs.version }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          target: migrator
          push: true
          tags: ghcr.io/pandio/knk-web-api-migrator:${{ steps.v.outputs.version }}
```

**knk-web-app** — on a tag: build (with the G1 `sed` step from § 8.1), `tar` the `build/` folder, and attach it to a
GitHub Release (`softprops/action-gh-release@v2` with `files: knk-web-app-*.tar.gz`).

**knk-plugin** — on a tag: `./gradlew build -PdevServerDirectory="$RUNNER_TEMP/devserver"` (as `build.yml` does),
then rename `knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar` to `knk-paper-<version>.jar` (G13) and attach it
to the GitHub Release.

> **Concept — why tag-triggered.** A tag is an immutable name for one commit. Building artifacts from tags means
> "version 1.0.0" always means the same bytes. A branch name like `main` keeps moving, so it can't promise that.

### 10.5 Stage 3 — deploy

**Stage 3a — a deploy script on the server, run by you (start here).** Commit it to knk-workspace (for example as
`scripts/deploy/knk-deploy.sh`) and install it on the server as `/usr/local/bin/knk-deploy`:

```bash
#!/usr/bin/env bash
# knk-deploy <version> — backup, migrate, roll the API, switch the web app, smoke-test.
# The plugin jar is swapped separately in a maintenance window (§ 10.6).
set -euo pipefail
ver="${1:?usage: knk-deploy <version>}"
cd /opt/knk

echo "== 1. backup";      /usr/local/bin/knk-db-backup
echo "== 2. pull";        sed -i "s/^KNK_VERSION=.*/KNK_VERSION=$ver/" .env
                          docker compose pull api migrator
echo "== 3. migrate";     docker compose run --rm migrator
echo "== 4. api";         docker compose up -d api
for i in $(seq 1 30); do curl -fsS http://127.0.0.1:5000/health/ready >/dev/null && break; sleep 2; done
curl -fsS http://127.0.0.1:5000/api/health
echo "== 5. web app";     test -d /var/www/knk/releases/$ver || { echo "missing web build $ver (download the release asset first)"; exit 1; }
                          ln -sfn /var/www/knk/releases/$ver /var/www/knk/current
echo "== 6. smoke";       curl -fsS -o /dev/null https://play.example.com/ && curl -fsS https://play.example.com/api/health
echo "deployed $ver"
```

**Stage 3b — GitHub Actions runs the same script (once 3a is routine).** Add a `deploy.yml` with
`on: workflow_dispatch` (input: version) in knk-workspace. Its job uses `environment: production`, and in GitHub →
Settings → Environments → production you add yourself as a **required reviewer**, so every deploy waits for your
click. The job SSHes to the server with a deploy key whose `authorized_keys` entry is restricted to that one command
(`command="/usr/local/bin/knk-deploy-wrapper",no-pty,no-port-forwarding ssh-ed25519 …`). The pipeline can then do
nothing on the server except deploy.

### 10.6 Release order, plugin deploy, and rollback

1. **API first**, including migrations: § 10.5 steps 1–4. Migrations must be backward compatible with the plugin
   that is still running ("expand, then contract"): add columns and tables freely, and drop or rename them only in a
   later release, after the code that used them is gone.
2. **Web app** next: step 5.
3. **Plugin** last, in a short announced maintenance window:
   `mcrcon … "say Restarting for an update in 5 minutes"`, then `systemctl stop minecraft`, run the world backup,
   swap the jar, add any new `config.yml` keys from the release notes, and `systemctl start minecraft`.

**Rollback:**

| What | How |
|---|---|
| Web app | `ln -sfn /var/www/knk/releases/<previous> /var/www/knk/current` (instant) |
| API (no migration in the release) | set `KNK_VERSION=<previous>` in `/opt/knk/.env`, `docker compose up -d api` |
| API (with a migration) | prefer **rolling forward** with a fix. If you must go back: stop the API, restore the pre-deploy dump (§ 12.4), start the previous version. EF `Down()` migrations exist, but restoring the backup is the tested path. |
| Plugin | put the previous jar back and restart |

---

## 11. First-run checklist

Tick these in order; write problems and fixes into a dated note under `docs/reports/`.

**A. Preparation (on your PC)**

- [ ] The § 2 blockers G1 and G2 are fixed or worked around. You have decided on each should-fix item (fix now, or
      accept for the beta).
- [ ] Trunk is green in CI in all three repos. Release tags are created and the release manifest is written (§ 10.2).
- [ ] Artifacts exist: the API runtime and migrator images in GHCR, the web build tarball, the plugin jar.
- [ ] The dev DB is migrated to the release's schema. The content review (§ 7.3) is done. The dev DB is backed up.
- [ ] World choice A or B is made (§ 7.4). The seed is exported and `manifest.txt` row counts are reviewed. For B,
      the world and WorldGuard folders are copied at the same time.
- [ ] Every secret in § 4.2 is generated and stored in the password manager.

**B. Host**

- [ ] SSH works with keys only, root login is off, unattended-upgrades and fail2ban are on (§ 3.1).
- [ ] Docker, nginx, certbot, the MySQL client and Java 21 are installed (§ 3.2). The directories exist with the right
      owners (§ 3.3).
- [ ] ufw allows only 22/80/443/25565. An external `nmap` scan shows nothing else open (§ 3.4).
- [ ] DNS `play.` and `mc.` resolve to the server (`dig +short play.example.com`).

**C. Database**

- [ ] `/opt/knk/compose.yaml`, `/opt/knk/.env` and `/etc/knk/*` (mode 600) are in place.
- [ ] `docker compose up -d db` shows `healthy`.
- [ ] Database `knk_prod` exists, plus users `knk_migrator` (all privileges on it) and `knk_app` (DML only) (§ 5.2).
- [ ] `docker compose run --rm migrator` ends with `Done.` In the database, `__EFMigrationsHistory` has the release's
      count and latest id, and `information_schema.triggers` shows 4 triggers.
- [ ] The seed is imported with `import-seed.sh` and its success line, **before** the API's first start (§ 7.6).
- [ ] `knk-db-backup` ran once by hand, its file passes `gunzip -t`, cron is installed, and the off-site copy is set up.

**D. API**

- [ ] `docker compose up -d api`. The log shows every startup seed `complete`, with nothing or little created after a
      seed import, and no `PluginApiKey is not set` warning.
- [ ] `curl 127.0.0.1:5000/health/ready` → `healthy`, and `curl 127.0.0.1:5000/api/health` → `ok`.
- [ ] `curl -H 'Host: evil.example.org' 127.0.0.1:5000/api/health` → **400** (the AllowedHosts filter works).
- [ ] **[KNG-64]** `scripts/security/alpha-probe.sh http://127.0.0.1:5000 --player '<test login>:<password>'` (a non-staff
      throwaway account) prints `ALL CHECKS PASSED`.

**E. Web app and TLS**

- [ ] The release is unpacked, `current` points to it, `nginx -t` passes, and nginx is reloaded.
- [ ] certbot issued the certificate and the HTTP → HTTPS redirect works. `certbot renew --dry-run` passes.
- [ ] `https://play.example.com/` loads. A deep link `https://play.example.com/auth/login` loads (SPA fallback).
      `https://play.example.com/health/live` → 403.
- [ ] The browser dev tools Network tab shows API calls going to `https://play.example.com/api/...`, **not**
      `localhost:5294` (G1).
- [ ] Register your account, log in with "remember me", close the browser, reopen it, and you're still logged in
      (refresh cookie over HTTPS). **[KNG-64]:** registration needs the `/account link` code (§ 6.5). Without
      "remember me" you're logged out when the browser closes.
- [ ] **[KNG-64]** Run the probe script against `https://play.example.com` too.
- [ ] Forgot-password sends a real email whose link opens `/auth/reset-password?token=…` on the production domain,
      and the reset works.
- [ ] First admin bootstrapped (§ 6.5). The admin pages load. Forms → the entity types show their seeded
      FormConfigurations.

**F. Minecraft server**

- [ ] Paper's checksum is verified, the EULA is accepted, and `server.properties` has `online-mode=true`, the
      whitelist on and RCON on loopback only (§ 9.3).
- [ ] WorldEdit and WorldGuard are the same versions as dev. The KnightsAndKings jar is installed and `config.yml` has
      the API key, `allow-untrusted-ssl: false`, and mode 600 (§ 9.5).
- [ ] `systemctl start minecraft`. The log shows KnightsAndKings enabled with no stack traces.
- [ ] `/knk health` reports the API up, and `/knk cache refresh` works.
- [ ] Join with your own account: you get the Default kit (`GrantOnFirstJoin`) and a user row with your UUID.
      `/account link` → link the code in the web app → the web account page shows your Minecraft name.
- [ ] `op` only yourself. A second test account without op can do player things (`/balance`, `/spawn`, `/kit`) and
      is refused admin commands.
- [ ] One feature end to end per area: a teleport (`/spawn`), `/pay` between two accounts (the ledger works), a gate
      open/close (copied world), opening a lootbox if one is enabled, and the siege lobby list.
- [ ] From outside, port 8081 is closed (`nmap -p 8081 <ip>`).
- [ ] `knk-world-backup` ran once and its archive opens.

**G. Go-live**

- [ ] **Restore drill done:** you restored last night's DB dump into a scratch database and counted rows (§ 12.4).
- [ ] Monitoring is on: an uptime check for `https://play.example.com/api/health` and the Minecraft port, and alerts
      reach your phone (§ 12.3).
- [ ] The release manifest is committed, and `ACTIVE_SESSIONS.md` / Linear updated.
- [ ] Whitelist the beta players and announce the server address.

---

## 12. Day-2 operations

### 12.1 Updating the platform

| What | How often | How |
|---|---|---|
| OS security patches | automatic (unattended-upgrades) | reboot monthly in a maintenance window: `sudo needrestart` / `sudo reboot` |
| MySQL patch (8.4.x) | quarterly | backup → change the image tag → `docker compose up -d db` |
| .NET runtime patches | monthly ("Patch Tuesday") | rebuild the API image (CI on a new patch tag) and deploy |
| Paper builds | when needed (security or bug fixes) | test on staging, swap the jar in a maintenance window |
| Minecraft version (1.21.10 → next) | a project of its own | plugin, WorldEdit and WorldGuard all have to support it first |

### 12.2 Logs

- API: `docker compose logs --since 1h api`. Docker keeps the logs; cap them in `/etc/docker/daemon.json` with
  `{"log-driver":"json-file","log-opts":{"max-size":"20m","max-file":"5"}}`.
- Paper: `journalctl -u minecraft` and `/srv/minecraft/logs/`.
- nginx: `/var/log/nginx/access.log` and `error.log`.
- Backups: `/var/log/knk-backup.log`.

### 12.3 Monitoring (minimum viable)

- **External uptime check** (UptimeRobot, Better Stack, Healthchecks.io, or self-hosted Uptime Kuma): HTTPS
  `https://play.example.com/api/health` every minute, a TCP check on `mc.example.com:25565`, and a *heartbeat* the
  backup script pings at the end, which alerts when the backup didn't run.
- **Disk space:** a full disk is the most common cause of a dead MySQL. Alert at 80%.
- **Later:** the API has OpenTelemetry built in. Run an OTel collector + Prometheus + Grafana (or a hosted service),
  point `Telemetry__Otlp__Endpoint` at it and set `Telemetry__Enabled=true`. The currency monitor already raises
  in-game alerts for ledger anomalies (`CurrencyMonitor:*`).

### 12.4 Restore drill (quarterly, and before every risky migration)

```bash
cd /opt/knk
f=$(ls -t /var/backups/knk/db-*.sql.gz | head -1)
gunzip -c "$f" | sed 's/`knk_prod`/`knk_restore_test`/g' \
  | docker compose exec -T db sh -c 'mysql -uroot -p"$(cat /run/secrets/mysql_root_password)"'
docker compose exec -T db sh -c 'mysql -uroot -p"$(cat /run/secrets/mysql_root_password)" -e "
  SELECT COUNT(*) FROM knk_restore_test.__EFMigrationsHistory;
  SELECT COUNT(*) FROM knk_restore_test.users;
  DROP DATABASE knk_restore_test;"'
```

A real restore uses the same pipe without the `sed`, with the API stopped. The world restore unpacks the matching
`minecraft-*.tar.gz` with Paper stopped.

### 12.5 Incident basics

- Something is broken after a deploy → roll back first (§ 10.6), debug second.
- A secret has leaked → rotate it (§ 4.2), restart the affected services, and check `audit_log_entries` and the
  currency alerts for misuse.
- Keep a short dated incident note under `docs/reports/` (what happened, impact, fix, prevention).

---

## Appendix A — what was verified and how

The steps below were rehearsed on 2026-10-07 in an isolated scratch environment, using Docker containers with
throwaway credentials. Nothing touched the dev DB or any real server.

| Check | Result |
|---|---|
| Build the API image from knk-web-api `master` `1805cf9` (§ 6.1 Dockerfile, `runtime` + `migrator` targets) | ✅ |
| `dotnet ef migrations bundle` | ❌ runs the startup seeds before migrating → `Table … EnchantmentDefinitions doesn't exist` (G7) |
| `dotnet ef migrations script --idempotent`, applied with the mysql client | ❌ `ERROR 1303 Can't create a TRIGGER from within another stored routine` (G7) |
| `dotnet ef database update` as a non-root user, binary logging on, without `log_bin_trust_function_creators` | ❌ fails at `AddCurrencyLedgerImmutabilityTriggers` (SUPER privilege) |
| Same with `log_bin_trust_function_creators=1`, MySQL **8.0** and **8.4.11** | ✅ 61 migrations, 4 triggers |
| API in Production mode on a DML-only `knk_app` user; all startup seeds | ✅ |
| Registration, login, refresh cookie `Secure; SameSite=None; HttpOnly` | ✅ |
| First admin via `PUT /api/PermissionGrants/by-node` + `X-API-Key` (401 without the key), then an admin-only write with the JWT | ✅ |
| `AllowedHosts` filter (public name 200, loopback 200, unknown host 400) | ✅ |
| `export-seed.sh` → `import-seed.sh` into a freshly migrated DB: content and group grants copied, no users or user grants; startup seeds then created nothing; the first new user got id 7, the Default group and the signup grant; re-import refused once a user existed | ✅ |
| `docker compose` stack from § 5.1 (healthcheck, `migrate` profile, host-network API on loopback) | ✅ |
| Nightly-dump command and restore into a scratch DB (migration history, triggers, data) | ✅ |
| Web app: `npm ci` | ❌ lock file out of sync (G2) |
| Web app: `CI=true npm run build` / `CI=false npm run build` with `baseUrl: '/api'` | ❌ lint warnings (G3) / ✅ 280 kB gzipped JS |
| nginx config from § 8.3: SPA fallback, `/api` proxy + login cookie, `/health` denied, cache and security headers | ✅ (after fixing the `add_header` inheritance trap now noted in the config) |
| Plugin jar build | ⚠️ not reproduced in the sandbox (Maven Central rate-limited it); GitHub CI `Build` is green on knk-plugin `main` `c7d5a1e` |
| Paper download API for 1.21.10 | ✅ build 130 resolved with a SHA-256 |
| Paper server, plugin ↔ API on a live server, TLS issuance, GitHub Actions workflows | ⏳ not tested; do them on staging first |

## Appendix B — reference files

| File | Purpose |
|---|---|
| [`scripts/seed/seed-tables.sh`](../../scripts/seed/seed-tables.sh) | table manifest: content / group-filtered / world / runtime |
| [`scripts/seed/export-seed.sh`](../../scripts/seed/export-seed.sh) | export the seed data set from the dev DB |
| [`scripts/seed/import-seed.sh`](../../scripts/seed/import-seed.sh) | load it into a new production DB (guarded, one transaction) |
| knk-web-api `Program.cs` | config binding, startup seeds, CORS, health |
| knk-web-api `appsettings.json` | every default the env file overrides |
| knk-web-api `.github/workflows/migrations.yml` | the fresh-DB migration check CI already runs |
| knk-web-app `src/config/appConfig.ts` | the compiled-in API URL (G1) |
| knk-plugin `knk-paper/src/main/resources/config.yml`, `plugin.yml` | plugin settings, commands and permission nodes |
| knk-plugin `.github/workflows/build.yml` | plugin CI |
