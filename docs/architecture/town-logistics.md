# Town logistics: policies, reserves, service areas and the planner (knk-web-api and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-21 (§ 4.3 demand source Shop level, § 11 shops collect: P10 #248 in `next` `289f4d4b`, docs #939); 2026-11-21 (P9 API follow-ups #928; first version production P9 #127/#686, docs PandiO/knk-workspace#929)
**Checked against:** knk-web-api `next` `37be22e5` (PR PandiO/knk-web-api#73), knk-web-app `next` `c12e0e7e` (PR
PandiO/knk-web-app#72). Not released; the manual steps of the
[smoke test § 10](../guides/production-storage-transport-smoke-test.md#10-phase-p9-town-logistics-127-api-686-web-app-tier3)
have not been run live yet.
**Related:** [TOWN_LOGISTICS § 2-5](../specs/production-storage-transport/TOWN_LOGISTICS.md) (the design: network,
consumers, the rule catalogue, the planner), decisions D-L1 to D-L3 and F11
([DECISIONS_2026-11-05](../specs/production-storage-transport/DECISIONS_2026-11-05.md)),
[API contract](../specs/api/API_CONTRACT_TOWN_LOGISTICS.md), [town logistics admin guide](../guides/admin/town-logistics-admin-guide.md),
[production transport](production-transport.md) (orders, carriers, lanes, `CreatePlannedAsync`),
[production world](production-world.md) (warehouses, structures, districts and rural placement),
[production engine](production-engine.md) (lines and their inputs), [stock core](stock-core.md) (storages, the ledger)

Phase P9 decides how goods move **inside a town**: from the town's **warehouses** to the **consumers** that need them.
A consumer is any structure with an **Input** or **Merchandise** storage. Each consumer storage has a **min**
(reorder point) and **max** (target level) per blueprint. The town's versioned **logistics policy** adds **reserves**
(stock the planner may not hand out), **priority classes** (who is served first when stock is short) and **service
areas** (which warehouse serves which district, the rural territory or a structure). The **planner** runs per town
every 10 minutes: it finds the consumer lines at or below their min, **reserves** stock at a warehouse up to the max and
makes a **collection order** (transport origin `Distribution`) that the consumer's **own worker** carries (reserve and
collect, D-L1). Every decision gets a one-line **explanation**, and a **dry run** shows the whole plan without writing
anything.

The planner only runs while the API's game setting **Production enabled** (`Production:Enabled`) is on (A21). Policies,
rules, consumer settings, the views and the dry run work while it is off. There is no game server part in P9: no plugin
code, no `config.yml` key and no command. The plugin's `production.logistics.lanes.*` keys belong to the lane measurer
of [production transport](production-transport.md), not to this planner.

## 1. Ownership

| Part | Where | Owns |
|---|---|---|
| `LogisticsPolicy`, `LogisticsRule`, `ConsumerReplenishment`, `LogisticsReservation`, `LogisticsPlannerRun`, `LogisticsPlanEntry` | knk-web-api `Models/Logistics/Logistics.cs` | The six tables of migration `AddTownLogistics` (§ 2) |
| Enums | knk-web-api `Enums/LogisticsEnums.cs` | Scopes, rule types, targets, area kinds, priority classes, reservation states, plan outcomes (stored as strings) |
| `LogisticsPolicyService` | knk-web-api `Services/Logistics/LogisticsPolicyService.cs` | Policy versions, rule validation, templates and Apply (§ 3) |
| `ConsumerReplenishmentService` | `Services/Logistics/ConsumerReplenishmentService.cs` | Min/max settings per consumer storage and blueprint |
| `LogisticsRecordsService` | `Services/Logistics/LogisticsRecordsService.cs` | Reservation reads and Release, planner run reads |
| `LogisticsRuleSet`, `LogisticsTownState` | `Services/Logistics/LogisticsTownState.cs` | The rules in force for a town and the town's state for one run: stock, consumers, demand settings, rule matching (§ 4) |
| `LogisticsPlanner` | `Services/Logistics/LogisticsPlanner.cs` | Settle, plan, write; the supply, service-area and consumer views (§ 5, § 6) |
| `LogisticsPlannerSweepService` | `Services/Logistics/LogisticsPlannerSweepService.cs` | The hosted service: every 60 s, plans each due town (§ 5.6) |
| Controllers | `Controllers/LogisticsControllers.cs` | `api/LogisticsPolicies`, `api/LogisticsRules`, `api/ConsumerReplenishments`, `api/LogisticsReservations`, `api/LogisticsPlannerRuns`, `api/Logistics` ([API contract](../specs/api/API_CONTRACT_TOWN_LOGISTICS.md)) |
| `ProductionSettings.ValidateLogistics` | `Services/Territory/ProductionSettings.cs` | The game settings section `production.logistics` (§ 7) |
| Service area for inbound deliveries | `Services/Production/TransportService.cs` (`EvaluateAsync`) | A producer without a preferred warehouse delivers to its service area's warehouse (§ 4.4) |
| Collection orders | `TransportService.CreatePlannedAsync` | Orders with origin `Distribution` and an idempotency key, inside the planner's transaction |
| Web app types and clients | knk-web-app `src/types/dtos/production/LogisticsDtos.ts`, `src/apiClients/logistics*` | Mirrors of `LogisticsDtos.cs` and `LogisticsEnums.cs` |
| Web app panels | knk-web-app `src/components/logistics/` | `TownLogisticsPanel`, `WarehouseLogisticsPanel`, `StructureLogisticsPanel`, `LogisticsPolicyPanel` with `LogisticsRuleEditor`, `LogisticsPlanView`, `LogisticsPlannerRunPanel`, `LogisticsReservationPanel` |
| Web app page and card | `src/pages/admin/logistics/LogisticsPage.tsx` (`/admin/logistics`), `src/components/admin/gameSettings/LogisticsSettingsCard.tsx` | The policy list; the settings card on Game settings |
| Client-side checks | `src/utils/logistics.ts` | The API's rule and settings checks mirrored before a save, labels, "low supply" |

## 2. Data model

| Table | Row | Keys and lifetime |
|---|---|---|
| `logistics_policies` | One **version** of a policy: scope `Town` (with `TownId`), `Warehouse` (with `WarehouseId`) or `Template` (with optional `Specialization`, `TownSize`, `IsDefaultTemplate`); `Version`, `LineageId` (the id of version 1), `BasedOnPolicyId`, `SupersededByPolicyId`, `SupersededAt`, `Author` (`Admin`; `ClanCouncil` is Later), `Reason`, `CreatedAt`, `CreatedByUserId` | Unique nullable `CurrentKey`: `town:<id>`, `warehouse:<id>` or the lineage of a template; set only on the current version, so a town or warehouse has at most one current policy. A version is never changed after it is written |
| `logistics_rules` | One rule of a version (§ 3.2): `Sequence`, `Type`, `Scope`, target, consumer, area, parameters, `ActiveFrom`/`ActiveUntil`, `Author`, `Reason` | Deleted with their version (cascade) |
| `consumer_replenishments` | Min/max of one blueprint in one consumer storage: `StorageId`, `StructureId` (the storage's holder), `ItemBlueprintId`, `ReorderPoint`, `TargetLevel`, optional `PriorityClass`, `Enabled`, `Note` | One per storage and blueprint |
| `logistics_reservations` | Stock held at a warehouse storage for a consumer storage: `Amount`, `Collected`, `Status` (`Open`, `Collected`, `Released`, `Cancelled`), `PriorityClass`, `TransportOrderId`, `PlannerRunId`, `ExpiresAt`, `ClosedAt`, `Explanation`, `StatusReason` | Unique nullable `OpenKey` `<consumerStorageId>:<blueprintId>`: one open reservation per consumer storage and blueprint |
| `logistics_planner_runs` | One run: `Trigger` (`Scheduled`, `Manual`), policy id and version used, start and finish, counts (demand lines, reservations made, orders made, released, collected, shortfalls), `Summary` | Runs older than `runRetentionDays` (14) are pruned by the sweep, 500 per sweep |
| `logistics_plan_entries` | The explanation of one consumer storage and blueprint in a run (every outcome except `NotNeeded`): stock, min, max, shortfall, reserved, `Outcome`, `RuleIds`, reservation and order ids, `Explanation` | Deleted with their run |

All amounts are raw units of the blueprint. Limits: 200 rules per policy, units and levels up to 100,000,000, days of
cover above 0 and at most 3650, a rule's reason 300 characters, a policy's reason 500.

## 3. Policies and rules

### 3.1 Versions

1. `POST api/LogisticsPolicies` writes version 1. A town or warehouse that already has a current policy is refused
   (409): edit that one.
2. A save (`PUT api/LogisticsPolicies/{id}`) writes version n + 1 with the rule list from the request, which replaces
   the old list as a whole, and supersedes `{id}`. Only the current version can be saved (409 otherwise, naming the
   current one). The save locks the old row (`SELECT … FOR UPDATE`) and moves the `CurrentKey`, so two saves at once
   make one new version and the other gets 409 "reload and try again".
3. Scope, town and warehouse can't change between versions. Old versions stay readable (`GET {id}/versions`, newest
   first) and read only. Planner runs record the policy id and version they used.
4. `DELETE` removes the whole lineage (every version and its rules). Planner runs keep the plain policy id.
5. Copy on write was chosen over drafts with activate or an audit log on a mutable row (L23 decision 4).

### 3.2 The V1 rule catalogue

These are the V1 rule types of [TOWN_LOGISTICS § 4](../specs/production-storage-transport/TOWN_LOGISTICS.md). Any other
type is refused with a pointer to [#324](https://github.com/PandiO/knk-workspace/issues/324): ceilings, allocation
quotas, rebalance, export/import, emergency modes and taxes are Later.

| Type | Scope | Items (`targetKind`) | Consumers (`consumerKind`) | Parameters | Example |
|---|---|---|---|---|---|
| `Reserve` (saving rule) | `Town` (town-wide) or `Warehouse` (local, with `warehouseId`) | `Any`, `Blueprint`, `Category` or `Tag` | — | `units` or `daysOfCover` (exactly one) | "Keep 14 days of bread town-wide"; "Docks keeps 500 planks" |
| `PriorityClass` | `Town` | as above | `Any`, `Structure` (one structure of the town) or `ProductionKind` (every structure of a kind) | `priorityClass`: `Critical`, `High`, `Normal`, `Low` | "Garrison food is Critical" |
| `ServiceArea` | — | — | — | `warehouseId` and `areaKind`: `District` (with `districtId`), `Rural` (the town's rural territory) or `Structure` (with `structureId`) | "Rural north → North Granary" |
| `Replenishment` | `Town` | as above | as `PriorityClass` | `reorderPoint` ≥ 0, `targetLevel` > 0, reorder point ≤ target level | "Every bakery: flour min 50, max 200" |

Every rule has an optional active window (`activeFrom`, `activeUntil`, UTC; until after from), an author and a reason
shown in the planner's explanation. The service checks every rule of a save and answers one 400 with all problems
("Rule 2: …"). Places must belong to the policy's town: warehouses by town or district, structures and districts the
same.

Per scope:

1. **Town policy:** every type.
2. **Warehouse policy:** local reserves and service areas only, always about its own warehouse (a reserve is forced to
   scope `Warehouse`).
3. **Template:** no warehouse rules, no service areas, no structure or district; it is for any town. Specialization is
   a `ResourceCategory` (`Crops`, `Wood`, `Stone`, `Ore`, `Fish`, `Flowers`, `Animals`) or empty for general; town size
   `Village`, `Town`, `City` or empty. One template can be the **default** (`isDefaultTemplate`); saving another as
   default clears the flag on the others. None is seeded.

### 3.3 Templates and Apply

`POST api/LogisticsPolicies/{templateId}/apply` with `{ townId, reason }` copies the template's rules into the town's
policy: a new version of the current one (keeping its name), or version 1 named "<town> logistics". `BasedOnPolicyId`
points at the template and the default reason is `From template "<name>" v<n>.` Admins pick the template (L23
decision 5). Since [#928](https://github.com/PandiO/knk-workspace/issues/928) a town carries an optional size and
specialization (`towns.LogisticsTownSize`, `towns.LogisticsSpecialization`, read and set with
`GET`/`PUT api/LogisticsPolicies/towns/{id}/profile`), and the profile suggests the current template with both labels
equal, else the same size with a general specialization, else the default template. The suggestion only helps the
picker: nothing is applied automatically, and the planner still uses the town's policy or the default template (§ 4.1).

## 4. The rules in force (`LogisticsRuleSet`, `LogisticsTownState`)

### 4.1 Which policy

1. The town's current policy (`PolicySource` `Town`), else the current **default template** (`DefaultTemplate`), else
   none (`None`: no reserves, no priorities, service areas by distance only; the plan warns about it).
2. Plus the current policies of every warehouse of the town (in one of its districts, or rural with its `TownId`).
3. Only rules active at the run's time count. The town policy's rules come first, then the warehouse policies', each
   in sequence order.

### 4.2 Matching

1. Items: `Blueprint` 3, `Category` 2 (the blueprint's category or any parent), `Tag` 1, `Any` 0.
2. Consumers: `Structure` 2, `ProductionKind` 1, `Any` 0.
3. `PriorityClass` and `Replenishment` take the **most specific** matching rule: consumer match first, then item
   match (score consumer × 10 + item).
4. `Reserve` takes the **largest** matching reserve, separately town-wide and per warehouse. Days of cover become units
   as ⌈days × average daily outflow⌉: the town's outflow for a town-wide reserve, the warehouse's for a local one.
5. Outflow and inflow are stock moves out of and into the town's warehouse storages (moves between two of its
   warehouses don't count) over the last `consumptionWindowDays` (7), divided by the window.

### 4.3 Demand: min and max per consumer storage

A consumer storage is a `Domain` storage with purpose `Input` or `Merchandise` whose holder is a structure of the town
that is not a warehouse. For each storage, one line per blueprint, the first source wins:

1. **Setting:** an enabled `ConsumerReplenishment` of that storage and blueprint (its priority class, if set, wins over
   the rules too).
2. **Rule:** the best `Replenishment` rule. A blueprint target creates demand on its own; a category, tag or `Any`
   target applies only to blueprints the structure's production lines consume.
3. **Shop level** (P10, #248): for a shop's Merchandise storage, each enabled `Stocked` blueprint catalogue entry with
   the shop type level's `reorderPointUnits` (min) and `targetUnits` (max), source `ShopLevel`; a level without
   `targetUnits` gives none ([shops § 7](shops.md#7-restocking-reserve-and-collect)). A category, tag or `Any`
   `Replenishment` rule also applies to these blueprints.
4. **Inputs:** for an Input storage, each line input's rate per hour × `defaultReorderHours` (4) for the min and ×
   `defaultTargetHours` (12) for the max, rounded up (L23 decision 8). Other Merchandise storages have no line inputs,
   so they need a setting or a blueprint rule.

The stock the planner compares is the storage's stock plus what is **on the way** to it in open `Distribution` orders
(planned minus delivered).

### 4.4 Service areas

For a structure: a `ServiceArea` rule with `areaKind` `Structure` for it, else the `District` rule of its district (a
structure in a district) or the `Rural` rule (a rural structure); the first in rule order wins. Without a rule the
nearest warehouse by road serves (`Source` `Nearest`). The same lookup gives producers their inbound warehouse: a
producer without a preferred warehouse delivers to its service area's warehouse when that one accepts and has room;
otherwise the transport evaluation warns and uses the nearest ([production transport](production-transport.md)).

## 5. The planner (`LogisticsPlanner`)

A run plans one town. A real run locks the town row (`SELECT … FOR UPDATE`) and runs in one transaction; a scheduled
run that finds the town planned meanwhile does nothing. The MySQL race test shows four runs at once make one
reservation and one order.

### 5.1 Step 1: settle reservations

Each open reservation of the town:

1. Its collection order loaded goods, or is loaded or delivered: `Collected` (with the loaded amount).
2. Its order ended (final) before loading: `Released`.
3. Past `ExpiresAt` (created + `reservationMinutes`, 30, F11): `Released`, and its order is cancelled when it is still
   `Planned` or `Assigned` (L23 decision 6: released at the first run after expiry).
4. It has no order: `Released`.

### 5.2 Step 2: what is free

Per blueprint, town-wide: stock in the town's warehouses − the town reserve − open reservations. Per warehouse: its
stock − its local reserve − its open reservations. Never below 0.

### 5.3 Step 3: demand lines and early outcomes

Every demand line (§ 4.3) gets an entry, checked in this order:

| Outcome | When |
|---|---|
| `AlreadyReserved` | An open reservation for this storage and blueprint is waiting for its worker |
| `NotNeeded` | Stock plus on the way is above the min |
| `NoWorker` | The consumer is not a production structure or has no workers (consumers collect with their own worker, D-L1; L23 decision 2) |
| `NotConnected` | A rural consumer whose road connection is not `Connected` (no off-road collection, D5) |
| `NoRoom` | Its storage has no room for one unit (capacity in raw units × storage weight) |
| `NoWarehouse` | The town has no warehouse |

The rest are short: shortfall = max − (stock + on the way). Each gets its priority class (setting, else the
`PriorityClass` rule, else `Normal`) and its warehouse candidates: the service area's warehouse first, then the others
by road distance (lane cost), then warehouse priority.

### 5.4 Step 4: serve by priority, then distance

The short lines are served `Critical`, `High`, `Normal`, `Low`, and inside a class by the distance to their first
candidate. For each line:

1. The need is the shortfall, cut to the room left in the storage after this run's other collections (`NoRoom` when
   none is left).
2. Take the first candidate that covers the whole need from what is free (warehouse and town-wide), else the one that
   covers most (L23 decision 7). Within a warehouse, the storage with the most free stock of it.
3. Nothing free anywhere: `NoStock` when no warehouse holds it, else `HeldByReserve` (reserves or higher classes took
   it).
4. One **collection order** per consumer storage and warehouse storage; the consumer may start one per worker this run
   (`CarrierFull` when all have one: next run). The order's lines are cut to the worker's carrier capacity (the
   structure's transport capacity, else the transport default); a line that no longer fits is `CarrierFull`.
5. The line is `Reserved` (the whole shortfall) or `PartlyReserved` (scarcity, a reserve, room or capacity), with a
   reservation for the carried amount that expires after `reservationMinutes`.

Each entry's explanation names the stock and on the way, the min and max with their source, the shortfall, the
priority class and where it came from, the warehouse and why it was picked, the reserves and rule ids involved, and
what limited the amount. Example: "Coal at Bakery is 0 (0 in stock + 0 on the way); min 20, max 60 (replenishment
setting #3): at or below the reorder point, short 60; Normal priority (the default). Reserved 60 of 60 at North, its
service area (nearest by road); no town reserve; collected by its own worker."

### 5.5 Step 5: write

A real run stores the reservations, makes each collection order through `TransportService.CreatePlannedAsync` (origin
`Distribution`, carrier = the consumer, from the warehouse storage to the consumer storage, an idempotency key per run
and group) inside the run's transaction, and stores the run with its entries (all but `NotNeeded`). The transport
sweep then sends the consumer's worker; while it is away the consumer's own output drops, as for any carrying worker
([production transport](production-transport.md)). A dry run returns the same plan, `dryRun: true`, with no ids and
nothing written, also while production is off.

### 5.6 Schedule

`LogisticsPlannerSweepService` wakes every 60 seconds. While `Production:Enabled` is on it plans every town that has a
warehouse and whose last run started at least `plannerIntervalMinutes` (10, D-L2) ago, then prunes old runs. A failing
town is logged and counted; the others still run. `POST api/Logistics/towns/{id}/run-now` runs one town at once (409
`ProductionDisabled` while production is off).

## 6. Views

1. **Town supply** (`GET api/Logistics/towns/{id}/supply`): per blueprint across the town's warehouses stock, reserved,
   reserve units, available, inflow and outflow per day and days of cover (stock ÷ daily outflow; null without
   outflow), with a per-warehouse split; the open reservations, the policy in force, the last run and the next
   scheduled one (null while production is off).
2. **Service areas** (`GET …/towns/{id}/service-areas`): each district, the rural territory and every structure that
   sends or receives goods, with the serving warehouse and whether a rule or the distance decided.
3. **Consumer** (`GET api/Logistics/consumers/{structureId}`): its storages with the demand lines and their source, its
   workers and carrier capacity, the serving warehouse, its open reservations and warnings.

In the web app ([admin guide](../guides/admin/town-logistics-admin-guide.md)) these are panels below the generic
detail pages, the pattern of the earlier production phases (L24 decision 1): **Town logistics** on a town's page,
**Logistics** on a warehouse's page, the consumer panel on a production structure's page, the rule editor and versions
on a policy's page, the plan explanation on a planner run's page, Release on a reservation's page. The panels show only
for staff with `knk.admin.world` and read nothing otherwise (L24 decision 5). The supply view marks a line as **low**
when nothing is available or it has under 3 days of cover.

The seeded form's Edit of a policy saves a new version that keeps the current rules (`updateKeepingRules`), because a
`PUT` without rules would empty the policy (L24 decision 3). Template labels are sent on every save (L24 decision 4);
since [#928](https://github.com/PandiO/knk-workspace/issues/928) the API also keeps a label left out (null) and clears
it on an empty string, so another client can't clear one by accident. Plan entries, collection orders, reservations,
service-area entries and the consumer view carry the consumer's structure type (`Shop`, `ProductionStructure`,
`Warehouse`, `GateStructure`, `Structure`), so a consumer can link to its own page.

## 7. Settings

Game settings section `production.logistics` (part of the production settings, validated on save):

| Key | Default | Range | Meaning |
|---|---|---|---|
| `plannerIntervalMinutes` | 10 | 1-1440 | Minutes between two scheduled runs of a town |
| `reservationMinutes` | 30 | 1-10080 | A reservation not collected within this is released at the next run |
| `consumptionWindowDays` | 7 | 1-90 | Days of outflow averaged for days of cover |
| `defaultReorderHours` | 4 | 0-720, ≤ target hours | Min of a line without a setting or rule, in hours of line input |
| `defaultTargetHours` | 12 | above 0, ≤ 720 | Max of such a line |
| `runRetentionDays` | 14 | 1-365 | Planner runs older than this are pruned |

No `api.env` key and no plugin key.

## 8. Access

Reads need the World dashboard area (`knk.admin.world` or a node under it) or the plugin key. Writes, Apply, Release,
the dry run and run now need `knk.admin.world` or the plugin key, plus the dashboard change rule on create and update;
deletes of a policy or a consumer setting also need `knk.admin.delete`. The dashboard types `LogisticsPolicy` and
`ConsumerReplenishment` are editable; `LogisticsRule`, `LogisticsReservation` and `LogisticsPlannerRun` are view only,
`LogisticsPlanEntry` view only without a seed. All are in the World area with lookups, pinned in
`ReadAccessRulesTests`, `DeleteAccessRulesTests`, `DashboardChangeAccessRulesTests` and `LookupFiltersTests`. The
`knk.admin.world` node was chosen like transport, over `knk.economy.admin` (L23 decision 9).

## 9. Migration, seeds and set-up

1. Migration `20261121024444_AddTownLogistics`: additive, the six tables of § 2, no data written
   ([production installation § 5.3](../guides/production-installation.md) item 16).
2. Seeds (form and display, "make default"): `LogisticsPolicy`, `ConsumerReplenishment`, `LogisticsRule`,
   `LogisticsReservation`, `LogisticsPlannerRun`; the last three forms are read only.
3. Set-up: a default template or town policies, consumers with an Input or Merchandise storage, workers on the
   consumers, and min/max settings where the line-input defaults don't fit ([admin guide](../guides/admin/town-logistics-admin-guide.md)).

## 10. Tests and recovery

### 10.1 Tests

1. knk-web-api xUnit: `Tests/.../Services/Logistics/LogisticsPlannerTests.cs` (17: outcomes, priorities, reserves,
   service areas, expiry, capacity, dry run), `LogisticsPolicyTests.cs` (8: versions, validation, templates),
   `Migrations/AddTownLogisticsTests.cs` (3), and with `KNK_TEST_MYSQL` `MySql/LogisticsMySqlTests.cs` (the run race).
   The access tests pin every route.
2. knk-web-app: Jest `src/utils/__tests__/logistics.test.ts`, `src/apiClients/__tests__/logisticsClients.test.ts`;
   Playwright `e2e/logistics.spec.ts` (20 tests, strict API, fixtures `e2e/fixtures/logistics.ts`). Specs that open a
   town, warehouse or production structure page as World staff mock the panels with `mockNoTownLogistics`,
   `mockNoWarehouseLogistics` and `mockNoConsumerLogistics`.
3. Manual: [smoke test § 10.1](../guides/production-storage-transport-smoke-test.md#101-steps-api) (24 API steps, 21
   automated, 3 partly) and [§ 10.2](../guides/production-storage-transport-smoke-test.md#102-steps-web-app-686) (22
   web app steps); not run live yet.

### 10.2 Recovery

1. **A reservation holds stock nobody collects:** release it (`POST api/LogisticsReservations/{id}/release`, or Release
   on the reservation's page); its collection order is cancelled before loading. After loading the next run marks it
   `Collected` instead (409 on Release).
2. **A wrong policy version:** save a new version with the old rules (copy them from the version in the history), or
   apply the template again. Versions are never edited in place.
3. **The planner stopped:** check `Production:Enabled`, that the town has a warehouse, and the API log for "Logistics
   planner failed for town <id>". A run now shows the error at once.
4. **Turning it off:** `Production:Enabled` off stops scheduled and manual runs; open reservations stay until the next
   run after it is on again settles them. Deleting a town's policy makes the town use the default template.

## 11. Limitations

1. Only production structures have workers. Shops are production structures underneath (P10,
   [#248](https://github.com/PandiO/knk-workspace/issues/248), [shops](shops.md)), so they collect with their own
   worker; other consumers (generic structures) show `NoWorker`.
2. No Rebalance orders between warehouses, no ceilings, quotas, export/import, emergency modes or taxes (Later,
   [#324](https://github.com/PandiO/knk-workspace/issues/324)). #127's original body listed Rebalance; the Decided
   catalogue marks it Later (L23 decision 1).
3. Warehouses have no workers in V1: consumers collect, warehouses never deliver.
4. Towns have no size or specialization fields, so templates are applied by hand; plan entries carry no structure type
   and some reads lack item and storage names; no `townId` lookup filter ([#928](https://github.com/PandiO/knk-workspace/issues/928)).
5. The council author (`ClanCouncil`) and in-game management are Later (TOWN_LOGISTICS § 4.1, #256).
6. The sweep's 60 s wake-up is fixed; only the per-town interval is a setting.
