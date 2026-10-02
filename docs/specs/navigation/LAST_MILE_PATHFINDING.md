# Road Navigation — Last-mile walkable pathfinding (design)

**Status:** Design proposed — **not implemented**. Ladders, doors and chunk loading were reviewed by the developer on 2026-10-02 (§11); the remaining §11 defaults are still unreviewed.
**Last updated:** 2026-10-02 (rev. 2: ladders, interact-gated doors, chunk-loading rationale, §13 KNG-36)
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
has been merged, and whether KNG-27 items 2 and 3 (§5.5) have landed — this design depends on item 3 (§8).

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
| **Drop 2-3** (new, directed) | landing cell is a valid cell, the column above the landing is clear for the fall, ≤ `max-drop` (default 3 = no fall damage) | +2.0 per block |
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
- **Budget:** `max-expansions` (default 20 000) and a path-length cap (default 1.75 × straight distance, at most
  96 cells). Exhausted or unreachable → `FALLBACK` (§7). No partial paths in v1: a path that stops short at a wall
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
  through a door the player cannot open. KnK domain permissions can be added as a second condition if the developer
  wants them. Staff with the region bypass → allowed.

`CellAccess` is a small port: `double extraCost(x,y,z)` — `0` free, finite = allowed at a penalty, `+∞` = blocked —
plus a deny reason for debugging. Cost-or-blocked (not a boolean) is deliberate: it also expresses "a gate I may breach
at a price" for NPC attackers later (§13). The core search is testable with ASCII fixtures.

## 7. One mechanism for direct mode (answers open question 3)

KNG-27 item 3 gives direct mode a periodic recheck. Both must be **one** mechanism, so item 3 is implemented first
with this seam (recommended order in §10):

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
- The item 3 recheck (same `RECHECK_TICKS` cadence) recomputes when the player is more than **6 blocks** from the path
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
`max-length-factor` (1.75), `max-length` (96), `max-drop` (3), `capture-margin` (16), `chunk-ttl-seconds` (10),
`recompute-distance` (6), `max-concurrent-searches` (2).

## 10. Phases (one fresh session each, order matters)

| Phase | Content | Size* | Needs |
|---|---|---|---|
| **0** | KNG-27 item 3 (direct-mode recheck) with the `DirectLeg` seam (§7), **no** walk path yet | small | §5.5 item 3; may already be done by the time this starts |
| **A** | `knk-core roads/walk/`: extract `WalkGrid` from `SpanGrid` (unchanged behaviour, existing tests green), `WalkSearch`, `CellAccess`, `PassabilityRules` additions, ladder links, `MovementProfile`, ASCII-fixture tests (§12) | **largest**, no Bukkit, no server | — |
| **B** | knk-paper: `WalkSnapshotService` (capture, `TickBudget`, TTL cache), `CellAccess` adapters (gates, denied regions, door-interact checks), ladder/door cell capture, the `permissive roadFloor` capture check | medium | A |
| **C** | Wire `DirectLeg` → walk path, `TrailRenderer.drawPath`, config, messages, kill switch; `NavigationServiceTest` with a fake `WalkPathfinder` | medium | 0, A, B |
| **D** (later) | Routed-mode start leg (player → road) and end leg in `drawRoute` use the same search; region last-leg predicate after KNG-27 item 2; ladders/doors refinements | optional | C + live feedback |

\* Relative effort: A ≈ 40 %, B ≈ 20 %, C ≈ 30 %, docs/status ≈ 10 % of the total. Phase A is a good first, self-contained
session — it can be fully verified by unit tests with no Minecraft server (the cloud sessions already compile
`knk-core` this way).

**Scope note.** The issue scopes this to `a.direct == true`. The same straight-line `drawLeg` is also used by the
*routed* trail for the player→road and road→target legs (`TrailRenderer.drawRoute`). v1 covers direct mode and the
`arrivedAtRouteEnd` handoff (which *is* direct mode) — the case observed live. Phase D covers the rest, cheaply, since
it reuses everything.

## 11. Decisions for the developer (reversible defaults chosen; veto any)

1. **Drops:** allow 2-3 block drops (default) vs ±1 only. Alley/roof towns need drops; 3 is the no-damage limit.
2. **Doors — decided 2026-10-02:** hand-openable doors/gates walkable only where the player may interact (§6); iron doors never.
3. **Water:** shallow wading allowed at ×3 cost; no swimming. Alternative: water impassable.
4. **Ladders — decided 2026-10-02:** allowed in v1 (§4). Vines/scaffolding later through `climbables`.
5. **No partial path** when the budget runs out — straight fallback instead.
6. **No chunk loading in v1** — rationale in §8; revisit in Phase D. (Explained to the developer 2026-10-02; not yet a veto.)
7. **Scope** is direct mode + `arrivedAtRouteEnd` in v1; routed start/end legs are Phase D.
8. **Do not adopt the Pathetic library now.** The research report ([2026-09-27](../../reports/2026-09-27-road-navigation-research.md) §5.3)
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

