# Road Navigation — Rev. 6 proposal: open areas first, curated tiles

**Status:** Accepted (developer, 2026-10-04): **Part B (curated tiles) first**, Part A after. **Part B implemented
2026-10-05, not live-tested**: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) §5.7 has the decisions D1-D7 (they refine
§3 below: a tile is curated by its first build, proposals live in the API) and the status. Handoff
[2026-10-05-road-curated-tiles.md](../../ai-agents/handoffs/2026-10-05-road-curated-tiles.md). Part A waits for the test
areas outside Cinix (D6).
**Last updated:** 2026-10-05
**Builds on:** [DESIGN.md](DESIGN.md) (rev. 5 + builder 5), [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) §5.6,
smoke-test guide [finding L](../../guides/road-navigation-smoke-test.md) (Build v202 analysed).
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27)

## 1. Why

Five days of smoke testing on Cinix (2026-09-30 to 10-04) show the same pattern every time:
- Every builder fix or config change moves the artefacts somewhere else.
- The admin then re-prunes, and spots that were fine before get worse.

Two causes, both structural:

1. **The centreline is made for corridors, not for areas.** The builder thins the road to a 1-block centreline and
   reads junctions off it. On wide, irregular or multi-level areas (plazas, wide stairs, market squares) a centreline
   naturally forks, sprouts spurs and runs in parallel lanes. Junction clustering, spur length, `plaza-growth`,
   auto-plazas, closing along the road, locked-node reach and the thin-loop rule each patch one symptom. Finding L
   measured the trade-off: no `junction-cluster-radius` serves both Brink and tile 1,-2 (radius 5 breaks Brink, radius
   3 doubles the junctions elsewhere).
2. **Corrections are stored as rules, not as results.** A prune tombstone means "leave out whatever lies near here
   next time". Tile 2,-2 holds 27 tombstones for 25 edges. After builder 5, 10 of them match nothing. A tombstone that
   matches the wrong chain fails silently (the correction report in builder 5 now makes this visible, but does not
   prevent it).

Cinix is a hard case (wide stairs, plazas on several levels, mixed materials), but the rest of KnK will add others (§2.3).

## 2. Part A — find open areas before making the centreline

### 2.1 Idea

Split the road mask into **areas** (places you cross in any direction) and **corridors** (places you follow). Make the
centreline of corridors only. Each area becomes one node, with an edge per corridor that touches it. Today the order is
the other way round: centreline first, then plazas reinterpret it. That is why a plaza footprint (or a junction
cluster) can swallow a fork it should not.

### 2.2 Pipeline

1. **Area cores**:
   - spans wider than the corridor width (today's auto-plaza rule, `WidthMax` of the floor's profiles), and
   - **designed areas**: a plaza centre with a radius (rev. 5), and optionally a linked **WorldGuard region**
     (cuboid or polygon), the idea shelved on 2026-10-04 for oddly shaped squares.
2. **Elongation test**: a wide region much longer than it is wide (length / width > 3, measured on its own centreline)
   is a wide corridor, not an area. A boulevard stays a road.
3. **Area footprint**: the core plus a small growth, or exactly the designed region. Footprints that touch merge. A
   designed area absorbs touching automatic ones, which handles an off-centre node like Merchants Square #3693.
4. **Cut the areas out** of the mask; make the centreline of what remains (the corridors).
5. **One node per area**, at its designed centre, or at its most central span (largest `dt`, nearest the medoid). Every
   corridor end touching the area becomes an edge to that node. The piece inside the area is a walk along the mask
   (today's closing path), so no internal centreline exists to fork.
6. **Very large areas** (a 60 × 60 square, a sand-floored desert town) stay one node. Routing across one is the
   last-mile walk search (KNG-51) between the corridor ends, not graph edges.

Tiles, Boundary nodes, anchors, recordings, profiles, stable ids and the router are unchanged. Junction clustering only
remains for forks between corridors, where the radius means what it says.

### 2.3 Scenarios to keep in mind beyond Cinix

| Scenario | Expected result | Risk / note |
|---|---|---|
| Town square with stalls, fountain, trees | One area node; obstacles inside don't matter | — |
| Oddly shaped square, node off-centre | Designed region (WorldGuard) or the merged automatic footprint | Needs the region link for exact shapes |
| Wide boulevard (8-12 wide, long) | Corridor (elongation test) | A threshold to tune once |
| Two wide roads crossing | A small area at the crossing, one junction | — |
| Plaza on several levels joined by stairs (Brink) | One area (the flood follows stair links) | A tall keep with many levels may want one area per level |
| Plaza straddling a tile border | Area cut at the border; Boundary nodes on the cut (today's stitch rule) | Same as today |
| Castle courtyard behind a gate | Area; the gate door stays on the corridor edge (gate cells unchanged) | — |
| Harbour, docks, wooden platforms | Area if planks are a profile material, else nothing | Planks are ambiguous; ambiguous reach applies |
| Bridges, tunnels, stacked roads | Corridors on separate span levels (unchanged) | — |
| Roundabout | Small island: one area; large island: a ring corridor (split as today) | — |
| Spiral ramp, switchbacks | Corridors; the thin-loop rule is 3D, so sides at different heights never collapse | Golden test exists |
| Rural trail with grass holes (finding H) | Unchanged: a mask gap, fixed by recording | — |
| Market street widening for 20 blocks | Elongated → corridor; short and wide → area mid-street | Either is routable |
| Village with 1-2 wide dirt paths | Corridors (unchanged) | — |
| Desert or snow town with path-material ground everywhere | One huge area; routing inside by the walk search | Breaks any centreline approach; areas first handles it best |

### 2.4 Cost

About 4-6 days in knk-core (area detection, elongation test, cut and stitch, area nodes, closing walks), plus golden
tests for the scenarios above. No API change for automatic areas. A WorldGuard link needs a nullable
`road_nodes.PlazaRegionId` and a region test passed in from the paper layer (core stays Bukkit-free). The offline replay
(finding L) is the regression gate: Cinix plus at least one different town.

## 3. Part B — curated tiles: rebuilds become a reviewed list of changes

### 3.1 Idea

A tile gets a **state**: `Detected` (the builder output is the graph, rebuilt freely) or `Curated` (an admin has edited
it; the stored graph is authoritative).
- Edits on a curated tile change the stored graph directly: delete an edge, move a node, record, merge. No tombstone
  is needed, because nothing re-detects behind the admin's back.
- Rebuilding a curated tile computes a **proposal**: the differences between a fresh detection and the stored graph
  (edges and nodes added, removed or moved, geometry changed). It is shown in the overlay (green new, red removed)
  and as a summary list.
- The admin accepts all, accepts items, or rejects. The plugin uploads stored graph + accepted changes through the
  existing upsert, so ids stay stable.

### 3.2 Details

- **Partial rebuild:** `/knk road build here radius <r>` proposes changes inside a circle only. This is for after the
  world changed: the dirty tracker already knows where.
- **Rejected items** go on a per-tile ignore list, which only filters later proposals and never changes detection. A
  stale entry is harmless; a stale tombstone today removes the wrong road.
- **Builder version:** `Detected` tiles built with an older `BUILDER_VERSION` can be queued automatically. `Curated`
  tiles only get a note ("built with v4; a rebuild would propose N changes").
- **Tombstones** stay for `Detected` tiles (they become rare). A curated tile's tombstones are cleared at the first
  accepted proposal.
- **API:** `road_tiles.State` and `CuratedAt` (one migration). Proposals are computed in the plugin and held per admin
  session; stored proposals for a web-app review page can come later.
- **Edge cases:** stitching a curated tile to a detected neighbour (Boundary nodes are matched by position as now);
  recorded edges and anchors stay as they are; a node the admin moved is never moved back by a proposal unless they
  accept it.

### 3.3 Cost

About 2-3 days: the graph diff and proposal model in knk-core; overlay colours and `accept` / `reject` / `build here
radius` in knk-paper; the tile state in knk-web-api; a small tile-state column in the web app.

## 4. Decisions needed (developer)

1. **Part B (curated tiles)**: yes or no; accept per item, or the whole proposal only, as a first step?
2. **Part A (areas first)**: yes or no; and whether a designed area may link a WorldGuard region.
3. **Order.** Recommendation: **B first**. It stops the churn regardless of how detection evolves, and makes every later
   builder change (including A) safe to try. Then A, gated by the offline replay on Cinix and on two or three other
   areas the developer picks (a different town, a village, a rural road network).
4. **Test areas** for the replay gate: which locations on the dev server represent other kingdoms' styles?

Until then, builder 5 plus the correction report is the working state: rebuild, unprune what the summary calls stale,
and use designed plazas where the automatic footprint is wrong.
