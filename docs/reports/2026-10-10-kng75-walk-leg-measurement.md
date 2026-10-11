# KNG-75 step 2a — the cost of 48-96 block walk legs

**Status:** measurement (offline replay of the server's capture and search on the dev world); input for step 2b's
decisions. **Last updated:** 2026-10-10
**Linear:** [KNG-75](https://linear.app/kngpandi/issue/KNG-75) (walk legs at both ends, destinations further than 48
blocks off-road); related [KNG-108](https://linear.app/kngpandi/issue/KNG-108) (height allowance)
**Code:** knk-plugin `claude/kng-75-offroad-destinations` `fec8e4b2` (= `main` `c4141f90` + the replay's batch mode,
`WalkReplayTest.legs`, `tools/road-replay/README.md`). Region files `r.2.-1`/`r.2.-2` of `world_KNK-DEV`, copied
2026-10-09 22:06; roads and Locations read-only from the dev DB.

## Question

Step 2 lets a destination lie further than 48 blocks off-road: by road to the nearest road point, then a walk path.
How far can that walk path reach before the capture (main thread), the search (walk thread) or the budget gives out,
and how many destinations need it?

## Who needs it (dev DB)

74 Locations in `world_KNK-DEV`, plain 3D distance to the nearest road edge (53 edges, 341 segments):

- **71 within 48** (today's limit);
- **2 at 48-96:** Location 7 "East Gate Square" (1418, 43, -174), 75.8 off-road; Location 72 (1500, 54, -636), 83.6;
- **none at 96-256**; one far-off test Location (81 "Orphan test" at (1, 2, 3)).

**Data finding:** Location 7 "East Gate Square" lies **inside solid andesite** (y 36-48 at (1418, -174) are all
andesite in the region file); no walk path can reach it, from anywhere. Its y (43) is probably wrong.

## Capture (main thread)

The capture box is the leg's bounding box plus `capture-margin` 16; `WalkSnapshotService` refuses more than
**49 chunks** (`MAX_CHUNKS_PER_REQUEST`), which keeps today's straight line. Live cost (finding N2, 2026-10-07):
**1.8 ms per chunk**, spread over ticks by `TickBudget`; cached 10 s.

| Leg length | Worst case | Over 49 chunks |
|---|---|---|
| 64 | 42 chunks | never |
| 80 | 49 chunks | never |
| 96 | 64 chunks | 15 % of directions and positions (diagonal legs) |

A 96-block leg at 64 chunks is ≈ 115 ms of main-thread work over several ticks; at 49, ≈ 90 ms. This applies to step
1's walk to the road too (`max-start-distance` 96): a long diagonal start leg keeps the straight line.

## Search (walk thread) and the length cap

22 legs: the two real ones (nearest road point → Location) and 20 road point → Location pairs 55-96 apart in all
directions (random pairs, not the nearest road, so many cross town walls). Columns are budgets
`factor/detour/max-length/expansions`; `100/0/10000/…` means no length cap. Path length after FOUND; search time is the
median of 5 runs on the developer's PC.

**Margin 16 (the shipped capture box):**

| leg | straight | box chunks | extract ms (offline) | 1.75/48/96/20000: result, expansions, ms | 1.75/48/144/20000: result, expansions, ms | 100/0/10000/20000: result, expansions, ms | 100/0/10000/400000: result, expansions, ms |
|---|---|---|---|---|---|---|---|
| real-EastGateSquare-75.8 | 75.6 | 24 | 76 | NO_PATH, 0, 0.8 | NO_PATH, 0, 0.4 | NO_PATH, 0, 0.5 | NO_PATH, 0, 0.3 |
| real-Location72-83.6 | 83.8 | 42 | 46 | FALLBACK, 9667, 74.2 | FOUND 96, 5509, 35.6 | FOUND 96, 5509, 35.0 | FOUND 96, 5509, 35.2 |
| loc77-o5-72 | 71.2 | 36 | 65 | FALLBACK, 7265, 70.1 | FOUND 119, 3845, 34.7 | FOUND 119, 3845, 37.1 | FOUND 119, 3845, 37.0 |
| loc56-o1-85 | 85.6 | 35 | 32 | FALLBACK, 669, 4.8 | FALLBACK, 1143, 8.8 | NO_PATH, 3793, 30.7 | NO_PATH, 3793, 29.2 |
| loc61-o1-65 | 65.2 | 30 | 30 | FALLBACK, 2841, 23.3 | FALLBACK, 2947, 23.6 | NO_PATH, 3252, 26.4 | NO_PATH, 3252, 25.6 |
| loc27-o1-72 | 72.1 | 24 | 27 | FALLBACK, 5867, 38.0 | FALLBACK, 6638, 48.5 | NO_PATH, 7161, 51.7 | NO_PATH, 7161, 54.1 |
| loc12-o5-80 | 79.3 | 35 | 28 | FALLBACK, 7417, 50.4 | FALLBACK, 9112, 68.5 | NO_PATH, 9223, 73.2 | NO_PATH, 9223, 74.2 |
| loc21-o5-79 | 78.4 | 28 | 21 | FALLBACK, 5119, 38.5 | FALLBACK, 6800, 50.9 | NO_PATH, 7290, 53.6 | NO_PATH, 7290, 55.1 |
| loc51-o0-73 | 73.5 | 36 | 28 | FALLBACK, 2830, 21.3 | FALLBACK, 3110, 23.7 | NO_PATH, 3252, 24.4 | NO_PATH, 3252, 25.8 |
| loc31-o4-59 | 59.0 | 20 | 15 | FALLBACK, 3870, 25.0 | NO_PATH, 3921, 28.7 | NO_PATH, 3921, 27.5 | NO_PATH, 3921, 30.2 |
| loc59-o4-77 | 76.2 | 35 | 27 | FOUND 85, 1143, 10.7 | FOUND 85, 1143, 6.9 | FOUND 85, 1143, 9.6 | FOUND 85, 1143, 9.7 |
| loc24-o2-69 | 69.7 | 18 | 16 | FALLBACK, 4266, 29.8 | FALLBACK, 4941, 36.9 | NO_PATH, 5577, 37.2 | NO_PATH, 5577, 41.2 |
| loc78-o6-90 | 90.1 | 28 | 25 | FALLBACK, 5062, 41.2 | FALLBACK, 6619, 48.4 | NO_PATH, 13808, 96.5 | NO_PATH, 13808, 95.9 |
| loc29-o2-68 | 68.0 | 18 | 21 | FALLBACK, 4266, 31.9 | FALLBACK, 4888, 32.7 | NO_PATH, 5577, 36.5 | NO_PATH, 5577, 41.2 |
| loc23-o2-68 | 67.6 | 30 | 26 | FALLBACK, 7971, 123.5 | FALLBACK, 8294, 138.6 | NO_PATH, 8701, 104.6 | NO_PATH, 8701, 117.9 |
| loc74-o4-89 | 88.1 | 40 | 23 | FOUND 95, 603, 5.2 | FOUND 95, 603, 5.5 | FOUND 95, 603, 5.3 | FOUND 95, 603, 5.4 |
| loc42-o6-86 | 85.9 | 32 | 33 | FOUND 95, 741, 6.4 | FOUND 95, 741, 6.3 | FOUND 95, 741, 6.5 | FOUND 95, 741, 6.9 |
| loc37-o6-58 | 57.6 | 25 | 22 | FALLBACK, 5338, 60.5 | FALLBACK, 5547, 63.1 | NO_PATH, 5869, 79.7 | NO_PATH, 5869, 56.7 |
| loc71-o0-91 | 91.2 | 48 | 35 | FALLBACK, 8216, 121.5 | FOUND 103, 925, 9.0 | FOUND 103, 925, 13.1 | FOUND 103, 925, 15.6 |
| loc40-o0-83 | 83.7 | 42 | 102 | FALLBACK, 7981, 119.9 | FOUND 107, 2787, 42.2 | FOUND 107, 2787, 38.7 | FOUND 107, 2787, 47.9 |
| loc6-o3-65 | 65.1 | 36 | 20 | FALLBACK, 5015, 50.5 | FOUND 112, 1806, 20.0 | FOUND 112, 1806, 20.2 | FOUND 112, 1806, 15.7 |
| loc66-o3-64 | 63.8 | 28 | 13 | FOUND 78, 409, 3.5 | FOUND 78, 409, 3.7 | FOUND 78, 409, 3.7 | FOUND 78, 409, 3.5 |

**Margin 32 (a larger box, for comparison; over 49 chunks for most legs):**

| leg | straight | box chunks | extract ms (offline) | 1.75/48/144/20000: result, expansions, ms | 100/0/10000/400000: result, expansions, ms |
|---|---|---|---|---|---|
| real-EastGateSquare-75.8 | 75.6 | 50 | 113 | NO_PATH, 0, 0.7 | NO_PATH, 0, 0.5 |
| real-Location72-83.6 | 83.8 | 72 | 93 | FOUND 96, 5529, 59.7 | FOUND 96, 5529, 39.2 |
| loc77-o5-72 | 71.2 | 64 | 87 | FOUND 119, 4034, 44.4 | FOUND 119, 4034, 24.3 |
| loc56-o1-85 | 85.6 | 63 | 45 | FALLBACK, 5522, 33.7 | FOUND 242, 10003, 73.8 |
| loc61-o1-65 | 65.2 | 56 | 47 | FALLBACK, 3657, 29.4 | NO_PATH, 4081, 32.2 |
| loc27-o1-72 | 72.1 | 48 | 54 | FALLBACK, 12079, 96.2 | FOUND 462, 17645, 147.2 |
| loc12-o5-80 | 79.3 | 63 | 51 | FALLBACK, 16071, 135.9 | FOUND 332, 17734, 149.5 |
| loc21-o5-79 | 78.4 | 54 | 48 | FALLBACK, 13498, 114.2 | FOUND 348, 15433, 133.4 |
| loc51-o0-73 | 73.5 | 64 | 57 | FALLBACK, 3858, 30.6 | NO_PATH, 4081, 32.4 |
| loc31-o4-59 | 59.0 | 42 | 39 | FALLBACK, 9280, 73.1 | FOUND 434, 16143, 124.3 |
| loc59-o4-77 | 76.2 | 63 | 51 | FOUND 85, 1143, 10.0 | FOUND 85, 1143, 8.8 |
| loc24-o2-69 | 69.7 | 40 | 36 | FALLBACK, 9899, 77.8 | FOUND 320, 11627, 87.2 |
| loc78-o6-90 | 90.1 | 54 | 53 | FALLBACK, 13260, 106.6 | NO_PATH, 21596, 168.5 |
| loc29-o2-68 | 68.0 | 40 | 35 | FALLBACK, 9755, 76.5 | FOUND 317, 11555, 85.9 |
| loc23-o2-68 | 67.6 | 56 | 52 | FALLBACK, 13786, 109.7 | FOUND 292, 15617, 126.7 |
| loc74-o4-89 | 88.1 | 70 | 42 | FOUND 95, 603, 4.5 | FOUND 95, 603, 3.3 |
| loc42-o6-86 | 85.9 | 60 | 48 | FOUND 95, 741, 5.3 | FOUND 95, 741, 4.9 |
| loc37-o6-58 | 57.6 | 49 | 40 | FALLBACK, 10634, 87.4 | NO_PATH, 12729, 102.1 |
| loc71-o0-91 | 91.2 | 80 | 52 | FOUND 103, 925, 7.2 | FOUND 103, 925, 7.1 |
| loc40-o0-83 | 83.7 | 72 | 60 | FOUND 107, 2787, 22.7 | FOUND 107, 2787, 24.7 |
| loc6-o3-65 | 65.1 | 64 | 37 | FOUND 112, 1806, 14.7 | FOUND 112, 1806, 14.6 |
| loc66-o3-64 | 63.8 | 54 | 29 | FOUND 78, 409, 3.2 | FOUND 78, 409, 3.2 |

## Findings

1. **The shipped length cap is the limit, not the cost.** `min(max-length 96, max(1.75 × d, d + 48))` is 96 for
   every leg of 48 blocks or more. Of the 9 legs reachable inside the box, the shipped cap finds 4; **`max-length` 144 finds
   all 9** (paths 78-119 blocks for 58-91 straight). Legs up to 48 blocks keep their cap (≤ 96) either way.
2. **Search cost is fine:** found legs take 2-45 ms, failing ones up to ~140 ms (the 20 000-expansion budget), off the
   main thread, at most 2 at a time.
3. **The other 13 legs are unreachable inside the box** (NO_PATH even with no cap and 400 000 expansions). With
   margin 32, 8 of them are "found" as 240-460-block walks round town walls - a detour, not a last leg; the road
   network is the better guide there. Keep margin 16.
4. **Capture is the constraint at 96:** 15 % of 96-block legs need 50-64 chunks and fall back to the straight line.

## Recommendation for step 2b

- **Walk range 96** (as decided, = `max-start-distance`), with **`MAX_CHUNKS_PER_REQUEST` 64** (8 × 8; ≈ 115 ms of
  main-thread capture over several ticks, ≈ 0.8 MB) so every 96-block leg, start or end, can be captured; or walk
  range 80 and keep 49.
- **`navigation.walk.max-length` 144** (from 96): legs over 48 blocks get a cap of 1.5-1.75 × their length (up to 144).
- 96-256 off-road: by road, then "No conventional path to X found." with the HUD arrow; beyond 256 refused (decided
  2026-10-09). No dev-world destination falls there today.
- Fix Location 7's y (data).
