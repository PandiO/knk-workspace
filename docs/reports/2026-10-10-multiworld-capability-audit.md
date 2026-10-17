# Multiworld capability audit and hub implementation readiness

**Status:** Code/schema-source audit complete. No live server, no database and no runtime prototype were available. Nothing here is implemented.
**Date:** 2026-10-10
**Last updated:** 2026-10-10
**Issue:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109) (hub), with [KNG-52](https://linear.app/kngpandi/issue/KNG-52) and [KNG-58](https://linear.app/kngpandi/issue/KNG-58). The gap issues created from this audit are listed in §12.
**Branch:** knk-workspace `claude/blissful-fermat-b7ihrz`. This follows [PR #11](https://github.com/PandiO/knk-workspace/pull/11), which was merged on 2026-10-10 before this audit started.
**Design:** [hub DESIGN §16](../specs/hub/DESIGN.md) holds the readiness summary and the phased plan.

## 0. Evidence base

| Repo | Default branch | SHA audited | Notes |
|---|---|---|---|
| knk-plugin | `main` | `973aa68b6843b2d631273885ea4752ca51d12b68` | KNG-58 P0 (`239ea49`) is **not** on `main`. It exists only on `claude/worldguard-entry-deny-bypass-sj1j7g`. |
| knk-web-api | `master` | `8cce48d00c4af2c591da33ef5ac2cf599281eddf` | |
| knk-web-app | `main` | `12c1d6001c41e1e4bcac29bee6067f1e8d3e858b` | |
| knk-workspace | `main` | `1c600a6` (PR #11 merge) | |

**Evidence types used in the matrix:**
- **CR:** code review of the default branch, cited as `path:line`.
- **MIG:** the EF model, `KnKDbContext` or `KnKDbContextModelSnapshot`. The real MySQL schema was **not inspected**, because no database was reachable from this session. Every schema statement is therefore *migration evidence, DB unverified*.
- **EXT:** external versioned source or binary, cited with its hash or commit.
- **DOC:** workspace documentation.
- **LIVE:** a live test. **None was run.**

**Path abbreviations:**
- `P/` = knk-plugin `knk-paper/src/main/java/net/knightsandkings/knk/paper/`
- `C/` = knk-plugin `knk-core/src/main/java/net/knightsandkings/knk/core/`
- `AC/` = knk-plugin `knk-api-client/src/main/java/net/knightsandkings/knk/api/`
- `API/` = knk-web-api root
- `APP/` = knk-web-app `src/`

Line numbers are at the SHAs above. Four parallel read-only traces produced the citations. The highest-impact claims (rows W1, W5, R1, G1, A2, H1) were re-checked by hand.

## 1. Verdict

**Concurrent multiworld is not supported for the Domain layer today.** Every other layer mostly carries the world correctly: Location, teleports, Game Settings per world, roads/navigation, lootboxes, Siege locations and the gate block index.

The root cause is that **no Domain (Town, District, Structure, GateStructure) stores its world**. The WorldGuard region id is the *only* key from region to domain, and it is used everywhere in that chain:
- API lookups;
- plugin caches;
- the region enter/leave tracker;
- the access preview;
- KNG-56 access flags;
- managed-region repair;
- discovery;
- the plugin's region HTTP endpoints.

Two consequences follow:
1. With identical region names in the hub and gameplay worlds, domains collide.
2. A move between same-named regions in different worlds produces no enter/leave transition.

Gates add a second, independent leak: a door with a blank world is animated in *every* world.

For the hub there are three further gaps:
- **Admission flash:** the player is teleported after `PlayerJoinEvent`, so they can briefly appear in gameplay.
- **Broken health probe:** the plugin calls a path that does not exist and parses the wrong status values. There is no service-wide outage state.
- **Siege respawn:** Siege's respawn handler would return an evacuated participant to the arena.

Managed regions are renamed `domain_<id>` (`API/Services/DomainRegionNameFinalizer.cs:13-17`), which is globally unique. This **reduces** the collision risk for domains created through the web flow. Hand-made and legacy region ids are not covered, and the hub acceptance test explicitly requires identical names to work, so this does not close the gap.

## 2. Capability/gap matrix

The **Hub?** column:
- **H**: blocks the first hub deployment, which runs separate concurrent worlds, each containing domains, Districts and gates.
- **G**: a general multiworld follow-up that does not block the hub.
- **H\***: blocks only the outage/admission part of the hub, not multiworld itself.

### 2.1 Database, entities and API

| ID | Subsystem | Status | Evidence | Hub? | Suggested fix | Type |
|---|---|---|---|---|---|---|
| D1 | Domain world identity | **Gap** | **Domain has no world column.** Fields are at `API/Models/Domain.cs:10-67`. Subtypes add none (`Town.cs:10-15`, `District.cs:10-19`, `Structure.cs:9-20`, `GateStructure.cs:10-59`). Mapping is TPT (`API/Properties/KnKDbContext.cs:187,1429,1444,1467,1473`; snapshot `UseTptMappingStrategy` `:1109`). | H | Add `WorldName` (required) to base `domains`, with a backfill (§4). | MIG+CR |
| D2 | Derived world via Location | Gap | **World can only be inferred from the Domain's Location, which is optional.** `Domain.LocationId` is nullable (`Domain.cs:25`), one-to-one with a unique index (`KnKDbContext.cs:1413-1417`). `Location.World` is a nullable `longtext` with no index, no DB default and no FK (snapshot `:2448-2449`; C# default `"world"` at `Location.cs:16`). | H | As D1. Validate a Location's world against the domain world. | MIG+CR |
| D3 | Domain↔Location delete direction | Risk | **Deleting a Location deletes its Domain.** The FK sits on Domain with Cascade (`KnKDbContext.cs:1417`; snapshot `:1812`). | G | Review: Restrict or SetNull. | MIG |
| D4 | Region id uniqueness | **Gap** | **`WgRegionId` has no unique constraint and no index** (snapshot `:1090-1102`). The code itself says "WgRegionId isn't unique" (`API/Services/DiscoveryService.cs:141`). | H | Unique `(WorldName, WgRegionId)` where non-empty. | MIG+CR |
| D5 | Parent/child same world | **Gap** | **Create checks only that the parent exists, never its world** (`API/Services/DistrictService.cs:108-112`, `StructureService.cs:64-70`). District→Town is Restrict (`KnKDbContext.cs:1448-1453`). | H | Reject a cross-world parent/child in the services. A child inherits its world from the parent by default. | CR |
| D6 | Gate locations | Gap | **Each gate Location carries its own world, and nothing requires them to agree.** This covers the GateDoor anchor/hinge/seed/display Location FKs (`API/Models/GateDoor.cs:61-80`) and the guard spawns (`GateStructure.cs:18`). | H | Validate that all gate Locations share the gate's domain world. | MIG+CR |
| D7 | Gate block snapshots | Unverified risk | **Snapshot coordinates carry no world.** `WorldX/Y/Z` are indexed without one (`API/Models/GateBlockSnapshot.cs:23-25`). They are scoped by GateDoorId and no coordinate lookup was found. | G | None needed while it is accessed only by door. | MIG |
| D8 | District inline Location | Gap | **An empty world can be stored.** `World = dto.Location.World ?? string.Empty` (`API/Services/DistrictService.cs:143,229`). Location create/update rejects blank (`LocationService.cs:40-41,62-63`), but this path does not. | G | Reject blank. | CR |
| D9 | World-task Location | Gap | **A missing world silently becomes `"world"`** (`API/Services/WorkflowService.cs:186-197`). | G | Reject a missing world. | CR |
| A1 | Domain DTOs | **Gap** | **No world in `DomainDto`, `DomainListDto`, `DomainRegionDecisionDto`, `DomainAccessRuleDto` or `DomainRegionQueryDto`** (`API/Dtos/DomainDtos.cs:21-156`). `LocationDto.world` exists (`LocationDtos.cs:28-29`). | H | Add `worldName` to every domain DTO and to region query/decision DTOs. | CR |
| A2 | Region→domain lookup | **Gap** | `GET api/Domains/by-region/{regionName}` (`API/Controllers/DomainsController.cs:112-116`) → `FirstOrDefaultAsync` on the lower-cased name, with no ordering (`API/Repositories/DomainRepository.cs:29-34`). `POST search-region-decisions` uses the same lookup (`DomainService.cs:158-181`). | H | Take `(world, regionId)`. | CR |
| A3 | Access rules | **Gap** | `GET api/Domains/access-rules` is keyed by `WgRegionId` only (`DomainService.cs:127-142`). | H | Add world to each rule. | CR |
| A4 | Region validators | **Gap** | The `contains-location` (x/z only), `contains-region` and `Regions/rename` calls send no world (`API/Services/RegionService.cs:84,146,222`; `LocationInsideRegionValidator.cs:149`). | H | Send the world, plugin endpoint included (R6). | CR |
| A5 | Discovery grant | Gap | Granted by raw region ids, lowest id wins (`DiscoveryService.cs:141-150`; `DiscoveryRepository.cs:50-60`). | G | `(world, regionId)`. | CR |
| A6 | Location search / warps / teleport audit | Supported | `POST api/Locations/search` has an optional world filter (`LocationRepository.cs:63,71`). Warp arrival uses `domain.Location.World` (`TeleportDestinationService.cs:485`). | — | — | CR |
| A7 | Game Settings per world | Supported (by name) | `WorldGameSettingsDto` is keyed by `WorldName` (`API/Dtos/GameSettingsDtos.cs:157-182`), deduplicated case-insensitively (`GameSettingsService.cs:60-64`). | — | — | CR |
| A8 | Game Settings spawn references | Gap | The `LocationReferenceDto` snapshot world defaults to `"world"` (`GameSettingsDtos.cs:231-274`). The source and world are never validated against domains or runtime worlds (`GameSettingsService.cs:245-300`). | H (hub spawn) | Validate that the referenced world exists in the runtime worlds, and that a world-spawn reference is in its own world. | CR |
| A9 | Runtime worlds report | Gap | `PUT runtime-worlds` replaces the whole list. **The last reporting server wins** (`GameSettingsService.cs:81-131`). `isPrimary` is never read. | G | Fine for one server; revisit if KNG-72 adds servers. | CR |
| A10 | Existing world-qualified tables | Supported | Lootbox, RoadTile/Node/Edge and SiegeScenario Hub use world columns (`KnKDbContext.cs:1001-1002,2245,2301,2347`; `Models/Siege/SiegeScenario.cs:32-36`). | — | A pattern to copy. | MIG |

### 2.2 Web app

| ID | Subsystem | Status | Evidence | Hub? | Suggested fix | Type |
|---|---|---|---|---|---|---|
| U1 | Region capture world | **Gap** | **The web app drops the captured region's world.** The plugin sends `worldName` (`P/tasks/WgRegionIdTaskHandler.java:414`). The web app stores only `regionId` (`APP/components/Workflow/WorldBoundFieldRenderer.tsx:36-44,327-333`) and shows the world read-only (`:213-226`). | H | Persist it into the new Domain `worldName`. | CR |
| U2 | Location capture world | Supported, with a silent default | The world is carried as `output.World ?? output.worldName ?? 'world'` (`WorldBoundFieldRenderer.tsx:322`). | G | Drop the `'world'` default. | CR |
| U3 | Domain forms | Gap / unverified | Forms are DB FormConfigurations (`APP/pages/FormWizardPage.tsx:306`). No world selector exists. The DB form contents were not inspected. | H | Add a world field (derived from capture, read-only) to the Domain form configs. | CR |
| U4 | Pickers | Gap | **Generic picker tables cannot tell worlds apart.** Location/Town/District show only id and name; Structure shows `(x,y,z)` without the world (`APP/config/objectConfigs.tsx:4-9,85`). Domain list labels have no world (`APP/types/dtos/domain/DomainDtos.ts:48-60`). | G (H for the hub pickers) | Show the world column; filter by world. | CR |
| U5 | Game Settings spawn pickers | Gap | **Each world's spawn/respawn picker lists Locations from every world** (`APP/pages/admin/GameSettingsPage.tsx:555-569`). Search ignores the world (`APP/components/admin/gameSettings/locationReferenceOptions.ts:127`). A missing world defaults to `'world'` (`:60`). The plugin ignores a cross-world world-spawn reference (DOC: game-settings DESIGN §3.6). | G | Filter by world; reject server-side (A8). | CR+DOC |
| U6 | Override display order | Doc drift | `orderByPrecedence` sorts depth-first (`APP/components/admin/gameSettings/GroupOverridesCard.tsx:31-40`). The API and plugin use D13 weight-first (§6). The plugin comment `C/domain/users/UserSummary.java:39-41` is stale the same way. | G | Align display with `PermissionGroupPrecedence`. | CR+DOC |

### 2.3 Plugin: mapping, caches, WorldGuard, tracker

| ID | Subsystem | Status | Evidence | Hub? | Suggested fix | Type |
|---|---|---|---|---|---|---|
| R1 | Region→domain query and cache | **Gap** | **The plugin queries and caches domains by region id only.** `DomainRegionQuery(Set<String> wgRegionIds)` (`C/domain/domains/DomainRegionQuery.java:5-6`). The resolver cache and the KNG-104 refresh are keyed by id (`C/regions/RegionDomainResolver.java:55,57,170-172,254,416`). Shared region caches map id→entity id (`C/cache/BaseRegionCache.java:18,34-36,47-49`). | H | Key `world:regionId` end to end. | CR |
| R2 | Domain DTOs in plugin | Gap | Town/District carry `wgRegionId` plus an optional location; Structure and GateStructure carry no world (`AC/dto/TownDto.java:14-16`, `StructureDto.java:12-13`, `GateStructureDto.java:24-103`). | H | Map the new `worldName`. | CR |
| R3 | Region queries at a location | Supported | **Queries run against the right world, but the returned ids lose it** (`P/regions/RegionIds.java:64-82`). | — | Return `(world,id)`. | CR |
| R4 | Explicit-world WG calls | Supported | `P/integration/WorldGuardIntegration.java:52-96`, `P/navigation/WorldGuardRegionShapes.java:46-50`, `P/tasks/LocationTaskHandler.java:469-470`, `P/tasks/TempRegionRetentionTask.java:126-128`, `P/settings/GameSettingsManager.java:512-517`. | — | — | CR |
| R5 | `findWorldByRegion` | **Gap** | **Returns the first loaded world that has the id.** Used by rename and containment (`P/tasks/WgRegionIdTaskHandler.java:643,775,827-840`). | H | Pass the world (the task already records it). | CR |
| R6 | Region HTTP endpoints | **Gap** | **Rename, contains-location and contains-region take no world** (`P/http/RegionHttpServer.java:46-47,72-84,149-181,215`). `P/tasks/LocationTaskHandler.java:622-640` returns the first world's region. | H | Required `world` parameter. | CR |
| R7 | Managed-region repair | **Gap** | **Startup repair and `/knk regions repair` change only the first world containing the id.** Config overrides are keyed by id (`P/regions/managed/WorldGuardManagedRegionStore.java:24-26,130-140`; `P/regions/managed/ManagedRegionsBootstrap.java:49,86-93,128-130`; `P/commands/RegionsAdminCommand.java:44-49`; `knk-paper/src/main/resources/config.yml:533-543`). | H | Specs carry the world. | CR |
| R8 | KNG-56 access flags | **Gap** | **Flags are written to every world's region with that id, and read from the first** (`P/regions/access/WorldGuardAccessFlagStore.java:19-21,33-55`). Sync and rules have no world (`P/regions/access/DomainAccessFlagSync.java:46,56-67,138-140`; `C/regions/access/AccessFlagSync.java:65-96`; `C/domain/domains/DomainAccessRule.java:10`). | H | World-qualified rules; write only that world's manager. | CR |
| R9 | Enter/leave tracker | **Gap** | **Same-named regions in another world produce no transition.** The tracker keeps `Map<UUID, Set<String>>` and short-circuits on `newRegions.equals(oldRegions)` (`P/regions/WorldGuardRegionTracker.java:63-66,135-149,425-449`). | H | `world:id` keys, or treat a world change as leave-all plus enter-all. | CR (hand-checked) |
| R10 | Portal world change | Gap (unverified at runtime) | **A vanilla portal world change may bypass the tracker.** It has no `PlayerChangedWorldEvent` or `PlayerPortalEvent` handler (`P/listeners/WorldGuardRegionListener.java:39-59`). | G (the KnK hub portal teleports) | Add a `PlayerChangedWorldEvent` resync. | CR |
| R11 | Access preview | **Gap** | **A cross-world teleport between same-named regions is not seen as a crossing.** The before/after maps are keyed by id (`P/regions/access/DomainAccessService.java:116-133`). This feeds the teleport restriction, respawn and mount checks (`P/KnKPlugin.java:2146-2150`; `P/regions/access/DomainAccessListener.java:72,93,131`). | H | A world change means exit-all/enter-all. | CR |
| R12 | WG `onCrossBoundary` | Unverified | **WorldGuard's own crossing check may also miss cross-world moves**, because `ProtectedRegion.equals` is id-based (`P/regions/access/DomainAccessHandler.java:51-63`). | H (verify live) | Live test L3. | CR |
| R13 | Combat safezones | Gap | Ids are read in the victim's world, but domains are resolved by id (`P/regions/WorldGuardCombatSafezones.java:71-78`). | H (hub combat rules) | Inherits R1. | CR |
| R14 | Discovery (KNG-20) | Gap | **Discovery is keyed by region id only**, in the listener, tracker, spool and grant DTO (`P/discovery/DomainDiscoveryListener.java:74,219,243,253-257`; `C/discovery/DiscoveryTracker.java:193,256,280`; `C/discovery/DiscoverySpool.java:58-61,207-218`; `AC/dto/DiscoveryGrantRequestDto.java:11`). | G | World-qualified keys and spool v2. | CR |
| R15 | Navigation region goals | Supported (workaround) | Uses the player's world and fails OTHER_WORLD for spawn goals elsewhere (`P/navigation/NavigationDestinations.java:240-250`). Road access warm-up inherits R1 (`P/roads/RoadNetworkCache.java:344`). | G | Inherits R1. | CR |

### 2.4 Plugin: locations, teleports, spawn, gates, lifecycle

| ID | Subsystem | Status | Evidence | Hub? | Suggested fix | Type |
|---|---|---|---|---|---|---|
| L1 | Location → Bukkit | Supported | **A missing or unloaded world yields empty or null; no world is invented** (`P/utils/KnkLocations.java:22-31`; `P/teleport/BackService.java:72-76,362-366`). | — | — | CR |
| L2 | First-world fallbacks | **Gap** | These fall back to `Bukkit.getWorlds().get(0)` (the `level-name` world):<br>• join spawn without settings (`P/listeners/PlayerListener.java:190-191`)<br>• `/spawn` resolver (`P/KnKPlugin.java:1988-1990`, `P/teleport/SpawnDestinationResolver.java:101-113`)<br>• Game Settings (`P/settings/GameSettingsManager.java:414-432`, Nether/End respawn `:501-506`)<br>• Siege vault return (`P/siege/SiegePlayerVault.java:229-232`) | H | On admission/containment paths: the hub, or refuse. Elsewhere: an explicitly configured gameplay world. | CR (hand-checked) |
| L3 | Literal `"world"` default | Gap | `/knk location tp` (`P/locations/LocationAdminCommand.java:155`). | G | Refuse blank. | CR |
| L4 | Teleport engine (KNG-17) | Supported | **The destination world comes from the target, and the safe-spot search runs there** (`P/teleport/TeleportService.java:312,378,439-463,657`). | — | — | CR |
| L5 | Respawn per world | Supported | The death-world policy is used, and nearest town is looked up in the death world (`P/settings/GameSettingsManager.java:462-500,508-522`; `C/settings/RespawnPlanner.java:99-113`). | — | — | CR |
| L6 | Game mode on world change | Gap | **The world's game mode is applied only at join and when the loading hold ends**, by design (Game Settings D3) (`P/listeners/PlayerListener.java:192-193`; `P/user/JoinLoadingGuard.java:97,170`). | G (the hub portal must set it itself) | The hub portal applies the destination mode; leave D3 as is. | CR+DOC |
| L7 | Gate teleport | Gap | A blank or unloaded door world uses the player's current world (`P/commands/GateCommandSupport.java:470-479`). | G | Refuse. | CR |
| G1 | Gate animation | **Gap (high)** | **A blank-world door is animated in every world.** One task runs per world, and the filter skips a door only when its world is non-blank and different (`P/gates/GateAnimationTask.java:140-142`). Doors get a blank world when the anchor JSON lacks one (`AC/dto/GateStructureDto.java:309-316`; `C/util/CoordinateParser.java:51-61`; `P/gates/GateLoaderAdapter.java:243`). | H | Reject blank-world doors at load (log and skip); require the anchor world. | CR (hand-checked) |
| G2 | Gate tasks for late worlds | **Gap** | **Tasks are created only for worlds loaded during `onEnable`** (`P/KnKPlugin.java:889-896`). The only `WorldLoadEvent` listener is Game Settings (`P/listeners/GameSettingsWorldListener.java:56`). | H (when Multiverse loads the hub after KnK) | Start/stop on `WorldLoadEvent`/`WorldUnloadEvent`; declare load order. | CR (hand-checked) |
| G3 | Gate spatial index / targeting | Supported (blank-world caveat) | **The block index is per world** (`C/gates/GateSpatialIndex.java:38-42,72-81`). Targeting filters by world first, but treats blank as world 0 (`C/gates/target/GateTargetMath.java:51-56,98-113`). | — | Covered by G1. | CR |
| G4 | Gate block operations | Supported | **Health, fire, display and state sync each use the door's own world**, and skip a blank or unloaded one (`P/gates/HealthSystem.java:189,209-212,350-353`; `P/gates/GateFireSystem.java:111`; `P/gates/GateDisplayManager.java:215-221`; `P/gates/GateStateSyncTask.java:366-371`). | — | — | CR |
| G5 | Gate name lookup | Gap | Returns the first match in any world (`C/gates/GateManager.java:258-262,291-295`). | G | Filter by world, or ask for the id when the name is ambiguous. | CR |
| G6 | Gate tasks / door capture | Supported (minor gaps) | Block scan and region capture record the world (`P/tasks/GateBlockScanTaskHandler.java:181-197`; `P/tasks/GateDoorRegionCaptureHandler.java:148-165`). Two minor gaps: redefine re-hydrates into the player's world (`:90-101`), and display orphan cleanup ignores the world (`P/gates/GateDisplayManager.java:185-205`). | G | Minor. | CR |
| S1 | Distance/proximity | Supported | **No unguarded cross-world `distance` call was found**; existing calls are guarded by a same-world check (`P/siege/SiegeService.java:341-342`; `P/lootbox/LootboxPresenter.java:207-208`; `P/commands/GateCommand.java:351-353`). Roads are per world (`P/roads/RoadNetworkCache.java:79,87`). | — | — | CR |
| S2 | NPCs | N/A | No NPC runtime exists, only a DTO field. | — | Design KNG-36 world-aware. | CR |
| S3 | Siege banner recovery | Gap | Entries for unloaded worlds are skipped and the log deleted (`P/siege/SiegeWorldPresenter.java:404-421`). | G | Keep unloaded-world entries. | CR |
| LC1 | Load order | **Gap** | **KnK cannot react to worlds that load after it enables.** `plugin.yml` has no `load:` (so POSTWORLD), depends on WorldGuard, soft-depends on WorldEdit, and has no Multiverse entry (`knk-paper/src/main/resources/plugin.yml:1-9`). Gate load (`P/KnKPlugin.java:400-419`), repair/sync (`:485-486`) and gate tasks (`:891`) assume worlds are loaded. A late world gets Game Settings and the 5-minute access sync only. | H | Provider-dependent (§9). Explicit world readiness before admission. | CR |
| LC2 | Unload/rename/missing world | Gap | **There is no world-unload handling.** No `WorldUnloadEvent` cleanup exists beyond the API report (`P/listeners/GameSettingsWorldListener.java:62-67`). A renamed world appears as a new name with defaults (`API/Services/GameSettingsService.cs:81-131`). | H (the hub world must not unload; a missing hub must fail closed) | Cancel unloading of a required world (`WorldUnloadEvent` is `Cancellable`, Paper API 1.21.10); refuse admission when it is missing. | CR+EXT |
| LC3 | Local stores | Mixed | Per store:<br>• Game Settings cache: per world by name (`P/settings/GameSettingsStore.java:32,41-42`)<br>• Siege vault: has the world (`P/siege/SiegePlayerVault.java:286,313-318`)<br>• Roads: have the world<br>• Discovery spool: id only (R14)<br>Plus three missing stores: no offline permission/user/mode store on `main` (KNG-58 unmerged), no hub config store, no return record. | H\* | Merge and extend KNG-58 (§5). | CR |
| H1 | Admission without a gameplay flash | **Gap** | **The player can briefly appear in their logout world before being moved.** There is no `AsyncPlayerSpawnLocationEvent` or `PlayerSpawnLocationEvent` handler; join spawn is a `teleport` inside `PlayerJoinEvent` (`P/listeners/PlayerListener.java:164,183-197`). | H | Paper 1.21.10 `io.papermc.paper.event.player.AsyncPlayerSpawnLocationEvent` (`@ApiStatus.Experimental`) keeps the player in the configuration phase until the handlers return. Set the hub spawn there from a thread-safe, pre-resolved snapshot. The Spigot `PlayerSpawnLocationEvent` is `@Deprecated(since="1.21.9", forRemoval=true)`. | CR+EXT |
| H2 | Region tracker on join | Gap (ordering) | **Registration order decides which location the tracker sees on join.** The tracker's join handler and `PlayerListener.onJoin` both run at NORMAL (`P/listeners/WorldGuardRegionListener.java:61-68`). | H | Moot once H1 sets the spawn before join. | CR |

### 2.5 Connectivity, permissions, Siege (hub outage scope)

| ID | Subsystem | Status | Evidence | Hub? | Suggested fix | Type |
|---|---|---|---|---|---|---|
| C1 | Plugin health probe | **Broken** | **The probe calls a path the API does not serve.** It calls `GET baseUrl + "/health"` with a TODO about the contract (`AC/impl/HealthApiImpl.java:34-35,57-69`). `base-url` is `.../api` (`knk-paper/src/main/resources/config.yml:4`), so it requests `/api/health`. The API serves only `/health/live` and `/health/ready` (`API/Controllers/HealthCheckController.cs:11,28,47`). | H\* | Probe `/health/ready` at the API root, not under `base-url`. | CR (hand-checked) |
| C2 | Health status parsing | **Broken** | **Even a correct path would parse as unhealthy.** Only `UP`/`OK` count as healthy (`C/domain/HealthStatus.java:16-18`); the API returns `healthy`/`degraded`/`unhealthy` (`HealthCheckController.cs:34,56,77-98`). | H\* | Parse the API contract; use the HTTP status as the primary signal. | CR (hand-checked) |
| C3 | Readiness depth | Gap | **`/health/ready` never fails when MySQL is down.** Only an always-healthy `"self"` check is registered (`API/Program.cs:86-87`), despite the "database" doc comment (`HealthCheckController.cs:43`). | H\* | Add an EF/DB health check to `ready`. | CR (hand-checked) |
| C4 | Cached health | Dead code / unsafe | **A cached "healthy" can be served for up to 30 s**, because `HealthDataAccess` defaults to CACHE_FIRST with a 30 s TTL (`C/dataaccess/HealthDataAccess.java:79-92,112-123`; `config.yml:703-709`). `DataAccessFactory.createHealthDataAccess` has no caller (`P/dataaccess/DataAccessFactory.java:286-292`). The only consumer is `/knk health` (`P/commands/HealthCommand.java:45-90`). | H\* | Outage detection must call the API directly (API_ONLY or the raw client), never the cache. | CR |
| C5 | Service-wide outage state | **Missing** | **There is no outage state, hysteresis, event or circuit breaker.** `BaseApiImpl` only throws (`AC/impl/BaseApiImpl.java:99-132`). Recovery is detected ad hoc per feature: the PM log shipper backoff (`C/messaging/PrivateMessageLogShipper.java:57,237-254`), the discovery replay timer (`P/discovery/DiscoveryFlushTask.java:31-38,70-77`), the siege result spool (`C/siege/SiegeMatchRecorder.java:29-38,71-80`) and the notification poller (`P/tasks/PlayerNotificationPoller.java:142,158-162`). `RoadDirtyTracker`'s "reachable" check is `apiClient != null` (`P/roads/RoadDirtyTracker.java:98`). KNG-57 exists only as TODOs. | H\* | One `ApiConnectivity` service (§5). Optionally feed it from `BaseApiImpl` failures (KNG-34's `ApiFailureObserver` is on an unmerged branch). | CR |
| P1 | Group precedence | Supported | `PermissionGroupPrecedence.Order` (`API/Services/PermissionGroupPrecedence.cs:19-40`) and `TeleportGroupPolicy.Chain` (`API/Services/TeleportGroupPolicy.cs:86-104`) both order by Weight descending (ties: lower id), each group followed by its parent chain, deduplicated keeping the first position. They are used for the user summary (`API/Services/UserService.cs:94,104-111`) and for override reads (`GameSettingsService.cs:155`). The plugin takes the first group with an override per field (`C/settings/GroupOverrides.java:71-86`). This matches hub DESIGN §13 and Game Settings D13 (2026-10-09). | — | — | CR+DOC |
| P2 | Permission resolution | Supported | **Inheritance runs child → parent:** a group inherits its `ParentGroup`'s grants, never the reverse (`API/Services/PermissionResolutionService.cs:41-52`). Order of sources: direct user grants first, then the user's groups by weight, each followed by its parent chain. Matching: exact beats wildcard; a trailing `*` is a prefix match not tied to dot boundaries; `x.*` also matches `x`; a bare `*` is weakest (`:66-95`). Within a source, a deny wins at equal strength (`:104-117`); across sources, the first source with any match decides (`:128-142`). Expired grants and memberships are ignored. There is **no node tree**: `knk.mode` does not imply `knk.mode.staff`. | — | — | CR |
| P3 | Group effective permission API | **Missing** | **Effective permissions can be computed only per user** (`API/Controllers/UsersController.cs:220-256`). `PermissionGroupsController` offers only CRUD, search and expiring memberships. The web app has no group effective-permission client (`APP/apiClients/permissionGroupClient.ts:25-53`). | H (exemption checkboxes) | §6. | CR |
| P4 | `knk.mode.*` seeding | Unverified | Neither node is seeded by migrations; they appear only in comments and tests. The live DB grants were not inspected. | G | Inspect the DB; seed if absent. | MIG |
| P5 | Active mode at runtime | Partly | **The active mode is in memory and survives an outage only while the player stays online** (`P/modes/ModeService.java:48-49,60,85-101`). On `main`, a rejoin during an outage re-checks the permission and fails closed: vanished staff are revealed and the mode is persisted as NONE (`P/listeners/ModeListener.java:38-73`). KNG-58 P0 fixes this but is unmerged. Several exemptions check the permission node rather than the active mode (`P/listeners/PlayerListener.java:183,299,378-381`; `P/user/JoinLoadingGuard.java:85`). | H\* | Merge KNG-58 P0. The hub exemption checks the **active mode**, not the node. | CR |
| SG1 | Siege bookkeeping | Supported (in memory) | **Match state is in memory only; the vault and result spool are on disk.** Lobbies and matches live in memory (`P/siege/SiegeService.java:156,160,1525-1550`). Vault files are `siege-vault/<uuid>.yml` (`P/siege/SiegePlayerVault.java:30-33,257-294`); the result spool is at `P/KnKPlugin.java:2545`. Gate lockdown recovery goes through the API (`P/siege/SiegeGateController.java:35-41,103-115`). | — | — | CR |
| SG2 | Siege respawn | **Containment gap** | **A dead, evacuated participant is respawned back into the arena.** `SiegeDeathRespawnListener.onRespawn` runs at HIGHEST, has no member check and is registered last, so it wins (`P/listeners/SiegeDeathRespawnListener.java:44-48`; `P/siege/SiegeService.java:1290-1304`; `P/KnKPlugin.java:864,933,2600`). It picks the vault return, else the hub, else the team spawn. | H\* | Consult containment first (§7). | CR |
| SG3 | External teleport mid-match | Gap | **Nothing reacts when a participant is moved out by another plugin**: no teleport, world-change or area-leave handler. The participant stays on the roster without capturing (`SiegeService.java:340-343`). `SiegeTeleportRestriction` covers only the KnK teleport engine (`P/siege/SiegeTeleportRestriction.java:16-34,53-73`). | H\* | The evacuation path must remove the member explicitly. | CR |
| SG4 | Vault restore / rejoin | Containment gap | **Restore and rejoin both teleport to the pre-siege location**, which would undo a hub placement. `restore` does so (`P/siege/SiegePlayerVault.java:139-155,225-232`). Quit restores the inventory and the location on the next join, two ticks after a MONITOR handler (`P/listeners/SiegeSessionListener.java:36-49`; `SiegeService.java:925-937`). | H\* | Restore the inventory without teleport when contained; the pre-siege location becomes the return record. | CR |
| SG5 | Siege API dependency | Supported (local) | **A match runs locally once started.** It ticks locally (`SiegeService.java:277-305`). `complete`/`abort` are spooled; `startMatch`/`participantLeft` are retried, then logged (`C/siege/SiegeMatchRecorder.java:166-185`). | — | — | CR |

## 3. Hub vs general summary

**Hub blockers (multiworld):**
- Domain world identity and lookups: D1, D2, D4, D5, D6, A1–A4, U1, U3, R1, R2, R5–R9, R11, R13.
- Gates and lifecycle: G1, G2, LC1, LC2.
- First-world fallbacks: L2.
- Admission: H1.
- Hub-spawn validation: A8.

**Hub blockers (outage/admission):** C1–C5, P3, P5, LC3, SG2–SG4.

**General follow-ups:** D3, D7–D9, A5, A9, U2, U4–U6, R10, R14, R15, L3, L6, L7, G5, G6, S3, P4.

## 4. World identity proposal

These are recommendations; the implementation is not authorized.

- **Key: world name.** Use the Bukkit world name, exactly as `Location.World`, Game Settings and roads already do. Record the world UUID from the runtime-worlds report so that a renamed folder can be detected rather than silently treated as a new world. Do not use Multiverse aliases.
- **Schema.**
  - Add `domains.WorldName varchar(64)` (base TPT table, so every subtype gets it). It starts nullable.
  - Backfill from `Location.World` where a Location exists.
  - The plugin reports which loaded world(s) contain each remaining `WgRegionId`.
    - Exactly one world: auto-fill.
    - Several or none: list them for admin resolution.
  - Then make the column `NOT NULL` and add a unique index on `(WorldName, WgRegionId)` for non-empty ids.
  - This is a rebase-sensitive migration, like the other open branches' migrations (tracker note on KNG-80).
- **Rules.**
  - A child must share its parent's world. Create defaults the child's world from the parent; update rejects a mismatch.
  - A domain's own Location and its gate Locations must be in the domain world.
  - The region capture world must equal the domain world.
- **Contracts.** Every region query, decision, access-rule and discovery DTO carries `worldName`. Plugin caches, tracker sets, access-flag specs, managed-region specs and the HTTP endpoints use a `world:regionId` key.

## 5. Connectivity and offline readiness

**What exists:**
- A health client, broken by C1 and C2.
- A cached health accessor that must not be used (C4).
- Per-feature retries and spools.
- KNG-52's Game Settings disk copy (`game-settings-cache.json`, DOC: game-settings DESIGN §3.7; `P/settings/GameSettingsStore.java:32`).
- KNG-56 access flags on WorldGuard regions.
- The KNG-58 P0 `OfflineSecurityStore`, **on an unmerged branch**.

**Missing orchestration:**
1. **Fix the probe.**
   - Call `/health/ready` at the API root.
   - Classify by HTTP status, with a body fallback.
   - Give it its own short timeout. The shared client is 10 s connect/read/write with no call timeout (`P/KnKPlugin.java:311-313`).
   - Make `ready` check the database.
2. **Add one `ApiConnectivity` service** (UNKNOWN → UP / DOWN):
   - a fresh probe on a schedule;
   - N consecutive failures to go DOWN and M consecutive successes to go UP (hysteresis);
   - optionally fed by request failures from `BaseApiImpl`;
   - a single main-thread event on each transition.
   
   The outage action (with its delay), portal readiness, return offers and KNG-58 refresh all subscribe to this one service. A cached healthy answer never sets UP.
3. **Readiness.** Gameplay entry requires `ApiConnectivity == UP` **and** the player's account to be loaded (`UserDataLoadedEvent`, `P/listeners/UserAccountListener.java:150`), rechecked at execution time.
4. **Persistence: extend the KNG-58 store, don't create a new one.**
   - The hub config, the outage action and its delay, and the return records go into the KNG-58 store.
   - Game Settings already has its own disk copy. Decide whether to fold it into KNG-58 or keep it and add only freshness/corrupt handling. The DESIGN requires reusing the shared mechanism, so folding it in is the default unless the developer prefers the existing file.

## 6. Mode-exemption eligibility

**Runtime check.** A player is exempt only when their **active mode** is STAFF/OWNER (`ModeService`), and the applicable group override has the matching exemption flag. Do not check the node itself. Entering a mode already requires the node, so this avoids fail-closed node checks during an outage (P5).

**API.**
- Add `GET api/PermissionGroups/{id}/permissions/check?node=` (or a batch `nodes=` form).
  - Refactor `PermissionResolutionService` so the per-user resolver and a per-group resolver share `TryMatch` and the first-matching-source logic.
  - The group resolver's sources are the group, then its parent chain, in that order. This is the same direction as user resolution; do not reverse it.
  - It returns Granted, Denied or Undeclared, plus the source group.
- The Game Settings override read DTO gains computed `canExemptStaffMode` / `canExemptOwnerMode`.
- PUT rejects `exemptInStaffMode=true` unless the group resolves as Granted for `knk.mode.staff`, and the same for owner. Validation is server-side, as DESIGN §13 requires.

**UI.** `GroupOverridesCard` shows each checkbox only when the computed flag is true, in the existing per-override card (`APP/components/admin/gameSettings/GroupOverridesCard.tsx:154-273`). It also lists the reason ("granted via Staff → ..."), which covers inherited and wildcard grants.

**Wildcard caveat.** A prefix wildcard like `knk.mod*` also matches, because matching is not tied to dot boundaries (P2). The checkbox then shows, which is consistent with how the node actually resolves.

**Open semantics.** It is unclear whether an unchecked box on a higher-precedence group *blocks* a checked box on a lower one. This is decision 5 in §11.

## 7. Siege outage containment (minimal)

No routine mid-match hub flow is proposed. When the configured outage action affects a participant (`siegeService.activeLobbyOf(player)`):

1. **Remove the member first** through the existing leave path (`SiegeService.leave` → `removeMember`, `P/siege/SiegeService.java:797-832,915-922`), with a distinct reason such as OUTAGE. Restore the inventory, XP, effects and game mode from the vault **without** the vault teleport.
2. **Record the return location** as the vault's pre-siege location, not the arena. If the vault write or restore fails, do not teleport out of the arena silently: keep the player and log loudly. This failure behaviour must be explicit.
3. **Then apply the action:** hub, current world's spawn, or kick.
4. **Add one `Containment.isContained(player)` check**, consulted by:
   - `SiegeDeathRespawnListener` (HIGHEST);
   - `PlayerListener` respawn (NORMAL);
   - `DomainAccessListener` respawn;
   - the `SiegeSessionListener` join restore (+2 ticks);
   - `SiegePlayerVault.restore`'s teleport.
   
   A contained player respawns or rejoins in the hub, and a pending respawn goes to the hub.
5. **For KICK**, quit already restores the inventory. On the next join, hub admission (H1) wins and the vault's location becomes the return record.

**Existing behaviour that settles part of the match question:** a match keeps ticking locally, and `complete`/`abort` are spooled. With the default SEND_TO_HUB, every non-exempt participant leaves, and the existing membership logic then ends the match. Exempt staff could keep a match running. Whether outage evacuation should **abort the whole match** (no rewards, spooled abort) or count as **individual leaves** is decision 6 in §11.

## 8. IsHub on base Domain

**Storage.**
- Add `domains.IsHub tinyint(1) NOT NULL DEFAULT 0` on the base TPT table, so Town, District, Structure and GateStructure all inherit it. No new subtype is needed.
- Migration `AddDomainIsHub`.
- Add `isHub` to `DomainDto` and every subtype DTO and mapping profile, and to the plugin DTOs.
- Domain forms are DB FormConfigurations, so adding the field to the Town/District/Structure/GateStructure forms is a **data change** to those configurations, not code (U3).

**Global hub selection.** Extend Game Settings rather than adding a new singleton:
- `hub.domainId`: must reference a domain with `IsHub = true`.
- `hub.spawnReference`: reuses `LocationReferenceDto`. It must resolve to a Location in the hub domain's `WorldName` and inside its region; validated server-side, with the plugin re-checking against WorldGuard.
- `outage.action` and `outage.delaySeconds`.

The admin UI adds a Hub card on the Game Settings page with a domain picker filtered to `IsHub`. This depends on D1: without a domain world, the spawn cannot be validated.

**The flag alone selects nothing.** Admission uses only `hub.domainId`.

**Not decided** (§11 decision 4):
- what other flagged domains mean (inert? per-world hubs?);
- nested flagged domains (a flagged District inside a flagged Town);
- whether hub rules apply to flagged-but-unselected domains;
- gameplay sub-domains inside a same-world hub region.

## 9. Provider comparison (required scope only)

**Required capabilities** for the first deployment:
1. Load one pre-existing hub world folder, plus the default `level-name` world, at startup, before admission.
2. Persist that list.
3. Fail closed when the hub world is missing.
4. Never unload it while needed.
5. Make world readiness visible before gate, repair and admission startup.
6. Keep KnK's existing ownership of spawn, respawn, game mode, time, weather and portal destinations (KNG-52, KNG-17).

Creating new worlds in-game, generators, cloning, per-world inventories, entry fees and Nether linking are **not** required. If the hub must be created rather than copied in, a void/flat generator is the only addition.

| Concern | A. Multiverse-Core + KnK portal | B. Minimal KnK loader + KnK portal | C. Core + Portals adapter |
|---|---|---|---|
| Load existing folder | `worlds.yml`, `auto-load: true` default | `new WorldCreator(name).createWorld()` per configured name in `onEnable` | As A |
| Create/import/generators | Full support (not required) | Only if needed: a small void generator | As A |
| Persistence | `worlds.yml` | A list in `config.yml` | As A |
| Missing world | Logs; the world is simply absent | KnK refuses admission (needed anyway) | As A |
| Threads | Main thread at enable | `createWorld` must run on the main thread and throws while worlds tick (`Server#createWorld` javadoc, Paper API 1.21.10). `onEnable` is safe. | As A |
| Startup readiness | Needs `softdepend: [Multiverse-Core]` so it enables first, plus a `WorldLoadEvent`-driven readiness check (G2, LC1) | Deterministic: KnK loads worlds, then starts gates, repair and admission | As A |
| Unload safeguard | Admins can `/mv unload`. KnK must cancel `WorldUnloadEvent` for required worlds. | Same listener; nothing else unloads | As A |
| Competing player rules | A config profile must disable them (below) | None | As A, plus portal permissions |
| Portal | KnK-owned: WG region trigger, readiness, Game Settings destination, return-record clearing | Same | Portals gives region/frame portals and permission gating, but the destination still needs a KnK adapter for groups, readiness and return records. **No work saved**, plus a second dependency. |
| Tests | Configuration plus pilot only | Unit tests for the loader and readiness, plus pilot | More integration |
| Upgrades | Pin a version and re-verify each Paper upgrade. 5.8.1 (2026-08-28) lists 1.21.10 on Modrinth. Extra commands and permissions for admins. | Paper `WorldCreator` API; little to maintain | Two plugins pinned to the same major |

**Multiverse facts verified for 5.8.1** (EXT: source tag `5.8.1` = `4de4e5a68edb2c7b74dcaa7643ac2575ccc1e9be`; Modrinth primary-file SHA-1 `1cc4c6799acfbd07139667d3e6512ebcb31be10b`):
- **License:** BSD-3-Clause (`LICENSE.md`).
- **Version and compatibility:**
  - 5.8.1 is a `release`, published 2026-08-28.
  - Its `game_versions` include 1.21.10; loaders: bukkit, paper, purpur, spigot.
  - 5.8.2-pre (2026-10-09) is a beta.
  - `plugin.yml` declares no `load:`, `api-version: 1.13`, and soft-depends on Vault and PlaceholderAPI.

**Can Core's competing rules be disabled cleanly?** Mostly yes, by configuration (`src/main/java/org/mvplugins/multiverse/core/config/CoreConfigNodes.java`, `listeners/MVPlayerListener.java`). The settings that matter:

| Setting | Default | Profile | Effect |
|---|---|---|---|
| `world.enforce-gamemode` | `true` | `false` | **Must be off:** it changes game mode on join and world change (`EnforcementHandler.java:58`). |
| `world.enforce-flight` | `true` | `false` | |
| `spawn.default-respawn-within-same-world` | `true` | `false` | With both respawn settings `false` and no per-world `respawn-world`, `getRespawnWorld` returns none and Core does not touch the respawn location (`MVPlayerListener.java:128-185`). Its respawn handler otherwise runs at LOW, before KnK's NORMAL/HIGHEST handlers. |
| `spawn.default-respawn-in-overworld` | `true` | `false` | As above. |
| `spawn.enforce-respawn-at-world-spawn` | `true` | (irrelevant once Core does not pick a respawn world) | |
| `spawn.first-spawn-override` | `false` | `false` | Teleports after `PlayerJoinEvent` when on, which is a gameplay flash. |
| `spawn.enable-join-destination` | `false` | `false` | Same as above. |
| `teleport.teleport-intercept` | `true` | `false` | Otherwise its HIGHEST teleport handler can cancel cross-world teleports through the entry checker. |
| `world.enforce-access` | `false` | `false` | |
| Per-world `auto-heal` / `hunger` | `true` | `true` | Only when `false` does Core cancel REGEN healing or food changes. A `false` would break the Peaceful preset. |

Two points the profile does not resolve:
- **Per-world `difficulty`, `pvp` and `spawn-location` are applied to the world on load.** KNG-52 sets world spawn on each refresh, so ownership must be explicit (KnK wins on refresh).
- **Event priorities and their interaction with WorldGuard are not proven.** Priorities are configurable (`event-priority.*`), but the order still needs the live pilot.

**Recommendation (not a decision).**

**B (minimal KnK loader) is the smaller and lower-risk option.** The world-lifecycle needs are small: load existing folders, fail closed, block unload. With A, KnK must still write the readiness, unload and fail-closed logic, *and* maintain a configuration profile that switches off most of Core's player-facing behaviour, *and* order its startup after Core.

**A is the better choice if** in-game world administration is wanted: create, import, clone or regenerate worlds, custom generators, or many worlds.

**C saves no work.**

This supersedes the earlier "Core recommended" lean in the [2026-10-10 research](2026-10-10-hub-multiverse-research.md), following DESIGN §15's instruction to compare against a minimal loader.

**The provider decision remains the developer's** (decision 1). Both A and B need: G2/LC1 readiness, the `WorldUnloadEvent` guard, H1 admission and the pilot gates of the research report.

## 10. Vanilla Peaceful healing/feeding (Java 1.21.10)

**Evidence (EXT):**
- Official Mojang `1.21.10` server jar (manifest entry `eec56ca0…`; server SHA-1 `95495a7f485eedd84ce928cef5e223b757d2f764`).
- Official server mappings (SHA-1 `c5440743411a6fd7490fa18a4b6c5d8edf36d88b`).
- Decompiled with Vineflower 1.11.1; names mapped through the official mappings.
- Paper `ver/1.21.10` @ `8043efd4d0e5bdc9dd0cbc33e9e8bb49e6d8c012` (`paper-server/patches/sources/net/minecraft/server/level/ServerPlayer.java.patch`, `.../world/food/FoodData.java.patch`).

**`ServerPlayer.tickRegeneration()`** (mapping lines 809–826) is called each player tick from `Player.aiStep()`. Mapped:

```java
if (level().getDifficulty() == Difficulty.PEACEFUL
        && level().getGameRules().getBoolean(GameRules.RULE_NATURAL_REGENERATION)) {
    if (tickCount % 20 == 0) {
        if (getHealth() < getMaxHealth()) heal(1.0F);          // Paper: heal(1.0F, RegainReason.REGEN)
        float sat = foodData.getSaturationLevel();
        if (sat < 20.0F) foodData.setSaturation(sat + 1.0F);
    }
    if (tickCount % 10 == 0 && foodData.needsFood())            // needsFood(): foodLevel < 20
        foodData.setFoodLevel(foodData.getFoodLevel() + 1);
}
```

**Units and intervals:**
- **Health:** +1.0 health point (half a heart) every 20 ticks while below max. That is 1 HP/s at 20 TPS.
- **Food:** +1 food level (half a drumstick) every 10 ticks while below 20. That is 2/s.
- **Saturation:** +1.0 every 20 ticks while below 20. This direct set is not capped at the food level; eating caps saturation at the food level, but this path does not.
- **Timing:** intervals use the player's `tickCount`, so they are game ticks and slow down under TPS lag.
- **Gamerule:** both are off when `naturalRegeneration` is false.
- **Paper changes:** Paper only adds `RegainReason.REGEN` to the heal. The food and saturation increments fire **no** `FoodLevelChangeEvent`.

**Ordinary food regeneration still runs on Peaceful** (`FoodData.tick`):
- With `naturalRegeneration`, saturation above 0, the player hurt and food at 20: every 10 ticks, heal `min(sat,6)/6` and add that much exhaustion. Paper: `SATIATED`, configurable `saturatedRegenRate`.
- Otherwise, with food at 18 or more and the player hurt: every 80 ticks, heal 1 and add 6 exhaustion (Paper: Spigot `regenExhaustion`).
- On Peaceful, exhaustion drains saturation but never food level.
- Starvation at food 0 hurts on Peaceful/Easy only above 10 HP. Peaceful refills food within ticks, so this is moot.

**Peaceful preset (KnK defaults, evidence-backed):**
- heal 1.0 HP / 20 ticks;
- feed +1 food / 10 ticks;
- saturation +1.0 / 20 ticks up to 20;
- only while `naturalRegeneration` is true in the player's world (recommended, to match vanilla).

**Region-scoped implementation without stacking:**
1. Run the preset per player inside the hub region on a 10-tick-aligned task. Use `player.getTicksLived()` modulo 20/10 to match vanilla's per-player phase, and heal with `RegainReason.REGEN`.
2. **Skip** the custom preset when the player's world difficulty is already PEACEFUL (native already applies). Otherwise a Peaceful hub world would double it.
3. Do **not** cancel or replicate `FoodData.tick` `SATIATED` regeneration. It is native behaviour on every difficulty, including Peaceful.
4. Peaceful is not invulnerability. Damage rules stay separate (DESIGN §13).

If the dedicated hub world is set to Peaceful difficulty, native behaviour matches exactly. But that is world-wide (it also removes hostile mobs) and does not cover a same-world hub, so the region preset is still needed.

## 11. Remaining developer decisions (answered 2026-10-10, see end of section)

Only behaviour that cannot be derived from code or existing decisions:

1. **Provider:** A (Multiverse-Core 5.8.1) or B (minimal KnK loader). §9 recommends B unless in-game world administration is wanted.
2. **Alpha scope (17–18 Oct):** do full world-qualification (§4, Phase 1) before the alpha, or adopt an interim constraint? The interim would be: globally unique region ids, enforced by validation, and no blank-world gates. It does **not** satisfy the identical-names acceptance test.
3. **Primary world:** confirm that the gameplay world stays the `level-name` (primary) world and the hub is the additional world. This affects new-player defaults, offline playerdata (`P/KnKPlugin.java:2244`) and any remaining first-world fallbacks.
4. **Multiple and nested hubs:** what `IsHub` means on unselected domains, and on nested flagged domains (§8).
5. **Exemption precedence:** does an unchecked exemption on a higher-precedence group block a checked one on a lower group, or does only a *checked* box count as "set" (effectively "any applicable group")? Recommended: only checked counts.
6. **Siege on outage:** abort the whole match, or treat evacuated participants as individual leaves while the match continues for exempt players (§7)?
7. **Game Settings persistence:** fold the existing `game-settings-cache.json` into the KNG-58 store, or keep it and add only freshness/corrupt handling (§5)?

**Already decided, not reopened:**
- SEND_TO_WORLD_SPAWN = the player's current world (DESIGN §15).
- Group precedence D13 = weight-first.
- Inheritance child→parent.
- Default action SEND_TO_HUB, delay "Uit" = immediate.
- Return-record lifecycle (DESIGN §12–13).

**Developer answers (2026-10-10, same day):**

| # | Decision |
|---|---|
| 1 | Minimal KnK loader (B). |
| 2 | Full fix first. A domain's world is extracted from its required region or Location world task, and asked in the web form only when no task provides it. No interim rule. |
| 3 | The gameplay world stays primary. |
| 4 | `IsHub` means eligible only, and nested hubs are not allowed. |
| 5 | Only a ticked box counts. |
| 6 | Abort the match. |
| 7 | Fold the Game Settings copy into KNG-58 after P0 merges. |

All smaller defaults in §4, §6 and §10 are accepted. See hub DESIGN §16.4.

## 12. Linear gap issues created (none implemented)

| Issue | Scope | Hub? |
|---|---|---|
| [KNG-111](https://linear.app/kngpandi/issue/KNG-111) | API/web: explicit Domain world, world-qualified region lookups, parent/child same-world validation | H |
| [KNG-112](https://linear.app/kngpandi/issue/KNG-112) | Plugin: `(world, regionId)` keys in resolver, caches, tracker, access preview, KNG-56 flags, managed regions, HTTP endpoints | H |
| [KNG-113](https://linear.app/kngpandi/issue/KNG-113) | Gates: blank-world doors animate in every world; tasks for late-loaded worlds | H |
| [KNG-114](https://linear.app/kngpandi/issue/KNG-114) | Admission before join (`AsyncPlayerSpawnLocationEvent`) and first-world fallbacks; world load readiness and unload guard | H |
| [KNG-115](https://linear.app/kngpandi/issue/KNG-115) | API connectivity: broken health probe, DB-blind readiness, service-wide outage state | H\* |
| [KNG-116](https://linear.app/kngpandi/issue/KNG-116) | Group effective-permission check for mode-exemption eligibility | H |
| [KNG-117](https://linear.app/kngpandi/issue/KNG-117) | Siege: contain outage evacuation of match participants | H\* |
| [KNG-118](https://linear.app/kngpandi/issue/KNG-118) | General multiworld follow-ups (discovery, pickers, defaults, game mode on world change, banner log, gate name lookup, doc drift) | G |

## 13. Proposed live checklist

**Setup:**
- Pinned Paper 1.21.10 build, WorldGuard and KnK jar (hashes recorded), plus Multiverse-Core 5.8.1 if option A is chosen.
- Worlds `hub` and `gameplay`.
- Two players, **P1** and **P2**.
- In both worlds: a Town `T` with a District `D` and a GateStructure `G`, using the **same region ids** (`t_test`, `d_test`, `g_test`) and the **same XYZ**. They get different access rules: hub D AllowEntry=false, gameplay D AllowEntry=true. They also get different gate states.

**Record per step:** the expected result, the observed result, the server log excerpt and pass/fail.

1. **Concurrency.** Both worlds load at startup. `/knk health` reports correct readiness. Game Settings runtime worlds list both.
2. **Identity.**
   - Same names: P1 in the hub at D's XYZ is refused entry; P2 in gameplay at the same XYZ is allowed.
   - Swap worlds and repeat.
   - Check that discovery, safezone and combat rules fire only for the domain of the player's own world.
3. **Cross-world transition.** Teleport P1 from hub `d_test` to gameplay `d_test` (same names). Enter/leave events and the access decision use the destination world.
4. **Gates.**
   - Open G in the hub while P2 watches G in gameplay. Only the hub gate animates; gameplay blocks are unchanged.
   - Repeat in reverse.
   - Load a gate whose anchor world is blank: it must be rejected and logged, not animated.
5. **Managed regions.** Run `/knk regions repair`. The parent/priority/flags are correct in **both** worlds' `t_test`. The KNG-56 flags differ per world as configured.
6. **Admission.**
   - P1 logs out in gameplay and rejoins with a healthy API. P1 appears directly in the hub; no gameplay frame or chunk load is visible. Record the client view and the server log.
   - Repeat for a first-join player and for a group with `joinAtLastLocation`.
7. **API-down cold restart.**
   - Persist settings, stop the API, restart the server.
   - P1 joins: hub, protections active, no gameplay flash.
   - P2 tries the portal: refused with a message.
   - Restore the API. After the hysteresis delay the portal works. P2 enters gameplay at the group/default entry spawn.
8. **Outage during portal transfer.** Start a portal transfer (warm-up if any) and cut the API before execution. The transfer is refused at execution; P1 stays in the hub; there is no duplicate evacuation.
9. **Outage actions** (each configured in turn), with P1 in gameplay:
   - NONE: not moved.
   - SEND_TO_HUB: moved once; the return record is written.
   - KICK: clear reason; on rejoin, the hub.
   - SEND_TO_WORLD_SPAWN: spawn of gameplay (P1's current world).
   - Repeat with the delay set to a non-zero value.
10. **Recovery return.**
    - Restart while the API is still down: the return record survives and the login notice appears.
    - API up: a clickable offer, and the return goes to the exact world, XYZ and orientation.
    - Double-click does nothing.
    - Delete the destination world or deny access: the record is invalidated with a message.
11. **Siege containment.**
    - P1 is in a running match; P1 is killed and is on the respawn screen; cut the API.
    - On respawn P1 is in the hub with the inventory restored once (count items before and after) and the return location = pre-siege.
    - Repeat with P1 alive mid-match, and with KICK (rejoin goes to the hub, the vault is restored once).
    - Check the match end/abort record in the spool.
12. **Mode transitions.**
    - Staff P2 in active staff mode, with the group's staff exemption checked: not evacuated, gameplay entry allowed during the outage.
    - Toggle the mode off during the outage: P2 now follows the group outage policy, with no repeated action.
    - Owner mode the same.
    - Restart while P2 is vanished and the API is down: P2 stays vanished (requires KNG-58).
    - Checkbox visibility: a group with a direct grant, an inherited grant (parent), a wildcard and a deny.
13. **Hub rules.**
    - PvP/PvE blocked; build blocked; chests and item frames blocked; doors and NPCs allowed.
    - The Peaceful preset heals 0.5 heart/s and feeds 1/0.5 s. In a hub world set to Peaceful, no doubling: measure HP/food over 60 s against §10.
14. **Lifecycle.**
    - Start with the hub folder renamed or missing: joins are refused with the local message.
    - `/mv unload hub` (option A) or another unload attempt is cancelled.
15. **Same-world hub.** A hub as a region in gameplay: rules apply inside the region only; outside play is unaffected.

## 14. What was not done

- No database inspection; there was no access.
- No build, test or live server run. The audit was read-only on all three code repos.
- No implementation.
- The runtime behaviour of WorldGuard `onCrossBoundary` across worlds (R12), vanilla portal handler lists (R10) and the Location task `"World"` key casing (`P/tasks/LocationTaskHandler.java:276,300`) are unverified and covered by the live checklist.
