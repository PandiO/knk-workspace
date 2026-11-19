# Knights & Kings changelog

This is a human-readable record of capabilities merged into the V3 default branches. It is not a complete commit log or a promise that code has been deployed to a public server. See [the feature register](FEATURE_REGISTER.md) for design, branch and live-verification status. Entries before this changelog was established on **2026-09-28** are a selective backfill from merge records and feature plans; linked plans describe the precise live-test coverage.

## Unreleased — on feature branches, not merged

- **Production engine API: kinds, levels, production lines, modifiers, weather and the sweep** ([PandiO/knk-workspace#86](https://github.com/PandiO/knk-workspace/issues/86),
  link L9 of the production, storage and transport chain; [production kinds](specs/production-storage-transport/PRODUCTION_KINDS.md)
  § 2-5, [design](specs/production-storage-transport/DESIGN.md) § 9). Production structures now produce. A
  **production kind** is catalogue data (seeded: Farm, Logger, Quarry, Mine, Fishery, Flower farm, Florist and Animal
  farm; Hunter later) with ten **levels** each (yield multiplier, cycle speed, area cap for the yield areas, Output
  storage and transport caps written on level change, an upkeep field without effect, unlocks and an upgrade cost in
  resources and coins). A structure's **production lines** (one per output) have a configured rate per hour; the
  engine settles each line on a grid anchored at its creation (no drift): it accrues `rate × elapsed` with fractions
  kept, moves the whole units from `SYS_PRODUCTION` into the structure's Output storage through the stock ledger, and
  writes a **cycle record** with the base rate, every modifier, the workers present, what was emitted and accepted, and
  why anything fell short. The rate runs through a **modifier pipeline** (additions first, then multiplications) with
  three sources: the structure's level, the **weather** (climate zones with weather odds, assigned per town, rolled once
  per in-game day and stored) and staff-made modifiers (scope global, kingdom, town, territory, structure or one line;
  target any output, a blueprint, a category or a kind; an optional active window). Output also scales with the
  **workers** present (one of two away = 50%). A full Output storage stops the line without accruing and it resumes,
  without catching up, once there is room; inputs are taken from the structure's Input storage while a line runs;
  after downtime a line catches up at most 24 hours. Blocked and resumed lines are queued as notifications for the game
  server. Staff can upgrade a structure by one level, paying the level's resources (to `SYS_CONSUMPTION`) and a
  player's coins in one transaction. Everything runs only with `Production:Enabled` on; the CRUD works while it is
  off. Also #819: the ItemBlueprint form gets "Storage weight" and a storage's page lists its stock by blueprint name.
  knk-web-api: entities `ProductionKind`, `ProductionKindLevel`, `ProductionLine`, `ProductionModifier`,
  `ClimateZone`, `WeatherType`, `WeatherRoll`, `ProductionCycleRecord` (and their child rows); endpoints
  `api/ProductionKinds`, `api/ProductionKindLevels` (edit only), `api/ProductionLines` (+ `{id}/settle`),
  `api/ProductionModifiers`, `api/ClimateZones` (+ `rolls/search`), `api/WeatherTypes`, `api/ProductionCycleRecords`
  (read only), `POST api/Production/run-now`, and on `api/ProductionStructures` `GET {id}/production` (the production
  view with "why not producing"), `PUT {id}/workers` and `POST {id}/upgrade`; the `ProductionStructure.ProductionKindId`
  foreign key; game settings `production.engine` (`baseCycleMinutes` 10, `catchUpCapHours` 24, `weatherDayMinutes`
  20); form and display seeds for the six major entities, `ProductionStructure` v2 (kind picker), `ItemBlueprint` v2
  (storage weight) and the `Storage` display v2. Writes need `knk.admin.world` (delete also `knk.admin.delete`, the
  upgrade also `knk.economy.admin`); reads the World area node or the plugin key. Smoke test:
  [production smoke test § 4](guides/production-storage-transport-smoke-test.md#4-phase-p3-production-engine-86-api-678-web-app-tier3).
  Admin steps:
  1. Apply the migration `AddProductionEngine` (`dotnet ef database update`; additive: thirteen tables, the seeded
     catalogue, one default climate zone and three weather types, and the foreign key from
     `production_structures.ProductionKindId` to the kinds). Before it, check that no production structure has a kind id
     outside 1-8 (`SELECT Id FROM production_structures WHERE ProductionKindId NOT BETWEEN 1 AND 8;` returns nothing);
     otherwise clear it, or the foreign key can't be added.
  2. Import the form and display seeds `ProductionKind`, `ProductionKindLevel`, `ProductionLine`,
     `ProductionModifier`, `ClimateZone` and `WeatherType`, and make the new versions of `ProductionStructure` (form and
     display), `ItemBlueprint` (form) and `Storage` (display) the default.
  3. No `api.env` key and no plugin `config.yml` change. The engine timing is a game setting (`production.engine`,
     defaults above).

- **Production engine in the web app: kind, level and line editors, weather, the production view and the cycle trace** ([PandiO/knk-workspace#678](https://github.com/PandiO/knk-workspace/issues/678),
  link L10 of the production, storage and transport chain; [production design](specs/production-storage-transport/DESIGN.md)
  § 9, § 11.1, [production kinds](specs/production-storage-transport/PRODUCTION_KINDS.md) § 4-5). Staff can now run
  the production engine from the web app. The dashboard lists production kinds, levels, lines, modifiers, climate zones
  and weather types; each is created and edited with its seeded form. A kind's page lists its ten levels (yield,
  cycle speed, area and output caps, upgrade coins, upgrade cost and unlocks); a level's page edits its **unlocks and
  upgrade cost**; a line's page shows its state and accrual, edits its **inputs** per hour, settles it now and lists its
  latest cycles; a climate zone's page edits its **weather odds** (at most 100% together, the rest clear) and its
  **towns**, and lists the stored daily rolls; a weather type's page edits its **effects** per resource category. A
  production structure's page gets a **Production** panel: why it isn't producing (production off, no kind, no output
  storage, a full output storage, missing inputs), each line's rate step by step (base rate, each modifier in the order
  applied, the unlock and the workers present), the **workers** present, the **upgrade** to the next level with its
  coins and resources shown before paying (`knk.economy.admin`), and the latest cycles, each with its **trace**. The game
  settings page gets a **Production engine** card (base cycle, catch-up cap, weather day) and **Run production now**;
  a save of the game settings now keeps `production.engine` (before, the web app's save dropped it and the API reset
  it to the defaults). knk-web-app: one client per resource, `StructureProductionPanel`, `ProductionKindLevelsPanel`,
  `ProductionKindLevelItemsPanel`, `ProductionLinePanel`, `ClimateZonePanel`, `WeatherTypeEffectsPanel`,
  `ProductionCycleTable`, `ProductionEngineSettingsCard`, `src/utils/productionEngine.ts`;
  `e2e/production-engine.spec.ts`. Smoke test:
  [production smoke test § 4.2](guides/production-storage-transport-smoke-test.md#42-steps-web-app-678). Admin steps:
  1. Deploy the web app with the production engine API (#86, in `next`) and its imported form and display seeds
     (`ProductionKind`, `ProductionKindLevel`, `ProductionLine`, `ProductionModifier`, `ClimateZone`, `WeatherType`,
     `ProductionStructure` v2). No migration, setting or plugin change.

- **World web app: warehouses, production structures and rural placement** ([PandiO/knk-workspace#676](https://github.com/PandiO/knk-workspace/issues/676),
  link L7 of the production, storage and transport chain, [production design](specs/production-storage-transport/DESIGN.md)
  § 3.3-3.4, § 11.1). Staff can now create warehouses and production structures in the web app with the seeded forms:
  in a district (district, street, house number) or rural (only the town, picked from the list), with the region drawn
  in game through Send to Minecraft. A save that breaks a placement rule set to warn still saves and shows the warning
  (for example P-2, outside the town's territory) until it is closed; a refused save shows the API's reason (both a
  district and a town, a blocking rule). The dashboard lists both types with their town, placement (District or Rural)
  and territory flag, production structures also with level, production on or off and their road connection; the
  structure, warehouse and production structure lists have a **Territory flag** filter that shows the structures the
  territory report flagged (contested, outside their town's territory). A warehouse's or production structure's page
  shows where it stands and its town, the production structure's warnings (contested land, outside its territory, not
  connected to its town's roads), its road connection, workers and delivery preference, the territory flag and
  loyalty, and every storage it holds with its stock (adjust and move with `knk.economy.admin`). The form builder's rule
  editor offers the validation type **Inside Territory**, a warning by default. knk-web-app: `warehouseClient`,
  `productionStructureClient`, `StructurePlacementPanel`, `StructureStoragesPanel`, `TerritoryFlagFilterSelect`,
  `src/utils/productionWorld.ts`; `e2e/production-world.spec.ts`. Smoke test:
  [production smoke test § 3.2](guides/production-storage-transport-smoke-test.md#32-steps-web-app-676). Admin steps:
  1. Deploy the web app with the world API (#91, in `next`) and its imported `Warehouse` and `ProductionStructure`
     form and display seeds. No migration, setting or plugin change.

- **World plugin: production region kinds, rural structure regions and the territory lookup** ([PandiO/knk-workspace#677](https://github.com/PandiO/knk-workspace/issues/677),
  link L8 of the production, storage and transport chain, [production design](specs/production-storage-transport/DESIGN.md)
  § 3.4). With the plugin switch `production.enabled` on, the managed-region repair (and a freshly finished region)
  gives a production structure's region the kind `RESOURCE_PRODUCTION` and a warehouse's the kind `STRUCTURE`. A rural
  structure (a town, no district) gets a region with no parent at its kind's floor priority (30), so no town flags are
  inherited and PvP stays allowed around it; the repair no longer warns about its missing district. The game server now
  answers the territory lookup the API's placement rule P-2 (`InsideTerritory`) asks, so a rural structure outside its
  town's territory gets a real warning instead of "not checked": `GET /api/territory/contains-region/{regionId}` (every
  block column of the region and its sub-regions owned by the holder; contested land counts as not owned) and `GET
  /api/territory/contains-location`, both with `holderKind`/`holderId`, on the region HTTP server behind the plugin key;
  HTTP 503 while `production.enabled` is off or the territory cache is not built yet, which the API shows as "not
  checked". The territory report now flags rural structures too (it reads each structure's town from the structure
  search). A structure moved from a district to rural keeps its old WorldGuard parent until staff remove it
  (`/rg setparent <region>`): the repair never clears a parent. With the switch off nothing changes. knk-plugin:
  `ManagedRegionKind.fromDomainType(type, production)`, `DomainRegionSpecs` rural rule, knk-core `TerritoryLookup`,
  knk-paper `TerritoryLookupHandler` and `RegionUnionOutlines`, `StructureListDto.townId`; plugin scenario
  `rural-structure-region`. Smoke test:
  [production smoke test § 3.3](guides/production-storage-transport-smoke-test.md#33-steps-plugin-677). Admin steps:
  1. No new `config.yml` key: the existing `production.enabled` switches it (plugin configuration § 4.31).
  2. For the lookup the API needs to reach the plugin's region HTTP server, as for region checks today
     (`MinecraftPlugin:BaseUrl`, the shared plugin key).
  3. After turning `production.enabled` on, run `/knk regions repair` once (or restart) so existing production
     structures and rural structures get their kind.

- **World API: rural structures, warehouses and production structures** ([PandiO/knk-workspace#91](https://github.com/PandiO/knk-workspace/issues/91),
  link L6 of the production, storage and transport chain, [production design](specs/production-storage-transport/DESIGN.md)
  § 3.3-3.4). A structure can now stand in a district (as before) or be **rural**: it belongs to a town by its
  `townId`, with no district and no street, as most farms, quarries and mines will. Exactly one of district and town is
  set (refused otherwise, also by the database); its effective town is the district's town or its own. Two new
  structure types: **warehouses** (take deliveries, priority, a delivery storage created with them) and **production
  structures** (level 1-10, production on/off, transport settings, preferred warehouse, road connection, workers; an
  output storage created with them; the production kind and production itself come with P3). The placement rules of
  the design are seeded on both forms as **warnings** an admin can switch to blocking: P-1, the region lies inside the
  district's region, and P-2, a rural structure lies inside its town's territory (new validation type
  `InsideTerritory`, a lookup on the game server, answered once the plugin link #677 is deployed; until then it says
  "not checked"). The same rules now run when the API saves a structure, so a blocking rule refuses the save there too;
  a rule that can't be checked never blocks. A rural structure on contested land keeps its town, keeps producing and
  shows a warning. With `production.enabled` off the territory rule is skipped; warehouses and production structures can
  still be created, edited and deleted. Rural structure regions have no parent (PvP stays allowed). knk-web-api:
  `Structure.TownId` (and nullable `DistrictId`/`StreetId`), entities `Warehouse` and `ProductionStructure`; endpoints
  `api/Warehouses` and `api/ProductionStructures` (CRUD, search, `PUT {id}/road-connection`); `api/Structures` accepts
  `townId` and lists `townId`, `isRural` and `territoryFlag`; form and display seeds `Warehouse` and
  `ProductionStructure`. Writes need `knk.admin.world` (delete also `knk.admin.delete`); reads the World area node or
  the plugin key. Smoke test:
  [production smoke test § 3](guides/production-storage-transport-smoke-test.md#3-phase-p2-world-rural-structures-warehouse-production-structure-91-api-676-web-app-677-plugin-tier3).
  Admin steps:
  1. Apply the migration `AddProductionWorld` (`dotnet ef database update`; additive: two nullable columns widened, a
     nullable `TownId`, a check constraint, two tables; existing structures keep their district and street).
  2. Import the form seeds `Warehouse` and `ProductionStructure` and their display seeds ("make default").
  3. No `api.env` key and no plugin `config.yml` change.

- **Stock core API: storages, the stock ledger and capacity** ([PandiO/knk-workspace#97](https://github.com/PandiO/knk-workspace/issues/97),
  link L4 of the production, storage and transport chain, [production design](specs/production-storage-transport/DESIGN.md)
  § 4). Staff can now create storages for a structure, town or district, a player, a clan or a transport's cargo, and
  every change of stock is a double-entry move in a ledger: stock never appears or vanishes, it moves from one storage
  to another, with five system storages (`SYS_PRODUCTION`, `SYS_CONSUMPTION`, `SYS_LOSS`, `SYS_ADJUSTMENT`,
  `SYS_WORLD`) as the other side of goods entering or leaving. Stackable items are counted per blueprint; unique items
  (an enchanted sword) keep their identity. A storage can cap raw units (amount × each item's new storage weight,
  default 1) and distinct items; a move over the cap, without enough stock or into a locked storage is refused or, in
  partial mode, moves what fits and reports the rest, never as an error. A repeated request with the same
  idempotency key applies once; concurrent moves never lose an update (row locks in id order, tested on MySQL with
  1000 parallel moves). Corrections are new compensating transactions, never edits. A reconciler checks that every
  blueprint sums to zero and every line equals its moves; `Production` moves older than 30 days are rolled up per line
  per day with totals unchanged (G3). The scheduled reconciler and roll-up run only with `production.enabled` on;
  storage pages, moves, adjustments and corrections by hand work while it is off. Nothing in game changes yet: the web
  app screens are the next link (#675). knk-web-api: entities `Storage`, `StockLine`, `StockUnit`,
  `StockTransaction`, `StockMove`, `StockMoveRollup`, `ItemBlueprint.StorageWeight`; `IStockService`
  (`Move`/`MoveMany`/`Adjust`/`Reverse`), `StockReconciler`, `StockRollupService`, `StockMaintenanceService`;
  endpoints `api/Storages` (CRUD, search) and `api/StockTransactions` (search, `{id}`, `moves/search`,
  `rollups/search`, `reconcile`; move, `adjust`, `{id}/reverse`, `rollup`); form and display seeds `Storage` and
  `StockTransaction`. Storage writes need `knk.admin.world` (create and edit also `knk.admin.content`, delete
  `knk.admin.delete`); ledger reads the World area node or `knk.economy.admin`; moving stock the new node
  `knk.economy.admin` (not under `knk.admin`, so only `*` or an explicit grant). Smoke test:
  [production smoke test § 2](guides/production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3).
  Admin steps:
  1. Apply the migration `AddStockCore` (`dotnet ef database update`; additive: six tables, `item_blueprints.StorageWeight`
     default 1, the five system storages).
  2. Import the form seeds `Storage` and `StockTransaction` and their display seeds ("make default").
  3. Grant `knk.economy.admin` to the staff who may move or adjust stock (nobody has it by default except `*`).
  4. No `api.env` key and no plugin `config.yml` change; keep the game setting `production.enabled` as it is.

- **Stock in the web app: storage pages, the adjust and move dialogs and the ledger explorer** ([PandiO/knk-workspace#675](https://github.com/PandiO/knk-workspace/issues/675),
  link L5 of the production, storage and transport chain, [production design](specs/production-storage-transport/DESIGN.md)
  § 4 and § 11.1). Staff now work with the stock core in the web app instead of a REST client: storages have a
  dashboard table (kind, holder, fill against the cap, lock) and the seeded form; a storage's page shows its capacity
  in raw units × storage weight against the cap (and when it is over its cap), its lock, its stock lines and its unique
  items; each line's amount opens the moves that made it in the new **Stock ledger** (Admin → Economy,
  `/admin/stock/ledger`), which lists transactions, moves and the 30-day roll-ups with filters for storage, blueprint,
  unique item, reason, actor, reference and dates, and puts the line's amount next to the net of its moves (A01, A22).
  The **Adjust stock** dialog (note required) and the **Move stock** dialog (several lines, a reason, all or nothing or
  partial) show the result per line: what moved and, for the rest, why (capacity full, distinct cap, not enough stock,
  locked, another line refused); a retry after a lost answer sends the same idempotency key, so it applies once. A
  ledger transaction's page lists its moves and writes a compensating correction with **Reverse**. The ledger page's
  health card runs the reconciler and the roll-up by hand (the stock part of #65). The blueprint list shows each
  blueprint's storage weight. knk-web-app: clients and types for `api/Storages` and `api/StockTransactions`, dashboard
  columns, `StoragePanel`, `StockTransactionPanel`, the two dialogs, `StockLedgerPage`, Playwright `e2e/stock.spec.ts`.
  Adjusting, moving, reversing and rolling up need `knk.economy.admin` (shown off with "Requires knk.economy.admin"
  without it); the ledger reads need `knk.admin.world` or `knk.economy.admin`. Smoke test
  [§ 2.2](guides/production-storage-transport-smoke-test.md#22-steps-web-app-675). No migration, no setting, no plugin
  change. Admin steps:
  1. Deploy the web app with (or after) the stock core API (#97) and import its form and display seeds (see that
     entry).
  2. Grant `knk.economy.admin` to the staff who adjust or move stock; staff with `knk.admin.world` only can read the
     ledger.
  3. A blueprint's storage weight is set through the API for now: the seeded ItemBlueprint form has no Storage weight
     field yet (seed follow-up on #675).

- **Navigation: where a route's road part ends** ([PandiO/knk-workspace#780](https://github.com/PandiO/knk-workspace/issues/780)
  option (b), [#771](https://github.com/PandiO/knk-workspace/issues/771) items 3 to 5, fix link F2 of the off-road
  navigation chain). Three plugin switches, all off by default, so routes, trails and sessions stay exactly as before:
  `navigation.road-goal-reachable` chooses a point destination's road goal by walk reachability (the road point from
  which the destination is reached on foot within the walk limits, with the least road plus walk length) instead of the
  straight-line nearest road point; this makes "Keep storage hall" reachable over the road with the shipped settings
  and removes scene 2's road overshoot. `navigation.road-to-its-end` keeps a road route to its end when the road network
  is swapped near the destination, instead of a walk leg from partway along the road. `navigation.trail-leg-spacing`
  now also spaces the walk trail with `guidance-v2` off (default 3.0, today's). NPC road plans are not affected.
  knk-plugin: knk-core `RoadGoalChoice`; knk-paper `NavigationService`, `NavigationConfig`, `TrailRenderer`. Smoke test:
  [off-road smoke test § 13](guides/navigation-offroad-smoke-test.md#13-f2-road-goal-and-route-ends-780-771-items-3-to-5-tier2).
  Admin steps:
  1. Merge into the plugin `config.yml` under `navigation:` (the switches off = no change), restart:
     ```yaml
     road-goal-reachable: false
     road-goal-candidates: 12
     road-to-its-end: false
     ```
  2. Optional, for the live test: `road-goal-reachable: true`, `road-to-its-end: true`, and a denser walk trail with
     `trail-leg-spacing: 1.5` to `2.0` (the developer's choice; the default stays 3.0). Never raise
     `max-snap-distance` for it.

- **Territory in game: who holds the land where you stand** ([PandiO/knk-workspace#689](https://github.com/PandiO/knk-workspace/issues/689),
  link L2 of the production, storage and transport chain, [territory design](specs/territory/DESIGN.md) § 1-4). With
  the new plugin switch `production.enabled` on, the game server works out each town's and kingdom's territory from the
  API's districts, crown land and ranges, measured from the nearest edge of each region, and keeps it per chunk; where a
  border runs through a chunk it is kept per block column, so borders can run diagonally. Players see an action bar line
  when they enter a town's territory, crown land or contested land, or leave into the wilderness. When two towns'
  territories overlap the server reports it to the API, which records the conflict and flags the structures standing
  there; staff check any spot with `/knk territory here`. Crown land regions get their own managed-region kind (top
  level, priority 10). With the switch off (the default) nothing of this runs. knk-plugin: knk-core `core/territory/`
  (chunk cache, rules, report, outlines, player tracker, `TerritoryService`), knk-api-client `TerritoryApiImpl`
  (`GET api/Territory/inputs`, `PUT api/Territory/report`), knk-paper `territory/` (listener,
  `PlayerTerritoryChangeEvent`, realtime `TerritoryChanged`), `/knk territory here|status|rebuild` (node
  `knk.admin.world.territory`), managed-region kind `CROWN_LAND`, plugin scenario `territory-border-crossing`. Map
  outlines are built and can be sent over the game hub, but the API and the map do not take them yet
  ([#802](https://github.com/PandiO/knk-workspace/issues/802)). Merged into `next` 2026-11-19 (knk-plugin `55804b11`,
  PandiO/knk-plugin#91; knk-workspace PR #804). Guides: [territory admin guide](guides/admin/territory-admin-guide.md),
  [player guide](guides/users/territory-player-guide.md), [architecture](architecture/territory.md). Admin steps:
  1. Merge into the plugin `config.yml` (the switch off = no change), restart:
     ```yaml
     production:
       enabled: false
       territory:
         refresh-minutes: 10
         notify-players: true
         report: true
         map-outlines: false
         max-chunks-per-world: 500000
         messages:
           enter-town: "&7Entering the territory of &f{name}"
           enter-crown-land: "&7Entering the crown land of &f{name}"
           enter-contested: "&6Entering contested land: &f{holders}"
           enter-wilderness: "&7Leaving &f{name}&7: wilderness"
     ```
  2. To test: `production.enabled: true` in the plugin and the API's game setting `production.enabled` on, then smoke
     test § 1.3; grant staff `knk.admin.world.territory` (included in `knk.admin.*`). Keep `map-outlines: false`
     until #802.
- **Territory in the web app: kingdoms, provinces, crown land, town power, contested zones and structure loyalty** ([PandiO/knk-workspace#690](https://github.com/PandiO/knk-workspace/issues/690),
  link L3 of the production, storage and transport chain, [territory design](specs/territory/DESIGN.md)). Staff can now
  do the territory set-up in the web app instead of with a REST client: kingdoms, provinces and crown land have
  dashboard tables and forms (crown land's region is drawn in game with Send to Minecraft, like a district's, G10); a
  town's page has a Territory panel with its power, kingdom, province and effective ranges, where staff set those and
  mark capital districts (G11); a conflict's page shows the two holders, the contested area and the structures standing
  in it, and staff award the area to one holder, mark the lines redrawn or reopen it (A05); a structure's page shows its
  territory flag and its conflict and sets its loyalty (A07); Game settings has a "Production and territory" card with
  the production switch and the range settings, with a worked example. knk-web-app: clients and types for
  `api/Kingdoms`, `api/Provinces`, `api/CrownLands`, `api/TerritoryConflicts`, `api/Territory`; dashboard columns; the
  three page panels and the settings card; Playwright `e2e/territory.spec.ts`. Every change needs `knk.admin.world`.
  Merged into `next` 2026-11-19 (knk-web-app `89751315`, PandiO/knk-web-app#57; knk-workspace PR #803). Smoke test
  [§ 1.4](guides/production-storage-transport-smoke-test.md#14-steps-web-app-690). No migration, no setting, no plugin
  change. Admin steps:
  1. Deploy the web app with (or after) the territory API (#326) and import its form and display seeds (see that
     entry).
  2. Set power, kingdom, province and capital districts on each town's page (Territory panel); the seeded Town and
     District forms do not have those fields yet (seed follow-up on #690).

- **Siege weapons: weapon spots are created in the web form with a world task, from a WorldEdit selection or WorldGuard region** ([PandiO/knk-workspace#783](https://github.com/PandiO/knk-workspace/issues/783)
  and [#799](https://github.com/PandiO/knk-workspace/issues/799), links L2 and L2b of the siege weapons chain, phase 2
  of [#354](https://github.com/PandiO/knk-workspace/issues/354)). In the scenario's "Siege weapons" step an admin creates
  a spot, picks its team and name, and clicks "Send to Minecraft" on the spot form's Min X field; in game they claim
  the task with `/knk task <code>`, select the spot with WorldEdit (`save`) or name a WorldGuard region
  (`region <id>`); the facing is pre-filled from where the admin looks (rounded to north, east, south or west) and can
  be changed (`facing <direction>`); the size class is worked out as width across × length along the facing × height
  (the largest class that fits) and again when the facing changes; a selection smaller than the small class
  (7 × 9 × 5) is refused; a floor that isn't solid or a volume that isn't clear is a warning; `confirm` completes the
  task, and the web form fills its six bounds, facing, size class and region and shows the warnings; the form's Submit
  saves the spot. knk-plugin: world task handler `SiegeWeaponSpot` (only with `siege.weapons.enabled`), rules in
  knk-core `core/siege/weapons/`; L2's in-game `/knk weaponspot` command is removed by #799, so there is one way to
  create a spot. knk-web-app: the spot form's fan-out of the task result. knk-web-api: the `SiegeWeaponSpot` form seed
  starts the task from Min X; with all six bounds the API works the size class out from bounds and facing on save and
  refuses bounds smaller than the small class; no migration, no new endpoint. Branches `claude/siege-weapons-l2`
  (in `next`) and `claude/siege-weapons-l2b` in knk-plugin, knk-web-api, knk-web-app and knk-workspace (PRs into
  `next`). Admin steps:
  1. Add the new block to the plugin's `config.yml` under the existing `siege:` section (off by default; the plugin
     never adds keys to an existing file):

     ```yaml
     siege:
       weapons:
         enabled: false
     ```

  2. To create spots, set `siege.weapons.enabled: true` on a test server and restart; the admin needs
     `knk.siege.admin.manage` in the web app.
  3. Import the `SiegeWeaponSpot` form seed; a database that imported it before #799 gets the task by turning on
     "Requires in-game action" on Min X with type `SiegeWeaponSpot` in the form designer (import never overwrites).

- **Territory API: kingdoms, provinces, crown land, town power and contested zones** ([PandiO/knk-workspace#326](https://github.com/PandiO/knk-workspace/issues/326),
  link L1 of the production, storage and transport chain, [territory design](specs/territory/DESIGN.md)). Staff can now
  set up who holds land: kingdoms, optional provinces (a town's province must be in its kingdom), crown land (a
  kingdom-held region with a range, drawn like a district, G10), each town's power and which districts are capitals.
  The API works out every district's range, base range + power × factor, multiplied for a capital (G11), and hands the
  game server everything its territory map needs in one read; when the game server reports that two towns' territories
  overlap, the API records a conflict and flags the structures standing there, and staff resolve it by awarding the
  area to one town or redrawing the lines. Structures can also be given a loyalty (stored only for now). Nothing in game
  changes yet: the game server side (#689) and the web pages (#690) are the next links. knk-web-api: entities
  `Kingdom`, `Province`, `CrownLand`, `TerritoryConflict`; `Town.Power`/`KingdomId`/`ProvinceId`,
  `District.IsCapital`, `Structure.LoyaltyTownId` and territory flag; the game setting section `production`
  (`Production:Enabled`, default off, and the territory ranges); endpoints `api/Kingdoms`, `api/Provinces`,
  `api/CrownLands`, `api/TerritoryConflicts` (with `resolve` and `reopen`), `api/Territory` (`inputs`, `report`,
  `towns/{id}`, `structures/{id}` with `loyalty` and `flag`); realtime event `TerritoryChanged`; form and display seeds
  for the four new entities. Writes need `knk.admin.world` (create and edit also `knk.admin.content`, deletes
  `knk.admin.delete`); the report is the game server's only. Merged into `next` 2026-11-19 (knk-web-api `0d6e369a`,
  PandiO/knk-web-api#53; knk-workspace PR #798); API contract in the [territory architecture](architecture/territory.md#4-api-contract). Admin steps:
  1. Apply the migration `AddTerritory` (`dotnet ef database update`; additive: four tables, defaulted columns).
  2. Import the form seeds `Kingdom`, `Province`, `CrownLand`, `TerritoryConflict` and their display seeds ("make
     default").
  3. Leave `production.enabled` off until the plugin link (#689) is deployed; set the ranges under
     `production.territory` in the game settings (defaults: base 100, factor 2, capital × 1.5).

- **Siege weapons: templates, ammo types, weapon spots and unlocks can be set up in the web app** ([PandiO/knk-workspace#782](https://github.com/PandiO/knk-workspace/issues/782),
  link L1 of the siege weapons chain, phase 1 of [#354](https://github.com/PandiO/knk-workspace/issues/354)). Staff
  can now describe trebuchets, catapults and ballistas, their ammunition and the places in a siege scenario where a
  team may put one; nothing changes in a match yet. knk-web-api: new entities `SiegeWeaponTemplate` (range, spread by
  ranging in, flight time, cone, gate and weapon damage multipliers, spot cooldown, match and unlock prices; schematic
  references stay nullable until #614), `SiegeAmmoType` (effect, player and structure damage, radius, knockback, armour
  piercing, effect area, price per shot; many-to-many with templates), `SiegeWeaponSpot` (owned by a scenario and one of
  its teams: bounds, facing, size class) and `UserSiegeWeaponUnlock` (one per player and type), plus
  `SiegeTeam.ActiveWeaponSpots` (0), `SiegeScenario.FriendlyFire` (off) and
  `SiegeScenario.WeaponSpotCooldownOverrideSeconds` (empty). Endpoints `api/SiegeWeaponTemplates`, `api/SiegeAmmoTypes`,
  `api/SiegeScenarios/{id}/weapon-spots` with `api/SiegeWeaponSpots/{id}`, and `api/UserSiegeWeaponUnlocks` (with
  `by-user/{userId}`); writes need `knk.siege.admin.manage` (or the plugin key), create and edit also
  `knk.admin.content`, deletes `knk.admin.delete`. knk-web-app: clients, dashboard columns and form wizard support.
  Branches `claude/siege-weapons-l1` in knk-web-api, knk-web-app and knk-workspace (PRs into `next`). No flag (data
  only). Admin steps:
  1. Apply the migration `AddSiegeWeapons` (`dotnet ef database update`; additive: five tables, three defaulted
     columns).
  2. Import the form seeds `SiegeAmmoType`, `SiegeWeaponTemplateAmmoType.join`, `SiegeWeaponTemplate`,
     `SiegeWeaponSpot`, `UserSiegeWeaponUnlock` (in that order, "make default").
  3. On a database that imported `SiegeScenario` and `SiegeTeam` before, add the scenario's "Siege weapons" step and
     the team's "Active weapon spots" field in the form designer (the seed files have them; import never overwrites).

- **Item identity: every item a player obtains is a blueprint item** ([PandiO/knk-workspace#141](https://github.com/PandiO/knk-workspace/issues/141),
  link L0 of the production, storage and transport chain). Every item you pick up, mine, loot, fish, craft or trade
  for now has a known item type on the server, while it looks and stacks exactly as before. knk-web-api, knk-plugin and
  knk-workspace branches `claude/item-identity-141`, merged into `next` 2026-11-19 (knk-web-api `7d213fd6`, knk-plugin
  `2ef256e7`, knk-workspace `ca3bcc98`). Guides: [admin](guides/admin/item-identity-admin-guide.md),
  [architecture](architecture/item-identity.md) (docs #796).
  1. API: `ItemBlueprint.VanillaMaterialMatchRefId`, unique, maps each obtainable vanilla material to one blueprint.
     Plain "vanilla shadow" blueprints in a new top-level "Uncurated" category are generated for materials nobody
     curated (D11/G4), after every catalogue scan and on `POST api/ItemIdentity/shadows/generate`. New
     `api/ItemIdentity`: `GET material-map` (any logged-in caller or the plugin key), `GET report` and
     `PUT matches/{materialRefId}` (`knk.admin.content`; the latter also the plugin key), `POST conversion-counts`
     (plugin key only). A catalogue merge keeps one match per material.
  2. Plugin: one resolver (instance tag → blueprint tag → vanilla match); `knightsandkings:knk_blueprint` stamped on
     blueprint items that differ from the plain vanilla item; the plain item never carries it (retag rule), so
     stacking is vanilla's. Conversion hooks on pickup, block and mob drops, fishing, crafting, trades and the first
     open of a container; counts logged and sent to the API. Everything behind `items.identity.enabled` and
     `items.identity.convert-on-obtain`, both off by default: with them off, items behave exactly as before.
  3. Admin steps: apply migration `AddItemIdentity` (additive: one nullable column with a unique index, one new table
     `item_conversion_stats`; no data written). Run a catalogue scan (or `POST api/ItemIdentity/shadows/generate`)
     to create the shadows. Merge into `config.yml`, then restart:
     ```yaml
     items:
       identity:
         enabled: false
         convert-on-obtain: false
         map-refresh-minutes: 10
         report-interval-minutes: 10
     ```
- **Navigation: walk trails reach the keep storage hall and pass roof hatches** ([PandiO/knk-workspace#771](https://github.com/PandiO/knk-workspace/issues/771)
  items 1 and 2, fix link F1 of the off-road navigation chain). A walking route that once found its way no longer
  loses it when the trail is recalculated inside a building: the recalculation keeps the area and length of the way
  already found. With the shipped settings the keep's storage hall is still not reached from spawn: the road ends on
  the stair house's lower landing, and the walk from there is too long (follow-up on #771). An open
  trapdoor over a ladder, such as the Garrison Watchtower Roof's hatch, is now climbed through up and down; a closed
  one is still never passed. Also for NPC walk legs. No flag, no config key, no migration. knk-plugin and
  knk-workspace branches `claude/offroad-walk-fixes-771` (PRs into `next`).
- **Off-road navigation: landmark preference weights** ([PandiO/knk-workspace#709](https://github.com/PandiO/knk-workspace/issues/709),
  link L9 of the off-road navigation chain, phase 5.2). Behind `navigation.landmarks` (off by default). A landmark
  with an area (a region or a radius) and a `Preference` above 1.0 makes walking routes avoid that area in the default
  `preferred` mode; below 1.0 they prefer it (preference indoors without an indoor road graph). `shortest` and
  `efficient` ignore the weights, NPCs never use them. Overlapping landmarks multiply, capped by the new
  `navigation.preference-max` (4.0). Landmarks standing on a road also become walk-link ends. knk-plugin and
  knk-workspace branches `claude/offroad-landmark-weights` (PRs into `next`). Admin steps: add
  `preference-max: 4.0` under `navigation:` in `config.yml`, restart. No migration.
- **Off-road navigation: route modes `shortest`, `efficient`, `preferred`** ([PandiO/knk-workspace#707](https://github.com/PandiO/knk-workspace/issues/707),
  link L7 of the off-road navigation chain, phase 4). `/navigate <place> [shortest|efficient|preferred] [spawn|region]`
  picks how the route is chosen, on roads and on foot: `shortest` the fewest blocks, `efficient` the cheapest road
  classes and walking (stairs, ladders, doors, water and drops cost extra), `preferred` also the road weights staff set
  with `/knk road edge set <id> cost <x>`. Without a word the route is `preferred`, exactly today's route. knk-plugin
  and knk-workspace branches `claude/offroad-route-modes` (PRs into `next`). No flag, no config key, no migration.
  1. Each typed word needs its node `knk.navigate.mode.<word>` (declared `default: op`); no word needs none. Tab
     completion offers only the words a player holds.
  2. The mode works with the destination engine on and off, and stays for the navigation's re-routes; walk links cost
     their walked length in `shortest`. NPC routes are unchanged.
  3. Admin steps: grant the three nodes to the groups that should have them (none by default; staff proposed).

- **Off-road navigation: shortcuts on foot in the middle of a route** ([PandiO/knk-workspace#705](https://github.com/PandiO/knk-workspace/issues/705),
  link L5 of the off-road navigation chain, phase 2). Where the road goes the long way round (a courtyard, a bailey), the
  route can now leave the road for a short walk across and join it again: the trail shows the walk in the walk colour
  and the HUD says "Leave the road and walk across". A target close enough for one walk path is reached over the road
  when the road carries most of the way. knk-plugin and knk-workspace branches `claude/offroad-walk-links` (PRs into
  `next`). Behind `navigation.walk-links`, off by default: with it off, routes, trails and sessions are exactly as
  before. No migration.
  1. A route is a list of legs: road stretches and walk links in any order, with the walk to the road and the last
     walk as before (`Route.legs()`). Walk links have their own id space (`WalkLinkId`, at least 2^62).
  2. Links join road nodes at most `walk-link-range` (40) blocks apart whose road is more than `walk-link-ratio` (2.0)
     times as long. They are searched lazily, off the main thread, after the first route, and cached per player; the
     session then takes the better route ("A shorter route opened").
  3. A link is offered only when the player's gate and region rules let them through; a new block-change hook drops
     a link within a second of a change near it, with a TTL as the backstop.
  4. Road-first (direct mode within `max-snap-distance`, which is unchanged): `road-first-share` 0.6 and
     `road-first-max-ratio` 1.5, defaults for the developer to confirm.
  5. `/knk road status` shows three walk-link lines (searches, cache, road-first decisions).
  6. Admin steps (only to try it): under `navigation:` add the keys of the PR's admin steps and set `walk-links: true`;
     restart.

- **Off-road navigation: the trail rounds plazas** ([PandiO/knk-workspace#712](https://github.com/PandiO/knk-workspace/issues/712),
  link L10 of the off-road navigation chain, phase 7 step 2). Where your route crosses a plaza from one road to
  another, the navigation trail now takes a rounded line across the square instead of a sharp corner at its middle,
  keeping clear of walls, wells and stalls. knk-plugin and knk-workspace branches `claude/offroad-plaza-lines` (PRs into
  `next`). Behind `navigation.plaza-lines`, off by default: with it off the trail is exactly as before. No migration.
  1. With the flag on, the road trail's spots inside a plaza crossing are drawn at the same share of the way along
     the plaza line (`core/navigation/PlazaTrail`, a `TrailRenderer.drawRoute` overload). The crossings are worked out
     lazily on the main thread, one per redraw, when the trail comes within 24 blocks, once per route.
  2. The route, its length, the ETA, the HUD, the maneuvers and the session's progress and cursor stay on the route
     polyline (A25, transcript test).
  3. The developer's decision after viewing the lines on Cinix and Brink (O33): a curve is taken down to 0.65 from an
     obstacle (`plaza-curve-clearance`); the A* line still never comes under 0.35.
  4. `/knk road status` shows "plaza lines: on; placed N of M crossings".
  5. Admin steps (only to try it): under `navigation:` add `plaza-curve-clearance: 0.65` beside the step-1 keys and set
     `plaza-lines: true`; restart.

- **Off-road navigation, phase 5.1 step B: landmarks in game** ([PandiO/knk-workspace#708](https://github.com/PandiO/knk-workspace/issues/708),
  link L8 of the off-road navigation chain). knk-plugin and knk-workspace branches `claude/offroad-landmarks` (PRs into
  `next`). Behind the new `config.yml` key `navigation.landmarks` (off by default: nothing changes for players).
  1. With the key on (and `navigation.destination-engine` on), players can `/navigate` to a landmark by name or as
     `landmark:<name>`; tab completion offers the landmarks of their world they may navigate to, not those with
     "Offer in /navigate" off, not other worlds' and none during a siege match. A landmark with a region ends the
     navigation inside the region, one with a radius inside that radius, one without either within the arrive distance.
     A navigation to a landmark that is deleted or switched off ends with the "no longer" message; a rename keeps it.
  2. Staff with `knk.admin.world.landmark` use `/knk landmark create <name> [region <id> | radius <n>]`, `list`, `show`,
     `move`, `delete`, `link <landmark> <domain>` and `unlink` in game.
  3. The navigation model keeps the landmarks in its snapshot (`offline/navigation-model.json`), so they work with the
     API down after a restart; a failed landmark read keeps the last ones.
  4. Admin steps: add `landmarks: false` under `navigation:` in `config.yml` (a missing key means `false`; see
     [plugin configuration § 4.15](guides/admin/plugin-configuration.md#415-navigation)); restart after changing it.
     The API side (migration, node) is step A's entry below. Steps:
     [off-road smoke test § 6.3](guides/navigation-offroad-smoke-test.md#63-in-game-step-b-a12-to-a14).

- **Off-road navigation, phase 5.1 step A: landmarks in the API and the web app** ([PandiO/knk-workspace#708](https://github.com/PandiO/knk-workspace/issues/708),
  link L8 of the off-road navigation chain, [#698](https://github.com/PandiO/knk-workspace/issues/698)). knk-web-api,
  knk-web-app and knk-workspace branches `claude/offroad-landmarks` (PRs into `next`). Nothing changes for players
  yet: the game server reads landmarks from step B (knk-plugin, `navigation.landmarks`, off by default).
  1. A landmark is a named place made by staff: a Location pin with a name (unique per world), optionally linked to a
     domain (the link is dropped when the domain is deleted), optionally with an area (a WorldGuard region or a radius
     up to 512 blocks), a route preference (0.25 to 4.0, used from phase 5.2) and "Offer in /navigate".
  2. API `api/landmarks`: `GET ?world=` and `GET {id}` for anyone, also without login (the `map` rate limit);
     `POST search` for the dashboard; `POST`, `PUT {id}`, `DELETE {id}` for staff with the new node
     `knk.admin.world.landmark` (plus `knk.admin.content` for create and edit, `knk.admin.delete` for delete) or the
     game server's key.
  3. Web app: Landmark on the dashboard (World area) with World, Point, Domain, Area and In /navigate columns, the
     default form "Landmark - Default (seed v1)", and a Landmarks box on every domain's detail page listing the
     landmarks linked to it, with **Add landmark**.
  4. Admin steps: apply the migration `AddLandmarks` (one new table `landmarks`, no change to existing tables); import
     the form seed `Landmark` (form configurations → Import / seeds); grant `knk.admin.world.landmark` to the ranks
     that make landmarks (`knk.admin.*` and `knk.admin.world.*` include it, a bare `knk.admin.world` does not; see the
     [dashboard access admin guide § 2](guides/admin/dashboard-access-admin-guide.md#2-area-nodes-one-per-part-of-the-dashboard)).
     No new settings. Steps: [off-road smoke test § 6](guides/navigation-offroad-smoke-test.md#6-phase-51-landmark-entity-708-tier3).

- **Overview map: moderation from the map** ([PandiO/knk-workspace#743](https://github.com/PandiO/knk-workspace/issues/743),
  link L9 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-app and
  knk-workspace branches `claude/overview-map-moderation` (PRs into `next`). No flag of its own: it needs the live
  players layer (`Map:LivePlayers:Enabled`) and is shown by the viewer's nodes.
  1. A moderator holding any of `knk.freeze`, `knk.unfreeze`, `knk.kick`, `knk.ban` or `knk.admin.user.manage` who
     clicks a player on the map gets a "Moderation" section under the name card: Freeze or Unfreeze, Kick and Ban, each
     only with its own node, with the same dialogs, endpoints and audit entries as the player profile, and
     "Open profile". Without `knk.admin.user.manage` (the profile page's node) "Open profile" is greyed out with a
     tooltip that says why, instead of a link to a no-access page (fix link F2,
     [#809](https://github.com/PandiO/knk-workspace/issues/809), branches `claude/overview-map-f2-panel-fixes`).
  2. Everyone else still gets only the name card; anonymous viewers make no extra request.
  3. Admin steps: none. Steps:
     [overview map smoke test § 9](guides/overview-map-smoke-test.md#9-phase-7-player-moderation-panel-743-tier2).

- **Navigation destination engine, phase 4: the hard blocks are scopes and running routes are re-checked, behind the flag** ([PandiO/knk-workspace#62](https://github.com/PandiO/knk-workspace/issues/62),
  link L4 of the destination engine chain, [#25](https://github.com/PandiO/knk-workspace/issues/25)). knk-plugin and
  knk-workspace branches `claude/navigation-destination-engine` (PRs into `next`). Only with
  `navigation.destination-engine: true` (off by default: nothing changes for players).
  1. With the key on, "still loading", "frozen", "no permission" and "in a siege" come from the engine's list with
     today's texts; freeze also holds for owner mode, staff mode and `knk.navigate.any`. `knk.navigate.any` alone
     (without `knk.navigate`) is enough to use `/navigate`.
  2. A running route is checked against the player's list every 2 seconds and at once when an objective is captured,
     the match ends, the lobby changes, a round is released, owner/staff mode is switched, a freeze starts or ends, or
     the list of places is refreshed. A destination that left the list ends the route with the reason as the message,
     for example "You can't navigate while frozen." or "Keep Gate is no longer part of this match."; an objective that
     only changed from capture to defend keeps the route.
  3. Admin steps: none (no new key, no migration, no API change). Steps:
     [destination engine smoke test § 4](guides/navigation-destination-engine-smoke-test.md#4-phase-4-hard-blocks-as-scopes-and-live-re-validation-62-tier3).

- **Overview map: live players on the map** ([PandiO/knk-workspace#739](https://github.com/PandiO/knk-workspace/issues/739),
  link L5 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-app and
  knk-workspace branches `claude/overview-map-players-page` (PRs into `next`). Behind the API setting
  `Map:LivePlayers:Enabled` (off by default: the page asks for no players and draws nothing new).
  1. The map shows online players with a head and their name label as in the in-game chat line, in the same colours,
     updated about every 2 s. Tags show AFK, and for staff who may see hidden players also "Staff mode", "Owner mode"
     and the minigame.
  2. A running siege shows one pin, for example "[Siege] 12 players", instead of its participants.
  3. Clicking a player opens a name card with the label and tags.
  4. Admin steps: none to keep it off. With the backend on (§ 4), the layer appears by itself. Optional: player heads
     from a skin service through `heads=` in BlueMap's `webapp.conf`
     ([closed-alpha runbook Phase 10](guides/closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737)
     step 3); without it everyone has BlueMap's default head. Steps:
     [overview map smoke test § 5](guides/overview-map-smoke-test.md#5-phase-4b-live-players-layer-739-tier2).

- **Navigation destination engine, phase 3: `/navigate`, tab completion, the compass and the route start on the engine, behind a flag** ([PandiO/knk-workspace#69](https://github.com/PandiO/knk-workspace/issues/69),
  link L3 of the destination engine chain, [#25](https://github.com/PandiO/knk-workspace/issues/25)). knk-plugin and
  knk-workspace branches `claude/navigation-destination-engine` (PRs into `next`). Behind the new `config.yml` key
  `navigation.destination-engine` (off by default: nothing changes for players).
  1. With the key on, `/navigate`, its tab completion and the navigation compass use one list of places per player,
     built from the navigation model of phase 2 and the road network: the same names, forms and messages as today
     outside a siege, and in a siege match only the match's objectives and team spawn, now also as
     `objective:<name>` and `objective:#<id>`. Places of another world are not suggested but still get "… is in
     another world". Nothing is looked up when a destination is chosen, so it works with the API down after a
     restart; without any saved model only streets and road points are offered, with "Some places aren't available
     while the web API is down.".
  2. The compass cycles the same list (the match's in a match, the configured general targets outside a siege) and
     keeps its own wording; a resume picks the stored destination again only while it is still listed. Routes start
     only from the list. Owner mode, staff mode and the new node `knk.navigate.any` (not granted by default) list
     every place, also in a match.
  3. The road-access answers ("Ignored" domains whose roads stay usable) and the compass settings come from the
     navigation model with the key on.
  4. Admin steps: add `destination-engine: false` under `navigation:` in `config.yml` (a missing key means `false`;
     see [plugin configuration § 4.15](guides/admin/plugin-configuration.md#415-navigation)); restart after changing
     it. No migration, no API change. Grant `knk.navigate.any` only to accounts that should navigate anywhere. Steps:
     [destination engine smoke test § 3](guides/navigation-destination-engine-smoke-test.md#3-phase-3-switch-over-behind-the-flag-69-tier3).

- **Navigation destination engine, phase 2: the navigation model and its offline snapshot** ([PandiO/knk-workspace#103](https://github.com/PandiO/knk-workspace/issues/103),
  link L2 of the destination engine chain, [#25](https://github.com/PandiO/knk-workspace/issues/25)). knk-web-api,
  knk-plugin and knk-workspace branches `claude/navigation-destination-engine` (PRs into `next`). Nothing changes for
  players: nothing in the plugin reads the model before phase 3, which switches to it behind a flag.
  1. The domain search (`POST api/Domains/search`) returns each domain's Location (`location`: id, name, x, y, z, yaw,
     pitch, world; `null` when the domain has none). The other fields are unchanged; no migration.
  2. The game server keeps a navigation model: every domain with its spawn Location, region, world, `/navigate`
     default and road-access flag, the Location targets, the navigation compass settings and an empty landmarks
     section for off-road landmarks (#708). It is refreshed from the API every minute, saved to
     `plugins/KnightsAndKings/offline/navigation-model.json` when it changed, and loaded at start-up, so it survives a
     restart with the API down. With an API from before this change it looks the Locations up one domain at a time,
     two a second.
  3. Admin steps: deploy knk-web-api and the plugin together (either order works). New `config.yml` key
     `navigation.destinations.stale-after-days: 14` under `navigation:` (a missing key means 14; see
     [plugin configuration § 4.15](guides/admin/plugin-configuration.md#415-navigation)). No migration. Steps:
     [destination engine smoke test § 2](guides/navigation-destination-engine-smoke-test.md#2-phase-2-navigation-model-and-offline-snapshot-103-tier2).

- **Overview map: gate command buttons in the map panel** ([PandiO/knk-workspace#742](https://github.com/PandiO/knk-workspace/issues/742),
  link L8 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-app and
  knk-workspace branches `claude/overview-map-gate-buttons` (PRs into `next`). Behind the API setting
  `Map:GateCommands:Enabled` (phase 6a, off by default: no buttons, no requests).
  1. A web account holding `knk.gate.admin` sees "Gate commands" when clicking a gate on `/map`: Open, Close, Toggle
     and Repair for the whole gate and for each door. The door moves in game; the panel shows the result (done, refused
     with the reason, no game server, timed out) and then reads the gate again.
  2. During a siege match on the gate the buttons are disabled with "Gate is in a running siege".
  3. Everyone else sees the panel as before; anonymous viewers make no permission request, and nobody without the node
     asks for door ids or sends commands.
  4. Admin steps: none to keep it off. To turn it on, set `Map__GateCommands__Enabled=true` as in phase 6a and reload
     `/map`. No migration, no plugin setting. Steps:
     [overview map smoke test § 8](guides/overview-map-smoke-test.md#8-phase-6b-gate-command-buttons-742-tier2).

- **Overview map: gate commands backend** ([PandiO/knk-workspace#741](https://github.com/PandiO/knk-workspace/issues/741),
  link L7 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-api,
  knk-plugin and knk-workspace branches `claude/overview-map-gate-commands` (PRs into `next`). Behind the new API
  setting `Map:GateCommands:Enabled` (off by default: the route answers 404 and nothing is sent). Nothing changes for
  players yet: the map panel's gate buttons (phase 6b) call this.
  1. New staff route `POST api/GateStructures/{id}/commands` with `{action: open|close|toggle|repair, doorId?}`, for
     web staff holding `knk.gate.admin` only. The API sends the command to the game server over the game hub and waits
     up to 5 s for its answer; the game server runs the existing gate operations, so the door animates as with
     `/gate`, and repair works as `/gate repair`.
  2. Refused while a siege match runs on the gate (409; the game server checks its siege lockdown too), without a
     connected game server (503), for a door of another gate (400); no answer in time is 504. Every command is written
     to the audit log (`GateCommandSent`, with the user, action, door and result).
  3. `GET api/Map/config` now reports `gateCommands.enabled` from the setting.
  4. Admin steps: none to keep it off. To turn it on, set `Map__GateCommands__Enabled=true` in the API's environment
     file (`Map__GateCommands__TimeoutSeconds`, default 5). No plugin setting (the plugin answers what it receives,
     with `realtime.enabled: true`). No migration. Steps:
     [overview map smoke test § 7](guides/overview-map-smoke-test.md#7-phase-6a-gate-commands-backend-741-tier3),
     [production installation § 4.3](guides/production-installation.md#43-api-configuration-file--etcknkapienv).

- **Navigation destination engine, phase 1: the pure engine in knk-core** ([PandiO/knk-workspace#96](https://github.com/PandiO/knk-workspace/issues/96),
  link L1 of the destination engine chain, [#25](https://github.com/PandiO/knk-workspace/issues/25)). knk-plugin and
  knk-workspace branches `claude/navigation-destination-engine` (PRs into `next`). Nothing changes for players: the
  engine is code and tests only and nothing in the plugin uses it yet (phase 3 switches to it behind a flag).
  1. The engine decides which places a player may navigate to: exclusive scopes by priority (loading, frozen, staff
     bypass, no permission, siege match, siege lobby, world), providers of candidates, name resolution and completion
     inside the list, an engine-issued handle, and re-validation of a running session by key.
  2. Each refusal carries a reason code and today's `/navigate` text, so the compass can keep its own wording; places
     may carry an arrival radius, ready for the landmark provider of off-road navigation (#708).
  3. Admin steps: none (no flag, no `config.yml` key, no migration). Steps:
     [destination engine smoke test § 1](guides/navigation-destination-engine-smoke-test.md#1-phase-1-pure-engine-in-knk-core-96-tier2).

- **Overview map: staff details in the map panel** ([PandiO/knk-workspace#740](https://github.com/PandiO/knk-workspace/issues/740),
  link L6 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-app and
  knk-workspace branches `claude/overview-map-staff-details` (PRs into `next`). No flag: gated by the node
  `knk.admin.world`, and shown only where the map is on (`Map:Enabled`).
  1. World staff who click a town, district or structure on the map see a "Details" section under the public part:
     the type's default display configuration in a compact form (no header, lists collapsed with their count,
     related records as links, no buttons or inline edits), with "Open full page" to the record's detail page. A
     gate shows its gate display (`GateStructure`).
  2. Everyone else sees the panel as before; their browser asks for no display configuration.
  3. The detail pages elsewhere in the web app are unchanged (the compact form is a new option of the same
     renderer).
  4. Admin steps: none. Steps:
     [overview map smoke test § 6](guides/overview-map-smoke-test.md#6-phase-5-staff-details-740-tier2).

- **Overview map: live players backend** ([PandiO/knk-workspace#738](https://github.com/PandiO/knk-workspace/issues/738),
  link L4 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-plugin,
  knk-web-api and knk-workspace branches `claude/overview-map-players-api` (PRs into `next`). Behind the new API setting
  `Map:LivePlayers:Enabled` and the plugin's existing `map.reporting.enabled` (both off by default: nothing is sent,
  kept or served). Nothing changes for players yet: the map page's player layer (phase 4b) reads this.
  1. The plugin reports its online players every `map.reporting.interval-ticks` (new key, default 40 = 2 s): world,
     position, facing, AFK, active mode and running minigame match, over the game hub.
  2. New anonymous read route `GET api/Map/players` (map rate limit): the live players with their name label as in
     the in-game chat line, and one pin per running siege match, "[Siege] 12 players". Players in staff or owner mode
     or in a running match never reach anonymous or plain logged-in viewers, not even in the response; a viewer with
     `knk.mode.staff` or `knk.mode.owner` sees them with a mode or minigame tag. A player who quits disappears at once,
     a server that stops reporting within three intervals.
  3. Admin steps: none to keep it off. To turn it on, set `Map__LivePlayers__Enabled=true` (with `Map__Enabled=true`)
     in the API's environment file and `map.reporting.enabled: true` in the plugin's `config.yml` (needs
     `realtime.enabled: true`); `Map__LivePlayers__PollIntervalMs` (2000), `Map__LivePlayers__LabelCacheSeconds` (60)
     and `map.reporting.interval-ticks` (40) have defaults. No migration. Steps:
     [overview map smoke test § 4](guides/overview-map-smoke-test.md#4-phase-4a-live-players-backend-738-tier3),
     [production installation § 4.3](guides/production-installation.md#43-api-configuration-file--etcknkapienv),
     [plugin configuration § 4.29](guides/admin/plugin-configuration.md#429-map).

- **Overview map: the `/map` page** ([PandiO/knk-workspace#737](https://github.com/PandiO/knk-workspace/issues/737),
  link L3 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-app and
  knk-workspace branches `claude/overview-map-page` (PRs into `next`). Behind the API setting `Map:Enabled` (off by
  default): while it is off the web app shows no map anywhere.
  1. A public `/map` page with BlueMap's 3D viewer in a frame (served by our own Nginx under `/bluemap/`) and a bridge
     script inside it that draws our pins and outlines and reports clicks (versioned messages, own origin only).
     Opening `/bluemap` itself in the browser goes to `/map`, so the map always shows under the app's header.
  2. Town, district and structure pins with their names: towns at every zoom, districts and structures when zoomed in;
     structures also show their type ("Structure, Gate").
  3. Clicking a town flashes its outline three times and opens a panel with its public fields; "Show region" keeps the
     town and all its districts visible with their names. Districts and structures open their own panels; a gate lists
     its doors with open/closed, destroyed and a health bar, and "Under siege" during a match.
  4. The panel works on phones as a bottom sheet. A "Map" entry in the top bar (signed in) and a map link on the start
     page (signed out) appear only while the map is on. Escape closes the panel, also right after a click inside the
     map: the bridge reports the key with the new message type `escapePressed` (fix link F2,
     [#757](https://github.com/PandiO/knk-workspace/issues/757), branches `claude/overview-map-f2-panel-fixes`).
  5. Panels come from a map action registry, so later features (staff details, gate buttons, the player panel) add
     their widgets and actions without touching the map side.
  6. Admin steps: none to keep it off. To use it, move the existing BlueMap test container into the `knk-alpha` stack
     and serve `/bluemap/` ([closed-alpha runbook Phase 10](guides/closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737):
     BlueMap v5.29, `webapp.conf` `client-decompression: true` and the bridge script, the `web` image with the new
     `nginx.conf`), then set `Map__Enabled=true`. Steps:
     [overview map smoke test § 3](guides/overview-map-smoke-test.md#3-phase-3-map-page-737-tier2).

- **Overview map: public map API** ([PandiO/knk-workspace#736](https://github.com/PandiO/knk-workspace/issues/736),
  link L2 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-web-api and
  knk-workspace branches `claude/overview-map-public-api` (PRs into `next`). Behind the new API setting `Map:Enabled`
  (off by default: every `api/Map` route answers 404). Nothing changes for players yet: the web map page (phase 3)
  reads these.
  1. New anonymous read routes under `api/Map`: `config` (label distances, flash settings, marker version),
     `markers` (pins and outlines of every town, district and structure, labelled with their names; structures with
     type and subtype; a pin at the spawn location, else at the centre of the region outline), and the public panels
     `towns/{id}`, `districts/{id}`, `structures/{id}` (a gate adds its doors with open state, destroyed and health,
     and "under siege"). The responses hold only the fields the design allows for anyone (O32); tests pin each field
     set.
  2. A new per-IP rate limit `map` (120 requests per minute by default) covers every map route.
  3. Admin steps: none to keep it off. To turn it on, set `Map__Enabled=true` in the API's environment file; the other
     new keys (`RateLimiting__Map__PermitPerMinute`, `Map__Labels__*__MaxDistance`, `Map__Flash__*`,
     `Map__Markers__CacheSeconds`) have defaults. No migration. Steps:
     [overview map smoke test § 2](guides/overview-map-smoke-test.md#2-phase-2-public-map-api-736-tier3),
     [production installation § 4.3](guides/production-installation.md#43-api-configuration-file--etcknkapienv).

- **Overview map: the game server reports town, district and structure outlines** ([PandiO/knk-workspace#735](https://github.com/PandiO/knk-workspace/issues/735),
  link L1 of the overview map chain, [#732](https://github.com/PandiO/knk-workspace/issues/732)). knk-plugin,
  knk-web-api and knk-workspace branches `claude/overview-map-outlines` (PRs into `next`). Behind the new plugin key
  `map.reporting.enabled` (off by default). Nothing changes for players yet: the outlines are what the coming web map
  draws.
  1. With reporting on, the plugin sends the outline (2D points, min and max Y) of every Town, District, Structure and
     Gate region to the API over the game hub (`ReportRegionOutlines`): after every managed-region repair (startup,
     `/knk regions repair`), after a world task's region is renamed or redefined (the old name is removed), and again
     on every hub (re)connect. Large reports are split under the hub's message limit. Since fix F1
     ([#750](https://github.com/PandiO/knk-workspace/issues/750), knk-plugin and knk-workspace branches
     `claude/overview-map-f1-subregions`, PRs into `next`) the domain sub-regions (`domain_<id>_sub_<n>`) are reported
     too: after every region access sync, the sub-regions it lists that were not reported yet, so a domain's outline is
     its main region plus its sub-regions, also for sub-regions drawn before reporting was on. No new key.
  2. The API keeps them in the new table `map_region_outlines`, one row per world and region id, linked to the domain
     that names the region (main region or sub-region), so the map keeps its outlines while the game server is down.
     Only a plugin-key game hub connection can write them.
  3. Admin steps: apply the migration `AddMapRegionOutlines` (additive, one new table). To turn reporting on, paste into
     the plugin's `config.yml` (it also needs `realtime.enabled: true`):
     ```yaml
     map:
       reporting:
         enabled: true
     ```
     Steps: [overview map smoke test § 1](guides/overview-map-smoke-test.md#1-phase-1-region-outlines-735-tier3),
     [plugin configuration § 4.29](guides/admin/plugin-configuration.md#429-map).

- **NPC navigation: no jumps toward a waypoint on the stair house; no hop after a stair step** ([PandiO/knk-workspace#695](https://github.com/PandiO/knk-workspace/issues/695),
  link J1 of the NPC navigation follow-ups chain). NPCs walk up stairs without the small hop after each step, and waiting
  NPCs no longer jump at the wall beside a flight. knk-plugin and knk-workspace branches `claude/npc-movement-j1` (PRs
  into `next`). Behind `npc.navigation.enabled` (off by default); no new `config.yml` key, no migration.
  1. The climb scenario failed CI now and then on "jumps toward a waypoint on the flights". Singles waiting for their
     turn at flight 1's top had a queue spot on the wall top beside the flight, a block above their feet: the place's
     queue line ran diagonally back through the wall. A queue spot is now on the way's own level and reached from the
     NPC's feet without a step of more than 0.6 (knk-core `CrowdControl.onTheWaysLevel`).
  2. Citizens moved on to the next waypoint once the body was within the list's margin (0.5 or 1.0) of a stair step's
     waypoint, while the feet were still below it, and the next waypoint a block up drew a jump (the replay's hall
     entry). Such a jump is now held back when the next cell toward the waypoint is at most a step up: the body steps
     onto the stair instead. The same holds back the engine's hop on a stair's lower half (the developer's "walked up a
     stair block and then seemed to jump up a bit"). It works through Citizens' jump power supplier (knk-paper
     `CitizensNpcRuntime.jumpPower`, `StepHop`), and a full block in the way keeps its jump. The climb and the replay
     report the jumps held back.
  3. Local runs of `npc-stairhouse-climb` (12 in a row, half of them the first run after a server start):
     0 jumps toward a waypoint and 0 engine hops (151 to 166 a run on `next`), the leader up in 57 s (75 to 81 s on
     `next`), the longest crowd wait 17 to 20 s (28 to 34 s). CI `paper-boot` green. Steps: [plan § 4c.8 item 6](specs/npc-platform/IMPLEMENTATION_PLAN.md#4c8-fix-links-after-the-smoke-tests-of-2026-11-16-and-2026-11-17-b1b5-c1-j1).

- **NPC navigation: held NPCs stay held through `/knk cache refresh`** ([PandiO/knk-workspace#724](https://github.com/PandiO/knk-workspace/issues/724),
  link R1 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-r1` (PRs
  into `next`). Behind `npc.navigation.enabled` (off by default); no new `config.yml` key, no migration.
  1. A cache refresh cleared the region → domain map and sent its first availability event at once, about half a
     second before the re-warm's answers were in. In that gap every region looked open to the NPC checks, so NPCs held
     at a district edge (followers by their lane check, a single NPC by its blocking element) walked on and crossed,
     for entry and exit alike. The re-warm's event then reset the trespass guard, so `trespasses` stayed 0.
  2. A clear of the map (the cache refresh, and a realtime domain change) now keeps the last known answers for the NPC
     checks until the re-warm is done. While it runs, a region the NPCs knew keeps its answer from before the clear.
     When the answers are in, the trespass guards of every NPC and follower take a last look under the old answers, the
     hold ends and the availability event follows, so the NPCs switch to the new answers at that event. A crossing in
     the gap (an NPC carried over the edge) is counted. Players' lookups are unchanged. A hold that no re-warm ends
     (NPC navigation off, no roads) ends by itself after a minute.
  3. Scenario `npc-group-cache-refresh-held` (followers held inside a district they may not leave, then a cache refresh with a slow API; it fails on `next` before the fix)
     runs in CI's `paper-boot` job (62 scenarios). Steps: [NPC movement smoke test, link R1](guides/npc-movement-smoke-test.md#link-r1-a-cache-refresh-while-npcs-are-held-at-an-edge),
     [plan Phase 4 known limit 4](specs/npc-platform/IMPLEMENTATION_PLAN.md#phase-4--groups-plugin).

- **NPC navigation: exit rules held while NPCs walk, not only where a route is planned** ([PandiO/knk-workspace#701](https://github.com/PandiO/knk-workspace/issues/701),
  link E1 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-e1` (PRs
  into `next`). Behind `npc.navigation.enabled` (off by default); no new `config.yml` key, no migration.
  1. The NPC walking checks now judge a step by the exit rule of every region the NPC stands in, as well as by the entry
     rule. That covers the recheck of the way ahead, the trespass guard, the walk to a blocking element, and a group's
     follower lanes, waypoints and guard. It applies to every domain type. Before, these checks were entry only, and an
     exit denied while an NPC walked out on an earlier route did not stop it.
  2. An NPC that would leave a region it may not leave stops at the edge, inside, and waits; it walks on when the rule
     allows it again, through the same realtime and `/knk cache refresh` paths as entry. In a group, the followers
     still inside stop at the edge and the leader and the followers already out walk on, as for entry.
  3. The trespass guard counts a denied exit: `TRESPASS <npc> left <region> at x y z (…)`, in `rules: trespasses`.
  4. The exit rule is the road router's own (`DomainAvailability` and the shared `DomainAccessEvaluator`). The NPC's
     access profile applies: `bypass-domain-rules`, an allow list naming the region, and a domain whose rule does not
     apply to roads all let it leave.
  5. Scenarios `npc-exit-denied-leader` (an NPC alone: exit denied through realtime, allowed again through a cache
     refresh) and `npc-group-exit-denied` (a group half inside, both ways through realtime) run in CI's `paper-boot`
     job (61 scenarios). Steps: [NPC movement smoke test, link E1](guides/npc-movement-smoke-test.md#link-e1-exit-denied-mid-trip),
     [plan Phase 4 developer test step 15](specs/npc-platform/IMPLEMENTATION_PLAN.md#phase-4--groups-plugin).

- **NPC navigation: off-road starts and ends with the walk navigator's search** ([PandiO/knk-workspace#700](https://github.com/PandiO/knk-workspace/issues/700),
  link C1 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-c1` (PRs
  into `next`). Behind `npc.navigation.enabled` (off by default); no new `config.yml` key, no migration.
  1. An NPC's off-road start (to the road), off-road goal (from the road's end) and a trip with no road are planned
     with the walk search players' trails use (the capture of loaded chunks, the NPC's gate, door and region access,
     `navigation.walk`'s caps) and walked as part of the route line: stretches, the 3D handover, the join from the
     feet, the walking surface. Before, they were straight lines cut into 16-block hops.
  2. The road is joined where the walk reaches it (any road point within 32 blocks along the road); the walk to the goal
     is tried from further back along the road when the road's end reaches nothing. Hops stay the fallback.
  3. A group's followers take the leader's walked path, as on roads; a walk's cells are not shaped or moved off walls
     (a spiral stair stays a spiral).
  4. An open door or fence gate no longer counts as a wall for NPC lines; the walk planner checks a found path against
     the NPC's body and searches again round cells it cannot stand in (an open trapdoor's panel).
  5. `/knk npc nav snapshot` takes the route's from and to into its box, so an off-road goal (a tower top) is inside.
  6. Scenario replays read Minecraft 26.x block states written as `{id, properties}` (stairs not facing north, top
     slabs, open doors); they were missing from every replay before.
  7. The developer's failed tower route of 2026-11-17 (`northern-wearway-upper-keep-tower`, stuck at 1405 85 −510) is
     replayed: a leader alone and a group of 20 reach the goal up the spiral staircase (`npc-replay-keep-tower`), and
     three scenes (a detour round a courtyard, a two-turn spiral, a ravine) run in CI's `paper-boot` job (59 scenarios with the off-road chain's L3, L4 and L10).
     Steps: [NPC movement smoke test, link C1](guides/npc-movement-smoke-test.md#link-c1-off-road-ends-with-the-walk-search-retest-of-2026-11-17-step-5).

- **Off-road navigation: plaza lines, step 1 (preview for staff)** ([PandiO/knk-workspace#712](https://github.com/PandiO/knk-workspace/issues/712),
  link L10 of the off-road navigation chain, phase 7 step 1). knk-plugin and knk-workspace branches
  `claude/offroad-plaza-lines` (PRs into `next`). The trail does not use plaza lines yet: the developer looks at them
  on Cinix and Brink first (O16). New flag `navigation.plaza-lines`, off by default and read by nothing yet; routes,
  trails, the session and NPC movement are unchanged. No migration.
  1. knk-core `core/navigation/shape/PlazaCurve`: where a route enters a plaza on one road and leaves on another, a
     cubic curve from the entry to the exit pulled towards the plaza node (`plaza-pull` 0.35, O30), checked every 0.5
     block on the plaza's clearance map, regions and floor; when it does not fit, `PlazaLine`'s A* guided by the curve
     (`plaza-guide-cost` 2; a new additive `PlazaLine.search` overload, the plain search unchanged); plazas only, by the
     NPC rule (O19). `core/navigation/PlazaLinePreviews`: the passes through a named node (every pair of its roads) or
     along a route, and the chat line.
  2. `/knk road plazaline [<plaza or junction>]` (`knk.admin.road`): draws the lines of your route's junctions, or of
     every pair of roads at a named node, for 10 seconds (green curve, orange A* line, red rejected curve, white the
     road graph's bend, light blue the plaza's edge) and writes each one's length against the chord and the right
     angle, its least clearance and why a curve did not fit.
  3. Three paper-boot scenarios on real plazas from the developer's snapshots: `plaza-line-brink`,
     `plaza-line-cinix-south-square`, `plaza-line-cinix-northern-gate-square` (two new trimmed snapshots of 175 KB
     each).
  4. Admin steps (optional, for the preview's pull): under `navigation:` add `plaza-lines: false`, `plaza-pull: 0.35`,
     `plaza-guide-cost: 2`; restart.

- **Off-road navigation: walk-trail particles stay put, and the guidance winds back** ([PandiO/knk-workspace#711](https://github.com/PandiO/knk-workspace/issues/711),
  link L4 of the off-road navigation chain, phase 6.2). knk-plugin and knk-workspace branches
  `claude/offroad-trail-cursor` (PRs into `next`). Behind `navigation.guidance-v2`, off by default: with it off the
  session, the trail, the re-routes and the walk legs are exactly as before (transcript tests). No migration. NPC
  navigation unchanged.
  1. Walk-trail particles sit on fixed anchors every `trail-leg-spacing` (3.0) blocks from the walk path's start, drawn
     from the leg's cursor, which follows the player along the path both ways and jumps more than 3 blocks only when
     the player really is nearer the other place (`TrailRenderer.anchoredWindow`, `PolylineCursor`).
  2. The route session keeps a monotone progress (ETA, percentage, maneuvers already announced) and a cursor that
     follows the player back along the road (continuity within `cursor-jump`, 12, for loops and switchbacks); the
     trail, the HUD distance and the maneuver ahead come from the cursor (`NavigationSession`, `CursorParameters`).
  3. A player off the road walks to the join point with the least remaining cost (`JoinPoint`); a walk leg stays while
     the player is within `walk.recompute-distance` of its path, walking back included, and is recomputed from the
     player beyond it (at most once per `reroute-min-interval`). `DirectLeg.best` and the start leg's "heading away"
     (N16) are not used under the flag. KNG-124, N17, rev. 9 and the partial path rule are kept.
  4. Admin steps (only to try it on a test server): under `navigation:` add `trail-leg-spacing: 3.0` and
     `cursor-jump: 12` beside `guidance-v2`; restart.
  5. Tests: knk-core +21 (the cursor on lines, corners, loops and switchbacks, the join point, the session's progress
     and cursor, today's session as a transcript), knk-paper +13 (anchors, the service with the flag on and off, the
     keys), new paper-boot scenario `walk-trail-cursor-stairhouse` (the cursor and the anchors on the stair house's
     shaped trail).

- **Off-road navigation: walk trails keep off the walls and round their corners** ([PandiO/knk-workspace#710](https://github.com/PandiO/knk-workspace/issues/710),
  link L3 of the off-road navigation chain, phase 6.1). knk-plugin and knk-workspace branches
  `claude/offroad-trail-corners` (PRs into `next`). Behind `navigation.guidance-v2`, off by default: with it off the
  walk paths, the search and the trail are exactly as before. No migration.
  1. With the flag on, the walk search uses a clearance cost (`walk.clearance-cost` 5 per block of clearance a step
     lacks to `walk.wall-clearance` 0.8) in place of `walk.wall-cost`; `clearance-cost: 0` keeps `wall-cost`.
  2. A found or partial walk path is shaped on the walk thread by the shared `CorridorShaper` over the captured
     terrain (`WalkTerrainNavWorld`, `WalkPathShaper` in `knk-core` `core/roads/walk/`), and its corners are drawn as
     curves checked against the clearance map (`walk.curve`). Leg colour and 3.0 spacing unchanged; the road trail is
     unchanged. `/knk road status` shows the shaped paths and their mean time.
  3. Admin steps (only to try it on a test server): under `navigation:` add `guidance-v2: false` (set `true` to test)
     and under `navigation.walk:` add `clearance-cost: 5`, `wall-clearance: 0.8`, `curve: true`; restart.
  4. Tests: knk-core +17 (clearance cost, the flag-off identity over five scenes, a 3-wide spiral stair, the NPC and
     player shapers on one scene), knk-paper +7, new paper-boot scenario `walk-trail-stairhouse` on the developer's
     stair house (a local run: 0 % of the trail under 0.7 blocks from a wall, against 44.7 % of today's path).

- **Off-road navigation: the shaping code is shared** ([PandiO/knk-workspace#704](https://github.com/PandiO/knk-workspace/issues/704),
  link L2 of the off-road navigation chain, phase 1). knk-plugin and knk-workspace branches
  `claude/offroad-shape-package` (PRs into `next`). Players and NPCs see no change; no `config.yml` key, no migration.
  1. The NPC path shaping (`Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine`) and the world primitives it reads
     (`NavWorld`, `NavPoint`, `NavGeometry`, and `PlazaCrossing`, formerly `RoadPlanner.PlazaCrossing`) moved to
     `knk-core` `core/navigation/shape/`, so the players' walk trail can use them in phase 6.1 (design O11).
  2. `HopPlanner`'s floor helpers live in `NavGeometry` (`HopPlanner` delegates); `LocalLegSearch` stays NPC-side.
  3. Tests: the same counts as before apart from one new guard test (`core/navigation/shape` uses nothing from
     `core/npc`); the NPC scenarios run in CI's `paper-boot` job.

- **Off-road navigation: walk-search measurements in `/knk road status`** ([PandiO/knk-workspace#703](https://github.com/PandiO/knk-workspace/issues/703),
  link L1 of the off-road navigation chain, phase 0). knk-plugin and knk-workspace branches `claude/offroad-measurements`
  (PRs into `next`). Players see no change: routes and trails are the same; staff get numbers to set the off-road
  budgets with.
  1. Every walk search reports its expansions, cells touched, search time and the cap that ended it
     (`max-expansions`, `max-length`), and whether steps were cut at the length cap; every chunk capture its chunks,
     cache hits, main-thread time and wait.
  2. `/knk road status` shows them under `walk paths:`: max, p95 and p50 over the last 512 searches and the five
     newest requests. `/knk road status reset` clears them, so one scene can be read at a time.
  3. The measurement steps are in the [off-road smoke test § 1](guides/navigation-offroad-smoke-test.md#1-phase-0-measurements-703-tier1);
     the [report skeleton](reports/2026-11-17-offroad-navigation-measurements.md) waits for the developer's live run.
  4. Admin steps: new key `navigation.walk.max-chunks-per-request` (default 64, the limit that was built in). Paste
     under `navigation.walk:`, then restart:

     ```yaml
         max-chunks-per-request: 64
     ```

- **NPC navigation: a group's path stays on the walk on stacked flights** ([PandiO/knk-workspace#699](https://github.com/PandiO/knk-workspace/issues/699),
  link B5 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-b5` (PRs
  into `next`). Only with `npc.navigation.enabled` on and `group-formation-keeping: elastic` or `plaza-lines` on (all
  off by default); no new `config.yml` key, no migration.
  1. A group that keeps its formation elastic, or takes plaza lines, walks a path shaped in its corridor. On the stair
     house's stacked flights that shaped line cut the hairpin across the stairwell, so the group's path skipped a
     flight's top and its landing (or ran on the hall floor beside a flight). Followers there were judged against a
     point a flight away: they left their lanes, walked their own legs back, and in the smoke test of 2026-11-17 walked
     up and down flight 4 for minutes while their leader waited on the passage right above them.
  2. A shaped point is now used only where it has a floor within a block of the route line's own point and a straight
     walk leads to it; otherwise the group path takes the route line's own point. Shaping on one level is unchanged.
  3. Tests: `npc-replay-quarry-to-keep` replays the developer's snapshot of 2026-11-17 and sends the group on to the
     route's end in the keep with the developer's settings; it fails when a follower leaves its lane on the flights
     and landings, or loops (three own legs back from one place). Followers off their lane on the stair house: 21
     before (every follower, at flight 5's top), 0 now; the leader arrives in 105.5 s instead of 123.8 s.

- **NPC navigation: crowd turns judged in 3D** ([PandiO/knk-workspace#672](https://github.com/PandiO/knk-workspace/issues/672),
  link B3 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-b3` (PRs
  into `next`). Only with `npc.navigation.enabled` and `crowd-awareness` on (both off by default); no new `config.yml`
  key, no migration.
  1. A narrow place taken in turns now has a floor: flat, or a flight's slope. An NPC whose feet are 1.5 blocks or more
     above or below it stands on another level.
  2. An NPC holding a turn that climbed on to the flight above, or fell under the place, has left it: its turn ends,
     unless one of its followers is still in the place.
  3. Nobody waits for an NPC on another level. Before, on the stair house's stacked flights, singles going the same
     way as a group waited behind its leader a flight up (seen from above it looked as if it stood at the place's
     entry) until the 30 s guard let them go, up to 18 at a time.
  4. The 30 s guard of a queue counts from the last time anyone entered the narrow place, not from the NPC's arrival:
     a long single file that keeps moving (18 NPCs up a one-wide stair, about 2 s each) is no longer let go at its
     end. A place nobody enters still lets its queue go after 30 s.
  5. Tests: `npc-stairhouse-climb` now fails when the 30 s guard lets anyone go, and reports why (where the NPC and
     every turn holder stood in 3D). The climb's queue let go by the guard: 0 to 6 per run before, 0 now (longest
     queue 18, 2.1 s per NPC ahead); falls, jumps toward a waypoint, stuck spells and lost followers stay 0.

- **NPC navigation: waypoints and group slots at the real stair heights; jumps told by upward speed** ([PandiO/knk-workspace#673](https://github.com/PandiO/knk-workspace/issues/673),
  link B4 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-b4` (PRs
  into `next`). Only with `npc.navigation.enabled` on; no new `config.yml` key, no migration.
  1. Waypoints go to the engine at the real walking surface: a bottom slab and an upright stair's step at half a block,
     not at the whole-block height navigation plans with. Where two waypoints rise more than a step, the step between
     them goes in, so the NPC walks a half-block stair up step by step instead of jumping.
  2. Group slots too: a follower's slot on a half-block stair lies on the step's surface.
  3. Once the leader has arrived, a follower standing at its slot's point (within a block across, less than a block
     up or down) counts as settled, also where the group path passes the same place twice. Before, it was sent round
     the loop, stalled next to its slot, and its recovery ended `no point ahead on its floor` and lost.
  4. A half-block step up is no jump for the low-headroom rule, so recovery finds its point ahead on a half-block stair.
  5. `/knk npc nav trace` marks `JUMP` by a jump's upward speed, not by any rise over 0.2 blocks: a step up a slab or
     a stair is no longer a jump.
  6. Tests: `npc-replay-quarry-to-keep` now fails on a lost follower: the group of 20 with the stored settings arrives
     with 0 lost (B2: 3) and 4 to 6 stuck spells (B2: 26). `npc-stairhouse-climb` fails on a jump toward a waypoint on the
     flights and their entries: 0. Both report the engine's own hops off a stair's step separately (Minecraft's move
     control hops whenever the block at the feet reaches above them; no waypoint height removes those).

- **NPC navigation: stretch handover in 3D, appended, bridged from the feet** ([PandiO/knk-workspace#671](https://github.com/PandiO/knk-workspace/issues/671),
  link B2 of the NPC navigation follow-ups chain). knk-plugin and knk-workspace branches `claude/npc-movement-b2` (PRs
  into `next`). The main cause of the failed smoke test of 2026-11-16 (chain report decision 34). Only with
  `npc.navigation.enabled` on; no new `config.yml` key, no migration.
  1. The next stretch is handed out by progress along the waypoints in 3D, not by horizontal distance to the stretch
     end, so a stretch end on the flight above no longer counts as near.
  2. The new stretch is appended to the waypoints not yet walked (those the NPC is already past are dropped), and the
     join is bridged from the NPC's feet.
  3. A step of the line the bridge cannot make is walked as a local leg, never as a straight walk across air.
  4. A group leader that falls below the group path no longer takes the path with it: followers don't walk off the same
     edge.
  5. `npc-stairhouse-climb` and `npc-replay-quarry-to-keep` now fail on falls, handovers onto another level and turns
     dropped by the crowd's guard after a fall. On the climb: falls 42 → 0, handovers onto another level 446 → 0,
     stuck spells 117 → 2. Known limit: followers on the stair house's half-block flight still get lost in the replay
     (a separate cause, proposed for B4, #673).

- **NPC navigation tests: the whole stair house and snapshot replay** ([PandiO/knk-workspace#670](https://github.com/PandiO/knk-workspace/issues/670),
  link B1b). knk-plugin and knk-workspace branches `claude/npc-movement-b1-scene` (PRs into `next`). Tests only, nothing
  changes on a server.
  1. The stair-house scenarios get the developer's whole schematic, both flights and the upper landings, in a bigger
     scenario box (`SizedScene`).
  2. `npc-stairhouse-climb` (report mode) walks a group of 20 with 20 singles on the real road line of the developer's
     traces from the street east of the house up all five flights with short stretches. On `next` it shows falls
     under the landings, stretches handed out on a flight above the NPC (decision 34's main cause) and a turn dropped
     by the crowd's 30 s guard.
  3. `SnapshotReplay` replays a zip of `/knk npc nav snapshot` in a scenario: blocks from its region files (Minecraft
     26.x included), its domains as WorldGuard regions with fake access data, the stored line and settings.
     `npc-replay-quarry-to-keep` replays the developer's snapshot of 2026-11-16, trimmed to the stair house. CI's `paper-boot` now expects 50 scenarios.

- **NPC navigation: `/knk npc nav snapshot <route>`** ([PandiO/knk-workspace#670](https://github.com/PandiO/knk-workspace/issues/670),
  link B1a of the NPC navigation follow-ups chain). knk-plugin branch `claude/npc-movement-b1` (PR into `next`). An admin
  command (`knk.admin.npc`) that writes one zip to `plugins/KnightsAndKings/npc-snapshots/` with a saved route's road line
  and stretches, the road graph, domains (whole regions, parents, priorities, entry and exit flags, gate state) and
  settings around it, and the region files its box touches, so the route can be replayed in CI (the replay follows in
  B1b). Refused while `npc.navigation.enabled` is off. Deploy: no `config.yml` key, no migration.

- **NPC navigation: the NPC rule checks see WorldGuard regions on a server** ([PandiO/knk-workspace#668](https://github.com/PandiO/knk-workspace/issues/668),
  link L9 of the NPC navigation follow-ups chain; #506, #593). knk-plugin and knk-workspace branches
  `claude/npc-followups-l9` (PRs into `next`). Nothing changes with `npc.navigation.enabled: false`.
  1. **What was wrong.** The NPC module starts while the plugin registers its commands, before the plugin builds its
     WorldGuard region tracker, so the region query it took at start was empty on every server. The NPC rule checks
     (the recheck of an NPC's way ahead, its trespass guard, and a group's follower lanes and guard) then saw no region
     anywhere: a district whose entry was removed mid-walk (realtime or `/knk cache refresh`) stopped nobody until the
     router's next plan, and `rules: trespasses` stayed 0 because no entry was ever seen. The per-region
     `npc.navigation` override scopes did not apply to NPCs either. The tests had passed because the scenarios built a
     region query of their own.
  2. **What changed.** The module asks for the region query when route following is built (on the first
     `/knk npc nav`) and logs `[NPC] no WorldGuard region query …` when there is none. The NPC scenarios with domain
     rules now read regions through the live module, as the server's checks do. L6's realtime path is unchanged; it
     was correct but had nothing to act on.
  3. **The op's entry bypass is not involved.** A group started with `/knk npc nav group` is judged as NPCs with its
     access profile (the command's profile argument, else `default`, whose `bypass-domain-rules` is `false`), never
     as the player who ran the command.
  4. **Deploy.** No new `config.yml` key, no migration. Check the startup line `0.1.0+<sha>`; per-region
     `npc.navigation` overrides now take effect for NPCs.

- **CI: the Paper boot test's log check no longer fails at random on the player scenarios** ([PandiO/knk-workspace#586](https://github.com/PandiO/knk-workspace/issues/586)).
  knk-plugin and knk-workspace branches `claude/paper-boot-flake-586` (PRs into `next`; the plugin fix also into `main`).
  1. **What was wrong.** Now and then a `paper-boot` run failed its log check on `Failed to sync user data for
     Scn…: RuntimeException: Failed to check duplicate`, though every scenario passed. The plugin printed that error's
     stack trace with `printStackTrace()`, one line at a time, and another API-client thread could log a plain warning
     in between; the check then gave the trace (with its "API unreachable" cause) to that warning.
  2. **What changed.** The join's account sync (and its welcome message fallback) log the exception with the log entry;
     the check prefers the entry that quotes the trace's exception. Nothing is excused that wasn't before. The teleport
     audit's retry that hits a stopped plugin is one `INFO` line (on `next` since 2026-11-15, now with a test of that
     exact race) ([CI § 7](guides/developer/ci.md#7-plugin-the-paper-boot-test)).
  3. **Deploy.** Nothing to deploy; server logs show the sync error's cause as part of the same entry.

- **CI: the API's MySQL tests run on every push** ([PandiO/knk-workspace#419](https://github.com/PandiO/knk-workspace/issues/419)).
  knk-web-api `main` and `next` ([knk-web-api#43](https://github.com/PandiO/knk-web-api/pull/43)); knk-workspace branch
  `claude/mysql-tests-ci-419` (PR into `next`).
  1. **What changed.** The new `mysql-tests` job of the API's "Build and test" workflow runs the 100 `requires-mysql`
     tests (row locks, transactions, unique indexes, ledger triggers) against a throwaway MySQL 8.0 service container,
     in parallel with `build-and-test`, and fails if any of them was skipped. 99 run and pass; one is a known failure
     ([#285](https://github.com/PandiO/knk-workspace/issues/285)). The job takes 7 to 8 minutes
     ([CI § 1.1.1](guides/developer/ci.md#11-tests-that-ci-does-not-run)).
  2. **Unchanged.** `build-and-test` keeps its name and duration, and local runs without `KNK_TEST_MYSQL` still skip
     these tests. `mysql-tests` is not a required check yet (recommended once it has been green a few times).
  3. **Deploy.** Nothing to deploy; workflows and one test mark only.

- **NPC navigation: push resistance with collision on; `collidable` stays off by default** ([PandiO/knk-workspace#627](https://github.com/PandiO/knk-workspace/issues/627),
  link M7 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 7, research report 2026-11-15
  § 6). knk-plugin and knk-workspace branches `claude/npc-movement-m7` (PRs into `next`, in review). Nothing changes with
  `npc.navigation.collidable: false` (still the default) or with `npc.navigation.enabled: false`.
  1. **What it does with `collidable: true`.** NPCs push and block each other; players never move an NPC (each NPC is
     exempt from every player's collision through Paper's per-entity collidable exemptions; no scoreboard team is
     touched). A push the NPC's own walk doesn't explain (a body, an attack's knockback, water, a piston) is detected,
     counted and logged with who did it, and the NPC walks back to its line or post: straight back, else along its own
     footsteps, else a local leg, and last, after 30 s, a teleport home only where no player sees it. Another NPC's
     jostle on its way is left to the crowd unless it goes towards a drop; queue spots never stand next to a drop of 3
     blocks or more. With `players-push-npcs: true` players bump NPCs (the realistic mode for later): a player who pushes
     an NPC 3 times in 10 s, or once towards a drop, stops colliding with it for 60 s. An attack's knockback stays and the
     NPC walks back. `/knk npc nav stats` shows `pushes: N (players N, attacks N), returned N, exempted N (now N),
     teleported N`; the metrics count `knk_npc_nav_events_total{event="pushed|push_returned|push_exempt|push_teleport"}`.
  2. **Checked** (scenarios on Paper 26.3 with Citizens and a scripted player): a player walking through a standing NPC
     carries it 2.85–3.80 blocks with collision on and no policy, 0.00 with K&K's; a guard on a wall walk pushed towards a
     7-block drop doesn't move, and with `players-push-npcs` it is pushed 0.68, the player is exempted at the edge, it
     never falls and walks back; the five Phase 4c scenes pass with collision on as with it off; 12 singles one way
     through a one-block door all arrive with turns kept.
  3. **Why the default stays off.** With bodies on everywhere, NPCs walking a 1-wide flight next to a drop can shove
     each other off it (the #491 stair corner scene: one fell), which push resistance can't undo; bodies of a squeezed
     row still overlap (closest 0.19). The plan (4c.4 item 7.4.10) lists what is missing before the default turns on.
  4. **Deploy.** Add the keys to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         collidable: false
         players-push-npcs: false
         push-return: true
         push-exempt-after: 3
         push-exempt-window-ticks: 200
         push-exempt-ticks: 1200
         push-teleport-ticks: 600
     ```

- **CI: GitHub Actions on Node.js 24, Release workflow fixes** ([PandiO/knk-workspace#426](https://github.com/PandiO/knk-workspace/issues/426)).
  knk-web-api, knk-web-app and knk-plugin `main` and `next`; knk-workspace branch `claude/actions-node24-426` (PR into
  `next`).
  1. **Actions.** Every workflow uses the Node.js 24 majors: `checkout` v7, `setup-dotnet` v6, `setup-node` v7,
     `setup-java` v6, `upload-artifact` v7, `cache` v6 and `gradle/actions/setup-gradle` v6 (with the open-source
     `cache-provider: basic`). The Node.js 20 warning on every run is gone; job and artifact names are unchanged
     ([CI § 6](guides/developer/ci.md#6-action-versions-nodejs-24)).
  2. **Release workflow.** One concurrency group per tag, so a third dispatch no longer replaces a pending second one.
     A tag that already exists at exactly the requested commit without a release gets its release from a new run
     instead of a failure; a tag at another commit, or one with a release, still fails the run.
  3. **Deploy.** Nothing to deploy; workflows only.

- **NPC navigation: crowd awareness, off by default** ([PandiO/knk-workspace#626](https://github.com/PandiO/knk-workspace/issues/626),
  link M4 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 4, decision 3; BEHAVIOR_MODEL
  NAV-26). knk-plugin and knk-workspace branches `claude/npc-movement-m4` (PRs into `next`, in review). Nothing changes
  with `crowd-awareness: false` (the default) or with `npc.navigation.enabled: false`.
  1. **What it does.** NPCs know who stands where near them: every 5 ticks the navigation service hashes the feet cell
     of every navigating NPC. A narrow place on an NPC's way (a door, an arch, a passage under 2 blocks wide) is taken
     in turns, one direction at a time: an NPC already in it goes first, then first come (decided by the developer
     2026-11-15). The others wait in a queue a block apart before it, a block to the side of the line, so the way out
     stays free. Two NPCs that meet head-on in a narrow place: the second to enter steps back out and waits (a yield).
     A group's leader keeps its turn until its followers are through. Waiting in a queue, yielding or standing behind
     another NPC (a single or a group's follower) is counted as a wait, not as a stuck spell, and recovery back-offs and
     side-steps never end on a cell where another NPC stands; K&K's local legs (`local-legs-clearance`) go round such a
     cell. `/knk npc nav stats` shows `crowd: waits N, yields N, longest queue N`; the metrics count
     `knk_npc_nav_events_total{event="crowd_wait"}` and `{event="crowd_yield"}`. Authority values and closed
     formations first are later updates (plan 4c.7).
  2. **Checked.** In `npc-doorway-crowd` (6 singles from each side of a one-block doorway at once) today's code gets
     11 of 12 through with 2 stuck spells and an NPC still for 11.7 s by the door (collision off); with the clearance-aware
     legs alone all 12 walk through each other (5 in the doorway at once) and, with collision on, open 6 stuck spells.
     With crowd awareness all 12 arrive both ways with 0 stuck spells, they take the doorway one direction at a time
     (at most 2 in its cell at once, the same way), the 7th in the queue waits 7.8–8.3 s, 1.5 s per NPC that went
     first, and nobody stands still outside a queue longer than 0.4 s. Turn-taking costs time with collision off: trips
     take 6.3 s on average instead of 3.7 s. The group of 20 through the stair-house entrance is unchanged (no narrow
     place on its line; 0 waits, 0 stuck spells, entrance still 0.4 s). Both scenarios now assert this, with collision
     off and on. The hash and the turns cost 0.0015–0.0063 ms per NPC per tick.
  3. **Deploy.** Add the key to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         crowd-awareness: false
     ```

- **NPC navigation: plaza lines, off by default** ([PandiO/knk-workspace#625](https://github.com/PandiO/knk-workspace/issues/625),
  link M5 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 5, decision 6; BEHAVIOR_MODEL
  NAV-27). knk-plugin and knk-workspace branches `claude/npc-movement-m5` (PRs into `next`, in review). Nothing
  changes with `plaza-lines: false` (the default) or with `npc.navigation.enabled: false`.
  1. **What it does.** The road graph collapses a plaza into one junction, so a route across a plaza runs to its
     middle and out again. With `plaza-lines: true` an NPC crosses a plaza on the straight line from where its route
     enters to where it leaves: the corridor widens to the plaza (a designed plaza's radius, or the open floor measured
     round the junction when it is wider than `corridor-half-width`, at most `plaza-corridor-blocks`), and the line
     goes round wells, stalls and trees with `wall-clearance` and never into a region the route does not pass.
     Groups take the same line, kept their formation's half width plus `wall-clearance` from obstacles, and keep
     their width on the open plaza. It works with or without `corridor-steering`. The players' trail and the road
     graph are unchanged; through-edges in the road-graph builder are a later update (plan 4c.7).
  2. **Checked.** In `npc-plaza-line` (a 15 × 15 plaza with a well on the chord) 3 singles walked +40 % over the
     chord through the plaza's middle; with the key on they walk +4 % over the shortest line that keeps 0.8 from the
     well and pass it at 0.64–0.75 blocks, never near the middle. A group of 7 in ranks of 3 takes the same line round
     the well with its own margin, 3 abreast all the way. The scenario now asserts this, with collision off and on.
     Known: with collision off the group there reports its arrival 20 s late (followers already in place), a bug in
     `next` filed as [#636](https://github.com/PandiO/knk-workspace/issues/636).
  3. **Deploy.** Add the keys to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         plaza-lines: false
         plaza-corridor-blocks: 16
     ```

- **NPC navigation: elastic formation keeping, off by default** ([PandiO/knk-workspace#624](https://github.com/PandiO/knk-workspace/issues/624),
  link M3 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 3, decision 2; #522, #493).
  knk-plugin and knk-workspace branches `claude/npc-movement-m3` (PRs into `next`, in review). Nothing changes with
  `group-formation-keeping: levels` (the default) or with `npc.navigation.enabled: false`.
  1. **What it does.** With `group-formation-keeping: elastic` a group fits its width to the free width across its
     path instead of fixed widths: neighbours move closer, down to shoulder to shoulder (`group-lateral-spacing-min`
     0.6), and the rows close up (`group-spacing-min` 1.0) before the group drops a width, so 3 abreast walk a 2-wide
     road. It decides its width ahead (the formation's depth plus `group-lookahead-blocks`, 4), so the followers are
     in their new lanes before the narrow place. It folds into single file only where 2 abreast squeezed don't fit
     for longer than `group-width-hysteresis-blocks`; a shorter tight place (a post, a one-block gap) is passed with
     the lanes merged. Stairs are walked as wide as the flight allows when each lane has its own steps; lanes may
     cross into regions the group's access rules allow; followers take the new slots by where they stand, so nobody
     crosses another's line. The group path follows the corridor-shaped line, and the outer lanes keep
     `wall-clearance` from walls where the road allows.
  2. **Stats.** The groups line of `/knk npc nav stats` has `merges N (reasons)` next to the narrowings, and the metric
     `knk_npc_nav_group_width_reasons_total` has `change="merge"`.
  3. **Checked.** `npc-stairhouse-group` (the developer's stair house, 20 in ranks of 3) now walks 3 abreast with no
     fold where it folded at the first step, the leader arrives after 7.5 s instead of 27 s and no follower stands in
     the entrance longer than 0.4 s (was 23.7 s); the group of 9 on the jagged straight has no stuck spells with
     collision off (was 5, 3 not freed). Both scenarios, collision off and on, check plan 4c.4 item 3.3;
     `npc-group-narrows` checks the squeeze on the corner scene.
  4. **Deploy.** Add the keys to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         group-formation-keeping: levels
         group-lateral-spacing-min: 0.6
         group-spacing-min: 1.0
         group-lookahead-blocks: 4
     ```

- **NPC navigation: clearance-aware local legs, off by default** ([PandiO/knk-workspace#623](https://github.com/PandiO/knk-workspace/issues/623),
  link M6 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 6, decision 8, add-on D).
  knk-plugin and knk-workspace branches `claude/npc-movement-m6` (PRs into `next`, in review). Nothing changes with
  `local-legs-clearance: false` (the default) or with `npc.navigation.enabled: false`.
  1. **What it does.** A local leg is the part of a trip an NPC walks without the road line: a short trip, a group
     follower's own leg back to its group, the recovery ladder's local leg when an NPC is stuck. Until now Citizens'
     own path search found the way, which knows the body's size but keeps no margin from walls, and its failed
     searches cost main-thread time before they came back with no path. With the key on, K&K searches the leg itself:
     on the walkable corridor around it (its own floor, steps of at most a block), with K&K's access rules for the
     NPC (gates, doors, regions it may not enter), keeping `wall-clearance` (0.8) from walls where the gap allows and
     never less than the body's width, so one-block doors stay open. The found way is smoothed into a few straight
     steps that keep the floor under the NPC and is walked as waypoints. When K&K finds nothing within its cell budget,
     Citizens' search walks the leg as before.
  2. **Stats.** `/knk npc nav stats` has a new line `local legs: k&k N, engine N, none N`: legs K&K's search found,
     legs Citizens' search walked, and legs neither found a way for.
  3. **Checked.** `npc-stuck-ladder` (now with the key on) checks that the ladder's local leg frees the pushed NPC as a
     K&K leg without an engine search; `npc-stairhouse-singles` (key on, collision off and on) checks that no local
     leg ends without a path. The other movement scenarios report the counts.
  4. **Deploy.** Add the key to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         local-legs-clearance: false
     ```

- **NPC navigation: corridor steering, off by default** ([PandiO/knk-workspace#622](https://github.com/PandiO/knk-workspace/issues/622),
  link M2 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 2, decision 1 option A).
  knk-plugin and knk-workspace branches `claude/npc-movement-m2` (PRs into `next`, in review). Nothing changes with
  `corridor-steering: false` (the default) or with `npc.navigation.enabled: false`.
  1. **What it does.** Before an NPC walks a stretch of its route (about 32 blocks), K&K builds the walkable corridor
     around the road line (`corridor-half-width` blocks each side, the NPC's own floor and the road's regions), works
     out each spot's clearance from walls, posts and drops, and moves the line: `wall-clearance` (0.8) off walls
     where the road is wide enough, on straights too; through the middle where it is narrower, so one-block doors
     stay open; straightened where the corridor allows; and through the middle of a doorway or entrance on its axis,
     with a waypoint 1.5 blocks before it, one in it and one after it (walked with waypoint margin 0.35). The shaped
     stretch is built once and shared by every NPC that gets it. Corner clearance and the waypoint chain still run on
     it. Group members keep today's line until link M3 fits formations to the corridor.
  2. **Checked.** With the key on, `npc-stairhouse-singles` and `npc-jagged-straight` (collision off and on) now
     assert: all 12 singles arrive, 0 stuck spells, nobody still longer than 3 s, no fall, corridor steering's own cost
     at most 0.03 ms per NPC per tick (the plan's budget; about 0.005 ms warm).
  3. **Deploy.** Add the three keys to `npc.navigation` in `config.yml` (configuration reference § 4.27) and restart:

     ```yaml
     npc:
       navigation:
         corridor-steering: false
         corridor-half-width: 4
         wall-clearance: 0.8
     ```

- **NPC navigation: movement evidence and diagnostics** ([PandiO/knk-workspace#621](https://github.com/PandiO/knk-workspace/issues/621),
  link M1 of the NPC navigation follow-ups chain, implementation plan Phase 4c.4 item 1 and 4c.5). knk-plugin and
  knk-workspace branches `claude/npc-movement-m1` (PRs into `next`, in review). No behaviour change, no new
  `config.yml` key; nothing changes for players or with `npc.navigation.enabled: false` (the default).
  1. **Why a group folded.** Every fold and narrowing now names its cause in the log line ("folds into a column: the
     path is too narrow for 2 abreast (stair) at …") and counts it: `stair` (a step on the path), `narrow` (no floor
     where a lane would stand), `door` (a gate door on the route), `rules` (a lane in other WorldGuard regions) and
     `edge` (a lane with floor but no room at its shoulder, a jutting wall piece). The groups line of
     `/knk npc nav stats` shows them ("folds 3 (stair 2, door 1)") and the metrics have
     `knk_npc_nav_group_width_reasons_total{change, reason}`. Counting only: the widths are chosen as before.
  2. **How much room the line has.** `/knk npc nav trace` writes a `# corridor:` line after each `# waypoints:` line:
     each waypoint's free width across the line (total, left, right in blocks, to the nearest wall, post, full-block
     step or drop, at most 4 per side).
  3. **Real places as test scenes.** Plugin scenarios can paste a WorldEdit schematic (`.schem`, the format
     `//schem save` writes) from the plugin's `scenario-scenes/` resources into their box. Five new scenarios, each run
     with `npc.navigation.collidable` off and on, measure today's movement in report mode (they log a
     `KNK-NPC-REPORT` line and pass; later links turn the numbers into checks): `npc-stairhouse-singles`,
     `npc-stairhouse-group`, `npc-jagged-straight`, `npc-doorway-crowd` and `npc-plaza-line`. The stair house is
     the developer's own schematic (attached to [#603](https://github.com/PandiO/knk-workspace/issues/603)); the
     other three scenes are synthetic by design. On it, a group of 20 folds at the first step and a follower stands
     about 24 s in the entrance, the developer's jam. CI's
     `paper-boot` job runs 45 scenarios now and copies the report lines into its summary.
- **NPC navigation: movement-quality design (decided)** ([PandiO/knk-workspace#603](https://github.com/PandiO/knk-workspace/issues/603), link L8): implementation plan Phase 4c (steering options from a [research report](reports/2026-11-15-npc-movement-research.md) on how games handle obstacle avoidance and stuck recovery, formations that tighten before they fold, turns at chokepoints, natural lines on plazas; links M1–M5) and BEHAVIOR_MODEL NAV-24–NAV-28; docs only; decided by the developer 2026-11-15 (all fifteen questions).
- **NPC navigation: entry removed in the web app with realtime on stops a group at the district's edge**
  ([PandiO/knk-workspace#593](https://github.com/PandiO/knk-workspace/issues/593), the developer's retest of
  [#506](https://github.com/PandiO/knk-workspace/issues/506) (Phase 4 developer test step 10); also
  [#533](https://github.com/PandiO/knk-workspace/issues/533); link L6 of the NPC navigation follow-ups chain).
  knk-plugin and knk-workspace branches `claude/npc-followups-l6` (PRs into `next`, in review). No change for players
  or with `npc.navigation.enabled: false` (the default).
  1. **Why the whole group walked in.** A district's entry changed in the web app arrives over realtime as
     `EntityChanged` (the plugin clears its region → domain map) and `DomainAccessChanged` (the WorldGuard flag sync).
     Neither told NPC navigation. The group kept its "may enter" answers from before the change, and the NPC checks
     count a region missing from the map as open, so every follower outside walked in and the trespass guard counted
     nothing. A `/knk cache refresh` afterwards came too late for the followers who were already inside.
  2. **The fix.** Both realtime events now ask, coalesced into one run after half a second, for the roads' regions to
     be asked about again in place (the last known rule is kept until the API answers) and then send the availability
     event the refresh sends. Followers outside stop at the edge within about a second, without a refresh. Only while
     NPC navigation runs.
  3. **The gate region over the district's entry is not the cause.** The NPC entry rule judges each region on its own:
     a step into `district_1000004` and `gate_2000131` at once is allowed only when both may be entered, so a gate
     region that allows entry (or has no domain) never hides the district's denial. There is no region priority in
     the entry rule. The rule is now one core class (`DomainEntryRule`) shared by the server and the tests.
  4. **No false trespass for an NPC that crossed just before the change arrived.** An NPC's own trespass guard (the
     leader's, and any NPC with an order of its own) now takes a fresh look when an availability event comes, as the
     followers' guard already did. An entry made under the old rules is not judged by the new ones. Entries made after
     the plugin knew still count.
  5. **Tests.** New plugin scenario `npc-group-realtime-entry`: a district under a gate region on a real server, entry
     removed and restored through the plugin's realtime classes mid-group (CI `paper-boot` now has `MIN_SCENARIOS` 35).
     New knk-core `NavGroupDomainRulesTest` covers the realtime, `DomainAccessChanged` and refresh paths with the gate
     region; on `next` the realtime path fails it (followers enter). There are also new resolver tests, two
     `NpcNavigationRulesTest` cases and the knk-paper `NavigationDomainChangesTest`.
  - **Admin steps:** none (no `config.yml` key, no new node, no API change). Developer retest: Phase 4 step 10 as
    changed in the implementation plan (realtime on, no `/knk cache refresh`), posted on #593.
- **NPC navigation: NPCs stay on the stair at a turn over a ledge, and falls are counted**
  ([PandiO/knk-workspace#592](https://github.com/PandiO/knk-workspace/issues/592), the developer's L3 retest of
  [#491](https://github.com/PandiO/knk-workspace/issues/491) and [#492](https://github.com/PandiO/knk-workspace/issues/492);
  link L5 of the NPC navigation follow-ups chain, implementation plan 4b.2). knk-plugin and knk-workspace branches
  `claude/npc-followups-l5` (PRs into `next`, in review). No change for players or with `npc.navigation.enabled: false`
  (the default).
  1. **What makes NPCs fall at a stair corner like 1411 73 -537** (shown on `next` by a new scenario; the developer's
     retest probably ran an older jar). A road line that cuts a 90° turn at a ledge puts route points over
     the drop on the inside of the turn. K&K moved such a point onto a floor, and when there was none within 2 blocks of
     the stair it took the nearest floor within 12 blocks: the ground 7 blocks below. The NPC got a waypoint with its
     feet on the ground and walked off the corner (the same 74 → 67 as the developer's trace), and the next waypoints chained along the ground. Corner
     clearance did not help because it only kept away from walls, and the inside of this turn is a drop.
  2. **The fix, for any turn at a ledge.** A route point over a drop moves onto the walkable cell beside it (within a
     block, floor continuity kept), or is left out when there is none. It never goes to a floor further away. Every step
     between two waypoints must be a straight walk on floor; where one is not (a diagonal across a drop or round a wall
     corner), the cells between go in as extra waypoints. Corner clearance keeps clear of a drop on the inside of a turn
     as it does of a wall. The group's path and the followers' lanes follow the same rules, so a lane never points at the
     floor below a landing's corner. At the #492 landing this is reproduced only with a road line that cuts
     the inside of the turn; whether it is the cause at 1433 44 -518 waits for the developer's rerun.
  3. **Falls are counted.** `falls` in `/knk npc nav stats` (the `fell` event) stayed 0 for Citizens NPCs: the check
     needed the engine's fall distance, which stays near 0 for them. A fall is now told from a stair step by the body's
     speed (0.55 blocks per tick or faster downwards). On the corner scene on `next` it now reports the 7-block falls it
     missed.
  4. **Traces show the waypoints.** `/knk npc nav trace` writes a `# waypoints:` line each time the traced NPC gets a new
     stretch, so a trace shows whether a waypoint cuts a turn.
  5. **Tests.** New plugin scenarios `npc-ledge-corner` and `npc-landing-ranks` on a new scene with both spots in their
     real geometry. `npc-ledge-corner` failed on `next`, and `npc-landing-ranks` failed there with the cutting line
     (it passes on `next` with a line along the flights' middle). Both pass with the fix. CI `paper-boot` now has `MIN_SCENARIOS` 34. New knk-core
     tests are `LedgeCornerTest` and `WaypointChainTest`, with more cases in `GroupPathTest` and `RecentStepsTest`.
  - **Admin steps:** none (no `config.yml` key, no new node, no API change). Developer retest: the L3 steps 3–5 on
    [#521](https://github.com/PandiO/knk-workspace/issues/521), changed as posted on #592.
- **Plugin: kick and ban sent from the web app are carried out in game**
  ([PandiO/knk-workspace#574](https://github.com/PandiO/knk-workspace/issues/574); developer decisions 2026-11-15 on
  [#565](https://github.com/PandiO/knk-workspace/issues/565); link L7 of the Chain 3 follow-ups chain,
  [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-plugin and knk-workspace branches
  `claude/web-kick-ban-574`, merged into `next` 2026-11-15 (knk-plugin#42 `1adcb497`, docs knk-workspace#596); on the
  trunk when the developer promotes `next`. For players: a kick from the web app disconnects
  them with the staff member's reason; a web ban puts them on the server's ban list like `/ban` (permanent, lifted with
  `/pardon`) and disconnects them if online.
  1. **Handlers.** The plugin handles the realtime `PlayerKick` / `PlayerBan` v1 events
     ([contract](specs/realtime-signalr/DESIGN.md), § 6.10): kick if online here; ban = permanent entry on Paper's
     profile ban list with the reason and the staff member as source (an existing entry is kept), then the kick. A
     repeated `actionId` is skipped; a malformed payload is logged and ignored. Bukkit calls on the main thread.
  2. **Texts.** New `config.yml` keys `realtime.moderation.kick-default-reason` and `realtime.moderation.ban-message`
     ([configuration reference § 4.3](guides/admin/plugin-configuration.md#43-realtime)).
  3. Docs: [smoke test § 7](guides/player-profile-smoke-test.md) steps 8–10 and 18 tagged with the plugin tests,
     realtime DESIGN § 6.10 item 8, configuration reference.
  - **Admin steps:** merge the `realtime.moderation` block into the dev and alpha `config.yml` (optional: defaults
     apply when missing). Needs `realtime.enabled: true`. Deploy order: the API with L6 (#565) first or together; a
     plugin without L7 ignores the events ("no handler"), so staff would see the action accepted without effect.
- **Plugin: the plain `/heal` is K&K's also on servers with WorldGuard**
  ([PandiO/knk-workspace#580](https://github.com/PandiO/knk-workspace/issues/580); developer decision 2026-11-15:
  option 1) — knk-plugin and knk-workspace branches `claude/heal-takeover-580` (PRs into `next`).
  1. **What players notice.** A player given `knk.heal` in-house (a rank or `/knk user <player> perm grant knk.heal`)
     can now use `/heal`; before, WorldGuard's own `/heal` answered "You don't have permission to do that." Ops are
     healed by K&K's command too ("Replenished <n> health."). `/knightsandkings:heal` keeps working, and WorldGuard's
     command stays reachable as `/worldguard:heal`.
  2. **How.** WorldGuard enables before K&K and registers its `/heal` first, so K&K's was left as
     `/knightsandkings:heal` only. At startup K&K now points the plain `heal` label at its own command
     (`CommandLabelTakeover`), and again once every plugin is enabled. The startup log says "/heal now runs
     KnightsAndKings's command instead of WorldGuard's" and warns if any other K&K command name is held by another
     plugin (none today: WorldGuard's other player commands have no K&K twin).
  3. **Tests.** New plugin scenario `player-heal-needs-grant` (CI `paper-boot`, `MIN_SCENARIOS` 32 with the NPC group scenarios of #522; failed before the
     fix, passes with it) and unit tests `CommandLabelTakeoverTest`. Docs: [in-game commands](guides/users/commands.md),
     [smoke test](guides/heal-takeover-smoke-test.md), [writing a plugin scenario § 1](guides/developer/plugin-scenarios.md),
     [CI § 7.1](guides/developer/ci.md).
  - **Admin steps:** none (no `config.yml` key, no new node, no API change).
- **NPC navigation: formations narrow before they fold, followers can finish their trip**
  ([PandiO/knk-workspace#522](https://github.com/PandiO/knk-workspace/issues/522) for
  [#493](https://github.com/PandiO/knk-workspace/issues/493) and [#507](https://github.com/PandiO/knk-workspace/issues/507);
  link L4 of the NPC navigation follow-ups chain, implementation plan 4b.3). knk-plugin and knk-workspace branches
  `claude/npc-followups-l4` (PRs into `next`, in review). No change for players or with `npc.navigation.enabled: false`
  (the default).
  1. **Narrowed formations (#493).** A group steps down 3 → 2 abreast before it folds into a column, and folds only
     where 2 abreast do not fit (gates, stairs): `ranks` from `group-ranks-width` down to 2, `cluster` 3 then 2, the
     `escort-ring` as its rings, then rows of 3 with the leader in the middle of the second row, then 2 abreast, then a
     column with one escort ahead. NPCs in a row walk shoulder to shoulder (`group-lateral-spacing` 1.0) and rows are
     1.5 blocks apart (`group-spacing`, was 2.0), so 3 abreast fit a 3-wide road and 2 abreast a 2-wide one; where a
     road's line runs along one side, the lanes shift half a block at a time to fit.
  2. **No switching at every lamp post.** A narrower width (still 2 abreast or more) or a wider one is taken only when
     it lasts `group-width-hysteresis-blocks` (3) along the path; a gate or a stair makes a column at once. The width
     that fits is worked out once per path point, so the tick cost per NPC stays as it was.
  3. **Followers that finish their trip (#507).** `group-followers-finish-trip` (default `false`, per world, region,
     template, assignment and `/knk npc nav group <n> … finish-trip|follow-leader`): when it is on and the leader has
     arrived, followers still on their way (held at a gate or a district edge) walk on to their place at the goal first,
     report (`… finished its trip at x y z`, event `group_finish_trip`, a member listener for later behaviour such as a
     courier handing over goods), then follow the group. Off, they follow the leader: a follower held at a gate when the
     group turned back now waits beside the road for the column instead of walking on to the old goal.
  4. **Logs and stats.** `group <n> … narrows to 2 abreast: the path is too narrow for 3 abreast at x y z`,
     `… widens to 3 abreast`, `… folds into a column: the path is too narrow for 2 abreast`, `… takes up 3 abreast
     again`; events `group_narrow`, `group_widen`, `group_fold`, `group_reform`, `group_finish_trip`; the groups line of
     `/knk npc nav stats` has `widths: narrows N, widens N | folds N, reforms N, folded now N | abreast now k |
     finished trips N (finishing now N)`.
  5. **Found on a real server and fixed.** Lanes keep clear of wall edges and are back on the road's centre 2 blocks
     before a narrow opening; flights of stairs are walked as a column; followers stopped at a door or a district edge
     queue a spacing apart instead of crowding one spot; a follower a block short of a door that starts closing steps
     back instead of walking into it (a portcullis blocks a body long before it is shut), and only one standing under
     the door walks on out.
  6. **Tests.** knk-core unit tests for every formation's widths, the per-point cache, step-down, hysteresis, the
     toggle, the queue and the door rule; three plugin scenarios on a real Paper server with Citizens
     (`npc-group-narrows`, `npc-group-gate-finish-trip`, `npc-group-access-change`); with #543's three and #540's
     six player scenarios, CI's `paper-boot` now expects 31 scenarios.
  7. **Admin steps** (restart): merge the three new keys and set `group-spacing: 1.5` where `config.yml` still says 2.0:

     ```yaml
     npc:
       navigation:
         group-spacing: 1.5
         group-lateral-spacing: 1.0
         group-width-hysteresis-blocks: 3
         group-followers-finish-trip: false
     ```

     Then run the developer test steps of plan 4b.3 (posted on #522), which include the #490 audit re-run.

- **Plugin scenarios: scripted players (server-side fake players), headless bot tests kept off**
  ([PandiO/knk-workspace#540](https://github.com/PandiO/knk-workspace/issues/540); developer decision 2026-11-15:
  build both). knk-plugin and knk-workspace branches `claude/scripted-players-540` (PRs into `next`). No change for
  players or real servers: everything runs only with `testing.scenarios.enabled` (off by default), and no
  `config.yml` key was added.
  1. **Fake players in scenarios.** `scene.player(name, …)` joins a fake player through the server's player list (an
     NMS `ServerPlayer` on an in-memory connection, all NMS code by reflection in `scenario/NmsFakePlayer`), so join
     and quit events, permission attachments and the plugin's join handling run. A scenario gives it a fake account
     and in-house grants (primed into the live caches), runs commands and chat through the server's real paths,
     clicks menu slots and moves with client packets, teleports it and reads every message it was sent
     ([writing a plugin scenario § 5](guides/developer/plugin-scenarios.md#5-players)).
  2. **Six player scenarios** in CI's `paper-boot` (28 scenarios, `MIN_SCENARIOS` 28): a command refused without and
     allowed with an in-house grant (`/feed`), chat with title and group colours and the `[STAFF]` tag, the join's
     loading hold (an owner never held, a rejoin held again), an InventoryMenu click (a locked button, opening the
     next menu, closing it), and gate smoke test § 2 steps 16 and 17 for players (`/tp` into a closed door, a rejoin
     inside a door that closed meanwhile). `knk scenario run player-*` runs a group by prefix.
  3. **Found on the way:** on a server with WorldGuard the plain `/heal` is WorldGuard's command, so in-house
     `knk.heal` grants never apply ([#580](https://github.com/PandiO/knk-workspace/issues/580)).
  4. **Headless bot tests, off.** `tools/bot-tests` (Mineflayer 4.39.0, pinned with a lock file) joins bots through
     the real protocol; the example `first-join` covers the real login path. CI runs them only with the repository
     variable `BOT_TESTS_ENABLED` set to `true`, and reports on every run whether the pinned and the newest Mineflayer
     list Minecraft 26.3 (today both stop at 26.1). How to switch them on: [CI § 7.3](guides/developer/ci.md#73-headless-bot-tests-off-until-mineflayer-supports-263).
  5. **Boot log check:** errors printed with `printStackTrace()` (one timestamped line per frame) are now joined to
     their entry, so the join's unreachable-API error is excused like the others.

- **Plugin CI: Citizens on the Paper boot test, NPC navigation scenarios on a fake road network**
  ([PandiO/knk-workspace#543](https://github.com/PandiO/knk-workspace/issues/543); developer decision 2026-11-15:
  pinned download). knk-plugin and knk-workspace branches `claude/citizens-ci-543` (PRs into `next`). No change for
  players or real servers: `npc.navigation.enabled` and `testing.scenarios.enabled` stay off by default.
  1. **Citizens on the CI server.** `paper-boot.yml` installs Citizens 2.0.44 build 4269, the server jar of
     `citizensApiVersion`, pinned by URL and SHA-256 (the pin came with #521; this change caches Citizens' downloaded
     libraries and documents bumping it, [CI § 7.2](guides/developer/ci.md#72-citizens-on-the-ci-server)). Bump it
     together with `citizensApiVersion`; if Citizens' Jenkins prunes the build, pin a newer build and its API snapshot
     at once.
  2. **NPC navigation checked at boot.** `boot-test.sh --npc-navigation` turns on `npc.navigation.enabled`, and the log
     check requires Citizens enabled and `[NPC] navigation: Citizens …`; a Citizens `ERROR` or stack trace fails the
     job like a KnK one (no Citizens line needed an excuse).
  3. **Three NPC scenarios** (`MIN_SCENARIOS` 22 with the three corner scenarios of #521): `npc-walks-road-route` (an
     NPC walks a road route and arrives), `npc-keeps-to-road-around-obstacle` (it keeps within 2 blocks of the road
     where open ground round an obstacle would be shorter) and `npc-group-keeps-spacing` (a column of three keeps its
     2-block spacing). The road is a `RoadNetworkSnapshot` routed through the navigator's own adapter
     (`NavigationService.planRoadFor`); the NPCs come from the running Citizens adapter. Each was seen failing with its
     behaviour broken (road graph ignored, formation slots shortened, waypoints never walked).
  4. Docs: [CI § 7](guides/developer/ci.md#7-plugin-the-paper-boot-test),
     [writing a plugin scenario](guides/developer/plugin-scenarios.md), the NPC implementation plan's developer tests
     (Phase 1 step 1, Phase 2 steps 3 and 4, Phase 4 step 3 tagged `[partly automated: …]`).
  - **Admin steps:** none (CI only; the plugin's `config.yml` is unchanged).
- **NPC navigation: wall corners, stuck recovery on the NPC's own floor, stuck counted per spell**
  ([PandiO/knk-workspace#521](https://github.com/PandiO/knk-workspace/issues/521) for
  [#508](https://github.com/PandiO/knk-workspace/issues/508), [#491](https://github.com/PandiO/knk-workspace/issues/491)
  and [#492](https://github.com/PandiO/knk-workspace/issues/492); link L3 of the NPC navigation follow-ups chain,
  implementation plan 4b.2). knk-plugin and knk-workspace branches `claude/npc-followups-l3` (PRs into `next`, in
  review). No change for players or with `npc.navigation.enabled: false` (the default).
  1. **Wall corners (#508).** At a turn of its route an NPC keeps `corner-clearance` (1 block) from walls on the
     inside of the turn, as far as the road allows; straight stretches may still run along a wall. Citizens moves on to
     the next waypoint within `waypoint-margin` (0.5 block, Citizens' own default is 1), so the NPC walks into the
     corner square and turns there instead of cutting the corner.
  2. **The stair corner (#491).** The 7-block fall at 1411 73 -537 came from Citizens' 1-block margin: the NPC turned
     a block before the corner and walked the diagonal over the drop. With the margin and the corner kept in the
     stretch, and a shortcut only where every cell under the body's width is standable floor, it walks round.
  3. **Recovery on the NPC's own floor (#492).** A stuck NPC and a group's follower aim at a point ahead along the
     path on the floor they stand on, never at the flight above or below (the old targets 1421 84 -516 and
     1424 48 -520). A leader below the route's end (37 blocks up, 4 across) plans the road instead of a short trip.
  4. **The recovery ladder.** A stuck NPC takes one step per try: back-off along its last footsteps, side-step away
     from the wall, one local leg ahead, then a replan; 1 s (`recovery-wait-ticks`) between tries, at most
     `max-retries` steps, the log's count never past the cap (no more "retry 4 of 3", no four lines in one second).
     Stuck is noticed after 2 s instead of 3 (`stationary-ticks`, `no-progress-ticks` 40). A follower takes the same
     ladder inside its group, never holds up the ones behind, and a left-behind follower's tries double from 5 s up to
     60 s (the 481 `group_rejoin` of #492 become tens).
  5. **What the counters meant (#491) and mean now.** `stuck_engine 14456` against `recovered 0` was not 14456 stuck
     NPCs: `stuck_engine` counted every Citizens cancel while an NPC moved, its stationary check and every failed path
     search of a retry (four per burst, a burst every 5 s), and `recovered` counted only a recovery leg that arrived;
     none did, because each aimed at another floor. The NPCs got free on the 5-second replan, the "second try" seen in
     game. Now `stuck_engine` and `stuck_no_progress` count stuck spells (one per spell, by what noticed it first),
     `freed_back_off`, `freed_side_step`, `freed_local_leg`, `freed_replan` and `not_freed` end them, `recovered` is
     their sum, `recovery_no_path` counts failed engine searches and `fell` counts falls of 3 blocks or more.
     `/knk npc nav stats` shows `stuck near a wall: N, freed by: …` and `stuck elsewhere`, steps per stuck, the
     longest still and falls; the group line shows `road plans per group event` and `local legs at once` instead of
     `most plans at once`.
  6. **Tests.** knk-core unit tests for corners, own-floor targets, the ladder and the counters; three plugin
     scenarios on a generated corner test scene (`npc-corners-line`, `npc-corners-walk` with 6 NPCs and a group of 6
     in `ranks` for 90 s, `npc-stuck-ladder`); CI's `paper-boot` server now has a pinned Citizens build (2.0.44
     build 4269, SHA-256 checked). `/knk npc nav scene corners` builds the scene on a test server.
  - **Admin steps:** merge the new and changed keys into `config.yml` (restart), from the
    [configuration reference § 4.27](guides/admin/plugin-configuration.md#427-npc):

    ```yaml
    npc:
      navigation:
        stationary-ticks: 40
        no-progress-ticks: 40
        max-retries: 3
        recovery-wait-ticks: 20
        corner-clearance: 1.0
        waypoint-margin: 0.5
    ```

    A server whose `config.yml` still says 60 for the two `*-ticks` keys keeps 60. To test: the Phase 4b developer
    test (L3) in the [implementation plan](specs/npc-platform/IMPLEMENTATION_PLAN.md#4b2-link-l3-521-wall-corners-and-stuck-recovery-508-491-492).
- **Smoke-test guides: every step in full again, automated steps tagged**
  ([PandiO/knk-workspace#511](https://github.com/PandiO/knk-workspace/issues/511); docs only, developer decision
  2026-11-15). knk-workspace `claude/smoke-guides-full-steps` (PR into `next`). The #511 backfill had shortened
  automated steps to one line; the 15 guides it touched (admin navigation, dashboard access, data and feedback
  primitives, entity detail, form step conditions, gate, kit grant delivery, link code, lootbox area region, player
  profile, realtime § S5, relation picker, settings pages, town streets) have their full manual instructions back, so
  every step can still be run by hand. A step a suite covers starts with `[automated: <test>]`, or
  `[partly automated: <test>; by hand: <what is left>]`; status lines count the tagged steps. What is automated did not
  change. The developer guides on plugin scenarios and web app testing describe the tag.
- **NPC navigation design: wall corners, stuck recovery, narrowed formations, followers that finish their trip**
  ([PandiO/knk-workspace#519](https://github.com/PandiO/knk-workspace/issues/519); design only, docs, nothing changes in game).
  knk-workspace `claude/npc-followups-l1` (PR into `next`, in review). BEHAVIOR_MODEL § 2 NAV-19–NAV-23 and
  implementation plan Phase 4b for links L3 (#521: #508, #491, #492) and L4 (#522: #493, #507); defaults approved by
  the developer 2026-11-15.
- **NPC groups: followers keep to the rules and out of closing gates**
  ([PandiO/knk-workspace#506](https://github.com/PandiO/knk-workspace/issues/506), part of
  [#507](https://github.com/PandiO/knk-workspace/issues/507); link L2 of the NPC navigation follow-ups chain,
  [#520](https://github.com/PandiO/knk-workspace/issues/520)) — knk-plugin and knk-workspace branches
  `claude/npc-followups-l2`, merged into `next` 2026-11-15 (knk-plugin#31, docs knk-workspace#536); on the trunk when the developer promotes `next`. No change for players or with
  `npc.navigation.enabled: false` (the default).
  1. **Access change in the middle of a group (#506).** A gate or availability event hands every follower its
     waypoints again in the next tick; the followers outside a district whose entry was removed stop at its edge, the
     ones inside walk on, and all follow once entry is allowed again. After `/knk cache refresh` the region → domain
     map is warmed again for the roads' regions and the NPCs hear of the change a second time: before, the NPC checks
     saw every district as open right after a refresh, and the group walked in. Followers have a trespass guard of
     their own, so `rules: trespasses` and `knk_npc_nav_events_total{event="trespass"}` count them too (log line
     `TRESPASS <npc> entered <region> … (a follower of group <n>)`).
  2. **No push by a closing gate (#507, the push only).** The gate's state event comes when the close starts. A
     follower that still has to pass the door stops a block short of the door's box (its closed footprint and its
     captured closed and opened regions); one already in it walks on out. The leader walks on and the rest follows
     when the gate opens, as before (developer decision 2026-11-14 on #507; the followers-finish-trip toggle comes
     with link L4).
  3. Follow-ups filed: #533 (a realtime domain change empties the map without warming it again), #534 (a single NPC
     or leader in a door's box when it starts closing).
  - **Admin steps:** none; no new `config.yml` key, no migration. Deploy the plugin. To test: the Phase 4 developer
    test steps 9 and 10 in the [implementation plan](specs/npc-platform/IMPLEMENTATION_PLAN.md).
- **Plugin: 13 more plugin scenarios and a freeze test replace evening checks in game**
  ([PandiO/knk-workspace#511](https://github.com/PandiO/knk-workspace/issues/511), plugin part; developer-facing, nothing
  changes in game). Merged into `next` 2026-11-15 (knk-plugin#35, merge `b2c5dff0`; docs knk-workspace#544); on the trunk when the developer promotes `next`.
  - **Scenarios** (CI `paper-boot`, a real Paper server with fake API data; 3 → 16, `MIN_SCENARIOS` 16): gate safety
    with mobs, a dropped item and a minecart standing in for players (moved out on their own side, out of a two-deep
    door, never into the next door's opening, opening leaves neighbours alone, door blocks never suffocate while a wall
    does); a lootbox area's region renamed and replaced in place over the region callback with its drawn bounds and
    flags; the temp-region sweep keeping an area's temp region; boxes asked for on the ground inside an area's Y range,
    under a roof, and none after lootboxes are switched off.
  - **Unit test:** `AdminFreezeListenerTest` (a frozen player can't walk, chat or run commands other than `/msg` and
    `/r`; teleports and damage).
  - **Smoke tests:** the automated steps are marked in the gate, lootbox area region, settings pages, player profile,
    kit grant delivery, link code and realtime § S5 guides; steps that need a player wait for simulated players
    ([#540](https://github.com/PandiO/knk-workspace/issues/540)). No plugin behaviour changed; `testing.scenarios.enabled`
    stays off by default.
  - **Admin steps:** none.
- **Plugin: the 52 tests that CI skipped now run, with MockBukkit**
  ([PandiO/knk-workspace#499](https://github.com/PandiO/knk-workspace/issues/499); developer-facing, nothing changes
  in game). Merged into `next` 2026-11-14 (knk-plugin#32, merge `0810a6c7`; docs knk-workspace#539); on the trunk when the developer promotes `next`.
  - The seven `requires-bukkit` test files of `knk-paper` pass and run in `./gradlew test` and CI; the tag exclusion and
    the `taggedTest` task are gone. knk-paper: 2,690 tests before, 2,735 after (all green; 18 skipped as before).
  - MockBukkit (`mockbukkit-v26.3` 4.120.0) is a test-only dependency (developer decision 2026-11-14) for tests that need
    Bukkit statics; its JUnit 6 dependency is excluded, the project stays on JUnit 5.
  - Stale tests were brought up to date, none deleted or skipped: the removed in-game account creation flow (KNG-67,
    KNG-208), `/account link` argument handling, Component messages, existing users looked up by UUID.
  - **Admin steps:** none.
- **Plugin features can prove themselves on a real server in CI: in-plugin test scenarios**
  ([PandiO/knk-workspace#421](https://github.com/PandiO/knk-workspace/issues/421); developer-facing, nothing changes for
  players). Merged into `next` 2026-11-14 (knk-plugin#30, merge `309d3580`; docs knk-workspace#532); on the trunk when the developer promotes `next`.
  - A scenario builds a small scene on a test server (blocks, a WorldGuard region, mobs, fake API data), plays it out
    over server ticks and asserts the result. The runner is platform-free in `knk-core` (`core/scenario/`), the Bukkit
    glue and the scenarios in `knk-paper` (`paper/scenario/`). Each scenario logs `KNK-SCENARIO PASS|FAIL <name>`, then
    a summary line.
  - `/knk scenario list | run <name|all>` (node `knk.admin.scenario`) exists **only** with the new
    `testing.scenarios.enabled: true`; off by default, so every real server behaves exactly as before.
  - Three scenarios: a portcullis opens and closes (`gate-open-close`), a closing door moves a mob out of its doorway
    without suffocating it (`gate-closing-moves-entity-out`, KNG-106), TNT breaks nothing outside every region but does
    inside one (`global-region-explosion`).
  - CI: the Paper boot test (`paper-boot.yml`) runs every scenario after the boot check and fails on a failed or
    missing scenario or a missing summary; the result table is in the job summary. About 4 s of scenarios in a
    1.5-minute job.
  - Guide: [writing a plugin scenario](guides/developer/plugin-scenarios.md); [CI § 7.1](guides/developer/ci.md#71-in-plugin-scenarios).
  - **Admin steps:** none. Don't add the `testing` block to dev, alpha or production configs; a missing block is off
    ([plugin configuration § 4.28](guides/admin/plugin-configuration.md#428-testing)).
- **Smoke-test fixes on `next` from 2026-11-14** (PandiO/knk-workspace#484, #485, #487) — knk-web-api, knk-plugin and
  knk-workspace branches `claude/smoke-fixes-484-485-487` (PRs into `next`, in review, not merged). **Deploy order:**
  API and plugin together (no migration). One entry per issue follows.
- **The link code reads XXXX-XXXX in game**
  ([PandiO/knk-workspace#484](https://github.com/PandiO/knk-workspace/issues/484); API only). The code from
  `/account link` is shown with the dash after four characters, as the website's code field and the claim code show it
  (it was `7KL-MZU0T`). `LinkCodeResponseDto.formattedCode` now comes from `LinkCodeService.FormatClaimCode`, the one
  formatter; the plugin shows that field unchanged, and the web app's field already ignored the dash when pasting.
  Checklist: [link code and registration confirmation smoke test § 1](guides/link-code-and-registration-confirmation-smoke-test.md).
  - **Admin steps:** none; deploy the API.
- **The game confirms a registration made with the link code**
  ([PandiO/knk-workspace#485](https://github.com/PandiO/knk-workspace/issues/485); API and plugin). After a player
  registers on the website with the code from `/account link`, the game tells them once that their website account is
  ready and linked, with the masked email and their Minecraft name to log in with: within seconds when online (realtime
  push, or the 2 s poll with realtime off), else about 2 s after the next join. A failed or expired code says nothing.
  The API queues an `AccountLinked` notification at registration (it already did for Account-page links and claims),
  now with `via` (`register`, `link`, `claim`); the plugin shows the new `messages.web-account-registered` for
  `register` and keeps `admission.account-linked` for the others. Fixed in passing: with the realtime hub connected the
  notification poll is paused, so a notice queued for an offline player only showed after the next hub reconnect; a
  join now drains the queue (`NotificationJoinDrain`). Checklist:
  [smoke test §§ 2–5](guides/link-code-and-registration-confirmation-smoke-test.md); key reference
  [plugin configuration § 4.18](guides/admin/plugin-configuration.md#418-messages).
  - **Admin steps:** deploy API and plugin. Plugin `config.yml`, optional (a missing key uses the jar's text):

    ```yaml
    messages:
      # PandiO/knk-workspace#485: shown once after a game-first registration. Placeholders: {maskedEmail}, {name},
      # {url} (web.public-url; lines that use it are left out while it is empty).
      web-account-registered: "&aYour website account is ready and linked to this Minecraft account.\n&aLog in at &e{url} &awith &e{maskedEmail} &aor your Minecraft name &e{name}&a.\n&cNot you? Tell staff right away."
    ```
- **Lootbox spawn areas keep the region exactly as drawn**
  ([PandiO/knk-workspace#487](https://github.com/PandiO/knk-workspace/issues/487), developer decision 2026-11-14;
  API and plugin; changes #34 below). A spawn area's region drawn in the web form keeps its outline and its height
  (e.g. Y 64–68) when it is renamed to `lootbox_area_<id>` on save or on a re-run of the region step; it is no longer
  stretched to the world's full build height. Boxes spawn on the ground inside it, also when the region is under a roof
  or an overhang (the spawner looks for good ground with two air blocks inside the region's Y range when the column's
  surface is above it). The rename, in-place replacement, reserved `area_<number>` names, cleanup protection and
  `finalize-temp-names` are unchanged; `/knk lootbox area create` still makes full-height regions. The API no longer
  sends `fullHeight=true` and the plugin ignores it. See
  [managed-worldguard-regions.md](architecture/managed-worldguard-regions.md) §7 and the
  [smoke test](guides/lootbox-area-region-smoke-test.md) § 1 step 4 and § 2 step 2.
  - **Admin steps:** deploy API and plugin together (no migration, no setting, no `config.yml` key). Import form seed
    `LootboxSpawnArea - Default (seed v3)` (`Data/FormConfigurationSeeds/LootboxSpawnArea.json`, descriptions only) and
    make it the default. Areas saved under #34 keep their full-height region until their region step is run again.
- **Plugin parts of UX chains 2 and 3 into `next`** (PandiO/knk-workspace#184, #31, #34, #261, #264, #269) — knk-plugin,
  knk-web-api and knk-workspace branches `claude/plugin-chains-into-next` (PRs into `next`, merged 2026-11-13: knk-plugin#20 `745fcf6`, knk-web-api#18 `c20899c`,
  knk-workspace#393 `6250d12`; developer's go 2026-11-13). The plugin branch merges chain 3 P3 `claude/temp-region-drafts-269` (which contains P1, R3, R2 and R1)
  and P2 `claude/realtime-client-flaky-264`; the API branch merges P3's API branch (contains R3) and is merged into
  `next` 2026-11-13 (knk-web-api#18 `c20899c`). The API parts of #184 and #261 are on `master` since 2026-11-12. **Deploy order:** back up the database, deploy the API and run
  `dotnet ef database update` (one new migration here, `AddTempRegionReleases`), then the plugin. One entry per feature
  follows.
- **Erasure retest fixes: first join without a cached user, erasure feed in PascalCase, test walkers out of the
  water** (PandiO/knk-workspace#486 retest, #490 remainder; plugin only). knk-plugin branch
  `claude/erasure-first-join-486-retest`, merged into `next` 2026-11-14 (knk-plugin#29, `058f93a`); on the trunk when the developer promotes `next`. The developer's retest of 2026-11-14
  (plugin `0.1.0+a760c4a4`) still got "Welcome back" in § S5 steps 1, 4, 5 and 5a. Two causes, both fixed:
  1. **The first join was decided from the user cache at `PlayerJoinEvent`**, which an erasure empties (and so does a
     website account that has no UUID yet), so the decision was skipped (`First-join kits: no cached user ... skipped`).
     It is now made once the join's account sync knows the account (`UserAccountListener`), with the erasure mark taken
     there whatever the cache holds, and an account the API created while the player connected (pre-login or the
     join's sync) counts as new, also with realtime off. One decision drives the welcome, the quiet discovery minutes
     and the first-join kit request. The log line is now `First join: <name> (user <id>) ...`.
  2. **The catch-up never read the feed:** the API sends `GET api/privacy/erasures` in PascalCase (`Items`,
     `ErasureId`, `LastId`, ...), the plugin read camelCase only, so every page parsed empty, nothing was applied and
     `erasure-feed.json` never moved. The plugin now reads both casings (no API change). The other REST DTOs of
     realtime #178 to #184 were checked: the API's world-task DTOs name their fields in camelCase explicitly; only the
     erasure feed lacked the attributes.
  3. **#490:** the test walkers (`/knk npc test spawn`) still drowned (audit: `DROWNING 1088`): Citizens' path search
     walks through and over water to reach a dry target, and seagrass, kelp and bubble columns passed the dry-spot
     check. Their own path search now never enters water or lava, and a spot needs a body's room with no fluid at all.
     No K&K listener records anything for an NPC's drowning damage.
  Design [realtime DESIGN §7.5](specs/realtime-signalr/DESIGN.md); smoke test
  [§ S5 steps 4, 5, 5a and 7](guides/realtime-smoke-test.md).
  - **Admin steps:** none (no `config.yml` key, no API change); deploy the plugin. With the fix, the first hub connect
    applies the erasures the feed holds that this server has not applied yet (`erasure-feed.json` starts at
    `"lastId":0` because no page was ever read): expect `Erasure #N applied` lines for older erasures, which are
    harmless (every step is idempotent; a UUID now in use by a fresh account comes with `formerUuid: null`).
- **An erased account's player is greeted as new, also after a restart** (PandiO/knk-workspace#486, follow-up of
  #184 from the developer's smoke test 2026-11-14; plugin only). knk-plugin branch `claude/erasure-first-join-486`,
  merged into `next` 2026-11-14 (knk-plugin#25); on the trunk when the developer promotes `next`. Before, a player whose
  account was erased while the server was down got "Welcome back" and no quiet discovery minutes on their next join:
  Minecraft's own player files are kept by design, and nothing marked the join as new. Now every applied erasure marks
  "next join is a first join" (`erasure-first-joins.json`, a hash and a time, no UUID or name; taken at the next join,
  dropped after 90 days), and a join right after a start waits at most 5 s for the first catch-up. Design
  [realtime DESIGN §7.5](specs/realtime-signalr/DESIGN.md); smoke test [§ S5 steps 4, 5 and 5a](guides/realtime-smoke-test.md).
  - **Admin steps:** none (no `config.yml` key, no API change); deploy the plugin. The file
    `plugins/KnightsAndKings/erasure-first-joins.json` appears after the first erasure.
- **GDPR account erasure reaches the game server at once (realtime S5)**
  ([PandiO/knk-workspace#184](https://github.com/PandiO/knk-workspace/issues/184), chain 2 R1; plugin part). With
  `realtime.enabled: true` the plugin acts on the API's `AccountErased` push: an online player is kicked with a neutral
  message (a siege vault they hold is given back first, once), then everything the server keeps about the account is
  deleted (offline security store, user and permission caches, discovery and statistics spools, PM-log queue and local
  log lines, offline siege vaults, hub-outage return point). Minecraft's own player files are listed for the owner, not
  deleted. Every hub (re)connect catches up through `GET api/privacy/erasures?since=`; an erasure with a failed step
  keeps the feed position before it and runs again at the next catch-up. With realtime off nothing new
  runs; the hourly offline-cache re-check stays the backstop. Checklist: [realtime smoke test § S5](guides/realtime-smoke-test.md);
  design: [DESIGN §7.5](specs/realtime-signalr/DESIGN.md).
  - **Admin steps:** API part already on `master` (migration `AddPrivacyErasureEvents`, optional
    `Privacy__ErasureFeedUuidRetentionDays`, default 35). Plugin: new optional block under `realtime:` in `config.yml`
    (defaults below; a missing block uses them). The push needs `realtime.enabled: true` and `api.auth.type: apikey`.
    For the smoke test only: `Privacy__GraceDays=0` on the dev API (put it back afterwards).

    ```yaml
    realtime:
      erasure:
        kick-message: "Your account data has been deleted."
        settle-seconds: 2          # wait between kick and deletion, 0-30
        feed-file: "erasure-feed.json"
        minecraft-files-list: "erasure-minecraft-files.txt"
    ```
- **Siege startup work retried when the API is back, also with the realtime hub off**
  ([PandiO/knk-workspace#31](https://github.com/PandiO/knk-workspace/issues/31), chain 2 R2; plugin only). When the API
  was down at server start, the siege's startup-only work (abort the previous run's unfinished matches, restore gates a
  crash left locked, fetch the runtime config with its lobbies and the title brackets) runs again by itself once the API
  connectivity turns UP, in that order, and on a fallback retry (30 s, 1 min, 2 min, then every 5 min) while anything is
  left and the API is not DOWN. `/siege admin reload` is no longer needed. With the hub on, the reconnect and the UP
  transition share one runner (each step runs once). Checklist: [API outage smoke test § #31](guides/api-outage-smoke-test.md).
  - **Admin steps:** none (no migration, no setting, no `config.yml` key); deploy the plugin.
- **Lootbox spawn areas keep a region drawn in the web form**
  ([PandiO/knk-workspace#34](https://github.com/PandiO/knk-workspace/issues/34), chain 2 R3; API and plugin). A region
  drawn through the LootboxSpawnArea form's region task is renamed from `tempregion_worldtask_<n>` to
  `lootbox_area_<id>` when the area is saved (stretched to the world's full build height until #487, above, which
  keeps the drawn height); before, the 14-day
  temp-region cleanup deleted it and the area stopped spawning. Re-running the region step replaces the previous region
  in place. The cleanup also asks the lootbox areas before deleting a temp region, `POST /api/Regions/finalize-temp-names`
  renames temp-named areas, and area names `area_<number>` are reserved. See
  [managed-worldguard-regions.md](architecture/managed-worldguard-regions.md) §7 and the
  [smoke test](guides/lootbox-area-region-smoke-test.md).
  - **Admin steps:** deploy API and plugin together (no migration, no setting, no `config.yml` key). Import form seed
    `LootboxSpawnArea - Default (seed v2)` (`Data/FormConfigurationSeeds/LootboxSpawnArea.json`; with #487, seed v3
    instead). Areas still on a temp
    name: run `POST /api/Regions/finalize-temp-names` once.
- **Kit "Grant" from the web app reaches the player in game**
  ([PandiO/knk-workspace#261](https://github.com/PandiO/knk-workspace/issues/261), chain 3 P1; plugin part). The plugin
  hands a web grant's items over with the `/kit give` placement: online within seconds (realtime push, or the 2 s poll
  with realtime off), offline on the next join, after a siege when granted during one (also when the player entered
  the siege while the delivery was being taken). It takes each delivery at the
  API before placing it, so a grant is never handed over twice. `/kit give` in game is unchanged; earlier web grants
  are not delivered retroactively (grant again). Design [kits DESIGN §4.7](specs/kits/DESIGN.md); checklist
  [kit grant delivery smoke test](guides/kit-grant-delivery-smoke-test.md).
  - **Admin steps:** API part already on `master` (migration `AddKitClaimDelivery`); deploy the plugin. No setting, no
    `config.yml` key.
- **Realtime client: flaky stop test fixed** ([PandiO/knk-workspace#264](https://github.com/PandiO/knk-workspace/issues/264),
  chain 3 P2; plugin). `RealtimeClient.stop()` asks the transport to close before it reports STOPPED, which removes the
  race behind the flaky `RealtimeClientTest.stopClosesAndNeverReconnects`. No visible change in game.
  - **Admin steps:** none.
- **Temp regions of abandoned drafts go within minutes, not after 14 days**
  ([PandiO/knk-workspace#269](https://github.com/PandiO/knk-workspace/issues/269), chain 3 P3; API and plugin). A region
  drawn through a form's region task (`tempregion_worldtask_<n>`) is released when its draft is deleted in Saved
  Progress, when its task is cancelled, fails or expires after a game server held it, or when the world-task sweep
  removes its session; the game server removes it every few minutes once no domain, sub-region, lootbox area, road edge
  or draft names it and it isn't renamed. The daily 14-day cleanup stays the backstop. See
  [managed-worldguard-regions.md](architecture/managed-worldguard-regions.md) §7 and the
  [world-task smoke test § 7](guides/world-task-hardening-smoke-test.md#7-temp-regions-of-abandoned-drafts-269-in-next).
  - **Admin steps:** API first: `dotnet ef database update` (additive migration `AddTempRegionReleases`, one table);
    optional `WorldTasks__TempRegionReleaseGraceMinutes` (5) and `WorldTasks__TempRegionReleaseKeepDays` (30). Then the
    plugin, with one new optional key (a plugin on an API without the route logs a warning per pass and removes
    nothing; set it to 0 until the API is deployed):

    ```yaml
    regions:
      temp-retention:
        days: 14                        # unchanged
        release-interval-minutes: 5     # new: pass that removes released temp regions; 0 = off
    ```

- **Form wizard: the step-jump dialog works again after Go to and back; one set of validation messages**
  (PandiO/knk-workspace#413 retest, #488, developer's retest on `next` 2026-11-14) — staff forms only. When a form step
  can't be left, every problem is listed once at the top of the form and shown once on its field, with one pop-up
  message; nothing is said above the Next button any more. knk-web-app branch `claude/wizard-messages-413-488`, merged into
  `next` 2026-11-14 (knk-web-app#22 `c54ebac`); on the trunk when the developer promotes `next`.
  - **#413:** after **Go to**, going back to step 1 and clicking step 3 again opened the dialog with ×, Close and Go to
    all disabled. Cause: `FeedbackModal` cleared its busy state only while a "mounted" ref was true, and React's
    StrictMode (the dev server) left that ref false after its extra mount, so busy stayed set after the first action.
    The ref is set again on mount, and each opening of a dialog resets busy (an action from an earlier opening no
    longer closes or un-busies a later one). Fixed in the shared dialog, so every `FeedbackModal` gets it.
  - **#488:** for every kind of failure on Next, Submit, Save or a stopped jump (required field, field validation,
    blocking rule incl. "could not be checked", "before leaving" condition with one/all/any rules or a field of an
    earlier step, the next step's "before entering" condition, many-to-many entries, list fields): one entry in the
    summary at the top (a link to its field; text when the field is not on this step; many-to-many entries link to the
    entries), one message under the field in the same style (a checkbox's message moved from beside its label to under
    it), and one toast on Next/Submit ("Fix the N problems on this step to continue." for more than one). The message
    above Next/Submit (#88) is removed, and a refused Next no longer fills the red banner (kept for a failed save).
    The checks that need no request run together, so "Region is required" and a failed Allow entry condition are both
    listed. Next on a many-to-many step now checks its entries' required values, as a jump already did. A blocking
    rule's text is no longer repeated under a field that shows it; warnings keep their own line and stay out of the
    summary. After **Go to** the step shows the same summary and marks as after Next; the jump dialog keeps its own
    list.
  - **Admin steps:** none; deploy the web app. Smoke test:
    [form step conditions smoke test § 2 step 1, § 3 step 3 and § 5 steps 2–2a](guides/form-step-conditions-and-step-jump-smoke-test.md).
- **Form wizard: the step-jump dialog can always be closed; a failed step condition marks its fields**
  (PandiO/knk-workspace#413, #414, follow-ups of #68/#88 from the developer's smoke test 2026-11-13) — staff forms only.
  knk-web-app branch from the fix session, PR into `next` (knk-web-app#20, merged 2026-11-14); on the trunk when the
  developer promotes `next`.
  - **#413:** the "Can't go to … yet" dialog locked (×, Close and Go to disabled) while "Go to" waited for the progress
    save. "Go to" now opens the stopped step at once with its issues shown and saves in the background; a failed save
    shows in the wizard's banner and the next Next saves again. A jump with nothing to stop it still saves first.
  - **#414:** when a "before leaving" condition, or the next step's "before entering" condition, stops Next or a jump,
    the fields its failing rules read show the condition's message in red, like a field validation rule (one rule: its
    field; all: the failing rules' fields; any: every field). The mark clears as soon as the condition holds. The
    message above Next stays.
  - **Admin steps:** none; deploy the web app. Smoke test:
    [form step conditions smoke test § 2 step 1 and § 5 step 2](guides/form-step-conditions-and-step-jump-smoke-test.md).
- **Form builder: step conditions; form wizard: click a step to jump to it** (PandiO/knk-workspace#88, #68) — staff
  who build forms can now say in the builder what must be filled in before a step may be left or opened, and staff who
  fill in a form can click a step in the progress strip instead of pressing Next many times. No change for players.
  Branches `claude/issues-68-88-readiness-wapo57`, merged into `next` 2026-11-13 (knk-web-app `next` `1f848f7` (knk-web-app#12), knk-web-api `next` `31abe2d` (knk-web-api#14), knk-workspace `next` `c68df65` (#379));
  on the trunk when the developer promotes `next`. [Smoke test](guides/form-step-conditions-and-step-jump-smoke-test.md),
  not run. Staff guide: [§ 5.1 and § 7.1](guides/admin/staff-web-app-guide.md#51-the-steps-of-a-form-next-clicking-a-step-and-what-stops-you)
  (docs #395). Found while documenting: #396 (every rule that could not run is listed as "game server could not be
  reached"), #397 (hand-written condition JSON is ignored by the form, or blocks the step when it is not valid JSON).
  - **Form builder (#88):** a **Step conditions** card in the step editor: "before leaving this step" (Completion) or
    "before entering this step" (Entry), active toggle, message, and rules over the step's fields or the fields of
    earlier steps (is, is not, greater / less than, contains, is empty, is not empty; all / any with two or more
    rules). Values keep the field's type (a tick box stores `true`, not text). A field that holds a record or a list
    (a linked entity, a list, a material or enchantment picker, banner layers) only offers "is empty" and "is not
    empty" (`stepConditionOperatorsFor`), and a list with every entry removed counts as empty. Conditions are part of the draft and go
    live on Publish; Publish refuses a "before leaving" condition without a message. JSON that was not made with the
    editor is shown as text and saved unchanged. A rule whose field is gone is red in the editor and a warning in
    the configuration health panel (`StepConditionHealth` in knk-web-api, which walks the steps in the form's step
    order, `StepOrderJson`; an info line instead of a warning for a switched-off condition).
  - **Form wizard (#88):** Next also checks the next step's Entry conditions (they were stored but never checked). A
    failed condition is shown above the Next/Submit button as well as in the toast.
  - **Form wizard (#68):** the steps in the progress strip, and in the narrow-screen list, are buttons. Back is always
    allowed. Forward checks the current step and every visible step up to the clicked one with the checks of Next
    (required fields, lists, field validations, conditions, blocking rules, the entries of a many-to-many step) and
    stops at the first step that fails: a dialog names the step, the fields and the messages, with **Go to <step>**.
    Warnings never stop a jump. A rule that could not run because the game server is unreachable does not stop it
    either; a dialog says which checks were skipped. A form opened with values (an entity being edited, a resumed
    draft) runs its rules once when it has loaded.
  - **Admin steps:** none (no migration, no setting, no plugin change). Deploy the API and the web app in either order.
- **Staff may freeze and unfreeze players** (PandiO/knk-workspace#367) — developer decision 2026-11-13: Staff helps
  players and enforces the rules (freeze, kick, ban, balances) and doesn't manage the game core. knk-web-api and
  knk-workspace branches `claude/staff-freeze-nodes-367`, not merged.
  - **API:** data-only migration `SeedStaffFreezeNodes` gives the **Staff** group `knk.freeze` and `knk.unfreeze`, the
    nodes `PUT api/Users/{id}/freeze` / `/unfreeze` and the plugin's `/freeze` / `/unfreeze` check (names match, no
    code change). Idempotent: skipped when there is no Staff group or when Staff or a group it inherits from already
    has a grant, deny or covering wildcard for the node. Down removes nothing (it can't tell its grant from one given
    before). Moderator and Admin aren't touched: on the alpha they inherit from Staff.
  - **Web app, plugin:** no change; the player profile's Freeze/Unfreeze and the in-game commands open up for Staff
    members by the grant.
  - **Admin steps:** back up the database, deploy the API, run `dotnet ef database update` (one data-only migration,
    no setting, no plugin change). The alpha and the dev seed (`knk-dev-db-seed`, Staff holds both nodes already) get
    no new row. Check: Staff's group page lists `knk.freeze` and `knk.unfreeze`. Smoke test:
    [player profile smoke test § 4 step 4](guides/player-profile-smoke-test.md#4-without-the-nodes).
- **Web app: lootbox Enable/Disable, Create New Street and hot edit greyed out without `knk.admin.content`**
  (PandiO/knk-workspace#383, follow-up of #374) — developer decision 2026-11-13: grey them out. knk-web-app branch
  `claude/content-gate-toggles-383` (PR into `next`, not merged).
  - **Web app:** three writes outside the form wizard save through a create or update that #374 gates. The Lootboxes
    page's Types tab **Enabled/Disabled** toggle (`PUT api/LootboxTypes/{id}`), the roads page's road-edge Street
    dropdown **Create New Street** (`POST api/Streets`) and the detail page's ✎ hot edit of a field (the type's `PUT`)
    are greyed out with "Requires knk.admin.content" (and any missing area node) for accounts without it, from the
    metadata's `actionNodes.create`/`edit`. **Not changed:** the roads page's Road profiles card (RoadProfile is
    exempt), road-edge edits (`knk.admin.road`), hot edit of a user (`knk.admin.user.manage`), lootbox tokens and
    settings.
  - **Admin steps:** none; deploy the web app (no migration, no setting, no API change). Smoke test:
    [dashboard access smoke test § 8 step 9c](guides/dashboard-access-smoke-test.md#82-disabled-actions-with-requires-node-decision-11).

- **API: creates, edits and link changes of dashboard types need `knk.admin.content`** (PandiO/knk-workspace#374,
  follow-up of #371) — developer decision 2026-11-13: "Area staff should not be able to change forms at this point.
  They only work with the content available." The API now says what the web app says since #371. knk-web-api and
  knk-web-app branches `claude/api-writes-need-content-374`, merged into `next` 2026-11-13 (knk-web-api#15 `b65e66d`,
  knk-web-app#13 `ca1959d`); on the trunk when the developer promotes `next`. Guides: [dashboard access admin guide
  § 2, § 4, § 8](guides/admin/dashboard-access-admin-guide.md), [staff web app guide](guides/admin/staff-web-app-guide.md)
  (docs #385).
  - **API:** the primary create (`POST`) and update (`PUT {id}`) of every dashboard type need the type's write node
    **and** `knk.admin.content` (one rule in `DashboardAccess`, enforced by `RequireDashboardChange`); without it 403
    `NoWriteAccess` "Creating or editing Town requires knk.admin.world and knk.admin.content.". The detail page's
    Select / Unlink / Add (`POST api/Relationships/{type}/{id}/{property}/link|unlink`) need the same. The metadata's
    `actionNodes.create`/`edit` and a relationship's `nodes` list the node. **Not changed:** User (player profile) and
    Permission Group (`knk.admin.user.perm` with the escalation guard), RoadProfile (the roads page), delete, bulk
    delete, export, reads, lookups, the player profile's freeze, balance, kick and ban, other writes of a type (gate
    door state, a domain's world backfill, lootbox in-game spawn areas, …) and the plugin (`api.auth.type: apikey`).
  - **Web app:** the detail page's Select…, Change…, Unlink and Add… are greyed out with "Requires knk.admin.content"
    without it, like New and Edit since #371.
  - **Admin steps:** no migration, no setting, no plugin change, no new package; deploy the API and the web app in
    either order. A rank needs `knk.admin.content` to keep creating or editing anything through the API: Admin
    (`knk.admin.*`) and the owner keep everything; the **Staff** group (`knk.kit.manage`, `knk.siege.admin.manage`, no
    `knk.admin.content`) can no longer create or edit kits or siege setup from the web or with `curl`, and a world,
    lootbox or siege rank only views, deletes (with `knk.admin.delete`) and exports. In-game commands are unaffected
    (they go through the plugin key). `SeedDashboardActionNodes` (AM1) seeded only `knk.admin.delete` and
    `knk.admin.export`, so nothing needs a data change; grant `knk.admin.content` by hand to a rank that should keep
    editing (it opens every content type too). The lootbox page's Enable/Disable toggle saves through the same `PUT`
    and needs `knk.admin.content` now as well (greyed out without it since #383). Smoke test:
    [dashboard access smoke test § 2.2 and § 8 step 9b](guides/dashboard-access-smoke-test.md#22-create-edit-and-link-changes-need-knkadmincontent-374).

- **Form wizard, New and Edit back on `knk.admin.content`** (PandiO/knk-workspace#371, reverts AM3's LAM3-1, answers
  #368) — developer decision 2026-11-13: area staff work with the content that exists and don't change forms for now.
  knk-web-app branch `claude/form-wizard-content-only-371`, merged into `next` 2026-11-13 (knk-web-app#11, `e6ba115`); on the trunk when the developer promotes `next`.
  - **Web app:** `/forms/:type` and `/forms/:type/edit/:id` need `knk.admin.content` again ("Staff only" otherwise).
    The dashboard's New, New with and Edit and the detail page's Edit need the type's own nodes **and**
    `knk.admin.content`, greyed out with "Requires knk.admin.content"; a picker's Create New is hidden without it.
    Edit of a user still opens the player profile for Staff. View, the explorer per area, lookups, Delete, bulk
    delete, Export and the player profile are unchanged.
  - **API:** unchanged by #371; it still accepts creates and edits per area node. #374 (above) asks for
    `knk.admin.content` there too.
  - **Admin steps:** no migration, no setting, no plugin change, no new package; deploy the web app only. World, kit,
    lootbox, siege, road and Staff ranks that should keep creating or editing records need `knk.admin.content`.
    Smoke test: [dashboard access smoke test § 8 steps 6, 7, 9, 9a](guides/dashboard-access-smoke-test.md#8-web-app-am3).

- **NPC navigation, Phases 1 to 4: NPCs walk K&K routes, alone and in groups (admin testing only)** — no change for players; off by
  default (`npc.navigation.enabled`). In `next` when the pull requests of PandiO/knk-workspace#360 are merged; on the
  trunk when the developer promotes `next`. Parent issue PandiO/knk-workspace#358,
  [implementation plan](specs/npc-platform/IMPLEMENTATION_PLAN.md).
  1. **Phase 1** (#359): the Citizens plugin as an optional dependency, an engine-neutral core with layered
     settings, NPC metrics (`knk_npc_nav_*`), the NPC event audit and a guard that keeps NPCs out of region tracking.
     Follow-up (#490, in `next` when its pull requests are merged): NPCs are kept out of the damage handlers of the
     player systems the developer's audit named (statistics, telemetry, combat tag, siege combat rules, admin freeze,
     join loading, teleport warmups, weapon enchantments, AFK activity, domain effect damage), for any entity with
     Citizens' `NPC` metadata, whether or not NPC navigation is on; gate, hub and decoration protection still apply
     to NPCs. The test walkers no longer pick spots under water, where they stood drowning, and the audit report
     lists damage causes; since the #486 retest PR their own path search never enters water either (the audit after
     the first fix still counted `DROWNING 1088`).
  2. **Phase 2** (#360): an NPC follows the road route K&K plans, one stretch of the road line at a time, with a
     watchdog that notices an NPC that makes no progress and sends it on a short recovery leg. NPCs have their own
     access profile instead of a player's rights, wait when the rules allow no route, pause when their chunk unloads
     and are spawned a few per tick. `/knk npc nav` replaces the test command of the Citizens spike.
  3. **Phase 3** (#361, in review; in `next` when its pull requests are merged): the rules stay binding while NPCs
     walk. A few NPCs per tick have their way ahead checked against the gate and access rules as they are now; a
     gate or access change reaches only the NPCs it concerns. An NPC with no allowed route walks to the closed gate
     or the district's edge and waits there until that gate or rule opens. A trespass guard counts any NPC that
     enters a region its rules deny (`knk_npc_nav_events_total{event="trespass"}`, must stay 0). New keys:
     `npc.navigation.rule-checks-per-tick` (10) and `npc.navigation.stop-on-trespass` (false).
  4. **Phase 4** (#377, in review; in `next` when its pull requests are merged): groups plan once. A group's leader
     plans the route; the followers walk the same path in formation slots (`column`, `ranks`, `cluster`,
     `escort-ring`), fold into a column where the road is too narrow (gates, stairs) and reform after. A gate or
     access change costs a group one route plan whatever its size (the Citizens spike planned 50 NPCs separately:
     1.3 s queue wait at p95), and a group has one blocked state and one wake-up. A follower that leaves its lane
     or gets stuck plans one short leg back; the leader waits for followers that fell far behind.
     `/knk npc nav group <n> [formation] [profile]` starts a test group. New keys under `npc.navigation`:
     `group-formation` (column), `group-spacing` (2.0), `group-ranks-width` (2), `group-rejoin-blocks` (4.0),
     `group-regroup-blocks` (24.0), `group-catch-up-speed` (1.3). New metric events `group_fold`, `group_reform`,
     `group_rejoin`, `group_regroup`, `group_lost`.
  - **Admin steps:**
    1. Install the Citizens plugin (build 4269 for 26.3 or newer) only where NPC navigation is tested; the plugin
       runs without it.
    2. Merge the `npc.navigation` block into `config.yml` by hand
       ([configuration reference § 4.27](guides/admin/plugin-configuration.md#427-npc) has the YAML). It ships with
       `enabled: false`.
    3. To test: `enabled: true`, restart, then the steps under "Developer test" of Phases 1, 2, 3 and 4 in the
       implementation plan.

## 2026-11-16

- **Code-recipe skills for endpoints, plugin commands and entities** ([PandiO/knk-workspace#424](https://github.com/PandiO/knk-workspace/issues/424))
  — no game change; developer-facing. Three new project skills in `.claude/skills/`, built from each repo's `main`
  with the real files to copy: `knk-api-endpoint` (a knk-web-api endpoint: controller, service, repository, DTOs,
  AutoMapper, the default-deny access rule and the pinned access tests, migration, xUnit tests),
  `knk-plugin-command` (a plugin command: plugin.yml, registration, in-house permission checks through
  `CommandNodes` and `KnkPermissible`, the command-label takeover for clashes, messages, config keys with deploy notes,
  unit, MockBukkit/Mockito and player-scenario tests) and `knk-entity-scaffold` (a new entity across API, web app and
  plugin, with a per-repo checklist). Each points to `knk-test-writer` for its tests. The stale Copilot files
  (`.github/copilot-instructions.md`, `.github/instructions/*`, `.github/prompts/scaffold-entity.prompt.md`) are
  deleted and the links to them point to the skills.
  - **Admin steps:** none.
- **Docs sessions follow a skill** ([PandiO/knk-workspace#425](https://github.com/PandiO/knk-workspace/issues/425))
  — no game change; developer-facing. The docs-session procedure moved from `docs/ai-agents/docs-session-prompt.md`
  into the new skill `.claude/skills/knk-docs-session/` (with templates for the docs PR, the closing comment and the
  sessions-archive entry), so a docs session loads it instead of carrying it in its prompt. The rules are unchanged:
  branch from knk-workspace `next`, merge its own docs PR into `next` once the checks pass and the Codex findings are
  handled (or Codex is at its usage limit), agent workflow files by their own PR into `main`, smoke-test guides keep
  every step with automated steps tagged, the tracker row goes straight to the sessions archive. The prompt is now a
  short starter (issue numbers, merged commits, base, the skill to follow); the global instructions, the documentation
  maintenance guide, `AGENTS.md` and `CLAUDE.md` point to the skill.
  - **Admin steps:** none.

## v0.3 — 2026-11-15

Release v0.3: the developer promoted `next` to trunk after testing it as a whole (knk-web-api `main` `2cc8254`,
knk-web-api#38; knk-web-app `main` `947923c`, knk-web-app#45; tags `v0.3` in both). knk-plugin is not part of this
release. The entries below were merged into `next` earlier (their dates are in each entry) and moved here from
Unreleased. Also in the release: the kick and freeze/unfreeze reason labels say "(optional)" once (knk-web-app#44) and
a leftover debug spec was removed from the e2e suite (knk-web-app#34).

- **Admin steps for the whole release** ([production installation § 5.3](guides/production-installation.md#53-apply-the-migrations)):
  three migrations, in this order: `20261115082252_DropTownStreet` (deletes the `TownStreet` rows, #409),
  `20261115092735_AddAuditLogSubject` (additive, #50) and `20261115125459_SeedStaffKickBanNodes` (data only, #119).
  No settings and no plugin `config.yml` keys. Kick and ban from the web take effect in game with knk-plugin `v0.2`
  (`f8f7fb2e`, which carries [#574](https://github.com/PandiO/knk-workspace/issues/574)) or later, running with
  `realtime.enabled: true`. Deploy order:
  1. Back up the database first: `DropTownStreet` drops the `TownStreet` table with its rows.
  2. Deploy the API.
  3. Run `dotnet ef database update` (the migrator, § 5.3). The API does not migrate on start.
  4. Deploy the web app.
- **Staff player profile, API part: frozen state in the summary, unfreeze reason, game sessions, search filters; kick and ban from the web**
  ([PandiO/knk-workspace#565](https://github.com/PandiO/knk-workspace/issues/565), part of #119; developer decisions
  2026-11-15 on kick and ban; link L6 of the Chain 3 follow-ups chain, [#564](https://github.com/PandiO/knk-workspace/issues/564))
  — knk-web-api, knk-web-app and knk-workspace branches `claude/player-profile-api-119`, merged into `next` 2026-11-15
  (knk-web-api#37 `5e10185f`, knk-web-app#42 `98e108f0`, docs knk-workspace#595); promoted to trunk in v0.3 (2026-11-15). For players: staff can now kick and ban them from the web app (carried out by the game server once
  knk-plugin link L7, [#574](https://github.com/PandiO/knk-workspace/issues/574), is in).
  1. **Frozen state from the summary.** `GET api/users/{id}/profile-summary` carries `frozenAt`, `frozenByUserId` and
     `frozenByUsername` next to `isFrozen` / `frozenReason`; the profile's frozen banner reads them and no longer
     reads the user and the audit log on every load.
  2. **Unfreeze reason.** `PUT api/Users/{id}/unfreeze` takes an optional `{ "reason" }`, written into the
     `PlayerUnfrozen` audit entry; the profile's unfreeze confirm asks for it (optional).
  3. **Game sessions in the timeline.** New `GET api/statistics/users/{id}/sessions?page=&pageSize=`
     (`knk.admin.user.manage`), newest first; the profile timeline shows them ("Played on {server}", end reason, active
     time) with a **Game sessions** chip.
  4. **Moderation search.** `POST api/Users/search` takes `online`, `frozen` and `paymentsLocked` filters, sorts by
     `lastseenat` and `experiencepoints`, and matches a UUID with or without dashes; list rows carry `isFrozen`,
     `paymentsLocked` and `createdAt`. Moderation → All players has Online / Frozen / Payments selects (in the URL),
     sortable Last seen and XP, Frozen / Payments locked chips and a Created column.
  5. **Kick and ban from the web.** `POST api/Users/{id}/kick` (`knk.kick`, reason optional, player must be online) and
     `POST api/Users/{id}/ban` (`knk.ban`, reason required; permanent on the game server's ban list, unban is `/pardon`
     in game). Audited (`PlayerKicked`, `PlayerBanned`) and sent to the game servers as realtime `PlayerKick` /
     `PlayerBan` v1 ([contract](specs/realtime-signalr/DESIGN.md)); refused for oneself, an account without
     Minecraft, a player ranked at or above the caller, a kick of an offline player (409) and while no game server is
     connected (503). Kick and Ban buttons on the profile (status strip and Moderation tab), greyed out with
     "Requires knk.kick / knk.ban" without the node.
  6. Docs: [smoke test § 7](guides/player-profile-smoke-test.md) (and § 2.2, 2.5, 3.1), realtime DESIGN § 6.10 (the
     event contract for L7), web-api architecture § 5.7, web-app architecture (staff player profile, moderation search).
  - **Admin steps:** apply the migration `SeedStaffKickBanNodes` (gives the Staff group `knk.kick` and `knk.ban`; data
     only). Deploy the **API first** (or together): an older API has no sessions, kick or ban endpoints (the web app's
     timeline then names the sessions as not loaded, and Kick/Ban answer 404). Kick and ban only take effect in game
     once knk-plugin with L7 (#574) is deployed with `realtime.enabled: true`.
- **Relation picker: lookup mode applies the field's narrowing filters**
  ([PandiO/knk-workspace#288](https://github.com/PandiO/knk-workspace/issues/288), developer decision 2026-11-15; link
  L5 of the Chain 3 follow-ups chain, [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-web-api,
  knk-web-app and knk-workspace branches `claude/lookup-picker-filters-288`, merged into `next` 2026-11-15 (knk-web-api#36
  `d8514ed4`, knk-web-app#41 `990af482`, docs knk-workspace#587); promoted to trunk in v0.3 (2026-11-15).
  No change for players.
  1. **Filtered fields work without the read node.** Staff who search a related type through `api/Lookup` (no read
     node of that type) can now use a relation field whose picker filters narrow the list, e.g. a siege objective's
     holder team scoped to its scenario: the picker offers the narrowed list, names only, instead of "This list is
     narrowed by …, which only the full … search can do".
  2. **API:** `POST api/Lookup/{type}/search` takes `filters` and passes those the type's lookup lists to the type's own
     search (one list per type in `DashboardLookups.cs`; users take none). Results stay `{ id, label, detail? }`.
     Another key answers 400 `LookupFilterNotAllowed`, an unusable value (an id that isn't a positive number, a flag
     that isn't true/false) 400 `LookupFilterInvalid`, so a lookup never lists more than the form asked for.
     `prefer…` filters only order; `excludeIds` stays in the browser. Access rule unchanged (any area node or the
     plugin key).
  3. **Web app:** the picker sends the filters and only shows the "narrowed by" refusal when the API refuses a filter.
  4. Docs: [smoke test § 2.4–2.5](guides/relation-picker-and-delete-details-smoke-test.md), web-api architecture
     (lookups), web-app architecture (relation picker), [access model § 4.6.3](specs/dashboard-access-model/DESIGN.md).
  - **Admin steps:** none (no migration, no setting, no new node). Deploy the **API first** (or together): an older API
     ignores `filters` and would answer with the unfiltered list, which the old web app refused to show.
- **Form builder: field validation rules are part of the draft and go live on Publish; add-from-template endpoints removed**
  ([PandiO/knk-workspace#291](https://github.com/PandiO/knk-workspace/issues/291); link L4 of the Chain 3 follow-ups
  chain, [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-web-api, knk-web-app and knk-workspace
  branches `claude/builder-draft-rules-291`, merged into `next` 2026-11-15 (knk-web-api#35 `93c3d50f`, knk-web-app#40
  `cd730f29`, docs knk-workspace#583); promoted to trunk in v0.3 (2026-11-15). No change for players.
  1. **Rules in the draft.** In the form builder a field's cross-field validation rules are kept in the draft (keyed by
     field GUID) with **Save Field** and **Save**, marked *Not published*, and applied on **Publish** (adds, edits and
     deletes); the form wizard keeps the published rules until then. **Discard** drops rule changes.
  2. **Draft-only fields** (added but not published yet) can get rules; a dependency on a field of the same form is
     chosen by GUID, on a parent form's field by id.
  3. **Publish** names rule changes ("Validation rules: 1 added, 1 changed, 1 removed.") and is refused when a rule's
     field or dependency left the form, or rules depend on each other in a circle.
  4. A draft saved before this change (no rules in it) keeps the published rules, unchanged.
  5. API: `GET api/FormConfigurations/{id}/builder` and the draft carry `validationRules`; `POST
     api/FormConfigurations/{configId}/steps/add-from-template` and `steps/{stepId}/fields/add-from-template` are
     **removed** (they wrote into the published rows; no caller since #71).
  6. Docs: [smoke test § 11](guides/form-display-builders-smoke-test.md), web-api architecture § 5.5, web-app
     architecture (builders).
  - **Admin steps:** none (no migration, no setting, no new node). Deploy API and web app together, **API first**: an
    older API ignores the rules in the draft, so they would be lost on Save.
- **"Show what uses it" for more refusals: form configuration delete, bulk delete rows, "skipped: in use"**
  ([PandiO/knk-workspace#289](https://github.com/PandiO/knk-workspace/issues/289); link L3 of the Chain 3 follow-ups
  chain, [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-web-api, knk-web-app and knk-workspace
  branches `claude/show-what-uses-it-289`, merged into `next` 2026-11-15 (knk-web-api#34 `378921c6`, knk-web-app#39
  `2dfd5883`); promoted to trunk in v0.3 (2026-11-15). No change for players.
  1. **Entity setup.** A form configuration whose delete is refused because another form opens it as a sub-form offers
     **Show what uses it**: the form fields and steps, each with the form (and step) it sits in. Not links: they have
     no page of their own.
  2. **Bulk delete.** Each row refused as in use keeps its **Show what uses it** (from #205), now through one shared
     component; covered end to end.
  3. **Cancelled form / deleted draft.** An entity skipped as in use after **Delete them** / **Delete draft and them**
     offers **Show what uses it** with every reference, as the in-use check counted them.
  4. API: `GET api/EntityReferences/{type}/{id}/rows` also takes `FormConfiguration` (needs `knk.admin.content`) and
     `?all=true` (every reference, cascades included); the read rules per referencing type stay as in #44.
  5. Docs: [smoke test § 4.8–4.12, § 5.3](guides/relation-picker-and-delete-details-smoke-test.md),
     [web-api architecture § 5.4](architecture/web-api-architecture.md), web-app architecture ("Show details").
  - **Admin steps:** none (no migration, no setting, no new node; deploy API and web app together, API first: an older
    API answers 404 for a form configuration, shown as an error line under the button).
- **Staff web app: the player profile's Permissions tab gets the grant form on top, a search and sortable columns**
  ([PandiO/knk-workspace#407](https://github.com/PandiO/knk-workspace/issues/407); link L3 of the staff web app
  follow-ups chain, [#517](https://github.com/PandiO/knk-workspace/issues/517)). knk-web-app and knk-workspace
  branches `claude/profile-permissions-407` (merged into `next` as knk-web-app#37 `b2589eb`, promoted in v0.3). On a player's profile
  (`/admin/users/<id>?tab=permissions`), Effective Permissions now has the grant/deny form above the list, a search box
  that filters by node and by source (a group's name, or "direct" for direct grants) and says when nothing matches,
  and Node, Value and Source headers that sort ascending, descending and back to the original order, with an arrow and
  `aria-sort`. The 1-day default expiry for direct grants and the `knk.admin.user.perm` gate are unchanged.
  - **Admin steps:** none; web app only (no API change, no migration, no setting). To test: § 6 of the
    [player profile smoke test](guides/player-profile-smoke-test.md).
- **Form wizard: list field cards stay readable on a phone**
  ([PandiO/knk-workspace#290](https://github.com/PandiO/knk-workspace/issues/290); link L2 of the Chain 3 follow-ups
  chain, [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-web-app and knk-workspace
  `claude/list-field-cards-290`, merged into `next` 2026-11-15 (knk-web-app#38 `9b5f9ddf`, docs knk-workspace#571); promoted to
  trunk in v0.3 (2026-11-15). In an Object List field the cards under "Selected (n):"
  wrap at narrow widths: the name keeps the card's width (a long name wraps instead of being cut to one letter) and ×
  and **Edit instance** move to their own line. Desktop layout unchanged. Playwright spec
  `e2e/form-wizard-list-field.spec.ts`.
- **Temp region releases: no server left out, no release stuck behind waiting ones**
  ([PandiO/knk-workspace#399](https://github.com/PandiO/knk-workspace/issues/399); link L1 of the Chain 3 follow-ups
  chain, [#564](https://github.com/PandiO/knk-workspace/issues/564)) — knk-web-api and knk-workspace branches
  `claude/temp-region-releases-399`, merged into `next` 2026-11-15 (knk-web-api#33 `3b36edc6`, docs knk-workspace#572);
  promoted to trunk in v0.3 (2026-11-15). No change for players.
  1. `GET api/WorldTasks/temp-region-releases` answers 400 for a blank or missing `serverId`, as `GET open` does.
     The plugin always sends `realtime.server-id`, so it is not affected.
  2. Unused temp regions of abandoned drafts are no longer kept past their release when more than 200 older releases
     wait on a region that is still in use: the API reads the due releases in pages until it has `max` to give.
  3. Admin steps: none (no settings, no migration, no plugin `config.yml` change).
- **Web app: admin tables no longer scroll the page sideways at phone width**
  ([PandiO/knk-workspace#535](https://github.com/PandiO/knk-workspace/issues/535); staff web app only). knk-web-app
  branch `claude/admin-mobile-overflow-535`, merged into `next` 2026-11-15 (knk-web-app#36 `5b87473`, docs
  knk-workspace#567); promoted to trunk in v0.3 (2026-11-15).
  1. At 390 px Mail log, Invitations, the Lootboxes Types, Specials, Areas and Active boxes tabs and the Minecraft
     catalogue audit made the whole page 70 to 450 px wider than the screen. The tables scroll inside their own box
     again. The cause was the visually hidden "Actions" head cell, positioned outside the table's scroll box; each box
     is now `relative` (the fix the form and display configuration tables got in #266).
  2. Tests: `e2e/admin-navigation.spec.ts` checks Mail log and Invitations (staff with some nodes) and the four
     Lootboxes tables plus the catalogue audit (owner) at 390 px; fixtures `e2e/fixtures/adminTables.ts`. Guide:
     [admin navigation § 2.4 and § 4.4](guides/admin-navigation-smoke-test.md).
  - **Admin steps:** none (web app only, no setting).
- **Staff web app: edit a permission group's own nodes, with a History**
  ([PandiO/knk-workspace#50](https://github.com/PandiO/knk-workspace/issues/50); link L2 of the staff web app follow-ups
  chain, [#517](https://github.com/PandiO/knk-workspace/issues/517)). knk-web-api, knk-web-app and knk-workspace
  branches `claude/group-grants-50` (merged into `next` as knk-web-api#32 `dcbb1f8` and knk-web-app#35 `4278102`, promoted in v0.3). A permission group's detail page
  (Dashboard → Permission Group → a group) has a **Permissions** panel: the group's own nodes (Granted/Denied, expiry),
  a grant/deny form whose expiry is empty (permanent) by default, Edit, change Granted/Denied and Remove per row.
  Changing Granted/Denied or removing asks first with the blast radius ("This affects N players", members of groups
  that inherit from it included; online players get the change within seconds). A **History** list shows each change
  to the group's nodes. Without `knk.admin.user.perm` the panel is read-only with "Requires knk.admin.user.perm".
  1. **API:** the audit log has a generic subject (developer decision 2026-11-15): `audit_log_entries` gets nullable
     `SubjectType` and `SubjectId` and `TargetUserId` becomes optional. A change to a group's own grants (added,
     updated, removed) leaves one entry with the group as subject (`PermissionGroup`), the staff member as actor and the
     node, before/after value and expiry in the details; player grant audits are unchanged. `GET api/audit-log` takes
     `subjectType` and `subjectId` (`knk.admin.user.manage`). New `GET api/PermissionGroups/{id}/member-count`
     (`knk.admin.user.manage` or the plugin key): active members of the group and of every group inheriting from it,
     each player once. Writes stay on the by-node routes and `knk.admin.user.perm`; nobody changes a group ranked at or
     above their own.
  2. **Follow-up:** [#558](https://github.com/PandiO/knk-workspace/issues/558) (plugin: members of inheriting groups
     and changes while realtime is down).
  - **Admin steps:** one additive migration, `AddAuditLogSubject` (two nullable columns, one index, `TargetUserId`
    nullable). The API does not migrate on start: back up the database, deploy the API, run `dotnet ef database update`,
    then deploy the web app (it needs the new endpoints). No settings, no `config.yml` key, no plugin change. Smoke
    test: [dashboard access smoke test § 8.7](guides/dashboard-access-smoke-test.md) (mostly automated in CI).
- **Dashboard: the PermissionGrant table loads** ([PandiO/knk-workspace#408](https://github.com/PandiO/knk-workspace/issues/408);
  API and staff web app). knk-web-api and knk-web-app branches `claude/permission-grant-table-408` (merged into `next` as
  knk-web-api#30 `2425f18` and knk-web-app#29 `9a29623`, promoted in v0.3). Dashboard → Permission Grant lists every grant and deny (node, Granted/Denied, holder, expiry)
  and pages, sorts and searches by node; it is read-only (no New, Edit or Delete that saves: grants are still changed
  on the player profile and with `/knk user … perm`; #50 adds the group editor).
  - **API:** `POST api/PermissionGrants/search` now needs `knk.admin.user.manage`, like `GET` and `GET {id}` (it needed
    `knk.admin.user.perm`), so whoever the dashboard lists the type for can read it. Writes still need
    `knk.admin.user.perm`. The search sorts by the column asked (`id`, `holderId`, `value`, `expiresAt`, `node`).
  - **Admin steps:** none; deploy the API and the web app together (no migration, no settings). Smoke test:
    [dashboard access smoke test § 8.6](guides/dashboard-access-smoke-test.md) (mostly automated in CI).
- **Town streets come from their districts; the `TownStreet` table is dropped**
  ([PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409), L1
  [#514](https://github.com/PandiO/knk-workspace/issues/514) design, L2
  [#515](https://github.com/PandiO/knk-workspace/issues/515) implementation) — knk-web-api, knk-web-app and
  knk-workspace branches `claude/town-streets-409` (merged into `next` as knk-web-api#31 `de74190` and knk-web-app#33 `d3d7152`, promoted in v0.3). Design
  [specs/towns/DESIGN_TOWN_STREETS.md](specs/towns/DESIGN_TOWN_STREETS.md) (approved 2026-11-14 with its defaults).
  1. **API.** A town's streets (`TownDto.streets` / `streetIds` of `GET api/Towns/{id}`) are the distinct streets of
     its districts, ordered by name then id, read-only; they follow every street linked to or unlinked from a district
     at once. Metadata lists Town `streets` as `storage: "derived"`; `POST api/Relationships/Town/{id}/streets/link`
     and `/unlink` answer 400 `RelationshipNotEditable` "Streets are managed on the district: open a district to add or
     remove them." (403 without the nodes, as before). `GET api/Towns` still carries no streets. Saving a town no
     longer writes its districts back.
  2. **Web app.** The Streets section of a town's detail page lists the streets with View and Edit, without Add…,
     Unlink, Create New or Delete (whatever the stored display configuration says), and shows the hint above. Streets
     are added to a town on a district's detail page (District → Streets → Add…).
  3. **Plugin:** no change (the JSON shape stays; `/knk towns` debug output shows the derived list).
  - **Admin steps:**
    1. Back up the database before deploying (the migration drops a table).
    2. Deploy the API and the web app together.
    3. Apply the migration `DropTownStreet` (dev: `dotnet ef database update`; alpha: the migrator image, runbook
       [§ API updates with migrations](guides/closed-alpha-deployment-runbook.md)). It drops `TownStreet` with **all**
       its rows, including streets no district of the town has (developer decision 2026-11-14 on #515). Such a street
       no longer shows on the town; link it to one of the town's districts to bring it back.
    4. Rollback: the migration's `Down` (`dotnet ef database update SeedStaffFreezeNodes`, the migration before it)
       recreates `TownStreet` and refills it from the districts; the dropped rows no district covered come back only
       from the backup.
    5. A Town form with a `Streets` / `StreetIds` field or step (the API ignores it) can be removed in the form builder;
       the read-only check `scripts/maintenance/town-street-orphans-409.sql` (result set 3) lists such configurations.
    6. Smoke test: [town streets smoke test](guides/town-streets-smoke-test.md) (L3
       [#516](https://github.com/PandiO/knk-workspace/issues/516)): the manual steps are the deploy and migration on dev
       and alpha and a look at a real town's Streets; the read-only section, the refused link, the derived list and the
       migration are automated (knk-web-app `e2e/town-detail.spec.ts`, knk-web-api `TownStreetsDerivedTests`,
       `RelationshipsControllerTests`, `DropTownStreetMigrationTests`). The dashboard access smoke test § 2.2 step 2
       and § 8 step 9b now use a district's streets as the link example.
- **Smoke tests: the web app's checks move into the automated suites** ([PandiO/knk-workspace#511](https://github.com/PandiO/knk-workspace/issues/511))
  — no game or player change; developer-facing. Playwright specs with a mocked API in knk-web-app `e2e/` now check what
  the developer did by hand in the smoke tests of features already on the trunk, and each guide marks those steps
  `[automated]` with the test, so the evening check covers only what is left (game server, real client, themes).
  Batch 1 (knk-web-app branch `claude/test-backfill-511`, PR into `next`): `e2e/player-profile.spec.ts` (player
  profile and player search, 21 of 26 steps) and `e2e/settings-pages.spec.ts` (settings pages, 22 of 26 steps), new
  helpers `e2e/support/layout.ts` (no sideways scroll at phone width), `e2e/fixtures/players.ts` and
  `e2e/fixtures/settings.ts`; `mockSession` keeps the realtime hub offline. Guides:
  [player profile](guides/player-profile-smoke-test.md), [settings pages](guides/settings-pages-smoke-test.md);
  [web app testing § 3](guides/developer/web-app-testing.md#3-end-to-end-tests-playwright). Merged into `next`
  2026-11-14 (knk-web-app#28, knk-workspace#528).
  Batch 2: `e2e/admin-navigation.spec.ts` (admin navigation, 20 of 24 steps) and `e2e/dashboard-access.spec.ts`
  (dashboard access § 8, with the API's xUnit tests marked in § 2.2, § 3, § 4 and § 7; 31 checks), fixture
  `e2e/fixtures/dashboardAccess.ts`. Found: Mail log and Invitations scroll sideways at phone width
  ([#535](https://github.com/PandiO/knk-workspace/issues/535)). Guides: [admin navigation](guides/admin-navigation-smoke-test.md),
  [dashboard access](guides/dashboard-access-smoke-test.md). Merged 2026-11-14 (knk-web-app#30, knk-workspace#537).
  Batch 3: `e2e/entity-detail.spec.ts` (entity detail, 14 of 21 steps) and "Show what uses it" in
  `e2e/dashboard-access.spec.ts`; the relation picker's Jest tests marked in its guide (19 of 24 steps), fixture
  `e2e/fixtures/entityDetail.ts`. Guides: [entity detail](guides/entity-detail-smoke-test.md),
  [relation picker and delete details](guides/relation-picker-and-delete-details-smoke-test.md). Merged 2026-11-14
  (knk-web-app#31, knk-workspace#538).
  Batch 4: `e2e/data-table.spec.ts` (shared table, pager and confirm; numbers in a Dutch browser) and the existing Jest
  and API tests marked in [data primitives](guides/data-primitives-smoke-test.md) (20 of 28 steps),
  [feedback primitives](guides/feedback-primitives-smoke-test.md) (15 of 28) and
  [form step conditions and step jump](guides/form-step-conditions-and-step-jump-smoke-test.md) (29 of 36).
  - **Admin steps:** none (tests and docs only).
- **Dashboard tables: the row actions scroll with the table again, and Export as CSV downloads at once**
  ([PandiO/knk-workspace#606](https://github.com/PandiO/knk-workspace/issues/606),
  [#607](https://github.com/PandiO/knk-workspace/issues/607), from the developer's smoke test of `next` on 2026-11-15;
  staff web app only). knk-web-app and knk-workspace branches `claude/dashboard-fixes-606-607` (knk-web-app#43 `6c1cf4a`
  into `next`, promoted in v0.3).
  - **#606:** View / Edit / Delete are the last column of the row again and scroll with the table; the pinned actions
    column of #405 cut off the table's other columns. The right-click / Shift+F10 row menu (#406) stays and is the fast
    way to view or edit a row at any width. The checkbox column stays pinned on the left and the row lines (#404) are
    unchanged.
  - **#607:** checked first: Export as CSV (the row menu and the bar above the table) already downloads the file
    straight away through a `Blob` and an `<a download>` link, named `<type>-<yyyy-mm-dd>.csv`, with no dialog or save
    picker of the app's own. A browser set to ask where to save each file still asks; that is the browser's setting.
    New Playwright tests catch the download and check the file name and the CSV header row.
  - **Admin steps:** none; deploy the web app. Smoke test:
    [dashboard access smoke test § 8.5](guides/dashboard-access-smoke-test.md) (9 of 11 steps automated in CI).
- **Dashboard tables: every row looks the same, the row actions stay in view, and a right-click menu**
  (PandiO/knk-workspace#404, #405, #406; staff web app only). knk-web-app branch `claude/dashboard-table-actions-404-406`,
  merged into `next` 2026-11-14 (knk-web-app#17); promoted to trunk in v0.3 (2026-11-15).
  - **#404:** rows from the second on no longer show a thick grey left edge; every row has the same 1px line.
  - **#405:** View / Edit / Delete sit in a column pinned to the table's right edge (the checkbox column to the left),
    so they stay in view on types with many columns and at phone width; a shadow shows on the pinned edge only while
    columns scroll under it.
    Reverted for the actions column by #606 (2026-11-15): they scroll with the table again; the checkbox column stays
    pinned.
  - **#406:** a right-click on a row (or Shift+F10 / the context-menu key on a focused row) opens View, Edit, Delete and
    Export as CSV. Items follow the same permission nodes as the buttons and are greyed out with "Requires <node>",
    not hidden. On a ticked row Delete and Export act on the whole selection (bulk delete needs
    `knk.admin.delete.bulk`). Ctrl/Cmd + right-click keeps the browser's menu.
  - **Admin steps:** none; deploy the web app. Smoke test:
    [dashboard access smoke test § 8.5](guides/dashboard-access-smoke-test.md) (mostly automated in CI).

## 2026-11-16

- **A manager run each weekday keeps the agent workflow tidy** ([PandiO/knk-workspace#418](https://github.com/PandiO/knk-workspace/issues/418))
  — no game change; developer-facing. The scheduled task "K&K daily digest" is now "K&K manager": each weekday at
  16:40 Europe/Amsterdam a fresh session follows the new `.claude/skills/knk-manager/` skill. It reports red CI on
  `next` or trunk first, acts on the developer's replies on the digest issue #333 ("2.3: yes", "pause X", "bump Y",
  "promote", "start docs #n"; each handled reply gets a reaction), promotes only on the developer's explicit go with
  release tags through the Release workflow, closes `status:in-review` issues whose work and docs reached trunk (unless
  a docs follow-up is open), opens and merges `main` → `next` sync pull requests, archives finished board rows and
  lists stale claims, suggests docs sessions over the debt cap and asks before starting an approved chain. It ends with
  the digest (`knk-digest`, which gained a § 7 "Manager run"). Coordinators now report to the manager with a comment
  on the chain's parent issue. DESIGN § 1.3, § 7, § 8.4 and the global instructions ("Manager run and daily digest")
  say so.
  - **Admin steps:** none. To give the manager an instruction, reply on #333.

- **Design sessions follow one procedure** — no game change; a new skill `.claude/skills/knk-design/`
  ([PandiO/knk-workspace#417](https://github.com/PandiO/knk-workspace/issues/417)) runs a feature's design: it reads the
  vision, related specs and legacy V1/V2 behaviour, asks the developer one question at a time with the ask-user prompt,
  writes `docs/specs/<feature>/DESIGN.md` with status header, decision log (agent decisions with their alternatives),
  platform-specific parts and numbered open questions, and puts larger choices in a weighted decision matrix for the
  developer. On approval it sets the spec to Decided, files a sub-issue with a `tier:` label per phase, writes each
  phase's first smoke-test guide section sized to its tier (folds in
  [#422](https://github.com/PandiO/knk-workspace/issues/422); `knk-test-writer` § 4 item 6 starts from it), drafts the
  chain charter and posts "Ready to schedule" on the feature issue for the manager. Templates for the spec, the
  decision matrix, the smoke-test section and the sub-issue are next to it.
  - **Admin steps:** none.

- **Intake skill: ideas are captured at once and shaped later** — no game change
  ([PandiO/knk-workspace#416](https://github.com/PandiO/knk-workspace/issues/416), phase 2 of the agent workflow,
  [DESIGN § 1.1](specs/ai-agent-workflow/DESIGN.md#1-roles)). New project skill `.claude/skills/knk-intake/`.
  1. **Capture mode** (the default): drop an idea in a session, even one line, and walk away. The session searches open
     and closed issues for duplicates, files an issue labelled `idea` with your words quoted as they are (or comments
     on the open issue that already has it), asks nothing and confirms in one sentence.
  2. **Shaping mode** ("let's go through ideas"): the open `idea` issues one at a time, each with a read-back, the repos
     it touches, a proposed `tier:` label and whether it needs design, at most three questions in the ask-user prompt,
     then "now, later or design first" (or drop). "Now" goes to the manager session, "design first" starts a design
     session with the `knk-design` skill.
  3. **Tier labels:** the global instructions now say that whoever files an issue sets a `tier:` label when the scope
     is clear; intake's shaping proposes one otherwise.
  - **Admin steps:** none. Optional: an `area:web-app` label, so intake can tag web-app ideas too (only `area:api` and
    `area:plugin` exist; agents cannot create labels).

## 2026-11-15

- **Smoke-test guides keep every step** — no game change; smoke-test guides keep each step's full manual instructions
  again, and a step an automated test covers gets a tag `[automated: <test>]`, so the developer can test everything by
  hand or skip what CI covers (developer decision 2026-11-15). Global instructions "Testing: automated first" item 2,
  the `knk-test-writer` skill § 4 and the link, coordinator and digest skills say so; the guides shortened on 2026-11-14
  are restored on `next`.
  - **Admin steps:** none.

## 2026-11-14

- **Agents test automatically first** — no game change; feature sessions now put each behaviour they change into the
  automated suites (Playwright for web pages, unit tests, MockBukkit/Mockito for plugin code, plugin scenarios on a real
  Paper server), and smoke-test guides list only what no suite can check (developer decision 2026-11-14). New skill
  `.claude/skills/knk-test-writer/`; global instructions "Testing: automated first"; the link and coordinator skills
  check it, the digest counts only manual steps. Backfill of features already in `next`: PandiO/knk-workspace#511.
  - **Admin steps:** none.

- **Web app end-to-end tests on Playwright, in CI** ([PandiO/knk-workspace#423](https://github.com/PandiO/knk-workspace/issues/423))
  — no player change; developer-facing. knk-web-app replaces Cypress with Playwright Test (`@playwright/test` 1.64.1,
  pinned): the specs run in Chromium against the production build with a mocked API (no API or database), and the
  mocks are typed with the app's DTOs (`npm run typecheck:e2e`). The Cypress registration spec is ported; new specs
  cover login with the expired-token refresh and retry, the dashboard town list with search, and the first form
  wizard step. New CI workflow `e2e.yml` (job `e2e`, 10-minute timeout) uploads the HTML report and, on failure, the
  traces. `npm run test:e2e` now builds and runs Playwright; the `cypress:*` scripts are gone.
  [Web app testing § 3](guides/developer/web-app-testing.md#3-end-to-end-tests-playwright),
  [CI § 1.1](guides/developer/ci.md#11-tests-that-ci-does-not-run).
  - **Admin steps:** none to deploy. Optional: make `e2e` a required check of the knk-web-app rulesets on `main` and
    `next`. Locally run `npx playwright install chromium` once.

- **Plugin CI: Paper boot test** ([PandiO/knk-workspace#420](https://github.com/PandiO/knk-workspace/issues/420)) — no
  game change. knk-plugin's new `paper-boot.yml` workflow builds the shaded jar, starts a real Paper 26.3 server with it,
  WorldGuard 7.0.20 and WorldEdit 7.4.6 (pinned downloads with SHA-256 checks) and no API, and fails unless KnK logs its
  version stamp and "Plugin Enabled!" without errors or stack traces from KnK, WorldGuard or WorldEdit (errors caused
  by the unreachable API are excused). The log is uploaded as an artifact. `./gradlew :knk-paper:taggedTest` runs the
  excluded `requires-bukkit` tests; they are Mockito tests, not server tests, and making them pass is #499. See
  [CI § 7](guides/developer/ci.md#7-plugin-the-paper-boot-test).
  - **Admin steps:** none for servers. When it has been stable for a while, add the check `paper-boot` (workflow "Paper boot
    test") as a required check to knk-plugin's "Trunk and next" ruleset.

- **knk-web-api trunk renamed to `main`** — no game change; knk-web-api's default branch is now `main`, like the other
  repos (developer, 2026-11-14). GitHub redirects the old name and moved the open pull requests. The agent rules and
  skills, the docs-session prompt, the deploy guides and `scripts/nas-ops/stage-b/pc/knk-release.sh` now say `main`;
  older docs that name knk-web-api `master` with a commit hash still point at the right commit.
  - **Admin steps:** in a local clone, `git branch -m master main`, `git fetch origin`,
    `git branch -u origin/main main`, `git remote set-head origin -a`. Pull the updated `knk-release.sh` on the PC
    before the next API release. Check that the API's rulesets and the `release` environment's deployment-branch rule
    name `main` (or the default branch).

## 2026-11-13

- **Account and invitation guides** (PandiO/knk-workspace#299) — no game change; players now have one guide for
  getting an account with an invitation, linking Minecraft, logging in and resetting a password, and staff have one for
  issuing invitations and running the invite-only switches. The player guide
  [`users/account-player-guide.md`](guides/users/account-player-guide.md) replaces `PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md`
  (renamed and rewritten against the trunks of 2026-11-13). The new
  [invitations admin guide](guides/admin/invitations-admin-guide.md) covers personal invites and shared codes, their
  actions and limits, mails, the four switches, the admission gate and the Access card, the Cloudflare Access sync,
  kill switches and troubleshooting. The 2026-01 account developer guide moved to
  [`archive/`](archive/DEVELOPER_GUIDE_ACCOUNT_INTEGRATION.md) (Kotlin examples, removed `/account create`). The guides
  index now gives the email guide and the invitations smoke test their real state (merged, run, live on the alpha).
  Filed: #449 (landing page says Java only), #450 (Rotate on an expired shared code), #452 (plugin leftovers of
  `/account create`).
  - **Admin steps:** none.
- **Siege player guide** (PandiO/knk-workspace#297) — no game change; players now have one guide to sieges: how to
  join and vote, the hub and team split, spawn choice, objectives and how a match is won, fighting, siege gates, the
  navigation compass, gear and enchantment books, leaving and rejoining, the end of a match, rewards and match history.
  [guides/users/siege-player-guide.md](guides/users/siege-player-guide.md), written from knk-plugin `main` `57884e97`,
  knk-web-api `master` `75b5a00` and knk-web-app `main` `3ba747d`. The gate structures player guide no longer calls
  gate objectives "not live". Filed while writing it: #451 (a kit claimed from the menu during a match is lost at the
  restore) and #453 (changelog entries for the alpha run 1 Siege packages merged 2026-11-01).
  - **Admin steps:** none.
- **Navigation and teleport guides (docs)** — players now have one page on finding the way with `/navigate` and on
  every way to teleport (spawn, hub, warps, requests, `/back`), and staff one page on building the road network and
  setting up warps, spawn and teleport prices. No game change. New: [player guide](guides/users/navigation-and-teleports-player-guide.md),
  [admin guide](guides/admin/navigation-and-teleports-admin-guide.md) (road setup, upkeep and the reset script, the Road
  network page, warps, group prices and cooldowns, staff teleports, `all` forms and exemptions), written against
  knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00` and knk-web-app `main` `3ba747d`
  (PandiO/knk-workspace#298). Filed: #447 (decision: player homes). Admin steps: none.

- **Dashboard access in the web app; bulk delete** (PandiO/knk-workspace#280 AM3, #205) — staff now see only the
  dashboard types of the areas they work in, buttons they can't use are greyed out with the permission they need, and
  owners and Admins can delete many rows at once. Accepted by the developer 2026-11-13 without a live test and merged 2026-11-13 (knk-web-app `main` `e02ee79`, knk-web-api `master` `45043a7`, also on `next`); the smoke test is in closed alpha
  test run 2 (checklist § 4c).
  - **Web app:** the dashboard, the detail page and the form wizard open for any area node (`knk.admin.content`,
    `knk.admin.world`, `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`, `knk.admin.road`,
    `knk.admin.user.manage`); the explorer lists only the types of the areas held. New, Edit, Delete and ⚙ are disabled
    with "Requires <node>" from the metadata's `actionNodes`; the bulk **Delete (n)** is hidden without
    `knk.admin.delete.bulk` and for users and permission groups. Bulk delete confirms with the count and type, calls
    `POST api/Dashboard/bulk-delete` in chunks of 100, keeps refused rows selected and lists them with their reasons
    ("Show what uses it" for rows still in use). Export CSV reads through `POST api/Dashboard/export` (audited; CSV
    format unchanged). Players no longer request `api/Metadata` (a 403 on every page since AM2). Refused reads say
    "You don't have access to …"; labels and join entries fall back to `api/Lookup`; a picker's Create New needs the
    related type's create node. Entity setup's lists stay `knk.admin.content`; its configuration Delete also needs
    `knk.admin.delete`. Audit entries `DashboardBulkDelete` / `DashboardExport` have labels.
  - **API:** `DELETE api/FormConfigurations/{id}` and `api/DisplayConfigurations/{id}` need `knk.admin.delete` too
    (developer decision 2026-11-12 on LV7-8); bulk-delete refusals carry a `code` (`InUse`, `NotFound`, `Refused`,
    `Failed`).
  - **Admin steps:** no migration, no setting, no plugin change, no new package. Deploy the AM3 API and web app
    together, **API first** (AM1–AM3 belong together; AM1/AM2 are already on `master`). Accounts that delete form or
    display configurations need `knk.admin.delete` (Admin and the owner have it; backfilled content holders too).
    Smoke test: [dashboard access smoke test § 2.1, § 8](guides/dashboard-access-smoke-test.md).

- **AI agent workflow setup: CI, `next` branches, chain skills, agent tooling and the sessions archive** — no game
  change. Agents now have automatic checks on every push, a `next` integration branch to work on, two project skills
  for running feature chains, a fast compile check before they stop, and a slimmer sessions board. Merged 2026-11-13
  on the developer's request (PandiO/knk-workspace#327, setup chain of
  [DESIGN § 12](specs/ai-agent-workflow/DESIGN.md); [report](reports/2026-11-12-agent-workflow-setup-chain.md)).
  1. **CI** (#328): `.github/workflows/ci.yml` in knk-web-api (restore, build, test on .NET 8; MySQL tests skip
     themselves) and knk-web-app (Node 22: `npm ci`, tests, `tsc`, build), on every push and pull request. No test was
     red, so nothing is marked as a known failure. knk-web-api#12, knk-web-app#9.
  2. **`next` branches, labels, digest** (#329): `next` in all four repos; the "Daily digest" issue #333.
  3. **Chain skills and the branch model** (#330): `.claude/skills/knk-coordinator/` and `knk-link/`; the global
     instructions describe trunk = production, `next` = integration (in force now that CI runs on both trunks), risk
     tiers, coordinators merging link PRs into `next`, docs sessions merging their own docs PR into `next`, and the
     platform-independence principle in the vision. knk-workspace#334, knk-web-api#13, knk-web-app#10, knk-plugin#16.
  4. **Agent tooling** (#331): `.mcp.json` (GitHub, Playwright, Context7), a fast-check Stop hook, a permission rule for
     `add_repo` with a guard that allows only the seven PandiO knk repositories. Guide:
     [agent-tooling](guides/developer/agent-tooling.md). knk-workspace#335.
  5. **Sessions board archive** (#332): `scripts/sessions-archive/archive_sessions.py` moved 240 finished entries to
     [monthly archive files](reports/sessions-archive/README.md); the board drops from 489 KB to 65 KB. Finished rows
     now go straight to the current month's archive file. knk-workspace#336 (applied by cherry-pick and a script run).
  - **Admin steps:**
    1. On the developer PC: set `GITHUB_PAT` (fine-grained, the knk repositories) and optionally `CONTEXT7_API_KEY`,
       start Claude Code in knk-workspace and approve the three MCP servers in `/mcp`.
    2. Optional: a JDK 25 in the cloud environment's setup script, or `KNK_JDK25_HOME`, so the hook can compile the
       plugin there (guide § 3.7).
    3. No deploy, migration, `config.yml` key or API setting changes.

- **Deployment log and deploy records** (PandiO/knk-workspace#303) — no game change; the project now records which
  version runs on the closed alpha. New [`DEPLOYMENTS.md`](DEPLOYMENTS.md): one row per deploy (commits and release
  tags, seed or patch, migrations, config keys merged, scripts, checks, rollback), back-filled from the deploy reports
  of 2026-10-11 to 2026-11-02, the alpha's current state marked "to be confirmed by the developer". The
  [closed-alpha runbook § Every deploy](guides/closed-alpha-deployment-runbook.md#every-deploy-gate-tags-release-and-log)
  adds the deploy gate (open `documentation` issues), release tags through the components' Release workflow, the
  log row and a GitHub Release on knk-workspace per deploy ("What's new" and "Admin steps"). Tag naming for the deploy
  release is open in #444.
  - **Admin steps:** none.

## 2026-11-12

- **Admin web app: chain 3 (V1–V7) and chain 2's web app merged, with the access model's API part** — staff get a
  rebuilt admin web app: builders that save drafts and publish on purpose, a search-as-you-type relation picker, a
  detail page that links and unlinks properly, clearer settings pages, a staff player profile with freeze, CSV export,
  a grouped admin sidebar, live updates and one look for dialogs, tables and messages. Merged 2026-11-12 on the
  developer's "merge V7": knk-web-app `main` `1371951` (merge of `claude/builders-71`, which contains chain 3 V1–V7 and
  chain 2's X1 with W1–W4), knk-web-api `master` `bc97b7d` (merge of `claude/builders-71`: V7, V6, V5, #280 AM1+AM2,
  and through AM1 the API parts of P1 #261, chain 2 R1 #184 and X1 #183), knk-workspace `main` `84b7527` (V1–V7 docs).
  Smoke tests: V7 run by the developer 2026-11-11/12, all pass; V1–V6, W1–W4, X1 and the #280 API steps **not run**.
  **Not merged:** every plugin branch (chain 2 R1–R3, chain 3 P1–P3), #280 AM3 (web app) and AM4, P2, P3, and chain 2's
  workspace docs branches (W1–W4, X1, R1; docs follow-ups #337–#341). Reports:
  [chain 3](reports/2026-11-08-ux-chain-3.md), [chain 2](reports/2026-11-05-ux-chain-2.md). The entries below give
  each part.
  - **Admin steps:**
    1. Back up the database. Deploy **the API first**, then the web app. The plugin doesn't change (no plugin branch
       is merged, no `config.yml` key added); the web app needs no new package.
    2. Migrations, applied in this order (`dotnet ef database update`): `20261105200758_AddPrivacyErasureEvents` (R1,
       one new table), `20261108162526_AddKitClaimDelivery` (P1, two nullable columns on `kit_claims`),
       `20261108181026_SeedDashboardActionNodes` (AM1, data only), `20261109101501_AddConfigurationDrafts` (V7,
       additive; existing form and display configurations stay published).
    3. `SeedDashboardActionNodes` gives the Admin group `knk.admin.delete`, `knk.admin.delete.bulk` and
       `knk.admin.export` where its wildcard doesn't cover them, and `knk.admin.delete` + `knk.admin.export` to every
       explicit holder of an area node **except the Staff group** (developer decision 2026-11-08). Before deploying,
       check that the Admin group still holds `knk.admin.*` (the alpha seed has it): on a database built from
       migrations alone Admin gets only the three action nodes and no `knk.admin.content` / `knk.admin.world`, so it
       couldn't read the content and world types.
    4. The plugin must run with `api.auth.type: apikey` (the alpha does; check dev). Every dashboard read is gated
       now, and in `bearer` mode the plugin would need nodes for towns, domains, kits, menus and the rest.
    5. Optional API settings (env): `Realtime__WebLiveUpdatesEnabled` (default `true`; `false` sends no live web
       events), `Realtime__WebPermissionCacheSeconds` (30), `Privacy__ErasureFeedUuidRetentionDays` (35).
    6. **What changes for staff on deploy, while the web app part of #280 (AM3) is not merged:**
       - Every dashboard delete needs `knk.admin.delete` on top of the area node. The **Staff group no longer deletes**
         kits, siege setup, road profiles or user accounts and **can't export** (its other rights stay: balance
         changes, freeze, kick, ban). The web app still shows those Delete buttons; the API refuses with its reason.
       - Only the owner hands out `knk.admin.*`, bulk delete or a group carrying them, and changes a group ranked at
         or above the actor's own: **Admins can no longer edit the Admin group** from the web.
       - Every dashboard list, detail and search needs one of the type's read nodes. Admin (`knk.admin.*`) and the
         owner see everything; Staff keeps players, kits and siege setup (its own area nodes). Pickers in the merged
         form wizard and detail page fall back to name-only lookups; other pages reading another area answer 403.
       - Logged-in players without an area node get a handled 403 on `GET api/Metadata` on each page load (a console
         error, nothing visible; AM3 skips the call).
       - Export works for holders of `knk.admin.export` (owner, Admin, backfilled area-node holders); bulk delete has
         no button yet (AM3).
    7. Chain 2 R1 and P1 are in the API without their plugin parts: account erasures are recorded in the erasure feed
       but not pushed to the game server yet, and a web "Grant" of a kit is stored as a pending delivery that arrives
       only once P1's plugin part runs (then all pending grants are handed over).

- **Form and Display builders: save in place, explicit Publish, Duplicate, Generate from metadata, live preview** —
  staff can save a form or page they're still working on without changing what other staff see, and publish it when
  it's ready. [PandiO/knk-workspace#71](https://github.com/PandiO/knk-workspace/issues/71) (chain 3 V7). **Save**
  keeps the builder open and stores a draft: the form wizard and the detail pages keep the published version until
  you press **Publish…**, which first says what changes for staff (steps and fields added, removed or changed, the
  default it replaces, saved wizard drafts that continue). **Save and close** follows Save's rule and returns to
  Entity setup; leaving with unsaved changes asks "Leave without saving?". A new form is a draft (not offered to staff)
  until its first Publish. **Duplicate** copies the published version under a new name; **Generate from metadata**
  adds a step or section per group of the entity's properties with sensible field types; **Preview** shows the form or
  page next to the builder with sample values or a real record. Entity setup marks drafts and unpublished changes and
  has Duplicate. Migration `AddConfigurationDrafts` (additive), new endpoints `GET {id}/builder`, `POST drafts`,
  `PUT {id}/draft`, `POST {id}/draft/discard`, `POST {id}/publish`, `POST {id}/duplicate` on both configuration
  controllers (`knk.admin.content`), no setting. Known limit: field validation rules are saved at once, outside the
  draft (#291). Smoke test passed 2026-11-11/12:
  [guides/form-display-builders-smoke-test.md](guides/form-display-builders-smoke-test.md). Docs follow-up #345.

- **Form wizard relation picker: search as you type, the full table as a fallback; "Show what uses it" on a refused
  delete** — picking a town, street or item in a form is now a search box instead of a long table.
  [PandiO/knk-workspace#191](https://github.com/PandiO/knk-workspace/issues/191),
  [#44](https://github.com/PandiO/knk-workspace/issues/44) (chain 3 V6). The first matches appear as you type, rows
  created in the same form first, keyboard and mouse picking, and **Open full table** for the old table in a dialog.
  Staff without access to the related type search by name only (the #280 lookups). A delete refused because the
  record is still used offers **Show what uses it**: the records, linked when the viewer may open them, fetched only on
  request through the new `GET api/EntityReferences/{type}/{id}/rows` (one of the type's read nodes). No migration, no
  setting. Smoke test not run:
  [guides/relation-picker-and-delete-details-smoke-test.md](guides/relation-picker-and-delete-details-smoke-test.md).
  Docs follow-up #344.

- **Entity detail page: real Select / Unlink / Add, a separate Delete, readable values and errors** — removing a
  related record from a detail page now only unlinks it and never deletes it.
  [PandiO/knk-workspace#188](https://github.com/PandiO/knk-workspace/issues/188),
  [#189](https://github.com/PandiO/knk-workspace/issues/189) (chain 3 V5). Delete is a separate red action behind a red
  question; Select and Add pick an existing record in a searchable picker (a child of another parent asks "Move
  here?"), through the new `POST api/Relationships/{type}/{id}/{property}/link|unlink` (the type's write node; no
  delete node). Links that can't change here (required parents, locations, gates, kits, lootbox/siege setup, players)
  show the reason; actions the viewer can't use say "Requires …". Values read as text, related values link to their
  page, collections show a count and 12 per page, and load errors say what happened ("You don't have access to Town
  "Cinix"", "doesn't exist"). No migration, no setting. Smoke test not run:
  [guides/entity-detail-smoke-test.md](guides/entity-detail-smoke-test.md). Docs follow-up #343.

- **Settings pages: units and help, confirms on risky switches, lootbox preview; Lootbox settings, Currency policy and
  Road network on the settings shell** — every settings field now says its unit and what the value means, and risky
  switches ask first. [PandiO/knk-workspace#26](https://github.com/PandiO/knk-workspace/issues/26) (chain 3 V4). Web app
  only, no API change, no setting.
  - **Lootboxes → Settings**, **Currency policy** and **Road network** have the settings header of Game and Siege
    settings: changes counted, Discard, Reload, Save (n), "Leave without saving?" before leaving with changes (on the
    lootbox page also when switching tabs), a toast on save and the reason in the header when the API refuses.
  - Settings fields show their unit (ticks, s, h, ‰, bp, ×, coins, gems, boxes) and one line of help, with what the
    value means ("= 1 s", "= 2.5%", "= 12:00 (noon)"); on Siege and Game settings too.
  - Switching payments off or on (per currency), lootboxes off or on, a lootbox type's Enabled and a token grant rule
    ask first and say what happens.
  - Lootbox settings: the announce thresholds are choices with **Never** (was the number 11), both announcements have
    a preview with sample values, unknown placeholders are named. The Odds tab shows small chances as "1 in N".
  - Currency policy: one Save for coins and gems; the lowest sender title is picked from the titles (was a bracket
    id).
  - Road network: the navigation defaults no longer save on change; Save saves them together with the compass
    settings. Road profiles and stretches keep their own Save.
  - Smoke test not run: [guides/settings-pages-smoke-test.md](guides/settings-pages-smoke-test.md). Docs follow-up
    #342 (admin guides). Who saved last and one save for road settings need the API later (#190).

- **Staff player profile: status strip, tabs, freeze/unfreeze, timeline, paged audit; better player search** — staff
  can freeze and unfreeze a player from the web with a reason, and see a player's history on one timeline.
  [PandiO/knk-workspace#119](https://github.com/PandiO/knk-workspace/issues/119) web part (chain 3 V3). No API change.
  - The profile header shows online / last seen, mode, **Frozen**, **Payments locked**, premium tier and account flags
    as chips, with **Freeze** (reason required, saved on the player and in the audit log) and **Unfreeze**; while
    frozen, since when, by whom and why.
  - The cards are on six tabs: Overview, Economy, Permissions, Moderation, Activity, Privacy (`?tab=` in the URL).
  - Activity has a **per-player timeline** (audit log and, with `knk.admin.currency.history`, the balance ledger,
    newest first, "Load older", filter chips) and the **audit log paged by the server** with an action filter.
  - Actions without their node are disabled with "Requires <node>" (freeze, unfreeze, groups, grants, kit grant,
    payment lock). A freeze in game shows on an open profile at once (realtime on).
  - The profile no longer crashes on a summary without groups, permissions, title or salary.
  - Moderation → All players: a UUID without dashes finds the player, sort by username, email or coins, the search in
    the URL (Back returns to it), a Last seen column, and **Recently opened** profiles (this browser).
  - Smoke test not run: [guides/player-profile-smoke-test.md](guides/player-profile-smoke-test.md). #119 stays open
    for its API part (unfreeze reason, frozen state in the summary, game sessions in the timeline, search filters,
    kick/ban from the web).

- **Dashboard: checkbox selection and Export CSV** — staff with the export permission can download the rows they
  selected, or the whole search, as a spreadsheet file.
  [PandiO/knk-workspace#205](https://github.com/PandiO/knk-workspace/issues/205) export part (chain 3 V2).
  - The dashboard table has a checkbox column. Rows stay links, and the row click still opens the detail page.
  - A bar above the table shows "n selected" and **Export CSV**. The export holds the selected rows, or with nothing
    selected the current search across all pages in its sort.
  - The file has the table's columns in table order with the values the table shows. It is UTF-8 with BOM, named
    `<Type>-<yyyy-mm-dd>.csv`, holds at most 10,000 rows, and texts that look like formulas are neutralized.
  - Export needs `knk.admin.export` (owner, Admin and backfilled area-node holders since AM1; not the Staff group).
    The file is still built in the browser; AM3 moves it to `POST api/Dashboard/export`, and bulk delete follows in
    AM3 (#280). No API change, no setting.
  - Smoke test not run:
    [entity lists smoke test § 7](guides/entity-lists-url-state-smoke-test.md#7-checkbox-selection-and-export-csv-205-export-part-chain-3-v2).

- **Web app fixes: Entity setup at phone width, colour baseline, landing slideshow fade** — the landing page's
  pictures now fade through black, and Entity setup fits a phone screen.
  [PandiO/knk-workspace#266](https://github.com/PandiO/knk-workspace/issues/266),
  [#263](https://github.com/PandiO/knk-workspace/issues/263), [#258](https://github.com/PandiO/knk-workspace/issues/258)
  (chain 3 V1). Entity setup (`/forms/{type}`) no longer scrolls sideways at 390 px (it was 785 px wide): the
  configuration lists' buttons wrap under the title and the tables scroll inside their cards. `WorldBoundFieldRenderer`
  and `BannerLayersField` moved to the theme tokens, so no file is over its raw colour baseline, and `npm run test:ci`
  now fails when one is. The landing slideshow fades the image out to black and then the next one in (1.25 s each),
  preloads the next image, and swaps without fades under `prefers-reduced-motion`. No API change, no setting. Smoke
  test not run:
  [design themes guide § 8](guides/design-themes-comparison.md#8-smoke-test-entity-setup-at-phone-width-colour-baseline-landing-fade-chain-3-v1).

- **Dashboard access model, API part (AM1 + AM2)** — who may view, delete, bulk-delete and export each kind of record
  is now decided per area (content, world, players, kits, siege, …) by the API.
  [PandiO/knk-workspace#280](https://github.com/PandiO/knk-workspace/issues/280) (stays open for AM3, the web app, and
  AM4). Design: [specs/dashboard-access-model/DESIGN.md](specs/dashboard-access-model/DESIGN.md).
  - **AM1 (actions):** new nodes `knk.admin.delete`, `knk.admin.delete.bulk` and `knk.admin.export` on top of the
    area nodes. Every dashboard delete (users and permission groups included) needs the area node and
    `knk.admin.delete`; `POST api/Dashboard/bulk-delete` (area + delete + bulk, at most 100 ids, a reason per refused
    row, not for users and groups) and `POST api/Dashboard/export` (area + export, at most 10 000 rows), each with one
    audit entry (`DashboardBulkDelete`, `DashboardExport`). Only the owner hands out bulk delete, also through
    `knk.admin.*` or groups that carry it; nobody changes a group ranked at or above their own. Migration
    `SeedDashboardActionNodes` (data only; see the Admin steps above). Metadata names each type's area and action
    nodes; live web updates follow the area node.
  - **AM2 (reads):** lists, details and searches of a type need one of its read nodes (the area node, or the page node
    of a page that shows it: Game settings reads locations and towns with `knk.admin.config`, roads read towns and
    streets, kits and lootboxes read items, …), or the plugin's key. The form wizard's own reads (form and display
    configurations, metadata, validation), drafts and your own world tasks and workflow sessions are open to anyone
    holding **any** area node. New `POST api/Lookup/{type}/search` and `GET api/Lookup/{type}/{id}` give pickers and
    labels id, name and one short line (users: the username only) for any area node. Public pages, self reads and the
    plugin (with `api.auth.type: apikey`) are unchanged. No migration, no setting.
  - Smoke test (API part, draft) not run: [guides/dashboard-access-smoke-test.md](guides/dashboard-access-smoke-test.md).
    Follow-ups #285, #286.

- **Live updates in the web app (realtime S4)** — when another staff member saves something, the dashboard and the
  open detail page refresh by themselves, and player lists show who is online.
  [PandiO/knk-workspace#183](https://github.com/PandiO/knk-workspace/issues/183) (chain 2 X1, API and web app). The
  dashboard table of that type and an open detail page re-read quietly ("Updated by alice at 21:52"; a deleted entity
  says so with Back); the moderation list's Online/Offline badges and a badge on the player profile follow players
  joining and quitting. The API sends these over the existing web hub only to staff holding the node that gates the
  same data over REST (since AM1 the type's area node; users and presence `knk.admin.user.manage`), checked per message
  (cached 30 s). Without a hub connection everything works as before. No migration, no plugin change; optional
  `Realtime:WebPermissionCacheSeconds` (30) and `Realtime:WebLiveUpdatesEnabled` (default `true`; `false` sends no
  live web events, decision 2026-11-06). Smoke test not run (realtime smoke test § S4, on the unmerged workspace
  branch `claude/realtime-web-live-183`). Docs follow-up #341.

- **Web app admin navigation: grouped admin sidebar, breadcrumbs and titles from one route table** — every admin page
  is now in one sidebar grouped by topic, with a breadcrumb trail, and staff only see the pages they can use.
  [PandiO/knk-workspace#30](https://github.com/PandiO/knk-workspace/issues/30) (chain 2 W4; fixes
  [#262](https://github.com/PandiO/knk-workspace/issues/262), the Invitations link that never showed). One route-meta
  table (`src/routes/routeTable.ts`) gives every page its layout (public, player, admin; each with its own error
  boundary), its gate (the same nodes as before), its tab title and its place in the navigation. The top bar has Home,
  Leaderboards, Guides, Dashboard (for `knk.admin.content`, LW4-1) and Admin; the admin pages are in a grouped sidebar
  (Content, World, Players & support, Economy, Settings, Owner; an "Admin pages" menu below 1280 px) that shows each
  page only with the node its API checks. `/admin` lists the same pages with a line each. Every admin page has a
  breadcrumb trail ("Economy › Balance event log › Transaction"). URLs unchanged. No API change. Smoke test not run
  (admin navigation smoke test, on the unmerged workspace branch `claude/admin-ia-30`). Docs follow-up #340.

- **Web app data and format primitives: one table and pager, one date/number format, tied labels, a settings page
  with unsaved-change handling** — numbers and dates now show in the viewer's own language and time zone, and
  Game Settings asks before you leave with unsaved changes.
  [PandiO/knk-workspace#187](https://github.com/PandiO/knk-workspace/issues/187) (chain 2 W3). `DataTable` and `Pager`
  (rows as real links, sortable headers announced with `aria-sort`) draw the dashboard table, the form pickers and
  Player moderation's four lists. `utils/format.ts`: numbers and dates in the viewer's locale (LW3-1), API dates
  without a zone read as UTC; the detail page and Account → Transactions no longer show raw ISO dates. `Field` ties
  every label to its input. Game Settings and Siege configuration share one settings header: last saved, "n unsaved
  changes", Discard and Save (n), a question before leaving, reloading or discarding, a toast on save and the API's
  reason on a refusal. No API change. Smoke test not run (data primitives smoke test, on the unmerged workspace branch
  `claude/admin-ia-30`). Docs follow-up #339.

- **Web app feedback primitives: one accessible dialog, confirm with danger and a reason, general toasts** — every
  pop-up in the web app now behaves the same way, deletes ask in red, and "saved" messages are small toasts.
  [PandiO/knk-workspace#33](https://github.com/PandiO/knk-workspace/issues/33) (chain 2 W2). All 16 overlays (messages,
  confirms, child forms, the builders' editors and template pickers, the import panel, the Invitations and telemetry
  drawers) use one `Dialog`: labelled `dialog`/`alertdialog` with `aria-modal`, focus moved in and returned, Tab kept
  inside, Escape and × close it, a click outside only closes messages and questions (never a form), nothing closes
  while saving. Deletes and "Leave this form?" are red with focus on Cancel; a child form with unsaved changes asks
  "Leave this form?" before Escape or × close it (LW2-2). `useConfirm` can ask for a reason. Success is a toast; toasts
  have info/warning kinds, an optional action and wait while hovered. No API change. Smoke test not run (feedback
  primitives smoke test, on the unmerged workspace branch `claude/admin-ia-30`). Docs follow-up #338.

- **No "Entity setup" link in the nav** — staff open Entity setup with the dashboard's ⚙ on a type instead of a
  separate menu link. [PandiO/knk-workspace#197](https://github.com/PandiO/knk-workspace/issues/197) (chain 2 W1). The
  page (route `/forms`, unchanged) is also reached through the "Drafts (n)" menu's "All saved progress" or by URL; the
  nav's **Dashboard** link is the current one there, on the builders and on detail pages. Web app only, no migration,
  no setting. Smoke test not run (dashboard return smoke test § 14a, on the unmerged workspace branch). Docs follow-up
  #337.

- **API parts only, no visible change yet: account-erasure feed and pending kit deliveries** — nothing changes in game
  until the plugin parts are merged. [PandiO/knk-workspace#184](https://github.com/PandiO/knk-workspace/issues/184)
  (chain 2 R1): executing a data-deletion request records each erased account in a new erasure feed (migration
  `AddPrivacyErasureEvents`, `GET api/privacy/erasures?since=`, plugin key; former UUIDs kept 35 days,
  `Privacy:ErasureFeedUuidRetentionDays`) and pushes `AccountErased` to the game server, which today's plugin ignores.
  [PandiO/knk-workspace#261](https://github.com/PandiO/knk-workspace/issues/261) (chain 3 P1): a web "Grant" on the
  player profile is a pending delivery on its `kit_claims` row (migration `AddKitClaimDelivery`) plus a
  `KitDeliveryPending` notification; `POST api/Kits/deliveries/{claimId}/delivered` (plugin key only). Today's plugin
  ignores the notification, so granted kits still don't arrive until P1's plugin part is merged. Both issues stay open
  for their plugin parts.

## 2026-11-10

- **Plugin configuration reference (docs)** — server admins now have one page for every setting in the plugin's
  `config.yml`, and a checklist for bringing a server's file up to date at each deploy.
  [guides/admin/plugin-configuration.md](guides/admin/plugin-configuration.md) gives each key's default, meaning, safe
  values, origin issue and whether a restart, `/ce reload` or `/knk lootbox reload` picks it up (checked against
  knk-plugin `main` `121030f`). [`scripts/plugin-config/config_diff.py`](../scripts/plugin-config/config_diff.py)
  lists the keys a server's file is missing compared with a jar. Docs only, no code change
  ([PandiO/knk-workspace#295](https://github.com/PandiO/knk-workspace/issues/295)).
  - **Admin steps:** at the next plugin deploy to dev and alpha, run the merge checklist (§ 2). A file from plugin
    `d56e41da` (2026-10-24) lacks 43 keys; delete the obsolete `gates.cleaving` block (#259).
  - Follow-ups: `/knk config diff` in game ([#308](https://github.com/PandiO/knk-workspace/issues/308)); config
    comment fixes added to [#307](https://github.com/PandiO/knk-workspace/issues/307).

- **Cleaving's gate numbers as combat values** — Cleaving's extra gate damage, its charged strike and the strike's
  cooldown are now set by staff in the web app, and the Guides page shows the live numbers. knk-plugin `main`
  `121030f`, knk-web-api `master` `b5e57fa`, knk-web-app `main` `9a85238`, merged from `claude/cleaving-combat-values-259`
  (PandiO/knk-workspace#259; decisions 2026-11-05: level I plus a step per level). New Combat values: gate damage bonus
  per level, charged strike at level I and per extra level, strike cooldown change per level (the level-I strike
  cooldown is Cooldown length). Defaults are the old numbers (+25 % per level, strike 5/6/7/8, 60/50/40/30 s); `/ce
  info` shows a gate line. Guide: [admin guide § 1](guides/admin/custom-enchantment-combat-values-admin-guide.md#1-where-to-edit).
  Smoke test run by the developer, all pass.
  - **Admin steps:**
    - knk-web-api: apply migration `20261105200617_AddCleavingCombatValues` (four nullable columns; the API fills in
      Cleaving's defaults at startup).
    - Web app: import form seed `EnchantmentDefinition - Default (seed v5)` and make it the default.
    - Plugin `config.yml`: the `gates.cleaving` block is **removed** and no longer read. Delete it from the dev and
      alpha configs (a server that changed these numbers enters them in the web app instead):
      ```yaml
      gates:
        cleaving:                       # delete this block
          damage-bonus-per-level: 0.25
          charged-hit-multiplier: [5, 6, 7, 8]
          charged-cooldown-seconds: [60, 50, 40, 30]
      ```
      New message key (defaults from the jar until merged by hand): `custom-enchantments.messages.cmd-info-tuning-gate:
      "&8   gate hits +%gateBonus%%, charged strike %strike%x, strike cooldown %strikeCooldown%"`.
  - **Docs follow-up (PandiO/knk-workspace#306, 2026-11-10):** player guide
    [gate structures § Cleaving](guides/users/gate-structures-player-guide.md#cleaving-the-siege-enchantment-for-gate-doors)
    (what it does, the cooldown, where to see the live numbers), `/ce info`'s combat value lines in
    [COMMAND_CATALOG_V3 § 4](specs/user-features/COMMAND_CATALOG_V3.md), and the latest migration in
    [production installation](guides/production-installation.md). No knk-dev-db-seed change is needed: after
    `dotnet ef database update` the API fills Cleaving's empty columns at startup.
- **Chat tokens** — knk-plugin `main` `b8ab3a0f`, knk-web-api `master` `6f3edd1`, knk-web-app `main` `4d6e2ac`, merged from `claude/chat-tokens-233`
  (PandiO/knk-workspace#233). `#hand` shows the held item with its tooltip. Statistics and profile tokens (`#stats`,
  `#kills`, `#deaths`, `#kd`, `#streak`, `#wins`, `#playtime`, `#balance`, `#title`, `#xp`, `#discoveries`) also work as
  `#kills@Steve`. `#location` shares the position, and `#tokens` lists the tokens. They work in chat, `/msg`, `/r` and staff chat.
  - Privacy: a token shows what `/stats <player>` shows another player (new `audience=public` statistics read). Sharing your
    own private statistic asks first (make public / send without / never ask).
  - Limits: per message and a statistics cooldown, on the Game Settings page, off by default.
  - Nodes: `knk.chat.token.*` seeded for the Default group, `knk.chat.tokens.bypass` for the staff ranks.
  - Two API migrations. Guide and smoke test: [guides/chat-tokens.md](guides/chat-tokens.md); smoke test run by the developer, all pass.
  - Tab completion: `#kills@` + Tab offers the online players the viewer can see (staff/owner mode respected); the
    name in `#kills@Steve` has Steve's tab-list colour. The list opens on Tab only (vanilla chat has no trigger character).

## 2026-11-05

- **Guides: a public page for every custom enchantment and ability** — anyone, signed in or not, can look up what
  each Knights and Kings enchantment does, with its chance, cooldown, effects and damage per level. knk-web-api
  `master` `2e3dfeb`, knk-web-app `main` `a7b231d`, merged from `claude/enchantment-info-221` (PandiO/knk-workspace#221;
  decisions 2026-11-03: public, custom enchantments only, under a new Guides section). New anonymous read
  `GET /api/EnchantmentDefinitions/public/info`; pages `/guides` and `/guides/enchantments`, linked from the navigation
  bar (signed in) and the landing page (signed out). The numbers are the live combat values. Guide: [admin guide
  § 8](guides/admin/custom-enchantment-combat-values-admin-guide.md#8-the-public-info-page-221). Smoke test run by the
  developer, all pass.
  - **Admin steps:** none (no migration, no seed, no config).
- **World-task offers reach non-op staff, and "Send again"** — [PandiO/knk-workspace#239](https://github.com/PandiO/knk-workspace/issues/239)
  and [#240](https://github.com/PandiO/knk-workspace/issues/240), follow-ups of the developer's WT2 test; merged 2026-11-05 after the developer's smoke test (all steps work):
  knk-web-api `master` `453729e`, knk-plugin `main` `33122cf4`, knk-web-app `main` `4d0c6ed`. The plugin checks `knk.tasks` for an
  offer like a command's node (Bukkit or the knk permission model), so staff whose group grants it get the
  Accept/Decline line or the auto-claim; a refused player is told why, and the web app says "doesn't have world-task
  access" instead of "declined" (new offer state `NoPermission`). A waiting task's code card has **Send again** and
  **Hand off to…** (`POST api/WorldTasks/{id}/offer`, same busy check, same task and code) and shows only the
  `/knk task <code>` command. No migration. Checklist: [realtime smoke test § WT2 follow-ups](guides/realtime-smoke-test.md).

## 2026-11-04

- **Ability kills name the ability, the player and the item** — a player killed by Chaos or Flash Chaos now reads
  `Steve was killed with Flash Chaos by Alex using [Storm Blade]` instead of a plain melee kill. knk-plugin `main`
  `bd4eff6`, merged from `claude/death-messages-222` (PandiO/knk-workspace#222; decisions 2026-11-03: one pattern with
  per-enchantment overrides in `config.yml`, only direct Chaos / Flash Chaos kills). Other deaths keep the vanilla
  message; a siege match still shows none; the killer and statistics are unchanged. Guide: [admin guide
  § 7](guides/admin/custom-enchantment-combat-values-admin-guide.md#7-death-messages-for-chaos-and-flash-chaos-kills-222).
  Smoke test run by the developer, all pass (the `using <item>` part was added after the test, on request, and accepted 2026-11-11).
  - **Admin steps:** plugin `config.yml`, new block under `custom-enchantments:` (the jar's defaults apply until it is
    merged by hand):
    ```yaml
    custom-enchantments:
      death-messages:
        enabled: true
        default: "%victim% was killed with %enchantment% by %player% using %item%"
        overrides: {}
    ```
- **Chaos and Flash Chaos hit as hard as staff set them** — the area damage, the damage and knockback radius and a
  separate gate damage of Chaos and Flash Chaos are combat values in the web app (defaults unchanged: 40 / 60 within
  3 blocks, knockback within 5). knk-plugin `main` `813b9cc` (with #222 in `bd4eff6`), knk-web-api `master` `369fd1c`,
  knk-web-app `main` `8613916`, merged from `claude/area-damage-223` (PandiO/knk-workspace#223; decisions 2026-11-03:
  damage grows with the level multiplier, gate damage is its own value). `/ce info` shows an area line. Guide: [admin
  guide § 1](guides/admin/custom-enchantment-combat-values-admin-guide.md#1-where-to-edit). Smoke test run by the
  developer, all pass.
  - **Admin steps:** knk-web-api migration `20261103202219_AddEnchantmentAreaDamage` (four nullable columns; startup
    fills the defaults); web app: import form seed `EnchantmentDefinition - Default (seed v4)` (or v5 from #259) and
    make it the default; plugin `config.yml`, new message key (jar default until merged):
    `custom-enchantments.messages.cmd-info-tuning-area: "&8   area damage %areaDamage% within %damageRadius% blocks, gates %gateDamage%, knockback within %effectRadius% blocks"`.
- **Page background: landing image 1 behind every page, on by default** — knk-web-app
  `main` `1cbee21`, merged from `claude/page-background-image-231` (PandiO/knk-workspace#231; developer approved 2026-11-04 after the live
  comparison, on by default). Every visitor can turn it off with the "Background image" item under the themes in the
  cogwheel theme switcher (remembered per browser), per tab with `?bg=off`, or for a whole build with
  `REACT_APP_PAGE_BACKGROUND=off`. The page backdrop (75 %), cards and tables (85–92 % per theme) and the auth backdrop
  (75 %) turn translucent over a 104 kB AVIF / 153 kB WebP copy of the image; fields, menus, dialogs and sticky bars
  stay solid. Text keeps WCAG AA over the image's darkest and lightest pixel (contrast test extended). The landing page
  keeps its slideshow and loads image 1 once. Guide: [guides/design-themes-comparison.md](guides/design-themes-comparison.md) § 7.

- **World tasks and the realtime channel merged** — 2026-11-04 at the developer's request after the smoke tests of #180 (all steps work or accepted) and #181 WT2 (works or accepted; follow-ups for step 6 and 10 filed): knk-web-api `master` `2258df5`, knk-plugin `main` `e1b6a7a9`, knk-web-app `main` `d0c2ba8`, knk-workspace `main`. Merges `claude/world-task-hardening` and `claude/realtime-signalr` (S1, S2, WT2, S3); one additive migration (`AddWorldTaskHardening`, back up first: the first sweep removes week-old sessions without a draft). The plugin keeps `realtime.enabled: false` until set; an existing server `config.yml` needs the `realtime:` block added by hand, and the web app needs `npm install` (new `@microsoft/signalr`). S1, S2 and S3 were not run as checklist sections. The five entries below were written for the feature branches; branch names in them are historical.
- **Realtime channel, S1 foundation** ([PandiO/knk-workspace#178](https://github.com/PandiO/knk-workspace/issues/178), merged 2026-11-04): SignalR hubs in the API (`/api/hubs/game`
  with the plugin key and `X-Knk-Server-Id`, `/api/hubs/web` with the JWT), a publisher with per-connection
  sequence numbers, and presence from the game server (roster on every connect, join/quit, 60 s grace) in
  `User.IsOnline`. The plugin connects with backoff, pauses while the API is down and re-reads its caches on every
  (re)connect; `realtime.server-id` replaces the hard-coded `localhost` on world-task claims. Off by default
  (`realtime.enabled: false`); no business events yet (S2). Checklist: [realtime smoke test](guides/realtime-smoke-test.md).
- **Realtime channel, S2 user state** ([PandiO/knk-workspace#179](https://github.com/PandiO/knk-workspace/issues/179), same
  branch): rank and group membership, permission grants, permission group edits, balances, freeze, active mode and
  other user fields changed in the web app (or by a rank expiring) reach an online player at once instead of after
  the 2 s poll, the 30 s permission cache, the 60 s user cache or a rejoin. A permission change also drops the
  player's remembered offline answers (#76). Player notifications are pushed; the 2 s poll stops while connected. The
  API sends events only after the database transaction committed. New optional plugin key
  `realtime.fallback-poll-multiplier` (default 4). Still off by default. Checklist: realtime smoke test § S2.
- **World tasks over the realtime channel (WT2)** ([PandiO/knk-workspace#181](https://github.com/PandiO/knk-workspace/issues/181),
  branch `claude/realtime-signalr` in knk-web-api, knk-plugin, knk-web-app and knk-workspace; the branch contains the
  world-task hardening below): "Send to Minecraft" offers the task to you in game and claims it there at once when you
  are online (no code to type); if you already hold a task the web app asks Queue / Hand off / Replace / Cancel;
  "Hand off to…" sends it to another online admin, who gets Accept/Decline in chat (2 min). The task code is always
  shown as the fallback. The web app follows the task live (web hub, `@microsoft/signalr`), a cancel in the web app
  stops the task in game at once, and headless scans start at once. With `realtime.enabled: false` (the default)
  everything works as before. Checklist: [realtime smoke test](guides/realtime-smoke-test.md) § WT2.
- **Realtime channel, S3 config and entity push** ([PandiO/knk-workspace#182](https://github.com/PandiO/knk-workspace/issues/182),
  branch `claude/realtime-signalr` in knk-web-api, knk-plugin and knk-workspace): a gate, a domain's entry/exit rules,
  game and hub settings, siege, lootbox, warp, navigation, road and telemetry settings, and the entities the game
  server caches (towns, districts, structures, items, kits, menus, grades, tags, title brackets, users, ...) edited in
  the web app are in effect on the running server within about two seconds instead of after a reload, a timer or a
  cache TTL. A gate held by a running siege match takes its edit after the match. The game server reports its worlds
  over the hub, and the siege's startup work that failed because the API was down (lobbies, title brackets, stale
  gates, unfinished matches; #31) runs again when the hub reconnects. The periodic re-syncs stay as a slower safety
  net. Still off by default (`realtime.enabled: false`); no new setting, no migration. Checklist: realtime smoke test § S3.
- **World tasks that always end, and tasks anchored to the form draft** — PandiO/knk-workspace#180 (WT1 of #66),
  branch `claude/world-task-hardening` in knk-web-api, knk-plugin, knk-web-app and knk-workspace. A task now ends
  Completed, Failed, Cancelled or Expired: it expires after 30 min unclaimed, a claim lasts while the game server sends
  heartbeats (released to Pending after 3 min without), and in-game `cancel`, quitting or a server restart hand it back
  with its task code; `discard` and the web app's "Cancel task" cancel it. Only one player can claim a task (409), the
  task code is checked and unique among open tasks, and the command is `/knk task <code>` (id claims need
  `knk.tasks.any`). The first task of a form saves the draft silently; a resumed draft keeps its workflow session and
  its fields find their tasks again, including results finished while the form was closed. Leaving the form cancels its
  open tasks; the form builder offers only task types the game server can run. Smoke test:
  [world-task-hardening-smoke-test.md](guides/world-task-hardening-smoke-test.md). One additive migration.

- **Hygiene and docs batch** — merged 2026-11-04: knk-web-api `master` `71b814c`, knk-web-app `main` `22100c3`,
  knk-plugin `main` `ed750ddf`, knk-workspace `main` `559124c`. The plugin's version is stamped at build time, `0.1.0+<commit>` (`dev`
  without git), and logged with the commit as the first startup line; CI passes `-PgitCommit=<sha>`
  ([#136](https://github.com/PandiO/knk-workspace/issues/136)). A plain `dotnet build` works on Linux at the API's repo
  root ([#106](https://github.com/PandiO/knk-workspace/issues/106)). The admin client-activity totals no longer count
  each request twice or add up across hours; a ConditionalRequired rule now really makes a field required: its config is
  `{"condition":{"op","value"}}` (older forms still read) and values compare by text; the unused
  `FieldValidationService` is gone; all API tests green ([#99](https://github.com/PandiO/knk-workspace/issues/99), 2026-11-04). Dead code removed: the API's
  `ExtractLocationDataFromTaskOutput` and the web app's location `worldName` default `'world'`
  ([#147](https://github.com/PandiO/knk-workspace/issues/147)). Docs: production-installation G10/§ 12.3 metrics
  ([#48](https://github.com/PandiO/knk-workspace/issues/48)), Game Settings § 3.6 runtime worlds per server (#147),
  stale statements in the legacy, teleport, siege and specs README docs
  ([#135](https://github.com/PandiO/knk-workspace/issues/135)).

- **Dashboard explorer: filter by display and form configuration** — knk-web-app `main` `738c16a`, merged from
  `claude/explorer-filter-226` (PandiO/knk-workspace#226, UX/realtime chain link 3c; live-tested 2026-11-03/04). A filter button next to the sort button narrows the type list
  to types with or without a published default display configuration and with or without a form configuration
  (a dropdown Any / Yes / No each), remembered per browser like the sort. Smoke test
  [guides/dashboard-return-smoke-test.md](guides/dashboard-return-smoke-test.md) § 9c.
- **Open form without the type overview card** — knk-web-app `main` `738c16a`, merged from
  `claude/form-hide-type-card-227` (PandiO/knk-workspace#227, UX/realtime chain link 3c; live-tested 2026-11-03/04). A form opened from the dashboard or the Entity setup page no
  longer has the entity type card ("EnchantmentDefinition (EnchantmentDefinition) 19 fields ▸ Fields") above it; the
  Entity setup page keeps it while no form is open. Smoke test
  [guides/dashboard-return-smoke-test.md](guides/dashboard-return-smoke-test.md) § 10a.
- **Register page: link-code field with the dash** — knk-web-app `main` `738c16a`, merged from
  `claude/register-code-mask-229` (PandiO/knk-workspace#229, UX/realtime chain link 3c; live-tested 2026-11-03/04). `/auth/register`'s link-code field is the same masked field as
  `/link` (`____-____`, the dash drawn by the field; O, I and L are kept for `/account link` codes). A code refused as
  a link code that is a live claim code from the disconnect screen goes on to `/link`, verified. Smoke test
  [guides/invitations-smoke-test.md](guides/invitations-smoke-test.md) § 4 steps 16 and 17c.

- **Dashboard menus and entity table follow the theme** — knk-web-app `main` `596c51a`, merged `--no-ff` from
  `claude/tokens-dashboard-menu` (PandiO/knk-workspace#95 follow-up). The "New with" / "Drafts" menus and the entity
  table (search box, sortable headers, selected-row stripe, links, paging text) use the theme tokens instead of fixed
  greys and green, so they change with the theme. In `current` only the menu items' text is a shade darker.

- **Shield banner patterns and armour trims on item blueprints and item instances** — knk-web-api `master` `93f9380` (migration
  `AddItemShieldBannerAndArmorTrim`, form seed `ItemBlueprint.json`, re-import it), knk-plugin `main` `497e0fe`, knk-web-app `main` `4dd11d0`,
  merged `--no-ff` from `claude/shield-banner-trim-232` ([PandiO/knk-workspace#232](https://github.com/PandiO/knk-workspace/issues/232);
  developer smoke test 2026-11-04: shield pattern checks passed, armour trim accepted). A shield's base colour and its
  pattern layers (bottom to top) and an armour piece's trim (pattern + material) are stored on the blueprint, copied
  onto each minted instance (frozen, like the grade; `/knk item more` clones copy them), applied when the plugin builds
  the item, and scanned back by the item and kit scans. The web app edits them on the blueprint form (new field type
  `BannerLayers`) and shows them on the item instance detail. The armour trim check asked for in #232 found no trim
  support in any repo; it was added. Smoke test: [guides/shield-banner-trim-smoke-test.md](guides/shield-banner-trim-smoke-test.md).
  Architecture: [item render pipeline § 2c](architecture/item-render-pipeline.md).

- **Theme switcher as a cogwheel, for every visitor** — knk-web-app `main` `865fe53`, merged `--no-ff` from
  `claude/theme-switcher-button` (PandiO/knk-workspace#95, developer request 2026-11-04). A cogwheel button opens the
  themes (Current, Brand, Brand (red), Proposal, each with a short description): in the navigation bar when logged in,
  floating in the top-right corner of the landing and auth pages when logged out, so new visitors can try them. The
  themes left the account menu. `REACT_APP_THEME_PICKER=off` hides it; the alpha build no longer sets `on`. Guide:
  [guides/design-themes-comparison.md](guides/design-themes-comparison.md) § 1.

## 2026-11-03

- **Flash Chaos's debuffs are adjustable, and abilities show their cooldown** — staff set Flash Chaos's Slowness
  level and duration and its Nausea duration in the web app, and a player who used an ability sees a grey boss bar
  counting down until it is ready again. knk-plugin `main` `4f29e9c3`, knk-web-api `master` `c4c7772`, knk-web-app
  `main` `ff83295`, merged from `claude/enchantments-201-202` (PandiO/knk-workspace#201, #202). Defaults unchanged
  (Slowness I 5 s, Nausea 12.5 s). Bars for Chaos, Flash Chaos, Health Boost, Armor Repair, Resistance, Invisibility,
  Freeze (per attacker) and Cleaving's strike; the navigation bar stays on top. Guide: [admin guide § 1, §
  6](guides/admin/custom-enchantment-combat-values-admin-guide.md#6-ability-cooldown-bars-202). Tested by the developer.
  - **Admin steps:** knk-web-api migration `AddEnchantmentEffectLevels` (two nullable columns; startup fills the
    defaults); web app: import form seed `EnchantmentDefinition - Default (seed v3)` (or a later version) and make it
    the default; plugin `config.yml`, new message key (jar default until merged):
    `custom-enchantments.messages.cmd-info-tuning-effects: "&8   effect level %effectLevel%, second effect %secondDuration%s"`.
- **Invisibility keeps its swirl particles** — knk-plugin `main` `8f11bed5`, follow-up of #211 (developer decision):
  the ability's potion shows the normal particles again.
  - **Admin steps:** none.
- **Dashboard explorer: favourites are copies** — knk-web-app `main` `a6d83c9`, merged from
  `claude/explorer-favourite-copies-225` (PandiO/knk-workspace#225, UX/realtime chain link 3c). A starred type shows under "Favourites" at the top and still
  in the full list below ("All entity types") at its usual place, so nothing goes missing from the list. Smoke test
  [guides/dashboard-return-smoke-test.md](guides/dashboard-return-smoke-test.md) § 9b.
- **Code entry pages centred** — knk-web-app `main` `603843d`, merged from `claude/code-entry-centred-228` (PandiO/knk-workspace#228, UX/realtime
  chain link 3c). While the code entry is all the card holds (`/link` before the code is verified, `/join` before the
  invitation is valid), its text, label, hint and error are centred like the code; steps with more on them stay
  left-aligned. Smoke test [guides/invitations-smoke-test.md](guides/invitations-smoke-test.md) § 4 step 17b.
- **Error text dark red again** — knk-web-app `main` `8e6c48a`, merged from `claude/danger-text-230`
  (PandiO/knk-workspace#230). A bug in #95's token codemod had split `text-danger-strong` into a class that doesn't
  exist on 12 lines in 8 files (login, register, `/link`, invite sign-up, form wizard, table errors); restored, the
  codemod rule fixed and a unit test guards against unknown token classes.

- **Design tokens and switchable themes (rebrand phase 1)** — knk-web-app `main` `c02b365`, merged
  `--no-ff` from `claude/design-tokens-95` (PandiO/knk-workspace#95, #92; compared live by the developer 2026-11-03). Every colour of the web app is now a theme token (CSS variables that
  Tailwind reads), with three themes to compare live: `current` (today's look, the default), `brand` (the 2020
  styleguide: orange primary and call to action, black navigation, Lato 2.015, headings in the
  Enchanted Land demo font) and `proposal` (charcoal, orange accents, red only for danger, warm neutrals, Cinzel headings). Staff switch them in
  the account menu; `?theme=` picks one per tab. A unit test checks WCAG AA contrast of every token pair in every
  theme. Accessibility fixes in all themes: `text-gray-400` → a 4.5:1 secondary text colour, a focus ring on every
  text field, 3:1 field borders, a visible red border and an icon on field errors, darker primary-button hover.
  Compared live by the developer 2026-11-03; fix round: `brand` primary is the guide's orange (black text,
  a darker orange for links), red stays for danger and as an accent; the decorative heading font only on
  player-facing pages (Lato on admin pages); full-bleed dark auth and landing pages in `brand`/`proposal`; the alpha
  build shows the picker to testers (`REACT_APP_THEME_PICKER=on`). A fourth theme, `brand-red`, is `brand` with the
  brand red as primary, to compare red and orange. Guide:
  [guides/design-themes-comparison.md](guides/design-themes-comparison.md).

- **Entity lists: table state and tabs in the URL, rows as links, "Drafts (n)" and "New with"** — knk-web-app
  `main` `44f9395`, merged `--no-ff` from `claude/entity-lists-url-state` (PandiO/knk-workspace#39, #177 follow-up; UX/realtime chain link 9; smoke test passed 2026-11-03). The
  dashboard's page, search and sort are in the URL (`/dashboard/Street?page=2&q=north&sort=name&dir=desc`), so Back,
  a refresh, a shared link and coming back from a form or the detail page keep the view. Rows are links to the
  detail page (middle-click, Ctrl/Cmd-click, keyboard); sortable headers are keyboard buttons with `aria-sort`. The
  lootbox and moderation pages keep the selected tab in `?tab=`, and the moderation tables' player names link to the
  profile. Next to "New {Type}": a ▾ "New with" menu for the type's other form configurations and a "Drafts (n)" chip
  that resumes one of your open drafts. The form wizard's pickers are unchanged (they keep their state in the table,
  not the URL). Web app only. Smoke test:
  [guides/entity-lists-url-state-smoke-test.md](guides/entity-lists-url-state-smoke-test.md).

## 2026-11-02

- **Invisible means invisible: no floating armour or held items** — while the Invisibility ability is active, other
  players no longer see the user's armour or what they hold; the user stays in the tab list and can still be hit.
  knk-plugin `main` `da422f3b`, merged from `claude/invisibility-full-hide` (PandiO/knk-workspace#211). Siege teammates
  and spectators still see everything; it ends with the invisibility (time, milk, death, a command) and on quit. Guide:
  [admin guide § 5](guides/admin/custom-enchantment-combat-values-admin-guide.md#5-what-players-see-boss-bars-and-hidden-name-tags-169-170).
  Known limit: arrows stuck in the body can still show.
  - **Admin steps:** none.
- **Item lore wraps; item scans leave out generated lore** — knk-plugin `main` `27798ab` and knk-web-app `main`
  `b770597`, merged `--no-ff` from `claude/item-lore-212-40-0ud18o` (PandiO/knk-workspace#212, #40; smoke test
  accepted 2026-11-03). A lore line wider than `lore.max-width` (default 40 visible characters) continues on the next
  line in the same colour: blueprint item descriptions and origin lines, every menu's lore, and the kits menu's
  rank-rule line. Scanning an item in the ItemBlueprint form (or a kit with KitScan) fills Display description with
  only the description as written: no custom-enchantment, Grade or Origin lines, and no wrapped pieces. See
  [item-render-pipeline.md](architecture/item-render-pipeline.md) § 2a/2b.

## 2026-11-01

- **Invitation code fields with fixed `KNK-` and dashes** — knk-web-app `main` `1c9524d` (PandiO/knk-workspace#208,
  QOL hotfix after alpha test run 1). The invitation code fields on `/join` and `/link` show `KNK-_____-_____` from
  the start; the player types only the 10 characters, and a pasted `KNK-ABCDE-FGHJK` (with or without dashes or the
  `KNK` prefix) lands as the same code.
- **Claim code field centered** — knk-web-app `main` `eac1013` (PandiO/knk-workspace#206, QOL hotfix after alpha
  test run 1). On `/link` and `/account` the code and its `____-____` mask now sit in the middle of the field
  instead of against its left edge; typed characters still land on their slots.
- **Form wizard: footer, unsaved-changes guard, blur validation, Save on any step; drafts per admin** —
  knk-web-app `main` `b3b415d` and knk-web-api `master` `8df59b7`, merged `--no-ff` from `claude/form-wizard-edit-mode` (PandiO/knk-workspace#109, #186, #64 FormWizard part;
  UX/realtime chain link 5, 2026-10-26; fix round 2026-10-27 after the developer's live test). Live-tested sections 1–6. The form's buttons (Cancel, Previous, Save
  Draft, Next/Submit) stick to the bottom of the window; leaving a form with unsaved changes (a link, Back, the
  breadcrumb, a reload) asks first, and Cancel no longer asks when nothing changed — "changed" means the values
  differ from the ones the form was opened with (or last saved with Save Draft), on any step: typing and clearing a
  field again is no change, and moving on with Next does not count as saving; a field is checked when it loses the
  focus, and a refused Next shows a summary that links to the fields; editing an existing entity can be saved from
  any step ("Save changes"); one-line text fields are inputs ("Multi-line text" toggle in the field editor for the
  rest). Drafts and workflow sessions now belong to the logged-in admin (they were all saved as user 1, so Saved
  Progress was shared): the API takes the owner from the login. One-time cleanup after deploy and a backup:
  `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql`. The debug logs in the form wizard are gone.
  Live checklist: [guides/form-wizard-edit-mode-smoke-test.md](guides/form-wizard-edit-mode-smoke-test.md).

## 2026-10-26

- **Dashboard explorer: one scrollbar, favourite types on top** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/dashboard-explorer-194`
  (PandiO/knk-workspace#194; UX/realtime chain link 3b, 2026-10-26). The explorer's list is the only thing that
  scrolls (it showed two scrollbars). A star on every type marks it a favourite: favourites are listed at the top
  A–Z, the rest A–Z below; kept per browser (localStorage). Live checklist: `guides/dashboard-return-smoke-test.md`
  section 9a.
- **Dashboard header spacing** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/dashboard-header-195` (PandiO/knk-workspace#195; UX/realtime
  chain link 3b, 2026-10-26). The dashboard no longer starts against the app's top header: explorer, title and the
  "New {Type}" / ⚙ buttons start 24 px lower, on one row, centred on each other and lined up with the table; the
  buttons are the same height, and on a phone a long "New {Type}" is cut off instead of pushing ⚙ off-screen. Live
  checklist: `guides/dashboard-return-smoke-test.md` section 8a.
- **Claim code field shows the dash from the start** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/claim-code-dash-196`
  (PandiO/knk-workspace#196, follow-up of #192; UX/realtime chain link 3b, 2026-10-26). On `/link` and `/account/link`
  the field shows `____-____` while empty and keeps the dash visible while the first four characters are typed
  (`K7__-____`); paste, autofill, Backspace/Delete across the dash and capitals work as before. Pasting the same code
  without its dash over the whole field no longer loses a character. Live checklist: `guides/invitations-smoke-test.md`
  step 17a.
- **Dashboard keeps its place; Submit waits for the save** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/kng-60-dashboard-hub`
  (PandiO/knk-workspace#177 link 1, #58; UX/realtime chain link 1, 2026-10-26). Not live-tested yet. The
  dashboard's type is in the URL (`/dashboard/{type}`; bare `/dashboard` reopens the last viewed type). Edit opens the
  form with `returnTo`, and Submit and Cancel go back to that dashboard type (the table reloads). Submit stays
  "Submitting…" with a "Saving {Type}…" line until the entity is saved; a second click does nothing. The draft is marked
  Completed only after the entity was saved. A success toast replaces the 3 s "Form completed" modal. Live checklist:
  `guides/dashboard-return-smoke-test.md`.
- **Dashboard as the CRUD hub: New, Configure, breadcrumbs, detail page header, Create New from metadata** — knk-web-app
  `main` `7ba0f4b`, merged `--no-ff` from `claude/kng-60-dashboard-hub` (PandiO/knk-workspace#177 link 2, #81, #39 Create New menu; UX/realtime chain link 3,
  2026-10-26). Not live-tested yet. "New {Type}" and a cogwheel to the type's Entity setup page next to the
  dashboard title, "New {Type}" in an empty table. One flat explorer list; types without a display configuration are
  marked and their View is disabled. An open form hides the explorer and shows a breadcrumb back to where it was opened.
  The detail page shows the entity's name with Back, Edit and Delete and its own tab title. Edit on a User row opens the
  player profile. The nav "Create New" menu lists every type the app can create (from the entity metadata; no more
  `itemType`, about 15 types added) and navigates once. The nav and page "Forms" are now "Entity setup" (route `/forms`).
  Live checklist: `guides/dashboard-return-smoke-test.md` sections 8–14.
- **Game Settings and Siege settings open only for the node their API checks** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/route-gates-185`
  (PandiO/knk-workspace#185; UX/realtime chain link 2, 2026-10-26). Not live-tested yet. `/admin/game-settings`
  and its nav link need `knk.admin.config`, `/admin/siege-configuration` and its link `knk.siege.admin.manage`
  (before: the moderator node `knk.admin.user.manage`, so a moderator got an editable page, "The hub-eligible domains
  could not be loaded" and a refused Save). Without the node the link is hidden and the page says "Staff only" with the
  node it needs. Live checklist: `guides/alpha-hardening-smoke-test.md` step 27a.
- **Buttons and inputs look as intended** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/styling-quick-wins-38` (PandiO/knk-workspace#38;
  UX/realtime chain link 2, 2026-10-26). Not live-tested yet. `primary-dark` exists (`#1d4ed8`), so the primary
  CTAs (login, register, account, every `FeedbackModal` confirm) darken on hover; `.btn*` are `inline-flex` with a gap,
  so an icon sits beside its label instead of above it; `btn-tertiary` (Save Draft) is styled; form fields that set
  `border-gray-300`/`border-slate-300` without a width (Game Settings, the builders, lootbox filters) and `.input` show a
  1px border. The `text-gray-400` contrast sweep stays with #95. Live checklist: the link 2 block of
  `reports/2026-10-26-ux-realtime-chain.md` (knk-workspace `main`).
- **Claim code fields show the separator themselves** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/claim-code-field-192`
  (PandiO/knk-workspace#192; UX/realtime chain link 2, 2026-10-26; closed alpha test run 1, #149). Not live-tested yet. On `/link` and `/account/link` the code field shows `XXXX-XXXX` as the player types or pastes the 8
  characters (with or without a dash, or with a space); the player never types the dash, the caret stays put, and
  Backspace/Delete work across it. The register page's invitation step checks 8 plain characters as a claim code
  first and goes on to `/link` verified when it is one. The separator is one constant (`CLAIM_CODE_SEPARATOR`, a dash
  until the testers decide; the API and the disconnect screen use a dash too). The link-code field and its #57 hints are
  unchanged. Live checklist: `guides/invitations-smoke-test.md` step 17.
- **A menu item that opens `/menu`; no more ghost blocks for Bedrock players** (back-fill, written 2026-11-13) — every
  player now has a nether star in the right-most hotbar slot that opens the main menu with a click, and on Bedrock
  (console) a block you may not break no longer disappears on your screen only. knk-plugin `main` `3550cbbe`, merged
  `--no-ff` from `claude/alpha-run-1-console-nav` on 2026-10-26
  ([PandiO/knk-workspace#160](https://github.com/PandiO/knk-workspace/issues/160) commit `003cce95`,
  [#161](https://github.com/PandiO/knk-workspace/issues/161) commit `cb659fd1`; closed alpha test run 1 package D,
  [report](reports/alpha-tests/test-run-1/2026-10-26-package-d-console-navigation.md)). The same merge carries the
  Siege gate-approach fix for the compass ([#176](https://github.com/PandiO/knk-workspace/issues/176), commit
  `ddc74e2c`), which is not part of this entry. Not live-tested yet: the checks are in
  [test run 2's checklist](reports/alpha-tests/test-run-2/test-run-2-checklist.md) (console block).
  - **Menu item (#160):** a `Menu (click to open)` nether star is given at every join when missing and back at
    respawn, in slot 8 by default; a player's own item in that slot is moved to a free slot, and with a full inventory
    nothing is given. Right-click (in the air, or on a block that does nothing itself; sneak to use it on a door,
    chest or button), left-click, or a click on it in the player's own inventory opens `/menu`. It never drops (death
    included), can't be moved, placed or put in a chest, crafting grid or item frame, and is skipped by kit scans.
    Everyone gets it by default (`give-to: all`); whether it gets in the way for Java players is decision D10 of
    [test run 2's preparation](reports/alpha-tests/test-run-2/test-run-2-preparation.md). Player side:
    [menus player guide](guides/users/menus-player-guide.md#the-menu-item).
  - **Ghost-block resync (#161):** a Bedrock client removes a block as it mines it, before the server answers. When
    the break is refused (WorldGuard, region rules, the hub, a gate, any plugin), the plugin now sends the real block
    (and the other half of a door, tall plant or bed) to that player again every `interval-ticks` while they keep
    swinging, and once more `window-ticks` after the last swing. It catches every refusal in one place (cancelled
    break or block-damage event, or a denied left-click), so new protections need nothing extra. Needs Floodgate;
    Java players are left alone unless `all-players` is on (testing only).
  - **Admin steps:** plugin only; no API change, migration or script. Merge the two new sections into the server's
    `config.yml` by hand (the plugin never adds keys to an existing file; without them it runs on these defaults) and
    restart. See [plugin configuration § 4.14](guides/admin/plugin-configuration.md#414-lore-menus-crossplay). Under
    `menus:`:

    ```yaml
      menu-item:
        enabled: true
        give-to: all              # all | bedrock (Floodgate players only)
        give-on-join: true
        keep-on-death: true
        material: NETHER_STAR
        name: "&6&lMenu &7(click to open)"
        lore:
          - "&7Opens the Knights & Kings menu (&e/menu&7)."
        slot: 8                   # 0-8 hotbar, 9-35 main inventory
        open-on: [RIGHT_CLICK, LEFT_CLICK, INVENTORY_CLICK]
        droppable: false
        movable: false
    ```

    And a new top-level section:

    ```yaml
    crossplay:
      block-resync:
        enabled: true
        all-players: false
        window-ticks: 30
        interval-ticks: 5
    ```

    On start the log shows `Menu item on (NETHER_STAR in slot 8, ...)` and `Bedrock block resync on (Bedrock players,
    ...)`; the resync only reaches Bedrock players when the log also shows `Floodgate detected`.

## 2026-10-25

- **Invincible gates refuse ignition** — hotfix, knk-plugin `main` `ee35fb1`, merged `--no-ff` from `claude/adoring-wright-ejn8f7` on 2026-10-25 (developer decision 2026-10-25; not in Linear,
  free issue limit). Not live-tested yet. Before, a flame arrow, fire charge, flint and steel or Fire Aspect hit on an effectively-invincible gate (door
  flag or structure `IsInvincibleOverride`) started a burn whose damage no-op'd while its fire and smoke showed for the whole
  duration. Now `GateDoorHitService.handleIgnite` fires no `GateDoorIgniteEvent` for such a gate, and `GateFireSystem` puts out a
  burning gate that becomes invincible (a siege override mid-burn). Direct hits are unchanged (event fires, `HealthSystem` no-ops).
- **Invite-only onboarding: the Cloudflare step in every flow, no dead end from `/auth/register` or the login page,
  claim codes recognised in link-code fields** — knk-web-api `master` `fa28f7ea` and knk-web-app `main` `0d612702`, merged `--no-ff` from `claude/invite-only-register-page`
  (2026-10-25; comment on KNG-218, no issue of its own — free issue limit; found on the alpha with the first two
  testers). New anonymous `GET api/Auth/onboarding-info` (`registrationMode`, `accessGate`, `publicBaseUrl`; to add to
  the Cloudflare bypass). With the Access sync on: the sign-up form's done step lists Cloudflare's email + 6-digit code
  step and its button is a **full page load** (the in-app navigation skipped Cloudflare and every call then failed
  with "Network error"); `/invite`, `/join`, `/link` and the login page show the journey with that step; a missing
  Cloudflare session is recognised (health probe, opaque redirect) and answered with one banner, "Sign in with
  Cloudflare"; the invitation, welcome, finish-linking and password-reset mails carry the step (`{{#accessGate}}` blocks).
  With the sync off nothing about Cloudflare shows. Under `Mode=Invite` the register page opens on an invitation step (invitation code → `/join`, the
  server's `XXXX-XXXX` code → `/link?code=`, the link-code form behind "Already playing and got a code from
  `/account link`?"), the login page's **Create an account** continues the invite flow (`/invite` with the kept personal
  invitation, `/link` with a verified claim code, else `/join`), the invite and join forms' **Log in** returns to them, a
  claim code typed with its dash into a link-code field is routed to the claim flow (look-alikes folded on
  `/account/link`), and every claim refusal says the code stays valid for 15 minutes. Deployed to the alpha the same day (API `alpha-fa28f7ea`, web `alpha-0d612702`); waiting for the tester's check.
- **Menu startup validation keeps retrying while the API is down** — knk-plugin `main` `ad5786c`, merged `--no-ff` from
  `claude/menu-validation-retry` on 2026-10-25 (not in Linear, free issue limit). The 2026-10-24 retry only re-listed the templates; on the dev server the list came back
  while every per-key fetch still failed (the connectivity monitor still reported the API down), and the pass ended with
  nothing validated. Now a template that can't be fetched keeps the pass retrying (10 s, 20 s, 40 s, then every minute) until
  every listed menu is validated or blocked, and the API-recovery event (KNG-115) starts a pass at once. Not live-tested yet (the merge of the siege follow-ups before it was).

## 2026-10-24

- **Siege playtest follow-ups (2026-10-24)** — merged `--no-ff` from `claude/dreamy-fermi-4h2ldl`: knk-plugin `main` `75d619b`,
  knk-web-api `master` `1aba1ee` (migration `AddSiegeSkipSeconds`), knk-web-app `main` `4a9537e`, knk-workspace `main`; not in
  Linear (free issue limit). Live run 1 by the developer the same day: every section works except the menu validation retry
  with the API down at plugin start (continued on knk-plugin branch `claude/menu-validation-retry`). Five changes from the test round:
  (1) a melee hit on a gate door with a **Fire Aspect** weapon has a chance per level (`gates.fire-aspect.ignite-chance-per-level`,
  15 % × level) of setting the block alight like a flaming arrow; (2) the new **Cleaving** custom enchantment (I–IV): gate hits
  ×1.25/×1.5/×1.75/×2, and a right-click on a door block is a charged strike of 5/6/7/8 such hits (netherite sword: 50/72/98/128 of a
  500 HP gate) with wood-break sounds and splinters, then a 60/50/40/30 s per-player cooldown (`gates.cleaving` in `config.yml`;
  the API's ability catalogue and permanent enchant books know it too); (3) the **spawn picker opens at the team split** in the hub
  (no picker at match start; the start teleports everyone to their choice; the Information menu's "Change spawnpoint" shows from the
  hub on); (4) the **spawn menu shrinks** to its options, and `MenuTemplateSeed.RepairSiegeLayoutAsync` fixes the growth, minimum
  height and spawn-button phases of siege menus seeded before these layout changes (seeds are create-only, so an existing database
  kept the old 5/6-row static menus); (5) **`/siege skip` seconds are settings**: `PlayerSkipMatchmakingSeconds` (60) and
  `AdminSkipMatchmakingSeconds` (31) on the global siege configuration, web app → Siege settings → "Skipping matchmaking"
  (migration `AddSiegeSkipSeconds`; the plugin floors both at one second before voting closes).
  Two defects found in the developer's second round the same day and fixed on the branch: (a) with the API down when the
  plugin started, every inventory menu stayed unavailable until a restart (the startup validation lists the templates once)
  - the list is now retried (10 s, 20 s, 40 s, then every minute), a menu the validation never saw is validated on its first
  open, and a siege menu that falls back to chat logs why - **the retry did not help on the dev server** (the per-key fetches
  still fail while the connectivity monitor reports the API down and the pass then ends without another retry; see the
  `claude/menu-validation-retry` branch); (b) a member waiting in the **server hub** was never moved to the
  scenario hub or their spawnpoint: the hub is a domain with AllowExit off and the siege used a plain teleport, which the
  domain-access rule refuses - siege teleports now use the same scoped border-crossing transfer as the hub's portal and
  outage actions, and a refused siege teleport is logged instead of ignored.

- **Domain names: whitespace and newlines trimmed** (not in Linear, free issue limit; knk-web-api `master` `09cf7e4` + `ac0f160`,
  knk-web-app `main` `83609f7`, knk-plugin `main` `1593e70`; merged directly, no PR; not live-tested). The dev database held
  districts named `Residential District\n`: the form wizard's String field is a textarea, so Enter added a newline the API stored as is,
  and the action bar in game showed `You are now entering Residential District []`. `Domain.Name` now trims in its setter, and
  Town, District, Structure, GateStructure and `POST`/`PUT api/Domains` trim `Name` and `Description` at both ends in one place
  (`DomainNameRules`) and refuse a name that is empty after trimming (400). The plugin strips names defensively as well. **Deploy:**
  migration `TrimDomainNames` strips the whitespace from the existing `domains.Name` rows (data only, nothing to undo). The web app
  drops a line break at either end of any String field on submit (plain spaces stay: a chat prefix means them).
- **Form wizard: step completion conditions run** ([KNG-186](https://linear.app/kngpandi/issue/KNG-186); knk-web-api `master` `a38c8ee`,
  knk-web-app `main` `00e4af6`, merged directly, no PR; smoke-tested by the developer, [guide](guides/form-validation-result-log-smoke-test.md)).
  A step's completion condition ("Allow entry must be ticked before you continue") now stops Next while it fails. The API sent every
  condition and field validation as inactive before, so none ever ran. `StepCondition` and `FieldValidation` have a real `IsActive`
  (migration `FormConditionAndValidationIsActive`, default on), kept by save, clone and export/import; the form configuration's own
  never-set flag is gone. The builder can't author step conditions yet ([KNG-274](https://linear.app/kngpandi/issue/KNG-274)).
- **Form wizard: validation rules remember their last run** ([KNG-269](https://linear.app/kngpandi/issue/KNG-269); same merges).
  The API keeps the most recent run of each API-backed rule per entity (or per draft) and answers from it while the rule and the
  inputs it reads are unchanged, so re-opening an entity no longer re-runs every region check against the game server. Region
  rules expire after 24 h (`ValidationResultLog:ExternalStateTtlHours`), a redrawn region drops its rows, a check the plugin
  couldn't complete is never remembered, and the log never blocks a form if it can't be read. A step's rules go in one
  `validate-batch` request; a reused result shows "checked … ago" with a **Re-check** that runs the rule for real.
- **Invite-only sign-up, email engine, admission gate and web-first linking — merged, off by default**
  ([KNG-205](https://linear.app/kngpandi/issue/KNG-205) with KNG-206, KNG-207, KNG-208, KNG-211 (API half), KNG-212,
  KNG-214, KNG-216, KNG-218; knk-web-api `master` `4aeb794`, knk-web-app `main` `b7c0e88`, knk-plugin `main`
  `d56e41da`, merged directly, no PR; smoke-tested by the developer on dev 2026-10-23/24, every section of the
  [invitations smoke test](guides/invitations-smoke-test.md) passed or accepted except § 7, which needs the alpha's
  Cloudflare). The seven chain links below are now on the trunks. Nothing changes until the switch-over
  ([alpha go-live § 11.1](guides/alpha-go-live.md)): `Security:Registration:Mode` stays `LinkCode`, the plugin's
  `admission.mode` stays `whitelist`, `CloudflareAccess:SyncEnabled` stays false. **Deploy:** five migrations
  (`LinkCodePurpose`, `AddEmailOutbox`, `AddInvitations`, `SeedInvitationStaffNode`, `SeedAlphaTesterGroup`); outside
  Development the API refuses to start with the Log transport unless `Email__AllowLogTransport=true` (until the relay);
  the plugin's `config.yml` needs `web.public-url`, the `admission:` section (missing = whitelist) and the new
  `messages.link-code-generated` text, which an existing file keeps old. Two defects found on dev and fixed: a claim
  code reused from the database was sent without a UTC marker and the plugin fell back to its offline store (api
  `d78dc75`); the first join after a web-first or `/link` link got "Welcome back" and every discovery message at once
  instead of the first-join welcome, kits and quiet minutes (plugin `7bea0793`, which also stops a crash in the join
  telemetry for an operator without an account).
- **Invitations chain, link 7: rollout preparation (I3) — the chain is complete**
  ([KNG-218](https://linear.app/kngpandi/issue/KNG-218), parent [KNG-205](https://linear.app/kngpandi/issue/KNG-205);
  branch `claude/player-signup-invitation-flow-f4v7ul`: knk-web-api `8f489b9`). A data migration seeds the **Alpha
  Tester** group (weight 1, under Default, no extra permissions) that invitations grant by default; it leaves an
  existing group of that name alone. New: the [invitations smoke test](guides/invitations-smoke-test.md) (every check
  of the email engine, invitations, the admission gate, the Access sync, the kill switches and the alpha switch-over)
  and the living [account identity and admission](architecture/account-identity-and-admission.md) architecture doc.
  The alpha go-live guide, the closed-alpha runbook, the production installation guide and the player account guide
  describe the invite-only state after the switch-over, with the five switch-over steps and the kill switches
  ([alpha go-live § 11.1](guides/alpha-go-live.md)). Merged 2026-10-24 (entry above).
- **Invitations chain, link 6: Cloudflare Access sync and the sign-up bypass (A1)**
  ([KNG-216](https://linear.app/kngpandi/issue/KNG-216); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `641f9c1`, knk-web-app `eeea86f`). With `CloudflareAccess__SyncEnabled=true`, the API keeps the
  Cloudflare Zero Trust email list `knk-api-testers` in sync: a new personal invite's address is added within seconds,
  a revoke, an unused expiry, a deactivation, a deletion or a merge removes it, and a sign-up with a shared code adds
  the new address during registration. Calls go through a `cfproxy` forward proxy that only allows
  `api.cloudflare.com`. `/admin/invitations` shows "Access sync: last OK 12:04 · 0 pending", red with the error, and
  the sign-up page tells new players that Cloudflare emails them a one-time PIN next. The NAS and dashboard steps
  (proxy, list, policy, token, bypass application for the sign-up pages, 30-day session) are in alpha go-live § 6.1.
  Off by default, so deploying changes nothing.
- **Invitations chain, link 5: admission gate on the game server (I2, plugin)**
  ([KNG-214](https://linear.app/kngpandi/issue/KNG-214); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-plugin `90b01850`, on the KNG-182 branch). With `admission.mode: invite` in the plugin's `config.yml`, the game
  server asks the API about every connecting player right after Mojang sign-in: admitted accounts and operators get in,
  a new player is turned away with the claim code and the `/link` address on the disconnect screen, a deactivated
  account is refused. If the API doesn't answer within 3 seconds, players the server already knows still get in and
  strangers are asked to try again. A refused player no longer gets an account created. After a link the player sees
  "Your Minecraft account is now linked to the web account st\*\*\*@example.com. Not you? Tell staff right away." in
  game. The default stays `admission.mode: whitelist`, so deploying the plugin changes nothing until the switch-over.
 
- **Invitations chain, link 4: admission gate (server side), claim codes and Minecraft linking (I2)**
  ([KNG-214](https://linear.app/kngpandi/issue/KNG-214); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `4d1fe00` + `44c5f63`, knk-web-app `a3f00fd` + `60ec323`). The API answers the game server's new
  pre-login question `GET api/Admission/{uuid}` (plugin key): with `Security:Registration:Mode=Invite` a player without
  an admitted account gets a claim code `XXXX-XXXX` for the disconnect screen (15 minutes, one per player), a
  deactivated one is refused; in every other mode everyone is admitted, so nothing changes until the switch. `/link`
  (open without an account) checks that code; a logged-in player links straight away, a new player signs up with an
  invitation and is linked in the same step. `/account/link` is the new onboarding page after an invitation sign-up
  and takes both claim codes and `/account link` codes; a banner reminds unlinked players. Linking a web account to
  Minecraft gives the starting balance, a "linked" mail and an in-game notice with the masked address. Staff get
  **Admit** and **Detach web login** on the player profile. An unlinked invited account gets one reminder mail after
  two days. The landing page shows the new join steps. The game server's side follows in link 5.

- **Invitations chain, link 3: invitations and invite-based registration (I1)**
  ([KNG-212](https://linear.app/kngpandi/issue/KNG-212); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `77042fd` + `8ca8507`, knk-web-app `dfa5cdd` + `18f3c9f`). Staff with the new node `knk.admin.invites`
  (granted to Admin by a seed migration) get **Invitations** (`/admin/invitations`): personal invites by email, in
  bulk, emailed or as copy-links (single use, 7 days by default, at most 30), and shared codes `KNK-XXXXX-XXXXX` with
  a label and a use cap (5 by default, at most 50); links and codes are shown once and only their SHA-256 is stored;
  resend (rotates the link, 3 a day), rotate, pause/resume, revoke, and a redemptions drawer. `/invite/:token` (the
  address shown locked and verified, the token removed from the address bar) and `/join?code=` sign up with an
  invitation once `Security:Registration:Mode=Invite` is set, creating a web account (`web-…` name, no starting
  balance until Minecraft is linked) and taking the use in one conditional UPDATE. The default stays `LinkCode`:
  today's `/account link` registration is unchanged and invite fields are refused. Migration `AddInvitations`
  grandfathers every active account as admitted; accounts the plugin creates are admitted until the mode is
  `Invite`. Account page: "Email verified" badge.

- **Invitations chain, link 2: the email engine (E1)** ([KNG-206](https://linear.app/kngpandi/issue/KNG-206); branch
  `claude/player-signup-invitation-flow-f4v7ul`: knk-web-api `0d7ec4a` + `a8b42ca`, knk-web-app `aecd811`). Every mail
  now goes through a persistent `email_outbox` table, written in the same transaction as the change that causes it, and
  a background dispatcher that retries (1 min … 4 h, Failed after 6 attempts), drops reset mails whose link expired, and
  deletes the content once sent. MailKit replaces `System.Net.Mail`; HTML and text templates share one layout; a
  throttle caps mails per recipient (3 per kind, 6 in total per hour) and per day (300). Password reset, the
  email-change notice and the data-deletion mails use it, and a staff email change now notifies the old address too.
  Staff with `knk.admin.config` get **Mail** (`/admin/email`): the mail log with masked addresses, Retry and "Send test
  mail to me". New settings `Email:Transport`, `Email:AllowLogTransport`, `App:PublicBaseUrl` and others; outside
  Development the API refuses to start with the Log transport unless `Email:AllowLogTransport=true` (the alpha needs it
  until its relay works). [Email guide](guides/email.md).

- **Invitations chain, link 1: optional SMTP auth (E0 API half), link-code hygiene and the linking rules (L0)**
  ([KNG-211](https://linear.app/kngpandi/issue/KNG-211), [KNG-207](https://linear.app/kngpandi/issue/KNG-207),
  [KNG-208](https://linear.app/kngpandi/issue/KNG-208); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `110451f` + `bb4b9ee`, knk-web-app `2bf70ab`, knk-plugin `30b10e6e` on the KNG-182 branch). With
  `Email:SmtpUsername` empty the reset and privacy mails go out without SMTP credentials, for the alpha's mail relay
  (`110451f` is self-contained for a cherry-pick to `master`). `linkcodes` rows carry a `Purpose` (link, password
  reset, admission claim) instead of being told apart by length; link codes are drawn without modulo bias; an hourly
  job expires and, after 7 days, deletes finished codes; five wrong codes block an account for 15 minutes (429
  `TooManyAttempts`). Linking a web-only account to an existing Minecraft account now folds the web login **into
  the Minecraft account** (decision I7): it keeps its id, stats, groups and balances (the higher of each), the shell
  is soft-deleted and signed out, and the web app is logged into the merged account. 409 `AlreadyRegistered` /
  `AlreadyLinked` refusals. The plugin's `/account` usage no longer lists `create`, the dead merge flow is gone and the
  link-code message ends with "Never give this code to anyone; staff never ask for it."

## 2026-10-23

- **Gate doors: open-door scans that work as expected** ([KNG-268](https://linear.app/kngpandi/issue/KNG-268),
  [KNG-270](https://linear.app/kngpandi/issue/KNG-270), [KNG-271](https://linear.app/kngpandi/issue/KNG-271); knk-plugin
  `main` `6ad683f8`, knk-web-api `master` `a853d37`, knk-web-app `main` `1d79af0`, merged directly, no PR; live-tested
  by the developer).
  - **Pairing along the slide.** A sliding door with an open-door scan moves each block to the open block straight
    along its slide; blocks no longer change columns (that jammed door 17).
  - **Empty open-door anchor = the anchor.** For a door that opens inside its own box, leave the open-door anchor
    empty: the scan starts at the anchor. An open scan made from another point than the one it is read from (anchor
    moved, cleared or edited) is ignored with a console warning until you scan again.
  - **Scans that can't work are refused** with the reason: a region door without its captured region (the message
    names `/gatedoor capture <id> opened|closed`), an open scan on a flood-fill door, a door without an anchor. A failed
    scan shows its reason once, and scan lists show "N blocks scanned." instead of a card per block and a broken picker.
  - **Deploy.** Import **GateDoor seed v3** and make it the default: it explains the open-door anchor and when an
    open-door scan is needed ([admin guide](guides/admin/gate-structures-admin-guide.md)).

- **Gate doors: no more jamming on their own decoration, and a GateDoor dashboard** ([KNG-272](https://linear.app/kngpandi/issue/KNG-272),
  [KNG-273](https://linear.app/kngpandi/issue/KNG-273); knk-plugin `main` `c09e9483`, knk-web-api `master` `85c0a26`,
  knk-web-app `main` `0ed300c`, merged directly, no PR; live-tested by the developer).
  - **Decorated doors move.** A door whose blocks of different materials follow each other in the direction it moves
    (chains above a portcullis, a decorated top row) jammed on its own blocks: a fence rising into the cell a chain had
    just left found the chain there and called it an obstruction. The door now clears such a cell first. A block a
    player puts in the way still jams it.
  - **GateDoor dashboard.** The web app's dashboard and GateDoor pickers list doors across all gates, with the gate's
    name, through the new `POST api/GateDoors/search` (search on door or gate name, filters gate, type, state, active).
  - **Configuring a door like this.** A door that rises and loses its chains needs no open-state scan: motion distance
    plus *Clip to geometry bounds* removes the chains as they leave the door box
    ([admin guide](guides/admin/gate-structures-admin-guide.md)). The open-scan pitfalls found on the way are fixed in
    the entry above.

- **Domain sub-regions: one domain, several WorldGuard regions** ([KNG-253](https://linear.app/kngpandi/issue/KNG-253),
  phases KNG-254–KNG-259; knk-web-api `master` `779629e`, knk-plugin `main` `9dfd7aae`, knk-web-app `main` `bf0d142`, merged directly, no PR; smoke-tested by the developer). A town, district,
  structure or gate can have extra regions besides its main one, added in a new "Sub-regions" step of its form. Example:
  a garrison gate's round tower next to its house.
  - **Naming.** Each sub-region is drawn through its own world task and renamed `domain_<id>_sub_<n>` on save.
  - **Copy of the main region.** The game server keeps every sub-region a copy of the main region: priority, flags,
    owners, members, with the main region as parent. This runs every 5 minutes, on `/knk regions repair` and on the new
    `/knk regions sync`.
  - **One domain.** Walking between a domain's regions gives no enter or leave message and no access refusal, even
    with Allow exit off. A door location in the tower counts as inside the gate. Discovery and analytics count the
    domain once.
  - **Round selections.** `//sel cyl` (and ellipsoid, convex) now becomes a polygon along its block outline, for every
    region a world task draws. Before, it became the box around it.
  - **Removed sub-regions.** One no domain lists is orphaned within two syncs, and the daily cleanup deletes it after
    `regions.temp-retention.days` (14). `/knk regions temp [purge]` lists and purges orphans.
  - **Fixes on the way.**
    - `knk-creation-timestamp` and the new orphan mark are now read back after a restart. Temp regions used to read as
      "without a creation time" after one.
    - A gate's edit form lists its sub-regions.
  - **Deploy.** Run the migration `DomainSubRegions`, import the seeds (`DomainSubRegion`; Town, District and Structure
    v2; GateStructure v3; display seeds v2), and deploy API and plugin together
    ([admin guide](guides/admin/domain-subregions-admin-guide.md), [design](specs/domain-subregions/DESIGN.md)).
  - **Not yet.** Placement checks for a drawn sub-region ([KNG-261](https://linear.app/kngpandi/issue/KNG-261)), and
    navigation knowing sub-regions ([KNG-260](https://linear.app/kngpandi/issue/KNG-260)).

- **Enchantments from the server scan, vanilla and custom in one picker** ([KNG-250](https://linear.app/kngpandi/issue/KNG-250);
  knk-web-api `master` `a1f8838`, knk-web-app `main` `f9ee73c`, knk-plugin `main` `c7806b87`, merged directly, no PR;
  live-tested by the developer). The **Scan server** of the Minecraft catalogue now reads the server's enchantments too,
  plus knk-plugin's 12 custom enchantments as `knk:<id>`. Old rows in another notation (a custom `chaos` saved without
  namespace) merge into the scanned row; unknown rows nothing uses are deleted and used ones become Missing. Every
  enchantment gets an enchantment definition (existing ones are linked, never deleted), so the item blueprint and lootbox
  pickers offer every vanilla and custom enchantment. The enchantment picker in forms searches the database, shows
  vanilla and custom together with a Custom badge and an All / Vanilla / Custom filter, and never creates anything on a
  pick any more (fixes [KNG-243](https://linear.app/kngpandi/issue/KNG-243)). The catalogue page shows the enchantment
  counters and "Missing enchantments still used". The built-in enchantment list and the hybrid picker are gone. Run the
  migration `MinecraftEnchantmentCatalogFields`, deploy plugin and API together and scan
  ([admin guide](guides/admin/minecraft-catalogue-admin-guide.md), [plan §12](specs/minecraft-catalog/IMPLEMENTATION_PLAN.md)).

- **Non-op players can pick up a world lootbox inside a protected region** ([KNG-266](https://linear.app/kngpandi/issue/KNG-266);
  knk-plugin `main` `1fbcb046`, merged directly, no PR; smoke-tested by the developer). WorldGuard refused the click on
  a box in a spawn area inside a domain region to anyone who isn't a member, so only ops could pick boxes up there. The
  plugin now tells WorldGuard to allow clicks on lootbox entities only; every other entity in the region stays protected.

- **Item blueprint Category filter in the web app, child categories included** ([KNG-263](https://linear.app/kngpandi/issue/KNG-263);
  knk-web-app `main` `b83e376`, merged directly, no PR; checked by the developer). The
  item blueprint list and every item blueprint picker get a Category filter that lists the category tree; choosing
  "Weapons" also shows the blueprints in Swords and Bows. The API's item blueprint search already worked this way (since
  2026-09-26), and so does the in-game item catalogue's category button. The list also shows each blueprint's category.

- **Item blueprints are cached for their own configured time** ([KNG-262](https://linear.app/kngpandi/issue/KNG-262),
  item blueprints only; knk-plugin `main` `64f39d28`, merged directly, no PR; smoke-tested by the developer).
  The plugin now keeps item blueprints for `cache.entities.itemBlueprints.ttl-minutes` (20 minutes) instead of the
  global 60 s, so the catalogue, kits and `/knk ib give` call the API far less often. A blueprint edited in the web app
  reaches the game within 20 minutes, or at once after `/knk cache refresh`. The other entities still use the global TTL.

- **Menu paging: the right page number and a fast item catalogue** ([KNG-230](https://linear.app/kngpandi/issue/KNG-230),
  [KNG-231](https://linear.app/kngpandi/issue/KNG-231); knk-plugin `main` `fae0b3b2`,
  merged directly, no PR; smoke-tested by the developer). Pager arrows show the current page instead of "Page 1/N" in every paged menu. Changing
  page re-renders from the open menu instead of fetching its template again. While a page loads, its arrows turn into a
  clock "Loading page N…" (and the action bar says it after half a second); further clicks wait for it; a failed load
  puts the previous page back with a message. The item catalogue keeps built pages for a minute, shared by all players,
  and loads the next page in the background, so paging forward is usually instant.

## 2026-10-22

- **Minecraft catalogue from the server itself** ([KNG-200](https://linear.app/kngpandi/issue/KNG-200); knk-web-api
  `master` `4f34f58`, knk-web-app `main` `0622a87`, knk-plugin `main` `69c93885`, merged directly, no PR). **Scan server** on
  the new admin page `/admin/minecraft-catalog` has knk-plugin read the server's registry (a headless WorldTask). The API
  stores every item and block with its name, item/block flags, default block state and a picture from a versioned public
  asset source (PrismarineJS, then InventivetalentDev), keeping ids, merging rows that only differ in notation, deleting
  unreferenced rows the server doesn't know and marking referenced ones Missing. Material pickers search this database
  only: items by default (`categoryFilter` BLOCK/ANY/BANNER), with name, key and icon; no more duplicate rows or poor
  search. The item blueprint overview shows the item's picture. The page also lists missing icons (with your own URL as
  override), an audit with **Merge into…**, and a backfill. The built-in material list (1.21.4, half of its icon URLs
  broken) and the hybrid picker are gone; a new database stays empty until its first scan. Run the two migrations as the
  [admin guide](guides/admin/minecraft-catalogue-admin-guide.md) describes. Live-tested by the developer on Minecraft 26.3
  (1812 entries). Follow-ups: [KNG-250](https://linear.app/kngpandi/issue/KNG-250) (enchantments),
  [KNG-251](https://linear.app/kngpandi/issue/KNG-251) (block-state picker). In passing: the object dashboard and form
  pickers now find their column definitions (the lookup was case-sensitive).

- **Performance metrics for the closed alpha** ([KNG-232](https://linear.app/kngpandi/issue/KNG-232); knk-plugin
  `main` `390d88a4`, knk-web-api `master` `3658cf2`, merged directly, no PR; unit-tested, not live-tested, everything off by default). The plugin can serve a Prometheus `/metrics` (`metrics.enabled`, off by default, bearer token) with TPS, tick
  time, players, chunks and entities per world, JVM heap/off-heap/GC, process CPU/RSS, the container's memory working set
  against its limit, API-call latency and the cost of 16 recurring tasks. The API's `/metrics` is now real
  (`Telemetry__Prometheus__Enabled` + a bearer token; the earlier note that it existed was wrong) and adds .NET runtime,
  HTTP client, process/cgroup and database-command metrics. Read the
  [performance metrics and capacity guide](guides/performance-metrics-and-capacity.md) for the collection stack, load
  steps, acceptance thresholds and the NAS-vs-cloud decision.

- **Default forms and display pages for the rest of the game content** ([KNG-139](https://linear.app/kngpandi/issue/KNG-139);
  knk-web-api `master` `3eac5ec`, knk-web-app `main` `0736ef3`, merged directly, no PR). 30 more bundled form seeds
  (Town, District, Street, Structure, Location; User, permission groups and grants, banners, Clan; grades, tags,
  categories, enchantments, item blueprints; kits and lootboxes), reworked from the dev forms with a description on
  every step and field and their known bugs fixed, and 7 display seeds (Structure, GateStructure with a warp and
  navigation section, User, ItemBlueprint, EnchantmentDefinition, MinecraftMaterialRef, ItemBlueprintDefaultEnchantment).
  Display configurations get **Export JSON** and **Import / Seeds** like form configurations (`knk-displayconfig/1`).
  Import both from the configuration lists and make them the default. Smoke-tested by the developer on 2026-10-22:
  every step passed or was accepted. Follow-ups: [KNG-243](https://linear.app/kngpandi/issue/KNG-243),
  [KNG-244](https://linear.app/kngpandi/issue/KNG-244), [KNG-246](https://linear.app/kngpandi/issue/KNG-246),
  [KNG-247](https://linear.app/kngpandi/issue/KNG-247), [KNG-248](https://linear.app/kngpandi/issue/KNG-248);
  details in the [seed review notes](reports/2026-10-19-kng-139-seed-review-notes.md).
- **Form saves keep what they should** ([KNG-195](https://linear.app/kngpandi/issue/KNG-195); same merges). A
  Structure's spawn point captured in game is saved; editing a player no longer unfreezes them or resets their email
  verification, account origin, gender, active state or gate pass-through; picking the empty option of an optional
  list no longer makes the save fail; a material or vanilla enchantment that isn't in the database yet is saved from
  the picker; saving a custom enchantment keeps its ability.

- **Gates can be warp destinations, and the gate form has the /navigate and road settings**
  ([KNG-229](https://linear.app/kngpandi/issue/KNG-229); knk-web-api `master` `be9f4e1`, merged directly, no PR). The
  bundled form seed "GateStructure - Default (seed v2)" adds "Entry rule on roads" and "Navigate to", plus a "Warp
  destination" step (on/off, price in gems, minimum title, minimum premium tier, discovered gates only), as on the
  Structure form. The API now stores a gate's warp settings; before, `GateStructureService` ignored them, although
  `/warp` already listed gates. A save without the warp step (the plugin, the v1 form) keeps them. Import the seed from
  Import / Seeds and make it the default; it imports next to v1. Smoke-tested by the developer on 2026-10-22: every step
  passed or was accepted.

## 2026-10-21

- **The plugin runs on Minecraft 26.3** ([KNG-182](https://linear.app/kngpandi/issue/KNG-182); knk-plugin `main`
  `857d4b1e`, merged directly, no PR). Paper 26.3 build 205 on Java 25 (Gradle 8.14 itself still runs on Java 21),
  `api-version` 26.3, WorldEdit 7.4.6 and WorldGuard 7.0.20 (the dev server runs FastAsyncWorldEdit 2.16.1). The world
  loader also finds worlds in Paper 26.x's `<level>/dimensions/minecraft/<name>/`, where Paper moves the hub and the
  other worlds on their first load, so the second start no longer reports the hub missing. Offline `/inventory` and
  `/enderchest` read `<world>/players/data`. Paper converts the world storage on the first 26.3 start; it can't be
  undone. Live-tested by the developer on `DEV_SERVER_26.3` on 2026-10-18 and 2026-10-20
  ([smoke test](guides/minecraft-26.3-upgrade-smoke-test.md)): every step passed or was accepted except the hub
  tiles of `/menu`, which were hidden because the server had started while the API was down
  ([KNG-201](https://linear.app/kngpandi/issue/KNG-201), not a 26.3 problem). The same startup-only shape was found
  in siege, gates and regions ([KNG-202](https://linear.app/kngpandi/issue/KNG-202),
  [KNG-203](https://linear.app/kngpandi/issue/KNG-203), [KNG-204](https://linear.app/kngpandi/issue/KNG-204)).
- **`/hub` takes any player to the hub** ([KNG-188](https://linear.app/kngpandi/issue/KNG-188); reached knk-plugin
  `main` with KNG-182 at `857d4b1e`, through the KNG-182 branch). Its three live checks are still to run. `/hub` goes to the hub spawn selected on the Game
  Settings page through the regular teleport engine: warmup, movement and combat cancel, the safe-spot check, and the
  siege, freeze and outage guards. It has its own cooldown, and the groups' spawn settings set its cooldown and price.
  Without a usable hub it says "The hub isn't available right now." and moves nobody. Staff can send a player with
  `/hub <player> [-s]`. `/hub return` is unchanged ([hub DESIGN §16.8](specs/hub/DESIGN.md)).

## 2026-10-19

- **Drawbridges swing as one straight plank, including arched doors**
  ([KNG-193](https://linear.app/kngpandi/issue/KNG-193); knk-plugin `main` `79be4882`, knk-web-api `master` `2d71155`,
  merged directly, no PR). A `ROTATION` door with a horizontal hinge was drawn mid-swing as a cloud of individually
  rotated blocks with a rigid fit, a residual and a snap on top, so its parts moved at different speeds. It is now
  played back as whole-door keyframes precomputed at load (`DrawbridgeKeyframes`): a digital-line plank from the hinge
  to the tip, one keyframe per tip-cell change, the closed scan verbatim at one end and the open scan verbatim (or a
  deck `MotionDistanceBlocks` long, counted in blocks) at the other; the door's own shape is the mask, so an arched
  door scanned in REGION mode with a material whitelist keeps its arch. The old path stays behind
  `gates.rotation.keyframes-enabled` until [KNG-194](https://linear.app/kngpandi/issue/KNG-194) removes it. The GateDoor
  form seed v2 adds the deck length for rotating doors and a "Door materials" field for region and flood-fill scans.
  Live-tested by the developer on gate door 14 (2026-10-19); the cardinal, arched, switch and fall-back checks of
  [guides/gate-smoke-test.md §3](guides/gate-smoke-test.md) were accepted without a run.

## 2026-10-18

- **Many-to-many form steps without a carrier field keep their relationships**
  ([KNG-190](https://linear.app/kngpandi/issue/KNG-190); knk-web-app `main` `e30c815`, merged directly, no PR).
  The wizard only kept a many-to-many step's relationships when its FormConfiguration also had a List field named
  after the step's related property, which the builder neither adds nor requires, so every add, remove and re-order
  on such a step was dropped. The wizard now adds that field when it loads a form. The seeded forms already had it.
  Also: the three web-app test suites that failed on `main` pass again (`test:ci` 154/154), and a duplicate, unused
  `useEnrichedFormContext` is gone. Ported from the stale `claude/bold-goodall-7eg00l` branch; live-tested by the
  developer (2026-10-18).

- **Fields asked in more than one form step share one value**
  ([KNG-120](https://linear.app/kngpandi/issue/KNG-120); knk-web-app `main` `0027677`, merged directly, no PR).
  A FormConfiguration can ask for the same property in two steps (the default District form asks for the Location
  twice). Filling the first copy left the second empty, and on submit the empty copy overwrote the value with null.
  Now changing either copy updates the other, in both directions and for every way a value changes (typing, value
  projections, child-form results, ItemScan); a resumed draft fills empty copies; an empty copy never overwrites a
  filled one on submit. Live-tested by the developer on the District form (2026-10-18).

- **The items catalogue shows each item with its default enchantments**
  ([KNG-175](https://linear.app/kngpandi/issue/KNG-175); knk-plugin `main` `147806d8`, merged directly, no PR).
  The `/menu` item catalogue built its icons from the blueprint alone, so the vanilla enchantments and custom
  enchantment lines a kit or `/knk itemblueprints give` adds were missing. It now builds them the same way
  (`assembleDefaults`), from the enchantments the blueprint already carries. Unit-tested; merged at the
  developer's request, no in-game result recorded.

- **Re-running a domain's region step replaces its region instead of leaving an orphan**
  ([KNG-103](https://linear.app/kngpandi/issue/KNG-103); knk-plugin `main` `e574f45` ([#12](https://github.com/PandiO/knk-plugin/pull/12)),
  knk-web-api `master` `73c70d5` ([#10](https://github.com/PandiO/knk-web-api/pull/10))). [Architecture](architecture/managed-worldguard-regions.md) §7.
  - Drawing a new region for an existing Town, District, Structure or Gate and saving it now gives the new region the
    domain's `domain_<id>` name. The old `domain_<id>` is redefined in place, keeping its parent, priority, owners,
    members and flags, and child regions stay linked. Before, the rename was refused, so the domain stayed on
    `tempregion_worldtask_<n>` and the old region stayed behind.
  - The API names the domain's previous region; the plugin only removes the domain's own `domain_<id>` or a temp
    region, and puts everything back if a step fails.
  - **`/knk regions temp`** reports leftover temp regions and `domain_<id>` regions no domain uses;
    **`/knk regions temp purge [hours]`** deletes unused temp regions older than `hours` (default 24).
  - Domains the old bug already left on a temp name are fixed once by hand (§7).
  - Live-tested by the developer (2026-10-18).

- **Commands show only what a player can use, and permission checks no longer flood the API**
  ([KNG-107](https://linear.app/kngpandi/issue/KNG-107); knk-plugin `main` `3ca5b3f`, knk-web-api `master`
  `ac3c869`; merged directly, no PR). [Architecture](architecture/plugin-permission-checks.md).
  - **`/knk help`** lists the `/knk` subcommands and the plugin's other commands the player may use, 8 lines a page
    with clickable page links (`/knk help <page>`); a command they can't use reads as unknown.
  - **Tab completion** offers only usable subcommands, actions, flags and player names; gate commands only the
    gates the player controls.
  - **"No permission" instead of the usage** for `/knk` subcommands and standalone commands the player holds no
    node for; usage lines name only the action typed or the held ones.
  - **The "/" list** leaves out commands the player can't run, every `plugin:command` form, and other plugins'
    commands they can't use (config `command-visibility.*`, `always-show` for exceptions). Ops see everything.
  - **One permission load per player:** checks resolve from the player's effective set, loaded at login and
    refreshed every 30 s, instead of one API request per node (a join sent 116 and `/knk help` 244, about 10 s).
    The API's effective set now carries `sourceRank`; the plugin also works with an API without it. A change made
    with `/knk user` applies at once.
  - Live-tested by the developer (smoke test and two retests, 2026-10-18).

## 2026-10-17

- **Gate doors refuse a Reference point 2 that isn't straight above the anchor**
  ([KNG-132](https://linear.app/kngpandi/issue/KNG-132); knk-web-app `main` `7c00508`, knk-plugin `main`
  `82455cf`). Both reference points are measured from the anchor: point 1 along the bottom edge (width), point 2
  straight up (height). A point 2 above point 1 gave a slanted height of 2, the block
  scan stored the wrong blocks and the door jammed. The GateDoor form now refuses such a point and says where it
  should be, the plugin's block scan refuses it too, and loading such a door logs a warning. The field descriptions
  come from the GateDoor form seed (KNG-139). Unit-tested; smoke-tested in game and merged by the developer.
- **Form wizard: child forms save what they create, sessions remember it, and ready-made gate and siege forms**
  ([KNG-133](https://linear.app/kngpandi/issue/KNG-133)…[KNG-139](https://linear.app/kngpandi/issue/KNG-139),
  [KNG-162](https://linear.app/kngpandi/issue/KNG-162), [KNG-164](https://linear.app/kngpandi/issue/KNG-164) and the
  smoke-test follow-ups KNG-166…169, KNG-172…174; branch `claude/wonderful-darwin-u39k1o`, which replaced
  `claude/jolly-archimedes-urhio9`: knk-web-api `master` `2929972`, knk-web-app `main` `bbd0dae`, knk-plugin `main` `5643ae6a`; merged
  directly, no PRs). **Needs two additive migrations** before the new web app runs against a database:
  `AddFormFieldSelectionLimits`, `AddFormSubmissionProgressCreatedEntities` (the dev DB has them).
  - **Child forms:** a "Create New" entity on a List field is saved when its form completes, and a form refuses to
    submit an entity that was never saved. **Edit instance** opens with the values the form holds. Editing loads
    List relationships (`districtIds`).
  - **Required lists and limits:** a required List refuses an empty list; minimum/maximum selections are stored and
    enforced.
  - **Step names** in the progress bar and as the title in edit mode, Boolean descriptions. Many steps scroll
    sideways; on a phone "Step 3 of 9 · Name" opens a list of all steps (KNG-168).
  - **Session entities:** what a form created is pinned in every picker of that type ("Created in this form", New),
    also after resuming a draft. **Cancel form** and deleting a draft ask whether to keep (default) or delete what
    child forms saved; in-use entities are skipped with the reason.
  - **Export / import:** Export JSON per form configuration, Import / Seeds with a dry run; never overwrites. Ten
    bundled seed forms: GateStructure (no house number), GateDoor and the siege set. On the dev DB the seeds are the
    defaults.
  - **Pickers** show the columns that tell rows apart (District: Town; Street: Districts, Towns; gates and structures:
    street + number, District, Town); saved columns map to them, and "Use built-in columns" clears saved ones
    (KNG-166).
  - **Refusals explain themselves:** a refused delete names what still uses the item ("This street can't be
    deleted: it is still used by 1 structure."), confirmations are in-app modals, no browser boxes (KNG-169).
    A form configuration that was opened can be deleted; its drafts go with it (KNG-172).
  - **Minecraft validation:** warning is warning and block is block; failures name what the region or location must
    be inside, a missing parent region or a wrong world get their own sentence (KNG-173). One open world task at a
    time, readable task header (KNG-174). A typed Location name survives a capture (KNG-167).
  - **Fixed along the way (live test):** a failed region rule no longer answers 500 (object cycle); a form rule's
    changed dependency path is saved; the rule builder finds a parent form's fields again (it showed "Property
    'Town' not found on entity 'SiegeObjective'").
  - **Live:** smoke-tested by the developer 2026-10-12 and 2026-10-16/17, all sections passed or accepted
    ([chain report](reports/2026-10-11-form-wizard-chain.md),
    [follow-ups and live test](reports/2026-10-12-form-wizard-chain-smoke-followups.md)). Follow-ups in Linear:
    KNG-183 (M2M direct pick), KNG-184 (clickable steps), KNG-185 (refusal details), KNG-186 (`isActive` never
    set), KNG-187 (web app: wrong world / missing region), KNG-188 (`/hub`).

- **The hub: a protected arrival world, API-outage actions and portals** ([KNG-109](https://linear.app/kngpandi/issue/KNG-109),
  KNG-113, KNG-114, KNG-116, KNG-117; knk-web-api `547d2b2` [#8](https://github.com/PandiO/knk-web-api/pull/8), knk-web-app
  `e86af25` [#6](https://github.com/PandiO/knk-web-app/pull/6), knk-plugin `9f31db6` [#11](https://github.com/PandiO/knk-plugin/pull/11)).
  - **Worlds:** KnK loads the worlds listed in `worlds.load` (e.g. a void `hub`). Gates animate only in their own world.
  - **Admission:** a Town, District or Structure can be selected as the hub on the Game Settings page. Joining players
    then arrive at its spot before they appear, also while the API is down. A missing hub refuses non-ops.
  - **Hub rules:** no combat or building, storage and item frames closed, doors and NPCs open (past WorldGuard), and the
    Peaceful heal/feed preset.
  - **API outage:** per hub or per group, Do nothing, Send to the hub, Kick or Send to world spawn, after a delay counted
    from the first failed health check. A Siege match is aborted.
  - **After the outage:** players get a clickable return to their spot, with fallbacks for an unsafe spot.
  - **Portals:** WorldGuard regions that take players into the game. Leaving otherwise says "use the portal".
  - **Also changed:** group overrides rank by hierarchy, then weight. Deleting a Location never deletes its domain.
  - **Live:** smoke-tested by the developer in three runs ([report](reports/2026-10-17-hub-smoke-test.md)). The remaining
    checks and Siege were accepted without a run.

Delegated batch of 2026-10-15 (`claude/linear-issues-delegation-k1trkm`), merged with trunk: knk-web-api `181bf3f`
([#11](https://github.com/PandiO/knk-web-api/pull/11)), knk-web-app `2fcbeae` ([#7](https://github.com/PandiO/knk-web-app/pull/7)),
knk-plugin `ad3bc48` ([#14](https://github.com/PandiO/knk-plugin/pull/14)). Developer live check 2026-10-17: KNG-171, KNG-121 (T1-T3),
KNG-125 and KNG-126 passed; KNG-121 T4, KNG-124 and KNG-118 accepted without a run.

- **Commands answer at once during an API outage** ([KNG-171](https://linear.app/kngpandi/issue/KNG-171); knk-plugin
  `77235931`). While `/knk health` shows DOWN, reads skip the API instead of trying three times: `/msg`, `/tpa` and
  `/knk help` no longer wait about a second. Permission checks answer from memory or the offline store with the same
  rules (a last-known deny stays a deny, an expired answer counts as denied). Writes still go to the API. Switch:
  `api.connectivity.skip-api-while-down` (on). See [architecture](architecture/api-connectivity.md) and the
  [outage smoke test](guides/api-outage-smoke-test.md).
- **Walk paths keep out of a region the player could not leave again** ([KNG-121](https://linear.app/kngpandi/issue/KNG-121);
  knk-plugin `8f28d65f`). The "no way out" rule of the road router now applies to walk legs too (direct mode, the
  walk to the road, the last leg): a region that allows entry but not exit is avoided unless the destination is in it.
- **Shut in close to a road: "No conventional path to the road found."** ([KNG-124](https://linear.app/kngpandi/issue/KNG-124);
  knk-plugin `e2955728`). A player within 8 blocks of the route but not on it gets a short check search; if they are
  boxed in, they get the message once. A player on the road sees no change.
- **Inventory menus: item blinker** ([KNG-125](https://linear.app/kngpandi/issue/KNG-125); knk-plugin `aaeb8e48`).
  New `BLINK` display mode: the item alternates with a yellow glass pane (same name and lore) every 10 ticks, its
  clicks keep working, and it stops on close. First user: the open group selector in the statistics visibility menu.
- **Staff note forms say why Reverse / Apply can't run yet** ([KNG-126](https://linear.app/kngpandi/issue/KNG-126);
  knk-web-app `7f5b9a8`). The transaction Reverse form and the Adjust balance card show a live "n / 10 characters"
  counter, and submitting with a short reason explains what is missing instead of doing nothing. Disabled buttons
  now look disabled.
- **Multiworld follow-ups** ([KNG-118](https://linear.app/kngpandi/issue/KNG-118), the items not already on the hub
  branch; knk-plugin `8ca2f1c9` `e9cc237b`, knk-web-api `d91a141` `3e666da` `faf9885`, knk-web-app `6c3d4bf`).
  Discoveries are kept per world (same region id in two worlds = two discoveries; spool file version 3, old files
  still read). The loaded-worlds report is kept per server (`game-settings.server-id`). A District's new inline
  Location, a world-task Location and a web capture without a world are refused instead of landing in a world named
  "world". Status of every row: [multiworld follow-ups](architecture/multiworld-follow-ups.md).

## 2026-10-11

- **Editing a domain's Location in its child form no longer blocks the domain form**
  ([KNG-130](https://linear.app/kngpandi/issue/KNG-130); knk-web-api `master` `917537a`,
  knk-web-app `main` `38854ba`). Renaming a Town's Location from the Town form made the Location boundary check fail
  ("outside the boundaries") and the Town form could not be submitted. The child form returned the Location's id as
  text, which the API could not read; the check never reached the region. Not caused by the multiworld work
  (KNG-111). The API now reads a text id, the web app keeps the id a number, and a Location value the check cannot
  read now says so instead of "outside the boundaries". Unit-tested; accepted and merged by the developer.
- **Recapturing a point of an existing gate door checks the gate's region again**
  ([KNG-131](https://linear.app/kngpandi/issue/KNG-131); knk-web-app `main` `38854ba`,
  knk-plugin `main` `1b3e06c2`). Capturing a Location in game for an existing GateDoor (e.g. its reference point)
  failed with "Location {coordinates} is outside {parentEntityName}'s boundaries" even inside the gate's region: the
  plugin got the gate's id instead of the gate, and looked for a region named "21". The web app now sends the saved
  gate. When the plugin can't find a region it now says so and follows the rule's blocking setting, and the
  coordinates and parent name are always filled in. Not caused by the multiworld work. Unit-tested; accepted and
  merged by the developer.
- **API background services log a database outage once** (KNG-115 live-test follow-up; knk-web-api `master`
  `f409271`). With MySQL stopped, the rank expiry sweep, the currency monitor and the location retention scheduler
  printed a full `MySqlException` stack trace on every iteration. They now log one short warning when the database
  becomes unreachable and one line when it is back. Other errors are still logged in full every time. See
  [architecture](architecture/api-connectivity.md#api-background-services-during-a-database-outage). Unit-tested;
  not yet checked against a stopped MySQL.
- **Dying resets combat and freezes** (knk-plugin `main` `c0ad2a9b`; trunk follow-up found in the
  [KNG-34 smoke test](guides/player-statistics-smoke-test.md), findings 6 and 7). After dying, a player can teleport
  again straight away: death clears their teleport combat tag (the killer stays tagged). A player frozen by the
  Freeze enchantment can move again after respawning, and HealthBoost's heal-over-time stops when the player dies.
  The other enchantment effects are potion effects, which death already clears. Unit-tested; not yet checked in game.
- **New players get the first-join kits** ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), plugin half; knk-plugin
  `main` `0ee516aa`). A player the server has never seen now receives every kit marked "Grant on first join" a moment
  after joining, exactly once. A relog grants nothing more, and an existing account never gets them. Three causes,
  all fixed: `KnKPlugin` built two caches, and the join listener read the one that never held the new account; the
  account created at pre-login was not marked as new; and the plugin misread the API's create response
  (`{user, linkCode}`), so creating the account failed before it was cached. That last one was already broken
  before. Live-tested 2026-10-11.
- **API connectivity: one up/down view of the API** ([KNG-115](https://linear.app/kngpandi/issue/KNG-115)): live-tested
  by the developer and merged. knk-web-api `master` `17ee730`, knk-plugin `main` `b5eee6e`.
  - The API's `GET /health/ready` now checks MySQL: 503 `unhealthy` when the database is down (never a 500), 200
    otherwise. A database outage is logged once when it starts and once when it ends.
  - The plugin probes `/health/ready` at the API root every 10 s (5 s timeout, never cached). It keeps one state:
    DOWN after 3 failed probes, UP after 2 passing ones. Each change fires `ApiConnectivityChangedEvent` on the main
    thread and is logged. `/knk health` shows the state, how long it has held and the last probe. Settings:
    `config.yml` → `api.connectivity`.
  - Nothing reacts to the event yet; offline security (KNG-58), hub outage actions (KNG-109/114) and Siege
    containment (KNG-117) will subscribe. See [architecture](architecture/api-connectivity.md).
- Players in owner mode or staff mode no longer show in the multiplayer server list ([KNG-127](https://linear.app/kngpandi/issue/KNG-127);
  knk-plugin `main` `ac2855a`). They were already hidden in game and in the tab list; the server list still counted them
  and showed their names when hovering over the player count. Now they are left out of both, and the Game Settings MOTD's
  `{online}` shows the same lowered count. The list has no viewer, so they are hidden there from staff too. Not yet
  checked in game.
- **Player statistics, leaderboards, owner diagnostics, GDPR deletion and world analytics** ([KNG-34](https://linear.app/kngpandi/issue/KNG-34),
  with [KNG-14](https://linear.app/kngpandi/issue/KNG-14)): merged after a live smoke test of all 27 steps
  ([guide and findings](guides/player-statistics-smoke-test.md)). knk-web-api `master` `34b8f9b`, knk-plugin `main`
  `aa5df70a`, knk-web-app `main` `5f40f93`. Six migrations (`AddPlayerStatistics` … `SeedStatisticsStaffNodes`).
  - **Statistics:** logins, active and AFK time (`/afk`, auto-AFK with an `[AFK]` tab marker in the group color), distance
    on foot, flying and in vehicles (mounts included), highest fall, PvP/PvE kills, deaths, damage, killstreaks, Siege
    results, coins/gems/XP earned and spent from the ledger (all past activity imported), title history, discoveries.
    Spooled to disk while the API is down.
  - **Privacy:** every statistic has its own visibility (Nobody by default, Friends, Everyone), set in game
    (`/stats settings`, a clearer group menu) or on `/account`, with a preview before group changes and a check for
    changes made elsewhere meanwhile.
  - **Read surfaces:** Profile → Statistics, `/stats [player]`, `/leaderboard` (`/lb <board> [period]` opens the board
    menu), web `/account`, `/players/<name>`, `/leaderboards` and a staff panel. Boards rank only statistics shown to
    everyone, cap repeat kills of the same victim at 3 a day, and support owner exclusions.
  - **Owner tools:** `/owner/telemetry` (diagnostic events, test runs, enhanced mode, player timeline), `/owner/privacy`
    (GDPR deletion: player requests with an email link, staff requests, 5-day grace period, erasure),
    `/owner/analytics` (movement heatmaps, menu funnels including Escape closes, domain entries/exits). Owner nodes
    `knk.owner.*`; wildcards unlock only analytics and leaderboard exclusions (D24). Moderators and Admins get
    `knk.admin.statistics.view`, Admins also `knk.admin.privacy.request`.
  - Kill switches in the plugin and API config. Follow-ups: [KNG-125](https://linear.app/kngpandi/issue/KNG-125)
    (menu item blinker), [KNG-126](https://linear.app/kngpandi/issue/KNG-126) (Reverse button feedback, trunk).

## 2026-10-10

- Gate teleports land somewhere safe, and gate doors no longer hurt players ([KNG-105](https://linear.app/kngpandi/issue/KNG-105),
  [KNG-106](https://linear.app/kngpandi/issue/KNG-106); knk-plugin `main` `8457657`). `/gatedoor tp` puts you on the
  ground next to the door, in front of or behind it, never inside its blocks or its opening, and refuses when there is
  no safe spot within 4 blocks. `/gate tp` uses the gate's spawn point (its Location) when set, else a safe spot by its
  first door, and says which. A closing or opening door (including a drawbridge's swing) now moves players, mobs,
  dropped items and vehicles with their riders out of its way before its blocks land, to solid ground on their own
  side when there is room; before, the collision check looked the wrong way while a door closed, and the push sent
  people behind a door through it. Anyone found inside door blocks (after a teleport, on join) is moved out, and door
  blocks cause no suffocation damage (`gates.safety.door-suffocation-damage: false`). Live-tested 2026-10-10.
- The first-join kit grant now runs once per player ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), API half;
  knk-web-api `master` `d5293fd`, migration `AddUserFirstJoinKitsGrantedAt`). A repeated or simultaneous
  grant-first-join call (a quick relog) no longer adds a second kit claim or second lootbox tokens; players already
  holding a first-join kit are marked as granted. Live-tested against the API 2026-10-10. The game server does not
  trigger the grant yet: the plugin half (one `CacheManager` in `KnKPlugin`) is still open.
- Walk paths get through tall buildings ([KNG-108](https://linear.app/kngpandi/issue/KNG-108); knk-plugin `main`
  `a388c70`). A walk path may now be 5 blocks longer for every block of height between the player and where they are
  going, so the way down a tower's spiral stair (the Keep Tower Roof: 168 blocks for 29 of height) is found. From
  such a roof the player gets the full path to the road instead of "Having trouble determining the route - guiding
  you to the nearest road.", and a destination on a roof gets a full path up. Setting:
  `navigation.walk.climb-allowance` (5; 0 = as before). A server `config.yml` needs no change. Known gap, not new: a
  player shut in within 8 blocks of a road is not told so ([KNG-124](https://linear.app/kngpandi/issue/KNG-124)).
- The game server now knows the domain of every region it preloads ([KNG-122](https://linear.app/kngpandi/issue/KNG-122);
  knk-plugin `main` `68022ce3`). The API answers a region lookup with at most one town, district and structure, so
  preloading several districts at once (when the road network loads, after `/knk cache refresh`, or for the regions at
  a spot) kept only one of them. The others were looked up later, one at a time, blocking routes for up to 3 seconds,
  and an overlapping second district could go unnoticed. The server now asks about each region on its own, a few at a
  time. The API and the web app are unchanged.
- A required yes/no (Boolean) field left unticked no longer blocks **Next** in FormWizard forms
  ([KNG-53](https://linear.app/kngpandi/issue/KNG-53); knk-web-app `main` `955fa20`). The KNG-26 fix only covered a
  brand-new form; resumed drafts saved before it and edit forms whose record had no value still held an empty value
  behind the unticked box. Every way a form is filled in now treats an unticked box as `false`. Also fixed: a saved
  `false` in a child/join form (e.g. a siege gate's Damageable) showed ticked when the field's default is on.
  Live-tested 2026-10-10.
- Domain forms accept an empty nullable field again ([KNG-119](https://linear.app/kngpandi/issue/KNG-119); knk-web-api
  `master` `a9e68f0` with migration `ClearPlaceholderFormFieldDefaults`). Editing a Town, District, Structure or
  GateStructure with **Road Access Override** (or Navigation Default Override, or another optional number, yes/no
  or choice field) left empty failed: entity metadata gave such fields the made-up default value "default", the
  Form Builder saved it on the field, and the form submitted it for the empty value. Metadata now reports no default
  for them, and the migration removes the saved "default" from existing form fields (text fields are left alone).
  An empty override follows the domain type again. The web app is unchanged.
- Navigation takes a road that a no-entry region covers only in part ([KNG-110](https://linear.app/kngpandi/issue/KNG-110),
  finding P4; knk-plugin `main` `4b9ddca4`). A region now blocks a road only where it covers the road's whole width:
  one free block beside it is enough, and the trail moves onto the free part, so the region's border does not push
  the player back. A region over the whole width blocks as before; for a player who may not leave a region, a stretch
  whose middle is in it still counts as inside. New: a region a player may enter but not leave blocks the way to a
  destination outside it ("You could not leave X again"), so navigation no longer leads players into it on the way
  somewhere else; a destination inside it is still reached. `/knk road status` counts the road pieces with such gaps.
  No new settings; the API and the web app are unchanged.
- Game Settings are applied in game ([KNG-52](https://linear.app/kngpandi/issue/KNG-52); knk-web-api `master`
  `8cce48d` with migration `AddGameSettingsMotdAndGroupOverrides`, knk-plugin `main` `973aa68b`, knk-web-app `main`
  `12c1d60`).
  - **What the page controls:**
    - the join and leave messages (`{player}`, `{group}`, `{title}`);
    - where regular players arrive on join (also the `/spawn` destination);
    - the server-list MOTD;
    - per world: the default game mode on join, a time lock, the weather rule (Normal, Constant, Blocked,
      Weighted) and the spawn point.
  - **Respawn per world:** synced with the join spawn, the world spawn (beds and anchors ignored), the server's
    choice (beds count), a chosen spot or the nearest town.
  - **Permission groups** can override the join and leave message, the spawn (a chosen spot, or "where they
    logged out" like owners) and the respawn. A player's groups count in the teleport-fee order (highest Weight
    first, each followed by its parents).
  - **Behaviour changes:**
    - **The hard-coded "respawn in town 4" is gone.** Respawn follows the page; choose Town 4 there to keep it.
    - Saving the page now needs `knk.admin.config`.
    - A staff `/weather` in a world with a weather rule asks for confirmation first.
    - The plugin keeps working from `plugins/KnightsAndKings/game-settings-cache.json` while the API is down.
  - **Spawn picker:** redesigned (a card for the chosen spot, a grouped searchable list with type chips). It now
    lists Structures, which were missing because the web app called a Locations route that doesn't exist.

- Navigation reaches destinations further off-road ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 2;
  knk-plugin `main` `8f2b7c30`). A destination may now be up to 256 blocks from a road (was 48). Within 96 blocks of
  where the road ends, the last stretch is a walk path; further out, the player is told "No conventional path to X
  found." and the HUD arrow and distance point the way until they are within 96 blocks, when a walk path takes over.
  Walk paths may now be up to 144 blocks long (was 96), and walks of up to 96 blocks, also to the road at the start,
  no longer fall back to a straight line for lack of captured terrain. Settings: `navigation.max-destination-distance`,
  `navigation.destination-walk-range`, `navigation.walk.max-length` (a server `config.yml` that spells out
  `max-length: 96` keeps the old cap - change it to 144). With walk paths off, nothing changes. KNG-75 is complete;
  follow-ups [KNG-108](https://linear.app/kngpandi/issue/KNG-108) (tall buildings) and KNG-36 (longer walks).

## 2026-10-09

- A navigating player off the road gets a walk path to it ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 1;
  knk-plugin `main` `c4141f90`). The trail shows the way to where the route starts (stairs, ladders, doors the
  player may open) instead of a straight line, and the road guidance starts once the player reaches the road; no
  "You left the road" on the way there. The player may now start up to 96 blocks from a road (was 48), measured in
  plain 3D, so a tower roof above a road works; height still decides which road (a bridge over a road). Shut in:
  "No conventional path to the road found."; a way too long to work out (a tall spiral stair): "Having trouble
  determining the route - guiding you to the nearest road." with the part of the path found. Setting:
  `navigation.max-start-distance`. With walk paths off, nothing changes. Follow-up for tall buildings:
  [KNG-108](https://linear.app/kngpandi/issue/KNG-108).
- Location retention is merged ([KNG-80](https://linear.app/kngpandi/issue/KNG-80); knk-web-api `master` `c397585`,
  knk-web-app `main` `d10e3dd`, knk-plugin `main` `68a5310`). A weekly check (Sunday 04:00 server time, configurable,
  plus "Run check now") flags Locations that still have the default name and that nothing uses, read from the database
  model rather than a hand-kept list, after a 7-day grace period. Staff review them under Player moderation → Orphaned
  Locations and keep or delete each one; nothing is deleted automatically, and a delete re-checks first. Kept Locations
  come back after 6 months or when they change. Online staff get one digest per run with something new;
  `/knk location orphans` and `/knk location tp <id>` work in game. New Moderator and Admin permission groups carry the
  new `knk.admin.location.*` nodes. Live-tested 2026-10-09
  ([smoke test](guides/location-retention-smoke-test.md), findings F1-F3 fixed). Follow-up: KNG-107.
- Gate commands get two layers ([KNG-77](https://linear.app/kngpandi/issue/KNG-77),
  [KNG-78](https://linear.app/kngpandi/issue/KNG-78), [KNG-79](https://linear.app/kngpandi/issue/KNG-79);
  knk-plugin `main` `5b1cc8b`, knk-web-api `master` `6192af0`):
  - `/gate` (`/knk gate`) acts on a whole gate and all its doors; `/gatedoor` (`/knk gatedoor`) acts on one door.
  - Both have open, close and **toggle**.
  - `here` picks the gate or door within 15 blocks, with a clickable choice when several are in range.
  - With no target, open, close, toggle, info and repair use the gate you are looking at, including an open one.
  - Per-id permissions now mean structure ids (`knk.gate.*`); door nodes are `knk.gatedoor.*`.
  - "here" is a reserved gate and door name.
  - See [architecture/gate-commands.md](architecture/gate-commands.md).
- The web app's entity navigator (left sidebar on the Dashboard and Forms pages) can be searched (display name or
  internal name) and sorted A–Z/Z–A ([KNG-61](https://linear.app/kngpandi/issue/KNG-61); knk-web-app `main`
  `ce47817`). On the Dashboard, types with a published default display configuration are listed under "Entities".
  The rest are in a collapsed "Without display configuration" group, and the Dashboard opens on the first
  "Entities" type. The sort direction and the group's open/closed state are remembered per page. Narrow-screen
  layout: [KNG-94](https://linear.app/kngpandi/issue/KNG-94).
- A navigation destination high above a road is no longer "too far from any road"
  ([KNG-75](https://linear.app/kngpandi/issue/KNG-75), finding N15; knk-plugin `main` `9f466a9f`). Destinations
  are measured to the nearest road in plain 3D; the player's own position still counts height ×4, so a player on
  a bridge keeps snapping to the bridge. A tower roof 28 blocks above a road is reached by road, then a walk path up.
  Setting: `navigation.destination-snap-vertical-weight` (default 1).
- Resetting a player's discovery on their moderation profile now asks in the app's own dialog instead of the
  browser's `confirm` ([KNG-40](https://linear.app/kngpandi/issue/KNG-40); knk-web-app `main` `6d23238`). After
  the reset the row leaves the list at once and a green line confirms it. The other `window.confirm` prompts are
  [KNG-82](https://linear.app/kngpandi/issue/KNG-82).
- Domain access refusals are also said in chat ([KNG-74](https://linear.app/kngpandi/issue/KNG-74); knk-plugin
  `main` `fd869aa`). The first "You are not allowed to enter/leave X." of a refusal episode goes to chat as well as
  the action bar. An episode is the first refusal after 10 s without one, or a different refusal. The `/navigate`
  arrow keeps off the action bar for about 3 s after a refusal, so the message can be read. Settings:
  `regions.access.chat-quiet-period-ms` and `action-bar-hold-ms`.
- Road navigation fixes from the live test, merged to knk-plugin `main`
  ([KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51)):
  - a gate closing behind the player no longer blocks the route; the route is judged by the part of each road still
    ahead;
  - a nearby destination the walk path cannot reach is tried by road ("following the roads instead");
  - a destination on the open side of a closed gate is reached;
  - with no open route, the player is guided as close to the destination as the open roads go.

## 2026-10-08

- Road navigation is merged ([KNG-27](https://linear.app/kngpandi/issue/KNG-27); knk-plugin `main` `f9026cb`,
  knk-web-api `master` `4c570fa`, knk-web-app `main` `b51eba0`). The road graph is built per tile from the world's
  road materials, with curated tiles that only propose changes after their first build, admin tools (`/knk road …`) and
  a web-app road admin page. `/navigate` (`/nav`) guides players along the roads with a particle trail and a HUD to a
  Location, Town, District, Structure (gates included, also as `gate:`), street or named road node. It respects gate
  state, pass-through rights, domain entry/exit rules and sieges, and re-routes on live changes. Design:
  [navigation](specs/navigation/DESIGN.md).
- Walkable last-mile paths ([KNG-51](https://linear.app/kngpandi/issue/KNG-51)): near a target, and after the road
  ends, the trail follows a path a player can walk (stairs, ladders, doors they may open, no regions they may not
  enter) instead of a straight line. Without one it says "No conventional path to X found."
  ([last-mile design](specs/navigation/LAST_MILE_PATHFINDING.md)).
- Live-tested on the dev server 2026-10-07/08 ([smoke-test guide](guides/road-navigation-smoke-test.md), findings
  N1-N12). Still open: the siege check (C6). Follow-ups: KNG-73, KNG-74, KNG-75, KNG-76.

## 2026-10-06

- PermissionGrant forms can now search for and pick a holder (a user or a permission group) in the web app: the web-app half of the PermissionHolder lookup is merged ([KNG-38](https://linear.app/kngpandi/issue/KNG-38), knk-web-app `main` `24b60ac`), completing the API half from 2026-10-04.

## 2026-10-05

- The lootbox opening reel's passing items now carry real enchantments ([KNG-54](https://linear.app/kngpandi/issue/KNG-54)), rolled from the box's own enchant rolls and shown with the grade the box gives them, so the winner is no longer the only enchanted item on the reel ([lootboxes design §3.9](specs/lootboxes/DESIGN.md)).
- Blueprint item descriptions without a colour of their own now render dark gray instead of vanilla purple lore (this fixes Flaming Samurai).
- Every route that spawns an item from a blueprint (lootbox delivery and reel, kits, `/knk itemblueprints give`) now builds it through one `BlueprintItemAssembler` entry point, and `/ce add` shares the custom-enchantment lore pipeline with `/ce remove`; see the [item render pipeline](architecture/item-render-pipeline.md). knk-plugin `main` `74607a9`.
- Fixed `/ce remove` leaving a stray blank line at the top of an item's lore after removing its last custom enchantment; removal now shares the same lore re-compose as applying one (knk-plugin `main` `e55e87f`).

## 2026-10-04

- Held a lootbox opening-reel item that comes up while the player is in a siege until their own inventory is restored, instead of losing it with the siege inventory ([KNG-44](https://linear.app/kngpandi/issue/KNG-44), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Replaced the lootbox admin Types tab's ~14 per-type odds requests with one staff-only batch endpoint, `GET api/LootboxTypes/odds` ([KNG-45](https://linear.app/kngpandi/issue/KNG-45), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Completed the plugin command-completion sweep with permission-filtered subcommands, vanish-aware player names, cached offline names where supported, fixed-value suggestions and explicit suppression of Bukkit's fallback suggestions ([KNG-30](https://linear.app/kngpandi/issue/KNG-30)).
- Fixed non-op staff access to `/freeze`, `/unfreeze`, `/staffchat` and `/knk` through the in-house permission model, and corrected the `/minecraft:tell`/`w` secure-chat mismatch ([KNG-24](https://linear.app/kngpandi/issue/KNG-24), [KNG-25](https://linear.app/kngpandi/issue/KNG-25)).
- Ensured siege members enter matches in survival so spawn-safe-zone damage denial is observable, and completed stable item-lore section spacing plus coherent lootbox special-description coloring ([KNG-28](https://linear.app/kngpandi/issue/KNG-28), [KNG-29](https://linear.app/kngpandi/issue/KNG-29)).
- Corrected untouched PermissionGroup premium-tier fields to submit `false` rather than `null` ([KNG-26](https://linear.app/kngpandi/issue/KNG-26)).
- Added the API half of the polymorphic PermissionHolder lookup used by PermissionGrant forms ([KNG-38](https://linear.app/kngpandi/issue/KNG-38)); its web-app half remains on the feature branch and is not yet part of the default-branch UI.

## 2026-10-02

- Added the maintained V1 → V2 → V3 [feature register](FEATURE_REGISTER.md), documented feature and guide updates at merge, and established this changelog ([KNG-33](https://linear.app/kngpandi/issue/KNG-33), [PR #5](https://github.com/PandiO/knk-workspace/pull/5)).

## 2026-09-29 — Backfilled from documented trunk merges

- Added managed WorldGuard-region ownership, priority and category-flag policy with idempotent startup repair. The live in-game smoke test remains tracked by [KNG-46](https://linear.app/kngpandi/issue/KNG-46) ([architecture](architecture/managed-worldguard-regions.md)).
- Modernized the shared AI-agent workflow and portable repository entrypoints ([KNG-32](https://linear.app/kngpandi/issue/KNG-32)).

## 2026-09-28 — Backfilled from documented trunk merges

- Completed the teleport feature merge, including requests, spawn/warps and ignore integration ([KNG-17](https://linear.app/kngpandi/issue/KNG-17), [design](specs/teleport/DESIGN.md)). Housing-linked `/home` remains separate scope.

## 2026-09-27 — Backfilled from documented trunk merges

- Added a permanent coin/gem transaction ledger and secure player payments, balance commands and administration ([KNG-21](https://linear.app/kngpandi/issue/KNG-21), [design](specs/currency-payments/DESIGN.md)).
- Added first-entry Town, District and Structure discoveries, rewards and a Discoveries menu ([KNG-20](https://linear.app/kngpandi/issue/KNG-20), [plan](specs/domain-discovery/IMPLEMENTATION_PLAN.md)).
- Expanded private messages with ignore, social-spy controls and moderation history ([KNG-18](https://linear.app/kngpandi/issue/KNG-18)). Its secure-chat follow-up was later completed in [KNG-25](https://linear.app/kngpandi/issue/KNG-25).
- Added world lootboxes, token pickups and an opening reel ([KNG-19](https://linear.app/kngpandi/issue/KNG-19)). The second live retest and remaining decisions are tracked in [KNG-31](https://linear.app/kngpandi/issue/KNG-31).

## 2026-09-26 — Backfilled from documented trunk merges

- Merged the Siege MVP: configurable scenarios, teams, objectives, live matches and player menus, following two live smoke-test rounds. Scheduled lobbies are later scope ([siege plan](specs/siege-minigame/IMPLEMENTATION_PLAN.md)).
- Added title and premium-tier display in game chat/tab list ([KNG-7](https://linear.app/kngpandi/issue/KNG-7), [KNG-8](https://linear.app/kngpandi/issue/KNG-8)).
- Ported general enchantment books and grade-based application limits ([KNG-5](https://linear.app/kngpandi/issue/KNG-5), [KNG-6](https://linear.app/kngpandi/issue/KNG-6)).
- Corrected hourly title salary and join-time payouts ([KNG-16](https://linear.app/kngpandi/issue/KNG-16)).

## 2026-09-25 — Backfilled from documented trunk merges

- Merged the persisted kit system, grant commands and kit authoring workflow. First-join grant remained to be confirmed live in the [kit plan](specs/kits/IMPLEMENTATION_PLAN.md).

For older implementation detail, consult [feature plans](specs/README.md), [dated reports](reports/) and the repository histories. Do not interpret the first date of a branch or issue as a release date.
