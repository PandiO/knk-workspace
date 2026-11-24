# Production Storage Terminals, Displays and Structure Menus — Admin Guide

**Status:** Current · **Last updated:** 2026-11-20 (first version, production P6 #683/#74, docs PandiO/knk-workspace#903)
**Checked against:** knk-web-api `next` `a2865d75`, knk-plugin `next` `8e672ba6` (not released; the game server part
runs only with `production.enabled: true`; the manual steps of the
[smoke test § 7](../production-storage-transport-smoke-test.md#7-phase-p6-terminals-displays-menus-commands-683-api-74-plugin-tier2)
have not been run live yet)
**Related:** [terminals architecture](../../architecture/production-storage-terminals.md) (capacity, viewers, the
terminal and display flows, the menus, tests), [API contract](../../specs/api/API_CONTRACT_PRODUCTION_STORAGE_MENUS.md),
[menus player guide § Structures and § Storage terminals and displays](../users/menus-player-guide.md#structures) (what
players see), [stock admin guide](stock-admin-guide.md) (storages, capacity, the ledger),
[production transport admin guide](production-transport-admin-guide.md) (orders),
[item identity admin guide](item-identity-admin-guide.md), [plugin configuration § 4.31](plugin-configuration.md#431-production)
(`production.storage.*`), [in-game commands](../users/commands.md#server-tools-knk)

Production phase P6 puts the stock into the world. You **bind** a chest, trapped chest or barrel to a storage:

1. A **terminal** shows the storage as a paged menu. Players take and put items there; each click is a move in the stock
   ledger, made as that player, and the chest itself stays empty.
2. A **display** is filled with a read-only sample of the stock, as full as the storage is. Nobody can take from it.

Each bound block adds its slots to the storage's room (a chest or barrel 27, a double chest 54), when the storage has
**units per slot** set. Bound blocks can't be broken, survive explosions and hoppers can't touch them.

Players also get the **Structures** tile in the main menu: every production structure and warehouse with search and
Town, Kind and Status filters, and a menu per structure. Members of the structure's town and staff see its rates,
workers, warnings, storages and transport orders; everyone else sees only the name, kind, town, level, products and
status. Staff get buttons for survey now, the transport dry run, the area outline, and cancel and retry on orders.

## 1. What you need

1. **knk-web-api** with migration `AddStorageContainers` applied. It only adds one table; existing storages and stock are
   not changed.
2. **One API restart** after the update: the three menus (`structures.overview`, `structures.structure`,
   `structures.orders`) are seeded, and the main menu gets its **Structures** tile in slot 18. A main menu where you
   already used slot 18, or that already opens the overview from some item, is left alone: add the tile yourself in the
   menu editor.
3. **Seeds.** As content staff, import the form and display seeds `StorageContainer`, the form seeds `StockTransaction`
   (seed v2, adds the reason Upgrade) and `ProductionArea` (seed v2), each with "make default".
4. **knk-plugin** of the same `next` (or later) on the game server, with `production.enabled: true` and the
   `production.storage` keys merged into `config.yml` (§ 5). Putting items into terminals also needs
   `items.identity.enabled: true`.
5. **Production enabled** ticked on the game settings page for terminal take and put and for the order retry. Binding,
   the menus and displays work while it is off.
6. **Town members.** Until town roles exist (#246), a player is a member of a town when they hold
   `knk.town.member.<town id>`. Make a permission group per town (for example "Town 3 members" with
   `knk.town.member.3`) and put its players in it. `knk.town.member.*` makes someone a member of every town.
7. **Nodes:**

   | To | Node(s) |
   |---|---|
   | `/knk storage bind\|unbind\|info\|reload` in game | `knk.admin.world.production` (in `knk.admin.world.*` and `knk.admin.*`) |
   | See a structure's details in every town, use every terminal, the menus' staff buttons, retry orders | `knk.admin.world` |
   | Survey now and Show area outline from the structure menu | `knk.admin.world` and `knk.admin.world.production` |
   | See and use one town's structures and terminals | `knk.town.member.<town id>` |
   | Read containers through the API (`api/StorageContainers`) | `knk.admin.world` |
   | Create and edit containers through the API | `knk.admin.world` and `knk.admin.content` |
   | Delete containers through the API | `knk.admin.world` and `knk.admin.delete` |

## 2. Binding containers

### 2.1 In game: `/knk storage`

Stand within 6 blocks of the chest, trapped chest or barrel and look at it.

1. Find the storage's id on its page in the web app (the storage list, or the structure's storages).
2. Empty the container: binding refuses one with items in it ("Empty the container first: its own items are not stock
   and would be lost.").
3. `/knk storage bind <storage id> terminal` or `/knk storage bind <storage id> display`, optionally followed by a
   label that players see instead of the storage's name: `/knk storage bind 12 display North hall`. A double chest is
   bound once, whichever half you look at. The answer: "Bound to <name> as a Terminal (54 slots, container #7)."; a
   display fills straight away.
4. `/knk storage info` says what a block is bound to, as the API knows it, and warns when this server has not loaded
   that yet.
5. `/knk storage unbind` removes the binding; a display's sample is cleared. The storage keeps its stock.
6. `/knk storage reload` reads every binding again now, for example after a change made through the API.

| Answer | Meaning |
|---|---|
| `Look at a chest, trapped chest or barrel (within 6 blocks).` | Nothing bindable in sight |
| `This block is already bound; unbind it first.` / `Not bound: that block is already bound` | One block, one binding |
| `Not bound: the API refused it (a system or transit storage, a double barrel, or an unknown storage)` | Check the storage id; system and transport cargo storages can't have containers |
| `Not bound: not allowed (403)` | The API refused the game server's call: check `api.auth.api-key` |
| `This block is not bound (try /knk storage reload after a web app change).` | `unbind` on a block this server doesn't know as bound |
| `Production is off on this server (production.enabled: false).` | Switch it on in `config.yml` and restart |

### 2.2 In the web app and through the API

The API has the dashboard type **StorageContainer** (World area) and its form and display seeds, but the web app on
`next` has no page for it yet ([#904](https://github.com/PandiO/knk-workspace/issues/904)), so bind in game. A script or
a staff tool can use `api/StorageContainers` ([API contract § 2](../../specs/api/API_CONTRACT_PRODUCTION_STORAGE_MENUS.md#2-apistoragecontainers));
send the canonical block (the left half of a double chest) and run `/knk storage reload` afterwards, or wait up to
`refresh-minutes`.

### 2.3 Room: units per slot

A storage's cap follows its containers only when it is capped and has **units per slot** set (the storage's page, or
the production kind level's units per slot for an Output storage). Then its cap is the slots of all its containers ×
units per slot: a warehouse storage with 64 units per slot and two double chests holds 2 × 54 × 64 = 6,912 units.
Without units per slot the storage keeps its fixed cap and the containers add nothing. Unbinding the last container
keeps the last cap; stock above a lowered cap stays, the storage only takes no more.

## 3. Displays

1. A display shows a sample of the storage, as full as the storage is: a storage at half its cap fills half the slots,
   spread over the container. The largest stocks get the most stacks. Unique items are not shown.
2. The items are tagged as a sample: a terminal refuses them and they are never real stock. Players can't take them out
   (the block opens as a read-only copy).
3. A display refreshes when its chunk loads, when someone opens it, after a terminal move on the same storage and after
   `/knk storage bind` or `reload`, at most once every `display-refresh-seconds` (30). Stock that production, transport
   or the web app moves shows at the next of these.
4. Put displays where players walk past them: a warehouse hall, the quarry's yard.

## 4. The structure menus

1. **Where:** the main menu's **Structures** tile ([player guide](../users/menus-player-guide.md#structures)). The
   menus are content seeds: change their texts and layout in the web app menu editor
   ([menu authoring admin guide](menus-admin-guide.md)).
2. **What members see:** give a town's players their `knk.town.member.<town id>` group (§ 1 item 6); without it they
   see only the public fields of their own town's structures.
3. **Staff buttons** (with `knk.admin.world`) in a structure's bottom row:
   1. **Survey now**: as `/knk production survey <id>` ([yield areas admin guide](production-yield-areas-admin-guide.md)).
   2. **Transport dry run**: what the automatic transport would do now, in chat; nothing changes.
   3. **Show area outline**: as `/knk production area show <id>`.
4. **Orders** (members and staff): open and recent orders of the structure. Staff click an order and confirm:
   1. **Cancel** (orders that are not final, returning or blocked on the way back): as in the
      [transport admin guide § 3.4](production-transport-admin-guide.md#34-cancelling).
   2. **Retry**: a waiting order (Planned, at a stop, waiting for room, blocked on return) tries its next step now; a
      Returned or Cancelled order is sent again as a **new manual order** with the same stops and amounts (once: a
      second retry gives the same new order). Refused while production is off, for an order on the road and for a
      delivered one.

## 5. On the game server: `production.storage`

Merge into the plugin's `config.yml` (Restart; [plugin configuration § 4.31](plugin-configuration.md#431-production)):

```yaml
production:
  enabled: true
  storage:
    refresh-minutes: 5            # how often the bound containers are read again
    display-refresh-seconds: 30   # at most one refresh of a display this often
```

With `production.enabled: false` the terminals are not running: bound blocks are plain chests, the menus are blocked
(the Structures tile is hidden) and `/knk storage` says production is off. A display keeps its last sample but is no
longer protected, so unbind displays before switching production off for good.

## 6. A safe test

On a test server with `production.enabled: true` and `items.identity.enabled: true`, a town **Test** (id 3) with a
warehouse **North** whose delivery storage (id 12) is capped with 64 units per slot, and two players: **Alice** in the
group with `knk.town.member.3`, **Bob** without:

1. Place a chest and a barrel in North. `/knk storage bind 12 terminal` on the chest and
   `/knk storage bind 12 display` on the barrel. The storage's cap is now 54 × 64 = 3,456 (its page shows it).
2. As Alice, right-click the chest and put 64 Cobblestone in from your inventory: "Put in 64". The chest itself is still
   empty; the storage holds 64, and the ledger shows a Deposit by Alice from `SYS_WORLD`.
3. Wait 30 seconds and open the barrel: one stack of Cobblestone. You can't take it.
4. As Alice, right-click the stack in the terminal: "Took 1 Cobblestone".
5. As Bob, right-click the chest: "Only members of this storage's town, its owner and staff can use this terminal."
6. As Bob, open **Structures** → North: name, kind Warehouse, town Test and status only. As Alice: also its storage with
   "Cobblestone: Amount: 63" and the Transport orders button.
7. Try to break the chest: "This terminal is bound to North …". Unbind both blocks when you are done.

The full checks are in the [smoke test § 7](../production-storage-transport-smoke-test.md#7-phase-p6-terminals-displays-menus-commands-683-api-74-plugin-tier2).

## 7. Effects on existing data

1. The migration adds one table. No container exists until you bind one.
2. Binding a container to a storage with units per slot **rewrites its cap**; unbinding the last one keeps the cap it
   had then. A production structure's Output storage with containers takes its cap from them, not from the level's
   output cap.
3. Every terminal move is a ledger transaction (Deposit or Withdraw, component `terminal`, the player as actor): it
   shows in the storage's history and the reconciler counts it.
4. The main menu of an existing database gets the Structures tile in slot 18 at the first start, unless that slot is
   used.
5. The structure menus show every production structure and warehouse to every player (the public fields). Nothing
   about a town's stock is shown to non-members.

## 8. Troubleshooting

| You see | Why | What to do |
|---|---|---|
| A chest opens as a normal chest after binding | The binding was made through the API and this server has not read it yet, or `production.enabled` is off | `/knk storage reload`; check the switch |
| `/knk storage info`: "(not loaded here yet; run /knk storage reload)" | The server's list is older than the API's | `/knk storage reload` |
| The storage's cap didn't change | The storage has no units per slot, or is uncapped | Set units per slot on the storage (§ 2.3) |
| A member gets "Only members of this storage's town …" | They don't hold `knk.town.member.<town id>`, or the storage belongs to another town, a clan or a player | Check their group; clan storages are staff only |
| "Item identity is off on this server …" when putting | `items.identity.enabled: false` | Switch it on (#141) |
| "This item isn't in the item catalogue" | A renamed item or another plugin's item | It can't be stock; see the [item identity admin guide](item-identity-admin-guide.md) |
| "Unique items can't be … in game yet" | Unique items move through the web app only (#897) | Use the web app |
| "Production is switched off; the terminal moves nothing right now." | Production enabled is off in the API | Tick it on the game settings page |
| "The storage is busy or locked" | Someone else moved stock at the same time, or the storage is locked | Try again; check the storage's lock |
| A display shows old stock | It refreshes only on its triggers (§ 3) | Open it, or wait |
| No Structures tile in the main menu | `production.enabled` is off, the API was not restarted, or slot 18 was taken | Switch it on; restart the API; add the tile in the menu editor |
| A player sees no rates or storages in their own town's structure | Not a member yet | Give them the town's group |
| Retry "The order is on the road" | It arrives at its ETA by itself | Wait |
| A bound chest was extended to a double chest and no longer works | The binding is keyed by the chest's left half and its slot count | Remove the extra chest, `/knk storage unbind`, place it again and bind again |

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#903).
