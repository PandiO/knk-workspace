# Handoff: KNG-107 — hide `/knk` subcommands and tab completions the sender can't use

**Status:** Round 1 implemented 2026-10-10 (`e329c4f`) and live-tested by the developer 2026-10-11. Round 2 addresses that feedback: knk-plugin `claude/kng-107-command-visibility` `49ba0f2`, with `main` `0ee516a` merged in. Offline tests pass. **Not merged, no PR: waiting for the developer's live re-test** (round 2 checklist below; it needs a non-op account).
**Linear:** [KNG-107](https://linear.app/kngpandi/issue/KNG-107) (follow-up of KNG-80).
**Last updated:** 2026-10-11

---

## Round 2 (2026-10-11): live-test feedback

| Feedback | Change (plugin `49ba0f2`) |
|---|---|
| `/knk help` shows nothing for the commands a player may use | `/knk help` lists the plugin's other commands the sender may use: plugin.yml description, filtered by `CommandNodes` or plugin.yml `permission:`, and only the registered ones. `/knk help <command>` describes them (usage, aliases), and `/knk help <tab>` offers them. `/knk help` itself is always listed now, which reverses round-1 decision 2. |
| `/knk lootbox` and `/knk currency` show their usage to a player who can't use them (MrBedue) | A nodeless `/knk` subcommand with action nodes (user, currency, lootbox, discovery, road, location) answers "You don't have permission" to a sender holding none of them (`CommandRegistry.execute` → `CommandPermissions.whenAnyAllowed`, a real async check). The actions still check their own nodes. |
| `/inventory` shows a usage line for a form the player can't use | A new shared list, `commands/support/CommandNodes`, holds each standalone command whose forms all need a node, with those nodes. These commands are wrapped in `PermissionGatedCommand`, which now accepts several nodes (any one is enough): a sender holding none gets "no permission", not the usage. The `/inventory`, `/enderchest`, `/fly`, `/heal` and `/feed` usage texts list only the forms the sender holds. |
| Typing "/" shows commands the player has no permission for | `GatedCommandVisibilityListener` now accepts several nodes per command (any one is enough) and hides every `CommandNodes` command from players holding none. The list is re-sent once when the real answer differs from the cold-cache one. |
| Fix the gate commands too | `/gate` and `/gatedoor` (and `/knk gate…`): completion and the no-argument help offer `open`/`close`/`toggle` only to a sender who may control at least one gate or door, and the gate/door names only for the ones they control. The admin actions (`repair`, `tp`, `override`, `reload`; door `health`, `active`, `invincible`, `capture`, `redefine`) are offered only to admins. `info`, `list` and `passthrough` stay open to everyone, as they are at execution, so `/gate` stays in "/". Each loaded gate's `knk.gate.open/close.<id>` nodes are warmed for completion. |
| New commands on main? | Merged `main` `0ee516a`. KNG-34 added `/afk`, `/leaderboard` (`/lb`) and `/stats settings`; none needs a node, so they stay open (listed in `/knk help`, shown in "/"). No new `/knk` subcommands. |

`CommandNodes` (any one node lets the sender in):

- **Teleport**
  - `tp`: staff / `knk.admin.tp` / staff.others
  - `tphere`: staff.others
  - `tpahere`: request.here
  - `spawn`: spawn / staff.others
  - `warp`: warp / staff.others
  - `warps`: warp
  - `back`: the back nodes / staff.back.others
- **Currency**
  - `pay`: pay
  - `balance`: balance / .others
  - `baltop`: baltop
  - `transactions`: transactions / .others
- **Player tools**
  - `fly`: fly / .others
  - `heal`, `feed`: node / .others / .all
  - `enderchest`: enderchest / .open
  - `inventory`: open / clear
  - `socialspy`: socialspy
- **Modes**
  - `ownermode`: mode.owner
  - `staffmode`: mode.staff
- **Other**
  - `navigate`: navigate
  - `kit`: kit list/get/give/purchase/manage
  - `siegemenu`: siege.play
  - `freeze`, `unfreeze`, `staffchat`: their node

Open to everyone:
- messaging: `/msg`, `/reply`, `/ignore`, `/unignore`
- teleport requests: `/tpa` (accept/deny), `/tpaccept`, `/tpdeny`, `/tpcancel`
- stats: `/user`, `/stats`, `/leaderboard`, `/afk`
- commands with an open help form: `/siege`, `/lootbox`
- gates: `/gate`, `/gatedoor`
- `/knk`

`/account`, `/menu`, `/discoveries` and `/ce` keep their plugin.yml `permission:`, which Bukkit checks.

## Round 1 (2026-10-10): what changed

Help listings and tab completion now offer only what the sender can run. Every check reads the **cached** permission answer and never waits on knk-web-api. Execution checks are unchanged: `whenAllowed` and the per-action checks still decide.

### `/knk` (root, help, arguments)

- **`CommandRegistry.isListed(sender, cmd)`** checks the metadata node and the visibility predicate. It is now the single test for:
  - `/knk help`
  - `/knk help <cmd>` (an unlisted subcommand reads as "Unknown command")
  - root completion
  - argument completion (nothing is suggested past an unlisted subcommand)
- **`setVisibleToAny(name, nodes)`** and **`setVisibility(name, predicate, nodes)`**: a nodeless subcommand is listed only to holders of one of its action nodes. Those nodes are added to `permissionNodes()`, so `/knk` and `/knk help` warm them before listing.
- **Wired:**
  - `user`, `currency` (in `KnkAdminCommand`)
  - `lootbox` (`LootboxAdminCommand::visibleTo`), `discovery`, `road`, `location` (in `KnKPlugin`)
  - `help` is listed only when some other subcommand is.
- **Per-action completion:**
  - `currency`: `CurrencyAdminCommand.complete` gets a cached `holds`.
  - `lootbox`: `tabComplete` returns no arguments for an action the sender can't run.
  - `user`: `UserManagementCommand.propertiesHeld`. `info` is offered if any property node is held.
- **Background warm:** root completion warms the listed nodes, at most every 20 s per player (the permission cache TTL is 30 s). A cold cache is correct from the next keystroke on.

### Standalone commands

Completion is gated through one of three new cached checks. Each asks the API in the background on a "no":
- `PlayerCommandSupport.holds/holdsAny`
- `PlayerCurrencyService.holds` (with `setCachedPermissions`)
- `CommandPermissions.hasForCompletion`

## Inventory (node each action or argument needs → completion now)

| Command | Action / argument → node | Completion after KNG-107 |
|---|---|---|
| `/knk help` | none | listed only if another subcommand is listed |
| `/knk health, cache, clans, towns, town, districts, district, locations, item (knk.admin), itemblueprints, menu, streets, street, tasks/task-claim/itemscan/kitscan/task-status (knk.tasks), tp (knk.admin.tp), regions` | one metadata node each | unchanged (already gated on the node), now also nothing past an unlisted one |
| `/knk location` | here `knk.admin.location`, tp `.tp`, orphans `.orphans` | already per action (KNG-80); nodes now warmed |
| `/knk user` | `knk.admin.user.{coins,gems,xp,group,perm,history}`; info = any | hidden without any; only held properties; no player names/args otherwise |
| `/knk currency` | reverse `knk.admin.currency.reverse`, history `.history`, lock/unlock `.lock`, alerts `.alerts` | hidden without any; only held actions; no names for others |
| `/knk lootbox` | `knk.lootbox.admin.<spawn,despawn,list,tp,give,token,reload,area>` | hidden without any; only held actions; no args for others |
| `/knk discovery` | `knk.admin.discovery` | hidden without it (was listed to everyone; player names leaked) |
| `/knk road` | `knk.admin.road` | hidden without it (completion was already gated) |
| `/knk gate`, `/knk gatedoor` (+ `/gate`, `/gatedoor`) | open/close/toggle `knk.gate.<action>.<id>` / `.*` / `knk.gate.admin` (door: `knk.gatedoor.…` or the gate's); repair/tp/override/reload (door: repair/tp/health/active/invincible/capture/redefine) admin; info/list/passthrough none | round 2: control actions and names only for gates/doors the sender controls; admin actions only for admins; info/list/passthrough open |
| `/tp` | `<player>` `knk.teleport.staff` or `knk.admin.tp`; `<a> <b>` `.staff.others`; coords `.staff`; `-s` `.staff.silent` | names only with staff/others; 2nd player only with others; coords only with staff; `-s` only with silent |
| `/tphere` | `knk.teleport.staff.others`; `-s` `.staff.silent` | nothing without others |
| `/tpa` | `<player>` `knk.teleport.request`; accept/deny none | names only with the node; accept/deny always |
| `/tpahere` | `knk.teleport.request.here` | nothing without it |
| `/tpaccept`, `/tpdeny`, `/tpcancel` | none | unchanged |
| `/spawn` | self `knk.teleport.spawn`; `<player>` `.staff.others`; `-s` `.staff.silent` | names only with others; `-s` only with silent |
| `/back` | self `knk.teleport.back*`; `<player>` `knk.teleport.staff.back.others`; `-s` `.staff.silent` | names only with back.others; `-s` only with silent |
| `/warp` | `knk.teleport.warp`; `<place> <player>` `.staff.others`; `-s` `.staff.silent` | nothing without warp/others; names only with others; `-s` only with silent |
| `/pay` | `knk.pay`; gems `knk.pay.gems` | nothing without pay; `gems` only with pay.gems |
| `/balance` | self `knk.balance`; `<player>` `knk.balance.others` | names only with others |
| `/baltop` | `knk.baltop` | coins/gems only with it |
| `/transactions` | self `knk.transactions`; `<player>` `.others` | filters with own; names only with others |
| `/fly` | `knk.fly`; `<player>` `knk.fly.others` | on/off with either; names only with others |
| `/heal`, `/feed` | `knk.heal`/`.others`/`.all` (same for feed) | names with .others; `all` with .all |
| `/enderchest` | self `knk.enderchest`; open/check `<player>` `knk.enderchest.open` | nothing without .open |
| `/inventory` | open `knk.inventory.open`; clear `knk.inventory.clear` | only held actions and their args |
| `/socialspy` | `knk.socialspy` | on/off only with it |
| `/ownermode`, `/staffmode` | `knk.mode.owner` / `knk.mode.staff` | nothing without the mode's node |
| `/siege` | play `knk.siege.play`, skip `.skip`, admin `.admin.{list,control,reload,manage}` | arg 1 was gated; args after join/info/vote/skip/admin start…kick now gated too |
| `/lootbox` | odds `knk.lootbox.odds` | arg 1 was gated; odds categories now gated too |
| `/kit` | `knk.kit.{list,get,give,purchase,manage}` | already gated (unchanged) |
| `/navigate` | `knk.navigate` | already gated (unchanged; KNG-110 owns it) |
| `/freeze`, `/unfreeze`, `/staffchat` | `knk.freeze`, `knk.unfreeze`, `knk.staffchat` | already gated by `PermissionGatedCommand` |
| `/account` | `knk.account.use` (Bukkit, default true) | already gated (Bukkit-only registry) |
| `/msg`, `/reply`, `/ignore`, `/unignore`, `/user`, `/stats`, `/menu`, `/discoveries` | none / plugin.yml default-true | unchanged |

## Tests

- **Round 2:** `./gradlew test` passes 3926 tests with 0 failures and 20 skipped; on `main` `0ee516a` it is 3892 / 0 / 20. `./gradlew build -x deployToDevServer` succeeds. New tests:
  - `GateCommandTest`: completion and help without nodes, with one gate's node, as admin
  - `CommandPermissionsTest`: the any-of gate, including the API-unreachable case
  - `GatedCommandVisibilityListenerTest`: an any-of command in "/"
  - `CommandRegistryPermissionsTest`:
    - a nodeless subcommand refuses a sender holding none of its nodes instead of showing its usage
    - help lists the other commands
  - `CommandNodesTest`: every gated command exists in plugin.yml, and the open commands are not gated
- **Round 1 `./gradlew test`:**
  - Branch: 3496 tests, 0 failures, 20 skipped (by tag).
  - `main` `973aa68b`: 3472 tests, 0 failures, 20 skipped.
  - No pre-existing failures. The branch adds 24 tests.
- **`./gradlew build -x deployToDevServer`:** succeeds.
- **New tests**, each checking that no nodes give no suggestions and one node gives only its action:
  - `CommandRegistryPermissionsTest`: visibility, warmed nodes, help listed only with something else, help detail of an unlisted command, console sees all
  - `CurrencyAdminCommandTest`
  - `LootboxAdminCommandTest`
  - `UserManagementCommandTest`
  - `StaffTeleportCommandTest`
  - `SpawnCommandTest`
  - `WarpCommandTest`
  - `PlayerUtilityCommandsTest`
  - new `CompletionPermissionsTest`: mode, pay/balance/baltop/transactions, socialspy, tpa/tpahere, back
  - `CommandPermissionsTest`
- **Changed assertions:** five existing completion tests (lootbox admin, player utilities, spawn, two warp) assumed unfiltered suggestions; one asserted the leak itself (lootbox spawn categories with only the `list` node). They now grant the node or expect nothing. No test was skipped or disabled.

## Live checklist (needs a **non-op** account — ops pass every check)

1. Deploy the plugin from `claude/kng-107-command-visibility` (`./gradlew :knk-paper:dev`) and restart.
2. **Player with no admin nodes** (Default group only, not op):
   - `/knk ` + Tab → no subcommands.
   - `/knk help` → "No commands available." (not a list).
   - `/knk help currency` → "Unknown command".
   - `/knk currency ` + Tab, `/knk lootbox ` + Tab, `/knk user Steve ` + Tab → nothing.
   - Running `/knk currency history Steve` is still refused with the no-permission message.
3. Same player, standalone commands:
   - `/tp `, `/tphere `, `/spawn `, `/back `, `/fly <state> `, `/heal `, `/enderchest `, `/inventory `, `/socialspy `, `/staffmode ` + Tab → no player names, no `-s`, no `all`/`open`/`clear`/`on`.
   - `/balance ` + Tab → no names, unless the group holds `knk.balance.others`.
   - `/pay ` + Tab → names if the Default group holds `knk.pay`; `/pay Bob 5 ` + Tab → `coins` only, unless `knk.pay.gems`.
   - `/tpa ` + Tab → names if the group holds `knk.teleport.request`.
   - `/warp ` + Tab → places if the group holds `knk.teleport.warp`, and no player names after a place.
4. **Staff with exactly one node.** Grant `/knk user <staff> perm grant knk.admin.currency.lock`, then:
   - `/knk ` + Tab shows `currency`.
   - `/knk currency ` + Tab → `lock`, `unlock` only.
   - `/knk help` lists currency.
   - Repeat with `knk.lootbox.admin.give` → `/knk lootbox ` + Tab → `give` only.
   - Repeat with `knk.admin.user.coins` → `/knk user Steve ` + Tab → `info`, `coins`.
   - Repeat with `knk.teleport.staff` → `/tp ` + Tab shows names, `/tp Steve ` + Tab shows no second name and no `-s`.
5. **Cold cache:** right after a grant (or join), the first Tab may still show the old answer. The next Tab, about a second later, should be correct. Report it if it takes longer.
6. **Op account:** everything still offered; all commands still run as before.


### Round 2 re-test (same non-op player; then staff with one node)

1. Deploy `49ba0f2` (`./gradlew :knk-paper:dev`) and restart.
2. **"/" list:** type `/` as a player with no staff nodes. `/tp`, `/tphere`, `/inventory`, `/enderchest`, `/fly`, `/heal`, `/feed`, `/socialspy`, `/staffmode`, `/ownermode`, `/freeze`, `/staffchat` are absent. `/msg`, `/spawn` (if Default holds `knk.teleport.spawn`), `/gate`, `/knk`, `/afk`, `/leaderboard` are present. After a grant the list may update a moment later, or on relog.
3. **`/knk help`:** shows the usable commands (`/msg`, `/spawn`, `/pay`, …, `/gate`) with descriptions, and no admin `/knk` subcommands. `/knk help spawn` shows its usage. `/knk help inventory` says "Unknown command".
4. **No usage without permission:** `/knk currency`, `/knk lootbox`, `/inventory`, `/enderchest open Steve`, `/tp Steve` all answer "You don't have permission…", not a usage line.
5. **Partial node:** grant `knk.inventory.clear` only. Then:
   - `/inventory` shows `Usage: /inventory clear <player> confirm` only.
   - `/inventory ` + Tab offers `clear` only.
   - `/inventory` appears in "/".
6. **Gates:**
   - As the player: `/gate ` + Tab offers `info`, `list`, `passthrough`, `help` only, and `/gate` (no args) shows no open/repair/reload lines.
   - Grant `knk.gate.open.<id>` for one gate: `/gate ` + Tab adds `open`/`close`/`toggle`, and `/gate open ` + Tab offers only that gate's id/name.
   - With `knk.gate.admin`: everything.
   - Same checks for `/gatedoor`.
7. **Op:** everything as before.
## Decisions for review

1. Open. `/knk help <cmd>` for an unlisted `/knk` subcommand says "Unknown command". `/knk help <other command>` does the same for a command the sender may not use.
2. Superseded in round 2. `/knk help` is always listed and now lists the other usable commands as well.
3. Accepted by the developer 2026-10-11. Background permission warm-up from tab completion.
4. Accepted by the developer 2026-10-11. `/tpa` keeps offering accept/deny without the request node.
5. Open. `/warp` place names are not filtered by lock state.
6. New, open. `/gate` and `/gatedoor` stay visible to everyone because `info`, `list` and `passthrough` need no node at execution. Hiding them would mean gating those actions too.
7. New, open. `/knk help` lists the other commands before the `/knk` subcommands. Shortcuts that duplicate a `/knk` subcommand (`/gate`, `/gatedoor`) are listed in both places.
8. New, open. A grant made mid-session updates the "/" list the next time the server re-sends it: on relog, on a world change, or once after the first send. That is the KNG-24 listener behavior.

## Follow-ups / gaps found (not done here)

- Gate commands: done in round 2.
- `/ignore` suggests staff holding `knk.msg.unignorable`, who can't be ignored. That is a target property, not a sender permission; left as is.
- `/account` uses a Bukkit-only registry (`knk.account.use`, default true), so no in-house grants. Unchanged.
- `/knk tp` stays on `knk.admin.tp` only, while `/tp` also accepts `knk.teleport.staff`. Unchanged.
- `/knk currency` and `/knk lootbox` still show their full usage to a sender holding only some of their actions. Their usage texts are not filtered per action.

## Files outside the original claim (kept minimal)

- `currency/PlayerCurrencyService.java`: `setCachedPermissions` + `holds`.
- `commands/support/PlayerCommandSupport.java`: `holds`, `holdsAny`, `completeWords`.
- `commands/support/CommandPermissions.java`: `hasForCompletion`.
- `locations/LocationAdminCommand.java`: a `NODES` constant.
- `KnKPlugin.java`: 5 short wiring edits:
  - lootbox / discovery / road / location visibility
  - the currency cached check
  - `ModeCommand`'s check
- Not touched:
  - KNG-110 roads/navigation internals (`RoadAdminCommand` itself is unchanged)
  - KNG-58 `ModeService` / `KnkPermissible`
  - KNG-34 `UserCommand`
  - gate commands

## Next step

The developer re-tests with the round 2 checklist, then opens a PR from `claude/kng-107-command-visibility` (plugin) and the workspace branch, and merges.
