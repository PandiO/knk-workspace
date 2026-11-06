# Siege Survival — first live checkpoint (link S5 smoke test)

**Status:** To run (written 2026-11-06 by link S5 of the [Siege Survival chain](../reports/2026-11-03-siege-survival-chain.md)); nothing in it has been run live. One sitting, about 45 minutes.
**Last updated:** 2026-11-06
**Branches under test:** knk-web-api `claude/siege-survival` `f87457b` (phase 1 entities, endpoints, form seeds, migration `20261106071958_AddSiegeSurvivalPhase1`); knk-plugin `claude/siege-survival` **`280da6fe`** (S1–S5). The web app has no survival routes yet (S9), so the scenario is authored with REST calls below.
**Design:** [DESIGN.md](../specs/siege-survival/DESIGN.md) §3, §3a–§3c, §4, §6, §7; plan [§2a](../specs/siege-survival/IMPLEMENTATION_PLAN.md#2a-delivery-order-and-merge-gates-2026-11-03) row S5 (exit: one complete wave, breach and capture on the castle; no NPC-team auto-forfeit). Issues [PandiO/knk-workspace#41](https://github.com/PandiO/knk-workspace/issues/41), [#146](https://github.com/PandiO/knk-workspace/issues/146).
**Also in this sitting:** the S3 PvP regression checklist (6 steps) in the chain report's S3 block, on the same deploy; run it after section 5.

Everything below is about the **dev server** with the **dev seed** (knk-dev-db-seed `4cc1263`): Siege scenario 1 "Cinix under Attack!", lobby 1 `cinix` ("Siege - Cinix"), human team 1 (Defender, blue) with spawn "Main" (location 46), NPC team 2 (Attacker, red) with the attacker spawns South (location 48), North (49), East (50); objectives 1 Throneroom (location 47, **InstantVictory = insta-lose**, no gate), 2 South Gate (gate structure 7, capture location 13), 3 Northern Gate (gate 8, location 18), 4 Keep Stair House (gate 6, location 51); world `world_KNK-DEV`. If your dev database has other ids, read them with `GET api/SiegeScenarios/1` and `GET api/SiegeLobbies` first and adjust the bodies.

## 0. What the castle map must have

- Every objective gate (6, 7, 8) loaded as a gate structure with at least one door that is **closed** at match start (the scenario's `siege_scenario_gates` rows say `CLOSED`, `Damageable`), and a **capture ring** (objective capture location + radius, 2.5–3 blocks in the seed) on the inside of the gate: the mobs stand in front of the closed door, break it, then walk to the ring.
- An outside spawn area reachable on foot from the South Gate's door (no cliff, no water the mobs must swim): the attacker South spawn (location 48, `1484 47 -400`) is the default below. The mobs path with the vanilla pathfinder (follow range 96 blocks): spawn → gate should be well under 96 blocks of walking; if the real route is longer, author a **lane point** halfway (section 2, step 5) or move the zone closer.
- The scenario area (town region `TownWgRegionId` of town 1 and the district regions) exists in WorldGuard: ghosts are confined to it (S60). Without it ghosts are not confined (logged as nothing; see flag S5-14 in the report).
- WorldGuard flags in the area must allow **mob damage to players** and **mob spawning by plugins** (`mob-spawning` only affects natural spawns; `deny-spawn` would block the plugin's spawns too — if no mob appears, check the region flags and the server's `spawn-monsters`/difficulty: Peaceful despawns monsters at once).

## 1. Deploy (10 min)

1. **API**: check out knk-web-api `claude/siege-survival` at `f87457b`, build, then against the dev database:
   ```bash
   dotnet ef database update
   ```
   (adds the 18 `siege_survival_*` tables; nothing existing changes). Start the API. Set `Security:PluginApiKey` as usual; the calls below use it as `X-API-Key` (a staff JWT with `knk.siege.admin.manage` works too: `Authorization: Bearer …`).
2. **Form seeds** (so the web app's generic forms can show the survival rows later; not needed for the checkpoint itself): the 18 seeds import the way the existing ones do, in this order (join entries before the forms that use them):
   ```bash
   API=http://localhost:5294; KEY=<Security:PluginApiKey>
   for s in SurvivalSettingsKit.join SurvivalSpawnZoneObjective.join SiegeSurvivalSettings SurvivalLobbySettings \
            SurvivalDifficultyProfile SurvivalMonsterType SurvivalSpecialWaveProfile SurvivalSpecialWaveMonsterType \
            SurvivalSpecialWaveEntry SurvivalSpawnZone SurvivalSpawnZonePoint SurvivalTargetOverride SurvivalPurchasePoint \
            SurvivalPurchaseOffer SurvivalMysteryBoxPool SurvivalMysteryBoxEntry SurvivalMysteryBoxEntryEnchantment SurvivalMysteryBoxPoint; do
     curl -s -X POST "$API/api/FormConfigurations/seeds/$s/import?makeDefault=true" -H "X-API-Key: $KEY" -H "Content-Length: 0"; echo " <- $s"
   done
   ```
   (`GET $API/api/FormConfigurations/seeds` lists them; an already imported seed writes nothing.)
3. **Plugin**: build knk-plugin `claude/siege-survival` at `280da6fe` (`./gradlew :knk-paper:dev` copies the shaded jar to the dev server; or `./gradlew :knk-paper:shadowJar` and copy `knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar`). No config change is required; the new `siege.survival:` block in `config.yml` has defaults (the server adds nothing to an existing file — the defaults apply when the keys are missing).
4. Start the server. Expected first lines: `Siege Survival runtime initialized (inert until a lobby draws a scenario with survival settings)`; no `[Survival]` warning. `/knk siege survival status` (needs `knk.admin.siege`, a child of `knk.admin`) answers `Survival scenarios known: [] …` until section 2 is done.

## 2. Author the survival scenario without the web app (10 min)

REST calls against the dev API (chosen over an SQL script because the API resolves the defaults, validates the rows and creates the inline locations; an SQL script would have to reproduce the EF conventions of 18 tables). All bodies are complete; `$API`/`$KEY` as above. Each step prints the created row; note the ids where asked.

1. **Survival settings on scenario 1** (human team 1, NPC team 2, min players 1, 10 s intermission, wipe-only end):
   ```bash
   curl -s -X PUT "$API/api/SiegeSurvival/scenarios/1/settings" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "enabled": true, "minPlayers": 1, "humanTeamId": 1, "npcTeamId": 2, "equipmentMode": "OwnInventory",
     "intermissionMillis": 10000, "endWhenAllObjectivesCaptured": false, "favorNearPlayersPercent": 0, "nearZoneCount": 1,
     "stuckAfterMillis": 30000, "lastEnemiesCount": 3, "respawnLimit": 2, "roundBackstopMillis": 300000, "meaningfulDistance": 1.0,
     "matchCurrencyPerKill": 70, "killBonusMultiplier": 1.1 }'
   ```
2. **One difficulty profile** (small, quick rounds for the checkpoint: 4 enemies in round 1, +2 per round, stats +25 % per round, at most 8 alive, one spawn per second; gate damage ×3 so a 500 HP door falls in about 17 hits):
   ```bash
   curl -s -X POST "$API/api/SurvivalDifficultyProfiles" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "siegeScenarioId": 1, "name": "Smoke test", "isDefault": true,
     "countPreset": "Linear", "countBase": 4, "countStep": 2, "countMultiplier": 1.1, "countSwitchRound": 9,
     "statPreset": "Linear", "statStep": 0.25, "statMultiplier": 1.1, "statSwitchRound": 9,
     "healthWeight": 1, "walkingSpeedWeight": 0.3, "meleeDamageWeight": 1, "rangedDamageWeight": 1, "attackSpeedWeight": 0.5,
     "perPlayerFactor": 0.25, "perPlayerAppliesToStats": false, "maxAlive": 8, "statCap": 8, "countCap": 0,
     "repairRatePerSecond": 50, "gateDamageFactor": 3, "captureContributionWeight": 1, "spawnIntervalMillis": 1000 }'
   ```
3. **Monster types** zombie (weight 2) and skeleton (weight 1, from round 2 so round 1 is melee only):
   ```bash
   curl -s -X POST "$API/api/SurvivalMonsterTypes" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d '{ "siegeScenarioId": 1, "entityType": "ZOMBIE", "weight": 2, "unlockRound": 1 }'
   curl -s -X POST "$API/api/SurvivalMonsterTypes" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d '{ "siegeScenarioId": 1, "entityType": "SKELETON", "weight": 1, "unlockRound": 2 }'
   ```
4. **The outside spawnzone** (always active, anchored on the attackers' South spawn, location 48) with **two spawn points**: the South spawn itself and a point 4 blocks east of it (created inline). Note the returned zone `id` (expected 1 on a fresh database):
   ```bash
   curl -s -X POST "$API/api/SurvivalSpawnZones" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "siegeScenarioId": 1, "name": "Outside south", "weight": 1, "anchorLocationId": 48, "areaRadius": null,
     "prerequisitePolicy": "All", "prerequisiteObjectiveIds": [], "minWave": 1, "maxWave": null,
     "forNormalWaves": true, "forSpecialWaves": true, "laneAutoReroute": false }'
   ZONE=1   # the id from the answer
   curl -s -X POST "$API/api/SurvivalSpawnZonePoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalSpawnZoneId\": $ZONE, \"kind\": \"Spawn\", \"sortOrder\": 0, \"name\": \"South spawn\", \"locationId\": 48 }"
   curl -s -X POST "$API/api/SurvivalSpawnZonePoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalSpawnZoneId\": $ZONE, \"kind\": \"Spawn\", \"sortOrder\": 1, \"name\": \"South spawn east\",
              \"location\": { \"name\": \"Survival south spawn east\", \"x\": 1488.2, \"y\": 47, \"z\": -400.5, \"yaw\": 99, \"pitch\": 0, \"world\": \"world_KNK-DEV\" } }"
   ```
   If the terrain 4 blocks east of the South spawn is not standable, stand where the second point should be and capture it with `/knk location here` (it prints the new location id; use `"locationId": <id>` instead of the inline location). The spawner snaps a point to the ground within a few blocks.
5. **Optional lane point** (only if the mobs don't find the gate in section 4: an ordered waypoint halfway between the spawn and the South Gate door, captured in-game):
   ```bash
   curl -s -X POST "$API/api/SurvivalSpawnZonePoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalSpawnZoneId\": $ZONE, \"kind\": \"Lane\", \"sortOrder\": 0, \"name\": \"Lane 1\", \"locationId\": <captured id> }"
   ```
6. **Optional second zone "Courtyard"** (to see the frontier advance after the South Gate objective falls; capture a standable point just inside the South Gate with `/knk location here`):
   ```bash
   curl -s -X POST "$API/api/SurvivalSpawnZones" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "siegeScenarioId": 1, "name": "Courtyard", "weight": 1, "anchorLocationId": <captured id>, "areaRadius": 3,
     "prerequisitePolicy": "All", "prerequisiteObjectiveIds": [2], "minWave": 1, "forNormalWaves": true, "forSpecialWaves": true, "laneAutoReroute": false }'
   ```
7. **Lobby override** (explicit `Inherit`, so the lobby row exists):
   ```bash
   curl -s -X PUT "$API/api/SiegeSurvival/lobbies/1/settings" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{ "allCapturedOverride": "Inherit" }'
   ```
8. **Check readiness and the frozen configuration the plugin will use**:
   ```bash
   curl -s "$API/api/siege-survival/scenarios/1/configuration?lobbyId=1" -H "X-API-Key: $KEY" | python3 -m json.tool | less
   ```
   Expect `"isReady": true`; warnings such as `end.wipe-only` are fine (only a team wipe or the Throneroom's insta-lose flag ends the game). An `errors` entry means the plugin will **not** start the round (the lobby cancels with "no scenario available" and the server log says why).
9. **Tell the plugin**: the plugin learns the survival scenarios at startup and every 5 minutes, so either restart the server now or wait 5 minutes. Then `/knk siege survival status` → `Survival scenarios known: [1]`.

What the admin must author for any survival lobby (follow-up [#265](https://github.com/PandiO/knk-workspace/issues/265)): the scenario must still pass the **PvP** structural readiness to be listed in the lobby's runtime config (both teams with a spawnpoint, `PlayersMin` ≥ 2, objectives with capture locations) — the dev seed does. The survival `minPlayers` (1) then replaces the PvP minimum for that lobby.

## 3. The checkpoint — one player (15 min)

Play in **survival mode** with ordinary gear (own-inventory mode; a bow helps for step 6). Use `/siege admin skip cinix` to shorten the matchmaking.

1. `/siege join cinix` alone. The draw happens with **one** player (PvP would cancel with "not enough players"); the server log has no `[Survival] … not ready` line. At the hub you are on the **Defender** team (blue); nobody is on the attackers.
2. Match start: the title "The siege begins!", then the survival line "Survival: defend Cinix under Attack! against the waves. Wave 1 starts in 10 s" and an action-bar countdown. The scoreboard still shows the PvP "Time left" (it does not run down: flag S5-4). `/knk siege survival status` shows `substate PREPARING`, `active zones [1]`.
3. **Round 1 spawn**: title "Round 1 — 4 enemies"; one zombie per second appears at the South spawn / the east point (both points used), vanilla look, no name tag. `/knk siege survival status` → `round 1 queue 0 alive 4`, `Stats this round: … =1.00` everywhere (round 1 = vanilla, S30), each enemy `APPROACHING -> gate:7`. Zombies do **not** burn in daylight and do not wander off.
4. **Walk to the gate**: the zombies walk to the South Gate's closed door and stop about 1.5 blocks in front of it (`BREACHING -> gate:7` in the status). If they stand still far away with `blocked` in the status, see "If something is off" below.
5. **Breach**: every second each zombie swings and the door loses 30 HP (10 × gate damage factor 3; the door's health display counts down; no player is credited). After about 17 hits the door is destroyed (the ordinary destroyed-door behaviour: blocks gone, no "Gate restored" broadcast). The status now shows the enemies `APPROACHING -> objective:2`.
6. **Capture**: the zombies walk through the opening to the South Gate capture ring and stand there (`CAPTURING -> objective:2`). The capture bar of objective 2 moves at the ordinary rate for 4 attackers; when it completes: the announcement names the **NPC team** ("<Attackers> captured South Gate!", S3-6), the gate opens/transfers as in PvP, and — if you authored the courtyard zone — the chat line "The enemy pushes forward: new spawn zones are active." and `active zones [1, 2]` in the status. **The game continues** (objective 2 is not insta-lose).
7. **Kill the round**: kill the four (they now target you when you come within 12 blocks: `ATTACKING -> player:…`; a zombie hit does vanilla damage). When the last one dies: "Round 1 cleared! Next round in 10 s", `substate INTERMISSION`, `Waves: reached 1, completed 1`.
8. **Round 2 stats**: title "Round 2 — 6 enemies"; `Stats this round: health=1.25 walking_speed=1.08 melee_damage=1.25 ranged_damage=1.25 attack_speed=1.13` (linear step 0.25 with the weights 1 / 0.3 / 1 / 1 / 0.5). A skeleton can appear now (weight 1 of 3): it draws its bow and shoots when you are in sight within 15 blocks; arrows deal 1.25× damage. Log line `[NPC] zombie <uuid> revision …` appears only when a value was clamped (none expected in round 2).
9. **Die once** (let the zombies kill you, or `/kill` yourself during the round): the death message is suppressed, your inventory is kept (S40), you respawn at the Defender spawn as a **ghost**: the chat line "You died. You are a ghost until the next round break …". Verify every ghost rule (§3b): no damage from mobs, lava or falling; hunger does not drop; you cannot break or place blocks, open chests, drop or pick up items, hit a mob, eat, or use items; mobs ignore you (walk past, never attack; `EntityTarget` safety net); arrows pass through you; walking out of the town's WorldGuard region sends you back to the spawn with "Ghosts stay inside the scenario area." Chat works. A second account on the attackers' side would not see you; a teammate sees you translucent (S3; needs a second player, optional). `/knk siege survival status` lists you under `ghosts`.
10. **Respawn at the intermission**: kill the remaining enemies as a ghost? You can't. **This is the team-wipe check instead (step 12)** — so for the respawn check die while a second player is alive, or skip to 12 and run 10–11 on a second match: when the last enemy dies the intermission starts and every ghost is released at once: teleported to a valid spawn, visible and vulnerable again, "Round 2 cleared!".
11. **Stuck handling** (observe during any round): an enemy that makes no progress for 30 s is removed and respawned at the active zone nearest to you (`[Survival] Lobby cinix: stuck STUCK_RESPAWN: enemy #n …` in the log); when the queue is exhausted and at most 3 enemies remain, they **glow** and run straight at you (`stuck GLOW` log lines, `glow` in the status). A second stuck respawn kills the enemy as the system (`RESPAWN_LIMIT_KILL`); 5 minutes after the last spawn everything alive is system-killed (`BACKSTOP_KILL`). System kills never count as player kills (`system n` in the status).
12. **Team wipe**: as the only player, die during a round (step 9). The match ends at once: "Your team was wiped out. Waves reached 2, completed 1.", the PvP result screen announces the attackers (flag S5-5), the ordinary post-match wait at the hub, then the restore: your inventory, the gates (South Gate door back, closed) and the boards exactly as PvP restores them; **no mob remains** anywhere (`/knk siege survival status` → `running survival matches: 0; adopted mobs 0; match actors 0`). The lobby goes to cooldown and matchmaking as usual.
13. **Restart** (S61): start another match, let round 1 spawn, then `stop` the server. On the next start the log shows the Siege abort/restore as for PvP and, if any mob was still in a loaded chunk, `[Survival] Removed n leftover match mobs from the loaded worlds`. Join again: your inventory is restored on join as in PvP.

**If something is off**
- Mobs spawn but don't move / status says `blocked`: the vanilla pathfinder found no route (walls, water, a drop over 3 blocks, more than 96 blocks). Add a lane point (section 2, step 5) or move the zone; `siege.survival.follow-range` can be raised in `config.yml`.
- Mobs stand in front of the door but the door takes no damage: the gate is not locked to this lobby or the mobs aren't registered actors (`match actors 0` in the status) — check the server log for `[Survival]` spawn lines and whether the gate structure is in the scenario's gates (`siege_scenario_gates`).
- Mobs don't spawn at all: the log line `[Survival] Lobby cinix: enemy n (ZOMBIE) not spawned: …` says why (world not loaded, zone unusable, WorldGuard deny-spawn, Peaceful difficulty).
- The lobby cancels at the draw with "no scenario available": the survival readiness has errors — section 2 step 8.

## 4. What to watch in the server log

`[Survival] Lobby cinix:` lines: `match started: scenario 1, difficulty Smoke test, 1 players, active zones [1]`; `round n started: k planned, max alive 8, stats …, players 1`; `round n completed; g ghosts respawned; record WaveRecord[reached=n, completed=n]`; `objective 2 captured by team 2: zones activated [2], deactivated []`; `stuck STUCK_RESPAWN|GLOW|RESPAWN_LIMIT_KILL|BACKSTOP_KILL: enemy #n round r at x y z target … respawns k`; `enemy #n system-killed: …`; `ending: TEAM_WIPE, record …, k spawns cancelled`; `survival match over: TEAM_WIPE, waves …`. `[NPC]` lines report clamped stats once per revision (expected from about round 6 when the speed hits the 0.5 cap). `[Siege]` lines are the ordinary ones; `match ended: TEAM_ELIMINATED -> LAST_ALLIANCE_STANDING (alliance 2)` is the expected PvP record of a survival loss (flag S5-5). Nothing should be logged at WARNING/SEVERE mentioning `Survival`, `NPC`, `visibility` or `MatchActor`.

## 5. Nothing changed for PvP (5 min)

Run the S3 regression checklist (chain report, S3 block, 6 steps) with two players on a scenario **without** survival settings, or on scenario 1 after `DELETE $API/api/SiegeSurvival/scenarios/1/settings` plus a restart: two teams again, the match ends on time, rejoin window and team-elimination work as before, no `[Survival]` line in the log.

## 6. Flags that need a decision after the test

From the chain report's S5 block (`S5-1` …): the targeting defaults (aggro 12, leash 24, commitment 4 s, margin 25 %, gate preference 0.9), the vanilla-pathfinder-only navigation of v1 (no WalkSearch/road legs yet), the gate-door reachability heuristic, the PvP result and rewards recorded for a survival loss until S8, the constant "Time left" on the PvP scoreboard, ghosts and the siege scoreboard team collision rule (not yet NEVER), `perPlayerAppliesToStats` folded into one `survival:round` source, and the 5-minute cache refresh (vs an explicit reload).
