# Role responsibilities and permission matrix — owner, Head Admin, Admin, Moderator, Staff, area ranks, players

**Status:** Proposed. This is a design for the developer's review, with no code yet. The developer's decisions of
2026-11-13 to 2026-11-15 are in § 9. Implementation follows this design straight away (developer 2026-11-13). The
links are in § 8: [#547](https://github.com/PandiO/knk-workspace/issues/547) to [#551](https://github.com/PandiO/knk-workspace/issues/551), sub-issues of #387.
**Last updated:** 2026-11-15 (first version, design session for #387)
**Issue:** [PandiO/knk-workspace#387](https://github.com/PandiO/knk-workspace/issues/387) (with the developer's node-tree
comment of 2026-11-13).
**Reworks:** the Staff freeze seed [#367](https://github.com/PandiO/knk-workspace/issues/367) (accepted without a live
test), and the dashboard rules of [#371](https://github.com/PandiO/knk-workspace/issues/371),
[#374](https://github.com/PandiO/knk-workspace/issues/374) and [#383](https://github.com/PandiO/knk-workspace/issues/383).
Those rules use `knk.admin.content` as a "may change the game core" switch for every area.
**Builds on:** [dashboard access model](../dashboard-access-model/DESIGN.md) (#280: registry, read gating, lookups,
bulk delete, export, escalation guard). This design keeps that model's mechanics and replaces its **node names and the
create/edit rule**. Model A's global `knk.admin.delete` / `knk.admin.export` give way to per-topic nodes (§ 9, D3).
**Related:** Head Admin [#351](https://github.com/PandiO/knk-workspace/issues/351), sudo mode
[#348](https://github.com/PandiO/knk-workspace/issues/348), trash [#349](https://github.com/PandiO/knk-workspace/issues/349),
owner notifications [#350](https://github.com/PandiO/knk-workspace/issues/350), group node editor
[#50](https://github.com/PandiO/knk-workspace/issues/50), admin guide
[dashboard access admin guide](../../guides/admin/dashboard-access-admin-guide.md) (#366/#385), the
[2026-10-26 command permission scan](../../reports/2026-10-26-command-permission-scan.md).
**Code basis (read only, `next`):** knk-web-api `c20899c`, knk-web-app `1f848f7`, knk-plugin `745fcf6`.

## 0. In one paragraph

Every staff right becomes a node in one of four admin trees:

- `knk.admin.content` covers what exists in the game: items, reference data, kits, lootboxes, menus and forms.
- `knk.admin.world` covers what is placed in the world: domains, gates, locations, roads and world tasks.
- `knk.admin.minigame` covers each minigame's setup, starting with siege.
- `knk.admin.user` covers players: moderation, balances, freeze, groups and grants.

Each topic in a tree has the same four rights:

| Node | Right |
|---|---|
| `<topic>` | view |
| `<topic>.edit` | create, edit and change links |
| `<topic>.delete` | delete one record |
| `<topic>.export` | export |

`<topic>.*` gives all four, and `knk.admin.<area>.*` gives a whole area. Bulk delete keeps one global node,
`knk.admin.delete.bulk`, which only the owner (later the Head Admin) hands out.

Each role then has one job:

- **Staff** helps players and enforces the rules. It can view the game core but doesn't change it.
- **Area ranks** manage one area or topic.
- **Admin** manages everything except the owner's levers.
- **The owner**, and later the Head Admin, holds bulk delete, Admin-group edits and the owner tools.

One data migration in one release moves every existing grant to the new names, keeping what each rank can do today.

## 1. Roles and responsibilities

| Role | Responsible for | Not responsible for | Group (alpha) |
|---|---|---|---|
| **Owner** | Everything; the last word on ranks; owner tools (telemetry, privacy requests, analytics, leaderboard management); bulk delete and who may hand it out; the Admin group and its members | — | user 1, `*` |
| **Head Admin** (planned, #351) | What the owner delegates: hands out bulk delete, edits the Admin group and its members, grants `knk.admin.*` | owner tools (`knk.owner.*` stays exact-grant owner only) | not built; the owner holds these rights until #351 |
| **Admin** | Running the game: all content, world and minigame setup, game settings, economy policy, invitations, Moderator/Staff/area ranks, deleting players | bulk delete grants, the Admin group itself, owner tools | `Admin` (100), `knk.admin.*` |
| **Moderator** | Staff's job with stronger tools: other players' inventories and ender chests, `/fly` and `/gamemode` for others, container bypass, mass teleports, orphaned-location triage, statistics | the game core, ranks above Staff | `Moderator` (50), inherits Staff |
| **Staff** | Helping players and enforcing the rules: answering questions, finding players, freezing, (future) kicking and banning, correcting balances, giving kits, lootbox tokens and items to players, staff chat and social spy, running live siege matches | creating, editing or deleting game content, world data or minigame setup; deleting players; ranks | `Staff`, below Moderator |
| **Area rank** (any group made for a job: builders, content, kit, lootbox, road, minigame managers) | One area or topic of the game core: view, create, edit, delete and export there | other areas, players, ranks, bulk delete | groups made by Admin; § 3 recipes |
| **Player** (Default, Alpha Tester, premium ranks) | Playing | anything under `knk.admin` | `Default`, `Alpha Tester`, `Noble`/`Royal`/`Dragon Blood` |

A person can hold several roles, for example Staff plus a content rank. Rights add up through group membership and the
group parent chain, as today.

## 2. The node tree

### 2.1 Shape and matching

The rights of every topic in an area tree (`knk.admin.content`, `knk.admin.world`, `knk.admin.minigame`):

| Node | Right | Typical holder |
|---|---|---|
| `knk.admin.<area>.<topic>` | **view**: dashboard lists, details and the topic's admin page (read-only) | Staff for kits and siege, consumers of a topic |
| `knk.admin.<area>.<topic>.edit` | **create, edit, change links** (dashboard New/Edit, form wizard, detail Select/Unlink/Add, hot edit, topic page writes, in-game commands that change the topic) | area rank |
| `knk.admin.<area>.<topic>.delete` | **delete one** record | area rank |
| `knk.admin.<area>.<topic>.export` | **export** rows | area rank |
| `knk.admin.<area>.<topic>.*` | all of the above for one topic | one-topic rank (kit manager, road manager) |
| `knk.admin.<area>.*` | every topic of an area | content manager, builder |
| `knk.admin.delete.bulk` | **bulk delete**, on top of the type's `.delete`; owner-granted only (unchanged guard rule) | owner, Admin |

How these nodes match follows from today's resolver (`PermissionResolutionService.TryMatch`, mirrored by the plugin's
`EffectivePermissionResolver`). Nothing in the resolver changes:

- A bare node is not a wildcard. `knk.admin.content.kit` (view) does **not** match `knk.admin.content.kit.edit`.
- A trailing `*` matches the bare node and every child. `knk.admin.content.kit.*` = view + edit + delete + export.
- `knk.admin.*` (Admin) and `*` (owner) cover every node, including `knk.admin.delete.bulk`. The guard keeps covering
  wildcards owner-only to hand out (dashboard access model § 4.4).
- `.edit`, `.delete` and `.export` each count as view too: the API's read nodes for a topic list all four, so a rank
  given only `.edit` can still open what it edits. Grant `<topic>.*` or `<topic>` + its write nodes in practice.

**Rule for in-game commands:** a command that changes a topic checks the topic's `.edit`. A command that only shows it
checks the view node. Player-help actions (giving a kit, a lootbox token or an item blueprint to a player; freezing;
balances) keep their own node outside the topic. Staff holds those.

### 2.2 Topics

The topics are feature topics, about a dozen (§ 9, D10). Every dashboard type belongs to exactly one topic in the
`DashboardAccess` registry; its view-only link rows go with it.

| Node | Dashboard types and pages | In game | Old node |
|---|---|---|---|
| `knk.admin.content.items` | ItemBlueprint, EnchantmentDefinition, Grade, Category, Tag, AbilityDefinition and their link rows (CategoryTag, ItemBlueprintTag, ItemBlueprintOrigin, ItemBlueprintDefaultEnchantment) | `/knk item` (rename/lore/enchant the held item): `.edit` | `knk.admin.content`; `/knk item`: `knk.admin.item` |
| `knk.admin.content.reference` | MinecraftBlockRef, MinecraftMaterialRef, MinecraftEnchantmentRef, TitleBracket; **Minecraft catalogue** page | — | `knk.admin.content` |
| `knk.admin.content.clans` | Clan, BannerDesign, BannerLayer | `/knk clans`: view | `knk.admin.content`; `knk.admin.clans` |
| `knk.admin.content.kit` | Kit, KitContent | `/kit manage` (a pointer to the web app): `.edit` | `knk.kit.manage` |
| `knk.admin.content.lootbox` | LootboxType, LootboxSpecialEntry, LootboxSpawnArea and their rows; **Lootboxes** page (Types tab Enable/Disable = `.edit`) | `/knk lootbox spawn\|despawn\|area\|reload`: `.edit`; `list\|tp`: view | `knk.admin.lootbox.manage`; `knk.lootbox.admin.<action>` |
| `knk.admin.content.menu` | MenuTemplates (no dashboard type yet; menu template editor #319) | `/knk menu`: view | `knk.admin.content`; `knk.admin.menu` |
| `knk.admin.content.forms` | FormConfiguration, FormStep, FormField, FieldValidationRule, DisplayConfiguration/Section/Field, EntityTypeConfiguration; **Entity setup**, form and display builders | — | `knk.admin.content` |
| `knk.admin.world.domain` | Domain, Town, District, Structure, Street, DomainSubRegion; **Domain discovery** page | `/knk towns\|town\|districts\|district\|streets\|street\|regions`: view | `knk.admin.world`; `knk.admin.discovery`; `knk.admin.<name>` |
| `knk.admin.world.gate` | GateStructure, GateDoor, gate snapshots | `/gate`, `/gatedoor` admin and gate block breaking: `.edit` | `knk.admin.world`; `knk.gate.admin`, `knk.gatedoor.admin` |
| `knk.admin.world.location` | Location; **Orphaned Locations** page; retention settings | `/knk location`, `/knk locations` | `knk.admin.world`; `knk.admin.location.*` (§ 2.3) |
| `knk.admin.world.road` | RoadProfile, RoadSeeds, RoadNodes, NavigationSettings; **Road network** page | `/knk road show\|hide\|status\|why\|goto\|profile list\|show`: view; every other `/knk road` subcommand: `.edit` | `knk.admin.road` |
| `knk.admin.world.task` | WorldTasks, Workflows | `/knk tasks` and the scan commands stay `knk.tasks` (player-help-like work assignment; § 2.4) | `knk.admin.world` |
| `knk.admin.minigame.siege` | SiegeScenario, SiegeTeam, SiegeLobby, SiegeObjective, SiegeSpawnpoint and their rows; **Siege settings** page (`.edit` to save) | `/siege admin manage` (a pointer): `.edit`; match control § 2.4 | `knk.siege.admin.manage` |

**Players tree (`knk.admin.user`).** It keeps its existing fine nodes. Only the freeze nodes move into it, and the
dashboard actions get their own nodes:

| Node | Right | Old node |
|---|---|---|
| `knk.admin.user.manage` | view players: moderation list, player profile, User type on the dashboard (unchanged) | — |
| `knk.admin.user.coins`, `.gems`, `.xp`, `.salary`, `.history`, `.info`, `.mode` | balances and player info (unchanged) | — |
| `knk.admin.user.freeze`, `knk.admin.user.unfreeze` | freeze / unfreeze: web profile, `/freeze`, `/unfreeze`, Player manager menu buttons (§ 9, D8: two nodes) | `knk.freeze`, `knk.unfreeze` |
| `knk.admin.user.kick`, `knk.admin.user.ban` | **reserved**: KnK `/kick`, `/ban` don't exist yet (§ 6, G13) | — |
| `knk.admin.user.group`, `.group.premium`, `.perm` | memberships, grants, Permission Group writes (unchanged; escalation guard) | — |
| `knk.admin.user.delete` | delete one player account (dashboard, `DELETE api/Users/{id}`) | `knk.admin.user.manage` + `knk.admin.delete` |
| `knk.admin.user.perm.delete` | delete a permission group | `knk.admin.user.perm` + `knk.admin.delete` |
| `knk.admin.user.export` | export players and groups | area node + `knk.admin.export` |
| `knk.admin.user.manage.all` | the in-game Player manager's full list (unchanged, owner) | — |

There is no bulk delete for users or groups (dashboard access model decision 6, unchanged).

### 2.3 Nodes that move without a new meaning

| Old | New | Note |
|---|---|---|
| `knk.admin.location.orphans` (`.notify`, `.keep`, `.delete`, `.run`), `.retention`, `.tp` | `knk.admin.world.location.orphans` (`.notify`, `.keep`, `.delete`, `.run`), `knk.admin.world.location.retention`, `knk.admin.world.location.tp` | Moderator keeps view/keep/tp/notify; Admin the rest. No clash with the Location type's `knk.admin.world.location.delete` (a dashboard delete of one Location) |
| `knk.admin.discovery` | `knk.admin.world.domain` (view the page) / `.edit` (change discovery settings) | the page's `ExtraReadNodes` entry for Domain goes |
| `knk.siege.admin.list`, `.control`, `.reload`, `.join` | `knk.admin.minigame.siege.list`, `.control`, `.reload`, `.join` | match control lives under the minigame's topic; `knk.admin.minigame.siege.*` = setup + control |
| `knk.lootbox.admin.give`, `.token` | unchanged | player help (Staff) |
| `knk.kit.give`, `knk.admin.itemblueprints` | unchanged | player help (Staff) |
| `knk.siege.play`, `.skip`, `.bypass.commands` | unchanged | player / staff-mode nodes, not setup |

### 2.4 Nodes that stay outside the trees

Player nodes (`knk.teleport.*`, `knk.pay`, `knk.kit.list|get|purchase`, `knk.lootbox.open|odds`, `knk.chat.*`, …),
staff tools that act on players rather than the game core (`knk.mode.staff`, `knk.staffchat`, `knk.socialspy`,
`knk.teleport.staff*`, `knk.admin.tp`, `knk.fly*`, `knk.gamemode.*`, `knk.inventory.*`, `knk.enderchest.*`,
`knk.region.bypass*`, `knk.notify.joinattempt`, `knk.tasks`), server operation (`knk.admin.config`,
`knk.admin.invites`, `knk.admin.currency.*`, `knk.admin.statistics.view`, `knk.admin.privacy.request`,
`knk.admin.health`, `knk.admin.cache`, `knk.admin.npc`, `knk.admin.regions`) and owner nodes (`knk.owner.*`, exact
grant only). This design does not rename them.

## 3. Permission matrix

### 3.1 Nodes per role (target state)

"inh." = through the parent chain. The alpha chain is Staff → Moderator → Admin.

| Role | Nodes |
|---|---|
| Owner | `*` (plus exact `knk.owner.*` nodes) |
| Head Admin (planned) | Admin's nodes, and the rights of § 1 once #351 moves them from owner-only to the Head Admin group |
| Admin | `knk.admin.*`; `knk.gamemode.*`, `knk.hub.bypass`, `knk.inventory.clear` (as seeded today) |
| Moderator | inh. Staff; `knk.admin.world.location.orphans(.notify\|.keep)`, `knk.admin.world.location.tp`, `knk.admin.statistics.view`, `knk.gamemode.others`, `knk.fly.others`, `knk.inventory.open`, `knk.enderchest.open`, `knk.region.bypass.containers`, `knk.teleport.all.*` (as seeded today, renamed) |
| Staff | **players:** `knk.admin.user.manage`, `.info`, `.history`, `.coins`, `.gems`, `.xp`, `.freeze`, `.unfreeze` (later `.kick`, `.ban`), `knk.admin.currency.history\|reverse\|lock\|alerts`; **game core, view only:** `knk.admin.content.kit`, `knk.admin.minigame.siege`; **live matches:** `knk.admin.minigame.siege.list`, `.control`; **player help:** `knk.kit.give`, `knk.lootbox.admin.give`, `knk.lootbox.admin.token`, `knk.admin.itemblueprints`, `knk.tasks`; **staff tools:** `knk.mode.staff`, `knk.staffchat`, `knk.socialspy`, `knk.teleport.staff*`, `knk.admin.tp`, `knk.fly`, `knk.gamemode.survival\|spectator`, `knk.region.bypass`, `knk.notify.joinattempt`, `knk.msg.bypass.*`, `knk.chat.tokens.bypass` |
| Builder (world rank) | `knk.admin.world.*` |
| Content manager | `knk.admin.content.*` |
| Kit manager | `knk.admin.content.kit.*` |
| Lootbox manager | `knk.admin.content.lootbox.*` |
| Road manager | `knk.admin.world.road.*` |
| Siege / minigame manager | `knk.admin.minigame.siege.*` (or `knk.admin.minigame.*` for every minigame) |
| Player | player nodes only |

Staff **loses** these (§ 9, D6): `knk.admin.road` (`/knk road` editing), `knk.lootbox.admin.spawn|despawn|area|reload`,
`knk.admin.item` (`/knk item`), `knk.siege.admin.reload`, and the write side of `knk.kit.manage` /
`knk.siege.admin.manage` (already refused on the web since #374). Lootbox `list`/`tp` become lootbox view
(`knk.admin.content.lootbox`), which Staff doesn't get. Staff still sees lootbox odds as a player
(`knk.lootbox.odds`). This is an agent default (§ 9, A4).

### 3.2 What each role can do

| | Web app | In game |
|---|---|---|
| **Owner** | everything, owner pages, bulk delete and handing it out, Admin group | everything, owner mode |
| **Head Admin** (planned) | as Admin, plus hand out bulk delete, edit the Admin group and its members | as Admin |
| **Admin** | every dashboard type: view, New/Edit, delete, bulk delete, export; Entity setup and builders; all admin pages (game settings, mail log, economy policy and alerts, invitations, roads, lootboxes, discovery, siege settings, orphaned locations); player profiles including delete; make and change groups ranked below Admin | every `/knk` subcommand, gates, roads, lootbox placement, siege setup pointers and match control, `/gamemode` any |
| **Moderator** | as Staff, plus Orphaned Locations (view, keep), player statistics | as Staff, plus inventory/ender chest of others, `/fly`/`/gamemode` others, mass teleports, container bypass |
| **Staff** | **Player moderation** and **player profile** (status, balances, freeze/unfreeze, timeline, give a kit, groups/perms only if also granted `.group`/`.perm`); **Balance event log** and transactions; **Dashboard** with User, Kit and the siege types **read-only** (New/Edit/Delete/Export greyed out with "Requires …") | `/freeze`, `/unfreeze`, Player manager, `/knk user <player> info\|coins\|gems\|xp\|history`, `/knk currency`, `/kit give`, `/knk lootbox give\|token`, `/knk ib give`, `/siege admin list\|start\|stop\|skip\|kick`, staff mode, staff chat, social spy, `/tp`, `/fly`, spectator |
| **Builder** | Dashboard: the world types (domains, towns, districts, structures, streets, sub-regions, gates, locations, world tasks, workflows): view, New/Edit/links, delete, export; **Road network**, **Domain discovery**, **Orphaned Locations** (view; triage needs the `.orphans.*` nodes) | `/knk road` (all), `/knk towns…`, `/gate` admin, `/knk location` |
| **Content manager** | Dashboard: every content type including kits, lootboxes, clans, reference data: view, New/Edit, delete, export; **Entity setup**, form and display builders, **Minecraft catalogue**, **Lootboxes** page | `/knk item`, `/knk lootbox spawn\|despawn\|area\|reload`, `/knk clans`, `/knk menu` |
| **Kit / lootbox / road / siege manager** | the same, limited to that topic; pickers of other topics through lookups (labels only) | the topic's commands |
| **Player** | public pages, own account | player commands |

### 3.3 The create/edit rule, before and after

| Action | Today (`next`) | Target |
|---|---|---|
| View a type | area node or a consumer page's node (`ReadNodes`) | topic view node, its `.edit`/`.delete`/`.export`, or a consumer page's topic node |
| Create, edit, change links | write node **and** `knk.admin.content` (#374), except User, Permission Group, RoadProfile | the topic's `.edit` (User: `knk.admin.user.manage` + the profile's own nodes; Permission Group: `knk.admin.user.perm`) |
| Delete one | area node **and** `knk.admin.delete` | the topic's `.delete` (User: `knk.admin.user.delete`; group: `knk.admin.user.perm.delete`) |
| Bulk delete | area node **and** `knk.admin.delete` **and** `knk.admin.delete.bulk` | the topic's `.delete` **and** `knk.admin.delete.bulk` (users and groups: never) |
| Export | area node **and** `knk.admin.export` | the topic's `.export` |
| Open the dashboard | any area node | any view node of any topic (from the registry) |
| Realtime audience of a change | area node (`WebNode`) | the topic's view node |
| Pickers / labels across topics | any area node (lookups) | any topic view node (lookups) |

`withContentNode` in the web app and `changesNeedContent` in the API go. Nothing needs `knk.admin.content` on top of
another node any more.

## 4. Rule for new features: which role owns this?

Ask in this order; the first "yes" decides.

1. **Does it act on one player?** That covers helping them, correcting them, punishing them, or giving them something
   from existing content. → **Staff.** Put the node under `knk.admin.user.<action>` when it changes the player's
   account or status. Use a player-help node next to the feature (`knk.<feature>.give`) when it hands out existing
   content.
2. **Does it define what exists in the game?** Items, kits, lootboxes, menus, forms, reference data, clans. →
   **Content.** Add a topic, or a type in an existing topic, under `knk.admin.content`.
3. **Does it place or shape something in the world?** Domains, gates, locations, roads, world tasks. → **World.** Add
   a topic under `knk.admin.world`.
4. **Is it the setup of a minigame?** → **Minigame**, `knk.admin.minigame.<game>`. Live match control is a child of
   the same topic (`.control`, `.list`, …) that Staff can be given.
5. **Is it server operation or a game-wide policy?** Game settings, mail, economy policy, invitations, performance. →
   **Admin**, with its own `knk.admin.<feature>` node (covered by `knk.admin.*`).
6. **Is it destructive in bulk, does it escalate rights, or is it owner insight?** Bulk delete, Admin-group edits,
   telemetry, privacy, analytics. → **Owner**, later the Head Admin (#351). Use `knk.owner.*` with an exact grant, or
   an entry on the guard's owner-grant list.

Then, for a feature in a tree:

- Give each new topic its four rights (view, `.edit`, `.delete`, `.export`) and add the type to the `DashboardAccess`
  registry with its topic. The registry test fails for a type without a topic.
- In-game commands that change the topic check `.edit`. Commands that only show it check the view node.
- Name the role in the feature's design and the docs impact list. Add the node to the admin guide's matrix
  (§ 4 of the [admin guide](../../guides/admin/dashboard-access-admin-guide.md)).
- Don't seed a new node to Staff unless step 1 applies.

## 5. Migration (one release, data migration)

The developer chose one data migration in one release (§ 9, D7). The API, web app and plugin switch their constants
together, and the old names disappear. The resolver is unchanged.

`MigrateRolePermissionNodes` (knk-web-api, data only, plus a backup table):

1. **Backup.** It copies every `PermissionGrant` row it will change or delete into `PermissionGrantNodeMigrationBackup`
   (holder, node, value, expiry, migration id). Down restores those rows and removes the rows Up added. This makes the
   change reversible, unlike the earlier seed migrations, which couldn't tell their grants from hand-made ones.
2. **Rewrite**, per holder (users and groups), for active and expired rows alike. Values and expiries are kept, and
   denies stay denies:

   | Holder has | Gets |
   |---|---|
   | `knk.admin.content` | `knk.admin.content.*` (they could edit everything in content) |
   | `knk.admin.world` **and** `knk.admin.content` | `knk.admin.world.*` |
   | `knk.admin.world` without `knk.admin.content` | view of every world topic (`.domain`, `.gate`, `.location`, `.road`, `.task`), plus `.delete` per topic if they had `knk.admin.delete`, plus `.export` per topic if they had `knk.admin.export`. Today they can't create or edit (#371/#374); road view is new (§ 9, D2) |
   | `knk.kit.manage` (± content, delete, export) | `knk.admin.content.kit`, plus `.edit` with content, `.delete` with delete, `.export` with export (collapsed to `.*` when all four) |
   | `knk.admin.lootbox.manage` | the same pattern on `knk.admin.content.lootbox` |
   | `knk.siege.admin.manage` | the same pattern on `knk.admin.minigame.siege` |
   | `knk.admin.road` | `knk.admin.world.road` + `.edit` (RoadProfile and road edits never needed content), `.delete` / `.export` as above |
   | `knk.admin.user.manage` + `knk.admin.delete` | `knk.admin.user.delete`; with `knk.admin.export`: `knk.admin.user.export` |
   | `knk.admin.user.perm` + `knk.admin.delete` | `knk.admin.user.perm.delete` |
   | `knk.freeze` / `knk.unfreeze` | `knk.admin.user.freeze` / `knk.admin.user.unfreeze` |
   | `knk.admin.location.*` family, `knk.admin.discovery`, `knk.siege.admin.list\|control\|reload\|join`, `knk.lootbox.admin.spawn\|despawn\|area\|reload\|list\|tp`, `knk.admin.item`, `knk.gate.admin`, `knk.gatedoor.admin` | the § 2.2 / § 2.3 name |
   | wildcard grants (`knk.kit.*`, `knk.siege.*`, `knk.siege.admin.*`, `knk.lootbox.admin.*`, `knk.admin.location.*`) | the matching new wildcard, plus the old one kept for the player nodes it still covers (`knk.kit.*` still covers `knk.kit.give`) |

   After the rewrite, `knk.admin.delete` and `knk.admin.export` rows are deleted (backed up). `knk.admin.*` and `*`
   are untouched.
3. **Staff reshape** (§ 9, D6). The Staff group loses `knk.admin.world.road*`, `knk.admin.content.lootbox.edit` (the
   old spawn/despawn/area/reload), `knk.admin.content.lootbox` (old list/tp; A4), `knk.admin.content.items.edit` (old
   `knk.admin.item`), `knk.admin.minigame.siege.reload`, and any `.edit`/`.delete`/`.export` on kit and siege. It
   keeps `knk.admin.content.kit` and `knk.admin.minigame.siege` (view), `.siege.list`, `.siege.control`, and the
   player-help nodes. These removals are deliberate, so they go in the changelog's Admin steps. Down restores them from
   the backup.
4. **Seeds.** `SeedCommandPermissionNodes`, `SeedStaffFreezeNodes`, `SeedDashboardActionNodes` and the dev seed keep
   their history. A follow-up seed gives a migrations-only database the § 3.1 nodes for Staff, Moderator and Admin,
   with the same "skip if decided" rule (`SeedDashboardActionNodes.Decides`).
5. **Escalation guard.** `OwnerGrantOnly` stays `{ knk.admin.delete.bulk }`. The guard tests get the new covering
   wildcards: `knk.admin.*`, `knk.admin.delete.*` and `knk.*` still cover it, and the new area wildcards
   (`knk.admin.content.*`, …) don't, which is correct.
6. **Deploy order.** Back up the database, then stop the game server. Deploy the API (the migration runs), the web app
   and the plugin jar together, then start the game server. An old plugin against a migrated database would refuse
   `/freeze`, `/knk road` and the lootbox admin commands to everyone but ops and `*`. The plugin `config.yml` doesn't
   change.

**Alpha check before the deploy:** run the migration against a copy of the alpha database, then list Staff's and
Moderator's effective nodes before and after. Look for wildcards on Staff (`knk.admin.user.*` would now include
`.delete` and `.export`). The 2026-10-26 scan lists Staff's user nodes one by one. If a wildcard is there, the
migration replaces it with the explicit § 3.1 list.

## 6. Gap list: target vs. what `next` does today

| # | Gap | Where (on `next`) | Fixed by |
|---|---|---|---|
| G1 | No view/edit split: an area node means view + create + edit; `knk.admin.content` is the global "may change" switch (#371/#374/#383 stopgap); the web app adds it itself (`withContentNode`) | knk-web-api `Attributes/DashboardAccess.cs` (`ChangeNodes`, `changesNeedContent`), `RequireDashboardChange`; knk-web-app `withContentNode`, `AREA_NODES` (`src/hooks/useStaffAccess.ts`) | L1, L3 |
| G2 | Delete and export are global nodes; an area rank made after AM1's backfill doesn't get them (smoke test 2026-11-13) | `SeedDashboardActionNodes`; `StaffPermissions.Delete/Export` | L1, L2 (per-topic `.delete`/`.export`) |
| G3 | Kits, siege, lootboxes and roads sit outside the admin trees (`knk.kit.manage`, `knk.siege.admin.manage`, `knk.admin.lootbox.manage`, `knk.admin.road`), so `knk.admin.content`/`.world` holders don't get them and Admin needs `knk.admin.*` | `StaffPermissions`; `DashboardAccess` entries; plugin `KitCommand`, `SiegeService`, `LootboxAdminCommand`, `RoadAdminCommand` | L1, L2, L4 |
| G4 | Roads page needs `knk.admin.road`, not world (smoke test #383 § 8 step 9c) | knk-web-app `src/routes/routeTable.ts` (`/admin/roads` → `staff(ROAD_ADMIN_NODE)`) | L3 |
| G5 | Freeze nodes outside the user tree; #367's seed accepted without a live test | `StaffPermissions.Freeze/Unfreeze`, `SeedStaffFreezeNodes`; plugin `/freeze`, `/unfreeze`, Player manager menu | L1, L2, L4 |
| G6 | Staff holds game-core nodes in game on the alpha: `/knk road` editing, lootbox spawn/despawn/area/reload, `/knk item`, siege reload | alpha seed (scan § 3); `SeedCommandPermissionNodes` (`knk.admin.item`, `knk.siege.admin.reload` for Staff) | L2 |
| G7 | `/knk road` checks one node for every subcommand, so view and edit can't be split | plugin `roads/RoadAdminCommand.java` (`NODE`, `hasNode`) | L4 |
| G8 | Location retention nodes, discovery, gate admin nodes outside the world tree | `StaffPermissions.Location*`, `ManageDiscovery`, `GateAdmin`; plugin gate listeners | L1, L2, L4 |
| G9 | Realtime audience uses area nodes | knk-web-api `Realtime/RealtimeWebChangeMap.cs` (`NodeFor` via registry) | L1 |
| G10 | Single-node route access for admin pages (lootboxes, discovery, siege settings, catalogue, Entity setup) | `routeTable.ts` | L3 |
| G11 | Pages outside the dashboard aren't greyed out without the write node (#380); Create New menu ignores areas (#353); material picker refused in world/lootbox forms (#352); Permission Group list needs `.perm` (#369); PermissionGrant table fails (#408) | knk-web-app | open issues. L3 rebases them on topic nodes; the fixes stay in their own issues |
| G12 | No web screen for a group's own nodes: area ranks are made through `PUT api/PermissionGrants/by-node` | — | #50 (not in this rework; the guide keeps the API recipe) |
| G13 | Staff is meant to kick and ban, but `/kick` and `/ban` are vanilla and op-only; rank grants don't reach Bukkit (scan F11) | plugin | [#552](https://github.com/PandiO/knk-workspace/issues/552); nodes reserved in § 2.2 |
| G14 | No Head Admin; its rights are owner-only | escalation guard, seeds | #351 (planned row only, § 9 D9) |
| G15 | A migrations-only database has no Staff group, and gives nobody `knk.admin.content`/`.world`; the alpha's rights come from a hand seed | `Migrations/` | L2 step 4 |
| G16 | The admin guide § 4 says New on Permission Group needs `knk.admin.content` too, but the API exempts Permission Group. To verify against the web app's `withContentNode`; it disappears with L3 either way | guide § 6 step 1; knk-web-app | L3, L5 |

## 7. Risks

- **Lock-out at deploy.** If the plugin and API don't ship together, staff lose in-game commands until both are
  deployed. Ops and `*` always pass. Mitigation: the § 5 deploy order, and the changelog's Admin steps.
- **Wildcards now cover delete.** `knk.admin.<area>.*` includes `.delete`/`.export` by decision (§ 9, D3). An Admin
  handing a builder `knk.admin.world.*` hands out delete in that area, which is intended. Bulk delete stays separate.
- **Tier 3 work with no flag.** A node rename can't sensibly sit behind a config flag (both names would have to work,
  which is the alias option the developer didn't pick). Run it as a chain: the coordinator merges into `next`, and the
  developer smoke tests on `next` before promotion. The § 5 alpha copy check is part of L2.
- **Hidden node users.** Menu templates and game settings can store node strings (menu `visibilityPermission`,
  `actionPermission`, group overrides). L2 must also rewrite node strings in `MenuTemplates` (for example the Player
  manager's freeze buttons) and any stored settings. L2 starts with a grep of seeded menus and settings for old nodes.

## 8. Implementation links

One chain, PRs into `next`. L1, L2 and L4 must be promoted together; L3 too, because its route table is hard-coded.

| Link | Tier | Repo | Scope | Depends on |
|---|---|---|---|---|
| **L1 API nodes and rules** ([#547](https://github.com/PandiO/knk-workspace/issues/547)) | `tier:3` | knk-web-api | `StaffPermissions` → topic constants (`ContentKit`, `ContentKitEdit`, …; old constants removed); `DashboardAccess` rewritten to topics (`Topic`, `ViewNode`, `EditNode`, `DeleteNode`, `ExportNode`, `ReadNodes` = view + three writes + consumer pages); `RequireDashboardChange` → `.edit`; delete attributes → `.delete`; `DashboardController` bulk delete → `.delete` + `knk.admin.delete.bulk`, export → `.export`; metadata `actionNodes` and `area`/`topic`; `RealtimeWebChangeMap`; non-dashboard controllers (Kits, Lootbox*, LootboxConfiguration, Road*, NavigationSettings, SiegeConfiguration, location retention/orphans, discovery, Users freeze/delete); lookups' "any topic view node"; tests (`DashboardAccessTests`, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`, `ProtectedRoutes`, guard tests) | — |
| **L2 Migration and seeds** ([#548](https://github.com/PandiO/knk-workspace/issues/548)) | `tier:3` | knk-web-api | `MigrateRolePermissionNodes` with backup table (§ 5 steps 1–3), node strings in seeded menus/settings, follow-up seed for migrations-only databases (step 4); MySQL tests on the alpha seed shape (Staff → Moderator → Admin, `knk.admin.*`), before/after effective-node report | L1 (constants) |
| **L3 Web app** ([#549](https://github.com/PandiO/knk-workspace/issues/549)) | `tier:2` | knk-web-app | `AREA_NODES` → topic view nodes from metadata (or a constant list kept in step with the registry); `routeTable.ts`: roads → `knk.admin.world.road`, lootboxes → `knk.admin.content.lootbox`, discovery → `knk.admin.world.domain`, siege settings → `knk.admin.minigame.siege` (save: `.edit`), orphans → `knk.admin.world.location.orphans`, catalogue → `knk.admin.content.reference`, Entity setup and builders → `knk.admin.content.forms` (save: `.edit`), form wizard routes → the type's `.edit` (from metadata); remove `withContentNode`; player profile freeze/unfreeze → new nodes, Delete → `knk.admin.user.delete`; greyed-out hints name the topic node; tests | L1 (metadata) |
| **L4 Plugin** ([#550](https://github.com/PandiO/knk-workspace/issues/550)) | `tier:2` | knk-plugin | `/freeze`, `/unfreeze`, Player manager menu → `knk.admin.user.freeze/unfreeze`; `RoadAdminCommand` view/edit split (§ 2.2); `LootboxAdminCommand` spawn/despawn/area/reload → `knk.admin.content.lootbox.edit`, list/tp → view; `SiegeService` admin nodes → `knk.admin.minigame.siege.*`, `manage` → `.edit`; `KitCommand` manage → `knk.admin.content.kit.edit`; `/knk item` → `knk.admin.content.items.edit`; `/knk clans\|menu\|towns…` → view nodes; gate admin → `knk.admin.world.gate.edit`; `CommandNodes` (KNG-107 list) and tab completion; tests | L1 (names only) |
| **L5 Docs** ([#551](https://github.com/PandiO/knk-workspace/issues/551)) | `tier:1` | knk-workspace | essential docs with the links: CHANGELOG with Admin steps (deploy order, Staff's removed nodes, node rename table), deploy notes, this design's status; later in the documentation issue: rewrite [dashboard access admin guide](../../guides/admin/dashboard-access-admin-guide.md) § 2–6 on topics and the matrix, the dashboard access smoke test (§ 8 accounts per role), staff web app guide, commands reference (`docs/guides/users/commands.md`), web-api/web-app architecture § 5.1/5.2, a superseded note in the [dashboard access model](../dashboard-access-model/DESIGN.md) | L1–L4 |

Separate issues (not links of this chain):

- **KnK `/kick` and `/ban`** ([#552](https://github.com/PandiO/knk-workspace/issues/552), feature, `tier:2`, G13). Nodes `knk.admin.user.kick` and `knk.admin.user.ban` for Staff,
  a required reason, an audit entry, and later buttons on the player profile.
- Existing open issues on the same screens: #50, #351, #352, #353, #369, #380, #408.

## 9. Decisions

### 9.1 Developer decisions (asked in the design session, 2026-11-13 to 2026-11-15)

| # | Question | Decision |
|---|---|---|
| D0 | Node tree direction (#387 comment, 2026-11-13) | Fold `knk.kit.manage` and lootboxes into `knk.admin.content`, roads into `knk.admin.world`, freeze into `knk.admin.user`; sub-nodes per topic with `.*` for all; separate read and write rights per node |
| D1 | Read/write naming | `<topic>` = view, `<topic>.edit` = create/edit/link, `<topic>.*` = all |
| D2 | Should `knk.admin.world` include the roads page? | **Yes.** Roads are topic `knk.admin.world.road`; `knk.admin.world.*` opens Road network and `/knk road` |
| D3 | How do area ranks get delete/export? | **Per-area delete in the tree** (`<topic>.delete`), so `knk.admin.<area>.*` covers it. This reverses model A's global `knk.admin.delete` (#280 decision 1) |
| D4 | Export and bulk delete with D3 | **Export in the tree** (`<topic>.export`); **bulk delete stays global** (`knk.admin.delete.bulk`, owner-granted, on top of `.delete`); `knk.admin.delete` and `knk.admin.export` retire |
| D5 | Does Staff keep read access to kits and siege setup? | **Yes, view only** (`knk.admin.content.kit`, `knk.admin.minigame.siege`) |
| D6 | Staff's in-game area nodes | **Player help only:** keeps lootbox give/token, item blueprint give, kit give, siege match control (list/start/stop/skip/kick); loses road editing, lootbox spawn/despawn/area, `/knk item` |
| D7 | Moving existing grants | **One data migration in one release**; API, web app and plugin switch together; no resolver aliases |
| D8 | Freeze nodes | **Two nodes:** `knk.admin.user.freeze` and `knk.admin.user.unfreeze` |
| D9 | Head Admin (#351) in the matrix | **Yes, as a planned row**; the owner holds its rights until #351 is built; no code in this rework |
| D10 | Topic granularity | **Feature topics** (about a dozen), not one per dashboard type |
| D11 | Where does siege setup go? | **A third area for minigames** (developer: more minigames will come, and they overlap content and world): `knk.admin.minigame.siege`. The name `minigame` is the agent's pick for "minigames or something similar" (A1) |
| D12 | Kick/ban gap | **File an issue; reserve the nodes in the design** (`knk.admin.user.kick`, `.ban`) |

### 9.2 Agent defaults (reversible, for review)

| # | Default | Alternatives |
|---|---|---|
| A1 | Area name `knk.admin.minigame` (singular, like `content` and `world`), siege as `knk.admin.minigame.siege` | `knk.admin.minigames`, `knk.admin.games`, `knk.admin.events` |
| A2 | Siege match control moves to `knk.admin.minigame.siege.list\|control\|reload\|join` (children of the topic; Staff gets list + control) | keep `knk.siege.admin.*` outside the tree |
| A3 | Siege `reload` leaves Staff (configuration, not player help) | Staff keeps reload |
| A4 | Lootbox `list`/`tp` become lootbox view, which Staff doesn't get | Staff keeps lootbox view (like kits) |
| A5 | Topics: `content.items`, `.reference`, `.clans`, `.kit`, `.lootbox`, `.menu`, `.forms`; `world.domain`, `.gate`, `.location`, `.road`, `.task`; `minigame.siege` (§ 2.2) | merge `reference` into `items`; a separate `world.discovery` |
| A6 | Location retention, discovery and gate admin nodes move into the world tree (§ 2.3) | leave them where they are |
| A7 | Player-help nodes keep their names (`knk.kit.give`, `knk.lootbox.admin.give\|token`, `knk.admin.itemblueprints`, `knk.tasks`) | move them under `knk.admin.user.<feature>` |
| A8 | Users: `knk.admin.user.delete`, groups: `knk.admin.user.perm.delete`, both: `knk.admin.user.export` (no bulk) | one `knk.admin.user.delete` for both |
| A9 | Migration keeps today's reach exactly, except road view for world-only holders (D2) | no road view for migrated world-only holders |
| A10 | A backup table makes the migration's Down exact | Down by reverse mapping only (lossy for collapsed `.*` grants) |
| A11 | No seeded area-rank groups; the admin guide gives one recipe per role (§ 3.1) | seed Builder / Content manager / … groups as templates |
| A12 | Tier 3 without a flag; chain with coordinator merges and a full smoke test on `next` before promotion (§ 7) | — |

### 9.3 Still open

- None blocking. A1–A12 are defaults that the developer can change at review, before L1 starts.
