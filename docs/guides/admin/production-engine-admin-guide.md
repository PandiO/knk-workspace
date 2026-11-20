# Production Engine — Admin Guide

**Status:** Current · **Last updated:** 2026-11-20 (P5: workers away carrying, docs #891); 2026-11-20 (P4 pointers to the yield areas admin guide; docs #882); 2026-11-19 (first version, production P3 #86/#678, docs PandiO/knk-workspace#839)
**Checked against:** knk-web-api `next` `6c648f60`, knk-web-app `next` `4e4ca39a` (not released; the engine runs only
with the game setting Production enabled on; the manual steps of the
[smoke test § 4](../production-storage-transport-smoke-test.md#4-phase-p3-production-engine-86-api-678-web-app-tier3)
have not been run live yet)
**Related:** [PRODUCTION_KINDS § 2–5](../../specs/production-storage-transport/PRODUCTION_KINDS.md) (the rules),
[production engine architecture](../../architecture/production-engine.md) (settle, formula, weather, tests),
[API contract](../../specs/api/API_CONTRACT_PRODUCTION_ENGINE.md), [warehouses and production structures admin
guide](production-world-admin-guide.md) (creating the structures), [stock admin guide](stock-admin-guide.md)
(storages, Adjust and Move), [territory admin guide](territory-admin-guide.md) (the Production and territory card),
[staff web app guide](staff-web-app-guide.md) (the dashboard and forms in general)

Production phase P3 makes production structures produce. Each structure has a **kind** (Farm, Logger, Quarry …) and a
**level** from 1 to 10. You give it one **production line** per item it makes, with a rate per hour. Every few minutes
the server **settles** each line: it works out how much was made since the last time, puts the whole units into the
structure's Output storage and keeps the fraction for next time. The rate goes up with the level, changes with the
**weather** of the structure's climate zone and with **modifiers** you create, and drops when **workers** are away.
Every settle leaves a **cycle** you can open to see why the number is what it is. You **upgrade** a structure by paying
the next level's resources and coins.

Players see nothing of this yet: nothing in game shows production, and only staff upgrade structures. The engine does
nothing at all while the game setting **Production enabled** is off; you can set everything up before turning it on.

## 1. What you need

1. **knk-web-api** with migration `AddProductionEngine` applied (after `AddProductionWorld`;
   [production installation § 5.3](../production-installation.md#53-apply-the-migrations) item 8). It seeds eight kinds
   with ten levels each, the climate zone "Default climate" and the weather types Rain, Storm and Drought.
2. **knk-web-app** of the same `next` (or later). An older web app resets the engine settings on every game settings
   save (§ 7).
3. **Seeds.** As content staff, import the form and display seeds `ProductionKind`, `ProductionKindLevel`,
   `ProductionLine`, `ProductionModifier`, `ClimateZone` and `WeatherType`, and the new versions `ProductionStructure -
   Default (seed v2)` (form and display), `ItemBlueprint - Default (seed v2)` (form) and `Storage - Default (seed v2)`
   (display), each with "make default".
4. **Production structures** with their Output storage ([warehouses and production structures admin
   guide](production-world-admin-guide.md)), and the item blueprints they make ([item identity admin
   guide](item-identity-admin-guide.md)).
5. **Production enabled** ticked on the game settings page (card "Production and territory") for anything to run.
6. **Nodes:**

   | To | Node(s) |
   |---|---|
   | See kinds, levels, lines, modifiers, zones, weather types, cycles and a structure's Production panel | `knk.admin.world` |
   | Create and edit them, including the lists on their pages (inputs, odds, towns, effects, level items) | `knk.admin.world` and `knk.admin.content` |
   | Delete them | `knk.admin.world` and `knk.admin.delete` |
   | Settle now, Save workers, Run production now | `knk.admin.world` |
   | Upgrade a structure | `knk.admin.world` and `knk.economy.admin` |
   | Change the engine settings | the game settings page |

   The list editors are enabled with `knk.admin.world` alone; without `knk.admin.content` their save is refused
   ([#842](https://github.com/PandiO/knk-workspace/issues/842)).

## 2. Kinds and levels

Open the **Dashboard**, type **ProductionKind**. The seeded kinds are Farm, Logger, Quarry, Mine, Fishery, Flower farm,
Florist and Animal farm (no Hunter in V1). The list shows Area model, Resource category, Default workers, Structures
(how many use the kind) and Active.

### 2.1 A kind

The kind form has three steps:

1. **Kind:** Name (unique), Description, Icon (a Minecraft material such as `IRON_PICKAXE`), **Area model** and
   **Exclusive areas** (whether the structures' areas may overlap; [yield areas admin guide](production-yield-areas-admin-guide.md) § 3.3), **Resource category** (Crops, Wood,
   Stone, Ore, Fish, Flowers, Animals: what weather and category modifiers act on), Active.
2. **Yield sources and workers:** Allows Derived, Allows Configured, Allows Hybrid (at least one; the yield sources a
   structure of this kind may use, [yield areas admin guide](production-yield-areas-admin-guide.md) § 3.1), **Default workers** (0–100: the workers a new structure of this kind gets), Cycle variation (used
   from P4).
3. **Default storages:** a JSON list of the storages a new structure of this kind gets next to its Output storage, for
   example `[{"purpose":"Input","name":"inputs","maxUnits":500}]` for a kind whose lines consume something. Don't list
   Output (it is always created); at most 10.

A new kind gets its ten levels at once. Changes to the default workers and storages apply to structures created
afterwards, not to existing ones. A kind that structures use can't be deleted ("N production structure(s) use this
kind; give them another kind first."), nor one a modifier targets.

### 2.2 Levels

A kind's page lists its ten levels: Yield, Cycle speed, Max area, Output cap, Upgrade coins, Upgrade cost and Unlocks.
Click a level to open it. Levels can't be added or removed, only edited. The level form:

1. **Level:** **Yield multiplier** (0–100; level 1 is 1, each level adds 0.15 up to 2.35 at level 10) and **Cycle
   speed** (how often the line settles: 2 = twice as often; it does not change the amount per hour; 1 to 1.45 by
   default). **Max area size** caps the structures' areas ([yield areas admin guide](production-yield-areas-admin-guide.md) § 3.2).
2. **Caps:** **Output storage cap** (Max units of the structure's Output storage), **Units per slot** and **Transport
   capacity**. They are written to the structure when it reaches this level (create, upgrade or a level change on its
   form); left empty they leave the structure as it is. The seeded levels leave all three empty. **Upkeep reduction**
   has no effect yet.
3. **Upgrade:** **Upgrade coins** (paid to reach this level: 0 at level 1, then 250, 1 000, 2 250 … 20 250 at level 10)
   and Upgrade duration (stored, not used: an upgrade is immediate).

Below the form, the **level items** list holds what this level unlocks and what it costs besides coins. **Add item**,
pick the **Role**: "Unlock (produced from this level on)" or "Upgrade cost (paid to reach this level)", the
**Blueprint**, and for a cost the **Amount**; then **Save items**. A blueprint unlocked at level 4 produces nothing on
a level 1–3 structure: its line shows "Unlocked at level 4 (the structure is level 2)."

### 2.3 Giving a structure its kind

On the production structure's form (seed v2), the **Production** step has **Production kind** before **Level**. A new
structure with a kind gets the kind's Default workers (unless you fill in Workers), its Default storages and its level's
caps. Changing the kind or the level of an existing structure writes the new level's caps; the time before the change
is settled at the old values first.

## 3. Production lines

A line is one item a structure makes. Create it from the structure's page (**Production** panel → **Add a production
line**) or from the **ProductionLine** dashboard list. The form has one step, **Output**:

1. **Production structure** (pick it; the form isn't pre-filled from the structure page) and **Output** (the item
   blueprint). One line per blueprint per structure.
2. **Rate source:** Configured for a line you make by hand (Derived and Hybrid lines are made from the surveys,
   [yield areas admin guide](production-yield-areas-admin-guide.md) § 4.3). **Rate per hour:** units per hour at level multiplier 1 with
   every worker present (0 to 1 000 000).
3. **Resource category** (optional): overrides the kind's for weather and category modifiers (a Farm line making
   flowers can be Flowers).
4. **Enabled:** your switch for the line.

The line starts **Running** and settles one cycle later (10 minutes at the default settings). The line's page shows its
structure, output, rate, **State** (Running, Paused by staff, Blocked: output storage full, Blocked: inputs missing,
Error) with the reason, **Accrued (not yet emitted)**, **Last settled** and **Next settle**.

1. **Inputs:** what the line uses up while it runs. **Add input**, pick the Blueprint and the amount **Per hour**, then
   **Save inputs**. Inputs are taken from the structure's first Input storage (give the kind an Input default storage,
   or create one for the structure in the stock screens). At most 10.
2. **Settle now** settles the line up to this moment ("Settled: 10 of 10 accepted." or "Settled: nothing was due."). It
   is refused while Production enabled is off.
3. **Latest cycles** lists this line's last settles (§ 5.3).
4. Switching **Enabled** off pauses the line from now; switching it on resumes it from that moment. A paused or blocked
   line never makes up the time it was stopped.

A line a modifier is scoped to (scope Output) can't be deleted until you change or delete that modifier. Deleting a line
deletes its cycles.

## 4. Modifiers, climate zones and weather

The rate of a line is: **rate per hour, plus every addition, times every multiplication, times the workers present
share** (and 0 while the output is not unlocked yet). Additions always come before multiplications: 60 + 40 then × 0.5
is 50, never 70. The level is one of the multiplications ("Level 2", × 1.15).

### 4.1 Modifiers

**ProductionModifier** on the dashboard. The form:

1. **Modifier:** Name, **Effect** (Add: units per hour added; Multiply: a factor, not negative), **Value**, Enabled.
2. **Scope:** where it applies, with **Scope id** for every scope but Global:

   | Scope | Applies to | Scope id |
   |---|---|---|
   | Global | every line | — |
   | Kingdom | structures of the kingdom's towns | the kingdom |
   | Town | structures of the town, in a district or rural | the town |
   | Territory | only the town's rural structures | the town |
   | Structure | one structure | the structure |
   | Output | one line | the line |
   | MapArea | nothing yet (the painted map comes later) | — |

3. **Target:** Any, or only one **Target blueprint**, **Target category** or **Target kind**.
4. **Active window:** **Active from** and **Active until** (until is exclusive); empty = always.

The list shows the scope with its id ("Town #7"), the effect as "+2/h" or "× 0.5" and the window. A modifier applies
from each line's next settle; time already settled is not recalculated. Disable it (Enabled off) to stop it without
deleting it.

### 4.2 Climate zones

Every town is in one **climate zone**; a town not listed in any zone is in the default zone ("Default climate", seeded
with no weather, so it is always clear). **ClimateZone** on the dashboard; the form has Name, Description and **Default
zone** (making a zone the default takes it away from the previous one; the default can't be unticked or deleted, make
another zone the default first).

The zone's page has three parts:

1. **Odds per day:** **Add weather type**, pick it and its **Chance %**; "Together 40%; clear 60%." shows the rest,
   which is clear weather. The odds may add up to at most 100%. **Save odds**.
2. **Towns:** **Add town**, then **Save towns**. A town added here leaves its previous zone.
3. **Stored rolls:** the weather of the last 14 days (Day, From, Until, Weather, Roll).

The weather is rolled once per **weather day** (20 minutes by default, a Minecraft day) per zone and stored. The roll is
fixed by the zone and the day, so it can't be re-rolled. Changed odds take effect from the next day.

### 4.3 Weather types

**WeatherType** on the dashboard: Name (not "Clear") and Description. On its page, the **effects**: **Add effect**,
pick the **Category**, the **Effect** (Add per hour, or Multiply) and the **Value**; one effect per category. **Save
effects**. A type with no effects changes nothing. Seeded: Rain (Crops and Flowers × 1.1), Storm (Fish × 0.5, Crops
× 0.9), Drought (Crops × 0.6, Flowers × 0.7, Animals × 0.8). A type a zone has odds for can't be deleted.

A weather effect acts on the lines whose category matches (the line's own, or its kind's) in the zone's towns, on the
day it was rolled.

## 5. The Production panel ("why not producing")

Open a production structure's page; below its placement, territory and storages panels is **Production**. Opening it
settles the structure first (while Production enabled is on), so what you see is up to date.

### 5.1 The top

**Not producing** (a yellow box) lists what stops the whole structure: "Production is turned off for the whole server
(Production:Enabled).", "The structure's production is switched off.", "The structure has no Output storage.". Then
**Kind**, **Level** ("3 of 10"), **Climate zone** and **Weather today** ("-" when today has not been rolled yet).

### 5.2 Lines

Each line shows its state and effective rate ("Running, 69/h"), the reasons it produces less or nothing, and its rate
step by step: the rate per hour, each addition and multiplication with its name ("Plus 40", "Level 2", "Rain in
Northern coast (Crops)", "Half"), the unlock and workers steps, and the **Effective rate**.

| Reason | What to do |
|---|---|
| The line is paused. | Switch the line's Enabled on |
| The Output storage is full (100 of 100 units). / … is locked … / … holds as many different items as it may | Move stock out, raise the storage's Max units or Max distinct items, or unlock it ([stock admin guide](stock-admin-guide.md)) |
| Not enough Coal in the Input storage: needs 6, has 2. / The line needs inputs but the structure has no Input storage. | Put the inputs into the structure's Input storage, or create one |
| Unlocked at level 4 (the structure is level 2). | Upgrade the structure, or remove the unlock from the level |
| All workers are away (0 of 2 present). / Only 1 of 2 workers present: 50% output. / The structure has no workers. | Set Workers present (§ 5.3), or raise the structure's Workers |
| The base rate is 0. / The modifiers bring the rate to 0. | Raise the line's Rate per hour; check the modifiers in the rate steps |
| The structure has no Output storage. | Create an Output storage for the structure |

A structure without a kind still produces: its lines just get no Level step.

### 5.3 Workers and cycles

1. **Workers:** **Workers present (of 2)** and **Save workers**. Output and inputs scale with the share present: one
   of two away halves them, both away stops the line (without blocking it). The time before the change counts at the
   old share. Since phase P5 a worker carrying a transport order is away until the order ends ([transport admin guide](production-transport-admin-guide.md)); the
   button is for tests and fixes.
2. **Latest cycles:** the structure's last 20 settles: Settled, Output, Period, Rate, Accepted ("10 of 10"), State
   after, Shortfall. **Trace** opens one: workers present, accrued before and after, rate source, the rate steps, the
   inputs taken and a link to the stock transaction (the **Ledger**). A cycle is written for each settle that produced
   and each change of state. A "Catch-up capped at 24 h: … s not produced." shortfall means the line was not settled
   for longer than the catch-up cap (§ 7).

## 6. Upgrades

The **Upgrade** part of the Production panel shows the next level's cost before you pay: "Level 3 costs **1000 coins**
and 20 × Cobblestone." (or "and no resources").

1. **Paid by (coins):** the player whose coins pay; required when the level costs coins ("This level costs coins: pick
   the player who pays.").
2. **Resources from (empty: its Output storage):** the storage the resources come from.
3. **Upgrade to level 3**, then **Pay and upgrade** (or Cancel). "Upgraded to level 3." and a line "Upgraded from level 2
   to 3, 1000 coins paid, resources: transaction #…".

The structure is settled at the old level first. The resources go to `SYS_CONSUMPTION` (stock reason Upgrade) and the
coins are spent with the currency reason "Production structure upgrade" (`PRODUCTION_UPGRADE`), in one step: if
either can't be paid, nothing changes and the message says why ("The upgrade cost could not be paid: …", or the coin
refusal). Level 10 is the top ("Level 10 is the highest level."); a structure without a kind can't be upgraded ("Pick
a production kind first: the levels come from the kind.").

Setting the **Level** on the structure's form also changes the level, without paying. Don't lower a level by hand and
upgrade again to the same level: that second upgrade is not charged
([#841](https://github.com/PandiO/knk-workspace/issues/841)).

## 7. The engine settings card (`production.engine`)

**Game settings** → **Production engine** (below "Production and territory"):

| Setting | Default | Range | What it does |
|---|---|---|---|
| Base cycle (minutes) | 10 | 1–1440 | A line settles every base cycle ÷ its level's cycle speed |
| Catch-up cap (hours) | 24 | 1–720 | A settle after a long pause (an API outage) produces at most this much |
| Weather day (minutes) | 20 | 1–10 080 | The weather is rolled once per day of this length; 20 = a Minecraft day |

They are saved with the page's **Save** (the card says "(changed)" until then). A new base cycle applies from
each line's next settle. **Run production now** rolls today's weather and settles every line at once and reports
"3 lines settled, 30 of 30 units accepted, 1 weather rolls."; it is disabled while Production enabled is off ("Production
is off: nothing runs (turn it on and save first)."). The server also settles the due lines by itself every 60 seconds.

## 8. Storage weight of an item blueprint

How full a storage is counts **raw units × storage weight** ([stock admin guide](stock-admin-guide.md)); a full Output
storage blocks a line. The ItemBlueprint form (seed v2) has **Storage weight** on its **Item in game** step, after Max
stack size (default 1; for example 2 for a bulky block, 0.25 for a small gem). Changing it changes how full every
storage holding that blueprint is at once. A storage's page (Storage display seed v2) lists its stock by blueprint name.

## 9. A safe test

1. On a test server with Production enabled off, import the seeds (§ 1). Give a rural production structure the kind
   Quarry (§ 2.3) and cap its Output storage at 100 units (stock admin guide).
2. Add a line for Cobblestone at 60 per hour (§ 3). Its state is Running; nothing happens yet.
3. Tick Production enabled, save, and press **Run production now** (§ 7) twice ten minutes apart, or wait ten minutes.
   The Production panel shows about 10 Cobblestone per cycle, the rate steps "Level 1 × 1" and Effective rate 60/h, and
   a cycle with a Trace.
4. Create a Global modifier Multiply 2 (§ 4.1); after the next settle the rate steps show it and the rate is 120/h.
   Delete it.
5. Fill the Output storage (or lower its Max units): the line becomes "Blocked: output storage full" and the panel says
   why. Move the stock out and press **Settle now** on the line: Running again.
6. Untick Production enabled and save when you're done; the lines stop and resume later without catching up the time
   off.

The full checks are the [smoke test § 4](../production-storage-transport-smoke-test.md#4-phase-p3-production-engine-86-api-678-web-app-tier3)
(§ 4.1 with a REST client, § 4.2 in the web app).

## 10. Effects on existing data

1. The migration only adds tables and the seeded catalogue. Existing production structures keep their level, workers
   and storages; a structure's `ProductionKindId` must be 1–8 or empty before the migration (it becomes a real
   reference to the kind).
2. No structure produces until you give it a line and Production enabled is on. Existing stock is untouched.
3. Production writes stock through the ledger (reason Production, from `SYS_PRODUCTION`; inputs reason ProductionInput,
   to `SYS_CONSUMPTION`), so it shows up in the stock transactions and rolls up after 30 days like other stock moves.
4. Every settle writes a cycle record and they are kept for now ([#828](https://github.com/PandiO/knk-workspace/issues/828)).

## 11. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| Nothing produces anywhere | Production enabled is off | Tick it on the Production and territory card and save |
| "Production is turned off (Production:Enabled)." on Settle now or Run production now | The same | The same |
| The engine settings are back at 10 / 24 / 20 after a save | An older web app dropped them | Deploy the web app of `next` `4e4ca39a` or later and set them again |
| A line stays "Blocked: output storage full" | The Output storage is full, locked, or at its distinct cap | Make room (§ 5.2), then Settle now |
| A line stays "Blocked: inputs missing" | The first Input storage lacks an input | Put at least one of each input in it |
| A line is in Error | No Output storage, or a rate source other than Configured | Create the storage; set Rate source Configured |
| "The structure already has a line for this blueprint." | One line per blueprint per structure | Edit the existing line |
| "rateSource: a Derived line needs a Derived structure …" | Survey lines follow the structure's yield source | Use Configured for a hand-made line ([yield areas admin guide](production-yield-areas-admin-guide.md)) |
| "The weather odds add up to more than 100%." | Too much weather | Lower the chances; the rest is clear |
| "This is the default zone; make another zone the default instead." | You unticked Default zone | Tick Default zone on another zone |
| "payerUserId is required: level N costs C coins." | No payer picked | Pick Paid by (coins) |
| "The upgrade cost could not be paid: …" | The storage lacks the resources | Move them in, or pick another storage under Resources from |
| Weather today shows "-" | Today was not rolled yet (Production enabled off, or the sweep has not run) | Wait a minute or Run production now |
| Save inputs, odds, towns, effects or items is refused with no write access | No `knk.admin.content` | Grant it (§ 1; [#842](https://github.com/PandiO/knk-workspace/issues/842)) |
| The kinds or lines list is missing from the dashboard | No `knk.admin.world`, or the display seeds are not imported | Grant the node; import the seeds (§ 1) |

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#839).
2. 2026-11-20: pointers to the [yield areas admin guide](production-yield-areas-admin-guide.md) where P3 said "P4" (docs PandiO/knk-workspace#882).
