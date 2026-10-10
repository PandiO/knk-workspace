# Road Navigation — Last-mile walkable pathfinding (design)

**Status:** Design decided — **Phases A-C implemented** (knk-core `roads/walk/`, knk-paper `navigation/walk/` + direct-mode wiring, unmerged, knk-plugin `claude/navigation-walkable-path` `305829b`, 2026-10-02); live test and Phase D next. Reviewed by the developer on 2026-10-02 (§11): decided items 1-4, 5 (pending live test), 6, 8; item 7 (scope) decided. No open decisions remain except the live test of item 5.
**Last updated:** 2026-10-10 (rev. 11: §5/§9 climb allowance for tall buildings, KNG-108; rev. 10: §10 Phase D step 1, the walk to the road, KNG-75; rev. 9: §11-5 no straight line after a failed search, finding N8; rev. 8: §4/§9 wall cost, finding N7; rev. 7: §11-5 partial paths implemented; rev. 6: §5/§9 detour allowance, live-test finding N2; rev. 5: §10 "Phase C status"; rev. 4: §10 "Phase B status"; rev. 3: §10 "Phase A status"; rev. 2: ladders, interact-gated doors, chunk-loading rationale, §13 KNG-36)
**Linear:** [KNG-51](https://linear.app/kngpandi/issue/KNG-51/navigation-last-mile-walkable-pathfinding-for-direct-modeoff-road-legs)
(split out of [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-auto-detected-road-graph-junctionsendpoints-from-road))
**Parent design:** [DESIGN.md](DESIGN.md) §6.2 ("real off-road pathfinding is Phase 6" — this document is the
first slice of it) · **Fix plan it was split from:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) §5.5
**Evidence:** [guides/road-navigation-smoke-test.md](../../guides/road-navigation-smoke-test.md) (findings 1 and 4,
live smoke test 2026-10-01)
**Code read for this design:** `knk-plugin` branch `claude/road-navigation` at `4e3f8af` (unmerged — see §0).

## 0. Freshness

All navigation code lives on the unmerged `claude/road-navigation` branches (`ACTIVE_SESSIONS.md`, 2026-10-01: nothing
merged to trunk). File and line references below are to that branch. Before Phase A, re-check the branch, whether it
has been merged. **Update 2026-10-02 (evening):** KNG-27 fix-plan items 1-6 have since landed on `claude/road-navigation`
(knk-plugin `6a73945` items 2-4, `9f66fea` item 5, `ef556e2` item 6; knk-web-app `6414e18` item 1; head `075ae94`, plus the
developer's own smoke-test fixes), so the direct-mode recheck this design builds on exists as
`NavigationService.recheckDirect` (§7).

## 1. Goal and non-goals

**Goal.** When the trail leaves the road network — direct mode, or the last leg after the road ends short of the
target — it follows a **walkable path over real blocks**, not a straight line through walls, down cliffs and across
gaps. If no path is found within budget, the trail falls back to today's straight line, so the player is never left
without a trail.

**Non-goals (v1).** A general navmesh; searches beyond ~48-64 blocks (the 48-block hard limit of DESIGN §6.2 stays);
replacing the road A\*; NPC routing; ladders/vines/swimming routes; async chunk loading.

## 2. What the issue assumed vs. what the code has

KNG-51 says no walkable-path utility exists. True for a *pathfinder*; **not true for the walkability model**, which
the road builder already has, Bukkit-free and tested. This shrinks the work considerably.

| Piece | Where (`claude/road-navigation`) | Reusable for the last mile? |
|---|---|---|
| Block view port (`isPassable`/`isSolid`/`isHazard`, `minY`/`maxY`) | `knk-core/.../util/BlockProbe`, extended by `roads/build/SurfaceGrid` (+ `floorMaterial`, `isStairOrSlab`) | **Yes, as is.** |
| Passable/solid/overlay/hazard rules over material names | `roads/build/PassabilityRules` | **Yes, as is.** Needs a few additions (§4). |
| Span = floor + 2 headroom, no hazard; links to dy ∈ {-1,0,+1}; jump/stair/slab step rule; diagonal corner rule | `roads/build/SpanGrid` (`isSpan`, `neighbourDy`, `stepAllowed`, `cornerPath`) | **The logic yes, the class no:** `isSpan` also requires a *road* material via `ProfileSet.isRoadMaterial`. Extract the profile-free core (§4). |
| Gate-door footprint cells | `roads/build/GateCells`, paper `roads/GateCellsIndex` | **Yes.** |
| Chunk-snapshot → compact spans, Bukkit collision flag | paper `roads/SpanExtractor`, `CompactSpans`, `CompactSurfaceGrid` (takes a `roadFloor` predicate), `ChunkSnapshotSurfaceGrid` | **Probably yes with `roadFloor = any material`** — verify memory per chunk and extraction time in Phase B. |
| Per-player access verdicts | `roads/route/AccessPolicy.check(RoadEdge)`, `GateAvailability`, `DomainAvailability` | **No — edge-based** (`edge.gateDoorIds()`, `edge.regionIds()`). A block search has no edges. See §6; this corrects the issue's "respect `AccessPolicy` the same way". |
| Search skeleton | `roads/route/AStarRouter` (`PriorityQueue<Entry(f,g,seq,state)>`) | **Pattern only.** Different state space (packed block keys, not nodes/edges). |
| Async request → main-thread delivery with a generation counter | `NavigationService.computeRoute`/`deliver`, `Active.generation` | **Yes — same pattern** (§5). |
| Particle drawing, tick-lag budget | paper `utils/ParticleDraw`, `utils/TickBudget` | **Yes.** |

## 3. Architecture

```
main thread                          routing executor                    main thread
-----------                          ----------------                    -----------
WalkSnapshotService                  WalkSearch (pure A*)                NavigationService
  capture chunks (TickBudget)  --->    over WalkGrid + CellAccess  --->    adopt path if generation matches
  region/gate cell access built        budget: expansions + length         TrailRenderer.drawPath
```

New code, all Bukkit-free except the capture adapter:

- **knk-core `roads/walk/`** (new sub-package next to `roads/route/`; answers open question 2 — it is a different
  search space than the road graph and should not be mixed into `route/`):
  - `WalkGrid` — profile-free neighbour/step logic extracted from `SpanGrid` (§4). `SpanGrid` then delegates to it,
    behaviour unchanged (extraction commit with the existing `SpanGridTest` as the proof).
  - `MovementProfile` — what the mover can do (headroom, step-up, max drop, door/gate capability, wading, climbables).
    The player profile is the only one in v1; it exists so KNG-36 can add NPC profiles without a rewrite (§13).
  - `WalkSearch` — bounded A\* (§5).
  - `WalkRequest` / `WalkResult` / `WalkPath` (floor-cell polyline + length + status).
  - `CellAccess` — the cell-level analogue of `AccessPolicy` (§6).
  - `WalkPathfinder` — the one-method interface `NavigationService` depends on, so a different engine (§11, item 8)
    can be swapped in.
- **knk-paper:**
  - `navigation/WalkSnapshotService` — captures the chunks around the leg on the main thread within `TickBudget`,
    keeps a short-TTL chunk cache, builds the `CellAccess` for the player.
  - `NavigationService`/`TrailRenderer` changes (§7, §8).

## 4. Walkability rule (answers "a concrete block-passability rule")

A **walk cell** is a floor block `(x,y,z)` such that: it is solid and not an overlay (looking through overlays like
carpets/snow, as `SpanGrid` does); it is not a hazard (`PassabilityRules.HAZARD_MATERIALS`); and the two blocks above
it are passable and hazard-free (gate footprints count as passable headroom, as in the builder). That is
`SpanGrid.isSpan` **minus the road-material test.**

**Links** — 8 horizontal directions, as `SpanGrid`:

| Move | Rule | Cost |
|---|---|---|
| Level | always | 1 (orthogonal), 1.41 (diagonal) |
| Step up 1 | lower cell has a 3rd passable block above (room to jump), **or** the upper cell is a stair/slab | +1.0 (+0.0 for stair/slab) |
| Step down 1 | symmetric to step up | +0.0 |
| **Drop 2-3** (new, directed) | landing cell is a valid cell, the column above the landing is clear for the fall, ≤ `max-drop` (default 3 = no fall damage) | **+10 per block** — avoided whenever any other route exists (`drop-penalty`, decided 2026-10-02) |
| Diagonal | needs an L-shaped walk through one flanking orthogonal cell (the existing `cornerPath` rule), so corners of walls are not cut | as above |

New material handling (put in `PassabilityRules`, with tests; none of this exists today because roads are flat
decorated paths):

- **Never a floor:** `*_FENCE`, `*_WALL`, `*_FENCE_GATE` (closed), iron doors/trapdoors, `*_PANE`/`IRON_BARS`
  (a 1.5-high collision box cannot be stood on or jumped onto). They are already non-passable for the cell above, so
  they correctly block movement.
- **Doors and fence gates (decided 2026-10-02):** hand-openable doors and gates (`*_DOOR` except iron, `*_FENCE_GATE`)
  are **walkable only if the player is allowed to interact there** (§6); an allowed door costs +3. Iron doors are never
  walkable (they need redstone). The span rule counts a door's blocks as passable feet/headroom — the same precedent
  as `GateCells` — and tags the cell so access is decided per request, not per material. Trapdoors are not entries
  in v1.
- **Water:** a cell whose feet block is water costs ×3; no cell without a solid floor exists, so open deep water is
  impassable. Swimming routes are out of scope (§11-3).
- **Ladders (decided 2026-10-02):** a column of consecutive `LADDER` blocks is a **climb**. A ladder block is
  passable but has no floor, so it is not a span; the search gets a second node kind, a *ladder cell* (feet block,
  flagged). Links: a standing span ↔ an adjacent ladder cell at its feet level; ladder cell ↔ ladder cell one block up
  or down (cost 2.0 per block — climbing is about half walking speed); a ladder cell → an adjacent standing span with
  floor at the ladder's level − 1 (a ledge beside it) or at its level (stepping off onto the wall top). Block facing is
  not needed: a cell on the wall side is solid, so it can never be a standing span. Config `climbables` (default
  `[LADDER]`) leaves room for vines/scaffolding later. Capture must record ladder cells, which `CompactSpans` does not
  store today — Phase B verifies this.
- **Player-placed obstacles / entities:** read from the live chunk snapshot at request time; entities are ignored.
- Slab/stair top height (0.5) is ignored for the trail height; `TrailRenderer.LIFT` stays as is.

## 5. The search (answers open question 1)

**A\*, not BFS.** The walkable surface is 2.5D (≈ one cell per column, a few stacked), so a 48-block radius is
≈ 100 × 100 columns ≈ **~13k cells worst case**, not "thousands of 3D blocks" — and the Euclidean heuristic means
typical searches expand a small fraction of that. BFS would expand the same worst case with no ordering benefit.

- **State:** packed `BlockKey` (already in `knk-core/util`), `long`-keyed open/closed maps.
- **Heuristic:** 3D octile/Euclidean distance to the goal (admissible with the costs above).
- **Start:** nearest walk cell to the player's feet within 2 blocks (mid-jump, on a ladder, in water). **Goal:** the
  target floor point snapped to the nearest walk cell within 3 blocks; the search ends when a cell is within
  `arriveDistance` of the target, or — for regions — when a `RegionShape.containsFloor` cell is reached (the goal is a
  predicate, so KNG-27 item 2's region last-leg can use it unchanged). No start/goal cell → `NO_PATH`.
- **Budget:** `max-expansions` (default 20 000) and a path-length cap: 1.75 × the straight distance or the straight
  distance + `detour-allowance` (48), whichever is longer, at most 96 cells. Exhausted or unreachable → `FALLBACK` (§7).
  *Rev. 6, 2026-10-07 (developer decision, live-test finding N2):* the factor alone was too tight for short legs.
  `/navigate Merchant Square` from 27.5 blocks away hit the cap of 48 while the only walkable way round the
  building was 67.7 blocks. The allowance gives every leg room to go round a block of houses; long legs are still
  bounded by the factor and by 96. *Rev. 11, 2026-10-10 ([KNG-108](https://linear.app/kngpandi/issue/KNG-108),
  live-test finding N17):* plus `climb-allowance` (5) blocks per block of height between start and target, above
  `max-length` too. The Keep Tower Roof's only way down is a spiral stair, 168 blocks for 29 of height, against a cap of
  77.6; the allowance makes it 217.6 (77.6 + 5 × 28, height from the start's floor). The replay found that path inside
  the shipped capture box (margin 16) in 1642 expansions, so neither the box nor the expansion budget changes. No partial paths in v1: a path that stops short at a wall
  is worse than an honest straight line.
- **Threading:** capture on the main thread, search on the existing routing executor, result delivered through
  `deps.mainThread()` and dropped when `Active.generation` moved on — exactly `computeRoute`/`deliver`.

## 6. Access at cell level (answers "respect AccessPolicy")

`AccessPolicy.check(RoadEdge)` cannot be called on a block. The same *rules* apply, expressed per cell, built per
request on the main thread (like `NavigationAccess.policyFor`) so the search thread touches no Bukkit:

- **Gates:** `GateCells.doorAt(x,y,z)` identifies a closed-footprint cell; its verdict comes from the **same**
  `GateAvailability` state/pass-rule logic the road router uses (open/jammed/destroyed/pass-through/siege lock). A cell
  whose door the player cannot pass is not walkable.
- **Domains:** one WorldGuard query on the main thread for the regions overlapping the search bounding box; keep only
  those whose domain **denies entry** (for regions the player is not in) or **denies exit** (for regions the player is
  in) via the shared `DomainAccessEvaluator`; the per-cell test is then pure geometry (`ProtectedRegion.contains`).
  Bypass permission (`knk.region.bypass`, staff) → everything open. This reproduces `DomainAvailability`'s entry/exit
  semantics. **Verify in Phase B** that `contains` is safe off the main thread; if not, copy the denied regions into
  Bukkit-free `RegionShape`s (the type already exists for destinations).
- **Siege:** a player in a siege has no navigation (`NavigationEligibility`); siege lockdown gates are covered by the
  gate rule above.

- **Doors (decided 2026-10-02):** during chunk capture (main thread) the door/gate cells inside the search box are
  collected (usually a handful). Each is checked **once per request** for "may this player interact here" and the
  verdict stored per cell, so the search thread stays Bukkit-free. Allowed → +3, denied → blocked. The check is **new**:
  the plugin has no interact helper today (grep of `knk-core`/`knk-paper` on `claude/road-navigation`, 2026-10-02). The
  recommended implementation is WorldGuard's own answer — `RegionQuery#testState(location, player, Flags.USE)` (and
  `Flags.INTERACT`), because it is what WG enforces when the player actually clicks the door, so the trail never leads
  through a door the player cannot open. **KnK domain permissions are also required (decided 2026-10-02):** the door must pass the WG check **and** the
  same domain entry rules as §6's domain bullet. Staff with the region bypass → allowed.

`CellAccess` is a small port: `double extraCost(x,y,z)` — `0` free, finite = allowed at a penalty, `+∞` = blocked —
plus a deny reason for debugging. Cost-or-blocked (not a boolean) is deliberate: it also expresses "a gate I may breach
at a price" for NPC attackers later (§13). The core search is testable with ASCII fixtures.

## 7. One mechanism for direct mode (answers open question 3)

KNG-27 item 3 gave direct mode a periodic recheck (**implemented**: `NavigationService.recheckDirect`, fields
`directBest` / `lastDirectRecalcTick` on `Active`, message `directRecalculating`, trigger "the player is more than
`reroute-distance` farther from the target than their closest approach", rate-limited by `reroute-min-interval`). The
walk path must use **that** recheck, not a second one: Phase C first refactors those fields into the `DirectLeg` below
(behaviour unchanged, existing tests green), then adds the walk path:

```java
final class DirectLeg {               // owned by Active; replaces a.target-only direct mode
    double[] target;
    List<double[]> path;              // null until a walk path is adopted
    enum Status { PENDING, WALKING, FALLBACK }
    long computedTick;
    int generation;
}
```

- `startDirect` creates the leg, draws the straight line **immediately** (PENDING — the player always has a trail)
  and requests a walk path.
- On adoption the trail switches to the path (WALKING). On `NO_PATH`/budget exhaustion the leg is FALLBACK and keeps
  today's straight line (and today's colour — no new visual state in v1).
- The existing recheck (same `RECHECK_TICKS` cadence) keeps its "heading away" trigger and additionally recomputes when the player is more than **6 blocks** from the path
  polyline (3D), the target moved, a gate/availability event fired for an active direct leg, or the path is older than
  **10 s** (player-placed blocks). It never recomputes every tick, and never while a request is in flight.
- `arrivedAtRouteEnd` hands the real end of the road to the same `DirectLeg`, so routed→direct is not a special case.
- Arrival stays Euclidean (`arriveDistance`) or `RegionShape.containsFloor` — unchanged.

`TrailRenderer`: add `drawPath(viewer, List<double[]> floorPoints)` — same windowing as `drawRoute` (the next
`trail-length` blocks from the player's projection, half length under lag), leg colour, `LEG_SPACING`. Path cells are
already floor cells, so the per-point `KnkLocations.floorOf` world reads in `drawLeg` are **not** needed for a walk
path (they remain for the straight fallback). `drawDirect(viewer, target)` stays as the fallback.

## 8. Chunk capture, performance, chunk loading

- **Which chunks:** the bounding box of start and goal expanded by a margin (default 16 blocks), capped to the 48-64
  block leg — typically 9-25 chunks, not the 49-81 of a full radius.
- **Only already-loaded chunks** (`World#isChunkLoaded`); a needed chunk that is not loaded → `NO_PATH` → straight
  fallback. **No chunk loading in v1.** Why (decided to explain 2026-10-02; the developer asked whether it is workload):
  workload is part of it, but not the main reason. (1) The leg is within 48 blocks = 3 chunks of the player, so the
  chunks are already loaded unless the server's view/simulation distance is set below ~4 — loading would almost never
  trigger. (2) A *synchronous* load stalls the main thread on disk/worldgen; an *async* load
  (`World#getChunkAtAsync`) is cheap but adds a waiting state, ticket lifetime and failure handling to every request.
  (3) Loading can **generate** new terrain in unexplored areas and keeps the chunk (and its entities) alive — side
  effects a visual guide should not have. (4) The fallback (today's straight line) is already acceptable when it
  happens. **Revisit in Phase D**: if live tests show the destination end is often unloaded, add async load of
  *existing* chunks only (`gen=false`), capped per request, with the ticket released after capture.
- **Main-thread cost:** `getChunkSnapshot` + `SpanExtractor` per chunk, spread over ticks by `TickBudget` (the road
  build already does this); a request waits in PENDING until its chunks are captured.
- **Cache:** `(world, chunkX, chunkZ) → compact spans`, TTL 10 s (matches the recompute age above), small LRU. A
  recompute for a moving player mostly reuses it. Invalidating it from `RoadDirtyTracker`'s block-change hooks is a
  possible later optimisation, not v1.
- **Search cost:** off the main thread; the ~13k-cell worst case with `long` maps is milliseconds-scale — measure in
  Phase A with a 96×96 open-field fixture and record the number in the phase status block.
- **Throttle:** one in-flight request per player; one global cap on concurrent walk searches (default 2).

## 9. Config (`navigation.walk.*`, in `NavigationConfig`)

`enabled` (true; false = today's straight lines — also the kill switch), `max-expansions` (20000),
`max-length-factor` (1.75), `max-length` (144 since KNG-75 step 2b; was 96), `detour-allowance` (48, rev. 6),
`climb-allowance` (5, rev. 11: blocks per block of height, also above `max-length`; KNG-108), `max-drop` (3), `drop-penalty` (10), `capture-margin` (16), `chunk-ttl-seconds` (10),
`recompute-distance` (6), `max-concurrent-searches` (2), `wall-cost` (1.0, rev. 8: a step onto a cell with a wall
among its 8 neighbours costs this much extra, so paths keep a block from walls and round corners wider - live-test
finding N7, the trail seemed to stop behind tight corners).

## 10. Phases (one fresh session each, order matters)

| Phase | Content | Size* | Needs |
|---|---|---|---|
| **0** | ~~KNG-27 item 3 (direct-mode recheck)~~ — **done 2026-10-02** (`6a73945`); the `DirectLeg` refactor moved into Phase C | — | — |
| **A** | `knk-core roads/walk/`: extract `WalkGrid` from `SpanGrid` (unchanged behaviour, existing tests green), `WalkSearch`, `CellAccess`, `PassabilityRules` additions, ladder links, `MovementProfile`, ASCII-fixture tests (§12) | **largest**, no Bukkit, no server | — |
| **B** | knk-paper: `WalkSnapshotService` (capture, `TickBudget`, TTL cache), `CellAccess` adapters (gates, denied regions, door-interact checks), ladder/door cell capture, the `permissive roadFloor` capture check | medium | A |
| **C** | Refactor the direct-mode fields of `Active` into `DirectLeg` (no behaviour change, existing tests green), then wire it → walk path, `TrailRenderer.drawPath`, config, messages, kill switch; `NavigationServiceTest` with a fake `WalkPathfinder` | medium | A, B |
| **D** (later) | Routed-mode start leg (player → road) and end leg in `drawRoute` use the same search; region last-leg predicate after KNG-27 item 2; ladders/doors refinements | optional | C + live feedback |

**Phase A status (2026-10-02, walkable chain link 2).** Done on knk-plugin `claude/navigation-walkable-path`
(`ea54013` extraction, `6352b4c` rules, `1fae034` search, `ad311ae` timing/maps). knk-core `roads/walk/`: `WalkGrid`
(extracted from `SpanGrid`, which delegates — road-builder tests unchanged and green), `MovementProfile`, `CellAccess`,
`WalkCells` (door/climbable/water flag port — the capture must provide it, §4), `WalkTerrain`, `WalkGoal`, `WalkBudget`,
`WalkRequest`/`WalkResult`/`WalkPath`, `WalkPathfinder` ← `WalkSearch`. `PassabilityRules` gained `isNeverFloor`,
`isHandOpenableDoor`, `isWalkFloor`, `isWater`. All §12 core fixtures are tests (knk-core 1561 → 1619). **96×96 open
field** (fixture terrain, 4-core cloud container, median after warm-up): straight across 95 blocks ≈ 3-5 ms (95
expansions); whole field expanded (9 215 cells, unreachable target) ≈ 80-90 ms; same with the default budget ≈ 75 ms
(stops at the length cap). That is above §8's "milliseconds-scale" guess for the worst case, but off the main thread and
bounded by the budget; typical legs expand a few hundred cells. Where the implementation settled details the design left
open, see the progress report's "Link 2" section (decisions L2-1 … L2-10); the most visible: unreachable → `NO_PATH`,
budget/length cap → `FALLBACK` (§12 wording; §5's sentence says both are FALLBACK — Phase C treats them alike).

**Phase B status (2026-10-02, walkable chain link 3).** Done on knk-plugin `claude/navigation-walkable-path`
(`beec0e1` cell access, `905987b` capture, `12c834a` snapshot service + config, `d08c341` `NavigationAccess.gateAvailability`
extraction, `aa320e5` access factory). knk-core `roads/walk/`: `GateCellAccess`, `DeniedRegionAccess`, `DoorCellAccess`.
knk-paper `navigation/walk/`: `WalkChunk`/`WalkChunkExtractor`/`CapturedWalkTerrain` (the capture), `WalkBox`,
`WalkSnapshotService` (loaded chunks only, `TickBudget`, shared TTL cache), `WalkAccessFactory` + `WorldGuardWalkAccess`;
`NavigationConfig.WalkConfig` (`navigation.walk.*`). Not wired into navigation yet. Two §2/§6 expectations changed:
the capture is its own per-block flags capture rather than `CompactSpans` with a permissive `roadFloor` (the walk search
asks about drop columns, ladders and water, which spans do not store); `ProtectedRegion.contains` off-thread was not
verified — denied regions are copied into `RegionShape`s instead. Measured on a synthetic chunk: ≈ 12 KB and
0.4-0.7 ms per chunk for a leg's 3-section band (array source; the live `ChunkSnapshot` number is Phase C's to read
from `WalkSnapshotService.stats()`). Tests: knk-core 1619 → 1628, knk-paper 1089 → 1116. Decisions L3-1 … L3-10 in the
progress report's "Link 3" section.

**Phase C status (2026-10-02, walkable chain link 4).** Done on knk-plugin `claude/navigation-walkable-path`
(`b0eee28` `DirectLeg` refactor — behaviour unchanged, navigation tests green; `fc1a98d` `TrailRenderer.drawPath`;
`305829b` wiring, config, kill switch). A direct leg (nearby target, and the last leg after a road's end) draws the
straight line at once (PENDING), captures and searches a walk path off the main thread (own `knk-navigation-walk`
pool of `max-concurrent-searches` threads) and switches to it (WALKING); no path of any kind keeps the straight line
(FALLBACK, §11-5). The existing `recheckDirect` is the only re-check: it also recomputes off the path (> 6), on a moved
target, after a gate/availability event and at 10 s, never while a request is in flight; "heading away" is measured
along a walking path. `config.yml` has the `navigation.walk:` block; `enabled: false` starts none of it and reproduces
the straight lines exactly (transcript test). `/knk road status` shows a "walk paths" line with the capture's µs per
chunk — **the live §8 number is still to be recorded** here. Tests: knk-paper 1116 → 1131. Decisions L4-1 … L4-10,
the combined live checklist (§11-5 first, then the §12 matrix) and the merge order are in the progress report's
"Link 4" section.

\* Relative effort: A ≈ 40 %, B ≈ 20 %, C ≈ 30 %, docs/status ≈ 10 % of the total. Phase A is a good first, self-contained
session — it can be fully verified by unit tests with no Minecraft server (the cloud sessions already compile
`knk-core` this way).

**Scope note.** The issue scopes this to `a.direct == true`. The same straight-line `drawLeg` is also used by the
*routed* trail for the player→road and road→target legs (`TrailRenderer.drawRoute`). v1 covers direct mode and the
`arrivedAtRouteEnd` handoff (which *is* direct mode) — the case observed live. Phase D covers the rest, cheaply, since
it reuses everything.

**Phase D ([KNG-75](https://linear.app/kngpandi/issue/KNG-75)), decided 2026-10-09 (developer).** Step 1, the walk to
the road: with walk paths, a player off the road walks to where the route starts along a walk path - a second
`DirectLeg`, `Active.startLeg`, aimed whenever a route is adopted and the player is more than `reroute-distance` from
it. The route is drawn from the road on (`drawRoute(…, fromPlayer=false)`); the straight line only while the search
runs or without a result. No way: "No conventional path to the road found." once, no straight line, the navigation
carries on. The core session waits until the player is within `reroute-distance` of the route; heading away drops the
leg and lets the session re-route from the road now nearest. The player may start `max-start-distance` (96) from a
road in plain 3D (`Snapper.snapRanked`: `snap-vertical-weight` only picks the road). Without walk paths nothing
changes (weighted 48, straight lines). **Implemented, live-tested and merged 2026-10-09** (knk-plugin `main`
`c4141f90`; smoke-test guide "KNG-75 step 1"). Live-test follow-ups: heading away needs both measures - farther
along the leg and farther from the route (N16, `c923aa3d`); a search out of budget on the way to the road says
"Having trouble determining the route - guiding you to the nearest road." instead of "No conventional path" (N17,
`2273ffaa`; a height allowance in the length cap for tall buildings is later, KNG-108). **Step 2a measured
(2026-10-10, [report](../../reports/2026-10-10-kng75-walk-leg-measurement.md)):** the shipped length cap (≤ 96) is
what stops 48-96 block legs (4 of 9 reachable found; `max-length` 144 finds all 9), searches take 2-140 ms off the main
thread, and 15 % of 96-block legs need 50-64 chunks (limit 49). Recommended for 2b: walk range 96, chunk limit 64,
`max-length` 144 - **accepted 2026-10-10 and implemented** (knk-plugin `claude/kng-75-offroad-destinations` `7b8a11cc`:
`walk.max-length` 144, `MAX_CHUNKS_PER_REQUEST` 64; `6c036eaf`: `max-destination-distance` 256,
`destination-walk-range` 96, the far leg - `DirectLeg.beyondWalkRange`, "No conventional path to X found." and the HUD
arrow, a walk leg once within 96; the route's trail draws no straight line on to such a target). Live test: guide
"KNG-75 step 2" B1-B6 - **all pass; merged to knk-plugin `main` `8f2b7c30` (2026-10-10). Phase D (KNG-75) is done**;
step 3 (chained legs) is KNG-36's, a height allowance for tall buildings KNG-108 (**implemented 2026-10-10**, knk-plugin
`claude/dazzling-dijkstra-94leyd` `8e0a83d`, not merged or live-tested; §5 rev. 11). Step 2: measure a 96-block leg's capture and search cost
(the capture limit is 49 chunks), then destinations up to the walk range by road plus a walk path, up to 256 by road
plus "No conventional path to X found." with the HUD arrow, beyond 256 refused. Step 3 (chained legs, KNG-36) only on
request.

## 11. Decisions for the developer (reversible defaults chosen; veto any)

1. **Drops — decided 2026-10-02:** 2-3 block drops are allowed but never preferred: the +10/block penalty makes any other route win, and a drop is used only when it is the sole way (or a far shorter one than ~10 blocks of detour per block dropped).
2. **Doors — decided 2026-10-02:** hand-openable doors/gates walkable only where the player may interact (§6) — WorldGuard `USE`/`INTERACT` **and** KnK domain rules; iron doors never.
3. **Water — approved 2026-10-02:** shallow wading allowed at ×3 cost; no swimming.
4. **Ladders — decided 2026-10-02:** allowed in v1 (§4). Vines/scaffolding later through `climbables`.
5. **No partial path — agreed 2026-10-02**, **to be tested on the live server** (does the straight fallback read acceptably, or is a partial path better?). Record the result here. **2026-10-07, developer:** prefers a **partial path**, untested (no unreachable destination on the dev world). **Decided and implemented 2026-10-08** (knk-plugin `d369ad4`): a NO_PATH or FALLBACK result carries `partialPath()`, the way to the expanded cell closest to the target (3D distance, ties to the cheaper), when that cell is at least 2 blocks closer than the start; `path()` stays empty. Direct mode follows it and draws the rest as a straight line to the target; it is recomputed like any walk path, and `/knk road status` counts it ("partial N"). A target with no walkable cell within 3 blocks still gets the straight line. Live test passed (run 3). **Rev. 9 (2026-10-08, finding N8, developer):** after a search that ran and found no way (NO_PATH or out of budget) there is **no straight line** at all: "No conventional path to X found." once per leg ("conventional" on purpose - secret passages), the partial path without a straight continuation, or no trail. Only a search that could not run keeps the straight line. *(N13, same day:)* before that, a nearby target the walk search cannot reach is tried once by road (back and round); a road route turns the navigation into a routed one whose last leg is again a walk path.
6. **No chunk loading in v1** — rationale in §8; revisit in Phase D. (Explained to the developer 2026-10-02; not yet a veto.)
7. **Scope — decided 2026-10-02:** direct mode + `arrivedAtRouteEnd` in v1; the routed start/end legs follow in Phase D once the live test is positive. **2026-10-09:** Phase D is KNG-75 (§10, after the scope note); step 1 implemented.
8. **Do not adopt the Pathetic library now — agreed 2026-10-02.** The research report ([2026-09-27](../../reports/2026-09-27-road-navigation-research.md) §5.3)
   called it the best off-the-shelf option, but: it is a new shaded dependency (cloud sessions have repeatedly had
   `repo.papermc.io`/Maven blocked or rate-limited, `ACTIVE_SESSIONS.md`); the repo already has a tested walkability
   model; and the gate/domain rules would have to be translated into Pathetic's validation processors anyway. The
   `WalkPathfinder` interface keeps the door open to a Pathetic adapter later.

## 12. Test plan

**knk-core (ASCII layers, the `SpanGrid`/`SkeletonGraph` fixture style):** flat field (path = straight); alley with a
1-block jog; wall with a stair detour (path goes around, not through); 1-wide gap; drop of 3 (allowed) and 4
(refused); fence/wall never a floor; door cell allowed vs denied vs iron door; ladder climb up and down, ladder with and without a top exit, ladder beside a ledge; closed gate cell denied → detour or `NO_PATH`; denied-region
cells; goal unreachable → `NO_PATH`; budget exhausted → `FALLBACK`; start/goal snapping; two-level stacked plaza;
96×96 open-field timing. `SpanGrid` behaviour pinned by the existing tests across the extraction.

**knk-paper (Mockito/JUnit, mocked `World` kept in a field):** `DirectLeg` PENDING → WALKING → FALLBACK; stale
generation dropped; recompute cadence (no per-tick recompute, one in flight); `arrivedAtRouteEnd` → direct leg;
kill switch; `TrailRenderer.drawPath` windowing (pure part).

**In-game matrix (developer):** town alley with height differences; multi-level plaza; structure reached via its
Location with a non-road final stretch (the 2026-10-01 case: ~13 m wall); wilderness with cliffs; closed gate on the
shortcut; denied-domain region on the shortcut; a door in a region where the player lacks interact; a ladder shortcut; place/break blocks on the path while navigating; unloaded edge of
the render distance; lag spike (TPS) while a path is computed.

**Definition of done:** the three §6.2 cases from the smoke test (finding 1 and finding 4) walk correctly in-game;
`navigation.walk.enabled: false` restores today's behaviour exactly; no server-tick regression (§8 numbers recorded).

## 13. Relation to KNG-36 (shared NPC traits and pathfinding platform)

**Sources:** [KNG-36](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform)
(Backlog, blocked by KNG-35, blocks KNG-37 and KNG-50; related to KNG-27) and
[specs/siege-survival/DESIGN.md](../siege-survival/DESIGN.md) §6, §12. KNG-36 is a **design** issue for the NPC platform:
it must "integrate with KNG-27 road navigation only where it actually solves NPC movement" and cover off-road,
vertical movement, doors/gates, crowds, changing WorldGuard access, chunk lifecycle, and budgets/benchmarks for path
computation. Siege survival's plan is "start with the existing NPC pathfinder plus explicit waypoints; extend it only
for demonstrated gaps". (The V3 plugin has no Citizens usage today — a grep on `claude/road-navigation` found none — so
"the existing NPC pathfinder" is V1 Citizens knowledge KNG-36 is meant to mine; not verified here.)

**They are different problems that share a middle layer.**

| | KNG-51 (player guidance) | KNG-36 (NPC movement) |
|---|---|---|
| Output | A polyline for particles; imperfect is fine; straight-line fallback | A path an entity must physically follow; a wrong cell = stuck or falling NPC |
| Mover | The player, with their own physics | An entity; an executor (Citizens navigator, Paper mob pathfinder or own steering) has to follow the path |
| Abilities | One (the player) | Per archetype: hitbox size, jump, doors/gates, swimming, climbing, breaching |
| Access | The player's permissions (§6) | Faction rules; gates are things to **breach** (a cost, not a wall) |
| Scale | ≤ 1 search per navigating player | Tens to hundreds of NPCs → shared caches, hard budgets |
| Out of scope for a path search | — | Crowds, combat detours, leash, repath on collision, chunk lifecycle |

**Shared layer = walkability grid + chunk capture/cache + bounded A\* + cell access.** KNG-51 builds that layer, so it
should be reusable without KNG-51 building any NPC feature. The seams below cost almost nothing now and are already in
the design: `MovementProfile` instead of constants (§3); `CellAccess` as cost-or-blocked (§6); `WalkPathfinder` returns
cells independent of the trail (§3); the chunk cache keyed by world/chunk and shared across requests, not per player
(§8); budgets and concurrency caps in config (§9). One concrete consequence: the `SpanGrid.HEADROOM = 2` constant becomes
a `MovementProfile` parameter in the extraction (a larger NPC needs more clearance).

**KNG-51 will not do:** crowd avoidance, following the path with an entity, repath-on-collision, per-NPC budgets,
faction access rules. Those are KNG-36's.

**How KNG-36 would plausibly use it.** Siege lanes are explicit waypoints with "local pathfinding between these
points": bounded segments of tens of blocks — the same shape as the last-mile search — so `WalkPathfinder` between
consecutive waypoints, executed by whatever mover KNG-36 picks (whether Citizens can follow a precomputed waypoint list
is a KNG-36 question). The KNG-27 road graph helps only for long-distance routing (a travelling NPC, DESIGN §8 Phase 6
"NPC routing with the same `AccessPolicy` for NPC factions"), and it needs this search for its off-road ends too.
Siege-survival §13 item 5 already asks to validate physical waypoint pathfinding on the castle map: KNG-36 should
benchmark `roads/walk/` against the Citizens navigator there, rather than assume either.

**Sequencing:** Phases 0-B do not depend on KNG-36 (backlog, itself blocked by KNG-35) and must not wait for it.
The risk to manage is the reverse: KNG-36's requirements widening KNG-51. Keep KNG-51 to player guidance and let KNG-36
add profiles, factions and execution on top of the layer.

