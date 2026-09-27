# How open-world games build road navigation — research for KnK road navigation

**Status:** Research complete; conclusions applied to [specs/navigation/DESIGN.md](../specs/navigation/DESIGN.md) (rev. 2)
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-street-road-graph-endpointsintersections-traced-road)
**Follows:** [2026-09-27-road-navigation-research.md](2026-09-27-road-navigation-research.md) (legacy scan + algorithms)

The developer's question: studios behind Red Dead Redemption 2 and Assassin's Creed Origins/Odyssey/Shadows clearly
don't log every road's begin, end and intersection by hand. How do they do it, and what does that mean for Knights and
Kings, whose roads are already built out of blocks?

**Source quality.** Rockstar and Ubisoft have published almost nothing on their road/GPS internals. What follows is:
**[confirmed]** published talks, articles, patents or official docs; **[RE]** community reverse-engineering (decompiled
code, modding tools); **[player]** player-level observation only; **[synthesis]** our own inference. Many pages
(gtamods, gdcvault, 80.lv, fandom) were blocked by the cloud proxy, so some claims rest on search excerpts; those are
marked. Check a source before quoting it in a spec.

---

## 1. Short answer

1. **Nobody hand-logs intersections.** Studios author a road's *intent* — a spline or road piece, its type, its speed —
   and the *topology* (where roads join, which nodes are junctions or dead ends) falls out of tooling:
   - Rockstar GTA III/Vice City: every road model carries its own little set of path nodes; at load time open ends
     within 1 unit of each other are merged, and a flood fill counts connected groups **[RE]**.
   - GTA V: a node counts as a junction when it has more than 3 distinct neighbours — **junction status is derived from
     node degree**, not tagged **[RE]** (CodeWalker's reconstruction of the format).
   - Ghost Recon Wildlands: a road pathfinder makes *following an existing road* very cheap, so new roads find and
     branch off old ones; junctions exist by construction **[confirmed]**.
2. **Roads are a separate, simpler layer from character navigation.** Characters use an auto-generated navmesh; travel
   and GPS use a road graph of nodes + links with flags **[confirmed/RE]**.
3. **The road graph carries flags per link/node, not just geometry** — road type, speed, "don't use for GPS",
   switched-off (closed), dead-end, junction, street name **[RE]**. Scripts can switch roads off in an area, and the GPS
   routes around them.
4. **Guidance is simple:** snap to the nearest node, run a plain shortest-path search, draw a polyline, give
   left/right at junctions, recalculate when off-route; off-road legs are a straight line **[RE]**.
5. **For KnK, the voxel world is already a "raster" of roads**, which is exactly what GIS road extraction works on:
   road mask → thinning to a centreline → a centreline cell with 3+ neighbours is a junction, 1 neighbour is an
   endpoint → chains between them are edges. **Admins then confirm, name and fix exceptions instead of logging
   coordinates [synthesis].** This replaces the manual-node step of design rev. 1.

---

## 2. Rockstar (RAGE: GTA III → GTA V, RDR2)

### 2.1 Data **[RE]**

- **GTA V `.ynd` path files** (from [CodeWalker `YndFile.cs`](https://github.com/dexyfex/CodeWalker/blob/master/CodeWalker.Core/GameFiles/FileTypes/YndFile.cs)
  and [`Space.cs`](https://github.com/dexyfex/CodeWalker/blob/master/CodeWalker.Core/World/Space.cs)):
  - The world is a **32 × 32 grid of 512 × 512 m cells**, one file per cell (`AreaID = y*32 + x`).
  - Nodes: area/node id, compressed position, street-name hash, flags `OffRoad`, `NoBigVehicles`, `SlipRoad`, `NoGps`,
    `IsJunction`, `Highway`, `Tunnel`, density 0-15, `DeadEndness`, speed class; special types such as stop sign,
    traffic-light stop, pedestrian crossing, `OffRoadJunction`.
  - Links: target node, length, `GpsBothWays`, `NarrowRoad`, lane counts/offset, `DontUseForNavigation`, `Shortcut`.
  - Pedestrians mostly use a separate navmesh (`.ynv`).
  - CodeWalker's `CheckIfJunction()` marks a node a junction when it has **> 3 distinct non-shortcut neighbours**, and
    derives `DeadEndness` and a heuristic value from the graph.
- **Runtime flags visible to scripts** (FiveM native docs, [`GET_VEHICLE_NODE_PROPERTIES`](https://github.com/citizenfx/natives/blob/master/PATHFIND/GetVehicleNodeProperties.md)):
  `OFF_ROAD`, `SWITCHED_OFF`, `TUNNEL_OR_INTERIOR`, `LEADS_TO_DEAD_END`, `HIGHWAY`, `JUNCTION`, `TRAFFIC_LIGHT`,
  `GIVE_WAY`, `WATER`. Roads can be switched off by area
  ([`SET_ROADS_IN_AREA`](https://github.com/citizenfx/natives/blob/master/PATHFIND/SetRoadsInArea.md)); nearest-node
  lookup can skip switched-off nodes ([`GET_CLOSEST_VEHICLE_NODE`](https://github.com/citizenfx/natives/blob/master/PATHFIND/GetClosestVehicleNode.md)).
- **GTA III / Vice City — the closest precedent to our problem** ([re3 `PathFind.cpp`](https://github.com/SugaryHull/re3/blob/master/src/control/PathFind.cpp),
  `PreparePathDataForType`): path nodes belong to road *models* (up to 12 per piece, internal or external). At load time
  each external node merges with the nearest unconnected external node of another piece within 1 unit, and
  `CountFloodFillGroups` labels connected components. A junction piece brings its own node layout; **the network
  assembles itself from the placed pieces.** GTA SA/IV compile this offline into 64 area files
  ([gtamods Paths (GTA SA)](https://gtamods.com/wiki/Paths_(GTA_SA)), [Paths (GTA4)](https://gtamods.com/wiki/Paths_(GTA4)) — search excerpts only).
- **How GTA V/RDR2 nodes are authored is not public.** A Rockstar developer is quoted as saying the world is hand-made
  with *"procedural tools that are all curated by the artists"*
  ([wccftech](https://wccftech.com/red-dead-redemption-2-procedural-limits/), excerpt only).
- **Patent [confirmed]:** Take-Two [US11071916](https://patents.google.com/patent/US11071916) describes low-level road
  nodes with attributes (speed, lane width, highway, lane count) grouped into a coarser graph for long-distance routes.

### 2.2 GPS **[RE]**

- GTA SA's `DoPathSearch` ([gta-reversed `PathFind.cpp`](https://github.com/gta-reversed/gta-reversed/blob/master/source/game_sa/PathFind.cpp)):
  snaps both ends to the nearest node (`FindNodeClosestToCoors`), **fails immediately if they have different
  flood-fill group ids** (precomputed connected components), then runs a bucketed Dijkstra from target to origin over
  integer link lengths, only through loaded areas (~350 units around the player). A community GPS mod calls it every
  radar frame, capped at 2,000 nodes ([plugin-sdk GPS example](https://github.com/DK22Pac/plugin-sdk/blob/master/examples/GPS/Main.cpp)).
- GTA V directions: [`GENERATE_DIRECTIONS_TO_COORD`](https://github.com/citizenfx/natives/blob/master/PATHFIND/GenerateDirectionsToCoord.md)
  returns the next instruction (left/right/straight), distance to the next junction, and "recalculating/off-route"
  states. [`START_GPS_MULTI_ROUTE`](https://github.com/citizenfx/natives/blob/master/HUD/StartGpsMultiRoute.md) routes
  through via-points along roads; [`START_GPS_CUSTOM_ROUTE`](https://github.com/citizenfx/natives/blob/master/HUD/StartGpsCustomRoute.md)
  draws straight lines that ignore roads (the off-road fallback).

### 2.3 RDR2

- Same path-node API as GTA V in the [RDR3 native DB](https://github.com/alloc8or/rdr3-nativedb-data) **[RE]**, plus
  `_IS_PATH_FOR_GPS_ON_ROAD` ("is the GPS route to the waypoint navigable along a road"),
  `_GET_PLAYER_MOUNT_IS_SPRINTING_ON_ROAD`, `TASK_MOVE_FOLLOW_ROAD_USING_NAVMESH`, GPS-disabled zones and road speed
  zones. Dirt roads and trails are most likely ordinary path nodes with off-road/narrow flags **[synthesis]**.
- Horse "cinematic" auto-travel: with a waypoint set, the horse follows the GPS route along roads and trails; it only
  engages when already on the route, and stick input cancels it **[player]**
  ([GameSpot](https://www.gamespot.com/articles/red-dead-2-guide-heres-how-to-set-your-horse-to-fo/1100-6462864/),
  [rdr2.org](https://www.rdr2.org/guides/red-dead-redemption-2-horse-autopilot-guide/)). No technical source.

---

## 3. Ubisoft and other open worlds

### 3.1 Road authoring **[confirmed, from article excerpts]**

- **Ghost Recon Wildlands** (Houdini): "thousands of kilometres of roads" made by a procedural road builder. The road
  pathfinder penalises steep slopes and tight turns (roads wind up mountains) and makes **following an existing road very
  cheap, so new roads branch off existing ones** — junctions come for free. Results are baked into heightmaps/masks.
  ([80.lv](https://80.lv/articles/procedural-technology-in-ghost-recon-wildlands),
  [80.lv world building](https://80.lv/articles/procedural-world-building-in-ghost-recon-wildlands),
  [GDC 2017](https://www.gdcvault.com/play/1024029/-Ghost-Recon-Wildlands-Terrain)). Based on Galin et al. 2010,
  *Procedural Generation of Roads* — weighted anisotropic shortest paths over slope/river/forest costs
  ([PDF](https://perso.liris.cnrs.fr/egalin/Articles/2010-roads.pdf)).
- **Assassin's Creed Origins** (Anvil): roads are splines on the terrain, adjusted per point; Houdini places content
  procedurally ([80.lv](https://80.lv/articles/building-the-world-of-assassins-creed-origins)). **Nothing public** on
  Odyssey/Valhalla/Shadows road authoring or their GPS graph.
- **Far Cry 5** (Dunia + Houdini): road splines clear vegetation, drive biome painting and carry metadata such as fence
  type ([GDC 2018](https://www.gdcvault.com/play/1025557/Procedural-World-Generation-of-Far),
  [80.lv](https://80.lv/articles/houdini-procedural-world-generation-of-far-cry-5)).
- **Horizon Zero Dawn:** runtime rule-based placement; "redirecting roads" is cheap because everything around a road
  regenerates ([Guerrilla](https://www.guerrilla-games.com/read/gpu-based-procedural-placement-in-horizon-zero-dawn)).
- **The Witcher 3:** REDkit has a road-creation workflow and automatic navmesh generation
  ([video](https://www.youtube.com/watch?v=DUFFtyjd9kY),
  [REDkit wiki](https://cdprojektred.atlassian.net/wiki/spaces/W3REDkit/pages/16351233)); not readable from here.

No public source explains how any of these turns splines into the GPS graph.

### 3.2 Guidance and mounts **[player]**

- **AC Origins:** hold to "follow road", or auto-travel to a map marker; a white path line shows the way
  ([Steam](https://steamcommunity.com/app/582160/discussions/0/1480982971169652821/)). **Odyssey:** separate "follow
  road" and "go to objective" ([supercheats](https://www.supercheats.com/assassins-creed-odyssey/walkthrough/horse-travel)).
  **Valhalla:** the horse rides to the minimap destination, with a mark in front of the horse showing the path
  ([game8](https://game8.co/games/Assassins-Creed-Valhalla/archives/306100)).
- **The Witcher 3:** hold canter without steering and Roach follows the road
  ([Steam](https://steamcommunity.com/app/292030/discussions/0/613958868356103275/)).
- **Kingdom Come: Deliverance:** hold sprint on a track and the horse autopilots; **the player steers at forks and
  crossroads** — the horse follows the current road segment and leaves junction choices to the player
  ([forum](https://forum.kingdomcomerpg.com/t/just-learned-a-thing-horse-follows-roads/47698)).
- **Breath of the Wild:** horses follow roads; every area is reachable by main road or off-road, and main roads are
  deliberately lowered and meandering
  ([Radiator blog](https://www.blog.radiator.debacle.us/2017/10/open-world-level-design-spatial.html),
  [Kotaku](https://kotaku.com/breath-of-the-wilds-biggest-design-secret-lots-of-tria-1819113140)).
- **Mount & Blade: Bannerlord:** campaign-map pathing prefers roads because terrain speed modifiers make them faster
  ([wiki](https://mountandblade.fandom.com/wiki/Bannerlord_Online/Travel_speed_(Map_speed))).
- **AC Odyssey Exploration mode** gives verbal directions (region + compass direction) instead of markers
  ([Game Developer](https://www.gamedeveloper.com/design/less-is-still-less-ac-odyssey-s-exploration-mode-and-time-wasters))
  — relevant to the vision's "lonely wilderness" feel.

### 3.3 Architecture and tooling

- **Two layers:** an auto-generated navmesh for characters — Recast voxelises geometry and filters walkable spans into
  regions, contours and polygons ([recastnavigation](https://github.com/recastnavigation/recastnavigation)) — and a
  separate road graph for vehicles/GPS (Rockstar sources above). Recast also rebuilds **per tile** when geometry
  changes, which is the model for incremental road rebuilds below.
- **Hierarchy only at scale:** HPA\* (clusters with precomputed entrance costs, ~10× faster, within 1% of optimal)
  ([Botea et al.](https://www.semanticscholar.org/paper/Near-Optimal-Hierarchical-Path-Finding-Botea-M%C3%BCller/b0f0432ba69e4d730b93a75e3d19c8e9d811efac))
  and Rockstar's coarse graph in the patent. KnK's graph is far too small to need it.
- **Raster-to-graph extraction (GIS):** thin the road mask to a 1-pixel skeleton; > 2 skeleton neighbours = junction,
  exactly 1 = endpoint; prune spurs; simplify
  ([ISPRS 2021](https://www.sciencedirect.com/science/article/abs/pii/S0924271621001490),
  [arXiv 1909.10173](https://arxiv.org/pdf/1909.10173)).
- A research agent also reported a May 2026 paper validating navmeshes against voxelised walkable space on Anvil and
  Unity scenes (arXiv 2605.21397); **not verified** — check before citing.

### 3.4 Medieval design notes

- KCD's codex: trade routes had fords, bridges, inns, signposts and milestones; people travelled in groups because of
  bandits ([wiki](https://kingdom-come-deliverance.fandom.com/wiki/Travel_and_Trade_Abroad)). Players miss signposts at
  KCD's crossroads ([forum](https://forum.kingdomcomerpg.com/t/road-signs/63312)).
- Fits KnK's vision of unlit, dangerous wilderness roads (concept v0.2, 2020) and the ambush-risk idea (iPhone notes 297).

---

## 4. What changes for Knights and Kings [synthesis]

The AAA studios' problem is the reverse of ours — they *author* roads and generate geometry; our roads already exist as
blocks. But the lesson carries over directly: **derive topology, let humans author only intent and exceptions.** In a
voxel world, the road blocks are the raster that GIS extraction works on.

| AAA practice | KnK equivalent (applied in DESIGN rev. 2) |
|---|---|
| Junction = node with > 3 neighbours (GTA V); network assembles from pieces (GTA III) | Road mask → centreline (thinning) → **junctions and endpoints detected by neighbour count**; admins confirm/name, don't log. |
| Per-area files, 512 m grid (`.ynd`); Recast per-tile rebuild | Road network built and stored per **512 × 512-block tile**; a tile is rebuilt when road blocks in it change. |
| Flood-fill group ids; route fails fast if not connected (GTA SA) | **Connected-component id** per node; `/navigate` knows instantly when no road connects start and goal and falls back to a direct trail. |
| Link/node flags: road type, speed, NoGps, switched off, dead end, street name | Edge **road class** from the dominant block material (stone road / gravel / dirt path), `NoGps`, `Closed`, `Oneway`, street label. |
| `SET_ROADS_IN_AREA` (scripts close roads) | **Closed gates close their road**: an edge passing through a closed GateStructure is excluded at routing time — a natural siege tie-in. |
| Street-name hash per node | **Street labels inferred** from data we already have: every Structure has a `StreetId` and a door-side `Location`; nearby edges take the majority street, which then continues straight through junctions. Admins fix conflicts. |
| Snap to nearest node, Dijkstra/A\*, left/right at junctions, recalculate off-route; straight "custom route" off-road | Unchanged from rev. 1. |
| KCD/Witcher/RDR2 "horse follows road, you choose at forks" | Later mode: **"follow road"** guidance without a destination (trail continues along the current road, fork choices shown at junctions). |

**Admin effort, before and after:**

- Rev. 1: record every street's begin, end and intersection by hand, then trace.
- Rev. 2: nothing for the normal case — the build seeds itself from every Domain's Location (town squares, gates and
  structures sit on roads) plus any seed an admin adds for a disconnected road. Admins review an overlay, name what the
  inference couldn't, merge or split the occasional junction, and record the stretches the palette can't follow
  (wooden bridges, tunnels, grass paths).
