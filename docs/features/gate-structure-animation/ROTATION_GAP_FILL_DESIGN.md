# Rotation Gap-Fill: Design & Implementation Plan

**Status:** Proposed (not started)
**Author:** Claude (plan requested by Pandi), 2026-09-09
**Related:** [SPEC.md](SPEC.md), [REQUIREMENTS.md](REQUIREMENTS.md), [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md), [DECISIONS.md](DECISIONS.md), [DUAL_SCAN_ANIMATION_DESIGN.md](DUAL_SCAN_ANIMATION_DESIGN.md) (Open Question 3 — this plan resolves it: dual-scan extends to `ROTATION` gates)

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

---

## Implementation plan

### Phase A — Schema — **Done** (2026-09-09)

- **Mechanism 1**: no schema change. Pure plugin-side runtime geometry.
- **Mechanism 2**: implemented in `knk-web-api-v2` as migration
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

### Phase B — Backend (knk-web-api-v2) — **Done** (2026-09-10)

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

### Phase C — Plugin (knk-plugin-v2)

- **Mechanism 1**:
  - `GateFrameCalculator`: add a corner-rotation helper (rotate the 4 local
    corners by a given angle around `hingeAxis`) and a rasterization helper
    (AABB + per-cell `isWithinGeometryBounds`-style projection + nearest-
    scanned-block material lookup). Both are pure functions, directly
    unit-testable without Bukkit, matching this session's `GateFrameCalculator.
    calculateRotationAngle` precedent.
  - Compute the sublattice index (`a² + b²` from `uStep`'s horizontal
    components) once per gate load (`GateLoaderAdapter`), cache it on
    `CachedGate` alongside `uStep`/`vStep`/`nStep`.
  - `GateAnimationTask.updateGateBlocks`/`finishOpening`/`finishClosing`: at
    the resting endpoints (frame 0 and frame `totalFrames`), when index `> 1`
    and `gate.getOpenBlocks()` is empty, source placements from the
    rasterized set instead of the sparse rotated set.
  - Add a plugin config toggle (e.g. `gates.rotationGapFill.rasterization-
    enabled`, default `true`) checked before Mechanism 1 engages at all —
    Decision 5's kill switch. `false` falls through to today's exact
    unmodified sparse-lattice behavior, same as if index were 1.
- **Mechanism 2**:
  - `GateLoaderAdapter.loadBlockSnapshots`: load `BlockSnapshots` into
    `gate.getBlocks()` as today (unchanged); separately fetch the gate's
    `OpenedBlockSnapshots` (new API call to Phase B's endpoint) into a new
    `gate.getOpenBlocks()` (empty list, not null, when none exist — this
    emptiness check *is* the Mechanism 1/2 selector, replacing the removed
    enum check).
  - `CachedGate`: add `openBlocks` (`List<BlockSnapshot>`).
  - New pairing helper (`GateBlockPairing` or similar): nearest-neighbor
    match each `blocks` entry to an `openBlocks` entry by 3D distance at
    load time (once per gate, not per frame) — cache the pairing on
    `CachedGate` alongside `openBlocks`.
  - `GateFrameCalculator.calculateBlockPosition`: for `MotionType=VERTICAL`/
    `LATERAL` with a non-empty `openBlocks`, `lerp` using the `SortOrder`
    pairing (per `DUAL_SCAN`'s original design). For `MotionType=ROTATION`
    with a non-empty `openBlocks`, apply the blend formula above using the
    nearest-neighbor pairing, falling back to the pure arc (today's formula)
    for any block with no pairing (Decision 1(a)). Per Decision 4: compute
    the raw `arcPos(frame)` without applying `ClipToGeometryBounds` inside
    the blend, add the correction term, and only then run the clipping check
    against the resulting final position — never clip the intermediate arc
    term, or the correction has nothing to add to.
  - `finishOpening`'s force-placement loop (added this session): for a
    `ROTATION` gate with `openBlocks`, force-places at the *converged* blend
    result (`progress=1`, i.e. `openScanPos` exactly) rather than a rotated
    derivation.
  - `resyncSpatialIndex` and every other call site assuming `gate.getBlocks()`
    + `calculateBlockPosition` is the sole source of truth (health system,
    `GateDoorHitService`, `CollisionPredictor`): these already call
    `calculateBlockPosition`, which now internally handles the blend/lerp —
    audit that none of them cache a *pre-blend* position anywhere that would
    go stale.
  - `GateBlockOrientation` (added this session): applies only to the arc
    term for unpaired `ROTATION` blocks. A paired block's orientation is
    taken from `openScanPos`'s snapshot as-is once `progress` is high enough
    that the position is dominated by the open-scan target — simplest
    correct rule: use scanned `OPEN` orientation whenever a block has a
    pairing at all, scanned `CLOSED` orientation rotated by the arc angle
    otherwise.
- New WorldTask type `GateOpenedBlockScan` (sibling to today's
  `GateBlockScan`), matching Decision 6's one-property-one-task-type
  convention. Reuses `GateBlockScanTaskHandler`'s existing scan geometry
  (`buildScanWings`/`ChunkedScanRunnable`/`computeCellPosition` — identical
  math, no changes needed there) but anchored at `gate.getOpenAnchorPoint()`
  instead of `gate.getAnchorPoint()`, and posting its result to Phase B's
  new `GateOpenedBlockSnapshot` endpoint instead of the existing one.
  Simplest implementation: `GateBlockScanTaskHandler.supports(...)` accepts
  both task type names, branching only on which anchor/output target to use
  — the scan loop itself is identical for either. Scanning a `ROTATION`
  gate's open state uses the exact same mechanism as `VERTICAL`.

### Phase D — Frontend (knk-web-app)

- No `AnimationDefinitionMode` dropdown needed — whether a gate uses
  dual-scan is entirely a function of whether the `OpenedBlockSnapshots`
  scan was completed.
- `FormConfig` for `GateStructure` gains a field for the new
  `OpenedBlockSnapshots` property, mirroring however `BlockSnapshots` is
  configured today (`worldTaskType: 'GateOpenedBlockScan'`, per Phase C) —
  a genuinely separate, ordinary wizard step, optional for any gate, added
  the same way any other `FormConfigurableEntity`-backed field is: no
  special "scan state" selector UI needed at all, since it's just a second
  property with its own scan trigger. An admin can add it, skip it, or come
  back and add it later; its mere presence/completion is what activates
  Mechanism 2 — this is the concrete UX improvement Decision 6 was about.
- While touching gate-type/motion-type field config: add the `GateType`/
  `MotionType` cross-validation flagged as missing during this session's
  earlier work (a `DRAWBRIDGE` should default-suggest `ROTATION`, not
  silently accept `VERTICAL`) — same class of bug as this session's
  `MotionType` defaulting incident, worth closing while this area is already
  being edited.

### Phase E — Docs

- `SPEC.md`/`REQUIREMENTS.md`: document Mechanism 1's automatic behavior
  (including the kill-switch config), the new `GateOpenedBlockSnapshot`
  entity/`OpenedBlockSnapshots` property, and Mechanism 2's implicit trigger
  and per-`MotionType` blend/lerp semantics.
- `GATE_FORMCONFIG.md`: add `OpenedBlockSnapshots` (and `OpenAnchorPointId`)
  to the requirement matrix as their own entries, same as any other field.
- Cross-link this doc and `DUAL_SCAN_ANIMATION_DESIGN.md` from each other,
  with `DUAL_SCAN_ANIMATION_DESIGN.md` updated to point at this doc's
  amendment — both the dropped `AnimationDefinitionMode` field and the
  dropped `State`-column schema, per Decision 6.

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
