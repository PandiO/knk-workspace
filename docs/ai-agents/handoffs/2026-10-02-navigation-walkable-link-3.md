Read docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md first and follow it; it overrides anything below.

Implement link 3 — KNG-51 Phase B (knk-paper: `WalkSnapshotService` capture/cache, `CellAccess` adapters, ladder/door
cell capture) end to end (code, tests, commits, push to claude/navigation-walkable-path, progress report, handoff) as
link 3 of the chain.

State you start from (written by link 2, 2026-10-02 ~19:40 UTC — re-check before relying on it):
- knk-plugin `claude/navigation-walkable-path` `ad311ae` = link 1's `d8507a3` + four link-2 commits (`ea54013` WalkGrid
  extraction, `6352b4c` PassabilityRules walk helpers, `1fae034` search + types, `ad311ae` timing/LongMap/MemoSurface).
  `origin/claude/road-navigation` `075ae94` and `origin/main` `27b4236` were merged ("already up to date") before the
  final push: check out, pull, merge both again (charter §1.2).
- Test counts on `ad311ae` (`./gradlew build -x deployToDevServer`, green): knk-core **1619**, knk-api-client **184**
  (2 skipped), knk-paper **1089** (14 skipped). Maven Central returned 429 on the first builds of a fresh container —
  retry (Gradle keeps what it downloaded), then `--offline`. Re-create `~/.gradle/gradle.properties` per charter §1.4.
- Progress report `docs/reports/2026-10-02-navigation-walkable-chain.md` has link 2's section with decisions L2-1 … L2-10;
  the design's §10 has a "Phase A status" note.
What earlier links say this link must wire (full list: report → "Link 2" → "What link 3 must wire"):
- A `WalkTerrain(SurfaceGrid, GateCells, WalkCells)` over chunks captured on the main thread (`TickBudget`, loaded chunks
  only, TTL cache keyed by world/chunk, shared across requests — design §8). The `SurfaceGrid` needs a permissive floor
  (`roadFloor` = any material) and must answer `floorMaterial` for every candidate cell (`CompactSurfaceGrid` throws for
  non-spans today) plus passable/solid/hazard for drop columns (head height down to `maxDrop` below, neighbour columns)
  and the block above ladder cells. Fence/wall/pane/door tops must not become floors (`PassabilityRules.isWalkFloor`
  needs the material name, or reject them at capture). Measure memory per chunk and extraction time (design §2 row 4).
- `WalkCells` door/climbable/water flags per block (`CompactSpans` stores none). On paper `LADDER` and doors are
  `isCollidable()`; the walk view relies on the flags to treat them as passable. `WalkCells.ofMaterials` is the reference.
- `CellAccess` adapters composed with `CellAccess.all(...)`, coordinates = the mover's feet block (L2-3): gates
  (`GateCells.doorAt` on feet/head → the same `GateAvailability` logic as the router), denied regions (entry/exit via
  `DomainAccessEvaluator`, `knk.region.bypass` → open; verify `ProtectedRegion.contains` off-thread safety, else copy into
  `RegionShape`s), doors (WorldGuard `USE`/`INTERACT` **and** KnK domain entry rules, checked once per door cell per
  request on the main thread → `0` or `CellAccess.BLOCKED`; the search adds the +3 itself).
- Config plumbing only as far as Phase B needs it (`max-drop`, `drop-penalty`, `capture-margin`, `chunk-ttl-seconds`,
  `max-concurrent-searches`); `MovementProfile.PLAYER.withDrops(...)`, `WalkBudget(...)`. Nothing is wired into
  `NavigationService` yet — that is Phase C; Phase B must leave navigation behaviour unchanged.
Phase-specific reading: `LAST_MILE_PATHFINDING.md` §2 (row 4: `SpanExtractor`/`CompactSpans`/`CompactSurfaceGrid`/
`ChunkSnapshotSurfaceGrid`), §4 (doors, water, ladders), §6 (all), §8 (all), §9, §10 Phase A status + Phase B row, §12
(knk-paper tests). Code: knk-core `roads/walk/` (all — start at `WalkSearch`'s class comment and `WalkCells`),
knk-paper `roads/SpanExtractor`, `CompactSpans`, `CompactSurfaceGrid`, `ChunkSnapshotSurfaceGrid`, `GateCellsIndex`,
`utils/TickBudget`, the road router's `GateAvailability`/`DomainAvailability`/`NavigationAccess.policyFor`; tests
`CompactSurfaceGridTest` (strict-fake style) and the navigation tests (mocked `World` kept in a field).
Open flags that affect this link: decision §11-5 (no partial path) still awaits the developer's live test — keep
`NO_PATH`/`FALLBACK`. L2-1 … L2-10 are reversible defaults; don't change them without a reason recorded in the report.
Known risks: the capture is where walk bugs will come from (the core assumes every block it asks is answered); keep the
search thread Bukkit-free; region `contains` off-thread; memory per cached chunk; the developer may commit to
`claude/road-navigation` while you work — merge it before the final push.
Next after you: link 4 — KNG-51 Phase C (`DirectLeg`, walk path in direct mode, `TrailRenderer.drawPath`, kill switch,
final write-up).
