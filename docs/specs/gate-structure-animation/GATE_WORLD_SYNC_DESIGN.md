# Gate World/DB Synchronization: Design & Implementation Plan

**Status:** Implemented (2026-09-10) — Phases 1-4 done; Phase 5 unit tests done,
manual/Phase-F-style live-server validation still outstanding (see Testing note below)
**Author:** Claude (plan requested by Pandi), 2026-09-10
**Related:** [ROTATION_GAP_FILL_DESIGN.md](ROTATION_GAP_FILL_DESIGN.md) (Phase C's
`GateRestingFramePlacer`/`GateStateSyncTask` work is where this gap was found and
is reused here), [SPEC.md](SPEC.md), [PHASE_STATUS.md](PHASE_STATUS.md)

---

## Context

Reported symptom: after a server restart, a gate's DB-persisted state (and the
in-memory `CachedGate.currentState` loaded from it) said `IsOpened=true`, but
the gate's physical world blocks were still in their closed position. Admins
and players could not toggle the gate or use pass-through, because those
systems correctly treat `CachedGate.currentState` (backed by the DB) as
authoritative and refused to re-open an "already open" gate - the *logical*
state was right; only the *physical* world never caught up to it.

### Root cause (confirmed by reading the code)

`GateStateSyncTask.reconcileWorldOnStartup()` already exists and is meant to
solve exactly this: once at boot, after gates are loaded, it force-places
every gate's blocks to match its loaded DB state. Two gaps make it unreliable
in practice:

1. **Chunk-not-loaded is a silent, permanent no-op.** `GateBlockPlacer.
   placeBlock`/`removeBlockIfMatches` check `world.isChunkLoaded(...)` and
   simply return `false` (a `LOGGER.fine`, not even a warning) if it isn't -
   they never force-load the chunk. At boot, only spawn-adjacent chunks are
   loaded (assuming no players are already online), so **any gate away from
   spawn has its startup reconciliation silently skipped**. There is no
   `ChunkLoadEvent` listener, no retry, no periodic re-check - the mismatch
   persists indefinitely, until an admin manually toggles that specific gate
   through a real open/close animation (which forces placement along the way).
2. **On-demand district loads never reconcile at all.** `DistrictGateLoader.
   loadIfNotAlreadyLoaded` -> `GateLoaderAdapter.loadForDistrict` (triggered
   the first time a player is resolved into a district this session) only
   caches the gate's data - it never calls anything equivalent to
   `reconcileGateWithWorld`. A gate loaded this way has *no* correction path
   at all, even if its chunk happens to be loaded at that moment.

### Decision (2026-09-10, Pandi): lean on district-load, not eager startup-fix

The originally-proposed fix (Phase C's write-up) was "force-load chunks and
fix everything at boot, spread across ticks." Pandi's explicit steer, which
this document now follows instead:

- Startup should **not** force-load any chunk or force-place any block. In a
  real deployment (not every gate near spawn, hundreds of gates across a
  large map) that does real, mostly-wasted work - loading/generating chunks
  for areas nobody is near yet, at the exact moment (boot) when the server is
  already busiest.
- The **district-load system is the natural, already-existing place to do
  this** instead: a district is only loaded (via `DistrictGateLoader`) the
  first time a player actually enters it, so any chunk-forcing work done at
  that point is inherently bounded to "this one district's gates" and
  triggered only when someone is actually about to be near them.
- Startup should still run a **diagnostic-only** pass: check whatever's
  already loaded (free - no forcing), log any mismatch found, and leave the
  fix to the district-load path. This gives operational visibility (a log
  line at boot saying "N gates found out of sync") without paying any
  eager-correction cost.
- A **periodic health-check** is also wanted, to catch drift introduced after
  a gate was already loaded and synced (e.g. an admin's WorldEdit session
  overwriting a gate's blocks, or a bug elsewhere corrupting one) - the
  district-load and startup mechanisms only ever check a gate once, at load
  time. This must be built with the same "no unbounded cost as gate count
  grows" discipline as everything else here.

---

## Goals

- A gate's physical world blocks eventually converge to its DB-authoritative
  state without requiring an admin to manually toggle it.
- **Never force-load or generate a chunk nobody is near** just to check or
  fix a gate - all correction work is triggered by, and bounded to, a
  district a player has actually just entered.
- Cheap, scale-safe checks: O(1) or O(district size) per triggering event,
  never O(total gate count) on a hot path, and zero ongoing cost while idle.
- Startup produces a diagnostic log of out-of-sync gates but does not act -
  correction is left entirely to the district-load path.
- An ongoing periodic health-check catches drift introduced after initial
  load, built to the same performance discipline (see Goals above) so its
  cost does not grow unbounded as the server's gate count grows.

## Non-goals (v1)

- Guaranteeing a gate in a district **no player ever visits in a session**
  gets corrected at all that session. Acceptable: nobody will ever observe
  the mismatch either, and the moment someone does visit, the district-load
  path fixes it.
- A live `ChunkLoadEvent`-driven system that reacts to *any* chunk load
  anywhere (e.g. another plugin pre-loading chunks, a player flying through
  on an elytra past a district they're not "in"). District-load is the
  chosen trigger; a raw per-chunk listener is a possible future refinement,
  not needed for this plan (see Risks).
- Changing the "DB wins" precedence itself. That part already works
  correctly today (`CachedGate.currentState`, loaded from the DB, is what
  toggle/pass-through/etc. already check) - this plan is entirely about
  making the *physical world* reliably catch up to it, not about changing
  who wins when they disagree.

---

## Design: three complementary mechanisms

```
gate loading path                  | sync behavior
------------------------------------|--------------------------------------
startup (loadAll)                   | diagnose only (log mismatches), never
                                     | force a chunk load or a block write
district entered for the first time | check + fix, force-loading each gate's
(loadForDistrict)                   | own chunk(s) only if needed
periodic timer (already-loaded      | check + fix already-loaded, already-
gates only)                         | cached gates only; never forces a load
```

All three share one primitive: **"does this gate's resting-frame footprint
match the physical world, and if not, fix it"** - built once, reused
everywhere, exactly the way `GateRestingFramePlacer` (Phase C, `ROTATION_
GAP_FILL_DESIGN.md`) already unifies "what should this gate's resting frame
look like" for `GateAnimationTask` and `GateStateSyncTask`.

### Shared primitive: `GateWorldSyncChecker` (new)

A small class alongside `GateRestingFramePlacer` with two pure-ish entry
points (the read is Bukkit-coupled - it reads live blocks - but does not
mutate anything):

```java
/** Read-only: does the gate's resting frame already match the physical world? */
static SyncResult check(World world, CachedGate gate, boolean rasterizationEnabled);

record SyncResult(boolean inSync, int mismatchedCellCount, int totalCellCount) {}
```

- Only ever called for a gate in a **resting** state (`CLOSED` or `OPEN`,
  never `OPENING`/`CLOSING`) - an animating gate's blocks are expected to be
  mid-transit, not resting-frame-shaped, and `GateAnimationTask` already
  owns placement for it every tick.
- Built on `GateRestingFramePlacer.restingFrameCells` (already exists,
  Phase C): compute the expected `(position, blockData)` set once, then read
  each position's actual block and compare material/blockdata. Cheap in the
  common (in-sync) case - it's a handful to a few dozen block reads per gate,
  no writes.
- `check()` never touches chunk-loading - callers are responsible for
  ensuring the chunk they want checked is already loaded (see each mechanism
  below); a position in an unloaded chunk is treated as "cannot determine,
  skip" (not counted as a mismatch), matching Bukkit's own behavior of
  returning an unloaded/empty snapshot for such reads.
- A separate `fix(World world, CachedGate gate, boolean rasterizationEnabled)`
  simply calls `GateRestingFramePlacer.placeRestingFrame` (unconditionally -
  no reason to re-diff cell-by-cell before writing, since the write path is
  already idempotent/cheap for an already-correct gate, per Phase C's design).

### Mechanism A — Startup: diagnose only, never fix

Replaces `GateStateSyncTask.reconcileWorldOnStartup`'s current
force-correct behavior:

1. After `gateManager.reloadGates()` completes (same trigger point as today),
   iterate every cached, non-destroyed, resting-state gate.
2. For each, check `world.isChunkLoaded(...)` for its relevant cell(s) -
   **do not force-load**. If not loaded, skip silently (it will be checked
   the first time its district is entered - Mechanism B).
3. For gates whose chunk *is* already loaded (spawn-adjacent gates, or any
   world where spawn chunks happen to include them), run `GateWorldSyncChecker.
   check(...)` and log a `WARNING` per mismatched gate (id, name, expected vs.
   observed state) - but do **not** call `fix()`.
4. Emit one summary `INFO` line: `"Startup gate sync check: X gate(s)
   verified, Y mismatch(es) found (see warnings above), Z gate(s) skipped
   (chunk not loaded - will be checked when their district is next
   entered)."`

Cost: bounded by however many gates happen to sit in already-loaded chunks
at boot (typically a small, spawn-adjacent subset) - zero forced I/O, no
chunk generation, no per-tick work needed since there's nothing to spread out.

### Mechanism B — District-load: check and fix (primary correction path)

Extends `GateLoaderAdapter.loadForDistrict` (called by `DistrictGateLoader.
loadIfNotAlreadyLoaded` the first time a player enters a district this
session):

1. After a district's gates finish loading and caching (today's existing
   behavior, unchanged), for each of that district's gates:
   - Skip if destroyed or currently animating (`OPENING`/`CLOSING`) - nothing
     to reconcile, `GateAnimationTask` already owns it.
   - Force-load its relevant chunk(s) via Paper's `World#getChunkAtAsync(x,
     z)` (available in this API version; not currently used anywhere in the
     codebase, but the correct tool here - loads, generating if necessary,
     without blocking/hitching the main thread the way a synchronous
     `getChunkAt` would).
   - Once the chunk future completes, hop back onto the main thread (Bukkit
     block access requires it) and run `GateWorldSyncChecker.check(...)`;
     if not in sync, call `fix(...)` and log an `INFO` line noting the
     correction (gate id/name, mismatched cell count) - this is exactly the
     "N gates found out of sync at startup" gates finally getting fixed,
     now attributed to the district-load event that triggered the fix.
2. Bounded, predictable cost: the number of chunks force-loaded per
   district-entry event is however many distinct chunks that *specific*
   district's gates occupy - not the server's total gate count, and not the
   whole district's terrain, just the handful of cells each gate's footprint
   touches. Districts are an admin-curated concept already used as the
   loading boundary for gate *data* (this reuses that same boundary for gate
   *world-sync*, rather than introducing a second "which chunks matter"
   concept).
3. This event is inherently rare (once per district per session, per
   `DistrictGateLoader`'s existing "no re-eviction" model) - no batching/
   ticking is needed here even at scale, since it never fires per-tick or
   per-gate-count, only per-district-first-visit.

### Mechanism C — Periodic health-check (ongoing drift detection)

A new lightweight periodic task, structurally similar to the existing
`GateStateSyncTask`'s DB-persistence timer:

1. Runs on a configurable interval (e.g. every 5 minutes) and, each run,
   processes a **budgeted batch** of gates (e.g. 10-20 per run, configurable)
   rather than the whole gate population at once - spreads cost across
   multiple runs as gate count grows, the same discipline `GateBlockScanTaskHandler`'s
   `ChunkedScanRunnable`/`FloodFillScanRunnable` already use for per-tick
   budgets during a scan.
2. Only considers gates that are **already loaded in a currently-loaded
   chunk** (a cheap `isChunkLoaded` check) - never forces a chunk load. This
   keeps the check's cost tied to "how much of the map currently has players
   near gates," not total gate count - the same "only touch what's already
   being observed" principle as Mechanism A, just recurring instead of
   one-shot.
3. For each candidate gate: `GateWorldSyncChecker.check(...)`; if mismatched,
   `fix(...)` and log (gate id/name, mismatch detail) - this path *does* self-
   heal (unlike Mechanism A), since it's the only mechanism that ever
   revisits an already-synced gate, so it's the only place that can catch
   later drift (WorldEdit tampering, a bug elsewhere) at all.
4. Round-robins which gates get checked each run (e.g. track a cursor/offset
   into the currently-loaded-and-cached gate list) so that, over enough runs,
   every currently-relevant gate eventually gets checked, without ever
   scanning the full list in one run.
5. Explicitly skips any gate that is `OPENING`/`CLOSING` (owned by
   `GateAnimationTask`, not resting) or mid-pass-through, to avoid fighting
   legitimate in-progress state.

---

## Design decisions (proposed, pending review)

**1. Startup diagnoses, district-load fixes — decided (2026-09-10, Pandi's steer).**
See Context above. Rationale: bounds all forced chunk-loading work to
"a district a player is actually entering," which scales with player
activity, not total server gate count.

**2. District, not raw chunk, is the fix-trigger boundary — decided.**
Reuses the existing `DistrictGateLoader` concept (already the boundary for
*loading gate data* on demand) as the boundary for *fixing gate world state*
too, rather than introducing a second, redundant "which chunks matter"
concept via a raw `ChunkLoadEvent` listener. See Risks for when this might
need revisiting.

**3. Periodic health-check self-heals; startup does not — decided, for now.**
The periodic check is the only mechanism that ever revisits an
already-loaded gate, so it needs to actually fix what it finds, or drift
introduced after initial load/district-sync would never be corrected at
all. If this turns out to cause churn (repeatedly "fixing" a location an
admin legitimately repurposed), revisit toward diagnostic-only + an admin
command to accept the new state, same as Mechanism A.

**4. Force-loading a chunk uses async (`getChunkAtAsync`), not sync
`getChunkAt` — decided.** Available in this Paper API version; avoids a
main-thread hitch for chunk generation during Mechanism B, which is the only
mechanism allowed to force a load at all.

**5. `GateWorldSyncChecker` is a new, shared read/fix primitive, not
duplicated per mechanism — decided.** All three mechanisms need the exact
same "does this match, and if not, fix it" logic; building it once (on top
of Phase C's already-existing `GateRestingFramePlacer`) keeps the actual
placement/rasterization/pairing logic in exactly one place, consistent with
how `GateAnimationTask` and `GateStateSyncTask` already share it.

---

## Implementation (2026-09-10)

### Phase 1 — `GateWorldSyncChecker` (knk-plugin, `knk-paper`) — **Done**

- New class alongside `GateRestingFramePlacer`: `check(world, gate,
  fallbackMaterial, rasterizationEnabled)` (read-only, returns `SyncResult`)
  and `fix(world, gate, fallbackMaterial, rasterizationEnabled)` (delegates
  to `GateRestingFramePlacer.placeRestingFrame`). `fallbackMaterial` was
  added to the signature beyond this doc's original sketch, since expected
  blockdata parsing (`GateBlockPlacer.parseBlockData`) already needs one for
  consistency with every other placement/removal call site.
- `SyncResult(inSync, mismatchedCellCount, totalCellCount, uncheckedCellCount)`
  plus a `fullyUnchecked()` helper (`uncheckedCellCount >= totalCellCount`) -
  used by all three mechanisms to distinguish "verified and matched",
  "verified and mismatched", and "couldn't verify at all right now" (Mechanisms
  A/C never force a chunk load, so a gate can land in that third bucket).
- `check()` built on `GateRestingFramePlacer.restingFrameCells`: for each
  expected cell, calls a new `GateBlockPlacer.blockMatches(world, position,
  expectedBlockData, fallbackMaterial)` - a read-only tri-state helper
  (`null` = chunk not loaded/unparseable, cannot determine) added alongside
  the existing `placeBlockIfVacant`/`removeBlockIfMatches` - and accumulates
  a mismatch count. Never mutates the world.
- `restingFrame(CachedGate)` (package-visible): resolves a resting gate's
  `CLOSED`/`OPEN` state to frame 0 or `totalFrames` - shared by `check()`,
  `fix()`, and `GateStateSyncTask`'s chunk-resolution step (Mechanism B).
- Tested: `restingFrame`'s pure CLOSED/OPEN → frame mapping
  (`GateWorldSyncCheckerTest`). `check()`/`fix()`'s live-block-comparison
  path needs a loaded `World` and is scoped to manual/Phase-F-style
  verification, matching this repo's existing convention for that class of
  test (see `GateBlockScanTaskHandlerTest`'s own note, and Phase C's
  `GateRestingFramePlacerTest` hitting the same `GateBlockOrientation.
  applyRotation` → `Bukkit.createBlockData` constraint).

### Phase 2 — Startup diagnostic pass — **Done**

- `GateStateSyncTask.reconcileWorldOnStartup()` replaced outright by
  `logStartupSyncDiagnostics()`: iterates every eligible (non-destroyed,
  resting) gate, resolves its world, and calls `GateWorldSyncChecker.check`
  - skipping (not logging as a mismatch) any gate whose result is
  `fullyUnchecked()` (nothing loaded yet). Logs a `WARNING` per mismatched
  gate and one `INFO` summary line (verified/mismatched/skipped counts).
  Never calls `fix()` - purely diagnostic, per Decision 1.
- `KnKPlugin`'s post-`reloadGates()` callback updated to call
  `logStartupSyncDiagnostics()` instead of the old method name.
- No new config; this does strictly less work than the code it replaced (a
  read-only check instead of a check-and-force-write pass).

### Phase 3 — District-load check-and-fix — **Done**

- `GateLoaderAdapter.loadForDistrict` now returns
  `CompletableFuture<List<Integer>>` (the ids of gates it actually cached)
  instead of `CompletableFuture<Void>` - the minimal change needed for a
  caller to know which gates to run Mechanism B against, without a second,
  redundant API round-trip.
- `GateStateSyncTask.checkAndFixGates(Collection<Integer> gateIds)` (new,
  public): hops onto the main thread, then per eligible gate collects the
  distinct chunk coordinates its `restingFrameCells` touch, force-loads all
  of them via `World#getChunkAtAsync` (parallel, non-blocking), and once
  every chunk future for that gate completes, hops back onto the main
  thread and runs `check`/`fix`. A gate spanning multiple chunks is handled
  naturally (all its chunks are loaded before checking), not just single-chunk
  gates.
- `DistrictGateLoader` gained a `GateStateSyncTask` constructor dependency
  and now calls `checkAndFixGates` on the ids `loadForDistrict` returns,
  both from `loadIfNotAlreadyLoaded` (the normal on-demand-entry path) and
  `forceReload` (admin-triggered re-load, so an edited gate's new geometry
  is verified immediately rather than waiting for the next health-check pass).
- `KnKPlugin`: `GateStateSyncTask` is now constructed *before*
  `DistrictGateLoader` (previously the reverse), so it can be passed in.

### Phase 4 — Periodic health-check task — **Done**

- Extended `GateStateSyncTask` itself with a second timer (rather than a new
  sibling class - Decision 5's "one shared coordinator" already put all
  sync orchestration here) via new constructor parameters
  `healthCheckIntervalSeconds`/`healthCheckBatchSize` (existing 5- and
  6-argument constructors delegate with defaults `300`/`15`, so no other
  caller needed updating).
- `start()` now also starts a `runTaskTimer` (main thread, not async - it
  touches Bukkit block state directly) running `runHealthCheckBatch`;
  `stop()` cancels both timers.
- `runHealthCheckBatch`: snapshots and sorts the currently-cached gate ids
  (a stable order independent of `HashMap` iteration/rehashing), computes
  this run's batch via a new pure static helper `selectRoundRobinBatch
  (totalCount, cursor, batchSize)`, and for each selected id calls
  `checkAndFixGateIfAlreadyLoaded` - which, unlike Mechanism B's
  `checkAndFixGate`, never force-loads a chunk: a gate that's
  `fullyUnchecked()` right now is simply left for a later run (or Mechanism
  B, if its district gets (re)entered first).
- New config keys `gates.world-sync.health-check-interval-seconds` (default
  `300`) and `gates.world-sync.health-check-batch-size` (default `15`),
  read once in `KnKPlugin` and passed to `GateStateSyncTask`'s constructor.

### Phase 5 — Testing — **Unit tests done; live-server validation outstanding**

- `GateStateSyncTaskRoundRobinTest`: `selectRoundRobinBatch` extracted as a
  pure, Bukkit-free static method specifically so the wraparound/cursor
  logic could be tested directly (consecutive batch, wrap-around, batch
  larger than total, cursor exactly at the end, a defensively-handled
  negative cursor, and a full multi-run sweep asserting every index is
  visited exactly once) - this is the part of Mechanism C with real
  off-by-one risk; the surrounding `runHealthCheckBatch`/`checkAndFixGateIfAlreadyLoaded`
  wiring is thin enough to review by inspection.
- `GateWorldSyncCheckerTest`: `restingFrame`'s CLOSED→0 / OPEN→totalFrames mapping.
- `DistrictGateLoaderTest`: extended with two new cases confirming
  `checkAndFixGates` is called with exactly the ids `loadForDistrict`
  returned, for both `loadIfNotAlreadyLoaded` and `forceReload`.
- Verified: full multi-module build succeeds; 346 tests pass across
  `knk-core`/`knk-api-client`/`knk-paper` (110 + 26 + 210, 12 pre-existing
  skips unrelated to this work), no new failures.
- **Not yet done**: the manual/Phase-F-style validation this doc's Phase 5
  originally called for (force a gate out of sync via WorldEdit or a direct
  DB edit; confirm startup only logs it, entering its district fixes it and
  logs the correction, and the periodic task catches drift introduced after
  that) needs a live server and hasn't been run yet.

---

## Edge cases

- **A gate whose district covers a huge area with gates far from the
  player's entry point**: Mechanism B still force-loads each of that
  district's gates' own chunks individually (not the district's whole
  bounding box) - cost is proportional to gate count in the district, not
  its geographic size.
- **A destroyed gate**: skip in all three mechanisms - its blocks are
  deliberately absent, there is nothing to reconcile until it respawns
  (`HealthSystem` already owns that transition and places blocks itself).
- **A gate mid-animation at the moment its district loads or a health-check
  cycle reaches it**: skip (only resting `CLOSED`/`OPEN` states are
  reconciled) - `GateAnimationTask` already owns correctness for an
  animating gate every tick.
- **Two players entering the same never-before-loaded district
  simultaneously**: `DistrictGateLoader.loadedDistrictIds` already guards
  against double-loading (`ConcurrentHashMap.newKeySet().add` returns false
  for the second caller) - Mechanism B rides that same guard, so the
  check-and-fix pass still only runs once.
- **A gate whose OpenAnchorPoint/geometry was edited after being loaded this
  session**: `DistrictGateLoader.forceReload` already exists for this
  (admin-triggered); Phase 3 explicitly re-runs the sync check there too, so
  an edited gate's new expected footprint gets verified against the world
  immediately rather than waiting for the next periodic cycle.
- **Rasterized (Mechanism-1, `ROTATION_GAP_FILL_DESIGN.md`) gates**:
  `GateWorldSyncChecker` uses `GateRestingFramePlacer.restingFrameCells`
  unchanged, which already produces the correct (rasterized or paired)
  expected-cell set - no special-casing needed here, this feature composes
  with rotation gap-fill for free.

## Risks

- **District boundaries might not align with "chunks a player can actually
  see."** A very large district could have a gate whose chunk isn't
  actually near where the player entered, so Mechanism B still force-loads
  a chunk nobody's looking at yet (though at least it's bounded to that one
  district, and only once per district per session). If this proves costly
  in practice, a future refinement could narrow the trigger to "player's
  current chunk plus a small radius" instead of "every gate in the
  district," at the cost of needing an additional trigger (e.g. periodic
  proximity check) for gates never quite gotten close enough to.
- **Periodic self-healing could fight a legitimate world change.** If an
  admin intentionally rebuilds over/removes a gate's blocks without going
  through the API (e.g. decommissioning it in the world before deleting the
  `GateStructure` record), the periodic check would keep "fixing" it back
  until the DB record is actually deleted. Mitigation: the periodic task
  should log every correction it makes, so this shows up as a repeating log
  line an admin can notice and investigate, and Decision 3 already flags the
  fallback to diagnostic-only if this becomes a real problem.
- **`World#getChunkAtAsync` still has a real (if async, non-blocking) cost**
  for a chunk that needs generating from scratch. Bounded per-district, but
  a district with many gates scattered across ungenerated terrain could
  still take a few seconds to fully settle after first entry - acceptable
  (it's async, doesn't block the player or the server), but worth measuring
  once implemented.
