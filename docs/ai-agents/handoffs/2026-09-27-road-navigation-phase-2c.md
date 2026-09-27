Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 2c — knk-plugin core: builder (`C/roads/build/`: ports `SurfaceGrid`/`GateCells`,
`PassabilityRules`, `ProfileSet`, `SpanGrid`, `MaskBuilder`, `DistanceTransform`, `Thinning`, `SkeletonGraph`,
`ProfileMatcher`, `Rdp`, `NodeMatcher`, `TileBuilder`, test fixture `GridFixture` + golden tests)** from
docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests, commits, push to `claude/road-navigation`, plan
status block, progress report, handoff), as **link 4** of the chain. **This phase is large** — charter §5 allows a split
at a commit boundary (e.g. 2c-1 = ports, `PassabilityRules`, `ProfileSet`, `SpanGrid`, `MaskBuilder`,
`DistanceTransform` with their unit tests; 2c-2 = `Thinning`, `SkeletonGraph`, `ProfileMatcher`, `Rdp`, `NodeMatcher`,
`TileBuilder` + `GridFixture` golden tests). If you split, finish at the boundary, mark the status "partial" naming
exactly which classes/tests exist, and hand 2c-2 to link 5 with the same file name pattern (`…-phase-2c-2.md`).

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`); its "Phase 1
  status → What later phases must wire" is the API contract the builder's output must satisfy (see below).
- **Phase 2a is done** (link 2): knk-plugin `claude/road-navigation` `35252c7` … `db962a4` — `C/util/BlockKey`
  (`pack/x/y/z/neighbour`, 26/12/26 bits, y −2048…2047), `C/util/Polygon2D`, `GateManager.closedFootprint(gateId)`
  → `List<Vector>` (Bukkit type — the paper side converts to `BlockKey`s for your `GateCells` port), `GateStateListener`,
  `C/regions/DomainAccessEvaluator`, and `ArchitectureGuardTest`, which **scans `C/roads/**` recursively**: any
  `import org.bukkit` or `org.bukkit.` in a code line under `C/roads/build/` fails it.
- **Phase 2b is done** (link 3, 2026-09-27): knk-plugin `claude/road-navigation` **`92375e5`** (commits `e7a5cb3`,
  `92375e5`; trunk `main` still `eb1d68c`, nothing to merge), knk-core **1130 tests green** (baseline before 2b: 1085)
  via the plan §0.4 scratch build (**not Gradle**, see risks). It added `C/roads/survey/{SurveySample, SurveyStats,
  ProfileLearner, ProposedProfile}` and **`C/domain/roads/RoadMaterialRole`** (`SURFACE/EDGE/ACCENT/OVERLAY`,
  `apiName()`/`fromApiName()`) — **reuse that enum in `ProfileSet`**, don't define a second role enum. Details and 12
  numbered decisions in the plan's "Phase 2b status".
- **knk-web-app:** untouched; not needed.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 2c section, refresh the summary table — 2c row is "in progress (link 4)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 2c in progress with the `C/roads/build/` class list; update as you go).
- **Baseline to record:** knk-core 1130 tests at `92375e5` (re-measure with the scratch build before changing anything;
  `./gradlew :knk-core:test` will fail on `paper-api` resolution — record that too).

What earlier phases say Phase 2c must wire:
- **From 2a (plan "Phase 2a status → What later phases must wire"):** `BlockKey.pack/x/y/z/neighbour` for every cell
  map (`SpanGrid` keys, mask, distance field, thinning); gate cells come in through your `GateCells` port
  (`OptionalInt doorAt(x, y, z)`), prebuilt by Phase 3 from `GateManager.closedFootprint` per door (D9) — the builder
  never touches `GateManager`. Gate-door cells count as **passable** and a chain through them yields an edge with
  `gateDoorIds`.
- **From 2b (plan "Phase 2b status → What later phases must wire"):** `ProfileSet` maps material → `(RoadMaterialRole,
  ambiguous, profile ids)` from `C/domain/roads/RoadMaterialRole`; a profile's `widthMax` is the learner's 95th-percentile
  run width (`15` = at least the cross-section) — plaza collapse uses `widthMax/2` of the matched profile; `ProfileMatcher`
  compares a chain's floor-material histogram with the profile's material `centreShare`s (Surface/Edge/Accent only —
  Overlay materials are never floors). Overlays are "looked through" by `SurfaceGrid.floorMaterial`.
- **From Phase 1 (API contract for the tile graph the builder produces; Phase 3 PUTs it):** node `key`s are free
  strings not starting with `id:`; `existingId` only for nodes of *this* tile (`NodeMatcher` output); `Boundary` nodes
  on the tile's border cells only; edges may be in either node order; geometry ends within 1.5 blocks of its nodes;
  `length ≥` straight-line distance; **no cross-tile edges** (the API stitches boundary nodes within Chebyshev 1 in x/z
  and |Δy| ≤ 1 itself); node kinds `Junction | Endpoint | Boundary | Anchor` (no gate kind — gates are edge data) and edge fields `geometry` (`int[][]`),
  `length`, `avgWidth`, `profileId`, `gateDoorIds`, `domainIds` (left empty by the builder — the paper job tags
  domains), `regionIds` (same) — read `W/Dtos/RoadDtos.cs` (`RoadTileGraphUpsertDto`, `RoadTileGraphNodeDto`,
  `RoadTileGraphEdgeDto`) on knk-web-api `claude/road-navigation` for the exact names, so `TileBuildResult` maps one to one
  in Phase 2e/3. The builder is pure (no I/O, no threads).
- **R22 (teleport branch, `origin/claude/teleport` in knk-plugin, not on trunk):** `C/teleport/BlockProbe` is exactly
  `boolean isPassable(int x,int y,int z); boolean isSolid(int x,int y,int z); boolean isHazard(int x,int y,int z);
  int minY(); int maxY();` (**`maxY` exclusive**). `SurfaceGrid` must declare these five with identical signatures and
  semantics plus `String floorMaterial(int x,int y,int z)` and `boolean isStairOrSlab(int x,int y,int z)`, so Phase 4
  can later make it `extends BlockProbe` without changing an implementation. Teleport's hazard set
  (`SafeLocationFinder.HAZARD_MATERIALS`): `LAVA, MAGMA_BLOCK, FIRE, SOUL_FIRE, CAMPFIRE, SOUL_CAMPFIRE, CACTUS,
  SWEET_BERRY_BUSH, POWDER_SNOW, WITHER_ROSE, POINTED_DRIPSTONE` — use the same list in `PassabilityRules` / the test
  fixture and say so in the status (Phase 4 unifies them when the branch lands).
- **R28:** `C/siege/SiegeFloor.floorY(double y, IntPredicate solidAt, IntToDoubleFunction topAt) → OptionalDouble`
  (`MAX_DROP = 4`, `MAX_LIFT = 3`) is the pure floor snap — use it if you need one (e.g. seed → span), don't write another.

Phase-specific reading: plan §0 (esp. 0.2 Bukkit-free, 0.4 scratch build), §1 (D7 boundary nodes/stitching, D9 gate
footprints, D11 `RegionIds`, D12 seeds), §2 (R1, R2, R3, R22, R28), "Phase 2 → 2c" (the whole section: the two port
interfaces verbatim, every class with its DESIGN §5 reference, the `GridFixture` ASCII format and the **golden test
list** — each golden test is a deliverable), "Phase 1 status" (contract, sample payloads), "Phase 2a status", "Phase 2b
status". DESIGN §2 (concepts: span, tile, node kinds), §3.3-3.6 (`RoadTile`, `RoadSeed`, `RoadNode`, `RoadEdge` fields),
§5.1 (mask rules incl. `ambiguous-reach`), §5.2 (spans, headroom, step-up, diagonals — the 3D core), §5.4 (mask and
snapshot capture: seeds, margin, cap), §5.5 (distance transform, Zhang-Suen thinning), §5.6 (skeleton → graph: degree
classification, junction clustering, spur pruning, plaza collapse, chains, anchors, boundary nodes), §5.7 (stable ids —
`NodeMatcher`), §5.8 (components — API side, not yours), §5.12 (known edge cases: read all, several are golden tests).
Config values the builder takes as parameters (`ambiguousReach`, junction radius, `minSpur`, RDP ε 0.75, margin, cell
cap): put them in a `BuildParameters` record with the DESIGN defaults; Phase 3's `NavigationConfig` (R16) fills it.

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): the exact `TileRequest`/`TileBuildResult`
shapes (mirror the DTO names), how `SpanGrid` represents a span (top-of-floor y + headroom), tie-breaks in junction
clustering and spur pruning, what a "warning" carries (text + position). Take the reversible default and number it in
your status block.

Known risks:
- **Network (same as links 1-3):** `repo.papermc.io` and `maven.enginehub.org` return HTTP 000 (proxy 403 on CONNECT) —
  re-check per charter §1.5; if still blocked, use the scratch build (recipe in the plan's "Phase 2a status" block:
  throwaway Gradle project, real `knk-core/src/{main,test}/java` as source sets + `stub/org/bukkit/util/Vector.java`
  rewritten from the Bukkit API — constructors, get/set X/Y/Z incl. `getBlockX/Y/Z`, add/subtract/multiply/divide,
  length/distance, dot/cross, normalize, `rotateAroundX/Y/Z`, `rotateAroundAxis`/`rotateAroundNonUnitAxis`, fuzzy
  `equals` (ε 1e-6), `clone`, `getMinimum/getMaximum`; Maven Central only; `workingDir = knk-core`). Put
  `org.gradle.workers.max=2`, `systemProp.org.gradle.internal.repository.max.tentatives=12`,
  `systemProp.org.gradle.internal.repository.initial.backoff=2000` in `~/.gradle/gradle.properties` before the first
  run (Maven Central answers 429 to parallel downloads), then `--offline`. Say "not compiled with Gradle" in your status.
- **Toolchain:** Java 21 present (`openjdk 21.0.10`), Gradle wrapper 8.10.2 downloads fine.
- **Size:** the golden-test list has 16 scenarios in 3D (tunnel under a road, bridge, stacked streets, spiral ramp).
  Build the fixture first and keep every golden test small (≤ 32×32 cells, 2-3 layers). Commit and push after each
  class + its tests so the branch is resumable; split at a commit boundary rather than leaving half-written classes.
- **Scope:** `C/roads/build/` only (plus the test fixture under `knk-core/src/test/.../roads/`) — no router (2d), no
  API client (2e), no paper code, no config loading. Don't touch `C/gates`, `C/regions`, `C/roads/survey` (done) or
  `C/siege` (R28 is use-as-is).
- **Bukkit-free:** material names are `String`s; passability is a table over names (`PassabilityRules`) — note in the
  status that Phase 3 must verify `Material#isCollidable()` on 1.21.10 when it feeds the table.
- **Tests are the deliverable:** unit tests per class plus the golden tests from the plan; each golden test asserts
  node kinds/count, edge count, edge lengths ±1, no stray spurs.

Next after you: **Phase 2d** (router — `C/roads/route/` and `C/navigation/`). Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-2d.md` and start it per charter §6 (or `…-phase-2c-2.md` if
you split 2c).
