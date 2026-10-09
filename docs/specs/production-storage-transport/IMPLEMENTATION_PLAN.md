# Production, storage and transport — Implementation plan

**Status:** Draft, **rev. 2** (after the developer's notes of 2026-10-09). No phase has started. The open decisions
are in [DESIGN §14](DESIGN.md#14-decisions), [PRODUCTION_KINDS §9](PRODUCTION_KINDS.md#9-decisions) and
[TOWN_LOGISTICS §8](TOWN_LOGISTICS.md#8-decisions). Each has a recommendation; phases can start on those.
**Last updated:** 2026-10-09
**Design:** [DESIGN.md](DESIGN.md), [PRODUCTION_KINDS.md](PRODUCTION_KINDS.md), [TOWN_LOGISTICS.md](TOWN_LOGISTICS.md).
**Evidence:** [V2 scan](../../reports/2026-10-09-v2-production-storage-transport-scan.md).
**Linear:** parent [KNG-83](https://linear.app/kngpandi/issue/KNG-83). Prerequisite
[KNG-95](https://linear.app/kngpandi/issue/KNG-95) (every item is a blueprint item).
**Branches (when work starts):** one standing branch per repo, `claude/production-storage-transport`, cut from
each repo's current default branch (`master` for knk-web-api, `main` for the others). Follow the board rules in
[ACTIVE_SESSIONS.md](../../ACTIVE_SESSIONS.md).

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
        │                                      │                                               later: physical transport (99)
        └──► P7 Delivery, inbox, deposit (90) ◄┘  P6 Plugin terminals/menus (88)        web-app insight (89) grows with each phase
```

---

## P1 — Stock core · [KNG-84](https://linear.app/kngpandi/issue/KNG-84)

**API**

- `Storage` (kind, holder FKs or `SystemKey`, purpose, capacity value object, stored totals, `RowVersion`, lock
  fields).
- `StockLine`, `StockUnit`, `StockTransaction`, `StockMove`. Enums in `Enums/`.
- Migration `AddStockCore`, which seeds the virtual storages `SYS_PRODUCTION`, `SYS_CONSUMPTION`, `SYS_LOSS`,
  `SYS_ADJUSTMENT` and `SYS_WORLD`.
- `Services/Stock/StockService.cs` (`Move`, `MoveMany`; row locks in id order; AllOrNothing or Partial; result
  values).
- `StockReconciler`.
- `StoragesController`, `StockTransactionsController` (ledger, paged).
- Permission `knk.economy.admin`.

**Web app:** storage CRUD, a storage detail view (lines and units), a manual move/adjust dialog, the ledger explorer.

**Tests:**

- capacity (both weightings);
- partial vs all-or-nothing;
- idempotency replay;
- concurrent moves (MySQL);
- the reconciler after every path;
- Restrict FKs;
- locks.

## P2 — World: Territory, Warehouse, ProductionStructure · [KNG-85](https://linear.app/kngpandi/issue/KNG-85)

**Needs:** DESIGN D1 and D5.

**API**

- `Territory : Domain`.
- `Structure.TerritoryId` with the District-xor-Territory rule; an effective-town resolver.
- `Warehouse : Structure`.
- `ProductionStructure : Structure` (fields per DESIGN §3.3; `ProductionKindId` nullable until P3 seeds kinds).
- Default storages on create.
- Audit and fix every `Structure.District` dereference; list the call sites in the PR.

**Web app:** FormConfigs with WorldTask capture.

**Plugin:** managed-region kinds for Territory, ProductionStructure and Warehouse; tests in
`ManagedRegionPolicyTest`.

## P3 — Production engine · [KNG-86](https://linear.app/kngpandi/issue/KNG-86)

**API**

- `ProductionKind` + seeds (PRODUCTION_KINDS §2.1).
- `ProductionKindLevel` (10 levels) and an upgrade action.
- `ProductionLine` (Configured rates in this phase, decimal accrual, inputs, status, `NextSettleAt` index).
- `ProductionCycleRecord`.
- `ProductionService.Settle*`.
- `ProductionSweepService` (pattern: `RankExpirySweepService`, with an injectable clock).
- Notifications to the outbox (blocked and resumed).

**Web app:** kind, level and line editors; structure detail with the cycle trace and a "why not producing" view.

**Tests:** drift-free accrual over simulated clocks; catch-up cap; stall-when-full (D4); inputs; level multipliers
and unlocks; upgrade costs (stock + currency in one transaction).

## P4 — Yield areas and surveys · [KNG-96](https://linear.app/kngpandi/issue/KNG-96)

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

## P5 — Transport core (simulated) · [KNG-87](https://linear.app/kngpandi/issue/KNG-87)

**API**

- `TransportOrder`, `TransportStop`, `TransportOrderLine`, a Transit storage per order, `TransportAssignment`
  (Simulated), `TransportEvent`, `TransportLane`.
- Triggers, sizing and destination choice (DESIGN §7.4, §7.6).
- `TransportSweepService`; manual orders, dry run, cancel.

**Plugin:** lane measurer (`AStarRouter`), `RoadConnection` updates, `/knk logistics lanes measure`, a headless
periodic job.

**Web app:** order list and detail (timeline, cargo, route), manual order form, dry run.

**Tests:** every lifecycle path, including AwaitingSpace → re-route → Returning and ReturnBlocked; cancel in each
state; restarts mid-transit; one open automatic order per source; ledger reconciliation.

## P6 — Plugin: terminals, displays, menus, commands · [KNG-88](https://linear.app/kngpandi/issue/KNG-88)

**API:** `StorageContainer` CRUD (Terminal and Display modes).

**Plugin:**

- terminal inventory view (paged; take and put as `SYS_WORLD` moves with idempotency keys);
- display renderer;
- logistics menus;
- `/knk storage|production|transport|logistics`;
- notifications and Bukkit events.

**Needs:** KNG-95 for put/take resolution.

**Tests:** canonical container keys (double chests); terminal take/put under lag and retry; display refresh
throttling.

## P7 — Item delivery, reward inbox, deposit/withdraw · [KNG-90](https://linear.app/kngpandi/issue/KNG-90)

**API:** `IItemDeliveryService`, player Inbox and Stash storages, claim and expiry, deposit/withdraw endpoints.

**Plugin:** `/inbox` and an inbox menu; migrate `KitGrantPlacer` and `LootboxDelivery` from dropping at the
player's feet to the delivery service.

**Tests:** offline, full-inventory and in-minigame deliveries land in the inbox; claim with partial space;
`StockUnit` rewards keep their enchantments; retries don't duplicate.

## P8 — Player harvesting and block regeneration · [KNG-97](https://linear.app/kngpandi/issue/KNG-97)

**API:** `HarvestRule` per kind; `ResourcePool` per area; a harvest report endpoint (idempotent, batched); the pool
multiplier in settle.

**Plugin:**

- the harvest listener in `RESOURCE_PRODUCTION` regions (replaces the KNG-48 config switch);
- `IRequirementEvaluator` (permission and title now);
- blueprint drops through KNG-95;
- a disk-persisted regeneration queue with placeholders and tree snapshots.

**Tests:** allowed vs denied breaks; pool math; regeneration across restart and chunk unload; surveys counting
pending regenerations.

## P9 — Town logistics · [KNG-98](https://linear.app/kngpandi/issue/KNG-98)

**Needs:** the developer's review of TOWN_LOGISTICS §4.

**API:**

- service areas;
- consumer replenishment settings;
- `LogisticsPolicy`/`LogisticsRule` (versioned);
- `LogisticsPlanner` (interval plus dry run) creating Distribution and Rebalance orders with explanations;
- default policy templates.

**Web app:** policy and rule editor, planner dry-run view, town supply view.

**Tests:** reserves never breached; priority under scarcity; quotas; rebalance; emergency modes; explanation
content.

## Web-app insight · [KNG-89](https://linear.app/kngpandi/issue/KNG-89)

The logistics dashboard, simulator, health view and order map. These grow alongside P3-P9.

---

## Later (own designs)

- [KNG-99](https://linear.app/kngpandi/issue/KNG-99): physical transport (NPC caravans, couriers, robbery, escort,
  risk, quests). After KNG-36.
- [KNG-100](https://linear.app/kngpandi/issue/KNG-100): inter-town trade and town treasury accounts.
- [KNG-101](https://linear.app/kngpandi/issue/KNG-101): pricing. **Needs the developer's pricing documents first.**
- [KNG-102](https://linear.app/kngpandi/issue/KNG-102): Backed container sync for housing.
- [KNG-91](https://linear.app/kngpandi/issue/KNG-91): processing chains, shops with levels, ownership and payouts.

## Smoke test outline (after P5 + P6)

1. In the web app:
   - create Territory "Cinix North" claimed by Cinix;
   - create the Docks Warehouse (district) with a terminal chest and a display chest;
   - create a Coal Mine (district) and a Logger in the territory, with a radius over a forest.
2. Survey the logger (`/knk production survey`). Check the composition and the derived rates in the web app.
3. `/knk logistics lanes measure`. The logger shows `Connected`, or `Unconnected` with a held transport warning.
4. Set the mine's rate high and watch the cycle trace. At 25% occupancy, an automatic order is planned. It departs;
   stock leaves the mine at departure, sits in transit, and arrives at the ETA. The display chest fills.
5. Lower the warehouse cap: AwaitingSpace → Returning → Returned. The ledger reconciles.
6. Restart the API mid-transit: the order resumes.
7. Take coal from the terminal chest. Your inventory gets blueprint-tagged coal, and the ledger shows a `SYS_WORLD`
   move.
