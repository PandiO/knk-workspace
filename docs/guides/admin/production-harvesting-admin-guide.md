# Player Harvesting, Resource Pools and Regeneration — Admin Guide

**Status:** Current · **Last updated:** 2026-11-21 (first version, production P8 #685/#134, docs PandiO/knk-workspace#922)
**Checked against:** knk-web-api `next` `9ad32c23`, knk-plugin `next` `6f6c915f` (not released; the manual steps of the
[smoke test § 9](../production-storage-transport-smoke-test.md#9-phase-p8-player-harvesting-and-block-regeneration-685-api-134-plugin-tier3)
have not been run live yet)
**Related:** [harvesting player guide](../users/harvesting-player-guide.md) (what players see; not repeated here),
[harvesting architecture](../../architecture/production-harvesting.md) (pool math, the split, restore rules, recovery),
[API contract](../../specs/api/API_CONTRACT_HARVESTING.md), [yield areas admin guide](production-yield-areas-admin-guide.md)
(areas and surveys), [production engine admin guide](production-engine-admin-guide.md) (kinds, lines, the production
view), [stock admin guide](stock-admin-guide.md) (Output storages, the Stock ledger),
[plugin configuration § 4.31](plugin-configuration.md#431-production) (`production.harvest.*`),
[Game Settings](../game-settings.md)

Players can work in a production structure's yield areas: break the blocks (or kill the animals) a **harvest rule**
names, keep a share as pay and give the rest to the structure's Output storage. This guide covers what you set up (the
switches, rules, pools, the API and game server settings), how to check a rule's balance, the in-game status command, a
safe test and what to do when something goes wrong.

## 1. What you need

1. **Both switches on.**
   1. The API's game setting **Production enabled** (`Production:Enabled`; Admin → Settings, the **Production and
      territory** card, see [Game Settings](../game-settings.md#production-and-territory)).
   2. The game server's `production.enabled: true` in the plugin `config.yml`, with the `production.harvest` block (§ 5;
      restart).

   With either off, breaks in production areas behave exactly as before: the harvest catalogue is empty and nothing is
   harvested or refused by harvesting.
2. **The migration** `AddPlayerHarvesting` on the API's database (four new tables and two columns with defaults;
   additive; [production installation § 5.3](../production-installation.md) item 15).
3. **The seeds** imported with "make default": `HarvestRule` and `ResourcePool` (form and display), `PlayerHarvest`
   (display, view only) and `ProductionKind` v3 (form and display, with the pool floor). The web app has no harvest pages yet
   (#913: rule editor with the balance, pools, history, the settings card); the seeds are ready for them. Until then
   everything here goes through the REST API (Swagger or a REST client, signed in as staff).
4. **Structures with areas.** Harvesting only happens inside the production areas of structures whose kind has an
   enabled rule ([yield areas admin guide § 3](production-yield-areas-admin-guide.md#3-areas)). Give each structure an
   **Output storage** ([stock admin guide](stock-admin-guide.md)): without one the town's share is lost.
5. **Nodes:**

   | Task | Node |
   |---|---|
   | Harvest in game | none, or the rule's own `requiredPermission` (§ 2) |
   | Read rules, pools, the history and the balance | `knk.admin.world` (or a node under it) |
   | Write rules and pools | `knk.admin.world` and the dashboard change rule for the type |
   | Delete a rule or a pool | `knk.admin.world` **and** `knk.admin.delete` |
   | `/knk production harvest status\|refresh` in game; also **not** harvested or refused by harvesting (bypass) | `knk.admin.world.production` (matched by `knk.admin.world.*`) |

   Test with a player account, not a staff account: holders of `knk.admin.world.production` are left to WorldGuard, so
   their breaks are neither harvests nor refused.

## 2. Writing a harvest rule

No rules are seeded. Write at least one per production kind you want players to work in (`POST api/HarvestRules`; the
web app form is #913). A rule applies in every area of every structure of its kind.

| Field | What to put | Example |
|---|---|---|
| Name | Unique within the kind | `Stone` |
| Production kind | The kind it belongs to (can't change later) | Quarry |
| Target kind, targets | Block or Entity; up to 50 names, one `*` at the start or end | `["STONE","DEEPSLATE"]`, `["*_LOG"]`, `["WHEAT"]`, `["SHEEP"]` |
| Min block age | Crops only: the ripe age | wheat 7 |
| Required permission, min title bracket | Who may (optional); grant the node with a role or group | `knk.harvest.quarry` |
| Tool class, min tool tier | What the player must hold (Any for none) | Pickaxe, Stone |
| Yield blueprint, yield per break | What a break gives (never the vanilla drop) | Cobblestone, 2 |
| Fortune bonus per level | Extra yield per fortune level, up to IV (0 = fortune does nothing) | 0.25 |
| Worker's share | The player's part, 0 to 1 | 0.25 (default) |
| Pool cost | Units drawn from the area's pool per break | 1 (default) |
| Cooldown seconds | Per player per area (optional) | 10 |
| Placeholder, placeholder material | What stands in meanwhile: DepletedBlock (with a material), Replant (crops), Air (flowers), Sapling (trees: the whole tree is felled), None (entities) | DepletedBlock, `BEDROCK` |
| Regen seconds, scales with pool | When the block comes back; optionally up to twice as long at an empty pool | 60, on |

1. **A stone rule needs a placeholder material other than stone** (for example `BEDROCK`), or a mined block would look
   untouched. Without a material the world's default is used: stone, netherrack in the nether, end stone in the end.
2. **Trees:** use targets `["*_LOG"]` with placeholder Sapling. A player breaking one log fells the whole tree; the
   report counts every log. More than 256 logs (the plugin's `tree-max-logs`) is treated as a building: only the broken
   log is harvested.
3. **Entities:** placeholder None. Killed animals don't come back on their own.
4. **Switch a rule off** (`enabled: false`) instead of deleting it: a rule with booked harvests can't be deleted.
5. A wrong value is refused with the field, for example `workerShare must be 0 to 1 (suggested 0.25).` or `targets:
   "oak log" is not a material or entity type name (letters, digits and _, may start or end with *).`

After saving, the game server picks the rule up within `catalog-refresh-minutes` (5), or at once with `/knk production
harvest refresh` (§ 6).

## 3. Resource pools and the floor

Each area has one **resource pool**. Every break takes the rule's pool cost; the pool refills by itself. While it is
low, the structure's own production is multiplied by `floor + (1 − floor) × fill`: with the default floor 0.5, an empty
pool halves production, a full pool changes nothing.

1. **You don't have to make pools.** The first harvest in an area makes a full one: capacity = the area's latest
   survey's total units, else `production.harvest.defaultPoolCapacity` (1000), refilling completely in
   `defaultRegenHoursToFull` (12 h). With "capacity from survey" on (the default) every new survey of the area updates
   the capacity and keeps the fill.
2. **Tune a pool** (`PUT api/ResourcePools/{id}`): capacity, units left (`current`),
   regeneration per hour, capacity from survey. Making a pool by hand (`POST`, one per area) with a typed capacity turns
   "capacity from survey" off unless you set it.
3. **The floor** is per production kind: `poolFloor` on the kind (0 to 1, default 0.5) in the Production Kind form (with the
   v3 seed) or `PUT api/ProductionKinds/{id}`.
4. **Where to see it:** `GET api/ResourcePools/{id}` shows `fill`, `poolFactor` and `hoursToFull`; the structure's production view
   shows `poolFactor` with the reason "Player harvesting has drawn down the resource pool: N% output until it
   regenerates."; each production cycle record keeps the factor used.
5. **An empty pool** still books harvests; the structure stays at its floor. To refuse harvests at an empty pool
   instead, set the plugin's `deny-at-empty-pool: true` (§ 5): players see "… is exhausted for now; come back later".

## 4. Checking a rule's balance (the net-output check)

A rule is **net-positive** when the town's share of one break is more than the production the structure loses while
the pool refills that break's cost. Check every rule after writing it, and again after changing the area, the pool or
the structure's lines:

```
GET api/HarvestRules/{id}/balance
```

1. `townSharePerBreak`: yield per break × (1 − worker's share).
2. Per area: `lostPerBreak` (null when the pool never refills), `netPositive`, and the pool numbers used
   (`poolExists: false` means the numbers a new pool would get).
3. `warnings`: one line per area that is not net-positive.

If a rule is not net-positive, raise the yield per break, lower the worker's share or the pool cost, or give the pool
more capacity or faster regeneration. The API saves a rule either way; the check is advice. (The rule editor that shows
it next to the form is #913.)

## 5. Settings

### 5.1 API: game settings `production.harvest`

Optional; the defaults apply when the section is missing. In the production section of `PUT api/GameSettings` (the web
app's settings card for it is #913):

```json
{ "harvest": { "defaultPoolCapacity": 1000, "defaultRegenHoursToFull": 12, "maxEntriesPerReport": 200 } }
```

| Key | Default | Meaning |
|---|---|---|
| `defaultPoolCapacity` | 1000 | A new pool's capacity when its area has no survey |
| `defaultRegenHoursToFull` | 12 | A new pool refills completely in this many hours (at most a year) |
| `maxEntriesPerReport` | 200 | The most entries one game server report may carry (1 to 500) |

A wrong value is refused with the key, for example `production.harvest.maxEntriesPerReport must be 1 to 500.`

### 5.2 Game server: plugin `production.harvest`

Merge into the plugin's `production` block and restart. Every key with its meaning is in
[plugin configuration § 4.31](plugin-configuration.md#431-production); the defaults:

```yaml
production:
  harvest:
    catalog-refresh-minutes: 5
    report-flush-seconds: 2
    report-batch: 200            # keep at or below the API's maxEntriesPerReport
    regen-blocks-per-tick: 64
    regen-retry-seconds: 5
    save-seconds: 10
    deny-at-empty-pool: false
    tree-max-logs: 256
    tree-max-leaves: 1500
    max-area-chunks: 256         # a bigger area is left out of harvesting (named in the status)
    messages:
      denied: "&cYou can't harvest this here: {reason}."
      regenerating: "&7This block is regenerating."
      paid: "&a+{amount} {item} &7(your share of the harvest)"
      rejected: "&cYour harvest at {area} was not booked: {reason}."
```

**Back up** `plugins/KnightsAndKings/production/harvest/` with the world ([production installation § 9.7](../production-installation.md#97-plugin-runtime-state-worth-knowing)):
`regen.txt` (blocks waiting to regenerate), `outbox.txt` (harvests not booked yet) and `owed.txt` (shares of offline
players). Restore it together with the world it belongs to.

## 6. In game: `/knk production harvest`

Node `knk.admin.world.production`.

1. `/knk production harvest status` (or just `/knk production harvest`):
   1. `Catalogue: <when read> (<n> rules, <n> areas); API flag on|off, …` and one `area left out: <area>: <why>` line
      per area the game server skipped (world not loaded, no volume, more than `max-area-chunks`).
   2. `Regenerating: <n> jobs (<n> waiting for their chunk); <n> restored, <n> dropped since start`.
   3. `Reports: <n> entries waiting (<n> sent); last <when>: <n> booked, <n> rejected`.
   4. `Harvests since start: <n>, <n> units paid; <n> offline players owed a share`.
2. `/knk production harvest refresh`: reads the catalogue now and answers `Catalogue read: <n> rules, <n> areas` (with
   `(the API's flag is off)` while it is), or `Catalogue not read: <reason>`.
3. Without `production.enabled` (or before the module starts): `Player harvesting is not running on this server.`

## 7. A safe test

On a test server, with § 1 done and a test player **without** staff nodes:

1. Write a Quarry rule `Stone` as in § 2 (`requiredPermission` `knk.harvest.quarry`, placeholder material `BEDROCK`,
   regen 60 s) and check `GET api/HarvestRules/{id}/balance` says `netPositive: true`.
2. `/knk production harvest refresh`. **Expected:** the rule and the quarry's areas counted, the API's flag on.
3. As the test player without the node, break stone in the area. **Expected:** `You can't harvest this here: you need
   the permission knk.harvest.quarry.` and the stone stays.
4. Grant the node and break stone with a stone pickaxe. **Expected:** no vanilla drop; bedrock where the stone was; a
   moment later `+<n> Cobblestone (your share of the harvest)`; the harvest in `POST api/PlayerHarvests/search`; the
   Output storage holds the town's share; the pool's `current` went down by the pool cost.
5. Wait 60 s (longer with "scales with pool"). **Expected:** the stone is back.
6. Switch the rule off and refresh. **Expected:** stone in the area behaves as without harvesting again.
7. The full test list is the [smoke test § 9](../production-storage-transport-smoke-test.md#9-phase-p8-player-harvesting-and-block-regeneration-685-api-134-plugin-tier3).

## 8. Effects on existing data

1. The migration only adds tables and two columns with defaults (`poolFloor` 0.5 on every kind, `poolFactor` 1 on
   existing cycle records); no rule or pool exists until you write one or a player harvests.
2. Writing the first rule of a kind changes every area of that kind's structures: the rule's targets there are now
   harvested by qualified players and **refused to everyone else**, also in a wilderness area outside every region.
   Other blocks in the area stay as WorldGuard and the global protection decide (L22 decision 1).
3. Structures slow down while players harvest (down to the floor), and Output storages fill faster.
4. Switching harvesting off (either switch, or the rule) leaves the history, pools and blocks waiting to regenerate:
   the game server keeps restoring jobs it already has while it runs harvesting; with `production.enabled: false` the
   jobs wait in `regen.txt` until it is on again.

## 9. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| `Player harvesting is not running on this server.` | `production.enabled` is false on that game server | § 1 item 1 |
| Status says `API flag off`; nothing is harvested | The API's **Production enabled** is off | Switch it on (§ 1), then `refresh` |
| A rule's blocks drop vanilla items and nothing is reported | The rule is off, not in the catalogue yet, or the block is outside every area of its kind | `refresh`; check the area with `/knk production area show` ([yield areas admin guide § 6](production-yield-areas-admin-guide.md#6-in-game-knk-production)) |
| Staff break blocks and nothing happens either way | Staff with `knk.admin.world.production` are bypassed | Test with a player account |
| Status lists `area left out: … spans N chunks (max 256)` | The area is too big for the game server's index | Make the area smaller or raise `max-area-chunks` |
| Players see `Your harvest at … was not booked: …` | The API rejected the entry (rule switched off, structure paused, …) or refused the report (409: production switched off) | Fix the cause; the block still regenerates; the server log names the keys |
| The Output storage doesn't grow, `shortfallReason` on harvests | The Output storage is full or missing (F10: the player is paid, the town's share is lost) | Empty or enlarge the Output storage |
| A depleted block never comes back | Someone changed the block (the job is dropped), or `regen.txt` was lost | Put it back by hand; status counts dropped jobs |
| Production of a structure is lower than its lines say | Its pool is drawn down (`poolFactor` below 1) | Expected; tune the pool (§ 3) or the rule (§ 4) |
| Surveys of a busy area run every 30 min | Harvest breaks count toward the survey's NotableChange counter (#923) | Harmless (the result doesn't change); wait for the fix |

## Changes

1. 2026-11-21: first version (docs PandiO/knk-workspace#922), checked against knk-web-api `next` `9ad32c23` and
   knk-plugin `next` `6f6c915f`.
