# Production Transport — Admin Guide

**Status:** Current · **Last updated:** 2026-11-20 (§ 3.4: cancel and retry in game since P6, docs #903); 2026-11-20 (first version, production P5 #79/#681/#682, docs PandiO/knk-workspace#891)
**Checked against:** knk-web-api `next` `bf8633fb`, knk-plugin `next` `7116f1a5`, knk-web-app `next` `5ad5029f` (not
released; orders move only with Production enabled on in the API, and lanes are measured only with `production.enabled:
true` on the game server; the manual steps of the
[smoke test § 6](../production-storage-transport-smoke-test.md#6-phase-p5-transport-core-simulated-79-api-681-plugin-682-web-app-tier3)
have not been run live yet)
**Related:** [production DESIGN § 7](../../specs/production-storage-transport/DESIGN.md) (the rules),
[transport architecture](../../architecture/production-transport.md) (lifecycle, ledger, triggers, lanes, tests),
[API contract](../../specs/api/API_CONTRACT_PRODUCTION_TRANSPORT.md), [warehouses and production structures admin guide](production-world-admin-guide.md)
(the structures, their storages and transport fields), [production engine admin guide](production-engine-admin-guide.md)
(lines, workers, the Production panel), [stock admin guide](stock-admin-guide.md) (storages, the ledger),
[plugin configuration § 4.31](plugin-configuration.md#431-production) (`production.logistics.lanes.*`),
[in-game commands](../users/commands.md#server-tools-knk)

Production phase P5 carries goods from production structures to warehouses. When a structure's **Output** storage is
full enough, the API makes a **transport order**: one of the structure's workers takes the goods to the nearest
warehouse of its town. You can also make an order by hand. While an order travels its cargo sits in the order's own
**cargo storage**, so no item is ever counted twice or lost.

Transport is **simulated**: nobody walks in the world. A trip takes its route length divided by a walking speed
(431.7 blocks take 100 seconds). The route length comes from a **lane**, the road distance between two structures that
the game server measures over the road network. Without a lane the API estimates it. While a worker is away carrying,
its structure produces less (one of two workers away: half). Nothing can be robbed yet. Players see nothing of this yet.

## 1. What you need

1. **knk-web-api** with migration `AddTransportCore` applied. It only adds tables; existing structures and stock are
   not changed.
2. **knk-web-app** of the same `next` (or later), for the order pages and panels.
3. **knk-plugin** of the same `next` (or later) on the game server, with `production.enabled: true`, the
   `production.logistics.lanes` keys merged into `config.yml` (§ 7) and the road network loaded. Without it there are no
   measured lanes: legs are estimated and rural producers stay **Unmeasured**, so they get no automatic transport.
4. **Seeds.** As content staff, import the form and display seeds `TransportOrder` and `TransportLane`, each with "make
   default". The TransportOrder form is read only (orders are made on the manual order page).
5. **Production enabled** ticked on the game settings page. While it is off no order moves and no automatic order is
   made; you can still make manual orders, dry runs, lanes and cancel.
6. **Nodes:**

   | To | Node(s) |
   |---|---|
   | See orders, lanes and a structure's Transport panel; make, dry-run and cancel orders; Run transport now | `knk.admin.world` |
   | Create and edit lanes | `knk.admin.world` and `knk.admin.content` |
   | Delete lanes | `knk.admin.world` and `knk.admin.delete` |
   | `/knk logistics lanes measure\|status` in game | `knk.admin.world.production` (in `knk.admin.world.*` and `knk.admin.*`) |

## 2. Before goods move: structures and warehouses

Transport uses the fields you set on the structures (see the
[warehouses and production structures admin guide](production-world-admin-guide.md)):

1. **Warehouses** of the town with **Accepts deliveries** on and a delivery storage. A warehouse in a district of the
   town counts too. A capped delivery storage takes only what fits.
2. On each **production structure**:
   1. **Automatic transport** (on by default).
   2. **Transport threshold**: the units in its Output storage that start a transport. Empty: 75% of the Output's cap,
      or 64 units when the Output is uncapped (the game settings, § 6).
   3. **Transport capacity**: what one worker carries. Empty: the level's, else 64 units.
   4. **Warehouse preference**: **Nearest** (by road) or **Preferred** with a warehouse; the preferred one is used only
      when it can take the cargo, else the nearest.
   5. **Workers**: total (default 2). A structure without workers can't carry.
   6. **Location**: needed to measure lanes and estimate distances.
3. **Rural producers** (Town (rural), no district) need a **road connection**. The game server sets it after it
   measures their lanes (§ 7). Until it is **Connected**, a rural producer gets no automatic transport: it fills its
   Output and stops, with a warning on its page.

Units are raw units: amount × the item's storage weight, as on the storage's Stock panel.

## 3. Orders

### 3.1 The order list

Admin sidebar, group **World** › **Transport orders** (`/admin/transport/orders`). Newest first, with Order, Status,
Origin, From, To (the stops joined with " → "), Units ("20 of 20 delivered", plus "returned" when some came back),
Created and ETA. A waiting order shows its reason under the status. Filter by **Open or final**, **Status**, **Origin**
and **Storage id**, then **Apply filters**; the filters stay in the URL, **Clear** removes them. "All orders of this
structure" on a structure's Transport panel opens the list for that structure (source, stop or carrier).

The statuses in words:

| Status | Words | Meaning |
|---|---|---|
| `Planned` | Planned | Made, not loaded (waits for its time or a free worker) |
| `InTransit` | On the road | Carrying to a stop |
| `AwaitingSpace` | Waiting for room | A stop is full; the carrier waits there (§ 3.5) |
| `Returning` | Returning | Bringing cargo back to the source |
| `ReturnBlocked` | Back, waiting for room at the source | Back, but the source is full |
| `Delivered` | Delivered | Done; every stop served |
| `Returned` | Returned | Done; some or all of the cargo came back |
| `Cancelled` | Cancelled | Done before loading; nothing moved |

### 3.2 An order's page

Click the order number. Below the order's details the **Transport** panel shows:

1. The status in words, with its reason.
2. **From** (the source storage, linked, at its structure), **Carried by** ("A worker of Quarry, up to 64 units" or "A
   simulated carrier"), the cargo storage, and the times (created, runs after, departed, completed).
3. **Cargo**: per item requested, loaded, delivered, returned and lost.
4. **On the road now**: what the cargo storage holds.
5. **Route**: each stop with its storage (linked), its status, the leg's distance and where it came from ("431.7 blocks
   (measured lane)", "(estimated (straight line × factor))", "(fallback distance)"), arrival or ETA, and delivered of
   planned per item. A stop added by a re-route says "re-routed from <stop>".
6. **Carriers**: mode, workers, speed, capacity, when assigned and back.
7. **Timeline**, oldest first: Created, Carrier assigned, Loaded, Departed, Arrived at a stop, Delivered, Worker back,
   Completed (and Waiting for a worker, Waiting for room, Re-routed, Returning, Cancel requested, Cancelled), each with
   its message and a link to its stock transaction.

### 3.3 Making an order by hand

1. Press **New manual order** on the list, or **New order from here** on a structure's Transport panel (fills in its
   Output storage and the structure as carrier).
2. Pick the **Source storage**, optionally a **Carrier (empty: the source's own worker)** (a production structure; empty:
   the source's structure, else a simulated carrier without a worker), **Start after (empty: now)** and a **Note**.
3. Add stops (**Add a stop**), each with its storage and one or more items with amounts (**Add an item to stop <n>**).
   The source can't be a stop, and one storage can't be two stops. The problems list under the form says what is
   missing.
4. Press **Dry run**. The **Dry run** section says "The order can be made." or "The order can't be made." with the
   reasons, the warnings (less at the source than asked, no free worker, an estimated route, no room at a stop), the
   carrier, the cargo and trip time, a cargo table ("40 (short)") and a legs table.
5. Press **Make the order**. It is on only after a dry run of exactly this request without errors; change anything and
   dry-run again. "Transport order #<n> made." opens its page. A double click makes one order.

Limits: at most 10 stops and 50 items per stop; a worker carries at most its capacity ("The cargo is <n> units; a worker
of <name> carries at most <c>."). Loading takes what the source holds when the order starts; with less than asked the
first stops get theirs first.

### 3.4 Cancelling

On an order that is not done and not already returning, press **Cancel the order**, type a reason if you like, and
**Cancel the order now**:

1. Not loaded yet: "Nothing is loaded yet: the order ends Cancelled."
2. On the road or waiting at a stop: "The cargo is loaded: the carrier turns back and the order ends Returned." A
   carrier on the road comes back in the time it has walked so far.

A refusal (already returning, already done) shows the API's sentence.

Staff can also cancel, or **retry** an order, in game from a structure's transport orders menu (P6, #683/#74; see the
[storage terminals admin guide § 4](production-storage-admin-guide.md#4-the-structure-menus)). The retry is API and
game only: the web app has no button for it.

### 3.5 Full stops and full sources

Goods are never dropped:

1. A stop with too little room takes what fits; the order is **Waiting for room** and tries again every minute.
2. After 30 minutes (`awaitingSpaceMinutes`) it is **re-routed** to another warehouse of the town with room (at most
   2 re-routes per order, `maxReroutes`). With none, the carrier goes on to its next stop and brings back what is left.
3. Back at a full source the order is **Back, waiting for room at the source** until there is room. Take goods out of
   the source, and it finishes within a minute.

## 4. Automatic transport

### 4.1 When an order is made

The API checks every minute (with Production enabled). A structure with automatic transport on sends an order when its
Output storage holds at least its threshold, when one of its lines is **Blocked: output storage full**, or when the Output holds as
many different items as it may. The order takes the Output's largest stock first, up to one worker's capacity, to the
preferred or nearest warehouse of its town (warehouses with room first). A structure has at most one automatic order
under way at a time.

It is held while: production is off; its automatic transport is off; it is rural and not **Connected**; it has no town,
no Output storage, no workers or nothing to carry; or no warehouse of its town takes deliveries. With no worker present
the order is made and waits for one.

### 4.2 The structure's Transport panel

On a production structure's page, below the Yield panel:

1. **Transport warnings**: not connected to its town's road network (or not measured yet), the Output storage full, no
   workers, no warehouse, the preferred warehouse can't take it.
2. Automatic transport, Road connection, Output ("100 / 100 units", linked), Trigger at, "A worker carries 64 units",
   Workers ("1 of 2 present, 1 away carrying"), the warehouse it would go to.
3. **Automatic trigger now**: why it would send an order, why it is held, and **The order the trigger would make** (the
   plan, as in a dry run). Nothing is written by looking.
4. **Open orders**, "All orders of this structure" and **New order from here**.
5. **Lanes**: the structure's lanes with **Add a lane**.

Staff without `knk.admin.world` see no New order from here and no Add a lane.

## 5. Lanes

A lane is the road distance between two structures. The game server measures them (§ 7): every production structure to
every warehouse of its town, and a town's warehouses among themselves (for re-routes). A lane counts in both
directions. Without a lane a leg is the straight distance × 1.4, or 200 blocks without locations; the order's route says
so.

On the dashboard type **TransportLane** (columns From, To, Road distance, Straight, Source, Measured; "Unreachable" for
a lane without a road) or a structure's **Add a lane** you can type a lane in: From, To and the road distance (Source
Manual). Only one lane per direction (the same pair again is refused; edit it). A lane marked not reachable is never
used. Delete a lane to have the game server measure it again. A typed lane is never re-measured by the game server
unless you delete it, and it does not change a road connection.

## 6. Settings: the Transport card

**Game settings** › **Transport**:

| Field | Default | Meaning |
|---|---|---|
| Walking speed | 4.317 blocks/s | The trip time: route ÷ speed |
| Carrier capacity | 64 | What a worker carries when its structure and level set none |
| Trigger threshold (%) | 75 | Of a capped Output storage, when the structure sets none |
| Trigger for uncapped Output | 64 units | The same for an uncapped Output |
| Unmeasured route factor | 1.4 | Straight distance × factor without a lane |
| Fallback distance | 200 blocks | A leg without lane and locations |
| Wait at a full stop | 30 min | Before re-routing |
| Re-routes per order | 2 | 0-10 |
| Lane max age | 24 h | Measured lanes older than this are measured again |

A value out of range is shown under the field ("production.transport.maxReroutes must be a whole number between 0 and
10.") and Save is off. Saving another card sends these back unchanged.

**Run transport now** runs the API's check at once: makes the automatic orders due and moves every open order as far as
its times allow, then says "<n> orders created, <m> moved on." (and "<k> failed"). It is off while production is off
("Production is off: no order moves").

## 7. On the game server: lanes and road connections

With `production.enabled: true` the plugin's lane measurer reads the API's list of lanes to measure (missing or older
than the lane max age), measures each pair with the road router over the loaded road network, reports the lanes, and
sets each production structure's road connection: **Connected** with at least one lane on the road, **Unconnected** when
every lane it has is without a road. A structure more than 48 blocks from a road, or on roads that do not join its
town's, is without a road. Gates and regions don't block the measurement. A structure without a location, or in a world
without a loaded road network, is skipped: it stays on the list and keeps its road connection.

Keys in `config.yml` (restart to apply; [plugin configuration § 4.31](plugin-configuration.md#431-production)):

```yaml
production:
  enabled: true
  logistics:
    lanes:
      interval-minutes: 60     # 0 = only on /knk logistics lanes measure; first run 2 minutes after start
      batch: 100               # pairs per run (1-1000)
      max-snap-distance: 48    # blocks from a structure's location to the road
      road-connections: true   # also set the producers' road connection
```

The start log says "Lane measurer is on (production.enabled): every 60 min, 100 pairs per run, road connections on.".

Commands (`knk.admin.world.production`):

1. `/knk logistics lanes measure`: "Reading the lane list and measuring over the road network...", then the result:
   "Lanes (command by <you>, <n> s ago): 5 due, 3 reachable, 2 without a road, 0 skipped; API created 5, updated 0;
   road connections sent 2", up to ten lines per pair ("#12 Quarry → #20 North: 431.7 blocks by road", "… no road (#13
   is more than 48 blocks from a road)"), and "Structure #12 is now Connected" / "Structure #13 is now Unconnected: its
   automatic transport is held". With nothing due: "Nothing due: every lane is measured and fresh (or the API's
   production flag is off).". A second measure while one runs: "A lane run is already going; you'll hear its result.".
2. `/knk logistics lanes status`: "Lane measurer: every 60 min, 100 pairs per run; lanes known since start: <n>" and the
   last run's result (or "No run since the server started.").

The server log has every run under `[Lanes]`. With `production.enabled: false` both commands answer "Production is off
on this server (production.enabled: false).". Players without the node can't use them.

To set a road connection by hand (no game server, or a structure the measurer can't judge), use `PUT
api/ProductionStructures/<id>/road-connection` with `{ "roadConnection": "Connected" }`
([API contract § 4](../../specs/api/API_CONTRACT_PRODUCTION_TRANSPORT.md#4-put-apiproductionstructuresidroad-connection)).

## 8. A safe test

On a test server, with a town that has one production structure **Quarry** (in a district, so no road connection is
needed, two workers, an Output storage capped at 100) and one warehouse **North** with a delivery storage:

1. Switch Quarry's automatic transport off and pause its lines, so nothing moves on its own.
2. Put 50 Cobblestone into Quarry's Output storage (the storage's **Adjust**, needs `knk.economy.admin`).
3. **New order from here** on Quarry, stop 1 North's delivery storage, 40 Cobblestone, **Dry run**: "The order can be
   made.", one leg and its trip time.
4. **Make the order**, then **Run transport now** on the game settings page. The order is On the road; Quarry shows
   "1 of 2 present, 1 away carrying"; the cargo storage holds 40.
5. After the trip time press **Run transport now** again. The order is Delivered, North holds 40, Quarry 10, the worker is
   back. The stock reconciler (`GET api/StockTransactions/reconcile`) is clean.
6. Switch automatic transport back on when you are done; with the Output over its threshold the next check sends an
   order by itself.

The full checks are in the [smoke test § 6](../production-storage-transport-smoke-test.md#6-phase-p5-transport-core-simulated-79-api-681-plugin-682-web-app-tier3).

## 9. Effects on existing data

1. The migration adds tables only. No order exists until production runs or you make one.
2. **Automatic transport is on by default** for every production structure. Once production is enabled, every
   structure in a district whose Output is over its threshold gets an order within a minute, to the nearest warehouse
   of its town; switch it off on a structure first if you don't want that. Rural ones wait for their road connection.
3. While an order runs, its structure has a worker away and produces less.
4. Each order adds a cargo storage ("Transport #<id> cargo") and ledger rows (TransportLoad, TransportDeliver,
   TransportReturn). A structure whose storages took part in a transport can't be deleted (ledger history, 409).

## 10. Troubleshooting

| You see | Why | What to do |
|---|---|---|
| No automatic order although the Output is full | Read **Automatic trigger now** on the structure: held reasons | Fix the reason; for a rural structure measure its lanes (§ 7) |
| "Not connected to its town's road network" | The game server found no road within 48 blocks, or roads that don't join | Build a road to it, `/knk road reload`, delete its lanes, `/knk logistics lanes measure` |
| "Its road connection has not been measured yet" | The game server has not measured it (no plugin, `production.enabled` off, no location, no road network loaded) | Give it a location, check the plugin, `/knk logistics lanes measure` |
| Planned for a long time, "Waiting for a free worker" | All its workers are away carrying | Wait, or give it more workers |
| "Waiting for room" | The stop's storage is full | Make room, or wait for the re-route after 30 minutes |
| "Back, waiting for room at the source" | The source filled up while the cargo was away | Take goods out of the source |
| Cancelled "Nothing to load" | The source held none of the cargo when the order started | Put stock in and make a new order |
| A leg "(estimated …)" or "(fallback distance)" | No measured lane between those structures | Measure lanes (§ 7) or type one in (§ 5) |
| Run transport now refused (409) | Production is off | Turn it on |
| `/knk logistics lanes measure` "skipped, #<id> has no location" | The structure has no location | Set its location |
| "lane list not read: …" in the result | The API could not be reached or refused the key | Check `api.base-url` and `api.auth.api-key` |

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#891).
