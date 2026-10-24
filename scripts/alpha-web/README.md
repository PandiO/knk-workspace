# knk-alpha web app (runbook Phase 6)

Build files for `knk-web-app:alpha-<sha>`. They are copied into `/srv/docker/build/knk-web-app/<sha>/` next to
`source/`, a `git archive` of knk-web-app.

| File | Use |
|---|---|
| `Dockerfile` | Two stages:<br>• build: `node:24-bookworm-slim`, `npm ci`, `npm run build` with `REACT_APP_API_BASE_URL=/api`, `REACT_APP_MC_SERVER_ADDRESS=play.knightsandkings.net`, no source maps, no Cypress binary;<br>• runtime: `nginxinc/nginx-unprivileged:1.28-alpine` (UID 101, port 8080).<br>Both pinned by digest |
| `nginx.conf` | The `app.knightsandkings.net` server. It serves the SPA (deep links → `index.html`, `/static/` cached for a year, `index.html` no-cache) and proxies `/api/` to `api:5000`. Docker DNS through a variable upstream, so nginx starts without the API. Passes `CF-Connecting-IP` as `X-Forwarded-For`, plus `X-Forwarded-Proto: https`. `/health/` is denied. Sets `nosniff`, `DENY` and `Referrer-Policy` headers |
| `.dockerignore` | Leaves `node_modules`, `build`, `cypress` and `.git` out of the context |

**Node 24, not 20:** knk-web-app's `package-lock.json` (lockfile v3) was written by npm 11. npm 10 (Node 20/22)
refuses it with "Missing: yaml@2.9.1 from lock file", npm 11 accepts it. Create React App 5 builds on Node 24 with
warnings only (2026-10-24).

Rehearsed on 2026-10-24 in a scratch Docker host, with API `a38c8ee` behind it on an internal network, called from a
container standing in for `cloudflared`:
- `/`, `/auth/register` and `/auth/reset-password` → `index.html`;
- `/api/users` → 401;
- `/health/ready` → 403;
- `.map` → 404;
- the `edge` network can't reach the API directly;
- 12 failed logins from one `CF-Connecting-IP` → 429 from the 11th on, while another IP still gets 401. So the API's
  `ForwardedHeaders` trust (known network = the `webapi` subnet) partitions the rate limits per real client.
