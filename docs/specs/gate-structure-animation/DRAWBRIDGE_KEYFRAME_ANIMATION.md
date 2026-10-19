# Drawbridge Animation: Analysis and Keyframed-Plank Proposal

**Status:** Implemented and merged (2026-10-19, [KNG-193](https://linear.app/kngpandi/issue/KNG-193)): knk-plugin
`main` `79be4882` (§9 steps 1-3: `knk-core/.../gates/DrawbridgeKeyframes`, load, playback, resting frames, sweep, switch
`gates.rotation.keyframes-enabled`), knk-web-api `master` `2d71155` (§9 step 4: GateDoor seed v2), the docs of §9 step 6.
The Java keyframes match the reference script cell for cell on every fixture of §5.9. **Live check (§9 step 5): passed
2026-10-19 on gate door 14 only** ("works perfectly"); the cardinal, arched, switch and fall-back checks were accepted by
the developer without a run ([guides/gate-smoke-test.md §3](../../guides/gate-smoke-test.md)). Next: delete the old
path, [KNG-194](https://linear.app/kngpandi/issue/KNG-194) (D6). Decided 2026-10-16 (D1–D8, §8); the step-0 data
check passed on 2026-10-16 (§4.2, §9).
**Rev. 2 (2026-10-15, developer request):** the method must support door shapes that are not rectangular, such as an
arched top. Added §5.11. The door's shape is now the set of scanned blocks, and the width rule, materials, sizes,
decisions D7–D8 and the plan were updated to match.
**Last updated:** 2026-10-19 (merged; live check on gate door 14 passed, the rest accepted without a run)
**Author:** Claude (requested by Pandi)
**Related:**
- [ROTATION_GAP_FILL_DESIGN.md](ROTATION_GAP_FILL_DESIGN.md). This proposal revisits its Decision 3 and replaces the mid-swing part of Decisions 7, 8, 8.1 and 8.2 for `ROTATION` gates.
- [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md), item 6.
- [KNG-132](https://linear.app/kngpandi/issue/KNG-132) (Ref 2 must be straight above the anchor; merged by 2026-10-19).
- [KNG-106](https://linear.app/kngpandi/issue/KNG-106) (entity safety, `GateSweep`).

Scope: `ROTATION` gates with a horizontal hinge (`DRAWBRIDGE`, and `TRAP`/`SLIDING` set to `ROTATION`), cardinal and
diagonal. `VERTICAL`/`LATERAL` gates are not touched. `DOUBLE_DOORS` would reuse the same method later (§5.10).

---

## 1. Summary

Today a drawbridge is drawn mid-swing as a **cloud of separate points**: each scanned block is rotated on its own and
rounded to a cell. For a diagonal gate with a scanned open state, a stack of per-block corrections sits on top of that:
- a rigid fit,
- a residual eased in with `progress⁵`,
- a 0.5-block snap,
- start points made up for the 17 blocks that only exist in the open scan.

Each layer was the right fix for a jam or an orphaned block. Together they make different parts of the door move at
different speeds: the far end lags, then catches up block by block. That is the "moving blob".

Two root causes sit under all of it:
1. **Points instead of a shape.** A tilted plane sampled at one point per scanned block cannot fill the cells the plane
   crosses. Blocks collide and holes open. This happens on cardinal gates too: a 4×8 cardinal door shows 20 of its 32
   blocks at mid-swing.
2. **Two different lengths on a diagonal.** A true rotation keeps true length. Players and builders count blocks.
   - An 8-tall door on a 45° hinge, rotated rigidly, reaches only 7.0 blocks from the hinge.
   - Entity 14's built open deck reaches about 9.2 blocks.
   - No rigid motion connects those two states. The per-block corrections exist to bridge that gap, so they can never
     look rigid.

**Proposal: a keyframed plank.** Treat the door as a 2D side profile (the door's cross-section, perpendicular to the
hinge) that is extruded along the hinge.
- Coordinates use the grid's own diagonal steps, so a diagonal gate behaves exactly like a cardinal one.
- Each keyframe draws the whole door as one straight plank: a digital line, the block equivalent of a straight line.
  It has no gaps, and its outline follows the door's own shape.
- Between keyframes the plank's tip moves exactly one cell.
- Keyframes are computed once at load and applied atomically, one whole shape per update, about every 4–5 ticks.
- The open deck's length comes from the open scan if one exists, otherwise from a length value (§6).
- The pairing, rigid fit, residual and snap machinery is no longer needed for `ROTATION`.
- **Any door shape works** (§5.11): arched or pointed tops, battlements, notches, cut-outs. The door's shape is the set
  of blocks the closed scan found. Each keyframe samples that shape along the plank, the way a texture is sampled. The
  closed keyframe equals the scan exactly, and the plank is never wider than the door at that height.

For entity 14 (4 wide × 8 tall, 45°) this gives **21 keyframes**: 32 blocks closed and **49 blocks open**. Both end
frames match the stored scans cell for cell (checked against the dev DB seed, §4.2), and every in-between frame is a
clean plank. A display-entity swing (§7) was considered and
dropped (D5): the block keyframes are the final look.

---

## 2. Reading list: which documents matter, and which are stale

| Document | What it gives you | State |
|---|---|---|
| [ROTATION_GAP_FILL_DESIGN.md](ROTATION_GAP_FILL_DESIGN.md) | The checkerboard math (`sublattice index = a²+b²`), Mechanism 1 (filled endpoints only), Mechanism 2 (scanned open state), Decisions 1–8.2 with live evidence from entity 14 | **Current** (header updated 2026-09-20) |
| [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md) item 6 (§6.1–6.11.3) | REGION capture, entity 14's real coordinates, five live-test rounds, the user's description of the open deck (§6.7) | **Current** |
| [WORLDGUARD_REGION_FEASIBILITY.md](WORLDGUARD_REGION_FEASIBILITY.md) §9 | Why `//sel convex` is needed for a diagonal or vertical door | Current |
| [GATE_WORLD_SYNC_DESIGN.md](GATE_WORLD_SYNC_DESIGN.md) | Startup reconciliation of resting frames | Current (live validation open) |
| [DUAL_SCAN_ANIMATION_DESIGN.md](DUAL_SCAN_ANIMATION_DESIGN.md) | First open-state idea | **Superseded** by ROTATION_GAP_FILL Decision 6 |
| [SPEC.md](SPEC.md) | Entity and DTO overview | **Stale** (Jan 31). Its gap-fill section still describes the per-block blend and greedy pairing as current |
| [SPEC_GATE_ANIMATION.md](SPEC_GATE_ANIMATION.md), [REQUIREMENTS_GATE_ANIMATION.md](REQUIREMENTS_GATE_ANIMATION.md) | Original rotation formula and "stable sort + last write wins" | **Stale**. Claims "no holes during rotation", which is not true (§4.1). Placement is now `placeBlockIfVacant` plus jam detection |
| [DECISIONS.md](DECISIONS.md), [PHASE_STATUS.md](PHASE_STATUS.md), [INDEX.md](INDEX.md), [AI_INDEX.md](AI_INDEX.md), the roadmaps | January planning | **Stale**. No animation decisions, no REGION mode, old `docs/features/...` paths |
| [GATE_FORMCONFIG.md](GATE_FORMCONFIG.md) | Form plan (Dutch) | **Stale**. Targets GateStructure, not GateDoor |
| [../../architecture/gate-commands.md](../../architecture/gate-commands.md), [../../guides/gate-smoke-test.md](../../guides/gate-smoke-test.md) | Commands, `GateSweep` and evacuation (KNG-106) | Current (2026-10-10) |

All rotation work so far was developed and live-tested on **one gate**, entity 14 "Northern Gate". The docs record no
live test of:
- a cardinal drawbridge,
- a diagonal drawbridge without an open scan,
- `DOUBLE_DOORS`.

---

## 3. How it works today

### 3.1 What the admin supplies and what is stored (knk-web-api `Models/GateDoor.cs`)

| Field | Meaning | How it is set | Used by the animation |
|---|---|---|---|
| `AnchorPointId` | Cell (0,0,0) of the closed door and the rotation pivot | Location world task (right-click a block or type `save`) | Pivot; base of every block position |
| `ReferencePoint1Id` | Far end of the bottom (hinge) row: the width direction | Location world task | `uAxis` = hinge direction; `uStep` = primitive grid step, e.g. (-1,0,1) |
| `ReferencePoint2Id` | Top of the door straight above the anchor: the height direction | Location world task. KNG-132 (unmerged) refuses a Ref 2 that is not at right angles | `vAxis`/`vStep` |
| `GeometryWidth` / `GeometryHeight` | Number of cells along u / v | Derived read-only in the web form: grid hops + 1 (`utils/forms/gateGeometry.ts`) | Scan bounds, clipping, rasterizer |
| `GeometryDepth` | Thickness along n | Typed | Clipping only; the rasterizer assumes 1 |
| `GateType`, `MotionType` | `DRAWBRIDGE` + `ROTATION` | Typed/selected. Not derived from each other | `MotionType` picks the formula; `GateType` picks the hinge (`DOUBLE_DOORS` → v, everything else → u) |
| `RotationMaxAngleDegrees` | Swing angle (default 90) | Typed | `angle = max × progress` |
| `AnimationDurationTicks` / `AnimationTickRate` | Frame count / place every n-th frame | Typed (tick rate 1–5) | `frame = elapsed ticks`, `progress = frame / duration` |
| `MotionDistanceBlocks` | Travel for VERTICAL/LATERAL (0 = height/width) | Typed | **Not used for ROTATION** |
| `OpenAnchorPointId` | Origin of a separately built open shape | Location world task | Base of the open-scan block positions |
| `ClosedRegionData` / `OpenedRegionData` | WorldEdit selection JSON (poly/cuboid/convex) | `/gatedoor capture <door> closed\|opened` | REGION scan and footprint polygon |
| `GeometryDefinitionMode` | `PLANE_GRID` / `FLOOD_FILL` / `REGION` | Selected | Scan method. The swing itself does not read it (proven by trace diff, ROTATION_GAP_FILL Decision 7) |
| `FaceDirection` | 8-way facing | Selected | Push direction, info display, safe spots. **Not** the basis |
| `HingeAxisId`, `MirrorRotation` | — | Stored | **Never read by the plugin.** The hinge is derived from Ref 1 |

Blocks are stored in two separate tables, `gate_block_snapshots` (closed) and `gate_opened_block_snapshots` (open), with
identical columns:
- `RelativeX/Y/Z` is a **world-axis offset** (`i·uStep + j·vStep + k·nStep`, rounded), not a u/v/n index;
- `WorldX/Y/Z`;
- `MaterialName`;
- `BlockDataJson` (actually Bukkit's `getAsString()`);
- `SortOrder` (scan order: width i, then height j).

Scans run headless:
1. The plugin re-fetches the saved door.
2. `GateBlockScanTaskHandler` walks the grid or the region.
3. The result is posted with `WorldTasksApi.complete`.
4. The API replaces the door's rows.

**Open-scan limitation:** the `PLANE_GRID` open scan reuses the closed basis (a vertical grid) at `OpenAnchorPoint`, so it
cannot capture a flat deck. §6.7 of the QOL plan found only fragments that way. A deck needs REGION capture with
`//sel convex`.

### 3.2 Load (knk-plugin `GateLoaderAdapter.precomputeBasisVectors`)

- `u = normalize(Ref1 − Anchor)`, `v = normalize(Ref2 − Anchor)`, `n = u × v`.
- `uStep`/`vStep` = the grid steps with the common divisor removed; `nStep = primitive(uStep × vStep)`.
- `sublatticeIndex = a² + b²` for `uStep = (a,0,b)`: 1 for cardinal, 2 for 45°, 5 for 2:1.
- Hinge = `uAxis` through the anchor. The swing follows the right-hand rule. For entity 14 it swings toward north-west,
  the same direction as `nStep`.
- With an open scan, three more steps run at load:
  - **`GateBlockPairing`** matches closed and open blocks with the Hungarian algorithm;
  - **`RigidTransform.fit`** fits one rotation and translation through the matched pairs (Kabsch);
  - start points are made up for the open-only blocks by running their open positions backwards through that fit.

### 3.3 Every tick (`GateAnimationTask.updateGateBlocks` → `GateFrameCalculator`)

For each closed block, and with an open scan also for each open-only block:
- **No open scan:** `position = anchor + rotate(relative, hinge, maxAngle × progress)`. The cell is
  `floor(position)`. Each block is rounded on its own.
- **With an open scan:** `arc + uniform fit correction × progress + residual × progress⁵`. The block snaps to its
  target once it is within 0.5 blocks.

The orientation of logs, stairs and similar blocks snaps to the nearest axis at the current angle. Cells are vacated and
placed by difference against the previous tick (`resolveVacateCells`). `placeBlockIfVacant` refuses a cell that holds a
foreign block, and 5 blocked ticks in a row mean JAMMED.

`TRACE_LOGGING_ENABLED = true` is still on in `main`. It was a temporary diagnostic from item 6.7 and logs every
block, every frame, at INFO.

### 3.4 Resting frames (`GateRestingFramePlacer.restingFrameCells`)

- **Open frame, with an open scan:** the open-scan blocks are placed verbatim.
- **Mechanism 1:** for a diagonal hinge without an open scan, the rotated rectangle is rasterized (filled), **only at
  frame 0 and the last frame** (Decision 3).
- **Otherwise:** each scanned block is placed on its own.

The same cells feed startup sync (`GateStateSyncTask`), the world-sync check and the siege non-member fake-block view
(`GateViewCells`).

---

## 4. Why it looks like a moving blob

Numbers below come from a small simulation that reimplements the current formula and the proposal for entity 14's real
geometry (Appendix A).

### 4.1 A point cloud cannot draw a tilted plane

Entity 14 **without** an open scan, using today's per-block formula:

| frame / 90 | cells occupied by the 32 blocks | blocks lost to collisions |
|---|---|---|
| 0 | 32 | 0 |
| 45 | 28 | 4 |
| 54 (worst) | 24 | 8 |
| 90 | 24 | 8 (Mechanism 1 then refills the end frame) |

Over 90 frames the world shows **29 different shapes**. Between two shapes, anywhere from 4 to 56 cells change. Most
updates are a few blocks shifting somewhere on the door, which is the shimmering, crawling look.

This is not specific to diagonals. A **cardinal** 4×8 door drops to **20 visible blocks** at frame 45, because at 45°
rows j and j+1 project 0.71 apart and round into the same cell. Mechanism 1 fills only the two resting frames
(Decision 3), so nothing fills the swing.

### 4.2 Two kinds of length on a diagonal

A rotation keeps true length. A row 7 blocks up lands 7.0 blocks from the hinge, which is 4.95 diagonal steps on a 45°
gate. Players and builders count **blocks along the diagonal** instead. Earlier work has already run into this:
- the comment in `rasterizeRotationFrame` about an "8-tall door only opens 6 blocks";
- the user's own description in QOL plan §6.7, that the open deck "needs *more* points along that horizontal spread".

Entity 14 shows it in the data:
- The recorded `OpenAnchorPoint` (1368,44,-591) lies **9.19 blocks** from the hinge line. No block of a rigid swing can
  get further than **7.0**.
- A filled diagonal deck of 14 half-diagonal strips (k = 0..13, strips alternating 4 and 3 blocks wide) has
  **exactly 49 blocks**, the stored open-scan count.
- Its outermost strip is 3 wide and centred, which matches the "extra row, ~2–3 blocks wide, centred … at the farthest
  point from the hinge".

**Confirmed from the stored data (2026-10-16).** Source: the dev DB seed `PandiO/knk-dev-db-seed` `d68b458` (dump of
2026-10-07), restored locally. Door 14 is "Outer Gate" in structure 14.
- Its 49 open snapshots are exactly strips k = 0..13 at y = 44, alternating 4 blocks (along-hinge positions 0,1,2,3) and
  3 blocks (0.5,1.5,2.5).
  - Every block lies inside the door's width, and every block is a spruce log.
  - The furthest strip is 9.19 blocks from the hinge line.
- The "extra row, ~2–3 blocks wide" is simply the last odd strip. There are no protrusions.
- The open anchor (1368,44,-591) is not a deck block; it is a reference point half a block past the deck's corner.
- The proposed keyframes reproduce both scans **cell for cell**: keyframe 0 is the 32 closed blocks and keyframe 20 is
  the 49 open blocks (Appendix A).

So the built open deck is **not a rigid image** of the closed door; it is about √2 longer along the swing. A rigid fit
(Decision 7) therefore leaves large residuals at the far end, up to 5.7 blocks as recorded in Decision 8.

### 4.3 The compensation stack is non-rigid by design

To land on a non-rigid target without jamming, items 6.10–6.11.3 added the following:

| Layer | Effect on the swing |
|---|---|
| Uniform fit | The near-hinge blocks move as one rigid piece |
| Residual × p⁵ | Far blocks hold back for the first ~70% of the swing, then rush in |
| 0.5-block snap | Each far block jumps to its target on its own frame |
| Open-only start points | 17 blocks start inside or near the wall and fly out on their own paths |

Each step was correct for its own problem (jams, rounding into a neighbour, orphaned blocks), and the jam is fixed. But a
door whose parts converge at different rates cannot read as one solid plank. Tuning the exponent or the snap radius
further only moves where the lag shows. That is going in circles, and this proposal stops it.

### 4.4 Updating every tick works against a block grid

Every tick, a few of the continuously moving points cross a cell boundary, so the door changes a few blocks at a time in
scattered places. Even a perfect shape would look restless updated like that. Block animations read as solid when the
**whole shape** changes at once in clear steps.

---

## 5. Proposal: the keyframed plank

### 5.1 Idea

A drawbridge with a horizontal hinge is the same **side profile** at every point along the hinge. So:
1. Draw the side profile: a straight line from the hinge to the tip, in grid steps.
2. Extrude it along the hinge for the door's width.
3. Do that once per keyframe, at load, and play the keyframes back as whole shapes.

### 5.2 Coordinates that make a diagonal look like a cardinal

Write every world cell uniquely as `anchor + i·uStep + k·e + y·(0,1,0)` with integers i, k, y:
- `uStep = (a,0,b)` is the hinge step.
- `e` is a **unit world axis**, (±1,0,0) or (0,0,±1), chosen so that (uStep, e) is an exact basis of the horizontal grid
  (`det = ±1`) and `e` points to the side the door opens toward.
- Such an `e` exists whenever |a| = 1 or |b| = 1. That covers cardinal, 45°, 2:1, 3:1 and so on.
  - Other slopes (e.g. 3:2) are refused at load with a warning and keep today's behaviour.
- Each step of k moves the strip **one face** outward, so consecutive strips always touch face to face.
  - Cardinal: `e = nStep`; one k step is one block.
  - 45°: one k step is half a diagonal step (0.71 blocks).
- Along the hinge, strip k is shifted by `f·k` u-steps, where `f = (e·uStep)/|uStep|²` (0 for cardinal, ½ for 45°).
- For a rectangular door, a cell (i, k, y) belongs to the door's width if `0 ≤ i + f·k ≤ W−1`.
  - The plank therefore never sticks out past the gateway opening.
  - On a 45° gate the strips alternate W and W−1 blocks: the normal diagonal sawtooth.
  - §5.11 replaces this box test with the door's real shape. The rectangle is just the special case where every cell of
    the box is a door block.

Entity 14: `uStep = (-1,0,1)`, `e = (-1,0,0)`, `f = ½`.

### 5.3 Closed, open, and in between

- **Profile**: cells (k, y). Closed = the column `(0, 0..H−1)`. Open = the row `(0..K, 0)`.
- **Open reach K**, in strips:
  - from the open scan when there is one: the largest k of its blocks (entity 14: K = 13);
  - otherwise from the configured deck length L (§6): `K = σ·(L−1)`, where σ is the sublattice index.
  - A cardinal door with L = H gives K = H−1, the same as today.
- **Tip path**: `tip(θ) = (K·sin θ, (H−1)·cos θ)` for θ from 0 to `RotationMaxAngleDegrees`.
  - Measured in grid steps this is a quarter circle, so it works the same at any facing.
  - For a cardinal door with L = H it is exactly today's rotation.
- **Each keyframe**: a naive digital line (8-connected: one cell per step along the longer axis) from (0,0) to the
  rounded tip. Then the line is extruded along i by the rule in §5.2.
- **Keyframe list**: one keyframe each time the rounded tip enters a new cell. Between two consecutive keyframes the tip
  moves exactly one cell, and the hinge cell never moves.

Entity 14 side profile (k across, y up, `#` = strip). Every frame is one straight plank:

```
kf 0 (0°)        kf 3 (~11°)      kf 6 (~22°)      kf 9 (~35°)      kf 12 (~47°)     kf 20 (86–90°)
#.............   ...#..........   ..............   ..............   ..............   ..............
#.............   ...#..........   .....#........   ........#.....   ..............   ..............
#.............   ..#...........   ....#.........   .......#......   ..........#...   ..............
#.............   ..#...........   ...#..........   .....##.......   .......###....   ..............
#.............   .#............   ..#...........   ....#.........   ......#.......   ..............
#.............   .#............   ..#...........   ..##..........   ...###........   ..............
#.............   #.............   .#............   .#............   ..#...........   ..............
#.............   #.............   #.............   #.............   ##............   ##############
32 blocks        28               25               32               39               49
```

### 5.4 Keyframes and timing

- Keyframe n is shown on the tick at which the continuous angle reaches the angle where its tip cell starts.
  - v1 uses linear time in angle.
  - An easing curve is a later option (§8 D4).
- Entity 14 has 21 keyframes over 90 ticks, so the shape changes about every **4.5 ticks**.
- Each change is applied **atomically in one tick**:
  1. Compute the difference between the old and new keyframe.
  2. Remove the cells that leave.
  3. Place the cells that enter or change blockdata.
- Between keyframes nothing is placed or computed.
- Precomputed at load: at most ~30 keyframes × ~130 cells for a 7×10 diagonal door, a few kB per door.
- Per-tick cost drops below today's (today: 49 blocks × two position computations every tick, plus trace logging).
- A short chain or ratchet click on each keyframe turns the steps into a deliberate mechanical feel. The sound is
  optional and can be configured.

### 5.5 Materials and orientation

- Profile cell p (0 = hinge, P−1 = tip) takes its material from closed row `j = round(p·(H−1)/(P−1))`.
- The width column comes from the nearest closed column at `i + f·k`.
- This is the same lookup that decides whether the cell exists at all (§5.11). Shape and material come from one
  sample of the scanned door, in every geometry mode.
- Orientation: `GateBlockOrientation.applyRotation` with **one angle per keyframe** for the whole door, as today. All
  logs flip together.
- **Last keyframe:**
  - with an open scan, the scan verbatim (unchanged item 6.9 behaviour);
  - otherwise the rasterized deck.
- **Keyframe 0** is the closed scan verbatim.
- **Cells that never move keep their scanned blockdata in every keyframe.** This applies to the hinge row (k = 0,
  y = 0) in particular.
  - Door 14's open scan keeps its hinge-row logs upright (`axis=y`), like the closed state.
  - Re-orienting them by the swing angle would flip them to `axis=x` mid-swing and back on the last keyframe.
- **The rest of the deck** snaps to one axis per keyframe and takes the open scan's own mixed x/z log axes on the last
  keyframe. That is a one-step texture change, not a shape change.

### 5.6 What the open scan does now

1. It is the authoritative open resting frame. Protrusions, other materials and slabs are placed exactly as scanned.
2. It sets the reach K.
3. Nothing else: no pairing, no fit, no residual.

Scanned blocks outside the plank's deck (protrusions) appear on the last keyframe. That is the same one-frame "pop"
ROTATION_GAP_FILL Decision 1 already accepted, limited to decorations.

### 5.7 What changes in the code (knk-plugin)

| Today | With this proposal |
|---|---|
| `GateFrameCalculator.calculateRotationPosition` / `blendRotationPosition` / `residualTaper` / `SNAP_DISTANCE`, `calculateOpenOnlyBlockPosition*` | Replaced for ROTATION by a new Bukkit-free `knk-core/.../gates/DrawbridgeKeyframes` (basis, profile line, tip path, keyframe list) |
| `GateBlockPairing`, `RigidTransform`, `CachedGateDoor.fittedOpenTransform`/open-only start points | No longer used for ROTATION. Pairing by index stays for VERTICAL/LATERAL. Delete after the live pilot (D6) |
| `rasterizeRotationFrame` (Mechanism 1, end frames only) | The last keyframe *is* the filled deck. Mechanism 1 is retired |
| `GateAnimationTask.updateGateBlocks` per-block loop | ROTATION: frame → keyframe index; apply the difference when the index changes |
| `GateRestingFramePlacer.restingFrameCells` | ROTATION: keyframe 0 / last keyframe (open scan verbatim stays) |
| `GateSweep.cells`, `GateManager` lookup, `HealthSystem`, `CollisionPredictor` | ROTATION: union of the keyframe cell sets between the two frames. Exact, and cheaper than walking every block's path |
| `GateFrameCalculator.isWithinGeometryBounds` (`ClipToGeometryBounds`, REGION footprint polygon) | Not used for ROTATION; the shape mask (§5.11) bounds the plank. Unchanged for VERTICAL/LATERAL |
| `GateBlockScanTaskHandler` PLANE_GRID scan keeps every non-air block in the box | Unchanged (D8). PLANE_GRID stays for rectangular doors; non-rectangular doors use the REGION scan with a material whitelist (§5.11) |
| Kill switch `gates.rotationGapFill.rasterization-enabled` | New switch `gates.rotation.keyframes-enabled` (default true; false = today's path) for the pilot |
| `TRACE_LOGGING_ENABLED = true` | false (or removed) |

### 5.8 Safety, hits and siege

- All of these keep working because the door stays real blocks:
  - the spatial index (hits on the gate);
  - `placeBlockIfVacant` and jam detection;
  - KNG-106 evacuation and push;
  - the siege fake-block view.
- The evacuation radius (6 blocks, chosen for a lowering drawbridge) must cover the reach K. Entity 14 at 9.2 blocks
  needs checking.
- `GateSweep` can be exact: the next keyframe's new cells are exactly the cells about to be filled.

### 5.9 Sizes: blocks closed, open and in between

From [`scripts/gate-animation/drawbridge_keyframes_sim.py`](../../../scripts/gate-animation/drawbridge_keyframes_sim.py), which rounds half-up like Java's `Math.round`. The deck length counts blocks (L = H). "Rigid" is the true-length alternative. "Cells changed" counts removals plus placements, so it can exceed the block count.

| Facing | W × H | Closed | Open (L = H) | Open (rigid) | Keyframes | Cells changed per keyframe |
|---|---|---|---|---|---|---|
| cardinal | 3 × 4 | 12 | 12 | 12 | 7 | 9–12 |
| cardinal | 4 × 6 | 24 | 24 | 24 | 11 | 16–24 |
| cardinal | 4 × 8 | 32 | 32 | 32 | 15 | 16–32 |
| cardinal | 7 × 10 | 70 | 70 | 70 | 19 | 35–84 |
| 45° | 3 × 4 | 12 | 18 | 13 | 10 | 3–20 |
| 45° | 4 × 6 | 24 | 39 | 28 | 16 | 10–42 |
| 45° | 4 × 8 | 32 | 53 | 39 | 22 | 4–56 |
| 45° | 4 × 8, K = 13 (entity 14 as built) | 32 | **49** | — | 21 | 4–54 |
| 45° | 7 × 10 | 70 | 124 | 91 | 28 | 19–130 |
| cardinal | arch, 7 wide × 9 tall (column heights 7,8,9,9,9,8,7) | 57 | 57 | — | 17 | 17–58 |
| 45° | arch, 5 wide × 7 tall (column heights 6,7,7,7,6) | 33 | 55 | — | 19 | 3–56 |

Formulas (rectangular doors; an arch has fewer blocks, because its missing corners stay missing in every keyframe):
- Cardinal open = W·L.
- 45° open = ⌈(K+1)/2⌉·W + ⌊(K+1)/2⌋·(W−1), with K = 2(L−1).
- A diagonal deck holds about twice as many blocks as the closed wall. That is the checkerboard fill, not a bug.
- Mid-swing count: an 8-connected plank has one cell per step along its longer axis, so the count dips at about 45° and
  grows again toward the deck.

### 5.10 Edge cases

- **`RotationMaxAngleDegrees` ≠ 90**: the tip path stops at that angle, and the last keyframe is that shape.
- **Negative angle** (swinging inward): `e` is chosen on the side the door actually opens toward.
- **Slopes without a unit-axis `e`** (e.g. 3:2): refuse at load with a warning and keep the old path. In practice such
  a gate is unlikely.
- **`GeometryDepth > 1`**: extrude the profile into a thicker plank (stack along the normal of the profile line). This is
  already unverified in today's code; keep it unverified.
- **`DOUBLE_DOORS`** (vertical hinge): the same method with the profile in the horizontal plane (a digital line in world
  x/z) and extrusion along y. Out of scope for v1, because DOUBLE_DOORS was never live-tested.
- **Lag skip** (TPS < 15): jump to the last keyframe, as today.
- **Jam on a keyframe**: hold that keyframe and retry, as today.

### 5.11 Non-rectangular doors (arched tops and other shapes)

**The door's shape is the set of blocks the closed scan found.**
- Each closed block has a position (a, v) in the door's own plane: a counts u-steps along the hinge, v counts rows up.
  This set of positions is the door's **shape mask**.
- A rectangle fills its W × H box. An arched door leaves the top corners empty.
- W and H are still the bounding box. Ref 1 and Ref 2 span the whole box, and Ref 2 sits straight above the anchor at
  the apex height (KNG-132), even where that spot is wall rather than door.

**How each keyframe uses the mask.** This replaces the box test in §5.2.
1. **Rows.** The profile line from hinge to tip has P cells. Cell p stands for mask row `r(p) = round(p·(H−1)/(P−1))`.
   - When the plank is compressed (P < H, e.g. a cardinal door around 45°), some rows are skipped for that frame.
   - When it is stretched (P > H, e.g. a diagonal deck), rows repeat.
   - In the closed keyframe P = H, so it is exact.
2. **Width.** For each strip cell, the along-hinge position is `a = i + f·k`.
   - If a is a whole number, the cell exists when the mask has (a, r(p)).
   - If a is a half step (odd strips on a 45° gate), the cell exists only when **both** neighbouring columns ⌊a⌋ and
     ⌈a⌉ have row r(p).
   - This is §5.2's "never wider than the door" rule, now applied to any outline instead of a box.
3. **Material.** It comes from the same mask cell (§5.5).

**Results** from the simulation (Appendix A) for a cardinal arch, 7 wide × 9 tall, and a 45° arch, 5 wide × 7 tall:
- Keyframe 0 equals the scanned door exactly.
- The apex row appears in every keyframe.
- The outline narrows toward the plank's tip, as it should.
- With no open scan, the open deck is the arch laid flat. On a 45° gate that is a diagonal arched deck with the normal
  sawtooth edge.

```
cardinal arch, closed (front)     45° arch, open deck seen from above (hinge = lower-right edge, apex = upper left)
..###..                           ..#.#.....
.#####.                           .#####....
#######                           #######...
#######                           .#######..
#######                           #########.
#######                           .#########
#######                           ..#######.
#######                           ...#####..
#######                           ....###...
57 blocks, 17 keyframes           .....#....    33 blocks closed, 55 open, 19 keyframes
```

**Other consequences of using the mask:**
- **Holes** (a window, a murder hole, portcullis-style gaps) are kept exactly at both resting frames.
  - Mid-swing, while the plank is compressed, a hole only one row tall can be skipped on some keyframes and seem to
    blink.
  - If that shows in testing, switch the row rule from "nearest row" to "any row in the cell's range". That keeps thin
    features and closes thin holes (D7).
- **Separate pieces** (e.g. a door with a separate decorative crest) are fine; the mask does not have to be connected.
- **Hinge:** unchanged. It is the line through the anchor along the bottom row, even when that row is not full.
- **Off-plane blocks** (depth > 1, studs, a frame sticking out) stay out of scope, as in §5.10.
- **`ClipToGeometryBounds`** is no longer needed for ROTATION, because the mask bounds the plank. It keeps its meaning
  for VERTICAL/LATERAL.

**Capturing an arched door: there is a gap today.**
- The `PLANE_GRID` scan keeps every non-air block in the W × H box. Only air is dropped at load.
- For a door in an arched opening, the box's top corners are wall. They would be captured as door and swing with it.
- `ScanMaterialWhitelist`/`ScanMaterialBlacklist` are only applied by the FLOOD_FILL and REGION scans
  (`GateBlockScanTaskHandler`), not by PLANE_GRID.

**Decided (D8, 2026-10-16): non-rectangular doors use REGION mode.** The PLANE_GRID scan is not changed and stays for
rectangular doors.
- Admin flow for an arched door:
  1. Set `GeometryDefinitionMode = REGION`.
  2. Make a `//sel convex` selection around the door and run `/gatedoor capture <door> closed`.
  3. Set `ScanMaterialWhitelist` to the door's materials (e.g. `spruce_planks`, `spruce_log`, `iron_bars`).
- A convex outline alone can catch a wall block in a stair-step of the arch. The whitelist is what makes it exact.
- The static `GateDoorConfig` in knk-web-app (`src/config/objectConfigs.tsx`) has no field for `ScanMaterialWhitelist`.
  The GateDoor form must expose it for REGION doors. Coordinate with the KNG-139 FormConfiguration work.
- A non-rectangular door scanned in PLANE_GRID mode still captures the wall blocks inside its box. The GateDoor
  `GeometryDefinitionMode` description should say "PLANE_GRID = rectangular doors only".

The open scan (optional) is unchanged. It is placed verbatim at the open frame, and only K is taken from it.

---

## 6. Admin and data changes

- **Deck length for ROTATION.** Reuse `MotionDistanceBlocks`; it is unused for ROTATION today. Meaning: "how many blocks
  the open deck reaches from the hinge, counted along the door's direction".
  - Precedence (as in §5.3): an open scan always sets the length, because its far edge is the last keyframe. The
    field is only used without an open scan, and 0 means `GeometryHeight`. A non-zero value that disagrees with an
    open scan logs a warning at load.
  - The web form gives the field a description for ROTATION (KNG-132 already adds geometry descriptions).
  - No migration needed. Alternative: a new field (D2).
- **Admin flow for a drawbridge:**
  1. Anchor = the bottom hinge block at one end. Ref 1 = the bottom hinge block at the other end; a diagonal is fine.
     Ref 2 = straight above the anchor (KNG-132).
  2. Run the closed scan.
     - For a non-rectangular door (e.g. an arched top), Ref 2 still marks the top of the bounding box straight above the
       anchor.
     - Use REGION mode: a `//sel convex` capture plus `ScanMaterialWhitelist` with the door's materials, so the wall
       around the arch is not captured (§5.11, D8).
  3. Optionally build the open deck and capture it with `//sel convex` + `/gatedoor capture <door> opened`. This is only
     needed for other materials or protrusions. Its far edge sets the length.
- **Optional form preview:** "closed 32 blocks → open 49 blocks, 21 steps, reaches 9.2 blocks". This lets the admin see
  the landing area before testing.
- **Out of scope here, but worth noting:**
  - `HingeAxisId` and `MirrorRotation` are stored and never used. Remove them or wire them up in a cleanup pass.
  - The `PLANE_GRID` open scan cannot capture a deck for ROTATION (§3.1). Either scan the deck plane (i along uStep, k
    along e) or refuse it.

---

## 7. Phase 2, display-entity swing: dropped (D5, 2026-10-16)

The developer dropped this option; the block keyframes are the final look. The analysis stays here so the idea is not
rediscovered and re-proposed without these trade-offs.

The idea was to render the swing with `BlockDisplay` entities instead of blocks if the 4–5 Hz steps were not smooth
enough.
- The plugin already uses display entities: `ItemDisplay` with interpolation in `LootboxPresenter`, and `TextDisplay` in
  `GateDisplayManager`.
- Every 2–3 ticks it sends one transform per display, and the client interpolates at its own frame rate. The result is a
  truly smooth, rigid swing.

How it would work:
1. At swing start, spawn one non-persistent display per closed block (tagged for cleanup, as in
   `GateDisplayOrphanCleanupTask`) and clear the real blocks.
2. Drive all displays with the same transform:
   - cardinal: the rotation about the hinge;
   - diagonal: the same rotation done in grid-step space (`B·R(θ)·B⁻¹`) so the deck lands at the block-count length.
3. At the end, place the resting blocks first, then remove the displays on the next tick so there is no gap.

Costs and open points:
- **Diagonal end shape:** the cubes stretch up to √2 along the swing near the end, and the final swap from tilted cubes to
  the grid deck is a visible change. A visual check decides whether that is acceptable.
- **Mid-swing gameplay:** displays have no collision and no hit box. The door cannot be hit mid-swing (about 4 s), and
  safety relies on the KNG-106 evacuation alone. Phase-1 keyframes can stay the logical "where the door is" for
  `GateSweep`.
- **Siege:** non-members must not see the displays during a lockdown. `SiegeGateViewService` would need
  `Player#hideEntity`.

The block keyframes would have been needed either way: they supply the resting frames, the safety sweep and the fallback.

---

## 8. Decisions (answered by the developer, 2026-10-16)

| # | Question | Recommendation | **Decision** |
|---|---|---|---|
| D1 | Default deck length for a diagonal door without an open scan: counted in blocks (8 tall → 8 diagonal blocks), or true length (8 tall → ~5–6 diagonal blocks, today's Mechanism 1)? | Blocks. It is what builders expect, and it matches how entity 14 was built | **Count in blocks.** The deck gets longer than today, so the live check includes each existing diagonal ROTATION door's landing area (§9) |
| D2 | Where the length lives: reuse `MotionDistanceBlocks` for ROTATION, or a new field? | Reuse. No migration | **Reuse `MotionDistanceBlocks`**. An open scan, when present, always sets the length; otherwise the field does, with 0 = `GeometryHeight` |
| D3 | Plank style mid-swing: thin (8-connected, edge contacts) or solid (4-connected staircase, about 1.4× the blocks at 45°)? | Thin | **Thin** |
| D4 | Timing: linear in angle, or eased (slow start, faster fall, "thud")? | Linear for v1 | **Linear in angle** |
| D5 | Phase 2 display-entity swing? | Decide after the phase-1 live check | **Dropped.** Blocks only; §7 is kept for the record |
| D6 | Delete the retired ROTATION machinery (blend, fit, residual, snap, Mechanism 1) right away, or keep it behind the switch for one round? | Keep behind the switch, then delete | **Keep behind the switch** until the live check passes, then delete |
| D7 | Mask row rule while the plank is compressed (§5.11): nearest row, or any row in the cell's range? | Nearest row | **Nearest row** |
| D8 | Let the PLANE_GRID scan honour `ScanMaterialWhitelist`/`Blacklist`, so an arched door is captured as its bounding box plus its materials? | Yes | **No.** Non-rectangular doors use REGION (`//sel convex` + whitelist); PLANE_GRID stays rectangle-only (§5.11) |

---

## 9. Implementation plan

0. **Data check: done (2026-10-16).** Door 14's open snapshots are a plain diagonal strip deck: K = 13, strips of 4/3,
   no protrusions. Both end keyframes match the scans exactly (§4.2).
   - In the 2026-10-07 dev seed, door 14 is the only ROTATION door and it has an open scan. So D1 (deck counted in
     blocks) changes the length of no existing door there.
   - Recheck against the live dev database before the live test, because it may have changed since the dump.
   - The seed stores door 14 as `GeometryDefinitionMode = PLANE_GRID`, with `ClosedRegionData` and `OpenedRegionData`
     still filled in. The swing does not read the mode (Decision 7), so this does not matter for the animation.
1. **knk-core `DrawbridgeKeyframes`** — **done 2026-10-19** (`DrawbridgeKeyframesTest`; the Java keyframes equal the
   reference script's, cell for cell, for every fixture of §5.9). Pure functions, with unit tests:
   - keyframe 0 equals the closed scan cells;
   - the last keyframe follows the §5.9 count formula;
   - the tip moves exactly one cell per keyframe;
   - no cell lies outside `0 ≤ i + f·k ≤ W−1`;
   - a cardinal door with L = H gives the same end frames as today;
   - an entity 14 fixture with K = 13 gives 49 blocks and 21 keyframes;
   - a 3:2 slope is refused;
   - arched masks (cardinal 7×9, 45° 5×7):
     - keyframe 0 equals the mask;
     - the apex row appears in every keyframe;
     - no keyframe cell lies outside the mask's outline at its row (both-neighbours rule on half steps);
     - a mask with a one-row hole keeps the hole at both resting frames.
2. **Load** — **done 2026-10-19.** `GateLoaderAdapter` builds and caches the keyframes on `CachedGateDoor`, with K taken from the open scan or
   from the length, after KNG-132's basis check (a refused door keeps the per-block path, one warning).
3. **Play** — **done 2026-10-19** (without the optional sound). `GateAnimationTask` applies the keyframe difference atomically, plus the optional per-keyframe sound;
   `GateRestingFramePlacer`, `GateSweep`, `GateManager` and `HealthSystem` read the keyframes for ROTATION; add the
   config switch; turn trace logging off.
4. **Web app/API (small)** — **done 2026-10-19** as GateDoor seed v2 (knk-web-api `Data/FormConfigurationSeeds/GateDoor.json`,
   new GUID and name; the developer imports it). The preview line was not done. knk-web-app untouched: the wizard uses
   the seeded form, so the static `GateDoorConfig` needs no whitelist field.
   - the `MotionDistanceBlocks` description for ROTATION (D2);
   - `ScanMaterialWhitelist` in the GateDoor form for REGION doors (missing from the static `GateDoorConfig`);
   - the `GeometryDefinitionMode` description "PLANE_GRID = rectangular doors only" (D8);
   - optionally, the preview line.

   This overlaps the KNG-132 / KNG-139 form work, so coordinate with those rows in ACTIVE_SESSIONS.
5. **Live check (developer)** — **passed 2026-10-19 on gate door 14 only**; the other items were accepted without a run
   (checklist: [guides/gate-smoke-test.md §3](../../guides/gate-smoke-test.md)):
   - Entity 14, 4 open/close cycles:
     - every step is a straight 4-wide plank;
     - the deck lands exactly on the 49 scanned blocks;
     - no jam;
     - no orphaned blocks;
     - a player in the landing area gets moved.
   - Build one **cardinal** 4×6 drawbridge (never tested before) and run the same check.
   - Build one **arched** drawbridge (e.g. 7 wide × 9 tall, in an arched opening) and run the same check.
     - Capture it with REGION, `//sel convex` and a material whitelist (D8).
     - Confirm the wall corners above the arch stay put.
   - Check the landing area of every existing diagonal ROTATION door without an open scan. Its deck is now counted in
     blocks (D1), so it reaches further than before.
   - Toggle the switch off and on to compare with the old path (D6). Delete the old path once this check passes.
6. **Docs** — **done 2026-10-19:**
   - Mark ROTATION_GAP_FILL Mechanisms 1–2 (ROTATION mid-swing) as superseded by this document.
   - Update SPEC.md's gap-fill section.
   - Add a short "Drawbridges" section to `guides/gate-smoke-test.md`.

---

## 10. How this relates to earlier decisions

| Earlier decision | Here |
|---|---|
| Decision 3: Mechanism 1 fills the endpoints only; "revisit … after measuring tick cost" | **Revisited.** Every keyframe is a filled shape. The cost is precomputed and lower than today's per-tick work (§5.4) |
| Decisions 7/8/8.1/8.2: rigid fit, residual, settle threshold, 0.5 snap | **Replaced for ROTATION.** Their goals (rigid look, exact landing, no jam) hold by construction: one shape per keyframe, the last keyframe is the scan, and all cells are integers, so there is no rounding hazard left to snap away |
| Decision 7 option 3 ("pure procedural rotation", rejected because it ignores the open scan) | **Not this.** The open scan sets the length and the final frame |
| Decision 1 (unpaired blocks pop in at the end) | Kept, now only for protrusions outside the deck |
| Decision 5 (kill switch) | Kept in spirit: a new switch for the new path |
| Decision 6 (separate open-snapshot table) | Unchanged |
| "Don't taper the residual linearly" (Decision 8 pitfall) | No longer relevant: there is no residual |

---

## Appendix A: simulation

The numbers in §4 and §5.9 come from [`scripts/gate-animation/drawbridge_keyframes_sim.py`](../../../scripts/gate-animation/drawbridge_keyframes_sim.py), a dependency-free Python 3 reference for the Java port. It rounds half-up like `Math.round`. It:
- reimplements `GateFrameCalculator.calculateRotationPosition` (Rodrigues rotation about the anchor, `floor` to a
  cell) for a door without an open scan;
- implements §5.2–5.4 (strip basis, naive digital line, tip path sampled finely, one keyframe per tip-cell change).

Inputs: entity 14's values from the QOL plan §6.7.
- anchor (1378,44,-588), uStep (-1,0,1), vStep (0,1,0);
- W = 4, H = 8;
- 90 frames, 90°.

It does not model the open-scan blend. Instead, the stored snapshots were checked directly (2026-10-16):
1. Restore `knk_uiux_seed.sql.gz` from `PandiO/knk-dev-db-seed` into a local MySQL 8.0.
2. Export `gate_block_snapshots` and `gate_opened_block_snapshots` for `GateDoorId = 14`.
3. Express each block's world position in the §5.2 basis: `i = dz`, `k = −dx − dz` from the anchor; along-hinge
   position `i + k/2`.
4. Compare the sets with keyframes 0 and 20 for K = 13.

The open scan's `openAnchor + Relative*` equals its `World*` columns for all 49 rows.

Rev. 2 added mask sampling (§5.11) on two arched doors:
- cardinal, 7 wide, column heights 7,8,9,9,9,8,7;
- 45°, 5 wide, column heights 6,7,7,7,6.

It checked that keyframe 0 equals the mask and that the apex row appears in every keyframe, under both row rules of D7.
The "any row" rule gives slightly fuller compressed frames (45 against 43 blocks at the minimum for the cardinal arch);
otherwise the two rules give the same counts.
