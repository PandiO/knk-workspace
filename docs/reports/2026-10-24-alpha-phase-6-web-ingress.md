# Closed alpha Phase 6: web app and `app.knightsandkings.net` — 2026-10-24

**Status:** Complete. `https://app.knightsandkings.net` serves the web app behind Cloudflare Access through the alpha's own tunnel. API updated to `a38c8ee9` (95 migrations) in the same change
**Last updated:** 2026-10-24
**Linear:** none. **To file:** the workspace has reached the free plan's issue limit (§ 7)
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 6 ·
[alpha go-live](../guides/alpha-go-live.md) § 6
**Build files:** [`scripts/alpha-web/`](../../scripts/alpha-web/) (web image, nginx, Compose blocks),
[`scripts/alpha-api/compose.api-service.yaml`](../../scripts/alpha-api/compose.api-service.yaml)

The developer ran every NAS command in an SSH session and used the Cloudflare dashboard. Claude Code (cloud session)
wrote and checked each block and rehearsed the web image, nginx and API together in a scratch Docker host first. The
tunnel token was typed at a hidden `read -rs` prompt on the NAS; it was never printed, logged or recorded.

## 1. Decisions (developer, 2026-10-24)

- **A separate tunnel for the alpha** (`knk-alpha`, its own `cloudflared` in the `knk-alpha` stack). The personal tunnel
  `HomeNetwork` (`cloudflare-tunnel` in the `core` stack) and its 7 Access applications stay untouched. "Everything should
  be as separate as possible from the personal stuff."
- **Versions:** web app `main` `00e4af614e60…` and API `master` `a38c8ee94116…`. The web app's KNG-186/269 code needs
  that API, and the API was recreated anyway (new network, `ForwardedHeaders`).
- **Access:** only staff addresses at first (3 emails, One-time PIN). Testers come with the invites (go-live § 10,
  Phase 9).

## 2. Design

```
browser ── Cloudflare (Access: Allow staff, OTP) ── tunnel knk-alpha ── cloudflared ─edge─ web (nginx :8080) ─webapi─ api :5000 ─backend─ mysql
                                                                            │ cfegress (internet)
```

| Piece | As built |
|---|---|
| `web` | `knk-web-app:alpha-00e4af61`. Build stage `node:24-bookworm-slim`; runtime `nginxinc/nginx-unprivileged:1.28-alpine` (UID 101, port 8080), both pinned by digest. `REACT_APP_API_BASE_URL=/api`, `REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net`, no source maps. Read-only root with `tmpfs /tmp`, `cap_drop: ALL`, `no-new-privileges`, image health check |
| nginx | SPA with deep links (`try_files … /index.html`), `/static/` cached for a year, `index.html` no-cache. `/api/` → `http://api:5000` through Docker DNS (variable upstream with `resolver 127.0.0.11`, so nginx starts without the API). `X-Forwarded-For` ← `CF-Connecting-IP`, `X-Forwarded-Proto: https`. `/health/` denied. `nosniff`, `X-Frame-Options DENY`, `Referrer-Policy` |
| `cloudflared` | `cloudflare/cloudflared:2026.10.3@sha256:faa8e0a1…`, distroless, UID 65532, read-only. `tunnel run` with `TUNNEL_TOKEN_FILE=/run/secrets/cloudflared_token` (the image's `--token-file`), metrics on `127.0.0.1` only |
| Networks | `webapi` (internal, `172.31.250.0/28`: `api` and `web`); `edge` (internal: `web` and `cloudflared`); `cfegress` (internet: `cloudflared` only). `web` has no internet; `cloudflared` can't reach the API |
| API | Image `alpha-a38c8ee9`, plus network `webapi`, `ForwardedHeaders__Enabled=true`, `ForwardedHeaders__KnownNetworks=172.31.250.0/28`, so rate limits and lockout count per real client |
| Tunnel route | Published application `app.knightsandkings.net` → service URL **`http://web:8080`**, *no* HTTP Host Header override (with `web:8080` there, the API's `AllowedHosts` would answer 400). Cloudflare created the CNAME `app` → `58b3e9bd-….cfargotunnel.com`. Access JWT validation at the tunnel is left off: Phase 9's sign-up bypass carries no Access token |
| Access | Self-hosted application `KnK alpha` (destination Public DNS `app.knightsandkings.net`, whole host), policy `Allow staff` (Include Emails: 3 staff addresses), One-time PIN only with instant authentication, session 24 h |
| Zone `knightsandkings.net` | SSL/TLS Full, Always Use HTTPS; WAF rate-limiting rule `KnK auth` (path starts with `/api/Auth/`, 30 requests / 10 s per IP → block 10 s); Bot Fight Mode off. HSTS not yet |

Findings while preparing:
- **knk-web-app's `package-lock.json` needs npm 11.** npm 10 (Node 20/22) refuses `npm ci` with "Missing: yaml@2.9.1
  from lock file". Node 24 / npm 11 accepts it, and Create React App 5 builds on it with warnings only.
- **The NAS Docker has no buildx.** The legacy builder ignores the `# syntax` line, which is harmless here.

## 3. Rehearsal (scratch Docker host, 2026-10-24)

Set up as on the NAS:
- MySQL at 93 migrations, then the `a38c8ee` migrator (2 migrations → 95);
- the API on `backend` + `webapi` (`172.31.250.0/28`) with `ForwardedHeaders`;
- the web image on `webapi` + `edge`;
- a curl container on `edge` standing in for `cloudflared`.

Results:
- `/`, `/auth/register` and `/auth/reset-password` → 200 `index.html`;
- `/api/users` and `/api/GateStructures` → 401;
- `/health/ready` → 403; a `.map` → 404;
- the `edge` network can't reach `api:5000`;
- the security headers are present;
- the bundle contains `/api` and `play.knightsandkings.net`;
- 12 failed logins with one `CF-Connecting-IP` → 401 × 10 then **429**, while another IP still got 401. So the API rate-limits
  per real client;
- `cloudflared` read-only reads the token file (a dummy token was rejected with "not valid").

## 4. On the NAS

| Item | Value |
|---|---|
| Archives | API `deployment-sources/knk-web-api/a38c8ee9/knk-web-api-a38c8ee9.tar.gz` `817cd0274359aee6070702db773c17632065f2fccdd22f02e840cabb63a6986d`; web app `deployment-sources/knk-web-app/00e4af61/knk-web-app-00e4af61.tar.gz` `ebdd126e8b6eaabfb07e95e6c324f158960c9a99f8808d20ae2690d56df5e14c` (same on PC and NAS; the image labels match) |
| Build files | API: unchanged (`Dockerfile` `80e9caeb…`, entrypoint `e872df91…`). Web: `Dockerfile` `7da26a88…`, `nginx.conf` `8486a47e…` |
| Images | `knk-web-api:alpha-a38c8ee9` `sha256:7e6d0157ab9a3f40009318cd1ec4ff6a4fd35e588f8b31b195a7f64817b03ee3` (269,990,838 B, `2002:2002`); migrator `sha256:07047ef301010705f2c557566e34e63e9db80dba223c65aafd1e79128f77a17b`; `knk-web-app:alpha-00e4af61` `sha256:3e1abb28027b0da93dd0e181a9d0a49756e4967147ccc3d6af275802e8c5502a` (58,463,445 B, UID 101) |
| Secret | `secrets/cloudflared_token`, 184 characters (base64), `65532:65532 600` |
| Pre-migrate dump | `alpha-db-pre-a38c8ee9/20261024T150152Z/knightsandkings_alpha-pre-migrate.sql.gz` `c391b7c0e9a2757cadeb8c17a38adf4d1132c2b90bb34b1fb95aab6311e947ff` (143 tables, API stopped) |
| Migration | rc 0, exactly `20261023134703_FormConditionAndValidationIsActive` and `20261023144845_AddFieldValidationRunLogs`, `Done.`, no fail/exception lines; log `backups/20261024T150152Z/migrate-a38c8ee9.log` |
| Compose | `c4e17e56…` → **`323676229b27b5db8df351d66cf0271fc30cab5de52ccd3757ab679403e5ad38`** (canonical `b5edbff7…`), Portainer stack 42 identical; backups `backups/20261024T150152Z/`. 66 diff lines: the API image line, 3 env lines plus 1 network line, the `web` and `cloudflared` blocks, and 3 networks. `up -d --no-deps api web cloudflared`; MySQL, Minecraft and playit kept running |
| `knk-ops` | `compose` records `32367622…` (wrapper `f4032f96…`); `secret-files` expects `cloudflared_token` (wrapper `81e5f372…`). Both match `scripts/nas-ops/stage-a/SHA256SUMS` |

## 5. Acceptance

| Check | Result |
|---|---|
| Containers | API healthy (`backend` 172.27.0.2, `webapi` 172.31.250.3), only the four known warnings; `web` healthy (`webapi` .2, `edge`); `cloudflared` up (`edge`, `cfegress`); no port bindings anywhere |
| Tunnel | 4 connections registered (`ams07`, `ams17`, `ams21`); after the route `Updated to new configuration … app.knightsandkings.net → http://web:8080`, no `ERR`/`WRN` since; the token isn't in the logs |
| Inside | nginx `/auth/register` 200, `/api/users` 401 |
| Browser (developer) | 1. `https://app.knightsandkings.net` → Access login → PIN → landing page; 2. deep link `/auth/login` works; 3. login as `__pandi__`, admin pages work; 4. API calls go to the same origin `/api/…` |
| nginx log (10 min) | 79 × 200 |
| `knk-ops` | `api-health` 200/200; `db-summary` 144 tables, 95 migrations (latest `AddFieldValidationRunLogs`), 0 clashes, `refresh_tokens` 1 (the new login); `compose` `matches_recorded: true`; `secret-files` 7 files incl. `cloudflared_token`, nothing missing or unexpected; `log-errors` 0 errors; `secret-scan` clean |

`db-summary` showed 10 users / 3 active, where it was 9 / 2 that morning. One account was created during the day; a
whitelisted player joining Minecraft creates one. Worth confirming that this was expected.

## 6. Runbook Phase 6 acceptance

| Item | State |
|---|---|
| External alpha users can load the web app and authenticate | yes for staff (Access OTP + KnK login). Testers follow with the invites |
| The browser calls only the intended API origin | yes (same origin `/api`, no CORS) |
| Admin routes enforce KnK roles | the admin pages work for `__pandi__`; anonymous API calls get 401. The non-staff check is the security probe (go-live § 8) |
| No internal management service exposed | only `app.` is published through the tunnel; the tunnel only dials out; the Phase 5 port scan showed no open port, and Phase 6 added none |

## 7. Open

- **To file in Linear:** "Closed alpha Phase 6: web app and `app.knightsandkings.net`", for this work; the free-plan limit
  blocks it.
- **HSTS** on `knightsandkings.net` now that the first visit worked (go-live § 6 zone settings).
- **Security probe** (go-live § 8): privately on the backend network and through Cloudflare. It needs a non-staff test
  account and an Access service token with a *Service Auth* policy.
- **The apex `knightsandkings.net` answers 520:** a proxied DNS record points at a server that doesn't answer. Delete or fix
  it; it doesn't affect `app.` or `play.`.
- **Repeat the external port scan** (go-live § 9 D) for the checklist. Phase 6 opened no ports (the tunnel dials out),
  so this is a formality.
- [KNG-228](https://linear.app/kngpandi/issue/KNG-228): `knk-ops` doesn't cover `web`, `cloudflared`, `playit` and
  `minecraft` yet.
- Phase 9 (invite-only, KNG-218) adds the Access sync, the sign-up bypass, `mailrelay` and `cfproxy` on this setup
  (go-live § 6.1).
