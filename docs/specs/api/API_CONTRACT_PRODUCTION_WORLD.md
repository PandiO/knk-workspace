# API Contract: Production world (`api/Warehouses`, `api/ProductionStructures`, structure placement)

**Status:** Current · **Last updated:** 2026-11-19 (P3 fields `productionKindId`, `workersPresent` point to the engine contract; docs #839); 2026-11-19 (first version, production P2 #91, docs PandiO/knk-workspace#830)
**Checked against:** knk-web-api `next` `fcfced27` (PR PandiO/knk-web-api#57; `Controllers/WarehousesController.cs`,
`Controllers/ProductionStructuresController.cs`, `Dtos/ProductionWorldDtos.cs`, `Dtos/StructureDtos.cs`,
`Services/Production/`), knk-plugin `next` `8ebb30be` (PR PandiO/knk-plugin#96; the territory lookup, § 6). Not released.
**Related:** [production world architecture](../../architecture/production-world.md) (rules, placement, region kinds),
[production DESIGN § 3.3–3.4](../production-storage-transport/DESIGN.md#33-world-entities),
[admin guide](../../guides/admin/production-world-admin-guide.md), [stock API contract](API_CONTRACT_STOCK.md) (the
structures' storages), [territory § 4](../../architecture/territory.md#4-api-contract) (flags, loyalty, report),
[smoke test § 3.1](../../guides/production-storage-transport-smoke-test.md#31-steps-api) (every endpoint with an example)

JSON property names are camelCase; enums travel as strings (`"Nearest"`, `"Unconnected"`). Both controllers work while
the game setting **Production enabled** is off. Paged searches take the common `PagedQueryDto` (`pageNumber`,
`pageSize`, `searchTerm`, `sortBy`, `sortDescending`, `filters` as a string map) and answer `PagedResultDto<T>`.

## 1. Access

| Endpoints | Needs |
|---|---|
| `GET` and `POST …/search` on both | `knk.admin.world` (World area), or the plugin key |
| `POST`, `PUT {id}` on both | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| `DELETE {id}` on both | `knk.admin.world` and `knk.admin.delete` |
| `PUT api/ProductionStructures/{id}/road-connection` | `knk.admin.world`, or the plugin key |

A missing node is 401/403 as for every staff endpoint.

## 2. Placement fields (every structure: `api/Structures`, `api/Warehouses`, `api/ProductionStructures`)

Added to `StructureDto` by P2. A structure is **in a district** or **rural**: exactly one of `districtId` and `townId`
is set; 0 counts as not set.

| Field | Type | Notes |
|---|---|---|
| `districtId` | int? | in a district: required with `streetId` and `houseNumber` > 0 |
| `streetId` | int? | required in a district; must be empty when rural |
| `houseNumber` | int | > 0 in a district; saved as 0 when rural |
| `townId` | int? | rural: the structure's own town; null in a district |
| `effectiveTownId` | int? | read only: the district's town, or `townId` |
| `isRural` | bool? | read only: no district |
| `placementWarnings` | string[]? | read only, **create only**: placement rules that failed as warnings, "<field>: <message>", or "<field>: not checked (…)" |
| `loyaltyTownId`, `territoryFlag`, `territoryFlaggedAt`, `territoryConflictId` | | read only, from territory ([territory § 4.3](../../architecture/territory.md#43-apiterritory)) |

Refusals (400, `{ "error": "<reason> (Parameter 'dto')" }` on the subtype endpoints):

1. "A structure is either in a district (districtId) or rural (townId): set exactly one of the two."
2. "StreetId is required for a structure in a district." / "HouseNumber must be greater than 0."
3. "A rural structure (townId) has no street: leave streetId empty."
4. "District with id N not found." / "Street with id N not found." / "Town with id N not found."
5. A **blocking** placement rule that failed: "<field label>: <message>" (for example "Region: P-2: the production
   structure's region is not inside its town's territory (or part of it is contested)."). A rule that could not run
   never refuses.

The database refuses both or neither too (check constraint `CK_structures_DistrictXorTown`). Deleting a street or town
a structure still uses answers 409 ("This street can't be deleted: it is still used by 1 structure. Remove or change
those first.") and the structure keeps it.

### 2.1 `POST api/Structures/search` row (`StructureListDto`)

New since P2: `townId` (the **effective** town: the district's town, or the rural structure's own), `isRural`,
`territoryFlag`, `townName`. Filters (`filters` map): `streetId` (`api/Structures` only), `districtId`, `townId` (matches the effective town), `isRural`
(`"true"`/`"false"`), `territoryFlag` (`Contested`, `OutsideTerritory`). The game server's territory report reads
`townId` from this search, so rural structures are flagged too.

## 3. `api/Warehouses`

### 3.1 `GET api/Warehouses`, `GET api/Warehouses/{id}`

`200` with `WarehouseDto` (all, or one; `404` if missing). Every structure field plus:

| Field | Type | Notes |
|---|---|---|
| `acceptsDeliveries` | bool? | default true |
| `priority` | int? | 0–1000, default 0; higher first among a town's warehouses |
| `defaultStorageId` | int? | the delivery storage created with it; on update another storage the warehouse holds; null keeps it |
| `storages` | `{ id, name, purpose }[]` | read only (single read): the storages it holds (kind `Domain`) |

### 3.2 `POST api/Warehouses`

Body: `WarehouseDto`; null fields take the default. Example (in a district):

```json
{ "name": "Market warehouse", "description": "", "wgRegionId": "tempregion_worldtask_12",
  "districtId": 4, "streetId": 9, "houseNumber": 3 }
```

`201` with the full DTO, `placementWarnings` and `storages` (one storage "Market warehouse - deliveries", purpose
`Delivery`, which is `defaultStorageId`). The structure, its storage and the region rename are one save; 400 as in § 2
or "priority must be 0 to 1000.".

### 3.3 `PUT api/Warehouses/{id}`

Body: `WarehouseDto`; null keeps. `204`; `404`; 400 as in § 2, "priority must be 0 to 1000." or "defaultStorageId must
be a storage this warehouse holds.". Placement warnings are not returned.

### 3.4 `DELETE api/Warehouses/{id}`

`204`: production structures that preferred it fall back to `Nearest`, its domain storages are deleted. `409` with
`{ "error" }` while one of its storages holds stock or has ledger history (nothing is deleted). `404`.

### 3.5 `POST api/Warehouses/search`

`PagedResultDto<ProductionWorldListDto>`: the structure row (§ 2.1) plus `acceptsDeliveries`, `priority`. Filters as in
§ 2.1. `sortBy`: `name` (default), `id`, `createdAt`. `searchTerm` matches name and description.

## 4. `api/ProductionStructures`

### 4.1 `GET api/ProductionStructures`, `GET api/ProductionStructures/{id}`

`200` with `ProductionStructureDto`. Every structure field plus:

| Field | Type | Notes |
|---|---|---|
| `productionKindId` | int? | the kind (P3: must exist, 0 clears; the read adds `productionKind` `{ id, name }`; [engine contract § 9.5](API_CONTRACT_PRODUCTION_ENGINE.md#95-changes-on-apiproductionstructures-crud-p3)) |
| `level` | int? | 1–10, default 1 |
| `productionEnabled` | bool? | default true |
| `automaticTransport` | bool? | default true |
| `transportThreshold`, `transportCapacity` | int? | ≥ 0; null = planner default; 0 on update clears |
| `warehousePreference` | `Nearest` \| `Preferred` | default `Nearest` |
| `preferredWarehouseId` | int? | required with `Preferred`; must exist; 0 clears |
| `preferredWarehouse` | `{ id, name }` | read only |
| `roadConnection` | `Unmeasured` \| `Connected` \| `Unconnected` | read only here (§ 4.6) |
| `roadConnectionMeasuredAt` | UTC date? | read only |
| `workersTotal` | int? | 0–100, default 2 |
| `workersPresent` | int? | read only here; `PUT …/workers` writes it ([engine contract § 9.3](API_CONTRACT_PRODUCTION_ENGINE.md#93-put-apiproductionstructuresidworkers)) |
| `warnings` | string[] | read only (single read): "Not connected to its town's road network: automatic transport is held.", "Its land is contested: it keeps its town and keeps producing.", "Outside its town's territory: it keeps its town and keeps producing." |
| `storages` | `{ id, name, purpose }[]` | read only (single read) |

### 4.2 `POST api/ProductionStructures`

Body: `ProductionStructureDto`. Example (rural):

```json
{ "name": "Quarry", "description": "", "wgRegionId": "tempregion_worldtask_13", "townId": 7 }
```

`201` with the full DTO, `placementWarnings` and one storage "Quarry - output" (purpose `Output`). 400 as in § 2 or:
"level must be 1 to 10.", "transportThreshold can't be negative.", "transportCapacity can't be negative.",
"workersTotal must be 0 to 100.", "Warehouse with id N not found.", "warehousePreference must be Nearest or
Preferred.", "warehousePreference Preferred needs a preferredWarehouseId.".

### 4.3 `PUT api/ProductionStructures/{id}`

As § 3.3 with the fields of § 4.1. Moving between a district and rural is an update with the new placement (the other
side cleared); the storages stay.

### 4.4 `DELETE api/ProductionStructures/{id}`

As § 3.4: `204`, or `409` while a storage holds stock or history.

### 4.5 `POST api/ProductionStructures/search`

As § 3.5, with the row's `productionKindId`, `level`, `productionEnabled`, `roadConnection`. Extra filters:
`productionKindId`, `roadConnection`.

### 4.6 `PUT api/ProductionStructures/{id}/road-connection`

The game server's lane measurement (DESIGN § 7.6, P5b). Body `{ "roadConnection": "Connected" }`. `200` with the full
DTO; `roadConnectionMeasuredAt` is set (cleared for `Unmeasured`). 400 "roadConnection must be Unmeasured, Connected or
Unconnected."; 404. Automatic transport is held for a rural structure unless `Connected` (D5).

## 5. Validation type `InsideTerritory`

Registered in the validation registry next to `RegionContainment` (`FieldValidationRule.ValidationType`).

1. **ConfigJson:** `{ "holderKind": "Town", "holderIdPath": "Id" }` (both optional; `holderKind` `Town` or `Kingdom`).
2. **Field value:** a region id, a record with `WgRegionId`, or a location record with `X` and `Z` (and `World`).
   **Dependency:** the holder record (its id at `holderIdPath`, `Name`, `WorldName`) or a bare id.
3. **Result:** valid "Inside <name>'s territory."; invalid "The region is not (wholly) inside <name>'s territory, or part
   of it is contested." (or "The location is not inside …"); placeholders `townName`, `holderName`.
4. **Skipped** (valid, metadata `skipped: ProductionDisabled`) while the game setting **Production enabled** is off.
5. **Could not run** (metadata `failureReason: TerritoryLookupUnavailable`): the game server is unreachable or answered
   anything but 200. The form shows it; a save through the API turns it into a "not checked" warning, never a refusal.

## 6. Game server: territory lookup (knk-plugin region HTTP server)

Called by the API (`TerritoryLookupClient`, 10 s time-out) at `MinecraftPlugin:BaseUrl` with header `X-API-Key: <plugin
key>`. Holder parameters: `holderKind` (`Town` or `Kingdom`) and `holderId`; `world` optional.

1. `GET /api/territory/contains-region/{regionId}?holderKind=Town&holderId=7[&world=world]`: inside when every block
   column of the region and its sub-regions is owned by the holder (contested columns are not owned). Regions over 1024
   columns per side are sampled.
2. `GET /api/territory/contains-location?holderKind=Town&holderId=7&x=120&z=-40[&world=world]`: inside when that column's
   owner is the holder and it is not contested; without `world` the server's default world.

| Status | Body |
|---|---|
| 200 | `{"inside":true,"holder":"Town 7","columns":48,"notOwned":0}`; a location adds `"owner":"Town 7","contested":false`; `"inside":false` adds a `"reason"` |
| 503 | `{"inside":null,"available":false,"reason":"territory is off on this game server (production.enabled: false)"}` (also before the first cache build, or when the region could not be read) |
| 400 | `{"inside":null,"available":true,"reason":"…"}` naming the bad parameter ("holderKind must be Town or Kingdom", "holderId must be a whole number", "x and z must be numbers", "regionId is required") |
| 401 | missing or wrong plugin key |
| 404 | `region <id> not found[ in <world>]`, or an unknown path |
| 405 | not a GET |

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#830).
2. 2026-11-19: `productionKindId` and `workersPresent` point to the [production engine contract](API_CONTRACT_PRODUCTION_ENGINE.md) (docs PandiO/knk-workspace#839).
