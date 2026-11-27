# API Contract: Player harvesting, resource pools and the harvest catalogue

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P8a #685, docs PandiO/knk-workspace#922)
**Checked against:** knk-web-api `next` `9ad32c23` (PR PandiO/knk-web-api#72; `Controllers/HarvestRulesController.cs`
with `HarvestRulesController`, `ResourcePoolsController`, `PlayerHarvestsController` and `HarvestController`,
`Dtos/ProductionHarvestDtos.cs`, `Services/Production/ProductionHarvest.cs`, `Models/Production/ProductionHarvest.cs`,
`Enums/ProductionHarvestEnums.cs`, `Services/Territory/ProductionSettings.cs`). Not released.
**Related:** [harvesting architecture](../../architecture/production-harvesting.md) (pool math, the split, the plugin
side), [PRODUCTION_KINDS § 6-§ 7](../production-storage-transport/PRODUCTION_KINDS.md),
[production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) (kinds, `poolFloor`, the production view),
[stock API contract](API_CONTRACT_STOCK.md) (the ledger, reason `PlayerHarvest`),
[harvesting admin guide](../../guides/admin/production-harvesting-admin-guide.md),
[smoke test § 9.1](../../guides/production-storage-transport-smoke-test.md#91-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names, errors `{ "error": "<reason>" }`, paged searches take `PagedQueryDto` and answer `PagedResultDto<T>`.
Times are UTC. Amounts are raw units of the rule's blueprint. On create and update a `null` field means "keep" (on
create: the default).

**The switch.** Rule and pool CRUD, the balance check and the history work while the API's game setting **Production
enabled** (`Production:Enabled`) is off. `GET api/Harvest/catalog` then answers `featureEnabled: false` with empty
lists, and `POST api/Harvest/reports` is 409 `{ "code": "ProductionDisabled", "error": ... }`.

**Status codes:** 400 validation (`{ "error": "<field rule>" }`), 403 a caller who may not, 404 a missing row, 409
`ProductionDisabled`, a conflict (`"The rule has booked harvests (history); switch it off instead of deleting it."`,
`"The area already has a resource pool (one per area)."`) or a concurrent save (`"The data changed while saving; try
again (a harvest report with the same keys)."`).

## 1. Access

| Route | Plugin key | `knk.admin.world` | + `knk.admin.delete` |
|---|---|---|---|
| `GET api/HarvestRules`, `GET …/{id}`, `POST …/search`, `GET …/{id}/balance` | yes | yes | — |
| `POST api/HarvestRules`, `PUT …/{id}` | yes | yes (and the dashboard change rule for `HarvestRule`) | — |
| `DELETE api/HarvestRules/{id}` | yes | — | yes |
| `GET api/ResourcePools`, `GET …/{id}`, `POST …/search` | yes | yes | — |
| `POST api/ResourcePools`, `PUT …/{id}` | yes | yes (and the dashboard change rule for `ResourcePool`) | — |
| `DELETE api/ResourcePools/{id}` | yes | — | yes |
| `GET api/PlayerHarvests/{id}`, `POST api/PlayerHarvests/search` | yes | yes | — |
| `GET api/Harvest/catalog` | yes | yes | — |
| `POST api/Harvest/reports` | yes, only | — | — |

Reads need the World dashboard area (`knk.admin.world` or a node under it) or the plugin key. The dashboard types
`HarvestRule` and `ResourcePool` are editable, `PlayerHarvest` is view only; all three are in the World area and have
lookups (`HarvestRule`, `ResourcePool`, `PlayerHarvest` with filters `productionStructureId` and `harvestRuleId`). The
rules are pinned in `ReadAccessRulesTests`, `DeleteAccessRulesTests`, `DashboardChangeAccessRulesTests` and
`LookupFiltersTests`.

## 2. `api/HarvestRules`

### 2.1 `HarvestRuleDto`

```json
{
  "id": 4,
  "name": "Stone",
  "productionKindId": 3,
  "productionKind": { "id": 3, "name": "Quarry" },
  "enabled": true,
  "targetKind": "Block",
  "targets": ["STONE", "DEEPSLATE"],
  "targetsJson": "[\"STONE\",\"DEEPSLATE\"]",
  "minBlockAge": null,
  "requiredPermission": "knk.harvest.quarry",
  "minTitleBracketId": null,
  "minTitleBracket": null,
  "toolClass": "Pickaxe",
  "minToolTier": "Stone",
  "yieldItemBlueprintId": 12,
  "yieldItemBlueprint": { "id": 12, "name": "Cobblestone" },
  "yieldPerBreak": 2,
  "fortuneBonusPerLevel": 0.25,
  "workerShare": 0.25,
  "poolCost": 1,
  "cooldownSeconds": null,
  "placeholder": "DepletedBlock",
  "placeholderMaterial": "BEDROCK",
  "regenSeconds": 60,
  "regenScalesWithPool": true,
  "note": null,
  "createdAt": "2026-11-21T09:00:00Z"
}
```

| Field | Create | Rule |
|---|---|---|
| `name` | required | 1 to 100 characters, unique per kind |
| `productionKindId` | required | an existing kind; can't change later |
| `enabled` | default true | off: left out of the catalogue, reports Rejected |
| `targetKind` | default Block | Block or Entity |
| `targets` (or `targetsJson`) | required | 1 to 50 names of letters, digits and `_`, at most 64 characters, upper-cased; one `*` at the start or end (`*_LOG`). `targetsJson` is the same list as JSON text (what the form seed sends), used when `targets` is null |
| `minBlockAge` | none | 0 to 25; 0 clears it |
| `requiredPermission` | none | a node of `a-z 0-9 . _ - *`, at most 150 characters; `""` clears it |
| `minTitleBracketId` | none | an existing title bracket; 0 clears it |
| `toolClass` | Any | Any, Pickaxe, Axe, Shovel, Hoe, Shears, Sword, FishingRod |
| `minToolTier` | Any | Any, Wood, Stone, Iron, Gold, Diamond, Netherite |
| `yieldItemBlueprintId` | required | an existing blueprint |
| `yieldPerBreak` | 1 | above 0, at most 64 |
| `fortuneBonusPerLevel` | 0 | 0 to 1; yield × (1 + bonus × level), the level counted up to IV |
| `workerShare` | 0.25 | 0 to 1 |
| `poolCost` | 1 | 0 to 1 000 000 per break |
| `cooldownSeconds` | none | up to 86 400; 0 clears it |
| `placeholder` | DepletedBlock | DepletedBlock, Replant, Air, Sapling, None |
| `placeholderMaterial` | none (the world's default) | a material name of `A-Z 0-9 _`; `""` clears it |
| `regenSeconds` | 60 | 1 to 604 800 |
| `regenScalesWithPool` | false | up to twice `regenSeconds` at an empty pool |
| `note` | none | at most 500 characters |

### 2.2 Routes

1. `GET api/HarvestRules` → `HarvestRuleDto[]` (by kind, then name); `GET api/HarvestRules/{id}` → `HarvestRuleDto` or
   404.
2. `POST api/HarvestRules` → 201 `HarvestRuleDto`; `PUT api/HarvestRules/{id}` → 200 `HarvestRuleDto`.
3. `DELETE api/HarvestRules/{id}` → 204; 409 once the rule has booked harvests.
4. `POST api/HarvestRules/search` (`PagedQueryDto`; filters `productionKindId`, `enabled`; sort `id`,
   `productionKindName`, else name) → `PagedResultDto<HarvestRuleListDto>`: `id`, `name`, `productionKindId`,
   `productionKindName`, `enabled`, `targetKind`, `yieldItemBlueprintId`, `yieldItemBlueprintName`, `yieldPerBreak`,
   `workerShare`, `poolCost`.

### 2.3 `GET api/HarvestRules/{id}/balance` → `HarvestRuleBalanceDto` (F9)

```json
{
  "harvestRuleId": 4,
  "harvestRuleName": "Stone",
  "townSharePerBreak": 1.5,
  "netPositive": true,
  "warnings": [],
  "areas": [
    {
      "productionAreaId": 7, "productionAreaName": "Pit",
      "productionStructureId": 21, "productionStructureName": "Quarry",
      "baseRatePerHour": 60, "poolFloor": 0.5, "poolCapacity": 1000, "regenPerHour": 83.333333,
      "poolExists": true, "townSharePerBreak": 1.5, "lostPerBreak": 0.00018, "netPositive": true
    }
  ]
}
```

1. `townSharePerBreak = yieldPerBreak × (1 − workerShare)`, without fortune.
2. `lostPerBreak = baseRatePerHour × (1 − poolFloor) × (poolCost ÷ poolCapacity) × (poolCost ÷ regenPerHour) ÷ 2`;
   `null` when the pool never refills (capacity or regeneration 0), 0 when `poolCost` is 0. `baseRatePerHour` is the sum
   over the structure's enabled lines before modifiers and built-in steps.
3. An area without a pool gets the numbers a new pool would get (`poolExists: false`).
4. `netPositive` is per area `lostPerBreak < townSharePerBreak` (`null` counts as not); the top-level value is true
   when every area is, also when the kind has no areas. `warnings` holds one line per area that is not.

## 3. `api/ResourcePools`

### 3.1 `ResourcePoolDto`

```json
{
  "id": 2,
  "productionAreaId": 7,
  "productionArea": { "id": 7, "name": "Pit" },
  "productionStructureId": 21,
  "productionStructure": { "id": 21, "name": "Quarry" },
  "capacity": 1000,
  "current": 940.5,
  "regenPerHour": 83.333333,
  "capacityFromSurvey": true,
  "capacitySurveyId": 15,
  "fill": 0.9405,
  "poolFactor": 0.97025,
  "poolFloor": 0.5,
  "hoursToFull": 0.71,
  "lastRegenAt": "2026-11-21T09:10:00Z",
  "createdAt": "2026-11-21T09:00:00Z",
  "updatedAt": "2026-11-21T09:10:00Z"
}
```

1. **Read:** `current` is the units left now (regeneration since `lastRegenAt` added); `fill = current ÷ capacity`;
   `poolFactor` is what this pool alone gives the structure (`floor + (1 − floor) × fill`); `hoursToFull` is null when
   full or not regenerating. The list DTO (`ResourcePoolListDto`: `id`, `name`, area and structure ids and names,
   `capacity`, `current`, `regenPerHour`, `lastRegenAt`) shows `current` **as stored**, without the regeneration since.
2. **Create** (`POST`, 201): `productionAreaId` required (one pool per area, 409 otherwise). `capacity` null = the
   latest survey's total units, else `production.harvest.defaultPoolCapacity`; `current` null = full; `regenPerHour`
   null = capacity ÷ `defaultRegenHoursToFull`; a typed `capacity` turns `capacityFromSurvey` off unless it is sent.
3. **Update** (`PUT`): `capacity` (above 0, at most 1 000 000 000), `current` (not negative, capped at the capacity),
   `regenPerHour` (0 to 1 000 000 000), `capacityFromSurvey`. The pool can't move to another area. The structure is
   settled first, so the time before counts at the old pool factor.
4. **Delete** (204): the next harvest in the area makes a new, full pool.
5. **Search** (`PagedQueryDto`; filters `productionStructureId`, `productionAreaId`; sort `name` (the structure),
   `capacity`, else id).
6. **Surveys:** with `capacityFromSurvey` on, each new survey of the area sets `capacity` to its total units and keeps
   the fill and the hours to full; `capacitySurveyId` names it. A survey of 0 units changes nothing.

## 4. `api/Harvest`

### 4.1 `GET api/Harvest/catalog` → `HarvestCatalogDto`

What the game server needs to decide breaks and regenerate blocks.

```json
{
  "featureEnabled": true,
  "generatedAt": "2026-11-21T09:10:00Z",
  "rules": [ { "id": 4, "name": "Stone", "productionKindId": 3, "...": "every HarvestRuleDto field" } ],
  "areas": [
    {
      "productionAreaId": 7, "name": "Pit",
      "productionStructureId": 21, "productionStructureName": "Quarry", "productionKindId": 3,
      "productionEnabled": true, "worldName": "world",
      "shape": "Cuboid", "wgRegionId": null, "points": null,
      "centerX": null, "centerY": null, "centerZ": null, "radius": null,
      "minX": 100, "minY": 60, "minZ": 100, "maxX": 109, "maxY": 69, "maxZ": 109,
      "poolFill": 0.9405
    }
  ]
}
```

1. `rules`: the enabled rules of every kind (full `HarvestRuleDto`).
2. `areas`: the areas of structures whose kind has an enabled rule; `productionEnabled` false means its reports are
   Rejected (the game server denies with "production at … is switched off"); `shape` Region, Cuboid, Polygon or Radius;
   `poolFill` is 1 without a pool.
3. While `Production:Enabled` is off: `featureEnabled: false` and both lists empty.

### 4.2 `POST api/Harvest/reports` → `HarvestReportResultDto`

The plugin key only. Books each entry once per idempotency key.

```json
{
  "entries": [
    {
      "idempotencyKey": "harvest-survival-1-0b5e…",
      "userId": 12,
      "harvestRuleId": 4,
      "productionAreaId": 7,
      "breaks": 3,
      "fortuneLevel": 0,
      "harvestedAt": "2026-11-21T09:09:58Z"
    }
  ]
}
```

1. **Report:** 1 to `production.harvest.maxEntriesPerReport` (200) entries; every entry needs its own key (1 to 100
   characters of letters, digits and `: _ . -`). A report that breaks these rules is 400 and books nothing.
2. **Entry:** `breaks` 1 to 10 000 (default 1), `fortuneLevel` 0 to 255 (default 0; counted up to IV), `harvestedAt`
   at most 10 minutes in the future (default now). The game server may group breaks of the same player, rule, area and
   fortune level into one entry.
3. **Per entry, in its own transaction** (area row lock, then the user row lock): settle the structure; make the pool
   if missing; regenerate it to now and draw `poolCost × breaks` (not below 0); split the yield (worker's share
   `SYS_PRODUCTION → SYS_WORLD`, the town's share `SYS_PRODUCTION → Output`, both reason `PlayerHarvest`, fractions
   carried per player and rule); store a `PlayerHarvest` row.
4. **Answer:** HTTP 200 with one result per entry, in order:

```json
{
  "featureEnabled": true,
  "entries": [
    {
      "idempotencyKey": "harvest-survival-1-0b5e…",
      "status": "Applied",
      "error": null,
      "playerHarvestId": 88,
      "userId": 12, "harvestRuleId": 4, "productionAreaId": 7, "productionStructureId": 21,
      "itemBlueprintId": 12,
      "yieldUnits": 6, "workerUnits": 1, "townUnits": 4, "townAccepted": 4, "townLost": 0,
      "poolBefore": 943.5, "poolAfter": 940.5, "poolCapacity": 1000,
      "regenSeconds": 64,
      "shortfallReason": null
    }
  ]
}
```

| `status` | Meaning |
|---|---|
| `Applied` | Booked now. The game server hands the player `workerUnits` of `itemBlueprintId` and restores the block after `regenSeconds` |
| `Replayed` | The key was booked before with the same entry; the stored result is returned (pay only if not paid yet) |
| `Rejected` | Not booked; `error` says why: the rule or area not found, the rule switched off, a rule of another kind than the area's structure, the structure's production switched off, the user not found, `breaks`/`fortuneLevel` out of range, `harvestedAt` in the future, or the key already used for a different entry |

`workerUnits` and `townUnits` are whole units (the fractions are carried). `townAccepted` is what the Output storage
took; `townLost = townUnits − townAccepted` with `shortfallReason` set (F10: the player is paid anyway).
`regenSeconds` is the rule's, or up to twice that at an empty pool with `regenScalesWithPool`.

A failure of the worker's share move is 409 for the whole report ("The worker's share could not be booked; try again
with the same key."); entries booked before it in the same report stay booked and answer Replayed on the retry.

## 5. `api/PlayerHarvests` (read only)

1. `GET api/PlayerHarvests/{id}` → `PlayerHarvestDto`: the key, user, rule, area and structure (ids and names), the
   blueprint, `breaks`, `fortuneLevel`, `harvestedAt`, `receivedAt`, `yieldUnits`, `workerShare`, `workerUnits`,
   `townUnits`, `townAccepted`, `poolBefore`, `poolAfter`, `poolCapacity`, `regenSeconds`, `workerTransactionId`,
   `townTransactionId` (the stock transactions) and `shortfallReason`.
2. `POST api/PlayerHarvests/search` (`PagedQueryDto`; the search term matches the username or the rule; filters
   `userId`, `harvestRuleId`, `productionStructureId`, `productionAreaId`; newest first by default, sort `id`, `name`
   (the rule) or the received time) → `PagedResultDto<PlayerHarvestListDto>`.

## 6. Game settings `production.harvest`

Inside the production section of `PUT api/GameSettings`; the defaults apply when the section is missing.

```json
{ "harvest": { "defaultPoolCapacity": 1000, "defaultRegenHoursToFull": 12, "maxEntriesPerReport": 200 } }
```

| Key | Default | Rule |
|---|---|---|
| `defaultPoolCapacity` | 1000 | above 0, at most 1 000 000 000: a new pool's capacity when the area has no survey |
| `defaultRegenHoursToFull` | 12 | above 0, at most 8760 (a year): a new pool regenerates its capacity in this many hours |
| `maxEntriesPerReport` | 200 | 1 to 500: the most entries one report may carry (keep the plugin's `report-batch` at or below it) |

A wrong value is refused with the key, for example `production.harvest.maxEntriesPerReport must be 1 to 500.`

## 7. Elsewhere

1. `ProductionKindDto.poolFloor` (0 to 1, default 0.5, P-D6) on `api/ProductionKinds`.
2. `poolFactor` on the structure's production view and on `ProductionCycleRecordDto` (default 1), with the not-producing
   reason "Player harvesting has drawn down the resource pool: N% output until it regenerates." below 1.
3. Stock reason `PlayerHarvest` on the two moves of each harvest, source type `PlayerHarvest`, source ref the entry key,
   stock keys `harvest:<key>:worker` and `harvest:<key>:town`.

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#922), checked against knk-web-api `next` `9ad32c23`.
