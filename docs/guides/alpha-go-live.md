# Knights and Kings — closed alpha go-live (KNG-64 layer on the NAS runbook)

**Status:** v2, aligned 2026-10-11 with the [closed-alpha deployment runbook](closed-alpha-deployment-runbook.md)
(the Codex NAS rollout). Not yet followed end to end.
**Last updated:** 2026-10-11
**Applies to:** builds that **include KNG-64**: knk-web-api `master` ≥ `30c5dc5`, knk-web-app `main` ≥ `98c0a76`,
knk-plugin `main` ≥ `34c9261`. **Never expose an older API.**
**Linear:** [KNG-64](https://linear.app/kngpandi/issue/KNG-64) (parent), [KNG-68](https://linear.app/kngpandi/issue/KNG-68) (this guide)
**Sources:** the [alpha hardening plan](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md) (§ 3 hosting, § 7 config, § 9
verification), the [production installation guide](production-installation.md), the
[NAS progress report](../reports/2026-10-11-closed-alpha-infrastructure-progress.md).

**Two documents, one rollout.** The [runbook](closed-alpha-deployment-runbook.md) owns the NAS work: backups, Portainer,
the `knk-alpha` stack, the alpha database, images, the Minecraft container, playit.gg, ingress and backup automation.
This guide owns what KNG-64 requires on top of it: which builds may go live, their configuration, the first admin, the
security probe and the go-live checklist. For infrastructure choices, the runbook wins. This guide wins for security
requirements.

---

## 1. What you're building

```
Tester's browser ──HTTPS──► Cloudflare edge ── Access: "is this an invited email?" (one-time PIN)
                                  │  Cloudflare Tunnel (outbound-only; no open HTTP ports)
                                  ▼
                      nginx ── /      → web app build (static files)
                            └─ /api/* → api:5000
NAS, stack knk-alpha (Portainer)
  api  (knk-web-api, private network only) ──► mysql (MySQL 9.6, private, never published)
  minecraft (Paper 1.21.10, main + hub world) ──► http://api:5000/api   (X-API-Key)
  api ──► http://minecraft:8081   (region callbacks, X-API-Key; never published)
  playit agent ──► minecraft:25565

Minecraft client ──► play.knightsandkings.net ──► playit.gg tunnel ──► playit agent
```

- **No inbound ports on the router.** Cloudflare Tunnel carries the web/API traffic and playit.gg carries Minecraft.
  Both dial out.
- **Two walls on the web.** Cloudflare Access only lets invited emails reach the site. Behind it, the hardened API checks
  every request.
- **One origin.** The SPA and `/api` share one hostname, so there's no CORS, and both the refresh cookie and the Access
  cookie are first-party.
- **Kill switches.** Stop `cloudflared` (or drop a tester from the Access policy) and the site is offline. Stop the
  playit agent and nobody can join. Each one leaves the other side running.

### 1.1 What changed since draft v1 (2026-10-08)

| Topic | Draft v1 | Now (runbook decisions, 2026-10-11) |
|---|---|---|
| Minecraft ingress | Router port-forward 25565, grey-cloud A record | **playit.gg** agent as a Compose service, GoDaddy `play.knightsandkings.net` → the playit hostname (runbook Phase 5) |
| Alpha data | Fresh DB + seed export/import | **Sanitized copy of the dev DB** (`knightsandkings_alpha`, only `__pandi__` and `admin` active; runbook Phase 2). The seed scripts stay the path for the VPS. |
| Paper host | PC or NAS, API on a LAN port | **Paper in the `knk-alpha` stack**: the plugin and API talk over service DNS, and no API port exists on the LAN |
| MySQL | 8.4 | 9.6.0 (pinned digest, runbook Phase 2) |
| Worlds | Dev map only | Main gameplay world + the converted hub (`knk_hub`), with a KnK-owned loader and no Multiverse (KNG-114) |
| Web hostname | `app.knightsandkings.net` | **Undecided.** The runbook mentions the earlier `knk.oldenzeelit.nl`. Pick one before building the web app (§ 6), because it goes into four settings. Below it's called `<web-host>`. |

---

## 2. Builds that may go live

| Repo | Minimum | On the NAS today | Action |
|---|---|---|---|
| knk-web-api | `master` ≥ `30c5dc5` (KNG-64 merge) | `knk-web-api:alpha-17ee730a`: **before KNG-64.** It's private, so nothing is exposed yet | Upgrade first (§ 3) |
| knk-web-app | `main` ≥ `98c0a76` | not built | Build in runbook Phase 6 (§ 6) |
| knk-plugin | `main` ≥ `34c9261`, plus the KNG-114 hub loader | not built | Build in runbook Phase 4 (§ 5). Take KNG-128/129 (new-player onboarding) if they're merged by then |

Build from the **current** trunk head at the moment you package, and record the exact commit, as the runbook does for
`17ee730a`.

---

## 3. Upgrade the alpha API to KNG-64 (runbook Phase 3b)

The running image predates KNG-64. It doesn't have the default-deny API, refresh sessions, code-based signup,
rate limits or the permission-escalation guard. Do this before the plugin connects (Phase 4) and before any ingress.

1. **Back up** `knightsandkings_alpha` with a new dated dump next to the clean baseline. Keep the baseline.
2. **Check for a holder-id clash.** The alpha DB comes from a dev dump taken at 00:20 on 2026-10-11, before the
   smoke test found and repaired the `admin` / Staff clash in dev. `admin` kept id 29 there, so check:
   ```sql
   SELECT u.Id, u.Username, g.Name FROM users u JOIN permission_groups g ON g.Id = u.Id;
   ```
   If it returns a row, run [`scripts/maintenance/repair-holder-id-clash.sql`](../../scripts/maintenance/repair-holder-id-clash.sql)
   with the MySQL client inside the `knk-alpha-mysql` container, as root, the same way as in Phase 2. Run it once
   per row until `clashes_left` is 0. Afterwards the user keeps its id and memberships, the group moves to a new
   id with its grants, and the user has no direct grants. Without the repair, assigning a group to `admin` fails
   with a 500 error (`InvalidCastException`), and Staff's grants also apply to `admin`.
3. **Build** from a source archive of `master` ≥ `30c5dc5`. Use the same deployment Dockerfile, keeping the
   `KNK_RUNTIME_UID`/`KNK_RUNTIME_GID` fix, and tag it `knk-web-api:alpha-<sha>`. From the same source, also build a
   **migrator** image: the SDK stage plus `dotnet-ef`, with entrypoint `dotnet ef database update`
   ([production guide § 6.1](production-installation.md#61-the-container-image), target `migrator`).
4. **Migrate.** Stop the API. Run the migrator once on `knk-alpha_backend`, with a connection string for an account
   that has schema rights. That's root for this one run, unless the stack has a migrator user; `knk_alpha_app`
   should stay rows-only. Feed the secret through the same wrapper as the API and never on the command line. It applies:
   - `20261008083025_AddRefreshTokensAndTokenVersion` (sessions: the `refresh_tokens` table plus a token version
     per user; every existing session ends once);
   - `20261010121436_AddDomainWorldName` (KNG-111: each Domain stores its world; the plugin's region report fills in the old ones).

   Both have **older timestamps** than the database's newest migration (`20261010170000_SeedStatisticsStaffNodes`).
   `database update` applies them anyway, but `dotnet ef migrations script <from>` would **skip** them, so don't use
   that. Expect **78** rows in `__EFMigrationsHistory` afterwards.
5. **Configure** the additions in § 4, switch the image tag in the stack and start the API. Accept it as in
   Phase 3.3: both health endpoints return 200, startup and restart are idempotent, and no secrets appear in the
   log. The log must also have no `PluginApiKey is not set` warning and no `Security:Jwt:Secret` error.
6. **Take a new clean baseline dump**, because the schema changed. Record its SHA-256 in a new dated progress report.

---

## 4. API configuration for the alpha

The runbook's Phase 3.2 keys stay (`ConnectionStrings__MySqlDbConnection`, `Security__PluginApiKey`,
`Security__Jwt__Secret` from secret files, `Database__MySqlServerVersion=9.6.0`, `ASPNETCORE_ENVIRONMENT=Production`).
KNG-64 adds:

```ini
AllowedHosts=<web-host>;api;localhost               # public name + the service name the plugin uses
Security__AllowUnauthenticatedPluginCalls=false     # already set
Security__PasswordResetFrontendBaseUrl=https://<web-host>
Security__PasswordResetExposeTokenInDevelopment=false
Security__Registration__AllowWebFirst=false         # players sign up with an in-game code only
Security__RefreshCookie__SameSite=Lax

# Client IPs for rate limits, lockout and logs. Trust only the nginx that proxies /api. Docker IPs change on
# recreate, so trust the subnet of the network nginx shares with the API, or give nginx a fixed address.
ForwardedHeaders__Enabled=true
ForwardedHeaders__KnownNetworks=<subnet nginx shares with api, e.g. 172.30.0.0/24>

# Region callbacks to the plugin's RegionHttpServer, over service DNS (the plugin binds 0.0.0.0 inside its container).
MinecraftPlugin__BaseUrl=http://minecraft:8081

# The backend network has no internet access, so SMTP can't work there. Use Log: reset links go to the API log,
# and you relay them. To send real mail, give the API an egress network and Email__SmtpPassword from a secret file.
Email__Provider=Log
Telemetry__Enabled=false                            # already set
```

`Cors__AllowedOrigins` stays empty: the browser only talks to its own origin.

---

## 5. Minecraft and plugin (runbook Phases 4–5)

**`server.properties`:** `online-mode=true`, `white-list=true`, `enforce-whitelist=true`. Add the testers with
`whitelist add <name>`. playit makes the server reachable from anywhere, so the whitelist is the gate.

**Plugin `plugins/KnightsAndKings/config.yml`:** a config.yml copied from the dev server keeps its old values. Set
these by hand:

```yaml
api:
  base-url: "http://api:5000/api"        # service DNS, never localhost
  allow-untrusted-ssl: false
  auth:
    type: apikey
    api-key: "<Security__PluginApiKey>"  # from the secret file; same value as the API
    api-key-header: "X-API-Key"
region-http:
  bind-address: "0.0.0.0"                # inside the container only: never publish 8081
  port: 8081
web:
  public-url: "https://<web-host>"       # /account link shows <web-host>/auth/register
```

Checks:
- The startup log shows `RegionHttpServer listening on 0.0.0.0:8081 (X-API-Key required)`, and there's no warning about a missing
  `web.public-url`.
- `/knk health` shows the API as UP.
- The API log has no 401 or 403 for plugin calls.

**Networks:**
- The Minecraft container needs `knk-alpha_backend` (to reach the API) and also a network with internet access
  (Mojang session servers).
- The playit agent needs internet access and must reach `minecraft:25565`.
- Publish no ports on the NAS for any of these.

**playit.gg:**
- Follow runbook Phase 5.
- If the tunnel gets a non-default port, add an SRV record `_minecraft._tcp.play`, so testers can still type
  `play.knightsandkings.net`.
- Paper sees playit's address, not the player's. If your playit tunnel offers Proxy Protocol, enable it there and in
  Paper's `config/paper-global.yml` (`proxies.proxy-protocol: true`) so that bans and logs see real IPs. Enable
  either both or neither.

---

## 6. Web app and ingress (runbook Phase 6)

**Build:**

```bash
# in knk-web-app at the main commit you package
REACT_APP_API_BASE_URL=/api REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net CI=false npm run build
```

**nginx:** the server block for `<web-host>`. nginx has to share a network with `api`: attach the existing
`core`-stack nginx to an alpha network, or add a small nginx container to the `knk-alpha` stack that `cloudflared`
reaches.

```nginx
server {
    listen 80;
    server_name <web-host>;
    root /usr/share/nginx/html;          # the build/ output
    index index.html;

    location /api/ {
        proxy_pass http://api:5000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        # cloudflared passes the real client IP as CF-Connecting-IP; hand it to the API as X-Forwarded-For.
        proxy_set_header X-Forwarded-For   $http_cf_connecting_ip;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Upgrade           $http_upgrade;     # ready for SignalR (KNG-57)
        proxy_set_header Connection        $http_connection;
        client_max_body_size 10m;
    }

    location /health/ { deny all; }
    location /static/ { expires 1y; try_files $uri =404; }
    location / { expires -1; try_files $uri /index.html; }      # SPA deep links (/auth/register, /auth/reset-password)

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header X-Frame-Options DENY always;
}
```

**Cloudflare Tunnel:** add a public hostname `<web-host>` → `http://<nginx>:80` on the existing tunnel.

**Cloudflare Access:** add a Self-hosted application for the **whole** `<web-host>`. The policy *Allow testers*
includes each tester's email, with One-time PIN login and a 24-hour session. This is plan decision D10: for a closed
alpha the allow-list covers the whole site, not only the admin pages. The plugin talks to `api` inside Docker, so
Access never stands in its way. For the probe from outside, add a service token (Access → Service Auth) and a
*Service Auth* policy.

**Zone settings (free plan):**
- SSL/TLS **Full**, *Always Use HTTPS*.
- HSTS after the first successful visit.
- One WAF rate-limiting rule: path starts with `/api/Auth/`, more than 30 requests per 10 s per IP → block for 10 s.
- Bot Fight Mode **off** for this host.

---

## 7. First admin and roles

The alpha DB already has the two accounts the runbook kept: `__pandi__` (Admin, Noble) and `admin` (Admin, Default).
No bootstrap is needed.

1. Log in on `https://<web-host>` with your existing credentials. The KNG-64 migration ended old sessions, so expect
   one fresh login.
2. Check the groups in `/admin/users`:
   - **Admin** holds `knk.admin.*`, or `*` for owners only.
   - **Weights** rank the staff groups (Admin > Moderator > Staff). Staff can only hand out or remove groups below
     their own highest rank.
   - Give Admin `knk.admin.user.group.premium` if admins should hand out premium ranks without holding their perks.
3. Give staff testers a role, never `*`.
4. Create one **non-staff test account** for the probe (§ 8). The probe logs it out everywhere.

If you ever need a fresh owner (for example, after rebuilding the DB from the seed), use the production guide § 6.5
bootstrap with the plugin key, from a container on `knk-alpha_backend`.

---

## 8. Security probe

Run [`scripts/security/alpha-probe.sh`](../../scripts/security/alpha-probe.sh). It needs only bash and curl.

- **Privately, before ingress.** On the NAS, run it from the pinned .NET SDK image, which is already pulled and has
  bash and curl:
  ```bash
  docker run --rm --network knk-alpha_backend -v "$PWD/scripts/security:/s:ro" --entrypoint bash \
    mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim /s/alpha-probe.sh http://api:5000 --player '<test>:<password>'
  ```
- **Through Cloudflare, after ingress** (from your PC):
  `scripts/security/alpha-probe.sh https://<web-host> --player '<test>:<password>' --cf-id <id> --cf-secret <secret>`.

Both must end with `ALL CHECKS PASSED`. The last check trips the login rate limiter for about a minute.

---

## 9. Go-live checklist

**A. Code**
- [ ] The API runs a KNG-64 build (`master` ≥ `30c5dc5`), and 78 migrations are applied (§ 3).
- [ ] The web app and plugin come from KNG-64 builds (§ 2). The plugin has the KNG-114 loader.

**B. Secrets and config**
- [ ] The secret files are mode 600 and owned by the runtime UID, and no value appears in Compose, Portainer or logs (runbook).
- [ ] The dev DB password is rotated (it was committed before KNG-64), and the dev machines use `dotnet user-secrets`.
- [ ] The API has the § 4 keys: `ForwardedHeaders` trusts only the nginx network, and `AllowWebFirst=false`.
- [ ] The plugin has `api.auth.type: apikey`, `region-http.bind-address: "0.0.0.0"` with 8081 unpublished, and
      `web.public-url`.

**C. Data**
- [ ] The holder-id clash query returns no rows.
- [ ] A clean baseline dump exists **after** the KNG-64 migrations, and one restore was rehearsed (runbook Phase 7).

**D. Services**
- [ ] mysql, api and minecraft are healthy. No ports are published except through cloudflared and playit.
- [ ] `https://<web-host>` shows the Access login, then the landing page after the PIN. A deep link (`/auth/login`)
      loads.
- [ ] An outside client joins via `play.knightsandkings.net` with no router port-forward.
- [ ] From outside (a phone hotspot), `nmap -p 80,443,3306,5000,8081,25565,25575 <home-ip>` shows everything closed
      or filtered.

**E. Security probe**
- [ ] Private and Cloudflare runs: `ALL CHECKS PASSED` (§ 8).

**F. Player flow (a tester or a second account)**
- [ ] A whitelisted player joins, and `/account link` shows the code (click to copy) and `https://<web-host>/auth/register`.
      They register with the code and land on the account page, logged in.
- [ ] Log in with the Minecraft name and log out on a phone.
- [ ] A Moderator can't grant `*` or reach the content tools, while an Admin can assign Staff and Moderator.
- [ ] A password change in browser B logs out browser A.

**G. Communication**
- [ ] The tester invite is sent (§ 10), together with how to report bugs.
- [ ] `ACTIVE_SESSIONS.md` and Linear are updated, and a dated go-live note is added under `docs/reports/`.

---

## 10. Tester invite (template)

> Welcome to the **Knights & Kings closed alpha**!
> 1. Join the Minecraft server **play.knightsandkings.net** (Java Edition 1.21.10). Your name is on the whitelist.
> 2. In game, type `/account link`. You get an 8-character code (click it to copy).
> 3. Open **https://<web-host>**, enter this email address to get a one-time PIN, then choose **Create account** and
>    enter the code, your email and a password.
> 4. From then on, you can log in with your Minecraft name or your email.
>
> Found a bug or something confusing? Send it to <channel> with what you did, what you expected, and a screenshot.

---

## 11. Running the alpha

- **Backups, restore rehearsal, upgrades:** runbook Phases 7–8. For an API release with a migration: back up, run the
  migrator, then the API, then the web app, then the plugin (production guide § 10.6 order).
- **Logs:** for the API, failed logins and lockouts carry the client IP from Cloudflare (via `ForwardedHeaders`).
- **Kill switches:** stop `cloudflared` or edit the Access policy for the web; stop the playit agent for Minecraft.

## 12. Moving on from the alpha

Before an **open beta**:
- Move to a VPS (production guide § 1.3 onwards), with the seed export/import instead of a dump copy.
- Drop the Access allow-list, or keep it for `/admin` only.
- Add email verification (plan § 12) and CI-built images (guide § 10).
- Decide on a public static site at `knightsandkings.net`.
