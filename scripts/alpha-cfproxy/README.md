# knk-alpha cfproxy (Phase 9, KNG-216)

The API has no internet. Its Cloudflare Access list sync (`CloudflareAccess__*`, alpha go-live § 6.1) goes through
`cfproxy`: tinyproxy 1.11 on Alpine 3.22, built on the NAS from this directory as `knk-cfproxy:alpha-1`. There's no
maintained upstream image (`vimagick/tinyproxy` has only a 2021 `latest`).

| File | Use |
|---|---|
| `Dockerfile` | `alpine:3.22` pinned by digest, `apk add tinyproxy`, config baked in, UID 2004 |
| `tinyproxy.conf` | Port 8888; clients only from the `mail` subnet `172.31.250.16/28`; `CONNECT` only to port 443; default-deny filter |
| `filter` | `^api\.cloudflare\.com$` (extended regex) |
| `compose.cfproxy-service.yaml` | The service, inserted before `volumes:`. Networks `mail` + `mail-egress`, read-only, `cap_drop: ALL`, health check `nc -z 127.0.0.1 8888` |

The API side (`scripts/alpha-api/`):
- `api-entrypoint.sh`: the image's entrypoint plus the optional secret `/run/secrets/cloudflare_api_token` →
  `CloudflareAccess__ApiToken` (the API reads the token only from the environment). Mounted from `config/api/`.
- `compose.api-service.yaml`: `CloudflareAccess__ProxyUrl=http://cfproxy:8888`, the token mount and an `env_file`
  `config/api/cloudflare-access.env` with `SyncEnabled`, `AccountId` and `ListId` (`cloudflare-access.env.example`).
  The kill switch is `SyncEnabled=false` in that file plus a recreate of the API; no Compose edit.

Rehearsed on 2026-10-24 in a scratch Docker host:
- `CONNECT api.cloudflare.com:443` → 200; `example.com` and `api.cloudflare.com.evil.test` → 403; a client outside
  the subnet → 403 (`Unauthorized connection`). A plain `http://api.cloudflare.com` GET is passed (tinyproxy can't
  limit plain HTTP by port); the API only uses `https://`.
- API `a38c8ee9` with the new entrypoint: starts without the token file and with it; the token is in the process
  environment only (not in `docker inspect`, not in the logs). With `SyncEnabled=true` and a fake token the sync went
  through `cfproxy` to Cloudflare and logged `HTTP 400 (9106: Authentication failed)`, so the whole path works.
