# v2 event-listener catalog (Bukkit/Spigot events)

> Companion to [commands-v2.md](commands-v2.md) and [events-v1.md](events-v1.md) — same purpose (fill the
> event-inventory gap left by the original legacy-spec-mining pass), same citation convention. See
> `commands-v1.md`'s header for the full rationale, and `user-system.md` for the citation style being matched.

## Methodology

Mined from `knk-v2-archive`, read directly from the absolute on-disk path
`C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-v2-archive` (the `Repository/knk-v2-archive`
checkout inside this isolated agent worktree is empty/untracked). Citation convention matches
`commands-v2.md`/`user-system.md`: `v2:src/main/java/net/knightsandkings/...:line`.

All 9 files under `src/main/java/net/knightsandkings/listeners/` were read in full, not excerpted:
`BlockListener.java`, `EntityListener.java`, `GenerationCommandListener.java`, `InventoryListener.java`,
`ItemListener.java`, `PlayerListener.java`, `ProjectileListener.java`, `RegionListener.java`,
`SelectionListener.java`.

**`Structure.java` verification.** `grep -r "implements Listener"` and `grep -r "@EventHandler"` over the whole
`src/main/java` tree both return exactly 10 files: the 9 listener classes above, plus
`net/knightsandkings/model/dominion/Structure.java`. `Structure` (`v2:src/main/java/net/knightsandkings/model/dominion/Structure.java:49`)
does `public class Structure extends Dominion implements Listener` — a real `org.bukkit.event.Listener`
(imported at `:13`), not a false-positive match on an unrelated "Listener"-named interface. However, **it has
zero live `@EventHandler` methods**: its only two handler methods, `onChestListChange(ChestListChangeEvent e)`
(`:618-630`) and `onConfirmation(ConfirmSelectionEvent<Item, Integer> e)` (`:646-693`), are both entirely
commented out. So `Structure` is technically a Bukkit listener class but registers no active event handlers —
it is **not documented below as a listener** (nothing to catalogue per-`@EventHandler`), but see the Bugs
section for a real side effect of the class still implementing `Listener` and still self-registering.

**Grep for stray listeners outside the `listeners` package.** Both greps above (`implements Listener` and
`@EventHandler`) returned the identical 10-file set — the 9 canonical listener classes plus `Structure.java`.
No other class anywhere in `src/main/java` declares `@EventHandler` methods or implements `Listener`, so there
is no scattered/stray listener to catalogue beyond what's already covered here.

Every method below was read from its full body (not just its signature/name) to describe what it actually does.
DTO/repository/DAO/WorldGuard-util classes referenced were not all opened in full — where behavior depends on
an external class's internals not read for this pass, it's marked "unclear/out of scope."

---

## 1. `BlockListener` — `net.knightsandkings.listeners.BlockListener`

### `onBreak(BlockBreakEvent e)` — `v2:...BlockListener.java:65-86`
- **Event / priority:** `BlockBreakEvent`, default priority, `ignoreCancelled` not set.
- **Trigger:** any block break by any player.
- **Goal:** Resolves the breaking `Player`'s `User` via `RepositoryManager...getRepository(User.class, UUID.class).getObjectById(...)` (`:69`). If no `User` found, error-messages the player and returns (`:71-74`). Looks up a `Warehouse` and a `Gate` at the broken block's location via `DominionDAL.getObjectByLocation(...)` (`:77-78`) — the `Warehouse` lookup result (`warehouse`) is **fetched but never used** (dead local variable, see Bugs). If a `Gate` is found and the block is inside `gate.isGateClosedRegion(...)`, calls `gate.damageGate(user, block)` and **cancels the break event** (`:79-83`) — i.e. breaking a closed gate's blocks damages the gate object instead of actually breaking the block.
- **Feature allocation:** `towns` (dominion/gate/warehouse interaction).
- **Bugs/edge cases:**
  - **Dead code / wasted lookup:** `Warehouse warehouse = ...getObjectByLocation(block.getLocation())` (`:77`) is computed on every single block break in the game (a DAO location query) and then never read again anywhere in the method — pure waste, and specifically the kind of "half-finished feature" pattern already flagged in `commands-v2.md` (e.g. the `Enderchest.check` dead branch). Possibly intended to guard warehouse blocks from being broken too, but that logic was never written.
  - A large `onGateHit(BlockDamageEvent e)` handler (`:38-63`) is fully commented out — an older gate-hit-on-punch mechanic superseded by (or duplicated with) the live `onBreak` gate-damage logic; dead code left in the tree, same pattern as several commented-out commands in `commands-v2.md`.
  - No `BlockPlaceEvent` handler anywhere in `BlockListener` (or any other v2 listener) — block placement inside dominion/town/gate regions is apparently left entirely to WorldGuard region flags, not custom KNK logic.

---

## 2. `EntityListener` — `net.knightsandkings.listeners.EntityListener`

### `onDamage(EntityDamageByEntityEvent e)` — `v2:...EntityListener.java:42-156`
- **Event / priority:** `EntityDamageByEntityEvent`, `@EventHandler(priority = EventPriority.HIGHEST)` (`:42`) — runs after other plugins, positioning KNK's PvP rules as close to authoritative/last-word as Bukkit allows at that priority.
- **Trigger:** any entity damaging another entity.
- **Goal:** When the damaged entity is a `Player` (`:50`): resolves `damagedUser` and their active `Siege` (`MinigameRepository<Siege>.getObjectByUser`, `:53-54`), and the WorldGuard `town` region at the damaged player's location (`:56-57`). If the damager is a `Projectile` (arrow), computes headshot via `isHeadshot(...)` (`:72`, body at `:176-181`) and **boosts damage 1.5x** on headshot (`e.setDamage(e.getFinalDamage()*1.5d)`, `:74`), then resolves the actual shooter as `damager` if it's a `Player` (`:76-81`). If a `damager` was found, resolves their `User` and `Siege` too (`:84-86`); otherwise logs a warning "No player found?!?" (`:88`) — this fires for any non-player damage source (e.g. mobs, dispensers, non-shooter projectiles).
  - **Siege PvP rules** (`:91-127`): if both damaged and damager are in the *same in-progress* siege, cancels damage and plays a warning sound if either combatant is standing in their team's "safe" spawn area (`:96-111`), and cancels + plays sound if the two `SiegeTeam`s are not enemies (`:113-119`, i.e. friendly fire inside a siege is blocked). Else, if the damage location is inside a `town` WorldGuard region, **all** damage there is unconditionally cancelled (`:121-126`) — a blanket in-town PvP-safe-zone rule.
  - **Headshot messaging + stat** (`:129-135`): if headshot and damage wasn't cancelled, sends "Headshot!"/"You got headshot!" messages and increments `damagerUser.getStatistics().addHeadshots(1)`.
  - **Item frame / armor stand protection** (`:138-148`): if the damaged entity is an `ItemFrame` or `ArmorStand` and the damager is a player without `k&k.owner` permission, cancels the event. Comment flags this as a known-temporary permission node: `//TODO Should be changed to OwnerMode` (`:142`).
  - **Damage stats** (`:149-154`): if not cancelled and a `damagedUser` was resolved, records `addDamageReceived`/`addDamageDealt` stats.
  - Finally unconditionally applies `e.setCancelled(cancelled)` (`:155`).
- **Feature allocation:** `siege-minigame` (PvP/safe-zone/headshot/kill-stat rules) + `towns` (in-town PvP-safe-zone) + `misc`/`world-admin` (item-frame/armor-stand griefing guard).
- **Bugs/edge cases:**
  - **Likely NPE:** `headShot` is computed purely from `damagerEntity instanceof Projectile` (`:68-82`) and is **independent** of whether a `Player` shooter was actually resolved. If a non-player entity fires a headshot-qualifying projectile (e.g. a dispenser-launched arrow, or a projectile whose `ProjectileSource` isn't an `Entity`/`Player`), `damager` stays `null` while `headShot` can still be `true`. At `:129`, `if (headShot && !cancelled) { damager.sendMessage(...)` then dereferences the possibly-null `damager` → NPE. This is the same "null target dereferenced without a guard" bug class already documented in `commands-v2.md`/`user-system.md` (`Enderchest.opCheck`).
  - `isHeadshot(Projectile a, Entity e)` (`:176-181`) declares a local `player_bodyheight = 1.35` that is **never used** — dead/leftover variable, and the actual geometry check (`projectileheight > bodyheight`, comparing projectile Y to target Y+1.33) is a crude approximation with no X/Z proximity check at all — any projectile simply *above* the target's head-height counts as a "headshot" regardless of horizontal distance. Flagged unclear/likely-buggy geometry, not confirmed exploitable without further gameplay testing.
  - The `//TODO Should be changed to OwnerMode` comment (`:142`) documents a known-temporary permission-node placeholder (`k&k.owner`) guarding item-frame/armor-stand protection — matches the "permission-node not-yet-finalized" pattern noted elsewhere in the codebase.

### `onDamage(EntityDamageEvent e)` — `v2:...EntityListener.java:158-174`
- **Event / priority:** `EntityDamageEvent`, default priority.
- **Trigger:** any damage to any entity (broader supertype than the `ByEntity` variant above — also fires for fall damage, fire, drowning, etc).
- **Goal:** If the damaged entity is a `Player` with a resolved `User`, and `e.getCause() == DamageCause.FALL`, records `user.getStatistics().addHighestFall(entity.getFallDistance())` (`:169-171`). No other cause is handled — the method is fall-damage-stat-tracking only, despite listening to the generic superclass event.
- **Feature allocation:** `users` (statistics tracking).
- **Bugs/edge cases:** None found; straightforward, though listening on the broad `EntityDamageEvent` for a single narrow cause is a minor inefficiency (fires for every single damage tick server-wide), not a correctness bug.

---

## 3. `GenerationCommandListener` — `net.knightsandkings.listeners.GenerationCommandListener`

### `onEvent(GenerationCommandEvent e)` — `v2:...GenerationCommandListener.java:45-143`
- **Event / priority:** custom `GenerationCommandEvent` (not a Bukkit core event), default priority.
- **Trigger:** fired whenever a production-structure "generation" tick/command completes (resource generation cycle for a `ProductionStructure`).
- **Goal:**
  - Broadcasts `e.getMessage()` to every subscriber UUID in the static `subscribers` set (`:39`, `:48-55`), pruning subscribers whose `User` can no longer be found in cache.
  - Pulls the `HandleGenerationDTO` off the event; bails with an error log if there's no generator instance, no producer dominion id, or the commodity isn't an `ItemCommodityDTO` (`:57-72`).
  - If no `StorageDTO` was supplied on the event and the generation's delivery type is `PUT_IN_STORAGE`, fetches the `StorageDTO` from the DAO by id (`:76-85`).
  - Computes `capacityPercentage` = current commodity capacity / storage max capacity *100 (`:86-88`). If that percentage is **at or above** `instance.getTransportThreshold()`, looks up any existing planned/immediate `TransportOrder` for the producer (`:90-107`), builds a `TransportPreperationCommand` with a 5-minutes-from-now planned execution date (`:111-119`), executes it, assigns the resulting order back onto the producer (`:120`), then **saves the order to the repository/DB and immediately evicts it from cache-only** (`repo.saveObject(order); repo.deleteObject(order, SaveMode.ONLY_CACHE)`, `:128-129`) before also saving the producer. Notifies all subscribers of the created/altered transport order (`:136-139`).
  - Below threshold, just logs an error-level "Threshold not reached" message (`:141`) — arguably mis-leveled (not really an error condition, just a normal no-op case), a minor logging-severity nit.
- **Feature allocation:** `towns` (dominions/structures/generation/storage/transport — the production→storage→transport pipeline).
- **Bugs/edge cases:**
  - **Possible NPE:** if `storage` ends up `null` after the `if (storage == null && ...)` branch (`:76-85`) — which only assigns it when the delivery type is specifically `PUT_IN_STORAGE`; for any other `GenerationDeliveryType`, `storage` stays whatever was passed on the event, which can be `null` if the caller didn't populate `StorageDTO` — the very next lines unconditionally call `storage.getCapacityMax()` / `storage.getCapacity(commodity)` (`:86-87`) with no null guard. This mirrors the "null dereference not guarded" bug class flagged in `EntityListener` above and in `commands-v2.md`.
  - **Possible NPE:** the subscriber-notification loop at `:137-139` calls `Bukkit.getPlayer(uuid).sendMessage(...)` directly, with no null-check on the `Bukkit.getPlayer(uuid)` result — if a subscriber has logged off between subscribing and this generation event firing, this throws. Contrast with the identical-purpose loop earlier in the same method (`:48-55`) which correctly resolves the subscriber's cached `User` object and skips/removes it if not found — the two subscriber-broadcast code paths in the same method use inconsistent null-safety.
  - Save/evict-from-cache sequencing (`:128-129`) is unusual (persist then immediately purge from cache) — flagged as a curious pattern worth a second look by someone who knows the caching layer's intended lifecycle, not confirmed as a bug.
  - Broad catch-and-`printStackTrace()`-and-continue handling around the `TransportOrder` lookup (`:92-103`) swallows three distinct exception types without any user-facing feedback if the lookup silently fails — same "print and move on" error-handling style flagged elsewhere in the codebase.

---

## 4. `InventoryListener` — `net.knightsandkings.listeners.InventoryListener`

### `onClick(InventoryClickEvent e)` — `v2:...InventoryListener.java:32-70`
- **Event / priority:** `InventoryClickEvent`, default priority.
- **Trigger:** any inventory click where `e.getSlot() >= 0` (guards out clicks outside any slot, e.g. clicking the border/outside-inventory area, `:34-36`).
- **Goal:** Resolves the clicking `Player`'s `User` (error-messages + returns if not found, `:41-44`). Looks up the player's active `MenuSession` (`:49`); if there's no session, or the session's currently-displayed menu's `Inventory` isn't the one that was clicked, does nothing (`:50-52`) — i.e. only intercepts clicks inside KNK's own custom menu GUIs, not arbitrary inventories. Otherwise resolves the clicked `MenuItem` via `new FindMenuItemCommand(user, e).call()` (`:55`), and if found, resolves its `MenuItemAction` for the specific click type (`e.getClick()`) and runs it (`:56-61`). Exceptions are caught and stack-traced only (`:63-68`) — no cancellation of the click and no user feedback on error.
- **Feature allocation:** `inventory-menus`.
- **Bugs/edge cases:**
  - **No `e.setCancelled(true)`** anywhere in this handler — clicking inside a KNK menu GUI does not, by itself, prevent the normal Bukkit inventory-click item-movement behavior (picking up/placing items) unless whatever `MenuItemAction.runAction(...)` does happens to cancel it internally (not traced — out of scope of this listener). If none of the menu actions cancel the event, players could drag items out of/into decorative menu slots. Flagged unclear/out of scope — would need to read `MenuItemAction` implementations to confirm.
  - Both catch blocks (`CommandException`, generic `Exception`) are marked `// TODO Auto-generated catch block` and only `printStackTrace()` — no message sent to the clicking player when menu-action execution fails, so an error is silent from the player's perspective.

### `onClose(InventoryCloseEvent e)` — `v2:...InventoryListener.java:72-106`
- **Event / priority:** `InventoryCloseEvent`, default priority.
- **Trigger:** any inventory close.
- **Goal:** Resolves the closing `Player`'s `User` (error-messages + returns if not found, `:77-80`). If there's no active `MenuSession` for the user, or the session's displayed menu's inventory doesn't match the one closed: checks the static `Enderchest.EC_VIEW` map (`:86-92`) — if the closing user was viewing another player's enderchest (per the `/enderchest open` command in `commands-v2.md`), saves the viewed target player's data (`target.saveData()`) and removes the view-tracking entry, then returns. Otherwise (the closed inventory *is* the user's active menu), resolves the cached `MenuDisplayed` for that user/inventory and, if it matches the session's current menu by id, calls `menuSession.changeCurrentMenu(null)` (`:96-104`) to clear the session state.
- **Feature allocation:** `inventory-menus` + `users` (enderchest-view cleanup, cross-references `Enderchest.EC_VIEW`, `v2:...spigot/command/user/Enderchest.java`).
- **Bugs/edge cases:** Broad catch-all `Exception` around the menu-session cleanup block (`:102-104`), stack-trace only, no user feedback — consistent with the error-handling style seen elsewhere. No other issues found; this is a reasonably careful handler (does null-check both the user and the session/menu-displayed lookups before dereferencing).

---

## 5. `ItemListener` — `net.knightsandkings.listeners.ItemListener`

### `onDrop(PlayerDropItemEvent e)` — `v2:...ItemListener.java:13-24`
- **Event / priority:** `PlayerDropItemEvent`, default priority.
- **Trigger:** a player drops an item with a custom display name (`item.hasItemMeta() && item.getItemMeta().hasDisplayName()`).
- **Goal:** Sets the dropped item entity's custom name (`entity.setCustomName(display)`) and makes it visible (`setCustomNameVisible(true)`) so the floating item entity shows its display name in the world, mirroring the item's in-inventory name.
- **Feature allocation:** `items`/`kits` (cosmetic — named-item visual polish).
- **Bugs/edge cases:** None found; simple and correct for its stated purpose.

### `onSpawn(ItemSpawnEvent e)` — `v2:...ItemListener.java:26-37`
- **Event / priority:** `ItemSpawnEvent`, default priority.
- **Trigger:** any item entity spawning in the world with a custom display name (same guard pattern as `onDrop`).
- **Goal:** Identical custom-name/visibility logic as `onDrop`, but for **all** item-entity spawns (not just player-initiated drops) — e.g. items spawned from a broken block, structure destruction, or plugin-generated loot.
- **Feature allocation:** `items`/`kits` (cosmetic).
- **Bugs/edge cases:** **Redundant with `onDrop`** — a player-dropped named item fires *both* `PlayerDropItemEvent` and `ItemSpawnEvent` (drop-triggered spawns fire both events in Bukkit), so the exact same custom-name-setting code runs twice for every player-dropped named item. Harmless (idempotent — setting the same name/visibility twice has no observable effect) but duplicate work; the two handlers could be collapsed into one `ItemSpawnEvent`-only handler.

---

## 6. `PlayerListener` — `net.knightsandkings.listeners.PlayerListener`

### `onLogin(PlayerLoginEvent e)` — `v2:...PlayerListener.java:68-88`
- **Event / priority:** `PlayerLoginEvent`, default priority.
- **Trigger:** any player login attempt.
- **Goal:** Asynchronously (`runTaskAsynchronously`) looks up the `User` by UUID; if none exists, **creates and saves a brand-new `User`** (`:79-83`) with default cash (`User.CASH_DEF`) and IP address info. Then calls `user.login(player, address)` (`:85`) regardless of whether the user was pre-existing or freshly created.
- **Feature allocation:** `users` (account creation/login bootstrapping).
- **Bugs/edge cases:**
  - Runs the entire user-lookup-and-creation flow **asynchronously off the main thread** inside a `PlayerLoginEvent` handler — `PlayerLoginEvent` is normally the place to *synchronously* allow/deny login (e.g. via `e.disallow(...)`); doing DB/Hibernate work asynchronously here means the event itself can't be blocked/denied based on the outcome of that async work (e.g. if `saveObject` fails), and there's a race with `PlayerJoinEvent` (below) firing shortly after — `onJoin` re-fetches the `User` synchronously and if the async creation from `onLogin` hasn't completed yet, `onJoin` could see `user == null` and kick the (now-actually-registered) player with the "Something went wrong" message (`:113-116`), which would be a confusing false-negative first-join kick. Flagged as a real async-ordering risk, not confirmed to reproduce without live testing.

### `onJoin(PlayerJoinEvent e)` — `v2:...PlayerListener.java:90-145`
- **Event / priority:** `PlayerJoinEvent`, default priority.
- **Trigger:** player join, after `onLogin`.
- **Goal:** Suppresses the default join message (`e.setJoinMessage(null)`, `:95`). Re-fetches the `User`; if not found, tracks a `UserLoginError` (creating one if none exists, incrementing/reading `loginAttempts`), saves it, logs an error, and kicks the player with a diagnostic message including attempt count (`:97-124`) — see async race note above. On success: attaches the live `Player` to the `User` (`:125`), sets a custom join message with a welcome-back or welcome-new-player greeting including current cash (`:126-132`), and — **unless** the player has `k&k.join.owner` — forces `GameMode.SURVIVAL`, disables flight, and teleports them to **`(Town) ...getRepository(Town.class,...).getList().get(0)`**, i.e. hard-codes teleporting every non-owner joining player to whichever `Town` happens to be first in the repository's list, falling back to the default world's spawn if that list is empty (`:134-143`). Finally updates the scoreboard (`ScoreboardUtil.setScoreboard`, `:144`).
- **Feature allocation:** `users` (spawn/greeting/gamemode reset) + `towns` (town-spawn teleport).
- **Bugs/edge cases:**
  - **`get(0)` on the `Town` list with no deterministic ordering guarantee** — every joining player who isn't an owner is sent to "the first town returned by the repository," which depends entirely on Hibernate/list insertion order rather than any explicit "capital"/"spawn town" designation. Same unindexed-first-element pattern recurs at `respawn(PlayerRespawnEvent e)` below (`:370`) — worth flagging as a design smell (no explicit spawn-town concept) even though it's not a crash-bug by itself.
  - The `UserLoginError`-tracking branch (`:97-124`) computes `attempts` from `loginError.getLoginAttempts()` only inside the `if (loginError != null)` branch, then references `attempts` in the kick message outside that branch (`:113-116`) via a null-conditional inline check (`attempts != null ? ... : null`) — this is defensively written and not itself buggy, but note the kick message can end up with a literal string `"null"` appended if `attempts` stays null (Java string concatenation of `null` — cosmetic issue, not a crash).

### `onLogout(PlayerQuitEvent e)` — `v2:...PlayerListener.java:147-159`
- **Trigger:** player disconnect.
- **Goal:** Fetches the `User`, calls `user.logout()`, saves via `SaveMode.ONLY_DAO` (DB write, skip cache-only path since the user object is about to be discarded), sets a custom quit message.
- **Feature allocation:** `users`.
- **Bugs/edge cases:** **No null-check on `user`** before calling `user.logout()` (`:156`) — every other handler in this class (and most others in the codebase) guards with `if (user == null) { ...return; }` before dereferencing; this one doesn't, so if a `User` genuinely can't be resolved on quit (e.g. the async `onLogin` creation race noted above never completed, or DB hiccup), this throws an NPE on every subsequent quit-handling logic for that player. Matches the "missing null-guard before dereference" bug class already called out multiple times in `commands-v2.md`/`user-system.md`.

### `onCommand(PlayerCommandPreprocessEvent e)` — `v2:...PlayerListener.java:161-186`
- **Event / priority:** `EventPriority.HIGHEST`.
- **Trigger:** any slash command typed by a player, before it's dispatched.
- **Goal:** If the player has an active `Creation` "creation wizard" session (`commands-v2.md`'s edit-flow mechanism), routes the raw command text through `creation.processEvent(e)` and uses its return value to decide whether to cancel the real command dispatch (`:166-173`) — i.e. while inside a creation wizard, typed text can be intercepted as wizard input instead of a real command. Separately, blocks `/help`, `/plugins`, `/pl`, `/plugin`, `/v`, `/version` for anyone without `k&k.owner` (`:175-185`) — an information-hiding measure (presumably to stop players from seeing the installed plugin list).
- **Feature allocation:** `users`/`world-admin` (info-hiding) + `towns` (Creation wizard hook, cross-domain since `Creation` wraps dominion/town/etc. edit flows).
- **Bugs/edge cases:** None found in this method itself; behavior is straightforward given its two purposes. (The `Creation.processEvent` internals were not read — out of scope.)

### `onChat(PlayerChatEvent e)` — `v2:...PlayerListener.java:188-234`
- **Event / priority:** `EventPriority.HIGHEST`.
- **Trigger:** any player chat message.
- **Goal:** Same `Creation` wizard interception as `onCommand` (`:194-201`). Capitalizes the first letter of the message and applies `&`-color-code translation (`:203-206`). Formats the chat line differently for owners (`k&k.owner`) vs default players via `ColorOptions` templates (`:207-216`) — note both branches have a commented-out title-name segment (`//+ "-{"...user.getTitleName()...`) left in place, dead/disabled cosmetic feature. Asynchronously scans all cached users for a name-mention (case-insensitive substring match of any user's name inside the chat message) and plays a "ping" sound to every mentioned user other than the sender (`:218-232`).
- **Feature allocation:** `users` (chat formatting + mention-ping).
- **Bugs/edge cases:**
  - **Substring mention matching, not word-boundary matching:** `e.getMessage().toLowerCase().contains(u.getName().toLowerCase())` (`:225`) means any username that is a substring of *any other word* in the chat message triggers a ping — e.g. a user named "Al" would be pinged by the word "Always" appearing in someone else's message. Minor false-positive-prone logic, not a crash.
  - **Possible NPE:** `u.getPlayer().playSound(...)` (`:227`) is called for every cached `User` whose name substring-matches, with no null-check that `u.getPlayer()` is actually online/non-null — `repo.getList(FetchMode.ONLY_CACHE)` (`:224`) plausibly includes users who are cached but currently offline (their live `Player` reference would be null/stale), which would NPE inside the async task. Same missing-null-guard pattern as elsewhere in this class.

### `onInteract(PlayerInteractEvent e)` — `v2:...PlayerListener.java:236-280`
- **Event / priority:** `EventPriority.HIGHEST`.
- **Trigger:** right-click (air or block) with main hand.
- **Goal:** If holding an `ENCHANTED_BOOK` with item meta whose display name resolves to a real `Enchantment` (via `Enchantment.getByKey(NamespacedKey.minecraft(...))`, `:248-249`), opens a `PlayerEnchantMenu` (an item-selection menu to pick what to enchant) and cancels the interact event (`:252-261`); catches `PersistenceException` with a user-facing error message. Else, if right-clicking a block, looks up a `Gate` at that location and, if `gate.passThrough()` succeeds, sends a "Passing through gate" message (`:265-272`) — note `passThrough()`'s own internal logic (open/close/cooldown/permission checks) was not read, out of scope. Finally, regardless of the above, if the user has an active `RegisterSession` (item registration flow), forwards the raw interact event to it via `session.onInteract(e)` (`:274-277`).
- **Feature allocation:** `items`/`kits` (enchant menu, register session) + `towns` (gate pass-through).
- **Bugs/edge cases:** None directly found in this method (it null-checks `mainHand` before use, and the enchant-menu path is wrapped in try/catch). The `//TODO` explicit dead-code segment noted in `EntityListener` doesn't appear here, but note this method mixes three unrelated concerns (enchanting, gates, item-registration) in one handler — organizational smell, not a functional bug.

### `onDeath(PlayerDeathEvent e)` — `v2:...PlayerListener.java:282-320`
- **Event / priority:** `EventPriority.HIGHEST`.
- **Trigger:** any player death.
- **Goal:** Logs the death with the killer's name (`:286`). Resolves both the dying `User` and (if present) the `killer`'s `User`. If dying user is unresolved, error-messages and returns — **but this happens after the killer-name log line already ran** (see Bugs). If both players are in the *same* in-progress `Siege`, announces the kill to all siege members and increments `killerMember.addKill()` / `member.addDeath()` (`:301-310`); regardless of siege status, if there was a killer, increments `userKiller.getStatistics().addKills(1)` (`:313`); otherwise (no killer, e.g. environmental death) sends the dying user a "You died" message (`:315`). Always increments the dying user's death stat (`:317`), zeroes dropped XP (`:318`), and sets a null (suppressed) death message (`:319`).
- **Feature allocation:** `siege-minigame` (kill/death tracking) + `users` (general death stats).
- **Bugs/edge cases:**
  - **Confirmed NPE on environmental/non-player deaths:** `Player killer = player.getKiller()` (`:285`) is **not null-checked** before `killer.getName()` is used in the log line at `:286` — `getKiller()` returns `null` for any non-PvP death (fall damage, lava, mobs, drowning, etc.), which is by far the more common death case. This throws an NPE on essentially every non-PvP player death, **before** the method even reaches its own `user == null` guard at `:292-295`. This is a clear, high-confidence bug of the exact "unguarded dereference of a legitimately-nullable getter" class flagged repeatedly in `commands-v2.md`.
  - `deathMSG` (`:290`) is declared and never assigned before being passed to `e.setDeathMessage(deathMSG)` (`:319`) — always `null`, meaning death messages are unconditionally suppressed; appears intentional (custom-death-message system not implemented / disabled) rather than accidental, but flagged since it reads like a stub.
  - Two commented-out `user.sendMessage(...)`/`userKiller.sendMessage(...)` lines (`:311-312`) sit directly above the live `userKiller.getStatistics().addKills(1)` call — leftover dead code, consistent with the pattern elsewhere.

### `respawn(PlayerRespawnEvent e)` — `v2:...PlayerListener.java:322-371`
- **Event / priority:** `EventPriority.HIGHEST`.
- **Trigger:** player respawn.
- **Goal:** If the user is in an in-progress siege, respawns them at their `SiegeMember`'s current spawnpoint (`:339`), and if their team has multiple spawnpoints or unclaimed objectives, opens a `SpawnpointOverview` menu one second later (`runTaskLater(..., 1*20)`) to let them pick a different spawn (`:340-355`). Otherwise, respawns at **`(Town) ...getRepository(Town.class,...).getList().get(0)`** — the same first-town-in-list pattern as `onJoin` (`:370`).
- **Feature allocation:** `siege-minigame` (spawnpoint selection) + `towns` (default-town respawn).
- **Bugs/edge cases:** Same `get(0)`-on-town-list design smell as `onJoin`, cited once above, recurring here (`:370`). No `List.isEmpty()` guard before `.get(0)` in either occurrence — if the `Town` repository is ever empty (fresh install, all towns deleted), both `onJoin` and `respawn` throw `IndexOutOfBoundsException`. Large block of alternate commented-out spawnpoint-menu code (`:357-366`) left in place, same dead-code pattern noted throughout this catalog.

### `onPickup(PlayerPickupItemEvent e)` — `v2:...PlayerListener.java:373-394`
- **Trigger:** player picks up a dropped item.
- **Goal:** If the picked-up item belongs to a siege (`repo.getObjectByItem(item)` — presumably siege-flag/objective items), and the picking-up player isn't in that same siege, **cancels the pickup**; if they are in that siege, calls `siege.removeDroppedItems(item)` to clear it from the siege's tracked dropped-items list (`:387-392`).
- **Feature allocation:** `siege-minigame` (objective-item pickup gating).
- **Bugs/edge cases:** None found; straightforward and appropriately null-guarded (`user == null` check at `:379-382` before use).

### `onMove(PlayerMoveEvent e)` — `v2:...PlayerListener.java:396-411`
- **Trigger:** any player movement where the destination block differs from the origin block (X/Y/Z block-coordinate comparison, `:405-407` — i.e. not fired on pure look/head-rotation-only movement).
- **Goal:** Increments `user.getStatistics().addDistanceTraveled(1)` by a flat `1` per qualifying move event, **not** actual distance moved.
- **Feature allocation:** `users` (statistics tracking).
- **Bugs/edge cases:** **Statistic doesn't measure what its name implies** — `addDistanceTraveled(1)` always adds exactly `1` regardless of how far the player actually moved between the two locations (could be one block or, in theory with lag/teleport-adjacent movement, much further); a per-move-event counter mislabeled as "distance traveled." This is a data-quality bug for any feature relying on that stat (leaderboards, achievements, etc.) rather than a crash bug — flagged as unclear-severity but worth noting given `commands-v2.md`'s precedent of catching subtly-wrong stat/goal implementations. `PlayerMoveEvent` also fires extremely frequently (multiple times per second per moving player) with no throttling — a performance consideration, not a correctness bug.

---

## 7. `ProjectileListener` — `net.knightsandkings.listeners.ProjectileListener`

### `onHit(ProjectileHitEvent e)` — `v2:...ProjectileListener.java:44-83`
- **Event / priority:** `ProjectileHitEvent`, default priority.
- **Trigger:** any projectile hitting an entity or block.
- **Goal:** Only handles `Arrow` projectiles (`:50`); if the shooter is a `Player`, resolves their `User` (error-messages + returns if not found, `:57-60`) and increments `addArrowsFired(1)` (`:61`) — note this fires on **hit**, not on shot, so the stat name is really "arrows landed," not "arrows fired" (naming mismatch, similar class of issue to `onMove`'s distance stat above). If the arrow hit a block, looks up a WorldGuard `"gate"` region at that block and, if found, resolves the `Gate` dominion object and — mirroring `BlockListener.onBreak` — calls `gate.damageGate(user, block)` if the gate is in its closed-region state (`:62-75`). **Every arrow, regardless of any of the above, is removed from the world** (`arrow.remove()`, `:78`) — i.e. arrows never persist as pickup-able entities after impact.
- **Feature allocation:** `towns` (gate damage-by-arrow) + `users` (arrow-fired/landed stat) + `misc` (arrow despawn-on-hit policy).
- **Bugs/edge cases:**
  - **Stat naming mismatch:** `addArrowsFired` (`:61`) is incremented in a *hit* handler, not a shot handler — there is no `EntityShootBowEvent` listener anywhere in the 9 listener classes, so this stat actually measures "arrows that hit something (entity or block) while shot by a player," not arrows fired — an arrow that flies off into the void and never hits anything is never counted. Same class of stat-mislabeling issue as `PlayerListener.onMove`'s distance-traveled counter.
  - `arrow.remove()` runs unconditionally for every arrow hit, even ones that never entered any gate/region logic — appears to be an intentional "no arrow pickup" design choice, not a bug, but worth surfacing since it's a global gameplay policy tucked inside what reads like a gate-damage handler.

---

## 8. `RegionListener` — `net.knightsandkings.listeners.RegionListener`

### `onEntered(RegionEnteredEvent e)` — `v2:...RegionListener.java:25-61`
- **Event / priority:** custom WorldGuard-bridge event (`net.raidstone.wgevents.events.RegionEnteredEvent`, a third-party WG-events library, not core Bukkit), default priority.
- **Trigger:** a player entering any WorldGuard region.
- **Goal:** Asynchronously looks up dominion entry information for the entered region by name via `DominionDAO.getEntryInformationByRegionName(...)` (`:35`), which returns an `Object[]` where `[0]` is (unclear/out of scope — likely a display name) and `[1]` is a `boolean` allow/deny flag. If entry info exists, resolves the entering `User` and sends either an allow-entry message (`Dominion.RG_ENTER_MSG_DEF`) or a deny-entry message (`Dominion.RG_ENTER_DENY_MSG_DEF`) with the dominion's name substituted in via string replace of the literal `"a Dominion"` placeholder (`:41-44`), then sets `e.setCancelled(...)` to actually block entry if denied.
- **Feature allocation:** `towns` (dominion boundary entry gating/messaging).
- **Bugs/edge cases:**
  - **String-replace-based templating is fragile:** `Dominion.RG_ENTER_MSG_DEF.replace("a Dominion", (String)entryInfo[0])` (`:41`) only works correctly if the template string contains the *exact* literal substring `"a Dominion"` (case-sensitive) — any future edit to that constant's wording that doesn't preserve that exact phrase silently breaks the name substitution (the message would just keep saying "a Dominion" literally, or if the phrase appears elsewhere in the template, replace the wrong occurrence). Fragile-by-construction, not a live bug given the current constant strings (not fully verified — `Dominion.RG_ENTER_MSG_DEF`'s exact text wasn't opened in this pass — flagged unclear/out of scope for full confirmation).
  - No null-check on the resolved `User` (`e.getPlayer()` → `getObjectByPlayer`, `:37`) before `user.sendABMessage(...)` at `:41`/`:43` — if a player enters a region before their `User` is resolvable (e.g. very early in the login/join sequence, or a related timing issue to the `onLogin`/`onJoin` async race flagged in `PlayerListener`), this would NPE.
  - `entryInfo[1]` is cast directly to `boolean` (`(boolean)entryInfo[1]`, `:40`) from an `Object[]` — brittle by construction (relies entirely on `DominionDAO` always returning that exact tuple shape); not confirmed broken, but a fragile contract between DAO and listener with no type-safety.

### `onLeft(RegionLeftEvent e)` — `v2:...RegionListener.java:63-101`
- **Trigger:** a player leaving any WorldGuard region.
- **Goal:** Mirrors `onEntered` — resolves `User` first this time (`:70`, no null-check before eventual use), looks up exit info by region name, and sends allow/deny-leave messages, cancelling the leave if denied. If `exitInfo` is `null` (no dominion info found for that region), falls through to send a **generic** `Dominion.RG_LEAVE_MSG_DEF` with no name substitution at all (`:97`) — i.e. every region-leave-with-no-dominion-match still gets a leave message, which is inconsistent with `onEntered`'s behavior of doing nothing at all when `entryInfo` is null.
- **Feature allocation:** `towns`.
- **Bugs/edge cases:**
  - **Asymmetric null-info handling vs `onEntered`:** `onEntered` silently no-ops when `entryInfo == null` (no message sent at all when there's no dominion match for the region); `onLeft` instead falls through to send the raw, non-personalized `RG_LEAVE_MSG_DEF` message for *every* region a player leaves that has no dominion match — this means players get a generic "you left [nothing]" style message on leaving essentially any non-dominion WorldGuard region (e.g. a WorldGuard-protected area unrelated to KNK's dominion system), which is very likely unintended noise. This looks like a copy-paste-and-diverge bug between the two near-identical handlers.
  - Same unguarded `User` null-dereference and same fragile `(String)`/`(boolean)` `Object[]` casting concerns as `onEntered`.

---

## 9. `SelectionListener` — `net.knightsandkings.listeners.SelectionListener`

### `onConfirmation(ConfirmSelectionEvent<Item, Integer> e)` — `v2:...SelectionListener.java:27-61`
- **Event / priority:** custom `ConfirmSelectionEvent<Item, Integer>` (KNK-internal, not core Bukkit), default priority.
- **Trigger:** a player confirms an item-selection UI flow that targets a `Storage` (i.e. `e.getStorage() != null`, `:33`).
- **Goal:** Re-fetches the target `Storage` fresh from the repository by id (`:34`), throwing a `RuntimeException` if it can no longer be found (`:36-38`) — an intentional hard-fail rather than a soft error message. Asynchronously iterates the confirmed selection map and calls `storage.addStorageItem(item, amount)` for each entry (`:43-53`), catching (and only logging + user-messaging, not re-throwing) any per-item failure with a partial-progress message ("Added items: X/Y"). Finally always calls `MenuUtil.closeMenu(user, false)` (`:59`) regardless of whether `e.getStorage()` was null or the loop succeeded/failed.
- **Feature allocation:** `towns` (structure storage) + `inventory-menus` (selection/confirm UI flow).
- **Bugs/edge cases:**
  - **Shadowed exception variable:** inside the `catch (Exception e)` block at `:48`, the caught exception is named `e` — **identical to the enclosing method's own `ConfirmSelectionEvent<Item, Integer> e` parameter** (`:28`). Java allows this because the catch block is a new scope, but it means the outer `e` (the event object) is inaccessible by that name inside the catch block, and any future edit to that catch block that tries to reference the *event* `e` would actually silently reference the *exception* instead (or fail to compile if the exception's type doesn't support whatever's called) — a real footgun/readability bug, matching the kind of copy-paste/naming-collision issue class documented in `commands-v2.md` (e.g. `ALIAS`/`PERM` copy-paste errors), just manifesting as variable shadowing here instead.
  - `items.indexOf(item)` used in the partial-failure message (`:51`) computes the index from the **outer** `items` list (`e.getSelection()`, a `List<SelectItem<...>>`) using `item` (a raw `Item` key from `e.getSelectionMap().keySet()`) — these are different element types (`SelectItem<Item,Integer>` vs `Item`), so `indexOf` would need `SelectItem.equals(Object)` to somehow match against a bare `Item`, which is very unlikely to be implemented that way; `indexOf` almost certainly always returns `-1` here, making the "X/Y added" progress count in the error message wrong/meaningless. Flagged as a likely-broken diagnostic message, not confirmed without reading `SelectItem`'s `equals()` (out of scope for this pass).
  - No null-guard on `user` before `user.sendMessage(...)` inside the per-item catch block (`:51`) — `user` comes from `e.getUser()` (`:31`) with no null-check anywhere in the method; unclear/out of scope whether `ConfirmSelectionEvent` guarantees a non-null user by construction.

---

## `Structure.java` — not a catalogued listener, but a real side effect

`Structure` (`v2:src/main/java/net/knightsandkings/model/dominion/Structure.java:49`) `implements Listener`
with an **instance initializer block** that unconditionally self-registers with Bukkit's plugin manager on
every construction:

```java
{
    Bukkit.getPluginManager().registerEvents(this, KNK.getPlugin());
}
```
`v2:...Structure.java:135-137`

Since `Structure` is a Hibernate `@Entity` (`:46`), this initializer runs **every time Hibernate constructs a
`Structure` instance** — i.e. on every row load from the database, not just on some singleton/manager object.
Given that its only two `@EventHandler` methods (`onChestListChange`, `onConfirmation`) are both fully
commented out (`:618-630`, `:646-693`), every one of these registrations adds a listener object to Bukkit's
internal per-event handler lists with **zero live handlers to invoke** — functionally inert today, but still a
real per-entity Bukkit `registerEvents` call with no corresponding `unregisterEvents`/`HandlerList.unregister`
anywhere found in this file, meaning each loaded `Structure` row leaves a permanent, never-cleaned-up listener
registration for the life of the server process. Not a crash bug, but a legitimate memory/registration-table
bloat concern worth flagging given how central `Structure` is to the `towns` domain (every warehouse,
production structure, etc. is a `Structure` subtype). This is exactly the kind of "commented-out dead branch
still has a live side effect" finding `commands-v2.md`'s methodology note calls out for the `Enderchest.opCheck`
case — same shape, different mechanism (self-registration overhead instead of a reachable NPE).

---

## v1 → v2 listener-domain comparison (brief)

This is scoped narrowly to the *listener/event-handling surface* only, and is inferred from what domains v2's
9 listener classes do and don't cover (block/entity/generation/inventory/item/player/projectile/region/
selection) — it does not come from reading v1's `src/Listeners/`, `src/Skills/`, `src/Currency/`, `src/Menu/`
source directly in this pass (that's the parallel v1 event-mining effort's job); treat this list as "domains v1
is known to have had dedicated systems for, per the task brief, that have no visible event-listener equivalent
anywhere in v2's 9 classes."

- **Currency/economy** — no listener class or `@EventHandler` method anywhere in v2 touches an economy/currency
  system at all (only `User.CASH_DEF`/`getCash()` appear, inside `PlayerListener`'s join-greeting message,
  `:129,131` — cash is *displayed*, never earned/spent via any event hook). v1's `src/Currency/` domain has no
  v2 listener-side equivalent found.
- **Skills** — no skill/XP/ability/leveling event handling anywhere in the 9 v2 listener classes. v1's
  `src/Skills/` domain has no v2 listener-side equivalent found.
- **Dedicated Menu event system** — v2 folds all menu interaction into `InventoryListener`'s generic
  `InventoryClickEvent`/`InventoryCloseEvent` handling (delegating to `MenuItem`/`MenuItemAction`), rather than
  a menu-domain-specific listener class the way v1's `src/Menu/` suggests. Not necessarily a *gap* (the
  functionality may well be present via the generic inventory-event route) but it's architecturally collapsed
  into one class instead of a dedicated domain, unlike v1's apparent separation.
- **Block placement** — v2's `BlockListener` only has a live `BlockBreakEvent` handler; there is no
  `BlockPlaceEvent` handler anywhere in the 9 classes, so any v1 build-placement-related listener logic (if
  present in `src/Listeners/`) has no obvious v2 equivalent.
- **Bow-shoot tracking** — v2 tracks "arrows fired" only on `ProjectileHitEvent` (see `ProjectileListener` bug
  note above), with no `EntityShootBowEvent` handler; if v1 had shot-based (not hit-based) archery tracking,
  that's a behavior gap, not just a missing class.
- **Vehicle/weather/world-generation events** — none of the 9 v2 classes touch `Vehicle*Event`, weather events,
  or chunk/world-generation Bukkit events at all; unclear whether v1's broader `src/Listeners/` tree covered
  any of these — flagged as a gap only if v1 turns out to have had them (out of scope to confirm here).
