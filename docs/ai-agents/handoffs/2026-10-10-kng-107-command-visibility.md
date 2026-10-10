# Handoff: KNG-107 — hide `/knk` subcommands and tab completions the sender can't use

**Status:** Implemented 2026-10-10 on knk-plugin `claude/kng-107-command-visibility` `e329c4f` (base `main` `973aa68b`). Offline tests pass. **Not merged, no PR: waiting for the developer's live test** (checklist below; it needs a non-op account).
**Linear:** [KNG-107](https://linear.app/kngpandi/issue/KNG-107) (follow-up of KNG-80).
**Last updated:** 2026-10-10

---

## What changed

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
| `/knk gate`, `/knk gatedoor` (+ `/gate`, `/gatedoor`) | per action / per structure (`knk.gate.*`, `knk.gatedoor.*`) | **unchanged — out of scope** (see follow-ups) |
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

- **`./gradlew test`:**
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

## Decisions for review

1. **`/knk help <cmd>` for an unlisted subcommand** says "Unknown command" instead of showing the usage and node. Reversible in `HelpSubcommand.showCommandDetail`.
2. **`/knk help` itself is hidden** when nothing else is listed. Running `/knk` or `/knk help` still works and prints "No commands available."
3. **Background warm from tab completion.** Root `/knk` completion warms every listed node at most once per 20 s per player. The standalone `holds` checks ask a cache miss in the background. Cached "no" answers cost no API call. This keeps completion non-blocking while letting staff see their grants after one keystroke.
4. **`/tpa` keeps offering `accept`/`deny`** without the request node, because they need no node.
5. **`/warp` place names are not filtered by the lock state** (title/premium/discovery/cost). Only the warp node gates them, because the lock reason comes from an async check. Possible follow-up.

## Follow-ups / gaps found (not done here)

- **Gate commands (KNG-105/106 own them):**
  - `/knk gate` and `/knk gatedoor` have no top-level node and no visibility predicate, so they are still listed in `/knk help` and root completion to everyone.
  - `GateCommand.complete` / `GateDoorCommand.complete` suggest every action and structure regardless of the per-action nodes.
  - Fix after KNG-105/106 merges: wire `setSubcommandVisibility("gate", …, GateCommand.CHECKED_NODES)`. Careful: per-structure nodes such as `knk.gate.open.5` are not covered by `CHECKED_NODES`' wildcard strings. Also filter the completers.
- `/ignore` suggests staff holding `knk.msg.unignorable`, who can't be ignored. That is a target property, not a sender permission; left as is.
- `/account` uses a Bukkit-only registry (`knk.account.use` is default true); no in-house grants. Unchanged.
- `/knk tp` stays on `knk.admin.tp` only, while `/tp` also accepts `knk.teleport.staff`. Unchanged.

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

The developer live-tests with the checklist, then opens a PR from `claude/kng-107-command-visibility` and merges. After KNG-105/106 merges, do the gate follow-up above.
