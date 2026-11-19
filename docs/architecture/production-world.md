# Production world: structure subtypes and placement (knk-web-api, knk-web-app and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-19 (first version, production P2 #91/#676/#677, docs PandiO/knk-workspace#830)
**Checked against:** knk-web-api `next` `fcfced27` (PR PandiO/knk-web-api#57), knk-web-app `next` `18385344` (PR
PandiO/knk-web-app#61), knk-plugin `next` `8ebb30be` (PR PandiO/knk-plugin#96). Not released; the manual steps of the
[smoke test § 3](../guides/production-storage-transport-smoke-test.md#3-phase-p2-world-rural-structures-warehouse-production-structure-91-api-676-web-app-677-plugin-tier3)
have not been run live yet.
**Related:** [production DESIGN § 3.3–3.4](../specs/production-storage-transport/DESIGN.md#33-world-entities) (the
rules), [API contract](../specs/api/API_CONTRACT_PRODUCTION_WORLD.md) (`api/Warehouses`, `api/ProductionStructures`),
[admin guide](../guides/admin/production-world-admin-guide.md), [stock core](stock-core.md) (the default storages),
[territory](territory.md) (the lookup and the structure flags), [managed WorldGuard regions](managed-worldguard-regions.md)
(the region kinds), [plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production)

Phase P2 of the production feature puts its buildings in the world. A structure now stands either **in a district** (as
before, with a street and house number) or **rural**, out in its town's territory with only a town. Two new structure
subtypes carry production: the **warehouse** (a town's storage hub) and the **production structure** (a farm, logger,
quarry …; the kind is data and comes with P3). Each gets its default storages from the [stock core](stock-core.md) when
it is created. Placement rules check, as warnings by default, that a structure's region lies in its district or in its
town's territory; the territory check asks the game server. Nothing produces yet: production lines and cycles are P3.

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| `Structure.TownId`, nullable `DistrictId`/`StreetId`, check constraint | knk-web-api | `Models/Structure.cs`, `Properties/KnKDbContext.cs` (one block) |
| `Warehouse`, `ProductionStructure` (TPT) and their enums | knk-web-api | `Models/Production/`, `Enums/ProductionWorldEnums.cs` |
| Placement (District-xor-Town) and the save-time rule check | knk-web-api | `Services/Production/StructurePlacement.cs` (`IStructurePlacement`), used by `StructureService` and the subtype services |
| Subtype services (CRUD, default storages, search, road connection) | knk-web-api | `Services/Production/ProductionWorldServices.cs`, `StructureBaseWriter.cs` |
| Controllers and DTOs | knk-web-api | `Controllers/WarehousesController.cs`, `ProductionStructuresController.cs`, `Dtos/ProductionWorldDtos.cs`, placement fields in `Dtos/StructureDtos.cs` |
| Validation type `InsideTerritory` and its lookup client | knk-web-api | `Services/ValidationMethods/InsideTerritoryValidator.cs`, `Services/Production/TerritoryLookupClient.cs` |
| Form and display seeds | knk-web-api | `Data/FormConfigurationSeeds/{Warehouse,ProductionStructure}.json`, `Data/DisplayConfigurationSeeds/…display.json` |
| Types, clients, columns, filter | knk-web-app | `src/types/dtos/structure/ProductionWorldDtos.ts`, `warehouseClient`, `productionStructureClient`, `objectConfigs`, `src/components/PagedEntityTable/TerritoryFlagFilterSelect.tsx` |
| Detail panels | knk-web-app | `src/components/production/StructurePlacementPanel.tsx`, `StructureStoragesPanel.tsx` (with `StructureTerritoryPanel` of territory) |
| Rule builder type | knk-web-app | `src/components/FormConfigBuilder/ValidationRuleBuilder.tsx` |
| Region kinds of the subtypes, rural regions | knk-plugin `knk-core` | `core/regions/managed/ManagedRegionKind.fromDomainType(type, production)`, `DomainRegionSpecs`, `ManagedRegionSpecSource` |
| Region creation hook | knk-plugin `knk-paper` | `paper/regions/managed/ManagedRegionsBootstrap.finalizeNewRegion` |
| Territory lookup endpoint | knk-plugin | `core/territory/TerritoryLookup.java`, `paper/http/TerritoryLookupHandler.java`, `paper/regions/RegionUnionOutlines.java` (wired in one `KnKPlugin` block) |
| Rural structures in the territory report | knk-plugin | `StructureSummary.townId`, `TerritoryService.StructureRef` |

## 2. Placement: in a district or rural

1. **District-xor-Town.** A structure has exactly one of `DistrictId` and `TownId`.
    1. **In a district:** `DistrictId`, a `StreetId` and a house number above 0, as before P2.
    2. **Rural:** `TownId`; no district, no street, house number 0.
    3. Enforced twice: `StructurePlacement.Normalize` (400 with the reason: "A structure is either in a district
       (districtId) or rural (townId): set exactly one of the two.", "StreetId is required for a structure in a
       district.", "A rural structure (townId) has no street: leave streetId empty.") and the MySQL check constraint
       `CK_structures_DistrictXorTown` (`(DistrictId IS NULL) <> (TownId IS NULL)`). A value of 0 counts as not set.
2. **Effective town** = the district's town, or `TownId` when rural (`StructurePlacement.EffectiveTownId`). The full
   DTO carries `townId` (own), `effectiveTownId` and `isRural`; the search row's `townId` is already the effective town.
3. **Applies to every structure type** saved through `api/Structures`, `api/Warehouses` and `api/ProductionStructures`.
   Gates stay district-only (unchanged) and get no save-time rule check (L6 decision 7).
4. **Moving a structure** between a district and rural is a normal update: send the new placement, the other side
   cleared. Its storages stay. Its WorldGuard region keeps its old parent (§ 6.3).
5. **Deleting a district, street or town** a structure still uses is refused (409 "still used by …"). The optional
   foreign keys are `ClientNoAction`, because `Restrict` on an optional relationship lets EF null the key of tracked
   structures and the delete would succeed silently (L6 decision 4).
6. **Audit:** every `Structure.District`/`Street` dereference (navigation, discovery, managed regions, domain access,
   teleport, siege) was checked for rural structures; the 13 call sites are listed in PandiO/knk-web-api#57. A rural
   structure's region-name finalizer sends **no parent region** (`DomainRegionNameFinalizer`: territory is not a
   region), and `GET api/Domains/by-region/{regionId}` lists no parent domains for it.

## 3. The subtypes

Both are TPT subtypes of `Structure` (tables `warehouses` and `production_structures`), so they carry every structure
field (name, region, access, spawn point, sub-regions, territory flag and loyalty). Fields left null on create get the
default; null on update means "keep".

### 3.1 `Warehouse`

| Field | Default | Rule |
|---|---|---|
| `AcceptsDeliveries` | true | takes deliveries from producers and transport (P5, P9) |
| `Priority` | 0 | 0–1000; higher first when several warehouses of a town could take a delivery |
| `DefaultStorageId` | the storage created with it | must be a storage the warehouse holds; `SET NULL` when that storage is deleted |

Deleting a warehouse resets every production structure that preferred it to `Nearest` (`BeforeDeleteAsync`).

### 3.2 `ProductionStructure`

| Field | Default | Rule |
|---|---|---|
| `ProductionKindId` | null | a plain indexed id until P3 adds the kind catalogue and the foreign key |
| `Level` | 1 | 1–10 (G8) |
| `ProductionEnabled` | true | the structure's own switch |
| `AutomaticTransport` | true | held while `RoadConnection` is not `Connected` for a rural structure (D5) |
| `TransportThreshold`, `TransportCapacity` | null (planner default) | ≥ 0; 0 on update clears it |
| `WarehousePreference` | `Nearest` | `Nearest` or `Preferred`; `Preferred` needs `PreferredWarehouseId` (an existing warehouse; 0 clears it) |
| `RoadConnection` | `Unmeasured` | `Unmeasured`, `Connected`, `Unconnected`; written only through `PUT …/road-connection` (the game server's measurement, P5b), which also sets `RoadConnectionMeasuredAt` |
| `WorkersTotal` | 2 | 0–100 |
| `WorkersPresent` | 2 | read only; P3/P5 write it |

`warnings` on a read (`ProductionStructureService.Warnings`, DESIGN § 3.4 R3 and § 7.6 D5):

1. "Not connected to its town's road network: automatic transport is held." (rural and `Unconnected`)
2. "Its land is contested: it keeps its town and keeps producing." (flag `Contested`)
3. "Outside its town's territory: it keeps its town and keeps producing." (flag `OutsideTerritory`)

A flagged structure keeps its town and keeps producing in V1 (A07); only the dashboard shows it.

### 3.3 Default storages

Created in the same transaction as the structure through `IStorageService.CreateAsync`, kind `Domain` with the
structure as holder (`DomainId`), uncapped:

| Subtype | Storage | Purpose |
|---|---|---|
| Warehouse | "<name> - deliveries" (becomes `DefaultStorageId`) | `Delivery` |
| Production structure | "<name> - output" | `Output` |

Names are cut at the storage name limit (100). P3 adds the kind's own storages next to the output storage. Deleting
the structure deletes its domain storages first; a storage that holds stock or has ledger history refuses with 409 and
the whole delete is rolled back. Storages added by hand to the structure (kind `Domain`, same `DomainId`) are listed
with it (`storages`) and deleted with it too.

## 4. Placement rules P-1 to P-3

Rules are ordinary form field validation rules on the Region field of the default `Warehouse` and
`ProductionStructure` forms. Every rule **warns** by default; an admin makes one blocking with its "Block step
progression" setting (`IsBlocking`, DESIGN § 3.4, R2).

| # | Rule | Validation type | Seeded |
|---|---|---|---|
| P-1 | A structure in a district has its region completely inside the district's region | `RegionContainment` (dependency District, `parentRegionPath: WgRegionId`, full containment) | both seeds, warning |
| P-2 | A rural structure's region lies inside its town's territory | `InsideTerritory` (dependency Town, `holderKind: Town`, `holderIdPath: Id`) | both seeds, warning |
| P-3 | A production area stays inside its structure's district or its town's territory | as P-1 / P-2 | waits for P4's areas |

1. **In the form wizard** the rules run as for any field (step progression, warnings in the step).
2. **On save through the API** (`IStructurePlacement.CheckRulesAsync`, run by `StructureService` and the subtype
   services on create and update): the default form's rules for the type run against the entity. A failed blocking rule
   is a 400 with "<field>: <message>"; failed warnings come back on create as `placementWarnings` (an update answers 204
   and drops them). The generic `Structure` form has no placement rules, so `api/Structures` returns an empty list
   unless an admin adds some.
3. **A rule that could not run** (game server offline, lookup missing) is a warning "<field>: not checked (…)", even
   when the rule is blocking: an offline server never stops authoring (L6 decision 3).
4. **`InsideTerritory`** (`InsideTerritoryValidator`):
    1. ConfigJson `{ "holderKind": "Town" | "Kingdom", "holderIdPath": "Id" }`, both optional. The field value is a
       region id (or a record with `WgRegionId`), or a location record with `X` and `Z`; the dependency is the holder.
    2. With the game setting **Production enabled** off the rule passes without a lookup ("Territory check skipped:
       production is off"), A21.
    3. Otherwise it asks the game server (§ 5) and answers "Inside <town>'s territory." or "The region is not (wholly)
       inside <town>'s territory, or part of it is contested." Placeholders `{townName}` and `{holderName}`.
    4. It reads external state, so a stored verdict expires (KNG-269).

## 5. Territory lookup (API → game server)

Territory is computed on the game server ([territory § 1](territory.md#1-who-computes-what)), so the API asks it. The
contract was agreed between L6 and L8 (knk-web-api `TerritoryLookupClient`, knk-plugin `TerritoryLookupHandler`).

1. **Where:** the plugin's region HTTP server (`region-http.bind-address`/`port`, default `127.0.0.1:8081`), at the
   API's `MinecraftPlugin:BaseUrl`, with the shared plugin key in `X-API-Key` (the API's `Security:PluginApiKey` = the
   plugin's `api.auth.api-key`). Time-out 10 seconds.
2. **Requests:**
    1. `GET /api/territory/contains-region/{regionId}?holderKind=Town&holderId=12[&world=W]`
    2. `GET /api/territory/contains-location?holderKind=Town&holderId=12&x=..&z=..[&world=W]`
3. **Answers:**

   | Status | Body | API shows |
   |---|---|---|
   | 200 | `{"inside": true, "holder": "Town 12", "columns": n, "notOwned": 0}` (region) or `{"inside": true, …, "owner": "Town 12", "contested": false}` (location) | passed |
   | 200 | `"inside": false` with a `reason` (region: how many columns the holder does not own and the first one) | the rule's failure message |
   | 503 | `{"inside": null, "available": false, "reason": "territory is off on this game server (production.enabled: false)"}`, also before the first cache build | "not checked" |
   | 400 / 404 / 401 | the reason (a bad `holderKind`, `region <id> not found`, missing key) | "not checked" |

4. **Region rule:** every block column of the region **and its sub-regions** (their union, KNG-257) must be owned by
   the holder; contested columns count as not owned. Up to 1024 columns per side the check is exact; larger regions are
   sampled evenly, always including the outline points and the last column (L8 decision 6). Region outlines are read
   on the main thread (8 s time-out).
5. **Location rule:** the column's owner must be the holder and not contested. Without `world` the server's first
   (default) world is used (L8 decision 4).
6. The endpoint is always registered; while `production.enabled` is off it answers 503 with the reason (L8 decision 3).

## 6. Game server: region kinds and rural regions

Everything here runs only with the plugin's `production.enabled: true` (A21); with it off the regions behave as before
P2 (a production structure stays `STRUCTURE`, a rural structure gets the "unknown district" warning).

1. **Kinds** (`ManagedRegionKind.fromDomainType(type, production)`), used by the startup repair, `/knk regions repair`
   and the region-creation hook:

   | Domain type | Kind | Flags |
   |---|---|---|
   | `ProductionStructure` | `RESOURCE_PRODUCTION` | `entry allow`, `entry-deny-message ""` (seeded); no `block-break` |
   | `Warehouse` | `STRUCTURE` | none |

   With production off a `ProductionStructure` stays `STRUCTURE`, because `RESOURCE_PRODUCTION` seeds `entry` flags
   (L8 decision 1).
2. **Rural regions** (a town, no district) are top level on purpose: no parent, the kind's floor priority 30, in their
   town's world, and no "unknown district" warning. So **PvP stays allowed** (the world default) and no town flags are
   inherited (DESIGN § 3.4, confirmed 2026-11-11). A structure in a district keeps its district's region as parent.
3. **Moving to rural** keeps the old parent: the repair never clears a parent (a safety rule other chains rely on).
   Staff clear it with `/rg setparent <region>`; [#824](https://github.com/PandiO/knk-workspace/issues/824) tracks
   doing it automatically.
4. **Territory report:** the structure search's `townId` (the effective town) feeds `TerritoryService.StructureRef`, so
   rural structures are flagged `Contested` or `OutsideTerritory` too ([territory § 5.3](territory.md#53-report-territoryreportbuilder)).
5. **Structure NPCs** are not protected yet: no structure NPCs exist; workers (P5) and shopkeepers (P11) will be
   invulnerable (L8 decision 7).

## 7. Web app

1. **Forms:** the seeded `Warehouse` and `ProductionStructure` forms (steps General information, Placement, Region and
   access, and Production or the warehouse's fields) with District, Street, House number and **Town (rural)**, and the
   RegionClaim world task on Region. No client-side District-xor-Town check: the API's `{ error }` sentence is shown on
   a refused save (`placementRefusalReason`, the .NET " (Parameter 'dto')" suffix cut). Each `placementWarnings` entry
   becomes a warning toast kept until closed ("Saved with a placement warning: …").
2. **Rule builder:** validation type **Inside Territory**: a new rule starts with the town holder config, the message
   "The region is not inside {townName}'s territory (or part of it is contested).", "Block step progression" off, and a
   help line.
3. **Dashboard:** columns Town, Placement, District and the subtype's own (Accepts deliveries, Priority; Level,
   Production, Road connection), Territory flag and World; Placement and Territory flag on Structure. A **Territory
   flag** filter ("All structures", "Flagged: in a contested zone", "Flagged: outside its town's territory") on the
   Structure, Warehouse and ProductionStructure lists (A07, #65).
4. **Detail pages** of warehouses and production structures (`DisplayWizardPage` for `isProductionWorldType`):
   `StructurePlacementPanel` (warnings, placement, effective town, region, deliveries and delivery storage or road
   connection, production, workers and delivery preference), `StructureTerritoryPanel` (flag and loyalty),
   `StructureStoragesPanel` (`POST api/Storages/search` with `domainId`, so storages added by hand show too) and one
   stock panel per storage. Road connection is shown only, never edited (L7 decision 7). The generic Structure page is
   unchanged apart from the columns and the filter.

## 8. Permissions

| Action | Needs |
|---|---|
| Read, search (`api/Warehouses`, `api/ProductionStructures`) | World area node `knk.admin.world`, or the plugin key |
| Create, update | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| Delete | `knk.admin.world` and `knk.admin.delete` |
| `PUT api/ProductionStructures/{id}/road-connection` | `knk.admin.world`, or the plugin key |
| Adjust or move stock in the structure's storages | `knk.economy.admin` ([stock admin guide](../guides/admin/stock-admin-guide.md)) |
| `/knk regions repair` | `knk.admin.regions` |

Pinned by `EndpointAccessRulesTests`, `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and
`DeleteAccessRulesTests`. Admin CRUD works while production is off.

## 9. Schema and migration

One additive migration `AddProductionWorld` (knk-web-api, after `AddStockCore`):

1. `structures`: `DistrictId` and `StreetId` nullable, new nullable `TownId` (index, FK to `towns`), check constraint
   `CK_structures_DistrictXorTown`; the three FKs re-created without cascade (`ClientNoAction` in the model).
2. New tables `warehouses` (FK `Id` → `structures` cascade, `DefaultStorageId` → `storages` set null) and
   `production_structures` (FK `Id` → `structures` cascade, `PreferredWarehouseId` → `warehouses` set null, index on
   `ProductionKindId`).
3. Existing structures keep their district, street and house number. Rolled back to `AddStockCore` and re-applied in
   the link's test; `has-pending-model-changes` clean.

Deploy: [production installation § 5.3](../guides/production-installation.md#53-apply-the-migrations), then import the
`Warehouse` and `ProductionStructure` form and display seeds ("make default"). No `api.env` key, no plugin `config.yml`
key; after turning `production.enabled` on in the plugin, run `/knk regions repair` once (or restart).

## 10. Tests

1. **knk-web-api:** `StructureSubtypeServicesTests` (15), `PlacementRulesTests` (6: the shipped seeds imported and run
   on save), `InsideTerritoryValidatorTests` (12, with the client's URLs, key and answers), `RuralStructureTests` (5),
   `AddProductionWorldTests` (4), `ProductionWorldMySqlTests` (2, requires MySQL: the check constraint, deleting a used
   street or town), `DeleteConstraintExceptionFilterTests`, the pinned access tests.
2. **knk-web-app:** Jest `productionWorld.test.ts`, `productionWorldClients.test.ts`, `ValidationRuleBuilder.test.tsx`,
   `PagedEntityTable.categoryFilter.test.tsx`, `domainWorld.test.ts`; Playwright `e2e/production-world.spec.ts` (9,
   strict API mocks in `e2e/fixtures/productionWorld.ts`) and one test in `form-builder-draft-rules.spec.ts`.
3. **knk-plugin:** `ProductionManagedRegionTest` (6), `TerritoryLookupTest` (8), `TerritoryLookupHandlerTest` (5, a
   real `RegionHttpServer`), `StructuresMapperTest` (2), a `TerritoryServiceTest` case, and the plugin scenario
   `rural-structure-region` ([plugin scenarios](../guides/developer/plugin-scenarios.md)).
4. **Manual:** [smoke test § 3](../guides/production-storage-transport-smoke-test.md#3-phase-p2-world-rural-structures-warehouse-production-structure-91-api-676-web-app-677-plugin-tier3),
   each step tagged with the tests above.

## 11. Recovery

1. **A save refused by a blocking rule that should pass:** make the rule a warning in the form configuration, save,
   then check the region in game. A rule that can't run never blocks.
2. **P-2 always "not checked":** the API can't reach the region HTTP server (`MinecraftPlugin:BaseUrl`, plugin key), the
   plugin's `production.enabled` is off (503), or the territory cache is not built yet (`/knk territory status`).
3. **A structure moved to rural still inherits town flags:** clear the stale parent with `/rg setparent <region>` (§ 6.3).
4. **A structure can't be deleted (409):** move or adjust its storages' stock to zero, or keep it; storages with ledger
   history can't be deleted (stock core).

## 12. Limitations (P2)

1. P-3 waits for P4's production areas; the validation types are ready.
2. An update drops the placement warnings (204), and the subtype endpoints' error body carries the .NET parameter
   suffix (the web app cuts it); [#831](https://github.com/PandiO/knk-workspace/issues/831).
3. The generic `Structure` form seed has no Town field yet, so a rural plain structure (not a warehouse or production
   structure) can only be created through `api/Structures` with `townId` ([#831](https://github.com/PandiO/knk-workspace/issues/831)).
4. A stale WorldGuard parent after a move to rural is not cleared ([#824](https://github.com/PandiO/knk-workspace/issues/824)).
5. No production kinds, lines, cycles or workers yet (P3, P5); `RoadConnection` is measured from P5b on.

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#830).
