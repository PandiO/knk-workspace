# Pricing: the developer's supply-and-demand notes

**Status:** Source transcription (step 2 of [#120](https://github.com/PandiO/knk-workspace/issues/120), `[KNG-101]`).
The transcription and translation are faithful to the notes; §4-6 are analysis and proposals for review. Nothing is
implemented, and the pricing model is not decided yet.
**Last updated:** 2026-11-11
**Source:** the developer's handwritten notes "Vraag- en aanbodformules uitleg" (supply and demand formulas
explained), 2 pages, Dutch, shared 2026-11-11: [source/vraag-en-aanbodformules-uitleg.pdf](source/vraag-en-aanbodformules-uitleg.pdf).
**Related:** [TOWN_LOGISTICS §7](../production-storage-transport/TOWN_LOGISTICS.md) (pricing hook),
[shops DESIGN §4](../shops/DESIGN.md) (interim pricing), [#325](https://github.com/PandiO/knk-workspace/issues/325)
(turnover tax and shop margins).

**Revision history**

- **2026-11-11:** first transcription, translation and analysis.

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

Read with a **falling** demand line (see §5, Q1):

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

| # | Question | Proposal |
|---|---|---|
| Q1 | The notes write `Qd = 10p + …`, but "10 = demand **drop** per price increase of 1". Is it `Qd = −10p + (20I + 10sp)`? | Yes, a minus. With `+10p` demand would rise with price and the equilibrium becomes `p = 4I + 5sp − T/5`, which runs away for a large village. |
| Q2 | Is the result the shop's sell price directly, or a basis that the shop level, shop tax and margin (#325) then multiply? | Basis; shop level and tax/margin on top, so levels and #325 keep their meaning. |
| Q3 | Should the price stay inside a band (for example `BasePriceMin`..`BasePriceMax`, or ×0.5..×2 of `sp`), and should it move gradually from hour to hour? | Clamp to a band and smooth (move part of the way each period), so one empty hour doesn't spike the price. |
| Q4 | Is `I` per village (town), per district, or the shop's own customers from the start? | Town player count first, then the shop's customers per period, as the notes say. |
| Q5 | Is buy-back (what the shop pays players) derived from the same `p*`? | Yes: buy-back = `p*` × buy-back % (default 50%). |
| Q6 | Are `a`, `b`, `d` set per blueprint, per category, or both? | Per category with optional per-blueprint overrides. |
| Q7 | The notes say "Word documents and iPhone notes" too (#120 step 1). Are there more pricing notes to import, or are these pages the model? | Import any others into this folder before the pricing design. |

## 6. Next step

After the answers: write `docs/specs/pricing/DESIGN.md` with the confirmed formula, its parameters and storage, the
price sweep, bands and smoothing, how shop level, tax and margins apply (#325), and then replace TOWN_LOGISTICS §7's
placeholder.
