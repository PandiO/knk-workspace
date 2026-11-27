# API Contract: Production storage containers, structure menus and the order retry

**Status:** Current · **Last updated:** 2026-11-20 (first version, production P6 #683, docs PandiO/knk-workspace#903)
**Checked against:** knk-web-api `next` `a2865d75` (PR PandiO/knk-web-api#67; `Controllers/StorageContainersController.cs`,
`Controllers/StructureMenusController.cs`, `POST {id}/retry` in `Controllers/TransportOrdersController.cs`,
`Dtos/StorageContainerDtos.cs`, `Dtos/StructureMenuDtos.cs`, `Services/Stock/StorageContainerService.cs`,
`Services/Production/StructureMenuService.cs`, `ProductionViewer.cs`, `TransportService.RetryAsync`). Not released.
**Related:** [terminals architecture](../../architecture/production-storage-terminals.md) (capacity, viewers, terminal and
display flows, the menus), [production DESIGN § 6 and § 11.2](../production-storage-transport/DESIGN.md),
[admin guide](../../guides/admin/production-storage-admin-guide.md), [stock API contract](API_CONTRACT_STOCK.md)
(`StockResultDto`, idempotency), [transport API contract](API_CONTRACT_PRODUCTION_TRANSPORT.md) (orders, cancel),
[smoke test § 7.1](../../guides/production-storage-transport-smoke-test.md#71-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names, a **null field means "keep"** on update, errors `{ "error": "<reason>" }`, paged searches take
`PagedQueryDto` and answer `PagedResultDto<T>`. Status codes: 400 for a validation error, 403 for a viewer who may not,
404 for a missing row, 409 for a conflict. Times are UTC.

**The viewer.** The menu reads and the terminal routes act for a viewer: a logged-in web user, or the player the game
server names in the header **`X-Acting-User-Id`** (with the plugin key). A game-server call without that header, and an
anonymous call, is a visitor. Staff are users with `knk.admin.world`; a town's members hold `knk.town.member.<town id>`
(or `knk.town.member.*`) until town roles (#246). See the [architecture § 3](../../architecture/production-storage-terminals.md#3-who-sees-and-uses-what-m3).

## 1. Access

| Endpoints | Needs |
|---|---|
| `GET api/StorageContainers/{id}`, `GET api/StorageContainers/by-block`, `POST api/StorageContainers/search` | `knk.admin.world` (World area), or the plugin key |
| `POST api/StorageContainers`, `PUT api/StorageContainers/{id}` | `knk.admin.world` and the dashboard change rule, or the plugin key |
| `DELETE api/StorageContainers/{id}` | `knk.admin.world` and `knk.admin.delete`, or the plugin key |
| `GET api/StorageContainers/{id}/terminal`, `POST …/{id}/put`, `POST …/{id}/take`, `GET …/{id}/display` | The plugin key only |
| `POST api/StructureMenus/search` | A logged-in user, or the plugin key |
| `GET api/StructureMenus/{id}`, `GET api/StructureMenus/{id}/orders` | Anyone; the answer depends on the viewer |
| `POST api/TransportOrders/{id}/retry` | `knk.admin.world`, or the plugin key |

Binding (CRUD) and every read work while the game setting **Production enabled** (`Production:Enabled`) is off. Terminal
put and take and the retry answer **409** while it is off.

## 2. `api/StorageContainers`

### 2.1 `StorageContainerDto`

| Field | Type | Meaning |
|---|---|---|
| `id` | int | |
| `storageId`, `storage` | int, `{ id, name }` | The storage the block shows |
| `mode` | `Terminal` \| `Display` | |
| `containerType` | `Chest` \| `TrappedChest` \| `Barrel` | |
| `isDouble` | bool | Chests and trapped chests only |
| `slots` | int | Read only: 54 for a double chest, else 27 |
| `worldName`, `x`, `y`, `z` | string, int | The canonical block (the left half of a double chest); `worldName` at most 64 characters, `y` -64 to 320 |
| `label` | string? | At most 100 characters; `""` clears it |
| `createdByUserId`, `createdAt`, `updatedAt` | | Read only |
| `storageContainerSlots` | int | Read only: Σ slots of every container of the storage |
| `storageUnitsPerSlot` | int? | Read only: the storage's units per slot |
| `storageMaxUnits` | long? | Read only: the storage's cap after this write |

`StorageContainerListDto` (search): `id`, `storageId`, `storageName`, `mode`, `containerType`, `isDouble`, `slots`,
`worldName`, `x`, `y`, `z`, `label`.

### 2.2 Reads

1. `GET api/StorageContainers/{id}` → `StorageContainerDto`, 404 when missing.
2. `GET api/StorageContainers/by-block?world=<name>&x=<x>&y=<y>&z=<z>` → the container bound to that exact block, or
   404. The game server asks with the canonical block.
3. `POST api/StorageContainers/search` → `PagedResultDto<StorageContainerListDto>`. The search term matches the label,
   the storage's name and the world. Filters: `storageId`, `mode` (`Terminal`, `Display`), `worldName`. `sortBy`:
   `label`, `storage`, else the id.

### 2.3 `POST api/StorageContainers` (bind)

Body: `storageId`, `worldName`, `x`, `y`, `z` (required), `mode` (default `Terminal`), `containerType` (default `Chest`),
`isDouble`, `label`. Answers **201** with the `StorageContainerDto` (`Location` the new container). The storage's cap is
rewritten (§ 2.6). Errors:

1. 400: `storageId is required.`; `Storage <id> not found.`; `System and transit storages can't have containers.`; `A
   barrel can't be double; only chests and trapped chests are.`; a missing or too long `worldName`; missing `x`, `y` or
   `z`; `y` out of range; a too long label; an unknown mode or type.
2. 409: `That block is already bound (container <id>).` (also when the unique index catches a race: `That block is
   already bound.`).

### 2.4 `PUT api/StorageContainers/{id}`

The fields of § 2.3; a null field keeps the stored value. A new `storageId` moves the container: both storages' caps are
rewritten. 404 when missing; errors as in § 2.3; 409 `The storage changed while saving; try again.` on a concurrency
conflict.

### 2.5 `DELETE api/StorageContainers/{id}` (unbind)

**204**. The storage's cap is rewritten; unbinding the last container leaves the last value. 404 when missing.

### 2.6 The container-derived cap

For a capped storage with `unitsPerSlot` set and at least one container: `maxUnits = Σ slots × unitsPerSlot`, written on
bind, move, unbind, `PUT api/Storages/{id}` and a production structure's level change (Output storage). Otherwise the
storage keeps its fixed `maxUnits`.

### 2.7 `GET api/StorageContainers/{id}/terminal?page=1&pageSize=54` → `TerminalViewDto` (game server)

For the viewer in `X-Acting-User-Id`. Stock lines by blueprint name first, then the unique items; page size 1-54
(default 54).

| Field | Meaning |
|---|---|
| `containerId`, `storageId`, `storageName` | |
| `totalUnits`, `capacityUsed`, `maxUnits` | Raw units, capacity used (amount × storage weight), the cap (null = none) |
| `isLocked` | The storage is locked now |
| `page`, `pageSize`, `totalCount` | `totalCount` counts stock lines and unique items (each capped at 2000) |
| `entries` | `TerminalEntryDto[]`: `itemBlueprintId`, `itemBlueprintName`, `amount`, and for a unique item (amount 1) `itemInstanceId` and `customDisplayName` |

403 `{ "error": "Forbidden", "message": "Only members of the storage's town (or its player) and staff may use this
terminal." }`; 404 when missing; 409 `This container is a Display, not a Terminal.`

### 2.8 `POST api/StorageContainers/{id}/put` and `…/take` → `StockResultDto` (game server)

`X-Acting-User-Id` is required (400 `{ "error": "ActingUserRequired" }` without it). Body `TerminalMoveDto`:

| Field | Meaning |
|---|---|
| `itemBlueprintId` + `amount` | An amount (at least 1) of a blueprint, or … |
| `itemInstanceId` | … one unique item. Exactly one of the two |
| `idempotencyKey` | Required, at most 100 characters, one per click. Stored as `terminal:<key>`: a retry with the same key applies once (`replayed` true) |
| `mode` | `Partial` (default: moves what fits or what there is, reports the rest) or `AllOrNothing` |

A put moves `SYS_WORLD` → the storage with reason `Deposit`; a take the storage → `SYS_WORLD` with reason `Withdraw`.
Both are ledger transactions with actor kind `PluginServer`, the player as actor user, component `terminal` and source
`StorageContainer`/`<id>`. The answer is the stock core's `StockResultDto` (`status`, `transactionId`, `replayed`,
`accepted`, `lines` with `requested`, `accepted`, `rejected`, `rejectReason` such as `CapacityFull`,
`DistinctCapReached`, `NotEnoughStock`, `Locked`; see the [stock contract § 4](API_CONTRACT_STOCK.md#4-apistocktransactions-writes)).

Errors: 400 for a missing key, both or neither item field, an amount under 1; 403 as in § 2.7; 404; **409**
`{ "code": "ProductionDisabled" }` while production is off, `{ "code": "IdempotencyKeyReuse" }` for a key used for a
different move, a display (`This container is a Display, not a Terminal.`) and a concurrency conflict (`The storage
changed while saving; try again.`). A locked storage or a full one is not an error: the line comes back rejected with
its `rejectReason`.

### 2.9 `GET api/StorageContainers/{id}/display` → `DisplaySampleDto` (game server)

| Field | Meaning |
|---|---|
| `containerId`, `storageId`, `slots` | |
| `fillRatio` | 0..1: capacity used ÷ `maxUnits`; 1 when the storage holds stock and has no cap |
| `filledSlots` | `round(fillRatio × slots)`, at least 1 when there is stock |
| `items` | `[{ itemBlueprintId, itemBlueprintName, stacks }]`, largest stock first; Σ `stacks` = `filledSlots`; unique items are not sampled |

No viewer check: a display is public. 404 when missing; 409 `This container is not a display.`

## 3. `api/StructureMenus`

### 3.1 `StructureMenuRowDto` (public)

| Field | Meaning |
|---|---|
| `id`, `structureType` | `ProductionStructure` or `Warehouse` |
| `name`, `productionKindId`, `kindName` | `kindName` is `Warehouse` for a warehouse |
| `townId`, `townName`, `isRural` | The district's town, else the rural town |
| `level` | Production structures; null for a warehouse |
| `products` | The blueprint names of its lines |
| `status`, `statusText` | `Working`, `Stalled`, `NoRoad`, `Full` and the sentence for it ([architecture § 4.2](../../architecture/production-storage-terminals.md#42-the-public-status-structuremenuserviceproducerstatus)) |

### 3.2 `POST api/StructureMenus/search` → `PagedResultDto<StructureMenuRowDto>`

Every production structure and warehouse. The search term matches the name, the kind and the products. Filters:
`townId`, `productionKindId`, `structureType`, `status`. `sortBy`: `town`, `kind`, `status`, else the name. Page size
1-200.

### 3.3 `GET api/StructureMenus/{id}` → `StructureMenuDto`

The row of § 3.1 plus:

| Field | Meaning |
|---|---|
| `viewerSeesDetails` | Staff, or a member of the structure's town |
| `viewerIsStaff` | The viewer holds `knk.admin.world` (the menu shows the staff buttons) |
| `detail` | Only when `viewerSeesDetails`; null otherwise, so a visitor's answer holds no stock, rates, workers or orders |

`detail`: `workersPresent`, `workersTotal`, `workersAway` (carrying an order), `rates` (`productionLineId`,
`itemBlueprintId`, `itemBlueprintName`, `ratePerHour`, `status`, `notProducingReasons`), `storages` (`storageId`,
`name`, `purpose`, `totalUnits`, `maxUnits`, `lines`: the top 54 `TerminalEntryDto`s by amount), `warnings`,
`notProducingReasons`, `openOrderCount`. A warehouse has no rates or workers. 404 when the id is no production
structure or warehouse.

### 3.4 `GET api/StructureMenus/{id}/orders?page=1&pageSize=28` → `PagedResultDto<TransportOrderListDto>`

The structure's transport orders, newest first (the transport search with `structureId`; the row shape is the
[transport contract § 2.2](API_CONTRACT_PRODUCTION_TRANSPORT.md#22-post-apitransportorderssearch--pagedresultdtotransportorderlistdto)).
403 `{ "error": "Forbidden", … }` for a viewer who doesn't see details; 404 when missing.

## 4. `POST api/TransportOrders/{id}/retry` → `TransportOrderDto`

Staff retry (M4). By the order's status:

1. `Planned`, `AtStop`, `AwaitingSpace`, `ReturnBlocked`: the next step runs now (event `Note` "Retried now by user
   <id>."); answers the order.
2. `Returned`, `Cancelled`: a new manual order with the same source, carrier and planned stop amounts, note "Retry of
   transport #<id>.", `clientKey` `retry-of-<id>`; answers the **new** order. A second retry answers the same new order.

409: production off; `Delivered` ("there is nothing to retry"); `InTransit`, `Returning` ("it arrives at <eta>"); no
cargo to send again; the create refused it ("The order can't be sent again: …"); a status with nothing to retry. 404
for an unknown order.

## 5. Related changes in the same release

1. World task type **`CaptureRadius`** (#877): the production area form sends it for a Radius area; the plugin's
   handler completes it with `centerX`, `centerY`, `centerZ`, `radius` and the world.
2. `ProductionArea` with shape `Region` (#877): when `wgRegionId` is sent and a bound is empty, the bounds come from the
   region's stored outline (x and z from its points, y from its height); a bound that is sent wins.
3. `yieldSource` (#877) on the production world's structure list rows (`ProductionWorldListDto`): `Configured`, `Derived` or `Hybrid`, null for a
   warehouse.
4. Stock reason `Upgrade` in the `StockTransaction` form seed v2 (#881).

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#903).
