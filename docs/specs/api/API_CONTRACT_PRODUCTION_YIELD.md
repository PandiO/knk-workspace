# API Contract: Production yield areas, surveys and Hybrid overrides

**Status:** Current · **Last updated:** 2026-11-20 (first version, production P4 #138, docs PandiO/knk-workspace#882)
**Checked against:** knk-web-api `next` `e26c7d88` (PR PandiO/knk-web-api#60; `Controllers/ProductionAreasController.cs`,
`Controllers/AreaSurveysController.cs`, `Controllers/ProductionYieldOverridesController.cs`, the P4 actions of
`Controllers/ProductionStructuresController.cs`, `Dtos/ProductionYieldDtos.cs`, `Services/Production/ProductionAreaServices.cs`,
`Services/Production/ProductionYield.cs`). Not released.
**Related:** [yield areas architecture](../../architecture/production-yield-areas.md) (rules and formulas),
[PRODUCTION_KINDS § 2–4](../production-storage-transport/PRODUCTION_KINDS.md),
[admin guide](../../guides/admin/production-yield-areas-admin-guide.md), [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md)
(kinds, lines), [production world API contract](API_CONTRACT_PRODUCTION_WORLD.md) (`api/ProductionStructures` CRUD),
[smoke test § 5.1](../../guides/production-storage-transport-smoke-test.md#51-steps-api) (every endpoint with an example)

The conventions of the [production engine API contract](API_CONTRACT_PRODUCTION_ENGINE.md) hold: camelCase JSON, enums
as their names, a **null field means "keep"** on update (on create: the default), child lists replace when sent,
errors `{ "error": "<reason>" }`, paged searches take `PagedQueryDto` and answer `PagedResultDto<T>`. Status codes:
400 for a validation error (`ArgumentException`), 404 for a missing row, 409 for a conflict (`InvalidOperationException`:
an overlap, the feature off, a Configured structure).

## 1. Access

| Endpoints | Needs |
|---|---|
| `GET` and `POST …/search` of `api/ProductionAreas`, `api/AreaSurveys`, `api/ProductionYieldOverrides`; `GET api/ProductionAreas/{id}/overlaps`, `GET api/ProductionAreas/survey-due`, `GET api/AreaSurveys/trend`, `GET api/ProductionStructures/{id}/yield` | `knk.admin.world` (World area), or the plugin key |
| `POST`, `PUT {id}` of areas and overrides | `knk.admin.world` and `knk.admin.content` (dashboard change rule), or the plugin key |
| `DELETE {id}` of areas and overrides | `knk.admin.world` and `knk.admin.delete` |
| `POST api/ProductionAreas/{id}/surveys`, `POST api/ProductionStructures/{id}/survey`, `POST api/ProductionStructures/{id}/materialize` | `knk.admin.world`, or the plugin key |

Area and override CRUD works while the game setting **Production enabled** (`Production:Enabled`) is off; the survey
queue is empty and survey reports are 409 while it is off.

## 2. Fields added to existing resources

### 2.1 `ProductionKindDto` (`api/ProductionKinds`)

| Field | Type | Notes |
|---|---|---|
| `surveyProfileJson` | string? | a JSON object (≤ 4000 characters) the plugin reads; `""` clears it; a change raises the version |
| `surveyProfileVersion` | int | read only |
| `primaryMultiplier` | decimal? | 0–100, default 1.5 |
| `yieldTable` | `ProductionYieldRowDto[]?` | replaces the table when sent (≤ 500 rows) |
| `primaryOutputs` | `ProductionKindPrimaryOutputDto[]?` | replaces the list when sent (≤ 50) |

`ProductionYieldRowDto`: `id`, `unitKey` (a key, a prefix ending in `:*`, or `*`), `itemBlueprintId`, `itemBlueprint`
(read), `ratePerUnitPerHour` (0 to the line maximum), `byproductChance` (0–1, default 1), `minLevel` (1–10, default 1).
A (unit key, blueprint) pair once. `ProductionKindPrimaryOutputDto`: `id`, `itemBlueprintId`, `itemBlueprint` (read);
a blueprint once. A table, primary or multiplier change settles the kind's Derived and Hybrid structures first; a table
change then materializes their lines.

Errors: "surveyProfileJson must be a JSON object.", "primaryMultiplier must be 0 to 100.", "yieldTable unitKey must be a
unit key such as BLOCK:COAL_ORE or a prefix such as TREE:OAK:* …", "yieldTable: ItemBlueprint with id N not found.",
"yieldTable K: ratePerUnitPerHour must be 0 to …", "yieldTable K: byproductChance must be 0 to 1.", "yieldTable K:
minLevel must be 1 to 10.", "yieldTable: K → blueprint N is listed twice.", "primaryOutputs: blueprint N is listed
twice.".

### 2.2 `ProductionStructureDto` (`api/ProductionStructures`)

| Field | Type | Notes |
|---|---|---|
| `yieldSource` | string? | `Derived`, `Configured` or `Hybrid`; must be one the kind allows; on create without it: the first allowed of Hybrid, Derived, Configured |
| `areas` | `ProductionAreaListDto[]?` | read only |

`PUT api/ProductionStructures/{id}` (and `api/Warehouses/{id}`) now answers **200 with the saved structure and its
`placementWarnings`**, as create does (#831), instead of 204. A change of `yieldSource`, or of `level` or
`productionKindId` on a surveyed structure, materializes the lines. Errors: "yieldSource must be Derived, Configured or
Hybrid.", "yieldSource: <kind> doesn't allow <source>.".

### 2.3 `ProductionLineDto`

`rateSource` `Derived` or `Hybrid` is accepted only on a structure of that yield source: "rateSource: a Derived line
needs a Derived structure (the structure is Hybrid)." `Configured` is accepted on any structure.

## 3. `api/ProductionAreas`

| Method | Route | Answer |
|---|---|---|
| `GET` | `api/ProductionAreas` | `ProductionAreaDto[]` |
| `GET` | `api/ProductionAreas/{id}` | `ProductionAreaDto` or 404 |
| `POST` | `api/ProductionAreas` | 201 `ProductionAreaDto` |
| `PUT` | `api/ProductionAreas/{id}` | 200 `ProductionAreaDto` |
| `DELETE` | `api/ProductionAreas/{id}` | 204 (its surveys go with it) |
| `POST` | `api/ProductionAreas/search` | `PagedResultDto<ProductionAreaListDto>`; filters `productionStructureId`, `model`, `exclusive`, `enabled`; sort `name` (default), `id`, `lastSurveyedAt` |
| `GET` | `api/ProductionAreas/{id}/overlaps` | `ProductionAreaOverlapDto[]` (every other area whose box overlaps) |
| `GET` | `api/ProductionAreas/survey-due?limit=50` | `SurveyDueAreaDto[]` (§ 5) |
| `POST` | `api/ProductionAreas/{id}/surveys` | 200 `AreaSurveyDto` with `materialization` (§ 5) |

`ProductionAreaDto`:

| Field | Type | Notes |
|---|---|---|
| `id` | int | |
| `productionStructureId` | int? | required on create; can't change |
| `productionStructure` | `{id, name}` | read |
| `name` | string | ≤ 100, unique per structure |
| `model` | string | read: the kind's area model |
| `shape` | string | `Region`, `Cuboid`, `Polygon`, `Radius`; required on create |
| `exclusive` | bool? | default the kind's `exclusiveAreas` |
| `worldName` | string? | ≤ 100; default the structure's world |
| `wgRegionId` | string? | ≤ 128; `Region` only |
| `points` | `[{x, z}]?` | `Polygon`: 3–200 points |
| `centerX`, `centerY`, `centerZ` | int? | `Radius`: default the structure's Location |
| `radius` | int? | `Radius`: 1–1024 |
| `minX`, `minY`, `minZ`, `maxX`, `maxY`, `maxZ` | int? | `Region`, `Cuboid`: the corners (any order); `Polygon`: `minY`/`maxY`; `Radius`: `minY`/`maxY` (default −64 and 319); y −2048…2048. Read: the bounding box |
| `size` | long | read: blocks, volume or radius |
| `sizeUnit` | string | read: `blocks`, `volume`, `radius` |
| `maxSize` | long? | read: the level's `maxAreaSize` |
| `enabled` | bool? | default true |
| `surveyRequestedAt`, `surveyRequestTrigger` | read | a pending request |
| `lastSurveyId`, `lastSurveyedAt` | read | the latest survey |
| `createdAt` | read | |

Errors: "productionStructureId is required.", "Give the structure a production kind first: the kind sets the area
model.", "The structure already has an area named 'X'.", "shape is required: Region, Cuboid, Polygon or Radius.",
"<field> is required for shape <shape>.", "wgRegionId is required for shape Region.", "A polygon needs at least 3
points.", "radius must be 1 to 1024.", "centerX and centerZ are required: the structure has no Location to centre the
radius on.", "minY must be at most maxY.", "The area is N (<unit>); level L of <kind> allows at most M." (400); "The area
overlaps the exclusive area 'X' of <structure>: exclusive <model> areas may not overlap." (409); "An area can't move to
another structure; delete it and create one there.".

## 4. `api/AreaSurveys` (read only)

| Method | Route | Answer |
|---|---|---|
| `GET` | `api/AreaSurveys/{id}` | `AreaSurveyDto` (units by count, descending) or 404 |
| `POST` | `api/AreaSurveys/search` | `PagedResultDto<AreaSurveyListDto>`; filters `productionAreaId`, `productionStructureId`, `trigger`; default newest first; sort `id`, `surveyedAt` |
| `GET` | `api/AreaSurveys/trend?productionAreaId=&take=30` | `AreaSurveyTrendDto`: `surveys` (oldest first, 1–100) and `series` (unit key → one count per survey) |

## 5. The game server's survey contract

**Queue:** `GET api/ProductionAreas/survey-due?limit=` (1–200, default 50). Empty while `Production:Enabled` is off.
Areas that are enabled, of a structure with a kind and yield source Derived or Hybrid, and requested, never surveyed or
surveyed 24 hours ago or more; requested first.

```json
[{
  "area": { "id": 7, "name": "North wood", "shape": "Radius", "centerX": 120, "centerZ": -40, "radius": 24, "…": "…" },
  "productionKindId": 2, "productionKindName": "Logger",
  "surveyProfileJson": "{\"unitTypes\":[\"TREE\",\"SAPLING\"]}", "surveyProfileVersion": 1,
  "trigger": "Creation",
  "overlappingSharedAreas": [{ "productionAreaId": 9, "productionStructureId": 4, "shape": "Radius", "…": "…" }]
}]
```

**Report:** `POST api/ProductionAreas/{id}/surveys`

```json
{
  "surveyedAt": "2026-11-20T10:15:00Z",
  "profileVersion": 1,
  "trigger": "Scheduled",
  "contentHash": "9f2c…",
  "note": "12 chunks, 3 trees",
  "units": [
    { "unitKey": "TREE:OAK:LARGE", "count": 3, "sharedBy": 1 },
    { "unitKey": "TREE:OAK:LARGE", "count": 1, "sharedBy": 2 },
    { "unitKey": "WATER:RIVER", "count": 120, "extra": "{\"columns\":60,\"avgDepth\":2.00,\"openSkyShare\":1.00}" }
  ]
}
```

| Field | Rule |
|---|---|
| `surveyedAt` | default now; at most an hour in the future |
| `profileVersion` | default the kind's; ≥ 0 |
| `trigger` | `Creation`, `Admin`, `Scheduled`, `NotableChange`; default the area's pending request, else `Scheduled` |
| `contentHash` | ≤ 128 |
| `note` | ≤ 500 |
| `units[].unitKey` | `^[A-Z0-9_]+(:[A-Z0-9_]+)*$` after trim and upper-case, ≤ 100 |
| `units[].count` | ≥ 0 |
| `units[].sharedBy` | 1–100, default 1; a key once per `sharedBy` |
| `units[].extra` | ≤ 500 |
| `units` | ≤ 2000 rows |

The API settles the structure, stores the survey, makes it the area's latest unless an equal or newer one is already
latest, clears the request and materializes the lines. Answer: `AreaSurveyDto` plus `materialization`
(`YieldMaterializationDto`: `linesCreated`, `linesUpdated`, `linesWithoutYield`, `skippedConfigured`, `notes`).
409: "Production is turned off (Production:Enabled): surveys are not taken.", "The structure is Configured: it is never
surveyed (G5)."

**Survey now:** `POST api/ProductionStructures/{id}/survey` with `{ "productionAreaId": 7 }` or an empty body (every
enabled area). Answer: the requested `ProductionAreaDto[]`. 404 for an unknown structure or "The structure has no enabled
area with id N."; 409 "The structure is Configured: it is never surveyed (G5). Switch it to Derived or Hybrid first." or
"The structure has no enabled area to survey."

## 6. `api/ProductionYieldOverrides`

| Method | Route | Answer |
|---|---|---|
| `GET` | `api/ProductionYieldOverrides`, `…/{id}` | `ProductionYieldOverrideDto` |
| `POST` | `api/ProductionYieldOverrides` | 201 |
| `PUT` | `api/ProductionYieldOverrides/{id}` | 204 |
| `DELETE` | `api/ProductionYieldOverrides/{id}` | 204 |
| `POST` | `api/ProductionYieldOverrides/search` | filters `productionStructureId`, `itemBlueprintId`, `kind`; sort `id` (default), `name` |

`ProductionYieldOverrideDto`: `id`, `productionStructureId` (required, can't change), `itemBlueprintId` (required; one
override per structure and blueprint), `kind` (`Pin`, `Exclude`, `Scale`; required), `value` (Pin: base rate per hour
above 0 and at most the line maximum; Scale: factor 0–100; Exclude: stored as 0), `note` (≤ 500), `createdAt`. Every
write settles the structure first and materializes after. Overrides are stored for any structure but count only while
its yield source is Hybrid.

## 7. `api/ProductionStructures/{id}/yield` and `/materialize`

`GET …/yield` → `ProductionYieldDto`: `productionStructureId`, `yieldSource`, `productionKind`, `level`, `surveysRun`,
`areas` (`ProductionAreaDto[]`), `outputs`, `unmatchedUnitKeys`, `notes`. Each output (`YieldOutputDto`):
`itemBlueprintId`, `itemBlueprintName`, `derivedRatePerHour`, `override`, `overrideValue`, `baseRatePerHour`,
`isPrimary`, `productionLineId`, `lineRateSource`, `contributions[]` (`productionAreaId`, `areaName`, `areaSurveyId`,
`unitKey`, `yieldRowUnitKey`, `count`, `sharedBy`, `share`, `ratePerUnitPerHour`, `byproductChance`, `ratePerHour`).

`POST …/materialize` → `YieldMaterializationDto` (§ 5). 404 for an unknown structure.

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#882).
