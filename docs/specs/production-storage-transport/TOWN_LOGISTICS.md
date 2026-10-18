# Town logistics: warehouses, distribution and saving rules, trade and pricing

**Status:** Draft (rev. 2 companion to [DESIGN.md](DESIGN.md)). It covers the developer's notes 15, 16 and 17
(2026-10-09). The developer asked for written-down town-management rules; none were found in the repository beyond
the fragments cited here. §4 is a **proposed rule catalogue** for review.

Most of the developer's **pricing** work (Word documents and iPhone notes) is **not in the repository**. It must be
imported before §7 can be completed; see D-L6.
**Last updated:** 2026-10-09
**Linear:** [KNG-83](https://linear.app/kngpandi/issue/KNG-83) (parent); phases in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

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
- **distribute** to consumers: shops and workshops that process resources into goods, garrisons, construction;
- **trade** with other towns by sending and receiving transports;
- **accept** player sales and, per concept L212, items forfeited by combat-loggers.

Everything moves as stock transactions and transport orders (DESIGN §4, §7). This document defines the **rules**
that decide what moves where, and the **pricing** hook that reads the result.

## 2. Network inside a town

- A town has one or more warehouses. Each warehouse has a **service area**: the districts and territories whose
  producers deliver to it and whose consumers it supplies. Default: nearest by road lane.
- The **town view** aggregates all its warehouses:
  - stock per blueprint;
  - days of cover = stock ÷ average daily consumption;
  - inflow and outflow rates.
- Warehouses can **rebalance** between themselves (a transfer order) when one is short and another has surplus.

## 3. Consumers and demand

A **consumer** is any structure with an `Input` or `Merchandise` storage: shop, workshop, garrison, construction
site. Demand is expressed by **replenishment settings** per consumer storage and blueprint. This is classic min/max
replenishment:

- `ReorderPoint` (min): when stock falls to it, request supply.
- `TargetLevel` (max): request up to this amount.
- `Priority class`: see §4.

Shop and workshop levels (DESIGN §10) set default min and max values. Admins, and later owners, can override them.
Demand also comes from:

- trade agreements (exports);
- construction and upgrades (resource costs, PRODUCTION_KINDS §5);
- player purchases (merchandise drawdown).

## 4. Rule catalogue (proposed)

A town has a `LogisticsPolicy` (versioned), plus optional per-warehouse policies. A policy is a list of
`LogisticsRule`s. Every rule has:

- scope: town or warehouse;
- target: blueprint, category or tag;
- parameters;
- an active window;
- the author: admin, or later the clan council;
- a reason text, shown in the web app's planner explanation.

| Type | Meaning | Parameters | Example |
|---|---|---|---|
| **Reserve** (saving rule) | Stock that may not be distributed or exported below this level. | units, or days of cover; town-wide or local | "Keep 14 days of bread town-wide." "Docks Warehouse keeps 500 planks." |
| **Ceiling** | Maximum stock. Inbound above it is redirected to another warehouse; surplus becomes an export candidate. | units | "Max 2,000 cobblestone at Docks." |
| **Allocation quota** | Shares of the **distributable** stock (above reserve) per consumer group. This is concept L168's "distribute stock evenly by predefined percentage". | % per group (shop category, structure, garrison) | "Iron: 50% blacksmiths, 30% armories, 20% garrison." |
| **Priority class** | Under scarcity, higher classes are served first; quotas apply inside a class. | `Critical`, `High`, `Normal`, `Low` per consumer or group | Garrison food is `Critical`. |
| **Service area / routing** | Which warehouse serves which districts and territories; inbound preference for producers. | mapping | "Rural north → North Granary." |
| **Rebalance** | Keep warehouses within a band of each other for a blueprint. | min share per warehouse, trigger gap | |
| **Export / import** | What may leave or enter, how much per period, minimum reserve before export, embargoes (power plays). | allow/deny lists, caps, partner towns | "No iron exports to Hostile Town." |
| **Emergency mode** | A policy switch that overrides the others while active. | mode | **Siege:** exports frozen, military priority up. **Famine:** food reserves doubled. |
| **Tax / tariff** (needs town accounts) | A percentage on trade and sales into the town treasury. | % per category | Concept L236 "tax rate". |

**Governance.**

- **Unmanaged town** (no ruling player clan): a default policy template for its size and specialization (concept
  L144: "some towns are iron/wood-rich, others fish/wheat-rich").
- **Ruled town:** the clan council proposes changes, which take effect at the weekly council (concept L236). Trade
  agreements can change at any time.
- Every policy change is a new version, kept for audit and for the dashboard ("since Tuesday the bread reserve is
  14 days").

## 5. Planner

`LogisticsPlanner` runs per town on an interval (and on demand, with a dry run in the web app):

1. Compute per blueprint: available = stock − reserves, per warehouse and town-wide.
2. Collect demand: consumers at or below their reorder point, upgrade and construction needs, export commitments.
3. Satisfy demand by priority class; inside a class, by quota; then by distance (lane cost).
4. Create **Distribution** orders (warehouse → consumer) and **Rebalance** orders, bundling lines per destination up
   to carrier capacity.
5. Create **Trade** orders due under agreements (§6).
6. Record a **plan explanation** per order: which rule, which shortfall, which priority. The web app shows "why did
   (or didn't) the bakery get flour".

Producers' automatic orders (DESIGN §7.4) bring stock **in**. The planner moves it **out** and **around**. Both use the
same transport lifecycle and carriers, so distribution and trade routes can also be escorted, ambushed and robbed
(note 17).

## 6. Inter-town trade

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

## 7. Pricing hook (note 16)

The intent: item prices follow **real supply and demand**, starting from `ItemBlueprint.BasePriceMin/Max`, with
further multipliers.

The developer's detailed pricing work is not in this repository. The fragments that are here:

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

| # | Question | Recommendation |
|---|---|---|
| D-L1 | Push or pull distribution | Pull (consumer min/max) plus push of surplus above ceilings. |
| D-L2 | Planner interval | 10 minutes per town, plus on-demand dry runs. |
| D-L3 | Default policy for unmanaged towns | A template per town specialization, editable by admins in the web app. |
| D-L4 | Who bears trade losses | The sender until delivery (CIF-like). Insurance or escort contracts can shift it later. |
| D-L5 | Town treasury | A new currency `AccountKind.Town`. Designed with the currency owner before trade or tax ships. |
| D-L6 | Pricing model | **Import the developer's pricing documents** (Word files, iPhone notes) into `docs/specs/` first. Then replace §7's placeholder. Tracked as its own issue. |
| D-L7 | Player sales to warehouses (concept L168) | Through a shop or warehouse terminal at the current town price. Goods enter as `Deposit` moves with payment. Designed with shops. |
