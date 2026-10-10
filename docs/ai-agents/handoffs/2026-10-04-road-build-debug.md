# Handoff: debug the road build after the 2026-10-04 reset (missing rural road, edges through the ground)

**Status:** Ready to start (written 2026-10-04 by a cloud session without DB or server access).
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) (road navigation). **Prompt for:** a Claude Code session on the
developer's machine with the knk-plugin and knk-web-api code **and read access to the dev MySQL database**.

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` in knk-workspace first
(claim a row before editing). Then debug the two road-build problems below: **confirm the cause from the database and the
code first, report it, and only then fix** — the fixes touch the shared road builder.

## What happened

- On 2026-10-04 the developer wiped all road data with `docs/guides/road-navigation-reset.sql` (road_edges, road_nodes,
  road_tiles, road_seeds, road_surveys **and** road_profiles; streets kept) and deleted the plugin's `roads/` tile cache.
- They then made **3 new surveys → 3 new profiles** (one is **"Cinix rural main"**, from a long survey), set the
  **ambiguous** flag on "all required blocks" in each profile, adjusted `WidthMin`/`WidthMax`, and built the tiles.
- Plugin code: knk-plugin `claude/road-navigation` (`075ae94`) or `claude/navigation-walkable-path` (`305829b`, contains
  `075ae94` + KNG-51) — **ask the developer which jar is deployed**; the builder code is the same on both.
  API: knk-web-api `claude/road-navigation` (`6947e2a` at the time of writing).

## Problem 1 — most of the "Cinix rural main" road is not built

More than 70 % of the road the developer surveyed is not in the network. It should connect **endpoint #3760** and
**endpoint #3778** (road_nodes ids).

**Prime suspect — the ambiguous flags** (developer likely read "ambiguous" as "required"):
- `knk-core/.../roads/build/ProfileSet.isAmbiguous`: a material is ambiguous in a column when **every** applicable profile
  listing it flags it.
- `MaskBuilder.filterAmbiguous`: ambiguous spans are kept only within `ambiguous-reach` (config `navigation.builder.ambiguous-reach`,
  default 3) spans of an **unambiguous** span; what is then no longer connected to a seed is dropped. A road whose
  surface materials are all flagged has no unambiguous spans → it vanishes except next to stray unambiguous blocks.
- DESIGN.md §5.1: "a road made entirely of an ambiguous material is marked unambiguous in its own profile".

**Second suspect — profile scope:** `ProfileSet.Profile.appliesTo` — a profile with `ScopeTownIdsJson` set only applies
inside those towns; a rural road outside the town is then not a road material at all.

**Other things to rule out:** seeds (survey breadcrumbs become `Survey` seeds every `breadcrumb-seed-spacing` = 32 blocks
— check they exist and lie on the road), the per-tile cell cap (`max-cells-per-tile`, a warning in the tile's
`WarningsJson`), a material on the road that is in no profile (gap; the build summary's coverage misses).

**Confirm with the DB (read-only):**
```sql
SELECT Id, Name, Enabled, WidthMin, WidthMax, ScopeTownIdsJson, MaterialsJson FROM road_profiles;
SELECT Id, World, ProfileId, SampleCount, StartedAt, LEFT(BreadcrumbJson, 300) FROM road_surveys;
SELECT Source, COUNT(*) FROM road_seeds GROUP BY Source;
SELECT Id, World, X, Y, Z, TileId, Kind, Source, ComponentId FROM road_nodes WHERE Id IN (3760, 3778);
SELECT Id, World, TileX, TileZ, CellCount, NodeCount, EdgeCount, WarningsJson
  FROM road_tiles WHERE Id IN (SELECT TileId FROM road_nodes WHERE Id IN (3760, 3778));
```
Then, for the survey of "Cinix rural main": list which of its Surface materials are `"ambiguous":true` in **every**
profile that lists them (that is the set the builder distrusts). If that set covers the road's actual surface, the cause
is confirmed. Best check in code: a `MaskBuilder`/`TileBuilder` unit test with a long road made only of a material that
is ambiguous in its only profile → the mask is (almost) empty; flip the flag → the road is built.

**Likely outcome:** a data fix (the developer clears the flag on the road's main Surface material(s), rebuilds the tiles),
not a code fix. Worth considering in code (ask first): a build-summary warning *"profile X: every Surface material is
ambiguous — its roads only survive next to unambiguous blocks"*, and/or a warning in the profile review/web-app editor.

## Problem 2 — edges run through the ground to a plaza junction above them

Edges **#5656, #5655, #5542** (road_edges ids) start at junctions lower than the plaza they lead to and their lines go
**through the ground** to the plaza's junction **#3752**. The developer saw more stretches "travelling through the road
or terrain surface" elsewhere. Nothing in the build checks for this.

**Prime suspect — the straight closing segment onto a plaza / cluster junction:**
- `SkeletonGraph` (plazas, step 2; clusters, step 3): the plaza becomes **one Junction at its widest core span**; every
  skeleton span within the core's clearance + `plaza-growth` (default 2) belongs to it, and a junction cluster within
  `junction-cluster-radius` that reaches the plaza joins it (the spans of that path too). The chain therefore ends where
  the plaza/cluster footprint begins.
- `TileBuilder.polyline(mask, chain, from, to)` closes the chain onto the node positions with a **straight segment**. If
  the ramp/stairs up to the plaza lies inside the footprint, the chain ends at the bottom and the closing segment climbs
  diagonally through the ground to the plaza's middle.
- `Rdp.simplify` (3D, `rdpEpsilon` 0.75) keeps segments within 0.75 of the centreline — not a deep cut, but no terrain check
  either.

**Confirm with the DB:**
```sql
SELECT Id, FromNodeId, ToNodeId, TileId, Length, MinY, MaxY, Source, GeometryJson
  FROM road_edges WHERE Id IN (5656, 5655, 5542);
SELECT Id, X, Y, Z, Kind, Source FROM road_nodes
  WHERE Id = 3752 OR Id IN (SELECT FromNodeId FROM road_edges WHERE Id IN (5656, 5655, 5542))
                  OR Id IN (SELECT ToNodeId   FROM road_edges WHERE Id IN (5656, 5655, 5542));
```
Positions are **floor blocks** (feet at y + 1). Look at the last geometry segment before #3752: its length and Δy. A long
final segment with several blocks of Δy confirms the closing-segment cause. If instead the cut is in the middle of the
geometry, look at RDP or at the span links (`SpanGrid`/`WalkGrid` step rules) and report.

Reproduce in a test before fixing: a `TileBuilderTest`/`SkeletonGraphTest` fixture (ASCII layers, the existing style) with a
plaza a few blocks above a road that climbs to it by stairs/ramp, ending inside the plaza footprint; assert that no
geometry segment passes through a solid block (or more than ~1 block above the floor).

**Proposed fix (confirm with the developer before implementing):**
1. Close a chain onto a plaza/cluster junction **along the mask**: a shortest path over the junction's member spans from
   the chain's last span to the node's span (BFS over `RoadMask` neighbours), appended before RDP — instead of the straight
   segment. Anchor/locked nodes off the mask may keep the straight closing if the gap is short.
2. A **build-summary warning** (`BuildWarning`, with a teleport like the existing ones) for any final edge segment that
   passes through solid blocks or floats more than 1 block above the floor, checked against the captured `SurfaceGrid`
   — so remaining cases show up without hunting.
3. Bump `TileBuilder.BUILDER_VERSION` if the output changes (forces rebuilds).

## Rules

- **Read-only on the database** unless the developer explicitly approves a write; never touch the production server.
- Code changes: ask the developer which branch to use (the walkable-path chain never pushed to `claude/road-navigation`,
  the developer's testing branch; `claude/navigation-walkable-path` contains it). knk-core builder tests must stay green
  (`./gradlew build -x deployToDevServer`; record module test counts before and after).
- Keep fixes minimal and each with a test; a changed builder behaviour gets its own commit.
- Record findings and the fix in `docs/guides/road-navigation-smoke-test.md` (new findings) and the tracker row; tell the
  developer which tiles to rebuild.

## Report back

For each problem: confirmed cause (with the DB rows / test that proves it), data fix for the developer (if any), code fix
(commits, tests), and what to rebuild and re-check in game.
