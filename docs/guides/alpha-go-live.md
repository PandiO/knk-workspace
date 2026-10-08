# Knights and Kings — closed alpha go-live (NAS + Cloudflare Tunnel)

**Status:** Draft v1. Not yet followed on the real NAS. The commands are standard Docker and Cloudflare Zero Trust
usage, adapted from the rehearsed parts of the production guide.
**Last updated:** 2026-10-08
**Applies to:** builds that **include KNG-64** (the alpha hardening branch `claude/ui-ux-assessment-discussion-66vc2l`
merged into knk-web-api `master`, knk-web-app `main` and knk-plugin `main`). **Never expose an older API.**
**Linear:** [KNG-64](https://linear.app/kngpandi/issue/KNG-64) (parent), [KNG-68](https://linear.app/kngpandi/issue/KNG-68) (this guide)
**Sources:** the [alpha hardening plan](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md) (§ 3 hosting, § 7 config, § 9
verification) and the [production installation guide](production-installation.md), whose sections this guide reuses
instead of repeating them.

This is the runbook for the **closed alpha**: a select group of players, the web app at `app.knightsandkings.net`,
everything hosted on the NAS, and nothing reachable from the internet except through Cloudflare. It ends in a
[go-live checklist](#9-go-live-checklist).

---

## 1. What you're building

```
Tester's browser ──HTTPS──► Cloudflare edge ── Access: "is this an invited email?" (one-time PIN)
                                  │  outbound-only tunnel; no open HTTP ports on your router
                                  ▼
NAS (Docker network knk-alpha, 172.30.0.0/24)
  cloudflared ──► web (nginx 172.30.0.10)  /        → web app build (static files)
                                            /api/*   → api:5000
                  api (knk-web-api) ──► db (MySQL 8.4, data volume, never published)
                  api :5000 also published on the NAS LAN IP, firewalled to the Paper host only

Paper server (NAS or PC) ──LAN──► http://<nas-lan-ip>:5000/api   (X-API-Key)
Minecraft clients ──TCP 25565──► router port-forward ──► Paper   (whitelist on, online-mode on)
```

Why this shape (plan § 3):
- **No inbound HTTP ports.** `cloudflared` dials out to Cloudflare, and Cloudflare also terminates TLS.
- **Two walls.** Cloudflare Access only lets invited emails reach the site at all. Behind it, the hardened API checks
  every request.
- **One origin.** The SPA and `/api` share `app.knightsandkings.net`: no CORS, and the refresh cookie and the Access cookie
  are first-party.
- **Kill switch.** `docker stop knk-alpha-cloudflared-1` takes the site offline instantly. Minecraft keeps running.

---

## 2. Prerequisites

- [ ] **The KNG-64 PRs are merged** in all three repos, and you've run the plan's live checks (§ 9) on your dev setup.
- [ ] **Cloudflare account** with `knightsandkings.net` added as a zone, and the registrar's nameservers pointed at
      Cloudflare (Cloudflare → *Add a site* → Free plan → it shows two nameservers to set at your registrar).
- [ ] **Zero Trust** enabled on that account (Cloudflare dashboard → *Zero Trust*, free plan, pick a team name).
- [ ] **NAS** with Docker / Container Manager, about 3 GB of free RAM, SSD storage if possible. Check the CPU
      architecture (`uname -m`): `x86_64` → `linux/amd64` images, `aarch64` → `linux/arm64`. Every image used here
      exists for both.
- [ ] A **password manager** entry "KnK alpha" for the secrets in § 3.
- [ ] Your **router** can forward TCP 25565 (Minecraft), as you already do for the dev server, if testers join from
      outside.

---

## 3. Secrets for the alpha

Generate these on your PC and store them in the password manager first (production guide § 4.2 explains each one):

| Secret | Generate | Used by |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | `openssl rand -base64 32` | db container |
| `KNK_DB_APP_PASSWORD` (user `knk_app`, rows only) | `openssl rand -base64 32` | API |
| `KNK_DB_MIGRATOR_PASSWORD` (user `knk_migrator`, schema) | `openssl rand -base64 32` | migrations, seed import |
| `Security__Jwt__Secret` | `openssl rand -base64 48` | API (the API refuses placeholder or committed values) |
| `Security__PluginApiKey` | `openssl rand -hex 32` | API **and** plugin `api.auth.api-key` (identical) |
| `TUNNEL_TOKEN` | Cloudflare (§ 6.1) | cloudflared |
| Gmail app password (optional) | Google account → App passwords | password-reset mail |

> **Rotate the dev DB password now.** Before KNG-64 it was committed in `knk-web-api/appsettings.json`. After
> rotating, give your dev machines the new value with
> `dotnet user-secrets set "ConnectionStrings:MySqlDbConnection" "Server=…;Password=<new>;…"` in the knk-web-api folder.

---

## 4. Files on the NAS

Pick a folder on the NAS's SSD volume, e.g. `/volume1/docker/knk-alpha/`. Below it's called `$ALPHA`.

```
$ALPHA/
  compose.yaml
  api.env              # mode 600 — API config + secrets
  db.env               # mode 600 — MYSQL_ROOT_PASSWORD
  cloudflared.env      # mode 600 — TUNNEL_TOKEN
  nginx/default.conf
  web/                 # the web app build (index.html, static/, images/…)
  backups/
```

### 4.1 `compose.yaml`

```yaml
name: knk-alpha

networks:
  knk:
    ipam:
      config:
        - subnet: 172.30.0.0/24          # fixed, so the API can trust exactly one proxy IP

services:
  db:
    image: mysql:8.4
    restart: unless-stopped
    command: ["--character-set-server=utf8mb4", "--collation-server=utf8mb4_0900_ai_ci",
              "--log-bin-trust-function-creators=1"]      # needed by the ledger-trigger migration (guide § 5.2)
    env_file: db.env
    volumes: ["db-data:/var/lib/mysql"]
    networks: [knk]
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p\"$$MYSQL_ROOT_PASSWORD\" --silent"]
      interval: 10s
      retries: 12
    # no "ports:" — MySQL is never published. For admin access use: docker compose exec db mysql …

  api:
    image: ghcr.io/pandio/knk-web-api:${KNK_VERSION:?set KNK_VERSION}   # or a locally built tag, § 5.2
    restart: unless-stopped
    env_file: api.env
    depends_on: { db: { condition: service_healthy } }
    networks: [knk]
    ports:
      - "<NAS-LAN-IP>:5000:5000"         # for the Paper server on the LAN; firewall it to the Paper host (§ 7)

  web:
    image: nginx:1.27-alpine
    restart: unless-stopped
    volumes:
      - ./web:/usr/share/nginx/html:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on: [api]
    networks:
      knk: { ipv4_address: 172.30.0.10 }
    # no "ports:" — only cloudflared reaches it

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    env_file: cloudflared.env             # TUNNEL_TOKEN=…
    depends_on: [web]
    networks: [knk]

volumes:
  db-data:
```

If the Paper server runs **on the NAS itself** in this compose project, drop the API `ports:` line and point the
plugin at `http://api:5000/api`.

### 4.2 `api.env`

Everything from production guide § 4.3 applies. These are the values that differ for the alpha:

```ini
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://0.0.0.0:5000
AllowedHosts=app.knightsandkings.net;<NAS-LAN-IP>;api;localhost

ConnectionStrings__MySqlDbConnection=Server=db;Port=3306;Database=knk_alpha;User=knk_app;Password=<KNK_DB_APP_PASSWORD>;Allow User Variables=True;

Security__Jwt__Secret=<openssl rand -base64 48>
Security__PluginApiKey=<openssl rand -hex 32>
Security__AllowUnauthenticatedPluginCalls=false
Security__PasswordResetFrontendBaseUrl=https://app.knightsandkings.net
Security__PasswordResetExposeTokenInDevelopment=false
Security__Registration__AllowWebFirst=false
Security__RefreshCookie__SameSite=Lax

# Client IPs for rate limiting, lockout and logs: nginx (172.30.0.10) is the only proxy we trust.
# nginx copies Cloudflare's CF-Connecting-IP into X-Forwarded-For (§ 4.3).
ForwardedHeaders__Enabled=true
ForwardedHeaders__KnownProxies=172.30.0.10

# Plugin region checks (RegionHttpServer). Use the Paper host's LAN IP when Paper isn't on the NAS,
# and set the plugin's region-http.bind-address to that same LAN IP (§ 7).
MinecraftPlugin__BaseUrl=http://<paper-host-lan-ip>:8081

Email__Provider=Log                      # or Smtp with the Gmail app password (guide § 4.3)
Telemetry__Enabled=false
```

### 4.3 `nginx/default.conf`

```nginx
server {
    listen 80;
    server_name app.knightsandkings.net;
    root /usr/share/nginx/html;
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
    location / { expires -1; try_files $uri /index.html; }      # SPA deep links (/auth/reset-password, …)

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header X-Frame-Options DENY always;
}
```

Lock the secret files down: `chmod 600 $ALPHA/*.env`.

---

## 5. Build and load

### 5.1 Database, migrations and seed

1. Start the database: `docker compose up -d db`, then wait until it shows `(healthy)` in `docker compose ps`.
2. Create the database and the two users. Use production guide § 5.2 with `knk_prod` replaced by **`knk_alpha`**. Run it with
   `docker compose exec -T db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'`.
3. Apply the migrations from your PC. The simplest path for the alpha: temporarily publish the DB to the LAN with an
   override file, or run the migrator image from production guide § 5.3 inside the `knk-alpha` network:
   ```bash
   # on the NAS, from $ALPHA, with the migrator image built from the same commit as the API:
   docker run --rm --network knk-alpha_knk \
     -e ConnectionStrings__MySqlDbConnection="Server=db;Port=3306;Database=knk_alpha;User=knk_migrator;Password=<…>;Allow User Variables=True;" \
     ghcr.io/pandio/knk-web-api-migrator:$KNK_VERSION
   ```
4. **Seed the content** (forms, menus, items, groups) from the dev DB with `scripts/seed/export-seed.sh` and
   `import-seed.sh` (production guide § 7). Do this **before the API's first start**. Choose a world, A or B (guide § 7.4):
   for an alpha on the dev map, B (`--with-world`) plus a copy of the world folders.

### 5.2 API image

The Dockerfile is in production guide § 6.1. Until CI publishes images (guide § 10), build on your PC at the merged
commit and copy the image to the NAS:

```bash
# in knk-web-api at the merged master commit; add --platform linux/arm64 for an ARM NAS
docker build --target runtime  -t knk-web-api:alpha1 .
docker build --target migrator -t knk-web-api-migrator:alpha1 .
docker save knk-web-api:alpha1 knk-web-api-migrator:alpha1 | gzip > knk-alpha1.tar.gz
# copy to the NAS, then on the NAS: docker load < knk-alpha1.tar.gz
```

Use `image: knk-web-api:alpha1` in `compose.yaml` (or set `KNK_VERSION`), then start it with `docker compose up -d api` and
check `docker compose logs -f api`. Expect the startup seeds and **no** `PluginApiKey is not set` warning. A
`Security:Jwt:Secret …` startup error means the secret is missing or a placeholder.

### 5.3 Web app

```bash
# in knk-web-app at the merged main commit
REACT_APP_API_BASE_URL=/api REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net CI=false npm run build
# copy build/* into $ALPHA/web/ on the NAS, then:
docker compose up -d web
```

---

## 6. Cloudflare

### 6.1 Tunnel

1. Zero Trust → **Networks → Tunnels → Create a tunnel** → *Cloudflared* → name it `knk-alpha` → choose **Docker**.
2. Copy only the token from the shown command into `$ALPHA/cloudflared.env` as `TUNNEL_TOKEN=<token>`.
3. **Public hostname:** subdomain `app`, domain `knightsandkings.net`, service type **HTTP**, URL `web:80`.
4. Start it with `docker compose up -d cloudflared`. The tunnel shows **Healthy** in the dashboard within a minute.

### 6.2 Access (the allow-list)

1. Zero Trust → **Settings → Authentication → Login methods**: make sure **One-time PIN** is enabled.
2. Zero Trust → **Access → Applications → Add an application → Self-hosted**:
   - Name `KnK alpha`, domain `app.knightsandkings.net` (the whole host, so `/api/*` is covered too), session
     duration **24 hours**.
   - Policy **Allow testers**: action *Allow*, include *Emails*, list each tester's email (or an *Email list* you
     maintain under Access → Lists).
3. Optional: a second policy, action **Bypass**, path `/api/health` only, if you use an external uptime monitor.
4. Optional, for the probe script from outside the LAN: Access → **Service Auth → Service Tokens → Create** →
   add a policy *Service Auth* including that token. Pass it to the probe with `--cf-id/--cf-secret`.

Testers open `https://app.knightsandkings.net`, enter their email, receive a PIN by email, and then reach the app.
They log in to KnK separately (two different logins: Cloudflare proves the invite, KnK proves the account).

### 6.3 Zone settings worth setting (free plan)

- SSL/TLS → **Full**; Edge Certificates → **Always Use HTTPS** on; **HSTS** on after the first successful visit
  (max-age 6 months, no preload yet).
- Security → **WAF → Rate limiting rules** (1 rule on the free plan): path starts with `/api/Auth/`, more than 30
  requests per 10 seconds per IP → block for 10 seconds. The API has its own limits; this rule stops floods at the edge.
- Leave **Bot Fight Mode off** for this hostname. It can challenge API calls from the SPA.

### 6.4 Minecraft DNS

Add `play.knightsandkings.net` as an **A** record → your home IP, **DNS only (grey cloud)**: the Cloudflare proxy
can't carry Minecraft. Forward TCP 25565 on the router to the Paper host. This reveals your home IP for the game
port only, as any self-hosted Minecraft server does.

---

## 7. Paper server and plugin

1. `server.properties`: `online-mode=true`, `white-list=true`, `enforce-whitelist=true` (guide § 9.3). Add the
   testers with `whitelist add <name>`.
2. Plugin `plugins/KnightsAndKings/config.yml` (guide § 9.5, plus the KNG-64 keys):
   ```yaml
   api:
     base-url: "http://<NAS-LAN-IP>:5000/api"
     allow-untrusted-ssl: false
     auth:
       type: apikey
       api-key: "<Security__PluginApiKey>"
       api-key-header: "X-API-Key"
   region-http:
     bind-address: "<paper-host-lan-ip>"     # 127.0.0.1 if the API runs on the same machine as Paper
   web:
     public-url: "https://app.knightsandkings.net"
   ```
3. **NAS firewall:** allow TCP 5000 only from the Paper host's IP. **Paper host firewall:** allow TCP 8081 only from the
   NAS's IP. Both services now also require the API key.
4. Restart Paper, then check `/knk health` and `/knk cache refresh`.

---

## 8. First admin and roles

1. Bootstrap yourself (production guide § 6.5, the **[KNG-64]** box):
   join → `/account link` → register at `https://app.knightsandkings.net/auth/register` with the code → grant
   yourself `*` with the plugin key:
   ```bash
   KEY='<Security__PluginApiKey>'
   curl -s -H "X-API-Key: $KEY" http://<NAS-LAN-IP>:5000/api/Users/uuid/<your-uuid>         # → your "id"
   curl -s -X PUT http://<NAS-LAN-IP>:5000/api/PermissionGrants/by-node -H "X-API-Key: $KEY" \
        -H 'Content-Type: application/json' -d '{"holderId":<id>,"node":"*","value":true}'
   ```
2. Create the role groups in the web app (plan § 8): **Admin** (`knk.admin.*`), **Moderator**, **Support**,
   **Finance**. Give staff testers a role, never `*`.
3. Create one **non-staff test account** for the probe script (§ 9 E).

---

## 9. Go-live checklist

**A. Code**
- [ ] KNG-64 merged in knk-web-api, knk-web-app and knk-plugin. The images and builds come from those merge commits.
- [ ] The plan's developer live checks (plan § 9) passed on the dev setup.

**B. Secrets and config**
- [ ] Every secret in § 3 is generated and stored in the password manager. The `*.env` files are mode 600.
- [ ] The dev DB password is rotated, and the dev machines use `dotnet user-secrets`.
- [ ] `api.env` has `ASPNETCORE_ENVIRONMENT=Production`, `ForwardedHeaders__KnownProxies=172.30.0.10` and
      `Security__Registration__AllowWebFirst=false`.

**C. Data**
- [ ] `knk_alpha` exists with the `knk_app` / `knk_migrator` users. The migrations are applied (the latest includes
      `AddRefreshTokensAndTokenVersion`).
- [ ] Seed imported before the API's first start. The world folders match the world choice.
- [ ] One backup taken (§ 10) and test-restored into a scratch database.

**D. Services**
- [ ] `docker compose ps`: db healthy, api, web and cloudflared up. The API log has no key or secret warnings.
- [ ] The tunnel is **Healthy** in Zero Trust.
- [ ] `https://app.knightsandkings.net` shows the Access login, and after the PIN the landing page. A deep link
      (`/auth/login`) loads.
- [ ] From the internet, nothing on the NAS is reachable except through the tunnel. Check with
      `nmap -p 80,443,3306,5000 <home-ip>` from outside (e.g. a phone hotspot): everything is closed or filtered.

**E. Security probe**
- [ ] From the LAN: `scripts/security/alpha-probe.sh http://<NAS-LAN-IP>:5000 --player '<test>:<pw>'` → `ALL CHECKS PASSED`.
- [ ] Through Cloudflare: `scripts/security/alpha-probe.sh https://app.knightsandkings.net --player '<test>:<pw>' --cf-id <id> --cf-secret <secret>` → `ALL CHECKS PASSED`.

**F. Player flow (with a tester or a second account)**
- [ ] Whitelisted player joins → `/account link` shows a code and the register URL → registers on the web → lands
      on the account page, logged in.
- [ ] Log in with the Minecraft name. Log out on a phone.
- [ ] A Moderator account can't grant `*` or reach the content tools. The owner can.
- [ ] Password change in browser B logs out browser A.

**G. Communication**
- [ ] The tester invite is sent (§ 11), with how to report bugs.
- [ ] `ACTIVE_SESSIONS.md` and Linear are updated. A dated go-live note is added under `docs/reports/`.

---

## 10. Running the alpha

- **Backups:** a nightly `mysqldump` from the db container into `$ALPHA/backups` (production guide § 5.5 script,
  with `docker compose exec` in `$ALPHA`), plus a NAS snapshot of `$ALPHA` and the world folders. Copy them off the NAS
  weekly.
- **Monitoring:** the Zero Trust tunnel status page, and optionally Uptime Kuma on another device checking
  `https://app.knightsandkings.net/api/health` (needs the Access bypass policy) and `play.knightsandkings.net:25565`.
- **Updates:** build new images and web build → `docker compose up -d api web`, migrator first when there's a
  migration (production guide § 10.6 order: API, web, then plugin).
- **Kill switch:** `docker compose stop cloudflared` (site offline), or remove the testers from the Access policy.
- **Logs:** `docker compose logs --since 1h api`. Failed logins and lockouts are logged with the client IP from
  Cloudflare.

## 11. Tester invite (template)

> Welcome to the **Knights & Kings closed alpha**!
> 1. Join the Minecraft server **play.knightsandkings.net** (Java Edition 1.21.10). Your name is on the whitelist.
> 2. In game, type `/account link`. You get an 8-character code.
> 3. Open **https://app.knightsandkings.net**, enter this email address to get a one-time PIN, then choose
>    **Create account** and enter the code, your email and a password.
> 4. From then on you can log in with your Minecraft name or your email.
>
> Found a bug or something confusing? Send it to <channel> with what you did, what you expected, and a screenshot.

## 12. Moving on from the alpha

Before an **open beta**:
- Move to a VPS (production guide § 1.3 onwards).
- Drop the Access allow-list (or keep it for `/admin` only).
- Add email verification (plan § 12).
- Set up CI-built images (guide § 10).
- Decide on a public static site at `knightsandkings.net`.
