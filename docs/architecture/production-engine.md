# Production engine: kinds, lines, modifiers, weather and cycles (knk-web-api and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-20 (P5: transport sends workers away, docs #891); 2026-11-20 (P4 pointers: Derived and Hybrid providers, area caps, variation; docs #882); 2026-11-19 (first version, production P3 #86/#678, docs PandiO/knk-workspace#839)
**Checked against:** knk-web-api `next` `6c648f60` (PR PandiO/knk-web-api#58), knk-web-app `next` `4e4ca39a` (PR
PandiO/knk-web-app#63). Not released; the manual steps of the
[smoke test § 4](../guides/production-storage-transport-smoke-test.md#4-phase-p3-production-engine-86-api-678-web-app-tier3)
have not been run live yet.
**Related:** [PRODUCTION_KINDS § 2–5](../specs/production-storage-transport/PRODUCTION_KINDS.md) (the rules),
[production DESIGN](../specs/production-storage-transport/DESIGN.md), [API contract](../specs/api/API_CONTRACT_PRODUCTION_ENGINE.md),
[admin guide](../guides/admin/production-engine-admin-guide.md), [production world](production-world.md) (the
structures, their storages and placement), [stock core](stock-core.md) (storages, capacity and the ledger the engine
writes to), [territory](territory.md) (`Production:Enabled`)

Phase P3 makes production structures produce. A structure has a **kind** (Farm, Logger, Quarry …) with ten **levels**,
and one **production line** per item it makes. Each line has a base rate per hour; the **modifier pipeline** (level,
weather, staff modifiers) and the **workers** present turn it into an effective rate. A background **sweep** settles
every due line on a fixed grid: it accrues the rate over the time passed, puts the whole units into the structure's
Output storage through the stock ledger and keeps the fraction. Every settle writes a **cycle record** that explains the
number. Staff upgrade a structure by paying the next level's resources and coins. Everything runs in the API; the game
server and players see nothing of P3 yet. The engine knows nothing of Minecraft beyond blueprint ids (DESIGN § 15.1).

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| Entities (kind, level, level item, line, line input, modifier, climate zone, zone odds, zone towns, weather type, effect, weather roll, cycle record) | knk-web-api | `Models/Production/ProductionEngine.cs`, `Enums/ProductionEngineEnums.cs` |
| Seeded catalogue | knk-web-api | `Models/Production/ProductionCatalogSeed.cs` (written by migration `AddProductionEngine`) |
| Engine: settle, rate formula, modifier sources, base-rate providers, overview, workers, upgrade, level caps | knk-web-api | `Services/Production/ProductionEngine.cs` (`IProductionEngine`, `ProductionRate`, `IProductionModifierSource`, `IProductionBaseRateProvider`, `ProductionLevels`) |
| Weather | knk-web-api | `Services/Production/ProductionWeather.cs` (`IProductionWeatherService`) |
| Sweep | knk-web-api | `Services/Production/ProductionSweepService.cs` (hosted service) |
| Catalogue and line CRUD, validation, search | knk-web-api | `Services/Production/ProductionCatalogServices.cs` |
| Kind, level caps and default storages on a structure | knk-web-api | `Services/Production/ProductionWorldServices.cs` (`ProductionStructureService`) |
| Settings `production.engine` | knk-web-api | `Dtos/TerritoryDtos.cs` (`ProductionEngineSettingsDto`), `Services/Territory/ProductionSettings.cs` |
| Controllers and DTOs | knk-web-api | `Controllers/Production{Kinds,KindLevels,Lines,Modifiers,CycleRecords}Controller.cs`, `ClimateZonesController.cs`, `WeatherTypesController.cs`, `ProductionController.cs`, the P3 actions of `ProductionStructuresController.cs`; `Dtos/ProductionEngineDtos.cs` |
| Dashboard types, lookups, access | knk-web-api | `Attributes/DashboardAccess.cs`, `Attributes/DashboardLookups.cs` |
| Notification `ProductionLineStatusChanged` | knk-web-api | `Dtos/PlayerNotificationDtos.cs`, `Services/InMemoryPlayerNotificationQueue.cs`, `Realtime/HubPlayerNotificationQueue.cs` |
| Form and display seeds | knk-web-api | `Data/FormConfigurationSeeds/{ProductionKind,ProductionKindLevel,ProductionLine,ProductionModifier,ClimateZone,WeatherType}.json` and their `.display.json`; `ProductionStructure` v2, `ItemBlueprint` v2 (form), `Storage` v2 (display) |
| Types and API clients | knk-web-app | `src/types/dtos/production/ProductionEngineDtos.ts`; `src/apiClients/production{Kind,KindLevel,Line,Modifier,CycleRecord}Client.ts`, `climateZoneClient.ts`, `weatherTypeClient.ts`, `productionClient.ts`; `getProduction`, `setWorkers`, `upgrade` on `productionStructureClient.ts` |
| Detail panels | knk-web-app | `src/components/production/`: `StructureProductionPanel`, `RateBreakdown`, `ProductionCycleTable`, `ProductionLinePanel`, `ProductionKindLevelsPanel`, `ProductionKindLevelItemsPanel`, `ClimateZonePanel`, `WeatherTypeEffectsPanel` (mounted by `src/pages/DisplayWizardPage.tsx`) |
| Settings card | knk-web-app | `src/components/admin/gameSettings/ProductionEngineSettingsCard.tsx` on `src/pages/admin/GameSettingsPage.tsx`; `normalizeProductionSettings` in `src/utils/territory.ts` |
| Labels and the rate steps | knk-web-app | `src/utils/productionEngine.ts` |

## 2. Kinds and levels

1. **A kind is data, not a class** (`ProductionKind`, PRODUCTION_KINDS § 2): name, description, icon (a Minecraft
   material name), area model (`BorderedField`, `ExclusiveVolume`, `SharedRadius`, `Pasture`, `HuntingGround`),
   exclusive areas, the yield sources it allows (Derived, Configured, Hybrid; at least one), resource category (`Crops`,
   `Wood`, `Stone`, `Ore`, `Fish`, `Flowers`, `Animals`), default workers (0–100, default 2), cycle variation (stored,
   used from P4: the Variation step, [yield areas § 4.4](production-yield-areas.md#44-primary-outputs-and-variation-production_kinds--42)), `DefaultStoragesJson` and active. The name is unique.
2. **Seeded catalogue** (migration `AddProductionEngine`, ids 1–8): Farm, Logger, Quarry, Mine, Fishery, Flower farm,
   Florist, Animal farm. Hunter is not in V1 (P-D10). The area model, category and level-1 area size follow
   PRODUCTION_KINDS § 2.1.
3. **Ten levels per kind** (`ProductionKindLevel`, G8), created with the kind and never added or removed
   (`api/ProductionKindLevels` is update only). The default curve (`ProductionCatalogSeed.DefaultLevel`), also used for
   kinds staff create:

   | Field | Level n | Effect |
   |---|---|---|
   | `YieldMultiplier` | 1 + 0.15 × (n − 1): 1 … 2.35 | the **Level** modifier (§ 4) |
   | `CycleSpeedMultiplier` | 1 + 0.05 × (n − 1): 1 … 1.45 | the cycle is base cycle ÷ speed; the rate per hour does not change (§ 3.2) |
   | `MaxAreaSize` | seeded kinds: level-1 size + step × (n − 1); new kinds: none | caps P4's areas (blocks, volume or radius by area model; [yield areas § 2.1](production-yield-areas.md#21-model-shape-and-bounding-box)) |
   | `OutputMaxUnits`, `UnitsPerSlot`, `TransportCapacity` | none | written to the structure on a level change (§ 2.5) |
   | `UpkeepReduction` | 0 | no effect in V1 (upkeep is Later) |
   | `UpgradeCoins` | 250 × (n − 1)²: 0, 250, 1000 … 20 250 | paid to reach the level (§ 8) |
   | `UpgradeDurationMinutes` | none | stored, not enforced |

4. **Level items** (`ProductionKindLevelItem`): role `Unlock` (the blueprint is produced only from this level on) or
   `UpgradeCost` (blueprint × amount paid to reach the level). One row per role and blueprint in a level. The seeded
   levels have none.
5. **On a structure.** `ProductionStructure.ProductionKindId` is a foreign key (Restrict) since P3; a kind with
   structures can't be deleted (409). Creating a structure with a kind gives it the kind's default workers (unless the
   request sets them), its Output storage plus the storages of `DefaultStoragesJson`, and the level's caps. Changing the
   kind or the level writes the new level's caps (`ProductionLevels.ApplyAsync`): `OutputMaxUnits` and `UnitsPerSlot` to
   the structure's Output storage, `TransportCapacity` to the structure; a cap left empty keeps the current value.
6. **`DefaultStoragesJson`** is a JSON list of `{ "purpose": "Input", "name": "inputs", "maxUnits": 500 }` (at most 10;
   any purpose but `Output`, which is always created). Each becomes a domain storage "<structure name> - <name>".

## 3. Lines and the settle grid

### 3.1 The line

A `ProductionLine` is one output of one structure (one line per blueprint per structure):

1. **Rate source.** `Configured` only in P3: the base rate is `ConfiguredRatePerHour` (0 to 1 000 000 units per hour,
   at level multiplier 1 with every worker present). `Derived` and `Hybrid` come with P4 (§ 9, [yield areas § 4](production-yield-areas.md#4-from-surveys-to-base-rates)).
2. **Resource category** (optional) overrides the kind's for weather and category modifiers.
3. **Enabled** is staff's switch; **Status** is `Running`, `Paused`, `BlockedFull`, `BlockedInputs` or `Error`, with a
   **StatusReason** in words.
4. **Accrued** is the fraction not yet emitted (decimal, six places).
5. **Grid:** `AnchorAt` (when the line was created), `LastSettledAt` (the end of the last settled period) and
   `NextSettleAt` (indexed; the sweep picks lines with `NextSettleAt ≤ now`).
6. **Inputs** (`ProductionLineInput`, at most 10): blueprint and amount per hour of running time, with their own
   fraction.
7. A line can't move to another structure. Deleting a line deletes its cycle records; a line a modifier is scoped to
   (`Output`) can't be deleted (409).

### 3.2 No drift

The cycle is `baseCycleMinutes × 60 ÷ CycleSpeedMultiplier` seconds (at least 1; `ProductionRate.Cycle`). Due times are
`AnchorAt + k × cycle`: after a settle at `now`, `NextSettleAt` is the first grid point strictly after `now`
(`ProductionRate.NextDue`). A sweep that runs late settles the actual time passed and the next due time stays on the
grid, so cycles never drift (V2 defects 5 and 10). Accrual uses the real elapsed seconds, not the cycle count, so the
rate per hour is the same at every cycle speed; a faster cycle only settles more often.

### 3.3 One settle (`SettleCoreAsync`)

Each line settles in **its own database transaction** with its row locked (`SELECT … FOR UPDATE`, read committed), so
two sweeps (or a sweep and a manual settle) never settle the same period twice; the MySQL test of four racing sweeps
proves it. In order:

1. **Nothing elapsed:** only `NextSettleAt` is recomputed (a stopped line is still looked at, to resume it).
2. **Gates** (each sets the status, accrues nothing and writes a record only when the status or reason changed):
    1. the structure's Production switch off → `Paused` "The structure's production is switched off.";
    2. the line switched off → `Paused` "The line is paused.";
    3. no provider for the rate source → `Error`;
    4. no Output storage → `Error` "The structure has no Output storage.";
    5. no room for one more unit (§ 5) → `BlockedFull` with the reason;
    6. a line blocked on inputs with an input still at 0 → stays `BlockedInputs`.
3. **Resume without catch-up:** a line that was not `Running` and passes the gates becomes `Running` from now; the
   stopped time is recorded as skipped, never produced.
4. **Accrue:** `elapsed = min(now − LastSettledAt, catch-up cap)`; `Accrued += effective rate × elapsed hours` (§ 4).
5. **Inputs** (§ 5.2), all or nothing.
6. **Emit** `floor(Accrued)` units from `SYS_PRODUCTION` to the Output storage with one stock move (reason
   `Production`, mode Partial, idempotency key `prod:<line>:<ticks>:out`). `Accrued` keeps the fraction.
7. **Status after:** all accepted → `Running` (and, when the cap cut time, the reason "Catch-up capped at 24 h: N s not
   produced."); fewer accepted → `BlockedFull` "The Output storage is full: A of E accepted.".
8. `LastSettledAt = now`, `NextSettleAt` on the grid, the cycle record (§ 6), commit; then the status notification
   (§ 7.3).

### 3.4 Catch-up cap

`production.engine.catchUpCapHours` (default 24, 1–720) bounds one settle. After an outage longer than the cap a line
produces at most the cap's worth and the record carries the skipped seconds. A stopped line never catches up (§ 3.3.3).

## 4. The modifier pipeline

1. **Base rate** from the line's `IProductionBaseRateProvider` (P3: `ConfiguredBaseRateProvider`).
2. **Modifier sources** (`IProductionModifierSource`, registered in DI, collected in order; a new factor is a new
   source, the engine does not change):

   | Source | Gives | Scope in the trace |
   |---|---|---|
   | `Level` | "Level n": Multiply by the structure's level row `YieldMultiplier` (none without a kind) | `Structure` |
   | `Weather` | "<type> in <zone> (<category>)": the effects of today's roll on the line's category (§ 4.1) | `Town` |
   | `Stored` | each enabled `ProductionModifier` whose scope, target and window match, source `Admin` | the row's scope |

3. **Formula** (`ProductionRate.Compute`, PRODUCTION_KINDS § 4.2, F8): every `Add` to the base first, then every
   `Multiply`, then × unlock × workers; never below 0; rounded to six decimals. The trace lists the modifiers in that
   order (additions first).
4. **Unlock** (0 or 1): 0 when a level of the kind lists the line's blueprint as `Unlock` and the structure is below the
   lowest such level; otherwise 1.
5. **Workers** (§ 4.2).
6. **Stored modifier matching** (`StoredModifierSource.Applies`):
    1. **Window:** `ActiveFrom` inclusive, `ActiveUntil` exclusive; empty = open.
    2. **Scope:** `Global` always; `Kingdom` the effective town's kingdom; `Town` the effective town (the district's
       town or the rural town); `Territory` rural structures of that town only; `Structure` that structure; `Output`
       that line. `MapArea` is stored but never matches (the painted map is Later).
    3. **Target:** `Any`; `Blueprint` the line's blueprint; `Category` the line's category; `Kind` the structure's kind.
    4. A `Multiply` value can't be negative; values are within ±1 000 000.

### 4.1 Weather

1. **Climate zone of a structure:** the zone its effective town is assigned to (`climate_zone_towns`, one zone per
   town), else the default zone. Exactly one zone is the default; the first zone created becomes it, setting another
   zone default moves it, and the default can't be unset or deleted.
2. **Weather day** = `floor(minutes since the Unix epoch ÷ weatherDayMinutes)` (default 20 = a vanilla day).
3. **Roll** once per zone and day (`WeatherRoll`, unique per zone and day): value = SHA-256 of
   `knk-weather:<zone>:<day>` → [0, 100). Odds are taken in ascending weather type id and cumulated; a value above their
   sum is **clear** (no type). So a replay of the same day gives the same weather. The stored row wins if the odds
   change later in the day. Two sweeps rolling at once: the unique index keeps the first, the other reads it.
4. The sweep rolls today for every zone that has no row; a settle that needs a missing day rolls it; a read never rolls
   (the overview reads the stored roll only).
5. **Effects** (`WeatherTypeEffect`): per category, `Add` or `Multiply` and a value; one effect per category per type.
6. **Seeded:** zone "Default climate" (default, no odds: always clear); types Rain (Crops, Flowers × 1.1), Storm (Fish
   × 0.5, Crops × 0.9), Drought (Crops × 0.6, Flowers × 0.7, Animals × 0.8). "Clear" is reserved as a type name.

### 4.2 Workers

`WorkerFactor = clamp(WorkersPresent, 0, WorkersTotal) ÷ WorkersTotal` (0 when there are no workers). One of two away
halves the output and the inputs; both away stops the line without blocking it. `PUT api/ProductionStructures/{id}/workers`
settles the structure first, so the time before counts at the old factor. Lowering `WorkersTotal` below the present
count lowers the present count with it. In P3 only staff or the game server (plugin key) set it; P5 sends workers away.

## 5. Full storage and inputs

### 5.1 Full Output storage (D4)

1. **Room** is checked before accruing (`NoRoomReasonAsync`): the storage's lock, its distinct-items cap (for a
   blueprint it doesn't hold yet) and its raw-units cap: Σ amount × `ItemBlueprint.StorageWeight` of its lines and unique
   items + one unit of the blueprint's weight must fit `MaxUnits` ([stock core § 6](stock-core.md#6-capacity)). An uncapped storage
   always has room.
2. **No room:** `BlockedFull` with the reason ("The Output storage is full (100 of 100 units).", "… is locked: …",
   "… holds as many different items as it may (distinct cap)."); nothing accrues while blocked.
3. **Partly accepted emit:** the units that don't fit stay in `SYS_PRODUCTION` (never produced) and the line becomes
   `BlockedFull`; they are not kept in `Accrued`, so there is no hidden catch-up.
4. **Resume** at the first settle that finds room, from that moment.

### 5.2 Inputs (V2 defect 12)

1. Taken from the structure's **first Input storage** (lowest id), per hour of running time, scaled by workers and
   unlock like the output. Each input keeps its own fraction; whole units are taken.
2. **All or nothing per settle:** when any input falls short, nothing is taken, nothing accrues, and the line becomes
   `BlockedInputs` "Not enough <blueprint> in the Input storage: needs N, has M." (or "The line needs inputs but the
   structure has no Input storage."). A blocked line resumes from the settle at which every input has at least one unit.
3. The inputs move to `SYS_CONSUMPTION` (reason `ProductionInput`, key `prod:<line>:<ticks>:in`) before the output is
   emitted; the record links the stock transaction.

## 6. Cycle records

1. A `ProductionCycleRecord` is written for every settle that accrued, and for every gate that changed the status or
   reason. It is append-only and holds: the period (start, end, settled at), elapsed and skipped seconds, rate source,
   base rate, each applied modifier (`ModifiersJson`: source, name, scope, effect, value, modifier id), unlock factor,
   workers present/total and factor, effective rate, accrued before/after, emitted, accepted, inputs taken
   (`InputsJson`), status after, shortfall reason and the stock transaction id.
2. Read through `GET api/ProductionCycleRecords/{id}`, `POST api/ProductionCycleRecords/search` (filters
   `productionStructureId`, `productionLineId`), the latest 20 of a structure in its overview, and the latest cycles of a
   line on the line page. The dashboard registers the type `ViewOnly`, so it has no list page of its own.
3. Indexed by line and settled time and by structure and settled time. There is no retention yet: one record per line
   per cycle grows without bound ([#828](https://github.com/PandiO/knk-workspace/issues/828)). The stock ledger's
   `Production` and `ProductionInput` moves roll up after 30 days as before ([stock core](stock-core.md)).

## 7. The sweep, `Production:Enabled` and the overview

### 7.1 The sweep

`ProductionSweepService` (hosted service, every 60 s, injectable `TimeProvider`) calls `IProductionEngine.SweepAsync`:

1. Reads the game settings. With `Production:Enabled` off it does **nothing else** (A21).
2. Rolls today's weather for each zone without a roll.
3. Settles up to 500 due lines (`NextSettleAt ≤ now`, oldest due first), each in its own transaction. A line that throws
   is counted as failed, logged as a warning and skipped; the others go on.
4. Logs a debug line when anything happened; outages of the database are logged through
   `ConnectivityAwareFailureLogger` as for the other sweeps.

`POST api/Production/run-now` runs the same sweep for **every** line (not only the due ones) and answers what it did.

### 7.2 `Production:Enabled` and the timing settings

1. The flag is the game setting `production.enabled` (the web app's "Production and territory" card; default off). Off:
   no sweep work, no weather rolls, `run-now` and `POST api/ProductionLines/{id}/settle` answer 409 "Production is turned
   off (Production:Enabled).", the overview doesn't settle and skips the weather source. Staff CRUD works either way.
2. The timing is the game setting section `production.engine`: `baseCycleMinutes` (default 10, 1–1440),
   `catchUpCapHours` (24, 1–720) and `weatherDayMinutes` (20, 1–10 080). Missing in stored JSON = the defaults; out of
   range = 400 on save. A changed base cycle applies from each line's next settle (its grid keeps its anchor).
3. The web app's game settings page must send `production.engine` back on every save, or the API resets it to the
   defaults; `normalizeProductionSettings` keeps it (fixed in #678). A later setting under `production` must be added
   there the same way.

### 7.3 Lazy settle and status notification

1. **Overview** (`GET api/ProductionStructures/{id}/production`, `OverviewAsync`): with the flag on it settles the
   structure first, then answers each line with its base rate, modifiers, unlock and worker factors, effective rate and
   "why not producing" reasons, the structure-wide reasons, its climate zone and today's weather, and the latest 20
   cycles. The reasons are the gates of § 3.3 in words plus "Unlocked at level N (the structure is level M).", "The
   structure has no workers.", "All workers are away (0 of N present).", "Only P of N workers present: X% output.",
   "The base rate is 0." and "The modifiers bring the rate to 0.". A structure without a kind is not a reason: its lines
   run without a level modifier.
2. **Settle on change:** a structure update that changes level, kind, total workers or the Production switch settles
   first (the time before counts at the old values); switching Production or a line back on settles again at once, so
   the line resumes from that moment instead of at the next sweep. A line update settles first too.
3. **Notification:** when a line's status changes into or out of `BlockedFull`/`BlockedInputs`, the engine enqueues a
   `ProductionLineStatusChanged` notification (user 0, for the game server and staff: structure, line, blueprint,
   previous and new status, reason) on the realtime hub. Nothing consumes it yet.

## 8. Upgrades

`POST api/ProductionStructures/{id}/upgrade` (`UpgradeAsync`) raises the level by exactly one:

1. Refused with 409 when the structure has no kind, is at level 10, the kind lacks the next level, or the level changed
   meanwhile; 400 when the level costs coins and no `payerUserId` is given.
2. Settles the structure first (the time before counts at the old level).
3. In **one database transaction**:
    1. the next level's `UpgradeCost` items move from `payFromStorageId` (default: the structure's Output storage) to
       `SYS_CONSUMPTION` with reason `Upgrade`, all or nothing;
    2. the level's `UpgradeCoins` are spent from the payer through the currency service (reason `PRODUCTION_UPGRADE`,
       initiator Admin with the staff member's user id, or System for the plugin key);
    3. the level rises and the level's caps are written (§ 2.5).

   A cost that can't be paid (stock short, coins short) is 409 with the reason and nothing changes.
4. **Idempotency:** the request's `idempotencyKey`, else `upgrade:<structure>:<target level>`, for both the stock move
   and the coin posting; a retry of the same upgrade applies once. Caution: the default key also replays after staff
   lowered the level by hand and upgrade to the same level again ([#841](https://github.com/PandiO/knk-workspace/issues/841)).
5. `UpgradeDurationMinutes` is stored but not enforced: the level rises at once.

## 9. Extension point for P4: `IProductionBaseRateProvider`

```csharp
public interface IProductionBaseRateProvider
{
    ProductionRateSource Source { get; }
    Task<decimal> BaseRatePerHourAsync(ProductionSettleContext ctx, CancellationToken ct = default);
}
```

1. The engine takes every registered provider (`IEnumerable<IProductionBaseRateProvider>`, keyed by `Source`). P3
   registers only `ConfiguredBaseRateProvider`.
2. `ProductionSettleContext` carries the structure, the line, the level row, the effective town and kingdom, the line's
   category, the moment and the engine settings.
3. P4 (#138, knk-web-api `next` `e26c7d88`) registers `DerivedBaseRateProvider` and `HybridBaseRateProvider` and the
   modifier sources `Primary` and `Variation`; a Derived or Hybrid line is accepted on a structure of that yield source
   ([yield areas architecture § 4–5](production-yield-areas.md#4-from-surveys-to-base-rates)). A line with a source no
   provider serves would stop with `Error` "Rate source X is not available yet (P4).".
4. New rate factors are new `IProductionModifierSource`s; P8's pool factor goes next to unlock and workers as a built-in
   step (`ProductionRate.Compute`).

## 10. Web app

1. **Kind** page: `ProductionKindLevelsPanel` lists the ten levels (yield, cycle speed, max area, output cap, upgrade
   coins, upgrade cost, unlocks), each linked to its level page. **Level** page: `ProductionKindLevelItemsPanel` edits the
   unlocks and upgrade cost and saves them with the level as read plus `items`.
2. **Line** page: `ProductionLinePanel` (structure, output, rate source and rate, state and reason, accrued, last and
   next settle, the inputs editor that sends `{ id, inputs }`, Settle now with the API's 409 reason, the latest cycles).
3. **Climate zone** page: `ClimateZonePanel` (odds, each 0–100 and together at most 100 with the rest shown as clear;
   towns; the stored rolls). **Weather type** page: `WeatherTypeEffectsPanel`. Each list editor sends only `{ id, <list> }`,
   which the API reads as "keep the other fields" (L10 decision 2).
4. **Production structure** page: `StructureProductionPanel` (kind, level, climate zone, weather today, structure-wide
   reasons; per line its state, reasons and `RateBreakdown`; Workers; Upgrade with the cost shown first, a payer and an
   optional storage, then a confirm step; the latest cycles in `ProductionCycleTable` with a trace per cycle).
   `RateBreakdown` computes its steps from the API's applied modifiers in the API's order and ends in the API's
   `effectiveRatePerHour`.
5. **Game settings:** `ProductionEngineSettingsCard` (the three timings with the API's bounds, saved with the page, and
   Run production now, disabled while production is off).
6. **Dashboard columns** (`objectConfigs`): kinds (area model, category, default workers, structures, active), levels,
   lines (structure, output, rate, status in words, next settle), modifiers ("+2/h" or "× 0.5", window), zones,
   weather types, cycle records.

## 11. Permissions

| Action | Needs |
|---|---|
| Read and search every P3 type, `GET …/production` | World area node `knk.admin.world`, or the plugin key |
| Create, update (kinds, levels, lines, modifiers, zones, weather types) | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| Delete | `knk.admin.world` and `knk.admin.delete` |
| `POST api/ProductionLines/{id}/settle`, `POST api/Production/run-now`, `PUT api/ProductionStructures/{id}/workers` | `knk.admin.world`, or the plugin key |
| `POST api/ProductionStructures/{id}/upgrade` | `knk.admin.world` and `knk.economy.admin`, or the plugin key |
| Game setting `production.engine` | as the game settings page |

Pinned by `EndpointAccessRulesTests`, `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and
`DeleteAccessRulesTests`. The level items, line inputs, zone odds and towns, weather effects and cycle records are
`ViewOnly` dashboard types: they are edited inside their parent.

## 12. Schema and migration

One additive migration `20261119193750_AddProductionEngine` (knk-web-api, after `AddProductionWorld`):

1. Thirteen tables: `production_kinds`, `production_kind_levels` (unique kind + level), `production_kind_level_items`
   (unique level + role + blueprint), `production_lines` (unique structure + blueprint, index `NextSettleAt`; cascade
   from the structure, Restrict to the blueprint), `production_line_inputs` (unique line + blueprint),
   `production_modifiers` (index enabled + scope), `climate_zones`, `climate_zone_weathers` (unique zone + type),
   `climate_zone_towns` (unique town), `weather_types`, `weather_type_effects` (unique type + category),
   `weather_rolls` (unique zone + day), `production_cycle_records` (cascade from the line). Kind, zone and weather type
   names are unique.
2. Foreign key `production_structures.ProductionKindId` → `production_kinds` (Restrict). Check before applying that no
   structure has a kind id outside 1–8: `SELECT Id FROM production_structures WHERE ProductionKindId NOT BETWEEN 1 AND 8;`.
3. Data: the catalogue of § 2.2 (80 levels), the default zone and the three weather types with their effects.
4. Rolled back to `AddProductionWorld` and re-applied in the link's test; `has-pending-model-changes` clean.

Deploy: [production installation § 5.3](../guides/production-installation.md#53-apply-the-migrations) item 8, then
import the six form and display seeds and make the v2 seeds of `ProductionStructure`, `ItemBlueprint` (form) and
`Storage` (display) the default. No `api.env` key, no plugin `config.yml` change.

## 13. Tests

1. **knk-web-api:** `ProductionEngineTests` (18: drift-free accrual over six hours of late sweeps, due lines only,
   run-now settles all, full storage stalls and resumes without catch-up, catch-up cap, inputs, the level modifier, new
   structures get the kind's workers, storages and caps), `ProductionModifierWeatherUpgradeTests` (27: formula order,
   scopes, targets, windows, validation, weather rolls and determinism, upgrades and refusals, the seeded catalogue),
   `ProductionEngineControllersTests` (2), `AddProductionEngineTests` (4), `ProductionSettingsTests`,
   `ProductionEngineMySqlTests` (2, with `KNK_TEST_MYSQL`: four sweeps racing settle each period once), the seed file
   tests and the pinned access tests.
2. **knk-web-app:** Jest `src/utils/__tests__/productionEngine.test.ts`, `src/apiClients/__tests__/productionEngineClients.test.ts`
   and the engine case of `territory.test.ts`; Playwright `e2e/production-engine.spec.ts` (17, strict API mocks in
   `e2e/fixtures/productionEngine.ts`). Strict specs that open a production structure page need a
   `ProductionStructures/<id>/production` mock.
3. **Manual:** [smoke test § 4](../guides/production-storage-transport-smoke-test.md#4-phase-p3-production-engine-86-api-678-web-app-tier3)
   (§ 4.1 API, § 4.2 web app), each step tagged with the tests above.

## 14. Recovery

1. **A line stays `BlockedFull`:** make room (move stock out, raise the Output storage's Max units, unlock it), then
   Settle now or wait for the sweep. The units not accepted are not produced later.
2. **A line stays `BlockedInputs`:** put at least one unit of each input into the first Input storage.
3. **`Error` "The structure has no Output storage.":** create a domain storage with purpose Output for the structure.
4. **Nothing produces anywhere:** `production.enabled` is off, or the sweep is failing (look for "Production sweep" in
   the API log); `POST api/Production/run-now` answers 409 when the flag is off.
5. **Engine timings back at 10/24/20 after a game settings save:** an older web app build dropped `production.engine`;
   deploy the web app of `next` `4e4ca39a` or later and set them again.
6. **Too much stock after an outage:** the catch-up cap bounds it; lower `catchUpCapHours` before bringing the API back
   if needed. Wrong output can be corrected with stock Adjust ([stock admin guide](../guides/admin/stock-admin-guide.md)).

## 15. Limitations (P3)

1. P3 alone has only `Configured` rates; areas, surveys, Derived/Hybrid yields, `MaxAreaSize` and cycle variation are
   used from P4 ([yield areas architecture](production-yield-areas.md), knk-web-api `next` `e26c7d88`).
2. No retention or roll-up of cycle records ([#828](https://github.com/PandiO/knk-workspace/issues/828)).
3. Upkeep and upgrade duration are stored without effect. Since P5 transport sends workers away and back
   ([transport architecture § 5.1](production-transport.md#51-the-carrier-design--77)); staff and the plugin key can still set them.
4. `MapArea` modifiers never match (the painted map is Later).
5. The structure search row has no kind name, a cycle record's inputs have no blueprint name, cycle records have no
   dashboard list, and the new-line form isn't pre-filled with the structure (points on
   [#678](https://github.com/PandiO/knk-workspace/issues/678#issuecomment-7021819495), not filed).
6. Nothing in game shows production yet, and nothing consumes `ProductionLineStatusChanged`.
7. The default upgrade key replays after a manual level change ([#841](https://github.com/PandiO/knk-workspace/issues/841)).

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#839).
2. 2026-11-20: pointers to the yield areas (P4) where P3 said "P4" (docs PandiO/knk-workspace#882).
