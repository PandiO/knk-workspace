# Road Navigation — Implementation Plan

**Status:** Ready for implementation (handoff to a Claude Code agent). No phase started.
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27)
**Design:** [DESIGN.md](DESIGN.md) rev. 4 (decided) — read it first; this plan says *where and how* to build it.
**Sources:** trunk as of 2026-09-27 — knk-web-api `master` `acaee99`, knk-plugin `main` `ceed2f6`, knk-web-app `main`
`46be4e9`; unmerged `knk-plugin` `origin/claude/teleport` (KNG-17). All file/line references below were read on those
commits; line numbers drift — search for the quoted symbol if a line doesn't match.

Path shorthands: `C/` = `knk-plugin/knk-core/src/main/java/net/knightsandkings/knk/core/`, `A/` =
`knk-plugin/knk-api-client/src/main/java/net/knightsandkings/knk/api/`, `P/` =
`knk-plugin/knk-paper/src/main/java/net/knightsandkings/knk/paper/`, `W/` = `knk-web-api/`, `F/` = `knk-web-app/src/`.

---

## 0. Instructions for the implementing agent

Read this section fully before touching code.

### 0.1 Read order

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, each repo's `CLAUDE.md`, `docs/ACTIVE_SESSIONS.md`.
2. `docs/specs/navigation/DESIGN.md` (the what), then this plan (the how). Where they disagree, **this plan wins** —
   §1 lists every deliberate deviation and why.
3. The research reports are background only; don't re-research.

### 0.2 Ground rules

- **Reuse before you write.** §2 is the reuse map: every capability that already exists somewhere in the three repos,
  and what to do with it (use as is / extract and make the old caller delegate / generalise). Creating a second copy of
  anything in §2 is a defect. If you find another existing piece that fits, prefer it and note it in the phase status.
- **Refactors keep behaviour.** Every extraction in §2 moves code and makes the old caller delegate; the old caller's
  tests must stay green without edits (except import changes). Do the extraction in its own commit, before the feature
  code that uses it.
- **Bukkit-free core.** Everything under `C/roads/`, `C/navigation/` and the new `C/util/` helpers must not import
  `org.bukkit` (knk-core has `paper-api` on its compile classpath, so the compiler won't stop you — the guard test in
  Phase 2a will).
- **Follow the local conventions quoted in each phase** (DTO naming, `[JsonPropertyName]`, enum storage, DI block,
  command metadata, config records). They were read from trunk; don't invent new styles.
- **Decisions you have to take alone:** take the conservative default, write it down in the phase status block under
  "Decisions to review", and continue. Don't block on the developer mid-week (global instructions).
- **Never** touch siege code paths beyond the read-only hooks listed in Phase 4 (siege is being playtested in parallel).
  Files you may not modify except where a task says so: `P/siege/**`, `C/siege/**`, `W/Services/Siege*`, `W/Models/Siege/**`.

### 0.3 Branches, claims, commits

- One standing branch per repo: **`claude/road-navigation`**, cut from trunk (`knk-web-api` `master`, `knk-plugin`
  `main`, `knk-web-app` `main`). Reuse it for every phase. Merge trunk into it (no rebase) when trunk moves.
- Before starting a phase, add/update the row in `docs/ACTIVE_SESSIONS.md` (feature: "Road navigation (KNG-27)"; list
  the phase and the files you'll touch). Update it when you pause or finish.
- Commit per logical step (extraction, model, service, tests…), messages in the repo's style, ending with the session's
  attribution lines. Push after each phase at the latest.
- After each phase, append a **"Phase N status"** block under that phase in this file (template in §9) and push the
  workspace change to `main`.
- Merge to trunk only when the developer says so (they smoke-test first). Phases are designed to be mergeable one by one.

### 0.4 Baselines and builds — record before Phase 1

| Repo | Command | Known baseline |
|---|---|---|
| knk-web-api | `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` (not the `.sln`; its path says `tests\`) | **5 known failures**: ClientActivityStore, 2× PathResolution `Town.*`, FieldValidation ConditionalRequired, FormSubmissionProgressRepository. Record the total. |
| knk-web-api | CI `.github/workflows/migrations.yml` | fresh MySQL 8: update → `has-pending-model-changes` → roll back to 0 → re-apply. Your migration must pass all four. |
| knk-plugin | `./gradlew test` / `./gradlew build -x deployToDevServer` (`build` depends on `deployToDevServer`) | All green. |
| knk-web-app | `npm run test:ci` | Failure count on trunk is **not documented**; measure it on a clean checkout before your first change and compare against that. `CI=true npm run build` fails on pre-existing ESLint warnings — don't try to fix them. |

**Cloud containers can't reach `repo.papermc.io` or `maven.enginehub.org`**, so Gradle can't resolve `paper-api`,
WorldGuard or WorldEdit there. If you run in the cloud:
- knk-core and knk-api-client: compile and test in a Maven-Central-only scratch build (`javac` + JUnit console
  launcher), as done in `docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md` (Phase 6b/7a status blocks) and
  `specs/items/GRADE_DROPCHANCE.md`. Stub the handful of `org.bukkit.util.Vector` uses you can't avoid (only
  `C/gates` needs it).
- knk-paper: cannot be compiled — check by careful reading, say "**not compiled**" in the status block, and list what
  the developer must build locally. Prefer running Phases 3-4 on the developer's machine if possible.
- `dotnet` may be missing in the container; install the .NET 8 SDK if the network allows, otherwise say so in the
  status block (don't skip writing the tests).

### 0.5 Parallel work and merge order

- Runs **in parallel with the siege work** (developer decision). Phases 1, 2, 3 and 5 share no files with siege.
  Phase 4 adds read-only accessors to `SiegeService`/`KnKPlugin` (§ Phase 4 task 4.9) — coordinate via
  `ACTIVE_SESSIONS.md` before touching them.
- **Phase 4 needs KNG-17 (teleport, `origin/claude/teleport`) merged to trunk.** It isn't yet, and it conflicts with
  trunk in `KnKPlugin` and `WorldGuardRegionTracker`. If Phases 1-3 are done and KNG-17 still isn't on trunk, stop
  after Phase 3 (and Phase 5) and hand off; don't port teleport code yourself.
- Phase 2a's `DomainAccessEvaluator` extraction touches `C/regions/SimpleRegionTransitionService.java`, which KNG-17
  also changes (`previewAccess`). Keep the extraction minimal (move the two private methods, delegate) so the teleport
  merge is a small conflict; §2 row R6 says how the two must end up.

---

## 1. Deviations from DESIGN.md (decided while planning)

| # | DESIGN says | Plan does | Why |
|---|---|---|---|
| D1 | `[RequirePluginServiceKey]` | `[RequirePluginService]` for plugin-only writes; `[RequireServiceOrPermission(StaffPermissions.RoadManage)]` for writes both the plugin and staff may do; GETs anonymous | The attribute was renamed on trunk (`W/Attributes/RequireServiceOrPermissionAttribute.cs`). |
| D2 | §6.7: siege areas blocked for non-participants | **Siege areas are not blocked.** A gate locked by a siege (`SiegeGateController.isLocked`) is treated like a **pass-through gate** for non-members (the siege carries them through in TELEPORT mode, `KnKPlugin` L1448-1450); navigation ends when the player joins a siege lobby | Matches trunk behaviour; blocking would contradict what the game actually allows. DESIGN §6.7 updated. |
| D3 | §3.8 endpoint list | Final route table in Phase 1 (kebab-case class routes, tile graph under `api/road-tiles/{world}/{x}/{z}/graph`, ETag + 304) | Local conventions + there is no ETag support anywhere yet. |
| D4 | §3.3 `RoadTile` | Adds `Version` (int, +1 per build) — the ETag | Needed for per-tile download. |
| D5 | §3.1 profile merge endpoint `merge-survey` | **Dropped.** The plugin's `ProfileLearner` (one implementation, Java) recomputes the profile from stored stats + the new survey and `PUT`s it; `RoadProfile` gains `StatsJson` (accumulated counts) | Avoids implementing the role rules twice (C# + Java). |
| D6 | §4 `StreetLabeler` in knk-core | **Street labelling runs in knk-web-api** during the tile upsert (`Services/Roads/RoadStreetLabeler.cs`, pure) | Structures, their Street and Location rows are in the DB; doing it in the plugin means N+1 API calls per tile. |
| D7 | §5.6 step 7 "Boundary node matched by position" | Concrete rule: each tile owns `Boundary` nodes on its own border cells; after a tile upsert the API creates a 1-block **stitch edge** between each of its boundary nodes and an adjacent (Chebyshev ≤ 1 in x/z, \|Δy\| ≤ 1) boundary node of a neighbour tile | Builds are order-independent; no cross-tile writes from the plugin. |
| D8 | §3.1 `ScopeDomainIds` "(e.g. one kingdom's towns)" | Scope = list of **Town** domain ids (no Kingdom/Province entity exists) | Revisit when a Kingdom entity exists. |
| D9 | §5.4 gate lookup via `GateSpatialIndex` | Use each door's **closed footprint** (`GateManager` frame 0), not the spatial index | The index only holds the *current* frame; an open gate would be missed. |
| D10 | Profile editor "material picker" | Text field with suggestions from `minecraftMaterialRefClient.getHybrid` | `HybridMaterialPicker` is a full paged table — too heavy per row. |

---

## 2. Reuse map (existing code → how this feature uses it)

"Extract" = move to the new location, make the old class delegate (keep its public API), keep its tests green.

| # | Existing | Where (trunk) | Action |
|---|---|---|---|
| **knk-plugin** | | | |
| R1 | `GateSpatialIndex.packCell(int,int,int)` (26/12/26-bit key) | `C/gates/GateSpatialIndex.java:25` | **Extract** to `C/util/BlockKey.java` (`pack`, plus new `x(key)`, `y(key)` with 12-bit sign extension, `z(key)`, `neighbour(key, dx,dy,dz)`); `GateSpatialIndex.packCell` delegates. Don't touch `GateBlockScanTaskHandler.packCoordinate` (different layout, internal). |
| R2 | `GateFrameCalculator.pointInPolygon(u,v,List<double[]>)` (package-private) | `C/gates/GateFrameCalculator.java:392` | **Extract** to `C/util/Polygon2D.java` (public `contains`, plus new `closestPointOnBoundary`, `distanceToBoundary`); `GateFrameCalculator` delegates. |
| R3 | `GateManager.doorBlockPositions(gate, frame)` (private static) | `C/gates/GateManager.java:151` | Make **public** as `closedFootprint(int gateId)` (frame 0 = closed, see `GateAnimationTask` L206-211) returning `List<Vector>`; used by the build job to tag gate cells. |
| R4 | Gate state changes: only a one-shot per-gate callback (`setAnimationCompletionCallback`, L89) | `C/gates/GateManager.java`, `P/gates/HealthSystem.java` (`destroyGate` L131, `respawnGate` L302) | **Add** a multicast `GateStateListener` (`void gateStateChanged(int gateId)`) to `GateManager` (`addStateListener`/`removeStateListener`), fired from `notifyAnimationCompleted`, `forceGateState`, and by `HealthSystem` after destroy/respawn (via a new `GateManager.fireStateChanged(id)`). Don't change the existing one-shot callback. |
| R5 | `CachedGateDoor` effective accessors | `C/domain/gates/CachedGateDoor.java` L383-410 (`isEffectivelyActive/Destroyed/AllowPassThrough`), `getCurrentState()`, `isJammed()` L373, `getCurrentSiegeId()` | Use as is in `GateAvailability` (Phase 2d). Always the *effective* accessors. |
| R6 | Entry/exit rules: private `checkEntryDenials`/`checkExitDenials` | `C/regions/SimpleRegionTransitionService.java` L144-182 | **Extract** to `C/regions/DomainAccessEvaluator.java` (pure; `Optional<Denial> entry(DomainSnapshot)`, `Optional<Denial> exit(DomainSnapshot)`; messages unchanged). The service delegates. When KNG-17 merges, its `previewAccess` must also delegate to this evaluator, and its `knk.region.bypass` predicate becomes the evaluator's bypass input — note this in the Phase 2 status for the teleport merger. |
| R7 | `RegionDomainResolver` + `DomainSnapshot` | `C/regions/RegionDomainResolver.java` (`getDomainByRegionIdNoRefresh` L285, `resolveRegionsFromApi` L146, record L600) | Use as is to map WG region ids → domain ids/snapshots (build-time domain tagging, runtime access). Promote the local `regionDomainResolver` in `KnKPlugin` (L689-697) to a field. |
| R8 | "WG region ids at a location" — **3 copies** | `P/regions/WorldGuardRegionTracker.getRegionNamesAt` L203-217, `P/regions/WorldGuardRegionLookup.at` L7-20, `P/discovery/DomainDiscoveryListener.regionIdsAt` L256-268 | **Extract** one `P/regions/RegionIds.at(Location)` (excludes `__global__`, like the discovery copy); all three delegate. Navigation uses it. |
| R9 | `SiegeWorldPresenter.ring(...)` per-viewer particles (private static) | `P/siege/SiegeWorldPresenter.java` L333-346 | **Extract** to `P/utils/ParticleDraw.java` (`ring(...)` unchanged + new `polyline(Player, List<Vector>, spacing, Particle, DustOptions)`, `pillar(...)`); siege delegates. This is the only siege file you edit, and only as this mechanical extraction. |
| R10 | `SiegeBukkit.toLocation(KnkLocation)`, `floorOf(Location)` | `P/siege/SiegeBukkit.java` | **Extract** the two generic methods to `P/utils/KnkLocations.java`; `SiegeBukkit` delegates. |
| R11 | TPS lag check — **3 copies** (`Bukkit.getTPS()[0] < 15`) + per-tick block budget | `P/tasks/GateBlockScanTaskHandler.java` L53-55, L547, L713, L845 | **Extract** `P/utils/TickBudget.java` (`isServerLagging()`, `perTick(normal, lagging)`); the three call sites delegate. |
| R12 | Main-thread executor | `P/menu/MenuService.mainThreadExecutor(Plugin)` L97-105 | Use as is (`whenCompleteAsync(..., mainThread)`); don't write another. |
| R13 | `/knk` subcommand registry | `P/commands/KnkAdminCommand.registerSubcommand` L417; metadata `CommandMetadata`; tab completion hard-coded in `onTabComplete` L451-480 | Register `road` like `DiscoveryAdminCommand` (lazy suppliers, own node check through Bukkit + `KnkPermissible`); add a `road` branch to `onTabComplete` that delegates to `RoadAdminCommand.complete(...)`. |
| R14 | Top-level command helpers | `KnKPlugin.registerTabCommand` L1310 (`/pay` template: `P/commands/PayCommand.java`) | `/navigate` uses `registerTabCommand`. |
| R15 | Permissions | `P/permissions/KnkPermissible.hasPermission(Player,String)` (sync, cache-only, fails closed) | Node checks for `knk.navigate` and `knk.admin.road` exactly like `DiscoveryAdminCommand.hasNode`. |
| R16 | Typed config | `P/config/KnkConfig.java` (record + section records with `defaults()`/`validate()`), `P/config/ConfigLoader.java` (`loadDiscovery` L112-150), test `ConfigLoaderDiscoveryTest` | Add `NavigationConfig` the same way. |
| R17 | REST client base | `A/impl/BaseApiImpl.java` (`get`, `putJson`, `execute` → `ApiException` on non-2xx incl. 304) | **Improve**: add `ConditionalResponse getConditional(String url, String etag)` returning `{notModified, body, etag}` (304 is not an error there). New impls extend `BaseApiImpl`; wire in `A/client/KnkApiClient` (constructor L136-188 + getter). |
| R18 | Data access for streets/locations/districts/structures (all **never constructed** on trunk) | `C/dataaccess/{StreetsDataAccess,LocationsDataAccess}`, `DataAccessFactory.createStreetsDataAccess` L101, `createLocationsDataAccess` L116, `createDistrictsDataAccess`, `createStructuresDataAccess` | Construct them in `KnKPlugin` as fields (if KNG-17 has merged and already created them, reuse those fields). Add `StreetsDataAccess.searchAsync(PagedQuery)` (it has none). |
| R19 | Domain catalogue | `C/dataaccess/DomainCatalogDataAccess.searchAsync(PagedQuery)` L90 → `KnkDomainSummary(id,name,domainType)` | Destination name search for towns/districts/structures. |
| R20 | Domain → Location resolution (town/district embed `location`; structure has only `locationId`) | Teleport branch `P/teleport/SpawnDestinationResolver.ownLocation(...)` + lambdas | Phase 4: **extract** into `C/navigation/DomainLocationResolver.java` (Bukkit-free, `LocationLookup` ports); teleport's `SpawnDestinationResolver` delegates. |
| R21 | Name/`type:name` resolution + completion | Teleport branch `C/teleport/WarpTargets` (bound to `KnkTeleportDestination`) | Phase 4: **generalise** into `C/util/NamedTargets<T>` (accessor functions for name/type/qualifiedName); `WarpTargets` becomes a thin wrapper. |
| R22 | `BlockProbe` / `SafeLocationFinder` / `BukkitBlockProbe` | Teleport branch `C/teleport/`, `P/teleport/` | Phase 4: move `BlockProbe` to `C/util/BlockProbe` (teleport keeps working via import change) and make `SurfaceGrid` (Phase 2) **extend** it. Until KNG-17 merges, `SurfaceGrid` declares the same method names (`isPassable`, `isSolid`) so the later `extends` is a no-op change. |
| R23 | Eligibility pattern | `P/discovery/DiscoveryEligibility` (loading/mode/freeze/gamemode/siege predicates) | `NavigationEligibility` composes the same services (`JoinLoadingGuard`, `ModeService`, `AdminFreezeManager`, `SiegeService`) — reuse predicates, don't copy logic. |
| R24 | Siege read-only state | `P/siege/SiegeService.lobbyOf(UUID)`, `activeLobbyOf`, `addObserver(SiegeMatchObserver)`; `SiegeGateController.isLocked(int)` L222 (local in `KnKPlugin` L1452) | Phase 4: promote `siegeGates` to a field + getter; read-only use. |
| R25 | Gate pass-through rules | `P/listeners/GatePassThroughConsequenceListener` L31-50 (`isEffectivelyAllowPassThrough` && `knk.gate.passthrough.use`, or `knk.gate.admin`) | **Extract** the predicate to `P/gates/GatePassThroughRules.canPass(Player, CachedGateDoor)`; the listener and navigation both call it. |
| R26 | Clickable chat | `P/siege/SiegeMessages.command(String)` L47-53 | Copy the pattern into `P/navigation/NavigationMessages` / `P/roads/RoadMessages` (feature-local message classes are the convention; no shared helper exists). |
| R27 | Ticker lifecycle | `P/discovery/DiscoveryFlushTask` (`start()`/`stop()` with `BukkitTask`) | Same shape for `NavigationTicker`, `RoadBuildQueue`, `RoadDirtyTracker` flush. |
| R28 | Pure floor snap | `C/siege/SiegeFloor.floorY(...)` | Use as is for trail heights (Bukkit-free, generic despite package). |
| **knk-web-api** | | | |
| R29 | JSON-column helper | `W/Services/GameSettingsJson.cs` (internal static `Serialize/Deserialize/DeserializeList`) | **Extract** to `W/Json/JsonColumn.cs` (same options); `GameSettingsJson` delegates. Road JSON columns use it. |
| R30 | Locked transaction pattern with in-memory fallback | `W/Repositories/SiegeMatchRepository.RunLockedAsync`, `DiscoveryRepository.RunLockedForUserAsync` | Same pattern for the tile upsert (`RoadNetworkRepository.RunInTransactionAsync`). |
| R31 | Auth attributes, staff nodes | `W/Attributes/RequireServiceOrPermissionAttribute.cs`, `StaffPermissions` in `W/Attributes/RequirePermissionAttribute.cs` L10-73 | Add `StaffPermissions.RoadManage = "knk.admin.road"`. |
| R32 | Street layer | `W/Dtos/StreetDtos.cs` (`StreetDto` L6-24), `W/Mapping/StreetMappingProfile.cs` L11-15, `W/Services/StreetService.cs`, `W/Controllers/StreetsController.cs` | Add counts to `StreetDto`, filled by `StreetService`; add `GET api/Streets/{id}/road`. |
| R33 | DI registration | `W/DependencyInjection/ServiceCollectionExtensions.cs` (siege block L107-117; convention scan L204-220) | Explicit commented "Road navigation" block after the siege block. |
| **knk-web-app** | | | |
| R34 | Admin page pattern | `F/pages/admin/DiscoveryAdminPage.tsx` + `F/components/admin/discovery/*` (inline edit: `DiscoveryOverridesCard.tsx`), route `F/App.tsx` L191-204 with `StaffRoute node`, nav `F/components/Navigation.tsx` L18-30 + `nodeAccess` L52-56 | Copy the structure for `/admin/roads`. |
| R35 | Client pattern | `F/apiClients/discoveryClient.ts` (singleton `ObjectManager`), `Controllers` enum `F/utils/enums.ts` L62-117 | `roadClient.ts`; enum entries. |
| R36 | FormWizard display panels | `F/components/FormWizard/displayPanels.tsx` (registry), `F/components/siege/SiegeReadinessPanel.tsx` | Street road panel = new registry entry `streetRoad` (FormWizard is the only panel mechanism; DisplayWizard has none). |
| R37 | Street search picker | `F/components/SearchableDropdown.tsx` + `streetClient.searchPaged` | Edge-table street picker. |
| R38 | Material suggestions | `F/apiClients/minecraftMaterialRefClient.getHybrid(search, category, take)` | Profile editor material field suggestions. |

---

## 3. Phase overview

| Phase | Repo | Content | Size | Needs | Mergeable alone |
|---|---|---|---|---|---|
| 1 | web-api | Data model, migration, services (tile upsert, stitching, components, street labels), controllers, Street counts | L | — | Yes (Swagger) |
| 2a | plugin core | Shared extractions R1, R2, R3, R4, R6 + Bukkit-free guard test | S | — | Yes (pure refactor) |
| 2b | plugin core | Survey maths: `SurveySampler` model, `ProfileLearner`, `CoverageCheck` | M | 2a | Yes |
| 2c | plugin core | Builder: span grid, mask, distance transform, thinning, graph, profile match, node matching | L | 2a | Yes |
| 2d | plugin core | Router: graph, snapping, A\*, access policy, region closest point, maneuvers, ETA | M | 2a | Yes |
| 2e | api-client | Ports, DTOs, mappers, impls, conditional GET (R17) | S | 1 (contract) | Yes |
| 3 | plugin paper | Config, wiring, extractions R8-R11/R25, snapshot grid, build job + queue, survey session, dirty tracker, `/knk road`, overlay | L | 1, 2a-2c, 2e | Yes (admin-only) |
| 4 | plugin paper | `/navigate`, sessions, trail/HUD, availability + live re-route, events | M-L | 2d, 3, **KNG-17 on trunk** | Yes |
| 5 | web-app | `/admin/roads` (profiles, tiles, edges), Street road panel | M | 1 | Yes |

Order: 1 and 2a-2d can run in parallel (two sessions); 2e after the Phase 1 DTOs are fixed; 3 after 1+2; 5 any
time after 1; 4 last.

---

## Phase 1 — knk-web-api: data model, services, API

**Goal:** the complete server side of DESIGN §3, per D1-D8. After this phase the plugin can upload tile graphs and
profiles, and anyone can download the network.

### 1.1 Enums and models

- `W/Enums/RoadEnums.cs` (namespace `knkwebapi_v2.Enums`; header comment like `Enums/SiegeEnums.cs`: stored as strings,
  serialized by name): `RoadClass { Main, Road, Path }`, `RoadMaterialRole { Surface, Edge, Accent, Overlay }`,
  `RoadNodeKind { Junction, Endpoint, Boundary, Anchor }`, `RoadNodeSource { Detected, Manual }`,
  `RoadEdgeSource { Detected, Recorded, Stitch }`, `RoadEdgeStatus { Ok, Stale }`,
  `RoadStreetSource { Inferred, Manual, None }`, `RoadSeedSource { Admin, Survey }`, `[Flags] RoadEdgeFlags
  { None = 0, Oneway = 1, NoGps = 2, Closed = 4 }` (stored as int — the one exception, a flags set; comment why).
- Models in `W/Models/Roads/` (file-scoped `namespace knkwebapi_v2.Models;`, XML summary citing DESIGN sections, no
  `FormConfigurableEntity` — these are edited through dedicated endpoints, not FormWizard):
  `RoadProfile`, `RoadSurvey`, `RoadTile`, `RoadSeed`, `RoadNode`, `RoadEdge` with the fields of DESIGN §3.1-3.6 plus:
  `RoadProfile.StatsJson` (D5), `RoadProfile.ScopeTownIdsJson` (D8, nullable), `RoadTile.Version` (D4),
  `RoadEdge.Source = Stitch` for D7, `RoadEdge.World` (denormalised, indexed). JSON columns are `string` properties
  named `*Json`, default `"[]"` where a list is expected. Timestamps `DateTime` set to `DateTime.UtcNow` in services
  (no base class / SaveChanges hook exists).

### 1.2 DbContext and migration

- `W/Properties/KnKDbContext.cs`: `DbSet`s + a commented `// Road navigation (docs/specs/navigation)` block of
  `modelBuilder.Entity<…>` configs after the discovery block. Conventions (from trunk):
  - `ToTable("road_profiles" | "road_surveys" | "road_tiles" | "road_seeds" | "road_nodes" | "road_edges")`,
    `HasKey(e => e.Id).HasName("PRIMARY")`.
  - Enums `.HasConversion<string>().HasMaxLength(20)`; JSON `.HasColumnType("longtext")`; timestamps
    `.HasColumnType("datetime")`.
  - Indexes: `road_profiles.Name` unique; `road_tiles (World, TileX, TileZ)` unique; `road_nodes (World, X, Y, Z)`
    unique, `(TileId)`, `(World, ComponentId)`; `road_edges (FromNodeId, ToNodeId)` unique, `(TileId)`,
    `(World, MinX, MinZ)`, `(StreetId)`; `road_seeds (World)`; `road_surveys (World, StartedAt)`.
  - FKs: node → tile **Cascade**; edge → from/to node **Cascade** (MySQL: two cascade paths from nodes to edges are
    fine; if EF complains about multiple cascade paths, make `ToNode` `Restrict` and delete edges explicitly in the
    service — note it); edge → tile **Cascade**; edge → street **SetNull**; edge → profile **SetNull**; survey →
    profile **SetNull**; survey → user `StartedByUserId` **Restrict** (users are soft-deleted).
- Migration `dotnet ef migrations add AddRoadNetwork` (timestamped `yyyyMMddHHmmss_AddRoadNetwork.cs` + Designer +
  snapshot update). **Bootstrap profile via `migrationBuilder.InsertData`** (discovery-rules precedent), fixed
  `seededAt` UTC: name `Default road`, class `Road`, materials (Surface: GRAVEL, DIRT_PATH, COARSE_DIRT, COBBLESTONE,
  STONE_BRICKS; Accent: COBBLESTONE_SLAB, COBBLESTONE_STAIRS, STONE_BRICK_SLAB, STONE_BRICK_STAIRS, MOSSY_COBBLESTONE,
  MOSSY_STONE_BRICKS, CRACKED_STONE_BRICKS; ambiguous: COBBLESTONE, STONE_BRICKS), `WidthMin` 1, `WidthMax` 7,
  `StatsJson` `{}`.
- Migration test `W/Tests/knkwebapi_v2.Tests/Migrations/AddRoadNetworkTests.cs` modelled on `AddDomainDiscoveryTests`
  (tables, unique indexes, the InsertData row).

### 1.3 DTOs, mapping

- `W/Dtos/RoadDtos.cs` (block namespace `knkwebapi_v2.Dtos`; **every property `[JsonPropertyName("camelCase")]`** —
  the global naming policy is `null`/PascalCase): `RoadProfileDto`, `RoadProfileUpsertDto`, `RoadMaterialDto
  {material, role, ambiguous, centreShare, edgeShare, samples}`, `RoadSurveyCreateDto`, `RoadSurveyDto`,
  `RoadTileDto {id, world, tileX, tileZ, version, builtAt, builderVersion, dirty, cellCount, nodeCount, edgeCount,
  levelCount, warnings[]}`, `RoadTileGraphDto {tile, nodes[], edges[]}`, `RoadNodeDto`, `RoadEdgeDto` (geometry as
  `int[][]`, `gateDoorIds`, `domainIds`, `flags` as string array), `RoadTileGraphUpsertDto` (below), `RoadNetworkMetaDto
  {profiles[], streets: [{id,name}], components: [{id, nodeCount}]}`, `RoadSeedDto`, `RoadNodeUpdateDto`,
  `RoadNodeMergeDto`, `RoadEdgeUpdateDto`, `RoadEdgeRecordDto`, `StreetRoadDto`.
- `RoadTileGraphUpsertDto`: `builderVersion`, `cellCount`, `levelCount`, `warnings[]`, `nodes[{key, existingId?, x, y,
  z, kind}]`, `edges[{existingId?, fromKey, toKey, geometry, length, avgWidth, profileId?, gateDoorIds[],
  domainIds[]}]` — `key` is a client-chosen string unique within the payload; `fromKey`/`toKey` may also be
  `"id:<n>"` to reference an existing node of another tile (never needed by the builder, but allowed for recorded edges).
- `W/Mapping/RoadMappingProfile.cs` (read side only, like `SiegeMappingProfile`); writes mapped by hand in services.
  JSON columns ↔ DTO lists through `JsonColumn` (R29).

### 1.4 Repositories and services

Explicit DI block in `ServiceCollectionExtensions` after the siege block (R33):
`// Road navigation (docs/specs/navigation/IMPLEMENTATION_PLAN.md)`.

- `W/Repositories/Interfaces/IRoadNetworkRepository.cs` + `W/Repositories/RoadNetworkRepository.cs`: tile get/create by
  `(world, x, z)`; tile graph read; nodes/edges by tile; nodes by world; edges by street; structures with location for a
  bbox (joins `structures` → `locations`, for labelling); `RunInTransactionAsync(work)` (R30 pattern, in-memory
  fallback).
- `W/Services/Roads/RoadGeometry.cs` — pure static: point-segment distance (3D), polyline length, bbox, bearing.
  (No geometry helpers exist in the API.)
- `W/Services/Roads/RoadStreetLabeler.cs` — pure static, DESIGN §5.11 (D6): votes from structures (Location within 16
  blocks of an edge, \|Δy\| ≤ 4, weight 1/distance), ≥ 60% majority, continuation through junctions (< 35°, same road
  class, same level) iterated to a fixed point, never overwriting `Manual`. Returns labels + conflicts.
- `W/Services/Roads/RoadComponents.cs` — pure static union-find over (nodes, edges) → `nodeId → componentId`
  (component id = smallest node id in it, so ids are stable).
- `W/Services/Interfaces/IRoadNetworkService.cs` + `W/Services/RoadNetworkService.cs`:
  - `UpsertTileGraphAsync(world, x, z, RoadTileGraphUpsertDto)` in one transaction:
    1. Load the tile's existing nodes/edges.
    2. Validate (DESIGN §3.8 rules + keys unique, kinds valid, geometry ends within 1.5 blocks of its nodes, length ≥
       straight line, node inside the tile's x/z range, referenced profile/gate/domain ids are ints).
    3. Upsert nodes: `existingId` present and belongs to this tile → update position/kind (unless `Locked` → keep
       position); otherwise insert. Delete this tile's `Detected` nodes not in the payload (cascades their edges).
       Keep `Manual` nodes.
    4. Upsert edges the same way; keep admin fields (`StreetId` when `StreetSource = Manual`, `Flags`,
       `CostMultiplier`) on matched edges; keep `Recorded` edges.
    5. Delete + recreate this tile's `Stitch` edges (D7) against neighbour tiles' `Boundary` nodes.
    6. Run `RoadStreetLabeler` for the tile's edges (+ 1-tile ring for continuation); write `StreetId`/`StreetSource`.
    7. `Version++`, `BuiltAt`, `Dirty = false`, counts, warnings (+ labeler conflicts).
    8. Recompute components for the world (`RoadComponents`), update changed `ComponentId`s only.
  - Profiles CRUD (validation: unique name, roles valid, material keys `^[A-Z0-9_]+$`, width min ≤ max, scope town ids
    exist and are Towns).
  - Surveys: create, list by world.
  - Tiles: list by world; mark dirty (sets `Dirty`, edges → `Stale`).
  - Seeds CRUD. Nodes: update (name/kind/lock), create anchor, merge (re-point the second node's edges to the first,
    drop self-loops/duplicates, delete the second; recompute components). Edges: create recorded (ends snapped to the
    nearest node within 3 blocks, else create `Anchor`s), update (street → `Manual`, class override via profile id,
    cost, flags), delete.
  - Meta: profiles + street names + component summary for a world.
  - Validation → `ArgumentException`, not found → `KeyNotFoundException`, conflicts → `InvalidOperationException`
    (trunk convention); controllers map them to `BadRequest(new { error = "ValidationFailed", message })` etc.

### 1.5 Controllers (D1, D3)

Namespace `knkwebapi_v2.Controllers`, kebab-case class routes (like `DiscoveryRewardsController`):

| Route | Verb | Auth |
|---|---|---|
| `api/road-tiles?world=` | GET | anonymous |
| `api/road-tiles/{world}/{tileX:int}/{tileZ:int}/graph` | GET — `ETag: "<version>"`; `If-None-Match` equal → **304** | anonymous |
| `api/road-tiles/{world}/{tileX:int}/{tileZ:int}/graph` | PUT (`RoadTileGraphUpsertDto`) | `[RequirePluginService]` |
| `api/road-tiles/{world}/{tileX:int}/{tileZ:int}/dirty` | POST | `[RequirePluginService]` |
| `api/road-network/meta?world=` | GET | anonymous |
| `api/road-profiles`, `api/road-profiles/{id:int}` | GET / GET | anonymous |
| `api/road-profiles`, `/{id:int}` | POST / PUT / DELETE | `[RequireServiceOrPermission(StaffPermissions.RoadManage)]` |
| `api/road-surveys` | POST | `[RequirePluginService]`; GET `?world=` anonymous |
| `api/road-seeds` | GET `?world=` anonymous; POST/DELETE `{id}` | `[RequireServiceOrPermission(RoadManage)]` |
| `api/road-nodes/{id:int}` | PUT | `[RequireServiceOrPermission(RoadManage)]` |
| `api/road-nodes/anchor`, `api/road-nodes/merge` | POST | same |
| `api/road-edges/search` | POST (`PagedQueryDto`, filters `world`, `tileId`, `streetId`, `unlabelled`, `stale`) | anonymous |
| `api/road-edges`, `/{id:int}` | POST (recorded) / PUT / DELETE | `[RequireServiceOrPermission(RoadManage)]` |
| `api/Streets/{id:int}/road` | GET (on `StreetsController`) | anonymous |

Use `HttpContext.GetKnkCaller().ActorUserId` for `RoadSurvey.StartedByUserId` (plugin sends `X-Acting-User-Id`).

### 1.6 Street counts (R32)

`StreetDto` += `[JsonPropertyName("edgeCount")] int EdgeCount`, `[JsonPropertyName("totalLength")] double
TotalLength`; mapping `.ForMember(..., o => o.Ignore())`; `StreetService` injects `IRoadNetworkRepository` and fills
them in `GetByIdAsync`/`GetAllAsync` (one grouped query for all). Existing street tests must stay green.

### 1.7 Tests (xUnit + EF InMemory, real repositories — `DiscoveryConfigurationServiceTests` style)

- `Services/Roads/RoadGeometryTests`, `RoadComponentsTests`, `RoadStreetLabelerTests` (majority, tie → conflict,
  continuation through a straight junction but not a 90° one, `Manual` untouched, different level ignored).
- `Services/RoadNetworkServiceTests`: first upsert creates nodes/edges, `Version` 1; identical re-upsert keeps ids,
  `Version` 2; missing node deleted with its edges; `Manual`/`Locked` node and `Recorded` edge survive; admin street
  label survives; stitch edges between two adjacent tiles regardless of build order; components merge across the
  stitch; dirty → edges `Stale`, upsert clears it; node merge; recorded edge snapping; validation failures (bad kind,
  geometry far from node, node outside tile).
- `Api/RoadTilesControllerTests`: ETag + 304; auth: web user without node → 403 on PUT graph, plugin key → 200
  (use `Api/ServiceAuthTestHelper`).
- `Services/StreetServiceTests` (existing) + counts case.
- Migration test (1.2).

**Acceptance:** `dotnet test` = baseline + new tests, no new failures; migration passes the four CI steps locally or in
CI; Swagger shows every route; a hand-made two-tile payload round-trips (PUT → GET graph → 304 on repeat).

---

## Phase 2 — knk-plugin core (Bukkit-free) and api-client

### 2a Shared extractions (one commit each, behaviour unchanged)

1. R1 `C/util/BlockKey` (+ tests: pack/unpack round-trip incl. y −64 and 319, neighbours).
2. R2 `C/util/Polygon2D` (+ tests: existing `GateFrameCalculator` tests still green; new closest-point tests).
3. R3 `GateManager.closedFootprint(int)` (+ test with `GateManagerTest.closedGateWithOneBlockAt`).
4. R4 `GateStateListener` in `C/gates/` + `GateManager.addStateListener/removeStateListener/fireStateChanged`
   (+ test: listener fired once on `notifyAnimationCompleted`, on `forceGateState`; existing one-shot callback still
   works).
5. R6 `C/regions/DomainAccessEvaluator` (+ tests moved/added: entry/exit denial messages identical;
   `SimpleRegionTransitionService` tests green).
6. **Guard test** `knk-core/src/test/java/.../core/ArchitectureGuardTest.java`: scans `src/main/java/.../core/{roads,
   navigation,util/BlockKey.java,util/Polygon2D.java,regions/DomainAccessEvaluator.java}` sources and fails on any
   `import org.bukkit`. (No ArchUnit on the classpath; a file scan is enough.)

### 2b Survey maths — `C/roads/survey/`

- `SurveySample` record: `floor` material, `overlay` (nullable), `offsets` = material per lateral offset −7…+7 (null =
  no standable cell / wall), `x, y, z`, `onGround`.
- `SurveyStats` (serialisable to `StatsJson`): per material counts per |offset| bucket (0-1 centre, 2-5 mid, 6-7
  outer), run-end counts, overlay counts, width histogram, sample count. `merge(SurveyStats)`.
- `ProfileLearner.learn(SurveyStats accumulated) → ProposedProfile`: road-likeness `r = centre/(centre+outer)`; run =
  contiguous offsets around 0 with `r ≥ 0.6`; roles (DESIGN §5.3): Surface (≥ 15% of centre samples), Edge (share at
  run ends ≥ 2× its centre share), Accent (road-like, < 5%), Overlay (seen as overlay); ambiguous when also seen in the
  outer bucket in ≥ 10% of samples *outside* runs; drop < 1%; widths = 5th/95th percentile.
  All thresholds are named constants at the top of the class.
- `CoverageCheck.misses(List<BreadcrumbPoint>, RoadNetworkSnapshot, maxDistance=2)` → list of misses with the floor
  material seen there.
- Tests: synthetic cross-sections for (a) stone-brick road with andesite kerbs on grass → Surface/Edge/terrain split;
  (b) gravel path 1-wide in a forest; (c) cobblestone kerb next to cobblestone house floor → ambiguous; (d) merging two
  surveys equals learning on the concatenation.

### 2c Builder — `C/roads/build/`

Ports (Bukkit-free):

```java
public interface SurfaceGrid {                      // R22: same names as teleport's BlockProbe
    boolean isPassable(int x, int y, int z);        // air, plants, carpets…; gate-door cells count as passable (see GateCells)
    boolean isSolid(int x, int y, int z);
    String floorMaterial(int x, int y, int z);      // Material name, "looking through" overlays
    boolean isStairOrSlab(int x, int y, int z);
    int minY(); int maxY();
}
public interface GateCells { OptionalInt doorAt(int x, int y, int z); }   // closed footprints (R3), prebuilt map
```

Classes (DESIGN §5 section in brackets):
- `ProfileSet` — enabled profiles (+ town scope via a `ScopeLookup` port: `OptionalInt townAt(x, z)`), material →
  (role, ambiguous, profile ids); `isRoadMaterial`, `isAmbiguous`.
- `SpanGrid` [§5.2] — spans keyed by `BlockKey`; `neighbour(key, dir 0..7)` computed on demand (at most one per
  direction, headroom rule, step-up headroom except stairs/slabs, diagonal needs an orthogonal link).
- `MaskBuilder` [§5.1, §5.4] — BFS from seeds over spans; ambiguous cells only within `ambiguousReach` of an
  unambiguous span (second BFS distance field); cap → warning with position.
- `DistanceTransform` [§5.5] — multi-source BFS from border spans (8-neighbour via `SpanGrid`), `int` per span.
- `Thinning` [§5.5] — Zhang-Suen on span neighbourhoods (P2..P9 = N, NE, E, SE, S, SW, W, NW via `SpanGrid.neighbour`);
  iterate both sub-passes until stable.
- `SkeletonGraph` [§5.6] — degree classification; junction clustering (radius, centroid-nearest); spur pruning
  (`max(minSpur, width)`); plaza collapse (`dt > widthMax/2` of the matched profile); chain tracing into edges;
  anchors split chains; boundary nodes at tile-border crossings (D7).
- `ProfileMatcher` — floor-material histogram within `dt` of a chain vs profile material shares (cosine) → profile id.
- `Rdp` — 3D Ramer-Douglas-Peucker (ε 0.75).
- `NodeMatcher` [§5.7] — greedy nearest within 3 blocks (3D) to previous nodes of the tile; returns `existingId`s.
- `TileBuilder` — orchestrates: `build(TileRequest{world, tileX, tileZ, margin, seeds, profiles, previousGraph,
  anchors, gateCells}, SurfaceGrid) → TileBuildResult{nodes, edges, cellCount, levelCount, warnings}`; pure, no I/O.
  Domain tagging is *not* here (needs WorldGuard) — the paper job adds `domainIds` afterwards.
- **Test fixtures:** `knk-core/src/test/.../roads/GridFixture.java` — builds a `SurfaceGrid` from ASCII layers:

  ```
  y=64          y=70
  ..GGG..       .......      G = gravel floor, S = stone bricks, a = andesite (edge), c = cobblestone (ambiguous)
  ..GGG..       SSSSSSS      / = stairs, _ = slab, # = wall (solid, not road), . = air/grass (not road)
  ```

  with helpers for stairs between layers and gate cells. Golden tests (each asserts node kinds/count, edge count,
  edge lengths ±1, no stray spurs): meandering 1-wide path; 5-wide road → single centreline; T, X and 5-way junctions
  → one junction each; plaza 15×15 with 4 exits → one junction; stairs up a hill; **tunnel under a road** (two
  separate edges, no junction); **bridge over a road**; **two stacked streets**; **spiral ramp**; mixed profiles
  (gravel into stone) → one continuous edge, profile per edge; cobblestone floor next to a cobblestone kerb held by
  `ambiguousReach`; gap of 2 air blocks → two components + no edge; closed gate cells on the road → edge with
  `gateDoorIds`; tile border crossing → boundary node; rebuild with one block changed keeps all other `existingId`s.

### 2d Router — `C/roads/route/` and `C/navigation/`

- `RoadNetworkSnapshot` (immutable per world): nodes, edges, per-edge decoded polyline, profile classes; built from tile
  graphs + meta; `SegmentIndex` (32×32 x/z buckets → segment refs).
- `Snapper.snap(x, y, z, maxDistance, verticalWeight)` → `SnapPoint{edgeId, segmentIndex, t, point, distance}`.
- `AStarRouter.route(RouteRequest{start, goals (1..n SnapPoints), accessPolicy, classCost}) → RouteResult` —
  virtual nodes split edges; heuristic = min Euclidean to any goal × cheapest class cost; oneway; binary heap.
- `AccessPolicy` interface (`EdgeVerdict check(RoadEdge)` → `OPEN | PASS_THROUGH(hint) | BLOCKED(reason)`) and
  `CompositeAccessPolicy`; implementations take ports:
  - `GateAvailability` (port `GateState { Optional<GateView> gate(int id); }` → state/jammed/destroyed/allowPassThrough/
    siegeLocked; `PassRule { boolean canPass(int gateId); }`) — OPEN or destroyed → open; closed + (pass-through
    allowed or siege-locked-for-non-member, D2) → `PASS_THROUGH`; otherwise blocked; OPENING/CLOSING/jammed → blocked.
  - `DomainAvailability` (uses `DomainAccessEvaluator` R6 + a `DomainLookup` port by domain id; bypass flag) — entry
    denied on edges entering a domain, exit denied on edges leaving the player's current domains.
  - `StaticFlagsAvailability` — `Closed`, `NoGps`.
  - Decisions cached per request by gate/domain id.
- `BlockedExplainer` — if no route: rerun with an "all open" policy; return the first blocked element on that route +
  the last reachable point before it (DESIGN §6.7).
- `RegionShape` (`Polygon2D` R2 + minY/maxY, or cuboid) → goal set: network points inside, else closest (DESIGN §6.3).
- `ManeuverBuilder` (DESIGN §6.5; ignores `Boundary` nodes and stitch edges), `EtaEstimator` (sprint 5.6 b/s).
- `C/navigation/NavigationSession` — pure state machine: `PLANNING → GUIDING ⇄ REROUTING → ARRIVED | ENDED(reason)`;
  inputs: position ticks, availability-change notices, clock; outputs: effects (draw trail range, HUD text, message,
  reroute request). Mirrors the siege `SiegeEffect` style (effects returned, not executed).
- Tests: shortest path vs class costs; oneway; closed gate → explained + partial route to the gate; pass-through gate
  → route with hint; entry denied → route ends at region edge with reason; exit denied; different components → refused;
  snap prefers the bridge over the road below; region multi-goal; maneuvers (left/right/straight bands, street change,
  tunnel/bridge phrases); session: off-route → reroute after N ticks, rate limit, arrival, gate closes mid-route →
  reroute with reason.

### 2e API client — `A/`

- Ports in `C/ports/api/`: `RoadNetworkQueryApi` (`tiles(world)`, `tileGraph(world, x, z, etag)` →
  `Conditional<RoadTileGraph>`, `meta(world)`, `profiles()`, `seeds(world)`), `RoadNetworkCommandApi` (`upsertTileGraph`,
  `markDirty`, `saveProfile`, `createSurvey(…, actingUserId)`, seed/node/edge review calls).
- DTO records in `A/dto/Road*Dto.java` (`@JsonProperty` names = Phase 1 camelCase), mappers `A/mapper/RoadMapper.java`,
  impls `A/impl/RoadNetworkQueryApiImpl.java` / `RoadNetworkCommandApiImpl.java` extending `BaseApiImpl`
  (`CompletableFuture.supplyAsync(..., executor)` like `DiscoveriesApiImpl`), wired in `KnkApiClient` + getters.
- R17: `BaseApiImpl.getConditional` (+ unit test with OkHttp `MockWebServer` if already a test dependency, otherwise a
  stubbed interceptor).
- Tests: mapper round-trips; conditional GET 200/304.

**Phase 2 acceptance:** all new core tests green (scratch build if in the cloud); existing core/api-client tests green;
guard test green.

---

## Phase 3 — knk-plugin paper: admin side (survey, build, review)

### 3.1 Config (R16)

`KnkConfig.NavigationConfig` (+ nested `SurveyConfig`, `BuilderConfig`, `TrailConfig`) with `defaults()` and
`validate()`, keys exactly as DESIGN §4; `ConfigLoader.loadNavigation`; back-compat constructors; `config.yml`
`navigation:` section; `ConfigLoaderNavigationTest` like the discovery one.

### 3.2 Extractions first (R8, R9, R10, R11, R25) — separate commits, callers delegate, tests green.

### 3.3 Wiring in `KnKPlugin`

- Promote to fields: `regionDomainResolver` (L689-697), `regionTracker` (L745). Note the double `CacheManager`
  construction (L363 and L466) — use the field as it is after L466; don't fix it here (flag it in the status).
- Construct (only if `navigation.enabled`) in a new `initializeRoads()` called after `initializeSiege()` (L822):
  `locationsDataAccess`, `streetsDataAccess`, `districtsDataAccess`, `structuresDataAccess` (R18; reuse if already
  present), `RoadNetworkCache`, `RoadDirtyTracker`, `RoadBuildQueue`, `RoadSurveyService`, `RoadOverlayRenderer`,
  `RoadAdminCommand`; register `road` on the `/knk` command (keep `knkAdminCommand` as a field, or use a supplier like
  `DiscoveryAdminCommand`); listeners via the existing `registerEvents` style.
- `onDisable`: stop survey sessions (discard), stop build queue (persist progress is in the API; nothing to spool),
  stop dirty-tracker flush (flush once synchronously if the API is reachable), before `apiClient.shutdown()` (L912).
- `plugin.yml`: `knk.admin.road` declared + added to `knk.admin` children; `knk.navigate: default: true` (used in
  Phase 4).

### 3.4 Classes — `P/roads/`

- `ChunkSnapshotSurfaceGrid` (implements `SurfaceGrid`): holds a **compact extraction** per chunk, not the snapshot
  (DESIGN §9): on the main thread take `chunk.getChunkSnapshot(false, false, false)`, immediately scan it for
  candidate spans (profile-material floor, or stairs/slab, with 2 passable blocks above — gate-door blocks count as
  passable) and keep only `long[] keys` + `short[] materialIds` + a flags byte per span (stair/slab, third block above
  passable — for the step-up rule of DESIGN §5.2, gate-tagged); release the snapshot. Material ids through a small
  `MaterialIds` intern table. The grid answers `isPassable`/`isSolid` only for the cells those flags describe; the
  builder never asks about other cells (assert this in a test with a strict fake).
- `GateCellsIndex` (implements `GateCells`) — from `gateManager.getAllGates()` + `closedFootprint` (R3) per world.
- `RoadBuildJob` — one tile: resolve seeds (API seeds + survey breadcrumbs + Domain Locations with a road span within 8
  blocks — domain locations from the town/district/structure data access), capture chunks the BFS reaches via
  `getChunkAtAsync` + main-thread extraction at `snapshot-chunks-per-tick` (R11 `TickBudget`), run `TileBuilder` on the
  api-client executor, tag `domainIds` on the main thread in budgeted batches (`RegionIds.at` R8 + R7), upload via
  `upsertTileGraph`, invalidate the cache for the tile, report a summary to the requester.
- `RoadBuildQueue` — ordered tiles (here / tile / radius / dirty / all), one job at a time, resumable (skips tiles whose
  `BuiltAt` is newer than the queue start on restart), throttled by TPS; progress in the action bar for the admin who
  started it.
- `RoadNetworkCache` — per world: tile list → conditional tile downloads (R17) → local file cache
  `plugins/KnightsAndKings/roads/<world>/<x>_<z>.json` (+ version) → `RoadNetworkSnapshot` (2d) rebuilt off-thread and
  swapped atomically; refresh on start, after builds, every 10 min.
- `RoadSurveyService` + `RoadSurveySession` — `/knk road survey start|stop|cancel`; samples every
  `sample-period-ticks` only when on ground, walking (speed > 0.1 b/tick), not flying/riding/swimming; builds
  `SurveySample`s (cross-section via world reads on the main thread — at most 15 columns per sample); live action bar;
  on stop: `ProfileLearner` on (profile's stored stats + this survey) → chat review with clickable
  **Save / Merge into … / Discard** (R26 pattern) → `createSurvey` + `saveProfile`; breadcrumb stored with the survey;
  survey seeds every `breadcrumb-seed-spacing`.
- `RoadDirtyTracker` — listeners for `BlockPlaceEvent`, `BlockBreakEvent`, `EntityExplodeEvent`/`BlockExplodeEvent`,
  `BlockPistonExtend/RetractEvent` (MONITOR, ignoreCancelled): material in `ProfileSet` or the block is headroom of a
  road span in the current snapshot → mark tile; flush batched every 30 s via `markDirty`. WorldEdit: if WorldEdit is
  present, subscribe to `EditSessionEvent` (register through WorldEdit's event bus in a class loaded only when the
  plugin is present) and mark the tiles of the edit region.
- `RoadOverlayRenderer` — `/knk road show [radius] [all]` per admin, ticker every 20 ticks: nodes as pillars, edges as
  polylines (R9 `ParticleDraw`), colours by street hash/status; only ±8 Y unless `all`; action-bar label of the
  looked-at node/edge.
- `RoadAdminCommand` — all DESIGN §7 subcommands; node check like `DiscoveryAdminCommand.hasNode` (R15); tab
  completion method used by `KnkAdminCommand.onTabComplete` (R13). Build summary with clickable teleports
  (`/knk tp`-style existing command or `player.teleportAsync` for staff).

### 3.5 Tests (knk-paper, JUnit 5 + Mockito; mocked `World` kept in a field)

`ConfigLoaderNavigationTest`; `RoadDirtyTrackerTest` (palette vs non-palette block, headroom block, batching);
`RoadSurveySessionTest` (sampling gates: flying/standing still ignored); `RoadAdminCommandTest` (permission denied,
usage, tab completion); `GatePassThroughRulesTest` (R25, same outcomes as the old listener tests);
`TickBudgetTest`; `ParticleDrawTest` (viewer range filter).

**Acceptance (developer, live):** survey three road types (main street, wilderness road, trail) → profiles saved;
`/knk road build radius 1500` around one real town (including a tunnel or bridge if one exists) → summary; `/knk road
show` looks right; one street label fix; a block broken on the road marks the tile dirty; rebuild keeps names.

---

## Phase 4 — knk-plugin paper: `/navigate` (after KNG-17 is on trunk)

**Start condition:** `origin/main` of knk-plugin contains the teleport classes (`C/teleport/WarpTargets`, …). Merge
trunk into `claude/road-navigation` first.

1. **R22** move `BlockProbe` to `C/util/BlockProbe`; `SurfaceGrid extends BlockProbe`; teleport imports updated.
2. **R21** `C/util/NamedTargets<T>`; `WarpTargets` delegates; teleport tests green.
3. **R20** `C/navigation/DomainLocationResolver` (town/district embedded location, structure `locationId` → Location
   lookup, `LocationLookup` ports); teleport `SpawnDestinationResolver` delegates.
4. **R6 follow-up**: teleport's `previewAccess` delegates to `DomainAccessEvaluator`; the `knk.region.bypass`
   predicate feeds `DomainAvailability`'s bypass.
5. `P/navigation/NavigationDestinations` — catalogue for `/navigate`: `DomainCatalogDataAccess.searchAsync` (R19),
   `LocationsDataAccess` search, `StreetsDataAccess.searchAsync` (R18), named road nodes from the snapshot → one list of
   `NavTarget(type, name, id)` resolved by `NamedTargets` (bare name / `type:name` / `type:#id`, ambiguity choices,
   tab completion).
6. `P/navigation/NavigateCommand` (`TabExecutor`, `registerTabCommand("navigate", …)`, alias `nav` in `plugin.yml`,
   node `knk.navigate` via R15) — DESIGN §6.1 forms, `stop`, no-arg status.
7. `P/navigation/NavigationService` — sessions per player (`C/navigation/NavigationSession`), routing off-thread on
   the api-client executor, effects applied on the main thread (R12); hard 48-block limit and direct mode
   (DESIGN §6.2); availability via `CompositeAccessPolicy` with paper adapters: `GateState` ← `GateManager` (R5) +
   `SiegeGateController.isLocked` (R24) + `GatePassThroughRules` (R25); `DomainLookup` ← `RegionDomainResolver` (R7).
8. Live changes: `GateStateListener` (R4) → sessions whose route contains that gate re-plan; `SiegeMatchObserver`
   (R24) `areaLockdownStarted`/`matchEnded` → re-plan affected sessions; domain cache refresh → re-plan all (rate
   limited).
9. **Siege read-only accessors** (coordinate first, §0.5): `KnKPlugin` field + getter for `siegeGates`; nothing else
   in siege changes. `NavigationEligibility` (R23) ends sessions when the player joins a siege lobby (`lobbyOf`),
   dies, quits, changes world, teleports > 16 blocks (`PlayerTeleportEvent`), or hits `max-session-minutes`.
10. `P/navigation/TrailRenderer` (R9 `ParticleDraw.polyline`, per player, next `trail-length` blocks, off-road legs
    sparser/other colour, heights via `SiegeFloor` R28) and `NavigationHud` — Adventure `BossBar` (`player.showBossBar`)
    with distance/ETA/next maneuver, `player.sendActionBar` arrow; hide on end.
11. Events in `P/events/`: `NavigationStartEvent` (cancellable), `NavigationRerouteEvent`, `NavigationArriveEvent`,
    `NavigationEndEvent` — same style as existing custom events there.
12. `NavigationMessages` (R26) with every player-facing string from DESIGN §6.

**Tests:** `NavigateCommandTest` (parsing, ambiguity, permission, too-far refusal message); `NavigationServiceTest`
(mocked snapshot + policy: start, reroute on gate change, end on siege join/teleport/death); `TrailRendererTest`
(range, spacing); core session tests from 2d.

**Acceptance (developer, live):** navigate to a Location, a Town spawn, a Structure, a region edge (`region`), a
street; through a tunnel; closed gate → reason + guidance to the gate; open it mid-route → shorter route announced;
pass-through gate hint; denied domain → ends at its edge with the reason; 48-block refusal; re-route when walking off;
arrival; auto-end on death/teleport/siege join.

---

## Phase 5 — knk-web-app: admin pages

- `F/types/dtos/road/RoadDtos.ts` (camelCase like the API), `F/apiClients/roadClient.ts` (R35; singleton; `Controllers`
  enum entries `RoadProfiles = 'road-profiles'`, `RoadTiles = 'road-tiles'`, `RoadEdges = 'road-edges'`,
  `RoadNetwork = 'road-network'`; GET params only for keys you have — undefined is sent as the text "undefined").
- Node constant `ROAD_ADMIN_NODE = 'knk.admin.road'` next to the DTOs; route `/admin/roads` in `F/App.tsx` inside
  `StaffRoute node={ROAD_ADMIN_NODE}`; nav link in `F/components/Navigation.tsx` + `nodeAccess` entry (R34),
  lucide icon `Route`.
- `F/pages/admin/RoadsAdminPage.tsx` (thin page, state + fetching, world selector) with cards in
  `F/components/admin/roads/`:
  - `RoadProfilesCard` — list, create, edit (name, class, cost, width, enabled, scope towns via `SearchableDropdown` over
    towns), materials table (material key text input with suggestions from `getHybrid` R38, role select, ambiguous
    toggle, read-only shares); pure `roadProfileForm.ts` (parse/validate, like `discoveryRuleForm.ts`).
  - `RoadTilesCard` — tile table (x, z, version, built, dirty, counts, warnings expandable), filter dirty/warnings.
  - `RoadEdgesCard` — server-paged `POST road-edges/search` with filters (unlabelled, stale, street); inline edit
    (street via `SearchableDropdown` + `streetClient.searchPaged` R37, cost, flags) in the `DiscoveryOverridesCard`
    pattern (R34), 4xx messages shown.
- Street road panel: `F/components/roads/StreetRoadPanel.tsx` (like `SiegeReadinessPanel`) registered as
  `streetRoad` in `F/components/FormWizard/displayPanels.tsx` (R36); document in the phase status how to add it to the
  Street FormConfiguration (a field on `Id` with `settingsJson {"displayPanel":"streetRoad"}` — a dev-DB step for the
  developer).
- Tests (jest + RTL; `react-router-dom` virtual mock as in `DiscoveryAdminPage.test.tsx`): client URL/method tests;
  `roadProfileForm` parser; page renders + error state; edge inline edit save/cancel/4xx; panel loading/error.

**Acceptance:** `npm run test:ci` = baseline + new tests; pages usable against a local API with seeded data; no new
ESLint warnings in touched files.

---

## 6. Out of scope (Phase 6 in DESIGN §8)

Automatic rebuild of dirty tiles; "follow road" mode; Pathetic off-road legs; NPC routing; travel modes and risk costs;
treasure-map items; discovery-gated destinations; web map; coarse graph above ~100 k nodes. Don't start any of these.

## 7. Risks and how to handle them

| Risk | Handling |
|---|---|
| Thinning artefacts on odd shapes (diagonal 2-wide roads, plazas) | Golden tests first; tune `min-spur-length`/cluster radius constants; anchors are the admin escape hatch. |
| Palette leaks (cobblestone towns) | Ambiguity reach + cell cap warnings; scoped profiles; test fixture. |
| Tile upsert size (dense town tile, ~2-3 k edges) | One transaction; batch inserts (`AddRange`); measure in the status block. |
| Build job main-thread cost | Compact extraction per chunk only; `TickBudget`; stop when TPS < 15. |
| KNG-17 merge conflicts | R6/R20-R22 are designed as delegations; do them in Phase 4, after the teleport merge, never before. |
| knk-paper not compilable in the cloud | Say so; keep paper code simple and read it twice; developer builds locally. |

## 8. Definition of done (whole feature)

All five phases merged to trunk by the developer; DESIGN §10 decisions implemented; tests green (baselines only);
`ACTIVE_SESSIONS.md` row moved to "Recently completed"; KNG-27 acceptance boxes ticked; a short handoff in
`docs/ai-agents/handoffs/` listing branches to delete.

## 9. Phase status template (append under each phase)

```
### Phase N status — <done|partial|blocked> <date> (<repo> `claude/road-navigation` <commits>)
- What was built (classes/files).
- Reuse: which §2 rows were applied; anything else reused.
- Tests: before → after per repo (note known failures); what was not run and why (e.g. knk-paper not compiled).
- Decisions to review: numbered, each with the default taken.
- Discrepancies found (docs vs code).
- Developer to-do (live checks, dev-DB steps, local builds).
```
