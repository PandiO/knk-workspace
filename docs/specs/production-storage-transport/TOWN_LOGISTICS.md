# Town logistics: warehouses, distribution and saving rules, trade and pricing

**Status:** Draft (rev. 3 companion to [DESIGN.md](DESIGN.md)). It covers the developer's notes 15, 16 and 17
(2026-10-09) and the voice design review of 2026-11-05 ([decision record](DECISIONS_2026-11-05.md) §5). The whole rule
catalogue in §4 belongs to the concept; rev. 3 splits it into a **V1 subset** and **Later** rules. Tags: **[V1]**,
**[Later]**, **[Parked]** (DESIGN header).

Most of the developer's **pricing** work (Word documents and iPhone notes) is **not in the repository**. It must be
imported before §7 can be completed; see D-L6.
**Last updated:** 2026-11-11 (open questions answered, [decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11))
**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22) (`[KNG-83]`, parent); phases
in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

**Revision history**

- **Rev. 2 (2026-10-09):** warehouses as hubs, proposed rule catalogue, planner, inter-town trade, pricing hook.
- **Rev. 3 (2026-11-05, [decision record](DECISIONS_2026-11-05.md) §5, §6):**
  - Distribution is **reserve and collect**: warehouses reserve, consumers send their own worker to collect (§5).
    Warehouses have no workers in V1.
  - V1 rule subset: reorder points and target levels, town reserves, priority classes, service areas. The other
    rules are [Later] (§4).
  - Governance confirmed: admin-edited default templates, a 10-minute planner with dry runs. Clan councils and
    in-game management are [Later] (§4.1).
  - Warehouse throughput is [Later] (§5.2).
  - Player sales now happen through shops in V1 (D-L7, [shops DESIGN](../shops/DESIGN.md)).
- **2026-11-11 ([decision record §11](DECISIONS_2026-11-05.md#11-follow-up-decisions-2026-11-11)):** a minimal town account kind moves into V1 for shop income (D-L5);
  reservations expire at the next planner run; the Later rules ([#324](https://github.com/PandiO/knk-workspace/issues/324)) and a shop turnover tax
  ([#325](https://github.com/PandiO/knk-workspace/issues/325)) have issues.

**Sources found in the repo:**

- concept v0.2 (`archive/vision-history/concept-v0.2-2020.md`):
  - L164: "stock/prices vary with supply from warehouses";
  - L168: warehouses are "town-owned storage/distribution hubs; collect and distribute resources to shops, enable
    inter-town trade agreements, and accept player item sales. Unmanaged, they distribute stock evenly by predefined
    percentage; once a clan rules the town, the clan sets distribution percentages in weekly councils";
  - L212: a combat-logger's inventory goes "into the nearest village/town's warehouse, later purchasable on the
    market";
  - L236: a ruling clan sets "the percentage of stock allocated to eligible shops, tax rate, bank interest rate…, and
    propose/accept/reject/counter trade agreements (7-day terms)";
- vision §4.3: town economy simulation with circumstances vs events;
- vision §4.4: game balance over realism;
- iPhone notes:
  - L278-279: artificial economy based on supply and the number of players; dynamic supply and demand;
  - L297-298: ambush risk "voor spelers en trade routes" (for players and trade routes);
  - L313-318: autonomous towns, technology, market-segment value factors;
- V1 `PropertyProduct`: daily stock and weekly price.

## 1. Purpose

Warehouses are a town's **central storage hubs** (note 15). They:

- **receive** production from the town's producers;
- **store** it, applying town-wide and per-warehouse **saving (reserve) rules**;
- **reserve** stock for consumers (shops, workshops that process resources into goods, garrisons, construction),
  which collect it with their own workers (§5);
- **trade** with other towns by sending and receiving transports [Later];
- take items forfeited by combat-loggers, per concept L212 [Later].

Player sales go through **shops** in V1 ([shops DESIGN](../shops/DESIGN.md)), not to the warehouse directly (D-L7).

Everything moves as stock transactions and transport orders (DESIGN §4, §7). This document defines the **rules**
that decide what moves where, and the **pricing** hook that reads the result.

## 2. Network inside a town

- A town has one or more warehouses. Each warehouse has a **service area**: the districts and territories whose
  producers deliver to it and whose consumers it supplies. Default: nearest by road lane.
- The **town view** aggregates all its warehouses:
  - stock per blueprint;
  - days of cover = stock ÷ average daily consumption;
  - inflow and outflow rates.
- Service areas default to the **nearest warehouse by road** [V1].
- [Later] Warehouses **rebalance** between themselves (a transfer order) when one is short and another has surplus.

## 3. Consumers and demand

A **consumer** is any structure with an `Input` or `Merchandise` storage: shop, workshop, garrison, construction
site. Demand is expressed by **replenishment settings** per consumer storage and blueprint. This is classic min/max
replenishment:

- `ReorderPoint` (min): when stock falls to it, the warehouse reserves supply for this consumer [V1].
- `TargetLevel` (max): reserve up to this amount [V1].
- `Priority class`: see §4 [V1].

Each consumer has its **own worker** [V1], like a producer (DESIGN §7.7). The worker collects reserved goods from the
warehouse. While the worker is away, the consumer's own output or service is lowered, the same as at a producer.

Shop and workshop levels (DESIGN §10) set default min and max values. Admins, and later owners, can override them.
Demand also comes from:

- player purchases (merchandise drawdown) [V1];
- construction and upgrades (resource costs, PRODUCTION_KINDS §5);
- trade agreements (exports) [Later].

## 4. Rule catalogue

A town has a `LogisticsPolicy` (versioned), plus optional per-warehouse policies. A policy is a list of
`LogisticsRule`s. Every rule has:

- scope: town or warehouse;
- target: blueprint, category or tag;
- parameters;
- an active window;
- the author: admin, or later the clan council;
- a reason text, shown in the web app's planner explanation.

All amounts are **raw units** (DESIGN §4.4). Days of cover convert to raw units with the average daily consumption.

| Type | Version | Meaning | Parameters | Example |
|---|---|---|---|---|
| **Reorder point / target level** | **V1** | Consumer replenishment settings (§3). | units per consumer storage and blueprint | "Bakery: flour min 50, max 200." |
| **Reserve** (saving rule) | **V1** | Stock that may not be reserved for consumers or exported below this level. | units, or days of cover; town-wide or local | "Keep 14 days of bread town-wide." "Docks Warehouse keeps 500 planks." |
| **Ceiling** | Later | Maximum stock. Inbound above it is redirected to another warehouse; surplus becomes an export candidate. | units | "Max 2,000 cobblestone at Docks." |
| **Allocation quota** | Later | Shares of the **distributable** stock (above reserve) per consumer group. This is concept L168's "distribute stock evenly by predefined percentage". | % per group (shop category, structure, garrison) | "Iron: 50% blacksmiths, 30% armories, 20% garrison." |
| **Priority class** | **V1** | Under scarcity, higher classes are served first; quotas apply inside a class. | `Critical`, `High`, `Normal`, `Low` per consumer or group | Garrison food is `Critical`. |
| **Service area / routing** | **V1** | Which warehouse serves which districts and territories; inbound preference for producers. | mapping | "Rural north → North Granary." |
| **Rebalance** | Later | Keep warehouses within a band of each other for a blueprint. | min share per warehouse, trigger gap | |
| **Export / import** | Later | What may leave or enter, how much per period, minimum reserve before export, embargoes (power plays). | allow/deny lists, caps, partner towns | "No iron exports to Hostile Town." |
| **Emergency mode** | Later | A policy switch that overrides the others while active. | mode | **Siege:** exports frozen, military priority up. **Famine:** food reserves doubled. |
| **Tax / tariff** (needs town accounts; [#324](https://github.com/PandiO/knk-workspace/issues/324), shop turnover tax [#325](https://github.com/PandiO/knk-workspace/issues/325)) | Later | A percentage on trade and sales into the town treasury. | % per category | Concept L236 "tax rate". |

Service areas default to the nearest warehouse by road; admins can override the mapping.

### 4.1 Governance

- **[V1] Default policy templates** per town size and specialization (concept L144: "some towns are iron/wood-rich,
  others fish/wheat-rich"), **edited by admins in the web app** (D-L3, confirmed).
- **[Later, later stage] Ruled town:** the clan council proposes changes, which take effect at the weekly council (concept L236).
  Trade agreements can change at any time.
- **[Later]** runtime management (distribution rules, reserves, taxes) also becomes available **in game**
  ([#256](https://github.com/PandiO/knk-workspace/issues/256); town roles and visibility in
  [#246](https://github.com/PandiO/knk-workspace/issues/246)).
- Every policy change is a new version, kept for audit and for the dashboard ("since Tuesday the bread reserve is
  14 days").

## 5. Planner: reserve and collect [V1] (rev. 3)

Distribution is **pull**, from the developer's earlier concept (D-L1). The warehouse **reserves** stock; the consumer
**collects** it with its own worker. So the rev. 2 "Distribution orders" become **reservations + collection orders**
carried by the consumer.

`LogisticsPlanner` runs per town every **10 minutes** (D-L2, confirmed), and on demand with a dry run in the web app:

1. Compute per blueprint: available = stock − reserves − open reservations, per warehouse and town-wide.
2. Collect demand: consumers at or below their reorder point, upgrade and construction needs.
3. Satisfy demand by **priority class** (for example garrisons first under scarcity); inside a class, by distance
   (lane cost).
4. Create a **reservation** per consumer and blueprint, up to its target level, at the warehouse of its service
   area. A reservation holds stock without moving it.
5. Create a **collection order** (a `TransportOrder` with origin `Distribution`) carried by the consumer's own worker.
   The worker's capacity bounds it; if no worker is free, it waits. On collection the reserved stock moves warehouse →
   transit → consumer storage.
6. Record a **plan explanation** per reservation and order: which rule, which shortfall, which priority. The web app
   shows "why did (or didn't) the bakery get flour".

While a consumer's worker is away, its output or service is lowered (DESIGN §7.7). **Warehouses have no workers in
V1.**

Producers' automatic orders (DESIGN §7.4) bring stock **in**. Consumers' collection orders take it **out**. Both use
the same transport lifecycle. In V1 both are simulated; later they can be carried, escorted, ambushed and robbed like
any transport (note 17).

[Later] in the planner ([#324](https://github.com/PandiO/knk-workspace/issues/324)): allocation quotas inside a priority class, ceilings and push of
surplus, rebalance orders, trade orders under agreements (§6), emergency modes.

### 5.1 Reservations

A reservation is a claim on warehouse stock for one consumer storage. Proposed shape: warehouse storage, consumer
storage, blueprint, amount, created and expiry time, the collection order. Reserved stock can't be reserved twice or
exported. A reservation that isn't collected before its expiry is released at the next planner run (F11, confirmed
2026-11-11). The exact model is decided in P9.

### 5.2 Warehouse throughput [Later]

[Later] ([#253](https://github.com/PandiO/knk-workspace/issues/253)): **warehouse workers** cap **throughput**
(deliveries unloaded per hour, so busy hubs become bottlenecks), take care of spoilage, and carry inter-warehouse
transfers (rebalance).

## 6. Inter-town trade [Later]

Later, with town treasury accounts ([#124](https://github.com/PandiO/knk-workspace/issues/124), KNG-100; D-L5).

A `TradeAgreement` has:

- partner towns A and B;
- goods lines: blueprint, amount per period, direction;
- a price per unit, or barter;
- a period;
- a term (default 7 days, concept L236);
- carrier requirements (mode, escort);
- risk responsibility: who bears losses from robbery (D-L4);
- status: proposed, countered, active, expired, broken.

- Each period, the planner creates trade orders from the sender's warehouse, respecting reserves and export rules.
- Payment settles on delivery through the currency service, between town accounts. These **need a new
  `AccountKind`** (currency DESIGN account kinds are `User` and `System` only).
- A delivery shortfall (robbery, shortage) is recorded against the agreement. Repeated failures can break it.
- Power plays: embargoes (export rules), raiding a rival's trade routes, and protecting your own with escorts and law
  buildings (DESIGN §7.5).

## 7. Pricing hook (note 16) [Later]

Supply-and-demand pricing is later and **needs the developer's pricing documents imported first** (D-L6,
[#120](https://github.com/PandiO/knk-workspace/issues/120), KNG-101). Until then shops use the **interim pricing** in
the [shops design](../shops/DESIGN.md): a static catalogue price, or base price × shop tax × shop level, with a 50%
buy-back.

**2026-11-11:** the developer's handwritten supply-and-demand notes are transcribed in
[pricing/SUPPLY_DEMAND_NOTES.md](../pricing/SUPPLY_DEMAND_NOTES.md): a linear demand and supply line per shop and
product, solved for the equilibrium price every hour (`p* = sp + (d·I − T) / (a + b)`). It is the candidate to replace
the placeholder below; open questions are listed there.

The intent: item prices follow **real supply and demand**, starting from `ItemBlueprint.BasePriceMin/Max`, with
further multipliers.

Apart from those notes, the developer's pricing work is not in this repository yet. Other fragments:

- vision §4.4 (balance over realism);
- vision §9.1 (the base price range feeds supply and demand);
- concept L164;
- iPhone L278-279 (prices derived from capacity: how many houses and players fit; dynamic supply and demand);
- iPhone L318 (factors from market-segment values, e.g. the agricultural sector or the steel industry);
- V1 `PropertyProduct.saveWeeklyProductPrice` (random in [min, max] × (1 + contribution/100)) and daily stock.

**What this network provides to any pricing model.** A daily `SupplyDemandSnapshot` per (town, blueprint):

- stock;
- days of cover;
- inflow (production, imports);
- outflow (consumption, sales, exports);
- unmet demand;
- trade prices.

**Placeholder structure until the developer's model is imported:**

```
price(town, blueprint) = basePrice(blueprint)                        — midpoint of BasePriceMin..Max
                       × scarcity(daysOfCover / targetCover)           — clamped curve, >1 when scarce
                       × shopLevel(price multiplier)                   — note 12
                       × circumstances/events                          — vision §4.3
                       × (1 + tax)
clamped to [BasePriceMin × lowBand, BasePriceMax × highBand], smoothed day over day
```

## 8. Decisions

Outcomes of the 2026-11-05 review ([decision record](DECISIONS_2026-11-05.md) §9).

| # | Question | Outcome |
|---|---|---|
| D-L1 | Push or pull distribution | **Pull via reserve and collect** (§5): warehouses reserve, consumers collect with their own worker. No push of surplus in V1. |
| D-L2 | Planner interval | **Confirmed:** 10 minutes per town, plus on-demand dry runs. |
| D-L3 | Default policy for unmanaged towns | **Confirmed:** a template per town size and specialization, edited by admins in the web app. |
| D-L4 | Who bears trade losses | [Later], with trade. Recommendation stands: the sender until delivery (CIF-like). Insurance or escort contracts can shift it later. |
| D-L5 | Town treasury | **Changed 2026-11-11 (F2):** a minimal currency `AccountKind.Town` ships in **V1** so shop income goes to the town. Designed with the currency owner. Trade, tax and spending from it (for example the carrier pool for hire) stay [Later] ([#124](https://github.com/PandiO/knk-workspace/issues/124)). |
| D-L6 | Pricing model | **Still required:** import the developer's pricing documents (Word files, iPhone notes) into `docs/specs/` first, then replace §7's placeholder (#120). |
| D-L7 | Player sales to warehouses (concept L168) | **Player sales now happen through shops in V1** ([shops DESIGN](../shops/DESIGN.md)). Selling to a warehouse terminal is not part of V1. |
