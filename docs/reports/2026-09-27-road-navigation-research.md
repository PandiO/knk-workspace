# Road navigation & pathfinding — research findings

**Status:** Research complete; design drafted in [specs/navigation/DESIGN.md](../specs/navigation/DESIGN.md)
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-street-road-graph-endpointsintersections-traced-road) (road navigation: street road graph + `/navigate`)
**Scope:** read-only scan of `knk-workspace/docs`, `knk-v1-archive`, `knk-v2-archive`, the three V3 repos
(`knk-plugin` `fda4373`, `knk-web-api` `d0bac59`, `knk-web-app` `4d8ebfc`, plus the unmerged `claude/teleport` and
`claude/domain-discovery` branches), the two archive Word documents (via their transcriptions, see §3), and published
road-extraction / routing / Minecraft pathfinding work (§5).

The question: the developer remembers designing a navigation system on top of **Street** entities and the **block types
roads are built from**, where street begin/end points and intersections are logged as data points, an algorithm follows
the physical road blocks between them (roads meander "like veins or roots"), and a pathfinder routes a player from A to B
along the roads, for example `/navigate <destination>` with a particle trail. What exists already, what did legacy build,
and what published techniques fit?

---

## 1. Summary

1. **No legacy road system exists in either archive.** V1 has one generic block-level A\* prototype
   (`src/PathFinding/PathFinder.java`, reachable only through the debug command `/test ai`, with inverted walkability
   logic) and a tutorial line saying *"the developer of this game still didn't invent Navigation"*. V2 has no
   pathfinding at all. Neither archive stores street coordinates, begin/end points, intersections or a road-block list.
   Both archives were searched completely, including V2's git history (V1 is a single import commit). **The street/
   intersection/road-tracing design the developer remembers was never committed**; if code existed, it lived on a
   machine or branch that is not in either archive.
2. **The only written trace of the road-block idea** is a 2019 note on the V1 NPC *Carrier* trait: *"Carriertrait gaat
   nog niet via voorgestelde blocktypes (gravel, slabs etc.)"* ("the Carrier trait doesn't follow the proposed block
   types yet"). So road-following was first wanted for **NPCs** (goods carriers), before player navigation.
3. **V3 Streets are addresses only.** `knk-web-api` `Models/Street.cs` has `Id`, `Name`, `Districts`, `Structures`, and
   no geometry. The plugin has a read-only street client that nothing uses except a debug command. The design has to
   add a road graph from scratch, but everything a `/navigate` command needs **around** the graph already exists or is
   on the teleport branch (destination parsing, Location resolution, a Bukkit-free block probe, a tick-budgeted flood
   fill, per-viewer particles).
4. **Vision is aligned.** `vision/vision.md` §2.4 already defines Streets as *"a navigable address and wayfinding
   system"* for players and NPCs, running across Districts/Towns/Provinces/Kingdoms with no required parent. The 2020
   concept doc describes roads that *"meander through the landscape and forests"*, unlit in the wilderness, with
   bridges, wells and statues along them. So the road graph must cope with long, winding, irregular roads.
5. **Recommended technique** (§5.5): admin-recorded nodes (endpoints, intersections), then **node-seeded region growing
   over road blocks** (each node grows "roots" along the road until they meet another node's roots, which means the two
   nodes are adjacent), then a **centerline-seeking A\*** restricted to road blocks to get the edge polyline, then
   Ramer-Douglas-Peucker compression. At runtime, snap the player to the nearest edge, run plain A\*, and render a
   per-player particle trail for the next ~30 blocks. Contraction hierarchies, HPA\* and Jump Point Search are
   overkill at KnK's scale.

---

## 2. Workspace docs (what was already written)

| Doc | Relevant content |
|---|---|
| `vision/vision.md` §2.1, §2.4 (lines 31, 60-62) | Hierarchy `Kingdom → Province → Town → District → Street (cross-cutting) → Structure`. Streets exist *"primarily to give players and NPCs a navigable address and wayfinding system, not to own a region or to gate access"*; may cross Districts, Towns, Provinces, Kingdoms; no required parent (a deliberate change from v1). `docs/vision.md` is a second, older copy with the same §2.4 text. |
| `archive/vision-history/concept-v0.2-2020.md` lines 73-79, 142-144 | Towns and kingdoms *"connected with each other by roads and paths in a manner that aligns with the way it used to be in the middle ages"*; roads *"meander through the landscape and forests"*; wilderness roads unlit, lit only near towns; streets contain *"an occasional well, bridge, statue"*; districts are *"useful for navigation in larger towns"*; resource structures outside towns *"connect back via paths"*. |
| `vision/source-notes-iphone.md` | See §3.1. |
| `specs/legacy/towns-districts-gates.md` lines 11, 16, 29, 60, 92, 110 | V1 `Street(ID, Name, TownID)`, `TownID = 1` is a wilderness sentinel; V2 Street is standalone, many-to-many with District, *"a named road/path with no region of its own"*; Gate belongs to a Street. |
| `specs/legacy/commands-v1.md` §7 (876-900), line 1598 | `/street set|remove|list` only; the dev command `/test ai` ran `PathFinder` between two spawnpoints and replaced the path with glass. |
| `specs/legacy/commands-v2.md` 150-160 | V2 `/street list|fetch|save|remove|edit|seed` (`seed` is an empty stub). |
| `specs/reconcile/RECONCILE_STREET.md`, `specs/api/API_CONTRACT_STREET.md` | Street MVP is read-only in the plugin; no legacy street business rules; no geometry in "future work". |
| `specs/user-features/COMMAND_CATALOG_V3.md` 234-239, 704 | Street commands in V3 are debug-only. |
| `specs/teleport/DESIGN.md` (KNG-17) §3.2, §3.4.2, §3.6, §3.7 | `/warp <domain>` with case-insensitive names and `type:name` disambiguation; `SafeLocationFinder` over a `BlockProbe` port; `/spawn` resolving a Location/Town/District/Structure; domain destination rules (`TeleportEnabled && LocationId != null && AllowEntry`). **The template for `/navigate` destination parsing.** |
| `specs/domain-discovery/DESIGN.md` (KNG-20) §1.3 | Region→domain resolution; `Domain.WgRegionId` has no unique index. Relevant if navigation should only offer discovered destinations. |
| `specs/terrain/terrain-specs.md` | Not relevant (reference locations for waterfalls/castles, 2020). |
| `backlog/` | `epics/` and `stories/` are empty; nothing on streets or navigation in `QOL_BUGFIX_BACKLOG.md`. |
| Linear | No existing issue mentions navigation, streets, roads or pathfinding (searched KNG-1…KNG-26). |

**Nothing** in the workspace described navigation, pathfinding, a road graph, a particle trail or `/navigate` before
this report.

---

## 3. The two archive Word documents

**Access note.** This session runs in a cloud container, so `D:\Shared\Werk\KnightsAndKings\archive\...` was not
reachable. Both documents were transcribed into the workspace on 2026-09-13/15 and were scanned in full from there:

- `KnightsAndKings_iphone_notes.docx` → `docs/vision/source-notes-iphone.md` (318 lines, labelled "raw, unedited";
  inventory in `reports/2026-09-15-smb-share-inventory.md` line 161: 34.1 KB).
- `iCloud drive export/Documents/Concept_KnightsAndKings_v0.2.docx` →
  `docs/archive/vision-history/concept-v0.2-2020.md` (the fullest of six concept variants; diff in
  `concept-variants-comparison.md`).

**Discrepancy to flag:** neither transcription contains the street begin/end/intersection design described in the
request. Either it lives in a note that is not in the 2026-09-13 export (a different Apple Notes note, or a newer one),
or the transcription dropped it. Worth a two-minute check of the original `.docx` and of Apple Notes on the phone; if
more text turns up, add it to `source-notes-iphone.md` and to DESIGN.md §2.

### 3.1 iPhone notes — every navigation-related line

| Line | Text (translated where Dutch) | What it means for the design |
|---|---|---|
| 14-15 | "3 minutes = 1000 blocks run; 30 minutes = 10,000 blocks" | ≈5.6 blocks/s = vanilla **sprint** speed (5.612 b/s). Use for ETA ("~3 min"). |
| 163 | "On fullchestEvent spawn an NPC with the Carrier trait" | Goods carriers walk between properties and warehouses. |
| **164** | **"The Carrier trait doesn't go via the proposed block types yet (gravel, slabs etc.)"** | **The origin of road-block routing**: NPCs were meant to follow road blocks. The only concrete road materials ever named are **gravel and slabs**. |
| 131 | "Store default locations outside shops and teleport players there" | Precedent for "a Location per structure" (V3 `Domain.Location`). |
| 140 | "Spawnpoints at useful buildings for donators, such as mines" | Destinations. |
| 272 | Transport quest: players can steal the carried chest | Transport quests move goods along routes. |
| **282** | **"For app/web app: find out how walkspeed works. Offer different travel methods and combine average speed with the distance of roads + a terrain modifier. Maybe simulate an attack when you meet bandits…"** | Road-graph **edge lengths** feed travel-time estimates; edges may carry a terrain modifier; a travel mode (walk/horse/cart) scales speed. The graph is a shared asset for the web app too. |
| 287, 289 | Minigame join conditions include whether the player discovered the town; a storyline limits discovering regions by time and title | Possible gating of navigation to discovered destinations (compare `TeleportRequiresDiscovery`). |
| 292-293 | Special item "radar" or "treasure map" giving hints toward items/treasures/quests nearby | A later consumer of the same guidance renderer. |
| **297-298** | **An algorithm for ambush probability for players and trade routes from time of day, distance to towns and order-keeping buildings (outposts, garrisons), and biome** | Edges can later carry a **risk** attribute; routing could offer "safest" vs "shortest". |

### 3.2 Concept v0.2 (2020)

Covered in §2 (lines 73-79, 142-144). Nothing algorithmic; it sets the **world constraints**: long meandering
inter-town roads, forests, bridges, unlit wilderness, towns split into districts for navigation.

---

## 4. Code scan

### 4.1 V1 (`knk-v1-archive`, raw JDBC over MySQL)

| File | What it is | Verdict |
|---|---|---|
| `src/PathFinding/PathFinder.java` (330 lines) | Generic weighted A\* over blocks. `f = g + 1.5 × euclidean3D`; 4 horizontal neighbours; step ±1 costs 1.414; falls up to `maxFallDistance` cost `2×drop`; optional ladders. Open/closed lists are `ArrayList`s scanned linearly (no priority queue). | **Prototype, broken.** `isObstructed()` returns true for *non*-solid blocks (L281-290), so walkability is inverted; start/end check uses `&&` for `||` (L56); world hard-coded to `getWorlds().get(0)` (L194); open-list nodes are duplicated (`getNode` only searches the closed list, L127-136); fall nodes never enter either list (L223-224). No road awareness at all: the only material it checks is `LADDER`. |
| `src/me/Pandi/Commands.java:392-414` | `/test ai`: paths from spawnpoint "point1" to "point2" and sets every path block to `GLASS` (destructive, never restored). | Debug only. |
| `src/Traits/CarrierTrait.java` (235 lines) | Citizens NPC trait: find the nearest town (WorldGuard `town` region or nearest town spawnpoint), pick a warehouse with chests, `npc.getNavigator().setTarget(propertySpawnPoint)`, and on `NavigationCompleteEvent` dump its inventory into the warehouse. Registered in `Main.java:319`; spawned by `/test npc` (`Commands.java:422`). | Works, but uses Citizens' generic navigator, so it ignores roads. **This is what note 164 is about.** |
| `src/Tutorial/IntroTutorial.java:39-41` | *"Since the developer of this game still didn't invent Navigation, You have to find Houses, Rooms and Properties by finding the right street and streetnumber … This can be a pain in the ass sometimes.."* | Confirms player navigation was wanted and never built. |
| `src/Streets/Street.java`, `src/Models/Street.java`, `src/DataManager/Streets.java`, `src/Streets/StreetCommands.java` | Table `Street(ID, Name, TownID)`; `/street set|remove|list` (`k&k.street`). `DataManager.Streets.RemoveStreet` (L127-157) never sets `removed = true`, so the cache is not updated. | Addresses only: `Structure` has `streetID` + `streetNumber` (`Models/Structures/Structure.java:15-17`); the transport minigame prints the destination as street + number with no guidance (`Minigames/Transport.java:410-418`). |
| `src/SpawnPoints/SpawnPoint.java`, `DataManager/spawnpoints/*` | `SpawnPoint(Name, TitleIDRequired, Price, DonatorIDRequired, World, X, Y, Z, Yaw, Pitch)`, `TownSpawnPoint`, `SpawnpointStructure`. | Legacy of today's `Domain.Location`. |

Negative results in V1: no road material list anywhere (the only `Material` list is mining,
`Resources/BlockBreakEvents.java:49`), no graph/Dijkstra/BFS code outside `PathFinder`, no `getRelative`/`BlockFace`
walking, no intersection/junction code (all "intersect" hits are WorldGuard `getIntersectingRegions`), no
`setCompassTarget`, no waypoints, no particle trails, no `/navigate`/`/route`/`/path`.

### 4.2 V2 (`knk-v2-archive`, Hibernate)

- `model/dominion/Street.java`: `id`, unique `name`, `@ManyToMany List<District> districts` (join table
  `Street_Districts`). Javadoc L89-101 states the intent that a street runs through several towns and the wilderness and
  should reference the districts/provinces it crosses. Menu icon `Material.RAIL`. Field history across all 146 commits:
  never any geometry. `StreetDAO` (commit `6600f2a`, deleted in `090247c`) was CRUD only.
- `Structure.java:68`: unique `(street_id, streetNumber)`.
- `/street list|fetch|save|remove|edit|seed` (`spigot/command/dominion/StreetCommand.java`; `seed` empty at L558-563).
- **No pathfinding or navigation code at all.** Particles are circles, not trails (`MGSpawnpoint.java:229-235`,
  `SiegeObjective.java:486`).

### 4.3 V3 — what the design can build on

**knk-web-api** (branch `claude/brave-volta-rl1e99` = trunk for these files)

- `Models/Street.cs:8-17`: `Id`, `Name`, `Districts` (M:N `DistrictStreet`), `Structures` (1:N, `Structure.StreetId`
  required). Town↔Street M:N via `TownStreet`, one-directional (`Town.Streets` only). **No geometry.** Not a Domain.
  `StreetsController` CRUD + `search`; `StreetService` handles only `Name` and `DistrictIds`.
- `Models/Location.cs`: `Id`, `Name`, `X/Y/Z`, `Yaw/Pitch`, `World`. `LocationRepository` search matches Name or World.
- `Models/Domain.cs:7-27`: `WgRegionId` (string, no unique index), `LocationId`/`Location` (the "default spawnpoint",
  cascade delete), `AllowEntry`/`AllowExit`. Subclasses Town, District (`TownId`), Structure (`StreetId`,
  `HouseNumber`, `DistrictId`), GateStructure. Domain DTOs for Town/District embed `location`; `StructureDto` has only
  `locationId` (a second lookup is needed).
- Domain lookups: `GET api/Domains/by-region/{regionName}`, `POST api/Domains/search`,
  `POST api/Domains/search-region-decisions`.
- There is no fallback authorization policy, so Streets/Locations/Domains CRUD is anonymous (`Program.cs:148-156`).
  Plugin-only writes use `[RequirePluginServiceKey]` (11 usages). New road-network writes should use it too.

**knk-plugin**

- Street stack exists but is unused: `knk-core` `domain/streets/*`, `StreetsQueryApi`, `StreetCache`,
  `StreetsDataAccess`; `DataAccessFactory.createStreetsDataAccess` (L101-106) is never called, and `CacheManager`
  builds no `StreetCache`. Only consumer: `commands/StreetsDebugCommand.java` (`/knk streets list`, `/knk street <id>`).
- Location → Bukkit: no shared converter. Cleanest is `siege/SiegeBukkit.toLocation(KnkLocation)` (L22-31) plus
  `floorOf`; `core/siege/SiegeFloor.floorY` is a pure floor-snap helper.
- **Block scanning template:** `tasks/GateBlockScanTaskHandler.java`, `FloodFillScanRunnable` (L577-720): BFS with an
  `ArrayDeque` frontier and a packed-long `HashSet` visited set, material whitelist/blacklist as boundaries, max
  cells/radius, tick budget `BLOCKS_PER_TICK = 200` (50 when TPS < 15), hard cap 20,000 cells, synchronous chunk loads
  (`ensureChunkLoaded` L380-390). A road tracer is the same shape, but with far more cells, so it should read
  `ChunkSnapshot`s instead of live blocks.
- **Per-viewer particles:** `siege/SiegeWorldPresenter.ring()` (L333-346) uses `viewer.spawnParticle`, range
  `PARTICLE_RANGE = 64`, driven by the siege ticker every 20 ticks.
- **Admin capture precedent:** `tasks/GateDoorRegionCaptureHandler.java` (`/knk gate door capture|redefine`): a direct
  admin command with a save/cancel loop that writes to the API, without the WorldTask/`WorkflowSessionId` machinery.
  `tasks/LocationTaskHandler.java` is the WorldTask equivalent (chat `save`/right-click).
- **WorldGuard:** `integration/WorldGuardIntegration.regionExists`, `regions/WorldGuardRegionLookup` (region ids at a
  location), `regions/WorldGuardRegionTracker` (enter/leave), `tasks/WgRegionIdTaskHandler.java:425-470, 562-600`
  (polygon/cuboid/polyhedral containment and vertex access). **No closest-point-of-region code exists anywhere**; it
  has to be built from `ProtectedPolygonalRegion.getPoints()` and cuboid min/max.
- **On `claude/teleport` (KNG-17, In Review, not on trunk):** `core/teleport/WarpTargets.java:39-70` resolves
  `name` / `type:name` case-insensitively with ambiguity choices and tab completion (L78-98);
  `core/teleport/SpawnPointResolver` + `paper/teleport/SpawnDestinationResolver` resolve Location/Town/District/
  Structure to a location; `core/teleport/SafeLocationFinder` over the Bukkit-free `BlockProbe` port
  (`isPassable/isSolid/isHazard/minY/maxY`) with `paper/teleport/BukkitBlockProbe`; `TeleportRestriction` (AllowEntry
  pre-check, siege guards). All directly reusable by `/navigate`.
- Nothing exists for trails, boss bars, compass targets or navigation (the "navigation" hits are the menu back-stack).
- Two doc drifts noticed in passing (not fixed here): `knk-plugin/CLAUDE.md` says no `menu` package exists, but
  `paper/menu/` does; it also says "no polling", but `tasks/HeadlessWorldTaskPoller` polls.

**knk-web-app:** Street DTO types only (`src/types/dtos/street/*`); no geometry or map UI.

---

## 5. Algorithms and prior art

WebFetch was blocked for spigotmc.org, modrinth.com and docs.papermc.io; claims about those pages come from search
summaries.

### 5.1 Getting a road network out of blocks

| Technique | Idea | Fit for KnK | Source |
|---|---|---|---|
| Flood fill / BFS over road voxels | Spread from a seed to neighbouring whitelisted blocks; allow ±1 height steps for stairs/slabs. | Gives the **road mask** (a blob several blocks wide). The first step of every pipeline. Already implemented for gates (`FloodFillScanRunnable`). | SpaceNet road pipeline: https://medium.com/the-downlinq/extracting-road-networks-at-scale-with-spacenet-b63d995be52d |
| Skeletonization (Zhang-Suen 2D; Lee 1994 3D) | Thin the mask to a 1-cell centerline that stays connected. | Turns 1-5+ wide roads into centerlines, but plazas and wide junctions produce spurs and junction clusters that need pruning. | https://github.com/linbojin/Skeletonization-by-Zhang-Suen-Thinning-Algorithm , https://scikit-image.org/docs/stable/auto_examples/edges/plot_skeleton.html |
| Skeleton → graph (skan, sknw) | Classify skeleton cells by neighbour count: 1 = endpoint, 2 = path, ≥3 = junction; trace junction to junction; each edge keeps its point list and length. skan merges junction clusters. | Exactly the "polyline + length" edge format needed. | https://skeleton-analysis.org/stable/getting_started/getting_started.html , https://github.com/Image-Py/sknw |
| Graph clean-up (SpaceNet) | Remove small components and dangling edges, join terminals that sit close to other nodes. | Needed after any automatic extraction. | (SpaceNet link above) |
| Seed-and-follow tracing (RoadTracer) | Start at a known vertex and repeatedly step along the road, adding the next segment; captured 45% more junctions than segment-then-extract. | The neural part is irrelevant, but the idea **is** the developer's "veins/roots" intuition: walk from each recorded node along road blocks until you reach another node. | https://arxiv.org/pdf/1802.03680 , https://roadmaps.csail.mit.edu/roadtracer/ |
| Ramer-Douglas-Peucker | Keep only points that deviate more than ε from the chord. | Compress traced polylines (ε ≈ 0.75 block) before storing; compute length from the unsimplified path. | https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm |

**Minecraft is 2.5D.** Treat the walkable surface cell (road block with two passable blocks above) as the unit; connect
cells only when |Δy| ≤ 1 (stairs, slabs), so a bridge over a road does not fuse with the road below; tunnels and bridges
are then naturally separate. Admin-recorded intersection nodes remove the weakest step of automatic extraction,
which is junction detection.

### 5.2 Routing on the graph

- **A\*** with a Euclidean heuristic is admissible because an edge is never shorter than the straight line between its
  ends. With hundreds to a few thousand nodes it answers in well under a millisecond. JGraphT ships
  `AStarShortestPath` and `BidirectionalDijkstraShortestPath`, but a hand-written A\* is ~80 lines and keeps
  `knk-core` dependency-free.
  https://jgrapht.org/javadoc/org.jgrapht.core/org/jgrapht/alg/shortestpath/package-summary.html ,
  https://www.redblobgames.com/pathfinding/grids/algorithms.html
- **Contraction hierarchies / ALT landmarks:** preprocessing costs roughly 100 Dijkstra runs and pays off on graphs with
  millions of nodes. **Overkill here.**
  https://jeansebastien-gonsette.medium.com/routing-faster-than-dijkstra-thanks-to-contraction-hierarchies-part-2-c185af608175 ,
  https://www.cs.princeton.edu/courses/archive/spr06/cos423/Handouts/GH05.pdf
- **Snapping to the network:** index edge segments spatially (a 16×16 or 32×32 grid-bucket map is enough; JTS `STRtree`
  is the heavyweight option), find the nearest segment, project the point onto it, and split that edge with a virtual
  node. https://docs.geotools.org/latest/userguide/library/jts/snap.html
- **Turn instructions (OSRM style):** each maneuver has `bearing_before`/`bearing_after` and a modifier (straight,
  slight, turn, sharp; left/right); `depart`/`arrive` have none. Suggested bands for Δbearing: < 20° straight, 20-60°
  slight, 60-120° turn, > 120° sharp. Only announce at nodes with ≥ 3 edges or where the street name changes. Minecraft
  yaw is 0 = south, so convert. https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md

### 5.3 Off-road legs (start → road, road → destination) and fallback

- **Block-grid A\*** with a road-preferring cost model and a hard iteration cap (V1's `PathFinder` is this idea, done
  badly).
- **Jump Point Search:** order-of-magnitude faster on uniform-cost grids, but does not fit weighted costs or 3D steps.
  https://en.wikipedia.org/wiki/Jump_point_search
- **HPA\*:** clusters with precomputed crossings; only worth it for a "no roads at all" long-distance fallback.
  http://webdocs.cs.ualberta.ca/~mmueller/ps/2004/hpastar.pdf
- **Flow fields:** one Dijkstra from the goal serves many travellers (for example a siege rally point); wasteful for one
  player. https://www.redblobgames.com/pathfinding/tower-defense/
- **Pathetic** (MIT): async A\* library for Paper with pluggable cost/validation processors and off-thread region-file
  reads; must be shaded and shut down on disable. **Best off-the-shelf option for the off-road legs.**
  https://github.com/bsommerfeld/pathetic-bukkit
- **Baritone** (client mod): tick-based cost model, segmented planning (plans the next segment before the current one
  ends), 2-bit chunk cache. https://github.com/cabaletta/baritone/blob/master/FEATURES.md
- **Mineflayer pathfinder:** A\* with toggleable movement rules. https://github.com/PrismarineJS/mineflayer-pathfinder
- **Citizens2 navigator:** A\*, switching to straight-line movement near the target (what V1's Carrier used).
  https://jd.citizensnpcs.co/net/citizensnpcs/api/ai/NavigatorParameters.html
- **Paper `Mob#getPathfinder`:** mob-only vanilla pathing; not usable for a player GPS.
  https://jd.papermc.io/paper/1.21.11/com/destroystokyo/paper/entity/Pathfinder.html

### 5.4 Existing Minecraft navigation plugins

- **CubBossa "GPS – Pathfinder"** (open source): admins hand-build roadmaps of waypoints and edges, with node groups and
  particle visualizers. **No automatic road tracing.** The closest existing data model to this design.
  https://github.com/CubBossa/PathFinder
- **GPS Systems** (particles + boss bar/action bar + re-routing): https://modrinth.com/project/MM77SgHU
- **SimpleGPS** (action bar/boss bar): https://modrinth.com/project/50g2IwKo
- **PathFinderGPS** (admin-defined particle routes): https://hangar.papermc.io/GabichiGG/PathFinderGPS

None of them traces roads from the blocks automatically. That part would be new, and it is the part that justifies
building rather than installing.

### 5.5 Guidance UX and threading

- `Player#spawnParticle` is visible to that player only (`World#spawnParticle` goes to everyone). Players on "minimal"
  particles may not see them, so pair the trail with a boss bar or action bar.
  https://hub.spigotmc.org/javadocs/bukkit/org/bukkit/entity/Player.html
- Draw only the next ~20-40 blocks from the player's projection onto the path; refresh every 5-10 ticks.
- Re-route when the player is more than ~6-8 blocks from the path for more than ~2 s; rate-limit it.
- Arrive within ~3-4 blocks, or once the projection passes the path's end.
- Graph search is pure data and runs async. Block reads must be on the main thread, or off-thread through
  `Chunk#getChunkSnapshot()`, which is thread-safe by design.
  https://hub.spigotmc.org/javadocs/bukkit/org/bukkit/ChunkSnapshot.html

### 5.6 Recommendation (carried into the design)

1. **Nodes are recorded by an admin** (endpoints, intersections, optional anchors on tricky stretches). Automatic
   junction detection is only a hint.
2. **Trace edges with node-seeded region growing**: a multi-source BFS from every node over surface road cells. Where
   two nodes' regions touch, those nodes are neighbours on the road. Between each neighbour pair, run A\* restricted to
   the two regions with a cost that prefers cells far from the road edge (a distance transform), which yields a
   centerline without full skeletonization. Then RDP, store polyline + length + street.
3. **Route at runtime** with a hand-written A\* on an in-memory graph, grid-bucket snapping and virtual nodes;
   OSRM-style maneuvers from bearings and street-name changes.
4. **Off-road legs:** straight-line particle hint in the MVP; Pathetic later.
5. **Guidance:** per-player particle trail, boss bar with distance/ETA/next maneuver, rate-limited re-routing.

---

## 6. Open items surfaced by this research

- Confirm whether a note about street begin/end/intersection logging exists outside the 2026-09-13 export (§3).
- The developer's road-building palette: which blocks roads are actually made of in the V3 world (the notes only name
  gravel and slabs). The tracer's whitelist depends on it; see DESIGN.md §9 Q1.
- Teleport (KNG-17) must reach trunk before `/navigate` can reuse `WarpTargets`/`SpawnPointResolver`/`BlockProbe`.
