# Siege shop and siege points — smoke test

**Status:** Draft (2026-11-20): §§ 1–2 built and tagged (L1 #866, L2 #867), §§ 3–5 draft from the design; no steps run by hand.
**Last updated:** 2026-11-20 (§ 2 updated to what L2 built, steps tagged, #867, #878); 2026-11-20 (§ 1 updated to what L1 built, steps tagged, #866); 2026-11-20 (draft from the design, phases 1–4, 5a, 5b)
**Design:** [specs/siege-shop/DESIGN.md](../specs/siege-shop/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611),
[#356](https://github.com/PandiO/knk-workspace/issues/356), [#859](https://github.com/PandiO/knk-workspace/issues/859)

Accounts used throughout: **Admin** (web app staff with the siege admin and content permissions, op in game), **A1**
and **A2** (two players on the attacking team), **D1** (a player on the defending team). Write down any step that
fails, with the server log lines.

## 1. Phase 1: shared match ledger and siege points earning (#866, tier:3)

*Built by L1 (2026-11-20, branches `claude/siege-shop-l1` in knk-plugin and knk-web-api). 17 of 19 steps fully or partly
automated (tagged; plugin tests in knk-core and knk-paper, API tests in xUnit); every step can still be run by hand;
manual steps not run yet. A full manual run takes about 40 minutes; the untagged steps and the by-hand parts about 25.*

### 1.0 Preconditions

1. Deployed: knk-web-api from the branch (or `next` once merged) with the migration `AddSiegePointsEarning` applied;
   knk-plugin built from the same branch.
2. Settings: in the plugin's `config.yml` under `siege:`
   ```yaml
   siege:
     points:
       enabled: true
   ```
   then restart. `SiegeConfiguration` with the default earn amounts (kill 100, streak step 0.1 cap 1.5, assist 40 with
   4 damage in 10 s, death 15, 1 point per 5 gate HP, 3 per capture %, capture 100, trickle 10 per 60 s) and
   `pointTransfersEnabled` false. The web app's siege settings page does not show these fields yet (#878): check them with
   `GET api/SiegeConfiguration` and change them with `PUT api/SiegeConfiguration` (Swagger, signed in as Admin), for
   example `{ "pointTransfersEnabled": true }`. The migration gives an existing configuration row the defaults.
3. Accounts and data: A1, A2, D1; a Ready Siege scenario with at least one gate and one capturable (non-instant-victory)
   objective; a lobby that can start with three players. Optional: diagnostic telemetry on, to check step 15.

### 1.1 Steps

1. [automated: knk-paper `SiegeScoreboardPresenterPointsTest`, `SiegePointsServiceTest.everyMemberStartsAtZeroWithTheirOwnScoreboardLine_A04_A10`]
   A1, A2 and D1 join and the match starts. **Expected:** each player's sidebar shows the usual lines (team, time
   left, objectives) plus "Siege points: 0" right under the time; each sees only their own number; team colours on
   name tags and `[K/D]` in the tab list are as before. (A04, A10)
2. [automated: knk-paper `SiegePointsServiceTest.killsPayWithTheStreakAndTheActionBarShowsEachChange_A05_A07_A10`]
   A1 kills D1 with a sword. **Expected:** A1's action bar shows "+100 kill · 100"; D1's shows "+15 death · 15"; the
   sidebars show 100 and 15. (A05, A07)
3. [automated: knk-paper `SiegePointsServiceTest.enemyDamageInTheWindowEarnsAnAssist_A06`, knk-core `SiegePointsEarnCalculatorTest``.anAssistPays40ToEveryEnemyAssisterButNeverTheKiller`]
   A2 hits D1 for at least 2 hearts, then within 10 s A1 kills D1. **Expected:** A1 gets "+110 kill ×1.1" (the 2nd
   kill of the streak), A2 gets "+40 assist". (A05, A06)
4. [automated: knk-core `SiegePointsEarnCalculatorTest``.assistsNeedFourDamageWithinTenSeconds`] A2 hits D1 for half a heart only, then A1 kills
   D1 within 10 s. **Expected:** no assist for A2. (A06)
5. [automated: knk-core `SiegePointsEarnCalculatorTest``.assistsNeedFourDamageWithinTenSeconds`] A2 hits D1 for 2 hearts, waits 15 s, then A1 kills
   D1. **Expected:** no assist for A2. (A06)
6. [automated: knk-core `SiegePointsEarnCalculatorTest``.aKillPays100AndTheStreakRaisesItByATenthUpToTheCap`] A1 keeps killing D1 until six kills
   in a row. **Expected:** kills 2–6 pay 110, 120, 130, 140, 150 (the action bar shows "×1.2" … "×1.5"); a 7th still
   pays 150. (A05)
7. [automated: knk-paper `SiegePointsServiceTest.killsPayWithTheStreakAndTheActionBarShowsEachChange_A05_A07_A10`]
   D1 kills A1. **Expected:** A1 gets "+15 death"; A1's next kill pays 100 again (streak reset). (A05)
8. [partly automated: knk-core `SiegePointsEarnCalculatorTest``.anEnvironmentDeathPaysTheVictimTheDeathAmount`, `.friendlyFireAndSuicidePayNobody`; by hand: the real fall]
   Friendly fire is off; A1 jumps from a height and dies without being hit first. **Expected:** A1 gets "+15 death"; no
   kill points to anyone. (A07)
9. [partly automated: knk-core `SiegePointsEarnCalculatorTest``.gateDamagePaysOnePointPerFiveHpAndKeepsTheFractions`, `SiegePointsServiceTest.gateDamagePaysOnePointPerFiveHp_A08`; by hand: real gate hits]
   A1 damages a gate door by 50 HP (watch the gate's health bar). **Expected:** A1 earns 10 points in total, shown as
   "+N gate" on the action bar as the hits land. (A08)
10. [partly automated: knk-core `SiegePointsCaptureTest.attackersEarnPerPercentTheyMoveAndDefendersEarnForPushingBack`; by hand: the radius in the world]
    A1 and A2 stand in an objective's capture radius while it moves 10 % towards the attackers. **Expected:** each
    earns about 30 points ("+N objective" every second); D1, standing outside the radius, earns nothing. D1 then
    enters alone and pushes it back 5 %. **Expected:** D1 earns about 15. (A08)
11. [partly automated: knk-core `SiegePointsCaptureTest.aCapturePays100ToTheCapturingSideInsideAndTheLastPercentsCount`; by hand: the capture in the world]
    The attackers capture the objective with A1 inside and A2 outside. **Expected:** A1's action bar shows "+100
    capture"; A2 gets no capture points. (A08)
12. [partly automated: knk-core `SiegePointsEarnCalculatorTest``.theTricklePaysOnlyMembersActiveInTheInterval`, `SiegePointsServiceTest.theTricklePaysActiveMembersOnly_andNeverAnAfkOne_A09`; by hand: real movement]
    A2 stands still at spawn for two minutes while A1 keeps playing (fighting, walking or standing on an objective).
    **Expected:** A1 gets "+10 activity" once a minute; A2 gets nothing. Walking at least 10 blocks in a minute,
    fighting, damaging a gate or standing in a capture radius counts as active; an AFK player (statistics AFK) never
    is. (A09)
13. [automated: knk-paper `SiegePointsServiceTest.siegePointsCommandPrintsBalanceEarnedAndSpent_A10`] `/siege points`
    as A1. **Expected:** "Siege points: B (earned E, spent S this match)", matching the sidebar and the action bar
    totals. (A10)
14. [automated: knk-paper `SiegePointsServiceTest.payIsRefusedWhileTransfersAreOff_A03`, `.payMovesPointsToATeammateOnlyAndNeverOverdraws_A01_A03`, knk-core `SiegePointsEconomyTest`]
    `/siege pay A2 50` as A1. **Expected:** refused, "Sending siege points to teammates is turned off in this game
    mode."; nothing changes. Admin sets `pointTransfersEnabled` true (`PUT api/SiegeConfiguration`) and a new match
    starts (settings are frozen per match); repeat. **Expected:** A1 −50, A2 +50, both told; `/siege pay A2 999999` is
    refused ("Not enough siege points: …") and nothing changes; `/siege pay D1 10` is refused (not a teammate). Set
    `pointTransfersEnabled` back to false afterwards. (A01, A03)
15. [partly automated: knk-paper `SiegePointsServiceTest.theMatchResultCarriesEarnedAndSpent_andTheEndStopsEarning_A04_A11`, `SiegePointsTelemetryTest`, knk-api-client `SiegeMatchesCommandApiImplTest.complete_sendsSiegePointsOnlyWhenTheyWereCounted_866`, API `SiegeMatchServiceTests.Complete_StoresSiegePointsEarnedAndSpent_AndZeroWhenNotSent`; by hand: the live result]
    The match ends. **Expected:** each member gets "Siege points this match: earned E, spent S."; `GET
    api/siege-matches/{id}` shows `siegePointsEarned` and `siegePointsSpent` per participant; with telemetry on, the
    owner timeline has `siege.points_earned` events (kills one each, capture progress and gate damage summed per
    minute). In the next match everyone starts at 0. (A04, A11)
16. [partly automated: knk-paper `SiegeScoreboardPresenterPointsTest.withSiegePointsOffTheBoardsStayOnePerTeamWithoutAPointsLine_A12`, `SiegeCommandPointsTest`, knk-api-client `SiegeMatchesCommandApiImplTest.complete_sendsSiegePointsOnlyWhenTheyWereCounted_866`; by hand: a real match]
    Admin sets `siege.points.enabled: false` and restarts; play a match with a kill. **Expected:** no siege points line
    (the sidebar looks exactly as before this feature), no points on the action bar ("You killed …" as before),
    `/siege points` says "Siege points are not enabled on this server.", `points` and `pay` are not suggested after
    `/siege `, and the match result has 0 siege points. (A12)
17. [automated: knk-core `MatchLedgerTest.retriesAreIdempotentAndConflictingReuseIsRejected`, `SiegePointsEconomyTest.aRetriedTransferOrChargeIsAppliedOnce_A02`]
    Retry safety (A02) is checked by the ledger tests only: a charge or transfer repeated with the same retry id
    debits once and returns the first result. (A02)
18. A1 leaves the match with `/siege leave` and rejoins a new match later. **Expected:** their balance is gone at the
    leave (§ 5.1.3); the result still lists what they earned. Manual: needs a real leave. (A04)
19. Server restart during a match. **Expected:** the match ends without rewards as before and no balance comes back
    (P12). Manual: needs a real restart. (A04)

## 2. Phase 2: shop catalogue entities, scenario overrides and web app forms (#867, tier:2)

*Built by L2 (2026-11-20, branches `claude/siege-shop-l2` in knk-web-api and knk-web-app; it also built #878, the
siege settings page fields of § 1). 11 of 14 steps fully or partly automated (tagged; API tests in xUnit, web app tests
in Jest and Playwright with a mocked API); every step can still be run by hand; manual steps not run yet. A full manual
run takes about 30 minutes; the untagged steps and the by-hand parts about 15. Nothing in game reads the catalogue
until phase 3.*

### 2.0 Preconditions

1. Deployed: knk-web-api from the branch (or `next` once merged) with the migration `AddSiegeShopCatalogue` applied
   and the API restarted once (the startup seed `SiegeShopSeed` fills the default catalogue); knk-web-app from the same
   branch.
2. Form configurations imported from knk-web-api `Data/FormConfigurationSeeds/`: `SiegeShopCategory`,
   `SiegeShopEntry`, `SiegeScenarioShopOverride`, and the updated `SiegeScenario` (new "Siege shop" step) and
   `ItemBlueprint` (new "Potion type" field). On a database that imported the old two, add the step and the field in
   the form designer (the seeds README says how).
3. Settings: none. No plugin change in this phase.
4. Accounts and data: Admin; one Siege scenario (call it S, id `<id>`); for step 3, at least one siege weapon template
   created **before** the API's first start with the migration (a fresh database has no templates, so its shop has no
   weapon entries until Admin adds them, step 7).

### 2.1 Steps

1. [automated: knk-web-api `SiegeShopServiceTests.Categories_AreSeeded_WithStableKeys`, `AddSiegeShopCatalogueTests.Up_SeedsTheThreeCategories`; knk-web-app e2e `siege-shop.spec.ts` "lists the seeded categories with their keys"]
   Admin opens the dashboard → SiegeShopCategory. **Expected:** three categories: Siege weapons (`siege-weapons`),
   Consumables (`consumables`), Magic (`magic`). (A13)
2. [automated: knk-web-api `SiegeShopSeedTests.FreshDatabase_GetsTheSection12Catalogue`; knk-web-app e2e `siege-shop.spec.ts` "lists the shop entries of both modes with category, kind, price and cap"]
   Admin opens the dashboard → SiegeShopEntry. **Expected:** for PvP Siege, under Consumables: Ender Pearl 300 (max 8),
   Splash Potion of Healing II 150 (max 10), Golden Apple 200 (max 6), Potion of Regeneration 250 (max 4); the same
   four for Siege Survival at 3000, 1500, 2000 and 2500. The Scenario column says "Default". (A13)
3. [automated: knk-web-api `SiegeShopSeedTests.FreshDatabase_GetsTheSection12Catalogue`; knk-web-app e2e `siege-shop.spec.ts` "lists the shop entries of both modes …"]
   In the same list (database with templates, precondition 4). **Expected:** one PvP Siege entry per weapon template,
   under Siege weapons, Price "Template price". No weapon entries for Siege Survival. (A13, A16)
4. [automated: knk-web-api `SiegeShopSeedTests.FreshDatabase_GetsTheSection12Catalogue`, `PotionTypeKeysTests.Blueprint_SavesReadsAndClearsItsPotionType`]
   Admin opens the item blueprint "Splash Potion of Healing II". **Expected:** material splash potion, Potion type
   `minecraft:strong_healing`; "Potion of Regeneration" has `minecraft:regeneration`. Typing `healing_iii` as a potion
   type and saving is refused with "not a vanilla potion type". (DESIGN § 9.4)
5. [partly automated: knk-web-api `SiegeShopServiceTests.Entry_Update_ChangesTheFields`; knk-web-app e2e `siege-shop.spec.ts` "saves a shop entry with its price and brakes …"; by hand: the seeded form's steps]
   Admin edits the PvP Ender Pearl: price 350, saves. **Expected:** saved; the list shows 350. The form shows the
   "Item" step (blueprint, quantity) and not "Siege weapon" while Kind is Item; the "Price" and "Cooldown and cap" steps
   show the step growth choices None, Linear, Logarithmic, Exponential. (A13)
6. [automated: knk-web-api `SiegeShopServiceTests.Entry_WhoseTargetDoesNotMatchItsKind_IsRefused`, `.Entry_WithABadValue_IsRefused`]
   Admin creates an entry with Kind Item, a price and a weapon template instead of an item blueprint (set Kind to
   SiegeWeapon, pick the template, switch Kind back to Item, pick a blueprint too). **Expected:** refused with "An Item
   entry sells an item blueprint, not a siege weapon template."; nothing saved. An exponential growth factor of 1, a
   cooldown step without a cooldown, or a maximum price below the price are refused the same way. (A14)
7. [partly automated: knk-web-api `SiegeShopServiceTests.WeaponEntry_SellsOneWeaponPerPurchase`; knk-web-app e2e `siege-shop.spec.ts` "saves a shop entry …"; by hand: the weapon picker]
   Admin creates a PvP Siege entry, Kind SiegeWeapon, category Siege weapons, a weapon template, price empty.
   **Expected:** saved; the list shows "Template price". (A16)
8. [automated: knk-web-api `SiegeShopServiceTests.Category_WithEntries_CannotBeDeleted_ButAnEmptyOneCan`, `.Category_CreateUpdate_AndKeyRules`; knk-web-app e2e `siege-shop.spec.ts` "saves a shop category …"]
   Admin creates a category key `traps`, name Traps, and tries to delete Consumables. **Expected:** Traps saved; the
   delete of Consumables is refused ("has 8 shop entries"). Delete Traps again. (A13)
9. Admin opens scenario S in the form wizard and goes to the "Siege shop" step. **Expected:** two lists, "Shop
   overrides" and "Scenario-only entries", both empty, with Create New. Manual: the scenario form is a seeded form with
   owned lists. (A13)
10. [partly automated: knk-web-api `SiegeShopServiceTests.Override_SavesAndReadsBack_ThroughTheScenario`, `.Override_OnePerScenarioAndEntry_OnlyForDefaultEntries`; knk-web-app Jest `siegeShopClients.test.ts`; by hand: the wizard]
    Under "Shop overrides", Create New: entry PvP Golden Apple, Hide in this scenario on; save. Create New again: entry
    PvP Ender Pearl, Max per match 4; save. Try a third override for the Ender Pearl. **Expected:** the first two are
    listed with their entry names; the entry picker lists default entries only; the third is refused ("This scenario
    already overrides that entry"). (A13)
11. [partly automated: knk-web-api `SiegeShopServiceTests.Scenario_ReadDto_ListsItsOverridesAndOwnEntries`; by hand: the wizard]
    Under "Scenario-only entries", Create New: Kind Item, category Consumables, any blueprint (say Arrow), quantity 16,
    price 40; the Scenario field is already S. Save. **Expected:** listed on the scenario; on the dashboard the entry
    shows Scenario S. (A13)
12. [automated: knk-web-api `SiegeShopServiceTests.Catalogue_ForAScenario_HidesAppliesOverridesAndAddsItsOwnEntries_A15`, `.Catalogue_AnEmptyOverride_KeepsTheDefault`]
    As Admin (signed in), open `GET api/SiegeShop/catalogue?mode=Siege&scenarioId=<id>` (Swagger or the browser).
    **Expected:** no Golden Apple; the Ender Pearl with `maxPerMatch` 4, `source` "Overridden" and its other fields
    from the default (price 350, cooldown 20, exponential cooldown growth); the arrows with `source` "Scenario";
    categories only where something is visible (no Magic). (A15)
13. [automated: knk-web-api `SiegeShopServiceTests.Catalogue_WeaponEntryWithoutPrice_UsesTheTemplatesMatchPrice_A16`]
    In the same response, look at the weapon entry of step 7. **Expected:** its `price` is the template's `MatchPrice`
    (200 by default). Without `scenarioId` the response has the mode's defaults only; `mode` missing answers 400.
    (A16)
14. [automated: knk-web-app Jest `SiegeConfigurationPage.test.tsx` "shows the siege points section (#878) …"; e2e `settings-pages.spec.ts` "the siege points section shows the earn amounts …"]
    Admin opens Siege settings. **Expected:** a "Siege points" section with the earn amounts of § 1.0 (kill 100, streak
    step 0.1, cap 1.5, assist 40, 4 damage, 10 s, death 15, 5 HP per point, 3 per capture %, capture 100, trickle 10 per
    60 s) and "Allow teammate transfers" off. Change the kill points to 120 and save: "Saved 1 setting."; a value the
    API refuses (streak cap 0.5) shows its reason. (#878)

## 3. Phase 3: shop menus and purchases in the plugin (#868, tier:3)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: phases 1 and 2; knk-plugin from `next` with this phase.
2. Settings: `siege.points.enabled: true`, `siege.shop.enabled: true`; to test weapon entries also
   `siege.weapons.enabled: true`.
3. Accounts and data: A1, A2, D1; the seeded catalogue with the ender pearl at 300, +50 linear, cooldown 20 s +10 s
   exponential ×1.5, cap 8; A1 has not unlocked the trebuchet. A Siege Survival scenario for step 13.

### 3.1 Steps

1. In a running match A1 types `/siege shop`, then opens `/siege menu` → Shop. **Expected:** the shop opens both
   ways, anywhere on the map, with the balance in the title, categories Siege weapons and Consumables, no empty Magic
   category. (A17)
2. A1 with 400 points buys an ender pearl. **Expected:** 300 charged, 1 pearl in the inventory, the line now shows
   350, "bought 1/8" and a 20 s cooldown. (A18, A20, A21)
3. A1 clicks the pearl again during the cooldown. **Expected:** "Cooldown: N s"; nothing charged. (A19)
4. After the cooldown, A1 with 100 points clicks the pearl. **Expected:** "Not enough siege points: 100/350";
   nothing charged. (A19)
5. A1 earns enough and buys pearls until the cap. **Expected:** prices 350, 450, 600, 800, …; cooldowns 30, 45, 67.5 s
   …; after the 8th, "Limit reached: 8 per match". (A20, A21, A22)
6. A1 fills every inventory slot and buys a healing potion. **Expected:** "Inventory full"; nothing charged. (A19)
7. A1 clicks the trebuchet entry. **Expected:** shown as locked with "unlock in /menu → Minigames → Siege unlocks";
   nothing charged, no spot picker. (A26)
8. During the match Admin changes the pearl's price in the web app. **Expected:** the shop keeps the old price; the
   next match uses the new one. (A23)
9. The match ends while A1 holds 3 unused pearls. **Expected:** the pearls are gone after the gear restore; no
   refund; the result shows spent points. (A11, A24)
10. In a new match A1's pearl price, cooldown and count start over. **Expected:** 300, no cooldown, 0/8. (A22)
11. A1 throws a bought pearl over the castle wall. **Expected:** vanilla behaviour, A1 lands inside. (P04)
12. The telemetry for the test run shows a `siege.shop.purchase` event per purchase with entry, price and purchase
    number. (A11)
13. In a Siege Survival match (after the Survival branch has merged): A1 earns siege points from NPC kills, buys a
    pearl in `/siege shop`, then buys at a purchase point and rolls the Mystery Box. **Expected:** all three charge the
    same balance; `/siege shop` opens the siege shop even next to a purchase point. (A17, A25)

## 4. Phase 4: siege weapon unlocks with coins and title level (#869, tier:2)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: phase 2; knk-web-api, knk-web-app and knk-plugin from `next` with this phase.
2. Settings: the trebuchet template with unlock price 1000 coins and minimum title level set to A1's title + 1; the
   ballista with 500 coins and no minimum.
3. Accounts and data: A1 with 1200 coins and a web account.

### 4.1 Steps

1. Outside a match A1 opens the main menu → Minigames → Siege unlocks. **Expected:** each template with price,
   minimum title and state; the trebuchet says "Needs title …". (A27)
2. A1 clicks the trebuchet. **Expected:** refused for the title level; coins unchanged. (A27)
3. A1 clicks the ballista and confirms, double-clicking fast. **Expected:** one charge of 500 coins, the ballista shows
   "Unlocked". (A27)
4. A1 joins a match and opens the main menu's Siege unlocks. **Expected:** unlocking is refused during a match; the
   shop's ballista entry is no longer locked. (A26, A28)
5. On the web app A1 opens their profile → Siege unlocks. **Expected:** the same list; the ballista unlocked;
   unlocking another type there charges coins once. (A27)

## 5. Phases 5a and 5b: menu item settings (#870, #871, tier:2)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: knk-web-api and knk-web-app with phase 5a; knk-plugin with phase 5b (and phase 3 for the shop target).
2. Settings: the seeded menu item settings (default clicks open `main`; siege match overrides open
   `siege.information` and, on shift-right, `siege.shop`).
3. Accounts and data: Admin; A1 online in the hub.

### 5.1 Steps

1. Admin opens the game settings page → Menu item, changes the name and sets shift-left to run `siege points`, then
   saves. **Expected:** A1's item shows the new name within seconds, without a restart, in the same slot. (A29)
2. Outside a match A1 right-clicks the item. **Expected:** the main menu opens. (A30)
3. In a running PvP match A1 right-clicks, then shift-right-clicks the item. **Expected:** the siege menu, then the
   siege shop. In a Survival match the same. (A30)
4. With the API stopped, restart the plugin and join as A1. **Expected:** the menu item is given from the `config.yml`
   keys and opens the main menu. (A31)
