# Gate Structures — System & Mechanics Design

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-10-23 (§4 jamming on a door's own blocks, KNG-272; §9 `POST api/GateDoors/search`, KNG-273; §10 open-scan gaps) — earlier: 2026-10-22 (§5 gate damage visuals, held-item melee damage and enchantment interplay; rest based on a full read-only code scan of `knk-web-api` `master`@`76644fe`, `knk-plugin` `main`@`e6e428b`, `knk-web-app` `main`@`4ff5dc6`, immediately after the `gate-structure-animation`/`gate-animation`/`gate-animation-2` branches were fast-forward merged into each repo's default branch)
**Companion docs:** `docs/guides/developer/gate-structures-developer-guide.md` (implementation), `docs/guides/admin/gate-structures-admin-guide.md` (config/commands), `docs/guides/users/gate-structures-player-guide.md` (player-facing), `docs/specs/gate-structure-animation/` (the full design-history trail this doc summarizes into current-state form)

Gate structures are the siege-game's gates/drawbridges/portcullises — animated, damageable, destructible world objects that block or allow passage through a wall, and (per the vision doc) form the primary objective of the Siege minigame. This doc describes the feature **as it currently exists**, not as a changelog of how it got there — see `docs/reports/gate-structure-merge-2026-09-21.md` for what the 2026-09-21 merge specifically added, and `docs/specs/gate-structure-animation/` for the decision-by-decision history.

---

## 1. Structure / Door model

A **GateStructure** is the addressable, siege-relevant entity (like a building: it has a street, house number, district). A GateStructure owns one or more **GateDoor**s — the actual animated, damageable objects. This split (introduced by "item 5" of the QOL implementation plan) exists because a real gate can have multiple independently-animating leaves (e.g. a double door, or a structure with both a main gate and a side postern) that should share one siege-relevant identity but animate/take damage independently.

- **GateStructure** (`knk-web-api` `Models/GateStructure.cs`, `knk-plugin` `CachedGateStructure`): identity, address (street/district/house number, inherited via `Structure`/`Domain`), icon, **guard & defense fields** (`GuardSpawnLocations`, `GuardCount`, `GuardNpcTemplateId` — **explicitly a future feature**, no guard-spawning logic exists in the plugin yet), **siege integration fields** (`IsOverridable`, `AnimateDuringSiege`, `CurrentSiegeId`, `IsSiegeObjective` — also currently unconsumed; no `Siege` entity exists yet anywhere in either repo), and 14 **cascading override** fields (§2).
- **GateDoor**: everything gameplay-visible — health, animation config, geometry, display config, damage/pass-through config, and the two block-snapshot collections (closed-state and open-state scans). Door names are unique within their parent structure, not globally.

A door is selected in-game either by a bare id/name (when unambiguous) or the two-level `<structure> <door>` form.

## 2. Cascading structure-level overrides

14 fields exist on **both** GateStructure (as `<Field>Override`, nullable) and GateDoor (as the field itself): `IsActive`, `CanRespawn`, `IsDestroyed`, `IsInvincible`, `OpenedState`, `AllowPassThrough`, `PassThroughDurationSeconds`, `ShowHealthDisplay`, `HealthDisplayMode`, `HealthDisplayYOffset`, `GateNameDisplayMode`, `StatusDisplayMode`, `AllowContinuousDamage`, `ContinuousDamageMultiplier`.

Resolution is **read-time, not write-cascade**: `structureOverride ?? doorOwnValue`. On the backend this is `GateDoor.GetEffective<T>`; on the plugin it's a family of `isEffectivelyXxx()`/`getEffectiveXxx()` accessors on `CachedGateDoor` that every gameplay code path is expected to use instead of the raw field getter — a raw-getter read silently ignores an active structure-level override. Overrides are set/cleared exclusively through `PATCH /api/GateStructures/{id}/overrides` (web-api) or `/knk gate admin override <structure> <field> <value|clear>` (plugin) — never through the general create/update payload, which the AutoMapper profile deliberately `.Ignore()`s for all 14 fields. This lets a single admin/siege action (e.g. "capture this structure") instantly change every door's effective active/invincible/pass-through state without rewriting every door row. **Who is allowed to call the override endpoint is explicitly still an open question** in the web-api controller's own comment — no permission model exists yet beyond the plugin-side `knk.gate.admin` gate on the command.

Fields with **no** structure-level override (per-door only): health/respawn-rate, all geometry/animation/rotation/scan/region fields, `FaceDirection`, `GateType`, `GeometryDefinitionMode`, `MotionType`, `InfoDisplayLocation`, `DoorNameDisplayMode`, `ContinuousDamageDurationSeconds`, `TileEntityPolicy`, `FallbackMaterial`.

## 3. Geometry definition modes

Set per door via `GeometryDefinitionMode`:

- **PLANE_GRID** (default) — a deterministic rectangular box (Width × Height × Depth) laid out from an `AnchorPoint` along basis vectors derived from two `ReferencePoint`s (falls back to world axes with a warning if reference points are missing). Bounds-checked as a simple rectangle test. `MotionDistanceBlocks` falls back to whichever geometry axis matches `MotionType` when left at 0. `ClipToGeometryBounds` hides blocks that would animate outside the box (lets a door retract into a housing).
- **FLOOD_FILL** — a BFS scan from admin-placed `SeedBlocks`, bounded by `ScanMaxBlocks`/`ScanMaxRadius` and a material whitelist/blacklist, optionally constrained to one plane. Not usable with a manually-scanned open state (Mechanism 2, §4) — the backend/plugin both explicitly reject `GateOpenedBlockScan` against a FLOOD_FILL door.
- **REGION** — the door's footprint is a WorldEdit selection captured via `/knk gate door capture`, stored as opaque vertex JSON (`ClosedRegionData`/`OpenedRegionData`) and projected once at load time onto the door's own basis into a 2D polygon, bounds-checked via even-odd ray casting rather than a rectangle test. Three underlying WorldEdit capture shapes are supported: `POLYGON2D` (X/Z outline + Y range), `CUBOID` (axis-aligned corners), and `CONVEX_POLYHEDRON` (`//sel convex` — the only shape able to precisely represent a genuinely vertical or diagonally-oriented door; its unordered vertex set is re-hulled via Andrew's monotone chain after projection). Used for doors whose shape can't be described as a clean box.
- **Neither the web-api nor the web-app enforce or surface region geometry validation beyond size limits.** Region data is stored and returned opaquely; there's no containment/geometry sanity check at write time. **The web-app's static admin form (`objectConfigs.tsx`) does not yet offer REGION as a `GeometryDefinitionMode` option** — it's reachable only through the dynamic, backend-authored FormConfiguration system, not the default admin form. Treat this as a known gap, not an intentional restriction.

## 4. Animation model

### Motion types

- **VERTICAL / LATERAL** — straight-line motion: `position = anchor + relativePos + motionVector * progress`. LATERAL slides along the door's own lattice direction, correctly handling a diagonally-oriented gate.
- **ROTATION** — used for `DRAWBRIDGE`/`DOUBLE_DOORS`. Each block rotates around the door's `HingeAxis` by `RotationMaxAngleDegrees * progress` (Rodrigues' rotation formula). Hinge axis is selected by gate type: DRAWBRIDGE hinges on the width axis (bottom edge), DOUBLE_DOORS on the height axis (vertical edge).

A `ConditionalValueMatchValidator` rule on the backend enforces `MotionType == ROTATION` whenever `GateType` is `DRAWBRIDGE`/`DOUBLE_DOORS` — this is a form-validation-layer rule, not a hard DB/plugin constraint.

### Mechanism 2 — manually-scanned open state, and the rigid-transform + residual hybrid

Most gates have no manually-scanned open state and just follow the pure geometric arc/line. But a door **can** have a second, separately-scanned "open" snapshot (`OpenAnchorPoint` + `GateOpenedBlockSnapshot` rows, populated by the `GateOpenedBlockScan` headless world task) whose real positions don't perfectly match pure procedural math — real-world scan imperfection, non-rigid geometry, etc. Animating each block independently toward its own real target looks "fluid" (blocks visibly drift apart from each other mid-swing) rather than rigid, so the plugin blends three terms for a ROTATION door with a scan-fitted correction:

1. **Arc position** — the pure procedural rotation, as if there were no correction.
2. **Uniform correction** — one best-fit rotation+translation (`RigidTransform`, fit once at door-load time via the Kabsch algorithm across every closed↔open correspondence pair) applied identically to every block, so the whole door shifts together. Scales linearly with progress, reaching full value at progress=1.
3. **Per-block residual** — a small extra per-block nudge on top of the uniform correction, closing the gap between the uniform-transform prediction and that block's real scanned position. Tapered by a **quintic** curve (`progress⁵`, not linear or cubic) so it doesn't cancel against the uniform correction's own scaling — chosen after live testing showed cubic still looked insufficiently rigid; quintic keeps a well-fit block's residual under ~3% through the first half of the swing.

**SNAP_DISTANCE = 0.5 blocks**: once a paired block's blended position naturally converges within 0.5 blocks of its real scanned target, it snaps exactly rather than approaching asymptotically forever. This threshold is provably collision-safe (real scanned blocks live on the integer lattice, never closer than 1 block apart, so within-0.5-of-one rules out within-0.5-of-any-other) and is what actually guarantees exact, collision-free convergence — taper tuning above is a pure visual concern, unrelated to this correctness guarantee.

**Open-only blocks** (scanned in the open state with no closed-side counterpart) get a synthesized closed-frame starting position — computed once at load by inverse-transforming their real open-scan position back through the fitted `RigidTransform` — so they animate across the full swing instead of only appearing at the end.

Blocks matched between closed and open scans use the Hungarian algorithm (`GateBlockPairing`, true minimum-total-distance bipartite assignment) rather than greedy nearest-neighbor — a greedy matcher was found to produce visibly non-rigid motion on dense REGION captures and was replaced.

### Mechanism 1 — automatic rasterized gap-fill

For a diagonal-hinge ROTATION gate, rotating a sparse integer lattice by a non-cardinal angle leaves gaps ("checkerboard") in the rendered footprint. `GateFrameCalculator.rasterizeRotationFrame` fills these automatically at the two **resting endpoint frames only** (never mid-swing) by testing every integer cell in the rotated bounding box against the door's own geometry bounds via inverse rotation. Governed by a server-wide kill switch, `gates.rotationGapFill.rasterization-enabled` (default `true`). Mechanism 2, when available, always wins outright over Mechanism 1.

### Per-tick driver and edge-case handling

`GateAnimationTask` (one instance per world) drives every animating door each tick: computes the current frame from elapsed wall-clock time, places/vacates blocks, and pushes nearby entities out of the way predictively.

- **Jamming**: 5 consecutive ticks of a blocked placement (a real player-placed block occupying a target cell) flips the door to `JAMMED`. The animation clock is held still (not reset) while jammed, and placement is retried every tick; jam clears the instant a placement fully succeeds again.
- **The door's own blocks never jam it** (KNG-272): a cell the door occupied last tick that one of its blocks now enters with other blockdata — a fence rising into the cell a chain just left — isn't vacated (it is a target) and its old block isn't replaceable, so it used to count as an obstruction. `updateGateBlocks` now clears such cells first (`resolveReplacedCells`, the same `keyframeDiff(...).changed()` the drawbridge keyframe path uses), through `removeBlockIfMatches`, so a foreign block in that cell still jams the door.
- **Orphaned blocks under multi-frame skips**: vacate-cell resolution is based on what the door's own last successful tick *actually placed* (tracked per-gate), not a one-tick-back arithmetic guess — protects against a main-thread stall spanning multiple animation frames stranding blocks that would otherwise never be individually targeted for removal.
- **Stray-cell vacate at completion**: on finishing an open or close, the task additionally clears any cell the swing actually placed that isn't part of either idealized resting frame (e.g. an open-only block's synthesized mid-swing leftover) — the normal resting-frame diff alone can't see this because it only compares the two idealized endpoints against each other.
- **Snow-layer clearing**: any time a gate block is placed or removed, the cell directly above is checked for a layered-snow block (`Material.SNOW`, not `SNOW_BLOCK`) and silently cleared — because gate block edits always disable physics, a snow layer resting on a moving gate block would otherwise be left floating unsupported. Presence/absence only, no item drop or partial-layer tracking.

## 5. Health, damage, destruction, and respawn

Each door has independent `HealthCurrent`/`HealthMax`/`RespawnRateSeconds`. Damage sources (block-break, explosion, projectile hit, melee left-click) are detected by `GateDoorHitService` (spatial-index lookup, O(1)) and routed through cancellable custom Bukkit events to `GateDamageConsequenceListener`, which owns a flat per-cause damage amount (10.0 for every cause — left-click, projectile, explosion, block-break — all equal) that a source can override with its own figure. Melee (left-click and block-break attempts by a player) does what the held item would do to a player (`GateMeleeDamage`): the player's attack damage attribute (base 1 + the item's modifiers, i.e. the tooltip's "Attack Damage", + potion effects such as the Strength a custom enchantment grants) plus the Sharpness bonus `0.5 × level + 0.5`, which the tooltip does not include. Not counted: critical hits and the swing cooldown (a click on a block doesn't reset it); an empty hand does 1. `gates.melee-damage.from-held-item: false` restores the flat 10, `gates.melee-damage.multiplier` scales it. Projectiles, explosions and fire keep their flat amounts. Damage no-ops entirely for an effectively-invincible or effectively-destroyed door.

**Continuous damage ("fire")**: a projectile that's a fireball or already burning (a Flame arrow) ignites the struck door block, and so does flint and steel; `GateFireSystem` tracks per-block burn expiries and applies `damagePerBlockPerTick × count-of-burning-blocks` on each tick — several burning blocks stack damage, deliberately modeling escalating siege pressure. Continuous-damage ticks deliberately don't persist to the database on every application (too frequent during a siege); the in-memory value stays authoritative and is flushed by the periodic sync sweep or on destroy.

*How a burning block looks (2026-10-22):* regular fire on the side of the door block the attacker is on (the struck face for a projectile or flint and steel, otherwise the free side facing the igniter), for as long as the block burns; the flame particles are gone. It is a client-side picture only (`GateFireVisuals`: a fire block sent to players within 64 blocks as a block change, re-sent every fire tick, the real block sent back when the burn ends) — it never exists in the world, so it can't spread, burn a wooden gate, hurt anyone or outlive a crash. A block with no free side still burns for damage, there is just nothing to draw. Smoke (a slow campfire-smoke column plus a puff, renewed every fire tick) rises off the *opposite* face of each burning block, the inside of the gate, so defenders — who can't see the fire from there — know which blocks to put out.

**Freeze puts fire out**: a defender who left-clicks a *burning* door block with a weapon carrying the `freeze` custom enchantment puts that block's fire out (the block stops adding to the continuous damage). Deterministic — it does not use freeze's 15%-per-level proc chance or cooldown, and only that one block is affected. "Defender" means a siege lockdown member whose team is in the alliance that currently owns the gate (`SiegeGatePlan.isDefender`); outside a lockdown nobody is a defender, so nobody can put the fire out.

**Area enchantments hit gates**: when `chaos` (40 damage) or `flash_chaos` (60 damage) goes off, every gate with a closed door block within `gates.area-enchantment-radius-blocks` (default 5, measured to the nearest edge of the block; entities are still only hurt within 3) takes that enchantment's own damage once (`GateAreaDamageService`, as a `GateDoorDamageEvent` with cause `ENCHANTMENT` carrying the amount, so invincibility, siege rules and the damage statistics apply as for any other hit). The knockback ring does not reach gates.

**Damage cracks**: a damaged gate's door blocks show vanilla's 10 block-breaking stages (`GateCrackVisuals`). The stage is the tenth of the gate's HP it has lost: up to 10% lost shows stage 0, 90% and more shows stage 9. Shown only while the door is closed and standing; opening, destruction, respawn or repair takes them down. Sent as block-break animation packets to players within 64 blocks (plus the gate's size), refreshed every 5 ticks on a change and re-sent every ~5 seconds because the client forgets an animation after ~20 seconds. Purely visual; `gates.damage-cracks.enabled` switches it off.

**Destruction**: health reaching 0 captures the door's current animation frame (so a door destroyed mid-swing or while open removes the right blocks, not frame-0's), clears every door block from the world unconditionally, plays a cosmetic-only particle/sound effect (no real terrain damage), and — if respawn is enabled — schedules a respawn.

**Respawn**: after `RespawnRateSeconds`, the door is restored to full health, `CLOSED`, frame 0, all blocks replaced, and a server-wide chat message announces the restoration.

Jammed state is tracked independently of health/destroy (it's an animation-loop concept, not a `HealthSystem` concept) but is force-cleared by both destroy and respawn.

## 6. Pass-through

A closed, pass-through-enabled door reacts to a player right-clicking it, per the player's own configured preference (`/knk gate passthrough <mode>`, stored on their user data):

- **Default** — the door opens fully and auto-closes after its effective pass-through duration; re-triggering while already open/opening just resets the close timer.
- **Instant Open** (requires `knk.gate.passthrough.instant`) — removes only the door blocks directly in the player's path (a short radius around their position + facing direction), restoring them once the player crosses to the far side or after a safety-net timeout. This is a real, briefly-visible block removal — a client-side-packet illusion was tried and reverted because Paper's server-side movement validation rejects a reported position inside a block that's still really solid.
- **Teleport** — the player is projected across the door plane to the far side, with a safe-Y search to avoid landing inside solid ground.

`knk.gate.admin` unconditionally bypasses both the `AllowPassThrough` gate and the `.use`/`.instant` permission checks.

## 7. Display

Each door's name/health/status renders as a floating `TextDisplay` (chosen over an ArmorStand for having no AI/physics/hitbox and native multi-line text). Each line is independently gated by its own display-mode field (`GateNameDisplayMode`/`DoorNameDisplayMode`/`HealthDisplayMode`/`StatusDisplayMode`, each `ALWAYS`/`NEVER`/`SIEGE_ONLY`, health additionally has `DAMAGED_ONLY`). Health text is colored green→yellow→gold→red by ratio, dark-red if destroyed. Position defaults to the door's geometric center, offset up and out along its face direction, unless an admin sets an explicit `InfoDisplayLocation` override.

## 8. Siege objective / guard fields — current status

`GateStructure.IsSiegeObjective`, `CurrentSiegeId`, `AnimateDuringSiege`, `IsOverridable`, and the entire `GuardSpawnLocations`/`GuardCount`/`GuardNpcTemplateId` block exist in the schema today but have **no consuming logic anywhere in the plugin or web-api** — no `Siege` entity exists yet, no guard-spawning code exists. These are forward-looking schema placeholders for the not-yet-built Siege minigame integration, not currently-functioning features. Don't describe them as implemented in player/admin-facing docs.

## 9. Cross-repo data flow

```
knk-web-app (admin authoring)  →  knk-web-api (source of truth, MySQL)  ←→  knk-plugin (runtime)
  objectConfigs.tsx / dynamic       GateStructure/GateDoor entities         GateManager in-memory cache
  FormConfiguration wizard          + 14 override fields                   (own bespoke cache, no TTL —
  world-task "scan" buttons         REST API, JWT bearer auth              not the generic entity-cache
                                     GateBlockScan/GateOpenedBlockScan      framework other entity types
                                     headless world-task completion         use)
                                     writes snapshot rows directly
```

The plugin loads all gates at startup (or on-demand per-district, triggered by a player's first WorldGuard-region entry into that district) and refreshes only via explicit `/knk gate admin reload`, district entry, or a periodic health-check/persist sweep — **not** the generic `cache: entities:` TTL/retry gateway every other entity type in the plugin uses. The web app's GateDoor dashboard and object pickers list doors across all gates through `POST api/GateDoors/search` (KNG-273; `GateDoorListDto` rows with the gate's name; search on door or gate name; filters `gateStructureId`, `gateType`, `openedState`, `isActive`; default order gate name, then door name). A block scan (closed or open state) runs as a **headless** world task — the plugin executes it server-side against the door's captured geometry/region with no player action required, then posts the resulting snapshot rows directly to `GateDoorsApi`, bypassing the generic entity create/update payload entirely (which the backend AutoMapper profile ignores those fields on anyway).

## 10. Known gaps and inconsistencies (accurate as of this scan — don't assume fixed without re-checking)

- REGION geometry mode isn't offered in the web-app's static admin form (`objectConfigs.tsx`) — only reachable via a backend-authored dynamic FormConfiguration.
- Region data (`ClosedRegionData`/`OpenedRegionData`) is stored and validated with no containment/geometry sanity checking anywhere in the stack.
- `GateStructureRepository.GetGatesByDomainAsync` is a stub that ignores `domainId` and returns every gate structure.
- `GateBlockScanRequestDto` (web-api) is defined but unused — the real scan pipeline reads a raw `gateDoorId` property out of the world task's input JSON instead.
- Test coverage is uneven: the animation math, event/consequence listeners, and health/respawn logic are well covered on the plugin side; `GateStructureService` and the backend's health-hits-zero/respawn-restores-health business rules (which live in `GateDoorRepository`) have little to no direct test coverage on the web-api side.
- Siege objective and guard-defense fields are schema-only placeholders (§8).
- Open-state scans (Mechanism 2) on VERTICAL/LATERAL doors pair closed and open blocks by **list index after air is dropped**, so two scans with air in different cells pair blocks across columns and can jam the door ([KNG-271](https://linear.app/kngpandi/issue/KNG-271)). A door that only rises and loses decoration (chains) needs no open scan: procedural motion with `MotionDistanceBlocks` and `ClipToGeometryBounds` does it.
- The GateDoor form doesn't explain the open anchor (the corner of a same-size box that matches the anchor's corner, the anchor itself when the door opens inside its own box, [KNG-270](https://linear.app/kngpandi/issue/KNG-270)) nor that a REGION open scan first needs `/gatedoor capture <door> opened` ([KNG-268](https://linear.app/kngpandi/issue/KNG-268)).
