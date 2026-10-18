# Changelog — Gate Structure Animation Merge — 2026-09-21

Fast-forward merge of each repo's `gate-structure-animation`/`gate-animation`/`gate-animation-2` feature branch into its default branch. All three were clean fast-forwards — no divergent commits on the base branch at merge time, no conflicts.

| Repo | Branch → target | Range | Commits |
|---|---|---|---|
| `knk-web-app` | `gate-animation-2` → `main` | `6426811..4ff5dc6` | 45 |
| `knk-web-api` | `gate-animation` → `master` | `3d89802..76644fe` | 41 |
| `knk-plugin` | `gate-structure-animation` → `main` | `3495144..e6e428b` | 65 |

This branch's scope covers items 4–7 of the [GateStructure QOL Implementation Plan](../specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md), plus preceding gate-animation foundation work already tracked in [PHASE_STATUS.md](../specs/gate-structure-animation/PHASE_STATUS.md). See the design doc (`docs/architecture/gate-structures-design.md`) for the full current-state feature description this merge contributes to — this entry covers only what changed in this merge itself.

## Item 4 — Save-after-scan fix

`knk-web-app`: `normalizeFormSubmission.ts` now strips any field backed by a `GateBlockScan`/`GateOpenedBlockScan` world-task renderer from the outgoing entity payload generically (by renderer type, not hardcoded field names) — fixes a 400 error when saving a gate after running a block scan.

## Item 5 — Multi-door support (`GateDoor` entity)

The largest single piece of work in this merge, spanning all three repos:

- **`knk-web-api`**: new `GateDoor`/`GateBlockSnapshot`/`GateOpenedBlockSnapshot` schema (migration `AddGateDoor`), moving nearly every per-door field off `GateStructure`. New `GateDoorsController`/`GateDoorService`/`GateDoorRepository`. 14 cascading structure-level override fields added (`GateStructureOverridesUpdateDto`, `PATCH /api/GateStructures/{id}/overrides`). `GateDoorOpenState` enum (`CLOSED`/`OPENING`/`OPEN`/`CLOSING`/`JAMMED`) replaces the old `IsOpened`+`IsJammed` boolean pair.
- **`knk-plugin`**: `knk-core`/`knk-api-client` restructured around `CachedGateDoor` (per-door animation/state) with `CachedGateStructure` holding only structure-level/override/siege fields. Animation engine, world-task handling, commands, and per-door display all updated for the door model. A live-dev-server concurrency bug was found and fixed along the way.
- **`knk-web-app`**: `GateDoorDto`/`gateDoorClient` added; `GateDoorConfig` split out of `GateStructureConfig` in `objectConfigs.tsx`; minimal GateDoor CRUD (item 5.8) plus inline, resumable GateDoor creation/editing from the GateStructure form (items 5.11/5.12 — `useRelationshipDrafts`, `RelationshipDraftCard`, `ChildFormModal` parent-link prefill) so an admin can author a structure's doors without leaving its form.

## Item 6 — Non-rectangular gate door shapes (WorldGuard/WorldEdit regions)

- New `GeometryDefinitionMode.REGION`, backed by WorldEdit-captured vertex JSON (`ClosedRegionData`/`OpenedRegionData` — repurposed from the older WorldGuard-region-*name* fields, migration `RenameGateDoorRegionFields`).
- `knk-plugin`: `/knk gate door capture`/`redefine` commands (`GateDoorRegionCaptureHandler`), region-based block scanning, and an animation rework generalizing the rotation rasterizer and bounds checks to REGION geometry — including same-day `CONVEX_POLYHEDRON` capture support to close an orientation gap PLANE_GRID/POLYGON2D/CUBOID couldn't cover (vertical/diagonal doors).
- **Rotation gap-fill saga** (the bulk of the plugin's commit volume in this merge): REGION-mode live testing against a real drawbridge surfaced three bugs, fixed in sequence — a block-pairing/orientation bug (Hungarian-algorithm rework replacing a greedy matcher), orphaned/stuck blocks under multi-frame animation skips, and a render cap that dropped extra open-scan blocks. Fixing the pairing/orientation issue then required a full mid-swing motion redesign (the "rigid transform + residual" hybrid, `RigidTransform`/Kabsch fit, quintic residual taper, distance-based snap) after two earlier, simpler approaches (uniform-rigid-only, then a fixed-progress settle threshold) were each live-tested and found insufficient. Full decision trail in [ROTATION_GAP_FILL_DESIGN.md](../specs/gate-structure-animation/ROTATION_GAP_FILL_DESIGN.md).
- `knk-web-api`: new `GateDoor` region-data update endpoint (`PUT /api/GateDoors/{id}/region`) and `ConditionalValueMatchValidator` enforcing `MotionType == ROTATION` for `DRAWBRIDGE`/`DOUBLE_DOORS`.
- `knk-web-app`: `gateGeometry.ts`'s lattice-hop-based width/height derivation (replacing an earlier Euclidean-distance calculation that overcounted diagonal spans) and REGION mode added to the DTO's type union (**not yet wired into the static admin form's geometry-mode select** — see the developer guide's known-gaps section).

## Item 7 — Snow layer handling during gate door animation

`knk-plugin`: `GateBlockPlacer.clearSnowLayerAbove` silently clears a layered-snow block (not `SNOW_BLOCK`) resting above any cell a gate places into or removes from, since gate block edits always disable physics and would otherwise leave snow hovering. Landed in both of `GateBlockPlacer`'s world-touching entry points, covering every animation step. Unit-tested (`GateBlockPlacerTest`, 7 new cases); the live, weather-dependent in-game verification was explicitly skipped by developer decision and closed untested rather than left pending.

## Also included in this merge (not separately tracked as backlog items)

- `knk-web-app`/`knk-web-api`: unrelated form-system work that rode along on the same branches — relationship-draft resumability made generic enough to also apply to non-gate one-to-many/many-to-many fields, boolean-field checkbox pre-check fix, nested child entity persistence on form completion, case-insensitive structure-id resolution for GateDoor creation, user CRUD wiring, password-reset flow, game settings admin editor.
- All three repos: a `CLAUDE.md` added with verified repo-specific agent conventions (final commit on each branch before merge).

## Verification performed at merge time

- **`knk-web-app`**: `npm run build` succeeds (lint warnings only, no errors); `npm run test:ci` shows the identical set of 10 pre-existing failing test suites before and after the merge — no regressions introduced.
- **`knk-web-api`**: diff against `master` is conflict-free; could not build/run tests in the merging sandbox (no .NET SDK available there).
- **`knk-plugin`**: diff against `main` is conflict-free (true fast-forward once an initial shallow-clone artifact was resolved via `git fetch --unshallow`); could not build in the merging sandbox (PaperMC's Maven repo isn't reachable through that sandbox's network policy). `ACTIVE_SESSIONS.md` already documents this exact code confirmed live-tested in-game through 2026-09-20, prior to this merge.

## Plan status

All of items 4–7 were already implementation-complete and closed (per developer live-testing) before this merge — this merge is the step that lands that already-finished work on each repo's default branch. See the implementation plan doc for the merge-completion note added alongside this changelog entry.
