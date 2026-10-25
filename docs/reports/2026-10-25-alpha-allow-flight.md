# Closed alpha: `allow-flight=true` on the Minecraft service — 2026-10-25

**Status:** Done. `knk-alpha-minecraft` runs with `allow-flight=true`; the "Flying is not enabled on this server" kicks
stop
**Last updated:** 2026-10-25
**Linear:** none (free plan issue limit). **To file:** this change
**Procedure:** [runbook § 4.1](../guides/closed-alpha-deployment-runbook.md), host Compose authoritative (A6,
[2026-10-21 container report](2026-10-21-minecraft-container.md) § 1)

The developer ran every command; Claude Code (cloud session) diagnosed the kick and wrote the blocks.

## 1. Diagnosis

Players were disconnected for flying while not flying. The suspicion was WorldGuard. WorldGuard 7.0.20 has no flight
detection and no kick of its own, and nothing in the alpha configures one. The kick is vanilla Minecraft's: a player
who stays airborne for about 80 ticks without falling is disconnected with "Flying is not enabled on this server",
unless `allow-flight=true` in `server.properties` (default `false`). The alpha has Bedrock players through Geyser,
whose movement differs from Java and trips this check; Geyser's own setup guide asks for `allow-flight=true`. Lag,
elytra, riding and surface swimming trip it for Java players too. The KnK plugin never kicks for movement; its
`ModeService` only calls `setFlying(false)` when a player leaves owner mode.

Trade-off: the server no longer kicks anyone for hovering, so a Java fly hack is not caught by this check either.
Acceptable for an invite-only alpha; WorldGuard region protection is unaffected.

## 2. Change

The itzg image writes `server.properties` from its environment on every start, so the switch lives in Compose, not in
the file. Edited over SSH in the host file (Portainer's editor and "Update the stack" stay off limits, A6).

| Step | Result |
|---|---|
| Backup | dated copies of `compose.yaml` and Portainer stack 42's file under `backups/<TS>/` |
| Compose | `ALLOW_FLIGHT: "TRUE"` in the `minecraft` service's `environment`; `docker compose config --quiet` clean |
| Restart | `rcon-cli save-all flush`, then `docker compose … up -d minecraft` (recreated; `restart` would not pick up the change) |
| Check | `docker inspect`: `ALLOW_FLIGHT=TRUE`; `/data/server.properties`: `allow-flight=true` (a grep 1.6 s after "Started" still showed `false`, because the entrypoint rewrites the file during start-up); log `Done (15.058s)`, Geyser `Done`; container `2001:2001`, `healthy` |
| Hashes | host `compose.yaml` and Portainer stack 42 both **`82def53828bc3f8ad45fdbbe0c89cdd282724fd1e4fd10604ccd05e7c086eeba`** (was `41f7b64a…`) |
| Workspace | `scripts/nas-ops/stage-a/ops/compose` `RECORDED_SHA` → `82def538…`, `SHA256SUMS` updated; runbook § 4.1, go-live § 5, nas-ops-access |

**Open:** the NAS copy `/usr/local/libexec/knk-ops/ops/compose` still records `41f7b64a…`. Reinstall it from
`scripts/nas-ops/stage-a/ops/compose` (root, 0755, [nas-ops-access § 2](../guides/nas-ops-access.md)), then
`knk-ops compose` must report `matches_recorded: true` and `files_identical: true`.

## 3. Rollback

Remove the `ALLOW_FLIGHT` line (or restore `backups/<TS>/compose.yaml`), copy to stack 42, `save-all flush`,
`up -d minecraft`, `RECORDED_SHA` back to `41f7b64a…`.
