# Dual-Scan Animation: Design & Implementation Plan

**Status:** Proposed (not started)
**Author:** Claude (plan requested by Pandi), 2026-09-07
**Related:** [SPEC.md](SPEC.md), [REQUIREMENTS.md](REQUIREMENTS.md), [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md), [DECISIONS.md](DECISIONS.md)

---

## Context

Today a gate is defined by scanning its **closed** state once (`GateBlockScan`
WorldTask, PLANE_GRID or FLOOD_FILL mode) into `GateBlockSnapshot` rows, and the
plugin **procedurally** animates them at runtime
(`GateFrameCalculator.calculateBlockPosition`): translate along a `MotionVector`
(derived from `MotionDistanceBlocks`) for VERTICAL/LATERAL motion, or rotate
around a `HingeAxis` for ROTATION motion, over `AnimationDurationTicks`.
Visibility during the animation is separately controlled by
`ClipToGeometryBounds`, which hides any block that animates outside a bounding
box built from `GeometryWidth`/`Height`/`Depth`.

This conflates two different concepts into one field. `GeometryHeight` is
documented (`SPEC.md`) as purely "blocks along v-axis" — the closed door's
shape — but `GateFrameCalculator.isWithinVerticalOpening` also uses it as the
vertical *ceiling a block is allowed to retract into*. The model's own author
already flagged this: `GateStructure.cs:77`'s comment on `ClipToGeometryBounds`
calls out exactly this retract-into-housing ambiguity. In practice this meant
that to make GateStructure #13 leave two rows visible in its opened state
(instead of one), the only working lever was inflating `GeometryHeight` from 4
to 5 — which doesn't mean "5 rows of closed door" (there are still only 4 real
scanned rows), it means "the retraction housing is 5 blocks tall." That
mismatch between a field's documented meaning and its actual runtime effect is
the problem this plan solves.

**Proposed direction** (Pandi's suggestion): instead of one closed-state scan
plus procedural motion math, scan the gate **twice** — once closed, once fully
opened, both physically built in Minecraft — and have the plugin interpolate
each block from its closed-scan position to its corresponding open-scan
position over `AnimationDurationTicks`. An admin defines the end state by
building it, not by fighting bounding-box/motion-vector math. This plan scopes
that as a new, opt-in animation mode that sits alongside the existing
procedural one — it does not replace or migrate any existing gate.

---

## Goals

- Let an admin capture an exact, arbitrary open-state block layout by building
  and scanning it, instead of deriving it from `MotionVector`/`ClipToGeometryBounds`.
- Keep every existing gate (including #13) working unchanged — this is a new
  opt-in mode, not a replacement of the procedural path.
- Reuse existing infrastructure wherever the shape fits: the `GateBlockScan`
  WorldTask pipeline, `VectorMath.lerp` (already implemented and tested,
  currently unused by any gate code path), the PLANE_GRID lattice-step
  scanning this session's fix introduced.

## Non-goals (v1)

- **FLOOD_FILL geometry mode.** BFS-from-seed exploration order isn't
  guaranteed to visit "the same relative shape" from two different seed
  points — the closed and open silhouettes could differ in block count/shape
  in ways that break the index-based correlation this design relies on (see
  Design below). FLOOD_FILL gates stay procedural-only for now.
- **ROTATION motion (DRAWBRIDGE-style swinging gates).** Two endpoint scans
  define a straight-line path between them, not an arc — interpolating a
  drawbridge's blocks in a straight line from flat to raised would cut through
  its own hinge geometry. A real fix needs either multi-keyframe capture or
  keeping the existing Rodrigues-rotation math. Deferred; flagged as an open
  question below.
- **DOUBLE_DOORS.** Builds on PLANE_GRID's two-wing scan; revisit once
  single-wing dual-scan is proven out.

---

## Design

### New concept: `AnimationDefinitionMode`

A new gate-level enum, alongside the existing `GeometryDefinitionMode`
(`PLANE_GRID` / `FLOOD_FILL`, `GateStructureEnums.cs:11-14`):

```csharp
public enum AnimationDefinitionMode
{
    PROCEDURAL,  // current behavior: MotionVector/HingeAxis + ClipToGeometryBounds
    DUAL_SCAN    // new: interpolate between two captured states
}
```

Default `PROCEDURAL` for every existing row (including #13) — nothing changes
for a gate that doesn't explicitly opt in.

### Correlating two scans of the same shape

A `DUAL_SCAN` gate keeps its existing `AnchorPoint`/`ReferencePoint1`/`ReferencePoint2`
(defining the same width×height×depth box and the same u/v/n lattice
directions this session's diagonal-gate fix already computes correctly), and
gains one new field: **`OpenAnchorPointId`** — a second `Location` reference,
following the exact pattern `AnchorPointId`/`ReferencePoint1Id`/`ReferencePoint2Id`
already use.

Scanning becomes two passes over the *same* `(i, j, k)` grid
(`GateBlockScanTaskHandler.buildScanWings`/`ChunkedScanRunnable`, unchanged
iteration order), just anchored at two different world origins:

- **Closed-state scan**: origin = `AnchorPoint` (today's behavior, unchanged).
- **Open-state scan**: origin = `OpenAnchorPoint` (new).

Because both passes walk the identical deterministic `i,j,k` loop, **`SortOrder`
is already the correlation key** between a closed-state block and its
open-state counterpart — no new matching logic needed, just two labeled sets
of the same shape.

### Storing two states of the same gate

`GateBlockSnapshot` (`Models/GateBlockSnapshot.cs`) gains one discriminator
column:

```csharp
public SnapshotState State { get; set; } = SnapshotState.CLOSED; // CLOSED | OPEN
```

A gate's snapshots become `(GateStructureId, State, SortOrder)`-addressable
instead of just `(GateStructureId, SortOrder)`. `SortOrder` pairs a closed row
with its open counterpart directly.

### Animating a `DUAL_SCAN` gate

`BlockSnapshot.java` (currently a single `relativePosition`) gains an optional
`openRelativePosition`. `GateFrameCalculator.calculateBlockPosition` gains a
branch:

```java
if (gate.getAnimationDefinitionMode() == AnimationDefinitionMode.DUAL_SCAN) {
    Vector interpolated = VectorMath.lerp(
        block.getRelativePosition(), block.getOpenRelativePosition(), progress);
    return gate.getAnchorPoint().clone().add(interpolated);
}
```

`VectorMath.lerp` already exists and is already unit-tested
(`VectorMathTest.shouldLerpBetweenVectors`) — it has simply never been wired
into any gate's animation path until now. `MotionVector`, `HingeAxis`,
`MotionDistanceBlocks`, `RotationMaxAngleDegrees`, and `ClipToGeometryBounds`
are all ignored for `DUAL_SCAN` gates (see open question below for the one
case that still needs one of them).

---

## Open design questions (need a decision before implementation)

**1. What happens to a block with no live open-state counterpart?**
If a closed-state cell (e.g. row 2 of gate #13's door) is open air in the
open-state scan, there's no meaningful position to lerp toward. Three options:

  - **(a) Vanish instantly** once `progress > 0`. Simplest, matches "removed
    when the entity opens" as already described for gate #13, but looks like
    a pop rather than a retraction.
  - **(b) Hybrid fallback**: a block with no open-state counterpart keeps
    animating via the *existing* procedural `MotionVector` +
    `ClipToGeometryBounds` path, while blocks that do have a captured open
    counterpart lerp to it. Reuses 100% of the current, working, tested
    procedural code for the "vanishing" blocks and only uses `DUAL_SCAN` logic
    for the blocks that have a real destination — no new vanish-motion design
    needed. Requires `MotionVector`/`ClipToGeometryBounds` to still be
    configured on a `DUAL_SCAN` gate for this fallback to have something to
    do, which partly re-introduces the field-overloading this plan exists to
    remove — but only for the subset of blocks that don't have a scanned
    destination, which is a materially smaller and better-scoped conflation
    than today's "every block, always."
  - **(c) Synthesize a direction**: compute an average/dominant motion
    direction from the blocks that *do* have a real destination, and slide
    the disappearing ones the same way, clipping once they leave the box.

  **Recommendation:** (b) for v1 — it's the smallest change or the largest
  guaranteed to not add new failure modes, and gate #13 already relies on the
  procedural path behaving exactly as it does today for its vanishing rows.
  Revisit (a)/(c) once dual-scan has real usage.

**2. Should `GeometryHeight`/`MotionDistanceBlocks` be hidden in the form UI
when `AnimationDefinitionMode=DUAL_SCAN` is selected?**
Recommend yes, once decision 1 lands — if the answer is (a) or (c), those
fields become fully irrelevant to `DUAL_SCAN` gates and showing them invites
exactly the confusion that started this conversation. If (b), they stay
visible but the field description should say they only affect blocks lacking
an open-state counterpart.

**3. Should `ROTATION` gates eventually get a `DUAL_SCAN`-like mode?**
Deferred (see Non-goals). If pursued later, it likely needs a third "scan
state" beyond `CLOSED`/`OPEN` — e.g. one or more intermediate keyframes — which
the `SnapshotState` enum should be designed to extend into rather than assume
is exactly two values forever. Recommend defining `SnapshotState` as a
string-backed enum in the migration (not a plain 0/1 bool column) so adding a
third state later is a value addition, not a schema change.

---

## Implementation plan

### Phase A — Schema

One EF Core migration (naming convention confirmed from
`20260902200227_AddGateMotionDistanceAndClipBounds`, the most recent
comparable single-purpose gate migration):

`{timestamp}_AddGateDualScanAnimationMode.cs`:
- `gate_structures`: add `AnimationDefinitionMode` (string/enum, `NOT NULL DEFAULT 'PROCEDURAL'`), add `OpenAnchorPointId` (nullable int, FK to `locations`, mirroring `AnchorPointId`'s existing FK).
- `gate_block_snapshots`: add `State` (string/enum, `NOT NULL DEFAULT 'CLOSED'`). Add a composite index on `(GateStructureId, State, SortOrder)` — this is the pairing lookup the animation-loading path will use.
- Down() drops both new columns/index and the FK, per this repo's existing migration style.

Backward compatibility: every existing row defaults to `PROCEDURAL`/`CLOSED`,
so `WHERE State = 'CLOSED'` reproduces exactly today's query results for every
existing gate with zero data migration needed.

### Phase B — Backend (knk-web-api-v2)

- `GateStructureEnums.cs`: add `AnimationDefinitionMode` and `SnapshotState` enums.
- `GateBlockSnapshot.cs`/`GateStructure.cs`: add the two new properties.
- `WorldTaskService.TryApplyGateBlockScanResultAsync` (`WorldTaskService.cs:346-382`): currently always does `ClearBlockSnapshotsAsync(gateStructureId)` + `AddBlockSnapshotsAsync(...)` scoped only to `gateStructureId`. Read a new `scanState` key from the task's `InputJson` (defaulting to `CLOSED` for full backward compatibility with every existing single-scan gate), and scope both the clear and the add to `(gateStructureId, scanState)` instead of `gateStructureId` alone — so an OPEN scan never wipes the CLOSED rows, and vice versa.
- `GateStructureService`: `ClearBlockSnapshotsAsync`/`AddBlockSnapshotsAsync` gain a `SnapshotState` parameter.
- `GateStructuresController`: `GET /{id}/snapshots` gains an optional `?state=` query param, defaulting to `CLOSED` (preserves every existing caller's behavior unchanged, including `GateStructuresApi.getGateSnapshots` on the plugin side until it's updated in Phase C).

### Phase C — Plugin (knk-plugin-v2)

- `GateBlockScanTaskHandler.parseGateStructureId`-style parsing: also read an optional `scanState` from `InputJson` (default `"CLOSED"`).
- `buildScanWings`: when `scanState == "OPEN"`, use `gate.getOpenAnchorPoint()` as the wing's anchor instead of `gate.getAnchorPoint()`; `uStep`/`vStep`/`nStep` derivation from `ReferencePoint1`/`ReferencePoint2` is unchanged (same shape, different origin).
- `buildOutputJson`: include `scanState` in the output so `WorldTaskService` (Phase B) knows which discriminator to persist under.
- `GateStructuresApi.getGateSnapshots`: add a `state` parameter (or a second method) to fetch each state's rows independently.
- `GateLoaderAdapter.loadBlockSnapshots`: for a `DUAL_SCAN` gate, fetch both `CLOSED` and `OPEN` snapshot lists and pair them by `SortOrder` into `BlockSnapshot` objects carrying both `relativePosition` and `openRelativePosition` (null when no `OPEN` row shares that `SortOrder` — see Open Question 1).
- `CachedGate`/`BlockSnapshot`: add `animationDefinitionMode` and `openRelativePosition` fields respectively, following the existing getter/setter pattern used for `uStep`/`vStep`/`nStep` earlier this session.
- `GateFrameCalculator.calculateBlockPosition`: add the `DUAL_SCAN` branch described in Design above, decided per Open Question 1's outcome.

### Phase D — Frontend (knk-web-app)

- `FieldEditor.tsx` (`worldTaskType` dropdown, line 71 area): when `'GateBlockScan'` is selected, add a "Scan State" selector (Closed / Open) alongside the existing hint text (lines 1132-1135), stored on the field config.
- `WorldBoundFieldRenderer.tsx` (`handleCreateInMinecraft`, lines 413-434): thread the configured scan state into the created task's `inputJson` (`{ gateStructureId, scanState }`) alongside the existing `gateStructureId`.
- Gate creation/edit wizard: add a second `GateBlockScan`-typed field (state=Open) as its own wizard step, alongside the existing closed-state scan step, gated behind `AnimationDefinitionMode=DUAL_SCAN` being selected earlier in the wizard.
- `FormConfig`: add `AnimationDefinitionMode` and `OpenAnchorPointId` fields (the latter reusing whatever field type `AnchorPointId`/`ReferencePoint1Id` already use for location capture).

### Phase E — Docs & FormConfig descriptions

- Field descriptions for `AnimationDefinitionMode`, `OpenAnchorPointId`, and (per Open Question 2's resolution) revised descriptions for `GeometryHeight`/`MotionDistanceBlocks`/`ClipToGeometryBounds` clarifying their scope now that a second mode exists.
- Update `GATE_FORMCONFIG.md`'s requirement matrix with the two new fields.
- Update `REQUIREMENTS.md`/`SPEC.md` with the new mode once implemented, mirroring how PLANE_GRID/FLOOD_FILL are currently documented.

### Phase F — Pilot & validation

- Migrate gate #13 to `DUAL_SCAN` manually as the pilot: set `OpenAnchorPointId`, run both scans, verify the two-remaining-row open state renders correctly without touching `GeometryHeight` at all.
- Leave every other existing gate on `PROCEDURAL` — no forced migration.

---

## Testing strategy

- **Migration**: `Up()`/`Down()` round-trip test (existing repo convention, if one exists for prior gate migrations — otherwise add one).
- **Backend**: unit test that a `CLOSED`-scoped scan-result apply never touches `OPEN` rows for the same gate and vice versa (regression guard for the `TryApplyGateBlockScanResultAsync` scoping change).
- **Plugin**:
  - `GateBlockScanTaskHandler`: extend the existing `computeCellPosition`-style pure-function tests to cover scanning from `OpenAnchorPoint` producing the same relative-index shape as `AnchorPoint`, just world-shifted.
  - `GateLoaderAdapter`: test that `SortOrder`-based pairing correctly matches a closed row to its open counterpart, and correctly leaves `openRelativePosition` null when no `OPEN` row shares that `SortOrder`.
  - `GateFrameCalculatorTest`: new tests for the `DUAL_SCAN` branch — frame 0 equals closed position, frame=`AnimationDurationTicks` equals open position, midpoint equals `VectorMath.lerp` at `progress=0.5` (reuse the existing `shouldLerpBetweenVectors` expectations as a cross-check).
  - Regression test that a `PROCEDURAL`-mode gate's animation output is byte-for-byte unchanged before/after this feature lands (guards the "existing gates keep working" goal).

## Risks

- **`SortOrder` determinism.** Correlation entirely depends on both scan
  passes visiting cells in the same order. This already holds today (the
  triple-nested `i,j,k` loop in `ChunkedScanRunnable` is deterministic) — but
  any future change to the scan loop's iteration order would silently corrupt
  every `DUAL_SCAN` gate's pairing. Worth a code comment at the loop site once
  this lands, cross-referencing this doc.
- **Admin error**: an open-state scan built with a different block count than
  the closed one (e.g. extra decorative blocks added only when open) breaks
  the 1:1 `SortOrder` assumption. Recommend the scan-completion path validate
  that both states report the same cell count for a `DUAL_SCAN` gate and
  surface a clear warning (mirroring the existing tile-entity-not-captured
  warning pattern in `GateBlockScanTaskHandler`) rather than failing silently.
- **Scope creep into ROTATION/FLOOD_FILL.** Explicitly out of scope for v1;
  resist folding them in until PLANE_GRID VERTICAL/LATERAL dual-scan is
  proven on at least gate #13.
