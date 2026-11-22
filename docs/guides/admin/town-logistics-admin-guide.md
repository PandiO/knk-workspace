# Town Logistics — Admin Guide

**Status:** Current · **Last updated:** 2026-11-21 (§ 1, § 4, § 5.3, § 8: shops collect with their own worker and restock at their level's min/max, P10 #248 in `next` `289f4d4b`, docs PandiO/knk-workspace#939); 2026-11-21 (first version, production P9 #127/#686, docs PandiO/knk-workspace#929)
**Checked against:** knk-web-api `next` `37be22e5`, knk-web-app `next` `c12e0e7e` (not released; the manual steps of the
[smoke test § 10](../production-storage-transport-smoke-test.md#10-phase-p9-town-logistics-127-api-686-web-app-tier3)
have not been run live yet)
**Related:** [town logistics architecture](../../architecture/town-logistics.md) (how the planner decides, matching,
recovery), [API contract](../../specs/api/API_CONTRACT_TOWN_LOGISTICS.md), [production transport admin
guide](production-transport-admin-guide.md) (orders, workers, lanes, road connections), [warehouses and production
structures admin guide](production-world-admin-guide.md), [production engine admin guide](production-engine-admin-guide.md)
(lines and inputs), [stock admin guide](stock-admin-guide.md) (storages, Adjust, the ledger),
[Game Settings](../game-settings.md), [TOWN_LOGISTICS](../../specs/production-storage-transport/TOWN_LOGISTICS.md) (the
design)

A town's **warehouses** supply its **consumers**: structures with an Input or Merchandise storage, such as a bakery that
needs flour. Every 10 minutes the **planner** looks at each consumer's stock, and where it has dropped to its **min**
it **reserves** goods at a warehouse up to its **max**. The consumer's own worker then walks over and **collects** them.
You steer it with the town's **logistics policy**: **reserves** the planner may not hand out ("keep 14 days of bread"),
**priority classes** for who comes first when stock is short, and **service areas** for which warehouse serves which part
of the town. This guide covers the set-up, the screens, the settings, a safe test and what to do when the bakery doesn't
get its flour.

Players see no screen or command for this in V1. What they notice: consumers keep running instead of starving for
inputs, and a consumer's worker is away (its output drops) while it fetches a collection.

## 1. What you need

1. **The API's switch.** The game setting **Production enabled** (`Production:Enabled`; Admin → Settings, the
   **Production and territory** card, see [Game Settings](../game-settings.md#production-and-territory)). With it off
   you can still write policies, settings and run a **dry run**, but the planner never runs: no reservations, no
   collections. The game server's `production.enabled` is not needed for the planner itself; the transport trips and
   road connections it relies on are ([production transport admin guide](production-transport-admin-guide.md)).
2. **The migration** `AddTownLogistics` on the API's database (six new tables, nothing else changed;
   [production installation § 5.3](../production-installation.md) item 16).
3. **The seeds**, imported with "make default" (Admin → Forms and Displays): form and display `LogisticsPolicy`,
   `ConsumerReplenishment`, `LogisticsRule`, `LogisticsReservation`, `LogisticsPlannerRun`.
4. **Permissions** (staff web app):

   | What | Node |
   |---|---|
   | See the panels, the Town logistics page and the dashboards | `knk.admin.world` (the panels are hidden without it) |
   | Write policies and settings, apply templates, release reservations, dry run, run now | `knk.admin.world` |
   | Delete a policy (every version) or a consumer setting | also `knk.admin.delete` |

5. **The world**, from the earlier phases:
   1. At least one **warehouse** in the town (in a district, or rural with the town set). A town without one is not
      planned.
   2. **Consumers**: production structures with workers and an **Input** storage, and shops (production structures
      underneath) with their **Merchandise** storage ([shops admin guide § 3.5](shops-admin-guide.md#35-restocking)).
      Only production structures and shops have workers in V1; any other consumer shows "no worker" and gets nothing
      (§ 8).
   3. **Lanes** or measured road connections between consumers and warehouses, so distances are known; a rural consumer
      needs road connection **Connected**.
   4. Stock in the warehouses.

## 2. Where things are

1. **Admin → Town logistics** (World group, `/admin/logistics`): pick a town and **Open the town**; the list of
   **Policies and templates** (filter **For**: towns, warehouses, templates; **Versions**: current only, current and
   superseded, superseded only) with **New policy or template**; links to the dashboards **Consumer settings**,
   **Reservations**, **Planner runs** and **All rules**.
2. **A town's page**, panel **Town logistics**: the policy in force, the warehouses, last and next run, **Dry run**,
   **Run the planner now**, **Apply a template**, **Supply**, **Open reservations**, **Service areas**, **Recent planner
   runs** (§ 5).
3. **A policy's page**: the rule editor, **Save as a new version**, **Versions**, and for a template **Apply to a town**
   (§ 3).
4. **A production structure's page**, panel **Supply (as a consumer)**: who collects, which warehouse serves it, its
   **Demand** and **Replenishment settings**, its open reservations (§ 4).
5. **A warehouse's page**, panel **Logistics**: what it serves, its warehouse policy, the reservations held there.
6. **A planner run's page**: the counts and the **Plan explanation**. **A reservation's page**: what it holds, its
   collection order, **Release**.
7. **Admin → Settings**, card **Town logistics** (§ 6).

## 3. Policies, rules and templates

### 3.1 Kinds of policy

| Policy | For | May hold |
|---|---|---|
| **Town policy** | One town (one current version) | Every rule type |
| **Warehouse policy** | One warehouse (one current version), on top of the town's | Local reserves and service areas of that warehouse only |
| **Template** | Any town; labels specialization (Crops, Wood, Stone, Ore, Fish, Flowers, Animals or general) and town size (Village, Town, City or any) | Reserves, priority classes and replenishment rules, without warehouses, districts or structures |

A town without its own policy uses the **default template** (tick **Default template** on one template; only one can be
it). With neither, the planner works by distance only: no reserves, everyone Normal priority, and its plan says so.

### 3.2 Making a policy

1. Admin → Town logistics → **New policy or template**: **Name**, **Scope** (Town, Warehouse or Template), the **Town**
   or **Warehouse**, for a template **Specialization**, **Town size** and **Default template**, and a **Reason**. Save:
   this is version 1. A town or warehouse that already has a policy is refused: open and edit that one.
2. On the policy's page, **Add the rule** for each rule (§ 3.3), give a **Reason for this version** ("Shown in the
   history, e.g. "Bread reserve 14 days"") and **Save as a new version**. The page checks the rules first and lists
   the problems; the API checks them again.
3. For a warehouse, its page's **Logistics** panel has **Make a warehouse policy**.

### 3.3 The rule types

| Rule | Fields in the editor | Effect | Example |
|---|---|---|---|
| **Reserve** | **Where** (Town-wide or One warehouse (local reserve)), **Items**, **Keep** (**Units** or **Days of cover**) | That much stock is never reserved for consumers. Days of cover become units from the average daily outflow over the consumption window. Several matching reserves: the largest counts | "Keep 14 days of bread town-wide"; "Docks keeps 500 planks" |
| **Priority class** | **Items**, **Consumers**, the class (Critical, High, Normal, Low) | When stock is short, Critical lines are served first, then High, Normal, Low; within a class the nearer consumer first | "Garrison food is Critical" |
| **Service area** | **Area** (a District, The rural territory, or one Structure), the **Warehouse** | That warehouse serves the area first; producers there without a preferred warehouse also deliver to it | "Rural north → North Granary" |
| **Replenishment** | **Items**, **Consumers**, **Min** and **Max** | A default min and max for those consumers, where they have no setting of their own (§ 4) | "Every bakery: flour min 50, max 200" |

**Items** is Every item, One blueprint, a Category (with its sub-categories) or a Tag. **Consumers** is Every
consumer, One structure or a production kind (every bakery). When several priority or replenishment rules match, the
most specific wins: a rule for the structure beats one for its kind beats one for everyone, then blueprint beats
category beats tag beats every item.

Every rule can have **Active from** and **Active until** (for example a festival week) and a reason, "Shown in the
planner's explanation". Ceilings, quotas, rebalancing between warehouses, export and import rules, emergency modes and
taxes are not available yet ([#324](https://github.com/PandiO/knk-workspace/issues/324)).

### 3.4 Versions

Every save is a new version; the old one stays in **Versions**, read only, with who saved it, when and why ("since
Tuesday the bread reserve is 14 days"). Only the current version can be edited: if someone saved meanwhile you get
"reload and try again". Editing a policy with the generic form's Edit also makes a new version and keeps the rules.
**Delete** (with `knk.admin.delete`) removes the policy with every version; the town then falls back to the default
template.

### 3.5 Templates

Write one template per kind of town, for example "Farming village" (Crops, Village) with a food reserve and the
garrison Critical. To use one:

1. On the town's **Town logistics** panel, **Apply a template**, **Pick a template** (each shows its specialization,
   size, "default" and rule count), an optional reason, **Apply to this town**; or on the template's page **Apply to a
   town**.
2. The template's rules **replace** the town policy's rules as a new version (or become its version 1). The old version
   stays in the history.
3. Towns have no size or specialization fields yet, so no template is picked for you
   ([#928](https://github.com/PandiO/knk-workspace/issues/928)). Service areas are not in templates: add them to the town
   policy after applying.

## 4. Consumer settings (min and max)

On a production structure's page, panel **Supply (as a consumer)**:

1. **Collected by**: its workers (present of total) and how much each carries. **Served by**: the warehouse of its
   service area, or the nearest by road. A structure with no Input or Merchandise storage says it is not a consumer:
   add an Input storage first.
2. **Demand**: per storage and item the **Stock**, **On the way**, **Min**, **Max**, **Priority** and **Min and max
   from**. The first source wins: its own **setting**, else a **Replenishment rule** of the policy, else for a shop's
   Merchandise storage its level's **Default min** and **Default max** for each stocked catalogue item (**Shop level**,
   [shops admin guide § 3.5](shops-admin-guide.md#35-restocking)), else the production line inputs: 4 hours of input
   for the min and 12 hours for the max (the defaults of § 6). Any other Merchandise storage has no line inputs, so it
   needs a setting or a rule.
3. **Replenishment settings**: **New setting** with **Storage**, **Item**, **Min (reorder point)**, **Max (target
   level)**, **Priority class** (empty = from the policy, else Normal) and a **Note**. One setting per storage and item;
   min at most max. **Edit** or **Delete** (with `knk.admin.delete`). All settings are on the **Consumer settings**
   dashboard too.

Pick a max the storage can hold and one worker can carry in a trip or two: the planner never reserves more than the
storage has room for or the worker can carry, and tries again next run.

## 5. The town panel, the dry run and "why didn't the bakery get flour"

### 5.1 What the panel shows

1. **Low supply**: items with nothing available or under 3 days of cover.
2. **Policy in force**: the town's own, the default template, or none ("no reserves or priorities apply").
3. **Warehouses** ("None: the planner does not run for this town" without one), **Last run** with its summary, **Next
   run** ("Production is off: no scheduled runs (a dry run still works)" while the switch is off).
4. **Supply** per item across the warehouses: **Stock**, **Reserved**, **Held by reserves**, **Available**, **In /
   day**, **Out / day**, **Days of cover**, with **By warehouse**.
5. **Open reservations** with **Release**, **Service areas** (each district, the rural territory and each structure
   with the warehouse that serves it and why), **Recent planner runs**.

### 5.2 Dry run and run now

**Dry run** shows what a run would do now and writes nothing ("Dry run: nothing was written."). It works while
production is off. **Run the planner now** does a real run at once (disabled while production is off). Both show the
plan:

1. **Consumer lines**: one per consumer storage and item that is short or blocked, with its outcome and a one-line
   explanation. Tick **Only the lines that didn't get everything** to see the problems.
2. **Collection orders**: what each consumer's worker will fetch from which warehouse, with warnings such as no worker
   free right now.
3. **Released reservations** and the plan's warnings.

A planner run's page shows the same explanation for any earlier run (runs are kept 14 days).

### 5.3 Reading the outcome

| Outcome | Means | What to do |
|---|---|---|
| Reserved | Reserved up to the max; the worker collects it | Nothing |
| Partly reserved | Less than needed: scarce stock, a reserve, the storage's room or the worker's capacity; the explanation says which | More stock, a lower reserve, a bigger storage, or wait for the next run |
| Not needed | Stock plus on the way is above the min (not stored in a run) | Nothing |
| Already reserved | A reservation is waiting for the worker | Wait, or release it (§ 5.4) |
| No stock | No warehouse of the town holds the item | Produce or bring in the item |
| Held by a reserve | There is stock, but reserves (or higher classes this run) keep it | Lower the reserve, or raise the consumer's priority class |
| No warehouse | The town has no warehouse | Build one |
| No worker | Not a production structure or shop, or no workers: consumers collect with their own worker | Give it workers (§ 8) |
| Not connected | A rural consumer whose road connection is not Connected | Build the road; check the road connection ([transport guide](production-transport-admin-guide.md)) |
| No room | Its storage is full | Raise the storage's capacity or lower the max |
| Carrier full | Its workers already have a collection this run, or the trip is full | Next run; more workers or capacity |

Example explanation: "Coal at Bakery is 0 (0 in stock + 0 on the way); min 20, max 60 (replenishment setting #3): at or
below the reorder point, short 60; Normal priority (the default). Reserved 60 of 60 at North, its service area (nearest
by road); no town reserve; collected by its own worker."

### 5.4 Reservations

A reservation holds the goods at the warehouse for 30 minutes. When the worker loads them it becomes **Collected**; if
not collected in time, or the order ends without loading, the next run **releases** it and the stock is free again. To
free it yourself: **Release** (in the town panel, the warehouse panel or the reservation's page, with an optional
reason). Its collection order is cancelled. Once the worker has loaded, Release is refused: the next run marks it
collected.

## 6. Settings

Admin → Settings, card **Town logistics** (saved with the page's **Save (n)**; problems are listed under the card):

| Field | Default | Range | Meaning |
|---|---|---|---|
| **Planner interval (minutes)** | 10 | 1-1440 | How often each town is planned |
| **Reservation expiry (minutes)** | 30 | 1-10080 | How long a reservation waits for the worker |
| **Consumption window (days)** | 7 | 1-90 | Days of outflow averaged for days of cover and day-based reserves |
| **Default min (hours of input)** | 4 | 0-720, at most the max | Min of a line with no setting or rule |
| **Default max (hours of input)** | 12 | above 0, at most 720 | Max of such a line |
| **Keep planner runs (days)** | 14 | 1-365 | Older runs and their explanations are deleted |

There is no `api.env` key and nothing in the plugin's `config.yml` for the planner.

## 7. A safe test

Use a test town, or the set-up of [smoke test § 10.0](../production-storage-transport-smoke-test.md#100-preconditions)
(warehouses North and South, consumers Bakery and Garrison with two workers and an Input storage each, lanes, Coal as
"flour").

1. With **Production enabled** off, open the town's panel: "Production is off", **Run the planner now** disabled.
   **Dry run**: lines with their outcomes, nothing written.
2. Give Bakery a setting: Coal, min 20, max 60. Put 100 Coal into North (Stock → Adjust). **Dry run**: Bakery
   "Reserved 60 of 60 at North" (a worker carries 64 by default, so keep the max below that for one trip).
3. Write a town policy with a town-wide Reserve of 70 units of Coal. **Dry run**: Bakery is Partly reserved, 30, and
   the explanation names the reserve rule.
4. Add a Priority class rule Critical for Garrison and give Garrison a setting for Coal too. **Dry run**: Garrison is
   served first.
5. Switch **Production enabled** on, **Run the planner now**: a reservation and a collection order (origin
   Distribution). Open the order: Bakery's worker carries it. Release the reservation: the order is cancelled.
6. Clean up: delete the settings and the policy, empty North with Adjust.

Each step is in full, with its automated test, in [smoke test § 10.1](../production-storage-transport-smoke-test.md#101-steps-api)
(API) and [§ 10.2](../production-storage-transport-smoke-test.md#102-steps-web-app-686) (web app).

## 8. Effects on existing data and limits

1. The migration adds tables only; nothing existing changes. Until you write a policy or setting, consumers with Input
   storages and production lines already get min and max from their line inputs, so **switching production on starts
   collections** for every such consumer in a town with a warehouse and stock. Check a dry run per town first.
2. Producers without a preferred warehouse now deliver to their service area's warehouse when it has room (before: the
   nearest). Without service-area rules nothing changes.
3. Collections take the consumer's workers away, so its own production drops during the trip.
4. Only production structures and shops collect (shops since P10,
   [#248](https://github.com/PandiO/knk-workspace/issues/248)); other consumers show **No worker**. Note: the consumer panel's "No workers: the planner
   can reserve but nobody collects" is wrong; the planner makes no reservation for such a consumer
   ([#930](https://github.com/PandiO/knk-workspace/issues/930)).
5. Warehouses never deliver on their own and goods are not moved between warehouses (rebalancing is Later, #324).
6. No in-game screen or command; town councils can't change policies yet.

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| The town panel or the menu is missing | No `knk.admin.world` | Grant it |
| "Last run: Never" with production on | The town has no warehouse, or the API's planner is failing | Add a warehouse; run now to see the error; check the API log for "Logistics planner failed for town" |
| Run now answers "Production is turned off" | `Production:Enabled` is off | Switch it on, or use the dry run |
| A consumer never appears in the plan | No Input or Merchandise storage, no setting, rule or line inputs, or it is a warehouse | Add the storage and a setting |
| Saving a policy says "not the current version" or "reload and try again" | Someone saved meanwhile, or you opened an old version | Open the current version from **Versions** and save again |
| Saving a policy lists "Rule n: …" problems | A rule misses a field, names a place outside the town, or a type the scope doesn't allow | Fix the rule as the message says |
| "Town … already has a logistics policy" | One current policy per town | Edit it; or delete it first |
| A template's labels disappeared after an edit outside the web app | A `PUT` without the labels clears them ([#928](https://github.com/PandiO/knk-workspace/issues/928)) | Set them again in the web app |
| Stock is "Held by a reserve" though the warehouse is full | Reserves in days of cover grow with outflow | Lower the days, or use units |
| Release is refused: "already loaded" | The worker loaded the goods | Nothing: the next run marks it collected |
