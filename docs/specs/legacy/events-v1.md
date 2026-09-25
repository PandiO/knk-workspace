# v1 event-listener catalog (Bukkit/Spigot events)

Mined from `knk-v1-archive` — companion to [commands-v1.md](commands-v1.md), same citation
convention (`v1:src/Path/File.java:line`), same principles (verbatim-only, marked gaps, no
invention — see [README.md](README.md)).

## Why this doc exists

`commands-v1.md` closed the gap around player/admin-*typed* commands. It didn't cover the other
half of v1's behavior surface: classes implementing `org.bukkit.event.Listener` with
`@EventHandler` methods, which drive most of the *passive/reactive* gameplay — joins, combat,
economy payouts, minigame triggers, menu clicks, region-touch effects — none of which is invoked
by a slash command at all. This doc closes that second gap.

## Methodology

Full read of every file matching `implements Listener` under `knk-v1-archive/src` (90 files,
confirmed by grep) plus several files outside that literal grep match that turned out to be
necessary cross-references (e.g. the sell-confirmation flow lives in `Listeners/PlayerListener.java`'s
shared chat handler, not in the three `*SellEvent.java` files whose own confirm-handlers are
dead/commented-out code — see the Property section). Split across 7 parallel research passes by
feature-domain slice (users/join/rank, economy, combat/skills, arena/duel/siege/minigames,
property/resources, towns/gates/social/world-admin, items/inventory-menus), each independently
verifying file paths and matching the citation rigor of `user-system.md`.

**Feature-domain categories** — identical vocabulary to `commands-v1.md`: `users`, `economy`,
`property`, `towns`, `items`, `inventory-menus`, `social`, `siege-minigame`, `world-admin`,
`misc`. Several files in this pass didn't cleanly fit an existing category (bandit/fishing/ocelot
minigames, discover-town quest tracking) — each research pass made an explicit judgment call and
recorded its reasoning inline rather than forcing a fit; look for "judgment call" / "recommended"
language in those sections.

## Cross-domain observations (read this before the per-domain sections)

- **A very large fraction of v1's event-handler surface is dead code.** Multiple slices
  independently found the same pattern: whole classes register as `Listener` but every
  `@EventHandler` method inside them is commented out (documented anyway, since knowing what was
  *attempted* is useful signal — e.g. `Sieges/ScenarioCreationEvents.java`, `Minigames/BanditKill.java`,
  `Minigames/BanditSpawn.java`, `Minigames/DiscoverTown.java`, `Minigames/TransportEvents.java`,
  `Products/SoulboundEvents.java`'s death-protection handler, most of `Skills/*`). In the
  combat/skills slice alone, 21 of 31 found handler methods are dead, and 2 of the remaining 9
  listen for a custom event (`NewSkillHandler`) that nothing in the codebase ever fires — leaving
  only 7 genuinely functioning handlers across 16 files. Treat every "documented" handler in this
  catalog as *found in source*, not as confirmation it does anything at runtime — each entry says
  explicitly whether it's live or dead.
- **Logic gets consolidated/migrated across files without cleanup.** Several individual
  `Skills/*.java` files' dead handlers correspond to logic that was actually migrated into a
  single consolidated `EntityListener#onHit` method elsewhere — with some deliberate rebalances
  made during that migration (documented in the combat/skills section) and at least one
  regression (a dropped friend-exclusion check).
- **Confirmed severe bug**: `Resources/BlockBreakEvents.java`'s user-existence check returns on
  the *success* path instead of the failure path, making the entire resource-property mining
  gate unreachable dead code at runtime, every single block-break event.
- **The `/property sell` / `/house sell` / `/room sell` confirmation flow** (the "type yes or no"
  prompt documented in `commands-v1.md`) is NOT implemented in the three dedicated
  `*SellEvent.java` files as their names would suggest — those contain only commented-out dead
  code. The real, live logic lives inside `Listeners/PlayerListener.java`'s shared chat handler,
  consuming the same static confirmation maps the command classes populate.
- **Menu-click handling is architecturally split into two uncoordinated systems**: a central
  dispatcher (`Menu/MenuClick.java`) that title-matches and delegates to plain (non-`@EventHandler`)
  methods, *and* five Menu classes that additionally register their own independent
  `@EventHandler InventoryClickEvent` listeners with their own title-matching — no single owner of
  click-cancellation. At least 4 confirmed uncancelled-click patterns (dupe/theft risk) and 6 of 9
  files missing a null-check on `event.getCurrentItem()` were found in that slice.
- **Unguarded casts and missing null-checks recur across domains**, matching the pattern already
  documented in `commands-v1.md` for command classes — event handlers have the same issue
  (`PlayerManagerClick`'s access-control short-circuit bug, `EnchantmentGenerator`'s
  generator-location leak on a failed roll, `AvengerSkill` checking the wrong event type than its
  own status message implies).
- **A possible new v3 domain surfaced**: `QuestMenuClick.java` and part of `ItemMenuClick.java`
  reference a quest system with no counterpart in `commands-v1.md`'s domain taxonomy — worth
  considering as its own `quests` domain rather than folding into `inventory-menus`.

---
# v1 event-listener catalog — Users / Join-flow / Rank-progression slice

Mined from `knk-v1-archive` (absolute path read for this pass:
`C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-v1-archive`,
cited below as `v1:src/...` per the convention in
`docs/specs/legacy/user-system.md` and `docs/specs/legacy/commands-v1.md`).
This continues the completed command-catalog effort
(`docs/specs/legacy/commands-v1.md`) into Bukkit **event listeners** —
`implements Listener` classes with `@EventHandler` methods.

## Methodology

Ten files were read in full, as assigned:
`src/Afk/AfkEvents.java`, `src/Donator/DonatorChat.java`,
`src/Donator/PlayerJoin_List.java`, `src/Experience/ExperienceChangeEvents.java`,
`src/Titles/TitleChangeEvents.java`, `src/Users/JoinEvents.java`,
`src/Users/Users.java`, `src/UsefulCommands/StaffChatEvents.java`,
`src/UsefulCommands/EnderchestViewEvent.java`, `src/Listeners/PlayerListener.java`.

Of these ten `Listener`-implementing classes, **five have every `@EventHandler`
method commented out** (dead/disabled code, not merely unregistered — the
annotation itself is commented so Bukkit never sees these as handlers even if
the class is registered): `AfkEvents`, `DonatorChat`, `PlayerJoin_List`,
`JoinEvents`, `StaffChatEvents`. `Users.java` implements `Listener` but
contains **zero** `@EventHandler` methods at all — it's a static
utility/data-access class (DB lookups, scoreboard updates, `newPlayer` logic)
that happens to `implements Listener`, matching the task brief's warning about
false positives from grepping for "Listener". The real logic for
"join message", "first join", "quit", and "location join" that the commented
`JoinEvents`/`PlayerJoin_List` stubs describe has been **moved into
`Listeners/PlayerListener.java`**, which is confirmed as the single largest
and most important file in this slice: 7 live `@EventHandler` methods driving
login, join, quit, movement (AFK/bandit-ambush/gate-activity/assignment-
tracking/teleport-delay/duel/tutorial), pre-command interception, chat
(donator-chat formatting, mention pings, sell-confirmations, tutorials),
death (coin/item drop, avenger skill, minigame short-circuits), and respawn
(spawnpoint routing, health/speed skill application, avenger-skill messaging).
Two other files contribute one live handler each: `ExperienceChangeEvents`
(custom `ExperienceChangeEvent` → fires `TitleChangeEvent`) and
`TitleChangeEvents` (custom `TitleChangeEvent` → the actual promotion/
demotion business logic). `EnderchestViewEvent` contributes one live handler
(`InventoryCloseEvent`, saves an offline-enderchest-viewer's data on close).

**Total: 10 live `@EventHandler` methods across 4 files with active code**
(`PlayerListener` ×7, `ExperienceChangeEvents` ×1, `TitleChangeEvents` ×1,
`EnderchestViewEvent` ×1), plus **16 commented-out/dead handler methods**
across the other 6 files (`AfkEvents` ×5, `DonatorChat` ×1, `PlayerJoin_List`
×2, `JoinEvents` ×5, `StaffChatEvents` ×1, `TitleChangeEvents` ×1 additional
commented `onMove`, `PlayerListener` ×1 additional commented title-check
block inside `OnMove`). Dead handlers are documented below for completeness
since the task brief says not to skip minor handlers, but are clearly marked
as disabled/superseded rather than invented live behavior.

---

## 1. `src/Listeners/PlayerListener.java`

The core join/quit/login/combat/economy-drop pipeline. All 7 handlers are
live (no priority except where noted; `HIGHEST` used on the 4 latest-declared
handlers). Feature allocation: primarily `users`, with `economy` (coin drops),
`social` (mentions), and `siege-minigame`/`misc` (transport/hideandseek/
tutorial short-circuits) cutting across several methods.

### `OnLogin(PlayerLoginEvent event)` — v1:src/Listeners/PlayerListener.java:101-148

| | |
|---|---|
| Event | `PlayerLoginEvent`, default priority |
| Trigger condition | Always runs on login attempt; branches on NPC metadata / existing-user / whitelist state |
| Goal/function | Records join timestamp (`Main.joinLong`, line 106) for later playtime accounting. Returns immediately for NPCs (line 108-110, `player.hasMetadata("NPC")`). If the UUID already has a DB user (`Users2.ExistUser`, line 112) it eagerly instantiates the `User` object (`Users2.InstantiateUser(uuid, false)`, line 114) and returns. Otherwise this is a brand-new player: checks server whitelist manually by iterating `Bukkit.getWhitelistedPlayers()` (lines 119-133) rather than relying on Bukkit's own login-event whitelist enforcement. If allowed, adds uuid to the static `newPlayers` list (line 137), creates the DB user via `main.CreateUser(...)` (line 138), broadcasts a "new player entered the Kingdoms" message, and plays `SoundHandler.NOTE_PLING` to every currently online player (lines 140-143). If not allowed (not whitelisted), only broadcasts a message that the player "tried to join... but is not whitelisted" (line 146) — it does **not** call `event.disallow(...)`, so the vanilla Bukkit whitelist system is presumably still what actually blocks the connection; this handler's message is purely informational. |
| Feature allocation | users |
| Bugs/edge cases | The manual whitelist loop (lines 119-133) never calls `event.disallow()` — if Bukkit's own whitelist is somehow not authoritative (e.g. this event fires before/instead of the native check, or whitelist is enforced elsewhere), an unauthorized player could still connect while only a chat broadcast fires. No player-facing kick message is sent to the connecting player themselves in the disallowed branch — only a server broadcast. Login events instantiate a full `User` object synchronously in the login thread (line 114) — depending on `Users2.InstantiateUser`'s implementation (out of scope) this could be a blocking DB call on the connection thread. |

### `OnJoin(PlayerJoinEvent event)` — v1:src/Listeners/PlayerListener.java:150-225

| | |
|---|---|
| Event | `PlayerJoinEvent`, default priority |
| Trigger condition | Always; branches on `Users2.ExistUser(uuid)` |
| Goal/function | Calls `main.DBreconnect()` unconditionally on every join (line 154) — reconnects the DB connection each time a player joins, regardless of whether it's needed. For existing users: re-instantiates the `User` (line 163), calls `user.join(player)` and `user.setJoinMessage(event)` (out of scope — presumably sets `event.setJoinMessage(...)`), then sends a block of welcome/stat messages (coins, gems, title, salary, income — lines 170-178) directly via `player.sendMessage` in addition to whatever `setJoinMessage` does. Teleports to spawn via `user.TeleportSpawn()` unless the player has `k&k.join.nolocation` or is in "owner modus" (line 180-182). If in owner-modus, instead checks every house for a missing spawnpoint and lists them (lines 185-211) — an admin-diagnostic message about houses lacking locations. If the player's UUID is in the static `Main.combatlogged` set (dropped inventory from prior combat-logout), sends an error message and removes them from the set (lines 215-219). For brand-new users (`Users2.ExistUser` false), delegates entirely to `Users.newPlayer(player)` (line 222) — this is where the real "first join" flow lives (see `Users.newPlayer` below, out-of-scope-as-handler but read for context since it's called directly from this handler). Always ends with `Users.updateScoreBoard(null)` (line 224). |
| Feature allocation | users |
| Bugs/edge cases | `main.DBreconnect()` on every single join (line 154) is a potentially expensive/risky operation to run unconditionally rather than only on detected connection loss. The event's own join-message mechanism (`user.setJoinMessage(event)`) is combined with a *second*, separate block of `player.sendMessage` calls for the same welcome info — duplicated/overlapping responsibility not visible from the method name. No permission check gates the house-spawnpoint diagnostic beyond already being in "owner modus". |

### `OnQuit(PlayerQuitEvent event)` — v1:src/Listeners/PlayerListener.java:227-310

| | |
|---|---|
| Event | `PlayerQuitEvent`, default priority |
| Trigger condition | Always; looks up user via `Users.findUser(uuid)` |
| Goal/function | AFK cleanup: removes AFK state and any pending AFK-commence timer (lines 251-258). Combat-log handling: if the quitting player is in `Main.incombat` (keyed by `User`, not `UUID` — see bug note), sets their health to 0 (kills them server-side), adds their UUID to `Main.combatlogged`, removes them from `incombat`, and notifies staff via `Main.Notify` (lines 263-269) — this is the mechanism that produces the "Your inventory got dropped when you logged off in combat!" message seen later in `OnJoin`. Transport minigame: if the user has an active `Transport`, marks it failed with a "left while transporting items!" message (lines 274-278). Tutorial: cancels any in-progress intro or general tutorial (lines 283-291). Sets the quit message from `user.getLeaveMessage()` (line 296) — donator/staff/owner-tiered quit message logic lives inside `User`, out of scope here. Accumulates playtime (`playTimeOverall`/`playTimeToday`) using the join timestamp recorded in `OnLogin`'s `Main.joinLong` map (lines 298-306). Calls `user.quit()` (persists to DB, presumably) and `Users.updateScoreBoard(null)`. |
| Feature allocation | users (with economy/siege-minigame touchpoints via combatlog/transport) |
| Bugs/edge cases | `Main.incombat.containsKey(user)` (line 263) — `incombat` is typed to key by `User` object identity rather than `UUID`; if `Users.findUser` and whatever populated `incombat` ever produce different `User` instances for the same player (e.g. object not interned/cached consistently), this lookup silently fails and combat-logging never triggers. Catch blocks for `UserNotFoundException`/general `Exception` around `Users.findUser` (lines 234-245) call `ErrorHandlers.userNotFoundAction` and `return` — meaning a quit event for an unrecognized user skips *all* of AFK/combat/transport/tutorial/playtime/quit-message logic entirely, including not setting `user.quit()` (acceptable if truly unknown, but note the quit message itself is also left at Bukkit's default in that path since `event.setQuitMessage` is never reached). |

### `OnMove(PlayerMoveEvent event)` — v1:src/Listeners/PlayerListener.java:312-528

| | |
|---|---|
| Event | `PlayerMoveEvent`, default priority |
| Trigger condition | Fires on every player movement; short-circuits for Citizens NPCs (line 322-325); several sub-blocks additionally gated on block-coordinate change (`event.getFrom()`/`getTo()` X/Y/Z comparison, lines 442-444) to avoid re-running per-tick sub-tick movement noise |
| Goal/function | This is the single largest handler in the slice and covers several unrelated concerns in one method: **AFK** — clears AFK if not mid-AFK-teleport, otherwise returns early (lines 342-351); always resets the AFK-commence timer to "afk in `main.afkTime` seconds from now" (line 352) on every move, meaning any movement at all — even a head-turn generating a move event — resets the AFK clock. **Gates** — for players inside a town (`TownEvents.inTown`), scans nearby entities around each town gate and toggles gate "active" state based on entity presence (lines 356-382) — this runs on *every* mover inside any town, not just near a specific gate. **Bandit ambush** — if not staff/owner-modus, not in a safe zone, not in a minigame, in survival mode, not flying, and no existing ambush, tracks a "bandit location" and triggers `BanditAmbushes.tryAmbush(user)` once the player has moved ≥5 blocks from the last tracked point (lines 385-402). **Title-check** — a large commented-out block (lines 405-434) duplicating the logic that now lives in `ExperienceChangeEvents`/`TitleChangeEvents` — dead code left in place, confirming the move-based title-check was superseded by the custom-event-based approach. **New-player teleport handoff** — if uuid is in the static `newPlayers` list, calls `Users.newPlayer(player)` (lines 437-440) on first detected movement (this is what the *also-live* commented-out `JoinEvents.locationJoin`/`onMove` pair intended to do, now consolidated here). Then, only on an actual block-coordinate change: increments any active `AssignmentTravelDistance` assignment (lines 447-455); checks Transport minigame progress against a "property" WorldGuard region to detect warehouse arrival (lines 457-469); cancels any pending `TeleportDelay` unless the player has teleport-immunity (lines 471-478); force-teleports players into position during an arena duel countdown (lines 480-500); and force-teleports/blocks players in an active tutorial stage back to the tutorial's target location unless the tutorial stage is "armor" or "food" at stage ≥4 (lines 502-526, with two empty `if` bodies at 511-516 that intentionally no-op to allow movement in those specific tutorial stages). |
| Feature allocation | users (AFK), towns (gates), siege-minigame (bandit ambush, transport, duel, hideandseek-adjacent), misc (tutorials) |
| Bugs/edge cases | Resetting AFK-commence on *every* `PlayerMoveEvent` (line 352) is a known-noisy pattern (head rotation alone fires `PlayerMoveEvent` in Bukkit) — likely intentional given the earlier fully-commented-out `AfkEvents` class attempted exactly the same thing across chat/damage/join/quit events and was abandoned in favor of this one central handler, but it means the AFK timer is reset far more often than "the player actually walked". The gate-toggle block (lines 356-382) runs the nearby-entity scan for every town member's every move, an O(gates × movers) scan with no apparent throttling — a possible performance hot path in a populated town. The stale commented title-check block (405-434) should probably be deleted rather than left as dead weight, though it does no harm since it's fully commented. `newPlayers` list-based dispatch (line 437) means the intended "teleport new players to `new` spawn on first move" flow depends on a static, non-per-plugin-reload-safe list also referenced in the disabled `JoinEvents`/`Users` classes — three separate classes (`Users`, `JoinEvents`, `PlayerListener`) each maintain their own `newPlayers`-like state; only `PlayerListener`'s and `Users`' `newPlayer()` call are actually wired together. |

### `onPreCommand(PlayerCommandPreprocessEvent event)` — v1:src/Listeners/PlayerListener.java:530-699

| | |
|---|---|
| Event | `PlayerCommandPreprocessEvent`, `priority = EventPriority.HIGHEST` |
| Trigger condition | Every command a player types; several independent sub-blocks each with their own trigger conditions |
| Goal/function | Instantiates the `User` (returns via error handler on failure, lines 538-550). **Hide and Seek**: if playing and in-hub-or-in-progress, cancels any command not in the minigame's allow-list (unless owner-modus), sending an error + hint (lines 555-567). **Transport minigame**: cancels `/menu` and `/point` specifically while transporting (lines 572-581). **Creations**: delegates the whole event to `creation.processEvent(event)` (line 589) — a large commented-out block below it (591-648) shows what that used to look like inline (stop/start/confirm/undo dispatch) before being refactored into `Creation.processEvent`. **Tutorials**: cancels the command outright if in any tutorial, then re-interprets `/menu`, `/next`, `/yes`, `/cancel` as tutorial-navigation commands via `tutorial.nextStage`/`TryNext`, otherwise calls `Tutorials.notAllowed(player)` (lines 653-678). **Reload command**: intercepts `/reload`, `/rl`, `/rel` for players with `bukkit.reload`, `k&k.reload`, or op, cancels it, and instead calls the plugin's own `main.reload(player)` (lines 683-690) — i.e. it hijacks the vanilla/other-plugin reload command to run a custom reload routine. **Staffchat shorthand**: rewrites `/sc` to `/staffchat` via `event.setMessage(...)` (lines 695-698) — this duplicates the intent of the fully-commented-out `StaffChatEvents.onCommand` handler, confirming that handler's logic was migrated here. |
| Feature allocation | siege-minigame (hideandseek/transport), towns (creations), misc (tutorials, reload, staffchat) |
| Bugs/edge cases | The tutorial block (line 657) calls `event.setCancelled(true)` unconditionally as soon as *any* tutorial is active, before checking which of the four recognized commands was typed — meaning **every** command is blocked during a tutorial, not just non-tutorial ones; this is presumably intentional (tutorials are meant to be linear) but is a much broader cancellation net than the Hide-and-Seek block's explicit allow-list approach two blocks above, an inconsistent pattern for "restrict player to a minigame/mode" across the same file. `message.split("/")[1]` (lines 668, 672) assumes the message always starts with `/` and has a second token — would throw `ArrayIndexOutOfBoundsException` on a lone `/` command with nothing after it, though Bukkit likely never fires this event for a bare `/`. |

### `onChat(PlayerChatEvent e)` — v1:src/Listeners/PlayerListener.java:701-991

| | |
|---|---|
| Event | `PlayerChatEvent`, `priority = EventPriority.HIGHEST` |
| Trigger condition | Every chat message; many independent sub-blocks |
| Goal/function | Finds user via `Users2.FindUser` (error-handled, lines 709-721). **Duel coin-bet chat capture**: if the player has an open duel bet-setup session (`DuelSetupClick.coinBetList`), cancels the chat and interprets the message as a coin amount or "cancel", validating the player's and opponent's balances, updating inventory bet-slot items, and reopening the setup inventory (lines 726-774) — this is a chat-based numeric-input UI pattern. **Donator chat formatting**: the same logic that exists (and is now dead) in `Donator/DonatorChat.java` — capitalizes the first letter of the message, tiers the chat format by owner/co-owner/staff permission or by donator rank (noble/royal/dragon blood/default), wrapped in a try/catch that only prints a stack trace on failure (lines 779-820) — confirms `DonatorChat.java`'s commented code was migrated here verbatim. **Player mention**: scans all online `User`s for their username appearing (case-insensitively) in the chat message; if found and not self, plays a ping sound to the mentioned player with a 3-tick cooldown counter stored per-mentioner in a `HashMap<UUID,Integer>` (lines 825-844). **House/Property/Room sell-confirmation**: three near-identical blocks (846-942) that treat the next chat message as a yes/no confirmation for a pending house/property/room sale, canceling the chat either way, executing the sale (refunding half price, removing WorldGuard region ownership, clearing personal spawnpoint if it pointed at the sold house) on "yes", or just printing a cancellation message otherwise. **Tutorials**: cancels chat and forwards the message to the active tutorial's `TryNext`, and removes the tutorial's `target` player from the event's recipient list so the tutorial NPC/target doesn't see the raw chat (lines 947-958). **Teleport-delay cancel**: typing "cancel" clears a pending `Main.teleportconfirm` entry (lines 963-969). **Creation events**: forwards chat to `creation.processEvent(e)` if the user has an active creation session (lines 974-978). **AFK removal**: identical AFK-clear-and-reset-timer logic as in `OnMove` (lines 983-990), run unconditionally at the end regardless of any of the above branches. |
| Feature allocation | users (donator chat, mentions, AFK), economy (sell confirmations), property (house/property/room sale), social (mentions), siege-minigame (duel bet chat), misc (tutorials, teleport delay) |
| Bugs/edge cases | The donator-chat block's format tiering is entirely inside a `try { } catch(Exception exception) { exception.printStackTrace(); }` (lines 779-820) with **no player-facing fallback and no re-throw** — if any of `player.getName()`, `e.getMessage().charAt(0)` (throws on empty message!), or the various `ColorOptions`/`user.getTitleName()` calls throw, the chat message's `e.setFormat(...)` is simply never called and the exception is silently swallowed to console only — the player's message would then use whatever Bukkit's default chat format is, with no error surfaced to them. `e.getMessage().charAt(0)` (line 782) is called with no length check — an empty chat message (if such a thing can reach this event) would throw `StringIndexOutOfBoundsException`, caught by the same swallow-all catch. The house/property/room sell-confirm blocks (846-942) all key off `e.getMessage().equalsIgnoreCase("yes"/"no")` but **do not validate that the player currently has permission or still owns the house/property/room** beyond the presence of a pending-sale map entry set elsewhere (out of scope) — if that invariant can be violated, could be exploited, though this is speculative without reading the command classes that populate `sellconfirm`. Multiple unrelated feature concerns (duel betting, donator chat, mentions, three kinds of sale confirmation, tutorials, teleport-delay, creations, AFK) are all handled inside one 290-line method with no early-return isolation — an exception or unexpected state in an earlier block (e.g. donator-chat's silently-swallowed exception) does not stop later blocks from running, but a `return` anywhere upstream (there is none in this method) would silently skip the AFK-reset tail logic. |

### `onDeath(PlayerDeathEvent event)` — v1:src/Listeners/PlayerListener.java:993-1162

| | |
|---|---|
| Event | `PlayerDeathEvent`, `priority = EventPriority.HIGHEST` |
| Trigger condition | Every player death; short-circuits for NPC deaths (line 996) |
| Goal/function | For NPC victims, zeroes dropped exp and clears the death message, then returns (lines 996-1001) — prevents Citizens NPCs from generating a "Player X died" broadcast. For real players: logs the death (line 1002), resolves the killer's `User` if the killer exists and isn't an NPC (lines 1020-1023), increments the victim's death counter, clears any `incombat` state, computes a coin penalty as `coins / Main.dropPercentage` and removes it from the victim (lines 1025-1031), records the death location, and always zeroes vanilla dropped XP (line 1033, XP is handled via the custom title/experience system instead). If there's a real killer, grants the killer XP (`getExpPart(5)`, multiplied by rank bonus) and a kill counter increment, with a chat message to the killer (lines 1035-1041). **Avenger skill**: if the victim has the "avenger" special skill, sets their avenger target to the killer and sends an activation message; if instead the victim *was* someone else's avenger target, sends a "you have been avenged" message to the victim and clears the killer's avenger target (lines 1046-1058) — note this branch fires on the **victim's own death event**, referencing `avenger`/`user` variables in a way that reads as if avenging the *previous* death of the current victim, requiring cross-referencing `Users.GetAvenger` (out of scope for full semantics, flagged as needing verification against `User`/avenger-skill design docs). **Minigame short-circuits**: if the victim is in an active Siege, sends a simple death message and returns early — skipping all normal coin/item-drop logic entirely (lines 1064-1076); if in a Transport minigame, either pays the killer a commission and fails the transport (if killed by a player) or fails the transport and salvages any "personal menu" item from the victim's inventory into their keep-items (if killed by environment), then returns (lines 1078-1102) — again skipping normal death-drop logic. **Normal (non-minigame) death economy**: if killed by a player, computes gold-ingot stacks representing the removed coins and adds them as physical drop items with lore describing the coin amount, plus a chat message to the victim (lines 1105-1116) — note `coins` is removed a **second time** via `user.removeCoins(coins)` at line 1111 (see bug). **Item retention filtering**: unless the victim is flagged combat-logged, splits `event.getDrops()` into "removable" (stripped from the drop) and "keep" (soulbound/ghosted/high-grade-4+ items), removes both sets from the actual drop list, and stores the "keep" set on the user to be restored on respawn (lines 1118-1157). Always zeroes dropped exp and (re-)sets the death message at the very end (lines 1159-1160). |
| Feature allocation | economy (coin drop/penalty), users (deaths/kills stat, avenger skill), items (soulbound/ghosted/grade-based retention), siege-minigame, misc |
| Bugs/edge cases | **`user.removeCoins(coins)` is called twice** for the same death in the non-minigame branch — once at line 1031 (`Integer coins = user.getCoins()/Main.dropPercentage; user.removeCoins(coins);`) unconditionally for every player death, and again at line 1111 (`user.removeCoins(coins);`) inside the `if (userKiller != null)` block using the *same* already-decremented `coins` value — meaning a PvP death would remove roughly double the intended coin penalty from the victim (once generically, once more specifically when computing the drop items), while an environmental/mob death only removes it once. This looks like a genuine double-deduction bug. `player.getKiller().getName()` is called directly at line 1115 and again at line 1085 without a null-check even though the method already established `killer`/`userKiller` may be null in other branches — in both cases it's inside an `if (userKiller != null)` guard so likely safe in practice, but relies on `killer` and `userKiller` staying in sync (they're set together at lines 1020-1023, so this holds). The avenger-skill block's exact trigger semantics (victim-sets-target-on-own-death vs. victim-was-avenged-on-own-death) reads ambiguously without `User.setAvengerTarget`/`getSpecialSkillName`/`Users.GetAvenger`'s full implementation — flagged as unclear/out-of-scope, would need `Users/User.java`'s avenger fields to confirm whether this fires on the *avenger's* death or the *original attacker's* death. |

### `respawn(PlayerRespawnEvent e)` — v1:src/Listeners/PlayerListener.java:1164-1334

| | |
|---|---|
| Event | `PlayerRespawnEvent`, `priority = EventPriority.HIGHEST` |
| Trigger condition | Every respawn; entire body gated on `!CitizensAPI.getNPCRegistry().isNPC(player)` (line 1171) |
| Goal/function | Resolves the `User`, with three separate catch branches (`UserNotFoundException`, `UserIsNpcException`, generic `Exception`) all returning (lines 1173-1186, generic catch swallows silently with no error handler call, unlike the other two). **Hide and Seek**: if actively playing, overrides respawn location to the town's spawnpoint (falling back to last death location on lookup failure) and returns early (lines 1191-1204) — skips everything below including health/speed/avenger logic for HS players. **Siege**: if actively in an active siege, sets respawn to the player's team's first spawnpoint and schedules (2s delay) opening a siege-spawnpoint-selection menu, then returns early (lines 1209-1223) — same short-circuit pattern. **Transport**: cancels the transport with a failure message if active (does *not* return — falls through to the rest of the method, lines 1228-1232). **Normal spawnpoint routing**: a fairly convoluted nested-if block (lines 1234-1271) that, based on whether the user's stored spawnpoint ID equals 1 and whether they lack `k&k.join.nolocation`/are not op, routes to either their personal spawnpoint or the global "spawn" point — the two inner branches (`if`/`else` at lines 1236 and 1251) are near-duplicates of each other differing only in permission-check polarity (see bug). **Keep-items restore**: re-adds all items stashed via the death handler's "keep" list back to the player's inventory and clears the stash (lines 1272-1276). **Health-scale from Health skill**: sets `player.setHealthScale(20 + health)` for skill levels below 7, flat 32 at level 7+ (lines 1281-1290). **Walk-speed from Speed skill**: a manual if/else-if ladder mapping speed-skill levels 1-7 to specific walk-speed floats, with levels 6 and 7 both mapping to the identical `0.32F` (lines 1295-1317, see bug). **Avenger skill messaging**: if the respawning player has an avenger target, either confirms the +50% damage bonus is still active (target still online/tracked) or informs them the target logged off (lines 1322-1332). |
| Feature allocation | users (spawnpoint routing, skills), siege-minigame (hideandseek/siege/transport short-circuits), items (keep-items restore) |
| Bugs/edge cases | The two nested branches at lines 1236-1250 and 1251-1266 are structurally identical (same three-way `spawnpoint.getSpawnPointID("spawn") != null` → per-spawnpoint-name check → else warn-op logic) but are gated by `!player.hasPermission("k&k.join.nolocation") \|\| !player.isOp()` vs. its else — given De Morgan's laws, `!(A) || !(B)` is true unless *both* A and B hold, meaning the "else" branch (lines 1251+) only runs when the player **both** has `k&k.join.nolocation` **and** is op — yet its body is nearly identical to the "then" branch, suggesting this conditional's intent (distinguish "should use custom spawnpoint" vs. "should always go to global spawn") is not actually achieved by the code as written; a likely logic bug where the two branches were meant to diverge more (e.g. skip personal-spawnpoint routing entirely for privileged players) but currently produce near-identical behavior regardless of the permission check. Walk-speed ladder (lines 1295-1317) has speed level 6 and 7 both set to `0.32F` — dead/redundant branch, likely a copy-paste leftover when a level was added without updating its value, or intentionally capped (unclear without design docs — flagged as unclear). The generic `catch (Exception ex) { return; }` (lines 1183-1186) swallows any unexpected error with **no logging and no `ErrorHandlers` call**, unlike the sibling `UserNotFoundException` branch two lines above it — inconsistent error-handling within the same try/catch chain, could hide real bugs silently in production. |

---

## 2. `src/Experience/ExperienceChangeEvents.java`

### `ExperienceChangeEvent(ExperienceChangeEvent e)` — v1:src/Experience/ExperienceChangeEvents.java:26-49

| | |
|---|---|
| Event | Custom event `Handlers.ExperienceChangeEvent` (not a Bukkit-native event — presumably fired manually wherever a user's experience changes, e.g. `user.addExperience(...)`), default priority |
| Trigger condition | Always runs when the custom event fires; all logic wrapped in try/catch |
| Goal/function | Looks up the player's current experience, current title ID, and recomputes what title ID that experience *should* map to via `title.getTitleIDbyExp(Experience)` (lines 34-36). If the new title ID is lower, fires a `TitleChangeEvent` with `isPromoting=false` (demotion); if higher, fires one with `isPromoting=true` (promotion) (lines 38-44) — via `Bukkit.getServer().getPluginManager().callEvent(...)`, i.e. this handler's real job is purely to detect a title-tier crossing and delegate the actual promotion/demotion mechanics to `TitleChangeEvents.onChange` (below). If `difference == 0`, no event fires — a no-op, correctly guarding against redundant title-change events on experience changes that don't cross a tier boundary. |
| Feature allocation | users (title/rank progression) |
| Bugs/edge cases | The entire method body is wrapped in a blanket `catch (Exception exception) { exception.printStackTrace(); }` (lines 45-48) with no rethrow and no player-facing error — if `Users.getUser(uuid)` returns null (e.g. race condition where the custom event fires for a player whose `User` object was just destroyed/nulled — see `Users.destroy`), this would NPE on `user.getExperience()` at line 34 and silently print a stack trace only, meaning a legitimate title change could be silently dropped with zero player feedback. |

---

## 3. `src/Titles/TitleChangeEvents.java`

### `onChange(TitleChangeEvent e)` — v1:src/Titles/TitleChangeEvents.java:35-69

| | |
|---|---|
| Event | Custom event `Handlers.TitleChangeEvent`, default priority |
| Trigger condition | Fired by `ExperienceChangeEvents` (or potentially other callers) whenever a title-tier crossing is detected |
| Goal/function | Reads the promotion/demotion flag and computes `changeAmount` (absolute difference between old/new title IDs). If the change is exactly 1 tier, directly calls `userPromotion`/`userDemotion` once (lines 49-51, 60-62). If the change spans 2+ tiers at once (e.g. a large one-shot experience grant), instead registers the UUID in the static `Main.titleChangeList` map with the tier count and starts a repeating loop (`setPromoteLoop`/`setDemoteLoop`) that applies **one** tier of promotion/demotion every 2 seconds (`runTaskTimer(main, 0, 2*20)`, lines 298-343) until the counter reaches 0 — i.e. multi-tier jumps are animated/staggered one tier at a time rather than applied instantly. |
| Feature allocation | users (title/rank progression) |
| Bugs/edge cases | None specific to the dispatch logic itself; see `userPromotion`/`userDemotion`/loop methods below for the substantive bugs. |

**`userPromotion(User user, Integer newTitleID)`** — v1:src/Titles/TitleChangeEvents.java:121-191 (helper, called from the handler and from `setPromoteLoop`'s runnable, not itself an `@EventHandler` but core to this handler's behavior so documented here per the task's "goal/function" requirement):

Computes coin/gem/exp bonuses (rank-multiplied via `user.getMultipliedInt`) and a skill-point amount equal to the number of tiers crossed (here always 1, since the multi-tier case routes through the loop instead). For online users: sends the tier's promotion message(s), plays `SoundHandler.LEVEL_UP`, plays a `MOBSPAWNER_FLAMES` effect, and sends a sequence of "Unlocked a SkillPoint" plus milestone-gated unlocks at title thresholds 5 (+1 house, +1 property), 10 (+1 house, +1 property, +1 skill point, "SpecialSkill-point" message), 12 (+1 quest slot, message only — no data mutation visible, see bug), and 15 (+1 house, +1 property, +1 keep, +1 assignment) — each gated by `newTitleID >= threshold && currentTitleID < threshold` so a multi-tier jump handled by the loop will correctly award each threshold exactly once as it steps through. Sets the player's experience bar via `title.setExperienceBar`. Always (online or offline) grants skill points, coins, gems, exp, sets the new title, and refreshes quest/assignment maximums (lines 184-190).

**`userDemotion(User user, Integer newTitleID)`** — v1:src/Titles/TitleChangeEvents.java:194-293: Mirror-image of promotion for thresholds 5/10/12/15 (removing house/property/keep/assignment slots and sending "Lost a slot" messages), with a special case at threshold 10: if the user currently has a special skill, it's stripped and named "none" with a message; otherwise a skill point is removed instead (lines 221-229). Skill-point/level removal logic (lines 249-273) removes one general skill point if available, otherwise picks a **random** skill from the skill list and removes a level from it — if that random skill has 0 levels, falls through to shuffling the entire skill list and removing a level from **every** skill that has any levels (lines 262-272, potential over-removal — see bug).

| | |
|---|---|
| Feature allocation | users (rank progression, unlocks) |
| Bugs/edge cases | **Threshold-12 promotion unlock only sends a message ("Unlocked a slot for a Quest") with no corresponding data mutation** (v1:src/Titles/TitleChangeEvents.java:165-168) — contrast with thresholds 5/10/15 which each call `user.addHouseAmount`/`addPropertyAmount`/etc.; either the quest-slot increment happens elsewhere (out of scope, unclear) or this is a promotion that promises a reward without granting it. The mirrored demotion side (231-234) also only sends a message with no `removeQuestAmount`-style call, consistent with the same gap. **Demotion's skill-removal fallback can remove levels from every skill with any level at once** (lines 262-272) — if the randomly-selected skill happens to be at level 0, the code shuffles and loops over *all* skills removing one level from each that has ≥1, rather than picking a second random skill — this could strip multiple skills' progress for what should be a single-tier demotion, a likely bug (probably meant to `break` after removing from one skill in the shuffled loop, but there's no `break` inside that `for` loop at line 265-271, unlike the single-skill `removeSkillID` call pattern used elsewhere). `setPromoteLoop`/`setDemoteLoop` (lines 295-343) use `runTaskTimer` without ever cancelling on plugin disable/reload — if a player's tier-jump is mid-loop during a `/reload`, the `BukkitRunnable` would presumably be cancelled by Bukkit's own task-scheduler cleanup on plugin disable, but there's no explicit persistence/resume, so a very slow (2s-per-tier) multi-tier promotion could be interrupted mid-way by a server reload, leaving the user partially promoted with the `Main.titleChangeList` entry orphaned (not removed, since the loop task itself is what would have removed it). |

---

## 4. `src/UsefulCommands/EnderchestViewEvent.java`

### `onClose(InventoryCloseEvent e)` — v1:src/UsefulCommands/EnderchestViewEvent.java:20-33

| | |
|---|---|
| Event | `InventoryCloseEvent`, default priority |
| Trigger condition | Only when the entity closing the inventory is a `Player` (line 23) and that player's UUID is a key in the static `EnderchestCommand.offlineEnderchest` map (line 27) — i.e. only relevant when a staff member was viewing another (offline) player's enderchest via `/enderchest`-style admin tooling |
| Goal/function | Looks up the target `Player` object associated with the viewing staff member's UUID in `offlineEnderchest`, and calls `target.saveData()` on it (line 30) — persists the (presumably synthetic/offline-representation) target player's data after the admin closes the viewed enderchest inventory. Does **not** remove the entry from `offlineEnderchest` after handling it (see bug). |
| Feature allocation | inventory-menus (admin enderchest viewing tool) |
| Bugs/edge cases | The `offlineEnderchest` map entry for this UUID is never removed after being handled (no `.remove(uuid)` call) — if `EnderchestCommand` doesn't clean this up elsewhere, closing the inventory a second time (or any subsequent unrelated inventory close by the same staff member, since the trigger only checks map membership, not which inventory was closed) would trigger `target.saveData()` again on a possibly-stale target reference; would need to read `UsefulCommands/EnderchestCommand.java` (out of scope) to confirm whether the map is cleared there instead. The handler also doesn't verify that the *specific* inventory closed was actually the enderchest view — any inventory close by a staff member with a pending `offlineEnderchest` entry (e.g. opening and closing an unrelated chest while still "logged" as viewing someone's enderchest) would fire this save, which may be harmless (just an extra save) or may fire prematurely before the admin is actually done, again unclear without `EnderchestCommand.java`. |

---

## 5. `src/Afk/AfkEvents.java` — all handlers dead/commented

No live `@EventHandler` methods. Five handlers are present in full but commented out (annotation and body both), confirming this class is inert even if registered as a listener:

| Commented handler | Would-be event | What it did (per comments) |
|---|---|---|
| `onWalk` | `PlayerMoveEvent` | v1:src/Afk/AfkEvents.java:31-63 — clear AFK unless mid-AFK-teleport, reset AFK-commence timer |
| `onChat` | `PlayerChatEvent` | v1:src/Afk/AfkEvents.java:65-94 — same AFK-clear/reset pattern on chat |
| `onDamage` | `EntityDamageEvent` | v1:src/Afk/AfkEvents.java:96-131 — same pattern, gated to `Player` entities, with an extra `UserIsNpcException` catch that silently returns |
| `onJoin` | `PlayerJoinEvent` | v1:src/Afk/AfkEvents.java:133-162 — same AFK-clear/reset pattern on join |
| `onQuit` | `PlayerQuitEvent` | v1:src/Afk/AfkEvents.java:164-195 — clears AFK and removes the AFK-commence timer entirely (no reset, since the player is leaving) |

Only a static helper `getPlayerAfk(Player player)` (v1:src/Afk/AfkEvents.java:197-211) remains live, scanning the static `afk` list for a matching player — used by other classes to query AFK state (out of scope to trace every caller). The task brief confirms `PlayerListener.OnMove` and `PlayerListener.onChat` now perform the equivalent AFK-clear/reset logic directly inline (see above), which is almost certainly why this entire class's handlers were commented out rather than deleted — a consolidation, not a removed feature. Feature allocation: users (AFK).

---

## 6. `src/Donator/DonatorChat.java` — all handlers dead/commented

One handler, fully commented: `onChat(PlayerChatEvent e)` — v1:src/Donator/DonatorChat.java:16-77. Per the comment body, this implemented owner/co-owner/staff/donator-tiered chat message formatting (identical branch structure to what's now live inline in `PlayerListener.onChat`, lines 779-820, confirmed effectively verbatim). This confirms the donator-chat formatting feature was migrated into `PlayerListener` and this standalone class left as dead code. Feature allocation: users/social (chat formatting by rank/donator tier).

---

## 7. `src/Donator/PlayerJoin_List.java` — all handlers dead/commented

Two commented handlers:

- `onJoin(PlayerJoinEvent e)` — v1:src/Donator/PlayerJoin_List.java:29-33 — body is just a comment noting "Located in the JoinEvents in the users package", itself now stale since that logic actually lives in `Listeners/PlayerListener.OnJoin`, not `Users/JoinEvents` (which is *also* fully dead — see below). A comment pointing to dead code pointing to more dead code.
- `onLeave(PlayerQuitEvent e)` — v1:src/Donator/PlayerJoin_List.java:35-89 — per the comment, built a donator/staff/owner-tiered **quit** message (paralleling the tiered join-message intent), with owner/co-owner/staff getting either a silent quit (if in owner/staff modus) or a rank-flagged leave message, and donator ranks (noble/royal/dragon blood) getting a tiered leave message; default users got `null` (silent quit). This tiered-quit-message feature does **not** appear to have a live equivalent in `PlayerListener.OnQuit`, which only sets `event.setQuitMessage(user.getLeaveMessage())` (v1:src/Listeners/PlayerListener.java:296) — `getLeaveMessage()` lives in `Users/User.java` (out of scope for this pass) and may or may not reimplement this same tiering internally; flagged as unclear/out-of-scope whether the donator/staff-tiered quit-message feature was preserved elsewhere or silently dropped when this class's handler was disabled.

Feature allocation: users (join/quit messaging by rank).

---

## 8. `src/Users/JoinEvents.java` — all handlers dead/commented

Five commented handlers, all superseded by `Listeners/PlayerListener.java`'s live equivalents (confirmed by near-identical code):

- `joinMessage(PlayerJoinEvent e)` — v1:src/Users/JoinEvents.java:46-122 — the original combined join-message + scheduled-donator-rank + scheduled-item-give + duplicate-IP-address-warning + welcome-stats flow. Superseded by `PlayerListener.OnJoin` for the messaging piece; the scheduled-donator/scheduled-item/duplicate-address pieces were extracted into standalone static helpers now living in `Users.java` (`CheckScheduledRank`, `CheckScheduledItems`, `CheckDuplicateAddress` — v1:src/Users/Users.java:477-535) for some other caller to invoke (not called from `PlayerListener.OnJoin` itself, per that method's read above — flagged as unclear/out-of-scope whether they're invoked from `User.join()`, which is out of scope for this pass).
- `firstJoin(PlayerLoginEvent e)` — v1:src/Users/JoinEvents.java:124-164 — near-identical whitelist-check-and-create-user logic to what's now live in `PlayerListener.OnLogin`; confirms that migration.
- `onQuit(PlayerQuitEvent e)` — v1:src/Users/JoinEvents.java:166-196 — playtime accounting, superseded by the equivalent block in `PlayerListener.OnQuit`.
- `locationJoin(PlayerJoinEvent e)` — v1:src/Users/JoinEvents.java:198-290 — an elaborate delayed (10-tick async) spawnpoint-teleport routine with kardenna-town special-casing and an owner-modus house-location diagnostic; a more complex ancestor of what's now handled more simply via `user.TeleportSpawn()` in `PlayerListener.OnJoin` plus the owner-modus house-diagnostic block there.
- `onMove(PlayerMoveEvent e)` — v1:src/Users/JoinEvents.java:292-305 — the new-player-first-move-teleport trigger, superseded by the `newPlayers.contains(uuid)` block in `PlayerListener.OnMove` (lines 437-440).

Feature allocation: users (join/quit flow, first-join onboarding).

---

## 9. `src/UsefulCommands/StaffChatEvents.java` — all handlers dead/commented

One commented handler: `onCommand(PlayerCommandPreprocessEvent e)` — v1:src/UsefulCommands/StaffChatEvents.java:15-26 (note: the `@EventHandler` annotation itself is double-commented, `////	@EventHandler`, a stray extra `//` suggesting this was disabled even earlier/more deliberately than the single-`//`-commented handlers elsewhere in this slice). Per the comment, rewrote `/sc` to `/staffchat`, identical to the live equivalent now in `PlayerListener.onPreCommand` (lines 695-698), confirming migration. Feature allocation: misc (staffchat shorthand).

---

## 10. `src/Users/Users.java` — verified not a live listener

`Users` `implements Listener` (v1:src/Users/Users.java:38) but contains **no `@EventHandler` methods whatsoever** — it is a static utility/data-access class: UUID↔ID↔username lookups (lines 51-135), daily-stat/playtime-reset routines (137-148, 298-318), donator-rank assignment with reward-item grants (`setDonator`, 150-203), armor damage-reduction calculation (`getDamageReduced`, 205-250), scoreboard refresh (`updateScoreBoard`, 252-257), duplicate-IP-address lookup helpers (259-296, 511-535), user lookup by UUID (`findUser`/`getUser`, 320-365, the latter throwing `UserIsNpcException` for Citizens NPCs and printing a bare "test" exception otherwise — see bug), temp-donator-ID listing (367-387), username-existence check (389-411), staff-chat broadcast helper (`sendStaffMessage`, 413-423, used by whatever staffchat command class exists — out of scope), the **first-join onboarding flow** (`newPlayer`, 425-475 — called directly from `PlayerListener.OnJoin` and `PlayerListener.OnMove`, teleports to the "new" or "spawn" spawnpoint, shows two sequential titles, sends a welcome chat message, starts the intro tutorial, gives the starter kit, and removes the player from `Main.newPlayers` after 3 seconds), and three scheduled-action helpers (`CheckScheduledRank`, `CheckScheduledItems`, `CheckDuplicateAddress`, 477-535, apparently extracted from the dead `JoinEvents.joinMessage` but — per the read of `PlayerListener.OnJoin` above — **not called from the live join handler**, so their current caller, if any, is unclear/out-of-scope for this pass; possibly invoked from `User.join()`, not read here).

Per the task brief's explicit warning, this class was correctly excluded from the handler inventory — it "coincidentally matches a grep for 'Listener'" without being one in practice.

| | |
|---|---|
| Feature allocation | users |
| Bugs/edge cases | `getUser(UUID uuid)` (v1:src/Users/Users.java:336-365): when no matching `User` is found and the UUID also isn't a Citizens NPC, the fallback is `try { throw new Exception("test"); } catch (Exception e) { e.printStackTrace(); }` (lines 355-360) — a placeholder/debug exception with the literal message `"test"`, left in from development, that produces a misleading stack trace in server logs for what is presumably a genuine "user not found" condition; the method then returns `null` from this branch with no `UserNotFoundException` thrown despite one existing and being imported, so every caller that only catches `UserNotFoundException` around a `getUser` call (a pattern seen repeatedly throughout this codebase, e.g. `PlayerListener.OnQuit`'s catch block) will **not** catch this particular failure mode and would instead NPE downstream when using the returned `null`. `isUsedAddress` (line 259-273) has a redundant/confusing check: `if (!list.isEmpty()) { if (list.size() < 1) { used = true; } }` — the inner condition `list.size() < 1` can never be true given the outer `!list.isEmpty()` guard already ensures `size() >= 1`, so `used` is **always left `false`** — this method appears to always return `false`, a likely dead/broken duplicate-address check (compare with the differently-named but similarly-purposed `offlineUser.isUsedAddress`, referenced elsewhere in this slice, e.g. `Listeners/PlayerListener.java`'s imports — out of scope to confirm whether that's a separate, correct implementation actually used instead of this broken one). |
# v1 event listener catalog — Economy slice

Mined from `knk-v1-archive` (see `docs/specs/legacy/commands-v1.md` and
`docs/specs/legacy/user-system.md` for the sibling command/data-model catalogs
and the citation convention this doc follows: `v1:src/Path/File.java:line`).

## Methodology

Full read of the nine files listed in the task brief
(`src/Currency/CheckSalary.java`, `CoinsPickupEvent.java`,
`GemPickupEvent.java`, `IncomePayout.java`, `PlayerPayEvent.java`,
`RentPayment.java`, `SalaryPayout.java`, `src/Votes/VoteEvent.java`,
`src/Skills/SkillPointPickupEvent.java`), plus targeted reads of every custom
event class one of these files listens for (`src/Handlers/KaKEvent.java`,
`IncomePayoutEvent.java`, `SalaryPayoutEvent.java`, `RentPaymentEvent.java`,
`PlayerPayEventHandler.java`) and a grep for every `new <Event>(...)` /
`callEvent(...)` call site that actually fires those custom events, to
establish real triggers (`src/Main/Main.java`, `src/Currency/CoinCommands.java`,
`src/Menu/PlayerManagerClick.java`). `Users.getUser(UUID)`
(`src/Users/Users.java:336`) and `User.saveSalaryTime()` /
`saveIncomeTime()` / `saveRentTime()` (`src/Users/User.java:1535-1554`) were
also read to confirm payout-interval semantics and a null-lookup bug (see
`RentPayment` below). Verbatim-only: nothing here is inferred beyond what the
method bodies actually do; anything not directly readable is marked
unclear/out-of-scope with what would need checking.

Four of the nine files (`IncomePayout`, `PlayerPayEvent`, `RentPayment`,
`SalaryPayout`) are Bukkit `Listener`s, but the event they listen for is a
**custom `org.bukkit.event.Event` subclass** (`Handlers.KaKEvent` and its four
children), not a native Bukkit event — these are fired synchronously via
`Bukkit.getServer().getPluginManager().callEvent(...)` from other code (a
repeating scheduler task in most cases, an admin menu click or a player
command in others), not raised by the server itself. `CheckSalary.java` is
dead code: it `implements Listener` but its only two `@EventHandler` methods
are commented out in their entirety, so the class registers no live handlers.
`CoinsPickupEvent`, `GemPickupEvent`, `SkillPointPickupEvent`, and `VoteEvent`
listen for genuine third-party/Bukkit events (`PlayerPickupItemEvent`,
`VotifierEvent`). None of the nine files define an event that is *also*
consumed reactively within the same file (no file plays both the "fires an
event others listen to" and "listens for a native Bukkit event" role at
once — the custom-event files are pure listeners of events fired elsewhere).

---

## 1. `CheckSalary.java` — dead code, no live handlers

`v1:src/Currency/CheckSalary.java:8` — `public class CheckSalary implements
Listener`. Both `@EventHandler` methods (`RegisterOnJoin` on
`PlayerJoinEvent`, `UnregisterOnLeave` on `PlayerQuitEvent`) are entirely
commented out (`v1:src/Currency/CheckSalary.java:20-41`). The class has no
active handler methods at all — it compiles and can be registered as a
listener, but does nothing. The commented-out code shows intent to warm a
`Main.registeredPlayerSalary` / `Main.registeredPlayerIncome` cache
(referenced as `HashMap<UUID, Integer>`, also commented out at
`v1:src/Currency/CheckSalary.java:17-18`) on join/leave, which appears to have
been superseded by the polling loop in `Main.startvariousTasks()` (see §4-6
below), which reads `user.getSalaryTime()`/`getIncomeTime()` directly off the
live `Users2.users` list every tick instead of a cache.

- **Feature allocation**: economy (intended salary/income bookkeeping),
  currently inert.
- **Bugs/edge cases**: entire class is dead weight — no functional bug since
  there's no functional code, but it's misleading dead code that suggests a
  caching mechanism that doesn't exist anywhere else in the read scope.

---

## 2. `CoinsPickupEvent.java` — coin-nugget/ingot/block pickup → coins

`v1:src/Currency/CoinsPickupEvent.java:18` — `implements Listener`.

### `GoldPickup(PlayerPickupItemEvent e)` — `v1:src/Currency/CoinsPickupEvent.java:26-77`

- **Bukkit event type**: native `org.bukkit.event.player.PlayerPickupItemEvent`.
- **Trigger condition**: a player picks up an item; `Users.getUser(uuid)`
  resolves to a non-null `User` (`:31-32`); the picked-up item's `Material`
  is `GOLD_NUGGET`, `GOLD_INGOT`, or `GOLD_BLOCK` (`:34-35`); and the user is
  not `inOwnerModus()` (`:37`).
- **Goal/function**: cancels the pickup (`e.setCancelled(true)`, `:40`) and
  removes the dropped item entity (`:41`, and again at `:70-73`), so the raw
  gold item never enters the player's inventory. Computes a coin amount:
  - If the item has no `ItemMeta`/lore (`:44`), rolls a random coin value per
    material tier via `main.getRandom(lower, upper)` scaled by stack
    `amount`: nugget `100–10000` (`:48`), ingot `10000–25000` (`:52`), block
    `25000–80000` (`:56`) — then applies `user.getMultipliedInt(coins)`
    (`:58`, presumably a donator/multiplier bonus, not read in this pass).
  - If the item *does* have lore (`:59-67`), instead **parses the coin value
    out of the item's lore text** (`meta.getLore().get(0).split(": ")[1]`,
    `:64`) and multiplies by stack amount (`:65`) — i.e. a specially-crafted
    gold item (likely a reward/shop item elsewhere in the plugin) can encode
    its own coin value, bypassing the random-roll path entirely.
  - Plays `SoundHandler.ITEM_PICKUP` (`:68`), credits the coins via
    `user.addCoins(coins)` (`:69`).
- **Feature allocation**: economy.
- **Bugs/edge cases**:
  - **Unsafe lore parsing** (`:64`): `meta.getLore().get(0).split(": ")[1]`
    has no bounds/format check. If lore exists but line 0 doesn't contain
    `": "`, `split` returns a 1-element array and `[1]` throws
    `ArrayIndexOutOfBoundsException`; if the substring after `": "` isn't a
    valid integer, `Integer.valueOf(...)` throws `NumberFormatException`.
    Either would propagate as an uncaught exception from the event handler
    (Bukkit logs it and disables nothing, but the pickup is left in a
    half-cancelled state — item already removed at `:41` before the parse
    failure).
  - **Redundant double item-removal**: `e.getItem().remove()` is called once
    unconditionally at `:41` and then again, guarded by a pointless
    non-null check, at `:70-73` (`e.getItem()` returns the same `Item`
    entity reference, which is never null here — the guard doesn't protect
    against anything real). Dead/no-op code, not a functional bug.
  - **Magic numbers**: all coin ranges (`100`, `10000`, `25000`, `80000`,
    etc.) are inline literals with no named constants (`:48,52,56`).
  - No check that `e.getItem()` or its `ItemStack` is non-null before
    `:34` — `PlayerPickupItemEvent.getItem()` is documented non-null by
    Bukkit, so this is likely fine, but is asserted rather than verified in
    this pass (unclear/out-of-scope: would need Bukkit API version check).

---

## 3. `GemPickupEvent.java` — diamond/diamond-block pickup → gems

`v1:src/Currency/GemPickupEvent.java:18` — `implements Listener`.

### `GoldPickup(PlayerPickupItemEvent e)` — `v1:src/Currency/GemPickupEvent.java:26-74`

(Method name is a copy-paste leftover from `CoinsPickupEvent` — it handles
gems, not gold.)

- **Bukkit event type**: native `PlayerPickupItemEvent`.
- **Trigger condition**: user resolves via `Users.getUser(uuid)` and is
  non-null (`:31-32`); picked-up `Material` is `DIAMOND` or `DIAMOND_BLOCK`
  (`:35`); the item has **no** `ItemMeta` (`:37`, i.e. lore-tagged diamonds —
  likely shop/reward items — are exempt and pass through untouched, unlike
  `CoinsPickupEvent`'s lore-value path); user is not `inOwnerModus()`
  (`:39`).
- **Goal/function**: cancels the pickup (`:42`). Rolls `random.nextInt(100)`;
  if `<= 80` (80% chance, `:43`) the item converts to gems: `DIAMOND` grants
  `amount * getRandom(1, 15)` gems (`:49`); `DIAMOND_BLOCK` grants
  `amount * getRandom(30, 150)` on a nested 1% roll (`:54-56`) or
  `amount * getRandom(20, 60)` otherwise (`:58-60`) — a "rare jackpot" tier
  inside the outer 80% success roll. Plays `ITEM_PICKUP` sound (`:50,61`),
  applies `user.getMultipliedInt(gems)` (`:63`), credits via
  `user.addGems(gems)` (`:64`), removes the item entity (`:65`). On the
  20% failure branch (`:66-69`), sends a "poor quality" message and — unlike
  the success path — **does not remove the item entity**, even though the
  pickup was already cancelled at `:42`.
- **Feature allocation**: economy.
- **Bugs/edge cases**:
  - **Item never removed on the "poor quality" branch** (`:66-69`): the
    event is cancelled (so it doesn't go to inventory) but `e.getItem()` is
    never removed, so the diamond item entity is left sitting in the world
    at the player's location indefinitely (or until it naturally despawns) —
    inconsistent with the success path's cleanup, and means players could
    potentially re-trigger the pickup event by picking it up again (each
    attempt independently rolling the 80/20 chance) since it's never
    consumed.
  - **Nested magic-number probability**: `80`, `1`, and the four range pairs
    are inline literals (`:43,49,54,56,58-60`).
  - Misleading method name (`GoldPickup` for a diamond/gem handler),
    carried over from `CoinsPickupEvent`.

---

## 4. `IncomePayout.java` — periodic property-income payout

`v1:src/Currency/IncomePayout.java:18` — `implements Listener`, listens for
the **custom event** `Handlers.IncomePayoutEvent` (`extends KaKEvent`,
`v1:src/Handlers/IncomePayoutEvent.java:7`).

### Custom event definition: `Handlers/IncomePayoutEvent.java`

- `v1:src/Handlers/IncomePayoutEvent.java:9-12` — constructor takes a `User`
  and calls `super(user, 4)` (the `4` is `KaKEvent`'s `eventValue`, documented
  only as "Range from 1 to 10" at `v1:src/Handlers/KaKEvent.java:11`; its
  actual consumer, if any, is unclear/out-of-scope — not read by
  `IncomePayout.java`). Exposes only the inherited `getUser()`
  (`v1:src/Handlers/KaKEvent.java:20-23`).

### Fire sites (who triggers this "event")

- `v1:src/Main/Main.java:1020-1023` — inside the repeating task registered at
  `v1:src/Main/Main.java:1190` (`runTaskTimer(this, 10*20, 20)`: 10s initial
  delay, then every `20` ticks = **every 1 second**). For every `User` in
  `Users2.users`, if `current > user.getIncomeTime()`, fires
  `new IncomePayoutEvent(user)`. `saveIncomeTime()` sets the next threshold to
  `current + 43200000L` (`v1:src/Users/User.java:1542-1547`) — **12 hours**,
  so in steady state each user receives at most one income payout per 12h,
  checked at 1-second granularity.
- `v1:src/Menu/PlayerManagerClick.java:328` — an admin-menu click path
  (unclear/out-of-scope exactly which menu action; not in read scope) can
  also force-fire `new IncomePayoutEvent(userTarget)` on demand for an
  arbitrary target user, bypassing the timer check entirely.

### `Payout(IncomePayoutEvent e)` — `v1:src/Currency/IncomePayout.java:28-52`

- **Trigger condition**: `e.getUser()` is non-null (`:32`) — always true in
  practice given both fire sites always construct the event with a resolved
  `User`. Payout only actually happens if
  `property.getIDList(null, null) != null && ...size() != 0 && income > 0`
  (`:38`) — i.e. the server must have at least one property registered
  system-wide (not owned-by-this-user specifically — `getIDList(null, null)`
  passes no owner filter, so this reads as "does *any* property exist
  anywhere", which is a strange gate for a per-user income payout; unclear
  without reading `Property.getIDList` whether `null, null` is scoped some
  other way — flagged as unclear/out-of-scope) and the user's multiplied
  income is positive.
- **Goal/function**: unconditionally calls `user.saveIncomeTime()` first
  (`:34`, reschedules the next 12h window regardless of whether the gated
  payout below actually fires — so a user with `income == 0` or no
  properties registered still has their timer reset and silently receives
  nothing). If the gate at `:38` passes: credits
  `user.addCoins(income)` (`:40`, where `income =
  user.getMultipliedInt(user.getIncome())`, `:37`), sends a
  gender-branched (`male`/`female`) salary-format chat message (`:41-48`),
  plays `SoundHandler.ORB_PICKUP` (`:49`).
- **Feature allocation**: economy.
- **Bugs/edge cases**:
  - **Silent no-op on ungated users**: because `saveIncomeTime()` runs
    unconditionally before the `:38` gate, a user with `income <= 0` (no
    income-producing properties) has their 12h timer reset every cycle they
    become eligible, but never gets a message telling them nothing happened
    — indistinguishable from a payout that simply granted 0, from the
    player's perspective (no message at all).
  - **No null check on `player`**: `Bukkit.getServer().getPlayer(user
    .getUsername())` (`:36`) returns `null` if the user is offline; `player`
    is then used unguarded at `:44/45/47/49` (`player.sendMessage(...)`,
    `player.playSound(...)`) *inside* the `:38` gated block — if income is
    positive and properties exist for an **offline** user (the timer check
    at the Main.java fire site iterates all users regardless of online
    status, `:1014`), this throws a `NullPointerException` from inside the
    event handler on every tick that user remains eligible and offline.
    This is the same missing-null-check pattern flagged across the codebase
    in `commands-v1.md`.
  - `gender` neither "male" nor "female" (e.g. unset/default) silently sends
    no message at all (no `else` branch, `:41-48`) even though coins were
    already credited — silent-partial-feedback bug, same family as the
    "permission check without else" pattern noted in `commands-v1.md`.

---

## 5. `PlayerPayEvent.java` — experience reward for player-to-player pay

`v1:src/Currency/PlayerPayEvent.java:13` — `implements Listener`, listens for
custom event `Handlers.PlayerPayEventHandler` (`extends KaKEvent`,
`v1:src/Handlers/PlayerPayEventHandler.java:9`).

### Custom event definition: `Handlers/PlayerPayEventHandler.java`

- `v1:src/Handlers/PlayerPayEventHandler.java:14-20` — constructor
  `(User user, Integer coinamount, UUID targetUUID)`, calls
  `super(user, 5)`. Stores `targetUUID` and `coinamount` as fields, exposes
  `getTargetUUID()` and `getInteger()` (the coin amount) in addition to the
  inherited `getUser()`.

### Fire site

- `v1:src/Currency/CoinCommands.java:66` — fired from the `/pay` (or similar)
  command handler: `new PlayerPayEventHandler(user, Integer.valueOf(args[2])
  .intValue(), target.getUUID())`, where `user` is presumably the **payer**
  (unclear/out-of-scope — would need to read `CoinCommands.java` in full to
  confirm which side is `user` vs `target`; based on `PlayerPayEvent`'s
  behavior below, granting XP to `e.getUser()` for "trading with"
  `user.getUsername()", it reads as if `e.getUser()` is the **recipient**
  being rewarded, i.e. `user` at the fire site is actually the payment
  recipient, not the payer — needs confirmation against `CoinCommands.java`
  which is out of this slice's read scope).

### `Pay(PlayerPayEventHandler e)` — `v1:src/Currency/PlayerPayEvent.java:21-34`

- **Trigger condition**: fires whenever `/pay`-equivalent fires the custom
  event (no additional gate inside this handler beyond the null check
  described below).
- **Goal/function**: computes `experience = round((coinamount/100)*1)`
  (`:29`) and grants it via `user.addExperience(experience, true)` (`:30`),
  plays `ORB_PICKUP` sound (`:31`), sends an achievement-style chat message
  naming `user.getUsername()` as the trade partner (`:32`).
- **Feature allocation**: economy (coin transfer) with a spillover into
  leveling/experience — cross-domain (economy → XP/leveling system); the XP
  grant here is the *only* side effect of this listener, i.e. `PlayerPayEvent`
  doesn't itself move any coins (that presumably already happened in
  `CoinCommands` before firing the event) — this listener is purely the
  "reward the recipient with bonus XP for receiving a payment" step.
- **Bugs/edge cases**:
  - **Null check ordering bug**: `User user = e.getUser();` (`:24`) then
    `Player player = user.getPlayer();` (`:25`) is called **before** the
    `if (user != null)` guard on `:26`. If `e.getUser()` is ever null, this
    throws `NullPointerException` at `:25`, making the subsequent null check
    at `:26` dead/unreachable protection — it can never actually catch a
    null `user` because the code already crashed one line earlier. Exact
    same "null check placed after the use it's supposed to guard" bug
    pattern.
  - **Integer-division bug**: `(coinamount/100)*1` (`:29`) — integer
    division truncates before the (no-op) `*1` multiply, so e.g. paying
    `150` coins yields `experience = round((150/100)*1) = round(1) = 1`, not
    `1.5`→`2` or any fractional-aware value; the `Math.round(...)` call is
    pointless since the input to it is already a truncated integer (the
    `/100` and the outer `Math.round` can never interact meaningfully — this
    is the same class of integer-division-then-round dead-precision bug
    flagged elsewhere in v1 per the task brief). The stray `*1` is a no-op,
    likely a leftover from a previously-tunable multiplier.
  - No null check on `player` (`Bukkit`/`user.getPlayer()` could return null
    if recipient is offline) before `player.playSound`/`sendMessage`
    (`:31-32`) — same offline-player NPE risk as `IncomePayout`.

---

## 6. `RentPayment.java` — periodic room-rent collection

`v1:src/Currency/RentPayment.java:24` — `implements Listener`, listens for
custom event `Handlers.RentPaymentEvent` (`extends KaKEvent`,
`v1:src/Handlers/RentPaymentEvent.java:10`).

### Custom event definition: `Handlers/RentPaymentEvent.java` — **confirmed bug**

- `v1:src/Handlers/RentPaymentEvent.java:12` declares `UUID uuid;` as an
  instance field, but **no constructor ever assigns it**. The constructor
  (`:15-18`) only calls `super(user, 3)` and does nothing else — `uuid`
  stays at its default value `null` for the entire lifetime of every
  `RentPaymentEvent` instance. `getUUID()` (`:20-23`) therefore **always
  returns `null`**, unconditionally, regardless of which `User` the event
  was constructed with.

### Fire site

- `v1:src/Main/Main.java:1038`, inside the same 1-second repeating task as
  §4/§7 (`runTaskTimer(this, 10*20, 20)`, `v1:src/Main/Main.java:1190`): for
  every room in `room.getRoomIDList(null)` with a non-zero `ownerID`
  (`:1027-1028`), if the owner hasn't logged in for 7+ days the room is
  force-repossessed with a console message (`:1032-1035`); otherwise, if
  `current > owner.getRentTime()`, fires `new RentPaymentEvent(owner)`
  (`:1038`). `saveRentTime()` sets the next threshold to `current +
  3600000L` (`v1:src/Users/User.java:1549-1553`) — **1 hour** cadence.

### `Payout(RentPaymentEvent e)` — `v1:src/Currency/RentPayment.java:35-80`

- **Trigger condition (as coded)**: `UUID uuid = e.getUUID();` (`:38`) then
  `User user = Users.getUser(uuid);` (`:39`) then `if (user != null)`
  (`:40`).
- **Goal/function (as designed, never actually reached — see bug below)**:
  saves a new rent-time window (`:42`), looks up the room by owner
  (`:45`), and if the owner can afford the rent, deducts coins
  (`user.removeCoins(rent)`, `:51`) and sends a gender-branched confirmation
  message (`:53-60`); otherwise (`:61-76`) sends an eviction message, calls
  `room.removeOwnerID(roomID)`, decrements the user's owned-room count
  (`user.removeRoomAmount(false, 1)`, `:66`), clears their rent timer
  (`user.removeRentTime()`, `:67`), pulls the WorldGuard `RegionManager` for
  the player's world and calls `room.removeRegionOwner(...)` to strip
  region-protection ownership (`:68-69`), and if the room had a spawnpoint
  that was also the user's personal spawnpoint, clears it
  (`:71-75`). Plays `SoundHandler.NOTE_BASS` either way (`:77`).
- **Feature allocation**: economy (rent collection) with property-ownership
  side effects (cross-domain into the property/room system —
  `Rooms.Room`, WorldGuard region ownership).
- **Bugs/edge cases — critical**:
  - **This entire handler is dead in practice.** Because
    `RentPaymentEvent.getUUID()` always returns `null`
    (`v1:src/Handlers/RentPaymentEvent.java:12,20-23`), the call
    `Users.getUser(null)` at `v1:src/Currency/RentPayment.java:39` loops over
    `Users2.users` comparing `user.getUUID().equals(null)`
    (`v1:src/Users/Users.java:342`), which is `false` for every entry (a
    non-null UUID's `.equals(null)` is always `false`), so `us` stays `null`
    through the loop and the lookup falls through to
    `Users.java:350`'s `CitizensAPI.getNPCRegistry().getByUniqueId(uuid)`
    check with `uuid == null` (behavior of that call with a null argument is
    unclear/out-of-scope — would need to read further into `Users.getUser`
    past line 351 and the Citizens API contract, but either it returns null
    or throws). In the null-returning case, `Users.getUser(null)` resolves
    to `null`, the `if (user != null)` guard at `:40` fails, and **the
    entire rent-collection/eviction body never executes** — meaning in the
    live game, this scheduled rent-payment path silently does nothing: no
    rent is ever collected and no auto-eviction for unpaid rent ever
    happens via this event, despite `Main.java`'s polling loop correctly
    identifying eligible owners every hour and firing the event as designed.
    The intended behavior can only be recovered by fixing
    `RentPaymentEvent` to actually store and return the owner's UUID (e.g.
    assigning `this.uuid = user.getUUID()` in its constructor, mirroring
    what `PlayerPayEventHandler` correctly does for its own fields).
  - Downstream of the above (would matter if the UUID bug were fixed): no
    null check on `player` (`Bukkit.getServer().getPlayer(...)`, `:44`)
    before use at `:56/59/63/74/77` — same offline-player NPE risk pattern
    as `IncomePayout`/`PlayerPayEvent`. Since `Main.java`'s fire site doesn't
    filter for online owners, an offline owner with unpaid rent would crash
    this handler on the very first line that touches `player`, *if* the
    UUID bug weren't already short-circuiting everything before it gets
    there.
  - `gender` neither "male" nor "female" again silently sends no confirmation
    message on the success branch (`:53-60`, no `else`) — same pattern as
    `IncomePayout`/`SalaryPayout`.

---

## 7. `SalaryPayout.java` — periodic title-based salary payout

`v1:src/Currency/SalaryPayout.java:17` — `implements Listener`, listens for
custom event `Handlers.SalaryPayoutEvent` (`extends KaKEvent`,
`v1:src/Handlers/SalaryPayoutEvent.java:9`).

### Custom event definition: `Handlers/SalaryPayoutEvent.java`

- `v1:src/Handlers/SalaryPayoutEvent.java:11-17` — declares an unused
  `UUID uplayer;` field (`:11`) that, like `RentPaymentEvent.uuid`, is never
  assigned in the constructor — but unlike `RentPaymentEvent`, **nothing in
  `SalaryPayout.java` ever calls `getUUID()`**, so this particular dead field
  is harmless (it's simply never read). `getUUID()` exists (`:19-22`) but is
  unused dead code as far as this handler is concerned.

### Fire sites

- `v1:src/Main/Main.java:1018`, same 1-second repeating task as §4/§6
  (`v1:src/Main/Main.java:1190`): for every `User` in `Users2.users`, if
  `current > user.getSalaryTime()`, fires `new SalaryPayoutEvent(user)`.
  `saveSalaryTime()` sets the next threshold to `current + 3600000L`
  (`v1:src/Users/User.java:1535-1539`) — **1 hour** cadence.
- `v1:src/Menu/PlayerManagerClick.java:308` — admin-menu-triggered forced
  payout for an arbitrary target user, same pattern as `IncomePayout`'s
  second fire site.

### `Payout(SalaryPayoutEvent e)` — `v1:src/Currency/SalaryPayout.java:27-54`

- **Trigger condition**: `e.getUser()` non-null (`:32`) — always true given
  both fire sites.
- **Goal/function**: calls `main.DBreconnect()` **unconditionally as the
  first line of the handler**, before even the null check (`:30`) — this
  closes and reopens the plugin's database connection
  (`v1:src/Main/Main.java:849-855`: `getConnection().close(); DBconnect();`)
  on every single salary payout. Then computes
  `coins = user.getMultipliedInt(title.getSalary(user.getTitleID()))`
  (`:35-36`), credits via `user.addCoins(coins)` (`:37`), reschedules via
  `user.saveSalaryTime()` (`:38`), sends a gender-branched message — but
  unlike `IncomePayout`/`RentPayment`, this one **has** a fallback `else`
  branch (`:48-51`) that defaults to the male-phrased message for any
  unrecognized gender, so (unlike the other two payout handlers) every
  successful payout does produce a message. Plays `ORB_PICKUP` (`:52`).
- **Feature allocation**: economy.
- **Bugs/edge cases**:
  - **Unconditional DB reconnect on every payout tick** (`:30`): since the
    fire site (`Main.java:1014-1019`) loops over *all* users every second
    and can fire one `SalaryPayoutEvent` per eligible user per tick, a
    server with many users becoming salary-eligible around the same time
    (e.g. right after a restart, when everyone's `salaryTime` may be stale/
    in the past) would call `main.DBreconnect()` — closing and reopening
    the plugin's single shared JDBC connection
    (`v1:src/Main/Main.java:849-855`) — once per user, back-to-back, on the
    main thread. This is a connection-thrashing bug: any other code
    concurrently relying on `getConnection()` (e.g. another handler mid-query
    on the same shared connection object, since there's no visible
    connection pool in this read scope) would have its connection yanked out
    from under it. Also a needless per-payout performance cost even in the
    single-user case — reconnecting to the DB is expensive relative to a
    simple coin-credit.
  - No null check on `player` (`Bukkit.getServer().getPlayer(user
    .getUsername())`, `:34`) before use at `:44/47/50/52` — same
    offline-player NPE risk as the other two scheduled payout handlers.
    Notably, `SalaryPayoutEvent`'s only fire condition from the timer loop
    is `current > user.getSalaryTime()` with **no online-status check**
    (`v1:src/Main/Main.java:1014-1019` iterates `Users2.users` unconditionally),
    so an offline user whose salary timer has lapsed would crash this
    handler the moment the next 1-second tick fires — this looks like it
    would trigger routinely (any offline player who stays offline past
    their next 1h salary window), not just as a rare race.
  - Commented-out dead line `//Main.registeredPlayerSalary.put(uuid,
    user.getSalaryTime());` (`:39`) — leftover from the same abandoned
    caching approach seen in `CheckSalary.java`.

---

## 8. `VoteEvent.java` — Votifier vote reward

`v1:src/Votes/VoteEvent.java:28` — `implements Listener`.

### `onVote(VotifierEvent e)` — `v1:src/Votes/VoteEvent.java:37-98`

- **Bukkit event type**: third-party `com.vexsoftware.votifier.model
  .VotifierEvent` (Votifier plugin's custom event, fired by that plugin when
  an external vote-site vote is recorded — not a native Bukkit event, and
  not one this file defines itself; it's a pure consumer of another plugin's
  event).
- **Trigger condition**: a vote arrives via Votifier; `player =
  Bukkit.getPlayer(username)` must resolve (no null check — see bug below);
  `Users.getUser(uuid)` must succeed (guarded by try/catch for
  `UserNotFoundException` and generic `Exception`, `:46-58`, both of which
  call `ErrorHandlers.userNotFoundAction(...)` and `return`).
- **Goal/function**: increments the user's vote counter
  (`user.addVotes(1)`, `:61`), then branches on `user.getDonatorName()`
  (`default`/`noble`/`royal`/`dragon blood`, `:62-97`) to pick escalating
  reward ranges (coins, gems, exp) and calls the local `vote(...)` helper
  (`:69,78,87,96`). Any donator tier not in this exact set of four strings
  (case-insensitive) — e.g. a typo, a future tier, or `null` — silently
  falls through with **no reward at all** and no fallback branch (`:62-97`,
  no final `else`).
  - Inside `exp` computation for each tier (`:64-68` etc.): `exp =
    user.getExpPart(10)`, with a `main.getRandom(0,10) <= 4` (40% chance)
    upgrade to `user.getExpPart(15)` — same four-line block duplicated
    verbatim across all four tiers (`:64-68, 73-77, 82-86, 91-95`).
- **`vote(Player player, Integer coins, Integer gems, Integer exp)` helper**
  (`v1:src/Votes/VoteEvent.java:100-168`) — re-resolves `User` from
  `player.getUniqueId()` independently (redundant second lookup + redundant
  second try/catch identical to `onVote`'s, `:106-118`). Computes
  `realcoins`: `titleID == 0` → `coins*1` (no-op multiply, `:123`);
  `titleID > 0` → `coins*(titleID/2)` (`:126`, **integer-division bug** —
  see below). Applies `getMultipliedInt` to coins/gems/exp (`:128-130`),
  plays `LEVEL_UP` sound (`:131`), credits coins/gems/exp (`:132-134`),
  server-broadcasts a formatted vote-reward summary to all players
  (`:135-142`), then rolls a **second** independent `product` shop-item
  reward from a shuffled ID list with `gradeChance` gating and a `break` on
  first success (`:144-154`), then on a **third** independent roll
  (`main.getRandom(0,100) <= 50`, using the *same* `random` variable
  computed once at `:135` — not re-rolled — so this bonus's probability is
  coupled to whatever value was already drawn for the broadcast, not an
  independent 50% check each time) grants gold nuggets + drops cooked mutton
  with a broadcast (`:156-161`), and finally (`random <= 1`, again reusing
  the same single `random` draw) grants a bonus skill point with a
  broadcast (`:162-166`).
- **Feature allocation**: economy (coins/gems primary), with clear
  cross-domain spillover into experience/leveling (`addExperience`), the
  item/product shop system (`product.createPropertyItem`,
  `gradeChance`), and skills (`addSkillPoints`) — this is the most
  cross-domain file in the slice.
- **Bugs/edge cases**:
  - **No null check on `player`** (`Bukkit.getPlayer(username)`, `:42`)
    before `player.getUniqueId()` at `:43` — if Votifier reports a vote for
    a username that isn't currently online (a very plausible real-world
    case — most vote sites don't require the player to be online at the
    moment the vote registers), this throws an immediate
    `NullPointerException` before the try/catch block even starts, so the
    vote is lost with no `ErrorHandlers` feedback at all — worse than the
    handled `UserNotFoundException` case just below it.
  - **Integer-division bug in `realcoins`** (`:126`): `coins*(user
    .getTitleID()/2)` truncates `titleID/2` before multiplying, so any user
    with `titleID == 1` gets `realcoins = coins*0 = 0` — a title-1 donator
    voting receives **zero** coin reward from this multiplier path (worse
    than `titleID == 0`, which explicitly gets `coins*1`), which is almost
    certainly not the intended "higher title = more reward" curve. Same
    integer-division-truncation bug family called out in the task brief.
  - Unnecessary/confusing `(Integer) exp/10` cast in the four `getRandom(...)`
    calls (`:69,78,87,96`) — casts an `int` division result to `Integer`
    for no functional reason (auto-boxing already happens), then divides
    `exp` by `10` as the random lower bound, which is itself another
    integer-division point (not necessarily wrong, but yet another
    truncating division in the same reward pipeline).
  - **Reused single random roll for two independent-looking bonus checks**:
    `Integer random = main.getRandom(0, 100);` is drawn once (`:135`) and
    then tested against two different thresholds (`<= 50` at `:156`, `<= 1`
    at `:162`) as if they were separate probability checks — in reality
    they're the same draw, so the "super lucky" skill-point bonus
    (nominally documented by its threshold as a 1-in-100 event) can only
    ever fire on draws that *also* satisfy the `<= 50` gold-nugget bonus
    (since `1 <= 50` always), meaning the two bonuses are not independent
    the way the separate `if` blocks visually suggest — anyone who gets the
    skill point always also gets the gold nuggets/mutton in the same vote,
    and the two "chances" are fully correlated rather than independent 50%
    and 1% events.
  - Four tiers' worth of near-identical `exp` computation logic
    (`:64-68,73-77,82-86,91-95`) duplicated verbatim rather than factored
    into a helper — not a bug, but a maintenance/consistency risk (a fix to
    one copy is easy to miss in the other three).

---

## 9. `SkillPointPickupEvent.java` — emerald/emerald-block pickup → skill points

`v1:src/Skills/SkillPointPickupEvent.java:20` — `implements Listener`.

### `EmeraldPickup(PlayerPickupItemEvent e)` — `v1:src/Skills/SkillPointPickupEvent.java:28-88`

- **Bukkit event type**: native `PlayerPickupItemEvent`.
- **Trigger condition**: `Users.getUser(uuid)` resolves (guarded by the same
  try/catch-`UserNotFoundException`/generic-`Exception` pattern as
  `VoteEvent`, `:35-47`, both branches call `ErrorHandlers
  .userNotFoundAction(...)` and `return`); picked-up `Material` is `EMERALD`
  or `EMERALD_BLOCK` (`:49`); item has no `ItemMeta` (`:51`); and — using a
  **different** owner-mode check than `CoinsPickupEvent`/`GemPickupEvent`
  (which call `user.inOwnerModus()`) — `!main.ownermodus.containsKey(uuid)
  || main.ownermodus.get(uuid) == false` (`:53`, reads `Main`'s own
  `ownermodus` map directly instead of going through the `User` object).
- **Goal/function**: cancels the pickup (`:56`); rolls `random.nextInt(100)
  <= 80` (80% success, `:57`, same shape as `GemPickupEvent`); on success,
  `EMERALD` grants `amount * getRandom(0, 1)` points (`:63`, i.e. **0 or 1**
  skill points per emerald in the stack — effectively a coin-flip per
  pickup, not a meaningful "amount"-scaled reward the way coins/gems are);
  `EMERALD_BLOCK` grants `amount * getRandom(2,5)` on a nested 1% roll
  (`:69`) or `amount * getRandom(4,10)` otherwise (`:72`); plays
  `ITEM_PICKUP` sound (`:75`), applies `user.getMultipliedInt(points)`
  (`:77`), credits via `user.addSkillPoints(false, points)` (`:78`), removes
  the item (`:79`). On the 20% failure branch (`:80-83`), sends a message.
- **Feature allocation**: **skills** (skill-point currency), not economy in
  the coins/gems sense — flagged as cross-domain per the task brief's
  instruction to note anything not clearly `economy`. It's included in this
  slice because it's structurally identical to `GemPickupEvent`/
  `CoinsPickupEvent` (same pickup-cancel-reroll-as-resource pattern) and
  file path (`src/Skills/`) confirms it's filed under the Skills domain, not
  Currency, in the actual source tree.
- **Bugs/edge cases**:
  - **Copy-paste message bug**: the failure message says `"Unfortunatly this
    Gem was of poor quality so you didn't receive any gems!"`
    (`v1:src/Skills/SkillPointPickupEvent.java:82`) — but this handler is
    about **emeralds/skill points**, not gems; the message text is a direct
    copy from `GemPickupEvent.java:68` (verbatim match) and was never
    updated. Players failing an emerald pickup roll get told about a "Gem"
    that doesn't exist in this transaction.
  - **Item never removed on the failure branch** (`:80-83`), same bug as
    `GemPickupEvent` — the pickup is cancelled but the item entity is left
    in the world uncollected, re-triggering the pickup roll on every
    subsequent attempt.
  - **`EMERALD` reward is effectively a binary 0/1** regardless of stack
    `amount` beyond the first unit's randomness — `getRandom(0,1)` returns
    0 or 1 once, then multiplies by `amount`, so picking up a stack of 64
    emeralds yields either `0` or `64` skill points, never anything in
    between — almost certainly not the intended scaling (compare
    `GemPickupEvent`'s `DIAMOND` case, which uses `getRandom(1,15)`, a real
    range, for the equivalent single-item tier).
  - **Inconsistent owner-mode check** vs. the sibling pickup handlers
    (`main.ownermodus.get(uuid) == false` direct map read here, vs.
    `user.inOwnerModus()` method call in `CoinsPickupEvent`/
    `GemPickupEvent`) — not necessarily a bug if both ultimately read the
    same underlying state, but it's an inconsistency worth flagging;
    confirming they're equivalent would require reading `User
    .inOwnerModus()`'s implementation, which is unclear/out-of-scope for
    this slice.
  - Same nested magic-number probabilities (`80`, `1`, range pairs) as
    `GemPickupEvent`, uncommented (`:57,63,67,69,72`).

---

## Cross-file observations (read before treating these as nine isolated bugs)

- **The "null check placed after the code it's supposed to guard" pattern**
  recurs three times in this slice alone: `PlayerPayEvent.java:24-26`
  (`user.getPlayer()` called before the `user != null` check),
  `VoteEvent.java:42-43` (`player.getUniqueId()` called with no null check on
  `player` at all, not even a misplaced one), and implicitly in every
  scheduled payout handler (`IncomePayout`, `SalaryPayout`, `RentPayment`)
  where `Bukkit.getServer().getPlayer(username)` is never null-checked before
  use — this looks like a systemic gap in this codebase's offline-player
  handling for anything fired from a server-side scheduler rather than a
  direct player action.
- **Two of the four custom `KaKEvent` payout events have a UUID field that's
  declared but never assigned in the constructor** (`RentPaymentEvent.uuid`,
  `SalaryPayoutEvent.uplayer`) — in `RentPaymentEvent`'s case this is not
  cosmetic dead code, it's a live, silent, total-failure bug that appears to
  disable rent collection entirely (see §6). `PlayerPayEventHandler`, by
  contrast, correctly assigns its `targetUUID`/`coinamount` fields in its
  constructor (`v1:src/Handlers/PlayerPayEventHandler.java:17-18`), showing
  the correct pattern exists elsewhere in the same file family, making the
  other two look like copy-paste omissions rather than an unfinished
  feature.
  - **`gender` fall-through silently drops the success message** in
  `IncomePayout` and `RentPayment` (no final `else`) but not in
  `SalaryPayout` (which has one) — inconsistent even among three near-
  identical payout handlers in the same package.
- **Integer-division-then-multiply reward bugs** appear at least twice in
  this slice (`PlayerPayEvent.java:29`, `VoteEvent.java:126`), matching the
  task brief's expectation of finding the same bug family seen elsewhere in
  v1.
- **The 1-second global polling loop** (`Main.startvariousTasks()`,
  `runTaskTimer(this, 10*20, 20)`, `v1:src/Main/Main.java:1190,994-1189`)
  is the shared trigger mechanism for `IncomePayout` (12h cadence),
  `SalaryPayout` (1h cadence), and `RentPayment` (1h cadence, though
  effectively inert per §6) — it iterates the **entire** `Users2.users` list
  every second checking three separate time thresholds, which is a
  reasonable design for a modest player base but has no batching/early-exit
  and, combined with `SalaryPayout`'s per-event `DBreconnect()` call, could
  become a real bottleneck as `Users2.users` grows (unclear/out-of-scope:
  would need production player-count numbers to assess actual severity).

---

## Coverage summary

All nine files in the assigned slice were read in full. Every `@EventHandler`
method across them (7 total: `CoinsPickupEvent.GoldPickup`,
`GemPickupEvent.GoldPickup`, `IncomePayout.Payout`, `PlayerPayEvent.Pay`,
`RentPayment.Payout`, `SalaryPayout.Payout`, `VoteEvent.onVote`) is
documented above, plus `CheckSalary.java`'s two commented-out
(non-functional) handlers and `SkillPointPickupEvent.EmeraldPickup`, for
**8 live `@EventHandler` methods + 2 dead/commented-out ones across 9
files**. Five custom-event source files (`KaKEvent`, `IncomePayoutEvent`,
`SalaryPayoutEvent`, `RentPaymentEvent`, `PlayerPayEventHandler`) and their
fire sites in `Main.java`, `CoinCommands.java`, and `PlayerManagerClick.java`
were additionally read to ground every "trigger condition" claim in this
document in actual code rather than inference. One confirmed critical bug
(`RentPaymentEvent`'s always-null UUID silently disabling rent collection)
and roughly a dozen smaller bugs/edge cases were found and cited above.
# v1 Bukkit Event Listeners — Combat & Special-Skills Slice

**Status:** draft catalog (source-grounded)
**Scope:** `src/KillsDeaths/{CombatCheck,KillDeathStat,RespawnLocation}.java`, `src/Listeners/DoubleDamageListener.java`, `src/Skills/{AssassinSkill,AttackSpeedEvent,AvengerSkill,DefenseEvent,ForgerSkill,HealthEvent,JuggernautSkill,NinjaSkill,PickpocketSkill,ShotbowSkill,SpeedEvent,StrengthEvent}.java`

## Methodology

Every file in the assigned slice was read in full from `C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-v1-archive` (cited below as `v1:src/...`). For each class, every `@EventHandler`-annotated method was catalogued individually — including handlers that are present in source but **commented out** (`//`-prefixed), since in this codebase commenting out a whole method is the de facto mechanism for disabling a listener without deleting it, and the ratio of live-vs-dead handlers turned out to be the single most important fact about this slice. Where a class's Bukkit logic is duplicated or superseded elsewhere (this happened repeatedly — see below), the superseding file was located via `Grep` for the relevant field/constructor names and read for cross-reference context only; it is **not** itself part of this catalog and was not exhaustively audited. Trigger conditions and formulas are quoted/paraphrased directly from the method bodies with line citations; nothing below is inferred beyond what the code states. Random rolls in this codebase use `Random.nextInt(100) <= N` or the project's `main.getRandom(min, max)` helper — both are noted verbatim per handler since the two are not equivalent (`nextInt(100) <= N` is a 0–99 roll against N, i.e. effectively `N+1`⁄100 chance; this is flagged where relevant).

## Headline finding: most of this slice is dead code

Of the 16 files and ~30 `@EventHandler` methods present in source, **only 7 handlers across 6 files are actually live** (not commented out). The other ~23 are fully commented-out method bodies retained as either history or as reference pseudocode. In several cases the *logic itself is not gone* — it was copy-pasted (in some cases verbatim, in others lightly adapted) into a single consolidated handler, `Listeners/EntityListener.java#onHit(EntityDamageByEntityEvent)` (`v1:src/Listeners/EntityListener.java:52`), which is **outside this assigned slice** but is cited throughout as the actual live implementation superseding the dead per-skill classes. This file was not exhaustively audited (that's presumably another slice's job) but was read far enough to confirm which of the assigned classes' commented-out logic it replaces, and to check it for the same bug classes this task asks about.

Live handlers in the assigned slice:
1. `CombatCheck#onEnter(EnterTownEvent)` — `v1:src/KillsDeaths/CombatCheck.java:186`
2. `KillDeathStat#ExpMobKill(EntityDeathEvent)` — `v1:src/KillsDeaths/KillDeathStat.java:237`
3. `DoubleDamageListener#DoubleDamage(DoubleDamage)` — `v1:src/Listeners/DoubleDamageListener.java:19`
4. `AssassinSkill#assassin(PlayerToggleSneakEvent)` — `v1:src/Skills/AssassinSkill.java:39`
5. `ForgerSkill#onPurchase(PurchaseEvent)` — `v1:src/Skills/ForgerSkill.java:31`
6. `HealthEvent#Health(NewSkillHandler)` — `v1:src/Skills/HealthEvent.java:75`
7. `PickpocketSkill#Pickpocket(PlayerInteractEntityEvent)` — `v1:src/Skills/PickpocketSkill.java:37`
8. `ShotbowSkill#Shotbow(EntityShootBowEvent)` — `v1:src/Skills/ShotbowSkill.java:30`
9. `SpeedEvent#SpeedWalk3(NewSkillHandler)` — `v1:src/Skills/SpeedEvent.java:86`

(That's 9, not 7 — corrected count; see per-file breakdown below for the exact tally including `RespawnLocation.java`, which is **100% dead**: 0 live handlers.)

All handlers use default `@EventHandler` priority except `DefenseEvent`'s dead handler (`EventPriority.HIGHEST`, commented) and the live `EntityListener#onHit` (`EventPriority.HIGHEST`, `v1:src/Listeners/EntityListener.java:52`). None in this slice declare `ignoreCancelled`.

---

## `KillsDeaths/CombatCheck.java`

Class-level: `public static Integer combat = 10;` and `HashMap<Player, Integer> incombat` (`v1:src/KillsDeaths/CombatCheck.java:35-36`) — a "you are in combat, don't log off" tracker.

### DEAD: `onHit(EntityDamageByEntityEvent)` — `v1:src/KillsDeaths/CombatCheck.java:38-111` (fully commented out)
- **Trigger (as written):** damager and damaged both `Player`; damaged not inside a `town` WorldGuard region unless inside an `arena` sub-region; not inside a `property` region.
- **Goal:** puts both combatants into `incombat` with a 10-tick(?) counter (`combat = 10`), sends an ActionBar "You are now in combat! Do not log off", but only for players in `GameMode.SURVIVAL` who are not `inStaffModus()`/`inOwnerModus()`.
- **Feature allocation:** `siege-minigame` (combat-lockout / anti-logout mechanic).
- **Note:** dead; superseded by nothing found in this slice — `Main.combatlogged` (referenced by the also-dead `onQuit`) still exists as a static list in `Main.java` but nothing in the live code populates it from this class.

### DEAD: `onQuit(PlayerQuitEvent)` — `v1:src/KillsDeaths/CombatCheck.java:113-158`
- **Trigger:** player is a key in `incombat`.
- **Goal:** zeroes the player's health (`player.setHealth(0.0D)`) — i.e. kills them for combat-logging — adds them to `Main.combatlogged`, removes them from `incombat`, and notifies staff. Item-drop-on-combat-log logic is itself commented out inside the commented method (a second, deeper layer of dead code, `v1:src/KillsDeaths/CombatCheck.java:119-152`).
- **Feature allocation:** `siege-minigame`.

### DEAD: `onJoin(PlayerJoinEvent)` — `v1:src/KillsDeaths/CombatCheck.java:160-170`
- **Trigger:** `Main.combatlogged.contains(uuid)`.
- **Goal:** informs the rejoining player their inventory was dropped, then clears them from `combatlogged`.
- **Bug/edge case:** import for `PlayerJoinEvent`/`UUID` never appears at file top — irrelevant since dead, but note this was never compiled as active code (further evidence it's stale reference code, not a "temporarily disabled" feature).

### DEAD: `onDeath(PlayerDeathEvent)` — `v1:src/KillsDeaths/CombatCheck.java:172-183`
- **Trigger:** dying entity is a `Player` present in `incombat`.
- **Goal:** removes them from `incombat` (so death exits combat state).

### LIVE: `onEnter(EnterTownEvent)` — `v1:src/KillsDeaths/CombatCheck.java:185-195`
- **Bukkit event type:** not a Bukkit-core event — `Handlers.EnterTownEvent`, a custom plugin event, default priority. Fired from `v1:src/Towns/TownEvents.java:124` via `Bukkit.getServer().getPluginManager().callEvent(new EnterTownEvent(user, townID))`.
- **Trigger condition:** `incombat.containsKey(player)` — i.e., this only fires meaningfully if something elsewhere still populates `incombat`. Since the only writer of `incombat` in this class is the dead `onHit` handler above, **and no other file in this slice writes to `CombatCheck.incombat`**, this live handler is currently unreachable in practice (the map it reads is never populated by any live code found so far) — flagged as unclear/out of scope whether something outside this slice populates it (`Main.java` has its own separate `incombat` field of type `HashMap<User, Long>`, a *different* map, so it does not feed this one).
- **Goal/function:** removes the player from `incombat` and sends an ActionBar "Out of combat!" (`ColorOptions.messagesubjects`).
- **Feature allocation:** `siege-minigame`.
- **Bug:** as noted, the map this reads appears to be dead/orphaned given the corresponding writer is commented out — likely a vestige of a half-removed feature.

---

## `KillsDeaths/KillDeathStat.java`

### DEAD: `Kill(PlayerDeathEvent)` — `v1:src/KillsDeaths/KillDeathStat.java:51-234` (fully commented out, by far the largest handler in the slice)
This is the canonical "PvP kill" handler: coin/item drop-on-death economy, K/D stat increments, assignment progress, and experience payout. Since it's entirely commented out it is cataloged only at a summary level (per instructions not to skip minor things, but this is a single dead block, not several):
- **Trigger:** `e.getEntity().getKiller() instanceof Player && e.getEntity() instanceof Player` (PvP kill branch), else `e.getEntity() instanceof Player` alone (PvE/environmental death branch).
- **Goal (PvP branch):** drops 10% (`part = 10`) of the victim's coins as `GOLD_INGOT` stack items with custom lore (`v1:src/KillsDeaths/KillDeathStat.java:106-115`); strips all death-drops except items with product "grade" > 3 (kept items are stashed in a static `respawn` map keyed by UUID for later re-give, `v1:src/KillsDeaths/KillDeathStat.java:119-159`); advances the killer's `AssignmentKill` bounty progress if not "only bandits" (`v1:src/KillsDeaths/KillDeathStat.java:165-176`); increments killer kills/exp and victim deaths (`v1:src/KillsDeaths/KillDeathStat.java:177-185`); messages killer with exp gained.
- **Goal (PvE/self-death branch):** flat 20% coin loss (`coins/5`, `v1:src/KillsDeaths/KillDeathStat.java:216-218` — comment/message says "20%" but this is a `/5` = exactly 20%, consistent), zeroes dropped XP, and stashes a "personal menu" item (matched by exact display-name string `"Gold]personal menu"` via `ChatColor.GOLD + "personal menu"`) into a `menu` map for later re-give on respawn.
- **Feature allocation:** `siege-minigame` (PvP economy penalty) — the PvE branch is more general death economy, still combat-adjacent.
- **Bug/edge case (as written, moot since dead):** the arena-exemption check (`Worldguard.getStructureIDbyRegion("arena", ...)`) only guards the coin-drop item creation, not the `userDied.removeCoins(dropamount)` call's precondition — actually on inspection the whole block including `removeCoins` is inside the same `if`, so that's fine. More notable: `RegionManager manager` referenced at `KillDeathStat.java` scope was never declared in this method (only in `CombatCheck.java`'s analogous dead method) — this method never actually declares/initializes a `manager` variable it implicitly needs for the arena check (`Worldguard.getRegionManager(died.getWorld())` is called inline instead, so no bug in practice, just noting the copy-paste divergence from `CombatCheck`).

### LIVE: `ExpMobKill(EntityDeathEvent)` — `v1:src/KillsDeaths/KillDeathStat.java:236-286`
- **Bukkit event type:** `EntityDeathEvent`, default priority.
- **Trigger condition:** unconditionally zeroes dropped exp for **every** entity death (`e.setDroppedExp(0)` at `KillDeathStat.java:239`, outside any `if`). The reward logic itself is gated on `e.getEntityType() == EntityType.OCELOT && e.getEntity().getKiller() instanceof Player`.
- **Goal/function:** this is not a PvP handler at all — it's a special "kill an ocelot" reward (ocelots are presumably a rare/boss mob spawn in this server, not vanilla cats). On qualifying kill:
  - Grants `user.getExpPart(12)` experience (a user-scaled XP fraction, formula opaque outside this slice — `getExpPart` not read).
  - Grants `main.getRandom(1000, 12000)` coins.
  - Fires a custom `ExperienceChangeEvent`.
  - Drops a random product via `product.getRandomProduct(null, null)` at the death location.
  - Chained (not mutually exclusive — see bug below) bonus rolls: `main.getRandom(0,100) <= 1` → +1 skill point; else `<= 5` → gems = `user.getMultipliedInt(main.getRandom(20,200))`; else `<= 15` → gems = `user.getMultipliedInt(main.getRandom(2,50))`.
- **Feature allocation:** own `skills`/economy sub-area (mob-kill reward, not PvP) per the `/specialskill` precedent in `commands-v1.md` — not `siege-minigame`, since it's explicitly `EntityType.OCELOT`, an unrelated mob kill.
- **Bugs/edge cases:**
  - The three bonus branches are `if / else if / else if` on **independent** `main.getRandom(0,100)` calls each time (three separate random draws, not one draw compared to three thresholds), so despite being written as an if/else-if chain the values are never actually mutually exclusive draws off one number — this is fine/intended-looking but means the effective probability of the skill-point branch is 1/100 of *this specific call's first roll*, not 1% of all kills combined with the others; correctness depends on reading each `main.getRandom` call as fresh, which it is (`main.getRandom` presumably `new Random()` each call — not verified in this slice, out of scope).
  - No null-check on `p` before `Users.getUser(uuid)` beyond the catch blocks — standard pattern in this codebase, no bug.
  - `EntityType.OCELOT` naming is surprising for a currency/XP/skill-point/gem "boss kill" reward this generous (200–12000 coins, up to 200 gems) — flagged as a naming anomaly worth checking against `commands-v1.md`/design docs; unclear whether "OCELOT" is used here as a stand-in mob for some other creature (e.g. custom-named/disguised mob) since the reward magnitude is far out of line with a normal passive mob. Marked unclear/out of scope — no definitive evidence in this file either way.

### DEAD: `respawn(PlayerRespawnEvent)` — `v1:src/KillsDeaths/KillDeathStat.java:288-307`
- **Trigger:** UUID present in `menu` map and/or `respawn` map (both populated only by the also-dead `Kill` handler above).
- **Goal:** re-gives the stashed "personal menu" item and/or the stashed high-grade items from the death-drop filter.
- Dead in lockstep with `Kill` — consistent, no orphaned-half-feature bug here (unlike `CombatCheck`'s `incombat`/`onEnter` split).

---

## `KillsDeaths/RespawnLocation.java` — fully dead (0/1 handlers live)

### DEAD: `Respawn(PlayerRespawnEvent)` — `v1:src/KillsDeaths/RespawnLocation.java:29-99` (only handler in file, entirely commented out)
- **Trigger (as written):** branches on Hide-and-Seek participation (`Main.HideAndSeek.getProgress()` + `getParticipating(user)`) vs. the user's configured `spawnpointID`.
- **Goal:** overrides `e.setRespawnLocation(...)` to either the Hide-and-Seek town's spawn point (falling back to the user's last death location on exception), or the user's chosen spawn point / the global "spawn" point, with an op-permission branch (`k&k.join.nolocation`) that — bug, dormant since dead — is written as `!player.hasPermission(...) || !player.isOp()`, which is almost certainly meant to be `&&` (as written, the "else" branch, i.e. "let the player pick their own spawn," is only skipped if the player simultaneously lacks the permission node **and** is not OP — an OR of two negatives is true unless both underlying conditions are true, so this condition is true for nearly all players including ops without the node, making the intended-restrictive branch fire almost always). Flagged as a real logic bug in the source, moot only because the whole method is disabled.
- **Feature allocation:** `siege-minigame`-adjacent (Hide-and-Seek is a minigame) but general respawn routing, not combat per se.
- Not superseded by anything found in this slice or `EntityListener.java`; respawn-location logic's current live equivalent (if any) is out of scope/unclear — not located during this pass.

---

## `Listeners/DoubleDamageListener.java`

### LIVE: `DoubleDamage(Handlers.DoubleDamage)` — `v1:src/Listeners/DoubleDamageListener.java:19-32`
- **Bukkit event type:** custom plugin event `Handlers.DoubleDamage` (extends `KaKEvent`), default priority. Constructor signature: `DoubleDamage(User user, Player target, Double damage, Boolean multiplier)` (`v1:src/Handlers/DoubleDamage.java:15`).
- **Trigger condition:** fires whenever this event is dispatched; the handler itself has no gating condition beyond reading `e.getMultiplier()`.
- **Fired from (live):** `Listeners/EntityListener.java:166` — `Bukkit.getServer().getPluginManager().callEvent(new DoubleDamage(userDamager, damaged, e.getDamage(), multiplier == 2))`, inside `EntityListener#onHit`'s AttackSpeed-skill block. That block: `if (userDamager.getAttackSpeedID() > 0)` then rolls `Main.getRandom(0,100) <= amount` (where `amount = skill.getSkillValue("AttackSpeed", userDamager.getAttackSpeedID())`); on success, `multiplier = 2` (message "Triple hit!") if `getAttackSpeedID() == 7` else `multiplier = 1.5` (message "Double hit!"), then `e.setDamage(e.getDamage()*multiplier)` before firing the custom event (`v1:src/Listeners/EntityListener.java:148-171`).
- **Goal/function:** purely cosmetic follow-up messaging to the **target**, not the attacker — the attacker already got their "Double/Triple hit!" message directly in `EntityListener`. This listener just tells the victim: `e.getMultiplier() == false` → "You have been Double hit!"; `true` → "You have been Triple hit!" (`v1:src/Listeners/DoubleDamageListener.java:24-31`).
- **Feature allocation:** `siege-minigame` (PvP damage-multiplier proc feedback) — functionally part of the AttackSpeed special skill.
- **Bugs/edge cases:**
  - `target` is read from the event but not null-checked before `.sendMessage` — if `Handlers.DoubleDamage`'s `target` field is ever null this NPEs; not observed as reachable given how it's constructed in `EntityListener`.
  - This listener's own dead twin exists verbatim inside `Skills/AttackSpeedEvent.java:124-138` (commented out) — i.e. the *exact same* `DoubleDamage(DoubleDamage e)` handler was duplicated into two files; only the `Listeners` package copy is live.
  - The `damage` local variable (`Double damage = e.getDamage();`) is read from the event but never used in the method body (`v1:src/Listeners/DoubleDamageListener.java:23`) — dead local, harmless.

---

## `Skills/AssassinSkill.java`

### LIVE: `assassin(PlayerToggleSneakEvent)` — `v1:src/Skills/AssassinSkill.java:38-129`
- **Bukkit event type:** `PlayerToggleSneakEvent`, default priority. Note: this fires on **both** sneak-on and sneak-off toggles (Bukkit doesn't distinguish in the event name; the method checks `!player.isSneaking()` to only act on the "started un-sneaking" — actually see below, it checks the *current* state at call time).
- **Trigger condition (exact):**
  1. `user.getSpecialSkillID() != -1 && user.getSpecialSkillID() != 0` else return (checked twice — once into a local `specialskillID` that is then never used for the name comparison, and again as `user.getSpecialSkillID() != 0` at `AssassinSkill.java:69` — the `specialskillID` local is dead/redundant).
  2. `skill.equalsIgnoreCase("assassin")` — skill-name string compare via `user.getSpecialSkillName()`.
  3. `!player.getGameMode().equals(GameMode.CREATIVE) || !player.isFlying()` — i.e. blocked only if **both** creative-mode **and** flying simultaneously (an OR of two "not" conditions — same OR/AND-inversion pattern flagged in `RespawnLocation` above; as written this only blocks a creative *and* flying player, not a creative player standing still, which is presumably not the intent but is technically a narrower guard, not a wide-open one like the RespawnLocation bug).
  4. `!player.isSneaking()` — since this fires on toggle, this branch is entered when the event represents the player **releasing** sneak (going from sneaking to not-sneaking) — i.e., the ability triggers on sneak-release, not sneak-press.
  5. `Bukkit.getServer().getOnlinePlayers().size() != 0` — trivially true whenever the triggering player themself is online; this can never be 0 since the player invoking it is by definition online. Dead/no-op guard.
  6. Not on cooldown (`!Cooldowntime.containsKey(uuid)`) and not already mid-activation (`!invtime.containsKey(uuid)`).
- **Goal/function:** "Assassin" stealth skill. On success: puts player in `invtime` (4-"tick" — actually second, see below — placeholder), sends an activation message, plays `SoundHandler.BLAZE_BREATH`; then for **every** online player within `10` blocks (`radius = 10D`) of the caster's location, calls `players.hidePlayer(player)` (hides the caster from them) — note this loop hides the caster from **all** online players regardless of distance in the first sub-loop (`for (Player players : Bukkit.getOnlinePlayers()) { players.hidePlayer(player); }`, `AssassinSkill.java:86-89`, no distance check), then a **second, separate** loop applies `PotionEffectType.BLINDNESS` (1 second, amplifier 2) only to players within the 10-block radius (`AssassinSkill.java:90-97`). After a scheduled delayed task of `4*20` ticks (4 seconds), the caster is re-shown to everyone, told the skill needs to recharge, a `BLAZE_DEATH` sound plays, and `Cooldowntime.put(uuid, 30)` starts a 30-second cooldown (decremented once/second by a `runTaskTimer(this, 10*20, 20)` loop in `Main.java` — `v1:src/Main/Main.java:1042-1049`, confirmed 1-second period at `Main.java:1190`).
- **Feature allocation:** own `skills` sub-area (per the `/specialskill` precedent), combat-adjacent stealth ability.
- **Bugs/edge cases:**
  - **Invisibility applies to *all* online players, blindness only to nearby ones** — the hide-from-everyone / blind-only-nearby split (`AssassinSkill.java:86-97`) means a player on the opposite side of the map is also unable to see the assassin for 4 seconds, which is a much larger effect than the "10-block radius" ability description implies; likely a bug (the hide loop should probably also be radius-gated) rather than intended global invisibility.
  - `invtime` map is populated (`invtime.put(uuid, 4)`) but its value is never read anywhere in this file or (per grep) elsewhere — `invtime` only gates via `containsKey`, the stored `Integer.valueOf(4)` is meaningless/write-only. No decrement loop for `invtime` was found (unlike `Cooldowntime`), so `invtime` entries are only ever removed by the scheduled 4-second Runnable itself (`AssassinSkill.java:109`), not by any tick-based countdown — consistent, not actually a leak, just a needless HashMap-as-boolean-flag pattern.
  - Self-triggering / spam: since the trigger is "stopped sneaking," a player can spam sneak/un-sneak; this is correctly guarded by `invtime`/`Cooldowntime` so no obvious spam exploit found.
  - No check that the caster isn't already invisible/hidden from combat state, and no interaction with `CombatCheck`'s (dead) combat-lock system — moot since that system is dead.
  - Dead field `Users users` import unused (uses static `Users.getUser` instead) — cosmetic only.

---

## `Skills/AttackSpeedEvent.java` — fully dead (0/2 handlers live)

### DEAD: `AttackSpeedHit(EntityDamageByEntityEvent)` — `v1:src/Skills/AttackSpeedEvent.java:33-86`
- **Trigger (as written):** both parties players, gated by `main.enableSkills` flag, and neither in a "safe zone" (`!userDamager.inSafeZone() && !userTarget.inSafeZone()`). Delegates to `dealDamage(...)`.
- Also contains a stray debug line: `if (e.getEntity() instanceof ArmorStand) Bukkit.broadcastMessage(...)` (`AttackSpeedEvent.java:40-42`) — leftover debug broadcast, dead.

### DEAD: `dealDamage(User, Player, EntityDamageByEntityEvent)` — `v1:src/Skills/AttackSpeedEvent.java:88-122` (helper, not an `@EventHandler` itself, but referenced here since it's this handler's payload)
- **Trigger:** `userDamager.getAttackSpeedID() != 0`; excludes friends (`!userDamager.getFriendList().contains(...)`); rolls `chance.nextInt(100) <= amount` where `amount = skill.getSkillValue("AttackSpeed", userDamager.getAttackSpeedID())`.
- **Goal:** `getAttackSpeedID() < 7` → 1.5x damage ("Double Hit!"); `>= 7` (only `== 7` reachable given `getSkillValue` domain, unverified) → 2x damage ("Triple Hit!"); fires `Handlers.DoubleDamage` event either way; plays `SoundHandler.ANVIL_LAND`.
- **Note:** this dead logic is what the live `EntityListener#onHit` reimplements almost identically at `v1:src/Listeners/EntityListener.java:148-171` (same 1.5x/2x split at level 7, same `DoubleDamage` event fire, same sound) — confirms this class's logic was migrated, not abandoned outright.

### DEAD: `DoubleDamage(DoubleDamage)` — `v1:src/Skills/AttackSpeedEvent.java:124-138`
- Verbatim duplicate of the live `DoubleDamageListener` handler (see above) — dead second copy.
- **Feature allocation (whole file):** `siege-minigame` / combat skill, migrated live to `EntityListener.java`.

---

## `Skills/AvengerSkill.java` — fully dead (0/3 handlers live)

Class holds `public static HashMap<UUID, UUID> avenger` (dead-on-death-victim → killer map).

### DEAD: `Avenger(PlayerDeathEvent)` — `v1:src/Skills/AvengerSkill.java:34-101`
- **Trigger:** PvP death (`e.getEntity() instanceof Player && e.getEntity().getKiller() instanceof Player`); victim's `getSpecialSkillID()` valid and non-zero; victim's `getSpecialSkillName().equalsIgnoreCase("avenger")`.
- **Goal:** records `avenger.put(deadUUID, killerUUID)`, messages the victim "Avenger skill activated!". A second, oddly-placed check immediately after — `if (avenger.containsValue(died))` (`AvengerSkill.java:86`) — is almost certainly a **bug**: it checks `containsValue(died)` where `died` is a `Player` object, but the map's value type is `UUID`, so this condition can never be true (`containsValue` against a `Player` on a `Map<UUID,UUID>` — type mismatch would actually fail to compile as written unless there's implicit autoboxing/equals weirdness; more likely this is simply unreachable/always-false dead logic even if it did compile, since no `UUID.equals(Player)` will ever match). Confirmed as dead-even-if-live code; the "You have been avenged!" / "You have avenged yourself!" messages inside this branch can never fire.
- **Feature allocation:** own `skills` sub-area / `siege-minigame` (PvP revenge mechanic).

### DEAD: `AttackDamage(PlayerRespawnEvent)` — `v1:src/Skills/AvengerSkill.java:103-143`
- **Trigger:** respawning user has `"avenger"` special skill and is a key in the `avenger` map.
- **Goal:** purely informational — messages the player "+50% attack damage against `<target>`" if their recorded killer is online, else "Your killer is not online anymore!". Note: this handler **only sends a message**; it does not itself apply any damage buff — the buff is applied by the third handler below.

### DEAD: `Kill(EntityDamageEvent)` — `v1:src/Skills/AvengerSkill.java:145-183`
- **Trigger:** damaged entity is a `Player` whose UUID is a **value** in the `avenger` map (i.e., this player is someone's recorded killer).
- **Goal/function — bug (classic attacker/defender confusion):** iterates all `avenger` entries where `entry.getValue().equals(uuid)` (the currently-damaged player is the recorded killer), and for the matching avenging player (`entry.getKey()`), if that avenger happens to also be online, applies **`avenged.damage(plusdamage)`** where `avenged` is the *original event's damaged entity* (the killer being avenged-upon) and `plusdamage = normaldamage * 1.5`. Read closely: this listens on `EntityDamageEvent` (any damage source, not `EntityDamageByEntityEvent`), so it doesn't actually check that the avenger is the one dealing the damage — it just checks "is the currently-damaged player someone's killer, and is the avenger online" and then applies **extra flat self-damage-equivalent** to the killer via `.damage(plusdamage)`, regardless of who or what caused the original damage event. This is a materially different (and much more powerful/exploitable, if live) mechanic than the "+50% attack damage" message in the previous handler promises: any damage at all to the killer (fall damage, lava, a mob, anything) gets amplified by 1.5x as long as their avenger is online — not "the avenger's next hit does +50%." **Flagged as a real bug**: message/behavior mismatch, and event-type choice (`EntityDamageEvent` vs `EntityDamageByEntityEvent`) means the avenger doesn't even need to be near or attacking. Entirely moot since dead, but a good example of the "checks the wrong condition" bug class the task asked to look for.
- **Feature allocation:** own `skills` sub-area (PvP revenge/damage-amp mechanic).
- No live equivalent of Avenger was found anywhere in `EntityListener.java` or elsewhere in the codebase search performed for this task — Avenger skill appears to be entirely non-functional in the current build (unlike AttackSpeed/Defense/Health/Ninja/Speed/Strength/Juggernaut which all migrated live into `EntityListener`).

---

## `Skills/DefenseEvent.java` — fully dead (0/1 handlers live), explicitly noted as relocated

File contains an explicit source comment: `//IS located in the HitFriendEvent` (`v1:src/Skills/DefenseEvent.java:33`) — the author's own note that this logic moved elsewhere. (In practice, per this task's cross-reference read, the live Defense logic is in `EntityListener.java`, not a file literally named `HitFriendEvent` found in this slice — that name wasn't located; treating the author's comment as informative-but-possibly-stale.)

### DEAD: `onHit(EntityDamageByEntityEvent)` — `v1:src/Skills/DefenseEvent.java:35-91`, priority `HIGHEST`
- **Trigger:** damaged is `Player`, not in safe zone.
- **Goal:** `reduction = skill.getSkillValue("Defense", user.getDefenseID())`; `damage = finalDamage - (finalDamage/100)*reduction` (percentage damage reduction); at `level == 7`, additionally a `50%` chance (`rand.nextInt(100) <= 50`) to fully cancel the hit ("Incoming damage has been reduced by 100%!") instead of just applying the percentage reduction.
- **Live counterpart found:** `EntityListener.java:176-201` implements the **same** level-7-cancel-at-a-chance / percentage-reduction pattern, but with the roll changed from `<= 50` to `<= 25` (`v1:src/Listeners/EntityListener.java:186`) — i.e., the live version **halved** the level-7 full-cancel chance from 50% to 25% relative to this dead file's value. Recorded as a real, confirmed behavioral difference between the dead reference code and the live implementation (not a bug — looks like a deliberate rebalance — but worth flagging since a naive reader of only this file would get the wrong chance value).
- **Feature allocation:** own `skills` sub-area (mitigation skill).

---

## `Skills/ForgerSkill.java`

### LIVE: `onPurchase(PurchaseEvent)` — `v1:src/Skills/ForgerSkill.java:30-64`
- **Bukkit event type:** custom plugin event `Handlers.PurchaseEvent`, default priority. Fired from `Menu/CouponClick.java:64,74` and `Properties/ItemFrameAdd.java:332` — i.e. this is an **economy/shop** trigger, not a combat trigger, despite living in the `Skills` package.
- **Trigger condition:** `Users2.users.contains(user)` sanity check (else treated as user-not-found); `user.getSpecialSkillName().equalsIgnoreCase("forger")`; `Bukkit.getPlayer(uuid) != null` (player currently online); then a `random.nextInt(100) <= 20` roll (20% chance, using raw `java.util.Random`, not the `main.getRandom` helper used elsewhere).
- **Goal/function:** duplicates the purchased item (`e.getItem()`) into the player's inventory (or drops it at their feet with an "Inventory full" message if no space), plays `SoundHandler.ANVIL_USE`, and messages "[Forger]-Purchase succesfully duplicated!" (note the "succesfully" typo preserved verbatim from source).
- **Feature allocation:** this is **not** combat/PvP — it's a shop-purchase-duplication passive, i.e. an economy skill despite the file's location in `src/Skills/`. Per the task's own precedent ("`skills` sub-area, economy-adjacent"), this is the clearest example in the whole slice of that precedent applying — Forger has zero interaction with any Bukkit combat event.
- **Bugs/edge cases:** no cooldown of any kind on this handler (unlike Assassin/Pickpocket) — every qualifying purchase independently rolls 20%, uncapped; no apparent exploit since it only duplicates what was already legitimately purchased (can't be looped by the player alone), but notably generous with no rate limit compared to every other skill in this slice.

---

## `Skills/HealthEvent.java`

### DEAD: `Healthjoin(PlayerJoinEvent)` — `v1:src/Skills/HealthEvent.java:33-37` — empty body, only a comment ("Setting health of a player is managed by the JoinEvents in the users package") — dead stub, out of scope (JoinEvents not read, per instructions not to invent).

### DEAD: `HealthRespawn(PlayerRespawnEvent)` — `v1:src/Skills/HealthEvent.java:39-72`
- **Trigger:** `main.existUser(uuid)`.
- **Goal:** `health = skill.getSkillValue("Health", user.getHealthID())`; if `level < 7`, `player.setHealthScale(20 + health)`; else (level 7) hardcoded `setHealthScale(32)`.

### LIVE: `Health(NewSkillHandler)` — `v1:src/Skills/HealthEvent.java:74-93`
- **Bukkit event type:** custom plugin event `Handlers.NewSkillHandler` (extends `KaKEvent`), default priority. Constructor: `NewSkillHandler(User user, String skill, Integer level)` (`v1:src/Handlers/NewSkillHandler.java:12`).
- **Trigger condition:** `skill.equalsIgnoreCase("health")`.
- **Goal/function:** identical health-scale formula to the dead `HealthRespawn` above (`< 7` → `20+health`, `else` → `32`) — this is the "apply the new max-health scale immediately when the skill is purchased/leveled up" handler, re-triggered on respawn conceptually but actually gated on the custom `NewSkillHandler` event, not `PlayerRespawnEvent`.
- **Important finding — likely unreachable in the current build:** a codebase-wide `Grep` for `new NewSkillHandler(` and `NewSkillHandler(` found **zero call sites** anywhere in `src/` other than the class's own constructor definition (`v1:src/Handlers/NewSkillHandler.java:12`). No file was found that actually does `Bukkit.getServer().getPluginManager().callEvent(new NewSkillHandler(...))`. This means **this live-looking `@EventHandler` is registered but its triggering event is never fired anywhere in the codebase** — functionally dead despite not being commented out. The same applies to `SpeedEvent#SpeedWalk3(NewSkillHandler)` below, which shares this event type. Flagged clearly as "written live, never invoked" — a distinct bug class from the commented-out ones above, and worth distinguishing in any downstream doc.
- **Feature allocation:** own `skills` sub-area (passive stat skill), not combat.

### DEAD: `LastHealthUpgrade(EntityDamageByEntityEvent)` — `v1:src/Skills/HealthEvent.java:94-136`
- **Trigger:** damaged is `Player`, `main.existUser(uuid)`, `level == 7`.
- **Goal:** `rand.nextInt(100) <= 50` → applies `Regeneration I` for 10 seconds, messages "You have Regeneration I for 10 seconds!"
- **Live counterpart:** `EntityListener.java:206-217` implements this near-verbatim (same `level == 7`, `Regeneration I`, 10s), but the roll there uses `skill.getSkillValue("health", healthLevel)` as the threshold rather than this dead file's hardcoded `50` (`v1:src/Listeners/EntityListener.java:211` vs `v1:src/Skills/HealthEvent.java:125`) — another confirmed rebalance-on-migration, worth flagging same as the Defense 50%→25% case above. Also notably the live version reacts to the **damage-taken** event (the `onHit` in `EntityListener` is keyed off `EntityDamageByEntityEvent` on the *damaged* player) whereas the trigger is the same shape, so functionally equivalent placement, just different threshold source.

---

## `Skills/JuggernautSkill.java` — fully dead (0/1 handlers live)

### DEAD: `Juggernaut(EntityDamageByEntityEvent)` — `v1:src/Skills/JuggernautSkill.java:27-70`
- **Trigger:** damaged is `Player`, damager is `Arrow` (i.e., an arrow-projectile hit specifically — not melee), not in safe zone, `specialSkillID` valid/non-zero, `getSpecialSkillName().equalsIgnoreCase("juggernaut")`.
- **Goal:** plays `SoundHandler.ANVIL_USE` and `e.setCancelled(true)` — i.e., **full arrow-damage immunity**, unconditional (no chance roll at all — this is the one skill in the slice that is a flat, unconditional block rather than a probabilistic proc).
- **Live counterpart:** `EntityListener.java:81-99` reimplements this in the arrow-shooter-resolution branch, same unconditional cancel, same sound, with an added `Main.logMessage("Juggernaut skill cancelling damage")` debug line and (notably) the null-safety improvement `userDamaged.getSpecialSkillName() != null && ...equalsIgnoreCase(...)` (`v1:src/Listeners/EntityListener.java:92`) — the dead version here has no null-guard on `getSpecialSkillName()`, so if a player has no special skill assigned and that getter returns `null` rather than an empty string, this dead code would NPE at the `.equalsIgnoreCase` call. Confirmed real bug in the dead file, fixed in the live migration.
- **Feature allocation:** own `skills` sub-area (ranged-damage-immunity tank ability).

---

## `Skills/NinjaSkill.java` — fully dead (0/1 handlers live)

Declares `public static Map<UUID, Integer> ninjatime` (`v1:src/Skills/NinjaSkill.java:35`) — confirmed via grep to be **written and read only within this same dead method**; i.e., even the static field is orphaned (no other file references `NinjaSkill.ninjatime`).

### DEAD: `Ninja(EntityDamageByEntityEvent)` — `v1:src/Skills/NinjaSkill.java:38-117`
- **Trigger:** both parties players; **defender's** skill checked (`userDamaged`, not the damager) — i.e. this is a defensive/evasive proc, correctly attributed to the person being hit, not a bug; not in safe zone; `specialSkillID` valid/non-zero; `getSpecialSkillName().equalsIgnoreCase("ninja")`; not already active (`!ninjatime.containsKey(uuid)`); `rand.nextInt(100) <= 30` (30% proc chance).
- **Goal:** on proc, hides the damaged player from every online player within 30 blocks (`radius = 30D`) and blinds those nearby (`BLINDNESS`, 1s, amplifier 2) — same "hide vs. blind radius" pattern as Assassin, but here **both** the hide and blind loops are inside the same `for (Player online : ...) if (plocs.distance(ploc) <= radius)` block (`NinjaSkill.java:88-96`), correctly radius-gated (unlike Assassin's global-hide bug above) — messages damager "You have been ninja'd!", plays `CREEPER_HISS`; after 5 seconds, un-hides globally and messages "Ninja skill is deactivated!", plays `BLAZE_DEATH`, clears `ninjatime`.
- **Live counterpart:** `EntityListener.java:219-251` reimplements this, keyed off `Main.ninjaSkill` (a `HashMap<User, Long>` on `Main`, storing an absolute expiry timestamp rather than this dead file's tick-count placeholder pattern) instead of the local `ninjatime` map, and — notably — **the live version's hide/un-hide deactivation step appears to rely on the same central tick-timer loop that decrements `AssassinSkill.Cooldowntime`/expires `Main.ninjaSkill`** (`v1:src/Main/Main.java:1082-1089`, confirmed to iterate `ninjaSkill` and compare `current > ninjaSkill.get(user)`) rather than a per-activation `scheduleSyncDelayedTask` the way this dead file and `AssassinSkill` both do. Same `null`-guard fix pattern as Juggernaut applies here too (`specialSkillName != null && ...` at `EntityListener.java:227` vs. the dead file's un-guarded `userDamaged.getSpecialSkillName().equalsIgnoreCase(...)` at `NinjaSkill.java:80`, a latent NPE in the dead version for skill-less players).
- **Feature allocation:** own `skills` sub-area (evasive stealth-on-hit ability).

---

## `Skills/PickpocketSkill.java`

### LIVE: `Pickpocket(PlayerInteractEntityEvent)` — `v1:src/Skills/PickpocketSkill.java:36-127`
- **Bukkit event type:** `PlayerInteractEntityEvent`, default priority. Not combat-damage-based — triggers on **right-clicking another player**.
- **Trigger condition:** `e.getPlayer() instanceof Player && e.getRightClicked() instanceof Player`; `e.setCancelled(true)` is called **unconditionally** for any player-right-clicks-player interaction (`PickpocketSkill.java:80`), **before** the skill/cooldown checks — meaning this handler suppresses the vanilla right-click-on-player interaction (e.g., trading, mounting, whatever else might normally trigger) for **every** player, not just Pickpocket-skill users. Flagged as an edge case: any other plugin/vanilla feature relying on `PlayerInteractEntityEvent` between two players is silently cancelled globally by this handler regardless of whether the source player even has the Pickpocket skill.
- Then: `specialSkillID` valid/non-zero, `skill.equalsIgnoreCase("pickpocket")`, not on cooldown (`!Cooldown.containsKey(uuid)`), then `rand.nextInt(100) <= 20` (20% success chance, note: separate `Random` instantiated per-call, `PickpocketSkill.java:75`, alongside an unused `main.getRandom(1,20)` roll stored in `chance` — see bug below).
- **Goal/function:** `chance = main.getRandom(1, 20)` is computed **before** the skill-check gate and used to size the theft regardless of whether the pickpocket attempt actually succeeds: `amount = (victim.getCoins()/100) * chance` and `gemamount = (victim.getGems()/100) * chance` (i.e., steals between 1% and 20% of the victim's coins/gems, scaled by this second independent random roll, decoupled from the 20% "chance you succeed at all" roll above). On success: `userVictim.sendCoins(uuid, amount)` (transfers coins from victim to attacker), plays `GHAST_DEATH`, messages the amount stolen; then a **nested bonus roll** `rand.nextInt(100) <= 8` (8% chance) additionally grants the attacker `gemamount` gems on top. On failure (80% base roll fails): "you tried to pickpocket ... but failed!" message, cooldown is still applied. Cooldown either way: `System.currentTimeMillis() + 900000L` = exactly 15 minutes.
- **Bugs/edge cases:**
  - `chance`/`amount`/`gemamount` are computed unconditionally at the top of the method (`PickpocketSkill.java:76-78`) even for players who don't have the Pickpocket skill at all or are on cooldown — wasted computation only, not a correctness bug (values are simply unused if the gates fail), but worth noting as sloppy structure.
  - **Global interaction cancellation bug** noted above — `e.setCancelled(true)` fires for every player-right-click-player regardless of skill possession.
  - Cooldown display math (`PickpocketSkill.java:113-121`) computes `rest = 3600 - timer` but `rest` is **never used** in the message — the actual cooldown is 900 seconds (15 min) not 3600 (1 hour), so this `rest`/`3600` pair looks like a leftover from an earlier 1-hour-cooldown version that wasn't fully updated when the cooldown was changed to 15 minutes; dead/unused variable, cosmetic only since it isn't displayed, but the presence of a stale `3600` constant here is a real inconsistency worth flagging.
  - No `friendList` exemption (unlike Strength/AttackSpeed elsewhere in this slice) — a player can apparently pickpocket their own declared friends; unclear if intentional, flagged as a possible design gap rather than a confirmed bug.
- **Feature allocation:** own `skills` sub-area — PvP-adjacent (steals from other players) but not a damage/combat event; still economy-adjacent per the task's Forger precedent, could reasonably also be tagged `siege-minigame` given it's player-vs-player; recording both.

---

## `Skills/ShotbowSkill.java`

### LIVE: `Shotbow(EntityShootBowEvent)` — `v1:src/Skills/ShotbowSkill.java:29-91`
- **Bukkit event type:** `EntityShootBowEvent`, default priority.
- **Trigger condition:** shooter is `Player`; `specialSkillID` valid/non-zero; `getSpecialSkillName().equalsIgnoreCase("shotbow")`; `rand.nextInt(100) <= 40` (40% proc chance).
- **Goal/function:** captures the just-fired arrow's velocity vector, then — 5 ticks later via `scheduleSyncDelayedTask(main, ..., 5)` — launches a **second** arrow from the same player with the same velocity (`player.launchProjectile(Arrow.class)`, `arrow.setVelocity(velocity)`, `arrow.setShooter(player)`) and plays a `BOW_FIRE` particle effect. Effectively a "double-shot" bow skill, free (no ammo consumed for the bonus arrow — it's synthesized, not drawn from inventory).
- **Bugs/edge cases:**
  - The delayed second-arrow launch closure captures `player`, `velocity`, and `worldname` from the enclosing scope but not the **original arrow's other properties** (enchantments, whether it's a fire-arrow via Flame, critical-hit state) — the clone only preserves velocity, not e.g. custom damage/enchant metadata that a purchased/upgraded bow might carry; unclear/out of scope whether the base game's arrow already carries these via NBT independent of this code — flagged as a plausible balance gap, not a confirmed bug.
  - No cooldown of any kind (unlike Assassin/Pickpocket/Ninja) — this is a per-shot 40% independent proc with no rate limit; combined with rapid-fire bows this could stack heavily, flagged as a potential balance/exploit concern (spam-clicking a bow could very plausibly double the arrow-per-second output on ~40% of shots).
  - `chance`/`worldname` locals fine; no null-checks needed since `player` is directly from the event.
- **Feature allocation:** own `skills` sub-area — ranged-combat skill, could be tagged `siege-minigame` if bow combat is siege-relevant (plausible given a siege-minigame context) but not confirmed combat-only here (works against mobs too, since `EntityShootBowEvent` doesn't require a PvP target).

---

## `Skills/SpeedEvent.java`

### DEAD: `SpeedWalk(PlayerJoinEvent)` — `v1:src/Skills/SpeedEvent.java:31-35` — empty stub, comment only ("Managed by the JoinEvents class in the users package"), same pattern as `HealthEvent#Healthjoin`.

### DEAD: `SpeedWalk2(PlayerRespawnEvent)` — `v1:src/Skills/SpeedEvent.java:37-83`
- **Trigger:** `main.existUser(uuid)`.
- **Goal:** sets `player.setWalkSpeed(...)` by a hardcoded per-level table: level 1→0.22, 2→0.24, 3→0.26, 4→0.28, 5→0.30, 6→0.32, 7→0.32 (note: levels 6 and 7 give the **identical** value, `0.32F` — either a deliberate cap or a copy-paste-and-forgot-to-change-the-value bug; flagged, can't determine intent from source alone).

### LIVE: `SpeedWalk3(NewSkillHandler)` — `v1:src/Skills/SpeedEvent.java:85-117`
- **Bukkit event type:** same custom `Handlers.NewSkillHandler` event as `HealthEvent#Health` above — **and subject to the identical finding: no call site for `new NewSkillHandler(...)` exists anywhere in the codebase**, so this handler, while syntactically live (not commented out), is never actually invoked by any code path found in this repository. Cross-referenced against the same grep result as the Health case.
- **Trigger condition:** `skill.equalsIgnoreCase("speed")`.
- **Goal/function:** identical hardcoded walk-speed table to the dead `SpeedWalk2` above, same level-6/level-7 duplicate-value quirk (`SpeedEvent.java:109-114`).
- **Feature allocation:** own `skills` sub-area (movement passive), not combat.

### DEAD: `SpeedHit(EntityDamageByEntityEvent)` — `v1:src/Skills/SpeedEvent.java:118-160`
- **Trigger:** damaged is `Player`, `main.existUser(uuid)`, `level == 7`, `rand.nextInt(100) <= 50` (50% chance).
- **Goal:** grants `PotionEffectType.SPEED` (5s, amplifier 1) with message "You got Speed II for 5 seconds!" — i.e., on-hit (being attacked) proc, not on-attack.
- **Live counterpart:** `EntityListener.java:253-267` reimplements this near-identically but the roll threshold is `skill.getSkillValue("speed", speedLevel)` rather than this dead file's hardcoded `50` (`v1:src/Listeners/EntityListener.java:261` vs `v1:src/Skills/SpeedEvent.java:149`) — same "hardcoded-in-dead-code, data-driven-in-live-code" migration pattern already seen for Defense and Health.

---

## `Skills/StrengthEvent.java` — fully dead (0/1 handlers live)

### DEAD: `StrengthHit(EntityDamageByEntityEvent)` — `v1:src/Skills/StrengthEvent.java:28-89`
- **Trigger:** `main.enableSkills` flag; both parties players (attacker read as `player` = `e.getDamager()`); attacker not in safe zone; target not in attacker's friend list; `getStrengthID() != 0`.
- **Goal:** `amount = skill.getSkillValue("Strength", user.getStrengthID())`; roll `chance.nextInt() <= amount` — **note the missing bound**: this is `Random.nextInt()` with **no argument**, which returns a full-range `int` (including negative values, roughly ±2.1 billion), compared against `amount` which is presumably a small percentage-like value (0–100-ish, based on every other skill in this file using `nextInt(100)`). Since `nextInt()` returns negative numbers roughly half the time, and any negative result is `<= amount` for any non-negative `amount`, this roll **succeeds roughly 50%+ of the time regardless of the configured `amount`/level**, effectively decoupling the proc chance from the skill's configured value. **Confirmed bug** — likely a typo for `chance.nextInt(100)` that was never caught, presumably because this code was already dead by the time anyone would have noticed the balance was wrong. Same bug appears **twice** in this method (`StrengthEvent.java:69` and `:78`, one for `getStrengthID() != 7` and one for `== 7`).
- **Goal (effect):** applies `PotionEffectType.INCREASE_DAMAGE` (Strength) — level `!= 7`: amplifier 1, 5 seconds; level `== 7`: amplifier 2, 4 seconds. Applied to the **attacker** (`player`, correctly — this is an on-attack self-buff, not a defender-side effect, so no attacker/defender confusion here).
- **Live counterpart:** `EntityListener.java:269-289` reimplements this with the bug **fixed** — uses `Main.getRandom(0, 100) <= chance` (`v1:src/Listeners/EntityListener.java:276`), a properly bounded roll — confirming this was indeed a known/fixed issue in the dead reference file, further evidence the dead code in this slice is genuinely stale rather than a parallel/alternate implementation.
  - However, the live version drops the `friendList` exclusion present in the dead file (no `getFriendList().contains(...)` check found in the corresponding `EntityListener.java:272-289` Strength block) — flagged as a behavioral regression/simplification versus the dead reference: in the live build, attacking a declared friend still grants the Strength buff, whereas the (superseded) dead code explicitly excluded friends. Also, the live version has **no null-guard** on `userDamager` if `e.getDamager()` isn't a `Player` or player-shot `Arrow` (see general `EntityListener` cross-reference note below) — out of scope to fix, flagged for awareness only since it directly affects whether this migrated Strength logic can NPE.
- **Feature allocation:** own `skills` sub-area (on-attack self-buff).

---

## Cross-cutting notes on the `EntityListener.java` migration target (context only, not exhaustively audited — outside assigned slice)

- `EntityListener#onHit(EntityDamageByEntityEvent)` (`v1:src/Listeners/EntityListener.java:52`) is the single live consolidation point for: AttackSpeed (double/triple hit), Juggernaut (arrow immunity), Defense (damage reduction + level-7 cancel chance), Health (regen proc), Ninja (evasive hide), Speed (on-hit speed proc), and Strength (on-attack damage buff) — i.e. **all** of `AttackSpeedEvent`, `JuggernautSkill`, `DefenseEvent`, part of `HealthEvent`, `NinjaSkill`, part of `SpeedEvent`, and `StrengthEvent` from this slice have their live logic here instead of in their own files.
- Confirmed rebalances during migration: Defense level-7 full-cancel chance dropped from 50% (dead) to 25% (live, `EntityListener.java:186`); Strength's broken unbounded `nextInt()` roll was fixed to a proper `nextInt(100)`-equivalent via `Main.getRandom(0,100)`.
- Confirmed regression during migration: Strength's friend-exclusion check present in the dead `StrengthEvent.java` is absent from the live `EntityListener.java` Strength block.
- Confirmed latent-NPE fixes during migration: Juggernaut and Ninja both gained `getSpecialSkillName() != null &&` guards in `EntityListener.java` that their dead single-purpose-file predecessors lacked.
- `userDamager` in `EntityListener#onHit` is only assigned inside the `if (e.getDamager() instanceof Player)` / `else if (e.getDamager() instanceof Arrow)` branches (`EntityListener.java:74-100`); if damage comes from neither (e.g. a zombie, a splash potion, TNT), `damager`/`userDamager` remain `null`, yet the Strength block later unconditionally calls `userDamager.getStrengthID()` (`EntityListener.java:272`) with no null-check — this reads as a real latent NPE risk in the live code for any non-player/non-arrow damage source reaching this deep into the method (assuming no earlier `return` intercepts it first — the safe-zone/siege checks at `EntityListener.java:292` onward come *after* the Strength block, so they wouldn't save it). This is flagged for completeness since it's a bug in the actual live game logic downstream of this slice's dead code, even though the file itself is out of scope for full audit.

---

## Per-file live/dead handler tally

| File | Total `@EventHandler` methods found | Live | Dead (commented) | Live-but-never-fired (orphaned event) |
|---|---|---|---|---|
| `KillsDeaths/CombatCheck.java` | 5 | 1 (`onEnter`) | 4 | — (though `onEnter`'s data source is itself orphaned, see notes) |
| `KillsDeaths/KillDeathStat.java` | 3 | 1 (`ExpMobKill`) | 2 | — |
| `KillsDeaths/RespawnLocation.java` | 1 | 0 | 1 | — |
| `Listeners/DoubleDamageListener.java` | 1 | 1 | 0 | — |
| `Skills/AssassinSkill.java` | 1 | 1 | 0 | — |
| `Skills/AttackSpeedEvent.java` | 2 | 0 | 2 | — |
| `Skills/AvengerSkill.java` | 3 | 0 | 3 | — |
| `Skills/DefenseEvent.java` | 1 | 0 | 1 | — |
| `Skills/ForgerSkill.java` | 1 | 1 | 0 | — |
| `Skills/HealthEvent.java` | 4 | 1 (`Health`) | 2 | 1 (`Health` itself — see finding) |
| `Skills/JuggernautSkill.java` | 1 | 0 | 1 | — |
| `Skills/NinjaSkill.java` | 1 | 0 | 1 | — |
| `Skills/PickpocketSkill.java` | 1 | 1 | 0 | — |
| `Skills/ShotbowSkill.java` | 1 | 1 | 0 | — |
| `Skills/SpeedEvent.java` | 4 | 1 (`SpeedWalk3`) | 3 | 1 (`SpeedWalk3` itself — see finding) |
| `Skills/StrengthEvent.java` | 1 | 0 | 1 | — |
| **Total** | **31** | **9** | **21** | **2 of the 9 "live" ones are actually never invoked** |

Net: of 31 `@EventHandler` methods in the assigned 16 files, 9 are not commented out, and of those 9, 2 (`HealthEvent#Health`, `SpeedEvent#SpeedWalk3`) have no code anywhere in the repository that fires their triggering custom event — leaving **7 genuinely functioning handlers** in this entire slice: `CombatCheck#onEnter` (itself reading an apparently-orphaned map), `KillDeathStat#ExpMobKill`, `DoubleDamageListener#DoubleDamage`, `AssassinSkill#assassin`, `ForgerSkill#onPurchase`, `PickpocketSkill#Pickpocket`, `ShotbowSkill#Shotbow`.
# v1 event-listener catalog — Arena/Duel/Siege/Minigame domain

Mined from `knk-v1-archive` (single-commit Bukkit import). Companion doc to
`docs/specs/legacy/commands-v1.md` (its `siege-minigame` domain section) and
`docs/specs/legacy/user-system.md` (citation format). All citations verbatim
`v1:src/Path/File.java:line` or `line1-line2`, relative to
`Repository/knk-v1-archive` (read from the absolute on-disk path since the
worktree's checkout of that repo is empty).

## Methodology

Full read, top to bottom, of all 14 assigned files under `src/Arenas`,
`src/HideAndSeek`, `src/Sieges`, `src/Minigames`, and `src/Treasure`, cataloguing
**every `@EventHandler`-annotated method found**, whether live or commented out.
A large fraction of this slice's `@EventHandler` methods are commented out in
source (`//` block comments spanning the entire method) — these are cited and
described from the comment text itself, exactly as the author left them, and
explicitly marked **dead/commented, never compiles** rather than described as
if they run. Only 9 `@EventHandler`-annotated methods across the 14 files are
live (not commented), and of those, one (`ArenaNPC.onEnter`) has an empty body
(its *contents* are commented out even though the annotation and method
signature are live) — functionally a no-op. No behavior is invented; anything
whose implementation lives in an out-of-scope class (`Treasures.java`,
`House`/`Room`/`Scenario`/`SiegeSpawnpoint`/`Objective`, etc.) is marked
unclear/out-of-scope. Feature-domain calls follow the categories established
in `commands-v1.md` (`siege-minigame`, `misc`, `world-admin`, etc.), with
explicit judgment-call flags per the task instructions where a file's actual
behavior doesn't fit `siege-minigame` cleanly.

## Cross-file structural observation (read first)

**Most of this domain's event-driven logic is dead code.** Of the 14 files,
6 have **zero live `@EventHandler` methods at all** — every listener in them
is commented out, so the class exists (registered as a `Listener` or not) but
contributes no runtime behavior beyond any plain helper methods it still
exposes (which are themselves only reachable from the dead code, i.e. also
effectively unreachable):

- `src/Arenas/ArenaTouch.java` — fully dead (1 commented handler).
- `src/Sieges/ScenarioCreationEvents.java` — fully dead (4 commented handlers:
  command-preprocess, chat, interact — the entire chat/click-driven siege
  scenario creation wizard's event wiring is commented out).
- `src/Sieges/SiegeEvents.java` — fully dead (1 commented handler, empty body
  besides an empty `for` loop even when uncommented).
- `src/Minigames/BanditKill.java` — fully dead (1 commented handler); the
  live helper method `banditAchieved(User)` (line 169-191) is never called
  from anywhere reachable, since its only caller is inside the commented-out
  `onNPCKill`.
- `src/Minigames/BanditSpawn.java` — fully dead (2 commented handlers, plus
  ~150 more lines of doubly-commented-out alternate implementation); the live
  helper methods `spawnBandits`/`createBandits`/`getRandomBanditLocation`/
  `isNight`/`getActiveBandits` are likewise unreachable in practice.
- `src/Minigames/DiscoverTown.java` — fully dead (1 commented handler).
- `src/Minigames/TransportEvents.java` — fully dead (4 commented handlers).

This is significant signal for v3 design: the "ambush bandits while walking,"
"discover-town travel-assignment tracking," and "transport/courier escort"
minigame families were apparently built out at the state/logic-class level
(`BanditSpawn`, `Transport`, etc., referenced but out of this read's scope)
but their Bukkit event hooks were disabled/abandoned before shipping — these
systems do not currently run in v1 at all, unlike, say, `/siege join` (a
stub command per `commands-v1.md`) which is at least reachable.

`src/Arenas/Duel.java` implements `Listener` but declares **no
`@EventHandler` methods whatsoever** (no `EventHandler` import even present)
— it is the duel state-machine/orchestration class (timers, countdown,
region-membership, reward payout), not itself an event listener; the actual
Bukkit hooks that drive it live in `DuelEvents.java`. Documented here for
context since `DuelEvents`' handlers call directly into its public methods.

---

## 1. `ArenaNPC.onEnter` — src/Arenas/ArenaNPC.java:28-45

1. **Event type**: `EnterTownEvent` (custom event, `Handlers.EnterTownEvent`). No priority/`ignoreCancelled` specified (default).
2. **Trigger condition**: annotation and signature are live, but the **entire method body is commented out** (v1:src/Arenas/ArenaNPC.java:31-44) — the method compiles and registers as a handler, but does nothing at runtime. Functionally a no-op.
3. **Goal/function (as written in the comment, not executing)**: intended to check `DiscoverTown.playersinTown` for a player who just entered the town matching the event's `townID`, and if found, call `spawnArenaMaster(townID)` (line 40) to spawn the arena-owner NPC for that town's arena(s).
4. **Feature allocation**: `siege-minigame` (arena domain) — intended purpose, though currently inert.
5. **Bugs/edge cases**: **Dead handler** — `spawnArenaMaster(Integer townID)` (lines 47-72), the one substantive method in this file, is never invoked from anywhere live; the arena-master NPC auto-spawn-on-town-entry feature does not currently function. `spawnArenaMaster` itself (if ever called) iterates `arena.getArenaIDList(townID)`, and for each arena with no NPC yet assigned (`npcID == 0 || npcID == null`, line 53) and a registered "npc" spawnpoint (line 56-57), creates a Citizens `NPC` of type `PLAYER` named "Paladinen" displayed as "Arena Owner" with the `ArenaMaster` trait, protected, spawned at the spawnpoint, and records its ID via `arena.setNPCID(...)` (60-65) — this logic itself looks complete and correct, just unreachable. Heavy use of `Bukkit.getConsoleSender().sendMessage(...)` debug logging left in (lines 51,55,59,69) — console-log spam if ever re-enabled, not gated by a debug flag (contrast `BanditSpawn`'s `debug` boolean gate).
6. Citation: v1:src/Arenas/ArenaNPC.java:28-45 (handler), 47-72 (`spawnArenaMaster`).

## 2. `DuelEvents.onKill` — src/Arenas/DuelEvents.java:59-86

1. **Event type**: `PlayerDeathEvent`. No priority/`ignoreCancelled` specified (default `NORMAL`).
2. **Trigger condition**: `e.getEntity() instanceof Player && e.getEntity().getKiller() instanceof Player` (line 62); `main.duelList` non-empty (64); the **head-of-queue duel only** — always inspects `main.duelList.get(0)` (66), never iterates the full list; requires that duel's `duelExpire` be non-null, i.e. the duel has actually started (67).
3. **Goal/function**: resolves both the dead and killing players' `User` objects (71-72, via `Users.getUser`, **not wrapped in try/catch** — unlike almost every other lookup in this slice); if the dead player is one of `duel.user1`/`duel.user2` (73) **and** the killer is the *other* duel participant (75), calls `duel.endDuel(true, killeru, diedu, duel.winTime)` (77) — this drives `Duel.endDuel` (src/Arenas/Duel.java:256-343): announces the winner via `ActionBar`, teleports the loser to the arena exit (or world spawn if none configured), schedules a delayed `removeDuel` and delayed winner-teleport via `BukkitRunnable`, and — if configured — pays out `coinPrize` (`winner.addCoins(...)`, Duel.java:311) and/or `itemPrize` items into the winner's inventory or enderchest, falling back to dropping items on the ground if both are full (Duel.java:317-333).
4. **Feature allocation**: `siege-minigame` (duel domain) — matches `commands-v1.md`'s existing categorization.
5. **Bugs/edge cases**:
   - **Only checks `duelList.get(0)`, never the full list** (v1:src/Arenas/DuelEvents.java:66) — if more than one duel is genuinely concurrently live in PvP (queueing design in `Duel.tryStart`, Duel.java:101-139, is meant to serialize duels via `countDownMove`/region membership, so in practice only the head duel should have live PvP-permitted arena membership at a time — but this is an assumption enforced elsewhere, not defensively checked here) a death in any duel other than index 0 would be silently ignored by this handler.
   - **If the dead player is a duel participant but the killer is *not* the other duelist** (e.g. killed by a third party, mob-attributed-to-player kill, or any other PvP source while standing in the arena), the code falls to the `else` branch and calls `duel.endDuel(false, null, null, 1)` (line 80) — a **forced draw that ends and cancels the entire duel**, rather than e.g. ignoring the kill or awarding the surviving duelist a win. Cite v1:src/Arenas/DuelEvents.java:73-82.
   - Participant identity is checked with reference equality (`diedu == duel.user1`, `killeru == duel.user1`, lines 73/75) rather than UUID/`.equals()` comparison — relies on `Users.getUser(uuid)` always returning the exact same cached `User` instance; fragile if any code path elsewhere constructs a fresh `User` for the same UUID (as e.g. `/stats` and `/balance` are documented doing in `commands-v1.md`). Flagged unclear/needs-cross-file-trace whether `Users.getUser` guarantees singleton identity.
   - No try/catch around `Users.getUser(...)` at lines 71-72 — inconsistent with the rest of the slice (every other file in this catalog wraps `Users.getUser` in try/catch for `UserNotFoundException`/`Exception`); an unresolvable user here (e.g. an NPC entity misclassified, or a user record missing) would throw unhandled inside a core PvP event handler.

## 3. `DuelEvents.onLeave` — src/Arenas/DuelEvents.java:88-124

1. **Event type**: `PlayerQuitEvent`. No priority/`ignoreCancelled` specified.
2. **Trigger condition**: fires for every player quit; resolves `User` via `Users.getUser(player.getUniqueId())` (92) with **no try/catch** (same omission as `onKill`); then unconditionally checks `main.duelList` (all entries, not just head) and `DuelCommands.inviteList`.
3. **Goal/function**: for every `Duel` in `main.duelList` where the quitting player is `user1` or `user2` (98,103), forces the duel to end **as if the other player won**: `duel.endDuel(true, duel.user2, duel.user1, 1)` (100) or the mirrored call for `user2` (105) — this routes through the same winner-payout path as a real kill in `Duel.endDuel` (Duel.java:256-343), i.e. **the remaining player is credited a win and receives the configured coin/item prize**, and is additionally sent a plain chat message "Your opponent left!" via `duel.sendMessage(...)` (101/106). Separately, iterates `DuelCommands.inviteList` (110-123) and removes/cancels any pending (pre-duel) invite involving the departing player, notifying the other party if they were the invite's target (119).
4. **Feature allocation**: `siege-minigame` (duel domain).
5. **Bugs/edge cases**:
   - **Quitting mid-duel awards the opponent a full win payout** (coins/items), identical to a legitimate kill — flagged as a possible design choice (forfeit = loss) but worth calling out explicitly since it's indistinguishable from `onKill`'s reward path; a player could quit intentionally to trigger this for the *other* player's benefit, or (more likely a griefing/self-serving angle) reconnect immediately after their opponent receives nothing while they lose nothing but the match — no penalty is applied to the departing player's own record in this file (any loss-tracking, if any, would live in `endDuel`/`Duel.java` internals not further explored here).
   - Loop over `main.duelList` has **two independent `if`s, no `break`/`return`** after a match is found (v1:src/Arenas/DuelEvents.java:96-108) — harmless in practice (a player shouldn't be in two duels simultaneously) but structurally sloppy; no early exit once the departing player's duel is handled.
   - Same unguarded `Users.getUser` call as `onKill` (line 92) — no try/catch, inconsistent with the rest of the codebase's pattern.

## 4. `DuelEvents.onClose` — src/Arenas/DuelEvents.java:126-177

1. **Event type**: `InventoryCloseEvent`. No priority/`ignoreCancelled` specified. Global — not scoped to a WorldGuard region.
2. **Trigger condition**: `e.getPlayer() instanceof Player` guard (129, needed since the API type is `HumanEntity`); `DuelCommands.inviteList` non-empty (134); dispatch is by **matching the closed inventory's title string** against the literal `"Choose duel-type and place bets!"` (with `ColorOptions.stats` color-code prefix) (136) — a fragile string-based correlation rather than a stored inventory reference/ID.
3. **Goal/function**: for the matching pending `DuelInvite`, if the closing player is the `sender` (140) or `target` (156) of that invite, and they have **not** already placed a coin bet (`!DuelSetupClick.coinBetList.containsKey(uuid)`, 142/158), refunds every non-air item from their designated item-bet slots back into their inventory via `Users.getUser(...).inventoryAddItem(...)` (148/164), notifies both parties that the duel setup was cancelled (151-152/167-168), and calls `removeInvite(invite)` (153/169) to tear down the pending invite.
4. **Feature allocation**: `siege-minigame` (duel domain, pre-duel setup phase).
5. **Bugs/edge cases**:
   - **If the closer *has* already placed a coin bet** (`DuelSetupClick.coinBetList.containsKey(uuid)` is true), **neither the refund/cancel body nor any alternate handling executes** — the `if (!... )` guards (142, 158) simply skip past the whole refund/cancel block with no `else`, so the method falls through to its end with no feedback and the pending `DuelInvite` is left in place, unresolved (v1:src/Arenas/DuelEvents.java:142-154, 158-171). Whether this is intentional (a coin-bet chat prompt is expected to be in progress and would handle inventory-close itself, per the commented-out `onChat` handler later in the same file) or a genuine dead-end leaving inconsistent invite state is unclear/out-of-scope — the coin-bet chat flow itself is entirely commented out in this same file (lines 178-235), so in the current build there is **no live path that ever sets an entry in `DuelSetupClick.coinBetList` in the first place**, meaning this guard's false branch can likely never actually be exercised at runtime — worth flagging as latent/unreachable-by-construction given the chat handler is dead.
   - Title-string matching for dispatch (line 136) is brittle: any inventory a player closes with that exact colored title (even one opened for unrelated reasons, in principle) would trigger this refund logic.

## 5. `HideAndSeekEvents.onHungerDecrease` — src/HideAndSeek/HideAndSeekEvents.java:241-277

1. **Event type**: `FoodLevelChangeEvent`. No priority/`ignoreCancelled` specified.
2. **Trigger condition**: `entity instanceof Player` (246); resolves `User` via `Users.getUser(uuid)` wrapped in proper try/catch (`UserNotFoundException` → `ErrorHandlers.userNotFoundAction`, generic `Exception` → stack trace + same handler, both with early `return`) (255-267, correctly gated); requires `HideandSeeks.findHideAndSeek(user)` to return non-null, i.e. the player is currently registered as a Hide and Seek participant (269-274).
3. **Goal/function**: `e.setCancelled(true)` (276) — unconditionally prevents hunger-level changes (i.e. starvation) for any participant, for the entire duration they're flagged as "in" a Hide and Seek game.
4. **Feature allocation**: `siege-minigame` (hideandseek domain, per `commands-v1.md`'s existing grouping).
5. **Bugs/edge cases**: unlike the **commented-out** sibling handler in the same file (`onDamage`, lines 82-239, dead) which explicitly checks `Main.HideAndSeek.getProgress()`/`getInHub()` before acting, `onHungerDecrease` has **no check on game stage** — hunger is frozen for a participant even during a pre-game lobby/setup phase, not just while actively hiding/seeking. Minor scope-creep versus the (dead) sibling's more careful gating; not necessarily wrong, but inconsistent with the pattern established elsewhere in the same class.

## 6. `HideAndSeekEvents.onTownLeave` — src/HideAndSeek/HideAndSeekEvents.java:279-338

1. **Event type**: `com.mewin.WGRegionEvents.events.RegionLeaveEvent` — a third-party WorldGuard-region-events plugin's custom event, fires whenever **any** player leaves **any** WorldGuard region. No priority/`ignoreCancelled` specified.
2. **Trigger condition** (all sequential early-returns): resolves `townID` from the region via `Worldguard.getStructureIDbyRegion(e.getRegion())` (282); resolves `User` with proper try/catch (287-299); requires `HideandSeeks.findHideAndSeek(user)` non-null (301-306, i.e. player is registered in a Hide and Seek game); requires `Worldguard.isTownRegion(e.getRegion())` (308-311, i.e. the region being left is specifically a "town" region, not an arbitrary one); requires **not** `Worldguard.isChildRegion(e.getRegion())` (313-316, skips leaves of sub-regions like houses/rooms nested inside the town, to avoid false triggers); requires the left town's ID to match `hs.getTownID()` (318-321, i.e. only the specific town this game is bound to); requires `hs.getProgress()` true (323-326, game must be actively in progress, not lobby); requires `!hs.getFinished()` (328-331, game must not already be over).
3. **Goal/function**: calls `user.pushBack()` (334) and shows an `ActionBar` warning "You can't leave this town while playing Hide and Seek!" (335-336) — a soft, after-the-fact boundary-enforcement mechanism keeping participants confined to the game's town during an active match.
4. **Feature allocation**: `siege-minigame` (hideandseek domain).
5. **Bugs/edge cases**: **`e.setCancelled(true)` is commented out** at v1:src/HideAndSeek/HideAndSeekEvents.java:333 — the underlying region-leave event is **not** actually cancelled; enforcement relies entirely on `user.pushBack()` (implementation out of scope — `Users.User` class not read in this pass) to physically relocate the player back inside the region after the fact. If `pushBack()` doesn't reliably restore the player's exact position (e.g. any latency, or if it merely nudges them rather than teleporting precisely), a player could transiently or persistently end up outside the town boundary while the game logic still behaves as though the leave "shouldn't" have happened — a race between the region-leave's other side effects (any other plugin reacting to the same event) and the corrective push-back. Flagged as unclear/needs-`pushBack()`-implementation-check rather than a confirmed bug, but the disabled cancellation is a deliberate, citable design choice worth flagging.

## 7. `FishGame.onCatch` — src/Minigames/FishGame.java:36-129

1. **Event type**: `PlayerFishEvent`. No priority/`ignoreCancelled` specified. Global — no WorldGuard region gate at all.
2. **Trigger condition**: resolves `User` with proper try/catch (43-55); requires `user.getTitleID() >= 3` (56) — a rank/title gate — else `e.setCancelled(true)` with a message naming the required title by ID (124-127, via `title.getTitleName(3,1)`/`(3,2)`, i.e. gendered title name); requires the held item to have `ItemMeta` (58) and to resolve to a known shop product by display name via `product.getProductIDbyDisplayName(...)` (60-61) — i.e., the player must be fishing with a specific **shop-sold fishing rod item**, not any vanilla rod — else `e.setCancelled(true)` with "You can only catch fish with an item from a shop!" (114-123, two separate cancel sites for the no-productID and no-ItemMeta cases).
3. **Goal/function**: on `PlayerFishEvent.State.CAUGHT_FISH` (64):
   - If the vanilla catch was `RAW_FISH` (66): swaps the caught `Item`'s stack for a custom "rawfish" shop-product item via `product.createPropertyItem(...)` (68), increments the user's fish-caught stat (`addCatchedFish(true,1)`, 69), grants 1 XP (`addExperience(1,true)`, 70) and fires a custom `ExperienceChangeEvent` (71), plays a pickup sound and sends chat feedback about the XP gained and a tip that fish sell for coins at a "Fishery" (72-74).
   - Otherwise (any non-raw-fish vanilla catch, i.e. junk/treasure) (75-112): a sequence of **independent** (not `else-if`) random-chance loot rolls, each of which — if triggered — overwrites the caught item's stack via `item.setItemStack(...)`: skill point (1/1000 chance, no item change, 79-81), small gold nuggets (100/1000, 82-87), large gold nuggets (1/1000, 88-93), small gold ingots (10/1000, 94-99), large gold ingots (1/1000, 100-105), gold blocks (1/10000, 106-111) — each with its own chat message.
4. **Feature allocation judgment call**: this is a **rank/shop-item-gated fishing loot system tied to the title/XP economy**, entirely unrelated to arena/siege/duel/hideandseek mechanics — no WorldGuard region check, no minigame-participant state, no team/objective tracking. Recommend `misc` (matches the existing precedent for `/treasure` in `commands-v1.md`, which was judged `misc` rather than `siege-minigame`), not `siege-minigame`. Flagging explicitly per the task's request to not force-fit non-siege minigames into the domain.
5. **Bugs/edge cases**:
   - **Overlapping independent `if`s, not `else-if`, on the loot-roll chain** (v1:src/Minigames/FishGame.java:82-111): because each condition is checked independently and each sets `item.setItemStack(...)` when true, if multiple rolls succeed in the same catch (statistically rare given the low percentages, but possible — e.g. both the 100/1000 small-nugget roll and the 1/1000 large-ingot roll succeed), **only the item set by the last successful branch in source order actually survives** on the caught `Item` entity, while the player still receives **all** the chat messages for every roll that succeeded — meaning the player can be told they received nuggets *and* ingots but only actually get whichever was set last (gold blocks last, since it's the final branch, would win if it also happened to roll). Minor economy-inconsistency bug, low-severity given the low overlap probability but a genuine logic flaw.
   - The `else` branch's cancel-with-message path (114-118) fires when `productID` resolves to `null` (no matching shop item), and the outer `else` (119-123) fires when the held item lacks `ItemMeta` at all — both send the identical error message, which is fine, but note the title check at line 56 runs *before* the item-check, so a low-title player fishing with a proper shop rod is told they lack rank (127) rather than ever reaching the item-validity branch — acceptable precedence, just noting message-ordering priority.

## 8. `OcelotSpawn.onSpawn` — src/Minigames/OcelotSpawn.java:19-26

1. **Event type**: `CreatureSpawnEvent`, explicit `priority = EventPriority.HIGHEST` (line 19) — runs late in the handler chain, just before `MONITOR`, so it overrides cancellations set by any other plugin/listener at `NORMAL` or lower priority (but not ones at `MONITOR`).
2. **Trigger condition**: `e.getEntityType() == EntityType.OCELOT` (22) — no location/region/world check at all.
3. **Goal/function**: `e.setCancelled(false)` (24) — unconditionally forces the spawn event to **not** be cancelled, regardless of whatever cancelled it earlier in the chain (other anti-mob-spam plugins, spawn-limiting logic, etc.).
4. **Feature allocation judgment call**: this is **not a minigame handler** in any functional sense — it registers no objective, region, or participant state; it is a blunt global mob-spawn-rule override/patch, presumably to guarantee ocelots can always spawn (perhaps because they're needed as tameable pets or for a cat/ocelot-related feature elsewhere in the codebase, out of scope here). It happens to live in the `Minigames` package but doesn't belong in `siege-minigame` at all. Recommend `misc`/`world-admin` (spawn-rule patch, akin to server-utility flags), explicitly flagged as a judgment call per the task instructions rather than silently filed under siege-minigame just because of its package location.
5. **Bugs/edge cases**: completely unscoped — applies globally, to every world, every biome, every spawn reason (natural, spawner, egg, etc. — `CreatureSpawnEvent` doesn't distinguish reason here since `e.getSpawnReason()` is never checked). If any other plugin or a later-priority `MONITOR` listener intentionally cancels ocelot spawns for a legitimate reason (mob-cap enforcement, protected-region rules), this handler silently defeats that intent for this one entity type. No debug logging, no explanation in-code of *why* ocelots specifically need this override.

## 9. `TreasureEvents.onClick` — src/Treasure/TreasureEvents.java:31-99

1. **Event type**: `PlayerInteractEvent`. No priority/`ignoreCancelled` specified. Global — not WorldGuard-region-gated; scoped purely by block type (`CHEST`) and static in-progress-creation state.
2. **Trigger condition**: resolves `User` with proper try/catch (38-50); branches on `Treasures.createTreasure` static map keyed by UUID (58) — i.e. whether the player is currently in **staff/admin treasure-creation mode** (presumably entered via a `/treasure create`-style command, out of scope of this file); within that, further branches on `action == RIGHT_CLICK_BLOCK && block != null && block.getType() == Material.CHEST` (54).
3. **Goal/function**:
   - **Creation mode + chest right-click** (58-75): cancels the event (60); if a `Treasure` already exists at that block's location (`Treasures.findTreasure(location)`, 57), errors "This chest already is a treasure!" (63); else calls `Treasures.createTreasure(location, Treasures.createTreasure.get(user.getUUID()))` (66) to persist a new treasure record, looks up a `SpawnPoint` exactly at that location via `spawnpoint.getSpawnPointIDbyLocation(location)` (67), and **only if one exists** (69), calls `Treasures.instantiateTreasure(Treasures.getTreasureID(spawnpointID), true)` (71) to activate it; sends a success message and clears the creation-mode flag for that player (73-74).
   - **Not in creation mode + chest right-click, treasure exists** (76-93): cancels the event (80); if the player hasn't already discovered this treasure (`!treasure.GetDiscoveredList().contains(userID)`, 81), opens it via `treasure.openTreasure(user)` (84, actual reward-granting logic out of scope — lives in `Treasure.java`/`Treasures.java`, not read in this pass); else tells them they already discovered it (87).
   - **Not in creation mode + chest right-click, no treasure at that location** (89-92): no cancellation, no player feedback — just a server-console debug log ("No treasure found on location", 91) via `main.logMessage(...)`; normal vanilla chest-opening proceeds uninterrupted.
   - **In creation mode, but the interaction was not a chest right-click** (94-98): cancels the event anyway and reminds the player to right-click a chest or type `/treasure cancel` (96-97) — meaning **while flagged for treasure creation, every `PlayerInteractEvent` for that player is intercepted and cancelled**, not just chest-related ones (e.g. right-clicking a door, a lever, or even left-clicking would all be swallowed by this branch as long as it isn't specifically a chest right-click).
4. **Feature allocation**: `misc`, consistent with the existing precedent set in `commands-v1.md` for `/treasure` (judged `misc`, not `siege-minigame`) — this listener is the natural companion to that command and inherits the same classification.
5. **Bugs/edge cases**:
   - **Silent no-treasure branch cancels nothing and gives zero feedback** (89-92) — right-clicking an ordinary chest with no treasure attached, while not in creation mode, produces only a server-console log line invisible to the player; harmless but a minor missed-feedback opportunity (contrast with the "This chest already is a treasure!" and "already discovered" branches, which do message the player).
   - **Treasure creation without a co-located `SpawnPoint` silently produces an un-instantiated treasure** (67-72): the DB row is saved via `Treasures.createTreasure(...)` regardless, but `instantiateTreasure(...)` — whatever runtime activation that performs — is skipped entirely if no exact-location spawnpoint exists. Whether an un-instantiated treasure can ever later be opened by a player (the discovery-check code path at line 78 onward calls `Treasures.findTreasure(location)`, which presumably still finds the DB row) is unclear/out-of-scope without reading `Treasures.java`; flagged as a possible "treasure created but non-functional" edge case rather than a confirmed bug.
   - **Broad interact-swallowing while in creation mode** (94-98): every non-chest-right-click interaction is cancelled for a player mid-treasure-creation, which could interfere with unrelated interactions (e.g. a staff member trying to also open a door or use another item) with only a generic reminder message, no way to distinguish accidental interactions from intentional ones except by cancelling all of them.
   - No priority/`ignoreCancelled` specified — if the player already has the interact event cancelled by anti-grief/region-protection plugins before this handler runs (default `NORMAL` priority, order among same-priority listeners is registration order), this handler's own logic still executes regardless of that prior cancellation (Bukkit's `ignoreCancelled` defaults to `false`, meaning the handler runs even on an already-cancelled event, but this handler doesn't check `e.isCancelled()` itself) — could mean chest-based treasure interactions still fire even if some other plugin already denied the raw block interaction, allowing treasure logic to run in a region where interaction was otherwise supposed to be blocked. Flagged as unclear without deeper cross-plugin knowledge.

---

## Summary of feature-domain allocation judgment calls

| File | Live handler(s)? | Recommended domain | Rationale |
|---|---|---|---|
| `ArenaNPC.java` | 1 (inert/no-op) | `siege-minigame` | Arena-master NPC spawn-on-town-entry; intended purpose fits arena, just currently dead. |
| `ArenaTouch.java` | 0 (fully dead) | `siege-minigame` | Intended purpose (open arena menu on region touch) fits arena. |
| `Duel.java` | 0 (no handlers; pure state class) | `siege-minigame` | Backing logic for `DuelEvents`. |
| `DuelEvents.java` | 3 | `siege-minigame` | Core duel kill/leave/setup-cancel handling. |
| `HideAndSeekEvents.java` | 2 | `siege-minigame` | Matches existing `commands-v1.md` hideandseek grouping. |
| `ScenarioCreationEvents.java` | 0 (fully dead) | `siege-minigame` | Siege-scenario creation wizard's event wiring (dead). |
| `SiegeEvents.java` | 0 (fully dead) | `siege-minigame` | Named/intended for siege. |
| `BanditKill.java` | 0 (fully dead) | **`misc`** (judgment call) | Roaming-ambush loot/kill minigame, not region/arena-based; separate family, matches Treasure precedent. |
| `BanditSpawn.java` | 0 (fully dead) | **`misc`** (judgment call) | Same ambush-minigame family as BanditKill; walk-triggered, title-scaled bandit-NPC spawner, not siege-related. |
| `DiscoverTown.java` | 0 (fully dead) | **`misc`** (judgment call) | Travel-distance **assignment/quest** progress tracking, not a minigame with objectives/teams; arguably belongs under a future `quests`/`assignments` domain rather than `misc` or `siege-minigame` — flagged as the least certain call in this table. |
| `FishGame.java` | 1 | **`misc`** (judgment call) | Rank/shop-item-gated fishing loot tied to title/XP economy; no region/arena/team mechanics at all. |
| `OcelotSpawn.java` | 1 | **`misc`/`world-admin`** (judgment call) | Not a minigame handler — a blunt global mob-spawn-rule override; only in the `Minigames` package by file location, not by function. |
| `TransportEvents.java` | 0 (fully dead) | **`misc`** (judgment call) | Courier/escort minigame family (move goods to a warehouse, risk of being killed en route for a bounty) — distinct from siege-minigame, matches Treasure precedent. |
| `TreasureEvents.java` | 1 | `misc` | Matches the existing explicit precedent set for `/treasure` in `commands-v1.md`. |

## Recurring bug/edge-case patterns found (beyond per-handler detail above)

1. **Missing try/catch around `Users.getUser(...)`** in `DuelEvents.onKill` (line 71-72) and `DuelEvents.onLeave` (line 92) — inconsistent with the try/catch pattern used everywhere else in this slice (`HideAndSeekEvents`, `FishGame`, `TreasureEvents` all wrap it correctly).
2. **A duel-participant's death to a non-opponent forces a full draw/cancellation** rather than ignoring the kill or awarding a win to the survivor (`DuelEvents.onKill`, lines 73-82).
3. **Quitting mid-duel grants the remaining player a full win payout** (coins/items), same path as a legitimate kill (`DuelEvents.onLeave`, lines 100/105 → `Duel.endDuel(true, ...)`).
4. **Commented-out `e.setCancelled(true)`** left disabled in `HideAndSeekEvents.onTownLeave` (line 333) — enforcement relies solely on a corrective `pushBack()` rather than preventing the leave outright.
5. **Overlapping independent `if`s in a loot-roll chain** overwrite each other's `ItemStack`, while still sending every roll's chat message (`FishGame.onCatch`, lines 82-111) — player-visible message/reward mismatch.
6. **Six of fourteen files have zero live event handlers** — entire minigame subsystems (bandit ambush, discover-town travel assignments, transport/courier escort, siege-scenario creation wizard, generic siege events, arena-touch menu) are event-wiring-disabled dead code in the current build, independent of any command-level stub status already documented in `commands-v1.md`.
7. **Unscoped/global handlers with no WorldGuard region gate**: `FishGame.onCatch`, `TreasureEvents.onClick`, and `OcelotSpawn.onSpawn` all act purely on item/entity-type/static-map state, never checking whether the player is inside an "arena"/"siege" (or any) WorldGuard region — a structural difference from the arena/siege/duel/hideandseek handlers, which lean on region membership (directly or via the `Duel`/`HideAndSeek` state objects) as part of their trigger conditions.

---

**9 live `@EventHandler`-annotated methods** found across the 14 assigned
files (1 of which, `ArenaNPC.onEnter`, is annotated but has an empty/no-op
body), plus **13 additional `@EventHandler` methods found entirely commented
out** (never compiled, described here from their comment text only) across
`ArenaTouch` (1), `ScenarioCreationEvents` (4: command-preprocess, chat,
interact, plus the doc lists 3 distinct handlers — see file for exact count),
`SiegeEvents` (1), `BanditKill` (1), `BanditSpawn` (2, plus a further
doubly-commented alternate implementation of the same handler), `DiscoverTown`
(1), `TransportEvents` (4), and `DuelEvents`/`HideAndSeekEvents` (1 each,
alongside their live handlers). 6 of the 14 files ship with **no live
event-driven behavior whatsoever**.
# knk-v1-archive — Bukkit Event Listeners: Property / House / Room / Resource domain

**Feature allocation for every listener catalogued below: `property`** (per task scope — this covers the House, Property, Room and Resource-property/resource-harvesting sub-domains).

## Methodology

Every file listed in the task brief was read in full from
`C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-v1-archive` (the working checkout
inside this worktree, `Repository/knk-v1-archive`, is empty — the archive was read from the
absolute disk path instead, as instructed). For every `@EventHandler` method found, the Bukkit
event type, its trigger condition (WorldGuard region lookups via `Worldguard.getStructureIDbyRegion`,
block/material checks, chat state-machine checks), and its goal were read directly out of the
method body — nothing here is inferred beyond what the code says. Where a class contained only
commented-out `@EventHandler` methods (dead code, not compiled), that is stated explicitly and the
dead code is still summarized, because it reveals design intent even though it does not run.
Three follow-up files outside the assigned list were opened because the code inside the assigned
files pointed directly at them and they were necessary to describe accurately what actually
happens at runtime: `src/Listeners/PlayerListener.java` (the sell-confirmation chat handler that
supersedes the three commented-out `Confirm` methods — see the dedicated section below),
`src/Handlers/ResourceBlockBreakEvent.java` (the custom Bukkit event that `BlockBreakEvents`
fires and that itself contains the harvesting/yield logic in its constructor), and a grep
confirming `HouseCommands`/`PropertyCommands`/`RoomCommands` are the source of the
`sellconfirm`/`sellpropertyID`/`sellRoomID` static maps referenced by the task brief. A repo-wide
search for `docs/specs/legacy/commands-v1.md` (named in the brief as the style reference) found no
such file in this worktree at all — `docs/specs/legacy/` only contains `README.md`,
`inventory-menus.md`, `items.md`, `kits.md`, `siege-minigame.md`, `towns-districts-gates.md`,
`user-system.md` — so this document's citation format instead follows `user-system.md`'s rigor
(file:line citation for every claim) as the closest available exemplar; this discrepancy is
flagged here rather than silently worked around.

All 13 assigned files were read in full (not excerpted): `Houses/HouseSellEvent.java`,
`Houses/HouseTouch.java`, `Properties/EnchantmentGenerator.java`, `Properties/HomelessEnter.java`,
`Properties/ItemFrameAdd.java`, `Properties/PropertyEvents.java`, `Properties/PropertySellEvent.java`,
`Properties/PropertyTouch.java`, `Properties/SpawnShopkeepers.java`, `Properties/StorageEvents.java`,
`Resources/BlockBreakEvents.java`, `Resources/ResourceKillEvents.java`, `Rooms/RoomSellEvent.java`.

---

## 1. The sell-confirmation flow — cross-reference finding (read this first)

The task brief specifically asked to check whether `HouseSellEvent`, `PropertySellEvent`, and
`RoomSellEvent` are where the `/house sell`, `/property sell`, `/room sell` "type yes or no"
chat-confirmation is consumed. **They are not.** In all three files the only `@EventHandler`
method (`Confirm(PlayerChatEvent e)`) is entirely commented out:

- `v1:src/Houses/HouseSellEvent.java:23-79`
- `v1:src/Properties/PropertySellEvent.java:23-71`
- `v1:src/Rooms/RoomSellEvent.java:25-70`

These three classes still `implements Listener` and are presumably still registered with Bukkit
(registration site not part of this slice), but since the only handler method in each is
commented out, **none of them currently do anything at runtime.** They are dead listener shells.

The actual, live confirmation logic was moved into a single shared handler,
`PlayerListener.onChat(PlayerChatEvent e)` at `v1:src/Listeners/PlayerListener.java:702-991`
(`@EventHandler(priority = EventPriority.HIGHEST)`, `v1:src/Listeners/PlayerListener.java:701`).
Three near-identical blocks inside that one method implement the three sell confirmations
back-to-back:

- **House sell confirm** — `v1:src/Listeners/PlayerListener.java:846-883`. Guarded by
  `HouseCommands.sellconfirm.containsKey(uuid)` (`:849`). On `"yes"` (`:857`): removes the house
  owner (`house.RemoveHouseOwner(houseID)`, `:859`), decrements the seller's house count
  (`user.removeHouseAmount(false, 1)`, `:860`), refunds **half** the house price
  (`user.addCoins((price/2))`, `:861`), and strips the WorldGuard region owner
  (`house.removeRegionOwner(player, houseID, manager)`, `:863`). If the sold house held the
  player's personal spawnpoint, the spawnpoint is reset to default (`:869-873`). On `"no"` or any
  other message: only a cancellation message is sent (`:874-880`) — no state is touched besides
  cleanup. In both branches (`yes`, `no`, and the fallback `else`), `HouseCommands.sellconfirm` and
  `HouseCommands.sellpropertyID` are removed for the uuid at `:881-882`, so the pending state is
  correctly cleaned up on every path, including "no" and garbage input.
- **Property sell confirm** — `v1:src/Listeners/PlayerListener.java:886-914`. Same shape:
  guarded by `PropertyCommands.sellconfirm.containsKey(uuid)` (`:888`); `"yes"` removes the
  property owner (`property.RemovePropertyOwner(propertyID)`, `:897`), refunds half price
  (`:898`), strips the WorldGuard region owner (`:900`). No house-amount decrement equivalent
  exists here (there is no `user.removePropertyAmount(...)` call — properties apparently aren't
  counted the same way houses are, or that accounting is unclear/out of scope from this file
  alone). `PropertyCommands.sellconfirm`/`sellpropertyID` cleaned up unconditionally at `:912-913`.
- **Room sell confirm** — `v1:src/Listeners/PlayerListener.java:917-942`. Guarded by
  `RoomCommands.sellconfirm.containsKey(uuid)` (`:919`). Unlike the other two, `"yes"` does not
  inline the sell logic — it delegates to `room.sellRoom(user, roomID)` (`:932`), a method not in
  this slice (out of scope — its internals, e.g. whether it also refunds coins, are unclear here).
  `"no"`/fallback both print the same "you keep renting" message (`:934-939`, duplicated code, not
  a bug per se). Cleans up `RoomCommands.sellconfirm`/`sellRoomID` unconditionally at `:940-941`.

All three blocks share one structural quirk worth flagging as an edge case: **the confirmation
check has no timeout and no re-entrancy guard beyond the map key's presence.** As long as
`sellconfirm` contains the uuid, *every* chat message the player sends is intercepted
(`e.setCancelled(true)` unconditionally once the key is present, e.g. `:856`, `:894`, `:929`) and
treated as a yes/no/anything-else answer — there's no way to send an unrelated chat message while
a sell is pending without it being swallowed and read as "cancel". This matches the commented-out
originals exactly, so it is inherited design, not a regression from the move.

The dead, commented-out originals in `HouseSellEvent`/`PropertySellEvent`/`RoomSellEvent` are
textually identical to their live `PlayerListener` counterparts except for one divergence: the
live `PropertyCommands` block resolves `RegionManager manager = Worldguard.getRegionManager(...)`
(`v1:src/Listeners/PlayerListener.java:899`) using the static `DataManager.Worldguard` helper,
while the commented-out `PropertySellEvent.java:55` used an instance field `worldguard.getRegionManager(...)`
from `API_methods.WorldGuard` — a different helper class with the same method name. This suggests
the commented-out code is an earlier draft that was superseded, not just disabled duplicate code.

---

## 2. `src/Houses/HouseSellEvent.java`

Whole file is dead code — see Section 1. `HouseSellEvent` has no constructor logic beyond storing
`main` (`v1:src/Houses/HouseSellEvent.java:18-21`) and declares `House`, `Town`, `Street`,
`WorldGuard` fields that are never used because the only method is commented out. No live
`@EventHandler`s exist in this file.

---

## 3. `src/Houses/HouseTouch.java`

### `PTouch(PlayerInteractEvent e)` — `v1:src/Houses/HouseTouch.java:46-185`
- **Event type**: `PlayerInteractEvent`, plain `@EventHandler` (default priority, no
  `ignoreCancelled`) — `v1:src/Houses/HouseTouch.java:46`.
- **Trigger condition**: only proceeds on `Action.RIGHT_CLICK_BLOCK` (`:68`). Resolves the
  clicked block's region via a locally-constructed `WorldGuardPlugin` (`getWorldGuard()`,
  `:187-198`, a private duplicate of the API_methods.WorldGuard helper rather than reusing it),
  then checks `regionset.size() > 0` (`:71`) and
  `Worldguard.getStructureIDbyRegion("house", block.getLocation(), regionmanager)` (`:73`, `:76`)
  to find a house ID for the block.
- **Goal/function**: Two branches.
  - If the clicking player owns the house (`house.getHouseOwnerID(houseID) == user.getID()`,
    `:82`): a per-player click counter (`static HashMap<UUID, Integer> click`, `:45`) is used to
    throttle a "This house is owned by you!" message + note-bass sound + step-sound effect so it
    only fires on the first click and then again every 7th click (`:84-101`).
  - Otherwise, it prints a full house info card (name, price, owner, title, experience — with the
    house ID only shown if the viewer `inOwnerModus()`) to the clicked player (`:104-121`).
  - At the very end, `e.setCancelled(false)` is called unconditionally (`:184`), even outside the
    `if (regionset.size() > 0)` / `if houseID != null` branches — i.e. this listener never actually
    cancels interaction, it always explicitly re-allows it (redundant given `false` is the Bukkit
    default, but explicit).
- **Feature allocation**: `property` (house sub-domain).
- **Bugs/edge cases**:
  - `:71` checks `regionset.size() > 0` but then immediately re-derives `houseID` via
    `Worldguard.getStructureIDbyRegion(...)` without using `regionset` at all — `regionset` is
    fetched only to gate on non-emptiness, then discarded; dead/wasted lookup.
  - The whole block of commented-out code at `:123-179` is a near-duplicate, more elaborate
    version of the live logic above (it additionally distinguishes "owner-mode observer" vs.
    "no owner" vs. "owner is viewer" vs. "someone else owns it" as four separate branches) —
    left in as a comment, presumably an earlier/more complete draft that was simplified for the
    live version, losing the "owner-mode observer sees extended info" special case in the process
    (unclear whether intentionally dropped or accidentally superseded).
  - The click-counter map (`click`, static, keyed by uuid only) is **never cleaned up** — entries
    accrue for every player who has ever right-clicked their own house and are never removed on
    logout; long-running servers would leak entries indefinitely (bounded by player count, so a
    minor leak, not unbounded).
  - No permission check beyond ownership match — any right-click on a "house" region block runs
    this logic for any player, including non-owners just to view the info card, which appears to
    be the intended behavior (public "for sale/info" display), not a bug.

---

## 4. `src/Properties/EnchantmentGenerator.java`

### `onClick(PlayerInteractEvent e)` — `v1:src/Properties/EnchantmentGenerator.java:52-146`
- **Event type**: `PlayerInteractEvent`, default `@EventHandler` — `:52`.
- **Trigger condition**: `Action.RIGHT_CLICK_BLOCK` on a block of type
  `Material.ENDER_PORTAL_FRAME` (`:56`) that resolves to a `"property"` WorldGuard region
  (`Worldguard.getStructureIDbyRegion("property", location, ...)`, `:59`), and whose property's
  category name (via `PropertyCategory.getCategoryName(property.getCategoryID(propertyID))`) is
  `"witchery"` (`:79`).
- **Goal/function**: A "ritual" enchantment-book generator gated by a flat 250,000-coin price
  (`Integer price = 250000`, `:38`). Uses a location-based in-use lock (`generatorList`,
  `List<Location>`, `:50`, checked/added via `inUse(location)` at `:81`/`:287-305` — compares only
  X/Z, ignoring Y, `:294-296`) so only one ritual can run per X/Z column at a time. If the player
  has enough coins:
  - 1% chance (`main.getRandom(0,100) <= 1`, `:87`) to instead pick a **random online player** and
    give them a cash prize of `price * random(1,3)` (250k–750k coins) while the initiating player
    still pays the full price and gets no book (`:88-107`) — this looks like an intentional
    "gambling side-effect" of the ritual, not a bug, but it means the *initiating* player can pay
    250k coins and receive **nothing** (no book, no refund) purely by bad luck on this 1% roll,
    combined with `RandomEnchantment` (`:149-191`) also being capable of returning `null` (see
    below) — a genuine "pay and get nothing" edge case.
  - Reads the category of the item currently in the player's hand (via product display name →
    `product.getCategoryID`) to bias enchantment selection (`:108-120`).
  - Calls `RandomEnchantment(categoryID)` (`:149-191`) to pick a weighted-random enchantment: base
    chance 30% for grade 1, 5% for grade 2, 2% for grade 3, multiplied ×4 if the enchantment's
    preferred category matches the held item's category (`:159-170`); if the roll succeeds but the
    category doesn't match, there's an *additional* 50/50 coin-flip to actually accept it or
    `continue` to the next candidate (`:171-181`) — meaning even satisfying the primary chance can
    still result in no pick for that candidate.
  - If `RandomEnchantment` returns non-null, plays a 4-stage `BukkitRunnable` animation sequence
    (`GeneratorAnimation`, `:193-285`): a flickering placeholder enchanted-book item is
    repeatedly dropped/removed/repositioned every 3 ticks for a spinning effect (`:196-223`),
    lightning strikes at tick 20 only if the chosen enchantment's grade is 3 (`Lightning` flag set
    at `:124-129`), the "real" enchanted-book item is dropped naturally at tick 40 with an anvil
    sound (`:224-261`), and finally at tick 80 the item is added to the player's inventory (or
    dropped on the ground if the inventory is full) with a completion message
    (`:262-284`).
  - If `RandomEnchantment` returns `null` (all candidates rejected), the code re-rolls once more
    (`:131-134`, `enchantmentID = RandomEnchantment(categoryID);`) but **the result of this second
    call is discarded** — it's assigned to the local `enchantmentID` variable but nothing further
    reads it, no animation is triggered, and the function silently falls through to the end of the
    `if` block having already deducted coins. This is a **real bug**: the player is charged (coins
    already removed at `:96`/`:106`) but if both enchantment rolls fail, they get nothing at all —
    no book, no message, no refund, and the location is never removed from `generatorList` at all
    in this failure path (see next bullet).
  - **`generatorList` leak on failure**: the location is added to `generatorList` at `:86` before
    any of the coin/roll logic runs, but it is only ever removed from `generatorList` inside the
    success path's final `BukkitRunnable` (`generatorList.remove(generatorLoc)`,
    `:268`, inside `GeneratorAnimation`'s `giveItem` runnable at `:262-284`). If
    `RandomEnchantment` returns `null` even after the retry (`:131-134`), `GeneratorAnimation` is
    never called, so `generatorList.remove(...)` never runs — **the generator location is
    permanently stuck as "in use"** after a double-failed roll, since `inUse()` (`:287-305`) will
    return `true` forever afterward for that X/Z. This is a confirmed edge case/bug: a low-chance
    failure permanently soft-locks that ritual location until a server restart clears the
    in-memory `generatorList`.
- **Feature allocation**: `property` (witchery-category property sub-feature).
- **Bugs/edge cases** (consolidated): (1) double-null-roll silently charges the player with no
  output and no feedback message (`:131-134`); (2) the same failure path permanently leaks the
  generator location into "in use" state (`:86`, only cleared at `:268` which is unreached on
  failure); (3) `inUse()` compares X/Z only, ignoring Y and world, so two properties stacked at the
  same X/Z in different worlds, or a portal frame block directly above/below another one, would
  incorrectly collide (`:294-296`).

---

## 5. `src/Properties/HomelessEnter.java`

Both `@EventHandler` methods are commented out — this class has **no live event handling** at all:
- `onEnter(PlayerMoveEvent e)` — `v1:src/Properties/HomelessEnter.java:27-82` (commented). Intent
  (from the dead code): while inside a `"property"` region, if the player owns 0 houses and 0
  rooms and isn't in owner-mode and isn't in creative, mark them in a static
  `homelessList` (`:25`) and deal 2 damage with a shopkeeper taunt message the first time they're
  flagged (`:42-47`). On leaving all property regions, if flagged homeless, prints a nudge to buy a
  house/rent a room and opens the "owned houses" menu after a 1-tick delay, unless the player is
  currently in owner-mode (`:56-79`).
- `onDeath(PlayerDeathEvent e)` — `v1:src/Properties/HomelessEnter.java:84-96` (commented). Intent:
  remove the dying player from `homelessList` on death.
- **Feature allocation**: `property` (would-be homeless-penalty mechanic).
- **Bugs/edge cases**: N/A — code doesn't run. Only the `public static ArrayList<UUID> homelessList`
  field (`:25`) is live, and nothing in this slice populates or reads it (grep would be needed
  beyond this slice to confirm total dead-ness across the codebase; within this file it is
  unused). Marking this whole feature "unclear/out of scope" for whether homelessness penalties
  exist anywhere else in the live game.

---

## 6. `src/Properties/ItemFrameAdd.java`

### `Add(PlayerInteractEntityEvent e)` — `v1:src/Properties/ItemFrameAdd.java:81-209`
- **Event type**: `PlayerInteractEntityEvent`, default `@EventHandler` — `:81`.
- **Trigger condition**: fires on right-clicking any entity; branches on
  `e.getRightClicked() instanceof ItemFrame` (`:101`) vs. `EntityType.ARMOR_STAND` (`:200`). For
  item frames, requires the frame's location **and** the player's own location to both resolve to
  a `"property"` WorldGuard region (`:107`) — i.e. you must be standing inside the property to
  interact with its item frames, not just clicking one from outside the boundary.
- **Goal/function**: This is the shop/enchant-menu entry point for property-based shops (item
  frames displaying purchasable products or enchantment books).
  - If the acting player is in "owner modus" (`main.ownermodus`, `:110`), the frame interaction is
    left alone (empty `if` branch, `:111-113`) so builders can edit frames normally.
  - Otherwise the interaction is always cancelled (`e.setCancelled(true)`, `:115`) and the frame's
    held item is inspected:
    - **Enchanted book / plain book frame** (`:120-167`): resolves an enchantment ID by display
      name (`:123`), requires the player to be holding an enchantable item
      (`product.getProductIDbyDisplayName`, `:131`), rejects soulbound items (`:133-150`), and
      uses `EnchantbookClick.canEnchant(...)` to check whether the held item can still take a
      level of that enchantment (`:137-146`). On success, opens the enchant-info menu
      (`openEnchantInfo`, `:140`, `:473-588`) and stashes the currently-held item into
      `enchantItem` (`:142`) keyed by uuid for later consumption by `addEnchantItem`.
    - **Regular product frame** (`:168-186`): resolves a product by stripped/space-collapsed
      display name (`product.getProductID`, `:171`), verifies the property actually stocks that
      product (`propertyproduct.getPropertyListbyProduct(productID).contains(propertyID)`,
      `:174`), fires a custom `ClickShopItemEvent` (`:178`, out of scope), and opens the item-info
      purchase menu (`propertyproduct.openItemInfo`, `:179`).
    - If frame + player aren't both inside a property region, item-frame interaction is simply
      cancelled unless in owner-mode (`:189-198`).
  - Armor stands are similarly locked down to owner-mode only (`:199-208`), independent of
    property-region checks (no WorldGuard lookup gating this branch at all — armor stands are
    protected everywhere, not just inside properties).
- **Feature allocation**: `property` (shop item-frame / enchant-ritual UI).
- **Bugs/edge cases**: none of substance found in this method beyond those already covered by
  `openEnchantInfo`/`addEnchantItem` below. Note the property-check asymmetry: item frames require
  region-matching before doing anything; armor stands never check the region at all (`:200-208`)
  — global lockdown, likely intentional (armor stands used as static display mannequins
  everywhere, not just shops), but flagged as a deliberate inconsistency worth confirming.

### `ArmorStandInterAct(PlayerInteractAtEntityEvent e)` — `v1:src/Properties/ItemFrameAdd.java:211-226`
- **Event type**: `PlayerInteractAtEntityEvent`, default `@EventHandler` — `:211`.
- **Trigger/goal**: Duplicate lockdown of armor-stand interaction — cancels unless the player is
  in owner-mode (`:216-225`), same as the armor-stand branch of `Add()` above but for the
  "interact-at" variant of the entity-click event (Bukkit fires both `PlayerInteractEntityEvent`
  and `PlayerInteractAtEntityEvent` for armor stands specifically). No WorldGuard check here either.
- **Feature allocation**: `property`.
- **Bugs/edge cases**: none found; appears to be defense-in-depth for the two different armor
  stand interaction event types Bukkit fires.

### `menuClose(InventoryCloseEvent e)` — `v1:src/Properties/ItemFrameAdd.java:228-232`
- **Event type**: `InventoryCloseEvent`, default `@EventHandler` — `:228`.
- **Trigger/goal**: Body is empty aside from resolving `uuid` (`:231`) — the method does nothing.
  **Dead/no-op handler.** Possibly a stub for planned cleanup (e.g. of `couponMenu`,
  `:79`, a static `HashMap<UUID, Inventory>` that is declared but never written to or read
  anywhere in this file) that was never finished.
- **Feature allocation**: `property`.
- **Bugs/edge cases**: confirmed no-op — flagged as dead/incomplete code, not a functioning
  cleanup hook despite the suggestive name.

### `DamageFrame(EntityDamageByEntityEvent e)` — commented out, `v1:src/Properties/ItemFrameAdd.java:234-270`
- Dead code. Intent: cancel damage to item frames/armor stands inside `"property"` regions unless
  the damaging player is in owner-mode. Superseded/duplicated by the interact-based cancellation
  above; without this handler, players **can still break item frames and armor stands by damaging
  them** even though they can't "use" them via right-click — i.e. the live code only guards the
  interact path, not the damage/destroy path. This is a real functional gap versus the commented
  intent, though it's out of scope to say whether some *other* listener not in this slice covers
  frame/armor-stand damage protection.

### `InfoClick(InventoryClickEvent e)` — `v1:src/Properties/ItemFrameAdd.java:272-464`
- **Event type**: `InventoryClickEvent`, default `@EventHandler` — `:272`.
- **Trigger condition**: matches the clicked inventory's stripped title against either (a) a
  product's display name (`product.getIDList(true, null, false)` loop, `:296-360`) or (b) an
  `"Enchant item with <name>"` title built from every enchantment's name (`:361-463`). Both
  branches additionally require the clicking player to currently be standing inside a `"property"`
  region (`Worldguard.getStructureIDbyRegion("property", player.getLocation(), ...)`, `:295`) —
  note this re-checks the player's *current* location at click time, not the location at frame-open
  time, so walking out of the property while the menu is still open will close the menu with an
  error rather than let the purchase go through (`:354-358`, `:457-461`).
- **Goal/function — shop purchase branch** (`:296-360`): clicking a `Material.NAME_TAG` item
  computes price = unit price × amount (amount read back out of an item's display-name substring
  parsed as `Amount: N`, `:315`), checks for an applicable coupon
  (`menu.getItemCoupon(...)`, `:321`) and if none, checks the player's coins against price and the
  property's live stock (`propertyproduct.getAmount(relationID)`, `:328`) before firing a
  `PurchaseEvent` (`:332`, out of scope) to actually complete the transaction. Clicking a
  `Material.CHEST` item instead calls `setItemStep(...)` (`:351`, `:687-789`) to step the
  purchase-amount selector.
- **Goal/function — enchant-ritual branch** (`:361-463`): clicking `Material.NETHER_STAR` parses
  chance/price numbers back out of the item's lore text (`:392-448`, five hardcoded tiers: default,
  slightly/increased/extremely-increased, and "super extreme" chance) and, if the player can
  afford the selected tier, closes the inventory, plays the ritual animation
  (`playEnchantAnimation`, `:590-619`), and queues the actual enchant attempt
  (`addEnchantItem`, `:621-685`).
- **Feature allocation**: `property`.
- **Bugs/edge cases**:
  - `:315` parses `menu.getItem(3).getItemMeta().getDisplayName().split(": ")[1]` — if that item
    or its display name is ever malformed (missing `": "`), this throws an uncaught
    `ArrayIndexOutOfBoundsException`/`NPE` inside an event handler; no try/catch around this
    specific parse (unlike the `Users.getUser` lookups elsewhere in this file which are properly
    guarded).
  - `:379`: `enchantItem.get(uuid).containsEnchantment(enchantment)` — `enchantItem.get(uuid)` can
    be `null` if the player reaches this inventory click without having gone through `Add()`'s
    book-frame flow first (e.g. stale/reopened menu, or two players racing on a shared static map
    keyed only by uuid — safe per-player, but not re-entrant per session). Would throw an NPE.
  - All five lore-parsing branches (`:390-455`) are heavily copy-pasted with only the lore index
    and multiplier differing — no functional bug, but notably fragile: any change to the lore text
    format in the menu-builder (`openEnchantInfo`) would silently break price/chance parsing here
    without a compile-time link between the two.

### `openEnchantInfo(...)` — `v1:src/Properties/ItemFrameAdd.java:473-588`
- Not an event handler itself (called from `Add()`); builds the enchant-ritual purchase menu.
  Max success chance is derived from the property's "contribution" tier
  (`property.getContribution(propertyID)`, `:483`) via a switch over exactly the values 5/10/15/20/30
  (`:489-506`); any other contribution value leaves `maxsuccesChance` at its default of 100
  (`:485`) — i.e. an unrecognized contribution tier silently grants a **guaranteed** 100% success
  chance rather than failing safe. Prices for the five tiers are `price`, `price*1.1`, `price*1.3`,
  `price*1.5`, `price*1.8` (`:513-516`, computed as `price + price*0.1` etc.), which does line up
  with the lore text's "Price: N" values consumed by `InfoClick` above.

### `playEnchantAnimation` / `addEnchantItem` — `v1:src/Properties/ItemFrameAdd.java:590-685`
- Not event handlers; the actual ritual mechanics. `addEnchantItem` runs after a 40-tick delay
  (`:631`, `runTaskLater(main, 2*20)`) and re-checks `user.getCoins() >= price` at execution time
  (`:635`) even though the coins were already validated before scheduling — a reasonable
  re-validation against races, but note **coins are only deducted on success**
  (`user.removeCoins(price)`, `:659`, inside the success branch only) — a failed ritual roll
  (`:662-666`) costs the player **nothing**, which contradicts the "ritual" framing (you'd expect
  the attempt itself, successful or not, to cost the price) but matches what the code actually
  does; flagging this as a notable behavior difference from `EnchantmentGenerator`'s ritual (which
  *does* always charge regardless of outcome, `EnchantmentGenerator.java:96`/`:106`). Enchant level
  cap of 6 enforced (`item.getEnchantmentLevel(enchantment)+enchLevel) <= 6`, `:651`) — if already
  at/above the effective cap the enchantment is silently **not** applied even though coins were
  never charged in this path anyway (so no monetary loss, just a silent no-op).

---

## 7. `src/Properties/PropertyEvents.java`

### `onEnter(RegionEnterEvent e)` — `v1:src/Properties/PropertyEvents.java:35-65`
- **Event type**: `com.mewin.WGRegionEvents.events.RegionEnterEvent` — a third-party WorldGuard
  region-events plugin hook, not a stock Bukkit event — default `@EventHandler` — `:35`.
- **Trigger condition**: `Worldguard.isPropertyRegion(region)` (`:42`) and `e.isCancelled() == false`
  (`:52`).
- **Goal/function**: looks up the entering user (`Users2.FindUser(uuid)`, `:45`; returns early if
  `null`, `:47-50`) and, if they have an active `AssignmentEnterPropertySpecific` assignment,
  calls `Assignment.enterProperty(propertyID)` (`:56-61`) — progresses an assignment/quest step
  tied to visiting a specific property. Only the first matching assignment in the list is
  processed (`break` at `:60`).
- **Feature allocation**: `property`.
- **Bugs/edge cases**: none evident; straightforward assignment-progress hook. Note this is the
  only file in this slice that reacts to *entering* a property region generically (as opposed to
  clicking something inside one).

### `onLeave(RegionLeaveEvent e)` — `v1:src/Properties/PropertyEvents.java:67-71`
- **Event type**: `RegionLeaveEvent` (same third-party plugin), default `@EventHandler` — `:67`.
- **Goal/function**: empty body — registered but does nothing. Confirmed no-op, not a
  parsing/read error on my part; the method literally has no statements.
- **Feature allocation**: `property`.
- **Bugs/edge cases**: dead/no-op handler, symmetrical counterpart to `onEnter` never implemented.

---

## 8. `src/Properties/PropertySellEvent.java`

Whole file is dead code — see Section 1. Same shape as `HouseSellEvent.java`: only a commented-out
`Confirm(PlayerChatEvent e)` method (`v1:src/Properties/PropertySellEvent.java:23-71`); fields
`Property`, `Town`, `Street`, `WorldGuard` declared but unused. No live `@EventHandler`s.

---

## 9. `src/Properties/PropertyTouch.java`

### `PropertyTouch(PlayerInteractEvent e)` — `v1:src/Properties/PropertyTouch.java:46-166`
(method name shadows the class name — legal in Java but unusual style)
- **Event type**: `PlayerInteractEvent`, default `@EventHandler` — `:46`.
- **Trigger condition**: `Action.RIGHT_CLICK_BLOCK` (`:68`) on a block resolving to a `"property"`
  WorldGuard region (`:70`). Uses its own private `getWorldGuard()` helper (`:168-179`) — a third
  copy of the same plugin-lookup boilerplate seen in `HouseTouch.java` (not deduplicated anywhere
  in this slice).
- **Goal/function**:
  - Excludes several interactive block types from any of this logic entirely —
    `ENDER_PORTAL_FRAME`, `WOODEN_DOOR`, `ENCHANTMENT_TABLE`, `ANVIL` (`:78`) — so those are left
    for other listeners (e.g. `EnchantmentGenerator` handles the ender-portal-frame case).
  - **Chest protection**: if the clicked block is a chest and the player is not in owner-mode
    (`:80`), the interaction is cancelled **unless** the property's category is `"tavern"`
    (`:86-89`) — i.e. non-tavern property chests are always protected from non-owners, but tavern
    chests get special room-based handling: if the chest is also inside a `"room"` region and that
    room has an owner other than the clicking player, cancel; otherwise (no room owner, or the
    player is the room owner) allow access (`:95-111`). Debug logging throughout gated by
    `main.debug` (`:73-107`).
  - **Info card / owned-click throttle**: for any non-tavern property (`:114`), reproduces the
    exact same click-counter throttle pattern as `HouseTouch` (own static
    `HashMap<UUID, Integer> click`, `:44`; same 7-click cadence, `:121-138`) when the clicking
    player owns the property, else prints a property info card (name, price, income, category,
    owner/title/experience) with property ID shown only in owner-mode (`:140-161`).
  - Tavern properties **never** get the ownership-throttle/info-card treatment at all (`:114`
    excludes them from that whole block) — the only tavern-specific behavior in this method is the
    chest/room-ownership check above; right-clicking a non-chest block inside a tavern property
    does nothing beyond the exclusions at `:78`.
- **Feature allocation**: `property` (tavern/room ↔ property relationship, general property info).
- **Bugs/edge cases**:
  - Same click-map leak pattern as `HouseTouch` — `click` (`:44`) is static, keyed by uuid, never
    purged on logout.
  - `:78`'s material exclusion list omits `Material.CHEST` from the "skip entirely" set even
    though chest is handled separately right after — not a bug, just worth noting the ordering:
    chest-specific logic at `:80-113` runs *inside* the `if (material != ENDER_PORTAL_FRAME && ...)`
    guard, so it's still gated by that same exclusion list (harmless, since CHEST was never in the
    exclusion list to begin with).
  - No explicit cancellation of the interaction for the non-chest/non-excluded/non-tavern branch —
    matches `HouseTouch`'s behavior of leaving interaction cancellation at Bukkit's default
    (`false`), i.e. always allowed through unless explicitly cancelled by the chest-protection
    branch.

---

## 10. `src/Properties/SpawnShopkeepers.java`

Entire file is commented out apart from the constructor (`v1:src/Properties/SpawnShopkeepers.java:14-18`).
No live `@EventHandler`s exist. Dead-code intent (from the comments):
- `onEnter(EnterTownEvent e)` (`:20-47`) — would spawn shopkeeper NPCs for a town when players
  enter it, using a `DiscoverTown.playersinTown` map to decide whether the town already has active
  players.
- `onLeave(LeaveTownEvent e)` (`:49-98`) — would despawn shopkeeper NPCs for a town once it has no
  more active players, iterating `property.getIDList(null, townID)` and despawning each property's
  Citizens NPC (`registry.getById(npcID)`).
- `spawnShopKeepers(Integer townID)` (`:100-176`) — would create/re-spawn Citizens `NPC`s per
  property based on category (blacksmith for armory/weaponry/archery/warehouse, butcher for
  food/butchery, farmer for bakery/grocery, priest for witchery), require a configured spawnpoint,
  and mark the NPC `.setProtected(true)`.
- **Feature allocation**: `property` (would-be shopkeeper NPC lifecycle).
- **Bugs/edge cases**: N/A — none of it runs. This means, as far as this slice shows, **shopkeeper
  NPCs are never spawned or despawned by any live listener** in the property domain; whether NPCs
  are spawned through some other, non-event-driven mechanism (e.g. a scheduled task, a command, or
  code outside this slice) is unclear/out of scope here.

---

## 11. `src/Properties/StorageEvents.java`

### `onStorage(StorageEvent e)` — `v1:src/Properties/StorageEvents.java:27-51`
- **Event type**: `Handlers.StorageEvent` — a custom (non-Bukkit-stock) event, default
  `@EventHandler` — `:27`. Always logs `"Fired!"` to console unconditionally on every invocation
  (`:30`), which looks like leftover debug logging not gated behind `main.debug` (inconsistent with
  the `if (main.debug)` pattern used everywhere else in this slice).
- **Trigger condition**: whatever fires `StorageEvent` elsewhere (not in this slice — presumably a
  storage-capacity check on the property's internal item storage, based on the message text).
- **Goal/function**: looks up the property's owner (`property.getPropertyOwnerID(propertyID)`,
  `:32`) and, for every currently-online user in `Users2.users` whose ID matches the owner
  (`:37-49`), sends a multi-line notification that the property's storage is full and suggests
  transporting it to a warehouse via a "Personal Menu" assignment or the property's shopkeeper.
- **Feature allocation**: `property` (storage-full notification).
- **Bugs/edge cases**:
  - Iterates *all* online users doing a linear `ownerID == userID` comparison instead of directly
    resolving the owner's `User`/`Player` object — O(n) in online player count for something that
    could be a direct lookup; not a correctness bug, but inefficient, and if the owner isn't
    currently online, no notification is sent or queued (no offline-mail/log fallback visible in
    this method) — the owner simply never finds out their storage is full unless they happen to be
    online at the exact moment `StorageEvent` fires.
  - Unconditional `Bukkit.getConsoleSender().sendMessage("Fired!")` on every fire (`:30`) — spammy
    debug leftover, not gated by `main.debug` unlike every other debug print seen elsewhere in this
    slice.

---

## 12. `src/Resources/BlockBreakEvents.java`

### `onBreak(BlockBreakEvent e)` — `v1:src/Resources/BlockBreakEvents.java:70-238`
- **Event type**: `BlockBreakEvent`, `@EventHandler(priority = EventPriority.HIGHEST)` — `:70`.
- **Trigger condition**: multiple gates, in order:
  1. If the player has an active WorldEdit session and is holding a `WOOD_AXE`, the break is
     cancelled outright and the method returns immediately (`:81-85`) — looks like a
     WorldEdit-tool conflict guard (wooden axe is WorldEdit's default selection tool), unrelated to
     the resource-property mechanics below.
  2. **User resolution bug**: `if (Users2.ExistUser(uuid)) { user = Users2.InstantiateUser(uuid, false); return; }` (`:88-92`).
     This `return`s **immediately whenever the user exists**, before any of the resource-harvesting
     logic below ever runs. Combined with the very next check, `if (user == null) { e.setCancelled(true); return; }`
     (`:94-98`) — since `user` was just set to a non-null `User` in the branch above (when it
     *does* exist) but that branch already returned, this second check can only ever be reached
     when `Users2.ExistUser(uuid)` was `false`, in which case `user` is still `null` from its
     declaration (`:79`), so it always cancels and returns too. **The net effect: this method
     always returns before line 100 for every single player, in every case** — the entire
     resource-mining region/material logic below (`:100-238`) is unreachable dead code at runtime.
     This is a severe, confirmed logic bug: the `return` at `:91` should almost certainly not be
     there (it looks like it was meant to be inside an `else`/negated branch, i.e. "if user does
     NOT exist, instantiate them and continue", but as written it exits on the success case
     instead of the failure case).
  - Because of the bug above, everything from `:100` onward — the town/property WorldGuard region
    resolution, the resource-property membership check
    (`property.getResourcePropertyIDList(false, null).contains(propertyID)`, `:107`), the
    `ResourceBlockBreakEvent` firing (`:153`, `:164`), and the wilderness-mining branch
    (`townID == null && propertyID == null`, `:158-168`) — is dead in practice. It is documented
    below anyway per the task brief's "don't skip anything for being minor" instruction, since it
    still describes the intended design and the yield logic it would trigger.
  - **Intended design (per the unreachable code)**: normal-mode players (`user.inOwnerModus() ==
    false && user.inStaffModus() == false && player.getGameMode() == GameMode.SURVIVAL`, `:104`)
    breaking blocks inside a resource-property's mining area, or in true wilderness (no town, no
    property), would have the vanilla break always cancelled (`e.setCancelled(true)`, `:150`/`:161`)
    and a custom `ResourceBlockBreakEvent` fired instead (`:153`, `:164`) — i.e. resource yield is
    entirely computed by that custom event's own constructor logic (see Section 13 /
    `Handlers/ResourceBlockBreakEvent.java`), not by this listener. Breaking inside a town but
    outside a resource-property is always cancelled with no event fired (`:219-229`, the `else`
    covering "region exists but isn't a qualifying resource-property"). Owner-mode/staff-mode
    players, or anyone not in survival, instead get a simple "can't break blocks while in
    ownermode or staffmode" message only if not in creative (`:230-237`) — note the message text
    says "ownermode or staffmode" even when the actual disqualifying condition could be gamemode,
    slightly misleading wording.
  - A large second `@EventHandler`, `onDrop(ItemSpawnEvent e)` (`:240-352`), is entirely
    commented out — its intent was to intercept vanilla block drops (cobblestone, coal, iron/gold
    ore, diamond, log, wheat) at a remembered `loc` and swap them for custom `product`-backed
    items, cancelling anything that doesn't match a known type. This has been fully superseded by
    `ResourceBlockBreakEvent`'s constructor-driven drop calculation (Section 13), which is a much
    more direct mechanism (compute-and-drop-immediately vs. cancel-vanilla-break-then-intercept-the-
    resulting-drop-event).
- **Feature allocation**: `property` (resource-property mining gate).
- **Bugs/edge cases**: the severe unreachable-code bug at `:88-98` is the headline finding for this
  file — as written, **no player can ever mine anything through this listener's intended path**;
  every break event handled here falls through to one of the two early returns before reaching the
  resource logic. Whether some other listener (outside this slice) independently handles block
  breaking is unclear/out of scope, but nothing in this file itself reaches the resource-property
  mining logic. Secondary: the WorldEdit/wooden-axe guard (`:81-85`) runs before user resolution,
  so it applies even to unregistered/non-existent users, which is presumably fine since it's a
  builder-tool conflict check unrelated to game economy.

---

## 13. `src/Handlers/ResourceBlockBreakEvent.java` (not in the assigned list, read for cross-reference)

Included because `BlockBreakEvents.java` fires this custom event and — per the task's "cite
resource-harvesting yield formulas" instruction — the actual yield formula lives here, not in
`BlockBreakEvents`. This is a `KaKEvent` subclass (custom Bukkit `Event` + `Cancellable`), not a
`Listener`; there is no separate `@EventHandler` anywhere in this slice that listens for it — **all
of its behavior runs synchronously inside its own constructor** (`calculateDropItem()`, called from
the constructor at `v1:src/Handlers/ResourceBlockBreakEvent.java:52`), which is an unusual pattern:
it's structured as a Bukkit `Event` (presumably so other, unrelated listeners elsewhere in the
codebase *could* react to it being fired/cancelled) but its primary effects happen unconditionally
as a side-effect of construction, not through the Bukkit event-dispatch/listener mechanism.

- **Yield/product resolution** (`:61-136`): maps broken `Material` to a product name — wheat
  (block ID 59) → `"wheat"`; `STONE` → `"cobblestone"`, or `"stone"` if the tool has Silk Touch
  (`:75-78`); `COAL_ORE` → `"coal"`, or `"coalore"` with Silk Touch (`:80-88`); `IRON_ORE` →
  `"ironore"`; `GOLD_ORE` → `"goldore"`; `REDSTONE_ORE` → `"redstone"`; `DIAMOND_ORE` →
  `"diamond"`; `EMERALD_ORE` → `"emerald"`; `LOG` → `"oakwood"`/`"sprucewood"`/`"birchwood"`/
  `"junglewood"` by data value (`:109-124`); `LOG_2` → `"acaciawood"`/`"darkoakwood"` by data value
  (`:125-135`). Any other material leaves `productName` null, so `product.getProductID(null, false)`
  returns null and the event self-cancels with a console error (`:138-144`) — a fail-safe, not a
  crash, but note the player-facing message at `:142` is itself commented out, so the player gets
  **no feedback at all** when this happens, only a console log.
- **Region-type re-validation** (`:150-170`): ore/stone materials (`requiresCustomCooldown == true`)
  additionally require the property's resource category to be exactly one of `stonequarry`,
  `coalmine`, `ironmine`, `goldmine`, `gemmine` (`:153-157`); if not, self-cancels silently
  (console-debug only). This means a resource-property of e.g. category `"lumbermill"` cannot yield
  stone/ore even if the block happens to be inside its bounds, and vice versa.
- **Yield amount formula** (`getCalculatedAmount`, `:224-305`): base amount from
  `product.getBaseDropAmount(productID)` (`:231`, out of scope — defined elsewhere), then, if the
  tool has `Enchantment.LOOT_BONUS_BLOCKS` (Fortune), a level-dependent random multiplier is
  applied: Fortune I gives a 33% chance to double; Fortune II gives 25%/25% chance of ×3/×2;
  Fortune III gives 20%/20%/20% chance of ×4/×3/×2; Fortune IV gives 20% each of ×5/×4/×3/×2; any
  level **above** 4 collapses to the same table as Fortune IV's first three tiers plus a flat ×2
  for the remaining 40% (`:267-297`) — i.e. Fortune V+ is not weighted any better than a capped
  Fortune-IV-like table, a design choice (vanilla Fortune caps at III normally; this plugin
  apparently supports enchanting higher, but the payoff curve stops scaling past level 4).
- **Assignment/quest hooks** (`:307-338`): after computing drops, checks the harvesting player's
  active assignments for `AssignmentHarvestRandom` and calls `.Harvest(drop)` per dropped item
  (`:307-321`), and separately checks active quests for `QuestHarvestResource` and calls
  `.Harvest(drop)` per item too (`:323-338`) — both scoped to the first matching assignment/quest
  only (`break` after match).
- **Regeneration/cooldown** (`handleRegeneration`, `:196-222`): ore/stone blocks
  (`isCustom == true`) get a per-block file-persisted cooldown via
  `file.saveBlock("ore-resources", ..., this.property.getCooldown(propertyID))` (`:208`) — i.e.
  the regrowth delay is configurable per resource-property. Non-custom blocks (wheat, wood) instead
  get pushed onto `BlockBreakEvents.refreshList` with a flat, hardcoded 25-second cooldown
  (`Integer cooldown = 25`, `:42`, used at `:215`) — this cooldown is **not** configurable per
  property unlike the ore/stone path, an inconsistency between the two resource types. In both
  cases the block is immediately set to `Material.AIR` (`:217`).
- **Bugs/edge cases**: (1) the silent-fail path at `:138-144` gives the player zero in-game
  feedback (commented-out message) when their break yields no recognized product — from the
  player's perspective the block would presumably already be cancelled upstream in
  `BlockBreakEvents` (itself unreachable per Section 12's finding, compounding the practical
  dead-ness of this whole pipeline); (2) the wood-vs-ore cooldown inconsistency noted above; (3)
  `getCalculatedAmount`'s Fortune table for `level > 4` effectively reuses the four `level == 4`
  probability tiers but replaces the `else` (originally reachable at 20% for ×2 under Fortune IV)
  with the full remaining 40% mapped to ×2 — internally consistent, just worth noting the curve
  doesn't reward Fortune levels above IV any further, unlike vanilla progression expectations.

---

## 14. `src/Resources/ResourceKillEvents.java`

### `onKill(EntityDeathEvent e)` — `v1:src/Resources/ResourceKillEvents.java:34-165`
- **Event type**: `EntityDeathEvent`, default `@EventHandler` — `:34`.
- **Trigger condition**: fires for every entity death; the killer-resolution and assignment-lookup
  logic is scoped inside `if (e.getEntity().getKiller() instanceof Player)` (`:44-62`), but note
  the subsequent drop-remapping loop (`:74-161`) runs **unconditionally for every entity death**,
  player-killed or not (e.g. mob-on-mob kills, environmental deaths) — only the assignment-progress
  side effect is player-gated.
- **Goal/function**: remaps vanilla mob drops to custom `Product`-backed items by exact material
  match: `RAW_CHICKEN`→`rawchicken`, `COOKED_CHICKEN`→`cookedchicken`, `PORK`→`rawporkchop`,
  `GRILLED_PORK`→`cookedporkchop`, `RAW_BEEF`→`rawbeef`, `COOKED_BEEF`→`steak`,
  `MUTTON`→`rawmutton`, `COOKED_MUTTON`→`cookedmutton`, `RABBIT`→`rawrabbit`,
  `COOKED_RABBIT`→`cookedrabbit` (`:76-146`). Gold/diamond drops (`GOLD_NUGGET`, `GOLD_INGOT`,
  `GOLD_BLOCK`, `DIAMOND`, `DIAMOND_BLOCK`) are passed through unmodified (`:146-148`). Any drop
  that already has a matching custom product by display name is also passed through unmodified
  (`:152-155`). Everything else (leather, feathers, string, bones, rotten flesh, etc. — anything
  not explicitly listed) is **silently dropped from the final drop list** because `newDrops` only
  ever receives explicitly-matched items and `e.getDrops()` is fully replaced with `newDrops` at
  the end (`:162-163`) — i.e. this listener strips out all "ordinary" vanilla mob loot that isn't
  on its allowlist, which is presumably intentional (custom economy replacing vanilla drops) but
  worth flagging as a broad, silent behavior.
- **Assignment hook**: if the killer resolves to a user with an active `AssignmentHarvestRandom`
  assignment, `.Harvest(drop)` is called once per **original** drop (not per remapped drop) inside
  the same loop (`:156-160`) — note this passes the *pre-remap* `drop` object, not the
  possibly-substituted custom item, to `Harvest`, which may matter if `Harvest` inspects item type.
- **Feature allocation**: `property` (per task's blanket allocation — though this listener is
  arguably closer to a general "resources" mechanic decoupled from property regions; there is
  **no WorldGuard/region check anywhere in this method** — it fires identically whether the kill
  happened inside a resource-property, inside a town, or in the wilderness, unlike
  `BlockBreakEvents`' region-gated mining logic). This asymmetry (mining is region-gated,
  mob-drop harvesting is not) is worth flagging explicitly since the task described this as a
  "resource-property" mechanic but the code shows animal/mob harvesting is global.
- **Bugs/edge cases**:
  - Dead branch: `else if (drop.getType() == Material.GOLD_INGOT)` at `:149-151` is unreachable —
    `GOLD_INGOT` is already matched by the combined condition two branches above (`:146`,
    `... || drop.getType() == Material.GOLD_INGOT || ...`), so this empty `else if` can never be
    entered. Harmless (empty body) but dead code.
  - No `user == null` guard before the `for (Assignment assignment : user.getAssignmentList())`
    loop at `:65` is fine because it's wrapped in `if (user != null)` (`:63-73`) — but note `user`
    is only ever assigned inside the `killer instanceof Player` branch (`:44-61`), and if the
    `Users.getUser(uuid)` lookup throws `UserNotFoundException`/other exception, the method
    `return`s immediately (`:54`, `:59`) — meaning for an unrecognized player-killer, the entire
    drop-remapping loop below (`:74-161`) is also skipped, not just the assignment hook. So a
    player killer with no resolvable `User` record gets **zero custom drops** from that kill (the
    original vanilla drops are also lost, since the method returns before `e.getDrops().clear()`
    is reached) — items simply vanish in that edge case. This is a genuine edge-case data loss bug,
    though it should be rare in practice (every real player should have a `User` record).

---

## 15. `src/Rooms/RoomSellEvent.java`

Whole file is dead code — see Section 1. Same shape as the other two sell-event shells: only a
commented-out `Confirm(PlayerChatEvent e)` method (`v1:src/Rooms/RoomSellEvent.java:25-70`); fields
`Room`, `Town`, `Property`, `Street`, `WorldGuard` declared but unused. No live `@EventHandler`s.

---

## Summary count

| File | Live `@EventHandler`s | Dead/commented `@EventHandler`s |
|---|---|---|
| `Houses/HouseSellEvent.java` | 0 | 1 |
| `Houses/HouseTouch.java` | 1 | 0 |
| `Properties/EnchantmentGenerator.java` | 1 | 0 |
| `Properties/HomelessEnter.java` | 0 | 2 |
| `Properties/ItemFrameAdd.java` | 4 (1 effectively no-op) | 1 |
| `Properties/PropertyEvents.java` | 2 (1 effectively no-op) | 0 |
| `Properties/PropertySellEvent.java` | 0 | 1 |
| `Properties/PropertyTouch.java` | 1 | 0 |
| `Properties/SpawnShopkeepers.java` | 0 | 2 |
| `Properties/StorageEvents.java` | 1 | 0 |
| `Resources/BlockBreakEvents.java` | 1 (unreachable past its own early-return bug) | 1 |
| `Resources/ResourceKillEvents.java` | 1 | 0 |
| `Rooms/RoomSellEvent.java` | 0 | 1 |
| **Cross-referenced (not assigned):** `Listeners/PlayerListener.java` | 3 relevant blocks inside `onChat` (house/property/room sell confirm) | — |
| **Cross-referenced (not assigned):** `Handlers/ResourceBlockBreakEvent.java` | 0 (not a `Listener`; logic runs in constructor) | — |

**Totals across the 13 assigned files**: 12 live `@EventHandler` methods, 9 dead/commented-out
`@EventHandler` methods. Three of the twelve "live" handlers are functionally inert at runtime for
reasons documented above (`ItemFrameAdd.menuClose`, `PropertyEvents.onLeave` — both true no-ops;
`BlockBreakEvents.onBreak` — reachable but its core logic is unreachable due to the early-return
bug at line 91). The three sell-confirmation flows described as "commented out" in this slice are
fully live and working, just relocated wholesale into `PlayerListener.onChat`.
# v1 event-listener catalog — Towns/Gates + Social + World-admin/misc

Mined from `knk-v1-archive` (single-commit Bukkit import, no ORM — see
`docs/specs/legacy/user-system.md` for the data-model side and citation
conventions this doc follows: `v1:src/Path/File.java:line`). Companion to
`docs/specs/legacy/commands-v1.md` (the Minecraft-command catalog); this doc
covers the same codebase's `@EventHandler`-annotated Bukkit event listeners
for one slice of the domain.

## Methodology

Full read of 13 files under `knk-v1-archive/src`: `Gates/GateEvents.java`,
`Towns/TownEvents.java`, `Friends/FriendInteract.java`,
`Friends/HitFriendEvent.java`, `Friends/MentionNameEvent.java`,
`Friends/UpdateFriendRegions.java`, `Broadcasts/BossBarEvents.java`,
`Handlers/WeatherChange.java`, `Teleport/TeleportDelay.java`,
`Teleport/TeleportMovement.java`, `Tutorial/TutorialEvents.java`,
`Listeners/EntityListener.java`, `Listeners/InventoryListener.java`.
Each `@EventHandler` method is documented individually with its own domain
call, per the task brief, rather than treating a file as one unit — this
matters most for `EntityListener`/`InventoryListener`/`TutorialEvents`,
which are catch-all classes bundling unrelated concerns. A large fraction of
the methods in this slice are **commented-out** (`//@EventHandler`) —
documented anyway since dead/abandoned listeners are useful signal for v3
design, exactly as `commands-v1.md`'s dead-code call notes state. Verbatim-
only: no invented behavior; anything not resolvable by reading the given
files is marked "unclear/out of scope." Feature-domain categories are the
ones from `commands-v1.md`: `towns`, `social`, `world-admin`, `misc`,
`inventory-menus`.

---

## Cross-file observations (read before the per-file sections)

- **A striking fraction of this slice is dead/disabled code.** Of the ~20
  `@EventHandler`-shaped methods found across these 13 files, only **9** are
  live (uncommented) handlers actually registered with Bukkit; the rest are
  commented out in-place, left as historical artifacts rather than deleted.
  `Friends/HitFriendEvent.java`, `Friends/MentionNameEvent.java`, and
  `Broadcasts/BossBarEvents.java` are **entirely** dead — every method in
  each of those three files is commented out, meaning friendly-fire
  prevention, @mention chat highlighting, and boss-bar HUD updates **do not
  function at all** in this build despite the classes/infrastructure
  existing and being wired into `Main` (unclear/out of scope whether `Main`
  still registers these no-op listeners — not read as part of this slice).
- **Teleport-cancel-on-move/damage is also fully dead**:
  `Teleport/TeleportMovement.java` has both its handlers commented out, so
  `TeleportDelay.cancelTeleport(uuid, true/false)` — a fully-implemented
  method with player feedback messages for both the movement and
  damage-interrupt cases — is **never invoked** by any live listener found
  in this slice. The teleport-delay countdown itself
  (`TeleportDelay.updateDelay()`) is a plain method, not an event handler;
  it is presumably ticked by a scheduler registered elsewhere (out of scope
  for this doc, not found in the 13 files read).
- **`Friends/UpdateFriendRegions.java` has a live but broken `onRemove`
  handler** — see the file section below; `targetID`/`userID` are declared
  but never assigned, so the region-membership-removal logic can never fire
  its intended branches (v1:src/Friends/UpdateFriendRegions.java:77-78).
- **`Tutorial/TutorialEvents.java`'s `onClick` method is not a Bukkit event
  handler** despite living in a `Listener` class alongside real
  `@EventHandler` methods — it has no `@EventHandler` annotation
  (v1:src/Tutorial/TutorialEvents.java:82) and is manually invoked from
  `Menu/MenuClick.java` (confirmed via repo-wide grep for `.onClick(`,
  files: `Tutorial/TutorialEvents.java`, `Menu/MenuClick.java`,
  `Main/Main.java` — the latter two outside this slice's read scope, so the
  exact call-site context is unclear/out of scope). Documented below anyway
  for completeness since it's tutorial-domain click-handling logic, but
  flagged as not a true listener.
- **`Towns/TownEvents.inTown`** is a `public static HashMap<User, Integer>`
  (v1:src/Towns/TownEvents.java:51) keyed directly on the mutable `User`
  object rather than a UUID — correctness depends entirely on `User`'s
  `equals()`/`hashCode()` implementation, which is outside this slice's read
  scope; flagged as unclear/out of scope but worth noting as a footgun
  pattern (same map is read from the commented-out `GateEvents.onGateMove`,
  showing it was intended to drive gate-activation-by-town-occupancy logic
  that was never finished/enabled).
- **Custom event types cross domains**: `TownEvents.onEnter`/`onLeave` fire
  the plugin's own `EnterTownEvent`/`LeaveTownEvent`
  (v1:src/Towns/TownEvents.java:124,190), and `UpdateFriendRegions`
  listens for the plugin's own `AddFriendEvent`/`RemoveFriendEvent`
  (v1:src/Friends/UpdateFriendRegions.java:37,71) — these are custom Bukkit
  events raised elsewhere (likely `Friends`/social commands, out of scope)
  rather than vanilla Bukkit events, so "trigger condition" for those two
  handlers is "whenever some other part of the plugin explicitly calls
  `callEvent(...)` with that custom type," not a raw player action.

---

## 1. `src/Gates/GateEvents.java` — domain: towns

### `onGateHit(BlockDamageEvent e)` — live
- **Event**: `BlockDamageEvent`, default priority, no `ignoreCancelled`
  (v1:src/Gates/GateEvents.java:39-40).
- **Trigger**: any block-damage action. Resolves a gate ID from the
  damaged block's location via
  `Worldguard.getStructureIDbyRegion("gate", blockLocation, ...)`
  (v1:src/Gates/GateEvents.java:45) — i.e., only fires meaningfully when the
  damaged block sits inside a WorldGuard region tagged as a `gate`
  structure. Also requires the damaging player to resolve to a `User` via
  `Users2.InstantiateUser` (v1:src/Gates/GateEvents.java:48); if not found,
  sends an error and returns (line 50-54). If `gateID` is null (block not
  in a gate region) or `Gates.findGate(gateID)` returns null (stale/missing
  gate record), silently returns (lines 56-66).
- **Goal**: calls `gate.damageGate(user)` (v1:src/Gates/GateEvents.java:68)
  — the actual damage-accumulation/gate-break logic lives in
  `Models.Structures.Gate`, outside this slice's read scope
  (unclear/out of scope for exact behavior, e.g. whether it breaks the gate
  block or is purely a counter).
- **Bugs/edge cases**: none observed in this method itself; note the
  user-not-found check happens *before* the gate-region check, so a
  non-gate block-damage event still pays the cost of a `User` lookup for
  every player on every block damage in the world (minor inefficiency, not
  a correctness bug) (v1:src/Gates/GateEvents.java:42-59).

### `onGateMove(PlayerMoveEvent e)` — commented out / dead
(v1:src/Gates/GateEvents.java:71-124). Would have driven gate
activation-state (`gate.toggleActive(...)`) based on whether any player is
within `Gates.activeRange` of a gate entity belonging to the town the
moving player is currently recorded as being "in" (via
`TownEvents.inTown`). Never enabled — no live equivalent found elsewhere in
this slice.

### `onGateTouch(PlayerInteractEvent e)` — live
- **Event**: `PlayerInteractEvent`, default priority
  (v1:src/Gates/GateEvents.java:126-127).
- **Trigger**: resolves the interacting player's `User` via
  `Users.getUser` (catching `UserNotFoundException`/`UserIsNpcException`/
  generic `Exception`, each with its own early-return —
  v1:src/Gates/GateEvents.java:134-149). Requires a non-null, non-AIR
  clicked block and `Action.RIGHT_CLICK_BLOCK`
  (v1:src/Gates/GateEvents.java:151-154). Then requires the player to have
  an **active gate-toggle request** pending: `Gates.findGateToggle(user) !=
  null` (v1:src/Gates/GateEvents.java:156) — the mechanism that creates a
  `GateToggle` request is not in this slice's read scope (likely a `/gate
  toggle` command flow — unclear/out of scope), so this handler is the
  *second half* of a two-step "start toggle, then right-click the gate
  block" flow.
- **Goal**: resets the pending toggle's timeout to +4s
  (v1:src/Gates/GateEvents.java:159), resolves the gate at the clicked
  block's location via the same `Worldguard.getStructureIDbyRegion("gate",
  ...)` lookup as `onGateHit`, and if found: cancels the toggle's own
  timeout task, calls `gate.toggleClosed()` (open/close state flip), sends
  a success message, and — if the toggle was configured for passthrough —
  starts a passthrough task (`toggle.startPassthroughTask()`,
  v1:src/Gates/GateEvents.java:173-176) which presumably lets the player
  walk through the (previously-solid) gate briefly. Both the "gate not
  found by ID" and "gateID itself null" paths send the same
  "Error while finding the gate of the clicked block!" message
  (v1:src/Gates/GateEvents.java:179,183).
- **Bugs/edge cases**: none observed beyond the two error paths being
  functionally identical (harmless duplication, not a bug).

---

## 2. `src/Towns/TownEvents.java` — domain: towns

### `onEnter(RegionEnterEvent e)` — live
- **Event**: `com.mewin.WGRegionEvents.events.RegionEnterEvent` (a
  WorldGuard-region-events-plugin event, not vanilla Bukkit), default
  priority (v1:src/Towns/TownEvents.java:53-54).
- **Trigger**: only proceeds if `Worldguard.isTownRegion(region)` is true
  (v1:src/Towns/TownEvents.java:60) — the entered WorldGuard region must be
  tagged as a town region. Resolves the town ID and its
  `requiredTitleID` (v1:src/Towns/TownEvents.java:62-63). Returns early if
  the player has no `Users.findUser(uuid)` record
  (v1:src/Towns/TownEvents.java:66-69), or on `User` instantiation failure
  (lines 70-85, correctly gated with returns in each catch branch).
- **Goal (title-gate sub-branch)**: only re-processes entry logic if the
  player isn't already recorded as being in this same town
  (`!inTown.containsKey(user) || inTown.get(user) != townID`,
  v1:src/Towns/TownEvents.java:87). If `main.leveledTownEnter` is enabled
  and the player's `titleID` is below the town's `requiredTitleID`, sends a
  rejection message and **cancels the region-enter event**
  (v1:src/Towns/TownEvents.java:89-96) — this is the town-entry gate
  (level-locked towns).
- **Goal (successful-entry sub-branch, `e.isCancelled() == false`,
  v1:src/Towns/TownEvents.java:99-126)**:
  - `DataManager.Structures.Gates.instantiateAll(townID)` — (re)instantiates
    the town's gates (line 101).
  - Sends an action-bar greeting ("Entering the town of ...") and plays a
    door-open sound (v1:src/Towns/TownEvents.java:104-106).
  - Records `inTown.put(user, townID)` (line 107).
  - **First-discovery reward**: if the town isn't already in the user's
    discovered-town list (`town.getUserIDListbyTown(townID).contains(...)`
    is false, line 109), saves the discovery, and grants randomized
    experience/coins/gems (lines 110-121) with a chat message and a
    level-up sound. Amounts are `main.getRandom(...)` scaled by
    `user.getMultipliedInt(...)` (donator/rank multiplier, presumably —
    exact multiplier logic out of scope).
  - Fires the plugin's own `EnterTownEvent(user, townID)`
    (v1:src/Towns/TownEvents.java:124).
- **Goal (unconditional-if-not-cancelled sub-branch,
  v1:src/Towns/TownEvents.java:127-152)**: runs **every** time the player
  enters a town region uncancelled, even if they were already recorded as
  in this town (this block is outside the `!inTown.containsKey` guard) —
  advances any `AssignmentTravelRandom`/`AssignmentTravelSpecific`
  quest-assignments the player holds by calling `.enterTown(townID)` on
  each (lines 129-140), and — if the player has active `BanditSpawn`
  NPCs tracked against their UUID — deregisters all of them from the
  Citizens NPC registry and clears the tracking entry
  (v1:src/Towns/TownEvents.java:142-151). This looks like a
  "entering a town scares off/removes your bandit chase" mechanic.
- **Bugs/edge cases**: the level-gate cancellation happens *before* the
  `Worldguard.getStructureIDbyRegion` result is checked for null anywhere
  — `townID`/`requiredTitleID` are used directly without a null-check
  (v1:src/Towns/TownEvents.java:62-63,91) — if `getStructureIDbyRegion`
  ever returns null for a region that `isTownRegion` accepted, `town
  .getRequiredTitleID(null)` and `user.getTitleID() < requiredTitleID`
  would NPE on unboxing; unclear/out of scope whether `isTownRegion` and
  `getStructureIDbyRegion` are guaranteed consistent (not read in this
  slice). Also note: the assignment-advance and bandit-cleanup block
  (lines 127-152) re-executes on every single re-entry check that isn't
  cancelled, not just first entry — likely intentional (re-arm quest
  progress each visit) but is a source of repeated side effects worth
  flagging as behavior-not-obviously-"once per town".

### `onLeave(RegionLeftEvent e)` — live
- **Event**: `com.mewin.WGRegionEvents.events.RegionLeftEvent`, default
  priority (v1:src/Towns/TownEvents.java:156-157).
- **Trigger**: `Worldguard.isTownRegion(region)` must be true
  (v1:src/Towns/TownEvents.java:163). Resolves `User` via `Users.getUser`
  (catches `UserNotFoundException`/generic `Exception`, each early-return
  correctly gated — note: unlike `onEnter`, this method does **not** catch
  `UserIsNpcException` separately, so an NPC leaving a town region would hit
  the generic `Exception` catch instead if `Users.getUser` throws that
  subtype — behaviorally similar outcome (error handler + return) but
  worth noting the inconsistency vs. `onEnter`'s three-way catch,
  v1:src/Towns/TownEvents.java:168-180). Only proceeds if `inTown
  .containsKey(user)` (line 182).
- **Goal**: re-checks the player's **current** location isn't still inside
  *any* town region (`Worldguard.getStructureIDbyRegion("town", player
  .getLocation(), regionmanager) == null`, v1:src/Towns/TownEvents.java:185)
  — guards against a leave-event firing while straddling two overlapping
  town regions. If confirmed clear of all towns: sends a "Leaving the town
  of ..." action-bar message, plays a door-close sound, fires the plugin's
  own `LeaveTownEvent(user, inTown.get(user))`, and removes the player from
  `inTown` (v1:src/Towns/TownEvents.java:187-192).
- **Bugs/edge cases**: none additional beyond the catch-inconsistency noted
  above.

### `onDamage(EntityDamageByEntityEvent e)` — commented out / dead
(v1:src/Towns/TownEvents.java:197-245). Would have been a PvP-prevention
rule: cancels damage to a `Player` entity whenever the entity's location
resolves to a `town` structure region that is **not** the "wilderness" town
(i.e., blanket PvP-block inside all named towns, exempting the wilderness
default), unless the location is also an "arena battleground" region (in
which case PvP is allowed to proceed). Never enabled; no live equivalent
found in this slice, so **town-region PvP is currently unrestricted by this
class** (any town-based PvP protection, if it exists at all in this build,
must come from elsewhere — out of scope).

---

## 3. `src/Friends/FriendInteract.java` — domain: social

### `onInteract(PlayerInteractEvent e)` — live
- **Event**: `PlayerInteractEvent`, default priority
  (v1:src/Friends/FriendInteract.java:38-39).
- **Trigger**: entire body wrapped in a blanket `try/catch (Exception)`
  that just prints the stack trace and swallows it
  (v1:src/Friends/FriendInteract.java:43-67) — any unexpected exception
  (e.g. NPE from `block.getLocation()` if `getClickedBlock()` is null on a
  non-block interact) is silently absorbed with no player feedback. Only
  proceeds if `Users.existUser(player.getName())` is true
  (v1:src/Friends/FriendInteract.java:45) and the action is
  `Action.RIGHT_CLICK_BLOCK` (line 48). Resolves the clicked block's
  location to a house structure ID via
  `Worldguard.getStructureIDbyRegion("house", ...)`
  (v1:src/Friends/FriendInteract.java:53), and requires that ID to also
  appear in `house.getHouseIDList(null)` (line 54) — a belt-and-suspenders
  double-check that the region ID really corresponds to a tracked house.
- **Goal**: this is a **house access-control gate dressed as a "friend"
  file** — not literally about the Friends system's data, but about who is
  allowed to interact with blocks inside someone else's house. If the house
  has a real owner (`ownerID != null && ownerID != 0`), the owner isn't the
  interacting player, and the player isn't in "owner mode"
  (`!user.inOwnerModus()`), the interaction is **cancelled**
  (v1:src/Friends/FriendInteract.java:57-60) — i.e., non-owners (which
  presumably includes non-friends; the actual friend-list check is not
  present in this method — see bug note) can't right-click blocks
  (chests, doors, buttons, etc.) inside a house they don't own.
- **Bugs/edge cases**: **despite living in `Friends/` and the class being
  named `FriendInteract`, this method never actually checks the house
  owner's friend list** — it blocks *all* non-owners uniformly, with no
  carve-out for friends of the owner (v1:src/Friends/FriendInteract.java:56-
  60, no reference to `getFriendList()` anywhere in the file). Either the
  "friends can interact with each other's houses" feature was never wired
  into this handler, or friend-based house access is granted through a
  different mechanism (e.g. WorldGuard region membership, populated by
  `UpdateFriendRegions` below) rather than this explicit check — plausible
  given `UpdateFriendRegions` adds friends as WorldGuard region *members*
  for houses, which could independently allow the interaction at the
  WorldGuard layer even though this handler's own Java-level check doesn't
  special-case friends. Flagging as unclear/out of scope which mechanism is
  authoritative without reading `Houses/House.java` and the WorldGuard
  interaction-flag configuration.

---

## 4. `src/Friends/HitFriendEvent.java` — domain: social — entirely dead

### `FriendHit(EntityDamageByEntityEvent e1)` — commented out / dead
(v1:src/Friends/HitFriendEvent.java:28-89). The **only** method in the
file, and it's fully commented out — the whole class exists solely to hold
this disabled handler. Would have been genuine friendly-fire prevention:
if a `Player` damages another `Player` who has the damager on their friend
list (`userDamaged.getFriendList().contains(damager.getUniqueId())`) and
the damager is **not** inside an "arena" WorldGuard region
(`Worldguard.getStructureIDbyRegion("arena", ...) == null`), the damage
event is cancelled and a "note bass" sound plays (v1:src/Friends/
HitFriendEvent.java:47-51). A parallel branch handles arrow damage,
resolving the shooter as the "damager" for the same friend-list check
(lines 58-79). **Not enabled** — no live equivalent found anywhere in this
slice, so friendly-fire between friends is currently unprevented by this
class (superseded, if at all, by `EntityListener.onHit`'s separate
`inSafeZone() || ... || userDamaged.getFriendList().contains(...)`
safezone/friend damage-cancel check — see file 12 below, which *does* have
a live friend-list PvP check, making this dead class's logic effectively
redundant/superseded rather than a pure gap).

---

## 5. `src/Friends/MentionNameEvent.java` — domain: social — entirely dead

### `Mention(PlayerChatEvent e)` — commented out / dead
(v1:src/Friends/MentionNameEvent.java:19-48). The only method, fully
disabled. Would have scanned each chat message (lowercased) for any online
player's name appearing as a substring, excluding the sender's own name,
and played a "note pling" sound to the mentioned player — with a debounce
mechanism via the static `click` map: the first mention plays a sound
immediately, then further mentions accumulate a per-target counter and only
play a sound again once that counter reaches exactly 3 (then resets)
(v1:src/Friends/MentionNameEvent.java:30-44) — i.e., a rate-limited
"someone said your name" chat-highlight/ping feature. **Not enabled** — the
static `click` map (v1:src/Friends/MentionNameEvent.java:17) is otherwise
unused within this file since its only consumer is the commented-out
method; @mention chat highlighting does not currently function.

---

## 6. `src/Friends/UpdateFriendRegions.java` — domain: social

### `onAdd(AddFriendEvent e)` — live
- **Event**: custom plugin event `Handlers.AddFriendEvent`
  (v1:src/Friends/UpdateFriendRegions.java:36-37) — fired elsewhere when a
  friend request is accepted (out of scope for this slice).
- **Trigger**: fires whenever `AddFriendEvent` is raised; no additional
  gating inside the handler itself.
- **Goal**: for every house the querying user owns (loops all house IDs via
  `house.getHouseIDList(null)`, resolving each house's WorldGuard region as
  `"house_" + houseID`), if the **new friend relationship's initiator**
  (`userID`) owns the house, adds the **target** friend's UUID as a
  WorldGuard region member; symmetrically, if the **target** (`targetID`)
  owns the house, adds the **initiator's** UUID as a member
  (v1:src/Friends/UpdateFriendRegions.java:49-67). Net effect: becoming
  friends with someone grants them WorldGuard region-member access to each
  other's houses — this is very plausibly the actual mechanism that backs
  the "friends can interact inside each other's houses" behavior that
  `FriendInteract.onInteract` (file 3 above) doesn't implement at the Java
  level.
- **Bugs/edge cases**: `userID`/`targetID` are correctly assigned here
  (`user.getID()` / `Users.fetchIDbyUUID(targetUUID)`,
  v1:src/Friends/UpdateFriendRegions.java:46-47) — this handler is correct;
  contrast with `onRemove` below.

### `onRemove(RemoveFriendEvent e)` — live, **buggy**
- **Event**: custom plugin event `Handlers.RemoveFriendEvent`
  (v1:src/Friends/UpdateFriendRegions.java:70-71).
- **Trigger**: fires whenever `RemoveFriendEvent` is raised.
- **Goal (intended)**: mirror-image of `onAdd` — should remove each
  ex-friend's UUID from the WorldGuard house-region membership list for any
  house either party owns (v1:src/Friends/UpdateFriendRegions.java:80-98).
- **BUG**: `userID` and `targetID` are declared (line 77-78) but **never
  assigned** — unlike `onAdd`, there is no `userID = user.getID();
  targetID = Users.fetchIDbyUUID(targetUUID);` call anywhere in this
  method (v1:src/Friends/UpdateFriendRegions.java:77-78, compare to the
  present assignment at lines 46-47 in `onAdd`). Both variables remain
  `null` for the method's entire execution. Since `ownerID` is a non-null
  `Integer` at the point of comparison (guarded by `ownerID != null &&
  ownerID != 0` at line 86), `ownerID == userID` and `ownerID == targetID`
  can **never be true** (comparing a non-null boxed `Integer` to `null`
  is always `false`) — the region-member-removal calls at lines 90 and 94
  are **dead code that never executes**. **Effect: removing a friend never
  revokes their WorldGuard house-region access** — once granted via
  `onAdd`, house access persists indefinitely even after unfriending,
  unless revoked through some other mechanism outside this slice.

---

## 7. `src/Broadcasts/BossBarEvents.java` — domain: misc — entirely dead

Three commented-out handlers, none live:
- **`onJoin(PlayerJoinEvent e)`** (v1:src/Broadcasts/BossBarEvents.java:16-
  25): would create a new boss bar for a joining player if one doesn't
  already exist for their UUID in `bar.barList`.
- **`onLeave(PlayerQuitEvent e)`** (lines 27-36): would remove the leaving
  player's entry from `bar.barList`.
- **`onMove(PlayerMoveEvent e)`** (lines 38-58): would update the boss
  bar's display location whenever a tracked player's `from`/`to` distance
  changes, or create a new bar if the player isn't tracked yet (with debug
  console messages either way).
None are enabled. `BossBarEvents` is otherwise an empty listener shell —
boss-bar HUD lifecycle is not driven by any live Bukkit event in this
slice; unclear/out of scope whether `BossBar`'s own class drives updates
through some other (non-listener) mechanism.

---

## 8. `src/Handlers/WeatherChange.java` — domain: world-admin

### `weatherChange(WeatherChangeEvent e)` — live
- **Event**: vanilla Bukkit `WeatherChangeEvent`, default priority
  (v1:src/Handlers/WeatherChange.java:21-22).
- **Trigger**: gated entirely on the static flag `Weatherchangeallow`
  (v1:src/Handlers/WeatherChange.java:19,24) — this is the exact flag
  documented as consumed by `/weather` in `commands-v1.md` (the command
  presumably toggles this static boolean; not re-verified here since
  `/weather`'s command class is out of this slice's read scope, but the
  field name and package match). When `Weatherchangeallow == false` (the
  default, per the field initializer at line 19), **every** natural weather
  change is intercepted.
- **Goal**: cancels the event (`e.setCancelled(true)`,
  v1:src/Handlers/WeatherChange.java:26), broadcasts a 3-line
  "Prevented weather change" banner to the whole server (lines 27-29), and
  plays a thunder sound to every online player (lines 30-33) — i.e., by
  default the server's weather is frozen and any organic change attempt is
  audibly/visibly announced as blocked, presumably until an admin runs
  `/weather` to flip `Weatherchangeallow` true (matching commands-v1.md's
  documented flag).
- **Bugs/edge cases**: none observed; straightforward and correctly
  gated. Note this broadcasts to the **entire server** every single time
  Bukkit's weather system *attempts* a change while disallowed — depending
  on how frequently vanilla weather-change attempts fire, this could be a
  spammy broadcast+sound-per-online-player pattern; not verified against
  Bukkit's actual `WeatherChangeEvent` firing frequency (out of scope).

---

## 9. `src/Teleport/TeleportDelay.java` — domain: world-admin

This class is a `Listener` (v1:src/Teleport/TeleportDelay.java:21) but
contains **no `@EventHandler`-annotated methods at all** — every method is
a plain static/instance helper (`hasDelay`, `hasImmune`, `hasLocation`,
`hasText`, `hasPrice`, `setDelay`, `setImmune`, `removeDelay`,
`removeImmune`, `removeLocation`, `removeText`, `removePrice`,
`updateDelay`, `cancelTeleport`, `executeTeleport`). Implementing
`Listener` with zero handlers is itself a minor code-smell but not a bug.
Documented here since it's the data/state backbone the (dead)
`TeleportMovement` handlers below were meant to interact with:

- **`setDelay`** (v1:src/Teleport/TeleportDelay.java:93-114): registers a
  pending teleport for a UUID with a countdown, target location, gem
  price, and display text; optionally marks the player movement-immune.
- **`updateDelay`** (lines 161-202): presumably ticked by a repeating
  scheduler task (registration site out of scope) — decrements every
  pending UUID's counter each call; at zero, removes the delay/immune
  state and calls `executeTeleport`. If the player has since gone offline,
  cleans up delay/location/immune state without executing.
- **`cancelTeleport(uuid, movement)`** (lines 204-239): tears down all
  pending-teleport state for a UUID and sends one of two messages
  ("canceled due to movement!" vs. "canceled!") depending on the `movement`
  flag — this is the method that `TeleportMovement`'s dead handlers were
  meant to call on player movement/damage (see file 10).
- **`executeTeleport`** (lines 241-312): charges gems if a price is set
  (only proceeds at all if `user.getGems() >= price`, else refunds/aborts
  with cleanup), teleports via `spawnpoint.teleport(user, location)`, and
  sends success/failure messages. Renames the destination display text to
  "Home" if the stored `teleportName` contains "house" or "room"
  (v1:src/Teleport/TeleportDelay.java:260-263).

No event-handler-specific claims to make here beyond confirming: **since
`TeleportMovement`'s handlers are commented out (file 10), `cancelTeleport`
is dead code from an event-trigger perspective** — it's only reachable if
some other, unread part of the codebase calls it directly (unclear/out of
scope).

---

## 10. `src/Teleport/TeleportMovement.java` — domain: world-admin — entirely dead

Both handlers commented out; the live constructor body is empty aside from
a `// TODO Auto-generated constructor stub` (v1:src/Teleport/
TeleportMovement.java:12-14) — a strong signal this class was scaffolded
and abandoned.

- **`onMovement(PlayerMoveEvent e)`** (lines 17-32): would cancel a
  pending teleport (via `TeleportDelay.cancelTeleport(uuid, true)`) if the
  player has a pending delay, isn't movement-immune, and their block
  coordinates actually changed (X/Y/Z block-level comparison, not just
  sub-block look/position change).
- **`onDamage(EntityDamageEvent e)`** (lines 34-50): would cancel a pending
  teleport (`cancelTeleport(uuid, false)`) if a delayed player takes any
  damage and isn't immune.

**Neither is enabled.** Combined with the confirmed-dead `cancelTeleport`
call path, this means **teleport-cancel-on-move and teleport-cancel-on-
damage do not function in this build** — a player with a pending
delayed teleport can walk around and take damage freely without losing
their teleport, contrary to what the fully-built `TeleportDelay` messaging
("Teleportation canceled due to movement!") implies was intended.

---

## 11. `src/Tutorial/TutorialEvents.java` — domain: misc (tutorial), with one method touching `inventory-menus`

### `onClick(InventoryClickEvent e, User user)` — **not a live Bukkit listener**
(v1:src/Tutorial/TutorialEvents.java:82-122). No `@EventHandler` annotation
and takes a non-standard extra `User user` parameter, confirming it's
manually invoked (grep-confirmed caller: `Menu/MenuClick.java`, outside
this slice's read scope). Domain judgment: **tutorial**, since its entire
body is tutorial-step advancement (`tut.TryNext("yes"/"cancel")`), even
though the trigger surface is an inventory click — it's not general
inventory-menu logic, it's the tutorial system reusing the menu-click
plumbing for its own "Start tutorial"/"Skip tutorial" buttons
(v1:src/Tutorial/TutorialEvents.java:90-119, matched by stripped, colorless
display-name equality). Cancels the click unconditionally
(`e.setCancelled(true)`, line 90) regardless of whether a tutorial/intro is
actually active for the clicking player.

### `onOpen(InventoryOpenEvent e)` — live
- **Event**: vanilla Bukkit `InventoryOpenEvent`, default priority
  (v1:src/Tutorial/TutorialEvents.java:206-207).
- **Trigger**: resolves the opening player's `User`
  (`Users.getUser`, catching `UserNotFoundException`/generic `Exception`,
  each early-returning — no separate `UserIsNpcException` catch here,
  v1:src/Tutorial/TutorialEvents.java:215-227). Only does anything further
  if `Tutorials.getTutorial(player)` returns non-null (line 231) — i.e.,
  the player must currently be mid-tutorial.
- **Goal**: for the "food" tutorial specifically, if the opened inventory's
  (color-stripped) name matches the "info about bread" product-info menu
  exactly, does nothing further (the blink-highlight call is itself
  commented out, v1:src/Tutorial/TutorialEvents.java:239-247) — else if the
  menu name contains "Product list of ", calls `menu.setMenuItemBlink(...)`
  to visually highlight slot 9 for the tutorial's configured interval
  (line 250). For the "armor" tutorial, if the menu name contains
  "Info about Leather ", blinks slot 5 (lines 259-264). **Domain call**:
  this handler is squarely tutorial-domain logic (guiding a new player to
  the right menu item) that happens to hook a `world-admin`/`inventory-
  menus`-adjacent vanilla event; classified `misc`(tutorial) per the task's
  domain guidance, not `inventory-menus`, since the menu system itself is
  untouched — only a cosmetic highlight is driven.
- **Bugs/edge cases**: the "bread info menu" exact-name-match branch
  (v1:src/Tutorial/TutorialEvents.java:239-247) has its actual blink call
  commented out (line 247) — so matching that specific branch currently
  does **nothing** except optionally log a debug message; effectively dead
  within a live method (partial dead code, not full-method dead).

### `onPurchase(PurchaseEvent e)` — live
- **Event**: custom plugin event `Handlers.PurchaseEvent`
  (v1:src/Tutorial/TutorialEvents.java:270-271) — fired elsewhere
  (shop/purchase command flow, out of scope) whenever a player buys a
  product.
- **Trigger**: resolves `productID`/`propertyID` from the purchase's
  relation ID, and requires `Tutorials.getTutorial(user.getPlayer())` to be
  non-null (v1:src/Tutorial/TutorialEvents.java:285-288) — only acts for
  players currently mid-tutorial.
- **Goal**: hardcoded property-ID checks drive tutorial progression —
  `propertyID == 22` + category "armor" advances the tutorial stage with
  the purchased item (v1:src/Tutorial/TutorialEvents.java:290-295);
  `propertyID == 19` + category "baked-goods" does the same
  (lines 296-302). Regardless of whether either branch matched, always
  updates the purchased-amount tally via `proProduct.saveAmount(...)`
  (line 303). The magic numbers `22`/`19` (specific property/shop IDs) are
  not resolved to human-readable names in this file — unclear/out of scope
  what those properties represent beyond "the armor shop" and "the bakery"
  implied by the category-name checks alongside them.
- **Bugs/edge cases**: none observed structurally; the hardcoded property
  IDs are fragile (any reshuffling of property IDs in the data store would
  silently break tutorial-purchase-detection with no error, just a
  no-op), but that's a data-coupling risk rather than a code bug per se.

### `onChat`, `onCommand`, `onMove`, `onLeave` — all commented out / dead
(v1:src/Tutorial/TutorialEvents.java:45-80, 124-154, 156-204, 307-320).
- `onChat(PlayerChatEvent e)`: would intercept chat entirely for a player
  mid-tutorial/intro-tutorial, cancel the event, feed the message into
  `TryNext(...)`, and strip the target from the event's recipient list.
- `onCommand(PlayerCommandPreprocessEvent e)`: would intercept `/menu`,
  `/next`, `/yes`, `/cancel` for a mid-tutorial player and route them into
  tutorial-stage advancement; any other command while mid-tutorial would
  call `Tutorials.notAllowed(player)`.
- `onMove(PlayerMoveEvent e)`: would forcibly teleport a mid-tutorial
  player back to `tutorial.targetLoc` and call `notAllowed(player)` if they
  move block-coordinates during specific tutorial stages (with named
  exceptions for "armor tutorial"/"food tutorial" at stage ≥ 4).
- `onLeave(PlayerQuitEvent e)`: would cancel the player's active
  intro/tutorial on quit.

None enabled — **the tutorial system currently has no chat interception,
no command interception, no movement lock, and no quit-cleanup**; only
inventory-click (manually wired), inventory-open (blink highlight), and
purchase-detection actually drive tutorial progression in this build. This
is a large functional gap versus what the class was clearly built to do.

---

## 12. `src/Listeners/EntityListener.java` — domain: split per handler (world-admin / misc combat)

### `onHit(EntityDamageByEntityEvent e)` — live
- **Event**: `EntityDamageByEntityEvent`, `priority = EventPriority.HIGHEST`
  (v1:src/Listeners/EntityListener.java:52-53) — runs late, after most
  other plugins' damage-modifying listeners, consistent with it being a
  final gate/modifier on damage.
- **Trigger/scope**: branches entirely differently depending on whether
  `e.getEntity()` is a `Player` (lines 55-376) versus an `ItemFrame`/
  `ArmorStand` (lines 377-403) — effectively two unrelated handlers packed
  into one method.
- **Player-damaged branch — domain: misc (combat/skills) primarily, with a
  `towns`-adjacent safezone check woven in**:
  - Resolves `userDamaged` (catches `UserNotFoundException`/
    `UserIsNpcException`/generic `Exception`, but notably does **not**
    `return` after the `UserNotFoundException` catch — it only calls
    `ErrorHandlers.userNotFoundAction(...)` and falls through
    (v1:src/Listeners/EntityListener.java:59-72) — meaning the rest of the
    method continues executing with `userDamaged == null`, which will NPE
    at the first `userDamaged.getSpecialSkillName()`/`.getFriendList()`
    etc. call if a damaged entity truly has no `User` record. **This is the
    same "missing return after error" bug class documented in
    `commands-v1.md`'s cross-domain observations** for `/user save`,
    confirmed present here too, v1:src/Listeners/EntityListener.java:61-64).
  - Resolves the damager as either a direct `Player` or an `Arrow`'s
    shooter-`Player` (lines 77-100); a "Juggernaut" skill check fires
    specifically for arrow damage where the damaged player's special skill
    is "juggernaut" — cancels the damage and plays a sound
    (v1:src/Listeners/EntityListener.java:91-98). If no damager resolves
    (non-player, non-arrow-from-player source), returns early (line
    102-124) — NPC damagers are also excluded via
    `CitizensAPI.getNPCRegistry().isNPC(damager)` (lines 104-107).
  - **Hide-and-Seek integration**: if both damaged and damager are in the
    *same* active Hide-and-Seek game, the damager is a seeker, the damaged
    is not a seeker, and the hide-timer phase has ended, calls
    `hsDamaged.catchParticipant(...)` (v1:src/Listeners/EntityListener.java:
    126-143) — this is the "seeker tags a hider" mechanic; does not itself
    cancel/modify the damage event.
  - **Skill-driven damage modification** (all gated on the relevant skill
    ID being > 0/at a specific tier, using `Skill.getSkillValue(...)` +
    `Main.getRandom(0,100)` chance rolls): AttackSpeed (double/triple-hit
    damage multiplier + message/sound, lines 148-171), Defense (flat
    percentage damage reduction, with a 25%-chance full-cancel at level 7,
    lines 176-201), Health (chance-based Regeneration I proc, lines 206-
    217), Ninja (30%-chance stealth/blindness proc against nearby players
    within a 30-block radius, rate-limited via `Main.ninjaSkill` map, lines
    222-251), Speed (chance-based Speed II proc, lines 256-267), Strength
    (chance-based Strength I/II potion proc on the damager, lines 272-289).
    All of these are skills-domain logic, arguably out of this slice's
    `towns/social/world-admin/misc` taxonomy — closest bucket is `misc`
    (combat mechanics) per the task's category list, flagged as a
    judgment call since no `skills` domain exists in the given taxonomy.
  - **Safezone/siege PvP gate — domain: towns/world-admin boundary**: if
    either party `inSafeZone()` **or** the damaged player has the damager
    on their friend list (`userDamaged.getFriendList().contains(damager
    .getUniqueId())`), and **neither** party is in an active siege, and
    **neither** is in an active Hide-and-Seek game, the damage is cancelled
    and a "note bass" sound plays (v1:src/Listeners/EntityListener.java:
    297-309) — this is the **live** friend-list PvP-prevention check
    referenced in the `HitFriendEvent` section above (file 4), functionally
    superseding that dead class. If both parties are in the **same**
    active siege, and the damaged player's `SiegeMember.isSafe()` is true
    (in their team's spawn/safe area), damage is cancelled with a message
    (v1:src/Listeners/EntityListener.java:311-347); a large block of siege
    kill/respawn/experience logic is commented out here too (lines 314-341)
    — siege-kill-triggers-respawn is apparently **also disabled** in this
    build, consistent with the dead-teleport/tutorial pattern seen
    elsewhere in this slice, though full siege-system verification is out
    of this slice's scope.
  - **Combat-tag**: for both damager and damaged, if they're in survival
    mode and not in staff/owner mode, sends a one-time "You are now in
    combat!" action-bar warning (only if not already tagged) and (re-)sets
    their `Main.incombat` timestamp to now + `Main.combat` seconds
    (v1:src/Listeners/EntityListener.java:351-373) — a standard PvP-logout
    -prevention combat timer.
- **ItemFrame/ArmorStand-damaged branch — domain: towns (property
  protection)**: if a player damages an `ItemFrame` inside a `property`
  WorldGuard region, or damages an `ArmorStand` anywhere, the damage is
  cancelled unless `main.ownermodus` records the player as currently in
  owner-mode for that UUID (v1:src/Listeners/EntityListener.java:379-402)
  — property-griefing protection for frames/stands. Note the `ArmorStand`
  check at line 395 is reached via an `else if` chained off the
  `propertyID != null` check, meaning an ArmorStand **inside** a property
  region is protected by the first branch (property-scoped), while an
  ArmorStand **outside** any property region is *also* protected globally
  by the second branch (line 395's `else if (e.getEntity() instanceof
  ArmorStand)`) — so ArmorStands are protected everywhere regardless of
  property region, while ItemFrames are only protected inside property
  regions. This asymmetry may be intentional (armor stands are more
  universally griefable/valuable) or an oversight; flagged as unclear
  intent, not a crash bug.

### `onDamage(EntityDamageEvent event)` — live — domain: misc
- **Event**: vanilla Bukkit `EntityDamageEvent`, default priority
  (v1:src/Listeners/EntityListener.java:406-407).
- **Trigger**: only for `Player` entities; resolves `User` with full
  three-way catch (`UserNotFoundException`/`UserIsNpcException`/generic
  `Exception`), each correctly early-returning
  (v1:src/Listeners/EntityListener.java:414-429) — unlike `onHit` above,
  this method's error handling is correctly gated.
- **Goal**: **AFK-cancel-on-damage** — if the player is currently AFK and
  not mid-AFK-teleport (`user.getAfk().teleporting == false`), removes
  their AFK state (v1:src/Listeners/EntityListener.java:434-440); always
  resets their AFK-commence timer to now + `main.afkTime` seconds (line
  441) — i.e., taking damage resets the AFK countdown and cancels existing
  AFK status, a standard "you're not actually afk if you're getting hurt"
  rule. **Avenger skill**: if the damaged player is the tracked target of
  some other player's "avenger" bond (`Main.avenger` map, value-lookup then
  key-scan to find the avenger, lines 446-457), deals the damaged player
  1.5x additional direct damage via `player.damage(plusdamage)`
  (v1:src/Listeners/EntityListener.java:460-462) — a skill/mechanic that
  amplifies damage taken by the avenger's bonded target, layered on top of
  whatever the original `EntityDamageEvent`'s damage was (applied as a
  *separate* damage call, not a modification of `event.getDamage()`,
  meaning this could itself re-trigger `EntityDamageEvent`/combat-tag
  logic recursively — not verified whether Bukkit's `Player.damage()`
  re-fires a nested event synchronously here, flagged as unclear/out of
  scope but worth noting as a possible re-entrancy risk).
- **Bugs/edge cases**: the avenger lookup loop (`for (User a :
  Main.avenger.keySet())`, lines 449-456) breaks on the first match, so if
  multiple avengers somehow bonded to the same target (data-model question,
  out of scope), only one would apply extra damage per damage event —
  likely intentional/inconsequential.

---

## 13. `src/Listeners/InventoryListener.java` — domain: inventory-menus (judgment call, see below)

### `onClose(InventoryCloseEvent event)` — live
- **Event**: vanilla Bukkit `InventoryCloseEvent`, default priority
  (v1:src/Listeners/InventoryListener.java:26-27).
- **Trigger**: only for `Player`; returns early if the player has NPC
  metadata (v1:src/Listeners/InventoryListener.java:38-41). Resolves
  `User` via `Users2.FindUser(uuid)` — if null, sends a generic
  "something went wrong... notify a developer" error and returns (lines
  43-49). Only proceeds further if `user.getMenuViewing() != null`
  (line 51) — i.e., the closing player must currently be in "spectating
  another player's inventory" mode.
- **Goal**: if the closed inventory's name matches the menu-viewing
  target's `getOpenMenu()` name, **and** it does *not* match the viewer's
  own `getMenuPrevious()` name, sends a "stopped viewing" message and calls
  `user.removeMenuViewing()` (v1:src/Listeners/InventoryListener.java:51-
  63) — cleans up the invsee/menu-spectate state when the spectating
  player closes the viewed inventory (but not when they close some other,
  unrelated inventory that happens not to be their own "previous" menu —
  the double-name-comparison logic here is intricate and not fully
  traceable without reading `User.getMenuViewing`/`getOpenMenu`/
  `getMenuPrevious` semantics from `Users/User.java`, out of this slice's
  scope; documented verbatim rather than interpreted further).
- **Domain call**: this is squarely about the **personal-inventory-viewing
  /invsee "menu" system** (`user.getMenuViewing()`, `getOpenMenu()`) — the
  task brief explicitly flags this file as a likely `inventory-menus`
  overlap, and this handler confirms it: it's managing the state machine
  for one player spectating another's live inventory, which is the
  `inventory-menus` domain (per `commands-v1.md`'s own domain definition:
  "menu/viewmenu/invsee/inventory/enderchest"), not general `world-admin`.
  Classified **`inventory-menus`**, not `world-admin`.

### `onClick(InventoryClickEvent event)` — live
- **Event**: vanilla Bukkit `InventoryClickEvent`, default priority
  (v1:src/Listeners/InventoryListener.java:66-67).
- **Trigger**: same `Player`/NPC-metadata/`User`-resolution guards as
  `onClose` (v1:src/Listeners/InventoryListener.java:69-89). Only acts if
  `user.getMenuViewing() != null` (line 91).
- **Goal**: unconditionally cancels the click
  (v1:src/Listeners/InventoryListener.java:93) — i.e., while spectating
  another player's inventory (invsee-style), the spectator cannot click/
  move any items around; it's a read-only view. Simple and correctly
  scoped.
- **Domain call**: same reasoning as `onClose` — **`inventory-menus`**,
  the invsee/menu-spectate read-only-lock behavior.

---

## Summary counts

- **13 files read in full.**
- **~24 `@EventHandler`-shaped methods found** (annotated or previously
  annotated-then-commented), across the 13 files.
- **9 live (enabled) handlers**: `GateEvents.onGateHit`,
  `GateEvents.onGateTouch`, `TownEvents.onEnter`, `TownEvents.onLeave`,
  `FriendInteract.onInteract`, `UpdateFriendRegions.onAdd`,
  `UpdateFriendRegions.onRemove` (buggy — no-op removal),
  `WeatherChange.weatherChange`, `TutorialEvents.onOpen`,
  `TutorialEvents.onPurchase`, `EntityListener.onHit`,
  `EntityListener.onDamage`, `InventoryListener.onClose`,
  `InventoryListener.onClick` — **14 live total** (correcting the earlier
  running estimate; see full per-file list above for the authoritative
  set).
- **~1 non-listener helper masquerading as a click handler**:
  `TutorialEvents.onClick` (manually dispatched, no `@EventHandler`).
- **~10 fully commented-out/dead handler methods**: `GateEvents
  .onGateMove`, `TownEvents.onDamage`, `HitFriendEvent.FriendHit`,
  `MentionNameEvent.Mention`, `BossBarEvents.onJoin/onLeave/onMove` (3),
  `TeleportMovement.onMovement/onDamage` (2), `TutorialEvents.onChat/
  onCommand/onMove/onLeave` (4).
- **3 files are entirely dead** (every handler commented out):
  `HitFriendEvent.java`, `MentionNameEvent.java`, `BossBarEvents.java`.
- **1 confirmed logic bug in live code**: `UpdateFriendRegions.onRemove`'s
  unassigned `userID`/`targetID` nulling out its own removal branches
  (v1:src/Friends/UpdateFriendRegions.java:77-78).
- **1 confirmed missing-return bug in live code** (same class as
  documented in `commands-v1.md`): `EntityListener.onHit`'s
  `UserNotFoundException` catch not returning
  (v1:src/Listeners/EntityListener.java:61-64).
# v1 event-listener catalog — Items/Products + Inventory-menus

Mined from `knk-v1-archive` (source read from
`C:\Users\Pandi\Documents\Werk\KnightsAndKings\Repository\knk-v1-archive`,
since the `Repository/knk-v1-archive` checkout inside this worktree is
empty/untracked). Citations use `v1:src/Path/File.java:line`, matching
`docs/specs/legacy/commands-v1.md` and `docs/specs/legacy/user-system.md`.

## Methodology

Full read, in full, of the 15 files named in the task brief: the six
Products/Effects classes (`CraftEvents.java`, `DropItem.java`,
`EnchantbookClick.java`, `SoulboundEvents.java`, `SpecialItemEvents.java`,
`Effects/ProductConsume.java`) and the nine Menu classes (`CouponClick.java`,
`DuelSetupClick.java`, `FriendManagerClick.java`, `ItemMenuClick.java`,
`MenuClick.java`, `OwnedhousesClick.java`, `OwnedpropertiesClick.java`,
`PlayerManagerClick.java`, `QuestMenuClick.java`). For every `@EventHandler`
method: the exact Bukkit event type, whether/when `setCancelled(true)` is
called, the trigger condition (inventory-title substring match, slot number,
ItemStack type/display-name check), what the handler does (read from the
method body, not inferred from the name), which feature domain it actually
belongs to, and any bug/edge-case found (uncancelled paths, missing
null-checks, fragile string matching). Non-`@EventHandler` public methods
that exist purely to be called by a dispatcher (see Architecture note below)
are documented too, since several of the "menu click" classes route through
them rather than through their own listener registration — skipping them
would silently drop most of the actual button logic. Verbatim-only, no
invented behavior; anything not resolvable from the read files is marked
"unclear/out of scope."

## Architecture note — two independent click-handling systems, not one

This slice does **not** have one listener per menu. There are two distinct,
independently-operating mechanisms, and most menus are wired into only one
of them — this distinction matters a lot for citing "is this handler
cancelling the event":

1. **The `MenuClick` central dispatcher** (`v1:src/Menu/MenuClick.java:58-443`,
   `@EventHandler onClick(InventoryClickEvent)` — actually named `Onclick`).
   It only does anything if the clicking player's UUID is a key in
   `MenuCommand.pmenu` (`v1:src/Menu/MenuClick.java:84`) — a session map
   presumably populated whenever a "personal menu" tree is opened
   (`MenuCommand.java` itself is out of scope for this slice, so exactly what
   populates/clears `pmenu` is unclear/out of scope here). If the UUID is
   **not** in `pmenu`, `Onclick` does nothing at all — no cancellation, no
   routing — regardless of what inventory is open. Inside the gate, it reads
   `menu.getName()` and does a long `if/else if` chain of exact
   (`equalsIgnoreCase`) or substring (`contains`) title matches, and for most
   of the tree, delegates to a **plain, non-`@EventHandler` public method**
   on a per-menu class it `new`s up right there
   (`v1:src/Menu/MenuClick.java:297-434`), e.g.
   `new OwnedhousesClick(main).onClick(e, user)`,
   `new DuelSetupClick(main).onClick(e, user)`,
   `new CouponClick(main).onClick(e, user)`,
   `new FriendManagerClick(main).ManageFriendsClick(e, user)` /
   `.AddFriendsClick(e, user)` / `.FriendRequestClick(e, user)`,
   `new PlayerManagerClick(main).PlayerManagerClick(e, user)`,
   `new ItemMenuClick(main).ShopItemsManagerClick(e, user)`.
   These delegate methods are **not themselves registered as Bukkit
   listeners** — they only ever run if `MenuClick.Onclick` calls them, and
   they rely on `MenuClick.Onclick` having already null-checked
   `e.getCurrentItem()` (`v1:src/Menu/MenuClick.java:79-82`) before routing.

2. **Independent, self-registered `@EventHandler InventoryClickEvent`
   listeners** that fire on *every* inventory click server-wide, with no
   dependency on `MenuCommand.pmenu` at all, each doing its own inventory-title
   match: `EnchantbookClick.onInvClick`
   (`v1:src/Products/EnchantbookClick.java:81-146`, matches by Inventory
   *object identity*, not title — see below), `ItemMenuClick.onClick`
   (`v1:src/Menu/ItemMenuClick.java:61-376`), `PlayerManagerClick.Onclick`
   (`v1:src/Menu/PlayerManagerClick.java:137-436`), `QuestMenuClick.onClick`
   (`v1:src/Menu/QuestMenuClick.java:44-179`), and
   `FriendManagerClick.Onclick` (`v1:src/Menu/FriendManagerClick.java:31-76`,
   handles only the "Friend request from " title, separately from its three
   `pmenu`-dispatched sibling methods in the same class). `CouponClick`,
   `DuelSetupClick`, `OwnedhousesClick`, and `OwnedpropertiesClick` have
   **no** independently-registered `InventoryClickEvent` handler of their
   own — their click logic (`onClick`, `ForcedHouseRemoveClick`,
   `ForcedPropertySellClick`, etc.) is reachable **only** through the
   `MenuClick` dispatcher, which is a single point of failure for all of
   them (if `pmenu` doesn't contain the UUID for any reason, none of that
   logic ever runs, and the click is never cancelled either).

Net effect: on any given inventory click, up to five separately-registered
listeners (`MenuClick`, `ItemMenuClick`, `PlayerManagerClick`,
`QuestMenuClick`, `FriendManagerClick`, plus `EnchantbookClick`,
`DuelSetupClick`'s drag handler, `ItemMenuClick`'s drag/close handlers) all
run and each independently string-matches the inventory title looking for
"is this mine?" There is no single owner of "cancel this click," so the
correctness of cancellation for any given menu depends on which of the two
systems (or both, or neither) happens to recognize its title.

## Products / Effects domain (`items` feature)

### `CraftEvents.java` — crafting-table gate

- **Event**: `PrepareItemCraftEvent` (`onCraft`,
  `v1:src/Products/CraftEvents.java:28-70`). Not a menu-click event; fires
  whenever a crafting grid's result slot would change.
- **Trigger**: no title/slot matching — applies to every crafting inventory,
  player 2×2 grid and workbench alike. Player identified via
  `e.getViewers().get(0)` cast to `Player`
  (`v1:src/Products/CraftEvents.java:31`) — assumes the first viewer exists
  and is a player; no bounds/`instanceof` check (see Bugs below).
- **Goal**: looks up the vanilla recipe result's material/type ID, maps it to
  an internal `ItemType` → `Product` → category
  (`v1:src/Products/CraftEvents.java:53-61`). If the user is not "in owner
  modus" (`!user.inOwnerModus()`, line 51) **and** the resulting product's
  category is one of `meat`, `fish`, `baked-goods`, `vegetables`, or
  `furniture`, it **replaces** the vanilla crafting result with a KnK
  "property item" version of the same product/amount
  (`v1:src/Products/CraftEvents.java:63`). For every other case — no
  matching product, product in a different category, or no product at all —
  it sets the result to `null`, i.e. **blocks the craft entirely**
  (`v1:src/Products/CraftEvents.java:68`).
- **Significant finding, not a bug**: this means, in v1, regular players
  (anyone not in "owner modus") cannot vanilla-craft **anything** — tools,
  weapons, blocks, redstone, etc. — except the specific food/furniture
  recipes the product system re-skins. All other crafting attempts silently
  produce no result. This is a foundational design decision for the whole
  crafting/product economy and should be called out explicitly for v3
  planning; it is easy to misread as "food crafting is special" when the
  real behavior is "crafting is disabled by default."
- **Bugs/edge cases**:
  - `e.getViewers().get(0)` (line 31) — no check that the viewer list is
    non-empty or that the first viewer is a `Player`; would throw
    `IndexOutOfBoundsException`/`ClassCastException` if a non-player viewer
    (or none) is ever first in the list.
  - Generic `catch (Exception ex)` around `Users.getUser(uuid)`
    (`v1:src/Products/CraftEvents.java:44-50`) — swallows and logs any
    exception, including unrelated runtime errors, then treats it the same
    as "user not found."
  - Feature allocation: **items** (product/category system) directly gating
    a core vanilla mechanic (crafting) — worth flagging as a strong
    items↔world-mechanics coupling for v3.

### `DropItem.java` — dropped/spawned item nameplate cosmetics

- **Event 1**: `PlayerDropItemEvent` (`test`,
  `v1:src/Products/DropItem.java:36-50`). Not cancelled; no gating logic at
  all — always runs.
- **Event 2**: `ItemSpawnEvent` (`test2`,
  `v1:src/Products/DropItem.java:52-66`). Not cancelled; same pattern.
- **Trigger**: none (title/slot n/a — these are world events, not menu
  clicks). Only condition checked is `item.hasItemMeta()` /
  `hasDisplayName()`.
- **Goal**: sets the dropped/spawned item entity's `setCustomName(...)` to
  the ItemStack's display name and `setCustomNameVisible(true)`
  (`v1:src/Products/DropItem.java:45-47`, `:61-63`) — purely cosmetic, makes
  a custom product's name show as a floating nameplate over the item entity
  in the world. `test`/`test2` fire on effectively the same trigger
  (dropping an item spawns an `Item` entity, which also fires
  `ItemSpawnEvent`), so the nameplate gets set twice for a manual drop — not
  harmful, just redundant.
- **Feature allocation**: `items` (product display polish), not
  `inventory-menus`.
- **Bugs/edge cases**:
  - Method names `test` and `test2` (`v1:src/Products/DropItem.java:37`,
    `:53`) are non-descriptive leftover/placeholder names — a code-quality
    flag, not a functional bug.
  - No null-checks needed here (`e.getItemDrop()`/`e.getEntity()` are
    non-null by Bukkit's event contract); none found missing.

### `EnchantbookClick.java` — custom enchant-book application flow

- **Event 1**: `PlayerInteractEvent` (`onClick`,
  `v1:src/Products/EnchantbookClick.java:41-67`). Not a click-cancelling
  event by nature; not cancelled here.
  - **Trigger**: player's held item is `Material.ENCHANTED_BOOK` with an
    item-meta display name (stripped of color) matching a known custom
    enchantment name from `Enchantment.getIDList()`
    (`v1:src/Products/EnchantbookClick.java:47-55`).
  - **Goal**: registers the player's UUID into three parallel `HashMap`s
    (`invList`, `enchList`, `enchantBook`,
    `v1:src/Products/EnchantbookClick.java:37-39`, populated at `:57-59`)
    and then calls `player.openInventory(player.getInventory())`
    (`v1:src/Products/EnchantbookClick.java:60`) — **the "menu" this class
    listens to is the player's own inventory**, not a custom GUI. This is
    architecturally unique among all 15 files: every other handler in this
    slice identifies "my menu" by inventory *title* string; this one
    identifies it by inventory *object reference* (see `onInvClick` below).
- **Event 2**: `InventoryCloseEvent` (`onInvClose`,
  `v1:src/Products/EnchantbookClick.java:69-79`) — cleans up the three maps
  for the closing player's UUID if present. No cancellation applicable.
- **Event 3**: `InventoryClickEvent` (`onInvClick`,
  `v1:src/Products/EnchantbookClick.java:81-146`).
  - **Trigger**: `e.getWhoClicked() instanceof Player` and
    `invList.get(uuid).equals(e.getInventory())`
    (`v1:src/Products/EnchantbookClick.java:88-90`) — object-identity match
    against the player's own inventory captured in step 1, not a title
    string.
  - **Cancellation**: `e.setCancelled(true)` unconditionally once the
    trigger matches (`v1:src/Products/EnchantbookClick.java:92`) — good,
    prevents the player from actually moving the clicked item while
    "selecting" it for enchanting.
  - **Goal**: takes the clicked item, verifies it's a known product
    (`product.getProductIDbyDisplayName`) and not soulbound
    (`!product.soulbound(item)`,
    `v1:src/Products/EnchantbookClick.java:97`), computes how many
    enchant levels are still available via `canEnchant(...)`
    (`v1:src/Products/EnchantbookClick.java:148-177`), applies either a
    vanilla `addUnsafeEnchantment` or a custom lore-based enchantment via
    `product.addCustomEnchantment` (`:110-123`), removes one instance of the
    enchant book from the player's inventory by display-name scan
    (`removeItemfromInventory`, `v1:src/Products/EnchantbookClick.java:179-200`),
    plays a sound, messages the player, and closes the inventory
    (`:124-130`).
  - **Bugs/edge cases**:
    - **NPE risk on empty-slot click**: `ItemStack item = e.getCurrentItem();`
      followed immediately by `item.hasItemMeta()`
      (`v1:src/Products/EnchantbookClick.java:93-94`) with **no null check**.
      Because the "menu" being watched is the player's *own full inventory*
      (opened via `player.openInventory(player.getInventory())`), empty
      slots are extremely likely during ordinary use (any player with free
      inventory space), so this is a readily-reachable
      `NullPointerException`, not a theoretical edge case.
    - `removeItemfromInventory` matches purely by display-name string
      equality (`v1:src/Products/EnchantbookClick.java:191`) — if the player
      holds multiple visually-identical enchant books (same display name),
      it removes whichever is found first by inventory-slot order, not
      necessarily the one that was actually used to trigger `onClick`.
    - `canEnchant`'s max-level formula (`Math.round(getEnchantmentMaxLevel /
      (6 - grade))`,
      `v1:src/Products/EnchantbookClick.java:151`) divides by
      `6 - product.getGrade(...)` — if a product's grade is ever `6` or
      higher this is a divide-by-zero (`ArithmeticException`, integer
      division); unclear/out of scope whether grade can reach that value
      (grade table not part of this read scope).
  - **Feature allocation**: `items` (product/enchant system). Not a
    "menu" in the `inventory-menus` sense at all — it repurposes the
    player's own backpack as the picker UI, which is itself worth flagging
    for v3 as an unusual pattern (no dedicated GUI layout, so it can't be
    redesigned/relaid-out independently of the player's actual inventory
    slots).

### `SoulboundEvents.java` — soulbound drop prevention

- **Event**: `PlayerDropItemEvent` (`onDrop`,
  `v1:src/Products/SoulboundEvents.java:81-96`).
- **Trigger**: dropped item has item-meta, has lore, and the lore list
  contains the exact string `ChatColor.RED + "Soulbound"`
  (`v1:src/Products/SoulboundEvents.java:90`).
- **Goal**: `e.setCancelled(true)` (`:92`) — blocks the manual `/drop`
  (Q-key) action for soulbound items. That is the **only** live handler in
  this file.
- **Significant finding**: two much larger handlers are present but fully
  commented out: `onPlayerDeathe(PlayerDeathEvent)`
  (`v1:src/Products/SoulboundEvents.java:29-64`) and
  `onRespawn(PlayerRespawnEvent)` (`:66-79`). The commented death handler
  implements exactly the "keep Soulbound items, but Ghosted items go into a
  temporary post-respawn return list" logic that the class's name and the
  `keep`/`KillDeathStat.respawn` fields imply should exist
  (`v1:src/Products/SoulboundEvents.java:27, 48-58`). With these disabled,
  **soulbound items in v1 are only protected from manual dropping — not
  from being lost on death.** This is a functional gap directly opposite to
  what "soulbound" items conventionally promise (keep-on-death), and is a
  high-value flag for v3: either the death-protection was deliberately
  pulled (and drop-protection is a deliberate partial feature), or this is
  dead/abandoned code that never got re-enabled. Either way it should not be
  assumed from the class name that soulbound items survive death in v1 —
  they don't, per the live code.
- **Feature allocation**: `items` (soulbound is explicitly named as an
  `items` sub-feature in `commands-v1.md`'s domain list). No inventory-menu
  component at all.
- **Bugs/edge cases**: none beyond the dead-code gap above; the live
  handler itself is straightforward and correctly cancels.

### `SpecialItemEvents.java` — "sword box" loot-box consumables

- **Event**: `PlayerInteractEvent` (`onInteract`,
  `v1:src/Products/SpecialItemEvents.java:24-70`).
- **Trigger**: right-click (air or block) while holding an item with a
  display name (color-stripped) equal to `"legendary sword box"` or
  `"rare sword box"` (`v1:src/Products/SpecialItemEvents.java:30-38, :52`).
- **Goal**: cancels the interaction (`e.setCancelled(true)`, lines 40, 54 —
  prevents the right-click from also triggering block interaction), grants
  the player a randomized sword via `product.getLegendarySwordBox()` /
  `product.getRareSwordBox()` (`:41, :55`), decrements the held box stack by
  one or clears the hand slot if it was the last one (`:43-50, :57-64`), and
  sends a colored confirmation message. This is a "loot box" opening
  mechanic implemented as a direct world right-click, not a GUI.
- **Feature allocation**: `items` (special/product items). No
  `inventory-menus` involvement.
- **Bugs/edge cases**: `player.getItemInHand() != null` guard
  (`v1:src/Products/SpecialItemEvents.java:32`) is effectively always true on
  this Bukkit API version (empty hand returns an `AIR` ItemStack, not
  `null`), so it's a harmless no-op guard rather than a real null-check —
  consistent with the same pattern flagged for casts elsewhere in the v1
  codebase per `commands-v1.md`'s cross-domain observations. No other issues
  found; both branches are symmetric and consistent.

### `Effects/ProductConsume.java` — food-item side-effect roll

- **Event**: `PlayerItemConsumeEvent` (`onConsume`,
  `v1:src/Effects/ProductConsume.java:34-171`). Correctly **not**
  cancelled anywhere — this handler piggybacks on a normal vanilla-consume
  action to add a side effect, it does not gate a menu, so no cancellation
  is expected or needed.
- **Trigger**: consumed item has item-meta with a display name that resolves
  to a known product (`product.getProductIDbyDisplayName`,
  `v1:src/Effects/ProductConsume.java:62`).
- **Goal**: rolls a random chance (5%/15%/25% depending on the product's
  "grade" 1-5, `:67-76`) to trigger an effect roll at all; if triggered,
  rolls separately for a harmful effect (`rand <= harmfulChance`) and a
  beneficial one (`rand >= beneficialChance`) with grade-dependent
  probability tables (`:79-101`), picks a specific effect ID from
  `Effect.getSpecificIDList(...)` weighted by the effect's own "Grade"
  field (`:108-126`, `:134-152`), and applies it via `addEffect(...)`
  (`v1:src/Effects/ProductConsume.java:173-244`), which switches on effect
  ID to call one of several `Effect.add*` methods (`addMTB`, `addDJ`,
  `addPG`, `addCB`, `addHB`, `addGB`, `addRB`) with randomized
  duration/delay/value ranges, then messages the player (success-green if
  beneficial, red if harmful). Separately, it also advances any
  `AssignmentFoodConsumeRandom` assignment the user has active by 1
  (`v1:src/Effects/ProductConsume.java:159-167`) — ties food consumption
  into the quest/assignment-progress system.
- **Feature allocation**: `items` (product consumables) with a secondary
  tie-in to the assignment/quest-progress system (`Assignments` package) —
  worth noting as a cross-domain dependency, not purely `items`.
- **Bugs/edge cases**:
  - `switch(effectID)` in `addEffect` (`v1:src/Effects/ProductConsume.java:179-231`)
    has no `default` case; if `effectID` is ever a value not in `{1,2,3,4,5,6,8}`
    (note: `7` is skipped entirely — unclear/out of scope why), `duration`
    stays at its pre-switch default of `600` and no `effect.add*(...)` call
    happens at all, yet the method still unconditionally sends the player a
    "You received the effect ..." message (`:236-243`) using
    `effect.getName(effectID)` — i.e. it can tell the player they received
    an effect that was never actually applied.
  - Same generic `catch (Exception ex)` / swallow-and-treat-as-not-found
    pattern as `CraftEvents` (`v1:src/Effects/ProductConsume.java:48-52`).
  - No missing null-checks found on `e.getItem()` (guaranteed non-null by
    the event contract) or on the `hasItemMeta()`/`hasDisplayName()` guard
    chain, which is correctly ordered here.

## Menu domain (`inventory-menus` shell, mixed underlying features)

### `MenuClick.java` — the personal-menu hub + central dispatcher

- **Event 1**: `InventoryClickEvent` (`Onclick`,
  `v1:src/Menu/MenuClick.java:58-443`) — see Architecture note above for the
  dispatcher role. Directly implements the `Menus.PersonalMenu` button tree
  itself (`v1:src/Menu/MenuClick.java:88-296`) in addition to dispatching
  ~35 other named sub-menus by title match (`:297-434`).
  - **Cancellation**: only cancelled for the `PersonalMenu` branch itself
    (`e.setCancelled(true)`, `v1:src/Menu/MenuClick.java:100`) — and *only*
    if `clicked != null` (see Bugs below) and the UUID is in `pmenu`. For
    every `else if` branch that delegates to another class's method
    (`:297-434`), cancellation is the delegate's responsibility, not
    `Onclick`'s.
  - **Trigger for `PersonalMenu` branch**: `menuName.equalsIgnoreCase(Menus.PersonalMenu)`
    (`v1:src/Menu/MenuClick.java:88`), then a long chain of
    `dc.contains(...)` substring checks on the clicked item's lower-cased,
    color-stripped display name (`:99` onward) — `"exit"`, `"skills"`,
    `"houselist"`, `"propertylist"`, `"houses"`, `"properties"`,
    `"teleport to points on the map"`, `"current rank: "`, `"titles"`,
    `"website"`, `"social"`, `"shopitems"`, `"player manager"`,
    `"refresh item-amount"`, `"refresh item-price"`, `"gem-shop"`,
    `"assignments"`, `"support"`, `"gate manager"`, and exact-match
    `"event manager"` / `"events"`.
  - **Special sub-case**: if a `Tutorial` targeting this player is active
    (`v1:src/Menu/MenuClick.java:90-98`), most of the normal button logic is
    skipped and only tutorial-stage-specific clicks (`"exit"`, and
    stage-4-only `"houses"`/`"skills"` for the "room tutorial"/"skills
    tutorial") are handled (`:101-138`) — the rest of the menu's buttons are
    inert while a tutorial owns the session.
  - **Goal (non-tutorial)**: routes to ~20 different sub-menu openers on
    `Menu` (e.g. `openSkillMenu`, `openHouselist`, `openOwnedHouses`,
    `openFriendsManager`, `openPlayerManager`, `openGateManager`,
    `openEventManager`), directly performs two admin bulk-refresh actions
    in-line (`"refresh item-amount"` / `"refresh item-price"` —
    `v1:src/Menu/MenuClick.java:236-257`, iterating every property-product
    relation and re-rolling its daily amount/weekly price), and closes the
    inventory + prints a URL for `"website"` (`:216-220`). Several branches
    additionally guard `user.inMiniGame()` and refuse with an error message
    if the player is mid-minigame (`:153-158` etc.).
- **Event 2**: `PlayerInteractEvent` (`onClick`,
  `v1:src/Menu/MenuClick.java:445-478`) — separate trigger, opens the
  Personal Menu itself. **Trigger**: right-click (air/block) while holding
  an item whose display name equals `ChatColor.GOLD + "personal menu"`
  (`v1:src/Menu/MenuClick.java:469`). **Goal**: `this.menu.OpenPersonalMenu(user)`
  (`:473`). Not a click-cancelling scenario; no cancellation logic present
  or needed.
- **Feature allocation**: `inventory-menus` is the correct primary domain
  for this file — it is the actual menu-navigation shell — but it directly
  touches `items`/property-economy (the two refresh actions),
  `siege-minigame` (dispatch to `Menus.SiegeManagerMenu`,
  `EventManagerMenu`, arena/duel titles), `social` (`FriendsManagerMenu`
  dispatch), `towns` (`GateManagerMenu` dispatch), and `users`
  (`PlayerManagerMenu` dispatch, donator/title info) purely through routing
  — i.e. this file is legitimately the shell, and everything it routes *to*
  belongs to another domain.
- **Bugs/edge cases**:
  - **Uncancelled empty-slot click inside a tracked menu**: `if (clicked ==
    null) { return; }` (`v1:src/Menu/MenuClick.java:79-82`) happens *before*
    any `e.setCancelled(true)` call, for *every* menu this dispatcher is
    responsible for (the `PersonalMenu` branch and all ~35 delegated
    branches, since the delegates are never reached either). Any click on
    an empty slot inside one of these menus — including the top (menu)
    inventory's decorative/unfilled slots — goes through completely
    uncancelled. Because the menus in this family are built with
    `Bukkit.createInventory(...)` and manually `setItem`-filled (not
    necessarily every slot), a player with an item on their cursor can drop
    it into any empty slot of these custom GUIs, and a player can freely
    pick up/move any item that Bukkit's default handling would otherwise
    allow for an uncancelled click — this is the theft/dupe-relevant bug the
    task asked to flag explicitly, and it affects the entire `pmenu`-gated
    menu family at once, not just one screen.
  - `MenuCommand.pmenu` gating means the **entire** dispatcher — cancellation
    included — does nothing if a player's UUID isn't in that map. Exactly
    when entries are added/removed is in `MenuCommand.java`, outside this
    read's scope — unclear/out of scope whether every custom-menu-open path
    reliably populates it, but the failure mode (no cancellation at all) is
    high-severity if any path misses it.
  - `addmenulist`/`addpropertylist` static helpers
    (`v1:src/Menu/MenuClick.java:479-508`) call
    `itemStack.getItemMeta()` and set display name/lore without checking
    that `getItemMeta()` returned non-null — fine for normal materials, but
    would NPE for a material with no meta support (edge case, not observed
    triggered anywhere in this slice).

### `CouponClick.java` — property-product coupon redemption

- **Only delegate method** `onClick(InventoryClickEvent e, User user)`
  (`v1:src/Menu/CouponClick.java:37-105`) — **not** annotated
  `@EventHandler`; reachable only via `MenuClick`'s
  `"Use " + "Item Coupon"` title match
  (`v1:src/Menu/MenuClick.java:354-356`).
  - **Cancellation**: `e.setCancelled(true)` unconditionally at the very top
    (`v1:src/Menu/CouponClick.java:42`) — correct, always cancels before any
    further logic.
  - **Trigger**: relies on the player currently standing inside a `property`
    WorldGuard region (`Worldguard.getStructureIDbyRegion`,
    `v1:src/Menu/CouponClick.java:43`) to resolve a `propertyID`, then reads
    slot 4 of the open inventory for a product display name
    (`v1:src/Menu/CouponClick.java:46`), then matches the *clicked* item's
    stripped display name against `"buy with coupon"`, a `"This item costs:
    "` prefix, or `"cancel"` (`:52-83`).
  - **Goal**: `"buy with coupon"` — decrements a coupon ItemStack by 1 (found
    via `getCouponfromMenu`, slot 2 of the menu,
    `v1:src/Menu/CouponClick.java:126-138`), returns it to the player's
    inventory, and fires a custom `PurchaseEvent` with `usingCoupon=true`
    (`:64`). The costs-money branch checks stock (`proproduct.getAmount`)
    and the user's coin balance before firing the same `PurchaseEvent` with
    `usingCoupon=false` (`:65-82`). `"cancel"` returns the coupon to the
    player, removes the session from `ItemFrameAdd.couponMenu`, and reopens
    the item-info screen (`:83-88`).
- **Event 2**: `InventoryCloseEvent` (`onClose`,
  `v1:src/Menu/CouponClick.java:107-124`) — this **is** a registered
  `@EventHandler`, independent of the dispatcher. **Trigger**: inventory
  title (stripped) contains both `"Use "` and `"Item Coupon"`
  (`v1:src/Menu/CouponClick.java:115`). **Goal**: if the player still has an
  active coupon-menu session (`ItemFrameAdd.couponMenu`), returns the
  coupon item to their inventory on close — a safety-net so the coupon
  isn't lost if the player closes the GUI instead of clicking cancel.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `items`/property-economy** (product purchase, coupon
  consumption, `PropertyProduct` stock/price) — explicitly a dual-nature
  case as flagged in the task brief.
- **Bugs/edge cases**:
  - Line 46 (`e.getInventory().getItem(4).getItemMeta().getDisplayName()`)
    and line 52 (`e.getCurrentItem().getItemMeta().getDisplayName()`) have
    **no null-checks** — if slot 4 is empty, or the clicked item has no
    meta, this throws an NPE. Since the method is only reached through
    `MenuClick`'s pre-filter (which already excludes `clicked == null`),
    the slot-4 risk is the more exposed one; slot 4 is expected to always
    be a fixed "which product" display item by design, but nothing enforces
    that defensively here.
  - Debug branches (`main.debug`) log to console rather than to the player
    for the "no propertyID/productID/relationID found / no clicked name
    match" failure paths (`v1:src/Menu/CouponClick.java:56-104`) — a player
    who triggers one of these edge cases (e.g. the property region lookup
    fails) gets **no feedback at all** unless the server has debug mode on.

### `DuelSetupClick.java` — siege-minigame duel-setup GUI

- **Only delegate method** `onClick(InventoryClickEvent e, User user)`
  (`v1:src/Menu/DuelSetupClick.java:45-186`) — not `@EventHandler`; reached
  only via `MenuClick`'s `Menus.DuelSetupMenu` title match
  (`v1:src/Menu/MenuClick.java:303-305`).
  - **Cancellation**: `boolean cancelled = true;` initialized at the top
    (`v1:src/Menu/DuelSetupClick.java:47`), and `e.setCancelled(cancelled)`
    applied unconditionally at the very end (`:185`) — but `cancelled` is
    explicitly flipped to `false` in one specific path: when the clicked
    slot is in the sender's/target's designated "item bet" slot list
    (`invite.senderItemList`/`targetItemList`) **and** that side's "ready"
    item currently reads `"Unready"` (`v1:src/Menu/DuelSetupClick.java:112-121`,
    `:171-180`) — i.e. **this is an intentional, narrowly-scoped
    uncancel**, allowing players to physically place/remove bet items in
    those specific slots while not-yet-ready. This is correct-by-design, not
    a bug, but worth flagging as the one deliberate exception to
    "menu-click events should be cancelled" found in this slice.
  - **Trigger**: matches the clicking player's UUID against an active
    `DuelInvite` (`DuelCommands.inviteList`,
    `v1:src/Menu/DuelSetupClick.java:52-61`), determines whether they're the
    `sender` or `target`, and checks the clicked slot against
    `senderClickList`/`senderItemList` or `targetClickList`/`targetItemList`
    (fields on `DuelInvite`, out of scope), then does display-name matching:
    `"back"`, `"unready"`, `"ready"`, and a `"Duel type: "` prefix that
    branches further on the clicked item's **Material** (`GOLD_BLOCK` →
    coins, `CHEST` → items, `WOOD_SWORD` → practice) to cycle the duel type
    (`v1:src/Menu/DuelSetupClick.java:72-121`, mirrored for target at
    `:132-181`).
  - **Goal**: cycles duel-type selection, toggles ready/unready (blocked if
    the two sides' duel types don't match,
    `v1:src/Menu/DuelSetupClick.java:78-88`), and on `"Duel type: "` +
    `GOLD_BLOCK` + shift-left-click, opens a chat-based coin-bet-amount
    prompt (`coinBetList.put(...)`, closes inventory, asks player to type an
    amount — `:96-101`). `checkReady(...)`
    (`v1:src/Menu/DuelSetupClick.java:232-269`) fires once both sides are
    `"Ready"`: collects bet items from designated free slots
    (`menu.duelMenuFree`), deducts the coin bet from both users, removes the
    invite, and starts a `Duel` (`Arenas.Duel`).
- **Event**: `InventoryDragEvent` (`onDrag`,
  `v1:src/Menu/DuelSetupClick.java:188-230`) — **is** a registered
  `@EventHandler`, independent of the dispatcher (drag events aren't routed
  through `MenuClick` at all). **Trigger**: the player's currently-open top
  inventory's title (stripped) equals `"choose duel-type and place bets!"`
  (`v1:src/Menu/DuelSetupClick.java:197`). **Cancellation**: only cancelled
  if that side (sender or target) is already `"Ready"`
  (`v1:src/Menu/DuelSetupClick.java:214-225`) — otherwise an uncancelled
  drag is allowed through, consistent with the item-bet-slot design intent
  above.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `siege-minigame`** (duel setup, `Arenas.Duel`/`DuelInvite`) —
  explicitly the dual-nature case the task brief calls out.
- **Bugs/edge cases**:
  - `ItemStack item = e.getCurrentItem();` then `item.hasItemMeta()`
    (`v1:src/Menu/DuelSetupClick.java:68-69`, mirrored `:128-129`) — **no
    null-check** on `getCurrentItem()`. Reached only if the clicked slot is
    in `senderClickList`/`senderItemList` (or target equivalents), so
    whether an empty slot can be in those lists is unclear/out of scope
    (`DuelInvite` construction not read), but if any designated bet/click
    slot can legitimately be empty (e.g. a bet slot with no item placed
    yet), this is a reachable NPE.
  - `checkReady`'s coin-bet extraction
    (`v1:src/Menu/DuelSetupClick.java:245-248`) parses the lore of slot 48
    by splitting on `": "` and taking `[1]` — fragile string-format
    dependency typical of this codebase; no defensive check that the lore
    line actually matches the expected `"...: <number>"` shape before
    `Integer.valueOf(...)`.

### `FriendManagerClick.java` — social friends UI

- **Event** (registered, independent): `InventoryClickEvent` (`Onclick`,
  `v1:src/Menu/FriendManagerClick.java:31-76`). **Trigger**: inventory title
  (stripped) contains `"Friend request from "`
  (`v1:src/Menu/FriendManagerClick.java:53`). **Cancellation**:
  `e.setCancelled(true)` only inside the `if (clicked.hasItemMeta())` branch
  (`:55-59`) — if the clicked item has no meta (e.g. empty slot, since
  `clicked` itself is never null-checked — see Bugs), the click is **not**
  cancelled. **Goal**: parses the target username out of the title itself
  (`menu.getName().split("from ")[1]`, `:57`), and on `"accept"`/`"deny"`/
  `"cancel"` dispatches the corresponding `/request accept|deny <name>`
  command via `Bukkit.dispatchCommand` (`:64-73`) then reopens the friend
  requests list.
- **Delegate methods** (not `@EventHandler`, reached only via `MenuClick`):
  - `ManageFriendsClick(InventoryClickEvent e, User user)`
    (`v1:src/Menu/FriendManagerClick.java:78-100`) — dispatched from
    `Menus.FriendsManagerMenu` (`v1:src/Menu/MenuClick.java:315-317`).
    Cancels unconditionally inside the `hasItemMeta()` branch (`:84`);
    handles `"back"` (returns to personal menu), `"add new friends"`
    (opens add-friends screen), `"you have new friendrequest(s)!"` (opens
    requests screen).
  - `AddFriendsClick(InventoryClickEvent e, User user)`
    (`v1:src/Menu/FriendManagerClick.java:102-129`) — dispatched from
    `Menus.AddFriendsMenu` (`v1:src/Menu/MenuClick.java:297-299`). `"back"`
    returns to the friends manager. Otherwise, resolves the clicked item's
    display name to a UUID via `offlineUser.getUUID(dc)`
    (`:114`), and if the item's **last lore line** (stripped) reads exactly
    `"click here to add!"` (`:120`), dispatches `/friends add <name>`
    (`:122`).
  - `FriendRequestClick(InventoryClickEvent e, User user)`
    (`v1:src/Menu/FriendManagerClick.java:131-147`) — dispatched from
    `Menus.FriendRequestMenu` (`v1:src/Menu/MenuClick.java:312-314`). `"back"`
    returns to the manager; otherwise resolves the clicked display name to a
    UUID and opens a per-target request-option screen.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `social`** (friends/requests, as explicitly named in
  `commands-v1.md`'s domain list) — a clean dual-nature case per the task
  brief.
- **Bugs/edge cases**:
  - `Onclick` (`v1:src/Menu/FriendManagerClick.java:34`) does
    `ItemStack clicked = e.getCurrentItem();` with **no null-check** before
    `clicked.hasItemMeta()` inside the title-match branch (`:55`) — clicking
    an empty slot inside a "Friend request from " inventory throws an NPE
    (and, per the note above, is also the one case in this handler where
    the click is left uncancelled, compounding the risk: a player could
    both crash the handler *and* move items freely on an empty-slot click
    here).
  - `ManageFriendsClick`/`AddFriendsClick`/`FriendRequestClick` all call
    `clicked.getItemMeta()` (`:81, 105, 134`) without a preceding null-check
    on `clicked` itself — safe in practice only because `MenuClick.Onclick`
    already filtered `clicked == null` before delegating
    (`v1:src/Menu/MenuClick.java:79-82`), which is an implicit
    cross-file contract, not something enforced locally.
  - `Onclick`'s username parse `menu.getName().split("from ")[1]`
    (`v1:src/Menu/FriendManagerClick.java:57`) is fragile: if a player's
    username itself happened to contain the substring `"from "`, or the
    title format ever changes, this silently breaks or throws
    `ArrayIndexOutOfBoundsException`.

### `ItemMenuClick.java` — shopkeeper/property-product management UI

- **Event 1** (registered, independent): `InventoryClickEvent` (`onClick`,
  `v1:src/Menu/ItemMenuClick.java:61-376`). **Trigger**: four separate
  inventory-title substring matches, each with its own cancellation
  behavior:
  - `"Overview"` (`v1:src/Menu/ItemMenuClick.java:88-100`) — cancels
    unconditionally (`:91`). Buttons: `"back"` → reopen shop-items manager;
    otherwise resolves the clicked display name to a `productID` and opens
    the property-add-item screen for it.
  - `"Products of "` (`:101-193`) — a shopkeeper's per-property product
    list. Resolves `propertyID` from lore parsed off slot 4
    (street/number/town, `:106-110`). **Only cancels inside the
    `propertyID != null && propertyID != 0` branch** (`e.setCancelled(true)`
    at `:118`) — the `else` branch (`:187-192`, "Something went wrong,
    please notify a staff-member") closes the inventory but **never calls
    `setCancelled`** before that close. Buttons inside the happy path:
    `"exit"` (close), `"Information about "` (open property info),
    `"Asignments"` [sic] (starts a `Transport` minigame-adjacent flow, closes
    inventory), `"Quest"` (routes into the quest-accept/deliver flow — see
    dual-nature note below), `"Sell items to this "` (opens the sell menu),
    plus a loop that opens item-info for any clicked item matching a
    product this property sells (`:176-186`).
  - `"Sell items to "` (`:194-283`) — the sell-back-to-shop screen. Calls
    `checkSellMenu(...)` (recomputes running total) on every click
    regardless of button (`:196`), independent of the specific button
    branches below, all of which are nested inside the same
    `propertyID != null && propertyID != 0` guard as above, with the same
    **uncancelled-`else`-branch** pattern (`:276-281`). Buttons: `"back"`
    (cancel+close), `"financial"`/`" "` (decorative, cancel only),
    `"sell items"` (cancels, sums slots 19-25 by matching display name to a
    product, credits coins, calls `onSell(...)` which fills the property's
    warehouse — `v1:src/Menu/ItemMenuClick.java:626-628`, — closes
    inventory), `"Information about "` (opens property list),
    `"sell instructions"` (decorative, cancel only).
  - `"Add a "` (`:284-344`, only entered if `menu.getItem(1)` has meta and
    is `Material.CHEST`) — the admin "which property sells this product"
    assignment screen. Cancels unconditionally (`:290`). `"back"` returns to
    the shop-item overview; otherwise for every existing property, if the
    clicked display name equals `"propertyname: " + <that property's
    name>`, parses street/number/town out of the clicked item's own lore
    (not slot 4 this time) and, if not already selling that product,
    calls `proproduct.savePropertyProduct(propertyID, productID)` to assign
    it (`:300-343`).
- **Event 2**: `InventoryDragEvent` (`onDrag`,
  `v1:src/Menu/ItemMenuClick.java:576-589`) — independent `@EventHandler`.
  **Trigger**: title contains `"Sell items to "`. **Goal**: for every
  dragged-into raw slot, re-runs `checkSellMenu(...)`. No explicit
  cancellation call in this handler itself (relies on the click handler's
  own cancellation state / the sell-menu's slot layout to constrain
  drag-drop).
- **Event 3**: `InventoryCloseEvent` (`onClose`,
  `v1:src/Menu/ItemMenuClick.java:591-624`) — independent `@EventHandler`.
  **Trigger**: title contains `"Sell items to "`. **Goal**: one tick later
  (`scheduleSyncDelayedTask`, delay 10), returns any items still sitting in
  slots 19-25 to the player's inventory, or drops them on the ground if the
  inventory is full (`:604-615`) — a safety net so items placed for sale
  aren't lost if the player closes without clicking "sell items."
- **Delegate method** `ShopItemsManagerClick(InventoryClickEvent e, User
  user)` (`v1:src/Menu/ItemMenuClick.java:378-393`) — **not**
  `@EventHandler`; reached only via `MenuClick`'s
  `Menus.ShopItemsManagerMenu` match (`v1:src/Menu/MenuClick.java:333-335`).
  Cancels unconditionally (`:382`); `"back"` returns to personal menu;
  otherwise if the clicked display name matches a known product category
  name, opens that category's shop-item screen (`openShopItem`).
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `items`/property-economy** — this entire file is shopkeeper
  and property-product administration (buying, selling, assigning which
  property sells which product, warehouse fill-on-sell) layered on top of
  generic menu chrome; it is not "menu logic" in a generic sense at all.
  The `"Quest"` button inside the `"Products of "` branch
  (`v1:src/Menu/ItemMenuClick.java:132-171`) additionally reaches into the
  `Quests` package (`Quest`, `QuestDeliverPackage`) — a second dual-nature
  seam inside the same handler, distinct from `QuestMenuClick.java`'s own
  dedicated quest-delivery screen.
- **Bugs/edge cases**:
  - **Uncancelled-on-error paths**: both the `"Products of "` and `"Sell
    items to "` branches leave the click **uncancelled** whenever
    `propertyID` resolution fails (`v1:src/Menu/ItemMenuClick.java:187-192`,
    `:276-281`) — an admin-data-integrity edge case (a shopkeeper GUI opened
    against a location with no resolvable property), but if it occurs, the
    player's click in that shopkeeper inventory goes through un-cancelled
    before the inventory is closed on the same tick — a narrow but real
    theft-risk window, and explicitly the kind of bug the task asked to
    flag.
  - Missing `hasItemMeta()`/null-checks before dereferencing
    `getItemMeta()`: `String dc = ChatColor.stripColor(clicked.getItemMeta().getDisplayName());`
    in the `"Overview"` branch (`v1:src/Menu/ItemMenuClick.java:90`) and the
    `"Add a "` branch (`:288`) both dereference `clicked.getItemMeta()`
    directly with no `hasItemMeta()` guard (contrast with the `"Sell items
    to "` branch, which does check `clicked.hasItemMeta()` at line 207) —
    inconsistent defensive style within the same file/method.
    `ShopItemsManagerClick` (`:381`) has the same gap.
  - `checkSellMenu`'s parameters `clickSlot`/`dragItem` are accepted but
    **never used** in the method body (`v1:src/Menu/ItemMenuClick.java:521-574`)
    — it always recomputes from scratch over the fixed slot range 19-25
    regardless of which slot triggered it; not a bug per se (the fixed-range
    recompute is self-correcting) but dead parameters worth flagging for
    cleanup.
  - `openShopItem` (`v1:src/Menu/ItemMenuClick.java:401-417`) puts the newly
    created inventory into `MenuClick.propertylistmap` (`:410`) — a map
    named for the *property list* menu, not the shop-item menu — a
    naming/bookkeeping mismatch that could cause this session to be
    misidentified or overwritten by actual property-list-menu logic
    elsewhere (out of scope to confirm the consumer side, but the map choice
    itself is visibly wrong for what it's used for here).

### `OwnedhousesClick.java` — property-domain "my houses" UI

- **Delegate method** `onClick(InventoryClickEvent e, User user)`
  (`v1:src/Menu/OwnedhousesClick.java:59-295`) — not `@EventHandler`;
  reached only via `MenuClick`'s `Menus.OwnedHousesMenu` match
  (`v1:src/Menu/MenuClick.java:426-428`). Handles **four** distinct
  logical screens inside one method body, disambiguated by which static
  session map currently contains the player's UUID and/or by exact
  inventory-title match, each with its own `e.setCancelled(true)`:
  1. `MenuClick.ownedhousesmap` (the main owned-houses list,
     `v1:src/Menu/OwnedhousesClick.java:72-221`) — cancels at line 86.
     Handles an active room/house tutorial specially (`:87-109`), else
     `"back"` (personal menu), `"buy a new house"` (opens house list if
     under cap, else error), `"rent a room"` (opens room list if the player
     has 0 rooms, else error), `"housename"` (parses a structure ID out of
     lore via `menu.getMenuStructureID`, opens per-house info screen),
     `"roomnumber"` (parses a room number and opens the room-sell-confirm
     screen), `"empty!"`/`"empty (room)!"` (open house/room list at page 0),
     `"locked!"` (parses a title-gate requirement out of lore and, if the
     required title ID is 5/10/15, schedules a `MenuItemBlink` highlight
     effect one second later — `:184-213`; also opens donator info if the
     lock line mentions `"Noble"`/`"Royal"`/`"Dragon Blood"`).
  2. `housemenu` (single-house info screen, `:223-239`) — cancels at line
     227. `"sell"` opens the sell-confirm screen; `"back"` returns to the
     owned-houses list.
  3. Exact title `"house sale"` (`:240-268`) — cancels at line 242. Parses
     the house name out of slot 4's lore by splitting on spaces and taking
     token `[7]` (fragile positional parse, `:243-245`). `"confirm"` calls
     `house.sellHouse(...)`, clears the player's spawnpoint if it was set to
     this house, removes the session, reopens owned-houses; `"cancel"`/
     `"back"` both just reopen the single-house info screen.
  4. Exact title `"stop renting a room"` (`:269-289`) — cancels at line 271.
     Parses a room ID out of slot 4's own display name (`"Confirmation " +
     roomID`, split, `:272`). `"confirm"` calls `room.sellRoom(...)` and
     returns to owned-houses; `"cancel"`/`"back"` return to owned-houses
     too.
  5. Exact title `"choose a house to remove"` (`:290-293`) — **empty
     if-block, no cancellation, no logic at all**. This screen's clicks are
     handled entirely passively — see `ForcedHouseRemoveClick` below for
     the *actual* click handling of this screen's equivalent menu content
     (dispatched separately by `MenuClick` under the
     `Menus.ForcedHouseSell` title, not this one — the two titles/paths
     appear to be near-duplicates; confirming whether `"choose a house to
     remove"` is ever actually opened as its own distinct menu vs. dead code
     is unclear/out of scope for this read).
- **Event**: `InventoryCloseEvent` (`onClose`,
  `v1:src/Menu/OwnedhousesClick.java:297-348`) — independent
  `@EventHandler`. **Trigger**: title equals `"choose a house to remove"`.
  **Goal**: force-removes house ownership from any house the closing player
  owns that isn't their current spawnpoint (prioritized), or any owned
  house at all if they're still over their house cap after that, looping
  until they're back under the cap (`:318-346`) — i.e. **closing this menu
  without complying is punished by forced property loss**, not just
  re-prompted. Both `if`/`else` branches at `:324-344` execute the exact
  same `RemoveHouseOwner` + message logic — the branching condition
  (whether the house is the current spawnpoint) has **no actual effect on
  behavior**, which looks like an incomplete implementation (the intent was
  presumably to prefer removing non-spawnpoint houses first, but both paths
  do the same thing).
- **Delegate method** `ForcedHouseRemoveClick(InventoryClickEvent e, User
  user)` (`v1:src/Menu/OwnedhousesClick.java:350-379`) — reached via
  `MenuClick`'s `Menus.ForcedHouseSell` match
  (`v1:src/Menu/MenuClick.java:306-308`). Cancels unconditionally
  (`:355`). On a `"housename: "`-prefixed click, parses street/number/town
  out of the clicked item's lore, resolves a `houseID`, force-removes
  ownership, and if the player is still over their house cap, reopens the
  same forced-sell menu (`:369-373`) — this is the actual sell-until-under-
  cap UI; `onClick`'s "choose a house to remove" branch above appears to be
  a vestigial/duplicate path.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `property`** (houses/rooms — explicitly the dual-nature case
  the task brief names for this file).
- **Bugs/edge cases**:
  - `String dc = ChatColor.stripColor(clicked.getItemMeta().getDisplayName().toLowerCase());`
    and `List<String> lore = clicked.getItemMeta().getLore();`
    (`v1:src/Menu/OwnedhousesClick.java:70-71`) are evaluated **before**
    any of the four screen-specific `if` blocks and **before** any
    null-check on `clicked` or `clicked.hasItemMeta()` — an empty-slot
    click (`clicked == null`) or a metaless item throws an NPE immediately,
    for *every* screen this method handles, not just one.
  - The dead `"choose a house to remove"` `if`-block with no cancellation
    (`v1:src/Menu/OwnedhousesClick.java:290-293`) — if this title is ever
    actually opened as a menu of its own (as opposed to `ForcedHouseSell`
    always being used instead), clicks inside it would be completely
    uncancelled, a theft-risk gap; unclear/out of scope whether any `Menu`
    method actually opens an inventory with exactly this title.
  - The `onClose` if/else with identical bodies
    (`v1:src/Menu/OwnedhousesClick.java:324-344`) — logic bug (dead
    branching condition), flagged above.
  - Positional lore/title parsing (`confirmnamesplit[7]`,
    `"Confirmation ".split(...)[1]`) is fragile to any format change, same
    pattern flagged repeatedly across this codebase.

### `OwnedpropertiesClick.java` — property-domain "my properties" UI

- Structurally a near-mirror of `OwnedhousesClick.java` for properties
  instead of houses/rooms (no room-rental equivalent, since properties
  don't have a room sub-concept).
- **Delegate method** `onClick(InventoryClickEvent e, User user)`
  (`v1:src/Menu/OwnedpropertiesClick.java:57-203`) — not `@EventHandler`;
  reached via `MenuClick`'s `Menus.OwnedPropertyMenu` match
  (`v1:src/Menu/MenuClick.java:429-431`). Three screens:
  1. `MenuClick.ownedpropertiesmap` (main list, `:69-156`) — cancels at
     line 75. `"back"`, `"buy a new property"` (list vs. cap-error, same
     pattern as houses), `"propertyname"` (opens per-property info),
     `"empty!"` (opens property list page 0), `"locked!"` (same title-gate
     blink-highlight + donator-info logic as `OwnedhousesClick`,
     `:107-155`).
  2. `propertymenu` (single-property info, `:158-175`) — cancels at line
     163. `"sell"` opens sell-confirm; `"back"` returns to list.
  3. Exact title `"property sale"` (`:176-201`) — cancels at line 179.
     Same fragile `confirmnamesplit[7]` positional-parse pattern as houses
     (`:180-183`). `"confirm"` → `property.sellProperty(...)`, removes
     session, reopens owned-properties list; `"cancel"`/`"back"` reopen the
     single-property info screen.
  - Unlike `OwnedhousesClick`, there is **no** dead/empty
    `"choose a house/property to remove"` branch here — the forced-sell
    flow is handled entirely by `ForcedPropertySellClick` below.
- **Event**: `InventoryCloseEvent` (`onClose`,
  `v1:src/Menu/OwnedpropertiesClick.java:205-256`) — independent
  `@EventHandler`, title `"choose a property to remove"`. Same forced-removal
  loop as `OwnedhousesClick.onClose`, and the **same identical if/else-bodies
  bug** (`:242-252` — the spawnpoint-preference branch has no actual effect
  on behavior).
- **Delegate method** `ForcedPropertySellClick(InventoryClickEvent e, User
  user)` (`v1:src/Menu/OwnedpropertiesClick.java:258-287`) — reached via
  `MenuClick`'s `Menus.ForcedPropertySell` match
  (`v1:src/Menu/MenuClick.java:309-311`). Same pattern as the house
  equivalent: cancels unconditionally, parses location from lore, removes
  ownership, reopens itself if still over cap.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `property`** — same dual-nature case as `OwnedhousesClick`,
  explicitly named in the task brief.
- **Bugs/edge cases**:
  - `List<String> lore = clicked.getItemMeta().getLore();`
    (`v1:src/Menu/OwnedpropertiesClick.java:68`) — same pre-branch,
    no-null-check pattern as `OwnedhousesClick.java:70-71`; an empty-slot
    click throws immediately, before any of the three screen branches (and
    before their `setCancelled` calls) are reached.
  - `dc` is computed fresh, separately, inside each of the three screen
    branches here (`:74, :162, :178`) rather than once up-front like
    `OwnedhousesClick` does — meaning the pre-branch NPE risk is scoped to
    `lore` only for this file (still a null-check gap, just smaller than
    the sibling file's).
  - Same identical-if/else-bodies dead-condition bug in `onClose` as
    `OwnedhousesClick`.
  - Same positional lore-splitting fragility (`confirmnamesplit[7]`).

### `PlayerManagerClick.java` — staff/admin player-moderation UI

- **Event** (registered, independent): `InventoryClickEvent` (`Onclick`,
  `v1:src/Menu/PlayerManagerClick.java:137-436`). **Trigger**: title
  (stripped) contains both `"Edit"` and `"statistics"`
  (`v1:src/Menu/PlayerManagerClick.java:161`). **Cancellation**: only inside
  `if (clicked.hasItemMeta())` (`:163-166`) — if the clicked item has no
  meta, the click is left uncancelled (same pattern flagged in
  `FriendManagerClick`), though `clicked` itself is never null-checked
  before that `hasItemMeta()` call (`:163`), so an empty-slot click NPEs
  before the cancellation question is even reached.
  - **Goal**: this is a full staff moderation console for a single target
    player, parsed by username straight out of the inventory title
    (`menuname.split(" ")[1]`, `:167-168` — fragile if a username itself
    contains a space-adjacent token position mismatch, though Minecraft
    usernames can't contain spaces so this specific parse is actually safe
    in practice). Buttons cover: `"back"`, `"kick player"` /
    `"ban player"` (dispatches `/kick`/`/ban` as the acting staff member,
    `:185-194`), `"save changes"` (reopens the screen to refresh displayed
    values — `:195-198`, does **not** appear to persist anything beyond
    what individual buttons already wrote through, despite the "changes
    will be lost" warning baked into the GUI item's lore at
    `v1:src/Menu/PlayerManagerClick.java:559`), `"promote"`/`"demote"`
    (sets target's experience to the min/max of the next/previous title
    via `/experience set`, `:199-210`), `"give highest title"` (title 18,
    `:211-217`), a large family of per-stat step-cycle buttons for
    experience/coins/gems/kills/deaths (click the stat display to cycle its
    click-increment step size — `setExpStep`/`setCoinStep`/`setGemStep`/
    `setKillStep`/`setDeathStep`, `:625-793`), matching
    add/remove/set-max buttons that call `/experience`, `/coins`, `/gems`,
    `/kills` commands or direct `User` setters (`:224-299, :348-417`),
    salary/income cooldown reset and instant-payout buttons (fires custom
    `SalaryPayoutEvent`/`IncomePayoutEvent`, `:300-347`), skillpoint/special
    -skillpoint add/remove (`:394-417`), and donator-title
    view/set-to-Noble/Royal/DragonBlood buttons that dispatch `/donator
    remove|set ...` (`:418-433`).
- **Delegate method** `PlayerManagerClick(InventoryClickEvent e, User user)`
  (`v1:src/Menu/PlayerManagerClick.java:438-497`) — note the method shares
  its name with the class itself; not `@EventHandler`, reached via
  `MenuClick`'s `Menus.PlayerManagerMenu` match
  (`v1:src/Menu/MenuClick.java:324-326`). This is the **roster** screen
  (list of online players to pick a target from), not the stat-edit screen
  above. Cancels unconditionally (`:446`). `"back"` returns to personal
  menu. Otherwise, for every online player, applies a three-tier permission
  gate (`v1:src/Menu/PlayerManagerClick.java:451-496`): if any online
  player outranks the acting player (`owner` perm and acting player lacks
  it), sends a blanket `"You can't modify this player!"` message
  **regardless of which player was actually clicked** — a broken-looking
  early message that fires once per online `owner`-permission player found
  in the loop, not gated to the specific clicked target; staff (not owner)
  can open non-staff, non-owner targets; owner/co-owner can open anyone
  they specifically clicked (or, per the `||` at `:477`, a co-owner can
  open **anyone at all**, since `player.hasPermission(coowner)` alone
  satisfies the whole condition regardless of which name was clicked —
  see Bugs).
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is `users`/staff-moderation and `economy`** (coins/gems/salary/
  income are directly mutated here) — this is squarely a `users`-domain
  admin tool wearing an inventory-menu skin, as the task brief anticipated
  calling out for this file.
- **Bugs/edge cases**:
  - **Broken/over-broad permission check**: the condition at
    `v1:src/Menu/PlayerManagerClick.java:477`,
    `player.hasPermission(owner) && dc.equalsIgnoreCase(players.getName() +
    "'s information") || player.hasPermission(coowner)`, is missing
    parentheses around the intended `(A && B) || C` grouping vs. what Java
    actually evaluates it as — which **is** `(A && B) || C` by operator
    precedence, so it's not a precedence bug, but the practical effect is
    still a real access-control bug: **any co-owner can open the
    stat-editor for any online player regardless of which item they
    clicked**, because `player.hasPermission(coowner)` alone short-circuits
    the whole `||` true on every iteration of the `for (Player players :
    Bukkit.getOnlinePlayers())` loop (`:451`) — meaning a co-owner clicking
    literally any item in the roster menu opens **the last online player
    iterated**, not the one they clicked, once the loop reaches a `players`
    entry that isn't gated out by the `owner`-outranks check above it. This
    is a real "wrong target" moderation bug, not just a permission-scope
    concern.
  - `clicked.getItemMeta().getDisplayName()` in `PlayerManagerClick(...)`
    (`v1:src/Menu/PlayerManagerClick.java:445`) has no `hasItemMeta()`
    guard.
  - `"save changes"` button's lore explicitly warns "Don't forget to save or
    changes will be lost" (`v1:src/Menu/PlayerManagerClick.java:559`), yet
    every mutating button (add/remove coins, gems, experience, kills,
    deaths, skillpoints, donator title, kick/ban) calls straight through to
    `player.performCommand(...)` or direct `User` setters immediately on
    click — there is no evidence in this file of any staged/unsaved state
    that `"save changes"` actually commits; it appears to just refresh the
    displayed numbers. Whether this is misleading UI copy or whether some
    other unread file batches changes is unclear/out of scope, but as
    presented in this file, every button is already live.
  - Step-cycle buttons (e.g. `"remove experience"`) read the **adjacent
    slot's** lore (`menu.getItem(slot+1)` or `slot-1`) to find the
    currently-selected step size (`v1:src/Menu/PlayerManagerClick.java:226-230`
    and throughout) — a purely positional-adjacency contract between the
    stat-display item and its neighboring cycle-step item, with no
    validation that the neighbor is actually the expected item type; if the
    GUI layout is ever edited, this silently breaks.

### `QuestMenuClick.java` — quest item-delivery UI

- **Event 1** (registered, independent): `InventoryClickEvent` (`onClick`,
  `v1:src/Menu/QuestMenuClick.java:44-179`). **Trigger**: title equals
  `"Deliver items for quest"` (`:72`). **Cancellation**: title-level guard
  first resolves `propertyID` via `Menus.getPropertyIDByInfoItem(menu.getItem(5))`
  (`:74`); if that fails, `e.setCancelled(true)` **is** called
  (`:77`) before broadcasting a developer-facing diagnostic message and
  bailing (`:78-89`) — unlike the analogous failure paths in
  `ItemMenuClick.java`, this one does cancel on the error path. Once
  `propertyID` resolves, individual buttons cancel their own branches:
  `"back"` (close inventory, `:93-97`), `"social profile"` (decorative,
  `:98-101`), `" "` (decorative, `:102-105`), `"Information about "`
  (`:106-109`), `"Quest: "` prefix (decorative, `:110-113`), and
  `"deliver items"` (`:114-177`) which iterates slots 19-25, validates each
  item against the quest's required `productID` (from either a
  `QuestHarvestResource` or `QuestDeliverPackage` cast of
  `Properties.Properties.ActiveQuests.get(propertyID)`), returns
  non-matching/unmetadata items to the player with an error message, and
  calls `rq.Deliver(item)`/`QDP.Deliver(item)` for matching ones, closing
  the inventory if the quest becomes `isCompleted()` (`:169-172`).
- **Event 2**: `InventoryDragEvent` (`onDrag`,
  `v1:src/Menu/QuestMenuClick.java:181-194`) — independent, title contains
  `"Deliver items for quest"`, re-runs `checkSellMenu(...)` per dragged
  slot (mirrors `ItemMenuClick`'s pattern almost exactly, including the
  method name `checkSellMenu` reused here for a delivery, not a sale — a
  naming leftover from copy-pasting the sell-menu pattern).
- **Event 3**: `InventoryCloseEvent` (`onClose`,
  `v1:src/Menu/QuestMenuClick.java:196-229`) — independent, title contains
  `"Deliver items for quest"`; same "return-or-drop items still in slots
  19-25 one tick later" safety net as `ItemMenuClick.onClose`.
- **Feature allocation**: **UI shell is `inventory-menus`, underlying
  feature is a `Quests` package feature not currently named in
  `commands-v1.md`'s domain list at all** (`items`, `inventory-menus`,
  `social`, `siege-minigame`, `property`, `towns`, `economy`, `users`,
  `world-admin`, `misc` are the categories that doc defines; none of them
  is "quests"). Given both this file and `ItemMenuClick.java`'s `"Quest"`
  button (`v1:src/Menu/ItemMenuClick.java:132-171`) independently reach
  into the same `Quests`/`Properties.Properties.ActiveQuests` machinery,
  this is worth flagging explicitly for v3 domain planning: quests may
  deserve their own top-level feature-domain folder rather than being
  folded into `items` or `property`.
- **Bugs/edge cases**:
  - `if (clicked == null || !clicked.hasItemMeta()) { return; }`
    (`v1:src/Menu/QuestMenuClick.java:65-68`) — this is the **only** file
    in the whole Menu family that null-checks *and* meta-checks the clicked
    item up front, correctly, before any further logic. Worth noting as the
    positive counter-example to the missing-null-check pattern flagged
    repeatedly elsewhere in this slice.
  - Same caveat as `ItemMenuClick`: this early return happens **before** any
    `e.setCancelled(true)` call for the general case (only the
    `propertyID == null` branch explicitly cancels) — so an empty-slot click
    inside the delivery menu, on a valid property, is **not cancelled**,
    same theft-risk-adjacent pattern as `MenuClick`/`ItemMenuClick`'s
    empty-slot gap, just scoped to this one menu instead of dozens.
  - `checkSellMenu`'s parameters `clickSlot`/`dragItem` are, again,
    unused in the body (`v1:src/Menu/QuestMenuClick.java:231-293`), same as
    `ItemMenuClick`'s copy of the same pattern.
  - `itemMeta.getDisplayName()` at `v1:src/Menu/QuestMenuClick.java:143-144`
    (inside the `"deliver items"` loop) is called on
    `menu.getItem(i).getItemMeta()` **after** the preceding `if` already
    established the item might have no meta (`:137`) and pushed it back to
    the player — but the following lines (`:143` onward) unconditionally
    re-fetch `menu.getItem(i)` and its meta regardless of whether that
    `if` branch executed, i.e. after an item has just been removed from
    slot `i` and returned to the player (`menu.setItem(i, new
    ItemStack(Material.AIR, 1))`, `:140`), the code falls through and still
    calls `.getItemMeta()` on the now-AIR item at `:143` — `AIR` items have
    no meta, so this throws immediately after the very branch meant to
    handle "this item is invalid" runs. This looks like a genuine logic bug
    (missing `continue`/`else` after the invalid-item branch), not just a
    missing guard.
  - The duplicated `checkSellMenu(player, menu, e.getRawSlot(),
    e.getCurrentItem())` call both before (`:90`) and after (`:176`) the
    `"deliver items"` handling in `onClick` recomputes the running delivery
    total twice per click on that button — redundant but not incorrect.

## Cross-file bug/edge-case summary (quick reference)

- **Uncancelled empty-slot clicks inside tracked menus** — the single
  largest theft/dupe-relevant pattern found. Present in: `MenuClick.Onclick`
  (affects the entire `pmenu`-gated dispatcher tree at once,
  `v1:src/Menu/MenuClick.java:79-82`), `ItemMenuClick.onClick`
  (`v1:src/Menu/ItemMenuClick.java:82-85`), and, narrower in scope, the
  `hasItemMeta()`-only cancellation gates in `FriendManagerClick.Onclick`
  (`v1:src/Menu/FriendManagerClick.java:55`) and
  `PlayerManagerClick.Onclick` (`v1:src/Menu/PlayerManagerClick.java:163`).
- **Uncancelled property-resolution-failure branches** in
  `ItemMenuClick.java` (`:187-192`, `:276-281`) — narrow window, admin-data
  edge case, but a real theft-risk window per the task's explicit ask.
- **NPE risk from missing null-check on `getCurrentItem()`/`getItemMeta()`
  before any screen-dispatch logic**, evaluated unconditionally up front:
  `OwnedhousesClick.onClick` (`v1:src/Menu/OwnedhousesClick.java:70-71`),
  `OwnedpropertiesClick.onClick` (`v1:src/Menu/OwnedpropertiesClick.java:68`),
  `EnchantbookClick.onInvClick` (`v1:src/Products/EnchantbookClick.java:93-94`
  — especially exposed since the "menu" it watches is the player's entire
  own inventory), `DuelSetupClick.onClick`
  (`v1:src/Menu/DuelSetupClick.java:68-69, 128-129`).
- **Logic bug (dead conditional branch)**: identical if/else bodies in
  `OwnedhousesClick.onClose` (`v1:src/Menu/OwnedhousesClick.java:324-344`)
  and `OwnedpropertiesClick.onClose`
  (`v1:src/Menu/OwnedpropertiesClick.java:242-252`) — the
  spawnpoint-priority condition has zero effect on behavior.
  `QuestMenuClick.onClick`'s post-invalid-item fallthrough
  (`v1:src/Menu/QuestMenuClick.java:137-150`) similarly reaches dead/
  throwing code after the branch meant to handle the case has already run.
- **Access-control bug**: `PlayerManagerClick.PlayerManagerClick(...)`'s
  co-owner branch (`v1:src/Menu/PlayerManagerClick.java:477`) opens the
  wrong target player's stat editor for co-owners, due to the permission
  check short-circuiting independent of which roster item was actually
  clicked.
- **Feature-scope discovery, not a code bug**: `SoulboundEvents.java`'s
  death-protection logic is fully commented out
  (`v1:src/Products/SoulboundEvents.java:29-64`) — soulbound items are
  currently drop-protected only, not death-protected, contrary to what the
  feature name implies.
- **Fragile positional string parsing** (split-and-index into lore/title/
  display-name strings with no format validation) recurs across nearly
  every file in the Menu family — cited per-file above rather than
  repeated here.

## Feature-domain dual-nature summary (for v3 planning)

| File | UI shell domain | Actual underlying feature |
|---|---|---|
| `CouponClick.java` | `inventory-menus` | `items` / property-economy (coupon & coin product purchase) |
| `DuelSetupClick.java` | `inventory-menus` | `siege-minigame` (duel setup) |
| `FriendManagerClick.java` | `inventory-menus` | `social` (friends/requests) |
| `ItemMenuClick.java` | `inventory-menus` | `items` / property-economy (shopkeeper buy/sell/assign), with a secondary seam into `Quests` via its `"Quest"` button |
| `MenuClick.java` | `inventory-menus` (the one file that *is* legitimately this domain) | routes to nearly every other domain; also directly performs two `items` bulk-admin actions in-line |
| `OwnedhousesClick.java` | `inventory-menus` | `property` (houses/rooms) |
| `OwnedpropertiesClick.java` | `inventory-menus` | `property` |
| `PlayerManagerClick.java` | `inventory-menus` | `users` (staff moderation: rank/title/donator, kick/ban) + `economy` (coins/gems/salary/income mutation) |
| `QuestMenuClick.java` | `inventory-menus` | a `Quests` package feature not currently represented in `commands-v1.md`'s domain taxonomy — candidate for its own `quests` domain in v3 |
| `EnchantbookClick.java` | none (hijacks the player's own inventory as the picker UI, not a purpose-built GUI) | `items` (product enchanting) |
| `CraftEvents.java`, `DropItem.java`, `SoulboundEvents.java`, `SpecialItemEvents.java`, `Effects/ProductConsume.java` | n/a — no menu component | `items` throughout |

## Counts

- **Files read in full**: 15/15 (6 Products/Effects, 9 Menu).
- **`@EventHandler` methods documented**: 22 total — 8 in the
  Products/Effects half (`CraftEvents.onCraft`; `DropItem.test`,
  `DropItem.test2`; `EnchantbookClick.onClick`, `.onInvClose`,
  `.onInvClick`; `SoulboundEvents.onDrop`; `SpecialItemEvents.onInteract`;
  `Effects/ProductConsume.onConsume`) and 14 in the Menu half
  (`MenuClick.Onclick` ×2 overloads — `InventoryClickEvent` and
  `PlayerInteractEvent`; `CouponClick.onClose`; `DuelSetupClick.onDrag`;
  `FriendManagerClick.Onclick`; `ItemMenuClick.onClick`, `.onDrag`,
  `.onClose`; `OwnedhousesClick.onClose`; `OwnedpropertiesClick.onClose`;
  `PlayerManagerClick.Onclick`; `QuestMenuClick.onClick`, `.onDrag`,
  `.onClose`).
- **Non-`@EventHandler` delegate click-methods documented** (reachable only
  via `MenuClick`'s dispatcher): 12 — `CouponClick.onClick`,
  `DuelSetupClick.onClick`, `FriendManagerClick.ManageFriendsClick`/
  `.AddFriendsClick`/`.FriendRequestClick`, `ItemMenuClick.ShopItemsManagerClick`,
  `OwnedhousesClick.onClick`/`.ForcedHouseRemoveClick`,
  `OwnedpropertiesClick.onClick`/`.ForcedPropertySellClick`,
  `PlayerManagerClick.PlayerManagerClick`.
- **Confirmed uncancelled-click bugs (dupe/theft-relevant)**: 4 distinct
  patterns across 5 files (`MenuClick`, `ItemMenuClick` ×2 branches,
  `FriendManagerClick`, `PlayerManagerClick`).
- **Confirmed missing-null-check NPE risks on `getCurrentItem()`/
  `getItemMeta()`**: 6 files (`OwnedhousesClick`, `OwnedpropertiesClick`,
  `EnchantbookClick`, `DuelSetupClick`, `FriendManagerClick`,
  `PlayerManagerClick`), with `QuestMenuClick` flagged as the one correct
  counter-example.
- **Dual-nature UI-shell-vs-underlying-feature files flagged**: 8 of 9 Menu
  files (all except `MenuClick.java` itself, which is legitimately the
  `inventory-menus` shell).
