# Feasibility Assessment: WorldGuard/WorldEdit Regions for Gate Door Geometry

**Status**: Decided — 2026-09-11 planning meeting; FLOOD_FILL viability confirmed-negative by live in-game test on 2026-09-12; item 6.1 design spike resolved 2026-09-13 (§9) — both previously-open sizing/design questions now have a concrete mechanism, so 6.2-6.7 are unblocked; 6.6's found orientation gap resolved same day via `CONVEX_POLYHEDRON` capture (§9.4). See §6 for the final decision (supersedes the original recommendation), §7 for the original resolved/open question tracking, §9 for the design spike, and §9.4 for the convex-polyhedron follow-up.
**Source item**: [QOL_BUGFIX_BACKLOG.md #6](../../backlog/QOL_BUGFIX_BACKLOG.md#6-non-rectangular-gate-door-shapes-via-worldguard-regions)
**Scope**: `knk-plugin-v2` (with cross-references to `knk-web-api-v2` for persistence impact) — both repos were renamed mid-session on 2026-09-13 to `knk-plugin`/`knk-web-api` respectively (dropping the "-v2" suffix); this doc keeps the original names in older sections for historical accuracy, new sections use the current names.
**Researched**: 2026-09-11 · **Decided**: 2026-09-11 · **FLOOD_FILL tested**: 2026-09-12 · **Design spike (6.1) resolved**: 2026-09-13 · **Convex polyhedron follow-up (§9.4) resolved**: 2026-09-13

---

## 1. What's actually being proposed

Replace the current anchor-point + reference-point-1 + reference-point-2 rectangular scan (`GeometryDefinitionMode.PLANE_GRID`) with a region — rectangular or polygonal — so admins can define non-rectangular gate door shapes, for both the closed and (optionally differently-shaped) open state.

## 2. Baseline: this is not a new-dependency decision

The framing in the original brain-dump ("do we take on a WorldGuard/WorldEdit dependency") doesn't match the current state of `knk-plugin-v2`:

- **WorldGuard is already a hard `depend`** in `knk-paper/src/main/resources/plugin.yml` — the plugin will not load without it.
- **WorldEdit is already a `softdepend`**, and `compileOnly("com.sk89q.worldedit:worldedit-bukkit:7.2.13")` / `compileOnly("com.sk89q.worldguard:worldguard-bukkit:7.0.10")` are already declared in `knk-paper/build.gradle.kts`.
- WorldGuard already backs the plugin's **core territory model** — `RegionDomainResolver` (domain/territory resolution) and `WorldGuardRegionTracker` (player region-transition tracking) both resolve everything through WG region names. It is not a peripheral integration; it's the backbone of how the plugin understands "where is this place."
- The DB (`knk-web-api-v2`) already stores WG-backed regions as **opaque name strings** — `GateStructure.RegionClosedId` / `RegionOpenedId` — and delegates all shape/geometry storage to WorldGuard's own region store. There is no precedent in this codebase for storing polygon/region geometry directly in KnK's own database.
- There is already a **complete, working, tested pipeline** for "draw a WorldEdit selection (cuboid or polygon) → persist as a WorldGuard region, store just the region name" — `WgRegionIdTaskHandler` (~1000 lines, `knk-paper/.../tasks/`), currently used for district/town regions. It handles polygon vertex containment against a parent region, region renaming, and listing existing regions as an alternative to drawing a new one.

**Implication:** Option 1 (WorldGuard) is not "should we add a dependency" — it's "should we point an existing, hard-depended-upon, already-battle-tested pipeline at one more use case." Option 3 (fully custom) would mean deliberately not reusing code that already does this, for a use case (gates) sitting right next to another (districts/towns) that already does.

## 3. Don't skip this: a non-rectangular option may already exist

Before comparing WG/WE/custom, note that **`GeometryDefinitionMode.FLOOD_FILL` already exists and already produces non-rectangular block sets** (`GateBlockScanTaskHandler.java:221-256, 518-680`) — a BFS flood-fill from seed block(s), bounded by material whitelist/blacklist, `ScanMaxRadius`/`ScanMaxBlocks`, and an optional single-plane constraint. It's live, unit-tested, and used today by `DOUBLE_DOORS` gates.

This doesn't automatically satisfy the request — flood fill detects a shape by material-boundary matching rather than by an admin precisely drawing one, so it's a different tool (good when the door face is visually/materially distinct from its surroundings; not useful when the admin wants to draw an arbitrary boundary irrespective of material, or wants a shape narrower/wider than what the material boundary happens to produce).

**Documented design intent** (`docs/features/gate-structure-animation/REQUIREMENTS.md`): "PLANE_GRID is for rectangular gates (portcullis, drawbridge) using 3 reference points. FLOOD_FILL is for irregular shapes (double doors, decorative gates) using seed blocks and BFS." The type table there pairs `DRAWBRIDGE → PLANE_GRID` and `DOUBLE_DOORS → FLOOD_FILL` as the intended combinations — i.e. the design was never meant to run FLOOD_FILL on a rotating drawbridge slab in the first place.

**However, this is not backend-enforced**: `GateStructuresController.cs:365-367` only validates that `GeometryDefinitionMode` is a defined enum value, not that it's a valid pairing with `GateType`. So `FLOOD_FILL` on a `DRAWBRIDGE` gate is untested/undocumented, not disallowed.

**In-game check completed (2026-09-12)** — result: **FLOOD_FILL cannot capture entity 14's drawbridge door, under any material/seed configuration tried.** This was tested directly against the actual drawbridge (not the still-unbuilt lateral door — see §7 note), by temporarily flipping entity 14 to `FLOOD_FILL` via direct API calls and running the real `GateBlockScan` headless task against the live world, then restoring it:

1. **Unfiltered** (seed = the door's existing anchor/ref1/ref2 corner points, plane-constrained, no material whitelist): capped at `ScanMaxBlocks=500` with `status: Warning` — only 11 of 500 returned blocks were the door's actual material (`minecraft:spruce_log`); the rest (338 air, 54 stone_bricks, 33 cobblestone, plus dirt/gravel/andesite/stairs) was the surrounding castle wall the flood fill bled into. A plane constraint alone does not stop it from traversing air and adjacent wall material.
2. **Whitelisted to `spruce_log`/`stripped_spruce_log`/`spruce_trapdoor`**, same three corner seeds: `status: Success`, but only **3 blocks** — exactly the three seed points, each isolated with no matching-material neighbor. The corner/reference points are evidently frame posts, not part of a contiguous deck surface.
3. **Whitelist widened** to also include `oak_slab`/`oak_stairs` (which had suspiciously high counts in run 1, suggesting real deck detail rather than wall clutter): same 3 isolated blocks — still no connection found.
4. **Reseeded from five interior points** of the known 4×8 rectangle (not the corners): `status: Success`, only **2** mutually-adjacent `spruce_log` blocks found.

**Conclusion**: this isn't a seed-choice or whitelist-tuning problem — the door's own blocks are not mutually face-adjacent. The visible drawbridge deck is built from a mix of full blocks, slabs, and stairs, which by nature leave air gaps between individual pieces at the level BFS traverses (face-to-face). **FLOOD_FILL requires physical material contiguity, which this door's actual construction doesn't have — no material whitelist can fix that.** This confirms FLOOD_FILL is not a viable substitute for item 6's region-based capture, at least for decoratively-detailed doors like this one, and closes the "maybe we don't need new work at all" question definitively: the region-based work is needed.

(Separately, per the original design intent, FLOOD_FILL was never targeted at DRAWBRIDGE in the first place — this test aimed at the actual motivating use case per the reporter: making entity 14's own drawbridge door non-rectangular, not the still-unbuilt lateral door from item 5.)

## 4. Option comparison

| Criterion | Option 1: WorldGuard region | Option 2: WorldEdit-only | Option 3: Custom selection |
|---|---|---|---|
| **New code to write** | Low — adapt `WgRegionIdTaskHandler`'s existing selection→persist flow to gate creation | Medium — reuse WE's `Region`/selection API for drawing + containment, but write new persistence (polygon vertices → KnK DB) since WG's region store is skipped | High — selection UX, point-in-polygon containment, and persistence all from scratch |
| **Admin usability** | No new paradigm — admins who set up districts/towns already know the `//sel poly` → "save region" flow from `WgRegionIdTaskHandler` | Same drawing UX (still WorldEdit `//sel`), but a different (new) "save" command since it's not going through WG's region-create flow | New selection tooling means new admin training regardless of how well-designed; also the highest UX risk (untested UX from scratch) |
| **Performance** | WG's `ApplicableRegionSet`/region containment is already used at runtime scale (player region-transition tracking) — proven fine for this codebase's scale | WE's `Region` interface (used for iteration/containment) is the same underlying library WG already depends on; no new perf characteristics vs Option 1 for the scan/animation-clip path | Point-in-polygon and iteration would be hand-rolled; risk of subtle inefficiency or correctness bugs under adversarial polygon shapes (self-intersecting, concave) that WE has already hardened against over years of production use |
| **Reliability** | Reuses tested code (`WgRegionIdTaskHandler`, `GateBlockPairing`'s mismatched-block-count pairing) | Reuses WE's region math (mature), but the KnK-side persistence layer (new DB schema + serialization) is new and untested | Highest risk — polygon/containment edge cases are a classic source of subtle bugs; the team would be re-solving a problem WorldEdit has already solved |
| **Persistence footprint** | None new — region shape lives in WG's own store; DB keeps storing an opaque name string, consistent with existing `RegionClosedId`/`RegionOpenedId` pattern | New: a polygon/cuboid vertex list needs a new DB shape (e.g. JSON column) on `GateStructure`/`GateDoor`, since WG's persistence layer is deliberately skipped | New: same as Option 2, plus no ecosystem tooling (WG's `/rg` commands, WE's `//sel` visualization) to inspect/debug what's stored |
| **Coupling introduced** | Unifies today's two independent, currently-unrelated concepts — `RegionClosedId`/`RegionOpenedId` (used only for entry-flag access control) and block-scan geometry — into one WG region per state. This is either a welcome simplification or an unwanted coupling depending on whether access-control shape and animation shape should ever diverge (see Open Questions). | Keeps geometry fully decoupled from the existing WG access-control regions — arguably the more correct architecture today, since those two concepts are unrelated in the current code | Fully decoupled, same as Option 2, but at much higher cost for the same architectural benefit |
| **Portability (engine-migration angle)** | No incremental cost — the plugin's territory model is already fully WG-dependent; removing WG from gates specifically doesn't meaningfully improve overall portability while WG remains load-bearing for `RegionDomainResolver` | Marginally more portable geometry *data* (own DB rows vs WG's opaque store), but still depends on the WorldEdit *API* to create/edit that data, so the actual migration risk (dependency on a Minecraft-specific plugin API) is only partially reduced | Most portable in principle, but this benefit is diluted almost to zero by the fact WG is already permanently load-bearing elsewhere in the plugin — a future engine migration would have to solve WG-in-territories regardless, making a WG-free gate subsystem a partial, low-value win |

## 5. Rework required regardless of which option is chosen

Two rectangle-specific choke points in the animation layer exist independent of the geometry-capture option:

1. **`GateFrameCalculator.isWithinGeometryBounds`** (`knk-core/.../gates/GateFrameCalculator.java:91-116`) clips animated block positions against a `Width × Height × Depth` oblique box. A polygon footprint needs this reworked into a point-in-polygon/region-containment check — for which `WgRegionIdTaskHandler`'s existing polygon vertex containment code (lines 427-578) is a direct template, or WorldEdit's own `Region.contains(...)` can be used directly regardless of which persistence option is chosen.
2. **Mechanism 1's rotation gap-fill, `rasterizeRotationFrame`** (`GateFrameCalculator.java:259-390`) is rectangle-specific — it uses `width-1`/`height-1` corner indices to gap-fill a rotated rectangular sheet for diagonal-hinge doors (DRAWBRIDGE-type gates). This is the highest-effort rework item and is **not solved by picking a region-capture option** — it needs its own design work to generalize rotation rasterization to an arbitrary polygon footprint. **Decided (2026-09-11): rotation-type gates are in scope for v1** (not deferred) — entity 14's drawbridge is a primary motivating case, so this generalization work is part of item 6's scope, not a follow-up.

The good news: everything else in the animation pipeline is already shape-agnostic by design —
- `GateFrameCalculator.calculateBlockPosition` computes each block's position independently via its own stored relative offset, not by scan-order/index pairing.
- `GateBlockPairing`'s greedy nearest-neighbor matcher (`knk-core/.../gates/GateBlockPairing.java:32-70`) already tolerates open/closed scans with **different block counts**, unit-tested — exactly what a polygon closed-state paired with a differently-shaped polygon open-state would produce.
- `GateAnimationTask` iterates `gate.getBlocks()` as a plain list; it never assumes a particular order or count tied to rectangular geometry.

So a polygon rework is scoped narrowly to (1) how the shape is captured/persisted, and (2) the two choke points above — not a rewrite of the animation engine.

## 6. Decision (2026-09-11)

**Option 2 — WorldEdit-only capture, KnK-owned persistence — with one added requirement: the stored region must round-trip back into an active WorldEdit session for re-editing, not just be captured once.**

Rationale (as originally recommended, now confirmed):
- Gate door geometry and WG access-control regions (`RegionClosedId`/`RegionOpenedId`) are unrelated concepts *today* — Option 2 preserves that separation, which matches current architecture rather than introducing new coupling. Confirmed: these stay independent (§7.2).
- It still fully reuses WorldEdit's mature, hardened selection UX and region/containment math — the actual hard, easy-to-get-wrong part of "arbitrary polygon support" — so it captures nearly all of Option 1's reliability benefit without adopting WG's protection/flag semantics for something that doesn't need them.
- The extra cost over Option 1 is narrow and well-understood: one new persistence shape (polygon/cuboid vertex list) on the `GateStructure`/`GateDoor` model, mirrored in `GateStructureDto.java`/`GateStructureDtos.cs`/`GateStructureMappingProfile.cs` — not new selection or containment logic.
- **Option 1 remains the documented fallback** if Option 2's persistence + round-trip-editing work proves costlier than expected once scoped in detail — the `WgRegionIdTaskHandler` pattern is ready to be pointed at gates directly with comparatively little adaptation, accepting the coupling tradeoff noted in §4.
- **Option 3 (custom) was rejected.** Highest implementation and reliability risk for a portability benefit that's largely moot given WorldGuard's existing, permanent role in the plugin's territory system.

**New requirement — round-trip editing**: unlike `WgRegionIdTaskHandler`'s one-way "draw once, save forever" flow, an admin must be able to reopen an existing gate door's stored region and redraw/adjust it with WorldEdit tooling. This needs a design for re-hydrating a stored polygon/cuboid vertex list into an active WorldEdit `LocalSession` (see §7, still open).

**Rotation scope — decided in scope for v1**: DRAWBRIDGE/rotation-type gates get polygon support in v1, not deferred. This means Mechanism 1's rotation rasterizer generalization (§5, item 2) is **required scope for this item**, not optional follow-up work — it's the single biggest effort driver and should be estimated/designed accordingly.

**Sequencing**: this item ships *after* [QOL_BUGFIX_BACKLOG.md #5](../../backlog/QOL_BUGFIX_BACKLOG.md#5-support-for-multiple-gate-doors-per-gate-structure) (multi-door support / the new `GateDoor` entity), so region data lands on `GateDoor` directly rather than requiring a second migration on the single-door `GateStructure` model.

**FLOOD_FILL check is complete (§3)** — it does not work for this door, no scope reduction from it. The region-based approach is the only viable path forward for entity 14's drawbridge.

## 7. Questions

### Resolved (2026-09-11 planning meeting; FLOOD_FILL check completed 2026-09-12)
1. ~~Does `FLOOD_FILL` already solve the reported use case?~~ → **No.** Tested directly against entity 14's live drawbridge (bypassing the form via direct API calls + the real headless `GateBlockScan` task) across four seed/whitelist configurations — never found more than 2-3 mutually-adjacent blocks of the door's actual material. The door's construction (mixed full blocks/slabs/stairs) doesn't have the face-to-face material contiguity BFS flood fill requires. See §3 for full detail. This removes any "maybe no new work is needed" possibility — region-based capture is confirmed necessary.
2. ~~Should geometry regions ever be the same region as access-control regions?~~ → No — keep independent. Matches current architecture; avoids coupling animation shape to access-control shape.
3. ~~Is rotation-type polygon support required for v1?~~ → Yes, in scope for v1 (§6).
4. ~~Does open-state region data belong on `GateStructure` or the new `GateDoor` entity?~~ → `GateDoor`, once item 5 ships first (§6, sequencing).

### Resolved 2026-09-13 (item 6.1 design spike — see §9)
5. ~~Concrete design for round-trip region editing~~ → **Resolved, §9.2**: `LocalSession.setRegionSelector(World, RegionSelector)` + `Polygonal2DRegionSelector`/`CuboidRegionSelector` constructed directly from stored vertex data, then `dispatchCUISelection` (both confirmed to exist with the needed signatures via direct `javap` inspection of the resolved WorldEdit jar). Effort: Small.
6. ~~Effort estimate for generalizing `rasterizeRotationFrame` to arbitrary polygon footprints~~ → **Resolved, §9.3**: the diagonal-hinge collision-handling core (steps 2/3/3b) is already shape-agnostic; only the corner list (step 1) and containment predicate (step 4) need swapping from rectangle-specific to polygon-based. Effort: Small-to-Medium (~1-1.5 days), Low-Medium risk.

## 9. Design spike (item 6.1) — resolved 2026-09-13

Resolves both "Still open" items from §7. This section is additive — §6's decision stands unchanged; 6.2-6.7 can now be implemented against the concrete mechanisms below rather than against an unsized open question. Written against the codebase as it stands after item 5 (multi-door `GateDoor`) landed — `GateDoor.GeometryDefinitionMode`/`RegionClosedId`/`RegionOpenedId` already exist (`knk-web-api-v2/Models/GateDoor.cs:49,158,161`), `GeometryDefinitionMode` is currently `{PLANE_GRID, FLOOD_FILL}` (`knk-web-api-v2/Models/GateStructureEnums.cs:11-15`), and `CachedGateDoor.getGeometryDefinitionMode()` already exists plugin-side (`knk-core/.../domain/gates/CachedGateDoor.java:198`) — so the branching hook 6.6 needs is already in place, nothing new to add there.

### 9.1 Persistence shape for `ClosedRegionData`/`OpenedRegionData` (needed by both 9.2 and 9.3 below)

6.2 decided *that* these columns hold "raw polygon/cuboid vertex-list JSON" but not the concrete shape. Proposed shape, chosen to mirror WorldEdit's own two selector types 1:1 (zero lossy translation, trivially reconstructible):

```json
{
  "type": "POLYGON2D",
  "worldName": "world",
  "points": [{"x": 100, "z": 200}, {"x": 108, "z": 200}, {"x": 108, "z": 206}],
  "minY": 64,
  "maxY": 68
}
```

or, for a cuboid capture:

```json
{
  "type": "CUBOID",
  "worldName": "world",
  "pos1": {"x": 100, "y": 64, "z": 200},
  "pos2": {"x": 110, "y": 68, "z": 210}
}
```

or, for a convex polyhedron capture (`//sel convex`, added in the §9.4 follow-up — the general-purpose answer for a shape that isn't genuinely horizontal or axis-aligned):

```json
{
  "type": "CONVEX_POLYHEDRON",
  "worldName": "world",
  "points": [{"x": 100, "y": 64, "z": 200}, {"x": 104, "y": 67, "z": 200}, {"x": 100, "y": 64, "z": 206}]
}
```

The `type` discriminator lets both the round-trip loader (9.2) and the headless region scanner (6.5) reconstruct the exact right WorldEdit `Region`/`RegionSelector` without re-deriving it from point count or other heuristics.

### 9.2 Round-trip region editing (resolves §7 item 5)

**Design**: re-hydrate the stored vertex list directly into the admin's active WorldEdit `LocalSession` via `LocalSession.setRegionSelector(World, RegionSelector)`. Confirmed against the actual dependency jar (`worldedit-core-7.3.0.jar`, package `com.sk89q.worldedit.regions.selector`, verified via `javap` against the resolved Gradle artifact) that both constructors needed for this exist and take exactly the stored data as input, no replay of `selectPrimary`/`selectSecondary` clicks required:
- `Polygonal2DRegionSelector(World, List<BlockVector2> points, int minY, int maxY)`
- `CuboidRegionSelector(World, BlockVector3 pos1, BlockVector3 pos2)`

Flow for a new `/knk gate door redefine <structure> <door> [closed|opened]` command (6.4):
1. Load the door's `ClosedRegionData`/`OpenedRegionData`, parse per the 9.1 shape.
2. Construct the matching selector from the stored `type` (`Polygonal2DRegionSelector` or `CuboidRegionSelector`).
3. `session.setRegionSelector(world, selector)` — the one call that actually re-hydrates the shape into the session. Everything downstream (drag-handle editing via CUI, `//` commands, `/undo`) is then just normal WorldEdit behavior operating on a selector that happens to start pre-populated instead of empty.
4. `session.dispatchCUISelection(player)` — the same call `WgRegionIdTaskHandler.startTask` already makes for a *fresh* selection (`WgRegionIdTaskHandler.java:112`); syncs the client-side CUI markers so the admin immediately sees the existing shape, not just an invisible-but-editable selection.
5. Reuse `WgRegionIdTaskHandler.handleSave`'s exact validate-then-persist tail (`WgRegionIdTaskHandler.java:199-295`) for the resave: on `'save'`, pull `session.getSelection(world)`, re-serialize its vertices to the 9.1 shape, `PATCH` the `GateDoor`.

This closes the round-trip loop with **zero new WorldEdit-side mechanism** — `setRegionSelector`/`dispatchCUISelection` are both already-public API, and `dispatchCUISelection` is already called once in this exact codebase for the fresh-selection case. The genuinely new part is entirely KnK-side: a small loader from stored JSON into these two constructors, plus the new `redefine` command. None of `WgRegionIdTaskHandler`'s WG-region bookkeeping (temp region naming, flag copying, `RegionManager.addRegion`) applies, since Option 2 (§6) deliberately skips WG's region store — this flow only ever touches a `LocalSession`, never `RegionManager`.

**Effort**: Small — closer to "a new command handler calling two existing WorldEdit methods, then reusing `handleSave`'s existing tail" than a new subsystem.

### 9.3 Rotation rasterizer generalization (resolves §7 item 6)

**Key finding that keeps this narrow**: the existing anchor/`ReferencePoint1`/`ReferencePoint2`-derived u/v/n basis (`GateLoaderAdapter.precomputeBasisVectors`, `knk-paper/.../gates/GateLoaderAdapter.java:292-341`) is **retained unchanged** for `REGION` mode, not replaced. `REGION` mode still requires `AnchorPointId`/`ReferencePoint1Id`/`ReferencePoint2Id` to be set exactly as `PLANE_GRID` requires today — this pins down the door's plane and (for `ROTATION` gates) the hinge line, which the captured WorldEdit polygon does not itself encode. The polygon supplies a precise **in-plane footprint** layered on top of that basis, not a replacement for it. This single decision is what turns the generalization from "redesign the geometry model" into "swap two predicates inside an already-shape-agnostic algorithm."

Also confirmed compatible with 6.5 (region-based scanning) already: `GateBlockScanTaskHandler`'s existing `FLOOD_FILL` path stores `BlockSnapshot.relativePosition` as a raw `worldPos - origin` offset (`GateBlockScanTaskHandler.java:608-610`), **not** a lattice index — `PLANE_GRID`'s `i*uStep + j*vStep` (`computeCellPosition`, line ~381) is one way to reach that same storage format, not the only legal one. So `REGION`-mode scanning (iterate the reconstructed `Region`'s contained blocks, store `worldPos - anchor` per block) needs no new `BlockSnapshot` convention — it follows the exact pattern `FLOOD_FILL` already established.

**Concrete changes** (all in `knk-core`'s `gates` package plus `GateLoaderAdapter`, none touching `GateBlockPairing`/`GateAnimationTask`):

1. New pure helper `GateFrameCalculator.pointInPolygon(double u, double v, List<double[]> polygonUV)` — standard even-odd ray-casting, ~20 lines, no Bukkit dependency (matches every other method in this file), directly unit-testable.
2. `CachedGateDoor` gains `closedFootprintUV`/`openFootprintUV` (each a `List<double[]>` of `{u, v}` pairs) — precomputed once at load, mirroring how `uStep`/`vStep`/`nStep` are already precomputed once rather than per-frame.
3. `GateLoaderAdapter` gains `precomputeFootprintPolygon(gate, dto)`: for `REGION` mode, parse `ClosedRegionData`/`OpenedRegionData` per 9.1, project each world-space vertex through `projectOntoBasis(vertex - anchor, uStep, vStep, nStep)` to get `(u, v)` pairs. A `CUBOID`-typed capture is expanded to its 4 rectangle corners first, then follows the identical path — a cuboid is just a 4-vertex polygon, so no separate code path is needed past that expansion. **Implementation note**: `projectOntoBasis` is currently `private static` in `GateFrameCalculator` (`knk-core`); since `GateLoaderAdapter` lives in a different module/package (`knk-paper`), this needs widening to `public static` — a one-line visibility change, called out here so it isn't a surprise mid-implementation.
4. `GateFrameCalculator.isWithinGeometryBounds`: add a `REGION` branch. Project `worldPosition` exactly as the existing box case already does (lines 110-111, unchanged), then instead of three `withinAxis` calls, test `withinAxis(indices[2], depth)` (the n/depth slab check — unchanged, a region is still a bounded-thickness slab) **and** `pointInPolygon(indices[0], indices[1], gate.getClosedFootprintUV())`.
5. `GateFrameCalculator.rasterizeRotationFrame`: exactly two localized swaps, structure otherwise unchanged —
   - Step 1 (lines 278-285, corner rotation): instead of the hardcoded `cornerIndices = {{0,0},{width-1,0},{0,height-1},{width-1,height-1}}`, iterate `gate.getClosedFootprintUV()`'s actual vertices (any count, not fixed at 4) to build `rotatedCorners`.
   - Step 4 (lines 368-386, containment test): replace `withinAxis(idx[0], width) && withinAxis(idx[1], height)` with `pointInPolygon(idx[0], idx[1], gate.getClosedFootprintUV())`; the existing `Math.abs(idx[2]) > BOUNDS_EPSILON` single-layer n-check is untouched.
   - Steps 2 (AABB of rotated corners), 3 (`byIndex` block-to-index lookup), and 3b (collision resolution, blocks processed farthest-from-hinge-first via `Math.abs(idx[1])`) are **unchanged** — none of them assume a rectangular footprint. 3b's sort only depends on each block's own v-index, which stays meaningful precisely because of the basis-retention decision above (the hinge still lies along the v≈0 edge, exactly as today).
6. New regression test: feed `rasterizeRotationFrame`/`isWithinGeometryBounds` a 4-vertex rectangular `closedFootprintUV` matching an existing `PLANE_GRID` gate's width/height, and assert byte-identical output to today's box-based code path against the existing `GateFrameCalculatorTest` fixtures (entity 14's drawbridge among them). This is the safety net that the generalization is a strict superset — "still passes every existing PLANE_GRID test unmodified" — not just new `REGION`-mode coverage.

**Effort estimate**: Small-to-Medium — roughly 1-1.5 days for `GateFrameCalculator`/`CachedGateDoor`/`GateLoaderAdapter` combined (6.6's core; separate from 6.5's own scan-handler work), smaller than the "explicitly unsized" framing in §5/§7 implied. The reason: steps 2/3/3b of `rasterizeRotationFrame` — the genuinely hard part, the diagonal-hinge lattice-collision handling from `ROTATION_GAP_FILL_DESIGN.md` — turn out to already be shape-agnostic, so generalizing is a two-point surgical swap (corner list, containment predicate) inside an algorithm that doesn't otherwise change, not a rewrite. Risk: Low-Medium — both swapped call sites are small, already covered by tests that must keep passing unmodified, and `pointInPolygon` is a well-known, easily-tested primitive.

**Non-goal, confirmed still out of scope**: multi-layer (`GeometryDepth > 1`) `ROTATION`+`REGION` doors. `rasterizeRotationFrame`'s existing single-layer (`n≈0`) assumption (comment at lines 360-367) is unchanged by this generalization and remains unaddressed — exactly as already flagged for `PLANE_GRID` in `ROTATION_GAP_FILL_DESIGN.md`. Not a new limitation introduced here.

### 9.4 Follow-up: `CONVEX_POLYHEDRON` capture, resolving the orientation gap found during 6.6

**Gap found while implementing 9.3 (2026-09-13)**: `POLYGON2D` and `CUBOID` — the only two capture shapes 9.1 originally specified — can each only precisely represent a *specific* kind of footprint. `Polygonal2DRegion` is an X/Z-plane outline extruded through a Y range: every captured vertex collapses onto the region's own `minY`, so a vertically-standing door's real height variation is lost entirely (its outline degenerates toward a line). `CuboidRegion`'s two corner points are always world-axis-aligned, so it can't precisely bound a diagonally-oriented rectangular door (e.g., entity 14's diagonal hinge, per its fixture data in `GateFrameCalculatorTest.buildRealGate14`) outside the horizontal plane either. Both are solid for a genuinely horizontal-ish footprint (a rotating deck, viewed from above — the documented primary motivating case) but not an arbitrary 3D orientation. This was flagged to the user rather than silently worked around, since it directly affects whether entity 14's *actual* closed-state shape (unknown at the time — vertical wall vs. horizontal deck) can be captured precisely at all.

**Resolution, requested and implemented same day**: add `CONVEX_POLYHEDRON` as a third capture shape, backed by WorldEdit's `ConvexPolyhedralRegion` (`//sel convex`). Each vertex carries its own independent `(x, y, z)` — nothing collapses — so it correctly represents *any* orientation, not just horizontal/axis-aligned ones.

- **JSON shape**: `{"type": "CONVEX_POLYHEDRON", "worldName": "...", "points": [{"x","y","z"}, ...]}` — no `minY`/`maxY` needed, since Y is per-point now. Added to 9.1's shape family alongside `POLYGON2D`/`CUBOID`.
- **API asymmetry worth knowing**: unlike `Polygonal2DRegionSelector`/`CuboidRegionSelector` (both take all points/corners in one constructor call), `ConvexPolyhedralRegionSelector` has no such constructor — it's built incrementally via `selectPrimary(firstVertex, limits)` then `selectSecondary(vertex, limits)` per remaining vertex (with `PermissiveSelectorLimits.getInstance()` for "no limit"), mirroring how WorldEdit's own `//sel convex` UX itself builds one click-by-click. This only affects round-trip redefine (9.2)'s reconstruction path, not capture (writing) or scanning (reading via `Region.iterator()`, which `ConvexPolyhedralRegion` supports for free via `AbstractRegion`'s generic bounding-box+`contains()` iterator, same as the other two types).
- **The one new wrinkle, solved**: WorldEdit exposes a `ConvexPolyhedralRegion`'s vertices as an unordered `Set<BlockVector3>`, but `pointInPolygon`'s ray-casting (9.3, item 1) requires points traced around the boundary in order. Solved with a new `GateFrameCalculator.convexHull2D` (Andrew's monotone chain, O(n log n)) applied to the *projected* (u, v) points — safe specifically for this capture type because a convex 3D shape's projection onto any plane is itself convex, so re-deriving the 2D hull after projection recovers a valid boundary trace regardless of input order. Deliberately **not** applied to `POLYGON2D`/`CUBOID` footprints (gated on a new `GateRegionDataFormat.isConvexPolyhedron` check) — hulling a legitimately concave `POLYGON2D` capture (e.g. an L-shaped outline) would silently convexify away the concave notch.
- **No changes needed in the rotation rasterizer or animation math itself** — confirms the 9.3 layering decision held up under a real follow-up requirement. `isWithinGeometryBounds`/`rasterizeRotationFrame` both already operate purely on the resulting `List<double[]> footprintUV`, agnostic to how those vertices were captured in 3D; the entire fix was scoped to the region-data-format/projection layer (`GateRegionDataFormat`, `GateLoaderAdapter.projectFootprintToUV`).
- Implemented in `knk-plugin-v2` (now `knk-plugin` — see the September 13 repository rename note) commit `cf8cbd7`. New tests: 4 pure `convexHull2D` cases (shuffled square, interior-point exclusion, shuffled triangle, degenerate inputs) plus a disabled `GateLoaderAdapterTest` case (same WorldEdit-not-on-test-classpath constraint as the existing `POLYGON2D` one) demonstrating a vertically-standing door's shape survives intact where `POLYGON2D` would have degenerated.
- **Still open**: whether entity 14's actual closed-state shape needs `CONVEX_POLYHEDRON` at all, or whether it's genuinely a horizontal deck that `POLYGON2D`/`CUBOID` already handle fine — unknown until 6.7's in-game testing against the real structure. `CONVEX_POLYHEDRON` is now available either way.

## 10. Sources

All findings verified directly against the repository on branch `gate-structure-animation`:
- `knk-plugin-v2/knk-paper/build.gradle.kts`, `knk-paper/src/main/resources/plugin.yml`
- `knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/GateBlockScanTaskHandler.java`
- `knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/WgRegionIdTaskHandler.java`
- `knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/integration/WorldGuardIntegration.java`
- `knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/regions/WorldGuardRegionTracker.java`
- `knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/gates/GateLoaderAdapter.java`
- `knk-plugin-v2/knk-core/src/main/java/net/knightsandkings/knk/core/regions/RegionDomainResolver.java`
- `knk-plugin-v2/knk-core/src/main/java/net/knightsandkings/knk/core/gates/GateFrameCalculator.java`
- `knk-plugin-v2/knk-core/src/main/java/net/knightsandkings/knk/core/gates/GateBlockPairing.java`
- `knk-plugin-v2/knk-core/src/main/java/net/knightsandkings/knk/core/domain/gates/CachedGateDoor.java`
- `knk-plugin-v2/knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/GateStructureDto.java`
- `knk-web-api-v2/Models/GateStructure.cs`, `knk-web-api-v2/Models/GateDoor.cs`, `knk-web-api-v2/Models/GateStructureEnums.cs`, `knk-web-api-v2/Models/Location.cs`
- `worldedit-core-7.3.0.jar` (`com.sk89q.worldedit.regions.selector.Polygonal2DRegionSelector`/`CuboidRegionSelector`, `com.sk89q.worldedit.LocalSession`) — inspected directly via `javap` against the resolved Gradle dependency to confirm exact constructor/method signatures, not assumed from memory of the WorldEdit API.
