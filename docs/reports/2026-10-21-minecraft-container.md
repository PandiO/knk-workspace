# Minecraft container on the NAS — Stage 1 (KNG-225)

**Status:** Paused after Stage 1 (container without the KnK plugin). Stage 2 waits for runbook Phase 3b.
**Last updated:** 2026-10-21
**Issue:** [KNG-225](https://linear.app/kngpandi/issue/KNG-225)
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 4 ·
**Prompt:** [2026-10-21 Minecraft container](../ai-agents/handoffs/2026-10-21-minecraft-container-prompt.md)

The developer ran every NAS command in an SSH session; this Claude Code session (developer PC, LAN) wrote them and
checked results with the read-only `knk-ops` operations. No secret values were printed or recorded.

## 1. Starting point (2026-10-21 15:38Z, `knk-ops`)

- knk-plugin `main` `79be4882`; KNG-182 (`claude/mc-26.2-upgrade` `88497649`) **not merged**.
- knk-web-api `master` `2d71155` includes KNG-64, but the NAS API is still `knk-web-api:alpha-17ee730a`:
  **Phase 3b has not run.**
- `knk-alpha` stack: API and MySQL healthy, no port bindings; host `compose.yaml` `b4c501ee…e298c` (matches the record),
  Portainer stack 42 `8ab2d339…` (canonically equal). Disk: 764 GiB free. Docker and containerd enabled at boot.

## 2. Decisions (developer, 2026-10-21)

- **A6:** the host `/srv/docker/stacks/knk-alpha/compose.yaml` is authoritative. After every change it is copied over
  Portainer stack 42's file (`/var/lib/docker/volumes/portainer_data/_data/compose/42/docker-compose.yml`); nobody
  presses "Update the stack" in Portainer. Each edit is preceded by a dated copy in `backups/<UTC timestamp>/`.
- **World source:** the live copy comes from the already-converted dev server `DEV_SERVER_26.3` (stopped for the
  copy), not from the 1.21.10 staging tree. It is newer and needs no conversion on the NAS. Consequence: the worlds
  are newer than the placeholder alpha database (a 2026-10-11 dev copy). Acceptable because that database is about
  to be replaced; the real alpha takes world and database from the same moment (runbook decision 2026-10-21).
  The 1.21.10 staging tree and its archives stay untouched as rollback.
- **Plugins:** FastAsyncWorldEdit 2.16.1 and WorldGuard 7.0.20 only; WorldEditSelectionVisualizer left out (untested
  on 26.3). The KnK jar comes in Stage 2.
- **KnK config:** built from the KNG-182 branch default `config.yml` plus deliberate dev values, not the dev file (§ 5).
- **Hub:** `worlds.load` has `knk_hub` with `create: false`, `required: true`: a missing hub must keep players out,
  never be replaced by an empty void world.
- **Memory:** heap 4 GiB (`MEMORY=4G`), container limit raised from 5 to **6 GiB** (idle use was 4.58 of 5 GiB).
- **View/simulation distance:** 12 / 8 (dev uses 25 / 10), easy to change in `environment`.

## 3. What was built

| Item | Value |
|---|---|
| Image | `itzg/minecraft-server:java25` @ `sha256:0f3d1571b7d7bf237c08cbe5ee33cfd67e16bd66f454259ed0a2e35f1e2a2e70` (image ID `sha256:031a6cde977f…`, built 2026-10-19) |
| Paper | 26.3 build **205** (`26.3-205-main@a90108f`), pinned with `PAPER_BUILD` |
| Container | `knk-alpha-minecraft`, `user: "2001:2001"` (no host account), `cap_drop: ALL`, `no-new-privileges`, `restart: unless-stopped`, `stop_grace_period: 2m`, `stdin_open`/`tty`, image health check, json-file logs 5 × 20 MB |
| Environment | `TYPE=PAPER`, `VERSION=26.3`, `EULA=TRUE`, `MEMORY=4G`, `USE_AIKAR_FLAGS`, `LEVEL=world_KNK-DEV`, `ONLINE_MODE`, `ENABLE_WHITELIST`, `ENFORCE_WHITELIST`, `MAX_PLAYERS=20`, `ENABLE_RCON`, `RCON_PASSWORD_FILE=/run/secrets/rcon_password` |
| Networks | `knk-alpha_backend` (internal) + new `knk-alpha_egress`; **no published ports** |
| Live data | `/srv/docker/stacks/knk-alpha/minecraft-data` (mode 700, owner 2001), 7.0 GiB |
| World archive | `knk-dev-worlds-20261021.tar.gz` (`world_KNK-DEV` + `plugins/WorldGuard`, `FastAsyncWorldEdit`, `KnightsAndKings`), SHA-256 `de62e97a08040b5b3eabdaeced30e261e649b66f59cbb63585ded6450cedd61c` |
| Plugin jars | `FastAsyncWorldEdit-Paper-2.16.1.jar` `557f15ed…b811`, `worldguard-bukkit-7.0.20.jar` `8768a49b…467b` (the dev server's builds) |
| RCON secret | `secrets/rcon_password`, owner 2001, mode 600 (the admin account can't read it) |
| KnK config | `plugins/KnightsAndKings/config.yml`, owner 2001, mode 600; source file SHA-256 `18f1df9d…e143` before the key was filled in on the NAS |
| Compose | before `b4c501ee…e298c` → with minecraft `87315c8e…d238c0` → with `mem_limit: 6g` `5e6d516b139f74dc9c8c261da8a3384d49e0837d27933489766972804c31f741`; Portainer stack 42 byte-identical |
| Backups | `backups/20261021T161135Z/` (original `compose.yaml` + stack 42 copy), plus one before the memory change |

## 4. Stage 1 results

| Check | Result |
|---|---|
| First start | Paper downloaded, `Done (8.523s)`; no migration (worlds already 26.3); FAWE and WorldGuard enabled, no ERROR/SEVERE |
| Container | `healthy`, user `2001:2001`, `PortBindings={}`, networks backend + egress |
| Console | `docker exec knk-alpha-minecraft rcon-cli plugins` answered (command in, answer out). Portainer → Console → `rcon-cli`: `list` answered "There are 0 of a max of 20 players online" (developer, 2026-10-21) |
| API / MySQL untouched | `knk-ops containers`: same start times, 0 restarts; `log-errors` all 0 |
| Resources (idle) | Minecraft 4.58 GiB (before the 6 GiB limit), Frigate 1.7 GiB / ~315 % CPU |
| Restart test (`sudo systemctl restart docker`) | Paper stopped through RCON and saved players and all three dimensions; all three `knk-alpha` containers came back on their own (0 restarts); API `/health/live` + `/ready` 200 |
| After the restart | Minecraft `healthy` and a new `Done` line (developer, 2026-10-21) |

## 5. KnK config prepared for Stage 2

Default `config.yml` of the KNG-182 branch with: `api.base-url: http://api:5000/api`, `api-key` from
`secrets/plugin_api_key` (inserted on the NAS with perl, never printed), `region-http.bind-address: 0.0.0.0`,
`web.public-url: https://app.knightsandkings.net`; from dev: `teleport.back.expire-seconds-by-kind.warps: 60`,
`teleport.back.price-coins: 100`, navigation builder `junction-cluster-radius: 5`, `min-spur-length: 15`,
`ambiguous-reach: 2`, `plaza-growth: 4`; `worlds.load` `knk_hub` (`void`, `create: false`, `required: true`).
Not taken from dev: `debug-logging: true`, `allow-untrusted-ssl: true`, the `localhost` URLs, the health cache policy
`CACHE_FIRST` (default `API_ONLY` is the KNG-115 fix) and the old link-code text. Re-check against the default of the
commit that is finally built.

## 6. Open

- **Phase 3b** (KNG-64 API on the NAS) runs in its own session; Stage 2 waits for it.
- (done) `rcon-cli` from Portainer's console works.
- **Stage 2:** build the KnK jar (KNG-182 branch, or `main` if merged), `releases/plugin/<commit>/`, install as
  `plugins/KnightsAndKings.jar`, checks per runbook § 4.4 and go-live § 5, then the `plugins/update/` swap and the
  Phase 4 acceptance list. Whitelist `__pandi__` with `rcon-cli whitelist add`.
- `knk-ops` doesn't know the Minecraft service yet: the `compose` recorded hash is stale (`matches_recorded: false`),
  `secret-files` lists `rcon_password` as unexpected, and `containers` doesn't cover `knk-alpha-minecraft` (Linear issue
  [KNG-228](https://linear.app/kngpandi/issue/KNG-228)).

## 7. Incident: stack started from Portainer with relative mount paths (2026-10-21 ~20:34–21:14 local)

- The developer stopped and started the `knk-alpha` stack from Portainer by accident. Portainer runs Compose in its
  own working folder `/data/compose/42`, and the Docker daemon resolved the Minecraft service's **relative** mounts
  (`./minecraft-data`, `./secrets/rcon_password`) against that path **on the host**. Docker created empty,
  root-owned folders there, so the server (UID 2001) couldn't write `/data` (`[init] [ERROR] Unable to write eula`;
  the "uid=1000" in that message is the image's default text). It restarted in a loop and became `unhealthy`.
- No data was touched: the live `minecraft-data` was last written at 18:19 UTC, before the incident. API and MySQL
  came back healthy (their mounts are absolute or a named volume).
- Fix: both mounts are now absolute (`/srv/docker/stacks/knk-alpha/minecraft-data:/data`,
  `/srv/docker/stacks/knk-alpha/secrets/rcon_password:/run/secrets/rcon_password:ro`). The fixed file was copied to
  Portainer stack 42, and Minecraft was recreated from the host file: `Done (9.343s)`, `healthy`, `user=2001:2001`.
  New Compose hash on host = stack 42: `46a8ab7b68c8db81f893a68d20712782fa23590e3ad5d4aa4029828fd23d69e7`. The empty
  folders under `/data/compose/42` were removed (`/data/compose/1–6` are older Portainer leftovers and were left alone).
- Rule: every host path in `compose.yaml` must be absolute, because Portainer can start the stack from its own folder.
  Starting/stopping the stack in Portainer is then harmless; "Update the stack" stays off-limits (A6).
