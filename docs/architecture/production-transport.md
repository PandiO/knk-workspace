# Production transport: orders, transit storage, simulated carriers and road-measured lanes (knk-web-api, knk-plugin and knk-web-app)

**Status:** Current · **Last updated:** 2026-11-20 (header: P6 adds the staff retry and the in-game orders menu, docs #903); 2026-11-20 (first version, production P5 #79/#681/#682, docs PandiO/knk-workspace#891)
**Checked against:** knk-web-api `next` `bf8633fb` (PR PandiO/knk-web-api#65), knk-plugin `next` `7116f1a5` (PR
PandiO/knk-plugin#108), knk-web-app `next` `5ad5029f` (PR PandiO/knk-web-app#68). Not released; the manual steps of the
[smoke test § 6](../guides/production-storage-transport-smoke-test.md#6-phase-p5-transport-core-simulated-79-api-681-plugin-682-web-app-tier3)
have not been run live yet.
**Related:** [production DESIGN § 7](../specs/production-storage-transport/DESIGN.md) (the rules: order model,
lifecycle, carriers, triggers, lanes, workers), [API contract](../specs/api/API_CONTRACT_PRODUCTION_TRANSPORT.md),
[admin guide](../guides/admin/production-transport-admin-guide.md), [production engine](production-engine.md) (lines,
settle, the worker factor), [production world](production-world.md) (warehouses, production structures, road
connection field), [stock admin guide](../guides/admin/stock-admin-guide.md) (storages, the ledger and the reconciler),
[plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production) (`production.logistics.lanes.*`),
[storage terminals and structure menus](production-storage-terminals.md) (P6: `POST api/TransportOrders/{id}/retry`, the
in-game orders menu with cancel and retry)

Phase P5 moves goods. A **transport order** takes cargo from a source storage (normally a production structure's Output
storage) to one or more **stops** (normally a warehouse's delivery storage). While it travels the cargo sits in the
order's own **Transit storage**, so the stock ledger balances at every step. V1 carriers are **simulated** (G14): one of
the producing structure's own workers is away while the order runs, and each leg takes its route length ÷ a walking
speed. Nothing walks in the world and nothing can be robbed (D6). The route length comes from a **lane**, the road
distance between two structures that the game server measures over the road network; without a lane it is estimated.

Orders are made three ways: **automatically** by the API's transport sweep when a producer's Output reaches a trigger,
**manually** by staff (web app or REST), and by a quest script (`Quest`, through the same endpoint). A rural producer
that the game server finds **not connected** to its town's roads gets no automatic transport (D5): it fills up and stops,
with a warning.

Everything runs only while the game setting **Production enabled** (`Production:Enabled`) is on, and on the game server
only with `production.enabled: true` (A21). Staff can still create manual orders, dry runs, lanes and cancel while it is
off; nothing moves until it is on again.

## 1. Ownership

| Part | Repo | Where |
|---|---|---|
| Entities (order, stop, stop line, cargo line, assignment, event, lane) | knk-web-api | `Models/Transport/Transport.cs`; enums `TransportOrigin`, `TransportStatus`, `TransportCarrierMode`, `TransportStopStatus`, `TransportEventKind`, `TransportLaneSource`, `TransportDistanceSource` in `Enums/TransportEnums.cs` |
| Fields the transport reads on a production structure (automatic transport, threshold, capacity, warehouse preference, road connection, workers) | knk-web-api | `Models/Production/ProductionStructure.cs` (from P2/P3; P5 writes `WorkersPresent` and the plugin writes `RoadConnection`) |
| Plans, create, cancel, the lifecycle steps, the automatic trigger, the structure view | knk-web-api | `Services/Production/TransportService.cs` (`TransportService`) |
| Distances, room, the warehouses of a town | knk-web-api | `Services/Production/TransportRouting.cs` (`TransportRouting`) |
| Lanes, the game server's report and the due list | knk-web-api | `Services/Production/TransportLaneService.cs` (`TransportLaneService`) |
| Background sweep (every 60 s) | knk-web-api | `Services/Production/TransportSweepService.cs`; registered in `DependencyInjection/ServiceCollectionExtensions.cs` |
| Road connection endpoint and the structure's dashboard warnings | knk-web-api | `ProductionStructuresController` (`PUT {id}/road-connection`, `GET {id}/transport`), `ProductionStructureService.SetRoadConnectionAsync` and `Warnings` in `Services/Production/ProductionWorldServices.cs` |
| Settings section `production.transport` | knk-web-api | `ProductionTransportSettingsDto` in `Dtos/TerritoryDtos.cs`; validation in `Services/Territory/ProductionSettings.cs` |
| Controllers and DTOs | knk-web-api | `Controllers/TransportOrdersController.cs`, `Controllers/TransportLanesController.cs`; `Dtos/TransportDtos.cs` |
| Dashboard types and access | knk-web-api | `Attributes/DashboardAccess.cs` (`TransportOrder` list only, `TransportLane` with delete; view only `TransportStop`, `TransportStopLine`, `TransportOrderLine`) |
| Form and display seeds | knk-web-api | `Data/FormConfigurationSeeds/{TransportOrder,TransportLane}.json`, `Data/DisplayConfigurationSeeds/{TransportOrder,TransportLane}.display.json` |
| Lane measuring rules (pure) | knk-plugin | `knk-core/.../core/production/transport/`: `LaneMeasurer`, `LaneJob`, `RoadConnectionBook`, `LaneSettings`, `LaneDue`, `LaneMeasurement`, `LanePosition`, `RoadConnection` |
| API port and client | knk-plugin | `knk-core/.../core/ports/api/TransportLanesApi.java`, `knk-api-client/.../api/impl/TransportLanesApiImpl.java` |
| Paper side | knk-plugin | `knk-paper/.../paper/production/LaneModule.java` (the scheduled job and the `KnK-lanes` thread), `LaneConfig.java`; `commands/LogisticsAdminCommand.java`; wiring in `KnKPlugin` |
| Types and API clients | knk-web-app | `src/types/dtos/production/TransportDtos.ts`; `src/apiClients/transportOrderClient.ts`, `transportLaneClient.ts`; `getTransport` on `productionStructureClient.ts` |
| Pages and panels | knk-web-app | `src/pages/admin/transport/TransportOrdersPage.tsx`, `TransportOrderNewPage.tsx`; `src/components/transport/`: `TransportOrderPanel`, `StructureTransportPanel`, `TransportPlanView`, `TransportOrderTable` (the two panels mounted by `src/pages/DisplayWizardPage.tsx`); `src/components/admin/gameSettings/TransportSettingsCard.tsx` |
| Labels and checks | knk-web-app | `src/utils/transport.ts` (status and event words, `canCancelOrder`, settings bounds, page paths) |

## 2. The order model (DESIGN § 7.1)

### 2.1 `TransportOrder`

| Field | Meaning |
|---|---|
| `Origin` | `Automatic` (the sweep), `Manual` (staff), `Quest` (a quest script); `Distribution` (P9) and `Trade` (later) are reserved |
| `Status`, `StatusReason` | The lifecycle (§ 3) and why it waits, re-routed, returned or was cancelled |
| `SourceStorageId`, `SourceStructureId` | Where the cargo starts; the structure is the source storage's holder (a `Domain` storage whose domain is a structure), used for lanes |
| `CargoStorageId` | The order's own Transit storage (§ 4), unique per order |
| `CarrierStructureId`, `CarrierCapacity` | The production structure whose worker carries, and how many raw units it may take (§ 5); both null for a carrier without a worker |
| `CurrentStructureId`, `CurrentStopId` | Where the carrier is (or left last), and the stop it heads for or stands at |
| `Reroutes`, `ReturnAttempts`, `CancelRequested` | Counters and the cancel flag of a loaded order |
| `ExecuteAfter` | Not before this time (a manual order may be scheduled) |
| `NextActionAt` | When the sweep looks at the order next; **null once the order is final**. "Open" means `NextActionAt` is set |
| `CreatedAt`, `DepartedAt`, `LegStartedAt`, `EtaAt`, `WaitingSince`, `CompletedAt` | Times |
| `CreatedByUserId`, `Note`, `ClientKey` | Who made a manual order, a note (≤ 500), and an idempotency key (≤ 80, unique): a repeated create with the same key returns the first order |
| `Risk` | Route risk (DESIGN § 7.5); always null in V1 (D6) |

The final statuses are `Delivered`, `Returned`, `Cancelled` and `Lost`. "Loaded" statuses (the cargo is in the Transit
storage) are `InTransit`, `AtStop`, `AwaitingSpace`, `Returning` and `ReturnBlocked`.

### 2.2 Stops and stop lines (V2 defect 3)

An order has one to ten **stops** (`TransportStop`), visited in `Sequence` order. Each stop names a storage (and its
structure, for lanes), has a status (`Pending`, `Delivered`, `Partial`, `Skipped`), the leg's distance and its source
(`Lane`, `Estimated`, `Fallback`), an ETA, arrival and completion times, a delivery try counter and, on a stop added by
a re-route, `ReroutedFromStopId`. Each stop has its own **stop lines** (`TransportStopLine`, one per blueprint, at most
50): `Planned` and `Delivered`. Every stop keeps its own amounts, so a two-stop order never delivers the first stop's
goods at the second (the V2 bug).

### 2.3 Cargo lines

`TransportOrderLine`, one per blueprint over all stops: `Requested`, `Loaded`, `Delivered`, `Returned` and `Lost`. At
every moment `Loaded = Delivered + Returned + Lost + what is still in the Transit storage`. `Lost` stays 0 in V1.

### 2.4 Assignments and events

A `TransportAssignment` records who carries: `Mode` (`Simulated` in V1; `NpcCaravan` and `PlayerCourier` are reserved),
the carrier structure, `Workers` (1 when a worker of the carrier structure carries, else 0), the speed and capacity used,
and `AssignedAt` until `ReleasedAt`. A `TransportEvent` is one line of the order's log: time, kind, the status after it,
the stop, the stock transaction id of a move, and a message (≤ 500). The kinds are `Created`, `WaitingForWorker`,
`Assigned`, `Loaded`, `Departed`, `ArrivedAtStop`, `Delivered`, `AwaitingSpace`, `Rerouted`, `ReturnStarted`,
`Returned`, `ReturnBlocked`, `WorkerReturned`, `Completed`, `CancelRequested`, `Cancelled` and `Note`. `GET` shows the
first 500 events, oldest first.

## 3. The status lifecycle (DESIGN § 7.2)

The lifecycle is shared by every carrier mode. V1 uses eleven states; `Ambushed`, `Defended`, `Robbed`, `Lost` and
`Stalled` are reserved for physical carriers (#53, #251) and never reached (a sweep that met one would stop the order).

| From | Step (when `NextActionAt` is due) | To |
|---|---|---|
| `Planned` | The carrier structure has no worker present: event `WaitingForWorker`, retry in 1 minute | `Planned` |
| `Planned` | A worker leaves (assignment), the cargo is loaded (§ 4), the carrier departs to the first stop with something planned | `InTransit` (passing `Assigned` and `Loading` in the same step) |
| `Planned` | The source holds none of the cargo: "Nothing to load", the worker comes back at once | `Cancelled` |
| `InTransit` | At the ETA: arrives (`ArrivedAtStop`) and delivers what the stop has room for | `AtStop`, then the next leg, `AwaitingSpace`, `Returning` or `Delivered` |
| `AwaitingSpace` | Tries again every minute; after `awaitingSpaceMinutes` re-routes or carries on (§ 4.3) | `InTransit` or (no stop left) `Returning` |
| (after the last stop) | Cargo is still on board | `Returning` |
| (after the last stop) | Nothing is on board | `Delivered` |
| `Returning` | At the ETA: puts the cargo back into the source | `Returned`, or `ReturnBlocked` while the source has no room |
| `ReturnBlocked` | Tries again every minute until the source takes everything | `Returned` |
| `Planned` | Staff cancel | `Cancelled` |
| any loaded status except `Returning`/`ReturnBlocked` | Staff cancel (`CancelRequested`) | `Returning`, ending `Returned` with "Cancelled: the cargo is back in the source." |

`Assigned`, `Loading` and `AtStop` never outlive one step. A cancel of a final or returning order is refused (409).
`Delivered` means every stop was served (some may be `Partial` or `Skipped` if a re-route took over); `Returned` means
some or all of the cargo came back.

## 4. Transit storage and the ledger

### 4.1 Every move is a ledger transaction

Creating an order also creates its Transit storage (`Kind` Transit, no holder, uncapped; named "Transport #<id>
cargo"). The cargo only ever moves through `IStockService.MoveManyAsync` in `Partial` mode:

| Step | Move | Ledger reason | Idempotency key |
|---|---|---|---|
| Load | source → transit, what is there up to the request | `TransportLoad` | `transport:<order>:load` |
| Deliver at a stop | transit → stop, what the stop has room for, up to its planned amounts and what is on board | `TransportDeliver` | `transport:<order>:stop:<stop>:try:<n>` |
| Return | transit → source, everything left | `TransportReturn` | `transport:<order>:return:try:<n>` |

Each transaction has the actor `System`, component `TransportService`, source `TransportOrder <id>` and a note
"Transport #<id>: <Load|Stop n|Return>". The event of the step keeps the transaction id, so the order's timeline links
to each move. The reconciler (`GET api/StockTransactions/reconcile`) is clean after every step (smoke test § 6.1
step 5).

### 4.2 Locking and restarts

Each lifecycle step runs in one database transaction (read committed) that first locks the order row (`SELECT … FOR
UPDATE` on `transport_orders`), reloads the order and checks it is still due. State lives only in the database, and each
retry has its own key, so a restart, a second sweep or a second API instance never applies a step twice: a restart mid
transit carries on at the next sweep and delivers once (step 16). The automatic trigger also locks the producer's row
and checks again that it has no open automatic order before it inserts one.

### 4.3 Overflow never drops cargo (V2 defect 2)

1. **Short at the source.** Loading takes what the source holds, up to the request. The stops keep what was loaded in
   visiting order: each stop's planned amount is lowered to what is left for it, and a stop left with nothing is
   `Skipped` (step 13).
2. **No room at a stop.** The stop takes what fits; the rest stays on board and the order is `AwaitingSpace` ("Stop
   <n> has no room for <k> unit(s) (<reason>): waiting."), trying again every minute.
3. **After `awaitingSpaceMinutes`** the stop ends `Partial` (or `Skipped`) and, while the order has re-routed fewer than
   `maxReroutes` times, it **re-routes** to another warehouse of the town where the stop stands: one that accepts
   deliveries, has a delivery storage not yet used by the order and some room; those with room for all of it first,
   then the nearest by route, then the highest priority. A new stop with the remaining amounts is inserted right after
   the full one (`Rerouted`, `ReroutedFromStopId`).
4. **No warehouse can take it** (or the re-route cap is reached): a `Note` event, and the carrier carries on to its
   next stop. After the last stop whatever is still on board goes back (`Returning`, the leg from where the carrier is
   to the source).
5. **The source is full on return.** What fits goes back; the order is `ReturnBlocked` and tries every minute until the
   source has room. The cargo stays in the Transit storage meanwhile (step 12).

### 4.4 Cancel

Before loading (`Planned`) the order ends `Cancelled` at once, its stops `Skipped`, no stock moved. A loaded order gets
`CancelRequested`, its pending stops are `Skipped` and it starts back: an order `InTransit` **turns around**, and the way
back takes as long as it has walked on this leg; an order waiting at a stop walks the route from that stop to the source.
It ends `Returned` with "Cancelled: the cargo is back in the source." (steps 14-15).

## 5. Simulated carrying (G14) and the trip time

### 5.1 The carrier (DESIGN § 7.7)

The carrier is a production structure: the one given in the request, or by default the structure that holds the source
storage when it is a production structure. Its worker:

1. **Capacity.** A worker carries at most the structure's `TransportCapacity` (set from its level by the engine), else
   the setting `defaultCarrierCapacity` (64), in raw units (amount × the blueprint's storage weight). A manual order
   over the capacity is refused (400).
2. **Leaves on loading.** At the start step a worker leaves: `WorkersPresent` goes down by one and an assignment is
   opened. With no worker present the order waits (`WaitingForWorker`, retried every minute); a structure without
   workers can't carry at all (400 on a manual order).
3. **Comes back when the order ends** (any final status, including a cancel and a return): `WorkersPresent` goes back
   up (never above `WorkersTotal`), event `WorkerReturned`. The worker is away for the whole order, waits and returns
   included.
4. **Lower output meanwhile.** The engine's worker factor is present ÷ total, so one of two workers away halves the
   structure's output and both away stop it (steps 6-7). Before each step that sends a worker away or brings one back,
   the service settles the carrier structure's production (`IProductionEngine.SettleStructureAsync`), so the time
   before counts at the old factor. Waiting retries don't settle (at most one retry interval off).

An order from a storage that no production structure holds (for example from a warehouse) is carried by a **simulated
carrier without a worker**: no capacity limit, nobody is away, and the plan warns so (step 17).

### 5.2 Distance and trip time (`TransportRouting.DistanceAsync`)

For a leg from structure A to structure B:

1. **`Lane`**: a reachable lane with a road distance between A and B, in either direction (the A → B one first). A lane
   counts in both directions.
2. **`Estimated`**: no lane, but both structures have a location in the same world: the straight horizontal distance
   (x and z) × `unmeasuredRouteFactor` (1.4), rounded to 0.01. The plan warns "no measured lane".
3. **`Fallback`**: no lane and no positions (or different worlds): `fallbackDistanceBlocks` (200).

A leg from a structure to itself is 0 blocks. A stop storage without a structure is a leg without an end, so it gets the
fallback. The trip time is ⌈distance ÷ `walkingSpeedBlocksPerSecond`⌉ seconds (4.317 blocks/s, a vanilla player's walk):
431.7 blocks take 100 s. The leg's distance and source are kept on the stop; the order's `EtaAt` and `NextActionAt` are
the arrival. `TransportDistanceSource.TurnedAround` exists in the enum but is not written: a turned-around return keeps
its time in the order's ETA only.

## 6. Automatic triggers and the D5 hold (DESIGN § 7.4, § 7.6)

### 6.1 The evaluation

For each production structure with `AutomaticTransport` on (the default), the sweep evaluates the trigger; `GET
api/ProductionStructures/{id}/transport` runs the same evaluation without writing (the "dry run" of the trigger).

1. **Threshold.** The structure's `TransportThreshold`, else for a capped Output storage ⌈cap × `defaultThresholdPercent`
   ÷ 100⌉ (at least 1), else `defaultThresholdUnits`.
2. **Trigger reasons** (any of them, V2 defect 7): the Output storage holds at least the threshold (and more than 0); a
   line of the structure is `BlockedFull`; the Output storage holds as many different items as its `MaxDistinct`.
3. **Held reasons** (any of them stops it): production is off; automatic transport is off; a **rural** structure
   (no district) whose road connection is not `Connected`; no town; no Output storage; no workers; an open automatic
   order of this structure already exists (one at a time per structure); the Output storage holds nothing; no
   warehouse of its town takes deliveries.
4. **Sizing** (V2 defect 8): the Output storage's stock, largest weighted amount first, up to the carrier capacity.
5. **Destination** (V2 defect 9): with warehouse preference `Preferred`, the preferred warehouse when it is one of the
   town's delivery warehouses and has room for the cargo (else a warning and the nearest); otherwise the town's
   warehouses that accept deliveries and have a delivery storage, those with room first, then the shortest route, the
   highest priority, the lowest id. One stop: the warehouse's delivery storage (`DefaultStorageId`).
6. **The plan** is the same plan a manual order gets (§ 5, the dry run); the order is made with origin `Automatic` and a
   `Created` event that quotes the trigger reasons.

A producer without a free worker is not held: the order is made and waits for a worker.

### 6.2 The D5 hold and the warnings (A13)

A rural production structure has no off-road transport. Its road connection (`Unmeasured` by default, `Connected`,
`Unconnected`) is set by the game server's lane measurer (§ 8.4) or by `PUT api/ProductionStructures/{id}/road-connection`.
While it is not `Connected`, automatic transport is held, so the structure fills its Output storage and its lines stop
(`BlockedFull`). The warnings:

1. The transport view: "Not connected to its town's road network: automatic transport is held (D5)." (Unconnected) or
   "Its road connection has not been measured yet: …" (Unmeasured); "The Output storage is full (…): production stops
   until goods are carried away (D4)."; no workers; no warehouse; the preferred warehouse can't take it.
2. The structure itself (`GET api/ProductionStructures/{id}` `warnings`): "Not connected to its town's road network:
   automatic transport is held." (Unconnected only) and "Its Output storage is full (…)".

A structure in a district needs no road connection. Manual orders are never held by D5.

## 7. The sweep and the `production.transport` settings

### 7.1 The sweep

`TransportSweepService` runs `ITransportService.SweepAsync` every 60 seconds (fixed, not a setting). Each run:

1. returns at once while `Production:Enabled` is off (A21): no automatic order, no step; a `Planned` order stays
   `Planned` and workers away stay away;
2. evaluates the trigger of every structure with automatic transport on, in id order (§ 6), and makes at most one
   order for each;
3. steps up to 200 due orders (`NextActionAt` ≤ now, the oldest due first; index on `NextActionAt`), each up to 25 steps
   in a row as long as each step is due at the same moment.

A failing structure or order is counted (`ordersFailed`) and logged; the others go on. `POST api/TransportOrders/run-now`
runs the same sweep at once over every open order, not only the due ones (still at most 200; 409 while production is off) and answers `{ ordersCreated,
ordersAdvanced, ordersFailed }`; each order still moves only as far as its times allow.

### 7.2 Settings

The section `production.transport` of the game settings (`GET`/`PUT api/GameSettings`, the web app's **Transport**
card). A save without the section keeps the stored one, so a client that does not send it does not reset it.

| Key | Default | Bounds | Used for |
|---|---|---|---|
| `walkingSpeedBlocksPerSecond` | 4.317 | 0.1-50 | Trip time (§ 5.2) |
| `defaultCarrierCapacity` | 64 | 1-1,000,000 | A worker's capacity without `TransportCapacity` |
| `defaultThresholdPercent` | 75 | 1-100 | Trigger for a capped Output storage without `TransportThreshold` |
| `defaultThresholdUnits` | 64 | 1-1,000,000 | Trigger for an uncapped Output storage without `TransportThreshold` |
| `unmeasuredRouteFactor` | 1.4 | 1-10 | Straight distance × factor without a lane |
| `fallbackDistanceBlocks` | 200 | 1-1,000,000 | A leg without lane and positions |
| `awaitingSpaceMinutes` | 30 | 1-10,080 | Wait at a full stop before re-routing |
| `maxReroutes` | 2 | 0-10 | Re-routes per order before the cargo goes back |
| `laneMaxAgeHours` | 24 | 1-8,760 | A plugin-measured lane older than this is due again |

A value out of bounds is 400 "production.transport.<key> must be <min> to <max>.".

## 8. Lanes and the game server's lane measurer (DESIGN § 7.6)

### 8.1 The lane

`TransportLane`: from and to structure (one lane per direction, unique; a lane counts in both directions for routes),
`Reachable`, `RoadDistance` (required when reachable, null when not), `StraightDistance`, the route's road edge ids (a
JSON list), an optional `MeasuredSeconds` (shown only), `Source` (`Plugin` or `Manual`), `MeasuredAt` and a note. An
unreachable lane is never a route; the leg falls back to the estimate. Deleting a structure deletes its lanes.

### 8.2 The due list and the report contract

1. **`GET api/TransportLanes/due?limit=<n>`** (1-500, default 100; empty while production is off): the pairs to measure,
   with both structures' positions (`world`, `x`, `y`, `z`, null without a location). The pairs are every production
   structure to every warehouse of its town that accepts deliveries, then the warehouses of one town among themselves
   (for re-routes). A pair is due when it has no lane in either direction (`Missing`) or its newest lane was measured by
   the plugin more than `laneMaxAgeHours` ago (`Stale`). A manual lane is never stale.
2. **`POST api/TransportLanes/report`** (at most 500 lanes): each lane is upserted by its (from, to) pair with source
   `Plugin` and `measuredAt` now unless sent; the answer counts `created` and `updated`. A reachable lane without a road
   distance is refused (400) for the whole report.
3. **`PUT api/ProductionStructures/{id}/road-connection`** with `{ "roadConnection": "Connected" | "Unconnected" |
   "Unmeasured" }`: sets the state and `RoadConnectionMeasuredAt` (cleared for `Unmeasured`). 404 for a structure that
   is not a production structure (a warehouse).

### 8.3 The measurer (`LaneMeasurer`)

The plugin measures a pair with the navigation road router (`AStarRouter`) over the plugin's road snapshot
(`RoadNetworkCache`), read-only and off the main thread:

1. Each structure's position (its location's feet) joins the road at the nearest road point within
   `max-snap-distance` blocks (48, 3D; the height only ranks the candidates, as navigation does). A structure with no
   road that near gives an unreachable lane ("#<id> is more than 48 blocks from a road").
2. The route is searched in the default route mode with every gate and region open (`AccessPolicy.ALL_OPEN`): the
   carriers are simulated workers, not players with access rules. One-way roads still count. The class costs and snap
   weight are navigation's router parameters.
3. The road distance is the walk to the road + the road route + the walk from the road, rounded to 0.01; the straight
   distance is the 3D distance between the two positions. The route's edge ids are reported in order.
4. Different worlds, roads that do not join ("the roads at the two structures are not connected") or no route:
   unreachable. Different worlds report no straight distance.
5. **Skipped** (not reported, stays due, no road connection judged): a structure without a location, or a world whose
   road snapshot is not loaded or empty. A missing snapshot never reads as "no road".

### 8.4 The job and road connections (`LaneJob`, `RoadConnectionBook`)

One run: read the due list (`batch` pairs), measure every pair on the `KnK-lanes` thread (timed as
`production.lanes.measure`), report the measured lanes (at most 500 per call; skipped ones are not reported), then, with
`road-connections` on, judge the structures of the measured lanes and send the states that changed:

1. A structure with at least one reachable lane measured since the server started is `Connected`; one whose every
   measured lane is unreachable is `Unconnected`; a structure with no measured lane is not judged. The book remembers
   every lane's last result, so a newly due unreachable lane does not undo an earlier reachable one.
2. An unchanged state is not sent again. A 404 marks the id as not a producer (a warehouse): it is not asked again until
   a restart. The book lives in memory and starts empty at each server start.

Only one run at a time; a second call gets the running one's result. A run that cannot read the list or report stops
with the reason in its summary and the log (`[Lanes] Run (<why>) stopped: …`). The summary line is "<n> due, <r>
reachable, <u> without a road, <s> skipped; API created <c>, updated <u>; road connections sent <k>", with up to 50
per-lane notes (10 shown in chat).

### 8.5 Wiring, settings and the command

`LaneModule` exists only with `production.enabled: true`. Keys `production.logistics.lanes.*`
([plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production)): `interval-minutes` (60; 0 =
only on the command; the first scheduled run two minutes after start, once the road network is downloaded), `batch`
(100, 1-1000), `max-snap-distance` (48), `road-connections` (true). The start log line is "Lane measurer is on
(production.enabled): every 60 min, 100 pairs per run, road connections on.". `/knk logistics lanes measure` runs a job
now and answers the sender; `/knk logistics lanes status` shows the interval, the lanes known since start and the last
run. Both need `knk.admin.world.production` (also matched by `knk.admin.world.*` and `knk.admin.*`); with production off
the command answers "Production is off on this server (production.enabled: false).".

## 9. Web app

1. **Transport orders** (`/admin/transport/orders`, admin sidebar group World, needs `knk.admin.world`): the order list
   newest first with status in words, origin, from, the stops joined with " → ", units ("20 of 20 delivered"), created
   and ETA; filters `open`, `status`, `origin`, `structureId` and `storageId` in the URL.
2. **An order's page** (`/display/TransportOrder/<id>`): the seeded display with a **Transport** panel below
   (`TransportOrderPanel`): status and reason, source, carrier, cargo storage, times, the cargo table, what is on the
   road now, the route per stop with distance source, carriers, the timeline oldest first with links to the stock
   transactions, and **Cancel the order** while it can be cancelled.
3. **New manual order** (`/admin/transport/orders/new`, from the list or a structure's **New order from here**): source
   storage, carrier, stops with items and amounts, execute after and a note. **Make the order** is on only after a
   **Dry run** of the same request without errors; the create carries a `clientKey`, so a double click makes one order.
4. **A production structure's Transport panel** (`StructureTransportPanel`, below the Yield panel): the warnings, the
   automatic trigger now (why it fires, why it is held, the order it would make), workers present and away, open orders,
   the structure's lanes with **Add a lane**.
5. **Game settings › Transport** card: the nine settings with the API's bounds checked before save, and **Run transport
   now** (off while production is off).
6. **Dashboard**: `TransportOrder` (list only, no create, edit or delete) and `TransportLane` (with the seeded form;
   delete needs `knk.admin.delete`).

The words on these pages are listed in the [admin guide](../guides/admin/production-transport-admin-guide.md).

## 10. Schema, migration and access

Migration **`AddTransportCore`** (`20261120123016`; after `SeedNavigateDefaultNode`, the production migration before it is `AddProductionYieldAreas`) creates seven tables and changes
no existing row: `transport_orders` (unique `CargoStorageId`, unique `ClientKey`, indexes on `NextActionAt`, on
`SourceStructureId, Origin, Status` and on `Status, Origin`), `transport_stops` (index `TransportOrderId, Sequence`),
`transport_stop_lines` and `transport_order_lines` (unique per blueprint), `transport_assignments` (index
`CarrierStructureId, ReleasedAt`), `transport_events` (index `TransportOrderId, At`) and `transport_lanes` (unique
`FromStructureId, ToStructureId`, cascade on structure delete). The order's storages and blueprints are restricted: a
storage that took part in an order has ledger history, so its structure can't be deleted (409, as in P2). Rolling back
drops the seven tables; the Transit storages and the ledger rows of moved stock stay.

| Endpoints | Needs |
|---|---|
| Reads: `GET api/TransportOrders/{id}`, `POST …/search`, `GET api/TransportLanes/{id}`, `POST …/search`, `GET api/TransportLanes/due`, `GET api/ProductionStructures/{id}/transport` | `knk.admin.world` (the World area), or the plugin key |
| `POST api/TransportOrders`, `…/dry-run`, `…/{id}/cancel`, `…/run-now`; `POST api/TransportLanes/report`; `PUT api/ProductionStructures/{id}/road-connection` | `knk.admin.world`, or the plugin key |
| `POST`, `PUT {id}` of `api/TransportLanes` | `knk.admin.world` and `knk.admin.content` (dashboard change rule) |
| `DELETE api/TransportLanes/{id}` | `knk.admin.world` and `knk.admin.delete` |

The rules are pinned by `EndpointAccessRulesTests`, `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests` and
`DeleteAccessRulesTests`.

## 11. Tests, recovery and limitations

### 11.1 Tests

1. knk-web-api: `Tests/.../Services/Production/TransportTests.cs` (lifecycle, ledger, overflow, re-route, return,
   cancel, restart, triggers, D5, workers; over `TransportTestDb`), `TransportLanesAndSettingsTests.cs` (due list,
   lane validation, settings), `Api/TransportControllersTests.cs`, `Migrations/AddTransportCoreTests.cs` and, with
   `KNK_TEST_MYSQL`, `MySql/TransportMySqlTests.cs` (the row locks).
2. knk-plugin: `knk-core/.../production/transport/` `LaneMeasurerTest` (over a built road network, with
   `LaneFixtures`), `LaneJobTest` (fake API), `RoadConnectionBookTest`; `knk-api-client/.../TransportLanesApiImplTest`;
   `knk-paper/.../production/LaneConfigTest`, `knk-paper/.../commands/LogisticsAdminCommandTest` (MockBukkit). No plugin
   scenario: measuring reads only the road snapshot and the API.
3. knk-web-app: `e2e/transport.spec.ts` (Playwright, mocked API, fixtures in `e2e/fixtures/transport.ts`), Jest
   `src/utils/__tests__/transport.test.ts`, `src/apiClients/__tests__/transportClients.test.ts`.
4. Manual: [smoke test § 6](../guides/production-storage-transport-smoke-test.md#6-phase-p5-transport-core-simulated-79-api-681-plugin-682-web-app-tier3),
   not run yet.

### 11.2 Recovery

1. **Cargo stuck in transit.** Look at the order: `AwaitingSpace` and `ReturnBlocked` retry every minute; make room at
   the stop or the source, or cancel a waiting order to bring the cargo back. Never adjust a Transit storage by hand: the
   order's lines would no longer match it.
2. **The reconciler is not clean.** The order's events link each stock transaction; compare the cargo lines with the
   Transit storage's stock.
3. **Production turned off mid-transit.** Nothing moves and workers stay away; turn it on again and the next sweep
   carries on from where each order was.
4. **Wrong lane.** Edit or delete it (`api/TransportLanes`, the dashboard); a deleted pair is due again for the plugin.
   A road connection set wrong: `PUT …/road-connection`, or delete the structure's lanes and measure again.

### 11.3 Limitations

1. Carriers are simulated only (`Simulated`); NPC caravans (#251) and player couriers are later. No route risk and no
   robbery (D6); `Lost` stays 0.
2. `Distribution` (P9) and `Trade` orders are not made yet.
3. The automatic trigger makes one order with one stop per structure at a time, from the Output storage only.
4. The sweep interval (60 s) and the waiting retry (1 min) are fixed.
5. Lanes are measured only between producers and the warehouses of their own town and among a town's warehouses; a
   manual order between other structures uses the estimate unless staff type a lane in. A manual lane is never stale.
6. The API's estimate uses the horizontal straight distance; the plugin's `straightDistance` is 3D.
7. The plugin judges road connections only from the lanes it measured since its last start; staff lanes do not change a
   road connection. Warehouses have no road connection.
8. `TurnedAround` is never written as a stop's distance source (§ 5.2).

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#891).
