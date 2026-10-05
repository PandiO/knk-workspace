# Road Navigation — Implementation Plan

**Status:** In implementation (chain, `docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md`). **Phase 1 done**
(knk-web-api `claude/road-navigation` `77e0a29`, 2026-09-27); **Phase 2a done** (knk-plugin `claude/road-navigation`
`db962a4`, 2026-09-27); **Phase 2b done** (knk-plugin `claude/road-navigation` `92375e5`, 2026-09-27); **Phase 2c done**
(knk-plugin `claude/road-navigation` `c2ca1e3`, 2026-09-27); **Phase 2d done** (knk-plugin `claude/road-navigation`
`a82db3c`, 2026-09-27); **Phase 2e done** (knk-plugin `claude/road-navigation` `4ffdd1a`, 2026-09-28); **Phase 3 done**
(knk-plugin `claude/road-navigation` `96f4c62`, 2026-09-28; compiled by link 9 on 2026-09-29 — the first Gradle build
was clean, one tab-completion slip fixed in `68fa48c`); **Phase 5 done** (knk-web-app `claude/road-navigation`
`9dbb481`, 2026-09-28); **Phase 4 done** (knk-plugin `claude/road-navigation` `4e3f8af`, 2026-09-29, after the trunk
merge `be5df0f` that brought in KNG-17). **All phases done — the chain is complete**; the developer merges phase by
phase after testing (closing handoff `docs/ai-agents/handoffs/2026-09-29-road-navigation-closeout.md`).
Every code reference was verified against trunk by a separate review pass on 2026-09-27; its corrections are folded in.
**Last updated:** 2026-10-04 (§5.6 designed plazas and the finding L follow-up; 2026-10-02: §5.5 fix-plan items 1-6 plus findings B and G implemented on
`claude/road-navigation-smoke-test-bugs-fagl4i`, awaiting the developer's merge and live re-test — see "5.5 status";
the walkable last mile stays open as KNG-51,
`LAST_MILE_PATHFINDING.md`; 2026-10-04 status: §5.6)
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

**Running as a chain of sessions?** Follow [`docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md`](../../ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md)
(one phase per link, fresh context per phase, never blocked by the developer's live testing); it adds to this section.

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
- **Never** change siege behaviour (siege is being playtested in parallel). Files you may not modify:
  `P/siege/**`, `C/siege/**`, `W/Services/Siege*`, `W/Models/Siege/**` — **except these four mechanical edits**, each in
  its own commit with siege tests green: `P/siege/SiegeWorldPresenter.java` (R9 delegation), `P/siege/SiegeBukkit.java`
  (R10 delegation), `P/siege/SiegeGateController.java` (R39 read-only predicate extraction, Phase 4) and the
  `siegeGates` field + getter in `KnKPlugin` (R24, Phase 4).

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
  `specs/items/GRADE_DROPCHANCE.md`. Stub `org.bukkit.util.Vector` for the files that import it: `C/gates/*`,
  `C/util/VectorMath`, `C/util/CoordinateParser`, `C/domain/gates/{BlockSnapshot,CachedGateDoor}`.
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
| D2 | §6.7: siege areas blocked for non-participants | **Siege areas are not blocked.** A siege-locked gate (`SiegeGateController.isLocked(gateStructureId)`) is passable for a non-member exactly when the siege's own non-member rule would carry them through (R39): with the default view `PreLockdownView` always (TELEPORT carry, `KnKPlugin` L1447-1449); with `PassThroughOnly` only doors that were open before the lockdown, by right-click. Navigation ends when the player joins a siege lobby | Matches trunk behaviour; blocking would contradict what the game allows. DESIGN §6.7 updated. |
| D3 | §3.8 endpoint list | Final route table in Phase 1 (kebab-case class routes, tile graph under `api/road-tiles/{world}/{x}/{z}/graph`, ETag + 304) | Local conventions + there is no ETag support anywhere yet. |
| D4 | §3.3 `RoadTile` | Adds `Version` (int, +1 per build) — the ETag | Needed for per-tile download. |
| D5 | §3.1 profile merge endpoint `merge-survey` | **Dropped.** The plugin's `ProfileLearner` (one implementation, Java) recomputes the profile from stored stats + the new survey and `PUT`s it; `RoadProfile` gains `StatsJson` (accumulated counts) | Avoids implementing the role rules twice (C# + Java). |
| D6 | §4 `StreetLabeler` in knk-core | **Street labelling runs in knk-web-api** during the tile upsert (`Services/Roads/RoadStreetLabeler.cs`, pure) | Structures, their Street and Location rows are in the DB; doing it in the plugin means N+1 API calls per tile. |
| D7 | §5.6 step 7 "Boundary node matched by position" | Concrete rule: each tile owns `Boundary` nodes on its own border cells; after a tile upsert the API creates a 1-block **stitch edge** between each of its boundary nodes and an adjacent (Chebyshev ≤ 1 in x/z, \|Δy\| ≤ 1) boundary node of a neighbour tile. Stitch edges are owned by the tile being upserted; the upsert deletes every stitch edge touching its boundary nodes (whoever owned it), recreates them, and bumps `Version` of every other tile that lost an owned stitch edge | Builds are order-independent; no cross-tile writes from the plugin; ETags never serve stale stitches. |
| D8 | §3.1 `ScopeDomainIds` "(e.g. one kingdom's towns)" | Scope = list of **Town** domain ids (no Kingdom/Province entity exists) | Revisit when a Kingdom entity exists. |
| D9 | §5.4 gate lookup via `GateSpatialIndex` | Use each door's **closed footprint** (`GateManager` frame 0), not the spatial index | The index only holds the *current* frame; an open gate would be missed. |
| D10 | Profile editor "material picker" | Text field with suggestions from `minecraftMaterialRefClient.getHybrid` | `HybridMaterialPicker` is a full paged table — too heavy per row. |
| D11 | §3.6 edges store `DomainIds` | Edges store **`RegionIds`** (WorldGuard region ids, ordered) as well as `DomainIds` | The plugin resolves domains by *region id* only (`RegionDomainResolver`); routing looks up region ids, the web app shows domain ids. |
| D12 | §5.4 seeds "every Domain Location near a road" | New endpoint `GET api/road-network/seed-locations?world=&minX=&minZ=&maxX=&maxZ=` returns domain Locations in a box | The plugin's data accesses only look up by id/region; listing per tile would be N+1. |
| D13 | §6.7 "live changes" via gate events | Gate events **plus** a 2-second re-check of the gates on active routes | Gate state is mutated in many places (see R4); a missed event must only delay a re-route, never leave a player routed through a closed gate. |

---

## 2. Reuse map (existing code → how this feature uses it)

"Extract" = move to the new location, make the old class delegate (keep its public API), keep its tests green.

| # | Existing | Where (trunk) | Action |
|---|---|---|---|
| **knk-plugin** | | | |
| R1 | `GateSpatialIndex.packCell(int,int,int)` (26/12/26-bit key) | `C/gates/GateSpatialIndex.java:25` | **Extract** to `C/util/BlockKey.java` (`pack`, plus new `x(key)`, `y(key)` with 12-bit sign extension, `z(key)`, `neighbour(key, dx,dy,dz)`); `GateSpatialIndex.packCell` delegates. Don't touch `GateBlockScanTaskHandler.packCoordinate` (different layout, internal). |
| R2 | `GateFrameCalculator.pointInPolygon(u,v,List<double[]>)` (package-private) | `C/gates/GateFrameCalculator.java:392` | **Extract** to `C/util/Polygon2D.java` (public `contains`, plus new `closestPointOnBoundary`, `distanceToBoundary`); `GateFrameCalculator` delegates. |
| R3 | `GateManager.doorBlockPositions(gate, frame)` (private static) | `C/gates/GateManager.java:151` | Make **public** as `closedFootprint(int gateId)` (frame 0 = closed, see `GateAnimationTask` L206-211) returning `List<Vector>`; used by the build job to tag gate cells. |
| R4 | Gate state changes: only a one-shot per-gate callback (`setAnimationCompletionCallback`, L89, removed when it fires) | `C/gates/GateManager.java`; mutations elsewhere | **Add** a multicast `GateStateListener` (`void gateStateChanged(int gateId)`) to `GateManager` (`addStateListener`/`removeStateListener`/`fireStateChanged(id)`). Fire it inside `GateManager` on: open start (OPENING, ~L281), close start (CLOSING, ~L317), `notifyAnimationCompleted`, `forceGateState`, `cacheGate` (reload). Call `fireStateChanged` after the mutations outside it: `HealthSystem.destroyGate` (L131) / `respawnGate` (L302), jam in `GateAnimationTask` (~L525/L534), `GateCommand` destroyed/active toggles (~L556/L610). Siege override setters in `SiegeGateController` (~L309/L324) are **not** edited — D13's 2-second re-check covers them. Don't change the existing one-shot callback. |
| R5 | `CachedGateDoor` effective accessors | `C/domain/gates/CachedGateDoor.java` L383-410 (`isEffectivelyActive/Destroyed/AllowPassThrough`), `getCurrentState()`, `isJammed()` L373, `getCurrentSiegeId()` | Use as is in `GateAvailability` (Phase 2d). Always the *effective* accessors. |
| R6 | Entry/exit rules: private `checkEntryDenials`/`checkExitDenials` | `C/regions/SimpleRegionTransitionService.java` L144-182 | **Extract** to `C/regions/DomainAccessEvaluator.java` (pure; `Optional<Denial> entry(DomainSnapshot)`, `Optional<Denial> exit(DomainSnapshot)`; messages unchanged). The service delegates. When KNG-17 merges, its `previewAccess` must also delegate to this evaluator, and its `knk.region.bypass` predicate becomes the evaluator's bypass input — note this in the Phase 2 status for the teleport merger. |
| R7 | `RegionDomainResolver` + `DomainSnapshot` | `C/regions/RegionDomainResolver.java` (`getDomainByRegionIdNoRefresh` L285, `resolveRegionsFromApi` L146, record L600) | Use as is to map WG region ids → domain ids/snapshots (build-time domain tagging, runtime access). Promote the local `regionDomainResolver` in `KnKPlugin` (L689-697) to a field. |
| R8 | "WG region ids at a location" — **3 copies** | `P/regions/WorldGuardRegionTracker.getRegionNamesAt` L203-217, `P/regions/WorldGuardRegionLookup.at` L23-37, `P/discovery/DomainDiscoveryListener.regionIdsAt` L256-268 | **Extract** `P/regions/RegionIds` with a cached `RegionQuery`: `applicable(Location)` → `ApplicableRegionSet` and `at(Location)` → ids (excluding `__global__`, like the discovery copy — confirm WG doesn't list it anyway and say so in the status). The tracker and discovery listener delegate to `at`; `WorldGuardRegionLookup` delegates to `applicable` (it needs the set for `queryValue(Flags.PVP)`). Navigation uses `at`. |
| R9 | `SiegeWorldPresenter.ring(...)` per-viewer particles (private static) | `P/siege/SiegeWorldPresenter.java` L333-346 | **Extract** to `P/utils/ParticleDraw.java` (`ring(...)` unchanged + new `polyline(Player, List<Vector>, spacing, Particle, DustOptions)`, `pillar(...)`); siege delegates. This is the only siege file you edit, and only as this mechanical extraction. |
| R10 | `SiegeBukkit.toLocation(KnkLocation)`, `floorOf(Location)` | `P/siege/SiegeBukkit.java` | **Extract** the two generic methods to `P/utils/KnkLocations.java`; `SiegeBukkit` delegates. |
| R11 | TPS lag check — **3 copies** (`Bukkit.getTPS()[0] < 15`) + per-tick block budget | `P/tasks/GateBlockScanTaskHandler.java` L53-55, ~L549, ~L715, ~L847 (a fourth, different TPS read in `GateAnimationTask` ~L755 stays as is) | **Extract** `P/utils/TickBudget.java` (`isServerLagging()`, `perTick(normal, lagging)`); the three call sites delegate. |
| R12 | Main-thread executor | `P/menu/MenuService.mainThreadExecutor(Plugin)` L97-105 | Use as is (`whenCompleteAsync(..., mainThread)`); don't write another. |
| R13 | `/knk` subcommand registry | `P/commands/KnkAdminCommand.registerSubcommand` L417; metadata `CommandMetadata`; tab completion hard-coded in `onTabComplete` L451-480 | Register `road` like `DiscoveryAdminCommand` (lazy suppliers, own node check through Bukkit + `KnkPermissible`); add a `road` branch to `onTabComplete` that delegates to `RoadAdminCommand.complete(...)`. |
| R14 | Top-level command helpers | `KnKPlugin.registerTabCommand` L1310 (`/pay` template: `P/commands/PayCommand.java`) | `/navigate` uses `registerTabCommand`. |
| R15 | Permissions | `P/permissions/KnkPermissible.hasPermission(Player,String)` (sync, cache-only, fails closed) | Node checks for `knk.navigate` and `knk.admin.road` exactly like `DiscoveryAdminCommand.hasNode`. |
| R16 | Typed config | `P/config/KnkConfig.java` (record + section records with `defaults()`/`validate()`), `P/config/ConfigLoader.java` (`loadDiscovery` L112-150), test `ConfigLoaderDiscoveryTest` | Add `NavigationConfig` the same way. |
| R17 | REST client base | `A/impl/BaseApiImpl.java` (`get`, `putJson`, `execute` → `ApiException` on non-2xx incl. 304) | **Improve**: add `ConditionalResponse getConditional(String url, String etag)` returning `{notModified, body, etag}` (304 is not an error there). New impls extend `BaseApiImpl`; wire in `A/client/KnkApiClient` (constructor L136-188 + getter). |
| R18 | Data access for streets/locations/districts/structures (all **never constructed** on trunk) | `C/dataaccess/{StreetsDataAccess,LocationsDataAccess}`, `P/dataaccess/DataAccessFactory.createStreetsDataAccess` L101, `createLocationsDataAccess` L116, `createDistrictsDataAccess`, `createStructuresDataAccess` | Construct them in `KnKPlugin` as **fields**. KNG-17 creates some of them inline as arguments to `SpawnDestinationResolver.create` (teleport `KnKPlugin` L1236-1242): after that merge, promote those to the same fields and pass them in — one instance each. Add `searchAsync(PagedQuery)` to `StreetsDataAccess` and `LocationsDataAccess` (neither has one; the query ports `StreetsQueryApi.search`/`LocationsQueryApi.search` exist). |
| R19 | Domain catalogue | `C/dataaccess/DomainCatalogDataAccess.searchAsync(PagedQuery)` L90 → `KnkDomainSummary(id,name,domainType)` | Destination name search for towns/districts/structures. |
| R20 | Domain → Location resolution (town/district embed `location`; structure has only `locationId`) | Teleport branch `P/teleport/SpawnDestinationResolver.ownLocation(...)` + lambdas | Phase 4: **extract** into `C/navigation/DomainLocationResolver.java` (Bukkit-free, `LocationLookup` ports); teleport's `SpawnDestinationResolver` delegates. |
| R21 | Name/`type:name` resolution + completion | Teleport branch `C/teleport/WarpTargets` (bound to `KnkTeleportDestination`) | Phase 4: **generalise** into `C/util/NamedTargets<T>` (accessor functions for name/type/qualifiedName); `WarpTargets` becomes a thin wrapper. |
| R22 | `BlockProbe` / `SafeLocationFinder` / `BukkitBlockProbe` | Teleport branch `C/teleport/`, `P/teleport/` (`BlockProbe`: `isPassable`, `isSolid`, `isHazard`, `minY()`, `maxY()` — **maxY exclusive**) | Phase 4: move `BlockProbe` to `C/util/BlockProbe` (teleport keeps working via import change) and make `SurfaceGrid` **extend** it. Until then `SurfaceGrid` declares **all five** methods with the same signatures and semantics (incl. `isHazard` and exclusive `maxY`), so the later `extends` changes no implementation. |
| R23 | Eligibility pattern | `P/discovery/DiscoveryEligibility` (loading/mode/freeze/gamemode/siege predicates) | `NavigationEligibility` composes the same services (`JoinLoadingGuard`, `ModeService`, `AdminFreezeManager`, `SiegeService`) — reuse predicates, don't copy logic. |
| R24 | Siege read-only state | `P/siege/SiegeService.lobbyOf(UUID)`, `activeLobbyOf`, `addObserver(SiegeMatchObserver)` (hooks `areaLockdownStarted`, `roundReleased`, `objectiveCaptured`, `matchEnded`); `SiegeGateController.isLocked(int gateStructureId)` L222 — takes the **structure** id: map door → `CachedGateDoor.getGateStructureId()` (instance is a local in `KnKPlugin` L1452) | Phase 4: promote `siegeGates` to a field + getter; read-only use. |
| R39 | Siege non-member gate rule (inline) | `P/siege/SiegeGateController.tryNonMemberPassThrough` ~L269-278, `P/siege/SiegeGateViewService.carryNonMemberThrough`, view mode `NonMemberGateView` (`PreLockdownView` default / `PassThroughOnly`) | Phase 4: **extract** the condition into a public read-only `SiegeGateController.canCarryNonMember(CachedGateDoor)` (uses the configured view mode and the door's pre-lockdown open state); the two existing callers use it; navigation's `GateAvailability` uses it (D2). Behaviour unchanged; siege tests green. |
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
| 2b | plugin core | Survey maths: `SurveySample`/`SurveyStats`, `ProfileLearner` | M | 2a | Yes |
| 2c | plugin core | Builder: span grid, mask, distance transform, thinning, graph, profile match, node matching | L | 2a | Yes |
| 2d | plugin core | Network snapshot, router: snapping, A\*, access policy, region closest point, maneuvers, ETA, `CoverageCheck` | M | 2a | Yes |
| 2e | api-client | Ports, DTOs, mappers, impls, conditional GET (R17) | S | 1 (contract) | Yes |
| 3 | plugin paper | Config, wiring, extractions R8-R11/R25, snapshot grid, build job + queue, survey session, dirty tracker, `/knk road`, overlay | L | 1, 2a-2e | Yes (admin-only) |
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
  `RoadEdge.Source = Stitch` for D7, `RoadEdge.World` (denormalised, indexed), `RoadEdge.RegionIdsJson` (D11). JSON columns are `string` properties
  named `*Json`, default `"[]"` where a list is expected. Timestamps `DateTime` set to `DateTime.UtcNow` in services
  (no base class / SaveChanges hook exists).

### 1.2 DbContext and migration

- `W/Properties/KnKDbContext.cs`: `DbSet`s + a commented `// Road navigation (docs/specs/navigation)` block of
  `modelBuilder.Entity<…>` configs after the discovery block. Conventions (from trunk):
  - `ToTable("road_profiles" | "road_surveys" | "road_tiles" | "road_seeds" | "road_nodes" | "road_edges")`,
    `HasKey(e => e.Id).HasName("PRIMARY")`.
  - Enums `.HasConversion<string>().HasMaxLength(20)`; JSON `.HasColumnType("longtext")`; timestamps
    `.HasColumnType("datetime")`.
  - **Every indexed string needs `HasMaxLength`** (Pomelo maps an unbounded `string` to `longtext`, which MySQL can't
    index): `World` 64 (all tables), `RoadProfile.Name` 100, `RoadNode.Name` 100, `RoadSeed.Note` 200.
  - Indexes: `road_profiles.Name` unique; `road_tiles (World, TileX, TileZ)` unique; `road_nodes (World, X, Y, Z)`
    unique, `(TileId)`, `(World, ComponentId)`; `road_edges (FromNodeId, ToNodeId)` unique, `(TileId)`,
    `(World, MinX, MinZ)`, `(StreetId)`; `road_seeds (World)`; `road_surveys (World, StartedAt)`.
  - FKs: node → tile **Cascade**; edge → from/to node **Cascade** (two cascade paths are fine on MySQL — the
    "multiple cascade paths" error is SQL Server's); edge → tile **Cascade**; edge → street **SetNull**; edge → profile **SetNull**; survey →
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
  `RoadNodeMergeDto`, `RoadEdgeUpdateDto` (incl. `propagate`), `RoadEdgeRecordDto`, `StreetRoadDto`, `RoadSeedLocationDto {domainId,
  domainType, name, x, y, z}` (D12).
- `RoadTileGraphUpsertDto`: `builderVersion`, `cellCount`, `levelCount`, `warnings[]`, `nodes[{key, existingId?, x, y,
  z, kind}]`, `edges[{existingId?, fromKey, toKey, geometry, length, avgWidth, profileId?, gateDoorIds[],
  domainIds[], regionIds[]}]` — `key` is a client-chosen string unique within the payload; `fromKey`/`toKey` may also be
  `"id:<n>"` to reference an existing node of another tile (never needed by the builder, but allowed for recorded edges).
- `W/Mapping/RoadMappingProfile.cs` (read side only, like `SiegeMappingProfile`); writes mapped by hand in services.
  JSON columns ↔ DTO lists through `JsonColumn` (R29).

### 1.4 Repositories and services

Explicit DI block in `ServiceCollectionExtensions` after the siege block (R33):
`// Road navigation (docs/specs/navigation/IMPLEMENTATION_PLAN.md)`.

- `W/Repositories/Interfaces/IRoadNetworkRepository.cs` + `W/Repositories/RoadNetworkRepository.cs`: tile get/create by
  `(world, x, z)`; tile graph read; nodes/edges by tile; nodes by world; edges by street; structures with their Location in a bbox (Structure is
  table-per-type over `domains`; `LocationId` lives on `Domain` — use the EF navigation, for labelling); domain
  Locations in a bbox (D12); `RunInTransactionAsync(work)` (R30 pattern, in-memory
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
       **Delete edges explicitly** before deleting nodes — don't rely on FK cascades: the EF InMemory provider used by the
       tests only cascades to tracked entities, so relying on cascades makes tests and MySQL behave differently.
    3. Upsert nodes: `existingId` present and belongs to this tile → update position/kind (unless `Locked` → keep
       position); otherwise insert. Delete this tile's `Detected` nodes not in the payload (cascades their edges).
       Keep `Manual` nodes.
    4. Upsert edges the same way; keep admin fields (`StreetId` when `StreetSource = Manual`, `Flags`,
       `CostMultiplier`) on matched edges; keep `Recorded` edges.
    5. Stitch edges (D7): delete every stitch edge touching this tile's `Boundary` nodes (whichever tile owns it),
       recreate them owned by this tile, and `Version++` every other tile that lost an owned stitch edge.
    6. Run `RoadStreetLabeler` for the tile's edges (+ 1-tile ring for continuation); write `StreetId`/`StreetSource`.
    7. `Version++`, `BuiltAt`, `Dirty = false`, counts, warnings (+ labeler conflicts).
    8. Recompute components for the world (`RoadComponents`), update changed `ComponentId`s only.
  - Profiles CRUD (validation: unique name, roles valid, material keys `^[A-Z0-9_]+$`, width min ≤ max, scope town ids
    exist and are Towns).
  - Surveys: create, list by world.
  - Tiles: list by world; mark dirty (sets `Dirty`, edges → `Stale`).
  - Seeds CRUD. Nodes: update (name/kind/lock), create anchor, merge (re-point the second node's edges to the first,
    drop self-loops/duplicates, delete the second; recompute components). Edges: create recorded (ends snapped to the
    nearest node within 3 blocks, else create `Anchor`s), update (street → `Manual`; with `propagate = true` the
    same label is applied along the road — `RoadStreetLabeler`'s continuation rule (< 35°, same class, same level),
    stopping at edges that already carry a different `Manual` street — and the response lists every edge changed;
    class override via profile id,
    cost, flags), delete.
  - Meta: profiles + street names + component summary for a world.
  - Seed locations (D12): domain Locations (Town/District/Structure/Gate with `LocationId`) whose Location is in the
    box and world.
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
| `api/road-network/seed-locations?world=&minX=&minZ=&maxX=&maxZ=` | GET (D12) | anonymous |
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
them in `GetByIdAsync`/`GetAllAsync` (one grouped query for all). **No street tests exist yet** — create
`Services/StreetServiceTests.cs` covering the existing behaviour first (create/update/get/search), then the counts.

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
- `Services/StreetServiceTests` (new, see 1.6) incl. counts.
- Stitch/ETag: rebuilding tile A bumps B's `Version` when B lost a stitch edge; B's graph never references a deleted
  node.
- Migration test (1.2).

**Acceptance:** `dotnet test` = baseline + new tests, no new failures; migration passes the four CI steps locally or in
CI; Swagger shows every route; a hand-made two-tile payload round-trips (PUT → GET graph → 304 on repeat).

---

### Phase 1 status — done 2026-09-27 (knk-web-api `claude/road-navigation` `55d5aaa`, `8553dec`, `c7df10e`, `77e0a29`; cut from `master` `ccc8c02`)

- **What was built** (all under `W/`):
  - `Enums/RoadEnums.cs` — `RoadClass`, `RoadMaterialRole`, `RoadNodeKind`, `RoadNodeSource`, `RoadEdgeSource`
    (`Detected | Recorded | Stitch`), `RoadEdgeStatus`, `RoadStreetSource`, `RoadSeedSource`, `[Flags] RoadEdgeFlags` (int).
  - `Models/Roads/{RoadProfile,RoadSurvey,RoadTile,RoadSeed,RoadNode,RoadEdge}.cs` — DESIGN §3 + D4 (`RoadTile.Version`),
    D5 (`RoadProfile.StatsJson`), D8 (`ScopeTownIdsJson`), D11 (`RoadEdge.RegionIdsJson`), `RoadEdge.World`;
    `RoadTile.Size = 512`, `RoadTile.TileCoordinate(int)`.
  - `Properties/KnKDbContext.cs` — `// Road navigation` block after the discovery block; tables/indexes/FKs exactly
    as 1.2 (plus `road_seeds.SurveyId → road_surveys` **SetNull**, decision 10).
  - Migration `Migrations/20260927190750_AddRoadNetwork.cs` (+ Designer, snapshot) with the `InsertData` bootstrap
    profile *Default road* (`seededAt` 2026-09-27 UTC). Passed the four fresh-DB steps **locally on MySQL 8.0.46**
    (update → `has-pending-model-changes` clean → update 0 → update) and the `Migrations (fresh DB)` workflow on
    every pushed commit that carries the migration (runs 108, 110, 111 green; run 107 = the models-only commit
    before the migration, red on "pending model changes" as expected).
  - `Json/JsonColumn.cs` (R29; `GameSettingsJson` delegates), `StaffPermissions.RoadManage = "knk.admin.road"` (R31).
  - `Dtos/RoadDtos.cs` — every DTO of 1.3, all `[JsonPropertyName("camelCase")]`, plus some not in the plan's list:
    `RoadTileUpsertResultDto` (the PUT graph response: tile + created/updated/deleted counts, stitch/labelled/
    unlabelled counts, `conflicts[]`, `deletedNodes[]`, `bumpedTileIds[]`), `RoadEdgeUpdateResultDto {edge,
    changedEdgeIds[]}`, `RoadNodeAnchorDto`, `RoadSeedCreateDto`, `RoadBreadcrumbPointDto {x,y,z,onRoad}`,
    `RoadStreetRefDto`, `RoadComponentDto`. Profile/survey `stats` are opaque JSON objects (`JsonElement?`).
  - `Mapping/RoadMappingProfile.cs` (read side), `Services/Roads/RoadJson.cs` (column ↔ DTO shapes, flag names).
  - `Repositories/Interfaces/IRoadNetworkRepository.cs` + `Repositories/RoadNetworkRepository.cs` — tracked-entity
    queries, `RunInTransactionAsync` (R30 pattern, in-memory fallback) + `LockTileAsync` (`SELECT … FOR UPDATE`),
    edge search with the 1.5 filters, `GetStreetEdgeStatsAsync` (one grouped query), structures/domain Locations
    in a box via the `Domain.Location` navigation.
  - `Services/Roads/RoadGeometry.cs`, `RoadComponents.cs` (union-find, id = smallest node id),
    `RoadStreetLabeler.cs` (votes 16 blocks / |Δy| ≤ 4 / weight 1/max(d, 0.5), ≥ 60 % majority, continuation < 35°
    same class same level to a fixed point, Manual untouched, ring edges as fixed context; plus `Propagate` for the
    edge update's "continue along the road").
  - `Services/Interfaces/IRoadNetworkService.cs` + `Services/RoadNetworkService.cs` — the 1.4 list. Upsert order:
    validate → nodes (match by `existingId`, else exact position; Locked keep position; Manual keep kind) → delete
    unmatched Detected nodes **and their edges explicitly** → edges (match by `existingId`, else node pair; admin
    fields kept) → delete unmatched Detected edges → stitch (D7) → labels (D6) → tile fields/Version/bumped
    neighbours → components. Everything inside one transaction.
  - Controllers: `RoadControllerBase` (400 `ValidationFailed` / 404 `NotFound` / 409 `Conflict`, `{error, message}`),
    `RoadTilesController`, `RoadNetworkController`, `RoadProfilesController`, `RoadSurveysController`,
    `RoadSeedsController`, `RoadNodesController`, `RoadEdgesController`, `StreetsController.GetStreetRoad`
    (`GET api/Streets/{id}/road`). Routes and auth exactly as the 1.5 table. Swagger lists all 17 road routes.
  - Street counts (1.6): `StreetDto.edgeCount/totalLength`, mapping `Ignore()`, `StreetService` takes
    `IRoadNetworkRepository` (constructor change; DI is convention-scanned, no other caller).
  - DI: `// Road navigation` block after the siege block in `ServiceCollectionExtensions` (R33).
- **Reuse:** R29 (extracted), R30 (pattern), R31, R32, R33 applied. Also reused: `ServiceAuthTestHelper` for the
  gate tests, `DiscoveryConfigurationServiceTests` style for the service tests, `AddDomainDiscoveryTests` style +
  `InsertData` precedent for the migration, `SiegeMatchRepository.RunLockedAsync` shape.
- **Tests:** `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` — before **1524 passed / 5 failed /
  42 skipped (1571)**, after **1627 passed / 5 failed / 42 skipped (1674)** → +103, no new failures. The 5 known
  failures, by name: `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
  `FormSubmissionProgressRepositoryTests.DeleteCompletedOlderThanAsync_DeletesStaleRootAndDescendantsInOrder`,
  `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`,
  `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2 (`Town.Name`, `Town.WgRegionId`). New test
  files: `Services/Roads/{RoadGeometryTests,RoadComponentsTests,RoadStreetLabelerTests}.cs`,
  `Services/RoadNetworkServiceTests.cs` (28 facts incl. every 1.7 item), `Services/StreetServiceTests.cs`,
  `Api/RoadControllersTests.cs` (ETag/304, error mapping, wire names, gates), `Migrations/AddRoadNetworkTests.cs`.
  **Acceptance run** against the API on a local MySQL (Development, `Security:PluginApiKey` set): two hand-made
  adjacent tile payloads → PUT 200 (second one reports `stitchEdges: 1`), GET graph 200 with `ETag: "1"`, repeat
  GET with `If-None-Match: "1"` → 304, `POST …/dirty` → edges `Stale` in `POST api/road-edges/search`
  `{"filters":{"stale":"true"}}`, anonymous PUT → 401, node outside the tile → 400 with the message.
- **Decisions to review** (defaults taken; all reversible):
  1. **Stitch edges live in the owning tile's graph** and may reference a node of the neighbour tile by id; the
     neighbour's `Version` is bumped only when it *loses* an owned stitch (D7 wording), not when the other tile
     gains one. The plugin must resolve cross-tile node ids from the other tile's download (Phase 2d/3).
  2. **Detected nodes that a Recorded edge touches are kept** on rebuild (otherwise the recording would vanish with
     its endpoint); Manual and Locked nodes are kept as the plan says.
  3. **Fallback matching:** a payload node without `existingId` on the exact position of an existing node of the
     tile matches it; a payload edge without `existingId` whose node pair already exists as a Detected edge of the
     tile matches it. Avoids unique-index violations when the builder misses a match; a pair held by a Recorded/
     Stitch edge or another tile's edge is a 400.
  4. **Inferred labels are recomputed from scratch** on every upsert (an Inferred label whose structures are gone
     is dropped); a vote conflict leaves the edge unlabelled and is appended to the tile warnings.
  5. **Mark dirty bumps `Version`** (the edges' `Stale` status is part of the graph download) and creates the tile
     row if unknown.
  6. **`propagate` writes `Manual`** on every edge it reaches (an admin's "continue along the road" must survive the
     next build); it stops at edges carrying a *different* Manual street and at side streets (> 35°).
  7. **Node edit locks the node** (`Locked = true`) unless the request says `"locked": false`; anchors and the
     Anchor ends of recorded edges are `Manual` + `Locked`.
  8. **Recorded edges belong to the tile of their first point**; ends snap to the nearest node within 3 blocks
     (any kind), else an Anchor is created there; length defaults to the polyline length.
  9. **`RoadSurvey.StartedByUserId` is nullable** (the plugin may omit `X-Acting-User-Id`), FK Restrict.
  10. `road_seeds.SurveyId` FK **SetNull** (the plan lists no rule for it).
  11. Edge update DTO distinguishes "leave" from "clear" with `clearStreet` / `clearProfile` flags (a nullable
      `streetId` alone can't).
  12. Meta `streets` lists only streets some edge of that world is labelled with (not every Street).
  13. Boundary validation: `Boundary` nodes must sit on the tile's border cells (x or z equal to the tile min/max);
      other kinds may sit anywhere in the tile. `id:<n>` node references must be in the same world.
  14. The labeler treats "same road class" as equal `RoadClass` of the edges' profiles (unmatched = null equals
      null only).
  15. Deleting a profile nulls `ProfileId` on its edges and surveys explicitly (SetNull parity for the InMemory
      provider).
- **Discrepancies found:**
  - Plan §0.4: `dot.net`, `builds.dotnet.microsoft.com` and `dotnetcli.azureedge.net` are blocked by the cloud
    proxy, but `apt-get install dotnet-sdk-8.0` (Ubuntu 24.04 archive, 8.0.131) and `apt-get install mysql-server`
    work — that is how the tests and the four migration steps ran here. `dotnet tool install dotnet-ef 9.0.10`
    works (api.nuget.org is reachable). Later links: same recipe.
  - Charter §9 / plan header: knk-web-api trunk had moved from `acaee99` to `ccc8c02` (lootboxes merge) when this
    link started; the branch is cut from `ccc8c02`. The clone's `origin/master` was stale until re-fetched — always
    `git fetch origin master` before cutting.
  - `dotnet run` ignores `ASPNETCORE_URLS` here (launchSettings wins): the API listens on `http://localhost:5294`.
  - `StreetsController` lives in namespace `KnKWebAPI.Controllers` (not `knkwebapi_v2.Controllers`); left as is.
- **Developer to-do:**
  - Dev DB: `dotnet ef database update` on `claude/road-navigation` adds the six `road_*` tables + the *Default road*
    profile row (id 1 on an empty table).
  - Set `Security:PluginApiKey` (the plugin's key) — every write route needs it or a JWT with `knk.admin.road`.
  - **Live checklist (Swagger, ~5 min):** (1) `GET api/road-profiles` shows *Default road*; (2) `PUT
    api/road-tiles/world/0/0/graph` with the payload below (header `X-API-Key`) → 200, `nodesCreated: 3`;
    (3) `GET api/road-tiles/world/0/0/graph` → 200 with `ETag: "1"`; repeat with `If-None-Match: "1"` → 304;
    (4) `PUT api/road-tiles/world/1/0/graph` with the second payload → `stitchEdges: 1`, and `GET
    api/road-network/meta?world=world` shows one component of 5 nodes; (5) `POST api/road-tiles/world/1/0/dirty` →
    `dirty: true`, then `POST api/road-edges/search` `{"filters":{"stale":"true"}}` lists that tile's edges;
    (6) `GET api/Streets/{id}` of any street shows `edgeCount`/`totalLength` (0 until labels exist).
    Payload 1: `{"builderVersion":1,"cellCount":10,"levelCount":1,"warnings":[],"nodes":[{"key":"b0","x":0,"y":64,
    "z":100,"kind":"Boundary"},{"key":"j","x":200,"y":64,"z":100,"kind":"Junction"},{"key":"b1","x":511,"y":64,
    "z":100,"kind":"Boundary"}],"edges":[{"fromKey":"b0","toKey":"j","geometry":[[0,64,100],[200,64,100]],
    "length":200,"avgWidth":3,"profileId":1,"gateDoorIds":[],"domainIds":[],"regionIds":[]},{"fromKey":"j",
    "toKey":"b1","geometry":[[200,64,100],[511,64,100]],"length":311,"avgWidth":3,"profileId":1,"gateDoorIds":[],
    "domainIds":[],"regionIds":[]}]}`. Payload 2: `{"builderVersion":1,"cellCount":5,"levelCount":1,"warnings":[],
    "nodes":[{"key":"b","x":512,"y":64,"z":100,"kind":"Boundary"},{"key":"e","x":700,"y":64,"z":100,
    "kind":"Endpoint"}],"edges":[{"fromKey":"b","toKey":"e","geometry":[[512,64,100],[700,64,100]],"length":188,
    "avgWidth":3,"profileId":1,"gateDoorIds":[],"domainIds":[],"regionIds":[]}]}`.
- **What later phases must wire** (contract, unchanged from the 1.5 table unless noted):
  - **Phase 2e (Java DTOs):** mirror `W/Dtos/RoadDtos.cs` one to one; names are the `[JsonPropertyName]`s. Enums
    are strings by name; `flags` is a string array (`Oneway`, `NoGps`, `Closed`); `geometry` is `int[][]`;
    `stats` (profile, survey) is an opaque JSON object (Jackson `JsonNode`/`Map`), send `null` to keep it on a
    profile PUT. `PUT …/graph` returns `RoadTileUpsertResultDto`, `PUT api/road-edges/{id}` returns
    `RoadEdgeUpdateResultDto`, `POST api/road-nodes/anchor` takes `RoadNodeAnchorDto`, `POST api/road-seeds` takes
    `RoadSeedCreateDto`. Errors are `{ "error": "ValidationFailed" | "NotFound" | "Conflict", "message" }`.
    R17 conditional GET: `ETag` is the quoted version (`"3"`); send it back verbatim in `If-None-Match`; weak
    tags (`W/"3"`) are accepted.
  - **Phase 3 (builder → PUT graph):** node `key`s are free strings (not starting with `id:`); `existingId` only for
    nodes of *this* tile (others = 400); `Boundary` nodes on the tile's border cells only; edges may be sent in
    either node order (the API normalises `FromNodeId < ToNodeId` and reverses geometry); geometry ends within 1.5
    blocks of their nodes; `length ≥` straight-line distance; the builder must **not** create cross-tile edges — the
    API stitches boundary nodes within Chebyshev 1 (x/z) and |Δy| ≤ 1 itself; a tile upsert deletes unmatched
    Detected nodes/edges of that tile only. Surveys: `POST api/road-surveys` with `X-Acting-User-Id`. Dirty:
    `POST api/road-tiles/{world}/{x}/{z}/dirty` (creates the tile if unknown).
  - **Phase 2d/3 (download):** a tile graph contains the tile's nodes and the edges it owns, including Stitch edges
    whose other node belongs to the neighbour tile — resolve node ids across downloaded tiles; edges with `status`
    `Stale` are still routable.
  - **Phase 5 (web app):** `POST api/road-edges/search` filters `world`, `tileId`, `streetId`, `unlabelled`,
    `stale` (strings, `"true"`), `sortBy` `id | length | streetId | tileId`; `PUT api/road-edges/{id}` with
    `propagate: true` returns every changed edge id; node edits lock the node unless `locked: false`.

## Phase 2 — knk-plugin core (Bukkit-free) and api-client

### 2a Shared extractions (one commit each, behaviour unchanged)

1. R1 `C/util/BlockKey` (+ tests: pack/unpack round-trip incl. y −64 and 319, neighbours).
2. R2 `C/util/Polygon2D` (+ tests: existing `GateFrameCalculator` tests still green; new closest-point tests).
3. R3 `GateManager.closedFootprint(int)` (+ test inside `GateManagerTest`, whose `closedGateWithOneBlockAt` helper is
   private).
4. R4 `GateStateListener` in `C/gates/` + `GateManager.addStateListener/removeStateListener/fireStateChanged`, fired
   at every GateManager mutation listed in R4 (+ test: fired once on open start, close start, completion,
   `forceGateState`, `cacheGate`; existing one-shot callback still works). The paper-side `fireStateChanged` calls
   (HealthSystem, GateAnimationTask jam, GateCommand) are Phase 3 task 3.2.
5. R6 `C/regions/DomainAccessEvaluator`. **No `SimpleRegionTransitionService` tests exist** — first write
   characterisation tests for the current entry/exit denials and messages (commit), then extract and delegate (commit)
   with those tests unchanged and green, then evaluator unit tests.
6. **Guard test** `knk-core/src/test/java/.../core/ArchitectureGuardTest.java`: scans `src/main/java/.../core/{roads,
   navigation,util/BlockKey.java,util/Polygon2D.java,regions/DomainAccessEvaluator.java}` sources and fails on any
   `import org.bukkit`. (No ArchUnit on the classpath; a file scan is enough.)

### Phase 2a status — done 2026-09-27 (knk-plugin `claude/road-navigation` `35252c7`, `4447afa`, `f5a8572`, `f5c420d`, `1ff918a`, `af38414`, `db962a4`; cut from `main` `eb1d68c`)

- **What was built** (all in knk-core, `C/`; one commit per item, public names exactly as §2 spells them):
  - `util/BlockKey.java` (R1, `35252c7`): `pack(int x, int y, int z)` (the 26/12/26-bit layout `GateSpatialIndex.packCell`
    always used), `x(long key)`, `y(long key)`, `z(long key)` (sign-extending, so negative x/z and y −64…319 round-trip;
    y covers −2048…2047), `neighbour(long key, int dx, int dy, int dz)`. `GateSpatialIndex.packCell(int,int,int)`
    delegates; a test pins the two bit-identical. `GateBlockScanTaskHandler.packCoordinate` untouched.
  - `util/Polygon2D.java` (R2, `4447afa`): `contains(double u, double v, List<double[]> polygon)` = the moved even-odd
    test with the inclusive edge (`Polygon2D.EPSILON = 0.001`, public), `closestPointOnBoundary(u, v, polygon)` →
    `double[]{u, v}` (null for a null/empty polygon; one vertex → that vertex; two → a segment),
    `distanceToBoundary(u, v, polygon)` → unsigned distance (0 on the edge, `Double.POSITIVE_INFINITY` for null/empty).
    `GateFrameCalculator.pointInPolygon` delegates (its private `isOnSegment` went with it; `BOUNDS_EPSILON` stays
    for the other bounds checks).
  - `gates/GateManager.closedFootprint(int gateId)` → `List<Vector>` (R3, `f5a8572`): frame-0 positions of the door's
    blocks regardless of current state; empty list for an unknown gate. The private `doorBlockPositions(gate, frame)`
    stays for `cacheGate`. (Returns Bukkit `Vector` like the rest of `C/gates` — the builder converts to `BlockKey`.)
  - `gates/GateStateListener` (`void gateStateChanged(int gateId)`) + `GateManager.addStateListener(l)` /
    `removeStateListener(l)` / `fireStateChanged(int gateId)` (R4, `f5c420d`). `CopyOnWriteArrayList`; a listener added
    twice is registered once; a listener that throws is logged and skipped. Fired inside `GateManager` after the
    mutation in `openGate` (OPENING), `closeGate` (CLOSING), `notifyAnimationCompleted` (after the one-shot callback,
    which is unchanged), `forceGateState`, `cacheGate` (initial load and reload alike). Not fired when open/close is
    refused or the id is unknown. Fires on the mutating thread (async loader threads for `cacheGate`).
  - `regions/DomainAccessEvaluator` (R6, `1ff918a` tests first, `af38414` extraction): `Optional<Denial> entry(DomainSnapshot)`,
    `Optional<Denial> exit(DomainSnapshot)`, `record Denial(RegionTransitionType type, DomainSnapshot domain, String
    message)`; messages unchanged ("You are not allowed to enter X." / "You are not allowed to leave X."), `null` flag =
    not restricted. `SimpleRegionTransitionService` holds `accessEvaluator = new DomainAccessEvaluator()` and
    `checkEntryDenials`/`checkExitDenials` delegate. `previewAccess` (KNG-17 branch) not touched.
  - `knk-core/src/test/java/.../core/ArchitectureGuardTest.java` (`db962a4`): scans `C/roads/`, `C/navigation/`,
    `C/domain/roads/` (recursively, skipped while absent) and `util/BlockKey.java`, `util/Polygon2D.java`,
    `regions/DomainAccessEvaluator.java` (must exist) for `import org.bukkit` and for `org.bukkit.` in non-comment
    lines. Verified negative: a `roads/Tmp.java` with `import org.bukkit.util.Vector` fails it with the file:line.
  - Tests added: `BlockKeyTest` (9), `Polygon2DTest` (16), `GateManagerTest` +13 (4 for R3, 9 for R4 incl. "one-shot
    callback still fires once and is removed"), `SimpleRegionTransitionServiceTest` (15 characterisation tests: every
    denial, every message wording, Town > District > Structure priority, the entered-domains callback),
    `DomainAccessEvaluatorTest` (6), `ArchitectureGuardTest` (2). Existing gate tests untouched.
- **Reuse:** §2 rows R1, R2, R3, R4, R6 applied as written. Nothing else extracted or duplicated.
- **Tests:** knk-core **1024 → 1085** (0 failures, 0 skipped; baseline recorded on `eb1d68c` before any change).
  **Not compiled with Gradle:** `./gradlew :knk-core:test` fails at `Could not resolve io.papermc.paper:paper-api`
  (the proxy answers 403 to CONNECT for `repo.papermc.io`, `maven.enginehub.org` and `hub.spigotmc.org` — same as
  link 1 saw, despite charter §9). Both counts come from the plan §0.4 scratch build: a throwaway Gradle project in
  the session scratchpad whose `sourceSets` point at the real `knk-core/src/{main,test}/java` plus a stub
  `org.bukkit.util.Vector` (only Bukkit type knk-core uses; floor block accessors, fuzzy `equals`, Rodrigues
  `rotateAroundAxis` copied from Paper's source), Maven Central only, `workingDir = knk-core`. All 9 Bukkit-importing
  main files compile against the stub, so the whole suite runs, not a subset. knk-paper and knk-api-client: not built
  (not touched). Note for cloud sessions: Maven Central answers **429** to Gradle's parallel downloads through the
  proxy — `org.gradle.workers.max=2` plus `systemProp.org.gradle.internal.repository.max.tentatives=12` /
  `initial.backoff=2000` in `~/.gradle/gradle.properties` fixed it; `services.gradle.org` and `plugins.gradle.org` are fine.
- **Decisions to review** (each cheap to change):
  1. `DomainAccessEvaluator.entry/exit` are **instance** methods (the plan doesn't say); a bypass predicate / future
     entry conditions can then be injected through a constructor without touching callers. The service creates its own
     instance (no constructor change → nothing for the KNG-17 merge to conflict with in the constructors).
  2. `Denial` carries the `DomainSnapshot` besides type and message — the router needs the domain for "You may not
     enter X. Guiding you to its edge."
  3. `checkExitDenials` had three identical passes over the left domains (commented town/district/structure priority
     but never filtered by type); they collapsed into one loop. Same result (first denial in set order), fewer changed
     lines for the KNG-17 merge.
  4. `Polygon2D.distanceToBoundary` is unsigned; callers combine with `contains` when the side matters.
  5. `GateStateListener` is fired synchronously on whichever thread mutates (main thread for animation/commands, loader
     threads for `cacheGate`); listeners must be thread-safe or hop to the main thread (`MenuService.mainThreadExecutor`,
     R12). `fireStateChanged` catches `RuntimeException` per listener so a bad listener can't stall `GateAnimationTask`.
  6. `cacheGate` fires for every (re)cache, including the initial startup load — one event per gate to any listener
     registered before the load. Navigation registers after startup; if that ever matters, gate it on `getGate(id) != null`.
  7. The guard also covers `C/domain/roads/` (DESIGN §4 puts the road records there) and code-line `org.bukkit.`
     references, not only imports; comment lines are exempt so Javadoc may say "Bukkit-free".
- **Discrepancies found:** none in the plan's code references (all five resolved on `eb1d68c`; line numbers drifted by a
  few lines only). Charter §9 / plan §0.4: the developer allowed the two Maven hosts, but this environment's network
  policy still denies them (proxy 403 on CONNECT) — the allow-list evidently isn't applied to this environment; the
  developer can add `repo.papermc.io` and `maven.enginehub.org` under the environment's network settings. The plugin
  `CLAUDE.md` lines "no menus package" / "no polling" are stale (charter §2.1 already says so; not edited).
- **Developer to-do:**
  1. Local: `./gradlew :knk-core:test` (expect 1085 green), then `./gradlew build -x deployToDevServer` — knk-paper
     compiles against the changed `GateManager`/`GateSpatialIndex`/`GateFrameCalculator`; only public API was added,
     so no paper changes are expected. If knk-paper's test count differs from your last run, say so in the next link's
     handoff.
  2. Live (~3 min, dev server, any gate): `/knk gate open|close|force` a door — animates as before; walk into a
     region whose domain has `allowEntry=false` — still "You are not allowed to enter X."; `allowExit=false` — still
     "You are not allowed to leave X.". Nothing else is observable — Phase 2a is a pure refactor.
  3. **KNG-17 (teleport) merger:** `SimpleRegionTransitionService.previewAccess` must delegate to
     `accessEvaluator.entry/exit`, and its `knk.region.bypass` predicate becomes the evaluator's bypass input (add a
     constructor parameter on `DomainAccessEvaluator` then). Expect a small conflict in `SimpleRegionTransitionService`
     imports/fields (this phase added one import and one field, and rewrote the two private check methods).
- **What later phases must wire:**
  - 2c (builder): `BlockKey.pack/x/y/z/neighbour` for every cell map; `GateManager.closedFootprint(gateId)` (via the
    `SurfaceGrid` port's gate lookup, filled in Phase 3 from `gateManager.getAllGates()`) to tag gate cells (D9).
  - 2d (router): `Polygon2D.contains/closestPointOnBoundary/distanceToBoundary` in `RegionClosestPoint`;
    `DomainAccessEvaluator.entry/exit` inside `AccessPolicy` (one evaluator instance passed in, so the paper side can
    later hand it the bypass); `GateManager.addStateListener(GateStateListener)` for live re-route (D13's 2-second
    re-check stays).
  - 3 (task 3.2): call `gateManager.fireStateChanged(gateId)` after `HealthSystem.destroyGate`/`respawnGate`, the jam
    in `GateAnimationTask`, and `GateCommand`'s destroyed/active toggles. Siege override setters: not edited (D13).
- **Scratch-build recipe (cloud, knk-core only)** — `build.gradle.kts` in a scratch dir: `plugins { java }`,
  `repositories { mavenCentral() }`, Java 21 toolchain, `sourceSets.main.java.setSrcDirs(listOf("<repo>/knk-core/src/main/java",
  "stub"))`, `sourceSets.test.java.setSrcDirs(listOf("<repo>/knk-core/src/test/java"))`, the same jackson 2.15.2 /
  gson 2.10.1 / junit-bom 5.10.2 dependencies as `knk-core/build.gradle.kts`, `tasks.test { useJUnitPlatform();
  workingDir = file("<repo>/knk-core") }`; `stub/org/bukkit/util/Vector.java` = a plain copy of Paper's `Vector` minus
  the Location/World/JOML/serialisation methods; copy the repo's `gradlew` + `gradle/` wrapper; `./gradlew test
  --offline --max-workers=2` after the first (online) run. Counts from `build/test-results/test/*.xml`.

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
- Tests: synthetic cross-sections for (a) stone-brick road with andesite kerbs on grass → Surface/Edge/terrain split;
  (b) gravel path 1-wide in a forest; (c) cobblestone kerb next to cobblestone house floor → ambiguous; (d) merging two
  surveys equals learning on the concatenation.

### Phase 2b status — done 2026-09-27 (knk-plugin `claude/road-navigation` `e7a5cb3`, `92375e5`; on top of 2a's `db962a4`; trunk `main` still `eb1d68c`)

- **What was built** (all in knk-core, Bukkit-free; names exactly as §2b spells them):
  - `roads/survey/SurveySample.java` (`e7a5cb3`): record `(int x, int y, int z, boolean onGround, String floor, String
    overlay, List<String> offsets)`; constants `MIN_OFFSET = -7`, `MAX_OFFSET = 7`, `WIDTH = 15`, `CENTRE_INDEX = 7`;
    `offsets` has exactly 15 entries (index `i` = offset `i - 7`), `null` = no standable cell (wall, drop); `floor`
    must equal the centre cell (validated); `SurveySample.of(x, y, z, onGround, overlay, offsets)` derives the floor
    from the centre cell; `materialAt(offset)`, `hasOverlay()`. Materials are plain names (`Material.name()` on the
    paper side).
  - `roads/survey/ProposedProfile.java` (`e7a5cb3`): record `(List<Material> materials, int widthMin, int widthMax,
    int sampleCount)` with nested record `Material(String material, RoadMaterialRole role, boolean ambiguous, double
    centreShare, double edgeShare, int samples)` — the `RoadProfileDto`/`RoadMaterialDto` names; `material(name)`,
    `roleOf(name)`, `withRole(role)`. Name, class, cost, scope are not learned and not in it.
  - `domain/roads/RoadMaterialRole.java` (`e7a5cb3`): `SURFACE`, `EDGE`, `ACCENT`, `OVERLAY`; `apiName()` →
    `Surface`/`Edge`/`Accent`/`Overlay` (the web-api enum names), `fromApiName(String)`. Shared with 2c
    (`ProfileSet`) and 2e (DTO mapping); the guard test already covers `domain/roads`.
  - `roads/survey/SurveyStats.java` (`92375e5`): immutable; `of(Collection<SurveySample>)`, `empty()`,
    `merge(SurveyStats)` (returns a new instance), `toJson()`/`fromJson(String)`; accessors `samples()`, `runs()`,
    `centreCells()`/`midCells()`/`outerCells()`, `materials()` (sorted map → `MaterialCounts(centre, mid, outer,
    runEnd, inRun, outsideRun, overlay)`), `counts(material)`, `widths()` (width → samples), `runEndSlots()`;
    `Bucket.of(offset)` (centre |o| ≤ 1, mid 2-5, outer 6-7).
  - `roads/survey/ProfileLearner.java` (`92375e5`): constants at the top — `ROAD_LIKENESS_MIN = 0.6`,
    `SURFACE_MIN_CENTRE_SHARE = 0.15`, `EDGE_RUN_END_FACTOR = 2.0`, `ACCENT_MAX_PRESENCE = 0.05`,
    `AMBIGUOUS_MIN_OUTSIDE_SHARE = 0.10`, `DROP_BELOW_PRESENCE = 0.01`, `WIDTH_MIN_PERCENTILE = 5`,
    `WIDTH_MAX_PERCENTILE = 95`, `MIN_WIDTH = 1`; `learn(SurveyStats) → ProposedProfile`; static
    `roadLikeness(MaterialCounts)`, `isRoadLike(MaterialCounts)` (also used by `SurveyStats.of` for the runs).
  - Tests (`knk-core/src/test/.../roads/survey/`): `SurveySampleTest` (7), `ProposedProfileTest` (3),
    `SurveyStatsTest` (17), `ProfileLearnerTest` (16: plan scenarios a-d, overlays, noise/accent thresholds,
    percentiles, walls, plaza limit, thresholds pinned), `domain/roads/RoadMaterialRoleTest` (2); helper
    `CrossSections` builds synthetic walks (road described in absolute lateral positions, walker wandering across it).
- **`StatsJson` v1** (the shape of `RoadProfile.StatsJson` and `RoadSurvey.StatsJson`, plan D5; flat, string material
  names, integer counts):
  `{"version":1,"samples":120,"runs":118,"cells":{"centre":360,"mid":940,"outer":470},"materials":{"STONE_BRICKS":
  {"centre":300,"mid":400,"outer":0,"runEnd":10,"inRun":118,"outsideRun":0,"overlay":0},…},"widths":{"4":8,"5":110}}`.
  `{}`, null and blank read as `SurveyStats.empty()` (the bootstrap *Default road* has `{}`); unknown keys are
  ignored, missing sections are zero; a missing/other `version` or a negative count throws `IllegalArgumentException`.
  Semantics: `centre/mid/outer` = non-null cross-section cells of that material per |offset| bucket; `runEnd` = times
  it was the outermost cell of a run (1-wide run: one end); `inRun` = samples whose run contained it; `outsideRun` =
  samples in which it appeared in the outer bucket outside the run; `overlay` = samples it lay on the floor in;
  `runs` = samples with a run; `widths` = run length → samples.
- **Reuse:** nothing in §2 applies to 2b (pure maths). Jackson (already a knk-core dependency) for the JSON; no new
  dependency. Nothing duplicated.
- **Tests:** knk-core **1085 → 1130** (0 failures, 0 skipped; 45 new). **Not compiled with Gradle:**
  `./gradlew :knk-core:test` still fails at `Could not resolve io.papermc.paper:paper-api` (403 from the proxy for
  `repo.papermc.io`; `maven.enginehub.org` also 000). Both counts from the plan §0.4 scratch build (recipe in the
  Phase 2a status; the `Vector` stub was rewritten from the Bukkit API, all 10 `org.bukkit`-importing main files
  compile against it). `ArchitectureGuardTest` passes with the new `roads/survey` and `domain/roads` sources.
  knk-paper, knk-api-client: not built, not touched.
- **Decisions to review** (each cheap to change; the admin reviews every proposal anyway — Phase 3 chat, Phase 5 editor):
  1. **Two-pass statistics.** A run needs road-likeness, which needs the whole survey's bucket counts, so
     `SurveyStats.of(samples)` counts buckets and overlays first and then classifies runs with *that batch's*
     road-likeness. `merge` sums everything. `merge(of(A), of(B)) == of(A ++ B)` exactly when both batches classify
     the materials alike (true for surveys of the same kind of road; scenario d). Phase 3 therefore builds a survey's
     stats once at stop (`SurveyStats.of(allSamples)`), not incrementally; for the live action bar re-run `of` over
     the samples so far (15 × N operations — trivial).
  2. **Mid-only materials are road-like.** `r = centre/(centre+outer)`; when both are 0 (seen only at |offset| 2-5)
     `r = 1`: a kerb the admin never stepped next to would otherwise be undefined and stop the run before the kerb,
     so it could never become an Edge. Terrain always shows up in the outer bucket too. Noise from this rule is
     dropped by the 1 % rule or never joins a run (test: podzol patch in scenario b).
  3. **Role order** for each road-like material with presence ≥ 1 %: presence &lt; 5 % → Accent; else run-end share
     ≥ 2 × centre share (and &gt; 0) → Edge; else centre share ≥ 15 % → Surface; else Accent (the residual the plan
     doesn't name, e.g. a 10 % patch material). Edge is tested before Surface so a kerb the admin often walked next
     to (centre share 20-30 % on a 3-wide road) is still an Edge, while a 1-wide path's only material (run-end share
     100 % = centre share 100 %) is a Surface. *Presence* = share of runs containing the material; *centre share* =
     the material's centre cells over the centre cells of all road-like materials (so terrain at ±1 next to a 1-wide
     path doesn't dilute it); *edge share* = its run ends over all run ends.
  4. **Ambiguous** = seen in the outer bucket outside the run in ≥ 10 % of all samples. A same-material courtyard
     *contiguous* with the kerb is swallowed by the run (it widens the road instead); only one separated by a
     non-road cell (grass strip, wall) counts as evidence — DESIGN §5.3 says the cross-section stops at walls anyway.
  5. **Sensitivity of the plan's formula** (not changed, flagged): a kerb material that also floors buildings seen at
     ±6-7 along more than ~15-20 % of the walk drops below `r ≥ 0.6` and is left out of the proposal (the admin adds
     it as Edge/ambiguous by hand); a road ≥ ~13 wide or a plaza surveyed *on its own* puts its surface in the outer
     bucket in every sample (`r = 3/7`) and learns nothing — plazas are learned from the streets leading into them
     (tests `aSurveyOfOnlyAPlazaLearnsNoMaterials`, `aStreetWideningIntoAPlaza…`). Roads up to ~11 wide are fine.
  6. **Overlay vs floor name collision:** a name seen both as floor and as overlay keeps the floor role when its run
     presence ≥ its overlay share, else it is proposed as Overlay. Overlays below 1 % of samples are dropped.
  7. **Widths:** nearest-rank percentiles of the width histogram; `15` means "at least the whole cross-section"; a
     survey without any run (or empty stats) proposes `1..1` and no materials (the API's upsert defaults are `1..7`;
     Phase 3 may prefer those for an empty proposal).
  8. **`onGround` is carried, not filtered:** `SurveyStats` counts every sample; Phase 3 only samples on the ground
     (DESIGN §5.3), the flag exists for the breadcrumb/coverage side.
  9. **`SurveySample` enforces `floor == offsets[7]`** (`IllegalArgumentException` otherwise); `SurveySample.of` avoids
     the duplication. The list is copied and unmodifiable.
  10. **`SurveyStats.fromJson` refuses other versions** instead of silently reading an empty profile; Phase 2e/3 should
      let that surface as an error (a newer plugin wrote the profile) rather than overwrite the stats.
  11. **`RoadMaterialRole` lives in `C/domain/roads/`** (DESIGN §4's home for road records) rather than in the survey
      package, so 2c's `ProfileSet` and 2e's DTO mapping share one enum; `ProposedProfile` mirrors the DTO field names
      but is not the DTO (2e writes those).
  12. **`SurveyStats.merge` returns a new instance** (both inputs unchanged); `equals`/`hashCode` are value-based so
      scenario (d) is an `assertEquals`.
- **Discrepancies found:** none in the plan text for 2b. Cloud network unchanged from links 1-2 (`repo.papermc.io`,
  `maven.enginehub.org` denied despite charter §9). KNG-17 (`core/teleport/WarpTargets`) is still not on `main`
  (`eb1d68c`) — Phase 4 still waits.
- **Developer to-do:**
  1. Local: `./gradlew :knk-core:test` (expect 1130 green), then `./gradlew build -x deployToDevServer` — only new
     classes were added, nothing in knk-paper references them yet, so no compile impact is expected.
  2. Live: nothing observable — 2b is pure maths; the `/knk road survey` command that feeds it is Phase 3. If you
     have a minute: glance at the `StatsJson` v1 shape above and say whether the flat per-material object suits the
     web app (Phase 5 treats it as opaque unless told otherwise).
- **What later phases must wire:**
  - **2c (builder):** `ProfileSet` maps material → `(RoadMaterialRole, ambiguous, profile ids)` using
    `C/domain/roads/RoadMaterialRole`; a profile's `widthMax` from the learner is the 95th-percentile run width
    (`15` = at least the cross-section) — plaza collapse uses `widthMax/2` of the matched profile as the plan says.
    `ProfileMatcher` compares floor-material histograms with the profile's `centreShare`s (Surface/Edge/Accent
    only; Overlay materials are not floors).
  - **2e (api-client):** `RoadMaterialDto.role` ↔ `RoadMaterialRole.apiName()` / `fromApiName()`; the opaque
    `stats` of profiles and surveys ↔ `SurveyStats.toJson()` / `fromJson()` (for a Jackson `JsonNode`:
    `mapper.readTree(stats.toJson())`; from the API: `SurveyStats.fromJson(node.toString())`, `{}` → empty).
    `ProposedProfile` → `RoadProfileUpsertDto`: `materials[*] = {material, role.apiName(), ambiguous, centreShare,
    edgeShare, samples}`, `widthMin`, `widthMax`, `sampleCount`, `stats` = the merged stats' JSON; `name`,
    `roadClass`, `costMultiplier`, `enabled`, `scopeTownIds` come from the existing profile or the admin.
  - **3 (survey session, `/knk road survey`):** build each sample with `SurveySample.of(x, y, z, onGround,
    overlayNameOrNull, offsets)` — 15 `Material.name()` strings for lateral offsets −7…+7 (perpendicular to the
    walking direction, floor through overlays at the standable height nearest the centre's, `null` where there is
    none / a wall stops the scan), overlay = the thin block on the centre floor. On stop:
    `SurveyStats survey = SurveyStats.of(samples)`; `SurveyStats merged = SurveyStats.fromJson(profile.stats)
    .merge(survey)`; `ProposedProfile p = new ProfileLearner().learn(merged)`; review; PUT the profile with `stats =
    merged.toJson()` and `sampleCount = p.sampleCount()`; `POST api/road-surveys` with `stats = survey.toJson()`,
    `sampleCount = survey.samples()`. "Learn a new profile" = `learn(survey)` with `stats = survey.toJson()`. The
    action bar's "top materials, estimated width" = `learn(SurveyStats.of(samplesSoFar))` every few seconds.
  - **5 (web app):** stats stay opaque; if a page ever shows them, the v1 shape above is the contract.

### 2c Builder — `C/roads/build/`

Ports (Bukkit-free):

```java
public interface SurfaceGrid {                      // R22: identical signatures/semantics to teleport's BlockProbe
    boolean isPassable(int x, int y, int z);        // PassabilityRules; gate-door cells count as passable (see GateCells)
    boolean isSolid(int x, int y, int z);
    boolean isHazard(int x, int y, int z);          // same hazard set as teleport's SafeLocationFinder
    int minY();
    int maxY();                                     // exclusive, like BlockProbe
    String floorMaterial(int x, int y, int z);      // Material name, "looking through" overlays
    boolean isStairOrSlab(int x, int y, int z);
}
public interface GateCells { OptionalInt doorAt(int x, int y, int z); }   // closed footprints (R3), prebuilt map
```

Classes (DESIGN §5 section in brackets):
- `PassabilityRules` — one pure definition of "passable" over material names (non-collidable materials + the overlay
  set: carpets, snow layer, pressure plates, rails, leaf litter, petals). `ChunkSnapshot` has no `isPassable`, and
  `Block#isPassable` (used by `SiegeBukkit`/`BukkitBlockProbe`) is not available off-thread, so the build uses this
  table; unit-test it against a list of materials. The paper side feeds it from `Material` (verify
  `Material#isCollidable()` exists on 1.21.10; otherwise use a curated set) and notes the difference from
  `Block#isPassable` in the status block.
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

### Phase 2c status — done 2026-09-27 (knk-plugin `claude/road-navigation` `2266921`, `cb8a7fd`, `6f870ff`, `96d40d6`, `23f9afa`, `4808d1b`, `c2ca1e3`; on top of 2b's `92375e5`; trunk `main` still `eb1d68c`)

- **What was built** (all in knk-core `C/roads/build/` unless noted; Bukkit-free, pure, no I/O or threads):
  - **Ports** — `SurfaceGrid` (teleport's five `BlockProbe` methods verbatim, `maxY` exclusive, plus
    `floorMaterial(x,y,z)` looking through overlays and `isStairOrSlab`), `GateCells` (`OptionalInt doorAt(x,y,z)`,
    `GateCells.NONE`), `ScopeLookup` (`OptionalInt townAt(x,z)`, `ScopeLookup.NONE`) for profile town scopes (D8).
  - `PassabilityRules` — one table over material names: overlay (DESIGN §4 `overlay-materials` incl. `*_CARPET`
    patterns, `PassabilityRules.overlayPredicate(patterns)`), passable = non-collidable or overlay, solid = its
    exact complement, hazard = teleport's `SafeLocationFinder.HAZARD_MATERIALS` verbatim (11 names), static
    `isStairOrSlab(name)`. `PassabilityRules.of(collidable, overlayPatterns)` takes the paper side's
    `Material#isCollidable()`; `defaults()` uses a curated non-collidable list (tests, fallback).
  - `ProfileSet` (+ nested `Profile(id, name, enabled, widthMin, widthMax, scopeTownIds, materials)` reusing
    `ProposedProfile.Material` and `RoadMaterialRole` from 2b) — material → `isRoadMaterial`/`isAmbiguous`/
    `info(role, ambiguous, profileIds)`/`maxWidthMax` per column; Overlay materials are never floors; a material
    is ambiguous only when every listing profile says so; scoped profiles apply only where `townAt` is in scope.
  - `BuildParameters` record (DESIGN §4 defaults: tile 512, margin 32, cap 250 000, cluster radius 3, min spur 4,
    ambiguous reach 3, RDP ε 0.75, seed snap radius 8, node match 3.0, edge match 2.0) with `withTile/withMaxCells/
    withAmbiguousReach/withGraphRules`.
  - `SpanGrid` [§5.2] — pure view over `SurfaceGrid`+`ProfileSet`+`GateCells`: `isSpan(x,y,z)`, allocation-free
    `neighbourDy(key, dir)` (−1/0/+1 or `NO_LINK`), `neighbour(key, dir) → OptionalLong`, `gateDoor(key)`,
    `isAmbiguous(key)`; directions `N..NW` clockwise (`DX`/`DZ`, `opposite`, `isDiagonal`).
  - `MaskBuilder` [§5.1, §5.4] (+ `Seed`, `Region` with `Region.tile(tx, tz, size)`/`grow(margin)`, `Result`) and
    `RoadMask` (dense, sorted keys + 8-neighbour table restricted to the mask, gate tags, floors, `levelCount`,
    `subset(keep)`), `BuildWarning(message, x, y, z)` with `text()`.
  - `DistanceTransform` [§5.5] — `compute(mask) → int[]` (border spans 1), `width(dt) = 2·dt − 1`, `halfWidth`.
  - `Thinning` [§5.5] — Zhang-Suen + corner-end guard + real-link connectivity check + Holt's staircase pass;
    `degree(mask, skeleton, i)`, package-private `linked`, `removeStaircaseCorners`, `neighboursStayConnected`.
  - `SkeletonGraph` [§5.6, D7] (+ `Anchor`, `Node`, `Chain`, `Result`) — plaza collapse, junction clustering,
    node-less loop seeding, anchors, chain tracing, endpoint extension, spur pruning with dissolve, loop/parallel
    splitting, tile-border cut; warnings `WARN_ANCHOR_OFF_ROAD`, `WARN_ANCHOR_DUPLICATE`.
  - `ProfileMatcher` — `histogram(mask, dt, chain)`, `match(mask, dt, chain) → OptionalInt`, static `cosine`.
  - `Rdp` — `simplify(points, ε)` (iterative, 3D, keeps the input arrays), `distanceToSegment`, `length`.
  - `NodeMatcher` [§5.7] (+ `PreviousNode`, `PreviousEdge`, `PreviousGraph` with `EMPTY`, `Candidate`) —
    `matchNodes → int[]` (`UNMATCHED = -1`), `matchEdge → OptionalInt`, static `polylineDistance`.
  - `TileBuilder` (`BUILDER_VERSION = 1`, `TileRequest(world, tileX, tileZ, parameters, seeds, profiles, gateCells,
    anchors, previousGraph)` with `tile()`/`region()`, `build(request, grid) → TileBuildResult`) and
    `TileBuildResult(builderVersion, cellCount, levelCount, nodes, edges, warnings)` with `Node(key, existingId, x,
    y, z, kind)`, `Edge(existingId, fromKey, toKey, geometry, length, avgWidth, profileId, gateDoorIds, domainIds,
    regionIds)` — the `RoadTileGraphUpsertDto`/`RoadTileGraphNodeDto`/`RoadTileGraphEdgeDto` field names read from
    `W/Dtos/RoadDtos.cs` on `claude/road-navigation`; `warningTexts()`, `node(key)`, `nodes(kind)`, `edgesOf(key)`.
  - `C/domain/roads/RoadNodeKind` (`JUNCTION/ENDPOINT/BOUNDARY/ANCHOR`, `apiName()`/`fromApiName()`).
  - **Test fixture** `knk-core/src/test/.../roads/build/GridFixture.java` (in the `build` test package, not
    `roads/`, for package-private access): ASCII layers (`G S a c / _ # X g L ~ s *`), `block/column/clear`,
    `gate(doorId, x, floorY, z, height)`, `gateCell`, the two default profiles (`townRoad()` width 3-5 with
    andesite/cobblestone kerbs, `gravelPath()` width 1-3), `spanGrid()`. Test-only `ThinningTest.render` draws a
    layer's mask/skeleton, used in every failure message.
  - `.gitignore`: `!**/src/**/build/` — the repo's `**/build/` (Gradle output) also hid the `core/roads/build`
    Java package; the first push (`2266921`) therefore carried only `RoadNodeKind`, `cb8a7fd` added the rest.
- **Reuse:** R1 (`BlockKey` for every key), R22 (`SurfaceGrid` = `BlockProbe` signatures; hazard list copied
  verbatim), R28 (`SiegeFloor.floorY` for seed → span in `MaskBuilder.snapSeed`), 2b's `RoadMaterialRole` and
  `ProposedProfile.Material` (no second role/material record), `RoadNodeKind` added next to `RoadMaterialRole` for
  2e/2d. Nothing in §2 duplicated; no new dependency.
- **Tests:** knk-core **1130 → 1280** (0 failures, 0 skipped; 150 new): `PassabilityRulesTest` 11, `ProfileSetTest`
  10, `BuildParametersTest` 3, `RoadNodeKindTest` 2, `SpanGridTest` 17, `RoadMaskTest` 7, `DistanceTransformTest` 6,
  `MaskBuilderTest` 17, `ThinningTest` 11, `RdpTest` 8, `ProfileMatcherTest` 8, `SkeletonGraphTest` 19,
  `NodeMatcherTest` 7, `TileBuilderTest` 24 = the plan's golden list, each asserting node kinds/count, edge count,
  lengths ±1 (mostly exact), no stray spurs, plus the Phase 1 contract (geometry ends on its nodes, length ≥ chord,
  unique pairs, nodes inside the tile, Boundary nodes on border cells, empty `domainIds`/`regionIds`).
  **Not compiled with Gradle:** `./gradlew :knk-core:test` cannot resolve `paper-api` here (proxy 403 on
  `repo.papermc.io`; `maven.enginehub.org` 000 — same as links 1-3); counts from the plan §0.4 scratch build (2a's
  recipe, `Vector` stub rewritten from the Bukkit API). `ArchitectureGuardTest` green with the new package.
  knk-paper and knk-api-client: not built, not touched.
- **Decisions to review** (numbered; defaults taken, all reversible):
  1. **Coordinates:** a span, a node and every geometry point are the **floor block** `(x, y, z)`; a player standing
     there has feet at `y + 1`. Phase 3 converts a player's feet block to `y − 1` (seeds tolerate feet or floor y,
     anchors do not — `/knk road node anchor` must store floor y); Phase 2d's snapper compares node/geometry y with
     the player's feet y − 1 (or adds 1 to the geometry).
  2. **Span rule:** floor `isSolid` (collidable and not an overlay) and a road material of an applicable profile,
     not a hazard, `y ≥ minY`, `y + 2 < maxY`, two passable hazard-free blocks above; a block in a gate door's
     closed footprint counts as passable inside `SpanGrid` (the `SurfaceGrid` need not fold gates in); a hazard in
     the floor or the headroom (fire, powder snow, berry bush) excludes the span.
  3. **Steps:** a link with |Δy| = 1 needs the lower span's third block passable (room to jump) unless the upper
     span is a stair or slab; links are symmetric, so a one-way drop under a low ceiling is not a link.
  4. **Diagonals:** a diagonal link needs an L-path through a flanking orthogonal span ending exactly on the target
     — corner-touching cells never join, so a 1-wide diagonal of corner-touching blocks is not a road (a player
     cannot walk it); 1-wide diagonal paths must be 4-connected staircases.
  5. **Ambiguity:** "within `ambiguousReach` of an unambiguous span" = BFS hops over spans; after the filter a
     re-reach from the seeds drops what became disconnected; a stretch of ambiguous material longer than
     `2 × reach` cuts the road. A seed on a filtered ambiguous span is dropped silently (it was matched).
  6. **Seed snapping:** own column first (floor y, feet y, then `SiegeFloor.floorY`), then growing x/z rings up to
     `seedSnapRadius` with |Δy| ≤ 4, only inside the region; unmatched → `BuildWarning` (not an error). The cell cap
     stops the BFS; the warning names the span that did not fit.
  7. **Distance transform convention:** border spans have `dt = 1`, so `width = 2·dt − 1` (exact for odd widths;
     DESIGN's "2 × dt" would read 2 for a 1-wide path). The plaza rule "dt > widthMax/2" is therefore implemented
     as `width(dt) > widthMax`: a road exactly `widthMax` wide, and the crossing square of two such roads, is not
     a plaza; a 7-wide stretch of a profile with `widthMax` 5 is. **`widthMax` must be ≥ the real road width** or
     the road collapses into junctions — the learner's 95th percentile guarantees that for surveyed roads; hand-made
     profiles should set it generously (15 = never a plaza under 31 wide).
  8. **Thinning additions** (each pinned by a test): (a) corner ends (exactly two skeleton neighbours that touch)
     are never deleted — textbook Zhang-Suen eats a 4-connected staircase (a 1-wide diagonal path) from its ends;
     (b) a span is deleted only when its skeleton neighbours stay one group over their real links — the textbook
     ring test assumes a flat grid, and a ramp's upper lane beside its lower cells is not one (the spiral ramp
     broke in two without this); (c) Holt's staircase templates run afterwards under the same connectivity check.
     Consequences: an L-corner of a 1-wide path is cut into a diagonal (length −0.59 per corner), a 1-wide T's
     centre is replaced by the stem's first span, a 2-wide road loses about one cell per end.
  9. **Endpoint extension:** thinning erodes a road end by about half its width; every Endpoint with one chain is
     walked back out along the mask in its last direction, at most `dt` steps, so a 5-wide road of 30 cells gives an
     edge of length 29 (both ends on the last row of road blocks).
  10. **Spur threshold** = `max(minSpurLength, median width along the chain)` (DESIGN's "local width" read as the
      spur's own width; the junction span's dt is inflated by the crossing and would prune 5-block arms at a plaza).
      Shortest spur first; a junction left with two chains dissolves into one chain routed through the straightest
      mask span between the two chain ends (often the road cell thinning removed, so the geometry has no bump); a
      junction left with one chain becomes an Endpoint; Endpoint–Endpoint chains shorter than `minSpurLength`
      (tiny blobs) are dropped; chains to Anchor or Boundary nodes are never spurs.
  11. **Junction clustering** = candidates within `junctionClusterRadius` **skeleton steps** (path-based, so two
      stacked streets never merge); node at the candidate nearest the cluster centroid (tie → lowest index); spans
      on the connecting paths belong to the junction.
  12. **Plaza** = connected group of spans wider than every listing profile's `widthMax`, one Junction at the group's
      widest span (tie → nearest the group centroid); every skeleton span inside belongs to it and each exit's edge
      geometry runs straight from the plaza rim to the centre (the 15×15 plaza's edges are 23 long = centre to exit
      end). A plaza group without skeleton spans is ignored.
  13. **Loops and parallel chains:** a skeleton component without any node (ring road) gets a Junction at its
      lowest-index span; a loop is split into three edges, a second chain on the same node pair into two, by
      Junction nodes at the split spans (no better kind exists; the API needs unique pairs, `FromNodeId < ToNodeId`).
  14. **Anchors** snap to the nearest skeleton span within `nodeMatchDistance` (3D); on a tie an existing node span
      wins (the junction the admin stood next to); the node becomes kind Anchor at the anchor's stored position
      with `existingId` = anchor id; an anchor beyond reach → `WARN_ANCHOR_OFF_ROAD`, a second anchor on the same
      span → `WARN_ANCHOR_DUPLICATE` (first wins). Anchors never dissolve or prune.
  15. **Tile border (D7):** a chain is cut where it leaves the tile; the last inside span becomes a Boundary node
      (an Endpoint there → Boundary, a Junction/Anchor keeps its kind); everything outside the tile is dropped
      (nodes with an outside position included — the neighbour tile builds them). Known limitations: a Junction or
      Anchor sitting exactly on a border cell with the road continuing across is not stitched (the API stitches
      Boundary nodes only); a junction cluster straddling the border whose centre lies outside yields a Boundary node
      at its last inside span, which may not be a border cell (the API then answers 400 for that tile — move the
      junction with an anchor). Both need a junction within one block of a tile border.
  16. **Stable ids:** greedy nearest within 3 blocks; anchors by id only; a matched **Locked** previous node keeps its
      old position and the geometry is closed onto it; an edge keeps its id when both nodes matched a previous edge's
      pair and the polylines stay within 2 blocks (symmetric farthest-point distance).
  17. **Edge fields:** `length` = walked 3D length of the unsimplified centreline including the closing segments onto
      the node positions; `avgWidth` = mean `2·dt − 1` over the chain's spans (node spans included); `geometry` = RDP
      (ε 0.75) of the same polyline, integer floor positions, first/last = the node positions exactly; `gateDoorIds`
      = distinct door ids of spans whose floor or headroom is in a closed footprint, in chain order.
  18. **Profile match:** histogram of every mask span within `dt − 1` hops of a chain span (the whole cross-section,
      each span once) vs each applicable profile's Surface/Edge/Accent `centreShare`s by cosine (uniform weights
      when a profile has no shares yet); a profile needs one shared material to be a candidate; ties → lower id;
      nothing shared → `profileId` empty (API `null`). A gravel path turning into stone bricks is **one** edge with the
      dominant material's profile (no split on profile change).
  19. `TileRequest.world` is carried for the caller and not used by the builder; `BUILDER_VERSION = 1`.
  20. Warnings are `BuildWarning(message, x, y, z)`; the API string is `"<message> at (x, y, z)"`
      (`TileBuildResult.warningTexts()`).
- **Discrepancies found:**
  - knk-plugin `.gitignore` `**/build/` swallowed the plan's package name `C/roads/build/` (see "What was built");
    fixed with a `src/**/build/` exception rather than renaming the package the plan, DESIGN and the guard test use.
  - Plan "Test fixtures" puts `GridFixture` under `knk-core/src/test/.../roads/`; it lives in `.../roads/build/`
    (package-private access to `RoadMask` internals used by the tests).
  - DESIGN §5.5 "width (2 × dt)" → `2·dt − 1` with border `dt = 1` (decision 7); §5.6 step 3 "local width" → the
    spur's median width (decision 10); plan "histogram within dt of a chain" → `dt − 1` hops (decision 18).
  - Textbook Zhang-Suen needed the two robustness additions of decision 8 (staircases, non-planar span grid).
  - Cloud network unchanged from links 1-3; additionally `./gradlew --offline` fails earlier on the shadow plugin
    (never reached the paper-api step) — irrelevant, noted for completeness. KNG-17 still not on `main`.
- **Developer to-do:**
  1. Local: `./gradlew :knk-core:test` (expect **1280** green), then `./gradlew build -x deployToDevServer` — only
     new classes and a `.gitignore` line; knk-paper does not reference them yet, so no compile impact is expected.
  2. Live: nothing observable — 2c is pure core; `/knk road build` (Phase 3) is what exercises it. If you have a
     minute, skim decisions 1 (floor-y convention), 7 (plaza threshold and `widthMax`), 8 (thinning consequences),
     15 (border limitations) — they shape Phases 2d/3.
  3. When Phase 3 lands: verify `Material#isCollidable()` exists on 1.21.10 and feed `PassabilityRules.of(name ->
     Material.valueOf(name).isCollidable(), config overlays)`; the curated default list is only a fallback.
- **What later phases must wire:**
  - **2d (router):** node/geometry y is the **floor** y (decision 1) — `Snapper` compares the player's feet y − 1
    (or adds 1 to the polyline) and `verticalWeight` applies to that difference; `RoadNodeKind` from
    `C/domain/roads`; edges arrive from the API with the fields `TileBuildResult.Edge` produced (`length`,
    `geometry` as `int[][]`, `gateDoorIds`, `regionIds`, `profileId`). `Polygon2D` (R2) for `RegionClosestPoint`,
    `DomainAccessEvaluator` (R6) inside `AccessPolicy`, `BlockKey` for any cell map — unchanged from 2a's notes.
  - **2e (api-client):** `TileBuildResult` → `RoadTileGraphUpsertDto`: `builderVersion`, `cellCount`, `levelCount`,
    `warnings = warningTexts()`, nodes `{key, existingId, x, y, z, kind = kind.apiName()}`, edges `{existingId,
    fromKey, toKey, geometry (List<int[]> → int[][]), length, avgWidth, profileId, gateDoorIds, domainIds,
    regionIds}` (the last two filled by Phase 3 before the PUT). `RoadProfileDto` → `ProfileSet.Profile(id, name,
    enabled, widthMin, widthMax, scopeTownIds, materials)` with `ProposedProfile.Material(material,
    RoadMaterialRole.fromApiName(role), ambiguous, centreShare, edgeShare, samples)`. Tile graph download →
    `NodeMatcher.PreviousGraph(nodes: PreviousNode(id, x, y, z, RoadNodeKind.fromApiName(kind), locked), edges:
    PreviousEdge(id, fromNodeId, toNodeId, geometry))` and `SkeletonGraph.Anchor(id, x, y, z)` for its Anchor-kind
    nodes; Stitch edges may stay in the list (their other node never matches).
  - **3 (paper build job):** `roads/ChunkSnapshotSurfaceGrid implements SurfaceGrid` over captured snapshots with
    `PassabilityRules.of(...)` (`floorMaterial` = the block at y, or y − 1 when the block at y is an overlay;
    `isStairOrSlab` from `Material` names or `Stairs`/`Slab` block data; `minY/maxY` from the `World`); a
    `GateCells` map prebuilt from `gateManager.getAllGates()` → `closedFootprint(id)` → `BlockKey` → door id (the
    builder checks the floor and both headroom blocks); `ScopeLookup` from the WorldGuard regions at the column →
    Town id via `RegionDomainResolver`; seeds = Domain Locations in the tile + margin box (D12 endpoint), survey and
    admin seeds, neighbour tiles' Boundary nodes; `BuildParameters` from `NavigationConfig.builder`;
    `new TileBuilder().build(request, grid)` **off the main thread** (pure); then domain/region tagging (sample the
    geometry every 4 blocks, D11) into `domainIds`/`regionIds`; PUT. Store anchors and seeds in floor-y convention.
    `ProfileSet` needs the *enabled* profiles only; disabled ones are dropped anyway.
  - **Scratch build (cloud):** unchanged from the 2a recipe; the `Vector` stub in this link's scratchpad was
    rewritten from the Bukkit API (constructors, get/set, arithmetic, length/distance, dot/cross, normalize,
    rotations incl. `rotateAroundNonUnitAxis`, fuzzy `equals`, `clone`, `getMinimum/getMaximum`).

### 2d Router — `C/roads/route/` and `C/navigation/`

- `RoadNetworkSnapshot` (immutable per world): nodes, edges, per-edge decoded polyline, profile classes, the set of
  all edge region ids; built from tile graphs + meta; `SegmentIndex` (32×32 x/z buckets → segment refs).
- `CoverageCheck.misses(List<BreadcrumbPoint>, RoadNetworkSnapshot, maxDistance=2)` → misses with the floor material
  seen there (used by the survey review in Phase 3).
- `Snapper.snap(x, y, z, maxDistance, verticalWeight)` → `SnapPoint{edgeId, segmentIndex, t, point, distance}`.
- `AStarRouter.route(RouteRequest{start, goals (1..n SnapPoints), accessPolicy, classCost}) → RouteResult` —
  virtual nodes split edges; heuristic = min Euclidean to any goal × cheapest class cost; oneway; binary heap.
- `AccessPolicy` interface (`EdgeVerdict check(RoadEdge)` → `OPEN | PASS_THROUGH(hint) | BLOCKED(reason)`) and
  `CompositeAccessPolicy`; implementations take ports:
  - `GateAvailability` (port `GateState { Optional<GateView> gate(int doorId); }` → state/jammed/destroyed/
    allowPassThrough/siegeLocked/siegeCarries; `PassRule { boolean canPass(int doorId); }`) — OPEN or destroyed → open;
    siege-locked → `PASS_THROUGH` if `siegeCarries` (R39, D2) else blocked; otherwise closed + pass-through allowed for
    this player → `PASS_THROUGH`; otherwise blocked; OPENING/CLOSING/jammed → blocked.
  - `DomainAvailability` (uses `DomainAccessEvaluator` R6 + a `DomainLookup` port **by WorldGuard region id** (D11);
    bypass flag) — entry denied on edges entering a region's domain, exit denied on edges leaving the player's current
    domains. The paper adapter resolves via `RegionDomainResolver.getDomainByRegionIdNoRefresh`, falling back to
    `resolveRegionsFromApi` (routing runs off the main thread, so the blocking call is allowed); `RoadNetworkCache`
    calls `warmCache(snapshot.regionIds())` after each snapshot swap so lookups are normally cache hits.
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

### Phase 2d status — done 2026-09-27 (knk-plugin `claude/road-navigation` `1f569b7`, `5f3f41e`, `c84b556`, `f371323`, `33efa64`, `a82db3c`; on top of 2c's `c2ca1e3`; trunk `main` still `eb1d68c`)

- **What was built** (knk-core, Bukkit-free, pure; no I/O, threads or clocks — the caller passes the tick):
  - **`C/domain/roads/`** (next to 2c's `RoadNodeKind`): `RoadClass` (`MAIN/ROAD/PATH`, `apiName()`/`fromApiName()`),
    `RoadEdgeFlag` (`ONEWAY/NO_GPS/CLOSED` ↔ `Oneway/NoGps/Closed`), `RoadEdgeSource` (`DETECTED/RECORDED/STITCH`),
    `RoadNode(id, x, y, z, kind, name, componentId)` (ids ≥ 0; `isDestination()` = named), `RoadEdge(id, fromNodeId,
    toNodeId, geometry List<int[]>, length, avgWidth, profileId, streetId, costMultiplier, flags, gateDoorIds,
    domainIds, regionIds, source, stale)` — the Phase 1 `RoadEdgeDto` fields the router needs (`status` folded into
    `stale`; the bounding box, `tileId`, `world`, `streetSource` are not carried).
  - **`C/roads/route/`**: `RoadNetworkSnapshot` (+ `Builder`, nested `Profile(id, name, roadClass, costMultiplier)`,
    `Street(id, name)`) — nodes, edges, incident-edge indexes, every polyline decoded once (`EdgePolyline`: cumulative
    distances, `pointAt`, `segmentAt`, `subPolyline`), profiles → road class, street names, `regionIds()` (every
    region any edge passes), `unresolvedEdgeIds()` (edges whose node is in a tile not downloaded — dropped, listed),
    `costFactor`/`edgeCost`/`minCostFactor`; `SegmentIndex` (32×32 x/z buckets → packed edge/segment refs; height
    not bucketed); `RouterParameters` (max-snap-distance 48, snap-vertical-weight 4, class-cost Main 0.9 / Road 1.0 /
    Path 1.15); `SnapPoint(edgeId, segmentIndex, t, point, distance, along)` + `onEdge`/`atNode` helpers;
    `Snapper` (`snap(feetX, feetY, feetZ)`, `snapFloor(...)`, static plan signature); `EdgeVerdict` (`OPEN |
    PASS_THROUGH(hint) | BLOCKED(reason)` + `Cause(GATE|DOMAIN|FLAG, id, name)`); `AccessPolicy` (+ `ALL_OPEN`),
    `CompositeAccessPolicy`, `StaticFlagsAvailability`, `GateAvailability` (ports `GateState { Optional<GateView>
    gate(doorId) }`, `GateView(doorId, name, AnimationState, jammed, destroyed, allowPassThrough, siegeLocked,
    siegeCarries)`, `PassRule { canPass(doorId) }`), `DomainAvailability` (port `DomainLookup { Optional<DomainSnapshot>
    domainByRegionId(regionId) }`, takes the shared `DomainAccessEvaluator`, the player's current region ids and a
    bypass flag); `RouteRequest(start, goals, accessPolicy, classCost)`, `Route` (steps with edge/direction/entry-exit
    along/length/cost/startDistance/verdict, polyline, walked length, cost, start/end, interior `nodeIds()`,
    `passThroughSteps()`, `project()`, `pointAt()`, `truncated()`, `withVerdicts()`), `RouteResult(FOUND | BLOCKED |
    DIFFERENT_COMPONENTS | NO_ROUTE)`, `AStarRouter` (`route`, `routeOrExplain`), `BlockedExplainer` (+
    `Explanation(verdict, blockedEdge, partialRoute, fullRoute)`), `RegionShape` (polygon + y band, or cuboid;
    `containsFloor`, `distanceFromFloor`, `closestPointFromFloor`), `RegionClosestPoint` (`goals(shape, snapshot)`,
    `crossings`, `closest`), `Maneuver(kind, position, along, bearingChange, street, text)` + `ManeuverBuilder`,
    `EtaEstimator`, `CoverageCheck` (`misses(List<SurveySample>, snapshot, maxDistance = 2)` → `Miss(x, y, z, floor,
    distance)`, `coverage`).
  - **`C/navigation/`**: `SessionParameters` (reroute-distance 8, reroute-after-ticks 40, re-route min interval 60
    ticks, improvement interval 200 ticks / threshold 15 %, arrive-distance 4, max-session-minutes 30, sprint-speed
    5.6, projection look-back 16), `NavigationEffect` (sealed: `ComputeRouteEffect(reason, keepCurrentUnlessShorter)`,
    `RouteAdoptedEffect(route, maneuvers, reason, explanation)`, `RerouteStartedEffect(reason, verdict)`,
    `RouteKeptEffect`, `GuidanceEffect(along, offRoute, remainingBlocks, etaSeconds, progress, aheadPoint,
    nextManeuver, metersToNext)`, `ArrivedEffect`, `EndedEffect(reason)`; enums `RouteReason`, `EndReason`),
    `NavigationSession` (`PLANNING → GUIDING ⇄ REROUTING → ARRIVED | ENDED`; `start()`, `onRouteResult(result,
    tick)`, `tick(feetX, feetY, feetZ, tick)`, `onElementBlocked(verdict, tick)`, `onElementOpened(tick)`,
    `end(reason)`; queries `state`, `route`, `maneuvers`, `explanation`, `along`, `remainingBlocks`).
  - **Test fixture** `knk-core/src/test/.../roads/route/NetworkFixture.java` (+ public `NetworkFixtureAccess` for
    other test packages): a 13-node / 14-edge town in the Phase 1 download shape — grid A-B-C-D with Keepstreet
    (Main) / Merchantstreet (Road) / a diagonal path, a gate edge (door 7), castle edges tagged with region
    `kardenna_castle` / domain 42, a oneway edge, a tile boundary with a stitch edge, a tunnel dip, a bridge in a
    second component. Reused by every 2d test.
- **Reuse:** R2 (`Polygon2D` inside `RegionShape`), R5 (via the `GateView` port: the paper side fills it from
  `CachedGateDoor`'s effective accessors), R6 (`DomainAccessEvaluator` instance passed into `DomainAvailability`),
  R7 (the `DomainLookup` port = `RegionDomainResolver.getDomainByRegionIdNoRefresh` → `resolveRegionsFromApi`),
  R25/R39 (the `PassRule` port and `GateView.siegeCarries`), 2a's `AnimationState` (the `GateView` state — no second
  gate-state enum), 2b's `SurveySample` as the breadcrumb (no second breadcrumb record), 2c's `RoadNodeKind`, the
  `SiegeEffect` style for `NavigationEffect`. Nothing in §2 duplicated; no new dependency.
- **Tests:** knk-core **1280 → 1364** (0 failures, 0 skipped; 84 new): `RoadNetworkSnapshotTest` 8, `SnapperTest` 9,
  `AccessPolicyTest` 15, `AStarRouterTest` 20, `RegionShapeTest` 4, `RegionClosestPointTest` 5, `ManeuverBuilderTest`
  9, `EtaEstimatorTest` 2, `CoverageCheckTest` 1, `NavigationSessionTest` 11 — every item of the plan's 2d test list:
  shortest path vs class costs (and edge multipliers); oneway (node and virtual-node cases, a start on a oneway edge
  that must go round); closed gate → BLOCKED with the reason, the gate edge and a partial route to the gate's node;
  pass-through gate → FOUND with the hint on the step; entry denied → route ends at the last node outside the region
  with "you may not enter Kardenna Castle"; exit denied → route stays inside; different components → refused before
  any policy call; snap prefers the bridge (feet y 73) over the road 8 below and the road at feet y 65; region
  multi-goal (crossing points, oneway entry refused, fallback to the closest network point); maneuvers (right /
  left / slight / sharp bands, "Continue onto", same street silent, Boundary nodes and stitch edges silent,
  tunnel / bridge / stairs phrases); session (off-route → re-route after N ticks, once, rate-limited; arrival; gate
  closes mid-route → re-route with the verdict and adoption of the partial route; improvement adopted only when
  > 15 % shorter; timeout; runtime end reasons). **Not compiled with Gradle:** `./gradlew :knk-core:test` still fails
  on `paper-api` (proxy 403 on `repo.papermc.io`, `maven.enginehub.org` 000 — same as links 1-4); counts from the
  §0.4 scratch build (2a's recipe, `Vector` stub rewritten from the Bukkit API surface, `testRuntimeOnly
  junit-platform-launcher` added for Gradle 8.10). `ArchitectureGuardTest` green with both new packages.
  knk-paper and knk-api-client: not built, not touched.
- **Decisions to review** (numbered; defaults taken, all reversible):
  1. **Snapper coordinates:** `Snapper.snap(x, y, z)` takes the player's **feet** position and compares it with the
     polyline's floor y + 1 (2c decision 1); `snapFloor` and the static plan signature take floor coordinates.
     `SnapPoint.point`, every `Route` polyline point and `Maneuver.position` are floor blocks — Phase 4 adds 1
     (+0.2) for particles. `NavigationSession.tick` likewise takes feet coordinates; `RegionShape.containsFloor` tests
     feet = floor + 1 against the region's y band.
  2. **Weighted snap distance:** the 48-block limit is checked on the *weighted* distance (`√(dx² + (w·dy)² + dz²)`),
     so a road 12 blocks below counts as 48 away. Ties → lower edge index, then lower segment.
  3. **Snapshot ids:** node ids must be ≥ 0 (the router's virtual nodes are −1 for the start and −2−k for goal k).
     Edges referencing a node of a tile not yet downloaded are dropped and listed in `unresolvedEdgeIds()` (Phase 1
     decision 1: stitch edges may point at the neighbour tile); the cache should log them and they resolve once the
     neighbour tile arrives.
  4. **Segment index:** 32-block x/z buckets, height not bucketed (a bridge and the road below share a bucket; the
     weighted metric separates them); a segment spanning several buckets is visited once per bucket (visitors are
     idempotent minima). Built eagerly with the snapshot.
  5. **Cost model:** `length × classCost(class) × profile.costMultiplier × edge.costMultiplier`; an edge without a
     (known) profile has class factor 1.0; a partial edge costs the polyline fraction of that. The heuristic scales
     Euclidean distance by the **minimum** factor over all edges (multipliers may be < 1), computed per request
     (O(E), trivial). Costs are consistent because `length ≥ polyline length ≥ chord`.
  6. **A\* tie-breaks:** equal `f` → larger `g` first, then insertion order; goals in other components are dropped
     before the search; the search stops when any goal is popped.
  7. **Blocked start edge:** if the edge the player stands on is BLOCKED (a closed road, a gate edge with the gate
     shut), no route leaves it — the explainer then reports that edge with an empty partial route. The paper side
     may prefer to snap to the nearest *usable* edge; not done here.
  8. **Explainer's partial route** ends at the entry **node** of the first blocked edge of the all-open route (the
     gate can sit anywhere along that edge; the network has no finer point). "Guiding you to the gate" therefore
     guides to the junction before the gate edge. The partial route's steps carry the real verdicts (pass-through
     hints kept). Oneway is still respected in the all-open search, so a goal cut off only by oneway rules is
     NO_ROUTE, not BLOCKED.
  9. **Gate rules order:** unknown door → OPEN (stale tag; nothing to check); destroyed → OPEN; OPEN → OPEN;
     OPENING/CLOSING → BLOCKED ("is opening/closing"); jammed → BLOCKED; siege-locked → PASS_THROUGH when
     `siegeCarries` else BLOCKED ("is locked for a siege"); closed + `allowPassThrough` + `PassRule.canPass` →
     PASS_THROUGH ("right-click the West Gate to pass"); else BLOCKED ("the West Gate is closed"). Several doors on
     one edge → the strictest, first door first. `GateView.name` null → "the gate".
  10. **Domain exit rule:** an edge "leaves" a domain the player stands in when its `regionIds` do not contain that
      domain's region id; an edge listing the region counts as staying inside (so the route ends on the last edge
      inside the domain). Entry is checked for every region on the edge the player is not currently in. Bypass →
      everything OPEN. Messages: "you may not enter X" / "you may not leave X" (lower-case fragments; the runtime
      composes the sentence — the evaluator's own "You are not allowed to enter X." is not reused verbatim).
  11. **Composite order:** first BLOCKED wins, else first PASS_THROUGH; cached per edge id. Recommended order for
      Phase 4: `StaticFlagsAvailability`, `GateAvailability`, `DomainAvailability`.
  12. **Region goals:** crossing points are bisected (12 steps) on the polyline segment that changes side, from
      either direction; a road entirely inside a region contributes its vertices; nothing inside → the single
      network point closest to the region, sampled every 4 blocks along every edge. Cuboid bounds are inclusive.
  13. **Maneuvers:** bearings over 6 blocks of the *route polyline* before/after the node; Δ = atan2(cross, dot)
      with x east / z south → positive = right; bands `< 20` straight, `[20, 60)` slight, `[60, 120]` turn,
      `> 120` sharp. A turn is announced at Junctions or on a street change; straight + street change → "Continue
      onto X"; same street → "Turn left to stay on X"; unlabelled next edge → "Take the path/road on the left"
      (path when the profile class is Path). Level change at any node from the *next step's* stretch: min y
      `< node y − 3` → DOWN "Go down into the tunnel"; max y `> node y + 3` → BRIDGE "Cross the bridge" when the
      step's end is back within 3 of the node's y, else UP "Take the stairs up". Boundary nodes and stitch edges
      never announce; the street comparison looks through stitch edges. `Maneuver.along` is polyline metres (what
      `Route.project` measures), not walked metres.
  14. **Route distances:** `Route.length()` is walked metres (sum of step lengths); `polylineLength()` / `along` /
      `project()` are polyline metres; `remainingBlocks = (1 − along/polylineLength) × length`. `Route.project`
      considers only segments ending after `along − 16` (look-back), so progress is monotone on self-crossing routes.
  15. **Session rules:** the "max once per 3 s" re-route limit (60 ticks) applies to OFF_ROUTE and ELEMENT_BLOCKED
      requests, not to the INITIAL one; an improvement request is limited to once per 200 ticks and adopts only a
      **full** route shorter than 85 % of what is left (a BLOCKED result or NO_ROUTE keeps the current route); when
      the current route is a *partial* one, an "element opened" notice retries unconditionally (the blocking gate
      may have opened). While REROUTING the old route keeps producing guidance and no second request is made. Results
      arriving after ARRIVED/ENDED are dropped. Arrival = within `arriveDistance` (3D, floor y) of the route's end
      point — for a partial route that is the last reachable node. "Already inside the region" is the runtime's
      check before starting (→ `end(ALREADY_THERE)`).
  16. **`EtaEstimator` formatting** ("~40 s" to 5 s, "~3 min", "340 m", "1.2 km") lives in core for the tests; the
      runtime may format its own.
  17. **`CoverageCheck`** takes `SurveySample`s (floor y) and plain 3D distance (weight 1), default 2 blocks; a miss
      reports `+∞` distance (the snapper only searches within `maxDistance`).
  18. **`RoadEdge` keeps `geometry` as `List<int[]>`** (defensive copy) rather than a packed array — 150 k points
      world-wide is a few MB (DESIGN §9), fine.
- **Discrepancies found:**
  - Plan 2d names `RegionShape → goal set`; the goal derivation is `RegionClosestPoint` (the DESIGN §4 name), with
    `RegionShape` as the pure geometry — both exist.
  - Plan 2d's `AccessPolicy.check(RoadEdge)` has no direction; `Oneway` is therefore the router's (DESIGN §6.7 lists
    it under static flags — handled, just not by `StaticFlagsAvailability`).
  - DESIGN §6.5 lists three level phrases without a rule for choosing; decision 13 defines one.
  - Cloud network unchanged from links 1-4 (`repo.papermc.io` 403, `maven.enginehub.org` 000). KNG-17 still not on
    `main`.
- **Developer to-do:**
  1. Local: `./gradlew :knk-core:test` (expect **1364** green), then `./gradlew build -x deployToDevServer` — only
     new classes in two new packages; knk-paper does not reference them yet.
  2. Live: nothing observable — 2d is pure core; `/navigate` (Phase 4) is what exercises it. Worth a skim: decisions
     1 (feet vs floor), 7-8 (blocked start edge, "to the gate" = to the junction before it), 10 (exit rule), 13
     (level-change phrases), 15 (re-route rules).
- **What later phases must wire:**
  - **2e (api-client):** `RoadEdgeDto` → `RoadEdge(id, fromNodeId, toNodeId, geometry (int[][] → List<int[]>), length,
    avgWidth, OptionalInt profileId, OptionalInt streetId, costMultiplier, flags (List<String> →
    `RoadEdgeFlag.fromApiName` into an EnumSet), gateDoorIds, domainIds, regionIds, RoadEdgeSource.fromApiName(source),
    "Stale".equals(status))`; `RoadNodeDto` → `RoadNode(id, x, y, z, RoadNodeKind.fromApiName(kind), name,
    componentId)`; meta `profiles[]` → `RoadNetworkSnapshot.Profile(id, name, RoadClass.fromApiName(roadClass),
    costMultiplier)`, `streets[]` → `RoadNetworkSnapshot.Street(id, name)`. The mapper may live in `A/mapper/RoadMapper`
    next to the DTO ↔ `TileBuildResult`/`ProfileSet.Profile` mappings 2c asked for.
  - **3 (paper cache):** `RoadNetworkCache` builds one `RoadNetworkSnapshot` per world from the downloaded tile graphs
    + meta (`builder(world).addNodes(...).addEdges(...).addProfile(...).addStreet(...).build()`), swaps it atomically,
    logs `unresolvedEdgeIds()`, calls `warmCache(snapshot.regionIds())` on the `RegionDomainResolver`. `RoadOverlayRenderer`
    reads `edges()`/`polyline(edge)` (floor y; ±8 of the viewer). Survey review: `CoverageCheck.misses(breadcrumbs,
    snapshot)`. `NavigationConfig` (R16) fills `RouterParameters` and `SessionParameters`.
  - **4 (`/navigate`):** per request build `CompositeAccessPolicy.of(new StaticFlagsAvailability(), new GateAvailability(
    gateState, passRule), new DomainAvailability(evaluator, lookup, regionIdsAt(player), bypass))` with `GateState` from
    `GateManager.getGate(id)` → `GateView(id, structure name, getCurrentState(), isJammed(), isEffectivelyDestroyed(),
    isEffectivelyAllowPassThrough(), SiegeGateController.isLocked(getGateStructureId()), canCarryNonMember(door))`,
    `PassRule` = `GatePassThroughRules.canPass(player, door)`; snap with `new Snapper(snapshot, routerParameters).snap(feet)`
    (refuse with the DESIGN messages when empty; direct mode when the target is within 48 of the player);
    destination goals: a point → `Snapper.snapFloor`, a named node → `SnapPoint.atNode`, a region →
    `RegionClosestPoint.goals(RegionShape.polygon/cuboid(...), snapshot)` (refuse "already in X" when
    `containsFloor(player)`); `new AStarRouter(snapshot).routeOrExplain(RouteRequest.of(start, goals, policy,
    routerParameters))` **off the main thread**; `new NavigationSession(sessionParameters, new
    ManeuverBuilder(snapshot)::build, tick)` → `start()` → apply effects; feed `onRouteResult` on the main thread;
    `tick(feet, tick)` from the ticker (every tick or every `trail-period-ticks`; `GuidanceEffect.along` is what to draw
    the next `trail-length` blocks from via `route.pointAt`); D13: every 2 s re-check `route.steps()` with a fresh policy
    → first BLOCKED step → `onElementBlocked(verdict, tick)`; `GateStateListener` / domain refresh → `onElementOpened(tick)`;
    the `Explanation` gives the message pieces ("No open route to X — " + `reason()` + ". Guiding you to the gate." /
    "You may not enter X. Guiding you to its edge." via `isDomainBlock()`); `EtaEstimator.describe(remaining)` for the
    boss bar; `Maneuver.text` for the HUD. `end(EndReason)` on quit/death/world change/teleport/siege/stop.

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

### Phase 2e status — done 2026-09-28 (knk-plugin `claude/road-navigation` `4fdece7`, `e45a84c`, `4ed4b22`, `4ffdd1a`; on top of 2d's `a82db3c`; trunk `main` still `eb1d68c`)

- **What was built:**
  - **Ports, `C/ports/api/`** (Bukkit-free, `CompletableFuture`, on knk-core types — decision 1):
    `RoadNetworkQueryApi` — `tiles(world)`, `tileGraph(world, tileX, tileZ, etag)` → `Conditional<RoadTileGraph>`,
    `meta(world)`, `profiles()`, `profile(id)` (404 → null), `surveys(world)`, `seeds(world)` (`GET api/road-seeds`),
    `seedLocations(world, minX, minZ, maxX, maxZ)` (D12 box query), `searchEdges(PagedQuery)` → `Page<RoadEdge>`;
    `RoadNetworkCommandApi` — `upsertTileGraph(world, x, z, TileBuildResult)` → `RoadTileUpsertResult`,
    `markDirty(world, x, z)` → `RoadTile`, `createProfile`/`updateProfile(id, RoadProfileUpsert)`/`deleteProfile(id)`,
    `createSurvey(RoadSurveyCreate, actingUserId)`, `createSeed(RoadSeedCreate)`/`deleteSeed(id)`, `updateNode(id,
    RoadNodeUpdate)`, `createAnchor(RoadNodeAnchor)`, `mergeNodes(keep, merge)`, `recordEdge(RoadEdgeRecord)`,
    `updateEdge(id, RoadEdgeUpdate)` → `RoadEdgeUpdateResult`, `deleteEdge(id)` (deletes: true on 204, false on 404).
  - **`C/domain/common/Conditional<T>(notModified, body, etag)`** (+ `modified(body, etag)`, `notModified(etag)`,
    `bodyOptional()`) — the R17 result type.
  - **`C/domain/roads/`** — thin records for the API shapes with no knk-core twin, mirroring `RoadDtos.cs`: `RoadTile`
    (`etag()` = `"<version>"`, `isBuilt()`, `SIZE = 512`, `tileCoordinate(block)`), `RoadTileGraph(tile, nodes, edges)`,
    `RoadTileUpsertResult`, `RoadProfile` (materials = `ProposedProfile.Material`, `statsJson` text, `hasStats()`),
    `RoadProfileUpsert` (+ `of(existing, learned, statsJson)` / `of(name, class, cost, scope, learned, stats)` — the 2b
    rule), `RoadBreadcrumbPoint`, `RoadSurvey`, `RoadSurveyCreate`, `RoadSeed`, `RoadSeedCreate` (+ `admin(...)`,
    `survey(...)`), `RoadSeedSource` (`ADMIN/SURVEY`, `apiName()`/`fromApiName()`), `RoadSeedLocation`, `RoadComponent`,
    `RoadNetworkMeta(profiles, streets: RoadNetworkSnapshot.Street, components)`, `RoadNodeUpdate` (+ `rename`,
    `unnamed`, `kind`, `locked`), `RoadNodeAnchor`, `RoadEdgeUpdate` (+ `street(id, propagate)`, `unlabelled`,
    `profile`, `flags`, `costMultiplier`; contradictions refused), `RoadEdgeRecord`, `RoadEdgeUpdateResult`,
    `RoadApiError(error, message)`. **`RoadNode` gained `locked`** (8-arg canonical constructor; the 7-arg one stays,
    `locked = false`) because `NodeMatcher.PreviousNode` needs it.
  - **`A/dto/`** — one record per class of `W/Dtos/RoadDtos.cs` (29 files: `RoadMaterialDto`, `RoadProfileDto`,
    `RoadProfileUpsertDto`, `RoadBreadcrumbPointDto`, `RoadSurveyCreateDto`, `RoadSurveyDto`, `RoadTileDto`,
    `RoadNodeDto`, `RoadEdgeDto`, `RoadTileGraphDto`, `RoadTileGraphNodeDto`, `RoadTileGraphEdgeDto`,
    `RoadTileGraphUpsertDto`, `RoadTileUpsertResultDto`, `RoadStreetRefDto`, `RoadComponentDto`, `RoadNetworkMetaDto`,
    `RoadSeedDto`, `RoadSeedCreateDto`, `RoadSeedLocationDto`, `RoadNodeUpdateDto`, `RoadNodeAnchorDto`,
    `RoadNodeMergeDto`, `RoadEdgeUpdateDto`, `RoadEdgeUpdateResultDto`, `RoadEdgeRecordDto`, `StreetRoadDto`,
    `RoadErrorDto`): `@JsonProperty` = the `[JsonPropertyName]`s, enums as `String`, `flags` as `List<String>`,
    `geometry` as `int[][]`, `stats` as `JsonNode`, dates as `OffsetDateTime` with `LenientOffsetDateTimeDeserializer`;
    request DTOs `@JsonInclude(NON_NULL)` (absent `existingId`/`profileId`/`stats` left out) and their dates
    `@JsonFormat(shape = STRING)` (decision 8).
  - **`A/mapper/RoadMapper`** — read side (`mapTile`, `mapNode`, `mapEdge`, `mapTileGraph`, `mapUpsertResult`,
    `mapMaterial`, `mapProfile(s)`, `mapSurvey`, `mapSeed`, `mapSeedLocation`, `mapStreet`, `mapComponent`, `mapMeta`,
    `mapEdgeUpdateResult`, `error(ApiException)` → `Optional<RoadApiError>`), write side (`toUpsertDto(TileBuildResult)`,
    `toNodeDto`/`toEdgeDto`, `toMaterialDto`, `toProfileUpsertDto`, `toSurveyCreateDto`, `toSeedCreateDto`,
    `toNodeUpdateDto`, `toAnchorDto`, `toEdgeUpdateDto`, `toEdgeRecordDto`) and the knk-core adapters the 2c/2d blocks
    asked for: `toBuilderProfile(s)` → `ProfileSet.Profile`, `toSnapshotProfile` → `RoadNetworkSnapshot.Profile`,
    `toPreviousGraph(RoadTileGraph)` → `NodeMatcher.PreviousGraph` (null → `EMPTY`), `toAnchors(RoadTileGraph)` →
    `SkeletonGraph.Anchor` list (Anchor-kind nodes).
  - **`A/impl/BaseApiImpl`** (additive, R17): `IF_NONE_MATCH_HEADER`, `record ConditionalResponse(notModified, body,
    etag)`, `getConditional(url, etag)` — sends `If-None-Match` verbatim (weak tags too; blank = none), 304 →
    `notModified` with the response's ETag (or the one sent), 2xx → body + ETag, any other non-2xx → `ApiException`
    exactly like `execute`. `get`/`postJson`/`putJson`/`delete`/`execute` untouched.
  - **`A/impl/RoadNetworkQueryApiImpl`**, **`RoadNetworkCommandApiImpl`** — `BaseApiImpl` + `supplyAsync(…, executor)`
    like `DiscoveriesApiImpl`; routes exactly the 1.5 table (world URL-encoded); `X-Acting-User-Id` on
    `createSurvey`; body-less POST for the dirty mark; a refusal completes exceptionally with the `ApiException` as
    the cause (`RoadMapper.error` reads its body). **`A/client/KnkApiClient`**: fields, construction,
    `getRoadNetworkQueryApi()` / `getRoadNetworkCommandApi()`.
- **Reuse:** R17 applied (improved, not replaced). Reused as is: `BaseApiImpl` request/parse/logging helpers,
  `UsersCommandApiImpl.ACTING_USER_HEADER`, `PagedQueryDto`/`PagedResultDto` → `Page`, `LenientOffsetDateTimeDeserializer`,
  the `ClansQueryApiImpl` 404-→-null convention, 2b's `ProposedProfile.Material` and `SurveyStats.toJson/fromJson`
  (no second material or stats record), 2c's `TileBuildResult`/`NodeMatcher.PreviousGraph`/`SkeletonGraph.Anchor`/
  `ProfileSet.Profile`, 2d's `RoadNode`/`RoadEdge`/`RoadNetworkSnapshot.Profile`/`Street` and the enums'
  `apiName()`/`fromApiName()`. No new dependency (`mockwebserver` not added — stubbed OkHttp interceptors).
- **Tests:** knk-core **1364 → 1374** (`ConditionalTest` 3, `RoadApiRecordsTest` 7; 0 failures, 0 skipped;
  `ArchitectureGuardTest` green — `domain/roads` and the ports are Bukkit-free). knk-api-client **134 → 174**
  (baseline measured at `a82db3c` before any change: 134 tests, 0 failures, **2 skipped** =
  `SiegeQueryApiLiveTest.fetchesRuntimeConfig` / `readinessOfAMissingScenarioIsNull`, live-only; unchanged after):
  `RoadMapperTest` 13 (fixture `src/test/resources/road/tile-graph.json`), `BaseApiImplConditionalGetTest` 6,
  `RoadNetworkQueryApiImplTest` 11, `RoadNetworkCommandApiImplTest` 9 — every item of the plan's 2e test list (mapper
  round-trips both ways where both sides exist; conditional GET 200/304 incl. weak tag, missing response ETag, 404).
  **Not compiled with Gradle:** `./gradlew :knk-api-client:test` fails on `paper-api` through knk-core (proxy 403 on
  `repo.papermc.io`, `maven.enginehub.org` 000 — same as links 1-5). Counts from the §0.4 scratch build extended to a
  two-project build: `core` (2a's recipe, jackson 2.15.2) and `apiclient` (`implementation(project(":core"))`,
  okhttp 4.12.0, jackson-databind + jsr310 2.17.2 — the same resolution the real build gets — junit-bom 5.10.2,
  `testRuntimeOnly junit-platform-launcher`, `workingDir = knk-api-client`, test resources mapped). knk-paper: not
  built, not touched.
- **Decisions to review** (numbered; defaults taken, all reversible):
  1. **Ports on knk-core types.** Both ports take/return knk-core records; the API shapes that had no core twin are
     new records in `C/domain/roads/` (not nested in the ports, not the DTOs), mapped in `RoadMapper`. Two of them
     import feature packages — `RoadProfile`/`RoadProfileUpsert` use `ProposedProfile.Material` (2b decision 11: one
     material record) and `RoadNetworkMeta.streets` is `List<RoadNetworkSnapshot.Street>` (2d's target type) — a
     `domain → roads/*` import direction that `domain/gates/CachedGateDoor` already has.
  2. **`Conditional<T>` lives in `C/domain/common/`** next to `Page`; shape `(notModified, body, etag)` with
     factories; the api-client twin `BaseApiImpl.ConditionalResponse` carries the raw body string.
  3. **`stats` is JSON text in knk-core** (`String statsJson`; `null` = absent, and on a profile PUT = keep) and a
     `JsonNode` on the wire. `RoadMapper.statsTree` refuses non-JSON text with `IllegalArgumentException` at mapping
     time. Phase 3 reads `SurveyStats.fromJson(profile.statsJson())` when `hasStats()`, else `SurveyStats.empty()`.
  4. **`tileGraph` returns one `RoadTileGraph` record per tile** (tile + nodes + edges), not the raw DTO. `RoadNode`
     carries `locked` now; node `world`/`tileId`/`source` and edge `tileId`/`world`/bbox/`streetSource` are still not
     carried (they stay on the DTOs; the tile is known per download).
  5. **404 semantics:** a never-built tile makes `tileGraph` complete exceptionally (`ApiException` 404) — Phase 3
     lists `tiles(world)` first and uses `PreviousGraph.EMPTY` for tiles not in the list; `profile(id)` completes with
     `null` on 404 (the existing get-by-id convention); the three deletes complete with `false` on 404.
  6. **`saveProfile` is two methods**, `createProfile`/`updateProfile`; the survey → upsert rule of the 2b status block
     is `RoadProfileUpsert.of(existing, learned, mergedStatsJson)` (identity kept from the stored profile) and
     `of(name, class, cost, scope, learned, stats)` for a new profile (enabled by default).
  7. **Errors:** futures keep the `DiscoveriesApiImpl` convention (a `RuntimeException` whose cause is the
     `ApiException`); `RoadMapper.error(apiException)` parses the `{error, message}` body (empty for any other body).
  8. **Request dates are `@JsonFormat(shape = STRING)` per field.** The client's `ObjectMapper` keeps Jackson's default
     `WRITE_DATES_AS_TIMESTAMPS`; no request DTO sent a date before, so the survey create is the first — handled on
     the field rather than changing the mapper for every other DTO.
  9. **Port methods beyond the plan's list:** `profile(id)`, `surveys(world)`, `seedLocations(...)` (the D12 query,
     separate from `seeds(world)` = `GET api/road-seeds` — the handoff conflated the two), `searchEdges` (review
     listings of stale/unlabelled edges). `StreetRoadDto` is mirrored for completeness but has no port method (a
     web-app route).
  10. **`markDirty` sends a body-less POST** (`RequestBody.create(new byte[0], null)`, no Content-Type);
      `RoadTilesController.MarkDirty` takes no body.
  11. **Flags:** `"None"` is tolerated on read (→ no flag); on write the flags go in enum order (`Oneway`, `NoGps`,
      `Closed`); an empty set is sent as `[]` (clears every flag), `null` is left out (unchanged).
  12. **`RoadTile.SIZE`/`tileCoordinate`** duplicate the API's `RoadTile.Size = 512`/`TileCoordinate` for Phase 3's
      tile maths (one constant, `Math.floorDiv`).
  13. The route constants (`/road-tiles`, …) and `encode`/`tileGraphUrl` are package-private statics on
      `RoadNetworkQueryApiImpl`, shared by the command impl through static imports.
- **Discrepancies found:**
  - The 2e handoff described `seeds(world)` as "D12 `seed-locations` box query"; the API has both `GET api/road-seeds
    ?world=` (stored seeds) and `GET api/road-network/seed-locations?…` (domain Locations) — both are exposed
    (decision 9).
  - `KnkApiClient`'s `ObjectMapper` writes `OffsetDateTime` as numeric timestamps (decision 8); harmless so far
    because no earlier request DTO carried a date.
  - Java records cannot have a static factory named like a component (`clearName()`, `clearStreet()`): the factories
    are `unnamed()`/`unlabelled()`.
  - Cloud network unchanged from links 1-5 (`repo.papermc.io` 403, `maven.enginehub.org` 000). KNG-17 still not on
    `main`. The knk-api-client baseline was unmeasured by links 1-5; now recorded (134 / 2 skipped at `a82db3c`).
- **Developer to-do:**
  1. Local: `./gradlew :knk-core:test` (expect **1374** green), `./gradlew :knk-api-client:test` (expect **174**, the
     two `SiegeQueryApiLiveTest` cases skipped as before), then `./gradlew build -x deployToDevServer` — knk-paper
     does not reference the new classes yet.
  2. Live: nothing observable in game — 2e is plumbing; Phase 3's `/knk road` exercises it. Optional 2-minute check
     against the running API with Phase 1's payload already applied: a `jshell`/test call of
     `apiClient.getRoadNetworkQueryApi().tileGraph("world", 0, 0, null).join()` returns `etag "1"`, and the same call
     with `"\"1\""` returns `notModified`. Worth a skim: decisions 1, 3, 5, 8.
- **What later phases must wire:**
  - **3 (paper):** `plugin.getApiClient().getRoadNetworkQueryApi()` / `getRoadNetworkCommandApi()`. Every future
    completes on the api-client executor — `whenCompleteAsync(…, mainThread)` (R12) before touching Bukkit.
    - *Cache (`RoadNetworkCache`):* `tiles(world)` → for each `isBuilt()` tile `tileGraph(world, tileX, tileZ,
      cachedEtag)`; on `notModified()` keep the file, else store `body()` + `etag()`; snapshot =
      `RoadNetworkSnapshot.builder(world).addNodes(graph.nodes()).addEdges(graph.edges())…` over every tile, plus
      `meta(world)`: `meta.profiles().stream().map(RoadMapper::toSnapshotProfile)` and `meta.streets()` as they are.
    - *Build job:* `profiles()` → `RoadMapper.toBuilderProfiles(...)` → `new ProfileSet(profiles, scopeLookup)`;
      previous graph = `RoadMapper.toPreviousGraph(tileGraph(...).body())` for a tile in the `tiles(world)` list, else
      `NodeMatcher.PreviousGraph.EMPTY`; anchors = `RoadMapper.toAnchors(graph)` (+ neighbour tiles' Boundary nodes from
      their downloads); seeds = `seeds(world)` + `seedLocations(world, minX − 8, minZ − 8, maxX + 8, maxZ + 8)` +
      survey breadcrumbs (`surveys(world)`); after tagging, rebuild each `TileBuildResult.Edge` with `domainIds`/
      `regionIds` filled (records — construct new ones) and `upsertTileGraph(world, x, z, build)`; show
      `RoadTileUpsertResult` counts, `conflicts`, `deletedNodes` and `bumpedTileIds` (refresh those tiles too).
    - *Survey session:* stored stats = `profile.hasStats() ? SurveyStats.fromJson(profile.statsJson()) :
      SurveyStats.empty()` (2b decision 10: an unknown version throws — show the error, never overwrite); on Save:
      `createSurvey(new RoadSurveyCreate(world, profileId, startedAt, endedAt, sampleCount, breadcrumb,
      thisWalk.toJson()), actingUserId)` then `updateProfile(id, RoadProfileUpsert.of(existing, learned,
      merged.toJson()))` or `createProfile(RoadProfileUpsert.of(name, roadClass, cost, scopeTownIds, learned,
      merged.toJson()))`; seeds every `breadcrumb-seed-spacing` via `createSeed(RoadSeedCreate.survey(world, x, y, z,
      survey.id()))`.
    - *Dirty tracker:* `markDirty(world, RoadTile.tileCoordinate(x), RoadTile.tileCoordinate(z))` per tile in the
      30-second flush.
    - *Review (`/knk road …`):* `updateNode(id, RoadNodeUpdate.rename(name) | unnamed() | kind(k) | locked(b))`,
      `createAnchor(new RoadNodeAnchor(world, x, y, z, name))`, `mergeNodes(keep, merge)`, `updateEdge(id,
      RoadEdgeUpdate.street(streetId, continueFlag) | unlabelled() | profile(id) | flags(set) | costMultiplier(m))`,
      `recordEdge(new RoadEdgeRecord(...))`, `deleteEdge(id)`, `createSeed(RoadSeedCreate.admin(...))`,
      `deleteSeed(id)`, `searchEdges(new PagedQuery(1, 50, null, "length", true, Map.of("world", w, "stale",
      "true")))`. On failure unwrap the `CompletionException` → `RuntimeException` → `ApiException` and show
      `RoadMapper.error(e).map(RoadApiError::message).orElse(e.getMessage())`.
  - **5 (web app):** nothing from 2e (it talks to the API directly); the DTO records document the wire shapes.

---

## Phase 3 — knk-plugin paper: admin side (survey, build, review)

### 3.1 Config (R16)

`KnkConfig.NavigationConfig` (+ nested `SurveyConfig`, `BuilderConfig`, `TrailConfig`) with `defaults()` and
`validate()`, keys exactly as DESIGN §4; `ConfigLoader.loadNavigation`; back-compat constructors; `config.yml`
`navigation:` section; `ConfigLoaderNavigationTest` like the discovery one.

### 3.2 Extractions first (R8, R9, R10, R11, R25) — separate commits, callers delegate, tests green.

Plus the paper-side R4 fire points: `gateManager.fireStateChanged(id)` after `HealthSystem.destroyGate`/`respawnGate`,
the jam in `GateAnimationTask`, and the `GateCommand` destroyed/active toggles.

### 3.3 Wiring in `KnKPlugin`

- Promote to fields: `regionDomainResolver` (L689-697), `regionTracker` (L745). Note the double `CacheManager`
  construction (L363 and L466) — use the field as it is after L466; don't fix it here (flag it in the status).
- Construct (only if `navigation.enabled`) in a new `initializeRoads()` called after `initializeSiege()` (L822):
  `locationsDataAccess`, `streetsDataAccess`, `districtsDataAccess`, `structuresDataAccess` (R18; reuse if already
  present), `RoadNetworkCache`, `RoadDirtyTracker`, `RoadBuildQueue`, `RoadSurveyService`, `RoadOverlayRenderer`,
  `RoadAdminCommand`. **Register `road` inside `registerCommands()` (L709) with lazy suppliers** (`() -> roadAdmin…`),
  like `DiscoveryAdminCommand` does — `registerCommands()` runs before `initializeRoads()`, so a direct reference would
  be null. Listeners via the existing `registerEvents` style.
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
  blocks — from `GET api/road-network/seed-locations`, D12), capture chunks the BFS reaches via
  `world.getChunkAtAsync(x, z, false)` (**never generate terrain**) + main-thread extraction at `snapshot-chunks-per-tick` (R11 `TickBudget`), run `TileBuilder` on the
  api-client executor, tag `domainIds` on the main thread in budgeted batches (`RegionIds.at` R8 + R7), upload via
  `upsertTileGraph`, invalidate the cache for the tile, report a summary to the requester.
- `RoadBuildQueue` — ordered tiles (here / tile / radius / dirty / all), one job at a time, resumable (skips tiles whose
  `BuiltAt` is newer than the queue start on restart), throttled by TPS; progress in the action bar for the admin who
  started it.
- `RoadNetworkCache` — per world: tile list → conditional tile downloads (R17) → local file cache
  `plugins/KnightsAndKings/roads/<world>/<x>_<z>.json` (+ version) → `RoadNetworkSnapshot` (2d) rebuilt off-thread and
  swapped atomically; tiles refresh on start, after builds and every 10 min; **meta (profiles + street names) every
  60 s** — it's a few KB, and it's how a street renamed in the web app reaches navigation messages within a minute.
  `/knk road reload` forces both.
- `RoadSurveyService` + `RoadSurveySession` — `/knk road survey start|stop|cancel`; samples every
  `sample-period-ticks` only when on ground, walking (speed > 0.1 b/tick), not flying/riding/swimming; builds
  `SurveySample`s (cross-section via world reads on the main thread — at most 15 columns per sample); live action bar;
  on stop: `ProfileLearner` on (profile's stored stats + this survey) → chat review with clickable
  **Save / Merge into … / Discard** (R26 pattern) → `createSurvey` + `saveProfile`; breadcrumb stored with the survey;
  survey seeds every `breadcrumb-seed-spacing`.
- `RoadDirtyTracker` — listeners for `BlockPlaceEvent`, `BlockBreakEvent`, `EntityExplodeEvent`/`BlockExplodeEvent`,
  `BlockPistonExtend/RetractEvent` (MONITOR, ignoreCancelled): material in `ProfileSet` or the block is headroom of a
  road span in the current snapshot → mark tile; flush batched every 30 s via `markDirty`. WorldEdit (always present:
  `plugin.yml` depends on WorldGuard, which needs WorldEdit): `@Subscribe` to `EditSessionEvent` on WorldEdit's event
  bus; at `Stage.BEFORE_CHANGE` wrap `event.getExtent()` in an `AbstractDelegateExtent` whose `setBlock` records the
  tile of each position into a concurrent set (it can run off the main thread under FAWE); the 30 s flush drains it.
- `RoadOverlayRenderer` — `/knk road show [radius] [all]` per admin, ticker every 20 ticks: nodes as pillars, edges as
  polylines (R9 `ParticleDraw`), colours by street hash/status; only ±8 Y unless `all`; action-bar label of the
  looked-at node/edge.
- `RoadAdminCommand` — all DESIGN §7 subcommands (incl. `street … --continue` → `propagate`, and `reload`); node check like `DiscoveryAdminCommand.hasNode` (R15); tab
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

### Phase 3 status — done 2026-09-28, compiled by link 9 on 2026-09-29 (knk-plugin `claude/road-navigation` `9fe993a`, `efc9251`, `f71ec99`, `939baa1`, `0f6a206`, `f0385ad`, `4804561`, `138bfc4`, `b1665ff`, `3b5c408`, `8017e55`, `d46d564`, `cab864d`, `96f4c62`; on top of 2e's `4ffdd1a`; trunk `main` still `eb1d68c`)

**Live smoke test 2026-09-29/30 and 2026-10-01 — usable after builder/profile tuning, one confirmed gap:** manual
cleanup of duplicate junctions and stale nodes (merge, lock, recorded edges) does not survive a full tile rebuild —
pruned junctions/endpoints reappear. Needs a code fix (persist/replay cleanup, or better plaza/cluster recognition
so duplicates aren't produced). Full detail in `docs/guides/road-navigation-smoke-test.md` Findings.

> **Compiled 2026-09-29 (link 9, `68fa48c`):** the first real Gradle build of the branch (`./gradlew build -x
> deployToDevServer`, paper-api / WorldGuard / WorldEdit resolvable in the cloud since the developer allowed the two
> Maven hosts) compiled every Phase 3 file unchanged. Of knk-paper's 821 tests one failed: `RoadAdminCommand.complete`
> never offered a quoted profile/street name (the prefix match compared the typed word with the opening quote) — fixed;
> the same test expected an unsorted list. Gradle counts on `68fa48c`: knk-core **1374**, knk-api-client **174** (2
> skipped), knk-paper **821** (14 skipped), all green — the "developer to-do 1 and 2" below are done; only the live
> checks (3) remain.

- **What was built** (knk-paper; 59 files, +7 580 / −101 lines; every class in `P/roads/` unless noted):
  - **Config (§3.1, R16):** `P/config/NavigationConfig` — a *top-level* Bukkit-free record (decision 1) with nested
    `TrailConfig`, `SurveyConfig`, `BuilderConfig`, `defaults()`/`validate()`, keys exactly DESIGN §4, plus the
    mappings `routerParameters()`, `sessionParameters()`, `builder().buildParameters()`, `passabilityRules(collidable)`,
    `isOverlayMaterial(name)`; `KnkConfig.navigation()` (+ a back-compat 6-arg constructor);
    `ConfigLoader.loadNavigation`; `config.yml` `navigation:` section with the DESIGN defaults;
    `ConfigLoaderNavigationTest` (bundled config = defaults, overrides, config errors, older constructors).
  - **Extractions (§3.2), one commit each, callers delegate:** R8 `P/regions/RegionIds` (one lazily created WorldGuard
    `RegionQuery`; `applicable(Location)`, `at(Location)`, `at(World, x, y, z)`; `WorldGuardRegionTracker.getRegionNamesAt`,
    `WorldGuardRegionLookup.at` and `DomainDiscoveryListener.regionIdsAt` delegate; the tracker exposes `regionIds()`) ·
    R9 `P/utils/ParticleDraw` (`ring` moved verbatim, new `polyline(viewer, points, spacing, particle, data)`, `pillar`,
    `canSee`; `SiegeWorldPresenter.ring` delegates — the only siege edit besides R10) · R10 `P/utils/KnkLocations`
    (`toLocation`, `floorOf`; `SiegeBukkit` delegates) · R11 `P/utils/TickBudget` (`TickBudget(DoubleSupplier)`,
    `isLagging()`, `perTick(normal, lagging)`, `server()`, static `isServerLagging()`; the three `isServerLagging()`
    copies in `GateBlockScanTaskHandler` delegate) · R25 `P/gates/GatePassThroughRules.canPass(Player, CachedGateDoor)`
    / `isAdmin` (the listener delegates) · R4 paper fire points: `HealthSystem.destroyGate`/`respawnGate`, the jam and
    un-jam in `GateAnimationTask.handleJamTracking`, `GateCommand` repair (`setIsDestroyed(false)`) and the active toggle
    call `gateManager.fireStateChanged(id)`.
  - **Wiring (§3.3):** `KnKPlugin` — `regionDomainResolver` and `regionTracker` promoted to fields (+ getters
    `getRegionDomainResolver()`, `getRegionTracker()`, `getRoadNetworkCache()`); R18 `locationsDataAccess`,
    `streetsDataAccess` (with a new `StreetCache` — `CacheManager` has none), `districtsDataAccess`,
    `structuresDataAccess` as fields, constructed in `initializeRoads()`; `initializeRoads()` runs after
    `initializeSiege()` and only when `navigation.enabled` (cache → dirty tracker → overlay → build queue → survey
    service, then `start()` each); `road` registered inside `registerCommands()` with lazy suppliers (a null service =
    "navigation disabled") and its tab completer through `KnkAdminCommand.registerSubcommand(metadata, executor,
    tabCompleter)`; `onDisable` stops survey (discard) → build queue → overlay → cache → dirty tracker (one synchronous
    flush, 5 s cap) before `apiClient.shutdown()`; `plugin.yml` `knk.admin.road` (child of `knk.admin`) and
    `knk.navigate` (default true). The double `CacheManager` construction (L383/L486) is flagged in a comment, not fixed.
  - **Classes (§3.4):**
    - `RoadNetworkCache` — per world `tiles(world)` → conditional `tileGraph` per built tile (no request at all when the
      listed version equals the cached one; 304 keeps the file); file cache `plugins/KnightsAndKings/roads/<world>/
      <x>_<z>.json` through `RoadTileCache` (own v1 JSON of the knk-core records via Gson, atomic writes, unreadable
      files = absent) keyed by `TileKey`; snapshot rebuilt on the api-client thread and swapped atomically; unresolved
      edge ids logged; `warmCache(regionIds())`; tiles every 10 min, meta every 60 s (rebuild only when the meta
      changed); `reload(world)`, `refreshTiles`, `refreshMeta`, `invalidateTile(key)`, `invalidateTileId`,
      `addListener(world)` (main thread); `roadMaterialNames()` for the dirty tracker.
    - `RoadDirtyTracker` + pure `DirtyTiles` — MONITOR/ignoreCancelled listeners for place, break, entity/block
      explode, piston extend/retract; a change matters when its material is a floor material of an enabled profile or
      the block is a road cell / one of its two headroom blocks in the current snapshot (`DirtyTiles.RoadCells`,
      packed `BlockKey`s of every geometry point and the cells between); WorldEdit `EditSessionEvent` at
      `BEFORE_CHANGE` wraps the extent in an `AbstractDelegateExtent` whose `setBlock` marks the tile (thread-safe);
      flush every 30 s with one `markDirty` per tile, failures re-marked.
    - `RoadOverlayRenderer` + pure `OverlayColors` — `/knk road show [radius] [all]` per admin, every 20 ticks: edges as
      DUST polylines (street stride colour, unlabelled grey, stale orange, closed red, no-gps purple), gate crossings a
      yellow pillar, nodes as pillars by kind (named = green, taller), ±8 blocks of the viewer's height unless `all`,
      action-bar label of the looked-at node/edge (12 blocks along the view ray, `Snapper.snap`).
    - `ChunkSnapshotSurfaceGrid` (thin Bukkit face: `capture(ChunkSnapshot, cx, cz)`, `bukkitCollidable()`) over the
      pure `CompactSurfaceGrid` + `SpanExtractor` + `CompactSpans` — per chunk a sorted `long[]` of span keys with an
      interned `short` material id and a flags byte (stair/slab, third-block-above passable, gate); the grid answers
      `isSolid` = stored span, `isPassable` from the headroom the extraction required and the third-block flag,
      `isHazard` false, `floorMaterial` of a non-span throws; `unknownQueries()` counts out-of-contract asks (the test
      proves 0 for the real `TileBuilder`). `frontierChunks(region)` = uncaptured 8-neighbours of chunks with a span on
      the matching border.
    - `GateCellsIndex` — every door's `closedFootprint` of the world → door id (R3, D9).
    - `RoadBuildJob` — inputs (profiles, previous graph from the cache or a download, this tile's Anchor nodes via
      `RoadMapper.toAnchors`, seeds = API seeds + survey breadcrumbs every 8 blocks + `seedLocations` box (D12, when
      `seed-from-domains`) + neighbour tiles' Boundary nodes as seeds) → capture (chunks around every seed, then the
      frontier, `getChunkAtAsync(x, z, false)`, `world.isChunkGenerated` first, `snapshot-chunks-per-tick` halved under
      lag, cap 1 600 chunks) → `TileBuilder.build` on the queue's build thread → region ids every 4 blocks of every
      edge on the main thread in `TickBudget` batches (200/50 per tick) → `warmCache` → domain ids from
      `getDomainByRegionIdNoRefresh` → edges rebuilt with `domainIds`/`regionIds` → `upsertTileGraph` → cache
      `invalidateTile` + bumped tiles → coverage misses (`CoverageCheck.misses` on the tile's on-road breadcrumbs) →
      `Outcome`. Scoped profiles get a `ScopeLookup` precomputed per captured chunk (Town region at the chunk centre).
    - `RoadBuildQueue` + pure `BuildQueueState` — `enqueue(sender, tiles, label)`, `enqueueDirty`, `enqueueAll`
      (API tile rows ∪ seed tiles ∪ domain-Location tiles inside the world border), `tilesWithin(world, x, z, r)`
      (nearest first), `status`, `cancel`, `describe()`; one job at a time, next only while not lagging, own single
      daemon build thread `knk-road-build`; persisted to `roads/build-queue.json` and resumed on start, skipping
      tiles whose `builtAt` is newer than the queue start; action-bar progress + per-tile chat summary (counts,
      disappeared nodes, street conflicts, warnings, coverage misses — each a clickable `/knk road goto x y z`).
    - `RoadSurveyService` + pure `RoadSurveySession`, `SurveySamplingGate`, `CrossSectionSampler` — tick every
      `sample-period-ticks`; a sample only when on ground, not flying/gliding/riding/swimming and moving ≥ 0.1
      blocks/tick, one per new floor block; floor under the feet through overlays, cross-section perpendicular to the
      walking direction (movement, else yaw) at the standable height nearest the previous column (|Δy| ≤ 1, walls and
      drops end the side), 15 columns max; live action bar (`ProfileLearner` on the samples so far every 40 ticks
      after 5 samples); stop → learner on stored stats + walk → review with clickable **Save / Merge into… / Discard**
      (unknown stats version: shown, never overwritten, save-as-new offered); Save = `updateProfile(RoadProfileUpsert.
      of(existing, learned, merged))` or `createProfile(of(name, Road, 1.0, [], learned, merged))` → `createSurvey`
      (breadcrumb, `X-Acting-User-Id` from the user cache) → Survey seeds every `breadcrumb-seed-spacing` → coverage
      misses against the current snapshot; `record start|stop [street]|cancel` → `recordEdge` (RDP-simplified floor
      polyline, width 2, region ids along it). Sessions die on quit / world change / shutdown.
    - `RoadAdminCommand` + `RoadMessages` (R26 pattern) — every DESIGN §7 subcommand: `survey start|stop|cancel|save
      [name]|merge <profile>|discard`, `profile list|show|role|ambiguous|enable|disable` (PUT with `statsJson = null`
      keeps the stats), `build here|tile <x> <z> [world]|radius <r>|dirty [world]|all [world]|status|cancel`, `seed
      add [note]|remove <id>|list [world]`, `show [radius] [all]|hide`, `street <street> [edgeId] [--continue]`
      (street by id, meta name, or `StreetsQueryApi.search`; "here" = the edge under the admin within 6 blocks),
      `node name|unname|merge|anchor [name]|lock|unlock [id]`, `record start|stop [street]|cancel`, `edge set <id|here>
      cost|oneway|nogps|close|open|profile|unlabel`, `edge delete <id>`, `tiles [world] [page]` (dirty first,
      teleports), `reload`, `status`, `why` (answers "Phase 4"), `goto <x> <y> <z>` (the click target,
      `teleportAsync`); node check like `DiscoveryAdminCommand.hasNode`; `complete(sender, args)` tab completion.
- **Reuse:** R3, R4, R7, R8, R9, R10, R11, R12 (`MenuService.mainThreadExecutor` everywhere), R13
  (`registerSubcommand` with a tab completer — no `onTabComplete` edit was needed, see discrepancies), R15, R16,
  R17 (through the 2e port), R18, R25, R26, R27 (start/stop `BukkitTask` shape), R28 (`SiegeFloor` via `KnkLocations`),
  2b-2e as wired in their notes (`SurveySample.of`, `SurveyStats`, `ProfileLearner`, `TileBuilder`, `PassabilityRules`,
  `ProfileSet`, `NodeMatcher.PreviousGraph`, `RoadNetworkSnapshot.builder`, `Snapper.snap`, `CoverageCheck`,
  `RoadMapper.*`, `Rdp`). Nothing under `C/**` or `A/**` was changed.
- **Tests:** knk-core **1374 → 1374**, knk-api-client **174 → 174** (2 skipped), both via the §0.4 scratch build
  (unchanged: nothing there was touched). knk-paper: **not compiled, not run here** (paper-api / WorldGuard / WorldEdit
  unresolvable — proxy denies `repo.papermc.io` and `maven.enginehub.org`, same as links 1-6). Instead the scratch
  build got a third project `paperpure` whose `sourceSets` whitelist the Bukkit-free paper files (`NavigationConfig`,
  `TickBudget`, `TileKey`, `RoadTileCache`, `RoadMessages`, `DirtyTiles`, `OverlayColors`, `CompactSpans`,
  `SpanExtractor`, `CompactSurfaceGrid`, `SurveySamplingGate`, `CrossSectionSampler`, `BuildQueueState`,
  `RoadSurveySession`) with Adventure 4.17 from Maven Central and a stub `org.bukkit.Bukkit.getTPS()` next to the
  `Vector` stub: **34 tests, 0 failures** (`NavigationConfigTest` 4, `TickBudgetTest` 3, `TileKeyTest` 2,
  `RoadTileCacheTest` 3, `RoadMessagesTest` 2, `DirtyTilesTest` 3, `OverlayColorsTest` 2, `CompactSurfaceGridTest` 4
  incl. the real `TileBuilder` on a 3-wide road with a closed gate → door 7 on the edge, 0 unknown queries,
  `SurveySamplingGateTest` 2, `CrossSectionSamplerTest` 3, `BuildQueueStateTest` 3, `RoadSurveySessionTest` 3).
  Written but **not run** (need paper-api + Mockito): `ConfigLoaderNavigationTest` 6, `GatePassThroughRulesTest` 3,
  `ParticleDrawTest` 4, `RoadDirtyTrackerTest` 3, `RoadAdminCommandTest` 6 — 17 test files added in knk-paper in all.
  The §3.5 list is covered except `RoadSurveySessionTest`'s gates, which are in the runnable set.
- **Decisions to review** (numbered; each cheap to change):
  1. `NavigationConfig` is a top-level record in `P/config` rather than `KnkConfig.NavigationConfig`: `KnkConfig`
     imports `org.bukkit.GameMode`, and a nested record could not be compiled and tested in the cloud's Bukkit-free
     scratch build. `KnkConfig.navigation()` is the access path either way.
  2. `RegionIds` lives in `P/regions/` (plan §2 R8) — the handoff and tracker said `P/utils/`; the plan wins. Its
     `at()` excludes `__global__` for every caller (the tracker never filtered; WorldGuard's `RegionResultSet`
     doesn't iterate the global region, so no behaviour changes).
  3. The tile builder runs on the build queue's **own single daemon thread** (`knk-road-build`), not the api-client
     executor: `KnkApiClient` exposes no executor getter (adding one is an `A/` change) and a multi-second CPU job on
     the shared pool would stall API callbacks. Uploads/downloads still complete on the api-client executor.
  4. Chunk capture = the 3×3 chunks around every seed, then repeatedly `CompactSpans.frontierChunks` (uncaptured
     neighbours of chunks holding a span on the matching border) until nothing is left or 1 600 chunks — a chunk-
     granular superset of "the chunks the BFS reaches", bounded by the tile + margin.
  5. Neighbour tiles' Boundary nodes are **seeds** (not anchors): an anchor outside the tile would be flagged
     "off road" by `SkeletonGraph`; as seeds they make the BFS cross the border (DESIGN §5.4 lists them as seeds).
  6. Cache file format: own v1 JSON of the knk-core records (`RoadTileCache`) with Gson (bundled by the server, already
     used by knk-paper) rather than re-serialising the api-client DTOs: the client's Jackson mapper isn't on knk-paper's
     compile classpath and the DTO→core direction exists but not core→DTO for tile graphs. A file of another version or
     unparsable = re-download.
  7. `refreshTiles` skips the conditional request entirely when the API's tile list shows the same `version` as the
     cached graph (the list is one request; a 304 per tile would be N).
  8. Snapshot rebuilds happen on the api-client thread that completed the last download (off the main thread, as the
     plan asks); listeners (dirty tracker's road cells) run on the main thread.
  9. A block change "matters" (dirty) when its material is a floor material (Surface/Edge/Accent, not Overlay) of an
     enabled profile **anywhere**, or it is a road cell / one of the two headroom blocks above one in the current
     snapshot; `BlockPlaceEvent` checks both the placed block and the replaced state. WorldEdit changes mark every
     changed block's tile regardless of material (bulk edits; conservative).
  10. Overlay colours: 16-entry palette with `id * 7 mod 16` (adjacent street ids differ); particles float 1.1 above
      the floor block; node pillars 2 (3 when named); the looked-at label uses the point 12 blocks along the view ray.
  11. Build queue persistence: `roads/build-queue.json` (pending tiles, start time, requester, label); resume skips
      tiles the API lists as built after the start (DESIGN §9 "progress per tile in BuiltAt").
  12. `build all <world>` = API tile rows ∪ tiles of every admin/survey seed ∪ tiles of every domain Location inside
      the world border (a tile with none of these has no seed and would build nothing).
  13. Domain Location seeds use `y − 1` (a Location's y is where a player stands; the floor is one below); survey
      seeds and breadcrumbs are floor blocks already. `MaskBuilder.snapSeed` looks ±4 anyway.
  14. `ScopeLookup` for scoped profiles = the Town whose region contains the **chunk centre** of each captured chunk
      (one WorldGuard lookup per chunk on the main thread, before the off-thread build) — not per column.
  15. Survey sampling: one sample per new floor block (not per period while standing on the same block); every sampled
      point is an `onRoad` breadcrumb (the admin is told to walk roads); the first tick of a walk never samples
      (no movement yet). Speed threshold 0.1 blocks/tick from DESIGN §5.3.
  16. A new profile from a survey is created as class `Road`, cost 1.0, no scope, enabled — class/cost/scope are edited
      in the web app (Phase 5) or `/knk road profile`. `save [name]` names it; `merge <profile>` re-targets the review.
  17. Survey/breadcrumb coverage after Save uses the **current** snapshot (the tile may not be rebuilt yet); the build
      summary repeats it after the rebuild with the tile's breadcrumbs.
  18. Recorded stretches: RDP ε 0.75, width 2, length = the walked polyline's length, region ids sampled at every
      geometry point, no profile; street optional.
  19. Clickable teleports go through a new `/knk road goto <x> <y> <z> [world]` subcommand (`teleportAsync`, admin
      node) — `/knk tp` only teleports to players.
  20. `edge set <id> …` for an edge not in any loaded snapshot still works with an empty flag baseline (so `close`
      on an unknown id sets only `Closed`).
- **Discrepancies found:**
  - `KnkAdminCommand.registerSubcommand(metadata, executor, tabCompleter)` already exists (used by lootboxes), so the
    plan's "add a `road` branch to `onTabComplete`" (R13) was unnecessary — the completer is registered, not branched.
  - `CacheManager` has no `StreetCache`; `createStreetsDataAccess` needs one, so `initializeRoads()` constructs it.
  - `KnkApiClient` has no executor getter (decision 3).
  - The handoff listed `RegionIds` under `P/utils/`; plan §2 says `P/regions/` (decision 2).
  - `SessionParameters` has no `withSprintSpeed`; `NavigationConfig.sessionParameters()` uses the canonical constructor.
  - `MaskBuilder.snapSeed`'s direct `SiegeFloor` scan asks `isSolid` of arbitrary cells, which the compact grid
    answers "false" (only spans are solid) — the radius search that follows finds the span, so seeds still snap.
  - Cloud network unchanged (papermc/enginehub 403). KNG-17 still not on `main`.
- **Developer to-do (local; the real compile of this phase):**
  1. `git pull` knk-plugin `claude/road-navigation`, then `./gradlew build -x deployToDevServer`. Expect import/signature
     slips in knk-paper — likely spots, in order: `RoadAdminCommand` (Adventure `sendMessage(Component)` overloads,
     the `switch` blocks), `RoadBuildJob` (`getChunkAtAsync(int, int, boolean)`, `Chunk.getChunkSnapshot(false, false,
     false)`, `World.isChunkGenerated`), `RoadDirtyTracker` (WorldEdit 7.2.13: `BlockVector3.getBlockX()`,
     `AbstractDelegateExtent.setBlock` generic signature, `WorldEdit.getInstance().getEventBus()`), `RoadOverlayRenderer`
     (`Particle.DustOptions`, `Player.getEyeLocation`), `RoadSurveyService` (`Player.isOnGround/isFlying/isGliding/
     isInsideVehicle/isSwimming/isInWater`), `ChunkSnapshotSurfaceGrid.bukkitCollidable` (`Material.isCollidable`),
     `KnKPlugin.initializeRoads` (field/getter names). Each is a one-line fix.
  2. `./gradlew :knk-paper:test` — the 17 new test files; `RoadAdminCommandTest` and `RoadDirtyTrackerTest` mock
     Adventure/Bukkit types and may need small adjustments.
  3. Live (dev server, `navigation.enabled: true`, API on `claude/road-navigation` with the Phase 1 migration applied):
     (a) `/knk road status` → "enabled", tiles 0; (b) `/knk road survey start "Kardenna main street"`, walk 2-3
     minutes, watch the action bar (samples climb only while walking on the ground), `/knk road survey stop` → proposal
     with roles/width, click **Save** → profile + survey + seeds messages; repeat for a wilderness road and a trail
     (`survey start` with no name → `save <name>`); (c) `/knk road profile list|show`; (d) `/knk road build radius
     1500` (include a tunnel or bridge if one exists) → action-bar progress, per-tile summary with clickable teleports;
     (e) `/knk road show` → coloured polylines, pillars at junctions, action-bar label when looking at an edge; `/knk
     road show all` on a bridge; (f) `/knk road street "<street>" --continue` on an edge you stand on → "and N more";
     (g) break a road block → within 30 s `/knk road tiles` lists the tile DIRTY; `/knk road build dirty` → names kept;
     (h) WorldEdit `//set` across a road → tile dirty; (i) `/knk road node name Market` + `/knk road seed add` +
     `/knk road edge set here close` → overlay turns red; (j) `/knk road reload`; (k) restart mid-`build all` → the queue
     resumes and skips tiles built before the restart.
- **What later phases must wire:**
  - **4 (`/navigate`):** `plugin.getRoadNetworkCache().snapshot(world)` (floor-y network, swapped atomically;
    `addListener` for swaps), `NavigationConfig` via `config.navigation()` (`routerParameters()`, `sessionParameters()`,
    `trail()`), `plugin.getRegionTracker().regionIds().at(player.getLocation())` for `DomainAvailability`,
    `plugin.getRegionDomainResolver()`, `GatePassThroughRules.canPass` as the `PassRule`, `gateManager.addStateListener`
    (fires now on every mutation path), `ParticleDraw.polyline(player, points, spacing, Particle.DUST, dustOptions)` for
    the trail, `RoadMessages` conventions, `knk.navigate` node (declared, default true), `/knk road why` to implement.
  - **5 (web app):** nothing from the plugin; profiles created in game are class Road ×1.0 without scope until edited
    there; `StatsJson` stays opaque.

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
8. Live changes: `GateStateListener` (R4) → sessions whose route contains that door re-plan; `SiegeMatchObserver`
   (R24) `areaLockdownStarted`, `roundReleased` (gate lockdown released), `objectiveCaptured` (gate state on capture)
   → re-plan affected sessions; domain cache refresh → re-plan all (rate limited); **D13 safety net:** every 40 ticks
   re-evaluate the gate verdicts of each active route and re-plan on any change.
9. **Siege read-only accessors** (coordinate first, §0.5): `KnKPlugin` field + getter for `siegeGates` (R24) and the
   R39 predicate extraction; nothing else in siege changes. `NavigationEligibility` (R23) ends sessions when the player joins a siege lobby (`lobbyOf`),
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

### Phase 4 status — done 2026-09-29 (knk-plugin `claude/road-navigation` `68fa48c` (Phase 3 compile fix), `be5df0f` (trunk merge), `7500f44`, `be329f7`, `40ee42e`, `aa71dae`, `57c1605`, `05f5639`, `0fd5f43`, `cdc73d1`, `9717036`, `cfe49f4`, `4e3f8af`; on top of Phase 3's `96f4c62` merged with trunk `main` `27b4236`)

**Live smoke test 2026-10-01 — paused with findings** (full detail in
`docs/guides/road-navigation-smoke-test.md` → Findings → "Phase 4/5 — live smoke test (2026-10-01)"):
basics, tab completion and permission checks pass; destination resolution and guidance mostly work but the §6.2
off-road/direct-mode leg draws a straight line through terrain instead of a walkable path, doesn't re-evaluate as the
player moves away from the goal, the §6.3 "already in region" check doesn't fire, and region-destination goal
selection (District) looks arbitrary rather than closest-to-player. Testing stopped before Availability/Ending/
Admin/Performance pending a fix.

- **Start condition and merge:** KNG-17 was on `origin/main` (`27b4236`, merged 2026-09-28). Phase 3 was compiled
  first (`68fa48c`, see the Phase 3 note above), then trunk merged in (`be5df0f`, no rebase). Conflicts: `KnkConfig` /
  `ConfigLoader` (teleport and navigation sections both kept — the record is now 8 fields with a compact constructor
  defaulting `teleport` and `navigation`; the 4-, 5-, 6- (`privateMessages, discovery`) and 7-arg (`…, teleport,
  discovery`) constructors all stay) and `SiegeBukkit` imports (R10 delegation kept, teleport's
  `teleport(Player, Location)` kept). `KnKPlugin`, `SimpleRegionTransitionService` and `WorldGuardRegionTracker`
  auto-merged: teleport's `previewAccess` reaches `DomainAccessEvaluator` through the private checks Phase 2a
  rewrote, the tracker keeps R8's `RegionIds` plus trunk's `setDenialBypass`/`bypassesDenials`/`previewAccess`, and
  teleport's inline `create*DataAccess` calls in `createSpawnCommand` became the Phase 3 fields
  (`ensureDomainDataAccesses()`, R18: one instance each, shared by `/spawn`, the road code and `/navigate`).
- **What was built** (52 files, +4 444 / −183 since the merge; one commit per item):
  - **R22** (`7500f44`): `C/util/BlockProbe` (moved from `C/teleport`, unchanged); `SurfaceGrid extends BlockProbe`
    (its five duplicate declarations dropped); teleport's `SafeLocationFinder`, `BukkitBlockProbe`, `TeleportService`
    and seven tests only change an import.
  - **R21** (`be329f7`): `C/util/NamedTargets<T>` (name/type accessors + optional id accessor: bare name, `type:name`,
    `type:#id`, `#id`; `suggestions`; one-word-at-a-time `complete`); `WarpTargets` is a static wrapper bound to
    `KnkTeleportDestination` — `WarpTargetsTest`, `WarpCommandTest` unchanged. `NamedTargetsTest` (7).
  - **R20** (`40ee42e`): `C/navigation/DomainLocationResolver` (ports `DomainFetch<TownDetail|DistrictDetail|
    StructureDetail>` + teleport's `LocationLookup`; `townLocation`/`districtLocation`/`structureLocation` = the moved
    `ownLocation` rule; `town`/`district`/`structure`/`byType` → `DomainPlace(id, name, domainType, wgRegionId,
    location)`); `SpawnDestinationResolver.create` builds one and hands its three lookups to `SpawnPointResolver` —
    `SpawnDestinationResolverTest` unchanged. `DomainLocationResolverTest` (5).
  - **R6 follow-up** (`aa71dae`): `previewAccess` javadoc + a characterisation test (entry/exit messages from the
    evaluator, `null` when allowed, no entered-domains callback).
  - **R24** (`57c1605`): `KnKPlugin.siegeGates` field + `getSiegeGates()`. **R39** (`05f5639`):
    `SiegeGateController.canCarryNonMember(CachedGateDoor)` (public, read-only: applied lockdown + pass-through
    service wired + (`PreLockdownView` → true | `PassThroughOnly` → the door was open and not destroyed before the
    lockdown)); `tryNonMemberPassThrough` and `carryNonMemberThrough` use it and keep their own member /
    current-state checks (behaviour unchanged; siege + gate tests 206 green). The only two siege edits.
  - **Helpers** (`0fd5f43`): `LocationsDataAccess.searchAsync(PagedQuery)`, `StreetsDataAccess.searchAsync` (R18);
    `GatePassThroughRules.canPass(boolean admin, boolean useNode, door)` (R25; the `Player` form delegates).
  - **`P/events/`** (`cdc73d1`): `NavigationStartEvent` (cancellable), `NavigationRerouteEvent(reason, detail)`,
    `NavigationArriveEvent`, `NavigationEndEvent(reason)` — the `GateDoorInteractEvent` style.
  - **`P/navigation/`** (`cdc73d1`, `9717036`, `cfe49f4`):
    - `NavigationMessages` (R26; every DESIGN §6 string; `bossBar()` = "→ Merchantstreet · 340 m · ~1 min").
    - `NavigationHud` — Adventure `BossBar` per player (label = next maneuver within 20 blocks, else the destination;
      progress = travelled / total), action-bar arrow (`⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉` from the relative bearing, pure `arrow()`).
    - `TrailRenderer` — the next `trail-length` blocks from the projection every `trail-period-ticks`, one particle
      per 1.5 blocks at floor + 1.2 (`ParticleDraw.polyline`, R9); straight legs player → road and road → target
      (3-block spacing, other colour, heights via `KnkLocations.floorOf` R10/R28) when the gap is > 2 blocks; half
      length under lag (`TickBudget` R11); direct-mode trail = one leg.
    - `NavTarget` (catalogue entry: LOCATION / TOWN / DISTRICT / STRUCTURE / STREET / NODE) and `Destination`
      (POINT / REGION / STREET / NODE, feet coordinates).
    - `NavigationDestinations` — Towns/Districts/Structures from `DomainCatalogDataAccess.searchAsync` (R19) and
      Locations from `LocationsDataAccess.searchAsync` (R18), paged (200, ≤ 25 pages), refreshed in the background
      every 60 s (the first stale call starts it, never awaited) and by `/knk cache refresh`; the labelled streets and
      named nodes of the world's snapshot; `resolve` / `complete` / `isComplete` through `NamedTargets`; `locate(target,
      mode, world)` → a Location's point, a domain's spawn Location through `DomainLocationResolver` or its WorldGuard
      region (`region`, or no Location), a street, a node — or `OTHER_WORLD` / `NO_LOCATION` / `NOT_FOUND`.
    - `NavigateCommand` (`TabExecutor`, `registerTabCommand("navigate")`, alias `nav`, node `knk.navigate` checked like
      `DiscoveryAdminCommand.hasNode`, R15): `/navigate <destination…> [spawn|region]`, `stop`, no-arg status;
      ambiguity → clickable `type:name` choices; unknown → "Did you mean" with clickable suggestions; completion =
      `stop` + names one word at a time + `spawn|region` after a complete name.
    - `NavigationEligibility` (R23: loading / frozen / siege-lobby predicates; `siegeMembers(Supplier<SiegeService>)`).
    - `RegionShapes` port + `WorldGuardRegionShapes` (polygon points + y band, cuboid corners; main thread).
    - `NavigationAccess` (`PolicyFactory`): per request `CompositeAccessPolicy.of(StaticFlagsAvailability,
      GateAvailability, DomainAvailability)`; on the main thread it reads the player's regions (`RegionIds.at`, R8),
      the two pass-through nodes, and **every door the network mentions once** (`GateManager.getGate` → `GateView`
      from the effective accessors R5, `SiegeGateController.isLocked` + `canCarryNonMember` R24/R39) so the policy
      needs no Bukkit or gate-cache access on the routing thread; `DomainLookup` = `getDomainByRegionIdNoRefresh`,
      falling back to `resolveRegionsFromApi` (3 s cap) off-thread (R7); bypass = `regionTracker::bypassesDenials`
      (KNG-17's `knk.region.bypass` predicate, R6).
    - `NavigationService` (`Deps` record so tests fake the server; implements `SiegeMatchObserver`): one core
      `NavigationSession` per player; goals per destination kind (point → `snapFloor`; node → `SnapPoint.atNode`;
      region → `RegionClosestPoint.goals`, refused "already in X" via `containsFloor`; street → the nearest point of
      each of the street's edges, multi-goal); refusals "too far from a road" / "X is too far from any road";
      **direct mode** within `max-snap-distance` (also for node/street/region targets), and the last off-road leg to
      the real target runs as direct mode once the routed session reaches the road's end; routing (`AStarRouter.
      routeOrExplain`) on a single daemon thread `knk-navigation-routing` with a policy built on the main thread,
      results delivered on the main thread with a per-session generation guard; every `NavigationEffect` applied in
      an exhaustive `switch`; ticker every tick (`tick()` → guidance, trail every period, HUD every 10 ticks,
      maneuver chat line once per maneuver within 20 blocks); **live changes** — `onGateChanged(doorId)` (R4
      listener, hopped to the main thread): sessions whose route or blocking edge holds the door re-check at once,
      others ask for an improvement; `onAvailabilityChanged()` (siege `areaLockdownStarted` / `objectiveCaptured` /
      `roundReleased` / `matchEnded`, R24; domain cache refresh hook) re-checks every session; `onNetworkChanged
      (world)` re-derives the goals and asks for a fresh route (`DESTINATION_LOST` when the target is gone);
      **D13** every 40 ticks each route's steps are re-judged with a fresh policy (first BLOCKED → `onElementBlocked`;
      a partial route whose blocking edge opened → `onElementOpened`); ends on `stop`, quit, death, world change,
      teleport > 16 blocks (`NavigationListener`, MONITOR), siege lobby membership (every 40 ticks and on
      `lobbyChanged`), timeout; arrival = the session's end point, the real target (direct), or `containsFloor` of
      the region; the four events; `explain(as, destination, out)` for `/knk road why`.
    - `NavigationListener` (quit / death / world change / teleport).
  - **`RoadAdminCommand`**: `why <destination> [--as <player>]` (resolves through the catalogue, then
    `NavigationService.explain`: "Open route: 340 m, 5 edges" + every non-open verdict, or "No open route — the West
    Gate is closed. Partial route: 120 m" + every non-open verdict of the all-open route; "Direct mode" / refusals);
    `setNavigation(...)` (lazy suppliers, no constructor change); tab completion of destinations after `why`.
  - **`KnKPlugin.initializeNavigation()`** after `initializeRoads()` (needs the cache, tracker, resolver, gate manager
    and domain catalogue): builds the catalogue (+ `/knk cache refresh` hook), `NavigationAccess`, eligibility, the
    routing executor, HUD, trail, the service; registers the gate listener, the siege observer, the snapshot listener,
    the domain-refresh hook and `NavigationListener`; `onDisable` stops the service (every session ends `STOPPED`)
    and the routing thread before the road cache. `/navigate` registered in `registerCommands()` with lazy
    suppliers. `plugin.yml`: `navigate` (alias `nav`); `knk.navigate` was declared in Phase 3.
- **Reuse:** R5, R6, R7, R8, R9, R10, R11, R12 (`MenuService.mainThreadExecutor` for every hop), R14
  (`registerTabCommand`), R15, R16 (`config.navigation()` → `routerParameters()`, `sessionParameters()`, `trail()`),
  R18, R19, R20, R21, R22, R23, R24, R25, R26, R27 (start/stop `BukkitTask` shape), R28, R39, 2d's whole router /
  session / explainer / maneuver / ETA surface as its "→ 4" note prescribes, 3's cache / config / `RegionIds` /
  `GatePassThroughRules` / `ParticleDraw`. Nothing in §2 duplicated. No new dependency.
- **Tests (Gradle, real):** baseline on `68fa48c` (Phase 3 compiled) knk-core **1374**, knk-api-client **174** (2
  skipped), knk-paper **821** (14 skipped); after the trunk merge (`be5df0f`, KNG-17's tests) **1532 / 184 / 1027**;
  after Phase 4 **1545 / 184 / 1074** — 0 failures everywhere. New: knk-core `NamedTargetsTest` 7,
  `DomainLocationResolverTest` 5, `SimpleRegionTransitionServiceTest` +1; knk-paper `NavigationServiceTest` 16
  (start, too-far refusals, direct mode + arrival, cancellable start event, re-route on a gate closing with the reason,
  the D13 re-check without an event, denied destination domain → partial route to its edge, ends on siege join / long
  teleport / death / stop, arrival event, region already-inside, region and street goals, network swap),
  `NavigateCommandTest` 9, `NavigationDestinationsTest` 6, `NavigationMessagesTest` 5, `NavigationHudTest` 4,
  `TrailRendererTest` 7, on a small in-test network (`NavigationTestNetwork`: knk-paper cannot see knk-core's
  `NetworkFixture`). Teleport, siege, gate, discovery and Phase 3 tests unchanged and green. `ArchitectureGuardTest`
  green with `C/navigation/DomainLocationResolver` and `C/util/NamedTargets`/`BlockProbe`.
- **Decisions to review** (numbered; defaults taken, all reversible):
  1. **Routing thread:** an own single daemon thread (`knk-navigation-routing`), not the api-client executor
     (`KnkApiClient` has no executor getter — Phase 3 decision 3); A\* on a town-sized network is well under a
     millisecond, so one thread serves every player.
  2. **Policy built on the main thread, gates pre-read:** `NavigationAccess.policyFor` reads every door the network
     mentions once per request (dozens, cheap) so the routing thread never touches Bukkit, `GateManager` or the siege
     controller; only the domain lookup may call the API off-thread (3 s cap, then "unknown = allowed").
  3. **Bypass = the region tracker's predicate** (`bypassesDenials`: `knk.region.bypass` or an in-flight staff
     teleport) as `DomainAvailability`'s bypass; the evaluator stays pure and stateless (`new
     DomainAccessEvaluator()` — the class, not the instance, is the single source of truth).
  4. **Direct mode also for node / street / region targets** within 48 blocks (DESIGN §6.2 names "the target"); and a
     routed session that reaches the road's end more than `arrive-distance` from the real target continues as direct
     mode for the last leg — arrival is at the target, not at the snap point.
  5. **Street goals** = the nearest point of *each* of the street's edges (sampled every 2 blocks), multi-goal A\*:
     the router picks the cheapest reachable one.
  6. **Region destinations have no world in the API:** the player's world's WorldGuard manager is asked; an unknown
     region reads "X has no location and no region to navigate to".
  7. **Catalogue refresh:** the API part loads at start and refreshes every 60 s in the background (started by the
     next stale call, never awaited — tab completion stays synchronous) and on `/knk cache refresh`; streets come
     from the snapshot's meta (only a street with edges can be navigated to — `StreetsDataAccess.searchAsync` exists
     per R18 but is not used here); page size 200, at most 25 pages (5 000 places).
  8. **Maneuvers:** one chat line per maneuver when it comes within 20 blocks; the boss bar label switches to the
     maneuver text within 20 blocks, else shows the destination.
  9. **D13 cadence:** every 40 ticks per session with a fresh policy; a gate event for a door on the route (or on the
     blocking edge of a partial route) re-checks immediately, any other door only asks for an improvement (the
     session's 200-tick rate limit applies); siege observer hooks and the domain refresh re-check every session.
  10. **Network swap:** goals are re-derived on the new snapshot and an improvement route requested (the current
      route keeps guiding unless the new one is > 15 % shorter — its polyline stays valid data); a destination that
      no longer resolves ends the session `DESTINATION_LOST`; a target now within 48 blocks switches to direct mode.
  11. **`NavigationStartEvent`** fires after the goals are resolved and before the first route, so a cancelling
      listener costs no routing; the canceller tells the player why.
  12. **Arrival sound:** Adventure `entity.player.levelup` (0.7 / 1.4) — `org.bukkit.Sound` needs a registry in unit
      tests.
  13. **Eligibility:** loading / frozen / siege-lobby members are *refused*; vanished staff may navigate; an active
      session ends on siege lobby membership (checked every 40 ticks and on `lobbyChanged`).
  14. **`/knk road why`** prints only the non-open verdicts (pass-through hints and blocks) of the player's route, or
      of the all-open route when blocked, with the same policy the player would get (`--as`); console must name a
      player.
  15. **R39 semantics:** `canCarryNonMember` is true for any applied lockdown in `PreLockdownView` (non-members walk
      through what they see removed) and only for doors open before the lockdown in `PassThroughOnly` — read from the
      two carry paths, which keep their own membership / current-state checks. Core's `SIEGE_HINT` wording ("walk up
      to it to be carried through") fits the default view; in `PassThroughOnly` the player right-clicks instead.
  16. **Trail heights:** route points are floor blocks → particle at floor + 1.2, x/z + 0.5 (block centre without
      quantising the 1.5-block spacing); the straight legs sample the real floor under each point.
  17. **Sessions are replaced, not refused:** `/navigate` while navigating ends the current session silently and
      starts the new one; `/navigate` alone shows "Navigating to X - 340 m to go [Stop]".
  18. **KnkConfig constructors:** the canonical record has 8 fields; the 4-, 5-, 6- (`…, privateMessages, discovery`)
      and 7-arg (`…, teleport, discovery`) forms stay so both trunk's and Phase 3's tests compile unchanged.
- **Discrepancies found:**
  - Plan §2 R18 asks for `StreetsDataAccess.searchAsync`; added, but the catalogue takes streets from the snapshot's
    meta (decision 7).
  - `previewAccess` already reached the evaluator after the merge (through the private checks Phase 2a rewrote); the
    "R6 follow-up" is a test + javadoc, no code.
  - Gradle resolves WorldEdit **7.3.0** through WorldGuard 7.0.10's pom although the build declares 7.2.13:
    `BlockVector3.getBlockX()` etc. are deprecated-for-removal warnings; used like the existing code
    (`WgRegionIdTaskHandler`).
  - Cloud Gradle: Maven Central answers 429 to parallel downloads (link 2's note); with `max.tentatives=12` /
    `initial.backoff=2000` the first build stalled > 25 min on EngineHub retries — `org.gradle.workers.max=2`,
    `max.tentatives=6`, `initial.backoff=1500` in `~/.gradle/gradle.properties` finished in ~2 min; every later
    build ran `--offline`.
  - Phase 3's `RoadAdminCommandTest` line for `edge set 12 c` expected an unsorted list; the code sorts.
  - `KnkConfig` on trunk had no 6-arg (`privateMessages, discovery`) form (Phase 3 added it) and Phase 3 had no
    `teleport` field; both kept (decision 18).
- **Developer to-do (live, dev server, `navigation.enabled: true`, API on `claude/road-navigation`, a built network
  — Phase 3's checklist first):**
  1. `git pull` knk-plugin `claude/road-navigation`; `./gradlew build -x deployToDevServer` (expect knk-core 1545,
     knk-api-client 184, knk-paper 1074 green); `./gradlew :knk-paper:dev`.
  2. `/navigate` → usage; `/navigate <tab>` → place names one word at a time, `town:Market` forms for shared names.
  3. `/navigate <a Location>` → "Navigating to X - 340 m. Follow the trail; [Stop]", gold particle trail ahead, boss
     bar "→ X · 340 m · ~1 min" with progress, action-bar arrow; walk it → "In 12 m: Turn left onto …" lines, arrival
     chime + "You have arrived at X".
  4. `/navigate <a Town>` → its spawn Location; `/navigate <the Town> region` → the route ends where the road enters
     the town's region; from inside: "You are already in X".
  5. `/navigate <a Structure>` (Location by `locationId`), `/navigate street:<name>` (ends on the street),
     `/navigate node:<name>`; a route through a tunnel → "Go down into the tunnel" / "Cross the bridge".
  6. Close a gate on the route (`/knk gate close`) → "The West Gate is closed - recalculating." within 2 s, detour
     or "No open route to X - the West Gate is closed. Guiding you to the gate."; open it → "A shorter route opened -
     following it now."; a pass-through gate → "Hint: right-click the West Gate to pass."
  7. A destination in a domain with `allowEntry=false` → "You may not enter X. Guiding you to its edge." — the route
     ends at the last edge outside; with `knk.region.bypass` the route goes in.
  8. Stand > 48 blocks from any road → "You're too far from a road - get within 48 blocks of one."; a target > 48
     from any road → "X is too far from any road."; a target within 48 → straight trail (direct mode).
  9. Leave the road for > 2 s → "You left the road - recalculating."; `/navigate stop`; `/back` or `/tp` > 16 blocks
     → "Navigation to X ended."; die → ended; `/siege join` → "… ended - you joined a siege."
  10. `/knk road why <destination> [--as <player>]` → the verdict list; `/knk cache refresh` reloads the catalogue.
  11. Watch `/tps` with a few players navigating (trail draws every 10 ticks, re-checks every 40).
- **What later work must wire (Phase 6, DESIGN §8 — out of scope here):** real off-road pathfinding replaces the
  straight legs (`TrailRenderer.drawLeg`, `NavigationService.startDirect`); `NavigationRerouteEvent` /
  `NavigationArriveEvent` for transport quests and tutorials; a `PassThroughOnly` hint wording in core's
  `GateAvailability.SIEGE_HINT` if the degrade switch is ever the default.

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
    pattern (R34), 4xx messages shown. Street editing (developer requirement: street names stay editable in the web
    app):
    - a **"Continue along the road"** checkbox (default on) → `propagate: true`; show how many stretches changed;
    - **"Create street…"** in the picker → small inline form → existing `streetClient.create` (reuse; don't add a
      road-specific street endpoint), then assign it;
    - a **Rename** link next to the street name → the existing Street edit form (`/forms/street/edit/:id`); renaming
      stays owned by the Street entity, so nothing road-specific stores names.
- Street road panel: `F/components/roads/StreetRoadPanel.tsx` (like `SiegeReadinessPanel`) registered as
  `streetRoad` in `F/components/FormWizard/displayPanels.tsx` (R36); document in the phase status how to add it to the
  Street FormConfiguration (a field on `Id` with `settingsJson {"displayPanel":"streetRoad"}` — a dev-DB step for the
  developer).
- Tests (jest + RTL; `react-router-dom` virtual mock as in `DiscoveryAdminPage.test.tsx`): client URL/method tests;
  `roadProfileForm` parser; page renders + error state; edge inline edit save/cancel/4xx; panel loading/error.

**Acceptance:** `npm run test:ci` = baseline + new tests; pages usable against a local API with seeded data; no new
ESLint warnings in touched files.
### Phase 5 status — done 2026-09-28 (knk-web-app `claude/road-navigation` `26de19e`, `23c64ef`, `ba79450`, `d60b458`, `baf9c20`, `ff3ad61`, `9dbb481`; cut from `main` `f56d421`)

**Live smoke test 2026-10-01 — passed**, one small finding: `RoadProfilesCard.tsx:152` uses the browser's native
`window.confirm()` for profile delete instead of `FeedbackModal.tsx`. See the smoke test guide Findings.

- **What was built** (all under `F/`; 17 files, +2 784 / −1 lines):
  - `types/dtos/road/RoadDtos.ts` — `ROAD_ADMIN_NODE = 'knk.admin.road'`, the enum name lists (`ROAD_CLASSES`,
    `ROAD_MATERIAL_ROLES`, `ROAD_EDGE_FLAGS`), every DTO of `W/Dtos/RoadDtos.cs` the web app reads or writes
    (profile, profile upsert with `stats: null`, tile, node, edge, tile graph, meta, edge search query/paged result
    with the API's `pageNumber`, edge update + result, node update, `StreetRoadDto`), `formatRoadFlags`.
  - `apiClients/roadClient.ts` (R35; singleton `roadClient`): profiles CRUD, `getTiles(world)`, `getTileGraph`,
    `getMeta(world)`, `searchEdges` (POST `road-edges/search`), `updateEdge`, `deleteEdge`, `updateNode`,
    `getStreetRoad` (GET `Streets/{id}/road`). `Controllers` enum: `RoadProfiles`, `RoadTiles`, `RoadEdges`,
    `RoadNetwork`, `RoadNodes` (`utils/enums.ts`); `StreetsOperation.Create = ''` declared (see discrepancies).
  - `App.tsx` route `/admin/roads` inside `StaffRoute node={ROAD_ADMIN_NODE}`; `components/Navigation.tsx` link
    "Roads" (lucide `Route`) + `nodeAccess` entry (R34).
  - `pages/admin/RoadsAdminPage.tsx` — world selector (text field remembered in `localStorage`), loads profiles +
    meta + tiles in parallel, a summary strip (tiles/dirty, components/nodes, labelled streets, enabled profiles),
    the three cards; a tile row's "Edges" button limits the edge table to that tile.
  - `components/admin/roads/RoadProfilesCard.tsx` — table + an editor panel (name, class, cost, width min/max,
    enabled, scope towns via `SearchableDropdown` over `townClient.searchPaged` + chips, materials table with
    `MaterialKeyInput.tsx` (text + `minecraftMaterialRefClient.getHybrid` suggestions, R38/D10), role select,
    ambiguous toggle, read-only centre/edge shares and samples); create / edit / delete (confirm); 4xx messages.
    `roadProfileForm.ts` (pure): `ProfileDraft`, `emptyProfileDraft`, `profileToDraft`, `parseProfileDraft`
    (mirrors `RoadNetworkService.ValidateProfile`), `toMaterialKey`, `formatShare`.
  - `components/admin/roads/RoadTilesCard.tsx` — x, z, version, built, builder version, Dirty/Built/Not built,
    cells/nodes/edges/levels, warnings expandable per row; "Dirty only" / "With warnings only" filters.
  - `components/admin/roads/RoadEdgesCard.tsx` — server-paged search (filters unlabelled, stale, street, tile;
    sort id/length/street/tile; 25/50/100 per page); rows show tile, street name + Rename link
    (`/forms/street/edit/:id`), label source badge, profile (class), length, width, cost, flags (Closed in red),
    source/stale/gate; inline edit in the `DiscoveryOverridesCard` pattern: street picker (`SearchableDropdown` +
    `streetClient.searchPaged`, R37) with **"Create street…"** (inline name form → existing `streetClient.create`,
    then assigned) and **"Continue along the road"** (default on → `propagate: true`; the notice says how many more
    stretches followed), profile override select ("None" → `clearProfile`), cost, the three flag checkboxes; the
    API's 4xx message is shown, the row stays in edit.
  - `components/roads/StreetRoadPanel.tsx` (R36, `SiegeReadinessPanel` shape) registered as `streetRoad` in
    `components/FormWizard/displayPanels.tsx`: "save first" notice without an id; counts, total length, junction
    count, the stretches (world, from/to, length, label source, flags, state), links to the Roads page; 404 →
    "This street does not exist (any more)."
  - Tests: `apiClients/__tests__/roadClient.test.ts` (8), `components/admin/roads/__tests__/roadProfileForm.test.ts`
    (8), `components/roads/__tests__/StreetRoadPanel.test.tsx` (5, through `FieldRenderer` like the siege panel),
    `pages/admin/__tests__/RoadsAdminPage.test.tsx` (15: load, error state, world switch, server filters + tile
    filter, propagate notice, cost/flags/profile save + cancel, clear street, 4xx kept in edit, client-side cost
    check, create street, paging, profile create with material suggestion + scope, edit + 4xx, width check, delete).
- **Reuse:** R34 (page/card/inline-edit pattern, route, nav), R35 (client + enum), R36 (display panel registry),
  R37 (`SearchableDropdown` + `streetClient.searchPaged`, also `streetClient.create`), R38 (`getHybrid`), D8 (scope =
  towns), D10 (text field + suggestions). Also reused: `toApiPagedQuery`, the discovery page test's virtual
  `react-router-dom` mock, `FeedbackModal`-free `window.confirm` for deletes (as the overrides card does).
- **Tests:** `npm run test:ci` on the clean `main` `f56d421` — **10 failed suites / 16 failed tests, 381 passed,
  397 total** (the undocumented trunk baseline, now recorded: `ConfigurationHealthPanel.test.simplified`,
  `ConfigurationHealthPanel.test`, `FieldRenderer.validation.test`, `FormWizard.m2mJoinPrefill.ui.test`,
  `ManyToManyRelationshipEditor.test`, `ManyToManyRelationshipEditor.ui.test`, `PathBuilder.test`, `LoginForm.test`,
  `useEnrichedFormContext.test`, `authService.test` — most fail to *run*: `react-router-dom` / missing-module
  resolution). After: **10 failed suites / 16 failed tests, 417 passed, 433 total** → +36, the same ten suites.
  `CI=true npm run build` compiles (TypeScript clean) and fails on the same **36 pre-existing ESLint warnings in 20
  files** before and after — none in a touched file.
- **Decisions to review** (defaults taken; all reversible):
  1. **World selector = a text field** remembered in `localStorage` (`knk.roads.world`), default `world`: there is
     no world-list endpoint and the tile list itself needs a world.
  2. **Edge table density:** 25 rows by default (50/100 selectable), sort id/length/street/tile ascending; filters
     reset to page 1.
  3. **No geometry in the edge table** — length, width and counts only; the street panel shows first/last point.
  4. **Warnings expand per tile row** (chevron + count → a full-width row listing them).
  5. **Profile editor is a panel below the table**, not an inline row (the materials table needs the width); towns
     are loaded when it opens; one profile edited at a time.
  6. **Material suggestions** after 2 characters, 250 ms debounce, 8 catalogue matches; a picked or typed key is
     normalised to Bukkit form (`minecraft:stone_bricks` → `STONE_BRICKS`, spaces/dashes → `_`, upper-case).
  7. **Hand-made profile defaults:** class Road, cost 1, width 1–15 (Phase 2c decision 7: `widthMax` must reach
     the real road width), enabled, everywhere, no materials (the card says a build cannot match it yet).
  8. **Edge PUT sends only changed fields**: clearing the picker → `clearStreet`; profile "None" → `clearProfile`;
     `propagate` only travels with a `streetId` (default on; the checkbox is disabled until the street changes);
     nothing changed → the edit just closes.
  9. **After an edge save the page is searched again** (propagated labels may be on it) and the meta reloaded
     when the street changed (the filter's street list follows).
  10. **Street picker** lists up to 1 000 streets by name (like the discovery domain picker); the *filter* offers
      only the labelled streets of the world (`meta.streets`, Phase 1 decision 12).
  11. **`StreetRoadPanel` uses plain anchors**, not router `Link`s: `FieldRenderers` is imported by nine test suites
      without a `react-router-dom` mock, and CRA's Jest resolver can't resolve that package — a `Link` import there
      breaks all of them (it did, before the fix).
  12. **`updateNode` is in the client** (the Phase 1 "→ 5" contract) although Phase 5 has no node UI.
  13. **No edge delete in the UI** — not in the Phase 5 list; a rebuild recreates detected edges anyway.
  14. A tile's **"Edges" button** sets the API `tileId` filter (chip with an × to clear) and scrolls to the table.
  15. The Rename link goes to `/forms/street/edit/:id` unchanged — it needs a default Street FormConfiguration.
- **Discrepancies found (docs vs code / environment):**
  - **`npm ci` fails on trunk:** `package-lock.json` is out of sync with `package.json` (`Missing: yaml@2.9.1 from
    lock file`). `npm install` works and rewrites the lockfile (23 +/33 − lines) — that diff was **restored, not
    committed** (not this phase's change; the developer may want to commit a fresh `npm install` lockfile on trunk).
    Cypress's postinstall binary download dies with `ECONNRESET` through the cloud proxy: `CYPRESS_INSTALL_BINARY=0
    npm install` is the working recipe.
  - Plan §0.4 / charter §1.6 say `npm run test:ci`; the trunk baseline was undocumented — recorded above.
  - `tsconfig.app.json` is a Vite-style leftover (`moduleResolution: bundler`, `allowImportingTsExtensions`);
    `tsc -p tsconfig.app.json` errors on the config itself, so `CI=true npm run build` is the type check.
  - `streetClient.create` referenced `StreetsOperation.Create`, which did not exist in the enum (the build never
    flagged it; at runtime an undefined operation produced the right URL `api/Streets`). Declared as `''`.
  - DESIGN §7 names the in-game node `knk.admin.roads`; the API (`StaffPermissions.RoadManage`), the plugin and the
    web app use `knk.admin.road` (plan R31). The plan wins; DESIGN's line is stale.
  - The trunk `Street` DTO in the web app (`types/dtos/street/StreetDto.ts`) has no `edgeCount`/`totalLength`
    (Phase 1 §1.6 added them to the API); not needed here — the street panel reads `GET Streets/{id}/road`.
- **Developer to-do:**
  - **Permission:** give the staff group `knk.admin.road` (the nav link, the route and every API write need it).
  - **Dev-DB step (Street FormConfiguration):** open the Forms page → Street → form builder, add a last step "Road"
    with one field on `Id`: label "Road", type Integer, read-only, not required, `settingsJson`
    `{"displayPanel":"streetRoad"}` (exactly like the siege readiness field on `SiegeScenario`). The panel appears in
    the Street edit form for saved streets.
  - **Live checklist (~10 min, against the Phase 1 API + its checklist data):** (1) log in with `knk.admin.road` →
    "Roads" in the nav, `/admin/roads` loads world `world`: profiles list *Default road*, tiles list `0, 0` and `1, 0`
    (the Phase 1 payloads), the dirty one with its warnings expandable; (2) Stretches: "Unlabelled only", Edit one →
    pick a street, "Continue along the road" on, Save → green notice "… continued along the road onto N more
    stretches", the Street filter now offers that street, rows show Manual; (3) Edit another → "Create New Street" →
    name → Create street → it is selected → Save; "Rename" opens `/forms/street/edit/:id`; (4) Edit → cost 0 → the
    client refuses; cost 2, Closed on → Save → row shows ×2 and Closed in red; (5) New profile "Trail": type `dirt`
    in the material field → pick `DIRT_PATH`, add town scope, Create → listed; Edit *Default road* → class Main →
    Save; rename Trail to "Default road" → the API's 400 message; Delete Trail (confirm); (6) after the dev-DB step,
    open a labelled street's edit form → the Road panel lists its stretches; an unsaved street shows the "save
    first" note; (7) switch world to a name without tiles → empty tables, no error; a typo world → same (the API
    returns empty lists); (8) without the node: the nav link is hidden and `/admin/roads` shows "Staff only".
  - Optional: commit a fresh `package-lock.json` on trunk so `npm ci` works again.
- **What later phases must wire:**
  - **4 (`/navigate`):** nothing from the web app. Street names reach the plugin through `StreetCache` (Phase 3,
    60 s refresh) — a rename in the Street form or a label change here needs no plugin action.
  - **Phase 6 / later:** if a node editor is added, `roadClient.updateNode` and `RoadNodeUpdateDto` are ready;
    node edits lock the node unless `locked: false`.

---

## 5.5 Fix plan before resuming the live smoke test (2026-10-01)

Six items, confirmed against actual `claude/road-navigation` source by two Explore agents (not guessed from
symptoms). Priority order below; each is independently implementable and testable. A seventh, larger item
(direct-mode/last-mile walkable pathfinding) was split out into its own Linear issue rather than bundled here —
see the note at the end of this section. Full findings this plan is based on:
`docs/guides/road-navigation-smoke-test.md` → Findings → "Phase 4/5 — live smoke test (2026-10-01)".

**1. Web-app: destructive road-admin actions use `window.confirm()` instead of `FeedbackModal`** (trivial, isolated)
- File: `knk-web-app/src/components/admin/roads/RoadProfilesCard.tsx` (~line 152) — confirmed instance.
- Before fixing, grep every road-admin component/page (`src/components/admin/roads/**`,
  `src/pages/admin/RoadsAdminPage.tsx`, the Street form's Road panel) for other `window.confirm(` call sites and
  fix all of them in the same pass, not just this one.
- Fix: copy the `useState`-driven modal pattern from `knk-web-app/src/components/ObjectDashboard/ObjectDashboard.tsx`
  (`handleDelete` ~lines 94-148, `<FeedbackModal>` JSX ~lines 168-178) — populate
  title/message/status/continueLabel/onContinue, `setModalOpen(true)`, let `FeedbackModal` await `onContinue`
  and stay open on thrown errors to show the failure state.
- Verify: manual check in the admin UI for every fixed component; grep confirms no `window.confirm(` left under
  the road-admin tree.

**2. Region-destination goal point cuts through non-road terrain instead of preferring roads (Bug 5)**
- The navigator must still prefer the road network: the expected behaviour mirrors a plain Location destination
  (Phase 4 item 19, already passing) — follow the road as far as it goes, and only use a short straight *last
  leg* for the small uncovered gap. "Closest point" for a region means *closest via the shortest road-based
  route from the player*, not raw Euclidean closest point, and never a long direct line through "gardens"/
  off-road terrain.
- Files: `knk-paper/.../navigation/NavigationService.java` (the goal-resolution/mode-decision path near
  `resolveGoals`) is the primary place to fix — investigate why a `REGION` goal currently appears to fall into
  full direct mode (bypassing the road network) instead of going through the same road-route-then-short-last-leg
  path a Location goal uses. `knk-core/.../roads/route/RegionClosestPoint.java` (`goals`/`crossings`/`closest`)
  already produces road-network-aware candidate points (where roads cross into the region, or the network's
  nearest approach) and should keep driving the **routed** A* search for region destinations — don't bypass it.
  `knk-core/.../roads/route/RegionShape.java` (`closestPointFromFloor`) may still be useful, but only for the
  short final gap *after* the road-based route ends (the same role the existing last-leg logic plays for
  Location targets), never as a replacement for road routing.
- Fix direction: find and correct the branching logic that decides direct-vs-routed for region destinations so
  it goes through the same "route via roads, then a short straight last leg if needed" path as Location targets,
  rather than a separate "if within direct-mode range of some precomputed region point, go fully direct" branch.
  The apparent arbitrariness observed in testing is a symptom of skipping the road route, not of picking the
  wrong point.
- Risk: must not regress the case where a region genuinely has no road anywhere near it (going direct may be the
  only option, per the existing refusal/direct-mode rules in §6.2) — preserve that fallback.
- Verify: live test approaching an irregular region (with roads nearby) from several angles; the trail should
  follow the road toward the region and only go off-road for a short final stretch, never a long straight line
  through terrain. Re-test the no-nearby-road case to confirm the existing fallback still works.

**3. Direct mode never re-evaluates as the player moves; "left the road" message structurally can't fire in
   direct mode (Bugs 2 & 3, bundled)**
- Files: `knk-paper/.../navigation/NavigationService.java` (`tick` ~463-503, which currently skips `recheck`
  entirely when `a.direct`; `tickDirect`; `arrivedAtRouteEnd` ~626-637), `knk-core/.../navigation/NavigationSession.java`
  (`tick` ~190-223, the existing routed-only off-route/reroute machinery, used as a reference, not reused verbatim
  since direct mode has no `Route` to project onto), `knk-paper/.../navigation/NavigationMessages.java` (`offRoute()`).
- Fix: give direct mode its own periodic recheck (same throttle cadence/constants as the routed `recheck`) that
  re-derives whether direct mode should still apply and whether the player is drifting away from the target.
  Decisions recorded:
  - New reason/message for direct mode's drift signal rather than reusing `offRoute()`'s "You left the road"
    wording (there is no road in direct mode) — e.g. a generic recalculating message.
  - On drift, recompute a new direct-mode target and re-draw; do not auto-promote to a routed session in this
    first pass (lower risk) — leaving the §6.2 48-block/road-connectivity check as the only thing that forces a
    `/navigate` re-run into routed mode, same as today. (This only applies to genuine point/Location direct-mode
    targets — once item 2 lands, region destinations should rarely reach pure direct mode at all except the
    short last-leg case, which is naturally short and doesn't need this drift handling the same way.)
  - Route the `arrivedAtRouteEnd` → direct-mode handoff through this same recheck cadence, not just a one-time
    Euclidean switch.
  - Bug 3 ("left the road" missing) is very likely fully explained by direct mode's structural gap — re-verify
    specifically for a **routed** session as a regression check (it was probably never actually broken there).
- Risk: message-spam if thresholds are too tight; trail-renderer state must reset cleanly on any mode switch;
  this is a live, frequently-exercised path — needs explicit regression coverage of the current happy path
  (arrival, normal walking) alongside the new drift case.
- Verify: live tests — direct-mode drift triggers the new signal; routed-mode lateral deviation still triggers
  `offRoute()` as before; `arrivedAtRouteEnd` handoff participates in the new recheck too.

**4. "You are already in X" doesn't fire for a region the player is standing in (Bug 4)**
- Files: same `NavigationService.navigate`/`resolveGoals`/`Goals.already()` path as item 2 (the ordering between
  the already-there check and the region goal/mode-decision computation is the leading hypothesis), plus
  `knk-core/.../roads/route/RegionShape.java` `containsFloor(...)` if investigation finds a genuine Y-bounds bug.
- Approach: investigate before fixing — reproduce across cuboid/polygon regions and multiple player Y positions
  (including a multi-level/stacked case) to determine whether `containsFloor` is geometrically wrong, or whether
  item 2's region-routing path runs before the already-there check short-circuits. Fix whichever it turns out to
  be; don't guess the exact line now.
- Sequencing: land **after** item 2, since both touch the same region goal-resolution path; re-test item 2's
  scenarios afterward for regressions.
- Verify: the four-case repro matrix (cuboid/polygon × mid-height/boundary/stacked Y) confirming the message
  fires and no trail is drawn.

**5. Plaza produces ~10 junctions instead of one (Bug 7 — root cause of most of item 6's cleanup)**
- Files: `knk-core/.../roads/build/SkeletonGraph.java` — `collapsePlazas` (~188-254, currently a strict
  per-span width test) and `clusterJunctions` (~265-355, currently refuses to walk through any plaza span at
  all). Test file: `SkeletonGraphTest.java` (existing `GridFixture`/`extract`/`Extraction` golden-test style).
- Fix: grow the plaza's footprint from its strict-width core via a bounded dilation/BFS (spending each span's
  remaining distance-transform budget outward from the core) so the 3-4-block edge band joins the plaza instead
  of forking into separate junctions; then let `clusterJunctions` merge a stray junction *adjacent to* (not
  through) a plaza into its node. Decision recorded: make the growth budget a new tunable `BuildParameters`
  field (not a hardcoded constant) so it can be adjusted per profile without a code change; exact default value
  left to whoever implements this, validated against the synthetic-fixture test.
- Explicitly do *not* widen `clusterJunctions`' general merge radius as a workaround — that risks worsening the
  already-filed off-tile-border Boundary node bug (finding B in the smoke-test doc).
- Risk: extra per-tile dilation pass must stay roughly linear in span count (runs on every rebuild, feeding
  into item 6); must not change output for ordinary non-plaza junctions — needs full existing-suite regression
  plus a new synthetic irregular-plaza fixture.
- Verify: new `SkeletonGraphTest` case (irregular plaza + nearby obstacle) asserting collapse to one junction
  node; full existing suite still green; live rebuild of a known problem plaza from the smoke-test doc.

**6. Manual node cleanup doesn't survive a rebuild (Bug 6 — narrow residual after item 5)**
- Files: `knk-core/.../roads/build/NodeMatcher.java` (proximity-only id carry-over), `knk-core/.../roads/build/TileBuilder.java`
  (`build` ~90-125, where a locked node's *position* is restored but nothing suppresses nearby duplicate
  candidates).
- Approach: do this only after item 5 lands and is verified live — most of what currently needs manual cleanup
  is item 5's plaza fragmentation, which item 5 removes at the source. Re-run the smoke test's duplicate-junction
  scenarios first and catalogue what residual cases still don't survive a rebuild before writing any code.
- For genuine residual cases: extend `TileBuilder.build` so a locked node acts as an exclusion zone during
  candidate generation, not just a position anchor for a matched candidate. Open (not decided): whether the
  exclusion radius is a new persisted field per node, or inferred from the existing `nodeMatchDistance` constant
  — leave this to the implementing session, informed by how much residual cleanup item 5 actually leaves behind.
- Before implementing, confirm with whoever owns `knk-web-api` whether `RoadEdgeRecord`'s rebuild-survival
  (implemented server-side, outside both repos checked here) already covers part of this, to avoid duplicating it.
- Verify: prune/merge a node, force a rebuild, confirm it stays pruned; unit test simulating two `TileBuilder.build`
  calls with the same locked-node state and a varying mask.

**Split out — new Linear issue, not part of this fix plan's execution:** direct-mode trail ignores terrain /
last-mile walkable pathfinding (originally "Bug 1"). Confirmed: no walkable-path utility, navmesh, or
Paper/Bukkit entity-pathfinding usage exists anywhere in either repo — this is net-new design work, not a
bounded bug fix. `NavigationService.startDirect`/`tickDirect` (knk-paper) and `TrailRenderer.drawLeg`/`legPoints`
draw a pure straight-line interpolation with no collision/walkability check, for both the off-road leg (§6.2,
within 48 blocks) and the "road ends short of target" last leg (`arrivedAtRouteEnd`). See the linked Linear issue
for the proposed minimal-viable direction (a bounded block-level search, ~48-64 blocks, respecting the player's
`AccessPolicy`, with a hard search budget and fallback to today's straight line) and open questions.
**Design drafted 2026-10-02:** [LAST_MILE_PATHFINDING.md](LAST_MILE_PATHFINDING.md) answers the open questions (A\*
on the road builder's span model, new `knk-core roads/walk/` package, one `DirectLeg` mechanism shared with item 3 above)
and sequences the work after item 3; it is proposed, pending the developer decisions in its §11.

### §5.5 status — items 1-6 code-complete on `claude/road-navigation`, live re-test pending (verified 2026-10-02)

Verified by the walkable-path chain, link 1 (`docs/reports/2026-10-02-navigation-walkable-chain.md`), against
knk-plugin `claude/road-navigation` `075ae94`, knk-web-app `6414e18`, knk-web-api `c029186`. Nothing of it is merged to
trunk. "Code-verified" = the code does what the item describes and its unit tests pass; every item's live "Verify"
step is still the developer's.

| Item | Commits | Code as planned? | Tests (all pass) | Verify step |
|---|---|---|---|---|
| 1 `window.confirm` → `FeedbackModal` | web-app `6414e18` | Yes — `RoadProfilesCard` delete only; grep of `components/admin/roads`, `components/roads` (Street road panel), `pages/admin/RoadsAdminPage.tsx` finds no other `confirm(` | `RoadProfilesCard.test.tsx` (new); road-admin suites 16/16 | Grep ✔; admin-UI click-through **needs live** |
| 2 Region goals follow the road | plugin `6a73945` | Yes — `NavigationService.regionGoals`: goals = `RegionClosestPoint.crossings` (multi-goal A\*), else the road's nearest approach + a last leg ≤ max-snap; fully direct only within `REGION_DIRECT_DISTANCE` (8), when the region is nearer than the road, or when no road gets within max-snap; refusal otherwise (§6.2 fallback kept) | `aRegionWithinDirectRangeStillFollowsTheRoadIntoIt`, `aRegionNearerThanAnyRoadIsWalkedToStraight`, `aRegionNoRoadEntersIsReachedByRoadThenAShortLastLeg` | **Needs live** (irregular region from several angles; no-road case) |
| 3 Direct-mode re-check, "left the road" | plugin `6a73945`; test `d8507a3` (link 1, on `claude/navigation-walkable-path`) | Yes — `recheckDirect` on `RECHECK_TICKS` (40), trigger `directBest + reroute-distance`, rate-limited by `reroute-min-interval`, new `directRecalculating` message + `NavigationRerouteEvent(OFF_ROUTE, "direct")`; not promoted to routed (plan decision); the `arrivedAtRouteEnd` leg is ordinary direct mode so it shares the re-check | `directModeRecalculatesWhenThePlayerWalksAway`, `directModeToARegionReAimsAtItsClosestPointAfterDrifting`, `aRoutedSessionStillSaysYouLeftTheRoad`; **gap closed by link 1:** `theLastLegAfterTheRoadsEndUsesTheDirectReCheck` (the handoff takes part in the re-check — no test pinned it) | **Needs live** (direct drift; routed lateral deviation; road-end handoff) |
| 4 "Already in X" | plugin `6a73945` | Yes — the fix covers both suspects: the check could run after goal resolution, **and** the shape test used the raw double position (x = 120.7 was outside a region ending at 120). Now checked first via `RegionShapes.containsFeet` = WorldGuard's block containment (`WorldGuardRegionShapes`), fallback `RegionShape.containsFeet` by feet block; arrival uses the same check | `aPlayerCountsByTheBlockTheirFeetAreIn` (core), `aPlayerInTheRegionsLastBlockColumnIsAlreadyThere`, `theAlreadyThereCheckUsesTheServersRegionContainment` | **Needs live** (cuboid/polygon × mid/boundary/stacked Y) |
| 5 Plaza = one junction | plugin `9f66fea` (+ finding B in the same commit) | Yes — `SkeletonGraph.plazaFootprint` (core + clearance + `BuildParameters.plazaGrowth`, default 2, `navigation.builder.plaza-growth`), bucket queue, linear; `clusterJunctions` joins a plaza when it reaches one along the skeleton (general radius unchanged) | `anIrregularPlazaWithObstaclesIsOneJunction` (8 → 1), `withoutPlazaGrowthTheIrregularPlazaStillFragments`, `aForkRightAtAPlazasEdgeMergesIntoThePlazaJunction`, `aPlazaStraddlingTheTileBorderGetsItsBoundaryNodeOnTheBorder` | Unit ✔; **live rebuild of a problem plaza needed** |
| 6 Manual cleanup survives a rebuild | plugin `ef556e2`; web-api `8523ec8`; developer follow-ups plugin `6a8caa7`, `9dccb58` + web-api `c029186`, `075ae94` | Yes, differently from the sketch: no exclusion zone per node — a locked node claims the nearest leftover candidate within `BuildParameters.lockedNodeReach` (default 8, `navigation.builder.locked-node-reach`; the plan's open question answered as one build-wide tunable) and absorbs duplicates joined to it within that reach; a recording now locks the detected nodes it snaps to (API). The developer added: Boundary nodes never take a locked inner node (`6a8caa7`), `/knk road node prune|unprune` with `Pruned` tombstones (`9dccb58`/`c029186`), two-arm junctions joined into one edge (`075ae94`) | `aMergedJunctionStaysMergedAcrossRebuilds` (two builds, varying mask), `aLockedJunctionClaimsTheBuildersJunctionBeyondTheNormalMatchDistance`, `anUnlockedNeighbourAndAFarJunctionAreNotMerged`, `aBoundaryCandidateNeverTakesALockedInnerNode`, `aPrunedDeadEndIsLeftOutAndItsJunctionDissolves`, `aJunctionLeftWithTwoArmsIsJoinedIntoOneEdge`, … ; web-api `RoadNetworkServiceTests` | **Needs live:** the plan wanted the residual cases catalogued after item 5 was verified live — that step was skipped (items 5 and 6 landed together); the developer's 2026-10-02 session is the first live evidence |

Other KNG-27 fixes on the branch (not §5.5 items): finding G — `/knk road show` names the node along the view ray
(`ae2f1e8`); the recorder records the floor block, not the one under it (`8b6d678`; **recordings made before it sit one
block too deep** — re-record them). Still open: finding D (upload timeout on a huge tile), finding E (no node/tile
delete, builder settings need a restart), `/knk road node info here`, a "prefer the domain's Location" setting
(smoke-test finding 4), and the direct-mode walkable path (KNG-51).

Test counts on `075ae94` (Gradle, `build -x deployToDevServer`, 2026-10-02): knk-core 1561, knk-api-client 184
(2 skipped), knk-paper 1088 (14 skipped), all green; with link 1's test knk-paper 1089. knk-web-api `c029186`:
1631 passed / 5 failed / 42 skipped — the 5 failures are the known non-road baseline (`ClientActivityStoreTests`,
`FormSubmissionProgressRepositoryTests`, `FieldValidationServiceTests`, 2× `PathResolutionServiceTests`). knk-web-app:
road suites 16/16 (needs `@testing-library/dom` installed; `npm ci` fails on a stale lockfile — `yaml@2.9.1` missing,
pre-existing). **Deploy note:** plugin `9dccb58` and API `c029186` go together (an older plugin can't parse the
`Pruned` node kind). knk-web-api `master` has 19 commits `claude/road-navigation` lacks — merge before merging to trunk.

### 5.5 status — items 1-6 implemented 2026-10-02 (branch `claude/road-navigation-smoke-test-bugs-fagl4i` in each repo, cut from the `claude/road-navigation` heads; KNG-51 not started)

- **What was built** (one commit per item group; all on `claude/road-navigation-smoke-test-bugs-fagl4i`):
  - **Item 1** — knk-web-app `6414e18`: the only `window.confirm(` in the road-admin tree (`components/admin/roads/**`,
    `pages/admin/RoadsAdminPage.tsx`, `components/roads/StreetRoadPanel.tsx`) was the profile delete in
    `RoadProfilesCard.tsx`; it now opens `FeedbackModal` (ObjectDashboard pattern: Delete runs the request, a failure
    keeps the modal open with the API's message). New `__tests__/RoadProfilesCard.test.tsx` (3 tests).
  - **Items 2-4** — knk-plugin `6a73945`:
    - Item 2: `NavigationService.regionGoals`. Root cause confirmed: `resolveGoals` went **fully direct whenever the
      region's edge was within 48 blocks** (true almost everywhere inside a town), bypassing the road. Now a region
      routes like a Location: goals are the road/region crossings (`RegionClosestPoint.crossings`, multi-goal A*
      picks the nearest *by road*); when no road enters the region, the road's nearest approach (only if within
      max-snap of the region) plus a short straight last leg to the region's closest point. Direct mode only when the
      road doesn't help: region within 8 blocks (`REGION_DIRECT_DISTANCE`), no farther than the nearest road, or no
      road reaches within max-snap of it while the region does. Otherwise the existing refusals stand.
    - Item 4: the "already in X" check runs first and asks the new `RegionShapes.containsFeet`, which
      `WorldGuardRegionShapes` answers with **WorldGuard's own block containment** (what the region tracker's
      enter/leave messages use); the fallback `RegionShape.containsFeet` counts the player by the block their feet are
      in (the old double comparison put x = 120.7 outside a region ending at 120). Arrival-in-region uses the same check.
      Not reproduced live (cloud session): see decision 3.
    - Item 3: `NavigationService.recheckDirect` on the routed re-check cadence (`RECHECK_TICKS`, also for the
      last-leg handoff after `arrivedAtRouteEnd`): walking `reroute-distance` farther than the closest approach says
      **"You're heading away from X - recalculating."** (new `NavigationMessages.directRecalculating`), re-derives the
      target (region closest point / street nearest point / Location unchanged), redraws trail and HUD, fires a
      `NavigationRerouteEvent` (OFF_ROUTE, detail "direct"); rate-limited by `reroute-min-interval`. Not promoted to a
      routed session (decision recorded above). The routed "You left the road" path was intact — pinned by a regression
      test.
    - Tests: `NavigationServiceTest` +8, `RegionShapeTest` +1.
  - **Item 5** (+ finding B) — knk-plugin `9f66fea`:
    - `SkeletonGraph.plazaFootprint`: the plaza is its strict-width core grown by each core span's own clearance
      (`dt − 1`) plus the new tunable **`BuildParameters.plazaGrowth`** (default 2, `navigation.builder.plaza-growth`);
      bucket queue, linear in spans; the junction position still comes from the core. `clusterJunctions`: a cluster
      that reaches a plaza node within `junction-cluster-radius` along the skeleton (never through it) joins that
      plaza's junction; the general cluster radius is unchanged.
    - Finding B ("Boundary node … is not on the tile border"): `cutAtTileBorder` first extends a chain whose node
      centre and first/last span are on opposite sides of the border through the node to its centre (straight mask
      line, BFS fallback within 64 steps, else dropped with warning `WARN_BORDER_NODE_UNREACHABLE`), and a plaza member
      span at the cut gets its own Boundary node. Both tiles now cut on their shared border and their Boundary nodes
      stitch (tested from both sides).
    - Golden fixture: a 21-wide square with chipped corners, an alcove, two bumps, a lamp post and a planter went from
      **8 junctions to 1** (still fragments with `plazaGrowth` 0). `SkeletonGraphTest` +4, `BuildParametersTest` updated.
  - **Item 6** — knk-plugin `ef556e2`, knk-web-api `8523ec8`:
    - `NodeMatcher`: a locked node (not Anchor/Boundary) still unmatched after the normal 3-block pass takes the nearest
      leftover candidate within **`BuildParameters.lockedNodeReach`** (default 8, `navigation.builder.locked-node-reach`).
    - `TileBuilder.mergeIntoLockedNodes`: an unmatched Junction/Endpoint joined by a chain ≤ the reach to a node on a
      locked node (and itself within the reach) merges into it; its chains start at the locked node, the joining chain
      goes, a duplicate pair keeps the shorter edge. No locked node → output unchanged.
    - web-api: `CreateRecordedEdgeAsync` now **locks the Detected nodes a recording snaps to** (bumping their tile's
      version) — the upsert already kept them, but unlocked the builder couldn't tell and minted duplicates next to
      them. Answers the "confirm with knk-web-api" note above: Recorded edges and recorded-through nodes already
      survived; their *neighbourhood* did not.
    - Tests: `TileBuilderTest` +3 (two rebuilds over different masks keep a merged pair merged; a locked junction claims
      the builder's junction 5 blocks away; unlocked/matched or out-of-reach neighbours stay), `NodeMatcherTest` +1,
      `RoadNetworkServiceTests` asserts the lock.
  - **Finding G** (not in the six items, documented smoke-test bug) — knk-plugin `ae2f1e8`:
    `RoadOverlayRenderer.describeLookedAt` names the node whose pillar is closest to the view ray (≤ 1.5 blocks, up to
    the overlay radius), else the first edge under the ray, else the node the `here` commands act on, marked
    "(here)". New `RoadOverlayRendererTest` (4). `/knk road node info here` (requested in G) is **not** built.
- **Reuse:** `RegionClosestPoint.crossings/closest`, `RegionShape.closestPointFromFloor`, `Snapper`, the existing
  `Goals`/`startDirect`/`arrivedAtRouteEnd` paths, `FeedbackModal`, `BuildWarning`, `BumpTileAsync`. Nothing duplicated.
- **Tests:** knk-plugin Gradle (cloud, real Paper deps): knk-core 1545 → **1554**, knk-api-client 184 (2 skipped),
  knk-paper 1074 → **1086** (14 skipped), all green. knk-web-api `dotnet test`: 1627 passed /
  **5 failed (the 5 known baseline failures)** / 42 skipped. knk-web-app: `react-scripts test src/components/admin/roads`
  11/11, `tsc --noEmit` clean.
- **Decisions to review** (defaults taken; all reversible):
  1. Item 2: `REGION_DIRECT_DISTANCE = 8` and "region no farther than the nearest road" decide direct vs routed for a
     region. Comparing real road length with the straight line needs KNG-51's walkable search; until then a region
     whose edge is 10 blocks away behind a wall, with the road 12 blocks away, still goes direct.
  2. Item 2: the region's closest-approach fallback is used only when that road point is within max-snap (48) of the
     region; farther → direct if the player is within 48 of the region, else "too far from any road" (previously the
     route silently ended at a far road point).
  3. Item 4 was fixed without a live repro (cloud session): the authoritative WorldGuard check removes every way our
     geometry copy could disagree with the region tracker (block flooring, polygon algorithm, Y band). If "already in"
     still fails live, the next suspect is the destination itself: `NavigationDestinations.locateDomain` falls back to the
     domain's spawn **point** when it has no `wgRegionId`, and a point never says "already in" — check
     `/knk road why town:<name> region`.
  4. Item 3: drift = `reroute-distance` (8) past the closest approach; at most once per `reroute-min-interval` (3 s),
     checked every 2 s. Event reason OFF_ROUTE with detail "direct" (no new `RouteReason` value).
  5. Item 5: `plaza-growth` default 2 (the fixture needs ≥ 1; 2 also covers 2-deep alcoves). A plaza's footprint can
     now swallow the first 2 spans of each exit road's skeleton; node position is unchanged.
  6. Item 6: one build-wide `locked-node-reach` (8) instead of a per-node persisted radius; only *unmatched* candidates
     merge (a node the admin left alone and the builder still finds stays). A locked node also claims a candidate up to
     8 blocks away by id, keeping the locked position.
  7. Item 6 web-api: recording an edge locks both snapped-to ends (same rule as decision 7 of Phase 1, "an admin edit
     locks the node"). `node unlock` undoes it.
  8. Finding B: when a straddling node's centre can't be reached within 64 mask steps, the chain part is dropped with a
     warning rather than failing the tile upload.
- **Discrepancies found:**
  - Plan item 3 expected the "left the road" message to be suppressed; it isn't — routed sessions send it (test added).
    The smoke test saw it missing because those sessions were in direct mode.
  - Item 5 text said `clusterJunctions` "refuses to walk through any plaza span": correct, and it also never *merged*
    into one — that was the second half of the bug.
- **Developer to-do:**
  - Merge `claude/road-navigation-smoke-test-bugs-fagl4i` into `claude/road-navigation` in knk-web-app, knk-web-api
    and knk-plugin (no migration; web-api change is service-only). Rebuild the plugin locally
    (`./gradlew build -x deployToDevServer`) and redeploy; restart the server (builder config is read in `onEnable`).
  - Optional config: `navigation.builder.plaza-growth: 2`, `locked-node-reach: 8.0` (defaults already apply when the
    keys are absent).
  - Live re-test, in this order (smoke-test guide §4 and §2):
    1. Web app: delete a profile → FeedbackModal, not the browser dialog.
    2. `/navigate` to a District / Town `region` from ~30-40 blocks away with a road nearby → trail follows the road
       into the region; from a few blocks away / off-road → straight; a region with no road near it → still direct or
       refused as before. `/knk road why` shows which.
    3. Standing inside the Town (cuboid and polygon, mid-height, at the band's edge, a stacked level) → "You are
       already in X", no trail.
    4. Direct mode (a Location < 48 blocks): walk away → "You're heading away from X - recalculating." once, trail
       redrawn; routed: leave the road > 2 s → "You left the road - recalculating."
    5. `/knk road build tile` on the Cinix plaza tiles → one junction per plaza; no "not on the tile border" error.
    6. Merge two duplicate junctions + lock, record a gap, rebuild the tile twice → the merge and recording hold.
    7. `/knk road show`: look at pillars near/far/from above → the bar names them; look at the sky → "(here)".
  - Then resume Phase 4 Availability/Ending/Admin/Performance (guide §4) — KNG-51 (walkable last mile) is still open,
    so straight direct-mode lines through walls are expected until it lands.

---

## 5.6 Designed plazas and movable nodes (rev. 5, 2026-10-04)

Developer decision after the 2026-10-04 smoke test: stop guessing plazas and pruning the result; let the admin say where
a plaza is. DESIGN §3.5 (`PlazaRadius`, moving a node), §5.6 step 4, §7.

**Status: implemented 2026-10-04, not yet live-tested.**
- knk-web-api `claude/road-navigation` `569699f` + `2edcb1f`: `road_nodes.PlazaRadius` (migration
  `20261004143846_AddRoadNodePlazaRadius`, **apply with the developer's go-ahead**), `PUT road-nodes/{id}` with
  `plazaRadius`/`clearPlaza` and `x`/`y`/`z` (same tile, free position, edge ends follow, node locked); edge prune keeps
  an orphaned plaza centre. Tests: `RoadNodeEditTests` (5).
- knk-plugin `claude/navigation-walkable-path` `f1270f4` (builder, version 4) + `38886df` (records, client, cache,
  build job, `auto-plazas` config, `/knk road node move <id>` / `plaza <radius> [id]` / `unplaza [id]`, overlay label).
  Gradle core 1641 / api-client 185 / paper 1135 green.
- knk-web-app: no node editing UI exists; `RoadNodeDto` there does not carry `plazaRadius` yet (not needed).

**Developer to-do (live test):** apply the migration; deploy API + plugin; on tile 2,-2: `/knk road node plaza 12 7`
(Brink) and a radius for the eastern place / Northern Gate Square; rebuild the tile; check `/knk road show` (one
junction per plaza, labels "plaza r…", arms following the stairs) and the build summary; optionally set
`navigation.builder.auto-plazas: false` and rebuild to see whether the designed plazas alone are enough; then unprune
tombstones that only existed to clean up plaza fragments.

**Follow-up 2026-10-04 evening: finding L, builder version 5** (smoke-test guide "Build v202 analysed"). Build v202
lost Brink's west junction and #3588's arms. An offline replay of the real builder on the dev world traced it to
junction clustering: a chain of forks on Brink's wide stairs joined a road fork 20 blocks away into the plaza. Neither
the tombstones nor the plazas caused it. knk-plugin `claude/navigation-walkable-path` (not pushed):
- `4bc6946`: plaza junctions stay.
- `8c9cb7e`: only the forks at a plaza's edge join it.
- `19bf4b1`: thin loops collapse.
- `2672558`: one-arm junctions become Endpoints.
- `8fe661a`: correction report and stale-prune warnings.
- `5d9a5e9`: builder version 5.

Gradle core 1646 / api-client 185 / paper 1137 green. No API change.

**Developer to-do:** deploy the jar; rebuild 2,-2, 2,-1, 1,-2; unprune the stale prunes the summary lists; move #3693 to
the middle of Merchants Square (or radius 16); check Brink in `/knk road show`.

The structural follow-ups (find open areas before making the centreline; freeze curated tiles and review rebuilds as
a list of proposed changes) are proposed in [REV6_PROPOSAL.md](REV6_PROPOSAL.md), not decided.

## 5.7 Rev. 6 Part B — curated tiles (in progress, started 2026-10-05)

**Developer decision 2026-10-04:** do the rev. 6 work, starting with the recommended part, **curated tiles**
([REV6_PROPOSAL.md](REV6_PROPOSAL.md) §3). Part A (open areas first, §2) follows. Handoff:
`docs/ai-agents/handoffs/2026-10-05-road-curated-tiles.md`. Decisions D1-D7 were answered on 2026-10-05 (below); the
step table is rewritten to match them.

**Goal.** Once a tile has been built, a rebuild never silently replaces the stored graph. It produces a **proposal**
(what a fresh detection would add, remove, move or reshape) that the admin reviews in game and accepts or rejects.
Tombstones then only filter proposals; a stale one can no longer remove a road from the stored graph.

### Decisions (developer, 2026-10-05)

- **D1 — a tile becomes Curated with its first build.** Every successful upsert leaves the tile `Curated` (`CuratedAt`
  = the first time). Admin edits are allowed on a curated tile and do not change the state. Later builds of a curated,
  built tile only make proposals. `/knk road tile uncurate [tile]` sets it back to `Detected` **once**: its next build
  writes directly, and that upsert curates it again. `/knk road tile curate [tile]` sets it without building.
- **D2 — existing tiles:** the migration marks built tiles that already hold admin data `Curated`: a tombstone, a Manual
  node (anchor), a locked node (names, moves and merges lock), a designed plaza or a Recorded edge. Today that is 2,-2
  and 2,-1. Every other tile starts `Detected`: its next build writes directly and curates it.
- **D3 — the admin chooses the granularity:** `accept|reject all`, one item (`3`), a selection or range (`1 4 7-9`), or
  every item of one kind (`added`, `removed`, `changed`, `moved`). The dependency rules apply to every selection.
- **D4 — rejecting a "removed" item confirms it**, so it is never proposed for removal again: a node is locked, an edge
  gets `Confirmed` (new column; its end nodes are locked too). Backdoor: `/knk road node unlock <id>` (exists) and
  `/knk road edge unconfirm <id>` (new). Rejected added / changed / moved items go on the tile's **rejected list**,
  which only filters later proposals; `/knk road proposal rejected` lists it and `unreject <n…|all>` takes entries back.
- **D5 — proposals live in the API** (one row per tile, with the rejected list), so the web app can review them later
  (B5). The plugin computes them, stores them through the API and reads them back after a restart.
- **D6 — Part A's regression gate** (offline replay on Cinix plus 2-3 areas outside it: another town, a village, a
  rural network) waits until the developer's other world is available, in a few days. Each area needs coordinates,
  road profiles covering its materials, and a few lines on the expected graph. Not needed for Part B.
- **D7 — the replay harness is committed to knk-plugin** as a test that is skipped unless `KNK_REPLAY_DIR` is set.

### Steps

One commit per step, a test with each. Branches: `claude/road-curated-tiles-nsrorb` in knk-web-api (from
`claude/road-navigation` `7f99cbd`) and knk-plugin (from `claude/navigation-walkable-path` `75f6a0e`).

| Step | Repo | Work |
|---|---|---|
| B1 | knk-web-api | Migration (apply only with a go-ahead, after a `road_tiles` backup): `road_tiles.State` (`Detected` \| `Curated`, default `Detected`) + `CuratedAt` with the D2 data update; `road_edges.Confirmed`; table `road_tile_proposals` (one row per tile: `ItemsJson`, `RejectedJson`, counts, `BaseVersion`, `BuilderVersion`, `CreatedBy`, `CreatedAt`, `UpdatedAt`). Every upsert sets `Curated` and clears the tile's pending items (the rejected list stays). `PUT road-tiles/{w}/{x}/{z}/state`; `GET\|PUT\|DELETE road-tiles/{w}/{x}/{z}/proposal`; `GET road-tiles/proposals?world=`. `PUT road-edges/{id}` takes `confirmed` (true locks both ends); an unmatched Confirmed edge survives an upsert while both its nodes stay. Tile DTOs carry `state` and `curatedAt`, edge DTOs `confirmed`. Tests. |
| B2 | knk-plugin core + api-client | `core/roads/build/TileDiff` (pure): compare a `TileBuildResult` with the stored tile graph. Items: edge added / removed / changed (geometry beyond `edgeMatchDistance`, or other gate doors, domains or profile), node moved (matched, unlocked, more than 2 blocks), node removed. Never proposed: Recorded and Stitch edges, Confirmed edges, locked or Manual nodes, tombstones. `TileDiff.merge(current, items, accepted)` builds the upload: the **current** stored graph plus the accepted items; an item that no longer fits the current graph (the edge was deleted or reshaped since) is skipped with a reason. Accepting everything of a fresh proposal uploads the build result as is (= today's upsert). Rejected-list matching. Records + API client calls for state, proposals and `confirmed`. Tests. |
| B3 | knk-plugin paper | `RoadBuildJob`: a curated, built tile (and `curated-tiles: true`) stores the diff as a proposal instead of upserting; the summary lists counts and the first numbered items with teleports. Overlay: added green, removed red, changed and moved yellow, numbered labels. Commands: `/knk road proposal [list]`, `accept\|reject <all\|n…\|kind>`, `clear`, `rejected`, `unreject`; `/knk road tile curate\|uncurate`; `/knk road edge confirm\|unconfirm <id>`. |
| B4 | knk-plugin paper | `/knk road build here\|tile\|radius\|dirty\|all` makes proposals for curated tiles and builds `Detected` ones directly. `/knk road tiles` shows the state, "built with vN" (older than the current `BUILDER_VERSION` is flagged, never rebuilt automatically) and pending proposal counts. Config `navigation.builder.curated-tiles: true` (false = today's behaviour, the kill switch). Replay harness (D7). |
| B5 | later | Partial rebuild (`/knk road build here radius <r>`, a proposal inside a circle); web-app tile-state column and proposal review. |

**Dependency rules for `merge`:** accepting an added edge brings its new end nodes (a new node another accepted item
already added is reused by position); accepting a removed node removes its edges; a detected, unlocked node left without
edges goes too; a moved node takes its edges' end points along (every uploaded edge's geometry is re-anchored on its final
node positions); node kinds follow the build only for nodes an accepted item touches; boundary nodes and stitch edges
follow the existing upsert rules.

**Tombstones on curated tiles:** prune and unprune keep their API behaviour (the edge or node goes now, and the
tombstone stays). The builder keeps reading tombstones when it makes a proposal, so pruned junk is not proposed again.
Because the stored graph is only replaced through a reviewed proposal, a stale tombstone can at worst hide a proposal
item. The builder-5 correction report still lists stale ones.

**Done when:** the live re-test on tile 2,-2 shows a rebuild after a config change as a proposal; accepting items
changes only those items; rejecting keeps the stored graph; `curated-tiles: false` restores today's behaviour. Gradle
and web-api tests are green, except the known failures.

**Order with the finding L re-test:** the developer runs the builder-5 re-test (plan §5.6, guide "Build v202
analysed") with the `claude/navigation-walkable-path` jar, before deploying this branch or applying the B1 migration.
The re-test's rebuilds then write directly, and D2 curates the result.

### §5.7 status

- 2026-10-05: decisions recorded; implementation started in a cloud session (no dev DB or server: migrations are
  written, not applied; nothing live-tested).

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
| KNG-17 merge conflicts | R6 (Phase 2a) is kept minimal — two private methods moved; teleport's `previewAccess` is pointed at it only in Phase 4. R20-R22 happen in Phase 4, after the teleport merge, never before. |
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
