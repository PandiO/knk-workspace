# Handoff: NAS closed-alpha infrastructure

**Date:** 2026-10-11
**Status:** Pre-KNG-64 API accepted privately; Phase 3b is blocked on API PR #9 review/merge and live-state re-verification
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
readiness reports the database healthy. The immediate next phase is the
KNG-64/package-fixed API replacement in runbook Phase 3b. Only after that
passes should the deployment continue to the coordinated KnK-owned multiworld
loader and private Minecraft service preparation. Do not expose the API or
start Minecraft before the relevant prerequisites pass.

## Addendum (Claude Code, 2026-10-11, after the KNG-64 merge)

Read this before Phase 4.

- **The deployed API predates KNG-64.** `17ee730a` is before the KNG-64 merge (knk-web-api `30c5dc5`).
  It is private, so nothing is exposed. Do the new runbook **Phase 3b** before the plugin connects: back up,
  run the holder-id clash check (the dev dump predates the `admin`/Staff id-29 repair), build from `master`
  ≥ `30c5dc5` with a migrator image, apply the two migrations (`AddRefreshTokensAndTokenVersion`,
  `AddDomainWorldName`), configure, accept, and take a new baseline. Details:
  [alpha-go-live § 3–4](../../guides/alpha-go-live.md#3-upgrade-the-alpha-api-to-kng-64-runbook-phase-3b).
- **Build Phase 3b from the package-fix merge (added 2026-10-12).** Build from knk-web-api `master` at or after the merge
  commit of [PR #9](https://github.com/PandiO/knk-web-api/pull/9) (unmerged as of 2026-10-12; it's ahead of `30c5dc5`). It
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

Repository refresh on 2026-10-12 (live NAS state still requires a fresh
operator-side check):

- Default branches were unchanged from the tracker snapshot: knk-workspace
  `main` `a38286c`, knk-web-api `master` `917537a`, knk-web-app `main`
  `38854ba`, and knk-plugin `main` `1b3e06c2`.
- [knk-web-api PR #9](https://github.com/PandiO/knk-web-api/pull/9) remained
  open and unreviewed at `25b4776`, cleanly mergeable onto `917537a`. Both
  reported `fresh-database` check runs passed. Do not build Phase 3b until it
  is reviewed, merged, and the exact new `master` merge commit is refreshed.
- The coordinated hub/multiworld work is now pushed but remains unmerged:
  [knk-web-api PR #8](https://github.com/PandiO/knk-web-api/pull/8) at
  `7ec345f`, [knk-web-app PR #6](https://github.com/PandiO/knk-web-app/pull/6)
  at `a17cb46`, and [knk-plugin PR #11](https://github.com/PandiO/knk-plugin/pull/11)
  at `6125ad43`. All three were open and cleanly mergeable. The branch handoff
  records dev smoke tests and green automated suites, but not the full
  restart/missing-hub/fail-closed acceptance required before alpha deployment.
  Preserve its API -> web -> plugin merge order and do not deploy the branch
  heads directly.

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
- The user copied the accepted hub archive to the development server and
  reported that it works there. Treat that as a useful smoke test, not as the
  full loader/restart/fail-closed acceptance required before deployment.

## Immediate continuation checklist

1. Re-read the report and runbook; refresh all repositories and inspect live
   Docker/Portainer state rather than trusting this snapshot.
2. Reconfirm both `knk-alpha` containers are healthy, their image IDs are
   unchanged, and `.HostConfig.PortBindings` remains empty.
3. Complete runbook Phase 3b before the plugin connects. Wait for
   knk-web-api PR #9 to merge, then build only from its exact `master` merge
   result; take the pre-upgrade dump, repair any holder-ID clash, run the two
   KNG-64 migrations through the one-off migrator, configure and accept the
   private replacement API, run the security probe, and take a new baseline.
4. Confirm the web hostname with the user before finalizing API/web/plugin
   settings. The open choices are `app.knightsandkings.net` and the older
   `knk.oldenzeelit.nl`; do not guess.
5. Coordinate with the active `claude/blissful-fermat-b7ihrz` session before
   touching the multiworld loader. Inspect the exact pushed/merged plugin
   revision and do not duplicate its work.
6. Verify the minimal KnK-owned loader: load `knk_hub` on the main thread,
   fail closed, keep the main world primary, provide deterministic transitions,
   and pass full restart and missing-hub tests. Do not add Multiverse Core.
7. Build and package the exact accepted plugin revision, then record its
   revision and artifact checksum.
8. Create a separate live Minecraft data path from the verified staging
   sources; never boot directly from staging.
9. Add Minecraft privately with Paper 1.21.10, Java 21, 1--4 GiB heap, and an
   approximately 5 GiB container limit. Do not add playit or public DNS yet.
10. Validate both worlds, plugin/API connectivity, clean shutdown/restart,
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

Use the fully rewritten, copy-ready prompt in
[2026-10-11-closed-alpha-continuation-prompt.md](2026-10-11-closed-alpha-continuation-prompt.md).
It includes the Phase 3b gate added after the KNG-64 merge, the package-fix PR
gate, current private API/MySQL evidence, the active multiworld-session
coordination boundary, verified world archives, and the unresolved web-hostname
decision. Older copies that say to build `17ee730a`, start Phase 4 immediately,
or create a disposable preflight stack are obsolete.
