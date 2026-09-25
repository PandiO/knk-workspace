# v3 Event-Listener Functional Catalog — `knk-plugin` (2026-09-25)

> Companion to [COMMAND_CATALOG_V3.md](COMMAND_CATALOG_V3.md) (same source-grounded rigor, applied to Bukkit event
> listeners instead of commands) and to [docs/specs/legacy/events-v1.md](../legacy/events-v1.md) /
> [events-v2.md](../legacy/events-v2.md) (same catalog style for the two prior codebases).

**Status:** Draft — fresh, source-grounded read of `knk-plugin` `main` at the absolute path
`C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-plugin` (the worktree's own `Repository/knk-plugin` is
empty/untracked, per task instructions).

**Method:** Every file under `knk-paper/src/main/java/net/knightsandkings/knk/paper/listeners/` (15 files) and four
named files under `knk-paper/src/main/java/net/knightsandkings/knk/paper/menu/` (`AnvilCaptureManager.java`,
`MenuClickListener.java`, `MenuControlHintListener.java`, `MenuLifecycleListener.java`) was read in full — 19
listener classes, **41 `@EventHandler` methods** total (34 in `listeners/`, 7 in `menu/`). Every handler method body
was read to describe actual behavior, not just the event type/signature. Registration was cross-checked by grepping
`KnKPlugin.java` for `registerEvents(` (13 call sites found directly in `KnKPlugin.onEnable`/`registerEvents(WorldGuardRegionTracker)`)
plus `EnchantmentBootstrap.java` (the four enchantment/freeze listeners are wired there, called from
`KnKPlugin.initializeEnchantmentRuntime()` at `KnKPlugin.java:504,809-812`, mirroring how the command catalog found
`EnchantmentCommandHandler`'s `/ce` wiring). **All 19 listener classes are confirmed registered and reachable at
runtime — no unregistered/dead listener class was found**, unlike the command catalog's `WorldGuardManagementCommand`
finding. Several cross-listener interaction risks (duplicate join messages, unguarded double chat-consumption, a
missing quit-cleanup path) were found instead and are documented per-listener below and summarized in §0.

All line numbers refer to
`knk-paper/src/main/java/net/knightsandkings/knk/paper/listeners/**` or `.../menu/**` as headed per file; `KnKPlugin.java`
and `EnchantmentBootstrap.java` line numbers are called out explicitly where cited.

---

## 0. Registration map and cross-cutting findings

| Listener class | Registered at | Priority notes |
|---|---|---|
| `ChatCaptureListener` | `KnKPlugin.java:339-342` | — |
| `EnchantmentCombatListener` | `EnchantmentBootstrap.java:40-47` | — |
| `EnchantmentInteractListener` | `EnchantmentBootstrap.java:48-57` | — |
| `EnchantmentEnchantTableListener` | `EnchantmentBootstrap.java:58` | — |
| `FreezeMovementListener` | `EnchantmentBootstrap.java:59` | — |
| `GateEventListener` | `KnKPlugin.java:575` | — |
| `GateDamageConsequenceListener` | `KnKPlugin.java:576` | — |
| `GatePassThroughConsequenceListener` | `KnKPlugin.java:583-584` | — |
| `RegionTaskEventListener` | `KnKPlugin.java:608-616` | **Conditional** — only registered if `worldTaskHandlerRegistry.getHandler("WgRegionId")` resolves non-null (`KnKPlugin.java:608-609`); silently skipped otherwise (only a log line either way, no hard failure) |
| `WorldTaskChatListener` | `KnKPlugin.java:619-622` | — |
| `WorldTaskLocationSelectionListener` | `KnKPlugin.java:625-628` | — |
| `WorldGuardRegionListener` | `KnKPlugin.java:681` (via private `registerEvents(WorldGuardRegionTracker)` helper, `KnKPlugin.java:677-687`) | — |
| `PlayerListener` | `KnKPlugin.java:682` | — |
| `UserAccountListener` | `KnKPlugin.java:683` | — |
| `ModeListener` | `KnKPlugin.java:685` | — |
| `AnvilCaptureManager` | `KnKPlugin.java:443` | — |
| `MenuClickListener` | `KnKPlugin.java:479-483` | — |
| `MenuLifecycleListener` | `KnKPlugin.java:484-486` | — |
| `MenuControlHintListener` | `KnKPlugin.java:487-489` | — |

**Cross-cutting findings** (detailed again under the relevant listener below):

1. **Duplicate join welcome messages.** `PlayerListener.onJoin` (`PlayerListener.java:131-163`) and
   `UserAccountListener.onPlayerJoin` (`UserAccountListener.java:81-121`) are *both* registered and *both* send an
   independent "Welcome back" message plus balance readout to the same joining player — `PlayerListener` prints
   `"Welcome back " + name` and only coins (`PlayerListener.java:139-141`); `UserAccountListener` separately prints
   a styled `"Welcome back, <name>!"` plus coins/gems/XP (`UserAccountListener.java:136-165`), asynchronously,
   arriving as a second, differently-formatted message shortly after. `PlayerListener`'s own class javadoc
   (`PlayerListener.java:47-52`) says "User creation is now handled by UserAccountListener... This listener only
   handles join greeting and teleportation" — the greeting itself was evidently not deduplicated when that split
   happened.
2. **No mutual exclusion between chat-capture and world-task chat handling.** `ChatCaptureListener` (LOWEST
   priority, no `ignoreCancelled`) and `WorldTaskChatListener` (default/NORMAL priority, no `ignoreCancelled`) both
   listen on the same deprecated `AsyncPlayerChatEvent` and both unconditionally attempt to consume+cancel it
   (`ChatCaptureListener.java:27-36`, `WorldTaskChatListener.java:39-62`). Since neither sets `ignoreCancelled =
   true`, a player who is simultaneously mid-`ChatCaptureManager` session (e.g. account-merge email prompt) *and*
   has an active WorldTask chat-input handler open would have the same raw message routed to **both** systems —
   `ChatCaptureListener` runs first (LOWEST) and cancels/consumes it, but `WorldTaskChatListener` still receives the
   (now-cancelled) event next and, having no `ignoreCancelled` guard, will still try `wgHandler.onPlayerChat(...)`
   /`locationHandler.onPlayerChat(...)`/`gateDoorRegionCaptureHandler.onPlayerChat(...)` against it. Whether that's
   harmless in practice depends on whether those session types can overlap for one player, which is **unclear/out
   of scope** without reading `ChatCaptureManager` and the task-handler classes themselves.
3. **Legacy vs. modern chat event split.** `ChatCaptureListener`/`WorldTaskChatListener` hook the deprecated Bukkit
   `AsyncPlayerChatEvent`, while `PlayerListener.onChat` (the message-formatting/mention-sound handler) hooks
   Paper's newer `io.papermc.paper.event.player.AsyncChatEvent` (`PlayerListener.java:28,240-291`). Whether
   cancelling the legacy event reliably prevents the new event's renderer from running (or vice versa) is a Paper
   platform-bridging question — **unclear/out of scope**, flagged here as a place a future contributor should
   verify rather than assume.
4. **No `PlayerQuitEvent` cleanup in `AnvilCaptureManager`.** Unlike `MenuLifecycleListener`, which explicitly
   handles both `PlayerQuitEvent` and `InventoryCloseEvent` for its own registries (see that class's javadoc,
   `MenuLifecycleListener.java:9-24`), `AnvilCaptureManager` only clears `activeSessions` on `InventoryCloseEvent`
   (`AnvilCaptureManager.java:181-197`) — there is no `PlayerQuitEvent` handler in the class at all. This relies on
   Bukkit reliably firing `InventoryCloseEvent` for a player who disconnects with the anvil open; if that ever
   doesn't happen (edge-case disconnects, e.g. a kick mid-tick) the `activeSessions` map leaks an entry for that
   UUID — the same class of unbounded-map leak `MenuLifecycleListener`'s javadoc explicitly calls out fixing for
   v1's menu system (`MenuLifecycleListener.java:14-15`).
5. **Blocking `.join()` calls on the main thread in enchantment listeners.** `EnchantmentEnchantTableListener`
   (`EnchantmentEnchantTableListener.java:41`), `EnchantmentInteractListener`
   (`EnchantmentInteractListener.java:75,99`) all call `.join()` synchronously inside their `@EventHandler` methods,
   which Bukkit dispatches on the main thread for these event types (`PrepareItemEnchantEvent`, `EnchantItemEvent`,
   `PlayerInteractEvent`). If `EnchantmentRepository`/`CooldownManager` are ever backed by real I/O (network/DB)
   rather than the current `LocalEnchantmentRepositoryImpl`/`InMemoryCooldownManager` (both purely local per
   `EnchantmentBootstrap.java:28-29`), these would stall the main thread. Currently harmless given the local
   implementations actually wired, but worth flagging as a footgun if a remote-backed repository/cooldown manager
   is ever swapped in without also removing the `.join()` calls. By contrast, `EnchantmentCombatListener` avoids
   this via `.thenCompose(...)` with no blocking `.join()` (`EnchantmentCombatListener.java:54-60`).

---

## 1. `listeners/` package

### 1.1 `ChatCaptureListener.java`

**Feature allocation:** `users`/`account` (chat-input plumbing for account flows) — generic utility, not itself
feature-specific.

**Status:** Finished, wired (`KnKPlugin.java:339-342`).

#### `onAsyncPlayerChat` — `AsyncPlayerChatEvent`, priority `LOWEST` (`ChatCaptureListener.java:27-36`)
- **Trigger:** `captureManager.isCapturingChat(player.getUniqueId())` returns true — i.e., the player has an active
  `ChatCaptureManager` session (`ChatCaptureListener.java:29`).
- **Goal/function:** Cancels the chat event (`event.setCancelled(true)`, line 31) so the raw message is never
  broadcast to other players, then routes it to `captureManager.handleChatInput(player, message)` (line 34) — the
  stated purpose is to keep sensitive input (emails, passwords) out of public chat (class javadoc,
  `ChatCaptureListener.java:10-14`).
- **Bugs/edge cases:** See cross-cutting finding #2 (no `ignoreCancelled`, races with `WorldTaskChatListener`) and
  #3 (legacy event vs. `PlayerListener`'s modern `AsyncChatEvent`).

---

### 1.2 `EnchantmentCombatListener.java`

**Feature allocation:** `custom-enchantments`.

**Status:** Finished, wired (`EnchantmentBootstrap.java:40-47`).

#### `onEntityDamage` — `EntityDamageByEntityEvent`, priority `LOWEST`, `ignoreCancelled = true` (`EnchantmentCombatListener.java:32-61`)
- **Trigger:** Damager is a `Player` (line 34), target is a `LivingEntity` (line 38); if `disableForCreative` is
  configured true, skipped for attackers in `GameMode.CREATIVE` (lines 42-44); attacker must be holding a
  non-air main-hand weapon (lines 46-49).
- **Goal/function:** Reads the weapon's lore (line 51-52), calls
  `enchantmentRepository.getEnchantments(lore)` then chains `enchantmentExecutor.executeOnMeleeHit(enchantments,
  attackerId, targetId, event.getDamage())` (lines 54-60) — a **non-blocking** async chain (`.thenCompose`, no
  `.join()`). Actual on-hit enchantment effects live in `EnchantmentExecutor` (not read as part of this task —
  out of scope).
- **Feature allocation:** `custom-enchantments`.
- **Bugs/edge cases:** None found in this method itself; note it never cancels or modifies `event.getDamage()` — any
  enchantment effect that should modify damage would have to happen inside `EnchantmentExecutor`, not here
  (unclear/out of scope, not read).

---

### 1.3 `EnchantmentEnchantTableListener.java`

**Feature allocation:** `custom-enchantments`.

**Status:** Finished, wired (`EnchantmentBootstrap.java:58`).

#### `onPrepareEnchant` — `PrepareItemEnchantEvent`, `ignoreCancelled = true` (`EnchantmentEnchantTableListener.java:20-25`)
- **Trigger:** `hasAnyCustomEnchantment(event.getItem())` — item has non-air type and its lore matches any custom
  enchantment (delegates to `enchantmentRepository.hasAnyEnchantment(lore).join()`, lines 34-42).
- **Goal/function:** Cancels the vanilla enchant-table preview entirely (line 23) if the item already carries a
  custom enchantment — prevents vanilla enchanting from being offered on an item that already has a KnK custom
  enchantment.
- **Feature allocation:** `custom-enchantments`.

#### `onEnchant` — `EnchantItemEvent`, `ignoreCancelled = true` (`EnchantmentEnchantTableListener.java:27-32`)
- **Trigger:** Same `hasAnyCustomEnchantment` check as above.
- **Goal/function:** Cancels the actual enchant application (line 30) — belt-and-suspenders with `onPrepareEnchant`
  in case the preview cancellation is somehow bypassed.
- **Feature allocation:** `custom-enchantments`.
- **Bugs/edge cases:** Both handlers block the main thread on `.join()` (see cross-cutting finding #5).

---

### 1.4 `EnchantmentInteractListener.java`

**Feature allocation:** `custom-enchantments`.

**Status:** Finished, wired (`EnchantmentBootstrap.java:48-57`).

#### `onPlayerInteract` — `PlayerInteractEvent`, priority `LOWEST`, `ignoreCancelled = true` (`EnchantmentInteractListener.java:50-116`)
- **Trigger:** Right-click (air or block) with the main hand only (lines 52-58); skipped in creative mode if
  `disableForCreative` (lines 61-63); requires a non-air item in hand or main-hand fallback (lines 65-71); the
  item's lore must resolve to at least one enchantment via `enchantmentRepository.getEnchantments(lore).join()`
  (lines 73-78).
- **Goal/function:** For each enchantment on the item (lines 83-106): looks up its `EnchantmentRegistry` definition
  and skips anything that isn't `EnchantmentType.SUPPORT` (lines 90-93); **checks
  `player.hasPermission("customenchantments." + enchantmentId)`** per-enchantment (line 95) — properly enforced,
  no analogous gap to the command catalog's `/ce info [player]` finding; checks
  `cooldownManager.getRemainingCooldown(...).join()` and, if still on cooldown, sends a formatted cooldown message
  and skips activating that enchantment (lines 99-103, `sendCooldownMessage` at 118-122); collects all
  activatable support enchantments and calls `enchantmentExecutor.executeOnInteract(map, playerId).join()` (line
  112); if it returns true, cancels the interact event (lines 113-115) — presumably to suppress the vanilla
  right-click action (block placement, eating, etc.) an activated support enchantment shouldn't also trigger.
- **Feature allocation:** `custom-enchantments`.
- **Bugs/edge cases:** Three blocking `.join()` calls in a single handler (lines 75, 99, 112) — see cross-cutting
  finding #5, most pronounced here since it's per-enchantment inside a loop (line 99 in particular is called once
  per SUPPORT enchantment on the item).

---

### 1.5 `FreezeMovementListener.java`

**Feature allocation:** `custom-enchantments` (freeze is an enchantment effect per `FrozenPlayerTracker`).

**Status:** Finished, wired (`EnchantmentBootstrap.java:59`).

#### `onPlayerMove` — `PlayerMoveEvent`, priority `HIGHEST`, `ignoreCancelled = true` (`FreezeMovementListener.java:17-37`)
- **Trigger:** `frozenPlayerTracker.isFrozen(player.getUniqueId())` (line 19); `event.getTo()` non-null (line 26);
  and the block-coordinate position actually changed (lines 29-33) — sub-block head/camera movement is allowed
  through untouched.
- **Goal/function:** Snaps the player back to `event.getFrom()` via `event.setTo(from)` (line 36) — hard-freezes
  block-level movement while frozen, without blocking look/camera movement.
- **Feature allocation:** `custom-enchantments`.
- **Bugs/edge cases:** `HIGHEST` priority with `ignoreCancelled = true` means if an earlier listener (e.g.
  `WorldGuardRegionListener`, at default `NORMAL`) already cancelled the move, this correctly no-ops rather than
  double-handling. No issues found.

---

### 1.6 `GateDamageConsequenceListener.java`

**Feature allocation:** `gate-structure-animation`.

**Status:** Finished, wired (`KnKPlugin.java:576`).

#### `onGateDoorDamage` — custom `GateDoorDamageEvent` (`GateDamageConsequenceListener.java:35-43`)
- **Trigger:** `!event.isCancelled()` (line 37).
- **Goal/function:** Looks up a flat damage amount per `event.getCause()` from the static `DAMAGE_BY_CAUSE` map
  (all four causes — `LEFT_CLICK`, `PROJECTILE`, `EXPLOSION`, `BLOCK_BREAK` — currently map to `10.0`, lines
  20-25), defaulting to `10.0` for any unmapped cause, then calls `healthSystem.applyDamage(gate, amount)` (line
  42). Class javadoc notes `HealthSystem` already no-ops for invincible/destroyed gates (lines 12-18) — not
  re-verified here (out of scope, `HealthSystem` itself not read).
- **Feature allocation:** `gate-structure-animation`.
- **Bugs/edge cases:** All four causes currently have identical damage (`10.0`) — the per-cause map exists but is
  not yet differentiated; not a bug, but worth flagging as a design decision that may be incomplete/placeholder
  (a `BLOCK_BREAK` full-break attempt and a single `LEFT_CLICK` punch dealing equal damage looks like a tuning gap
  rather than a deliberate choice, per the class's own javadoc — "future causes/amounts can be tuned here").

#### `onGateDoorIgnite` — custom `GateDoorIgniteEvent` (`GateDamageConsequenceListener.java:45-52`)
- **Trigger:** `!event.isCancelled()` (line 47).
- **Goal/function:** Calls `fireSystem.igniteBlock(event.getGate(), event.getHitBlock())` (line 51) — starts a burn
  via `GateFireSystem` (not read — out of scope).
- **Feature allocation:** `gate-structure-animation`.

---

### 1.7 `GateEventListener.java`

**Feature allocation:** `gate-structure-animation`.

**Status:** Finished, wired (`KnKPlugin.java:575`). This is the largest listener class in the catalog — 6 handler
methods, all adapting raw Bukkit block/entity/projectile events into the custom `GateDoorDamageEvent` /
`GateDoorIgniteEvent` / `GateDoorInteractEvent` events other listeners (§1.6, §1.8) react to. Detection itself is
delegated to `GateDoorHitService` (not read — out of scope); this class's job is purely translating Bukkit events
into that service's calls and propagating cancellation back.

#### `onBlockBreak` — `BlockBreakEvent`, priority `HIGHEST`, `ignoreCancelled = true` (`GateEventListener.java:57-81`)
- **Trigger:** `hitService.resolveDoorGate(world, block)` returns non-null, i.e. the broken block is a gate door
  block (line 62).
- **Goal/function:** If the breaking player holds `knk.gate.admin`, logs the admin break and lets it proceed
  unimpeded — **no damage registered, no cancellation** (lines 68-71). Otherwise cancels the break (line 74),
  messages the player in red naming the gate (lines 75-78), and registers `BLOCK_BREAK`-cause damage via
  `hitService.handleDamage(...)` (line 80) — so a non-admin's *attempt* to break the block still deals gate damage
  even though the block itself survives.
- **Feature allocation:** `gate-structure-animation`.
- **Bugs/edge cases:** `knk.gate.admin` fully bypasses both the break-prevention and the damage registration for
  admins — intentional per the inline comment (line 67), no gap found.

#### `onEntityExplode` — `EntityExplodeEvent`, priority `HIGH`, `ignoreCancelled = true` (`GateEventListener.java:88-103`)
- **Trigger:** Any block in `event.blockList()` resolves to a gate door via `hitService.resolveDoorGate` (line 93).
- **Goal/function:** For every gate block caught in the blast, registers `EXPLOSION`-cause damage via
  `hitService.handleDamage(gate, event.getEntity(), block, ...)` (line 99) and collects it into `blocksToRemove`;
  after the loop, removes all of those blocks from `event.blockList()` (line 102) so vanilla explosion physics
  never destroys the gate block outright — damage is tracked separately through the gate's own health system
  instead.
- **Feature allocation:** `gate-structure-animation`.

#### `onBlockExplode` — `BlockExplodeEvent`, priority `HIGH`, `ignoreCancelled = true` (`GateEventListener.java:108-123`)
- **Trigger/goal:** Same pattern as `onEntityExplode` but for explosions with no causing entity (bed/respawn-anchor
  detonations per the javadoc, lines 105-107) — passes `null` for the damager (line 119).
- **Feature allocation:** `gate-structure-animation`.

#### `onProjectileHit` — `ProjectileHitEvent`, priority `NORMAL`, `ignoreCancelled = true` (`GateEventListener.java:131-154`)
- **Trigger:** `event.getHitBlock()` non-null (an entity hit is ignored, lines 133-137) and that block resolves to
  a gate door (line 139).
- **Goal/function:** Resolves the shooter entity if the projectile has one (lines 144-146), registers
  `PROJECTILE`-cause damage (line 148), then checks `resolveIgniteCause(event.getEntity())` (lines 150,162-170) —
  a `Fireball`/`SmallFireball` always ignites (`FIRE_CHARGE`), or any projectile currently on fire
  (`getFireTicks() > 0`, e.g. Flame-enchanted arrow or one that flew through fire/lava) ignites as
  `FLAMING_PROJECTILE`. If an ignite cause resolved, calls `hitService.handleIgnite(...)` (line 152).
- **Feature allocation:** `gate-structure-animation`.

#### `onBlockIgnite` — `BlockIgniteEvent`, priority `NORMAL`, `ignoreCancelled = true` (`GateEventListener.java:183-211`)
- **Trigger:** `resolveIgniteCause(event.getCause())` maps `FLINT_AND_STEEL`→`FLINT_AND_STEEL` or
  `FIREBALL`→`FIRE_CHARGE`; every other vanilla ignite cause (lava contact, fire spread, lightning) returns null
  and the handler no-ops (lines 218-224).
- **Goal/function:** Per the extensive javadoc (lines 172-182): vanilla ignition targets the adjacent **air**
  block a player was looking at, not the gate door block itself, which would otherwise leave a cosmetic floating
  fire block next to the gate instead of the gate actually burning. This handler checks whether the directly
  ignited block is itself a gate door (`directGate`, line 193); if so, cancels vanilla placement and ignites that
  block for real (lines 194-197). Otherwise it checks all 6 neighboring blocks (`ADJACENT_FACES`, lines 200-210)
  and, on the first neighbor that resolves to a gate door, cancels and ignites that neighbor instead.
- **Feature allocation:** `gate-structure-animation`.
- **Bugs/edge cases:** Only the *first* matching neighbor (in `ADJACENT_FACES` iteration order: UP, DOWN, NORTH,
  SOUTH, EAST, WEST) is ignited if multiple neighbors happen to be gate blocks — a corner/adjacent-gates edge case
  that would silently ignite only one of several eligible gate blocks. Minor, likely rare in practice.

#### `onPlayerInteract` — `PlayerInteractEvent`, priority `NORMAL`, `ignoreCancelled = true` (`GateEventListener.java:233-255`)
- **Trigger:** `event.getClickedBlock()` non-null and resolves to a gate door (lines 235-243).
- **Goal/function:** Right-click (`Action.RIGHT_CLICK_BLOCK`) dispatches to `hitService.handleInteract(gate,
  player, clickedBlock)`, producing a `GateDoorInteractEvent`; if that resulting event ends up cancelled, the
  original Bukkit interact is cancelled too (lines 247-251) — propagating whatever
  `GatePassThroughConsequenceListener` (§1.8) decides back onto the original click. Left-click
  (`Action.LEFT_CLICK_BLOCK`) instead registers `LEFT_CLICK`-cause damage directly (lines 252-253) — this is the
  "punch damage" the class javadoc on `onBlockBreak`'s doc comment (line 55) says is tracked independently from a
  completed break attempt.
- **Feature allocation:** `gate-structure-animation`.
- **Bugs/edge cases:** The javadoc (lines 226-232) explicitly notes `knk.gate.open`/`knk.gate.close` (the manual
  `/knk gate open|close` command permissions) are **unrelated** to pass-through detection here — that permission
  split lives entirely in `GatePassThroughConsequenceListener` (§1.8), not this method. No permission check exists
  in this method itself, by design (detection-only, per the class javadoc lines 31-37).

---

### 1.8 `GatePassThroughConsequenceListener.java`

**Feature allocation:** `gate-structure-animation`.

**Status:** Finished, wired (`KnKPlugin.java:583-584`).

#### `onGateDoorInteract` — custom `GateDoorInteractEvent` (`GatePassThroughConsequenceListener.java:31-50`)
- **Trigger:** `!event.isCancelled()` (line 33); `gate.isEffectivelyAllowPassThrough()` OR the player holds
  `knk.gate.admin` (line 41); and, if not admin, the player must also hold `knk.gate.passthrough.use` (line 44).
- **Goal/function:** Resolves the player's preferred pass-through mode via `resolveMode` (lines 57-70): reads
  `userManager.getCachedUser(playerId).gatePassThroughMethodDefault()`, defaulting to `GatePassThroughMethod.DEFAULT`
  if the user isn't cached yet (lines 58-61); if the preferred mode is `INSTANT_OPEN` but the player is non-admin
  and lacks `knk.gate.passthrough.instant`, **silently downgrades to `DEFAULT`** rather than denying — described
  in the javadoc (lines 52-56) as intentional ("the gate should 'just work' at whatever tier the player is
  permitted"). Dispatches to `passThroughService.dispatch(gate, player, mode)` (line 49).
- **Feature allocation:** `gate-structure-animation`.
- **Bugs/edge cases:** Permission enforcement here is layered correctly (base `knk.gate.passthrough.use` gate, then
  a separate `knk.gate.passthrough.instant` gate for the higher tier, with admin bypass for both) — **no
  unenforced-but-declared permission node found** in this listener, unlike the command catalog's `/ce info
  [player]` `.others` gap. `gate.isEffectivelyAllowPassThrough()` itself (the gate's own admin-configured
  pass-through toggle) is not re-verified here — its correctness is out of scope (`CachedGateDoor` not read).

---

### 1.9 `ModeListener.java`

**Feature allocation:** `users`/`account` (owner/staff vanish-mode restore).

**Status:** Finished, wired (`KnKPlugin.java:685`).

#### `onJoin` — `PlayerJoinEvent`, priority `HIGHEST` (`ModeListener.java:38-75`)
- **Trigger:** Always runs; branches on `modeService.getPersistedMode(player).isVanished()` (line 46).
- **Goal/function:** First calls `modeService.refreshVisibilityFor(player)` (line 44) to hide any already-vanished
  players from the newly-joined player. If the persisted mode isn't vanished, applies `ActiveMode.NONE` (to also
  re-reveal the player to anyone who still had them hidden from a previous vanished session — comment lines
  48-49) and returns (lines 47-52). If vanished: nulls the join message (line 57, "so there's no window where
  other players see them"), applies the vanish mode immediately (line 58), then asynchronously re-confirms via
  `modeService.whenHasModePermission(...)` (lines 59-74) that the player still holds the mode's permission node —
  if revoked while offline, it's silently cleared (`applyMode(NONE)` + `persist(NONE)`, lines 70-71) and the
  player is told why (line 72-73); if still held, sends an action-bar confirmation (lines 65-67). Guards against
  the player disconnecting or switching modes again before the async permission check resolves (`!player.isOnline()
  || modeService.getActiveMode(player) != persisted`, line 60).
- **Feature allocation:** `users`/`account`.
- **Bugs/edge cases:** Runs at `HIGHEST`, explicitly designed (per class javadoc, lines 18-27) to run after
  `PlayerListener`'s `NORMAL`-priority join-message set so it can null it for vanished players — correct ordering
  given `PlayerListener` has no explicit priority (defaults to `NORMAL`). `UserAccountListener.onPlayerJoin` is
  `HIGH` (between `PlayerListener`'s `NORMAL` and this `HIGHEST`) but doesn't touch the join message at all, so no
  conflict there.

#### `onQuit` — `PlayerQuitEvent`, priority `HIGHEST` (`ModeListener.java:77-86`)
- **Trigger:** Always runs; nulls the quit message only if `modeService.isVanished(player)` (lines 80-81).
- **Goal/function:** Calls `modeService.forget(player)` unconditionally (line 85) — comment notes every in-session
  mode change was already persisted when made, so nothing further needs persisting here (lines 83-84).
- **Feature allocation:** `users`/`account`.

---

### 1.10 `PlayerListener.java`

**Feature allocation:** mixed — `users`/`account` (login/join/salary/presence), `misc`/`other` (chat formatting,
death/respawn, item pickup, command blocking). Class javadoc explicitly marks this "Legacy" (`PlayerListener.java:47-52`).

**Status:** Finished, wired (`KnKPlugin.java:682`) — but see per-handler notes for stub/incomplete pieces.

#### `onValidateLogin` — `AsyncPlayerPreLoginEvent` (`PlayerListener.java:73-113`)
- **Trigger:** Always runs pre-login.
- **Goal/function:** Fetches the user by UUID via `usersDataAccess.getByUuidAsync(uuid, FetchPolicy.STALE_OK).join()`
  (line 79); if the result is stale, triggers a background refresh (`triggerBackgroundUserRefresh`, lines 80-81,
  115-129) but still proceeds. If the lookup succeeds, logs and returns (lines 84-87). If `NOT_FOUND`, falls back
  to a **username** lookup (`usersDataAccess.getByUsernameAsync(username).join()`, line 90) — presumably to catch
  a UUID mismatch/migration case; if that also misses, creates a brand-new `UserDetail` and calls
  `usersDataAccess.getOrCreateAsync(uuid, true, newUser).join()` (lines 96-102). Any exception during the whole
  flow is caught and logged, and **login is allowed to proceed regardless** (line 111, comment: "Allow login to
  proceed even if data fetch fails").
- **API calls:** `UsersDataAccess` (wraps `UsersQueryApi`/`UsersCommandApi`, out of scope for direct inspection —
  data-access layer, not itself an API class).
- **Feature allocation:** `users`/`account`.
- **Bugs/edge cases:** This is a **blocking** `.join()` chain (multiple, in the worst NOT_FOUND path: up to three
  sequential blocking API round-trips — UUID lookup, username lookup, create) inside `AsyncPlayerPreLoginEvent`,
  which Bukkit already dispatches asynchronously, so blocking here is expected/safe for this specific event type
  (unlike the main-thread-blocking concern flagged for the enchantment listeners in cross-cutting finding #5).

#### `onJoin` — `PlayerJoinEvent` (`PlayerListener.java:131-163`)
- **Trigger:** Always runs (no explicit priority → `NORMAL`).
- **Goal/function:** Reads the user from `cacheManager.getUserCache()` (line 134), reports presence (see
  `reportPresence`, lines 213-222), sets a plugin-styled join message (line 137), sends a "Welcome back" message
  plus coin balance and a first-time-player greeting if `user.isNewUser()` (lines 139-144). If the player lacks
  `knk.mode.owner`, forces `GameMode.SURVIVAL`, `setFlying(false)`, and teleports them to
  `Bukkit.getWorlds().get(0)`'s spawn (lines 147-156) — **dead commented-out code** for a richer town-based
  teleport is left in place (lines 150-155). Sets the scoreboard (line 158) and, if the user resolved, triggers a
  background salary payout (line 161, `triggerBackgroundSalaryPayout`, lines 170-191) which pays out via
  `usersCommandApi.payOutSalaryById(userId)` and messages the player on the main thread if a payout occurred.
- **API calls:** `UsersCommandApi.payOutSalaryById`, `UsersCommandApi.setPresenceById` (via `reportPresence`).
- **Feature allocation:** `users`/`account`.
- **Bugs/edge cases:** See cross-cutting finding #1 (duplicate welcome message with `UserAccountListener`). Also:
  `DEFAULT_RESPAWN_TOWN_ID = 4` is declared as a class constant (line 56) but **never referenced in this method** —
  the actual teleport target here is just `Bukkit.getWorlds().get(0)`'s spawn (line 156), not town 4; the constant
  is instead used (as a literal `4`, not the named constant) in `onPlayerRespawn` below. Minor
  naming/consistency gap: the constant's name implies it governs *this* join teleport but it doesn't.

#### `onLeave` — `PlayerQuitEvent` (`PlayerListener.java:193-201`)
- **Goal/function:** Reports presence as offline (line 197) and sets the quit message.
- **Bugs/edge cases:** **Duplicate line** — `e.quitMessage(...)` is called twice in a row with an identical
  argument (`PlayerListener.java:199-200`). Harmless (second call just overwrites the first with the same value)
  but a clear leftover/copy-paste artifact.

#### `reportPresence` (helper, not an `@EventHandler` itself) — `PlayerListener.java:213-222`
- Called from both `onJoin` and `onLeave`. Calls `usersCommandApi.setPresenceById(user.id(), isOnline)`; no-ops
  silently if `user == null || user.id() == null || usersCommandApi == null` (line 214) — the javadoc (lines
  203-212) explicitly accepts this as an acceptable miss ("a missed presence ping is not worth failing login
  over"), citing that this is the *only* mechanism reporting presence to knk-web-api at all (no periodic sync
  loop exists to fall back on).

#### `onCommand` — `PlayerCommandPreprocessEvent` (`PlayerListener.java:224-238`)
- **Trigger:** Message case-insensitively matches `/help`, `/plugins`, `/pl`, `/plugin`, `/v`, or `/version`
  (lines 228-233).
- **Goal/function:** Cancels the command for anyone without `knk.mode.owner` (lines 234-236) — hides
  plugin-list/version info from non-owners, presumably to obscure the server's plugin stack.
- **Feature allocation:** `misc`/`other`.
- **Bugs/edge cases:** String-literal command matching, not a Bukkit command-permission override — trivially
  bypassable via any alias not in this exact list (e.g. a different plugin's `/pl:list` alias, or namespaced
  `/bukkit:version`), which Bukkit's `PlayerCommandPreprocessEvent` would still deliver as a *different* message
  string this check wouldn't match. Low-stakes (information disclosure of plugin list only) but a real gap.

#### `onChat` — `io.papermc.paper.event.player.AsyncChatEvent` (`PlayerListener.java:240-291`)
- **Trigger:** Always runs, `NORMAL` priority.
- **Goal/function:** Builds a formatted `Component` (owner-tagged in a distinct color if `knk.mode.owner`, plain
  otherwise; capitalizes the first letter of the message and converts legacy `&`-color codes, lines 244-268) and
  installs it via `e.renderer(...)`. Separately, spins up an **async** `BukkitRunnable` (lines 273-290) that scans
  all online players for a case-insensitive name mention in the raw message and, subject to a 5-second
  per-recipient cooldown (`MENTION_SOUND_COOLDOWN_MILLIS`, `mentionSoundCooldowns` map), plays a note-block ping
  sound to each mentioned player.
- **Feature allocation:** `misc`/`other`.
- **Bugs/edge cases:** See cross-cutting findings #2/#3 (legacy `AsyncPlayerChatEvent` vs. this modern
  `AsyncChatEvent`). Mention-detection is a plain substring match (`lowered.contains(p.getName().toLowerCase())`,
  line 279) — matches partial names too (e.g. a player named "Ann" would trigger on any message containing "Anna"),
  a minor false-positive source, not a security issue.

#### `onPlayerDeath` — `PlayerDeathEvent` (`PlayerListener.java:293-298`)
- **Goal/function:** Sends "You died" to the dying player. The `killer` local variable is fetched (line 296) but
  **never used** — dead/unused code, presumably a placeholder for a future killer-credit message.
- **Feature allocation:** `misc`/`other`.
- **Status:** Stub — minimal implementation, `killer` capture suggests unfinished intent.

#### `onPlayerRespawn` — `PlayerRespawnEvent` (`PlayerListener.java:300-320`)
- **Goal/function:** Fetches the default town (hardcoded literal `4`, not the `DEFAULT_RESPAWN_TOWN_ID` constant —
  line 305) via `townsDataAccess.getByIdAsync(4, FetchPolicy.CACHE_FIRST)`, but the success branch contains only a
  `TODO` comment and a commented-out `e.setRespawnLocation()` call (lines 311-315) — **the fetched town is never
  actually used to set the respawn location.** The method fetches data and then does nothing with it.
- **Feature allocation:** `towns`/`world-admin`.
- **Status:** **Stub.** This handler is a confirmed no-op for its stated purpose — it performs a real async API
  call but the entire consequence is an unimplemented TODO.

#### `onItemPickup` — `PlayerPickupItemEvent` (`PlayerListener.java:322-328`)
- **Goal/function:** Cancels item pickup for every player except those with `isOp()` (lines 324-327) —
  unconditional, no exceptions for e.g. containers, drops from the player's own inventory, or any other
  distinction.
- **Feature allocation:** `misc`/`other`.
- **Bugs/edge cases:** This is a **blanket disable of vanilla item pickup for every non-OP player on the server**,
  with no visible feature flag, permission node, or scoping condition — worth flagging prominently since it's a
  significant, unconditional gameplay restriction that isn't obviously connected to any named KnK feature area in
  this file; the reason for it (perhaps a custom pickup/inventory system elsewhere handles pickup instead) is
  **unclear/out of scope** without reading further systems.

---

### 1.11 `RegionTaskEventListener.java`

**Feature allocation:** `world-tasks`.

**Status:** Finished, wired **conditionally** (`KnKPlugin.java:608-616` — only if the `WgRegionId` handler resolved
from `worldTaskHandlerRegistry`; in practice this handler is always registered immediately after
`WgRegionIdTaskHandler` is created and registered into the registry a few lines earlier in `onEnable`,
`KnKPlugin.java:349-350`, so the conditional is effectively always true at normal startup, but a future refactor
that reorders handler registration could silently disable this listener with only a missing log line as evidence).

#### `onRegionEnter` — custom `OnRegionEnterEvent` (`RegionTaskEventListener.java:23-28`)
- **Trigger:** Always runs.
- **Goal/function:** Pure pass-through — extracts player and `regionId` from the event and calls
  `wgRegionIdTaskHandler.onRegionEnter(player, regionId)` (line 27). All actual logic lives in
  `WgRegionIdTaskHandler` (not read — out of scope).
- **Feature allocation:** `world-tasks`.

---

### 1.12 `UserAccountListener.java`

**Feature allocation:** `users`/`account`.

**Status:** Finished, wired (`KnKPlugin.java:683`).

#### `onPlayerJoin` — `PlayerJoinEvent`, priority `HIGH` (`UserAccountListener.java:81-121`)
- **Trigger:** Always runs.
- **Goal/function:** Kicks off `userManager.onPlayerJoinAsync(player)` (line 88) — async so the join itself is
  never held up waiting on the web API (javadoc, lines 36-43, 71-79). On completion, hops back to the main thread
  via `Bukkit.getScheduler().runTask(plugin, ...)` (line 89) and, if the player is still online (re-checked by
  UUID, lines 91-94): sends a welcome message (`sendWelcomeMessage`, lines 136-166 — name + coins/gems/XP if
  `userId() != null`); if `userData.hasDuplicateAccount()`, sends a duplicate-account warning pointing at
  `/account link` (`sendDuplicateAccountPrompt`, lines 171-198); if `!userData.hasEmailLinked() &&
  userData.userId() != null`, sends an account-linking suggestion (`sendAccountLinkSuggestion`, lines 203-227).
  Any exception during message display is caught, logged with stack trace, and a fallback "could not be loaded"
  message is sent instead (lines 109-118).
- **Feature allocation:** `users`/`account`.
- **Bugs/edge cases:** See cross-cutting finding #1 — duplicate welcome message vs. `PlayerListener.onJoin`.

#### `onPlayerQuit` — `PlayerQuitEvent`, priority `MONITOR` (`UserAccountListener.java:126-131`)
- **Goal/function:** Clears the cached `PlayerUserData` for the quitting player via
  `userManager.clearCachedUser(uuid)` (line 129) — runs at `MONITOR` so it's guaranteed to fire after every other
  plugin's quit-time logic that might still want to read the cache.
- **Feature allocation:** `users`/`account`.

---

### 1.13 `WorldGuardRegionListener.java`

**Feature allocation:** `towns`/`world-admin` (region entry/exit gameplay consequences).

**Status:** Finished, wired via the `registerEvents(WorldGuardRegionTracker)` helper (`KnKPlugin.java:558-566,681`).

#### `onPlayerMove` — `PlayerMoveEvent`, `ignoreCancelled = true` (`WorldGuardRegionListener.java:31-35`)
- **Trigger:** Always runs (no explicit priority → `NORMAL`); delegates to `tracker.handleMove(...)` inside the
  shared `handle` helper (lines 77-98), which returns `null` for "no change or suppressed" (line 79).
- **Goal/function:** If movement is denied, cancels the event and sends a red action-bar message (lines 87-91).
  If allowed and the transition type is `ENTER`, sends a yellow-ish action-bar welcome message (lines 94-95). All
  actual region-boundary logic lives in `WorldGuardRegionTracker` (not read — out of scope).
- **Feature allocation:** `towns`/`world-admin`.
- **Bugs/edge cases:** Logs at `LOGGER.info` for every non-null decision (lines 84-85, 88-89) on `PlayerMoveEvent`
  — a very high-frequency event (fires multiple times per second per player while moving). If decisions are
  frequent (e.g. players lingering near a region boundary), this could produce significant log volume/IO
  overhead. Worth flagging as a potential performance/log-spam concern, though actual frequency depends on
  `tracker.handleMove`'s own suppression logic (out of scope).

#### `onPlayerTeleport` — `PlayerTeleportEvent`, `ignoreCancelled = true` (`WorldGuardRegionListener.java:37-41`)
- Same `handle(...)` delegation as `onPlayerMove`, for teleports instead of walking. `LOGGER.info` per-call (line
  39) is far less of a concern here given teleports are comparatively rare.
- **Feature allocation:** `towns`/`world-admin`.

#### `onPlayerJoin` — `PlayerJoinEvent` (`WorldGuardRegionListener.java:43-69`)
- **Goal/function:** Calls `tracker.handleJoin(player)` (line 47); if the decision denies movement, sends an error
  message and force-teleports the player to world spawn as a safe fallback (lines 53-61); if allowed and type is
  `ENTER`, sends a welcome message (lines 62-67).
- **Feature allocation:** `towns`/`world-admin`.

#### `onPlayerQuit` — `PlayerQuitEvent` (`WorldGuardRegionListener.java:71-75`)
- **Goal/function:** Calls `tracker.handleQuit(player)` — cleans up whatever per-player state the tracker holds
  (not read — out of scope).
- **Feature allocation:** `towns`/`world-admin`.

---

### 1.14 `WorldTaskChatListener.java`

**Feature allocation:** `world-tasks`.

**Status:** Finished, wired (`KnKPlugin.java:619-622`).

#### `onPlayerChat` — `AsyncPlayerChatEvent` (`WorldTaskChatListener.java:39-62`)
- **Trigger:** Always runs (no explicit priority → `NORMAL`, no `ignoreCancelled`).
- **Goal/function:** Tries three task handlers in a fixed fallback order, cancelling the chat event and stopping on
  the first one that reports it handled the message: `handlerRegistry.getWgRegionIdHandler().onPlayerChat(...)`
  (lines 45-50, "most common use case" per comment), then `handlerRegistry.getLocationTaskHandler().onPlayerChat(...)`
  (lines 53-57, marked `// TODO: Route to other task handlers as they are implemented`), then
  `gateDoorRegionCaptureHandler.onPlayerChat(...)` (lines 59-61) — the last one is explicitly *not* part of
  `WorldTaskHandlerRegistry` per the field's own comment (lines 22-26): it's a direct admin command flow
  (region capture/redefine), not a `FormConfig`-driven `WorldTask`, routed here directly for consistency with the
  existing dispatch style.
- **Feature allocation:** `world-tasks`.
- **Bugs/edge cases:** See cross-cutting finding #2 (races with `ChatCaptureListener`, both unguarded on the same
  deprecated event). The `TODO` at line 52 documents that this dispatch chain is explicitly incomplete — only
  three of presumably more task-handler types are wired here.

---

### 1.15 `WorldTaskLocationSelectionListener.java`

**Feature allocation:** `world-tasks`.

**Status:** Finished, wired (`KnKPlugin.java:625-628`).

#### `onPlayerInteract` — `PlayerInteractEvent` (`WorldTaskLocationSelectionListener.java:20-29`)
- **Trigger:** `Action.RIGHT_CLICK_BLOCK` with `EquipmentSlot.HAND` only (line 22).
- **Goal/function:** Delegates to `locationTaskHandler.onBlockRightClick(player, clickedBlock)`; if it returns
  true, cancels the interact event (lines 26-27) — routes block right-clicks to an active `LocationSelection`
  world task. All actual selection logic lives in `LocationTaskHandler` (not read — out of scope).
- **Feature allocation:** `world-tasks`.

---

## 2. `menu/` package (4 assigned files)

### 2.1 `AnvilCaptureManager.java`

**Feature allocation:** `inventory-menus`. Extensively documented in its own class javadoc (lines 25-80) as an
in-house replacement for a rejected third-party AnvilGUI dependency, built directly against Bukkit's anvil-rename
mechanics (Phase 7/QOL follow-up per docs cited inline).

**Status:** Finished, wired (`KnKPlugin.java:443`).

#### `onPrepareAnvil` — `PrepareAnvilEvent` (`AnvilCaptureManager.java:134-151`)
- **Trigger:** `isTrackedAnvil(event.getInventory())` — the anvil belongs to a currently-active session (line
  136, checked by scanning `activeSessions.values()`, line 220-222).
- **Goal/function:** Zeroes the repair cost (line 140) and unconditionally overwrites the result slot with a
  green "Confirm" item showing the currently-typed rename text as lore (`getRenameText()`, lines 142-150) — per
  the extensive class javadoc, this only works reliably because `SECOND_INGREDIENT_SLOT` is deliberately kept
  empty (a real item there breaks vanilla's rename-validity computation entirely, per the documented live-testing
  finding at lines 34-47).
- **Feature allocation:** `inventory-menus`.

#### `onClick` — `InventoryClickEvent` (`AnvilCaptureManager.java:153-179`)
- **Trigger:** Clicking player has an active session whose tracked inventory matches `event.getInventory()`
  (lines 158-161).
- **Goal/function:** **Cancels every click unconditionally** (line 165, "Never allow taking/moving items"). Only
  reacts further if the click was in the top (anvil) inventory (lines 167-171): clicking `CONFIRM_SLOT` (slot 2)
  extracts the rename text and calls `complete(...)` (lines 173-175, 204-210 — strips color codes via
  `ChatColor.stripColor`, line 230, then deferred one tick via `Bukkit.getScheduler().runTask` to avoid
  reentrancy from closing an inventory inside its own click handler, per the inline comment lines 199-203);
  clicking `INPUT_SLOT` (slot 0, repurposed as Cancel per the class javadoc's documented history, lines 49-59)
  calls `cancel(...)` (lines 176-177, 212-218).
- **Feature allocation:** `inventory-menus`.

#### `onClose` — `InventoryCloseEvent` (`AnvilCaptureManager.java:181-197`)
- **Trigger:** Closing player has a session whose tracked inventory matches (lines 186-189).
- **Goal/function:** Removes the session and runs `session.onCancel()` next tick (lines 195-196) — the comment
  (lines 191-194) notes a successful Confirm/Cancel click already removed the session *before* closing the
  inventory, so reaching this handler at all means the close happened some other way (Escape key, etc.), making
  this a genuine cancel rather than a double-completion race.
- **Feature allocation:** `inventory-menus`.
- **Bugs/edge cases:** See cross-cutting finding #4 — no `PlayerQuitEvent` handler in this class; cleanup relies
  entirely on `InventoryCloseEvent` firing, which is not guaranteed in every disconnect scenario.

---

### 2.2 `MenuClickListener.java`

**Feature allocation:** `inventory-menus`.

**Status:** Finished, wired (`KnKPlugin.java:479-483`).

#### `onClick` — `InventoryClickEvent` (`MenuClickListener.java:70-161`)
- **Trigger:** Clicking entity is a `Player` with a registered `OpenMenuContext` (lines 72-79) whose tracked
  inventory equals `event.getView().getTopInventory()` (lines 81-87, explicitly guards against a stale context
  from an uncleanly-closed menu, per the inline comment).
- **Goal/function:** Cancels the click unconditionally (line 90, "Never allow taking, rearranging, or
  shift-clicking items into a KnK menu"). Requires a `MenuSession` to exist for the player, else logs a warning
  and bails (lines 92-96). Resolves the actually-clicked slot via `resolveClickedSlot` (lines 98, 176-189) —
  notably special-cases `ClickType.DOUBLE_CLICK`, whose `getClickedInventory()`/`getSlot()` are unreliable in
  Bukkit for a "gather" gesture, by instead reusing `MenuSession.getLastClickedSlot()` recorded from the
  player's immediately-preceding ordinary click. Looks up the `RuntimeMenuItem` at that slot from the last render
  (line 103); bails if none, or if `displayMode()` is `DISABLED`/`HIDDEN` (line 104). **Re-checks visibility**
  (`item.isVisibleTo(player::hasPermission)`, lines 108-113) and **action permission**
  (`item.isActionAllowedFor(player::hasPermission)`, lines 115-119) at click time — explicitly documented
  defense-in-depth against render-time state going stale before the click lands (class javadoc, lines 41-45).
  Special-cased shift-click shortcuts, checked *before* any condition/action evaluation: shift-clicking a
  search-prompt-bound item instead fires `SEARCH_CLEAR` (lines 142-145); shift-clicking a pagination
  next/prev-bound item instead jumps to `PAGE_FIRST` (lines 151-155). Otherwise runs `executeClick` (line 156,
  201-220): evaluates the item's own `conditions()` list first (all must pass, AND semantics, first denial wins
  and aborts *every* action on the item, lines 202-208); then, independently per action in `item.actions()`,
  evaluates that action's own `conditions()` (an action-level failure only skips that one action, not siblings,
  lines 210-217) before calling `actionRegistry.execute(...)`. A `MenuActionException` from any action is caught,
  logged, and surfaced to the player as a generic "Something went wrong with that." message (lines 157-160).
- **Feature allocation:** `inventory-menus`.
- **Bugs/edge cases:** The shift-click shortcut checks (lines 142,151) both key off `hasAction(item, ...)` —
  if a single menu item somehow had *both* a `SEARCH_PROMPT` action and a `PAGE_NEXT`/`PAGE_PREV` action bound
  (unlikely by design, but not structurally prevented), only the search-clear branch would ever fire on
  shift-click since it's checked first and returns immediately (line 145) — the pagination shortcut branch would
  be unreachable for that item. Low-likelihood edge case given normal menu authoring, not observed to occur in
  practice (menu template content not read — out of scope).

---

### 2.3 `MenuControlHintListener.java`

**Feature allocation:** `inventory-menus`.

**Status:** Finished, wired (`KnKPlugin.java:487-489`). Explicitly a "Post-Phase-8 QOL follow-up" per the class
javadoc (lines 17-38).

#### `onToggleSneak` — `PlayerToggleSneakEvent` (`MenuControlHintListener.java:47-65`)
- **Trigger:** Player has a registered `OpenMenuContext` (lines 50-53).
- **Goal/function:** Approximates "hold shift to reveal a tooltip's extra lines" — since Bukkit exposes no
  server-side "which slot is the mouse hovering" signal for arbitrary items (only for bundles natively, per the
  javadoc lines 19-22), this instead reacts to the *global* sneak toggle: for every slot with precomputed
  control-hint lore (`context.controlHintLoreBySlot()`, captured at the last render by
  `MenuRenderer.resolveControlHints`, not read here), it appends the hint lines to that slot's live `ItemStack`
  lore when sneaking starts, and strips them back off when sneaking stops (`toggleHints`, lines 67-94) — matched
  by comparing the lore's *trailing* entries against the known hint list (lines 78-79), so it never touches other
  lore (page count, active search/filter value, etc.), which stays exactly as the last real render left it. No
  re-render or data re-fetch occurs — pure client-visible lore mutation of the already-rendered `Inventory`.
- **Feature allocation:** `inventory-menus`.
- **Bugs/edge cases:** None found; this is a narrowly-scoped, well-documented cosmetic feature. One inherent
  limitation (acknowledged by the javadoc itself, not a bug): it reacts to sneak *toggling*, not to actual mouse
  hover, so hints for every hinted slot in the menu appear/disappear together on one shift-press rather than
  per-hovered-item — a known approximation, not a defect.

---

### 2.4 `MenuLifecycleListener.java`

**Feature allocation:** `inventory-menus`.

**Status:** Finished, wired (`KnKPlugin.java:484-486`). Explicitly framed in its own javadoc (lines 9-24) as the
fix for a specific v1 reconciliation gap (#4: "v1's static per-player maps that were never cleared and grew
without bound").

#### `onQuit` — `PlayerQuitEvent` (`MenuLifecycleListener.java:35-38`)
- **Goal/function:** Calls `menuService.closeSession(player.getUniqueId())` (line 37) — clears the player's
  `MenuSession` (core-layer: navigation history, per-section page, dirty flag) entirely on quit.
- **Feature allocation:** `inventory-menus`.

#### `onInventoryClose` — `InventoryCloseEvent` (`MenuLifecycleListener.java:40-51`)
- **Trigger:** Closing entity is a `Player` with a registered `OpenMenuContext` whose tracked inventory equals
  `event.getInventory()` (lines 42-47).
- **Goal/function:** Calls `openMenuContextRegistry.close(player.getUniqueId())` (line 48) — clears only the
  paper-side live `Inventory` reference, deliberately leaving the core `MenuSession` intact so reopening the menu
  later resumes exactly where the player left off (javadoc, lines 18-23), the same way any other in-menu
  navigation would.
- **Feature allocation:** `inventory-menus`.
- **Bugs/edge cases:** This class is the positive counter-example to cross-cutting finding #4 — it correctly
  handles *both* `PlayerQuitEvent` and `InventoryCloseEvent` for its own two registries, which is exactly the
  pattern `AnvilCaptureManager` is missing a `PlayerQuitEvent` half of.

---

## 3. Summary counts

- **19 listener classes** read in full (15 in `listeners/`, 4 named in `menu/`).
- **41 `@EventHandler` methods** total: 34 in `listeners/`, 7 in `menu/`.
- **19 of 19 listener classes confirmed registered** and reachable at runtime (13 direct `registerEvents` calls in
  `KnKPlugin.onEnable`/its `registerEvents(WorldGuardRegionTracker)` helper, 4 via `EnchantmentBootstrap`, 2 via
  the InventoryMenu block) — **no dead/unregistered listener class found**, unlike the command catalog's
  `WorldGuardManagementCommand` finding. One listener (`RegionTaskEventListener`) is registered conditionally on a
  handler-registry lookup succeeding, which is effectively always true at normal startup given current
  registration ordering, but is a latent fragility worth noting (§0, row for `RegionTaskEventListener`).
- **5 cross-cutting findings** documented in §0 (duplicate join welcome messages, unguarded double chat
  consumption, legacy-vs-modern chat event split, missing quit-cleanup in `AnvilCaptureManager`, blocking
  `.join()` calls in enchantment listeners) plus **per-listener bugs/edge cases** noted throughout §1–§2, most
  notably: `PlayerListener.onPlayerRespawn` is a confirmed **stub** (fetches town data, never uses it —
  `PlayerListener.java:300-320`), `PlayerListener.onItemPickup` is an unconditional, unscoped disable of item
  pickup for all non-OP players (`PlayerListener.java:322-328`), and `PlayerListener.onLeave` has a harmless
  duplicate `quitMessage(...)` call (`PlayerListener.java:199-200`).
