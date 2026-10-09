# Production, storage and transport — Implementation plan

**Status:** Draft. No phase has started. The design decisions D1-D13 ([DESIGN.md §12](DESIGN.md#12-decisions)) have
recommended defaults. Phases 1-2 can start on those defaults; D1 must be confirmed before Phase 2's migration.
**Last updated:** 2026-10-09
**Design:** [DESIGN.md](DESIGN.md) · **Evidence:** [V2 scan](../../reports/2026-10-09-v2-production-storage-transport-scan.md)
**Linear:** parent [KNG-83](https://linear.app/kngpandi/issue/KNG-83); phases listed per section.
**Branches (when work starts):** one standing branch per repo, `claude/production-storage-transport`, cut from
each repo's current default branch (`master` for knk-web-api, `main` for the others). Follow the board rules in
[ACTIVE_SESSIONS.md](../../ACTIVE_SESSIONS.md).

## Order and dependencies

```
P1 Storage core (API) ──► P2 Structure subtypes (API, D1) ──► P3 Production lines (API)
        │                          │                                   │
        │                          └──────────────► P4 Transport orders + lanes (API, plugin lane measure)
        │                                                              │
        └──► P7 Deposit/withdraw (API + plugin, D13)    P5 Plugin views/commands ◄─┘   P6 Web-app admin ◄─ P2..P4
```

P5 and P6 can start as soon as the API endpoints they read exist; they don't need all of P4. Later phases (L1-L3)
get their own designs.

Each phase ends with: `dotnet test` (API), `npm run test:ci` + build (web app), `./gradlew build -x deployToDevServer`
(plugin), a short smoke list for the developer, and doc updates (this plan's status lines, the feature register
rows, `CHANGELOG.md` on merge).

---

## P1 — Storage core (knk-web-api) · [KNG-84](https://linear.app/kngpandi/issue/KNG-84)

**Builds:** `Storage`, `StorageItem`, `StorageMovement`; `Structure.DeliveryStorageId` and the `Storages` navigation;
`IStorageService` (§5); admin endpoints for storages, items, adjust and movements; a reconciler.

- Models: `Models/Storage.cs`, `Models/StorageItem.cs`, `Models/StorageMovement.cs`, enums
  `StoragePurpose` and `StorageMovementReason` in `Enums/`. `KnKDbContext` configuration:
  - the check constraint "exactly one of StructureId/UserId";
  - `Amount > 0`;
  - `ItemBlueprint` FK **Restrict**;
  - unique `IdempotencyKey`;
  - index `(StorageId, CreatedAt)`.
- Migration `AddStorageCore`.
- `Services/Economy/StorageService.cs`: conditional updates under a `SELECT … FOR UPDATE` row lock on `storages`,
  `TryAdd`/`TryRemove`/`Transfer` with partial mode, and movement rows in the same transaction. It runs inside a
  caller's transaction when one is open, as the currency service does ([currency DESIGN](../currency-payments/DESIGN.md), "call `ICurrencyService` inside your own transaction").
- `Services/Economy/StorageReconciler.cs`: Σ movements = amounts; `TotalAmount`/`DistinctItems` = row aggregates.
- `Controllers/StoragesController.cs`: CRUD (FormConfigurable), `GET {id}/items`, `POST {id}/adjust`,
  `GET {id}/movements` (paged). Admin permission `knk.economy.admin` (new node, added to the permission seed).
- **Tests** (`Tests/knkwebapi_v2.Tests/Services/Economy/`):
  - caps: distinct, total, an over-cap storage after lowering a cap;
  - partial vs all-or-nothing;
  - removal of more than stock;
  - idempotency-key replay;
  - concurrent adds: two tasks, MySQL `requires-mysql` category, asserting no lost update;
  - reconciler;
  - FK restrict on blueprint delete.
- **Acceptance:** an admin can create a storage on any Structure, adjust stock, see the ledger, and cannot exceed
  caps. Concurrent adjustments never lose an update.

## P2 — Warehouse and ProductionStructure subtypes (knk-web-api, small plugin change) · [KNG-85](https://linear.app/kngpandi/issue/KNG-85)

**Needs:** D1 confirmed (nullable `DistrictId` + `RulingTownId`), D11, D12.

- Models: `Models/Warehouse.cs`, `Models/ProductionStructure.cs` (TPT, like `GateStructure`), with the
  `IProductionSite` interface; `Structure.RulingTownId`; `DistrictId` nullable with the validator "District or
  RulingTown". The migration keeps all existing rows valid (all have a District today).
- Services and controllers `WarehousesController`, `ProductionStructuresController`. Create creates the default
  storage and sets `DeliveryStorageId` (Warehouse) or the Output storage (ProductionStructure).
  `ProductionSettings` defaults (240/1, 2,600/12) in `appsettings`.
- Check every place that dereferences `Structure.District` (navigation destinations, discovery, managed regions,
  domain access) and handle `null` → `RulingTown`. List the call sites in the PR.
- FormConfigurations for both subtypes, reusing the Structure create flow with WorldTask location and region
  capture.
- knk-plugin: `ManagedRegionKind.fromDomainType` maps `ProductionStructure` → `RESOURCE_PRODUCTION`
  and `Warehouse` → `STRUCTURE`. Add a test in `ManagedRegionPolicyTest`. Coordinate with
  [KNG-47](https://linear.app/kngpandi/issue/KNG-47).
- **Tests:** create flows; the district-or-town validator; effective-town resolution; the managed-region kind
  mapping.
- **Acceptance:** an admin creates a warehouse and a production structure (also one in the wilderness with a
  ruling town) from the web app. Each gets its default storage. The region gets the right managed kind on startup
  repair.

## P3 — Production lines (knk-web-api) · [KNG-86](https://linear.app/kngpandi/issue/KNG-86)

- Models: `ProductionLine`, `ProductionLineInput`, `ProductionLineStatus`. Index `(Enabled, NextCycleAt)`.
  Migration `AddProductionLines`.
- `Services/Economy/ProductionService.cs`: `SettleLineAsync`, `SettleStructureAsync` (DESIGN §6.1: anchor
  cycles, whole cycles only, inputs, catch-up cap D5, full behavior D4).
- `Services/Economy/ProductionSweepService.cs`, a `BackgroundService` modelled on `RankExpirySweepService`:
  interval from `Economy:Production:SweepInterval`, batched due query.
- Lazy settle in `GET` endpoints for structures, storages and lines. `POST api/ProductionLines/{id}/run-now`.
- Notifications: `ProductionBlocked`/`ProductionResumed` to the player-notification queue for users who watch
  logistics (a watcher list in the API, toggled by `/knk logistics watch`; see P5).
- **Tests:** drift-free anchors over simulated clocks (inject a clock); catch-up cap; full storage per D4; inputs
  partially available; disabled structure; concurrency with a P1 adjust on the same storage; a 10k-line sweep
  query plan uses the index.
- **Acceptance:** seeded "Coal Mine" (coal 8 per hour, storage 240/1) and "Stone Quarry" (stone 12/h + iron 2/h,
  680/4), the V2 seeds, produce on time across an API restart. They show `BlockedFull` when full and resume when
  space frees.

## P4 — Transport orders and lanes (knk-web-api + knk-plugin) · [KNG-87](https://linear.app/kngpandi/issue/KNG-87)

- Models: `TransportOrder`, `TransportOrderStop`, `TransportOrderItem`, `TransportLane`, status enums. A filtered
  unique index keeps one open automatic order per source. Migration `AddTransportOrders`.
- `Services/Economy/TransportService.cs`:
  - the trigger (§6.2) called from production settle;
  - sizing (stock-based allocation of `TransportCapacity`);
  - destination choice (§6.4);
  - lifecycle steps Load / Deliver / Return (§6.3), each one transaction;
  - manual orders with a dry run;
  - cancel.
- `Services/Economy/TransportSweepService.cs` (`BackgroundService`): advances orders whose `ExecuteAfter`,
  `ArrivesAt` or retry time is due.
- `Controllers/TransportOrdersController.cs`, `Controllers/TransportLanesController.cs` (plugin key for
  lanes). The API marks lanes unmeasured when a structure's Location changes, or when a warehouse or production
  structure is created or deleted (pairs within the same effective town).
- knk-plugin: `knk-api-client` lane DTOs and port. A lane measurer uses `AStarRouter` over the current
  `RoadNetworkSnapshot` between Locations and posts the road length. It runs as `/knk logistics lanes measure` and as
  a periodic low-priority headless job (pattern `HeadlessWorldTaskPoller`). Without a route it posts `Straight`.
- **Tests (API):**
  - threshold by occupancy;
  - blocked trigger;
  - distinct-cap trigger;
  - no destination warns;
  - preferred falls back to nearest;
  - sizing with mixed stock;
  - load partial stock;
  - in-transit invisibility in both storages;
  - deliver overflow → AwaitingSpace → re-route → Returning → Returned;
  - ReturnBlocked;
  - cancel in each state;
  - one-open-order index;
  - the ledger reconciles after every path, including chaos tests that kill the transaction mid-way.
- **Tests (plugin):** lane measurer on a fixture road snapshot.
- **Acceptance:** with the two seeds and a Docks Warehouse (2,600/12), automatic orders are created at 25%
  occupancy. They show ETA from road distance, arrive, and never lose or duplicate items in any overflow scenario.

## P5 — Plugin views, commands and notifications (knk-plugin) · [KNG-88](https://linear.app/kngpandi/issue/KNG-88)

- `knk-api-client`: DTOs and ports for storages, lines, orders and the logistics summary. Cache-first reads with a
  short TTL. Mutations go direct and run async.
- Commands (DESIGN §8.3) under `/knk storage|production|transport|logistics`, with permission-filtered completion
  (KNG-30 conventions) and documentation in the command catalog.
- Menu features in `paper/menu/content/`:
  - `LogisticsMenuFeature` (structure logistics, storage contents with paging, transport orders);
  - menu templates seeded in the API like the other menu definitions;
  - stepper adjust and deposit wait for menu-engine gaps G3 and G2.
- `/knk logistics watch on|off` toggles the API watcher list. Notifications arrive through `PlayerNotificationPoller`.
- Bukkit events `ProductionCycleEvent`, `TransportOrderStatusEvent` (fired from notification handling; no I/O in
  listeners).
- **Tests:** command parsing and completion; menu row mapping; notification formatting.
- **Acceptance:** staff can inspect any structure's production, stock and orders in game, run a dry run, cancel an
  order, and receive watch notifications.

## P6 — Web-app admin (knk-web-app) · [KNG-89](https://linear.app/kngpandi/issue/KNG-89)

- API clients in `src/apiClients/` (`storageClient.ts`, `productionClient.ts`, `transportClient.ts`,
  `logisticsClient.ts`) on `objectManager.ts`; types in `src/types/dtos/`.
- FormConfigurations (seeded by the API) for Warehouse, ProductionStructure (+ first line), Storage,
  ProductionLine (+ inputs).
- Pages in `src/pages/admin/`:
  - **Logistics dashboard:** per town, warehouses with fill bars, producers with line states, an open-orders
    timeline with ETA, and warnings;
  - **Storage detail:** contents, adjust dialog, movement ledger with filters.
- **Tests:** client tests; dashboard rendering with fixture data.
- **Acceptance:** an admin can set up the whole chain from the web app and follow it on the dashboard.

## P7 — Admin deposit and withdraw (knk-web-api + knk-plugin) · [KNG-90](https://linear.app/kngpandi/issue/KNG-90)

**Needs:** D10, D13.

- API: `POST api/Storages/{id}/deposit` and `/withdraw` (plugin key + acting user + permission, idempotency
  keys). `ItemBlueprint.VanillaMaterialMatch` (unique nullable Material ref) with migration and a seed for the
  "Resources" category (Coal, Cobblestone, Oak/Spruce log, Wheat, …; see the items V1 seed).
- Plugin:
  - `BlueprintItemAssembler` stamps `knightsandkings:knk_blueprint` on stackables;
  - a resolver: instance tag → blueprint tag → vanilla match;
  - `/knk storage deposit <storage>` (hand or hotbar) and `/knk storage withdraw …`;
  - withdraw builds items through `BlueprintItemAssembler`, minting non-stackables through the API's instance
    service;
  - returns overflow to storage (D10).
- **Tests:**
  - resolver order;
  - an assembler stamp that does not break stacking with older un-tagged stacks: decide a one-time "retag on
    deposit/withdraw" rule and test it;
  - idempotent retries;
  - partial acceptance returns the rest to the player.
- **Acceptance:** staff can move real items between their inventory and any storage without duplication on a lag
  spike or retry.

---

## Later (own designs, not scheduled) · [KNG-91](https://linear.app/kngpandi/issue/KNG-91)

- **L1 Consumption chains and supply orders:** input lines at workshops; warehouse → input-storage orders on a
  refill threshold (DESIGN §10.1).
- **L2 Shops on warehouse supply:** with the shops/property design, currency reasons and town accounts (§10.2-10.3).
- **L3 Physical transport and risk:** NPC carrier or cart on the road route for in-transit orders, escort and raid
  gameplay, a courier-quest port of V1 `Minigames/Transport.java`. Depends on KNG-36 (§10.4).

## Smoke test outline (for the developer, after P4/P5)

1. Create the Docks Warehouse in Cinix, a Coal Mine (in a district) and a wilderness Stone Quarry with ruling
   town Cinix.
2. `/knk logistics lanes measure`. Check road vs straight distances in `/knk transport dryrun <quarry>`.
3. Set coal to 1 cycle per 60 s (`CycleSeconds` = 60) and watch with `/knk logistics watch on`.
4. At 25% occupancy, an order is planned with `ExecuteAfter` +5 min. It departs, and its ETA matches distance /
   speed. Stock leaves the mine at departure and appears in the warehouse at arrival.
5. Lower the warehouse cap below the incoming cargo: the order goes `AwaitingSpace`, then `Returning`, then
   `Returned`. Coal totals across both storages plus the ledger match.
6. Restart the API mid-transit. The order resumes and arrives at the original ETA (or immediately if overdue).
