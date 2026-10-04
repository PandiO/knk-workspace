# Plugin command completion sweep (KNG-30)

**Status:** Merged to knk-plugin `main` at `52ce855`, retained through backlog merge `1a69ec3`; live verification pending
**Last updated:** 2026-10-04

This report inventories every command declared in `knk-paper/src/main/resources/plugin.yml` and every
subcommand registered by `KnkAdminCommand`. Suggestions are prefix-filtered. Player suggestions use
the viewer-aware `VisiblePlayers` path (`Player.canSee`) unless the command intentionally completes a
stored list such as pending teleport requesters or ignored players. Commands without arguments have
an explicit empty completer, preventing Bukkit's default all-online-player fallback.

## Root commands

| Command | Argument suggestions |
|---|---|
| `/knk` | Permission-filtered registered subcommands; details below |
| `/account` | Permission-filtered `status`, `link` |
| `/ownermode`, `/staffmode` | `on`, `off`, `enable`, `disable`, `help`; then `onquit` |
| `/ce` | Permission-aware enchantment actions; enchantment ids/levels; viewer-visible players for `info` and `cooldown clear` |
| `/freeze`, `/unfreeze` | Viewer-visible online player names (the command still accepts an explicitly typed known/offline name) |
| `/staffchat`, `/reply`, `/menu`, `/discoveries`, `/siegemenu`, `/tpcancel`, `/warps`, `/back` | Explicitly no suggestions |
| `/msg` | Viewer-visible online players other than the sender |
| `/socialspy` | `on`, `off` |
| `/ignore` | Viewer-visible online players other than the sender |
| `/unignore` | Names in the sender's stored ignore list |
| `/kit` | Permission-scoped actions; viewer-visible player for `give`; cached kit names for `get`, `give`, `purchase`; management actions |
| `/pay` | Viewer-visible players plus `confirm`, `cancel`; `coins`, `gems` |
| `/balance` | Viewer-visible players |
| `/baltop` | `coins`, `gems` |
| `/transactions` | Viewer-visible players; `coins`, `gems`, `xp` |
| `/siege` | Permission-filtered player/admin actions; lobby/scenario names; active members visible to the sender |
| `/user`, `/stats` | `statistics`, `stats`; viewer-visible players |
| `/fly` | `on`/`off` variants and viewer-visible players |
| `/heal`, `/feed` | `all` and viewer-visible players |
| `/enderchest` | `open`, `check`; viewer-visible online players and cached offline account names |
| `/inventory` | `open`, `clear`; viewer-visible online players and cached offline account names; `confirm` |
| `/tp`, `/tphere` | Viewer-visible players; coordinates (`~`), worlds, `-s` |
| `/tpa`, `/tpahere` | Viewer-visible players; `accept`, `deny` |
| `/tpaccept`, `/tpdeny` | Pending requester names |
| `/spawn` | Viewer-visible players; `-s` |
| `/warp` | Cached destination names; viewer-visible staff targets; `list`, `-s` |
| `/lootbox` | Permission-filtered `help`, `odds`; configured categories |

## `/knk` subcommands

| Subcommand(s) | Argument suggestions |
|---|---|
| `help` | Commands available to the sender |
| `health`, `town`, `district`, `street`, `task-claim`, `task-status` | No enumerable argument set; explicitly no fallback player names |
| `cache` | `refresh`, `reload` |
| `clans` | `list`, `info`, `banner`, `design` |
| `towns`, `districts`, `streets` | `list` |
| `locations` | `list`; common page/size values |
| `location` | `here` |
| `item` | `rename`, `lore`, `enchantments`; lore operations; definition search fields/ids/keys/names/levels |
| `itemblueprints` (`itemblueprint`, `ib`) | `list`, `search`, `get`, `give`; search fields/page sizes; viewer-visible give target |
| `menu` | `open`, `page`, `search`, `filter`; `next`, `prev`, `clear` |
| `tasks` | `Pending`, `Claimed`, `InProgress`, `Completed`, `Failed` |
| `itemscan`, `kitscan` | `claim` |
| `gate` | Gate actions; pass-through modes; admin/door actions; opened/closed region slot |
| `user` | Viewer-visible players; `info`, balances, `history`, `group`, `perm`; action verbs and currency filters |
| `currency` | Existing permission-aware transaction/history/lock/alert suggestions |
| `tp` | Viewer-visible players; `-s` |
| `regions` | `repair` |
| `lootbox` | Permission-filtered actions; viewer-visible give/token target; categories, active ids, areas and fixed values |
| `discovery` | `list`, `reset`, `status`; viewer-visible player target |

## Verification

- `:knk-paper:compileJava` and `:knk-paper:compileTestJava`: pass.
- All command-package and enchantment-command tests: pass.
- Full non-deploy Gradle build and test suite passed again after the 2026-10-04 fast-forward merge.
  Live/smoke verification remains for the developer.
