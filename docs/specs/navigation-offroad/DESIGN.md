# Off-road navigation and points of interest — mixed routes, indoor and wilderness walking, better trails

**Status:** **Proposed** (2026-11-17) — open questions in § 15. (On approval: **Decided <date>** (developer).)
**Last updated:** 2026-11-17 (design session: the draft's code claims checked against knk-plugin `next` `e69dba6` and corrected (§ 3.1, § 3.4); a compile-and-test check of the shared shaping package (§ 3.4); the sources re-read and the draft corrected (§ 3.5); question 15.9 answered (O16)); 2026-11-17 (first draft from the developer's voice session of 2026-11-17, checked against knk-plugin `next` `e69dba6` and the docs on knk-workspace `next` `6be8222`)
**Issue:** [PandiO/knk-workspace#698](https://github.com/PandiO/knk-workspace/issues/698); phases as sub-issues in § 14.
**Dependencies:** [navigation](../navigation/DESIGN.md) (road graph, `/navigate`, walk paths, all merged), [navigation destination engine](../navigation-destination-engine/DESIGN.md) (proposed; the POI provider of § 6 plugs into it), the NPC movement quality work on `next` ([architecture § 12](../../architecture/npc-navigation.md#12-movement-quality-phase-4c-links-m1m7), merged 2026-11-16, not yet live tested (#621 to #627 open): `corridor/Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine`, `LocalLegSearch`). Related issues: #603 (NPC movement quality), #625 (NPC plaza lines), #110 (KNG-93, entrances), #25 (KNG-235, destination engine).
**Authority:** the developer's answers of 2026-11-17 (decision log O01–O10 and the answers of the design session, O16 onward). Supersedes nothing yet (question 15.10 asks about the builder through-edges of the NPC plan): the road-navigation design stays binding for the road graph; this document extends its § 6.2 "off-road legs" and "Phase 6" rows. This document is the canonical specification, not a claim that the proposed entities, endpoints or behaviour exist.

Related: [LAST_MILE_PATHFINDING](../navigation/LAST_MILE_PATHFINDING.md), [REV6_PROPOSAL](../navigation/REV6_PROPOSAL.md) (areas before the centreline), [REV7_PROPOSAL](../navigation/REV7_PROPOSAL.md) (routing view, entrances), [NPC movement research](../../reports/2026-11-15-npc-movement-research.md), [NPC platform plan 4c](../npc-platform/IMPLEMENTATION_PLAN.md), [domain discovery](../domain-discovery/DESIGN.md).

## 1. Goal and scope

1. **Goal:** a player can navigate to and from places the road graph does not cover: rooms and corridors inside castles and towers, public spaces inside structures, and open country. A route may mix any number of road legs and off-road legs in any order. A route may also run completely off-road for a long stretch (a whole castle indoors). The particle trail along it reads as a natural walking line: it rounds corners with room to spare, does not jump when the player moves, winds back when the player walks back, and crosses plazas on a smooth line instead of through the plaza's centre node.
2. **In scope (v1):**
    1. Mixed routes: road and walk legs chained dynamically by one planner (§ 5.1, § 5.2).
    2. Long off-road routes, indoors first, through a hierarchical walk search (§ 5.3).
    3. Route preference: shortest, efficient and preferred routes; preference weights on road edges now, on walk areas through POIs (§ 5.4).
    4. Points of interest (POI): a named, optionally connected and optionally extended place; a destination provider for navigation (§ 6).
    5. Wilderness routing: a coarse layer for long open-country legs (§ 5.5).
    6. Guidance quality: wider rounded corners on walk trails, trail particles that do not snap, winding back along the route (§ 7).
    7. Plaza lines for the players' trail: a smooth, node-pulled, obstacle-aware line across a plaza (§ 8, a separate issue with a dependency on § 7).
    8. A measurement first: live numbers of the current walk search in a large indoor build (§ 9.2).
3. **Out of scope:**
    1. Explicit POI to POI links (decision O05: inferred only in v1; the data model leaves room, § 6.3).
    2. A hand-built indoor road graph (decision O02: skipped; preference weights come from POI areas).
    3. The plaza POI subtype and plaza area effects (decision O10: planned extension, § 10.1).
    4. Changes to the road graph builder. The NPC plan's decision of 2026-11-15 puts plaza through-edges in the builder "later, so the players' trail improves too" (npc-platform IMPLEMENTATION_PLAN decision 6, 4c.7); how § 8 relates to it is question 15.10.
    5. Swimming, flying and boat routes, vertical shortcuts with elevators. (LAST_MILE § 1 lists a navmesh, vines and swimming and async chunk loading as its non-goals; ladders were allowed later.)
    6. NPC use of the new layers: the NPC side reuses the same core modules later (§ 7.5.7, § 10); no NPC behaviour changes here.

## 2. Decision log

| ID | Date | Who | Decision |
|---|---|---|---|
| O01 | 2026-11-17 | developer | The navigator must combine road legs and off-road legs dynamically in one route (start off-road, road, off-road, road, in any order), and must support long stretches completely off-road, for example all indoors in a large castle with wooden floors. |
| O02 | 2026-11-17 | developer | Routes can be the shortest, the most efficient, or the preferred one. Preference means weights on road graph stretches (exist today); the same is wanted indoors. A full indoor road graph for that is not required: if it is, skip it and document it for a later update. |
| O03 | 2026-11-17 | developer | Indoor and wilderness may use different methods. Look at best practice in other games. The result must pair computational efficiency with a good in-game result. |
| O04 | 2026-11-17 | developer | New entity, point of interest (POI): in its basic form a Location with a name, attached to an entity that describes it as a place of interest. The link to a domain entity (structure, town, district, any domain) is optional. A POI may define its extent by a WorldGuard region or a range around its position. Built alongside the navigation work, because navigation uses it for indoor walking and wilderness routing. |
| O05 | 2026-11-17 | developer | POIs are disconnected and inferred in the first version: no explicit POI to POI links. Links can follow later if needed. |
| O06 | 2026-11-17 | developer | Performance budgets: check first how the current navigator performs, then set them. |
| O07 | 2026-11-17 | developer | The walk trail still clings to inner walls in tight corners (a spiral tower stair), also when the trail is redrawn as the player moves. The earlier wider-corner change helped a little, not enough. An improvement pass is wanted. |
| O08 | 2026-11-17 | developer | When a player walks back along the route, the navigation must wind back: on a road the road trail is shown again from the player's point on it. Only a player who left the road gets a walk trail to the road. Today the trail is drawn from the point where the player was closest to the destination. |
| O09 | 2026-11-17 | developer | Plazas get their own issue. Where a route enters and leaves a plaza, the trail takes a rounded, shorter line from road A to road B instead of a right angle at the plaza node. The plaza node must still pull on the curve, so the line does not run along the plaza's edges and does not go to the centre and back. The line must be aware of walls and obstacles on the plaza. An earlier attempt at rounding was made and did not work out. |
| O10 | 2026-11-17 | developer | Planned, not for this run: a plaza as a child entity of the POI. The builder keeps recognising plazas and offers the admin a suggestion ("create a plaza POI for this spot"); the admin customises it (WorldGuard region for the exact shape) and the road nodes are connected to it. Area effects and special features attach to the plaza entity later. |
| O11 | 2026-11-17 | agent | Reuse the NPC movement corridor modules for the players' trail: move `Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine` with the world primitives they need (`NavWorld`, `NavPoint`, `NavGeometry`, and `PlazaCrossing` taken out of `RoadPlanner`) to a shared package `core/navigation/shape/`; `LocalLegSearch` stays NPC-side. The player side reads terrain through a `NavWorld` adapter over the captured walk terrain, off the main thread (§ 3.4; alternatives in 2.1). |
| O12 | 2026-11-17 | agent | One planner with road legs and walk legs: dynamic "walk links" between road nodes in the routing view, plus the existing off-road ends (alternatives in 2.1). |
| O13 | 2026-11-17 | agent | Long off-road legs by a lazy hierarchical search over loaded chunks first; persisted walk tiles for wilderness beyond loaded chunks later (matrix in § 5.6, alternatives in 2.1). |
| O14 | 2026-11-17 | agent | Three route modes, default preferred: `shortest` (length only), `efficient` (walking time, with the walk profile's costs for stairs, ladders, doors and water), `preferred` (efficient with the weights). Without weights preferred equals efficient (alternatives in 2.1). |
| O15 | 2026-11-17 | agent | Rewind by splitting the route's progress (never decreases, for ETA and maneuvers) from the player's cursor (follows the player forwards and backwards) (alternatives in 2.1). |
| O16 | 2026-11-17 | developer | Question 15.9: the developer cannot recall the details of the earlier plaza rounding attempt. Record it as a risk (§ 12.5) and design § 8 on the evidence of the NPC plaza line (M5); phase 7 starts with a short check on two real plazas before the full build. |
| O17 | 2026-11-17 | agent | Walk links (§ 5.2) are a separate edge kind with their own id space, disjoint from road edges, cut pieces (2 000 000 000 upward) and the router's negative virtual nodes; a test asserts it (alternatives in 2.1). |
| O18 | 2026-11-17 | agent | Walk links and clusters are invalidated by a new block-change hook (a `TerrainChangeListener` port in core, a Paper listener for block changes in loaded chunks, batched per chunk), not by the road dirty tracker, which sees road blocks only; until it fires, entries also expire after a TTL (alternatives in 2.1). |
| O19 | 2026-11-17 | agent | Plaza lines (§ 8) apply at plazas only, with the NPC rule: a designed plaza (`PlazaRadius`) or a junction whose open radius exceeds `corridor-half-width`. Street T and L junctions get no plaza line; their corners are rounded by the road trail as today (alternatives in 2.1). |
| O20 | 2026-11-17 | agent | Walk trails keep the binding look of the navigation DESIGN (sparser than the road trail, leg colour): `trail-leg-spacing` default 3.0, now on fixed anchors (§ 7.2) (alternatives in 2.1). |
| O21 | 2026-11-17 | agent | No chunk loading for walk legs in v1: LAST_MILE decision 6 stays as it is (explained to the developer 2026-10-02, not a veto); legs plan to the edge of the loaded terrain and continue as the player moves, as Baritone does (alternatives in 2.1). |
| O22 | 2026-11-17 | agent | The POI phase is split in two sub-issues: 5.1 the POI entity (API, web app, plugin, destination) and 5.2 POI preference weights in the walk search, which depends on the route modes of phase 4 (alternatives in 2.1). |

### 2.1 Agent decisions: alternatives

1. **O11 Where the shaping code lives.** Chosen: move the shaping classes and the world primitives they read to a neutral package `core/navigation/shape/` (the NPC code imports from there), because the player trail needs exactly its clearance map, string pulling and plaza line, and the NPC package name would mislead. The code check of § 3.4 showed that moving the `corridor` package alone is not enough: it imports `NavWorld`, `NavPoint`, `NavGeometry`, `RoadPlanner.PlazaCrossing` (and `LocalLegSearch` also `HopPlanner` and `LocalLeg`) from `core/npc/nav`, so the primitives move with it, `PlazaCrossing` becomes a top-level record, `HopPlanner`'s floor helpers (`floor`, `feet`, `floorNear`, `CONTINUITY_RANGE`) move into `NavGeometry`, and `LocalLegSearch` (NPC legs, main thread, 2 048 cells) stays in `core/npc/nav/corridor/`. A compile-and-test check of the move passed (§ 3.4.3).
    1. (a) Copy the classes for the player trail: two copies drift apart, and every fix to corners would be made twice.
    2. (b) Let the player trail import `core/npc/nav/corridor/` as it is: works, but makes the player feature depend on the NPC package, which is off by default and Citizens-oriented.
    3. (c) Write a new shaper for walk paths only: duplicates tested code (`CorridorTest`, `PlazaLineTest`, `CorridorShaperTest`).
    4. (d) Move only the `corridor` package and leave the primitives in `core/npc/nav`: a smaller diff (about 15 files), but the shared package would still import the NPC package, the dependency (b) was meant to avoid.
2. **O12 Mixed routes.** Chosen: keep the road A* as the planner and give it extra edges the routing view creates lazily, "walk links" between road nodes (and POI nodes) that lie within a walking distance of each other and whose road distance is much longer than the straight distance. A walk link's cost comes from a bounded walk search, cached, invalidated by the dirty tracker. Start and goal legs stay as today (walk path to the road, walk path from the road end), generalised to many candidate join points.
    1. (a) One big search over road cells and walk cells together: exact, but it loads every road cell near the route into the walk grid and breaks the "road graph is cheap" property.
    2. (b) A second planner for off-road, with the road planner calling it at the ends only (today's state): cannot produce road, off-road, road shortcuts in the middle of a route, which is what O01 asks for.
    3. (c) Add the shortcuts to the stored graph as recorded edges by hand: curation burden the design avoids (decision O05 has the same reasoning).
3. **O13 Long walks.** Chosen: HPA*-style lazy clusters now (§ 5.3), persisted tiles later (§ 5.5), see the matrix in § 5.6.
4. **O14 Route modes.** Chosen: three modes, default preferred.
    1. (a) Only shortest and preferred: loses the case "fastest" where a spiral stair is shorter than a long ramp but slower to walk; the walk profile already prices stairs, ladders and doors (`drop-penalty`, `climb-allowance`, door cost).
    2. (b) A slider of weights per player: a menu and a rule set for something players do not ask for.
5. **O15 Rewind.** Chosen: separate progress from cursor.
    1. (a) Raise the session parameter `offRouteLookBackBlocks` to a large value: the projection then jumps to the wrong branch on a route that passes the same place twice (a loop, a switchback).
    2. (b) Recompute the route when the player walks back: costs a search and flickers, and loses the "same route" property the player has seen.
6. **O17 Walk link ids.** Chosen: a separate edge kind with its own id space, because REV7 § 7.2 leaves no defined room above the cut pieces and the pieces grow upward.
    1. (a) Ids above the cut pieces, as the draft said: about 147 million ids remain under the int maximum and the pieces grow into them, a silent collision risk (REV7 § 2.6).
    2. (b) Negative ids: taken by the router's virtual start and goal nodes.
7. **O18 Invalidation of links and clusters.** Chosen: a new block-change hook with a TTL as a backstop.
    1. (a) Reuse `RoadDirtyTracker`: it sees road materials and road headroom only, so a wall built across a courtyard shortcut or inside a castle would go unseen.
    2. (b) TTL only (as walk capture today, 10 s): simple, but a cached link would have to be rebuilt every few seconds, which removes the point of caching it.
8. **O19 Which junctions get a plaza line.** Chosen: the NPC rule, so NPC and player lines agree (risk 12.6) and the developer's wish ("where a route enters and leaves a plaza") is met.
    1. (a) Every junction, street T and L crossings included: on a 3 wide street the curve has no room, and the road trail already rounds there.
    2. (b) Designed plazas only: misses the automatic plazas the builder collapses (navigation DESIGN § 5.6 step 4).
9. **O20 Walk trail spacing.** Chosen: keep 3.0 and the leg colour, fix the snapping by anchoring (§ 7.2). The snapping comes from the window starting at the projection, not from the spacing.
    1. (a) 1.5 like the road trail, as the draft said: changes a Decided look (navigation DESIGN, LAST_MILE "no new visual state in v1") without the developer.
10. **O21 Chunk loading.** Chosen: none in v1.
    1. (a) Load chunks in the background for a long leg, as live-tag cross-sections do: loads terrain for one player's guidance, a server cost the measurements of phase 0 do not cover yet; reconsider with phase 8.
11. **O22 POI phase split.** Chosen: two sub-issues, so the entity can ship without waiting for the route modes.
    1. (a) One POI phase that waits for phase 4: delays POI destinations, which need no weights.
    2. (b) Weights inside phase 4: phase 4 would then need the POI entity, a dependency in the wrong direction.

## 3. Current state and legacy behaviour

1. **Built today (V3, knk-plugin `next` `e69dba6`):**
    1. Road graph, router, routing view, `/navigate`, compass: see [navigation DESIGN](../navigation/DESIGN.md). Router: A* with class and edge cost, per-player `AccessPolicy`; edges cut at gate doors and region borders (rev. 7 Part A).
    2. Walk search `core/roads/walk/WalkSearch` (bounded A*, packed `long` keys, `MovementProfile`, `CellAccess`): stairs, slabs, 2 to 3 block drops at +10 per block, ladders, doors and gates by interaction rights, water at x3, `wall-cost` 1.0 for a cell beside a wall (checked: `besideWall` adds it when any of the eight neighbours is solid and not passable at any height from 1 to the headroom; a step cost on whole cells, no distance). Config `navigation.walk.*`: `max-expansions` 20000, `max-length` 144, `max-length-factor` 1.75, `detour-allowance` 48, `climb-allowance` 5, `capture-margin` 16, `chunk-ttl-seconds` 10, `recompute-distance` 6, `max-concurrent-searches` 2. Capture of loaded chunks only (`WalkSnapshotService`); at most 64 chunks per request.
    3. Where walk paths are used: direct mode (target within 48 blocks), the leg from the player to the road (start up to 96 blocks from a road), the last leg from the road's end to the destination (destination up to 256 blocks from a road, walk path within 96, the HUD arrow beyond). They are separate legs at the two ends of a route. There is no walk leg in the middle of a route and no route without a road when the distance exceeds 144 blocks.
    4. Trail drawing `paper/navigation/TrailRenderer` (checked): road trail every `SPACING` 1.5 blocks, centred across the road (`centredWindow`, `TrailCentring`, KNG-76, KNG-110); walk legs: `drawPath` takes `pathWindow(points, feet, length, LEG_SPACING)`, which starts at the player's projection onto the path (`project`) and places a point every `LEG_SPACING` 3.0 blocks from there, straight segments between block centres, no smoothing, no anchoring. Straight legs (`drawLeg`) use the same 3.0 spacing; `drawRoute` adds a straight leg from the player to the trail's first point when it is more than `LEG_MIN` 2.0 blocks away (or the walk leg to the road instead, KNG-75). The window is redrawn every `trail-period-ticks` (10 ticks), over `trail-length` 30 blocks.
    5. Session `core/navigation/NavigationSession.tick` (checked): projects with `route.project(x, floorY, z, along - offRouteLookBackBlocks)` and then keeps `along = max(along, projection.along())`; the road trail, the HUD distance, the percentage and the next maneuver are all drawn from `along`. Walk legs, in `paper/navigation/NavigationService`: `DirectLeg.best` is the least remaining distance seen; `recheckDirect` treats `remaining > best + reroute-distance` as "heading away" and recomputes towards a target re-derived from the player's position (at most once per `reroute-min-interval`). The walk leg to the road (start leg) needs both measures: farther along the leg **and** farther from the route than its closest approach (N16, live test S3), and is dropped when the player comes within `reroute-distance` of the route.
    6. NPC movement quality (merged into `next` 2026-11-16, behind off-by-default keys, not yet live tested: #621 to #627 open): `corridor/Corridor` (clearance map; `Corridor.build` reads the live world through `NavWorld`), `CorridorShaper` (wall clearance 0.8, hard minimum 0.35, string pulling), `FreeWidth`, `PlazaLine` (bounded A* on a plaza's footprint, string pulling, tangent bends; on the test plaza +11 % over the chord and +4 % over the shortest line that keeps 0.8 from the well, against +40 % over the chord before), `LocalLegSearch` (main thread, at most 2 048 cells). A junction whose open radius (the 4th shortest of 16 rays) is no more than `corridor-half-width` counts as a street junction and gets no plaza line. Architecture [§ 12](../../architecture/npc-navigation.md#12-movement-quality-phase-4c-links-m1m7). The road graph and the players' trail are untouched by it ("`TrailCentring` is applied to the player trail only").
2. **V1/V2:** the legacy plugins had no navigation (the V1 tutorial joked that it did not exist). Nothing to keep or drop. The legacy `Location` and WorldGuard region use is kept as is.
3. **Related open work:** #603 and its links M1–M7 (merged into `next`), #625 plaza lines for NPCs (merged into `next`), #110 (KNG-93) entrances and the `entrance` mode (not built), #25 (KNG-235) the destination engine (proposed), REV6 Part A areas-first (not built). LAST_MILE kept chained walk legs in the middle of a route "only on request"; decision O01 is that request. The developer's earlier attempt at rounding a plaza route from edge to edge is not documented and the developer cannot recall its details (O16); see risk 12.5.
4. **Code check of the shared shaping package (O11), 2026-11-17, knk-plugin `next` `e69dba6`:**
    1. `core/npc/nav/corridor/` holds `Corridor` (486 lines), `CorridorShaper` (910), `FreeWidth` (119), `PlazaLine` (416), `LocalLegSearch` (460). Imports from `core/npc/nav`: `NavWorld`, `NavPoint`, `NavGeometry` (all five), `RoadPlanner.PlazaCrossing` (`CorridorShaper`), `HopPlanner` and `LocalLeg` (`LocalLegSearch`). `NavGeometry` itself calls `HopPlanner.floorNear` and `CONTINUITY_RANGE`. Importers of the package: `NpcNavigationService`, `RouteFollower`, `NavGroup`, `CrowdControl`, paper `NpcNavRunner`, the scenario `NpcMovementReport`, and seven test classes. `NavWorld` is implemented by `BukkitNavWorld` (paper, live world) and five test worlds; `NavPoint` and friends are used in about 80 files.
    2. The player trail's walk paths come from `core/roads/walk/WalkSearch` over captured `WalkCells`, off the main thread. To shape them off the main thread the player side needs a `NavWorld` over the captured walk terrain (`WalkTerrainNavWorld`, Bukkit-free), not `BukkitNavWorld`.
    3. Throwaway check (a scratch worktree, not committed): `Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine`, `NavWorld`, `NavPoint`, `NavGeometry` and an extracted `PlazaCrossing` moved to `core/navigation/shape/`, imports rewritten (120 files, 11 renames). `./gradlew :knk-core:test :knk-paper:test` passed: knk-core 3 011 tests, knk-paper 2 891 tests (18 skipped), no failures. Two leftovers for phase 1: `NavGeometry` still imported `HopPlanner` (its floor helpers move into `NavGeometry`), and the package-private test world `GridWorld` was needed in both test packages (it becomes a shared test fixture). The paper-boot scenarios were not run; phase 1 runs them.
5. **Corrections to the first draft from the sources (2026-11-17):**
    1. The road dirty tracker does not see general block changes: `RoadDirtyTracker` reacts only to blocks that touch a road-profile material or a road span's headroom, batched every 30 s, by tile (navigation DESIGN § 6). Walk capture relies on its 10 s chunk TTL; dirty-tracker invalidation was "a possible later optimisation, not v1" (LAST_MILE). Walk links and clusters therefore need a new block-change hook (§ 5.2.3, § 5.3.5, § 11).
    2. Virtual edge ids: REV7 § 7.2 puts split nodes and cut pieces at 2 000 000 000 upward and the router's virtual nodes below zero, so "above the cut pieces" leaves no defined room. Walk links get their own disjoint id space, asserted in tests (§ 5.2.3).
    3. The plaza collapse rule is navigation DESIGN § 5.6 step 4, not REV6 § 1.
    4. `entrance` is not a `/navigate` mode today (only `spawn` and `region`); it comes with #110 (§ 4.4).
    5. The road router's "under 5 ms" is a target of the navigation DESIGN, not a measurement (§ 9.1).
    6. The navigation DESIGN wants off-road legs "sparser and in another colour" and LAST_MILE "no new visual state in v1"; the draft's walk spacing of 1.5 contradicted that (§ 7.2.2, O20).
    7. The HPA* figure "within 1 %, up to 10 times faster" is for the variant that precomputes the entrance costs (Botea 2004), not for a lazy one (§ 5.6).

## 4. Player and admin experience

1. **Player, indoors:** the player stands in a castle hall and types `/navigate throne room` (a POI name). The trail leads along the corridors on the shortest sensible walk; at stairs it leads up the stair, and it keeps a block or more from the inner wall of a spiral stair. If the player walks back down a few steps, the trail is drawn again from where the player stands, not from the highest point reached.
2. **Player, mixed:** from a field the trail leads over a walk path to the road, along the road, takes a shortcut across a courtyard where that is much shorter than the road around it, joins the road again, and ends with a walk path into the building to the POI. The player sees one trail; the HUD says the same as today.
3. **Player, wilderness:** a destination 300 blocks from the road over open country: the trail follows a smooth line over walkable ground around lakes and cliffs. Where the terrain between is not loaded the HUD arrow guides until the leg comes within range (as today beyond 96 blocks), see § 5.5.
4. **Command:** `/navigate <destination> [shortest|efficient|preferred] [spawn|region]` (alias `/nav`; `entrance` joins the trailing words with #110). The mode word is optional; the default is `preferred` (question 15.4). The trailing `spawn`/`region` stays last, so the compass's general targets (`/navigate` arguments with a trailing `spawn`/`region`, compass DESIGN) keep working. Tab completion offers POIs the player may navigate to (§ 6.5).
5. **Admin, POI:** in game `/knk poi create <name> [region <id> | radius <n>]` at the position the admin stands on, `/knk poi list|show|move|delete|link <domain>|unlink`. In the web app a POI page and a POI list on the domain form (§ 6.4). A recognised plaza is offered as a suggestion only in the later plaza extension (§ 10.1).
6. **Admin, preference:** a POI that has an extent can carry a `preference` weight (for example 0.8 for the great hall, 2.0 for the servants' corridor). Routes prefer low weights. The existing road edge `cost` stays the road's equivalent (`/knk road edge set <id> cost <x>`).
7. **Admin, tuning of the trail:** config keys of § 7.6.

## 5. Routing rules

### 5.1 Legs and the route

1. A route is an ordered list of legs. A leg is `Road` (a polyline on the road graph, as today), `Walk` (a walk path on captured terrain), or `Straight` (the fallback hint, only where today's rules allow it). The trail, the HUD and the session work on the list; today's route has the shape Walk (optional), Road, Walk (optional), generalised to any sequence.
2. The progress of a session is measured over the whole list: `progress` is total length covered; `cursor` is the player's current position on the list (§ 7.5).
3. Every walk leg keeps today's rules unchanged: loaded chunks only, `CellAccess` for gates, doors and regions, `No conventional path to X found.` when a search ran and found nothing (decision of 2026-10-08, rev. 9), the partial path rule.

### 5.2 Walk links in the middle of a route (O12)

1. **Candidates.** For every pair of road nodes (including POI nodes of § 6.2 when they lie on the road) within `walk-link-range` (default 40 blocks, straight line) whose road distance is more than `walk-link-ratio` (default 2.0) times the straight distance, the planner may ask the walk search for a link. The pair list per tile is computed from the stored graph once and cached.
2. **Lazy.** A link is searched only when the road A* reaches one of its ends and the link could improve the route (its straight-line bound beats the road distance). One request per candidate, off the main thread, within the global limit `max-concurrent-searches`.
3. **Cached.** A found link is stored as a walk-link edge (its own edge kind and id space, O17) with its walk path, its cost, and the gate and region tags a road edge has. It is dropped when the block-change hook (O18) reports a change in a chunk of the link's box, on a gate or region change as for road edges, and after `walk-link-ttl-seconds` (default 600) as a backstop. A search that found no path is cached as "none" for `walk-link-retry-seconds` (default 600).
4. **Access.** A link is checked by the player's `CellAccess` like a walk leg, and by the per-player `AccessPolicy` for its tags, so a link through a region the player may not enter is not offered.
5. **Never mandatory.** A road without links behaves as today. Links only add choices.

### 5.3 Long walks and indoor routes (O01, O13)

1. **When.** A walk leg longer than the single search's budget (`max-length` 144, 20 000 expansions) or a route with no road within reach (inside a castle) uses the hierarchical search. Short legs keep the plain bounded A*.
2. **Clusters.** Loaded chunks are cut into clusters of one chunk column by level (a level is a connected stack of walk cells, the span idea of the road builder). A cluster's entrances are its walk cells on the border to a neighbour cluster, grouped into at most `cluster-entrances` (default 6) entrance points per border segment.
3. **Abstract graph.** Nodes are entrance points. Edges inside a cluster get their cost from the bounded walk search between the two entrances, computed when the abstract search first asks for them and cached with the cluster. Edges between clusters cost one step. POI nodes (§ 6.2) join the abstract graph as nodes of the cluster they stand in.
4. **Search.** A* on the abstract graph from the cluster of the start to the cluster of the goal, then a refinement: the plain walk search along the winning chain of clusters only (the corridor), which gives the exact path. The expansion budget applies to the refinement, per cluster.
5. **Invalidation.** A cluster is dropped when the block-change hook (O18) reports a change in its chunk, or when its chunk unloads. The road dirty tracker does not see these changes (§ 3.5.1).
6. **Limits.** Only loaded chunks take part, as today (LAST_MILE decision 6, no chunk loading; kept in v1 by O21). A route whose clusters are not all loaded is planned over the loaded part and the remainder is guided by the HUD arrow, as today beyond the walk range.

### 5.4 Route modes and preference (O02, O14)

1. **Costs.** `shortest`: length only. `efficient`: the walk profile's costs (stairs, ladders, doors, water, drops) and the road class cost. `preferred`: efficient times the preference multipliers below.
2. **Road.** The multipliers are the road's existing `profile.CostMultiplier`, `edge.CostMultiplier` and class cost. They apply in `preferred` only; `efficient` uses the class cost; `shortest` none.
3. **Walk areas.** A POI with an extent and a `preference` weight multiplies the cost of every walk cell inside its extent, in `preferred` mode. The extent is looked up per cell from the POI's region or range (§ 6.2). Overlapping POIs multiply (an upper cap `preference-max` default 4.0 so one bad overlap cannot block a hall).
4. **Heuristic.** The A* heuristic stays admissible: it uses the smallest multiplier in force (never above 1.0 unless all weights are above 1.0).
5. **No weights, no change.** A world without preference POIs behaves like `efficient`.

### 5.5 Wilderness (O03, decision matrix § 5.6)

0. **Practice in other games (research reports of 2026-09-27 and 2026-11-15).** Open-world games use two layers: a road graph for the GPS and a generated navmesh for characters; GPS legs off the road are straight lines. Minecraft bots (Baritone) plan in segments up to the edge of the loaded terrain, off the main thread, with costs in ticks. The road graph already is the coarse layer of an HPA*-style hierarchy, so hierarchy pays off only at scale. Smoothing is by line of sight (Theta*, Lazy Theta*) or the funnel algorithm; the simplified funnel can produce illegal paths, so samples are checked against the clearance map (§ 7.1.3). Flow fields fit many units with one goal, not players with their own goals. Clearance is a soft margin plus a hard minimum; hard erosion (Recast style) closes one-block doors. This design follows that: the walk grid and its clusters are the navmesh equivalent, roads stay the GPS layer, and wilderness legs are planned in segments over the loaded terrain.

1. **What differs.** Wilderness legs are long, open and rarely blocked by doors and regions; accuracy to the block matters less than a smooth line and a bounded cost. Indoor legs are short in volume, complex in shape and full of doors and stairs.
2. **Phase W1 (with the hierarchical search).** The hierarchical search of § 5.3 also runs over open terrain. Clusters of open terrain are large and have many entrances; therefore a coarse cluster size of 2 by 2 chunk columns is used when a leg is longer than `coarse-above` (default 160 blocks) and open (`openness` of its straight corridor above a threshold). Line of sight smoothing (§ 7.1) then straightens the path.
3. **Phase W2 (later, separate issue).** Persisted walk tiles built offline like road tiles (`/knk walk build`), storing per 16 by 16 column the walkable surface classes and the cluster graph. They make routes beyond the loaded chunks possible, and they make results reproducible and cheap. They need a schema and an admin tool; decided after the measurements of § 9.2.
4. **Caching of trips.** Results of common trips (spawn to town gates) are cached as virtual edges like walk links (§ 5.2) with the same invalidation. No separate cache design.

### 5.6 Decision matrix: how long off-road legs are planned (O13)

**Status:** Proposed 2026-11-17 — the developer decides (question 15.1).
**Question:** how to plan walk legs of several hundred blocks, indoors and in the open, within a tick budget that has no room for a 20 000 cell search per player.

1. **Options:**
    1. **A. Raise the caps of the existing bounded A*:** `max-length` and `max-expansions` up, chunks up. No new code.
    2. **B. Lazy HPA* over loaded chunks (§ 5.3):** clusters and entrances built on demand, refinement along the corridor. In the spirit of the road graph as the coarse layer (research report § 3.9: HPA* with precomputed entrance costs finds paths within 1 % of optimal, up to 10 times faster; the lazy variant pays for the entrance costs on first use, so its first request in an area is slower).
    3. **C. Persisted walk tiles (§ 5.5 W2):** an offline built navigation structure per tile, queried like the road graph.
    4. **D. POI skeleton only:** POIs as nodes, connected by inferred walk searches between neighbours, nothing else.
2. **Considerations and weights:**
    1. **Latency and tick safety** (25): the search stays off the main thread and within budget on a 400 block route.
    2. **Route quality** (20): short, natural, correct at doors and stairs.
    3. **Works beyond loaded chunks** (10): wilderness trips longer than the view distance.
    4. **Platform independence** (15): how much is Bukkit-free `knk-core` logic and reusable by NPCs and another engine.
    5. **Effort to build and maintain** (15): code, tests, tools.
    6. **Fit with what exists** (15): reuse of `WalkSearch`, dirty tracker, road tile cache.
3. **Matrix** (score 1 to 5; weighted total = sum of score times weight divided by 5):

| Consideration | Weight | A. Raise caps | B. Lazy HPA* | C. Walk tiles | D. POI skeleton |
|---|---|---|---|---|---|
| Latency and tick safety | 25 | 1 | 4 | 5 | 3 |
| Route quality | 20 | 4 | 4 | 4 | 2 |
| Beyond loaded chunks | 10 | 1 | 1 | 5 | 2 |
| Platform independence | 15 | 4 | 4 | 4 | 3 |
| Effort | 15 | 5 | 3 | 1 | 4 |
| Fit with what exists | 15 | 5 | 4 | 2 | 3 |
| **Weighted total** | 100 | **68** | **73** | **70** | **57** |

4. **Pros and cons:**
    1. **A.** Pros: nothing to build. Cons: worst case grows with the area (a 96 by 96 field fully expanded cost 80 to 90 ms; a castle with many levels and 400 blocks is several times more), the captured box grows quadratically (64 chunks about 0.8 MB per request), two concurrent searches would block each other.
    2. **B.** Pros: cost grows with the corridor, not the area; clusters are shared between players and with NPCs; invalidation reuses the dirty tracker. Cons: new structures (clusters, entrances), a cache to bound and invalidate, and the first request of an area pays for the clusters it needs.
    3. **C.** Pros: best latency, works beyond loaded chunks, reproducible. Cons: a schema, a build tool, curation questions (when stale), and it is the most work; the road graph's history (rev. 6 churn) is a warning.
    4. **D.** Pros: tiny. Cons: only as good as the POIs placed; no route without POIs, which contradicts decision O05's "POIs are optional".
5. **Recommendation:** B now, with the cluster structure designed so C can later persist the same clusters (same cluster ids, same entrance rule). The totals are close (B 73, C 70, A 68); the weights are judgement, and the real deciding fact is that C is the only option that reaches beyond loaded chunks. What would change the recommendation: the measurements of § 9.2 showing that A already fits the real castle (then A, and B later), or a requirement for 1000 block wilderness routes (then C earlier). Reversible: B and C share the structure; A stays as the fallback path.

## 6. Points of interest (O04, O05)

### 6.1 Concept

1. A POI is a named place: a `Location` (world, x, y, z, yaw, pitch) with a name, optionally linked to one domain (town, district, structure, gate structure, any domain), optionally with an extent. It is a separate entity so the destination work does not grow.
2. It answers "where is the throne room" for players and the walk planner. It is not a domain: a POI has no region of its own unless given one, no access rules of its own (access follows the domain it is linked to and the region it uses), and no discovery rewards in v1.
3. **Scopes.** POIs follow the destination rules: a POI in another world is not offered in tab completion (destination engine E11), and an exclusive scope such as a siege match hides them (E2).

### 6.2 What a POI gives navigation

1. **Destination.** Navigate to a POI by name: arrival means inside the extent (region or range) if there is one, otherwise within `arrive-distance` of its point. The entrance problem of REV7 Part B gets a second answer: a POI placed at the door is the destination.
2. **Nodes.** POIs join the walk planner as nodes (§ 5.2 candidates, § 5.3 abstract graph). Connections between them are inferred by the walk search, cached, invalidated with the dirty tracker. This is the indoor skeleton the developer asked for, built from names and pins, not from traced corridors.
3. **Weights.** A POI with an extent and `preference` is a weighted area (§ 5.4.3).
4. **Hints for tab completion.** POIs are destinations the destination engine's provider lists (§ 6.5).

### 6.3 Data (additive, no migration risk to existing tables)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `Name` | string (100) | unique per world |
| `LocationId` | int FK to `locations` | the pin; reuses the existing Location entity and its retention rules |
| `DomainId` | int? FK to `domains`, SetNull | optional link to any domain |
| `ExtentKind` | enum `None`, `Region`, `Radius` | |
| `RegionId` | string? | WorldGuard region id, when `ExtentKind` is `Region` |
| `Radius` | double? | blocks, when `ExtentKind` is `Radius` (a cylinder, as the sub-region spec's cylinder shape) |
| `Preference` | double, default 1.0 | cost multiplier of walk cells inside the extent, 0.25 to 4.0 |
| `NavigationEnabled` | bool, default true | a POI can exist without being offered as a destination |
| `Kind` | enum `General` | the only value in v1; the plaza subtype of § 10.1 adds `Plaza` (a discriminator column, so no later migration of this table) |

Room for explicit links later (O05): a table `poi_links (FromPoiId, ToPoiId, Weight, OneWay, Blocked, Note)` is not created now and the planner reads connections through one interface (`PoiConnections`), so adding stored links later changes the interface's implementation only, not the planner and not this table.

### 6.4 API and web app

1. `GET api/pois?world=` (anonymous read, like road network reads), `GET api/pois/{id}`, writes `POST/PUT/DELETE api/pois[/{id}]` with the default-deny access rule and the pinned access tests (`knk.admin.poi` for staff and the plugin key), `POST api/pois/search` for the catalogue (a name, a domain, a world), DTOs with navigation DTOs, AutoMapper profile.
2. The plugin catalogue loads POIs with the domain places (the destination engine's snapshot is the persisted copy, § 6.5).
3. Web app: a POI list and form through the FormWizard defaults (entities with API metadata become eligible automatically; only a default seed is needed), and a POI list on the domain pages.

### 6.5 Plugin

1. `knk-core`: `Poi`, `PoiExtent` (region or cylinder, Bukkit-free: `RegionShape` already exists for region goals), `PoiConnections` (inferred in v1), `PoiProvider` for the destination engine (candidate key `poi:<id>`, label, detail "in <domain>").
2. `knk-paper`: `/knk poi …` command (the `knk-plugin-command` skill's pattern), the WorldGuard region lookup for extents, the POI layer in tab completion.
3. Until the destination engine of KNG-235 is built, POIs register in today's `NavigationDestinations` catalogue as a target type `poi:`.

## 7. Guidance quality (O07, O08)

### 7.1 Wide, smooth corners on walk trails

1. **Cause (checked in the code).** `WalkSearch` adds a flat `wall-cost` (1.0) to a cell with a wall in any of its eight neighbours; it works on whole cells and has no notion of distance. The path is the cell list; `drawPath` draws straight segments between block centres every 3.0 blocks. The smoothing that centres a road trail (`TrailCentring`) applies to road trails only. On a spiral stair the cells nearest the newel are cheap enough for the search and the straight segments cut the inner corner.
2. **Rule.** After the search, a walk path is shaped by the shared shaping module (O11): the clearance map of the path's strip (`Corridor`), `CorridorShaper` pulling points to the place nearest the line that keeps `wall-clearance` (default 0.8, hard minimum 0.35), then string pulling by line of sight. Where a flight of stairs is narrower than twice the clearance, the point goes to the most clearance the stair allows (as the NPC shaper does).
3. **Curve.** The shaped polyline is drawn with a Catmull-Rom or Chaikin pass (a few subdivisions) whose samples are validated against the clearance map; a sample that would violate the hard minimum is moved back to the polyline. A spiral stair then reads as a spiral, not as a polygon.
4. **Search side.** `wall-cost` becomes a clearance cost: cost per block of clearance lacking to `wall-clearance`, from the same distance transform, as `LocalLegSearch` does for NPCs (5 per block there). This changes which cells the search picks, so it needs the plain-A* tests to be re-baselined; config key `navigation.walk.clearance-cost` (default 5; 0 keeps today's `wall-cost` behaviour exactly, the kill switch).
5. **Cost.** One shaping per walk path on the routing thread, strip of 8 blocks half width (the NPC default `corridor-half-width` is 4): at most a few thousand cells, same order as the search. Measured in phase 0.

### 7.2 Particles that do not snap

1. **Cause (checked in the code).** `drawPath` takes the window from the player's projection onto the path (`pathWindow`) and places particles at `start + k * spacing`, every `trail-period-ticks` (10 ticks). The particle positions therefore move with the player's projection: at a corner the projection can jump onto the other side of a wall, and particles slide along the path with every redraw. The road trail has fixed spots every 1.5 blocks (KNG-76) for exactly this reason; the walk trail does not. The figure of "every four blocks" in the developer's observation does not appear in the code: walk legs use 3.0 blocks and a 6 block recompute distance; the likely source is that spacing.
2. **Rule.** Walk trails use fixed anchoring like road trails: anchors at multiples of the spacing from the path's start, the window is the anchors at or after the cursor and within `trail-length`. The spacing of a walk trail becomes a config key `navigation.trail-leg-spacing` with today's 3.0 as default, and the leg colour stays (O20: the navigation DESIGN wants off-road legs sparser and in another colour).
3. **Cursor projection.** The cursor is projected with continuity (§ 7.5): a jump of more than 3 blocks along the path in one redraw is ignored unless the player really is nearer to it, so a player standing at a wall's other side does not make the trail jump.

### 7.3 Redraw cadence

1. The redraw period stays `trail-period-ticks`. The shaped path is computed once per path; the window is cheap. No change expected to server cost; measured in phase 0.

### 7.4 Plaza lines

See § 8: a separate issue that depends on § 7.1 (the shared shaping module and curve drawing).

### 7.5 Winding back (O08, O15)

1. **Cause (checked in the code).** For a road route `NavigationSession.tick` keeps `along = max(along, projection.along)` and projects with a look-back of the session parameter `offRouteLookBackBlocks`; the trail is drawn from `along`. A player who walks back is therefore guided as if still at the far point, and `drawRoute` draws a leg from the player to that point (when more than `LEG_MIN` away). For a walk leg `DirectLeg.best` (the least remaining distance seen) makes the leg treat walking back as "heading away" and recompute towards where the player used to be.
2. **Rule.** The session keeps two numbers: `progress` (monotone, used for ETA, the HUD's percentage and maneuver announcements already passed) and `cursor` (the player's current place on the route list, forwards or backwards). The trail, the HUD distance and the maneuver ahead are drawn from `cursor`. The cursor is the projection of the player onto the route's legs near the previous cursor: all candidates within `reroute-distance` of the player, the one with the smallest change from the previous cursor wins (continuity), and when none is within `reroute-distance` the player is off route.
3. **Walk back on a road.** The player is on the road again within `reroute-distance`: the cursor moves back, the road trail is drawn from it, no walk leg.
4. **Off the road.** The player leaves the road: a walk leg to the nearest join point, chosen by remaining cost (walk distance plus remaining route length), not by distance only, so a player who walked a short way backwards past a better join point is guided to the better one in either direction.
5. **Walk legs.** `best` and "heading away" are replaced by the player's distance to the leg's path polyline: within `recompute-distance` the leg stays and the window is drawn from the cursor on it; beyond it the leg is recomputed from the player's position (at most once per `reroute-min-interval`, as today).
6. **Loops.** A route passing the same place twice (a loop, a switchback) keeps its cursor by continuity (a candidate more than `cursor-jump` blocks away along the route, default 12, is taken only when the previous cursor candidate is farther than `reroute-distance`).
7. **Rules kept and replaced.** Kept: the near-road check-only leg (KNG-124), "Having trouble determining the route…" for a search over budget on the way to the road (N17), "No conventional path to X found." (rev. 9) and the partial path rule. Replaced under `guidance-v2` only: the two-measure "heading away" of the start leg (N16) and `DirectLeg.best`, by the distance to the leg's path (item 5). With `guidance-v2: false` both stay as today.
8. **NPCs.** The NPC navigation service follows its own route and is unchanged.

### 7.6 Configuration

New keys under `navigation`: `walk.clearance-cost` (5), `walk.wall-clearance` (0.8), `walk.curve` (true), `trail-leg-spacing` (1.5), `cursor-jump` (12). Feature flag for the whole improvement pass: `navigation.guidance-v2` (default false until live tested; false reproduces today's trail exactly, transcript test as for `walk.enabled: false`).

## 8. Plaza lines for the players' trail (separate issue; O09)

**Why a separate issue.** It touches the router's output and the trail, it depends on § 7.1 (shared shaping, curve drawing, clearance map), and the developer named an earlier attempt that did not work out. It can ship after § 7 without changing the rest.

1. **Problem.** The builder collapses a plaza into one junction (navigation DESIGN § 5.6 step 4, plan 4c.1 item 6). Plaza lines apply at plazas only (O19). A route that enters a plaza on road A and leaves on road B is a polyline through the node: a sharp bend at the plaza's centre or at the node of a T crossing.
2. **Where it runs.** The road plan already names every plaza crossing of a route (`RoadPlanner.PlazaCrossing`, `NavigationService.plazaCrossingsOf`: a designed plaza's centre with its `PlazaRadius`, other junctions measured with 16 rays). The players' trail uses the same list. The route graph, the router's result, the HUD length and the ETA keep using the graph's edges; only the drawn polyline and the cursor's projection use the shaped line (a plaza line is a replacement for the stretch inside the footprint).
3. **The line (pulled curve).** From where the route enters the footprint (entry point P0 with tangent t0 along road A) to where it leaves (exit point P1 with tangent t1 along road B), a cubic Hermite or Bezier curve with the plaza node N as an attractor: the control points are P0 + a·t0 and P1 − a·t1 with a = `length(P0,P1) / 3`, then the curve's midpoint is pulled towards N by `pull` times the distance from the chord's midpoint to N (default `plaza-pull` 0.35; 0 = the chord with rounded ends, 1 = the curve passes through N). A plaza with three roads (T shape) and a route from the stem to the right arm therefore bends gently towards the node and does not run to the corner of the square, nor to the node and back.
4. **Validation.** The curve is sampled every 0.5 block against the clearance map of the plaza footprint (`Corridor.build(..., discs)` as M5 does). A sample under the hard minimum clearance, in a region the player may not enter, or without floor continuity rejects the curve; then the existing `PlazaLine` result (bounded A* on the footprint, string pulled, bends at tangent points) is used with the curve as the guide: its A* cost adds a penalty for distance from the curve (`plaza-guide-cost`, default 2 per block). When that finds nothing the unshaped route polyline stays (today's behaviour).
5. **Shape knowledge.** The footprint is the designed `PlazaRadius` where set; otherwise the measured open radius (NPC side already does this). With a plaza POI (§ 10.1) the footprint is the POI's WorldGuard region, which gives odd-shaped squares exactly.
6. **Cost.** At most one A* of 4 096 cells per plaza crossing per route computation, cached per (plaza, entry, exit) for the route's life.
7. **Config:** `navigation.plaza-lines` (false until live tested), `plaza-pull` (0.35), `plaza-guide-cost` (2), `plaza-corridor-blocks` (shared with the NPC key, 16).
8. **Tests.** The synthetic plaza scene of the NPC scenarios (15 by 15, four 3 wide roads, a 2 by 2 well on the west to north chord), extended with a plaza with three roads (T shape), a plaza with two roads at a right angle (L shape), a plaza with a stall on the curve, and a street T junction that must get no plaza line (O19).
9. **First step: a check on real plazas (O16).** Because the earlier attempt is not documented, the phase starts by running the curve and the A* fallback on two real plazas (Cinix and Brink, from a snapshot as the NPC scenarios do) and showing the developer the lines before the trail uses them.

## 9. Performance

### 9.1 Numbers known today (from the docs of the merged work)

| Measure | Value | Source |
|---|---|---|
| Straight 95 block walk search | about 3 to 5 ms | LAST_MILE Phase A status |
| 96 by 96 open field fully expanded | 80 to 90 ms (default budget: about 75 ms) | LAST_MILE Phase A status |
| Walk searches in live tests | 2 to 140 ms, off the main thread | KNG-75 step 2a report |
| Chunk capture | 0.4 to 0.7 ms per chunk (synthetic), about 12 KB per chunk | LAST_MILE Phase B status |
| Chunks per request | up to 64 (15 % of 96 block legs need 50 to 64) | KNG-75 step 2a report |
| Budgets today | 20 000 expansions, 144 blocks, 2 concurrent searches | `config.yml` |
| Road router | target under 5 ms for a few thousand nodes (a target, not a measurement) | DESIGN § 6.2 |

### 9.2 Phase 0: measure before building (O06)

1. A measurement issue and branch (no behaviour change) that adds timing and counters to the plugin and runs them on the dev world: the walk search and capture per request (expansions, cells, µs), `/knk road status` already shows capture µs per chunk.
2. Scenes: a large indoor build (the keep with the stair house and the spiral stair), the longest corridor route in it, the courtyard shortcut of § 5.2, an open-country leg of 200 and of 400 blocks.
3. Output: a dated report `docs/reports/<date>-offroad-navigation-measurements.md` with the table of § 9.1 filled with live values and the three decisions it informs: whether option A of § 5.6 already fits (then B moves later), the cluster size, the budgets of § 9.3.

### 9.3 Proposed budgets (to be set from § 9.2; defaults for review)

1. **Main thread:** capture within the existing `TickBudget`; navigation work per player per tick unchanged; the trail shaping and curve run off the main thread.
2. **Search latency (off-thread):** plain walk search at most 150 ms at the 95th percentile for 144 blocks; hierarchical search at most 400 ms at the 95th percentile for 400 blocks indoors; a request over budget returns a partial path as today.
3. **Memory:** clusters cached for at most `cluster-cache-chunks` (default 1024 chunks, about 12 MB at 12 KB per chunk) with least recently used eviction.
4. **Concurrency:** `max-concurrent-searches` stays 2 until measured; link searches (§ 5.2) share the same pool and are dropped first under load.
5. **Counters:** `/knk road status` shows searches, expansions, cache hits, links found and dropped, shaping time.

## 10. Planned extensions (not for this run)

### 10.1 Plaza as a child of POI (O10)

1. A plaza is a POI of `Kind = Plaza`, the way a gate is a structure subtype; it keeps all POI fields and adds plaza fields (area effects, features) in later work.
2. The builder keeps recognising plazas automatically. Each detection becomes a suggestion in the same review flow that curated tiles use ("the road graph recognised a plaza at x y z; create a plaza POI?"). Accepting creates the POI, links the road node (`road_nodes.PlazaPoiId`, nullable, at most one plaza POI per node) and optionally attaches a WorldGuard region for the exact shape.
3. A linked plaza POI gives § 8 its footprint. Deleting the POI sets the node back to its designed or automatic plaza behaviour (`SetNull`), so nothing breaks.
4. Area effects and plaza features attach to the plaza entity, not to the road graph; the graph builder stays free of gameplay.
5. Domain discovery (`UserDomainDiscovery`) could later reward entering a plaza POI; that is a separate decision.
6. The link column must be reconciled with REV6 Part A, which proposes a nullable `road_nodes.PlazaRegionId` for designed areas (not built): one column that points to the plaza POI (which holds the region) is the likely answer, decided with the extension.

### 10.2 Explicit POI links (O05)

1. Stored links only for what blocks cannot express (a secret passage, a ladder shortcut), preferences (a route through the great hall), and forbidden pairs. Same pattern as recorded versus detected road edges. See § 6.3 for the seam.

### 10.3 Persisted walk tiles (§ 5.5 W2)

1. Separate issue after the measurements.

## 11. Platform-specific parts

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| Terrain capture for the walk grid | Paper chunk snapshots | `knk-paper` `navigation/walk/WalkSnapshotService`, `WalkChunkExtractor` | `WalkTerrain`, `WalkCells` (exist) |
| POI extents from WorldGuard regions | WorldGuard region lookup | `knk-paper` `WorldGuardRegionShapes` (exists) | `RegionShape` (exists), `PoiExtent` (new) |
| Trail particles and the HUD | Paper particles and boss bar | `knk-paper` `TrailRenderer`, `NavigationHud` | none: no game logic, the shaped polyline is computed in core |
| Block changes for link and cluster invalidation (O18) | Bukkit block events | `knk-paper` a new walk-terrain listener beside `RoadDirtyTracker` (which sees road blocks only) | a small `TerrainChangeListener` port in core (new) |
| Terrain reads for shaping walk paths off the main thread | captured chunk data | none at runtime: `WalkSnapshotService` captures, the adapter reads the capture | `NavWorld` (moved to `core/navigation/shape/`), `WalkTerrainNavWorld` over `WalkCells` (new, Bukkit-free) |
| Walk legs, links, clusters, route modes, cursor, shaping, plaza curve | pure game logic | `knk-core` `roads/walk/`, `roads/route/`, `navigation/`, `navigation/shape/` | the logic itself |
| POI command | Bukkit commands | `knk-paper` `/knk poi` | `PoiQueryApi` port (new) |

Everything that decides a route, a cost or a curve stays in Bukkit-free `knk-core`, so a move to another engine replaces the capture and rendering adapters only.

## 12. Risks and integration checks

1. **Cluster cache size and invalidation** can grow with active players; the budget of § 9.3 and the eviction are the guard; phase 0 measures the real cost of a cluster.
2. **Changing which cells the walk search picks** (clearance cost, § 7.1.4) can change routes players know; the kill switch and the A/B transcript tests of the existing walk scenarios guard it.
3. **Walk links** can add routes through places not meant as roads (across a farm field); the `walk-link-range` and `ratio` limits, the access policy and per-POI or per-domain exclusion (a `Blocked` flag on a domain's road access rule, reusing REV7 Part C's "Ignored/Applies") are the guards.
4. **Cursor continuity** (§ 7.5) on loops and switchbacks needs the tests listed in § 13 (loop route, switchback, a player who stands between two branches).
5. **The earlier plaza rounding attempt** is not described in the docs, and the developer cannot recall its details (O16, 2026-11-17). § 8 may repeat a failure nobody wrote down. Guards: phase 7 starts with a check on two real plazas shown to the developer (§ 8.9), the A* fallback on the footprint, and the flag `plaza-lines` off by default. The available evidence that a footprint search works is the NPC plaza line (on the test plaza +40 % over the chord before, +11 % after; plan 4c.3 decision 6), which is not live tested yet.
10. **The NPC movement quality code is not live tested** (#621 to #627 open). Phase 1 moves it and phases 6 and 7 build on it for players; a live finding on the NPC side may change the shared code. Phase 1 changes no behaviour, and the shared regression test of risk 6 keeps NPC and player lines one code path.
6. **Two shaping paths** (NPC and player) must stay one code path: a regression test runs the same scene through both and compares the line.
7. **Destination engine order.** If KNG-235 is built after this, POIs first register in the old catalogue (§ 6.5.3) and move to a provider later; no data change.
8. **Main-thread safety:** all new searches and the shaping run off the main thread; the new capture work is within `TickBudget`; the scenario with 20 navigating players (as the Citizens stress test guide does for NPCs) is part of phase 4.
9. **Docs and tests triggers** as in `knk-test-writer`: unit tests in core for every rule of § 5, § 7 and § 8; paper tests for the trail anchoring and cursor; plugin scenarios on a Paper server for a spiral stair, a courtyard shortcut and a plaza T crossing.

## 13. Acceptance checklist

| ID | Check | Phase |
|---|---|---|
| A01 | The measurement report exists with live values for the table of § 9.1 and the decisions it informs | 0 |
| A02 | A route from a field over a courtyard shortcut to a building has road and walk legs in the order walk, road, walk, road, walk; the trail follows them | 2 |
| A03 | A walk link is offered only where the road distance is more than `walk-link-ratio` times the straight distance and within `walk-link-range` | 2 |
| A04 | A walk link through a region the player may not enter, or a closed gate, is not offered | 2 |
| A05 | A change to blocks in a link's box drops the link; the next route searches again | 2 |
| A06 | A castle-wide indoor route of at least 250 blocks is found without a road, within the budget of § 9.3 | 3 |
| A07 | The hierarchical path equals the plain A* path in length within 5 percent on the test scenes | 3 |
| A08 | Unloaded chunks are never loaded; a route over a partly loaded area plans the loaded part and the HUD arrow guides the rest | 3 |
| A09 | `shortest`, `efficient` and `preferred` give different routes on a scene with a spiral stair beside a ramp and a road edge with a cost multiplier | 4 |
| A10 | A POI with a `preference` of 2.0 is avoided in `preferred` and ignored in `shortest` | 5.2 |
| A11 | A world without preference POIs gives the same route in `preferred` and `efficient` | 4 |
| A12 | A POI is created, linked to a domain, listed, renamed and deleted from the web app and in game; its reads are anonymous, its writes pinned by the access tests | 5 |
| A13 | Navigating to a POI with a region ends the navigation inside the region; with a radius inside the radius; with neither within `arrive-distance` | 5 |
| A14 | Tab completion lists only POIs the player may navigate to | 5 |
| A15 | On a spiral stair of width 3 the trail keeps at least `wall-clearance` from the inner wall wherever the stair allows it, and never under the hard minimum | 6 |
| A16 | With `guidance-v2: false` the trail is identical to today's (transcript test) | 6 |
| A17 | Walk trail particles sit on fixed anchors: two redraws with the player standing still draw the same positions; a step of the player moves no particle that is ahead | 6 |
| A18 | A player who walks 20 blocks back along a road sees the road trail from their position, with no walk leg | 6 |
| A19 | A player who leaves the road is guided to the join point with the smallest remaining cost, forwards or backwards | 6 |
| A20 | A looped route keeps the cursor on the right branch; a switchback does not jump | 6 |
| A21 | A walk leg is not recomputed while the player is within `recompute-distance` of it, also when walking back | 6 |
| A22 | On a plaza with three roads (T shape) the line from the stem to the right arm is rounded, passes within `plaza-pull` of the node as configured, keeps `wall-clearance` from obstacles and stays inside the footprint; a street T junction gets no plaza line (O19) | 7 |
| A23 | A plaza with an obstacle on the curve gets the A* line, not a line through the obstacle | 7 |
| A24 | `plaza-lines: false` gives today's route polyline | 7 |
| A25 | The route length, ETA and maneuvers are unchanged by plaza lines | 7 |

## 14. Phases

(Filled on approval; the sub-issues are filed with the parent issue. Each phase merges into `next` on its own, behind its flag.)

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 0 | Measurements: timing counters, scenes, report (§ 9.2) | A01 | knk-plugin, knk-workspace | tier:1 | none | to file | none |
| 1 | Shared shaping module: move `core/npc/nav/corridor` to `core/navigation/shape`, no behaviour change (O11) | NPC tests unchanged | knk-plugin | tier:2 | none | to file | none |
| 2 | Walk links in the routing view, mixed routes (§ 5.1, § 5.2) | A02–A05 | knk-plugin | tier:3 | `navigation.walk-links` (off) | to file | 0 |
| 3 | Hierarchical walk search, indoor routes, wilderness W1 (§ 5.3, § 5.5) | A06–A08 | knk-plugin | tier:3 | `navigation.walk.hierarchical` (off) | to file | 0, 1 |
| 4 | Route modes and road weights (§ 5.4), plugin side | A09, A11 | knk-plugin | tier:2 | none | to file | 2 |
| 5.1 | POI entity: API, web app, plugin, destination provider (§ 6), separate issue | A12–A14 | knk-web-api, knk-web-app, knk-plugin | tier:3 (schema) | `navigation.poi` (off) | to file | none |
| 5.2 | POI preference weights in the walk search (§ 5.4.3), POIs as walk-planner nodes (§ 6.2.2) | A10 | knk-plugin | tier:2 | `navigation.poi` (off) | to file | 4, 5.1 (and 3 for POI nodes in clusters) |
| 6 | Guidance quality: shaping and curve on walk paths, anchored particles, cursor and winding back (§ 7) | A15–A21 | knk-plugin | tier:3 (game feel) | `navigation.guidance-v2` (off) | to file | 1 |
| 7 | Plaza lines for the players' trail (§ 8), separate issue | A22–A25 | knk-plugin | tier:2 | `navigation.plaza-lines` (off) | to file | 6 |
| 8 | Persisted walk tiles (§ 5.5 W2) | to be written | knk-web-api, knk-plugin | tier:3 | to be set | to file later | 0, 3 |

Order: 0 and 1 first (independent), then 6 (the corner, snapping and rewind items are the developer's short-term wish) alongside 2 and 3; the POI entity (5.1) at any time, POI weights (5.2) after 4 and 5.1; plaza lines (7) after 6. Smoke test: [guides/navigation-offroad-smoke-test.md](../../guides/navigation-offroad-smoke-test.md) (written on approval).

## 15. Open questions

1. **Long walks (matrix § 5.6).** Which approach for long off-road legs? Options: (a) B, lazy HPA* over loaded chunks now, persisted tiles later; (b) A, only raise the caps, decide again after phase 0; (c) C, persisted walk tiles from the start. Recommendation: (a), because it bounds the cost by the route and shares clusters with NPCs; it is reversible toward (c).
2. **Order of the work.** The short-term wishes are indoor and mixed routes (phases 2 and 3) and the trail quality (phase 6). Options: (a) phase 0 and 1, then 6 and 2 in parallel, then 3; (b) 6 first alone because it is the smallest and most visible; (c) 3 first. Recommendation: (a) with phase 6 first of the two if only one chain runs.
3. **Walk link limits.** `walk-link-range` 40 blocks and `walk-link-ratio` 2.0. Options: (a) as proposed; (b) shorter range 24, ratio 3.0 (fewer shortcuts, safer); (c) per domain type. Recommendation: (a), tuned in the live test.
4. **Route mode words.** `/navigate <dest> shortest|efficient|preferred`. Options: (a) the three words; (b) two words (`shortest`, default); (c) a setting per player instead of a word. Recommendation: (a), default `preferred`.
5. **POI permission and ownership.** Who creates POIs? Options: (a) staff only (`knk.admin.poi`), as roads; (b) staff and domain owners for POIs inside their domain; (c) players. Recommendation: (a) now.
6. **POI and the destination engine.** Options: (a) POIs in the old catalogue until KNG-235 is built; (b) build the engine's phase 1 and 2 first. Recommendation: (a), because the engine is proposed and unstarted.
7. **Cluster persistence.** Options: (a) memory only in v1 (rebuilt after restart, within budget); (b) persist the clusters at once with the offline snapshot. Recommendation: (a), since persisted tiles are phase 8.
8. **Plaza pull default.** `plaza-pull` 0.35. Options: (a) 0.35; (b) 0.5 (stronger bend to the node); (c) tune live with a command that sets it per plaza. Recommendation: (a), tuned on the real plazas of Cinix and Brink.
9. ~~**Earlier plaza attempt.** What was tried and what failed (§ 12.5)?~~ Answered 2026-11-17: the developer cannot recall the details; recorded as risk 12.5 with guards (O16).
10. **Plaza through-edges in the builder (NPC plan decision 6, 2026-11-15).** That decision puts plaza through-edges in the road-graph builder "later, so the players' trail improves too". § 8 instead shapes the drawn line at runtime and leaves the graph alone. Options: (a) § 8's runtime line now, the builder through-edges stay a later option for route length and ETA; (b) build the through-edges instead and drop § 8; (c) both in phase 7. Recommendation: (a).

### After v1

1. Explicit POI links (§ 10.2), the plaza POI subtype (§ 10.1), persisted walk tiles (phase 8), NPC use of walk links and clusters, route risk weighting (ambush), a 2D web map of POIs, discovery rewards for POIs. Issues are filed when the parent issue exists.
