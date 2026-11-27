# Off-road navigation in knk-plugin (walk search, walk links, road goal, route modes, trail shaping)

**Status:** Current · **Last updated:** 2026-11-25 (new page: the off-road chain's code as merged into `next`, PandiO/knk-workspace#698, docs #1033)
**Checked against:** knk-plugin `next` `2c5d5846` (the chain's merges: L1 `04506d8c`, L2 `c45c16bb`, L3 `54dfe8d7`,
L4 `580aafa1`, L5 `3977329c`, L7 `a94332d9`, L8 `5fd81466`, L9 `c7be34fb`, L10 `ce0f65ec` and `4daa0c84`, F1 `cee53213`,
F2 `6311de11`, F3 `6878d584`, the spacing default `916d89d4`, L7b `c7e36e6e`; landmarks since #976 L3 `14645895`);
knk-web-api `next` `e06fd5c0` and knk-web-app `next` `8be9e24c` for the group default route mode (L7b `5e16ea04`,
`86463af7`; `88d6f663`, `3b672c97`). None of it is on trunk yet.
**Applies to:** knk-plugin `next`. Each part is behind its own `navigation.*` key (§ 9) except the route modes, which
add no key and whose default is today's route.
**Related:** [off-road navigation design](../specs/navigation-offroad/DESIGN.md) (the decisions O01–O33 and phases),
[walkable last-mile paths](../specs/navigation/LAST_MILE_PATHFINDING.md) (the walk search this builds on),
[road navigation design](../specs/navigation/DESIGN.md), [NPC navigation](npc-navigation.md) (shares the shaping
package), [plugin architecture](plugin-architecture.md), [plugin permission checks](plugin-permission-checks.md) § 4,
[landmarks as a Domain subtype](../specs/landmark-domain/DESIGN.md), the
[off-road smoke test](../guides/navigation-offroad-smoke-test.md), [plugin configuration § 4.15](../guides/admin/plugin-configuration.md#415-navigation),
the [chain report](../reports/2026-11-17-navigation-offroad-chain.md) (decisions per link).

What this page covers: how a player's `/navigate` route leaves the road and comes back, in code. The road graph, its
builder and the road A* are the road navigation design's; the NPC side is [npc-navigation.md](npc-navigation.md).
Landmarks as places (entity, regions, discovery, warps) are #976's; only their weights on walk legs are here (§ 6).

## 1. Ownership and layers

knk-core holds every rule and stays free of Bukkit (`ArchitectureGuardTest`); knk-paper captures the world on the
main thread, runs searches on the routing and walk threads and draws.

| Area | knk-core | knk-paper |
|---|---|---|
| Walk search (§ 2) | `core/roads/walk/` (`WalkSearch`, `WalkPathfinder`, `MovementProfile`, `WalkBudget`, `WalkClearance`, `WalkCellWeights`, `WalkPathShaper`, `WalkTerrainNavWorld`, `WalkMeasurements`, `TerrainChangeListener`) | `paper/navigation/walk/` (`WalkSnapshotService`, `WalkLegPreparer`, `WalkAccessFactory`, `WorldGuardWalkAccess`, `WalkTerrainListener`, `WalkLinkTagger`) |
| Walk links and mixed routes (§ 3) | `core/roads/links/` (`WalkLinkCandidates`, `WalkLinkCache`, `WalkLinkPlanner`, `RoadFirstRule`, `WalkLinkCounters`); `core/roads/route/` (`WalkLink`, `WalkLinkId`, `Route.legs()`, `ManeuverBuilder`) | `NavigationService` (`linkPlanner`, the link searches, road-first in direct mode) |
| Road goal (§ 4) | `core/roads/route/RoadGoalChoice` | `NavigationService` (the candidate searches, `goalChosen`, `goalChoiceLog`) |
| Route modes (§ 5) | `core/roads/route/RouteMode`, `RouteRequest.mode`, `RoadNetworkSnapshot.costFactor(…, mode)`, `AStarRouter`, `MovementProfile.forMode`, `GroupRouteModeResolver` | `NavigateCommand` (`parseRoute`, `withMode`), `GroupRouteModeDefaults`, `KnKPlugin.wireGroupRouteModeDefaults` |
| Landmark weights (§ 6) | `core/landmarks/LandmarkWeights`, `WalkCellWeights`, landmark nodes in `WalkLinkCandidates` | the walk request in `NavigationService.forMode` |
| Trail shaping and guidance (§ 7) | `core/navigation/shape/` (`NavWorld`, `NavPoint`, `NavGeometry`, `Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine`, `PlazaCrossing`, `PlazaCurve`); `core/navigation/` (`PolylineCursor`, `CursorParameters`, `JoinPoint`, `PlazaTrail`, `PlazaLinePreviews`, `NavigationSession`) | `TrailRenderer`, `NavigationService` (direct and walk legs, cursor), `PlazaLinePreview` (`/knk road plazaline`) |
| Measurements (§ 8) | `WalkSearchStats`, `WalkMeasurements` | `WalkSnapshotService` counters, `/knk road status` lines |

## 2. The walk search

The bounded A* of [LAST_MILE_PATHFINDING](../specs/navigation/LAST_MILE_PATHFINDING.md) is unchanged in shape; the
chain added to it:

1. **Capture and threads.** `WalkLegPreparer` (main thread) builds the leg's box, asks `WalkSnapshotService` for the
   loaded chunks of the box (spread over ticks, a shared TTL cache per world and chunk, no chunk loading) and the
   player's gate, door and region access. The search (`WalkSearch.find`) runs on the walk executor over the immutable
   capture; at most `walk.max-concurrent-searches` run server-wide. A box over `walk.max-chunks-per-request` chunks
   gets no walk path (L1).
2. **Clearance cost (L3, #710).** With `guidance-v2` the profile's `clearanceCost` (`walk.clearance-cost`, 5) replaces
   `wall-cost`: a standing cell pays that much per block its `WalkClearance` lacks to `walk.wall-clearance` (0.8). At
   0 the search is the one before (the flag-off identity tests pin this).
3. **Fixes F1 and F3 (#771, #780).** Which end a search with no expansions could use, and doors: only closed doors are
   checked against the player's door rights (an open door is passed), players only.
4. **Mode and weights.** `MovementProfile.forMode(mode)` gives the length-only profile in `shortest` (§ 5);
   `WalkCellWeights` multiplies cell costs by the landmark weights in `preferred` (§ 6). `WalkCellWeights.NONE` and the
   default mode keep today's search exactly.
5. **Budget.** `WalkBudget` (`walk.max-expansions` 20 000, `max-length-factor` 1.75, `max-length` 144 plus
   `climb-allowance` per block of height, `detour-allowance` 48). Running out gives no path, never a partial one. The
   hierarchical search for longer legs (phase 3, #706) is on hold (O32); the `walk.max-length` limit seen from the
   upper keep corridors is #1030.

## 3. Walk links and mixed routes (L5, #705; `navigation.walk-links`)

A walk link is a walk path between two road nodes that the road A* may take instead of the road between them. It is
its own edge kind (`WalkLink`, `WalkLinkId`) and never enters the `RoadNetworkSnapshot`.

1. **Candidates** (`WalkLinkCandidates`, per snapshot, from the graph only): two turnable nodes (junctions, ends,
   anchors, named nodes; since L9 also landmark nodes) of one component within `walk-link-range` (40) blocks whose
   road distance is more than `walk-link-ratio` (2.0) times the straight distance, or not joined by road within
   `ratio × range`.
2. **Planner** (`WalkLinkPlanner`, per route request): at each node the A* expands, a candidate with a found link the
   request's `AccessPolicy` lets the player take is offered as an edge; one with no answer yet is collected as wanted;
   "none" and running searches are left out. A link costs `mode.linkCost(link) × max(1, cheapest road factor)`, so a
   walk is never cheaper per block than the cheapest road and the heuristic stays admissible.
3. **Searches.** After the first route, `NavigationService` searches the most promising wanted links off the main
   thread with the player's walk access, one at a time beside the walk legs, at most `walk-link-searches-per-route`
   (4) per route; a found link reroutes.
4. **Cache** (`WalkLinkCache`, keyed by world, mover and link): found links live `walk-link-ttl-seconds`, "none"
   `walk-link-retry-seconds` (600 each). The block-change hook (`WalkTerrainListener` → `TerrainChangeListener`: block
   place, break, burn, fade, form, explosions, pistons, entity changes; registered only with `walk-links` on) drops a
   link whose chunks change; a gate or availability change drops every "none" of the world. WorldEdit edits are not
   seen; the TTL is the backstop.
5. **Tags and access.** `WalkLinkTagger` (main thread) records the WorldGuard regions and gate doors a link passes,
   so the per-player access policy judges it like a road edge at every route.
6. **The route as legs.** `Route.legs()` returns road legs and walk-link legs in order; the trail draws a walk-link leg
   in the walk-leg colour and `ManeuverBuilder` adds "Leave the road and walk across".
7. **Road-first rule** (`RoadFirstRule`, the developer's wish of 2026-11-18): in direct mode (a target within
   `max-snap-distance`) the road is used instead of the single walk path when it carries at least `road-first-share`
   (0.6) of the way and the whole way, the walks to and from the road estimated at 1.5 × their straight distance, is
   at most `road-first-max-ratio` (1.5) times the walk path.

## 4. Road goal by walk reachability (F2 and F3, #780, #771; `navigation.road-goal-reachable`)

Without the key the road goal of a point destination is the road point nearest it in a straight line
(`Snapper.snapFloor`), which inside a building can be a dead end far from the destination on foot.

1. **Candidates** (`RoadGoalChoice.candidates`, `candidatesAlongRoad`): the nearest point of each road edge within
   `max-snap-distance` of the destination, nearest first, today's point among them, plus the road's nodes onward from
   today's point (F3); at most `road-goal-candidates` (12).
2. **Searches.** Each candidate gets one walk search to the destination within the `walk:` limits, one at a time off
   the main thread; each reached one gets a road route.
3. **Choice** (`RoadGoalChoice.best(options, walkWeight)`): the least road length plus `road-goal-walk-weight` (4.0)
   times walk length, so the walk starts as late as the road usefully carries the route. One INFO line per choice
   lists every candidate's road and walk lengths. The first route is today's; the chosen one replaces it when the
   searches answer. None reached: today's goal.
4. **`road-to-its-end`** (F2): a road route the player follows is kept when the road network is swapped near the
   destination, instead of switching to direct mode partway along the road.
5. **NPCs** reuse `RoadGoalChoice` through `npc/nav/NpcRoadGoals` behind `npc.navigation.road-goal-reachable` (#814,
   [NPC navigation](npc-navigation.md)). Road edge ids that change between two choices seconds apart are #1032.

## 5. Route modes (L7, #707) and a group's default (L7b, #852)

1. **`RouteMode`** (`SHORTEST`, `EFFICIENT`, `PREFERRED`; `DEFAULT = PREFERRED`). Road factor per edge:
   `shortest` 1.0, `efficient` the road class's `class-cost`, `preferred` edge multiplier × profile multiplier ×
   class cost, in today's order of the products, so the default's numbers are bit-identical. Walk legs: `shortest`
   prices every move as the blocks walked (`MovementProfile.lengthOnly()`: no jump, drop, door, wall or clearance
   cost; what the mover can do is unchanged); the other two keep today's profile. Walk links: `shortest` prices a link
   by its walked length, the others by its walk cost; one link cache serves all modes.
2. **Where the mode travels.** `RouteRequest.mode` (old constructors default to `preferred`), `Route.mode()`, the
   session's `Active` (set in the shared `begin`), the walk request (`forMode` on the walk thread) and the link
   planner. NPC plans pass no mode. Explanations (`/knk road why`) route in the default mode.
3. **The command.** `NavigateCommand.parseRoute` reads `<dest> [mode] [spawn|region]`; after `spawn`/`region` a word
   is part of the name. A typed word is checked with `CommandPermissions.whenAllowed` against `knk.navigate.mode.<word>`
   once the destination is resolved; completion offers only held words (`hasForCompletion`). Both the destination
   engine path and the old path share this code; on the old path a siege match reads no mode word.
4. **Group default.** knk-web-api `PermissionGroup.DefaultRouteMode` (enum `RouteMode`: `Shortest`, `Efficient`,
   `Preferred`, stored by name in a nullable `varchar(16)`; migrations `AddPermissionGroupDefaultRouteMode` and
   `NormalizePermissionGroupDefaultRouteMode`). The DTO's write rule: a name sets it, null or `""` clears it, a body
   without the property keeps it (`DefaultRouteModeSent`). The web app shows it in the group form (Enum field with
   `settingsJson.emptyOptionLabel`) and the dashboard column "Default route".
5. **Plugin side.** `GroupRouteModeResolver.resolve(memberships, groups)`: of the active memberships whose group has a
   default, the highest weight wins (tie: the lower group id). `GroupRouteModeDefaults` caches the answer per user:
   `cachedDefault` never calls the API and never blocks; a miss answers null (today's call) and fills in the
   background from `GET api/UserPermissionGroups?userId=` and the cached `GET api/PermissionGroups`. It is warmed on
   every `/navigate` and Tab, dropped by the permission cache's user and all invalidations and by
   `PermissionGroupChanged`, and refilled after 10 minutes (`DEFAULT_TTL`); a fill that started before an
   invalidation is discarded. `NavigateCommand.withMode`: no typed word → the cached group default (no node check) or
   today's call; a typed word → its node check. The knk-api-client reads `defaultRouteMode` in either spelling.
6. **Proof of "default = today".** Golden transcripts written on the base before phase 4
   (`knk-core/src/test/resources/route-modes/`; `RouteModeDefaultTranscriptTest`, `LinkRouteDefaultTranscriptTest`,
   `WalkLegDefaultTranscriptTest`) compare the default and `preferred` character for character.

## 6. Landmark weights on walk legs (L9, #709; `navigation.landmarks`, `preference-max`)

1. `LandmarkWeights.areas` (main thread) turns each landmark with an area and a `Preference` other than 1.0 into a
   weighted area; since #976 L3 the area is the union of the landmark's regions (its own region and sub-regions, or the
   parent domain's), no radius.
2. `LandmarkWeights.within` (walk thread, per request) keeps the areas whose box meets the request's reach box and
   gives a `WalkCellWeights`: a cell's cost is multiplied by the product of the areas over its feet block, capped at
   `preference-max` (4.0) and at its inverse. The heuristic is scaled by the product of the weights below 1.0, so it
   stays admissible. Only `preferred` uses them (`RouteMode.usesPreferenceWeights()`).
3. Landmark nodes (the road nodes landmarks stand on) join the walk-link candidates (§ 3.1); connections are inferred
   (O05), none stored.

## 7. Trail shaping and guidance

1. **Shared shaping package (L2, #704).** `core/navigation/shape/` holds the NPC shaping classes moved out of
   `core/npc/nav/` without a behaviour change (`NavWorld`, `NavPoint`, `NavGeometry`, `Corridor`, `CorridorShaper`,
   `FreeWidth`, `PlazaLine`, `PlazaCrossing`) and the players' `PlazaCurve`. It imports nothing from `core/npc`.
2. **Shaped walk paths (L3, #710; `guidance-v2`, `walk.curve`).** `WalkPathShaper` runs on the walk thread after the
   search, over `WalkTerrainNavWorld` (the capture, never the live world): the path is cut into runs between ladders
   and drops, each run goes through `CorridorShaper` with `walk.wall-clearance` (points pulled to keep clearance,
   chokepoints such as doors on their axis, string pulling), then each corner is rounded by a Bézier whose samples are
   checked against the clearance map; a failing corner is retried half as wide, then kept sharp.
3. **Anchored particles and the cursor (L4, #711; `guidance-v2`, `trail-leg-spacing`, `cursor-jump`).**
   `TrailRenderer` draws a walk trail at the fixed anchors `k × trail-leg-spacing` (2.0) from the path's start, which
   depend only on the path. `PolylineCursor` keeps the player's place on a polyline both ways with continuity (a far
   jump only when the local candidate is farther than `reroute-distance`, or, on a walk path, really nearer);
   `NavigationSession` keeps a monotone `progress` and the `cursor` (`CursorParameters`), so the trail, the HUD distance
   and the next maneuver follow a player who walks back. `JoinPoint` picks where a player off the road joins: the
   least walk (straight distance × 1.5) plus remaining route. A walk leg stays while the player is within
   `walk.recompute-distance` of it. Since F2 `trail-leg-spacing` also spaces the walk trail with `guidance-v2` off.
4. **Plaza lines (L10, #712; `plaza-lines`, `plaza-pull`, `plaza-guide-cost`, `plaza-curve-clearance`).** Step 1:
   `PlazaCurve` builds, for a route that enters a plaza on one road and leaves on another, a cubic Bézier from the
   entry to the exit pulled `plaza-pull` towards the node, checked every sample against the plaza's clearance map
   (corridor, footprint, floor continuity, regions the route passes, `plaza-curve-clearance`); a failing curve falls
   back to `PlazaLine`'s A* guided by the curve (`plaza-guide-cost`), else the route's own bend. Which junctions: a
   designed plaza, or a junction whose open floor is wider than `npc.navigation.corridor-half-width` (capped by
   `npc.navigation.plaza-corridor-blocks`). `/knk road plazaline` (`PlazaLinePreview`) shows the lines to staff with
   the flag on or off. Step 2: `PlazaTrail` maps a trail spot inside a crossing to the same share of the way along the
   plaza line, lazily per crossing, once per route; the route, its length, ETA, maneuvers, progress and cursor stay on
   the route polyline.

## 8. Measurements (L1, #703)

`WalkSearchStats` and `WalkMeasurements` count expansions, search and shaping time per walk search;
`WalkSnapshotService` reports chunks, cache hits, main-thread extraction time and wait per capture. `/knk road status`
prints the lines. Nothing reads them to decide. The results are in
[the phase 0 measurements report](../reports/2026-11-17-offroad-navigation-measurements.md); the concurrency step and the tick time of a large capture moved to
#1029.

## 9. Configuration and flags

Every key is read at start-up (restart after a change) and documented with its default in
[plugin configuration § 4.15](../guides/admin/plugin-configuration.md#415-navigation):

| Part | Keys | Default |
|---|---|---|
| Measurements | `walk.max-chunks-per-request` | 64 |
| Walk-trail quality (phases 6.1, 6.2) | `guidance-v2`, `walk.clearance-cost`, `walk.wall-clearance`, `walk.curve`, `trail-leg-spacing`, `cursor-jump` | on since #990 (out of this chain's docs), 5, 0.8, true, 2.0, 12 |
| Walk links, road-first | `walk-links`, `walk-link-range`, `walk-link-ratio`, `walk-link-ttl-seconds`, `walk-link-retry-seconds`, `walk-link-searches-per-route`, `road-first-share`, `road-first-max-ratio` | off, 40, 2.0, 600, 600, 4, 0.6, 1.5 |
| Road goal | `road-goal-reachable`, `road-goal-candidates`, `road-goal-walk-weight`, `road-to-its-end` | off, 12, 4.0, off |
| Plaza lines | `plaza-lines`, `plaza-pull`, `plaza-guide-cost`, `plaza-curve-clearance` | off, 0.35, 2, 0.65 |
| Landmarks | `landmarks`, `preference-max` | off, 4.0 |
| Route modes | none (nodes `knk.navigate.mode.<word>`, `default: op`; the group default in the API) | `preferred` |

## 10. Tests

1. knk-core: the flag-off identity tests of L3, L4, L5 and L10 (the search, the trail and the routes exactly as before
   with each key off), the route-mode golden transcripts (§ 5.6), `RouteModeTest`, `WalkRouteModeTest`,
   `WalkLinkRouteModeTest`, `GroupRouteModeResolverTest`, the `RoadGoalChoice`, `PolylineCursor`, `JoinPoint`,
   `PlazaCurve`, `WalkPathShaper` and walk-link tests; `ArchitectureGuardTest` for the shape package.
2. knk-paper: `NavigateCommandRouteModeTest`, `NavigateCommandGroupRouteModeTest`, `NavigationServiceRouteModeTest`,
   `GroupRouteModeDefaultsTest`; plugin scenarios on a real Paper server, among them `WalkTrailCursorScenario` and
   `PlazaLineRealPlazaScenario` ([plugin scenarios](../guides/developer/plugin-scenarios.md)).
3. knk-web-api: `PermissionGroupDefaultRouteModeTests`, `NormalizePermissionGroupDefaultRouteModeTests` and their MySQL
   tests; knk-web-app: `permissionGroupRouteMode.test.tsx`, `FieldRenderers.emptyOption.test.tsx` and
   `e2e/permission-group-route-mode.spec.ts`.
4. Live: the [off-road smoke test](../guides/navigation-offroad-smoke-test.md) § 1, § 8–§ 10, § 12–§ 14 passed, § 3,
   § 5, § 15 accepted without a live test; § 6 and § 7 superseded by the
   [landmark-domain smoke test § 3](../guides/landmark-domain-smoke-test.md#3-phase-3-plugin-985-tier2).

## 11. Limitations and open work

1. No hierarchical walk search: legs beyond the single search's budget get no walk path (phase 3, #706, on hold); no
   persisted walk tiles (phase 8, #713, later).
2. Only loaded chunks are captured; a leg touching an unloaded chunk keeps its straight line.
3. NPCs do not use walk links or route modes (NPC plans route in `preferred`).
4. The group default is read from a warm cache only: the first `/navigate` after a join or a change may run in
   `preferred`.
5. Open issues: #1029 (phase 0 concurrency and tick time), #1030 (walk length cap from the upper keep stair house),
   #1031 (skip an identical walk recompute while standing still), #1032 (road edge ids change between goal choices).
