# Road navigation chain — progress report

**Status:** running
**Last updated:** 2026-09-27 (link 3: Phase 2b done; link 4 started on Phase 2c)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) · **Charter:** `docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md` · **Plan:** `docs/specs/navigation/IMPLEMENTATION_PLAN.md`

## Summary for the developer

| Phase | State | Branch heads | Details |
|---|---|---|---|
| 1 — knk-web-api: data model, services, API | **done** (link 1) | knk-web-api `claude/road-navigation` `77e0a29` (from `master` `ccc8c02`) | [Phase 1](#phase-1--knk-web-api-data-model-services-api-link-1) |
| 2a — plugin core extractions | **done** (link 2) | knk-plugin `claude/road-navigation` `db962a4` (from `main` `eb1d68c`) | [Phase 2a](#phase-2a--knk-plugin-core-shared-extractions--guard-test-link-2) |
| 2b — survey maths | **done** (link 3) | knk-plugin `claude/road-navigation` `92375e5` (on 2a's `db962a4`; trunk `main` still `eb1d68c`) | [Phase 2b](#phase-2b--knk-plugin-core-survey-maths-link-3) |
| 2c — builder | in progress (link 4) | knk-plugin `claude/road-navigation` (continues from `92375e5`) | |
| 2d — router | not started | — | |
| 2e — api-client | not started | — | |
| 3 — plugin paper admin side | not started | — | |
| 5 — web-app admin pages | not started | — | |
| 4 — `/navigate` | waiting for KNG-17 on trunk | — | |

- **Review first** (ranked): (1) Phase 1 decision 1 — stitch edges are owned by the last-built tile and reference the
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
  (flat per-material counts) is now fixed by the plugin — see the plan's "Phase 2b status".
- **Cloud network, please check:** `repo.papermc.io` and `maven.enginehub.org` are still denied by the environment's
  network policy (proxy 403 on CONNECT) in links 1 and 2, so no link can compile knk-paper or run knk-core through
  Gradle; knk-core is tested through the plan §0.4 scratch build instead. Adding both hosts to the environment's
  allowed domains would let later links build the real thing.
- **Test when you have time:** pull `claude/road-navigation` in each repo; build the plugin (`./gradlew build -x deployToDevServer`, fix compile errors first if any link marked knk-paper "not compiled"); apply the new web-api migration to the dev DB (developer only); run the web-api; `./gradlew :knk-paper:dev`; then each phase's live checklist from the plan in phase order.

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
  option 1 (Claude Code Remote `create_session`, same environment) — link 4 = Claude Code Remote session
  `session_01Ns8adeiE7FBtoTYbSMYvtb` (created 2026-09-27 20:32 UTC, parent `session_01GHceCT4sjFzuGiq81wtJB7`).
