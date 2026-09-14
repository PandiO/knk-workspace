# Gate Animation System - Phase Status

**Last Updated**: 2026-09-05

| Phase | Focus | Status | Notes |
| --- | --- | --- | --- |
| 1 | Backend Data Model | ✅ Complete | GateStructure + GateBlockSnapshot entity/migration already in place. |
| 2 | Backend Logic (Repository, Service, DTOs) | ✅ Complete | Added read/create/update/nav DTOs, snapshot create DTO, mapping, and service overloads; added unit tests. |
| 3 | Backend API (Controller & Endpoints) | ✅ Complete | Gate API routes, validation, state/snapshot endpoints, and controller tests added. |
| 4 | Frontend Types & API Client | ✅ Complete | Gate DTOs extended, snapshot DTOs added, gate client expanded, unit tests added. |
| 5 | Frontend UI Configuration | ✅ Complete | GateStructureConfig defined with 20 fields; entity routing registered; uses generic FormWizardPage/DisplayWizard (no custom pages). |
| 6 | Plugin Core (API Client, Cache, Loader) | ✅ Complete | Gate loader adapter caches gates from API; animation data precomputed; startup load wired. |
| 7 | Plugin Animation Engine | ✅ Complete | Frame calculator, block placement, animation task, state machine, lag/chunk handling implemented. |
| 8 | Plugin Entity Interaction | ✅ Complete | Collision prediction + entity push integration added with unit tests. |
| 9 | Plugin Commands & Events | ✅ Complete | Player/admin commands (9.1, 9.2) were already implemented in GateCommand and wired into /knk gate via KnkAdminCommand's CommandRegistry, with permission nodes (9.4) already in plugin.yml. Event wiring (9.3) completed this pass: BlockBreakEvent, PlayerInteractEvent (left/right-click split), ProjectileHitEvent, EntityExplodeEvent, and BlockExplodeEvent now resolve hits via an O(1) spatial index and route through Cancellable GateDoorInteractEvent/GateDoorDamageEvent custom events, with damage consequence handling separated into GateDamageConsequenceListener. |
| 10 | WorldGuard & Health System | ✅ Complete | WorldGuard flags applied on state changes; health/damage/respawn logic implemented and persisted. Continuous damage (fire) system added: see Phase 10 addendum below - this was listed as a Phase 9/10 deliverable in REQUIREMENTS.md but had not actually been implemented until this pass. |
| 11 | Testing & Optimization | 🔶 Partial | 11.3 (Plugin Unit Tests): coordinate parsing, frame-to-position (linear + rotation), collision prediction, and entity push direction were already covered; this pass closed the two remaining gaps - a diagonal (non-axis-aligned) basis-vector test and a default-axes-fallback test for GateLoaderAdapter (the roadmap's Risk Management section flags diagonal geometry as high-risk), and strengthened the rotation frame test from assertNotEquals to exact expected values. 11.1/11.2 (backend .NET / frontend unit tests), 11.4 (integration), 11.5/11.6 (in-game functional and TPS/load testing), 11.7 (edge cases), and 11.8 (profiling/optimization) still need a live server/stack and are not started. |

## Phase 5 Implementation Details

**Approach**: Configuration-driven UI (KnK Generic Framework Pattern)
- **No custom components**: Uses existing FormWizardPage and DisplayWizard
- **No custom pages**: Uses existing PagedEntityTable for listings
- **Configuration only**: ObjectConfig + EntityMapping registration

**Workflows**:
- **Create**: POST `/forms/gatestructure` → FormWizardPage renders from GateStructureConfig
- **Edit**: PUT `/forms/gatestructure/edit/:id` → FormWizardPage renders from GateStructureConfig
- **View**: GET `/display/gatestructure/:id` → DisplayWizard renders entity
- **List**: GET `/` → PagedEntityTable with columnDefinitionsRegistry.gatestructure

**Files Modified**:
- `src/config/objectConfigs.tsx`: Added GateStructureConfig (20 fields) + columnDefinitionsRegistry entry
- `src/utils/entityApiMapping.ts`: Registered gatestructure in all 5 CRUD functions
- `docs/features/gate-structure-animation/PHASE_5_COMMIT_MESSAGES.md`: Commit history

## Phase 9 Implementation Details (Event Wiring, section 9.3)

**Approach**: O(1) spatial-index lookup + Cancellable custom events, replacing the prior
per-event O(gates x blocks) linear scan (`findGateContainingBlock`).

- **Detection**: `GateSpatialIndex` (knk-core) maps `world -> packed block coord -> gateId`
  for every gate's animated door blocks, updated incrementally by `GateAnimationTask` during
  animation and by `HealthSystem` on destroy/respawn - never a separate pass, so the index
  can't drift from the blocks actually placed in the world.
- **Events**: `GateDoorInteractEvent` (right-click) and `GateDoorDamageEvent` (left-click,
  arrow, explosion, block-break) are new `Cancellable` Bukkit events fired by
  `GateDoorHitService`, which also gates on gate state (closed/active/not destroyed) so
  detection stays independent of consequence.
- **Consequence**: `GateDamageConsequenceListener` owns the per-cause damage amount and calls
  `HealthSystem.applyDamage`, replacing the inline damage calls previously duplicated across
  `GateEventListener`'s block-break and explosion handlers.
- **Bug fix**: `HealthSystem.destroyGate()` now captures the gate's animation frame before
  resetting state, fixing a case where destroying a gate while `OPEN` or mid-animation left
  its actually-visible blocks in the world instead of removing them.

**Note**: 9.1, 9.2, and 9.4 were already complete going into this pass (`GateCommand` +
`KnkAdminCommand` registry + `plugin.yml` permissions) - only 9.3 needed work, so this
closes out Phase 9 entirely.

**Files Added/Modified** (`knk-plugin`, this pass - 9.3 only):
- `knk-core/.../gates/GateSpatialIndex.java` (new), `GateManager.java` (index ownership)
- `knk-paper/.../events/GateDoorInteractEvent.java`, `GateDoorDamageEvent.java` (new)
- `knk-paper/.../gates/GateDoorHitService.java` (new), `GateAnimationTask.java`,
  `HealthSystem.java`
- `knk-paper/.../listeners/GateEventListener.java` (refactored),
  `GateDamageConsequenceListener.java` (new)
- `KnKPlugin.java`: registration wiring
- Tests: `GateSpatialIndexTest`, `GateManagerTest`, `GateDoorHitServiceTest`,
  `GateDamageConsequenceListenerTest`, updated `GateEventListenerTest`/`HealthSystemTest`

## Phase 10 Addendum (Continuous Damage / Fire System)

**Gap found**: REQUIREMENTS.md lists "Continuous damage system (fire effects, damage-over-time)"
as a Paper plugin deliverable, but no fire/burn/DOT mechanic existed anywhere in the gates code -
only discrete hit damage (`GateDoorDamageEvent` causes: LEFT_CLICK, PROJECTILE, EXPLOSION,
BLOCK_BREAK, each a flat one-shot amount via `GateDamageConsequenceListener`).

**What was added**: a gate door block hit by a flaming projectile (an arrow with the Flame
enchantment, or one that flew through fire/lava - `Entity.getFireTicks() > 0`) or a fire charge
(`SmallFireball`) now catches fire and burns for a configurable duration, dealing
damage-over-time to the owning gate's `HealthCurrent` for every block still burning each tick
(so several burning blocks stack damage).

- **Detection**: `GateEventListener.onProjectileHit` (extended) resolves an ignite cause and
  calls the new `GateDoorHitService.handleIgnite`, which fires a new cancellable
  `GateDoorIgniteEvent` under the same closed/active/not-destroyed qualification as
  `handleDamage` (a door block only has a stable world position - the thing that "burns" - while
  CLOSED).
- **Consequence**: `GateDamageConsequenceListener` (now also constructed with a `GateFireSystem`)
  reacts to `GateDoorIgniteEvent` by calling `GateFireSystem.igniteBlock`, which records a
  fire-expiry timestamp per world block position on the gate (`CachedGate.burningBlocks`) and
  plays an immediate particle/sound effect.
- **Damage-over-time tick**: a new `GateFireDamageTask` (thin `BukkitRunnable`, interval
  `gates.fire-tick-interval-seconds`, default 1s) calls `GateFireSystem.tick()`, which prunes
  expired burns, applies `gates.fire-damage-per-tick` x still-burning-block-count damage via a
  new `HealthSystem.applyContinuousDamage`, and extinguishes a gate's fire if it stops qualifying
  (destroyed, inactive, or no longer CLOSED - e.g. it started opening mid-burn).
- **Data retention vs. performance balance** (explicit requirement): `applyContinuousDamage`
  deliberately does NOT persist to the API on every tick, unlike `applyDamage`. The in-memory
  `HealthCurrent` updates immediately (so the 1s-refreshed health display stays live and the
  destroy check is accurate), but the DB write is left to the existing
  `GateStateSyncTask`/`state-sync-interval-seconds` periodic sweep (default 120s) - or happens
  immediately if a tick's damage destroys the gate (`destroyGate` already persists). This avoids
  one API call per burning gate per second during a large siege.
- **Config**: new `gates.fire-duration-seconds` (8), `gates.fire-damage-per-tick` (2.0),
  `gates.fire-tick-interval-seconds` (1) keys in `config.yml`.
- **Flint and steel follow-up fix**: vanilla `BlockIgniteEvent` for FLINT_AND_STEEL (and
  FIREBALL) targets the AIR block adjacent to the face clicked/hit, not the block itself - so
  lighting a gate door block with flint and steel was setting the block *next to* it on fire
  instead. `GateEventListener.onBlockIgnite` now detects this (the ignited block itself, or one
  of its 6 neighbors, resolving to a gate door block via `GateDoorHitService`), cancels the
  vanilla placement, and redirects the ignition onto the actual door block through the same
  `GateDoorIgniteEvent` -> `GateFireSystem.igniteBlock` path as a direct hit. Added
  `GateDoorIgniteEvent.Cause.FLINT_AND_STEEL`.

**Files Added/Modified** (`knk-plugin`, this pass):
- `knk-core/.../domain/gates/CachedGate.java`: `burningBlocks` map + `isOnFire()`
- `knk-paper/.../events/GateDoorIgniteEvent.java` (new; causes FLAMING_PROJECTILE, FIRE_CHARGE,
  FLINT_AND_STEEL)
- `knk-paper/.../gates/GateFireSystem.java` (new), `GateFireDamageTask.java` (new)
- `knk-paper/.../gates/GateDoorHitService.java`: `handleIgnite`
- `knk-paper/.../gates/HealthSystem.java`: `applyContinuousDamage`
- `knk-paper/.../listeners/GateEventListener.java`: ignite-cause detection on projectile hits
  and on `BlockIgniteEvent` (flint and steel / fireball adjacent-block redirect)
- `knk-paper/.../listeners/GateDamageConsequenceListener.java`: `GateDoorIgniteEvent` handling
- `KnKPlugin.java`: wiring; `config.yml`: new `gates.fire-*` keys
- Tests: `GateFireSystemTest` (new), plus additions to `HealthSystemTest`,
  `GateDoorHitServiceTest`, `GateEventListenerTest`, `GateDamageConsequenceListenerTest`

## Phase 11 Implementation Details (Plugin Unit Test Gaps, section 11.3)

**Scope of this pass**: 11.3 only, and only the two items not already covered - the rest of
Phase 11 (11.1, 11.2, 11.4-11.8) needs a live Minecraft server and/or the web app/API stack
running, which isn't something achievable as a code-only change.

- **Diagonal basis-vector test** (`GateLoaderAdapterTest.
  loadAndCacheGate_ComputesBasisVectorsForDiagonalFaceDirection`): the existing basis-vector
  test only used axis-aligned reference points (u=(1,0,0), v=(0,1,0)), which trivially
  produces n=(0,0,1) regardless of whether the cross-product's sign or operand order is
  correct. The new test uses a diagonal reference point (1,0,1) so a sign/order bug in
  `precomputeBasisVectors` would actually be caught - this is the exact risk the roadmap's
  Risk Management section calls out as "Diagonal Gate Geometry Calculation".
- **Default-axes fallback test** (`loadAndCacheGate_FallsBackToDefaultAxesWhenReferencePointsMissing`):
  covers the previously-untested branch where `referencePoint1`/`referencePoint2` are absent.
- **Rotation frame test strengthened** (`GateFrameCalculatorTest.shouldCalculateRotationPosition`):
  replaced `assertNotEquals` with the exact expected position computed from Rodrigues' formula.
  Lower priority than the above since the underlying `VectorMath.rotateAroundAxis` primitive
  already has thorough, exact-value tests in `VectorMathTest`.

**Still outstanding for Phase 11**: 11.1 (.NET backend unit tests, different repo/stack),
11.2 (frontend unit tests), 11.4 (integration across web app/API/plugin), 11.5 (in-game
functional test cases TC-001..TC-006), 11.6 (TPS/load testing, TC-101..TC-103), 11.7 (edge
cases TC-201..TC-204), 11.8 (profiling/optimization). All require a live server or multi-service
stack rather than unit-test-level code changes.

**Files Modified** (`knk-plugin`, this pass - 11.3 only):
- `knk-paper/.../gates/GateLoaderAdapterTest.java`: 2 new tests
- `knk-core/.../gates/GateFrameCalculatorTest.java`: 1 test strengthened
