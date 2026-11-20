# Plugin configuration reference (`config.yml`)

**Status:** Current · **Last updated:** 2026-11-20 (§ 4.31 `production.surveys.*`, § 2.1 and § 3 rows, production chain L12, #679); 2026-11-20 (§ 4.27 `npc.navigation.road-goal-reachable`, `road-goal-walk-weight` and § 2.1 row, NPC follow-ups G1, #814); 2026-11-20 (§ 2.1 `map.reporting.*` rows on trunk since v0.3, docs #767); 2026-11-20 (§ 4.15 `navigation.road-goal-walk-weight`, `road-goal-reachable` text, `trail-leg-spacing` default 3.0 → 2.0, and § 2.1 row, off-road F3, #780, #771, #710); 2026-11-19 (§ 4.31 `production.enabled` also covers P2c, no new key, production chain L8, #677); 2026-11-19 (§ 4.13 `siege.weapons.enabled` and § 2.1 row: the web-form world task replaces `/knk weaponspot`, siege weapons L2b, #799); 2026-11-19 (§ 4.15 `navigation.road-goal-reachable`, `road-goal-candidates`, `road-to-its-end`, `trail-leg-spacing` with `guidance-v2` off, and § 2.1 row, off-road F2, #780, #771); 2026-11-19 (§ 2.1 row of #689: in `next` `55804b11`; § 4.31 links the [territory admin guide](territory-admin-guide.md), docs #806); 2026-11-19 (§ 4.13 `siege.weapons.enabled` and § 2.1 row, siege weapons L2, #783); 2026-11-19 (§ 4.31 `production` (territory), § 2.1 and § 3 rows, production chain L2, #689); 2026-11-19 (§ 4.30 `items.identity`, § 2.1 and § 3 rows, production chain L0, #141); 2026-11-18 (§ 4.15 `navigation.preference-max` and § 2.1 row, off-road L9, #709); 2026-11-18 (§ 4.15: the `/navigate` route mode words add no key, off-road L7, #707); 2026-11-18 (§ 4.15 `navigation.walk-links`, the `walk-link-*` and `road-first-*` keys, and § 2.1, off-road L5, #705); 2026-11-18 (§ 4.15 `navigation.plaza-curve-clearance`, `plaza-lines` draws on the trail, and § 2.1, #712 step 2); 2026-11-18 (§ 4.15 `navigation.landmarks` and § 2.1 row, off-road L8, #708); 2026-11-18 (§ 4.15 `navigation.destination-engine` and § 2.1 row, destination engine L3, #69); 2026-11-18 (§ 4.15 `navigation.destinations.stale-after-days` and § 2.1 row, destination engine L2, #103); 2026-11-18 (§ 4.29 `map.reporting.interval-ticks` and the live player report, § 2.1 row, overview map L4, #738); 2026-11-18 (§ 4.29 `map.reporting.enabled`, § 2.1 and § 3 rows, overview map L1, #735); 2026-11-18 (§ 4.27: every `npc.navigation` key checked against `config.yml` on knk-plugin `next` `7aef3de4`, no key added; texts of `pathfinder`, `hop-blocks`, `recheck-ticks`, `walk-only-blocks` and `stop-on-trespass` for the fix links C1 and E1, region overrides for NPCs since L9, #726); 2026-11-18 (§ 4.15 `navigation.plaza-lines`, `plaza-pull`, `plaza-guide-cost` and § 2.1, #712 step 1); 2026-11-18 (§ 4.15 `navigation.trail-leg-spacing`, `navigation.cursor-jump`, `guidance-v2` text, and § 2.1, #711); 2026-11-17 (§ 4.15 `navigation.guidance-v2`, `walk.clearance-cost`, `walk.wall-clearance`, `walk.curve` and § 2.1, #710); 2026-11-17 (§ 4.15 `navigation.walk.max-chunks-per-request` and § 2.1, #703); 2026-11-16 (§ 4.27 `npc`: the per-NPC table no longer split by the `collidable` note, link to the NPC navigation admin guide, docs #658); 2026-11-16 (§ 4.27 `npc`: push resistance for `collidable` (still false), `players-push-npcs`, `push-return`, `push-exempt-after`, `push-exempt-window-ticks`, `push-exempt-ticks`, `push-teleport-ticks`, #627); 2026-11-16 (§ 4.27 `npc`: `crowd-awareness`, #626); 2026-11-16 (§ 4.27 `npc`: `plaza-lines`, `plaza-corridor-blocks`, #625); 2026-11-15 (§ 4.27 `npc`: `group-formation-keeping`, `group-lateral-spacing-min`, `group-spacing-min`, `group-lookahead-blocks`, #624); 2026-11-15 (§ 4.27 `npc`: `local-legs-clearance`, #623); 2026-11-15 (§ 4.27 `npc`: `corridor-steering`, `corridor-half-width`, `wall-clearance`, #622); 2026-11-15 (§ 4.3 `realtime.moderation` and § 2.1, web kick/ban, #574); 2026-11-15 (§ 2.1: #522 merged into `next` `deb7ff49`, #589); 2026-11-15 (§ 4.27 `npc`: `group-lateral-spacing`, `group-width-hysteresis-blocks`, `group-followers-finish-trip`, `group-spacing` 2.0 → 1.5, `group-formation` and `group-ranks-width` texts, #522); 2026-11-15 (§ 4.27 `npc`: `corner-clearance`, `waypoint-margin`, `recovery-wait-ticks`, `stationary-ticks` and `no-progress-ticks` 40, `max-retries` reworded, #521); 2026-11-14 (§ 4.28 `testing.scenarios`, test servers only, #421); 2026-11-14 (§ 4.18 `messages.web-account-registered`, #485); 2026-11-14 (§ 2.1: the #377 `group-*` keys are in `next` since 2026-11-13, PandiO/knk-workspace#496); 2026-11-13 (§ 4.11 gates are discovered too; § 4.21 realtime push; § 4.26 the kit cache, PandiO/knk-workspace#300)
**Checked against:** knk-plugin `main` `121030f`; § 4.11, § 4.21 and § 4.26 against `57884e9`; § 4.27 `npc`, the `realtime.erasure` and `realtime.moderation` blocks and `regions.temp-retention.release-interval-minutes` against knk-plugin `next` (not on trunk yet). Update this page in place whenever a `config.yml` key is added, renamed, removed or gets a new default.
**Source:** knk-plugin `knk-paper/src/main/resources/config.yml` (1,152 lines at `121030f`), read by
`knk-paper/.../paper/config/ConfigLoader.java`, `EnchantmentConfigManager.java` and `KnKPlugin.java`
**Related:** [production installation § 9.5](../production-installation.md#95-install-the-knightsandkings-plugin),
[closed-alpha deployment runbook](../closed-alpha-deployment-runbook.md),
[global instructions § Shipping a change](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation),
[custom enchantment combat values](custom-enchantment-combat-values-admin-guide.md),
[gate structures admin guide](gate-structures-admin-guide.md)

This is the reference for every key in the Knights and Kings plugin's `config.yml`
(`plugins/KnightsAndKings/config.yml` on a server). For each key it gives the default, what the key does, safe
values, the issue that added it, and whether a restart or a reload command picks up a change.

Many settings are **not** in `config.yml`. They live in the web app and the API, and the plugin re-reads them on
its own: Game Settings (announcements, spawn, respawn, time, weather, and the chat token limits from #233), custom
enchantment combat values, lootbox areas and odds, siege lobbies and scenarios, road profiles, currency policy and
permission groups. This page only covers the file.

## 1. How the plugin reads `config.yml`

- **The file is written once.** `KnKPlugin.onEnable` calls `saveDefaultConfig()`, which writes the jar's built-in
  `config.yml` only when the server has none. After that the plugin never changes the file: a new build never adds
  its new keys, and it never removes keys it stopped reading. Merge new keys by hand at every deploy (§ 2).
- **A missing key uses the built-in default.** Where the code passes its own fallback (most keys), that is used.
  Otherwise Bukkit falls back to the jar's `config.yml`. The two are the same for every key checked for this
  reference except `custom-enchantments.messages.cmd-reload`, whose code fallback is shorter
  ([#307](https://github.com/PandiO/knk-workspace/issues/307)). So a server without a new key runs on the default, with no warning in the log. That is what goes
  wrong when a merge is skipped: you can't change the setting, and a message key shows the jar's text.
- **A key the plugin doesn't read is ignored.** An old block such as `gates.cleaving` (removed by #259) does no
  harm. Delete it when you merge, so nobody edits it expecting an effect.
- **Restart, reload or live.** The **Applies** column in § 4 says when a change takes effect:
  - **Restart:** read once at startup (most keys). Restart the server, never use `/reload` (the runbook rule).
  - **`/ce reload`:** the custom enchantment messages and death messages. The command (node
    `customenchantments.command.reload`) re-reads the whole file and refreshes the combat values from the API.
  - **`/knk lootbox reload`:** the `lootboxes` section. The command (node `knk.lootbox.admin.reload`) re-reads the
    whole file and the API's lootbox runtime config.
  - **Any reload:** a few keys are read again on every event: `join-refusal-notify.enabled`,
    `regions.global.protection` and `regions.effect-damage.enabled`. Either reload command makes the plugin re-read
    the file, so they change after `/ce reload` or `/knk lootbox reload` too.
- **Secrets.** `api.auth.api-key` (and `metrics.token`) are secrets. Keep the file `chmod 600`. Never paste them in
  an issue, a report or chat.
- **Colour codes.** Text uses `&` colour codes. `\n` starts a new line where the comment says so.

## 2. Merging config changes at a deploy

Do this at **every** plugin deploy to dev or alpha, also when the release notes list no config change.

1. **Get both files.** Extract the new jar's default and copy the server's live file:

   ```bash
   unzip -p KnightsAndKings.jar config.yml > jar-config.yml
   cp plugins/KnightsAndKings/config.yml server-config.yml          # on the alpha: the file in the stack's plugins/ folder
   ```

2. **List the differences** with [`scripts/plugin-config/config_diff.py`](../../../scripts/plugin-config/config_diff.py)
   (Python 3 with PyYAML; it runs on the developer PC too):

   ```bash
   python3 scripts/plugin-config/config_diff.py jar-config.yml server-config.yml
   ```

   It prints the keys missing on the server and the keys only on the server. Example: a file from before #259 gives
   one missing key (`custom-enchantments.messages.cmd-info-tuning-gate`) and three server-only keys
   (`gates.cleaving.*`). A file from plugin `d56e41da` (the alpha's 2026-10-24 build) gives 43 missing keys.
3. **Paste the missing keys** from `jar-config.yml` into the server file, **in the same section and with their
   comments**, so the next person can see what they do. Keep every local value (API URL, API key, server ids,
   admission mode, ports, worlds, region overrides).
4. **Delete the server-only keys** that the changelog lists as removed. If a key isn't in the changelog, check it
   for a typo first: a misspelt key is ignored too.
5. **Read the changelog's "Admin steps"** for the builds since the last deploy. They list changed defaults, which
   the script can't detect: the server keeps its old value on purpose. Adopt the new default where the entry says so.
6. **Check the YAML.** It must load (`python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" server-config.yml`).
   Then copy it back (`chmod 600`), restart, and look for `Configuration loaded successfully` in the log.
7. **Record it** in the deploy report: build, keys added, keys removed and values changed. Leave out secrets.

A `/knk config diff` command that lists missing keys in game is proposed in
[PandiO/knk-workspace#308](https://github.com/PandiO/knk-workspace/issues/308).

### 2.1 Key changes since 2026-10-24

Newest first. Builds before this list: compare the files with the script.

| Merged | Issue | Added (+), removed (−) or changed | Applies |
|---|---|---|---|
| in review, not in `next` yet (`claude/production-p4b`) | [#679](https://github.com/PandiO/knk-workspace/issues/679) | + `production.surveys.poll-minutes` (5), + `batch` (20), + `chunks-per-tick` (2), + `max-area-blocks` (16000000), + `max-area-chunks` (256), + `scheduled-loads-chunks` (false), + `notable-change-blocks` (64), + `notable-cooldown-minutes` (30), + `areas-refresh-minutes` (10): yield-area surveys, only with `production.enabled` | Restart |
| in review, not in `next` yet (`claude/npc-movement-g1`) | [#814](https://github.com/PandiO/knk-workspace/issues/814) | + `npc.navigation.road-goal-reachable` (false), + `npc.navigation.road-goal-walk-weight` (4.0): an NPC's road goal for a point destination chosen by walk reachability, as `navigation.road-goal-reachable` does for players; both per world, region, template or assignment | Restart |
| in `next` (`55804b11`, 2026-11-19), not on trunk yet | [#689](https://github.com/PandiO/knk-workspace/issues/689) | + `production.enabled` (false), + `production.territory.refresh-minutes` (10), + `production.territory.notify-players` (true), + `production.territory.report` (true), + `production.territory.map-outlines` (false), + `production.territory.max-chunks-per-world` (500000), + `production.territory.messages.*` (four lines): the production feature flag (G16) and territory, the chunk cache, the lookup on chunk crossings and the conflict report | Restart |
| in review, not in `next` yet (`claude/offroad-smoke-fixes-f3`) | [#780](https://github.com/PandiO/knk-workspace/issues/780), [#771](https://github.com/PandiO/knk-workspace/issues/771), [#710](https://github.com/PandiO/knk-workspace/issues/710) | + `navigation.road-goal-walk-weight` (4.0): with `road-goal-reachable`, a road-goal candidate's score is road length plus this times walk length; the candidates also include the road's nodes onward from the nearest point. `navigation.trail-leg-spacing` default 3.0 → **2.0** (the developer's choice in the live test of 2026-11-19); an existing `config.yml` keeps the value it has | Restart |
| in review, not in `next` yet (`claude/offroad-route-ends-f2`) | [#780](https://github.com/PandiO/knk-workspace/issues/780), [#771](https://github.com/PandiO/knk-workspace/issues/771) | + `navigation.road-goal-reachable` (false), + `navigation.road-goal-candidates` (12), + `navigation.road-to-its-end` (false); `navigation.trail-leg-spacing` (3.0, unchanged) now also spaces the walk trail with `guidance-v2: false`; `max-snap-distance` unchanged | Restart |
| in `next` (L2, #783); the web-form task in review (`claude/siege-weapons-l2b`, #799) | [#783](https://github.com/PandiO/knk-workspace/issues/783), [#799](https://github.com/PandiO/knk-workspace/issues/799) | + `siege.weapons.enabled` (false): siege weapons; with `true` the plugin handles the weapon spot form's `SiegeWeaponSpot` world task (create weapon spots from a WorldEdit selection or WorldGuard region, phase 2; L2's `/knk weaponspot` is removed by #799), later phases add placement and firing behind the same switch | Restart |
| in review, not in `next` yet (`claude/item-identity-141`) | [#141](https://github.com/PandiO/knk-workspace/issues/141) | + `items.identity.enabled` (false), + `items.identity.convert-on-obtain` (false), + `items.identity.map-refresh-minutes` (10), + `items.identity.report-interval-minutes` (10): item identity, every obtained item resolves to a blueprint | Restart |
| in review, not in `next` yet (`claude/offroad-landmark-weights`) | [#709](https://github.com/PandiO/knk-workspace/issues/709) | + `navigation.preference-max` (4.0): with `navigation.landmarks: true`, the cap of overlapping landmark preference weights on walk cells in the `preferred` route mode (and its inverse the other way); at least 1.0 | Restart |
| in review, not in `next` yet (`claude/offroad-landmarks`) | [#708](https://github.com/PandiO/knk-workspace/issues/708) | + `navigation.landmarks` (false): `true` loads the landmarks of `api/landmarks` into the navigation model, offers them to `/navigate` through the destination engine (needs `navigation.destination-engine: true` too) and turns `/knk landmark` on | Restart |
| in review, not in `next` yet (`claude/navigation-destination-engine`) | [#69](https://github.com/PandiO/knk-workspace/issues/69) | + `navigation.destination-engine` (false): `true` switches `/navigate`, its tab completion, the navigation compass and the route start to the destination engine and the road-access answers to the navigation model; removed again in phase 4b (#747) | Restart |
| in review, not in `next` yet (`claude/navigation-destination-engine`) | [#103](https://github.com/PandiO/knk-workspace/issues/103) | + `navigation.destinations.stale-after-days` (14); the plugin also writes `plugins/KnightsAndKings/offline/navigation-model.json` (the navigation model snapshot), which nothing reads before destination engine phase 3 | Restart |
| on trunk (knk-plugin v0.3) | [#738](https://github.com/PandiO/knk-workspace/issues/738) | + `map.reporting.interval-ticks` (40); with `map.reporting.enabled: true` the plugin also reports its online players (position, AFK, mode, minigame match) for the map's live player layer | Restart |
| on trunk (knk-plugin v0.3) | [#735](https://github.com/PandiO/knk-workspace/issues/735) | + `map.reporting.enabled` (false): region outlines to the API for the overview map; needs `realtime.enabled: true` | Restart |
| in review, not in `next` yet (`claude/offroad-walk-links`) | [#705](https://github.com/PandiO/knk-workspace/issues/705) | + `navigation.walk-links` (false), + `navigation.walk-link-range` (40), + `walk-link-ratio` (2.0), + `walk-link-ttl-seconds` (600), + `walk-link-retry-seconds` (600), + `walk-link-searches-per-route` (4), + `road-first-share` (0.6), + `road-first-max-ratio` (1.5); `max-snap-distance` unchanged | Restart |
| in review, not in `next` yet (`claude/offroad-plaza-lines`, step 2) | [#712](https://github.com/PandiO/knk-workspace/issues/712) | + `navigation.plaza-curve-clearance` (0.65); `navigation.plaza-lines` now draws the plaza lines on the trail | Restart |
| `next` (step 1) | [#712](https://github.com/PandiO/knk-workspace/issues/712) | + `navigation.plaza-lines` (false), + `navigation.plaza-pull` (0.35), + `navigation.plaza-guide-cost` (2); step 1: only the staff preview `/knk road plazaline` read them | Restart |
| in review, not in `next` yet (`claude/offroad-trail-cursor`) | [#711](https://github.com/PandiO/knk-workspace/issues/711) | + `navigation.trail-leg-spacing` (3.0), + `navigation.cursor-jump` (12); both act only with `guidance-v2: true` | Restart |
| in review, not in `next` yet (`claude/offroad-trail-corners`) | [#710](https://github.com/PandiO/knk-workspace/issues/710) | + `navigation.guidance-v2` (false), + `navigation.walk.clearance-cost` (5), + `walk.wall-clearance` (0.8), + `walk.curve` (true); the three walk keys act only with `guidance-v2: true` | Restart |
| in review, not in `next` yet (`claude/offroad-measurements`) | [#703](https://github.com/PandiO/knk-workspace/issues/703) | + `navigation.walk.max-chunks-per-request` (64, the limit that was built in; raise it on a test server only, for the off-road phase 0 measurements) | Restart |
| in review, not in `next` yet (`claude/web-kick-ban-574`) | [#574](https://github.com/PandiO/knk-workspace/issues/574) | + `realtime.moderation` (`kick-default-reason`, `ban-message`; optional, defaults apply when missing) | Restart |
| in review, not in `next` yet (`claude/npc-movement-m7`) | [#627](https://github.com/PandiO/knk-workspace/issues/627) | `npc.navigation.collidable` text (default still false); + `players-push-npcs` (false), + `push-return` (true), + `push-exempt-after` (3), + `push-exempt-window-ticks` (200), + `push-exempt-ticks` (1200), + `push-teleport-ticks` (600) | Restart |
| in review, not in `next` yet (`claude/npc-movement-m4`) | [#626](https://github.com/PandiO/knk-workspace/issues/626) | + `npc.navigation.crowd-awareness` (false) | Restart |
| in `next` (`3f116188`, 2026-11-16), not on trunk yet | [#625](https://github.com/PandiO/knk-workspace/issues/625) | + `npc.navigation.plaza-lines` (false), + `plaza-corridor-blocks` (16) | Restart |
| in `next` (`138ebc66`, 2026-11-16), not on trunk yet | [#624](https://github.com/PandiO/knk-workspace/issues/624) | + `npc.navigation.group-formation-keeping` (levels), + `group-lateral-spacing-min` (0.6), + `group-spacing-min` (1.0), + `group-lookahead-blocks` (4) | Restart |
| in `next` (2026-11-15), not on trunk yet | [#623](https://github.com/PandiO/knk-workspace/issues/623) | + `npc.navigation.local-legs-clearance` (false) | Restart |
| in `next` (`0fa74a67`, 2026-11-15), not on trunk yet | [#622](https://github.com/PandiO/knk-workspace/issues/622) | + `npc.navigation.corridor-steering` (false), + `corridor-half-width` (4), + `wall-clearance` (0.8) | Restart |
| in `next` (`deb7ff49`, 2026-11-15), not on trunk yet | [#522](https://github.com/PandiO/knk-workspace/issues/522) | + `npc.navigation.group-lateral-spacing` (1.0), + `group-width-hysteresis-blocks` (3), + `group-followers-finish-trip` (false); `group-spacing` default 2.0 → 1.5 (now the gap between rows and in the column). A server whose `config.yml` still says `group-spacing: 2.0` keeps 2.0: change it to 1.5 | Restart |
| in `next` (`5dc88cfd`, 2026-11-15), not on trunk yet | [#521](https://github.com/PandiO/knk-workspace/issues/521) | + `npc.navigation.corner-clearance` (1.0), + `waypoint-margin` (0.5), + `recovery-wait-ticks` (20); `stationary-ticks` and `no-progress-ticks` default 60 → 40; `max-retries` now counts the recovery steps (back-off, side-step, local leg ahead). A server whose `config.yml` still says 60 keeps 60: change the two lines to 40 | Restart |
| in `next` (`309d3580`, 2026-11-14), not on trunk yet | [#421](https://github.com/PandiO/knk-workspace/issues/421) | + `testing.scenarios` (`enabled` false, `world`, `origin.x/y/z`). **Don't merge it into real servers:** a missing block means off, which is what they need | Restart |
| in review, not in `next` yet (`claude/smoke-fixes-484-485-487`) | [#485](https://github.com/PandiO/knk-workspace/issues/485) | + `messages.web-account-registered` (optional: a missing key uses the jar's text) | Restart |
| in `next` (`745fcf6`, 2026-11-13), not on trunk yet | [#184](https://github.com/PandiO/knk-workspace/issues/184), [#269](https://github.com/PandiO/knk-workspace/issues/269) | + `realtime.erasure` (`kick-message`, `settle-seconds`, `feed-file`, `minecraft-files-list`; optional, defaults apply when missing), + `regions.temp-retention.release-interval-minutes` (5, 0 = off) | Restart |
| in `next` (`0506e691`, 2026-11-13), not on trunk yet | [#377](https://github.com/PandiO/knk-workspace/issues/377) | + `npc.navigation.group-formation`, + `group-spacing`, + `group-ranks-width`, + `group-rejoin-blocks`, + `group-regroup-blocks`, + `group-catch-up-speed` (NPC groups; nothing uses them unless a group is started) | Restart |
| in `next`, not on trunk yet | [#361](https://github.com/PandiO/knk-workspace/issues/361) | + `npc.navigation.rule-checks-per-tick`, + `npc.navigation.stop-on-trespass`; `recheck-ticks` is used from now on | Restart |
| in `next`, not on trunk yet | [#359](https://github.com/PandiO/knk-workspace/issues/359), [#360](https://github.com/PandiO/knk-workspace/issues/360) | + `npc.navigation` block (off by default): Phase 1 keys and, with Phase 2, `spawns-per-tick`, `hop-blocks`, `max-retries`, `no-route-wait-ticks`, `walk-only-blocks`, `access-profiles` | Restart |
| 2026-11-10 | [#259](https://github.com/PandiO/knk-workspace/issues/259) | − `gates.cleaving` (`damage-bonus-per-level`, `charged-hit-multiplier`, `charged-cooldown-seconds`): no longer read. Cleaving's numbers are combat values in the web app now ([combat values guide](custom-enchantment-combat-values-admin-guide.md#1-where-to-edit)). Delete the block. + `custom-enchantments.messages.cmd-info-tuning-gate` | `/ce reload` |
| 2026-11-10 | [#233](https://github.com/PandiO/knk-workspace/issues/233) | No `config.yml` change. The chat token limits are on the web app's Game Settings page ([chat tokens guide](../chat-tokens.md)) | — |
| 2026-11-04 | [#178](https://github.com/PandiO/knk-workspace/issues/178), [#179](https://github.com/PandiO/knk-workspace/issues/179) | + `realtime` block (off by default) | Restart |
| 2026-11-04 | [#180](https://github.com/PandiO/knk-workspace/issues/180) | + `world-tasks.heartbeat-interval-seconds` | Restart |
| 2026-11-04 | [#222](https://github.com/PandiO/knk-workspace/issues/222) | + `custom-enchantments.death-messages` (`enabled`, `default`, `overrides`) | `/ce reload` |
| 2026-11-04 | [#223](https://github.com/PandiO/knk-workspace/issues/223) | + `custom-enchantments.messages.cmd-info-tuning-area`. The text of `gates.area-enchantment-radius-blocks` changed: Chaos and Flash Chaos gate damage is a combat value now, the radius stays here | `/ce reload` |
| 2026-11-03 | [#201](https://github.com/PandiO/knk-workspace/issues/201) | + `custom-enchantments.messages.cmd-info-tuning-effects` | `/ce reload` |
| 2026-11-03 | [#212](https://github.com/PandiO/knk-workspace/issues/212) | + `lore.max-width` | Restart |
| 2026-10-26 | [#151](https://github.com/PandiO/knk-workspace/issues/151) | + `custom-enchantments.tuning-refresh-minutes` (restart), `custom-enchantments.messages.cmd-info-tuning` (`/ce reload`) | See § 4.20 |
| 2026-10-26 | [#159](https://github.com/PandiO/knk-workspace/issues/159) | + `join-refusal-notify` | See § 4.5 |
| 2026-10-26 | [#160](https://github.com/PandiO/knk-workspace/issues/160) | + `menus.menu-item` | Restart |
| 2026-10-26 | [#161](https://github.com/PandiO/knk-workspace/issues/161) | + `crossplay.block-resync` | Restart |
| 2026-10-26 | [#162](https://github.com/PandiO/knk-workspace/issues/162) | + `regions.effect-damage` | See § 4.23 |
| 2026-10-26 | [#150](https://github.com/PandiO/knk-workspace/issues/150), [#154](https://github.com/PandiO/knk-workspace/issues/154) | + `siege.rejoin-window-seconds`, `gates.siege` | Restart |
| 2026-10-25 | QOL hotfix | + `regions.global` (`protection`, `crafting-blocks`) | See § 4.23 |
| 2026-10-24 | siege playtest 2026-10-24 | + `gates.fire-aspect.ignite-chance-per-level` | Restart |
| 2026-10-24 | Bedrock menus | + `menus.bedrock-transition-delay-ticks` | Restart |

## 3. Sections at a glance

| § | Section | What it covers |
|---|---|---|
| 4.1 | `api` | knk-web-api URL, API key, timeouts, connectivity probe |
| 4.2 | `region-http` | The plugin's own HTTP server the API calls back |
| 4.3 | `realtime` | SignalR channel to the API (off by default) |
| 4.4 | `metrics` | Prometheus `/metrics` endpoint (off by default) |
| 4.5 | `web`, `admission`, `join-refusal-notify`, `onboarding` | Web links, the invite-only gate, refused-join notices, first join |
| 4.6 | `account` | `/account` link codes and cooldowns |
| 4.7 | `world-tasks`, `player-notifications` | Polling and leases for world tasks and queued in-game moments |
| 4.8 | `private-messages` | `/msg`, `/reply`, social spy, PM log |
| 4.9 | `game-settings` | How the plugin follows the web app's Game Settings |
| 4.10 | `teleport` | Warmups, cooldowns, `/tpa`, `/warp`, `/back` |
| 4.11 | `discovery` | Domain discovery detection and effects |
| 4.12 | `statistics`, `telemetry`, `world-analytics` | Player statistics, diagnostic events, anonymous heatmaps |
| 4.13 | `siege` | Rejoin window |
| 4.14 | `lore`, `menus`, `crossplay` | Lore width, menus, the menu item, Bedrock ghost blocks |
| 4.15 | `navigation` | Road navigation and walk paths |
| 4.16 | `currency` | `/pay`, `/baltop`, `/transactions` |
| 4.17 | `gates` | Gate commands, sync, damage, fire, pass-through, animation |
| 4.18 | `messages` | Plugin prefix, account and currency messages |
| 4.19 | `enchant-books` | Grade level cap of enchantment books |
| 4.20 | `custom-enchantments` | Runtime settings, death messages, `/ce` messages |
| 4.21 | `lootboxes` | How this server places, shows and opens lootboxes |
| 4.22 | `worlds` | Extra worlds loaded at startup |
| 4.23 | `regions` | Region cleanup, global protection, effect damage, managed regions, entry/exit |
| 4.24 | `command-visibility` | What `/` suggests |
| 4.25 | `offline-cache` | Offline security cache |
| 4.26 | `cache` | API response cache per entity |
| 4.27 | `npc` | NPC navigation on Citizens (off by default) |
| 4.28 | `testing` | In-plugin test scenarios, test servers only (off by default) |
| 4.29 | `map` | Overview map reports to the API (off by default) |
| 4.30 | `items` | Item identity: blueprint tags and the conversion hooks (off by default) |
| 4.31 | `production` | Production feature flag; territory chunk cache, lookup and conflict report; yield-area surveys (off by default) |

## 4. Key reference

Keys are written relative to the section heading (`auth.type` under `api` is `api.auth.type`). "Restart" means the
key is read at startup only (§ 1).

### 4.1 `api`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `base-url` | `"http://localhost:5294/api"` | knk-web-api base URL, **with** the `/api` suffix. Production: `http://127.0.0.1:5000/api` (loopback) | Restart | — |
| `debug-logging` | `false` | Logs every request and response (URL, latency, headers, body; the key and `Authorization` redacted). Noisy: only for a short debug session | Restart | — |
| `allow-untrusted-ssl` | `false` | Accepts self-signed certificates. Development only; keep `false` on any server that reaches the API over a network | Restart | KNG-64 |
| `auth.type` | `apikey` | `none`, `bearer` or `apikey`. The API refuses protected game-server calls without the key; `none` only works when the API sets `Security:AllowUnauthenticatedPluginCalls` (development) | Restart | KNG-22 |
| `auth.bearer-token` | `""` | Token for `type: bearer` | Restart | KNG-22 |
| `auth.api-key` | `""` | **Secret.** Must equal the API's `Security:PluginApiKey` (`Security__PluginApiKey`), e.g. `openssl rand -hex 32`. With `type: apikey` and an empty key the plugin refuses to start, on purpose. The region HTTP server (§ 4.2) also requires it | Restart | KNG-22 |
| `auth.api-key-header` | `"X-API-Key"` | Header name. Keep `X-API-Key`, which the API reads | Restart | KNG-22 |
| `timeouts.connect` / `.read` / `.write` | `10` / `10` / `10` | HTTP timeouts in seconds | Restart | — |
| `connectivity.enabled` | `true` | Probes the API's `GET /health/ready` (which checks MySQL too) and keeps one UP/DOWN state; `/knk health` shows it | Restart | KNG-115 |
| `connectivity.probe-interval-seconds` | `10` | Seconds between probes | Restart | KNG-115 |
| `connectivity.probe-timeout-seconds` | `5` | Whole-call timeout of a probe (the API's own database check gives up after 3 s) | Restart | KNG-115 |
| `connectivity.failures-to-down` | `3` | Consecutive failed probes before UP → DOWN | Restart | KNG-115 |
| `connectivity.successes-to-up` | `2` | Consecutive passing probes before DOWN → UP | Restart | KNG-115 |
| `connectivity.health-root-url` | `""` | API root that serves `/health/ready`. Empty = `base-url` without `/api` | Restart | KNG-115 |
| `connectivity.skip-api-while-down` | `true` | While DOWN, reads (permission checks, users, catalogues) make no API call and are answered from the caches, then the offline store (§ 4.25). Writes still go to the API. `false` = keep calling the API during an outage | Restart | KNG-171 |

### 4.2 `region-http`

knk-web-api calls the plugin back on this server for region renames and containment checks.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `bind-address` | `"127.0.0.1"` | Listen address. Loopback accepts only this host. Use the Docker host IP when the API runs in a container; never `0.0.0.0` on a public server | Restart | KNG-64 |
| `port` | `8081` | Listen port; the API's `MinecraftPlugin__BaseUrl` must use the same port | Restart | — |

### 4.3 `realtime`

One SignalR connection to the API's game hub ([design](../../specs/realtime-signalr/DESIGN.md),
[smoke test](../realtime-smoke-test.md)). Off by default: with `enabled: false` the plugin polls as before. Needs
`api.auth.type: apikey`.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | Turns the channel on. When on, the plugin reports who is online and re-reads what the API changed after every (re)connect | Restart | #178 |
| `server-id` | `"localhost"` | This game server's id: sent to the hub (`X-Knk-Server-Id`) and **stored on world tasks claimed here, also with realtime off** (#180). Letters, digits, `.`, `_`, `-`, at most 64. Give every server sharing one API its own id | Restart | #178 |
| `hub-url` | `""` | Full hub URL. Empty = `api.base-url` without `/api` plus `hub-path`. The plugin talks to the API directly, not through nginx | Restart | #178 |
| `hub-path` | `"/api/hubs/game"` | Hub path used when `hub-url` is empty | Restart | #178 |
| `backoff-seconds` | `[1, 2, 5, 10, 30]` | Delays between reconnect attempts; the last repeats. No attempts while the connectivity probe says DOWN | Restart | #178 |
| `backoff-jitter` | `0.2` | Random spread of each delay (0.2 = ±20 %), so servers don't retry in step | Restart | #178 |
| `erasure.kick-message` | `"Your account data has been deleted."` | GDPR erasure push (only while `enabled`): the kick text for an online player whose account the API erased. A siege vault they hold is given back before the kick | Restart | #184 |
| `erasure.settle-seconds` | `2` | Wait between the kick and the deletion of what this server keeps about the account (quit handlers, Minecraft saving the player), 0-30 | Restart | #184 |
| `erasure.feed-file` | `"erasure-feed.json"` | File in the plugin folder that keeps the position in the API's erasure feed; every (re)connect catches up from it | Restart | #184 |
| `erasure.minecraft-files-list` | `"erasure-minecraft-files.txt"` | Minecraft's own player files (`.dat`, stats, advancements) of erased accounts are listed here for the owner, never deleted | Restart | #184 |
| `moderation.kick-default-reason` | `"You were kicked by a member of staff."` | Kick and ban from the web app (only while `enabled`): the kick text when staff kick a player from the profile page without a reason. A kick with a reason shows the reason as typed. `&` colour codes; `{player}`, `{staff}` | Restart | #574 |
| `moderation.ban-message` | `"You are banned from this server.\nReason: {reason}"` | The kick text of an online player banned from the web app. The ban itself goes on this server's ban list (`banned-players.json`: permanent, the reason, the staff member's username as source; lifted with `/pardon`). `&` colour codes; `{reason}`, `{player}`, `{staff}` | Restart | #574 |
| `fallback-poll-multiplier` | `4` | While connected, re-syncs that the hub now pushes run this many times less often (social spy re-check 60 s → 4 min); the player notification poll stops while connected. `1` = no slowdown | Restart | #179 |

### 4.4 `metrics`

A Prometheus endpoint with TPS, tick time, players, chunks, JVM, CPU, memory and API-call timings
([performance metrics and capacity](../performance-metrics-and-capacity.md)). Off by default.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | Starts the endpoint | Restart | KNG-232 |
| `bind-address` | `"127.0.0.1"` | Listen address. For Prometheus in another container use the Docker host or bridge IP **and** set `token`; never `0.0.0.0` on a public server | Restart | KNG-232 |
| `port` | `9225` | Listen port | Restart | KNG-232 |
| `token` | `""` | **Secret.** Bearer token the scraper sends. Required when `bind-address` isn't loopback; the plugin refuses to start otherwise | Restart | KNG-232 |
| `sample-seconds` | `5` | How often the main thread samples TPS, tick time, chunks and entities (1–60) | Restart | KNG-232 |

### 4.5 `web`, `admission`, `join-refusal-notify`, `onboarding`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `web.public-url` | `""` | Public web app URL without a trailing slash, e.g. `https://app.knightsandkings.net`. Used in player messages (`/account link`). Empty: lines with `{url}` are left out | Restart | KNG-64 |
| `admission.mode` | `whitelist` | Admission gate at pre-login ([invitations design § 5.2](../../specs/invitations/DESIGN.md)). `whitelist`: no gate, the vanilla whitelist decides (also the kill switch). `open`: no gate. `invite`: operators and admitted accounts get in, everyone else gets a claim code; switch the API's `Security:Registration:Mode` to `Invite` at the same time | Restart | KNG-214 |
| `admission.api-timeout-ms` | `3000` | How long pre-login waits for the API. On a timeout, players the offline cache knows get in and strangers are told to retry (fail-closed) | Restart | KNG-214 |
| `admission.link-url` | `""` | Where the claim code is entered. Empty = `{web.public-url}/link` | Restart | KNG-214 |
| `admission.kick` | (text) | Disconnect screen for a stranger. Placeholders `{url}`, `{code}` (`XXXX-XXXX`), `{minutes}` | Restart | KNG-214 |
| `admission.unavailable` | (text) | Disconnect screen when access can't be checked | Restart | KNG-214 |
| `admission.deactivated` | (text) | Disconnect screen for a deactivated account | Restart | KNG-214 |
| `admission.account-linked` | (text) | In-game notice after a Minecraft-to-web link (on the next join when offline). Placeholder `{maskedEmail}` | Restart | KNG-214 |
| `join-refusal-notify.enabled` | `true` | Online holders of `knk.notify.joinattempt` get a chat line with the reason when a join is refused (ban, whitelist, full, admission gate, missing world, hub) | Any reload | #159 |
| `join-refusal-notify.cooldown-seconds` | `60` | At most one line per player per this many seconds, so a client retrying in a loop doesn't flood chat. Read at startup, although the file's comment says both keys are read on every refusal ([#307](https://github.com/PandiO/knk-workspace/issues/307)) | Restart | #159 |
| `onboarding.first-join-welcome` | (list of 2 lines) | Sent instead of "Welcome back" on a player's first join. Placeholder `{player}` | Restart | KNG-128 |
| `onboarding.link-prompt` | (text) | Text before the link button on the first join and in the reminder | Restart | KNG-128 |
| `onboarding.link-button` / `.link-button-hover` | (text) | The clickable button (runs `/account link`) and its hover | Restart | KNG-128 |
| `onboarding.discovery-quiet-minutes` | `10` | Discovery announcements are held this long after a first join and then shown as one summary (0–60, `0` = off). Rewards are given right away | Restart | KNG-129 |
| `onboarding.discovery-settled-summary` | (text) | That summary. Placeholder `{count}` | Restart | KNG-129 |
| `onboarding.unlinked-reminder.enabled` / `.message` | `true` / (text) | Reminder at every later join of a player without a web account, followed by the button | Restart | KNG-129 |

### 4.6 `account`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `link-code-expiry-minutes` | `20` | How long an `/account link` code stays valid | Restart | — |
| `chat-capture-timeout-seconds` | `120` | Longest wait for a player's chat input in an account flow | Restart | — |
| `cooldowns.account-create-seconds` | `300` | Cooldown of `/account create` | Restart | — |
| `cooldowns.link-code-generate-seconds` | `60` | Cooldown of `/account link` (getting a code) | Restart | — |
| `cooldowns.link-code-consume-seconds` | `10` | Unused: codes are entered on the website. Kept so old files load | — | — |
| `cooldowns.cleanup-interval-minutes` | `5` | How often expired cooldowns are dropped from memory | Restart | — |

### 4.7 `world-tasks`, `player-notifications`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `world-tasks.headless-poll-interval-seconds` | `5` | How often the plugin asks the API for headless (player-less) world tasks | Restart | — |
| `world-tasks.headless-poll-max-interval-seconds` | `60` | The interval doubles up to this while none is found | Restart | — |
| `world-tasks.heartbeat-interval-seconds` | `60` | How often this server renews its claims (at least 10). The API hands a claim back after 3 minutes without one (`WorldTasks:LeaseMinutes`), so stay well below that | Restart | #180 |
| `player-notifications.poll-interval-seconds` | `2` | How often queued in-game moments (e.g. a promotion granted on the web) are fetched; skipped with no players online, stopped while `realtime` is connected | Restart | — |

### 4.8 `private-messages`

`/msg`, `/reply` and `/socialspy` ([design § 3.3.10](../../specs/private-messages/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `max-length` | `256` | Longer messages are cut off (only possible from the console) | Restart | — |
| `sound.enabled` / `.volume` / `.pitch` | `true` / `1.0` / `1.0` | Sound played to the recipient | Restart | — |
| `rate-limit.max-messages` / `.window-seconds` | `5` / `5` | At most this many messages per window per sender. Bypass: `knk.msg.bypass.ratelimit` | Restart | — |
| `rate-limit.duplicate-window-seconds` | `10` | The same text to the same player within this window counts as spam | Restart | — |
| `spy.refresh-seconds` | `60` | How often the social spy audience is re-checked (× `realtime.fallback-poll-multiplier` while connected) | Restart | — |
| `log.local-enabled` / `.local-retention-days` | `true` / `30` | Daily file `logs/private-messages-YYYY-MM-DD.log` in the plugin folder, kept this many days | Restart | — |
| `log.api-enabled` | `true` | Also logs to knk-web-api (30-day retention, read with `knk.pmlog.read`). Needs the API key. Waits in memory (up to 1,000) and in `private-messages-spool.jsonl` while the API is down | Restart | — |
| `log.flush-seconds` | `5` | Sent every this many seconds or every 50 messages | Restart | — |
| `log.filter-command-log` | `true` | Keeps `issued server command: /msg …` lines out of `latest.log` | Restart | — |
| `block-vanilla-commands` | `true` | Routes `/minecraft:msg`, `tell`, `w` through `/msg` and blocks `/teammsg`, `/tm`, `/me` for non-ops, so they can't bypass spy, the limit and the log | Restart | — |

### 4.9 `game-settings`

The settings themselves are edited on the web app's Game Settings page ([game settings guide](../game-settings.md));
these keys only tune how the plugin follows them.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `refresh-interval-seconds` | `30` | How often the settings are read (at least 5). `/knk cache refresh` reads them at once | Restart | KNG-52 |
| `runtime-sync-interval-seconds` | `30` | How often loaded worlds are checked; reported to the API when they change or every 10 minutes (at least 5). Needs the API key | Restart | KNG-52 |
| `server-id` | `"default"` | This server's id in that report; each server replaces only its own worlds. Give every server sharing one API its own id. Blank = `default` | Restart | KNG-118 |
| `backup-history-limit` | `48` | Earlier versions kept in `game-settings-backups/` (0 = none). The latest is always in `game-settings-cache.json` and used when the API is down at startup | Restart | KNG-52 |

### 4.10 `teleport`

Player teleports (`/tpa`, `/tpahere`, `/spawn`, `/warp`, `/back`). Staff teleports (`/tp`, `/tphere`, `/knk tp`)
are instant and skip all of this ([teleport design § 3.11](../../specs/teleport/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `warmup-seconds` | `5` | Wait before a teleport; moving a block or taking damage cancels it | Restart | — |
| `warmup-short-seconds` | `3` | Warmup for holders of `knk.teleport.warmup.short` (Noble tier and up) | Restart | — |
| `cooldown-seconds` | `30` | Before the same kind of teleport works again. A permission group's own cooldown (web app, KNG-41) replaces it | Restart | — |
| `combat-tag-seconds` | `10` | A PvP hit (dealt or taken) blocks player teleports this long | Restart | — |
| `safe-search-radius` | `3` | Blocks searched around an unsafe destination for a safe spot before refusing | Restart | — |
| `request.expire-seconds` | `30` | Time the target has to accept a `/tpa` or `/tpahere` | Restart | — |
| `request.cooldown-seconds` | `10` | Between two requests from one player (`knk.teleport.bypass.cooldown` skips it) | Restart | — |
| `request.max-incoming` | `5` | Pending requests per player; the oldest is dropped past this | Restart | — |
| `request.price-coins` | `0` | Coins a request costs (0 = free), charged by the API after the warmup and refunded on failure. A permission group can replace it (KNG-41) | Restart | — |
| `destinations.cache-seconds` | `60` | How long a player's `/warp` destination list is cached | Restart | — |
| `back.enabled` | `true` | `/back` to the latest death or teleport the player's nodes allow (KNG-42) | Restart | KNG-42 |
| `back.expire-seconds` | `300` | How long `/back` stays available after the death or teleport | Restart | KNG-42 |
| `back.expire-seconds-by-kind` | (not set) | Optional per-kind overrides: `death`, `warps`, `teleport`, `spawn` (commented example in the file) | Restart | KNG-42 |
| `back.price-coins` | `0` | Coins a player's own `/back` costs (`knk.teleport.bypass.cost` pays nothing) | Restart | KNG-42 |

### 4.11 `discovery`

The first entry into a Town, District, Structure or gate is recorded and rewarded once; the API decides the rewards and
caps ([design § 3.6](../../specs/domain-discovery/DESIGN.md), [economy admin guide § 5](economy-admin-guide.md#5-discoveries)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | Detection on or off | Restart | KNG-20 |
| `batch-window-ticks` | `20` | How often entered regions are sent, one request per player | Restart | KNG-20 |
| `max-requests-per-minute` | `12` | Per player; the rest waits | Restart | KNG-20 |
| `excluded-game-modes` | `[CREATIVE, SPECTATOR]` | Game modes that discover nothing | Restart | KNG-20 |
| `exclude-siege-participants` | `true` | Siege lobby members discover nothing until restored after the match | Restart | KNG-20 |
| `spool-directory` / `replay-interval-seconds` | `discovery-spool` / `60` | Discoveries made while the API was down, one file per player, replayed this often and at the next join | Restart | KNG-20 |
| `effects.sound` / `.sound-volume` / `.sound-pitch` | `UI_TOAST_CHALLENGE_COMPLETE` / `0.8` / `1.0` | A Bukkit `Sound` name or a namespaced key | Restart | KNG-20 |
| `effects.particle` / `.particle-count` / `.particle-spread` | `HAPPY_VILLAGER` / `30` / `0.6` | A Bukkit `Particle` that needs no extra data | Restart | KNG-20 |
| `effects.town-firework` | `true` | Extra firework for a Town | Restart | KNG-20 |
| `effects.spacing-ticks` | `10` | Between the effects of several places found at once | Restart | KNG-20 |
| `messages.discovered` | (text) | One line per place. `{type}`, `{name}`, `{parent}` | Restart | KNG-20 |
| `messages.replay-summary` | (text) | Shown when spooled discoveries are granted later. `{count}` | Restart | KNG-20 |

### 4.12 `statistics`, `telemetry`, `world-analytics`

Player statistics ([plan § 5.1](../../specs/player-statistics/IMPLEMENTATION_PLAN.md)); `/stats settings` (the
privacy menu) works with either value of `enabled`.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `statistics.enabled` | `true` | `false` registers no statistics listener, task or `/afk` | Restart | KNG-34 |
| `statistics.flush-interval-seconds` | `60` | Batches sent this often | Restart | KNG-34 |
| `statistics.max-batch-entries` | `2000` | Entries per batch (the API takes at most 2,000) | Restart | KNG-34 |
| `statistics.spool-directory` / `.replay-interval-seconds` | `statistics-spool` / `60` | Undelivered batches on disk, replayed this often | Restart | KNG-34 |
| `statistics.excluded-game-modes` | `[CREATIVE, SPECTATOR]` | No combat, distance or fall statistics in these modes (playtime still counts) | Restart | KNG-34 |
| `statistics.afk.enabled` | `true` | `false`: every online second is active; no `/afk`, no automatic AFK, no marker | Restart | KNG-34 |
| `statistics.afk.idle-seconds` | `300` | Automatic AFK after this long without activity | Restart | KNG-34 |
| `statistics.afk.command-enabled` / `.tab-list-marker` / `.marker-text` | `true` / `true` / `"&7[AFK]"` | `/afk`, and the tab-list marker and its text | Restart | KNG-34 |
| `statistics.movement.enabled` / `.max-segment-blocks` | `true` / `10.0` | Distance per mode; a longer single move is a relocation, not travel | Restart | KNG-34 |
| `statistics.fall.enabled` | `true` | Highest survived fall | Restart | KNG-34 |
| `statistics.combat.enabled` | `true` | Kills, deaths, damage, arrows, headshots, open-world killstreaks | Restart | KNG-34 |
| `statistics.combat.count-custom-damage` | `false` | Plugin-dealt damage (Chaos procs) would be counted twice; leave off | Restart | KNG-34 |
| `statistics.combat.pve-excluded-spawn-reasons` | `[SPAWNER, SPAWNER_EGG, BREEDING, EGG, DISPENSE_EGG]` | Farmed creatures: killing them is no PvE kill | Restart | KNG-34 |
| `statistics.gates.enabled` / `.fire-attribution` | `true` / `true` | Credit gate-door damage to players, fire to whoever lit each block (gate HP works the same either way) | Restart | KNG-34 |
| `statistics.siege.report-departed-members` | `true` | Report members who left a match early with their stats (still no reward) | Restart | KNG-34 |
| `telemetry.enabled` | `true` | Diagnostic timeline only the owner reads in the web app. Never chat, command arguments, IPs or tokens | Restart | KNG-34 |
| `telemetry.max-buffer-events` | `5000` | Held between flushes; beyond this the oldest are dropped. Never spooled | Restart | KNG-34 |
| `telemetry.flush-interval-seconds` / `.config-poll-seconds` | `10` / `60` | Send interval; how often the owner's choices (enhanced players, test runs) are read | Restart | KNG-34 |
| `telemetry.enhanced-movement-sample-seconds` | `5` | Position sample interval for enhanced players | Restart | KNG-34 |
| `world-analytics.enabled` | `true` | Anonymous heatmaps, menu funnels and domain interactions for `/owner/analytics` | Restart | KNG-34 |
| `world-analytics.movement-sample-seconds` | `10` | One sample per online, non-AFK player this often (at least 10) | Restart | KNG-34 |
| `world-analytics.cell-size` | `16` | Heatmap cell edge in blocks | Restart | KNG-34 |
| `world-analytics.flush-interval-seconds` | `300` | Posted this often, never across the API's statistics midnight | Restart | KNG-34 |
| `world-analytics.movement` / `.menu-funnels` / `.domain-interactions` | `true` / `true` / `true` | Part switches | Restart | KNG-34 |
| `world-analytics.excluded-game-modes` | `[CREATIVE, SPECTATOR]` | Not sampled (spectators never are) | Restart | KNG-34 |
| `world-analytics.max-pending-batches` | `12` | Windows kept in memory while the API is unreachable | Restart | KNG-34 |

### 4.13 `siege`

Lobbies, scenarios and the siege configuration are edited in the web app.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `rejoin-window-seconds` | `300` | A member who disconnects at the hub or in a match keeps their place this long and counts as present at the end. `0` = a disconnect is a leave | Restart | #150 |
| `weapons.enabled` | `false` | Siege weapons ([SIEGE_WEAPONS.md](../../specs/siege-minigame/SIEGE_WEAPONS.md)). `false`: nothing of the feature is registered and matches and world tasks behave as before. `true`: the plugin handles the weapon spot form's `SiegeWeaponSpot` world task ("Send to Minecraft" on Min X, claimed with `/knk task <code>`), which reads a WorldEdit selection or WorldGuard region and fills the form's bounds, facing, size class and region (phase 2; with `false` such a task is failed as having no handler); later phases add placement and firing behind the same switch. Leave `false` on live servers until the [smoke test](../siege-weapons-smoke-test.md) has been run | Restart | [#783](https://github.com/PandiO/knk-workspace/issues/783), [#799](https://github.com/PandiO/knk-workspace/issues/799) |

### 4.14 `lore`, `menus`, `crossplay`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `lore.max-width` | `40` | Lore lines wider than this many visible characters wrap between words, keeping their colour (blueprint items and every menu). At least 10 | Restart | #212 |
| `menus.bedrock-transition-delay-ticks` | `3` | Bedrock (Floodgate) players: a menu-to-menu click closes the menu first and opens the next this many ticks later, so Geyser's late close doesn't close the new one. `0` = off; at most 20. Java players are never delayed | Restart | Bedrock menus |
| `menus.menu-item.enabled` | `true` | An inventory item that opens `/menu`, for console and Bedrock players. It never drops, can't be stored or placed | Restart | #160 |
| `menus.menu-item.give-to` | `all` | `all`, or `bedrock` (Floodgate players only) | Restart | #160 |
| `menus.menu-item.give-on-join` / `.keep-on-death` | `true` / `true` | Put it back at every join when missing; give it back at respawn | Restart | #160 |
| `menus.menu-item.material` / `.name` / `.lore` | `NETHER_STAR` / (text) / (1 line) | Its look | Restart | #160 |
| `menus.menu-item.slot` | `8` | 0–8 hotbar (8 = right-most), 9–35 main inventory. A player's own item there is moved; with a full inventory nothing is given | Restart | #160 |
| `menus.menu-item.open-on` | `[RIGHT_CLICK, LEFT_CLICK, INVENTORY_CLICK]` | What opens the menu. `INVENTORY_CLICK` only works while `movable` is `false` | Restart | #160 |
| `menus.menu-item.droppable` / `.movable` | `false` / `false` | Allow dropping it (gone until the next join or respawn) or moving it in the own inventory | Restart | #160 |
| `crossplay.block-resync.enabled` | `true` | Bedrock ghost blocks: a refused break is sent to the player again while they keep swinging. Needs Floodgate | Restart | #161 |
| `crossplay.block-resync.all-players` | `false` | Also for Java players (only for testing) | Restart | #161 |
| `crossplay.block-resync.window-ticks` / `.interval-ticks` | `30` / `5` | Resend every interval while swinging, and once more this window after the last swing | Restart | #161 |

### 4.15 `navigation`

Road navigation ([design § 4](../../specs/navigation/DESIGN.md)); road materials live in the API's road profiles.
Every key has a default, and the defaults are tuned from live tests: change them only with a reason.

The route mode words of `/navigate` (`shortest`, `efficient`, `preferred`, off-road phase 4,
[#707](https://github.com/PandiO/knk-workspace/issues/707)) add no key: they use `class-cost` (in `efficient` and
`preferred`), the walk costs of `walk:` (in `efficient` and `preferred`) and the road profiles' and edges' cost
multipliers (in `preferred`, the default); who may type a word is the nodes `knk.navigate.mode.<word>`
([commands](../users/commands.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | `/navigate` on or off | Restart | KNG-27 |
| `class-cost` | `{ Main: 0.9, Road: 1.0, Path: 1.15 }` | Routing cost per road class; lower is preferred | Restart | KNG-27 |
| `overlay-materials` | `[SNOW, "*_CARPET", "*_PRESSURE_PLATE", RAIL, POWERED_RAIL, LEAF_LITTER, PINK_PETALS]` | Thin blocks that may lie on a road; `*_SUFFIX` patterns allowed | Restart | KNG-27 |
| `seed-from-domains` | `true` | Domain locations within 8 blocks of a road seed the build | Restart | KNG-27 |
| `max-snap-distance` | `48` | A destination (and, without walk paths, the player) must be this close to a road; a closer target is walked to directly | Restart | KNG-27 |
| `snap-vertical-weight` / `destination-snap-vertical-weight` | `4` / `1` | How much a block of height counts when snapping the player / a destination | Restart | KNG-27 |
| `max-start-distance` | `96` | With walk paths: how far the player may be from a road | Restart | KNG-51 |
| `max-destination-distance` / `destination-walk-range` | `256` / `96` | With walk paths: how far a destination may be from a road, and within which range of the road's end the last leg is walked | Restart | KNG-51 |
| `trail-length` / `trail-period-ticks` / `trail-particle` / `trail-color` | `30` / `10` / `DUST` / `"#E8C66A"` | The particle trail | Restart | KNG-27 |
| `reroute-distance` / `reroute-after-ticks` | `8` / `40` | Reroute when the player strays this far for this long | Restart | KNG-27 |
| `arrive-distance` / `max-session-minutes` | `4` / `30` | Arrival distance; the longest navigation session | Restart | KNG-27 |
| `sprint-speed` | `5.6` | Blocks per second for the ETA | Restart | KNG-27 |
| `survey.sample-period-ticks` / `.cross-section-half-width` / `.breadcrumb-seed-spacing` | `4` / `7` / `32` | `/knk road survey` sampling | Restart | KNG-27 |
| `builder.tile-size` / `.tile-margin` / `.max-cells-per-tile` | `512` / `32` / `250000` | Graph build tiles | Restart | KNG-27 |
| `builder.snapshot-chunks-per-tick` | `4` | Chunks captured per tick on the main thread during a build (fewer under lag) | Restart | KNG-27 |
| `builder.junction-cluster-radius` / `.min-spur-length` / `.ambiguous-reach` | `3` / `4` / `3` | Junction merging, short spur removal, reach of ambiguous materials (cobblestone, planks) | Restart | KNG-27 |
| `builder.plaza-growth` | `2` | Cells a plaza reaches beyond its wide core | Restart | KNG-27 |
| `builder.locked-node-reach` | `8.0` | An admin-locked node absorbs rebuilt junctions and dead ends this close | Restart | KNG-27 |
| `builder.auto-plazas` | `true` | Wide road areas become plazas on their own; `false` = only designed plazas (`/knk road node plaza`) | Restart | KNG-27 |
| `builder.curated-tiles` | `true` | A rebuild of a built tile only proposes changes (`/knk road proposal`); `false` uploads directly (kill switch) | Restart | KNG-27 |
| `walk.enabled` | `true` | Walkable last-mile paths ([design § 9](../../specs/navigation/LAST_MILE_PATHFINDING.md)); `false` = straight lines (kill switch) | Restart | KNG-51 |
| `walk.max-expansions` / `.max-length-factor` / `.max-length` | `20000` / `1.75` / `144` | Search size and the longest path relative to the straight distance | Restart | KNG-51 |
| `walk.detour-allowance` / `.climb-allowance` | `48` / `5` | Blocks a path may always add; blocks per block of height | Restart | KNG-51 |
| `walk.max-drop` / `.drop-penalty` | `3` / `10` | Deepest drop (3 = no fall damage) and its extra cost per block | Restart | KNG-51 |
| `walk.capture-margin` / `.chunk-ttl-seconds` | `16` / `10` | Blocks captured around the box (loaded chunks only); how long a captured chunk is reused | Restart | KNG-51 |
| `walk.recompute-distance` / `.max-concurrent-searches` | `6` / `2` | Recompute after straying this far; searches at once, server-wide | Restart | KNG-51 |
| `walk.climbables` / `.wall-cost` | `[LADDER]` / `1.0` | Materials climbed like a ladder; extra cost beside a wall (0 = hug walls) | Restart | KNG-51 |
| `guidance-v2` | `false` | Off-road trail-quality pass. Phase 6.1: walk paths keep `walk.wall-clearance` from walls, are shaped off the main thread and drawn with checked curves. Phase 6.2: walk-trail particles on fixed anchors; the trail, the HUD distance and the maneuver ahead follow the player back along the route; a player off the road walks to the join point with the least remaining cost; a walk leg stays while the player is within `walk.recompute-distance` of it (no "heading away"). `false` = walk paths, the search and the trail exactly as before (kill switch). Keep `false` until the live test ([off-road smoke test § 8](../navigation-offroad-smoke-test.md#8-phase-61-walk-trail-corners-710-tier3)) signs it off (and [§ 9](../navigation-offroad-smoke-test.md#9-phase-62-anchored-particles-and-winding-back-711-tier3) for phase 6.2) | Restart | [#710](https://github.com/PandiO/knk-workspace/issues/710), [#711](https://github.com/PandiO/knk-workspace/issues/711) |
| `walk.clearance-cost` / `.wall-clearance` | `5` / `0.8` | With `guidance-v2`: extra cost per block of clearance a step lacks to `wall-clearance`, in place of `wall-cost` (0 = keep `wall-cost`); the clearance the trail keeps from walls, posts and drops where there is room (0.35 to 2) | Restart | [#710](https://github.com/PandiO/knk-workspace/issues/710) |
| `walk.curve` | `true` | With `guidance-v2`: corners of the shaped walk trail drawn as curves checked against the walls (`false` = straight pieces) | Restart | [#710](https://github.com/PandiO/knk-workspace/issues/710) |
| `trail-leg-spacing` | `2.0` | Blocks between a walk trail's particles (0.5 to 16; 2.0 since off-road F3, the developer's choice in the live test of 2026-11-19; 3.0 before). With `guidance-v2`: the fixed anchors, counted from the walk path's start. Since off-road F2 ([#771](https://github.com/PandiO/knk-workspace/issues/771) item 3) also the spacing of the walk trail with `guidance-v2: false`. 3.0 gives the sparser trail of before; 1.5 a denser one | Restart | [#711](https://github.com/PandiO/knk-workspace/issues/711), [#771](https://github.com/PandiO/knk-workspace/issues/771) |
| `cursor-jump` | `12` | With `guidance-v2`: how far along the route the player's place may move in one tick; a place farther along (the other pass of a loop, the other arm of a switchback) is taken only when the player is more than `reroute-distance` from the stretch they were on | Restart | [#711](https://github.com/PandiO/knk-workspace/issues/711) |
| `plaza-lines` | `false` | Off-road phase 7: where a route enters a plaza on one road and leaves on another, the road trail is drawn along a rounded line from road to road, pulled towards the plaza node and checked against walls, objects, regions and floor (an A* line round an obstacle when the curve does not fit). Plazas only: a designed plaza, or a junction whose open floor is wider than `npc.navigation.corridor-half-width` (`npc.navigation.plaza-corridor-blocks` caps the radius). Only the drawn trail changes: route length, ETA, HUD and maneuvers never change. `/knk road plazaline` shows the lines to staff, on or off. `false` = today's trail ([off-road smoke test § 10.2](../navigation-offroad-smoke-test.md#102-step-2-the-trail-draws-the-plaza-lines)) | Restart | [#712](https://github.com/PandiO/knk-workspace/issues/712) |
| `plaza-pull` / `plaza-guide-cost` / `plaza-curve-clearance` | `0.35` / `2` / `0.65` | How far the curve's middle is pulled from the straight entry-to-exit line towards the plaza node (0 = the straight line with rounded ends, 1 = through the node; 0 to 1); the A* fallback's cost per block it strays from the curve (0 or more); the least clearance in blocks the curve keeps from a wall or object to be taken (0.35 to 2; a player is 0.6 wide; the developer's 0.65, O33); under it the A* line is drawn, which keeps `walk.wall-clearance` where it can, never under 0.35 | Restart | [#712](https://github.com/PandiO/knk-workspace/issues/712) |
| `walk-links` | `false` | Off-road navigation phase 2 ([design § 5.1, § 5.2](../../specs/navigation-offroad/DESIGN.md)): `true` lets a road route leave the road for a walk path between two road nodes (a courtyard shortcut, drawn in the walk-leg colour, "Leave the road and walk across") where the road between them is much longer, and turns on the road-first rule below. Links are searched off the main thread with the player's walk access after the first route (one at a time beside the walk legs, at most `walk-link-searches-per-route` per route), cached per player, judged by the player's gate and region rules at every route, and dropped within a second when blocks change within a block of them. Needs `walk.enabled: true`. Read at start-up. `false` = routes, trails and sessions exactly as before. Leave `false` on live servers until the [off-road smoke test § 3](../navigation-offroad-smoke-test.md#3-phase-2-walk-links-and-mixed-routes-705-tier3) has passed | Restart | [#705](https://github.com/PandiO/knk-workspace/issues/705) |
| `walk-link-range` / `walk-link-ratio` | `40` / `2.0` | With `walk-links`: a link joins two road junctions (or end points) at most this many blocks apart in a straight line (2 to 128) whose road is more than this times as long (above 1); the developer's O28, tuned in the live test | Restart | [#705](https://github.com/PandiO/knk-workspace/issues/705) |
| `walk-link-ttl-seconds` / `walk-link-retry-seconds` | `600` / `600` | With `walk-links`: a found link is kept this long unless blocks change near it (the block-change hook drops it at once; WorldEdit edits are only caught by this time); "no link" is kept this long, or until a gate or access rule changes (at least 1 each) | Restart | [#705](https://github.com/PandiO/knk-workspace/issues/705) |
| `walk-link-searches-per-route` | `4` | With `walk-links`: the most link searches one route asks for, the most promising first (0 to 32; 0 = links found earlier are still used, no new ones are searched) | Restart | [#705](https://github.com/PandiO/knk-workspace/issues/705) |
| `road-first-share` / `road-first-max-ratio` | `0.6` / `1.5` | With `walk-links`, the road-first rule (the developer's wish of 2026-11-18): a target within `max-snap-distance` (one walk path today) is reached over the road instead when the road carries at least this part of the way (0 to 1) and the whole way (the walks to and from the road estimated at 1.5 times their straight distance) is at most this times the walk path (at least 1). Agent defaults for the developer to confirm in the live test. `max-snap-distance` itself is not changed | Restart | [#705](https://github.com/PandiO/knk-workspace/issues/705) |
| `road-goal-reachable` | `false` | Off-road fix link F2 ([#780](https://github.com/PandiO/knk-workspace/issues/780) option (b), [#771](https://github.com/PandiO/knk-workspace/issues/771) item 4): `true` chooses a point destination's road goal (where the road part of a route ends and the last walk leg starts) by walk reachability instead of the straight-line nearest road point. Up to `road-goal-candidates` road points (one per road edge, within `max-snap-distance` of the destination, nearest first, today's point among them) are each searched on foot to the destination within the `walk:` limits, one search at a time off the main thread; among the reached ones the least road length plus `road-goal-walk-weight` times walk length wins (F3: the walk weighs above the road, so the road carries the route as far as it usefully goes; the candidates also include the road's nodes onward from today's point within `max-snap-distance`). Every choice writes one INFO line with each candidate's road and walk lengths. The first route is today's; the chosen one replaces it once the searches answer (usually within a second or two). None reached: today's point. Fixes the keep storage hall (today's goal is a dead end in the keep stair house) and the road overshoot before a walk leg. NPC road plans are not affected. `max-snap-distance` itself is not changed | Restart | [#780](https://github.com/PandiO/knk-workspace/issues/780) |
| `road-goal-candidates` | `12` | With `road-goal-reachable`: the most road points searched per navigation (1 to 32); each costs one walk search | Restart | [#780](https://github.com/PandiO/knk-workspace/issues/780) |
| `road-goal-walk-weight` | `4.0` | Off-road fix link F3 (smoke test of 2026-11-19, [#780](https://github.com/PandiO/knk-workspace/issues/780), [#771](https://github.com/PandiO/knk-workspace/issues/771) items 4 and 5): with `road-goal-reachable`, a candidate's score is its road length plus this many times its walk length, the least winning; a block walked counts this many blocks of road, so the walk starts as late as the road usefully carries the route (1 to 100; 1 is F2's road plus walk, which stopped the road at the Keep Garrison's exit on the way to the Keep Tower Roof) | Restart | [#780](https://github.com/PandiO/knk-workspace/issues/780) |
| `road-to-its-end` | `false` | Off-road fix link F2 ([#771](https://github.com/PandiO/knk-workspace/issues/771) item 5): `true` keeps a road route the player follows when the road network is swapped (live edge tags, a rebuild) while the player is within `max-snap-distance` of the destination; the last walk leg then starts at the road's end. `false` (today): such a swap switches to direct mode, a walk leg from where the player stands, partway along the road | Restart | [#771](https://github.com/PandiO/knk-workspace/issues/771) |
| `walk.max-chunks-per-request` | `64` | A walk leg whose capture box covers more chunks gets no walk path (1 to 1024). Keep 64; raise it on a test server only, to measure long legs ([off-road smoke test § 1](../navigation-offroad-smoke-test.md#1-phase-0-measurements-703-tier1)) | Restart | [#703](https://github.com/PandiO/knk-workspace/issues/703) |
| `destinations.stale-after-days` | `14` | Destination engine ([design § 7.3](../../specs/navigation-destination-engine/DESIGN.md)): the navigation model (domain places, Locations, compass settings) is kept in `offline/navigation-model.json` in the plugin folder and loaded at start-up, so navigation can work with the API down after a restart. A model older than this many days adds "may be out of date" to the destination lists (at least 1). Nothing reads the model before phase 3 (#69, behind `navigation.destination-engine`); the file is written from phase 2 on and holds no player data | Restart | [#103](https://github.com/PandiO/knk-workspace/issues/103) |
| `destination-engine` | `false` | Destination engine phase 3 ([design § 9, E17](../../specs/navigation-destination-engine/DESIGN.md)): `true` makes `/navigate`, its tab completion and the navigation compass use one list per player from the navigation model above (`type:name` and the `spawn`/`region` words also work in a siege match; nothing is looked up when a destination is chosen, so it works with the API down after a restart), starts routes only from that list, and reads the road-access answers ("Ignored" domains) and the compass settings from the model. `false` keeps today's paths exactly. Read at start-up (`/knk reload` does not switch it). Leave `false` on live servers until the developer has run the [smoke test § 3 and § 4](../navigation-destination-engine-smoke-test.md#3-phase-3-switch-over-behind-the-flag-69-tier3) with it on; removed in phase 4b ([#747](https://github.com/PandiO/knk-workspace/issues/747)) | Restart | [#69](https://github.com/PandiO/knk-workspace/issues/69) |
| `landmarks` | `false` | Off-road navigation phase 5.1 ([design § 6](../../specs/navigation-offroad/DESIGN.md)): `true` loads the landmarks staff made in the web app or with `/knk landmark` (`api/landmarks`) into the navigation model (its `landmarks` section, kept in `offline/navigation-model.json`), offers them to `/navigate`, its tab completion and the compass as `landmark:<name>` (only while `destination-engine` is `true` as well; hidden in a siege match and in other worlds), and turns `/knk landmark` on. `false`: nothing about landmarks runs and `/knk landmark` says it is off. Read at start-up. Leave `false` on live servers until the [off-road smoke test § 6.3](../navigation-offroad-smoke-test.md#63-in-game-step-b-a12-to-a14) has passed | Restart | [#708](https://github.com/PandiO/knk-workspace/issues/708) |
| `preference-max` | `4.0` | Off-road navigation phase 5.2 ([design § 5.4.3](../../specs/navigation-offroad/DESIGN.md)), only with `landmarks: true`: in the `preferred` route mode (the default; `shortest` and `efficient` ignore it) a landmark with an extent (region or radius) and a `Preference` other than 1.0 multiplies the walk cost of every cell inside it, so a walk leg avoids an area above 1.0 and prefers one below. Overlapping landmarks multiply; the product is capped at this value, and at its inverse the other way (4.0: between 0.25 and 4), so one bad overlap cannot block a hall. A value below 1.0 or not a number is read as 4.0. Read at start-up. See the [off-road smoke test § 7](../navigation-offroad-smoke-test.md#7-phase-52-landmark-preference-weights-709-tier2) | Restart | [#709](https://github.com/PandiO/knk-workspace/issues/709) |

### 4.16 `currency`

The limits that matter (amounts, daily caps, who may send) are in the API's currency policy
([payments design § 3.6](../../specs/currency-payments/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `client-cooldown-seconds` | `3` | Pause between two `/pay` of one player before even asking the API | Restart | Currency phase 3 |
| `baltop-page-size` | `10` | Lines per `/baltop` page (at most 50) | Restart | Currency phase 3 |
| `transactions-page-size` | `8` | Lines per `/transactions` and `/knk user <player> history` page (at most 50) | Restart | Currency phase 3 |

### 4.17 `gates`

Gate mechanics are in the [gate structures admin guide](gate-structures-admin-guide.md). Under `gates:` the plugin
reads only the keys below. **`gates.cleaving` was removed by #259:** Cleaving's gate bonus, charged strike and
strike cooldown are combat values now (web app: Enchantment definitions → Cleaving → Combat values). Delete an old
block.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `here.radius` | `15` | `/gate toggle here`, `/gatedoor repair here`: doors within this many blocks | Restart | KNG-78 |
| `here.ambiguity` | `prompt` | Several in range: `prompt` lists them as clickable lines, `nearest` picks the closest | Restart | KNG-78 |
| `lookat.enabled` / `.max-distance` | `true` / `12` | Without a target, `/gate`/`/gatedoor` commands use the door you look at (then `here`) | Restart | KNG-79 |
| `state-sync-interval-seconds` | `120` | Safety-net push of every gate's state (also pushed after each animation and at shutdown). Also persists fire damage | Restart | — |
| `display-cleanup-interval-seconds` | `60` | Scan for orphaned or duplicate gate info displays | Restart | — |
| `safety.door-suffocation-damage` | `false` | Moving doors push entities out of the way; `true` adds vanilla suffocation damage on top (decision for review) | Restart | KNG-106 |
| `fire-duration-seconds` | `8` | How long a door block set alight burns | Restart | — |
| `fire-damage-per-tick` | `2.0` | HP damage per burning block per fire tick (several blocks stack) | Restart | — |
| `fire-tick-interval-seconds` | `1` | Seconds between fire ticks | Restart | — |
| `damage-cracks.enabled` | `true` | Vanilla breaking cracks in 10 stages that follow the gate's HP (visual only) | Restart | Gate damage visuals (2026-10-22) |
| `melee-damage.from-held-item` | `true` | A hit on a door does the held item's attack damage plus Sharpness (empty hand 1); `false` = a flat 10 | Restart | Gate damage visuals |
| `melee-damage.multiplier` | `1.0` | Scales that item damage | Restart | Gate damage visuals |
| `fire-aspect.ignite-chance-per-level` | `0.15` | Fire Aspect chance per level to set a hit door block alight (I 15 %, II 30 %). `0` = off. Defenders never burn their own gate | Restart | Siege playtest 2026-10-24 |
| `area-enchantment-radius-blocks` | `5.0` | Chaos and Flash Chaos hurt every gate with a door block within this many blocks of the user. Their gate **damage** is a combat value (#223) | Restart | #223 |
| `passthrough-instant-open-radius-blocks` | `1` | InstantOpen pass-through removes the door blocks this close to the player | Restart | — |
| `passthrough-instant-open-timeout-seconds` | `5` | They come back after this, if the player doesn't cross | Restart | — |
| `siege.defender-pass-through` | `true` | In a siege lockdown the owning alliance right-clicks to open and the gate closes by itself; `false` = right-clicks toggle | Restart | #154 |
| `siege.defender-pass-through-seconds` | `0` | How long it stays open; `0` = the gate's own pass-through duration | Restart | #154 |
| `rotationGapFill.rasterization-enabled` | `true` | Kill switch for filling diagonal-hinge rotation gates' sparse open footprint | Restart | — |
| `rotation.keyframes-enabled` | `true` | Drawbridge keyframes (KNG-193); `false` = the old per-block rotation | Restart | KNG-193 |
| `world-sync.health-check-interval-seconds` / `.health-check-batch-size` | `300` / `15` | Periodic re-check of a small batch of loaded gates against the database | Restart | — |

### 4.18 `messages`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `prefix` | `"&8[&6KnK&8] &r"` | Prefix of plugin messages | Restart | — |
| `account-created` / `account-linked` / `duplicate-account` | (text) | Account flow messages (`account-linked` is read but shown nowhere; the in-game link notice is `admission.account-linked` § 4.5, a game-first registration's is `web-account-registered` below) | Restart | — |
| `web-account-registered` | `"&aYour website account is ready and linked to this Minecraft account.\n&aLog in at &e{url} &awith &e{maskedEmail} &aor your Minecraft name &e{name}&a.\n&cNot you? Tell staff right away."` | Shown once after a game-first registration (registered on the website with the `/account link` code): within seconds when online (realtime push or the notification poll), else about 2 s after the next join. Placeholders `{maskedEmail}`, `{name}` (the Minecraft name), `{url}` (`web.public-url`; lines with it are dropped while that is empty). A missing key uses the jar's text. An Account-page link or a claim shows `admission.account-linked` instead | Restart | [#485](https://github.com/PandiO/knk-workspace/issues/485) |
| `link-code-generated` | (text) | `/account link`. Placeholders `{code}`, `{minutes}`, `{url}`; lines with `{url}` are dropped while `web.public-url` is empty. Take the current default from the jar: an older file keeps its old text | Restart | KNG-208 |
| `link-code-entered-in-game` | (text) | `/account link <code>`: codes go on the website | Restart | KNG-208 |
| `invalid-link-code` | (text) | Invalid or expired code | Restart | — |
| `merge-complete` | (text) | `{coins}`, `{gems}`, `{exp}` | Restart | — |
| `currency.*` | `pay-sent`, `pay-received`, `pay-confirm`, `pay-insufficient`, `pay-cap`, `pay-new-account`, `pay-not-transferable`, `pay-self`, `pay-unknown`, `balance-self` | The most visible `/pay` and `/balance` texts. Any key left out uses the built-in text (`CurrencySettings.DEFAULT_MESSAGES`), so this list can be shorter | Restart | Currency phase 3 |

### 4.19 `enchant-books`

The v1 grade level cap (KNG-6, [GRADE_DROPCHANCE](../../specs/items/GRADE_DROPCHANCE.md)): an item of grade G takes
an enchantment only up to `maxLevel / divisor(G)`. The divisors are per-grade fields in the web app.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `grade-cap.enabled` | `true` | `false` = no cap | Restart | KNG-6 |
| `grade-cap.apply-to-custom` | `false` | v1 never capped custom enchantments; `true` caps them too | Restart | KNG-6 |
| `grade-cap.ungraded-stars` | `1` | Grade assumed for items without one (1 = most capped; 0 = uncapped) | Restart | KNG-6 |
| `grade-cap.bonus-level-chance` | `0.20` | Chance (0.0–1.0) of one bonus level, within the cap (v1's exact odds: 0.21) | Restart | KNG-6 |
| `grade-cap.grade-refresh-minutes` | `10` | How often the divisors are re-read from the API (at least 1) | Restart | KNG-6 |

### 4.20 `custom-enchantments`

Chance, cooldown, duration, level multiplier and the other numbers per enchantment are **combat values in the web
app** ([combat values guide](custom-enchantment-combat-values-admin-guide.md)). This section holds the runtime
switches and texts. The `messages` and `death-messages` keys are read every time they are used, so `/ce reload`
applies an edit; the other keys need a restart.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `disable-for-creative` | `false` | `true`: custom enchantments don't trigger in creative mode | Restart | — |
| `cooldown-message` | `"&c%seconds% seconds remaining"` | Shown when an ability is on cooldown. `%seconds%`; blank = this default | Restart | — |
| `tuning-refresh-minutes` | `5` | How often combat values are re-read from the API (at least 1; also at `/ce reload`). While the API is down the last values stay | Restart | #151 |
| `death-messages.enabled` | `true` | The death message of a player killed by Chaos or Flash Chaos names the ability, its user and item. Only a death inside the ability's own hit; other deaths keep vanilla's text; a siege match still shows none | `/ce reload` | #222 |
| `death-messages.default` | `"%victim% was killed with %enchantment% by %player% using %item%"` | The pattern. `%victim%`, `%player%` (the user), `%enchantment%`, `%item%` (shown like vanilla's `using [Sword]` with its hover; ` using %item%` is left out when unknown); `&` colour codes | `/ce reload` | #222 |
| `death-messages.overrides` | `{}` | Optional pattern per enchantment id, e.g. `chaos: "%victim% was blown apart by %player%'s %enchantment% using %item%"` (ids: `chaos`, `flash_chaos`) | `/ce reload` | #222 |
| `messages.cmd-help-header`, `cmd-unknown`, `cmd-no-permission`, `cmd-player-only`, `cmd-hand`, `cmd-hand-target`, `cmd-invalid-level` | (text) | `/ce` command texts | `/ce reload` | — |
| `messages.cmd-usage-add` / `-remove` / `-info` / `-cooldown` | (text) | Usage lines | `/ce reload` | — |
| `messages.cmd-unknown-enchantment`, `cmd-add-success`, `cmd-add-level`, `cmd-remove-success`, `cmd-player-not-found`, `cmd-clear` | (text) | Results. `%enchantment%`, `%lvl%`, `%player%` | `/ce reload` | — |
| `messages.cmd-reload` | (text) | `/ce reload` reply. Without the key the code's shorter `"&aPlugin configuration was reloaded."` is shown (#307) | `/ce reload` | — |
| `messages.cmd-info-header` / `cmd-info-line` / `cmd-info-none` | (text) | `/ce info`. Line: `%name%`, `%level%`, `%id%`, `%cooldown%` | `/ce reload` | — |
| `messages.cmd-info-tuning` | `"&8   chance %chance%%, duration %duration%s, cooldown %cooldownSetting%"` | `/ce info`: combat values at the item's level, under every enchantment | `/ce reload` | #151 |
| `messages.cmd-info-tuning-effects` | `"&8   effect level %effectLevel%, second effect %secondDuration%s"` | Only for an enchantment with an effect level or a second effect (Flash Chaos: Slowness level, Nausea) | `/ce reload` | #201 |
| `messages.cmd-info-tuning-gate` | `"&8   gate hits +%gateBonus%%, charged strike %strike%x, strike cooldown %strikeCooldown%"` | Only under Cleaving: gate bonus, charged strike multiplier and strike cooldown at the item's level. `%strikeCooldown%` is `Ns`, or `off` when the cooldown is 0 or turned off | `/ce reload` | #259 |
| `messages.cmd-info-tuning-area` | `"&8   area damage %areaDamage% within %damageRadius% blocks, gates %gateDamage%, knockback within %effectRadius% blocks"` | Only for Chaos and Flash Chaos: area damage, gate damage and radii at the item's level | `/ce reload` | #223 |
| `messages.ench-use` | `"&cYou cannot use %enchantment%."` | `/ce add` refusal when the sender may not use that enchantment | `/ce reload` | — |

In `config.yml` at `121030f` the `# PandiO/knk-workspace#223` comment sits above `cmd-info-tuning-gate`, not above
`cmd-info-tuning-area`. The keys are right; the comment move is tracked in
[#307](https://github.com/PandiO/knk-workspace/issues/307).

### 4.21 `lootboxes`

Areas, limits, odds, the daily cap and announcements are set in the web app (`/admin/lootboxes`,
[design § 3.4](../../specs/lootboxes/DESIGN.md)). This section is how this server places, shows and opens boxes.
Every key applies after `/knk lootbox reload`; a key left out uses the built-in default. Web-app changes arrive at the
next `runtime-refresh-seconds`, or at once with `realtime.enabled: true` ([economy admin guide § 4](economy-admin-guide.md#4-lootboxes)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | Lootboxes on this server | `/knk lootbox reload` | Lootboxes |
| `server-id` | `"default"` | Sent with every spawn so the drop log shows the server | `/knk lootbox reload` | Lootboxes |
| `runtime-refresh-seconds` | `60` | Runtime config and active boxes re-read from the API | `/knk lootbox reload` | Lootboxes |
| `scheduler-tick-seconds` | `20` | How often each area is considered (its own interval still applies) | `/knk lootbox reload` | Lootboxes |
| `claim-max-distance` | `5` | Blocks between the player and the box | `/knk lootbox reload` | Lootboxes |
| `full-inventory` | `refuse` | `refuse` (no claim with a full inventory) or `drop-owned` (claim, drop leftovers owner-locked) | `/knk lootbox reload` | Lootboxes |
| `staff-mode-can-claim` | `false` | Players in `/staffmode` or `/ownermode` can't open boxes | `/knk lootbox reload` | Lootboxes |
| `surface.max-attempts-per-tick` | `4` | Random columns tried per area per try | `/knk lootbox reload` | Lootboxes |
| `surface.forbidden-ground` | `[WATER, LAVA, MAGMA_BLOCK, CACTUS, POWDER_SNOW]` | Never placed on these | `/knk lootbox reload` | Lootboxes |
| `display.model` | `token` | `token` (the token item) or `type` (the type's display material from the web app) | `/knk lootbox reload` | Lootboxes |
| `display.label` / `.rotate` | `true` / `true` | Floating label; rotation | `/knk lootbox reload` | Lootboxes |
| `display.particles-radius` | `15` | Gold particles and a chime every 4 s to players this close (0 = off) | `/knk lootbox reload` | Lootboxes |
| `display.grade-colors` | `"1"`–`"10"`: `&9 &9 &b &b &d &6 &6 &c &c &4` | Label colour per grade | `/knk lootbox reload` | Lootboxes |
| `token.material` | `ENDER_CHEST` | Material of token items. An item is a token only by its tag; pick something that isn't a fuel or crafting ingredient | `/knk lootbox reload` | Lootboxes |
| `opening.style` | `wheel` | `wheel` (a slowing reel) or `instant` | `/knk lootbox reload` | Lootboxes |
| `opening.reel-steps` / `.slowest-step-ticks` / `.show-result-ticks` | `32` / `8` / `50` | Reel length, last step delay, how long the result stays | `/knk lootbox reload` | Lootboxes |
| `opening.public-effects` | `true` | Particles and sounds others nearby see and hear | `/knk lootbox reload` | Lootboxes |

### 4.22 `worlds`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `load` | `[]` | Extra worlds loaded at startup, next to the gameplay world. Each entry: `name` (folder; letters, digits, `_`, `-`), `environment` (`normal`, `nether`, `the_end`), `generator` (`default`, `flat`, `void`; keep it the same), `create` (default `false`), `required` (default `true`: while missing, only operators may join). Example: `- { name: hub, environment: normal, generator: void, create: true, required: true }`. KnK never deletes or regenerates a world | Restart | KNG-114 |

### 4.23 `regions`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `temp-retention.days` | `14` | The daily cleanup deletes an unused `tempregion_worldtask_*` region and an orphaned domain sub-region this many days later (at least 1) | Restart | KNG-103, KNG-258 |
| `temp-retention.release-interval-minutes` | `5` | How often the server removes temp regions the API released (deleted draft, region task cancelled, failed or expired after a server held it, session removed by the sweep), with the same "used by a domain or lootbox area" checks, without the age. `0` = off; set `0` while the API has no release route yet (it logs a warning per pass otherwise) | Restart | #269 |
| `global.protection` | `true` | Where only WorldGuard's `__global__` applies, default players can't build, use crafting blocks or break decorations, and explosions break nothing. Doors, gates and storage stay usable. `knk.region.bypass` and ops pass | Any reload | QOL hotfix 2026-10-25 |
| `global.crafting-blocks` | (16 materials, `CRAFTING_TABLE` … `FLETCHING_TABLE`) | The blocked crafting blocks; empty = the built-in list | Restart | QOL hotfix 2026-10-25 |
| `effect-damage.enabled` | `true` | Players inside a domain take no damage from the causes below, unless the region flag `knk-effect-damage` is `allow`, or it is unset and `pvp` is `allow`. Siege members in a match keep the siege's rules | Any reload | #162 |
| `effect-damage.causes` | `[FIRE, FIRE_TICK, LAVA, CAMPFIRE, HOT_FLOOR, POISON, WITHER, MAGIC, DRAGON_BREATH, FREEZE]` | Bukkit `DamageCause` names; empty = this list | Restart | #162 |
| `managed.startup-repair.enabled` | `true` | Re-checks parent, priority and category flags of every Town, District, Structure and Gate region at startup ([managed regions](../../architecture/managed-worldguard-regions.md)) | Restart | — |
| `managed.startup-repair.delay-ticks` / `.attempts` / `.retry-delay-seconds` / `.page-size` | `100` / `3` / `30` / `100` | Wait for WorldGuard, retries while the API starts, rows per request | Restart | — |
| `managed.resource-production-block-break` | `false` | `true` lets anyone break any block in resource production regions (v1 limited it to logs). Leave off until a block filter exists | Restart | — |
| `managed.manage-global-region` | `false` | Apply v1's `__global__` flags. Changes what is buildable across the world | Restart | — |
| `managed.overrides` | `{}` | Per region id: `kind`, `priority`, `flags` (flags only set while absent). Kinds: `town`, `district`, `structure`, `house`, `property`, `resource_production`, `room`, `gate`, `arena`, `battleground` | Restart | — |
| `managed.extra-regions` | `[]` | Regions with no domain (arenas, battlegrounds) that still get a parent, priority and flags: `{ region, kind, parent }` | Restart | — |
| `access.sync.enabled` | `true` | Writes each domain's AllowEntry/AllowExit as WorldGuard flags, enforced also while the API is down (KNG-56) | Restart | KNG-56 |
| `access.sync.delay-ticks` / `.attempts` / `.retry-delay-seconds` | `100` / `3` / `30` | First sync after enable; retries | Restart | KNG-56 |
| `access.sync.interval-minutes` | `5` | Re-sync from the API (0 = only at startup, repair and new regions) | Restart | KNG-56 |
| `access.message-interval-ms` | `2000` | A player is told "You are not allowed to …" at most this often | Restart | KNG-56 |
| `access.chat-quiet-period-ms` | `10000` | The first refusal of an episode also goes to chat (0 = every one) | Restart | KNG-74 |
| `access.action-bar-hold-ms` | `3000` | The `/navigate` arrow isn't drawn over a refusal for this long | Restart | KNG-74 |
| `access.load-guard.enabled` / `.max-refusals-per-second` / `.window-seconds` / `.escalation-window-seconds` | `true` / `20` / `3` / `60` | A refusal rate no honest player reaches: first a teleport to spawn, then a kick if it repeats within the escalation window | Restart | — |

### 4.24 `command-visibility`

Only the `/` suggestions change; every command still checks its own permission. Ops see everything.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `hide-namespaced` | `true` | Hide every `plugin:command` form | Restart | KNG-107 |
| `hide-other-plugins-without-permission` | `true` | Hide other plugins' commands the player can't run or that declare no permission | Restart | KNG-107 |
| `always-show` | `[]` | Labels never hidden by the rule above, e.g. `[rules, discord]` | Restart | KNG-107 |

### 4.25 `offline-cache`

The last account, freeze, staff/owner mode and permission answers, kept in one file so they still apply after a
restart while the API is down. Used only when the API can't be asked; holds no email or balances.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | `false` logs a warning: permissions, freeze and modes don't survive an API outage | Restart | KNG-58 |
| `file` | `offline-security.json` | In the plugin folder | Restart | KNG-58 |
| `identity-max-age-days` | `30` | An account unconfirmed for longer is forgotten (at most 30: the GDPR erasure deadline) | Restart | KNG-58 |
| `permission-max-age-hours` | `72` | An older permission answer counts as "no" | Restart | KNG-58 |
| `verify-after-hours` | `6` | Hourly, accounts not confirmed for this long are re-checked (an erased account is deleted from the file) | Restart | KNG-58 |
| `flush-seconds` | `10` | How often changes are written | Restart | KNG-58 |

### 4.26 `cache`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `ttl-seconds` | `60` | Global time-to-live of cached API responses. Used for most entities (see below) | Restart | — |
| `entities.<entity>.*` | see below | Per entity: `ttl-minutes` (or `ttl-seconds`), `max-ttl-minutes`, `default-policy` (`CACHE_ONLY`, `CACHE_FIRST`, `API_ONLY`, `API_THEN_CACHE_REFRESH`, `STALE_OK`), `allow-stale`, `retry-attempts`, `retry-backoff-ms` | Restart | — |
| `entities.permissions.resolve-from-effective-set` | `true` | Answer permission checks from each player's whole permission set (one call per player per `ttl-seconds`); `false` = one call per node | Restart | KNG-107 |
| `entities.permissions.effective-set-stale-seconds` | `90` | Help, Tab and `/` use the last set this long past its TTL while it reloads; running a command always waits for a fresh set | Restart | KNG-107 |

Entity defaults (`ttl` / `max-ttl`, all `CACHE_FIRST`, `allow-stale: true`, 3 retries, 100 ms backoff unless noted):
`users` 15/60 min; `towns`, `districts`, `domains`, `domainCatalog` 30/240 min; `structures`, `locations` 20/120 min;
`streets`, `minecraftMaterials` 60/480 min; `enchantments`, `itemBlueprints`, `kits`, `grades`, `tags`, `menus`
20/120 min; `siege` 30/240 min with 200 ms backoff; `health` 30/120 **s**, `API_ONLY`, no stale, 2 retries, 50 ms
(KNG-115: a cached "healthy" must not stand in for "reachable now"); `permissions` 30/120 **s**.

The file's own comment (KNG-262) says that for most entities `ttl-minutes` isn't used and the global
`ttl-seconds` applies; `itemBlueprints` does use its own TTL. A web-app edit shows in game after at most that TTL,
or at once after `/knk cache refresh`. Kits are not among the caches `/knk cache refresh` drops: a kit edit shows in the
kits menu after `ttl-seconds`, or at once with `realtime.enabled: true`; claims always read the API.

### 4.27 `npc`

NPC navigation ([implementation plan](../../specs/npc-platform/IMPLEMENTATION_PLAN.md), parent issue
[#358](https://github.com/PandiO/knk-workspace/issues/358)): K&K plans routes, the Citizens plugin moves the NPCs.
Everything is under `npc.navigation`. Off by default; without the Citizens plugin, `/knk npc status` says why it is
off. Route following also needs `navigation.enabled` and `navigation.walk.enabled` (§ 4.15).

Global switches:

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | NPC navigation on or off. Off: nothing runs, `/knk npc` only reports | Restart | #359 |
| `max-plans-in-flight` | `4` | Route and leg plans running at once, server-wide; 1–64 | Restart | #359 |
| `spawns-per-tick` | `2` | NPC spawns per tick at most; 1–20. Twenty player-shaped NPCs spawned in one tick cost a 48.8 ms tick | Restart | #360 |
| `rule-checks-per-tick` | `10` | NPCs whose way ahead and position are checked against the current gate and access rules per tick at most (the recheck, the trespass guard, wake-ups after a gate or access change); 1–200. 200 walking NPCs at `recheck-ticks: 40` need 5 per tick; with too few, checks come later than `recheck-ticks` | Restart | #361 |

Per-NPC settings. The values under `npc.navigation` are the global layer; `worlds.<world>` and
`regions.<WorldGuard region or domain id>` (innermost region wins) override single keys, and `/knk npc status` shows
each value with the layer it came from. A wrong value is reported at startup and skipped. The region layer applies to
NPCs since link L9 ([#668](https://github.com/PandiO/knk-workspace/issues/668)); before, NPC navigation saw no
WorldGuard region.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `pathfinder` | `citizens` | Citizens' path search for local legs and recovery, and for off-road hops when the walk search finds no off-road walk (since #700): `citizens` or `citizens_async` | Restart | #359 |
| `stretch-blocks` | `32` | Blocks of the route handed to the NPC at once; 8–128 | Restart | #359 |
| `hop-blocks` | `16` | Blocks between the hops of a recovery leg, or of an off-road part when the walk search found no walk (one Citizens search each; since #700 off-road starts and ends use the walk search of `navigation.walk` first); 4–48 | Restart | #360 |
| `recheck-ticks` | `40` | Ticks between rechecks of a walking NPC's way ahead against the current gate and access rules; a denied region, a region the NPC stands in and may not leave (since #701) or a closed gate ahead plans the route again. 0 = off: gate and access events still reach the NPCs and the trespass guard still looks every 40 ticks; 0–1200 | Restart | #359, used from #361 |
| `stationary-ticks` | `40` | Ticks in one block before Citizens reports stuck; the first recovery step starts then; 10–1200 (60 before #521) | Restart | #359, #521 |
| `no-progress-ticks` | `40` | Ticks without progress along the route before K&K's watchdog steps in; 20–1200 (60 before #521) | Restart | #359, #521 |
| `max-retries` | `3` | Recovery steps of a stuck NPC before its route is planned again: 1 back-off (walk back along its last footsteps), 2 side-step (one block away from the wall), 3 local leg ahead (one Citizens search to a point ahead on its own floor). Steps that cannot be taken are skipped and not counted; after two replans without getting free the order fails; 0–10 | Restart | #360, #521 |
| `recovery-wait-ticks` | `20` | Ticks between two recovery steps of a stuck NPC (back-off, side-step, local leg, replan); 0–200 | Restart | #521 |
| `corner-clearance` | `1.0` | Blocks an NPC keeps between itself and a wall on the inside of a turn of its route, as far as the road allows; straight stretches may run along a wall unless `corridor-steering` is on; 0–2, 0 = off | Restart | #521 |
| `waypoint-margin` | `0.5` | How close an NPC comes to a route waypoint before it heads for the next one; smaller walks turns through the corner point instead of cutting it (Citizens' own default is 1); 0.2–1.5. A stretch with a doorway that corridor steering lined up is walked with 0.35 | Restart | #521, #622 |
| `corridor-steering` | `false` | Corridor steering (off until the developer has tested it): each stretch of the route line is re-placed in the walkable corridor around it before the NPC walks it: away from walls, posts and drops by `wall-clearance` where the road is wide enough (on straights too), straightened where the corridor allows, and through the middle of doorways and entrances on their axis (a waypoint 1.5 blocks before, one in it, one after). Corner clearance and the other safety steps still run on the shaped line. A stretch's corridor is built once and shared by every NPC on it | Restart | #622 |
| `corridor-half-width` | `4` | Blocks either side of the route line the corridor looks at; 1–8 | Restart | #622 |
| `wall-clearance` | `0.8` | Blocks from the NPC's centre to a wall, post or drop that corridor steering keeps where the road allows (the body's half width is 0.3); narrower places are walked through their middle, so one-block doors stay open; also the preferred margin of `local-legs-clearance`; 0.35–2 | Restart | #622 |
| `local-legs-clearance` | `false` | Clearance-aware local legs (off until the developer has tested it): short trips, a group follower's own leg back to its group and the recovery ladder's local leg are searched by K&K on its own walk grid with the corridor's clearance per cell (the body's width as the hard minimum, so one-block doors stay open; `wall-clearance` as a preferred margin), smoothed into a few straight steps and walked as waypoints. When K&K's search finds nothing within its cell budget, Citizens' own search walks the leg as before. `/knk npc nav stats` counts `local legs: k&k N, engine N, none N` | Restart | #623 |
| `plaza-lines` | `false` | Plaza lines (off until the developer has tested it). The road graph collapses a plaza into one junction, so a route across it runs to the plaza's middle and out again. With this on, where a route passes a plaza junction the corridor widens to the plaza (a designed plaza's radius, or the open floor measured round the junction when it is wider than `corridor-half-width`, ending `wall-clearance` short of its edge) and the NPC walks the straight line from where the route enters the plaza to where it leaves, round wells, stalls and trees with `wall-clearance`, never into a region its line does not pass. A group's path and its leader take the same line, kept the formation's half width plus `wall-clearance` from obstacles. Works with or without `corridor-steering`; the players' trail is unchanged | Restart | #625 |
| `plaza-corridor-blocks` | `16` | The largest plaza radius, in blocks, that `plaza-lines` widens the corridor to; 4–32 | Restart | #625 |
| `crowd-awareness` | `false` | Crowd awareness (off until the developer has tested it). Narrow places on an NPC's way (a door, an arch, a passage under 2 blocks wide) are taken in turns: one direction at a time, an NPC already in it first, then first come. The others wait in a queue a block apart before it, a block to the side of the line, so the way out stays free; a group's leader keeps its turn until its followers are through. Two NPCs that meet head-on in a narrow place: the second to enter steps back out and waits. Waiting behind another NPC, in a queue or stepping aside counts as waiting, not as being stuck, and recovery steps never end on a cell where another NPC stands. `/knk npc nav stats` shows `crowd: waits N, yields N, longest queue N` | Restart | #626 |
| `no-route-wait-ticks` | `100` | Ticks an NPC waits before asking again while the rules allow no route or the way ahead is not loaded; 20–6000. An NPC waiting at a closed gate or a district edge is woken by the gate or access change itself; this is the fallback | Restart | #360 |
| `walk-only-blocks` | `64` | With an end too far from a road: the longest trip walked off-road (with the walk search since #700, in hops when it finds nothing); further, the order fails; 0–256 (0 = never) | Restart | #360, #700 |
| `road-goal-reachable` | `false` | A point destination off the road: the road goal is chosen as for players with `navigation.road-goal-reachable` (#780). Today's goal, the nearest point of each road edge within `navigation.max-snap-distance` of the destination and the road's nodes onward (at most 12) each get a road route and one walk search with the NPC's access; the least road plus `road-goal-walk-weight` times walk wins and the order keeps it for its replans. None reached: today's goal, as before. A group takes its leader's choice. Needs `navigation.walk.enabled`. Off until tested | Restart | #814 |
| `road-goal-walk-weight` | `4.0` | With `road-goal-reachable`: a block walked counts as this many blocks of road (the players' `navigation.road-goal-walk-weight` default); 1–100 | Restart | #814 |
| `stop-on-trespass` | `false` | The trespass guard always logs and counts an NPC that entered a region its current rules deny, or (since #701) left a region it may not leave (`TRESPASS <npc> entered <region> …` or `… left <region> …`). `true`: also stop that NPC and plan its route again; for dev servers | Restart | #361, #701 |
| `collidable` | `false` | Whether NPCs have bodies: they push and block each other, or walk through everything (`false`). With it on, players never move an NPC unless `players-push-npcs` is on (each NPC is exempt from every player's collision through Paper's per-entity collidable exemptions; no scoreboard team is touched), and push resistance runs: a displacement the NPC's own walk doesn't explain (a body, an attack's knockback, water, a piston) is detected, counted and logged with who did it, and the NPC walks back to its line or post; queue spots never stand on a cell next to a drop of 3 blocks or more. A real client still feels a slight nudge from an NPC's body; the NPC doesn't move. `/knk npc nav stats` shows `pushes: N (players N, attacks N), returned N, exempted N (now N), teleported N` | Restart | #359, #627 |
| `players-push-npcs` | `false` | With `collidable` on: whether players' bodies push NPCs too. `true`: players bump NPCs, a pushed NPC walks back, and a player who keeps pushing one (below) stops colliding with it for a while, at once when the push goes towards a drop | Restart | #627 |
| `push-return` | `true` | With `collidable` on: a pushed or knocked-back NPC walks back to its line or post: straight back where that is a straight walk, else along its own footsteps, else a local leg (K&K's search with `local-legs-clearance`, else Citizens'), last a teleport home. Another NPC's jostle on its way, in a queue or at its goal is the crowd's business (no walk back) unless it goes towards a drop; an NPC standing at its post is walked back when another NPC moves it a block or more; a group's follower is left to its group | Restart | #627 |
| `push-exempt-after` | `3` | With `players-push-npcs` on: pushes by one player within `push-exempt-window-ticks` before that player stops colliding with that NPC for `push-exempt-ticks`; 1–20 | Restart | #627 |
| `push-exempt-window-ticks` | `200` | The window in which `push-exempt-after` pushes count; 20–6000 | Restart | #627 |
| `push-exempt-ticks` | `1200` | How long a player who kept pushing an NPC stops colliding with it; 20–72000 | Restart | #627 |
| `push-teleport-ticks` | `600` | Ticks a pushed NPC may take to walk back before it teleports home, and only while no player (within 64 blocks with a line of sight) sees it where it stands or where it goes; 0 = never; 0–12000 | Restart | #627 |
| `chunk-loading` | `load` | Outside player-loaded areas: `load` or `simulate` (read now, used in Phase 7b) | Restart | #359 |
| `group-formation` | `column` | The formation of a group of NPCs (a leader plans the route once, the followers walk it in slots): `column` (single file), `ranks` (rows behind the leader), `cluster` (a loose crowd, 3 abreast) or `escort-ring` (an octagon around the leader, then wider rings). Where the road is too narrow a formation narrows before it folds: `ranks` one fewer abreast at a time down to 2, a `cluster` 3 then 2, the `escort-ring` rows of 3 with the leader in the middle of the second row, then 2 abreast; only where 2 abreast do not fit (a gate, stairs, a wall walk) the group walks as a column, and it takes up the widest width that fits again after | Restart | #377, #522 |
| `group-spacing` | `1.5` | Blocks between the rows of a formation and between NPCs in a column; 1–8 (was 2.0 and also the gap in a row before #522) | Restart | #377, #522 |
| `group-lateral-spacing` | `1.0` | Blocks between neighbours in a row of a group's formation (1 = shoulder to shoulder); 1–8. 3 abreast need a road 1 + 2 × this wide, rounded down to whole blocks (3 at 1.0 and 1.25, 4 at 1.5); the escort ring's first ring has a radius of 1.25 × this | Restart | #522 |
| `group-ranks-width` | `2` | NPCs per row in the `ranks` formation (2 = pairs), its widest width; it narrows one by one down to 2 before it folds into a column; 2–8 | Restart | #377, #522 |
| `group-width-hysteresis-blocks` | `3` | A group changes to a narrower width (still 2 abreast or more) or a wider one only when it lasts this many blocks along the path; with `group-formation-keeping: levels` a column at a gate or a stair is taken at once, with `elastic` the column needs it too (shorter tight places are passed by merging lanes); 0–16 | Restart | #522, #624 |
| `group-formation-keeping` | `levels` | How a group keeps its formation (off until the developer has tested it). `levels`: fixed widths as above. `elastic`: the width is fitted from the free width across the path (walls, drops and regions the group's access rules deny end it); neighbours squeeze to `group-lateral-spacing-min` and the rows close up to `group-spacing-min` before the group narrows; it decides its width `group-lookahead-blocks` past its depth ahead of the leader; every width change, the column included, needs the tight place to last `group-width-hysteresis-blocks`, and shorter ones are passed with the lanes merged (counted as `merges` in `/knk npc nav stats` with their reason); the column only where 2 abreast squeezed don't fit; stairs as wide as the flight allows when each lane has its own steps; followers get the new slots by their place on every width change; the outer lanes keep `wall-clearance` from a wall where the road allows | Restart | #624 |
| `group-lateral-spacing-min` | `0.6` | Blocks between neighbours in a row that an `elastic` formation squeezes to before it narrows (0.6 = the body's width, shoulders touch). 3 abreast then fit a 2-wide road (2 × 0.6 + 2 × 0.35 = 1.9), 2 abreast a road 1.3 wide; 0.5–8 | Restart | #624 |
| `group-spacing-min` | `1.0` | Blocks between the rows that an `elastic` formation closes up to while it is squeezed (the body's depth plus 0.4), and the gap in its column; 0.6–8 | Restart | #624 |
| `group-lookahead-blocks` | `4` | Blocks an `elastic` formation looks ahead of its leader past its own depth when it decides its width (the decided "depth + 4"), so it starts squeezing or narrowing before the tight place; 0–32 | Restart | #624 |
| `group-followers-finish-trip` | `false` | When the leader has arrived and the group turns back, followers still on their way (held at a gate or a district edge, behind) finish their trip to the goal first and then rejoin the group (couriers); `false`: they follow the leader at once | Restart | #522 |
| `group-rejoin-blocks` | `4.0` | A follower further than this from its lane plans its own leg back to the group's path (one local leg, never the whole route). A follower without progress for `no-progress-ticks` takes the recovery steps first (back-off, side-step), then its own leg back to a point ahead of it on its own floor; 2–16 | Restart | #377, #521 |
| `group-regroup-blocks` | `24.0` | The leader waits when a follower is this many blocks behind its slot, until the group has closed up to half of it (30 seconds at most); 0–256, 0 = the leader never waits | Restart | #377 |
| `group-catch-up-speed` | `1.3` | Walking speed, as a factor, of a follower that is behind its slot; 1–2, 1 = followers never walk faster | Restart | #377 |

`collidable` stays `false` by default after #627: with bodies on, NPCs walking a 1-wide flight next to a drop can shove
each other off it (the #491 stair corner scene, `npc-ledge-corner`), which push resistance cannot undo; see
[implementation plan 4c.4 item 7.4.10](../../specs/npc-platform/IMPLEMENTATION_PLAN.md) for what is still missing. Turn it
on per world or region where NPCs don't walk such places, after the developer test there. What each movement key does on a server, and the stats lines they add: [NPC navigation admin guide](npc-navigation-admin-guide.md).

The `group-*` keys are per-NPC settings like the others, but a group takes them once, for its leader: a world, a
region, an NPC template or an assignment can give groups their own formation and toggle.
`/knk npc nav group <n> [formation] [profile] [finish-trip|follow-leader]` starts a test group; `finish-trip` or
`follow-leader` sets `group-followers-finish-trip` for that group (the assignment layer).

Access profiles, `access-profiles.<id>` (until NPCs have their own permissions). `default` always exists. NPCs never
pass a closed gate.

| Key | Default | What it does | Applies | Added by |
|---|---|---|---|---|
| `bypass-domain-rules` | `false` | Ignore every domain's entry and exit rule | Restart | #360 |
| `open-doors` | `true` | May open hand-openable doors on off-road legs | Restart | #360 |
| `allow-regions` | `[]` | WorldGuard region ids the NPC may enter and leave whatever the domain says | Restart | #360 |
| `deny-regions` | `[]` | Region ids the NPC never enters (wins over `allow-regions`) | Restart | #360 |

The block to paste (the Phase 1 keys with the Phase 2, 3 and 4 additions; Phase 4, #377, adds the six `group-*`
lines; #521 adds `recovery-wait-ticks`, `corner-clearance` and `waypoint-margin` and sets `stationary-ticks` and
`no-progress-ticks` to 40; #522 adds `group-lateral-spacing`, `group-width-hysteresis-blocks` and
`group-followers-finish-trip` and sets `group-spacing` to 1.5; #622 adds `corridor-steering`,
`corridor-half-width` and `wall-clearance`; #623 adds `local-legs-clearance`; #624 adds `group-formation-keeping`,
`group-lateral-spacing-min`, `group-spacing-min` and `group-lookahead-blocks`; #625 adds `plaza-lines` and
`plaza-corridor-blocks`; #626 adds `crowd-awareness`; #627 adds `players-push-npcs`,
`push-return`, `push-exempt-after`, `push-exempt-window-ticks`, `push-exempt-ticks` and `push-teleport-ticks`):

```yaml
npc:
  navigation:
    enabled: false
    max-plans-in-flight: 4
    spawns-per-tick: 2
    rule-checks-per-tick: 10
    pathfinder: citizens
    stretch-blocks: 32
    hop-blocks: 16
    recheck-ticks: 40
    stationary-ticks: 40
    no-progress-ticks: 40
    max-retries: 3
    recovery-wait-ticks: 20
    corner-clearance: 1.0
    waypoint-margin: 0.5
    corridor-steering: false
    corridor-half-width: 4
    wall-clearance: 0.8
    local-legs-clearance: false
    plaza-lines: false
    plaza-corridor-blocks: 16
    crowd-awareness: false
    no-route-wait-ticks: 100
    walk-only-blocks: 64
    road-goal-reachable: false
    road-goal-walk-weight: 4.0
    stop-on-trespass: false
    collidable: false
    players-push-npcs: false
    push-return: true
    push-exempt-after: 3
    push-exempt-window-ticks: 200
    push-exempt-ticks: 1200
    push-teleport-ticks: 600
    chunk-loading: load
    group-formation: column
    group-spacing: 1.5
    group-lateral-spacing: 1.0
    group-ranks-width: 2
    group-width-hysteresis-blocks: 3
    group-formation-keeping: levels
    group-lateral-spacing-min: 0.6
    group-spacing-min: 1.0
    group-lookahead-blocks: 4
    group-followers-finish-trip: false
    group-rejoin-blocks: 4.0
    group-regroup-blocks: 24.0
    group-catch-up-speed: 1.3
    worlds: {}
    regions: {}
    access-profiles:
      default:
        bypass-domain-rules: false
        open-doors: true
        allow-regions: []
        deny-regions: []
```

### 4.28 `testing`

In-plugin test scenarios ([#421](https://github.com/PandiO/knk-workspace/issues/421);
[writing a plugin scenario](../developer/plugin-scenarios.md)). **Test servers only:** the CI boot test and a
developer's throwaway server. Keep it off on dev worlds with builds, the alpha and production; a server without the
block is off, so there is nothing to merge at a deploy.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `scenarios.enabled` | `false` | `true` registers `/knk scenario list \| run <name\|all>` (node `knk.admin.scenario`) and logs a warning at startup. `false`: no command, nothing changes | Restart | #421 |
| `scenarios.world` | `""` | World the scenes are built in; blank = the main world | Restart | #421 |
| `scenarios.origin.x`, `.y`, `.z` | `30000`, `100`, `30000` | Lowest corner of the first scene. Each scene is a 32 × 24 × 32 box that is **cleared to air** before and after its scenario; scene *n* sits 64 × *n* blocks further along x. Pick a place far from anything built; `y` + 24 must fit in the world's height | Restart | #421 |

```yaml
testing:
  scenarios:
    enabled: false
    world: ""
    origin:
      x: 30000
      y: 100
      z: 30000
```

### 4.29 `map`

Overview map in the web app ([design](../../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md) § 7, [smoke test § 1](../overview-map-smoke-test.md#1-phase-1-region-outlines-735-tier3),
[#732](https://github.com/PandiO/knk-workspace/issues/732)). Off by default: with `reporting.enabled: false` the plugin
reads and sends nothing for the map and behaves as before. The reports travel over the game hub, so they also need
`realtime.enabled: true` (§ 4.3); with realtime off the plugin logs a warning and sends nothing. The block sits between
`regions` and `command-visibility` in the file.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `reporting.enabled` | `false` | `true` sends the outline (2D points, min and max Y) of every Town, District, Structure and Gate region to the API, which keeps them in `map_region_outlines`: after every managed-region repair (startup, `/knk regions repair`), after a world task's region is renamed or redefined (the old name is removed), and again on every game hub (re)connect | Restart | #735 |
| `reporting.interval-ticks` | `40` | With `reporting.enabled: true`, every this many ticks (40 = 2 s; 10 to 1200, values outside are clamped) the plugin also sends each online player's world, position, facing, AFK state, active mode and running minigame match to the API (`ReportMapPlayers`). The API decides who may see whom: players in staff or owner mode or in a running match never reach anonymous or plain logged-in viewers. The snapshot runs on the main thread (one pass over the online players, timed as `map.player_snapshot` in the metrics), the send off it | Restart | #738 |

```yaml
map:
  reporting:
    enabled: false
    interval-ticks: 40       # live player report interval (40 ticks = 2 s; 10..1200)
```

### 4.30 `items`

Item identity ([PandiO/knk-workspace#141](https://github.com/PandiO/knk-workspace/issues/141),
[production DESIGN § 8](../../specs/production-storage-transport/DESIGN.md#8-item-identity-note-9)): every item a
player obtains resolves to one item blueprint, in this order: the `knightsandkings:knk_item_instance` tag (unique
items), the `knightsandkings:knk_blueprint` tag, the material's vanilla match from knk-web-api
(`GET api/ItemIdentity/material-map`, generated "Uncurated" shadows until curated). Items that don't resolve
(custom-named, custom-lored, another plugin's data) are logged once and left alone. A plain vanilla item never carries
a blueprint tag, so stacking stays exactly vanilla's. With both switches `false` nothing of this runs.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `identity.enabled` | `false` | Load the material map, stamp `knk_blueprint` on blueprint items that differ from the plain vanilla item (kits, lootboxes, `/knk itemblueprints give`), send the conversion counts | Restart | #141 |
| `identity.convert-on-obtain` | `false` | The conversion hooks: pickup, block and mob drops, fishing, crafting, trades, the first open of a container block since the start. Resolve, count, remove a stale blueprint tag from an otherwise plain item. Needs `identity.enabled` | Restart | #141 |
| `identity.map-refresh-minutes` | `10` | How often the material map is fetched again (never per event); at least 1 | Restart | #141 |
| `identity.report-interval-minutes` | `10` | How often the counts go to `POST api/ItemIdentity/conversion-counts` and a summary line to the log; at least 1 | Restart | #141 |

```yaml
items:
  identity:
    enabled: false
    convert-on-obtain: false
    map-refresh-minutes: 10
    report-interval-minutes: 10
```

### 4.31 `production`

The production, storage and transport feature ([PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22),
flag G16) and, since [#689](https://github.com/PandiO/knk-workspace/issues/689), territory
([territory DESIGN § 1-4](../../specs/territory/DESIGN.md)). With `enabled: false` nothing of the feature runs (A21):
no cache, no listener, no report, no realtime handler, and crown land regions are not managed. `/knk territory` then
answers that territory is off. How staff set territory up and use it: [territory admin guide](territory-admin-guide.md).

Since [#677](https://github.com/PandiO/knk-workspace/issues/677) (P2c, no new key) the switch also covers the world side
of production phase P2: the region kinds of production structures and warehouses, rural structure regions without a
parent (PvP allowed, no town flags), and the territory lookup the API's `InsideTerritory` placement rule calls on the
region HTTP server (`region-http`, plugin key). While it is off the lookup answers HTTP 503 ("territory unavailable",
shown as "not checked" in the API) and the repair treats these structures as before.

With `enabled: true` the plugin reads `GET api/Territory/inputs` (every district and crown land with its holder, rank
and range, already computed by the API) a few seconds after start, reads those regions' shapes from WorldGuard, and
builds the territory chunk cache: a chunk wholly owned by one holder (or contested by two) is one entry, a chunk a
border crosses is **split** and kept per block column. It rebuilds on the realtime event `TerritoryChanged` (also after
a hub reconnect), every `refresh-minutes`, and on `/knk territory rebuild`; it skips the rebuild when the inputs'
`version` and the region shapes are unchanged. Players' territory is looked up on every chunk crossing (per block in a
split chunk). After a rebuild the plugin sends one full report per world (`PUT api/Territory/report`: equal-rank
overlaps and flagged structures) when `report` is on and the API's `Production:Enabled` is on.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | The production feature flag (plugin side of G16). Territory, and every later production link, runs only with it on. Also adds crown land regions (domain type `CrownLand`) to the managed-region repair (kind `CROWN_LAND`, no parent, priority 10). Since #677 also: production structures get the region kind `RESOURCE_PRODUCTION` and warehouses `STRUCTURE`; rural structures (no district) get a region with no parent at priority 30; the region HTTP server answers the territory lookup (`/api/territory/contains-region/{regionId}`, `/api/territory/contains-location`; 503 while off) | Restart | #689, #677 |
| `territory.refresh-minutes` | `10` | How often the inputs and region shapes are read again besides the `TerritoryChanged` event, so a region redrawn in place is picked up; `0` = only on the event and `/knk territory rebuild` | Restart | #689 |
| `territory.notify-players` | `true` | An action bar line when a player enters or leaves territory or contested land (`messages`) | Restart | #689 |
| `territory.report` | `true` | Send the conflict report after each rebuild. The API also needs `Production:Enabled`, else it refuses (409, logged); `/knk territory status` shows the last result | Restart | #689 |
| `territory.map-outlines` | `false` | Send territory outlines over the game hub (`ReportTerritoryOutlines`) for the overview map. Leave off until the API and the map bridge accept them ([#802](https://github.com/PandiO/knk-workspace/issues/802)); also needs `realtime.enabled` | Restart | #689 |
| `territory.max-chunks-per-world` | `500000` | Safety limit of the cache per world; a district or crown land that would pass it is left out and logged. A range of 300 blocks takes about 1,300 chunks | Restart | #689 |
| `territory.messages.enter-town` | `&7Entering the territory of &f{name}` | Action bar on entering a town's territory; `{name}` the town | Restart | #689 |
| `territory.messages.enter-crown-land` | `&7Entering the crown land of &f{name}` | On entering crown land; `{name}` the kingdom | Restart | #689 |
| `territory.messages.enter-contested` | `&6Entering contested land: &f{holders}` | On entering contested land; `{holders}` the contesting towns or kingdoms, `/`-separated | Restart | #689 |
| `territory.messages.enter-wilderness` | `&7Leaving &f{name}&7: wilderness` | On leaving all territory; `{name}` the holder left (or "contested land") | Restart | #689 |

```yaml
production:
  enabled: false
  territory:
    refresh-minutes: 10
    notify-players: true
    report: true
    map-outlines: false
    max-chunks-per-world: 500000
    messages:
      enter-town: "&7Entering the territory of &f{name}"
      enter-crown-land: "&7Entering the crown land of &f{name}"
      enter-contested: "&6Entering contested land: &f{holders}"
      enter-wilderness: "&7Leaving &f{name}&7: wilderness"
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

Command: `/knk territory here|status|rebuild`, node `knk.admin.world.territory` (in `knk.admin.*` and
`knk.admin.world.*`).

Since [#679](https://github.com/PandiO/knk-workspace/issues/679) (P4b, yield-area surveys) the switch also runs the
surveys: the plugin reads the API's survey queue (`GET api/ProductionAreas/survey-due`; requested areas first, then
never surveyed, then a day old; `Configured` structures never), counts what each area holds (trees by species and size,
rock and ores, crops, flowers, water per biome, pasture animals) from chunk snapshots and reports it
(`POST api/ProductionAreas/{id}/surveys`). Snapshots are taken on the main thread within `chunks-per-tick` (timed as
`production.survey.capture` in the metrics); counting and reporting run on their own thread. Block breaks and places in
an area ask for a `NotableChange` survey after `notable-change-blocks`. Also the `CaptureRadius` world task. Commands:
`/knk production survey <structure> [area]|survey status|area show <structure> [area] [seconds]`, node
`knk.admin.world.production` (in `knk.admin.*` and `knk.admin.world.*`).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `surveys.poll-minutes` | `5` | How often the survey queue is read; `0` = only on `/knk production survey` and after a notable change | Restart | #679 |
| `surveys.batch` | `20` | Queue items read per poll (1-200) | Restart | #679 |
| `surveys.chunks-per-tick` | `2` | Chunk snapshots per server tick, the main-thread budget (1-64); higher surveys faster at a higher tick cost | Restart | #679 |
| `surveys.max-area-blocks` | `16000000` | An area with more blocks (columns × height) is not surveyed (logged, shown in `/knk production survey status`) | Restart | #679 |
| `surveys.max-area-chunks` | `256` | An area spanning more chunks is not surveyed. A radius of 64 spans about 81 chunks | Restart | #679 |
| `surveys.scheduled-loads-chunks` | `false` | `false`: the daily survey waits until the area's chunks are loaded (P-D2); requested surveys (creation, `/knk production survey`, notable change) always load them, without generating new chunks | Restart | #679 |
| `surveys.notable-change-blocks` | `64` | Block breaks and places in one area that ask the API for a `NotableChange` survey; `0` = off | Restart | #679 |
| `surveys.notable-cooldown-minutes` | `30` | At most one notable-change survey per area this often | Restart | #679 |
| `surveys.areas-refresh-minutes` | `10` | How often the area list is read again (notable-change counters, `area show`) | Restart | #679 |

## 5. Maintaining this page

- A change that adds, renames or removes a key, or changes a default, updates § 2.1 and the section's table in the
  same PR, and lists the YAML to paste in the PR's deploy notes and the changelog's **Admin steps**
  ([documentation maintenance](../developer/DOCUMENTATION_MAINTENANCE.md)).
- Re-check the **Applies** column against the code when a key's reader moves: `ConfigLoader` and code that reads
  `getConfig()` once are Restart; `EnchantmentConfigManager` and `() -> getConfig()…` suppliers are reload-safe.
- Record the knk-plugin commit you checked in the header.

## Changes

1. 2026-11-20: § 4.31 `production.surveys.*` (#679), § 2.1 and § 3 rows; checked against knk-plugin `claude/production-p4b`, not merged into `next` yet
1. 2026-11-20: § 4.27 `npc.navigation.road-goal-reachable` and `road-goal-walk-weight` (#814, NPC follow-ups G1), § 2.1 row; checked against knk-plugin `claude/npc-movement-g1`, not merged into `next` yet
1. 2026-11-20: § 2.1: the `map.reporting.*` rows (#735, #738) on trunk since knk-plugin v0.3 (docs #767)
1. 2026-11-19: § 4.31 `production.enabled` also switches the P2c region kinds, rural structure regions and the territory lookup (#677); no new key; checked against knk-plugin `claude/production-p2c`, not merged into `next` yet
1. 2026-11-19: § 4.15 `navigation.road-goal-reachable`, `road-goal-candidates`, `road-to-its-end` (#780, #771 items 4 and 5), `trail-leg-spacing` also with `guidance-v2` off (#771 item 3), § 2.1 row; checked against knk-plugin `claude/offroad-route-ends-f2`, not merged into `next` yet
1. 2026-11-19: § 4.31 `production` (`enabled`, `territory.refresh-minutes`, `notify-players`, `report`, `map-outlines`, `max-chunks-per-world`, `messages.*`, #689), § 2.1 and § 3 rows; checked against knk-plugin `claude/production-t-b`, not merged into `next` yet
1. 2026-11-19: § 4.30 `items.identity` (`enabled`, `convert-on-obtain`, `map-refresh-minutes`, `report-interval-minutes`, #141), § 2.1 and § 3 rows; checked against knk-plugin `claude/item-identity-141` `a6c5a2bc`; unchanged in the merge into `next` `2ef256e7` (checked 2026-11-19, docs #796). Admin guide: [item identity](item-identity-admin-guide.md)
1. 2026-11-18: § 4.15 `navigation.walk-links`, `walk-link-range`, `walk-link-ratio`, `walk-link-ttl-seconds`, `walk-link-retry-seconds`, `walk-link-searches-per-route`, `road-first-share`, `road-first-max-ratio` (#705), § 2.1 row; checked against knk-plugin `claude/offroad-walk-links` `de44d58b`, not merged into `next` yet
1. 2026-11-18: § 4.15 `navigation.plaza-curve-clearance`, the `plaza-lines` text (#712 step 2), § 2.1 row; checked against knk-plugin `claude/offroad-plaza-lines` `28ad18c5`, not merged into `next` yet
1. 2026-11-18: § 4.29 `map.reporting.interval-ticks` and the live player report (#738), § 2.1 row; checked against knk-plugin `claude/overview-map-players-api`, not merged into `next` yet
1. 2026-11-18: § 4.29 `map.reporting.enabled` (#735), § 2.1 and § 3 rows; checked against knk-plugin `claude/overview-map-outlines`, not merged into `next` yet
1. 2026-11-18: § 4.15 `navigation.plaza-lines`, `plaza-pull`, `plaza-guide-cost` (#712 step 1), § 2.1 row; checked against knk-plugin `claude/offroad-plaza-lines`, not merged into `next` yet
1. 2026-11-16: § 4.27 `npc`: push resistance with `collidable` (default still false), `players-push-npcs`, `push-return`, `push-exempt-after`, `push-exempt-window-ticks`, `push-exempt-ticks`, `push-teleport-ticks` (#627), § 2.1 row; checked against knk-plugin `claude/npc-movement-m7`, not merged into `next` yet
1. 2026-11-16: § 4.27 `npc`: `crowd-awareness` (#626), § 2.1 row (and the #625 row now in `next`); checked against knk-plugin `claude/npc-movement-m4`, not merged into `next` yet
2. 2026-11-16: § 4.27 `npc`: `plaza-lines`, `plaza-corridor-blocks` (#625), § 2.1 row (and the #624 row now in `next`); checked against knk-plugin `claude/npc-movement-m5`, not merged into `next` yet
3. 2026-11-15: § 4.27 `npc`: `group-formation-keeping`, `group-lateral-spacing-min`, `group-spacing-min`, `group-lookahead-blocks` and the `group-width-hysteresis-blocks` text (#624), § 2.1 row (and the #623 row now in `next`); checked against knk-plugin `claude/npc-movement-m3`, not merged into `next` yet
4. 2026-11-15: § 4.27 `npc`: `local-legs-clearance` and the `wall-clearance` text (#623), § 2.1 row (and the #622 row now in `next`); checked against knk-plugin `claude/npc-movement-m6`, not merged into `next` yet
5. 2026-11-15: § 4.27 `npc`: `corridor-steering`, `corridor-half-width`, `wall-clearance`, the `corner-clearance` and `waypoint-margin` texts (#622), § 2.1 row; checked against knk-plugin `claude/npc-movement-m2`, not merged into `next` yet
6. 2026-11-15: § 4.27 `npc`: `group-lateral-spacing`, `group-width-hysteresis-blocks`, `group-followers-finish-trip`, `group-spacing` 2.0 → 1.5, the `group-formation` and `group-ranks-width` texts (#522), § 2.1 row (and the #521 row now in `next`); checked against knk-plugin `claude/npc-followups-l4`, not merged into `next` yet
7. 2026-11-15: § 4.27 `npc`: `corner-clearance`, `waypoint-margin`, `recovery-wait-ticks`, `stationary-ticks` and `no-progress-ticks` 40, `max-retries` and `group-rejoin-blocks` reworded (#521), § 2.1 row; checked against knk-plugin `claude/npc-followups-l3`, not merged into `next` yet
8. 2026-11-14: § 4.28 `testing.scenarios` (#421), § 2.1 and § 3 rows; checked against knk-plugin `next` `309d3580`
9. 2026-11-14: § 4.18 `messages.web-account-registered` (#485), § 2.1 row; checked against knk-plugin `claude/smoke-fixes-484-485-487`, not merged into `next` yet
10. 2026-11-13: § 4.3 `realtime.erasure` (#184) and the regions `temp-retention.release-interval-minutes` (#269), PR into `next` from `claude/plugin-chains-into-next`
11. 2026-11-13: § 4.27 `npc`: six `group-*` keys, PandiO/knk-workspace#377
12. 2026-11-13: § 4.27 `npc`: `rule-checks-per-tick`, `stop-on-trespass`, PandiO/knk-workspace#361
13. 2026-11-13: § 4.27 `npc`, PandiO/knk-workspace#359 and #360; checked against knk-plugin `claude/npc-navigation`, not merged into trunk yet
14. 2026-11-10: first version, PandiO/knk-workspace#295; checked against knk-plugin `main` `121030f`
