# Pricing: the developer's supply-and-demand notes

**Status:** Source transcription (step 2 of [#120](https://github.com/PandiO/knk-workspace/issues/120), `[KNG-101]`).
The transcription and translation are faithful to the notes; §4-6 are analysis and decisions. Nothing is implemented.
**The notes are a foundation, not a worked-out model** (developer, 2026-11-11): they show how prices should react to
player consumer behaviour. **Not for V1:** without real player behaviour, and with a small player count, it would
not work well. V1 shops keep the interim pricing (shops DESIGN §4).
**Last updated:** 2026-11-11
**Source:** the developer's handwritten notes "Vraag- en aanbodformules uitleg" (supply and demand formulas
explained), 2 pages, Dutch, shared 2026-11-11: [source/vraag-en-aanbodformules-uitleg.pdf](source/vraag-en-aanbodformules-uitleg.pdf).
**Related:** [TOWN_LOGISTICS §7](../production-storage-transport/TOWN_LOGISTICS.md) (pricing hook),
[shops DESIGN §4](../shops/DESIGN.md) (interim pricing), [#325](https://github.com/PandiO/knk-workspace/issues/325)
(turnover tax and shop margins).

**Revision history**

- **2026-11-11:** first transcription, translation and analysis. The same day the developer answered Q1-Q5 and
  left Q6 to this session (§5), and set the status: a foundation, Later, damped for small player counts (§5a).

## 1. Transcription (Dutch, as written)

Page 1:

> Om de evenwichtsprijs te berekenen moet je een aantal gegevens weten om formules op te kunnen stellen. Elke vraag-
> en aanbodformule verschilt per product. De formules in dit voorbeeld zijn gebaseerd op aardappelen.
>
> De gegevens die je vooraf moet weten:
> - p = huidige prijs van het product
> - sp = standaardprijs van het product
> - I = aantal inwoners in dorp van de winkel (later zeer waarschijnlijk klantenaantal van afgelopen periode)
> - T = toevoer van het product naar de winkel (toevoer bestaat uit vaste voorraad-aanvulling en losse verkoop van
>   spelers aan de winkel)
> - 10 = vraagdaling per prijsverhoging van 1 (nodig om relatie tussen vraag en prijs aan te geven)
> - 20 = oorspronkelijke gemiddelde vraag van het product per speler in een bepaalde periode (in dit geval 1 uur)
> - 15 = aanbodsteiging per prijsverhoging van 1
> - Gegevens zoals toevoer en oorspronkelijke vraag zijn/worden berekend voor een specifieke tijdsperiode (1 uur).

Page 2:

> - Vervolgens kunnen we hiermee de Q-demand en Q-supply maken.
>
>   Qd = 10p + (20I + 10sp)
>
>   Qs = 15p + (T − 15sp)
>
> - Dan kan je nu de formules herformuleren naar p = …
> - Stel vervolgens beide p = …-formules aan elkaar gelijk. Hier komt een getal uit, vul deze in in een van de
>   p = …-formules om de evenwichtsprijs te krijgen.
> - Deze stappen blijven herhalen elke vooraf bepaalde periode van tijd (in dit geval elk uur).

## 2. Translation (English)

To calculate the **equilibrium price** you need some data to set up the formulas. Every demand and supply formula
is different per product. The formulas in this example are based on **potatoes**.

Data you need first:

- **p** = the current price of the product;
- **sp** = the standard price of the product;
- **I** = the number of inhabitants of the shop's village (later very likely the number of customers in the last
  period);
- **T** = the supply of the product to the shop (supply is the fixed stock replenishment plus occasional sales by
  players to the shop);
- **10** = the drop in demand per price increase of 1 (needed to express the relation between demand and price);
- **20** = the original (average) demand for the product per player in a given period (here 1 hour);
- **15** = the rise in supply per price increase of 1;
- data such as supply and original demand are calculated for a specific time period (1 hour).

Then we can build Q-demand and Q-supply:

```
Qd = 10p + (20I + 10sp)
Qs = 15p + (T − 15sp)
```

Rewrite both formulas to `p = …`. Set the two `p = …` formulas equal to each other. That gives a number; fill it in
one of the `p = …` formulas to get the equilibrium price. Repeat these steps every set period of time (here every
hour).

## 3. The model in general form

Per **shop and product**, recalculated **every period** (1 hour in the example):

| Symbol | Meaning | Example (potatoes) |
|---|---|---|
| `p` | price (the unknown) | |
| `sp` | standard price | |
| `I` | inhabitants of the shop's village; later customers in the last period | |
| `T` | supply to the shop in the period: stock replenishment + player sales to the shop | |
| `a` | demand drop per +1 price | 10 |
| `d` | average demand per player per period at the standard price | 20 |
| `b` | supply rise per +1 price | 15 |

With a **falling** demand line (confirmed by the developer 2026-11-11, §5 Q1; the notes' `+10p` is a slip):

```
Qd(p) = d·I − a·(p − sp)        = −a·p + (d·I + a·sp)      → with the example: −10p + (20I + 10sp)
Qs(p) = T   + b·(p − sp)        =  b·p + (T − b·sp)         → with the example:  15p + (T − 15sp)
```

At the standard price, demand is `d·I` and supply is `T`. Setting `Qd = Qs` gives the equilibrium price directly:

```
p* = sp + (d·I − T) / (a + b)              example: p* = sp + (20I − T) / 25
```

So the price rises above the standard price when demand at the standard price exceeds supply, and falls below it
when supply exceeds demand. `a + b` sets how strongly it reacts.

**Worked example** (numbers chosen for illustration, not from the notes): `sp = 5`, `I = 10`, `T = 150` per hour.
`p* = 5 + (200 − 150) / 25 = 7`. Check: `Qd = −70 + 200 + 50 = 180`, `Qs = 105 + 150 − 75 = 180`.

The notes' two-step method (rewrite to `p = …`, set equal, substitute back) gives the same result; solving `Qd = Qs`
for `p` in one step is equivalent.

## 4. How it maps onto the V3 design

| Notes | V3 source | Notes on the mapping |
|---|---|---|
| `sp` standard price | `ItemBlueprint` base price: the midpoint of `BasePriceMin`/`BasePriceMax` (decision 2026-11-11, F1) | The interim shop price already uses it. |
| `I` inhabitants / customers | first: a town's population or player count; later: distinct customers of the shop in the last period (from the sales ledger) | V3 has no "inhabitants" of a village yet. |
| `T` supply to the shop | stock moves **into** the shop's Merchandise in the period: collections from the warehouse (reserve and collect, TOWN_LOGISTICS §5) + buy-backs from players (shops DESIGN §3.2) | Both are ledger moves, so `T` is a sum over `StockMove`s. Processing output of a processing shop also counts as supply (proposal). |
| `a`, `b`, `d` | per-product parameters, "different per product" | Proposed: on the blueprint or its category, with defaults per category, edited in the web app. |
| period (1 hour) | a price sweep per shop | Like the production sweep, with an injectable clock. |
| equilibrium price `p*` | the shop's sell price for the next period | Static catalogue prices still win (shops DESIGN §4). |

This replaces the placeholder formula in TOWN_LOGISTICS §7 (scarcity from days of cover) **once confirmed**. The
`SupplyDemandSnapshot` there already holds the inputs (inflow, outflow, sales).

## 5. Questions for the developer

Answered 2026-11-11:

| # | Question | Answer |
|---|---|---|
| Q1 | The notes write `Qd = 10p + …`, but "10 = demand **drop** per price increase of 1". Is it `Qd = −10p + (20I + 10sp)`? | **Yes, a minus.** So `p* = sp + (d·I − T) / (a + b)`. |
| Q2 | Is `p*` the shop's sell price directly, or a basis? | **A basis.** Shop level, shop tax and later the margin and turnover tax (#325) apply on top. |
| Q3 | Band and smoothing? | **Clamp and smooth:** keep the price inside a band (for example `BasePriceMin`..`BasePriceMax`) and move part of the way to `p*` each period. Band and step size to design. |
| Q4 | What `I` counts | **The town's player count first**, then the shop's distinct customers in the last period once sales data exists. |

Answered later the same day:

| # | Question | Answer |
|---|---|---|
| Q5 | Is buy-back derived from the same `p*`? | **Yes:** the shop pays the equilibrium-based price × 50%. |
| Q6 | What are 10/15/20, and where are they set? | The developer doesn't remember what the exact numbers stood for and left it to this session. **Decision (session, reversible):** they are example values only. `a`, `b` and `d` are parameters **per item category with optional per-blueprint overrides**, edited in the web app, and tuned from real data. Defaults are set so that the price moves slowly (§5a). |
| Q7 | More pricing notes to import? | Not known. The developer wrote these notes a while back and added them as they are; import anything else that turns up into this folder. |

## 5a. Damping for a small player base (developer, 2026-11-11)

With few players the price must **not fluctuate much or wildly**. Proposed, to settle in the pricing design:

- **Narrow band:** clamp the final price to a band around `sp` (for example ×0.8..×1.25 to start), within
  `BasePriceMin`..`BasePriceMax`.
- **Slow steps:** each period, move only a small fraction of the way from the current price to `p*` (for example
  10%).
- **Confidence by volume:** scale that fraction by how much real trade there was (sales and supply in the period
  against a minimum volume). With almost no trade the price barely moves and drifts back to `sp`.
- **Longer period while quiet:** compute over a rolling window (for example 24 hours) instead of a single hour until
  trade volume is high enough.

## 6. Next step

**Later**, once the game has real player behaviour to price from: write `docs/specs/pricing/DESIGN.md` with the formula,
its parameters and storage, the price sweep, the damping in §5a, how shop level, tax and margins apply (#325), and
then replace TOWN_LOGISTICS §7's placeholder. Until then V1 uses the interim pricing. The inputs are recorded from V1 on as hourly
trade stats per shop and blueprint ([shops DESIGN §9.1](../shops/DESIGN.md#91-hourly-trade-stats-v1-developer-2026-11-11)),
decided by the developer 2026-11-11, so the later switch starts from real data.
