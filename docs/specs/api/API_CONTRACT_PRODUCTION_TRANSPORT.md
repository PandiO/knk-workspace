# API Contract: Production transport orders, lanes and road connections

**Status:** Current · **Last updated:** 2026-11-20 (P6 adds `POST api/TransportOrders/{id}/retry`, see the storage menus contract § 4, docs #903); 2026-11-20 (first version, production P5 #79/#681, docs PandiO/knk-workspace#891)
**Checked against:** knk-web-api `next` `bf8633fb` (PR PandiO/knk-web-api#65; `Controllers/TransportOrdersController.cs`,
`Controllers/TransportLanesController.cs`, the P5 actions of `Controllers/ProductionStructuresController.cs`,
`Dtos/TransportDtos.cs`, `Services/Production/TransportService.cs`, `TransportLaneService.cs`, `TransportRouting.cs`).
Not released.
**Related:** [transport architecture](../../architecture/production-transport.md) (lifecycle, ledger, triggers, lanes),
[production DESIGN § 7](../production-storage-transport/DESIGN.md), [admin guide](../../guides/admin/production-transport-admin-guide.md),
[production world API contract](API_CONTRACT_PRODUCTION_WORLD.md) (`api/ProductionStructures`, `api/Warehouses`),
[production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) (`api/GameSettings` production section),
[smoke test § 6.1](../../guides/production-storage-transport-smoke-test.md#61-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names, a **null field means "keep"** on update, errors `{ "error": "<reason>" }`, paged searches take
`PagedQueryDto` and answer `PagedResultDto<T>`. Status codes: 400 for a validation error, 404 for a missing row, 409 for
a conflict. Times are UTC.

## 1. Access

| Endpoints | Needs |
|---|---|
| `GET api/TransportOrders/{id}`, `POST api/TransportOrders/search`, `GET api/TransportLanes/{id}`, `POST api/TransportLanes/search`, `GET api/TransportLanes/due`, `GET api/ProductionStructures/{id}/transport` | `knk.admin.world` (World area), or the plugin key |
| `POST api/TransportOrders`, `POST api/TransportOrders/dry-run`, `POST api/TransportOrders/{id}/cancel`, `POST api/TransportOrders/run-now`, `POST api/TransportLanes/report`, `PUT api/ProductionStructures/{id}/road-connection` | `knk.admin.world`, or the plugin key |
| `POST api/TransportLanes`, `PUT api/TransportLanes/{id}` | `knk.admin.world` and `knk.admin.content` (dashboard change rule), or the plugin key |
| `DELETE api/TransportLanes/{id}` | `knk.admin.world` and `knk.admin.delete` |

Orders have no `PUT` or `DELETE`: they are written by the transport service only. Everything except `run-now` and
`due` works while the game setting **Production enabled** (`Production:Enabled`) is off; orders then wait.

## 2. `api/TransportOrders`

### 2.1 `GET api/TransportOrders/{id}` → `TransportOrderDto`

| Field | Type | Meaning |
|---|---|---|
| `id`, `origin`, `status`, `statusReason` | | `origin`: `Automatic`, `Manual`, `Quest` (`Distribution`, `Trade` reserved); `status`: see the [architecture § 3](../../architecture/production-transport.md#3-the-status-lifecycle-design--72) |
| `sourceStorageId`, `sourceStorage` | int, `{ id, name }` | Where the cargo starts |
| `sourceStructureId`, `sourceStructure` | int?, ref? | The source storage's structure |
| `cargoStorageId`, `cargoStorage` | int, ref | The order's Transit storage ("Transport #<id> cargo") |
| `carrierStructureId`, `carrierStructure`, `carrierCapacity` | int?, ref?, long? | The production structure whose worker carries, and its capacity in raw units; null = a carrier without a worker |
| `risk` | decimal? | Always null in V1 |
| `currentStructureId`, `currentStopId` | int? | Where the carrier is or left last; the stop it heads for |
| `reroutes`, `cancelRequested` | int, bool | |
| `executeAfter`, `nextActionAt`, `createdAt`, `departedAt`, `legStartedAt`, `etaAt`, `waitingSince`, `completedAt` | date | `nextActionAt` null = final |
| `createdByUserId`, `note`, `clientKey` | | |
| `isFinal` | bool | `Delivered`, `Returned`, `Cancelled` or `Lost` |
| `inTransit` | `[{ itemBlueprintId, itemBlueprintName, amount }]` | What the Transit storage holds now |
| `stops` | `TransportStopDto[]` | In visiting order: `id`, `sequence`, `storageId`, `storage`, `structureId`, `structure`, `status` (`Pending`, `Delivered`, `Partial`, `Skipped`), `reroutedFromStopId`, `distanceBlocks`, `distanceSource` (`Lane`, `Estimated`, `Fallback`), `etaAt`, `arrivedAt`, `completedAt`, `attempts`, `lines` (`id`, `itemBlueprintId`, `itemBlueprintName`, `itemBlueprint`, `planned`, `delivered`) |
| `lines` | `TransportOrderLineDto[]` | Cargo per blueprint: `requested`, `loaded`, `delivered`, `returned`, `lost` |
| `assignments` | `TransportAssignmentDto[]` | `mode` (`Simulated`), `carrierStructureId`, `carrierStructure`, `workers` (0 or 1), `speedBlocksPerSecond`, `capacity`, `assignedAt`, `releasedAt` |
| `events` | `TransportEventDto[]` | First 500, oldest first: `id`, `at`, `kind`, `statusAfter`, `transportStopId`, `stockTransactionId`, `message` |

### 2.2 `POST api/TransportOrders/search` → `PagedResultDto<TransportOrderListDto>`

Newest first (`sortBy` set with `sortDescending: false` gives oldest first). Filters (`filters` map):

| Filter | Value |
|---|---|
| `status` | Comma list of statuses |
| `origin` | One origin |
| `open` | `true` (not final) or `false` |
| `sourceStructureId`, `sourceStorageId` | int |
| `storageId` | The source or any stop |
| `structureId` | The source, any stop or the carrier |

`searchTerm` is an order id (a leading `#` is allowed). A row: `id`, `origin`, `status`, `statusReason`,
`sourceStorageId`, `sourceStorageName`, `sourceStructureId`, `sourceStructureName`, `destinations` (the stops' storage
names joined with " → "), `unitsRequested`, `unitsLoaded`, `unitsDelivered`, `unitsReturned`, `createdAt`, `etaAt`,
`completedAt`.

### 2.3 `POST api/TransportOrders` (manual or quest order) and `POST api/TransportOrders/dry-run`

Both take `TransportOrderCreateDto`:

```json
{
  "sourceStorageId": 41,
  "carrierStructureId": null,
  "origin": "Manual",
  "executeAfter": null,
  "note": "Stock for the market",
  "clientKey": "web-5f1c…",
  "stops": [
    { "storageId": 77, "lines": [ { "itemBlueprintId": 12, "amount": 40 } ] },
    { "storageId": 78, "lines": [ { "itemBlueprintId": 12, "amount": 10 }, { "itemBlueprintId": 15, "amount": 4 } ] }
  ]
}
```

1. `carrierStructureId` null: the source storage's structure carries when it is a production structure; otherwise a
   simulated carrier without a worker.
2. `origin`: `Manual` (default) or `Quest`; anything else is 400.
3. `executeAfter`: not before this time (default now). `note` ≤ 500 and `clientKey` ≤ 80 characters.
4. **`clientKey`**: a create with a key already used returns the first order (201 with that order), also when two
   requests race.
5. The cargo is the sum of the stops' lines.

**Refusals** (400 on create, `valid: false` with `errors` on a dry run): the order is empty or has no stop or more than
10; the source or a stop is not found, or is a system (`Virtual`) or `Transit` storage; a stop is the source; a stop
without lines or with more than 50; an amount ≤ 0 (or over the stock maximum); a blueprint listed twice in a stop or not
found; an unknown or server-only origin; a carrier that is not a production structure; a carrier without workers; the
cargo (raw units, amount × storage weight) over the carrier's capacity ("The cargo is <n> units; a worker of <name>
carries at most <c>."). A create answers 400 with all errors in one sentence.

**`POST …/dry-run` → `TransportPlanDto`** (writes nothing):

| Field | Meaning |
|---|---|
| `valid`, `errors`, `warnings` | Warnings: short stock at the source ("loading takes what is there"), no free worker ("the order waits"), no production structure carries, a leg without a measured lane, a stop without room now ("the carrier would wait there") |
| `sourceStorageId`, `sourceStructureId`, `carrierStructureId`, `carrierCapacity`, `speedBlocksPerSecond`, `workersPresent`, `workersTotal` | |
| `lines` | Per blueprint: `itemBlueprintId`, `itemBlueprintName`, `requested`, `available` (what the source holds now) |
| `legs` | Per stop: `sequence`, `fromStructureId`, `toStructureId`, `toStorageId`, `toStorageName`, `distanceBlocks`, `distanceSource`, `seconds`, `lines`, `roomUnits` (null = uncapped) |
| `totalUnits`, `totalSeconds` | |

A create answers **201** with the `TransportOrderDto` (status `Planned`, event `Created`).

### 2.4 `POST api/TransportOrders/{id}/cancel`

Body `{ "reason": "…" }` (optional; the first 200 characters are kept). Answers 200 with the order:

1. `Planned`: `Cancelled` at once, no stock moved, its stops `Skipped`.
2. Loaded (`InTransit`, `AtStop`, `AwaitingSpace`): `cancelRequested` true, events `CancelRequested` and
   `ReturnStarted`, status `Returning`; it ends `Returned`.

404 for an unknown order; **409** "The order is already <status>." for a final order and "The order is already
returning its cargo." for `Returning` or `ReturnBlocked`.

Since P6 (#683) staff can also retry an order: `POST api/TransportOrders/{id}/retry`, in the
[storage menus API contract § 4](API_CONTRACT_PRODUCTION_STORAGE_MENUS.md#4-post-apitransportordersidretry--transportorderdto).

### 2.5 `POST api/TransportOrders/run-now` → `TransportSweepResultDto`

Runs the transport sweep now: the automatic triggers, then every open order (at most 200) as far as its times allow.
`{ "featureEnabled": true, "ranAt": "…", "ordersCreated": 1, "ordersAdvanced": 3, "ordersFailed": 0 }`. **409** `{
"error": "Production is turned off (Production:Enabled)." }` while the flag is off.

## 3. `GET api/ProductionStructures/{id}/transport` → `TransportStructureViewDto`

The automatic trigger's dry run for a production structure (writes nothing; 404 for an unknown structure):
`productionStructureId`, `featureEnabled`, `automaticTransport`, `roadConnection`, `isRural`, `effectiveTownId`,
`outputStorageId`, `outputUnits`, `outputMaxUnits`, `threshold`, `carrierCapacity`, `workersPresent`, `workersTotal`,
`workersAway`, `warnings`, `triggerReasons`, `heldReasons`, `wouldCreate` (a `TransportPlanDto`, null when held or not
triggered), `destinationWarehouseId`, `openOrders` (`TransportOrderListDto[]` of orders whose source or carrier is this
structure). The sentences are listed in the [architecture § 6](../../architecture/production-transport.md#6-automatic-triggers-and-the-d5-hold-design--74--76).

## 4. `PUT api/ProductionStructures/{id}/road-connection`

Body `{ "roadConnection": "Connected" }` (`Unmeasured`, `Connected` or `Unconnected`, any case). Sets the structure's
`roadConnection` and `roadConnectionMeasuredAt` (now; null for `Unmeasured`) and answers 200 with the
`ProductionStructureDto`. 400 for another value, 404 when the id is not a production structure (the game server sends
it for warehouses too and stops after the 404). A rural structure that is not `Connected` gets no automatic transport
(D5).

## 5. `api/TransportLanes`

### 5.1 `TransportLaneDto`

| Field | Type | Rules |
|---|---|---|
| `id` | int? | |
| `fromStructureId`, `toStructureId` | int | Required on create; two different structures that exist; one lane per (from, to) |
| `fromStructure`, `toStructure` | ref | Read only |
| `reachable` | bool? | Default true on create |
| `roadDistance` | decimal? | 0-1,000,000; **required when reachable**; cleared when not reachable |
| `straightDistance` | decimal? | 0-1,000,000 |
| `routeEdgeIds` | long[]? | Stored as JSON (≤ 8,000 characters) |
| `measuredSeconds` | int? | ≥ 0, shown only |
| `source` | string? | `Plugin` or `Manual` (default `Manual` on create, kept on update) |
| `measuredAt` | date? | Default now on create, and on an update that changes `roadDistance` or `reachable` |
| `note` | string? | ≤ 300 |

### 5.2 CRUD

1. `GET api/TransportLanes/{id}`; `POST api/TransportLanes/search`: newest measurement first; filters
   `fromStructureId`, `toStructureId`, `structureId` (either end), `source`; `searchTerm` matches either structure's
   name. A row: `id`, `fromStructureId`, `fromStructureName`, `toStructureId`, `toStructureName`, `reachable`,
   `roadDistance`, `straightDistance`, `source`, `measuredAt`.
2. `POST` → 201; `PUT {id}` → 200. 400 for a rule above, **409** "A lane between these two structures (in this
   direction) already exists; edit it instead." (or "Another lane …" on update).
3. `DELETE {id}` → 204; the pair is due again for the game server.

### 5.3 The game server's contract

1. **`GET api/TransportLanes/due?limit=100`** → `TransportLaneDueDto[]` (limit 1-500; empty while production is off):
   `fromStructureId`, `fromStructureName`, `from` (`{ world, x, y, z }` or null without a location),
   `toStructureId`, `toStructureName`, `to`, `reason` (`Missing` or `Stale`), `lastMeasuredAt`. The pairs: each
   production structure to each warehouse of its town that accepts deliveries, then a town's warehouses among
   themselves. A pair is due without a lane in either direction, or when its newest lane has source `Plugin` and is
   older than `production.transport.laneMaxAgeHours`.
2. **`POST api/TransportLanes/report`** with `{ "lanes": [TransportLaneDto, …] }` (at most 500) → `{ "created": 3,
   "updated": 0 }`. Each lane is upserted by its (from, to) pair with source `Plugin`; an unreachable lane is sent with
   `"reachable": false` and no road distance. One invalid lane refuses the whole report (400).

## 6. Game settings: `production.transport`

The section `transport` of the production settings (`GET`/`PUT api/GameSettings`):

```json
"transport": {
  "walkingSpeedBlocksPerSecond": 4.317, "defaultCarrierCapacity": 64, "defaultThresholdPercent": 75,
  "defaultThresholdUnits": 64, "unmeasuredRouteFactor": 1.4, "fallbackDistanceBlocks": 200,
  "awaitingSpaceMinutes": 30, "maxReroutes": 2, "laneMaxAgeHours": 24
}
```

Bounds and meaning: [architecture § 7.2](../../architecture/production-transport.md#72-settings). A save without the
section keeps the stored one; a value out of bounds is 400 "production.transport.<key> must be <min> to <max>.".

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#891).
