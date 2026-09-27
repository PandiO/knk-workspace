# Road Navigation — Design

**Status:** Draft rev. 2 — awaiting developer review (open questions in §9). Not MVP-critical: build after the siege MVP.
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-street-road-graph-endpointsintersections-traced-road)
**Research:** [reports/2026-09-27-road-navigation-research.md](../../reports/2026-09-27-road-navigation-research.md)
(legacy scan, archive notes, V3 building blocks, algorithm sources);
[reports/2026-09-27-open-world-navigation-research.md](../../reports/2026-09-27-open-world-navigation-research.md)
(how Rockstar, Ubisoft and other open worlds do it).

**Rev. 2 (same day):** rev. 1 had admins record every street's begin, end and intersection by hand. Open-world games
don't do that — they author a road's intent and derive the topology (GTA V marks a node a junction by its neighbour
count; GTA III assembles its network from road pieces; Wildlands' roads branch off each other by construction). Our
roads are already a raster of blocks, so rev. 2 **detects junctions and endpoints automatically** (road mask →
centreline → neighbour count), **infers street names** from the Structures that already know their street, builds and
rebuilds the network **per tile**, and leaves admins only review, naming and exceptions.

---

## 1. Goal

Give Streets a physical shape so that players (and later NPCs) can be guided **along the real roads** of the world:

- The plugin **finds the road blocks** of the world, reduces them to centrelines, and turns them into a graph: nodes at
  junctions and dead ends, edges along the road between them (polyline, length, road class, street).
- Admins **review** the result, name what couldn't be inferred, and patch what the blocks can't express.
- `/navigate <destination>` routes a player over that graph to a **Location**, a **Domain's default spawn Location**
  (Town, District, Structure), or the **closest point of a Domain's WorldGuard region**, and shows the way with a
  particle trail visible only to that player.

This realises vision §2.4 (Streets as *"a navigable address and wayfinding system"* for players and NPCs) and closes the
gap V1's intro tutorial joked about (*"the developer … still didn't invent Navigation"*).

### 1.1 Out of scope for the first version (see §8 Phase 6)

- Off-road pathfinding around obstacles (the MVP draws a straight hint between the player and the nearest road).
- NPC routing (V1 Carrier trait, transport quests), travel-time/travel-mode estimates in the web app, route risk
  (ambush) weighting, "follow road" mode without a destination. The data model leaves room for all of them.
- A 2D map in the web app.
- Cross-world routes (one graph per world; no portals).
- Automatic rebuilds on block changes (v1 marks tiles dirty; an admin triggers the rebuild).

---

## 2. Concepts

```
 Street "Keepstreet"            Street "Merchantstreet"
  E1 ●━━━━━━━━━━━━━━━━━━● J1 ━━━━━━━━━━━━━━━━━━● E3        ● node (detected: E = end, J = junction)
                        ┃                                   ━ edge (centreline polyline over road blocks)
                        ┃  Merchantstreet                   street labels: inferred from nearby Structures
                        ● E2
```

- **Road palette** — the block materials roads are made of (gravel, dirt path, cobblestone, stone bricks, their slabs
  and stairs, …), each mapped to a **road class** (`Main`, `Road`, `Path`) with a cost factor. The builder only walks
  over palette blocks.
- **Road cell** — a palette block a player can stand on (two passable blocks above).
- **Road mask** — the connected road cells reachable from the seeds.
- **Seed** — a starting point for finding the mask. Seeded automatically from every Domain `Location` near a road;
  admins add seeds for road networks no domain touches.
- **Road node** — a point on the centreline. Kinds:
  - `Junction` — detected: 3+ centreline branches meet (intersections of any shape).
  - `Endpoint` — detected: a dead end or the end of a road.
  - `Boundary` — where a road crosses a tile border; joins the tile graphs (§5.6).
  - `Anchor` — placed by an admin to force a split or a node the detector missed.
  - `Virtual` — created in memory at routing time (the player's snap point, the destination's). Never stored.
  Admins can **name** any node ("Kardenna market cross"); named nodes are `/navigate` destinations.
- **Road edge** — the centreline between two adjacent nodes: polyline, walked length, road class, street label, flags.
- **Road tile** — a 512 × 512-block square of one world (32 × 32 chunks, like GTA V's path areas). The unit of building,
  storage and rebuilding.
- **Component** — a connected piece of the network. Every node carries its component id, so "no road connects these"
  is known without searching (GTA SA's flood-fill groups).

---

## 3. Data model (knk-web-api)

New entities, one migration (`AddRoadNetwork`). Tables in `snake_case` like the rest of the schema.

### 3.1 `RoadTile` (`road_tiles`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `World`, `TileX`, `TileZ` | string, int, int | Unique. Tile = `floor(x / 512)`, `floor(z / 512)`. |
| `BuiltAt` | DateTime? | Last successful build. |
| `BuilderVersion` | int | A builder change forces rebuilds. |
| `Dirty` | bool | Set by the plugin when palette blocks change in the tile (§5.7). |
| `CellCount`, `NodeCount`, `EdgeCount` | int | Build statistics for the admin overview. |
| `Warnings` | string? (JSON) | Build warnings: cell cap hit, suspected leak into a building, unmatched seeds. |

### 3.2 `RoadSeed` (`road_seeds`)

`Id`, `World`, `X`, `Y`, `Z`, `Note`, `CreatedAt`. Admin-added seeds only; domain seeds are derived at build time and
not stored.

### 3.3 `RoadNode` (`road_nodes`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | Stable across rebuilds (§5.5). |
| `World`, `X`, `Y`, `Z` | string, int | Standing position on the centreline. Unique `(World, X, Y, Z)`. |
| `TileId` | int FK → `road_tiles` | |
| `Kind` | enum `Junction`, `Endpoint`, `Boundary`, `Anchor` | Stored as string. |
| `Source` | enum `Detected`, `Manual` | `Manual` nodes (anchors) survive rebuilds untouched. |
| `Name` | string?, max 100 | Optional; makes the node a destination. |
| `ComponentId` | int | Recomputed after every build (§5.6). |
| `Locked` | bool | Set when an admin edits the node (name, merge, move); rebuilds keep it where it is. |

### 3.4 `RoadEdge` (`road_edges`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | Stable across rebuilds where the node pair is unchanged. |
| `FromNodeId`, `ToNodeId` | int FK → `road_nodes`, cascade | `FromNodeId < ToNodeId`; unique pair. |
| `TileId` | int FK | Edges never cross a tile border (they end at `Boundary` nodes). |
| `Geometry` | string (JSON) | RDP-simplified polyline `[[x,y,z],…]` of standing positions, From → To. |
| `Length` | double | Walked 3D length of the unsimplified centreline. |
| `MinX`, `MinZ`, `MaxX`, `MaxZ` | int | Bounding box. |
| `AvgWidth` | double | Mean road width from the distance transform. |
| `RoadClass` | enum `Main`, `Road`, `Path` | Majority class of the cells along the edge (palette mapping). |
| `StreetId` | int? FK → `streets`, SetNull | |
| `StreetSource` | enum `Inferred`, `Manual`, `None` | `Manual` labels are never overwritten by inference. |
| `CostMultiplier` | double, default 1.0 | Admin tuning on top of the road-class factor; later the hook for terrain and ambush-risk modifiers (iPhone notes 282, 297). |
| `Flags` | set: `Oneway`, `NoGps`, `Closed` | `NoGps` = never route over it (private paths); `Closed` = admin closure. Gate closures are dynamic (§6.2). |
| `Source` | enum `Detected`, `Recorded` | `Recorded` = an admin walked it (§5.8); survives rebuilds. |
| `Status` | enum `Ok`, `Stale` | `Stale` when its tile is dirty; still routable. |

### 3.5 Street changes

None to the table. `StreetDto` gains read-only `edgeCount`, `totalLength`. The plugin's unused `StreetCache` stays
unused; navigation reads the network bundle (§3.6).

### 3.6 Endpoints

| Route | Auth | Purpose |
|---|---|---|
| `GET api/road-network?world={w}` | anonymous read | Whole graph of a world: nodes, edges with geometry, street id → name map, `version` (ETag). The plugin caches it and re-fetches on change. Estimate: 2,000 edges × ~40 points ≈ 1-2 MB, fetched on start and after builds only. |
| `GET api/road-tiles?world={w}` | anonymous read | Tile overview (built, dirty, counts, warnings) for the admin overlay and web app. |
| `PUT api/road-tiles/{world}/{tileX}/{tileZ}` | `[RequirePluginServiceKey]` | **Build result for one tile**, one transaction: detected nodes (with `existingId` when matched, §5.5), detected edges, statistics. Deletes the tile's unmatched `Detected` nodes/edges; keeps `Manual`/`Locked` nodes and `Recorded` edges; recomputes component ids for the world. Idempotent. |
| `POST api/road-tiles/{world}/{tileX}/{tileZ}/dirty` | `[RequirePluginServiceKey]` | Mark dirty (batched by the plugin). |
| `GET/POST/DELETE api/road-seeds` | writes: plugin key | Admin seeds. |
| `PUT api/road-nodes/{id}` (name, kind, lock), `POST api/road-nodes` (anchor), `POST api/road-nodes/merge` | plugin key or staff JWT | Review actions. |
| `POST api/road-edges` (recorded), `PUT api/road-edges/{id}` (street, class, cost, flags), `DELETE` | plugin key or staff JWT | Review actions and recorded edges. |
| `GET api/streets/{id}/road` | anonymous | Edges and nodes of one street (web-app view). |

Validation in `RoadNetworkService`: nodes in the tile they claim; no self-loops; geometry starts/ends within 1.5 blocks
of its nodes; length ≥ straight-line distance; `StreetId` exists.

---

## 4. Plugin architecture (knk-plugin)

Pure logic in `knk-core` (Bukkit-free, unit-tested), thin Paper adapters in `knk-paper` — the siege/teleport split.

| Module | Package | Contents |
|---|---|---|
| knk-core | `core/domain/roads/` | Records `RoadNode`, `RoadEdge`, `RoadTile`, `RoadNetwork` (immutable snapshot of one world), `BlockPos`. |
| knk-core | `ports/api/RoadNetworkQueryApi`, `RoadNetworkCommandApi` | API ports. |
| knk-core | `core/roads/build/` | `SurfaceGrid` port (`isRoadCell`, `roadClassAt`, `isPassable`), `MaskBuilder`, `DistanceTransform`, `Thinning` (2D, per height layer), `SkeletonGraph` (degree classification, junction clustering, spur pruning), `NodeMatcher` (stable ids), `StreetLabeler`, `Rdp`, `TileBuilder` (orchestrates §5). |
| knk-core | `core/roads/route/` | `RoadGraph`, `SegmentIndex` (grid buckets), `Snapper`, `AStarRouter`, `Route`, `ManeuverBuilder`, `RegionClosestPoint`. |
| knk-core | `core/navigation/` | `NavigationSession` state machine, `DestinationResolver` (wraps teleport's `WarpTargets`), `EtaEstimator`. |
| knk-api-client | `impl/RoadNetwork*ApiImpl`, DTOs, mapper | |
| knk-paper | `roads/` | `ChunkSnapshotSurfaceGrid`, `RoadBuildJob` (tick-budgeted snapshot capture, async build), `RoadNetworkCache` (per world, ETag), `RoadDirtyTracker` (§5.7), `RoadAdminCommand`, `RoadOverlayRenderer`. |
| knk-paper | `navigation/` | `NavigateCommand`, `NavigationService` (sessions, ticker), `TrailRenderer`, `NavigationHud` (boss bar/action bar), `NavigationListener` (quit, world change, teleport, death, siege join), events (§6.6). |

Config (`config.yml`):

```yaml
navigation:
  enabled: true
  road-palette:                  # material -> road class; §9 Q1
    Main: [STONE_BRICKS, MOSSY_STONE_BRICKS, CRACKED_STONE_BRICKS, POLISHED_ANDESITE, "STONE_BRICK_*"]
    Road: [COBBLESTONE, MOSSY_COBBLESTONE, ANDESITE, GRAVEL, "COBBLESTONE_*"]
    Path: [DIRT_PATH, COARSE_DIRT, ROOTED_DIRT, PACKED_MUD]
  palette-exclude: []            # e.g. roof slabs, if they cause leaks
  class-cost: { Main: 0.9, Road: 1.0, Path: 1.15 }
  seed-from-domains: true        # every Domain Location within 8 blocks of a road cell is a seed
  max-snap-distance: 48
  trail-length: 30
  trail-period-ticks: 10
  trail-particle: DUST
  trail-color: "#E8C66A"
  reroute-distance: 8
  reroute-after-ticks: 40
  arrive-distance: 4
  max-session-minutes: 30
  sprint-speed: 5.6              # blocks/s; iPhone notes: "3 min = 1000 blocks"
  builder:
    tile-size: 512
    tile-margin: 32              # extra blocks read around a tile so borders are traced consistently
    max-cells-per-tile: 250000
    snapshot-chunks-per-tick: 4
    junction-cluster-radius: 3
    min-spur-length: 4
    plaza-width: 9               # wider than this = plaza (§5.4)
```

---

## 5. Building the road network

Offline, per tile, admin-triggered (`/knk road build …`). All steps after snapshot capture run off the main thread on
packed-`long` arrays, like `GateBlockScanTaskHandler`'s `FloodFillScanRunnable`.

### 5.1 Road cells and the mask

A **road cell** is `(x, y, z)` where the block is in the palette and the two blocks above are passable. Neighbours: the 8
horizontal neighbours at `dy ∈ {−1, 0, +1}`; diagonal steps only when one of the two orthogonal cells is also a road cell
(roads touching at a corner don't leak). The |Δy| ≤ 1 rule makes stairs and slabs walkable and keeps a bridge separate
from the road under it.

**Mask:** a BFS over road cells from all seeds in or near the tile (tile + margin): admin seeds, plus every Domain
`Location` that has a road cell within 8 blocks, plus `Boundary` nodes of already-built neighbouring tiles. Seeding
instead of scanning every column means a gravel beach or a cobblestone roof nowhere near a road is never picked up.
Capped at `max-cells-per-tile`; hitting the cap is a warning ("possible leak") listed with its location.

### 5.2 Snapshot capture

On the main thread, `ChunkSnapshot`s of the chunks the BFS actually reaches, a few per tick. Chunks load with
`getChunkAtAsync`; nothing is loaded synchronously.

### 5.3 Centreline (thinning)

1. **Height layers.** Split the mask into layers where one (x, z) column holds more than one road cell (a bridge over a
   road, a road over a tunnel): cells connected with |Δy| ≤ 1 stay in one layer. Almost the whole world is one layer.
2. **Distance transform** per layer: each cell's distance to the nearest non-road cell (BFS from the border). Gives
   width (`2 × dt`) and centre-seeking weights.
3. **Thinning** per layer: Zhang-Suen on the (x, z) projection, keeping each cell's y. Result: a 1-cell-wide centreline
   that follows the middle of wide roads and stays exactly on 1-wide paths.

### 5.4 From centreline to graph (what replaces manual node logging)

1. **Classify** every centreline cell by its number of centreline neighbours: **1 = endpoint, 2 = along the road,
   ≥ 3 = junction candidate** — the same rule GTA V's tooling uses for junctions and the standard GIS rule.
2. **Cluster junctions.** Wide crossings give a small cloud of junction cells; merge those within
   `junction-cluster-radius` into one `Junction` node at the cell nearest the cloud's centroid.
3. **Prune spurs.** A branch that ends in an endpoint and is shorter than `max(min-spur-length, local road width)` is
   thinning noise from a road's corner or a doorway notch; drop it and reclassify its junction.
4. **Plazas.** Areas with `dt > plaza-width / 2` (town squares made of road blocks) thin into loops and star shapes.
   Every centreline branch leaving a plaza is joined to one `Junction` at the plaza's centre, so a square becomes one
   node where its streets meet.
5. **Edges** are the centreline chains between nodes. Record `Length` from the raw chain, `AvgWidth` from `dt`,
   `RoadClass` = majority class of the chain's cells, then RDP (ε = 0.75) for `Geometry`.
6. **Tile borders.** Chains that leave the tile end at a `Boundary` node on the border (§5.6).

Admin `Anchor` nodes are honoured: the chain through an anchor is split there.

### 5.5 Stable ids across rebuilds

A rebuild must not throw away admin work (names, street labels, flags). `NodeMatcher` matches each new node to an old
one of the same tile within 3 blocks (greedy nearest match is enough); matched nodes keep their id, name and
lock. An edge keeps its id and admin fields when its matched node pair is unchanged and its new polyline stays within
2 blocks of the old one. `Locked` nodes don't move; the builder snaps the chain to them. Unmatched old detected
nodes/edges are deleted; the build summary lists what disappeared so an admin can check a road wasn't broken by a builder.

### 5.6 Tiles, borders and components

- Each tile is built from its own area plus a `tile-margin` of context, so the centreline across a border is identical
  whichever side is built first. A chain crossing the border gets a `Boundary` node at the crossing cell; the
  neighbouring tile's build matches it by position.
- After a tile build, the API recomputes **component ids** for the world (a union-find over nodes and edges; thousands
  of nodes, milliseconds). Routing fails fast when start and goal are in different components, as GTA SA does.

### 5.7 Keeping up with the world

- `RoadDirtyTracker` listens to `BlockPlaceEvent`, `BlockBreakEvent`, explosions and piston moves; if the block is in the
  palette, or is the air above a road cell, it marks the tile dirty (batched every 30 s). The tile's edges become
  `Stale` (still routable) and the admin overview lists it.
- WorldEdit/FAWE edits don't fire Bukkit block events, so a WorldEdit `EditSessionEvent` hook marks the edited
  region's tiles dirty (Phase 3, when WorldEdit is present).
- v1: rebuilds are admin-triggered (`/knk road build dirty`). Automatic rebuilds after a quiet period are Phase 6.

### 5.8 Recorded edges (what blocks can't express)

`/knk road record start` samples the admin's position every 10 ticks while they walk from one node to another;
`/knk road record stop [street]` snaps both ends to the nearest nodes (creating `Anchor`s if needed) and stores a
`Recorded` edge. This covers wooden bridges, tunnels, fords and grass paths without widening the palette. Recorded
edges survive rebuilds.

### 5.9 Street labels (inferred, then reviewed)

Every V3 Structure already has a `StreetId` and a `Location` by its door. `StreetLabeler`:

1. **Votes:** each Structure with a Location votes for its street on the nearest edge within 16 blocks (weighted by
   1 / distance).
2. **Assign** each edge the street with a clear majority (≥ 60% of the vote weight).
3. **Continue through junctions:** an unlabelled edge inherits the street of the edge it continues most straightly at a
   junction (smallest bearing change, < 35°, same road class), repeated until nothing changes — how a street "runs
   through" a crossing.
4. Conflicts (two streets with similar weight) and edges with no label are listed in the build summary; unnamed
   wilderness roads simply stay unlabelled.

Admins override with `/knk road street <street>` (sets `StreetSource = Manual`, never overwritten).

### 5.10 Known edge cases

| Case | Handling |
|---|---|
| Plaza or square of palette blocks | §5.4 step 4: one junction at its centre. |
| Two parallel roads touching (an avenue with a median) | Corner rule stops corner leaks; if they touch along a side they become one wide road, which is fine for routing. |
| Bridge over a road | Separate height layers (§5.3); no false junction. |
| Gaps (doorway, wooden bridge, ford) | No connection → separate components; the summary lists close-by endpoints of different components ("gap of 4 blocks at …") so an admin can add the material or record the edge. |
| Palette leaks into buildings (cobblestone floors) | Doorways usually break the mask; otherwise the cell cap warns, and `palette-exclude` or a spur/plaza rule contains it. |
| Detector misses or over-splits a junction | Review: `node merge`, `node anchor`. |

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
| bare `<name>` | Searched across all of the above; one match → go; several → list `type:name` choices (teleport's `WarpTargets` behaviour). |

A domain without a `Location` falls back to `region` automatically; with neither it is refused with a clear message.
Resolution reuses teleport's `WarpTargets`/`SpawnPointResolver` (on `claude/teleport`, KNG-17). Unlike `/warp`, a
destination does **not** need `TeleportEnabled`: navigating is walking. `AllowEntry = false` is allowed with a warning
(§9 Q4). Structures need a second lookup for their `Location` (`StructureDto` only has `locationId`).

### 6.2 Route computation (async)

1. Resolve the destination to a point, or a **set** of goal points (region mode, §6.3).
2. **Snap** the player and the target to the nearest edge segments within `max-snap-distance` (grid-bucket
   `SegmentIndex`), project, and split the edges with `Virtual` nodes.
3. **Direct mode** when nothing is within snap distance, when the snapped points are in **different components**
   (instant check), or when the straight-line distance is shorter than both snap distances together: a straight trail
   toward the target, recomputed as the player moves (GTA's "custom route").
4. **A\*** with cost `Length × classCost × CostMultiplier`, Euclidean heuristic scaled by the cheapest class cost (keeps
   it admissible). Skipped: `NoGps`, `Closed`, wrong-way `Oneway`, and **edges through a closed gate** — any edge whose
   polyline passes through the region of a `GateStructure` that is currently closed (read from the gate runtime), the
   way GTA scripts switch roads off in an area. A siege-locked town is therefore routed around, or reached up to its
   gate.
5. Build the `Route`: off-road leg (player → snap point), road legs (polylines, reversed where traversed To → From,
   trimmed at the virtual nodes), off-road leg to the target; maneuvers (§6.5); ETA `length / sprint-speed`.

Target: < 5 ms for a few thousand nodes; the network snapshot is immutable, so routing runs on any thread.

### 6.3 Closest point of a region

For `town:Kardenna region`, the goal is where the road reaches the region, not its centre.

- Polygonal region: `ProtectedPolygonalRegion.getPoints()` + min/max Y; cuboid: min/max corners → a Bukkit-free
  `RegionShape` in knk-core.
- Goals = every network point **inside** the region (edge segments clipped to the polygon), or, if none, the network
  point closest to the polygon. A\* runs multi-goal (heuristic = distance to the polygon) and stops at the first goal:
  the route ends where the road enters the region, which is the natural "arrival" at a town gate.
- Already inside: "You are already in Kardenna."

### 6.4 Guidance

- **Trail:** every `trail-period-ticks`, project the player onto the route and draw the next `trail-length` blocks with
  `Player#spawnParticle` (only they see it), one particle every ~1.5 blocks at standing height + 0.2, `DUST` in the
  configured colour; off-road legs sparser and a different colour.
- **Boss bar:** `"→ Merchantstreet · 340 m · ~1 min"`, progress = travelled / total; within 20 blocks of a turn the
  next maneuver replaces it (`"Turn left onto Merchantstreet"`).
- **Action bar:** an arrow (`⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉`) from the player's yaw to the trail point ~6 blocks ahead, for players
  with minimal particles.
- **Re-route:** more than `reroute-distance` off the route for `reroute-after-ticks` → recompute (max once per 3 s),
  "Recalculating…".
- **Arrival:** within `arrive-distance` (or inside the region) → sound + `"You have arrived at Kardenna Market."`.
- **Ends** on quit, death, world change, teleport (> 16 blocks), joining a siege match, or `max-session-minutes`. One
  session per player; a new `/navigate` replaces the old.

### 6.5 Maneuvers

At each route node that is a `Junction`, or where the street label changes: Δ = bearing after − bearing before (from
~6 blocks of polyline each side). Bands: < 20° straight (announced only on a street change: "Continue onto …"),
20-60° slight, 60-120° turn, > 120° sharp; sign gives left/right. Unlabelled edges: "Take the path on the left".

### 6.6 Events

`NavigationStartEvent` (cancellable), `NavigationRerouteEvent`, `NavigationArriveEvent`, `NavigationEndEvent` (reason).
Later consumers: transport quests, tutorial steps, discovery, bandit ambushes on long routes.

---

## 7. Admin tooling

In-game (`knk.admin.roads`), direct commands in the `GateDoorRegionCaptureHandler` style (no WorldTask):

| Command | Does |
|---|---|
| `/knk road build here` / `build tile <x> <z>` / `build radius <r>` / `build dirty` / `build all` | Builds tiles (§5), progress in the action bar, then a **build summary** in chat: nodes/edges, disappeared nodes, unlabelled/conflicting streets, suspected leaks, component gaps — each with a clickable teleport to the spot. |
| `/knk road seed add [note]` / `seed remove` / `seed list` | Seeds for roads no domain touches. |
| `/knk road show [radius]` / `hide` | Overlay: nodes as particle pillars by kind, edges as lines coloured by street, unlabelled grey, stale orange, closed red, tile borders faint; looking at a node or edge shows its id, kind, street, class in the action bar. |
| `/knk road street <street> [edgeId]` | Label the edge under you (or by id), `Manual`. |
| `/knk road node name <name>` / `node merge <id> <id>` / `node anchor` / `node lock` | Review fixes. |
| `/knk road record start` / `stop [street]` / `cancel` | Recorded edges (§5.8). |
| `/knk road edge set <id> class <c>` / `cost <x>` / `oneway` / `nogps` / `close` / `open` | Tuning. |
| `/knk road tiles` | Tile overview: built, dirty, warnings. |

Typical session: `/knk road build radius 1500` around Kardenna, look at the summary, `/knk road show`, fix two street
labels and one gap, done. No coordinates are typed or logged.

Web app (admin, Phase 5): tile overview, Street detail with its edges and total length, edge table with class/cost/
flags/street editing, build warnings. No map in v1.

---

## 8. Implementation phases

Each phase is independently mergeable and testable without a live server except where noted.

| Phase | Repo | Contents | Tests |
|---|---|---|---|
| 0 | workspace | Developer answers §9 (every question has a default). | — |
| 1 | web-api | `RoadTile`, `RoadSeed`, `RoadNode`, `RoadEdge`, enums, migration `AddRoadNetwork`, `RoadNetworkService` (tile replace with id matching, component ids), controllers (§3.6), `StreetDto` counts. | Service/validation unit tests; fresh-DB migration CI. |
| 2 | plugin core | `core/roads/build/` (mask, distance transform, layered thinning, degree classification, junction clustering, spur/plaza rules, node matching, street labelling, RDP) and `core/roads/route/` (graph, snapping, A\*, components, maneuvers, region closest point). All Bukkit-free. | Golden tests on synthetic `SurfaceGrid`s: meandering 1-wide path, 5-wide road, T, X and 5-way junctions, plaza, stairs up a hill, bridge over a road, gap, cobblestone-floor leak (capped), tile-border continuity, rebuild keeps ids and labels. Router: shortest path, class costs, oneway, closed/NoGps, closed-gate avoidance, components fail fast, region multi-goal. |
| 3 | plugin paper | `ChunkSnapshotSurfaceGrid`, `RoadBuildJob`, `RoadNetworkCache`, `RoadDirtyTracker` (+ WorldEdit hook), `/knk road …`, overlay. API client + mapper. | Contract test against Phase 1; **live:** build the tiles around one real town and review the result on the dev server. |
| 4 | plugin paper | `/navigate`, `DestinationResolver` (after KNG-17 merges), `NavigationService`, trail, boss/action bar, gate closures, events, config. | Session state-machine tests in core; **live** checklist: Location, Town spawn, Structure, region edge, street; re-route; arrival; closed gate; auto-end on death/teleport/siege. |
| 5 | web-app | Tile overview, street road panel, edge table. | Component tests. |
| 6 (later) | all | Automatic rebuild of dirty tiles after a quiet period; "follow road" mode without a destination (fork choices at junctions, as in KCD/Witcher/RDR2); off-road legs with Pathetic; NPC routing (Carrier/transport quests); ETA per travel mode and terrain/risk modifiers; treasure-map/radar items reusing the trail; discovery-gated destinations; 2D web map. | — |

**Dependencies:** Phase 4 depends on KNG-17 (teleport) reaching trunk. Phases 1-3 depend on nothing in flight. Gate
closure (Phase 4) reads the gate runtime read-only; nothing here changes siege code.

**Rough size:** Phase 1 M, Phase 2 L (the builder is the novel part; rev. 2 moves effort from admins to code), Phase 3
M, Phase 4 M, Phase 5 S.

---

## 9. Open questions (recommended default in bold)

1. **Road palette and classes.** Which blocks are the V3 world's roads built from, and which count as main road vs
   path? Legacy only names "gravel, slabs" (iPhone notes 164). **Default: the §4 mapping, tuned after the first build
   around one town; plugin `config.yml`.**
2. **Seeding.** Seed automatically from every Domain `Location` near a road? **Yes**, plus admin seeds for roads no
   domain touches.
3. **Domain destination default.** **`Location` when set, else region; the `region` keyword forces the region.**
4. **Restricted or undiscovered destinations.** **Allowed, with a warning for `AllowEntry = false`; no discovery
   gating in v1** (a per-domain flag later, like `TeleportRequiresDiscovery`).
5. **Closed gates close roads.** Route around (or up to) a closed gate? **Yes** — it matches the siege theme and costs
   little.
6. **Off-road legs.** **Straight-line hint in v1**; Pathetic in Phase 6.
7. **Trail visibility.** **Only the navigating player.**
8. **Street labels from Structures.** Infer street names from the Structures along a road, with admin override?
   **Yes.**
9. **Priority.** **Post-siege-MVP**; Phases 1-2 can run in parallel with siege work (no shared files).
10. **Missing source note.** The street begin/end/intersection idea isn't in the transcribed iPhone notes (first
    research report §3). Rev. 2 no longer needs manual logging, so this only matters for history. **Default: proceed.**
