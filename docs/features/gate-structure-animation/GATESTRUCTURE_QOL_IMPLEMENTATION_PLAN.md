# GateStructure QOL Implementation Plan (Items 4–7)

**Status**: Plan drafted 2026-09-12. Item 4 complete (2026-09-12). Item 5 backend (5.1-5.3) complete (2026-09-12); plugin (5.4-5.7) complete (2026-09-12, `knk-plugin-v2`, uncommitted on branch `gate-structure-animation` - full solution builds, 352/352 tests pass, 12 pre-existing `@Disabled` Bukkit-runtime tests skipped); frontend (5.8-5.9) not started. Items 6-7 not started.
**Scope**: [QOL_BUGFIX_BACKLOG.md](../../QOL_BUGFIX_BACKLOG.md) items 4, 5, 6, 7 — the GateStructure-related follow-up work that sits on top of the already-complete base gate animation system (see [PHASE_STATUS.md](./PHASE_STATUS.md), Phases 1–10 done, Phase 11 partial).
**Explicitly out of scope for this plan**: reworking the GateStructure `FormConfiguration` (id 9)'s conditional step visibility — deferred until these four items are working (per 2026-09-12 discussion). Item 5 and item 6 below each need *some* minimal admin-facing CRUD to be usable at all; that's scoped narrowly (generic ObjectConfig CRUD, no bespoke wizard steps) and called out explicitly where it applies, so it isn't confused with the deferred form polish work.

---

## Ordering: Item 4 → 5 → 6 → 7

This is the order proposed, and it holds up against the dependency graph:

- **Item 4 first** — fully independent of the other three, small, and already fully decided (a single frontend fix in `normalizeFormSubmission.ts`). Doing it first matters practically, not just because it's easy: items 5 and 6 both involve repeatedly editing/saving gate configs and running scans during development, which hits this exact save-after-scan bug constantly if left unfixed. Fixing it first keeps the rest of the work friction-free.
- **Item 5 second** — this was already decided at the 2026-09-11 planning meeting: item 6's region data must land on the new `GateDoor` entity directly, or it needs a second migration later. Beyond that explicit dependency, item 5 also reshapes the animation engine's iteration model (from "one block list per structure" to "one block list per door"), which item 7 touches too — see below.
- **Item 6 third** — builds directly on `GateDoor` from item 5 (region capture, per-door state). It's also the largest, least-defined item (the rotation-rasterizer generalization and the round-trip WorldEdit-editing design are both explicitly unsized/undesigned as of the feasibility assessment), so it needs the foundation under it to be stable first.
- **Item 7 last** — the snow-layer fix hooks into the block-movement/placement code path (`GateAnimationTask`/`GateBlockPlacer`) that both item 5 (per-door iteration) and item 6 (region-based scanning, generalized rotation rasterization) substantially rewrite. Implementing it last means writing the snow-removal check once, against the final code shape, instead of writing it now and re-verifying/adapting it twice as 5 and 6 land.

---

## Item 4 — Fix GateStructure save-after-scan bug

**Reference**: [QOL_BUGFIX_BACKLOG.md #4](../../QOL_BUGFIX_BACKLOG.md#4-gatestructure-edit-form-fails-to-save-after-scanning-openedblocksnapshots-and-latently-blocksnapshots). Decision already made — this is implementation only, no further design needed.

**Status**: ✅ Complete (2026-09-12, `knk-web-app` commit). `normalizeFormSubmission.ts` strips any field whose `settingsJson` marks it as rendered by a headless world-task type (via the existing `isHeadlessTaskType` helper), generically by renderer/task type rather than by field name - covers both `blockSnapshots` and `openedBlockSnapshots`. New tests added; full suite green.

### 4.1 — Implement the fix
- In `knk-web-app/src/utils/forms/normalizeFormSubmission.ts` (around line 279): strip any field backed by a `GateBlockScan`/`GateOpenedBlockScan`-type field renderer from the outgoing entity payload, generically (by field/renderer type), not by hardcoding `blockSnapshots`/`openedBlockSnapshots` field names — so any future field of the same renderer type is covered automatically.
- Cover both `blockSnapshots` and `openedBlockSnapshots` in the same change (confirmed both hit the identical bug via the same `WorldBoundFieldRenderer.tsx` code path).

### 4.2 — Verify
- Reuse the direct-API test technique already proven during the FLOOD_FILL check (2026-09-12): PUT a gate with a populated snapshot-summary-shaped field via the API to confirm the backend still accepts/ignores it correctly, and separately drive an actual form save through the web app UI to confirm the frontend no longer sends the offending shape.
- Confirm the "Previously scanned: N blocks (status)" UI summary still displays correctly after the fix (draft resume, display) — only the final submission payload should change.
- Regression note for later: when item 5 moves these fields onto `GateDoor`, re-verify this fix still applies to the new per-door scan-summary fields (flagged again in item 5.7 below).

**No backend or migration changes required** — confirmed the backend already ignores these fields on write (`GateStructureMappingProfile.cs` `.Ignore()` mappings); this is a frontend-only fix.

---

## Item 5 — Multi-door support (`GateDoor` entity)

**Reference**: [QOL_BUGFIX_BACKLOG.md #5](../../QOL_BUGFIX_BACKLOG.md#5-support-for-multiple-gate-doors-per-gate-structure). Key decisions already made: per-door independent state + a structure-level cascading force-state override (for admin commands/permissions and the future Siege capture event); automatic migration for existing single-door gates; sequenced before item 6.

**Status**: 🔶 Backend complete (5.1-5.3, 2026-09-12, `knk-web-api-v2` commit); plugin complete (5.4-5.7, 2026-09-12, `knk-plugin-v2`, uncommitted); frontend (5.8-5.9, `knk-web-app`) not started.

- **Done (backend)**: `GateDoor` entity/migration (5.1) with the item-required data backfill (one `GateDoor` auto-created per existing `GateStructure`, current geometry/animation/state data carried over, `IsOpened`/`IsJammed` collapsed into `OpenedState`); models/DTOs/mapping/repositories/services/controllers (5.2-5.3), including the new `PATCH /api/GateStructures/{id}/overrides` endpoint for decision B's cascade mechanism. Full solution builds; 289/294 tests pass (the 5 failures are pre-existing on the unmodified baseline, confirmed via an isolated worktree comparison - unrelated to this work).
- **Additional decision made during backend implementation**: `FaceDirection` converted from a free-form string (validated ad hoc against a hardcoded allowlist) to a proper `GateFaceDirection` enum (`NORTH, NORTH_EAST, EAST, SOUTH_EAST, SOUTH, SOUTH_WEST, WEST, NORTH_WEST`) on `GateDoor`, for compile-time type safety. The migration's data backfill remaps the legacy lowercase-hyphenated values (e.g. `"north-east"`) to the new enum's member names (e.g. `"NORTH_EAST"`).
- **Migration NOT yet applied to any database.** The connection string in this environment points at the shared dev DB - per this plan's own cross-cutting note, back up the database before running `dotnet ef database update` for the `AddGateDoor` migration.
- **Done (plugin, 5.4-5.7)**: full per-door restructuring of `knk-plugin-v2`. Concretely:
  - `knk-api-client`: new `GateDoorDto`/`GateStructureOverridesUpdateDto` + `GateDoorsApi`/`GateDoorsApiImpl` (per-door state/health/operational-settings, mirroring the old now-removed `GateStructuresApi` methods); `GateStructureDto` trimmed to structure-level fields + embedded `gateDoors`, plus `getByIdWithSnapshots`/`updateOverrides`; `GateBlockSnapshotDto`/`GateBlockScanRequestDto` re-keyed from `gateStructureId` to `gateDoorId`.
  - `knk-core`: `CachedGate` renamed/split into `CachedGateDoor` (per-door data, unchanged field set, plus a `gateStructureId` and a nullable back-pointer to its parent) and new `CachedGateStructure` (identity, Siege fields, the 14 nullable override columns). `GateManager` now caches both, keyed separately by door id and structure id; `openGate`/`closeGate` etc. gate on `CachedGateDoor.isEffectivelyActive()`/`isEffectivelyDestroyed()` rather than the raw fields.
  - **Decision 5.0-B implementation**: resolved via `CachedGateDoor.isEffectivelyXxx()`/`getEffectiveXxx()` accessors that read `structure.getXxxOverride() ?? this.xxx` at call time (not a write-cascade) - setting/clearing an override is a single mutation on the one shared `CachedGateStructure` object, and every door reflects it immediately with no per-door loop. Wired into every consumer that gates a behavior (animation, damage/destroy/respawn, fire, pass-through, display).
  - **Decision 5.0-C implementation**: kept the existing in-memory `AnimationState` + `isJammed` flag as the live representation (lowest risk, no behavior change to the already-tested animation state machine); added `GateDoorOpenStateMapper` as a small wire-format boundary (`toWireValue`/`animationStateFromWireValue`/`isJammedFromWireValue`) used only where the plugin talks to the API. `GateDoorOpenState` was **not** introduced as a new Java domain type.
  - `GateLoaderAdapter` rewritten: `loadAll`/`loadForDistrict` now enumerate structure ids then fetch each via `getByIdWithSnapshots` (one call per structure, replacing the old one-call-per-gate snapshot fetch pattern), building one `CachedGateStructure` and N `CachedGateDoor`s from the embedded `gateDoors`.
  - All per-door consumers (`GateFrameCalculator`, `GateBlockPairing`, `GateAnimationTask`, `GateSpatialIndex`, `HealthSystem`, `GateFireSystem`, `GateStateSyncTask`, `GateDoorHitService`/events/listeners, `GatePassThroughService`, `GateRestingFramePlacer`, `GateWorldSyncChecker`, `CollisionPredictor`, `EntityPusher`, `EntityEvacuator`, `GateBlockOrientation`, `WorldGuardIntegration`, `DistrictGateLoader`) updated for the type rename; `GateSpatialIndex`/`GateDisplayManager`'s existing per-gate-id keying already generalizes to per-door for free.
  - `GateDisplayManager` renders decision 5.0-D's combined hover (`<StructureName>` gated by the existing, now-effective `GateNameDisplayMode`; `<DoorName>` gated by the new `DoorNameDisplayMode`; health; status) - still exactly one `TextDisplay` per door.
  - `GateCommand` extended for decision 5.0-D's two-level addressing: `resolveDoor` tries the full joined selector as a direct door id/name first (unchanged single-arg behavior), then falls back to `<structure> <door>` (args[0] = structure, rest = door) if that fails. New `/knk gate admin override <structure> <field> <value|clear>` subcommand covers `active`/`destroyed`/`invincible`/`canrespawn`/`openedstate` (the fields the backlog's two concrete use cases need); the remaining cascade-overridable display/pass-through fields are supported by the model/API but not yet exposed as a command - add a case when a concrete use needs one. `openedstate` additionally cascades a real `gateManager.openGate`/`closeGate` call per door so the override has immediate animated effect, not just a stored flag.
  - `GateBlockScanTaskHandler` re-keyed from `gateStructureId` to `gateDoorId` (parses `gateDoorId` out of `inputJson`, fetches via `GateDoorsApi.getById`), matching the backend's `WorldTaskService` expectation.
  - `EntityPusher.vectorFromFaceDirection` updated to match against the new uppercase-underscore `GateFaceDirection` wire values (e.g. `"NORTH_EAST"`) instead of the legacy lowercase-hyphenated ones.
  - Verification: `./gradlew clean build` succeeds across all three subprojects; 352/352 tests pass (12 pre-existing `@Disabled` Bukkit-runtime tests skipped, same as before this work).
- **Known follow-ups once the frontend lands**:
  - `WorldBoundFieldRenderer.tsx` (`knk-web-app`) still sends `gateStructureId` in the `GateBlockScan`/`GateOpenedBlockScan` task's `inputJson` - both the backend (already done) and the plugin (now done, this pass) expect `gateDoorId` there instead. This is the one remaining piece of the item 4 follow-up.
  - `ConditionalValueMatchValidator`'s `GateType`/`MotionType` FormConfig rule (5.3's admin-authored-data note) lives in the database, not source control, so it needs manual re-authoring against the new `GateDoor` fields once the frontend's per-door form exists - it can't be fixed from a code change.
  - 5.9's migration verification against entity 14 (and building its real second door) can only happen once the frontend can drive door CRUD, and the DB migration has actually been applied.

This is the largest architectural change of the four — a new entity, cross-repo DTO changes, and an animation-engine iteration model change. Phases below are ordered so each layer only starts once the layer under it exists.

### 5.0 — Design decisions to lock in before touching code

**A. Complete per-door field inventory** (expanded 2026-09-12 by walking every field on `GateStructureDto` and deciding per-door vs. structure-level — the original draft of this plan only listed geometry/scan fields and missed several):

*Per-door only, no structure-level override — always that door's own value:*
- Identity: `Name` (new field — see decision D)
- Health/lifecycle: `HealthCurrent`, `HealthMax`, `RespawnRateSeconds`
- Gate type & animation: `GateType`, `GeometryDefinitionMode`, `MotionType`, `AnimationDurationTicks`, `AnimationTickRate`, `FaceDirection`
- Geometry (PLANE_GRID): `AnchorPointId`, `OpenAnchorPointId`, `ReferencePoint1Id`, `ReferencePoint2Id`, `GeometryWidth`, `GeometryHeight`, `GeometryDepth`, `MotionDistanceBlocks`, `ClipToGeometryBounds`
- Geometry (FLOOD_FILL): `SeedBlocks`, `ScanMaxBlocks`, `ScanMaxRadius`, `ScanMaterialWhitelist`, `ScanMaterialBlacklist`, `ScanPlaneConstraint`
- Block management: `FallbackMaterialRefId`, `TileEntityPolicy`
- Rotation-specific: `HingeAxisId`, `RotationMaxAngleDegrees`, `MirrorRotation`
- Double-doors-specific: `LeftDoorSeedBlockId`, `RightDoorSeedBlockId`
- WorldGuard-named-but-repurposed (currently unused, migrated from the legacy project): `RegionClosedId`, `RegionOpenedId` — per item 6.2's decision, these get renamed to `ClosedRegionData`/`OpenedRegionData` and repurposed to hold item 6's captured polygon/cuboid vertex JSON, rather than staying WG region-name strings
- Pass-through: `PassThroughConditionsJson`
- Display position: `InfoDisplayLocationId`
- Continuous damage: `ContinuousDamageDurationSeconds`

*Per-door, with a nullable structure-level override (mechanism in decision B):*
`IsActive`, `CanRespawn`, `IsDestroyed`, `IsInvincible`, `OpenedState` (decision C), `AllowPassThrough`, `PassThroughDurationSeconds`, `ShowHealthDisplay`, `HealthDisplayMode`, `HealthDisplayYOffset`, `GateNameDisplayMode`, `StatusDisplayMode`, `AllowContinuousDamage`, `ContinuousDamageMultiplier`.

*Stays on `GateStructure`, unaffected:* `Id`, `Name`, `Description`, `CreatedAt`, `AllowEntry`, `AllowExit`, `WgRegionId`, `LocationId`/`Location`, `StreetId`, `DistrictId`, `HouseNumber`, `IconMaterialRefId`, the guard/defense system (`GuardSpawnLocationIds`, `GuardCount`, `GuardNpcTemplateId`), and Siege integration (`IsOverridable`, `AnimateDuringSiege`, `CurrentSiegeId`, `IsSiegeObjective`) — Siege capture is already decided to be a whole-structure event cascading to every door, not a per-door concept, so these stay put. Plus the new `GateDoors: List<GateDoorDto>` nav collection.

**B. Structure-level override mechanism: nullable override fields, resolved at read time — not a write-cascade**

This resolves the previously-open design question from the original backlog item (item 5, "still open" #4: concrete design for the force-state cascade). Rather than looping over every child door and writing N rows (fragile, non-atomic, awkward to undo), every overridable field above gets a matching **nullable** field on `GateStructure` (e.g. `IsActiveOverride: bool?`, `HealthDisplayModeOverride: GateInfoDisplayMode?`). The *effective* value used everywhere at runtime — animation engine, display, command responses — is `structureOverride ?? door.OwnValue`. Setting an override is a single-row write on `GateStructure`; clearing it (`null`) instantly reverts every door to its own value, no per-door cleanup needed. This also makes the future Siege "capture destroys all doors" case cheap and atomic: set `IsDestroyedOverride = true` once, and every door's effective state reads as destroyed without writing to each door row.

**C. `OpenedState`: replace the `IsOpened`+`IsJammed` booleans with one persisted enum**

Recommendation: **yes, an enum is the better model.** Two concrete findings support this:
- The plugin already has an in-memory `AnimationState` enum (`knk-core/.../domain/gates/AnimationState.java`) with `CLOSED, OPENING, OPEN, CLOSING` — the animation engine already thinks in these terms; the DB just doesn't persist that granularity today, only a flat `IsOpened` bool plus a separate, currently shallow `IsJammed` bool (verified: `IsJammed` is only touched in `CachedGate.java` today, not woven into the animation state machine anywhere else).
- Two independent booleans allow nonsensical combinations (`IsOpened=true` *and* `IsJammed=true` simultaneously) that a single enum makes structurally impossible.

Add a new persisted `GateDoorOpenState` enum: `CLOSED, OPENING, OPEN, CLOSING, JAMMED` (mirrors `AnimationState` plus `JAMMED` as its own distinct state — a jammed door isn't cleanly "open" or "closed," it's stuck mid-motion). This replaces both `IsOpened` and `IsJammed` on `GateDoor`. Whether the existing in-memory `AnimationState` gets retired in favor of this richer persisted enum, or kept as a plugin-internal "currently animating" detail synced from it, is an implementation decision for 5.4/5.5, not something to lock in here.

**D. New: `GateDoor.Name` + door-name display**

- New `Name` field on `GateDoor` (string), unique **within its parent `GateStructure`** (not globally) — enforce via a unique index/service-level check scoped to `GateStructureId`.
- Enables name-based command addressing: `/knk gate open <gateStructureName|gateStructureId> <gateDoorName|gateDoorId>` — the command resolver needs to accept either an id or a name at both levels.
- New `DoorNameDisplayMode` field on `GateDoor` (reuse the existing `GateInfoDisplayMode` enum type, same as `GateNameDisplayMode`/`StatusDisplayMode`), toggling whether the door's own name line shows in its hover.
- Each door's hover combines structure + door info, e.g.:
  ```
  <GateStructureName>
  <GateDoorName>
  <GateDoorHealthCurrent>
  <GateDoorOpenedState>
  ```
  each line gated independently by its own (possibly structure-overridden) display-mode setting.

### 5.1 — Backend: schema & migration
- New `GateDoors` table (`knk-web-api-v2`) with the full per-door field set from decision A, plus `Name`/`DoorNameDisplayMode` (decision D) and `OpenedState` (decision C, replacing `IsOpened`/`IsJammed`). FK to `GateStructure` (one-to-many).
- New nullable override columns on `GateStructure` for every field listed as overridable in decision A (decision B's mechanism).
- `GateBlockSnapshot`/`GateOpenedBlockSnapshot` ownership moves from `GateStructure` to `GateDoor` (FK change) — these are per-door block sets now, not per-structure.
- Data migration: for every existing `GateStructure` row (e.g. entity 14), auto-create exactly one `GateDoor` row carrying over its current geometry/state/snapshot data, with a generated default `Name` (e.g. the structure's own name, or "Door 1"). No manual admin re-authoring — this was the explicit decision.
- **Take a DB backup immediately before running this migration** — it restructures every existing gate row's field ownership across two tables; this is exactly the kind of schema change worth a safety net even in a small-team/solo-dev project.
- `GateStructure` keeps only the structure-level fields from decision A, plus the new override columns and the `GateDoors` nav collection.

### 5.2 — Backend: models, DTOs, mapping
- `GateDoor.cs` model; `GateDoorDto`/`GateDoorCreateDto`/`GateDoorUpdateDto` covering the full field set from decision A + C + D (follow the existing `GateStructureDto` pattern in `Dtos/GateStructureDtos.cs` for shape/converters).
- `GateDoorMappingProfile.cs` (new), following `GateStructureMappingProfile.cs`'s existing pattern — including the same `.Ignore()` treatment for `BlockSnapshots`/`OpenedBlockSnapshots` on write (per item 4's finding, this needs to carry over to the new owner).
- Update `GateStructureDto`/`GateStructureMappingProfile.cs` to drop the fields that moved to `GateDoor`, add the new override fields from decision B, and add the `GateDoors: List<GateDoorDto>` nav property.
- A small shared "effective value" resolver helper (e.g. `GateDoor.GetEffective<T>(door, structure, selector)`) is worth adding once here rather than re-deriving `structureOverride ?? door.OwnValue` inline at every call site across services/animation/display code.

### 5.3 — Backend: services, repositories, controllers
- `GateDoorService`/`GateDoorRepository` with full CRUD scoped under a parent `GateStructure` (add/edit/remove a door independent of its siblings and of the parent). Enforce the `Name` uniqueness-within-structure constraint from decision D here.
- `GateDoorsController` — new endpoints, e.g. `GET/POST /api/GateStructures/{id}/doors`, `PUT/DELETE /api/GateDoors/{doorId}`.
- Structure-level override endpoint(s) on `GateStructuresController` (e.g. `PATCH /api/GateStructures/{id}/overrides`) that set/clear the nullable override columns from decision B — this replaces the previously-vague "force-state endpoint" with a concrete mechanism.
- **Carry over admin-authored FormConfig validation rules that reference the fields moving to `GateDoor`**: `ConditionalValueMatchValidator`'s existing rule (`GateType in [DRAWBRIDGE, DOUBLE_DOORS] → MotionType must equal ROTATION`, `Services/ValidationMethods/ConditionalValueMatchValidator.cs`) is admin-authored FormConfig data tied to the old GateStructure-level fields — once `GateType`/`MotionType` move to `GateDoor`, this rule needs recreating against the new `GateDoor` form/fields, not just the code path.
- Permission model for who can call the override endpoint (backlog item 5, "still open" #5) — resolve alongside 5.3.

### 5.4 — Plugin: core model restructuring (`knk-core`, `knk-api-client`)
- `GateDoorDto.java` (new, `knk-api-client`), mirroring the C# DTO, including the effective-value resolution helper from 5.2's pattern.
- `CachedGate` (`knk-core/.../domain/gates/`) restructures from a single block list to a list of per-door block lists/state.
- `GateManager`/`GateLoaderAdapter` updates to load and cache the new per-door structure from the API, resolving effective (override-aware) values as it builds the in-memory representation.

### 5.5 — Plugin: animation engine and state systems, per-door
- `GateFrameCalculator`, `GateBlockPairing`, `GateAnimationTask`, `GateSpatialIndex` (all `knk-core`/`knk-paper` `.../gates/`) shift from "iterate `gate.getBlocks()`" to "iterate each door's block list independently."
- **These existing systems also need explicit updates for per-door state** (not just the animation-loop classes above) — found by auditing what currently reads/writes `GateStructure`'s state fields directly:
  - `HealthSystem.java` — health/damage/respawn/destroy logic moves to operating per-door.
  - `GateFireSystem.java`/`GateFireDamageTask` — continuous fire damage-over-time, same shift.
  - `GateStateSyncTask.java` — the periodic health-persistence sweep needs to sync per-door state (and be override-aware when reading "effective" values back).
  - `GateDoorHitService`/`GateDoorInteractEvent`/`GateDoorDamageEvent` — already named "Door" from the original single-door system; now need to actually resolve *which* door was hit, not just which structure.
- This is a refactor of already-working, well-tested code (per `PHASE_STATUS.md` Phases 7-10), so the priority is preserving existing single-door behavior exactly (entity 14's drawbridge must animate/take damage/respawn identically post-refactor) while making the multi-door case work — regression tests on the existing `GateFrameCalculatorTest`/`GateBlockPairingTest`/`GateSpatialIndexTest`/`HealthSystemTest`/`GateFireSystemTest` suites are the safety net.

### 5.6 — Plugin: world task handling updates
- `GateBlockScanTaskHandler.java` and the `GateBlockScan`/`GateOpenedBlockScan` task/DTO family shift from keying off `gateStructureId` to `gateDoorId` (a scan targets one door, not a whole structure).
- `WorldTaskService.CompleteAsync` (`knk-web-api-v2`) updates its snapshot-writing branch (`ClearBlockSnapshotsAsync`/`AddBlockSnapshotsAsync` and the `Opened*` equivalents) to operate against the `GateDoor` the task's `inputJson` names, not the `GateStructure`.

### 5.7 — Plugin: commands and per-door display
- `GateCommand.java` — extend to address a specific door by name or id (decision D's `/knk gate open <structure> <door>` syntax), and add a command/subcommand for setting/clearing structure-level overrides (decision B).
- `GateDisplayManager.java` — currently renders **exactly one** floating `TextDisplay` per gate (`Map<Integer, TextDisplay>` keyed by structure id, confirmed by reading the class). This needs to become one display **per door** (keyed by door id), anchored at that door's own `InfoDisplayLocationId`, rendering the combined structure+door hover format from decision D, with each line gated by its own effective (override-aware) display-mode setting.

### 5.8 — Frontend: minimal GateDoor CRUD
- **Not** the deferred FormConfig rework — just enough generic CRUD to create/edit/delete `GateDoor` rows under a `GateStructure`, following the same "ObjectConfig + generic framework, no custom pages" pattern already established for `GateStructure` itself (`PHASE_STATUS.md` Phase 5).
- Concrete existing files that need changes, not just new ones alongside them:
  - `src/config/objectConfigs.tsx` — the existing `GateStructureConfig` (20 fields) needs fields **removed** to match the slimmed-down `GateStructureDto` (leaving stale fields referencing properties that no longer exist would break the existing edit form), plus a new `GateDoorConfig`.
  - `src/utils/entityApiMapping.ts` — register `gatedoor` in all 5 CRUD functions, alongside the existing `gatestructure` registration.
  - `src/types/dtos/gateStructure/GateStructureDto.ts` — slim down to match the backend change; add a `GateDoorDto.ts` counterpart.
  - `src/apiClients/gateStructureClient.ts` — add a `gateDoorClient.ts` counterpart.
  - `src/utils/forms/gateGeometry.ts` — this dedicated geometry-handling utility (found while auditing, not previously in this plan) almost certainly needs updating for the field ownership change.
  - `src/utils/forms/enumFieldMetadata.ts` — add metadata for the new `GateDoorOpenState`/`DoorNameDisplayMode` enums.
- Re-verify item 4's fix applies to the `GateDoor`-owned scan-summary fields too (they'll have the identical "previously scanned" summary shape, now on a different entity).

### 5.9 — Migration verification
- Confirm entity 14 gets exactly one auto-migrated `GateDoor` row with all fields carried over correctly, and animates identically to its pre-migration behavior (same drawbridge motion, same block set, same health/respawn behavior).
- This is also the point to actually build out entity 14's second door (the lateral/vertical door mentioned in the backlog) as a real test of independent multi-door CRUD, independent animation, name-based command addressing, and the per-door hover display.

---

## Item 6 — Non-rectangular gate door shapes (WorldGuard/WorldEdit regions)

**Reference**: [QOL_BUGFIX_BACKLOG.md #6](../../QOL_BUGFIX_BACKLOG.md#6-non-rectangular-gate-door-shapes-via-worldguard-regions), [WORLDGUARD_REGION_FEASIBILITY.md](./WORLDGUARD_REGION_FEASIBILITY.md). Decision: WorldEdit-only capture with KnK-owned persistence, round-trip editing, rotation-type gates in scope for v1, region data lands on `GateDoor` (from item 5). FLOOD_FILL confirmed non-viable for entity 14's drawbridge by live test (2026-09-12) — this is the only remaining path to a non-rectangular drawbridge shape.

### 6.1 — Design spike (do this before writing implementation code)
Two pieces of this item are explicitly unsized/undesigned as of the feasibility assessment — size and design them first so the rest of the phases below have a real estimate and a concrete approach, rather than discovering scope mid-implementation:
- **Round-trip region editing**: how a stored polygon/cuboid vertex list gets re-hydrated into an active WorldEdit `LocalSession` so an admin can redraw it. `WgRegionIdTaskHandler`'s region-rename flow (`knk-paper/.../tasks/`) is the closest existing precedent, though it operates on WG regions, not WE-only sessions.
- **Rotation rasterizer generalization**: sizing and approach for generalizing `GateFrameCalculator.rasterizeRotationFrame` (currently rectangle-specific, `width-1`/`height-1` corner indices) to an arbitrary polygon footprint.

### 6.2 — Backend: region persistence on `GateDoor`
- Add a new `GeometryDefinitionMode` value (e.g. `REGION`) alongside `PLANE_GRID`/`FLOOD_FILL`.
- **Decided (2026-09-12)**: repurpose `GateDoor.RegionClosedId`/`RegionOpenedId` (moved from `GateStructure` in item 5, currently unused, migrated from the legacy project) to hold the raw polygon/cuboid vertex-list JSON directly, rather than adding separate new columns. Since their content changes from "an opaque WorldGuard region name string" to "the actual captured vertex data," **rename them** as part of this change (e.g. `ClosedRegionData`/`OpenedRegionData`) so the field name matches what it actually stores — keeping the old `*Id` naming while it holds a full vertex blob would mislead future readers. Follow the existing string-JSON convention already used for `SeedBlocks`/`ScanMaterialWhitelist` for the actual shape.
- This decision is what makes round-trip editing (6.4) meaningful: the stored JSON is loaded back into an active WorldEdit session for redefinition, deliberately mirroring WorldGuard's own `/rg redefine <region name>` workflow — an admin gets a familiar "select existing, redraw, resave" flow rather than a one-shot capture.

### 6.3 — Plugin: WorldEdit capture flow
- New task/command flow: an admin draws a selection with WorldEdit (`//sel poly` or `//sel cuboid`), then a KnK command persists the resulting vertex list against a `GateDoor` via the API — modeled on `WgRegionIdTaskHandler`'s existing selection-capture pattern, but stopping short of WG's persistent-region/flag layer (per the Option 2 decision).

### 6.4 — Plugin: round-trip re-edit flow
- Implements the design from 6.1: re-hydrate a `GateDoor`'s stored `ClosedRegionData`/`OpenedRegionData` (6.2) into a WorldEdit `LocalSession` so an admin can pull up an existing door and redraw/adjust it, rather than only being able to capture once.
- Modeled directly on WorldGuard's own `/rg redefine <region name>` (load the existing shape into the admin's active WorldEdit selection, let them redraw with normal WorldEdit tools, then re-save) — a new command in this shape, e.g. `/knk gate door redefine <gateStructure> <gateDoor> [closed|opened]`, following the same UX admins already know from WorldGuard rather than inventing a new interaction pattern.

### 6.5 — Plugin: region-based scanning
- Extend (or add a sibling to) `GateBlockScanTaskHandler` for the new `REGION` mode: iterate the stored region's contained blocks (via WorldEdit's `Region` iteration/`contains()`) instead of the anchor/ref1/ref2 lattice math used by `PLANE_GRID`.

### 6.6 — Plugin: animation rework
- Generalize `GateFrameCalculator.isWithinGeometryBounds` (currently an oblique-box clip check) into a polygon/region containment check — `WgRegionIdTaskHandler`'s existing polygon-vertex-containment code (lines 427-578) is a direct template, or WorldEdit's own `Region.contains(...)` can be used directly.
- Implement the rotation rasterizer generalization sized in 6.1.
- `GateBlockPairing`'s existing nearest-neighbor matcher already tolerates mismatched open/closed block counts (confirmed in the feasibility assessment) — no change needed there.

### 6.7 — Testing
- Draw the real irregular boundary of entity 14's drawbridge (the actual motivating case) via WorldEdit, capture both states, and confirm the animation interpolates correctly with no dropped/leaked blocks compared to the current `PLANE_GRID` rectangle baseline.
- Cover a rotation-type gate specifically, since that's the part of this item with the least-proven approach going in.

---

## Item 7 — Snow layer handling during gate door animation

**Reference**: [QOL_BUGFIX_BACKLOG.md #7](../../QOL_BUGFIX_BACKLOG.md#7-snow-layer-handling-during-gate-door-animation). Decisions already made: silent removal (no item drop), presence/absence check only (no partial-layer-height tracking).

### 7.1 — Implement
- Add a snow-layer check into the block-movement/placement code path (`GateAnimationTask`/`GateBlockPlacer`, by this point already reshaped by items 5 and 6's per-door iteration and region-based scanning) that:
  - detects a snow layer on the block position a door block is currently occupying, and
  - detects a snow layer on the position a door block is about to be placed into during an animation step,
  - and silently removes it in either case before/as the move happens.

### 7.2 — Test
- Reproduce the original bug (open a horizontal door, let snow accumulate, close it) on entity 14 or any similarly-oriented gate, confirm no hovering snow remains.
- Confirm the fix applies generically across gate types/door orientations, not just the drawbridge case it was reported against.

---

## Cross-cutting notes

- **Testing technique**: the direct-API-bypass approach proven during the 2026-09-12 FLOOD_FILL check (create a `WorkflowSession` + `WorldTask` via `curl`, let `HeadlessWorldTaskPoller` execute it against the live dev server, poll for completion) is a fast, form-UI-independent way to test scan-related changes throughout items 4–6 without waiting on frontend work to land first.
- **Effort sizing**: item 5 is the largest in raw scope (cross-repo schema/DTO/animation-engine change, now with a fuller field inventory per §5.0-A than the original draft of this plan had); item 6 has the least-certain effort (two explicitly unsized design questions in §6.1). Neither is sized in hours here — recommend sizing each phase above once item 5's field inventory is implemented and the 6.1 design spike is done, rather than estimating blind.
- **Breaking-change coordination**: item 5 moves fields off `GateStructure` onto `GateDoor` across three repos (`knk-web-api-v2`, `knk-api-client`/`knk-plugin-v2`, `knk-web-app`) at once. Since this is a single-team project without API versioning between these repos, phase order within item 5 matters for deployability: DB migration (5.1) → backend (5.2-5.3) → plugin (5.4-5.7) → frontend (5.8), each layer only deployed once the layer below it is live.
- **DB backup before item 5's migration** (5.1): called out inline there too, but worth repeating here — this is the single highest-blast-radius step in the whole plan, since it restructures every existing gate row's field ownership in one migration.
- **Admin-authored FormConfig data, not just code**: item 5.3 flags one example (`ConditionalValueMatchValidator`'s `GateType`/`MotionType` rule) but the general point applies broadly — any FormConfig/DisplayCondition rows authored against the old GateStructure-level fields (steps, visibility conditions, validators) need auditing once those fields move to `GateDoor`, since that configuration lives in the database, not in source-controlled code, and won't show up in a code diff.
