# Production kinds, yield areas, levels, harvesting and regeneration

**Status:** Draft (rev. 2 companion to [DESIGN.md](DESIGN.md)). It records the developer's notes 7, 8, 11, 13 and 18
of 2026-10-09 and proposes mechanics. The decisions in §9 are open. Nothing is implemented.
**Last updated:** 2026-10-09
**Linear:** [KNG-83](https://linear.app/kngpandi/issue/KNG-83) (parent); phases in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).
**Related:** [KNG-48](https://linear.app/kngpandi/issue/KNG-48) (block-break in resource regions),
[managed regions](../../architecture/managed-worldguard-regions.md) (`RESOURCE_PRODUCTION` kind), V1
`Resources/*` and `Handlers/ResourceBlockBreakEvent.java` ([events-v1.md](../legacy/events-v1.md) lines 2073-2230).

## 1. Purpose

A `ProductionStructure` produces **raw** resources: the start of every supply chain. Note 7 lists the kinds below.
They differ mainly in **where** the resources come from:

- a bordered field;
- an exclusive volume;
- a shared radius;
- a pasture;
- hunting grounds.

Yields are computed from what is actually in that area (note 8), then multiplied by the structure's level, its town
and other factors.

## 2. Kinds are data

`ProductionKind` is a catalogue row, edited in the web app. It is not a class per kind (DESIGN §3.1). Fields:

| Field | Meaning |
|---|---|
| `Name`, `Description`, `Icon` | e.g. "Logger", "Quarry". |
| `AreaModel` | `BorderedField`, `ExclusiveVolume`, `SharedRadius`, `Pasture`, `HuntingGround` (§3). These are code strategies. |
| `AllowedYieldSources` | `Derived`, `Configured`, `Hybrid` (§4.1). |
| `SurveyProfile` | What the survey counts and how it groups units: materials, tree species and size, water and biome, entity types (§3.2). |
| `YieldTable` | `SurveyUnit → output blueprint` rows: base rate per unit per hour, byproduct chance, minimum level. |
| `PrimaryOutputs` | For kinds "designed for" one output (a coal mine). They get the primary multiplier; everything else is a byproduct. |
| `Levels` | `ProductionKindLevel` rows (§5). |
| `HarvestRules` | Player harvesting (§6). |
| `RegenerationRules` | §7. |
| `DefaultStorages` | Purposes and caps created with a new structure. |

### 2.1 Initial catalogue (note 7; concept v0.2 L158: Lumberyard, Mines, Quarry, Farm, Fishing docks)

| Kind | Area model | Exclusive? | Survey basis | Outputs (examples) | Special |
|---|---|---|---|---|---|
| **Farm** | BorderedField | yes | Crop blocks per type on farmland (wheat, carrots, potatoes, beetroot, melon and pumpkin stems/fruit, sugar cane, cocoa, nether wart, sweet berries, …). | The crop, plus seeds as a byproduct. | Crop mix = field contents. |
| **Logger** | SharedRadius around the structure, or an admin polygon | no | Trees: clusters of logs + leaves, grouped by species and size class. Saplings count as future yield. | Logs per species (oak, spruce, birch, jungle, acacia, dark oak, cherry, mangrove), sticks or saplings as byproduct. | No dedicated field. Yield follows the forest. Shared with other loggers and players (§3.4). |
| **Quarry** | ExclusiveVolume (WorldGuard region or WorldEdit selection) | yes | Stone-type blocks in the volume: stone, granite, diorite, andesite, deepslate, tuff, sandstone, … plus ores. | Rock types by share; ores as byproducts. | |
| **Mine** | ExclusiveVolume ("mineshaft") | yes | Ore blocks (primary = the ore it was designed for) and rock. | Primary ore; other ores and rock as byproducts. | `PrimaryOutputs` boost. |
| **Fishery** | SharedRadius over water | no | Water volume (source blocks), biome (ocean, river, swamp, …), depth, open-sky share. | Fish per biome table (cod, salmon, tropical, pufferfish), byproducts (junk/treasure, chance and level-gated). | Spoilage later (§8.5). |
| **Flower farm** | BorderedField | yes | Flower blocks per type in bordered beds. | Flowers, dyes later via processing. | One or more flower types. |
| **Florist** | SharedRadius | no | Flowers per type present in the cultivated area. | Flowers. | Like Logger/Fishery: cultivates a shared area. |
| **Animal farm** | Pasture (region) | yes | Animal entities per type inside the pasture. | Drops of the selected animals (wool, leather, beef, pork, mutton, feathers, eggs, milk later). | Population regulation (§8.7). |
| **Hunter** | HuntingGround: home-base structure + hunting areas (regions or radius) | no | Mob spawn potential (biome, light, area) and observed kills. | Drops of passive and hostile mobs (leather, bones, string, gunpowder, …). | Touches mob spawning rules (§8.8). Later. |

## 3. Areas

### 3.1 Area models

`ProductionArea` (owned by the structure) has:

- `Model`;
- `Shape`, one of:
  - a WorldGuard region id (a managed region parented to the structure);
  - a WorldEdit cuboid or polygon (stored as points, captured with a WorldTask, like existing region capture);
  - `Radius` around a centre (default: the structure's Location);
- `Exclusive`, from the model; can be overridden off;
- `LastSurveyId`.

A structure can have several areas, for example a farm with two fields.

- **Exclusive areas** of the same model may not overlap. This is checked on save in the API from bounding boxes,
  with exact checks in the plugin.
- **Shared areas** may overlap each other and anything else (§3.4).

### 3.2 Surveys

An **AreaSurvey** is a snapshot of what the area contains, computed by the plugin and stored by the API:

- `SurveyedAt`;
- the `SurveyProfile` version;
- `Units`: a list of (unit key, count, extra); for example `TREE:OAK:LARGE ×12`, `BLOCK:COAL_ORE ×340`,
  `WATER:RIVER ×4,200`, `ENTITY:SHEEP ×18`;
- a content hash.

Survey history is kept so that the dashboard can show trends (a forest being cut down).

- **How:** async `ChunkSnapshot` reads (no main-thread block access), the same technique as road tile scans.
  - Trees: connected log clusters with leaves within reach; species by log type; size class by log count.
  - Pastures and hunting grounds count entities (main thread, cheap). Hunting grounds also sample spawn conditions.
- **When:**
  - on creation;
  - on admin request (`/knk production survey <structure>`, web app button);
  - on a schedule (default daily) when the chunks are loaded or can be loaded cheaply;
  - after notable change (for example, harvested blocks in the area exceeding a threshold).
- **Placeholders:** blocks waiting to regenerate (§7) count as present. A survey measures the **intended** state,
  so harvesting doesn't make the structure's yield flap.

### 3.3 Area capture and editing

Areas are created and edited in the web app (note 10), with a world capture step:

- the existing WorldTask `DefineRegion` flow for regions and selections;
- a new `CaptureRadius` (stand at the centre, set the radius) for shared areas.

In game, `/knk production area show <structure>` draws the outline with particles. The navigation trail renderer
can be reused.

### 3.4 Shared areas and competition

When shared areas overlap (two loggers in one forest), each unit is split between the structures whose areas
contain it. Recommendation: an equal split per unit (P-D4). A tree in two loggers' radii yields half to each. This
keeps the total extraction from a forest bounded no matter how many producers crowd it. Players harvesting in the
same area draw from the same pool (§6.3).

## 4. Yield

### 4.1 Yield source per structure (note 8)

| Mode | Rates come from | Use |
|---|---|---|
| `Derived` | Survey units × `YieldTable` | Pure world-driven. |
| `Configured` | An admin-entered list of outputs and rates per hour | Special structures, testing, kinds without a survey (early phases). |
| `Hybrid` (recommended default) | Derived, then admin **pins** (always include at a fixed rate), **exclusions** and **scales** per output | World-driven with balancing control. |

The effective output list and rates are materialized into `ProductionLine` rows (one per output) after each survey or
config change, with `RateSource` recorded on each line.

### 4.2 Rate formula

For each output `o` of a structure:

```
base(o)     = Σ over survey units u: count(u) × share(u) × rate(u, o)        (Derived; share = §3.4 split)
            | configured(o)                                                   (Configured)
rate(o)     = base(o) × Π multipliers                                         (per hour)
multipliers = level(o)        — §5, includes 0 when o is not unlocked at this level
            × primary(o)      — PrimaryOutputs boost (mines)
            × town            — town level/prosperity, later tech
            × territory       — vision §2.3 resourceYield, later
            × pool(area)      — ResourcePool fill factor (§6.3)
            × season/event    — later
            × admin scale     — Hybrid
```

Byproducts are produced as a **share** (rate × chance), not as random rolls. That keeps output predictable and
testable. A per-cycle random variation (±x%) can be enabled per kind for flavour.

### 4.3 Accrual and cycles

Rates can be fractional (0.3 iron per hour), so each line keeps a decimal `Accrued`. Each settle does:

```
Accrued += rate × elapsed
emit floor(Accrued)
Accrued -= emitted
```

Settles happen on the line's due time, which is anchored; there is no drift (V2 defect 5). Catch-up is capped. A
full output storage sets `BlockedFull`, and accrual stops (DESIGN D4). Every settle writes a
**`ProductionCycleRecord`** with elapsed time, base, each multiplier, emitted amount, accepted amount and the reason
for any shortfall. This is the "why did it produce 7" trace for the web app (note 10).

## 5. Levels (note 11)

`ProductionKindLevel` (per kind):

| Field | Meaning |
|---|---|
| `Level` | 1..N (P-D5) |
| `YieldMultiplier` | Applied to every output. |
| `OutputUnlocks` | Outputs that need at least this level (for example diamonds as a mine byproduct from level 5). Some byproduct chances grow per level. |
| `MaxAreaSize` | Bounds for areas: blocks/volume or radius. |
| `StorageCaps`, `TransportCapacity` | Written to the structure on level change. |
| `UpgradeCost` | Resources (blueprint × amount) + coins. Paid from a storage as `Upgrade` consumption moves and through the currency service. |
| `UpgradeDuration` | Optional construction time. |
| `Requirements` | Town level, technology, profession (later; evaluated through a shared `IRequirementEvaluator`). |

Upgrades are performed by admins in the MVP. Once ownership exists, owners upgrade, possibly with resources donated
by players (concept v0.2 L166: shop levels "gated by donated resources or completed quests").

**Shop levels** (note 12) use the same pattern in the shop design. Their extra fields cover:

- cycle-speed multiplier;
- input-cost multiplier;
- price multiplier;
- merchandise caps.

## 6. Player harvesting in yield areas (note 13)

### 6.1 What players can do

V1 let players mine and farm inside resource properties (`/rp`, `ResourceBlockBreakEvent`) and regrew the blocks.
V3 keeps this:

- By default, players break nothing inside a production area: the WorldGuard `block-break` and `interact` deny of
  the `RESOURCE_PRODUCTION` region.
- A KnK listener **allows** the blocks or entities listed in the kind's `HarvestRules` for players who meet the
  rule. This is the listener [KNG-48](https://linear.app/kngpandi/issue/KNG-48) asks for; KNG-48 is folded into this
  phase.

`HarvestRule`:

| Field | Meaning |
|---|---|
| `Targets` | Materials (`COAL_ORE`, `WHEAT` age 7, `*_LOG`) or entity types. |
| `Requirement` | A permission node, title bracket, skill or profession level, or knowledge unlock (vision §3.6; iPhone L151 "Knowledge nodig om materials te minen en farmen", knowledge is needed to mine and farm materials). Evaluated by the shared `IRequirementEvaluator`, so new progression systems plug in later. |
| `Tool` | Required tool class or tier. |
| `YieldToPlayer` | Output blueprint and amount per break. V1 formula: `baseDropAmount × fortune factor`, capped at Fortune IV. Items are blueprint items (DESIGN §8). |
| `PoolCost` | Units drawn from the area's `ResourcePool` per break. |
| `Cooldown` | Per player per area (anti-farming), optional. |
| `Fee` | Later, with ownership: a share of the value to the owner or town. |

### 6.2 Physical yield

The broken block's vanilla drops are replaced by the rule's blueprint items, delivered like any drop. The block is
handed to the regeneration service (§7). Harvested items are **player property**, not structure stock. They don't
pass through a storage unless the player deposits them.

### 6.3 Impact on the structure: the shared ResourcePool

Each area has a `ResourcePool`:

- `Capacity`, derived from the survey (for example the total harvestable units);
- `Current`;
- `RegenPerHour`.

- **Player harvesting** reduces `Current` by `PoolCost`.
- **Regeneration** adds `RegenPerHour`, up to `Capacity`.
- **Production** reads the fill factor:
  `pool multiplier = floor + (1 − floor) × Current / Capacity`, with `floor` per kind (for example 0.5).

So heavy player harvesting visibly slows the structure, recovers over time, and can never stop it completely. This
gives harvesting a real economic effect (P-D6).

The abstract production itself does **not** draw down the pool and does **not** change blocks. The world stays
stable, and the structure doesn't eat its own forest. A later "workers" visual layer can show NPC workers without
changing the stock math.

## 7. Block regeneration (note 18)

Harvested blocks come back, as in V1 (`Resources/BlockRefresh.java`; ore and stone cooldowns persisted, crops and
wood after 25 s).

- **Regeneration jobs** are stored **plugin-side on disk**, per world, like the KNG-56 flag cache. They hold position,
  original block data, placeholder and restore time. They survive restarts and are applied when the chunk is loaded.
  Restores are idempotent: they only restore if the placeholder is still there.
- **Placeholders per rule:**

  | Harvested | Placeholder | Restore |
  |---|---|---|
  | Ore, rock | Stone / bedrock-like "depleted" block (P-D7) | Original block after the cooldown |
  | Crops | Replanted at age 0 | Natural growth, or forced to mature after the cooldown |
  | Flowers | Air | Original after the cooldown |
  | Trees (whole tree felled) | Sapling | **Snapshot restore** of the original tree after the cooldown (saved on fell, like gate block snapshots), or vanilla growth (P-D8) |
  | Animals, mobs | — | Population regulation (§8.7), not block regeneration |

- Cooldowns are per rule and can be scaled by the structure's level and by pool fill.
- A later option: **per-player ore refresh** (iPhone L133). Each player sees their own copy of an ore vein through
  client-side block changes. Noted, not designed.

## 8. Kind notes and open details

### 8.1 Farm

Counts mature-capable crop blocks per type; growth stage is ignored for yield. Bordered region. Byproduct seeds.
Open: whether farmland must be hydrated to count.

### 8.2 Logger

- A tree = a log cluster connected to leaves. Size classes come from log count (small/medium/large).
- Species come from the log material; mixed trees go to the majority species.
- Saplings count at a small rate (future forest).
- Deforestation by players lowers the next survey's base, and the pool reflects short-term damage.
- Open: tree detection limits (giant jungle and dark oak trees), radius defaults per level.

### 8.3 Quarry

Composition by rock type in the volume; ores in the volume are byproducts. Open: count only exposed blocks
(faces touching air) or the whole volume? Recommendation: whole volume, because the quarry "digs".

### 8.4 Mine

Like Quarry, with `PrimaryOutputs` = the designed ore. Open: should a mine's yield follow the ore actually present
in the shaft, or the designed ore regardless? Recommendation: survey-based, with a primary boost. A coal mine with no
coal in its shaft produces little, which rewards good placement.

### 8.5 Fishery

- Water source blocks within the radius, by biome. Depth and open sky act as multipliers.
- The fish table follows the vanilla fishing loot weights per biome, adjusted.
- **Spoilage** (later): a `Perishable` property on blueprints, with shelf life per item. Stock lines track batches
  (production date), and a periodic job moves expired batches to `SYS_LOSS` (`Spoilage`). Ice in the storage, or
  knowledge, extends shelf life. This needs batch tracking on `StockLine` (ERP "lots"). Deferred; the stock model
  can add a `BatchDate` column without changing moves.

### 8.6 Flower farm and Florist

A flower farm is a Farm with flower beds (bordered, exclusive). A florist cultivates a shared radius (non-exclusive)
and yields what grows there. Both use the same survey unit (`FLOWER:<type>`).

### 8.7 Animal farm

- The pasture region counts animals per selected type. Yield is per animal per hour (wool, leather, meat, eggs).
- **Population regulation:** a target population per type, set by level and pasture size.
  - Below the target, the plugin spawns (breeds) animals over time.
  - Above it, it culls to the target and converts the culled animals into extra yield.
  - Feed as an input line (wheat, carrots, seeds) is optional; without feed, breeding stops.
- Open: whether animals killed by players in the pasture count as harvest (with HarvestRules) or as theft.

### 8.8 Hunter

- Home base (the structure) + hunting grounds (regions or radius).
- Yield is simulated from the mob types that can spawn there (biome, light, time of day) and from a "hunt
  effectiveness" set by level.
- Real kills by the hunter's NPCs or by players on contract can add to it later.
- It interacts with the game's mob spawning and density rules (safezones, bandit spawns), so it needs the spawning
  design first. **Deferred.**

## 9. Decisions

| # | Question | Recommendation |
|---|---|---|
| P-D1 | Default yield source | `Hybrid` for every kind. `Configured` is allowed for testing and special structures. |
| P-D2 | Survey frequency | Daily when chunks are loaded, plus on demand and after large changes. |
| P-D3 | Survey cost limit | Max area volume per kind and level (for example 64×64×64 for quarries at level 1). Surveys run async on snapshots and are throttled per tick budget. |
| P-D4 | Shared-area split | Equal split per unit between overlapping structures. |
| P-D5 | Number of levels | 10 per production kind. (Concept v0.2 had 20 per shop; shops can choose their own.) |
| P-D6 | Player harvesting vs structure yield | Shared `ResourcePool` with a floor of 0.5 (§6.3). |
| P-D7 | Ore placeholder | A neutral "depleted" block (stone for overworld ores, netherrack in the nether), so players can't tell a depleted vein from rock. |
| P-D8 | Tree regeneration | Snapshot restore (exact tree), with a sapling placeholder in between. |
| P-D9 | Byproducts | Deterministic shares, with optional ±10% per-cycle variation per kind. |
| P-D10 | Hunters and spawning | Out of the first release. Designed with the mob spawning and bandit work. |
