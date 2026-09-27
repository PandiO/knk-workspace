# Road Navigation — Design

**Status:** Draft — awaiting developer review (open questions in §9). Not MVP-critical: build after the siege MVP.
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-street-road-graph-endpointsintersections-traced-road)
**Research:** [reports/2026-09-27-road-navigation-research.md](../../reports/2026-09-27-road-navigation-research.md)
(legacy scan, archive notes, V3 building blocks, algorithm sources). File/line references below are explained there.

---

## 1. Goal

Give Streets a physical shape so that players (and later NPCs) can be guided **along the real roads** of the world:

- Admins record each street's **begin/end points and intersections** as graph nodes.
- The plugin **traces the road blocks** between nodes (roads meander, widen, climb stairs, cross bridges) and stores each
  stretch as an edge: polyline, length, street.
- `/navigate <destination>` routes a player over that graph to a **Location**, a **Domain's default spawn Location**
  (Town, District, Structure), or the **closest point of a Domain's WorldGuard region**, and shows the way with a
  particle trail visible only to that player.

This realises vision §2.4 (Streets as *"a navigable address and wayfinding system"* for players and NPCs) and closes the
gap V1's intro tutorial joked about (*"the developer … still didn't invent Navigation"*).

### 1.1 Out of scope for the first version (see §8 Phase 6)

- Off-road pathfinding around obstacles (the MVP draws a straight hint from the player to the nearest road).
- NPC routing (V1 Carrier trait, transport quests), travel-time/travel-mode estimates in the web app, route risk
  (ambush) weighting. The data model leaves room for all three.
- A 2D map in the web app.
- Cross-world routes (one graph per world; no portals).

---

## 2. Concepts

```
 Street "Keepstreet"            Street "Merchantstreet"
  E1 ●━━━━━━━━━━━━━━━━━━● X1 ━━━━━━━━━━━━━━━━━━● E3
                        ┃
                        ┃  (Merchantstreet continues)
                        ● E2
 ● node   ━ edge (traced polyline over road blocks)
```

- **Road node** — a point on a road surface an admin recorded, or one the tracer split out. Kinds:
  - `Endpoint` — a street's begin or end, or a dead end.
  - `Intersection` — where two or more roads meet. A node is shared by every street that passes it; it does not belong
    to a street.
  - `Anchor` — an optional helper node an admin places on a tricky stretch (a bridge, a tunnel, a plaza) to force the
    tracer through it or to split a long edge.
  - `Virtual` — created only in memory at routing time (the player's snap point, the destination's snap point). Never
    stored.
- **Road edge** — one traced stretch between two adjacent nodes: polyline, walked length, street (nullable: unnamed
  wilderness paths), status. Undirected by default.
- **Road network** — all nodes and edges of one world. Street membership is a label on edges, so "the geometry of
  Keepstreet" = its edges, and "the streets at X1" = the streets of the edges meeting there.
- **Road palette** — the set of block materials roads are made of (gravel, dirt path, cobblestone, stone bricks, their
  slabs and stairs, …). The tracer only walks over palette blocks.

Why admin-recorded nodes rather than fully automatic extraction: automatic junction detection is the weakest step of
every published road-extraction pipeline (wide junctions and plazas produce clusters and spurs), and the admin already
knows where streets begin, end and cross. Recording ~2-4 points per street is cheap; tracing the hundreds of blocks
between them is the tedious part, and that is what gets automated.

---

## 3. Data model (knk-web-api)

New entities, one migration (`AddRoadNetwork`). Tables in `snake_case` like the rest of the schema.

### 3.1 `RoadNode` (`road_nodes`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `World` | string (64), required | Bukkit world name, same as `Location.World`. |
| `X`, `Y`, `Z` | int | Block coordinates of the road **surface** block (the player stands at Y + 1). |
| `Kind` | enum `RoadNodeKind` (`Endpoint`, `Intersection`, `Anchor`) | Stored as string like the other enums. |
| `Name` | string?, max 100 | Optional ("Kardenna market cross"). Named nodes are valid `/navigate` destinations (§6.1). |
| `CreatedAt`, `UpdatedAt` | DateTime | |

Unique index `(World, X, Y, Z)`. Index `(World, X, Z)` for area queries.

### 3.2 `RoadEdge` (`road_edges`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `FromNodeId`, `ToNodeId` | int FK → `road_nodes`, cascade delete | Stored with `FromNodeId < ToNodeId`; unique index on the pair. |
| `StreetId` | int? FK → `streets`, SetNull | Unnamed paths are allowed. |
| `World` | string (64) | Denormalised from the nodes for per-world loading. |
| `Geometry` | string (JSON, `longtext`) | RDP-simplified polyline `[[x,y,z],…]` of standing positions (surface Y + 1), from `From` to `To`. |
| `Length` | double | Walked 3D length of the **unsimplified** path, in blocks. |
| `MinX`, `MinZ`, `MaxX`, `MaxZ` | int | Bounding box, for area queries and the plugin's spatial index. |
| `AvgWidth` | double? | Mean road width along the path, from the tracer; informational and for later costs. |
| `CostMultiplier` | double, default 1.0 | Admin tuning: > 1 to discourage (steep stairs, a dangerous forest road), < 1 to prefer a main road. Later the hook for terrain and ambush-risk modifiers (iPhone notes 282, 297). |
| `Oneway` | bool, default false | For one-way stretches (a drop, a ladder-free cliff path). Direction is From → To. |
| `Source` | enum `RoadEdgeSource` (`Traced`, `Recorded`, `Manual`) | Traced by the tracer; recorded by an admin walking it (§5.4); manual = straight segment typed in. |
| `Status` | enum `RoadEdgeStatus` (`Ok`, `Stale`, `Disabled`) | `Stale` when validation finds the road changed (§5.5); `Disabled` excluded from routing. |
| `TracerVersion` | int | Lets a tracer change force a re-trace. |
| `TracedAt`, `UpdatedAt` | DateTime | |

Edges are replaced as a set per trace run (§5.3), so there is no edit history on geometry. That is acceptable: a
re-trace is cheap and deterministic.

### 3.3 Street changes

None to the table. `StreetDto` gains read-only `nodeCount`, `edgeCount`, `totalLength` for the web app. The plugin's
unused `StreetCache` stays unused; navigation reads the road network bundle instead (§3.4).

### 3.4 Endpoints

| Route | Auth | Purpose |
|---|---|---|
| `GET api/road-network?world={w}` | anonymous read (like other reference data) | The whole graph of a world in one payload: nodes, edges (with geometry), street id → name map, and a `version` (max `UpdatedAt` + counts, as an ETag). The plugin caches it and re-fetches on `If-None-Match` mismatch. Size estimate: 2,000 edges × ~40 points ≈ 1-2 MB JSON, fetched on start and after edits only. |
| `GET/POST/PUT/DELETE api/road-nodes[/{id}]`, `POST api/road-nodes/search` | writes: `[RequirePluginServiceKey]` | Node CRUD from the admin commands. Deleting a node cascades its edges. |
| `PUT api/road-edges/trace-result` | `[RequirePluginServiceKey]` | Body: `{ world, nodeIds[], edges[] }`. Replaces every `Traced` edge whose **both** nodes are in `nodeIds` with the given set in one transaction; `Recorded`/`Manual` edges are kept. Idempotent. |
| `POST api/road-edges`, `PUT/DELETE api/road-edges/{id}` | `[RequirePluginServiceKey]` or staff JWT | Recorded/manual edges and admin tuning (`StreetId`, `CostMultiplier`, `Oneway`, `Status`). |
| `GET api/streets/{id}/road` | anonymous | Edges and nodes of one street (web-app view). |

Validation in `RoadNetworkService`: both nodes in the same world; no self-loop; geometry starts/ends within 1.5 blocks
of its nodes; length ≥ straight-line distance; `StreetId` exists.

---

## 4. Plugin architecture (knk-plugin)

Follows the siege/teleport split: pure logic in `knk-core` (Bukkit-free, unit-tested), thin Paper adapters in
`knk-paper`.

| Module | Package | Contents |
|---|---|---|
| knk-core | `core/domain/roads/` | Records `RoadNode`, `RoadEdge`, `RoadNetwork` (immutable snapshot of one world), `BlockPos`. |
| knk-core | `ports/api/RoadNetworkQueryApi`, `RoadNetworkCommandApi` | API ports. |
| knk-core | `core/roads/trace/` | `RoadTracer` (§5), `SurfaceGrid` port (`isRoadSurface(x,y,z)`, `isPassable(x,y,z)`), `DistanceTransform`, `Rdp`. |
| knk-core | `core/roads/route/` | `RoadGraph` (adjacency built from a `RoadNetwork`), `SegmentIndex` (grid buckets), `Snapper`, `AStarRouter`, `Route`/`RouteLeg`, `ManeuverBuilder`, `RegionClosestPoint`. |
| knk-core | `core/navigation/` | `NavigationSession` state machine, `DestinationResolver` (wraps teleport's `WarpTargets`), `EtaEstimator`. |
| knk-api-client | `impl/RoadNetworkQueryApiImpl`, `RoadNetworkCommandApiImpl`, DTOs + mapper | |
| knk-paper | `roads/` | `ChunkSnapshotSurfaceGrid` (implements `SurfaceGrid` over snapshots), `RoadTraceJob` (tick-budgeted capture + async trace), `RoadNetworkCache` (per world, ETag refresh), `RoadAdminCommand`, `RoadOverlayRenderer`. |
| knk-paper | `navigation/` | `NavigateCommand`, `NavigationService` (sessions, ticker), `TrailRenderer`, `NavigationHud` (boss bar/action bar), `NavigationListener` (quit, world change, teleport, death, siege join), events (§6.6). |

Config (`config.yml`):

```yaml
navigation:
  enabled: true
  road-palette: [GRAVEL, DIRT_PATH, COARSE_DIRT, COBBLESTONE, MOSSY_COBBLESTONE, STONE_BRICKS,
                 MOSSY_STONE_BRICKS, CRACKED_STONE_BRICKS, ANDESITE, POLISHED_ANDESITE, "*_SLAB", "*_STAIRS"]  # §9 Q1
  palette-exclude: [OAK_SLAB, SPRUCE_SLAB]      # e.g. roof slabs, if they cause leaks
  max-snap-distance: 48          # blocks from the player/destination to the road network
  trail-length: 30               # blocks of path drawn ahead
  trail-period-ticks: 10
  trail-particle: DUST           # with colour below; falls back to END_ROD
  trail-color: "#E8C66A"
  reroute-distance: 8
  reroute-after-ticks: 40
  arrive-distance: 4
  max-session-minutes: 30
  sprint-speed: 5.6              # blocks/s; iPhone notes: "3 min = 1000 blocks"
  tracer:
    max-cells-per-run: 400000
    snapshot-chunks-per-tick: 4
    max-radius: 2048
```

---

## 5. Road tracing — the "veins/roots" algorithm

Admin-triggered, offline. The goal is: given a set of recorded nodes and the world's blocks, find which nodes are
directly connected by road and the centerline between them.

### 5.1 Surface cells

A **road cell** is a block position `(x, y, z)` where:

1. the block's material is in the road palette, and
2. the two blocks above are passable (a player can stand there), and
3. for slabs: bottom slabs count at their own Y; stairs count at their own Y.

Neighbours: the 8 horizontal neighbours at `dy ∈ {−1, 0, +1}` (diagonals only when one of the two orthogonal cells is
also a road cell, so roads touching at a corner do not leak). The |Δy| ≤ 1 rule keeps a bridge separate from the road
under it and makes stairs and slabs walkable.

### 5.2 Steps

Run for a **scope**: one street's nodes, all nodes within a radius, or all nodes of a world.

1. **Capture.** On the main thread, take `ChunkSnapshot`s of the chunks around the scope's nodes, a few per tick
   (`snapshot-chunks-per-tick`), growing outward only into chunks the flood actually reaches. No synchronous chunk
   loads beyond what the flood needs; unloaded chunks are loaded with `getChunkAtAsync`.
2. **Grow roots (multi-source BFS).** Seed a BFS queue with every node, labelled by node id. Expand over road cells;
   each cell gets the label of the first node to reach it and its BFS distance. This partitions the road mask into one
   region per node — each node's "root system" — and stops at `max-cells-per-run`/`max-radius`.
3. **Find neighbours.** Wherever a cell labelled A touches a cell labelled B, nodes A and B are adjacent along the road.
   Collect those pairs (with the contact cell). A node can have any number of neighbours (an X-crossing has 4).
4. **Centerline per pair.** Compute a distance transform over the mask (BFS from the mask's border cells inward: each
   cell's distance to the nearest non-road cell). For each adjacent pair, run A\* from A to B restricted to cells
   labelled A or B, with step cost `1 + k / (1 + dt(cell))` (k ≈ 2). Paths therefore prefer the middle of wide roads
   and still follow 1-wide paths exactly. Diagonal steps cost √2, vertical steps add 0.25.
5. **Simplify.** Record `Length` from the raw path, then RDP with ε = 0.75 for `Geometry`. `AvgWidth` = mean of
   `2 × dt` along the raw path.
6. **Report.** Send the edge set to `PUT api/road-edges/trace-result`; show a summary to the admin: edges found,
   nodes with **no** neighbours (probably placed off the road or on a non-palette block), and **dead-end suspects**:
   mask cells far (> 24 blocks) from every edge whose region is a long thin tail — likely a street end with no node,
   offered as "`/knk road node add` here?" with coordinates.

Everything after step 1 runs off the main thread on plain arrays (packed `long` keys, as in `FloodFillScanRunnable`).
Memory: a 3-wide road is ~3,000 cells per km, so even 50 km of roads is ~150,000 cells — small; the
`max-cells-per-run` cap guards against a palette that leaks into a cobblestone town square or a gravel beach.

### 5.3 Why not full skeletonization

Skeletonize → junction detection → graph is the standard remote-sensing pipeline (research §5.1). It is kept as the
fallback if region growing turns out to mis-assign regions on wide plazas, but with admin nodes the region-growing
approach is simpler: no spur pruning, no junction-cluster merging, and every edge is guaranteed to end at a node the admin
chose. It is also the literal form of the developer's "veins or roots" intuition.

Known edge cases and how they are handled:

| Case | Handling |
|---|---|
| Plaza or square made of palette blocks | Its cells are split between the surrounding nodes; the centerline A\* crosses it straight-ish. If results look wrong, place an `Anchor` in the middle. |
| Two parallel roads touching (a wide avenue with a median) | Diagonal-corner rule keeps corners from leaking; otherwise they merge into one wide road, which is fine for routing. |
| Bridge over a road | Separate because of the Δy rule, unless the bridge deck is within 1 block of the road below (rare). |
| Gaps (a doorway, a wooden bridge not in the palette, a ford) | The two sides get no contact, so no edge. Admin fixes it by adding the bridge material to the palette, or by **recording** the edge (§5.4). |
| Town streets that are not palette blocks (grass paths) | Same: record the edge, or place nodes and use `Manual` straight segments for short hops. |
| Palette leaks into buildings (cobblestone floors) | Doorways are usually a non-palette threshold; if not, `palette-exclude` or a `max-width` check (cells with `dt` > 6 are not expanded). |

### 5.4 Recorded edges (fallback for anything the tracer can't follow)

`/knk road record start <fromNode>` samples the admin's standing position every 10 ticks while they walk;
`/knk road record stop <toNode> [street]` closes it into a `Recorded` edge (RDP applied). This covers wooden bridges,
tunnels, fords and grass paths without widening the palette.

### 5.5 Keeping the network in sync with the world

- `/knk road validate [street|radius]` samples every edge's geometry points (standing position must still be passable
  over a palette block or the recorded edge's original block) and marks edges `Stale` above a threshold (say 10% of
  points broken). `Stale` edges stay routable but are listed for re-trace.
- A re-trace of a scope replaces only its `Traced` edges (§3.4), so recorded and manual work is never lost.

---

## 6. Navigation at runtime

### 6.1 Command

```
/navigate <destination> [spawn|region]      alias /nav
/navigate stop
/navigate                                    shows the current route, or usage
```

Permission `knk.navigate` (default: every player). Destination forms (case-insensitive, tab-completed):

| Form | Resolves to |
|---|---|
| `location:<name>` / `location:#<id>` | A `Location` by name (exact, then unique prefix) or id. |
| `town:<name>`, `district:<name>`, `structure:<name>` (or `#<id>`) | The domain's `Location` (default spawn); with `region`, the closest point of its WorldGuard region (§6.3). |
| `street:<name>` | The nearest point on that street's edges. |
| `node:<name>` | A named road node. |
| bare `<name>` | Searched across all of the above; one match → go; several → list `type:name` choices (the teleport `WarpTargets` behaviour). |

A domain without a `Location` falls back to `region` automatically. A domain with neither is refused with a clear
message.

Resolution reuses teleport's `WarpTargets`/`SpawnPointResolver` (on `claude/teleport`, KNG-17). Unlike `/warp`, a
destination does **not** need `TeleportEnabled`: navigating is walking, so every domain with a location or region is
a valid destination. `AllowEntry = false` is allowed but warned about (§9 Q4). Structures need a second lookup for their
`Location` (`StructureDto` only has `locationId`).

### 6.2 Route computation (async)

1. Resolve the destination to a target: a point, or a **set** of goal points (region mode, §6.3).
2. **Snap** the player's position and the target to the network: the nearest edge segments within `max-snap-distance`
   through the grid-bucket `SegmentIndex`; project onto the segment; insert `Virtual` nodes that split the edge.
3. If the straight-line distance player → target is shorter than both snap distances combined, or nothing is within
   snap distance, skip the graph: **direct mode** (a straight trail toward the target, recomputed as the player moves).
4. **A\*** over the graph with cost `Length × CostMultiplier`, heuristic Euclidean distance to the target (admissible).
   `Disabled` edges and wrong-way `Oneway` edges are skipped.
5. Build the `Route`: an off-road leg (player → snap point), the road legs (edge polylines, reversed where traversed
   To → From, trimmed at the virtual nodes), and an off-road leg to the target. Compute `Maneuver`s (§6.5) and ETA
   (`length / sprint-speed`).

Target: < 5 ms for a few thousand nodes; the network snapshot is immutable, so routing runs on any thread.

### 6.3 Closest point of a region

For `town:Kardenna region`: the goal is to reach the region's edge the shortest way, not its centre.

- Polygonal region: `ProtectedPolygonalRegion.getPoints()` (2D) + min/max Y; cuboid: min/max corners. Converted to a
  Bukkit-free `RegionShape` in knk-core.
- Goals = every road-network point **inside** the region (edge segments clipped to the polygon), plus, if none, the
  point on the network closest to the polygon. A\* then runs as a multi-goal search (heuristic = distance to the
  polygon, still admissible) and stops at the first goal reached. Result: the route ends where the road enters the
  region, which is the natural "arrival" at a town gate.
- If the player is already inside the region: "You are already in Kardenna" and no route.

### 6.4 Guidance

- **Trail:** every `trail-period-ticks`, the player's position is projected onto the route; the next `trail-length`
  blocks of the route are drawn with `Player#spawnParticle` (visible only to them), one particle every ~1.5 blocks at
  standing height + 0.2, `DUST` in the configured colour. Off-road legs use a sparser, differently coloured trail.
- **Boss bar:** `"→ Merchantstreet · 340 m · ~1 min"` with progress = travelled / total. The next maneuver replaces it
  within 20 blocks of a turn: `"Turn left onto Merchantstreet"`.
- **Action bar:** an arrow (`⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉`) from the angle between the player's yaw and the bearing to the trail
  point ~6 blocks ahead, for players with particles set to minimal.
- **Re-route:** if the player is more than `reroute-distance` from the route for `reroute-after-ticks`, recompute from
  their position (max once per 3 s). A different route is announced ("Recalculating…").
- **Arrival:** within `arrive-distance` of the target (or inside the region in region mode) → sound + chat
  `"You have arrived at Kardenna Market."`, session ends.
- **Ends automatically** on quit, death, world change, teleport (except short-distance teleports < 16 blocks), joining
  a siege match, or `max-session-minutes`. One session per player; a new `/navigate` replaces the old one.

### 6.5 Maneuvers

At each route node with ≥ 3 edges, or where the street label changes: Δ = bearing after − bearing before (bearings from
the polyline's last/first ~6 blocks around the node, so small wiggles don't count). Bands: < 20° straight (only
announced if the street name changes: "Continue onto …"), 20-60° slight, 60-120° turn, > 120° sharp; sign gives
left/right. Unnamed edges read "Take the path on the left".

### 6.6 Events (for other features)

Custom Bukkit events in `navigation/events/`: `NavigationStartEvent` (cancellable), `NavigationRerouteEvent`,
`NavigationArriveEvent`, `NavigationEndEvent` (reason). Consumers later: transport quests, tutorial steps, discovery
("arrived at a town you haven't discovered"), bandit ambushes on long routes.

---

## 7. Admin tooling

In-game (`knk.admin.roads`), following the `GateDoorRegionCaptureHandler` pattern (direct commands, no WorldTask):

| Command | Does |
|---|---|
| `/knk road node add <endpoint\|intersection\|anchor> [name]` | Adds a node at the road block under the admin's feet (or the targeted block with `--look`); refuses if the block is not in the palette unless `--force`. |
| `/knk road node remove [id]` / `move [id]` / `list [radius]` / `name <id> <name>` | Maintenance; `remove` without id takes the nearest within 3 blocks. |
| `/knk road trace street <street>` / `trace radius <r>` / `trace all` | Runs §5 for that scope, shows progress in the action bar and a summary at the end (edges, isolated nodes, dead-end suspects with clickable "add node here"). |
| `/knk road assign <street> [edgeId]` | Sets the street of the edge under the admin (or by id). A trace keeps existing street labels on edges whose node pair is unchanged. |
| `/knk road record start <fromNode>` / `stop <toNode> [street]` / `cancel` | Recorded edges (§5.4). |
| `/knk road edge set <id> cost <x>` / `oneway <true\|false>` / `disable` | Tuning. |
| `/knk road show [radius]` / `hide` | Admin overlay: nodes as coloured pillars of particles (kind = colour), edges as lines coloured by street (hash of id), `Stale` in red, `Disabled` grey; labels in the action bar when looking at a node. |
| `/knk road validate [scope]` | §5.5. |

Web app (admin, Phase 5): Street detail shows its edges (count, length, status) and nodes; edge list with
`CostMultiplier`/`Oneway`/`Status` editing; a road-network table per world with stale/isolated filters. No map in v1.

---

## 8. Implementation phases

Each phase is independently mergeable and testable without a live server except where noted.

| Phase | Repo | Contents | Tests |
|---|---|---|---|
| 0 | workspace | Developer answers §9 (can be done any evening; every question has a default). | — |
| 1 | web-api | `RoadNode`, `RoadEdge`, enums, migration `AddRoadNetwork`, `RoadNetworkService`, controllers (§3.4), `StreetDto` counts. | Service/validation unit tests; migration on the fresh-DB CI workflow. |
| 2 | plugin core | `core/roads/` tracer + router + snapping + maneuvers + region closest point, all Bukkit-free. | Golden tests on synthetic `SurfaceGrid`s: meandering 1-wide path, 5-wide road, T and X junctions, stairs up a hill, bridge over a road, plaza, gap (no edge), palette leak into a floor (capped). Router: shortest path, oneway, disabled edges, virtual-node splits, region multi-goal. |
| 3 | plugin paper | `ChunkSnapshotSurfaceGrid`, `RoadTraceJob`, `RoadNetworkCache`, `/knk road …` admin commands, overlay. API client + mapper. | Contract test against the Phase 1 API; **live**: record and trace one real street + one crossing on the dev server. |
| 4 | plugin paper | `/navigate`, `DestinationResolver` (after KNG-17 merges), `NavigationService`, trail, boss/action bar, events, config. | Session state-machine tests in core; **live** checklist: navigate to a Location, a Town spawn, a Structure, a region edge, a street; re-route; arrival; auto-end on death/teleport/siege. |
| 5 | web-app | Street road panel, edge tuning, network table. | Component tests. |
| 6 (later) | all | Off-road legs with Pathetic; NPC routing (Carrier/transport quests) over the graph; ETA per travel mode and terrain/risk modifiers (iPhone notes 282, 297); "treasure map/radar" items reusing the trail; discovery-gated destinations; a 2D web map. | — |

**Dependencies:** Phase 4 depends on KNG-17 (teleport) reaching trunk for `WarpTargets`/`SpawnPointResolver`. Phases 1-3
depend on nothing in flight. Nothing here touches the siege branch.

**Rough size:** Phase 1 S-M, Phase 2 M-L (the tracer is the novel part), Phase 3 M, Phase 4 M, Phase 5 S.

---

## 9. Open questions (recommended default in bold)

1. **Road palette.** Which blocks are the V3 world's roads actually built from? The only legacy mention is "gravel,
   slabs" (iPhone notes 164). **Default: the list in §4, tuned after the first trace on the dev server; kept in plugin
   `config.yml` because only the plugin traces.** Move it to the API only if the web app needs it.
2. **Edges without a street.** Allow unnamed wilderness paths? **Yes (`StreetId` nullable).**
3. **Domain destination default.** Spawn `Location` or region edge? **`Location` when set, else region; `region`
   keyword forces the region.**
4. **Restricted or undiscovered destinations.** Navigate to a domain with `AllowEntry = false`, or one the player hasn't
   discovered (KNG-20)? **Allowed, with a warning for `AllowEntry = false`; no discovery gating in v1** (can be a
   per-domain flag later, like `TeleportRequiresDiscovery`).
5. **Off-road legs.** **Straight-line hint in v1**; Pathetic in Phase 6.
6. **Particle visibility.** Only the navigating player sees their trail? **Yes.** (A "follow me" shared trail for
   clans/escorts could come later.)
7. **Street membership of intersections.** Nodes are shared, streets live on edges. Confirm this matches how you think
   of intersections. **Default: yes.**
8. **Priority.** **Post-siege-MVP**, but Phase 1-2 are safe to run in parallel with siege work because they touch no
   siege files.
9. **Missing source note.** The street begin/end/intersection idea isn't in the transcribed iPhone notes (research
   §3). Is there another note or a local code copy with the old tracer? **Default: design proceeds from this document.**
