# Territory (knk-web-api, knk-plugin and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-19 (first version, territory V1 #326/#689/#690, docs PandiO/knk-workspace#806)
**Checked against:** knk-web-api `next` `0d6e369a` (PR PandiO/knk-web-api#53), knk-plugin `next` `55804b11` (PR
PandiO/knk-plugin#91), knk-web-app `next` `89751315` (PR PandiO/knk-web-app#57). Not released; everything in game is
off by default (`production.enabled`), and the smoke test has not been run live yet.
**Related:** [territory DESIGN](../specs/territory/DESIGN.md) (rules, decisions G10, G11, G16, G17),
[admin guide](../guides/admin/territory-admin-guide.md), [player guide](../guides/users/territory-player-guide.md),
[plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production),
[smoke test § 1](../guides/production-storage-transport-smoke-test.md#1-territory-v1-326-api-689-plugin-690-web-app-tier3),
[managed WorldGuard regions](managed-worldguard-regions.md) (the `CROWN_LAND` kind),
[plugin scenarios](../guides/developer/plugin-scenarios.md) (`territory-border-crossing`)

Territory says which town or kingdom holds a spot of land. It is measured outward from the WorldGuard regions of
districts and crown land: a district reaches as far as its town's range, crown land as far as its own range. Where two
towns reach the same land it is **contested**; where nobody reaches it is **wilderness**. Production (#22) uses it to
check where rural structures may stand.

## 1. Who computes what

| Part | Owner | Why |
|---|---|---|
| Holders (kingdoms, provinces, towns, crown land), power, capital districts, range settings, admin awards | knk-web-api (database) | Admin-set data, edited in the web app |
| Effective ranges (base + power × factor, capital × multiplier) | knk-web-api (`TerritoryRules.TownRange`, `DistrictRange`) | One place for the formula; the plugin uses each region's `range` as given |
| The territory itself: which holder owns each chunk or block column | knk-plugin (game server, chunk cache) | Only the game server has the region shapes |
| Conflicts (overlaps of equal rank) and structure flags | Detected by the plugin, stored by the API (`PUT api/Territory/report`), resolved by admins | Admins resolve conflicts (DESIGN § 3); the API keeps the record |
| Screens: dashboards, town, conflict and structure panels, the settings card | knk-web-app | Through the metadata framework plus three panels |

Decision (L1, DESIGN § 4.3): the API computes no overlaps, because it has no region geometry and would have to ask the
plugin per chunk; the plugin does not own conflicts, because then the database would hold no admin record.

### 1.1 Source locations

| Part | Repo | Where |
|---|---|---|
| Entities and enums | knk-web-api | `Models/Territory/` (`Kingdom`, `Province`, `CrownLand`, `TerritoryConflict` with `TerritoryHolderKind`, `TerritoryConflictStatus`, `TerritoryConflictResolution`, `StructureTerritoryFlag`); `Town.Power`/`KingdomId`/`ProvinceId`, `District.IsCapital`, `Structure.LoyaltyTownId`/`TerritoryFlag`/`TerritoryFlaggedAt`/`TerritoryConflictId`, `GameSettings.ProductionSettingsJson` |
| Rules, services, controllers, DTOs | knk-web-api | `Services/Territory/` (`TerritoryRules`, `TerritoryService`, `TerritoryConflictService`, `KingdomService`, `ProvinceService`, `CrownLandService`, `TerritoryHolderRules`, `ProductionSettings`), `Controllers/TerritoryController.cs`, `TerritoryConflictsController.cs`, `KingdomsController.cs`, `ProvincesController.cs`, `CrownLandsController.cs`, `Dtos/TerritoryDtos.cs` |
| Realtime event | knk-web-api | `Realtime/RealtimeEntityChangeMap.cs` (`AddTerritoryEvents`), `Realtime/Contracts/ConfigContracts.cs` (`TerritoryChanged`, scope `territory`) |
| Cache, rules, report, outlines, tracker (Bukkit-free) | knk-plugin `knk-core` | `core/territory/` |
| API port and client | knk-plugin `knk-core`, `knk-api-client` | `core/ports/api/TerritoryApi.java`, `api/impl/TerritoryApiImpl.java`, `api/realtime/ConfigEvents.TERRITORY_CHANGED` |
| Game server wiring, listener, command | knk-plugin `knk-paper` | `paper/territory/` (`TerritoryModule`, `TerritoryListener`, `TerritoryConfig`, `PlayerTerritoryChangeEvent`), `paper/commands/TerritoryAdminCommand.java` |
| Crown land region kind | knk-plugin `knk-core` | `core/regions/managed/ManagedRegionKind.CROWN_LAND` |
| Web app | knk-web-app | `src/types/dtos/territory/TerritoryDtos.ts`, `src/apiClients/` (`kingdomClient`, `provinceClient`, `crownLandClient`, `territoryConflictClient`, `territoryClient`), `src/components/territory/` (`TownTerritoryPanel`, `TerritoryConflictPanel`, `StructureTerritoryPanel`), `src/components/admin/gameSettings/TerritorySettingsCard.tsx`, `src/utils/territory.ts` |

## 2. Data

Migration `20261119102500_AddTerritory` (additive, no data written;
[production installation § 5.3](../guides/production-installation.md#53-apply-the-migrations)):

1. `kingdoms`: `Id`, `Name` (≤ 100, unique `IX_kingdoms_Name`, trimmed), `Description` (≤ 1000), `CreatedAt`.
2. `provinces`: `Id`, `Name` (≤ 100, unique per kingdom `IX_provinces_KingdomId_Name`), `Description`, `KingdomId`
   (required), `CreatedAt`.
3. `crown_lands`: a `Domain` subtype (shares `Id` with `domains`: name, description, `WgRegionId`, `WorldName`,
   `LocationId`, entry/exit, sub-regions) plus `KingdomId` (required) and `Range` (0 to 10,000 blocks).
4. `territory_conflicts`: `World` (≤ 100), holder A and B as (kind, id) in normal order (smaller kind, then id, first),
   `Status` (`Open`/`Resolved`), `StillOverlapping`, `ChunksJson` (sorted `[x, z]` pairs), `ChunkCount`, the bounding
   box `MinChunkX`…`MaxChunkZ`, `DetectedAt`, `LastReportedAt`, `Resolution` (`None`/`Awarded`/`Redrawn`),
   `AwardedHolderKind`/`AwardedHolderId`, `ResolvedAt`, `ResolvedByUserId`, `ResolutionNote` (≤ 1000). Index
   `IX_territory_conflicts_World_Status`.
5. `towns`: `Power` (int, default 0, at most 1,000,000), `KingdomId` and `ProvinceId` (nullable FKs).
6. `districts`: `IsCapital` (default false).
7. `structures`: `LoyaltyTownId` (nullable FK to `towns`; null = loyal to its own town; stored only in V1),
   `TerritoryFlag` (`None`/`OutsideTerritory`/`Contested`), `TerritoryFlaggedAt`, `TerritoryConflictId` (nullable FK).
8. `game_settings.ProductionSettingsJson`: the game settings section `production`, `{ enabled, territory: { baseRange,
   powerFactor, capitalMultiplier } }`. Null or missing = `enabled: false`, base 100, factor 2, capital × 1.5.

Holder kinds: `Town` (rank 1) and `Kingdom` (rank 2, through crown land). A district's holder is its town; crown
land's holder is its kingdom. Provinces group towns and hold no land themselves.

## 3. Rules (`TerritoryRules`, API and plugin)

The API's `Services/Territory/TerritoryRules.cs` is the reference; knk-core `core/territory/TerritoryRules` is the same
logic for positions in the cache.

1. **Range** (G11): a town's district range = max(0, `baseRange` + `power` × `powerFactor`); a capital district's =
   that × `capitalMultiplier`. Crown land uses its own `Range`. Bounds on save: `baseRange` 0–10,000, `powerFactor`
   0–1,000, `capitalMultiplier` 1–10 (400 otherwise).
2. **Distance** is from the nearest edge of the region or any of its sub-regions (`TerritoryShape`): a column inside or
   on the outline is at 0; outside it is the Euclidean distance from the column's block coordinates to the nearest
   outline segment (cuboids as four corners, polygons as their points). A column is reached when the distance ≤ range.
3. **Resolve** (`Resolve(claims, awardedTo)`): of every holder reaching a spot, keep the highest rank. One holder: it
   owns the spot. Two or more: contested (no owner), unless an admin's award covering the spot names one of them, which
   then owns it. Nobody: wilderness. So crown land always beats towns, two districts of one town never conflict, and
   two crown lands of one kingdom never conflict.
4. **Conflict pair** (`IsConflictPair`): two different holders of equal rank. In V1 that is town against town or
   kingdom against kingdom (crown land of two kingdoms).
5. **Town save rule** (`TerritoryHolderRules`): power 0–1,000,000; kingdom and province must exist; the province must
   be in the town's kingdom. Applied only when `power` is on the request (`null` = "not on this form", so today's Town
   form, which does not send it, leaves the fields alone).
6. **Holder deletes**: a kingdom with towns, provinces or crown land and a province with towns are refused (409);
   moving a province with towns to another kingdom is refused (400).

## 4. API contract

Access in one line per controller; every write needs `knk.admin.world` or the plugin key, creates and edits of the
dashboard types also `knk.admin.content` (`RequireDashboardChange`), deletes `knk.admin.delete` on top. Reads need the
type's dashboard read access (World area) or the plugin key. Pinned in `EndpointAccessRulesTests`,
`ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and `DeleteAccessRulesTests`.

### 4.1 `api/Kingdoms`, `api/Provinces`, `api/CrownLands`

Each has the same shape:

| Method and route | Body / query | Answer |
|---|---|---|
| `GET` | — | All rows (`KingdomDto[]`, `ProvinceDto[]`, `CrownLandDto[]`) |
| `GET {id}` | — | One row with its relations (a kingdom's `towns`, `provinces`, `crownLands`; a province's `kingdom` and `towns`; crown land's `kingdom` and `subRegions`), 404 if unknown |
| `POST` | the DTO without `id` | 201 with the row; 400 with `{ error }` on a rule (name required and unique, kingdom unknown, range out of 0–10,000, `wgRegionId` required for crown land) |
| `PUT {id}` | the DTO | the row; 400 as for `POST`; 400 when a province with towns would move kingdom |
| `DELETE {id}` | — | 204; 409 when a kingdom or province still has members (§ 3 item 6) |
| `POST search` | `PagedQueryDto` (term on the name; crown land also filters `kingdomId`; sort `name` or id) | `PagedResultDto` of `KingdomListDto` (`townCount`, `crownLandCount`), `ProvinceListDto` (`kingdomName`, `townCount`), `CrownLandListDto` (`kingdomName`, `range`, `wgRegionId`, `worldName`) |

`CrownLandDto`: `id`, `name`, `description`, `createdAt`, `allowEntry`, `allowExit`, `wgRegionId`, `worldName`,
`locationId`, `kingdomId`, `range`, `kingdom`, `subRegions`. Its region is captured in game by the form's world task,
like a district's (G10). On a region rename the API sends no domain type to the plugin (L1 decision 10).

Town and district fields travel on the existing DTOs: `TownDto.power`, `kingdomId`, `provinceId` (applied only when
`power` is not null) and `DistrictDto.isCapital` (nullable; null leaves it alone).

### 4.2 `api/TerritoryConflicts`

No create or update: conflicts come from the report.

| Method and route | Body / query | Answer |
|---|---|---|
| `GET` | `openOnly` (default false) | `TerritoryConflictDto[]` |
| `GET {id}` | — | `TerritoryConflictDto`: `id`, `world`, `holderA`/`holderB` (`{ kind, id, name }`), `status`, `stillOverlapping`, `chunks` (`[x, z][]`), `chunkCount`, the bounding box, `detectedAt`, `lastReportedAt`, `resolution`, `awardedHolder`, `resolvedAt`, `resolvedByUserId`, `resolutionNote`, `flaggedStructures` (`{ id, name }[]`) |
| `POST search` | `PagedQueryDto` | `PagedResultDto<TerritoryConflictListDto>` (`name`, `world`, `status`, `stillOverlapping`, `chunkCount`, `resolution`, `detectedAt`, `flaggedStructureCount`) |
| `POST {id}/resolve` | `{ resolution: "Awarded" \| "Redrawn", awardedHolder?: { kind, id }, note?: ≤ 1000 }` | the conflict, now `Resolved`; 400 when the resolution is unknown or the awarded holder is not one of the two; 409 when it is already resolved |
| `POST {id}/reopen` | — | the conflict, `Open` again with the award withdrawn (the note stays); 409 when it is open, or when another open conflict exists for the same pair and world |
| `DELETE {id}` | — | 204; flagged structures keep their flag but lose the conflict link (`knk.admin.delete`) |

### 4.3 `api/Territory`

| Method and route | Access | Body | Answer |
|---|---|---|---|
| `GET inputs` | World read access or the plugin key | — | `TerritoryInputsDto` (§ 4.4) |
| `PUT report` | Plugin key only | `TerritoryReportDto` (§ 4.5) | `TerritoryReportResultDto`; 409 `{ error, code: "ProductionDisabled" }` while the game setting `production.enabled` is off; 400 when `world` is missing or longer than 100 |
| `GET towns/{id}` | World read access | — | `TownTerritoryDto`: `townId`, `power`, `kingdomId`, `provinceId`, `range`, `capitalRange`, `districts` (region DTOs as in the inputs, with their range) |
| `GET structures/{id}` | World read access | — | `StructureTerritoryDto`: `structureId`, `structureName`, `townId` (of its district), `loyaltyTownId`, `loyaltyTownName`, `territoryFlag`, `territoryFlaggedAt`, `territoryConflictId` |
| `PUT structures/{id}/loyalty` | `knk.admin.world` | `{ loyaltyTownId: int \| null }` | the structure's territory; 400 for an unknown town, 404 for an unknown structure |
| `DELETE structures/{id}/flag` | `knk.admin.world` | — | the structure's territory with the flag cleared (the next report sets it again if it still applies) |

Only the report is gated by the flag (L1 decision 6): CRUD, inputs and resolve work with `production.enabled` off, so
staff can set territory up before switching it on.

### 4.4 Inputs payload (`GET api/Territory/inputs`)

```json
{
  "productionEnabled": true,
  "settings": { "baseRange": 100, "powerFactor": 2, "capitalMultiplier": 1.5 },
  "version": "3f1c0a9e5b7d2c4a6e8f0b1d",
  "generatedAt": "2026-11-19T12:00:00Z",
  "kingdoms": [{ "id": 1, "name": "Aurelia" }],
  "towns": [{ "id": 7, "name": "Phoenix", "kingdomId": 1, "provinceId": null, "power": 50, "range": 200 }],
  "districts": [{ "id": 21, "name": "Old Town", "world": "world", "wgRegionId": "district_old_town",
                  "subRegionIds": [], "holder": { "kind": "Town", "id": 7 }, "isCapital": true, "rank": 1,
                  "range": 300 }],
  "crownLands": [{ "id": 40, "name": "Royal forest", "world": "world", "wgRegionId": "crown_royal_forest",
                   "subRegionIds": [], "holder": { "kind": "Kingdom", "id": 1 }, "isCapital": false, "rank": 2,
                   "range": 80 }],
  "awards": [{ "conflictId": 3, "world": "world", "holder": { "kind": "Town", "id": 7 },
               "chunks": [[12, -4], [12, -3]] }]
}
```

1. `version` is a SHA-256 over everything except `version` and `generatedAt` (24 hex characters): equal versions mean
   equal inputs. Holder names are part of it, so a rename rebuilds too.
2. `awards` are the resolved conflicts with `resolution: Awarded`; their chunks go to the named holder (§ 3 item 3).
   A `Redrawn` conflict is no award: the overlap is expected to be gone after the admin's change.
3. Every district and crown land is listed, also one without a world; the plugin leaves out a source whose region it
   cannot find (a warning in `/knk territory status`).

### 4.5 Report payload (`PUT api/Territory/report`)

One full snapshot per world, sent by the plugin after a rebuild (L1 decision 2):

```json
{
  "world": "world",
  "inputsVersion": "3f1c0a9e5b7d2c4a6e8f0b1d",
  "overlaps": [{ "holderA": { "kind": "Town", "id": 7 }, "holderB": { "kind": "Town", "id": 9 },
                 "chunks": [[14, -2], [15, -2]] }],
  "structures": [{ "structureId": 55, "flag": "Contested",
                   "holderA": { "kind": "Town", "id": 7 }, "holderB": { "kind": "Town", "id": 9 } },
                 { "structureId": 61, "flag": "OutsideTerritory" }]
}
```

What the API does (`TerritoryService.ApplyReportAsync`), in one transaction per step:

1. **Overlaps.** Each pair is normalised; a pair that is not a conflict pair, names an unknown holder, has a
   malformed chunk or 0 or more than 100,000 chunks is skipped (listed in `skipped`). An open conflict for the same
   pair and world is updated (area, `lastReportedAt`, `stillOverlapping: true`); otherwise a new one is opened. The same
   pair twice in one report has its areas merged.
2. **Gone overlaps.** An open conflict of that world the report does not name gets `stillOverlapping: false` and stays
   open: only admins close conflicts (DESIGN § 3).
3. **Structure flags.** Each listed structure (in that world) gets its flag; a `Contested` one is linked to the open
   conflict of its two holders when there is one. A structure of that world that was flagged and is not listed now is
   cleared. Unknown structures and flags other than `OutsideTerritory`/`Contested` are skipped.
4. **Answer** `TerritoryReportResultDto`: `world`, `conflictsCreated`, `conflictsUpdated`,
   `conflictsNoLongerOverlapping`, `structuresFlagged`, `structuresCleared`, `skipped[]`. The API logs one summary line.

The report's own writes send no `TerritoryChanged` and no structure update event for the flag fields
(`RealtimeEntityChangeMap` ignores `TerritoryFlag`, `TerritoryFlaggedAt`, `TerritoryConflictId` on structures).

### 4.6 Realtime `TerritoryChanged`

Config event `TerritoryChanged` with `ConfigChangedPayload` scope `territory`, sent after a save that changes an input:
any change to a kingdom, province, crown land or domain sub-region; a town's `Power`, `KingdomId`, `ProvinceId` or
`Name` (or a town added or removed); a district's `IsCapital`, `TownId`, `WgRegionId`, `WorldName` or `Name` (or a
district added or removed); a conflict's `Status`, `Resolution` or award, or its delete; and the game settings'
`ProductionSettingsJson`. The plugin debounces it (2 s) and re-reads the inputs.

## 5. Game server (knk-plugin)

Nothing below runs unless the plugin key `production.enabled` is `true` (A21); keys in
[plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production).

### 5.1 Life cycle (`TerritoryModule`, `TerritoryService`)

1. **Start:** the first build 5 s (100 ticks) after the plugin starts, when WorldGuard has loaded every world's regions;
   then a check every `territory.refresh-minutes` (default 10; 0 = only on events and `/knk territory rebuild`); a
   refresh after a `TerritoryChanged` event (merged over 40 ticks) and after the game hub reconnects.
2. **Refresh** (`TerritoryService.refresh`): read `GET api/Territory/inputs` (async), read the source regions' outlines
   through `RegionOutlinePort` (main thread, the same `RegionOutlineAdapter` the overview map uses), then build the
   cache off the main thread unless the inputs' `version`, the shapes' fingerprint and the API's flag are all unchanged.
   Overlapping refreshes are merged: one runs, one more follows. The new cache is swapped in whole; a failed read keeps
   the old one.
3. **After a rebuild:** the player tracker is told on the main thread; with `territory.report: true` and the API's
   `productionEnabled`, one report per world; with `territory.map-outlines: true`, the outlines over the game hub. A
   forced rebuild (`/knk territory rebuild`) reports even when nothing changed; unchanged periodic checks do not
   (L2 decision 9).

### 5.2 The chunk cache (`TerritoryCacheBuilder`, `TerritoryMap`, `TerritoryCache`)

1. For each source (a district or crown land with its shape), every chunk within range of the shape's bounding box is
   classified by the distance from the chunk's centre: if centre distance + half the chunk diagonal is in range, the
   chunk is reached **fully**; if centre distance − half the diagonal is out of range, not at all; otherwise **partly**.
   The distance changes by at most one block per block moved (1-Lipschitz), so this bound holds for every column
   (L2 decision 3).
2. Each chunk gets the `Resolve` verdict over the holders reaching it, with the award covering it. A chunk with a
   partly reaching source is resolved per block column at build time (all 256 columns, off the main thread, L2
   decision 2); if every column has the same verdict it is stored whole, otherwise as a **split** chunk that keeps a
   verdict per column, so a border can run diagonally through a chunk.
3. Wilderness is not stored. `max-chunks-per-world` (default 500,000) caps each world: a source that would pass it is
   left out with a warning.
4. A lookup (`TerritoryCache.lookup(world, x, z)`) is a map read: the chunk's verdict, or the column's in a split
   chunk. It is safe from any thread; the cache is immutable.

### 5.3 Report (`TerritoryReportBuilder`)

1. **Overlaps:** every chunk with a contested column (whole or split) adds that chunk to each conflict pair among its
   contesting holders.
2. **Structures:** a structure is placed at the centre column of its region's bounding box (L2 decision 4).
   Contested land flags it `Contested` with its first two contesting holders; land its own town does not own
   (wilderness, another town, or crown land, also of its own kingdom) flags it `OutsideTerritory` (L2 decision 5). A
   structure whose town (through its district) or region is unknown is not reported, so rural structures without a
   district are not checked yet (P2, #91).

### 5.4 Outline payload (`TerritoryOutlines`, hub method `ReportTerritoryOutlines`)

Built from the cache only with `map-outlines: true`; one hub message per world:

```json
{ "world": "world", "inputsVersion": "3f1c0a9e5b7d2c4a6e8f0b1d",
  "outlines": [{ "kind": "Owned", "holders": [{ "kind": "Town", "id": 7, "name": "Phoenix" }],
                 "rings": [{ "hole": false, "points": [[160, -64], [208, -64], [208, -16], [160, -16]] }] },
               { "kind": "Contested", "holders": [{ "kind": "Town", "id": 7, "name": "Phoenix" },
                                                  { "kind": "Town", "id": 9, "name": "Rivertown" }],
                 "rings": [ ... ] }] }
```

Each area (one owner, or one contested set) is a set of rings of block-corner points `[x, z]`: outer rings clockwise
with x east and z south, holes the other way. Whole chunks give 16-block edges, split chunks one edge per block column.
The API does not store these yet and the map does not draw them ([#802](https://github.com/PandiO/knk-workspace/issues/802));
keep `map-outlines: false` until then (L2 decision 1: outlines go over the hub because overview map O15 puts no BlueMap
plugin on the game server).

### 5.5 Players and other features

1. `TerritoryListener` looks the player's column up on join, moves to another block column, teleports, respawns and
   world changes; `TerritoryTracker` skips the lookup while the player stays in the same chunk (the same column in a
   split chunk). A change of area (owner, or contested set) fires `PlayerTerritoryChangeEvent` (from, to, cache) and,
   with `notify-players`, an action bar line from `messages.*`. The first lookup after a join shows nothing.
2. Placement and entry rules of later phases call `KnKPlugin.getTerritoryModule().service().lookup(world, x, z)` (a
   `TerritoryVerdict`: owner, contesting) and listen to `PlayerTerritoryChangeEvent`. Both are null or never fired
   while `production.enabled` is off.
3. `/knk territory here|status|rebuild` (node `knk.admin.world.territory`, `TerritoryAdminCommand`): `here` gives the
   holder of the sender's column, whether the chunk is split, and the cache version; `status` the chunks, split chunks,
   worlds, version, build time, sources, awards, the API's flag, the last report and up to five warnings; `rebuild`
   a forced refresh with its summary.
4. **Crown land regions:** managed-region kind `CROWN_LAND` (priority floor 10, no parent, no flags of its own; see
   [managed WorldGuard regions](managed-worldguard-regions.md)). `ManagedRegionKind.fromDomainType("CrownLand")` maps to
   it; the region repair adds crown land regions from the domain catalogue only with `production.enabled`.

## 6. Web app (knk-web-app)

1. **Dashboards and forms** for Kingdom, Province, CrownLand and TerritoryConflict through the metadata framework
   (`Controllers` enum, `entityApiMapping`, `objectConfigs`), with the seeded forms of L1 (G17); TerritoryConflict has
   search, fetch and delete only.
2. **Town page, Territory panel** (`TownTerritoryPanel`): power, kingdom, province, range and capital range, and each
   district with its range; **Edit territory** sets power, kingdom and province (only that kingdom's provinces), and a
   per-district button marks or unmarks the capital. Saves go through `PUT api/Towns/{id}` and `PUT api/Districts/{id}`
   with the record's identity fields plus the territory change and every other "not on this form" group null
   (L3 decision 2), so nothing else on the record changes.
3. **Conflict page, Contested zone panel** (`TerritoryConflictPanel`): holders, state, world, area, overlap, detected
   and last reported, resolution, flagged structures; **Award to …** (each holder), **Mark the lines redrawn**,
   **Reopen**, each behind a confirmation, with an optional note.
4. **Structure page, Territory and loyalty panel** (`StructureTerritoryPanel`, `Structure` only): flag and conflict,
   own town, **Loyal to** with **Save loyalty**, **Clear flag**.
5. **Game settings, "Production and territory" card** (`TerritorySettingsCard`): the switch and the three range
   settings with a worked example; Save is off while a value is outside the API's bounds.
6. `src/utils/territory.ts` repeats the range formula for the example and the panels' labels (matching
   `TerritoryRules`).

## 7. Tests

1. knk-web-api: `TerritoryRulesTests`, `TerritoryServiceTests`, `TerritoryConflictServiceTests`,
   `TerritoryHolderServicesTests`, `ProductionSettingsTests`, `TerritoryRealtimeEventTests`, `AddTerritoryTests`, and
   the pinned access tests.
2. knk-plugin: knk-core `core/territory/` (`TerritoryRulesTest`, `TerritoryShapeTest`, `TerritoryCacheBuilderTest`,
   `TerritoryReportBuilderTest`, `TerritoryOutlinesTest`, `TerritoryTrackerTest`, `TerritoryServiceTest`,
   `TerritorySettingsTest`); knk-api-client `TerritoryApiImplTest`; knk-paper `TerritoryConfigTest`,
   `TerritoryAdminCommandTest`, `CrownLandManagedRegionTest` and the listener tests; plugin scenario
   `territory-border-crossing` on a real Paper server ([plugin scenarios § 1](../guides/developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines)).
3. knk-web-app: Jest `territory.test.ts`, `territoryClients.test.ts`; Playwright `e2e/territory.spec.ts` with the
   DTO-typed fixtures `e2e/fixtures/territory.ts` (strict specs that open a town or structure page use
   `mockNoTownTerritory` / `mockNoStructureTerritory`).
4. Manual: [smoke test § 1](../guides/production-storage-transport-smoke-test.md#1-territory-v1-326-api-689-plugin-690-web-app-tier3),
   each step tagged with the tests above.

## 8. Limitations and follow-ups

1. Map outlines are built but not stored or drawn ([#802](https://github.com/PandiO/knk-workspace/issues/802)).
2. The seeded Town and District forms have no power, kingdom, province or capital fields; the town page's Territory
   panel sets them (proposal on [#690](https://github.com/PandiO/knk-workspace/issues/690#issuecomment-7007691107)).
3. Loyalty is stored only; it has no effect in game in V1 (DESIGN § 4 Later).
4. The territory check at structure creation only warns, through the next report's flag; the form rule
   `InsideTerritory` and rural structures with a `TownId` are P2's ([#91](https://github.com/PandiO/knk-workspace/issues/91)),
   which also needs a plugin lookup endpoint for it.
5. Crown land created in the web app sends no domain type to the plugin on a rename (L1 decision 10).
6. A world whose last source is removed still gets an (empty) report while the plugin runs, so its open conflicts turn
   `stillOverlapping: false`; after a plugin restart that world is no longer reported and its conflicts keep their last
   state until an admin resolves or deletes them.
7. Later or parked (DESIGN § 9): grasp and expansion points, public safety, the source registry, patrol trails, revolts,
   territory effects, a WorldGuard export.
