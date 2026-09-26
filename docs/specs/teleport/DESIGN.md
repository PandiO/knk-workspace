# Teleportation Commands — Design

**Status:** Draft — awaiting developer review (open questions in §5)
**Last updated:** 2026-09-26
**Linear:** [KNG-17](https://linear.app/kngpandi/issue/KNG-17/teleportation-staff-tp-tpa-requests-spawn-domain-warps-v1-port)
**Sources:** `knk-v1-archive` (`src/UsefulCommands/PlayerTeleportCommand.java`, `src/UsefulCommands/SpawnCommand.java`,
`src/SpawnPoints/SpawnPoint.java`, `src/SpawnPoints/SpawnPointCommands.java`, `src/Teleport/*`, `src/Houses/HomeCommands.java`,
`src/Menu/Menu.java`, `src/Menu/SpawnpointClick.java`, `src/Listeners/PlayerListener.java`, `src/Main/Main.java`,
`src/DataManager/Towns.java`, `plugin.yml`); `knk-v2-archive` (`listeners/PlayerListener.java`, `model/location/Location.java`,
`model/dominion/*`); `knk-plugin` at `claude/siege-minigame` head `0fa6d06`; `knk-web-api` `cd95dd1`; `knk-web-app` `9a6f347`;
docs `specs/legacy/commands-v1.md`, `commands-v2.md`, `inventory-menu-screens.md`, `user-features/*`, `siege-minigame/*`.
All `v1:`/`v2:` paths are relative to the archive's `src/` (v2: `src/main/java/net/knightsandkings/`); v3 plugin paths are
relative to `knk-paper/src/main/java/net/knightsandkings/knk/paper/` unless prefixed with a module name.

---

## 0. Scope

**In:**
- Staff teleports: self → player, player → player, player → self ("tphere"), self → coordinates, send a player to spawn / a
  domain; silent flag; rank check; audit log.
- Player teleport requests: `/tpa` (go to), `/tpahere` (bring), accept / deny / cancel, expiry.
- `/spawn` (server spawn).
- Domain spawn teleports ("warps", v1 `/point`/`/warp` + the v1 "Teleport to points on the map" menu): Town / District /
  Structure `Domain.Location` as the destination, per-domain enablement, gem price, title / premium-tier requirements,
  optional discovery requirement.
- The shared engine: warmup with movement/damage cancel, cooldown, combat tag, safe-location check, async chunk-safe
  teleport, and the guards (siege match, siege area lockdown, admin freeze, vanish, domain AllowEntry/AllowExit).
- `/back` to point of death — optional last phase, pending §5 Q5.

**Out (explicitly):**
- `/home` and house/room/property spawnpoints — the v1 property system has no v3 model and structure ownership is
  shelved (vision §4.5, `legacy/inventory-menu-screens.md` "Structures … shelved 2026-09-25"). Revisit with that feature.
- Setting a domain's spawn point in-game — already covered by the existing Location field on Domain forms (web-app
  FormWizard + `tasks/LocationTaskHandler.java` "type save" world task). No `/spawnpoint` CRUD port.
- Join / respawn location policy (`GameSettings.DefaultRespawnPolicyJson`, the hard-coded respawn town `4`) — a
  separate world-settings concern; only the `/spawn` destination reuses `GameSettings.JoinSpawnReference`.
- Arena/duel/tutorial/AFK/treasure/ocelot spawnpoints (v1 minigames not in v3).
- Siege-internal teleports (hub, spawn picker, vault restore) — owned by `specs/siege-minigame`; this design only adds
  guards so ordinary teleports cannot interfere with a match.
- A `/tptoggle` "block all requests" setting (no legacy precedent; easy follow-up).

---

## 1. Legacy design

### 1.1 v1

**Permission nodes** (hard-coded strings, `sender.hasPermission`): `k&k.teleport.normal`, `k&k.teleport.staff`,
`k&k.teleport.owner` (the last two only select help text), `k&k.spawn`, `k&k.spawn.others`, `k&k.home`, `k&k.spawnpoint`.
`/point`/`/warp` has **no** permission check. Staff power is mostly gated by the in-memory owner-mode map
`Main.ownermodus` (`v1:Main/Main.java:280`), not by a node.

**Commands** (`v1 plugin.yml:64-65, 93-98, 133-138`; executors wired `v1:Main/Main.java:623-654`):

| Command | Behaviour | Source |
|---|---|---|
| `/tpa <p1> <p2> [silent\|s]` (owner mode) | Intended: teleport p1 to p2, optionally without messages to p1/p2. **Dead**: guard `Bukkit.getOnlinePlayers().contains(args[0])` compares `Collection<Player>` to a `String`, always false. | `UsefulCommands/PlayerTeleportCommand.java:80-108` |
| `/tpa <player> spawnpoint\|sp` (owner mode) | Only working `/tpa` path: teleports the sender to the target's **house** spawnpoint. Bugs: `!= "spawn"` reference compare (`:130`), no `break` after the match so every non-matching house prints "An error occured … contact Pandi" (`:133-148`). | `:110-156` |
| `/tpa <player>` (owner mode) | Intended: instant self → player. **Dead** (same `contains(String)` bug at `:163`) — always answers "not online"/"can't find". | `:161-176` |
| `/tpa <player>` (`k&k.teleport.normal`) | Requires `coins >= 10000` (`:185`); **dead** (`contains(String)` at `:192`). Intended flow: put sender in `Main.teleportconfirm` with `30` (s), tell sender "You are about to pay 10000 coins for teleporting, type cancel to cancel the tpa", tell target "type /tpa <accept/deny>". The 30 is never decremented, coins are never charged, `accept`/`a` and `deny`/`d` are empty blocks (`:187-191`). Typing `cancel` in chat clears the map entry (`Listeners/PlayerListener.java:961-969`). | `:181-207` |
| `/spawn [player]` (`k&k.spawn`, `.others`) | Destination = spawnpoint named `"spawn"`. Others: instant, no checks (`:61-76`). Owner mode: instant (`:79-89`). Otherwise: refuse while duelling, then `tryRegularTeleport(user,"spawn")` (`:104-110`). A 3-second delayed version is commented out (`:94-103`). Console → `ClassCastException` (`:39`). Non-op gets no feedback when no spawn is configured. | `UsefulCommands/SpawnCommand.java` |
| `/point <name>` / `/warp <name>` | Spawnpoint must be in the "general" list (`:380`), refuse while duelling (`:383-388`), then `tryRegularTeleport`. | `SpawnPoints/SpawnPointCommands.java:376-399` |
| `/point list` | Lists general spawnpoints with price, additionally hiding names containing `house`/`ocelot` (`:371`); "price is in gems and is paid when teleporting". | `:365-375` |
| `/spawnpoint set <name> <requiredtitle> <requireddonator> <price>` / `remove` / `list` / `rename` / `relocate` (`k&k.spawnpoint`) | Staff CRUD of the `SpawnPoint` table at the sender's position. Bug: the donator argument is resolved through `title.getTitleID` (`SpawnPoint.java:71`). | `SpawnPointCommands.java:65-340` |
| `/home` (`k&k.home`) | Teleports to the user's house/room spawnpoint via `tryRegularTeleport`; owner mode instant; duel check. | `Houses/HomeCommands.java:27-77` |

**Menu:** Personal menu slot 1, COMPASS "Teleport to points on the map" / "Teleport to important points in the world" /
"Price will be paid in gems!" (`Menu/Menu.java:215`). `openTeleportMenu` (`Menu.java:2010-2130`): title "Teleport to
spawnpoints", info tile "Teleportation starts after 3 seconds" + "The prices are paid in gems!" (`:2042` — wrong for
non-premium players, who wait 5 s), one COMPASS per general spawnpoint coloured by required donator tier with
"Price: N" and "Available! Click here to teleport" / "Locked! Reach title X to unlock" / "Locked! Donator-rank X or higher
required!". Click → `tryRegularTeleport` (`Menu/SpawnpointClick.java:37-49`) — **no duel check on this path**.

**Engine — `SpawnPoint.tryRegularTeleport` (`SpawnPoints/SpawnPoint.java:677-741`):**
1. Owner mode → instant teleport, no checks.
2. Spawnpoint must be in `getSpawnPointList(true,false,false,true,false,false)` (general + house + room) else "You can't
   teleport to this location with this command!".
3. `donatorID >= requiredDonatorID` else "You need to have Donator-rank X or higher…"; `titleID >= requiredTitleID` else
   "You need to have the title X or higher…"; `gems >= price` else "You don't have enough gems…".
4. Warmup: **3 s if `donatorID > 0`, else 5 s** ("You need to wait N seconds before teleporting..."), via
   `TeleportDelay.setDelay(uuid, n, location, price, name, immune=false)`.

Spawnpoint categories are derived from **name substrings** (`SpawnPoint.java:120-189`): `house`, `arena`, `ocelot`,
`room`, `property`, `treasure` are excluded unless their flag is set; names containing `new`, `tutorial`, `Tutorial` or
`afk` are always excluded; everything else is "general". Towns got a spawnpoint automatically in the creation wizard:
**name = town name, required title = the town's entry title, price = 10 gems, donator = 0**
(`DataManager/Towns.java:196`), linked through the `TownSpawnPoint` table (`:228`). House/room/property/arena
spawnpoints are created at price 0 with names `house_<id>`, `room_<id>`, … (`HouseCommands.java:351`,
`RoomCommands.java:341`, `PropertyCommands.java:382`, `ArenaCommands.java:317`).

**Warmup/cancel — `Teleport/TeleportDelay.java`:** static maps keyed by UUID; `updateDelay()` (`:161-202`) is called once
per second from the `startvariousTasks` runnable (`Main.java:993-1190`, `runTaskTimer(this, 10*20, 20)`), decrements, and
at 0 calls `executeTeleport` (`:241-312`), which **re-checks and only then deducts gems** ("You paid N gems and your new
balance is M"), renames `house`/`room` destinations to "Home", and says "You teleported to X". Cancellation: **any**
`PlayerMoveEvent` — including pure head rotation, there is no block-change check — cancels with "Teleportation canceled
due to movement!" (`Listeners/PlayerListener.java:471-477`). The dedicated movement/damage listener is entirely commented
out (`Teleport/TeleportMovement.java:17-50`), so **damage never cancelled a warmup**; the "immune" flag is always false.
`TeleportDelay_v2`/`TeleportDelayList_v2` are unused scaffolding (all-static fields).

**Teleport primitive — `SpawnPoint.teleport` (`:773-805`):** calls `isChunkLoaded((int)x,(int)z)` with **block**
coordinates as **chunk** coordinates, then busy-waits on the main thread until that (wrong) chunk loads. Safety helpers
exist but are not used by `tryRegularTeleport`: `canTeleport` (feet + head must be AIR or SNOW, `:807-830`) and
`TeleportNearby` (`:855-890`, unbounded recursion when no spot is safe; `FreeOfPlayers` tests the original location,
not the candidate).

**Restrictions:** the only one is `Arena.isDuelling` (commands, not menu). A combat tag existed — `Main.combat = 10` s,
set on PvP hits (`Listeners/EntityListener.java:360,371`) — but no teleport path checks it. No cooldown after a teleport.
Vanish (owner mode) had no teleport interplay beyond the bypass.

**Advertised, never built:** premium-tier perks list "Dragon blood back-command — Allows one to teleport back to his
point-of-death" and "Dragon blood teleportation — Send teleport invites to players or invite them to teleport to you"
(`Menu.java:2220-2221`); default vs. noble/royal/dragon-blood spawnpoint access "The teleport delay is 5 seconds" /
"3 seconds" (`Menu.java:2183-2216`). No `/back`, `/tpahere`, `/tpaccept` exists in `plugin.yml`.

**Discovery:** v1 had a `DiscoveredTowns` table (`Towns/Town.java:362-372`), used only for first-join routing
(`Users/User.java:3447-3466`: spawn if Kardenna discovered, else the `new` spawnpoint) — **not** for teleport access.

**Other v1 bugs worth not repeating:** `updateDelay` removes from `Delay` while iterating its `keySet()` (`:163,185,194`)
→ `ConcurrentModificationException` when two warmups are active; one missing user aborts every other player's tick
(`return` at `:175/180`).

### 1.2 v2

No teleport command of any kind (`legacy/commands-v2.md:496-502`; v2 `plugin.yml` has none — verified). What exists:
- Join: every non-`k&k.join.owner` player is teleported to the **first town in the repository**
  (`v2:listeners/PlayerListener.java:131-139`; `getList().get(0)` throws on an empty list, so the `null` fallback to
  world spawn is unreachable). Respawn does the same (`:365`).
- `Dominion` gained `location` ("This location can be used as spawn location for players among other things",
  `v2:model/dominion/District.java:282-288`) and `allowEntry` (`model/dominion/Dominion.java:191`).
- `Location.TeleportNearby` (`v2:model/location/Location.java:274-310`) — same algorithm as v1 but recursing with
  `radius+1` forever when nothing is safe. Used by minigame hub/spawn teleports (`model/minigame/MGMember.java:320,331`,
  `MiniGame.java:831`).

### 1.3 v3 today

**Commands:**
- `/knk tp <player>` — `commands/TeleportToPlayerCommand.java`, registered at `commands/KnkAdminCommand.java:374-380`,
  node `knk.admin.tp` (`plugin.yml`, child of `knk.admin`). Resolves both users over REST, `RankHierarchy.actorOutranks`,
  then a synchronous `senderPlayer.teleport(target)` (`:62`). No vanish check, no siege check, no audit, no silent mode,
  no safety check. Default cause is `PLUGIN`, so it **bypasses** the siege lockdown (next bullet).
- `/knk gate admin tp <door|id>` (`knk.gate.admin`) — teleport to a gate anchor, gate feature's own.
- No `/tp`, `/tpa`, `/spawn`, `/warp`, `/back`, `/home` in `knk-paper/src/main/resources/plugin.yml`.

**Reusable pieces:**
- `Domain.LocationId`/`Location` (`knk-web-api:Models/Domain.cs:22-26`), `AllowEntry`/`AllowExit` (`:16-18`); TPT
  subtypes `Town`/`District`/`Structure`. `Location` = X/Y/Z/Yaw/Pitch/World (`Models/Location.cs`). The plugin already
  reads it (`knk-core:domain/towns/TownDetail.java` `location`, `dataaccess/TownsDataAccess`, `LocationsDataAccess`,
  `DomainCatalogDataAccess.searchAsync` — the latter returns only id/name/type).
- `GameSettings.JoinSpawnMode` + `JoinSpawnReferenceJson` (`LocationReferenceDto` with `sourceType`
  Location/Town/District/Structure) — authored in `knk-web-app:src/pages/admin/GameSettingsPage.tsx`, exposed by
  `GET /api/GameSettings`, **never read by the plugin** (the join teleport is hard-coded to world 0's spawn,
  `listeners/PlayerListener.java:177`; respawn to hard-coded town `4`, `:65, 387-415`).
- Region policy on teleports: `listeners/WorldGuardRegionListener.java:37-41` runs `RegionTransitionService` on every
  `PlayerTeleportEvent` and cancels when a domain's `AllowEntry`/`AllowExit` is false
  (`knk-core:regions/SimpleRegionTransitionService.java:144-181`). **No staff bypass exists.**
- Siege: `siege/SiegeService.java` `lobbyOf`/`activeLobbyOf` (HUB or IN_PROGRESS)/`runningMatchOf` (`:1471-1488`),
  command filter `isCommandAllowed` (`:1277-1283`, `listeners/SiegeCommandFilterListener.java`), default
  `SiegeConfiguration.AllowedCommands = "/siege,/msg,/r,/staffchat,/menu"` (`knk-web-api:Models/Siege/SiegeConfiguration.cs:54`
  — note `/menu` is allowed, so a menu-driven teleport would slip past the command filter). Area lockdown
  `siege/SiegeAreaLockdown.blockingEntry` (`:90-106`) + `listeners/SiegeAreaLockdownListener.java:42-50`, which
  **skips `TeleportCause.PLUGIN`**; bypass node `knk.siege.bypass.lockdown`. Siege code lives on `claude/siege-minigame`,
  not yet on plugin `main`.
- Freeze: `user/AdminFreezeManager.isFrozen`; `listeners/AdminFreezeListener.java` blocks commands (`:76-84`) and walking
  (`:48-66`) — its `PlayerMoveEvent` handler does **not** receive `PlayerTeleportEvent` (separate HandlerList), so a
  frozen player can still be teleported (e.g. by a menu action or another player).
- Vanish: `modes/ModeService.isVanished` (`:89`), persisted `User.ActiveMode`; staff/owner visibility via
  `knk.mode.staff`/`knk.mode.owner`.
- Permissions: `permissions/KnkPermissible` (sync cache-only, fails closed; op bypass) and
  `commands/support/PlayerCommandSupport.whenAllowed` (async, for commands). Rank check `commands/support/RankHierarchy`.
- Player data in cache: `knk-core:domain/users/UserSummary` has `gems`, `experiencePoints`, `titleBracketId`,
  `premiumTierGroupId`, `isFrozen`, `activeMode`. Premium tiers are `PermissionGroup`s `Noble`/`Royal`/`Dragon Blood`
  with weights 10/20/30 (`knk-web-api:Migrations/20260924082801_AddUserFeaturesPhase5PremiumTiers.cs:45-47`).
- Currency: `UsersCommandApi.adjustBalancesById` → `PUT /api/users/{id}/balances` → `UserService.AdjustBalancesAsync`
  (`knk-web-api:Services/UserService.cs:618-712`): read-modify-write, no concurrency token, no idempotency, audited as
  `BalanceAdjusted`. Being hardened by `specs/currency-payments/`.
- Audit: `AuditLogService.RecordAsync(actor, target, action, detailsJson)`; `Enums/AuditAction.cs` ends at
  `KitGranted = 11`; web-app labels in `src/pages/admin/PlayerProfilePage.tsx:37-40` + union type
  `src/types/dtos/userManagement/UserProfileSummaryDtos.ts:109-112`. Plugin writes can be restricted with
  `[RequirePluginServiceKey]` (`Attributes/RequirePluginServiceKeyAttribute.cs`, open until `Security:PluginServiceKey`
  is set). The API ignores the plugin's `X-Acting-User-Id` header (actor comes only from JWT claims), so plugin-made
  mutations are currently recorded with `actorUserId = null`.
- `utils/CommandCooldownManager` (in-memory per-player cooldowns). InventoryMenu engine (`menu/`, `MenuFeature`,
  content features like `menu/content/ProfileMenuFeature.java`) for a teleport menu.
- No combat tag in v3 (`CombatSafezoneCheck` is KNG-11 enchant safezones, not a tag). No `teleportAsync` use anywhere.

**Doc/code discrepancies found** (flag, not fixed):
1. `legacy/commands-v1.md:1532` says owner-mode `/tpa <player>` works (`v1:163-166`); it is dead (same `contains(String)`
   bug). The v3 `TeleportToPlayerCommand` javadoc repeats this premise. Net: **no v1 player-to-player teleport worked**.
2. `legacy/commands-v1.md:1538` says the chat "cancel" listener is commented out; an active copy exists at
   `v1:Listeners/PlayerListener.java:961-969` (it only clears the unused map).
3. `user-features/COMMAND_CATALOG_V3.md` (2026-09-25) lists no `/knk tp`, `/freeze`, `/msg`, `/staffchat`, `/kit`,
   `/siege`, `/fly`/`/heal`/… — stale.
4. `user-features/EVENT_CATALOG_V3.md:464-468` says `onPlayerRespawn` never sets the location; fixed since (`c908981`,
   now a blocking `CACHE_FIRST` `.join()` on the main thread).
5. `knk-plugin/CLAUDE.md`: "No dedicated gui/menus package exists yet" — stale, `menu/` exists; "authenticated with a JWT
   bearer token" — `config.yml` default is `api.auth.type: none`.
6. v1 menu lore "Teleportation starts after 3 seconds" (`Menu.java:2042`) vs. 5 s actual for non-premium.

---

## 2. Gap analysis

| Capability | v1/v2 behaviour | v3 today | Reusable v3 component (path) | Work |
|---|---|---|---|---|
| Staff self → player | Owner-mode `/tpa <p>`; dead in v1 | `/knk tp <p>` works, no audit/vanish/siege | `commands/TeleportToPlayerCommand.java`, `RankHierarchy` | S (rewire onto engine) |
| Staff player → player, tphere, silent | Intended in v1, dead | None | `RankHierarchy`, `ModeService` | S |
| Staff → coordinates | None | None | — | S |
| Player request (`/tpa`, accept/deny) | Designed in v1 (10000 coins, 30 s), never functional | None | `CommandCooldownManager` | M |
| `/tpahere` | Advertised Dragon Blood perk, never built | None | Premium groups (weights 10/20/30) | S (on top of `/tpa`) |
| `/spawn` | Spawnpoint `"spawn"` via the paid/delayed engine; `/spawn <p>` staff | None; join → world spawn | `GameSettings.JoinSpawnReference`, `GET /api/GameSettings` | S (+ new plugin client) |
| Domain spawn teleport (`/warp`) | `/point`: title ≥, donator ≥, gem price (towns 10), 3/5 s warmup | Domains have `Location`, nothing teleports there | `Domain.LocationId`, `TownsDataAccess`, `LocationsDataAccess` | L (API + plugin) |
| Teleport menu | Personal menu COMPASS → list with lock lore | None | InventoryMenu engine `menu/`, `MenuFeature` | M |
| Warmup + cancel | 5 s / 3 s premium; any look/move cancels; damage never | None | — | M (engine) |
| Cooldown after teleport | None | None | `utils/CommandCooldownManager` | S |
| Combat tag | 10 s tag, not checked by teleports | None | — | S |
| Safe location | Helpers unused; wrong-chunk busy-wait; unbounded recursion | None | Paper `teleportAsync` | S |
| Siege / minigame block | Duel check only | Command filter (menu bypass), lockdown skips `PLUGIN` cause | `SiegeService.activeLobbyOf`, `SiegeAreaLockdown.blockingEntry` | S |
| Freeze interplay | Intended "can't be teleported", never built | Commands blocked; teleports of a frozen player not blocked | `AdminFreezeManager.isFrozen` | S |
| Vanish interplay | Owner mode = instant bypass | `/knk tp` ignores vanish | `ModeService.isVanished`, `knk.mode.*` | S |
| Domain AllowEntry/AllowExit on teleport | v2 flag only | Enforced on all teleports, no staff bypass | `WorldGuardRegionListener` | S (bypass node) |
| Paying for teleports | Gems deducted after warmup, no audit | Balance path exists, not idempotent | `UsersCommandApi.adjustBalancesById` → `AdjustBalancesAsync` | M (charge endpoint) |
| Admin teleport audit | None | None | `AuditLogService`, `[RequirePluginServiceKey]` | S |
| `/back` (death) | Advertised perk, never built | None | — | S (optional) |

**Reuse as-is:** Domain/Location data and gateways, `KnkPermissible`/`PlayerCommandSupport`, `RankHierarchy`,
`ModeService`, `AdminFreezeManager`, `SiegeService`/`SiegeAreaLockdown` queries, `CommandCooldownManager`, the audit
service, the InventoryMenu engine. **Extend:** `Domain` (teleport settings columns), `AuditAction` (+1 value),
`WorldGuardRegionListener` (bypass node), `/knk tp` (delegate). **New:** a teleport engine (plugin), the command set,
a GameSettings read client, the API teleport-destination/charge service, a teleport menu.

---

## 3. v3 design

### 3.1 Principles

- **Plugin-only wherever no currency or persistent state is involved.** Staff teleports, requests, `/spawn`, warmup,
  cooldown and guards are plugin-only. The API is needed only for (a) paid/requirement-gated domain teleports, (b) the
  audit trail, (c) reading `GameSettings` (existing endpoint).
- **One engine, many entry points.** Every command and menu click builds a `TeleportPlan` and hands it to
  `TeleportService`; no command calls `player.teleport` directly. Siege-internal teleports stay outside the engine.
- **Teleport with `TeleportCause.COMMAND`**, never the default `PLUGIN`, so the existing region (`AllowEntry`/`AllowExit`)
  and siege-lockdown listeners apply to our teleports as they do to vanilla ones. The engine also **pre-checks** both so
  a player is refused before a warmup or a charge, not after.

### 3.2 Command tree

Top-level commands follow the v3 convention of no `permission:` entry in `plugin.yml`; each executor checks its node
through `PlayerCommandSupport.whenAllowed` (`KnkPermissible` async, ops pass). Console is refused for commands that move
the sender; console may run the "others" forms.

| Command | Aliases | Node(s) | Behaviour |
|---|---|---|---|
| `/tpa <player>` | `/tpa accept\|deny [player]` (v1 form) | `knk.teleport.request` | Ask to go to `<player>`. Engine runs on accept (warmup on the requester). |
| `/tpahere <player>` | — | `knk.teleport.request.here` | Ask `<player>` to come to you. Warmup on the target after they accept. |
| `/tpaccept [player]` | `/tpyes` | (none — answering is always allowed) | Accept the newest (or named) pending request. |
| `/tpdeny [player]` | `/tpno` | (none) | Deny. |
| `/tpcancel` | — | (none) | Withdraw your outgoing request, or cancel your own running warmup. |
| `/spawn` | — | `knk.teleport.spawn` | To server spawn (§3.6). |
| `/spawn <player>` | — | `knk.teleport.staff.others` | Send a player to spawn, instant. Console allowed. |
| `/warp` / `/warp list` | `/point` (v1) | `knk.teleport.warp` | Open the teleport menu (§3.8); chat list fallback when the menu is unavailable. |
| `/warp <domain>` | `/point <domain>` | `knk.teleport.warp` | Domain spawn teleport (§3.7). Name match is case-insensitive; ambiguous names list `Type:Name` choices; `town:Kardenna` form accepted. |
| `/warp <domain> <player>` | — | `knk.teleport.staff.others` | Send a player, instant, free. Console allowed. |
| `/tp <player>` | `/knk tp <player>` (kept) | `knk.teleport.staff` (or legacy `knk.admin.tp`) | Self → player, instant. Rank check (existing behaviour). |
| `/tp <player> <target>` | — | `knk.teleport.staff.others` | Player → player, instant. The actor must outrank both players (console skips the check). |
| `/tp <x> <y> <z> [world] [yaw pitch]` | `~` relative coords | `knk.teleport.staff` | Self → coordinates. |
| `/tphere <player>` | — | `knk.teleport.staff.others` | Target → self, instant, rank-checked. |
| any staff form + `-s` | `silent`/`s` last arg (v1) | `knk.teleport.staff.silent` | No message to the moved/visited player. Always silent when the actor is vanished. |

`/tp` vs vanilla: declaring `tp` in `plugin.yml` makes the bare label resolve to the plugin; vanilla stays reachable as
`/minecraft:tp` (op level 2). See §5 Q1 — the default taken here is to own `/tp` and `/tphere` and leave `/teleport`
vanilla.

### 3.3 Permission nodes (in-house model, `KnkPermissible`)

| Node | Meaning | Default grant (review §4) |
|---|---|---|
| `knk.teleport.request` | `/tpa` | Default group |
| `knk.teleport.request.here` | `/tpahere` | Dragon Blood (v1 perk text) — §5 Q2 |
| `knk.teleport.spawn` | `/spawn` | Default group |
| `knk.teleport.warp` | `/warp`, teleport menu | Default group |
| `knk.teleport.back` | `/back` (Phase 7) | Dragon Blood (v1 perk text) |
| `knk.teleport.warmup.short` | 3 s instead of 5 s | Noble (inherited by Royal/Dragon Blood) — v1 "donatorID > 0" |
| `knk.teleport.bypass.warmup` / `.cooldown` / `.cost` / `.requirements` / `.combat` | Individual bypasses | Staff groups |
| `knk.teleport.staff` | `/tp <player>`, `/tp <coords>`; staff teleports skip warmup/cost/cooldown/safety | Staff groups |
| `knk.teleport.staff.others` | Move other players (`/tp a b`, `/tphere`, `/spawn <p>`, `/warp <d> <p>`) | Staff groups |
| `knk.teleport.staff.silent` | `-s` flag | Staff groups |
| `knk.region.bypass` | Skip `AllowEntry`/`AllowExit` denials (in `WorldGuardRegionListener`) | Staff groups |
| existing `knk.admin.tp` | Accepted as an alias of `knk.teleport.staff` for `/knk tp` / `/tp <player>` during transition | unchanged |
| existing `knk.siege.bypass.lockdown`, `knk.siege.bypass.commands` | Reused, not duplicated | unchanged |

Declared in `plugin.yml` with `default: op` for documentation, matching the `knk.kit.*` convention. Owner/staff *mode*
is not a bypass by itself (v1 used owner mode as the gate); the nodes are.

### 3.4 Engine (knk-paper `teleport/`, pure logic in knk-core `core/teleport/`)

`TeleportPlan { subject, destinationSupplier, kind (STAFF|REQUEST|SPAWN|WARP|BACK), actor, warmupSeconds,
chargeSpec?, silent, auditSpec? }`. `TeleportService.start(plan)`:

1. **Guards** (`TeleportGuards`, each returns an optional denial message; bypass nodes as listed):
   - subject frozen (`AdminFreezeManager.isFrozen`) → "You can't teleport while frozen." Staff kinds move frozen players
     only with `knk.teleport.staff.others` (e.g. to a jail spot) — allowed.
   - subject in an active siege (`SiegeService.activeLobbyOf(subject)` present) → refuse, unless
     `knk.siege.bypass.commands`. Staff moving a match member → refuse with "X is in a siege match; use /siege admin
     kick first" (a teleport would desync the vault snapshot).
   - request target in an active siege → "X is in a siege match."
   - destination inside a locked siege area → `SiegeAreaLockdown.blockingEntry(subject, from, to)` (bypass
     `knk.siege.bypass.lockdown`).
   - destination domain `AllowEntry=false` or origin domain `AllowExit=false` → refuse (bypass `knk.region.bypass`),
     using the same `RegionTransitionService` decision the listener uses.
   - combat tag (§3.4.3) → "You were in combat N s ago; wait M s."
   - cooldown → "You can teleport again in N s."
   Siege guards are wired through a `TeleportRestriction` interface that `SiegeService` registers, so the teleport
   branch compiles on `main` before siege merges (§4 D9).
2. **Warmup** (skipped for STAFF kinds and `knk.teleport.bypass.warmup`): default **5 s**, **3 s** with
   `knk.teleport.warmup.short` (v1 values). Action-bar countdown "Teleporting in N…". One warmup per player; a new one
   replaces the old (message "Previous teleport cancelled").
   Cancel on: block-position change (`from.getBlockX/Y/Z != to…`, not head rotation — fixes v1), any damage taken
   (`EntityDamageEvent` on the subject — the v1 intent that was never live), the subject being teleported by anything
   else, death, quit, becoming frozen, joining a siege lobby. Message "Teleport cancelled: you moved." / "…: you took
   damage." Nothing has been charged at this point.
3. **Commit:** re-run guards (state may have changed), resolve the destination, **charge** (§3.7.3) if the plan has a
   price, find a **safe location** (§3.4.2), then `subject.teleportAsync(loc, TeleportCause.COMMAND)`.
   If the future completes `false` (cancelled by a listener) or the subject went offline, **refund** the charge.
4. **After:** set cooldown (player kinds only), messages, audit (staff kinds), `TeleportEvent` log line.

#### 3.4.1 Timing/task model
Warmups are held in a `ConcurrentHashMap<UUID, PendingTeleport>` ticked by one `BukkitRunnable` every 5 ticks (smooth
countdown). All Bukkit calls on the main thread; REST calls (charge, audit) async with the continuation re-scheduled on
the main thread (existing `runTask` pattern in `TeleportToPlayerCommand`).

#### 3.4.2 Safe location
`SafeLocationFinder` (knk-core, Bukkit-free over a `BlockProbe` port): a spot is safe when feet and head blocks are
passable, the block below is solid and not in the hazard set (lava, magma, fire, soul fire, campfire, cactus, sweet
berry bush, powder snow, wither rose, pointed dripstone), and Y is inside world bounds. Search order: exact spot, then
rings radius 1..`teleport.safe-search-radius` (default **3**) at dy 0, +1, −1, +2, −2. **Bounded** — if none found,
refuse ("The destination isn't safe right now; staff have been notified" + log). Staff kinds skip the check (exact
spot, as staff intend). Player-to-player teleports check the target's spot too (the target may be flying or in a
2-high gap).

#### 3.4.3 Combat tag
New `CombatTagListener`: player-vs-player damage (direct or projectile) tags both for `teleport.combat-tag-seconds`
(default **10**, v1 `Main.combat`). Only teleports check it here; the siege has its own combat rules and members are
already blocked.

#### 3.4.4 Vanish
- Name resolution for non-staff treats vanished players as offline (same message, same tab-complete exclusion) —
  `VisibleTargetResolver` using `ModeService.isVanished` + viewer holding `knk.mode.staff`/`knk.mode.owner`.
- A vanished actor's staff teleports are silent to the target automatically. Staff teleporting to a vanished,
  higher-ranked player is refused by the existing rank check.
- Requests can't be sent **by** a vanished player to a non-staff player (would reveal them) — refused with a hint.

### 3.5 Requests (`/tpa`, `/tpahere`)

- `TeleportRequestBook` (knk-core, pure): `Request { id, requester, target, direction (TO_TARGET|TO_REQUESTER), createdAt,
  expiresAt }`. Expiry `teleport.request.expire-seconds` = **30** (v1 value). Max one outgoing request per requester (new
  replaces old); max `teleport.request.max-incoming` = 5 per target (oldest dropped). Duplicate to the same target within
  the window → "already pending". Send cooldown `teleport.request.cooldown-seconds` = 10 (bypass `.cooldown`).
- Messages: requester "Request sent to X. It expires in 30 s. /tpcancel to withdraw."; target gets a clickable
  Adventure component `[Accept] [Deny]` running `/tpaccept X` / `/tpdeny X`, plus "X wants to teleport to you" /
  "X asks you to teleport to them".
- On accept: guards re-run for **both** players (either may have joined a siege, been frozen, gone vanished, gone
  offline); the destination is the **live** location of the stationary player at commit time (not at accept time), then
  the safe-location check; warmup on the moving player.
- Price: `teleport.request.price-coins` (default **0**, §5 Q2), charged to the requester on commit via the same charge
  path as warps (`reason = "teleport.request"`).
- Quit/death of either side clears their requests. State is in-memory only; a restart drops pending requests (fine for
  a 30 s window).

### 3.6 `/spawn`

Destination = `GameSettings.JoinSpawnReference` when `JoinSpawnMode = CustomReference` (resolve `sourceType` Location
→ `LocationsDataAccess`, Town/District/Structure → that domain's `Location`), else the main world's spawn. New
read-only `GameSettingsQueryApi` in knk-api-client on the existing `GET /api/GameSettings`, cached (TTL 5 min,
refreshed on `/knk cache`). Player `/spawn` is free, uses warmup/cooldown/guards; `/spawn <player>` is staff, instant.
The v1 "spawn" spawnpoint also had a price/title requirement — not ported (spawn is the universal escape hatch).

### 3.7 Domain teleports (`/warp`)

#### 3.7.1 Data model (knk-web-api)
New columns on `Domain` (TPT base table `domains`, so Town/District/Structure all get them):

| Column | Type | Default | v1 equivalent |
|---|---|---|---|
| `TeleportEnabled` | bool | `false` | spawnpoint present in the "general" list |
| `TeleportPriceGems` | int ≥ 0 | `0` | `SpawnPoint.Price` (towns 10) |
| `TeleportMinTitleBracketId` | int? FK `title_brackets` `SetNull` | null | `TitleIDRequired` |
| `TeleportMinPremiumGroupId` | int? FK `permission_groups` `SetNull` (must be `IsPremiumTier`) | null | `DonatorIDRequired` |
| `TeleportRequiresDiscovery` | bool | `false` | none (v1 didn't gate on discovery) |

Migration `AddDomainTeleportSettings`; no backfill (v1 spawnpoints were never imported into v3). Fields are added to
the Town/District/Structure FormConfigurations (dev-DB authoring, like Kits Phase 3). A domain is a valid destination
only when `TeleportEnabled && LocationId != null && AllowEntry`.

#### 3.7.2 Access rule (server-side, `TeleportDestinationService.EvaluateAsync(user, domain)`)
In order, first failure wins (reason code + message): disabled / no location / entry closed → not listed;
title: `user.ExperiencePoints >= bracket.MinExperience` (`TitleTooLow`, "Reach title X to unlock"); premium: the
user's highest active premium group `Weight >= required.Weight` (`PremiumTooLow`, "Premium tier X or higher
required"); discovery: only when `TeleportRequiresDiscovery` **and** the domain-discovery feature is present
(`NotDiscovered`, "Discover X first"); price: `Gems >= TeleportPriceGems` (`InsufficientGems`). The plugin's
`knk.teleport.bypass.requirements` / `.cost` are passed as flags by the plugin (§4 D6). Membership/citizenship is not a
v3 concept, so there is no member-only rule.

#### 3.7.3 API endpoints (`Controllers/TeleportDestinationsController.cs`, route `api/teleport-destinations`)

| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/api/teleport-destinations?userId={id}` | open read (as other GETs) | All enabled destinations with `{domainId, name, domainType, location, priceGems, minTitleName, minPremiumTierName, requiresDiscovery, available, lockReason}` for that user — feeds `/warp list`, tab-complete and the menu. |
| POST | `/api/teleport-destinations/{domainId}/charge` | `[RequirePluginServiceKey]` | Body `{userId, idempotencyKey, bypassRequirements, bypassCost}`. Re-evaluates the rule, deducts `TeleportPriceGems` through `UserService.AdjustBalancesAsync(…, reason: "teleport.domain", metadata: {domainId, idempotencyKey})`, returns `{charged, newGems, location}` or 409 with the reason code. |
| POST | `/api/teleport-destinations/refund` | `[RequirePluginServiceKey]` | Body `{userId, idempotencyKey}` — compensating `+gems` for a charge whose teleport failed. |

DTOs in `Dtos/TeleportDtos.cs`. Until `specs/currency-payments/` lands its ledger/idempotency, the key is only carried in
the audit metadata and the plugin never retries a charge (timeout = treat as failed, no teleport; the audit trail
reconciles the rare lost response). **Once currency-payments lands, charge/refund move onto its ledger API with the
key as the real idempotency key** — no teleport-specific ledger. Request-flow coin charges use the same pattern with
`PUT /api/users/{id}/balances` until then.

#### 3.7.4 Plugin side
- `TeleportDestinationsQueryApi` + `TeleportDestinationsCommandApi` ports (knk-core), impls in knk-api-client;
  `TeleportDestinationsDataAccess` with a per-user cached list (TTL `teleport.destinations.cache-seconds` = 60,
  invalidated after a charge and on `/knk cache`).
- `/warp <domain>`: resolve from the cached list → guards → warmup → **charge** → safe spot → `teleportAsync` →
  refund on failure. The destination location comes from the charge response (fresh) or the list for free warps.
- Messages keep v1 wording: "You need to wait N seconds before teleporting...", "You paid N gems and your new balance
  is M", "You teleported to X", "You don't have enough gems to teleport to this location!".

### 3.8 Teleport menu (InventoryMenu)

`TeleportMenuFeature` (`menu/content/`) registering content source `teleport.destinations` (rows from the cached list)
and action `teleport.warp` (calls the same `/warp` path, closes the menu). Template `teleport.destinations` seeded in
`knk-web-api:Models/Menu/MenuTemplateSeed.*` (create-only by key, like other content ports), layout after v1 §3.6:
COMPASS per destination coloured by required premium tier, lore "Price: N gems", "Available! Click here to teleport" /
"Locked! Reach title X to unlock" / "Locked! Premium tier X or higher required!", info tile with the **real** warmup
for the viewer. Hub tile in `/menu` (COMPASS "Teleport to points on the map"). Because `/menu` is allowed during a
siege, the action relies on the engine's siege guard, not the command filter.

### 3.9 Admin UI (knk-web-app)
- Domain teleport fields appear through FormConfiguration (no code) — authoring step in the plan.
- `PlayerTeleported` audit label in `PlayerProfilePage.tsx` and the `AuditAction` union type.
- No new page.

### 3.10 Audit of admin teleports
- New `AuditAction.PlayerTeleported = 12`. Recorded for every STAFF-kind teleport: `/tp <p>` (target = the visited
  player), `/tp a b` / `/tphere` / `/spawn <p>` / `/warp <d> <p>` (target = the moved player; details also carry the
  visited player). Details JSON: `{kind, actorUsername, subjectUserId, visitedUserId?, from:{world,x,y,z},
  to:{world,x,y,z,domainId?}, silent, via:"command"}`.
- Endpoint `POST /api/users/{id}/teleport-audit` (`UsersController`), `[RequirePluginServiceKey]`, body carries
  `actorUserId` — trusted only because the key is required; same caveat as the open CP7 actor-attribution question
  (`ACTIVE_SESSIONS.md`, InventoryMenu row). Fire-and-forget from the plugin with one retry; every staff teleport is also
  logged locally (`[KnK Teleport] actor → subject from … to …`) so nothing is lost when the API is down.
- Player teleports are not audited (volume); paid ones are covered by `BalanceAdjusted` with `reason teleport.*`.

### 3.11 Config (`config.yml`, new `teleport:` block)

```yaml
teleport:
  warmup-seconds: 5            # v1 default
  warmup-short-seconds: 3      # knk.teleport.warmup.short (v1 premium)
  cooldown-seconds: 30         # after a player-initiated teleport (review D4)
  combat-tag-seconds: 10       # v1 Main.combat
  safe-search-radius: 3
  request:
    expire-seconds: 30         # v1
    cooldown-seconds: 10
    max-incoming: 5
    price-coins: 0             # v1 intended 10000, never charged (Q2)
  destinations:
    cache-seconds: 60
  back:
    enabled: false             # Phase 7 (Q5)
    expire-seconds: 300
```

### 3.12 Anti-exploit & concurrency
- **Escape exploits:** combat tag + damage cancel stop "teleport out of a fight"; warmup cancel on block move stops
  "start warmup while running"; guard re-check at commit stops "start warmup, then join a siege/get frozen".
- **Charge/teleport atomicity:** charge only after the warmup; refund if `teleportAsync` returns false or the player is
  gone; no retry of a charge without a ledger idempotency key.
- **Double-accept / race:** `TeleportRequestBook` operations are main-thread only; accepting removes the request
  atomically; a second `/tpaccept` finds nothing.
- **Request spam / harassment:** send cooldown, per-target cap, 30 s expiry, no requests from vanished players.
- **Information leaks:** vanished players look offline; `/warp list` shows only enabled destinations; locked reasons
  are fine to show (v1 did).
- **Region/siege bypass through plugin cause:** all engine teleports use `COMMAND`; `/knk tp`'s current `PLUGIN`-cause
  bypass of the lockdown is closed.
- **Chunk loading:** `teleportAsync` replaces v1's main-thread busy-wait.
- **Stale destination cache:** the charge endpoint re-evaluates server-side and returns the authoritative location.

### 3.13 Observability
- Plugin: one INFO line per staff teleport, FINE per player teleport; WARNING on unsafe destination, charge/refund
  failure. Counters in `/knk health`-style output are not needed now.
- API: `BalanceAdjusted`/`PlayerTeleported` audit rows; the existing OpenTelemetry HTTP metrics cover the new routes
  (`/metrics`), no custom meter.

---

## 4. Decisions taken by default (each: review)

- **D1 (review):** Keep `/knk tp` as an alias; the real staff surface is `/tp`/`/tphere`, which shadow vanilla (Q1).
- **D2 (review):** Warmup 5 s / 3 s with `knk.teleport.warmup.short` granted to the Noble group (inherited upward) —
  v1's `donatorID > 0` rule, expressed as a node rather than a hard-coded tier check.
- **D3 (review):** Warmup cancels on block movement and on any damage; head rotation does not cancel (v1 cancelled on
  any `PlayerMoveEvent`, v1's damage cancel was never live).
- **D4 (review):** New 30 s post-teleport cooldown for player-initiated teleports (v1 had none) and a 10 s combat tag
  (v1 value, never enforced in v1).
- **D5 (review):** `/spawn` is free and has no title/premium gating, destination from `GameSettings.JoinSpawnReference`.
- **D6 (review):** The plugin decides bypasses (it holds the permission resolution) and passes
  `bypassRequirements`/`bypassCost` to the charge endpoint; the endpoint is service-key protected.
- **D7 (review):** Domain teleport settings are columns on `Domain`, not a separate entity or a v1-style SpawnPoint
  table; a domain has exactly one teleport destination (its `Location`).
- **D8 (review):** Staff teleports skip warmup, cost, cooldown and the safe-location check, but not the siege-member
  guard (use `/siege admin kick` first) and not the rank check.
- **D9 (review):** Siege guards via a `TeleportRestriction` registration so the teleport branch forks from plugin
  `main` independently of `claude/siege-minigame`.
- **D10 (review):** Frozen players cannot start or receive player teleports; staff may still move them.
- **D11 (review):** `knk.region.bypass` is added to `WorldGuardRegionListener` for staff; without it even `/tp` into a
  closed domain is cancelled today.
- **D12 (review):** Request state is in-memory; no persistence across restarts.

## 5. Open questions for the developer

1. **Own `/tp`?** (a) Plugin owns `/tp` + `/tphere` (vanilla via `/minecraft:tp`); (b) staff stay on `/knk tp …` only;
   (c) own `/tp` and `/teleport` both. **Recommended: (a)** — the familiar label gets rank checks, vanish and audit;
   `/teleport` stays vanilla for command blocks/datapacks.
2. **Who can use player requests, and at what cost?** v1 designed `/tpa` for everyone with `k&k.teleport.normal` at
   10000 coins (never charged); the premium page sold "teleport invites" as a Dragon Blood perk.
   (a) `/tpa` + `/tpahere` free for all; (b) `/tpa` free for all, `/tpahere` Dragon Blood only; (c) both for all at a
   coin price. **Recommended: (b)**, price `0` configurable.
3. **Should domain teleports require discovery?** v1 never did; the domain-discovery feature is being designed now.
   (a) never; (b) per-domain flag `TeleportRequiresDiscovery` (default off); (c) always. **Recommended: (b)**.
4. **Which domain types can be warp targets?** (a) Towns only (v1 practice: town spawnpoints + a few hand-made points);
   (b) any Domain with `TeleportEnabled`. **Recommended: (b)** — the flag already keeps the list curated.
5. **Build `/back`?** (a) no; (b) death location only, Dragon Blood (v1 perk text), 5 min, not after a siege death;
   (c) death + last teleport origin for everyone. **Recommended: (b)**, last phase.
6. **Warp price currency:** v1 charged gems. Keep gems for warps and coins for requests, or unify? **Recommended:
   gems for warps (v1), coins for requests if Q2 ever sets a price (v1 design).**

