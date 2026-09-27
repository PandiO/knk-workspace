Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 2d — knk-plugin core: router (`C/roads/route/`: `RoadNetworkSnapshot`, `SegmentIndex`,
`CoverageCheck`, `Snapper`, `AStarRouter`, `AccessPolicy` + `CompositeAccessPolicy` + `GateAvailability` /
`DomainAvailability` / `StaticFlagsAvailability`, `BlockedExplainer`, `RegionShape`, `ManeuverBuilder`, `EtaEstimator`;
`C/navigation/NavigationSession`)** from docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests, commits,
push to `claude/road-navigation`, plan status block, progress report, handoff), as **link 5** of the chain. Charter §5
allows a split at a commit boundary if it turns out too big (e.g. 2d-1 = snapshot, index, snapper, A\*, access policies,
explainer; 2d-2 = `RegionShape`, `ManeuverBuilder`, `EtaEstimator`, `CoverageCheck`, `NavigationSession`); if you
split, mark the status "partial" naming exactly which classes/tests exist and hand 2d-2 to link 6 as `…-phase-2d-2.md`.

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`). Its "Phase 1
  status → What later phases must wire" describes the tile graph download the router consumes (nodes with `kind`,
  edges with `geometry` `int[][]`, `length`, `avgWidth`, `profileId`, `streetId`, `flags` (`Oneway`, `NoGps`, `Closed`),
  `gateDoorIds`, `domainIds`, `regionIds`, `status` (`Ok`/`Stale`, both routable), `source` (`Detected`/`Recorded`/
  `Stitch`); stitch edges may reference a node of the neighbour tile by id — resolve across downloaded tiles).
  `W/Dtos/RoadDtos.cs` on that branch has the exact names (clone knk-web-api read-only if you need them; the 2c link
  cloned it to `/home/user/pandio/knk-web-api`, that path may not exist in your container).
- **Phase 2a is done** (link 2): `C/util/BlockKey`, `C/util/Polygon2D` (`contains`, `closestPointOnBoundary`,
  `distanceToBoundary` — R2, for `RegionClosestPoint`/`RegionShape`), `GateManager.closedFootprint`, `GateStateListener`,
  `C/regions/DomainAccessEvaluator` (`Optional<Denial> entry/exit(DomainSnapshot)`, instance methods — pass one instance
  into `DomainAvailability`), `ArchitectureGuardTest` (scans `C/roads/**` and `C/navigation/**` recursively: any
  `org.bukkit` import or `org.bukkit.` code reference under your packages fails it).
- **Phase 2b is done** (link 3): `C/roads/survey/*`, `C/domain/roads/RoadMaterialRole`.
- **Phase 2c is done** (link 4, 2026-09-27): knk-plugin `claude/road-navigation` **`c2ca1e3`** (commits `2266921` …
  `c2ca1e3`; trunk `main` still `eb1d68c`, nothing to merge), knk-core **1280 tests green** (baseline before 2c: 1130) via
  the plan §0.4 scratch build (**not Gradle**, see risks). It added `C/roads/build/*` (the builder) and
  **`C/domain/roads/RoadNodeKind`** (`JUNCTION/ENDPOINT/BOUNDARY/ANCHOR`, `apiName()`/`fromApiName()`) — reuse that enum
  for node kinds in the snapshot, don't define a second one. Details and 20 numbered decisions in the plan's "Phase 2c
  status"; the ones that bind you are repeated below.
- **knk-web-app:** untouched; not needed.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 2d section, refresh the summary table — 2d row is "in progress (link 5)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 2d in progress with the class list; update as you go).
- **Baseline to record:** knk-core 1280 tests at `c2ca1e3` (re-measure with the scratch build before changing anything;
  `./gradlew :knk-core:test` will fail on `paper-api` resolution — record that too).

What earlier phases say Phase 2d must wire:
- **Coordinates (2c decision 1):** every node position and geometry point is the **floor block** `(x, y, z)`; a player
  standing there has feet at `y + 1`. `Snapper.snap(x, y, z, …)` takes a player position — decide once whether it takes
  feet coordinates and subtracts 1 internally, or floor coordinates (recommended: take the player's feet position and
  compare with geometry y + 1; document it as a decision). `snap-vertical-weight` (DESIGN §5.2, 4) multiplies that
  height difference so a player on a bridge snaps to the bridge, not the road 4-10 blocks below.
- **Edge data (2c decision 17, Phase 1 DTOs):** `length` is the walked 3D centreline length (≥ chord), `geometry` an
  RDP polyline whose first/last points are exactly the two nodes' positions; edges arrive in either node order
  (the API normalises `FromNodeId < ToNodeId` and reverses geometry) — your snapshot must not assume geometry
  direction beyond "from → to". `gateDoorIds` are the doors whose closed footprint the edge passes; `regionIds` are
  WorldGuard region ids in order (D11) — `DomainAvailability` looks domains up **by region id**.
- **Node kinds:** `Boundary` nodes and `Stitch` edges are plumbing — `ManeuverBuilder` ignores them (plan 2d);
  routing treats them like any node/edge (a stitch edge is 1 block long). `Anchor` nodes are named destinations
  only when they carry a `name`.
- **Access (plan 2d, D2, D13):** `GateAvailability` over a `GateState` port (`Optional<GateView> gate(int doorId)` →
  state, jammed, destroyed, allowPassThrough, siegeLocked, siegeCarries) and a `PassRule` port (`canPass(doorId)`):
  OPEN or destroyed → open; siege-locked → `PASS_THROUGH` when `siegeCarries` (R39) else blocked; closed and
  pass-through allowed for this player → `PASS_THROUGH` with hint; OPENING/CLOSING/jammed → blocked.
  `DomainAvailability` uses `DomainAccessEvaluator.entry/exit` (R6) with a `DomainLookup` port by region id and a
  bypass flag: entry denied on edges entering a region's domain, exit denied on edges leaving the player's current
  domains. `StaticFlagsAvailability` honours `Closed` and `NoGps`. Decisions cached per request by gate/domain id.
- **Components (Phase 1, DESIGN §5.8):** nodes carry `componentId` from the API — `AStarRouter` refuses fast when
  start and goal components differ (before searching).
- **Class costs (DESIGN §4 `class-cost`, plan 2d):** `RouteRequest.classCost` maps `RoadClass` (from the profile of
  the edge, via the meta's profiles) → factor; edges without a profile use 1.0. Heuristic = min Euclidean distance
  to any goal × the cheapest factor (admissible).
- **Router output for Phase 4:** `Route` = ordered edges with entry/exit `t` on the first/last edge, total length,
  the polyline to draw, per-edge verdicts (for "pass-through" hints), `BlockedExplainer` output when no route exists
  (first blocked element + last reachable point). `ManeuverBuilder` (DESIGN §6.5): left/right/straight bands, street
  change, "Go down into the tunnel"/"Cross the bridge" when the next edge's height differs by > 3. `EtaEstimator`:
  sprint 5.6 blocks/s. `NavigationSession`: pure state machine returning effects (siege `SiegeEffect` style).

Phase-specific reading: plan §0 (esp. 0.2 Bukkit-free, 0.4 scratch build), §1 (D2 siege areas open, D7 boundary
stitching, D11 `RegionIds`, D13 gate re-check), §2 (R2, R5, R6, R7, R22, R39), "Phase 2 → 2d" (the whole section — every
class with its port), "Phase 1 status" (download contract, decision 1 on stitch edges), "Phase 2a status → What later
phases must wire", "Phase 2c status" (decisions 1, 15, 17). DESIGN §2 (concepts), §3.5-3.6 (`RoadNode`/`RoadEdge`
fields incl. `Flags`, `GateDoorIds`, `DomainIds`, `Status`), §5.2 (snapping paragraph), §6 whole (6.1 command
semantics only for context, 6.2 route computation, 6.3 closest point of a region, 6.4 guidance, 6.5 maneuvers, 6.6
events, 6.7 availability — read all of 6.7, several rules are tests), §5.8 (components), §9 (scale: per-world snapshot
memory). Config values the router takes as parameters (`max-snap-distance` 48, `snap-vertical-weight` 4,
`class-cost`, `reroute-distance` 8, `reroute-after-ticks` 40, `arrive-distance` 4, `max-session-minutes` 30,
`sprint-speed` 5.6): put them in a `RouterParameters`/`SessionParameters` record with the DESIGN defaults like 2c's
`BuildParameters`; Phase 3's `NavigationConfig` (R16) fills them.

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): the snapshot's internal representation
(edge polylines decoded once; segment index bucket size 32), how virtual nodes split an edge, tie-breaks in A\*,
what a maneuver record carries (text + position + bearing change), the `NavigationSession` effect vocabulary. Take the
reversible default and number it in your status block.

Known risks:
- **Network (same as links 1-4):** `repo.papermc.io` and `maven.enginehub.org` return HTTP 000 (proxy 403 on CONNECT) —
  re-check per charter §1.5; if still blocked, use the scratch build (recipe in the plan's "Phase 2a status" block;
  the 2c status adds what the `Vector` stub must cover). Put `org.gradle.workers.max=2`,
  `systemProp.org.gradle.internal.repository.max.tentatives=12`, `systemProp.org.gradle.internal.repository.initial.backoff=2000`
  in `~/.gradle/gradle.properties` before the first run, then `--offline`. Say "not compiled with Gradle" in your status.
- **Toolchain:** Java 21 present (`openjdk 21.0.10`), Gradle wrapper 8.10.2 downloads fine. The knk-plugin clone may
  be shallow (`--depth 1` of `main`): `git fetch --depth 60 origin claude/road-navigation:refs/remotes/origin/claude/road-navigation`
  then `git checkout -b claude/road-navigation origin/claude/road-navigation`.
- **Repo layout:** the knk-plugin clone lands at `/home/user/knk-plugin` (not `Repository/knk-plugin`); the
  workspace clone may be in detached HEAD — `git branch -f main HEAD && git checkout main` before pushing to `main`.
- **`.gitignore`:** knk-plugin ignores `**/build/`; 2c added `!**/src/**/build/`. Your packages (`roads/route`,
  `navigation`) are not affected, but check `git status` shows your files before the first commit.
- **Size:** 2d is "M" but has many small classes; the tests listed in the plan's 2d section are the deliverable
  (shortest path vs class costs; oneway; closed gate → explained + partial route; pass-through gate → hint; entry
  denied → route ends at region edge with reason; exit denied; different components → refused; snap prefers the
  bridge over the road below; region multi-goal; maneuvers; session states). Build a small in-memory network fixture
  first (a few tiles' worth of nodes/edges in the Phase 1 download shape) and reuse it everywhere. Commit and push
  after each class + its tests.
- **Scope:** `C/roads/route/` and `C/navigation/` only (plus test fixtures) — no paper code, no API client (2e), no
  config loading, no changes to `C/roads/build/` (done), `C/roads/survey/` (done), `C/gates`, `C/regions`, `C/siege`.
- **Bukkit-free:** positions are ints/doubles, ids are ints, regions are `Polygon2D`/cuboids — the guard test fails
  on any `org.bukkit`.

Next after you: **Phase 2e** (api-client — `A/`: ports, DTOs, mappers, impls, conditional GET R17). Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-2e.md` and start it per charter §6 (or `…-phase-2d-2.md` if you
split 2d).
