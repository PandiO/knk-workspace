# API Contract: Shops (shop types and levels, shops, the catalogue, buying and selling, trade stats, town accounts)

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P10 #248, docs PandiO/knk-workspace#939)
**Checked against:** knk-web-api `next` `289f4d4b` (PR PandiO/knk-web-api#74; `Controllers/ShopsControllers.cs`,
`Dtos/ShopDtos.cs`, `Enums/ShopEnums.cs`, `Services/Shops/*.cs`, `Services/Currency/CurrencyService.Town.cs`,
`Services/Territory/ProductionSettings.cs`). Not released.
**Related:** [shops architecture](../../architecture/shops.md) (pricing, the purchase and sale transactions, restocking,
processing, the town account, the stats), [shops DESIGN](../shops/DESIGN.md), [shops admin
guide](../../guides/admin/shops-admin-guide.md), [town logistics API contract](API_CONTRACT_TOWN_LOGISTICS.md) (the
setting source `ShopLevel`, structure type `Shop`), [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md)
(lines and the production view, which work for shops), [smoke test § 11.1](../../guides/production-storage-transport-smoke-test.md#111-steps-api)
(every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names (case-insensitive on input, numbers refused), paged searches take `PagedQueryDto` (page size 1-200,
default 20) and answer `PagedResultDto<T>`. Times are UTC. Amounts are raw units of the blueprint; prices and balances
are whole coins. `NamedRefDto` fields (`shopType`, `shop`, `itemBlueprint`, `town`, …) are read only. On create and
update a null field means "keep" (on create: the default); where a field says "0 clears it", 0 sets it to none.

**The switch.** With the API's game setting **Production enabled** (`Production:Enabled`) off, `sell-quote`, `sell`
and a purchase with `deliverTo: Inbox` answer 409 `{ "code": "ProductionDisabled", "error": ... }`, and the stats job
writes nothing. Everything else works.

**Status codes** (`ShopErrors`): 400 validation (`{ "error": ... }`), 403 a caller who may not, 404 a missing row
(`{ "error": ... }`; `GET {id}` answers a bare 404), 409 `{ "code": "<code>", "error": ... }` for a refusal (§ 5.4) or
`{ "error": ... }` for a conflict (a duplicate name, level or catalogue entry, a type in use, a shop that can't be
deleted).

## 1. Access

| Route | Plugin key | `knk.admin.world` | + other node |
|---|---|---|---|
| `GET` and `POST …/search` of every controller, `GET api/Shops`, `GET api/Shops/{id}/offer`, `GET api/TownAccounts/by-town/{townId}`, `GET api/TownAccounts/{id}/ledger` | yes | yes (any node of the World area) | — |
| `POST` and `PUT` of `api/ShopTypes`, `api/ShopTypeLevels`, `api/Shops`, `api/ShopCatalogueEntries` | yes | yes | the dashboard change rule of the type (`knk.admin.content`) |
| `POST api/ShopTradeStats/rebuild` | yes | yes | — |
| `DELETE` of `api/ShopTypes`, `api/ShopTypeLevels`, `api/Shops`, `api/ShopCatalogueEntries` | yes | yes | `knk.admin.delete` |
| `POST api/Shops/{id}/quote`, `…/purchase`, `…/sell-quote`, `…/sell` | yes | no | — |

Dashboard types (World area, with lookups): `ShopType`, `ShopTypeLevel`, `Shop`, `ShopCatalogueEntry` editable;
`ShopTradeStat` and `TownAccount` view only. Pinned in `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and
`DeleteAccessRulesTests`.

## 2. Shop types and levels

### 2.1 `api/ShopTypes`

| Method | Route | Answer |
|---|---|---|
| `GET` | `{id}` | `ShopTypeDto` with its categories and levels |
| `POST` | `search` | `ShopTypeListDto` (`id`, `name`, `defaultKind`, `isActive`, `acceptedCategoryCount`, `levelCount`); filter `isActive`; term = name; by name |
| `POST` | — | 201 `ShopTypeDto` |
| `PUT` | `{id}` | 200 `ShopTypeDto` |
| `DELETE` | `{id}` | 204; 409 while a shop uses the type |

`ShopTypeDto`:

| Field | Type | Notes |
|---|---|---|
| `id` | int? | Read only |
| `name` | string | Required on create; unique (409); at most 100 |
| `description` | string? | At most 500; `""` clears it |
| `defaultKind` | `Trading` \| `Processing` | Default `Trading`; a new shop without `kind` gets it |
| `isActive` | bool? | Default true |
| `acceptedCategoryIds` | int[]? | The categories it buys from players (a category also accepts its sub-categories). On `PUT` the list replaces the current one; null keeps it. An unknown id is 400 |
| `acceptedCategories` | `NamedRefDto[]` | Read only |
| `levels` | `ShopTypeLevelDto[]` | Read only, by level |
| `createdAt` | DateTime? | Read only |

### 2.2 `api/ShopTypeLevels`

| Method | Route | Answer |
|---|---|---|
| `GET` | `{id}` | `ShopTypeLevelDto` |
| `POST` | `search` | `ShopTypeLevelListDto` (`id`, `shopTypeId`, `shopTypeName`, `level`, `priceMultiplier`, `cycleSpeedMultiplier`, `yieldMultiplier`, `merchandiseMaxUnits`); filter `shopTypeId`; by type and level |
| `POST` | — | 201; also writes the caps to the storages of the type's shops at that level |
| `PUT` | `{id}` | 200; the same |
| `DELETE` | `{id}` | 204 (no check of the shops at that level) |

`ShopTypeLevelDto`:

| Field | Type | Notes |
|---|---|---|
| `id` | int? | Read only |
| `shopTypeId` / `shopType` | int? | Required on create; can't change (400) |
| `level` | int? | 1-100, unique per type (409) |
| `cycleSpeedMultiplier`, `yieldMultiplier`, `inputCostMultiplier`, `priceMultiplier` | decimal? | Above 0 and at most 100; default 1 |
| `merchandiseMaxUnits`, `inputMaxUnits` | long? | Storage caps in raw units; 0 clears it; negative is 400 |
| `unitsPerSlot` | int? | Raw units per bound container slot (both storages); 0 clears it |
| `reorderPointUnits`, `targetUnits` | long? | The default restocking min and max per stocked catalogue blueprint; 0 clears it; `targetUnits` below `reorderPointUnits` is 400 |

## 3. `api/Shops`

| Method | Route | Answer |
|---|---|---|
| `GET` | — | Every `ShopDto` |
| `GET` | `{id}` | `ShopDto` |
| `POST` | `search` | `ProductionWorldListDto` (the structure list row); filters `districtId`, `townId`, `isRural`, `shopTypeId`, `kind`; term = name or description |
| `POST` | — | 201 `ShopDto`, with the Merchandise and Input storages |
| `PUT` | `{id}` | 200 `ShopDto` |
| `DELETE` | `{id}` | 204; 409 while its storages hold stock or have ledger history, or its worker is out collecting |
| `GET` | `{id}/offer` | `ShopOfferDto` (§ 4.1) |
| `POST` | `{id}/quote`, `{id}/purchase` | § 4.2 |
| `POST` | `{id}/sell-quote`, `{id}/sell` | § 4.3 |

A shop is also a production structure: `api/ProductionStructures/{id}` (its worker, transport and road connection),
`api/ProductionStructures/{id}/production`, `…/workers` and `api/ProductionLines` work for it.

`ShopDto` carries every `StructureDto` field (name, description, placement: `districtId`, `streetId`, `houseNumber`
or rural with `townId`, …, as for any structure) plus:

| Field | Type | Notes |
|---|---|---|
| `shopTypeId` / `shopType` | int? | 0 clears it; an unknown id is 400 |
| `kind` | `Trading` \| `Processing` | On create without one: the type's `defaultKind`, else `Trading` |
| `level` | int? | 1-100, default 1; a change applies the new level's caps |
| `taxModifier` | decimal? | Above 0, at most 100; default 1 |
| `buyBackPercent` | decimal? | 0-100; default 50 |
| `shopkeeperLocationId` | int? | Where the shopkeeper spawns (P11); 0 clears it; an unknown location is 400 |
| `hideSoldOut` | bool? | Leave sold-out items out of the offer instead of `soldOut` |
| `productionEnabled` | bool? | The shop's own processing switch |
| `workersTotal` | int? | 0 to the production maximum; default 1 |
| `workersPresent` | int? | Read only |
| `transportCapacity` | int? | Units the worker carries per collection; 0 clears it (the planner's default) |
| `storages` | `StructureStorageNavDto[]` | Read only: the Input and Merchandise storages |
| `effectiveTownId` | int? | Read only: the district's town, else the shop's `townId`; its account gets the income |
| `catalogueEntryCount` | int? | Read only |

## 4. The catalogue, the offer, buying and selling

### 4.1 `api/ShopCatalogueEntries` and the offer

| Method | Route | Answer |
|---|---|---|
| `GET` | `{id}` | `ShopCatalogueEntryDto` |
| `POST` | `search` | `ShopCatalogueEntryListDto`; filters `shopId`, `itemBlueprintId`; term = blueprint name; by shop, pinned first, order |
| `POST` | — | 201 |
| `PUT` | `{id}` | 200; an entry keeps its shop and item (400 on a change) |
| `DELETE` | `{id}` | 204 |

`ShopCatalogueEntryDto`: `id`; `shopId` / `shop` (required); `itemBlueprintId` / `itemBlueprint` (required for a
stackable item; for a unique item it is the instance's blueprint, another one is 400); `itemInstanceId` (one unique
item, at most once across all shops, 409); `staticPrice` (coins per unit, 0-1,000,000,000, wins over the formula; 0
clears it); `stockMode` (`Stocked` default, or `Unlimited`, blueprints only, 400 for a unique item); `pinned`;
`sortOrder`; `enabled` (default true); `createdAt`. A blueprint twice in one shop is 409.

`GET api/Shops/{id}/offer` → `ShopOfferDto`: `shopId`, `shopName`, `kind`, `level`, `shopTypeName`, `townId`,
`townName`, `hideSoldOut`, `buysFromPlayers` (`Production:Enabled` and a type with accepted categories), `items[]`:

| Field | Notes |
|---|---|
| `catalogueEntryId` | Null for Merchandise stock without an entry |
| `itemBlueprintId`, `itemBlueprintName` | |
| `itemInstanceId` | One unique item (a bought-back item is resold as that exact item) |
| `unitPrice` | Coins |
| `priceSource` | `Static` or `Formula` (items without a price are left out) |
| `stock` | Units on sale; null = unlimited |
| `soldOut` | Stock 0 (left out when the shop hides sold-out items) |
| `pinned`, `sortOrder` | Entries without a row have `sortOrder` 2147483647 |
| `enchantments` | A unique item's enchantments, `"<name> <level>"` |

Order: enabled entries (pinned first, then `sortOrder`, then id), then Merchandise blueprints without an entry, then
unique items without an entry.

### 4.2 Buying

`POST api/Shops/{id}/quote` and `POST api/Shops/{id}/purchase` take `ShopPurchaseRequestDto`:

| Field | Type | Notes |
|---|---|---|
| `userId` | int | Required for a purchase |
| `catalogueEntryId` \| `itemInstanceId` \| `itemBlueprintId` | | One of them, checked in this order; none is 400 |
| `amount` | long | 1-100,000, default 1; a unique item 1 |
| `expectedUnitPrice` | long? | The price the player saw; another price is 409 `PriceChanged` |
| `confirmed` | bool | Must be true for a purchase (409 `NotConfirmed`) |
| `deliverTo` | `Inventory` \| `Inbox` | Default `Inventory` (the game server places the item after it checked the room); `Inbox` delivers through P7 and needs `Production:Enabled` |
| `idempotencyKey` | string | Required for a purchase: 1-60 of `A-Z a-z 0-9 : _ . -` |

The **quote** (`ShopQuoteDto`, changes nothing): `shopId`, `catalogueEntryId`, `itemBlueprintId`,
`itemBlueprintName`, `itemInstanceId`, `amount`, `unitPrice`, `totalPrice`, `priceSource`, `stock`, `refusal` (null =
can be bought; `NotForSale`, `SoldOut`, `NotEnoughStock`, `NoTown`) and `refusalMessage`. A catalogue entry of another
shop is 404.

The **purchase** (`ShopPurchaseResultDto`): `shopId`, `userId`, `itemBlueprintId`, `itemInstanceId`, `amount`,
`unitPrice`, `totalPrice`, `deliverTo`, `stockTransactionId`, `currencyTransactionId` (the posting's public id),
`itemDeliveryId` (for `Inbox`), `townId`, `coinsAfter` (the player's), `replayed` (true for a retry with the same
key). One database transaction: `SHOP_PURCHASE` player → town account, then the stock move `ShopSale` (Merchandise, or
`SYS_ADJUSTMENT` for an `Unlimited` entry, → `SYS_WORLD`), then the P7 delivery for `Inbox`; a failure in any part
rolls back all of them. Keys: `shop-buy:<idempotencyKey>` on the stock transaction and the posting,
`shop-buy:<idempotencyKey>:inbox` on the delivery.

### 4.3 Selling

`POST api/Shops/{id}/sell-quote` and `POST api/Shops/{id}/sell` take `ShopSellRequestDto`: `userId`, `lines[]`
(1-54; each `itemBlueprintId` and `amount` 1-100,000, or `itemInstanceId` with amount 1, an instance on one line
only), `expectedTotal` (the total the player saw; another total is 409 `PriceChanged`), `confirmed` (must be true for a
sale), `idempotencyKey` (required for a sale, as in § 4.2). Both need `Production:Enabled`.

The **sell quote** (`ShopSellQuoteDto`): `shopId`, `lines[]` (`lineNo` from 0, `itemBlueprintId`,
`itemBlueprintName`, `itemInstanceId`, `amount`, `unitPrice` (the buy-back price), `linePrice`, `refusal` (null =
accepted; `CategoryNotAccepted`, `NoPrice`, `NotResolved`, `InStorage`, `Soulbound`, `NoRoom`), `refusalMessage`),
`total` (of the accepted lines), `accepted` (every line accepted; a sale is all or nothing), `townCanPay`.

The **sale** (`ShopSellResultDto`): `shopId`, `userId`, `total`, `lines[]`, `stockTransactionIds[]`,
`currencyTransactionIds[]`, `coinsAfter`, `replayed`. Refused when a line is refused (409 with that line's code and
`Line <n>: …`), on `PriceChanged`, `NoTown` or `TownFundsInsufficient`. One database transaction, per line
`SHOP_BUYBACK` town account → player and the move `SYS_WORLD` → Merchandise (`ShopBuyBack`); keys
`shop-sell:<idempotencyKey>:<lineNo>`.

### 4.4 Refusal codes (409)

| Code | Where | Meaning |
|---|---|---|
| `ProductionDisabled` | `sell-quote`, `sell`, purchase to `Inbox` | `Production:Enabled` is off |
| `NotConfirmed` | `purchase`, `sell` | `confirmed` was not true |
| `PriceChanged` | `purchase`, `sell` | The price or total is not the one sent; confirm again |
| `NotForSale` | `purchase` | No such item on offer, the entry is switched off, or no price |
| `SoldOut`, `NotEnoughStock` | `purchase` | Not enough units in Merchandise (also when the last units went meanwhile) |
| `StorageLocked` | `purchase`, `sell` | The Merchandise storage is locked; nothing moved |
| `InsufficientFunds` | `purchase` | The player has too few coins |
| `InboxFull` | `purchase` to `Inbox` | No room in the player's inbox |
| `NoTown` | `purchase`, `sell` | The shop has no town |
| `TownFundsInsufficient` | `sell` | The town's account can't pay the total |
| `CategoryNotAccepted`, `NoPrice`, `NotResolved`, `InStorage`, `Soulbound`, `NoRoom` | `sell` | A line's refusal (`NoRoom` also when Merchandise is full) |
| `IdempotencyKeyReuse` | `purchase`, `sell` | The key was used by another player or for another shop |

A purchase or sale that was refused moved nothing.

## 5. `api/ShopTradeStats`

| Method | Route | Answer |
|---|---|---|
| `GET` | `{id}` (long) | `ShopTradeStatDto` |
| `POST` | `search` | `ShopTradeStatListDto`; filters `shopId`, `itemBlueprintId`, `from` and `to` (ISO times on `hourStart`; `from` inclusive, `to` exclusive); newest hour first |
| `POST` | `rebuild` | `ShopTradeStatRebuildDto` → `ShopTradeStatRebuildResultDto` |

`ShopTradeStatDto`: `id`, `shopId` / `shop`, `itemBlueprintId` / `itemBlueprint`, `hourStart` (UTC, on the hour),
`unitsSold`, `revenue`, `unitsBoughtBack`, `buyBackPaid`, `unitsSupplied` (production, transport and distribution into
Merchandise), `distinctCustomers`, `townPlayerCount` (null in V1), `avgSellPrice` (null without sales), `stockAtEnd`,
`computedAt`. The list row has `shopName`, `itemBlueprintName` and the unit and coin columns.

`ShopTradeStatRebuildDto`: `shopId` (null = every shop), `from`, `to` (whole UTC hours; `to` after `from`; at most 744
hours; `to` capped at the end of the current hour). Answer: `hours`, `rowsWritten`, `rowsDeleted`. Idempotent; works
while `Production:Enabled` is off. An unknown shop is 404.

## 6. `api/TownAccounts`

Read only: balances change through the currency ledger only.

| Method | Route | Answer |
|---|---|---|
| `GET` | `{id}` | `TownAccountDto` |
| `GET` | `by-town/{townId}` | `TownAccountDto`; 404 while the town has no account (it opens with the first posting) |
| `POST` | `search` | `TownAccountListDto` (`id`, `townId`, `townName`, `coins`, `updatedAt`); filter `townId`; term = town name; by town name |
| `GET` | `{id}/ledger?pageNumber=1&pageSize=50` | `PagedResultDto<TownAccountEntryDto>`, newest first |

`TownAccountDto`: `id`, `townId` / `town`, `coins`, `reconciled` (the last town leg's balance after equals `coins`),
`ledgerBalance`, `createdAt`, `updatedAt`.

`TownAccountEntryDto`: `entryId`, `transactionPublicId`, `reasonCode` (`SHOP_PURCHASE`, `SHOP_BUYBACK`), `amount` (+ in,
− out), `balanceBefore`, `balanceAfter`, `sourceType` (`ShopPurchase`, `ShopBuyBack`), `sourceRef` (the shop id),
`userId` (the player), `createdAt`.

**Currency.** A town leg is a `currency_entries` row with `accountKind` `Town` (2) and `townId`. The reasons
`SHOP_PURCHASE` (kind Spend) and `SHOP_BUYBACK` (kind Grant) post only through the shop routes; any other currency route
refuses them. Reversing a transaction with a town leg (`POST api/currency/admin/transactions/{publicId}/reverse`) is
400 `{ "code": "NotReversible" }` (the currency routes map this code to 400; [#934](https://github.com/PandiO/knk-workspace/issues/934)).

## 7. Game settings `production.shops`

In the production section of `GET`/`PUT api/GameSettings` (`knk.admin.config` to write); a `PUT` without `shops`
keeps the stored section.

| Key | Default | Allowed |
|---|---|---|
| `enchantmentPercentPerLevel` | 10 | 0-1000 (400 outside) |
| `statsLookbackHours` | 2 | 0-168 |

## 8. Related changes in other contracts

1. **Town logistics** ([contract](API_CONTRACT_TOWN_LOGISTICS.md)): the demand `settingSource` `ShopLevel` (a shop
   level's default min/max on a Merchandise storage); `consumerStructureType` and `structureType` `Shop` (#928).
2. **Stock** ([contract](API_CONTRACT_STOCK.md)): the stock reasons `ShopSale` and `ShopBuyBack`, transaction source
   type `Shop` with the shop id as `sourceRef`; `POST api/StockTransactions/search` with those filters lists a shop's
   sales and buy-backs.
3. **Item delivery** ([contract](API_CONTRACT_ITEM_DELIVERY.md)): the delivery reason `ShopPurchase`.
