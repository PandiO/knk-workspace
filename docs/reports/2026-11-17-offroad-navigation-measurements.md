# Off-road navigation: phase 0 measurements of the walk search

**Status:** Skeleton (2026-11-17), waiting for the developer's live run. Every "_to fill_" cell is a live value from
the dev world; nothing in this report is measured live yet. · **Last updated:** 2026-11-17 (skeleton by link L1 of
the off-road navigation chain: tables, steps, decision rules)

**Issue:** [PandiO/knk-workspace#703](https://github.com/PandiO/knk-workspace/issues/703) (phase 0, link L1 of the
[off-road navigation chain](https://github.com/PandiO/knk-workspace/blob/main/docs/ai-agents/handoffs/NAVIGATION_OFFROAD_CHAIN.md)), parent
[#698](https://github.com/PandiO/knk-workspace/issues/698).
**Design:** [specs/navigation-offroad/DESIGN.md](../specs/navigation-offroad/DESIGN.md) § 9 (measure before setting
budgets, decision O06), § 5.6 (options A, B, C; decision O32), § 13 A01.
**How to measure:** [smoke-test guide § 1](../guides/navigation-offroad-smoke-test.md#1-phase-0-measurements-703-tier1)
(steps 2 to 9). **Counters:** knk-plugin `claude/offroad-measurements` (PR into `next`): `/knk road status` and
`/knk road status reset`, config key `navigation.walk.max-chunks-per-request`.

This report is dated and is not overwritten: a later measurement run gets a new dated report.

## 1. Answers (to fill after the run)

1. **Does option A (raised caps) already fit the keep?** _to fill_ (yes / no, with the rule of § 4 and the numbers of
   table 3.2). If yes, the developer is asked again before L6 (decision O32; charter § 2.3).
2. **Which cluster size?** _to fill_ (§ 5).
3. **Which budgets?** _to fill_ (table 3.3); they replace the proposals of DESIGN § 9.3 for L5 and L6.

## 2. Run and scenes

| Item | Value |
|---|---|
| Date of the run | _to fill_ |
| Plugin build | knk-plugin `next` `073fa4cf` (`v0.1.0+073fa4cf`, contains #703 `04506d8c`), dev server DEV_SERVER_26.3 (Paper 26.3) |
| Server | _to fill_ (CPU, memory, players online) |
| Settings, run 1 | as shipped: `max-snap-distance` 48, `walk.max-expansions` 20000, `walk.max-length` 144, `walk.max-chunks-per-request` 64 |
| Settings, run 2 (option A) | `max-snap-distance` 600, `walk.max-expansions` 200000, `walk.max-length` 1000, `walk.max-chunks-per-request` 800, `walk.detour-allowance` 600. The detour allowance was added after run 1: the length cap is min(`max-length`, max(`max-length-factor` × straight, straight + `detour-allowance`)) + `climb-allowance` × rise, so raising `max-length` alone leaves a 17-block keep leg capped near 65 blocks (scene 1, run 1 ended at that cap). Changed from the guide's 450 / 600 / 512 because the dev world's open-country targets are 482 and 569 blocks away (not 200 and 400): the outpost leg's capture box is 24 by 32 = 768 chunks. The keep scenes are short, so the keep rule of § 4 reads the same either way. |
| Settings, run 3 (only if needed) | run 2 with `walk.max-expansions` 500000 |
| Chunks force-loaded | Coal mine: `/forceload add 945 -593 1459 -551` (132 chunks). Outpost, four bands of at most 216 chunks: `/forceload add 1427 -583 1797 -456`, `1427 -455 1797 -328`, `1427 -327 1797 -200`, `1427 -199 1797 -93`. Southern Marshes, destination end only: `/forceload add 1468 1210 1692 1434` (225 chunks). Indoor scenes: none (the player's view distance loads them). Afterwards `/forceload remove all`. |

The developer chose the scenes on 2026-11-18 from six Locations in `world_KNK-DEV`. Scenes 1 to 6 start at the siege
spawn by the south gate, x 1443, y 43, z -567 (`/tp 1443 43 -567`); scenes 7 to 9 start at a Location (`/tp` to its
coordinates) and go to another, as indoor routes with bits of road between them. Straight distance is horizontal.

| # | Scene | Start | Destination (`/navigate`) | Straight distance | Height difference | Notes |
|---|---|---|---|---|---|---|
| 1 | Keep (corridor route) | spawn 1443 43 -567 | `Keep storage hall` (Location 56; 1421 73 -488) | 82 | +30 | over 48: run 1 is road plus walk legs; run 2 one walk search |
| 2 | Climb: keep tower (stairs, bottom to top) | spawn 1443 43 -567 | `Keep Tower Roof` (Location 52; 1411 113 -504) | 71 | +70 | over 48 (as scene 1); `length-pruned` matters here (climb allowance 5 blocks per block of height) |
| 3 | Climb: garrison watchtower | spawn 1443 43 -567 | `Garrison Watchtower Roof` (Location 53; 1401 107 -542) | 49 | +64 | just over 48, so run 1 already routes it over the road |
| 4 | Open country, about 400 blocks | spawn 1443 43 -567 | `Coal mine` (Location 55; 961 79 -577) | 482 | +36 | run 1 roads plus end legs; run 2 one walk search (within 600) |
| 5 | Open country, about 570 blocks | spawn 1443 43 -567 | `Outpost under construction` (Location 54; 1781 134 -109) | 569 | +91 | run 2's largest capture (about 768 chunks, about 10 s at 4 per tick): note the tick time |
| 6 | Very long haul (extra) | spawn 1443 43 -567 | `Southern Marshes` (Location 57; 1580 45 1322) | 1894 | +2 | beyond every run's `max-snap-distance`: both runs are roads plus end legs; shows the end legs and how far the walk search is from such distances (option C territory) |
| 7 | Indoor pair: tower roof to storage hall (extra) | Keep Tower Roof 1411 113 -504 | `Keep storage hall` | 19 | -40 | within 48: direct walk in both runs; a long way down through the keep |
| 8 | Indoor pair: watchtower to tower roof (extra) | Garrison Watchtower Roof 1401 107 -542 | `Keep Tower Roof` | 39 | +6 | down one building, across, up the other |
| 9 | Indoor pair: storage hall to watchtower (extra) | Keep storage hall 1421 73 -488 | `Garrison Watchtower Roof` | 58 | +34 | over 48: run 1 road plus walk legs, run 2 one walk search |

No scene is about 200 blocks away; scene 4 stands in for the 400-block row, scene 5 goes beyond it. Rows of § 3.2 are
read with these numbers: "keep" = scene 1, "stair house" = scene 2, "courtyard" = scene 3, "400" = scene 4, "200"
unused; add rows for scenes 5 to 9.

## 3. Measurements

### 3.1 DESIGN § 9.1 with live values

| Measure | Value in DESIGN § 9.1 (from the docs) | Live value | From (scene, run) |
|---|---|---|---|
| Straight 95 block walk search | about 3 to 5 ms | _to fill_ | _to fill_ |
| 96 by 96 open field fully expanded | 80 to 90 ms (default budget: about 75 ms) | _to fill_ (or n/a) | _to fill_ |
| Walk searches in live tests | 2 to 140 ms, off the main thread | _to fill_ (p50 / p95 / max of search µs) | all scenes, run 1 |
| Chunk capture | 0.4 to 0.7 ms per chunk (synthetic), about 12 KB per chunk | _to fill_ (capture µs / chunks of the cold requests; KB from `walk paths:` "cached (KB)") | _to fill_ |
| Chunks per request | up to 64 (15 % of 96 block legs need 50 to 64) | _to fill_ (max / p95 of chunks) | _to fill_ |
| Budgets today | 20 000 expansions, 144 blocks, 2 concurrent searches | _to fill_ (how many searches ended at each cap in run 1) | run 1 |
| Road router | target under 5 ms for a few thousand nodes (a target, not a measurement) | not measured by phase 0 (the counters cover the walk search) | — |

Reference only, not live (fixture terrain in the cloud build container, 4 cores, `WalkSearchTimingTest`, knk-plugin
`claude/offroad-measurements`, 2026-11-17): 95 blocks across an open field 1.2 ms (95 expansions); the whole 96 by 96
field expanded 98 ms (9 215 expansions, about 11 µs per expansion); the same with the default budget 85 ms.

### 3.2 Per scene and run (DESIGN § 9.2)

Copy from `/knk road status`: the first `walk recent:` line after `/navigate` (the cold capture), and the `walk cost:`
lines after walking the whole route ("whole walk").

| Scene, run | Outcome (cap) | Path length | Expansions | Cells | Chunks (cached) | Capture µs | Wait ms | Search µs | Queue µs | Length-pruned | Tick time during the capture | Whole walk: searches, search µs p95, capture µs p95 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| keep, run 1 | FALLBACK (max-length), 2 of 2 searches; the player got stuck in the lower flights of the keep stair house | 7 (partial, 17 straight) | 2093 | 2093 | 9 (0) | 10556 | 158 | 19410 | 33 | yes (2 of 2) | not measured | 2 searches; 25.6 ms; 10.6 ms |
| keep, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| stair house, run 1 | FOUND (scene 2, Keep Tower Roof) | 161 (30 straight) | 4428 | 4439 | 12 (0) | 48404 (first capture after the server start; later cold captures of 12 chunks took 4.7 ms) | ≤ 203 | 127035 | ≤ 1000 | no | not measured | 4 searches; 127.0 ms; 48.4 ms |
| stair house, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| courtyard, run 1 | FOUND (scene 3, Garrison Watchtower Roof) | 129 (28 straight) | 2914 | 2932 | 12 (0) | 4984 | ≤ 150 | 40484 | ≤ 31 | no | not measured | 4 searches; 40.5 ms; 5.0 ms |
| courtyard, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 200, run 1 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 200, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 400, run 1 | no route: "No road connects you to Coal mine." (scene 4); no walk search ran | — | — | — | — | — | — | — | — | — | — | — |
| 400, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 5 outpost, run 1 | no route: "No road connects you to …" (as scene 4); no walk search ran | — | — | — | — | — | — | — | — | — | — | — |
| 5 outpost, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 6 marshes, run 1 | no route: "Southern Marshes is too far from any road." | — | — | — | — | — | — | — | — | — | — | — |
| 7 tower roof to storage hall, run 1 | FOUND, the route worked | 217 (44 straight) | 2958 | 3050 | 12 (12) | 0 (cached) | 0 | 16018 | 14 | no | not measured | 5 searches; 18.2 ms; 6.4 ms |
| 7 tower roof to storage hall, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 8 watchtower to tower roof, run 1 | NO_PATH, 5 of 5 ("No conventional path to Keep Tower Roof found.") | 8 (40 straight) | 44 | 44 | 20 (0) | 6583 | 214 | 414 | ≤ 43 | no | not measured | 5 searches; 0.5 ms; 6.6 ms |
| 8 watchtower to tower roof, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| 9 storage hall to watchtower, run 1 | NO_PATH (37 straight, 44 expansions), then FALLBACK (max-length) 5 of 5 on the walk legs ("guiding you to the nearest road"; stuck after a few blocks) | 25 (25 straight) | 2165 | 2165 | 12 (0) | 3591 | ≤ 93 | 11875 | ≤ 17 | yes (5 of 6) | not measured | 6 searches; 24.8 ms; 4.3 ms |
| 9 storage hall to watchtower, run 2 | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| run 3 (if needed) | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |
| concurrency (step 8) | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ | _to fill_ |

Run 1 on scenes 4 and 5 is today's behaviour (roads, walk legs at the ends of at most 96 blocks): its rows hold the
end legs, one line each.

### 3.3 Budgets (DESIGN § 9.3)

| # | Budget | Proposed in DESIGN § 9.3 | Measured | Set to |
|---|---|---|---|---|
| 1 | Main thread: capture within `TickBudget`, navigation work per player per tick unchanged | as proposed | _to fill_ (capture µs of the largest cold request; tick time) | _to fill_ |
| 2 | Plain walk search, p95 for 144 blocks | at most 150 ms | _to fill_ (search µs p95, run 1) | _to fill_ |
| 3 | Hierarchical search, p95 for 400 blocks indoors | at most 400 ms | _to fill_ (run 2's single search is the upper bound a hierarchical search must beat) | _to fill_ |
| 4 | Memory: `cluster-cache-chunks` | 1024 chunks, about 12 MB | _to fill_ (KB per captured chunk on the dev world) | _to fill_ |
| 5 | Concurrency: `max-concurrent-searches` | stays 2 until measured | _to fill_ (queue µs, step 8) | _to fill_ |
| 6 | Counters in `/knk road status` | searches, expansions, cache hits, links, shaping time | phase 0 built searches, expansions, cells, capture, wait, queue, caps | later phases add links (L5) and shaping (L3) |

## 4. Question 1: does option A fit the keep?

Proposed rule (agent proposal, for the developer to accept or change): option A fits the keep when, in run 2,

1. the keep's longest route is found in one search that no cap ended (`walk recent:` shows `FOUND` without a cap);
2. its search time is within budget 3 of table 3.3 (proposed 400 ms);
3. its cold capture keeps the server's tick time under 50 ms (the capture runs 4 chunks per tick, under lag 1) and its
   wait is short enough that the player sees the trail switch from the straight line in time (proposed: 2 s);
4. the 400 block open-country leg is not part of this rule: option A was never meant for the wilderness beyond loaded
   chunks (DESIGN § 5.6, option C), but its run 2 row shows how far A goes.

Answer: _to fill_. If yes, the coordinator asks the developer before L6 (O32): A for the keep now, B later.

## 5. Question 2: which cluster size?

DESIGN § 5.3.2 proposes one chunk column per level (16 by 16). The live numbers decide between 1 by 1, 2 by 2 and 4 by
4 chunks per cluster:

1. **Cost of one cluster edge** (a bounded walk search between two entrances of a cluster, § 5.3.3): about the cells of
   one level of the cluster times the µs per expansion. µs per expansion = search µs / expansions over the scenes of run
   2: _to fill_.
2. **First request in an area** (lazy HPA*): clusters along the corridor times the edges per cluster (up to
   `cluster-entrances` 6 per border, 4 borders: at most 24 entrances, so up to 276 edges, fewer in practice) times the
   cost of one edge.
3. **Refinement:** the plain walk search along the corridor, as in run 1.

| Cluster | Cells per level | One edge (µs) | Clusters on the 400 block leg | First request (estimate) | Fits budget 3? |
|---|---|---|---|---|---|
| 1 by 1 chunk | 256 | _to fill_ | about 25 | _to fill_ | _to fill_ |
| 2 by 2 chunks | 1 024 | _to fill_ | about 13 | _to fill_ | _to fill_ |
| 4 by 4 chunks | 4 096 | _to fill_ | about 7 | _to fill_ | _to fill_ |

Answer: _to fill_ (the largest cluster whose first request stays within budget 3; smaller clusters invalidate less on a
block change, O18).

## 6. Question 3: which budgets?

Answer: _to fill_ (the "Set to" column of table 3.3, and the values L5 and L6 put in `config.yml`).

## 7. Limits of these numbers

1. Search µs is wall time on a walk thread: it includes garbage collection and anything else the machine runs.
2. Capture µs counts the main-thread time to extract the request's chunks; a chunk two requests wait for counts for
   both, and a chunk from the 10 s cache costs nothing. Read the cold request (the first `walk recent:` line after
   `/knk road status reset`) for a scene's full capture cost.
3. The dev server is not production hardware; the budgets get a margin for that.
4. Run 2's `max-snap-distance` 450 changes which destinations are routed over roads; it is a measurement setting only,
   restored in step 9.
5. Force-loaded chunks stay loaded until `/forceload remove all`.
