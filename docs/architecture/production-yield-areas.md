# Production yield areas and surveys: areas, surveys, yield tables and Derived/Hybrid rates (knk-web-api, knk-plugin and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-21 (§ 6 and limitations: the placeholder overlay is the P8 regeneration queue, docs #922); 2026-11-20 (first version, production P4 #138/#679/#680, docs PandiO/knk-workspace#882)
**Checked against:** knk-web-api `next` `e26c7d88` (PR PandiO/knk-web-api#60), knk-plugin `next` `d36001b2` (PR
PandiO/knk-plugin#105), knk-web-app `next` `eaf0467d` (PR PandiO/knk-web-app#67). Not released; the manual steps of the
[smoke test § 5](../guides/production-storage-transport-smoke-test.md#5-phase-p4-yield-areas-and-surveys-138-api-679-plugin-680-web-app-tier3)
have not been run live yet.
**Related:** [PRODUCTION_KINDS § 2–4 and § 8](../specs/production-storage-transport/PRODUCTION_KINDS.md) (the rules),
[production DESIGN](../specs/production-storage-transport/DESIGN.md), [API contract](../specs/api/API_CONTRACT_PRODUCTION_YIELD.md),
[admin guide](../guides/admin/production-yield-areas-admin-guide.md), [production engine](production-engine.md) (lines,
settle, modifiers; P4 plugs into its § 9), [production world](production-world.md) (the structures),
[plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production) (`production.surveys.*`)

Phase P4 lets a production structure's rates come from the world. A structure gets one or more **areas** (a WorldGuard
region, a cuboid, a polygon or a radius). The game server **surveys** each area: it counts what the area holds (trees by
species and size, rock and ores, crops, flowers, water, animals) as **unit keys** and reports the counts to the API. The
API keeps every survey as history. The structure's kind has a **yield table** that turns unit keys into item blueprints
at a rate per unit per hour. A structure's **yield source** decides where its lines' base rates come from: `Configured`
(the rates staff type, as in P3), `Derived` (the latest surveys through the yield table) or `Hybrid` (Derived, then the
structure's pins, exclusions and scales). The engine of P3 still settles the lines; P4 only supplies the base rate and
two extra steps (primary output, variation) in the modifier pipeline.

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| Entities (area, survey, survey unit, yield row, primary output, Hybrid override) | knk-web-api | `Models/Production/ProductionYield.cs`; enums `ProductionAreaShape`, `AreaSurveyTrigger`, `ProductionYieldOverrideKind` in `Enums/ProductionEngineEnums.cs`; P4 fields on `ProductionKind` (`Models/Production/ProductionEngine.cs`) and `ProductionStructure` (`Models/Production/ProductionStructure.cs`) |
| Seeded survey profiles | knk-web-api | `ProductionCatalogSeed.SurveyProfile` (written by migration `AddProductionYieldAreas`) |
| Geometry, unit keys, yield calculator, Derived and Hybrid providers, primary and variation steps | knk-web-api | `Services/Production/ProductionYield.cs` (`AreaGeometry`, `SurveyUnitKeys`, `ProductionYieldCalculator`, `DerivedBaseRateProvider`, `HybridBaseRateProvider`, `PrimaryOutputModifierSource`, `VariationModifierSource`) |
| Area CRUD, survey queue and report, survey history and trend, overrides, materialization | knk-web-api | `Services/Production/ProductionAreaServices.cs` (`ProductionAreaService`, `AreaSurveyService`, `ProductionYieldOverrideService`, `ProductionYieldService`) |
| Yield table, primary outputs, survey profile on the kind | knk-web-api | `Services/Production/ProductionCatalogServices.cs` (`ProductionKindService.ApplyYieldAsync`) |
| Yield source on the structure | knk-web-api | `Services/Production/ProductionWorldServices.cs` (`ApplyYieldSourceAsync`) |
| Controllers and DTOs | knk-web-api | `Controllers/ProductionAreasController.cs`, `AreaSurveysController.cs`, `ProductionYieldOverridesController.cs`, the P4 actions of `ProductionStructuresController.cs` (`yield`, `survey`, `materialize`); `Dtos/ProductionYieldDtos.cs` |
| Dashboard types and access | knk-web-api | `Attributes/DashboardAccess.cs` (`ProductionArea`, `ProductionYieldOverride`; view only `AreaSurvey`, `AreaSurveyUnit`, `ProductionYieldRow`, `ProductionKindPrimaryOutput`), `Attributes/DashboardLookups.cs` |
| Form and display seeds | knk-web-api | `Data/FormConfigurationSeeds/{ProductionArea,ProductionYieldOverride}.json`, new versions of `ProductionKind`, `ProductionStructure`, `Structure`; display seeds `AreaSurvey`, `ProductionArea`, `ProductionYieldOverride` and new versions of `ProductionKind`, `ProductionStructure` |
| Survey rules (pure) | knk-plugin | `knk-core/.../core/production/survey/`: `SurveyCounter`, `SurveyProfile`, `SurveyMaterials`, `AreaShape`, `AreaSpec`, `SurveySettings`, `NotableChangeTracker`, `PlaceholderOverlay`, `CaptureRadius`, `SurveyUnit`, `SurveyDue` |
| API port and client | knk-plugin | `knk-core/.../core/ports/api/ProductionSurveyApi.java`, `knk-api-client/.../api/impl/ProductionSurveyApiImpl.java` |
| Paper side | knk-plugin | `knk-paper/.../paper/production/`: `SurveyModule` (poll, listeners), `SurveyRunner` (budgeted snapshots), `ChunkSnapshotBlocks`, `SurveyWorld`, `SurveyRegionShapes`, `SurveyConfig`, `AreaOutlineRenderer`, `CaptureRadiusTaskHandler`; `commands/ProductionAdminCommand.java`; wiring in `KnKPlugin` |
| Plugin scenario | knk-plugin | `knk-paper/.../paper/scenario/scenarios/ProductionAreaSurveyScenario.java` (`production-area-survey`) |
| Types and API clients | knk-web-app | `src/types/dtos/production/ProductionYieldDtos.ts`; `src/apiClients/{productionArea,areaSurvey,productionYieldOverride}Client.ts`; `getYield`, `requestSurvey`, `materialize` on `productionStructureClient.ts` |
| Panels | knk-web-app | `src/components/production/`: `StructureYieldPanel`, `ProductionAreaPanel` (with `AreaPlot`, `SurveyCompositionTable`, `SurveyTrendTable`), `AreaSurveyPanel`, `ProductionKindYieldTablePanel` (mounted by `src/pages/DisplayWizardPage.tsx`) |
| Labels and checks | knk-web-app | `src/utils/productionYield.ts` (`yieldSourceText`, `isYieldFormType`, override checks) |

## 2. Areas

### 2.1 Model, shape and bounding box

1. **The model comes from the kind** (`ProductionKind.AreaModel`, PRODUCTION_KINDS § 3.1): `BorderedField`,
   `ExclusiveVolume`, `SharedRadius`, `Pasture`, `HuntingGround`. It is copied onto the area on every save; a structure
   needs a production kind before it can have an area ("Give the structure a production kind first: the kind sets the
   area model.").
2. **The shape** (`ProductionAreaShape`) is how the area is stored:

   | Shape | Fields | Bounding box |
   |---|---|---|
   | `Region` | `wgRegionId` and the region's corners (`minX…maxZ`) | the reported corners |
   | `Cuboid` | two corners `minX…maxZ` (any order) | the corners, sorted |
   | `Polygon` | `points` (`[{x, z}]`, 3 to 200) and `minY`/`maxY` | the points' extremes and the y range |
   | `Radius` | `radius` (1–1024), `centerX/Y/Z` (empty = the structure's Location), `minY`/`maxY` (empty = −64 and 319) | centre ± radius |

   The y values must lie in −2048…2048 with `minY ≤ maxY`. A partial update of the same shape keeps the fields it does
   not send. `worldName` defaults to the structure's world (then its Location's world, then `world`). A Region area
   does not read its bounds from WorldGuard yet; staff type them ([#877](https://github.com/PandiO/knk-workspace/issues/877)
   item 1).
3. **Size** (`AreaGeometry.Size`) is what the level's `MaxAreaSize` caps, in the unit of the model
   (`AreaGeometry.SizeUnit`): footprint **blocks** for `BorderedField` and `Pasture` (a polygon's shoelace area, a
   radius's ⌈π r²⌉, else width × depth), **volume** for `ExclusiveVolume` (footprint × height), **radius** for
   `SharedRadius` and `HuntingGround` (the radius, or half the wider side of the box for other shapes). An area over the
   cap is refused (400) with the size and the maximum; a level-up raises the cap. The cap is checked on save only: a
   later level-down or cap change leaves larger areas as they are.

### 2.2 The no-overlap rule (G6)

1. `Exclusive` comes from the kind's `ExclusiveAreas` on create and can be turned off per area.
2. An exclusive area may not overlap another **exclusive** area of the **same model** in the same world. The check
   compares **bounding boxes** in the database (index `IX_production_areas_WorldName_Model_Exclusive`); a hit is a 409
   naming the other area and its structure. Two circles or polygons whose boxes touch but whose shapes do not are also
   refused (§ 9).
3. Shared (non-exclusive) areas may overlap anything. Their units are split (§ 4.3). `GET api/ProductionAreas/{id}/overlaps`
   lists every area whose box overlaps, exclusive or not, for the web app's plot.

### 2.3 Lifecycle

1. **Create** of an area of a Derived or Hybrid structure sets `SurveyRequestedAt` with trigger `Creation`; a Configured
   structure's area is never asked for (G5).
2. **Update** settles the structure first (the time before counts with the old area). A change of shape, world, region
   or box on an enabled area of a surveyed structure asks for a new survey (trigger `Admin`). An area cannot move to
   another structure.
3. **Delete** settles first, then removes the area with its surveys and their units.
4. **Disable** (`enabled: false`): never due, and its surveys no longer count in the yield.

## 3. Surveys

### 3.1 The queue and the report contract

```
plugin                                         API
  GET api/ProductionAreas/survey-due?limit=20  ──►  areas due, requested first
  ◄── [{ area, productionKindId, productionKindName, surveyProfileJson,
         surveyProfileVersion, trigger, overlappingSharedAreas }]
  … snapshots on the main thread, counting off it …
  POST api/ProductionAreas/{id}/surveys        ──►  settle, store, latest?, materialize
       { surveyedAt, profileVersion, trigger, contentHash, note,
         units: [{ unitKey, count, sharedBy, extra }] }
  ◄── 200 AreaSurveyDto + materialization
```

1. **Due** (`ProductionAreaService.SurveyDueAsync`): enabled areas of structures with a kind and a yield source other
   than Configured that are requested, never surveyed or last surveyed 24 hours ago or more. Order: requested (oldest
   request first), then by last survey, then by id. `limit` 1–200, default 50. The list is **empty while
   `Production:Enabled` is off** (A21). Each item carries the trigger the plugin should report (`Admin`/`Creation` when
   requested, `Creation` when never surveyed, else `Scheduled`) and, for a shared area, the other structures' enabled
   shared areas that overlap it (for the split).
2. **Report** (`ReportSurveyAsync`), 409 while `Production:Enabled` is off or for a Configured structure. Checks: unit
   keys normalized (§ 3.3), `count ≥ 0`, `sharedBy` 1–100, a key at most once per `sharedBy`, at most 2000 rows,
   `surveyedAt` not more than an hour in the future, `contentHash` ≤ 128 and `note` ≤ 500 characters. `trigger` defaults
   to the area's pending request, else `Scheduled`; `profileVersion` defaults to the kind's.
3. Then: settle the structure (the time before counts at the old contents), store the survey (`TotalUnits` = Σ counts),
   make it the area's latest **only when it is not older than the current latest** (a late report stays in the history
   only), clear a request made before now, and materialize the lines (§ 5). The answer carries the materialization.
4. **Survey now**: `POST api/ProductionStructures/{id}/survey` (optional `productionAreaId`) puts the structure's
   enabled areas at the head of the queue with trigger `Admin`. 409 for a Configured structure or one without an enabled
   area; 404 for an unknown structure or area. The command and the web app button use it; the plugin's notable-change
   counter uses it too and reports its survey with trigger `NotableChange` (§ 6.4).

### 3.2 History and trend

1. Every survey is kept (`area_surveys`, `area_survey_units`); nothing prunes them yet (§ 9).
2. `AreaSurvey`: `surveyedAt` (the plugin's time), `receivedAt` (the API's), `profileVersion`, `trigger` (`Creation`,
   `Admin`, `Scheduled`, `NotableChange`), `contentHash`, `totalUnits`, `note`, and the unit rows.
3. `GET api/AreaSurveys/trend?productionAreaId=&take=30` (1–100) gives the last surveys oldest first and, per unit key,
   one count per survey (`series`). The web app draws one small line per unit (insight "a forest being cut down").

### 3.3 Unit keys

1. A unit key is upper-case segments of `A–Z`, `0–9` and `_` joined by colons, at most 100 characters
   (`SurveyUnitKeys.NormalizeKey`; input is trimmed and upper-cased). The plugin writes (`SurveyCounter`):

   | Unit type | Key | Counted |
   |---|---|---|
   | `CROP` | `CROP:<TYPE>` | crop blocks, growth stage ignored |
   | `TREE` | `TREE:<SPECIES>:<SMALL\|MEDIUM\|LARGE>` | 26-connected log clusters inside the area with leaves within `leafReach`; species by majority log; size by log count (`smallMaxLogs` 6, `mediumMaxLogs` 20); a cluster over `maxLogs` (400) is a building and not counted |
   | `SAPLING` | `SAPLING:<SPECIES>` | saplings (future forest) |
   | `BLOCK` | `BLOCK:<MATERIAL>` | rock and every ore, or the profile's `materials`, in the whole volume |
   | `FLOWER` | `FLOWER:<TYPE>` | flowers, the lower half of tall ones |
   | `WATER` | `WATER:<BIOME>` | still water source blocks per biome of the column's top water block; `extra` `{"columns","avgDepth","openSkyShare"}` |
   | `ENTITY` | `ENTITY:<TYPE>` | animals seen in the area (default farm animals, or the profile's `entityTypes`) |

2. A **yield row pattern** is a key, a key ending in `:*` (a prefix: `TREE:OAK:*`) or `*` alone
   (`NormalizePattern`). Per blueprint, the most specific matching row wins: an exact key beats every prefix, a longer
   prefix beats a shorter one, `*` matches last; ties go to the lower row id (`SurveyUnitKeys.Match`).

### 3.4 The survey profile

1. `ProductionKind.SurveyProfileJson` (≤ 4000 characters, a JSON object) tells the plugin what to count;
   `SurveyProfileVersion` rises on every change and is stored with each survey. The migration seeds version 1:

   | Kind (id) | Profile |
   |---|---|
   | Farm (1) | `{"unitTypes":["CROP"]}` |
   | Logger (2) | `{"unitTypes":["TREE","SAPLING"]}` |
   | Quarry (3), Mine (4) | `{"unitTypes":["BLOCK"]}` |
   | Fishery (5) | `{"unitTypes":["WATER"]}` |
   | Flower farm (6), Florist (7) | `{"unitTypes":["FLOWER"]}` |
   | Animal farm (8) | `{"unitTypes":["ENTITY"]}` |

2. The plugin owns the rest of the format (`SurveyProfile.parse`); every field but `unitTypes` is optional:

   ```json
   {
     "unitTypes": ["TREE", "SAPLING"],
     "materials": ["STONE", "COAL_ORE"],
     "entityTypes": ["SHEEP", "COW"],
     "tree": { "smallMaxLogs": 6, "mediumMaxLogs": 20, "maxLogs": 400, "leafReach": 1 }
   }
   ```

   Unknown unit types and fields are ignored with a warning; `leafReach` is clamped to 1–4. A missing or broken profile
   counts nothing, and the survey fails with "the kind's survey profile counts nothing" (§ 6.2).

## 4. From surveys to base rates

### 4.1 Yield sources (PRODUCTION_KINDS § 4.1)

| Source | Base rate of a line | Surveyed | Overrides |
|---|---|---|---|
| `Configured` | `ConfiguredRatePerHour` staff enter | never (G5) | ignored |
| `Derived` | the yield calculator over the latest surveys | yes | ignored (the yield view says so) |
| `Hybrid` (default, P-D1) | Derived, then the structure's override for that output | yes | applied |

1. `ProductionStructure.YieldSource` must be one the kind allows (`AllowsDerived`, `AllowsConfigured`,
   `AllowsHybrid`; a kind allows at least one). A new structure without a choice gets the first allowed of Hybrid,
   Derived, Configured. **Structures that existed before P4 were migrated as `Configured`** (column default), so they
   keep their P3 lines and rates.
2. A line's `RateSource` follows the structure: a `Derived` or `Hybrid` line is only accepted on a structure of that
   source; a `Configured` line may sit on any structure and keeps its configured rate (an admin's explicit line wins).
3. The engine asks the `IProductionBaseRateProvider` of the line's source (production engine § 9): `DerivedBaseRateProvider`
   and `HybridBaseRateProvider` both call `ProductionYieldCalculator.ComputeAsync` and take the line's blueprint.

### 4.2 The calculation (`ProductionYieldCalculator`)

For each **enabled** area with a latest survey, for each unit row of that survey, for each blueprint of the kind's
yield table rows with `MinLevel ≤ structure level`, the best matching row (§ 3.3) adds:

```
contribution = count ÷ sharedBy × ratePerUnitPerHour × byproductChance
```

rounded to the engine's decimals. A blueprint's **derived rate** is the sum over all areas and units. Units no row
matches are listed as `unmatchedUnitKeys`. For a Hybrid structure the override then sets the **base rate**:

| Override | Base rate |
|---|---|
| none | derived rate |
| `Pin` (value > 0, ≤ the line maximum) | the value, whatever the survey says |
| `Exclude` | 0 |
| `Scale` (factor 0–100) | derived rate × factor |

A pin of an output no survey yields still makes that output (and its line). `byproductChance` is a share (P-D9): a row
with 0.25 produces a quarter of the rate, deterministically, not by dice.

### 4.3 The `sharedBy` split (G7)

1. A unit counted in a **shared** area that other structures' shared areas also cover is split equally between them:
   the plugin sets `sharedBy` = 1 + the number of **other structures** whose enabled shared areas contain the unit's
   position (a tree's lowest log, a water column's top block). It gets those areas from `overlappingSharedAreas` in the
   due item. Exclusive areas are never split (`overlappingSharedAreas` is empty for them).
2. The rows are one per (key, `sharedBy`): `TREE:OAK:LARGE` × 3 own and × 2 `sharedBy 2` are two rows.
3. The API divides each row's count by its `sharedBy`. Each structure is surveyed on its own schedule, so two
   structures' halves come from different surveys and can disagree for up to a day.
4. Known gap: the split is per unit position over all overlapping shared areas, whatever their kind; a logger and a
   flower farm whose radii overlap split each other's trees and flowers although only one of them yields from each
   ([#875](https://github.com/PandiO/knk-workspace/issues/875), split per unit type).

### 4.4 Primary outputs and variation (PRODUCTION_KINDS § 4.2)

Two built-in modifier sources run in the P3 pipeline (production engine § 4) and show in the cycle trace:

1. **Primary** (`PrimaryOutputModifierSource`): a blueprint listed in the kind's `PrimaryOutputs` gets
   `× PrimaryMultiplier` (default 1.5, 0–100) on Derived and Hybrid lines ("Primary output of Mine"). Configured lines
   and a multiplier of 1 add nothing.
2. **Variation** (`VariationModifierSource`): with the kind's `CycleVariation` on, every line gets a factor in
   0.9–1.1 ("Variation (±10%)"), fixed per line and UTC hour (SHA-256 of `variation:<lineId>:<hour>`), so a replay of
   the same settle gives the same result. It applies to Configured lines too.

## 5. Materialization: outputs become lines

`ProductionYieldService.MaterializeAsync` (also `POST api/ProductionStructures/{id}/materialize`) settles the structure,
then:

1. **Configured structure:** every non-Configured line becomes `Configured` (its configured rate kept). Nothing else.
2. **Derived or Hybrid:** for every output with a base rate above 0 it makes a line if none exists (rate source = the
   structure's, anchored now, next settle one cycle on). An existing Configured line of that output is kept and listed
   as `skippedConfigured`; other lines take the structure's source. Lines whose output no longer yields stay, with a base
   rate of 0 (`linesWithoutYield`): nothing is deleted, so cycle records and storage links survive.
3. It runs after every survey report, override create, update or delete, yield source change, level or kind change of
   a surveyed structure, and yield table change of the kind (for each of the kind's surveyed structures). A change of
   primary outputs or multiplier settles but does not re-materialize (no new outputs).
4. The answer lists `linesCreated`, `linesUpdated`, `linesWithoutYield`, `skippedConfigured` and notes.

`GET api/ProductionStructures/{id}/yield` (`ExplainAsync`) returns the same computation for display: the yield source,
level, whether surveys run, the areas with size and cap, every output with its derived rate, override, base rate,
primary flag, line and the contributions (area, survey, unit key, matched row, count, `sharedBy`, share, rate per unit,
chance, rate), the unmatched unit keys and notes ("No area has been surveyed yet.", "The structure is Derived: its Hybrid
overrides are ignored.", …). For a Configured structure, and for a Configured line on a surveyed one, the base rate shown
is the configured rate.

## 6. The game server (knk-plugin)

### 6.1 Wiring and settings

Nothing is built, listened to or sent unless `production.enabled: true` (A21, G16). Then `KnKPlugin` builds the
`SurveyModule` with `SurveyConfig.read` (`production.surveys.*`, defaults when the block is missing), registers
`/knk production` and the `CaptureRadius` world task handler. The keys (plugin configuration § 4.31):

| Key | Default | Meaning |
|---|---|---|
| `poll-minutes` | 5 | how often `survey-due` is read; 0 = only on the command and after a notable change |
| `batch` | 20 | queue items per read (1–200) |
| `chunks-per-tick` | 2 | chunk snapshots per server tick (1–64) |
| `max-area-blocks` | 16,000,000 | larger areas (columns × height) are skipped |
| `max-area-chunks` | 256 | areas spanning more chunks are skipped |
| `scheduled-loads-chunks` | false | false: a `Scheduled` survey waits for loaded chunks; requested ones load them |
| `notable-change-blocks` | 64 | block breaks and places in one area that ask for a survey (0 = off) |
| `notable-cooldown-minutes` | 30 | at most one notable-change survey per area this often |
| `areas-refresh-minutes` | 10 | how often `GET api/ProductionAreas` is re-read |

### 6.2 The async `ChunkSnapshot` pipeline (`SurveyRunner`)

One survey runs at a time, in queue order.

1. **Prepare (main thread):** the area becomes an immutable `AreaShape` (`Cuboid`, `Polygon` with a y band, or
   `Radius` as a vertical cylinder; a `Region` area is read from WorldGuard by `SurveyRegionShapes`, cuboid or polygonal
   regions only). Skipped with the reason when the world is not loaded or the area is over `max-area-chunks` or
   `max-area-blocks`.
2. **Capture (main thread, budgeted):** every tick, `tick()` takes at most `chunks-per-tick` chunk snapshots
   (`ChunkSnapshot`, timed as `production.survey.capture` in the metrics). An unloaded chunk is loaded without
   generating it, except for a `Scheduled` survey with `scheduled-loads-chunks: false`, which is **skipped and stays due**
   (P-D2 "when the chunks are loaded"). The animals in the area are read on the main thread. A capture that takes too
   long fails ("capture timed out").
3. **Count (off the main thread):** `SurveyCounter` runs on the counting executor over the snapshots
   (`ChunkSnapshotBlocks`), the `PlaceholderOverlay` (blocks waiting to regenerate count as their original: the harvest
   regeneration queue since P8, #134, [harvesting architecture § 6.4](production-harvesting.md#64-placeholders-and-the-persisted-regeneration-queue-production_kinds--7-p-d7-p-d8)) and the entities. It is pure: the same world gives the same rows and the same `contentHash`
   (SHA-256 of the sorted `key|sharedBy|count|extra` lines).
4. **Report (off the main thread):** `POST …/surveys` with the due item's profile version and the trigger
   (`NotableChange` when the notable counter asked for it, else empty so the API uses the request's). The outcome
   (`REPORTED`, `SKIPPED`, `FAILED` with the reason) goes back to the main thread for the log, the command sender and
   `survey status`.

### 6.3 Polling and failures

The module reads `survey-due` every `poll-minutes` and on `/knk production survey`. An API error is logged and the area
stays due (nothing is cleared until a report succeeds). A skipped Scheduled survey also stays due, so it is offered again
at the next poll.

### 6.4 Notable change

`NotableChangeTracker` indexes the known areas (refreshed every `areas-refresh-minutes`) by chunk and counts block breaks
and places inside them. After `notable-change-blocks` changes since the last survey, at most once per
`notable-cooldown-minutes`, the module asks the API for a survey of that area (`POST …/{structure}/survey`), marks it and
polls; the report then carries trigger `NotableChange`.

### 6.5 Commands and the radius task

1. `/knk production survey <structure> [area]`, `survey status`, `area show <structure> [area] [seconds]`, node
   `knk.admin.world.production` (admin guide § 6). `<structure>` is an id, or the name of a structure that has areas in
   the plugin's area list. `area show` draws the outline with particles (`AreaOutlineRenderer`, default 30 s).
2. `CaptureRadiusTaskHandler` handles world task type `CaptureRadius` (chat `radius <n>`, `center`, `confirm`, `cancel`,
   `discard`; output `shape`, `worldName`, `centerX/Y/Z`, `radius`). The API does not know the task type yet and the
   area form does not start it ([#877](https://github.com/PandiO/knk-workspace/issues/877) item 2), so it cannot be used
   from the web app yet.

## 7. Web app

1. **Production structure page** (`StructureYieldPanel`): the yield source in words, the areas (shape, size against the
   cap, exclusive or shared, last survey, "(survey requested)", "(disabled)"), **Add area**, **Survey now** (not for
   Configured), "Outputs and why each rate is what it is" (per output: derived rate, override, base rate, primary, the
   contributions behind it, the unmatched units) and, for Hybrid, the override of each output (None, Pin, Exclude,
   Scale) and "Pin an output the survey doesn't yield".
2. **Production area page** (`ProductionAreaPanel`): structure, model and shape, size against the cap, exclusive or
   shared, last survey, enabled; **Survey this area now**; "From above" (`AreaPlot`, the footprint with overlapping areas,
   also as a table); the latest survey's composition (`SurveyCompositionTable`: count, share of the survey, "Shared by
   N" or "Own", extra); the trend over the last 30 surveys (`SurveyTrendTable`: first, latest, change, a small line per
   unit); the history.
3. **Area survey page** (`AreaSurveyPanel`): one survey's composition.
4. **Production kind page** (`ProductionKindYieldTablePanel`): the yield table (unit key, output, rate per unit/h,
   chance, from level) and the primary outputs, each list saved as a whole. The survey profile and the primary multiplier
   are on the kind's seeded form.
5. The `ProductionArea` and `ProductionYieldOverride` forms report refusals (over the cap, overlap, a second override of
   an output) inline, as the placement rules do (`isYieldFormType`).

## 8. Schema, migration and access

1. Migration `AddProductionYieldAreas` (`20261119205631`), additive:
   1. `production_structures.YieldSource` varchar(16), default `Configured` for existing rows;
   2. `production_kinds.PrimaryMultiplier` decimal(12,4) default 1.5, `SurveyProfileJson` varchar(4000),
      `SurveyProfileVersion` int default 1; the eight seeded kinds get their profiles (§ 3.4);
   3. new tables `production_areas`, `area_surveys`, `area_survey_units`, `production_yield_rows`,
      `production_kind_primary_outputs`, `production_yield_overrides`. Deleting a structure cascades to its areas,
      surveys, units and overrides; deleting a kind cascades to its rows and primary outputs; a blueprint used by a row,
      primary output or override cannot be deleted (Restrict).
   4. Unique: area name per structure; (survey, unit key, `sharedBy`); (kind, unit key, blueprint); (kind, blueprint)
      for primary outputs; (structure, blueprint) for overrides.
2. Access (pinned in `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`):

   | Endpoints | Needs |
   |---|---|
   | reads of areas, surveys, trend, overrides, `…/yield`, `survey-due` | `knk.admin.world` (World area) or the plugin key |
   | area and override create, update | `knk.admin.world` and `knk.admin.content` (dashboard change rule), or the plugin key |
   | area and override delete | `knk.admin.world` and `knk.admin.delete` |
   | `POST …/{id}/surveys`, `POST api/ProductionStructures/{id}/survey`, `…/materialize` | `knk.admin.world` or the plugin key |
   | `/knk production …` in game | `knk.admin.world.production` |

3. Admin CRUD of areas and overrides works while `Production:Enabled` is off (DESIGN § 18.2); the queue is empty and
   reports are 409 then.

## 9. Tests, recovery and limitations

1. **Tests:** knk-web-api `Services/Production/ProductionYieldTests.cs` (18 tests: caps, shapes, overlaps, queue order,
   G5, feature off, report checks and late reports, trend, Derived, the split, Hybrid overrides, Configured lines,
   `MinLevel` and primary, profile versions, variation, delete), `Api/ProductionYieldControllersTests.cs`,
   `Services/Production/PlacementRulesTests.cs` (#831), `Migrations/AddProductionYieldAreasTests.cs`,
   `MySql/ProductionYieldMySqlTests.cs` (with `KNK_TEST_MYSQL`); knk-plugin `SurveyCounterTest`, `SurveyAreasTest`,
   `CaptureRadiusTest`, `ProductionSurveyApiImplTest`, `SurveyRunnerTest`, `SurveyConfigTest`,
   `ProductionAdminCommandTest` and the scenario `production-area-survey`; knk-web-app Jest
   `productionYieldClients.test.ts`, `productionYield.test.ts` and Playwright `e2e/production-yield.spec.ts`.
2. **Recovery:**
   1. Rates look wrong: open the structure's yield view; check the unmatched unit keys (no yield row), the area's
      latest survey and `sharedBy`, and the override.
   2. Lines missing after a yield table edit: `POST api/ProductionStructures/{id}/materialize`.
   3. Surveys never arrive: `production.enabled` on the game server and `Production:Enabled` in the API, the structure not
      Configured, the area enabled, then `/knk production survey status` for skips (unloaded chunks, size caps, profile).
   4. A bad survey: survey again; the newest survey replaces it as the latest (the bad one stays in the history).
3. **Limitations (P4):**
   1. The overlap rule compares bounding boxes, not shapes; the plugin does not check exact shapes either.
   2. Region areas need their bounds typed; the area form has no region capture step and the `CaptureRadius` task is not
      reachable from the web app ([#877](https://github.com/PandiO/knk-workspace/issues/877)).
   3. No default yield tables: the seeded kinds have profiles but no rows, so Derived and Hybrid structures yield
      nothing until staff fill the table ([#836](https://github.com/PandiO/knk-workspace/issues/836)).
   4. `sharedBy` ignores the unit type ([#875](https://github.com/PandiO/knk-workspace/issues/875)).
   5. Survey history is never pruned.
   6. An area keeps the model it was saved with when its kind's area model changes, until it is saved again.
   7. Harvest breaks count toward the NotableChange counter (#923).
   8. The structure list does not show the yield source ([#877](https://github.com/PandiO/knk-workspace/issues/877)
      item 3).

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#882).
2. 2026-11-21: the placeholder overlay is the P8 regeneration queue; limitation 7 is now #923 (docs PandiO/knk-workspace#922).
