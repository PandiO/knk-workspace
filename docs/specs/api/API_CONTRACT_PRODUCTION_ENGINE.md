# API Contract: Production engine (kinds, levels, lines, modifiers, weather, cycles, upgrades)

**Status:** Current · **Last updated:** 2026-11-19 (first version, production P3 #86, docs PandiO/knk-workspace#839)
**Checked against:** knk-web-api `next` `6c648f60` (PR PandiO/knk-web-api#58; `Controllers/Production*Controller.cs`,
`Controllers/ClimateZonesController.cs`, `Controllers/WeatherTypesController.cs`, the P3 actions of
`Controllers/ProductionStructuresController.cs`, `Dtos/ProductionEngineDtos.cs`, `Services/Production/`). Not released.
**Related:** [production engine architecture](../../architecture/production-engine.md) (settle, formula, weather,
upgrades), [PRODUCTION_KINDS § 2–5](../production-storage-transport/PRODUCTION_KINDS.md),
[admin guide](../../guides/admin/production-engine-admin-guide.md), [production world API contract](API_CONTRACT_PRODUCTION_WORLD.md)
(`api/ProductionStructures` CRUD), [stock API contract](API_CONTRACT_STOCK.md) (the storages and ledger the engine
writes to), [smoke test § 4.1](../../guides/production-storage-transport-smoke-test.md#41-steps-api) (every endpoint
with an example)

JSON property names are camelCase; enums travel as their names (`"Configured"`, `"BlockedFull"`, `"Multiply"`). On
create and update a **null field means "keep"** (on create: the default). Child lists (a level's `items`, a line's
`inputs`, a zone's `weatherOdds` and `towns`, a weather type's `effects`) **replace** the stored list when sent and are
kept when null. Errors are `{ "error": "<reason>" }`. Paged searches take the common `PagedQueryDto` (`pageNumber`,
`pageSize`, `searchTerm`, `sortBy`, `sortDescending`, `filters` as a string map) and answer `PagedResultDto<T>`. CRUD
works while the game setting **Production enabled** is off; the engine actions do not (§ 9).

## 1. Access

| Endpoints | Needs |
|---|---|
| `GET` and `POST …/search` on every resource below, `GET api/ProductionStructures/{id}/production` | `knk.admin.world` (World area), or the plugin key |
| `POST`, `PUT {id}` (kinds, levels, lines, modifiers, zones, weather types) | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| `DELETE {id}` | `knk.admin.world` and `knk.admin.delete` |
| `POST api/ProductionLines/{id}/settle`, `POST api/Production/run-now`, `PUT api/ProductionStructures/{id}/workers` | `knk.admin.world`, or the plugin key |
| `POST api/ProductionStructures/{id}/upgrade` | `knk.admin.world` and `knk.economy.admin`, or the plugin key |

A missing node is 401/403 as for every staff endpoint. Pinned by `EndpointAccessRulesTests`, `ReadAccessRulesTests`,
`DashboardChangeAccessRulesTests` and `DeleteAccessRulesTests`.

## 2. `api/ProductionKinds`

### 2.1 `GET api/ProductionKinds`, `GET api/ProductionKinds/{id}`

`200` with `ProductionKindDto` (all, or one; `404`):

| Field | Type | Notes |
|---|---|---|
| `id` | int | seeded 1–8 |
| `name` | string | unique, ≤ 100, required on create |
| `description` | string? | ≤ 1000 |
| `icon` | string? | Minecraft material name, ≤ 100 |
| `areaModel` | string | `BorderedField`, `ExclusiveVolume`, `SharedRadius`, `Pasture`, `HuntingGround`; required on create |
| `exclusiveAreas` | bool | areas may not overlap (P4) |
| `allowsDerived`, `allowsConfigured`, `allowsHybrid` | bool | at least one true |
| `resourceCategory` | string | `Crops`, `Wood`, `Stone`, `Ore`, `Fish`, `Flowers`, `Animals`; required on create |
| `defaultWorkers` | int | 0–100, default 2 |
| `cycleVariation` | bool | stored; used from P4 |
| `defaultStoragesJson` | string? | JSON list of `{ "purpose", "name", "maxUnits" }`; "" clears it |
| `isActive` | bool | default true |
| `createdAt` | DateTime | read only |
| `levels` | `ProductionKindLevelDto[]` | read only: its ten levels (§ 3) |

### 2.2 `POST api/ProductionKinds`

Example:

```json
{ "name": "Vineyard", "areaModel": "BorderedField", "resourceCategory": "Crops", "defaultWorkers": 3,
  "defaultStoragesJson": "[{\"purpose\":\"Input\",\"name\":\"inputs\",\"maxUnits\":500}]" }
```

`201` with the kind and its ten levels (the default curve: yield 1 + 0.15 per level, cycle speed 1 + 0.05 per level,
upgrade coins 250 × (level − 1)², no caps). 400:

1. "areaModel is required." / "resourceCategory is required." / "name is required." / "name must be at most 100 characters."
2. "areaModel must be one of BorderedField, ExclusiveVolume, …" (the same for `resourceCategory`).
3. "A production kind named 'X' already exists."
4. "A kind must allow at least one yield source."
5. "defaultWorkers must be 0 to 100."
6. `defaultStoragesJson`: "… must be a JSON list of {purpose, name, maxUnits}.", "… the Output storage is always
   created; don't list it.", "… maxUnits can't be negative.", "… at most 10 storages.", a bad purpose, a name over 40
   characters, "defaultStoragesJson is too long." (4000).

### 2.3 `PUT api/ProductionKinds/{id}`

Body: `ProductionKindDto`; null keeps. `204`; `404`; 400 as in § 2.2. Existing structures keep their workers and
storages; the default storages and workers apply to structures created afterwards.

### 2.4 `DELETE api/ProductionKinds/{id}`

`204` (its levels and level items go with it); `404`; `409` "N production structure(s) use this kind; give them another
kind first." or "A production modifier targets this kind; change or delete it first.".

### 2.5 `POST api/ProductionKinds/search`

`PagedResultDto<ProductionKindListDto>`: `id`, `name`, `areaModel`, `resourceCategory`, `defaultWorkers`, `isActive`,
`structureCount`. Filters `areaModel`, `resourceCategory`, `isActive` (`"true"`/`"false"`). `searchTerm` matches the
name. `sortBy` `name` (default) or `id`.

## 3. `api/ProductionKindLevels` (update only)

### 3.1 `GET api/ProductionKindLevels`, `GET api/ProductionKindLevels/{id}`

`200` with `ProductionKindLevelDto`:

| Field | Type | Notes |
|---|---|---|
| `id`, `productionKindId`, `productionKind` (`{ id, name }`), `level` | | read only; level 1–10 |
| `yieldMultiplier` | decimal | 0–100; the Level modifier |
| `cycleSpeedMultiplier` | decimal | above 0, at most 100; cycle = base cycle ÷ speed |
| `maxAreaSize` | int? | P4's area cap; 0 clears it |
| `outputMaxUnits`, `unitsPerSlot` | int? | written to the structure's Output storage on a level change; 0 clears (= leave the storage) |
| `transportCapacity` | int? | written to the structure on a level change; 0 clears |
| `upkeepReduction` | decimal | 0–1; no effect in V1 |
| `upgradeCoins` | long | ≥ 0; paid to reach this level |
| `upgradeDurationMinutes` | int? | stored, not enforced; 0 clears |
| `items` | `{ id, role, itemBlueprintId, itemBlueprintName, itemBlueprint, amount }[]` | `role` `Unlock` (amount 0) or `UpgradeCost` (amount > 0) |

### 3.2 `PUT api/ProductionKindLevels/{id}`

Example (a cost of 1000 coins and 20 of blueprint 41 to reach the level, and blueprint 57 produced from it on):

```json
{ "upgradeCoins": 1000,
  "items": [ { "role": "UpgradeCost", "itemBlueprintId": 41, "amount": 20 },
             { "role": "Unlock", "itemBlueprintId": 57 } ] }
```

`204`; `404`; 400 "yieldMultiplier must be 0 to 100.", "cycleSpeedMultiplier must be above 0 and at most 100.",
"upkeepReduction must be 0 to 1 (it has no effect in V1).", "upgradeCoins can't be negative.", "ItemBlueprint with id N
not found.", "An upgrade cost needs an amount above 0.", "Blueprint N is listed twice as Unlock." (or `UpgradeCost`), a
negative cap. There is no `POST` or `DELETE`: every kind has exactly levels 1–10.

### 3.3 `POST api/ProductionKindLevels/search`

`ProductionKindLevelListDto`: `id`, `name` ("Quarry level 2"), `productionKindId`, `productionKindName`, `level`,
`yieldMultiplier`, `cycleSpeedMultiplier`, `upgradeCoins`. Filter `productionKindId`; `searchTerm` matches the kind
name; sorted by kind name, then level (`sortDescending` reverses both).

## 4. `api/ProductionLines`

### 4.1 `GET api/ProductionLines`, `GET api/ProductionLines/{id}`

`200` with `ProductionLineDto`:

| Field | Type | Notes |
|---|---|---|
| `productionStructureId`, `productionStructure` (`{ id, name }`) | | required on create; can't change |
| `itemBlueprintId`, `itemBlueprint` (`{ id, name }`) | | required on create; one line per blueprint per structure |
| `rateSource` | string | `Configured` (only value accepted in P3) |
| `configuredRatePerHour` | decimal | 0–1 000 000 |
| `resourceCategory` | string? | overrides the kind's; "" clears it |
| `enabled` | bool | staff switch; default true |
| `status`, `statusReason` | | read only: `Running`, `Paused`, `BlockedFull`, `BlockedInputs`, `Error` |
| `accrued`, `anchorAt`, `lastSettledAt`, `nextSettleAt`, `createdAt` | | read only |
| `inputs` | `{ id, itemBlueprintId, itemBlueprintName, itemBlueprint, amountPerHour, accrued }[]` | at most 10; `amountPerHour` above 0 and at most 1 000 000 |

### 4.2 `POST api/ProductionLines`

```json
{ "productionStructureId": 12, "itemBlueprintId": 41, "configuredRatePerHour": 60,
  "inputs": [ { "itemBlueprintId": 63, "amountPerHour": 6 } ] }
```

`201`: `status` `Running`, `accrued` 0, `anchorAt` now, `nextSettleAt` one cycle later. 400: "productionStructureId is
required.", "itemBlueprintId is required.", "ProductionStructure with id N not found.", "ItemBlueprint with id N not
found.", "The structure already has a line for this blueprint.", "rateSource: only Configured exists yet; Derived and
Hybrid come with the yield areas (P4).", "configuredRatePerHour must be 0 to 1000000.", "A line has at most 10
inputs.", "An input's amountPerHour must be above 0 and at most 1000000.", "Input blueprint N is listed twice.".

### 4.3 `PUT api/ProductionLines/{id}`

Body: `ProductionLineDto`; null keeps; `inputs` replaces. The line is settled up to now first (with the feature on),
so the change applies from now; `"enabled": true` settles again, so a paused line resumes at once. `204`; `404`; 400 as
in § 4.2 or "A line can't move to another structure; delete it and create one there.".

### 4.4 `DELETE api/ProductionLines/{id}`

`204` (its inputs and cycle records go with it); `404`; `409` "A production modifier is scoped to this line; change or
delete it first.".

### 4.5 `POST api/ProductionLines/search`

`ProductionLineListDto`: `id`, `name`, `productionStructureId`, `productionStructureName`, `itemBlueprintId`,
`itemBlueprintName`, `rateSource`, `configuredRatePerHour`, `status`, `nextSettleAt`. Filters `productionStructureId`,
`itemBlueprintId`, `status`. `searchTerm` matches the blueprint or structure name. `sortBy` `id` (default), `name` (the
blueprint), `nextSettleAt`.

### 4.6 `POST api/ProductionLines/{id}/settle`

Settles the line up to now. `200` `{ "settled": true, "cycle": <ProductionCycleRecordDto> }`, or `{ "settled": false,
"cycle": null }` when nothing was due (no record written). `404`; `409` "Production is turned off (Production:Enabled).".

## 5. `api/ProductionModifiers`

### 5.1 `GET api/ProductionModifiers`, `GET api/ProductionModifiers/{id}`

`200` with `ProductionModifierDto`:

| Field | Type | Notes |
|---|---|---|
| `name` | string | required on create, ≤ 100 |
| `source` | string | read only; staff rows are `Admin` |
| `scope` | string | `Global`, `Kingdom`, `Town`, `Territory` (rural structures of a town), `MapArea` (never matches in V1), `Structure`, `Output` (one line); required on create |
| `scopeRefId` | int? | the kingdom, town, structure or line id; required for every scope but `Global` and `MapArea` (cleared for those); 0 clears |
| `target` | string | `Any` (default), `Blueprint`, `Category`, `Kind` |
| `targetItemBlueprintId`, `targetCategory`, `targetProductionKindId` | | the one the target needs; the others are cleared |
| `effect` | string | `Add` (units per hour) or `Multiply`; required on create |
| `value` | decimal | within ±1 000 000; a `Multiply` can't be negative; required on create |
| `activeFrom`, `activeUntil` | DateTime? | UTC; from inclusive, until exclusive; empty = open |
| `clearWindow` | bool? | write only: true clears both dates |
| `enabled` | bool | default true |

### 5.2 `POST`, `PUT {id}`, `DELETE {id}`

```json
{ "name": "Phoenix stone fair", "scope": "Town", "scopeRefId": 7, "target": "Category", "targetCategory": "Stone",
  "effect": "Multiply", "value": 2, "activeUntil": "2026-12-01T00:00:00Z" }
```

`201` / `204` / `204`; `404`. 400: "scope is required.", "effect is required.", "value is required.", "scopeRefId is
required for scope Town.", "scopeRefId N is not an existing town." (kingdom, structure, "production line"), "target
Blueprint needs an existing targetItemBlueprintId.", "target Category needs a targetCategory.", "target Kind needs an
existing targetProductionKindId.", "value must be within ±1000000.", "A multiplying modifier can't be negative.",
"activeUntil must be after activeFrom.". A change applies from the next settle of each line; time already settled is
not recomputed.

### 5.3 `POST api/ProductionModifiers/search`

`ProductionModifierListDto`: `id`, `name`, `source`, `scope`, `scopeRefId`, `target`, `effect`, `value`, `activeFrom`,
`activeUntil`, `enabled`. Filters `scope`, `scopeRefId`, `enabled`. `searchTerm` matches the name. `sortBy` `name`
(default) or `id`.

## 6. `api/ClimateZones`

### 6.1 `GET api/ClimateZones`, `GET api/ClimateZones/{id}`

`200` with `ClimateZoneDto`: `id`, `name` (unique, ≤ 100), `description`, `isDefault`, `createdAt`, `weatherOdds`
(`{ id, weatherTypeId, weatherTypeName, weatherType, chancePercent }[]`), `towns` (`{ townId, townName, town }[]`) and,
on a single read, `rolls`: the latest 14 stored rolls, newest first (`WeatherRollDto`, § 6.4).

### 6.2 `POST`, `PUT {id}`, `DELETE {id}`

```json
{ "name": "Northern coast", "weatherOdds": [ { "weatherTypeId": 1, "chancePercent": 30 },
  { "weatherTypeId": 2, "chancePercent": 10 } ], "towns": [ { "townId": 7 } ] }
```

1. **Odds:** each 0–100, one per weather type, together at most 100; the rest is clear.
2. **Towns:** a town is in one zone; listing it here moves it from its previous zone. A town in no zone uses the default.
3. **Default:** `"isDefault": true` makes this the default (the previous one stops being it); the first zone created is
   the default; `"isDefault": false` on the default zone is refused.
4. `201` / `204` / `204`; `404`. 400: "chancePercent must be 0 to 100.", "WeatherType with id N not found.", "Weather
   type N is listed twice.", "The weather odds add up to more than 100%.", "Town N not found.", "A climate zone named
   'X' already exists.", "This is the default zone; make another zone the default instead.". `DELETE` of the default
   zone: 409 "The default climate zone can't be deleted; make another zone the default first.". A zone's stored rolls
   go with it.
5. Changed odds apply from the next day without a roll; a day already rolled keeps its stored weather.

### 6.3 `POST api/ClimateZones/search`

`ClimateZoneListDto`: `id`, `name`, `isDefault`, `townCount`, `weatherTypeCount`. `searchTerm` matches the name.
`sortBy` `name` (default) or `id`.

### 6.4 `POST api/ClimateZones/rolls/search`

`PagedResultDto<WeatherRollDto>`: `id`, `climateZoneId`, `climateZoneName`, `day` (in-game day number), `dayStartsAt`,
`dayEndsAt`, `weatherTypeId` (null = clear), `weatherTypeName` ("Clear" when none), `weatherType`, `rollValue` ([0,
100)), `rolledAt`. Filter `climateZoneId`. Newest day first (`sortBy` set without `sortDescending`: oldest first). Rolls
are written by the engine only.

## 7. `api/WeatherTypes`

### 7.1 `GET api/WeatherTypes`, `GET api/WeatherTypes/{id}`

`200` with `WeatherTypeDto`: `id`, `name` (unique, ≤ 100, not "Clear"), `description`, `createdAt`, `effects`
(`{ id, category, effect, value }[]`: one per resource category, `Add` or `Multiply`).

### 7.2 `POST`, `PUT {id}`, `DELETE {id}`

```json
{ "name": "Blizzard", "effects": [ { "category": "Crops", "effect": "Multiply", "value": 0.2 },
  { "category": "Fish", "effect": "Multiply", "value": 0.5 } ] }
```

`201` / `204` / `204`; `404`. 400: "'Clear' is the name of no weather (the rest of a zone's odds).", "A weather type
named 'X' already exists.", "A multiplying effect can't be negative.", "An effect value is too large.", "Category X is
listed twice.". `DELETE` while a zone has odds for it: 409 "A climate zone has odds for this weather type; remove them
first.". Stored rolls of a deleted type become clear (`SET NULL`).

### 7.3 `POST api/WeatherTypes/search`

`WeatherTypeListDto`: `id`, `name`, `effectCount`. `searchTerm` matches the name. `sortBy` `name` (default) or `id`.

## 8. `api/ProductionCycleRecords` (read only)

### 8.1 `GET api/ProductionCycleRecords/{id}`

`200` with `ProductionCycleRecordDto`; `404`:

| Field | Type | Notes |
|---|---|---|
| `id`, `productionLineId`, `productionStructureId`, `itemBlueprintId`, `itemBlueprintName` | | |
| `settledAt`, `periodStart`, `periodEnd` | DateTime | |
| `elapsedSeconds` | long | accrued (after the catch-up cap) |
| `skippedSeconds` | long | dropped by the cap, or while stopped or blocked |
| `rateSource`, `baseRatePerHour` | | |
| `modifiers` | `AppliedModifierDto[]` | `{ source, name, scope, effect, value, modifierId }`, additions first, then multiplications |
| `unlockFactor` | decimal | 0 or 1 |
| `workersPresent`, `workersTotal`, `workerFactor` | | |
| `effectiveRatePerHour` | decimal | |
| `accruedBefore`, `accruedAfter` | decimal | |
| `emitted`, `accepted` | long | whole units moved to the Output storage, and how many it took |
| `inputs` | `{ itemBlueprintId, consumed }[]` | |
| `statusAfter`, `shortfallReason` | string | |
| `stockTransactionId` | long? | the ledger transaction of the output (or the inputs) |

### 8.2 `POST api/ProductionCycleRecords/search`

`PagedResultDto<ProductionCycleRecordDto>`. Filters `productionStructureId`, `productionLineId`. Newest first (`sortBy`
set without `sortDescending`: oldest first). No `POST`, `PUT` or `DELETE`; records go with their line.

## 9. Engine actions

### 9.1 `POST api/Production/run-now`

Runs the sweep for **every** line now (not only the due ones) after rolling today's weather. `200`
`ProductionSweepResultDto`:

```json
{ "featureEnabled": true, "ranAt": "2026-11-19T20:10:00Z", "weatherRolled": 1, "linesSettled": 3,
  "unitsEmitted": 30, "unitsAccepted": 30, "linesFailed": 0 }
```

`409` "Production is turned off (Production:Enabled).". The background sweep does the same every 60 s for the due lines
only.

### 9.2 `GET api/ProductionStructures/{id}/production`

The structure's engine view (`ProductionOverviewDto`). With the feature on it **settles the structure first** (lazy
settle); with it off it changes nothing and leaves the weather out of the rates. `404` for an unknown structure.

| Field | Type | Notes |
|---|---|---|
| `productionStructureId`, `featureEnabled`, `productionEnabled` | | |
| `productionKind` | `{ id, name }`? | |
| `level`, `workersPresent`, `workersTotal` | int | |
| `outputStorageId`, `inputStorageId` | int? | the first storage of that purpose |
| `climateZone`, `weatherToday` | string? | today's stored roll; "Clear" for none; null when not rolled yet |
| `notProducingReasons` | string[] | structure-wide: "Production is turned off for the whole server (Production:Enabled).", "The structure's production is switched off.", "The structure has no Output storage." |
| `lines` | `ProductionLineOverviewDto[]` | `line` (§ 4.1), `baseRatePerHour`, `modifiers`, `unlockFactor`, `workerFactor`, `effectiveRatePerHour`, `notProducingReasons` (empty = producing at the rate shown) |
| `recentCycles` | `ProductionCycleRecordDto[]` | the latest 20 of the structure |

A line's reasons: "The line is paused.", the line's blocked or error reason, "Unlocked at level N (the structure is
level M).", "The structure has no workers.", "All workers are away (0 of N present).", "Only P of N workers present: X%
output.", "The base rate is 0.", "The modifiers bring the rate to 0.".

### 9.3 `PUT api/ProductionStructures/{id}/workers`

Body `{ "workersPresent": 1 }`. Settles the structure first, then sets the workers present. `200` with the overview
(§ 9.2); `404`; 400 "workersPresent must be 0 to N (the structure's workers).". The total is the structure's
`workersTotal` ([production world contract § 4](API_CONTRACT_PRODUCTION_WORLD.md#4-apiproductionstructures)).

### 9.4 `POST api/ProductionStructures/{id}/upgrade`

Body (`ProductionUpgradeRequestDto`, may be empty): `payFromStorageId` (where the resource cost comes from; null = the
Output storage), `payerUserId` (who pays the coins; required when the next level costs coins), `idempotencyKey`
(default `upgrade:<id>:<target level>`).

`200` `ProductionUpgradeResultDto`:

```json
{ "productionStructureId": 12, "fromLevel": 2, "toLevel": 3, "coinsPaid": 1000,
  "stockTransactionId": 5531, "currencyTransactionId": "c8f1…" }
```

The structure settles first; then in one transaction the cost moves to `SYS_CONSUMPTION` (stock reason `Upgrade`), the
coins are spent (currency reason `PRODUCTION_UPGRADE`), the level rises by one and the level's caps are written.

1. `400`: "payerUserId is required: level N costs C coins.", "payFromStorageId is required: the structure has no Output
   storage.", "idempotencyKey is too long.".
2. `409` (nothing changes): "The structure has no production kind, so it has no levels to upgrade to.", "The structure
   is at the highest level (10).", "The kind has no level N.", "The structure's level changed meanwhile; try again.",
   "The upgrade cost could not be paid: blueprint B: <reason> (A of R).", the currency service's refusal (not enough
   coins, idempotency key reused with another request), "The currency service is not available.".
3. `404` for an unknown structure.
4. A retry with the same key applies once. The default key also replays after a manual level change
   ([#841](https://github.com/PandiO/knk-workspace/issues/841)).

### 9.5 Changes on `api/ProductionStructures` CRUD (P3)

1. `productionKindId` is a foreign key: an unknown id is 400 "ProductionKind with id N not found."; 0 clears it. The
   read adds `productionKind` (`{ id, name }`).
2. Create with a kind: `workersTotal`/`workersPresent` default to the kind's `defaultWorkers`; the kind's
   `defaultStoragesJson` storages are created next to the Output storage; level 1's caps apply.
3. A change of `level` or `productionKindId` writes the new level's caps; a change of level, kind, `workersTotal` or
   `productionEnabled` settles the structure first; `"productionEnabled": true` settles again afterwards.
4. Search filter `productionKindId`.

## 10. Game settings `production.engine`

Part of the `production` section of `GET`/`PUT api/GameSettings`:

```json
{ "production": { "enabled": true, "territory": { … },
  "engine": { "baseCycleMinutes": 10, "catchUpCapHours": 24, "weatherDayMinutes": 20 } } }
```

`baseCycleMinutes` 1–1440, `catchUpCapHours` 1–720, `weatherDayMinutes` 1–10 080; out of range is 400
"production.engine.baseCycleMinutes must be 1 to 1440." (and likewise). A save without `engine` resets it to the
defaults: clients must send it back.

## 11. Notification `ProductionLineStatusChanged`

Pushed on the realtime hub when a line's status changes into or out of `BlockedFull` or `BlockedInputs`. `userId` 0
(for the game server and staff); payload `productionLineStatus`: `productionStructureId`, `productionStructureName`,
`productionLineId`, `itemBlueprintId`, `itemBlueprintName`, `previousStatus`, `status`, `reason`. No client consumes it
yet.

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#839).
