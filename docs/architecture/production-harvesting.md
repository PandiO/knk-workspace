# Player harvesting and block regeneration (knk-web-api and knk-plugin)

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P8 #685/#134, docs PandiO/knk-workspace#922)
**Checked against:** knk-web-api `next` `9ad32c23` (PR PandiO/knk-web-api#72), knk-plugin `next` `6f6c915f` (PR
PandiO/knk-plugin#114). Not released; the manual steps of the
[smoke test § 9](../guides/production-storage-transport-smoke-test.md#9-phase-p8-player-harvesting-and-block-regeneration-685-api-134-plugin-tier3)
have not been run live yet.
**Related:** [PRODUCTION_KINDS § 6-§ 7](../specs/production-storage-transport/PRODUCTION_KINDS.md) (the design: rules,
the worker's share, pools, regeneration), decision record § 3.6 and § 11 F9-F10
([DECISIONS_2026-11-05](../specs/production-storage-transport/DECISIONS_2026-11-05.md)),
[API contract](../specs/api/API_CONTRACT_HARVESTING.md), [harvesting admin guide](../guides/admin/production-harvesting-admin-guide.md),
[harvesting player guide](../guides/users/harvesting-player-guide.md), [production engine](production-engine.md) (settle,
the built-in steps), [yield areas and surveys](production-yield-areas.md) (areas, surveys, the placeholder overlay),
[stock core](stock-core.md) (the ledger), [plugin configuration § 4.31](../guides/admin/plugin-configuration.md#431-production)
(`production.harvest.*`)

Phase P8 lets players work in a production structure's **yield areas**. A **harvest rule** per production kind names
what a player may break or kill there, who may, with which tool and how often, and what one break yields. The game
server decides each break from a cached **catalogue**, replaces the vanilla drops, leaves a **placeholder** and reports
the harvest. The API books it once: the **worker's share** goes to the player, the **town's share** into the structure's
Output storage. Each break also draws on the area's **resource pool**; while the pool is low the structure produces
less on its own (never below the kind's floor), so harvesting has a cost, and the **net-output check** says whether a
rule still leaves the town better off. The block comes back after the rule's regeneration time.

Everything here needs both switches on: the game server's `production.enabled` and the API's game setting **Production
enabled** (`Production:Enabled`). With either off, breaks in production areas behave exactly as before (A21): the
catalogue is empty (`featureEnabled: false`), reports are refused with 409 `ProductionDisabled`, and the plugin builds
nothing.

## 1. Ownership

| Part | Where | Owns |
|---|---|---|
| `HarvestRule`, `ResourcePool`, `PlayerHarvest`, `HarvestAccrual` | knk-web-api `Models/Production/ProductionHarvest.cs` | The rule, the pool per area, the booked history, the carried fractions |
| `ResourcePoolMath` | knk-web-api `Services/Production/ProductionHarvest.cs` | Pure pool arithmetic shared by the engine, the reports and the balance check (§ 3) |
| `HarvestRuleService`, `ResourcePoolService`, `HarvestService` | same file | Rule CRUD and the balance check; pool CRUD and survey capacity; reports, the catalogue and the history |
| `HarvestRulesController`, `ResourcePoolsController`, `PlayerHarvestsController`, `HarvestController` | knk-web-api `Controllers/HarvestRulesController.cs` | `api/HarvestRules`, `api/ResourcePools`, `api/PlayerHarvests`, `api/Harvest` ([API contract](../specs/api/API_CONTRACT_HARVESTING.md)) |
| Pool step in settle | knk-web-api `Services/Production/ProductionEngine.cs` (`PoolFactorAsync`) | `poolFactor` on the production view and on `ProductionCycleRecord` |
| `ProductionSettings.ValidateHarvest` | knk-web-api `Services/Territory/ProductionSettings.cs` | The game settings section `production.harvest` |
| `HarvestGate`, `HarvestCatalog`, `HarvestAreaIndex`, `HarvestTools`, `HarvestCooldowns`, `RequirementEvaluator` | knk-plugin knk-core `production/harvest/` | The break decision (no Bukkit) |
| `RegenQueue`, `RegenJob`, `TreeFeller` | same | Regeneration jobs, the restore rules, whole-tree snapshots; the survey `PlaceholderOverlay` |
| `HarvestOutbox`, `OwedPay` | same | Report entries and their keys; shares owed to offline players |
| `HarvestApi` / `HarvestApiImpl` | knk-core port, knk-api-client | `GET api/Harvest/catalog`, `POST api/Harvest/reports` |
| `HarvestModule`, `HarvestWorldGuardListener`, `HarvestRequirements`, `HarvestConfig`, `HarvestStore` | knk-paper `production/harvest/` | The listeners, pay, the files, the WorldGuard pass, permission and title checks, `production.harvest.*` |
| Wiring | knk-paper `KnKPlugin` (`initializeHarvesting`), `GlobalRegionProtectionListener.setAllowedBreaks`, `SurveyModule` (the overlay), `ProductionAdminCommand` (`/knk production harvest`) | Additive hooks |

The API is the only truth for what was booked and what a player earned. The game server decides who may break what
(requirement, tool, cooldown are stored in the API but checked only by the game server) and owns the regeneration
queue; the API only tells it how long each block waits.

## 2. Harvest rules and targets (PRODUCTION_KINDS § 6.1)

A rule belongs to one production kind (unique name per kind) and applies in every area of every structure of that kind.

1. **Targets:** `targetKind` Block or Entity and up to 50 material or entity type names; a name may start or end with
   `*` (`*_LOG`, `DEEPSLATE_*`). Crops can ask for a lowest block age (`minBlockAge`, 0 to 25; wheat 7).
2. **Who:** an optional permission node (`requiredPermission`, checked through the game server's permission cache) and
   an optional lowest title bracket (`minTitleBracketId`, compared with the player's experience points from the user
   cache). This is the design's `IRequirementEvaluator`, the place for professions and knowledge unlocks later (F12).
3. **Tool:** `toolClass` (Any, Pickaxe, Axe, Shovel, Hoe, Shears, Sword, FishingRod) and `minToolTier` (Any, Wood,
   Stone, Iron, Gold, Diamond, Netherite).
4. **Cooldown:** `cooldownSeconds` per player per area (up to 24 h; the game server keeps it in memory, so a restart
   clears it).
5. **Yield:** the rule's blueprint (`yieldItemBlueprintId`, DESIGN § 8: never vanilla drops), `yieldPerBreak` (up to
   64) and `fortuneBonusPerLevel` (0 to 1): `yield = breaks × yieldPerBreak × (1 + bonus × fortune)`, fortune counted up
   to level IV (V1 cap).
6. **Split and cost:** `workerShare` (0 to 1, default 0.25) and `poolCost` per break (default 1).
7. **Regeneration:** `placeholder` (DepletedBlock, Replant, Air, Sapling, None), `placeholderMaterial` (DepletedBlock
   only; null = the world's default: netherrack in the nether, end stone in the end, else stone), `regenSeconds` (1 s
   to 7 days, default 60) and `regenScalesWithPool` (§ 7).
8. **Enabled:** a switched-off rule is left out of the catalogue and its reports are Rejected. A rule with booked
   harvests can't be deleted (409); switch it off. It can't move to another kind.

**Shared areas.** Areas can overlap. The gate tries the areas at a block lowest id first and, in each, the rules of the
area's kind that target the block; the first rule the player meets wins. The first unmet condition met on the way is
the denial reason (§ 6.2).

## 3. The resource pool, its floor and refill (PRODUCTION_KINDS § 6.3, P-D6)

One `ResourcePool` per production area (unique; deleted with the area):

1. **Made on the first harvest** in the area, full: capacity = the latest survey's `TotalUnits`, else
   `production.harvest.defaultPoolCapacity` (1000); `regenPerHour = capacity ÷ defaultRegenHoursToFull` (12 h).
   Staff may make or edit it earlier (`POST`/`PUT api/ResourcePools`).
2. **Survey capacity:** with `capacityFromSurvey` on (default), every new survey of the area sets the capacity to its
   total units and keeps the fill and the hours to full (`ResourcePoolService.ApplySurvey`, called from the survey
   report). A survey of 0 units changes nothing.
3. **Lazy regeneration:** the stored `current` is "as of `lastRegenAt`". Every read adds `regenPerHour × hours since`,
   capped at the capacity (`ResourcePoolMath.CurrentAt`); there is no sweep. A write (a harvest, a staff edit) first
   brings the value to now.
4. **Draw:** a harvest takes `poolCost × breaks`, never below 0.
5. **Pool factor:** `floor + (1 − floor) × fill`, with `fill = current ÷ capacity` and the kind's `PoolFloor` (0 to 1,
   default 0.5). A structure with several areas combines them: `Σ current ÷ Σ capacity`. A structure without a pool (or
   with capacity 0) gets factor 1.
6. **In the engine:** settle multiplies each line's rate by the pool factor at settle time as a built-in step next to
   unlock and workers ([production engine](production-engine.md)); `poolFactor` is on the production view (with the
   reason "Player harvesting has drawn down the resource pool: N% output until it regenerates.") and on each
   `ProductionCycleRecord`. Before each harvest the API settles the structure, so the time before counts at the old
   factor.
7. **An empty pool** still books harvests (L21 decision 1); production simply stays at its floor. The game server may
   refuse breaks at fill 0 with `deny-at-empty-pool: true` (off by default).

## 4. The worker's share and the town's share (PRODUCTION_KINDS § 6.2, F10)

Each booked entry, in its own transaction:

1. `worker = yield × workerShare + carried`, `town = yield × (1 − workerShare) + carried`. The whole units are moved, the
   fractions are carried per player and rule in `HarvestAccrual` (decision: not per area).
2. The worker's share moves `SYS_PRODUCTION → SYS_WORLD` (all or nothing), reason **PlayerHarvest**: the items leave
   the town economy into the world, where the game server hands them over. This move must succeed, or the entry fails
   with 409 and is sent again.
3. The town's share moves `SYS_PRODUCTION → Output` (partial), reason **PlayerHarvest**. What the Output storage can't
   take stays in `SYS_PRODUCTION`: lost to the town, while the player is still paid (F10). The entry's
   `shortfallReason` says so ("The Output storage took 3 of 6: the rest is lost to the town (F10)."); a structure
   without an Output storage loses the whole town's share.
4. Both moves carry the source `PlayerHarvest`, the entry key as source ref, actor PluginServer with the player as
   acting user, component `player-harvest`, and their own stock idempotency keys `harvest:<key>:worker` and
   `harvest:<key>:town`, so the reconciler stays clean.

No wage in coins or title XP is paid per harvest (optional in V1, not built).

## 5. The net-output check (F9)

`GET api/HarvestRules/{id}/balance` answers, for every area of every structure of the rule's kind:

1. `townSharePerBreak = yieldPerBreak × (1 − workerShare)` (without fortune).
2. `lostPerBreak = Σ base rate per hour × (1 − floor) × (poolCost ÷ capacity) × (poolCost ÷ regenPerHour) ÷ 2`: the
   production lost through the lower pool factor until regeneration refills one break's pool cost. The base rate is the
   structure's enabled lines before modifiers and built-in steps (Configured: the configured rate; Derived and Hybrid:
   the yield calculation). Null when the pool never refills (no capacity or no regeneration); 0 when `poolCost` is 0.
3. `netPositive` per area is `lostPerBreak < townSharePerBreak`; the rule's `netPositive` is true when every area is
   (also with no areas yet), and `warnings` has one line per area that is not. An area without a pool is checked with
   the numbers a new pool would get (`poolExists: false`).

The check is advice: the API saves a rule that is not net-positive. The web app rule editor that shows it is #913.

## 6. The plugin side

### 6.1 The catalogue

`HarvestModule` reads `GET api/Harvest/catalog` at start, every `catalog-refresh-minutes` (5) and on `/knk production
harvest refresh`: the enabled rules and the areas of structures whose kind has one, with shape (Region, Cuboid,
Polygon, Radius), bounds, the structure's production switch and the pool fill. `HarvestAreaIndex` indexes the areas by
chunk; an area whose world is not loaded, with no volume or spanning more than `max-area-chunks` (256) chunks is left
out and named in the status. The refresh also warms the permission cache of online players for the rules' nodes (and
on join). Until the first catalogue is read, or while it says `featureEnabled: false`, every break is IGNORE.

### 6.2 The break decision (`HarvestGate`)

Main thread, from caches only, in this order:

1. **IGNORE** (left to WorldGuard, the global protection and vanilla, as without harvesting): no catalogue, the flag
   off, not a target of any rule, or outside every area.
2. **DENY** with the message `denied` (`You can't harvest this here: {reason}.`): a block waiting to regenerate (the
   message `regenerating` instead), or a target whose first unmet condition is, in order: the structure's production
   switched off; not ripe; the permission (`you need the permission <node>`) or the title (`you need the title <name> or
   higher`; `your title can't be checked right now` while the brackets aren't loaded); the tool (`needs a pickaxe`,
   `needs a iron tool or better`, article to be fixed in #924); the cooldown (`wait N s`); an empty pool with `deny-at-empty-pool`. A player whose
   user id is not cached yet is refused with `your account is still loading`. One message per player at most every 2 s.
3. **ALLOW**: the rule and the area the player met.

**Who is refused (L22 decision 1).** In an area, a rule's target the player does not qualify for is refused with the
reason, also outside every region (a logger's radius in the wilderness), so an unqualified player can't get the
vanilla drops there. Every other block is left alone. Holders of `knk.admin.world.production` are not decided at all
(bypass): their breaks are left to WorldGuard, so they neither harvest nor get refused.

### 6.3 Listeners

1. **Block break:** LOW decides (DENY cancels); HIGHEST turns off the vanilla drops for an ALLOW; MONITOR, when the
   break went through, records the harvest: the regeneration job, the cooldown, the placeholder on the next tick and the
   report entry.
2. **WorldGuard:** `HarvestWorldGuardListener` marks WorldGuard's `BreakBlockEvent` (and `DamageEntityEvent` for an
   entity rule) ALLOW for an allowed harvest, so a `RESOURCE_PRODUCTION` region's `block-break` deny for non-members
   lets it through (this replaces the KNG-48 config switch, #105). Other plugins' refusals are left alone.
3. **Global protection:** `GlobalRegionProtectionListener` asks `HarvestModule.anyAllowsBreak` through its
   `setAllowedBreaks` hook before refusing a break outside every region, so a qualified harvest in a wilderness area
   passes; nothing else changes there (L22 decision 7: a hook, not un-cancelling afterwards).
4. **Entities:** damage to a target the player may not harvest is cancelled with the reason; on the kill of an allowed
   target the drops are cleared and an entry is reported. Entities have no placeholder or regeneration (§ 8 item 6).
5. **Saplings:** a sapling standing in for a felled tree doesn't grow (`StructureGrowEvent` cancelled at its position).
6. **Chunk loads** wake waiting jobs; **joins** pay owed shares and warm permissions.

### 6.4 Placeholders and the persisted regeneration queue (PRODUCTION_KINDS § 7, P-D7, P-D8)

| Placeholder | Left meanwhile | Restored |
|---|---|---|
| DepletedBlock | `placeholderMaterial`, else netherrack / end stone / stone by world | The original block data |
| Replant | The crop at age 0 | The crop as it was |
| Air | Air | The block |
| Sapling | The whole tree is felled; a sapling of the majority log species at the base where the ground takes one (the game's own check), else air | The exact tree (logs and leaves) by snapshot |
| None | Nothing | Nothing (entity rules) |

1. **Trees:** a Sapling rule's break fells the logs 26-connected to the broken one inside the area plus the natural
   leaves within six steps (at most `tree-max-leaves`, 1500) and reports breaks = logs. More than `tree-max-logs` (256)
   logs is not a tree (a log building or a giant): only the broken log is harvested.
2. **The job** (`RegenJob`) holds every position with its original and placeholder data. Its restore time is first the
   rule's `regenSeconds`, then the API's answer (`regenSeconds` of the entry, § 7).
3. **Restore rules (`RegenQueue`, L22 decision 5):** a due job is restored only when all its chunks are loaded (a
   restore never loads a chunk; it waits for a chunk load); only when every position still holds its placeholder's
   material, else the whole job is dropped and the world left as it is; never into a living entity (postponed by
   `regen-retry-seconds`, 5); at most `regen-blocks-per-tick` (64) blocks per tick, timed as metric
   `production.harvest.regen`.
4. **Surveys:** the queue is the survey `PlaceholderOverlay`: a survey counts a block waiting to regenerate as its
   original (L12).

### 6.5 Reports, keys and pay (`HarvestOutbox`)

1. Breaks of the same player, rule, area and fortune level join one open entry until it is sent. Its key is
   `harvest-<server>-<uuid>`, the server part from the world-task lease id (else the server name).
2. Every `report-flush-seconds` (2) up to `report-batch` (200) entries go out as one `POST api/Harvest/reports` (the API
   takes at most `production.harvest.maxEntriesPerReport`, 200 by default and 500 at most). One report is in flight at
   a time.
3. **Answer:** an Applied or Replayed entry sets its jobs' restore time, updates the area's local fill (used by
   `deny-at-empty-pool`) and pays `workerUnits` of the blueprint: into the inventory, the rest at the player's feet,
   with the message `paid`; offline players are owed it (`OwedPay`) until they join. A Rejected entry pays nothing and
   tells the player `rejected` with the API's reason; its block still regenerates. An entry missing from the answer is
   sent again.
4. **Failures (L22 decision 6):** 409, 400, 403 or 404 for the whole report drop its entries (nothing was booked;
   nobody is paid; online players are told "production is switched off" or "the report was refused"). Any other failure
   (timeouts, 5xx, no connection) keeps the entries and resends them with the same keys after a growing pause (5 s up to
   5 min). The outbox is saved right after each answer, so a Replayed answer after a restart can't pay twice.

**Idempotency on the API side.** Each entry's key is unique in `player_harvests` with a SHA-256 of the entry. The same
key with the same entry answers Replayed with the stored result (checked again after the area row lock); the same key
with another entry is Rejected ("Idempotency key '…' was already used for a different harvest."). Keys are 1 to 100
characters of letters, digits and `: _ . -`. The API locks the area row, then the player's row, so concurrent
harvests in one area draw the pool one after the other.

### 6.6 Files

`plugins/KnightsAndKings/production/harvest/`, one record per line, written to a temporary file and moved into place
every `save-seconds` (10) when changed, right after each report answer and at shutdown:

1. `regen.txt`: the regeneration jobs (with tree snapshots).
2. `outbox.txt`: report entries without an answer (key, player, user, rule, area, breaks, fortune, first break,
   attempts).
3. `owed.txt`: worker's shares of offline players.

Broken lines are skipped and logged. Losing `regen.txt` leaves placeholders standing for good; losing `outbox.txt`
loses unbooked harvests (§ 8.2). Back the folder up with the world.

## 7. Regeneration time

The API's answer carries `regenSeconds = rule.regenSeconds`, or, with `regenScalesWithPool`, `regenSeconds × (2 − fill
after the draw)`: up to twice as long at an empty pool. The game server moves the restore time of the entry's jobs to
"broken at + that". The game server doesn't use the regeneration time for anything else.

## 8. Schema, migration, access, tests and limitations

### 8.1 Schema and access

1. Migration `20261121011159_AddPlayerHarvesting` (additive, after `AddItemDelivery`): tables `harvest_rules` (deleted
   with their kind; unique kind and name), `resource_pools` (unique per area, deleted with it), `player_harvests`
   (unique `IdempotencyKey`; rule and user restrict delete) and `harvest_accruals` (unique user and rule), and the
   columns `production_kinds.PoolFloor` (0.5) and `production_cycle_records.PoolFactor` (1). No data written.
2. Seeds: form and display `HarvestRule`, `ResourcePool`; display `PlayerHarvest`; `ProductionKind` v3 (form and
   display, with the pool floor). `HarvestAccrual` has none (a counter table).
3. Access: reads of `api/HarvestRules`, `api/ResourcePools`, `api/PlayerHarvests` and `GET api/Harvest/catalog` need
   the World area (`knk.admin.world`) or the plugin key; writes need `knk.admin.world` and the dashboard change rule,
   deletes also `knk.admin.delete`; `POST api/Harvest/reports` is the plugin key only. Pinned in
   `ReadAccessRulesTests`, `DeleteAccessRulesTests`, `DashboardChangeAccessRulesTests` and `LookupFiltersTests`.
   Details: [API contract § 1](../specs/api/API_CONTRACT_HARVESTING.md#1-access).
4. Game settings `production.harvest`: `defaultPoolCapacity` (1000), `defaultRegenHoursToFull` (12),
   `maxEntriesPerReport` (200, at most 500). Defaults apply when the section is missing.

### 8.2 Tests and recovery

1. knk-web-api: `ProductionHarvestTests` (pool math, the split, fractions, F10, the floor in settle, the balance,
   replay and key reuse, rejections, the flag), `HarvestControllersTests`, `AddPlayerHarvestingTests`, and with
   `KNK_TEST_MYSQL` `PlayerHarvestMySqlTests` (one pool per area and every draw counted under concurrent harvests, one
   booking per key).
2. knk-plugin: knk-core `HarvestGateTest`, `RegenQueueTest`, `HarvestOutboxTest`, `TreeFellerTest`, `HarvestRuleTest`,
   `HarvestAreaIndexTest`; knk-api-client `HarvestApiImplTest`; knk-paper `HarvestModuleTest` (MockBukkit), the harvest
   cases in `GlobalRegionProtectionListenerTest` and `ProductionAdminCommandTest`.
3. Plugin scenarios on a real Paper server: `player-harvest-regenerate` and `player-harvest-tree`
   ([plugin scenarios § 1](../guides/developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines)).
4. Manual steps: [smoke test § 9](../guides/production-storage-transport-smoke-test.md#9-phase-p8-player-harvesting-and-block-regeneration-685-api-134-plugin-tier3)
   (§ 9.1 API, § 9.2 game server).

**Recovery:**

1. **A placeholder that never comes back** (the job was dropped because the block changed, or `regen.txt` was lost):
   put the block back by hand (WorldEdit); `/knk production harvest status` counts dropped jobs since start.
2. **Harvests not booked** (a refused report, a lost outbox): the server log names the keys ("Harvest report refused
   by the API (409) …"); the players got nothing and the town nothing. Staff can grant the items with a gift
   ([reward inbox admin guide § 3](../guides/admin/reward-inbox-admin-guide.md#3-gifting-items-to-a-player)).
3. **A pool that is wrong** (a survey of a half-empty area, a typo): `PUT api/ResourcePools/{id}` with `capacity`,
   `current` or `regenPerHour`; the structure is settled first.
4. **The town's share lost to a full Output:** visible as `shortfallReason` on the harvest and `townAccepted` below
   `townUnits`; raise the Output capacity or empty it. The lost units are not booked again.

### 8.3 Limitations

1. No web app pages for rules (with the balance), pools, the history or the `production.harvest` card (#913); staff use
   the REST API ([admin guide](../guides/admin/production-harvesting-admin-guide.md)); the seeds are ready for the pages.
2. Harvest breaks also count toward the survey's NotableChange counter, so heavy harvesting can ask for a survey whose
   result doesn't change (at most once per 30 min per area) (#923).
3. Cooldowns live in the game server's memory: a restart clears them.
4. No coin wage or title XP per harvest; no professions, paid work or quests (later).
5. Requirement, tool and cooldown are only checked by the game server; the API trusts the plugin key.
6. Entity rules have no population regulation: killed animals don't come back (PRODUCTION_KINDS § 8.7).

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#922), checked against knk-web-api `next` `9ad32c23` and
   knk-plugin `next` `6f6c915f`.
