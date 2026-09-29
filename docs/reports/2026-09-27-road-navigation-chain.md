# Road navigation chain — progress report

**Status:** finished — all phases done (1, 2a-2e, 3, 5 and 4); nothing merged to trunk, the developer merges phase by phase after testing (closing handoff `docs/ai-agents/handoffs/2026-09-29-road-navigation-closeout.md`)
**Last updated:** 2026-09-29 (link 9: Phase 3 compiled, trunk merged, Phase 4 done — chain complete)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) · **Charter:** `docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md` · **Plan:** `docs/specs/navigation/IMPLEMENTATION_PLAN.md`

## Summary for the developer

| Phase | State | Branch heads | Details |
|---|---|---|---|
| 1 — knk-web-api: data model, services, API | **done** (link 1) | knk-web-api `claude/road-navigation` `77e0a29` (from `master` `ccc8c02`) | [Phase 1](#phase-1--knk-web-api-data-model-services-api-link-1) |
| 2a — plugin core extractions | **done** (link 2) | knk-plugin `claude/road-navigation` `db962a4` (from `main` `eb1d68c`) | [Phase 2a](#phase-2a--knk-plugin-core-shared-extractions--guard-test-link-2) |
| 2b — survey maths | **done** (link 3) | knk-plugin `claude/road-navigation` `92375e5` (on 2a's `db962a4`; trunk `main` still `eb1d68c`) | [Phase 2b](#phase-2b--knk-plugin-core-survey-maths-link-3) |
| 2c — builder | **done** (link 4) | knk-plugin `claude/road-navigation` `c2ca1e3` (on 2b's `92375e5`; trunk `main` still `eb1d68c`) | [Phase 2c](#phase-2c--knk-plugin-core-builder-link-4) |
| 2d — router + navigation session | **done** (link 5) | knk-plugin `claude/road-navigation` `a82db3c` (on 2c's `c2ca1e3`; trunk `main` still `eb1d68c`) | [Phase 2d](#phase-2d--knk-plugin-core-router-and-navigation-session-link-5) |
| 2e — api-client | **done** (link 6) | knk-plugin `claude/road-navigation` `4ffdd1a` (on 2d's `a82db3c`; trunk `main` still `eb1d68c`) | [Phase 2e](#phase-2e--knk-plugin-api-client-ports-dtos-mapper-conditional-get-link-6) |
| 3 — plugin paper admin side | **done** (link 7; compiled by link 9 on 2026-09-29, one slip fixed in `68fa48c`) | knk-plugin `claude/road-navigation` `96f4c62` → `68fa48c` (on 2e's `4ffdd1a`; trunk merged after it) | [Phase 3](#phase-3--knk-plugin-paper-admin-side-survey-build-review-link-7) |
| 5 — web-app admin pages | **done** (link 8) | knk-web-app `claude/road-navigation` `9dbb481` (from `main` `f56d421`) | [Phase 5](#phase-5--knk-web-app-admin-pages-link-8) |
| 4 — `/navigate` | **done** (link 9) | knk-plugin `claude/road-navigation` `4e3f8af` (on the trunk merge `be5df0f` = Phase 3's `68fa48c` + `main` `27b4236` with KNG-17) | [Phase 4](#phase-4--knk-plugin-paper-navigate-link-9) |

- **Review first — Phase 4** (ranked, plan "Phase 4 status → Decisions to review"): (1) decision 3 — the region
  tracker's `knk.region.bypass` predicate is also navigation's bypass (staff routes through closed domains);
  (2) decision 15 — the R39 predicate reads `PreLockdownView` as "carried through any locked door", `PassThroughOnly`
  as "only doors open before the lockdown" (siege behaviour itself unchanged); (3) decision 4 — direct mode also for
  node/street/region targets within 48 blocks, and the last off-road leg to the real target after the road ends;
  (4) decision 7 — the destination catalogue is loaded from the API every 60 s (≤ 5 000 places) and streets come
  from the snapshot; (5) decision 9/10 — re-check cadence (2 s) and what a network rebuild does to active routes;
  (6) decision 18 — `KnkConfig` keeps four older constructor forms after the merge.
- **Review first — earlier phases** (ranked): (1) Phase 1 decision 1 — stitch edges are owned by the last-built tile and reference the
  neighbour's node by id, so a tile download can point at a node of another tile; (2) decision 2 — Detected nodes
  touched by a Recorded edge survive rebuilds; (3) decision 6 — "continue along the road" writes Manual labels on
  every edge it reaches; (4) decision 4 — Inferred labels are recomputed from scratch per build (conflicts →
  unlabelled + warning). All in the plan's "Phase 1 status" block. Phase 2a is a pure refactor; its decisions 1-3
  (`DomainAccessEvaluator` shape: instance methods, `Denial` carries the domain, the three exit loops collapsed to one)
  only matter for the KNG-17 merge — see the plan's "Phase 2a status". Phase 2b (survey maths): (5) its decision 5 —
  the plan's centre-vs-outer road-likeness rule cannot learn a plaza or a ≥ 13-wide road surveyed on its own, nor a
  kerb material that also floors buildings along more than ~15-20 % of the walk (the admin adds those by hand); (6)
  decision 1 — a survey's run statistics are classified with that survey's own material distribution, then merged
  by summing, so profiles accumulate exactly across surveys of the same kind of road; (7) the `StatsJson` v1 layout
  (flat per-material counts) is now fixed by the plugin — see the plan's "Phase 2b status". Phase 2c (builder):
  (8) decision 1 — every node and geometry point is the **floor block** (feet at y + 1); Phases 2d/3 convert;
  (9) decision 7 — the plaza rule is `2·dt − 1 > widthMax`, so a profile's `widthMax` must be at least the real road
  width or the road collapses into junctions (the learner's 95th percentile guarantees this for surveyed roads;
  hand-made profiles should set 15); (10) decision 8 — Zhang-Suen got two robustness additions (staircase ends kept,
  deletions checked on real span links) with visible consequences: L-corners of 1-wide paths become diagonals, a
  1-wide T's centre moves one cell into the stem; (11) decision 15 — a Junction or Anchor exactly on a tile border
  is not stitched to the neighbour tile (rare; an anchor one block in fixes it) — see the plan's "Phase 2c status".
  Phase 2d (router): (12) decision 1 — the snapper and the session take the player's **feet** position and compare
  with floor y + 1; every point they return is a floor block; (13) decisions 7-8 — a player standing on a blocked
  edge gets no route (explained with an empty partial route), and "Guiding you to the gate" guides to the junction
  *before* the gate edge, not to the gate itself; (14) decision 10 — an edge "leaves" a no-exit domain when its
  region list lacks the domain's region, so the route ends on the last edge inside; (15) decision 13 — tunnel /
  bridge / stairs are chosen from the next edge's min/max y relative to the node (> 3 down → tunnel; > 3 up and back
  down → bridge; else stairs); (16) decision 15 — re-route rate limits (60 ticks for off-route/blocked, 200 ticks
  and > 15 % shorter for "something opened") — see the plan's "Phase 2d status". Phase 2e (api-client): (17)
  decision 1 — the two road ports take and return knk-core records; the API shapes without a core twin are new thin
  records in `C/domain/roads/`, two of which import feature packages (`ProposedProfile.Material`,
  `RoadNetworkSnapshot.Street`); (18) decision 3 — profile/survey `stats` travel as JSON text in knk-core and a JSON
  object on the wire, `null` on a profile PUT keeps the stored stats; (19) decision 5 — a never-built tile makes
  `tileGraph` fail with a 404 rather than answer empty (Phase 3 lists tiles first); (20) decision 8 — request dates
  are serialised per field as ISO strings because the client's `ObjectMapper` writes numeric timestamps by
  default — see the plan's "Phase 2e status". Phase 3 (paper admin side, **not compiled in the cloud — your first
  local `./gradlew build -x deployToDevServer` of the branch is its real compile**, expect a handful of one-line
  import/signature fixes, listed in order of likelihood in the plan's "Phase 3 status → Developer to-do"): (21)
  decision 3 — the tile builder runs on the build queue's own daemon thread, not the api-client pool; (22) decision
  4 — chunk capture expands chunk by chunk from the seeds along "frontier" chunks (a superset of the exact BFS,
  bounded by tile + margin, cap 1 600 chunks); (23) decision 9 — a block change marks a tile dirty when its material
  is any enabled profile's floor material or it is a road cell / its two headroom blocks, and WorldEdit edits mark
  every touched tile; (24) decision 12 — `build all` = API tile rows ∪ seed tiles ∪ domain-Location tiles in the
  world border; (25) decision 16 — a profile learned from a survey is created as class Road ×1.0 without scope (edit
  in the web app); (26) decision 1 — `NavigationConfig` is a top-level record in `P/config` (Bukkit-free, so the
  scratch build tests it) — see the plan's "Phase 3 status". Phase 5 (web app): (27) decision 1 — the world selector
  is a text field remembered in the browser (no world-list endpoint); (28) decision 8 — an edge PUT sends only the
  changed fields, "continue along the road" only with a street; (29) decision 11 — the Street form's road panel links
  with plain anchors (router imports break nine FormWizard test suites); (30) decision 13 — no edge delete in the UI;
  plus one trunk chore: `npm ci` fails on the current lockfile — see the plan's "Phase 5 status".
- **Cloud network:** `repo.papermc.io` and `maven.enginehub.org` were denied by the environment's network policy
  (proxy 403 on CONNECT) in links 1-8, so those links tested knk-core through the plan §0.4 scratch build and never
  compiled knk-paper. **Allowed by the developer on 2026-09-29** (both answer 200 now) — link 9 is the first link
  that builds the plugin with Gradle; its handoff makes Phase 3's real compile the first step.
- **Test when you have time:** pull `claude/road-navigation` in each repo; build the plugin (`./gradlew build -x deployToDevServer` — it compiles and its 2 803 tests are green as of `4e3f8af`, nothing to fix first); apply the new web-api migration to the dev DB (developer only); run the web-api; `./gradlew :knk-paper:dev`; `CYPRESS_INSTALL_BINARY=0 npm install && npm start` in knk-web-app (grant `knk.admin.road`, add the `streetRoad` field to the Street form — plan "Phase 5 status"); then each phase's live checklist from the plan in phase order (3 → 5 → 4: a built network is what `/navigate` needs).
- **Merging (developer):** phases are mergeable one by one in the order 1 (web-api) → plugin (2a-2e, 3 and 4 are one branch — merge `claude/road-navigation` into `main` once; it already contains `main` `27b4236`) → 5 (web-app); the closing handoff lists the branches to delete afterwards.

## Phase 1 — knk-web-api: data model, services, API (link 1)

- **Commits** (knk-web-api `claude/road-navigation`, cut from `master` `ccc8c02`): `55d5aaa` enums/models/DbContext/
  JsonColumn/RoadManage · `8553dec` migration `AddRoadNetwork` + bootstrap profile · `c7df10e` DTOs, mapping,
  repository, `RoadNetworkService`, labeler, components, tests · `77e0a29` controllers (ETag/304), Street counts,
  `StreetServiceTests`. Workspace `main`: this report, plan header + "Phase 1 status" block, tracker rows, handoff
  `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2a.md`.
- **Tests:** 1524 → 1627 passed, the same 5 known failures (named in the plan status), 42 skipped. Migration passed
  the four fresh-DB steps locally (MySQL 8.0.46 via apt) and in the `Migrations (fresh DB)` workflow on every
  commit that carries it (runs 108/110/111 green; 107 was the models-only commit, red as expected).
- **Acceptance:** Swagger shows the 17 road routes; a two-tile hand-made payload round-tripped on the running API
  (PUT 200 → GET with `ETag: "1"` → 304 on repeat; stitch across the tiles; dirty → Stale; 401/400 cases).
- **Flagged decisions:** 15, numbered in the plan status block; the four worth a look are in the summary above.
- **Discrepancies:** the cloud proxy blocks the dotnet install hosts but `apt-get install dotnet-sdk-8.0` /
  `mysql-server` work (plan §0.4 updated in the status block); web-api trunk had moved to `ccc8c02`; `dotnet run`
  listens on `localhost:5294` (launchSettings); `StreetsController` is in namespace `KnKWebAPI.Controllers`.
- **Live checklist:** plan "Phase 1 status → Developer to-do" (6 Swagger steps, ~5 min, payloads included).
- **Risks:** none open for this phase. Contract for later phases is written under "What later phases must wire".
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2a.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment) — link 2 = Claude Code Remote session `session_01HnoVDWFbstro88fNr2ntKM` (created 2026-09-27 19:46 UTC, same environment).

## Phase 2a — knk-plugin core: shared extractions + guard test (link 2)

- **Commits** (knk-plugin `claude/road-navigation`, cut from `main` `eb1d68c`, one per plan item): `35252c7` R1
  `util/BlockKey` (`GateSpatialIndex.packCell` delegates) · `4447afa` R2 `util/Polygon2D` (`GateFrameCalculator.
  pointInPolygon` delegates; new `closestPointOnBoundary`/`distanceToBoundary`) · `f5a8572` R3 `GateManager.
  closedFootprint(gateId)` · `f5c420d` R4 `GateStateListener` + `GateManager.addStateListener/removeStateListener/
  fireStateChanged` (fired on open start, close start, completion, forced state, cache) · `1ff918a` 15 characterisation
  tests for `SimpleRegionTransitionService` (no source change) · `af38414` R6 `regions/DomainAccessEvaluator`
  (`entry`/`exit` → `Optional<Denial>`; the service delegates, characterisation tests unchanged) · `db962a4`
  `ArchitectureGuardTest` (fails on any `org.bukkit` in `C/roads`, `C/navigation`, `C/domain/roads`, the two util
  helpers and the evaluator; proven with a deliberate violation). Workspace `main`: plan header + "Phase 2a status"
  block, this report, tracker row, handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2b.md`.
- **Tests:** knk-core 1024 → 1085, 0 failures, 0 skipped (61 new). **Not compiled with Gradle** — `paper-api` can't be
  resolved here (proxy denies `repo.papermc.io`); counts come from the plan §0.4 scratch build (real sources, stub
  `org.bukkit.util.Vector`, Maven Central only; recipe in the plan status block). knk-paper/knk-api-client not built,
  not touched. The existing gate tests (`GateSpatialIndexTest`, `GateFrameCalculatorTest`,
  `GateFrameCalculatorRegionModeTest`, `GateManagerTest`) pass unmodified apart from the R3/R4 additions in
  `GateManagerTest`.
- **Flagged decisions:** 7, numbered in the plan status block; 1-3 concern the `DomainAccessEvaluator` shape and only
  matter for the KNG-17 merge (whose `previewAccess` must delegate to it — noted there for the merger).
- **Discrepancies:** plan references all resolved on `eb1d68c`. Network: charter §9 says the two Maven hosts were
  allowed, but this environment still denies them; Maven Central additionally answers 429 to Gradle's parallel
  downloads through the proxy (fixed with `org.gradle.workers.max=2` + download retries in `~/.gradle/gradle.properties`).
- **Live checklist:** plan "Phase 2a status → Developer to-do" (local `./gradlew :knk-core:test` + full build, ~3 min of
  gate open/close and entry/exit-denied checks; nothing new is observable).
- **Risks:** KNG-17 merge touches `SimpleRegionTransitionService` (one import, one field, the two check methods
  rewritten here) — small, mechanical. `cacheGate` fires the state listener once per gate at startup (decision 6).
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2b.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 3 =
  Claude Code Remote session `session_01GHceCT4sjFzuGiq81wtJB7` (created 2026-09-27 20:09 UTC, parent this session
  `session_01HnoVDWFbstro88fNr2ntKM`).

## Phase 2b — knk-plugin core: survey maths (link 3)

- **Commits** (knk-plugin `claude/road-navigation`, on top of 2a's `db962a4`; trunk `main` unchanged at `eb1d68c`):
  `e7a5cb3` value types — `roads/survey/SurveySample` (record: floor, overlay, cross-section −7…+7 with null = no
  standable cell, x/y/z, onGround), `roads/survey/ProposedProfile` (materials with role/ambiguous/centreShare/
  edgeShare/samples, widthMin/widthMax, sampleCount — the `RoadProfileDto`/`RoadMaterialDto` names), `domain/roads/
  RoadMaterialRole` (shared enum, `apiName()`/`fromApiName()`) · `92375e5` `roads/survey/SurveyStats` (immutable
  counts per material per |offset| bucket 0-1/2-5/6-7, run ends, in-run, outside-run, overlays, width histogram;
  `of(samples)`, `merge`, `toJson`/`fromJson` = **StatsJson v1**, `{}` → empty) and `roads/survey/ProfileLearner`
  (`learn(SurveyStats) → ProposedProfile`; thresholds 0.6 / 15 % / 2× / 5 % / 10 % / 1 % / 5th-95th percentile as
  named constants). Workspace `main`: plan header + "Phase 2b status" block, this report, tracker row, handoff
  `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2c.md`.
- **Tests:** knk-core 1085 → 1130, 0 failures, 0 skipped (45 new: `SurveySampleTest` 7, `ProposedProfileTest` 3,
  `SurveyStatsTest` 17, `ProfileLearnerTest` 16, `RoadMaterialRoleTest` 2). The plan's four scenarios pass: (a)
  stone-brick road with andesite kerbs on grass → Surface + Edge, grass absent, width 7; (b) 1-wide gravel path in a
  forest → gravel is the Surface (not an Edge), width 1; (c) cobblestone kerb next to a cobblestone courtyard → Edge +
  ambiguous, not ambiguous without the courtyard; (d) `merge(of(A), of(B)) == of(A ++ B)` and equal proposals.
  **Not compiled with Gradle** (paper-api unresolvable, same 403 as links 1-2); counts from the §0.4 scratch build.
  `ArchitectureGuardTest` green with the new packages.
- **Flagged decisions:** 12, numbered in the plan status block; the ones worth a look are in the summary above
  (formula sensitivity for plazas / building-shared kerbs, per-survey run classification, the StatsJson layout).
- **Discrepancies:** none in the plan text. KNG-17 still not on `main`.
- **Live checklist:** nothing observable (pure maths); local `./gradlew :knk-core:test` expects 1130 green — plan
  "Phase 2b status → Developer to-do".
- **Risks:** the learner is a heuristic the admin reviews; its two known blind spots are decision 5. The StatsJson
  shape is the contract for Phase 2e/3/5 from now on (versioned; other versions are refused, not misread).
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2c.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 4 =
  Claude Code Remote session `session_01Ns8adeiE7FBtoTYbSMYvtb` (created 2026-09-27 20:32 UTC, parent this session
  `session_01GHceCT4sjFzuGiq81wtJB7`).

## Phase 2c — knk-plugin core: builder (link 4)

- **Commits** (knk-plugin `claude/road-navigation`, on top of 2b's `92375e5`; trunk `main` unchanged at `eb1d68c`):
  `2266921` `domain/roads/RoadNodeKind` (the rest of that commit was swallowed by `.gitignore`, see discrepancies) ·
  `cb8a7fd` `.gitignore` exception `!**/src/**/build/` + ports `SurfaceGrid`/`GateCells`/`ScopeLookup`,
  `PassabilityRules`, `ProfileSet`, `BuildParameters` · `6f870ff` `SpanGrid` (3D spans, one link per direction,
  step and diagonal rules) + test `GridFixture` · `96d40d6` `MaskBuilder`, `RoadMask`, `DistanceTransform`,
  `BuildWarning` · `23f9afa` `Thinning` (Zhang-Suen + Holt), `Rdp`, `ProfileMatcher` · `4808d1b` `SkeletonGraph`,
  `NodeMatcher`, `TileBuilder`/`TileBuildResult`, thinning corner-end guard · `c2ca1e3` `TileBuilderTest` (the plan's
  golden list) + cleanups. Workspace `main`: plan header + "Phase 2c status" block, this report, tracker row, handoff
  `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2d.md`.
- **Tests:** knk-core 1130 → **1280**, 0 failures, 0 skipped (150 new across 14 classes). All 16 golden scenarios of
  the plan pass with exact or ±1 lengths: meandering 1-wide path; 5-wide road → one centreline of length 29 for 30
  cells; T, X and 5-way → one junction each; 15×15 plaza with four exits → one junction, four edges of 23; stairs
  up a hill; tunnel under a road, bridge over a road, two stacked streets → separate edges, no junction; spiral ramp
  → one edge climbing over itself; gravel into stone → one edge, dominant profile; cobblestone courtyard held by
  `ambiguousReach`; 2-block gap → two components; closed gate → one edge with `gateDoorIds`; tile-border crossing →
  Boundary nodes on the border cells (both tiles' views); rebuild with one block changed → every `existingId` kept.
  **Not compiled with Gradle** (paper-api unresolvable, same 403 as links 1-3); counts from the §0.4 scratch build.
  `ArchitectureGuardTest` green with the new package.
- **Flagged decisions:** 20, numbered in the plan status block; the four worth a look are in the summary above
  (floor-y convention, plaza threshold vs `widthMax`, thinning consequences, border limitation).
- **Discrepancies:** knk-plugin's `.gitignore` (`**/build/`) hid the plan's package `core/roads/build/` — fixed with a
  `src/**/build/` exception (a one-line change the developer may prefer to review); `GridFixture` lives in the
  `roads/build` test package; DESIGN §5.5's "width = 2 × dt" is `2·dt − 1` with border `dt = 1`; "local width" for
  spurs is the spur's own median width; textbook Zhang-Suen needed two additions for staircases and the non-planar
  span grid. Cloud network unchanged. KNG-17 still not on `main`.
- **Live checklist:** nothing observable (pure core); local `./gradlew :knk-core:test` expects 1280 green — plan
  "Phase 2c status → Developer to-do".
- **Risks:** the builder's output quality depends on `widthMax` being ≥ the real road width (decision 7) and on
  1-wide diagonal paths being 4-connected staircases (decision 4); junctions within one block of a tile border may
  not stitch (decision 15). All surface in Phase 3's `/knk road build` summary and overlay, none blocks 2d/2e.
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2d.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 5 =
  Claude Code Remote session `session_015VRbxcdymMMgk4go3KJYSg` (created 2026-09-27 21:33 UTC, parent this session
  `session_01Ns8adeiE7FBtoTYbSMYvtb`).

## Phase 2d — knk-plugin core: router and navigation session (link 5)

- **Commits** (knk-plugin `claude/road-navigation`, on top of 2c's `c2ca1e3`; trunk `main` unchanged at `eb1d68c`):
  `1f569b7` `domain/roads/{RoadClass,RoadEdgeFlag,RoadEdgeSource,RoadNode,RoadEdge}`, `roads/route/{RoadNetworkSnapshot,
  EdgePolyline,SegmentIndex}` + the shared test fixture `NetworkFixture` · `5f3f41e` `RouterParameters`, `SnapPoint`,
  `Snapper` · `c84b556` `EdgeVerdict`, `AccessPolicy`, `CompositeAccessPolicy`, `StaticFlagsAvailability`,
  `GateAvailability`, `DomainAvailability` · `f371323` `Route`, `RouteRequest`, `RouteResult`, `AStarRouter`,
  `BlockedExplainer` · `33efa64` `RegionShape`, `RegionClosestPoint`, `Maneuver`, `ManeuverBuilder`, `EtaEstimator`,
  `CoverageCheck` · `a82db3c` `navigation/{SessionParameters,NavigationEffect,NavigationSession}`. Workspace `main`:
  plan header + "Phase 2d status" block, this report, tracker row, handoff
  `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2e.md`.
- **Tests:** knk-core 1280 → **1364**, 0 failures, 0 skipped (84 new across 10 classes) — every item of the plan's
  2d test list (shortest path vs class costs, oneway, closed gate → explained + partial route, pass-through gate →
  hint, entry denied → route ends at the region edge with the reason, exit denied, different components → refused,
  snap prefers the bridge over the road below, region multi-goal, maneuver bands and level phrases, session
  off-route / rate limit / arrival / gate closes mid-route). **Not compiled with Gradle** (paper-api unresolvable,
  same 403 as links 1-4); counts from the §0.4 scratch build. `ArchitectureGuardTest` green with `roads/route` and
  `navigation`.
- **Flagged decisions:** 18, numbered in the plan status block; the five worth a look are in the summary above
  (feet-vs-floor coordinates, blocked start edge, "to the gate" = to the junction before the gate edge, the domain
  exit rule, the level-change phrase rule, the re-route rate limits).
- **Discrepancies:** the plan's `RegionShape → goal set` is split into `RegionShape` (geometry) and
  `RegionClosestPoint` (DESIGN §4's name); `Oneway` is handled by the router rather than a policy (the plan's
  `check(RoadEdge)` has no direction); DESIGN §6.5 needed a rule for choosing tunnel / bridge / stairs. Cloud network
  unchanged. KNG-17 still not on `main`.
- **Live checklist:** nothing observable (pure core); local `./gradlew :knk-core:test` expects 1364 green — plan
  "Phase 2d status → Developer to-do".
- **Risks:** none for 2e/3. Phase 4 must respect the wiring notes in the status block (feet coordinates in,
  floor coordinates out; the 2-second re-check feeds `onElementBlocked`; policies are per request and never shared).
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-27-road-navigation-phase-2e.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 6 =
  Claude Code Remote session `session_01MUaznjnfwJ88nqc1o1Cnkw` (created 2026-09-27 22:10 UTC, parent this session
  `session_015VRbxcdymMMgk4go3KJYSg`).

## Phase 2e — knk-plugin api-client: ports, DTOs, mapper, conditional GET (link 6)

- **Commits** (knk-plugin `claude/road-navigation`, on top of 2d's `a82db3c`; trunk `main` unchanged at `eb1d68c`):
  `4fdece7` ports `C/ports/api/{RoadNetworkQueryApi,RoadNetworkCommandApi}`, `C/domain/common/Conditional<T>`, the
  `C/domain/roads/` API records (`RoadTile`, `RoadTileGraph`, `RoadTileUpsertResult`, `RoadProfile`,
  `RoadProfileUpsert`, `RoadSurvey`, `RoadSurveyCreate`, `RoadBreadcrumbPoint`, `RoadSeed`, `RoadSeedCreate`,
  `RoadSeedSource`, `RoadSeedLocation`, `RoadNetworkMeta`, `RoadComponent`, `RoadNodeUpdate`, `RoadNodeAnchor`,
  `RoadEdgeUpdate`, `RoadEdgeRecord`, `RoadEdgeUpdateResult`, `RoadApiError`) and `RoadNode.locked` ·
  `e45a84c` `A/dto/Road*Dto` (29 records mirroring `RoadDtos.cs`) + `A/mapper/RoadMapper` (both directions, the
  knk-core adapters `toBuilderProfile`/`toSnapshotProfile`/`toPreviousGraph`/`toAnchors`, `error(ApiException)`) ·
  `4ed4b22` `BaseApiImpl.getConditional` + `ConditionalResponse` (R17, additive) · `4ffdd1a`
  `A/impl/{RoadNetworkQueryApiImpl,RoadNetworkCommandApiImpl}` wired in `KnkApiClient`
  (`getRoadNetworkQueryApi()`/`getRoadNetworkCommandApi()`). Workspace `main`: plan header + "Phase 2e status"
  block, this report, tracker row, handoff `docs/ai-agents/handoffs/2026-09-28-road-navigation-phase-3.md`.
- **Tests:** knk-core 1364 → **1374** (0 failures, 0 skipped); knk-api-client **134 → 174** (baseline measured before
  any change at `a82db3c`: 134, 0 failures, 2 skipped = the two live-only `SiegeQueryApiLiveTest` cases, unchanged
  after; 40 new: `RoadMapperTest` 13, `BaseApiImplConditionalGetTest` 6, `RoadNetworkQueryApiImplTest` 11,
  `RoadNetworkCommandApiImplTest` 9). Every item of the plan's 2e test list: mapper round-trips both ways, conditional
  GET 200/304 (plus weak tag, missing response ETag, 404), routes/verbs/headers/bodies of the 1.5 table, error body
  mapping. **Not compiled with Gradle** (paper-api unresolvable through knk-core, same 403 as links 1-5); counts from
  the §0.4 scratch build extended to a two-project build (`core` + `apiclient`, recipe in the plan status block).
  `ArchitectureGuardTest` green. knk-paper not built, not touched.
- **Flagged decisions:** 13, numbered in the plan status block; the four worth a look are in the summary above
  (ports on knk-core types with two domain → feature-package imports, stats as JSON text, 404 semantics, ISO dates
  per field).
- **Discrepancies:** the 2e handoff conflated `GET api/road-seeds` with the D12 `seed-locations` box query (both are
  exposed); the client `ObjectMapper` writes dates as timestamps (no earlier request DTO sent one); Java records
  refuse static factories named like a component (`unnamed()`/`unlabelled()` instead of `clearName()`/`clearStreet()`).
  Cloud network unchanged. KNG-17 still not on `main`.
- **Live checklist:** nothing observable in game (plumbing); local `./gradlew :knk-core:test` expects 1374 and
  `./gradlew :knk-api-client:test` 174 (2 skipped) — plan "Phase 2e status → Developer to-do" (optional 2-minute
  ETag/304 check against the running API).
- **Risks:** none for Phase 3 beyond the wiring notes in the status block (futures complete on the api-client
  executor; a never-built tile is a 404; unknown `StatsJson` versions throw and must be shown, not overwritten).
  Phase 3 itself cannot be compiled in the cloud (knk-paper) — the charter says implement by careful reading and
  mark "not compiled"; the developer's first local build of the branch is the real compile.
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-28-road-navigation-phase-3.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 7 =
  Claude Code Remote session `session_01NPPpKzLCV3MKUQkAwnYUz4` (created 2026-09-28 05:23 UTC, parent this session
  `session_01MUaznjnfwJ88nqc1o1Cnkw`).

## Phase 3 — knk-plugin paper: admin side (survey, build, review) (link 7)

- **Commits** (knk-plugin `claude/road-navigation`, on top of 2e's `4ffdd1a`; trunk `main` unchanged at `eb1d68c`):
  `9fe993a` navigation config (`P/config/NavigationConfig`, `ConfigLoader.loadNavigation`, `config.yml`, R16) ·
  `efc9251` R8 `P/regions/RegionIds` (tracker, lookup, discovery listener delegate) · `f71ec99` R9 `P/utils/ParticleDraw`
  (`SiegeWorldPresenter.ring` delegates) · `939baa1` R10 `P/utils/KnkLocations` (`SiegeBukkit` delegates) · `0f6a206`
  R11 `P/utils/TickBudget` (three `GateBlockScanTaskHandler` copies delegate) · `f0385ad` R25
  `P/gates/GatePassThroughRules` · `4804561` R4 paper fire points (`HealthSystem`, `GateAnimationTask` jam,
  `GateCommand` toggles) · `138bfc4` `RoadNetworkCache` + `RoadTileCache` + `TileKey` + `RoadMessages` · `b1665ff`
  `RoadDirtyTracker` + `DirtyTiles` · `3b5c408` `RoadOverlayRenderer` + `OverlayColors` · `8017e55`
  `ChunkSnapshotSurfaceGrid`/`CompactSurfaceGrid` + `SpanExtractor` + `CompactSpans` + `GateCellsIndex` · `d46d564`
  `RoadBuildJob` + `RoadBuildQueue` + `BuildQueueState` · `cab864d` `RoadSurveyService`/`RoadSurveySession` +
  `SurveySamplingGate` + `CrossSectionSampler`, `RoadAdminCommand`, `KnKPlugin.initializeRoads` wiring, `plugin.yml`
  nodes · `96f4c62` tests (17 files). 59 files, +7 580 / −101. Workspace `main`: plan header + "Phase 3 status" block,
  this report, tracker row, handoff `docs/ai-agents/handoffs/2026-09-28-road-navigation-phase-5.md`.
- **Tests:** knk-core **1374 → 1374**, knk-api-client **174 → 174** (2 skipped) — untouched, re-run through the §0.4
  scratch build. knk-paper **cannot be compiled or tested in the cloud** (paper-api, WorldGuard, WorldEdit
  unresolvable — same proxy 403 as links 1-6); the scratch build gained a third project that compiles the 14
  Bukkit-free paper files (config, tile maths, cache codec, dirty rules, overlay colours, span extraction + compact
  grid, survey gates + cross-section, queue state, survey session) against knk-core, the api-client and Adventure from
  Maven Central: **34 tests, 0 failures**, including the real `TileBuilder` running on the compact extraction of a
  fake world with a closed gate across the road (door id on the edge, zero out-of-contract grid queries). Five more
  test files (17 tests: `ConfigLoaderNavigationTest`, `GatePassThroughRulesTest`, `ParticleDrawTest`,
  `RoadDirtyTrackerTest`, `RoadAdminCommandTest`) need paper-api + Mockito and are **written, not run**.
- **Flagged decisions:** 20, numbered in the plan status block; the six worth a look are in the summary above (build
  thread, frontier capture, dirty rule, `build all` scope, new-profile defaults, top-level config record).
- **Discrepancies:** `KnkAdminCommand.registerSubcommand` already takes a tab completer (no `onTabComplete` edit);
  `CacheManager` has no `StreetCache` (constructed in `initializeRoads`); `KnkApiClient` has no executor getter;
  `RegionIds` is in `P/regions/` per plan §2 (the handoff said `P/utils/`); `SessionParameters` has no
  `withSprintSpeed`; `MaskBuilder.snapSeed`'s direct floor scan is a no-op on the compact grid (the radius search
  still snaps seeds). Cloud network unchanged. KNG-17 still not on `main`.
- **Live checklist:** plan "Phase 3 status → Developer to-do" — (1) local build, fix the import/signature slips it
  finds (likely spots listed there), (2) `./gradlew :knk-paper:test`, (3) survey three road types → Save; `/knk road
  build radius 1500`; `/knk road show`; a street label with `--continue`; a broken road block marks the tile dirty
  within 30 s; `build dirty` keeps names; WorldEdit edit marks dirty; restart mid-`build all` resumes.
- **Risks:** the whole phase is uncompiled Paper code written against the neighbouring files' signatures — the first
  local build is the real check; each slip should be a one-liner. The frontier capture and the budgeted tagging were
  designed for TPS, not measured; `/knk road build status` shows where a slow build spends its time. WorldEdit's
  `EditSessionEvent` hook runs under FAWE off the main thread — `DirtyTiles` is thread-safe for that reason. Phase 4
  should build on `plugin.getRoadNetworkCache()`, `getRegionTracker().regionIds()`, `GatePassThroughRules.canPass`
  and `ParticleDraw.polyline` (all listed in the status block's "→ 4" note).
- **Next link:** handoff `docs/ai-agents/handoffs/2026-09-28-road-navigation-phase-5.md`; started per charter §6
  option 1 (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 8 =
  Claude Code Remote session `session_0137PksZMzCVnVX6YkMD5cSg` (created 2026-09-28 06:15 UTC, parent this session
  `session_01NPPpKzLCV3MKUQkAwnYUz4`).

## Phase 5 — knk-web-app: admin pages (link 8)

- **Commits** (knk-web-app `claude/road-navigation`, cut from `main` `f56d421`): `26de19e` road DTOs + `roadClient` +
  `Controllers` entries · `23c64ef` `/admin/roads` route, nav link, `RoadsAdminPage` shell (world selector) ·
  `ba79450` `RoadProfilesCard` + `roadProfileForm.ts` + `MaterialKeyInput` · `d60b458` `RoadTilesCard` · `baf9c20`
  `RoadEdgesCard` (+ `StreetsOperation.Create`) · `ff3ad61` `StreetRoadPanel` registered as `streetRoad` · `9dbb481`
  page tests, panel links as anchors. 17 files, +2 784 / −1. Workspace `main`: plan header + "Phase 5 status" block,
  this report, tracker row, handoff `docs/ai-agents/handoffs/2026-09-28-road-navigation-phase-4.md` (for later).
- **Tests:** `npm run test:ci` on the clean checkout — **10 failed suites / 16 failed tests, 381 passed, 397 total**
  (the trunk baseline the plan asked for; the ten suites are named in the plan status, most fail to run on
  `react-router-dom` / missing-module resolution). After Phase 5: **10 / 16 failed, 417 passed, 433 total** → +36
  (client 8, form 8, panel 5, page 15), the same ten suites. `CI=true npm run build`: TypeScript clean; the same 36
  pre-existing ESLint warnings in 20 files before and after, none in a touched file.
- **Flagged decisions:** 15, numbered in the plan status block; worth a look: (1) the world selector is a remembered
  text field (no world-list endpoint), (8) an edge PUT sends only the changed fields and `propagate` only with a
  street, (11) the street panel links with plain anchors because nine FormWizard test suites import `FieldRenderers`
  without a router mock, (13) no edge delete in the UI.
- **Discrepancies:** trunk `npm ci` fails (lockfile out of sync: `yaml@2.9.1`) — `CYPRESS_INSTALL_BINARY=0 npm
  install` is the cloud recipe, the lockfile diff was not committed; `tsconfig.app.json` is a Vite leftover (the CRA
  build is the type check); `streetClient.create` referenced a non-existent `StreetsOperation.Create` (declared now);
  DESIGN §7 says `knk.admin.roads`, everything built uses `knk.admin.road`.
- **Live checklist:** plan "Phase 5 status → Developer to-do" — grant `knk.admin.road`; add the `streetRoad` display
  panel field to the Street FormConfiguration (dev-DB step, described there); then the 8-step walk-through of the
  page (profiles, tiles, edge labelling with "continue along the road", create street, rename link, street panel).
- **Risks:** the page was verified with Jest against mocked clients only — the first run against the real API is the
  developer's; the request shapes were read from `Dtos/RoadDtos.cs` and the controllers on `claude/road-navigation`
  `77e0a29`, so a mismatch would be a name typo, not a design gap. `SearchableDropdown` loads the whole street/town
  list once (1 000 cap) — fine at this project's scale.
- **Next link:** on 2026-09-28 none was started — KNG-17 was not on knk-plugin trunk (`origin/main` `eb1d68c`), so per
  charter §4.7 the Phase 4 handoff was written for later. **Resumed 2026-09-29:** KNG-17 merged to trunk on
  2026-09-28 (plugin `main` now `27b4236`) and the developer allowed the two Maven hosts, so link 8's session updated
  the handoff (Phase 3 real compile first, then trunk merge, then Phase 4) and started link 9 per charter §6 option 1
  (Claude Code Remote `create_session` in the same environment, `source_url` = knk-workspace `main`) — link 9 =
  Claude Code Remote session `session_01EeBiwHtsk7WJ3LSFG1voJa` (created 2026-09-29 08:10 UTC, parent this session `session_0137PksZMzCVnVX6YkMD5cSg`).

## Phase 4 — knk-plugin paper: `/navigate` (link 9)

- **Setup facts:** Java 21 present; `repo.papermc.io` and `maven.enginehub.org` answered 200 — the first link to build
  the plugin with Gradle. Maven Central 429s on parallel downloads needed link 2's `~/.gradle/gradle.properties`
  settings, and a *short* retry backoff (`max.tentatives=6`, `initial.backoff=1500`; with 12 × 2 000 ms the first
  attempt stalled > 25 min on EngineHub retries). Every later build ran `--offline`.
- **Order followed (handoff):** (1) Phase 3's first real compile on `96f4c62` → clean; 1 of knk-paper's 821 tests
  failed (quoted names in tab completion) → `68fa48c`; (2) `git merge origin/main` (`27b4236`, KNG-17 + KNG-32 +
  managed regions) → `be5df0f`: three conflicts (`KnkConfig`, `ConfigLoader`, `SiegeBukkit` imports) resolved by
  keeping both sides, `KnKPlugin`/`SimpleRegionTransitionService`/`WorldGuardRegionTracker` auto-merged, teleport's
  inline data-access construction promoted to the Phase 3 fields (R18); (3) Phase 4.
- **Commits** (knk-plugin `claude/road-navigation`): `68fa48c` Phase 3 compile fix · `be5df0f` trunk merge ·
  `7500f44` R22 `C/util/BlockProbe`, `SurfaceGrid extends` · `be329f7` R21 `C/util/NamedTargets<T>`, `WarpTargets`
  wrapper · `40ee42e` R20 `C/navigation/DomainLocationResolver`, `SpawnDestinationResolver` delegates · `aa71dae` R6
  follow-up (`previewAccess` pinned to the evaluator) · `57c1605` R24 `siegeGates` field + getter · `05f5639` R39
  `SiegeGateController.canCarryNonMember` · `0fd5f43` `searchAsync` on Locations/Streets data accesses (R18),
  `GatePassThroughRules.canPass(admin, useNode, door)` (R25) · `cdc73d1` events, `NavigationMessages`,
  `NavigationHud`, `TrailRenderer` · `9717036` `NavTarget`, `Destination`, `RegionShapes` + WorldGuard adapter,
  `NavigationEligibility`, `NavigationDestinations`, `NavigateCommand` · `cfe49f4` `NavigationAccess`,
  `NavigationService` (live re-routes, D13), `NavigationListener`, `KnKPlugin.initializeNavigation`, `/navigate` in
  `plugin.yml`, `/knk road why` · `4e3f8af` tests. 52 files, +4 444 / −183 on top of the merge. Workspace `main`:
  plan header + Phase 3 compile note + "Phase 4 status", this report, tracker row, closing handoff.
- **Tests (Gradle):** Phase 3 baseline `68fa48c` knk-core **1374**, knk-api-client **174** (2 skipped), knk-paper
  **821** (14 skipped) → after the merge **1532 / 184 / 1027** → after Phase 4 **1545 / 184 / 1074**, 0 failures.
  Phase 4 added 13 core tests (`NamedTargetsTest`, `DomainLocationResolverTest`, one `previewAccess`
  characterisation) and 47 paper tests (`NavigationServiceTest` 16, `NavigateCommandTest` 9,
  `NavigationDestinationsTest` 6, `NavigationMessagesTest` 5, `NavigationHudTest` 4, `TrailRendererTest` 7). Teleport
  (`WarpTargetsTest`, `SpawnDestinationResolverTest`, …), siege + gate (206) and Phase 3 tests unchanged and green.
- **Flagged decisions:** 18, numbered in the plan status block; the six worth a look are in the summary above
  (bypass predicate, R39 semantics, direct mode's reach, catalogue refresh, re-check cadence / network swaps,
  `KnkConfig` constructors).
- **Discrepancies:** `previewAccess` already reached the evaluator after the merge (the R6 follow-up is a test);
  streets for the catalogue come from the snapshot, not `StreetsDataAccess.searchAsync` (added anyway, R18);
  WorldEdit resolves as 7.3.0 through WorldGuard 7.0.10 (deprecation warnings on `BlockVector3.getBlockX()`);
  Phase 3's `RoadAdminCommandTest` expected an unsorted completion list; Gradle's retry backoff (above).
- **Live checklist:** plan "Phase 4 status → Developer to-do" — build; `/navigate` to a Location, a Town spawn, a
  Town `region`, a Structure, a street, a node; through a tunnel; close a gate on the route → detour or "Guiding you
  to the gate", open it → "shorter route"; pass-through hint; `allowEntry=false` domain → "Guiding you to its edge";
  the two 48-block refusals and direct mode; walk off → re-route; stop / teleport / death / siege join end it;
  `/knk road why`; `/tps` with a few navigators.
- **Risks:** the runtime was unit-tested with inline executors and a mocked player, not on a server — the first
  live session is the check for thread hops (`MenuService.mainThreadExecutor` everywhere), the boss bar and
  particle rates; `WorldGuardRegionShapes` and the WorldEdit vector accessors compile against 7.3.0 and run against
  whatever the dev server carries (`getBlockX()` exists in both); the D13 policy rebuild reads every gate of the
  network per session per 2 s (dozens of `getGate` calls — trivial, but visible if a network ever tags hundreds of
  doors); a destination catalogue of thousands of places is one paged download per minute.
- **Next link:** none — Phase 4 was the last phase (charter § top): the chain is complete. Closing handoff
  `docs/ai-agents/handoffs/2026-09-29-road-navigation-closeout.md` (merge order, branches to delete after the
  merges, where the live checklists are). No session was started.
