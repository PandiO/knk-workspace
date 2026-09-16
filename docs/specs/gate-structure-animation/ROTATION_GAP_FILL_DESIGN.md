# Rotation Gap-Fill: Design & Implementation Plan

**Status:** Phases A-D implemented (2026-09-10) — backend schema/API, plugin
Mechanisms 1 & 2, frontend/validation support all done and tested; Phase E
(this doc's own cross-links, in progress) and Phase F (live-server pilot)
remain. **Update (2026-09-16):** Phase F's live pilot against entity 14
surfaced a real defect in Mechanism 2's per-block blend (non-rigid "fluid"
swing motion once tested against a dense, real captured open scan) — see
**Decision 7** below for the confirmed root cause, the options weighed, and
the fix direction chosen (implemented as
[GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md)
item 6.10).
**Author:** Claude (plan requested by Pandi), 2026-09-09
**Related:** [SPEC.md](SPEC.md), [REQUIREMENTS.md](REQUIREMENTS.md), [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md), [DECISIONS.md](DECISIONS.md), [DUAL_SCAN_ANIMATION_DESIGN.md](DUAL_SCAN_ANIMATION_DESIGN.md) (Open Question 3 — this plan resolves it: dual-scan extends to `ROTATION` gates; that doc is now superseded by this one for `VERTICAL`/`LATERAL` too, per Decision 6), [GATE_WORLD_SYNC_DESIGN.md](GATE_WORLD_SYNC_DESIGN.md) (a related but separate gap found while implementing this plan's Phase C)

> **Amends `DUAL_SCAN_ANIMATION_DESIGN.md`** in two ways:
> 1. That doc proposes an explicit `AnimationDefinitionMode.PROCEDURAL`/
>    `DUAL_SCAN` field an admin selects. This plan drops that field in favor
>    of an implicit trigger (see Mechanism 2 below) so the same rule — "a
>    scanned open state, if present, always wins, regardless of `GateType`/
>    `MotionType`" — applies uniformly to every motion type instead of
>    needing a separate opt-in per gate.
> 2. That doc proposes storing the open state as rows in the *same*
>    `GateBlockSnapshot` table, discriminated by a new `State` column. This
>    plan uses a **separate entity/table instead** — `GateOpenedBlockSnapshot`,
>    mirroring `GateBlockSnapshot`'s shape exactly — because the admin-facing
>    `FormWizard`/`FormConfig` system (`knk-web-app`) ties a `WorldTask`-backed
>    scan to *one property*, one-shot: there's no existing mechanism to
>    re-trigger a scan against the same property for a different purpose. A
>    shared table would need new special-casing in the wizard to know "this
>    is actually the second scan for this gate, tag it differently"; a
>    genuinely separate property is just a second, ordinary
>    `FormConfigurableEntity`, fitting the wizard's existing convention with
>    no new UI concept. It also removes, by construction, the risk (flagged
>    in earlier drafts of this plan) of one scan's completion logic
>    accidentally clobbering the other state's rows — there's no shared table
>    to mis-scope in the first place. See Decision 6.
>
> "Dual-scan" below refers to the same *concept* `DUAL_SCAN_ANIMATION_DESIGN.md`
> introduced (two physically-scanned states instead of one scan plus
> procedural math); the storage shape and activation mechanism both change.

---

## Context

GateStructure #14 (a diagonal-facing `DRAWBRIDGE`, `MotionType=ROTATION`) opens
correctly in size and position, but its open-state grid is a checkerboard: half
the cells that should hold a door block are air. This is not a rounding bug —
it is the exact, provable shape of the lattice `GateFrameCalculator.
calculateRotationPosition` produces whenever a gate's hinge line is diagonal.

### Why this happens

A `PLANE_GRID` gate's blocks are stored as `relativePosition = i*uStep +
j*vStep + k*nStep` (`GateBlockScanTaskHandler.computeCellPosition`), where
`uStep`/`vStep`/`nStep` are the primitive (GCD-reduced) integer lattice steps
along the gate's width/height/depth axes (`VectorMath.primitiveLatticeStep`).

When closed (`angle=0`), a block's world position only ever combines `uStep`
and `vStep`. `vStep` is always a clean vertical unit step `(0,1,0)` (required
for the basis to stay orthogonal — see the `GateLoaderAdapter` hinge-axis fix
from this session), so each width-column stacks solidly regardless of whether
`uStep` itself is diagonal.

When rotated around the hinge (`uAxis` for `DRAWBRIDGE`, `vAxis` for
`DOUBLE_DOORS` — `GateAnimationTask.resolveHingeAxis`), the *other* axis
sweeps into `nStep`. If the gate's face is diagonal, `nStep` is **also**
diagonal — the direction perpendicular to a 45° line in a horizontal plane is
another 45° line. Two diagonal vectors as your two grid axes only reach a
sublattice of the true grid.

This generalizes past the 45° case. For any primitive `uStep = (a, ·, b)` in
the horizontal plane (`nStep` its horizontal perpendicular, so `|nStep| =
|uStep|` always):

```
sublattice index = a² + b²
```

- Cardinal (`a=1,b=0` or `a=0,b=1`): index = 1 → full coverage, no gaps.
- 45° diagonal (`a=±1,b=±1`, gate #14's case): index = 2 → checkerboard,
  exactly half the cells covered.
- Any other coprime diagonal (e.g. `a=2,b=1`, a "2-over-1" Minecraft-style
  offset wall): index = 5 → only 1 in 5 cells covered — far sparser than a
  checkerboard.

So "checkerboard" is the *mild* end of this problem, and it only exists for
diagonal-hinge `ROTATION` gates. A cardinal-hinge `ROTATION` gate has index 1
and needs neither mechanism in this plan — it already renders a full grid
today.

### Why this is genuinely hard to patch with the rotation formula alone

The rotation formula is a pure function: `worldPos = anchor + rotate
(relativePos, hingeAxis, angle)`. There is no integer `(i, j)` combination of
`uStep`/`nStep` that reaches the missing-parity cells — every combination
preserves the same residue class mod the sublattice index. Filling the gaps
requires blocks that do not correspond to any scanned snapshot at all.

---

## Goals

- Fill the diagonal-hinge open-state footprint completely, **automatically,
  with zero required admin action**, for any existing or future diagonal
  `ROTATION` gate.
- Let an admin who wants full creative control over the open shape (different
  material, an intentionally non-solid look, or eventually a non-rectangular
  `FLOOD_FILL` shape) override the automatic fill by physically building and
  scanning the true open state — available for **every** motion type
  (`VERTICAL`, `LATERAL`, `ROTATION`) and **every** gate type, triggered the
  same way in every case: a scanned open state exists, or it doesn't.
- No separate mode field to select or forget to select — the override is
  purely a function of whether open-state snapshots exist for that gate.
- When both a manual override and an automatic derivation exist for the same
  endpoint, the manual scan always wins outright — the automatic mechanism
  never runs for a gate that has one.
- For `ROTATION` gates specifically, make the transition into a manually
  scanned open state a smooth, continuous motion rather than an abrupt swap —
  see Mechanism 2 below.
- Do not regress cardinal-hinge `ROTATION` gates, `VERTICAL`/`LATERAL` gates,
  or the closed state of any gate.

## Non-goals (v1)

- Filling gaps **during** the swing (intermediate frames) for the automatic
  rasterization mechanism. Mechanism 1 guarantees the resting closed/open
  endpoints only; mid-swing frames may still show transient sparseness —
  decided (Decision 3), not just deferred, though revisitable once real tick
  cost is measured. (Mechanism 2's blended interpolation, by contrast, *is*
  continuous across every frame — see below.)
- `FLOOD_FILL` geometry mode and `DOUBLE_DOORS` — revisit once the
  `DRAWBRIDGE`/`PLANE_GRID` case is proven, same staging `DUAL_SCAN` used.
- Automatically detecting and "fixing" a poorly-oriented diagonal gate's
  reference points. This plan fills whatever footprint the gate is configured
  with; it doesn't second-guess the configuration itself.

---

## Design: two complementary mechanisms, not two alternatives

```
does this gate have any OPEN-state snapshot rows?
  yes -> use them (Mechanism 2) - always wins, no rasterization involved
  no  -> is this a ROTATION gate with sublattice index > 1?
           yes -> rasterize automatically (Mechanism 1)
           no  -> today's exact existing behavior, unchanged
```

### Mechanism 1 (automatic default) — Corner-rasterized fill

At the resting closed and open frames, instead of placing only the `W×H`
individually-rotated scanned points, compute the shape's actual footprint and
fill every real cell inside it:

1. Rotate the door's 4 corners (`(0,0)`, `(W-1,0)`, `(0,H-1)`, `(W-1,H-1)` in
   local `u`/`v` space) the same way any point is rotated, using the same
   `hingeAxis`/angle as the frame being rendered.
2. Take the axis-aligned bounding box of those 4 rotated corners.
3. For every integer world cell in that bounding box, test whether it falls
   inside the rotated rectangle. This reuses `GateFrameCalculator.
   isWithinGeometryBounds`'s existing projection logic almost verbatim — it
   already projects a world position onto `uStep`/`vStep`/`nStep` and checks
   the projected index against `[0, extent-1]`; today it's only ever called
   on the sparse set of individually-rotated scanned points, but nothing
   about the check itself is specific to that sparse set.
4. For each cell that passes, source its material/blockdata by rounding its
   projected `(u, n)` index to the nearest real scanned `(i, j)` block.

For gate #14 concretely: rotated corners span an 11×11 bounding box (121
candidate cells), of which the projection test keeps ~64 — double the 32
originally scanned, matching the `index = 2` formula above exactly (true
fill density = `index` × the naive rotated-lattice count).

This mechanism requires **no schema change** — it's pure plugin-side
geometry, computed from data the gate already has (`uStep`/`vStep`/`nStep`,
`hingeAxis`, `RotationMaxAngleDegrees`). It runs unconditionally whenever the
computed sublattice index is `> 1` and no `OPEN`-state snapshots exist for
that gate.

**Self-consistency property worth calling out**: because Mechanism 1's fill
is *derived from* the same corners the arc rotates, it can never disagree
with where the swing naturally arrives — there is no size-mismatch/pop
concern for this mechanism at all (unlike a naive version of Mechanism 2 —
see below for how that's avoided too).

### Mechanism 2 (manual override, every motion/gate type) — Scanned open state

**Trigger**: implicit. If a gate has any rows in its `OpenedBlockSnapshots`
collection (backed by the separate `GateOpenedBlockSnapshot` entity — see
Decision 6), those rows are used as the true open-state shape — no separate
`AnimationDefinitionMode` field, no admin toggle to remember. This is safe
because there's no realistic "partially scanned" state to accidentally
trigger on: a scan's completion path clears-then-adds that property's rows
as one operation per completed scan, and — because `OpenedBlockSnapshots` is
its own table rather than a `State`-discriminated slice of a shared one —
there is no way for that operation to touch anything else. Either a finished
open scan exists for a gate, or it doesn't; there is no incomplete
in-between row set to worry about, and no cross-state contamination possible
even in principle.

**Animating a `VERTICAL`/`LATERAL` gate with an `OPEN` scan** (unchanged from
`DUAL_SCAN_ANIMATION_DESIGN.md`'s own design): pair each closed-state block
with its open-state counterpart by `SortOrder` (both scans walk the same
deterministic `(i,j,k)` loop from their respective anchors), and `lerp` its
position over the animation duration. This works because the real motion
(sliding up or sideways) already *is* a straight line.

**Animating a `ROTATION` gate with an `OPEN` scan**: a straight-line `lerp`
between the two scanned states is wrong here — picture a log standing
vertical against the wall when closed and lying flat as part of the bridge
when open; the straight-line path between those two points cuts through the
wall and into the ground, not up and out along a hinge's natural arc. So
`ROTATION` keeps using the existing Rodrigues rotation formula as the base
motion (unchanged, still swings the way it does today) — but the destination
it's steered toward is corrected to match the real scanned block, throughout
the swing, not swapped in abruptly at the last frame:

1. **Pair** each closed-state block to its nearest open-state block by 3D
   world-space distance (not `SortOrder` — the two states are independently
   built structures with no shared iteration order to correlate by).
2. At every frame, compute two positions the same way the plugin already can:
   - `arcPos(frame)` — today's rotation formula, unchanged.
   - `arcPos(totalFrames)` — what the arc math would produce at the final
     frame if there were no `OPEN` scan at all (i.e. today's checkerboard-
     sparse derived "open" position).
3. Blend a correction term in as the animation progresses:

```
finalPos(frame) = arcPos(frame) + (openScanPos - arcPos(totalFrames)) * progress(frame)
```

At `frame = 0`, `progress = 0`, so this is exactly today's closed position —
no change. At `frame = totalFrames`, `progress = 1`, so this becomes
`arcPos(totalFrames) + (openScanPos - arcPos(totalFrames)) = openScanPos`
exactly — the block lands precisely on its real scanned position, every
time, with **no pop**. In between, the block follows the natural swinging
arc while continuously drifting toward where it actually ends up. `openScanPos`
is used as-is for blockdata/orientation too — an admin who built the open
bridge with logs lying flat already scanned the correct orientation directly,
so `GateBlockOrientation`'s angle-based rotation (added this session) applies
only to the arc term, never to a block that has a real open-scan pairing.

> **Superseded 2026-09-16 (Decision 7, below).** Live-tested against a real,
> dense captured open scan (entity 14, `//sel convex`), this per-block blend
> is exactly what produces a visibly non-rigid ("fluid") swing — every block
> is blended independently toward its own nearest-neighbor open match, so
> neighboring blocks' correction vectors routinely disagree. Replaced by a
> uniform rigid-transform base motion; see Decision 7 for the confirmed
> evidence and reasoning, and
> [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md)
> item 6.10 for the implementation.

**Unpaired blocks**: an open-scan block with no reasonably-close arc-derived
neighbor (e.g. the open shape is meaningfully bigger than the closed one) has
no `arcPos` to blend from. This is the same shape of problem
`DUAL_SCAN_ANIMATION_DESIGN.md`'s own Open Question 1 already worked through
for its "closed block with no open counterpart" case, mirrored in reverse —
see Decision 1 below.

---

## Design decisions (resolved 2026-09-09)

**1. Unpaired-block fallback rule — Decided: (a) pop in at the final frame.**
An open-scan block with no close arc-derived neighbor (or, symmetrically, a
closed block whose nearest open-scan match is implausibly far away) simply
appears at the final frame, matching today's behavior for a block with
nothing to interpolate toward. Matches `DUAL_SCAN`'s own recommendation for
the symmetric case ("smallest change, no new failure modes"). Revisit a
staged fade-in or synthesized-source approach only if real usage on gate #14
and other diagonal gates shows it's actually needed.

**2. Pairing algorithm — Decided: ship greedy nearest-neighbor for v1.**
Each closed block claims its closest unclaimed open block by 3D distance, no
smarter (e.g. optimal-assignment) algorithm for now. Known risk: this can
produce visually crossing paths if the open scan rearranges blocks
non-locally relative to the closed shape. Validate with a deliberately-
scrambled test open scan (Phase F) before deciding whether that risk is real
enough in practice to warrant a smarter algorithm later.

**3. Mechanism 1 mid-swing extension — Decided: no, endpoints only for v1.**
Matches every tick's placement/removal cost of the *current* sparse-lattice
sweep. Mechanism 2 doesn't have this limitation at all — its blend is
already continuous every frame by construction. Revisit full-sweep
rasterization only after measuring actual server tick impact on a real gate.

**4. `ClipToGeometryBounds` scope — Decided, with an implementation note.**
`ClipToGeometryBounds` (`isWithinGeometryBounds`) is a purely geometric
check — does a computed position sit inside the configured box — and is
unrelated to what's physically in the world at that position. It is **not**
the mechanism that stops the animation from overwriting a real, unrelated
block; that's `GateBlockPlacer.placeBlockIfVacant`'s obstruction check, a
separate mechanism that is already unconditional and always-on today for
every placement (mid-swing, rasterized, or open-scan alike) — nothing in
this plan changes that, and it needs no decision.

For the geometric check specifically:
  - **`OPEN`-scan / fully-converged positions (Mechanism 2, `progress=1`):
    never clipped.** Whatever was scanned is exactly what gets placed.
  - **Mid-swing arc-derived positions (Mechanism 2's `arcPos` term, and
    today's `PROCEDURAL` `ROTATION` gates): unchanged from today.** If an
    admin has `ClipToGeometryBounds` enabled, it continues to apply to the
    arc exactly as it does now.
  - **Mechanism 1's rasterization is always self-bounded** by the box it
    derives fresh each frame from the rotated corners — the admin-configured
    `ClipToGeometryBounds` toggle doesn't gate it either way; there's no
    meaningful "unbounded rasterization" for that toggle to turn off.
  - **Implementation note**: the blend formula (`arcPos(frame) + correction
    × progress`) needs the *raw, unclipped* `arcPos(frame)` as an input — if
    the existing `calculateBlockPosition` short-circuits to `null` on a
    clipped arc position before the correction term is added, the blend
    breaks (nothing to add a correction to). Clipping must be evaluated
    against the *final blended position* — the value actually being placed
    — not against the intermediate arc term.

**5. Kill switch for Mechanism 1 — Decided: yes.**
Not a response to a known defect — rasterization isn't implemented yet, so
there's nothing currently buggy. It's a precaution specific to Mechanism 1
being unconditional: once it ships, it runs automatically for every diagonal
`ROTATION` gate with zero admin action, so a defect found later would affect
every such gate on the server simultaneously rather than just one someone is
actively working on. A plugin-config toggle (default on) allows disabling it
server-wide in seconds without a code deploy while any future issue is
diagnosed. Mechanism 2 needs no equivalent switch — its trigger requires a
deliberate, effortful admin action (building and scanning a structure),
which is already a much stronger safeguard against accidental activation
than a pure computed condition.

**6. Storage shape for the open state — Decided: separate entity/table, not
a shared `State` column (resolved 2026-09-09, superseding this doc's own
earlier draft and `DUAL_SCAN_ANIMATION_DESIGN.md`'s original schema
proposal).**
`GateOpenedBlockSnapshot` is its own entity, own table
(`gate_opened_block_snapshots`), own EF Core `DbSet`, mirroring
`GateBlockSnapshot`'s columns exactly (`RelativeX/Y/Z`, `WorldX/Y/Z`,
`MaterialName`, `BlockDataJson`, `TileEntityJson`, `SortOrder`,
`GateStructureId` FK) — no `SnapshotState` enum, no `State` column on the
existing `GateBlockSnapshot` table. `GateStructure` gains a new
`OpenedBlockSnapshots` navigation collection alongside the existing
`BlockSnapshots`, and keeps `OpenAnchorPointId`/`OpenAnchorPoint` unchanged.

Reason: the admin-facing `FormWizard`/`FormConfig` system ties one
`WorldTask`-backed scan to one property, one-shot, with no existing way to
re-scan the same property for a different purpose. A shared table with a
`State` discriminator doesn't fit that — it would need the wizard to know
this is "the second scan for this gate, tag it OPEN," which is new,
special-cased behavior. A genuinely separate property is just a second,
ordinary `FormConfigurableEntity` (`GateOpenedBlockSnapshot`, mirroring the
existing `[FormConfigurableEntity("GateBlockSnapshot")]` on
`GateBlockSnapshot`), giving it its own wizard step and its own scan trigger
with zero new UI concepts.

This also strictly improves the safety property Mechanism 2's implicit
trigger (above) already relied on: with a shared table, the scan-completion
logic would need to *correctly scope* its clear/add operation by `State` to
avoid one scan wiping out the other —
real, unbuilt risk, already flagged in an earlier draft of this plan. With
two separate tables, that failure mode doesn't exist to build correctly or
incorrectly; each scan's clear/add is naturally scoped to its own table.

Accepted trade-off: more schema surface (a second table that duplicates
`GateBlockSnapshot`'s column shape) and, if a future intermediate-keyframe
mode is ever pursued (`DUAL_SCAN_ANIMATION_DESIGN.md`'s own speculative
note), each additional keyframe state would need its own new property/table
rather than a single enum value addition. Judged not worth designing around
now — it's hypothetical future work, not a concrete present need, and
shouldn't drive today's design over a real, current constraint.

This decision also applies to `DUAL_SCAN_ANIMATION_DESIGN.md`'s own
`VERTICAL`/`LATERAL` use case, not just the `ROTATION` extension this plan
adds — the same `FormWizard` constraint applies equally there.
`GateOpenedBlockSnapshot`/`OpenedBlockSnapshots` is now the one open-state
mechanism for every motion type; `DUAL_SCAN_ANIMATION_DESIGN.md`'s schema
section should be read as superseded by this decision, not just by
Decision-1-through-5's `AnimationDefinitionMode` removal.

**7. Mid-swing rigidity for `ROTATION` gates with a dense/mismatched open
scan — Decided (2026-09-16): fix with a uniform rigid-transform base
motion (`GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` item 6.10). A richer
rigid-plus-residual hybrid was designed alongside it and is deliberately
deferred as a documented future improvement — not built now, not
abandoned.**

**What was found.** `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` item 6.7's
third round of live testing on entity 14 (32 closed blocks, 49 open-scan
blocks after the real `//sel convex` capture) reported the mid-swing motion
looking "weird" / "more like fluid than a drawbridge" — worse than the
pre-item-6 pure-procedural rotation. The working hypothesis at the time
(every closed block now gets Mechanism 2's linear correction term, most of
them non-trivial, because the dense real scan pairs nearly everything) was
confirmed with direct evidence in a follow-up diagnostic session, not just
re-reasoned:

- Diagnostic trace logging (`knk-plugin` commit `9c02f02`) captured a full
  per-block, per-frame breakdown (`baseline`/`pairedOpen`/`openTarget`/
  `correction`/`correctionMag`/`final`) for a live open *and* close cycle, in
  both `GeometryDefinitionMode=REGION` and `GeometryDefinitionMode=PLANE_GRID`.
- **The two modes' logs are byte-for-byte identical** (diffed directly, with
  timestamps stripped) except for HTTP-latency noise and ordinary
  tick-scheduling jitter between two separate real-time runs (one frame
  logged once in one run, split across two ticks in the other). This rules
  out `GeometryDefinitionMode` as the cause outright — confirmed by code
  inspection too: neither `GateFrameCalculator.calculateBlockPositionBreakdown`
  nor `GateAnimationTask.updateGateBlocks` reads `GeometryDefinitionMode` at
  all. Mechanism 2 activates purely on `gate.getPairedOpenBlock(id) != null`,
  independent of capture mode — so toggling REGION vs. PLANE_GRID on this
  door was never going to change anything about the swing.
- The trace confirms the hypothesis precisely: adjacent blocks carry wildly
  different `correctionMag` values at the same frame (e.g. the hinge-row
  block sits at `0.000` for the entire swing while its immediate neighbor
  reaches `~5.0` blocks of extra drift by the final frame) — each block is
  blended independently toward its own individually nearest-neighbor-matched
  open cell (`GateBlockPairing`'s Hungarian match, optimal only in *total*
  distance, never in per-block agreement with its neighbors), so the door
  does not move as one rigid piece.
- A second, compounding effect: the open scan has 49 cells against 32 closed
  cells, so `GateBlockPairing` (inherently capped at `min(closed, open)`)
  leaves 17 cells unpaired; those never enter `GateAnimationTask.
  updateGateBlocks`'s per-tick loop (it only ever iterates the closed-block
  list) and only appear in one shot when `GateRestingFramePlacer.
  transitionRestingFrame` force-places the full open-scan set at the very
  last tick — item 6.9's own accepted, documented trade-off, confirmed
  working as designed, not a new problem.
- Comparison against the pre-item-6 formula (`knk-plugin` git history,
  commit `fbbb077` "feat(gate): implement rotation gap-fill Mechanisms 1 and
  2" — the commit that introduced Mechanism 2 in the first place): before
  this plan, `ROTATION` motion was simply `position = anchor + rotate
  (relativePos, hingeAxis, angle)` — one rigid rotation, identical formula,
  identical axis/angle, applied uniformly to every block, every frame. That
  uniformity is exactly what guaranteed the "way smoother" look the user is
  asking to get back; Mechanism 2's per-block correction term is what broke
  it, by construction, once the pairing is dense enough that most/every
  block gets a non-trivial correction — true for any real captured open scan
  denser than the small hand-built fixtures Mechanism 2 was validated
  against (see Decision 2's original "known risk," which materialized here
  in a different, uglier form than the "crossing paths" it anticipated).

**Options considered**, in increasing order of how much of Mechanism 2's
original per-block intent they preserve:

1. **Uniform rigid transform.** Replace the per-block correction with one
   shared best-fit rotation+translation (least-squares/Procrustes/Kabsch,
   fit once per door load from the paired closed/open points), applied
   identically to every block, including the 17 open-only ones (by
   inverse-transforming their real open-scan position back through the same
   shared transform to synthesize a closed-side start point, instead of
   leaving them un-animated as today). Rigid by construction — every block
   shares the exact same motion, so no two neighbors can disagree — and,
   unlike today's per-block scheme, it animates 100% of blocks, not just the
   paired ones. Trade-off: mid-swing exactness for any individual block
   whose true relationship to the fitted transform is a genuine outlier (see
   below).
2. **Keep per-block pairing, animate the open-only blocks too.** Smaller
   patch, doesn't touch the per-block correction term at all, so the core
   warping complaint is untouched.
3. **Drop Mechanism 2's blend entirely, pure procedural rotation.**
   Simplest, matches the pre-item-6 look exactly, but gives up the entire
   point of a manually-scanned open state — an admin's real captured shape
   stops being used for anything beyond the resting frame.
4. **Hybrid — uniform rigid transform as the base motion, plus a small
   residual correction on top, computed relative to the fitted transform's
   own prediction rather than the raw rotation arc.** A block that's
   genuinely rigid gets ~zero residual (rigid-looking, same as option 1);
   only a block that's truly part of a non-rigid addition (e.g. a
   decorative element or support strut with no real rotational relationship
   to anything in the closed scan) gets a residual nudge, sized to how
   non-rigid it actually is, instead of the uniform full correction every
   block gets under today's shipped Mechanism 2. This is the option that
   gives up *nothing* from the original design goals — full multi-material
   support, full shape/dimension-mismatch support, **and** exact per-block
   convergence even for a genuinely non-rigid open-state addition — at the
   cost of materially more design and implementation work: choosing a fit
   algorithm and its degenerate-input handling (too few pairs, collinear/
   coplanar points), deciding how a residual is sized/tapered (so it
   doesn't just reintroduce today's per-block disagreement in a smaller
   dose), and a larger new test surface than option 1's.

**Decision: ship option 1 now; option 4 (the hybrid) is deliberately
deferred as a documented future improvement, not abandoned.** Reasoning:

- **Timeline.** The immediate goal is a clean, presentable animation as soon
  as possible. Option 1 is a materially smaller, better-understood change (a
  standard rigid-registration fit, plus reusing the inverse-rotation math
  `rasterizeRotationFrame` already established for a related problem) with a
  clear, bounded test surface. Option 4 has open design questions
  (fit-degeneracy handling, residual sizing/tapering) that would need their
  own design pass before implementation could even start — not worth the
  delay for a fix the user wants live soon.
- **Fit to the actual, real data.** Entity 14's real open scan (49 blocks)
  is the door's own closed structure (32 blocks) rotated open, plus a modest
  extra row at the farthest edge from the hinge (per the user's own in-game
  description, item 6.7's "Second round" — a few blocks wide, centered on
  the door's width) — substantially explained by the closed/open
  lattice-density difference this entire document's problem statement is
  about, not a structurally disconnected addition. This is close enough to
  "the same rigid body, rotated" that a single fitted transform should
  already look clean for the overwhelming majority of blocks on this door;
  the design's own motivating worst case for Mechanism 2 ("a log standing
  vertical when closed and lying flat, a *different structure*, when open")
  is a hypothetical extreme this gate's real data doesn't actually exercise.
- **Nothing in the plan's stated goals is given up by option 1.**
  Multi-material support and the resting-frame shape/dimension mismatch —
  the two goals explicitly checked against this decision before it was made
  — are both properties of `GateRestingFramePlacer`'s endpoint placement and
  each block's own `BlockSnapshot`/open-scan blockdata, never of which
  formula drives the *mid-swing* position. `GateRestingFramePlacer.
  restingFrameCells` (item 6.9) places `gate.getOpenBlocks()`'s own
  `blockData`/positions verbatim at the open resting frame regardless of the
  swing formula above it, and continues to do so unmodified under option 1.
- **What option 1 genuinely gives up**, stated plainly rather than glossed
  over: mid-swing positional exactness for any block that is a true outlier
  under a global least-squares fit — i.e. a hand-built open-state addition
  that isn't well-explained by any single rotation of the closed shape. Such
  a block still converges to its *exact* scanned position at the resting
  frame (unaffected, per the point above) but follows a straighter/less
  individually-tailored path getting there than today's per-block scheme
  would (which is exact at every single frame, at the cost of being the
  thing that's visibly broken today). For entity 14's actual geometry this
  is expected to be a non-issue or a very minor one; it becomes a real
  limitation only for a hypothetical future door built more like the "log
  lying flat" example above.
- **Option 4 is not rejected on the merits** — it is the strictly more
  complete answer, and is worth building once there's a concrete door that
  actually needs it (i.e. one where a global rigid fit visibly fails for
  some of its blocks in live testing). Recorded here specifically so that
  need is recognized quickly if/when it shows up, instead of rediscovering
  this whole analysis from scratch.

**Follow-up implication for `GateBlockPairing`**: option 1 removes the
Hungarian nearest-neighbor matcher from the *position-driving* path — it no
longer decides where a block goes, only (if at all) supplies the rough
initial correspondence a rigid-registration fit needs between the two point
sets to fit against. It is not being deleted.

---

## Implementation plan

### Phase A — Schema — **Done** (2026-09-09)

- **Mechanism 1**: no schema change. Pure plugin-side runtime geometry.
- **Mechanism 2**: implemented in `knk-web-api` as migration
  `20260909201218_AddGateOpenAnchorAndOpenedBlockSnapshots`:
  - `gate_structures.OpenAnchorPointId` (nullable `int`, FK to `locations`,
    `OnDelete: Restrict`) — mirrors `AnchorPointId` exactly.
  - New table `gate_opened_block_snapshots`, mirroring `gate_block_snapshots`'
    columns exactly (`RelativeX/Y/Z`, `WorldX/Y/Z`, `MaterialName`,
    `BlockDataJson`, `TileEntityJson`, `SortOrder`, `GateStructureId` FK with
    `OnDelete: Cascade`), plus the same three indexes `gate_block_snapshots`
    has (`GateStructureId`; `(GateStructureId, SortOrder)`;
    `(WorldX, WorldY, WorldZ)`).
  - **No `SnapshotState` enum, no `State` column added to
    `gate_block_snapshots`** — per Decision 6.
  - **No `AnimationDefinitionMode`** — per Decision 1-5's amendment.
  - New model `GateOpenedBlockSnapshot.cs`
    (`[FormConfigurableEntity("GateOpenedBlockSnapshot")]`, mirroring
    `GateBlockSnapshot.cs`), and `GateStructure.OpenedBlockSnapshots`
    navigation collection alongside the existing `BlockSnapshots`.
  - Verified: migration generated cleanly, full backend build succeeds, all
    5 gate-related tests pass, and the 5 pre-existing unrelated test
    failures (client activity, path resolution, form submission progress)
    are confirmed present on the branch before this change too (checked via
    `git stash`), i.e. not a regression.
  - Not yet applied to the dev database (`dotnet ef database update`) —
    pending explicit go-ahead, since it's a real schema change even though
    fully additive/non-destructive (see below).
- **Data impact of applying this migration**: purely additive. Every
  existing `gate_structures` row gets `OpenAnchorPointId = NULL` (today's
  implicit "no override" state). No existing row in any table is modified
  or deleted. The new table starts empty. On MySQL 8.0.12+/InnoDB this
  qualifies for near-instant DDL (metadata-only column add), so it should
  also be fast regardless of table size.

### Phase B — Backend (knk-web-api) — **Done** (2026-09-10)

- No `AnimationDefinitionMode` enum/field needed (per Decision 1-5) — not added.
- **DTOs** (`Dtos/GateStructureDtos.cs`): `GateOpenedBlockSnapshotDto`/
  `GateOpenedBlockSnapshotCreateDto` added, mirroring `GateBlockSnapshotDto`/
  `GateBlockSnapshotCreateDto` exactly. `GateStructureDto` (and the legacy,
  otherwise-unused `GateStructureReadDto`) gained `OpenAnchorPointId`/
  `OpenAnchorPoint`/`OpenedBlockSnapshots` alongside their existing
  `AnchorPoint*`/`BlockSnapshots` fields.
- **Scan-result DTO** (`Dtos/GateBlockScanDtos.cs`): `WorldTaskTypes.
  GateOpenedBlockScan` constant and `GateOpenedBlockScanResultDto` added,
  mirroring `GateBlockScanResultDto` (same shape, targets
  `GateOpenedBlockSnapshotCreateDto` instead).
- **Scan-completion path** (`Services/WorldTaskService.cs`):
  `CompleteAsync` now branches on `TaskType` between the existing
  `GateBlockScan` handling and a new, structurally-identical
  `TryApplyGateOpenedBlockScanResultAsync`, which calls the new
  `ClearOpenedBlockSnapshotsAsync`/`AddOpenedBlockSnapshotsAsync` service
  methods — naturally correct by construction (Decision 6), no
  `State`-scoping logic needed at all. Covered by
  `WorldTaskServiceGateScanTests` (new): a `GateOpenedBlockScan` completion
  never touches `BlockSnapshots` and vice versa.
- **Repository/service** (`GateStructureRepository`/`GateStructureService`
  + interfaces): `GetOpenedBlockSnapshotsByGateIdAsync`/
  `AddOpenedBlockSnapshotAsync`/`AddOpenedBlockSnapshotsAsync`/
  `DeleteOpenedBlockSnapshotsByGateIdAsync` added, mirroring the existing
  `*BlockSnapshot*` methods exactly. `DeleteAsync` now also clears
  `OpenedBlockSnapshots` before deleting a gate (parity with the existing
  `BlockSnapshots` cleanup, on top of the FK's own `OnDelete: Cascade`).
  `ApplyLocationReferencesAsync` now resolves `OpenAnchorPointId`/
  `OpenAnchorPoint` the same way it already does for `AnchorPoint`.
  Fixed in passing: `BuildGateQuery()`/`SearchAsync` were missing an
  `.Include(gs => gs.OpenAnchorPoint)` (present for `AnchorPoint` but never
  added for its sibling when Phase A introduced it) — a gate's
  `OpenAnchorPoint` navigation would otherwise never have loaded.
- **Controller** (`Controllers/GateStructuresController.cs`): `GET
  /{id}/openedSnapshots`, `POST /{id}/openedSnapshots/bulk`, `DELETE
  /{id}/openedSnapshots` added, mirroring the existing `/snapshots`
  endpoints' routes, verbs, and error handling exactly.
- `GateStructuresController`: no new validation tied to a mode field — the
  existing `GateType`/`MotionType` validation from this session's earlier
  work is untouched.
- Verified: full backend build succeeds with no new warnings; the new
  `WorldTaskServiceGateScanTests` (2 tests) and the existing
  `GateStructureMappingProfileTests` pass; full suite run confirms the same
  5 pre-existing, unrelated failures noted in Phase A (client activity,
  path resolution, form submission progress) and no new ones.
- Not yet done (left for Phase C/D per the plan): the plugin-side
  `GateOpenedBlockScan` `WorldTask` producer (`GateBlockScanTaskHandler`
  branching) and the frontend `FormConfig` wiring — this phase only adds
  the backend surface those will call into.

### Phase C — Plugin (knk-plugin) — **Done** (2026-09-10)

- **Mechanism 1**:
  - `VectorMath.sublatticeIndex(Vector step)` (new, `knk-core`): the `a²+b²`
    formula, computed from `uStep`'s horizontal (X/Z) components. Cached on
    `CachedGate.sublatticeIndex` by `GateLoaderAdapter.precomputeBasisVectors`
    for every gate (cheap, purely geometric), alongside `uStep`/`vStep`/`nStep`.
  - `GateFrameCalculator.rasterizeRotationFrame(gate, angleDegrees)` (new):
    rotates the door's 4 local corners around `hingeAxis`, takes their AABB,
    and tests every integer cell in it by **inverse-rotating it back into the
    closed frame** and reusing a shared `projectOntoBasis` helper (extracted
    from `isWithinGeometryBounds`) against the gate's own unrotated
    `uStep`/`vStep`/`nStep` — equivalent to, and simpler than, rotating the
    step basis forward, since it reuses the gate's already-stored steps
    unchanged. A passing cell's material comes from whichever originally-
    scanned block shares its (rounded) u/v index. Two bugs found and fixed
    during implementation (both caught by unit tests, not left in): (1) a
    naive AABB epsilon-padding let stray cells outside the true footprint
    spuriously pass the projection check for a degenerate 1×1 gate — fixed by
    computing the AABB with no padding, relying only on the projection
    check's own epsilon; (2) the projection check only constrained u/v
    indices, not the n (depth) index, so it accepted points anywhere along
    the infinite line through the footprint, not just the true single-layer
    sheet — fixed by requiring `|nIndex| ≈ 0` (every scanned block is a
    single layer, per `GateBlockScanTaskHandler.computeCellPosition`; a
    documented, known gap for a future `GeometryDepth > 1` extension).
  - Pure, Bukkit-free, directly unit-tested (`GateFrameCalculatorTest`): exact
    reproduction of the closed grid at angle 0, more cells than the naive
    rotated-and-floored set at the open angle, and the trivial 1×1 edge case.
  - `gates.rotationGapFill.rasterization-enabled` config key (default `true`,
    `config.yml`) — Decision 5's kill switch, threaded through
    `GateAnimationTask` and `GateStateSyncTask`'s constructors from `KnKPlugin`.
  - Integration point: rather than touching the hot per-tick
    `GateAnimationTask.updateGateBlocks` sweep at all, Mechanism 1 (and
    Mechanism 2's converged endpoint) is applied only where the plan already
    called for endpoints-only behavior (Decision 3) — `finishOpening`/
    `finishClosing`'s existing force-placement passes, and
    `resyncSpatialIndex`. Kept the mid-swing sweep byte-for-byte its original
    self except for one small, always-safe addition (Mechanism 2's paired
    blockdata substitution, below).
- **Mechanism 2**:
  - `GateLoaderAdapter`: `loadAndCacheGate` gained a 3-arg overload taking
    `openedSnapshotDtos` (the 2-arg form now delegates with an empty list, so
    every existing call site/test kept working unmodified); `loadAll`/
    `loadForDistrict` now fetch `GateStructuresApi.getGateOpenedSnapshots`
    (new API client method, mirroring `getGateSnapshots`) alongside the
    existing snapshots call. `GateStructureDto` (api-client) gained
    `openAnchorPoint`, parsed the same way as `anchorPoint`.
  - `CachedGate`: `openBlocks` (`List<BlockSnapshot>`, empty not null),
    `openAnchorPoint`, and `openBlockPairing` (`Map<Integer, BlockSnapshot>`,
    keyed by the **closed** block's own `getId()` — chosen over a list-index
    key so `GateFrameCalculator.calculateBlockPosition` needs no index
    parameter at all, keeping every existing call site's signature and
    behavior unchanged when a gate has no pairing).
  - `GateBlockPairing.pairNearestNeighbor` (new, `knk-core`, pure/testable):
    greedy nearest-3D-neighbor matching by absolute world position. Pins down
    the many-to-one tie-break Decision 2 left open: closed blocks claim in
    list (SortOrder) order, so "first-claimed-wins" — a later block wanting
    an already-claimed open block falls back to its next-nearest available,
    or is left unpaired (Decision 1(a)'s existing fallback) if none remain.
  - `GateLoaderAdapter.loadOpenBlockSnapshots`: populates `openBlocks` and
    computes the pairing — by `GateBlockPairing` (absolute world distance)
    for `ROTATION`, by matching SortOrder-sorted list index for
    `VERTICAL`/`LATERAL` (both scans "walk the same deterministic loop from
    their own anchor", per the design).
  - `GateFrameCalculator.calculateBlockPosition`: for a block with a pairing,
    `VERTICAL`/`LATERAL` now `lerp`s between the closed position and the
    paired open block's absolute world position; `ROTATION` applies the
    `arcPos(frame) + (openScanPos - arcPos(totalFrames)) * progress` blend.
    Both verified by unit test to reduce to exactly the closed position at
    `progress=0` and exactly `openScanPos` at `progress=1`; an unpaired block
    on the same gate is unaffected (falls through to the original formulas).
    Per Decision 4, clipping is still checked only against the final blended
    `position`, never an intermediate term — unchanged control flow, just a
    different `position` value feeding into the existing check.
  - Orientation (per the design's "simplest correct rule"): a paired block
    always uses the paired open block's own blockdata as-is — never
    `GateBlockOrientation`'s angle-based rotation — in both
    `GateAnimationTask.updateGateBlocks` (mid-swing) and the shared
    `GateRestingFramePlacer` (endpoints), unconditionally on pairing
    presence, not gated on how far `progress` has converged (matches the
    design's explicit choice of the simpler, unconditional rule).
  - **Found while wiring up the endpoints (not originally called out in this
    plan): `GateStateSyncTask.reconcileWorldOnStartup`** independently
    force-places a gate's resting frame from scratch (to fix a world/DB
    mismatch after a restart) and had its own separate per-block placement
    loop — meaning a diagonal-hinge gate already `OPEN` when the server
    booted would have been reconciled back to the *old* sparse/unpaired
    footprint, silently undoing Mechanism 1/2 on every restart. Fixed by
    extracting the shared "what does this gate's resting frame actually look
    like" logic (rasterize-or-per-block, pairing-aware) into a new
    `GateRestingFramePlacer` (`knk-paper`), used by both `GateAnimationTask`
    (animation completion) and `GateStateSyncTask` (startup reconciliation) -
    including a `RestingCell(position, blockData)` pairing so the stale-frame
    vacate step can still safely match-before-remove for a rasterized cell,
    not just a plain scanned block. **Investigating this further surfaced a
    separate, broader gap** in world/DB synchronization generally (not
    specific to rotation gap-fill) — `reconcileWorldOnStartup` silently
    no-ops for any gate whose chunk isn't loaded at boot, with no retry, and
    on-demand district loads never reconcile at all. That problem and its
    proposed fix (lean on district-load rather than an eager startup pass,
    plus a periodic health-check) are scoped out into their own document:
    see [GATE_WORLD_SYNC_DESIGN.md](GATE_WORLD_SYNC_DESIGN.md) — proposed,
    not started, and intentionally reuses `GateRestingFramePlacer` from this
    phase as its shared placement/check primitive.
- **New WorldTask type** `GateOpenedBlockScan`: `GateBlockScanTaskHandler.
  supports(...)` now accepts both task type names; `execute` resolves
  `useOpenAnchor` from the task's own `taskType()` and threads it through to
  `buildScanWings`, which sources the wing's *origin* from `OpenAnchorPoint`
  instead of `AnchorPoint` when set (the lattice basis itself is still always
  derived from `ReferencePoint1/2` relative to the closed `AnchorPoint`, per
  the design's own `GateStructure.cs` contract - only the origin moves). The
  scan loop, chunking, and output JSON building are byte-for-byte unchanged -
  the backend (`WorldTaskService`, Phase B) is what routes the identically-
  shaped output to the right table based on `TaskType`, so this handler never
  needed to know about `GateOpenedBlockSnapshot` at all. `FLOOD_FILL` +
  `useOpenAnchor` fails fast with an explicit "not supported yet" message,
  matching the plan's non-goal instead of silently scanning the wrong thing.
- **Verified**: full multi-module build succeeds; 335 tests pass across
  `knk-core`/`knk-api-client`/`knk-paper` (110 + 26 + 199, 12 pre-existing
  skips unrelated to this work), including new coverage for
  `VectorMath.sublatticeIndex`, `GateFrameCalculator`'s rasterization and
  blend/lerp formulas, `GateBlockPairing`, `GateLoaderAdapter`'s opened-scan
  loading and pairing (both motion-type branches), `GateBlockScanTaskHandler.
  supports`/anchor branching, and `GateRestingFramePlacer`'s eligibility logic.
  A few planned assertions needed a live Bukkit server to exercise (anything
  touching `GateBlockOrientation.applyRotation`'s `Bukkit.createBlockData`
  call) and were scoped down or left to manual/Phase F testing instead,
  matching this codebase's existing convention for that class of test.

### Phase D — Frontend (knk-web-app) — **Done** (2026-09-10)

- No `AnimationDefinitionMode` dropdown needed — whether a gate uses
  dual-scan is entirely a function of whether the `OpenedBlockSnapshots`
  scan was completed. Unchanged from the plan; nothing to add here.
- **`FormConfig` for `GateStructure` gaining an `OpenedBlockSnapshots` field
  is an admin/data action, not a code change** — this was the first thing
  Phase D had to clarify. `objectConfigs.tsx`'s static `GateStructureConfig`
  (Phase 5's original 20-field config) turned out to no longer be what
  actually drives the gate creation/edit wizard: `FormWizardPage`/
  `FormWizard` render fields entirely from the *dynamic*, database-backed
  `FormConfigurationDto` (built via the `FormConfigBuilder`/`FieldEditor`
  admin UI) - the static config is only still consulted for the gate list's
  column definitions. Per `GATE_FORMCONFIG.md` (Deel B) itself, no
  `GateStructure` `FormConfiguration` has actually been seeded yet at all
  (its own "Openstaande werkzaamheden" #4). So "add a field for
  `OpenedBlockSnapshots`, mirroring `BlockSnapshots`" isn't a file to edit -
  it's something whoever eventually builds that `FormConfiguration` does
  through the admin UI, the same way they'll need to add `BlockSnapshots`
  itself. **What Phase D *could* and did fix in code** is the supporting
  infrastructure `BlockSnapshots`'s `worldTaskType: 'GateBlockScan'` field
  already depends on, generalized to recognize its sibling:
  - `FieldEditor.tsx`: `'GateOpenedBlockScan'` added to
    `PREDEFINED_TASK_TYPES` (so it's selectable at all when an admin does
    build the field), plus a hint explaining it scans the gate's open state
    from its Open Anchor Point rather than the closed one.
  - `WorldBoundFieldRenderer.tsx`: every place that special-cased the literal
    string `'GateBlockScan'` (headless/no-player detection, the "send to
    Minecraft" button's entity-id guard, the scan-progress/result-details
    UI) generalized to a shared `GATE_BLOCK_SCAN_TASK_TYPES = ['GateBlockScan',
    'GateOpenedBlockScan']` array and an `isGateBlockScanTask` helper - both
    task types now get byte-for-byte identical treatment, matching the
    backend's own "the scan loop itself is identical for either" design
    (Phase C).
  - New tests (`WorldBoundFieldRenderer.results.test.ts`, `it.each`-parameterized
    over both task types): scan status/block-count/warning result details,
    and headless-task-type detection.
- **`GateType`/`MotionType` cross-validation** (the opportunistic cleanup
  this plan flagged): the static `objectConfigs.tsx` field system's
  `validation` callback is single-value-only (`(value: T) => string |
  undefined`, no access to sibling fields), and the real admin form's
  cross-field validation goes through the dynamic `FieldValidationRule` /
  `IValidationMethod` backend system instead - but that system had no
  validation type capable of expressing "field X must equal value Y when
  dependency Z matches a condition" at all. The closest existing one,
  `ConditionalRequiredValidator`, only checks presence/absence, never the
  field's actual value. Added a new sibling, `ConditionalValueMatchValidator`
  (`knk-web-api`, registered in DI alongside the other `IValidationMethod`s):
  `ConfigJson` names a `condition` (evaluated against the dependency field,
  e.g. `GateType in "DRAWBRIDGE,DOUBLE_DOORS"`) and an `expected` clause
  checked against the field's own value when the condition holds (e.g.
  `MotionType equals "ROTATION"`) - same operator vocabulary as
  `ConditionalRequiredValidator` (`equals`/`notEquals`/`greaterThan`/
  `lessThan`/`contains`/`in`). This is a reusable building block, not
  GateStructure-specific; wiring an actual `FieldValidationRule` row that
  uses it onto `GateStructure.MotionType` is, like the `OpenedBlockSnapshots`
  field above, an admin/data action that happens once a real `GateStructure`
  `FormConfiguration` exists to attach it to.
  - Found and fixed two bugs while writing this (both caught by new tests,
    not shipped): (1) `System.Text.Json` deserializes an `object`-typed
    config property as a boxed `JsonElement`, never a plain CLR `string` -
    a naive `is string` check (the pattern `ConditionalRequiredValidator`
    itself already uses for its own "in"/"contains" operators, apparently
    never caught since its own test file is excluded from the build - see
    below) silently always fails; fixed via an explicit `ToComparableString`
    helper that unwraps `JsonElement` by `ValueKind` first. (2)
    `JsonSerializer.Deserialize` is case-sensitive by default, so a
    camelCase `ConfigJson` (the convention every other DTO in this API
    uses) wouldn't populate PascalCase C# properties at all; fixed with
    `PropertyNameCaseInsensitive = true` on the deserialize call.
  - New `ConditionalValueMatchValidatorTests` (11 tests): the DRAWBRIDGE/
    DOUBLE_DOORS + non-ROTATION-motion scenario directly, condition
    operators (`in`, `equals`), unconstrained-when-condition-not-met for
    every other `GateType`, missing/malformed config handling, and the
    `expected` clause's own `in` operator. Written against the actual,
    current `IValidationMethod.ValidateAsync(fieldValue, dependencyValue,
    configJson, formContextData)` signature (confirmed from
    `FieldValidationService`'s real call sites) rather than the older
    `FieldValidationRule`-based signature `tests/.../ValidationMethodsTests.cs`
    uses - that whole file (plus a few other validation-system test files)
    is `<Compile Remove>`-excluded from the test project already, predating
    the current interface; not touched here, out of scope for this plan.
- **Verified**: frontend `tsc --noEmit` passes with no errors; the two
  updated/new frontend test files pass (21/21, up from 15 before - 2 new
  `it.each` blocks); backend full suite passes 288/293 (11 new tests, same
  5 pre-existing unrelated failures as every prior phase - client activity,
  path resolution, form submission progress).

### Phase E — Docs — **Done** (2026-09-10)

- `SPEC.md`: added `OpenAnchorPointId`/`OpenAnchorPoint` to `GateStructure`'s
  field list and DB schema block, a new `GateOpenedBlockSnapshot` entity
  subsection mirroring `GateBlockSnapshot`'s, and a "Rotation Gap-Fill
  (Mechanisms 1 & 2)" subsection under Plugin Animation Engine documenting
  the automatic-rasterization trigger/kill-switch and Mechanism 2's implicit
  trigger with per-`MotionType` blend/lerp formulas.
- `REQUIREMENTS.md`: same `OpenAnchorPointId` addition to the GateStructure
  field list, plus a `GateOpenedBlockSnapshot Entity` subsection and two new
  `Related Documentation` links (this doc, `GATE_WORLD_SYNC_DESIGN.md`).
- `GATE_FORMCONFIG.md`: new "Optioneel, ongeacht type (Rotation Gap-Fill)"
  section adding `OpenAnchorPointId`/`OpenedBlockSnapshots` to the
  requirement matrix as their own entries (per-type, they apply to every
  `GateType`, unlike the rest of section 2's type-dependent fields);
  updated point 3 ("Afgeleide velden") to note `ConditionalValueMatchValidator`
  (Phase D) as the available stop-gap for the `GateType`/`MotionType`
  consistency check until real server-side derivation exists; updated point
  4 ("Seeden van de configuratie") to note `OpenedBlockSnapshots` needs
  adding alongside `BlockSnapshots` whenever that seeding finally happens.
- `DUAL_SCAN_ANIMATION_DESIGN.md`: added a top-of-document amendment notice
  (mirroring this doc's own header note, from the other direction) plus
  inline `⚠️` callouts at the specific `AnimationDefinitionMode` and
  `State`-column sections, clarifying exactly what shipped differently
  (implicit trigger, separate `GateOpenedBlockSnapshot` table) versus what's
  still accurate as historical rationale (the motivating problem, the
  `VERTICAL`/`LATERAL` lerp logic's shape, Open Question 1's resolution).
- This doc's own top-level `Status` line updated from "Proposed (not
  started)" - stale since Phase A landed - to reflect Phases A-D actually
  being done, and cross-linked to `GATE_WORLD_SYNC_DESIGN.md` (found while
  implementing Phase C, documented as its own plan rather than folded in
  here).

### Phase F — Pilot & validation

- **Mechanism 1 first, zero admin action**: once shipped, verify GateStructure
  #14 opens to a solid (not checkerboarded) bridge with no configuration
  change at all.
- **Mechanism 2 second, opt-in**: separately, build and scan a custom open
  shape for a test `ROTATION` gate to confirm the blend produces a smooth,
  pop-free swing into the true scanned shape, and that a `VERTICAL`/`LATERAL`
  test gate's existing `lerp` behavior is unaffected.
- Leave every other gate untouched — both mechanisms apply automatically and
  losslessly based on existing data; no forced migration for either.

---

## Edge cases

**Geometry / lattice**
- Cardinal-hinge `ROTATION` gates (index 1): Mechanism 1 must compute index=1
  and take the existing procedural path with zero behavior change.
- Non-45° diagonal hinges (index ≥ 5): Mechanism 1's cost is proportional to
  index (more candidate cells in the AABB); Mechanism 2's admin cost is
  unaffected either way (still "build and scan one shape").
- `GeometryDepth > 1` (multi-layer thick doors): rotation around `uAxis`
  affects **both** `vStep` and the closed-state's `nStep` (thickness)
  components together — both are perpendicular to the hinge and therefore
  both get mixed by the rotation, not just height. Needs explicit
  verification once `D > 1` is tested; gate #14 has `D=0` (effectively 1
  layer) so this path is currently unexercised for both mechanisms.
- `GeometryWidth`/`Height` = 1: index math is moot (no gaps possible with a
  single column) — Mechanism 1 should compute a trivial 1-cell "fill"
  identical to the unrasterized result.

**Mechanism interaction**
- A gate has *both* `OPEN` snapshots and a diagonal hinge: Mechanism 2 must
  fully suppress Mechanism 1 (the `openBlocks`-empty check already gates
  this) — never rasterize on top of or alongside a manual scan.
- An admin deletes a gate's `OPEN` snapshots after having them: Mechanism 1
  should then engage automatically if index `> 1` (falls through to the
  default) — the implicit trigger cuts both ways, no separate "revert to
  procedural" step needed.

**Pairing / blending (Mechanism 2, `ROTATION`)**
- Greedy nearest-neighbor pairing producing crossing motion paths — see Open
  Question 2.
- A block with no pairing at all (Decision 1) — default: pop in at the
  final frame, same as today's behavior for that one block.
- Very large corrections (`openScanPos` far from `arcPos(totalFrames)`): the
  linear correction term is added to an already-curved arc, so a block with
  a large mismatch may visually appear to "overshoot" or move in a way that
  doesn't read as a clean arc *or* a clean line — acceptable for v1 (still
  converges exactly, just not necessarily elegantly for extreme mismatches);
  flag as a known visual limitation, not a defect to fix now.
  **Superseded 2026-09-16 (Decision 7)**: this "acceptable for v1" call
  turned out to be wrong in practice once real dense scan data was tested
  live — this is exactly what produced the reported "fluid"/non-rigid swing.
  See Decision 7 for the confirmed root cause and the fix direction (item
  6.10 of `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md`).
- Multiple closed blocks nearest-neighbor-matching the *same* open block
  (many-to-one): needs an explicit tie-break rule (e.g. first-claimed-wins,
  remaining closed blocks fall back to unpaired behavior) — not yet decided,
  needs to be pinned down in Phase C, not left implicit in the pairing
  helper's implementation.

**Motion / timing**
- `RotationMaxAngleDegrees` other than 90, `AnimationTickRate > 1`, a
  lag-induced fast-forward, or a main-thread stall jumping straight to
  `frame == totalFrames` (this session's `finishOpening` fix): the blend
  formula is evaluated per-frame from `progress(frame)`, so a frame skip
  just means `progress` jumps too — the formula still converges correctly at
  `progress=1` regardless of how it got there. This is a genuine advantage
  over the earlier hard-swap design, which needed careful footprint-vacate
  handling for exactly this scenario.
- Jam/obstruction: placements (whether blended or rasterized) still go
  through the same `placeBlockIfVacant` obstruction check as any other frame.
- Repeated open/close cycles: closing must run the blend/pairing in reverse
  cleanly (progress decreasing from 1 to 0) without leaving stray blocks.

**Data / admin workflow**
- `OPEN` scan built with tile-entity-bearing blocks: same existing,
  already-documented scan limitation.
- Admin re-scans the closed state after an open-state scan already exists:
  structurally cannot invalidate `OpenedBlockSnapshots` (separate table,
  Decision 6) — but the plugin-side pairing helper still needs to recompute
  (closed positions changed, so nearest-neighbor pairing needs to be redone
  on next load, not left stale).
- `DOUBLE_DOORS`' two-wing scan: out of scope for v1; if pursued later, each
  wing needs its own `OpenAnchorPoint`/`openBlocks`/pairing.

**System integration**
- `GateSpatialIndex` must reflect the *current frame's* blended/rasterized
  positions at all times while animating, and the converged/rasterized
  positions while resting open — not a stale pre-blend position.
- `WorldGuardIntegration.syncRegions`'s `RegionOpenedId`: confirm it doesn't
  assume the open footprint matches `GeometryWidth × GeometryHeight`.
- `CollisionPredictor`/`EntityPusher`'s `entitySearchRadius`: verify it
  covers the actual (rasterized- or scan-derived) footprint.
- `GateDisplayManager`: audit for any assumption that the visual open-state
  size matches the closed-state configured geometry.

---

## Testing strategy

- **Plugin — Mechanism 1**:
  - Pure unit tests for the corner-rotation and rasterization helpers: verify
    gate #14's known numbers (121-cell AABB, ~64 filled cells) as a
    regression anchor.
  - Index computation (`a²+b²`) unit tests: cardinal → 1, 45° → 2, `(2,1)` →
    5.
  - Regression test: a cardinal `ROTATION` gate's placements are
    byte-for-byte unchanged before/after this feature lands.
- **Plugin — Mechanism 2**:
  - Blend formula unit tests: `progress=0` returns the closed position
    exactly, `progress=1` returns the scanned open position exactly (for any
    arbitrary `openScanPos`, including ones far from `arcPos(totalFrames)`),
    and intermediate `progress` values are a deterministic function of both
    inputs.
  - Pairing helper unit tests: correct nearest-neighbor matches for a known
    small set of closed/open positions; explicit test for the many-to-one
    tie-break rule (Edge cases above) once decided.
  - Regression test: a `VERTICAL`/`LATERAL` gate with an `OPEN` scan produces
    the same `lerp` result `DUAL_SCAN_ANIMATION_DESIGN.md`'s own plan
    specifies, unaffected by this plan's `ROTATION`-specific branching.
  - `finishOpening`/`finishClosing`: `ROTATION` with `openBlocks` converges
    to the exact scanned position at the relevant endpoint.
  - Vacate/idempotency test across repeated open/close cycles, including the
    reverse-blend direction on close.
- **Backend**: scan-completion test that applying a `GateOpenedBlockScan`
  result never touches `BlockSnapshots` for the same gate and vice versa
  (this is structurally guaranteed by separate tables, per Decision 6, but
  worth a regression test anyway); confirm no `AnimationDefinitionMode`
  validation exists to remove/skip.
- **Manual (Phase F pilot)**: GateStructure #14 opens solid via Mechanism 1
  with zero config change; a separately-configured test `ROTATION` gate with
  a custom `OPEN` scan swings smoothly into the true shape with no pop.

## Risks

- **Mechanism 1 is unconditional, not opt-in** — a bug in the index or
  rasterization math affects every diagonal `ROTATION` gate automatically.
  Mitigated by Decision 5's kill switch.
- **Pairing quality** (Decision 2) — greedy nearest-neighbor is simple but not
  guaranteed visually clean for an open scan that rearranges blocks
  non-locally relative to the closed shape.
- **Rasterization cost scales with sublattice index.** A `(2,1)`-type gate's
  Mechanism 1 fill is ~5× the naive block count; verify actual tick cost on
  a real gate before assuming it's negligible.
- **This plan's Phase A no longer depends on `DUAL_SCAN_ANIMATION_DESIGN.md`
  shipping first at all** — per Decision 6, it doesn't reuse that doc's
  schema proposal (neither `AnimationDefinitionMode` nor the `State`
  column); `GateOpenedBlockSnapshot` is implemented independently and
  already exists in the codebase as of 2026-09-09. `DUAL_SCAN_ANIMATION_
  DESIGN.md` should instead be updated to adopt *this* plan's schema for its
  own `VERTICAL`/`LATERAL` use case, reversing the original dependency
  direction.
- **Scope creep into `FLOOD_FILL`/`DOUBLE_DOORS`.** Same discipline
  `DUAL_SCAN`'s plan calls for: prove this out on `DRAWBRIDGE`/`PLANE_GRID`
  (gate #14) before generalizing either mechanism.
