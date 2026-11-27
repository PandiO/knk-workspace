# API Contract: Town logistics (policies, rules, consumer settings, reservations, the planner)

**Status:** Current · **Last updated:** 2026-11-21 (`settingSource` `ShopLevel`, shops P10 #248, docs #939); 2026-11-21 (P9 follow-ups #928: town profile, labels on `PUT`, structure types, names, `townId` lookups)
**Checked against:** knk-web-api `next` `37be22e5` (PR PandiO/knk-web-api#73; `Controllers/LogisticsControllers.cs`,
`Dtos/LogisticsDtos.cs`, `Enums/LogisticsEnums.cs`, `Services/Logistics/*.cs`, `Models/Logistics/Logistics.cs`,
`Services/Territory/ProductionSettings.cs`). Not released.
**Related:** [town logistics architecture](../../architecture/town-logistics.md) (the rules in force, matching, the
planner's steps), [TOWN_LOGISTICS § 2-5](../production-storage-transport/TOWN_LOGISTICS.md),
[transport API contract](API_CONTRACT_PRODUCTION_TRANSPORT.md) (orders, origin `Distribution`),
[town logistics admin guide](../../guides/admin/town-logistics-admin-guide.md),
[smoke test § 10.1](../../guides/production-storage-transport-smoke-test.md#101-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names (case-insensitive on input), paged searches take `PagedQueryDto` and answer `PagedResultDto<T>`. Times
are UTC. Amounts are raw units of the blueprint. `NamedRefDto` fields (`town`, `warehouse`, `itemBlueprint`, …) are
read only.

**The switch.** Everything works while the API's game setting **Production enabled** (`Production:Enabled`) is off,
except `POST api/Logistics/towns/{id}/run-now`: 409 `{ "code": "ProductionDisabled", "error": ... }`. The dry run and
the views answer `featureEnabled: false` then.

**Status codes:** 400 validation (`{ "error": "<all problems, e.g. Rule 2: …>" }`), 403 a caller who may not, 404 a
missing row (`{ "error": ... }` from the logistics routes), 409 a conflict (`{ "error": ... }`: not the current version,
a town that already has a policy, a reservation that is not open or already loaded, a concurrent save) or
`ProductionDisabled`.

## 1. Access

| Route | Plugin key | `knk.admin.world` | + `knk.admin.delete` |
|---|---|---|---|
| `GET` and `POST …/search` of every controller, `GET api/LogisticsPolicies/{id}/versions`, `GET api/Logistics/…` | yes | yes (any node of the World area) | — |
| `POST api/LogisticsPolicies`, `PUT …/{id}` | yes | yes (and the dashboard change rule for `LogisticsPolicy`) | — |
| `POST api/LogisticsPolicies/{id}/apply` | yes | yes | — |
| `DELETE api/LogisticsPolicies/{id}` | yes | — | yes |
| `POST api/ConsumerReplenishments`, `PUT …/{id}` | yes | yes (and the dashboard change rule for `ConsumerReplenishment`) | — |
| `DELETE api/ConsumerReplenishments/{id}` | yes | — | yes |
| `POST api/LogisticsReservations/{id}/release` | yes | yes | — |
| `POST api/Logistics/towns/{id}/dry-run`, `…/run-now` | yes | yes | — |
| `PUT api/LogisticsPolicies/towns/{townId}/profile` | yes | yes | — |

Dashboard types (World area, with lookups): `LogisticsPolicy` and `ConsumerReplenishment` editable;
`LogisticsRule`, `LogisticsReservation`, `LogisticsPlannerRun` and `LogisticsPlanEntry` view only. Pinned in
`ReadAccessRulesTests`, `DeleteAccessRulesTests`, `DashboardChangeAccessRulesTests` and `LookupFiltersTests`.

## 2. `api/LogisticsPolicies`

### 2.1 `LogisticsPolicyDto`

| Field | Type | Notes |
|---|---|---|
| `id` | int? | Read only |
| `name` | string | Required |
| `scope` | `Town` \| `Warehouse` \| `Template` | Required on create; can't change |
| `townId` / `town` | int? | Required for `Town`; can't change |
| `warehouseId` / `warehouse` | int? | Required for `Warehouse`; can't change |
| `specialization` | string? | Templates only: `Crops`, `Wood`, `Stone`, `Ore`, `Fish`, `Flowers`, `Animals`; on `PUT` null keeps it and `""` clears it (general) |
| `townSize` | string? | Templates only: `Village`, `Town`, `City`; on `PUT` null keeps it and `""` clears it |
| `isDefaultTemplate` | bool? | Templates only; saving one as default clears the others; on `PUT` null keeps it |
| `version`, `lineageId`, `isCurrent`, `basedOnPolicyId`, `supersededByPolicyId`, `supersededAt` | | Read only |
| `author` | `Admin` \| `ClanCouncil` | Default `Admin` |
| `reason` | string? | Up to 500; default "Created." / "Edited." |
| `createdAt`, `createdByUserId` | | Read only |
| `rules` | `LogisticsRuleDto[]` | The whole list of the version (at most 200); a save replaces it |

Template labels left out of a `PUT` (null) are kept, like `name`; an empty string clears a label
([#928](https://github.com/PandiO/knk-workspace/issues/928) item 2).

### 2.2 `LogisticsRuleDto`

| Field | Type | Notes |
|---|---|---|
| `id`, `logisticsPolicyId` | int? | Read only (rules get new ids in every version) |
| `sequence` | int | Order in the list; renumbered 1..n on save |
| `type` | `Reserve` \| `PriorityClass` \| `ServiceArea` \| `Replenishment` | Required; other types are refused (Later, #324) |
| `scope` | `Town` \| `Warehouse` | Default `Town`; `Warehouse` only for a local `Reserve` |
| `warehouseId` | int? | Required for a local reserve and a service area; a warehouse of the policy's town |
| `targetKind` | `Any` \| `Blueprint` \| `Category` \| `Tag` | Not for service areas; default `Blueprint` with an `itemBlueprintId`, else `Any` |
| `itemBlueprintId`, `categoryId`, `tagId` | int? | The target, required for its kind |
| `consumerKind` | `Any` \| `Structure` \| `ProductionKind` | `PriorityClass` and `Replenishment` only; default from the ids given |
| `structureId` | int? | A structure of the policy's town (consumer or service-area structure) |
| `productionKindId` | int? | For `consumerKind` `ProductionKind` |
| `areaKind` | `District` \| `Rural` \| `Structure` | `ServiceArea` only, required |
| `districtId` | int? | A district of the policy's town, for `areaKind` `District` |
| `units` / `daysOfCover` | long? / decimal? | `Reserve`: exactly one; units 0-100,000,000, days above 0 and at most 3650 |
| `reorderPoint` / `targetLevel` | long? | `Replenishment`: both, 0 ≤ reorder ≤ target, target 1-100,000,000 |
| `priorityClass` | `Critical` \| `High` \| `Normal` \| `Low` | `PriorityClass`, required |
| `activeFrom`, `activeUntil` | DateTime? | Optional window; until after from |
| `author`, `reason` | | Reason up to 300 |
| `summary` | string | Read only: one line, e.g. "Reserve 14 days of Bread, town-wide" |

Scope limits: a warehouse policy holds local reserves and service areas about its own warehouse only; a template holds
no warehouse rules, service areas, structures or districts.

### 2.3 Routes

| Route | Body → answer | Notes |
|---|---|---|
| `GET {id}` | → `LogisticsPolicyDto` | Any version |
| `POST search` | `PagedQueryDto` → `LogisticsPolicyListDto` page | Filters `scope`, `townId`, `warehouseId`, `lineageId`, `current` (`true` default, `false` superseded only, `all`), `specialization`; search term = name |
| `GET {id}/versions` | → `LogisticsPolicyListDto[]` | Every version of the lineage, newest first |
| `POST` | `LogisticsPolicyDto` → 201 `LogisticsPolicyDto` | Version 1; 409 when the town or warehouse already has a policy |
| `PUT {id}` | `LogisticsPolicyDto` → 200 `LogisticsPolicyDto` | Writes version n + 1 and returns it (a new id); 409 unless `{id}` is current, or when another save got in first |
| `DELETE {id}` | → 204 | Deletes every version |
| `POST {id}/apply` | `{ "townId": 5, "reason": "…" }` → `LogisticsPolicyDto` | `{id}` must be a template (400); copies its rules into the town's policy as a new version, or its version 1 |
| `GET towns/{townId}/profile` | → `TownLogisticsProfileDto` | The town's labels and the template that fits them (§ 2.4); 404 unknown town |
| `PUT towns/{townId}/profile` | `TownLogisticsProfileDto` → `TownLogisticsProfileDto` | Sets `townSize` and `specialization`: null keeps a field, `""` clears it; 400 unknown label or another `townId`; 404 unknown town |

`LogisticsPolicyListDto`: `id`, `name`, `scope`, `townId`, `townName`, `warehouseId`, `warehouseName`,
`specialization`, `townSize`, `isDefaultTemplate`, `version`, `lineageId`, `isCurrent`, `ruleCount`, `reason`,
`createdAt`.

### 2.4 `TownLogisticsProfileDto` (#928)

A town's size and specialization, the labels the default templates key on (TOWN_LOGISTICS § 4.1), stored on the town
(`towns.LogisticsTownSize`, `towns.LogisticsSpecialization`; not on the town form). Fields: `townId`, `townName`,
`townSize` (`Village`, `Town`, `City` or null), `specialization` (a resource category or null = general), and read only
`suggestedTemplateId`, `suggestedTemplateName`, `suggestedTemplateMatch`: the current template with both labels equal
(`Exact`), else the same size with a general specialization (`Size`), else the default template (`Default`), else
`None`; the oldest template lineage wins a tie. The suggestion is for the web app's template picker; the planner still
uses the town's own policy or the default template (§ 7.2 `policySource`).

## 3. `api/LogisticsRules` (read only)

`GET {id}` → `LogisticsRuleDto`; `POST search` → `LogisticsRuleListDto` page (`id`, `logisticsPolicyId`,
`policyName`, `policyVersion`, `policyIsCurrent`, `sequence`, `type`, `scope`, `summary`, `reason`). Filters
`logisticsPolicyId`, `townId`, `type`, `current` (true by default). Rules are edited inside their policy.

## 4. `api/ConsumerReplenishments`

`ConsumerReplenishmentDto`: `id`, `storageId` (a structure's `Domain` storage with purpose `Input` or `Merchandise`,
not a warehouse's), `structureId` (read only, the holder), `itemBlueprintId`, `reorderPoint`, `targetLevel` (0 ≤
reorder ≤ target, target 1-100,000,000), `priorityClass` (`Critical` … `Low`, or empty = the policy's rules),
`enabled` (default true), `note`, `createdAt`, `updatedAt`. One per storage and blueprint (409 on a second).

| Route | Notes |
|---|---|
| `GET {id}`, `POST search` | Filters `storageId`, `structureId`, `townId`, `itemBlueprintId`, `enabled`; search term = structure or blueprint |
| `POST` → 201, `PUT {id}` → 200 | On update a `null` field keeps its value, except `note` (null clears it); `priorityClass: ""` clears the class |
| `DELETE {id}` → 204 | |

## 5. `api/LogisticsReservations`

`LogisticsReservationDto`: `id`, `townId`, `warehouseId`, `warehouseStorageId`, `consumerStructureId`,
`consumerStorageId`, `itemBlueprintId` (each with its `NamedRefDto`), `consumerStructureType` (`Shop`, `ProductionStructure`, `Warehouse`, `GateStructure` or `Structure`), `amount`, `collected`, `status` (`Open`,
`Collected`, `Released`, `Cancelled`), `priorityClass`, `transportOrderId`, `transportOrderStatus`, `plannerRunId`,
`createdAt`, `expiresAt`, `closedAt`, `explanation`, `statusReason`.

| Route | Notes |
|---|---|
| `GET {id}`, `POST search` | Newest first; filters `townId`, `warehouseId`, `consumerStructureId`, `consumerStorageId`, `itemBlueprintId`, `status`, `open`, `transportOrderId`, `plannerRunId` |
| `POST search` rows | `LogisticsReservationListDto`: `id`, `townId`/`Name`, `warehouseId`/`Name`, `consumerStructureId`/`Name`, `consumerStructureType`, `consumerStorageId`/`Name`, `warehouseStorageId`/`Name`, `itemBlueprintId`/`Name`, `amount`, `collected`, `status`, `priorityClass`, `transportOrderId`, `createdAt`, `expiresAt` |
| `POST {id}/release` | Body `{ "reason": "…" }` (optional, up to 300). Cancels its collection order when it is not final, sets `Cancelled`. 409 when not open, or when the worker already loaded (the next run marks it `Collected`) |

## 6. `api/LogisticsPlannerRuns` (read only)

`GET {id}` → `LogisticsPlannerRunDto` (`id`, `townId`, `town`, `logisticsPolicyId`, `policyVersion`, `trigger`
(`Scheduled`, `Manual`), `startedAt`, `finishedAt`, `demandLines`, `reservationsCreated`, `ordersCreated`,
`reservationsReleased`, `reservationsCollected`, `shortfalls`, `summary`, `createdByUserId`, `entries` (§ 7.2, every
outcome but `NotNeeded`)). `POST search` → `LogisticsPlannerRunListDto` page.

## 7. `api/Logistics`

### 7.1 Routes

| Route | Answer | Notes |
|---|---|---|
| `GET towns/{townId}/supply` | `TownSupplyDto` | § 7.3 |
| `GET towns/{townId}/service-areas` | `TownServiceAreasDto` | `entries[]`: `areaKind` (`District`, `Rural`, `Structure`), `districtId`/`districtName` or `structureId`/`structureName`/`structureType`, `warehouseId`, `warehouseName`, `source` (`Rule` or `Nearest`), `ruleId` |
| `POST towns/{townId}/dry-run` | `LogisticsPlanDto` with `dryRun: true` | Writes nothing; works while production is off |
| `POST towns/{townId}/run-now` | `LogisticsPlanDto` with `runId` | 409 `ProductionDisabled` while off; 404 unknown town |
| `GET consumers/{structureId}` | `ConsumerViewDto` | 404 unknown structure |

### 7.2 `LogisticsPlanDto`

`townId`, `townName`, `featureEnabled`, `dryRun`, `at`, `runId`, `policyId`, `policyName`, `policyVersion`,
`policySource` (`Town`, `DefaultTemplate`, `None`), `entries[]`, `orders[]`, `released[]` (`reservationId`, `status`,
`reason`), `collected[]` (reservation ids), `warnings[]`, `summary`.

`LogisticsPlanEntryDto` (one per consumer storage and blueprint): `consumerStructureId`/`Name`,
`consumerStructureType` (`Shop`, `ProductionStructure`, `Warehouse`, `GateStructure` or `Structure`), `consumerStorageId`/`Name`, `itemBlueprintId`/`Name`, `warehouseId`/`Name`, `priorityClass`, `stock` (stock + on the
way), `reorderPoint`, `targetLevel`, `shortfall`, `reserved`, `outcome`, `settingSource` (`Setting`, `Rule`, `ShopLevel` (a shop level's default min/max, [shops contract](API_CONTRACT_SHOPS.md)), `Inputs`),
`ruleIds[]`, `reservationId`, `transportOrderId`, `explanation`.

`outcome`: `Reserved`, `PartlyReserved`, `NotNeeded`, `AlreadyReserved`, `NoStock`, `HeldByReserve`, `NoWarehouse`,
`NoWorker`, `NoRoom`, `NotConnected`, `CarrierFull` (meanings in the
[architecture § 5](../../architecture/town-logistics.md#5-the-planner-logisticsplanner)).

`LogisticsPlannedOrderDto` (one collection order): `consumerStructureId`/`Name`, `consumerStructureType`,
`consumerStorageId`/`Name`, `warehouseId`/`Name`, `warehouseStorageId`/`Name`, `lines[]` (`itemBlueprintId`,
`itemBlueprintName`, `amount`), `carrierCapacity`, `workersPresent`,
`workersTotal`, `transportOrderId` (null in a dry run), `warnings[]`.

### 7.3 `TownSupplyDto`

`townId`, `townName`, `featureEnabled`, `at`, `consumptionWindowDays`, `warehouses[]` (`NamedRefDto`), `lines[]`,
`openReservations[]` (`LogisticsReservationListDto`), `policyId`, `policySource`, `lastRun`
(`LogisticsPlannerRunListDto`), `nextRunAt` (null while production is off).

`TownSupplyLineDto`: `itemBlueprintId`, `itemBlueprintName`, `stock`, `reserved` (open reservations), `reserveUnits`
(the town reserve), `available` (stock − reserves − reservations, never below 0), `inflowPerDay`, `outflowPerDay`,
`daysOfCover` (stock ÷ daily outflow; null without outflow), `warehouses[]` (`warehouseId`, `warehouseName`, `stock`,
`reserved`, `reserveUnits`, `available`).

### 7.4 `ConsumerViewDto`

`structureId`, `structureName`, `structureType`, `townId`, `isConsumer`, `hasWorkers`, `workersTotal`, `workersPresent`,
`carrierCapacity`, `serviceWarehouseId`, `serviceWarehouseName`, `serviceSource`, `storages[]` (`storageId`,
`storageName`, `purpose`, `lines[]`: `itemBlueprintId`, `itemBlueprintName`, `stock`, `inbound`, `reorderPoint`,
`targetLevel`, `priorityClass`, `settingSource`, `consumerReplenishmentId`, `ruleIds[]`), `openReservations[]`,
`warnings[]`.

## 8. Game settings `production.logistics`

Inside the production section of `PUT api/GameSettings`; a missing `logistics` section keeps the stored one (else the
defaults). A wrong value is refused with the key, for example `production.logistics.reservationMinutes must be 1 to
10080.`

| Field | Default | Range |
|---|---|---|
| `plannerIntervalMinutes` | 10 | 1-1440 |
| `reservationMinutes` | 30 | 1-10080 |
| `consumptionWindowDays` | 7 | 1-90 |
| `defaultReorderHours` | 4 | 0-720, at most `defaultTargetHours` |
| `defaultTargetHours` | 12 | above 0, at most 720 |
| `runRetentionDays` | 14 | 1-365 |

## 9. Elsewhere

1. `TransportService.CreatePlannedAsync` makes the collection orders: origin `Distribution`, carrier = the consumer
   structure, source = the warehouse storage, one stop at the consumer storage, idempotency key
   `logistics:<runId>:<consumerStorageId>:<warehouseStorageId>`.
2. The production view's inbound evaluation (`TransportService.EvaluateAsync`) uses a producer's service area when it
   has no preferred warehouse; a warning says when that warehouse can't take the delivery.
3. Lookups (`api/Lookup`) with a `townId` filter for the rule editor's and settings' pickers: `Warehouse`, `District`,
   `Structure`, `ProductionStructure`, `Shop`, `LogisticsPolicy`, `LogisticsReservation`, `LogisticsPlannerRun`, and
   since [#928](https://github.com/PandiO/knk-workspace/issues/928) `LogisticsRule`, `ConsumerReplenishment` and
   `Storage` (storages held by the town, one of its districts or a structure in it).
