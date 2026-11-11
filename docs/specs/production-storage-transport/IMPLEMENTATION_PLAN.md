# Production, storage and transport — Implementation plan

**Status:** Draft, **rev. 3** (after the developer's voice design review of 2026-11-05,
[decision record](DECISIONS_2026-11-05.md) §10). No phase has started. Decisions are in
[DESIGN §14](DESIGN.md#14-decisions), [PRODUCTION_KINDS §9](PRODUCTION_KINDS.md#9-decisions) and
[TOWN_LOGISTICS §8](TOWN_LOGISTICS.md#8-decisions); the few still open are listed there. Every item is marked
**V1** or **Later**. The production structures work and the garrison/guard NPC work ship in the **same test phase**.
**Last updated:** 2026-11-11 (open questions answered, [decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11); issues #324, #325)
**Design:** [DESIGN.md](DESIGN.md), [PRODUCTION_KINDS.md](PRODUCTION_KINDS.md), [TOWN_LOGISTICS.md](TOWN_LOGISTICS.md),
[shops DESIGN](../shops/DESIGN.md), [NPC platform](../npc-platform/DESIGN.md) (lifecycle).
**Evidence:** [V2 scan](../../reports/2026-10-09-v2-production-storage-transport-scan.md).
**Issues:** parent [#22](https://github.com/PandiO/knk-workspace/issues/22) (`[KNG-83]`). Phase issues are sub-issues of #22 and keep
their Linear id in the title (`[KNG-84]` = [#97](https://github.com/PandiO/knk-workspace/issues/97) and so on). Prerequisite
[#141](https://github.com/PandiO/knk-workspace/issues/141) (`[KNG-95]`, every item is a blueprint item).
**Branches (when work starts):** one standing branch per repo, `claude/production-storage-transport`, cut from
each repo's current default branch (`master` for knk-web-api, `main` for the others). The earlier docs-only
knk-workspace branch of that name was merged into `main` and deleted on 2026-10-18. Follow the board rules in
[ACTIVE_SESSIONS.md](../../ACTIVE_SESSIONS.md).

**Revision history**

- **Rev. 2 (2026-10-09):** phases P1-P9 and the web-app insight track.
- **Rev. 3 (2026-11-05, [decision record](DECISIONS_2026-11-05.md) §10):** decision record items folded into P1, P3,
  P5, P6, P7, P8 and P9; new phases P10 Shops, P11 Shopkeepers and P12 Display stalls; NPC lifecycle requirements on
  the NPC platform; every item marked V1 or Later; new Later issues; smoke test updated.
- **2026-11-11 ([decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11)):** P10 gains a minimal town account kind and the settled pricing
  details; P9 releases expired reservations; Later issues #324 and #325.

## Rules for every phase

- **Web app first** (developer note 10). A phase that adds entities also ships:
  - their FormConfig CRUD;
  - a detail view with the insight data it produces: ledger, cycle trace, event log, plan explanation.
  - In-game menus and commands follow in P6, or within the phase when they are needed to test.
- **Checks per phase:**
  - `dotnet test` (API, including `requires-mysql` concurrency tests for stock);
  - `npm run test:ci` + `npm run build` (web app);
  - `./gradlew build -x deployToDevServer` (plugin);
  - a smoke list for the developer;
  - updated status lines here, feature register rows, and `CHANGELOG.md` on merge.
- **The reconciler stays green.** Any phase that moves stock adds its paths to the reconciliation tests.

## Order and dependencies

```
KNG-95 Item identity ───────────────────────────────┬──────────────┬──────────────┐
                                                    │              │              │
P1 Stock core (84) ──► P2 World (85) ──► P3 Production engine (86) ──► P4 Areas & surveys (96) ──► P8 Harvest & regen (97)
        │                    │                 │
        │                    └────────► P5 Transport core (87) ──► P9 Town logistics (98) ──► later: trade (100)
        │                                      │                                               next: NPC caravans (#251)
        └──► P7 Delivery, inbox, deposit (90) ◄┘  P6 Plugin terminals/menus (88)

P10 Shops (#248): static catalogue ──► restocking (needs P9), processing, player selling
        ├──► P11 Shopkeepers (#249) ◄── NPC platform lifecycle (KNG-36; same test phase as the guard work, #234)
        └──► P12 Display stalls (#250)
web-app insight (89) grows with each phase
```

P10's static catalogue needs P1, P2 and the P3 level pattern only, so it can start before P9. Restocking needs P9.

---

## P1 — Stock core · [#97](https://github.com/PandiO/knk-workspace/issues/97) (`[KNG-84]`)

**API**

All **V1**.

- `Storage` (kind, holder FKs or `SystemKey`, purpose, capacity value object, stored totals, `RowVersion`, lock
  fields).
- **Capacity in raw units (rev. 3):** `MaxUnits`, `MaxDistinct`, `UnitsPerSlot`; capacity use = Σ amount ×
  `ItemBlueprint.StorageWeight`. No `StackSlots` mode.
- **`ItemBlueprint.StorageWeight`** (decimal, default 1) with its migration. Per-item values are Later tuning, data
  only.
- `StockLine`, `StockUnit`, `StockTransaction`, `StockMove`. Enums in `Enums/`.
- Migration `AddStockCore`, which seeds the virtual storages `SYS_PRODUCTION`, `SYS_CONSUMPTION`, `SYS_LOSS`,
  `SYS_ADJUSTMENT` and `SYS_WORLD`.
- `Services/Stock/StockService.cs` (`Move`, `MoveMany`; row locks in id order; AllOrNothing or Partial; result
  values).
- `StockReconciler`.
- `StoragesController`, `StockTransactionsController` (ledger, paged).
- Permission `knk.economy.admin`.

**Web app:** storage CRUD, a storage detail view (lines and units), a manual move/adjust dialog, the ledger explorer,
`StorageWeight` on the blueprint form.

**Tests:**

- capacity in raw units with `StorageWeight` (default 1 and a non-1 value);
- partial vs all-or-nothing;
- idempotency replay;
- concurrent moves (MySQL);
- the reconciler after every path;
- Restrict FKs;
- locks.

## P2 — World: rural structures, Warehouse, ProductionStructure · [#91](https://github.com/PandiO/knk-workspace/issues/91) (`[KNG-85]`)

**Needs:** the territory V1 work ([#326](https://github.com/PandiO/knk-workspace/issues/326), [territory DESIGN](../territory/DESIGN.md)) for the territory
lookup used by P-2 and P-3; DESIGN D1 (2026-11-11, DESIGN §3.4) and D5 (confirmed 2026-11-05). All **V1**. The
district part of this phase doesn't wait for #326.

**API**

- `Structure.TownId` for rural structures, with the District-xor-Town rule; `DistrictId` and `StreetId` nullable; an
  effective-town resolver (DESIGN §3.3-3.4).
- `Warehouse : Structure`.
- `ProductionStructure : Structure` (fields per DESIGN §3.3, including `WorkersTotal`; `ProductionKindId` nullable
  until P3 seeds kinds).
- **Placement rules** (DESIGN §3.4): P-1 `RegionContainment` against the district in the Warehouse,
  ProductionStructure (and later Shop) seed forms; P-2 and P-3 through a new `InsideTerritory` validation type; the
  same rules checked on save in the API.
- A flag on structures whose land is contested or outside their town's territory, listed on the
  `TerritoryConflict` (#326).
- Default storages on create.
- Audit and fix every `Structure.District` and `Structure.Street` dereference; list the call sites in the PR.

**Web app:** FormConfigs with WorldTask capture (district or rural, with the town picker for rural); the rule builder
offers `InsideTerritory`; the dashboard shows flagged structures.

**Plugin:** managed-region kinds ProductionStructure (`RESOURCE_PRODUCTION`) and Warehouse (`STRUCTURE`); rural
structure regions without a parent at their floor priority; `/knk regions repair` handles structures without a
district; tests in `ManagedRegionPolicyTest`.

**Tests:** District-xor-Town; effective town for both; P-1 blocks, P-2 and P-3 warn; a structure on land that becomes
contested keeps its town and is flagged; rural structures through navigation, discovery and domain access.

## P3 — Production engine · [#86](https://github.com/PandiO/knk-workspace/issues/86) (`[KNG-86]`)

**API**

All **V1** unless marked.

- `ProductionKind` + seeds (PRODUCTION_KINDS §2.1; Hunter stays out of V1, P-D10).
- `ProductionKindLevel` (10 levels: yield multiplier, cycle speed, storage caps and `UnitsPerSlot`, transport
  capacity, an `UpkeepReduction` field **without effect**) and an upgrade action.
- `ProductionLine` (Configured rates in this phase, decimal accrual, inputs, status, `NextSettleAt` index).
- **Modifier pipeline (rev. 3):** `ProductionModifier` (scope, target, effect, active window, source), a resolver
  per cycle, and modifier **sources** as an extension point. V1 sources: **structure level** and **weather**.
- **Weather (rev. 3):** `ClimateZone` (one default; assignable per town), weather types with odds per
  zone and modifiers per resource category, a **daily stored roll per zone** (`WeatherRoll`), and a sweep that rolls
  once per in-game day.
- **Producer workers (rev. 3):** `WorkersTotal` (default 2), workers present, and the worker-availability factor in
  settle (one of two away → 50%, both away → 0).
- `ProductionCycleRecord` with **each** applied modifier and the workers present.
- `ProductionService.Settle*`.
- `ProductionSweepService` (pattern: `RankExpirySweepService`, with an injectable clock).
- Notifications to the outbox (blocked and resumed).
- **Later:** the other modifier sources ([#254](https://github.com/PandiO/knk-workspace/issues/254), [#255](https://github.com/PandiO/knk-workspace/issues/255), [#257](https://github.com/PandiO/knk-workspace/issues/257)).

**Web app:** kind, level and line editors; modifier list; climate zone and weather editors with the roll history;
structure detail with the cycle trace (per modifier) and a "why not producing" view.

**Tests:** drift-free accrual over simulated clocks; catch-up cap; stall-when-full (D4); inputs; level modifiers,
cycle speed and unlocks; modifier scope, target and window matching and their order; one stored weather roll per
zone per day, identical on replay; worker factor 100/50/0%; upgrade costs (stock + currency in one transaction).

## P4 — Yield areas and surveys · [#138](https://github.com/PandiO/knk-workspace/issues/138) (`[KNG-96]`)

All **V1** (unchanged in rev. 3; Hybrid default confirmed, P-D1).

**API:**

- `ProductionArea` (models, shapes, exclusivity checks);
- `AreaSurvey` history;
- survey profiles and yield tables;
- Derived/Hybrid rate materialization into lines;
- shared-area split.

**Plugin:**

- an async survey runner on `ChunkSnapshot`s: blocks, trees, water and biome, crops and flowers, pasture entities;
- a tick budget;
- `/knk production survey|area show`;
- a `CaptureRadius` WorldTask handler.

**Web app:** area capture, survey viewer (composition table, 2D plot, trend), Hybrid override editor.

**Tests:** tree detection fixtures; overlap split; Derived vs Hybrid materialization; survey idempotence (same world
→ same hash).

## P5 — Transport core (simulated) · [#79](https://github.com/PandiO/knk-workspace/issues/79) (`[KNG-87]`)

**API**

- `TransportOrder`, `TransportStop`, `TransportOrderLine`, a Transit storage per order, `TransportAssignment`
  (Simulated), `TransportEvent`, `TransportLane`.
- Triggers, sizing and destination choice (DESIGN §7.4, §7.6). **V1**
- **Simulated only, robbery off** (D6). **V1**
- **Carried by the producer's own workers (rev. 3):** an order takes a free worker, the worker's capacity bounds the
  order, and the order waits when no worker is free; the worker is away until the order is done (DESIGN §7.7).
  **V1**
- **Unconnected producers (rev. 3, D5):** automatic transport held; warnings for the missing road and the full
  storage. **V1**
- `TransportSweepService`; manual orders, dry run, cancel. **V1**
- **Later:** NPC caravans with virtual movement ([#251](https://github.com/PandiO/knk-workspace/issues/251), next follow-up), town carrier pool for hire
  ([#252](https://github.com/PandiO/knk-workspace/issues/252)), couriers, robbery and escort ([#53](https://github.com/PandiO/knk-workspace/issues/53)).

**Plugin:** lane measurer (`AStarRouter`), `RoadConnection` updates, `/knk logistics lanes measure`, a headless
periodic job.

**Web app:** order list and detail (timeline, cargo, route), manual order form, dry run.

**Tests:** every lifecycle path, including AwaitingSpace → re-route → Returning and ReturnBlocked; cancel in each
state; restarts mid-transit; one open automatic order per source; ledger reconciliation; an order waits without a
free worker; output drops while a worker is away and recovers on return; an unconnected producer holds transport and
stops when full.

## P6 — Plugin: terminals, displays, menus, commands · [#74](https://github.com/PandiO/knk-workspace/issues/74) (`[KNG-88]`)

All **V1**; Backed mode is Later ([#113](https://github.com/PandiO/knk-workspace/issues/113)).

**API:** `StorageContainer` CRUD (Terminal and Display modes); container-derived capacity = bound slots ×
`UnitsPerSlot` (rev. 3).

**Plugin:**

- terminal inventory view (paged; take and put as `SYS_WORLD` moves with idempotency keys);
- display renderer;
- logistics menus;
- `/knk storage|production|transport|logistics`;
- notifications and Bukkit events.

**Needs:** KNG-95 for put/take resolution.

**Tests:** canonical container keys (double chests); terminal take/put under lag and retry; display refresh
throttling; binding or unbinding a container changes the cap by its slots × `UnitsPerSlot`.

## P7 — Item delivery, reward inbox, deposit/withdraw · [#60](https://github.com/PandiO/knk-workspace/issues/60) (`[KNG-90]`)

All **V1**.

**API:** `IItemDeliveryService`, player Inbox and Stash storages, claim and expiry, deposit/withdraw endpoints.
Rev. 3 inbox rules (DESIGN §4.6):

- a **hard cap**, with a **premium cap source** (premium tiers raise it);
- **overflow to `SYS_LOSS`** (`InboxOverflow`) when a reward arrives at a full inbox;
- **near-cap warnings** and a notification when something is lost;
- **30-day expiry** with reminders (`InboxExpired` to `SYS_LOSS`).

**Plugin:** `/inbox` and an inbox menu; migrate `KitGrantPlacer` and `LootboxDelivery` from dropping at the
player's feet to the delivery service.

**Tests:** offline, full-inventory and in-minigame deliveries land in the inbox; claim with partial space;
`StockUnit` rewards keep their enchantments; retries don't duplicate; a full inbox sends the reward to `SYS_LOSS`
with a ledger record and a notification; premium raises the cap; warnings at the thresholds; expiry after 30 days.

## P8 — Player harvesting and block regeneration · [#134](https://github.com/PandiO/knk-workspace/issues/134) (`[KNG-97]`)

All **V1** unless marked.

**API:**

- `HarvestRule` per kind, with `WorkerShare` (default 25%);
- `ResourcePool` per area;
- a harvest report endpoint (idempotent, batched) that **splits each harvest**: the worker's share as
  `SYS_PRODUCTION → SYS_WORLD`, the rest `SYS_PRODUCTION → Output` (both `PlayerHarvest`);
- the pool factor in settle;
- the **net-positive check** per rule (PRODUCTION_KINDS §6.3), shown in the web app.
- An optional coin wage or title XP per harvest is allowed, not required.
- **Later:** professions, paid work, quests, the roleplay theft mode.

**Plugin:**

- the harvest listener in `RESOURCE_PRODUCTION` regions (replaces the KNG-48 config switch);
- `IRequirementEvaluator` (permission and title now);
- blueprint drops through KNG-95;
- a disk-persisted regeneration queue with placeholders and tree snapshots.

**Tests:** allowed vs denied breaks; the worker's share split and its ledger moves; the town gains net output for a
net-positive rule; pool math; regeneration across restart and chunk unload; surveys counting pending regenerations.

## P9 — Town logistics · [#127](https://github.com/PandiO/knk-workspace/issues/127) (`[KNG-98]`)

The developer reviewed TOWN_LOGISTICS §4 on 2026-11-05; the V1 subset is below.

**API (V1):**

- service areas (default: nearest warehouse by road);
- consumer replenishment settings (reorder point, target level, priority class);
- **consumer workers** (the same model as producer workers);
- `LogisticsPolicy`/`LogisticsRule` (versioned) with the V1 rule types: reserves, priority classes, service areas;
- **reserve and collect:** `LogisticsPlanner` (10-minute interval plus dry run) creating **reservations** and
  **collection orders** carried by the consumer's worker, with explanations;
- default policy templates, edited by admins;
- no warehouse workers.

**Later:** ceilings, allocation quotas, export/import and embargoes, emergency modes, rebalance, tax/tariff
([#324](https://github.com/PandiO/knk-workspace/issues/324)); clan council governance (later stage); in-game runtime management ([#256](https://github.com/PandiO/knk-workspace/issues/256)); warehouse throughput ([#253](https://github.com/PandiO/knk-workspace/issues/253)).

**Web app:** policy and rule editor, planner dry-run view, town supply view with reservations.

**Tests:** reserves never breached; a reservation can't be taken twice; priority under scarcity; collection by the
consumer's worker lowers its output while away; expired reservations are released at the next run; explanation
content.

## P10 — Shops · [#248](https://github.com/PandiO/knk-workspace/issues/248)

**V1.** Design: [shops DESIGN](../shops/DESIGN.md). One update, built in this order:

1. **Static admin catalogue first** (needs P1, P2 and the P3 level pattern):
   - `Shop : Structure` with Input and Merchandise storages, a kind (`Processing` or `Trading`), a level, accepted
     categories, its own worker and a shopkeeper spawn location (used by P11);
   - `ShopCatalogueEntry` (blueprint or item instance, static price, admin pin);
   - shop levels on the production level pattern (processing speed, yield, input cost, price multiplier, storage
     caps), with the same admin UI;
   - **minimal town account kind** (`AccountKind.Town`) so shop income goes to the town (decision 2026-11-11; trade,
     tax and spending stay in [#124](https://github.com/PandiO/knk-workspace/issues/124));
   - buying: a currency transaction (player → town account) and a stock transaction in one database transaction;
     **every purchase confirmed**;
   - interim pricing: a static price wins; otherwise base price (midpoint of `BasePriceMin`/`BasePriceMax`) × shop
     tax modifier × shop level modifier; enchantments on unique items add a percentage of the base price.
2. **Then, in the same update:**
   - **restocking** from the warehouse by the shop's own worker (reserve and collect, needs P9);
   - **processing** lines (flour → bread) on the P3 engine;
   - **players selling** to shops: accepted categories; buy-back = sell formula × buy-back % (default 50%); unique
     items become a `StockUnit` in Merchandise and are resold as that exact item.

**Plugin:** shop menus on the inventory menu engine, from the developer's V1 menu templates.

- **hourly trade stats** (`ShopTradeStat` per shop, blueprint and hour, rolled up from the ledger; shops DESIGN
  §9.1): recorded from V1 for the later pricing model, not used by V1 pricing.

**Web app:** shop CRUD, catalogue editor, levels, sales ledger, trade stats chart.

**Tests:** the hourly rollup matches the ledger and is idempotent per shop and hour; a purchase is atomic (coins and stock together, coins to the town account); confirmation required; a static price wins; formula
price; 50% buy-back; refused categories; a sold enchanted item comes back on sale with its enchantments; restock and
processing keep the ledger reconciled.

**Later:** real pricing ([#120](https://github.com/PandiO/knk-workspace/issues/120)); a town turnover tax on shops with shop margins ([#325](https://github.com/PandiO/knk-workspace/issues/325)); sales
slowed while a shop's only NPC is out, once hired workers exist. **Decided later:** whether selling to a shop should
be more or less attractive than selling to a marketplace vendor.

## P11 — Shopkeepers · [#249](https://github.com/PandiO/knk-workspace/issues/249)

**V1.** Needs P10 and the NPC platform lifecycle (KNG-36, [#234](https://github.com/PandiO/knk-workspace/issues/234)). Ships in the same test phase as the
garrison/guard NPC work.

- A shopkeeper NPC (human or villager) at the shop's stored spawn location.
- Stays in place and looks at nearby players by default; option to roam within the shop region.
- A greeting on entering the shop region, with a cooldown (cosmetic).
- Right-click opens the shop menu: info header (name, level, owner) and the paged catalogue.
- NPC lifecycle: non-persistent entity, spawn on demand, one live entity per NPC id, orphan sweep on chunk load.

**Tests:** one shopkeeper after a restart, a crash, a chunk reload and repeated spawn requests; orphans removed;
greeting cooldown; the menu opens for the right shop.

## P12 — Display stalls · [#250](https://github.com/PandiO/knk-workspace/issues/250)

**V1.** Needs P10.

- `ShopDisplaySpot`, registered explicitly (like containers; never scanned).
- Paper item display entities with a floating price label, non-persistent.
- Selection: admin pins first, then the system fills the rest (in stock and best sellers first); sold-out items are
  greyed out by default, hidden as an option per shop.
- Right-click → shop item information menu; shift-right-click → quick buy with a confirmation.

**Tests:** spot selection order; sold-out handling; no duplicate display entities after reloads; quick buy always
asks for confirmation.

## NPC platform: lifecycle and reliability

**V1**, owned by the NPC platform ([NPC platform DESIGN](../npc-platform/DESIGN.md), lifecycle section). Needed by
P11 and by rendered producer and consumer workers, later by carriers, alongside guards. The garrison/guard NPC work
([#234](https://github.com/PandiO/knk-workspace/issues/234), [#238](https://github.com/PandiO/knk-workspace/issues/238)) ships in the same test phase as this feature.

## Web-app insight · [#65](https://github.com/PandiO/knk-workspace/issues/65) (`[KNG-89]`)

The logistics dashboard, simulator, health view and order map. These grow alongside P3-P12.

---

## Later

Designed for in V1 (fields, extension points), not built.

| Item | Issue |
|---|---|
| NPC caravans with virtual movement (**next follow-up after V1**) | [#251](https://github.com/PandiO/knk-workspace/issues/251) |
| Physical transport: player couriers, robbery, escort, route risk, quests | [#53](https://github.com/PandiO/knk-workspace/issues/53) (`[KNG-99]`) |
| Town carrier pool for hire | [#252](https://github.com/PandiO/knk-workspace/issues/252) |
| Warehouse workers and throughput | [#253](https://github.com/PandiO/knk-workspace/issues/253) |
| Painted fertility map | [#254](https://github.com/PandiO/knk-workspace/issues/254) |
| Technologies / knowledge modifier | [#255](https://github.com/PandiO/knk-workspace/issues/255) |
| Seasons, staffing, exhaustion, events, neighbour bonuses, upkeep, war disruption, per-player weather | [#257](https://github.com/PandiO/knk-workspace/issues/257) |
| In-game runtime management | [#256](https://github.com/PandiO/knk-workspace/issues/256) (town runtime management design: [#246](https://github.com/PandiO/knk-workspace/issues/246)) |
| Inter-town trade and town treasury accounts | [#124](https://github.com/PandiO/knk-workspace/issues/124) (`[KNG-100]`) |
| Pricing (needs the developer's pricing documents first) | [#120](https://github.com/PandiO/knk-workspace/issues/120) (`[KNG-101]`) |
| Backed container sync for housing | [#113](https://github.com/PandiO/knk-workspace/issues/113) (`[KNG-102]`) |
| Ceilings, quotas, export/import, emergency modes, rebalance, tax/tariff | [#324](https://github.com/PandiO/knk-workspace/issues/324) |
| Town turnover tax on shops and shop margin pricing | [#325](https://github.com/PandiO/knk-workspace/issues/325) |
| Clan council governance | later stage than #324/#325; no issue yet (developer 2026-11-11) |
| Professions, paid work and quests for harvesting; roleplay theft mode | later stage than #324/#325; no issue yet (developer 2026-11-11) |
| Processing chains beyond V1 shops, ownership and payouts | [#56](https://github.com/PandiO/knk-workspace/issues/56) (`[KNG-91]`; its shop part moved to P10-P12) |

## Smoke test outline (after P5, P6, P7 and P10-P12)

1. In the web app:
   - give Cinix a power value so its territory reaches the forest north of town (territory feature, #326);
   - create the Docks Warehouse (district) with a terminal chest and a display chest, `UnitsPerSlot` 200; its cap
     shows 27 slots × 200 = 5,400 units per single chest;
   - create a Coal Mine (district) and a rural Logger for Cinix in that forest, with a radius over the trees; each
     has 2 workers. Placing the logger outside Cinix's territory shows a warning;
   - give Cinix a climate zone with a high storm chance.
2. Survey the logger (`/knk production survey`). Check the composition and the derived rates in the web app.
3. `/knk logistics lanes measure`. The logger shows `Connected`, or `Unconnected` with a held-transport warning. An
   unconnected logger keeps producing until its storage is full, then stops, with both warnings on the dashboard.
4. Set the mine's rate high and watch the cycle trace: it lists the level modifier and the day's weather modifier.
   At the threshold an automatic order is planned and one worker leaves with it: the next cycle shows 50% output.
   Stock leaves the mine at departure, sits in transit, and arrives at the ETA. The display chest fills. The worker
   returns and output is back to 100%.
5. Lower the warehouse cap: AwaitingSpace → Returning → Returned. The ledger reconciles.
6. Restart the API mid-transit: the order resumes.
7. Take coal from the terminal chest. Your inventory gets blueprint-tagged coal, and the ledger shows a `SYS_WORLD`
   move.
8. Harvest in the mine's area as a player who meets the rule: you get about 25%, the rest appears in the mine's
   Output storage; the dashboard shows the mine's net output going up.
9. Fill your inbox to its cap, then claim a reward: you get the near-cap warning, the overflow lands in `SYS_LOSS`
   with a notification.
10. Create a trading shop with a static catalogue and a shopkeeper. Walk in: the shopkeeper greets you once and looks
    at you. Right-click: the shop menu shows the info header and the catalogue. Buy an item: a confirmation first,
    then coins and stock move together.
11. Shift-right-click an item on a display stall: quick buy asks for confirmation. Right-click shows the item info.
12. Sell an enchanted sword to a weaponsmith at 50% of its price; it comes back on sale with its enchantments. A
    weaponsmith refuses bread.
13. Restart the server and reload the shop's chunks: exactly one shopkeeper and one set of display entities.
