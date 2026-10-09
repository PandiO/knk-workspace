# V2 production, storage and transport — legacy code and vision scan

**Status:** analysis (read-only). The V3 design that follows from it is
[specs/production-storage-transport/DESIGN.md](../specs/production-storage-transport/DESIGN.md).
**Last updated:** 2026-10-09
**Feature register rows:** "Resource gathering, production structures and town economy" and "Warehouses, storage and
transport orders" ([FEATURE_REGISTER.md](../FEATURE_REGISTER.md), World, travel and settlement).
**Code inspected:** `knk-v2-archive`, all remote branches (fetched 2026-10-09). Line numbers are from
`origin/2025/01/Hibernate-update` @ `b7592a0` unless a different ref is named. V3 references are knk-web-api `master`
(`Models/Structure.cs`, `Models/Domain.cs`, `Models/Item/*`, `Models/Currency/*`) and knk-plugin `main`
(`knk-core/.../roads/route/AStarRouter.java`, `paper/menu/`).
**Paths below** are relative to `src/main/java/net/knightsandkings/` in the V2 archive.

## 1. Summary

- V2 built a working pipeline: production structure → local storage → automatic transport order → warehouse. It is
  a concept-stage system with no gameplay layer. There are no owners, no player interaction beyond admin menus, and
  no consumers of the warehouse stock (no shops, no crafting).
- **Most of the code is not on `main`.** `main` @ `400e5c8` (2022-12-22) has only `Storage`, `Generation`,
  `Production`, `IProducer`, a chest-based `Warehouse`, and a `GenerationHandler` that is never started. The
  production structure, transport orders and schedulers live on the branch chain
  `2023/09/ProductionStructures` → `2023/12/LazyLoadingRemoval` → `2025/01/Hibernate-update` (§2). Earlier docs
  that call this "zero trace" or "on main" ([gap audit](LEGACY_VS_V2_GAP_ANALYSIS.md) lines 18-20,
  [towns-districts-gates.md](../specs/legacy/towns-districts-gates.md) line 33) looked at `main` only, or at V3.
- The data model is sound and maps well onto V3: a `Storage` with counted item rows and two caps, a timed
  `Generation` that yields into a storage, a `Production` subtype with input requirements, and a `TransportOrder`
  with order items and route nodes. The runtime has correctness bugs (§7): two infinite loops, silent item loss on
  overflow, lost updates between two concurrent timers, production drift, and main-thread database I/O.
- Transport in V2 is **simulated and instant**. The travel-time fields exist but are unused (the `wait()` call is
  commented out), and no NPC or cart moves. V1 had the physical side instead: a player courier minigame
  (`Minigames/Transport.java`) and a Citizens `CarrierTrait`, both disconnected from stock.
- The vision treats this system as the backbone of the economy (warehouses distribute to shops, inter-town trade,
  bandit risk on trade routes). It leaves ownership, town treasury and shop design open (§8).

## 2. Where the code lives (branch history)

| Ref | Tip | What it holds for this feature |
|---|---|---|
| `main` (= `ImprovedMenus`) | `400e5c8` 2022-12-22 | `Storage`, `Generation`, `Production`, `IProducer`/`IProducable`, `GenerationTypes`, chest-based `Structure` storage + `Warehouse`, storage menus, `/storage`. `GenerationHandler` is never instantiated, and `Generation`/`Production` are not registered in `HibernateUtil`. |
| `CreationArchitecture2` | `51e1591` 2023-10-26 | Fix for doubled storage additions (`StorageFillCommand`). |
| `2023/09/ProductionStructures` | `fc73101` 2024-01-07 | `ProductionStructure`, `TransportOrder`/`TransportOrderItem`/`TransportRouteNode`, all transport commands, `GenerationScheduler`/`TransportHandler`, `GenerationCommandListener`, `/generation`, `/test transportpreperation`, seed data. Last commit: "Added automatic transport functionality". |
| `2023/12/LazyLoadingRemoval` | `ce69ebc` 2025-01-04 | Contains the branch above. Through **`b8cd1e5` (2024-02-11)** it adds the DTO/HQL query layer, batch saves and the automatic transport loop ("Automatic handling of TransportOrder instances is achieved with high query efficiency"). `b8cd1e5` is the **last coherent, runnable snapshot**: `KNK.onEnable` starts `GenerationHandler` and `TransportHandler` (`KNK.java:342-343` at that ref). |
| `2025/01/Java21-HibernateRemoval`, `2025/01/Hibernate-update` | `61f239c`, `b7592a0` 2025-01-04/17 | Port to Java 21, Spigot 1.21.3 and Hibernate 6 (`@Any` discriminators, jakarta). `4f99eb5` ("Changes found from a long time ago") and `890292b` ("No idea if these changes work") reworked the generation and preparation DTOs. The schedulers are **commented out** (`KNK.java:341-342`). The tip message says "There still are many runtime errors". |

The feature is described from the newest tip, which holds the most complete design. Where behavior differs from the
runnable `b8cd1e5` snapshot, that is noted.

## 3. Domain model (entities)

All are Hibernate `@Entity`, JOINED inheritance where subclassed, MySQL. IDs are generated client-side
(`ICreatable.createId()`).

### 3.1 `Structure` (`model/dominion/Structure.java`), extends `Dominion`

| Field | Mapping | Notes |
|---|---|---|
| `district` | `@ManyToOne district_id`, nullable | Optional: "some structures are NOT located inside the boundaries of a town" (javadoc). |
| `town` | `@ManyToOne town_id`, nullable | Revived 2023-11-29 as a "ruling town" so wilderness producers still belong to a town and can find a warehouse (`@implNote`, lines ~95-105). `getTown()` returns `district.town` when a district is set, else `town`. |
| `street`, `streetNumber` | `@ManyToOne street_id` + column; unique together | |
| `storages` | `@OneToMany(mappedBy="structure")`, cascade ALL | "A Structure can for example have a Storage for storing resources used to upgrade the Structure's level, and another for other items" (javadoc). |
| `deliveryStorage` | `@OneToOne delivery_storage_id`, cascade ALL | Where transports deliver to; `getDeliveryStorage()` falls back to `storages.get(0)` (`Structure.java:476-484`). |

**Removed on the branch:** chest-based storage (`chests`, `capacity`, `capacityUsed`, `fetchChests`, `addChest`,
`storeItemStack`, `canStore`, the `ChestListChangeEvent` and `ConfirmSelectionEvent` handlers). On `main` this was
live: a Warehouse scanned its WorldGuard region for chest blocks and BlockListener kept the list current. The
developer's reason (commit `1dc1548`, 2021-08-17): "change Local Storage of Structure class from physical chests to
database tables → easier to make partitions (KNK-36), high probability the server will experience less payload".

### 3.2 `Warehouse` (`model/dominion/Warehouse.java`), extends `Structure`

No extra persistent fields. Creation wizard stages: district (required), street, street number, region (WorldEdit
selection → region `warehouse_<id>`, priority 12, `INTERACT allow`), location. The menu lore shows capacity used,
capacity total and percentage (left over from the chest version). Seed: "Docks Warehouse", Cinix, storage of 2,600
items / 12 unique (`data/TestWarehouse1.java`).

### 3.3 `ProductionStructure` (`model/dominion/structure/ProductionStructure.java`), extends `Structure`, implements `IProducer`

This is the "structure child class for resource production".

| Field | Default | Meaning |
|---|---|---|
| `override` | false | If true, the structure's `autostart` overrides each Generation's own `autoStart` (`IProducable`). |
| `autostart` | true | Structure-level autostart (used only when `override`). |
| `producerObjects: List<Generation>` | — | `@OneToMany(mappedBy="producerDominion")`, cascade ALL. |
| `nearestWarehouse` | null | Cached result of the nearest-warehouse search (`nearestWarehouse_id`). |
| `preferredWarehouse` | null | Chosen destination (`preferredWarehouse_id`). |
| `warehousePreference` | `NEAREST` | Enum `NEAREST`, `PREFERRED`, `CUSTOM`. `CUSTOM` is treated as `NEAREST` (`TransportPreperationCommand.java:228-235`). |
| `automaticalTransport` | true | Column default 1. Declared, but **never read**: the listener ignores it (§5.2). |
| `transportThreshold` | 25 | "percentage of storage capacity that needs to be reached in order for the PS instance to start transporting" (javadoc, line 91). |
| `transportOrder` | null | `@OneToOne(mappedBy="structure")`, the open order. |

`createInstance` (lines 268-327) creates the region `productionstructure_<id>` and one Storage (capacity 240,
1 unique item). It also creates one `Generation` with the chosen Item as commodity, `yieldPerDelivery` = the typed
"amount per hour", `PUT_IN_STORAGE` and autostart. The creation stages add "commodity" and "genPerPeriod" to the base
Structure stages. Seeds: **Coal Mine** (8 per hour, storage 240/1) and **Stone Quarry** ("generates stone, and some
iron ore as byproduct": stone 12/h + iron 2/h, storage 680/4) (`data/TestStructure1.java`, `TestStructure2.java`).

### 3.4 `IProducer<G extends Generation>` / `IProducable`

`IProducer` javadoc: "adds the framework for other classes to produce a certain amount objects in specified periods
of time… Items (a coal mine produces a certain amount of coal items per hour), but other objects can also be
produced. Think of gold, gems, NPC's (soldiers)". Methods: productions get/set/add/remove, `isAutostart`,
transport threshold, production location, transport order. `IProducable` holds `override` and `autostart`.
`IProducerConverter` (Hibernate `AttributeConverter`) casts between `IProducer` and `IPersistent`.
`Generation.producerDominion` stores the producer as a `Dominion` FK because "the IProducer interface cannot be
stored by hibernate" (`Generation.java:64-65`).

### 3.5 `Generation<T extends IPersistent>` (`model/dominion/structure/Generation.java`)

A timed yield with no inputs ("doesn't require anything else than time").

| Field | Notes |
|---|---|
| `producerDominion` / transient `iProducer` | Owner. |
| `commodity: T` | Hibernate `@Any` with discriminator values `Item`, `Structure`, `Warehouse` (`:83-91`). In practice only `Item` is supported: `PUT_IN_STORAGE` requires an Item commodity. |
| `yieldPerDelivery` (int, ≥1) | Amount per cycle (formerly `genPerPeriod`). |
| `deliveryPeriodVal` (double, >0), `timeVal` (int, a `java.util.Calendar` field constant, default `HOUR_OF_DAY`) | Cycle length = `deliveryPeriodVal` × unit. The double is rounded to an int when applied (`GenerationUtil.getNextDelivery`). |
| `lastDeliveryDate: Calendar` | Anchor for the next cycle. |
| `autoStart`, `generating` | `generating` is the "active" flag. |
| `deliveryType` | `GenerationDeliveryType` `PUT_IN_STORAGE` or `SPAWN_ON_GROUND` (renamed from `GenerationTypes` on 2024-02-11). |
| `exceptions: Map<Calendar,String>` | Error log per generation (`GenerationExceptions` table). |
| `storage` | Output storage (for `PUT_IN_STORAGE`). |

The `doTick()` per-second loop from `main` is commented out (`:422-448`), replaced by the batched
`HandleGenerationCommand` (§5.1).

### 3.6 `Production<T>` extends `Generation<T>` (`Production.java`)

Adds `requirements: Map<Item,Integer>` (`ProductionRequirements` table, unique `production_id,item_id`):
"The requirements are required for every 1 object of the commodity produced" (`:39`). `addRequirement` and
`removeRequirement` merge amounts. **No code consumes the requirements.** `GenerationCommand` never checks or
deducts inputs, and `ProductionCache.getProductionsByRequirement` is the only reader. This is the unbuilt
"use resources to produce other items" step.

### 3.7 `Storage` (`model/dominion/structure/Storage.java`)

Javadoc: "stores items with their corresponding amount for users and structures… Knights and Kings needs additional
functionality… such as enlarged max. capacity, filtering, partitioning etc."

| Field | Default | Notes |
|---|---|---|
| `name` | "Storage" | |
| `structure` / `user` | — | One owner: a Structure or a User. The User path is "not supported yet" in creation or menus. |
| `itemAmountMax` | 999 | Max **distinct** items. |
| `capacityMax` | 999,999 | Max **total** count. Counts are raw; there is no stack-size weighting, unlike the chest-era `ChestUtil`, which weighted 16-stack items as 4×. |
| `storageItems: Map<Item,Integer>` | — | `StorageItems(storage_id, item_id, amount)`, unique per pair. |
| `capacity`, `itemAmount` | transient | Recomputed in `setStorageItems` when loading. |

Rules (`addStorageItem` `:381-413`, `removeStorageItem` `:465-485`):

- Adding a new distinct item when `itemAmount ≥ itemAmountMax` throws `UniqueItemCapacityException`.
- Adding when full throws `CapacityException(overflow = amount)`. Exceeding the max throws
  `CapacityException(overflow = amount − free)`, and nothing is added.
- Removing an absent item throws `StorageException`. Removing more than stored throws
  `CapacityException(overflow = shortfall)`, and nothing is removed.
- Callers loop and retry with `amount − overflow`, which turns the all-or-nothing method into "as much as fits".

`StorageDTO` (`dal/dto/storage/StorageDTO.java`) repeats the same rules on a detached snapshot. Each
`StorageItemDTO` carries a `PersistStrategy` (`SAVE`/`UPDATE`/`DELETE`) so `StorageDAO.saveStorageDTO` can write
only the changed rows.

### 3.8 Transport model (`model/dominion/structure/transport/`)

**`TransportOrder`.** Javadoc: "created and executed in order to transport items from one storage object to
another."

| Field | Notes |
|---|---|
| `structure` | `@OneToOne` ProductionStructure (the sender). |
| `destinationList: List<TransportRouteNode>` | "the transportOrder should be able to deliver to multiple destinations" (`:54-56`). |
| `transportOrderItems: List<TransportOrderItem>` | |
| `waitingTimePickup` (5), `simulatedTravelTime` (10) | "artificial travel time between the pickup locations" / "between the last pickup location and the destination(s)… when there is no NPC that needs to physically walk" (`:77-88`). Units are implied seconds. **Unused.** |
| `executionStyle` | `ExecutionStyles.IMMEDIATELY` (default) or `PLANNED` (the enum also has `UNEXECUTE_ON_EXCEPTION`, `CONTINUE_ON_EXCEPTION`). |
| `executionDate`, `executed`, `executedDate` | |
| `transportNPC` | Commented out: "Hibernate still wants to load the class definition while being transient" (`:69-74`). This was the planned Citizens NPC carrier. |

**`TransportOrderItem<T>`.** `commodity` (`@Any`), `amount` (planned), `amountReceived` (picked up),
`amountDelivered`, `transportSource: Storage`, `generation`, `order` (list position).

**`TransportRouteNode<Node extends Structure>`.** `node` (`@Any`, Structure or Warehouse), `transportOrder`,
`order`. Delivery goes to `node.deliveryStorage`.

### 3.9 Database tables

On a Hibernate JOINED schema (V2 naming): `Dominion`, `Structure` (+`town_id`, `delivery_storage_id`), `Warehouse`,
`ProductionStructure`, `Storage`, `StorageItems`, `Generation`, `GenerationExceptions`, `Production`,
`ProductionRequirements`, `TransportOrder`, `TransportOrderItem`, `TransportRouteNode`. There are no indexes beyond
PKs and the two unique constraints.

## 4. Supporting infrastructure

- **Command pattern** (`command/Command.java`): `Command<T> implements Callable<T>, Runnable`, with `execute` and
  `unExecute` (undo), a status log (`StatusType`: `PENDING`, `EXECUTING`, `EXECUTED`, `UNEXECUTING`,
  `UNEXECUTED`), and `log()` messages. Every step in this feature is a Command, which gives undo for free in
  principle. Several `unExecute`s are no-ops or incomplete (§7).
- **Repository/cache/DAO layer:** `RepositoryManager` → `Repository` (cache + DAO). Feature-specific:
  `StorageDAO` (`getStorageDTOById`, `saveStorageDTO`), `GenerationDAO` (`getHandleGenerationDeliveryCheckDTOList`,
  `getObjectsForHandling`, `saveGenerationDTOList`), `ProductionStructureDAO` (`getProductionStructureTransportPreperationDTO`:
  structure, warehouses in town, generations and storages in four queries), `TransportOrderDAO` (date-check list,
  DTO load in three queries, batch save), `StructureDAO.getStructureIdsByDistricts`. The repositories are
  `GenerationRepository`, `ProductionStructureRepository`, `TransportOrderRepository`, `StructureRepository`, and
  the caches are `StorageCache`, `GenerationCache`, `ProductionCache`.
- **DTOs** (`dal/dto/**`): `HandleGenerationDTO`, `HandleGenerationCheckDTO`, `HandleGenerationDeliveryCheckDTO`,
  `GenerationTransportPreperationDTO`, `ProductionStructureTransportPreperationDTO`, `StorageDTO`/`StorageItemDTO`,
  `HandleTransportOrderDTO`, `TransportOrderItemDTO`, `TransportRouteNodeDTO`, `TransportOrderExecutableCheck`,
  `ItemCommodityDTO`, `StructureDTO`, `DominionDTO`. In early 2024 the developer cut query volume by projecting
  `select new …DTO(…)` instead of loading entity graphs (commits `09ffd8e` … `7798263`).
- **Exceptions** (`exceptions/dominion/`): `StorageException` (runtime), `CapacityException(overflowCount)`,
  `UniqueItemCapacityException` (renamed from `UniqueItemException`), `TransportExecutionException`.

## 5. Runtime flows

### 5.1 Production tick (`scheduling/GenerationHandler` → `command/generation/HandleGenerationCommand` → `GenerationCommand`)

1. `GenerationHandler.getInstance()` (enabled at `b8cd1e5`) starts an **async** Bukkit timer every
   `taskDelay` = 120 s.
2. `HandleGenerationCommand.performExecute` (`:107-149`) loads `HandleGenerationDeliveryCheckDTO`
   (`id, generating, autoStart, producer.override, lastDeliveryDate`) for **every** generation with
   `lastDeliveryDate < now`, which is all of them.
3. Inactive generations: if `autoStart && !override || override && autoStart` and the output storage has room,
   it sets `generating = true` in memory. Otherwise it drops them (`:64-84`).
4. It loads `HandleGenerationDTO`s for the remaining ids, then runs a `GenerationCommand` per generation on a
   2-thread pool, one at a time (`future.get()` in the loop).
5. `GenerationCommand.performExecute` (`:113-202`):
   - It skips if `lastDeliveryDate + period > now`.
   - `SPAWN_ON_GROUND`: drops `yield` items at the producer's location on the main thread (an Entity commodity
     would be spawned via NMS).
   - `PUT_IN_STORAGE`: loads `StorageDTO`, adds `yield` in a retry loop, and saves with `saveStorageDTO`.
   - It sets `lastDeliveryDate = now`. This is the drift bug: it does not add one period to the old anchor.
   - It fires `GenerationCommandEvent` on the main thread.
6. Batch save: `saveGenerationDTOList(completed)` updates `lastDeliveryDate` and `generating` for completed rows.

### 5.2 Automatic transport order creation (`listeners/GenerationCommandListener`)

On each `GenerationCommandEvent` (main thread):

1. It messages every subscriber (`/generation updates sub`) with `"Generated <item> <n> times. Output to storage (<id>)."`.
2. It computes `capacityPercentage = storage.getCapacity(commodity) / storage.capacityMax × 100`, which is **per
   commodity**, against the total capacity (`:86-88`).
3. If that is ≥ `transportThreshold`: it fetches the open (unexecuted, `PLANNED`/`IMMEDIATELY`) order for the
   producer. It runs `TransportPreperationCommand(producer, existingOrder, generation)` with
   `PLANNED, now + 5 min`, saves the order, evicts it from the cache, and saves the producer. All of this is
   synchronous on the main thread.
4. It does not check `automaticalTransport`.

### 5.3 Transport preparation (`command/transport/TransportPreperationCommand`)

1. It takes the producer's generations, or only the selected ones, and the map generation → storage.
2. It builds a `TransportOrderItem` per generation whose commodity is not already on the order ("Currently I am not
   sure if and how I wish orderItem instances will merge… For now I will skip merging", `:213-215`).
   - Planned amount = `TRANSPORT_CAPACITY_MAX (128) / number of generations`: a fixed cart size split evenly,
     regardless of actual stock.
3. Destination: by `warehousePreference`, `nearestWarehouse` or `preferredWarehouse`. If that is null, it runs
   `RetrieveNearestWarehousesCommand`:
   - It takes the producer's (ruling) town and all structure ids in the town's districts.
   - It loads each one by id and keeps the Warehouses, an N+1 query.
   - It picks the smallest straight-line `distanceSquared` to the producer's location.
   - It caches the result in `nearestWarehouse` with `SaveMode.ONLY_CACHE`, so the cache is never persisted and
     never invalidated.
4. It appends a `TransportRouteNode(destination)` if the destination is new, or creates a new
   `TransportOrder(nodes, items, producer)` with the execution style and date.

### 5.4 Transport execution (`scheduling/TransportHandler` → `HandleTransportCommand` → `TransportExecutionCommand`)

1. An async timer every 120 s (`TransportHandler`, enabled at `b8cd1e5`).
2. `HandleTransportCommand` loads `TransportOrderExecutableCheck` for all `executed = false` orders. It keeps
   `IMMEDIATELY` orders and `PLANNED` orders whose date has passed, then loads `HandleTransportOrderDTO`s
   (order + route nodes + items) in three queries.
3. Per order, `TransportExecutionCommand.performExecute` (`:86-154`):
   - **Pickup:** a `PickupOrderItemCommand` per item, in list order. It removes up to `amount` from the source
     storage (retry loop down to the available stock), sets `amountReceived`, and saves the source storage.
   - **Delivery:** a `DeliverTransportItemsCommand` per route node, in list order. It adds `amountReceived` per
     item to the node's `deliveryStorage` (retry loop) and saves it.
   - `simulatedTravelTime`/`waitingTimePickup` are not applied ("Wait method cannot be used: It throws…
     IllegalMonitorStateException", `:110-113`).
   - It marks the order executed and clears `producer.transportOrder` (cache only).
4. Batch save of executed orders (`saveTransportOrderDTOList`) plus `Storage.saveAll()`.

`HandleTransportationCommand` (`command/`) is an unused older scaffold.

### 5.5 Admin storage editing (menus)

- `StorageOverview` / `StorageOverviewSection`: storage details plus a contents grid ("Item: name", "Amount: n",
  stack size = amount). A "Storage actions" dropdown → "Add items to storage" opens `SelectObjectMenu` over all
  Items with amount steppers. On confirm, a `StorageFillCommand` runs per selection and the overview refreshes.
- `StorageAddMenu` + `StorageAddItem`: a stepper item. Left/right click add or remove `step`; shift-left/right
  doubles or halves the step (doubling past 128 wraps back to 1). The confirm item shows "Storage cap. after adding". The expected-use
  calculation is stubbed (`getExpectedStorageUse()` returns 0).
- `ChestFillSelect`: a `CachableSelect` variant that adds to chests, a structure or a storage. Its `getEvent()`
  runs `StorageFillCommand` for **only the first** selected item (`getResult().get(0)`), then fires
  `ConfirmSelectionEvent` with the storage. On `main`, `SelectionListener` then processes that event as well
  (the doubled-amount bug) and reads `getSelectionMap()`, which that constructor leaves null, so it throws an NPE.
  On the branch, the event return is commented out (fix `51e1591`).
- `ChestOverview` (main only): lists a structure's chests, with capacity bars, and opens a chest on click.
- `ProductionStructureMenu` (`menu/preset/menu/dominion/structure/`): details plus dropdowns "Click to show
  Storages" and "Click to show Productions". It is opened from `RepositoryDetails` when browsing repositories.
- `CachableDetail` (main): "Set new LocalStorage" header item on any Structure without storages
  (`createLocalStorage`, 999 unique / 999,999 capacity).

These menus are reachable only through debug and repository browsers, not from gameplay
([inventory-menu-screens.md](../specs/legacy/inventory-menu-screens.md) lines 534-548).

## 6. Commands, events and permissions

| Kind | Name | Where | Behaviour |
|---|---|---|---|
| Player cmd | `/storage list\|fetch\|save\|remove\|edit` | `spigot/command/dominion/structure/StorageCommand.java` | CRUD + creation wizard; perm `k&k.storage.<sub>` ([commands-v2.md](../specs/legacy/commands-v2.md) §`/storage`). |
| Player cmd | `/generation updates sub\|unsub` | `spigot/.../GenerationCommand.java` | Subscribe to generation messages. Perm typo `k&k.generationupdates` (missing dot). |
| Player cmd | `/test transportpreperation` | `spigot/command/TestCommand.java:38-133` | Prepares, executes and immediately undoes a transport order on the newest ProductionStructure (developer smoke test). |
| Player cmd | `/dominion list\|fetch\|save\|remove\|edit\|resetflags` (Structure) | `StructureCommand.java` | Declared with `@CommandAlias("dominion")`, which **collides** with `DominionCommand`. Its `k&k.structure.*` perms are in `plugin.yml`. |
| Internal cmd | `GenerationCommand`, `HandleGenerationCommand`, `StorageFillCommand` (ADD/REMOVE, undoable), `TransportPreperationCommand`, `RetrieveNearestWarehousesCommand`, `TransportExecutionCommand`, `PickupOrderItemCommand`, `DeliverTransportItemsCommand`, `HandleTransportCommand` | `command/**` | §5. |
| Custom event | `GenerationCommandEvent` (extends `CommandEvent<GenerationCommand>`) | `event/command/` | Fired after each successful generation; carries the generation DTO, commodity, amount and storage DTO. Message templates `MESSAGE_DEF_1/2`. |
| Custom event | `ChestListChangeEvent` (ADD/REMOVE/UPDATE) | `event/dominion/structure/` | Chest era (main): recomputes a structure's chest capacity. Dead on the branch. |
| Custom event | `ConfirmSelectionEvent<T,K>` | `event/` | Generic menu-selection confirm. It carries a storage, structure or chests. Handled by `SelectionListener` (adds to storage) and, on main, `Structure.onConfirmation` (stores into warehouse chests). |
| Bukkit listener | `GenerationCommandListener` | `listeners/` | §5.2. |
| Bukkit listener | `BlockListener.onBreak`/`onPlace` | `listeners/` | Main: keeps a warehouse's chest list current when chests are placed or broken. Branch: the warehouse lookup remains, but its result is unused. |
| Bukkit listener | `SelectionListener.onConfirmation` | `listeners/` | Adds the selection to a storage asynchronously. On `main`, the menu-built event has a null `getSelectionMap()` (NPE). On the branch, no menu fires a storage-carrying event any more, so this path is dead. |
| Scheduler | `GenerationHandler`, `TransportHandler` (120 s async), `GenerationScheduler` (an unused `java.util.Timer` stub) | `scheduling/` | §5. |
| Tab completion | `@storageids`, `@storages` | `KNK.java:692-702` | |

## 7. Defects and weaknesses found

Severity: **H** = loses or duplicates items or hangs a thread; **M** = wrong result or scaling problem;
**L** = cosmetic or dead code.

| # | Sev | Where | Problem |
|---|---|---|---|
| 1 | H | `GenerationCommand.java:166-180`, `DeliverTransportItemsCommand.java:98-112`, `PickupOrderItemCommand.java:97-111` (undo) | `while (amount > 0)` catches `UniqueItemCapacityException` without changing `amount`, so it **spins forever** on the async thread once a storage hits its distinct-item cap. |
| 2 | H | `DeliverTransportItemsCommand` | When the destination is full, the overflow is subtracted and dropped. Items already picked up from the source **disappear**. `amountDelivered` is overwritten, not accumulated. |
| 3 | H | `TransportExecutionCommand.java:116-120`, `DeliverTransportItemsCommand` | Multiple route nodes: `division` is stored but never applied, so **every node receives the full picked-up amount** (duplication). |
| 4 | H | `StorageDAO.saveStorageDTO` | Writes absolute `SET amount = <snapshot value>` from a detached DTO. Generation and transport run on two independent async timers (plus menu edits), so concurrent writers overwrite each other (**lost update**). Pickup and delivery commit in separate transactions, so a crash between them loses the cargo. |
| 5 | M | `GenerationCommand.java:188` | `lastDeliveryDate = now` instead of `+ period`, so production drifts by up to one tick (≤120 s) each cycle. After downtime only one cycle is paid. When the storage is full, the cycle is consumed and the production is silently lost. |
| 6 | M | `GenerationCommandListener` | Runs DB reads and writes on the **main thread**. It iterates the `subscribers` set while removing from it (`ConcurrentModificationException`). `Bukkit.getPlayer(uuid).sendMessage` NPEs for an offline subscriber. A failed preparation leaves `order == null`, so `saveObject(null)` throws. |
| 7 | M | Threshold rule | Per-commodity share of total capacity. With several commodities in one storage (Stone Quarry), the storage can be 100% full while no single commodity reaches 25%, so **transport never triggers** and production stops. |
| 8 | M | `TransportPreperationCommand` | Order size is fixed at `128 / generations`, regardless of stock or demand. Existing items are never topped up. `automaticalTransport` is never read. `CUSTOM` preference is ignored. |
| 9 | M | `RetrieveNearestWarehousesCommand` | N+1 loads. Straight-line distance ignores roads and walls. The cached `nearestWarehouse` is never persisted or invalidated (a new or removed warehouse is not noticed). It throws if the producer has no town. |
| 10 | M | `GenerationDAO.getHandleGenerationDeliveryCheckDTOList` | Selects every generation every 120 s and filters the due time in Java. It does not scale and has no index on the due time. |
| 11 | M | Transport | Instant: travel and wait times are not applied, so the order is a teleport. No in-transit state is visible. Nothing can intercept, escort or delay it. |
| 12 | M | `Production.requirements` | Never enforced, so "production from inputs" does not exist at runtime. |
| 13 | M | `GenerationCommand` | `yieldAmount` is never set, so `unExecute` removes nothing. The undo path of `HandleGenerationCommand` is therefore broken. |
| 14 | L | Design | `@Any` polymorphic commodity (Item/Structure/Warehouse) with no use beyond Item. `Calendar` plus int unit constants for durations. Client-side id generation. Two-flag `override`/`autostart` logic that is hard to reason about. Exceptions used for normal capacity control flow. |
| 15 | L | Commands | `StructureCommand` alias collides with `/dominion`. Perm typo `k&k.generationupdates`. `/test transportpreperation` has no `plugin.yml` entry. |
| 16 | L | Menus | `ChestFillSelect` processes only the first selection. `SelectionListener` NPE (`selectionMap` null) on `main`. `StorageAddMenu.getExpectedStorageUse()` returns 0. Leftover chest-era lore on Warehouse (`getCapacityUsed`). |
| 17 | L | Notifications | When a storage is full or a transport fails (no warehouse), nobody is told. V1 had `StorageEvent` → "storage is full" owner message ([events-v1.md](../specs/legacy/events-v1.md) line 2046+). |

## 8. What the vision and V1 add

Full sweep with line references: vision `docs/vision/vision.md`, concept `archive/vision-history/concept-v0.2-2020.md`,
raw notes `vision/source-notes-iphone.md`, and legacy reports in `specs/legacy/`. Highlights relevant to design:

- **Structure types (decided, vision §2.5):** "a single `Structure` base class with one concrete subclass per
  functional type (Gate, Warehouse, Shop, House, Keep, Tavern, Resource-Property, Non-functional, …)… Cross-cutting
  capabilities… (e.g. 'can be produced from,' 'can be owned') are interfaces layered on top". V2's
  `ProductionStructure` + `IProducer` is exactly this shape.
- **Territory yield (long-term, §2.3):** `resourceYield`, "resource types + base yield rate, modifiable by whoever
  controls the territory (tech-tree bonuses, structures built within it)".
- **Town minimum (concept L133-144):** every town has "2 resource production structures, 1 warehouse, 3 shops".
  Towns are resourced by geography (iron/wood-rich vs fish/wheat-rich). "Resource-producing structures outside the
  town proper connect back via paths."
- **Catalogue (concept L148-158):** resource producers are Lumberyard, Mines, Quarry, Farm and Fishing docks.
  "Warehouses: storage/distribution structures."
- **Warehouses (concept L168):** "town-owned storage/distribution hubs; collect and distribute resources to shops,
  enable inter-town trade agreements, and accept player item sales. Unmanaged, they distribute stock evenly by
  predefined percentage; once a clan rules the town, the clan sets distribution percentages in weekly councils."
- **Shops (concept L164-166):** "stock/prices vary with supply from warehouses"; local storage, crafting orders,
  levels gated by donated resources.
- **Scalability (vision §4.1, candidate 2):** "Decouple storefront from production capacity for shops… the
  production/stock capacity becomes a separate, queueable ownable resource (EVE Online-style)."
- **Ownership (vision §4.5, open):** single vs multi-owner for shops and resource-production structures is
  undecided. The developer's notes say the hard part is "the custom stock and upgrade level of the structure".
- **Resource-properties pay coins and materials** (iPhone note L92): "naast coins ook grondstoffen… zelf houden als
  eigenaar of automatisch verkopen" (besides coins, also raw materials, which the owner can keep or sell
  automatically).
- **Transport as gameplay:** "On fullchestEvent spawn an NPC with the Carrier trait" (L163-164). Transport quests
  where other players can steal the chest (L268-272). Travel time = average speed × road distance + terrain
  modifier (L282). Ambush probability "voor spelers en trade routes" (for players and trade routes) (L297-298).
  Trademaster/Transporter profession (concept L229, notes L284).
- **V1 implementation** (`knk-v1-archive`): resource-properties with mining categories and block regrowth
  (`Resources/*`, mining gate unreachable due to a bug); chest-backed property and warehouse storage
  (`Property.fillWarehouse`, `getFullChest`); a "storage full" owner notice (`StorageEvents`); the courier
  minigame `Minigames/Transport.java` (empties the property chests into the player, random warehouse in the nearest
  town, kill-the-courier bounty broadcast, commission = Σ priceMin × amount / 5); `Traits/CarrierTrait.java` (NPC
  walks to a warehouse, ignores roads); daily shop stock and weekly prices (`PropertyProduct`).

## 9. V3 starting point (what already exists)

| Concern | V3 today |
|---|---|
| Structure entity | `Structure : Domain` (TPT) with required `StreetId`, `HouseNumber`, required `DistrictId`. Only subtype: `GateStructure`. No owner, no storage, no ruling town. [KNG-47](https://linear.app/kngpandi/issue/KNG-47) tracks subtypes. |
| Items | `ItemBlueprint` (stackable catalogue entry, `MaxStackSize`, `BasePriceMin`/`Max`, `Category`, `Grade`, `Origins` → Domain). `ItemInstance` only for non-stackables, so stored resources are counted per blueprint. |
| Currency | Double-entry ledger (`CurrencyTransaction`/`CurrencyEntry`), account kinds `User` and `System` only. Shops and production payouts are out of its scope and will call `SpendAsync`/grant APIs with new reason codes. |
| Background jobs | `BackgroundService` precedent in the API: `RankExpirySweepService` (30 s), `CurrencyMonitorService`, `RetentionPolicyService`. |
| Roads | Road graph in the API (`RoadNode`/`RoadEdge.Length`, `CostMultiplier`). A* routing lives in the plugin (`knk-core/.../roads/route/AStarRouter.java`). NPC routing is out of scope until KNG-36. |
| Regions | Managed WorldGuard kind `RESOURCE_PRODUCTION`; the logs-only break rule is open ([KNG-48](https://linear.app/kngpandi/issue/KNG-48)). |
| Menus | Data-driven menu engine with `MenuFeature` content sources (`paper/menu/`). Deposit slots (G2) and click-type steppers (G3) are not built. |
| Item delivery to players | `BlueprintItemAssembler` (one item render path), kit grant/placer, lootbox delivery: reusable for "withdraw from storage". |

## 10. Verdict for V3

Reusable **almost 1:1** (concept and shape): Storage with counted rows and two caps; Warehouse and
ProductionStructure as Structure subtypes; timed yield into a storage; Production inputs; the threshold-triggered
automatic transport order with planned execution; the order/item/route-node structure with
planned/received/delivered amounts; nearest/preferred warehouse; `deliveryStorage`; the admin overview and add-items
menus; subscription-style staff notifications.

**Change on the way in:** server authority (API owns all stock mutations, atomic and ledgered), due-time scheduling
with catch-up instead of drift, a real in-transit phase with travel time from road distance, the overflow and
duplication fixes, an occupancy-based threshold, stock-based order sizing, typed commodities (ItemBlueprint), and
no main-thread I/O.

**Drop:** chest-scanning storage (already dropped by the developer), `@Any` commodities, `SPAWN_ON_GROUND`
(deferred, not ported), Calendar unit constants, client-side ids, and the generic undo machinery as a persistence
strategy. Database transactions replace it.

The V3 design, decisions and phases are in
[specs/production-storage-transport/DESIGN.md](../specs/production-storage-transport/DESIGN.md) and
[IMPLEMENTATION_PLAN.md](../specs/production-storage-transport/IMPLEMENTATION_PLAN.md).
