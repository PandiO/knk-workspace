# Active Sessions

Live tracker of in-progress work across all four Knights and Kings repos
(`knk-workspace`, `knk-web-app`, `knk-web-api`, `knk-plugin`). Referenced by
`docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`.

**How to use this file:**
- Before starting work, check the table below for anything overlapping
  your intended scope. If something overlaps, stop and flag it rather than
  proceeding.
- Add a row when you start; scope by **feature**, not by repo, since most
  features span all three component repos.
- Update your row's Status/Last Updated whenever you pause, and move it to
  "Recently Completed" (below) when you finish, rather than deleting it
  outright — keeps a short trail of what just happened.
- This file will get concurrent edits from parallel sessions. That's
  expected — if you hit a merge conflict here, resolve it by keeping both
  rows rather than picking one; conflicts on this file are cheap to fix by
  hand.
- Keep entries short — this is a status board, not a design doc. Link out
  to the relevant branch, PR, or `docs/reports/` file instead of restating
  detail here.

## In progress

| Feature | Repos / files claimed | Owner (human / session) | Status | Started | Last updated |
|---|---|---|---|---|---|
| _(example)_ Siege minigame — capture point sync | web-api: `Services/SiegeService.cs`; plugin: `siege/` package | Claude Code session A | Implementing capture-point event handling | 2026-09-17 | 2026-09-17 |

## Recently completed

| Feature | Repos touched | Finished | Notes / link |
|---|---|---|---|
| _(example)_ Codebase scan — knk-plugin | knk-plugin (read-only), knk-workspace (docs) | 2026-09-17 | See `docs/reports/plugin-scan-2026-09-17.md` |
| Gate door snow-layer handling (item 7) | plugin: `knk-paper/.../gates/GateBlockPlacer.java` (`knk-plugin` branch `gate-structure-animation`); workspace: `docs/specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` | 2026-09-20 | Closed by explicit user decision **without** live verification: 7.1 implemented + unit-tested (`GateBlockPlacer.clearSnowLayerAbove`, `GateBlockPlacerTest`, 233/233 `knk-paper` green); 7.2's weather-dependent in-game retest on entity 14 was never done. If a hovering-snow report surfaces later, re-open with real evidence rather than assuming this already covers it. |
| Gate rotation gap-fill — rigid mid-swing animation (items 6.7/6.10/6.11, incl. 6.11.1-6.11.3) | plugin: `knk-core/.../gates/{RigidTransform,GateFrameCalculator,GateBlockPairing}.java`, `knk-core/.../domain/gates/CachedGateDoor.java`, `knk-paper/.../gates/{GateAnimationTask,GateLoaderAdapter,GateRestingFramePlacer}.java` (`knk-plugin` `17f016d`, branch `gate-structure-animation`); workspace: `docs/specs/gate-structure-animation/{ROTATION_GAP_FILL_DESIGN.md,GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md}` | 2026-09-20 | Confirmed live (4 open/close cycles, entity 14, `GeometryDefinitionMode=REGION`): no jam, no orphaned blocks, rigid swing. See `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` item 6.11.3 and `ROTATION_GAP_FILL_DESIGN.md` Decision 8.2 for full history. Item 7 (snow layer handling) is next. |
| Codebase scan — knk-web-api | knk-web-api (read-only); knk-workspace docs | 2026-09-18 | See `docs/reports/web-api-scan-2026-09-18.md`, `docs/architecture/web-api-architecture.md`, `docs/guides/web-api-reading-guide.md` |
| Codebase scan — knk-web-app | knk-web-app (read-only), knk-workspace (docs) | 2026-09-18 | See `docs/reports/web-app-scan-2026-09-18.md`, `docs/architecture/web-app-architecture.md`, `docs/guides/web-app-reading-guide.md` |
| InventoryMenu — engine reconciliation, design review, FormConfig scoping | knk-workspace (docs only) | 2026-09-21 | Reconciled Jan 2026 flexbox design against legacy bug findings; added search/filters/conditional-actions/permissions to spec; decided DB-persisted templates day one, FormConfig authoring UI deferred to a future update. See RECONCILIATION.md, DESIGN_REVIEW.md, FORMCONFIG_INTEGRATION.md. |
| Gate structure animation — merge feature branches to main/master | knk-web-app (`gate-animation-2` → `main`, `6426811..4ff5dc6`, 45 commits); knk-web-api (`gate-animation` → `master`, `3d89802..76644fe`, 41 commits); knk-plugin (`gate-structure-animation` → `main`, `3495144..e6e428b`, 65 commits) | 2026-09-21 | All three were clean fast-forwards (no divergent commits on the base branch, no conflicts), pushed directly to the shared branch per explicit user decision. knk-plugin initially looked like it had unrelated history (`no merge base`) — turned out to be a shallow-clone artifact in this sandbox; `git fetch --unshallow` resolved it and the branch was a true ff-ancestor of main. Verified: web-app builds clean and has zero new test regressions vs. pre-merge main (10 pre-existing failing suites, identical before/after). web-api's merge is conflict-free by diff but couldn't be built/tested here (no dotnet SDK in this sandbox). knk-plugin's merge is conflict-free by diff but couldn't be built here (repo.papermc.io blocked by sandbox network policy); ACTIVE_SESSIONS' own prior entries already document this exact code live-tested in-game through 2026-09-20. Followed by full gate-structure documentation pass — see `docs/architecture/gate-structures-design.md`, `docs/guides/developer/gate-structures-developer-guide.md`, `docs/guides/admin/gate-structures-admin-guide.md`, `docs/guides/users/gate-structures-player-guide.md`, and the dated changelog entry. |

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| _(none currently)_ | | | |
