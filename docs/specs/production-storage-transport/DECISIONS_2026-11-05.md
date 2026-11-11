# Production, storage and transport: decision record, 2026-11-05

**Status:** Approved by the developer (voice design review, 2026-11-05). This record is **authoritative** where it
differs from DESIGN.md, PRODUCTION_KINDS.md, TOWN_LOGISTICS.md or IMPLEMENTATION_PLAN.md (all rev. 2, 2026-10-09)
until those documents are revised to rev. 3.
**Folded in:** 2026-11-05, rev. 3 of all four documents takes in this record. The record stays the source for the
wording of each decision.
**Last updated:** 2026-11-11 (§11 follow-up answers; §12 Territory)
**Parent issue:** KNG-83 (now tracked as a `[KNG-83]` issue in `PandiO/knk-workspace`).
**Scope of the review:** principles, storage, production structures, transport, NPC transporters, warehouses and
town logistics, shops, shopkeepers and display stalls, NPC lifecycle.

## How to read this

The developer's approach for this feature: **design the full concept now, but ship a solid foundation in the first
version** and grow it in updates (proof of concept → closed alpha → closed beta). Every decision is tagged:

- **[V1]**: part of the first version of the feature.
- **[Later]**: part of the concept, scheduled for a future update. Design for it (fields, extension points), don't
  build it.
- **[Parked]**: direction agreed, details not yet decided.

The production structures work and the garrison/guard NPC work are to ship in the **same test phase / sprint**.

---

## 1. Principles (DESIGN §2)

All six principles are confirmed as written, with these clarifications:

1. **API is the single source of truth for stock.** Confirmed.
2. **Double-entry stock moves.** Confirmed. Clarified for harvesting:
   - Structure production: each cycle moves `SYS_PRODUCTION → structure Output storage` (reason `Production`).
   - Manual player harvesting: the player's share goes to the player's real inventory, recorded as
     `SYS_PRODUCTION → SYS_WORLD` (reason `PlayerHarvest`). Items re-enter the system only by deposit or sale.
     The town's share is a normal move into the structure's Output storage (see §3.6).
3. **Physical gameplay on top of abstract truth.** Confirmed.
4. **Data where admins configure, code where behaviour differs.** Confirmed.
5. **Web app first for admin.** Confirmed. **[Later]** runtime management (distribution rules, reserves, taxes and
   similar town administration) also becomes available **in game**.
6. **Never lose or duplicate an item.** Confirmed. Partial moves remain allowed (`Partial` mode accepts what fits and
   reports the rest as rejected; rejected amounts stay in the source). Deliberate, ledger-recorded losses to
   `SYS_LOSS` (e.g. inbox overflow, §2.4) do not violate this principle.

## 2. Storage (DESIGN §4, §6)

### 2.1 Kinds and lines [V1]

- The five storage kinds (Domain, Player, Clan, Transit, Virtual) are sufficient "for now".
- `StockLine` (fungible) and `StockUnit` (unique `ItemInstance`) confirmed.

### 2.2 Capacity [V1] — replaces DESIGN D3 and §4.4's weighting choice

- **All capacity and all economy rules count in raw units.** Reserves, quotas and days of cover stay in raw units.
- **Physical storage sets the size of the cap through a conversion, not 1:1:**
  `capacity (units) = physical container slots bound to the storage × UnitsPerSlot`.
  Example: factor 200, 10 double chests = 540 slots → 108,000 units, regardless of item type.
- `UnitsPerSlot` is raised by the structure's level or set by an admin.
- Add **`ItemBlueprint.StorageWeight`** (decimal, default **1** for every item) from the start. Capacity use =
  Σ amount × weight. Per-item weighting (bulky stone vs small gems) is **[Later]** tuning: data only, no migration
  or code change.
- Storages without bound containers keep a fixed (admin- or level-defined) raw cap.
- The `StackSlots` weighting mode from rev. 2 is dropped.
- Unchanged: lowering a cap below current content never trims; only removals are allowed until it fits.

### 2.3 In-game containers [V1]

- **Terminal** and **Display** modes first (DESIGN D8 confirmed).
  - Terminal: the chest is an access point; opening it shows the API storage as a paged menu; take/put are stock
    moves; the physical chest stays empty.
  - Display: read-only visual sample of the stock (fill level visible); clicks do nothing or open the terminal menu.
  - Typical warehouse: a few terminal chests, many display chests.
- **[Later]** Backed mode, with housing.

### 2.4 Player reward inbox [V1] — replaces DESIGN D7

- **Hard cap**, raised by premium tiers (part of the commercial model).
- **Overflow is lost**: a reward that arrives when the inbox is full moves to `SYS_LOSS` (reason e.g.
  `InboxOverflow`), so the ledger keeps the record. Rationale (developer): the inbox is already a quality-of-life
  bonus over vanilla; keeping room is the player's responsibility.
- **Warnings** as the inbox approaches its cap, and a notification when something is lost.
- **30-day expiry** with reminders (expired items → `SYS_LOSS`).

## 3. Production structures (PRODUCTION_KINDS.md)

### 3.1 Kinds and areas [V1]

- Catalogue of nine kinds confirmed (Farm, Logger, Quarry, Mine, Fishery, Flower farm, Florist, Animal farm, Hunter).
  Hunter stays out of V1 (P-D10).
- Five area models confirmed (Bordered field, Exclusive volume, Shared radius, Pasture, Hunting ground), including
  the exclusive vs shared split.
- Surveys and **Hybrid** as the default yield source confirmed (P-D1).

### 3.2 Modifier pipeline [V1 engine, Later sources] — generalizes PRODUCTION_KINDS §4.2

The developer wants output to be **highly configurable**, with many factors over time. Do not hardcode the
multiplier list. Build a general **modifier pipeline**:

- Each modifier has:
  - **scope**: global, kingdom, town, territory, map area (grid cell), structure, or one output;
  - **target**: a specific blueprint, a category (e.g. "crops"), or a production kind;
  - **effect**: multiply or add;
  - **active window**: always, a season, until an expiry.
- Each cycle collects all applicable modifiers and records **each one** in the `ProductionCycleRecord` trace.
- New factors are new modifier **sources**; the engine does not change.

**Active in V1:** only two modifier sources:

1. **Structure level** (§3.3).
2. **Weather** (§3.4).

**[Later] modifier sources** (all wanted by the developer):

- **Painted resource/fertility map** (Catan/Civilization-style tile availability): an admin paints resource
  availability on a map (e.g. via a paint tool over Dynmap in the web app), for example "fertile for wheat, less so
  for potatoes". Stored as a grid layer (e.g. per chunk) with a value per resource category; an area samples and
  averages the cells it covers.
- **Technologies / knowledge**: towns and kingdoms research fields (mining, harvesting, …) that raise or lower
  yields.
- Seasons.
- **Staffing**: NPC workers raise output (an early form exists in V1 via transport workers, §4.2).
- Soil exhaustion and crop rotation.
- Random events (blight, mine collapse).
- Neighbour bonuses (e.g. a mill next to a farm).
- Upkeep: output drops if the structure isn't maintained.
- War disruption: contested territory, sieges.

### 3.3 Levels [V1]

Production structure levels affect:

- the **yield multiplier** (a level modifier in the pipeline);
- **cycle speed** (more output cycles);
- **storage capacity** (incl. `UnitsPerSlot`, §2.2);
- **upkeep reduction**: the field exists on `ProductionKindLevel` but has **no effect** in V1. Upkeep itself is
  **[Later]**.

Number of levels per kind: P-D5 (10) stands unless revisited.

### 3.4 Weather [V1 minimal, Later full] — custom, not vanilla

Vanilla Minecraft weather is rejected: it is world-wide and random, so it can't give a mountain village a different
climate from a Mediterranean coastal one.

- **Climate zones**: assigned per town (V1) or territory; **[Later]** painted on the same map grid as fertility.
- Each zone has **weather odds** (e.g. 30% rain, 5% storm, 10% drought); **[Later]** they vary by season.
- The system **rolls the weather per zone** (e.g. once per in-game day) and **stores** it, so it is traceable and
  identical for everyone.
- Each weather type has **modifiers per resource category** (a storm hits fisheries hard and farms a little; a
  drought hits farms).
- **V1:** one default climate; zones assignable per town.
- **[Later]** per-player weather (Paper `Player#setPlayerWeather`) so players inside a zone see its weather.

### 3.5 Accrual

Fractional accrual, deterministic byproduct shares (optional ±10%) and "line stops when output storage is full, no
accrual while stopped" (DESIGN D4) confirmed.

### 3.6 Player harvesting [V1] — refines PRODUCTION_KINDS §6

Problem the developer raised: if individuals take yield for personal gain, the town economy (which needs the yield
for processing, upkeep, etc.) falls apart. Decision: harvesting counts as **working for the town**.

- Players who meet the **conditions** (permission/title via `IRequirementEvaluator`) may harvest in a structure's
  yield area.
- **Automatic worker's share**: each harvest's drops are split immediately: a share (suggested 25%, configurable per
  kind) goes to the player's inventory as pay; the rest is moved straight into the structure's Output storage as
  stock. Nothing has to be handed back, so it can't be dodged.
- **The town gains net output**: a harvest drains the `ResourcePool` by less than it adds to stock, so active
  workers raise the structure's total output.
- Optional small coin wage or title XP per harvest is allowed but not required for V1.
- Block regeneration (PRODUCTION_KINDS §7, P-D7, P-D8) confirmed as designed.
- **[Later]** ties into professions, skills, paid work/jobs and quests; players can **sell harvests back to the
  town**; a stricter roleplay mode where harvested goods are tagged town property and keeping them is theft (wanted
  status, law system).

## 4. Transport (DESIGN §7)

### 4.1 V1 scope

- **Simulated transport only**, robbery **off** (DESIGN D6 confirmed for V1). Purpose: prove that yields, storage
  moves and transport into warehouses work end to end.
- Lifecycle and branches (AwaitingSpace / re-route / return, stalled, cancelled) as designed.
- Automatic triggers (fill threshold, BlockedFull, distinct cap), stock-based sizing, preferred-or-nearest warehouse
  within the effective town, manual orders with dry run: confirmed.

### 4.2 Producer workers carry the goods [V1] — new

- Each `ProductionStructure` has its **own workers**, **2 by default** (simulated or rendered; not important for the
  model).
- Output scales with the number of workers present: when one worker leaves to carry a transport order, output drops
  to **50%**; with both away, it stops. Full output resumes when the worker returns.
- A transport order is carried by one of the structure's own workers; its capacity bounds the order size. If no
  worker is free, the order waits.
- This is the first, built-in form of the staffing modifier (§3.2): a modifier source "workers present / workers
  total".
- **[Parked]** worker count growing with structure level.

### 4.3 Unconnected rural producers [V1] — replaces DESIGN D5 wording

An unconnected producer keeps producing into its local storage, but automatic transport is held. When the local
storage is full, the line stops (like any full producer). Both the **missing road connection** and the **full
storage** appear as warnings in the dashboard.

### 4.4 NPC transporters [Later, next follow-up after V1]

The developer wants NPC transport as a **close follow-up** and to design it now:

- Carrier: a caravan NPC (mule, cart, driver) on the NPC platform; holds only the order id, never items.
- Route: walks the real road route (road graph) and reports progress to the API.
- **Virtual movement** (recommended): when no players are near, the NPC despawns and advances along the route on a
  timer; it reappears at the right position when a player comes close. Keeps load low and ETAs reliable.
- Capacity and speed per carrier type (mule vs wagon), possibly level-tied.
- **[Later]** **town carrier pool for hire**: a town has a carrier pool (stable, caravan yard, carters' guild,
  standalone or as quarters inside a warehouse, mirroring the garrison rule for guards). The town or the structure
  itself pays to hire carriers when its own workers can't keep up with its output and orders. Combines the "town
  pool" and "hired per order" options; needs town treasury accounts.

## 5. Warehouses and town logistics (TOWN_LOGISTICS.md)

### 5.1 Distribution: reserve and collect [V1] — replaces push-based distribution in TOWN_LOGISTICS §5

From the developer's earlier concept:

- The warehouse **reserves** stock for each consumer (shop, workshop, garrison) based on that consumer's settings
  (reorder point, target level).
- The **consumer sends its own worker** to collect the reserved goods. While the worker is away, the consumer's own
  output or service is lowered, the same as at a producer (§4.2).
- So the planner's "Distribution orders" become **reservations + collection orders** carried by the consumer.
- **Warehouses have no workers in V1.**
- **[Later]** warehouse workers that cap **throughput** (deliveries unloaded per hour; busy hubs become bottlenecks),
  spoilage care, inter-warehouse transfers (rebalance).

### 5.2 Rule catalogue

All rule types in TOWN_LOGISTICS §4 belong to the concept. Split:

- **[V1]** consumer reorder points and target levels (with reserve-and-collect); **town reserves**; **priority
  classes** (e.g. garrisons first under scarcity); **service areas** defaulting to the nearest warehouse by road.
- **[Later]** ceilings, allocation quotas, export/import rules and embargoes, emergency modes (siege, famine),
  rebalance, tax/tariff.

### 5.3 Governance [V1]

- Default policy templates per town size/specialization, **edited by admins in the web app** (D-L3 confirmed).
- Planner interval **10 minutes per town**, plus dry runs (D-L2 confirmed).
- **[Later]** clan council governance (weekly council), in-game runtime management (§1).

### 5.4 Trade and pricing [Later]

- Inter-town trade and town treasury accounts: later (KNG-100, D-L5).
- Supply-and-demand pricing: later; **needs the developer's pricing documents (Word files, iPhone notes) imported
  first** (D-L6, KNG-101).

## 6. Shops [V1] — new; previously deferred to KNG-91

Shops are **in the first version** of this feature.

### 6.1 Shape

- `Shop : Structure` with an **Input** storage and a **Merchandise** storage.
- Two kinds:
  - **Processing shops** (bakery, blacksmith): turn inputs into goods on production lines, then sell them.
  - **Trading shops** (general store, market stall): sell goods as they are.
- **Every shop can also buy from players and resell**, processing shops included. Example: a player sells an
  enchanted diamond sword to the weaponsmith; it becomes a `StockUnit` in Merchandise (enchantments intact) and goes
  back on sale as that exact item.
- **Accepted categories per shop type** (a weaponsmith buys weapons only).
- **[Open/Later]** whether selling to a shop should be more or less attractive than selling to a marketplace vendor
  (developer unsure).

### 6.2 V1 build order inside the same update

1. **Static admin catalogue first** (fallback and a new gameplay mechanic before the supply chain is live): admins
   add blueprints or item instances to a shop at a **static price**.
2. Then, in the same update: **restocking** from the warehouse via the shop's own worker (§5.1), **processing**
   (e.g. flour → bread), **players selling** to shops.

### 6.3 Interim pricing [V1] (until the pricing model, §5.4)

- Where an admin set a static catalogue price, that price is used.
- Otherwise: **sell price = blueprint base price × shop tax modifier × shop level modifier.**
- **Buy-back from players** = the same formula × a buy-back percentage, default **50%**.
- For unique items: base price plus a value per enchantment (detail for the shop design).

### 6.4 Shop levels

Shop levels (processing speed, yield, input cost, price multiplier, storage caps) use the same level-definition
pattern and admin UI as production kinds (DESIGN §10).

## 7. Shopkeepers and display stalls [V1] — new

### 7.1 Shopkeeper NPC

- A **human or villager NPC** on the NPC platform.
- Its **spawn location is stored on the shop** model.
- Default: **stays in place** and **looks at nearby players** inside the shop. Option: roam within the shop region.
- Greets players entering the shop region ("Hello there, <username>"), with a cooldown; cosmetic only.
- **Right-click** opens the shop menu: a header with shop info (name, level, owner) and the catalogue, paged, below.
  Built on the inventory menu engine.
- The developer will provide **V1 inventory menu templates** for shop menus.

### 7.2 Display stalls

- Display spots (shelves, stalls) are **registered explicitly**, like containers; never found by scanning.
- Rendered as **Paper item display entities** (preferred over item frames: no rotation, can't be knocked down, can
  carry a floating price label), similar to how lootboxes spawn item entities.
- Not every shop can display its whole catalogue. Selection: **admin pins first**, remaining spots filled by the
  system (in-stock items and best sellers first); sold-out items hidden or greyed out.
- **Right-click** a displayed item → opens the **shop item information** menu (no purchase).
- **Shift-right-click** → quick buy, **always with a confirmation**.
- **Every purchase requires a confirmation**, whatever the channel.

## 8. NPC lifecycle and reliability [V1] — applies to the NPC platform

V1 (legacy) suffered from disappearing and duplicated NPCs. Requirements for shopkeepers, guards, workers and future
carriers; the **NPC platform owns all of this**:

- **Never persist NPC entities in chunks.** Spawn them as non-persistent entities; only the definition (owner
  structure, location, look, behaviour) lives in the API.
- **Spawn on demand**: spawn when a player is within range of the shop/district/town; **despawn** when nobody is
  near. Exact activation radius to be designed.
- **One live entity per NPC id**: entities carry their NPC id (PDC tag); a registry permits one per id, and a second
  spawn reuses the first.
- **Orphan sweep**: on chunk load, any tagged entity not in the registry is removed.
- Correct after API/server stop, crash, kill or restart: NPCs spawn when needed and never otherwise.

## 9. Changes to existing open decisions

| Rev. 2 decision | Outcome |
|---|---|
| DESIGN D3 capacity weighting | **Replaced** by §2.2 (raw units, slots × factor, item weight 1). |
| DESIGN D4 output full | Confirmed. |
| DESIGN D5 unconnected producer | Confirmed with wording in §4.3 (produce until full, then stop, warnings). |
| DESIGN D6 simulated robbery | Off in V1. |
| DESIGN D7 inbox limits | **Replaced** by §2.4 (hard cap, premium raises, overflow lost, warnings, 30-day expiry). |
| DESIGN D8 container modes | Confirmed: Terminal + Display. |
| DESIGN D1, D2, D9, D10, D11 | Not discussed; recommendations stand. |
| P-D1 Hybrid default | Confirmed. |
| P-D5 levels | Not discussed; 10 stands. |
| P-D6 harvesting vs yield | **Refined** by §3.6 (worker's share; town gains net). Pool floor 0.5 stands. |
| P-D7, P-D8 regeneration | Confirmed. |
| P-D10 hunters | Confirmed out of V1. |
| D-L1 push or pull | **Pull via reserve-and-collect** (§5.1). |
| D-L2 planner interval | Confirmed: 10 minutes. |
| D-L3 default policy | Confirmed: admin-edited templates. |
| D-L4, D-L5, D-L7 | Later, with trade/treasury/shops-buy-from-players as noted. D-L7 player sales now happen through shops in V1 (§6). |
| D-L6 pricing documents | Still required before real pricing. |

## 10. New items for the implementation plan

- `ItemBlueprint.StorageWeight` (default 1) and container-derived capacity `slots × UnitsPerSlot` (P1/P6).
- Inbox cap, premium cap source, overflow to `SYS_LOSS`, near-cap warnings (P7).
- Modifier pipeline with level and weather sources; climate zones and daily weather rolls (P3).
- Producer workers (default 2), worker-availability output scaling, transport carried by own workers (P3/P5).
- Harvest worker's share and net-positive pool math (P8).
- Reserve-and-collect distribution, consumer workers, V1 rule subset (P9).
- New phases for **shops** (static catalogue → restocking, processing, player selling), **shopkeepers** and
  **display stalls**.
- NPC lifecycle requirements (§8) in the NPC platform design; the garrison/guard work ships in the same sprint.
- Later backlog issues: NPC caravans (next follow-up), town carrier pool for hire, warehouse throughput, painted
  fertility map, technologies, seasons, staffing, exhaustion, events, neighbour bonuses, upkeep, war disruption,
  per-player weather, ceilings/quotas/exports/emergency modes, clan councils, in-game runtime management, trade,
  pricing, professions/paid work for harvesting.

## 11. Follow-up decisions (2026-11-11)

The developer answered the open questions left by rev. 3 (question round in the rev. 3 session, 2026-11-11). Where an
answer changes a §1-10 item, it says so.

| # | Question | Decision |
|---|---|---|
| F1 | Shops: which blueprint base price | The **midpoint** of `BasePriceMin` and `BasePriceMax`. |
| F2 | Shops: who receives purchase coins before town treasury accounts | **Town accounts now.** A minimal town account kind ships in V1 for shop income. Changes §5.4 / D-L5 (town treasury was Later). Trade and tax stay Later. |
| F3 | Shops: value of enchantments on unique items | **A percentage** of the base price for now (§6.3 "value per enchantment"). |
| F4 | Shops: shop tax modifier vs a later town tax | Direction, not built in V1: the town will tax shops, for example one global shop tax collected each period (a week, to be decided) as a percentage of that period's turnover. Inspiration undecided: Dutch law, US law, a hybrid, or medieval law. Shops then set a **margin** from item base prices, the cost of resources and manufacturing, and taxes, so they still make a profit; supply and demand still influence prices. The V1 per-shop tax modifier stays as the interim stand-in. Issue [#325](https://github.com/PandiO/knk-workspace/issues/325). |
| F5 | Display stalls: sold-out items | **Greyed out** by default; hiding is an option per shop. |
| F6 | Shops: what a shop's absent worker lowers | **Processing only** for now. This also drives the need for workers-for-hire and transport-for-hire. Once those exist, **sales** are affected too when a shop has only one NPC and it is out fetching stock. |
| F7 | Selling to a shop vs a marketplace vendor | **Decide later.** |
| F8 | Modifier order in the pipeline | **Additions first, then multiplications.** |
| F9 | Net-positive harvest check | **Use the proposed check:** production lost while the pool refills must be below the town's share of one harvest; the web app warns per rule. |
| F10 | Town's share of a harvest when Output is full | **Lost to the town** (rejected, stays in `SYS_PRODUCTION`, like a full line); the player's share is still paid. |
| F11 | Uncollected warehouse reservations | **Expire**, released at the next planner run. The exact model is settled in P9. |
| F12 | Filing Later items | File the Later logistics rules ([#324](https://github.com/PandiO/knk-workspace/issues/324)) and the shop turnover tax ([#325](https://github.com/PandiO/knk-workspace/issues/325)). Clan council governance and harvest professions/paid work are for a **later stage** than those; not filed yet. |

## 12. Territory as a V1 requirement (2026-11-11)

Developer request, 2026-11-11: **Territory is required for V1.** Production structures mostly stand in the rural
parts of towns, they must still be connected to a town, and their regions need the same field validation as
districts and gate structures. Replaces the "minimal, optional region" recommendation of DESIGN D1.

Folded into DESIGN §3.4 and IMPLEMENTATION_PLAN P2. Proposals there still to confirm: a required region and town
claim, which region rules block or warn (T1-T7), and no overlap with other territories or towns (a new
`RegionNoOverlap` rule type).
