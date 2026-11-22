# Production storage terminals, display containers and structure menus (knk-web-api and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-20 (first version, production P6 #683/#74, docs PandiO/knk-workspace#903)
**Checked against:** knk-web-api `next` `a2865d75` (PR PandiO/knk-web-api#67), knk-plugin `next` `8e672ba6` (PR
PandiO/knk-plugin#110). Not released; the manual steps of the
[smoke test § 7](../guides/production-storage-transport-smoke-test.md#7-phase-p6-terminals-displays-menus-commands-683-api-74-plugin-tier2)
have not been run live yet.
**Related:** [production DESIGN § 6](../specs/production-storage-transport/DESIGN.md) (storage containers) and § 11.2
(the menus), decision record § 15.1 M1-M5, [API contract](../specs/api/API_CONTRACT_PRODUCTION_STORAGE_MENUS.md),
[admin guide](../guides/admin/production-storage-admin-guide.md), [menus player guide § Structures](../guides/users/menus-player-guide.md#structures),
[stock admin guide](../guides/admin/stock-admin-guide.md) (storages, capacity, the ledger),
[production transport](production-transport.md) (orders, cancel), [item identity admin guide](../guides/admin/item-identity-admin-guide.md),
[plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production) (`production.storage.*`)

Phase P6 brings the stock into the world. Staff **bind** a chest, trapped chest or barrel to a storage. A **terminal**
shows the storage as a paged menu: every take and put is a stock-ledger move, the block itself stays empty. A
**display** is filled read-only with a sample of the stock, as full as the storage is. Every bound block adds its slots
to the storage's capacity. Players get the **Structures** menus: a searchable overview of every production structure
and warehouse, a menu per structure and its transport orders. The API filters what each viewer sees: the public fields
for everyone, the stock, rates, workers and orders only for members of the structure's town and staff (M3).

The API is the only truth (DESIGN § 6.2). The plugin never finds containers by scanning and never keeps stock of its
own: it reads the binding list, and each click is one API call made for the player.

On the game server everything here needs `production.enabled: true` (A21): without it the terminal module is not built,
`/knk storage` says production is off and the three menus are blocked. In the API, binding and every read work while
the game setting **Production enabled** (`Production:Enabled`) is off; terminal take and put and the order retry need it
on (409 otherwise).

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| Entity `StorageContainer`; enums `StorageContainerMode` (Terminal, Display), `StorageContainerType` (Chest, TrappedChest, Barrel) | knk-web-api | `Models/Stock/StorageContainer.cs`, `Enums/StockEnums.cs`; `DbSet` and indexes in `Properties/KnKDbContext.cs` |
| CRUD, terminal view, take and put, display sample, the container-derived cap | knk-web-api | `Services/Stock/StorageContainerService.cs` (`StorageContainerService`, `StorageContainerCapacity`); the cap is also applied by `StorageService` (storage update) and `ProductionEngine` (level change of an Output storage) |
| Who is looking (viewer, staff, town membership) | knk-web-api | `Services/Production/ProductionViewer.cs` (`ProductionViewer`, `ProductionViewerResolver`, `PermissionTownMembershipResolver`) |
| Structure menu reads | knk-web-api | `Services/Production/StructureMenuService.cs` |
| Order retry | knk-web-api | `TransportService.RetryAsync` in `Services/Production/TransportService.cs` |
| Controllers and DTOs | knk-web-api | `Controllers/StorageContainersController.cs`, `Controllers/StructureMenusController.cs`, `POST {id}/retry` in `Controllers/TransportOrdersController.cs`; `Dtos/StorageContainerDtos.cs`, `Dtos/StructureMenuDtos.cs` |
| Dashboard type, lookup | knk-web-api | `Attributes/DashboardAccess.cs` (`StorageContainer`, World area, with delete), `Attributes/DashboardLookups.cs` |
| Menu seeds | knk-web-api | `Models/Menu/MenuTemplateSeed.Production.cs` (`structures.overview`, `structures.structure`, `structures.orders`, the hub tile and `RepairProductionHubTileAsync`) |
| Form and display seeds | knk-web-api | `Data/FormConfigurationSeeds/StorageContainer.json`, `Data/DisplayConfigurationSeeds/StorageContainer.display.json`; `StockTransaction.json` v2 (reason Upgrade, #881), `ProductionArea.json` v2 (#877) |
| Terminal rules (pure) | knk-plugin | `knk-core/.../core/production/terminal/`: `ContainerIndex`, `BlockKey`, `StorageContainerInfo`, `TerminalLayout`, `TerminalPage`, `TerminalMessages`, `DisplayLayout`, `DisplaySample`, `DisplayThrottle`, `TerminalSettings`, `BindRequest`, `StockMoveResult` |
| Menu text and facets (pure) | knk-plugin | `knk-core/.../core/production/menu/`: `StructureMenuText`, `StructureFacets`, `StructureMenu`, `StructureRow`, `TransportOrderRow`, `TransportDryRun` |
| API ports and clients | knk-plugin | `knk-core/.../core/ports/api/StorageContainersApi.java`, `StructureMenusApi.java`; `knk-api-client/.../api/impl/StorageContainersApiImpl.java`, `StructureMenusApiImpl.java`, `ProductionHttp.java` |
| Paper side: terminals and displays | knk-plugin | `knk-paper/.../paper/production/terminal/`: `StorageTerminalModule` (events, takes, puts, displays, protection), `TerminalView`, `DisplayView`, `DisplayWriter`, `BlueprintItems`, `ContainerBlocks`, `StorageTerminalConfig` |
| Paper side: menus | knk-plugin | `knk-paper/.../paper/menu/content/StructuresMenuFeature.java` and its views and rows (`StructuresView`, `StructureView`, `StructureOrdersView`, `StructureOverviewRow`, `StructureStorageRow`, `TransportOrderMenuRow`) |
| Command | knk-plugin | `knk-paper/.../paper/commands/StorageAdminCommand.java` (`/knk storage`); wiring in `KnKPlugin` (`initializeStorageTerminals`, `townAt`, `structuresStaffTools`) |
| Scenario | knk-plugin | `knk-paper/.../paper/scenario/scenarios/StorageDisplayDoubleChestScenario.java` |

## 2. The `StorageContainer` (DESIGN § 6.2-6.3)

| Field | Meaning |
|---|---|
| `StorageId` | The storage the block shows. Not a system (`Virtual`) or `Transit` storage: those are refused (400) |
| `Mode` | `Terminal` or `Display`. Backed mode (a normal chest mirrored into the API) is Later (#113) |
| `ContainerType`, `IsDouble` | `Chest`, `TrappedChest` or `Barrel`; only chests and trapped chests can be double (a double barrel is 400) |
| `Slots` | Derived on save: 54 for a double chest, else 27 |
| `WorldName`, `X`, `Y`, `Z` | The block, unique (`IX_storage_containers_WorldName_X_Y_Z`). `Y` from -64 to 320. A double chest is stored once, by its canonical half: the left half in Bukkit's `DoubleChest.getLeftSide()`, which the plugin sends |
| `Label` | Optional name for staff and players ("North terminal"), at most 100 characters; empty clears it |
| `CreatedByUserId`, `CreatedAt`, `UpdatedAt` | Audit |

A container is deleted with its storage (cascade). Binding, moving and unbinding run in one transaction under the
storage's row lock (`StockLocks.LockStoragesAsync`); a block that is taken is a 409.

### 2.1 Container-derived capacity (DESIGN § 4.4)

`StorageContainerCapacity.ApplyAsync` writes the storage's cap from its containers:

1. Only for a capped storage with `UnitsPerSlot` set. Without `UnitsPerSlot` the storage keeps its fixed `MaxUnits`.
2. `MaxUnits = Σ Slots of its containers × UnitsPerSlot`. A chest or barrel adds 27 slots, a double chest 54, so
   placing and binding a chest adds room.
3. It runs after each bind, move to another storage (both storages), unbind, storage update (`StorageService`) and level
   change of a production structure's Output storage (`ProductionEngine`, after the level's `OutputMaxUnits` and
   `UnitsPerSlot`). With bound containers the derived cap wins over the level's `OutputMaxUnits`.
4. Unbinding the **last** container leaves the last value; nothing is trimmed. Stock above a lowered cap stays; the
   storage only takes no more (as for any cap, [stock admin guide](../guides/admin/stock-admin-guide.md)).

Every reader (stock moves, the engine's full check, the transport's room) sees the result in `MaxUnits`, so there is no
second capacity rule.

## 3. Who sees and uses what (M3)

### 3.1 The viewer

`ProductionViewerResolver.ResolveAsync` turns the caller into a `ProductionViewer(UserId, IsStaff)`:

1. A web user: their user id. The game server (plugin key): the player in `X-Acting-User-Id`. Anyone else, and a game
   server call without a player, is a **visitor** (public fields only, A25).
2. `IsStaff`: the user holds `knk.admin.world`.

### 3.2 Town membership until town roles (#246)

`PermissionTownMembershipResolver` makes a user a member of town `<id>` when they hold `knk.town.member.<id>`
(wildcard-aware, so `knk.town.member.*` covers every town), granted through permission groups. Town roles (#246) will
replace this class; nothing else depends on the node.

### 3.3 The rules

1. **Details of a structure** (`SeesDetailsAsync`): staff, or a member of the structure's town. The town is the
   district's town for a structure in a district, else its rural town.
2. **A storage** (`SeesStorageAsync`, terminals): staff; for a player storage only that player; for a domain storage the
   members of the domain's town (a town itself, a district's town, or a structure's effective town). Clan, transit and
   system storages: staff only.
3. The filter is applied in the API, so the game server never receives stock, rates, workers or orders that the player
   may not see.

## 4. Structure menus (DESIGN § 11.2, M1-M5)

### 4.1 Reads (`StructureMenuService`)

1. **Overview** (`POST api/StructureMenus/search`, M2): every production structure and warehouse, public fields only:
   type, name, kind (`Warehouse` for a warehouse), town, rural flag, level, products (the blueprint names of its
   lines) and a status. Filters `townId`, `productionKindId`, `structureType`, `status`; the search term matches the
   name, the kind and the products. Sorted by name (or `town`, `kind`, `status`), at most 200 rows per page. The whole
   list is built in memory per call.
2. **Structure menu** (`GET api/StructureMenus/{id}`, M1, M3): the public row, `viewerSeesDetails`, `viewerIsStaff` and,
   only when the viewer sees details, `detail`: workers present, total and away (carrying an order), rates per line
   with their status and why a line is not producing (from `ProductionEngine.OverviewAsync`), warnings and the open
   order count (from `TransportService.StructureViewAsync`), and every domain storage of the structure with its top 54
   stock lines. For a warehouse the open order count counts orders with a stop there, and a Full or Stalled status is
   its warning.
3. **Orders** (`GET api/StructureMenus/{id}/orders`): the structure's transport orders, newest first, through the
   transport search with `structureId`. Members and staff only (403 for anyone else).

Reads stay on while production is off (G16). The public rows read stored line states and never settle.

### 4.2 The public status (`StructureMenuService.ProducerStatus`)

For a production structure, the first that applies:

| Status | When | Text |
|---|---|---|
| `Full` | An enabled line is `BlockedFull` | "Its storage is full: production stops until goods are carried away." |
| `NoRoad` | Rural and its road connection is not `Connected` (D5) | "Not connected to its town's roads: goods are not carried away." |
| `Stalled` | Production switched off on the structure; no enabled running line; or no worker present | "Production is switched off." / "It produces nothing yet." / "No production line is running." / "All workers are away." |
| `Working` | Otherwise | "Working." |

A warehouse is `Full` when its default storage is at its cap, `Stalled` when it takes no deliveries, else `Working`.

### 4.3 The menu seeds

`MenuTemplateSeed.Production.cs` seeds three menus as menu content (create-only, editable in the web app menu editor,
A27). The plugin side is `StructuresMenuFeature` (§ 4.4).

1. **`structures.overview`**: the hub's **Structures** tile (slot 18, `CRAFTING_TABLE`) opens it. A header item, then
   the searchable content section `Structures` on the row source `structures.overview`, with the facet buttons Town
   (compass), Kind (hopper), Status (redstone torch, values Working, Stalled, NoRoad, Full), the search sign, Clear
   filters (barrier) and the pagers.
2. **`structures.structure`**: the details header, then "Productions" (rates), "Workers", "Warnings" and the
   transport orders entry, shown when `structure.getSeesDetails` is true; the storage list (row source
   `structures.storages`, "Amount: N" per item); and a bottom row behind `knk.admin.world` (`VisibilityPermission`)
   with **Survey now** (`structures.survey`), **Transport dry run** (`structures.dry-run`) and **Show area outline**
   (`structures.outline`). Players get no action buttons.
3. **`structures.orders`**: one structure's orders (row source `structures.orders`): cargo, from, to, state and the
   expected arrival. For staff (`ActionPermission` `knk.admin.world`) a row's click asks to confirm
   `structures.order-cancel` when `row.getCanCancel` is true and `structures.order-retry` when `row.getCanRetry` is
   true; Confirm and Cancel buttons show while an action is pending (condition `structures.pending`).

A hub seeded before P6 gets its tile at the next API start (`RepairProductionHubTileAsync`): skipped when any hub item
already opens `structures.overview` or when an admin used slot 18. The other two menus are new keys, so create-only
seeding adds them.

### 4.4 `StructuresMenuFeature` (knk-plugin)

The feature is always registered, so the seeded menus validate. With `production.enabled: false` the plugin blocks the
three menu keys ("production is switched off"), which hides the hub tile.

1. **Roots**: `structures` (`StructuresView`: the facet values and the filter lines), `structure` (`StructureView`: the
   last menu read for this viewer and `ctx.structureId`) and `structureOrders`.
2. **Row sources**: `structures.overview` (search, facets Town and Kind by name, Status as it is), `structures.storages`
   (the storages of `GET api/StructureMenus/{id}`; the same read fills the `structure` root) and `structures.orders`
   (a 403 for a visitor is an empty list).
3. **Every read acts for the viewer** (`X-Acting-User-Id`), so the API does the M3 filter.
4. **Caching**: the facet lists come from one background read of up to 200 structures, kept 5 minutes; a structure menu
   is kept 10 seconds per viewer and structure (at most 512 remembered). Providers run on the main thread and never do
   I/O: they read what the last fetch left, start a fetch when nothing is there and repaint when it lands.
5. **Town first** (DESIGN § 11.2.1): as a `MenuObserver`, when the overview opens from another menu or a command, the
   feature sets the Town facet to the town whose land the player stands in (territory lookup, #689); in the wilderness
   it sets nothing. Coming back to it from one of the structure menus keeps the filters.
6. **Staff actions** (M4) check `knk.admin.world` again on the click ("Only staff can do that."):
   1. Survey now and Show area outline run `/knk production survey <id>` and `/knk production area show <id>` for
      the player (`ProductionAdminCommand`), so they need `knk.admin.world.production` too and P4's survey module.
   2. Transport dry run calls `GET api/ProductionStructures/{id}/transport` and prints it in chat: automatic transport
      and road, Output and threshold, carriers and workers, the reasons for and against, warnings, what order it would
      create and the open orders. "Nothing changes."
   3. Cancel and retry call `POST api/TransportOrders/{id}/cancel` and `/retry` after the confirm.
7. Which orders offer cancel and retry is the plugin's (`TransportOrderRow`): cancel for every state except Delivered,
   Returned, Cancelled, Lost, Returning and ReturnBlocked; retry for every state except Delivered, Lost, InTransit and
   Returning. The API refuses what it can't do (§ 4.5).

### 4.5 Order retry (`TransportService.RetryAsync`, M4)

1. 409 while `Production:Enabled` is off.
2. `Delivered`: 409, nothing to retry. `InTransit` and `Returning`: 409, it arrives at its ETA.
3. `Returned` or `Cancelled`: a **new manual order** with the same source, carrier and the stops' planned amounts, note
   "Retry of transport #<id>.", client key `retry-of-<id>`, so a repeated retry returns the same new order. An order
   without cargo, or one the create refuses, is a 409.
4. A waiting order (`Planned`, `AtStop`, `AwaitingSpace`, `ReturnBlocked`): its next action moves to now, with an event
   "Retried now by user <id>." (or "the game server"), then it advances at once. One without a next action is a 409.

## 5. Terminals: put and take through item identity (DESIGN § 6.2 Terminal mode)

### 5.1 Opening

1. `ContainerIndex` holds every binding by canonical block and, for displays, by chunk. It is the API's list
   (`POST api/StorageContainers/search`), read at start, every `production.storage.refresh-minutes` (5) and after
   `/knk storage bind|unbind|reload`. Opening a chest needs no API call to find its binding.
2. A right-click on a bound block (either half of a double chest) is cancelled: a terminal opens `TerminalView`, a
   display opens `DisplayView` (§ 6). The block's own inventory is never opened.
3. `TerminalView` is a 54-slot screen: the storage's entries in the top five rows (45 per page: stock lines by name,
   then unique items), the bottom row with Previous (slot 45), the fill (49, "40 of 1,000 units (4%)" or "40 units"
   without a cap) and Next (53). Pages come from `GET api/StorageContainers/{id}/terminal` (page size up to 54, at most
   2000 stock lines and 2000 unique items read).
4. The player must be in the plugin's user cache ("Your account isn't loaded yet").

### 5.2 Take

1. A click on an entry: left takes a stack (the item's stack size), right one, shift as many as fit in the player's
   inventory; never more than the entry holds (`TerminalLayout.takeAmount`). "Your inventory is full." when nothing
   fits.
2. One `POST api/StorageContainers/{id}/take` (storage → `SYS_WORLD`, reason `Withdraw`, actor kind `PluginServer`,
   actor user the player, component `terminal`, source `StorageContainer`/`<id>`) with a new idempotency key per click.
   The API sends what it accepted; the player gets that many of the blueprint's item (`BlueprintItems`, built like kit
   items with the blueprint's default enchantments; a blueprint that can't be built is `PAPER` with its name).
3. Unique items are refused in game ("Unique items can't be taken out in game yet; use the web app.").

### 5.3 Put

1. A click on an item in the player's own inventory puts the stack (right click one).
2. Refused before the API (`StorageTerminalModule.refusal`, `put`):
   1. a display sample (tagged, § 6.2);
   2. a damaged item (it would come back repaired);
   3. with `items.identity.enabled: false`: everything ("Item identity is off on this server");
   4. an item that doesn't resolve to a blueprint (renamed items, other plugins' items: "This item isn't in the item
      catalogue (<reason>)");
   5. a unique item (`INSTANCE`): "Unique items can't be put in a terminal in game yet";
   6. an enchanted vanilla item (`VANILLA_MATCH` with enchantments or stored enchantments), since it would come back
      without them.
3. The amount is taken out of the player's inventory and **held** while the API answers.
   `POST api/StorageContainers/{id}/put` (`SYS_WORLD` → storage, reason `Deposit`, mode `Partial`): what the API did not
   accept (full, distinct cap) goes back to the inventory, or is dropped at the player's feet when that is full.
4. A lost answer (no HTTP status) is sent again with the **same** key, once (`PUT_RETRIES`), so it applies at most once;
   if it is lost again the items go back to the player and the server log notes the key.

### 5.4 After a move and errors

1. One move at a time per view and per player (`begin`/`end`); drags in a terminal or display are cancelled.
2. After a move the open page is read again and every loaded display of the same storage is asked to refresh (§ 6.3).
3. API answers become messages (`TerminalMessages`): 403 "Only members of this storage's town, its owner and staff can
   use this terminal."; 409 `ProductionDisabled` "Production is switched off; the terminal moves nothing right now.";
   409 for a display "This container is a display, not a terminal."; other 409 and 423 "The storage is busy or locked";
   404 "This container is no longer bound."; no answer "The storage can't be reached right now". A short move says why:
   "the storage is full", "the storage can't hold another kind of item", "not enough in stock", "the storage is locked".

## 6. Display containers

### 6.1 The sample (`StorageContainerService.DisplaySampleAsync`)

1. Fill ratio: capacity used (Σ amount × storage weight of lines and unique items) ÷ `MaxUnits`, at most 1; 1 when the
   storage holds stock but has no cap; 0 when empty.
2. Filled slots: `round(fill × Slots)`, at least 1 when the storage holds anything.
3. Which blueprints: the largest stock lines first (at most one per slot, only the first `filled` of them), and their
   stacks by largest remainder over the filled slots, each shown blueprint at least one stack. Unique items are not
   sampled.

### 6.2 Writing it (`DisplayWriter`, `DisplayLayout`)

1. Full stacks of each blueprint's item, spread evenly over the inventory (a half-full chest looks half full, not packed
   at the top).
2. Every stack is tagged `knightsandkings:knk_display_sample`, so a terminal refuses it and nobody mistakes it for real
   stock.
3. Opening a display shows `DisplayView`, a read-only copy titled "Display: <name>"; every click and drag is cancelled.
4. Unbinding a display clears the block's inventory.

### 6.3 Refresh and throttle (`DisplayThrottle`)

1. A display is refreshed when its chunk loads, when it is opened, after a terminal move on the same storage, after
   `/knk storage bind` and after a reload (displays in loaded chunks).
2. At most one refresh per container every `production.storage.display-refresh-seconds` (30). A refresh asked for
   sooner is remembered and runs once the interval has passed, so the last change is never lost.
3. A display in an unloaded chunk is skipped; a 404 drops it from the index.
4. Stock that changes without a terminal (production, transport, the web app) shows at the next refresh trigger, not at
   once.

## 7. Protection

1. A bound block can't be broken: "This terminal is bound to <name>. Unbind it first (/knk storage unbind)."
2. Explosions (entities and blocks) leave bound blocks out.
3. Hoppers move nothing into or out of a bound block (`InventoryMoveItemEvent`, with a cheap chunk check first,
   `ContainerIndex.anyNear`). Proved on a real server by the scenario `storage-display-double-chest`.
4. Without `production.enabled` none of this runs: a bound block is a plain chest, and a display keeps its last sample
   without protection (unbind displays before switching production off for good).

## 8. Binding: `/knk storage` and the web app

`/knk storage bind <storage id> <terminal|display> [label]|unbind|info|reload`, node `knk.admin.world.production`
(`StorageAdminCommand`):

1. The sender looks at a chest, trapped chest or barrel within 6 blocks; the plugin sends the canonical half and
   whether it is double.
2. `bind` refuses a block that is already bound and a container with items in it (its own items are not stock and would
   be lost). Then `POST api/StorageContainers`; on success the binding goes into the index and a display is filled.
3. `unbind`: `DELETE api/StorageContainers/{id}` (the API's delete rule: `knk.admin.world` and `knk.admin.delete`, so
   staff need both nodes in the web; the game server's plugin key passes).
4. `info` asks the API (`GET api/StorageContainers/by-block`) and says when this server's index differs.
5. `reload` reads every binding now (after a change in the web app).
6. API errors: 400 "a system or transit storage, a double barrel, or an unknown storage", 403, 404, 409 "that block is
   already bound".

The API also has the dashboard type **StorageContainer** (World area) with the seeded form and display, but the web
app on `next` has no entity mapping for it yet ([#904](https://github.com/PandiO/knk-workspace/issues/904)), so binding
is in game or through the API. A binding made through the API reaches the game server at its next refresh or
`/knk storage reload`.

## 9. Schema, migration and access

Migration **`AddStorageContainers`** (`20261120185936`, after `AddSiegeShopCatalogue` of the siege shop chain) creates
one table, `storage_containers` (index `StorageId`, unique `WorldName, X, Y, Z`, cascade on storage delete), and
changes no existing row. Rolling back drops it; storages keep the last `MaxUnits` it wrote.

| Endpoints | Needs |
|---|---|
| `GET api/StorageContainers/{id}`, `GET …/by-block`, `POST …/search` | The World area (`knk.admin.world`), or the plugin key |
| `POST`, `PUT {id}` of `api/StorageContainers` | `knk.admin.world` and the dashboard change rule, or the plugin key |
| `DELETE api/StorageContainers/{id}` | `knk.admin.world` and `knk.admin.delete`, or the plugin key |
| `GET …/{id}/terminal`, `POST …/{id}/put`, `POST …/{id}/take`, `GET …/{id}/display` | The plugin key only; the player in `X-Acting-User-Id` (put and take require it) |
| `POST api/StructureMenus/search` | A logged-in user or the plugin key |
| `GET api/StructureMenus/{id}`, `GET …/{id}/orders` | Anyone; filtered by viewer (§ 3), orders 403 for non-members |
| `POST api/TransportOrders/{id}/retry` | `knk.admin.world`, or the plugin key |

The rules are pinned by `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and `DeleteAccessRulesTests`.

## 10. Tests, recovery and limitations

### 10.1 Tests

1. knk-web-api: `Tests/.../Services/Production/TerminalsAndMenusTests.cs` (the cap from slots, binding refusals,
   terminal put and take once per key for members and staff only, partial takes, the flag off, the display sample, the
   visitor's and the member's menu, the overview with statuses and filters, the public status, retry, the region bounds
   and yield source of #877), `Services/MenuTemplateProductionSeedTests.cs` (the menu seeds and the hub tile repair),
   `Migrations/AddStorageContainersTests.cs`, and the access tests above.
2. knk-plugin: `knk-core` `TerminalLogicTest` (index, layout, throttle, display layout, messages),
   `StructureMenuTextTest`; `knk-api-client` `StorageContainersApiImplTest`, `StructureMenusApiImplTest`; `knk-paper`
   `StorageTerminalModuleTest` (MockBukkit: opening, take, put, held items and the lost answer, refusals, displays,
   protection), `StructuresMenuFeatureTest`, `StorageAdminCommandTest`, `StorageTerminalConfigTest`; the scenario
   `storage-display-double-chest` ([plugin scenarios § 1](../guides/developer/plugin-scenarios.md)).
3. Manual: [smoke test § 7](../guides/production-storage-transport-smoke-test.md#7-phase-p6-terminals-displays-menus-commands-683-api-74-plugin-tier2),
   not run yet.

### 10.2 Recovery

1. **A binding made in the web app doesn't work in game.** `/knk storage reload`, or wait `refresh-minutes`.
   `/knk storage info` tells whether the API and the server agree.
2. **A put whose answer was lost twice.** The items went back to the player; the server log has the idempotency key.
   Check the storage's ledger for `terminal:<key>`: if the API applied it, the player has the items twice; take the
   surplus by hand.
3. **A display shows old stock.** Open it (asks a refresh) or wait for a terminal move or a chunk load; the interval
   is `display-refresh-seconds`.
4. **A storage's cap is wrong.** Its cap follows its containers only with `UnitsPerSlot` set; check the containers on
   the storage's page and save the storage to re-apply.
5. **A bound chest later extended to a double chest** (or a double chest cut to one): the row keeps its type and
   slots, and when the canonical half changes the binding is no longer found from the block. Unbind it before changing
   the chest (`/knk storage unbind`, or delete it in the web app), then bind it again.

### 10.3 Limitations

1. Unique items can't be put in or taken out of a terminal in game; they move through the web app (#897).
2. Opening the structure menu from a worker NPC waits for worker NPCs (#897); the menu opens from the overview only.
3. Backed mode is Later (#113). Notifications and `/knk transport` are #897.
4. Town membership is the permission node `knk.town.member.<id>` until town roles (#246).
5. A display refreshes on its triggers only; stock moved by production, transport or the web app shows later.
6. Display samples hold no unique items.
7. The overview is built in memory for every search, which is fine for hundreds of structures.

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#903).
