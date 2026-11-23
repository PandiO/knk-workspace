# Production, storage and transport — Design

**Status:** **Decided 2026-11-16** (developer), after the in-game menus pass (M1-M5); no open questions (§19). Every recommendation the developer had not discussed was confirmed or changed in the 2026-11-16 design pass ([decision record §15](DECISIONS_2026-11-05.md#15-design-pass-to-decided-2026-11-16), G1-G16). Before that: draft **rev. 3**. Rev. 3 takes in the developer's voice design review of 2026-11-05, recorded in
[DECISIONS_2026-11-05.md](DECISIONS_2026-11-05.md). Rev. 2 took in the 18 notes of 2026-10-09. §14 lists what is
settled and what is still open. Only the prerequisite item identity (§ 8, #141) is implemented (in `next`). Items are tagged **[V1]** (first version), **[Later]** (in the
concept, a future update) or **[Parked]** (direction agreed, details open).
**Last updated:** 2026-11-19 (§ 8: the retag rule and what #141 built, docs #796); 2026-11-16 (design pass: §14 confirmations, §15-§19 platform parts, risks, acceptance, tiers, open questions; #22); 2026-11-11 (open questions answered, [decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11))
**Companion documents:**
- [PRODUCTION_KINDS.md](PRODUCTION_KINDS.md): farms, loggers, quarries, mines, fisheries, flower farms and florists,
  animal farms, hunters. Covers yield areas, surveys, levels, player harvesting and block regeneration.
- [TOWN_LOGISTICS.md](TOWN_LOGISTICS.md): warehouses as hubs, distribution and saving rules, inter-town trade and
  the pricing hook.
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

**Evidence:** [reports/2026-10-09-v2-production-storage-transport-scan.md](../../reports/2026-10-09-v2-production-storage-transport-scan.md)
covers the V2 code on all branches, the vision and V1. "V2 defect n" refers to scan §7.
**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22) (`[KNG-83]`, Linear
[KNG-83](https://linear.app/kngpandi/issue/KNG-83)) is the parent. The phase and follow-up issues are listed in the
implementation plan.
**Related:**
- [KNG-47](https://linear.app/kngpandi/issue/KNG-47): Structure subtypes.
- [KNG-48](https://linear.app/kngpandi/issue/KNG-48): block-break in resource regions.
- [KNG-36](https://linear.app/kngpandi/issue/KNG-36): NPC platform.
- [navigation](../navigation/DESIGN.md): roads.
- [currency](../currency-payments/DESIGN.md): ledger patterns and payments.
- [items](../items/IMPLEMENTATION_PLAN.md): `ItemBlueprint` and `ItemInstance`.
- [lootboxes](../lootboxes/DESIGN.md): reward delivery.
- [shops](../shops/DESIGN.md): shops, shopkeepers and display stalls (new in rev. 3).
- [NPC platform](../npc-platform/DESIGN.md): NPC lifecycle and reliability (shopkeepers, workers, carriers).

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
- **Rev. 3 (2026-11-05, [decision record](DECISIONS_2026-11-05.md)):**
  - Full concept now, solid foundation first: every item is tagged [V1], [Later] or [Parked].
  - Principles clarified: harvest moves, partial moves, deliberate `SYS_LOSS` losses, in-game runtime management
    later (§2).
  - Capacity in raw units; container-derived caps = slots × `UnitsPerSlot`; `ItemBlueprint.StorageWeight` (default
    1); `StackSlots` dropped (§4.4, replaces D3).
  - Reward inbox: hard cap raised by premium, overflow to `SYS_LOSS`, warnings, 30-day expiry (§4.6, replaces D7).
  - Transport: simulated only in V1, robbery off; producer workers carry orders; unconnected producers produce until
    full; NPC transporters with virtual movement designed as the next follow-up; town carrier pool for hire later (§7).
  - Shops, shopkeepers and display stalls are in V1, with their own [design](../shops/DESIGN.md) (§10).
  - The production structures work and the garrison/guard NPC work ship in the same test phase.
- **2026-11-11 ([decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11)):** answers to the open questions: shop income goes to a town account
  in V1, midpoint base price, enchantments as a percentage, a later shop turnover tax
  ([#325](https://github.com/PandiO/knk-workspace/issues/325)), and the other items listed in §14.
- **2026-11-11:** Territory is a V1 requirement with region rules T1-T7 (§3.4, decision record §12).
- **2026-11-11 (later):** Territory is computed, not a WorldGuard region; see [territory DESIGN](../territory/DESIGN.md) (decision record §13).
  §3.3-3.4 and P2 reconciled with it: rural structures link to a town, placement rules P-1 to P-3 ([#326](https://github.com/PandiO/knk-workspace/issues/326)).

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
   - **Harvesting (rev. 3):** structure production moves `SYS_PRODUCTION → structure Output storage` each cycle
     (`Production`). In manual player harvesting, the player's share goes to the player's real inventory and is
     recorded as `SYS_PRODUCTION → SYS_WORLD` (`PlayerHarvest`). Those items re-enter the system only by deposit or
     sale. The town's share is a normal move into the structure's Output storage (PRODUCTION_KINDS.md §6).
3. **Physical gameplay on top of abstract truth.** A cart, an NPC mule, a courier's sealed crate or a warehouse
   chest is a **view** of API-held stock or a **token** for it. It is never a second copy. This is the lesson of V2's
   chest era (scan §3.1) and the way to make robbing and escorting safe against item duplication (§7).
4. **Data-driven where admins configure, code where behavior differs.** Production kinds, levels, yield tables,
   distribution rules and production modifiers are data, edited in the web app. Area models, the state machine and
   stock rules are code.
5. **Web app first for admin** (note 10). Every entity has FormConfig CRUD. Every automated decision leaves a
   readable trace: what was produced, why, which modifiers applied, which rule sent which cargo where. In-game menus
   cover viewing and in-world actions. **[Later]** runtime management (distribution rules, reserves, taxes and similar
   town administration) also becomes available in game
   ([#256](https://github.com/PandiO/knk-workspace/issues/256)).
6. **Never lose or duplicate an item.** Each move is complete or doesn't happen. Overflow is held, re-routed or
   returned. Plugin-originated actions carry idempotency keys.
   - Partial moves stay allowed: `Partial` mode accepts what fits and reports the rest as rejected; the rejected
     amount stays in the source (§4.5).
   - Deliberate, ledger-recorded losses to `SYS_LOSS` (inbox overflow and expiry, §4.6) do not break this principle.
     The ledger keeps the record.

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

Warehouse / ProductionStructure / Shop (Structure subtypes); territory lookup (territory DESIGN)   world context
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

- **Territory** [V1] (vision §2.3; note 14; developer requirement 2026-11-11) is the rural land of a town. It is
  **computed and chunk-cached, not an entity with a region** ([territory DESIGN](../territory/DESIGN.md), [#326](https://github.com/PandiO/knk-workspace/issues/326)).
  Most production structures stand in it. What production needs from it: §3.4.
- **`Structure`** is either in a district (`DistrictId`) or **rural** (`TownId`). Exactly one is set: check
  constraint plus validator. `DistrictId` and `StreetId` become nullable (today both are required). **Effective
  town** = `District.Town ?? Town`. This replaces rev. 1's `RulingTownId` (§3.4).
- **`Warehouse : Structure`**: `AcceptsDeliveries`, `Priority`, and a default storage. It is a town's hub; see
  TOWN_LOGISTICS.md.
- **`ProductionStructure : Structure`**: the vision's "Resource-Property". Fields:
  - `ProductionKindId`;
  - `Level`;
  - `ProductionEnabled`;
  - transport settings (`AutomaticTransport`, threshold, capacity);
  - `WarehousePreference` and `PreferredWarehouseId`;
  - `RoadConnection` state (§7.6);
  - `WorkersTotal` (default 2) and the workers currently present (§7.7) [V1];
  - areas, lines and storages.
  - One subtype for all kinds; the **kind is data** (PRODUCTION_KINDS.md §2).
- **`Shop : Structure`** [V1, rev. 3]: Input and Merchandise storages, a shop level, its own worker, a stored
  shopkeeper spawn location and registered display spots. See [shops DESIGN](../shops/DESIGN.md) and §10.

### 3.4 Territory and placement rules [V1] (2026-11-11)

Territory is the rural land around a town: the fields, forests and mines where most production structures stand.
The developer made it a V1 requirement of this feature on 2026-11-11 (decision record §12). Later that day the
developer decided territory is **computed and chunk-cached, not a WorldGuard region** (decision record §13). The full
design is in [territory DESIGN](../territory/DESIGN.md) and its V1 work in [#326](https://github.com/PandiO/knk-workspace/issues/326). This section says only
what production needs from it. It replaces the region-based proposal of §12 (a `Territory : Domain` with a required
region, rules T1-T7, a `TERRITORY` managed region kind).

**What production uses:**

- **A structure belongs to a town by a database link** (territory DESIGN §4), not by its position. A structure is
  either **in a district** (`DistrictId`, as today) or **rural** (`TownId`, no district). Exactly one of the two is
  set: check constraint plus validator. `DistrictId` and `StreetId` become nullable; a rural structure has no street.
  **Effective town** = `District.Town ?? Town` (confirmed by the developer 2026-11-11, decision record §14).
- **The territory lookup** (territory DESIGN §1): which holder owns a position, from the chunk cache. Production calls
  it to check placement and to flag structures; it never stores territory itself.
- **Contested or lost land:** when a structure's land becomes contested or leaves its town's territory, the
  structure keeps its town. It is flagged and listed on the `TerritoryConflict` (territory DESIGN §3-4). It keeps
  producing in V1, with a dashboard warning (confirmed 2026-11-11); effects on output come Later (war disruption,
  #257).
- **Climate zones** are assigned per town (PRODUCTION_KINDS §4.4); there is no territory-level zone in V1.

**Placement rules** (form validation rules; "warn" = the admin sees it and can still save; "block" = the save is
refused). **Every rule warns by default; admins choose per rule whether it blocks**, through the rule's existing
`IsBlocking` setting in the form configuration (developer, 2026-11-11):

| # | Rule | How | Level |
|---|---|---|---|
| P-1 | A structure in a district has its region inside the district's region (the gate rule, applied to the warehouse, production structure and shop forms; the generic `Structure` form has no such rule today) | existing `RegionContainment`, dependency `District.WgRegionId`, full containment | warn (default) |
| P-2 | A rural structure's region (or location) lies inside its town's territory | **new** validation type `InsideTerritory`, a territory lookup | warn (default; territory DESIGN §4) |
| P-3 | A production area (PRODUCTION_KINDS §3.1) stays inside its structure's district or its town's territory | `RegionContainment` for a district, `InsideTerritory` for a rural structure | warn (default) |

- No overlap, territory-location or "near the town" rules: territory is computed around the town's districts, and
  overlaps become contested zones, not validation errors.
- `InsideTerritory` is added to the API's validation registry and the web-app rule builder. It asks the component
  that holds the chunk cache, as `RegionContainment` asks the plugin today. Production areas and structure regions
  with several regions use their region union (KNG-257).
- The same rules also run when the API saves a structure, so a request outside the form can't skip them; a rule set
  to block refuses the save there too (proposal).

**Plugin:**

- Rural structures keep their own WorldGuard region (`RESOURCE_PRODUCTION` for production structures, `STRUCTURE`
  for warehouses and shops) for harvest rules and protection. With no district, the region has **no parent** and gets
  its kind's floor priority (managed regions §4; territory DESIGN §8 ladder: districts, then structures). Confirmed
  2026-11-11: no parent for now, so **PvP stays allowed** around rural structures (world default), with no town flags
  inherited.
- **Structure NPCs are invulnerable in V1** (developer, 2026-11-11): players can fight each other near a structure,
  but can't damage or kill its workers or shopkeeper. Robbing, raiding and killing carriers come Later with physical
  transport (#251, #53).
- No `TERRITORY` region kind. Region entry messages for territory come from the territory feature (#326).
- `/knk regions repair` handles structures without a district.

**Audit:** every `Structure.District` and `Structure.Street` dereference (navigation, discovery, managed regions,
domain access, teleport, siege) handles a rural structure (#91).

## 4. Stock model

### 4.1 Storage, owners and kinds (note 3)

`Storage` is a place that holds items. Every storage has a **kind** and **at most one holder**:

| Kind | Holder (exclusive FK) | Examples |
|---|---|---|
| `Domain` | `DomainId` (any Domain: Structure, Town, District) | warehouse stock, a producer's output, a shop's merchandise and inputs, a town treasury vault |
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

The five kinds are enough for now (rev. 3, confirmed).

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
- `RewardInbox` (undeliverable reward parked), `InboxClaim`, `InboxOverflow` and `InboxExpired` (to `SYS_LOSS`,
  §4.6)
- `ContainerSync` (§6)
- `PlayerHarvest` (PRODUCTION_KINDS.md §6)
- `Spoilage` (later)
- `AdminAdjust`

### 4.4 Capacity [V1] (rev. 3, replaces D3)

**All capacity and all economy rules count in raw units.** Reserves, quotas and days of cover are raw units too.

A value object on the storage:

- `MaxDistinct`;
- `MaxUnits` (raw units);
- `UnitsPerSlot`, for storages with bound containers.

**Capacity use** = Σ amount × `ItemBlueprint.StorageWeight`.

- `ItemBlueprint.StorageWeight` is a decimal, **default 1** for every item, added from the start. Per-item weighting
  (bulky stone vs small gems) is **[Later]** tuning: data only, no migration or code change.
- **Container-derived capacity:** physical storage sets the size of the cap through a conversion, not 1:1:
  `capacity (units) = physical container slots bound to the storage × UnitsPerSlot`.
  Example: factor 200, 10 double chests = 540 slots → 108,000 units, whatever the item type.
- `UnitsPerSlot` is raised by the structure's level or set by an admin.
- Storages without bound containers keep a **fixed** raw cap, defined by an admin or the level.
- The rev. 2 `StackSlots` weighting mode is dropped. There is no `UnitWeighting` field.
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
`LootboxDelivery` (`:329-341`).

**Inbox limits [V1] (rev. 3, replaces D7).** The inbox is a quality-of-life bonus over vanilla; keeping room is the
player's responsibility.

- **Hard cap.** Premium tiers raise it (part of the commercial model).
- **Overflow is lost.** A reward that arrives when the inbox is full moves to `SYS_LOSS` (`InboxOverflow`). The
  ledger keeps the record.
- **Warnings** as the inbox approaches its cap, and a notification when something is lost.
- **30-day expiry**, with reminders. Expired items move to `SYS_LOSS` (`InboxExpired`).

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
- **Derived capacity** = bound slots × `UnitsPerSlot` (§4.4), so placing a chest adds capacity. This is what V2
  tried with `capacityUsed`.
- **Partial sync** (note 4, "in part or in full"): a container may carry a slot filter (blueprints or categories).
  Only matching items are stock; others are unmanaged.

Decided (rev. 3, D8): build **Terminal** (with the deposit and withdraw engine, implementation plan) and **Display**
first [V1]. A typical warehouse has a few terminal chests and many display chests. **[Later]** Backed mode, designed
in detail when housing arrives, because it is only needed for player-built storage.

Container-derived capacity (`bound slots × UnitsPerSlot`, §4.4) applies to every mode.

## 7. Transport (notes 1, 17)

**V1 scope (rev. 3):** simulated transport only, robbery **off** (D6). The purpose is to prove that yields, storage
moves and transport into warehouses work end to end. The lifecycle and its branches (AwaitingSpace, re-route,
return, stalled, cancelled), the automatic triggers, stock-based sizing, the preferred-or-nearest warehouse within the
effective town, and manual orders with a dry run are all [V1]. Physical carriers, robbery, escort and route risk are
[Later].

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
| **Simulated** | The ETA comes from lane distance / speed. Nothing walks. In V1 the order is carried by one of the producer's own workers (§7.7). | None. | Off in V1 (D6). Later: a risk roll per leg against the route risk (§7.5) can produce an `Ambushed` event. It is resolved automatically, or turned into a spawned encounter if players are near. | **[V1].** It stays as the fallback when no carrier is available. |
| **NPC caravan** | An NPC (mule, cart, wagon driver) walks the road route (KNG-27 graph + KNG-36 NPC platform). The NPC's position is reported to the API with progress. See §7.8. | The NPC entity carries the order id. It has no inventory of its own. | Killing or stopping the NPC lets attackers open a **loot view** of the transit storage (Terminal-style) and take items as `TransportRobbed` moves. | **[Later], next follow-up after V1** ([#251](https://github.com/PandiO/knk-workspace/issues/251)). |
| **Player courier** | A player accepts a courier contract (a quest or job board; profession Transporter/Trademaster, concept L229). The player gets a **sealed cargo crate** item. | The crate is an `ItemInstance` bound to the order. It is not stackable and can't be opened by the courier. Whoever holds the crate holds the right to the cargo; the items stay in the transit storage. | If the courier dies, the crate drops and anyone can pick it up (V1 "kill the courier for a bounty", `Minigames/Transport.java`). Delivering a crate at a stop's terminal completes delivery. A thief can "fence" a crate at a black market or open it at a thieves' den, moving the cargo to themselves; they become wanted (iPhone L268-272). | With the quest and job systems. |
| **Escort** (add-on to NPC or courier) | Players or guard NPCs accompany a carrier. | — | They lower risk and defend during ambushes. Escort rewards are paid on delivery. | With caravans. |

The duplication guarantee: no physical object ever contains the cargo items. The crate and the NPC are keys to the
transit storage, so killing, dropping, duplicating or crashing can't copy goods.

### 7.4 Planning and triggers

- **Automatic from producers** [V1]:
  - Fires when occupancy reaches the threshold, a line is blocked full, or the distinct cap blocks a line (V2
    defect 7).
  - The order is sized by stock up to carrier capacity (V2 defect 8). In V1 that is the capacity of the producer's
    worker who carries it (§7.7).
  - The destination follows the producer's preference within its effective town (§7.6).
- **Distribution** [V1, rev. 3]: reserve and collect. The warehouse reserves stock for each consumer (shop,
  workshop, garrison); the consumer sends its own worker to collect it as a collection order. Planned by the town's
  logistics policy (TOWN_LOGISTICS.md §5).
- **Trade** [Later]: warehouse → another town's warehouse, under a trade agreement (TOWN_LOGISTICS.md §6).
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

The formula is a later balancing task. The model only needs per-leg risk and the event log. Route risk is [Later];
V1 has no robbery (D6).

### 7.6 Roads and lanes (note 14)

- `TransportLane` (from structure, to structure): road distance, straight distance, the route's edge ids, measured
  time, source.
- The plugin measures lanes with `AStarRouter` over the road snapshot.
- Simulated ETA = road length / carrier speed. NPC and courier carriers walk the actual route.
- **Road connection:** a rural `ProductionStructure` (in its town's territory) must be connected to its town's road
  network. Its `RoadConnection` state is `Connected`, `Unconnected` or `Unmeasured`.
- **Unconnected producer [V1] (rev. 3, D5):** it keeps producing into its local storage, but automatic transport is
  held. When the local storage is full, the line stops, like any full producer. Both the **missing road connection**
  and the **full storage** show as warnings in the dashboard. There is no off-road transport.

### 7.7 Producer workers carry the goods [V1] (rev. 3)

- Each `ProductionStructure` has its **own workers**, **2 by default**. They can be simulated or rendered; that
  doesn't matter for the model.
- Output scales with the workers present. When one of two workers leaves to carry a transport order, output drops to
  **50%**. With both away, it stops. Full output resumes when the worker returns.
- A transport order is carried by one of the structure's own workers. The worker's capacity bounds the order size.
  If no worker is free, the order waits.
- This is the first, built-in form of the staffing modifier: a modifier source "workers present / workers total"
  (PRODUCTION_KINDS.md §4.2).
- Consumers (shops, workshops, garrisons) use the same rule for collection orders (TOWN_LOGISTICS.md §5).
- **[Parked]** worker count growing with structure level.
- Rendered workers are **invulnerable in V1** (§3.4).

### 7.8 NPC transporters [Later, next follow-up after V1] (rev. 3)

Designed now, built right after V1 ([#251](https://github.com/PandiO/knk-workspace/issues/251)).

- **Carrier:** a caravan NPC (mule, cart, driver) on the NPC platform. It holds only the order id, never items.
- **Route:** it walks the real road route (road graph) and reports progress to the API.
- **Virtual movement:** when no players are near, the NPC despawns and advances along the route on a timer. It
  reappears at the right position when a player comes close. This keeps load low and ETAs reliable. It follows the
  [NPC lifecycle rules](../npc-platform/DESIGN.md) (non-persistent entities, one live entity per NPC id).
- **Capacity and speed** per carrier type (mule vs wagon), possibly tied to a level.
- **[Later] Town carrier pool for hire** ([#252](https://github.com/PandiO/knk-workspace/issues/252)): a town has a
  carrier pool (stable, caravan yard, carters' guild), standalone or as quarters inside a warehouse, mirroring the
  garrison rule for guards. The town or the structure itself pays to hire carriers when its own workers can't keep up
  with its output and orders. It combines the "town pool" and "hired per order" options and needs town treasury
  accounts.

## 8. Item identity (note 9)

Stock is counted per blueprint, so every item the system touches must resolve to one. This is generalized into a
game-wide rule (its own issue):

- **Every item a player can obtain is a blueprint item, or is converted into one when it enters play.** This covers
  pickup, block drops, mob drops, fishing, crafting results, villager trades and containers from outside the system.
- Mechanism:
  - each vanilla `Material` that can be obtained maps to exactly one blueprint (`ItemBlueprint.VanillaMaterialMatch`,
    unique);
  - "vanilla shadow" blueprints are generated for materials nobody has curated yet;
  - the plugin stamps `knightsandkings:knk_blueprint` on blueprint items that differ from the plain vanilla item
    (built in #141 for every blueprint item, not only stackables; see the retag rule below);
  - unique items keep `knk_item_instance`.
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
- **Retag rule (agent decision on #141, built 2026-11-19): the plain vanilla item is canonical and never tagged.**
  - A blueprint tag is only ever on an item that differs from the plain vanilla item of its material (a display name,
    lore, enchantments the blueprint sets). A blueprint whose items look exactly like the vanilla item (every
    generated shadow) builds the plain, untagged item, which resolves through the vanilla match.
  - A blueprint tag on an item that is otherwise plain (an older build, or a blueprint edited to plain since) is
    removed by the conversion hooks; the item then resolves through its material's vanilla match and merges with
    plain stacks.
  - So the tag is never the only difference between two stacks, and tagged and untagged stacks of the same item
    can't exist side by side: stacking is exactly vanilla's.
  - Untagged items with a custom name, lore or another plugin's data are left alone and counted as unresolved.
  - Built: knk-web-api `next` `7d213fd6`, knk-plugin `next` `2ef256e7`; how it works in the code:
    [item identity architecture](../../architecture/item-identity.md). Items handed out before the plugin switch was
    on are not retagged ([#791](https://github.com/PandiO/knk-workspace/issues/791)).

## 9. Production (summary; details in PRODUCTION_KINDS.md)

- A `ProductionStructure` has a **kind** (catalogue entry: Farm, Logger, Quarry, Mine, Fishery, Flower farm,
  Florist, Animal farm, Hunter, …), one or more **areas**, a **level**, storages, and **production lines** (one per
  output).
- **Yield source** per structure (note 8): `Derived` (from a survey of the area's contents), `Configured` (an admin
  table), or `Hybrid` (survey-derived, with admin pins, exclusions and overrides; recommended default).
- **Rate** = base rate run through the **modifier pipeline** (rev. 3; PRODUCTION_KINDS.md §4.2). Each modifier has a
  scope, a target, an effect (multiply or add) and an active window. New factors are new modifier sources; the engine
  doesn't change.
  - [V1] sources: structure **level** and **weather** (custom climate zones with daily stored rolls), plus the
    built-in worker-availability scaling (§7.7), the pool fill factor and the shared-area split.
  - [Later] sources: painted fertility map, technologies, seasons, staffing, soil exhaustion, events, neighbour
    bonuses, upkeep, war disruption.
  - Each cycle writes a `ProductionCycleRecord` that lists **each** applied modifier (insight, note 10).
- **Cycles**:
  - anchored to the cycle length, so there is no drift (V2 defect 5);
  - catch-up is capped;
  - inputs are consumed when a line has them (V2 defect 12);
  - a full output storage puts the line in `BlockedFull`.
- **Player harvesting** in yield areas counts as working for the town: an automatic worker's share goes to the
  player, the rest goes straight into the structure's Output storage, and the town gains net output (rev. 3). Rights,
  the shared `ResourcePool` and **block regeneration** (notes 13, 18): PRODUCTION_KINDS.md §6-7.

## 10. Processing, shops and levels (note 12)

Shops are **[V1]** since rev. 3 (they were deferred to KNG-91 before). Full design:
[shops DESIGN](../shops/DESIGN.md). Summary:

- **`Shop : Structure`** with an **Input** and a **Merchandise** storage. Two kinds:
  - **processing shops** (bakery, blacksmith) turn inputs into goods on production lines, then sell them;
  - **trading shops** (general store, market stall) sell goods as they are.
- **Every shop can also buy from players and resell**, processing shops included. A bought unique item becomes a
  `StockUnit` in Merchandise (enchantments intact) and goes back on sale as that exact item. Each shop type has
  **accepted categories** (a weaponsmith buys weapons only).
- **Build order inside the same update:** a static admin catalogue first; then restocking from the warehouse by the
  shop's own worker (reserve and collect), processing, and players selling to shops.
- Processing is a production line with inputs. It runs at a processing structure: a workshop, a processing shop, a
  sawmill. Inputs come from an `Input` storage that the shop's worker refills by collecting reservations
  (TOWN_LOGISTICS.md §5).
- **Interim pricing** until the pricing model: a static catalogue price wins; otherwise sell price = blueprint base
  price (midpoint of `BasePriceMin`/`BasePriceMax`) × shop tax modifier × shop level modifier; buy-back from players
  = the same × a buy-back percentage (default 50%). Enchantments add a percentage of the base price. Shop income goes
  to the town's account, a minimal town account kind in V1 (2026-11-11).
- **[Later]** a town turnover tax on shops, with shops setting their own margins ([#325](https://github.com/PandiO/knk-workspace/issues/325)).
- **Shop level** sets processing speed (cycle length multiplier), yield, input cost per cycle, the price multiplier
  and storage caps. The level-definition pattern and admin UI are the same as for production kinds
  (PRODUCTION_KINDS.md §5).
- **Shopkeeper NPCs** and **display stalls** are [V1] too; see the shops design §5-6.
- **Pricing** (note 16) [Later] reads supply and demand from this network: warehouse stock, days of cover, inflow,
  sales. See TOWN_LOGISTICS.md §7.

## 11. Admin, debug and insight (note 10)

### 11.1 Web app (primary)

- **FormConfig CRUD:**
  - Warehouse, ProductionStructure (district or rural, with areas and initial lines), ProductionKind and levels, Storage
    and container bindings, climate zones and weather types, Shop with catalogue, levels and display spots;
  - transport orders (manual), logistics policies and rules, trade agreements;
  - blueprint vanilla matches.
- **Logistics dashboard per town:**
  - warehouses (fill, days of cover per key resource);
  - producers (line states, last survey, level, road connection, workers present);
  - open orders on a timeline with carrier mode, ETA and risk;
  - warnings.
- **Structure detail:**
  - area surveys, with a 2D plot of composition from survey data;
  - lines, each with its cycle history and modifier breakdown;
  - a "why not producing" explanation;
  - storage contents.
- **Ledger explorer:** stock transactions filtered by storage, blueprint, reason, actor and reference, with
  drill-down from any number to the moves that made it.
- **Order detail:** event timeline, cargo, the route on a map (road edges), risk per leg.
- **Simulator:** forecast the next N hours of production and transport for a structure or town without writing
  anything (dry-run planner). Useful for balancing.
- **Health:** reconciler results, storages over cap, unconnected producers, full storages, stalled orders, sync
  conflicts, inboxes near their cap.

### 11.2 In game (secondary)

- Menus [V1], decided 2026-11-16 ([decision record §15.1](DECISIONS_2026-11-05.md#151-in-game-menus-2026-11-16), M1-M5):
  1. **Structures overview:** a new "Structures" icon in the main menu (`HubMenuFeature`). One row per production
     structure and warehouse, with search and filters (kind, town, status) on the menu engine's searchable content
     section and FilterBar (`MenuContentQuery`). The town filter starts on the town whose district or territory the
     player stands in (territory lookup, #326); outside any town's land it starts empty. Clicking a row opens the
     structure menu.
  2. **Structure menu** (production structures and warehouses), also opened by right-clicking the structure's
     worker NPC: name, kind, town, level, what it produces and a status (working, stalled, no road, full) for every
     player; for members of the structure's town and staff also exact rates, storage contents, workers present or
     away and warnings. Layout from V2's `ProductionStructureMenu` and `StorageOverview` (M5).
  3. **Transport orders list** per structure, opened from the structure menu: open and recent orders with cargo,
     from, to, state and expected arrival. Town members and staff only (M3).
  4. All three are **read-only for players**. Staff (`knk.admin.world`) get buttons that mirror the commands: survey
     now, planner dry run, cancel or retry an order, show the area outline (M4). Player management waits for #246
     and #256.
  5. The API filters the detail fields by caller (M3), so the plugin never receives stock it may not show.
  6. Already specified elsewhere: storage terminal (§6, decision record §2.3), inbox (§4.6, P7), shop menus (shops
     DESIGN §8).
  7. Every menu is seeded as menu content (like G17's form seeds), so it works on a fresh database and the developer
     can reshape it in the web app menu editor.
- Commands under `/knk storage|production|transport|logistics` for in-world actions and testing:
  - bind a container;
  - run a survey;
  - measure lanes;
  - watch notifications;
  - dry runs.

## 12. V2 → V3 concept map (updated)

| V2 | V3 rev. 3 |
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
| `simulatedTravelTime` (unused), commented-out `transportNPC` | Simulated mode with real ETA, carried by producer workers (V1); NPC caravan and player courier modes (Later) |
| `Structure.town` (wilderness "ruling town") | A rural structure's `TownId`, checked against the computed territory (§3.4) |
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
- Rural producers live in a town's territory and connect by road (note 14).
- Yields depend on area contents and multipliers, including the production level (notes 7, 8, 11).
- Player harvesting and block regeneration exist in yield areas (notes 13, 18).
- The web app is primary for admin (note 10).
- Every item is a blueprint item (note 9).

Rev. 1 decisions now superseded:

- D1 (`RulingTownId`) is replaced by a rural structure's `TownId` and the computed territory (§3.4).
- D2: ownership is still deferred, but storage holders are now general.
- D7: simulated transport is now explicitly the first mode, not the design.
- D13 is generalized in §8.

**Settled by the developer (2026-11-05, [decision record](DECISIONS_2026-11-05.md) §9):**

- All six principles (§2), with the rev. 3 clarifications.
- The five storage kinds, `StockLine` and `StockUnit` (§4.1-4.2).
- Shops, shopkeepers and display stalls are in V1 ([shops DESIGN](../shops/DESIGN.md)).
- The production structures work and the garrison/guard NPC work ship in the same test phase.

| # | Question | Outcome (2026-11-05) |
|---|---|---|
| D1 | Territory scope now | **V1 requirement (developer, 2026-11-11):** territory is **computed and chunk-cached**, not a WorldGuard region ([territory DESIGN](../territory/DESIGN.md), [#326](https://github.com/PandiO/knk-workspace/issues/326), decision record §13-14). A rural structure has `TownId` (district XOR town); placement rules P-1 to P-3 warn by default and admins can make each block; contested structures keep producing; rural regions have no parent (PvP allowed); structure NPCs are invulnerable (§3.4). |
| D2 | Ownership and payouts (vision §4.5) | **Confirmed 2026-11-16 (G1):** deferred. Storages and holders are ready for it. Producers stay town/staff-run until the property economy design. |
| D3 | Capacity weighting | **Replaced** (§4.4): raw units everywhere; container-derived caps = slots × `UnitsPerSlot`; `ItemBlueprint.StorageWeight` default 1; `StackSlots` dropped. |
| D4 | Output full | **Confirmed:** stall without accruing. Shown on the dashboard. |
| D5 | Unconnected rural producer | **Confirmed** with the §7.6 wording: produce into local storage until full, then stop; automatic transport held; warnings for the missing road and the full storage. No off-road transport. |
| D6 | Simulated-mode robbery | **Off in V1.** |
| D7 | Inbox limits | **Replaced** (§4.6): hard cap raised by premium tiers; overflow to `SYS_LOSS`; near-cap warnings and a loss notification; 30-day expiry with reminders. |
| D8 | Container modes first | **Confirmed:** Terminal + Display. Backed with housing [Later]. |
| D9 | Courier crates | **Confirmed 2026-11-16 (G2):** an `ItemInstance` bound to the order. Not soulbound, so it can be stolen. It expires with the order. [Later] |
| D10 | Ledger retention | **Confirmed 2026-11-16 (G3):** keep all moves. Roll `Production` moves up per line per day after 30 days. |
| D11 | Vanilla shadow blueprints (§8) | **Confirmed 2026-11-16 (G4):** generate automatically for every obtainable material, in an "Uncurated" category. Admins curate later. |

**Settled 2026-11-11** ([decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11) F1-F12): the shop pricing details, shop income to a town account in V1,
display stalls, the shop worker effect, the modifier order, the harvest rules and reservation expiry. See the
companion documents and the shops design §11.

**Settled 2026-11-16** ([decision record §15](DECISIONS_2026-11-05.md#15-design-pass-to-decided-2026-11-16)): G1-G4 above; crown land is a domain entity with a WorldGuard region (G10); range
from the nearest region edge, capital bonus as a multiplier (G11); NPC activation radius per consumer (G12) and the
registry in plugin memory (G13); worker carrying simulated in V1 (G14); flags (G16).

**Still open:** none. Moved to After v1 (G15, §19): worker count by level, shop vs vendor, the turnover tax (#325).

Production- and logistics-specific decisions are in the companion documents.

## 15. Platform-specific parts

This spec predates the [design template](../../../.claude/skills/knk-design/design-template.md); §15-§19 add the
template's sections it lacked (2026-11-16). The game logic stays out of Paper (vision principle, platform
independence):

1. **API (`knk-web-api`), engine-free, the source of truth:** storages, stock lines and units, the ledger and
   reconciler, capacity, production lines, accrual and the sweep, the modifier pipeline, levels, transport orders and
   their lifecycle, the LogisticsPlanner, shops, pricing, the town account, the territory computation inputs, the
   reward inbox. Nothing here knows Minecraft beyond the `Material` names in the catalogue.
2. **knk-core (Bukkit-free):** survey counting over a block-snapshot port (`BlockSnapshotSource`: material, position,
   biome), the shared-area split, harvest bookkeeping (`ResourcePool`, floor 0.5), regeneration scheduling, the
   territory chunk-cache and split-chunk resolution over a region-geometry port, the item-conversion rule
   (material → blueprint), NPC lifecycle registry rules (one live entity per id, orphan rule). Unit-tested without a
   server.
3. **knk-paper adapters (Paper/Bukkit only):**
   1. `ChunkSnapshot` reader behind `BlockSnapshotSource` (async surveys).
   2. Block-break/harvest listeners and the block placer for placeholders and regeneration (tree snapshot restore).
   3. Containers: storage terminals and display containers (inventory menus, `menu/`), the deposit/withdraw menus.
   4. Item conversion hooks on pickup, drops, crafting, fishing and villager trades (#141).
   5. NPC entities through the NPC platform's Citizens runtime (`paper/npc/citizens/`): shopkeepers, workers,
      display-stall item display entities.
   6. Region capture through the existing world tasks (`DefineRegion`, new `CaptureRadius`).
   7. BlueMap markers for territory outlines (in-game maps work, #224).
4. **WorldGuard:** only for the domain regions that already use it (districts, structures, crown land, G10). Territory
   is computed, not a region (territory §1). No new WorldGuard flags.
5. **Pragmatic exceptions (no port):** inventory menu layout, particle outlines (`/knk production area show`) and
   item display entities have no game logic and stay Paper details.

## 16. Risks and integration checks

1. **Stock concurrency.** Every stock move is one ledger transaction with an idempotency key; `requires-mysql`
   concurrency tests (P1) and the reconciler stay green in every phase.
2. **Survey cost on the main thread.** Surveys read `ChunkSnapshot`s async; entity counts (pastures) are the only main
   thread part. Budget checked with `PluginMetrics.timed` (KNG-232).
3. **NPC load.** Shopkeepers and workers share the NPC budgets of the navigation work (0.03 ms per NPC per tick,
   BEHAVIOR_MODEL §13); spawns paced by `spawns-per-tick`. Workers carry goods simulated in V1 (G14), so production
   doesn't wait on navigation Phases 5-8 or the stair gate (#358).
4. **Item conversion (#141)** touches every item path in the game (kits, lootboxes, siege rewards, enchantment books).
   It ships first and on its own, with a conversion log, before any phase relies on it.
5. **Delivery change (P7)** replaces drop-at-feet for kits and lootboxes; kit claim delivery (#261) is the current
   path and must keep working.
6. **Overlap with running work:** the town account touches currency (`AccountKind`); territory touches districts and
   towns (towns streets #409 merged); shopkeepers depend on the NPC platform lifecycle (§6a); garrison/guard NPC work
   (#234, #236, #238, #245) ships in the same test phase.
7. **Realtime.** Plugin caches are invalidated through the notification outbox now and SignalR when
   `realtime.enabled` (#66); every new entity type registers its invalidation.

## 17. Acceptance checklist

Each item is checked by an automated test or a smoke step; the phase that delivers it is in brackets.

1. A01 [P1] A stock move debits one storage and credits another in one ledger transaction; a repeated idempotency
   key applies once; the reconciler finds no difference after 1000 concurrent moves.
2. A02 [P1] A storage refuses a move over its capacity (raw units × `StorageWeight`, §4.4); `Partial` mode accepts
   what fits and reports the rest.
3. A03 [P1] Unique items keep their identity (`StockUnit`) through deposit, transport and withdrawal.
4. A04 [#141] Every obtainable vanilla material has exactly one blueprint; uncurated ones are in "Uncurated" (G4); an
   item picked up, crafted, fished or traded resolves to its blueprint.
5. A05 [#326] A position's territory holder is the town (or crown land) whose district or crown-land region edge is
   within range; a capital's range is multiplied (G11); overlapping equal-rank territory is contested and creates a
   `TerritoryConflict`.
6. A06 [P2] A rural structure has exactly one of `DistrictId` and `TownId`; placement rules P-1 to P-3 warn by
   default and block when an admin sets them to blocking (R2).
7. A07 [P2] A structure whose land becomes contested keeps its town, keeps producing and is flagged (R3).
8. A08 [P3] A production line accrues by the rate formula with modifiers in order (additions, then
   multiplications); a full output storage stalls the line without accruing (D4); the cycle trace shows each factor.
9. A09 [P3] Levels 1-10 per kind (G8) change the multiplier and the area cap.
10. A10 [P4] A `Derived` or `Hybrid` structure is surveyed on creation, once a day while its chunks are loaded, on
    demand and after a notable change; a `Configured` structure never is (G5).
11. A11 [P4] An area over the kind's maximum volume for its level is refused (G6); overlapping shared areas split
    each unit equally (G7).
12. A12 [P5] A transport order moves goods sender → transit → receiver with the ledger balanced at every step; a
    worker carrying an order lowers output to 50% (one of two away) and stops it (both away) (§7.7); the trip takes
    route length ÷ speed (G14).
13. A13 [P5] An unconnected rural producer fills local storage and stops; automatic transport is held; the dashboard
    warns about the missing road and the full storage (D5).
14. A14 [P6] A storage terminal shows the storage's stock and moves items in and out through the ledger; a display
    container mirrors stock read-only.
15. A15 [P7] An undeliverable reward goes to the inbox; at the hard cap (raised by premium tiers) the overflow is
    logged as `InboxOverflow` to `SYS_LOSS` with a loss notification; items expire after 30 days with reminders (D7).
16. A16 [P8] A player harvest in a yield area draws from the shared `ResourcePool` (floor 0.5); the harvested block
    shows a placeholder and regenerates (ores to the neutral block, trees by snapshot restore with a sapling in
    between).
17. A17 [P9] The planner runs every 10 minutes per town; warehouses reserve and consumers collect with their own
    worker (D-L1); a dry run explains the plan.
18. A18 [P10] A shop sells at the midpoint base price with its modifiers; purchase coins go to the town account
    (S-3); hourly trade stats are recorded per shop and blueprint.
19. A19 [P11] A shopkeeper spawns when a player comes within its radius (48 blocks default), despawns when no player
    has been within radius + 16 for 10 s, and is never duplicated after a restart, crash or chunk reload (G12, §6a).
20. A20 [P12] A display stall shows its items as item display entities; sold-out items are greyed out by default;
    a quick buy asks for confirmation.
21. A21 [all] With `production.enabled: false` (plugin) and `Production:Enabled` false (API) nothing of this feature
    runs: no sweeps, surveys, NPCs or listeners.
22. A22 [P1, P3, P10] Ledger roll-up: `Production` and `ProductionInput` moves older than 30 days are summed per line
    per day with totals unchanged (G3).

23. A23 [every phase] Every new entity has a FormConfiguration seed and a DisplayConfiguration seed in
    `knk-web-api` `Data/`; the seed dry-run tests (`FormConfigurationSeedFilesTests`,
    `DisplayConfigurationSeedFilesTests`) pass and the FormWizard opens the entity's create form from a fresh database
    (G17).

24. A24 [P6] The main menu has a "Structures" icon; the overview lists production structures and warehouses with
    search and filters, and its town filter starts on the town whose district or territory the player stands in
    (empty outside any town's land) (M2).
25. A25 [P6] Right-clicking a structure's worker NPC or a row in the overview opens the structure menu; a player who
    is not in the structure's town sees only name, kind, town, level, products and status, and the API response for
    that player holds no stock, rates, workers or orders (M3).
26. A26 [P6] Town members and staff see exact rates, storage contents, workers present or away, warnings and the
    transport orders list; players have no action buttons; staff buttons run survey now, dry run, cancel or retry an
    order and show the area outline (M4).
27. A27 [P6] The structures overview, structure menu and transport orders list are seeded as menu content and open
    on a fresh database.

## 18. Phases, tiers and flag

1. **Feature tier: `tier:3`** (new foundations, schema changes and game feel).
2. **Flags (agent decision G16):** plugin `production.enabled` (default `false`) and API `Production:Enabled`
   (default `false`, a game setting) gate the sweeps, surveys, planner, NPCs and listeners. Web-app CRUD stays
   available to admins so content can be prepared while it is off.
3. **Phases** are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) with their issues. Proposed tiers:

| Phase | Issue | Tier | Why |
|---|---|---|---|
| Item identity | [#141](https://github.com/PandiO/knk-workspace/issues/141) | 3 | touches every item path |
| Territory V1 | [#326](https://github.com/PandiO/knk-workspace/issues/326) | 3 | new holder model, crown land entity, schema |
| P1 Stock core | [#97](https://github.com/PandiO/knk-workspace/issues/97) | 3 | ledger, schema, concurrency |
| P2 World | [#91](https://github.com/PandiO/knk-workspace/issues/91) | 3 | structure subtypes, schema |
| P3 Production engine | [#86](https://github.com/PandiO/knk-workspace/issues/86) | 3 | accrual and sweep, game feel |
| P4 Areas and surveys | [#138](https://github.com/PandiO/knk-workspace/issues/138) | 3 | async world reads, game feel |
| P5 Transport core | [#79](https://github.com/PandiO/knk-workspace/issues/79) | 3 | order lifecycle, ledger |
| P6 Terminals and menus | [#74](https://github.com/PandiO/knk-workspace/issues/74) | 2 | plugin UI plus caller-filtered read endpoints; needs #326 for the default town filter |
| P7 Delivery and inbox | [#60](https://github.com/PandiO/knk-workspace/issues/60) | 3 | replaces kit/lootbox delivery |
| P8 Harvest and regeneration | [#134](https://github.com/PandiO/knk-workspace/issues/134) | 3 | changes the world, game feel |
| P9 Town logistics | [#127](https://github.com/PandiO/knk-workspace/issues/127) | 3 | planner, game feel |
| P10 Shops | [#248](https://github.com/PandiO/knk-workspace/issues/248) | 3 | money, town account |
| P11 Shopkeepers | [#249](https://github.com/PandiO/knk-workspace/issues/249) | 2 | NPC platform consumer |
| P12 Display stalls | [#250](https://github.com/PandiO/knk-workspace/issues/250) | 2 | display entities, quick buy |
| Web-app insight | [#65](https://github.com/PandiO/knk-workspace/issues/65) | 2 | read-only views, grows per phase |

4. **Links (on approval, 2026-11-16).** A phase spanning several repos is split into one link per repo; the original
   issue keeps the first link (usually the API). Order: top to bottom, a link starts when the links it depends on
   are merged into `next`. Smoke sections are in the
   [smoke-test guide](../../guides/production-storage-transport-smoke-test.md).

| Link | Issue | Repo | Tier | Depends on | Smoke |
|---|---|---|---|---|---|
| Item identity | [#141](https://github.com/PandiO/knk-workspace/issues/141) | API, plugin | 3 | — (prerequisite, own issue) | — |
| T-a Territory API | [#326](https://github.com/PandiO/knk-workspace/issues/326) | knk-web-api | 3 | — | § 1 |
| T-b Territory plugin | [#689](https://github.com/PandiO/knk-workspace/issues/689) | knk-plugin | 3 | #326 | § 1 |
| T-c Territory web app | [#690](https://github.com/PandiO/knk-workspace/issues/690) | knk-web-app | 2 | #326 | § 1 |
| P1 Stock core API | [#97](https://github.com/PandiO/knk-workspace/issues/97) | knk-web-api | 3 | #141 | § 2 |
| P1b Stock web app | [#675](https://github.com/PandiO/knk-workspace/issues/675) | knk-web-app | 2 | #97 | § 2 |
| P2 World API | [#91](https://github.com/PandiO/knk-workspace/issues/91) | knk-web-api | 3 | #97, #326 | § 3 |
| P2b World web app | [#676](https://github.com/PandiO/knk-workspace/issues/676) | knk-web-app | 2 | #91 | § 3 |
| P2c World plugin | [#677](https://github.com/PandiO/knk-workspace/issues/677) | knk-plugin | 2 | #91 | § 3 |
| P3 Production engine API | [#86](https://github.com/PandiO/knk-workspace/issues/86) | knk-web-api | 3 | #91 | § 4 |
| P3b Production web app | [#678](https://github.com/PandiO/knk-workspace/issues/678) | knk-web-app | 2 | #86 | § 4 |
| P4 Yield areas API | [#138](https://github.com/PandiO/knk-workspace/issues/138) | knk-web-api | 3 | #86 | § 5 |
| P4b Surveys plugin | [#679](https://github.com/PandiO/knk-workspace/issues/679) | knk-plugin | 3 | #138 | § 5 |
| P4c Yield areas web app | [#680](https://github.com/PandiO/knk-workspace/issues/680) | knk-web-app | 2 | #138 | § 5 |
| P5 Transport API | [#79](https://github.com/PandiO/knk-workspace/issues/79) | knk-web-api | 3 | #86 | § 6 |
| P5b Lanes plugin | [#681](https://github.com/PandiO/knk-workspace/issues/681) | knk-plugin | 2 | #79 | § 6 |
| P5c Transport web app | [#682](https://github.com/PandiO/knk-workspace/issues/682) | knk-web-app | 2 | #79 | § 6 |
| P6a Terminals/menus API | [#683](https://github.com/PandiO/knk-workspace/issues/683) | knk-web-api | 2 | #97, #91, #79 | § 7 |
| P6 Terminals and menus plugin | [#74](https://github.com/PandiO/knk-workspace/issues/74) | knk-plugin | 2 | #683, #689 | § 7 |
| P7 Delivery API | [#60](https://github.com/PandiO/knk-workspace/issues/60) | knk-web-api | 3 | #97 | § 8 |
| P7b Inbox plugin | [#684](https://github.com/PandiO/knk-workspace/issues/684) | knk-plugin | 3 | #60 | § 8 |
| P8a Harvest API | [#685](https://github.com/PandiO/knk-workspace/issues/685) | knk-web-api | 3 | #86, #138 | § 9 |
| P8 Harvest plugin | [#134](https://github.com/PandiO/knk-workspace/issues/134) | knk-plugin | 3 | #685, #679 | § 9 |
| P9 Town logistics API | [#127](https://github.com/PandiO/knk-workspace/issues/127) | knk-web-api | 3 | #79 | § 10 |
| P9b Logistics web app | [#686](https://github.com/PandiO/knk-workspace/issues/686) | knk-web-app | 2 | #127 | § 10 |
| P10 Shops API | [#248](https://github.com/PandiO/knk-workspace/issues/248) | knk-web-api | 3 | #97, #91, #86 (restocking: #127) | § 11 |
| P10b Shop menus plugin | [#687](https://github.com/PandiO/knk-workspace/issues/687) | knk-plugin | 2 | #248, developer's menu templates | § 11 |
| P10c Shops web app | [#688](https://github.com/PandiO/knk-workspace/issues/688) | knk-web-app | 2 | #248 | § 11 |
| P11 Shopkeepers | [#249](https://github.com/PandiO/knk-workspace/issues/249) | knk-plugin | 2 | #687, NPC platform §6a lifecycle (#358) | § 12 |
| P12 Display stalls | [#250](https://github.com/PandiO/knk-workspace/issues/250) | knk-plugin | 2 | #687 | § 13 |
| Web-app insight | [#65](https://github.com/PandiO/knk-workspace/issues/65) | knk-web-app | 2 | grows with each phase | — |

## 19. Open questions

None blocking. Everything the developer was asked on 2026-11-16 is in the [decision record §15](DECISIONS_2026-11-05.md#15-design-pass-to-decided-2026-11-16)
(G1-G17, and the in-game menus M1-M5 in §15.1). Agent decisions to review: G12 (numbers), G13, G14, G15, G16.

### After v1

1. Producer worker count growing with level: with the staffing source, [#257](https://github.com/PandiO/knk-workspace/issues/257).
2. Shop vs marketplace vendor attractiveness (shops S-1): with the pricing model, [#120](https://github.com/PandiO/knk-workspace/issues/120).
3. Shop turnover tax and margin pricing: [#325](https://github.com/PandiO/knk-workspace/issues/325).
4. Professions, paid work and quests for harvesting (F12): with town runtime management, [#246](https://github.com/PandiO/knk-workspace/issues/246).
5. Trade loss bearer per agreement (G9) and treasury spending: [#124](https://github.com/PandiO/knk-workspace/issues/124).
6. Courier crates (G2): with player couriers, [#53](https://github.com/PandiO/knk-workspace/issues/53).
