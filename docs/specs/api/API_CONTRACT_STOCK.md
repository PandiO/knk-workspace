# API Contract: Stock core (`api/Storages`, `api/StockTransactions`)

**Status:** Current · **Last updated:** 2026-11-19 (first version, stock core P1 #97, docs PandiO/knk-workspace#820)
**Checked against:** knk-web-api `next` `2e7d4e81` (PR PandiO/knk-web-api#56; `Controllers/StoragesController.cs`,
`Controllers/StockTransactionsController.cs`, `Dtos/StockDtos.cs`). Not released.
**Related:** [stock core architecture](../../architecture/stock-core.md) (rules, locking, reconciler),
[production DESIGN § 4](../production-storage-transport/DESIGN.md#4-stock-model),
[stock admin guide](../../guides/admin/stock-admin-guide.md),
[smoke test § 2.1](../../guides/production-storage-transport-smoke-test.md#21-steps) (every endpoint with an example)

JSON property names are camelCase; enums travel as strings (`"Domain"`, `"AdminAdjust"`). Both controllers work while
`Production:Enabled` is off. Paged searches take the common `PagedQueryDto` (`pageNumber`, `pageSize`, `searchTerm`,
`sortBy`, `sortDescending`, `filters` as a string map) and answer `PagedResultDto<T>`.

## 1. Access

| Endpoints | Needs |
|---|---|
| `api/Storages` GET, `search` | `knk.admin.world` or `knk.economy.admin` |
| `api/Storages` POST, PUT | `knk.admin.world` and `knk.admin.content` |
| `api/Storages/{id}` DELETE | `knk.admin.world` and `knk.admin.delete` |
| `api/StockTransactions` GET, `search`, `moves/search`, `rollups/search`, `reconcile` | `knk.admin.world` or `knk.economy.admin` |
| `api/StockTransactions` POST (move), `adjust`, `{id}/reverse`, `rollup` | `knk.economy.admin` |

The plugin's service key passes all of them. A missing node is 401/403 as for every staff endpoint.
`knk.economy.admin` is not matched by `knk.admin.*`; only `*` or an explicit grant.

## 2. `api/Storages`

### 2.1 `GET api/Storages` and `GET api/Storages/{id}`

`200` with `StorageDto` (all, or one; `404` if missing). The single read also fills `capacityUsed`, `isLocked`,
`lines` and `units`.

`StorageDto`:

| Field | Type | Notes |
|---|---|---|
| `id` | int | |
| `name` | string | required on create, at most 100 characters, trimmed |
| `kind` | `Domain` \| `Player` \| `Clan` \| `Transit` \| `Virtual` | required on create; `Virtual` can't be created |
| `purpose` | `General` \| `Output` \| `Input` \| `Delivery` \| `Merchandise` \| `Inbox` \| `Stash` \| `Vault` | default `General` |
| `domainId` / `userId` / `clanId` | int? | exactly the one matching the kind (none for `Transit`) |
| `domain` / `user` / `clan` | `{ id, name }` | read only |
| `systemKey` | string? | read only; `SYS_PRODUCTION`, `SYS_CONSUMPTION`, `SYS_LOSS`, `SYS_ADJUSTMENT`, `SYS_WORLD` |
| `holderName` | string | read only: domain name, username, clan name, system key or `"Transit"` |
| `maxUnits` | long? | raw units cap; null = no cap; not on `Transit` |
| `maxDistinct` | int? | lines + unique items cap |
| `unitsPerSlot` | int? | stored for P6; no effect yet |
| `totalUnits`, `distinctItems` | long, int | read only, kept by the stock service |
| `capacityUsed` | decimal | read only, single read: Σ amount × storage weight |
| `rowVersion` | long | send it back on update; older = `409` |
| `lockedUntil`, `lockReason` | UTC date, string (≤ 200) | a future `lockedUntil` refuses moves in and out |
| `isLocked` | bool | read only |
| `createdAt` | UTC date | read only |
| `lines` | `StockLineDto[]` | `id`, `storageId`, `itemBlueprintId`, `itemBlueprintName`, `amount`, `storageWeight`, `updatedAt` |
| `units` | `StockUnitDto[]` | `id`, `storageId`, `itemInstanceId`, `itemBlueprintId`, `itemBlueprintName`, `customDisplayName`, `addedAt` |

### 2.2 `POST api/Storages`

Body: `StorageDto` (name, kind, purpose, holder id, caps, lock). `201` with the storage and a `Location` header.
`400 { error }`: missing name or kind, `Virtual` kind, a holder that doesn't exist or doesn't match the kind ("A Domain
storage has only DomainId; remove UserId."), negative caps, a cap on `Transit`.

```json
{ "name": "S1", "kind": "Domain", "purpose": "General", "domainId": 12, "maxUnits": 100 }
```

### 2.3 `PUT api/Storages/{id}`

Body: `StorageDto`; totals, lines and units are ignored. `204`. `404` missing; `400` as on create; `409 { error }`:
a system storage, a kind or holder change on a storage with stock or history, an old `rowVersion`, or a concurrent
change while saving. A null `kind` or holder id keeps the current one.

### 2.4 `DELETE api/Storages/{id}`

`204`. `404` missing. `409 { error }`: a system storage, or a storage with stock or ledger history.

### 2.5 `POST api/Storages/search`

Filters: `kind`, `purpose`, `domainId`, `userId`, `clanId`, `locked` (`true`/`false`). `searchTerm` matches the name,
the holder's name and the system key. `sortBy`: `name`, `kind`, `totalUnits` (default id). Answers
`StorageListDto` rows: `id`, `name`, `kind`, `purpose`, `holderName`, `domainId`, `userId`, `clanId`, `systemKey`,
`totalUnits`, `distinctItems`, `maxUnits`, `maxDistinct`, `lockedUntil`.

## 3. `api/StockTransactions`: reads

### 3.1 `POST api/StockTransactions/search`

Filters: `storageId` (either side of any move), `itemBlueprintId`, `itemInstanceId`, `transactionId`, `reason`,
`actorUserId`, `sourceType`, `sourceRef`, `since`, `until` (UTC; `until` exclusive). Rows (`StockTransactionListDto`):
`id`, `reason`, `mode`, `actorKind`, `actorUserId`, `actorComponent`, `sourceType`, `sourceRef`, `note`,
`reversesTransactionId`, `createdAt`, `moveCount`, `totalAmount`.

### 3.2 `GET api/StockTransactions/{id}`

`200` with `StockTransactionDto` = the list row plus `actorUsername`, `idempotencyKey`, `reversedByTransactionId` (the
correction that undid it) and `moves` (`StockMoveDto[]`). `404` missing (also after a roll-up removed it).

### 3.3 `POST api/StockTransactions/moves/search`

Filters: `storageId` (from or to), `fromStorageId`, `toStorageId`, `itemBlueprintId`, `itemInstanceId`,
`transactionId`, `reason`, `actorUserId`, `since`, `until`. `storageId` + `itemBlueprintId` is the drill-down from a
stock line. Rows (`StockMoveDto`): `id`, `transactionId`, `lineNo`, `fromStorageId`, `fromStorageName`,
`toStorageId`, `toStorageName`, `itemBlueprintId`, `itemBlueprintName`, `itemInstanceId`, `amount`, `reason`,
`createdAt`.

### 3.4 `POST api/StockTransactions/rollups/search`

Filters: `storageId` (from or to), `itemBlueprintId`, `reason`, `since`, `until` (by day). Rows
(`StockMoveRollupDto`): `id`, `day`, `reason`, `fromStorageId`, `fromStorageName`, `toStorageId`, `toStorageName`,
`itemBlueprintId`, `itemBlueprintName`, `amount`, `moveCount`, `rolledUpAt`.

### 3.5 `GET api/StockTransactions/reconcile`

Runs the reconciler now (read only). `200` with `StockReconciliationReport`: `checkedAt`, `clean`, `linesChecked`,
`unitsChecked`, `blueprintImbalanceCount`, `lineDifferenceCount`, `unitDifferenceCount`, `totalDifferenceCount`, and
up to 100 rows each of `blueprintImbalances` (`itemBlueprintId`, `sum`), `lineDifferences` (`storageId`,
`itemBlueprintId`, `lineAmount`, `ledgerNet`), `unitDifferences` (`itemInstanceId`, `storageId`, `ledgerStorageId`),
`totalDifferences` (`storageId`, `storedTotalUnits`, `actualTotalUnits`, `storedDistinctItems`,
`actualDistinctItems`).

## 4. `api/StockTransactions`: writes

Every write that moves stock answers **`200` with `StockResultDto`**, also when nothing moved:

```json
{
  "status": "PartiallyApplied",
  "transactionId": 41,
  "replayed": false,
  "accepted": 18,
  "lines": [
    { "lineNo": 0, "fromStorageId": 6, "toStorageId": 7, "itemBlueprintId": 3, "itemInstanceId": null,
      "requested": 40, "accepted": 18, "rejected": 22, "rejectReason": "CapacityFull" }
  ]
}
```

1. `status`: `Applied`, `PartiallyApplied`, `Rejected` (no transaction, `transactionId` null).
2. `rejectReason`: `None`, `CapacityFull`, `DistinctCapReached`, `NotEnoughStock`, `Locked`, `OtherLineRejected`.
3. `replayed: true`: the idempotency key was seen with the same request; this is the first result and nothing moved
   again (rejected parts read `None`).

Errors: `400 { error }` malformed request (no lines, more than 500, same storage on both sides, blueprint and item
instance both or neither, amount outside 1..10^12, unique item amount ≠ 1, unknown reason, bad key format, unknown
blueprint or item instance, an adjustment without note or with delta 0, a manual `Correction`); `404 { error }` a
storage or transaction that doesn't exist; `409 { code: "IdempotencyKeyReuse", error }` the key was used for a
different request; `409 { error }` a transaction already reversed, or a concurrent change while saving.

Idempotency keys: 1-100 characters, letters, digits and `: _ . -`; unique across the ledger. Send one on every call
that may be retried (the web app sends one per dialog).

The actor is taken from the caller: a web user gives `actorKind: User`, `actorUserId` = the user, `actorComponent:
"web"`; the service key gives `PluginServer` and `"plugin"`.

### 4.1 `POST api/StockTransactions` (move)

```json
{
  "reason": "Distribution",
  "mode": "AllOrNothing",
  "lines": [
    { "fromStorageId": 6, "toStorageId": 7, "itemBlueprintId": 3, "amount": 30 },
    { "fromStorageId": 5, "toStorageId": 6, "itemInstanceId": 912 }
  ],
  "note": "optional",
  "sourceType": "optional", "sourceRef": "optional",
  "idempotencyKey": "web-6c1f…"
}
```

`mode`: `AllOrNothing` (default) or `Partial`. A line has a blueprint with an amount, or an item instance (amount 1,
may be left out). One reason per request; `AdminAdjust` needs `SYS_ADJUSTMENT` on one side; `Correction` is refused
(use reverse).

### 4.2 `POST api/StockTransactions/adjust`

```json
{ "storageId": 6, "itemBlueprintId": 3, "delta": 64, "note": "count after the fire", "idempotencyKey": "web-…" }
```

`delta` > 0 moves from `SYS_ADJUSTMENT` into the storage, < 0 back out; for a unique item send `itemInstanceId` with
`delta` +1 or −1. Reason `AdminAdjust`; `note` required.

### 4.3 `POST api/StockTransactions/{id}/reverse`

Body (optional): `{ "note": "…", "idempotencyKey": "…" }`. Writes a `Correction` that moves every move of `{id}` back,
all or nothing, with `reversesTransactionId` = `{id}`. `Rejected` (`NotEnoughStock`, `Locked`, …) when the stock has
moved on. A second reverse of the same transaction is `409`.

### 4.4 `POST api/StockTransactions/rollup`

Runs the 30-day roll-up now. `200` with `StockRollupResult`: `cutoff` (UTC; moves before it were eligible),
`transactionsRolledUp`, `movesRolledUp`, `rollupRowsWritten`.

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#820).
