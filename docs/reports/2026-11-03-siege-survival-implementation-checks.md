# Siege Survival implementation checks — 2026-11-03

**Status:** Research only; no code changed. Answers the implementation checks in [Siege Survival DESIGN §13](../specs/siege-survival/DESIGN.md#13-open-implementation-clarifications-not-missing-core-gameplay-decisions) (item 18 and the "to verify" items 2, 3, 5, 9). Live tests on the server are still required where marked.
**Last updated:** 2026-11-03
**Issue:** KNG-50 (Siege Survival)
**Base:** knk-plugin `main` `c823260`; knk-web-api `master` `8df59b7`; Paper API `26.3.build.205-stable` sources; vanilla Minecraft 26.3 server jar (unobfuscated), read with `javap`.

**Source limits.** The vanilla jar is not Paper's patched server, and no client code was read. Where Paper fires an event or how the client renders something is marked *unconfirmed* unless the Paper Javadoc says so. Vanilla facts were read from bytecode; two were re-checked by hand (melee interval 20 ticks, `ItemEntity` not interactable). Plugin paths below are relative to `knk-paper/src/main/java/net/knightsandkings/knk/paper/` (`paper/`) or `knk-core/src/main/java/net/knightsandkings/knk/core/` (`core/`).

## Summary

| # | Check | Result | Blocks v1? |
|---|---|---|---|
| 1 | Claim the Mystery Box item by right-click | Dropped `Item` entities can't be clicked. Reuse the lootbox stack (`ItemDisplay` + `Interaction` + `TextDisplay`), which already works. | No |
| 2 | Ghost visibility | Siege boards already make invisible players translucent to their own team only. Add invisibility, hide from non-members, `setInvulnerable(true)`. **`ModeService` would un-hide ghosts**; needs a fix. | Small fix |
| 3 | Headshots and crits | `EntityDamageByEntityEvent#isCritical()` exists. Arrow position at damage time ≈ impact point (±0.3). Existing headshot rule is player-sized. | No |
| 4 | Mob attack speed, ranged damage | Mobs ignore `ATTACK_SPEED`; melee interval is a fixed 20 ticks. Needs a custom attack goal (or scale damage instead). Arrow damage via the damage or shoot event. | Design note |
| 5 | Rebuilt doors and large mobs | Respawn is instant with no collision handling; evacuation uses a 1×1 standing spot. Rebuild must go through the normal closing animation; large-mob spots need a fix. | Yes, small |
| 6 | Repair input | Right-click on gate blocks is taken and destroyed doors have no blocks. Use **sneak within range** (proven patterns exist) with a boss-bar progress. | No |
| 7 | Multi-door gates | Health is per door; damage only while CLOSED. No public heal API. Two new `HealthSystem` methods needed. | Yes, small |
| 8 | NPC movement and capture | No mob code exists. WalkSearch (merged) gives block-level paths. Capture and gate damage are player-only today. | Largest piece of work |
| 9 | Mystery Box odds | Roll engine is two-stage (grade, then item); percentages need a small adapter and a match-scoped endpoint. Reel timing logic is reusable. | No |
| 10 | Speed limits | Ground speed ≈ speed²; keep effective speed ≤ 0.4, cap 0.5 (estimate, test live). | No |

Correction found: DESIGN §12 says KNG-27 navigation is unmerged. It is merged on plugin main (e.g. `0baccce Merge KNG-27 / KNG-51 live-test follow-ups`); updated in the same change as this report.

## 1. Claiming the Mystery Box item

- **A dropped item can't be right-clicked.** Vanilla `ItemEntity` keeps `Entity#isPickable() = false` and overrides `isAttackable()` to false, so the client aims through it (client side unconfirmed) and no `PlayerInteractEntityEvent` fires.
- **`Interaction` entity** (`org/bukkit/entity/Interaction.java`): width/height, `setResponsive`, `getLastInteraction()`/`getLastAttack()` with player and timestamp. Right-click fires `PlayerInteractEntityEvent` (+ `PlayerInteractAtEntityEvent`), possibly once per hand; left-click fires Paper's `PrePlayerAttackEntityEvent`.
- **Already built:** `paper/lootbox/LootboxPresenter.java:123-135` spawns a tagged, non-persistent `ItemDisplay` + `Interaction` (0.9×0.9) + `TextDisplay`; `paper/listeners/LootboxInteractListener.java:96-115` handles the clicks (main hand, reach and line of sight at :162-170); `paper/lootbox/LootboxWorldGuardListener.java` allows the click inside WorldGuard regions.
- **Recommendation:** use the same stack on top of the end portal frame. Enchantment glint with `ItemMeta#setEnchantmentGlintOverride(true)`; name in the `TextDisplay`. Accept the click only from the roller (S39). Optionally hide the `Interaction` from other players.
- **Gate-animation interaction:** `GateAnimationTask.isMovable` (:758-763) does not exclude `Interaction` entities, so a box placed in a gate's path would be moved by the animation. Place boxes away from gates or exclude `Interaction` there.
- Risks: reach +3 blocks server-side, duplicate per-hand events, the hitbox catching the crosshair.

## 2. Ghost visibility

- **Vanilla rule:** `Entity#isInvisibleTo(viewer)` is false when viewer and target are on the same team with `canSeeFriendlyInvisibles`; the client then draws them translucent (unconfirmed client side). Use the INVISIBILITY effect, not `setInvisible`: `LivingEntity#updateInvisibilityStatus` resets the flag from the effect. Armour and held items still render.
- **Already in place:** `paper/siege/SiegeScoreboardPresenter.java:64-70` registers every siege team on every member's board and turns on see-friendly-invisibles only for the viewer's own team (verified). An invisible ghost in its own `siege_<id>` team is therefore translucent to teammates and invisible to other teams. Don't move ghosts to a separate team. Shared rank teams have it off (`paper/utils/ScoreboardUtil.java:53-57,129`).
- **Mob targeting:** invisibility alone is not enough: vanilla targeting range becomes max(range × visibility, 2.0), so a zombie still finds an invisible ghost within ~2.5 blocks. `LivingEntity#canBeSeenAsEnemy` = `!isInvulnerable() && canBeSeenByAnyone()`, and `TargetGoal#canContinueToUse` drops targets that fail `canAttack`. So **`setInvulnerable(true)` blocks new targets and drops current ones** for goal-based mobs (brain-based mobs unconfirmed). Add an `EntityTargetLivingEntityEvent` safety net and clear mob targets on the ghost transition.
- **Arrows still hit ghosts** (`Player#isPickable` is `!isSpectator()`): cancel `ProjectileHitEvent` on ghosts.
- **Conflict:** `paper/modes/ModeService.java:228-241` calls `viewer.showPlayer(plugin, target)` for every non-vanished player (verified). It runs on join (`paper/listeners/ModeListener.java:45`) and after permission changes (`paper/user/UserAdminService.java:736`), and would un-hide ghosts. Route ghost hiding through `ModeService` (one visibility arbiter). `paper/user/JoinLoadingGuard.java:98,187` toggles invulnerability at join; re-apply ghost state after it.
- **Recommended setup:** infinite invisibility (no particles/icon); `hideEntity` from non-members; team collision rule NEVER (`LivingEntity#setCollidable` doesn't work client-side for players, per Javadoc); `setInvulnerable(true)` (read back with `isMarkedInvulnerable()`); cancel hunger/exhaustion, pickups, attacks and interactions; adventure mode; no flight; hide or vault armour so it doesn't float (`SiegePlayerVault` exists).
- Risks: teammates' clicks may land on a ghost in front of a mob (unconfirmed); hidden ghosts leave non-members' tab list; Bedrock (Geyser) translucency unconfirmed.

## 3. Headshots and critical hits

- `EntityDamageByEntityEvent#isCritical()` exists (Paper API :64-74, verified): true for a player melee crit and for a critical arrow. Vanilla melee crit: attack strength > 0.9, falling, not on ground, not climbing, not in water, not riding, not sprinting, target living; ×1.5. Mobs never crit.
- **Arrow impact point:** vanilla `AbstractArrow#stepMoveAndHit` sets the arrow position to the hit location before damage, so the arrow's location in the damage event is the entry point into the target's (0.3-inflated) box. Good to about 0.3 blocks; tridents the same; other projectiles and Paper patches unconfirmed. `ProjectileHitEvent` has no hit position for entities. For more precision, ray-trace the victim's bounding box along the arrow's velocity.
- **Existing code:** `paper/listeners/SiegeCombatListener.java:46-73` handles player victims only; `core/siege/SiegeCombatRules.java:60-66` uses `y > feet + 1.33` (player-sized). For mobs use a relative test such as `hitY ≥ feetY + 0.74 × victim.getHeight()` (`getHeight()` covers babies and `SCALE`). Watch spiders, slimes and piercing arrows. A kill that is both crit and headshot counts ×1.1 once (DESIGN S32).

## 4. Mob attack speed and ranged damage

- **Mobs don't use `ATTACK_SPEED`** (only players, items, effects and rabbits read it). `MeleeAttackGoal` uses a fixed `adjustedTickDelay(20)` interval (verified in bytecode); `ZombieAttackGoal` extends it. Victims ignore most of a second hit within 10 ticks (invulnerability frames), so faster than one hit per 10 ticks is wasted.
- **Skeletons:** `RangedBowAttackGoal` with a minimum interval of 40 ticks (20 on Hard), ≥ 20 ticks drawing. Arrow damage is `power × 2 + difficulty term` and does not read `ATTACK_DAMAGE`. `reassessWeaponGoal` re-adds vanilla goals on equipment changes.
- **Recommendation:** melee rate: replace `ZOMBIE_ATTACK`/`MELEE_ATTACK` with our own goal (Paper `MobGoals`) that runs its own cooldown (≥ 10 ticks) and calls `swingMainHand()` + `attack(target)`. Ranged damage: multiply `event.getDamage()` in `EntityDamageByEntityEvent` for arrows from tagged mobs (or `AbstractArrow#setDamage` in `EntityShootBowEvent`). Ranged rate: also a custom goal. Simplest fallback if goals slip: scale `ATTACK_DAMAGE` for damage per second and keep the vanilla rhythm.
- **Design consequence:** "attack speed" scaling in DESIGN §7 needs our own attack goals; document that the implementation scales the goal cooldown, bounded below by 10 ticks.

## 5. Rebuilt gate doors and large mobs

- **Animation path** (`paper/gates/GateAnimationTask.java:251-263, 731-755`): before each block step it predicts upcoming cells (`CollisionPredictor.java:37-52`), tests each entity's real bounding box (:74-99) and moves it with `EntityEvacuator`, or pushes it away. Excludes only dead entities, displays, hanging entities and spectators.
- **Standing spot is player-sized:** `core/gates/safety/GateSafeSpotFinder.java:123-127` → `core/teleport/SafeLocationFinder.java:58-65` checks one 1×1 column (feet, head, ground) within 6 across, ±2 up/down (`EntityEvacuator.java:154-155`). Ravagers, golems and spiders can be put into gaps too small for them. `GateSuffocationGuard` (:52-65) only protects inside gate cells.
- **Blocks don't wait for entities:** `GateBlockPlacer.placeBlockIfVacant` (:88-117) checks blocks only, so an entity that couldn't be moved gets enclosed. Entities never jam a door; only non-gate solid blocks do (5 consecutive blocked steps, `GateAnimationTask.java:51-53, 662-683`).
- **Respawn bypasses all of it:** `HealthSystem.respawnGate` (:335-371) → `restoreGateBlocks` (:383-416) places the closed blocks immediately (verified), with no push or vacancy check, and broadcasts "Gate '…' has been restored!" to the whole server (:367-370).
- **Recommendation:** never use `respawnGate` for survival repairs (see §7 for the replacement). Make the standing-spot search size-aware (check width × height clearance for the entity), and add a live test with a ravager and a spider standing in a closing door.

## 6. Repair input

- Right-click on gate blocks is already used (open/pass-through in `paper/siege/SiegeGateListener.java:43-67`, Cleaving's charged strike) and left-click deals damage. A destroyed door has no blocks to click (removed from the spatial index, `HealthSystem.java:270-272`). Holding right-click does not produce continuous events.
- Patterns in the plugin: channel with cancel-on-move/damage/death (teleport warmup, `WarmupBook` + `TeleportWarmupListener.java:62-96`); sneak detection (`MenuControlHintListener.java:48`, `NavigationCompassListener.java:52`); per-player boss bars and action bars (`NavigationHud.java:48-61`, `EffectBossBars.java`).
- **Recommendation:** a player counts as repairing while **sneaking within range of the door's bounds**, alive, a match member on the defending side, checked every tick or second. Taking damage doesn't stop it (S08); releasing sneak, leaving range, attacking or dying does. Show progress with a boss bar and an action-bar ETA. Alternative: right-clicking an `Interaction` hitbox in the doorway, counted while the last click is under ~400 ms old (must be removed before the door closes; see §1).

## 7. Multi-door gates: health and repair API

- Health is **per door**: API `Models/GateDoor.cs:32-40` (`HealthCurrent`, `HealthMax` default 500, `CanRespawn`, `IsDestroyed`); plugin `CachedGateDoor.java:128-146`. Structure overrides (Active, Destroyed, Invincible, CanRespawn) apply via `isEffectivelyX` (:393-410); no structure health override. `setOpen` acts on all standing doors of a structure (`SiegeGateController.java:473-479`).
- Damage path: `GateEventListener` → `GateDoorHitService.handleDamage` (:66-84) → `HealthSystem.applyDamage` (:71-110). **Only CLOSED, active, non-destroyed doors take damage**, so a door can't be hit while open or animating. This answers the "animation-time damage" question: none.
- **No public heal.** `persistHealthChange` is private (:423). Proposed new `HealthSystem` methods:
  - `repairToFull(door)`: health = max, sync cracks and display, persist, fire state changed; then `closeGate` if the door is open (damaged standing doors, S49).
  - `rebuildForClosing(door)`: destroyed = false, active = true, health = max, state OPEN at the last frame, no blocks placed; persist; then `gateManager.closeGate(id)`. The normal animation then places the blocks with entity handling and jam reporting.
- Report "closed" only when the door actually reaches CLOSED. A jam leaves the state at CLOSING with the clock held and fires no event (`:185-190`); the per-door completion callback is overwritten by the next caller (`GateManager.java:92-96`), so listen with a `GateStateListener`. Keep `CanRespawnOverride = false` (`SiegeGateController.java:440`).
- Repair work is tracked per door (DESIGN §5) while `setOpen` and damage credit are per structure; survival code must address doors individually.

## 8. NPC movement, gate breaching and capture

- **Navigation code is merged** (KNG-27, 51, 73/92, 104, 108, 123, 234). Reusable for mobs:
  - `core/roads/walk/WalkSearch.java:61`: bounded A* with **block-level waypoints** (`WalkPath.points()` :66, partial results :78), Bukkit-free. Only a player `MovementProfile` exists (:51); the paper-side preparers take a `Player` (`WalkLegPreparer.prepare` :68, `WalkAccessFactory.prepare` :151). Limits: legs ≤ 144 blocks, 64 chunks per request, loaded chunks only (`WalkSnapshotService.java:30-57`), 2 concurrent searches server-wide. `GateCellAccess` treats a closed door as blocked; `CellAccess` can express "breakable at cost X".
  - `core/roads/route/AStarRouter.java:54`: road routes as simplified polylines; usable after resampling to waypoints.
  - `core/siege/SiegeGateApproach`: stand point in front of a closed door.
  - Not reusable: navigation sessions, trail rendering, HUD, compass.
- **Paper APIs:** `Pathfinder#moveTo/findPath` (no custom node lists: follow waypoints one `moveTo` at a time); `MobGoals` with `VanillaGoal` keys to remove vanilla targeting/wandering. Vanilla goals re-path every 4–10 ticks, so `moveTo` only sticks if our own goal owns movement. `FOLLOW_RANGE` is both target range and path radius.
- **Driving a mob:** our own TARGET goal (aggro radius, leash anchor, ghost exclusion), a `FollowRouteGoal` (next waypoint), a `BreachGateGoal` (walk to the door's stand point, then on a timer `swingMainHand` + `GateDoorHitService.handleDamage(gate, mob, block, cause, dmg)`, which accepts non-player entities, :16-22, :74-84). Vanilla melee mobs never produce a block-hit event, so this goal is required.
- **The plugin spawns no mobs today** and has no MobGoals/Pathfinder code. Precedent for PDC-tagged, non-persistent entities with a leftover sweep: `GateDisplayManager.java:35,112-141`, `LootboxPresenter.java:41-109`.
- **Player-only assumptions to change:**
  - Capture: `SiegeService.presence` (:385-409) loops over `roster().playerIds()` (verified); `ObjectiveState.Presence(playerId, teamId, distance)` (:30); `CaptureCalculator` (:38-55) counts heads. Add actor kind and weight to `Presence`, include tagged mobs, use weighted sums (weight 1 keeps PvP identical), allow a null capturer for NPC captures (`SiegeService:2230`, `SiegeTelemetryObserver:126`), exclude ghosts.
  - Gate damage on locked siege gates: `SiegeGateListener.attacker()` (:96-100) resolves players only and `SiegeGatePlan.canDamage` (:140-145) refuses a null team, so mob hits are cancelled. Needs a team-based check and a new `GateDoorDamageEvent.Cause` (e.g. NPC_MELEE). `SiegeGateDamageSink` doesn't credit non-player damage. A creeper explosion deals 10 per gate block in its blast (`GateEventListener.java:157-165`).
  - Statistics: `CombatStatisticsListener:192` would count survival mob kills as ordinary PvE kills; decide whether that is wanted.
- **Siege runtime notes:** `SiegeDeathRespawnListener.onDeath` (:32-42) already keeps inventory and clears drops (matches S40). `SiegeInventoryGuardListener` cancels all player pickup (:198-200) except own-match siege books; Mystery Box overflow drops need the same exception, and Mystery Box items need the post-restore strip sweep that `SiegeEnchantBooks` uses (:51-52).
- **Risks:** leftover vanilla goals overriding movement (goal sets differ per mob type); path range/node limits; planner vs. mob movement mismatch (ladders, step and jump rules); crowding at gates and moats; tick cost; WorldGuard blocking plugin spawns (unconfirmed); sun burning; Peaceful difficulty despawn; mobs standing in closing doors; ghosts still targeted or counted.

## 9. Mystery Box odds and animation

- **Roll engine** (`knk-web-api/Services/Lootbox/LootboxRollEngine.cs`): weights are normalized (`PickWeighted` :359-369). Items are picked in two stages: a grade window by `DropChance` (:308-340), then an item by `LootItem.Weight` (:101-103). Enchantments are independent `ChancePercent` hits, grade-clamped and vanilla-filtered (:109-130). The roll runs in the API inside the claim transaction with the daily cap and minting (`LootboxRuntimeService.cs:484-560`).
- **Percentages need a small adapter**, because the grade stage would distort them: either one synthetic grade with Weight = percent, or a `MysteryBoxRoll` doing a single weighted pick and reusing the enchantment rules (exposing the private `RollEnchantments`/`CanCarry`/`ConflictsWithAny`). The book variant only needs the weighted pick; `paper/siege/SiegeEnchantBooks.java:39-55` already builds match-tagged books.
- **Match-scoped endpoint** (proposal): `POST SiegeMatches/{id}/mystery-box/rolls` with the roll id as idempotency key; charges match currency, runs the adapter, records one roll and returns blueprint, enchantments and quantity; no daily cap, minting, claim or tokens.
- **Animation reuse:** `core/lootbox/LootboxReel.java:63-116` is Bukkit-free and not tied to a menu: it plans the strip with the winner at the marker, draws decoys with real weights and builds the ease-out timing from `reel-steps` 32 / `slowest-step-ticks` 8 (`config.yml:819-820`). The menu-bound part (`LootboxOpening` :181-290: inventory, tick sound with rising pitch, landing effects) gets an `ItemDisplay` renderer instead. Decoys: `LootboxDelivery.decoy` (:237-259) → `BlueprintItemAssembler.assemble`; the real item gets a match tag instead of `ItemInstanceTag`.

## 10. Movement speed limits

- Defaults: `MOVEMENT_SPEED` zombie 0.23, skeleton/creeper 0.25, spider 0.3 (attribute range 0–1024).
- Vanilla `MoveControl` turns at most 90° per tick; below an effective speed of 1, ground speed grows roughly with **speed²** (~1.6·s² blocks/tick, zombie ≈ 1.7 blocks/s; derived from bytecode, not measured).
- `PathNavigation`: waypoint tolerance 0.75 − width/2; overshooting likely starts above ~0.9 blocks/tick (effective speed ~0.75, estimate). Stuck check every 100 ticks stops the path if the mob moved less than speed × 25 blocks, so faster mobs re-path more in crowds.
- **Guidance (to test live):** scale speed with an `AttributeModifier`; keep the effective speed ≤ 0.4 (≈ 5 blocks/s, near a sprinting player) and treat 0.5 as the hard cap for the stat-cap check in readiness. Remember the squared effect when choosing the walking-speed weight (DESIGN S54).

## Live tests to run on the castle map

1. Vanilla goal removal per selected mob type (zombie, skeleton, spider, creeper, …).
2. `moveTo` reliability at 10, 20, 35 and 60 blocks.
3. Spawnzone to gate with no authored lanes, at 10, 30 and 50 mobs; tick cost at 50.
4. Breaching a locked siege gate (after the team-based damage check), then rerouting through the breach.
5. Repair to full and rebuild-and-close with players, a ravager and a spider standing in the doorway; jam reporting.
6. Weighted NPC capture and the next spawnzone unlocking.
7. Kiting and leash distance.
8. Ghost transition: mobs drop the target, arrows pass, teammates see translucent, others see nothing; after a rejoin and a permission change (`ModeService`).
9. Stuck respawn, glow for the last enemies and system kill (DESIGN §3c).
10. Lane override, including an invalid routepoint.
11. Mobs far from players (chunk loading) and WorldGuard spawn flags.
12. Mystery Box roll, roller-only claim, 10 s despawn, overflow drop pickup.
13. Headshot/crit multiplier on mobs of different heights; speed cap at 0.4 and 0.5.

## Follow-ups for the design

- DESIGN §12: KNG-27 is merged (fixed with this report).
- DESIGN §7: attack-speed scaling is implemented through custom attack goals, bounded below by 10 ticks; walking speed is capped (proposed 0.5) because of the squared effect.
- DESIGN §3b: ghost hiding must go through `ModeService` as the single visibility arbiter.
- DESIGN §5: repair input is sneak-in-range; rebuild uses the normal close animation, never `respawnGate`.
