# Knights and Kings — closed alpha go-live (KNG-64 layer on the NAS runbook)

**Status:** v2, aligned 2026-10-11 with the [closed-alpha deployment runbook](closed-alpha-deployment-runbook.md)
(the Codex NAS rollout). Not yet followed end to end. 2026-10-21: web hostname decided (`app.knightsandkings.net`),
DNS in Cloudflare, Minecraft console/autostart/plugin updates ([KNG-225](https://linear.app/kngpandi/issue/KNG-225)).
2026-10-22: § 3 (API upgrade) done on the NAS ([KNG-227](https://linear.app/kngpandi/issue/KNG-227)); § 3–4 corrected from that run.
**Last updated:** 2026-10-24 (Phase 9 E0: the mail relay is live, § 4 mail block is SMTP; KNG-205 invitations merged: the feature-branch notes replaced; settings as before, all off until § 11.1); 2026-10-22; 2026-10-21 (KNG-218, invitations chain link 7: § 4.1 settings after the invite-only switch-over, § 5.1 admission gate instead of the whitelist, § 9 F2, § 10 invite mail, § 11 kill switches and **§ 11.1 the switch-over steps**, § 12); 2026-10-21 (§ 6.1: Cloudflare Access sync, `cfproxy`, the sign-up bypass — KNG-216, feature branch; § 4: `Email__AllowLogTransport` for API builds with the KNG-206 email engine; notes pointing to the KNG-205 invitations plan); 2026-10-18
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
  minecraft (Paper 26.3, main + hub world)    ──► http://api:5000/api   (X-API-Key)
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
| Minecraft ingress | Router port-forward 25565, grey-cloud A record | **playit.gg** agent as a Compose service; `play.knightsandkings.net` → the playit address as a DNS-only record in **Cloudflare DNS** (runbook Phase 5) |
| Alpha data | Fresh DB + seed export/import | **Sanitized copy of the dev DB** (`knightsandkings_alpha`, only `__pandi__` and `admin` active; runbook Phase 2). The seed scripts stay the path for the VPS. |
| Paper host | PC or NAS, API on a LAN port | **Paper in the `knk-alpha` stack**: the plugin and API talk over service DNS, and no API port exists on the LAN |
| MySQL | 8.4 | 9.6.0 (pinned digest, runbook Phase 2) |
| Worlds | Dev map only | Main gameplay world + the converted hub (`knk_hub`), with a KnK-owned loader and no Multiverse (KNG-114) |
| Web hostname | `app.knightsandkings.net` | **`app.knightsandkings.net`** (developer decision 2026-10-21). `knightsandkings.net` is already an active Cloudflare zone, so it gets the same free edge certificate as `oldenzeelit.nl`; `oldenzeelit.nl` stays personal (its Microsoft 365 mail is not used for KnK). |

---

## 2. Builds that may go live

| Repo | Minimum | On the NAS today | Action |
|---|---|---|---|
| knk-web-api | `master` ≥ `30c5dc5` (KNG-64 merge) | `knk-web-api:alpha-a38c8ee9` since 2026-10-24 (KNG-64, KNG-205, KNG-186/269; behind `app.knightsandkings.net` `/api`) | Done (§ 3, [report](../reports/2026-10-22-alpha-api-kng64-upgrade.md)) |
| knk-web-app | `main` ≥ `98c0a76` | `knk-web-app:alpha-00e4af61` at `https://app.knightsandkings.net` since 2026-10-24 | Done (runbook Phase 6, [report](../reports/2026-10-24-alpha-phase-6-web-ingress.md)) |
| knk-plugin | `main` ≥ `34c9261`, plus the KNG-114 hub loader | `plugins/KnightsAndKings.jar` from `main` `d56e41da` since 2026-10-24 ([KNG-225](https://linear.app/kngpandi/issue/KNG-225)) | Done (runbook Phase 4, [report](../reports/2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md)); later builds via `plugins/update/` (§ 5) |

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
3. **Build** from a source archive of `master` ≥ `30c5dc5`. Use the deployment build files in
   [`scripts/alpha-api/`](../../scripts/alpha-api/): the Phase 3.1 Dockerfile with the `KNK_RUNTIME_UID`/`KNK_RUNTIME_GID`
   fix (now UID/GID 2002, no host account) and a `migrator` target (the SDK stage plus `dotnet-ef` 9.0.10, entrypoint
   `dotnet ef database update`, [production guide § 6.1](production-installation.md#61-the-container-image)). Tag them
   `knk-web-api:alpha-<sha>` and `knk-web-api-migrator:alpha-<sha>`.
4. **Migrate.** Stop the API. Run the migrator once on `knk-alpha_backend`, with a connection string for an account
   that has schema rights. That's root for this one run, unless the stack has a migrator user; `knk_alpha_app`
   should stay rows-only. Feed the secret through the same wrapper as the API and never on the command line. It applies:
   - `20261008083025_AddRefreshTokensAndTokenVersion` (sessions: the `refresh_tokens` table plus a token version
     per user; every existing session ends once);
   - `20261010121436_AddDomainWorldName` (KNG-111: each Domain stores its world; the plugin's region report fills in the old ones).

   Both have **older timestamps** than the database's newest migration (`20261010170000_SeedStatisticsStaffNodes`).
   `database update` applies them anyway, but `dotnet ef migrations script <from>` would **skip** them, so don't use
   that. `master` after `07fda99e` also adds `AddHubSettings`, `AddFormFieldSelectionLimits`,
   `AddFormSubmissionProgressCreatedEntities` and `LocationDeleteKeepsDomain`. Count the expected rows from the built
   source: **82** for `be9f4e1a` (the 2026-10-22 run). 78 was right only up to `07fda99e`.
5. **Configure** the additions in § 4, switch the image tag in the stack and start the API. Accept it as in
   Phase 3.3: both health endpoints return 200, startup and restart are idempotent, and no secrets appear in the
   log. The log must also have no `PluginApiKey is not set` warning and no `Security:Jwt:Secret` error.
   On the NAS, the host `compose.yaml` is authoritative (A6): back it up, edit it, copy it over Portainer stack 42's
   file and recreate only `api` (`docker compose up -d --no-deps api`). Never press "Update the stack".
6. **Take a new clean baseline dump**, because the schema changed. Record its SHA-256 in a new dated progress report.

---

## 4. API configuration for the alpha

The runbook's Phase 3.2 keys stay (`ConnectionStrings__MySqlDbConnection`, `Security__PluginApiKey`,
`Security__Jwt__Secret` from secret files, `Database__MySqlServerVersion=9.6.0`, `ASPNETCORE_ENVIRONMENT=Production`).
KNG-64 adds:

```ini
AllowedHosts=app.knightsandkings.net;api;localhost;127.0.0.1     # public name, the service name the plugin uses, and
                                                    # 127.0.0.1: the Host of the image health check and knk-ops (else 400)
Security__AllowUnauthenticatedPluginCalls=false     # already set
Security__PasswordResetFrontendBaseUrl=https://app.knightsandkings.net
Security__PasswordResetExposeTokenInDevelopment=false
Security__Registration__AllowWebFirst=false         # players sign up with an in-game code only
Security__RefreshCookie__SameSite=Lax

# Client IPs for rate limits, lockout and logs. Trust only the nginx that proxies /api. Docker IPs change on
# recreate, so trust the subnet of the network nginx shares with the API, or give nginx a fixed address.
ForwardedHeaders__Enabled=true
ForwardedHeaders__KnownNetworks=<subnet nginx shares with api, e.g. 172.30.0.0/24>

# Region callbacks to the plugin's RegionHttpServer, over service DNS (the plugin binds 0.0.0.0 inside its container).
MinecraftPlugin__BaseUrl=http://minecraft:8081

# Live since 2026-10-24 (KNG-211, E0): mail goes through the stack's mailrelay container (network mail) to the free
# knightsandkingsmc@gmail.com account; the API itself has no internet. Block: scripts/alpha-mail/.
# Receiving support@knightsandkings.net can use Cloudflare Email Routing (free) to forward to that Gmail.
Email__Transport=Smtp
Email__SmtpHost=mailrelay
Email__SmtpPort=587
Email__UseStartTls=false                            # internal hop; the relay does TLS to Gmail
Email__SmtpUsername=                                # empty: the relay holds the Gmail app password
Email__FromAddress=knightsandkingsmc@gmail.com
# Emergency only (relay broken): Email__Transport=Log plus Email__AllowLogTransport=true; reset links go to the API log.
App__PublicBaseUrl=https://app.knightsandkings.net  # links in invitation, reset and admission messages (KNG-205)
Telemetry__Enabled=false                            # already set
```

`Cors__AllowedOrigins` stays empty: the browser only talks to its own origin. `ForwardedHeaders__*` stays off until
nginx exists (§ 6).

**Log levels:** setting `Logging__LogLevel__Microsoft.EntityFrameworkCore=Warning` as an environment variable has no
effect on the NAS image, because its `/bin/sh` entrypoint drops variable names that contain dots. Mount
[`scripts/alpha-api/appsettings.Production.json`](../../scripts/alpha-api/appsettings.Production.json) read-only at
`/app/appsettings.Production.json` instead. It sets EF Core and HttpClient to Warning; finding A5 measured about
186,000 API lines a day without it.

**Mail from the KNG-206 email engine on.** Mail goes through a persistent outbox with retries, an hourly throttle and
the `/admin/email` page (staff with `knk.admin.config`). With the relay of KNG-211, the mail block becomes:

```ini
Email__Transport=Smtp
Email__SmtpHost=mailrelay
Email__SmtpPort=587
Email__UseStartTls=false          # internal hop to the relay
Email__SmtpUsername=              # empty: no SMTP authentication, the relay holds the Gmail credentials
Email__FromAddress=knightsandkingsmc@gmail.com
App__PublicBaseUrl=https://app.knightsandkings.net
```

Then remove `Email__AllowLogTransport`. The [email guide](email.md) has every setting, the smoke steps and
troubleshooting.

### 4.1 After the invite-only switch-over (KNG-205)

*Describes the API as merged on 2026-10-24 (the invitations feature, KNG-205). Until the switch-over (§ 11.1) every value below except the mail block stays at its default, which
keeps the alpha exactly as above.* Design: [invitations DESIGN](../specs/invitations/DESIGN.md); how it fits together:
[account identity and admission](../architecture/account-identity-and-admission.md).

```ini
# Sign-up: invitations instead of /account link codes (§ 11.1 step 3). LinkCode is the default and the kill switch.
Security__Registration__Mode=Invite
# Security__Registration__AllowWebFirst no longer matters once Mode is set; leave it false.

# Invitations (defaults shown; omit to keep them). The group must exist: migration SeedAlphaTesterGroup makes it.
# Invitations__DefaultExpiryDays=7  Invitations__MaxExpiryDays=30  Invitations__SharedDefaultMaxUses=5
# Invitations__SharedMaxUsesCap=50  Invitations__ResendPerDay=3   Invitations__InvitableGroups__0=Alpha Tester
# Admission (defaults): claim codes live 15 min; invited accounts unlinked after 2 days get one reminder mail (0 = off).
# Admission__ClaimCodeMinutes=15  Admission__FinishLinkingReminderDays=2

# Cloudflare Access sync (§ 6.1): on from § 11.1 step 2. ApiToken lives only in /etc/knk/api.env (mode 600).
CloudflareAccess__SyncEnabled=true
CloudflareAccess__AccountId=<account id>
CloudflareAccess__ListId=<id of knk-api-testers>
CloudflareAccess__ProxyUrl=http://cfproxy:8888
# CloudflareAccess__ApiToken=…   (env file only)

# Mail through the relay (KNG-211); invites, welcome, linked and reminder mails use it, links use App__PublicBaseUrl.
Email__Transport=Smtp
Email__SmtpHost=mailrelay
Email__SmtpPort=587
Email__UseStartTls=false
Email__SmtpUsername=
Email__FromAddress=knightsandkingsmc@gmail.com
App__PublicBaseUrl=https://app.knightsandkings.net
# No Email__AllowLogTransport once the relay works.
```

The stack then has two small helper containers besides the API: **`mailrelay`** (the SMTP relay of KNG-211,
[email guide § 3](email.md)) and **`cfproxy`** (§ 6.1 step 1). Neither publishes a port.

---

## 5. Minecraft and plugin (runbook Phases 4–5)

**`server.properties`:** `online-mode=true`, `white-list=true`, `enforce-whitelist=true`. Add the testers with
`whitelist add <name>`. playit makes the server reachable from anywhere, so the whitelist is the gate **until the
invite-only switch-over** (§ 5.1, § 11.1).

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
  public-url: "https://app.knightsandkings.net"       # /account link shows app.knightsandkings.net/auth/register
```

Checks:
- The startup log shows `RegionHttpServer listening on 0.0.0.0:8081 (X-API-Key required)`, and there's no warning about a missing
  `web.public-url`.
- `/knk health` shows the API as UP.
- The API log has no 401 or 403 for plugin calls.

**Console, autostart and plugin updates** ([KNG-225](https://linear.app/kngpandi/issue/KNG-225), runbook Phase 4):
- Console: RCON on 25575 **inside** the container only, password from a secret file (`RCON_PASSWORD_FILE`). Use
  `rcon-cli` through Portainer's container console or `sudo docker exec -it knk-alpha-minecraft rcon-cli` over SSH.
  Never publish 25575.
- Autostart: `restart: unless-stopped` and a stop grace period that lets Paper save the worlds on a NAS shutdown.
- Plugin updates: the KnK jar is installed as `plugins/KnightsAndKings.jar`. A new build goes into `plugins/update/`
  under the same filename; Paper swaps it in on the next start. Then a controlled restart (`save-all`, stop, start).
  Never `/reload`.

**Networks:**
- The Minecraft container needs `knk-alpha_backend` (to reach the API) and also a network with internet access
  (Mojang session servers).
- The playit agent needs internet access and must reach `minecraft:25565`.
- Publish no ports on the NAS for any of these.

### 5.1 After the switch-over: the admission gate instead of the whitelist (KNG-214)

*Merged 2026-10-24; needs a plugin build from `main` at or after the KNG-214 merge (Paper 26.3).* The plugin asks the
API about every connecting player right after Mojang sign-in. Admitted accounts (every account that existed when the
`AddInvitations` migration ran, and every invited account that linked its Minecraft account) and operators get in. A
new player is turned away with a claim code and `https://app.knightsandkings.net/link` on the disconnect screen. Nobody adds names
to the whitelist any more.

A `config.yml` copied from an older build has no `admission:` section, which means `whitelist` (off). Add it:

```yaml
admission:
  mode: invite            # whitelist (default, gate off) | open | invite
  api-timeout-ms: 3000    # then the offline store decides: known players in, strangers "try again"
  link-url: ""            # empty: {web.public-url}/link
```

Then `white-list=false` in `server.properties` (or `/whitelist off`). The section is read **at start-up only**:
`/knk reload` doesn't switch it, restart the server. Keep `online-mode=true`: the gate trusts the UUID only because
Mojang checked it. Checks: the start-up log shows `[KnK Admission] admission.mode=invite` and no warning about a missing
link URL; a stranger sees the five-line screen with a code; the server log says "Refused <name> (<uuid>):
admission.kick" without the code.

**playit.gg:**
- Follow runbook Phase 5 (done 2026-10-24, [report](../reports/2026-10-24-alpha-phase-5-playit.md)).
- **Custom domain:** playit routes Minecraft Java tunnels by the hostname in the handshake. A CNAME to the tunnel address
  resolves but can't connect. Add `play.knightsandkings.net` as a playit *external domain* (Cloudflare NS record `play`
  → `ns1.playit-dns.com`/`ns2.playit-dns.com`, then *Change domain* on the tunnel). This needs Premium.
- **Region:** the free tunnel uses global anycast and ran through California (~155 ms from NL). A Premium regional tunnel
  (Germany) gives ~27 ms.
- If the tunnel gets a non-default port, add an SRV record `_minecraft._tcp.play`, so testers can still type
  `play.knightsandkings.net`.
- Paper sees playit's address, not the player's. If your playit tunnel offers Proxy Protocol, enable it there and in
  Paper's `config/paper-global.yml` (`proxies.proxy-protocol: true`) so that bans and logs see real IPs. Enable
  either both or neither. With the itzg image also set `USES_PROXY_PROTOCOL=true`, or its health check (no PROXY
  header) marks the container unhealthy. **On since 2026-10-24** (playit v2); direct LAN connections are then refused.

---

## 6. Web app and ingress (runbook Phase 6)

**Build:**

```bash
# in knk-web-app at the main commit you package
REACT_APP_API_BASE_URL=/api REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net CI=false npm run build
```

**nginx:** the server block for `app.knightsandkings.net`. nginx has to share a network with `api`: attach the existing
`core`-stack nginx to an alpha network, or add a small nginx container to the `knk-alpha` stack that `cloudflared`
reaches.

```nginx
server {
    listen 80;
    server_name app.knightsandkings.net;
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

**Cloudflare Tunnel:** add a public hostname `app.knightsandkings.net` → `http://<nginx>:80` on the existing tunnel.

> **As built 2026-10-24** ([report](../reports/2026-10-24-alpha-phase-6-web-ingress.md)): not the existing tunnel but the alpha's
> own (`knk-alpha`, `cloudflared` in the `knk-alpha` stack with `TUNNEL_TOKEN_FILE`). nginx is the `web` service
> (nginx-unprivileged, port **8080**; [`scripts/alpha-web/`](../../scripts/alpha-web/)). The route is a *published application*
> with service URL `http://web:8080`. **Leave the HTTP Host Header empty**: an override such as `web:8080` makes every
> `/api` call fail `AllowedHosts` (400). The web app's lockfile needs npm 11, so build with Node 24.

**Cloudflare Access:** add a Self-hosted application for the **whole** `app.knightsandkings.net`. The policy *Allow testers*
includes each tester's email, with One-time PIN login and a 24-hour session. *(After the switch-over, § 6.1: the
testers come from the API-owned list `knk-api-testers`, staff stay in a hand-made Emails include, the session is 30
days, and a bypass application opens only the sign-up pages.)* This is plan decision D10: for a closed
alpha the allow-list covers the whole site, not only the admin pages. The plugin talks to `api` inside Docker, so
Access never stands in its way. For the probe from outside, add a service token (Access → Service Auth) and a
*Service Auth* policy.

**DNS zone:** `knightsandkings.net` is an active Cloudflare zone (public NS `barbara`/`michael.ns.cloudflare.com`,
the same pair as `oldenzeelit.nl`, checked 2026-10-21); GoDaddy is only the registrar. Confirm in the dashboard that the
zone shows *Active* and sits in the same account as the tunnel. The free Universal SSL certificate covers the apex
and one subdomain level, so keep names one level deep. The apex already serves something through Cloudflare: check what
before adding zone-wide rules.

**Zone settings (free plan; set them on `knightsandkings.net`, they are per zone):**
- SSL/TLS **Full**, *Always Use HTTPS*.
- HSTS after the first successful visit. *(On since 2026-10-24: 6 months, includeSubDomains and preload off.)*
- The apex and `www` redirect (Redirect Rule, 302) to `app.knightsandkings.net`, using an originless
  `AAAA @ 100::` proxied record. The GoDaddy parking records were removed. Don't add zone-wide rules that would hit
  `play.`, which is delegated to playit's DNS.
- One WAF rate-limiting rule: path starts with `/api/Auth/`, more than 30 requests per 10 s per IP → block for 10 s.
- Bot Fight Mode **off** for this host.

### 6.1 Cloudflare Access sync and the sign-up bypass (KNG-216)

*Applies once an API build with [KNG-216](https://linear.app/kngpandi/issue/KNG-216) is deployed (merged to `master`
2026-10-24). Until then, and whenever
`CloudflareAccess__SyncEnabled` is false, the tester list stays hand-made as described above.* Design:
[invitations DESIGN § 5.8](../specs/invitations/DESIGN.md) (decision I8).

The API keeps a Zero Trust **email list** in sync: personal invites that can still be used, plus every active account
that was invited or grandfathered. A second Access application opens only the sign-up pages, so an invitee can sign up
before their address is on the list. Do the steps in this order; nothing changes for testers until step 7.

**1. Forward proxy (`cfproxy`).** The API has no internet on purpose, so its Cloudflare calls go through a small
proxy that allows only `api.cloudflare.com:443`. Add to the `knk-alpha` stack:

```yaml
  cfproxy:
    image: vimagick/tinyproxy:1.11.2        # pin the tag you test; no :latest
    restart: unless-stopped
    networks: [backend, mail-egress]        # backend: the API reaches it; mail-egress: the network with internet
    volumes:
      - /etc/knk/cfproxy/tinyproxy.conf:/etc/tinyproxy/tinyproxy.conf:ro
      - /etc/knk/cfproxy/filter:/etc/tinyproxy/filter:ro
```

`/etc/knk/cfproxy/tinyproxy.conf`:

```
Port 8888
Listen 0.0.0.0
Timeout 30
MaxClients 10
LogLevel Info
Allow <backend subnet, e.g. 172.20.0.0/16>
ConnectPort 443
FilterDefaultDeny Yes
FilterExtended Yes
Filter "/etc/tinyproxy/filter"
```

`/etc/knk/cfproxy/filter` (one line):

```
^api\.cloudflare\.com$
```

Check from the API container: `curl -sS -x http://cfproxy:8888 https://api.cloudflare.com/client/v4/ -o /dev/null -w '%{http_code}\n'`
answers (any HTTP code, e.g. 400/404, means the proxy let it through), and `curl -x http://cfproxy:8888 https://example.com`
is refused (403 from tinyproxy).

**2. The list.** Zero Trust → *My Team* → *Lists* (or *Reusable components → Lists*) → *Create list*: name
**`knk-api-testers`**, type **User email addresses**. Add **one staff address** so the list is never empty. Note the
list's id (in the URL or `GET accounts/{account}/gateway/lists`). **Nobody edits this list by hand after step 7:** the
API removes anything in it that isn't an invite or an account.

**3. The policy.** Access → *Applications* → the `app.knightsandkings.net` app → policy *Allow testers*: add an **Include → Email
list → `knk-api-testers`** rule. Keep the existing hand-made *Emails* include for staff: the API never touches it.
Set the application's **session duration to 30 days** (it was 24 h), so the PIN is rare.

**4. The API token.** *My Profile → API Tokens → Create custom token*: permission **Account → Zero Trust → Edit**,
account resources **only this account**, no zone permissions. Put it in `/etc/knk/api.env` (mode 600) as
`CloudflareAccess__ApiToken=…`. Never in compose files, appsettings or a ticket.

**5. The bypass application.** Access → *Add an application → Self-hosted*, same hostname `app.knightsandkings.net`, name
"KnK sign-up (bypass)", with these paths (Access uses the most specific path, so everything else stays behind *Allow
testers*):

| Kind | Paths |
|---|---|
| Pages | `/invite/*`, `/invite`, `/join*`, `/link*` |
| Static files of the SPA | `/static/*`, `/favicon.ico`, `/manifest.json`, `/logo*.png` |
| Anonymous API calls of those pages | `/api/Invitations/check`, `/api/Admission/claim/check`, `/api/Auth/register` |

One policy: **Action Bypass, Include Everyone**. The WAF rule on `/api/Auth/` stays.

**6. The API settings** (in `/etc/knk/api.env` next to the token):

```bash
CloudflareAccess__AccountId=<account id>
CloudflareAccess__ListId=<id of knk-api-testers>
CloudflareAccess__ProxyUrl=http://cfproxy:8888
# CloudflareAccess__ReconcileMinutes=5, __InlineAddTimeoutSeconds=5, __MaxRemovalsPerRun=25 are the defaults.
CloudflareAccess__SyncEnabled=false        # step 7 turns it on
```

**7. Turn it on.** Testers with an account are added by the sync. A current tester who has **no account yet** gets
a personal invite from `/admin/invitations` instead (the sync adds invite addresses, and removes anything else it
finds in the list). Then set `CloudflareAccess__SyncEnabled=true` and recreate the API. Within a minute,
`/admin/invitations` shows **"Access sync: last OK hh:mm · 0 pending · n on the list"**. If it's red, the line names
the error (token permission, list id, proxy).

**Kill switches.** `CloudflareAccess__SyncEnabled=false` → back to editing the list by hand (the API stops all calls).
Deleting the bypass application closes sign-up again without touching the app. If the line says removals were "held
back", more than `MaxRemovalsPerRun` addresses would have been removed in one run: check the list and the database
before raising the limit for one run.

**Check from a private window** (after step 7):
- [ ] `/invite/x` and `/join` load without an Access login (and show "invalid invitation" for a made-up link);
- [ ] `/account` and `/api/Users/1` show the Access login;
- [ ] a new personal invite's address appears in `knk-api-testers` within seconds; revoking it removes it;
- [ ] a shared-code sign-up's address is added during registration, and the sign-up's done page says Cloudflare
      will email a PIN; the PIN mail arrives and `/account/link` opens;
- [ ] deactivating a test account removes its address on the next run; the staff *Emails* include is unchanged;
- [ ] `/admin/invitations` shows the green line.

**Limits.** The free Zero Trust plan has **50 seats**: everyone who logs in through Access, staff included, uses one.
A list holds 1,000 entries.

---

## 7. First admin and roles

The alpha DB already has the two accounts the runbook kept: `__pandi__` (Admin, Noble) and `admin` (Admin, Default).
No bootstrap is needed.

1. Log in on `https://app.knightsandkings.net` with your existing credentials. The KNG-64 migration ended old sessions, so expect
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

- **Privately, before ingress.** On the NAS, run it from the API image, which has bash and curl:
  ```bash
  docker run --rm --network knk-alpha_backend --user 65534:65534 --cap-drop ALL -v "<dir with the script>:/s:ro" \
    --entrypoint bash knk-web-api:alpha-<sha> /s/alpha-probe.sh http://api:5000 --player "<test>:$PW"
  ```
  Over plain `http` curl drops the `Secure` refresh cookie, so the script reads it from `Set-Cookie`.
- **Through Cloudflare, after ingress** (from your PC):
  `scripts/security/alpha-probe.sh https://app.knightsandkings.net --player '<test>:<password>' --cf-id <id> --cf-secret <secret>`.

Both must end with `ALL CHECKS PASSED`. The last check trips the login rate limiter for about a minute.

The service token needs a policy with Action **Service Auth** that is **attached to the application**. Otherwise
Access answers 302, and the script stops with a hint. The test account must be non-staff. The User form can't create a
web account (it has no password field), so staff create it with `POST /api/Users`. **Passed on 2026-10-24**, privately
and through Cloudflare ([report](../reports/2026-10-24-alpha-security-probe.md)).

---

## 9. Go-live checklist

**A. Code**
- [ ] The API runs a KNG-64 build (`master` ≥ `30c5dc5`), and the migration count of the built source is applied (§ 3; 93 for `4aeb7947`).
- [ ] The web app and plugin come from KNG-64 builds (§ 2). The plugin has the KNG-114 loader.

**B. Secrets and config**
- [ ] The secret files are mode 600 and owned by the runtime UID, and no value appears in Compose, Portainer or logs (runbook).
- [ ] The dev DB password is rotated (it was committed before KNG-64), and the dev machines use `dotnet user-secrets`.
- [ ] The API has the § 4 keys: `ForwardedHeaders` trusts only the nginx network, and `AllowWebFirst=false`.
- [ ] The plugin has `api.auth.type: apikey`, `region-http.bind-address: "0.0.0.0"` with 8081 unpublished, and
      `web.public-url`.

**C. Data**
- [ ] The holder-id clash query returns no rows.
- [x] A clean baseline dump exists **after** the KNG-64 migrations (2026-10-22/24 baselines).
- [ ] ~~One restore was rehearsed (runbook Phase 7).~~ **Deferred to the beta** (developer, 2026-10-24). For the alpha:
      `knk-alpha-snapshot` before/after each session and before updates, `knk-alpha-restore` tested on a mock stack
      ([`scripts/alpha-snapshot/`](../../scripts/alpha-snapshot/)).

**D. Services**
- [ ] mysql, api and minecraft are healthy. No ports are published except through cloudflared and playit.
- [ ] `https://app.knightsandkings.net` shows the Access login, then the landing page after the PIN. A deep link (`/auth/login`)
      loads.
- [ ] An outside client joins via `play.knightsandkings.net` with no router port-forward.
- [ ] From outside (a phone hotspot), `nmap -p 80,443,3306,5000,8081,25565,25575 <home-ip>` shows everything closed
      or filtered. (2026-10-24, before Phase 6: 13 ports closed/filtered with macOS `nc`, no IPv6; repeat after
      Phase 6, [Phase 5 report](../reports/2026-10-24-alpha-phase-5-playit.md) § 8.)

**E. Security probe**
- [x] Private and Cloudflare runs: `ALL CHECKS PASSED` (§ 8). 2026-10-24, API `a38c8ee9` ([report](../reports/2026-10-24-alpha-security-probe.md)).

**F. Player flow (a tester or a second account)** — before the invite-only switch-over
- [ ] A whitelisted player joins, and `/account link` shows the code (click to copy) and `https://app.knightsandkings.net/auth/register`.
      They register with the code and land on the account page, logged in.
- [ ] Log in with the Minecraft name and log out on a phone.
- [ ] A Moderator can't grant `*` or reach the content tools, while an Admin can assign Staff and Moderator.
- [ ] A password change in browser B logs out browser A.

**F2. Invite flow** — after the switch-over (§ 11.1; merged 2026-10-24, off until then). Details:
[invitations smoke test](invitations-smoke-test.md) § 9.
- [ ] Every active account was admitted by the migration (smoke test § 0.2), and `Alpha Tester` exists.
- [ ] `/admin/invitations` shows "Access sync: last OK …" in green.
- [ ] A personal invite mail arrives; the link opens without an Access login; sign-up → the PIN step → `/account/link`.
- [ ] Joining with the new Minecraft account shows a claim code; entering it links the account; the rejoin gets the
      first-join welcome and kits once, and the chat names the linked web account.
- [ ] A shared code (`/join`) works for its use cap and no further.
- [ ] A grandfathered tester joins without a code; an operator joins; `/whitelist` is off.

**G. Communication**
- [ ] The tester invite is sent (§ 10), together with how to report bugs.
- [ ] `ACTIVE_SESSIONS.md` and Linear are updated, and a dated go-live note is added under `docs/reports/`.

---

## 10. Tester invite (template)

**After the invite-only switch-over** (§ 11.1; merged 2026-10-24, off until then) the invite **is** the system mail: create a
personal invite on `/admin/invitations` and the API sends it (expires in 7 days; *Resend* gives a fresh link). The
mail links `/invite/<token>`; the tester signs up, gets the Cloudflare PIN, then joins the server and enters the code
shown on the disconnect screen on `/account/link`. For a **shared code** (Discord, a friend group) post this short text
with the code from the result panel:

> Knights & Kings closed alpha: sign up at **https://app.knightsandkings.net/join** with code `KNK-XXXXX-XXXXX` (valid until
> <date>, <n> places). Then join **play.knightsandkings.net** (Java Edition 26.3): you'll get a code on screen; enter
> it on the website to link your Minecraft account. Never give that code to anyone; staff never ask for it.
> Bugs or questions: <channel>. This is an alpha: progress may be reset.

**Before the switch-over** (today's alpha), the hand-sent text:

> Welcome to the **Knights & Kings closed alpha**!
> 1. Join the Minecraft server **play.knightsandkings.net** (Java Edition 26.3). Your name is on the whitelist.
> 2. In game, type `/account link`. You get an 8-character code (click it to copy).
> 3. Open **https://app.knightsandkings.net**, enter this email address to get a one-time PIN, then choose **Create account** and
>    enter the code, your email and a password.
> 4. From then on, you can log in with your Minecraft name or your email.
>
> Found a bug or something confusing? Send it to <channel> with what you did, what you expected, and a screenshot.
>
> This is a closed **alpha**: things will break, and your progress may be **reset** between or during test runs.

---

## 11. Running the alpha

- **Backups, restore rehearsal, upgrades:** runbook Phases 7–8. For an API release with a migration: back up, run the
  migrator, then the API, then the web app, then the plugin (production guide § 10.6 order).
- **Logs:** for the API, failed logins and lockouts carry the client IP from Cloudflare (via `ForwardedHeaders`).
- **Plugin-only releases:** stage the jar in `plugins/update/` as `KnightsAndKings.jar`, compare `config.yml` with the
  new jar's defaults, then restart Minecraft at a quiet moment (runbook Phase 4). Releases with an API migration keep the
  order above.
- **Hand deploys for now:** API and web app images are built and switched by hand per the runbook. CI-built images
  and an approved pull path are [KNG-226](https://linear.app/kngpandi/issue/KNG-226), after the first alpha weekend.
- **Kill switches:** stop `cloudflared` or edit the Access policy for the web; stop the playit agent for Minecraft.
  After the switch-over also: `admission.mode: whitelist` + restart + `white-list=true` (gate off, whitelist back);
  `Security__Registration__Mode=LinkCode` (no new sign-ups by invite); `CloudflareAccess__SyncEnabled=false` (list by
  hand again); delete the bypass application (sign-up pages behind Access again). Each one alone is safe.

### 11.1 Switch-over to invite-only (KNG-218)

*Merged to every trunk on 2026-10-24 and smoke-tested on dev ([smoke test](invitations-smoke-test.md), § 0–6 and § 8).
Preconditions (plan § 8): E0's relay live (KNG-211), the merged builds deployed per [plan § 9](../specs/invitations/IMPLEMENTATION_PLAN.md#9-merge-and-deploy-order)
(the plugin after KNG-182), and the [invitations smoke test](invitations-smoke-test.md) § 0–8 passed on dev.* Every
deploy follows the runbook order: **back up → migrator → API → web app → plugin**. Run the matching smoke-test § 9
checks after each step before going on.

1. **Deploy behaviour-neutral.** API with `Security__Registration__Mode` unset (`LinkCode`) and
   `CloudflareAccess__SyncEnabled=false`; plugin with `admission.mode: whitelist` (or no `admission:` section);
   `white-list=true`. The migrator applies `LinkCodePurpose`, `AddEmailOutbox`, `AddInvitations` (every active account
   admitted), `SeedInvitationStaffNode`, `SeedAlphaTesterGroup`. Nothing changes for testers. Check the § 4 mail block
   and `/admin/email` → *Send test mail to me*.
2. **Access sync and bypass.** § 6.1 steps 1–7: `cfproxy`, the list, the policy (30-day session), the token, the
   bypass application, the settings. Testers **without** an account get a personal invite first; then
   `CloudflareAccess__SyncEnabled=true`. The list fills with the current testers; the admin line turns green.
3. **Sign-up by invitation.** `Security__Registration__Mode=Invite`, recreate the API. The developer invites a test
   address and signs up with it (the web half of the web-first flow).
4. **The gate.** Add the `admission:` section with `mode: invite` (§ 5.1), restart the server, then `/whitelist off`
   (`white-list=false`). The developer joins with the second Minecraft account, gets the code, links on
   `/account/link` and rejoins.
5. **Alpha checks.** Run the smoke-test sections marked "alpha" (§ 9 step 5). Then swap the tester invite (§ 10), and
   update `ACTIVE_SESSIONS.md`, KNG-218 and a dated go-live note.

**Rolling back:** the kill switches above, in reverse order (gate first: `admission.mode: whitelist` + whitelist on).
No migration needs to be undone; the new columns and tables are unused while the switches are off.

## 12. Moving on from the alpha

Before an **open beta**:
- Move to a VPS (production guide § 1.3 onwards), with the seed export/import instead of a dump copy.
- Drop the Access allow-list, or keep it for `/admin` only. *(Superseded for the alpha 2026-10-21: Access stays, and the API keeps its list in sync once [KNG-216](https://linear.app/kngpandi/issue/KNG-216) ships; see [invitations DESIGN § 5.8](../specs/invitations/DESIGN.md).)* Mind the free Zero Trust plan's **50 seats** (staff included): past that, the beta needs either a paid plan or Access dropped for the player pages.
- Decide whether invite-only stays (decision I3: at least the alpha test sessions, maybe the beta). `Security__Registration__Mode=Open` is reserved for that and behaves like `Invite` today.
- Add email verification (plan § 12; [KNG-159](https://linear.app/kngpandi/issue/KNG-159): invite mails already verify the address, shared-code sign-ups don't) and CI-built images (guide § 10).
- Move mail from Gmail to a provider on `knightsandkings.net` with SPF/DKIM/DMARC (decision E1; [email guide](email.md)).
- Decide on a public static site at `knightsandkings.net`.
