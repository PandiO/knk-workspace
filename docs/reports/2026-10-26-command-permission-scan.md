# Command permission scan — knk-plugin (2026-10-26)

**Status:** Final scan; the fixes it led to are in review on `claude/alpha-run-1-permissions` (not merged, not deployed)
**Last updated:** 2026-10-26
**Issue:** [PandiO/knk-workspace#158](https://github.com/PandiO/knk-workspace/issues/158) (alpha test run 1, package C);
parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Previous scan:** [`specs/user-features/COMMAND_PERMISSION_SCAN.md`](../specs/user-features/COMMAND_PERMISSION_SCAN.md)
(2026-09-23, before the in-house permission system existed; superseded for v3 by this file)
**Scanned:** knk-plugin `main` `ee35fb1d`, knk-web-api `master` `6f08383`, the alpha's seed data
(`knk-dev-db-seed` `821bd2e`, `seed/knk_seed.sql`)

## 1. Method

- Every command in `knk-paper/src/main/resources/plugin.yml` (47 commands on `main`, 48 with the new `/gamemode`) and every `/knk` subcommand registered in
  `KnkAdminCommand` and `KnKPlugin.registerCommands` (29 subcommands).
- Every node a command checks: `CommandMetadata` nodes, `CommandNodes` (the KNG-107 list), the constants in the
  executors, and every `hasPermission(...)` call site — split into checks that go through the in-house permission
  model (`KnkPermissible`, `CommandPermissions`, `PlayerCommandSupport`, or a Bukkit-or-KnK predicate) and checks that
  go through **Bukkit only**.
- Rank seeds: the alpha's grants in the seed database (holder ids 1–9: user 1 the owner, 2 Noble, 3 Royal,
  4 Dragon Blood, 5 Default, 6 Moderator, 7 Admin, 8 Staff, 9 Alpha Tester) and the seed migrations in knk-web-api.

How a check reaches a rank matters more than whether a node exists: **the in-house permission system never reaches
Bukkit's permissions**. Nothing in the plugin adds a `PermissionAttachment`. So:

- a node checked through `KnkPermissible` works for ranks (grants, groups, wildcards) and for ops;
- a node checked with Bukkit's `hasPermission` only works for ops and for its `plugin.yml` default — a rank grant has
  no effect;
- every vanilla command (`/gamemode`, `/weather`, `/time`, `/give`, ...) needs its `minecraft.command.*` Bukkit node,
  which only ops hold. That is the "gamemode is op-only" finding.

## 2. Findings

| # | Finding | Severity | Done on the branch |
|---|---|---|---|
| F1 | `/gamemode` is vanilla: op only, no rank can be given it. | Issue's example | New KnK `/gamemode <mode> [player]` (alias `/gm`), nodes `knk.gamemode.<mode>` and `knk.gamemode.others` (`knk.gamemode.*` = all). Bare `/gamemode` now resolves to KnK (as `/tp`); vanilla stays reachable as `/minecraft:gamemode`. |
| F2 | `/knk item` (rename, lore, enchantment catalogue) was gated on the `knk.admin` umbrella itself, so only holders of `knk.admin`/`knk.admin.*` could use it. `/knk itemblueprints` (list, search, give) had a node but no rank held it except Admin through `knk.admin.*`. | "KnK items" | `/knk item` gets its own `knk.admin.item` (child of `knk.admin`). Both item nodes seeded for Staff. |
| F3 | Menu item `visibilityPermission`/`actionPermission` and the `permission-node` menu condition were Bukkit-only. The Player manager hub tile (`knk.admin.user.manage`) and its freeze buttons (`knk.freeze`/`knk.unfreeze`) were invisible or refused for non-op Staff although the Staff group holds those nodes. | Bug | `MenuPermissions`: Bukkit or in-house (cached answer). |
| F4 | The Player manager's own reads (`knk.admin.user.manage`, `.manage.all`) and its freeze action were Bukkit-only: non-op staff got an empty list. | Bug | In-house check added (`UserManagerMenuFeature.holds`). |
| F5 | Breaking gate blocks (`knk.gate.admin`, `GateEventListener`) and the InstantOpen pass-through (`knk.gate.passthrough.instant`) were Bukkit-only. | Bug | Both through `GatePassThroughRules`' check (Bukkit or in-house). |
| F6 | `customenchantments.<id>` (activating a SUPPORT enchantment: chaos, flash chaos, health boost, armor repair, resistance, invisibility) is Bukkit-only and undeclared, so as far as the code shows only ops can use support enchantments. The `/ce` subcommand nodes (`customenchantments.command.add`, `.remove`, `.reload`, `.info.others`, `.cooldown.clear(.others)`) are Bukkit-only too. | Bug, needs a decision | **Not fixed** — needs a gameplay decision (who may use support enchantments) and `/ce` is changed on package B's branch. **To file** as a sub-issue of #149 (creating it was refused in this session; see the #158 comment). |
| F7 | `knk.tasks` (`/knk tasks`, `task-claim`, `task-status`, `itemscan`, `kitscan`) is not covered by `knk.admin`/`knk.admin.*` and no rank held it: only ops could claim world, item and kit scan tasks. | Missing seed | Seeded for Staff. |
| F8 | Nodes no rank held: `knk.fly(.others)`, `knk.enderchest.open`, `knk.inventory.open/.clear`, `knk.hub.bypass`, `knk.siege.admin.join` (package A, unmerged). | Missing seed | Seeded (§ 4). |
| F9 | knk-web-api seeds none of the `knk.siege.*` nodes (the alpha has them only because the seed database was made by hand). | Missing seed | Back-filled where missing (§ 4). |
| F10 | `knk.account.create` and `knk.account.link` are declared but never checked (`/account link` checks `knk.account.use`); `knk.account.admin` is a placeholder with no code. | Leftover | Noted only. |
| F11 | Other vanilla commands staff may want (`/weather`, `/time`, `/give`, `/clear`, `/effect`, `/kick`, `/ban`, ...) stay op-only. | Gap | Noted only; a general bridge (grant `minecraft.command.*` through Bukkit permission attachments from the in-house set) would be a separate feature. |
| F12 | `GameSettingsWeatherCommandListener` checks `minecraft.command.weather` through Bukkit — correct, it reacts to the vanilla command. | OK | — |

## 3. Inventory

"Check" says how the node is checked: **KnK** = in-house model (ranks work), **Bukkit** = Bukkit only,
**plugin.yml** = Bukkit's `permission:` on the command. "Seed" = who holds it: alpha seed database (S) or a knk-web-api
seed (M), and the new migration `SeedCommandPermissionNodes` (C). "Open" = no node.

### 3.1 Player commands

| Command | Nodes | Check | Seed |
|---|---|---|---|
| `/account [link\|status]` (`/acc`) | `knk.account.use` | plugin.yml + Bukkit | `default: true`; Default (S) |
| `/menu` | `knk.menu` | plugin.yml | `default: true`; Default (S) |
| `/discoveries` (`/disc`) | `knk.discoveries` | plugin.yml | `default: true`; Default (S) |
| `/ce` | `customenchantments.command.use`, `.info` / `.add`, `.remove`, `.reload`, `.info.others`, `.cooldown.clear(.others)` | plugin.yml + **Bukkit** | use/info Default (S); others op only (F6) |
| `/msg`, `/reply`, `/ignore`, `/unignore` | open; `knk.msg.bypass.ratelimit`, `knk.msg.bypass.ignore`, `knk.msg.unignorable` | KnK / API | bypass nodes Staff (S) |
| `/socialspy` (`/spy`) | `knk.socialspy` (`.exempt`) | KnK | Staff (S); exempt: owner |
| `/kit list\|get\|give\|purchase\|manage` | `knk.kit.list`, `.get`, `.give`, `.purchase`, `.manage` | KnK | list/get/purchase Default (S); give/manage Staff (S) |
| `/pay`, `/balance` (`/bal`), `/baltop`, `/transactions` (`/tx`) | `knk.pay` (`.gems`, `.bypass`), `knk.balance(.others)`, `knk.baltop` (`.exempt`), `knk.transactions(.others)` | KnK | player nodes Default (M `SeedCurrencyPlayerNodes`); `.bypass`, `.exempt`, `.others` Staff (S); `.gems` nobody (by design) |
| `/siege ...`, `/siegemenu` (`/sgm`) | `knk.siege.play`, `.skip`, `.admin.list\|control\|reload\|manage`, `.bypass.commands`; `.admin.join` (package A) | KnK (`play` also Bukkit, `default: true`) | play Default (S, C); skip Noble (S, C); admin/bypass Staff (S, C); join Admin (C) |
| `/user statistics [player]` (`/u`), `/stats`, `/leaderboard` (`/lb`), `/afk` | open | — | — |
| `/navigate` (`/nav`) | `knk.navigate` | Bukkit or KnK | `default: true`; Default (S) |
| `/tpa`, `/tpahere`, `/tpaccept`, `/tpdeny`, `/tpcancel` | `knk.teleport.request`, `.request.here`; answering open | KnK | request Default (S); here Dragon Blood (S) |
| `/spawn`, `/warp` (`/point`), `/warps` | `knk.teleport.spawn`, `.warp`; `.staff.others` for another player | KnK | Default (S); others Staff (S) |
| `/back` | `knk.teleport.back`, `.back.warps\|teleport\|spawn\|all`; `.staff.back.others` | KnK | `back` Dragon Blood (S); the rest nobody |
| `/hub` | open; `/hub <player>` `knk.teleport.staff.others` | KnK | Staff (S) |
| `/lootbox` (`/lb`) | `knk.lootbox.odds`; opening boxes `knk.lootbox.open` | KnK | Default (M `LootboxSeed`) |
| `/gate`, `/gatedoor` | `knk.gate.open.*\|close.*\|admin`, `knk.gatedoor.*`, `knk.gate.passthrough.use\|instant` (per-id forms too); info/list/passthrough open | KnK (block break and instant: **were Bukkit**, F5) | nobody but ops (Admin's `knk.admin.*` doesn't cover `knk.gate.*`) |

### 3.2 Staff commands

| Command | Nodes | Check | Seed |
|---|---|---|---|
| `/ownermode` (`/om`), `/staffmode` (`/sm`) | `knk.mode.owner`, `knk.mode.staff` | KnK | staff: Staff (S); owner: owner user |
| `/freeze`, `/unfreeze` | `knk.freeze`, `knk.unfreeze` | KnK (menu buttons **were Bukkit**, F3/F4) | Staff (S) |
| `/staffchat` (`/sc`) | `knk.staffchat` | KnK | Staff (S) |
| `/fly [on\|off] [player]` | `knk.fly`, `.others` | KnK | **new:** Staff / Moderator (C) |
| `/heal`, `/feed` | `knk.heal(.others\|.all)`, `knk.feed(...)` | KnK | nobody (left for the developer) |
| `/enderchest` (`/ec`), `/inventory` (`/inv`, `/invsee`) | `knk.enderchest(.open)`, `knk.inventory.open\|clear` | KnK | **new:** open nodes Moderator, clear Admin (C) |
| `/tp`, `/tphere` | `knk.teleport.staff`, `.staff.others`, `.staff.silent`, `knk.admin.tp` | KnK | Staff (S) |
| **`/gamemode` (`/gm`) — new** | `knk.gamemode.survival\|creative\|adventure\|spectator\|others` | KnK | survival + spectator Staff, others Moderator, `knk.gamemode.*` Admin (C) |

### 3.3 `/knk` subcommands

No top-level gate; each subcommand checks its own node through `CommandPermissions` (KnK). `knk.admin` (plugin.yml
umbrella) and the in-house `knk.admin.*` (Admin, S) cover every `knk.admin.<x>`.

| Subcommand | Node | Seed besides Admin |
|---|---|---|
| `health`, `cache`, `clans`, `towns`, `town`, `districts`, `district`, `locations`, `menu`, `streets`, `street`, `regions` | `knk.admin.<name>` | — |
| `location here\|tp\|orphans` | `knk.admin.location`, `.location.tp`, `.location.orphans(...)` | tp/orphans Moderator (M `SeedLocationRetentionStaffGroups`) |
| `item` | was `knk.admin`; now **`knk.admin.item`** | **Staff (C)** |
| `itemblueprints` (`ib`) | `knk.admin.itemblueprints` | **Staff (C)** |
| `tasks`, `task-claim`, `task-status`, `itemscan`, `kitscan` | `knk.tasks` (not under `knk.admin`) | **Staff (C)**, Admin too |
| `gate`, `gatedoor` | see `/gate` | — |
| `user <player> ...` | `knk.admin.user.<info\|coins\|gems\|xp\|group\|perm\|history\|manage\|mode\|salary>`, `.manage.all` | Staff (S); `.manage.all` owner |
| `currency ...` | `knk.admin.currency.<history\|reverse\|lock\|alerts>` (+ `.policy`, `.unlimited` on the web/API) | Staff (S) |
| `tp` | `knk.admin.tp` | Staff (S) |
| `lootbox ...` | `knk.lootbox.admin.<spawn\|despawn\|list\|tp\|give\|token\|reload\|area>` | Staff (S) |
| `discovery` | `knk.admin.discovery` | Staff (S) |
| `road` | `knk.admin.road` | Staff (S) |
| `help` | open | — |

### 3.4 Non-command nodes touched by package C

| Node | What | Check | Seed |
|---|---|---|---|
| `knk.region.bypass` | domain entry/exit, global-region protection | KnK | Staff (S) |
| **`knk.region.bypass.containers` — new (#157)** | open storage where a region refuses it; staff mode and owner mode always pass | Bukkit or KnK | Moderator (C), Admin |
| **`knk.notify.joinattempt` — new (#159)** | chat notice for refused joins | Bukkit or KnK | Staff (C) |
| `knk.hub.bypass` | build and use in the hub | KnK | **Admin (C)** |

## 4. Rank seed migration

knk-web-api `Migrations/20261026160000_SeedCommandPermissionNodes.cs` (data only). Proposed defaults; the developer
should review them (all reversible: change the group's grants in the web app, or roll the migration back):

| Tier | New grants |
|---|---|
| Staff (→ also Moderator, Admin) | `knk.tasks`, `knk.admin.item`, `knk.admin.itemblueprints`, `knk.gamemode.survival`, `knk.gamemode.spectator`, `knk.fly`, `knk.notify.joinattempt` |
| Moderator (→ also Admin) | `knk.region.bypass.containers`, `knk.gamemode.others`, `knk.fly.others`, `knk.enderchest.open`, `knk.inventory.open` |
| Admin | `knk.gamemode.*`, `knk.siege.admin.join`, `knk.hub.bypass`, `knk.inventory.clear` |
| Back-fill (Down keeps them) | Default `knk.siege.play`; Noble `knk.siege.skip`; Staff `knk.siege.admin.list\|control\|reload\|manage`, `knk.siege.bypass.commands` |

A group is skipped when it is missing, or when it or a group in its parent chain already has a grant or deny for the
node, or a wildcard covering it. On the alpha seed (checked on MySQL 8.0 with `knk_seed.sql`) that gives 16 rows:
7 on Staff, 5 on Moderator, 4 on Admin (`knk.gamemode.*`, `knk.inventory.clear`, `knk.hub.bypass`,
`knk.siege.admin.join`; the other Admin nodes come through the chain or `knk.admin.*`); the back-fill adds nothing
there. A second run adds nothing; Down removes the 16.

## 5. Not done here

- F6 (custom enchantments, Bukkit-only and undeclared per-enchantment nodes) — to file as a sub-issue of #149.
- `/heal`, `/feed`, the `/back` kinds and the `knk.gate.*` nodes still have no rank; that's a game-design call, not a
  missing node.
- A general bridge from in-house grants to vanilla `minecraft.command.*` nodes (F11).
- `COMMAND_CATALOG_V3.md` and the 2026-09-23 scan in `specs/user-features/` describe the pre-rank state; they are not
  rewritten (the catalogue's `/gamemode` gap is closed by this branch).
