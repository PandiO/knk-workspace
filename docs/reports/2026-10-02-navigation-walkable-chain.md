# Navigation walkable-path chain — progress report

**Status:** running (links 1-3 done; link 4 next)
**Last updated:** 2026-10-02 (link 3)
**Charter:** [`docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md`](../ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) (reconcile), [KNG-51](https://linear.app/kngpandi/issue/KNG-51) (implement)
**Design:** [`docs/specs/navigation/LAST_MILE_PATHFINDING.md`](../specs/navigation/LAST_MILE_PATHFINDING.md)

This file is append-only: each link adds its own section below; only the summary and the header are refreshed.

## Summary for the developer

| Link | Phase | State | Branch heads | Details |
|---|---|---|---|---|
| 1 | KNG-27 reconciliation | **done** 2026-10-02 | knk-plugin `claude/navigation-walkable-path` `d8507a3` (= `claude/road-navigation` `075ae94` + 1 test commit); workspace `main` | [Link 1](#link-1--kng-27-reconciliation) |
| 2 | KNG-51 Phase A (`knk-core roads/walk/`) | **done** 2026-10-02 | knk-plugin `claude/navigation-walkable-path` `ad311ae` | [Link 2](#link-2--kng-51-phase-a-knk-core-roadswalk) |
| 3 | KNG-51 Phase B (knk-paper capture, cell access) | **done** 2026-10-02 | knk-plugin `claude/navigation-walkable-path` `aa320e5` | [Link 3](#link-3--kng-51-phase-b-knk-paper-capture-and-cell-access) |
| 4 | KNG-51 Phase C (`DirectLeg`, walk trail, config) | next | — | — |

**Review first**
1. `IMPLEMENTATION_PLAN.md` "§5.5 status" — all six fix-plan items are code-complete on `claude/road-navigation`; every
   item's live "Verify" step is still yours. Item 6 skipped the planned "catalogue residual cases after item 5 is
   verified live" step (items 5 and 6 landed together), so your rebuild re-test is the first real check.
2. Stretches recorded with `/knk road record` before `8b6d678` sit one block too deep — re-record them.
3. Plugin `9dccb58` and API `c029186` must be deployed together (an older plugin can't parse the `Pruned` node kind).
4. Link 2's decisions L2-1 … L2-10 (walk rules the design left open) — none changes behaviour in game yet; the ones
   you would notice live are L2-2 (head under water = not walkable), L2-4 (no diagonal through doorways) and L2-5
   (a 3-block drop costs 33).
5. The 96×96 worst case is ~80-90 ms (off the main thread, budget-bounded), more than the design's "milliseconds"
   guess — fine for one search per player, worth watching in Phase B/C live tests.
6. Link 3's L3-1 (the walk capture is its own per-block flags capture, not `CompactSpans` with a permissive
   `roadFloor`), L3-3 (door rule = WorldGuard `testBuild(INTERACT, USE)` + the domain regions) and L3-5 (domain
   lookups happen on the routing thread) — none is visible in game until Phase C wires them.

**Test when you have time:** pull `claude/navigation-walkable-path` in knk-plugin; `./gradlew build -x deployToDevServer`;
`./gradlew :knk-paper:dev`; then the live checklist (link 1's is the KNG-27 re-test below; links 2-4 add theirs).

## Link 1 — KNG-27 reconciliation

**Session:** Claude Code cloud session, 2026-10-02 ~19:00-20:00 UTC. Started from the link-1 handoff
(`2026-10-02-navigation-walkable-link-1.md`).

### Setup
- Heads at start (unchanged during the link): knk-plugin `origin/claude/road-navigation` `075ae94` (trunk `main`
  `27b4236` contained), knk-web-app `6414e18`, knk-web-api `c029186`. `claude/road-navigation-smoke-test-bugs-fagl4i`
  is still identical to `claude/road-navigation` in all three repos. No new developer commits after 18:00 CEST.
- Created knk-plugin **`claude/navigation-walkable-path`** from `origin/claude/road-navigation` `075ae94`; `origin/main`
  was already contained (no merge commit). Pushed with `-u`. Push checks: plugin feature branch ✔, workspace `main` ✔.
- Network: `repo.papermc.io`, `maven.enginehub.org`, Maven Central all 200 — **knk-paper compiles in the cloud**.

### Baselines (for links 2-4) — knk-plugin `075ae94`, `./gradlew build -x deployToDevServer`, BUILD SUCCESSFUL

| Module | Tests | Failures | Skipped |
|---|---|---|---|
| knk-core | **1561** | 0 | 0 |
| knk-api-client | **184** | 0 | 2 |
| knk-paper | **1088** | 0 | 14 |

After link 1 (`d8507a3`): knk-core 1561, knk-api-client 184, **knk-paper 1089** (+1, link 1's test). Links 2-4 compare
against these numbers. Counted from `*/build/test-results/test/*.xml`.

Other repos (read/run only, no changes): knk-web-api `c029186` `dotnet test` (SDK 8 installed in the session): 1631
passed / 5 failed / 42 skipped — the 5 are the known non-road baseline failures. knk-web-app `6414e18`: road suites
(`components/admin/roads`, `components/roads`) 16/16; `npm ci` fails on a stale lockfile (`yaml@2.9.1` missing) and
`@testing-library/dom` is not a declared dependency — both pre-existing, not KNG-27's.

### §5.5 verification
Per item (commits, code vs plan, tests, live status): `IMPLEMENTATION_PLAN.md` → "§5.5 status". Short form:

| Item | Commit(s) | Code | Tests | Live |
|---|---|---|---|---|
| 1 FeedbackModal | web-app `6414e18` | ✔ (only call site in the road tree) | ✔ | click-through |
| 2 region goals follow the road | plugin `6a73945` | ✔ | ✔ | needs live |
| 3 direct-mode re-check | plugin `6a73945` (+ link 1 test `d8507a3`) | ✔ | ✔ (gap closed) | needs live |
| 4 "already in X" | plugin `6a73945` | ✔ (WorldGuard containment, checked first) | ✔ | needs live (4-case matrix) |
| 5 plaza = one junction | plugin `9f66fea` | ✔ | ✔ | live rebuild |
| 6 cleanup survives rebuild | plugin `ef556e2`, `6a8caa7`, `9dccb58`, `075ae94`; web-api `8523ec8`, `c029186` | ✔ (locked-node reach instead of an exclusion zone; plan left it open) | ✔ | residual cases need live |

### Commits
- knk-plugin `claude/navigation-walkable-path`: `d8507a3` — test `theLastLegAfterTheRoadsEndUsesTheDirectReCheck`
  (item 3's "the `arrivedAtRouteEnd` handoff participates in the recheck" had no test; test only, behaviour unchanged).
- knk-workspace `main`: tracker claim; `IMPLEMENTATION_PLAN.md` "§5.5 status" + header; smoke-test guide
  cross-references for findings B, C, D, E, G and Phase 4/5 findings 1-7, plus a "rebuild re-test (2026-10-02)" block
  reconstructed from the developer's commits; KNG-27 tracker row corrected (the 2026-10-01 "paused" row was stale);
  this report; link 2's handoff.

### Flagged decisions
- **L1-1:** the link-1 test commit lives on `claude/navigation-walkable-path`, not on `claude/road-navigation` (the chain
  never pushes there). It reaches trunk when this branch does; cherry-pick `d8507a3` if you merge
  `claude/road-navigation` first and want it there.
- **L1-2:** nothing else was fixed. Open items found but out of §5.5 scope (written up, not fixed): finding D (upload
  timeout), finding E (no node/tile delete; restart for builder settings), `/knk road node info here`, a "prefer the
  domain's Location" option (smoke-test finding 4).

### Discrepancies
- The tracker and the workspace docs did not record any of the §5.5 work (corrected).
- Item 6 deviates from the plan's sketch (exclusion zone per locked node) — it uses a build-wide `locked-node-reach`
  (default 8) and duplicate absorption; the plan left the radius question open, so this is within scope.
- knk-web-api `master` has 19 commits `claude/road-navigation` lacks — merge before merging to trunk.

### Live checklist (developer) — KNG-27 re-test
1. Full restart (builder keys are read only in `onEnable`; new keys `navigation.builder.plaza-growth` default 2,
   `locked-node-reach` default 8); rebuild tile 2,-2 and a
   known problem plaza → one junction per plaza, no "Boundary node … not on the tile border".
2. Merge a duplicate junction pair, rebuild the tile → stays merged. Prune a spur (`/knk road node prune`), rebuild →
   stays out; `unprune` brings it back.
3. Re-record stretches recorded before `8b6d678`.
4. `/navigate` to a District/Structure region with roads nearby, from several sides → trail follows the road, short
   last leg only; a region with no road near it → straight line (or refusal beyond 48 blocks).
5. Stand inside a cuboid and a polygon region (mid-height, boundary block, stacked level) → "You are already in X".
6. Direct mode: walk away → "heading away … recalculating"; routed: leave the road → "You left the road"; reach a
   road's end short of the target and walk away → the same "heading away" message.
7. Web app: delete a road profile → FeedbackModal, failure keeps the modal open.
8. Then resume Phase 4 item 20 of the smoke test. The straight line through terrain (finding 1) stays until KNG-51.

### Risks
- None of items 2-6 has been seen working in game yet; links 2-4 build on `recheckDirect` (item 3) — if the live test
  finds it wrong, link 4's `DirectLeg` refactor is where it gets corrected.
- The developer may keep committing to `claude/road-navigation`; links 2-4 merge it at start and before their final push.

### Next link
Link 2 — KNG-51 Phase A. Handoff: `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-2.md`. Started with
charter §6 option 1 (new session): Claude Code Remote `create_session`, same environment, model `claude-opus-5-5`,
source knk-workspace — session `session_01CcMg85W2QPXEDg1YQgJDaV`, 2026-10-02 19:16 UTC.

## Link 2 — KNG-51 Phase A (`knk-core roads/walk/`)

**Session:** Claude Code cloud session `session_01CcMg85W2QPXEDg1YQgJDaV`, 2026-10-02 ~19:15-19:40 UTC. Started from the
link-2 handoff.

### Setup
- knk-plugin `claude/navigation-walkable-path` checked out at `d8507a3`; `origin/claude/road-navigation` still `075ae94`,
  `origin/main` still `27b4236` — both merges "already up to date" at start and again before the final push (no
  developer commits during the link). Push checks ✔ (plugin branch, workspace `main`).
- Network: papermc/enginehub 200. Maven Central answered **429** on two of the first three builds (shadow plugin and
  jackson/gson jars); the third attempt completed and later builds ran `--offline`. Gradle tuning re-created per charter
  §1.4. Not a blocker, but a fresh container may need the same retries.
- Baseline on `d8507a3` = link 1's: knk-core **1561**, knk-api-client **184** (2 skipped), knk-paper **1089** (14 skipped).

### Commits (knk-plugin `claude/navigation-walkable-path`, all pushed)
| Commit | What |
|---|---|
| `ea54013` | **Extraction**: `roads/walk/WalkGrid` = `SpanGrid`'s span rule, links, step and corner rules, profile-free (floor test + headroom parameters). `SpanGrid` delegates, public API and constants unchanged; existing tests unchanged and green (1561 → 1561). |
| `6352b4c` | `PassabilityRules`: `isNeverFloor` (fences, walls, fence gates, panes, iron bars/door/trapdoor), `isHandOpenableDoor`, `isWalkFloor`, `isWater` + 4 tests; builder passability unchanged (pinned). |
| `1fae034` | The search and its types: `WalkPathfinder` ← `WalkSearch`; `WalkRequest`/`WalkResult`/`WalkPath`; `MovementProfile`; `CellAccess`; `WalkTerrain`; `WalkCells`; `WalkGoal`; `WalkBudget`. `WalkGrid` gains a `WalkCells` view (doors/climbables passable in the walk view only; the builder passes `WalkCells.NONE`). 50 tests (`WalkSearchTest` = the §12 list, `WalkTypesTest`). |
| `ad311ae` | 96×96 timing test; `LongMap` (open addressing, no boxing) + `MemoSurface` (per-search block memo) after a JFR profile showed `Long.hashCode` collisions on packed `BlockKey`s (treeified `HashMap` buckets). |

Reuse rows applied (design §2): span rule/links/step/corner → extracted, not copied; `BlockProbe`/`SurfaceGrid`,
`GateCells`, `BlockKey`, `PassabilityRules` reused as is; `AStarRouter` as pattern (entry ordering, tie-break).

### Tests vs baseline (`./gradlew build -x deployToDevServer`, BUILD SUCCESSFUL)
| Module | Baseline | After link 2 |
|---|---|---|
| knk-core | 1561 | **1619** (+58: 4 PassabilityRules, 38 WalkSearch, 12 WalkTypes, 3 timing, 1 LongMap) |
| knk-api-client | 184 (2 skipped) | 184 (2 skipped) |
| knk-paper | 1089 (14 skipped) | 1089 (14 skipped) — no knk-paper change |

**96×96 open-field timing** (fixture terrain, 4-core container, median after warm-up): across 95 blocks ≈ 3-5 ms (95
expansions); full field expanded, unreachable target ≈ 80-90 ms (9 215 expansions; was ~130-140 ms before `LongMap`);
same with the default budget ≈ 75 ms (8 308 expansions, stops at the length cap → FALLBACK). Recorded in the design's §10
"Phase A status". The remaining cost is memo lookups and the fixture's own material `HashMap`; if Phase C live tests
show it matters, a per-cell/neighbour memo in `WalkSearch` is the next step.

### Flagged decisions (reversible defaults; the design left these open)
- **L2-1** Outcomes: no start/goal cell or a fully searched area → `NO_PATH`; expansion budget or a search that hit the
  length cap → `FALLBACK` (§12's wording; §5 says "exhausted or unreachable → FALLBACK"). Phase C treats both alike.
- **L2-2** A cell whose feet are in water wades (×3); water in any headroom block above the feet is swimming → not
  walkable (§11-3 "no swimming"). Waterlogged blocks are not visible by material name.
- **L2-3** `CellAccess` is asked per **feet block** (`floorY + 1`; a ladder cell's own block). The door penalty (+3) is the
  profile's and added by the search; an access adapter answers only `0` or `BLOCKED` for doors. `CellAccess.all(...)`
  composes adapters. NaN/negative answers count as blocked.
- **L2-4** Diagonals never enter or leave a door cell (doors are passed straight on) and need an accessible, door-free
  flanking cell on the corner path, so a diagonal can't slip past a denied door/region corner.
- **L2-5** Drops are orthogonal and directed; the clear fall column runs from the mover's head height down to the
  landing; a drop of `k` costs `k + 10k` (base `k`, not 1, keeps the heuristic consistent) — a 3-block drop costs 33.
- **L2-6** Door blocks and climbables are never floors (nobody "stands on" a door or ladder). Ladders: a ladder cell links
  up/down (2.0/block), to the floor at its foot (same column), to an orthogonal ledge at feet level, to the wall top one
  higher, and is entered from those cells in reverse (getting on from the top is allowed). Orthogonal only.
- **L2-7** The start cell ignores `CellAccess` (the mover is already there); start/goal snapping measures from the point
  to the cell's block column (not its centre), so a player at a block edge mid-jump still snaps.
- **L2-8** The length cap is on walked length (horizontal 1/√2 per move + every block climbed or dropped), checked per
  relaxation; geometry fixtures use a loose budget (`WalkFixture.GEOMETRY`), the cap has its own tests.
- **L2-9** Heuristic `max(horizontal distance, |Δfloor y|)` instead of 3D Euclidean: a step down costs 1 for a √2 chord,
  so Euclidean would overestimate. Admissible and consistent with the costs above (up to the goal predicate's slack).
- **L2-10** The search reads climbables from the `WalkCells` port; `MovementProfile.climbables` is what the capture
  (`WalkCells.ofMaterials` or its own flags) should use. `MovementProfile.PLAYER.withDrops/withClimbables` take config.

### Discrepancies
- §5 vs §12 on unreachable → see L2-1.
- §8 expected "milliseconds-scale" for the ~13k-cell worst case; measured ~80-90 ms for 9.2k cells (see above).
- The design lists ladder links but not getting on a ladder from its top; implemented (L2-6) because a climb down needs it.

### Live checklist (developer)
Nothing in game yet — Phase A is pure core and changes no knk-paper behaviour. Optional: rebuild a known tile → the
road graph is identical to before (the extraction's in-game proof; the unit tests already pin it). Review L2-1 … L2-10.

### What link 3 must wire (Phase B)
- A `WalkTerrain` over captured chunks: `SurfaceGrid` with a permissive floor (`roadFloor = any material`) that also answers
  `floorMaterial` for every candidate cell (`CompactSurfaceGrid.floorMaterial` throws for non-spans today) and
  passable/solid/hazard for the blocks the walk asks beyond the builder: drop columns (head height down to `maxDrop`
  below, in neighbour columns), the block above a ladder cell. Fence/wall/pane/door tops must not become floors — either
  keep material names for `PassabilityRules.isWalkFloor` or reject them during capture.
- `WalkCells` flags (door, climbable, water) per block — `CompactSpans` does not store them. On paper `LADDER` and doors
  are `isCollidable()`; the walk view counts them passable via the flags, so the flags must be right.
- `CellAccess` adapters, combined with `CellAccess.all`: gates (`GateCells.doorAt` on the feet/head blocks →
  `GateAvailability` verdict), denied regions (entry/exit via `DomainAccessEvaluator`, bypass → open), doors (WorldGuard
  `USE`/`INTERACT` **and** domain entry → `0`/`BLOCKED`). Coordinates are the feet block (L2-3).
- Config → `MovementProfile.PLAYER.withDrops(max-drop, drop-penalty)`, `WalkBudget(max-expansions, max-length-factor,
  max-length, 2, 3)`. `WalkSearch` is stateless — one shared instance on the routing executor.
- Region destinations: `WalkGoal` = `RegionShape::containsFloor`. `WalkPath.points()` are floor positions like route points.

### Risks
- The capture (Phase B) is where most walk bugs will come from: the core assumes the terrain answers every block it asks.
- Worst-case search time (above) under many concurrent players — the design's global cap of 2 concurrent searches matters.

### Next link
Link 3 — KNG-51 Phase B. Handoff: `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-3.md`. Started with
charter §6 option 1 (new session): Claude Code Remote `create_session`, same environment, model `claude-opus-5-5`,
source knk-workspace — session `session_014imn6hbUd6JTy1R3e6Str1`, 2026-10-02 19:39 UTC.

## Link 3 — KNG-51 Phase B (knk-paper capture and cell access)

**Session:** Claude Code cloud session `session_014imn6hbUd6JTy1R3e6Str1`, 2026-10-02 ~19:40-20:05 UTC (container clock). Started from
the link-3 handoff (link 2 had created this session).

### Setup
- Workspace was checked out detached; switched to `main`. knk-plugin was not in the container: attached with
  `add_repo` and cloned (`claude/navigation-walkable-path` at `ad311ae`). `origin/claude/road-navigation` still
  `075ae94`, `origin/main` still `27b4236` — both merges "already up to date" at start and again before the final push
  (no developer commits during the link). Push checks ✔.
- Network: papermc/enginehub 200; the first build completed without Maven Central 429s; later builds `--offline`.
- Baseline on `ad311ae` = link 2's: knk-core **1619**, knk-api-client **184** (2 skipped), knk-paper **1089** (14 skipped).

### Commits (knk-plugin `claude/navigation-walkable-path`, all pushed)
| Commit | What |
|---|---|
| `beec0e1` | knk-core `roads/walk/`: `GateCellAccess` (verdicts from `GateAvailability.decide`, floor..floor+headroom like `WalkGrid.gateDoor`), `DeniedRegionAccess` (`DomainAvailability`'s entry/exit split per feet block over `RegionShape`s; `resolve` keeps the denying domains; bypass → none), `DoorCellAccess` (denied door blocks, feet/head). 9 tests incl. search detours. |
| `905987b` | knk-paper `navigation/walk/`: `WalkChunk` (one flags byte per block — passable/solid/hazard/stair + door/climbable/water — uniform sections stored as one byte; floor materials for every solid block with a walk-passable block above; door positions), `WalkChunkExtractor` (pure, the builder's `PassabilityRules` and `BlockSource`), `CapturedWalkTerrain` (`SurfaceGrid` + `WalkCells` over a request's chunks). Tests: block-by-block and search-by-search equality with the world it was captured from (curated and paper collision tables: ladders/doors collidable), memory/time measurement. |
| `12c834a` | `WalkSnapshotService` (main thread: loaded chunks only, 4 chunks/tick and 1 under lag via `TickBudget`, world/chunk-keyed TTL cache shared across requests, LRU 256, union of section bands, dropped when the world's gate footprints change, cancellable futures, `stats()`), `WalkBox` (leg ± `capture-margin`, also vertically), `GateCellsIndex.doorIdsWithin` + content `equals`; `NavigationConfig.WalkConfig` (`navigation.walk.*`, all §9 keys + `climbables`, `profile()`, `budget()`; the old 14-argument constructor keeps the defaults) and its loader. |
| `d08c341` | **Extraction**: `NavigationAccess.gateAvailability(player, doorIds)` out of `policyFor` (same parts, same order; navigation tests unchanged and green) + public accessors (`domainByRegionId`, `bypasses`, `evaluator`, `regionsAt`). |
| `aa320e5` | `WalkAccessFactory` (main thread: gate verdicts for the doors in the box, one WorldGuard check per door block, WorldGuard regions overlapping the box as `RegionShape` candidates with "player inside"; `WalkAccess.resolve()` on the routing thread composes gates + doors + denied regions with `CellAccess.all`) and `WorldGuardWalkAccess` (the WorldGuard calls, kept apart so the factory loads without WorldGuard in tests). 6 tests. |

Reuse rows applied (design §2): `BlockProbe`/`SurfaceGrid`, `PassabilityRules` (incl. Bukkit's collision predicate),
`SpanExtractor.BlockSource`, `GateCells`/`GateCellsIndex`, `TickBudget`, `GateAvailability` (via the extracted
`NavigationAccess.gateAvailability`), `DomainAvailability`'s messages and `DomainAccessEvaluator`, `RegionShape` +
`WorldGuardRegionShapes.toShape`, `RegionIds`, `BlockKey`. `CompactSpans`/`CompactSurfaceGrid` were **not** reused —
see L3-1.

### Tests vs baseline (`./gradlew build -x deployToDevServer`, BUILD SUCCESSFUL, test results cleaned first)
| Module | Baseline | After link 3 |
|---|---|---|
| knk-core | 1619 | **1628** (+9 `WalkCellAccessTest`) |
| knk-api-client | 184 (2 skipped) | 184 (2 skipped) |
| knk-paper | 1089 (14 skipped) | **1116** (14 skipped; +7 `WalkCaptureTest`, +1 `WalkCaptureMeasureTest`, +12 `WalkSnapshotServiceTest`, +6 `WalkAccessFactoryTest`, +1 config) |

**Memory and extraction time per chunk (design §2 row 4, §8)** — synthetic overworld chunk (rolling grass 60-72,
stone with ores, two caves, a pond, a tree, a cottage with a door and a ladder), array-backed block source, 4-core
container, median of 41: the band a leg captures (3 sections) ≈ **12 KB**, **0.4-0.7 ms**; the whole column
(-64..320, empty sections skipped) ≈ 17 KB, 2.3-2.7 ms. A real `ChunkSnapshot` read is slower than the array, so the
live number will be higher; `WalkSnapshotService.stats().meanCaptureMicros()` measures it on the server (Phase C can
log it). Cache ceiling: 256 chunks ≈ 3-5 MB.

### Flagged decisions (reversible defaults; the design left these open)
- **L3-1** The capture is its own per-block flags capture (`WalkChunk`), not `CompactSpans` with `roadFloor = any`:
  `CompactSpans` keeps only spans and their headroom, but the walk search also asks drop columns down to `maxDrop` in the
  neighbour columns, the block above a ladder and water at the feet, and needs door/climbable/water flags. The
  "permissive `roadFloor`" is kept in spirit: every material is recorded as a possible floor; the search's
  `PassabilityRules.isWalkFloor` rejects fence/wall/pane/door/ladder tops. Verified by block-by-block and search
  equality tests against the uncaptured world.
- **L3-2** Denied regions are copied into Bukkit-free `RegionShape`s on the main thread (the design's fallback). Whether
  `ProtectedRegion.contains` is safe off-thread was **not** verified — WorldGuard does not document it and regions can be
  redefined during a search, so the copy is the safe default. Containment is on the feet block (WorldGuard's block rule);
  a degenerate polygon becomes its bounding cuboid rather than being dropped.
- **L3-3** Door rule: WorldGuard `RegionQuery.testBuild(location, player, INTERACT, USE)` (membership, or both flags
  allowing — at least as strict as WorldGuard's own door check), WorldGuard's region bypass or `knk.region.bypass` →
  allowed. The KnK domain half of §11-2 is `DeniedRegionAccess`, which blocks door cells in a region the player may not
  enter like any other cell (composed with `CellAccess.all`; tested). Each door block in the box is checked once per
  request; door blocks outside the box are not checked (no cell there can be reached).
- **L3-4** Gate cells: floor, feet and head blocks (floor..floor+headroom, the blocks `WalkGrid.gateDoor` tags); a door the
  gate cache does not know is open (the router's rule); pass-through and siege-carried gates are walkable (the hint is
  Phase C's message business).
- **L3-5** Domain lookups run in `WalkAccess.resolve()` on the **routing thread**, not in the main-thread `prepare`:
  `NavigationAccess.domainByRegionId` may wait up to 3 s for the API, as the road router's lookups do.
- **L3-6** Only the box's sections are captured (leg ± `capture-margin` vertically too); a taller box later recaptures the
  chunk with the union of both bands. The Bukkit port reads every block of the band (no `ChunkSnapshot.isSectionEmpty`
  skip — its index convention is not pinned by a test here, and a wrong skip would hide blocks).
- **L3-7** Constants, not config: 4 chunks per tick (1 while lagging), cache ≤ 256 chunks (LRU), ≤ 49 chunks per request
  (`TOO_LARGE` beyond — a 48-block leg + 16 margin needs at most 6 × 6). A world's cached chunks are dropped when its gate
  footprints change (the capture records floors under gate blocks).
- **L3-8** Outside the captured chunks/band a block is neither passable nor solid — the box is the search's boundary.
  `floorMaterial` of a block the capture did not record throws (like `CompactSurfaceGrid`); a correct capture never hits
  it, but Phase C must treat any exception from the search as FALLBACK.
- **L3-9** `NavigationConfig.WalkConfig` carries all §9 keys plus `climbables`; `enabled` and `recompute-distance` are not
  wired yet and `config.yml` has no `walk:` block yet (Phase C adds it; the bundled-config test pins the defaults).
- **L3-10** New code lives in the sub-package `knk-paper .../navigation/walk/` (the design wrote `navigation/WalkSnapshotService`).

### Discrepancies
- Design §2 row 4 expected `CompactSpans`/`CompactSurfaceGrid` with a permissive `roadFloor` to be "probably" reusable — it
  is not enough for the walk search (L3-1).
- Design §6 asks to verify `ProtectedRegion.contains` off-thread; not verified, the copy was taken instead (L3-2).
- The navigation routing executor is a single thread (`knk-navigation-routing`), so `max-concurrent-searches` (default 2)
  is effectively 1 unless Phase C gives walk searches their own executor.

### Live checklist (developer)
Nothing changes in game yet — the capture and access classes are not wired into `NavigationService` (Phase C). Review
L3-1 … L3-10. Phase C's checklist will cover the in-game matrix (§12).

### What link 4 must wire (Phase C)
- **Construction** (`KnKPlugin`, next to `NavigationAccess`): `new WalkSnapshotService(navigation.passabilityRules(
  ChunkSnapshotSurfaceGrid.bukkitCollidable()), navigation.walk(), TickBudget.server(), System::currentTimeMillis)`,
  `.start(this)` (and `.stop()` on disable); `WorldGuardWalkAccess.factory(access)`; one shared `new WalkSearch()`.
- **Per request, main thread:** `GateCellsIndex gates = GateCellsIndex.of(gateManager, world.getName())`;
  `WalkBox box = WalkBox.around(world.getName(), feet x/y/z, target floor x/y/z, walk.captureMargin(),
  world.getMinHeight(), world.getMaxHeight())`; `walkSnapshots.capture(WalkSnapshotService.of(world), gates, box)` → the
  future completes on the main thread (possibly at once); not `ready()` → FALLBACK (straight line). Then
  `WalkAccess access = walkAccessFactory.prepare(player, world, gates, capture, walk.profile().headroom())`.
- **Routing thread:** `CellAccess cells = access.resolve()`; `new WalkRequest(capture.terrain().terrain(), cells,
  walk.profile(), feet x/y/z, target floor x/y/z, goal, walk.budget())` (goal: `WalkGoal.within(target, arriveDistance)` or
  `RegionShape::containsFloor`); `walkSearch.find(...)` inside try/catch (exception → FALLBACK, L3-8); deliver with the
  generation check. Cancel the capture future when the leg is replaced before it completes.
- `config.yml` `navigation.walk:` block (all keys, defaults) + the bundled-config test; `enabled: false` = today exactly.
- Optional: a debug line with `WalkSnapshotService.stats()` (captured chunks, mean µs per chunk, cache bytes) for the
  live §8 measurement.

### Risks
- The live `ChunkSnapshot` extraction time is unmeasured (array fake only); watch `stats()` in the Phase C live test.
- WorldGuard's `testBuild(INTERACT, USE)` for doors is untested against a live WorldGuard (mocked port in tests); a wrong
  answer shows as a trail through a door the player cannot open, or around one they can.
- The capture assumes the collision predicate and overlay patterns the road builder uses; a material Bukkit calls
  collidable that a player can walk through (or the reverse) is wrong for both.

### Next link
Link 4 — KNG-51 Phase C. Handoff: `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-4.md`. Started with
charter §6 option 1 (new session): Claude Code Remote `create_session`, same environment, model `claude-opus-5-5`,
source knk-workspace — session `session_01XxVP8zNRBbath1Q6dQki82`, 2026-10-02 20:01 UTC.
