# Shops: shop types, the catalogue, buying and selling, restocking, processing, the town account, the shop menus and display stalls (knk-web-api, knk-web-app and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-21 (§ 14: display stalls, production P12 #250, docs PandiO/knk-workspace#970; § 15 and § 16 renumbered); 2026-11-21 (§ 13: the shop menus of the plugin, production P10b #687, docs PandiO/knk-workspace#966); 2026-11-21 (first version, production P10 #248/#688, docs PandiO/knk-workspace#939)
**Checked against:** knk-web-api `next` `289f4d4b` (PR PandiO/knk-web-api#74) and `e02bf557` (PR PandiO/knk-web-api#75,
the P9 follow-ups that name shops as consumers) and `7c6dd7f5` (PR PandiO/knk-web-api#79, the menu seeds), knk-web-app
`next` `11832d6b` (PR PandiO/knk-web-app#73), knk-plugin `next` `c349a53c` (PR PandiO/knk-plugin#120); § 14 against
knk-web-api `next` `d86d6e1a` (PR PandiO/knk-web-api#80) and knk-plugin `next` `b31fceb6` (PR PandiO/knk-plugin#121). Not
released; the manual steps of the
[smoke test § 11](../guides/production-storage-transport-smoke-test.md#11-phase-p10-shops-248-api-687-plugin-menus-688-web-app-tier3)
have not been run live yet, nor those of § 11.4 (display stalls).
**Related:** [shops DESIGN § 2-5, § 9.1](../specs/shops/DESIGN.md) (the design: model, buying and selling, interim
pricing, levels, trade stats), [API contract](../specs/api/API_CONTRACT_SHOPS.md), [shops admin
guide](../guides/admin/shops-admin-guide.md), [town logistics](town-logistics.md) (the planner that restocks shops),
[production engine](production-engine.md) (lines, levels, workers), [production transport](production-transport.md)
(collection orders and carriers), [production world](production-world.md) (structures and placement),
[production item delivery](production-item-delivery.md) (delivery to the inbox), [stock core](stock-core.md) (storages
and the ledger), [currency DESIGN](../specs/currency-payments/DESIGN.md) (the currency ledger)

Phase P10 adds **shops**: structures that sell goods to players for coins and buy goods back. A shop has a **shop type**
(bakery, weaponsmith, …) that decides which item categories it buys from players and which **levels** it has, a
**kind** (**Trading**: sells goods as they are; **Processing**: turns inputs into goods first), a level, a tax modifier
and a buy-back percentage. Admins fill a **static catalogue** per shop. A player's coins go to the **town account** of
the shop's town, and buy-backs are paid from it. The town planner **restocks** a shop from the town's warehouses with
the shop's own worker; a Processing shop runs **processing lines** on the production engine; **hourly trade stats** are
rolled up from the ledger for the later supply-and-demand pricing.

The game server part is the **shop menus** of link L26 ([#687](https://github.com/PandiO/knk-workspace/issues/687),
§ 13): the shop menu, the item information menu, the purchase confirmation and the sell menu, which call the purchase
and sale routes with the plugin key. Until shopkeepers arrive ([#249](https://github.com/PandiO/knk-workspace/issues/249))
a shop is opened with `/knk shop <shop id>`. No plugin `config.yml` key belongs to P10 or P10b.

**The switch.** Admin writes and buying from the catalogue work while the API's game setting **Production enabled**
(`Production:Enabled`) is off. Selling to a shop, delivery to the inbox, restocking, processing and the stats job need
it on (A21).

## 1. Ownership

| Part | Where | Owns |
|---|---|---|
| `Shop`, `ShopType`, `ShopTypeCategory`, `ShopTypeLevel`, `ShopCatalogueEntry`, `ShopTradeStat`, `TownAccount` | knk-web-api `Models/Shops/Shop.cs` | The seven tables of migration `AddShops` (§ 2) |
| Enums | `Enums/ShopEnums.cs` | `ShopKind` (`Trading`, `Processing`), `ShopDeliveryTarget` (`Inventory`, `Inbox`), `ShopStockMode` (`Stocked`, `Unlimited`), stored as strings |
| `ShopTypeService`, `ShopService`, `ShopLevels` | `Services/Shops/ShopAdminServices.cs` | Shop types with accepted categories, levels and their caps, shops (a `StructureSubtypeService` with the two storages on create) |
| `ShopCatalogueService`, `ShopTradeStatService`, `ShopTradeStatSweepService`, `TownAccountService` | `Services/Shops/ShopRecordsServices.cs` | The catalogue, the hourly stats with the job every 10 minutes, town account reads |
| `ShopPricing` | `Services/Shops/ShopPricing.cs` | The interim price rule (§ 4) |
| `ShopTradingService` | `Services/Shops/ShopTradingService.cs` | Offer, quote, purchase, sell quote and sale (§ 5, § 6) |
| `ICurrencyTownService.PostWithTownAsync` | `Services/Currency/CurrencyService.Town.cs` (a partial of `CurrencyService`) | Postings between players and a town's account (§ 9) |
| Currency reasons | `Services/Currency/CurrencyReasons.cs` | `SHOP_PURCHASE`, `SHOP_BUYBACK` (`IsTownReason`) and their nominal counterpart `SYS_SHOPS` |
| Engine hook | `Services/Production/ProductionEngine.cs` | A shop's lines produce into Merchandise at the shop level's speed, yield and input cost; a Trading shop's lines are paused (§ 8) |
| Planner hook | `Services/Logistics/LogisticsTownState.cs` | A shop level's default min/max for the stocked catalogue blueprints, source `ShopLevel` (§ 7) |
| Structure type names | `Services/Logistics/LogisticsStructureTypes.cs` (#928) | `Shop` in plan entries, reservations and service areas (checked before `ProductionStructure`) |
| Controllers | `Controllers/ShopsControllers.cs` | `api/ShopTypes`, `api/ShopTypeLevels`, `api/Shops`, `api/ShopCatalogueEntries`, `api/ShopTradeStats`, `api/TownAccounts` ([API contract](../specs/api/API_CONTRACT_SHOPS.md)) |
| `ProductionSettings.ValidateShops` | `Services/Territory/ProductionSettings.cs` | The game settings section `production.shops` (§ 10) |
| Seeds (G17) | knk-web-api form and display seeds `ShopType`, `ShopTypeLevel`, `Shop`, `ShopCatalogueEntry`, `ShopTradeStat`, `TownAccount` | The generic forms and detail pages (the join `ShopTypeCategory` has none) |
| Web app types and clients | knk-web-app `src/types/dtos/production/ShopDtos.ts`, `src/apiClients/shop*Client.ts`, `townAccountClient.ts` | Mirrors of `ShopDtos.cs` and `ShopEnums.cs`; registry rows in `entityApiMapping` and `objectConfigs` |
| Web app panels | `src/components/shops/` | `ShopTypePanel`, `ShopPanel` with `ShopCatalogueEditor` and `ShopTradeStatsPanel`, `TownAccountPanel`, mounted below the generic detail pages in `src/pages/DisplayWizardPage.tsx` |
| Client-side checks and labels | `src/utils/shops.ts` | The API's level and catalogue checks mirrored before a save, `formatCoins`, `priceSourceLabel`, `formatUtcHour` |
| Menu seeds | knk-web-api `Models/Menu/MenuTemplateSeed.Shops.cs` | The menu templates `shops.shop`, `shops.item`, `shops.confirm` (§ 13.2) |
| Plugin records and texts | knk-plugin knk-core `production/shop/` | `ShopOffer`, `ShopOfferItem`, `ShopQuote`, the purchase and sell requests and results, `ShopItemRef`, `ShopAmounts`, `SellBasket`, `SellMenuLayout`, `ShopKeys`, `ShopMenuKeys`, `ShopRefusal`, `ShopText`; the port `core/ports/api/ShopsApi` |
| Plugin API client | knk-api-client `ShopDtos`, `ShopMapper`, `ShopsApiImpl` | `offer`, `quote`, `purchase`, `sell-quote`, `sell` with the plugin key |
| Plugin menus | knk-paper `production/shop/` | `ShopMenuFeature` (the menu engine ids), `ShopService` (offer, quote, amount, purchase), `ShopView`, `ShopOfferRow`, `SellModule` and `SellView` (the sell menu); `commands/ShopAdminCommand` (`/knk shop`); the blocks in `KnKPlugin` |

## 2. Data model

One additive migration, `20261121041739_AddShops`, one contiguous block in `KnKDbContext` (no `DbSet` properties).

| Table | Row | Keys and lifetime |
|---|---|---|
| `shops` | A shop: `ShopTypeId` (nullable), `Kind`, `TaxModifier` (default 1), `BuyBackPercent` (default 50), `ShopkeeperLocationId` (P11), `HideSoldOut` | TPT subtype of `production_structures` (and so of `structures`): the shop's row sits next to its production structure row. Its level is `ProductionStructure.Level`; `ProductionKindId` stays empty. A shop type in use can't be deleted (Restrict) |
| `shop_types` | `Name` (unique, 100), `Description` (500), `DefaultKind`, `IsActive`, `CreatedAt` | — |
| `shop_type_categories` | Join: one accepted category of a type | Unique per type and category; deleted with the type. Edited only through the type's `acceptedCategoryIds` |
| `shop_type_levels` | One level of a type: `Level` (1-100), `CycleSpeedMultiplier`, `YieldMultiplier`, `InputCostMultiplier`, `PriceMultiplier` (each above 0, at most 100), `MerchandiseMaxUnits`, `InputMaxUnits`, `UnitsPerSlot`, `ReorderPointUnits`, `TargetUnits` (nullable) | Unique per type and level; deleted with the type. The number of levels is free; levels are set by admins, no upgrade costs in V1 (L25 decision 7) |
| `shop_catalogue_entries` | `ShopId`, `ItemBlueprintId`, optional `ItemInstanceId`, `StaticPrice` (nullable, at most 1,000,000,000), `StockMode`, `Pinned`, `SortOrder`, `Enabled`, `CreatedAt` | A blueprint at most once per shop, an item instance at most once across all shops (both checked by the service); deleted with the shop |
| `shop_trade_stats` | One shop, blueprint and UTC hour: units sold, revenue, units bought back, buy-back paid, units supplied, distinct customers, `TownPlayerCount` (null in V1), average sell price, stock at the end, `ComputedAt` | Unique per shop, blueprint and hour; deleted with the shop; hours without trade have no row (§ 11) |
| `town_accounts` | One per town: `Coins`, `CreatedAt`, `UpdatedAt` | Created with the town's first posting; changed only through the currency ledger; never below 0 (§ 9) |

The migration also adds the nullable column `currency_entries.TownId` and replaces the check
`CK_currency_entries_Account` with one that has a third case for town legs (every existing row still passes). No data
is written.

**Why `Shop : ProductionStructure`.** The design says `Shop : Structure`. L25 made it a subtype of
`ProductionStructure` (still a `Structure` subtype) so a shop reuses the producer's worker, the transport carrier FK
and the production engine without changing any FK (L25 decision 1, to be reviewed by the developer). Consequences:
shops also appear in `api/ProductionStructures` and its dashboard type; a shop is created with automatic transport off
(its worker only collects, never ships goods away), yield source `Configured` (never surveyed) and one worker.

## 3. Shop types, levels and shops

1. **Accepted categories.** A shop type buys from players only items whose blueprint category, or one of its parent
   categories, is in its list (a weaponsmith that accepts Weapons also buys Swords under Weapons). A type without
   categories buys nothing; a shop without a type buys nothing and uses level multiplier 1. `PUT` with
   `acceptedCategoryIds` replaces the whole list; leaving it out keeps it. The web app saves only `{ id,
   acceptedCategoryIds }` so it can't overwrite a concurrent edit (L27 decision 3).
2. **Levels** follow the production level pattern (PRODUCTION_KINDS § 5): processing speed, yield and input cost, the
   price multiplier, the Merchandise and Input caps, units per bound container slot, and the default min/max for
   restocking. On the API a cap of 0 clears it (no cap). Saving a level (create or update) writes its caps and units
   per slot to the storages of every shop of that type at that level; a null cap leaves the storage's current cap.
   Deleting a level doesn't check shops: shops at that level then use multiplier 1, no default min/max, and keep the
   caps they had.
3. **Shops** carry every structure field (placement as for any structure, [production world](production-world.md)).
   On create a shop gets a **Merchandise** and an **Input** storage (`Domain` storages named after the shop), capped
   by its level if the type has that level; one worker (`workersTotal` and `workersPresent` 1); the kind from the
   type's `defaultKind` when none is given. Changing the type or level later applies the new level's caps. Changing the
   level, type, workers, kind or the processing switch first settles the shop's processing up to now at the old
   values ([production engine](production-engine.md)).
4. **The shop's town** is its district's town, else its own `TownId` (a rural shop with the town set). Its income goes
   to that town's account (`effectiveTownId` on `ShopDto`). A shop without a town can't sell (`NoTown`).
5. **Deleting a shop** is refused (409) while its storages hold stock or have ledger history, or while its worker is
   out carrying goods.

## 4. Interim pricing

Until the supply-and-demand model ([#120](https://github.com/PandiO/knk-workspace/issues/120)), shops DESIGN § 4:

```
sell price   = static catalogue price, when an admin set one (> 0)
             | round(base price × enchantment factor × shop tax modifier × level price multiplier)
base price   = midpoint of the blueprint's BasePriceMin and BasePriceMax (F1)
enchantments = 1 + Σ enchantment levels × production.shops.enchantmentPercentPerLevel (10) / 100, unique items only (F3)
buy-back     = floor(sell price × BuyBackPercent / 100)                                   (default 50%)
```

1. Coins are whole numbers. A formula price is rounded half away from zero and is at least 1 when the base price is
   above 0. A buy-back is rounded down: the town never pays more than the percentage.
2. A blueprint without a base price and without a static price has no price (`priceSource` `None`): it is not on
   offer and the shop doesn't buy it (`NoPrice`).
3. A static price wins for buying too: the buy-back is that price × the percentage. Static prices apply to entries that
   are enabled.
4. Worked example (smoke § 11.1 step 9): Iron ore with base price 18-22 (midpoint 20) at level 2 (price × 1.5) and tax
   modifier 1.1 sells at round(20 × 1.1 × 1.5) = 33; a Diamond sword (base 100) with Sharpness 2 and Unbreaking 1
   sells at 100 × 1.3 = 130 and is bought back for 65.
5. The trade stats are recorded, but V1 pricing reads none of them.

## 5. The offer and buying

### 5.1 The offer

`GET api/Shops/{id}/offer` (`ShopOfferDto`) lists what a player can buy now, in this order:

1. The enabled catalogue entries: pinned first, then by `sortOrder`, then by id. A blueprint entry in `Stocked` mode
   shows the units of that blueprint in Merchandise; an `Unlimited` entry shows `stock: null` and is never sold out. An
   item-instance entry shows stock 1 while the instance is in Merchandise, else 0.
2. What is in Merchandise without an entry: restocked or processed blueprints, then bought-back unique items, at the
   formula price. A bought-back unique item is offered as that exact item, with its enchantments ("Sharpness 2").
3. Items without a price are left out. Sold-out items are listed with `soldOut: true` (the menus grey them out),
   unless the shop has `hideSoldOut`, which leaves them out (F5).

`buysFromPlayers` is true when `Production:Enabled` is on and the shop's type has at least one accepted category.

### 5.2 Quote, confirm, purchase

1. **Quote** (`POST …/quote`, plugin key) prices a purchase now and changes nothing: the item is a catalogue entry, a
   unique item (`itemInstanceId`, amount 1) or a blueprint from the offer. `refusal` says why it can't be bought:
   `NotForSale` (no such item, the entry is switched off, or no price), `SoldOut`, `NotEnoughStock`, `NoTown`. Amount
   1 to 100,000.
2. **Purchase** (`POST …/purchase`, plugin key) needs `confirmed: true` (`NotConfirmed`) and the `expectedUnitPrice`
   the player saw: a changed price is 409 `PriceChanged` so the player confirms again (L25 decision 4; a stored quote
   token was the alternative). It then checks the quote's refusals, the player's coins (`InsufficientFunds`) and, for
   `deliverTo: Inbox`, the room in the player's inbox (`InboxFull`).
3. **One database transaction** (read committed), coins first, then goods, the lock order of a P7 delivery (L25
   decision 6):
   1. `PostWithTownAsync`: `SHOP_PURCHASE`, the player −total, the town account +total (§ 9). Source
      `ShopPurchase` / the shop id, initiator the player.
   2. The stock move, reason `ShopSale`, all or nothing: Merchandise → `SYS_WORLD`, or for an `Unlimited` blueprint
      entry `SYS_ADJUSTMENT` → `SYS_WORLD`. Source `Shop` / the shop id, actor kind `PluginServer`, actor the player,
      component `shops`. A refused move (the last units went meanwhile, or the storage is locked) throws
      `NotEnoughStock` or `StorageLocked` and rolls the payment back: nothing is taken without the item.
   3. A unique item gets the player as owner (its owner count rises when the owner changes).
   4. `deliverTo: Inbox`: a P7 delivery (`ItemDeliveryReason.ShopPurchase`, key `<key>:inbox`) into the player's
      inbox; a lost unit is `InboxFull` and rolls everything back. `deliverTo: Inventory` (the default): the game server
      places the item itself, after it checked the player's room.
4. **Idempotency.** `idempotencyKey` is required (1-60 of `A-Z a-z 0-9 : _ . -`). The stock transaction and the
   currency posting use `shop-buy:<key>`. A retry with the same key returns the first result with `replayed: true`;
   the same key from another player or for another shop is 409 `IdempotencyKeyReuse`.
5. Buying works with `Production:Enabled` off, except delivery to the inbox (409 `ProductionDisabled`). This is why
   `Unlimited` exists: a catalogue can sell before the supply chain runs (L25 decision 5).
6. The MySQL tests (`ShopsMySqlTests`) cover two players racing for the last units (one is charged) and a purchase
   whose goods can't be taken (its payment rolls back).

## 6. Selling to a shop

1. **Sell quote** (`POST …/sell-quote`, plugin key, needs `Production:Enabled`) prices up to 54 lines: a stackable
   blueprint and amount (1 to 100,000), or one unique item (`itemInstanceId`, amount 1, once per sale). Per line the
   buy-back price or a refusal: `CategoryNotAccepted`, `NoPrice`, `NotResolved` (no such blueprint or instance),
   `InStorage` (the instance is already in a storage, not in the player's hands), `Soulbound`, `NoRoom` (the shop has
   no Merchandise storage). `accepted` is true only when every line is accepted; `townCanPay` when the town's account
   holds the total.
2. **Sale** (`POST …/sell`, plugin key) is all lines or none: `confirmed: true`, the `expectedTotal` the player saw
   (`PriceChanged`), a town (`NoTown`) whose account can pay (`TownFundsInsufficient`; L25 decision 3: the town pays,
   nothing is minted).
3. **One database transaction**; per line, with key `shop-sell:<key>:<lineNo>`:
   1. `PostWithTownAsync`: `SHOP_BUYBACK`, the player +line price, the town account −line price. Source
      `ShopBuyBack` / the shop id.
   2. The stock move `SYS_WORLD` → Merchandise, reason `ShopBuyBack`, all or nothing. A full Merchandise storage is
      `NoRoom`, a locked one `StorageLocked`; either rolls the whole sale back.
   3. A unique item becomes a `StockUnit` in Merchandise with its enchantments, its owner cleared; the offer resells
      that exact item.
4. A retry with the same key returns the stored lines with `replayed: true`.
5. A new town's account starts at 0, so a shop can buy back only after its town has earned coins from sales.

## 7. Restocking (reserve and collect)

A shop is a **consumer** of the [town logistics planner](town-logistics.md) through its Merchandise storage, and its own
worker collects, as any production structure's (TOWN_LOGISTICS § 5, D-L1):

1. For each enabled, `Stocked`, blueprint catalogue entry, the planner adds a demand line on the shop's Merchandise
   storage with the shop level's `reorderPointUnits` (min, 0 when empty) and `targetUnits` (max), source `ShopLevel`
   (`LogisticsTownState.ShopDefaults`). A level without `targetUnits` gives no default. `Unlimited` entries, unique
   items and goods without an entry are not restocked.
2. Precedence per storage and blueprint, the first that exists wins: the consumer's own replenishment **Setting**, a
   **Replenishment rule** (a category, tag or `Any` rule also matches the shop's stocked blueprints), the shop level
   default (**ShopLevel**), the line **Inputs** (Input storages only).
3. The Input storage of a Processing shop is restocked like any production structure's: from its lines' inputs, or a
   setting or rule.
4. The planner reserves at a warehouse up to the max and makes a collection order (origin `Distribution`) carried by
   the shop (carrier = the shop). While the worker is away, processing slows; selling goes on (F6). Deliveries into
   Merchandise count as supply in the trade stats.
5. Restocking needs `Production:Enabled`, a warehouse in the town and a road connection or lane, as in
   [town logistics § 1](town-logistics.md).

## 8. Processing

1. A **Processing** shop's lines ([production engine](production-engine.md), `api/ProductionLines`) consume from its
   Input storage and produce into its **Merchandise** storage (`ProductionEngine.OutputPurposeOf`), not an Output
   storage.
2. The shop type's level sets the cycle speed and yield (read as a production kind level) and the input cost (inputs
   per hour × `inputCostMultiplier`). Smoke § 11.1 step 24: with yield × 1.5 and input cost × 0.5, an hour gives 15 Iron
   ore for 10 Coal instead of 10 for 20.
3. A **Trading** shop's lines are `Paused` ("A trading shop doesn't process; make it a Processing shop to run its
   lines."), and its production view lists "A trading shop doesn't process." as a reason.
4. The worker factor, the processing switch (`productionEnabled`) and `Production:Enabled` work as for any production
   structure: `api/ProductionStructures/{id}/production` and `…/workers` work for shops.

## 9. The town account

1. **Model.** Currency `CurrencyAccountKind.Town = 2`: a town leg in `currency_entries` names the town (`TownId`) and
   records its balance before and after, like a user leg. `town_accounts.Coins` holds the balance. The account is
   created with the town's first posting (`EnsureTownAccountAsync`). Coins only.
2. **Posting.** `ICurrencyTownService.PostWithTownAsync(townId, legs, ctx)` on the same `CurrencyService`: the user legs
   are balanced by one town leg (−Σ user legs). Only the town reasons are allowed (`SHOP_PURCHASE` with negative user
   legs, `SHOP_BUYBACK` with positive ones); the other currency routes refuse them. It locks the users first, then the
   town account (`SELECT … FOR UPDATE`); the account never goes below 0 (`InsufficientFunds` with `townId` in the
   details, which the shop routes turn into `TownFundsInsufficient`). Idempotent like every posting; it runs inside the
   caller's transaction. A refused posting puts the account's balance back.
3. **Reversal.** A reversal of a transaction with a town leg is refused with `NotReversible` (HTTP 400 on the currency admin route): a correction is a new shop
   posting. Reversal and staff corrections of town legs are
   [#934](https://github.com/PandiO/knk-workspace/issues/934).
4. **Reads.** `api/TownAccounts`: by id, `by-town/{townId}`, `search`, and `{id}/ledger` (the town legs newest first,
   with reason, amount, balances, source, the player as `userId`). `reconciled` is true when the last town leg's
   balance after equals `Coins`.
5. No other currency behaviour changed. Trade, tax and spending from town accounts are Later
   ([#124](https://github.com/PandiO/knk-workspace/issues/124)).

L25 decision 2 chose town legs with balances over a system account string per town (no balance or floor) or a coins
column on `towns`.

## 10. Settings and access

**Game settings section `production.shops`** (part of the production settings, `PUT api/GameSettings`; a save without
the section keeps the stored one). No web app card yet.

| Key | Default | Allowed | Effect |
|---|---|---|---|
| `enchantmentPercentPerLevel` | 10 | 0-1000 | A unique item's price rises by this percent of the base price per enchantment level |
| `statsLookbackHours` | 2 | 0-168 | The stats job also recomputes this many earlier hours (late ledger rows) |

No `api.env` key and no plugin `config.yml` key.

**Access** (dashboard types in the World area, with lookups; pinned in `ReadAccessRulesTests`,
`DashboardChangeAccessRulesTests` and `DeleteAccessRulesTests`):

| Route | Plugin key | Staff |
|---|---|---|
| Reads (`GET`, `search`, `offer`, `ledger`, `by-town`) | yes | any node of the World area |
| Create and update shop types, levels, shops, catalogue entries | yes | `knk.admin.world` and the dashboard change rule (`knk.admin.content`) |
| `POST api/ShopTradeStats/rebuild` | yes | `knk.admin.world` |
| Deletes | yes | `knk.admin.world` and `knk.admin.delete` |
| `quote`, `purchase`, `sell-quote`, `sell` | yes | no (the game server acts for the player after the player confirmed) |

The web app hides the shop panels without `knk.admin.world` and turns off creates and edits without `knk.admin.content`
and deletes without `knk.admin.delete`, with the node named (L27 decision 5).

## 11. Trade stats

1. **Rows** per shop, blueprint and UTC hour (shops DESIGN § 9.1), built from the ledger so they can be rebuilt at any
   time:
   1. **Sold** and **revenue**: the shop's `ShopSale` moves out of Merchandise, plus its `Unlimited` sales (`ShopSale`
      transactions with source Shop / the shop id from `SYS_ADJUSTMENT`); the revenue is the player legs of the
      currency posting with the same idempotency key.
   2. **Bought back** and **paid**: `ShopBuyBack` moves into Merchandise and their postings.
   3. **Supplied**: moves into Merchandise with reason `Production`, `TransportDeliver` or `Distribution`.
   4. **Distinct customers** (actors of the sales), **average sell price** (revenue ÷ units sold, null without sales),
      **stock at the end** of the hour (the stock now, less what came in since, plus what went out since).
      `townPlayerCount` is null while towns have no member count.
2. **The job** (`ShopTradeStatSweepService`) runs every 10 minutes while `Production:Enabled` is on and recomputes the
   last completed hours (`statsLookbackHours` + 1 hours before the current one). It is idempotent: the rows of each shop
   and hour in the range are replaced.
3. **Rebuild** (`POST api/ShopTradeStats/rebuild`): whole UTC hours `from` (inclusive) to `to` (exclusive, capped at
   the end of the current hour), one shop or all, at most 744 hours; works while the switch is off.
4. V1 pricing doesn't read the stats; they are there for the supply-and-demand model (#120).

## 12. The web app (L27, #688)

1. **No own pages.** The entities use the generic dashboard, forms and detail pages with L25's seeds (G17); the panels
   are mounted below the detail pages (L27 decision 1):
   1. `/display/ShopType/<id>`: `ShopTypePanel` (**Accepted categories and levels**): the categories as chips with a
      Category picker and **Save the categories**; the **Levels** table with Add, Edit and Delete, the API's checks run
      first in `src/utils/shops.ts`.
   2. `/display/Shop/<id>`: `ShopPanel` (kind, type and level, prices, worker, storages, the town account and balance,
      **Offer now** from `offer`, **Sales and buy-backs** from `POST api/StockTransactions/search` with source Shop and
      the shop id), `ShopCatalogueEditor` (**Catalogue**), `ShopTradeStatsPanel` (**Trade stats per hour**: an inline
      SVG bar chart of sold, bought back and supplied per UTC hour over 24 hours, 7 or 30 days, one item or all, totals,
      rows, **Rebuild from the ledger**; L27 decision 2: no chart library). Below them the production view
      (`StructureProductionPanel`, P3b) and the consumer panel (`StructureLogisticsPanel`, P9b), because a shop is a
      production structure.
   3. `/display/TownAccount/<id>`: `TownAccountPanel` (**Balance and ledger**, pages of 25).
2. Small additive types: `StockReason` gains `Upgrade`, `ShopSale`, `ShopBuyBack`; `LogisticsSettingSource` gains
   `ShopLevel`.
3. Tests: Jest `src/utils/__tests__/shops.test.ts`, `src/apiClients/__tests__/shopClients.test.ts`; Playwright
   `e2e/shops.spec.ts` with DTO-typed mocks in `e2e/fixtures/shops.ts` (a strict spec that opens a shop page needs
   `mockShopPage(api)`, which also mocks the production and consumer panels).

## 13. The game server: shop menus (L26, #687)

Everything here runs only with the plugin's `production.enabled: true` (A21). The layouts are the legacy V1 shop menus
(developer decision 2026-11-21 on #687; [legacy inventory-menu-screens § 3.7](../specs/legacy/inventory-menu-screens.md)),
with the deviations of § 13.6 for the developer's review. Player view: [menus player guide § Shops](../guides/users/menus-player-guide.md#shops).

### 13.1 Opening a shop

1. `ShopService.open(player, shopId)` reads `GET api/Shops/{id}/offer`, then opens `shops.shop` with `ctx.shopId`.
   `/knk shop <shop id>` (`ShopAdminCommand`, node `knk.admin.world.production`, like `/knk storage`) calls it until
   shopkeepers (P11, [#249](https://github.com/PandiO/knk-workspace/issues/249)) do; a shopkeeper needs no menu change.
2. Refused: a player in a siege ("Shops are closed to you during a siege."), an unknown shop (404: "There is no shop
   #<id>."), the console ("Only players can open a shop."), and with the flag off ("Production is off on this server
   (production.enabled: false).").
3. **State.** The menu providers run on the main thread and never wait for the API: they read what the last call left
   (the offer per shop and the quote per player, item and amount, each kept 10 seconds) and start a call when nothing
   is there; when it lands, the open shop menus repaint. After a trade the shop's offer and quotes are dropped, so the
   menus read them again. A player's amounts and price notes are forgotten when they quit.

### 13.2 The menus and the engine ids

The three seeded menus (knk-web-api `MenuTemplateSeed.Shops.cs`, create-only like every menu seed) use ids that
`ShopMenuFeature` registers. It is always registered, so the seeds validate also with the flag off; then the services
are null, `KnKPlugin` blocks the three menus ("production is switched off"), the sources are empty, the conditions deny
and the actions say production is off.

| Menu | Size | Slots | Context |
|---|---|---|---|
| `shops.shop` (V1 "Products of X") | 6 rows, dynamic (at least 2) | 0 Financial (coins), 3 Sell chest (condition `shops.buys`, action `shops.sell`), 4 the shop's information, 8 Back; rows 2-5 the catalogue (row source `shops.offer`), pager in 45 and 53; a row click opens `shops.item` | `ctx.shopId` |
| `shops.item` (V1 item info) | 1 row | 0 Financial, 3 Amount (action `shops.amount`), 4 the item (row source `shops.item`), 5 the price (name tag; click condition `shops.buyable`, opens `shops.confirm` with `ctx.amount`), 6 the description, 8 Back | `ctx.shopId`, `ctx.item` |
| `shops.confirm` (V1 sale confirmation) | 2 rows | 4 the confirmation (book: amount, price each, total, a changed price, a refusal), 8 Back, 10 Confirm to the reward inbox, 12 Confirm (to the inventory), 13 the item, 14 Cancel (`menu.back`); both Confirm buttons have action `shops.purchase` (`deliverTo` `Inbox` or `Inventory`) and click condition `shops.buyable` | `ctx.shopId`, `ctx.item`, `ctx.amount` |

1. **Variable root** `shop` (`ShopView`): coins, the shop's information lines (type, kind, level, town, whether it
   buys), the amount, the price lines, the description, the confirmation lines.
2. **Row sources** `shops.offer` (the offer, a page of it) and `shops.item` (the one item of `ctx.item`), rows
   `ShopOfferRow`: the real item (`BlueprintItems`), "Price: <n> coins each", the stock ("plenty" for unlimited), a
   unique item's enchantments, "Featured" for a pinned entry (glowing), a sold-out item greyed with "Sold out".
3. **`ctx.item`** is a `ShopItemRef`: `e<catalogue entry id>`, `i<item instance id>` or `b<blueprint id>` (Merchandise
   stock without an entry).
4. **Conditions:** `shops.buys` is the offer's `buysFromPlayers`; `shops.buyable` denies an item that is no longer on
   offer, a sold-out item and a unique item.
5. **Amount** (`shops.amount`): 1, 8, 16, 32, 64, then 1 again (V1 `setItemStep`), kept by the plugin per player, shop
   and item (`ShopAmounts`; a variable root can't read the engine's session state); capped by limited stock, 1 for a
   unique item, at most 100,000.

### 13.3 The purchase flow

`shops.purchase` (`ShopService.purchase`), on the main thread:

1. **Checks before a call:** the item is still on offer and not unique ("Unique items can't be bought in game yet; ask
   a staff member.", until the instance-to-item builder [#897](https://github.com/PandiO/knk-workspace/issues/897));
   the player is not in a siege; the player's account is loaded; a quote for this amount is there ("The shop is still
   working out the price; click again in a moment.") and has no refusal. For `Inventory`: the item can be built on
   this server and the inventory has room for the whole amount ("Your inventory has no room for <n>. Make room, or
   send it to your reward inbox."). One purchase per player at a time.
2. **The call** `POST api/Shops/{id}/purchase` with the quote's `unitPrice` as `expectedUnitPrice`, `confirmed: true`,
   `deliverTo` and a fresh idempotency key (`ShopKeys`). A call with no answer or a 5xx is sent once more with the same
   key, so it is booked once.
3. **Done:** for `Inventory` exactly the bought amount is placed; what no longer fits (the inventory filled up
   meanwhile) drops at the player's feet, owner-locked; a player who left before it was placed is logged for staff.
   For `Inbox` the API delivers through P7. The chat says "You bought <n> x <item> for <total> coins[. It waits in your
   reward inbox (/inbox)]. You have <n> coins left." and the menu goes back to the item information menu.
4. **409 `PriceChanged`:** "The price changed. Check the new price and confirm again."; the confirmation stays open,
   reads a new quote and shows "The price changed from <old>. Confirm again to buy."
5. **Every other 409** has its own message (`ShopRefusal`, e.g. "You don't have enough coins.") with "Nothing was
   charged."; still no answer after the retry: "The shop didn't answer. If coins were taken, show staff this code:
   <key>", and the server logs the key.

### 13.4 The sell menu and the sale flow

The engine has no deposit slots (legacy gap G2), so `SellModule` builds the sell menu itself (`SellView`,
`SellMenuLayout`): 4 rows, 0 Financial, 3 Sell (chest with the total), 4 the shop's information, 5 how to sell (book), 8
Back, slots 19-25 the picked stacks. The Sell chest of `shops.shop` opens it (`shops.sell`); refused in a siege, before
the account is loaded, and for a shop that doesn't buy.

1. **Picking.** A click on a stack in the player's inventory adds it; a click on a picked stack takes it out. At most 7
   stacks (`SellBasket`). A pick is a reference to an inventory slot, not the items: they stay in the inventory. Each
   stack is resolved through item identity ([#141](https://github.com/PandiO/knk-workspace/issues/141); needs
   `items.identity.enabled`): a blueprint, or a unique item as its instance. Picks of the same blueprint form one sale
   line.
2. **Refused before the API**, as the storage terminal does: display samples, damaged items (they would be resold
   repaired), enchanted plain items (they would lose their enchantments), unresolved items ("This item isn't in the
   item catalogue."), a stack already picked.
3. **Quote.** After each change `POST …/sell-quote`: the chest shows the total, each picked stack its buy-back price
   ("Buy-back: <n> coins each", "For these <n>: <n> coins") or its refusal; "Take out the marked items to sell" while a
   line is refused, "The town can't pay this much right now" when `townCanPay` is false.
4. **Sell.** A click on the chest checks the picked stacks are still where they were ("Your inventory changed; check
   the sale and click again."), takes them from the inventory, then sends `POST …/sell` with `confirmed: true`, the
   total shown as `expectedTotal` and a fresh idempotency key (one retry with the same key on no answer). All lines or
   none: on any refusal the items go back to the player (dropped where they stand if they left), on `PriceChanged`
   with a new quote; on success "You sold <n> item stacks for <total> coins. You now have <n> coins." and the menu
   closes. No answer after the retry: "The shop didn't answer; your items are back. If you were paid anyway, show staff
   this code: <key>".
5. On a plugin disable the sell menus close; picked items never left the inventory, so nothing is lost.

### 13.5 Refusal messages

`ShopRefusal` maps the API's codes (API contract § 4.4) to what the player reads: `ProductionDisabled` "Selling to shops
and buying into the reward inbox are switched off right now.", `PriceChanged` (asks again, § 13.3), `NotForSale`,
`SoldOut`, `NotEnoughStock`, `StorageLocked`, `InsufficientFunds` "You don't have enough coins.", `InboxFull`, `NoTown`,
`TownFundsInsufficient` "The town can't pay that much right now.", `CategoryNotAccepted` "This shop doesn't buy items of
that kind.", `NoPrice`, `NotResolved`, `InStorage`, `Soulbound`, `NoRoom`, `IdempotencyKeyReuse`; an unknown code shows
the API's own message, else "The shop couldn't do that right now." The full list with meanings is in the [menus player
guide § Shops](../guides/users/menus-player-guide.md#shops).

### 13.6 Deviations from the legacy menus (for the developer's review)

Listed in PR PandiO/knk-plugin#120 with the agent decisions; the developer reviews them.

1. Shop menu: V1 slots 2 (quest map) and 5 (transport assignment) are left out; V1's Exit in slot 8 is the engine's
   Back.
2. Shop menu: V1 sized the menu by the product count without paging; here 6 rows with paging, so any catalogue fits.
3. Shop menu: the information item shows type, kind, level, town and whether the shop buys; V1 showed address, price,
   income and owner.
4. Shop menu: sold-out items greyed out and pinned items highlighted are new (shops DESIGN § 7, F5).
5. Item information: the title is the fixed "Shop item" (engine titles are fixed); V1 used the product name.
6. Item information: V1's placeholder in slot 7 is left out; Exit is Back.
7. Item information: V1's name tag bought at once; here it opens the confirmation (DESIGN § 3.1). V1's property-region
   requirement is dropped.
8. Confirmation: V1 had no purchase confirmation, so the V1 house-sale confirmation is reused, with the item in slot
   13 and the added reward-inbox Confirm in slot 10.
9. Sell menu: built in the plugin, not the engine (no deposit slots, legacy gap G2).
10. Sell menu: V1 took the items dragged into the menu; here a click picks a stack, which stays in the inventory until
    the sale; refused lines are marked, and a sale is all lines or none.
11. The V1 coupon menu ("Use Item Coupon?") is not ported: V3 has no coupons.

The main agent decisions with them: the amount kept by the plugin (not `menu.state.cycle`); two Confirm buttons
(not the inbox as automatic overflow); back to the item information menu after a purchase; unique items listed but not
bought (#897); picks as slot references; one sale line per blueprint; the node `knk.admin.world.production` (not a new
`knk.admin.world.shop`); one retry with the same key.

## 14. The game server: display stalls (L29, #250)

Everything in game here runs only with the plugin's `production.enabled: true` (A21); the API part is admin CRUD and
works with `Production:Enabled` off, like the catalogue. Design: [shops DESIGN § 7](../specs/shops/DESIGN.md). Player
view: [menus player guide § Display stalls](../guides/users/menus-player-guide.md#display-stalls); set-up: [shops
admin guide § 3.6](../guides/admin/shops-admin-guide.md#36-display-stalls).

### 14.1 Spot registration

1. **A spot is one block** (a shelf, a barrel, a slab, a stall counter) registered for one shop: entity
   `ShopDisplaySpot` (knk-web-api `Models/Shops/ShopDisplaySpot.cs`, table `shop_display_spots`, migration
   `AddShopDisplaySpots`): `ShopId`, `WorldName`, `X`/`Y`/`Z` (Y -64 to 320), `Facing` (`North`, `East`, `South`,
   `West`; default `South`), `PinnedCatalogueEntryId` (an entry of the same shop, optional), `SortOrder`, `Label`
   (optional, at most 100 characters), `Enabled`, `CreatedByUserId`, `CreatedAt`, `UpdatedAt`.
2. **Rules** (`ShopDisplaySpotService`): a block is a spot once (unique world and x/y/z; 409 "The block … is already
   a display spot."), at most 100 spots per shop (409), a spot keeps its shop (400 on a change), the pin must be an
   entry of the spot's own shop (400; `0` clears it). Without a `sortOrder` a new spot comes after the shop's last one.
   Spots go with their shop (cascade); a deleted catalogue entry clears the pins on it (set null).
3. **Never found by scanning** (production DESIGN § 6.2, like storage containers). Two ways in:
   1. In game, `/knk shop display add <shop id> [label]` while looking at the block (within 6 blocks): the plugin
      sends `POST api/ShopDisplaySpots` with the block and the facing towards the admin (`DisplaySpot.Facing.towards`
      of the player's yaw), with the plugin key.
   2. The web app's generic dashboard form (`ShopDisplaySpot` form and display seeds, World area); a page of its own is
      [#968](https://github.com/PandiO/knk-workspace/issues/968). The plugin picks such a change up at its next
      re-read (`refresh-minutes`, default 5) or at once with `/knk shop display reload`.
4. **The plugin's copy** (`DisplaySpotIndex`, knk-core) is the API's whole list (`POST api/ShopDisplaySpots/search`,
   pages of 200), read at start, every `refresh-minutes` and on `reload`; `add`, `remove` and `pin` change it in place
   after the API answered. It is indexed by spot, block, shop and chunk; the fill order is `SortOrder`, then id.
5. Contract: [API contract § 4.5](../specs/api/API_CONTRACT_SHOPS.md#45-apishopdisplayspots-display-stalls).

### 14.2 Item display entities and their respawn

`ShopDisplayPresenter` (knk-paper), the lootbox technique (lootboxes DESIGN D3). Per shown spot, on top of the block:

1. an `ItemDisplay` with the item (transform `FIXED`, billboard fixed, turned to the spot's facing, scaled by
   `item-scale`, default 0.5): it doesn't turn with the viewer and can't be knocked down, pushed or picked up;
2. an `Interaction` hitbox of the same size, for the clicks;
3. a `TextDisplay` label (billboard centre) when `label` is on: the item's name, "<price> coins each" (a unique item
   without "each"), or "Sold out" in red, and with `hints` on "Right-click: information · Shift: buy" ("Right-click:
   information" for a sold-out item) (`DisplayText`).

All three are **non-persistent** and carry PDC `knightsandkings:knk_shop_display = <spot id>`. They are spawned only
while the spot's chunk is loaded and removed when it unloads; a crash leaves nothing behind. The block itself is never
changed. A sold-out item is the real item dimmed (brightness 3/3).

Respawn (`ShopDisplayModule`): once a second every chosen spot whose entities went away (killed, a chunk reload) is
spawned again; a chunk that loads gets its spots painted at once (or its shop read, the first time); when a chunk's
entities load, stray stall entities that the module doesn't own are removed (`purgeOrphans`, also for every world at
start), so a spot never shows two copies. An update with the same block, facing and label setting changes the
entities in place; anything else respawns them. On a plugin disable every stall entity goes.

### 14.3 Selection: pins, the pin fallback and best sellers

`DisplaySelection.select` (knk-core, pure) fills one shop's enabled spots in fill order from the shop's offer (`GET
api/Shops/{id}/offer`, § 5.1, read through `ShopService.fetchOffer`) and its units sold:

1. **A spot's own pin** (`PinnedCatalogueEntryId`) shows that entry.
2. **The pin fallback:** a pinned entry that is gone, switched off, hidden (sold out with **Hide sold-out items**) or
   already shown on an earlier spot doesn't leave the spot empty: the spot is filled like an unpinned one (a link
   decision in PandiO/knk-plugin#121; the alternative was an empty spot).
3. **The catalogue's pinned entries** (`pinned`) fill the next free spots, in the offer's order.
4. **The rest:** in-stock items before sold-out ones, then **best sellers** (most units sold), then the offer's order.
5. Sold-out items are greyed out, or not shown when the shop's `hideSoldOut` is set (they are then not in the offer).
6. An item is shown on one spot at most; spots left over when the offer runs out, and disabled spots, show nothing.

**Best sellers** are the units sold per blueprint over the last `best-seller-hours` (default 168, 7 days; 1 to 2160),
summed from `POST api/ShopTradeStats/search` (filters `shopId` and `from`, the window's start on the whole hour; § 11)
and read at most every 10 minutes per shop. Units sold, not revenue and not all time (a link decision in PandiO/knk-plugin#121). If the stats can't be
read, the last numbers are used, or none: the stalls still fill.

**When it runs:** every `selection-refresh-seconds` (default 30) for the shops with a spot in a loaded chunk; when such
a chunk loads; after the spot list changes; and at once after a purchase, sale or refusal that drops the shop's
offer (`ShopService.onOfferChanged`, one listener). The reads are off the main thread, one at a time per shop; the
result is applied on the main thread. Unique items in the offer get their real item built first, so a stall shows the
exact item (another item falls back to paper while its template is missing).

### 14.4 Interactions

`ShopDisplayModule` listens on the stall entities only (the PDC tag); everything else is left alone.

1. **Right-click** (`PlayerInteractEntityEvent`, main hand; the off-hand copy is ignored; two clicks within 250 ms are
   one): `ShopService.openItem(player, shopId, ref, false)` reads the offer and opens `shops.item` (§ 13.2) with
   `ctx.shopId` and `ctx.item`. No purchase. Anyone can click: there is no node, as for the shop menus.
2. **Shift-right-click, the quick buy:** `openItem(…, true)` opens `shops.confirm` with `ctx.amount` = the amount the
   player last picked for that item in the item information menu (`ShopAmounts`, 1 at first; a link decision, the alternatives were always 1 or a stack), and asks
   for the quote at once. **Every purchase is confirmed there**; the flow is § 13.3. An item that can't be bought
   opens nothing and is told: "This item is sold out.", "Unique items can't be bought in game yet.", "This item is no
   longer for sale here."
3. **Refused before a menu:** a player in a siege ("Shops are closed to you during a siege."), a spot showing nothing
   ("Nothing is on display here right now."), an offer that can't be read ("Could not open the shop (<why>).").
4. **Left-click and damage** on a stall entity are cancelled (`PrePlayerAttackEntityEvent`): nothing happens.
5. **WorldGuard** (`ShopDisplayWorldGuardListener`, registered only with WorldGuard): shops stand in town regions,
   where WorldGuard refuses entity use to non-members. For a stall entity only, a player's `UseEntityEvent` is marked
   allowed before WorldGuard's region check (the KNG-266 lootbox pattern); every other entity stays protected.

No new menu seed: the stalls reuse L26's `shops.item` and `shops.confirm` (a link decision; the alternative was a stall menu seed), so `content-seeds.json` is
unchanged. The node for `/knk shop display` is L26's `knk.admin.world.production` (not a new `knk.admin.world.shop`).

### 14.5 Configuration

`production.shops.displays.*` in the plugin's `config.yml` (restart; out-of-range values are clamped,
`DisplaySettings`): `refresh-minutes` 5 (1-1440), `selection-refresh-seconds` 30 (5-3600), `best-seller-hours` 168
(1-2160), `item-scale` 0.5 (0.1-2.0), `label` true, `hints` true. Reference: [plugin configuration
§ 4.31](../guides/admin/plugin-configuration.md#431-production). The start logs "Shop display stalls on: spots re-read every <n> min,
shown items chosen every <n> s (best sellers of the last <n> h)".

## 15. Tests and recovery

1. **knk-web-api** (xUnit): `Services/Shops/ShopTradingTests.cs` (23), `ShopSupplyTests.cs` (8), `ShopAdminTests.cs` (9),
   `Migrations/AddShopsTests.cs` (3); with `KNK_TEST_MYSQL`, `MySql/ShopsMySqlTests.cs` (2). The access tables and the
   seed import tests cover the six types; `MenuTemplateContentSeedTests` the three menu seeds. Display stalls (§ 14):
   `ShopDisplaySpotTests.cs` (5), `Migrations/AddShopDisplaySpotsTests.cs` (2) and the `ShopDisplaySpot` rows of the
   pinned access tests (`ReadAccessRulesTests` with the plugin-key reads of `ShopDisplaySpots` and `ShopTradeStats`
   search, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`). Every step of the
   [smoke test § 11.1](../guides/production-storage-transport-smoke-test.md#111-steps-api) names its test.
2. **knk-web-app**: § 12.3; the steps of [smoke test § 11.3](../guides/production-storage-transport-smoke-test.md#113-steps-web-app-688).
3. **knk-plugin**: knk-core `ShopItemRefTest`, `ShopRefusalTest`, `ShopAmountsTest`, `ShopKeysTest`, `SellBasketTest`,
   `ShopTextTest`; knk-api-client `ShopsApiImplTest`; knk-paper `ShopServiceTest`, `SellModuleTest` (MockBukkit, a
   stand-in shops API), `ShopMenuSeedsTest` (the seeded menus of `content-seeds.json` against the registered feature),
   `ShopAdminCommandTest`; the scenario `player-shop-sell-and-buy` on a real Paper server in CI's `paper-boot`
   ([plugin scenarios § 1](../guides/developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines)). The steps of
   [smoke test § 11.2](../guides/production-storage-transport-smoke-test.md#112-steps-plugin-687) name them.
   Display stalls (§ 14): knk-core `DisplaySelectionTest`, `DisplaySpotIndexTest`, `DisplaySpotFacingTest`,
   `DisplayTextTest`; knk-api-client `ShopDisplaySpotsApiImplTest`; knk-paper `ShopDisplayModuleTest` (MockBukkit: the
   entities, the clicks with the real `ShopService`, respawn and stray copies), `ShopDisplayCommandTest`,
   `ShopDisplayConfigTest`; the scenario `shop-display-stall`. The steps of [smoke test
   § 11.4](../guides/production-storage-transport-smoke-test.md#114-steps-display-stalls-plugin-and-api-250) name them.
3. **Recovery.**
   1. A town account that is not `reconciled`: compare `GET api/TownAccounts/{id}/ledger` with the balance; there is no
      correction route for town legs yet (#934).
   2. Trade stats that look wrong: `POST api/ShopTradeStats/rebuild` for the range; the rows come from the ledger.
   3. A purchase or sale the game server isn't sure about: send it again with the same `idempotencyKey`; the replay
      says what happened. The plugin logs the key of a purchase or sale that got no answer, and the player is shown
      it ("show staff this code"); a player who left before a bought item was placed is logged too ("give it back by
      hand").
   4. A stall that shows two copies or a wrong item: `/knk shop display list <shop id>` says what each spot should
      show; `/knk shop display reload` re-reads the spots; a chunk reload removes stray copies (§ 14.2).
   5. Turning shops off for players: `Production:Enabled` off stops selling, inbox delivery, restocking, processing
      and the stats job; buying from the catalogue goes on. Switching catalogue entries off (`enabled: false`) takes
      them off the offer.

## 16. Limitations

1. No shopkeeper NPC ([#249](https://github.com/PandiO/knk-workspace/issues/249)): the full shop menu is opened with
   `/knk shop <id>` (staff with `knk.admin.world.production`); players reach a shop's items only through its display
   stalls (§ 14), which open the item information and the confirmation, not the shop menu or the sell menu.
   `ShopkeeperLocationId` is stored for P11.
2. Display spots have no page of their own in the web app yet, only the generic dashboard form
   ([#968](https://github.com/PandiO/knk-workspace/issues/968)); a spot added there shows after `refresh-minutes` or
   `/knk shop display reload`.
3. Unique items are listed in the shop menus but can't be bought in game until
   [#897](https://github.com/PandiO/knk-workspace/issues/897) (buy them through staff).
4. A town leg can't be reversed or corrected by staff ([#934](https://github.com/PandiO/knk-workspace/issues/934)).
5. Interim pricing only; prices don't use the trade stats yet (#120), only the display stalls read them (best sellers, § 14.3). Levels are set by admins, no upgrade costs.
6. Web app gaps noted on [#688](https://github.com/PandiO/knk-workspace/issues/688#issuecomment-7058103705): the shop
   search row has no kind or type name, the town ledger shows user ids, sales and currency legs are not joined; no
   `production.shops` settings card and no account on the town page.
7. Deleting a shop type level doesn't check the shops at that level (§ 3.2).
8. `townPlayerCount` is always null (towns have no member count in V1).
