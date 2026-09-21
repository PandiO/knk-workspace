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

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| InventoryMenu Phase 1 — core data model & persistence | knk-workspace (docs only so far; no code touched in knk-web-api/knk-plugin) | Missing `docs/specs/inventory-menu/IMPLEMENTATION_PLAN.md`, which the task brief for this phase relies on as the source of truth. It doesn't exist anywhere in the repo. What does exist under `docs/specs/inventory-menu/` has three *different, non-matching* "Phase 1" definitions: REQUIREMENTS_INVENTORY_MENU.md §8 / QUICK_REFERENCE.md ("Phase 1 = Core Framework" — the Java engine classes: `Menu`, `MenuSection`, `MenuItem`, `MenuUtil`, coordinate/slot calc, basic rendering — no DB persistence at all); ARCHITECTURE_DESIGN.md §8 ("Phase 1 = Parallel Implementation" — a legacy-migration phase, running v2 alongside v1); and RECONCILIATION.md's mention of a "migration Phase 1" (same axis as ARCHITECTURE_DESIGN's). None of these is "Phase 1 = core data model & persistence" as briefed, and none names the specific entity set (`MenuTemplate`, `MenuSectionTemplate`, `MenuItemTemplate`, `VariableBinding`, `ActionBinding`, `ConditionBinding`) or field-level requirements (e.g. explicit integer `sortOrder`) the brief asked me to implement — those names don't appear anywhere in the finalized docs. FORMCONFIG_INTEGRATION.md documents the *decision* that templates are DB-persisted from day one (consistent with DESIGN_REVIEW.md §Customizability and this file's 2026-09-21 "engine reconciliation" row below), and references a `MenuTemplatesDataAccess`-style gateway as a naming precedent, but that's a one-line mention, not a schema. Separately, `knk-plugin` has no `InventoryMenus` branch to "continue" (only `gate-structure-animation` exists there) and no menu-related code exists in any of the three component repos yet. Per this project's own hard rule ("if IMPLEMENTATION_PLAN.md or the other docs don't clearly cover something, stop and flag it rather than improvising"), a full entity schema (fields, types, relationships, cardinalities, enum values for Action/Condition kinds) was **not** invented to fill this gap. Needs: someone to write `IMPLEMENTATION_PLAN.md` (or confirm one of the existing "Phase 1"s / a different plan is actually the intended scope) before Phase 1 implementation can start. | 2026-09-21 |
