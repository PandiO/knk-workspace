# Road Navigation — Design

**Status:** Decided (rev. 4) — all questions answered (§10); ready for implementation, **in parallel with the siege
work** (developer decision). Phase 4 waits for KNG-17 (teleport) to reach trunk. **Rev. 5 addendum (2026-10-04,
developer decision after the smoke test):** designed plazas and movable nodes — §3.5 `PlazaRadius`, §5.6 step 4, §7.
**Builder 5 (2026-10-04, finding L):** §5.6 steps 2, 3, 3b and the §7 corrections line. **Rev. 6:**
[REV6_PROPOSAL.md](REV6_PROPOSAL.md). **Part B, curated tiles, is implemented (2026-10-05, not live-tested):** §3.3
`State`/`CuratedAt`, §3.6 `Confirmed`, §3.9 proposals, §7 commands; decisions and status in plan §5.7. Part A (open
areas before the centreline) follows. **2026-10-09 (finding N15, merged):** destinations snap with their own height
weight, `destination-snap-vertical-weight` (default 1) - §4, §5.2, §6.2 step 2. **2026-10-09 (merged to trunk):**
KNG-73 (configurable default destination, §6.1) and rev. 7 Parts A and C ([REV7_PROPOSAL.md](REV7_PROPOSAL.md):
routing view, entry rule on roads, §6.7).
**Last updated:** 2026-10-09
**Implementation plan:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — its §1 lists ten small deviations (D1-D10) decided
while mapping the design onto trunk code; where this document and the plan disagree, the plan wins.
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27/road-navigation-street-road-graph-endpointsintersections-traced-road)
**Research:** [reports/2026-09-27-road-navigation-research.md](../../reports/2026-09-27-road-navigation-research.md)
(legacy scan, archive notes, V3 building blocks, algorithm sources);
[reports/2026-09-27-open-world-navigation-research.md](../../reports/2026-09-27-open-world-navigation-research.md)
(how Rockstar, Ubisoft and other open worlds do it).

**Revision history**

- **Rev. 1:** admins record every street's begin, end and intersection by hand; a tracer follows the road blocks between
  them.
- **Rev. 2:** open-world games derive road topology instead of logging it (GTA V marks a node a junction by its
  neighbour count; GTA III assembles its network from road pieces). Junctions and endpoints are **detected
  automatically** (road mask → centreline → neighbour count), street names are **inferred** from Structures, and the
  network is built **per tile**.
- **Rev. 3 (developer feedback):**
  - Roads **overlap vertically** (tunnels, underground roads, bridges, roads over roads) → the builder works on a
    3D "span grid" instead of a 2D map (§5.2).
  - Roads are built from **several block combinations** → named **road profiles** (surface, edge, accent and overlay
    materials) replace the single palette (§5.1).
  - An admin **survey walk** ("player road walk scan") learns the profiles from the roads themselves, seeds the build,
    and checks its coverage afterwards (§5.3).
  - Street names inferred from Structures: **confirmed**. Closed gates close roads: **confirmed and widened** — the
    router treats gate states and domain entry conditions as live availability (§6.7).
- **Rev. 4 (developer answers + scale check):** the remaining questions are answered (§10). The off-road leg gets a
  **hard 48-block limit** (§6.2). A scale check against the full vision — 7 kingdoms × 10+ towns × 3+ districts ×
  dozens of structures — adds per-tile network downloads, compact build memory, scoped profiles and a resumable
  world build (§9).

---

## 1. Goal

Give Streets a physical shape so that players (and later NPCs) can be guided **along the real roads** of the world:

- An admin **walks a few roads** in survey mode; the plugin learns which block combinations the roads are made of.
- The plugin **finds all road blocks** from there, reduces them to centrelines — on every level, including tunnels and
  bridges — and turns them into a graph: nodes at junctions and dead ends, edges along the road between them.
- Admins **review** the result, name what couldn't be inferred, and patch what the blocks can't express.
- `/navigate <destination>` routes a player over that graph to a **Location**, a **Domain's default spawn Location**
  (Town, District, Structure), or the **closest point of a Domain's WorldGuard region**, **only over roads that player
  can actually use right now** (open gates, domains they may enter), and shows the way with a particle trail only they
  see.

This realises vision §2.4 (Streets as *"a navigable address and wayfinding system"* for players and NPCs) and closes the
gap V1's intro tutorial joked about (*"the developer … still didn't invent Navigation"*).

### 1.1 Out of scope for the first version (see §8 Phase 6)

- Off-road pathfinding around obstacles (v1 draws a straight hint between the player and the nearest road).
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
                        ┃                                   ━ edge (centreline over road blocks)
          tunnel ┅┅┅┅┅┅┅┃┅┅┅┅┅┅┅┅ (y 48, under J1)         ┅ edge on a lower level: a separate edge,
                        ● E2                                  no junction with the road above
```

- **Road profile** — a named road style, e.g. *"Kardenna main street"* (stone-brick surface, polished-andesite kerbs,
  stone-brick slabs and stairs), *"gravel highway"* (gravel + coarse dirt, cobblestone edges), *"forest trail"* (dirt
  path, coarse dirt, rooted dirt). A profile lists materials by **role** (§5.1), a road class (`Main`, `Road`, `Path`)
  with a cost factor, and a typical width. Profiles are **learned by survey walks** (§5.3) and editable. The builder only
  walks over materials of some profile.
- **Road cell** — a block position a player can stand on whose floor block (or the block under a thin overlay such as
  snow or a carpet) belongs to a profile. Any number of road cells can share one (x, z) column: a street, the tunnel
  under it, the bridge over it.
- **Road mask** — the connected road cells reachable from the seeds.
- **Seed** — a starting point for the mask: every Domain `Location` near a road, every survey breadcrumb (§5.3), and
  admin seeds.
- **Road node** — a point on the centreline: `Junction` (detected, 3+ branches), `Endpoint` (detected, dead end or road
  end), `Boundary` (road crossing a tile border), `Anchor` (placed by an admin), `Virtual` (routing-time only, never
  stored). Admins can **name** any node; named nodes are `/navigate` destinations.
- **Road edge** — the centreline between two adjacent nodes: polyline (3D), walked length, profile/road class, street
  label, flags, and the **gate doors and domains it passes through** (for availability, §6.7).
- **Road tile** — a 512 × 512-block square of one world (all heights), the unit of building, storage and rebuilding.
- **Component** — a connected piece of the network; every node carries its component id, so "no road connects these"
  is known without searching.
- **Survey** — one admin walk in survey mode: samples of the road under and beside the admin, plus the walked path.

---

## 3. Data model (knk-web-api)

New entities, one migration (`AddRoadNetwork`). Tables in `snake_case` like the rest of the schema.

### 3.1 `RoadProfile` (`road_profiles`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `Name` | string (100), unique | "Kardenna main street". |
| `RoadClass` | enum `Main`, `Road`, `Path` | Drives the routing cost factor (config `class-cost`). |
| `CostMultiplier` | double, default 1.0 | Per-profile tuning on top of the class. |
| `Materials` | string (JSON) | `[{material, role, ambiguous, centreShare, edgeShare, samples}]`, role ∈ `Surface`, `Edge`, `Accent`, `Overlay`. Shares/samples come from surveys; admins can edit roles and the `ambiguous` flag. |
| `WidthMin`, `WidthMax` | int | From surveys (5th/95th percentile); used for plaza detection and leak limits. |
| `SampleCount` | int | Total survey samples merged into this profile. |
| `Enabled` | bool | Disabled profiles are ignored by builds. |
| `ScopeDomainIds` | string? (JSON int[]) | Optional: the profile only applies inside these domains' regions (e.g. one kingdom's towns), so one kingdom's road block can be another's wall block (§9). Null = everywhere. |
| `CreatedAt`, `UpdatedAt` | DateTime | |

A seed migration creates one bootstrap profile (*"Default road"*: gravel, dirt path, coarse dirt, cobblestone, stone
bricks, their slabs and stairs) so a build works before the first survey.

### 3.2 `RoadSurvey` (`road_surveys`)

`Id`, `World`, `ProfileId` (FK, the profile the samples were merged into), `StartedBy` (user id), `StartedAt`,
`EndedAt`, `SampleCount`, `Breadcrumb` (JSON polyline of the walked path, RDP-simplified, with per-point `onRoad` flag),
`Stats` (JSON: material histogram by lateral offset, width histogram). Kept for coverage checks (§5.3) and to re-derive
a profile if the merge rules change.

### 3.3 `RoadTile` (`road_tiles`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `World`, `TileX`, `TileZ` | string, int, int | Unique. Tile = `floor(x / 512)`, `floor(z / 512)`; covers all heights. |
| `BuiltAt` | DateTime? | Last successful build. |
| `BuilderVersion` | int | A builder change forces rebuilds. |
| `Dirty` | bool | Set when road blocks change in the tile (§5.9). |
| `CellCount`, `NodeCount`, `EdgeCount`, `LevelCount` | int | Build statistics; `LevelCount` = max road cells stacked in one column. |
| `Warnings` | string? (JSON) | Cell cap hit, suspected leak, survey coverage gaps, unmatched seeds. |
| `State` | enum `Detected \| Curated` | Rev. 6 Part B (plan §5.7 D1). Every upload leaves the tile `Curated`; a build of a curated, built tile only makes a **proposal** (§3.9). An admin sets `Detected` for one direct rebuild (`/knk road tile uncurate`). |
| `CuratedAt` | DateTime? | When the tile was first curated. |

### 3.4 `RoadSeed` (`road_seeds`)

`Id`, `World`, `X`, `Y`, `Z`, `Source` (`Admin`, `Survey`), `SurveyId?`, `Note`, `CreatedAt`. Domain seeds are derived
at build time and not stored.

### 3.5 `RoadNode` (`road_nodes`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | Stable across rebuilds (§5.7). |
| `World`, `X`, `Y`, `Z` | string, int | Standing position. Unique `(World, X, Y, Z)`. |
| `TileId` | int FK → `road_tiles` | |
| `Kind` | enum `Junction`, `Endpoint`, `Boundary`, `Anchor` | |
| `Source` | enum `Detected`, `Manual` | `Manual` nodes survive rebuilds untouched. |
| `Name` | string?, max 100 | Optional; makes the node a destination. |
| `ComponentId` | int | Recomputed after every build. |
| `Locked` | bool | Set when an admin edits the node; rebuilds keep it in place. |
| `PlazaRadius` | int?, 1-32 | Rev. 5: the node is the centre of a **designed plaza** of this radius (§5.6 step 4). Only on `Junction` and `Anchor` nodes; setting it locks the node. |

An admin can **move** a node (`PUT road-nodes/{id}` with `x`, `y`, `z`; rev. 5): within its own tile, onto a free
position; the node is locked and the ends of its edges follow it. Rebuilds keep a locked node in place; the builder's
own junction is merged into it only within `locked-node-reach`, so moving suits corrections of a few blocks and
plaza centres (a plaza's junction is always placed on its centre).

### 3.6 `RoadEdge` (`road_edges`)

| Field | Type | Notes |
|---|---|---|
| `Id` | int PK | Stable where the node pair is unchanged. |
| `FromNodeId`, `ToNodeId` | int FK → `road_nodes`, cascade | `FromNodeId < ToNodeId`; unique pair. |
| `TileId` | int FK | Edges end at `Boundary` nodes on tile borders. |
| `Geometry` | string (JSON) | RDP-simplified 3D polyline `[[x,y,z],…]` of standing positions, From → To. |
| `Length` | double | Walked 3D length of the unsimplified centreline. |
| `MinX`, `MinY`, `MinZ`, `MaxX`, `MaxY`, `MaxZ` | int | 3D bounding box. |
| `AvgWidth` | double | From the distance transform. |
| `ProfileId` | int? FK → `road_profiles`, SetNull | Best-matching profile (§5.6); gives the road class. |
| `StreetId` | int? FK → `streets`, SetNull | |
| `StreetSource` | enum `Inferred`, `Manual`, `None` | `Manual` is never overwritten. |
| `CostMultiplier` | double, default 1.0 | Admin tuning; later terrain/ambush-risk hook (iPhone notes 282, 297). |
| `Flags` | set: `Oneway`, `NoGps`, `Closed` | Static admin flags. Live availability is §6.7. |
| `GateDoorIds` | string (JSON int[]) | Gate doors whose closed-state blocks sit on this edge (§5.2). |
| `DomainIds` | string (JSON int[]) | Domains (Town/District/Structure/Gate) whose regions the edge passes through, in order. |
| `Source` | enum `Detected`, `Recorded` | `Recorded` = walked by an admin (§5.3, §5.10); survives rebuilds. |
| `Status` | enum `Ok`, `Stale` | `Stale` when its tile is dirty; still routable. |
| `Confirmed` | bool | Rev. 6 Part B (plan §5.7 D4): an admin kept this detected edge when a proposal wanted to remove it. Never proposed for removal again; an upload keeps it while both its nodes stay (they are locked). |

### 3.7 Street changes

None to the table. `StreetDto` gains read-only `edgeCount`, `totalLength`.

### 3.8 Endpoints

| Route | Auth | Purpose |
|---|---|---|
| `GET api/road-network/tiles?world={w}` | anonymous read | Tile list with a per-tile `version` (§9): the plugin compares it with its local cache. |
| `GET api/road-network/tiles/{world}/{tileX}/{tileZ}` | anonymous read | One tile's nodes and edges (geometry, gate/domain ids), ETag = tile version. The plugin downloads only changed tiles and keeps them in a local file cache between restarts. |
| `GET api/road-network/meta?world={w}` | anonymous read | Profiles and the street id → name map. |
| `GET/POST/PUT/DELETE api/road-profiles[/{id}]` | writes: plugin key or staff JWT | Profiles. (No merge endpoint: the plugin recomputes the profile from its stored stats and saves it — plan D5.) |
| `POST api/road-surveys`, `GET api/road-surveys?world=` | plugin key | Store finished surveys. |
| `GET api/road-tiles?world={w}` | anonymous read | Tile overview. |
| `PUT api/road-tiles/{world}/{tileX}/{tileZ}/graph` | `[RequirePluginService]` | Build result for one tile, one transaction: detected nodes (with `existingId` when matched), edges, statistics, warnings. Deletes unmatched `Detected` nodes/edges; keeps `Manual`/`Locked` nodes and `Recorded` edges; recomputes component ids. Idempotent. |
| `POST api/road-tiles/{world}/{tileX}/{tileZ}/dirty` | plugin key | Mark dirty (batched). |
| `GET/POST/DELETE api/road-seeds` | writes: plugin key | Seeds. |
| `PUT api/road-nodes/{id}`, `POST api/road-nodes` (anchor), `POST api/road-nodes/merge` | plugin key or staff JWT | Review actions. |
| `POST api/road-edges` (recorded), `PUT api/road-edges/{id}`, `DELETE` | plugin key or staff JWT | Review actions and recorded edges. |
| `GET api/streets/{id}/road` | anonymous | One street's edges and nodes. |
| `GET api/navigation-settings/domain-defaults`, `PUT …/domain-defaults/{domainType}` | writes: plugin key or staff JWT (`knk.admin.road`) | Where `/navigate <domain>` leads without `spawn`/`region`, per domain type (KNG-73, §6.1). |

Validation in `RoadNetworkService`: nodes in the tile they claim; no self-loops; geometry starts/ends within 1.5 blocks
of its nodes; length ≥ straight-line distance; referenced profile/street/gate/domain ids exist.

### 3.9 `RoadTileProposal` (`road_tile_proposals`, rev. 6 Part B)

One row per tile (plan §5.7 D5): the pending **items** of the last rebuild of a curated tile and its **rejected list**,
as JSON in the plugin's item format (knk-core `TileProposal`), plus counts, the build's builder version, cell/level
counts and warnings, `BaseVersion`, `CreatedBy`, `CreatedAt`/`UpdatedAt`. Item kinds: edge added / removed / changed
(course beyond `edgeMatchDistance`, or other gate doors, domains or profile), node moved (more than 2 blocks) / removed.
Never proposed: Recorded and Stitch edges, `Confirmed` edges, locked nodes. An upsert clears the pending items and keeps
the rejected list. Routes: `GET|PUT|DELETE api/road-tiles/{world}/{x}/{z}/proposal`, `GET api/road-tiles/proposals?world=`,
`PUT api/road-tiles/{world}/{x}/{z}/state`.

---

## 4. Plugin architecture (knk-plugin)

Pure logic in `knk-core` (Bukkit-free, unit-tested), thin Paper adapters in `knk-paper`.

| Module | Package | Contents |
|---|---|---|
| knk-core | `core/domain/roads/` | Records `RoadProfile`, `RoadNode`, `RoadEdge`, `RoadTile`, `RoadNetwork` (immutable per-world snapshot), `BlockPos`. |
| knk-core | `ports/api/RoadNetworkQueryApi`, `RoadNetworkCommandApi` | API ports. |
| knk-core | `core/roads/survey/` | `SurveySampler` (cross-section sampling, §5.3), `ProfileLearner` (role classification, widths, merge), `CoverageCheck`. |
| knk-core | `core/roads/build/` | `SurfaceGrid` port (material, overlay, passability, gate-door lookup at a position), `SpanGrid` (§5.2), `MaskBuilder`, `DistanceTransform`, `Thinning`, `SkeletonGraph` (degree classification, junction clustering, spur/plaza rules), `ProfileMatcher`, `NodeMatcher`, `Rdp`, `TileBuilder`. (Street labelling runs in knk-web-api — plan D6.) |
| knk-core | `core/roads/route/` | `RoadGraph`, `SegmentIndex` (3D-aware grid buckets), `Snapper`, `AStarRouter`, `AccessPolicy` + `DomainAccessEvaluator` (§6.7), `Route`, `ManeuverBuilder`, `RegionClosestPoint`. |
| knk-core | `core/navigation/` | `NavigationSession` state machine, `DestinationResolver` (wraps teleport's `WarpTargets`), `EtaEstimator`. |
| knk-api-client | `impl/RoadNetwork*ApiImpl`, DTOs, mapper | |
| knk-paper | `roads/` | `ChunkSnapshotSurfaceGrid` (+ gate cells from each door's closed footprint — plan D9), `RoadBuildJob`, `RoadSurveySession` (samples the admin's walk), `RoadNetworkCache`, `RoadDirtyTracker`, `RoadAdminCommand`, `RoadOverlayRenderer`. |
| knk-paper | `navigation/` | `NavigateCommand`, `NavigationService` (sessions, ticker, availability change listeners), `TrailRenderer`, `NavigationHud`, `NavigationListener`, events (§6.6). |

Config (`config.yml`) — materials live in the API profiles now, not in config:

```yaml
navigation:
  enabled: true
  class-cost: { Main: 0.9, Road: 1.0, Path: 1.15 }
  overlay-materials: [SNOW, "*_CARPET", "*_PRESSURE_PLATE", RAIL, POWERED_RAIL, LEAF_LITTER, PINK_PETALS]
  seed-from-domains: true        # every Domain Location within 8 blocks of a road cell is a seed
  max-snap-distance: 48          # hard limit (developer decision): player and destination must be this close to a road
  snap-vertical-weight: 4        # 1 block of height counts as 4 when snapping the player (bridge vs road below)
  destination-snap-vertical-weight: 1 # the same for a destination: plain 3D, its last leg is a walk path (N15)
  trail-length: 30
  trail-period-ticks: 10
  trail-particle: DUST
  trail-color: "#E8C66A"
  reroute-distance: 8
  reroute-after-ticks: 40
  arrive-distance: 4
  max-session-minutes: 30
  sprint-speed: 5.6              # blocks/s; iPhone notes: "3 min = 1000 blocks"
  survey:
    sample-period-ticks: 4
    cross-section-half-width: 7
    breadcrumb-seed-spacing: 32
  builder:
    tile-size: 512
    tile-margin: 32
    max-cells-per-tile: 250000
    snapshot-chunks-per-tick: 4
    junction-cluster-radius: 3
    min-spur-length: 4
    ambiguous-reach: 3           # §5.1: ambiguous material only counts within 3 cells of an unambiguous road cell
```

---

## 5. Building the road network

### 5.1 Road profiles — handling many block combinations

Real roads mix materials: a stone-brick surface with andesite kerbs, gravel patched with coarse dirt, slabs and stairs
on slopes, snow or carpets lying on top. One flat palette can't express that, and some materials (cobblestone, stone
bricks, planks) are also used for buildings. A profile therefore gives each material a **role**:

| Role | Meaning | Example |
|---|---|---|
| `Surface` | The walking surface; dominates the middle of the road. | stone bricks, gravel, dirt path |
| `Edge` | Borders and kerbs; mostly at the sides. | polished andesite, cobblestone |
| `Accent` | Occasional variants and slope pieces. | cracked/mossy variants, slabs, stairs |
| `Overlay` | Thin blocks lying *on* the road; the road cell is the block beneath. | snow layer, carpet, rails |

Each material also has an **`ambiguous`** flag for materials common outside roads. Rules for the mask:

- A cell is a road cell if its floor material (looking through `Overlay`s) is a `Surface`, `Edge` or `Accent`
  material of **any enabled profile**. Different profiles can meet and mix — a gravel highway entering a stone-brick
  town is one continuous mask.
- An **ambiguous** material only counts within `ambiguous-reach` cells of an unambiguous road cell. A cobblestone kerb
  or a short cobblestone bridge still joins the road; a cobblestone house floor or courtyard behind it does not. A road
  made *entirely* of an ambiguous material is marked unambiguous in its own profile (the admin's choice, prompted by
  the survey).
- After the centreline is built, each edge is matched to the profile whose material mix fits best (§5.6); that gives
  its road class and cost. Mixed or patched roads simply match the closest profile.

### 5.2 Vertical overlap — tunnels, bridges, roads under roads

The world is not a height map: one (x, z) column can hold a street, a tunnel under it and a bridge over it. The builder
therefore never projects onto 2D. It works on a **span grid**, the same structure Recast uses for multi-level navmeshes
(its "compact heightfield"):

- **A span** is one road cell `(x, y, z)`: a road-profile floor with two passable blocks above (gate-door blocks count
  as passable, below). A column can have any number of spans.
- **Links:** each span links to at most one span in each of the 8 horizontal directions, at `dy ∈ {−1, 0, +1}`.
  *At most one* is guaranteed by the headroom rule: in the neighbouring column, standable cells at y−1, y and y+1
  exclude each other pairwise, because each needs a solid floor at its own height and air at the two heights above it
  (y and y+1: y needs air at y+1 where y+1 needs a floor; y−1 and y: y−1 needs air at y; y−1 and y+1: y−1 needs air at
  y+1). A step up additionally needs headroom above the lower span, except onto stairs and
  slabs. Diagonal links need one of the two orthogonal links, so roads touching at a corner don't join.
- **Consequence:** every span has the same 8-neighbourhood a flat grid cell has. The distance transform, thinning,
  degree classification and graph extraction below run on spans **unchanged** — and a tunnel under a road, a bridge
  over it, two stacked city streets, a ramp or a spiral stair are automatically separate or connected exactly as a
  player could walk them. No layer splitting, no special cases.
- **Underground roads** are road cells like any other; nothing requires sky access. They are reached through their
  entrances (a tunnel mouth, a ramp) from any seed. Levels connected only by a ladder, a water lift or an elevator get a
  **recorded vertical edge** (§5.10) — the builder never climbs ladders.
- **Snapping** (§6.2) weights height differences ×`snap-vertical-weight`, so a player on a bridge snaps to the bridge,
  not to the road 10 blocks below. Destinations snap with `destination-snap-vertical-weight` (default 1, plain 3D;
  finding N15, 2026-10-09): their last leg is a walk path, which climbs stairs and ladders, so a roof 28 blocks above
  the road below it is 28 blocks off-road, not 112.
- **Overlay** (§7) shows only edges within ±8 blocks of the viewer's Y by default (`/knk road show all` for every level).
- **Guidance** adds "Go down into the tunnel" / "Cross the bridge" when the next edge's height differs by more than 3
  blocks from where the player is (§6.5).

### 5.3 Survey walk ("player road walk scan")

Instead of guessing which blocks roads are made of, an admin **walks** representative roads in survey mode for a few
minutes, in various places — a main street, a wilderness road, a trail, a tunnel. The plugin learns from what's under
and beside them.

```
/knk road survey start [profile name]     e.g. "Kardenna main street"; omit to learn a new profile
/knk road survey stop                     ends the walk and shows the proposed profile
/knk road survey cancel
```

**Sampling** (every `sample-period-ticks`, only while the admin is on the ground and walking — not flying, riding,
swimming or standing still):

1. The **floor under the feet** (through overlays) and any overlay on it.
2. A **cross-section** perpendicular to the walking direction: the floor material at lateral offsets −7 … +7, each at
   the standable height nearest the centre's (|Δy| ≤ 1 per step, stopping at walls).
3. The **breadcrumb**: the admin's position.

The action bar shows live progress (samples, top materials, estimated width).

**Learning** (`ProfileLearner`, on stop) — unsupervised, from how materials are distributed across the cross-section:

- `centreShare(m)`: how often material m is at offsets −1 … +1; `outerShare(m)`: how often at ±6 … ±7. Road materials
  are common in the middle and rare outside; terrain (grass, stone, sand, leaves) is the opposite. Road-likeness
  `r(m) = centreShare / (centreShare + outerShare)`.
- Per sample, the **road run** = the contiguous stretch around the centre whose materials have `r ≥ 0.6`; its length
  is that sample's width, and materials peaking at the run's ends are `Edge`s.
- Roles: high centre share → `Surface`; peaks at the run's ends → `Edge`; road-like but < 5% of samples → `Accent`;
  seen on top of the floor → `Overlay`. Materials that are road-like here but also appear as walls or floors off the
  road in the cross-sections are proposed as **ambiguous**. Materials below 1% are dropped as noise.
- Widths → `WidthMin`/`WidthMax` (5th/95th percentile).

**Review:** on stop, the chat shows the proposed profile — materials with roles and shares, width range, proposed
ambiguous flags — with clickable **Save / merge into "…" / edit role / discard**. Repeated surveys into the same
profile accumulate their counts, so walking "for x amount of time in various places" steadily refines it. Profiles are
also editable in the web app (Phase 5).

**What else a survey gives the build:**

- **Seeds:** a breadcrumb point every `breadcrumb-seed-spacing` blocks becomes a `Survey` seed, so roads no Domain
  touches — including underground ones — are found.
- **Coverage check:** after a build, every breadcrumb point marked on-road must lie within 2 blocks of a built edge.
  Misses are listed with the likely cause: *"You walked here, but OAK_PLANKS isn't in any profile (bridge?) — add as
  Accent / record this stretch."*
- **Recorded stretches:** a stretch of breadcrumb over non-road ground (a grass path, a ladder, a ford) can be saved as a
  `Recorded` edge in one click — this replaces rev. 2's separate `record` commands.

### 5.4 Mask and snapshot capture

Offline, per tile, admin-triggered (`/knk road build …`). A BFS over spans from all seeds in or near the tile (tile +
`tile-margin`): Domain Locations with a road span within 8 blocks, survey and admin seeds, and `Boundary` nodes of
already-built neighbours. `ChunkSnapshot`s of the chunks the BFS reaches are taken on the main thread, a few per tick,
with `getChunkAtAsync`; everything after capture runs off the main thread on packed-`long` span keys (as in
`GateBlockScanTaskHandler`'s `FloodFillScanRunnable`). Capped at `max-cells-per-tile`; hitting the cap is a warning with
its location.

**Gates on the road:** a gate door standing on a road would break the mask while closed (no headroom). The
`SurfaceGrid` asks the gates' closed footprints (`GateManager`, frame 0 — plan D9) whether a block belongs to a
gate door; such blocks count as passable headroom, and the spans under them are tagged with the door id. Every edge
crossing tagged spans records the door in `GateDoorIds`. The build is therefore the same whether gates are open or
closed; the gate's *state* only matters at routing time (§6.7).

### 5.5 Centreline

1. **Distance transform** over the span grid: each span's distance to the nearest non-road neighbour. Gives width
   (`2 × dt`) and centre-seeking.
2. **Thinning** (Zhang-Suen on the span grid's 8-neighbourhood, §5.2): a 1-span-wide centreline following the middle of
   wide roads and exactly on 1-wide paths.

### 5.6 From centreline to graph

1. **Classify** centreline spans by their number of centreline neighbours: **1 = endpoint, 2 = along the road, ≥ 3 =
   junction candidate** (the GTA V / GIS rule).
2. **Cluster junctions** within `junction-cluster-radius` into one `Junction` at the span nearest the cluster's
   centroid. Builder 5 (finding L, 2026-10-04): of a cluster, only the members that fork within the radius of a
   plaza's footprint join that plaza; the members left over form their own junction(s), clustered among themselves
   (a chain of forks across Brink's wide stairs had pulled a road fork 20 blocks away into the plaza).
3. **Prune spurs** shorter than `max(min-spur-length, local width)`. A plaza's junction (designed or automatic) is never
   dissolved or turned into an Endpoint by this or the prune steps, and a non-plaza junction left with one arm is
   emitted as an Endpoint (builder 5).
3b. **Thin loops** (builder 5): a loop back to one node, or two chains between the same two nodes, whose sides stay
   within 3 blocks of each other the whole way is one lane around an obstacle (lamp post, planter, stall): the loop
   is dropped, of two parallel chains the longer goes. Wider loops (a ring road, a block of houses between two
   streets) get a junction inserted so every edge keeps a distinct node pair.
4. **Plazas.** *Designed* (rev. 5, run first): every node of the tile with a `PlazaRadius` is a plaza centre. The
   road span nearest the node (within 3 blocks; otherwise the warning *"Plaza centre is not on the road"*) starts a
   flood over the road spans linked to it that lie within `PlazaRadius` (3D) of the centre — the **footprint**. Every
   centreline span in it belongs to one `Junction` placed exactly on the node, so the node keeps its id, name and lock
   (an `Anchor` centre takes the junction over as usual). Every branch leaving the footprint becomes an edge to it;
   the edge closes onto the centre along the road, not in a straight line. Junction clusters touching the footprint
   join it, and the automatic rule below ignores spans inside it. *Automatic* (`navigation.builder.auto-plazas`,
   default on): road spans wider than the `WidthMax` of every profile listing their floor are a plaza core; its
   footprint is the core's clearance plus `plaza-growth`; each footprint becomes one `Junction` at its widest span.
   With `auto-plazas: false` only designed plazas exist and wide areas are thinned like roads.
5. **Edges** = centreline chains between nodes: `Length` from the raw chain, `AvgWidth` from `dt`, `Geometry` via RDP
   (ε = 0.75, 3D). **Profile match:** the histogram of floor materials within `dt` of the chain, compared with each
   profile's material shares (cosine similarity); best match → `ProfileId`.
6. **Domains:** sample the polyline every 4 blocks against the WorldGuard regions (`WorldGuardRegionLookup`) and map
   region ids to domains (`core/regions/RegionDomainResolver`) → ordered `DomainIds`.
   *Live tags (2026-10-08, smoke-test findings N3/N4):* stored tags are a snapshot of build or record time. The
   plugin also re-tags every edge from the world (`LiveEdgeTags`: regions every 2 blocks, gate doors every half
   block, `core/roads/build/EdgeTagging`) when the network changes and every minute, and the router uses the stored
   tags plus these. A domain region made after the build, or a gate a recording missed, counts without a rebuild.
   Recorded stretches also store the gate doors they pass.
7. **Tile borders:** chains leaving the tile end at a `Boundary` node matched by position with the neighbour tile.

Admin `Anchor` nodes are honoured (the chain is split there).

### 5.7 Stable ids across rebuilds

New nodes are matched to old ones of the same tile within 3 blocks (3D, greedy nearest); matched nodes keep id, name
and lock. An edge keeps its id and admin fields (street, flags, cost) when its matched node pair is unchanged and its
polyline stays within 2 blocks of the old one. `Locked` nodes don't move. Unmatched old detected nodes/edges are
deleted and listed in the build summary.

### 5.8 Components

After a tile build, the API recomputes component ids (union-find over nodes and edges; milliseconds). Routing fails fast
across components (GTA SA's flood-fill groups).

### 5.9 Keeping up with the world

`RoadDirtyTracker` marks a tile dirty (batched every 30 s) on `BlockPlaceEvent`, `BlockBreakEvent`, explosions and piston
moves that touch a profile material or the headroom above a road span, and on WorldEdit `EditSessionEvent`s over the
tile (when WorldEdit is present). Its edges become `Stale` (still routable) and the tile is listed for rebuild. Gate
animations do **not** dirty tiles (§5.4). Automatic rebuilds are Phase 6.

### 5.10 Recorded edges (what blocks can't express)

Stretches the builder can't follow — a wooden bridge you don't want in a profile, a grass path, a ford, a **ladder or
water lift between road levels** — are saved from a survey breadcrumb (§5.3) or with `/knk road record start|stop`:
both ends snap to the nearest nodes (creating `Anchor`s if needed); vertical recorded edges are allowed. Recorded
edges survive rebuilds.

### 5.11 Street labels (confirmed)

Every Structure has a `StreetId` and a door-side `Location`:

1. **Votes:** each Structure votes for its street on the nearest edge within 16 blocks, same level (|Δy| ≤ 4), weighted
   by 1 / distance.
2. **Assign** the street with ≥ 60% of an edge's vote weight.
3. **Continue through junctions:** an unlabelled edge inherits the street of the edge it continues most straightly
   (< 35° bearing change, same road class, same level), until nothing changes.
4. Conflicts and unlabelled edges go into the build summary; unnamed wilderness roads stay unlabelled.

`/knk road street <street>` overrides (`StreetSource = Manual`, never overwritten).

### 5.12 Known edge cases

| Case | Handling |
|---|---|
| Road under a road / tunnel / bridge / stacked streets | Span grid (§5.2): separate unless walkably connected. |
| Levels joined by ladders, water lifts, elevators | Recorded vertical edge (§5.10). |
| Plaza of road blocks | One junction at its centre (§5.6 step 4). |
| Gravel beach, cobblestone roof far from roads | Never reached: the mask grows from seeds only. |
| Cobblestone floors next to a cobblestone kerb | `ambiguous` + `ambiguous-reach` (§5.1). |
| Gaps (doorway, non-profile bridge, ford) | Separate components; the summary lists nearby endpoints of different components and survey coverage misses. |
| Closed gate across the road | Door blocks count as headroom; tagged, handled at routing (§5.4, §6.7). |
| Detector misses or over-splits a junction | `node merge`, `node anchor`. |

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
| `town:<name>`, `district:<name>`, `structure:<name>` (or `#<id>`) | The domain's default destination (below); with `spawn` its `Location`, with `region` the closest point of its WorldGuard region (§6.3). |
| `street:<name>` | The nearest point on that street's edges. |
| `node:<name>` | A named road node. |
| bare `<name>` | Searched across all of the above; one match → go; several → `type:name` choices (teleport's `WarpTargets`). |

**Default destination (KNG-73, 2026-10-08, on `claude/kng-73-road-navigation-n92vlm`, not on trunk).** Without a mode
word a domain leads to its *default*: `Spawn` (its `Location`) or `Region`. The default is set per domain type (Town,
District, Structure, GateStructure; table `domain_navigation_defaults`, seeded `Spawn`) on the web app's road admin page,
and a single domain overrides it (`domains.NavigationDefaultOverride`, null = follow the type; "Navigation Default
Override" on its form, added with the Form Builder). `POST api/Domains/search` returns the effective value as
`navigationDefault`, which the plugin's catalogue keeps on each `NavTarget` (refreshed in the background once a
minute old, or by `/knk cache refresh`). Being inside the
domain's region is "already there" with either default (N9). A domain without a `Location` falls back to `region` and
one without a region to its `Location`; with neither it is refused. Resolution reuses teleport's
`WarpTargets`/`SpawnPointResolver` (on `claude/teleport`, KNG-17). Unlike `/warp`, destinations don't need
`TeleportEnabled`. A destination the player may not enter is handled by §6.7. Structures need a second lookup for their
`Location` (`StructureDto` has only `locationId`).

### 6.2 Route computation (async)

1. Resolve the destination to a point, or a set of goal points (region mode, §6.3).
2. **Snap** the player and the target to the nearest edge segments within `max-snap-distance`, using 3D distance with
   height weighted ×`snap-vertical-weight` for the player and ×`destination-snap-vertical-weight` (1) for the target
   (§5.2, N15); split the edges with `Virtual` nodes.
3. **Off-road legs are straight-line hints with a hard limit** (developer decision):
   - Target within `max-snap-distance` (48) of the player → **direct mode**, a straight trail to the target, no road.
   - Otherwise **both** the player and the target must be within 48 blocks of a road, or `/navigate` refuses:
     *"You're too far from a road — get within 48 blocks of one."* / *"Kardenna Mill is too far from any road."*
   - Start and goal in different components (no road connects them) → refused with *"No road connects you to …"*
     (known instantly from the component ids, §5.8).
   - The straight legs (player → road, road → target) are re-drawn as the player moves; real off-road pathfinding is
     Phase 6. **Update 2026-10-02:** the first slice of it — a bounded walkable-path search for direct-mode and
     last-mile legs, with a straight-line fallback — is designed in [LAST_MILE_PATHFINDING.md](LAST_MILE_PATHFINDING.md)
     (Linear KNG-51; proposed, not implemented). **Update 2026-10-09 (KNG-75 step 1, merged, plugin `main` `c4141f90`):** with walk
     paths the player → road leg is a walk path too, and the player may start `max-start-distance` (96) from a road in
     plain 3D (the height weight only picks the road); without them the 48-block weighted limit stays. Destinations
     further off-road follow in step 2 (LAST_MILE_PATHFINDING.md §10, Phase D). **Step 2 (2026-10-10, merged, plugin `main` `8f2b7c30`):** with
     walk paths a destination may be 256 from a road (`max-destination-distance`, plain 3D); within 96 of the road's
     end (`destination-walk-range`) the last leg is a walk path, further the HUD arrow alone ("No conventional path to
     X found.") until the player is within 96.
4. **A\*** with cost `Length × classCost × profile.CostMultiplier × edge.CostMultiplier`, Euclidean heuristic scaled by
   the cheapest class cost. Edges are filtered by the player's **`AccessPolicy`** (§6.7).
5. Build the `Route`: off-road legs, road legs (trimmed at virtual nodes), maneuvers (§6.5), ETA
   (`length / sprint-speed`).

Target: < 5 ms for a few thousand nodes; the network snapshot is immutable, so routing runs on any thread.

### 6.3 Closest point of a region

Polygonal region: `ProtectedPolygonalRegion.getPoints()` + min/max Y; cuboid: min/max corners → a Bukkit-free 3D
`RegionShape`. Goals = network points inside the region, or, if none, the point closest to it. A\* runs multi-goal and
stops at the first goal: the route ends where the road enters the region. Already inside: "You are already in
Kardenna."

### 6.4 Guidance

- **Trail:** every `trail-period-ticks`, the next `trail-length` blocks from the player's projection onto the route,
  with `Player#spawnParticle` (only they see it), one particle every ~1.5 blocks at standing height + 0.2; off-road legs
  sparser and in another colour.
- **Boss bar:** `"→ Merchantstreet · 340 m · ~1 min"`, progress = travelled / total; the next maneuver within 20
  blocks of a turn.
- **Action bar:** direction arrow (`⬆ ⬈ ➡ ⬊ ⬇ ⬋ ⬅ ⬉`) to the trail point ~6 blocks ahead, for players with minimal
  particles.
- **Re-route:** more than `reroute-distance` off the route (3D) for `reroute-after-ticks` → recompute (max once per 3 s).
- **Arrival:** within `arrive-distance`, or inside the region → sound + `"You have arrived at Kardenna Market."`.
- **Ends** on quit, death, world change, teleport (> 16 blocks), joining a siege match, or `max-session-minutes`.

### 6.5 Maneuvers

At each `Junction` on the route, or where the street label changes: Δ = bearing after − before (~6 blocks each side).
< 20° straight (only announced on a street change: "Continue onto …"), 20-60° slight, 60-120° turn, > 120° sharp;
left/right from the sign. Height changes: when the next edge starts > 3 blocks below/above the current one, "Go down
into the tunnel" / "Take the stairs up" / "Cross the bridge". Unlabelled edges: "Take the path on the left".

### 6.6 Events

`NavigationStartEvent` (cancellable), `NavigationRerouteEvent` (with reason), `NavigationArriveEvent`,
`NavigationEndEvent` (reason). Later consumers: transport quests, tutorial steps, discovery, bandit ambushes.

### 6.7 Availability — gates, entry conditions, live changes (confirmed)

The router only uses roads this player can actually use **now**. Every edge carries its `GateDoorIds` and `DomainIds`
(§5.4, §5.6); a per-request `AccessPolicy` decides each once and caches the answer for the whole search:

| Check | Source | Blocked when |
|---|---|---|
| Gate doors on the edge | `GateManager.getGate(id)` → `CachedGateDoor.getCurrentState()`, `isDestroyed()`, `isJammed()` | State is `CLOSED`, `CLOSING`, `OPENING` or jammed. `OPEN` or destroyed → passable. A door in an active siege (`getCurrentSiegeId() != null`) is blocked for non-participants regardless. `AllowPassThrough` doors: passable only for players the pass-through rules allow, with a hint "right-click the gate to pass". |
| Domain entry | the domains in `DomainIds` the route *enters* | `AllowEntry = false`, or any future entry condition (vision §2.2: title, balance, clan, premium rank). |
| Domain exit | the domains the player is in and the route *leaves* | `AllowExit = false`. |
| Road access (rev. 7 Part C) | the domain's effective `roadAccess` on `POST api/Domains/search` | Domain entry and exit above are **skipped** for a domain whose rule is `Ignored` for roads (per type on the road admin page, per domain "Road Access Override"). For domains along a public street (houses, shops): routes pass them, the rule still holds at the border and on the walk path. Every current type defaults to `Applies`. [REV7_PROPOSAL.md](REV7_PROPOSAL.md) §4, KNG-92. |
| Siege | `SiegeGateController.isLocked` (read-only) | **Not blocked** (plan D2): trunk keeps siege areas open to non-members and carries them through locked gates, so a siege-locked gate counts as a pass-through gate for non-members. Navigation ends when the player joins a siege lobby. |
| Static flags | edge `Flags` | `Closed`, `NoGps`; `Oneway` against direction. |

**One source of truth for entry rules.** Today `core/regions/SimpleRegionTransitionService.checkEntryDenials`/
`checkExitDenials` decide AllowEntry/AllowExit when a player crosses a region border. That logic is extracted into a
shared `DomainAccessEvaluator` (knk-core) used by both the region tracker and the router, so navigation can never send a
player somewhere the border check would stop them, and any future entry condition applies to both at once. Staff and
owner-mode bypasses apply the same way in both.

**When no usable route exists**, the router searches again ignoring availability. If that finds a route, the player is
told exactly why and guided as far as they can go:

- *"No open route to Cinix Keep — the West Gate is closed. Guiding you to the gate."*
- *"You may not enter Kardenna Castle. Guiding you to its edge."* (destination domain denied: route ends at the region
  boundary, §6.3)

*Live test 2026-10-08 (findings N5, N6):* the end of such a partial route is **not an arrival**. The player is told
once ("End of the open route to X: the South Gate is closed. The route continues when it opens"), the session keeps
guiding, and only a *full* route replaces it when the element opens ("The way to X is open again"). The trail of a
partial route has no straight leg on to the target. A player standing **on** a blocked edge may walk its open side:
each part of the start edge, from the player to a node, is tagged from the world and checked on its own
(`RouteRequest.StartSides`), so the way back to another road is open (before, a blocked start edge could not be left).
The live re-check only judges the route **ahead** of the player: a gate closing behind them is no block (N10). A
pass-through gate follows the right-click rule exactly: a gate admin passes any door, anyone else a door with
AllowPassThrough and the use node, with Bukkit's or KnK's permissions (N11). The start snaps to a road that connects
to the goal when the nearest one is a stretch on its own (N12). A domain asked for without `spawn`/`region` is
reached by standing in its region (N9); the default itself (spawn or region) is configurable since KNG-73 (§6.1). A
goal on a blocked edge is reached over the open stretch from a node (goal sides, N14), and with no open route the player
is guided as close to the goal as the open roads go when that beats stopping at the first block of the shortest
all-open route (N14).

**Fresh domain rules (KNG-104, merged 2026-10-09, plugin `1159ae5d`).** The router and the walk path look domains up by region through
`RegionDomainResolver`; an entry older than the cache TTL (1 minute) is answered as it is and re-asked from the API in
the background, a region the API no longer knows is forgotten, and `/knk cache refresh` clears the map. So a changed
AllowEntry/AllowExit reaches the next route or re-check within about a minute, without a restart.

**Routing view (rev. 7 Part A, merged 2026-10-09).** Navigation routes on a view of the network in which every edge is
cut where its access tags change - at each gate door and region border the live tags find - so a gate is its own short
piece and a district clipping a road blocks only the stretch inside it ([REV7_PROPOSAL.md](REV7_PROPOSAL.md) §2,
`RoutingView`). Pieces map back to their stored edge for admins (`/knk road why`: `edge #10139 blocks 31-34`). This
makes the per-part patches above (start sides, goal sides, the part re-check) unnecessary; Part A step 2 removed them
(knk-plugin `main` `723d21f4`, 2026-10-09). A start at a node whose snapped edge is blocked leaves from that node. A region whose domain's entry rule is
"Ignored" for roads (rev. 7 Part C: houses, shops along a street) cuts nothing (knk-plugin `eea80099`): the `/navigate`
catalogue knows those regions by id, and a change recuts the roads at once. A region counts on a road where it covers the road's centreline (finding P4: one that covers only part of the
width still blocks the stretch when it covers the centre).

**Live changes.** `NavigationService` listens to gate state changes (an observer on `GateManager`'s animation-complete
notifications), domain cache refreshes and siege state changes:

- An element on an active route becomes blocked → re-route with the reason: *"The West Gate closed — recalculating."*
- A gate opens or a domain opens that would make the route clearly shorter (> 15%) → re-route (rate-limited to once per
  10 s): *"The North Gate opened — shorter route found."*

---

## 7. Admin tooling

In-game (`knk.admin.roads`), direct commands in the `GateDoorRegionCaptureHandler` style (no WorldTask):

| Command | Does |
|---|---|
| `/knk road survey start [profile]` / `stop` / `cancel` | Survey walk (§5.3): learn or refine a profile, add seeds, keep the breadcrumb for coverage. |
| `/knk road profile list` / `show <name>` / `role <name> <material> <role>` / `ambiguous <name> <material> <true\|false>` / `enable\|disable <name>` | Profile review in-game (also in the web app). |
| `/knk road build here` / `tile <x> <z>` / `radius <r>` / `dirty` / `all` | Builds tiles (§5.4-5.8), then a **build summary**: nodes/edges, levels, disappeared nodes, street conflicts, leaks, component gaps, **survey coverage misses** — each with a clickable teleport. Builder 5: a **corrections** line (prune tombstones used / stale, anchors, designed plazas); each stale prune is a warning "Prune matched nothing (stale; unprune it)" with a teleport. |
| `/knk road seed add [note]` / `remove` / `list` | Admin seeds. |
| `/knk road show [radius] [all]` / `hide` | Overlay: nodes by kind, edges coloured by street, unlabelled grey, stale orange, closed red, gate-crossing edges with a gate marker; only the viewer's level unless `all`. Rev. 6: pending proposal items too (added green, removed red, changed or moved yellow); the action bar names the item looked at, with its number. |
| `/knk road street <street> [edgeId] [--continue]` | Label an edge (`Manual`); `--continue` carries the label along the road through straight junctions (§7.1). |
| `/knk road node name <name>` / `merge <id> <id>` / `anchor` / `lock` | Review fixes. |
| `/knk road node move <id>` / `plaza <radius> [id]` / `unplaza [id]` | Rev. 5: move a node to the block you stand on; make a `Junction` or `Anchor` (by id, or the nearest one) the centre of a designed plaza, or clear it (§5.6 step 4). |
| `/knk road record start` / `stop [street]` / `cancel` | Recorded edge, including vertical ones (§5.10). |
| `/knk road edge set <id> cost <x>` / `oneway` / `nogps` / `close` / `open` | Tuning. |
| `/knk road tiles` | Tile overview: state (curated), builder version (an older one is flagged, never rebuilt automatically), items to review. |
| `/knk road proposal [page]` / `list` / `accept <all\|n…\|kind>` / `reject <all\|n…\|kind>` / `clear` / `rejected` / `unreject <n…\|all>` | Rev. 6 Part B: review the proposal of a curated tile (the tile you stand in, or `@x,z`). Accept merges the items into the current graph and uploads it (an item an admin overrode since is skipped with a reason); reject confirms a removed edge or locks a removed node, and puts any other item on the rejected list, which hides that change from later proposals. The step that leaves nothing pending uploads with the proposal's builder version. Kinds: `added`, `removed`, `changed`, `moved`. |
| `/knk road tile curate` / `uncurate` | Rev. 6 Part B: `uncurate` lets the tile's next build write directly (one-shot: that upload curates it again). |
| `/knk road edge confirm\|unconfirm <id\|here>` | Rev. 6 Part B: keep a detected edge a build lost (its ends are locked), or take that back. |
| `/knk road why <destination>` | Debug: route for the admin *as a given player* (`--as <player>`), listing every blocked gate/domain. |

Typical first session: survey a main street, a wilderness road and a trail (five minutes each) → `/knk road build
radius 1500` around Kardenna → read the summary → `/knk road show` → fix two street labels and one bridge. No
coordinates typed.

Web app (admin, Phase 5): profile editor (materials, roles, ambiguous flags, class, cost), tile overview, Street detail
with its edges, edge table with class/cost/flags/street editing (incl. "continue along the road" and "create street"),
build warnings. **Street names stay fully editable in the web app** (developer requirement): a Street's name lives
only on the `Street` entity — edges reference it by id — so renaming a street in its existing web-app form renames it
everywhere, navigation messages included (the plugin refreshes street names every 60 s).

### 7.1 Admin workflows

Where each step happens: **in-game** for anything that needs someone standing in the world (survey, build, overlay,
recording a stretch); **web app** for naming, labelling, profiles, tuning and overviews. Nothing asks for coordinates.

**A. Once per building style — teach the plugin what roads look like** (in-game, ~5 min per road type)
1. `/knk road survey start "Kardenna main street"`, walk the road for a few minutes, `/knk road survey stop`.
2. Review the proposed profile in chat (materials, roles, ambiguous flags, width) → Save / Merge / Discard. Fine-tune
   later in the web app. Repeat for each road type (main street, wilderness road, trail) and each kingdom style.

**B. Scan an existing area** (in-game, then review; ~15-30 min per town the first time)
1. `/knk road build radius 1500` (or `here` / `tile` / `all`). The build finds the roads from domain spawn Locations,
   survey paths and seeds, and detects junctions and dead ends by itself.
2. Read the build summary: disappeared nodes, unlabelled or conflicting streets, suspected leaks, gaps between road
   pieces, survey coverage misses — each clickable to teleport there.
3. `/knk road show` to see the result as particles; fix what's wrong:
   - a gap (wooden bridge, ford, grass path, ladder) → add the material to a profile, or record the stretch by walking
     it (`/knk road record` or from a survey path);
   - a junction detected twice or missed → `/knk road node merge` / `node anchor`;
   - a road that shouldn't be used for routing → `edge … nogps` / `close`.
4. Streets: most stretches are named automatically from the Structures along them (§5.11). Name the rest, in-game
   (`/knk road street …`) or in the web app edge table, both with "continue along the road".

**C. A new road is built** (builders place blocks)
1. Placing or breaking road blocks marks the tile dirty (the tile overview lists it; routing keeps working on the old
   data).
2. An admin runs `/knk road build dirty`. Existing names, labels and fixes are kept; the new road is joined to the
   network where it touches existing roads.
3. If the new road uses a material no profile knows, the build summary says so (coverage/gap) → survey it or add the
   material in the web app.

**D. A new street (name)**
1. Create the Street in the web app (the existing Street form), or from the road page's "create street" in the edge
   editor.
2. Structures created on that street (every Structure already has a Street) make the next build/labelling pick the name
   up automatically; streets without buildings (wilderness roads) are assigned in the edge table or in-game, with
   "continue along the road".

**E. Rename or re-assign a street** — web app only, no rebuild: rename in the Street form (takes effect in-game within
a minute), or change the street of a stretch in the edge table. Manual labels are never overwritten by later builds.

**F. Routine upkeep** — glance at the tile overview for dirty tiles and warnings; `/knk road build dirty` now and then
(automatic rebuilds are a later phase).

---

## 8. Implementation phases

| Phase | Repo | Contents | Tests |
|---|---|---|---|
| 0 | workspace | Done: all questions answered (§10). | — |
| 1 | web-api | `RoadProfile` (+ bootstrap seed), `RoadSurvey`, `RoadTile`, `RoadSeed`, `RoadNode`, `RoadEdge`, migration `AddRoadNetwork`, `RoadNetworkService` (tile replace with id matching, component ids, survey merge), controllers (§3.8), `StreetDto` counts. | Service/validation unit tests; fresh-DB migration CI. |
| 2 | plugin core | `core/roads/survey/` (sampling maths, profile learning), `core/roads/build/` (span grid, mask with ambiguity reach, distance transform, thinning, graph, profile match, node matching, street labels, RDP), `core/roads/route/` (graph, 3D snapping, A\*, components, `AccessPolicy` + extracted `DomainAccessEvaluator`, maneuvers, region closest point). All Bukkit-free. | Golden tests on synthetic grids: meandering 1-wide path, 5-wide road, T/X/5-way junctions, plaza, stairs, **tunnel under a road, bridge over a road, two stacked streets, spiral ramp**, mixed-profile road, cobblestone-floor leak held by ambiguity reach, closed gate on the road, tile borders, rebuild keeps ids/labels. Survey: synthetic cross-sections → expected roles/widths. Router: class costs, oneway, closed gate, denied entry/exit, "why blocked" fallback, component fail-fast, region multi-goal. `SimpleRegionTransitionService` tests stay green after the extraction. |
| 3 | plugin paper | `ChunkSnapshotSurfaceGrid` (+ gate lookup, compact span extraction §9), `RoadSurveySession`, `RoadBuildJob` + resumable world build queue, `RoadNetworkCache` (per-tile download + local file cache), `RoadDirtyTracker` (+ WorldEdit hook), `/knk road …`, overlay. API client + mapper. | Contract test against Phase 1; **live:** survey three road types, build around one real town (incl. a tunnel or bridge if one exists), review. |
| 4 | plugin paper | `/navigate`, `DestinationResolver` (after KNG-17 merges), `NavigationService` with availability listeners, trail, boss/action bar, events. | Session tests in core; **live:** Location, Town spawn, Structure, region edge, street; through a tunnel; closed gate → reason + guidance to the gate; gate opens mid-route → shorter route; denied domain; re-route; arrival. |
| 5 | web-app | Profile editor, tile overview, street road panel, edge table. | Component tests. |
| 6 (later) | all | Automatic rebuild of dirty tiles; "follow road" mode (fork choices at junctions, as in KCD/Witcher/RDR2); off-road legs with Pathetic; NPC routing (Carrier/transport quests) with the same `AccessPolicy` for NPC factions; ETA per travel mode and terrain/risk modifiers; treasure-map/radar items; discovery-gated destinations; 2D web map. | — |

**Scheduling:** runs **in parallel with the siege work** (developer decision, 2026-09-27). Phases 1-3 and 5 share no
files with siege; Phase 4 only reads gate and siege state.

**Dependencies:** Phase 4 depends on KNG-17 (teleport) reaching trunk. The `DomainAccessEvaluator` extraction (Phase 2)
touches `core/regions/` on trunk — a small refactor, coordinate via `ACTIVE_SESSIONS.md`. Gate and siege state are read
only; no siege code changes.

**Rough size:** Phase 1 M, Phase 2 L, Phase 3 M-L (survey + build job), Phase 4 M, Phase 5 S-M.

---

## 9. Scale — the full world (7 kingdoms)

The vision's world: 7 kingdoms, each with at least 10 towns of at least 3 districts and dozens of structures, joined by
long meandering roads (vision §2, concept v0.2). The design was checked against that size.

**Estimate** (order of magnitude): ~70 towns, ~210 districts, 3,500+ structures on a world ~10-12 km across; ~4 km of
streets per town (~280 km) plus ~85 km of inter-town roads → **~365 km of road, ~1.3 M road spans, ~10-15 k nodes,
~15-20 k edges, ~150 k polyline points, ~576 tiles** (most of them wilderness with one road or none).

| Part | Load at that size | Verdict |
|---|---|---|
| Routing (A\* over 15 k nodes) | a few ms worst case, off the main thread; 100 players re-routing is negligible | Fine as designed. A coarse graph over junctions (Rockstar's patent, research §2.1) or contraction hierarchies only pay off above ~100 k nodes — upgrade path if the world grows ~10×. |
| Database | 20 k edges, 15 k nodes, 576 tiles | Fine. Component recompute (union-find) takes milliseconds. |
| Street labels, access checks | 3,500 structure votes per build; a route touches at most a few hundred domains, each decided once | Fine. |
| Trails | 100 navigating players ≈ 200 particles/tick, each sent to one player | Fine. |
| Rebuilds | per tile: a changed street re-traces ~100 chunks in seconds | Fine: dirty tiles only, never the world. |
| **Network download** | a whole-world JSON bundle would be 3-6 MB | **Changed:** per-tile download with per-tile versions and a local file cache (§3.8); a restart downloads only tiles changed since. In memory the whole graph is still only a few MB. |
| **Build memory** | full-height chunk snapshots are large; a tile can touch ~1,000 chunks | **Changed:** each snapshot is reduced right away to a compact list of candidate spans (packed position + material id of profile-material floors with headroom) and released; only those lists stay in memory while a tile builds. |
| **First full-world build** | ~60 k chunks along roads; ~12 min at 4 chunks/tick, faster with an empty server | **Changed:** `/knk road build all` runs as a **resumable background queue** (progress per tile in `road_tiles.BuiltAt`), throttled by TPS, survives restarts; recommended kingdom by kingdom. |
| **Materials per kingdom** | each kingdom has its own building style (resource packs, concept v0.2), so one kingdom's road block can be another's wall block | **Changed:** optional profile **scope** (`ScopeDomainIds`, §3.1) keeps ambiguous materials local. When a Kingdom/Province entity exists (vision §2.1), scopes can point at it instead of a list of towns. |
| **Admin review time** | the real cost at this scale is people, not CPU: ~15-30 min per town the first time (labels, bridges, a few junction fixes) + a few survey walks per kingdom style | ≈ 20-35 hours one-off for 70 towns, spread over time; afterwards only dirty-tile rebuilds. Street-label inference (§5.11) is what keeps this low. |

---

## 10. Questions

### 10.1 Resolved (developer, 2026-09-27, first round)

- **Street labels inferred from Structures:** yes (§5.11).
- **Closed gates close roads:** yes, and more generally the router must treat roads as unavailable because of entry
  conditions, gate open/closed states etc. (§6.7). This also settles rev. 2's "restricted destinations" question: the
  route ends at the boundary with the reason, instead of navigating in with a warning.
- **Vertical overlap and multiple block combinations** raised by the developer → span grid (§5.2) and road profiles
  (§5.1).
- **Player road walk scan:** adopted as the survey walk (§5.3); it is now the main way the builder learns road
  materials.

### 10.2 Resolved (developer, 2026-09-27, second round)

1. **Seeding:** from every Domain `Location` near a road, plus survey breadcrumbs and admin seeds.
2. **Domain destination:** its spawn `Location` when set, else where the road enters its region; the `region` keyword
   forces the region.
3. **Off-road legs:** straight-line hint, **with a hard limit** — player and destination must be within 48 blocks of a
   road (or within 48 blocks of each other), otherwise `/navigate` refuses (§6.2). Real off-road pathfinding stays
   Phase 6.
4. **Trail visibility:** only the navigating player.
5. **Pass-through gates:** count as open for players the pass-through rules allow, with a "right-click the gate to
   pass" hint (§6.7).
6. **Ladders and lifts:** connected only through admin-recorded vertical edges in v1 (§5.10).
7. **Priority:** start **now, fully in parallel** with the siege work (Phase 4 still waits for KNG-17).
8. **Off-road hard limit:** 48 blocks (`max-snap-distance`).

No open questions remain.
