# Siege Survival — economy, kits and Mystery Box checkpoint (link S7b smoke test)

**Status:** To run (written 2026-11-07 by link S7b of the [Siege Survival chain](../reports/2026-11-03-siege-survival-chain.md)); nothing in it has been run live. One sitting, about 30 minutes; it **continues** the [S5 smoke test](siege-survival-smoke-test.md) on the same deploy and the same authored scenario.
**Last updated:** 2026-11-07
**Branches under test:** knk-web-api `claude/siege-survival` **`df3e546`** (phase 1 + the S7a Mystery Box roll endpoint; both migrations `20261106071958_AddSiegeSurvivalPhase1` and `20261107095043_AddSiegeSurvivalMysteryBoxRolls`; the 18 form seeds); knk-plugin `claude/siege-survival` **`18a6001`** (S1–S5, S7a api-client, S7b). The web app has no survival routes yet (S9), so everything is authored with REST calls.
**Design:** [DESIGN.md](../specs/siege-survival/DESIGN.md) §8, §8a, §8b, §11; decisions S20, S23, S33–S36, S38–S40, S44, S45, S57–S59; plan [§2a](../specs/siege-survival/IMPLEMENTATION_PLAN.md#2a-delivery-order-and-merge-gates-2026-11-03) row S7. Issue [PandiO/knk-workspace#41](https://github.com/PandiO/knk-workspace/issues/41).
**Before this:** the S5 checklist's sections 0–2 are done on this database (survival settings on scenario 1, the "Smoke test" difficulty profile, monster types, the outside spawnzone) and at least one S5 match has run. `$API`, `$KEY` as in S5 section 1. A **second player** makes the transfer, the "teammate cannot claim" and the "teammate can pick up" checks possible; everything else is one player.

## 1. Deploy (5 min)

1. **API** at `df3e546`: `dotnet ef database update` (adds `siege_survival_mystery_box_rolls` and `siege_survival_mystery_box_deliveries`; nothing existing changes), start it. The roll endpoints need the plugin key or `knk.siege.admin.manage` (S7a-5).
2. **Plugin** at `18a6001` (`./gradlew :knk-paper:dev`, or `shadowJar` and copy the jar). No config change is required; the new key `siege.survival.mystery-box.reel-max-step-ticks` (default 8 ticks for the slowest reel step) applies when missing.
3. Start the server. Expected: `Siege Survival runtime initialized …` as before and **no** `Siege Survival phase 4 (kits, shops, Mystery Box) is off` warning (it appears only when the item-blueprint/material data access failed to start, i.e. the API was down at startup). `/knk siege survival status` → `… economy services installed` is not printed; the line ends with `match ground items tracked for []`.

## 2. Author the economy on scenario 1 (10 min)

Pick the ids first:
```bash
curl -s "$API/api/Kits?pageSize=50" -H "X-API-Key: $KEY" | python3 -m json.tool | grep -E '"id"|"name"'       # two kits: K1 (default), K2
curl -s "$API/api/ItemBlueprints?pageSize=50" -H "X-API-Key: $KEY" | python3 -m json.tool | grep -E '"id"|"name"'   # B1 a weapon (bow/sword), B2 a stackable (arrows/bread), B3 for the box
curl -s "$API/api/EnchantmentDefinitions?pageSize=50" -H "X-API-Key: $KEY" | python3 -m json.tool | grep -E '"id"|"key"|"isCustom"'  # E1, E2: two **vanilla** definitions (isCustom false, e.g. minecraft:power, minecraft:unbreaking)
```
Every kit must exist (readiness `equipment.*`); a custom enchantment on a book entry only gives a labelled book (flag S7b-7).

1. **Kits mode with two kits and a default** (replaces the S5 settings body; everything else as in S5 step 1):
   ```bash
   curl -s -X PUT "$API/api/SiegeSurvival/scenarios/1/settings" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "enabled": true, "minPlayers": 1, "humanTeamId": 1, "npcTeamId": 2, "equipmentMode": "Kits",
     "selectedKitIds": [K1, K2], "defaultKitId": K1, "baselineLoadoutKitId": null,
     "intermissionMillis": 10000, "endWhenAllObjectivesCaptured": false, "favorNearPlayersPercent": 0, "nearZoneCount": 1,
     "stuckAfterMillis": 30000, "lastEnemiesCount": 3, "respawnLimit": 2, "roundBackstopMillis": 300000, "meaningfulDistance": 1.0,
     "matchCurrencyPerKill": 70, "killBonusMultiplier": 1.1 }'
   ```
   `GET $API/api/SiegeSurvival/scenarios/1/settings` echoes the stored shape: if the kit fields are named differently there (the S4 join is `SurvivalSettingsKit`), use those names.
2. **A purchase point with two offers** at a block next to the Defender spawn (stand on the block the players will right-click and capture it with `/knk location here`, or send it inline; the point's **block** is the one at the location's integer coordinates, `interactionRange` is the reach in blocks):
   ```bash
   curl -s -X POST "$API/api/SurvivalPurchasePoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" -d '{
     "siegeScenarioId": 1, "name": "Armory", "sortOrder": 0, "interactionRange": 4,
     "location": { "name": "Survival armory", "x": <x>, "y": <y>, "z": <z>, "yaw": 0, "pitch": 0, "world": "world_KNK-DEV" } }'
   POINT=<id from the answer>
   curl -s -X POST "$API/api/SurvivalPurchaseOffers" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalPurchasePointId\": $POINT, \"itemBlueprintId\": B1, \"quantity\": 1, \"price\": 60, \"sortOrder\": 0 }"
   curl -s -X POST "$API/api/SurvivalPurchaseOffers" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalPurchasePointId\": $POINT, \"itemBlueprintId\": B2, \"quantity\": 70, \"price\": 40, \"sortOrder\": 1 }"
   ```
   (70 of a 64-stackable: the second stack of 6 shows the split and, with a full inventory, the match-scoped drop.)
3. **Two Mystery Box pools, exactly 100 % each** (S59; 60.49 % + 40 % is refused by readiness `box.total` and by the roll with 409 `PoolInvalid`):
   ```bash
   curl -s -X POST "$API/api/SurvivalMysteryBoxPools" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d '{ "siegeScenarioId": 1, "name": "Weapons", "variant": "Items" }'
   ITEMS=<id>
   curl -s -X POST "$API/api/SurvivalMysteryBoxEntries" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalMysteryBoxPoolId\": $ITEMS, \"sortOrder\": 0, \"itemBlueprintId\": B1, \"chancePercent\": 60,
              \"enchantments\": [ { \"enchantmentDefinitionId\": E1, \"level\": 2, \"chancePercent\": 50 } ] }"
   curl -s -X POST "$API/api/SurvivalMysteryBoxEntries" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalMysteryBoxPoolId\": $ITEMS, \"sortOrder\": 1, \"itemBlueprintId\": B3, \"chancePercent\": 40 }"
   curl -s -X POST "$API/api/SurvivalMysteryBoxPools" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d '{ "siegeScenarioId": 1, "name": "Books", "variant": "EnchantedBooks" }'
   BOOKS=<id>
   curl -s -X POST "$API/api/SurvivalMysteryBoxEntries" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalMysteryBoxPoolId\": $BOOKS, \"sortOrder\": 0, \"enchantmentDefinitionId\": E1, \"enchantmentLevel\": 3, \"chancePercent\": 70 }"
   curl -s -X POST "$API/api/SurvivalMysteryBoxEntries" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"survivalMysteryBoxPoolId\": $BOOKS, \"sortOrder\": 1, \"enchantmentDefinitionId\": E2, \"enchantmentLevel\": 1, \"chancePercent\": 30 }"
   ```
   (If an entry's enchantment list is a separate endpoint on your build, `POST api/SurvivalMysteryBoxEntryEnchantments` with `survivalMysteryBoxEntryId`.)
4. **One box point per variant**: place an **end portal frame** block yourself near the spawn for each (the plugin never places or restores blocks; it only warns when the block differs), stand on it, `/knk location here`, then:
   ```bash
   curl -s -X POST "$API/api/SurvivalMysteryBoxPoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"siegeScenarioId\": 1, \"name\": \"Weapon box\", \"locationId\": <id>, \"interactionRange\": 4, \"blockType\": \"minecraft:end_portal_frame\",
              \"rollPrice\": 100, \"claimTimeoutMillis\": 10000, \"survivalMysteryBoxPoolId\": $ITEMS }"
   curl -s -X POST "$API/api/SurvivalMysteryBoxPoints" -H "X-API-Key: $KEY" -H "Content-Type: application/json" \
        -d "{ \"siegeScenarioId\": 1, \"name\": \"Book box\", \"locationId\": <id>, \"interactionRange\": 4, \"blockType\": \"minecraft:end_portal_frame\",
              \"rollPrice\": 100, \"claimTimeoutMillis\": 10000, \"survivalMysteryBoxPoolId\": $BOOKS }"
   ```
   The price is 100 here (the design default is 1000, S34) so one round pays for a roll.
5. **Readiness and the frozen configuration**: `curl -s "$API/api/siege-survival/scenarios/1/configuration?lobbyId=1" -H "X-API-Key: $KEY" | python3 -m json.tool | less` — `"isReady": true`, `equipment.mode` `Kits` with both kits and the default, one purchase point with two offers, two `mysteryBoxPoints` with their pools and `chanceBasisPoints` (6000/4000 and 7000/3000). Errors mean the round will not start.
6. Restart the server (or wait 5 minutes for the cache). `/knk siege survival status` → `Survival scenarios known: [1]`.

## 3. The checkpoint (15 min)

Own gear in the inventory before joining (it must come back at the end). `/siege admin skip cinix` shortens the matchmaking.

1. **Kit pick at the hub**: `/siege join cinix`. At the hub the chat says "Kits mode: pick your kit before the match starts (K1name, K2name); no pick = K1name. Use /siege kit [name] …" and a **"Pick your kit"** chest menu opens (two chests; the default one glints). Click K2. Chat: "Kit picked: K2name. It is granted when the match starts." `/siege kit` reopens the menu; `/siege kit K1n` (a unique prefix) picks by name. A second player who picks nothing gets the default.
2. **Grant at the start**: at "The siege begins!" your (snapshotted) inventory is **cleared** and replaced by K2's items in their kit slots; chat "Your kit is in your inventory; it stays with you on death and goes away after the match." (the second player: "… (the default kit) …"). Log: `[Survival] Lobby cinix: equipment mode KITS, 1 purchase points, 2 Mystery Box points, match key <token>` and `KITS → kit K2 for <name>: n placed, 0 dropped`. `/knk siege survival status` ends with `Economy: balances […=0], kill reward 70 ×1.1 bonus, ghosts 0, …, equipment KITS`, a `Shops: 1 points, 2 offers ready …` line and two `Mystery Box …: rolls 0 …` lines (`faces ready 2`). A `WARNING … Mystery Box point n … is <block>, configured minecraft:end_portal_frame` means the block at the point is wrong (step 2.4).
3. **Kill → balance +70**: kill one zombie in round 1 with a melee hit: action bar "+70 match coins · balance 70"; `/siege balance` → "Match balance: 70 coins (1 kills, 70 per kill, ×1.1 on a headshot/critical)". Log `kill: enemy #n by <name> +70 (balance 70), permanent +30 coins / +3 xp accrued` (accrued only; S8 settles).
4. **+77 on a critical or headshot**: jump-attack (fall while hitting) for a critical: "+77 match coins (critical)"; or with the kit's bow, hit the zombie's head (arrow above `feet + eyeHeight − 0.3`, i.e. the top ~0.3 blocks of a zombie) for the killing blow: "+77 match coins (headshot)". Only the **killing** blow decides, and only a hit of the last 5 s by the killer counts (flag S7b-4).
5. **Buy**: right-click the Armory block (or `/siege shop` within 4 blocks): the "Armory · <balance> coins" menu shows the two offers with price and quantity; an unaffordable one says so in red. Buy B2 (40): "Bought 70× <name> for 40 · balance …", two stacks (64 + 6) in the inventory, the menu re-renders. Buying with too little: "Not enough match coins: 60 needed, you have …". Fill the inventory and buy again: the overflow **drops at your feet** ("inventory full: dropped at your feet"); you can pick it up again (member), a hopper under it does not take it, a mob does not pick it up. Purchases work during the wave **and** during the break (S58).
6. **Transfer** (second player): `/siege pay <mate> 20` → "Paid 20 match coins to <mate> (balance …)", the mate sees "… paid you 20 match coins (balance …)". `/siege pay <mate> 99999` → "Not enough match coins"; `/siege pay <self> 1` → "You cannot pay yourself"; a player outside the match → "… is not in your match".
7. **Roll the weapon box** (needs ≥ 100): right-click the frame with less → "Mystery Box: 100 match coins per roll; you have …". With enough: "Rolling the Mystery Box for 100 · balance …" at once (the charge, id `m<matchId>-p<point>-<uuid>`), then the **reel**: an item floats above the frame and changes rapidly with its name above it, a note-block tick and enchant particles per step, slowing down over ~20 steps; the last item lands with the level-up sound and a totem/end-rod burst. Chat: "You rolled <name>! Right-click it within 10 s to claim." Log: `roll m… by <name> at box n charged 100 (balance …)`, `roll m… animation: 20 steps, … ticks, reel [ids]`, `roll m… landed on entry k (<name>); claim window 10000 ms`. The API has the row: `GET $API/api/siege-survival/matches/<matchId>/mystery-box/rolls` (state `Rolled`). While it runs, a second right-click on the frame says "Your roll is still running …", the mate gets "The box is busy with another roll".
8. **Claim by the roller only**: the mate right-clicks the floating item → "Only <name> can claim this roll." You right-click it → "Claimed: <name>", the item is in your inventory (enchanted with E1 at level 2 in about half the rolls: the entry's independent chance), the entities are gone, the API row is `Claimed` with `deliveryKind Inventory`. Log `roll m… claimed by <name> (Inventory)`. A full inventory drops it at the box, owned by you (`Drop`).
9. **Timeout forfeit**: roll again and do not claim: after 10 s the item vanishes, action bar "The Mystery Box item was not claimed in time.", log `roll m… forfeited: TIMEOUT (no refund, S59)`, the API row `Forfeited`/`Timeout`, the balance stays reduced. The box accepts a new roll at once.
10. **Death forfeit**: roll, then die during the reel (`/kill`): the entities vanish at once, log `… forfeited: ROLLER_DIED …`, API `RollerDied`. As a **ghost** you cannot buy ("Ghosts cannot buy anything."), roll ("Ghosts cannot roll the Mystery Box."), pay ("Ghosts cannot transfer coins.") or be paid ("<name> is a ghost and cannot receive coins now."); kills by a ghost are impossible anyway. Your kit stays in your inventory on death and respawn (S40/S45; **no re-grant**, flag S7b-1).
11. **Book variant**: roll the book box: the reel shows enchanted books; the claim gives an **enchanted book** with the rolled enchantment and level (E1 III in 70 % of the rolls); API row with `variant EnchantedBooks`, `entry.enchantmentDefinitionId`.
12. **Item tags**: every kit item, bought item and prize is a match item (`/knk siege survival status` reports nothing per item; use an NBT viewer or the pickup checks): a teammate can pick up your dropped overflow; a player **not** in the match cannot ("That item belongs to another match."); a hopper and a mob cannot; you cannot put one into a chest (the Siege storage guard) or an item frame; death drops nothing (S40).
13. **Match end removes everything**: finish with a team wipe (die as the last player) or `/siege admin stop cinix`. Every box entity is gone, every ground match item is removed (`removed n match ground items` in the log when any lay around), the pending roll (if you were mid-reel) is forfeited with `MATCH_ENDED`; the log has `economy closed: balances […], accrued kills n (settlement is S8)`. After the post-match wait the **vault restore** gives back your own gear exactly, with **no** kit, bought or box item left (the plugin strips its match items from you before the restore as well: `removed n match item stacks from <name> before the restore`). `/knk siege survival status` → `running survival matches: 0` … `match ground items tracked for []`.
14. **Restart during a roll** (optional): start a match, roll, stop the server during the reel. On the next start: `[Survival] Removed n leftover Mystery Box entities and m match items` (if the chunk was loaded) and the Siege abort/restore as in S5 step 13. The roll row stays `Rolled` on the API (no recovery before S8; flag S7b-9).

**If something is off**
- No kit picker at the hub: the scenario's `equipment.mode` is not `Kits` in the frozen configuration (step 2.5), or the cache was not refreshed (restart). `/siege kit` says "This lobby's scenario does not use kits".
- "Your kit could not be granted (it no longer exists)": the kit id in the settings does not resolve (`GET api/Kits/<id>`); the match goes on empty-handed and logs `KIT MISSING`.
- The shop menu shows a barrier "Not available": the offer's blueprint could not be assembled (log `Purchase offer n … cannot be sold`); check the blueprint's material ref.
- The reel shows a barrier face for an entry: `Mystery Box entry n (…) has no displayable item` in the log — same cause.
- "The match is not registered with the API yet": the `createMatch` call of the Siege start has not answered; try again a moment later. "Your user id is unknown": the join did not resolve the user (API down at the join).
- A roll answers "The Mystery Box could not roll (api-conflict:PoolInvalid)": the pool was edited after the draw and no longer adds up to 100 %; the charge stands (S59, S7a-6).

## 4. What to watch in the server log

`[Survival] Lobby cinix:` lines added by S7b: `equipment mode …, n purchase points, m Mystery Box points, match key …`; `KITS|MATCH_PROGRESSION → kit n [(default)] for <name>: k placed, d dropped` or `KIT MISSING, empty inventory`; `kill: enemy #n by <name> [(headshot|critical)] +70|77 (balance …), permanent +… accrued`; `<name> bought q× <item> for p (balance …, dropped stacks d)`; `roll <id> by <name> at box n charged p (balance …)`, `roll <id> animation: …`, `roll <id> landed on entry k …`, `roll <id> claimed by <name> (Inventory|Drop)`, `roll <id> forfeited: TIMEOUT|ROLLER_DIED|ROLLER_LEFT|MATCH_ENDED (no refund, S59)`; `economy closed: balances …`; `removed n match ground items`, `removed n match item stacks from <name> before the restore`. WARNINGs that are expected only when authoring is off: `Mystery Box point … is <block>, configured …`, `… pool invalid …`, `Purchase offer … cannot be sold`, `roll … refused by the API (409 …)`, `roll …: network error …; retrying the same call in n ms` (the retry is the same idempotent call). Nothing at SEVERE.

## 5. Own-inventory and match-progression modes (5 min, optional)

- `PUT …/scenarios/1/settings` with `"equipmentMode": "OwnInventory"` (+ restart): no picker, your own gear stays, shops and boxes work the same, the restore gives everything back.
- `"equipmentMode": "MatchProgression", "baselineLoadoutKitId": K1`: no picker, the inventory is replaced by K1 at the start ("Your baseline gear is in your inventory …"); with `null` the inventory is **empty** at the start.

## 6. Flags that need a decision after the test

From the chain report's S7b block: **S7b-1** (§8 prose "re-granted at every respawn" vs the table "not granted again" — the table was followed), the plain-inventory kit picker and shop menus instead of API-seeded menu definitions, transfers as a command, the match item tag being the Siege match token (not the API match id), the 5-second killing-blow window and the head band of 0.3 blocks below the eyes, custom enchantments on book prizes, the local cancel of a roll after an API error (charge stands), no roll recovery before S8, and `/siege shop` as the command fallback for a purchase point in range.
