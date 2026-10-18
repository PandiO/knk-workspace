# Gate Structures — Developer Guide

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-09-21 (based on a full read-only code scan of `knk-web-api` `master`@`76644fe`, `knk-plugin` `main`@`e6e428b`, `knk-web-app` `main`@`4ff5dc6`)
**Companion docs:** `docs/architecture/gate-structures-design.md` (the "what and why" — read this first), `docs/guides/admin/gate-structures-admin-guide.md`, `docs/specs/gate-structure-animation/` (design-history trail)

Purpose: get a developer productive extending or debugging gate structures without re-deriving the file layout and cross-repo wiring from scratch.

## File/class map

### knk-web-api

| Concern | Files |
|---|---|
| Domain model | `Models/GateStructure.cs`, `Models/GateDoor.cs`, `Models/GateBlockSnapshot.cs`, `Models/GateOpenedBlockSnapshot.cs`, `Models/GateStructureEnums.cs`; `GatePassThroughMethod` enum lives on `Models/User.cs` |
| DTOs | `Dtos/GateStructureDtos.cs` (incl. `GateStructureOverridesUpdateDto`), `Dtos/GateDoorDtos.cs`, `Dtos/GateBlockScanDtos.cs` (world-task result contract) |
| Controllers | `Controllers/GateStructuresController.cs` (`api/GateStructures`), `Controllers/GateDoorsController.cs` (`api/GateDoors` + nested `api/GateStructures/{id}/doors`) |
| Services | `Services/GateStructureService.cs`, `Services/GateDoorService.cs`; scan-completion glue in `Services/WorldTaskService.cs` (`CompleteAsync`, `ExtractGateDoorId`) |
| Repositories | `Repositories/GateStructureRepository.cs`, `Repositories/GateDoorRepository.cs` — **health-hits-zero→destroyed and respawn-restores-health business rules live here**, not in the service layer |
| Mapping | `Mapping/GateStructureMappingProfile.cs`, `Mapping/GateDoorMappingProfile.cs` |
| Validation | `Services/ValidationMethods/ConditionalValueMatchValidator.cs` (the drawbridge/double-doors ⇒ ROTATION rule) |
| Region bridge | `Services/RegionService.cs` — HTTP client *to the plugin*, not region math itself |
| Migrations | See the design doc §History or `docs/specs/gate-structure-animation/` for the schema-evolution timeline; most recent is `20260913154909_RenameGateDoorRegionFields.cs` |
| Tests | `Tests/knkwebapi_v2.Tests/{Services/GateDoorServiceTests.cs, Mapping/GateStructureMappingProfileTests.cs, Mapping/GateDoorMappingProfileTests.cs, Services/WorldTaskServiceGateScanTests.cs, Services/ValidationMethods/ConditionalValueMatchValidatorTests.cs}` |

### knk-plugin

| Concern | Files |
|---|---|
| Pure geometry/animation math (`knk-core`) | `net/knightsandkings/knk/core/gates/{GateFrameCalculator,GateBlockPairing,RigidTransform,GateManager,GateSpatialIndex}.java` |
| Domain model (`knk-core`) | `net/knightsandkings/knk/core/domain/gates/{CachedGateStructure,CachedGateDoor,BlockSnapshot,AnimationState}.java` |
| Cross-module port | `net/knightsandkings/knk/core/ports/gates/GateControlPort.java`, implemented by `PaperGateControlAdapter` |
| Paper runtime | `knk-paper/.../gates/{GateAnimationTask,GateBlockPlacer,GateRestingFramePlacer,GateLoaderAdapter,GateDisplayManager,GateDoorHitService,GateFireSystem,GatePassThroughService,HealthSystem,GateBlockOrientation,GateDoorOpenStateMapper,GateStateSyncTask,GateWorldSyncChecker,DistrictGateLoader}.java` |
| Commands | `knk-paper/.../commands/GateCommand.java` |
| Listeners | `knk-paper/.../listeners/{GateEventListener,GateDamageConsequenceListener,GatePassThroughConsequenceListener}.java` |
| World tasks | `knk-paper/.../tasks/{GateBlockScanTaskHandler,GateDoorRegionCaptureHandler,GateRegionDataFormat}.java` |
| WorldGuard | `knk-paper/.../integration/WorldGuardIntegration.java` (now minimal — see below), `knk-paper/.../regions/WorldGuardRegionTracker.java` |
| Config | `knk-paper/src/main/resources/config.yml` (`gates:` block), `plugin.yml` (permission nodes) |
| Tests | `knk-core/src/test/.../gates/{GateFrameCalculatorTest,GateFrameCalculatorRegionModeTest,GateBlockPairingTest,RigidTransformTest,GateManagerTest,GateSpatialIndexTest}.java`; `knk-paper/src/test/.../gates/*Test.java`, `.../listeners/*Test.java`, `.../tasks/*Test.java` |

### knk-web-app

| Concern | Files |
|---|---|
| Types/DTOs | `src/types/dtos/gateStructure/{GateStructureDto,GateDoorDto,GateBlockSnapshotDto,GateStructureOverridesUpdateDto}.ts` |
| API clients | `src/apiClients/{gateStructureClient,gateDoorClient}.ts` |
| Static admin form config | `src/config/objectConfigs.tsx` (`GateStructureConfig`, `GateDoorConfig`) |
| Gate-specific form utils | `src/utils/forms/gateGeometry.ts` (lattice-hop width/height derivation), `src/utils/gateCoordinates.ts` |
| World-task-aware rendering | `src/components/Workflow/WorldBoundFieldRenderer.tsx` (headless gate-scan handling) |
| Inline child (GateDoor-from-GateStructure) authoring | `src/hooks/useRelationshipDrafts.ts`, `src/components/FormWizard/RelationshipDraftCard.tsx`, `src/components/FormWizard/ChildFormModal.tsx` |
| Tests | `src/apiClients/__tests__/{gateStructureClient,gateDoorClient}.test.ts`, `src/utils/forms/__tests__/gateGeometry.test.ts`, `src/utils/gateCoordinates.test.ts`, `src/config/{gateStructureConfig,gateDoorConfig}.test.ts`, `src/components/FormWizard/__tests__/{FieldRenderers.relationshipDrafts,ChildFormModal.workflowSession}.test.tsx` |

There is **no dedicated GatePage/GateDoorPage component** in the web-app — gates plug entirely into the generic `objectConfigs`-driven admin UI (`ObjectDashboard`, `FormWizardPage`, `DisplayWizard`, `PagedEntityTable`). Adding a new gate-related field to the simple form means editing `objectConfigs.tsx`; adding one that needs a world-task ("scan"/"capture" button) or inline-child behavior means authoring it via the backend `FormConfigBuilder` tool instead — those settings live in DB-seeded `FormConfiguration`/`FormField.settingsJson`, not in this repo's source.

## How it hooks into existing plugin systems

- **Hexagonal boundary**: `GateLoaderAdapter` (DTO→domain conversion) deliberately lives in `knk-paper`, not `knk-core`, specifically to avoid a circular dependency between `knk-core` and `knk-api-client` — `knk-core` never imports the REST DTOs.
- **Caching**: gates use their own bespoke `GateManager` cache (`ConcurrentHashMap`s, no TTL), **not** the generic `DataAccessFactory` cache-first gateway (`FetchPolicy`, TTL/retry from `config.yml`'s `cache: entities:` block) that every other entity type (Users, Towns, Districts, Locations, etc.) goes through. If you're extending the generic cache framework, gates are the one entity family that intentionally doesn't participate — don't assume adding a `gates:` entry to `cache: entities:` does anything.
- **Loading trigger**: `WorldGuardRegionTracker`'s player-enters-a-region callback triggers `DistrictGateLoader.loadIfNotAlreadyLoaded(districtId)` — gates for a district load lazily on first player entry, not eagerly for the whole world at once (beyond the initial full-server startup load).
- **Spatial lookup**: `GateSpatialIndex` is the O(1) `world+packedCell → gateId` map every hit-detection path (`GateDoorHitService`) uses; it's kept in lockstep with every block placement/removal, not rebuilt periodically. If you add a new code path that places/removes gate blocks directly (bypassing `GateBlockPlacer`), you must update the spatial index yourself or hit detection will silently miss those cells.
- **Events**: gate interaction/damage/ignite are custom, cancellable Bukkit events (`GateDoorInteractEvent`, `GateDoorDamageEvent`, `GateDoorIgniteEvent`) fired by `GateDoorHitService`, decoupled from their consequence listeners (`GateDamageConsequenceListener`, `GatePassThroughConsequenceListener`). Detection and consequence are deliberately separate — to change how much damage a cause deals, edit `GateDamageConsequenceListener.DAMAGE_BY_CAUSE`, not the detection code.
- **WorldGuard**: `WorldGuardIntegration` used to sync a door's WorldGuard regions on open/close; that sync was **removed** when door region fields were repurposed from WorldGuard region names to opaque captured-geometry JSON (item 6.2). The class and the animation task's reference to it are kept wired but unused, as a "may want it again" placeholder — don't assume it still does anything today.
- **Effective-value indirection**: any new gameplay code touching a cascade-overridable field on `CachedGateDoor` (active/destroyed/invincible/canRespawn/allowPassThrough/display modes) **must** use the `isEffectivelyXxx()`/`getEffectiveXxx()` accessor, not the raw field getter, or a structure-level admin override will be silently ignored.

## Extending the system

**Adding a new door field:**
1. Add the column/property to `GateDoor` (web-api model + migration) and `GateDoorDto`.
2. Add it to `Mapping/GateDoorMappingProfile.cs` (both directions) — remember the write-side pattern of falling back to the entity default when the DTO value is null.
3. Add it to `knk-plugin`'s `CachedGateDoor` and `GateLoaderAdapter`'s DTO→domain conversion.
4. If it should be structure-cascadable: add a matching `<Field>Override` to `GateStructure`/`CachedGateStructure`, `GateStructureOverridesUpdateDto`, the `ApplyOverride<T>` calls in `GateStructureService.UpdateOverridesAsync`, and an `isEffectivelyXxx()` accessor on `CachedGateDoor` — and make sure the AutoMapper profile still `.Ignore()`s it on the general write path.
5. Add it to `knk-web-app`'s `GateDoorDto.ts` and, if it should be editable through the simple admin form, `GateDoorConfig` in `objectConfigs.tsx`.

**Adding a new geometry mode**: extend `GeometryDefinitionMode` in all three repos' enums, add a scan branch in `GateBlockScanTaskHandler`, and a bounds-check branch in `GateFrameCalculator.isWithinGeometryBounds`/`rasterizeRotationFrame`. REGION mode is the most recent precedent to follow.

**Adding a new pass-through mode**: extend `GatePassThroughMethod` (both repos) and add a branch in `GatePassThroughService`.

**Adding a new damage cause**: add an entry to `GateDamageConsequenceListener.DAMAGE_BY_CAUSE` and a detection call from the relevant Bukkit event in `GateEventListener`.

## Known thin spots worth checking before you touch adjacent code

- `GateStructureRepository.GetGatesByDomainAsync` is a stub — it ignores `domainId` and returns every gate structure. Don't build on it assuming it filters.
- `GateBlockScanRequestDto` is defined but never used; `WorldTaskService.ExtractGateDoorId` reads a raw `gateDoorId` property out of `WorldTask.InputJson` directly instead.
- `GateStructureService` (CRUD, `UpdateOverridesAsync`, location resolution) and `GateDoorRepository`'s health/respawn business rules have no or minimal direct test coverage on the web-api side — treat changes there as higher-risk until covered.
- `objectConfigs.tsx`'s `GateDoorConfig.geometryDefinitionMode` select only offers `PLANE_GRID`/`FLOOD_FILL` even though the DTO type includes `REGION` — a real gap between the type layer and the static form, not an intentional restriction.
- `src/utils/gateCoordinates.ts`'s `parseCoordinateInput` has no production call site outside its own test — likely dead code.
