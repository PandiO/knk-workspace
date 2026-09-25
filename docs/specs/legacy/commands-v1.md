# v1 command catalog (Minecraft commands)

Mined from `knk-v1-archive` (single-commit Bukkit import, no ORM — see
`docs/specs/legacy/user-system.md` for the data-model side of this codebase
and its citation conventions, which this doc follows: `v1:src/Path/File.java:line`).

## Why this doc exists

The original `legacy-spec-mining` pass (`user-system.md`, `inventory-menus.md`,
`towns-districts-gates.md`, `kits.md`, `siege-minigame.md`) documented data
models, business rules, and bugs per subsystem, but **did not systematically
inventory the actual player/admin-facing Minecraft commands** — which ones
existed, their arguments, their permission gates, and what they actually did.
`docs/specs/user-features/COMMAND_PERMISSION_SCAN.md` later filled in the full
`k&k.*` permission-node inventory for v1/v2/v3, but only tabulated a handful of
rank-relevant commands in detail. This doc (and its `commands-v2.md` sibling)
closes that specific gap: **every** command class found in the v1 source tree,
grouped by feature domain, with syntax, arguments, permission gate(s), actual
behavior (read from the method body, not just the name), and known bugs.

## Methodology

Full read of every `*Command*.java` file under `knk-v1-archive/src` (~67 files)
plus `plugin.yml` and `Main.java`'s ~69 `getCommand(...).setExecutor(...)`
registrations (the ground-truth command→class mapping — several classes
implement multiple distinct commands, e.g. `CoinCommands` → `/coins`, `/pay`,
`/balance`). Four additional command-implementing classes were found that don't
match a `*Command*` filename pattern (`FlyMode.java`, `Invsee.java`,
`ItemRenamer.java`, `LoreEditer.java`). Two classes are confirmed dead code
(registered nowhere, or registered but running an empty/no-op handler) —
flagged inline rather than silently dropped, since knowing what was
*attempted but abandoned* is itself useful signal for v3 design.

**Feature-domain categories used throughout** (chosen to align with existing
`docs/specs/` folder names where one already exists): `users` (identity/rank/
title/donator/permissions), `economy` (coins/gems/salary/lottery), `property`
(houses/rooms/properties/resource-properties — no v3-side folder exists yet),
`towns` (towns/districts/gates/streets/spawnpoints/structures/creation-wizard),
`items` (products/soulbound/ghosted/enchant/rename/lore), `inventory-menus`
(menu/viewmenu/invsee/inventory/enderchest), `social` (friends/requests),
`siege-minigame` (arena/duel/siege/scenario/hideandseek/treasure/vote),
`world-admin` (fly/gamemode/weather/reload/tpa/spawn — server/ops utilities),
`misc` (afk/discord/heal/message/ping/staffchat/tutorial/dev-tools).

**Verbatim-only, marked gaps, no invention** — same principles as the rest of
`docs/specs/legacy/` (see [README.md](README.md)). Where a subcommand's
underlying logic lives in a class outside the read scope (e.g. `Room.java`,
`Gate.java`), that's noted as unclear/out-of-scope rather than assumed.

## Cross-domain observations (read this before the per-domain sections)

- **Permission-check hygiene is wildly inconsistent, file to file.** Some
  commands (`HealCommands`, `ShopkeeperCommands`, `ViewMenuCommand`) cleanly
  gate every subcommand with an early return. Others check a permission but
  have no `else` branch, so failure is a silent no-op with zero player
  feedback (`/staffmode`, `/default set`, `/experience`, `/coins` unknown
  subcommand). At least one command (`/user save`) has the specific
  "permission check without `return`" bug already documented in
  `user-system.md` — confirmed still present, and not found duplicated
  elsewhere in this deeper pass. A recurring structural pattern in both
  `/property` and `/house`/`/room`: the top-level `onCommand` nests
  create/remove/part/spawnpoint inside a permission check, but then handles
  buy/sell/info/purge/list as a **sibling** block at the same nesting level —
  outside the permission gate entirely. This means `/property purge`,
  `/house purge`, `/room purge` (all ownership-wiping admin actions) have
  **no permission check whatsoever** in v1, despite being documented as
  staff-only in their own help text.
- **`(Player) sender` casts without an `instanceof Player` guard** appear
  repeatedly across otherwise-unrelated files (`WeatherChangeCommand`,
  `GameModeCommand`, `FlyMode`, `SpawnCommand`, `ItemRenamer`, `LoreEditer`) —
  each would throw `ClassCastException` if invoked from console by a sender
  holding the right permission.
  the underlying `k&k.*` permission string being wildly inconsistent in
  format (`k&k.house.*` vs `k&k.house`, `k&k.rooms` vs `k&k.room`).
- **Several commands are dead code**: `FreezeCommands` (`/freeze`, unregistered,
  no-op body), `RepairCommand` (`/repair`, unregistered, empty permission-true
  branch), `UsefulCommands/ViewMenuCommands.java` (unregistered, no-op body —
  do not confuse with the live `commands/ViewMenuCommand.java`).
- **Several commands are stubs**: `/tpa accept`/`/tpa deny` (empty blocks —
  the entire normal-player teleport-request flow never completes), `/siege
  join` ("Command not configured yet."), `/treasure remove` (three empty
  validation blocks, no removal logic ever written), `/scenario`'s
  spawnpoint/objective/info/list (documented in help text, no code branch).
- **Two currency/rank systems (Title/Experience, Donator) and the entire
  property/house/room system have no v2 equivalent** — see
  `commands-v2.md`'s v1→v2 diff section for the full breakdown.

---
# v1 — Users/rank/economy domain command catalog

Full source-grounded command catalog for the Users/rank/economy domain of knk-v1-archive. All citations verbatim `v1:src/Path/File.java:line`.

# 1. `/user` — src/Users/UserCommands.java

Top-level gate: `sender.hasPermission("k&k.ranks")` (v1:src/Users/UserCommands.java:46); else prints "You don't have permission for this command!" (line 281). Domain: users.

Dispatch requires exactly `args.length == 2` (line 48) — args[0]=subcommand, args[1]=target/"all". If args[1] is neither an existing user (`Users.existUser`) nor "all", error and `return false` (lines 52-62). With any other arg count, help text is printed (lines 272-278, `staffcommandhelp`, which itself is stale/incomplete — no "co-owner"/"owner" perm hints).

- **`/user remove <player|all>`** (lines 64-79). No additional permission beyond top-level `k&k.ranks`. "all" branch loops `Bukkit.getOnlinePlayers()` and deletes each by UUID (BUG: message at line 72 always echoes `args[1]` i.e. literally "all", not the per-iteration player name). Calls `offlineUser.deleteUser(UUID)`.
- **`/user default <player|all>`** (lines 80-104). No extra perm check. Runs `pex user <name> group remove {owner,co-owner,builder,staff}` + `group add default`, `setOp(false)`, then `user.updateScoreBoard()`.
- **`/user staff <player|all>`** (lines 105-129). No extra perm check (any `k&k.ranks` holder can promote to staff). Same pex pattern, adds "staff" group.
- **`/user builder <player|all>`** (lines 130-154). No extra perm check. Same pattern, adds "builder" group.
- **`/user co-owner <player|all>`** (lines 155-185). Extra check: `sender.hasPermission("k&k.ranks.co-owner")` (line 157) — HAS proper else-branch with `return`-equivalent (falls through to nothing further since it's the terminal else, line 182-185: correctly gated, no bug). BUG (pre-existing, cosmetic): "all" branch loop's success message at line 169 is inside the loop but only iterates variable `target`, fine; however the pex removal list omits "staff" from the second removal in the non-all branch is fine — actually re-check: line 163-167 removes owner, builder, staff, builder(again, duplicate remove-builder line 166) then adds co-owner — "builder" removed twice, "staff" removed once; harmless duplicate, not a functional bug beyond redundancy.
- **`/user owner <player|all>`** (lines 186-216). Extra check: `sender.hasPermission("k&k.ranks.owner")` (line 188), properly gated with else at 213-215.
- **`/user save <player|all>`** (lines 217-267). **BUG — same missing-return pattern as documented**: line 219 `if (!sender.hasPermission("k&k.ranks.staff"))` sends error message (line 221) but there is **no `return`/`return false`** after it (v1:src/Users/UserCommands.java:219-222) — execution falls through into the save logic at line 223 regardless of permission result. This is the exact pattern flagged in the existing user-system.md doc, confirmed present and reproduced verbatim in the same class/file (this literally is that documented bug — I did not find a *second* instance of it in this file, but confirm it as real). Actual save logic: "all" branch (lines 223-240) has an apparent secondary bug — it only saves **the sender's own** user object (`Users.getUser(((Player)sender).getUniqueId())`) via `main.saveUsers(user, false)`, not all online players' data, despite `all` being the requested target — the loop-over-online-players pattern used elsewhere is absent here. Non-all branch (241-267) resolves target via `Bukkit.getPlayer(targetUsername)`, catches `UserNotFoundException`/generic `Exception` (with early `return false` on failure, correctly), then calls `user.saveUser()` with try/catch reporting success/failure to sender.
- **Default/unknown subcommand**: prints `staffcommandhelp.get(2)` only (a single line, not full help) (line 270).
- **No args or args.length != 2**: prints full `staffcommandhelp` list (lines 272-278).

# 2. `/ownermode` (alias `om`) and `/staffmode` (alias `sm`) — src/Users/OwnerCommands.java

Both commands routed through same `onCommand`, dispatched on `label` (line 56, 137). Domain: users.

## `/ownermode` (alias `om`)
Casts `sender` directly to `Player` (line 58) — NPE/ClassCastException risk if invoked from console (no `instanceof Player` guard anywhere in file). Resolves `User` via `Users.getUser(uuid)`, catching `UserNotFoundException`/`Exception` with early return on failure (lines 62-74, correctly gated).
- Permission: `player.hasPermission("k&k.owner") || player.hasPermission("k&k.co-owner")` (line 75), else-branch sends "You don't have permission for this command!" (line 135) — correctly terminal, no fallthrough bug here.
- **No args**: toggles `user.setOwnerMode(!user.inOwnerModus())` then `Users.updateScoreBoard(null)` (lines 77-86).
- **`enable`/`on`** (lines 89-104):
  - with second arg `onquit`/`oq`: schedules deferred enable via `enableonquit` map (static `HashMap<UUID,Boolean>`, line 51), message only, mode NOT changed immediately.
  - with second arg anything else: prints usage error (line 99) — note: `args.length==2` branch, so only exactly 2 args triggers this path; unmatched second arg still only errors, doesn't call setOwnerMode.
  - with no second arg (args.length==1): `user.setOwnerMode(true)` (line 103).
- **`disable`/`off`** (lines 105-117): same onquit pattern via `disableonquit` map; else `user.setOwnerMode(false)`. NOTE: unlike enable's invalid-2nd-arg branch, disable's invalid 2nd-arg case (not "onquit"/"oq") has **no else** — silently does nothing (minor asymmetry/edge case, not the return-bug pattern but a silent-no-op edge case), v1:src/Users/OwnerCommands.java:107-113.
- **`help`**: prints `commandhelp` list (lines 118-123).
- **unrecognized first arg**: usage message (lines 124-126).
- All branches under `args.length>=1` call `Users.updateScoreBoard(null)` at the end (line 128) regardless of which branch executed, including the "usage error" no-op branches — harmless but slightly wasteful.

## `/staffmode` (alias `sm`)
Same structural pattern (lines 137-216).
- Permission: `player.hasPermission("k&k.staff") && !player.hasPermission("k&k.co-owner")` (line 156) — **no else-branch at all** (unlike ownermode) — if permission fails, method silently does nothing and returns false with zero feedback to the player (v1:src/Users/OwnerCommands.java:156-216, missing else). This is a distinct bug: no permission-denied message exists for staffmode (contrast with ownermode's line 135).
- Design note: co-owners are explicitly *excluded* from staffmode (they use ownermode instead) via the `&& !hasPermission("k&k.co-owner")` clause.
- Same enable/disable/onquit/help subcommand structure, using `user.setStaffMode(...)`, `staffcommandhelp` list, and the same shared static `enableonquit`/`disableonquit` maps (line 51-52) — **shared between ownermode and staffmode**, meaning a UUID queued for deferred owner-mode-enable and deferred staff-mode-enable would collide in the same map (potential cross-feature bug, since both handlers write/read the identical static maps without differentiating which mode was requested) — flagging as unclear/needs runtime trace to confirm actual consumption site (not shown in this file).

# 3. `/stats` (alias `s`) — src/Users/StatsCommands.java

Domain: users. **No permission check at all** — any sender can invoke (v1:src/Users/StatsCommands.java:21-51, no `hasPermission` call anywhere in file).
Casts `sender` to `Player` unconditionally (line 25) — console use would throw ClassCastException.
- **`/stats <player>`** (args.length==1, lines 26-40): resolves UUID via `Users.fetchUUIDbyUsername`; if found, constructs a fresh `new User(targetUUID)` (bypassing any cache), prints `ColorOptions.getPlayerStats(target)`, then `target.destroy()`. If not found, "This player does not exist".
- **`/stats` (no args)** (lines 41-47): prints stats for `Users.getUser(p.getUniqueId())` (sender's own cached User, not destroyed after).

# 4. `/default set <player...>` — src/UsefulCommands/RankCommands.java

Domain: users. Label must be exactly "default" (line 22); only args.length>0 is checked overall (line 24), and only `set` subcommand is implemented — no other subcommand branch, no else/usage message if args[0] isn't "set" or if args.length==0 (silent no-op, v1:src/UsefulCommands/RankCommands.java:20-70 — falls straight through, no feedback).
Permission: `sender.hasPermission("k&k.ranks.modify")` (line 26) — checked, but **no else branch** — if permission fails, command silently no-ops with zero feedback (same missing-feedback class of bug as staffmode above), v1:src/UsefulCommands/RankCommands.java:26-66.
- **`/default set <player>`** (args.length==2, lines 30-43): if online player found, runs `pex group Owner/Builder/Staff user remove` + `pex group Default user add`, success message; else "Can't find player".
- **`/default set <player> <player> ...`** (args.length>2, lines 44-60): loop `for (int i = 1; i < (args.length + 1); i++)` — **BUG: off-by-one / ArrayIndexOutOfBoundsException**. Loop condition should be `i < args.length`; using `args.length + 1` means the loop attempts `args[args.length]` on its final iteration, which is out of bounds (v1:src/UsefulCommands/RankCommands.java:46). This will throw at runtime whenever 3+ args are supplied (i.e., every multi-player invocation of `/default set p1 p2`).
- Note: only online players are handled (`Bukkit.getServer().getPlayer`); offline targets always fall to "Can't find player" even if the account exists in the user DB.

# 5. `/donator` — src/Donator/DonatorCommands.java

Domain: users (donator rank is identity-adjacent). Top-level branch on `sender.hasPermission("k&k.donator")` (line 49) with a **real** privileged/unprivileged fork — non-staff users still reach an else-branch (lines 227-247) that supports only `list` with args.length==1, or prints limited `commandhelp`.

Privileged branch (`k&k.donator`, args.length>0, lines 51-226):
- **`/donator set <donator> <username>`** (args.length==3, lines 53-82). Normalizes "dragonblood"/"db" → "dragon blood" (line 58-61). Validates donator name against `donator.getDonatorNames()` (case-insensitive via `.toLowerCase()`). **BUG**: if `Bukkit.getPlayer(args[2]) != null` (i.e., target is online) the if-body at lines 64-66 is **empty** — nothing happens, no message, no `setDonator` call — donator is silently NOT set for online players (v1:src/Donator/DonatorCommands.java:64-66). Only the `else if (Users.existUser(args[2]))` branch (offline-but-known user) actually calls `Users.setDonator(...)` (line 70). This looks like an inverted/incomplete condition — online players can never be donator-set via this path.
- **`/donator tempset <donator> <username> <time> <timeUnit>`** (args.length==5, lines 84-135). Validates donator ID, user existence, `main.isInt(args[3])`, and time-unit string against a fixed list (days/day/hour/hours/minutes/minute/seconds/second) — note line 103 uses `|` (non-short-circuit bitwise OR) instead of `||` before the last `equalsIgnoreCase("second")` check, functionally works but is a style smell/possible bug source if `equalsIgnoreCase` ever had side effects (it doesn't, so harmless in practice) (v1:src/Donator/DonatorCommands.java:103). Sets `target.setTempDonator(donatorID, main.calculateTimeValue(time, timevalue))`.
- **`/donator upgrade <username>`** (args.length==2, lines 137-161). **BUG**: not-found branch references `args[2]` (line 156) but only `args[0]`/`args[1]` are valid for this 2-arg command — `ArrayIndexOutOfBoundsException` whenever `Users.existUser(args[1])` is false (v1:src/Donator/DonatorCommands.java:156).
- **`/donator downgrade <username>`** (args.length==2, lines 163-187). Same **BUG**: not-found branch uses `args[2]` (line 182), out of bounds for a 2-arg command (v1:src/Donator/DonatorCommands.java:182).
- **`/donator remove <username>`** (args.length==2, lines 189-203). Same **BUG**: not-found branch uses `args[2]` (line 198), out of bounds (v1:src/Donator/DonatorCommands.java:198). Sets donator to `getDonatorID("Default")`.
- **`/donator list`** (lines 205-212): no perm beyond `k&k.donator`, prints available donator ranks/colors (uses `sender.getName()` oddly embedded in the preview string, line 211 — looks like a copy-paste display bug reusing sender's name in the rank-name preview instead of a fixed sample).
- Unknown subcommand / args.length==0: prints `staffcommandhelp`.

Unprivileged branch (no `k&k.donator`, lines 227-247): only `/donator list` (args.length==1) works, using text "Noble" instead of the actual rank name (line 237 — appears intentionally generic for non-staff, printing color codes only). Any other input prints short `commandhelp`.

# 6. `/experience` (alias `exp`) — src/Experience/ExperienceCommands.java

Domain: users. Gate: `sender.hasPermission("k&k.experience")` (line 28, matches lowercase runtime string despite plugin.yml's odd `K&k.experience` casing — Bukkit permission checks are case-insensitive in practice, but noting the source string is lowercase `k&k.experience`, v1:src/Experience/ExperienceCommands.java:28). **No else-branch at all for the permission failure** — if the sender lacks the permission, the whole block (lines 30-144) is skipped silently with zero feedback message (v1:src/Experience/ExperienceCommands.java:28-146).
- **`/experience set <amount> <username>`** (args.length==3, lines 32-42) or **`/experience set <amount>`** (args.length==2, self-target, sender must be Player, lines 43-52). Validates `main.isInt(args[1])`. Calls private `setExperience()`.
- **`/experience add <amount> <username|self>`** (lines 58-82). Same pattern, `addExperience()`.
- **`/experience remove|delete|del <amount|all> <username|self>`** (lines 84-120). Supports "all" to zero out. `removeExperience()`.
- **`/experience <username>`** (args.length==1, falls to `else if (Users.existUser(args[0]))`, lines 122-135): displays target's experience (no permission distinction — same `k&k.experience` gate covers this read-only lookup too).
- **`/experience` (no args)** (lines 136-144): if sender is Player, shows own experience.
- Helper methods `setExperience`/`addExperience`/`removeExperience` (lines 151-267) each wrapped in try/catch generic Exception with stack trace + generic error message to sender; `removeExperience`'s "all" path returns early (line 245) before reaching the shared success message at 250-256, avoiding a double-message bug (correctly handled with `return`).

# 7. `/nexttitle` — src/Titles/NextTitleCommands.java

Domain: users. **No permission check anywhere in file** (v1:src/Titles/NextTitleCommands.java, entire onCommand lines 26-121). Casts `sender` to `Player` unconditionally at line 30 — console-unsafe.
Resolves own `User` via `Users.getUser(uuid)` with try/catch UserNotFoundException/Exception, early return on failure (lines 34-46, correctly gated).
- **`/nexttitle <username>`** (args.length==1, lines 47-94): resolves target user (falls back to constructing offline `new User(...)` with `setOfflineUser(true)` if lookup throws, lines 52-68). If target's titleID == 18 (max title, hardcoded magic number), prints a "highest title" congratulation message branching on gender string (male/female/none) — three independent `if` checks (not else-if), all could theoretically fire if gender string is inconsistent, though in practice mutually exclusive by value. Otherwise computes and shows XP needed for next title via `Title.getExpmin(targetTitleID+1) - experience`. Destroys the temp `User` object only if it was constructed offline (`isOfflineUser()`).
- **`/nexttitle` (no args)** (lines 94-117): same logic for sender's own user, hardcoded titleID 18 check again, same three-gender-branch pattern; suggests `/changegender` command exists elsewhere for "none" gender case.
- Bug/edge note: magic number `18` for max title repeated twice (lines 71, 98) rather than referencing a named constant — fragile if title table changes.

# 8. `/coins`, `/pay`, `/balance` (alias `bal`) — src/Currency/CoinCommands.java

Domain: economy. Single `onCommand` handles all three labels sequentially via independent `if` blocks (not else-if) at lines 27, 106, 211 — meaning if a command were ever registered under multiple labels simultaneously matching more than one condition it could double-fire, but in practice each label is mutually exclusive so this is fine.

## `/pay <coins|gems> <name> <amount>` (label "pay", lines 27-105)
**No `hasPermission` check anywhere in this branch** — any player can use `/pay` (v1:src/Currency/CoinCommands.java:27-105, domain economy — likely intentional, it's a player-to-player transfer, not an admin command).
- Validates `args.length==3` and rejects if `args[1]` (the target name) contains "-" (line 29) — odd validation, likely meant to block negative-amount tricks but checks the wrong index (should probably validate `args[2]` for a leading "-"); as written it blocks player names containing a hyphen, not negative amounts — **likely bug**: negative-amount protection is misapplied to the wrong argument (v1:src/Currency/CoinCommands.java:29).
- Casts sender to Player unconditionally (line 34) — console-unsafe.
- **BUG**: uses `Integer.valueOf(args[2]).intValue()` directly (lines 49, 56, 58, 66, 73) with **no `main.isInt(args[2])` validation** before parsing for the "coins" sub-path (contrast: "gems" sub-path at line 80 does validate `main.isInt(args[2])` before use, but the balance-check at line 73 `Integer.valueOf(args[2])` runs *before* that validation, so a non-numeric amount for `/pay gems` throws `NumberFormatException` at line 73 regardless) — both coins and gems paths can throw unhandled `NumberFormatException` for non-numeric amount input (v1:src/Currency/CoinCommands.java:49,73).
- coins path: balance check `user.getCoins() < amount` → early `return true` with error if insufficient (line 49-53); on success sends coins via `user.sendCoins(...)`, messages both parties (target only if online, line 59-65), fires `PlayerPayEventHandler` event (line 66).
- gems path: balance check similarly (line 73-77); messages wrapped so failure to message offline target is silently swallowed via empty catch (lines 83-89, intentional).
- unknown first arg: usage error (line 100-103).

## `/coins <set|add|remove> <amount> <username>` (label "coins", lines 106-210)
Gate: `sender.hasPermission("k&k.coins")` (line 108), correctly gated with else (line 206-209).
- **`set`**, **`add`**, **`remove|delete|del`** subcommands mirror the Experience pattern exactly (3-arg targeted or 2-arg self-target-if-Player), delegating to private `setCoins`/`addCoins`/`removeCoins` (lines 235-352), each wrapped in try/catch, "all" flag zeroes balance with early return before duplicate message (line 330, correctly gated like Experience's).
- No args: usage message (line 204).
- Unknown subcommand (not set/add/remove/delete/del): **no else branch** — silently does nothing (v1:src/Currency/CoinCommands.java:110-201, no final else after the remove/delete/del block) — same silent-no-op class of bug.

## `/balance` (alias `bal`) (label "balance"/"bal", lines 211-231)
**No permission check** — public command (economy self-service, likely intentional).
- **`/balance <username>`** (args.length==1, lines 213-222): looks up any user by name (no online-check, uses `new User(...)` directly without destroy() — minor resource-cleanup omission, target User object never destroyed, v1:src/Currency/CoinCommands.java:217), shows coins+gems.
- **`/balance` (no args)** (lines 223-230): if sender is Player, shows own coins+gems via cached `Users.getUser`.

# 9. `/gems` — src/Currency/GemCommands.java

Domain: economy. Gate: `sender.hasPermission("k&k.gems")` (line 38), correctly gated with else (lines 145-148).
Structurally identical to `/coins`'s admin subcommand set: `set`/`add`/`remove|delete|del`, 3-arg targeted or 2-arg self (Player only), delegating to `setGems`/`addGems`/`removeGems` (lines 153-271), all wrapped in try/catch, "all" flag on remove zeroes with early return (line 249) before duplicate message — correctly gated, mirrors Coins/Experience pattern exactly.
Unlike CoinCommands' `/coins`, this one DOES have a trailing else for unrecognized subcommand and for args.length==0 — both print `staffcommandhelp` (lines 131-137, 138-144) — so no silent-no-op gap here, unlike `/coins`'s missing subcommand-else.
No public/self-serve equivalent of `/balance` exists in this file for gems alone (that's covered by CoinCommands' `/balance`).

# 10. `/lottery` — src/Events/FridayLotteryCommands.java

Domain: economy. **No `hasPermission` check anywhere** (v1:src/Events/FridayLotteryCommands.java, entire file) — gate is only `sender instanceof Player` (line 37), with a proper else sending "You need to be a player to perform this command!" (line 79) — console-safe, correctly gated.
- **`/lottery enter`** (lines 44-48): constructs `new User(uuid)`, calls `lottery.addPlayer(player, user.getAdress())` [sic, "Adress" is the actual method name typo present in source], then `user.destroy()`. No validation of whether player already entered, no confirmation message to the player at all (silent success from the player's perspective — no `sendMessage` call on the happy path, v1:src/Events/FridayLotteryCommands.java:44-48).
- **`/lottery info`** (lines 49-62): prints draw day/time, prize formula, entry price, all sourced from `FridayLottery` instance.
- **unrecognized subcommand / args.length != 1**: prints `commandhelp` (lines 63-69, 70-76).

# 11. `/kills` — src/KillsDeaths/KillCommands.java

Domain: misc/stats (per instructions). Casts sender to Player unconditionally at line 31 (console-unsafe) BEFORE the permission check even runs. Gate: `p.hasPermission("k&k.kills")` (line 33), correctly gated with else (lines 130-133).
- **`/kills add <username> <amount>`** (args.length==3, lines 37-64): validates `main.isInt(args[2])`; resolves target via `Users.getUser(Users.fetchUUIDbyUsername(args[1]))` with try/catch UserNotFoundException/Exception, early return (correctly gated). Calls `user.addKills(false, amount, amount)`. **BUG**: line 60 `Bukkit.getPlayer(args[1]).sendMessage(...)` has **no null-check** — if the target player is offline, `Bukkit.getPlayer(args[1])` returns null and this throws `NullPointerException` (v1:src/KillsDeaths/KillCommands.java:60). Contrast with CoinCommands' `/pay` which does null-check before messaging (line 59 there).
- **`/kills remove <username> <amount>`** (args.length==3, lines 66-92): same structure, `user.removeKills(false, amount, amount)`, but does NOT attempt to message the target at all (no equivalent of line 60) — so no NPE risk here, just asymmetric behavior vs. `add`.
- **`/kills add <amount>`** / **`/kills remove <amount>`** (self-target, args.length==2, lines 97-125): **BUG — missing numeric validation**: `Integer.valueOf(args[1])` at line 114 is called with **no `main.isInt(args[1])` guard** (unlike the 3-arg branches which validate at lines 39/68) — non-numeric amount throws unhandled `NumberFormatException` (v1:src/KillsDeaths/KillCommands.java:114). Also note: if `args[0]` is neither "add" nor "remove" in this 2-arg branch, there's no else/usage message — silent no-op (lines 115-124, no trailing else).
- unrecognized arg count (not 2 or 3): usage message (lines 126-129, using raw `ChatColor` not `ColorOptions`, stylistically inconsistent with rest of file which mixes both).

---

## Summary of recurring bug patterns found (beyond the seeded one)
1. **Missing-return-after-permission-check** (the seeded pattern): confirmed exactly as described at `/user save` (v1:src/Users/UserCommands.java:219-222). No second literal instance of *that exact* pattern (check-fails-but-falls-through-to-privileged-action) was found in the other 10 files — the other permission checks either return correctly or have a different bug class.
2. **Silent no-op on missing permission (no else/feedback)**: `/staffmode` (OwnerCommands.java:156-216), `/default set` (RankCommands.java:26-66), `/experience` (ExperienceCommands.java:28-146).
3. **Silent no-op on unrecognized subcommand** (no trailing else): `/coins` (CoinCommands.java:110-201), `/kills add|remove` self-target branch (KillCommands.java:115-124).
4. **Off-by-one loop bound → ArrayIndexOutOfBoundsException**: `/default set <p1> <p2> ...` (RankCommands.java:46, `i < args.length + 1`).
5. **Wrong array index reused from a different arg-count branch → ArrayIndexOutOfBoundsException**: `/donator upgrade|downgrade|remove` not-found messages reference `args[2]` in 2-arg commands (DonatorCommands.java:156, 182, 198).
6. **Missing null-check before use → NullPointerException**: `/kills add` messaging offline target (KillCommands.java:60).
7. **Missing numeric validation before parse → NumberFormatException**: `/pay coins|gems` amount (CoinCommands.java:49,73), `/kills add|remove` self-target amount (KillCommands.java:114).
8. **Dead/empty conditional branch**: `/donator set` silently does nothing when target is online (DonatorCommands.java:64-66) — inverted logic, donator-set only works for offline-but-known targets.
9. **Minor resource-cleanup omission**: `/balance <username>` never calls `target.destroy()` (CoinCommands.java:217).

**31 distinct commands/subcommands found** across user/ownermode/staffmode/stats/default/donator/experience/nexttitle/coins/pay/balance/gems/lottery/kills.
# v1 — Property/Housing domain command catalog

Full source-grounded catalog for the Property/Housing domain, based on complete reads of all three assigned files:
- v1:src/Houses/HouseCommands.java (1118 lines)
- v1:src/Houses/HomeCommands.java (78 lines)
- v1:src/Rooms/RoomCommands.java (982 lines)

All citations verbatim `v1:src/Path/File.java:line` or `line1-line2`. Feature domain is `property` for all commands unless noted.

# STRUCTURAL NOTE (applies to both HouseCommands and RoomCommands)

In both files, the top-level `onCommand` opens `if (args.length > 0)` and THEN nests `if (player.hasPermission("k&k.house.*"))` / `if (player.hasPermission("k&k.rooms"))` around only the admin subcommands (create/remove/part/spawnpoint). That inner permission block closes, and then buy/sell/info/purge/list (house) or rent/sell/info/purge/list (room) are handled as **sibling** if/else-if chains at the SAME level as the permission check — i.e. **outside** it. See v1:src/Houses/HouseCommands.java:108-511 and v1:src/Rooms/RoomCommands.java:113-430. Net effect: buy/sell/info/purge/list (house) and rent/sell/info/purge/list (room) have **no permission gate whatsoever**, including `purge` (an ownership-wipe admin action).

---

## /house create <houseName> <townName> <streetName> <houseNumber> <titleID> <grade(1-5)>
1. Syntax: `/house create <name> <townName> <streetName> <houseNumber> <titleID> <grade>` — v1:src/Houses/HouseCommands.java:77,116
2. Args: exactly 7 tokens (incl. subcommand) required, v1:...HouseCommands.java:116. args[4]/[5]/[6] must be ints, v1:...:125. titleID bounds 0-18, v1:...:134-138. grade bounds 1-5, v1:...:139-143. Requires an active WorldEdit selection, v1:...:113,118,182-185. Validates town exists (v1:...:144), street exists in town (v1:...:147), house number free on that street (v1:...:150), and that the new WorldGuard region doesn't overlap another (v1:...:158).
3. Permission: `k&k.house.*`, v1:...HouseCommands.java:110.
4. Goal: computes price via `salary=title.getSalary(titleID); dailySalary=salary*4; timePrice=random(dailySalary*30,dailySalary*60); price=round(timePrice*(1+(grade/10))/100)*100` (v1:...:722-725); saves house row (v1:...:727); creates a WorldGuard `ProtectedCuboidRegion "house_"+houseID` and registers it (v1:...:735-763); sets flags ENTRY=DENY, FEED_AMOUNT=20, FEED_DELAY=1, empty deny messages, priority 11, ENTRY regiongroup="non_members" (v1:...:766-781); runs `rg flag house_<id> deny-blocks any` via `sender.performCommand` (v1:...:783); sends success + spawnpoint-hint messages (v1:...:785-786).
5. Domain: property.
6. Bugs:
   - **Integer-division bug nullifies `grade`**: `grade/10` with grade∈[1,5] is always 0 (integer division), so `(1+(grade/10))` is always 1 — grade has zero effect on price despite being a required, validated argument. v1:...:725.
   - Leftover debug code: iterates every block in the selection and does `Bukkit.broadcastMessage("Chest detected!")` (server-wide broadcast) if a chest is found — clearly test/debug code left in production path. v1:...:743-751.
   - Dead/commented-out WorldEdit Polygonal2DRegion block. v1:...:740-761.
   - The `allow-blocks` performCommand that would whitelist chest/furnace/etc. usage inside the house is commented out (v1:...:784), while `deny-blocks any` (v1:...:783) is live — meaning nothing is actually usable inside a newly created house despite the help text implying normal habitability. Contrast with Room's equivalent, which is NOT commented out (see room create below).

## /house remove <townName> <streetName> <houseNumber>  |  /house remove <houseID>
1. Syntax: two forms, v1:...HouseCommands.java:78,193-248.
2. Args: 4-token form (town, street, houseNumber) v1:...:193-226, or 2-token form (houseID) v1:...:227-244. Validates town/street existence, numeric parsing, house exists at that street number (v1:...:207) or houseID present in `house.getHouseIDList(null)` (v1:...:233).
3. Permission: `k&k.house.*`, v1:...:110.
4. Goal (`removeHouse`, v1:...:789-863): if house has an owner, resolves owner (online via `Users.getUser`, else `offlineUser`), clears the owner's active spawnpoint only if it currently equals the house's spawnpoint (v1:...:804-806,821-823), decrements the owner's house count (v1:...:810,827); removes the house's spawnpoint row if any (v1:...:848-851); removes all house "parts" (sub-regions) from WorldGuard + DB (v1:...:853-857); removes the main WorldGuard region and DB row (v1:...:859-860); confirmation message (v1:...:862).
5. Domain: property.
6. Bugs: `User user = Users.getUser(ownerUUID);` at v1:...:800 is called with NO try/catch for `UserNotFoundException`, unlike every other `Users.getUser` call in this same file (e.g. v1:...:907-919, 976-986, 1014-1026) — inconsistent error handling, risk of an uncaught exception here specifically.

## /house part add <houseID>
1. Syntax: `/house part add <houseID>`, v1:...HouseCommands.java:79,256.
2. Args: exactly 3 tokens; args[2] must be int (v1:...:258); requires active WorldEdit selection (v1:...:260); houseID must exist (v1:...:262); new region must belong to the same house ID via `Worldguard.checkSameRegionID` (v1:...:271).
3. Permission: `k&k.house.*`, v1:...:110.
4. Goal (`addHouseRegion`, v1:...:865-900): saves a house-part DB row (v1:...:867); scans existing part IDs for one missing a live WorldGuard region to reuse as the new partID (v1:...:869-879); builds `ProtectedCuboidRegion "house_"+houseID+","+partID` (v1:...:882-886); sets it as a child of the main house region via try/catch `CircularInheritanceException` (v1:...:890-896); success message (v1:...:898).
5. Domain: property.
6. Bugs: **`manager.addRegion(gateRegion);` is commented out** — v1:...:887 (`//manager.addRegion(gateRegion);`) — the new sub-region object is built and parented but never registered with the WorldGuard `RegionManager`, so it likely has no protective effect at all. Contrast: Room's equivalent (`addRoomRegion`) DOES call `manager.addRegion(region)` live (v1:src/Rooms/RoomCommands.java:803) — this bug is House-specific.

## /house part remove <houseID> <partID>
1. Syntax: `/house part remove <houseID> <partID>`, v1:...HouseCommands.java:80,297.
2. Args: exactly 4 tokens; args[2]/args[3] must be ints (v1:...:299); houseID must exist (v1:...:301); partID validated via `house.checkPartID` (v1:...:304).
3. Permission: `k&k.house.*`, v1:...:110.
4. Goal (`removeHouseRegion`, v1:...:1109-1117): removes WorldGuard region `"house_"+houseID+","+partID"` and the DB part row; sends confirmation.
5. Domain: property.
6. Bugs: none observed beyond structural ones noted elsewhere.

## /house spawnpoint set
1. Syntax: `/house spawnpoint set` (stand inside the house), v1:...HouseCommands.java:81,340.
2. Args: none beyond subcommand; behavior derived from current player location.
3. Permission: `k&k.house.*`, v1:...:110 (no further check).
4. Goal: gets player location (v1:...:342); requires standing inside a "house" WorldGuard region (v1:...:343-345); derives houseID from the region (v1:...:348); only proceeds if the house has no spawnpoint yet (v1:...:349); saves a new spawnpoint row and links it to the house (v1:...:351-352); success message with full house/street/town description (v1:...:353).
5. Domain: property.
6. Bugs: none observed.

## /house spawnpoint remove <houseID>  |  /house spawnpoint remove <streetName> <streetNumber> <townName>
1. Syntax: two forms, v1:...HouseCommands.java:82,371-479.
2. Args: ID form requires args.length>=3 with args[2] numeric (v1:...:369-371); location form requires args.length==5 with args[3] numeric (v1:...:414-420).
3. Permission: `k&k.house.*`, v1:...:110.
4. Goal: verifies house exists and has a spawnpoint; if the house has an owner, resolves the owner (try/catch `UserNotFoundException`, v1:...:383-395 / 437-449) and calls `user.removeSpawnpoint()` **unconditionally** (not just when it matches the house's spawnpoint), then removes the house's spawnpoint row and the spawnpoint DB entry (v1:...:396-405 / 450-459).
5. Domain: property.
6. Bugs:
   - Unlike `removeHouse()` which only clears the owner's personal spawnpoint if it currently equals the house's spawnpoint (v1:...:804), this handler clears the owner's spawnpoint unconditionally whenever the house has an owner (v1:...:379-398, and duplicated at 433-452) — could wipe a player's active "home" even if it currently points elsewhere.
   - The two branches (ID-based, v1:...:373-413; location-based, v1:...:416-479) are near-duplicate logic copy-pasted rather than shared.

## /house <unrecognized subcommand under k&k.house.*> — help-print side effect on `purge`
Because the exclusion list at v1:...HouseCommands.java:502 (`!= buy && != sell && != info && != list`) omits `purge`, a staff user with `k&k.house.*` running `/house purge ...` triggers a spurious full `staffcommandhelp` printout (v1:...:504-508) in addition to `purge` executing normally afterward at v1:...:646-689. Bug, cite v1:...:502-508 vs 646.

## /house buy <streetName> <streetNumber> <townName>  |  /house buy <houseID>
1. Syntax: two forms, v1:...HouseCommands.java:83,513-561.
2. Args: 4-token street/town form (v1:...:513-545) or 2-token houseID form (v1:...:546-561); validates town/street/number lookups or houseID list membership.
3. Permission: **none checked** — this branch is outside the `k&k.house.*` gate entirely (see structural note).
4. Goal (`buyHouse`, v1:...:902-967): resolves buyer's User (try/catch, v1:...:907-919); checks `user.canBuyHouse()` slot limit (v1:...:930-934); if `coins >= price` and house unowned: saves ownership (v1:...:939), increments house count (v1:...:940), deducts coins (v1:...:941), grants WorldGuard region membership via `house.addRegionOwner` (v1:...:943); sets buyer's spawnpoint to the house's spawnpoint if one exists (v1:...:950-956); sends purchase confirmation with price paid (v1:...:957-958). Errors: house owned by someone else (v1:...:961), insufficient coins with shortfall shown (v1:...:965).
5. Domain: property (economy transaction).
6. Bugs:
   - Dead/unreachable branch: `if (user.getHouseAmount(false) == 0)` at v1:...:946 is evaluated **after** `user.addHouseAmount(false,1)` was already called at v1:...:940, so the count is already ≥1 and the "Congratulations on your first house!" message (v1:...:948) can never fire under normal conditions.
   - `houseAmount` and `houseMax` locals fetched at v1:...:923-924 are effectively dead — the real limit check uses `user.canBuyHouse()` (v1:...:930) instead.

## /house sell <streetName> <streetNumber> <townName>
1. Syntax: `/house sell <streetName> <streetNumber> <townName>` (no houseID shortcut, unlike buy/info), v1:...HouseCommands.java:84,568-604.
2. Args: exactly 4 tokens; only this one form supported.
3. Permission: none (outside gate).
4. Goal (`sellConfirm`, v1:...:969-1008): resolves seller's User (try/catch, v1:...:974-986); requires `house.getHouseOwnerID(houseID) == user.getID()` (v1:...:995); on success, stores pending-confirmation state in static maps `sellconfirm`/`sellpropertyID` keyed by UUID (v1:...:997-998, declared v1:...:71-72) and prompts "type yes or no" showing a refund of `price/2` (v1:...:1000-1003). **The actual finalize-on-"yes" logic (coin refund, ownership clear) is not present in this file** — presumably handled by a chat/event listener elsewhere, out of scope of the three assigned files; noted as unclear/out-of-scope rather than assumed.
5. Domain: property.
6. Bugs: none observed in this file's portion; owned-by-someone-else error at v1:...:1006.

## /house info <streetName> <streetNumber> <townName>
1. Syntax: `/house info <streetName> <streetNumber> <townName>` (4-token only, no houseID shortcut), v1:...HouseCommands.java:85,609-641.
2. Args: exactly 4 tokens.
3. Permission: none for invoking; ID field only shown if `sender.hasPermission("k&k.house")` or `main.ownermodus` contains sender, v1:...:1036.
4. Goal (`infoHouse`, v1:...:1010-1058): displays name, location, price for any house; owner section conditionally shown.
5. Domain: property.
6. Bugs — **confirmed bug**: `User user = Users.getUser(sender.getUniqueId())` (v1:...:1016) resolves the VIEWER's own account, not the house owner's. Later, when displaying the "Owner"/"Titlename"/"Experience" block (v1:...:1048-1055), the code uses this same `user` variable's fields (`user.getUUID()`, `user.getGenderID()`, `user.getTitleID()`, and implicitly `user.getUsername()`) even though `Integer userID = house.getHouseOwnerID(houseID);` is computed at v1:...:1048 and never actually used to look up a different User object. Net effect: `/house info` on someone else's owned house shows the **viewer's own** username/title/experience as if they were the owner.

## /house purge <houseID|all>
1. Syntax: `/house purge <houseID/all>`, v1:...HouseCommands.java:86,646-689.
2. Args: exactly 2 tokens; args[1]="all" or numeric houseID (v1:...:648-669), validated against `house.getHouseIDList(null)`.
3. Permission: **none checked anywhere in this branch** — v1:...:646-689 has no `hasPermission` call. This is reachable by any player who can run `/house` with args, despite being listed only in `staffcommandhelp` (v1:...:86). Significant bug.
4. Goal: for "all", iterates every house ID and calls `house.purgeHouseOwner(houseID2)` (v1:...:673-677); for a single ID, same call once (v1:...:680-682). `purgeHouseOwner` itself lives in `House.java` (not in assigned scope) but by naming/usage pattern clears ownership.
5. Domain: property.
6. Bugs: no permission check (see above); on invalid arg[1], sends a blank error string `ColorOptions.error + ""` (v1:...:684) — near-silent failure, minor UX bug. Also triggers the spurious staffcommandhelp print noted above when run by a `k&k.house.*` staffer (v1:...:502-508).

## /house list
1. Syntax: `/house list`, v1:...HouseCommands.java:87,691-694.
2. Args: none.
3. Permission: none to invoke; ID column gated by `sender.isOp() || sender.hasPermission("k&k.house") || main.ownermodus...`, v1:...:1086.
4. Goal (`houseList`, v1:...:1060-1107): resolves viewer's own User (v1:...:1064-1076); iterates all houses, printing name/price and availability status.
5. Domain: property.
6. Bugs — **same class of bug as infoHouse**: for unavailable houses, v1:...:1102 prints `user.getUsername()` where `user` is still the VIEWER's own resolved User object (from v1:...:1066), never reassigned to the actual owner. `userID` (v1:...:1099) and `uuid = user.getUUID()` (v1:...:1100) are computed/fetched but never used to look up the real owner — so every "Unavailable" house incorrectly shows the viewer's own username as "Owner".

## /house (no args)
1. Syntax: bare `/house`.
2. Args: none.
3. Permission: `k&k.house` (note: singular, distinct string from the `k&k.house.*` gate used for admin subcommands) determines whether `staffcommandhelp` or public `commandhelp` is shown, v1:...HouseCommands.java:697.
4. Goal: prints help list.
5. Domain: property.
6. Bugs: none; notable that the codebase uses two related-but-different permission nodes for house (`k&k.house.*` for admin actions, `k&k.house` for help/ID visibility) — worth flagging for v3 permission-model design.

---

## /home
1. Syntax: `/home` (no args, no aliases per prompt), v1:src/Houses/HomeCommands.java:27-77.
2. Args: none.
3. Permission: `k&k.home`, v1:...HomeCommands.java:34 (else falsecommand error, v1:...:68).
4. Goal: resolves user (`Users.getUser(uuid)` — **not wrapped in try/catch**, just a null-check `if ((user = Users.getUser(uuid)) != null)`, v1:...:39); compares user's current spawnpointID to the ID of the default "spawn" spawnpoint (v1:...:41-42) — if equal, tells player they have no home yet (buy a house / rent a room) (v1:...:60); otherwise, if the player is in `main.ownermodus` (staff/owner mode), teleports directly with no duel check (v1:...:44-47); otherwise checks `Arena.isDuelling(uuid)` and blocks with an error if true (v1:...:50-54); otherwise delegates to `spawnpoint.tryRegularTeleport(user, spawnpoint.getSpawnPointName(spawnpointID))` (v1:...:56) — actual teleport/cooldown mechanics live in `SpawnPoint` class, out of scope, so exact warmup/cooldown behavior is unclear from this file.
5. Domain: property-adjacent (teleport utility; the "home" location itself is set as a side effect of buying a house or renting a room).
6. Bugs: `Users.getUser(uuid)` at v1:...:39 has no try/catch for `UserNotFoundException`, inconsistent with the pattern used in HouseCommands/RoomCommands (e.g. v1:src/Houses/HouseCommands.java:907-919) — risk of an uncaught exception instead of a graceful message if the user record is missing/throws.

---

## /room create <streetName> <streetNumber> <townName> <roomNumber> <price>
1. Syntax, v1:src/Rooms/RoomCommands.java:66,120. Property that owns the room ("tavern") is looked up, not created here — rooms attach to an existing `Property`.
2. Args: exactly 6 tokens; args[2]/args[4]/args[5] must be ints (v1:...:129); requires active WorldEdit selection (v1:...:122-123); requires town (v1:...:137), street (v1:...:140), and an existing property/"tavern" at that street+number (v1:...:143); requires room number not already used at that property (`room.checkRoom(...)==false`, v1:...:146); requires unique WorldGuard region (v1:...:153).
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal (`createRoom`, v1:...:703-744): saves room row (v1:...:706); creates `ProtectedCuboidRegion "room_"+roomID` and **correctly registers it** via `regionManager.addRegion(region)` (v1:...:718); sets flags ENTRY=DENY, DENY_MESSAGE empty, FEED_AMOUNT=20, FEED_DELAY=1, ENTRY_DENY_MESSAGE empty, **CHEST_ACCESS=ALLOW** (v1:...:721-726), priority 12; sets ENTRY regiongroup="non_members" (v1:...:729-737); runs `rg flag room_<id> deny-blocks any` then **`rg flag room_<id> allow-blocks chest, 58, 26, bookshelf, furnace`** (v1:...:739-740) — unlike House's equivalent, this allow-blocks command is NOT commented out.
5. Domain: property.
6. Bugs: the error message at v1:...:179 references `args[3]` and `args[6]` for the "must be numbers" values, but the actual validated indices are `args[2]`, `args[4]`, `args[5]` (v1:...:129) — wrong variable indices shown to the user (cosmetic but genuinely wrong).

## /room remove <streetName> <streetNumber> <townName> <roomNumber>
1. Syntax, v1:...RoomCommands.java:67,192.
2. Args: exactly 5 tokens; args[2]/args[4] numeric (v1:...:194); requires town/street/property/room lookups to resolve to an existing `roomID` via `room.getRoomID` (v1:...:210).
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal (`removeRoom`, v1:...:746-779): if room has an owner, decrements their room count (online path v1:...:756, offline path v1:...:759) using `Users.fetchUUIDbyID` + `Users.getUser` **not wrapped in try/catch** (v1:...:751-753); removes the room's spawnpoint row if set (v1:...:764-767); removes all room parts and the main WorldGuard region + DB row (v1:...:769-776); confirmation message (v1:...:778).
5. Domain: property.
6. Bugs:
   - Same unguarded `Users.getUser` pattern as House's `removeHouse`, v1:...:753.
   - Unlike `removeHouse()` (HouseCommands.java:804-807), `removeRoom()` does **not** first check whether the room's spawnpoint equals the owner's currently-active personal spawnpoint before deleting the spawnpoint row — it just decrements room count and deletes the spawnpoint outright (v1:...:748-767), risking the former renter's saved home pointing at a now-deleted spawnpoint record.
   - Error message v1:...:232 references `args[3]`/`args[5]` instead of the actually-validated `args[2]`/`args[4]` — same class of index-mismatch bug as create.

## /room part add <roomID>
1. Syntax, v1:...RoomCommands.java:68,245.
2. Args: exactly 3 tokens; args[2] numeric (v1:...:247); requires WorldEdit selection (v1:...:250-251); roomID must exist (v1:...:253); `Worldguard.checkSameRegionID` check (v1:...:261).
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal (`addRoomRegion`, v1:...:781-816): saves room-part row, finds a free partID by scanning existing parts for one lacking a live region (v1:...:785-795), builds region `"room_"+roomID+","+partID` and **correctly calls `manager.addRegion(region)`** (v1:...:798-803) — contrast with House's equivalent where this call is commented out (HouseCommands.java:887); sets parent via try/catch `CircularInheritanceException` (v1:...:806-812); success message (v1:...:814).
5. Domain: property.
6. Bugs: none observed (this is the "correct" counterpart to the House part-add bug).

## /room part remove <roomID> <partID>
1. Syntax, v1:...RoomCommands.java:69,287.
2. Args: exactly 4 tokens; args[2]/args[3] numeric; roomID exists (v1:...:293); partID validated via `room.checkPartID` (v1:...:295).
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal (`removeRoomRegion`, v1:...:818-824): removes region and DB part row; confirmation.
5. Domain: property.
6. Bugs: none observed.

## /room spawnpoint set
1. Syntax: help text says "add" (v1:...RoomCommands.java:70) but the code's actual keyword is "set" (v1:...:330) — **doc/code mismatch in the built-in help text itself**.
2. Args: none beyond subcommand; behavior derived from player's current location.
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal: requires standing inside a "room" WorldGuard region (v1:...:333-335); derives roomID; only proceeds if room has no spawnpoint yet (v1:...:339); saves spawnpoint and links it (v1:...:341-342); success message (v1:...:343, minor formatting: missing space before the concatenated roomID value).
5. Domain: property.
6. Bugs: help-text/code mismatch noted above.

## /room spawnpoint remove <roomID>
1. Syntax: `/room spawnpoint remove <roomID>` (no street/town alternate form, unlike House), v1:...RoomCommands.java:71,357-407.
2. Args: exactly 3 tokens; args[2] numeric (v1:...:361); roomID must exist (v1:...:364) and have a spawnpoint (v1:...:366).
3. Permission: `k&k.rooms`, v1:...:115.
4. Goal: if room has an owner, resolves them via `Users.fetchUUIDbyID`+`Users.getUser` **not wrapped in try/catch** (v1:...:372-373), removes the owner's personal spawnpoint unconditionally (v1:...:377/381) — same "unconditional clear" pattern flagged for House — then removes the room's spawnpoint row (v1:...:389-390) and confirms (v1:...:391).
5. Domain: property.
6. Bugs: unconditional owner-spawnpoint clear (not gated on equality check) as with House's equivalent; unguarded `Users.getUser` call.

## /room <unrecognized, under k&k.rooms gate> — help-print side effect on `purge`
Exclusion list at v1:...RoomCommands.java:421 also omits `purge`, so `/room purge ...` run by a `k&k.rooms` holder triggers a spurious `staffcommandhelp` printout (v1:...:422-427) in addition to normal purge execution at v1:...:621-664. Same bug class as House.

## /room rent <streetName> <streetNumber> <townName> <roomNumber>  |  /room rent <roomID>
1. Syntax: two forms, v1:...RoomCommands.java:72,432-492.
2. Args: 5-token location form or 2-token roomID form; standard lookup validation.
3. Permission: **none** — outside the `k&k.rooms` gate (structural note above).
4. Goal (`rentRoom`, v1:...:826-879): if `coins >= price` (v1:...:839) and room unowned (v1:...:841) and `user.getRoomAmount(false) < user.getRoomAmount(true)` (under slot max, v1:...:843): **then an inner check `if (user.getRoomAmount(false) == 0)`** (v1:...:845) gates the actual rent logic — sets owner (v1:...:847), increments room count (v1:...:848), deducts coins (v1:...:849), records rent start time via `user.saveRentTime()` (v1:...:850, implying hourly billing processed elsewhere, out of scope/unclear), then immediately calls **`room.purgeRoomOwner(roomID)`** (v1:...:851). Commented-out `//room.addRegionOwner(sender, roomID, manager);` (v1:...:852) means WorldGuard membership is never actually granted to the renter (contrast with House's live `house.addRegionOwner` call at HouseCommands.java:943). Sets renter's spawnpoint if the room has one (v1:...:854-860); success message including "per hour that you are online" pricing note (v1:...:861-862).
5. Domain: property (economy).
6. Bugs — multiple significant ones:
   - **Renting a 2nd+ room silently no-ops**: the inner condition `user.getRoomAmount(false) == 0` (v1:...:845) means the entire rent-success block only executes if the player currently owns ZERO rooms, even though the outer condition at v1:...:843 already confirmed they're under their max slot count (e.g. 1 < 2 would pass the outer check but fail this inner one). If a player already rents 1 room and tries to rent a 2nd within their allowance, **nothing happens at all** — no coins deducted, no error message, no success message, completely silent no-op.
   - **Ownership immediately purged after being set**: `room.saveOwnerID(roomID, uuid)` (v1:...:847) is followed a few lines later by `room.purgeRoomOwner(roomID)` (v1:...:851) — by naming/usage parity with the admin `/room purge` command (v1:...:650,655) and House's analogous `house.purgeHouseOwner` (HouseCommands.java:675,680), this method appears to clear ownership — meaning the just-set owner may be immediately unset. (Exact internals live in `Room.java`, out of scope, but the naming strongly suggests this bug; flagged as high-confidence but not 100% verifiable without that file.)
   - WorldGuard region membership is never granted to the renter (`addRegionOwner` call commented out, v1:...:852) — renter may lack actual build/enter rights despite the DB recording them as owner.
   - The final `else` branch (v1:...:867-869, generic "can't rent a room!") appears logically unreachable given the two prior conditions (`<` and `==`) exhaust the possible relations under normal data invariants — dead/defensive code, not confirmed harmful.

## /room sell <streetName> <streetNumber> <townName> <roomNumber>  |  <roomID>
1. Syntax: two forms, v1:...RoomCommands.java:73,496-555.
2. Args: standard lookup validation, same pattern as rent.
3. Permission: none.
4. Goal (`sellConfirm`, v1:...:881-903): requires `room.getOwnerID(roomID) == user.getID()` (v1:...:891); stores pending state in static maps `sellconfirm`/`sellRoomID` (v1:...:893-894, declared v1:...:60-61); prompts yes/no. **Unlike House's sellConfirm, this prompt does not display the refund amount at all** (compare v1:...:896-898 to HouseCommands.java:1000-1003, which explicitly shows `price/2`). Actual finalize-on-confirm logic not present in this file (out of scope/unclear, same as House).
5. Domain: property.
6. Bugs: missing refund-amount display in the confirmation prompt (UX inconsistency vs. House).

## /room info <streetName> <streetNumber> <townName> <roomNumber>  |  <roomID>
1. Syntax: two forms, v1:...RoomCommands.java:74,560-620. Note the args.length!=5/2 fallback error message at v1:...:619 says "Usage: /room sell ..." instead of "/room info ..." — copy-paste bug in the error text.
2. Args: standard lookup validation.
3. Permission: none to invoke; ID shown only if `sender.hasPermission("k&k.room")` (singular) or in `ownermodus`, v1:...:917.
4. Goal (`infoRoom`, v1:...:905-940): displays roomnumber, tavern/street/town location, rent price; for owner section, **correctly** resolves the actual owner's identity via `Integer userID = room.getOwnerID(roomID); UUID uuid = this.user.getUUIDbyID(userID);` using the `offlineUser` helper (v1:...:930-937) rather than reusing the viewer's own `user` — this correctly avoids the bug found in House's `infoHouse()`.
5. Domain: property.
6. Bugs: only the copy-paste usage-message text bug noted above; the owner-identity bug present in House does NOT occur here.

## /room purge <roomID|all>
1. Syntax, v1:...RoomCommands.java:75,621-664.
2. Args: exactly 2 tokens; "all" or numeric roomID validated against `room.getRoomIDList(null)`.
3. Permission: **none checked** — same bug as House purge; this branch (v1:...:621-664) has no `hasPermission` call despite being a `staffcommandhelp`-only listed command.
4. Goal: purges single room or all rooms' ownership via `room.purgeRoomOwner`.
5. Domain: property.
6. Bugs: no permission check; blank error message on invalid arg (`ColorOptions.error + ""`, v1:...:659) same as House.

## /room list
1. Syntax, v1:...RoomCommands.java:76,666-668.
2. Args: none.
3. Permission: none to invoke; ID shown only if `sender.isOp() || sender.hasPermission("k&k.room") || ownermodus`, v1:...:960.
4. Goal (`roomList`, v1:...:942-981): iterates all rooms, shows number/location/price/availability; for "Unavailable" rooms, **correctly** resolves and displays the actual renter's username via `this.user.getUUIDbyID(userID)` / `getUserName` (v1:...:973-976) — again correctly avoiding the House-list identity bug.
5. Domain: property.
6. Bugs: none observed (correct counterpart to the buggy House list).

## /room (no args)
1. Syntax: bare `/room`, v1:...RoomCommands.java:679-694.
2. Args: none.
3. Permission: `k&k.room` (singular) gates staff vs. public help, v1:...:681.
4. Goal: prints help list. **Note**: the public `commandhelp` list (v1:...:79-87) literally reads "/house buy <houseName>", "/house sell...", "/house info...", "/house list" — a clear copy-paste bug: it was never updated from HouseCommands' text to reference `/room`/rent terminology.
5. Domain: property.
6. Bugs: copy-pasted House help text shown to players running `/room` with no permission (v1:...:82-85).

## /room <unrecognized final fallback> — silent no-op for unprivileged create/remove/part/spawnpoint
At v1:...RoomCommands.java:669-678, the final else of the rent/sell/info/purge/list chain checks `if (!args[0].equals(create/remove/part/spawnpoint))` before printing staffcommandhelp — meaning if it IS one of those four, **nothing is printed at all**. Since create/remove/part/spawnpoint are only handled inside the `k&k.rooms`-gated block (v1:...:115-429), an unprivileged player typing e.g. `/room create ...` gets zero feedback: no permission-denied message, no usage help, completely silent. Bug/UX gap, cite v1:...:113-119 and 669-678.

---

**25 distinct commands/subcommands found across houses/homes/rooms** (12 under `/house`, 1 `/home`, 12 under `/room`).

Key cross-cutting findings worth flagging to the merge/catalog effort:
- Both `/house` and `/room` have a structural permission gap: buy/sell/info/list AND the admin-only `purge` are all reachable with no permission check.
- Permission-node inconsistency: House uses `k&k.house.*` (admin) vs `k&k.house` (help/ID visibility); Room uses `k&k.rooms` (admin, plural) vs `k&k.room` (help/ID visibility, singular) — four distinct, unrelated-looking node strings for what is conceptually the same two-tier split.
- Owner-identity display bug exists in House's `infoHouse`/`houseList` but was correctly avoided in Room's `infoRoom`/`roomList` — suggests Room was written/fixed later or by someone more careful.
- The "purge immediately after rent" (`room.purgeRoomOwner` right after `saveOwnerID`, RoomCommands.java:847-851) and the "can only rent when you own zero rooms" bug (RoomCommands.java:845) are the two most consequential functional bugs found — worth prioritizing for v3 spec review since they suggest room renting for a 2nd room may be effectively non-functional in v1.
# v1 — Property/category/resource domain command catalog

Files read in full:
- `src/Properties/PropertyCommands.java` (1077 lines) — registered `/property`
- `src/Properties/PropertyCategoryCommands.java` (249 lines) — registered `/propertycategory`, alias `pc`
- `src/Resources/ResourceCommands.java` (312 lines) — registered `/resourceproperty`, alias `rp`

**Structural note (important, applies to almost every /property subcommand):** In `onCommand` of `PropertyCommands.java`, the permission-gated block `if (player.hasPermission("k&k.property"))` (v1:src/Properties/PropertyCommands.java:129) only wraps `create`, `remove`, `part`, `spawnpoint` (args.length>0 branch, lines 131–495) and an args.length==0 branch (497–512, see bug below). It closes at line 513. Immediately after, at v1:src/Properties/PropertyCommands.java:514, a **sibling** `if (args.length > 0)` block handles `buy`, `sell`, `info`, `purge`, `shopkeepercheck`, `list` — this sibling block is NOT inside the permission check, so these six subcommands run for **any player**, permission or not.

---

## /property create
1. **Syntax**: `/property create <name> <streetName> <townName> <streetNumber> <category> <titleID> <contribution>` (usage string at v1:src/Properties/PropertyCommands.java:217; note the string lists 7 params but code requires exactly 8 args incl. `create` token).
2. **Arguments**: requires `args.length == 8` (v1:src/Properties/PropertyCommands.java:137). args[1]=name, args[2]=streetName, args[3]=townName, args[4]=streetNumber (must be int, v1:149), args[5]=category name, args[6]=titleID (must be int, v1:149), args[7]=contribution (must be int, v1:149). Requires an active WorldEdit selection (v1:143). Validates: titleID exists in `title.getIDList()` (v1:155); `main.checkContribution(contribution)` (v1:157); town exists (v1:159); street exists in that town (v1:162); street number not already used (v1:165); WorldGuard region doesn't overlap another "property" region (v1:173); category exists (v1:175).
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129 (guards the whole create/remove/part/spawnpoint block).
4. **Goal**: Builds a `ProtectedCuboidRegion` from the WorldEdit selection, computes price/income from title salary and contribution, persists via `property.saveProperty(...)` (v1:813), creates the WorldGuard region named `property_<id>`, sets ENTRY=ALLOW and empty deny messages, priority 11, then runs `/rg flag property_<id> deny-blocks any` via `performCommand` (v1:819-834).
5. **Domain**: property.
6. **Bugs/edge cases**:
   - v1:src/Properties/PropertyCommands.java:209 — the error message for non-numeric args references `args[8]`, but `args.length==8` means valid indices are 0-7; this throws `ArrayIndexOutOfBoundsException` whenever this branch is reached (i.e., whenever args[4]/[6]/[7] aren't ints).
   - v1:src/Properties/PropertyCommands.java:809 — `Integer price = ... Math.round((timePrice*(1+(contribution/100)))/100.0)*100`. `contribution/100` is **integer division** on an `Integer`/`int`; for any contribution < 100 this truncates to 0, making the multiplier always `1` regardless of the actual contribution value — contribution appears to have no effect on price unless it is ≥100.
   - v1:src/Properties/PropertyCommands.java:810 — similarly `((price-(price/4))/100)/100.0` divides by int 100 before the final `/100.0`, causing precision loss/truncation before the double division is applied.

## /property remove
1. **Syntax**: `/property remove <town-name> <streetname> <housenumber>` OR `/property remove <propertyID>` (v1:src/Properties/PropertyCommands.java:272-273, 277-278).
2. **Arguments**: Two forms dispatched by `args.length`: 4-arg form (townName=args[1], streetName=args[2], streetNumberString=args[3], v1:224-226) validates town exists, street exists in town, streetNumber is int, and that a property occupies that street/number (`property.checkStreetNumber(...) == false`, v1:236). 2-arg form (args[1]=propertyID, v1:259-268) validates int and that ID exists in `property.getIDList(null,null)`.
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129.
4. **Goal**: `removeProperty` (v1:841-877) — if property has an owner, decrements owner's property-amount counter (via `User.removePropertyAmount` or `offlineUser.removePropertyAmount` fallback, v1:851-864); removes all WorldGuard sub-part regions and their DB rows (v1:866-870); removes the main `property_<id>` region; calls `propertyproduct.removeAllbyProperty(propertyID)` (removes associated shop products) and `property.removePropertybyID(propertyID)` (v1:872-874).
5. **Domain**: property.
6. **Bugs/edge cases**: none obviously wrong in this subcommand's logic beyond the shared "no return after error message" style found throughout (e.g. v1:246 sends error but doesn't `return`, though the surrounding if/else chain makes this benign here since it's the terminal else).

## /property part add
1. **Syntax**: `/property part add <propertyID>` (v1:src/Properties/PropertyCommands.java:323, 76).
2. **Arguments**: `args.length == 3` required for the `add` form nested inside `args[0]=="part"` requiring `args.length>=3` (v1:283, 287). args[2] must be int (v1:289) and must be an existing property ID (v1:293). Requires active WorldEdit selection (v1:291). Validates new region doesn't overlap a different property's gateRegion via `Worldguard.checkSameRegionID` (v1:302).
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129.
4. **Goal**: `addPropertyRegion` (v1:879-914) — calls `property.savePropertyPart(propertyID)` to allocate a new part row, then scans existing part IDs to find one not yet backed by a WorldGuard region (v1:886-893, though the actual `manager.addRegion` call is commented out at v1:901 — the sub-region is constructed but never added to the WorldGuard manager!), sets it as a child of the main `property_<id>` region via `region.setParent(...)` (v1:906), catching `CircularInheritanceException` by just printing a stack trace (v1:907-910).
5. **Domain**: property.
6. **Bugs/edge cases**:
   - v1:src/Properties/PropertyCommands.java:901 — `//manager.addRegion(gateRegion);` is commented out. The new `ProtectedCuboidRegion` sub-part is built and parented, but never registered with the `RegionManager`, so the part-region likely does not persist/apply in WorldGuard despite the success message being sent.
   - If `partID` remains `null` (all existing part IDs already have regions, loop at 886-893 never breaks), the code still proceeds to build a region named `"property_" + propertyID + ",null"` (v1:897) — no null-check before use.

## /property part remove
1. **Syntax**: `/property part remove <propertyID> <partID>` (v1:src/Properties/PropertyCommands.java:353, 77).
2. **Arguments**: `args.length == 4` (v1:328). args[2] and args[3] must be ints (v1:330). args[2] must be a valid property ID (v1:332); args[3] must be a valid part ID for that property via `property.checkPartID` (v1:335).
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129.
4. **Goal**: `removePropertyRegion` (v1:916-924) — removes WorldGuard region `property_<id>,<partID>` and removes the DB part row via `property.removePropertyPart` (v1:920-921).
5. **Domain**: property.
6. **Bugs/edge cases**: none additional found.

## /property spawnpoint set
1. **Syntax**: `/property spawnpoint set` (v1:src/Properties/PropertyCommands.java:78; "While standing inside the property").
2. **Arguments**: none beyond the literal `set` token. Uses the player's current location (v1:373).
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129.
4. **Goal**: Verifies the player is standing inside a WorldGuard region and that region resolves to a "property" region (v1:374-378), derives `propertyID` via `Worldguard.getStructureIDbyRegion` (v1:379). If the property has no spawnpoint yet (`property.getPropertySpawnPoint(propertyID) == 0`, v1:380), saves a new spawnpoint (`spawnpoint.saveSpawnPoint(...)`, v1:382) and links it to the property (`property.savePropertySpawnPoint`, v1:383).
5. **Domain**: property.
6. **Bugs/edge cases**: none found beyond generic patterns.

## /property spawnpoint remove
1. **Syntax**: `/property spawnpoint remove <id>` OR `/property spawnpoint remove <streetname> <streetnumber> <townname>` (usage strings at v1:src/Properties/PropertyCommands.java:472-473, though the earlier inline usage at v1:466-467 mistakenly says "/house spawnpoint remove" — leftover from a renamed command).
2. **Arguments**: two forms by arg count under `args[1]=="remove"` (v1:398): `args.length>=3` with args[2] numeric propertyID (v1:402-406, note: `>=3` check but only args[2] used, extra args ignored) validated against `property.getIDList(null,null)` (v1:404) and requires the property currently has a spawnpoint (`!= 0`, v1:407); or `args.length==5` form (v1:421) with streetName=args[2], streetNumber=args[3] (int-checked, v1:425), townName=args[4], resolving town → street → property by location (v1:428-436), then removing if `getPropertySpawnPoint(propertyID) != null` (v1:437).
3. **Permission**: `k&k.property`, v1:src/Properties/PropertyCommands.java:129.
4. **Goal**: Removes the property→spawnpoint link (`property.removePropertySpawnPoint`) and deletes the spawnpoint row (`spawnpoint.removeSpawnPoint`) (v1:410-411, 440-441).
5. **Domain**: property.
6. **Bugs/edge cases**: v1:src/Properties/PropertyCommands.java:437 checks `property.getPropertySpawnPoint(propertyID) != null` (Integer null-check) whereas the id-based form at v1:407 checks `!= 0` — inconsistent sentinel semantics between the two code paths for "no spawnpoint" (one treats 0 as "none", the other treats null as "none"); if the underlying getter can return primitive `0` in both cases, the 5-arg form's null check would never be true and the "doesn't have a spawnpoint" branch (v1:443-446) would be unreachable.

## /property buy
1. **Syntax**: `/property buy <streetName> <streetNumber> <townName>` OR `/property buy <propertyID>` (v1:src/Properties/PropertyCommands.java:569; 2-arg form at v1:551).
2. **Arguments**: 4-arg form (v1:518): streetName=args[1], streetNumber=args[2] (int-checked, v1:522), townName=args[3]; resolves town→street→property by location. 2-arg form (v1:551): args[1] must be int propertyID, must exist in `property.getIDList(null,null)` (v1:556).
3. **Permission**: **No permission check** — this subcommand sits in the sibling `if (args.length > 0)` block at v1:514, outside the `k&k.property` guard at v1:129-513. Any player can buy a property.
4. **Goal**: `buyProperty` (v1:926-970) — checks the buyer's current property count vs. their max slot allowance, refusing with a gem-shop upsell message if over (v1:941-945); checks the buyer has enough coins (v1:946); if the property is unowned (`getPropertyOwnerID == 0`, v1:948) it saves the new owner (`property.savePropertyOwner`), resets the owner's income timer (`user.saveIncomeTime()`), deducts coins (`user.removeCoins(price)`), and grants WorldGuard region ownership (`property.addRegionOwner`) (v1:950-954). Sends a special "first property" congratulations message if this is the buyer's first (v1:956-959).
5. **Domain**: property.
6. **Bugs/edge cases**: No permission check at all for a coin-spending, ownership-transferring action (intentional design per the help-text listing it as a public command, but worth flagging explicitly since it's asymmetric with `create`/`remove`).

## /property sell
1. **Syntax**: `/property sell <streetName> <streetNumber> <townName>` (v1:src/Properties/PropertyCommands.java:609). No propertyID-only form exists for sell (unlike buy/remove).
2. **Arguments**: `args.length == 4` only; streetName=args[1], streetNumber=args[2] (int-checked, v1:578), townName=args[3]; resolves town→street→property by location (v1:574-606).
3. **Permission**: No permission check (same sibling block as `buy`, v1:514).
4. **Goal**: `sellConfirm` (v1:972-996) — only proceeds if `property.getPropertyOwnerID(propertyID) == user.getID()` (v1:983); if so, stores a pending-confirmation flag in the static maps `sellconfirm`/`sellpropertyID` keyed by player UUID (v1:985-986) and prompts the player to type `yes`/`no` (actual sale completion is presumably handled elsewhere, e.g. a chat listener — not in this file).
5. **Domain**: property.
6. **Bugs/edge cases**: Sale price shown to the player is `price/2` (v1:990, integer division) — 50% of the purchase price, not derived from any stored "sell price" field. The actual chat-confirmation handler (where `sellconfirm`/`sellpropertyID` are consumed) is not in this file, so full sale-completion logic could not be verified from these three files.

## /property info
1. **Syntax**: `/property info <streetName> <streetNumber> <townName>` (v1:src/Properties/PropertyCommands.java:649). No propertyID-only form.
2. **Arguments**: `args.length == 4`; streetName=args[1], streetNumber=args[2] (int-checked, v1:618), townName=args[3]; resolves property by street/town location (v1:612-646).
3. **Permission**: No permission check for invoking `info` itself (sibling block, v1:514). Inside `infoProperty`, showing the property **ID** specifically is gated on `sender.hasPermission("k&k.property") || main.ownermodus.containsKey(sender.getUniqueId())` (v1:1011) — cosmetic gate only, not an access gate.
4. **Goal**: `infoProperty` (v1:998-1036) — prints name, category, location, price, income, level; if unowned prints `-Owner: -` (v1:1021-1023), else looks up owner via `offlineUser` helper methods and prints owner name, title name, and experience (v1:1026-1034).
5. **Domain**: property.
6. **Bugs/edge cases**: none found beyond the cosmetic-gate note above.

## /property purge
1. **Syntax**: `/property purge <propertyID/all>` (v1:src/Properties/PropertyCommands.java:84, usage sent via `staffcommandhelp.get(11)` at v1:695 on wrong arg count).
2. **Arguments**: `args.length == 2`; args[1] is either literal `all` (v1:657) or an int propertyID validated against `property.getIDList(null,null)` (v1:661-667).
3. **Permission**: **No permission check.** This subcommand is in the sibling `if (args.length > 0)` block at v1:514 (outside the `k&k.property` guard), despite being listed only in `staffcommandhelp` (v1:84), not `commandhelp` — i.e. it's documented as staff-only but is not actually permission-gated. Any player can run `/property purge all`, which purges every property's owner.
4. **Goal**: v1:675-692 — first unconditionally purges shopkeeper NPCs for ALL properties (`property.purgePropertyNPC(sender)`, v1:676) regardless of the `all` flag or a valid single ID. Then, if `all==true`, loops every property ID calling `property.purgePropertyOwner(propertyID2)` (v1:680-684, strips ownership from every property on the server); else if a valid single `propertyID` was resolved, purges just that one (v1:685-688); else (invalid arg) sends an empty error string `ColorOptions.error + ""` (v1:691) — no useful feedback.
5. **Domain**: property.
6. **Bugs/edge cases**:
   - Missing permission check (see above) — a clearly staff/admin-only, destructive, server-wide action (`purge all` strips every property's owner) reachable by any player.
   - v1:669/673 — when args[1] is invalid, code still falls through to line 675-676 and unconditionally purges ALL shopkeeper NPCs regardless of whether a valid target was given.
   - v1:691 — dead/empty error message `ColorOptions.error + ""` gives the player no actual information when their argument was invalid.

## /property shopkeepercheck
1. **Syntax**: `/property shopkeepercheck` (v1:src/Properties/PropertyCommands.java:85).
2. **Arguments**: none.
3. **Permission**: **No permission check** — sibling block v1:514, same as `purge`. Listed only in `staffcommandhelp` (v1:85) but not actually gated.
4. **Goal**: v1:697-732 — counts Citizens NPC entities (and non-NPC entities) named "shopkeeper" in the player's current world (v1:701-715), separately counts properties that have a non-zero NPC ID set (`property.getNPCID(propertyID)`, v1:716-722), and reports whether the two counts match, with a hint to run `/property purge all` if they don't and it's not attributable to entity unloading/memory-saving (v1:724-732).
5. **Domain**: property.
6. **Bugs/edge cases**: Missing permission check (staff-documented, not enforced). Also only scans `player.getWorld().getEntities()` — a single world — while properties/shopkeepers could exist in other worlds, so counts could be inherently mismatched across a multi-world setup; not flagged as an error case in code.

## /property list
1. **Syntax**: `/property list` (v1:src/Properties/PropertyCommands.java:86, 95, 101).
2. **Arguments**: none.
3. **Permission**: No permission check to invoke `list` (both player sibling block v1:514/734-737, and console branch v1:756-758). Console (non-player sender) also supports `list` directly (v1:754-798), the only console-usable `/property` subcommand. Within `propertyList`, showing the property ID is gated on `sender.isOp() || sender.hasPermission("k&k.property") || main.ownermodus.containsKey(...)` (v1:1051) — cosmetic only.
4. **Goal**: Two separate implementations: `propertyList(User)` for players (v1:1038-1075) and an inline console loop (v1:758-787). Both iterate `property.getIDList(null,null)` and print name/category/price/income/availability; the player version additionally distinguishes "Owned by you!" (v1:1061-1063) from "Unavailable. Owner: X" (v1:1066-1069); the console version always prints owner username for unavailable properties without a "owned by you" concept (v1:774-783, no session player to compare against).
5. **Domain**: property.
6. **Bugs/edge cases**: Code duplication between the two nearly-identical list implementations (player vs console) is a maintainability smell but not a functional bug.

---

## /propertycategory set (alias /pc set)
1. **Syntax**: `/propertycategory set <name> <description>` (v1:src/Properties/PropertyCategoryCommands.java:34, 69).
2. **Arguments**: `args.length >= 2` (v1:55); categoryName=args[1], description built from `main.stringBuilder(args, 2, args.length)` (v1:60, so description is optional — empty string if only 2 args given). Validates no existing category has that name (v1:58).
3. **Permission**: `k&k.propertycategory`, v1:src/Properties/PropertyCategoryCommands.java:49.
4. **Goal**: `category.saveCategory(categoryName, description)` (v1:61) — creates a new property category row.
5. **Domain**: property (category sub-domain).
6. **Bugs/edge cases**: none found.

## /propertycategory remove
1. **Syntax**: `/propertycategory remove <name/id>` (v1:src/Properties/PropertyCategoryCommands.java:35).
2. **Arguments**: requires `args.length == 2` (v1:74); if numeric, args[1] treated as category ID and validated against `category.getCategoryIDList()` (v1:76-78); else treated as a category name via `category.getCategoryID(args[1])` (v1:90).
3. **Permission**: `k&k.propertycategory`, v1:src/Properties/PropertyCategoryCommands.java:49.
4. **Goal**: `category.removeCategory(categoryID)` (v1:82, 93) — deletes the category row; sends a success message including the resolved name.
5. **Domain**: property.
6. **Bugs/edge cases**: v1:src/Properties/PropertyCategoryCommands.java:74-100 — the outer `if (args.length == 2) { ... }` has **no else branch**. If a player runs `/propertycategory remove` with any arg count other than 2, nothing happens at all — no usage message, silent no-op (contrast with `set`/`rename`/`changedescription` which all print usage on bad arg count).

## /propertycategory rename
1. **Syntax**: `/propertycategory rename <oldname> <newname>` (v1:src/Properties/PropertyCategoryCommands.java:36; error text at v1:145 actually says `<oldname/ID> <newname>`).
2. **Arguments**: `args.length == 3` (v1:104); args[1] resolved as either an int category ID (v1:106-108, existence checked via `category.getCategoryName(id) != null`) or a category name (v1:126); args[2] is the new name, validated to not already be in use (`category.getCategoryID(args[2]) == null`, v1:111, 129).
3. **Permission**: `k&k.propertycategory`, v1:src/Properties/PropertyCategoryCommands.java:49.
4. **Goal**: `category.saveName(categoryID, args[2])` (v1:114, 132) — renames the category, reporting old→new name.
5. **Domain**: property.
6. **Bugs/edge cases**: none found beyond duplicated ID-vs-name branches (code duplication, not a functional bug).

## /propertycategory changedescription
1. **Syntax**: `/propertycategory changedescription <name/id> <description>` (v1:src/Properties/PropertyCategoryCommands.java:37, 183).
2. **Arguments**: `args.length >= 3` (v1:150); args[1] resolved as int ID or name (same dual-branch pattern as rename, v1:152-180); new description built from `main.stringBuilder(args, 2, args.length)` (v1:159, 173) — can be multi-word.
3. **Permission**: `k&k.propertycategory`, v1:src/Properties/PropertyCategoryCommands.java:49.
4. **Goal**: `category.saveDescription(categoryID, newDesc)` (v1:160, 174) — updates description, message shows old→new description.
5. **Domain**: property.
6. **Bugs/edge cases**: none found.

## /propertycategory list (alias /pc list)
1. **Syntax**: `/propertycategory list` (v1:src/Properties/PropertyCategoryCommands.java:38, note help text typo "propertycatgory").
2. **Arguments**: none.
3. **Permission**: Reachable via TWO paths — inside the permission-gated branch (v1:186-189, requires `k&k.propertycategory`) AND inside the else-branch for players **without** that permission, where `list` is still explicitly allowed (v1:199-203: `if (args.length==1 && args[0]=="list") propertycategoryList(player)`). So effectively **no permission is required** to list categories — any player can. Within `propertycategoryList`, showing category ID is gated on `sender.isOp() || sender.hasPermission("k&k.propertycategory") || main.ownermodus.containsKey(...)` (v1:238) — cosmetic only.
4. **Goal**: `propertycategoryList` (v1:228-248) — iterates `category.getCategoryIDList()`, prints name (and ID if permitted) and description for every category.
5. **Domain**: property.
6. **Bugs/edge cases**: Console (non-player `CommandSender`) cannot use `/propertycategory` at all — the outermost check is `if (sender instanceof Player) {...} else { sender.sendMessage("You need to be a player...") }` (v1:219-222), unlike `/property` which supports a console-only `list`. The public `commandhelp` text block (v1:23-29) references `/point list` and `/point <name>` — leftover/incorrect command name, not `/propertycategory` or `/pc`.

---

## /rp create
1. **Syntax**: plugin.yml describes `/rp <create> <categoryID> <propertyID>`; actual staff help text says `/rp create <resourceCategory> <streetName> <streetNumber> <townName>` (v1:src/Resources/ResourceCommands.java:43). Two forms actually implemented, dispatched by arg count.
2. **Arguments — 3-arg form** (`args.length == 3`, v1:80): args[1] = category **name** (looked up via `resourceCategory.getCategoryID(args[1])`, v1:82), args[2] must be int (v1:85). Validates the resolved category exists, args[2] parses as int, and (supposedly) that the numeric ID is an existing property (`resourceProperty.getIDList(null,null).contains(propertyID)`, v1:88) not already a resource property (v1:90).
   **Arguments — 5-arg form** (`args.length == 5`, v1:106): args[1]=category name, args[2]=streetName, args[3]=streetNumber (int-checked, v1:111), args[4]=townName; resolves town → street → property by location (v1:114-140), then re-resolves category by name again (v1:123) and checks it's not already a resource property (v1:126).
3. **Permission**: `k&k.resourceproperty`, v1:src/Resources/ResourceCommands.java:73.
4. **Goal**: `createResourceProperty` (v1:235-270) — persists the property→category link (`resourceProperty.saveResourceProperty`, v1:238), fetches the WorldGuard region `property_<id>`, sets `BLOCK_BREAK` flag to ALLOW, then based on category name (stonequarry/coalmine/ironmine/goldmine/gemmine/wheatfarm/lumberjack) picks a hardcoded legacy block-ID string and runs `/rg flag property_<id> allow-blocks <ids>` via `performCommand` (v1:244-267).
5. **Domain**: property (resource sub-domain).
6. **Bugs/edge cases**:
   - **v1:src/Resources/ResourceCommands.java:87 — critical bug.** In the 3-arg form, after validating `main.isInt(args[2])` (v1:85), the code parses `propertyID` from **`args[1]`** instead of `args[2]`: `Integer propertyID = Integer.valueOf(args[1]);`. Since `args[1]` is the category **name** string (already consumed as a category lookup key, e.g. "stonequarry"), this call will throw `NumberFormatException` for any real-world usage — the 3-arg create form as written is effectively broken/unreachable without crashing.
   - v1:92-93 — if the property IS already a resource property (`getResourcePropertyIDList(true, categoryID).contains(propertyID)` true), the 3-arg form has no `else` branch giving feedback — silent no-op (contrast with the 5-arg form at v1:129-132, which does message "This property is already registered as a Resource-property!").
   - Destroy-block strings are legacy numeric Minecraft block IDs (e.g. "1 16" for coal) hardcoded per category name string match; any category name not in the seven listed leaves `destroyBlock == null`, and `performCommand("rg flag property_<id> allow-blocks null")` would run with the literal string "null" (v1:267).

## /rp remove
1. **Syntax**: `/rp remove <propertyID>` (v1:src/Resources/ResourceCommands.java:44).
2. **Arguments**: requires `args.length == 2` (v1:159).
3. **Permission**: `k&k.resourceproperty`, v1:src/Resources/ResourceCommands.java:73.
4. **Goal**: Removes the resource-property link (`resourceProperty.removeResourceProperty(propertyID)`, v1:168) and sets the property's WorldGuard region `BLOCK_BREAK` flag to DENY if the region exists (v1:169-174).
5. **Domain**: property.
6. **Bugs/edge cases**:
   - **v1:src/Resources/ResourceCommands.java:161 — critical bug.** Inside the `args.length == 2` branch, the code checks `main.isInt(args[2])` — but `args.length == 2` means only `args[0]` and `args[1]` are valid indices; accessing `args[2]` throws `ArrayIndexOutOfBoundsException` on every invocation of this subcommand. `/rp remove <id>` as written cannot succeed without crashing.
   - v1:163 correctly parses `propertyID` from `args[1]` (the intended target), so the intent is clear even though the preceding validation line is broken.
   - v1:166-176 — if the property exists but is not currently a registered resource property (`getResourcePropertyIDList(false, null)` doesn't contain it), there is no `else` branch — silent no-op with no feedback to the player.

## /rp blocks reload
1. **Syntax**: `/rp blocks <reload>` (v1:src/Resources/ResourceCommands.java:45).
2. **Arguments**: `args.length == 2`, args[1] must equal `reload` literally (v1:191-193).
3. **Permission**: `k&k.resourceproperty`, v1:src/Resources/ResourceCommands.java:73.
4. **Goal**: If `BlockBreakEvents.refreshList.size() > 50` warns it may take a while (v1:195-197), then calls `main.refreshResources(user)` (v1:199) — the actual refresh logic lives in `Main.refreshResources`, not visible in this file.
5. **Domain**: property.
6. **Bugs/edge cases**: none found in this file; behavior of `refreshResources` itself not verifiable from these three files.

---

**Other notes:**
- `changeFlags(Player, Integer, Integer)` in `ResourceCommands.java` (v1:src/Resources/ResourceCommands.java:272-311) is a public helper method that resets/reassigns block-break flags for a resource property, but it is **never called from `onCommand`** in this file — it may be invoked from elsewhere (e.g. a category-rename handler) but is not itself a command entry point; flagged as present but not exercised by any `/rp` subcommand.
- The `/property` staff help text advertises a `quest` subcommand (`-/property quest <reload/collect/remove>`, v1:src/Properties/PropertyCommands.java:83) that has **no corresponding `if (args[0].equalsIgnoreCase("quest"))` branch anywhere in `onCommand`** — it falls through to the generic "print staffcommandhelp" else-branch (v1:356-361 or similar). This is a documented-but-unimplemented (or removed-but-not-cleaned-up) command.
- Sender-type handling is inconsistent across the three files: `/property` supports console for `list` only; `/propertycategory` refuses console entirely; `/resourceproperty` also refuses console entirely (v1:src/Resources/ResourceCommands.java:226-228).

20 distinct commands/subcommands found across property/propertycategory/resourceproperty.
# Towns/Districts/Structures/Gates/Streets/Spawnpoints Command Catalog (knk-v1-archive)

All citations use `v1:src/...:line`. Root: `Repository/knk-v1-archive`.

---

## 1. `/town2` — `src/commands/TownCommand.java` (class `commands.TownCommand`)

Permission gate: `sender.hasPermission(command.getPermission())` at v1:src/commands/TownCommand.java:44 — i.e. relies on plugin.yml's declared `k&k.town` permission, not a hardcoded string. If false, message sent AND `return false` (correctly short-circuits) — v1:src/commands/TownCommand.java:44-48.
No-args → prints `commandhelp` (create/remove/purge) and returns — v1:src/commands/TownCommand.java:49-56.

### `create`
- Syntax: `/town2 create` (no further args parsed at all).
- Args: none consumed beyond `args[0]`.
- Player-only: `sender instanceof Player` check, else `CommandExceptions.SenderNotPlayer` — v1:src/commands/TownCommand.java:65-69.
- Looks up `User` via `Users.getUser(uuid)`; on `UserNotFoundException` or generic `Exception` calls `ErrorHandlers.userNotFoundAction` — v1:src/commands/TownCommand.java:73-85.
- Goal: instantiates `new TownCreation(user)` (v1:src/commands/TownCommand.java:87) — starts a multi-stage "creation" session (see `/creation` below); the TownCreation object is never stored to a variable used afterward — presumably self-registers in its constructor (unverified from this file).
- Bug: local var `townID` declared (line 62) but unused (dead code).

### `remove`
- Syntax: `/town2 remove <name/id>`; requires exactly 2 args else usage message — v1:src/commands/TownCommand.java:91-95.
- Resolves numeric vs name via `Main.isInt` → `DataManager.Towns.FetchTownID` — v1:src/commands/TownCommand.java:97-106.
- Validates existence via `DataManager.Towns.ExistTown(townID)`, then `DataManager.Towns.RemoveTown(sender, townID)` — v1:src/commands/TownCommand.java:108-114.

### `purge`
- Syntax: `/town2 purge` (no further args read).
- Goal: iterates `DataManager.Towns.GetIDList()` and calls `DataManager.Towns.PurgeTown(townID)` for every town, unconditionally — v1:src/commands/TownCommand.java:116-124. No confirmation, no per-town filter (unlike `/town purge <id/all>` in TownCommands.java which supports a single ID).

**Domain:** towns. **Note:** Uses `DataManager.Towns` (a different data-access class than `Towns.Town` used by `/town`, see below) — important for v3 data-model mapping.

---

## 2. `/district` — `src/commands/DistrictCommand.java`

Permission: `sender.hasPermission(command.getPermission())` (plugin.yml `k&k.district`) — v1:src/commands/DistrictCommand.java:41-45, with correct `return false` on failure.
No-args → `commandhelp` (create/remove) — v1:src/commands/DistrictCommand.java:46-53.

### `create`
- Syntax: `/district create` (no further args parsed).
- Player-only check, `Users.getUser` lookup identical pattern to TownCommand — v1:src/commands/DistrictCommand.java:62-82.
- Goal: `new DistrictCreation(user)` — v1:src/commands/DistrictCommand.java:84. Starts a creation session.
- Dead var `townID` (line 60), unused.

### `remove`
- Syntax: `/district remove <id>`; requires exactly 2 args — v1:src/commands/DistrictCommand.java:88-92.
- **Numeric-only**: `Main.isInt(args[1])` required, else error "must be a numeric value" — v1:src/commands/DistrictCommand.java:94-98 (unlike town/street/spawnpoint, no name-lookup fallback for districts).
- Validates via `DataManager.Districts.ExistDistrict(districtID)`, then `DataManager.Districts.RemoveDistrict(sender, districtID)` — v1:src/commands/DistrictCommand.java:101-107.

**Domain:** towns (sub-unit of town).

---

## 3. `/structure` — `src/commands/StructureCommand.java`

Permission: `sender.hasPermission(command.getPermission())` (plugin.yml `k&k.structure`) — v1:src/commands/StructureCommand.java:52-56, correct return.
Help text (v1:src/commands/StructureCommand.java:40-46) advertises both `create <structureType>` and `remove`, but **only `create` is implemented** in the `onCommand` if/else chain — v1:src/commands/StructureCommand.java:66-102. `remove` is a phantom/documented-but-missing subcommand (typing `/structure remove` falls through to no branch matching and does nothing — returns false silently after the outer `if` closes).

### `create`
- Syntax: `/structure create <structureType>`; requires exactly 2 args — v1:src/commands/StructureCommand.java:68-72.
- `structureType` lowercased (line 73).
- Player-only + `Users.getUser` lookup, same pattern — v1:src/commands/StructureCommand.java:74-99.
- Goal: `new StructureCreation(user, structureType)` — v1:src/commands/StructureCommand.java:101. No validation that `structureType` is a recognized type at this layer (deferred to `StructureCreation`, unverified — file not in scope).
- Dead var `townID` (line 77), unused.

**Domain:** towns (structures placed within towns).

---

## 4. `/creation` — `src/commands/CreationCommand.java`

Permission: `sender.hasPermission(command.getPermission())` (plugin.yml `k&k.creation`) — v1:src/commands/CreationCommand.java:52-56, correct return.
No-args → `commandhelp` — v1:src/commands/CreationCommand.java:57-64.

### `<creationID>` (numeric)
- Syntax: `/creation <id>`, detected via `Main.isInt(message)` — v1:src/commands/CreationCommand.java:67.
- Player-only + `Users.getUser` — v1:src/commands/CreationCommand.java:69-94.
- Goal: `Creations.FindStashedCreation(creationID)`; if found, `creation.setUser(user)` then `creation.nextStage(creation.getLastStage()+1)` — resumes/advances a stashed multi-stage creation session (town/district/structure creation wizard) attaching the *current* invoking player as its user — v1:src/commands/CreationCommand.java:97-106. If not found: error message to player only (not `sender`) — v1:src/commands/CreationCommand.java:105 uses `player.sendMessage`, fine since player-only path.
- Edge case: `creation.nextStage(creation.getLastStage()+1)` — jumps to stage = lastStage+1, not "current stage+1"; if `getLastStage()` means "highest stage reached" this could skip stages or always jump past the end depending on semantics — flagged as "unclear" without reading `Creation`/`TownCreation` classes.

### `list`
- Syntax: `/creation list`. Available to console too (no player-only gate for this branch) — v1:src/commands/CreationCommand.java:108-122.
- Goal: iterates `Creations.StashedCreations`, printing ID, creation subject/type, owning user's username, last stage, current stage — v1:src/commands/CreationCommand.java:111-119.

**Domain:** towns (cross-cutting — the shared wizard/session mechanism for town/district/structure creation, listed under CreationCommand per assignment).

---

## 5. `/town` — `src/Towns/TownCommands.java` (class `Towns.TownCommands`, **distinct from #1**)

No permission declared in plugin.yml per task description; in-code permission check is the string literal `"k&k.town"` (same string as `/town2`'s permission node, but checked via `player.hasPermission("k&k.town")`, not `command.getPermission()`) — v1:src/Towns/TownCommands.java:87.

Structure: staff-tier subcommands (`create`, `remove`, `part`, `purge`) are gated inside `if (player.hasPermission("k&k.town"))` (v1:src/Towns/TownCommands.java:84-365); **regardless of that permission check's outcome**, execution then falls through unconditionally to a second `if (args.length >= 1)` block (v1:src/Towns/TownCommands.java:366-402) that (re-)parses `args[0]` for `list`/`info` — available to ALL players.

**Bug (double-output):** a permitted player running `/town list` or `/town info <x>` first falls into the staff `if`-chain (create/remove/part/purge/else), and since `args[0]` matches none of those, hits the trailing `else` at v1:src/Towns/TownCommands.java:351-357 which prints `staffcommandhelp`. Execution then continues past the closing brace to the second block (line 366+) which correctly matches `list`/`info` and executes it. Net effect: permitted (staff) players seeing `/town list` or `/town info` get BOTH the staff help text AND the actual list/info output printed. Non-permitted players are unaffected (they never enter the staff `if`).

Console senders go through a wholly separate `else` branch (`sender instanceof Player` is false) supporting only `list`/`info`, else `consolecommandhelp` — v1:src/Towns/TownCommands.java:419-492.

### `create` (staff, player-only implicitly via permission block)
- Syntax: `/town create <name> <requiredtitle> <description...>`; requires `args.length > 4` (i.e. ≥5 args: create+name+title+description word(s)) — v1:src/Towns/TownCommands.java:95-98.
- Requires an active WorldEdit selection (`worldedit.getWorldEdit().getSelection(player)`) — v1:src/Towns/TownCommands.java:92, 100.
- `requiredtitle` (args[2]) resolved as numeric title ID or by name via `title.getTitleID` — v1:src/Towns/TownCommands.java:103-155.
- Validates player isn't already standing in an existing town (`town.checkTownbyLocation`) and that selection doesn't overlap an existing "city" WorldGuard region (`checkTownRegion` on both min/max corners) — v1:src/Towns/TownCommands.java:112-120, 138-146.
- Goal (`createTown`, v1:src/Towns/TownCommands.java:537-581): rejects duplicate town names (case-insensitive) — v1:src/Towns/TownCommands.java:539-546; persists via `town.saveTown(...)`; creates a WorldGuard `ProtectedCuboidRegion` named `"town_" + townID` from the WorldEdit selection; sets flags ENTRY=ALLOW, MOB_SPAWNING=DENY, PVP=DENY, DAMAGE_ANIMALS=ALLOW, ENTITY_ITEM_FRAME_DESTROY=DENY, DENY_MESSAGE=""; priority 8; attempts to parse an ENTRY region-group flag to `"non_members"` (wrapped in try/catch, exception only printed — swallowed) — v1:src/Towns/TownCommands.java:562-577.

### `remove` (staff)
- Syntax: `/town remove <name/id>`; exactly 2 args — v1:src/Towns/TownCommands.java:167-193.
- Resolves by numeric ID or name.
- Goal (`removeTown`, v1:src/Towns/TownCommands.java:583-605): if town has a spawnpoint, removes it (`spawnpoint.removeSpawnPoint` + `removeTownSpawnPoint`); removes all town "parts" (sub-regions) both from WorldGuard (`town_ID,subID`) and DB (`town.removeTownPart`); removes the main `town_ID` WorldGuard region; removes the town from DB (`town.removeTownbyID`).

### `part add` (staff)
- Syntax: `/town part add <name/id>`; requires a WorldEdit selection — v1:src/Towns/TownCommands.java:195-249.
- Validates the selection's corners are within the SAME town's existing "city" region(s) via `checkSameTownRegion` before adding — v1:src/Towns/TownCommands.java:214, 230.
- Goal (`addTownRegion`, v1:src/Towns/TownCommands.java:607-642): `town.saveTownPart(townID)`; picks the first partID not already present as a WorldGuard region key; creates `ProtectedCuboidRegion` `"town_ID,partID"` from the selection; sets it as a **child** of the parent `town_ID` region via `region.setParent(...)` (catches `CircularInheritanceException`, prints only). **Bug/dead code:** the newly created `region` object is never actually added to the `RegionManager` (`manager.addRegion(region)` is commented out at line 629) — the sub-region is built and parented in memory but never persisted into WorldGuard's manager, so it likely never takes effect / never saves.

### `part remove` (staff)
- Syntax: `/town part remove <name/id> <part-id>`; requires exactly 4 args — v1:src/Towns/TownCommands.java:251-298.
- Validates part ID is numeric and exists via `town.checkPartID(townID, partID)`.
- Goal (`removeTownRegion`, v1:src/Towns/TownCommands.java:644-652): removes WorldGuard region `"town_ID,partID"` and DB record.

### `purge` (staff)
- Syntax: `/town purge <id/all>`; requires exactly 2 args, else `staffcommandhelp` + explicit `return false` — v1:src/Towns/TownCommands.java:310-319.
- `all`: iterates every town ID and calls `purgeTown` — v1:src/Towns/TownCommands.java:321-326.
- `<id>`: validates numeric and existence, else help + return — v1:src/Towns/TownCommands.java:327-349.
- Goal (`purgeTown`, v1:src/Towns/TownCommands.java:703-778): guards against purging the "wilderness" town (returns immediately) — v1:src/Towns/TownCommands.java:705-708; sends "Purging command not available yet" message; attempts to reset the town's WorldGuard PVP flag to `null` (falls back to `State.ALLOW` on exception) — v1:src/Towns/TownCommands.java:709-721. **The bulk of the actual purge logic (removing child regions) is commented out** (v1:src/Towns/TownCommands.java:722-777) — this subcommand is effectively a stub that only touches the PVP flag and explicitly tells the user it's "not available yet."
- Bug: `region.setFlag(DefaultFlag.PVP, null)` inside try is dereferenced without checking `region` for null (if `manager.getRegion("town_" + townID)` returns null, NPE on `region.setFlag`) — v1:src/Towns/TownCommands.java:712-716.

### `list` (all players + console)
- Syntax: `/town list`. Goal (`townList` for players / inline duplicate for console, v1:src/Towns/TownCommands.java:654-681 and 423-446): lists every town's name, description, and whether it has a spawnpoint (colored yes/no). **Town ID only shown if** `sender.isOp() || sender.hasPermission("k&k.town") || main.ownermodus.containsKey(sender.getUniqueId())` — v1:src/Towns/TownCommands.java:664, i.e. ID is gated but name/description/spawnpoint-status are public to any player.

### `info` (all players + console)
- Syntax: `/town info <name/id>`; exactly 2 args — v1:src/Towns/TownCommands.java:372-401 (player) / 448-477 (console).
- Goal (`townInfo`, v1:src/Towns/TownCommands.java:683-701): prints town name, ID (gated by `isOp()||hasPermission("k&k.town")`, note: does NOT check `ownermodus` here unlike `townList`, inconsistent gating), spawnpoint yes/no, description.

**Domain:** towns. **Data note:** uses `Towns.Town` instance (`town.getTownIDList()`, `town.saveTown`, etc.) — a *different* class from `DataManager.Towns` used by `/town2`.

---

## 6. `/gate` — `src/Gates/GateCommands.java`

No blanket command-level permission check (only per-subcommand checks; `list` and the broken `invincible` have none/broken checks — see below). No-args → `staffcommandhelp` — v1:src/Gates/GateCommands.java:61-68.

### `create`
- Syntax: `/gate create <name> <streetname> <facedirection>`; exactly 4 args — v1:src/Gates/GateCommands.java:82-86.
- `facedirection` must be north/east/south/west (case-insensitive) — v1:src/Gates/GateCommands.java:87-92.
- **Permission check happens AFTER argument-shape validation**: `sender.hasPermission("k&k.gate")` — v1:src/Gates/GateCommands.java:93-97 (ordering oddity, not a security hole since it still blocks before execution, but a non-permitted user gets argument-usage feedback before being told they lack permission).
- Player-only (implicit — `worldedit.getWorldEdit().getSelection((Player) sender)` at line 98 would ClassCastException-crash if sender weren't a Player, since there's no `instanceof` guard before this cast — **potential bug**: console running `/gate create` with valid 4 args and passing the facedirection check would hit `(Player) sender` and throw `ClassCastException`, uncaught here — v1:src/Gates/GateCommands.java:98).
- Requires WorldEdit selection — v1:src/Gates/GateCommands.java:98-102.
- Resolves town by player's current location (`street.getTownIDbyLocation`), then street by name within that town — v1:src/Gates/GateCommands.java:103-114.
- Rejects duplicate gate name on same street/town via `Gates.existGate` — v1:src/Gates/GateCommands.java:115-119.
- Goal (`createGate`, v1:src/Gates/GateCommands.java:452-492): **the actual DB-persistence call `Gates.createGate(...)` is commented out** (v1:src/Gates/GateCommands.java:458) inside an empty try/catch that can never throw; relies entirely on `Gates.instantiateGate(name, streetID, townID, true)` (line 466) to create+persist the gate (the boolean `true` presumably signals "create new"). Then creates a WorldGuard `ProtectedCuboidRegion` `"gate_" + gate.getId()` from the selection and calls `gate.addRegion(region)`. Marked "unclear" whether persistence fully works without reading `Gates`/`Gate` classes — flagged as suspicious dead code.

### `remove`
- Permission: `k&k.gate` — v1:src/Gates/GateCommands.java:127-131.
- Syntax: `/gate remove <gateID>` (2 args) OR `/gate remove <name> <streetname>` (3 args, player-only, resolves town by location) — v1:src/Gates/GateCommands.java:133-182.
- Goal (`removeGate`, v1:src/Gates/GateCommands.java:494-503): `gate.removePermanently(sender)`; success message only if it returns true (no failure message on false — silent failure).

### `toggle`
- Permission: `k&k.gate.toggle` — v1:src/Gates/GateCommands.java:202-206.
- **Two forms:**
  - No-arg (`args.length == 1`, i.e. just `/gate toggle`): player-only; looks up `User`; if the user already has an active `GateToggle` task (`Gates.findGateToggle(user)`), blocks with error; otherwise starts `new GateToggle(user, false)` and prompts "Right-click a gate within 3 seconds to open it" — v1:src/Gates/GateCommands.java:208-245. This is a click-to-toggle interaction mode, not immediate execution.
  - By ID (2 args) or name+street (3 args, player-only, location-based town resolution): resolves the `Gate` object directly, then calls `gate.toggleClosed()` immediately — v1:src/Gates/GateCommands.java:247-310.

### `passthrough` (alias `pt`)
- Permission: `k&k.gate.passthrough` — v1:src/Gates/GateCommands.java:313-317.
- Syntax: `/gate passthrough` (no further args; player-only) — v1:src/Gates/GateCommands.java:319-354. Same click-to-interact pattern as bare `toggle`, but starts `new GateToggle(user, true)` — opens for 2 seconds then auto-closes per the message text (v1:src/Gates/GateCommands.java:352-354).
- If args given beyond the bare command, tells user it only works as a bare click-trigger command — v1:src/Gates/GateCommands.java:355-358.

### `invincible` — **broken/stub**
- Permission check present but its body is empty: `if (!sender.hasPermission("k&k.gate")) { }` — v1:src/Gates/GateCommands.java:364-367. No message, no `return false`, and critically **no code follows this block at all** within the `invincible` branch — the subcommand does absolutely nothing regardless of permission outcome. `gateID`/`gate` locals declared and unused (lines 361-362). This is a non-functional stub.

### `info`
- Permission: `k&k.gate.info` — v1:src/Gates/GateCommands.java:373-377.
- Syntax: by ID (2 args) or name+street (3 args, player-only/location-based) — v1:src/Gates/GateCommands.java:379-428, same resolution pattern as remove/toggle.
- Goal (`infoGate`, v1:src/Gates/GateCommands.java:505-514): prints gate name, street name, town name, open/closed status, and whether the *sender* has `k&k.gate.toggle` ("Controllable by you").

### `list`
- **No permission check at all** — v1:src/Gates/GateCommands.java:442-445 dispatch, body at 516-536. Any sender (including console) can list gates. Gate numeric ID only shown if `sender.hasPermission("k&k.gate")` (line 524); the "Status" line is hardcoded to always print "Opened" regardless of actual closed state (v1:src/Gates/GateCommands.java:531) — **bug**: unlike `infoGate` (line 511) which correctly branches on `gate.getClosed()`, `listGates` always reports every gate as Opened.

**Domain:** towns (gates are sub-structures of streets/towns).

---

## 7. `/street` — `src/Streets/StreetCommands.java`

**Console entirely blocked**: the whole command body is wrapped in `if (sender instanceof Player)`, else just "You need to be a player to perform this command!" — v1:src/Streets/StreetCommands.java:46, 219-222. Unlike `/town` and `/spawnpoint`, console cannot even run `/street list`.
Staff subcommands gated by `sender.hasPermission("k&k.street")` — v1:src/Streets/StreetCommands.java:48.

### `set` (staff)
- Syntax: `/street set <name> <town-name/town-ID>`; exactly 3 args — v1:src/Streets/StreetCommands.java:53-94.
- Resolves town by ID or name; rejects duplicate street name within that town (`street.checkStreet`).
- Goal (`setStreet`, v1:src/Streets/StreetCommands.java:227-238): `street.saveStreet(streetName, townID)`, wrapped in try/catch that prints stack trace and generic error to sender on failure.

### `remove` (staff)
- Syntax: `/street remove <name/ID> <town-name/town-ID>`; exactly 3 args — v1:src/Streets/StreetCommands.java:96-172.
- Street resolved by numeric ID (`street.checkStreetbyID`) or by name+townID (`street.checkStreet`/`street.getStreetID`); town resolved by ID or name.
- Goal (`removeStreet`, v1:src/Streets/StreetCommands.java:240-256): only removes if `street.getTownID(streetID) == townID` (defensive consistency check) — **note:** if this check fails, the method silently does nothing (no error message to the sender) — v1:src/Streets/StreetCommands.java:244-255 — silent no-op bug.

### `list`
- Staff path: `/street list` (exactly 1 arg after "list", i.e. no extra args) — v1:src/Streets/StreetCommands.java:174-182.
- Non-staff players (have permission for `/street` command itself via being able to invoke it, but lack `k&k.street`): can still call `list` — v1:src/Streets/StreetCommands.java:199-210, i.e. `list` is accessible to any player, staff or not (mirrors town's non-gated `list`/`info`).
- Goal (`listStreet`, v1:src/Streets/StreetCommands.java:258-278): prints street name + town name for every street; street ID only shown if `sender.isOp() || sender.hasPermission("k&k.town") || main.ownermodus.containsKey(...)` — **note**: gated by `k&k.town` permission, not `k&k.street` (cross-domain permission check) — v1:src/Streets/StreetCommands.java:270.

**Domain:** towns (streets are town sub-elements; gates reference streets).

---

## 8. `/spawnpoint` (alias `sp`) and `/point` (alias `warp`) — `src/SpawnPoints/SpawnPointCommands.java`

Single class, `onCommand` dispatches on `label` twice — first `if` block handles `spawnpoint`/`sp` (v1:src/SpawnPoints/SpawnPointCommands.java:65-340), second independent `if` handles `point`/`warp` (v1:src/SpawnPoints/SpawnPointCommands.java:342-411). Both blocks can theoretically run in the same invocation but Bukkit only ever passes one matching label, so effectively mutually exclusive at runtime.

### `/spawnpoint` (alias `sp`)
Single blanket permission check for the ENTIRE command (all subcommands including `list`): `sender.hasPermission("k&k.spawnpoint")` — v1:src/SpawnPoints/SpawnPointCommands.java:67, else generic "no permission" message (no early logic runs at all if false) — no granular per-subcommand permissions here (unlike `/gate`).

#### `set` (player-only, staff)
- Syntax: `/spawnpoint set <name> <requiredtitle> <requireddonator> <price>`; exactly 5 args — v1:src/SpawnPoints/SpawnPointCommands.java:76-126.
- `price` must be numeric.
- `title` resolved by name (`title.getTitleID`) or must be a valid numeric ID present in `title.getIDList()` — v1:src/SpawnPoints/SpawnPointCommands.java:85.
- `donator` resolved similarly via `donator.getDonatorIDbyString`/`getDonatorIDList()`.
- Rejects duplicate spawnpoint name (`spawnpoint.getSpawnPointID(name) == null` check).
- Goal: `spawnpoint.saveSpawnPoint(name, titleID.toString(), price, donatorID.toString(), world, x, y, z, yaw, pitch)` using the player's current location — v1:src/SpawnPoints/SpawnPointCommands.java:93-106. Errors caught, stack-traced, and (if op) the raw exception text shown to the player.
- Edge case: `titleID.toString()` — if `titleID` is null (can happen if `getTitleID` returned null but the code took the other branch of the `||` via `getIDList().contains(...)`) this would NPE; but logically if `getTitleID(title)` is null, `title` string might still be a valid numeric ID in `getIDList()`, meaning `titleID` (line 87, assigned from `getTitleID(title)`) stays null while the outer condition passed via the second `||` operand — **potential NPE** at `titleID.toString()` (line 96) when a valid numeric title ID string is passed that `getTitleID` (which presumably looks up by name) doesn't resolve — v1:src/SpawnPoints/SpawnPointCommands.java:85-96. Same pattern/risk for `donatorID.toString()` — v1:src/SpawnPoints/SpawnPointCommands.java:88-96.

#### `remove` (player-only, staff)
- Syntax: `/spawnpoint remove <name/ID>`; exactly 2 args — v1:src/SpawnPoints/SpawnPointCommands.java:130-196.
- Resolves by numeric ID or name.
- Goal: if the spawnpoint is tied to a town (`spawnpoint.checkTownSpawnPointbySpawnPoint`), first removes that town-spawnpoint link (`removeTownSpawnPoint`), then removes the spawnpoint itself (`removeSpawnPoint`) — both wrapped in separate try/catch with generic error messages.

#### `list` (player-only under `spawnpoint`/`sp` top permission)
- Syntax: `/spawnpoint list` — v1:src/SpawnPoints/SpawnPointCommands.java:198-208.
- Goal: prints name/ID/price for `spawnpoint.getSpawnPointList(true, true, true, true, true, true)` (all six boolean flags true — presumably "include all categories") — full unfiltered listing, gated only by the top-level `k&k.spawnpoint` permission.
- Console variant (v1:src/SpawnPoints/SpawnPointCommands.java:306-320) uses `getSpawnPointList(false, false, false, false, false, false)` (all flags false — a different, presumably restricted, subset) and additionally excludes anything in `spawnpoint.getHouseSpawnPointList()` — inconsistent filtering between player and console `list`.

#### `rename` (player-only, staff)
- Syntax: `/spawnpoint rename <oldname> <newname>`; exactly 3 args — v1:src/SpawnPoints/SpawnPointCommands.java:210-254.
- Resolves old spawnpoint by numeric ID or name; rejects if `newname` already used by another spawnpoint.
- Goal: `spawnpoint.saveName(spawnpointID, newname)`.

#### `relocate` (player-only, staff)
- Syntax: `/spawnpoint relocate <name/id>`; exactly 2 args — v1:src/SpawnPoints/SpawnPointCommands.java:256-289.
- Goal: overwrites the spawnpoint's stored location with the invoking player's current location (`spawnpoint.saveLocation(...)`). No confirmation prompt.
- Edge case (minor UX bug): in the name-lookup branch (as opposed to ID branch), the success message echoes `args[1]` (the raw name typed) instead of the canonical spawnpoint name — v1:src/SpawnPoints/SpawnPointCommands.java:280 vs the ID branch's correct `spawnpointName` at line 268.

#### Console path for `/spawnpoint` (no Player)
- Only `list` supported (filtered, excludes house spawnpoints) — v1:src/SpawnPoints/SpawnPointCommands.java:304-335; anything else prints `consolecommandhelp`.

### `/point` (alias `warp`)

**No permission check anywhere in this block** — v1:src/SpawnPoints/SpawnPointCommands.java:342-411. Any player who can execute a command at all can use `/point`/`warp`.
- Player-only (console gets "You need to be a player..." — v1:src/SpawnPoints/SpawnPointCommands.java:407-409).
- Looks up `User` via `Users.getUser(uuid)`, standard error handling.

#### `list`
- Syntax: `/point list` — v1:src/SpawnPoints/SpawnPointCommands.java:365-375.
- Goal: lists spawnpoints from `getSpawnPointList(false,false,false,false,false,false)`, additionally hardcoded-excluding any whose name contains the literal substrings `"house"` or `"ocelot"` (line 371) — brittle string-based filtering rather than a data flag. Notes prices are "in gems, paid when teleporting."

#### `<name>` (teleport)
- Syntax: `/point <name>` (single arg, non-"list") — v1:src/SpawnPoints/SpawnPointCommands.java:376-399.
- Resolves spawnpoint ID by name via `spawnpoint.getSpawnPointID(args[0])`.
- Access control: membership in `spawnpoint.getSpawnPointList(false,false,false,false,false,false)` — i.e. gating is done via the spawnpoint's own stored flags/category, NOT a Bukkit permission node.
- Blocks teleport if the player is currently duelling (`new Arena().isDuelling(uuid)`) — v1:src/SpawnPoints/SpawnPointCommands.java:383-388.
- Goal: `spawnpoint.tryRegularTeleport(user, args[0])` — actual teleport + presumably payment logic lives in `SpawnPoint` class (out of scope).

**Domain judgment:** `/spawnpoint` (staff CRUD) is clearly **towns** domain (spawnpoints are attached to towns, `checkTownSpawnPointbySpawnPoint`/`removeTownSpawnPoint` tie directly into town data). `/point`/`warp`, however, is functionally a **general-purpose teleport/warp command** — it has no permission node, no town-membership requirement to use, resolves purely by spawnpoint name/category flags, and explicitly filters out house-tied spawnpoints — it reads as a **world-admin/teleport-utility** feature that happens to share its backing data table (`SpawnPoint`) with the town system rather than a town-management command itself. Flagging for v3 planners to consider splitting the underlying "spawnpoint" data concept from the "warp" player-facing feature.

---

## Cross-cutting observations for v3 planning
- Two unrelated `Town`-adjacent data-access classes exist: `DataManager.Towns` (static-style, used only by `commands.TownCommand` / `/town2`) vs `Towns.Town` (instance-style, used by `Towns.TownCommands` / `/town`, and referenced by `Gates`/`Streets` commands for town name/ID lookups). Any v3 model should reconcile these into one town repository.
- Permission-check style is inconsistent across the domain: `commands.*` classes use `command.getPermission()` (plugin.yml-driven), while `Towns.TownCommands`, `Gates.GateCommands`, `Streets.StreetCommands`, `SpawnPoints.SpawnPointCommands` use hardcoded permission-node strings inline, with `/gate` alone doing granular per-subcommand nodes (`k&k.gate`, `k&k.gate.toggle`, `k&k.gate.passthrough`, `k&k.gate.info`) vs `/spawnpoint`'s single blanket node for all subcommands, vs `/street`'s single node, vs `/town`'s single node with the list/info leak described above.
- Two commands with **no permission check at all**: `/gate list` and `/point`/`warp` (both list and teleport).
- One functionally dead/stub subcommand: `/gate invincible`.
- One documented-but-unimplemented subcommand: `/structure remove`.
- One subcommand whose core logic is entirely commented out (stub behind a message): `/town purge`.
- One subcommand where the created object is never added to the region manager: `/town part add`.

---

**32 distinct commands/subcommands found across town2/district/structure/creation/town/gate/street/spawnpoint/point** (3 + 2 + 1 + 2 + 7 + 7 + 3 + 5 + 2), not counting the phantom `/structure remove` (documented but unimplemented) or the dead `/gate invincible` stub as separately functional.
# Command catalog: Items / Inventory-menus / Social / NPC domain (knk-v1-archive)

## /product (feature domain: items)
Class: `Products/ProductCommands.java`. Registered `v1:src/Main/Main.java:611`. plugin.yml desc "/product for all product-commands" (no permission node in plugin.yml).

Dispatch: `if (label.equalsIgnoreCase("product"))` v1:src/Products/ProductCommands.java:53. Only works for `sender instanceof Player` (v1:56) — console senders get "You need to be a player" v1:292 (correct behavior — but note the whole permission gate is nested inside the Player check, so console never even reaches a permission check).

Permission gate: `player.hasPermission("k&k.product")` v1:src/Products/ProductCommands.java:61, guards ALL subcommands.

- **/product set <name> <category> <grade(1-5)> <minprice> <maxprice> <description>** v1:63-141
  - Requires item in hand (`getItemInHand() != null` — note: this never catches held AIR, since `getItemInHand()` returns an ItemStack(AIR) not null when hand empty in this Bukkit version, so bug: can "hold" nothing and pass this check, but then `item.hasItemMeta()` will be false and it errors gracefully v1:139) v1:65.
  - Requires custom display name (`item.hasItemMeta()`) v1:68.
  - Requires >=5 args v1:71.
  - Validates args[3..5] are ints (grade/minprice/maxprice) v1:75; grade must be 1-5 v1:83.
  - Validates category exists via `category.getCategoryID()` v1:85.
  - Validates no existing product with same display name v1:88.
  - Validates item has a matching DB material/type via `getDBTypeID` v1:90-92 (uses block ID + data value, v1:298-320 — legacy 1.8-era numeric IDs).
  - Saves product with enchants and lore serialized to strings v1:93-110.
  - Bug: `main.isInt(args[3]) && main.isInt(args[4]) && main.isInt(args[5])` at v1:75 accesses args[5] before confirming `args.length >= 6` (only checked `>= 5` at v1:71) — ArrayIndexOutOfBoundsException if exactly 5 args given.

- **/product get <amount> <name>** v1:146-182
  - Requires >=3 args v1:148.
  - Two paths: `<amount> <name>` (name non-numeric) v1:150-162, or `<amount> <productID>` (both numeric) v1:163-174.
  - Gives item via `product.createPropertyItem()`, adds directly to inventory (no full-inventory check) v1:157,169.
  - Bug: else branch v1:176 references `args[3]` in error message but this branch only guarantees args.length>=3 (indices 0-2) — potential AIOOBE if amount fails validation with exactly 3 args... actually args[3] would throw if args.length==3. Minor cosmetic bug, only in error-message path.
  - No permission beyond the top-level `k&k.product` gate — anyone with base product perm can pull arbitrary product IDs by number, not just named/listed ones (as long as ID is in `getIDList(false,...)`).

- **/product give <player> <amount> <name>** v1:183-242
  - Requires exactly 4 args v1:185 (`<player> <amount> <name>`... but note arg order used is args[1]=username, args[2]=amount, args[3]=productname — i.e. syntax is actually `/product give <player> <amount> <name>` matching staffcommandhelp v1:45).
  - Validates target online via `Bukkit.getPlayer()` v1:189; looks up `Users.getUser()`, catches `UserNotFoundException` v1:194-206.
  - Validates amount numeric v1:207; validates product exists by name v1:210.
  - Calls `product.giveProduct(player, userTarget, productID, amount)` v1:213 — dead/commented-out old logic below it (v1:214-223) shows this used to give directly to inventory with slot-check; now delegated entirely to `Product.giveProduct` (not read — out of scope).
  - Else path (not-4-args) just prints `staffcommandhelp.get(4)` which is the `/product list` line, not the `give` usage line — **bug**: wrong help line shown (index mismatch; give's usage isn't in the list at all, in fact staffcommandhelp only has set/get/give/remove/list = indices 2-6, get(4) is `/product remove`) v1:44-49,241.

- **/product remove <name/id>** v1:244-273
  - Requires >=2 args v1:246.
  - If args[1] numeric, treated as ID and checked against `product.getIDList(true, null, true)` v1:248-251; else treated as name-based lookup v:258-268 (joins ALL remaining args as name via `main.stringBuilder`, so numeric IDs with multi-word names aren't really distinguished except by args[1] alone).
  - Calls `removeProduct()` v1:322-328 which removes all PropertyProduct links then removes the product, unconditionally (no confirmation).

- **/product list** v1:275-278, prints all products via `productList()` v1:330-360; shows product ID only if `sender.isOp() || sender.hasPermission("k&k.property") || main.ownermodus.containsKey(...)` v1:342 (additional gated info within otherwise open listing).

- **/product** (no args): prints `staffcommandhelp` (static usage list) v1:283-289 — reachable WITHOUT the `k&k.product` permission check (the permission check only guards the `args.length > 0` branch) — i.e. any player can see the full command-syntax help without permission, though can't execute. Minor info-disclosure, not a real bug.

---

## /soulbound (feature domain: items)
Class: `Products/SoulboundCommands.java`, dispatch `label.equalsIgnoreCase("soulbound")` v1:src/Products/SoulboundCommands.java:46. Registered v1:src/Main/Main.java:612. plugin.yml desc "/soulbound" (no permission node declared in plugin.yml).

Permission: `p.hasPermission("k&k.soulbound")` v1:51.

Player-only (else: "need to be a player") v1:133-136.

- Requires item in hand: `p.getItemInHand() != null || p.getItemInHand().getType() != Material.AIR` v1:53 — **bug: should be `&&` not `||`**; as written this condition is always true (first clause `!= null` is basically always true for `getItemInHand()` in this Bukkit version since it returns AIR ItemStack not null), so the "you need an item in hand" message v1:127 is effectively unreachable dead code.
- **/soulbound add** (args.length==1) v1:56-82: adds "Soulbound" lore tag via `product.SoulboundItem(item)` unless lore already contains "Soulbound" or "Ghosted" tag v1:65; if meta null/no lore, unconditionally soulbinds v1:73-81.
- **/soulbound remove** v1:84-110: only works if lore contains exact string `ChatColor.RED + "Soulbound"` v1:91 (single lore-line match, not substring) — removes that single lore line, calls `updateInventory()`.
- Any other/missing arg: prints `soulboundhelp` static list v1:27-33,113-124.

## /ghosted (same class, feature domain: items)
Dispatch `label.equalsIgnoreCase("ghosted")` v1:138. Registered v1:src/Main/Main.java:613 (SAME class instance pattern — `new SoulboundCommands(this)` re-instantiated separately for each getCommand call, not shared instance, but harmless since class is stateless besides `product`/`main` fields).

Permission: `p.hasPermission("k&k.ghosted")` v1:143.

- Same "always true" item-in-hand bug at v1:145 (same `||` mistake).
- **/ghosted add** v1:150-174: adds via `product.GhostItem(item)`; checks neither "Ghosted"(GRAY) nor "Soulbound"(RED) already present v1:157; **bug**: the empty-meta fallback branch (no ItemMeta) at v1:170-174 calls `GhostItem` but the success message says "Succesfully **soulbound** the item" (copy-paste bug from soulbound branch) v1:173.
- **/ghosted remove** v1:176-202: checks for lore line `ChatColor.DARK_GRAY + "Ghosted"` v1:183 — **inconsistency bug**: the `add` path checks for `ChatColor.GRAY + "Ghosted"` (v1:157) but the `remove` path checks for `ChatColor.DARK_GRAY + "Ghosted"` (v1:183) — two different ChatColor constants for the same tag, meaning `/ghosted remove` will basically never find the tag that `/ghosted add` produces (assuming `GhostItem()` tags with GRAY, matching the `add`-side check) — likely-broken remove path. (Not verified against `Product.GhostItem()` body — out of scope file — but the add/remove color mismatch is visible directly in this file.)
- Any other/missing arg: prints `ghostedhelp` v1:35-41,205-216.

---

## /enchant (feature domain: items)
Class: `UsefulCommands/EnchantmentCommand.java`. Registered v1:src/Main/Main.java:636. plugin.yml desc "/enchant to enchant an item" (no permission node declared in plugin.yml, though code checks one).

Dispatch v1:src/UsefulCommands/EnchantmentCommand.java:27. Player-only v1:29-31 (else "need to be a player" v1:66).
Permission: `p.hasPermission("k&k.enchant")` v1:32.

- **/enchant <enchantment> <level>** (2 args) v1:34-42: same item-in-hand `||` bug as soulbound (v1:36, effectively always true, dead-code error branch v1:41). Calls `addEnchant(p, args[0], Integer.valueOf(args[1]))` v1:38 — **bug: no `main.isInt()` validation on args[1]**; non-numeric level throws uncaught `NumberFormatException`, crashing the command silently (no catch anywhere in chain) — unlike almost every other command in this batch which validates ints first.
- **/enchant all** (1 arg, "all") v1:44-51: loops all `Enchantment.values()` and adds each unsafely at level 10 directly to `p.getItemInHand()` v1:48-50 — does NOT go through `addEnchant`/`Product.getEnchantmentfromString`, bypassing whatever custom-enchant mapping the "named enchantment" path uses; no user-feedback message sent at all on success (no `sendMessage` after the loop) — silent success.
- Any other 1-arg value: falsecommand usage message v1:52-55.
- `addEnchant()` v1:72-84: resolves the string via `Product.getEnchantmentfromString()`; if unresolved, error message v1:82; else calls `item.addUnsafeEnchantment()` directly on `player.getItemInHand()` (re-fetched inside `addEnchant`, not the same reference necessarily but functionally fine) v1:75,78.

---

## /rename (feature domain: items)
Class: `UsefulCommands/ItemRenamer.java`. Registered v1:src/Main/Main.java:645. plugin.yml desc "/rename to rename an item" (no permission node in plugin.yml).

Dispatch v1:src/UsefulCommands/ItemRenamer.java:26: `if (label.equalsIgnoreCase("rename") && sender.hasPermission("k&k.rename"))` — permission checked inline in the `if` v1:28, redundantly re-checked at v1:31 (`p.hasPermission` again) — harmless but redundant. **Bug**: if permission fails at the OUTER `if` (v1:28), the whole block is skipped silently — no error message sent to the player at all (the `else` at v1:54-57 "You don't have permission" is only reached if the label matches AND the first hasPermission passed AND the inner one somehow failed — which given they're literally the same check, is unreachable dead code). So a player without `k&k.rename` invoking `/rename` gets **no feedback whatsoever** (silent no-op).
- Also **unguarded cast**: `Player p = (Player) sender;` v1:30 happens BEFORE any `instanceof Player` check — if a console/CommandBlock sender without k&k.rename issues `/rename`, it silently does nothing (permission blocks it, per above); but if a non-player sender somehow HAS the permission (e.g. console with `*` perms), this throws `ClassCastException` — no player-type guard exists anywhere in this file, unlike every other command in this batch.
- **/rename <name...>** args.length>0 v1:33-49: requires item in hand (again the always-true-`!= null` check, but this one has no `Material.AIR` clause at all so it's genuinely just checking non-null, effectively always true — dead "need item" branch v1:47-49 truly unreachable). Joins all args, applies `getColor(args[0])` (single &-code -> ChatColor, else defaults to WHITE, v1:63-127) prefixed to the FULL joined string (including args[0] itself, i.e. the color-code token like `&c` remains part of the displayed name text along with the color) — replaces literal `&` with `§` in the whole string afterward v1:44. Net effect: `getColor` reads args[0] to pick a color but then the entire `allArgs` (which still contains args[0], e.g. "&c") is used as the name text with `&`→`§` substitution, so the leading color-code token ends up duplicating as literal legacy color code text via `§c` at the start of the name in addition to the ChatColor prefix — likely produces doubled/redundant coloring rather than a bug that breaks functionality (since `§c` also color-codes it).

---

## /lore (feature domain: items)
Class: `UsefulCommands/LoreEditer.java`. Registered v1:src/Main/Main.java:646. plugin.yml desc "/lore to modify a lore of an item" (no permission node in plugin.yml).

Dispatch v1:src/UsefulCommands/LoreEditer.java:26. **Bug**: `Player p = (Player) sender;` v1:30 cast happens with NO `instanceof Player` guard anywhere in the method — console use throws `ClassCastException` (contrast with rename which at least conditions the block on `sender.hasPermission` before the same unguarded cast — lore doesn't even have that outer permission-checked entry gate before the cast).
Permission: `p.hasPermission("k&k.lore")` v1:31 (checked after the unsafe cast).

- **/lore add <text...>** v1:35-119: requires item in hand + not AIR (proper `&&`, v1:39, unlike other files — correct here) and `item.hasItemMeta()` v1:42. Complex lore-line manipulation: strips out any existing "Soulbound"/"Ghosted" tag lines, appends new line, re-appends the soulbound/ghosted tags at the end v1:57-94 (this is presumably to keep those tags last in the lore list). **Bug**: `meta.getLore()` at v1:56 returns the SAME list reference as stored in the ItemMeta wrapper in many Bukkit impls, but more importantly the code mutates `lore` (a `List<String>` — likely a fixed-size `Arrays.asList` in some code paths, though here it's whatever `getLore()` returns) via `.remove()` calls at v1:65,69 while iterating over it with an index-based for-loop (`for (int i=0; i<lore.size(); i++)`, v1:61) — **classic bug: removing elements from a list while iterating by increasing index skips elements** (indices shift after each removal), so if lore had adjacent tag lines it may fail to strip all of them correctly.
  - `else` branch v1:99-111 (no ItemMeta present) is **dead/unreachable**: it re-fetches `item.getItemMeta()` at v1:101 immediately after the enclosing `if (item.hasItemMeta())` (v1:42) already confirmed meta exists — this else branch corresponds to `!item.hasItemMeta()`, yet it calls `item.getItemMeta()` again (which for Bukkit always returns a non-null ItemMeta object regardless, just an "empty" one) and proceeds to build lore anyway; functionally it still works (sets fresh lore on an itemless-meta item) so not exactly dead, but the surrounding structure duplicates the entire add-lore code block for the "no meta" case with slightly different (simpler, no soulbound/ghosted-preserving) logic — code duplication, not a bug per se.
- **/lore clear** v1:121-159: requires item + not AIR + hasItemMeta. If lore.size()>1, iterates removing all non-Soulbound/Ghosted lines v1:132-141 — **same remove-while-iterating bug** as above (v1:139 `lore.remove(lore.indexOf(lore.get(i)))` while for-loop increments i). If lore.size()==1, checks `!lore.get(0).contains("soulbound") || !lore.get(0).contains("ghosted")` v1:144 — **bug: case-sensitive lowercase string check** against tags that are actually stored capitalized ("Soulbound"/"Ghosted", see SoulboundCommands.java) — this condition is essentially always true (a line rarely literally contains lowercase "soulbound" AND "ghosted" both absent test — actually it's an OR of two negated contains, so true unless the single line contains BOTH literal substrings "soulbound" and "ghosted", which given case sensitivity practically never happens) meaning clear on a single-line lore ALWAYS clears it even if that single line is a Soulbound/Ghosted tag — inconsistent with the multi-line branch's protection of those tags. Also `meta.getLore()` at v1:129 called without checking `hasLore()` first — if `hasItemMeta()` is true but item has no lore, `getLore()` may return null and `.size()` at v1:130 throws NPE (no `meta.hasLore()` guard here unlike the `add` subcommand which does check `meta.hasLore()`... wait actually `add` doesn't call hasLore either, it checks `meta.getLore() == null`. `clear` has no such null-check before calling `.size()` — potential NPE if item has meta but no lore).
- Other/missing args: falsecommand usage v1:120,164-166.

---

## /repair — **DEAD/UNREGISTERED COMMAND** (feature domain: items)
Class: `UsefulCommands/RepairCommand.java`, full file v1:1-30.
- **NOT registered anywhere**: confirmed via `grep -n "repair" plugin.yml` — no `repair:` entry exists in plugin.yml at all (v1:plugin.yml, full 173-line file reviewed, no "repair" string present anywhere), and `grep -n "RepairCommand"` against Main.java returns zero matches — no `getCommand("repair").setExecutor(...)` call exists. Since plugin.yml doesn't declare `repair` as a command, Bukkit would not even resolve `getCommand("repair")` to a non-null Command object, so even if Main.java tried to wire it, it would NPE at startup — it simply isn't wired at all.
- Even if it WERE registered: the method body does literally nothing. `onCommand` v1:src/UsefulCommands/RepairCommand.java:18-28: checks `label.equalsIgnoreCase("repair")` v1:20, checks `sender.hasPermission("k&k.repair")` v1:22, and the permission-true branch is an **empty block** (`{ }` v1:23-25) — no repair logic, no item lookup, no message, nothing. This is a stub/placeholder class that was never implemented. There is no other file implementing repair-via-listener that I found in this scope (only unrelated hits for "repair" in AnvilMenu.java's anvil-window packet title string, and Product.java's "armorrepair" custom-enchantment name — neither is a `/repair` command implementation).
- **Conclusion**: `/repair` is entirely dead code — not registered in plugin.yml, not wired in Main.java, and even its handler does nothing.

---

## /menu (feature domain: inventory-menus)
Class: `Menu/MenuCommand.java`. Registered v1:src/Main/Main.java:609. plugin.yml desc "/menu opens the personal menu" (no permission node declared in plugin.yml).

Dispatch v1:src/Menu/MenuCommand.java:38. Player-only (`sender instanceof Player`, but note structure: the outer `if` has no `else` printing anything for non-player — v1:42-76 shows no final else-branch for `!(sender instanceof Player)`, so a console caller of `/menu` gets **total silence**, no feedback at all — differs from most other commands in this batch which print "need to be a player").
Permission: `sender.hasPermission("k&k.menu")` v1:44.

- No args/subcommands — `/menu` takes none. Looks up `Users.getUser(uuid)`, catches `UserNotFoundException` v1:50-62. Checks `arena.isDuelling(uuid)` — blocks menu-opening while duelling v1:64-68. Opens the personal menu via `menu.OpenPersonalMenu(user)` v1:70, plays `SoundHandler.ORB_PICKUP` v1:71.
- No bugs of note besides the missing non-player feedback described above.

---

## /ViewMenu (feature domain: inventory-menus)
Class: `commands/ViewMenuCommand.java` (note different package: `commands`, not `UsefulCommands`). Registered v1:src/Main/Main.java:582 `getCommand("ViewMenu").setExecutor(new ViewMenuCommand(this));`. plugin.yml: `viewmenu: description: Mirror the menu view of a player to check his behaviour / permission: k&k.viewmenu` v1:plugin.yml:9-11.

Dispatch v1:src/commands/ViewMenuCommand.java:35.
Permission: `sender.hasPermission(command.getPermission())` v1:39 — resolves dynamically to plugin.yml's declared `k&k.viewmenu` node rather than a hardcoded string (only command in this batch to do so). Properly returns early on failure v1:41-43 (unlike some other files, this one is clean with early returns throughout).

- **/viewmenu** (no args): prints `commandhelp` usage list v1:44-51,27-33.
- Non-player sender: proper early-return error message v1:53-57.
- **/viewmenu stop**: v1:69-80. Looks up caller's `User` via `Users2.FindUser(uuid)` v1:61 (different data-access class than the `Users` class used elsewhere in this batch — `DataManager.Users2`). If not currently viewing anyone (`user.getMenuViewing() == null`), errors v1:71-74. Else sends a message using `user.getMenuViewing().getUsername()` v1:77 **AFTER already deciding to stop** but BEFORE calling `user.removeMenuViewing()` v1:78 — order is fine actually (message built before removal, correct). No bug here.
- **/viewmenu <username>**: v1:82-109. Resolves target UUID via `Users2.FetchUUIDbyUsername` v1:83; if null, error v1:85-88. Fetches target `User` v1:90; null-check v1:92-95. Registers viewer on target (`userTarget.addMenuViewers(user)`, `user.setMenuViewing(userTarget)`) v1:100-101 regardless of whether target currently has a menu open. If target has an open menu (`getOpenMenu() != null`), immediately opens it for the viewer v1:103-105; else informs viewer it'll open automatically later v1:106-108.
- No self-view guard: nothing stops a player from `/viewmenu <ownusername>` (not validated) — minor edge case, not necessarily harmful.
- No `Material`/duel-state checks like `/menu` has.

---

## `UsefulCommands/ViewMenuCommands.java` — **DEAD/UNREGISTERED CODE** (feature domain: inventory-menus)
Full file v1:src/UsefulCommands/ViewMenuCommands.java:1-23. This is a SEPARATE class from `commands/ViewMenuCommand.java` above (different package: `UsefulCommands`, plural class name `ViewMenuCommands`).
- Confirmed via `grep -n "ViewMenuCommands" src/Main/Main.java` → **zero matches**. Not registered anywhere in Main.java.
- Even if it were registered, the `onCommand` method body is a no-op stub: `public boolean onCommand(...) { return false; }` v1:17-21 — no label check, no logic whatsoever, just returns false unconditionally.
- **Conclusion**: this class is entirely dead code — unregistered AND functionally empty. Should not be confused with the actually-wired `commands.ViewMenuCommand` (#8 above).

---

## /invsee, /is (feature domain: inventory-menus)
Class: `UsefulCommands/Invsee.java`. Registered v1:src/Main/Main.java:642-643 (executor + `is` alias). plugin.yml desc "/invsee <username>", aliases `[is]` (no permission node declared in plugin.yml).

Dispatch v1:src/UsefulCommands/Invsee.java:30: `label.equalsIgnoreCase("invsee") || label.equalsIgnoreCase("is")`.
Permission: `player.hasPermission("k&k.inventory.*")` v1:35.

- **/invsee <player>** v1:37-82: requires exactly 1 arg. If target online (`Bukkit.getPlayer`), checks target isn't `k&k.owner` unless sender also is `k&k.owner` v1:43 (`!target.hasPermission("k&k.owner") || sender.hasPermission("k&k.owner")`), then `player.openInventory(target.getInventory())` v1:46 — directly opens the LIVE inventory object (shared reference, so this is a true live/editable invsee, not a snapshot). Else if offline but a known user (`Users.existUser`), constructs an NMS `EntityPlayer`/`PlayerInteractManager` to load a fake offline player entity v1:54-58, calls `target.loadData()` v1:61, same owner-permission check, opens inventory, and registers the constructed offline target into `EnderchestCommand.offlineEnderchest` map (cross-class static map reuse) v1:66 — note: it's stored under the **invsee-caller's UUID key** shared with the enderchest command's static map, meaning invoking `/invsee` on an offline player then later `/enderchest` (or vice versa) could interact with stale/wrong cached offline-player entities if both features are used in sequence by the same player (shared mutable static state across two unrelated command classes) — worth flagging as a cross-feature coupling risk for v3.
- Non-player sender: error message ("need to be on a pc-version..." — unusual phrasing) v1:89.
- No permission-check-without-return bugs here — structure is clean if/else throughout.

## /inventory (SAME class, feature domain: inventory-menus)
Dispatch v1:92 `label.equalsIgnoreCase("inventory")`. plugin.yml desc "/inventory clear <player>" (registered v1:src/Main/Main.java:644, no separate alias).
Permission: `sender.hasPermission("k&k.inventory.*")` v1:94 (same node as invsee).

- **/inventory clear <player>** v1:96-138: requires args.length>1 (i.e. `args[0]=clear`, `args[1]=player` — syntax is positional, no actual `"clear"` keyword validation is required to reach the online-target branch structurally, but line v1:102 does check `args[0].equalsIgnoreCase("clear")` before clearing) v1:96-113. If target online and args[0]=="clear": owner-permission guard, then `inv.clear()` v1:104-109. **Bug**: if `args[0]` is NOT "clear" (any other first arg) while target resolves online, falls to `else` at v1:110-113 printing usage — fine. But if target is OFFLINE (`Users.existUser(args[1])`) branch v1:114-134: it constructs the NMS offline player and calls `inv.clear()` **unconditionally without checking `args[0].equalsIgnoreCase("clear")` at all** v1:114-133 — meaning for an OFFLINE target, ANY first argument (not just literally "clear") triggers the destructive inventory-clear action, e.g. `/inventory foo <offlineplayer>` would still wipe their inventory. This is a real logic bug — the "clear" keyword is only validated on the online-player code path, not the offline one.
- Player-existence checks throughout use `Users.existUser` / NMS entity construction, same pattern as `/invsee`.

---

## /enderchest, /ec (feature domain: inventory-menus)
Class: `UsefulCommands/EnderchestCommand.java`. Registered v1:src/Main/Main.java:637-638. plugin.yml: `enderchest: description: /enderchest / permission: k&k.enderchest / aliases: [ec]` v1:plugin.yml:109-112.

Dispatch v1:src/UsefulCommands/EnderchestCommand.java:57 (`"enderchest" || "ec"`). Player-only, proper else-message v1:198-201.
Looks up `Users.getUser(uuid)` with exception handling v1:63-77 BEFORE any permission check.

Permission structure (unusual — checks a HIGHER/staff permission first, falls back to base):
- If `player.hasPermission("k&k.enderchest.others")` v1:78 → staff subcommands available:
  - **/enderchest check <player>** v1:83-138: views target's enderchest (online via `target.getEnderChest()` v1:108, or offline via NMS entity construction v1:116-133), guarded by `!target.hasPermission("k&k.owner")` (note: unlike invsee, there is NO "unless sender is also owner" override here — an owner target's enderchest can never be checked by staff, period) v1:106,124. **Bug**: inside this branch, `userTarget = Users.getUser(uuid)` v1:92 — looks up the **sender's own uuid**, not the target's, despite the variable name `userTarget` — looks like a copy-paste bug (should probably fetch the target's UUID), though `userTarget` is never actually used afterward in this branch so it's a harmless-but-confusing dead assignment / mislabeling bug.
  - **/enderchest open <player>** v1:139-166: opens the enderchest FOR the target player themselves (`target.openInventory(target.getEnderChest())` v1:161) rather than for the staff sender — i.e. this remotely forces open the target's own enderchest on their screen (unusual/prank-like feature). Requires target online implicitly via `userTarget.getPlayer()` v1:160 (NPE risk if `userTarget.getPlayer()` returns null for an offline player, since only online-player error handling is done via the catch block around `Users.getUser` at v1:146-159, not a null-check on `getPlayer()` itself).
  - **/enderchest help**: prints staffcommandhelp v1:167-172.
  - Unknown subcommand: also prints staffcommandhelp (same as help) v1:173-179.
  - No args at all (staff, args.length==0): opens **own** enderchest directly v1:180-183.
- Else if `player.hasPermission("k&k.enderchest")` (base perm) v1:185: no subcommands available at all — regardless of args, always just opens own enderchest v1:186-193 (any args silently ignored — no usage/help message ever shown to base-permission users, e.g. `/enderchest check bob` silently just opens their own chest, giving a base user a misleading result rather than a "no permission" or "unknown subcommand" message). Also checks duel-state via `Arena.isDuelling` before opening v1:187-192 (this duel-guard only applies to the base-permission path, NOT to the staff `k&k.enderchest.others` path — inconsistent; staff can open own/others' enderchest while duelling).
- Else: "no permission" message v1:196.

---

## /friends (alias friend, f) (feature domain: social)
Class: `Friends/FriendCommands.java`. Registered v1:src/Main/Main.java:598-599. plugin.yml desc "/friends <add/remove/list> <username>", aliases [friend, f] (no permission node in plugin.yml or code — **no `hasPermission` check anywhere in this entire file for any of the three commands**).

Dispatch v1:src/Friends/FriendCommands.java:65 (`"friends" || "friend" || "f"`).
- Player path v1:67-137: looks up `Users.getUser(uuid)` (note: **not wrapped in try/catch** here despite `Users.getUser` throwing `UserNotFoundException` elsewhere in the codebase — here it's just called as `if (Users.getUser(uuid) != null)` v1:72, implying either an overload that returns null instead of throwing, or a latent unhandled-exception risk if this shares the throwing overload used by other files. Given `ProductCommands`/`MenuCommand`/`EnderchestCommand` all wrap `Users.getUser` in try/catch for `UserNotFoundException`, but this file doesn't, it's likely this call can throw uncaught in the same way, or there's an overload divergence — flagged as "unclear, needs cross-referencing Users.java" behavior risk).
  - **/friends add <username>** v1:77-85 (needs exactly 2 args) → `sendFriendRequest()` v1:293-361: validates target exists v1:298, not self v1:310, not already friends v1:314, no duplicate incoming/outgoing request v1:317,320, saves request, notifies target if online (loop over `Bukkit.getOnlinePlayers()` v1:324-332) with a sound + message, notifies sender. Broad try/catch wraps whole method v1:296-360, generic message on any exception v1:356-360.
  - **/friends remove <username>** v1:87-95 (needs exactly 2 args) → `removeFriend()` v1:363-410: if actual friends, deletes friend + fires `AddFriendEvent` (note: uses "Add"FriendEvent even for a REMOVAL — likely a generic/misnamed event, or an event bug re-using the wrong event class for opposite semantics — worth flagging, though the event's actual handling logic is out of scope) v1:385-386; else if there's a pending outgoing request, revokes it instead v1:388-391; else error.
  - **/friends list** v1:97-122: **oddity/dead-code bug**: `if (target.getFriendAmount() > 10) {...} else {...}` v1:107 — both branches (v1:109-113 and v1:115-120) contain **byte-for-byte identical code** (loop printing `target.getFriendNames()`), meaning the `>10` conditional is entirely pointless/dead — likely leftover from an intended pagination feature that was never implemented. Calls `target.destroy()` afterward v1:122 (resource cleanup of a possibly newly-constructed `User` — but note `target` here is actually always the CALLER via `Users.getUser(uuid)`/`new User(uuid)` v1:99-106, not an arbitrary target — so `/friends list` only ever lists your OWN friends despite superficially being reusable code; there is no separate "list someone else's friends" for player-senders, only for console, see below).
  - Any other/no subcommand: prints `commandhelp` v1:124-129, or v1:131-136 if `Users.getUser(uuid) == null`.
- Console/non-player path v1:138-169: only supports **/friends list <username>** (needs exactly 2 args, args[0]=="list") v1:140-161 — looks up arbitrary target's friends by username via `Users.existUser`+`Users.fetchUUIDbyUsername` v1:144-146, prints their friend list — this is the "view anyone's friends" capability but restricted to non-player (console) senders only; **no permission check** gates this either (console commands typically implicitly require op/console anyway via server config, but nothing IN this code enforces it). Any other console invocation: prints `consolecommandhelp` v1:163-167.

## /request (feature domain: social)
Same class, dispatch v1:172 `label.equalsIgnoreCase("request")`. Registered v1:src/Main/Main.java:600. plugin.yml: `request: descrption: /request <accept/deny/list>...` (note plugin.yml has a typo "descrption" v1:plugin.yml:52 — cosmetic, doesn't affect function since Bukkit just won't recognize the misspelled key, meaning this command effectively has **no description shown** in-game, though functionally unaffected). No permission node.

- Player path v1:174-220 — **no `else` for `Users.getUser(uuid) == null`** at all (contrast with `/friends` which does print help in that case) — if `Users.getUser(uuid)` returns null, the whole block v1:181-219 is skipped and **nothing happens, no feedback** — silent no-op bug.
  - **/request accept <username>** v1:185-190 (needs exactly 2 args; if not-2-args, this specific subcommand does nothing/no message at all — a further silent no-op edge case, v1:187-190 has no else) → `acceptRequest()` v1:412-454: validates not already friends v1:421, validates a pending request from that user exists v1:423, saves friendship + fires `AddFirendEvent`(**correct semantics this time** — this really is an add) v1:425-426, notifies both.
  - **/request deny <username>** v1:192-197 (same silent-no-op-if-not-2-args issue) → `denyRequest()` v1:456-482: validates pending request exists v1:465, deletes it, notifies denier only (not the denied party).
  - **/request list** v1:199-205: prints all incoming request UUIDs — **bug**: the loop `for (UUID targetuuid : user.getFriendRequestList()) { player.sendMessage(... + user.getUsername()); }` v1:202-205 — the message uses `user.getUsername()` (the SENDER's own name) instead of resolving `targetuuid` to a name — every line of the "request list" prints the CALLER's own username repeatedly instead of each individual requester's name. Clear bug (the loop variable `targetuuid` is never actually used inside the loop body at all).
  - Other/no args: `requestcommandhelp` v1:206-218.
- Console path v1:221-253: **/request list <username>** (args.length==2, args[0]=="list") — same pattern as friends-console, prints target's `getFriendRequestNames()` v1:225-244. Other: `requestconsolecommandhelp` v1:248-251.

## /requests (feature domain: social)
Same class, dispatch v1:256 `label.equalsIgnoreCase("requests")`. Registered v1:src/Main/Main.java:601. plugin.yml desc "/requests to see all open friend-requests", no permission.

- Player-only, proper else-message for non-player v1:285-288.
- args.length==0 v1:262-277: looks up own `User`, prints `getFriendRequestNames()` (correctly, using actual names this time, not the `/request list` bug) v1:264-273; else (user lookup null) error message v1:274-276.
- Any args present: prints `requestcommandhelp` (reuses the /request help text, not a /requests-specific one — there's no dedicated requestshelp list, cosmetic mismatch) v1:278-284.
- Effectively `/requests` (no args) duplicates `/request list` but with a correctly-working implementation (unlike the buggy sibling).

---

## /shopkeeper (feature domain: misc — NPC/property administration, not items/inventory/social; closest existing bucket would be "npc-shopkeeper" or "world-admin"; going with "misc" per instructions but noting it's really an NPC-trait-reload admin tool tied to Properties/Towns/SpawnPoints/Citizens, distinct from both item-shop and player-inventory concerns)
Class: `NPCs/ShopkeeperCommands.java`. Registered v1:src/Main/Main.java:610. plugin.yml: `shopkeeper: description: /shopkeeper reload to reload the shopkeeper traits / permission: k&k.shopkeeper` v1:plugin.yml:73-75.

Dispatch v1:src/NPCs/ShopkeeperCommands.java:32.
Permission: `sender.hasPermission("k&k.shopkeeper")` v1:34 — no player-type guard at all (works fine for console too since `reloadShopkeeper` only uses `sender.sendMessage`, no player-only casts) — this is actually one of the more robust files in this batch, console-safe.

- **/shopkeeper reload** (exactly 1 arg, "reload") v1:36-40 → `reloadShopkeeper(sender)` v1:57-104 (static method): iterates all properties (`property.getIDList(null,null)`) v1:61, for each with a valid NPC ID, removes+re-adds the `Shopkeeper` trait v1:70,76, despawns if currently spawned (broadcasts to console) v1:71-75, respawns at the property's spawnpoint if one is configured v1:78-86, else warns all online OPs individually that no spawnpoint is set v1:87-95 (does NOT warn the invoking `sender` if sender isn't an op and isn't online — e.g. a non-op console/permission-holder invoking this wouldn't see the "no spawnpoint" warnings, only see the final blanket "Succesfully reloaded" message v1:103 regardless of per-property issues).
- Any other arg count/value: falsecommand usage v1:42-48.
- No sub-actions besides `reload` exist despite the class name "ShopkeeperCommands" (plural) — it's effectively a single-purpose command.

---

## Summary count

**33 distinct commands/subcommands found** across product/soulbound/ghosted/enchant/rename/lore/repair/menu/viewmenu/invsee/inventory/enderchest/friends/request/requests/shopkeeper:

1. /product set
2. /product get
3. /product give
4. /product remove
5. /product list
6. /product (no-args help)
7. /soulbound add
8. /soulbound remove
9. /ghosted add
10. /ghosted remove
11. /enchant <name> <level>
12. /enchant all
13. /rename <name>
14. /lore add
15. /lore clear
16. /repair (dead/unregistered, empty body)
17. /menu
18. /viewmenu <username>
19. /viewmenu stop
20. /invsee <player>
21. /inventory clear <player>
22. /enderchest (base, own chest)
23. /enderchest check <player> (staff)
24. /enderchest open <player> (staff)
25. /enderchest help (staff)
26. /friends add
27. /friends remove
28. /friends list (player + separate console variant)
29. /request accept
30. /request deny
31. /request list (player, buggy — prints own name; + separate console variant)
32. /requests (no-args)
33. /shopkeeper reload

## Key structural findings for v3 planning
- Two confirmed dead-code artifacts: `UsefulCommands/RepairCommand.java` (registered nowhere, empty handler) and `UsefulCommands/ViewMenuCommands.java` (registered nowhere, empty handler) — both candidates for deletion, not porting.
- Permission-check hygiene varies wildly: some files (ViewMenuCommand, ShopkeeperCommands) are clean with early returns; others (`FriendCommands`, all three of friends/request/requests) have **zero permission checks** anywhere; `ItemRenamer`/`LoreEditer` perform unguarded `(Player) sender` casts before/without an `instanceof` check, risking `ClassCastException` from console.
- Recurring `getItemInHand() != null || ... != Material.AIR` pattern (should be `&&`) appears in SoulboundCommands (x2) and EnchantmentCommand — makes the "no item in hand" guard dead code in all three places.
- Several genuine functional bugs found: `/ghosted` add/remove color-tag mismatch (GRAY vs DARK_GRAY) likely breaking ghosted-removal; `/request list` printing the wrong username in its loop; `/friends list` having two identical if/else branches (dead conditional); `/inventory clear` skipping the "clear" keyword check on the offline-player code path (any first arg destructively clears an offline target's inventory); remove-while-iterating-by-index bugs in `LoreEditer` (both add and clear paths).
- Cross-class static-state coupling: `Invsee.java` writes into `EnderchestCommand.offlineEnderchest` static map keyed by the invsee-caller's UUID — shared mutable state between two unrelated feature files.
# v1 — Siege-minigame / arena / skills domain command catalog

Full command catalog for Siege-minigame / Arena / Skills domain (knk-v1-archive). All citations verbatim `v1:path:line`. Root omitted from citations (relative to repo root, i.e. `src/...`).

================================================================
1. `/arena` — ArenaCommands.java (v1:src/Arenas/ArenaCommands.java)
================================================================
Registered permission per assignment: `k&k.arena`. Entire handler is wrapped in `sender instanceof Player` (v1:src/Arenas/ArenaCommands.java:80) — **console cannot use `/arena` at all** (falls through silently, returns false).

Main gate: `player.hasPermission("k&k.arena")` (v1:src/Arenas/ArenaCommands.java:84) wraps create/remove/part/location/npc/staff-help, but NOT `list` — see below.

- **`/arena create <name> <streetName> <townName> <streetNumber>`** (v1:...:90-147)
  - Requires `args.length==5`; requires an active WorldEdit selection (v1:98); `streetNumber` must be int (v1:100); town/street must exist; street number must be unused (`checkStreetNumber`, v1:109); WorldEdit selection converted to a WorldGuard `ProtectedCuboidRegion` and checked for overlap via `Worldguard.checkUniqueRegion` (v1:117) before calling `createArena()` (v1:471-498), which persists the arena, creates the WG region `arena_<id>` with ENTRY=ALLOW, greet message, priority 11, and runs `rg flag arena_<id> deny-blocks any` via `sender.performCommand` (v1:495).
  - Permission: gated by outer `k&k.arena` only.
  - **Bug**: error message on non-numeric `args[4]` references `args[6]`, `args[7]`, `args[8]` (v1:src/Arenas/ArenaCommands.java:138) — but this is a 5-arg command (`args.length==5` required at line 92), so `args[6..8]` are out of bounds → this message construction throws `ArrayIndexOutOfBoundsException` whenever a non-numeric street number is supplied. Also the usage-string help at line 146 references `<category> <income> <price> <contribution>` params that don't exist in the actual 5-arg parse — help text/behavior mismatch (leftover from a copy-pasted house/shop command).
  - Feature domain: siege-minigame (arena infrastructure).

- **`/arena remove <arenaName|arenaID>`** (v1:...:149-196)
  - Two-arg command; disambiguates by `main.isInt(args[1])` — non-numeric treated as name (v1:151), numeric as ID (v1:168). Validates existence via `arena.getArenaID`/`arena.getArenaIDList(null).contains`. Calls `removeArena()` (v1:500-520): removes all sub-region parts, removes gate region, deletes arena row.
  - Permission: outer `k&k.arena` only.

- **`/arena part add <arenaID> [battleground]`** (v1:...:197-250)
  - Requires `args.length>=3`; `args[2]` (arenaID) must be int; requires active WorldEdit selection; checks new region doesn't overlap a *different* arena via `Worldguard.checkSameRegionID` (v1:218); optional literal `"battleground"` 4th arg. Calls `addArenaRegion()` (v1:522-586): auto-assigns next free partID by probing region-manager keys, names region `arena_<id>,<partID>` or `...,<partID>-battleground`, sets priority 11/12; for battleground sets PVP=ALLOW, ENTRY=DENY with `non_members` region-group flags (v1:558-573); sets parent region to the arena gate.
  - Permission: outer `k&k.arena` only.

- **`/arena part remove <arenaName> <partID>`** (v1:...:252-287)
  - Requires `args.length==4`; `args[3]` must be int; arena must exist by name; partID must exist via `arena.checkPartID`. Calls `removeArenaRegion()` (v1:588-603) which removes the WG region (plain or `-battleground` suffix) and the DB part row.
  - Permission: outer `k&k.arena` only.
  - **Note**: `/arena part` with an unrecognized 2nd token (neither add/remove) prints full staff help (v1:288-294); `/arena part` alone (length<3) prints a bare usage line (v1:295-298).

- **`/arena location set <locationCategory>`** (v1:...:299-340)
  - Player must be standing inside an arena gate region; validates `locationName` via `arena.validLoc()`; resolves the arena via `Worldguard.getRegion(location,"arena",manager)` → `getStructureIDbyRegion`; saves a spawnpoint keyed `arena_<id>_<locationName>` at the player's exact location/yaw/pitch (v1:317).
  - Permission: outer `k&k.arena` only.

- **`/arena location remove <locationCategory> <arenaName>`** (v1:...:342-374)
  - Requires `args.length==4`; validates location category, arena existence, and that a spawnpoint ID exists for that pair before removing both the arena-side reference and the spawnpoint record.
  - Permission: outer `k&k.arena` only.
  - Typo in usage string: "locaiton" (v1:373).

- **`/arena npc refresh <arenaID>`** (v1:...:383-410)
  - Requires `args.length==3`; `args[2]` must be int and a known arena ID; calls `arena.refreshNPC(sender, arenaID)`.
  - Permission: outer `k&k.arena` only.

- **`/arena buy` / `/arena sell` / `/arena info`** (v1:413-422) — recognized as tokens but the matching `if` branch body is **empty** (v1:413-416): no message, no action, complete no-op stub. Any other unrecognized first arg prints staff help.

- **`/arena list`** (v1:441-449, dispatched from outside the `k&k.arena` permission gate at v1:439) — calls `arenaList()` (v1:605-623) which prints all arena names; arena **ID** is only shown if `sender.isOp() || sender.hasPermission("k&k.arena") || main.ownermodus.containsKey(...)` (v1:615). **This is the one `/arena` subcommand with NO permission requirement** — any player can run it.
  - No-arg `/arena` prints staff help if permitted, else plain `commandhelp` (v1:450-465).

Feature domain: siege-minigame (arena creation/administration is core infrastructure for duels/sieges).

================================================================
2. `/duel` — DuelCommands.java (v1:src/Arenas/DuelCommands.java)
================================================================
**No `hasPermission` check anywhere in this file** — any player online can use all subcommands (v1:src/Arenas/DuelCommands.java, entire file). Player-only; console gets an error (v1:165-168).

- **`/duel accept`** (v1:75-85): scans `inviteList` for an invite targeting this player, calls `invite.acceptInvite()`; if none found, sends "no invites" message.
- **`/duel deny`** (v1:86-97): same scan, calls `invite.denyInvite()`.
- **`/duel cancel`** (v1:98-107): scans for an invite this player *sent*, calls `invite.cancelInvite()`.
  - **Bug**: unlike accept/deny, if no matching invite is found the loop simply ends with **no feedback message at all** (v1:100-107) — silent no-op.
- **`/duel <playerName>`** (v1:108-147): sends a duel invite. Requires the *sender* to currently be standing in an arena region (`arenaID != null` via `Worldguard.getStructureIDbyRegion`, v1:110/72); target must be online and not self; checks for a pre-existing identical invite; constructs `new DuelInvite(user, userTarget, arenaID)` (v1:138) and confirms to sender.
- **`/duel <offlinePlayerName>`** (v1:148-150): if the name resolves to a known-but-offline user, sends "currently not online".
- Anything else / wrong arg count → prints `commandhelp` (v1:153-157, 160-163).

**Bug**: UUID comparisons throughout use reference equality `==` instead of `.equals()`: `invite.target.getUUID() == player.getUniqueId()` (v1:79), `invite.sender.getUUID() == player.getUniqueId()` (v1:90), `player.getUniqueId() == invite.sender.getUUID()` (v1:102), and again at v1:132. `UUID` is not guaranteed to be reference-identical across lookups, so these comparisons can spuriously fail to match a real invite depending on caching behavior of `getUniqueId()`/`getUUID()`.

Feature domain: siege-minigame (arena-scoped PvP duel).

================================================================
3. `/siege` — SiegeCommands.java (v1:src/Sieges/SiegeCommands.java)
================================================================
No-arg prints `staffcommandhelp` which advertises `join, leave, vote, skip, info, list` (v1:32-42), but **only join/leave/skip are actually implemented** — `vote`, `info`, `list` have no matching `if` branch anywhere in `onCommand`, so running them does absolutely nothing (falls through, no message).

**No `hasPermission` check anywhere in this file.**

- **`/siege join`** (v1:57-59): stub — sends `"Command not configured yet."` Unimplemented.
- **`/siege leave`** (v1:60-95): player-only (console gets `CommandExceptions.SenderNotPlayer`, v1:66); looks up `User`; finds active siege via `Sieges.findSiege(user)`; if none, informs and returns; else `siege.leavePlayer(user)`.
- **`/siege skip <siegeNumber>`** (v1:96-208): requires 2nd arg. Gating logic is donator-tier based, NOT a Bukkit permission: player must have `user.getDonatorID() >= 1` (v1:125) else blocked with a message pointing to `/donator`; **console senders bypass this check entirely** (`allowedToSkip = true` unconditionally at v1:136). `siegeIndex = Integer.valueOf(siegeArg) - 1` used to index `Sieges.Sieges.get(siegeIndex)` (v1:143-145) — **no bounds check**; an out-of-range index throws `IndexOutOfBoundsException` (unhandled). Calls `siege.skipStage(sender)`.
- Large dead/commented-out code block (v1:166-208) — leftover Hide-and-Seek skip logic, not live.

Feature domain: siege-minigame (core siege state machine control).

================================================================
4. `/scenario` — ScenarioCommands.java (v1:src/Sieges/ScenarioCommands.java)
================================================================
Help text advertises `create, remove, spawnpoint, objective, info, list` (v1:30-40) but **only create/remove are implemented**; spawnpoint/objective/info/list have no code branch — silently do nothing.

**No `hasPermission` check anywhere in this file** (odd for an administrative/world-editing command).

- **`/scenario create`** (v1:56-84): player-only; looks up `User`; starts a builder flow via `new ScenarioCreation(user)` (v1:84) — presumably a stateful wizard (not in assigned files).
- **`/scenario remove <id|name>`** (v1:85-161): player-only; requires `args.length==2`. If `args[1]` is numeric, treated directly as `scenarioID`; otherwise treated as a name, and resolution **requires the player to be standing inside the town region** the scenario belongs to (`Worldguard.getStructureIDbyRegion("town",...)`, v1:132) — if not standing in a town, remove-by-name fails with an explicit message (v1:136). Instantiates the scenario object (`Scenarios.instantiateScenario(scenarioID,false)`) and calls `Scenario.removePermanently(player)` (v1:160).

Feature domain: siege-minigame (siege "scenario" = objective/map configuration).

================================================================
5. `/hideandseek` (alias `/hs`) — HideAndSeekCommands.java (v1:src/HideAndSeek/HideAndSeekCommands.java)
================================================================
- No-arg (v1:49-64): prints `commandhelp` (join/leave/skip/info); if `sender.hasPermission("k&k.hideandseek")` (v1:52) additionally appends `stop`/`autostart` help lines — but this only affects the *displayed help text*, not gating of those subcommands' logic (each still independently checks the permission, see below).

- **`/hs join`** (v1:66-100): player-only; requires at least one active HS instance; **iterates every `HideAndSeek` instance whose `getMatchmaking()` is true and calls `hs.joinPlayer(user)` on ALL of them, with no `break`** (v1:90-96) — **bug**: a player could be joined into multiple simultaneous Hide-and-Seek games. No permission check.
- **`/hs leave`** (v1:101-136): player-only; finds the user's active HS via `HideandSeeks.findHideAndSeek(user)`; if `hs == null`, sends an error message (v1:129) but **there is no `return` afterward** — execution falls through to `hs.leave(hs.getParticipant(user))` (v1:132) on a null reference → **NullPointerException bug**. No permission check.
- **`/hs skip [id]`** (v1:137-238):
  - Player branch: requires `user.getDonatorID() >= 1` (donator-tier gate, not a Bukkit permission, v1:162) else blocked; if the player is in an active HS, skips it directly; else, if `user.inStaffModus() || user.inOwnerModus()` (mode-flag gate, not `hasPermission`, v1:173), allows skip-by-ID with a numeric 2nd arg; otherwise errors.
  - Console branch (v1:204-238): always allowed, no permission of any kind, requires numeric ID arg, calls `hs.skipStage(null)`.
- **`/hs info`** (v1:239-270): requires at least one active HS; player-only; opens `menu.openHideAndSeekOverview(user)`. No permission check.
- **`/hs stop <id>`** (v1:271-325): gated by `sender.hasPermission("k&k.hideandseek")` (v1:273); requires numeric ID arg; calls `hs.forceStop(user)` (user may be `null` if sender is console).
- **`/hs autostart <id>`** (v1:326-375): gated by `sender.hasPermission("k&k.hideandseek")` (v1:328); toggles `hs.setAutostart(...)`; when turning autostart ON and the HS instance is fully idle (`!cooldown && !matchmaking && !progress`, v1:365), immediately calls `hs.startMatchmaking()` as a side effect.

Feature domain: siege-minigame (adjacent PvP minigame, same permission node `k&k.hideandseek`).

================================================================
6. `/specialskill` — SpecialSkillCommands.java (v1:src/Skills/SpecialSkillCommands.java)
================================================================
Player-only (whole handler wrapped, v1:47; console gets explicit error v1:224). Single top-level gate: `player.hasPermission("k&k.specialskill")` (v1:66) covers all subcommands uniformly.

Help text advertises `points set/add/remove`, `set`, `remove`, `list`, `info <name/id>` (v1:29-40); **`info` is never implemented** as a branch — silently falls through to generic help.

- **`/specialskill points set <amount> <username>`** (v1:74-89 dispatch → `setSpecialSkillPoints()` v1:230-271): requires numeric amount; looks up target (falls back to constructing an offline `User` if not online, v1:244); calls `userTarget.setSkillPoints(true, amount)` — correctly targets `userTarget`.
- **`/specialskill points add <amount> <username>`** (v1:91-106 → `addSpecialSkillPoints()` v1:273-314): same shape, calls `userTarget.addSkillPoints(...)` — correctly targets `userTarget`.
- **`/specialskill points remove <amount|all> <username>`** (v1:108-123 → `removeSpecialSkillPoints()` v1:316-370):
  - **Bug 1**: when `args[2].equalsIgnoreCase("all")`, the call site does `this.removeSpecialSkillPoints(user, Integer.valueOf(args[2]), args[3], true)` (v1:118) — `Integer.valueOf("all")` **throws `NumberFormatException`** immediately (uncaught), so `/specialskill points remove all <username>` always crashes before reaching the method body.
  - **Bug 2**: if `args[2]` is neither a valid integer nor `"all"`, no branch matches (v1:112-119 has no else covering this case) — silent no-op, no feedback.
  - **Bug 3 (most severe)**: inside `removeSpecialSkillPoints()` itself, both branches operate on `user` (the command-issuing staff member) instead of the resolved `userTarget` (v1:342 `user.setSkillPoints(true,0)`; v1:352 `user.removeSkillPoints(true, amount)`) — despite looking up `userTarget` by `targetUsername` (v1:323) and printing messages that claim the target's balance was changed (v1:348, v1:358), the points are actually removed from the **staff member's own** balance, not the target's. Confirmed by contrast with the correctly-targeted `set`/`add` sibling methods.
- **`/specialskill set <specialskill> <username>`** (v1:139-172): resolves skill by name via `specialskill.getSpecialSkillID`; target must be resolvable via `Users.fetchUUIDbyUsername` (online lookup, throws `UserNotFoundException` if not found/online — offline players are NOT supported here, unlike the points methods); calls `userTarget.setSpecialSkill(specialskillID)`.
- **`/specialskill remove <username>`** (v1:174-199): same online-only lookup; calls `userTarget.setSpecialSkill(0)`.
- **`/specialskill list`** (v1:200-203 → `listSpecialSkill()` v1:372-392): lists all special skills with name/description; ID shown only if `sender.isOp() || sender.hasPermission("k&k.town")` (**note: checks `k&k.town`, not `k&k.specialskill`** — v1:382, likely a copy-paste artifact from another list method) `|| main.ownermodus.containsKey(...)`.

Feature domain: judgment call — this is a player-progression/skill-point economy tied to `Users`, not the siege minigame proper. Classify as its own `specialskill`/skills sub-area (economy-adjacent, since "skillpoints" function as a spendable currency).

================================================================
7. `/treasure` — TreasureCommands.java (v1:src/Treasure/TreasureCommands.java)
================================================================
Single gate for entire command: `sender.hasPermission("k&k.treasure")` (v1:40) — covers create/cancel/activate/deactivate/remove/help; console is not excluded (Bukkit `CommandSender.hasPermission` works for console too).

Help advertises `create, cancel, activate, deactivate, remove, info, list` (v1:23-34); **`info` and `list` are never implemented** — no matching branch, falls to generic staff-help else (v1:120-126).

- **`/treasure create <grade 1-5>`** (v1:44-74): requires numeric grade strictly between 0 and 6 (i.e. 1-5, v1:51); player-only; stores `uuid -> grade` into `Treasures.createTreasure` map (v1:57), telling the player to right-click a chest to complete creation (actual creation happens in a listener elsewhere, out of scope).
- **`/treasure cancel`** (v1:75-92): player-only; removes the player's pending entry from `Treasures.createTreasure` if present.
- **`/treasure activate`** (v1:93-96): calls `Treasures.instantiateAll(-1)` — works for console too (no player-only gate).
- **`/treasure deactivate`** (v1:97-100): calls `Treasures.stopAll()`.
- **`/treasure remove <ID>`** (v1:101-117): **entirely broken/stub**. Three validation checks each have an **empty if-body and no `return`**:
  - `if (args.length != 2) { }` (v1:103-106) — does nothing, doesn't guard against missing `args[1]`.
  - `if (!main.isInt(args[1])) { }` (v1:107-110) — does nothing; falls through to `Integer.valueOf(args[1])` (v1:111) which will throw `NumberFormatException` on non-numeric input, or `ArrayIndexOutOfBoundsException` if `args.length==1` (since the length check above is a no-op).
  - `if (Treasures.findTreasure(treasureID) != null) { }` (v1:112-115) — does nothing; **the actual removal logic was never written**. No message is ever sent to the sender for this subcommand under any input. Confirmed dead/incomplete implementation.

Feature domain: judgment call — `misc`/gameplay-event system (treasure chests are a world-event minigame, not core siege), closer to misc than economy despite granting loot.

================================================================
8. `/vote` — VoteCommand.java (v1:src/Votes/VoteCommand.java)
================================================================
**No `hasPermission` check anywhere in this file** — fully open to any sender including console.

- **`/vote`** (no args) (v1:131-137): prints `votemessage` — static info block with two external voting-site links.
- **`/vote rewards`** (v1:85-129): with no further arg, or unrecognized 2nd arg, prints `defaultrewards` (v1:118-122, 124-128); with `args[1]` = `default`/`noble`/`royal`/`dragonblood`(or alias `db`) prints the matching static reward list (v1:89-116). Purely informational — no actual reward-granting logic lives here (presumably a Votifier listener elsewhere handles the real grant).
- **Gap**: if `args[0]` is anything other than `"rewards"` (e.g. `/vote foo`), there is no `else` branch at all (v1:85-130) — the command silently does nothing, not even a usage/error message.

Feature domain: judgment call — `misc`/economy-adjacent (voting rewards feed into coins/gems/exp, but this file itself is purely informational text, no transactional logic).

================================================================
SUMMARY OF CROSS-CUTTING OBSERVATIONS
================================================================
- Permission conventions are wildly inconsistent across this domain: `ArenaCommands`/`TreasureCommands`/`SpecialSkillCommands`/`HideAndSeekCommands` (stop/autostart) use explicit `k&k.<feature>` `hasPermission` nodes; `DuelCommands`, `SiegeCommands`, `ScenarioCommands`, `VoteCommand`, and most of `HideAndSeekCommands` (join/leave/skip/info) check **no Bukkit permission at all**, relying instead on ad-hoc gates like donator tier or staff/owner "modus" flags, or nothing.
- Several files have help text advertising subcommands that were never implemented: `SiegeCommands` (vote/info/list), `ScenarioCommands` (spawnpoint/objective/info/list), `SpecialSkillCommands` (info), `TreasureCommands` (info/list). These are documentation-only, not real commands, and were not counted below.
- `ArenaCommands` `buy`/`sell`/`info` tokens are recognized but execute an intentionally empty block (no-op) rather than falling to the generic help.

N = 36 distinct implemented commands/subcommands found across arena/duel/siege/scenario/hideandseek/specialskill/treasure/vote (arena:8, duel:4, siege:3, scenario:2, hideandseek:6, specialskill:6, treasure:5, vote:2).
# v1 — World-admin / misc / dev-tools domain command catalog

Root: /c/Users/Pandi/Documents/Werk/KnightsAndKings/Repository/knk-v1-archive (all citations `v1:src/...`)

=== /afk (AfkCommand) — misc ===
File: src/Afk/AfkCommand.java
- Syntax: `/afk` (no args used). v1:src/Afk/AfkCommand.java:22-24
- Args: none.
- Permission: **NONE checked** — any sender can run it. v1:src/Afk/AfkCommand.java:22-53
- Goal: only runs `if (sender instanceof Player)` (v1:24-26); looks up `Users2.FindUser(uuid)` (v1:33); on failure calls `ErrorHandlers.userNotFoundAction(null, player, true)` and returns false (v1:34-43); toggles `user.setAfk()`/`user.removeAfk()` (v1:44-50). Sends no chat feedback to the player at all (no sendMessage anywhere in the success path) and no message for console senders either — silently does nothing for console.
- Bugs: no permission gate; no feedback message on toggle; console sender falls through with zero output (dead branch, no else on `instanceof Player`).

=== /discord (DiscordCommand) — misc ===
File: src/UsefulCommands/DiscordCommand.java
- Syntax: `/discord`, no args. v1:src/UsefulCommands/DiscordCommand.java:33
- Permission: NONE checked. v1:31-40
- Goal: purely informational — prints static `discordmessage` list (invite link) to sender. v1:22-28, 35-39
- Bugs: none functional; trivial.

=== /heal (HealCommands) — misc ===
File: src/UsefulCommands/HealCommands.java
- Syntax: `/heal`, no args. v1:21
- Permission: `k&k.heal` checked with proper else-branch message. v1:23, 35-38
- Goal: `player.setHealth(player.getMaxHealth())`, `setFoodLevel(20)`, sends achievement message. v1:27-30
- Non-player sender gets explicit error message (correct handling). v1:31-34
- No bugs found.

=== /message (alias msg) and /reply (alias r) — MessageCommands.java, same class, dispatched by `label` — misc ===
File: src/UsefulCommands/MessageCommands.java
**/message <player> <message>**
- Syntax/args: v1:37-92. Requires `args.length >= 2` else shows usage help (v1:42-87, commandhelp line 2 = "-/message <player> <message>", v1:27-33).
- Permission: **NONE checked** for either sub-command.
- Goal: validates sender isn't messaging self (v1:45-46, 80-83); resolves target via `Bukkit.getPlayer` (v1:47); builds message string avoiding leading space via length check (v1:49-59); records reciprocal reply-target map `main.msgReceived` for BOTH parties (v1:63-64); sends colored messages to both, plays `NOTE_PLING` sound to target (v1:65-67); invokes `socialSpy` (v1:69, defined 139-161).
- Unused variable `senderUUID` declared but never used. v1:61
- If target not currently online: distinguishes "not online" vs "no player found" via `Users.existUser`. v1:70-79

**/reply <message> (alias /r)**
- Syntax/args: v1:93-135. Requires prior `main.msgReceived` entry (v1:99, error "You have nobody to reply to!" v1:127-129) and `args.length >= 1` (v1:101, else shows commandhelp.get(3) = "-/reply <message>" v1:125).
- Permission: NONE checked.
- Goal: looks up last message-partner username from map (v1:103), resolves online target (v1:104), builds message — **bug: leading-space bug**, loop starts at i=0 always prepending a space to an initially empty string (v1:106-110), unlike /message's cleaner builder. Sends messages both ways, plays sound, updates `msgReceived` only one-directionally for the reply-map refresh (target->sender, v1:116), calls `socialSpy` (v1:118).
- Bug: `UUID targetUUID` declared at line 62 unused issue N/A (used at 62… actually only used at v1:63-64 in /message; in reply targetUUID used at 116, fine).

**socialSpy(sender, target, message)** — staff/owner eavesdrop broadcast, not itself a command.
- v1:139-161. Broadcasts every private message to online players who `hasPermission("k&k.staff")` and NOT `k&k.owner"` (v1:146), excluding sender/target by UUID — **bug: compares UUIDs with `!=` (reference inequality) instead of `.equals()`** at v1:148, 155 — technically incorrect equality check for object identity (works in practice only because Bukkit typically returns cached UUID instances, but is not guaranteed-correct code).
- Separately broadcasts to any player whose `main.ownermodus` map entry is `true` (owner "spy mode" toggle) v1:152-159, same UUID `!=` bug pattern.

=== /page (PageCommand) — misc ===
File: src/UsefulCommands/PageCommand.java
- Syntax: `/page`, no args. v1:33
- Permission: NONE. v1:31-39
- Goal: purely informational, prints static `pagemessage` (link to planetminecraft server page). v1:23-28, 35-38
- `main` field is `@SuppressWarnings("unused")` — confirmed genuinely unused in the class. v1:16-21

=== /ping (PingCommands) — misc ===
File: src/UsefulCommands/PingCommands.java
**`/ping` (no args, self)**
- Permission: NONE checked for the command overall.
- Goal: requires `sender instanceof Player` (else error, v1:67-69); looks up `Users.getUser(uuid)` with try/catch → `ErrorHandlers.userNotFoundAction` on failure (v1:48-60); reports `user.getPing()`; warns if ping > 100. v1:61-66

**`/ping <player>` (args.length==1)**
- Goal: `Player target = Bukkit.getPlayer(username)` (v1:74) then **immediately dereferences `target.getUniqueId()` at line 75 without a null check** — **bug: NullPointerException if target is offline**, since the null-check (`if (target != null)`, v1:91) happens only afterward, too late to prevent the crash on line 75.
- After the (unreachable-if-null) UUID fetch, looks up `Users.getUser(targetUUID)`, reports ping, else distinguishes offline vs unknown player via `Users.existUser`. v1:78-100

**`/ping` with 2+ args**
- Prints `commandhelp` usage block. v1:101-107

=== /staffchat (aliases sc, st) — StaffChatCommand — misc ===
File: src/UsefulCommands/StaffChatCommand.java
- Syntax: `/staffchat <message>` / `/sc` / `/st`. v1:38
- Permission: `k&k.staff` checked with proper else. v1:40, 92-95
- Args: requires `args.length > 0` else shows help (`commandhelp.get(2)` = "-/st <message>"). v1:42, 88-91
- Goal: broadcasts the message to every online player who also has `k&k.staff` (v1:44-46), prefixed with sender's chat-prefix (looked up via `Users.getUser`, with try/catch → `ErrorHandlers.userNotFoundAction`, v1:53-67) or `"[CONSOLE]: "` for non-player senders (v1:69-72); plays `NOTE_PLING` sound at volume 0.5 to each staff recipient (v1:85).
- No functional bugs found (message-builder quirk at v1:76 `msg.length() <= 1` still works correctly for first token).

=== /freeze — FreezeCommands.java — DEAD/UNWIRED CODE ===
File: src/UsefulCommands/FreezeCommands.java
- Confirmed via `grep -rn "FreezeCommands" src/`: only self-references in the file itself (class decl v1:13, constructor v1:16) plus the compiled `.class` binary match. **It is never registered as a command executor in Main.java, and not referenced anywhere else in the source tree.** It is fully dead code / an unimplemented stub.
- `onCommand` body is literally `return false;` — does nothing whatsoever regardless of label/args/permissions. v1:33-36
- Contains only unused scaffolding: descriptive comments outlining intended freeze semantics (can't walk/take damage/run commands/be teleported/chat except to freezing staff member; quitting while frozen = 7-day ban) at v1:21-23, and an unused `commandhelp` list for `/freeze <player> <reason>` and `/unfreeze <player>` (v1:25-31) that is never referenced by the no-op `onCommand`.
- No permission node is ever checked (nothing to check — dead).

=== /weather — WeatherChangeCommand — world-admin ===
File: src/UsefulCommands/WeatherChangeCommand.java
- Syntax: `/weather <rain|storm|r|sun|s|allowchange>`. v1:24
- Permission: `k&k.weather` checked with else-branch message. v1:26, 62-65
- **Bug: `Player player = (Player) sender;` cast happens unconditionally right after the permission check, before any `instanceof Player` check** (v1:28) — a console sender with `k&k.weather` permission would throw `ClassCastException`.
- Args: exactly 1 arg required else usage message (v1:29, 58-61).
  - `rain`/`storm`/`r`: sets `Weatherchangeallow=true`, `world.setStorm(true)`, message, then immediately flips flag back `false` (v1:31-36) — pattern presumably to permit a `WeatherChangeEvent` listener elsewhere to allow this programmatic change.
  - `sun`/`s`/`""` (empty string also matches!): sets storm false the same way. v1:37-42 — note `args[0].equalsIgnoreCase("")` is effectively unreachable since args.length==1 guarantees a non-empty token normally, but could match if user passes a literal empty-string argument.
  - `allowchange`: toggles the static `WeatherChange.Weatherchangeallow` flag directly. v1:43-53
  - else: usage message. v1:54-56

=== /gamemode (alias gm) — GameModeCommand — world-admin ===
File: src/UsefulCommands/GameModeCommand.java
- Syntax: `/gamemode [0|1|2|survival|creative|spectator|s|c|sp] [player]`. v1:23
- Permission: `k&k.gamemode` for self; `k&k.gamemode.others` additionally required to target another player (v1:25, 38/63/88).
- **Bug: `Player p = (Player) sender;` cast without `instanceof` check** in the args.length==1/0 self-target branches (e.g. v1:33, 58, 83, 110) — console with `k&k.gamemode` crashes with `ClassCastException`.
- **Bug: missing feedback** — if sender lacks `k&k.gamemode.others` in the 2-arg branch, the `if (sender.hasPermission(...))` (v1:38, 63, 88) has no `else`, so the command silently does nothing with zero message to the sender.
- Goal per branch: creative (1/creative/c) v1:29-53, survival (0/survival/s) v1:54-78, spectator (2/spectator/sp) v1:79-103, else usage v1:104-107; no-args toggles cyclically survival<->creative, spectator->survival v1:108-124.

=== /fly — FlyMode — world-admin ===
File: src/UsefulCommands/FlyMode.java
- Syntax: `/fly [enable|on|disable|off] [player]`. v1:26
- Permission: `k&k.fly` (single node governs both self and others — no separate "others" permission). v1:29
- **Bug: `Player p = (Player) sender;` cast without `instanceof Player` check** at v1:28 — console with `k&k.fly` crashes.
- **Bug (logic error) in disable-others branch**: checks `p.getAllowFlight()` (the **sender's own** fly state) instead of `target.getAllowFlight()` when deciding whether to disable another player's fly mode — v1:72 should reference `target`, not `p`. This means disabling another player's flight is gated on the *staff member's own* current fly state, not the target's.
- **Bug: enable-others branch never notifies the target player**, only the sender (v1:44, 48) — target gets no message that fly was enabled for them.
- Toggle branches (no args) at v1:97-109 work correctly off `p.getAllowFlight()`.

=== /knightsandkings (alias k&k) reload — ReloadCommand — world-admin ===
File: src/UsefulCommands/ReloadCommand.java
- Syntax: `/k&k reload` (only "reload" subcommand recognized). v1:45, 51
- Permission: `k&k.reload` with else message. v1:47, 65-67
- Goal: `args.length==1 && args[0]=="reload"` → `main.reload(sender)` (v1:53); else usage message; `args.length != 1` prints full help list. v1:49-64
- Contains a fully **commented-out** `@EventHandler onReloadCommand(PlayerCommandPreprocessEvent)` (v1:29-41) intended to intercept vanilla `/reload`, `/rl`, `/rel` and redirect to `main.reload` — currently inert/disabled dead code, not active.

=== /tpa — PlayerTeleportCommand — world-admin ===
File: src/UsefulCommands/PlayerTeleportCommand.java
- Syntax varies by permission tier. Help text: v1:42-50.
- Requires `args.length >= 1` and `sender instanceof Player`, else prints permission-tiered usage blocks (v1:210-228: normal/staff/owner-specific usage lines gated by `k&k.teleport.normal`/`k&k.teleport.staff`/`k&k.teleport.owner`||isOp).
- Looks up sender's `User` via `Users.getUser(uuid)` w/ try-catch → `ErrorHandlers.userNotFoundAction`. v1:65-77

**Owner/staff path** — gated by `main.ownermodus.get(uuid)==true` (an in-memory "owner mode" toggle map), NOT a permission string. v1:78
- `/tpa <p1> <p2> [silent|s]` (2-3 args): **Bug — `Bukkit.getOnlinePlayers().contains(args[0])`** at v1:82/85 compares a `Collection<Player>` against a raw `String` — this is always `false` (Player.equals(String) never true), so **this whole branch is dead/unreachable**; the intended teleport-two-players logic (v1:84-98, silent vs. announced messaging, correctly implemented internally) can never actually execute due to this guard bug.
  - Falls through instead to the `else if (Users.existUser(args[0]))` branch (v1:110) — spawnpoint-teleport logic for offline-lookup-by-username: resolves target's saved spawnpoint, finds matching house via `house.getHouseSpawnPoint(i)==spawnpointID` (v1:130-148). **Bug: no `break` after a match is found** inside the `for (int i : house.getHouseIDList(null))` loop — after teleporting on a match it keeps iterating and the `else` branch (v1:144-147) fires an erroneous "An error occured... contact Pandi" message for every subsequent non-matching house, potentially spamming/misleading the sender even on success.
- `/tpa <player>` (1 arg, owner-mode): teleports sender directly to that player if online (v1:163-166), else distinguishes offline vs unknown (v1:167-176).
- `args.length==0` under this branch: empty no-op else (v1:178-180 — dead stub, does nothing).

**Normal-player path** — `k&k.teleport.normal` permission (v1:181).
- `/tpa <player>` (1 arg): requires `user.getCoins() >= 10000` else shows coin-requirement message (v1:185, 199-202).
  - `accept`/`a` and `deny`/`d` subcommands are **empty stub blocks that do nothing** (v1:187-191) — **major bug: /tpa accept and /tpa deny are non-functional no-ops.**
  - Otherwise (online target): sets `Main.teleportconfirm.put(uuid, 30)`, prints a 30-second-confirmation prompt to both sender and target instructing them to type `/tpa accept|deny` (v1:194-197) — **but since accept/deny are stubs and the referenced chat-listener for "cancel" is commented out (v1:234-244), the confirmation flow never completes and the teleport itself never actually happens for normal players.** No coins are ever deducted or transfer executed anywhere in this file for the normal-tier path.
- Usage-only branch when args wrong length: v1:203-207.

=== /spawn — SpawnCommand — world-admin ===
File: src/UsefulCommands/SpawnCommand.java
- Syntax: `/spawn [player]`. v1:37
- **Bug: `Player player = (Player) sender;` cast without `instanceof` check** at v1:39 — console crashes with `ClassCastException` before any permission check even runs.
- Looks up `Users.getUser(uuid)` w/ try-catch → `ErrorHandlers.userNotFoundAction`. v1:43-55
- Permission: `k&k.spawn` (v1:56), plus `k&k.spawn.others` to teleport a named target (v1:67).
- Entire body is wrapped in `if (spawnpoint.getSpawnPointID("spawn") != null)` (v1:58) — **bug: if no spawn point is configured, a regular non-op player gets ZERO feedback** (only `player.isOp()` branches print "No spawn-location has been set..." at v1:86-89 and v1:111-114) — silent no-op for ordinary users in that misconfiguration case.
- `args.length==1` (teleport a named target, requires `k&k.spawn.others` else explicit error). v1:61-76
- No-args, owner-mode (`main.ownermodus`): instant teleport, no delay/duel-check. v1:79-89
- No-args, regular player: checks `Arena().isDuelling(uuid)` and blocks with error if true (v1:104-109); otherwise `spawnpoint.tryRegularTeleport(user, "spawn")` (v1:110). A commented-out 3-second-delay scheduled-task version is present but inactive (v1:94-103).

=== /tutorial — TutorialCommands — misc ===
File: src/Tutorial/TutorialCommands.java
Subcommands: `start`, `info`, `list`, else/no-args → help. Two help-text variants: `staffcommandhelp` (v1:28-35, shown to holders of `k&k.tutorial.others`) vs `commandhelp` (v1:37-44, everyone else).

**`/tutorial start <tutorial> [player]`**
- 3-arg staff form: requires `k&k.tutorial.others`; resolves target, `Users.getUser` w/ try-catch → `ErrorHandlers.userNotFoundAction`; validates tutorial via `Tutorial.isValid`; `tutorial.createTutorial(userTarget, tutorialName)`. v1:55-92
- 2-arg self form: requires `sender instanceof Player`, else error; same validate+create flow for self. v1:93-126
- Permission: `k&k.tutorial.others` gates only the "start for someone else" 3-arg form; the 2-arg self-service form has **no permission check at all**.

**`/tutorial info <tutorial> [player]`** — mirrors `start`'s structure (3-arg staff / 2-arg self), same permission pattern (`k&k.tutorial.others` for targeting others, none for self). v1:137-189. Sends tutorial description via `tutorial.file.getDescription`.

**`/tutorial list [player]`**
- **Bug: 2-arg staff branch reads `Player target = Bukkit.getPlayer(args[2])` at v1:195, but `args.length==2` (checked at v1:192) means the only valid indices are `args[0]` and `args[1]` — `args[2]` is out of bounds → guaranteed `ArrayIndexOutOfBoundsException`** whenever a staff member with `k&k.tutorial.others` runs `/tutorial list <targetPlayer>`. (Should almost certainly be `args[1]`.)
- 1-arg self form works correctly: calls `showTutorialList((Player) sender)`. v1:207-215
- `showTutorialList` (v1:262-284) iterates all tutorials, printing name/description/completion status/reward (gems+XP) per tutorial — helper, not a command itself.

=== /initiate — me/Pandi/Commands.java — dev-tooling / misc (setup) ===
File: src/me/Pandi/Commands.java
- Syntax: `/initiate database <host> <port> <dbname> <user> <password>` (exactly 6 args incl. subcommand). v1:95-182
- Permission: `k&k.initiate` with else message. v1:97, 183-186
- Only recognized subcommand is `database` (the `possible_initiations` list literally contains only "database", v1:111); anything else → error listing possibilities. v1:168-177
- Goal: writes `db-connection.yml` in the plugin data folder with HOST/PORT/DATABASE/USER/PASSWORD via Bukkit `YamlConfiguration` (v1:100, 134-149); "none" password → empty string (v1:127-130); wrong arg count → usage message (v1:161-167). Domain: dev/infra setup, not gameplay — misc.

=== /test — me/Pandi/Commands.java — dev-tooling / misc grab-bag (individual subcommands span domains, noted) ===
File: src/me/Pandi/Commands.java
- Permission: `k&k.test` gates the entire command, else message. v1:189-191, 756-759
- Requires `sender instanceof Player` for the entire subcommand dispatch chain except one special "loop" case for non-players (see below). v1:193
- **Bug: `args[0]` is read at v1:214 with no preceding `args.length >= 1` check** — running `/test` with zero arguments as a player throws `ArrayIndexOutOfBoundsException`.
- **Bug: nearly all subcommands are independent `if` blocks, not `else if`** — so subcommand names that happen to collide both fire. Confirmed collision: **`"bar"` appears twice** (v1:386 ActionBar test-message sender, and v1:586 wither-removal utility) — `/test bar` runs BOTH bodies sequentially in one invocation.
- User lookup via `Users.getUser(uuid)` w/ try-catch → `ErrorHandlers.userNotFoundAction`, done once up front (v1:200-212) then reused by all subcommands as `user`.

Enumerated subcommands (all under `if (sender instanceof Player)`, require `k&k.test`):
1. `user` — misc/dev: re-fetches `Users.getUser`, catches only `NullPointerException` (inconsistent with the rest of the file's `UserNotFoundException` pattern), prints debug messages. v1:214-228
2. `leftovers` — misc/dev cleanup: removes entities named "Z" or "Zz" across all worlds. v1:229-241
3. `trait` — NPC/minigame: spawns an NPC with `TestTrait`. v1:242-249
4. `reach` — quest system: force-completes `user.getQuestList().get(0).goalReached()` — **no bounds check, NPE/IndexOutOfBounds if quest list empty.** v1:250-253
5. `loop` (player variant) — dev/text-utility: splits a hardcoded Dutch sentence into chunks of 5 words, prints each chunk. v1:254-275
6. `transport` — minigame: creates/stops a `Transport` instance (`tp.cancel("Cancelled")` via `transport stop`). v1:276-290
7. `banner` — inventory/dev: builds and gives a patterned banner ItemStack. v1:291-308
8. `assign` — quest/economy: instantiates and assigns SEVEN different `Assignment` subtypes to the user simultaneously (food, property-enter, travel-specific, kill, travel-distance, harvest, travel-random), sends one confirmation message referencing only the last one. v1:309-326
9. `savep` — quest/economy: finds first `AssignmentTravelSpecific` in user's list and calls `saveAll()`. v1:327-339
10. `retrievep` — **empty no-op stub.** v1:340-343
11. `assignments` — quest: reports assignment-list size or "no assignments". v1:344-353
12. `frontlocation` — minigame (bandits): drops 2 gold nuggets at a computed bandit-spawn location. v1:354-361
13. `timer` (`start`/`stop`) — dev utility: `BukkitRunnable` incrementing a field `timer` every second; `stop` cancels and reports elapsed value. v1:362-385
14. `bar` (1st) — UI/dev: sends a test `ActionBar` message. v1:386-391 (see collision bug above)
15. `ai` — pathfinding/dev: runs `PathFinder` between two named spawnpoints, replaces path blocks with glass (visualizes path — destructive to world). v1:392-414
16. `npc` — NPC/minigame: spawns a "test" NPC with `CarrierTrait`, gives it a bread item, sets unprotected; scheduled task body is fully commented out. v1:415-444
17. `new` — economy/inventory/dev: broadcasts item-in-hand type, then gives every online player a chainmail-boots item. v1:445-456
18. `tut` — tutorial: force-creates the "Food" tutorial for the user. v1:457-461
19. `settut` — tutorial/dev: saves a new tutorial file entry "Menu" worth 50 (reward). v1:462-467
20. `duel` — arena/PvP: constructs and starts a `Duel` vs `args[1]` — **no bounds check on `args[1]`**, and no null-check on `Bukkit.getPlayer(args[1])` before passing into `Duel` constructor. v1:468-472
21. `letter` — dev/text utility: capitalizes first letter of `args[1]` — **no bounds check on `args[1]`** (AIOOBE risk). v1:473-478
22. `world` — dev: prints sender's X coordinate. v1:488-491
23. `format` — dev: prints `main.getHourtime/getRestMinutetime/getRestSecondtime` for `Integer.valueOf(args[1])` — **no bounds check, and unhandled `NumberFormatException` risk if args[1] isn't numeric.** v1:492-495
24. `purge` — housing: purges every room's owner via `room.purgeRoomOwner(roomID)`, messaging once per room — **destructive bulk operation gated only behind `k&k.test`, no confirmation.** v1:496-505
25. `gladiator` — NPC/minigame: spawns an NPC with `Gladiator` trait. v1:506-512
26. `zone` — **empty no-op stub.** v1:513-515
27. `bandits` — minigame (bandit-spawn system): clears `BanditSpawn.banditID`, removes stray "bandit"-named entities and orphaned bandit NPCs not in the active list. v1:516-539
28. `armor` — inventory/dev: scans inventory+armor slots for an iron chestplate, reports found/not-found. v1:540-574
29. `time` — dev: broadcasts `main.getTime()`. v1:575-580
30. `data` — dev: broadcasts item-in-hand's legacy `getData()` byte. v1:581-585
31. `bar` (2nd, duplicate name — see bug above) — dev/world cleanup: removes all Wither entities in world "world". v1:586-596
32. `hunger` — misc: sets sender's food level to 2. v1:597-600
33. `skills` — world-admin/economy toggle: flips `main.enableSkills` boolean server-wide, messages sender. v1:601-612
34. `file` — resources/dev: reports `YmlFile.getLastID(name)` for `args[1]` — **no bounds check on `args[1]`.** v1:613-618
35. `flags` — resources/economy: iterates all resource properties and calls `ResourceCommands.changeFlags` for each — bulk operation. v1:619-628
36. `more` — inventory: sets held item stack size to 64; separately re-checks `sender instanceof Player` even though outer scope guarantees it. v1:629-648
37. `item` — economy/inventory: shuffles product ID list, grants first item that passes `gradeChance`. v1:649-662
38. `address` — misc/dev: reports player's IP address string. v1:663-668
39. `npctest` — NPC/dev: elaborate NPC-spawn + random-wander scheduled task test (uses `scheduleSyncRepeatingTask`), also broadcasts to nearby players and console via `System.out.println`. v1:669-733

Non-player else-branch (runs when sender is NOT a `Player`, i.e., console with `k&k.test`):
40. `loop` (console/non-player variant, distinct implementation from #5) — dev: counts down from 10 to 0 inclusive, printing "- N" each iteration, then "End: " + last value. v1:741-755

=== CommandExceptions.java — NOT a command ===
File: src/Exceptions/CommandExceptions.java
- It is a plain utility/constants holder class (does NOT extend `Exception` despite the name) providing two static `String` message constants: `SenderNotPlayer` and `NoPermission`, built from `ColorOptions.falsecommand`. v1:5-9. Not itself registered anywhere as a command; presumably referenced by other command classes as canned error text (not observed being used in any of the 16 files read here — none of the reviewed classes reference `CommandExceptions.SenderNotPlayer`/`NoPermission`, they all inline their own error strings instead, suggesting this class may itself be effectively unused/legacy).

=== Registration note ===
`grep -n "FreezeCommands" src/Main/Main.java` returned no matches, and `grep -rn "FreezeCommands" src/` across the whole tree found only the class's own file plus its compiled `.class` binary — confirming FreezeCommands is entirely unwired dead code, not invoked programmatically from anywhere else either.

N distinct commands/subcommands found across afk/discord/heal/message/reply/page/ping/staffchat/freeze/weather/gamemode/fly/reload/tpa/spawn/tutorial/initiate/test: **63** (afk 1, discord 1, heal 1, message 1, reply 1, page 1, ping 3 [no-arg/1-arg/help], staffchat 1, freeze 1 [dead/no-op], weather 4 [rain/sun/allowchange/usage], gamemode 4 [creative/survival/spectator/toggle], fly 4 [enable-self/enable-other/disable-self/disable-other-collapsed as 2 forms i.e. counted as 2, toggle], reload 1, tpa 5 [staff-pair, staff-spawnpoint, staff-self-target, normal-request, accept/deny-stub], spawn 3 [self-owner/self-normal/target-other], tutorial 6 [start-self/start-other/info-self/info-other/list-self/list-other], initiate 1, test 40).
