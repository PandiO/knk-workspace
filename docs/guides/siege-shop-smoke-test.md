# Siege shop and siege points — smoke test

**Status:** Draft (2026-11-21): §§ 1–4 built and tagged (L1 #866, L2 #867, L3 #868, L4 #869), § 5.1 built and tagged (L5 #870), § 5.2 built and tagged (L6 #871); no steps run by hand.
**Last updated:** 2026-11-21 (§ 5.2 updated to what L6 built, steps tagged; locked-weapon text in §§ 3–4 names /menu → Siege Minigame → Siege unlocks, #871); 2026-11-20 (§ 4 updated to what L4 built, steps tagged, #869); 2026-11-20 (§ 3 updated to what L3 built, steps tagged, #868); 2026-11-20 (§ 5 updated to what L5 built, § 5.1 steps tagged, #870); 2026-11-20 (§ 2 updated to what L2 built, steps tagged, #867, #878); 2026-11-20 (§ 1 updated to what L1 built, steps tagged, #866); 2026-11-20 (draft from the design, phases 1–4, 5a, 5b)
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

*Built by L3 (2026-11-20, branches `claude/siege-shop-l3` in knk-plugin and knk-web-api). 16 of 19 steps fully or partly
automated (tagged; plugin tests in knk-core, knk-api-client and knk-paper with MockBukkit, API tests in xUnit); every
step can still be run by hand; manual steps not run yet. A full manual run takes about 45 minutes; the untagged steps
and the by-hand parts about 25.*

### 3.0 Preconditions

1. Deployed, **in this order**: knk-plugin from the branch (or `next` once merged), then knk-web-api from the branch
   (or `next`), restarted once. The API seeds the menus `siege.shop` and `siege.shop.category` and adds the **Shop**
   button to `siege.information` (also on a database seeded before, once); a plugin without this phase would block
   `siege.information` at its menu validation, so the plugin goes first. Phases 1 and 2 are deployed (migrations
   `AddSiegePointsEarning` and `AddSiegeShopCatalogue` applied, the default catalogue seeded).
2. Settings: in the plugin's `config.yml` under `siege:`
   ```yaml
   siege:
     points:
       enabled: true
     shop:
       enabled: true
   ```
   then restart. For steps 7 and 8 also `weapons:` → `enabled: true`. The shop needs siege points: with
   `shop.enabled: true` and `points.enabled: false` the log says so and the shop stays off (step 18).
3. Accounts and data: A1, A2, D1; the seeded PvP catalogue (§ 2 step 2: ender pearl 300, +50 linear, cooldown 20 s
   +10 s exponential ×1.5, cap 8; splash potion of healing II 150; golden apple 200; regeneration 250); for steps 7
   and 8 one weapon entry (§ 2 step 7) whose template A1 has **not** unlocked; a Ready Siege scenario. To have points
   to spend quickly, let A1 kill D1 a few times, or lower the prices of a test scenario with overrides (§ 2 step 10).
   A Siege Survival scenario for step 17 (after the Survival branch has merged). Optional: diagnostic telemetry on,
   for step 15.

### 3.1 Steps

1. [partly automated: knk-paper `SiegeShopServiceTest.theShopOpensAnywhereDuringTheMatch_withItsCategoriesAndNoWeaponsWhileTheyAreOff_A17`, `SiegeCommandShopTest.withTheShopOnTheSubcommandOpensTheShop_A17`, `SiegeShopMenuFeatureTest.withTheShopOnTheButtonFollowsTheMatch_andBuyingReachesTheService`, knk-web-api `MenuTemplateSiegeSeedTests.Information_HasAShopButton_ShownOnlyWhileTheViewerCanUseAShop_868`, knk-api-client `SiegeMenuSeedContractTest`; by hand: the real menus]
   In a running match A1 types `/siege shop`, closes it, then opens `/siege menu` and clicks **Shop** (emerald, top
   left), once at spawn and once far out on the map. **Expected:** the shop opens all four times. Its gold header item
   shows "Siege points: N" (the menu engine's titles are fixed text, so the balance is there, not in the title) and
   "Purchases are final; bought items end with the match."; the categories are Consumables, plus Siege weapons only
   with `siege.weapons.enabled: true`; no Magic category. Outside a match `/siege shop` says "The siege shop is open only
   during a running siege match." and `/siege menu` has no Shop button. (A17)
2. [automated: knk-paper `SiegeShopServiceTest.aPurchaseChargesTheCurrentPriceAndGivesTheFullQuantity_A18_A20_A21`, knk-core `ShopPurchaseServiceTest.aPurchaseChargesTheCurrentPriceAndGivesTheFullQuantity_A18`]
   A1 with 400 points opens Consumables and clicks the Ender Pearl. **Expected:** "Bought Ender Pearl for 300 siege
   points. Balance: 100."; one ender pearl in the inventory; the sidebar shows 100; the pearl's line now shows "Price:
   350 siege points", "Bought: 1/8" and "Cooldown: 20 s" counting down, greyed out. (A18, A20, A21)
3. [automated: knk-core `ShopPurchaseServiceTest.eachRefusalChargesNothingAndNamesItsReason_A19`, knk-paper `SiegeShopServiceTest.eachRefusalChargesNothing_andAFullInventoryIsRefused_A19`]
   A1 clicks the pearl again during the cooldown. **Expected:** "Cooldown: N s."; nothing charged. (A19)
4. [automated: knk-core `ShopPurchaseServiceTest.eachRefusalChargesNothingAndNamesItsReason_A19`, knk-paper `SiegeShopServiceTest.eachRefusalChargesNothing_andAFullInventoryIsRefused_A19`]
   After the cooldown, A1 with 100 points clicks the pearl. **Expected:** "Not enough siege points: 100/350."; the line
   says the same in red; nothing charged. (A19)
5. [automated: knk-core `ShopPurchaseServiceTest.pricesAndCooldownsGrowUntilTheCap_A20_A21_A22`, `ShopBrakesTest.theDesignExample_pearlPricesAndCooldowns_A20_A21`, `.priceGrowsPerCurve_A20`, `.theMaximumPriceHolds_andNoStepIsAFixedPrice_A20`, `.cooldownGrowsPerCurve_andTheMaximumHolds_A21`]
   A1 earns enough and buys pearls until the cap, waiting out each cooldown. **Expected:** prices 350, 450, 600, 800,
   1050, 1350, 1700; cooldowns after the 2nd, 3rd and 4th purchase 30, 45 and 67.5 s (shown rounded up); after the
   8th the line says "Limit reached: 8 per match" and a click says "Limit reached: 8 per match.". (A20, A21, A22)
6. [automated: knk-paper `SiegeShopServiceTest.eachRefusalChargesNothing_andAFullInventoryIsRefused_A19`, knk-core `ShopPurchaseServiceTest.eachRefusalChargesNothingAndNamesItsReason_A19`]
   A1 fills every main inventory slot (hotbar included) with full stacks and buys a Splash Potion of Healing II.
   **Expected:** "Inventory full: make room for the whole stack first."; nothing charged, nothing dropped. (A19, P22)
7. [automated: knk-paper `SiegeShopServiceTest.aLockedWeaponShowsWhereToUnlockIt_andCantBeBought_A26`, knk-core `ShopPurchaseServiceTest.aLockedWeaponIsRefusedAndShownLocked_andWeaponsWaitForTheirHandler_A26`, `ShopCatalogueTest.anEntryRowShowsPriceBoughtCooldownAndWhyNot_A26`]
   With `siege.weapons.enabled: true`, A1 opens Siege weapons and clicks the weapon entry. **Expected:** the line is
   greyed out and says "Locked: unlock it in /menu → Siege Minigame → Siege unlocks."; the click says the same; nothing
   charged, no spot picker. (A26)
8. [automated: knk-paper `SiegeShopServiceTest.aLockedWeaponShowsWhereToUnlockIt_andCantBeBought_A26`]
   Admin grants A1 the weapon's unlock in the web app (UserSiegeWeaponUnlock); in the **next** match A1 clicks the
   entry. **Expected:** "Siege weapons can't be bought yet."; nothing charged (placing weapons comes with siege weapons
   phase 3, #784, which plugs into the shop's purchase port). Unlocks are read at the match start. (A26)
9. [automated: knk-paper `SiegeShopServiceTest.theCatalogueIsReadOnceAtTheStart_editsApplyFromTheNextMatch_andCountersStartOver_A22_A23`, knk-core `ShopPurchaseServiceTest.theCatalogueIsTheOneTheMatchStartedWith_A23`]
   During the match Admin changes the PvP Ender Pearl's price to 999 in the web app. **Expected:** the shop keeps the
   old price for the rest of the match; the next match shows 999. Set it back afterwards. (A23)
10. [partly automated: knk-paper `SiegeShopServiceTest.afterTheMatchNothingIsSold_andTheSpentPointsAreInTheResult_A11_A24`, `SiegePointsServiceTest.theMatchResultCarriesEarnedAndSpent_andTheEndStopsEarning_A04_A11`; by hand: the gear restore]
    The match ends while A1 holds 3 unused pearls. **Expected:** after the post-match wait the pearls are gone with
    the gear restore (A1 gets their own inventory back); no points come back; "Siege points this match: earned E,
    spent S." counts the purchases, and `GET api/siege-matches/{id}` shows the same `siegePointsSpent`. (A11, A24)
11. [automated: knk-paper `SiegeShopServiceTest.theCatalogueIsReadOnceAtTheStart_editsApplyFromTheNextMatch_andCountersStartOver_A22_A23`, knk-core `ShopPurchaseServiceTest.pricesAndCooldownsGrowUntilTheCap_A20_A21_A22`]
    In a new match A1 opens Consumables. **Expected:** the pearl at 300 again, no cooldown, "Bought: 0/8". (A22)
12. A1 throws a bought pearl over the castle wall. **Expected:** vanilla behaviour: A1 lands inside, no siege rule stops
    it. Manual: needs real terrain. (P04)
13. [automated: knk-paper `SiegeShopServiceTest.aDeadMemberCantBuy`]
    A1 dies and clicks an offer in a shop menu still open on the death screen, or types `/siege shop` and buys right
    after respawning. **Expected:** while dead: "You can buy only while you are alive in the match."; after the respawn
    the purchase works. (P22)
14. [automated: knk-paper `ItemPotionTypeTest.theBlueprintsPotionTypeIsOnTheBuiltItem`, knk-api-client `ItemAppearanceMapperTest.blueprintJsonCarriesThePotionType_868`]
    A1 buys a Splash Potion of Healing II and a Potion of Regeneration and looks at them. **Expected:** a pink splash
    potion "Splash Potion of Healing II" (Instant Health II) and a regeneration potion, both usable; they are gone at the
    match end like the pearls. (§ 9.4)
15. [automated: knk-paper `SiegeShopTelemetryTest.aPurchaseIsOneEventWithEntryPriceAndPurchaseNumber_A11`, knk-web-api `TelemetryEventCatalogTests.EveryBaselineFamilyOfTheDesign_IsListedAsBaseline`]
    With diagnostic telemetry on, open the owner timeline for the test run. **Expected:** one `siege.shop_purchase`
    event per purchase with `entryId`, `categoryId`, `kind`, `price` and `purchaseNo` (the player's n-th purchase of
    that entry); refusals send none. (A11, P27)
16. [automated: knk-paper `SiegeShopMenuFeatureTest.withTheShopOffTheButtonIsHiddenAndTheActionsSaySo`, `SiegeCommandShopTest.withTheShopOffTheSubcommandIsHiddenAndSaysSo`, knk-api-client `SiegeMenuSeedContractTest`]
    Admin sets `siege.shop.enabled: false` (points stay on) and restarts; play a match. **Expected:** `/siege menu`
    looks exactly as before this phase (no Shop button), `/siege shop` says "The siege shop is not enabled on this
    server.", `shop` is not suggested after `/siege ` and not in `/siege help`; siege points work as in § 1. (flag off)
17. [partly automated: knk-paper `SiegeShopServiceTest.anotherModesShopIsUsedThroughTheSurvivalHook_P21`; by hand: everything, after the Survival merge]
    In a Siege Survival match (after the Survival branch has merged and registered its shop with the hook): A1 earns
    siege points from NPC kills, buys a pearl in `/siege shop`, then buys at a purchase point (clicking its block, or
    `/siege buy` in range) and rolls the Mystery Box. **Expected:** all three charge the same balance; `/siege shop`
    opens the siege shop even next to a purchase point. Manual: Survival is not merged. (A17, A25)
18. Admin sets `siege.shop.enabled: true` and `siege.points.enabled: false`, restarts. **Expected:** the server log
    says "siege.shop.enabled is on but siege.points.enabled is off: the siege shop needs siege points, so it stays off";
    the game behaves as in step 16. Manual: needs a restart.
19. Stop the API for a moment right before a match starts (or block its catalogue route), start the match, bring the
    API back within 10 s. **Expected:** `/siege shop` first says "The siege shop is still opening; try again in a
    moment.", then opens once the catalogue was read (two retries 5 s apart); if the API stays down, "The siege shop
    isn't available in this match." and the log has one warning. Manual: needs a real outage
    (`SiegeShopServiceTest.aFailedCatalogueReadIsRetriedTwice_thenTheMatchHasNoShop` covers the logic).

## 4. Phase 4: siege weapon unlocks with coins and title level (#869, tier:2)

*Built by L4 (2026-11-20, branches `claude/siege-shop-l4` in knk-web-api, knk-plugin and knk-web-app). 8 of 9 steps
fully or partly automated (tagged; API tests in xUnit, plugin tests in knk-core, knk-api-client and knk-paper, web app
tests in Playwright with a mocked API); every step can still be run by hand; manual steps not run yet. A full manual
run takes about 25 minutes; the untagged step and the by-hand parts about 15.*

### 4.0 Preconditions

1. Deployed: knk-web-api from the branch (or `next` once merged) with the migration `AddSiegeWeaponUnlockMinTitle`
   applied and restarted once (it seeds the menu `siege.unlocks` and adds the **Siege unlocks** button to
   `siege.overview`, also on a database seeded before, once); knk-plugin and knk-web-app from the same branch. No
   deploy order: the button uses only engine ids and stays hidden until the plugin has validated `siege.unlocks`.
   In the web app's Entity setup, import the form seed **SiegeWeaponTemplate - Default (seed v2)** and make it the
   default (it adds "Minimum title to unlock").
2. Settings: none in `config.yml` (no flag). The trebuchet template with unlock price 1000 coins and **Minimum title to
   unlock** set to the title above A1's; the ballista with 500 coins and no minimum; a third template (for example the
   catapult) with 800 coins and no minimum. For step 6 a Ready Siege scenario and a shop entry for the ballista (§ 2
   step 7), with `siege.points.enabled`, `siege.shop.enabled` and `siege.weapons.enabled` on.
3. Accounts and data: A1 with 1200 coins, a linked web account, and none of the three types unlocked.

### 4.1 Steps

1. [partly automated: knk-web-api `MenuTemplateSiegeSeedTests.Overview_HasASiegeUnlocksButton_OpeningTheUnlocksMenu_869`, `SiegeWeaponUnlockPurchaseServiceTests.Overview_ListsEveryTemplate_WithPriceMinimumTitleAndState`, knk-core `SiegeUnlockRowViewTest.anUnlockableRowSaysThePrice_andAsksToConfirm`, `SiegeUnlockRowViewTest.theOtherStatesSayWhy_andGoStraightToTheAction`, knk-paper `SiegeUnlocksMenuFeatureTest.rowsListEveryTemplateWithTheViewersState_A27`, knk-api-client `SiegeMenuSeedContractTest`; by hand: the real menus]
   Outside a match A1 types `/menu`, clicks the **Siege Minigame** tile (the minigames tile), then **Siege unlocks**
   (anvil, top left). **Expected:** the Siege unlocks menu: the header says "Coins: 1200" and A1's title; one line per
   template with "Unlock price: N coins", "Minimum title: …" and its state: the ballista "Unlock for 500 coins", the
   catapult "Unlock for 800 coins", the trebuchet "Needs title <title>". (A27)
2. [automated: knk-web-api `SiegeWeaponUnlockPurchaseServiceTests.Purchase_BelowTheMinimumTitle_IsRefused_AndChargesNothing_A27`, knk-paper `SiegeUnlocksMenuFeatureTest.aRefusalIsShown_A27`]
   A1 clicks the trebuchet. **Expected:** no confirmation; chat says "You need the title <title> to unlock the
   Trebuchet."; A1 still has 1200 coins. (A27)
3. [partly automated: knk-web-api `SiegeWeaponUnlockPurchaseServiceTests.Purchase_ChargesTheUnlockPriceOnce_UnderTheSpecKey_AndWritesTheUnlock`, `SiegeWeaponUnlockPurchaseServiceTests.Purchase_ADoubleClick_ChargesOnce_A27`, knk-paper `SiegeUnlocksMenuFeatureTest.aPurchaseGoesToTheApi_andDropsTheCachedRows`, `SiegeUnlocksMenuFeatureTest.aSecondClickWhileTheFirstRunsSendsNothing_A27`; by hand: the confirm buttons]
   A1 clicks the ballista. **Expected:** chat asks "Unlock the Ballista for 500 coins? Click Confirm in the menu." and
   Confirm (lime) and Cancel (red) appear in the header. A1 double-clicks **Confirm** fast. **Expected:** chat says
   "Unlocked the Ballista for 500 coins. You can buy it in siege matches now."; the ballista line says "Unlocked";
   the header says "Coins: 700"; in the web app's balance log A1 has one `SIEGE_UNLOCK` posting of 500 with key
   `siege-unlock:<ballista id>:<A1 id>`, and the catapult now says "Not enough coins: 700/800". (A27)
4. [automated: knk-web-api `SiegeWeaponUnlockPurchaseServiceTests.Purchase_WithoutEnoughCoins_IsRefused_AndChargesNothing_A27`, `SiegeWeaponUnlockPurchaseServiceTests.Purchase_ADoubleClick_ChargesOnce_A27`]
   A1 clicks the catapult, then the ballista again. **Expected:** "Not enough coins to unlock the Catapult: 700/800."
   and "You have already unlocked the Ballista."; nothing charged (still 700). (A27)
5. [automated: knk-paper `SiegeUnlocksMenuFeatureTest.duringAMatchNothingIsBought_andTheMenuSaysSo_A28`, knk-core `SiegeUnlockRowViewTest.duringAMatchNothingIsUnlockable_A28`]
   Give A1 another 800 coins (staff grant). A1 joins a match and, once it is running, opens `/menu` → Siege Minigame →
   Siege unlocks and clicks the catapult. **Expected:** the header and the catapult line say "Siege weapons can't be
   unlocked during a match. Unlock them after it."; no confirmation; the same line in chat; coins unchanged. (A28)
6. [partly automated: knk-paper `SiegeShopServiceTest.aLockedWeaponShowsWhereToUnlockIt_andCantBeBought_A26`, knk-core `ShopPurchaseServiceTest.aLockedWeaponIsRefusedAndShownLocked_andWeaponsWaitForTheirHandler_A26`; by hand: the real shop]
   In that match A1 opens `/siege shop` → Siege weapons. **Expected:** the ballista entry is not locked (unlocks are
   read at match start; until siege weapons phase 3, #784, a click says "Siege weapons can't be bought yet."); an entry
   for a type A1 hasn't unlocked says "Locked: unlock it in /menu → Siege Minigame → Siege unlocks." (A26)
7. [automated: knk-web-app `e2e/siege-unlocks.spec.ts` "lists every weapon type with price, minimum title and state (A27)", knk-web-api `SiegeWeaponUnlockPurchaseServiceTests.Controller_Mine_NeedsAWebUser`]
   After the match, on the web app A1 opens their account page (`/account`). **Expected:** a **Siege
   unlocks** panel with "Coins: …", A1's title and the same list: the ballista "Unlocked", the trebuchet "Needs title
   …", the catapult with an "Unlock for 800 coins" button. (A27)
8. [automated: knk-web-app `e2e/siege-unlocks.spec.ts` "unlocking asks to confirm, then charges once even on a double click (A27)", "cancel leaves everything as it was", "the API's refusal is shown and nothing changes (A27)", knk-web-api `SiegeWeaponUnlockPurchaseServiceTests.Controller_AWebUser_BuysForThemselves`, `SiegeWeaponUnlockPurchaseServiceTests.Controller_AWebUser_CannotBuyForAnotherPlayer`]
   A1 clicks **Unlock for 800 coins**, then **Cancel**; then again, and double-clicks **Confirm: unlock for 800
   coins**. **Expected:** Cancel charges nothing; the confirm charges 800 coins once, says "Unlocked the Catapult for
   800 coins. You can buy it in siege matches now." and the catapult says "Unlocked". In game, the Siege unlocks menu
   shows the catapult unlocked as well (within 5 seconds of reopening). (A27)
9. [manual]
   Admin opens the trebuchet template in the web app, clears **Minimum title to unlock**, and saves; A1 reopens the
   in-game Siege unlocks menu. **Expected:** the trebuchet says "Minimum title: none" and, with enough coins,
   "Unlock for 1000 coins".

## 5. Phases 5a and 5b: menu item settings (#870, #871, tier:2)

*Phase 5a built by L5 (2026-11-20, branches `claude/siege-shop-l5` in knk-web-api and knk-web-app): § 5.1, 7 steps, all
fully or partly automated (tagged; API tests in xUnit, web app tests in Jest and Playwright with a mocked API); every
step can still be run by hand; manual steps not run yet. A full manual run of § 5.1 takes about 10 minutes. Phase 5b
built by L6 (2026-11-21, branch `claude/siege-shop-l6` in knk-plugin): § 5.2, 12 steps, 11 fully or partly automated
(tagged; plugin tests in knk-core, knk-api-client and knk-paper with Mockito and MockBukkit); every step can still be run
by hand; manual steps not run yet. A full manual run of § 5.2 takes about 30 minutes (it needs a PvP siege round); the
untagged step and the by-hand parts about 20.*

### 5.0 Preconditions

1. Deployed: knk-web-api from the branch (or `next` once merged) with the migration `AddMenuItemSettings` applied;
   knk-web-app from the same branch. For § 5.2: knk-plugin with phase 5b (#871) and phase 3 (#868) for the shop target.
2. Settings: none to set. The menu item section starts at the seeded defaults: today's `menus.menu-item.*` look
   (nether star, `&6&lMenu &7(click to open)`, slot 8) with every click opening `main`; overrides for Siege match and
   Siege Survival match (left and right click → `siege.information`, shift + right click → `siege.shop`) and Siege hub
   (left and right click → `siege.information`).
3. Accounts and data: Admin (web app staff with `knk.admin.config`); for § 5.2 A1 online in the hub, plus enough
   players (or the test lobby's minimum) to start a PvP siege round with A1 in it.
4. For § 5.2 step 6's shop: `siege.points.enabled: true` and `siege.shop.enabled: true` in the plugin's `config.yml`
   (§ 3.0); without them the shift + right click answers "The siege shop is not enabled on this server.", which is
   also a pass for the menu item.

### 5.1 Steps: the Menu item card (phase 5a)

1. [automated: knk-web-api `MenuItemSettingsTests.FreshDatabase_ReadsTodaysConfigDefaults_AndTheSiegeOverrides_A29`, `.ExistingRowWithoutTheColumn_OrUnreadableJson_ReadsTheDefaults`; knk-web-app e2e `menu-item-settings.spec.ts` "shows the seeded menu item …"; Jest `menuItemSettings.test.ts`]
   Admin opens Game settings and scrolls to the **Menu item** card. **Expected:** "Menu item enabled", "Give on join"
   and "Keep on death" on, "Droppable" and "Movable" off; Who gets it "All players"; Material `NETHER_STAR`; Name
   `&6&lMenu &7(click to open)`; Lore `&7Opens the Knights & Kings menu (&e/menu&7).`; Slot 8; the preview shows the
   coloured name and lore. Under **Clicks** all five clicks (Left click, Right click, Shift + left click, Shift + right
   click, Click in the inventory) are "Open menu" `main`. Under **Situation overrides**: Siege Survival match and Siege
   match with Left and Right click "Open menu" `siege.information`, Shift + right click `siege.shop`, the other clicks
   "Use default"; Siege hub with Left and Right click `siege.information`. (A29)
2. [automated: knk-web-api `MenuItemSettingsTests.Save_StoresLookClicksAndOverrides_AndReadsThemBack_A29`; knk-web-app e2e `menu-item-settings.spec.ts` "saves the look, a click and an override …"]
   Admin changes the Name to `&bKnK menu`, sets Shift + left click to "Run command" with `siege points`, sets Siege
   hub's Shift + right click to "Open menu" `siege.shop` (the key field offers `main`, `siege.information`,
   `siege.shop` and `siege.overview`), sets Siege match's Left click to "Use default", and saves. **Expected:** the card
   heading said "(changed)" before saving; "Game settings saved." and "No unsaved changes."; after a page reload the
   four changes are still there (Siege match keeps Right click and Shift + right click only). (A29)
3. [automated: knk-web-api `MenuItemSettingsTests.Save_DropsEmptyOverrides_AndAClickTableMayBeEmpty`; knk-web-app e2e `menu-item-settings.spec.ts` "removes an override and adds it back empty …"]
   Admin clicks **Remove Siege hub**, picks Siege hub under Situation, clicks **Add override** and saves without
   setting a click. **Expected:** the Siege hub override is shown with every click on "Use default"; after a reload
   it is gone (an empty override is not stored). Put it back as in precondition 2 and save. (A29)
4. [automated: knk-web-app e2e `menu-item-settings.spec.ts` "says what the API would refuse and keeps Save off"; Jest `menuItemSettings.test.ts` "lists what the API would refuse"]
   Admin types `Siege Shop` as Left click's menu key and 40 as Slot. **Expected:** under the card "Slot must be 0 to
   35." and "Left click: "Siege Shop" is not a menu key (…)"; Save is off. Discard the changes.
5. [automated: knk-web-api `MenuItemSettingsTests.Save_WithABadValue_IsRefusedWithTheReason_AndNothingChanges` (15 cases); knk-web-app e2e `menu-item-settings.spec.ts` "a refused save shows the API reason in the header"]
   As Admin, send `PUT api/GameSettings` (Swagger) with the current settings and `menuItem.clicks` containing
   `"MIDDLE_CLICK": {"type": "OpenMenu", "menuKey": "main"}`. **Expected:** 400 with "menuItem.clicks: 'MIDDLE_CLICK'
   is not a click type (…)"; nothing saved. The same for an unknown situation (`arena.duel`), an action type
   `Teleport`, Run command without a command, Who gets it `java`, or a material `nether star`.
6. [automated: knk-web-api `MenuItemSettingsTests.SavingTheSection_TellsTheGameServerToReload_A29`; by hand: the plugin's reload is § 5.2 step 1]
   Admin saves a change on the card while a game server is connected. **Expected:** the API sends
   `GameSettingsChanged` (scope `Game`) over the realtime channel, the event the plugin already reloads the game
   settings on. What players see is § 5.2 step 1, after phase 5b. (A29)
7. [automated: knk-web-api `AddMenuItemSettingsTests.Up_AddsOneNullableJsonColumnOnGameSettings_AndNothingElse`, `.Down_DropsOnlyThatColumn`]
   On a copy of a database from before the migration, apply `AddMenuItemSettings` and open Game settings.
   **Expected:** the migration only adds the nullable `game_settings.MenuItemSettingsJson`; the card shows the seeded
   defaults of step 1.

### 5.2 Steps in game (phase 5b, #871)

1. [automated: knk-api-client `GameSettingsMenuItemMapperTest.theSectionIsRead`; knk-paper `GameSettingsManagerMenuItemTest.everyApiAnswerPassesTheSectionOn_A29`, `MenuItemSettingsSyncTest.theApiSettingsReplaceTheFile_AndTheClicksFollowThem_A29`]
   With the API up and the card at the seeded defaults (§ 5.0 precondition 2), restart the game server and read its log.
   **Expected:** first `Menu item on (NETHER_STAR in slot 8, for ALL players) from config.yml until the game settings
   answer`, then within a few seconds `[MenuItem] Settings from the game settings page applied: NETHER_STAR in slot 8,
   for ALL players, 3 situation override(s)`. No `[MenuItem]` warning. (A29)
2. [automated: knk-paper `MenuItemSettingsSyncTest.aNewLookReachesOnlinePlayersWithoutARestart_A29`, `MenuOpenerServiceTest.liveAnOutdatedItemIsReplacedWhereItIs_AndNothingIsGivenOrMoved`, `GameSettingsManagerMenuItemTest.everyApiAnswerPassesTheSectionOn_A29`]
   A1 is online with the item in slot 8 and a sword in slot 0. Admin sets the card's Name to `&bKnK menu` and saves.
   **Expected:** within a few seconds (the realtime `GameSettingsChanged` event; without the realtime hub at the next
   game settings re-read) A1's item shows the new name, still in slot 8; the sword stays in slot 0; no restart; the log
   repeats the "applied" line. (A29)
3. [automated: knk-paper `MenuItemActionRunnerTest.aCommandIsRunByThePlayer_AndNoneDoesNothing`, `MenuItemSettingsSyncTest.theApiSettingsReplaceTheFile_AndTheClicksFollowThem_A29`]
   Admin sets Shift + left click to "Run command" `siege points` and saves. Outside a siege A1 sneaks and left-clicks
   with the item. **Expected:** the same answer as typing `/siege points` (with siege points off or outside a match it
   says so); the main menu does not open. (A29)
4. [automated: knk-core `MenuItemActionResolverTest.outsideASiegeEveryClickOpensTheMainMenu_A30`; knk-paper `MenuItemActionRunnerTest.theMainMenuOpensThroughSlashMenuAsBefore`, `MenuOpenerListenerTest.rightAndLeftClicksInTheAirOpenTheMenu`, `.aDoorKeepsWorkingUnlessThePlayerSneaks`, `.aClickOnItInTheOwnInventoryOpensTheMenuAndMovesNothing`]
   Outside a siege A1 right-clicks in the air, then left-clicks, then opens the inventory and clicks the item, then
   right-clicks a door (not sneaking). **Expected:** the main menu (as `/menu`) each of the first three times; the door
   just opens. (A30)
5. [automated: knk-paper `SiegeMenuItemSituationsTest.aRunningMatchIsSiegeMatch_TheHubAndTheResultAreSiegeHub_AnythingElseIsNone`; knk-core `MenuItemActionResolverTest.atTheSiegeHubLeftAndRightOpenTheSiegeMenu`]
   A1 joins a PvP siege lobby (`/siege join <lobby>`). While matchmaking A1 right-clicks the item; once the round is at
   the scenario hub (team split) A1 right-clicks and left-clicks it again. **Expected:** while matchmaking the main
   menu (no situation yet); at the hub the siege **Information** menu of A1's lobby both times.
6. [automated: knk-core `MenuItemActionResolverTest.inAPvpMatchClicksOpenTheSiegeMenuAndShiftRightTheShop_A30`; knk-paper `MenuOpenerListenerTest.inAMatchAClickOpensTheSiegeMenuAndShiftRightTheShop_A30`, `MenuItemActionRunnerTest.theSiegeMenusOpenThroughTheirCommands_WhichKnowTheMatch`]
   In the running match A1 right-clicks the item, left-clicks it, sneaks and right-clicks it (also on a door), then
   sneaks and left-clicks it. **Expected:** right and left click open the siege **Information** menu; shift + right
   click opens the **siege shop** (as `/siege shop`: right after the start it may say "The siege shop is still opening;
   try again in a moment."); shift + left click runs `siege points` from step 3 (with the seeded table it would open
   the main menu, as `/menu` does in a match). (A30)
7. [automated: knk-paper `SiegeMenuItemSituationsTest.aRunningMatchIsSiegeMatch_TheHubAndTheResultAreSiegeHub_AnythingElseIsNone`]
   After the match ends normally A1 is back at the scenario hub with the result; A1 right-clicks the item; after the
   post-match time (or `/siege leave`) A1 right-clicks it again. **Expected:** first the siege Information menu (the
   result), then the main menu.
8. Siege Survival match (#41): **skip until Siege Survival is merged.** Its branch provides the
   `siege.survival.match` check at its merge; then in a running Survival match right click opens `siege.information`
   and shift + right click the siege shop, as in step 6 [automated once there: knk-core
   `MenuItemActionResolverTest.inASurvivalMatchTheSameOverrideApplies_A30`]. (A30)
9. [automated: knk-paper `MenuOpenerServiceTest.liveSwitchedOffTakesItAway`, `.liveAMissingItemIsNotGiven_AndAnUnchangedOneStays`, `.switchedOffTakesItAway`, `.aJoiningPlayerGetsItInTheConfiguredSlot`]
   Admin switches "Menu item enabled" off and saves. **Expected:** within a few seconds A1 no longer has the item.
   Admin switches it on again and saves. **Expected:** nothing is given while A1 plays; A1 gets it back at the next
   rejoin or respawn, in slot 8. (A29)
10. [automated: knk-core `MenuOpenerPlacementTest` (a pinned item found in another slot moves back); knk-paper `MenuOpenerServiceTest.thePlayersOwnItemMovesAsideAndIsKept`]
    Admin sets Slot to 4 and saves. **Expected:** A1's item stays in slot 8 while A1 plays (nothing is moved
    mid-fight); after A1 rejoins it is in slot 4 and whatever A1 had in slot 4 moved to a free slot. Put Slot back to
    8 and the Name and Shift + left click back to the seeded values, and save.
11. [automated: knk-paper `MenuItemSettingsSyncTest.withTheApiDownAtStartupTheConfigFileSettingsStay_AndEveryClickRunsSlashMenu_A31`, `GameSettingsManagerMenuItemTest.withTheApiDownAtStartupTheCachedSectionIsNotUsed_SoConfigYmlStays_A31`, `MenuOpenerListenerTest.withTheConfigFileSettingsAShiftClickOpensTheMenuAsBefore_A31`; knk-core `MenuItemActionResolverTest.theConfigFileSettingsNeverAskForASituation_A31`, `MenuOpenerSettingsTest.theFileShapeOpensTheMainMenuOnItsClicks_AndAShiftClickIsThePlainClick_A31`]
    Set `menus.menu-item.name` in the plugin's `config.yml` to `&eFile menu` (to tell the two apart), stop the API,
    restart the game server and join as A1. **Expected:** the log shows `Menu item on (...) from config.yml until the
    game settings answer` and no "applied" line; A1 has the item named `&eFile menu` in the `config.yml` slot; every
    click (right, left, either while sneaking, in the inventory) opens the main menu, exactly as before #871. (A31)
12. Start the API again and wait for the next game settings read (`game-settings.refresh-interval-seconds`, or the
    realtime reconnect). **Expected:** the "applied" line of step 1; A1's item takes the card's name in place without a
    rejoin. Put `menus.menu-item.name` back in `config.yml`.
