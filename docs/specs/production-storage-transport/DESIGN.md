# Production, storage and transport — Design

**Status:** Draft, **rev. 2**. Rev. 2 takes in the developer's 18 notes of 2026-10-09 (listed in the revision
history). The decisions in §14 are open; each one has a recommendation. Nothing is implemented.
**Last updated:** 2026-10-09
**Companion documents:**
- [PRODUCTION_KINDS.md](PRODUCTION_KINDS.md): farms, loggers, quarries, mines, fisheries, flower farms and florists,
  animal farms, hunters. Covers yield areas, surveys, levels, player harvesting and block regeneration.
- [TOWN_LOGISTICS.md](TOWN_LOGISTICS.md): warehouses as hubs, distribution and saving rules, inter-town trade and
  the pricing hook.
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

**Evidence:** [reports/2026-10-09-v2-production-storage-transport-scan.md](../../reports/2026-10-09-v2-production-storage-transport-scan.md)
covers the V2 code on all branches, the vision and V1. "V2 defect n" refers to scan §7.
**Linear:** [KNG-83](https://linear.app/kngpandi/issue/KNG-83) is the parent. The phase and follow-up issues are
listed in the implementation plan.
**Related:**
- [KNG-47](https://linear.app/kngpandi/issue/KNG-47): Structure subtypes.
- [KNG-48](https://linear.app/kngpandi/issue/KNG-48): block-break in resource regions.
- [KNG-36](https://linear.app/kngpandi/issue/KNG-36): NPC platform.
- [navigation](../navigation/DESIGN.md): roads.
- [currency](../currency-payments/DESIGN.md): ledger patterns and payments.
- [items](../items/IMPLEMENTATION_PLAN.md): `ItemBlueprint` and `ItemInstance`.
- [lootboxes](../lootboxes/DESIGN.md): reward delivery.

**Revision history**

- **Rev. 1 (2026-10-09, morning):** V2 port with fixes. Storage, production lines, simulated timed transport.
- **Rev. 2 (2026-10-09, developer notes 1-18):**
  - The system is the **backbone** of many gameplay features (2).
  - Transport is meant to be **physical**: NPCs or players carry the goods, and the goods can be robbed, escorted or
    tied to quests. Simulation is only the first step (1, 17).
  - Storage is a **general capability**: player, clan and domain storage, including a private inbox for rewards a
    player can't receive right now (3).
  - Optional **sync with in-game containers** (4, 5).
  - The **domain model is redesigned** to current practice (6).
  - **Production kinds** with yield areas and derived yields (7, 8).
  - **Every item is an ItemBlueprint** (9).
  - **Web app first** for admin, with debug and insight tools (10).
  - **Production and shop level systems** (11, 12).
  - **Player harvesting** in yield areas (13) and **block regeneration** (18).
  - **Territory** and road connection for rural producers (14).
  - **Warehouses as distribution hubs** with town rules and trade (15).
  - **Supply-and-demand pricing** (16).

## 1. Role and scope

Resource production, storage, transport, distribution and processing form one network. It is a **backbone** for
much of the game (note 2):

- shops get their stock and prices from it;
- quests come out of transports (escort, rob, deliver);
- clans and kingdoms gain or lose power through supply routes and raids;
- town management sets distribution, reserves and trade;
- professions and skills unlock harvesting and processing;
- siege and conquest can cut supply lines.

Other features plug into it, so the core must be general and stable from the start.

This design fixes the **core model and its rules**:

- the stock model;
- storage owners and containers;
- production;
- transport orders and their execution modes;
- distribution hooks;
- item identity;
- admin and insight tooling.

The detailed gameplay of each production kind is in [PRODUCTION_KINDS.md](PRODUCTION_KINDS.md). Town rules and
pricing are in [TOWN_LOGISTICS.md](TOWN_LOGISTICS.md). Shops, professions, the knowledge system and the
ownership/payout model have their own future designs. This document defines only the interfaces they use.

## 2. Principles

1. **One source of truth for stock: the API.** Every quantity change is a database transaction in knk-web-api. The
   plugin, NPCs, players and in-game containers act through it (§5). This is the rule the currency ledger already
   follows ([currency DESIGN](../currency-payments/DESIGN.md) §3).
2. **Inventory as double-entry stock moves between locations.** Industry inventory systems (ERP warehouse
   management, e.g. Odoo's `stock.location`/`stock.quant`/`stock.move`) never "add" or "remove" stock. They **move**
   it from one location to another, and use virtual locations for production, consumption, transit, loss and
   adjustment.
   - V3 does the same, mirroring its own currency ledger: currency `System` accounts are the virtual storages here.
   - So "goods in transit", "goods stolen" and "goods produced" are all the same operation.
   - Every item is accounted for at every moment, and reconciliation is a sum (§4.3).
3. **Physical gameplay on top of abstract truth.** A cart, an NPC mule, a courier's sealed crate or a warehouse
   chest is a **view** of API-held stock or a **token** for it. It is never a second copy. This is the lesson of V2's
   chest era (scan §3.1) and the way to make robbing and escorting safe against item duplication (§7).
4. **Data-driven where admins configure, code where behavior differs.** Production kinds, levels, yield tables,
   distribution rules and multipliers are data, edited in the web app. Area models, the state machine and stock rules
   are code.
5. **Web app first for admin** (note 10). Every entity has FormConfig CRUD. Every automated decision leaves a
   readable trace: what was produced, why, which multipliers applied, which rule sent which cargo where. In-game menus
   cover viewing and in-world actions.
6. **Never lose or duplicate an item.** Each move is complete or doesn't happen. Overflow is held, re-routed or
   returned. Plugin-originated actions carry idempotency keys.

## 3. Domain model

### 3.1 What rev. 2 changes compared with V2 (note 6)

| V2 practice | Problem | V3 practice |
|---|---|---|
| Bidirectional object graphs everywhere (`Structure.storages` ↔ `Storage.structure`, `Generation.producer` ↔ `producerObjects`), loaded and "verified" against a cache | Duplicate instances, cache verification code in every setter, N+1 loads | **Aggregates** with clear roots (§3.2). Cross-aggregate references are **by id**. Navigations exist only inside an aggregate or for read projections. |
| `@Any` polymorphic commodity (Item / Structure / Warehouse) | Untyped and unenforceable FKs | Typed references. Stock holds a **blueprint** (fungible) or an **ItemInstance** (unique). |
| Storage owner = nullable Structure **or** User | Hard to extend (clan, town, NPC, transit) | **Owner by holder kind** with exclusive FKs and a check constraint, plus **virtual** system storages (§4.1). |
| Single-sided `addStorageItem`/`removeStorageItem` | No trail; items can appear or vanish | **Double-entry stock transactions** (§4.3). |
| Exceptions for capacity | Retry loops, infinite loops (V2 defect 1) | Capacity is a **result value**. |
| Undo via Command `unExecute` | Undo often incomplete (V2 defect 13) | **Database transactions** for atomicity. Corrections are compensating moves, never edits. |
| `Calendar` + int unit constants, client-side ids | Fragile | UTC timestamps, durations in seconds, database identity. |
| One class per concept with flags (`override` + `autostart`) | Unclear precedence | **Explicit state** (`Status` enums with timestamps) and one switch per level. |
| Subclass per functional idea | Class explosion if each production kind became a class | **TPT subclass for structure identity** (Warehouse, ProductionStructure, Shop…, vision §2.5), **catalogue data for kinds** (Farm, Logger…), **composition for capabilities** (has storages, produces, can be owned). |
| Logic in entities, I/O in event listeners | Main-thread I/O (V2 defect 6) | Thin entities, **application services** own the use cases, **domain events** go to an outbox for notifications and plugin events. |

### 3.2 Aggregates (knk-web-api)

```
Storage  ─── StockLine (fungible: blueprint + amount)           ┐ inventory context
   │     └── StockUnit (unique: ItemInstance)                   │
   │     └── StorageContainer (optional in-game container binding, §6)
StockTransaction ─── StockMove (from storage → to storage, item, amount)   ┘ append-only

ProductionStructure (Structure subtype) ─── ProductionArea ─── AreaSurvey (history)   ┐ production context
   │                                    └── ProductionLine (output, rate source, status)  │
   │                                    └── ProductionCycleRecord (trace, history)        │
ProductionKind (catalogue) ─── ProductionKindLevel ─── LevelYieldUnlock                ┘
ResourcePool (per area: harvestable units, regeneration)

TransportOrder ─── TransportStop ─── TransportOrderLine          ┐ transport context
   │          └── cargo = a Transit Storage (§4.1)               │
   │          └── TransportAssignment (carrier: simulated / NPC / player) + TransportEvent log
TransportLane (read model: road distances)                       ┘

LogisticsPolicy (per Town, per Warehouse) ─── LogisticsRule      ┐ distribution context (TOWN_LOGISTICS.md)
SupplyRequest / ReplenishmentPlan, TradeAgreement                ┘

Territory (Domain subtype), Warehouse / ProductionStructure / later Shop (Structure subtypes)   world context
```

Each aggregate is changed only through its application service:

- `IStockService`
- `IProductionService`
- `ITransportService`
- `ILogisticsPlanner`
- `IItemDeliveryService`

Services may call each other inside one database transaction (the currency pattern: "call `ICurrencyService`
inside your own transaction").

### 3.3 World entities

- **`Territory : Domain`** (new; vision §2.3; note 14). Fields:
  - `ClaimedByTownId` (nullable; in this feature, a producer's territory must be claimed);
  - an optional WorldGuard region.
  - `Province` comes later. Vision fields `controlledBy`, `accessConditions` and `resourceYield` are added when
    their features need them.
- **`Structure`** gets `TerritoryId` (nullable). Exactly one of `DistrictId` and `TerritoryId` is set: check
  constraint plus validator. **Effective town** = `District.Town ?? Territory.ClaimedByTown`. This replaces rev. 1's
  `RulingTownId`.
- **`Warehouse : Structure`**: `AcceptsDeliveries`, `Priority`, and a default storage. It is a town's hub; see
  TOWN_LOGISTICS.md.
- **`ProductionStructure : Structure`**: the vision's "Resource-Property". Fields:
  - `ProductionKindId`;
  - `Level`;
  - `ProductionEnabled`;
  - transport settings (`AutomaticTransport`, threshold, capacity);
  - `WarehousePreference` and `PreferredWarehouseId`;
  - `RoadConnection` state (§7.6);
  - areas, lines and storages.
  - One subtype for all kinds; the **kind is data** (PRODUCTION_KINDS.md §2).
- **Shops** (later, own design) become `Shop : Structure`, with merchandise and input storages and a shop level
  (note 12).

## 4. Stock model

### 4.1 Storage, owners and kinds (note 3)

`Storage` is a place that holds items. Every storage has a **kind** and **at most one holder**:

| Kind | Holder (exclusive FK) | Examples |
|---|---|---|
| `Domain` | `DomainId` (any Domain: Structure, Town, District, Territory) | warehouse stock, a producer's output, a shop's merchandise and inputs, a town treasury vault |
| `Player` | `UserId` | **private inbox** (undeliverable rewards, note 3), personal stash or vault (vision §9.1 premium slots), house storage |
| `Clan` | `ClanId` | clan vault |
| `Transit` | none; referenced by its `TransportOrder` | the cargo of one order while it travels (§7) |
| `Virtual` | `SystemKey` | `SYS_PRODUCTION` (source of produced goods), `SYS_CONSUMPTION` (inputs used up), `SYS_LOSS` (spoiled, destroyed), `SYS_ADJUSTMENT` (admin corrections), `SYS_WORLD` (items entering or leaving the system from or to the physical world, §6, §8) |

Other fields:

- `Name`;
- `Purpose` (`General`, `Output`, `Input`, `Delivery`, `Merchandise`, `Inbox`, `Stash`, `Vault`);
- capacity policy (§4.4);
- `TotalUnits` and `DistinctItems`, stored and kept in step;
- `RowVersion`.

A holder can have several storages: V2's "one storage for upgrade resources, another for other items".

### 4.2 Stock lines: fungible and unique items

- **`StockLine`** `(StorageId, ItemBlueprintId)` → `Amount`. For stackable, identical items: resources, food, most
  goods.
- **`StockUnit`** `(StorageId, ItemInstanceId)`. For items with their own identity: enchanted rewards, soulbound
  gear, any `ItemInstance` (items DESIGN). A unique item is in exactly one storage, or in a player's hands.
  ERP calls this serial tracking.

This lets the private inbox hold a lootbox reward with its enchantments, and lets a warehouse hold coal by the
thousand without a row per item.

### 4.3 Stock transactions (the ledger)

`StockTransaction` is the header:

- `Reason`;
- actor (user, system, plugin server);
- references (production cycle, transport order, quest, lootbox claim, …);
- `IdempotencyKey` (unique when set);
- `CreatedAt`.

`StockMove` is a line: `FromStorageId`, `ToStorageId`, either `ItemBlueprintId` + `Amount` or `ItemInstanceId`.
Rules:

- Append-only. Corrections are new transactions.
- For every blueprint, the sum over all storages, virtual ones included, is zero. The reconciler checks that each
  `StockLine.Amount` equals the net of its moves.
- One stock transaction can sit inside the caller's wider database transaction. Example: a shop sale writes a
  currency transaction and a stock transaction together.

Reasons (initial):

- `Production`, `ProductionInput`
- `TransportLoad`, `TransportDeliver`, `TransportReturn`, `TransportRobbed`, `TransportLost`
- `Distribution`, `Trade`
- `Deposit`, `Withdraw`
- `RewardInbox` (undeliverable reward parked), `InboxClaim`
- `ContainerSync` (§6)
- `PlayerHarvest` (PRODUCTION_KINDS.md §6)
- `Spoilage` (later)
- `AdminAdjust`

### 4.4 Capacity

A value object on the storage:

- `MaxDistinct`;
- `MaxUnits`;
- `UnitWeighting`: `Raw` (one item = one unit; the V2 rule) or `StackSlots` (a stack of up to 64 = one slot, so a
  16-stackable item uses 4× the space of a 64-stackable one; the chest-era `ChestUtil` rule).
- Capacity can be **fixed** (admin or level defined) or **derived** from bound containers (§6.3).
- Levels (PRODUCTION_KINDS.md §5, shop levels) raise caps by writing the value; nothing is recomputed implicitly.
- Over-cap after lowering a cap: removals only, nothing trimmed silently (rev. 1 rule).
- Capacity limits real storages only. Virtual and transit storages are unbounded; a transit storage is bounded by its
  order's carrier capacity at planning time.

### 4.5 Stock operations (`IStockService`)

```
StockResult Move(from, to, item, amount, reason, refs, mode: AllOrNothing | Partial)
StockResult MoveMany(lines[], reason, refs, mode)        // one StockTransaction
```

- Atomic: a conditional `UPDATE` under a row lock on both storages, in id order to avoid deadlocks.
- The result reports accepted and rejected amounts and why: `CapacityFull`, `DistinctCapReached`,
  `NotEnoughStock`, `Locked`.
- No loops, no exceptions for capacity (V2 defects 1, 2, 4).
- Storage **locks** (`LockedUntil`, `LockReason`) freeze a storage during sync conflicts, sieges or investigations.

### 4.6 Item delivery to players (`IItemDeliveryService`, note 3)

This is one entry point for every reward or grant that should reach a player:

- lootbox delivery;
- kit grants;
- quest rewards;
- gifts;
- inbox claims;
- withdrawals.

1. If the player is online, has room and is allowed to receive items (not in a siege match, not in a minigame
   inventory), the plugin places the items in their inventory.
2. Otherwise the items move `SYS_* → Player Inbox` (`RewardInbox`), with a notification.
3. The player claims them later with `/inbox` or an inbox menu, which moves `Inbox → SYS_WORLD` while the plugin
   places the items (§8.2).

This replaces today's "drop the leftovers at the player's feet" in `KitGrantPlacer` (`:279`) and
`LootboxDelivery` (`:329-341`). Inbox capacity, expiry and premium size are open decisions (D7).

## 5. API ownership and plugin cooperation

The plugin observes the world. It does not hold truth:

- it surveys areas (PRODUCTION_KINDS.md §3);
- it reports player harvests;
- it moves carriers;
- it detects robberies;
- it renders containers.

Each report is a command to the API with an idempotency key. The API validates it and applies it, or rejects it.
Reads are cache-first in the plugin with a short TTL. Push from the API goes through the notification outbox
(`PlayerNotificationPoller` today; SignalR later, [KNG-57](https://linear.app/kngpandi/issue/KNG-57)).

## 6. In-game containers (notes 4, 5)

### 6.1 Why V2 found it hard

On `main`, V2 scanned every block of a warehouse's region for chests, kept live `Chest` objects in memory, and
recomputed capacity on block place and break events (scan §3.1). It broke on:

- double chests (two blocks, one inventory);
- unloaded chunks (the chest list went stale);
- hoppers, droppers and explosions (no events in V2's listener);
- several live copies of one structure, each listening to events;
- stack-size accounting;
- no persisted list of containers.

The developer then moved to database storage (commit `1dc1548`). The problem is a two-way sync between two sources
of truth.

### 6.2 V3 approach: one truth, three binding modes

A `StorageContainer` row binds a block (world, x, y, z, container type) to a storage, with a **mode**. Containers are
registered explicitly: admin in the web app (WorldTask capture), or `/knk storage bind` while looking at a block.
They are never found by scanning.

| Mode | Truth | What the player sees | Sync | Use |
|---|---|---|---|---|
| **Terminal** (recommended default) | API | Opening the block shows the storage as a paged virtual inventory. Take and put are stock moves. The block's own inventory stays empty. | None: the block is an access point, like an ender chest. | Warehouses, town vaults, clan vaults, the player inbox and stash. |
| **Display** | API | The container is filled **read-only** with a visual sample of the stock (for example proportional to fill level). Clicks are cancelled or redirected to the terminal view. | One-way, API → world, when the chunk loads and after changes (throttled). | Atmosphere: a full warehouse looks full. |
| **Backed** (later) | World, mirrored into the API | A normal chest. Players use it freely. | World → API deltas from `InventoryCloseEvent`, `InventoryMoveItemEvent` (hoppers), block break and explode events, and a reconcile on chunk load. | Player and clan houses, where vanilla chest feel matters. |

### 6.3 Rules that make Backed mode workable

These are the improvements over V2. They apply only to Backed mode.

- **A canonical key per inventory.** A double chest is keyed by its left half, so a container is never counted
  twice.
- **The plugin is the single writer per container.** It sends deltas with the container's last known version. On a
  version conflict, the API locks the storage and the plugin reconciles from a full snapshot.
- **Unknown items stay unmanaged.** Items that don't resolve to a blueprint (§8) stay in the chest but are not stock.
  The capacity view marks their slots as used.
- **Restricted container types:** chests, barrels and trapped chests. Shulker boxes are treated as an item (a
  `StockUnit` whose contents are serialized), not as a nested storage.
- Hoppers and droppers into or out of a bound container are **denied** unless the admin enables an "automation"
  flag. That avoids per-tick event floods.
- **Reconcile on chunk load:** a content hash is compared with the last synced hash; a mismatch triggers a snapshot
  sync. Changes while the chunk was unloaded can only come from outside the server.
- **Derived capacity** = slots × stack size of the bound containers, so placing a chest adds capacity. This is what
  V2 tried with `capacityUsed`.
- **Partial sync** (note 4, "in part or in full"): a container may carry a slot filter (blueprints or categories).
  Only matching items are stock; others are unmanaged.

Recommendation: build Terminal (with the deposit and withdraw engine, implementation plan) and Display first.
Design Backed in detail when housing arrives, because it is only needed for player-built storage (D8).

## 7. Transport (notes 1, 17)

### 7.1 Order model

`TransportOrder`:

- `Origin`: `Automatic`, `Distribution`, `Trade`, `Manual`, `Quest`;
- `Status`;
- `SourceStorageId`;
- an ordered list of `TransportStop`s (destination storage, per-line planned amounts);
- `TransportOrderLine`s (blueprint, requested, loaded, delivered, returned, lost);
- `CargoStorageId`, the order's **Transit storage**;
- timestamps (`ExecuteAfter`, `DepartedAt`, `EtaAt`, `CompletedAt`);
- `CarrierCapacity`;
- `Risk` (§7.5);
- an event log (`TransportEvent`: departed, arrived at stop, ambushed, robbed, escorted, rerouted, …).

### 7.2 Lifecycle (shared by every carrier)

```
Planned → Assigned → Loading → InTransit ⇄ AtStop(delivering) → Delivered
                                   │            └→ AwaitingSpace → (re-route | Returning → Returned)
                                   ├→ Ambushed → (Defended → InTransit) | Robbed → (partial: InTransit | total: Lost)
                                   └→ Stalled (carrier gone: NPC despawned, courier logged out) → Reassigned | Returning
Planned/Assigned → Cancelled
```

- **Loading** moves source → transit (`TransportLoad`).
- **Delivery** moves transit → stop storage (`TransportDeliver`), using the per-stop planned amounts (no V2
  defect 3).
- **Overflow** never drops (V2 defect 2): it waits, re-routes, or returns.
- **Robbery** moves transit → the robber's inventory (through `SYS_WORLD`) or the robber's inbox (`TransportRobbed`).
- **Losses** without a beneficiary move transit → `SYS_LOSS` (`TransportLost`).
- The **only** place cargo exists in transit is the transit storage. Carriers are tokens (§7.3).

### 7.3 Carriers: execution modes (`TransportAssignment`)

| Mode | How it moves | Cargo token | Robbery | Status |
|---|---|---|---|---|
| **Simulated** | The ETA comes from lane distance / speed. Nothing walks. | None. | A risk roll per leg against the route risk (§7.5) can produce an `Ambushed` event. It is resolved automatically, or turned into a spawned encounter if players are near. | First phase. It stays as the fallback when no carrier is available. |
| **NPC caravan** | An NPC (mule, cart, wagon driver) walks the road route (KNG-27 graph + KNG-36 NPC platform). The NPC's position is reported to the API with progress. | The NPC entity carries the order id. It has no inventory of its own. | Killing or stopping the NPC lets attackers open a **loot view** of the transit storage (Terminal-style) and take items as `TransportRobbed` moves. | After KNG-36. |
| **Player courier** | A player accepts a courier contract (a quest or job board; profession Transporter/Trademaster, concept L229). The player gets a **sealed cargo crate** item. | The crate is an `ItemInstance` bound to the order. It is not stackable and can't be opened by the courier. Whoever holds the crate holds the right to the cargo; the items stay in the transit storage. | If the courier dies, the crate drops and anyone can pick it up (V1 "kill the courier for a bounty", `Minigames/Transport.java`). Delivering a crate at a stop's terminal completes delivery. A thief can "fence" a crate at a black market or open it at a thieves' den, moving the cargo to themselves; they become wanted (iPhone L268-272). | With the quest and job systems. |
| **Escort** (add-on to NPC or courier) | Players or guard NPCs accompany a carrier. | — | They lower risk and defend during ambushes. Escort rewards are paid on delivery. | With caravans. |

The duplication guarantee: no physical object ever contains the cargo items. The crate and the NPC are keys to the
transit storage, so killing, dropping, duplicating or crashing can't copy goods.

### 7.4 Planning and triggers

- **Automatic from producers:**
  - Fires when occupancy reaches the threshold, a line is blocked full, or the distinct cap blocks a line (V2
    defect 7).
  - The order is sized by stock up to carrier capacity (V2 defect 8).
  - The destination follows the producer's preference within its effective town (§7.6).
- **Distribution:** warehouse → consumers (shops, workshops, garrisons), planned by the town's logistics policy
  (TOWN_LOGISTICS.md).
- **Trade:** warehouse → another town's warehouse, under a trade agreement (TOWN_LOGISTICS.md §6).
- **Manual and Quest:** created by admins or by quest scripts. A dry run previews the plan (replaces
  `/test transportpreperation`).

### 7.5 Route risk (power plays, note 17)

`Risk` is computed per leg when the order is planned and refreshed at each leg. Inputs, from the iPhone notes
(L297-298) and vision §6:

- time of day;
- distance to law-enforcement buildings and their state (a siege can disable them);
- biome;
- territory control (a hostile clan raises risk);
- bandit activity;
- `RoadEdge.CostMultiplier`.

Escorts and the carrier's quality lower it. This is how clans and kingdoms exert pressure. They can:

- raid rival trade routes;
- protect their own;
- take the law buildings that keep roads safe.

The formula is a later balancing task. The model only needs per-leg risk and the event log.

### 7.6 Roads and lanes (note 14)

- `TransportLane` (from structure, to structure): road distance, straight distance, the route's edge ids, measured
  time, source.
- The plugin measures lanes with `AStarRouter` over the road snapshot.
- Simulated ETA = road length / carrier speed. NPC and courier carriers walk the actual route.
- **Road connection:** a rural `ProductionStructure` (in a Territory) must be connected to its town's road
  network. Its `RoadConnection` state is `Connected`, `Unconnected` or `Unmeasured`.
  - `Unconnected` producers can still produce.
  - Automatic transports from them are held, with a warning. Alternatively they could run with an off-road penalty
    (D5).

## 8. Item identity (note 9)

Stock is counted per blueprint, so every item the system touches must resolve to one. This is generalized into a
game-wide rule (its own issue):

- **Every item a player can obtain is a blueprint item, or is converted into one when it enters play.** This covers
  pickup, block drops, mob drops, fishing, crafting results, villager trades and containers from outside the system.
- Mechanism:
  - each vanilla `Material` that can be obtained maps to exactly one blueprint (`ItemBlueprint.VanillaMaterialMatch`,
    unique);
  - "vanilla shadow" blueprints are generated for materials nobody has curated yet;
  - the plugin stamps `knightsandkings:knk_blueprint` on stackables;
  - non-stackables keep `knk_item_instance`.
- Conversion hooks:
  - `EntityPickupItemEvent`;
  - `BlockDropItemEvent`;
  - `EntityDeathEvent` drops (V1 `ResourceKillEvents` remapped drops the same way);
  - `PlayerFishEvent`;
  - `CraftItemEvent`/`PrepareItemCraftEvent`;
  - merchant trades;
  - first open of an unmanaged container.
- Resolution order when depositing: instance tag → blueprint tag → vanilla match. Items that don't resolve (named,
  custom-lored, from another plugin) are refused.

## 9. Production (summary; details in PRODUCTION_KINDS.md)

- A `ProductionStructure` has a **kind** (catalogue entry: Farm, Logger, Quarry, Mine, Fishery, Flower farm,
  Florist, Animal farm, Hunter, …), one or more **areas**, a **level**, storages, and **production lines** (one per
  output).
- **Yield source** per structure (note 8): `Derived` (from a survey of the area's contents), `Configured` (an admin
  table), or `Hybrid` (survey-derived, with admin pins, exclusions and overrides; recommended default).
- **Rate** = base rate × multipliers:
  - level (note 11);
  - town;
  - territory;
  - technology (later);
  - season (later);
  - pool depletion from player harvesting (note 13);
  - shared-area competition.
  - Each cycle writes a `ProductionCycleRecord` with the multiplier breakdown (insight, note 10).
- **Cycles**:
  - anchored to the cycle length, so there is no drift (V2 defect 5);
  - catch-up is capped;
  - inputs are consumed when a line has them (V2 defect 12);
  - a full output storage puts the line in `BlockedFull`.
- **Player harvesting** in yield areas, with rights, yield and depletion of a shared `ResourcePool`, and **block
  regeneration** (notes 13, 18): PRODUCTION_KINDS.md §6-7.

## 10. Processing, shops and levels (note 12; hooks)

- Processing is a production line with inputs. It runs at a processing structure: a workshop, a shop with a
  workshop, a sawmill. Inputs come from an `Input` storage that distribution keeps filled (TOWN_LOGISTICS.md §3).
- **Shop level** (shop design) sets:
  - production speed (cycle length multiplier);
  - yield;
  - input cost per cycle;
  - the price multiplier;
  - storage caps.
- The level-definition pattern is the same as for production kinds (PRODUCTION_KINDS.md §5), so one admin UI
  serves both.
- **Pricing** (note 16) reads supply and demand from this network: warehouse stock, days of cover, inflow, sales.
  See TOWN_LOGISTICS.md §7.

## 11. Admin, debug and insight (note 10)

### 11.1 Web app (primary)

- **FormConfig CRUD:**
  - Territory, Warehouse, ProductionStructure (with areas and initial lines), ProductionKind and levels, Storage
    and container bindings;
  - transport orders (manual), logistics policies and rules, trade agreements;
  - blueprint vanilla matches.
- **Logistics dashboard per town:**
  - warehouses (fill, days of cover per key resource);
  - producers (line states, last survey, level, road connection);
  - open orders on a timeline with carrier mode, ETA and risk;
  - warnings.
- **Structure detail:**
  - area surveys, with a 2D plot of composition from survey data;
  - lines, each with its cycle history and multiplier breakdown;
  - a "why not producing" explanation;
  - storage contents.
- **Ledger explorer:** stock transactions filtered by storage, blueprint, reason, actor and reference, with
  drill-down from any number to the moves that made it.
- **Order detail:** event timeline, cargo, the route on a map (road edges), risk per leg.
- **Simulator:** forecast the next N hours of production and transport for a structure or town without writing
  anything (dry-run planner). Useful for balancing.
- **Health:** reconciler results, storages over cap, unconnected producers, stalled orders, sync conflicts.

### 11.2 In game (secondary)

- Menus: structure logistics, storage terminal, inbox, transport orders.
- Commands under `/knk storage|production|transport|logistics` for in-world actions and testing:
  - bind a container;
  - run a survey;
  - measure lanes;
  - watch notifications;
  - dry runs.

## 12. V2 → V3 concept map (updated)

| V2 | V3 rev. 2 |
|---|---|
| `Storage` (structure or user) | `Storage` with kind and holder (Domain, Player, Clan, Transit, Virtual) |
| `StorageItems` map | `StockLine` (fungible) + `StockUnit` (instances) |
| `StorageFillCommand`, add/remove methods | `IStockService.Move` and double-entry `StockTransaction` |
| Chest-scanning warehouse | `StorageContainer` bindings in Terminal, Display or Backed mode |
| `Warehouse` | `Warehouse : Structure` (hub, policies) |
| `ProductionStructure` + `IProducer` | `ProductionStructure : Structure` + `ProductionKind` catalogue + areas + levels |
| `Generation` / `Production` | `ProductionLine` (rate from survey or config, inputs) + `ProductionCycleRecord` |
| `GenerationDeliveryType.SPAWN_ON_GROUND` | Dropped |
| `transportThreshold`, nearest or preferred warehouse | Kept, with fixed semantics (§7.4) |
| `TransportOrder` / `TransportOrderItem` / `TransportRouteNode` | `TransportOrder` / `TransportOrderLine` / `TransportStop` + transit storage + assignments + events |
| `simulatedTravelTime` (unused), commented-out `transportNPC` | Simulated mode with real ETA; NPC caravan and player courier modes |
| `Structure.town` (wilderness "ruling town") | `Territory` claimed by a town (§3.3) |
| `GenerationCommandListener` + subscriber set | Domain events → notification outbox → plugin events and messages |
| `/generation updates`, `/storage …`, `/test transportpreperation` | Web-app tools first; `/knk logistics watch`, `/knk storage …`, dry runs |
| Generic Command pattern + undo | Application services + database transactions + compensating moves |

## 13. Improvement checklist (V2 defect → V3 answer)

| V2 defect (scan §7) | Answer |
|---|---|
| 1 infinite loop at the distinct cap | Capacity is a result value (§4.5) |
| 2 overflow dropped | AwaitingSpace → re-route → Returning (§7.2) |
| 3 multi-stop duplication | Per-stop planned amounts (§7.1-7.2) |
| 4 lost updates, split transactions | Locked conditional moves, double-entry ledger (§4.3-4.5) |
| 5 drift and silent loss when full | Anchored cycles, catch-up cap, BlockedFull (§9) |
| 6 main-thread I/O, subscriber set | API-side processing, outbox notifications (§5) |
| 7 threshold rule | Occupancy, blocked and distinct-cap triggers (§7.4) |
| 8 sizing and ignored flags | Stock-based sizing, flags honoured (§7.4) |
| 9 nearest-warehouse search | Road lanes, per-order choice (§7.6) |
| 10 polling everything | Indexed due times (PRODUCTION_KINDS.md §4) |
| 11 instant transport | Lifecycle with ETA and carriers (§7) |
| 12 inputs ignored | Inputs consumed per cycle (§9, §10) |
| 13 broken undo | Transactions and compensating moves (§3.1) |
| 14 `@Any`, Calendar, client ids | Typed refs, seconds, database identity (§3.1) |
| 15-16 command, permission and menu bugs | `/knk` subcommands and menu engine (§11.2) |
| 17 no notifications | Outbox notifications and dashboard warnings (§11) |

## 14. Decisions

**Settled by the developer (2026-10-09):**

- Transport is physical (NPC or player) in the end, and robbable, escortable and quest-linked. Simulation is the
  first step (notes 1, 17).
- Storage is a general capability for players, clans and domains, including a reward inbox (note 3).
- Container sync is a requirement, designed in §6 (notes 4, 5).
- Rural producers live in a town's Territory and connect by road (note 14).
- Yields depend on area contents and multipliers, including the production level (notes 7, 8, 11).
- Player harvesting and block regeneration exist in yield areas (notes 13, 18).
- The web app is primary for admin (note 10).
- Every item is a blueprint item (note 9).

Rev. 1 decisions now superseded:

- D1 (`RulingTownId`) is replaced by Territory.
- D2: ownership is still deferred, but storage holders are now general.
- D7: simulated transport is now explicitly the first mode, not the design.
- D13 is generalized in §8.

**Open (recommendation first):**

| # | Question | Recommendation |
|---|---|---|
| D1 | Territory scope now | A minimal `Territory : Domain` with `ClaimedByTownId` and an optional region. Province, controlledBy, accessConditions and resourceYield come later. |
| D2 | Ownership and payouts (vision §4.5) | Still deferred. Storages and holders are ready for it. Producers stay town/staff-run until the property economy design. |
| D3 | Capacity weighting default | `StackSlots` for container-bound storages (it matches what players see). `Raw` for abstract ones. |
| D4 | Output full | Stall without accruing (rev. 1 D4). Shown on the dashboard. |
| D5 | Unconnected rural producer | Production continues. Automatic transport is held, with a warning. No off-road transport. |
| D6 | Simulated-mode robbery | Off by default. A per-town switch enables risk rolls with automatic outcomes, so routes matter before NPCs exist. |
| D7 | Inbox limits | No hard cap. Expiry after 30 days moves items to `SYS_LOSS`, with reminders. Premium tiers get a larger **stash**; the inbox is not a premium feature. |
| D8 | Container modes first | Terminal + Display. Backed with housing. |
| D9 | Courier crates | An `ItemInstance` bound to the order. Not soulbound, so it can be stolen. It expires with the order. |
| D10 | Ledger retention | Keep all moves. Roll `Production` moves up per line per day after 30 days. |
| D11 | Vanilla shadow blueprints (§8) | Generate automatically for every obtainable material, in an "Uncurated" category. Admins curate later. |

Production- and logistics-specific decisions are in the companion documents.
