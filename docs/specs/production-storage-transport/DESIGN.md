# Production, storage and transport — Design

**Status:** Draft for developer review. It ports the V2 concept with targeted fixes. The decisions marked
**[DECIDE]** in §12 are open. Nothing is implemented.
**Last updated:** 2026-10-09
**Implementation plan:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
**Evidence:** [reports/2026-10-09-v2-production-storage-transport-scan.md](../../reports/2026-10-09-v2-production-storage-transport-scan.md)
(V2 code on all branches, vision, V1). Section numbers below that start with "scan" refer to that report.
**Linear:** parent issue and phase issues are listed in the implementation plan header.
**Related:** [KNG-47](https://linear.app/kngpandi/issue/KNG-47) (Structure subtypes),
[KNG-48](https://linear.app/kngpandi/issue/KNG-48) (resource-production block-break rule),
[KNG-36](https://linear.app/kngpandi/issue/KNG-36) (NPC platform: physical caravans later),
[navigation](../navigation/DESIGN.md) (road distances), [currency](../currency-payments/DESIGN.md) (later payouts),
[items](../items/IMPLEMENTATION_PLAN.md) (`ItemBlueprint` as the commodity).

## 1. Goal and scope

The goal is a resource economy backbone. Production structures produce resources over time into their own storage.
When that storage fills, the resources are transported automatically to a town warehouse. Later phases add
consumption: structures that turn inputs into goods, and shops that sell goods supplied from warehouses.

V2 built this as a concept (scan §1-§5). Its shapes carry over almost unchanged. The changes are about where the
logic runs, about correctness, and about making transport take time.

**In scope (this design, phases 1-5):**

1. Storages with counted item stock, two caps and an append-only movement ledger.
2. `Warehouse` and `ProductionStructure` as `Structure` subtypes.
3. Production lines: timed yield into a storage, with optional inputs (V2 `Generation` + `Production`).
4. Automatic and manual transport orders from production to a warehouse, with travel time and a visible in-transit
   state.
5. Admin tooling: web-app CRUD and a logistics dashboard, plugin commands, read-only in-game menus, staff
   notifications.
6. Admin deposit/withdraw of physical items into and out of a storage.

**Designed only as hooks (later phases, own designs):**

- shops buying from warehouses;
- ownership and income payouts (vision §4.5 is open);
- warehouse distribution percentages and clan councils (concept L168);
- inter-town trade agreements;
- physical caravans with escort and raids ([KNG-36](https://linear.app/kngpandi/issue/KNG-36), iPhone notes L163, L268, L297);
- territory `resourceYield` (vision §2.3);
- the technology tree (vision §4.3).

**Out of scope:** player gathering rules inside resource regions. That is
[KNG-48](https://linear.app/kngpandi/issue/KNG-48) and the V1 resource-property mining port. It touches the same
structures but not the stock model.

## 2. Principles

1. **The API owns all stock.** Every quantity change is a single database transaction in knk-web-api: production,
   pickup, delivery, deposit, withdraw and admin adjustment. The plugin never computes stock. It asks the API and
   renders the answer. This mirrors the currency ledger rules ([currency DESIGN](../currency-payments/DESIGN.md)
   §3: server authority, append-only ledger, idempotency).
2. **No item is created or destroyed by accident.** A move is either complete or does not happen. Overflow is
   returned, held or retried, never dropped. This is the inverse of V2 defects 2-4 (scan §7).
3. **Due-time scheduling, not polling everything.** Work is selected by an indexed `Next…At <= now` column.
   Production anchors advance by whole cycles, never "now".
4. **Keep the V2 shape** (names, fields, flows) unless a fix needs a change, so the developer recognises the system.
   §3 lists every change.
5. **Simulated first, physical later.** Transport is an abstract timed order. A visible NPC or cart can later drive
   the same order state machine without changing the stock rules.

## 3. V2 → V3 concept map

| V2 concept | V3 | Change |
|---|---|---|
| `Storage` (structure **or** user owner, `itemAmountMax`, `capacityMax`, `Map<Item,int>`) | `Storage` + `StorageItem` rows | **Keep.** Owner stays Structure-or-User (User storage is for the later personal stash, vision §9.1). Caps renamed `MaxDistinctItems`/`MaxTotalAmount`. Adds `Purpose` (below) and a `RowVersion`. |
| — | `StorageMovement` (ledger) | **New.** Append-only record of every change (reason, amount, balance after, actor, reference). |
| `Structure.storages`, `Structure.deliveryStorage` | Same, on `Structure` | **Keep.** `DeliveryStorageId` is nullable, with a fallback to the first `Delivery`/`General` storage. |
| `Structure.town` (revived "ruling town" for wilderness) | `Structure.RulingTownId` | **Keep the idea.** Nullable. Needed for wilderness producers; see D1. |
| `Warehouse extends Structure` (no fields) | `Warehouse : Structure` (TPT) | **Keep.** Adds `AcceptsDeliveries` (bool) and `Priority` (tie-break). |
| `ProductionStructure extends Structure implements IProducer` | `ProductionStructure : Structure` | **Keep.** The fields carry over (below). `override` + `autostart` collapse into one `ProductionEnabled`. `automaticalTransport` is kept as `AutomaticTransport` and is **actually read**. |
| `WarehousePreference` NEAREST / PREFERRED / CUSTOM | Same enum | **Keep.** `CUSTOM` = an explicit ordered stop list (later phase). Until then it is rejected on save, not silently treated as NEAREST. |
| `nearestWarehouse` (cached, never invalidated) | Computed per order from `TransportLane` | **Change** (V2 defect 9). |
| `transportThreshold` (% of max, per commodity) | `TransportThresholdPercent` (% of **total occupancy**) + distinct-cap trigger | **Change** (V2 defect 7). |
| `IProducer` / `IProducable` interfaces | C# interface `IProductionSite` on the entity | **Keep the idea** (vision §2.5 "can be produced from" as an interface). Only `ProductionStructure` implements it now. A Shop with a workshop can later implement it too. |
| `Generation` (`yieldPerDelivery`, `deliveryPeriodVal` × Calendar unit, `lastDeliveryDate`, `autoStart`, `generating`, `deliveryType`, `exceptions`, `storage`) | `ProductionLine` | **Keep, renamed** (one class instead of two). `CycleSeconds` (int) replaces the period double + unit constant. `NextCycleAt` + `LastCycleAt` replace `lastDeliveryDate`. `Enabled` replaces `autoStart`/`generating`. `Status` + `LastError` replace the `exceptions` map. `OutputStorageId` stays. |
| `Production.requirements` (`Map<Item,int>` per 1 output) | `ProductionLineInput` rows (per **cycle**) + `InputStorageId` | **Keep**, and V3 **enforces** them (V2 never did). Per cycle, not per item, to avoid fractional inputs. |
| `GenerationDeliveryType` PUT_IN_STORAGE / SPAWN_ON_GROUND | Storage only | **Drop** ground drops (needs loaded chunks and dupes on retry). Recorded as a possible later "visible output" decoration. |
| `@Any` commodity (Item/Structure/Warehouse) | `ItemBlueprintId` FK | **Change.** Only Item was ever used. Non-item commodities (soldiers, coins) get their own typed line kinds if they come. |
| `TransportOrder` (one open per producer, `executionStyle`, `executionDate`, `executed`, `simulatedTravelTime`, `waitingTimePickup`) | `TransportOrder` with a `Status` state machine | **Keep, extended.** `ExecuteAfter` (=`executionDate`), `DepartedAt`, `ArrivesAt`, `CompletedAt`. Travel time is **applied** (V2 defect 11). |
| `TransportOrderItem` (`amount`, `amountReceived`, `amountDelivered`, source storage, generation, order) | Same | **Keep.** Renamed `RequestedAmount`/`LoadedAmount`/`DeliveredAmount`, plus `ReturnedAmount`. |
| `TransportRouteNode` (ordered destinations) | `TransportOrderStop` | **Keep the table.** Phase 4 allows **one** delivery stop. Multi-stop needs explicit per-stop amounts (fixes V2 defect 3) and comes with `CUSTOM`. |
| `TRANSPORT_CAPACITY_MAX = 128`, split evenly per generation | `ProductionStructure.TransportCapacity` (default 128), allocated by stock | **Change** (V2 defect 8). |
| `GenerationHandler`/`TransportHandler` (Bukkit async timers, 120 s) | API `BackgroundService`s | **Move** to the API (precedent: `RankExpirySweepService`). |
| `GenerationCommandEvent` + `GenerationCommandListener` | API domain events → plugin notification + Bukkit event | **Keep the event idea.** Plugin-side `ProductionCycleEvent`/`TransportOrderEvent` for other plugin features. No DB work in listeners. |
| `/generation updates sub` | `/knk logistics watch` (staff) | **Keep**, over the existing player-notification queue. |
| `/storage list\|fetch\|save\|remove\|edit` | Web-app CRUD + `/knk storage …` | **Adapt.** Creation and editing move to the web app (V3 convention). In-game is for viewing, adjusting and testing. |
| `/test transportpreperation` | `/knk transport dryrun <structure>` | **Keep** as an admin dry run (no undo dance). |
| Command pattern with `unExecute` | Database transactions | **Drop** as a persistence strategy. A transaction gives the all-or-nothing V2 tried to get from undo. |
| Storage menus (`StorageOverview`, `StorageAddMenu` steppers, `ProductionStructureMenu`) | Menu-engine screens (§8.2) | **Keep the layout ideas.** Steppers need menu-engine gap G3. |
| Chest-scanning warehouse (main) | — | **Dropped** (the developer already dropped it in 2021, scan §3.1). |

## 4. Data model (knk-web-api)

Names follow the API's conventions (`Models/`, TPT for `Domain` subtypes as in `GateStructure`,
`[FormConfigurableEntity]` for admin CRUD, `[RelatedEntityField]`/`[NavigationPair]` for FKs). Times are UTC
`DateTime`. Amounts are `int`, except the ledger (`long` ids).

### 4.1 Structure additions (`Models/Structure.cs`)

| Field | Type | Notes |
|---|---|---|
| `RulingTownId` | `int?` FK Town (SetNull) | The town a structure answers to when it has no District (wilderness producer). Effective town = `District.Town ?? RulingTown`. See D1. |
| `DeliveryStorageId` | `int?` FK Storage (SetNull) | Where incoming transports are put. |
| `Storages` | nav, 1-n | `Storage.StructureId`. |

### 4.2 `Warehouse : Structure` (new table `warehouses`)

| Field | Default | Notes |
|---|---|---|
| `AcceptsDeliveries` | true | Admin switch to take a warehouse out of the destination pool (renovation, siege). |
| `Priority` | 0 | Tie-break when lanes are equally short; also the order for future distribution. |

On creation the service creates its default storage (`Purpose = Delivery`) and sets `DeliveryStorageId`. Defaults
come from `ProductionSettings`: 2,600 total / 12 distinct (V2 seed values).

### 4.3 `ProductionStructure : Structure` (new table `production_structures`), implements `IProductionSite`

| Field | Default | V2 origin |
|---|---|---|
| `ProductionEnabled` | true | `override` + `autostart` |
| `AutomaticTransport` | true | `automaticalTransport` |
| `TransportThresholdPercent` | 25 | `transportThreshold` |
| `TransportCapacity` | 128 | `TRANSPORT_CAPACITY_MAX` |
| `WarehousePreference` | `Nearest` | same |
| `PreferredWarehouseId` | null | `preferredWarehouse` |
| `ProductionKind` | null (string) | **New, optional**: catalogue label (`Lumberyard`, `Mine`, `Quarry`, `Farm`, `FishingDocks`, concept L158). Display and filtering only; behavior comes from the lines. |
| `ProductionLines` | nav 1-n | `producerObjects` |

On creation the service creates the output storage (`Purpose = Output`; defaults 240 / 1, from V2) and, when the form
supplies an output blueprint and yield, one line. That is the V2 `createInstance` behavior.

### 4.4 `Storage` (`storages`) and `StorageItem` (`storage_items`)

`Storage`:

| Field | Type | Notes |
|---|---|---|
| `Id` | int | |
| `Name` | string | default "Storage" |
| `StructureId` | int? | Exactly one of `StructureId`/`UserId` is set (check constraint). |
| `UserId` | int? | Reserved for the personal stash; no flows in this design. |
| `Purpose` | enum `General`, `Output`, `Input`, `Delivery`, `Merchandise` | V2's javadoc example ("a Storage for upgrade resources and another for other items"; shops need "a resource-storage and a merchandise storage", commit `f2aa2e2`). |
| `MaxDistinctItems` | int | V2 `itemAmountMax` |
| `MaxTotalAmount` | int | V2 `capacityMax`; see D3 for stack weighting. |
| `TotalAmount` | int | **Stored** running total (V2 recomputed it in memory). Kept in step with the rows in the same transaction. |
| `DistinctItems` | int | stored, same reason |
| `RowVersion` | concurrency token | Optimistic check for cap-edits vs. moves. |

`StorageItem`: `(StorageId, ItemBlueprintId)` PK, `Amount` (int, `> 0`; a row is deleted at 0). `ItemBlueprint` FK
is **Restrict**, never cascade (vision §9.2 rule: nothing that references shared item rows may cascade-delete them).

### 4.5 `StorageMovement` (`storage_movements`, append-only)

| Field | Notes |
|---|---|
| `Id` (long), `CreatedAt` | |
| `StorageId`, `ItemBlueprintId`, `Delta` (signed), `AmountAfter` | Reconciliation: Σ deltas = current amount per pair (as `CurrencyReconciler`). |
| `Reason` | `Production`, `ProductionInput`, `TransportLoad`, `TransportDeliver`, `TransportReturn`, `Deposit`, `Withdraw`, `AdminAdjust`, `CapacityTrim`. |
| `ProductionLineId?`, `TransportOrderId?`, `ActorUserId?` | References. |
| `IdempotencyKey` | Unique when set. Plugin-initiated deposit/withdraw sends one, so retries don't double. |

Retention follows `RetentionPolicyService` patterns: production rows can be rolled up daily after N days (D9).

### 4.6 `ProductionLine` (`production_lines`) and `ProductionLineInput` (`production_line_inputs`)

`ProductionLine`:

| Field | Default | Notes |
|---|---|---|
| `ProductionStructureId` | — | V2 `producerDominion` |
| `Name` | blueprint name | |
| `OutputBlueprintId` | — | V2 `commodity` |
| `YieldPerCycle` | 1, ≥1 | V2 `yieldPerDelivery` |
| `CycleSeconds` | 3600, ≥60 | V2 `deliveryPeriodVal` × `timeVal` |
| `OutputStorageId` | the structure's Output storage | V2 `storage` |
| `InputStorageId` | null | Required when inputs exist. |
| `Enabled` | true | V2 `autoStart`/`generating` |
| `Status` | `Running` | `Running`, `Paused` (disabled, or structure disabled), `BlockedFull` (no room), `BlockedInputs` (inputs missing), `Error`. |
| `LastCycleAt`, `NextCycleAt` | | Indexed `NextCycleAt` (where Enabled). |
| `LastError` | null | Replaces the V2 `exceptions` map. History is in the movement ledger and logs. |
| `TotalProduced` | 0 | Running counter for the dashboard. |

`ProductionLineInput`: `(ProductionLineId, ItemBlueprintId)` PK, `AmountPerCycle` (≥1).

### 4.7 Transport

**`TransportOrder`** (`transport_orders`):

| Field | Notes |
|---|---|
| `Id`, `Name` | |
| `SourceStructureId` | V2 `structure` (sender). |
| `Origin` | `Automatic`, `Manual`, `Quest` (later). |
| `Status` | §6.3 state machine. |
| `ExecuteAfter` | V2 `executionDate`. Automatic orders: now + `ProductionSettings.AutoOrderDelay` (default 5 min, the V2 value). `IMMEDIATELY` = now. |
| `LoadSeconds` | V2 `waitingTimePickup`. |
| `TravelSeconds` | Computed at departure from the lane (§6.4). V2 `simulatedTravelTime`. |
| `DepartedAt`, `ArrivesAt`, `CompletedAt` | |
| `LastError` | |
| `CreatedByUserId?` | For manual orders. |

**`TransportOrderStop`** (`transport_order_stops`): `TransportOrderId`, `Sequence`, `StructureId` (destination),
`StorageId` (resolved delivery storage at planning time). Phase 4 allows one stop.

**`TransportOrderItem`** (`transport_order_items`): `TransportOrderId`, `Sequence`, `ItemBlueprintId`,
`SourceStorageId`, `ProductionLineId?`, `RequestedAmount`, `LoadedAmount`, `DeliveredAmount`, `ReturnedAmount`.
Invariant once settled: `LoadedAmount = DeliveredAmount + ReturnedAmount + InTransit`, and `InTransit` is 0 when the
order is final.

At most one **open** (not final) automatic order per source structure: a filtered unique index. This is the V2
`@OneToOne transportOrder`.

**`TransportLane`** (`transport_lanes`): `(FromStructureId, ToStructureId)` PK, `RoadDistance` (double, blocks, null
if unmeasured), `StraightDistance`, `MeasuredAt`, `Source` (`Road`, `Straight`). Lanes are recomputed when either
end's Location changes, and on demand (§8.3).

### 4.8 Settings (`ProductionSettings`, appsettings `Economy:Production`)

Sweep interval (60 s); max catch-up cycles (24); auto-order delay (5 min); load seconds (5); carrier speed
(blocks/s, default 4: walking pace with a cart; [DECIDE] D7); straight-line detour factor when no road distance
(1.4); default storage caps per purpose.

## 5. Stock rules (`IStorageService`)

All stock changes go through one service. Each call is one transaction and returns what happened. Capacity is a
normal result, not an exception (V2 defect 14).

```
StorageChangeResult TryAddAsync(storageId, blueprintId, amount, reason, refs, allowPartial)
StorageChangeResult TryRemoveAsync(storageId, blueprintId, amount, reason, refs, allowPartial)
TransferResult      TransferAsync(fromStorageId, toStorageId, blueprintId, amount, reason, refs, allowPartial)
// result: Accepted (int), Rejected (int), RejectReason (None | DistinctCapReached | CapacityFull | NotEnoughStock | ...)
```

- **Atomicity.** Use conditional SQL, not read-modify-write. Example for an add:
  `UPDATE storages SET TotalAmount = TotalAmount + @n … WHERE Id = @id AND TotalAmount + @n <= MaxTotalAmount`.
  Then upsert the item row with `Amount = Amount + @n`. Then insert the movement. For partial adds, compute
  `n = min(requested, free)` inside the same statement or under a row lock (`SELECT … FOR UPDATE` on the storage
  row, MySQL). Concurrent producers, transports and menu edits then cannot overwrite each other (V2 defect 4).
- **Distinct cap.** Adding a blueprint not yet present, when `DistinctItems = MaxDistinctItems`, accepts 0 with
  `DistinctCapReached`. It never loops (V2 defect 1).
- **Cap edits.** Lowering a cap below current stock is allowed. The storage is then over cap: no adds, removals
  only. Nothing is trimmed silently. `CapacityTrim` exists only for an explicit admin trim.
- **Deletion.** A storage with stock cannot be deleted (409) unless an admin chooses "move to" another storage or
  "discard" (`AdminAdjust` with a note).

## 6. Flows

### 6.1 Production cycle (`ProductionSweepService`, API `BackgroundService`)

Each sweep (default 60 s) runs in batches of N lines:

1. Select enabled lines with `NextCycleAt <= now` whose structure has `ProductionEnabled`, ordered by `NextCycleAt`.
2. For each line: `due = min(floor((now − LastCycleAt) / Cycle), MaxCatchUpCycles)`. Then in one transaction:
   1. If the line has inputs, `k = min(due, inputs available / AmountPerCycle)` for every input. If `k = 0`, set
      `BlockedInputs` and stop.
   2. Under the output storage's row lock, reduce to whole cycles that fit:
      `kDone = min(k, floor(free / YieldPerCycle))`, where `free` also respects the distinct cap. Then
      `TryAddAsync(output, YieldPerCycle × kDone)`. No partial cycle is ever written.
   3. Consume inputs for `kDone` cycles (`ProductionInput`).
   4. Advance `LastCycleAt += kDone × Cycle`. This is anchor-based, so there is no drift (V2 defect 5).
   5. If `kDone < due` because the output is full: set `BlockedFull` (D4 decides whether the anchor stops or
      catches up). Otherwise `Running`.
   6. `NextCycleAt = LastCycleAt + Cycle`. `TotalProduced += kDone × Yield`.
3. After the line commits, evaluate the transport trigger (§6.2) for its structure.
4. Emit domain events (`ProductionCycled`, `ProductionBlocked`, `ProductionResumed`) to the notification outbox (§8.4).

**Lazy settle.** `GET` endpoints for a structure, storage or line call `SettleAsync(structureId)` first. Viewers then
always see current stock, even between sweeps. The sweep is only the guarantee that nothing waits forever.

**Downtime.** After API downtime, the catch-up cap prevents an unlimited burst; D5 sets the cap. Production does
not depend on players, chunks or the game server being online (D8).

### 6.2 Automatic transport trigger

Evaluated after each production commit, and in each sweep for structures that are blocked full. A new automatic
order is planned when **all** of these hold:

- `ProductionStructure.AutomaticTransport` is on (V2 never checked this);
- there is no open order for this source;
- **occupancy** `TotalAmount / MaxTotalAmount ≥ TransportThresholdPercent`, **or** any line is `BlockedFull`,
  **or** `DistinctItems = MaxDistinctItems` and a line's blueprint is missing (fixes V2 defect 7);
- a destination exists (§6.4). If none exists, the structure gets a `NoDestination` warning and staff are notified.
  V2 failed silently here (defect 17).

**Order sizing** (fixes V2 defect 8): fill `TransportCapacity` from the source's Output storage, largest stock
first, with a minimum share per present blueprint, `ceil(capacity / distinct)` capped by stock. Unused capacity is
then redistributed to the remaining stock. Items whose blueprint the destination's distinct cap could never accept
are left out and noted on the order.

### 6.3 Transport order lifecycle (`TransportSweepService`, same host, its own interval)

```
Planned ──(ExecuteAfter ≤ now)──► Loading ──(load done)──► InTransit ──(ArrivesAt ≤ now)──► Delivering
   │                                 │                                                        │
   └──cancel──► Cancelled            └──nothing loaded──► Cancelled (reason Empty)            ├─► Delivered (all delivered)
                                                                                             ├─► AwaitingSpace (remainder held, retried)
                                                                                             └─► Returning ──(ArrivesAt)──► Returned / PartiallyDelivered
```

- **Loading** (one transaction): for each item, `TransferAsync(source → order cargo)`. It is modelled as
  `TryRemove(source, allowPartial)` plus `LoadedAmount += accepted`. The cargo lives **on the order**: in transit, it
  belongs to neither storage. That makes in-transit stock explicit and visible (V2 had no such state). Then
  `DepartedAt = now`, `ArrivesAt = now + LoadSeconds + TravelSeconds`. Status `InTransit`.
- **Delivering** (one transaction per stop): `TryAddAsync(stop.Storage, LoadedAmount − DeliveredAmount, allowPartial)`.
  `DeliveredAmount += accepted`.
  - If everything is delivered: `Delivered`.
  - If a remainder is left: `AwaitingSpace`. It is retried each sweep for up to `AwaitingSpaceRetries` (default 10)
    and also tries the next-nearest eligible warehouse (re-route). After that it goes `Returning`: the remainder
    travels back with the same lane time and is added to the source on arrival (`ReturnedAmount`).
  - If the source has no room on return either, the order stays `ReturnBlocked` with a staff alert.
  - **Nothing is ever dropped** (V2 defect 2).
- **Cancel** (admin) before `Loading`: just `Cancelled`. While `InTransit` or `AwaitingSpace`: switches to
  `Returning`.
- **Multi-stop** (later, with `CUSTOM`): each stop gets explicit per-item amounts at planning time, so the V2 "every
  stop gets everything" duplication cannot occur (V2 defect 3).

### 6.4 Destination choice

1. Candidate warehouses: `AcceptsDeliveries`, a delivery storage with any free space, and in the source's effective
   town (`District.Town ?? RulingTown`). Inter-town supply is a later trade-agreement feature.
2. `Preferred`: the preferred warehouse, if it is a candidate. Otherwise fall back to Nearest and warn.
3. `Nearest`: the lowest lane cost. Cost = `RoadDistance` if measured, else `StraightDistance × DetourFactor`. Ties
   break by `Priority`, then id. Computed per order from `transport_lanes` (an indexed read). There is no cached
   `nearestWarehouse` field to go stale (V2 defect 9).
4. `TravelSeconds = cost / CarrierSpeed`.

### 6.5 Manual orders

An admin (web app or `/knk transport create <source> [warehouse] [blueprint:amount …]`) creates an order with an
explicit destination and amounts. It goes through the same lifecycle. `Origin = Manual`. It is a dry-run preview
when `?dryRun=true`: this replaces `/test transportpreperation`.

### 6.6 Deposit and withdraw (admin first)

- **Deposit:** the plugin resolves each `ItemStack` in a deposit inventory to a blueprint. Today only
  non-stackable items carry an id (`knightsandkings:knk_item_instance`, `paper/mapper/ItemInstanceTag.java`).
  Stackable blueprint items and vanilla-gathered resources carry nothing. Resolution order (D13):
  1. an instance tag → its blueprint, and the instance is retired on deposit;
  2. a new `knightsandkings:knk_blueprint` tag, stamped by `BlueprintItemAssembler` on stackables (it stacks
     correctly because every item of a blueprint gets the same tag);
  3. a plain vanilla item with no custom name, lore or enchantments → the blueprint marked as that Material's
     vanilla resource (`ItemBlueprint.VanillaMaterialMatch`, unique per material).

  Anything else is refused and returned. It sends one request with an idempotency key. The API answers
  accepted/rejected per stack. The plugin removes exactly the accepted amounts from the player inventory and
  returns the rest.
- **Withdraw:** the API removes stock (`Withdraw`, idempotency key) and returns the stacks to hand out. The plugin
  builds them through `BlueprintItemAssembler`. Non-stackables are minted as `ItemInstance`s through the existing
  item-instance service. If the inventory is full, the plugin gives what fits and calls `Deposit` back with the same
  key family for the remainder, or drops it at the player's feet (D10).
- Player-facing deposit/withdraw waits on ownership (§10).

## 7. API surface (knk-web-api)

| Method | Route | Auth | Purpose |
|---|---|---|---|
| CRUD | `api/Warehouses`, `api/ProductionStructures` | admin permission (`knk.economy.admin`) | Structure subtypes; create also creates the default storage (and the first line). |
| CRUD | `api/Storages` | admin | Caps, name, purpose. Delete rules per §5. |
| GET | `api/Storages/{id}/items` | admin, or plugin key | Settled stock. |
| POST | `api/Storages/{id}/adjust` | admin | `AdminAdjust` with a note. |
| POST | `api/Storages/{id}/deposit`, `.../withdraw` | plugin key + acting user + permission | §6.6, idempotent. |
| GET | `api/Storages/{id}/movements?from&to&reason` | admin | Ledger, paged. |
| CRUD | `api/ProductionLines` (+ inputs) | admin | |
| POST | `api/ProductionLines/{id}/run-now` | admin | Settle immediately (testing). |
| GET/POST | `api/TransportOrders` (`?status&source&dryRun`), `{id}/cancel` | admin | |
| GET | `api/Logistics/summary` | admin | Dashboard aggregate: stock per structure, line states, open orders, warnings. |
| GET/PUT | `api/TransportLanes`, `POST api/TransportLanes/measure-requests` | plugin key | The plugin pulls lanes to measure and posts road distances (§8.3). |

Controllers follow the plain `api/[controller]` convention. Authorization uses the existing
`RequireServiceOrPermission` attribute family.

## 8. Plugin (knk-plugin)

### 8.1 API client and caching

`knk-api-client` gets DTOs and ports for storages, lines, orders and lanes. Read paths are cache-first with a short
TTL (stock changes every minute). All mutations are direct API calls, off the main thread. Results are applied on
the main thread (V2 defect 6).

### 8.2 Menus (menu engine, `paper/menu/content/`)

| Screen | Content | V2 source |
|---|---|---|
| Structure logistics | Header: structure, kind, town, storages. Rows: production lines with state and next cycle; open order with ETA. | `ProductionStructureMenu` |
| Storage contents | Paged grid of blueprint icons, amount as lore, stack count as item amount. Header: totals vs caps and a fill bar. | `StorageOverview(Section)` |
| Transport orders | Orders with status, items, ETA. Admin can cancel. | new |
| Admin adjust (later) | Stepper per blueprint (left/right ±step, shift = step ×2/÷2) and a confirm showing the "after" totals. | `StorageAddMenu`/`StorageAddItem` |

The stepper screen needs menu-engine gap **G3** (click-type actions), and deposit needs **G2** (deposit slots)
([inventory-menu-screens.md](../legacy/inventory-menu-screens.md) lines 109-111). Until those exist, adjust and
deposit are commands or web-app actions.

### 8.3 Commands (`/knk …`, permission-filtered, with tab completion per the KNG-30 conventions)

- `/knk storage show <structure|storageId>` · `adjust <storage> <blueprint> <±amount> [note]` ·
  `deposit <storage>` (hand or hotbar, admin) · `withdraw <storage> <blueprint> <amount>`
- `/knk production show <structure>` · `run <line>` · `pause|resume <line|structure>`
- `/knk transport list [status]` · `show <order>` · `create …` · `dryrun <structure>` · `cancel <order>`
- `/knk logistics watch on|off`: staff live feed (successor of `/generation updates`)
- `/knk logistics lanes measure [structure]`: computes road distances with `AStarRouter` over the road snapshot,
  from each producer's Location to each candidate warehouse's Location (same town), and posts them to
  `api/TransportLanes`. It also runs as a low-priority headless task after a structure's Location changes (lanes
  marked unmeasured by the API, polled like other headless world tasks).

### 8.4 Events and notifications

- The API writes logistics notifications (blocked lines, no destination, awaiting space, return blocked, order
  delivered) to the existing player-notification queue. Recipients are watchers and, later, owners.
  `PlayerNotificationPoller` delivers them. That replaces the V2 in-memory subscriber set (V2 defect 6).
- For other plugin features (quests, tutorial, future escorts), the plugin fires Bukkit events when it learns of
  state changes: `ProductionCycleEvent`, `TransportOrderStatusEvent`. Listeners must not do I/O on the main thread.

### 8.5 World hooks

- Region kind: a `ProductionStructure` region maps to `RESOURCE_PRODUCTION` and a `Warehouse` region to
  `STRUCTURE` in the managed-region policy (`ManagedRegionKind.fromDomainType`). That removes the per-region
  overrides ([KNG-47](https://linear.app/kngpandi/issue/KNG-47)).
- [KNG-48](https://linear.app/kngpandi/issue/KNG-48)'s allowed-block list naturally belongs on `ProductionStructure`
  (for example `AllowedBreakMaterials`), but it stays its own issue.

## 9. Web app (knk-web-app)

- **Form configurations** for `Warehouse`, `ProductionStructure` (with an inline "first production line" step),
  `Storage`, `ProductionLine` (+ inputs), using the generic FormWizard and the existing Structure create flow
  (WorldTask region and location capture, as for other structures).
- **Logistics dashboard** (admin): per town, warehouses with fill bars; production structures with line states and
  occupancy; open orders as a timeline with ETA; warnings (`BlockedFull`, `NoDestination`, `AwaitingSpace`,
  `ReturnBlocked`).
- **Storage detail:** contents table, adjust action, movement ledger with filters (by reason, by blueprint, by date).
- This also realises the iPhone-note idea of a website showing "hoe vol je properties zitten" (how full your
  properties are) (L105).

## 10. Later phases (hooks only)

1. **Consumption chains** (Phase 6+): lines with inputs at a workshop (`IProductionSite` on a Shop, or a
   `ProductionStructure` with inputs, e.g. Sawmill: logs → planks). **Supply orders** are transport in the other
   direction: warehouse → input storage. They are triggered when an input storage falls below a refill threshold. The
   state machine and stock rules are reused unchanged.
2. **Shops** (own design, with the shops/property row in the register): a `Shop : Structure` with `Merchandise` and
   `Input` storages. Selling decrements merchandise through `IStorageService`. Prices come from
   `ItemBlueprint.BasePriceMin/Max` plus supply. Payment goes through `ICurrencyService` with new reason codes.
   Warehouses distribute to shops by percentage (concept L168).
3. **Ownership and income** (vision §4.5 open): owners per structure, and payout of production value or auto-sell
   (iPhone L92). This needs Town/Structure currency accounts, which the ledger does not have yet (currency DESIGN
   L238-247). The "decouple storefront from production capacity" option (vision §4.1) fits this model: capacity
   = lines + storages, ownable separately.
4. **Physical transport and risk:** an NPC carrier or cart walks the road route for an `InTransit` order (KNG-36
   NPC platform plus the KNG-27 road graph). A route risk (`RoadEdge.CostMultiplier`, bandits) can delay, damage
   or rob cargo (`Lost` amounts as a separate ledger reason). Player escort and courier quests are the V1
   `Minigames/Transport.java` port, now with real cargo. Thieves become wanted (iPhone L268-272).
5. **Territory yield and tech** (vision §2.3, §4.3): modifiers on `YieldPerCycle` from territory control and
   technology. These are multipliers in §6.1 step 2, not new entities.

## 11. Improvement checklist (V2 defect → V3 answer)

| V2 defect (scan §7) | V3 answer |
|---|---|
| 1 infinite loop on distinct cap | `TryAdd` returns `DistinctCapReached`, no loops (§5) |
| 2 delivery overflow dropped | AwaitingSpace → re-route → Returning (§6.3) |
| 3 multi-stop duplication | one stop now, explicit per-stop amounts later (§6.3) |
| 4 lost updates, split transactions | conditional SQL in one transaction per move, row lock, ledger (§5) |
| 5 drift, downtime, silent loss when full | anchor-based cycles, catch-up cap, `BlockedFull` state (§6.1) |
| 6 main-thread I/O, unsafe subscriber set | API-side processing, notification queue, async client (§8) |
| 7 threshold never reached with mixed stock | occupancy + blocked + distinct-cap triggers (§6.2) |
| 8 fixed 128/N sizing, ignored flags | stock-based allocation, `AutomaticTransport` honoured, `CUSTOM` rejected until built (§6.2, §3) |
| 9 N+1, straight line, stale cache | `transport_lanes` with road distances, per-order choice (§6.4) |
| 10 polling every generation | indexed `NextCycleAt` due query, batches (§6.1) |
| 11 instant transport | Loading/InTransit with ETA from lanes (§6.3) |
| 12 inputs never enforced | inputs consumed per cycle, `BlockedInputs` (§6.1) |
| 13 broken undo | DB transactions instead of `unExecute` |
| 14 `@Any`, Calendar units, client ids, double flags | typed FK, seconds, DB identity, one `Enabled` per level |
| 15 command alias and permission typos | `/knk` subcommands with permission filtering |
| 16 menu bugs | menu engine, one confirm path, no event double handling |
| 17 no notifications | blocked/no-destination/awaiting-space notifications (§8.4) |

## 12. Decisions

Each item has a recommended default, so implementation can start. The developer confirms or overrides.

| # | Question | Recommendation |
|---|---|---|
| D1 | Wilderness producers: V3 `Structure.DistrictId` is required. | Add nullable `Structure.RulingTownId`. Make `DistrictId` nullable with the rule "District **or** RulingTown is required" (validator + check constraint). Effective town = `District.Town ?? RulingTown`. V2 did the same ("revive the Town field", 2023-11-29). |
| D2 | Ownership before player features? | MVP is **town/staff-run**: no owners, no payouts. Warehouses are town-owned per concept L168. Ownership comes with the property economy design (vision §4.5). |
| D3 | Capacity unit. | Keep V2's **raw item count** (simple, predictable). Optionally add a per-storage `WeightByStackSize` flag later (chest-era `ChestUtil` weighted 16-stack items ×4). |
| D4 | When a line's output is full. | **Stall without accruing**: the anchor moves to now while blocked. Lost output is visible as `BlockedFull` time on the dashboard. This avoids bursts when space frees up and makes "empty your storage" matter. The alternative is to accrue up to the catch-up cap. |
| D5 | Catch-up after API downtime. | Cap at 24 cycles (one day for hourly lines). |
| D6 | Ground-drop output (`SPAWN_ON_GROUND`). | Drop it. |
| D7 | Transport speed and visibility. | Simulated. Carrier speed 4 blocks/s, load 5 s. ETA is shown in menus and the dashboard. A physical NPC comes later (§10.4). |
| D8 | Does production need the game server or loaded chunks? | No. It is abstract and API-side. |
| D9 | Ledger retention. | Keep all non-production rows. Roll production rows up per line per day after 30 days. |
| D10 | Withdraw with a full inventory. | Give what fits and return the rest to storage (no world drops). |
| D11 | Entity names. | Keep V2's `ProductionStructure`, `Warehouse`, `Storage`, `TransportOrder`. Rename `Generation` → `ProductionLine` (one class for V2 `Generation` + `Production`). The UI label for the structure type is "Resource production" (managed-region kind `RESOURCE_PRODUCTION`; vision "Resource-Property"). |
| D12 | Relation to KNG-47 (all Structure subtypes). | Build `Warehouse` and `ProductionStructure` here as the first two §2.5 subclasses. KNG-47 keeps House/Property/Room and the ownership-dependent flags. |
| D13 | How a physical item maps to a blueprint for deposit (§6.6). | Instance tag → blueprint; new `knk_blueprint` PDC tag for stackables; plain vanilla items map through a unique `VanillaMaterialMatch` on the resource blueprint (coal, logs, wheat, …), so items gathered in the world can be stored. |
