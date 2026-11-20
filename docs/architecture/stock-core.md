# Stock core (knk-web-api and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-19 (limitations: Storage weight on the ItemBlueprint form v2, production cycles in P3; docs #839); 2026-11-19 (§ 2: default storages of the P2 structure subtypes, docs #830); 2026-11-19 (first version, stock core P1 #97/#675, docs PandiO/knk-workspace#820)
**Checked against:** knk-web-api `next` `2e7d4e81` (PR PandiO/knk-web-api#56), knk-web-app `next` `9f46cb49` (PR
PandiO/knk-web-app#60). Not released; no plugin part yet (nothing in game changes).
**Related:** [production DESIGN § 4](../specs/production-storage-transport/DESIGN.md#4-stock-model) (the rules),
[stock API contract](../specs/api/API_CONTRACT_STOCK.md) (`api/Storages`, `api/StockTransactions`),
[stock admin guide](../guides/admin/stock-admin-guide.md) (the web app screens),
[smoke test § 2](../guides/production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3),
[item identity](item-identity.md) (the blueprint every stock line counts), [territory](territory.md) (the other part of
the production chain in `next`)

The stock core is the one place where the game's goods are counted. Every item lives in a **storage**; stock never
appears or vanishes, it **moves** from one storage to another in a double-entry **ledger**. Later production phases
(production cycles, transport, inbox, shops) write to it through one service, `IStockService`; P1 itself only offers
staff tools: storages, manual moves and adjustments, corrections, the ledger explorer, the reconciler and the roll-up.

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| Entities `Storage`, `StockLine`, `StockUnit` | knk-web-api | `Models/Stock/Storage.cs` |
| Entities `StockTransaction`, `StockMove`, `StockMoveRollup` | knk-web-api | `Models/Stock/StockTransaction.cs` |
| `ItemBlueprint.StorageWeight` (decimal, default 1) | knk-web-api | `Models/Item/ItemBlueprint.cs` |
| Enums (kind, purpose, reason, mode, reject reason, result status, actor kind) | knk-web-api | `Enums/StockEnums.cs` |
| `IStockService` (move, move many, adjust, reverse) and the row locks | knk-web-api | `Services/Stock/StockService.cs`, `Services/Stock/StockContracts.cs` |
| Storage CRUD and search | knk-web-api | `Services/Stock/StorageService.cs`, `Controllers/StoragesController.cs` |
| Ledger reads (transactions, moves, roll-ups) | knk-web-api | `Services/Stock/StockLedgerService.cs`, `Controllers/StockTransactionsController.cs` |
| Reconciler, roll-up, scheduled maintenance | knk-web-api | `Services/Stock/StockReconciler.cs`, `StockRollupService.cs`, `StockMaintenanceService.cs` |
| DTOs | knk-web-api | `Dtos/StockDtos.cs` |
| Dashboard access (types `Storage`, `StockTransaction`, `StockMove`, `StockLine`, `StockUnit`) | knk-web-api | `Attributes/DashboardAccess.cs` |
| Migration `20261119160613_AddStockCore` | knk-web-api | `Migrations/` |
| Form and display seeds `Storage`, `StockTransaction` | knk-web-api | `Data/FormConfigurationSeeds/`, `Data/DisplayConfigurationSeeds/` |
| API clients and types | knk-web-app | `src/apiClients/storageClient.ts`, `stockTransactionClient.ts`, `src/types/dtos/stock/StockDtos.ts` |
| Storage page panel, transaction page panel, dialogs, health card | knk-web-app | `src/components/stock/` (`StoragePanel`, `StockTransactionPanel`, `StockAdjustDialog`, `StockMoveDialog`, `StockResultView`, `StockLedgerHealthCard`, `LookupPicker`) |
| Ledger explorer `/admin/stock/ledger` | knk-web-app | `src/pages/admin/stock/StockLedgerPage.tsx`, route `stockLedger` in `src/routes/routeTable.ts` |
| Labels, result texts, the explorer's address state | knk-web-app | `src/utils/stock.ts` |

The panels are mounted on the generic detail page (`src/pages/DisplayWizardPage.tsx`) for the types `Storage` and
`StockTransaction`, below the seeded display.

## 2. Storages and holders

A `Storage` has a **kind** and at most one **holder** column, enforced by the check constraint `CK_storages_Holder`:

| Kind | Holder | Capped | Notes |
|---|---|---|---|
| `Domain` | `DomainId` (any domain: structure, town, district) | yes | warehouses, production output, town stock |
| `Player` | `UserId` | yes | inbox, stash, vault (later phases) |
| `Clan` | `ClanId` | yes | |
| `Transit` | none | no | a transport order's cargo (P5 points at it) |
| `Virtual` | `SystemKey` | no | the five system storages, below |

**Purpose** (`General`, `Output`, `Input`, `Delivery`, `Merchandise`, `Inbox`, `Stash`, `Vault`) says what the storage
is for; P1 only stores it. Since P2 ([#91](https://github.com/PandiO/knk-workspace/issues/91), in `next`) warehouses and production
structures create their default `Domain` storages (`Delivery`, `Output`) through `IStorageService.CreateAsync` in the
structure's create transaction and delete them with the structure ([production world § 3.3](production-world.md#33-default-storages)).

The five **system storages** are seeded by the migration with ids 1-5 and are the other side of stock entering or
leaving the system: `SYS_PRODUCTION` (made), `SYS_CONSUMPTION` (used up), `SYS_LOSS` (lost, robbed, spoiled),
`SYS_ADJUSTMENT` (staff corrections), `SYS_WORLD` (in a player's hands or the physical world). They are unbounded, may
go negative and can't be created, edited or deleted through the API (`EnsureSystemStorageAsync` recreates one only on
a database built without migrations, as in tests).

Rules in `StorageService`:

1. Create needs a name (at most 100 characters), a kind other than `Virtual` and exactly the holder column of that
   kind, which must exist; any other holder column is a 400.
2. Transit storages take no cap (400). Caps and units per slot are not negative.
3. Kind and holder change only while the storage has no stock and no ledger history (409); on update a null kind or
   holder keeps the current one.
4. Delete only an empty storage without history: the ledger keeps every storage it names (409).
5. Every update can send `rowVersion`; an older one is a 409 (`ConcurrencyCheck` on `Storage.RowVersion`, which every
   move bumps too).
6. Admin CRUD works while `Production:Enabled` is off (DESIGN § 18.2).

## 3. Stock lines and unique items

1. **Stackable items** are a `StockLine`: one blueprint (`ItemBlueprintId`, from [item identity](item-identity.md)) in
   one storage, unique per (storage, blueprint). A line is deleted when it reaches zero. Real storages never go below
   zero; virtual storages do, so for every blueprint the sum over all storages is zero.
2. **Unique items** (an enchanted sword) are a `StockUnit`: one `ItemInstance` in one storage, with a unique index on
   the item instance, so it is in at most one storage. No row means it is in the world (`SYS_WORLD`) or not yet in the
   system; a move from a virtual storage accepts a unit that has no row.
3. `Storage.TotalUnits` (Σ line amounts plus the number of unique items) and `Storage.DistinctItems` (lines plus unique
   items) are stored, kept in step by `IStockService` under the storage's row lock, and checked by the reconciler.

## 4. The ledger

1. **`StockTransaction`** is the header of one request: one `Reason`, the `Mode`, the actor (`ActorKind` `User`,
   `System` or `PluginServer`; `ActorUserId` without a foreign key, like the currency ledger, so the id survives a
   deleted account; `ActorComponent` such as `web`, `plugin`, `StockReconciler`), optional `SourceType`/`SourceRef`
   (what it belongs to, for later phases), `Note`, `IdempotencyKey` (unique when set), `RequestHash` (SHA-256 of the
   request) and `ReversesTransactionId` (unique: a transaction is reversed at most once).
2. **`StockMove`** is one line: from storage, to storage, either a blueprint and an amount (always positive) or one
   item instance (amount 1; a check constraint keeps it one or the other), the request's `LineNo`, and the header's
   `Reason` and `CreatedAt` repeated so the ledger can be queried per storage without a join.
3. **Append-only.** Nothing writes to a transaction or move after it is saved. A correction is a new transaction with
   reason `Correction` that moves every move of the original back, all or nothing (`ReverseAsync`); the original
   shows the correction as `reversedByTransactionId` on read. A correction that finds the stock gone is `Rejected` and
   nothing changes.
4. **Reasons** (DESIGN § 4.3, initial list): `Production`, `ProductionInput`, `TransportLoad`, `TransportDeliver`,
   `TransportReturn`, `TransportRobbed`, `TransportLost`, `Distribution`, `Trade`, `Deposit`, `Withdraw`,
   `RewardInbox`, `InboxClaim`, `InboxOverflow`, `InboxExpired`, `ContainerSync`, `PlayerHarvest`, `Spoilage`,
   `AdminAdjust`, `Correction`. `AdminAdjust` moves always have `SYS_ADJUSTMENT` on one side; `Correction` is written
   only by reversing. Enums are stored as strings, so new members are additive.
5. **Idempotency.** A request with a key that was seen before, with the same request hash, replays the first result
   (`replayed: true`, same transaction id, nothing moves again). The same key with a different request is a 409
   `IdempotencyKeyReuse`. A key is 1-100 characters of letters, digits and `: _ . -`. A replay reports what was
   applied; the rejected parts of the first request are not stored, so their reason reads `None`.

## 5. `IStockService`: locking and results

`IStockService` (`StockService`) is the only code that changes quantities:

| Method | What it does |
|---|---|
| `MoveAsync(line, ctx, mode)` | one line; same as `MoveManyAsync` with one line |
| `MoveManyAsync(lines, ctx, mode)` | every line in one transaction with one reason (at most 500 lines; amount 1 to 10^12) |
| `AdjustAsync(storageId, blueprintId, itemInstanceId, delta, ctx)` | between the storage and `SYS_ADJUSTMENT`, reason `AdminAdjust`; note required; a unique item by +1 or −1 |
| `ReverseAsync(transactionId, ctx)` | the compensating `Correction`, all or nothing |
| `GetSystemStorageIdAsync(key)` | the id of a system storage |

**Order of work in one request** (DESIGN § 4.5, V2 defect 4):

1. Validate the request (malformed → `ArgumentException`, 400).
2. Open a database transaction, or join the caller's (then the caller commits; a move inside a rolled-back caller
   transaction is rolled back with it).
3. Lock every storage of the request with `SELECT … FOR UPDATE` in ascending id order (`StockLocks`), so two requests
   never deadlock on each other.
4. Under the lock: the idempotency lookup, the stock, lock and capacity checks per line (each line sees the lines
   before it), and one `SaveChanges` that writes the ledger rows, the lines and units and the storage totals together.
   Each touched storage's `RowVersion` goes up (a conditional update on top of the lock).
5. Two identical requests serialize on the lock and the second replays; the unique idempotency index catches the rest
   (the same key on other storages: the loser replays the winner's result).

**Results, never exceptions.** Capacity, missing stock and locks come back in `StockResult` (HTTP 200):

1. `Status`: `Applied` (every line in full), `PartiallyApplied` (some moved, the rest stays in the source), `Rejected`
   (nothing moved, no transaction written).
2. Per line: `Requested = Accepted + Rejected` and a `RejectReason`: `CapacityFull`, `DistinctCapReached`,
   `NotEnoughStock`, `Locked`, or `OtherLineRejected` (another line of an all-or-nothing request was refused).
3. `AllOrNothing` (default): any short line rejects the whole request. `Partial`: each line moves what fits.
4. A lock (`LockedUntil` in the future) refuses every move into **and out of** the storage with `Locked`.

Thrown: `KeyNotFoundException` (a missing storage or transaction, 404), `StockIdempotencyConflictException` (409
`IdempotencyKeyReuse`), `InvalidOperationException` (a transaction already reversed or without moves, 409).

## 6. Capacity

DESIGN § 4.4 rev. 3. Capacity limits real storages only (`Domain`, `Player`, `Clan`); `Virtual` and `Transit` are never
capped.

1. **Raw units.** Capacity use = Σ line amount × `ItemBlueprint.StorageWeight`, plus each unique item's blueprint
   weight. A blueprint saved without `storageWeight` keeps its weight; new and existing blueprints start at 1.
2. **`MaxUnits`** caps the raw units; a line moves only as many units as fit (`floor(free / weight)`).
3. **`MaxDistinct`** caps the number of lines plus unique items; a new blueprint or unique item into a full storage is
   `DistinctCapReached` (more of a blueprint already there is not).
4. **`UnitsPerSlot`** is stored for P6 (bound containers: cap = slots × units per slot); nothing binds a container in
   P1, so it doesn't change the cap yet.
5. Lowering a cap below what is stored trims nothing: the storage is over its cap and accepts removals only (the
   storage page says "over its cap: removals only").
6. Capacity use is computed under the lock on every move; the storage read (`GET api/Storages/{id}`) returns it as
   `capacityUsed`.

## 7. Reconciler and roll-up

**Reconciler** (`StockReconciler.RunAsync`, read-only) checks four things and returns a `StockReconciliationReport`
(`clean`, counts and up to 100 listed rows per kind):

1. **Blueprint imbalances:** for every blueprint, the amounts over all storages (virtual ones included) sum to zero.
2. **Line differences:** every stock line equals the net of its moves plus its roll-up rows.
3. **Unit differences:** every unique item is in the storage its last move went to.
4. **Total differences:** every storage's stored `TotalUnits` and `DistinctItems` equal its lines and units.

**Roll-up** (`StockRollupService.RollUpAsync`, G3, DESIGN § 14 D10, A22): `Production` and `ProductionInput` moves of
whole UTC days more than 30 days back (cutoff = start of today − 30 days) are summed per day, reason, storage pair and
blueprint into `StockMoveRollup` rows (unique per that key; a later roll-up of the same day adds to the row, with
`MoveCount`). The summed moves and their transactions are deleted in the same database transaction, in batches of
500. Stock lines are not touched, so totals are unchanged and the reconciler stays clean. Every other reason keeps
every row; transactions with a unique item and transactions a correction points at are skipped. Safe to rerun and to
run twice at once (the second delete fails and that batch rolls back).

**Scheduled maintenance** (`StockMaintenanceService`, a hosted service, G16): an hourly tick; the reconciler every
6 hours and the roll-up every 24 hours, counted from the first tick after start, **only while the game setting
`production.enabled` (`Production:Enabled`) is on**. With it off a tick does nothing and logs nothing. A reconciler
difference is logged as a warning ("Stock reconciler: … blueprint imbalance(s), …"); a roll-up that did something is
logged as information ("Stock roll-up: …"). Staff can run both by hand at any time (`GET api/StockTransactions/reconcile`,
`POST api/StockTransactions/rollup`, or the ledger page's health card).

## 8. Permissions

| Action | Node(s) |
|---|---|
| Read storages (`api/Storages` GET and search) | `knk.admin.world` or `knk.economy.admin` (dashboard type `Storage`, World area) |
| Create and edit a storage | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| Delete a storage | `knk.admin.world` and `knk.admin.delete` |
| Read the ledger (`api/StockTransactions` GET, the searches, `reconcile`) | `knk.admin.world` or `knk.economy.admin` (view-only type `StockTransaction`) |
| Move, adjust, reverse, roll up | `knk.economy.admin` |

1. `knk.economy.admin` is **not** under `knk.admin`, so `knk.admin.*` doesn't grant it; only `*` or an explicit grant.
2. The plugin's service key passes both reads and writes (for later phases).
3. The web app hides nothing it can show: without `knk.economy.admin` the write buttons are off with the title
   "Requires knk.economy.admin"; the route `/admin/stock/ledger` needs `knk.admin.world` or `knk.economy.admin`
   (`staffAny`). The API refuses on its own either way.
4. Pinned in the access tests: `ReadAccessRulesTests`, `EndpointAccessRulesTests` and the dashboard access registry
   tests.

## 9. Schema and migration

`20261119160613_AddStockCore`, additive:

1. New tables `storages` (check constraint `CK_storages_Holder`, unique `SystemKey`), `stock_lines` (unique storage +
   blueprint), `stock_units` (unique item instance), `stock_transactions` (unique `IdempotencyKey`, unique
   `ReversesTransactionId`), `stock_moves` (indexes from/to storage + blueprint + `CreatedAt`), `stock_move_rollups`
   (unique day + reason + from + to + blueprint). Every foreign key is `Restrict`.
2. `item_blueprints.StorageWeight` (decimal), 1 on existing rows.
3. Data: the five system storages, ids 1-5. Nothing else.
4. No `api.env` key and no plugin key. The scheduler follows the game setting `production.enabled` (section
   `production`, added by `AddTerritory`).

Deploy and seed steps: [production installation § 5.3](../guides/production-installation.md) item 6 and the
[stock admin guide § 1](../guides/admin/stock-admin-guide.md#1-what-you-need).

## 10. Tests

1. knk-web-api xUnit: `StockServiceTests` (moves, partial, capacity × weight, unique items, locks, idempotency,
   reverse), `StorageServiceTests` (holder rules, system storages, delete, row version, storage weight),
   `StockReconcilerAndRollupTests` (clean after every path, finds outside changes, roll-up totals, the maintenance job
   only with `production.enabled`), `StockControllersTests` (actor, drill-down, access), `AddStockCoreTests`
   (migration).
2. knk-web-api MySQL tests (`StockLedgerMySqlTests`, real row locks): 1000 concurrent moves lose no update, 50 parallel
   moves of 10 from 100 give exactly 10, 20 parallel identical requests apply once, one key across different storages,
   parallel moves never pass a cap, a move inside the caller's transaction rolls back with it, the migration seeds the
   five system storages, the roll-up keeps the reconciler clean.
3. knk-web-app: Jest `src/utils/__tests__/stock.test.ts`, `src/apiClients/__tests__/stockClients.test.ts`; Playwright
   `e2e/stock.spec.ts` with fixtures `e2e/fixtures/stock.ts` (mocked API).
4. Manual: [smoke test § 2](../guides/production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3)
   (§ 2.1 API, § 2.2 web app); every step is tagged with the tests above; not run yet.

## 11. Recovery

1. **The reconciler reports a difference.** Something changed stock outside `IStockService` (SQL by hand, a restore of
   part of the database). Find the line in the report (`lineDifferences`: storage, blueprint, line amount, ledger net),
   look at its moves in the ledger explorer, and correct it with an adjustment (`AdminAdjust`, note why) so the line
   matches what should be there; never edit `stock_moves` or `stock_lines` in SQL. A stored total difference
   (`totalDifferences`) is not healed by later moves, because the service changes the stored totals by delta; fix the
   two columns in SQL from the lines and units (`TotalUnits` = Σ amounts + unit count, `DistinctItems` = lines +
   units) and run the reconciler again. There is no repair endpoint (P1).
2. **A wrong manual move.** Reverse it (a `Correction`); if the stock has moved on, the reverse is `Rejected` and you
   adjust instead.
3. **A storage refuses everything.** Look at its lock (`lockedUntil`) and its cap; a storage over its cap takes
   removals only.
4. **A retried request was refused with `IdempotencyKeyReuse`.** The caller sent a different body with the same key;
   send the original body, or a new key for a new request.

## 12. Limitations (P1)

1. No plugin part: nothing in game reads or writes stock yet; containers (P6), transport (P5)
   and the inbox (P7) are later phases.
2. Storages are created by hand; nothing creates a storage for a structure, player or clan automatically yet.
3. The Storage weight field is on the `ItemBlueprint` form from seed v2 (#819); the production engine (P3) writes
   stock through `IStockService` ([production engine](production-engine.md)).
4. A rolled-up transaction is gone, so it can't be reversed or opened; its totals live in the roll-up rows.
5. The scheduled reconciler only logs; there is no alert or realtime event. The currency monitor's alerts page does
   not show stock differences.
6. The web app's ledger explorer filters by ids (storage, blueprint, item instance, actor), not by name.

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#820).
2. 2026-11-19: limitations updated for P3 and the ItemBlueprint form v2 (docs PandiO/knk-workspace#839).
