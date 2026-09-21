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
| InventoryMenu Phase 1 — core data model & persistence | web-api: `MenuTemplate`/`MenuSectionTemplate`/`MenuItemTemplate`/`VariableBinding`/`ActionBinding`/`ConditionBinding` entities, EF migration, `MenuTemplatesController` CRUD, seed mechanism (`knk-web-api` branch `claude/inventory-menu-phase-1-wxl3z0`); plugin: `MenuTemplatesDataAccess` gateway, domain records, API-client DTOs/mapper/impl, config wiring (`knk-plugin` same branch name); workspace: `docs/specs/inventory-menu/IMPLEMENTATION_PLAN.md` | 2026-09-21 | Migration generated + applied end-to-end against a real local MySQL 8.0 instance and exercised through the running API (nested create/read/update/delete, validation errors) — caught and fixed a real EF fixup bug this way. Plugin side verified with direct `javac` against real dependency jars, since `repo.papermc.io` is blocked by this session's egress policy (confirmed via the proxy's own status endpoint, not routed around) and Gradle couldn't resolve `paper-api`; `KnkApiClient.getMenuTemplatesQueryApi()` confirmed present in compiled bytecode via `javap`. **Branch note:** the task originally named `knk-plugin`'s `InventoryMenus` branch, but that branch's history turned out to be rooted in a pre-restructure repo scaffold unrelated to current `main` (`git merge` refuses it as "unrelated histories"). Per explicit user decision, `InventoryMenus` is being left alone/ignored — `claude/inventory-menu-phase-1-wxl3z0` (forked cleanly from `main`) is the branch going forward for this feature on `knk-plugin` too. Not yet built/tested: knk-paper's own edits (`KnKPlugin.java`, `KnkConfig.java`, `ConfigLoader.java`, `DataAccessFactory.java`) could only be reviewed by hand against the `ItemBlueprints` precedent, since compiling them needs `paper-api` directly. Needs before Phase 2: a real Gradle build once `paper-api` is reachable, and any decisions Phase 2 (rendering engine) surfaces that Phase 1 didn't need to make. |
| Gate door snow-layer handling (item 7) | plugin: `knk-paper/.../gates/GateBlockPlacer.java` (`knk-plugin` branch `gate-structure-animation`); workspace: `docs/specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` | 2026-09-20 | Closed by explicit user decision **without** live verification: 7.1 implemented + unit-tested (`GateBlockPlacer.clearSnowLayerAbove`, `GateBlockPlacerTest`, 233/233 `knk-paper` green); 7.2's weather-dependent in-game retest on entity 14 was never done. If a hovering-snow report surfaces later, re-open with real evidence rather than assuming this already covers it. |
| Gate rotation gap-fill — rigid mid-swing animation (items 6.7/6.10/6.11, incl. 6.11.1-6.11.3) | plugin: `knk-core/.../gates/{RigidTransform,GateFrameCalculator,GateBlockPairing}.java`, `knk-core/.../domain/gates/CachedGateDoor.java`, `knk-paper/.../gates/{GateAnimationTask,GateLoaderAdapter,GateRestingFramePlacer}.java` (`knk-plugin` `17f016d`, branch `gate-structure-animation`); workspace: `docs/specs/gate-structure-animation/{ROTATION_GAP_FILL_DESIGN.md,GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md}` | 2026-09-20 | Confirmed live (4 open/close cycles, entity 14, `GeometryDefinitionMode=REGION`): no jam, no orphaned blocks, rigid swing. See `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` item 6.11.3 and `ROTATION_GAP_FILL_DESIGN.md` Decision 8.2 for full history. Item 7 (snow layer handling) is next. |
| Codebase scan — knk-web-api | knk-web-api (read-only); knk-workspace docs | 2026-09-18 | See `docs/reports/web-api-scan-2026-09-18.md`, `docs/architecture/web-api-architecture.md`, `docs/guides/web-api-reading-guide.md` |
| Codebase scan — knk-web-app | knk-web-app (read-only), knk-workspace (docs) | 2026-09-18 | See `docs/reports/web-app-scan-2026-09-18.md`, `docs/architecture/web-app-architecture.md`, `docs/guides/web-app-reading-guide.md` |
| InventoryMenu — engine reconciliation, design review, FormConfig scoping | knk-workspace (docs only) | 2026-09-21 | Reconciled Jan 2026 flexbox design against legacy bug findings; added search/filters/conditional-actions/permissions to spec; decided DB-persisted templates day one, FormConfig authoring UI deferred to a future update. See RECONCILIATION.md, DESIGN_REVIEW.md, FORMCONFIG_INTEGRATION.md. |

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| _(none currently)_ | | | |
