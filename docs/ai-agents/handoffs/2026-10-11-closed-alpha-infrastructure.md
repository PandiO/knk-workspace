# Handoff: NAS closed-alpha infrastructure

**Date:** 2026-10-11
**Status:** API built, privately deployed, and accepted; Minecraft preparation is next
**Branch:** `codex/closed-alpha-infrastructure-handoff`
**Related issues:** KNG-109, KNG-114, KNG-115
**Progress report:** [`2026-10-11-closed-alpha-infrastructure-progress.md`](../../reports/2026-10-11-closed-alpha-infrastructure-progress.md)
**Runbook:** [`closed-alpha-deployment-runbook.md`](../../guides/closed-alpha-deployment-runbook.md)

## Resume point

The `knk-alpha` MySQL and API containers are healthy on the private internal
Compose network. Neither has a published host port. The cleaned database
baseline remains backed up, only `__pandi__` and `admin` are active, and API
startup plus a controlled restart left all recorded schema, activity, and
canonical-seed counts unchanged.

The pinned API source archive for `knk-web-api` commit `17ee730a` was verified,
extracted, built, and deployed. The accepted image is
`knk-web-api:alpha-17ee730a`, image ID
`sha256:61c7e1f6bd451748e3bf6c1cc65f9a49fe5e1b12bdce2bf273c91f8bbea46251`,
running as `1000:1000`. `/health/live` and `/health/ready` both return 200;
readiness reports the database healthy. The next phase is the KnK-owned
multiworld loader and private Minecraft service preparation. Do not expose
the API or start Minecraft until that phase's own prerequisites pass.

## Addendum (Claude Code, 2026-10-11, after the KNG-64 merge)

Read this before Phase 4.

- **The deployed API predates KNG-64.** `17ee730a` is before the KNG-64 merge (knk-web-api `30c5dc5`).
  It is private, so nothing is exposed. Do the new runbook **Phase 3b** before the plugin connects: back up,
  run the holder-id clash check (the dev dump predates the `admin`/Staff id-29 repair), build from `master`
  ≥ `30c5dc5` with a migrator image, apply the two migrations (`AddRefreshTokensAndTokenVersion`,
  `AddDomainWorldName`), configure, accept, and take a new baseline. Details:
  [alpha-go-live § 3–4](../../guides/alpha-go-live.md#3-upgrade-the-alpha-api-to-kng-64-runbook-phase-3b).
- **Build Phase 3b from the package-fix merge (added 2026-10-12).** Build from knk-web-api `master` at or after the merge
  commit of [PR #9](https://github.com/PandiO/knk-web-api/pull/9), **`07fda99`** (merged 2026-10-12; it includes `30c5dc5`). It
  upgrades OpenTelemetry to 1.19 (fixes GHSA-vh2m-22xx-q94f and GHSA-g94r-2vxg-569j). AutoMapper 12.0.1
  (GHSA-rvv3-g6hj-g44x) is an accepted alpha risk, [KNG-165](https://linear.app/kngpandi/issue/KNG-165), and is
  suppressed via `NuGetAuditSuppress`. The `sdk:8.0` build should therefore print no NU190x advisory; record any that
  does appear.
- **Plugin/API wiring inside Docker:**
  - plugin `api.base-url: http://api:5000/api`, `api.auth.type: apikey`;
  - `region-http.bind-address: "0.0.0.0"` (never publish 8081), `web.public-url: https://<web-host>`;
  - API `MinecraftPlugin__BaseUrl=http://minecraft:8081`;
  - the Minecraft container needs an egress network next to the internal `backend`.

  See [alpha-go-live § 5](../../guides/alpha-go-live.md#5-minecraft-and-plugin-runbook-phases-45).
- **The web hostname is open:** `app.knightsandkings.net` (KNG-64 plan) or the earlier `knk.oldenzeelit.nl`. It is
  used by `web.public-url`, `Security__PasswordResetFrontendBaseUrl`, `AllowedHosts` and the Access application.
- **Email:** the `backend` network has no egress, so use `Email__Provider=Log` for the alpha unless the API gets one.

## Verified current state

- NAS SSH commands should be written as commands for the already-open,
  persistent NAS session. Label Windows PowerShell commands explicitly.
- Portainer authoritative instance: Compose-managed `portainer`, volume
  `portainer_data`, host HTTPS port 9444, accessible through
  `portainer.pyth`; stack editing works.
- Retired instance: `portainer-retired-core`, stopped, restart `no`, volume
  `core_portainer_data`.
- Alpha stack path: `/srv/docker/stacks/knk-alpha`.
- Alpha MySQL: `knk-alpha-mysql`, no host port, healthy, database
  `knightsandkings_alpha`, app user `knk_alpha_app`.
- Alpha API: `knk-alpha-api`, private `knk-alpha_backend` network only, no
  host port, healthy, image `knk-web-api:alpha-17ee730a` at
  `sha256:61c7e1f6bd451748e3bf6c1cc65f9a49fe5e1b12bdce2bf273c91f8bbea46251`.
- Secrets exist as protected files under
  `/srv/docker/stacks/knk-alpha/secrets/`; never display them.
- Clean alpha dump SHA-256:
  `dd877d5587982d2a31e5b0ec003cec92d47960cfed969f57bdf600b979ed975f`.
- Main archive SHA-256:
  `82b0afca0327f5e499250b7a030783e1c4fe365d0f56f4d5e29f47144533b150`.
- Hub archive SHA-256:
  `43944a03d673d2b6b8e92dfb2f016b389ca414baa135b600519e072f6ccb9cc4`.
- API source archive directory uses short commit `17ee730a`; the operator
  verified its companion checksum and confirmed the commit is on
  `origin/master`.
- API source archive SHA-256:
  `0a7a04ef8ce92f34ab8027d9cf2322b2005bb60d8e8c54f03d7e6d2820bc6ac7`.
- Pulled .NET base digests and final build evidence are in the progress
  report. The incorrect UID-1654 build is retained under diagnostic tag
  `knk-web-api:alpha-17ee730a-uid1654-failed`; do not deploy it.
- Host Compose SHA-256 after API promotion:
  `b4c501eedee03404f6829390dc9eb1d3b3eeb0dd0886136081cce5276a4e298c`.
  It canonically matches Portainer stack 42. The prior MySQL-only file is
  backed up as
  `/srv/docker/stacks/knk-alpha/compose.mysql-only.pre-api.20261011T151034Z.yaml`.
- No Minecraft, playit, or web-app alpha service has been started.

## Immediate continuation checklist

1. Re-read the report and runbook; refresh all repositories and inspect live
   Docker/Portainer state rather than trusting this snapshot.
2. Reconfirm both `knk-alpha` containers are healthy, their image IDs are
   unchanged, and `.HostConfig.PortBindings` remains empty.
3. Read the current multiworld audit/design work and inspect current
   `knk-plugin` `main`; do not assume KNG-114's existing-world loader exists.
4. Implement or verify the minimal KnK-owned loader: load `knk_hub` on the
   main thread, fail closed, keep primary-world assumptions explicit, and
   add deterministic hub/gameplay transitions. Do not add Multiverse Core.
5. Build and package the exact plugin revision that contains the accepted
   loader, then record its revision and artifact checksum.
6. Create a separate live Minecraft data path from the verified staging
   sources; never boot directly from staging.
7. Add Minecraft privately with Paper 1.21.10, Java 21, 1--4 GiB heap, and an
   approximately 5 GiB container limit. Do not add playit or public DNS yet.
8. Validate both worlds, plugin/API connectivity, clean shutdown/restart,
   database effects, and backups before adding another service.

## Decisions to preserve

- No Multiverse Core; KnK owns minimal multiworld lifecycle/transition logic.
- First deployment remains Paper 1.21.10 / Java 21. Paper 26.2 / Java 25 is a
  later cloned-environment upgrade.
- One Minecraft server, two concurrent worlds: main gameplay plus hub.
- playit.gg is for Minecraft only; public name is intended to be
  `play.knightsandkings.net` via GoDaddy DNS.
- Cloudflare Tunnel/nginx is for the web/API only.
- Alpha MySQL stays private; dev MySQL stays LAN-only.
- Initial Minecraft heap target 1–4 GiB with an approximately 5 GiB container
  limit because Frigate and other services share a 16 GiB host.
- Keep existing backups and retired Portainer state until restore tests and a
  retention decision are complete.

## Prompt for a new session

Copy the following prompt into a new session:

> Continue the Knights & Kings NAS closed-alpha deployment from the durable
> handoff in `knk-workspace/docs/ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md`.
> Also read `docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md`,
> `docs/guides/closed-alpha-deployment-runbook.md`, the repository `AGENTS.md`,
> `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, and the current
> `docs/ACTIVE_SESSIONS.md` before acting. Refresh all repositories and verify
> live state instead of trusting old branch names. The API milestone is
> complete: accepted image
> `sha256:61c7e1f6bd451748e3bf6c1cc65f9a49fe5e1b12bdce2bf273c91f8bbea46251`
> runs privately as `knk-alpha-api`, both health endpoints return 200,
> restart/seeding is idempotent, and no secret leaked. Reconfirm that state,
> then continue at Phase 4: inspect the current KNG-114/multiworld work,
> implement or verify the KnK-owned `knk_hub` loader, package the exact plugin
> revision, and prepare a separate live Minecraft data path from verified
> staging. Do not expose the API, start Minecraft before loader/data-path
> validation, add playit, alter the clean database baseline, delete backups,
> or remove retired Portainer state before the relevant validation passes.
> Give NAS commands for an already-open persistent SSH session and label any
> Windows PowerShell commands. Preserve these decisions: no Multiverse Core;
> Paper 1.21.10/Java 21 first; one server with main+hub; playit only for
> Minecraft at `play.knightsandkings.net`; Cloudflare/nginx only for web/API;
> MySQL private.
