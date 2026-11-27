# Production Yield Areas and Surveys — Admin Guide

**Status:** Current · **Last updated:** 2026-11-20 (first version, production P4 #138/#679/#680, docs PandiO/knk-workspace#882)
**Checked against:** knk-web-api `next` `e26c7d88`, knk-plugin `next` `d36001b2`, knk-web-app `next` `eaf0467d` (not
released; surveys run only with Production enabled on in the API and `production.enabled: true` on the game server; the
manual steps of the
[smoke test § 5](../production-storage-transport-smoke-test.md#5-phase-p4-yield-areas-and-surveys-138-api-679-plugin-680-web-app-tier3)
have not been run live yet)
**Related:** [PRODUCTION_KINDS § 2–4](../../specs/production-storage-transport/PRODUCTION_KINDS.md) (the rules),
[yield areas architecture](../../architecture/production-yield-areas.md) (formulas, survey pipeline, tests),
[API contract](../../specs/api/API_CONTRACT_PRODUCTION_YIELD.md), [production engine admin guide](production-engine-admin-guide.md)
(kinds, levels, lines, the Production panel), [warehouses and production structures admin guide](production-world-admin-guide.md)
(creating the structures), [plugin configuration § 4.31](plugin-configuration.md#431-production) (`production.surveys.*`),
[in-game commands](../users/commands.md#server-tools-knk)

Production phase P4 lets a production structure produce what its land holds. You give a structure one or more
**areas**: a WorldGuard region, a box, a polygon or a circle around it. The game server **surveys** each area once a day
(and when you ask): it counts the trees, rock and ores, crops, flowers, water or animals inside and sends the counts to
the API. The kind's **yield table** says what each counted thing produces per hour. A structure's **yield source**
decides what its lines use:

1. **Hybrid** (the default for new structures): the survey, with your **pins**, **exclusions** and **scales** on top.
2. **Derived**: the survey only.
3. **Configured**: the rates you type on its lines, as before P4. A Configured structure is never surveyed.

The engine of P3 still does the producing: settling, storages, weather, modifiers and upgrades work as in the
[production engine admin guide](production-engine-admin-guide.md). Players see nothing of this yet.

## 1. What you need

1. **knk-web-api** with migration `AddProductionYieldAreas` applied (after `AddProductionEngine`). It gives every kind a
   survey profile and a primary multiplier of 1.5. Production structures that existed before stay **Configured**, so
   they keep producing exactly as before until you switch them.
2. **knk-web-app** of the same `next` (or later), for the Yield panels.
3. **knk-plugin** of the same `next` (or later) on the game server, with `production.enabled: true` and the
   `production.surveys` keys merged into `config.yml` (§ 7). Without the plugin nothing is surveyed and Derived and
   Hybrid structures produce nothing (unless pinned).
4. **Seeds.** As content staff, import the form and display seeds `ProductionArea` and `ProductionYieldOverride`, the
   display seed `AreaSurvey`, and the new versions `ProductionKind - Default (seed v2)` (form and display),
   `ProductionStructure - Default (seed v3)` (form and display) and `Structure - Default (seed v3)` (form), each with
   "make default".
5. **Production enabled** ticked on the game settings page (card "Production and territory"). While it is off you can
   still create areas and overrides, but nothing is surveyed and survey reports are refused.
6. **Nodes:**

   | To | Node(s) |
   |---|---|
   | See areas, surveys, overrides and a structure's yield | `knk.admin.world` |
   | Create and edit areas, overrides, the yield table and primary outputs | `knk.admin.world` and `knk.admin.content` |
   | Delete areas and overrides | `knk.admin.world` and `knk.admin.delete` |
   | Survey now (web app), Materialize | `knk.admin.world` |
   | `/knk production survey\|area show` in game | `knk.admin.world.production` (in `knk.admin.world.*` and `knk.admin.*`) |

## 2. The kind's yield table

Open the **Dashboard**, type **ProductionKind**, open a kind.

### 2.1 Survey profile and primary multiplier (the kind's form, "Yield" step)

1. **Survey profile** is the JSON the game server reads to know what to count. The seeded profiles:

   | Kind | Counts |
   |---|---|
   | Farm | `CROP` |
   | Logger | `TREE`, `SAPLING` |
   | Quarry, Mine | `BLOCK` (rock and every ore) |
   | Fishery | `WATER` |
   | Flower farm, Florist | `FLOWER` |
   | Animal farm | `ENTITY` (farm animals) |

   You can narrow it, for example a quarry that counts only some blocks:
   `{"unitTypes":["BLOCK"],"materials":["STONE","ANDESITE","COAL_ORE"]}`, or an animal farm for sheep and cows only:
   `{"unitTypes":["ENTITY"],"entityTypes":["SHEEP","COW"]}`. A logger can set tree sizes:
   `"tree":{"smallMaxLogs":6,"mediumMaxLogs":20,"maxLogs":400,"leafReach":1}`. Every change raises the profile version,
   which is stored with each survey. A profile that counts nothing makes every survey of the kind fail (§ 9).
2. **Primary multiplier** (default 1.5): the factor the kind's primary outputs get on Derived and Hybrid lines.

### 2.2 Yield table and primary outputs (the kind's page)

1. Under the kind's details, the **yield table** lists rows of **Unit key**, **Output**, **Rate per unit/h**, **Chance**
   and **From level**. Add a row, fill it, save the list. A seeded kind starts with an empty table: **Derived and Hybrid
   structures of that kind produce nothing until you add rows** (default tables are
   [#836](https://github.com/PandiO/knk-workspace/issues/836)).
2. **Unit key** is what the survey counts (§ 5.2 lists them): an exact key such as `TREE:OAK:LARGE` or `BLOCK:COAL_ORE`,
   a prefix ending in `:*` such as `TREE:OAK:*` (every oak size), or `*` for everything. When several rows for the same
   output match a unit, the most exact one counts: `TREE:OAK:LARGE` beats `TREE:OAK:*`, which beats `*`.
3. **Rate per unit/h** is what one counted unit makes per hour at level 1 before modifiers. Ten large oaks at 2 per unit
   make 20 Oak logs per hour.
4. **Chance** (0–1, default 1) turns the row into a byproduct produced at that share of the rate: 0.2 makes a fifth.
   It is a fixed share, not a dice roll.
5. **From level** (1–10): the row counts only from that structure level on, so upgrades can unlock outputs.
6. **Primary outputs**: the outputs that get the primary multiplier (a mine's ore, not its stone). Add and save.
7. Saving the yield table settles every Derived and Hybrid structure of the kind first and then makes their lines
   again (§ 4.3). Units no row matches show as "No row of the kind's yield table matches these units" on the
   structure's page.

## 3. Areas

### 3.1 Giving a structure its yield source

On the production structure's form, **Yield source** (after Production kind) is Hybrid, Derived or Configured; only the
ones the kind allows are accepted ("yieldSource: Logger doesn't allow Configured."). Switching an existing Configured
structure to Hybrid or Derived makes a line for each output its surveys yield; switching back to Configured turns its
survey lines into Configured lines with the rate they had configured (often 0: set it).

### 3.2 Creating an area

From the structure's page, **Add area** (or Dashboard → **ProductionArea** → create). The structure needs a production
kind first: the kind decides the **area model** and whether areas are **exclusive**.

1. **Area** step: the structure, a **Name** unique on that structure ("North wood"), the **Shape**, the **World** (empty
   = the structure's world), **Exclusive** (empty = the kind's setting) and **Enabled**.
2. **Shape** step, the fields of the chosen shape:

   | Shape | Fill in |
   |---|---|
   | Region | the WorldGuard region id **and** its corners (Min/Max X, Y, Z): the bounds are not read from the region yet ([#877](https://github.com/PandiO/knk-workspace/issues/877)) |
   | Cuboid | two opposite corners, in any order (`//pos1` and `//pos2` in WorldEdit show them) |
   | Polygon | its points and Min/Max Y through the API (`points`: `[{"x":..,"z":..}]`, 3–200); the form has no point list |
   | Radius | the radius (1–1024); the centre is the structure's Location unless you fill Centre X/Y/Z; Min/Max Y default to the world's bottom and top |

3. Save. The API works out the bounding box and the **size**, and refuses:
   1. an area over the level's **Max area size** ("The area is 40 (radius); level 1 of Logger allows at most 32."). The
      size is counted as blocks of ground for fields and pastures, as volume for quarries and mines, and as the radius
      for loggers and hunting grounds. Upgrade the structure, or raise the level's cap on the kind
      (production engine admin guide § 2.2);
   2. an **exclusive** area whose box overlaps another exclusive area of the same model ("The area overlaps the
      exclusive area 'Pit' of South quarry: exclusive ExclusiveVolume areas may not overlap."). The check uses the boxes
      around the shapes, so two circles whose boxes touch are refused even if the circles don't;
   3. a second area with the same name on the structure.
4. A new area of a Hybrid or Derived structure is surveyed at once (at the game server's next queue read, within
   `poll-minutes`).

The radius task `CaptureRadius` (stand in the middle and set the radius in chat) is in the plugin but cannot be started
from the area form yet ([#877](https://github.com/PandiO/knk-workspace/issues/877)); type the centre and radius.

### 3.3 Shared and exclusive areas

1. **Exclusive** areas (fields, quarries, pastures by default) may not overlap each other. Each structure keeps its own
   land.
2. **Shared** areas (loggers' and fisheries' radii by default) may overlap. A tree inside two loggers' areas is split:
   each gets half ("Shared by 2" on the survey). Three loggers share by three, and so on.
3. Shared areas of different kinds split too: a logger and a florist whose circles overlap split each other's units
   ([#875](https://github.com/PandiO/knk-workspace/issues/875)). Keep shared areas of different kinds apart for now.

### 3.4 The area's page

Open an area (from its structure, or Dashboard → ProductionArea):

1. **Size** against the level's cap, model and shape, exclusive or shared, last survey, enabled.
2. **Survey this area now** (§ 4.1).
3. **From above**: the area's outline with the areas that overlap it (dashed), and the same as a table.
4. **Latest survey**: each unit with its count, its share of the survey, "Own" or "Shared by N", and extra data (water
   depth and open sky).
5. **Trend** over the last 30 surveys: first, latest, change and a small line per unit, to see a forest being cut down.
6. **History**: every survey, newest first; open one to see its units.

Editing the shape or world asks for a new survey. **Enabled** off: the area is never surveyed and its units no longer
count. Deleting an area deletes its surveys.

## 4. Surveys and yield

### 4.1 When surveys run

1. When an area is created or its shape changes.
2. Once a day per area. With `scheduled-loads-chunks: false` (the default) the daily survey waits until the area's
   chunks are loaded by players; it stays due and is tried at every queue read.
3. On request: **Survey now** on the structure's page (every enabled area), **Survey this area now** on an area's page,
   or `/knk production survey <structure> [area]` in game (§ 6). Requested surveys load the chunks they need.
4. After a **notable change**: 64 block breaks and places inside one area (at most every 30 minutes per area).

Configured structures are never surveyed and have no Survey now ("A Configured structure is never surveyed, so there is
no Survey now"). Nothing is surveyed while Production enabled is off or `production.enabled` is false on the game server.

### 4.2 The structure's yield ("Outputs and why each rate is what it is")

On the production structure's page:

1. The yield source in words, the areas with size, kind of area and last survey ("(survey requested)", "(disabled)").
2. Each **output** with its rate from the survey, the override, the **base rate** the line uses, and "primary". Open an
   output to see where it comes from: per area and unit, the count, the share (½ when shared by two), the yield row that
   matched, the rate per unit, the chance and the result.
3. "No row of the kind's yield table matches these units: …": add rows (§ 2.2) or ignore them.
4. The base rate then goes through the production engine's steps (level, weather, modifiers, workers). A primary output
   shows an extra step "Primary output of <kind>" in the cycle trace; with the kind's **Cycle variation** on, every line
   shows "Variation (±10%)", the same for a line within one hour.

### 4.3 Lines from outputs

After every survey, override change, yield table save, yield source change, level-up or kind change, the API makes a
line for each output with a base rate above 0. It never deletes lines: an output the land no longer yields keeps its
line at a base rate of 0. A **Configured line** you made yourself on a Hybrid or Derived structure keeps your rate and
wins over the survey. To make the lines by hand: `POST api/ProductionStructures/<id>/materialize`.

## 5. Hybrid overrides

Only for Hybrid structures (a Derived structure ignores them, and its page says so). On the structure's page, each
output has an **Override**:

| Override | Effect | Value |
|---|---|---|
| None (the survey's rate) | the survey decides | — |
| Pin | always produce at this base rate per hour, whatever the survey says | above 0 |
| Exclude | never produce this output | — |
| Scale | the survey's rate × the factor | 0–100 |

**Pin an output the survey doesn't yield** adds an output the land doesn't have (a quest reward, an event). One override
per output; saving it settles the structure first, so the change counts from now. Overrides are also on the Dashboard
(**ProductionYieldOverride**), with a **Note** field for other staff.

## 6. In game: `/knk production`

Node `knk.admin.world.production`; needs `production.enabled: true` ("Production is off on this server
(production.enabled: false)." otherwise).

1. `/knk production survey <structure> [area]`: survey now. `<structure>` is the structure's id (the web app shows it),
   or its one-word name if it has areas. Answers "Asking the API to survey structure #12…", "Queued 2 …", then one line
   per area as it finishes. A Configured structure: "Survey not requested: … never surveyed (G5) …".
2. `/knk production survey status`: the queue, the survey running now, how many were reported since start, the last
   queue read, the last results (reported with rows and units, skipped or failed with the reason) and the
   notable-change counters.
3. `/knk production area show <structure> [area] [seconds]`: draws the structure's areas with particles for you (default
   30 seconds) and names each with its shape.

## 7. Game server settings (`production.surveys`)

Merge into the `production` block of `config.yml` (the plugin never adds new keys to an existing file) and restart;
details in [plugin configuration § 4.31](plugin-configuration.md#431-production):

```yaml
production:
  enabled: true
  surveys:
    poll-minutes: 5
    batch: 20
    chunks-per-tick: 2
    max-area-blocks: 16000000
    max-area-chunks: 256
    scheduled-loads-chunks: false
    notable-change-blocks: 64
    notable-cooldown-minutes: 30
    areas-refresh-minutes: 10
```

Surveys read chunk snapshots on the main thread, `chunks-per-tick` per tick, and count off it. Lower `chunks-per-tick`
if `production.survey.capture` shows in tick times (performance metrics guide); raise `max-area-chunks` only for big
areas you mean to survey (a radius of 64 spans about 81 chunks).

## 8. A safe test

1. On a test server with WorldGuard, import the seeds (§ 1), tick Production enabled and set `production.enabled: true`.
2. Build a small oak wood near spawn. On the Logger kind, add the yield row `TREE:OAK:*` → Oak log, rate 1, and save.
3. Create a production structure **Test logger** (kind Logger, yield source Hybrid) with its Output storage, located in
   the wood, and a Radius area of 20 around it.
4. Wait for the next queue read (or `/knk production survey <id>`). The area's page shows a survey with
   `TREE:OAK:SMALL|MEDIUM|LARGE` counts; the structure's page shows Oak log with a base rate equal to the number of oaks,
   and the structure has an Oak log line.
5. Pin Apple at 5 per hour: an Apple line appears. Exclude Oak log: its base rate is 0. Set both back to None.
6. Fell a few trees and survey again: the trend shows fewer oaks and the rate drops.
7. Turn `production.enabled` off (or untick Production enabled) when done.

The full checks are the [smoke test § 5](../production-storage-transport-smoke-test.md#5-phase-p4-yield-areas-and-surveys-138-api-679-plugin-680-web-app-tier3)
(§ 5.1 API, § 5.2 game server, § 5.3 web app).

## 9. Effects on existing data

1. Existing production structures become **Configured** and keep their lines, rates and storages; nothing changes until
   you switch one.
2. Kinds get a survey profile and a primary multiplier of 1.5 and an empty yield table. The primary multiplier only
   acts on Derived and Hybrid lines, so existing Configured lines are unchanged; Cycle variation, if you ticked it on a
   kind, now varies every line of that kind by up to ±10% per hour.
3. Surveys are kept forever for now (one row per survey and one per unit group); plan for the history to grow with the
   number of areas.
4. An item blueprint used in a yield row, primary output or override can't be deleted while it is used.

## 10. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| A Hybrid or Derived structure produces nothing | No area, no survey yet, or no yield table row matches | Look at the structure's yield: add an area, Survey now, add rows (§ 2.2) |
| "No area has been surveyed yet." for long | The game server is not surveying | `production.enabled: true`, Production enabled ticked, then `/knk production survey status` |
| `survey status` says "skipped, N of N chunks not loaded (a Scheduled survey …)" | The daily survey waits for loaded chunks | Normal; Survey now loads them, or set `scheduled-loads-chunks: true` |
| "skipped, the area spans N chunks (production.surveys.max-area-chunks 256)" or "holds N blocks" | The area is too big for the server's limits | Make the area smaller, or raise the limit |
| "failed, the kind's survey profile counts nothing" | The kind's profile is empty or broken | Fix the kind's Survey profile (§ 2.1) |
| "Survey not requested: … Configured …" / no Survey now button | The structure is Configured | Switch it to Hybrid or Derived (§ 3.1) |
| "The structure has no enabled area to survey." | No area, or all disabled | Add or enable an area |
| "Give the structure a production kind first …" | The structure has no kind | Set its Production kind |
| "The area is N (…); level L of … allows at most M." | Over the level's cap | Make it smaller, upgrade, or raise the cap |
| "The area overlaps the exclusive area …" | Two exclusive boxes of the same model overlap | Move the area, or untick Exclusive on one of them |
| "yieldSource: <kind> doesn't allow <source>." | The kind doesn't allow that source | Pick another, or allow it on the kind |
| "rateSource: a Derived line needs a Derived structure …" | A survey line on a structure of another source | Use Configured for hand-made lines |
| A tree counts half | It lies in another structure's shared area too | Expected (§ 3.3) |
| A new output has no line after a yield table save | The structure has no survey yet, or the row's From level is above the structure's level | Survey now; check From level; `POST …/materialize` |
| "Production is turned off (Production:Enabled): surveys are not taken." in the game server log | The API's switch is off | Tick Production enabled |
| `/knk production` answers "Unknown structure 'X': use its id" | The name has spaces, is not unique, or the structure has no area | Use the id |

## Changes

1. 2026-11-20: first version (docs PandiO/knk-workspace#882).
