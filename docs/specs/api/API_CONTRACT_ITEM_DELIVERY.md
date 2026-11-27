# API Contract: Item deliveries, the reward inbox and the stash

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P7 #60, docs PandiO/knk-workspace#915)
**Checked against:** knk-web-api `next` `2952d0c7` (PR PandiO/knk-web-api#70; `Controllers/ItemDeliveriesController.cs`
with `ItemDeliveriesController` and `InboxController`, `Dtos/ItemDeliveryDtos.cs`, `Services/Stock/ItemDeliveryService.cs`,
`Services/Territory/ProductionSettings.cs`, `Models/Stock/ItemDelivery.cs`). Not released.
**Related:** [item delivery architecture](../../architecture/production-item-delivery.md) (flows, keys, the kit and
lootbox paths), [production DESIGN § 4.6](../production-storage-transport/DESIGN.md), [stock API contract](API_CONTRACT_STOCK.md)
(`StockResultDto`, reject reasons, storages), [reward inbox admin guide](../../guides/admin/reward-inbox-admin-guide.md),
[smoke test § 8.1](../../guides/production-storage-transport-smoke-test.md#81-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names, errors `{ "error": "<reason>" }`, paged searches take `PagedQueryDto` and answer `PagedResultDto<T>`.
Times are UTC. Amounts are raw units; caps and fill are raw units × the blueprint's `storageWeight`.

**Moves.** Every call that moves items (a delivery, a claim, a stash deposit or withdraw) needs:

1. The API's game setting **Production enabled** (`Production:Enabled`): 409 `{ "code": "ProductionDisabled", "error":
   ... }` while it is off. Reads work while it is off; the sweep does nothing.
2. An **`idempotencyKey`** of 1 to 80 characters of letters, digits and `: _ . -` (400 otherwise). A retry with the
   same key and request applies once and answers the stored result; the same key with another request is 409
   `{ "code": "IdempotencyKeyReuse" }`.

**The player the game server names.** The game server calls with the plugin key (`X-API-Key`). The claim, and a stash
move from the game server, also need **`X-Acting-User-Id`** naming the player of the route (400 `{ "error":
"ActingUserRequired" }` when it is missing or names someone else).

**Status codes:** 400 validation, 403 a caller who may not, 404 a missing user (or no inbox yet for a claim), 409
`ProductionDisabled`, `IdempotencyKeyReuse`, a locked inbox (`"The inbox is locked: <reason>."`) or a concurrent save
(`"The inbox changed while saving; try again with the same key."`).

## 1. Access

| Route | Plugin key | The player (web) | `knk.economy.admin` | `knk.admin.world` |
|---|---|---|---|---|
| `POST api/ItemDeliveries/search`, `GET api/ItemDeliveries/{id}` | yes | — | yes | yes |
| `POST api/ItemDeliveries` | yes (actor PluginServer) | — | yes (actor User, a gift or grant) | — |
| `GET api/Inbox/{userId}`, `GET api/Inbox/{userId}/stash` | yes | their own | yes | — |
| `POST api/Inbox/{userId}/claim` | yes, as the named player | — | — | — |
| `POST api/Inbox/{userId}/stash/deposit`, `.../withdraw` | yes, as the named player | — | yes | — |
| `POST api/Inbox/sweep` | — | — | yes | — |

`knk.economy.admin` is not under `knk.admin`: `knk.admin.*` doesn't give it. The dashboard types `ItemDelivery` and
`ItemDeliveryLine` are view only. The rules are pinned in `ReadAccessRulesTests` and `EndpointAccessRulesTests`.

## 2. `api/ItemDeliveries`

### 2.1 `POST api/ItemDeliveries` → `ItemDeliveryDto`

Delivers items to a player's inbox: what the game server could not place, or a grant from staff.

```json
{
  "userId": 12,
  "reason": "Lootbox",
  "sourceType": "LootboxClaim",
  "sourceRef": "77",
  "note": null,
  "idempotencyKey": "lootbox-claim-77",
  "lines": [
    { "itemBlueprintId": 5, "amount": 40 },
    { "itemInstanceId": 901 }
  ]
}
```

| Field | Type | Notes |
|---|---|---|
| `userId` | int | The player (404 when missing) |
| `reason` | `Kit` \| `Lootbox` \| `Quest` \| `Gift` \| `Admin` \| `Other` | default `Other` |
| `sourceType`, `sourceRef` | string ≤ 64 | What it is for; the game server sends `Kit` + the kit name, `LootboxClaim` + the claim id |
| `note` | string ≤ 500 | Free text |
| `idempotencyKey` | string | Required (see the top) |
| `lines` | 1 to 100 | Each either `itemBlueprintId` + `amount` (1 or more), or `itemInstanceId` (amount 1 or left out; `itemBlueprintId`, when sent, must match the instance's) |

Rules: a unique item in one line only; an instance that is already in a storage is 400 ("a delivery brings items from
the world"); a locked inbox is 409 and nothing moves. What fits under the cap moves `SYS_WORLD` → the inbox
(RewardInbox); the rest `SYS_WORLD` → `SYS_LOSS` (InboxOverflow). The answer is 200 also when everything was lost
(`status` Lost) and on a replay (`replayed` true).

`ItemDeliveryDto`:

| Field | Notes |
|---|---|
| `id`, `userId`, `username`, `reason`, `sourceType`, `sourceRef`, `note` | |
| `status` | `Inboxed` (all in the inbox), `PartlyLost`, `Lost` |
| `actorKind`, `actorUserId` | `PluginServer` (with the acting user when sent) or `User` (the staff member) |
| `idempotencyKey`, `inboxStorageId` | |
| `stockTransactionId`, `overflowTransactionId` | The RewardInbox and InboxOverflow transactions; null when nothing fitted or nothing was lost |
| `capUnits` | The inbox cap when the delivery arrived |
| `createdAt`, `expiresAt` | `expiresAt` = `createdAt` + `expiryDays` |
| `inboxedUnits`, `lostUnits`, `remainingUnits` | Sums of the lines |
| `replayed` | True when this is the stored answer of an earlier request with the same key |
| `lines[]` | `ItemDeliveryLineDto`: `id`, `lineNo`, `itemBlueprintId`, `itemBlueprintName`, `itemInstanceId`, `customDisplayName`, `requested`, `inboxed`, `lost`, `claimed`, `expired`, `remaining`, `expiresAt`, `remindersSent` |

### 2.2 `POST api/ItemDeliveries/search` → `PagedResultDto<ItemDeliveryListDto>`

Filters (`filters` of `PagedQueryDto`): `userId`, `reason`, `status`, `sourceType`, `sourceRef`, `open` (`"true"`: with
something still in the inbox). The search term matches the username, the key, the source ref and the note. Newest first;
`sortBy: "id"` ascending for oldest first. `ItemDeliveryListDto`: `id`, `userId`, `username`, `reason`, `status`,
`sourceType`, `sourceRef`, `createdAt`, `expiresAt`, `inboxedUnits`, `lostUnits`, `remainingUnits`.

### 2.3 `GET api/ItemDeliveries/{id}` → `ItemDeliveryDto`

404 when missing.

## 3. `api/Inbox`

### 3.1 `GET api/Inbox/{userId}` and `GET api/Inbox/{userId}/stash` → `PlayerStorageViewDto`

The player's Inbox or Stash, with an empty view before the first item (`storageId` null).

| Field | Notes |
|---|---|
| `userId`, `purpose` (`Inbox` \| `Stash`), `storageId` | |
| `usedUnits`, `capUnits`, `fillPercent` | Raw units × storage weight; the cap is the player's current one (§ 5) |
| `warningPercent` | The highest `warnAtPercent` level reached, or null |
| `premiumTierGroupId` | The active premium tier whose caps apply, or null |
| `isLocked` | The storage is locked (nothing moves) |
| `entries[]` | `PlayerStorageEntryDto`: `itemBlueprintId`, `itemBlueprintName`, `itemInstanceId`, `customDisplayName`, `amount`, and for the inbox `nextExpiresAt` and `nextExpiringAmount` (the first lot that expires and how much of it) |

### 3.2 `POST api/Inbox/{userId}/claim` → `PlayerStorageMoveResultDto`

The game server claims what the player has room for and places what was accepted.

```json
{ "idempotencyKey": "inbox-claim-u12-3f9a0c1d2e4b", "lines": [ { "itemBlueprintId": 5, "amount": 25 } ] }
```

Inbox → `SYS_WORLD` (InboxClaim), partial: each line moves what the inbox holds (`NotEnoughStock` for the rest); the
accepted amounts are booked on the lots that expire first. 404 when the player has no inbox yet.

`PlayerStorageMoveResultDto`: `storageId`, `result` (the stock core's `StockResultDto`: `status`, `transactionId`,
`replayed`, `accepted`, `lines[]` with `accepted`, `rejected`, `rejectReason`), `view` (the `PlayerStorageViewDto` after
the move).

### 3.3 `POST api/Inbox/{userId}/stash/deposit` and `.../withdraw` → `PlayerStorageMoveResultDto`

The same body as a claim. Deposit `SYS_WORLD` → the stash (Deposit) up to the stash cap (`CapacityFull` for the rest;
with the default base cap of 0 only a premium tier with a stash cap can deposit); withdraw stash → `SYS_WORLD`
(Withdraw). The stash is made on first use. Callers: the game server for the player in `X-Acting-User-Id`, or staff with
`knk.economy.admin` (actor User).

### 3.4 `POST api/Inbox/sweep` → `InboxSweepResultDto`

Runs the reminders and expiry now (the API also runs them every hour): `remindersSent` (players reminded),
`expiredLines`, `expiredUnits`, `ranAt`. Nothing happens while `Production:Enabled` is off.

## 4. The `InboxUpdated` player notification

Queued for the player (`GET api/PlayerNotifications/pending`, type `InboxUpdated`, with an `inbox` payload,
`InboxNotificationDto`):

| `event` | When | Fields |
|---|---|---|
| `Delivered` | After each delivery | `deliveryId`, `reason`, `inboxedUnits`, `lostUnits` (above 0: the loss message), `warningPercent` (the level this delivery passed, or null), `fillPercent`, `capUnits` |
| `ExpiryReminder` | A lot's expiry came within a `reminderDaysBefore` value; summed per player per sweep | `expiringUnits`, `expiresAt` (the first) |
| `Expired` | Lots expired in a sweep; one per player | `lostUnits` |

## 5. Game settings `production.delivery`

Part of the production section of `GET`/`PUT api/GameSettings`. A save without `delivery` keeps the stored one; a
missing section reads as the defaults.

| Field | Default | Range |
|---|---|---|
| `inboxBaseCapUnits` | 2304 | 0 to 10,000,000 |
| `stashBaseCapUnits` | 0 | 0 to 10,000,000 |
| `expiryDays` | 30 | 1 to 365 |
| `reminderDaysBefore` | `[7, 1]` | at most 5 values, each 1 to `expiryDays` − 1 |
| `warnAtPercent` | `[80, 95]` | at most 5 values, each 1 to 100 |
| `premiumTiers` | `[]` | `{ "permissionGroupId", "inboxCapUnits", "stashCapUnits" }`, one per group; caps 0 to 10,000,000 or null (the base) |

A player's cap is the higher of the base and their active premium tier's entry. Errors are 400 with the field name
(`production.delivery.reminderDaysBefore: at most 5 values, each 1 to expiryDays - 1.`).

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#915), checked against knk-web-api `next` `2952d0c7`.
