# Inventory Menus — Admin Guide

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-11-11 (first version, PandiO/knk-workspace#302; checked against knk-plugin `main` `121030f`,
knk-web-api `master` `b5e57fa` and knk-web-app `main` `9a85238`)

How the in-game menus are defined, changed and checked. What players see is in the
[menus player guide](../users/menus-player-guide.md); the engine's design is in
[specs/inventory-menu](../../specs/inventory-menu/).

> **There is no menu editor in the web app.** Menu templates are created by the API's seed data and changed through
> the REST API (`api/MenuTemplates`). The authoring UI was deferred on purpose
> ([implementation plan](../../specs/inventory-menu/IMPLEMENTATION_PLAN.md), "Explicitly out of scope"); a web editor
> is a separate decision ([#319](https://github.com/PandiO/knk-workspace/issues/319)).

## 1. Where menus come from

- **Seeds:** at every start, knk-web-api creates every built-in menu template that doesn't exist yet, by key
  (`Models/Menu/MenuTemplateSeed*.cs`). Existing templates are never overwritten, with one exception (§ 4). Deleting a
  seeded template and restarting the API brings back the seed version: that is also how to reset one.
- **Examples:** nine demo templates (`example.*`) are seeded only with `Seeding:IncludeExamples` true (the default; the
  closed alpha runs with `false`). Remove old ones with `scripts/maintenance/remove-seeded-examples.sql`.
- **The API:** `api/MenuTemplates`: `GET /` (list), `GET /{id}`, `GET /by-key/{key}`, `POST /`, `PUT /{id}`,
  `DELETE /{id}`. Reads need a signed-in user; writes need the game server or `knk.admin.content`. **`PUT` replaces the
  whole template** (sections, items, bindings), so always send the complete tree.

The built-in menus: `main` (the hub, 3 rows), `kits.overview`, `profile.main`, `items.catalog`, `premium.tiers`,
`discoveries.main`, `teleport.destinations`, `statistics.main`, `statistics.leaderboards`, `statistics.leaderboard`,
`statistics.visibility`, `users.manager` (+ `.edit`, `.titles`, `.groups`) and the siege menus `siege.overview`,
`siege.information`, `siege.spawnpoint`.

## 2. What a template contains

| Level | Fields (as in `Dtos/MenuDtos.cs`) |
|---|---|
| Template | `Key` (what the plugin opens, e.g. `kits.overview`), `Name` (the inventory title, `&` colours work), `Description`, `Height` (rows, 1–6), `Growth` (`Static` / `Dynamic`), `MinHeight`, background material, `AutoRefreshTicks`, sections |
| Section | `Name` (unique in the template), `Kind` (ContentGrid, SearchBar, FilterBar, StaticButtons, ConfirmDialog), position and size, `Overflow`, `VisibilityPermission`, `Searchable`, `ContentSourceId` + `ContentSourceParamsJson`, items |
| Item | slot (`SlotOverride`, or automatic), material, amount, display mode (Normal, Disabled, Highlight, Hidden, Blink), `VisibilityPermission` (render), `ActionPermission` (click), `IsRowTemplate`, variable bindings (name, lore lines, material, amount), actions, conditions |

Texts can use getter chains such as `$player.getName$`, `$row.getName$` (in a row template) or `$ctx.lobbyId$`.

**Built-in actions:** `menu.close`, `menu.open` (param `key`), `menu.back`, `menu.page.next|prev|first`,
`menu.search.prompt|clear`, `menu.filter.prompt|cycle|clear`, `menu.confirm.request|accept|cancel|doubleclick`,
`menu.state.set|cycle`; features add their own (`kits.claim`, `teleport.warp`, `siege.*`, `statistics.*`, ...).
**Built-in conditions:** `always`, `permission-node`, `has-pending-confirmation`, `value-equals`, `menu-available`
(param `key`; use it as a Render condition on hub tiles so a tile hides when its menu isn't available).

**Content sources** (fill a section from game data; a row source needs exactly one row-template item):
`items.catalog`, `catalog.itemblueprints`, `kits.available`, `titles.brackets`, `premium.tiers`, `users.online`,
`users.target`, `users.titles`, `users.groups`, `discoveries.rows`, `teleport.destinations`,
`statistics.main.title-history`, `statistics.visibility.rows`, `statistics.leaderboards.boards`,
`statistics.leaderboard.entries`, `siege.lobbies`, `siege.vote-candidates`, `siege.body`, `siege.spawn-options`,
`example.rows`.

## 3. Sizes and paging

- **Height** is 1–6 rows of 9 slots. Every section must fit inside the menu without overlapping another; slot
  overrides must be in the menu. The API doesn't check these; the plugin does when the menu is assembled.
- **Dynamic** menus drop empty rows from the bottom after each render, down to `MinHeight` (a section keeps its own
  first `MinHeight` rows). When the row count changes, the menu reopens at the new size. **Static** menus never
  change size.
- **Paging:** a section with more items than slots pages (`Overflow` `Scroll` or `Wrap`; `Hide` shows one page only).
  Sections with a content source always page. Paging wraps around at both ends. Pager arrows get a `Page X/Y` line
  automatically.

## 4. The siege menus are repaired at every API start

Since the 2026-10-24 playtest the three siege menus shrink to their content: `siege.overview` (5 rows, Dynamic, min 2),
`siege.information` (6, Dynamic, min 3) and `siege.spawnpoint` (3, Dynamic, min 2). At **every API start**,
`RepairSiegeLayoutAsync` sets `Growth` and `MinHeight` of these three back to those seed values and makes the spawn
menu reachable in the hub phase. **A change you make to `Growth` or `MinHeight` of these three menus is reverted at the
next API start** (the older smoke-test note that only "Static" rows are touched is out of date). Other fields of these
menus, and every other menu, are left alone.

## 5. When the game server picks a change up

- **Cache:** the plugin caches each template by key for **60 seconds** (the global `cache.ttl-seconds`; the
  `cache.entities.menus.ttl-minutes` setting isn't used, [#121](https://github.com/PandiO/knk-workspace/issues/121)).
  An edited menu shows its new content after at most a minute.
- **Validation happens once, at startup.** The plugin lists every template, checks it (layout, every getter chain
  against the declared types, every action, condition and content-source id) and blocks the broken ones for the rest
  of the run. An edit to an already-validated menu is only checked for layout when it opens; its bindings are checked
  again at the next restart. **A new template is "unavailable" until a restart**: `menu-available` hides its hub tile,
  `/warp` doesn't use it, but `/knk menu open <key>` does open it. Siege menus are the exception: an unavailable siege
  menu is validated on the spot.
- `/knk cache refresh` doesn't clear menus, and there is no menu reload command: restart the plugin for a full reset.
  (With the realtime channel switched on, a template change also clears that key at once; it is off by default.)
- **API down at startup:** validation retries after 10 s, 20 s, 40 s, then every 60 s, and at once when the API comes
  back. Until then menus are unavailable and siege, teleport and leaderboard commands fall back to chat. Console:
  `InventoryMenu startup validation: failed to list menu templates (API down?) …` and, when done, `… checked N menu(s),
  B blocked`. (Merged 2026-10-25; not yet confirmed in a live test.)
- **A broken template:** the console logs `menu '<key>' is broken and will refuse to open: <reasons>`; players get `That
  menu is unavailable right now.` `/knk menu broken` lists the blocked menus and why.

## 6. Bedrock players

- With Floodgate installed, a menu-to-menu switch for a Bedrock player closes the current menu and opens the next one
  `menus.bedrock-transition-delay-ticks` later (default 3, at most 20, 0 = off; Java players are never delayed). This
  also applies when a Dynamic menu changes size. Keep menu hops and size changes to what is needed.
- Sizes are 1–6 rows for everyone; there is no Bedrock-specific limit.
- The menu item (`menus.menu-item.*`, a nether star in slot 8 for every player by default) exists mainly for Bedrock
  and console players; see the [plugin configuration reference](plugin-configuration.md).

## 7. A safe way to add or change a menu

1. Create it under a new key (e.g. `test.<name>`) with `POST api/MenuTemplates`, signed in with `knk.admin.content`.
   Keep the height 1–6, sections inside the menu and apart, and use only the ids in § 2.
2. On the **dev** server, restart the plugin and check the console (`checked N menu(s), 0 blocked`) and
   `/knk menu broken`.
3. Open it with `/knk menu open <key>` (needs `knk.admin.menu`), as a Java and, if possible, a Bedrock player. Check
   paging and, for a Dynamic menu, how it shrinks with little content.
4. To change an existing menu: `GET` it, edit, `PUT` the whole tree, wait a minute (or restart), and restart once more
   so its bindings are validated again.
5. Only then link it: a `menu.open` action (param `key`) with a `menu-available` Render condition on the hub tile.
6. Leave `Growth` and `MinHeight` of the siege menus alone (§ 4).

## 8. Known gaps

- No web editor for menu templates (decision issue [#319](https://github.com/PandiO/knk-workspace/issues/319)).
- Per-menu cache time ignored ([#121](https://github.com/PandiO/knk-workspace/issues/121)).
- Hub tiles hidden until restart when the API is down at server start ([#144](https://github.com/PandiO/knk-workspace/issues/144);
  the retry above was merged for it but hasn't been confirmed live).
- The siege menu repair overwrites staff changes to `Growth`/`MinHeight` (§ 4,
  [#320](https://github.com/PandiO/knk-workspace/issues/320)).
