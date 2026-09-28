Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 3 — knk-plugin paper: admin side (survey, build, review)** from
docs/specs/navigation/IMPLEMENTATION_PLAN.md (§3.1 config R16, §3.2 extractions R8-R11/R25 + the paper-side R4 fire
points, §3.3 wiring in `KnKPlugin`, §3.4 classes `P/roads/*`, §3.5 tests), end to end (code, tests, commits, push to
`claude/road-navigation`, plan status block, progress report, handoff), as **link 7** of the chain. Phase 3 is "L":
charter §5 allows a split at a commit boundary — a natural one is **3a** = config + extractions + wiring skeleton +
`RoadNetworkCache` + `RoadDirtyTracker` + `RoadOverlayRenderer` + `/knk road show|reload|seed|node|edge` (review) and
**3b** = `ChunkSnapshotSurfaceGrid` + `GateCellsIndex` + `RoadBuildJob`/`RoadBuildQueue` + `RoadSurveyService`/
`RoadSurveySession` + `/knk road survey|build`. If you split, mark the status "partial" naming exactly which classes,
tests and subcommands exist and hand the rest to link 8 as `…-phase-3b.md`.

**knk-paper cannot be compiled in the cloud** (paper-api, WorldGuard, WorldEdit unresolvable — links 1-6 all saw
`repo.papermc.io` 403 / `maven.enginehub.org` 000; re-check per charter §1.5). The charter says: implement by careful
reading of the neighbouring paper code, say "**not compiled**" in the status block, list what the developer must
build locally, and keep going. Put every pure piece you can (tile maths, dirty-tracker batching, survey sampling
gates, config validation, chunk-extraction span rules, overlay colour hashing) behind Bukkit-free helpers that the
knk-core/knk-api-client scratch build *can* run, and test those; the Mockito tests of §3.5 are written but marked
"not run".

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`). Route
  table plan §1.5; contract in "Phase 1 status → What later phases must wire → Phase 3": node `key`s free strings
  (not `id:`), `existingId` only for nodes of *this* tile, `Boundary` nodes on the border cells only, no cross-tile
  edges (the API stitches within Chebyshev 1 / |Δy| ≤ 1), geometry ends within 1.5 blocks of their nodes, `length ≥`
  chord; surveys need `X-Acting-User-Id`; dirty creates the tile row if unknown. Read-only clone: `GIT_LFS_SKIP_SMUDGE=1
  git clone --depth 1 --branch claude/road-navigation https://github.com/PandiO/knk-web-api /home/user/pandio/knk-web-api`.
- **Phases 2a-2e are done** (links 2-6): knk-plugin `claude/road-navigation` **`4ffdd1a`** (trunk `main` still
  `eb1d68c`, nothing to merge). knk-core **1374** tests, knk-api-client **174** (2 live-only skips) — both via the plan
  §0.4 scratch build (**not Gradle**). What 3 wires, all reachable from `plugin.getApiClient()`:
  - **2e ports** (`C/ports/api/RoadNetworkQueryApi`, `RoadNetworkCommandApi`; impls in `A/impl/`, getters
    `getRoadNetworkQueryApi()`/`getRoadNetworkCommandApi()` on `KnkApiClient`): `tiles(world)`, `tileGraph(world, x, z,
    etag)` → `Conditional<RoadTileGraph>` (304 → `notModified()`, never-built → exceptional 404), `meta(world)`,
    `profiles()`, `profile(id)`, `surveys(world)`, `seeds(world)`, `seedLocations(world, minX, minZ, maxX, maxZ)`,
    `searchEdges(PagedQuery)`; `upsertTileGraph(world, x, z, TileBuildResult)`, `markDirty`, `createProfile`/
    `updateProfile`/`deleteProfile`, `createSurvey(RoadSurveyCreate, actingUserId)`, `createSeed`/`deleteSeed`,
    `updateNode`, `createAnchor`, `mergeNodes`, `recordEdge`, `updateEdge`, `deleteEdge`. Records in `C/domain/roads/`
    (`RoadTile.etag()`/`isBuilt()`/`tileCoordinate(block)`, `RoadProfile.hasStats()`/`statsJson`,
    `RoadProfileUpsert.of(existing, learned, statsJson)`, `RoadSeedCreate.admin/survey`, `RoadNodeUpdate.rename/
    unnamed/kind/locked`, `RoadEdgeUpdate.street(id, propagate)/unlabelled/profile/flags/costMultiplier`,
    `RoadApiError`); adapters in `A/mapper/RoadMapper` (`toBuilderProfiles`, `toSnapshotProfile`, `toPreviousGraph`,
    `toAnchors`, `error(ApiException)`). Every future completes on the api-client executor; a refusal is a
    `CompletionException` → `RuntimeException` → `ApiException` (status + `{error, message}` body). The full wiring
    recipe is the plan's "Phase 2e status → What later phases must wire → 3 (paper)" — cache, build job, survey
    session, dirty tracker, review, each with the exact calls.
  - **2d** (`C/roads/route/`, `C/navigation/`): `RoadNetworkSnapshot.builder(world).addNodes(..).addEdges(..)
    .addProfile(..).addStreet(..).build()`, `unresolvedEdgeIds()`, `regionIds()`, `edges()`/`polyline(edge)` for the
    overlay, `CoverageCheck.misses(breadcrumbs, snapshot)` for survey review; everything in **floor-block**
    coordinates (feet = floor + 1). See "Phase 2d status → What later phases must wire → 3 (paper cache)".
  - **2c** (`C/roads/build/`): ports `SurfaceGrid`, `GateCells`, `ScopeLookup`; `PassabilityRules.of(...)`,
    `BuildParameters`, `ProfileSet(profiles, scope)`, `TileBuilder.build(request, grid)` (pure, off-thread),
    `TileBuildResult` (+ `Node`/`Edge` records — rebuild edges to fill `domainIds`/`regionIds`), `NodeMatcher.
    PreviousGraph`, `SkeletonGraph.Anchor`, `BuildWarning`. See "Phase 2c status → What later phases must wire → 3
    (paper build job)" for the extraction rules (floor material, stairs/slabs, headroom, gate cells, seeds, margins).
  - **2b** (`C/roads/survey/`): `SurveySample.of(x, y, z, onGround, overlay, offsets)` (15 columns, −7…+7),
    `SurveyStats.of(samples)`/`merge`/`toJson`/`fromJson` (unknown version → throws: show, never overwrite),
    `ProfileLearner.learn(stats) → ProposedProfile`. See "Phase 2b status → What later phases must wire → 3".
  - **2a**: `GateManager.closedFootprint(id)` (R3), `GateManager.addStateListener` (R4), `BlockKey`, `Polygon2D`,
    `DomainAccessEvaluator` (R6).
- **knk-web-app:** untouched; not needed.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 3 section, refresh the summary table — 3 row is "in progress (link 7)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 3 in progress with the file list; update as you go).
- **Baselines to record:** knk-core 1374 and knk-api-client 174 (2 skipped) at `4ffdd1a`; knk-paper tests **cannot
  be run here** — count the test files you add and say so.

What earlier phases say Phase 3 must wire (plan §3 + the 2b/2c/2d/2e status blocks — read all four "→ 3" notes):
- §3.1 `KnkConfig.NavigationConfig` (+ `SurveyConfig`, `BuilderConfig`, `TrailConfig`), keys exactly DESIGN §4,
  `ConfigLoader.loadNavigation`, `config.yml` `navigation:` section, `ConfigLoaderNavigationTest`.
- §3.2 extractions **first, one commit each, callers delegate, tests green by reading**: R8 `P/utils/RegionIds.at`
  (from `WorldGuardRegionTracker`), R9 `P/utils/ParticleDraw` (from `SiegeWorldPresenter` — one of the four allowed
  siege edits), R10 `P/utils/KnkLocations` (from `SiegeBukkit` — allowed siege edit), R11 `P/utils/TickBudget` (three
  TPS copies in `GateBlockScanTaskHandler`), R25 `P/gates/GatePassThroughRules` (from the pass-through listener) —
  see §2 rows for exact locations; plus the R4 fire points (`HealthSystem.destroyGate/respawnGate`, the jam in
  `GateAnimationTask`, `GateCommand` toggles).
- §3.3 `KnKPlugin`: promote `regionDomainResolver`/`regionTracker` to fields, `initializeRoads()` after
  `initializeSiege()` gated on `navigation.enabled`, R18 data accesses as fields, `road` registered in
  `registerCommands()` with **lazy suppliers** (it runs before `initializeRoads()`), `onDisable` order, `plugin.yml`
  permissions (`knk.admin.road` under `knk.admin`, `knk.navigate` default true). Flag the double `CacheManager`
  construction, don't fix it.
- §3.4 the ten classes under `P/roads/` (compact chunk extraction per DESIGN §9 — never keep `ChunkSnapshot`s; never
  generate terrain; builder on the api-client executor; domain tagging on the main thread in `TickBudget` batches;
  cache files `plugins/KnightsAndKings/roads/<world>/<x>_<z>.json` + etag; meta every 60 s; survey sampling gates;
  clickable Save / Merge / Discard (R26); dirty listeners + WorldEdit `EditSessionEvent` extent; overlay via
  `ParticleDraw`; `RoadAdminCommand` with every DESIGN §7 subcommand + `reload`, `hasNode` like
  `DiscoveryAdminCommand`, tab completion hooked into `KnkAdminCommand.onTabComplete`).
- §3.5 tests (written even if not runnable here).

Phase-specific reading: plan §0 (esp. 0.2, 0.4), §2 rows R3, R4, R7-R19, R24-R26, §3 whole, the "→ 3" notes of the
2b, 2c, 2d and 2e status blocks; DESIGN §4 (config keys), §5.1-5.4 (survey + seeds), §7 (admin commands), §9
(memory). knk-plugin: `P/KnKPlugin.java` (constructor/`registerCommands`/`initializeSiege`/`onDisable`),
`P/commands/{KnkAdminCommand,DiscoveryAdminCommand}.java`, `P/config/{KnkConfig,ConfigLoader}.java` +
`ConfigLoaderDiscoveryTest`, `P/tasks/GateBlockScanTaskHandler.java` (TPS copies), `P/siege/{SiegeWorldPresenter,
SiegeBukkit}.java` (only the two generic methods move), `P/regions/WorldGuardRegionTracker.java` (`RegionIds.at`
source), `P/menu/MenuService.mainThreadExecutor`, one existing paper test with a mocked `World` for the style.
knk-web-api (read-only): `Controllers/RoadTilesController.cs`, `Services/RoadNetworkService.cs` (upsert validation
messages you will see as 400s).

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): cache file format (JSON of the
`RoadTileGraphDto` shape + etag is the reversible default — reuse the DTO records through the client's
`ObjectMapper`), how the build queue persists across restarts (the API's `builtAt` is the plan's answer), survey
review UX details (R26 pattern), overlay colours. Take the reversible default and number it.

Known risks:
- **Cannot compile knk-paper here** — the biggest risk of the whole chain lands on this link: write every class
  against the real signatures (open the neighbouring files, copy their import lists), keep Bukkit calls thin, and
  tell the developer exactly which files to compile first. A second pass by the developer (`./gradlew build -x
  deployToDevServer`) is expected to find import/signature slips; make them cheap to fix.
- **Network:** same as links 1-6 — scratch build for knk-core/knk-api-client only (recipe in the 2a and 2e status
  blocks; put `org.gradle.workers.max=2` + the retry properties in `~/.gradle/gradle.properties` first, then
  `--offline`).
- **Toolchain/layout:** Java 21 present; knk-plugin clone lands at `/home/user/knk-plugin` (may be `--depth 1` of
  `main`: `git fetch --depth 60 origin claude/road-navigation:refs/remotes/origin/claude/road-navigation` then check
  it out); the workspace clone may be in detached HEAD — `git checkout main`, `git pull --ff-only origin main`
  before editing docs (other sessions push to `main`); `add_repo` (push access) is needed before the first push to
  knk-plugin. Long shell heredocs may stall in this environment — write files with the file-writing tool.
- **Siege:** only the two mechanical edits (R9, R10) in `P/siege/`, each in its own commit; nothing else there.
- **Scope:** no `/navigate` (Phase 4), no web-app (Phase 5), no changes to `C/roads/**`, `C/navigation/**`,
  `C/domain/roads/**` or `A/**` beyond what a genuine wiring need proves (a missing field → add it with a decision
  note; a missing port method → add it to the port + impl + test).
- **Size:** "L" — commit and push after each logical part (config; each extraction; wiring skeleton; cache; dirty
  tracker; overlay; review commands; extraction grid + gate cells; build job + queue; survey service; tests).

Next after you: **Phase 5** (knk-web-app admin pages — plan "Phase 5"; the web app is buildable in the cloud: `npm ci`,
`npm run test:ci`, measure the baseline first). Phase 4 waits for KNG-17 (charter §4.7). Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-5.md` and start it per charter §6 (or `…-phase-3b.md` if you
split 3).
