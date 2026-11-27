# Siege weapons — smoke test

**Status:** § 1 updated to phase 1 as built (link L1, #782): 2 of its 11 steps automated, 8 partly, not run live yet;
§ 2 rewritten for spots as WorldGuard regions (#988, developer decision 2026-11-22; replaces L2b's spot task): 2 of its
9 steps automated, 7 partly, not run live yet; § 3–9 draft
from the design (2026-11-19), no steps run. Every step can still be run by hand.
**Last updated:** 2026-11-22 (§ 2 rewritten for spots as WorldGuard regions and § 1 step 7 changed, #988, steps tagged); 2026-11-19 (§ 2 rewritten to the web-form world task of link L2b, #799, steps tagged); 2026-11-19 (§ 2 updated to what link L2 built, steps tagged); 2026-11-19 (§ 1 updated to what link L1 built, steps tagged); 2026-11-19 (draft from the design,
phases 1–9)
**Design:** [specs/siege-minigame/SIEGE_WEAPONS.md](../specs/siege-minigame/SIEGE_WEAPONS.md) · **Issue:**
[PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354)

Accounts used throughout: **Admin** (web app staff with `knk.admin.content`, `knk.admin.world` and
`knk.siege.admin.manage`, op in game),
**A1** and **A2** (two players on the attacking team), **D1** (a player on the defending team). Write down any step
that fails, with the server log lines.

## 1. Phase 1: entities, API, form seeds and unlocks (#782, tier:3)

*Updated to what was built (link L1, 2026-11-19): 2 of 11 steps automated in CI, 8 partly (tagged); every step can
still be run by hand; not run live yet. A full manual run takes about 25 minutes, the untagged step about 5. The tests
named here are in knk-web-api `Tests/knkwebapi_v2.Tests/` and knk-web-app `e2e/` and `src/`.*

### 1.0 Preconditions

1. Deployed: knk-web-api from `next` with the phase 1 migration `AddSiegeWeapons` applied (`dotnet ef database
   update`); knk-web-app from `next`.
2. Settings: none (no flag, no config key: phase 1 is data only).
3. Accounts and data: Admin with `knk.siege.admin.manage` and `knk.admin.content` (create and edit need both; deleting
   also needs `knk.admin.delete`); a second staff account with `knk.admin.content` only; players A1 and A2 with web
   accounts; one Siege scenario with two teams (attackers and defenders) that was Ready before the migration.

### 1.1 Steps

1. [partly automated: FormConfigurationSeedFilesTests (every seed dry-runs and imports in dependency order); by hand:
   the import panel] As Admin, open Form configurations → Import / seeds and import, in this order, `SiegeAmmoType`,
   `SiegeWeaponTemplateAmmoType.join`, `SiegeWeaponTemplate`, `SiegeWeaponSpot` and `UserSiegeWeaponUnlock`, each with
   "make default". If the database imported `SiegeScenario` and `SiegeTeam` before this phase, add by hand in the form
   designer what their seed files gained (import never overwrites): the scenario's "Siege weapons" step before
   "Readiness" (Friendly fire, Spot cooldown override, the owned Weapon spots list) and the team's "Active weapon spots"
   field at the end of "Role and alliance". **Expected:** the five new forms are listed as defaults; the scenario and
   team forms show the new step and field. (A01)
2. [partly automated: e2e/siege-weapons.spec.ts "saves an ammo type with its structure damage", SiegeWeaponServiceTests
   `AmmoType_SavesEveryField_IncludingStructureDamage`; by hand: the seeded four-step form] As Admin, open the dashboard
   → Siege ammo type → Create and make "Heavy boulder": effect Impact, player damage 12, structure damage 120, blast
   radius 2, knockback 1, armour piercing 0, projectile block STONE, price per shot 20. **Expected:** it saves and the
   ammo type list shows it with effect, damage, structure damage, radius and price. (A01)
3. [partly automated: e2e/siege-weapons.spec.ts "saves a weapon template", SiegeWeaponServiceTests
   `Template_SavesEveryField_AndTheAmmoLink`; by hand: the seeded form's steps and its Ammo join step] As Admin, create
   the template "Trebuchet": kind Indirect, size Large, max health 400, build time 60 s, reload 20 s, max range 120, min
   range 20, start spread 8, minimum spread 3, ranging step 1.5, flight time 4 s, arc height 30, gate multiplier 1,
   weapon multiplier 1, spot cooldown 120 s, match price 800, unlock price 5000, and on the Ammo step add a join entry
   for "Heavy boulder". **Expected:** it saves; reopening shows the same values and the ammo link; the template list
   shows kind, size, prices and 1 ammo type. (A01)
4. As Admin, start a template "Ballista" and switch the kind between Indirect and Direct (manual: display conditions
   of the seeded form). **Expected:** "Spread and flight" shows only for Indirect, "Firing cone" (default 60) only for
   Direct; a Direct template with gate multiplier 3 saves. (A01)
5. [partly automated: SiegeWeaponServiceTests `Template_RefusesBadValues`; by hand: the message in the wizard] As Admin,
   try to save a template with a minimum spread larger than its start spread, and one with a min range above its max
   range. **Expected:** each is refused with a message naming the field (`minSpreadRadius can't be larger than
   startSpreadRadius`, `minRange must be below maxRange`); nothing is saved. (A01)
6. [partly automated: SiegeWeaponServiceTests `Scenario_FriendlyFireAndCooldownOverride_TeamActiveSpots_Save`; by hand:
   the scenario and team forms] As Admin, open the scenario: on "Siege weapons" leave Friendly fire off and the spot
   cooldown override empty; open the attacker team and set Active weapon spots to 2. **Expected:** the values save;
   the defender team still shows 0. (A01)
7. [partly automated: SiegeWeaponServiceTests `Spot_IsCreatedUnderItsScenario_AndShowsOnTheScenario`,
   `Spot_TeamMustBelongToTheScenario`, `Spot_RegionTheGameServerDoesntKnow_IsRefused`,
   src/apiClients/__tests__/siegeWeaponClients.test.ts; by hand: the owned list in the wizard] As Admin, on the
   scenario's "Siege weapons" step use Create New: team = the attackers (the picker lists only this scenario's teams),
   name "North wall", facing North; on "Place and size" pick the existing region `siegespot_test` (§ 2.0) with **Send to
   Minecraft** on Region and `select siegespot_test` in game, or type `siegespot_test` in the Region field. The form has
   no bounds fields and Size class is read-only (#988). **Expected:** the spot saves (`POST
   api/SiegeScenarios/{id}/weapon-spots`) and shows in the step's list with size class Small; a region name that
   doesn't exist on the game server is refused ("Region '…' doesn't exist on the game server" or the plugin's "No
   WorldGuard region …"). Needs the game server connected to the API; § 2 covers the region in detail. (A01)
8. [partly automated: SiegeWeaponServiceTests `Unlock_IsListedForThatPlayerOnly_AndOncePerType`; by hand: the form]
   As Admin, open the dashboard → User siege weapon unlock → Create: player A1, weapon type "Trebuchet", unlocked at
   empty. (Players buying an unlock with coins is not built in this phase.) **Expected:** A1's unlocks list
   "Trebuchet" with today's date (`GET api/UserSiegeWeaponUnlocks/by-user/<A1 id>`); A2's don't; a second unlock of
   Trebuchet for A1 is refused with "already unlocked". (A01)
9. [partly automated: SiegeWeaponServiceTests `AmmoType_AllowedOnATemplate_CantBeDeleted`,
   `Template_WithUnlocks_CantBeDeleted_WithoutItCascadesItsAmmoLinks`; by hand: the dashboard message] As Admin (with
   `knk.admin.delete`), try to delete "Heavy boulder" and then "Trebuchet". **Expected:** both are refused: the ammo
   type names the Trebuchet that allows it, the template says players have unlocked it. (A01)
10. [automated: e2e/siege-weapons.spec.ts "content-only staff do not get the siege weapon types"] Log in as the staff
    account with `knk.admin.content` only and open the dashboard. **Expected:** no Siege weapon template, ammo type or
    unlock type in the list. (A01)
11. [automated: AddSiegeWeaponsTests `Up_NewColumns_DefaultToTheOldBehaviour`, the existing Siege suites] Open the
    scenario that was Ready before the migration and press Re-check on "Readiness". **Expected:** still Ready; existing
    scenarios have Friendly fire off, no cooldown override and 0 active weapon spots, so their matches play as before.

## 2. Phase 2: spots as WorldGuard regions (#783, #799, #988, tier:3)

*Rewritten for #988 (developer decision 2026-11-22, spec W76): 2 of 9 steps automated in CI, 7 partly (tagged); every
step can still be run by hand; not run live yet. A full manual run takes about 20 minutes. The tests named here are in
knk-web-api `Tests/knkwebapi_v2.Tests/` (`Services/SiegeWeaponServiceTests`, `Services/SiegeWeaponSpotRegionTests`,
`Services/ValidationMethods/SiegeWeaponSpotValidatorTests`, `Services/Regions/GameRegionQueryClientTests`,
`Realtime/RealtimeHubTests`, `Services/FormConfigurationSeedFilesTests`), knk-plugin `knk-core/src/test/.../core/`
(`regions/query/RegionQueryAnswersTest`, `siege/weapons/`) and `knk-paper/src/test/.../paper/`
(`realtime/RegionQueryRealtimeSyncTest`, `siege/weapons/SiegeWeaponsSettingsTest`), and knk-web-app
`e2e/siege-weapons.spec.ts` and `src/components/FormWizard/__tests__/FormWizard.validationMessages.ui.test.tsx`.*

A spot **is a WorldGuard region**. In the web app's weapon spot form, "Place and size" has three fields: **Region**
(required) with the normal region world task (`ReagionCreate`: "Send to Minecraft", claim it in game with
`/knk task <code>`, then draw a box with WorldEdit and type `save`, or type `select <region>`), **Facing** (picked in the
form) and **Size class** (read-only). Two rules sit on Region: the **size check** (blocking) shows the class for the
facing, or "too small", before Submit; the **site check** (a warning) says when the floor under the region isn't solid
or its space isn't clear. Both ask the game server over the game hub; the API works the class out again on save. A
region drawn in the form is renamed to `siege_spot_<id>` on save. The custom `SiegeWeaponSpot` task of #799 and the six
bounds fields are gone.

### 2.0 Preconditions

1. Deployed: phase 1; knk-web-api, knk-web-app and knk-plugin from `next` with #988; the API migration
   `DropSiegeWeaponSpotBounds` applied (`dotnet ef database update`; only `next` test databases have the columns).
2. Settings: API `RegionQueries:Enabled` on (the default; `RegionQueries:TimeoutSeconds` 5); plugin
   `siege.weapons.enabled: true` under `siege:` in `config.yml`, then a restart (step 1 starts with it `false`). The
   game server is connected to the API's realtime hub (its log says so at startup).
3. Accounts and data: Admin in the web app and in game with `knk.siege.admin.manage` and WorldEdit; the scenario from
   § 1 with an attacker and a defender team, its town in the world you draw in; the `SiegeWeaponSpot` form seed as of
   #988 (a database that imported it before: delete "SiegeWeaponSpot - Default (seed v1)" and import it again, or make
   the form-designer changes in the changelog's admin steps); flat open ground with a solid floor; a WorldGuard cuboid
   region of 7 × 5 × 9 blocks (x × y × z) on open ground named `siegespot_test`.

### 2.1 Steps

1. [partly automated: SiegeWeaponsSettingsTest `flagOff_RegistersNoSiteCheck_SoTheApiGetsNoAnswer`,
   `theBundledConfig_HasTheFlag_Off`, SiegeWeaponSpotValidatorTests `Site_GameServerOfflineOrFlagOff_PassesWithAFailureReason`;
   by hand: the live form] With `siege.weapons.enabled: false` (the default), open the scenario in the web app, go to
   its "Siege weapons" step, create a spot, choose the attacker team, name it `Test north`, go to "Place and size" and
   type `siegespot_test` in Region, then click elsewhere. **Expected:** the form shows "Size class Small: the region is
   7 wide x 9 long x 5 high facing North." and, in an amber box, "Validation could not be completed" with "Floor and
   space not checked: No answer from the game server within 5 s … The game server answers only with
   siege.weapons.enabled on."; the startup log has no "Siege weapons are on" line. Set the flag to `true` and restart.
   **Expected:** the log says "Siege weapons are on (siege.weapons.enabled): the weapon spot site check
   (SpotSiteCheckQuery) is answered."; back in the form, **Re-run validation** now says "The floor is solid and the
   space is clear." (A04 for this phase)
2. [partly automated: e2e `draws the region with the region task, shows the size class for the facing and the site
   warning, and saves the spot` (the task is created for Region with type ReagionCreate), FormConfigurationSeedFilesTests
   `SiegeWeaponSpotSeed_DrawsItsRegionThroughTheRegionTask_WithTheSizeAndSiteRules`; by hand: the claim and the drawing
   in game] Clear Region and click **Send to Minecraft** on it. Claim the code in game with `/knk task <code>`.
   **Expected:** the game says "[WorldTask] Define a WorldGuard region." with the `save` and `select` options. Select an
   area 7 blocks along x (east-west), 5 high and 9 along z (north-south) on open ground with the WorldEdit wand
   (`//sel cuboid`), its bottom on the layer a weapon stands on, and type `save`. **Expected:** "Region created:
   tempregion_worldtask_<id>" and "✓ Task completed!"; within a few seconds the web form's Region shows
   `tempregion_worldtask_<id>`, the size check says "Size class Small: … 7 wide x 9 long x 5 high facing North." and the
   site check "The floor is solid and the space is clear." (A02)
3. [partly automated: SiegeWeaponSpotValidatorTests `Size_ShowsTheClassForTheFacing`,
   `Size_TooSmall_Fails_WithTheReason`, SiegeWeaponServiceTests `Spot_RegionSmallerThanTheSmallClass_IsRefused`, e2e
   (the class changes with the facing); by hand: the live form] Set Facing to East and click into Region and out again
   (or **Re-run validation**). **Expected:** the size check says "The region is too small for a weapon facing East: 9
   wide x 7 long x 5 high, the small class needs at least 7 wide x 9 long x 5 high." and Submit is refused with it in the
   list of problems. Set Facing to South. **Expected:** "Size class Small … facing South." again. (A02)
4. [partly automated: SiegeWeaponServiceTests `Spot_SizeClass_IsWorkedOutFromTheRegionAndFacing_NotTheGivenValue`,
   `Spot_DrawnRegion_IsGivenItsFinalNameOnSave_AndAReRunReplacesTheOldOne`, SiegeWeaponSpotRegionTests
   `DrawnRegion_IsRenamedToSiegeSpotAndId_InTheScenariosWorld`, e2e (the save without bounds); by hand: the live round
   trip and the rename in WorldGuard] Click **Submit**. **Expected:** the spot "Test north" is listed on the scenario's
   "Siege weapons" step with the attacker team, facing South and size class Small; reopening it shows Region
   `siege_spot_<id>`; in game, `/rg info siege_spot_<id>` shows the box you drew and `/rg info
   tempregion_worldtask_<id>` says the region doesn't exist. (A02)
5. [automated: SiegeWeaponSpotValidatorTests `Size_TooSmall_Fails_WithTheReason`,
   `BothRules_TooSmallAndAWarning_TheBlockingSizeReasonIsShown_NotTheSiteReason`, SiegeWeaponServiceTests
   `Spot_RegionSmallerThanTheSmallClass_IsRefused`, e2e `a region smaller than the small class blocks Submit with the
   reason`] Create a second spot `Tiny`, draw a 5 × 5 × 5 box through its Region task and try to Submit. **Expected:**
   the size check says "The region is too small for a weapon facing North: 5 wide x 5 long x 5 high, the small class
   needs at least 7 wide x 9 long x 5 high."; Submit is refused and no spot is saved. Discard the draft. (A03)
6. [partly automated: SiegeWeaponsSettingsTest `flagOn_AnswersTheSiteCheck_FromTheWorldsBlocks`, SpotSiteCheckTest,
   RegionQueryAnswersTest `siteCheck_CarriesTheCountsAndWarnings`, e2e (the warning on the region field); by hand: real
   terrain] Create a spot `Edge` for the defenders and draw a 7 × 5 × 9 box that hangs partly over a drop and has one
   solid block inside. **Expected:** under Region, a warning (not an error) "The floor isn't solid: n of 63 blocks under
   the spot are air or not solid, so a weapon would hang in the air. The volume isn't clear: 1 blocks inside the spot
   would be replaced by the weapon (they come back when it is removed)."; Submit saves the spot anyway. (A02)
7. [partly automated: SiegeWeaponSpotValidatorTests `Size_APolygon_CountsAsItsBoundingBox_AndSaysSo`,
   SiegeWeaponSpotRegionTests `APickedRegion_IsLeftAlone`, RegionQueryRealtimeSyncTest; by hand: a polygon in game] Create
   a spot `Poly`, send its Region task, draw a polygon (`//sel poly`) whose bounding box is at least 7 × 5 × 9 and type
   `save`. **Expected:** the size check shows a class and adds "The region is a polygon; its bounding box counts, so
   draw a box to be sure the weapon fits."; nothing refuses it. Discard the draft. Then, for a picked region: create a
   spot `Region`, send its task and type `select siegespot_test`. **Expected:** Region shows `siegespot_test`; Submit
   saves it and the region keeps its name (no `siege_spot_<id>`). (A02)
8. [partly automated: SiegeWeaponServiceTests `Spot_GameServerOffline_KeepsTheGivenClass_AndSaves`,
   `Spot_ChangingTheFacing_WorksTheClassOutAgain`, GameRegionQueryClientTests `NoGameServer_SendsNothing`, Jest
   `FormWizard.validationMessages` (#988 case); by hand: the server stopped] Stop the Minecraft server. Open "Test
   north", set Facing to North and click into Region and out. **Expected:** both rules show the amber "Validation could
   not be completed" box ("Size class not checked: No game server is connected …"); Submit saves the spot and the size
   class stays Small (not checked; L3 checks it again before a weapon is placed). Start the server again; reopen and
   save: still Small. (#988 open point 1)
9. [automated: RealtimeHubTests `GameHub_RegionGeometryQuery_RoundTrip_TheResultAnswersTheClient`,
   `GameHub_SpotSiteCheckQuery_RoundTrip`, `GameHub_RegionQueryResult_IgnoredWhileOff`, `WebHub_CannotAnswerARegionQuery`,
   GameRegionQueryClientTests] Set `RegionQueries:Enabled` to `false` in the API settings and restart the API. Open
   "Test north" and re-run validation. **Expected:** both rules say "Region queries to the game server are switched off
   (RegionQueries:Enabled) …" in the amber box; Submit still saves. Set it back to `true` and restart.

## 3. Phase 3: buying, placement, paste, build phase and restore (#784, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: phases 1–2, siege points (#356), siege shop (#611), schematic pipeline (#614) with armed, fired and
   wreck schematics uploaded for "Trebuchet" and a ballista template.
2. Settings: `siege.weapons.enabled: true`.
3. Accounts and data: A1 (Trebuchet unlocked), A2 (no unlocks), D1; the scenario with two attacker spots (one Large,
   one Small) and Active weapon spots 2; a running match. Give A1 enough siege points with the admin command (or play
   until they have them).

### 3.1 Steps

1. Set `siege.weapons.enabled: false` and reload. As A1, open the siege shop. **Expected:** no siege weapons category;
   `/siege` weapon commands say the feature is off. Set it back to `true`. (A04)
2. As A2, open the siege shop's siege weapons category and choose the Trebuchet. **Expected:** refused: not
   unlocked. (A05)
3. As A1, choose the Trebuchet. **Expected:** the spot list shows only the attackers' free active spots that fit a
   Large weapon (not the Small one, not defender spots). (A05)
4. As A1 with fewer siege points than the price, pick the Large spot. **Expected:** refused with "not enough siege
   points"; the balance is unchanged. (A06)
5. Place a block inside the Large spot, then as A1 with enough points pick it. **Expected:** refused: the area isn't
   clear; no points taken. Remove the block. (A06)
6. Have A2 stand inside the Large spot. As A1, pick it. **Expected:** A2 is pushed to the spot's edge, the price is
   taken once, and the trebuchet appears rotated to the spot's facing. (A07)
7. Watch the weapon right after the paste. **Expected:** HP starts at 0 and rises evenly to max over the build time;
   right-clicking it while building says it isn't ready. (A08)
8. While a weapon is building, stop the server (kill the process) with the API also stopped. Start the server.
   **Expected:** the spot is restored to its original blocks from the local snapshot without the API; once the API
   is back, the plugin syncs without errors. (A12)
9. Place a weapon again and end the match with `/siege` admin stop. **Expected:** every weapon and wreck is removed
   and every spot shows its original blocks. (A13)

## 4. Phase 4: weapon damage, wreck, spot cooldown, info display and statistics (#785, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: phases 1–3.
2. Settings: `siege.weapons.enabled: true`; scenario Friendly fire off.
3. Accounts and data: A1, A2, D1; a running match with a built attacker weapon.

### 4.1 Steps

1. As D1, hit the attackers' weapon with a sword, then an arrow, then set fire next to it. **Expected:** each hit
   lowers its HP like a gate hit, with cracks growing as HP drops. (A09)
2. As A2, hit the same weapon. **Expected:** no damage (friendly fire off). Turn Friendly fire on for the scenario,
   start a new match and repeat. **Expected:** A2's hits now do damage. (A09)
3. As D1, keep hitting until HP reaches 0. **Expected:** destruction sound and particles, the wreck schematic replaces
   the weapon, and whoever was operating it loses the lease. (A10)
4. As A1, open the shop and try to place a weapon on the same spot. **Expected:** the spot is locked for the
   template's cooldown; the other attacker spot is still offered. After the cooldown, the wreck is cleared and the
   spot is free again. (A10)
5. Set a cooldown override on the scenario, destroy a weapon again. **Expected:** the override length is used. (A10)
6. Check A1's siege points after the weapon they bought was destroyed during and after its build. **Expected:** no
   refund in either case. (A11)
7. Stand near a weapon as A1, then as D1. **Expected:** A1 sees its info display (state, HP, reload); D1 sees nothing.
   (A14)
8. After the match, open the match's statistics. **Expected:** shots, hits, damage and kills per weapon and ammo type
   are recorded. (A35)

## 5. Phase 5: ballista direct fire (#786, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: phases 1–4.
2. Settings: `siege.weapons.enabled: true`.
3. Accounts and data: A1, A2, D1; a built attacker ballista with three bolt types (kinetic, explosive, incendiary);
   a defender gate in the cone; siege points for A1 and A2.

### 5.1 Steps

1. As A1, mount the ballista. **Expected:** A1 holds the lease. As A2, try to mount it. **Expected:** refused: in
   use. (A15)
2. As A1, scroll the mouse wheel. **Expected:** the bolt type cycles, the action bar shows bolt and price, and the
   hotbar slot doesn't change. (A16)
3. Aim outside the cone (more than the template's half-angle from the spot's facing) and fire. **Expected:** refused;
   no points taken. (A17)
4. Fire a kinetic bolt at D1 inside the cone. **Expected:** D1 takes only the ammo damage (no extra arrow damage) and
   is pushed along the bolt's flight; the arrow is removed and can't be picked up. (A18)
5. Fire at the defender gate. **Expected:** the gate loses structure damage × the ballista's gate multiplier. (A18)
6. Fire twice quickly. **Expected:** the second shot is refused until the reload ends; A1 paid once; the ballista
   shows its fired schematic until the reload ends. (A19)
7. Stay mounted without firing past the idle timeout. **Expected:** the lease ends with "lease ended: idle"; A2 can
   now mount. Also check death, leaving the match and walking away end it. (A20)
8. Kill D1 with a bolt. **Expected:** A1 gets the kill, full siege points and streak progress. (A21)
9. As D1, try to mount the attackers' ballista. **Expected:** refused; D1 can damage it but never fire it. (A22)

## 6. Phase 6: trebuchet and catapult in game with aiming preview arc (#787, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 6.0 Preconditions

1. Deployed: phases 1–4.
2. Settings: `siege.weapons.enabled: true`.
3. Accounts and data: A1, A2, D1; a built attacker trebuchet with "Heavy boulder" and "Heavy bomb"; a defender
   building with a roof within range; siege points for A1.

### 6.1 Steps

1. As A1, right-click any block of the trebuchet. **Expected:** A1 holds the lease and gets two clickable chat
   choices: the targeting page link and "aim in game". (A23)
2. Choose "aim in game" and look at open ground within range. **Expected:** a particle arc runs from the trebuchet to
   a circle at that point, at the start spread; A2 standing next to A1 sees no arc. (A36)
3. Look at a point beyond max range, then closer than min range, then at the sky. **Expected:** the arc and circle
   switch to the warning colour and a click is refused with the reason. (A24, A36)
4. Scroll to change ammo and fire at a valid point. **Expected:** the action bar showed ammo and price; A1 pays once;
   the trebuchet swaps to fired. (A19, A24)
5. Watch the shot. **Expected:** a block display projectile flies the arc and lands after about the template's flight
   time; players near the impact hear a whistle on the way down. (A25)
6. Fire again at about the same point after each reload. **Expected:** the circle (preview and impacts) narrows by the
   ranging step down to the minimum spread. Aim far away, or let A2 take over. **Expected:** the spread is back at the
   start radius. (A26)
7. Have D1 stand under the defender building's roof inside the radius and fire at the roof. **Expected:** the shot
   lands on the roof; D1 takes nothing. Have D1 stand on the roof. **Expected:** D1 is hit. (A27)
8. Repeat steps 6.1.6 and 5.1.6–5.1.9 for the trebuchet (reload, idle, kill credit, enemies can't operate).
   **Expected:** the same results as for the ballista. (A19–A22)

## 7. Phase 7: ammo effects and spawn protection (#788, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 7.0 Preconditions

1. Deployed: phases 1–6 (siege fire #615 for ground fire).
2. Settings: `siege.weapons.enabled: true`.
3. Accounts and data: A1 operating a trebuchet and a ballista; D1 and D2 as targets, one in full Blast Protection IV
   armour, one unarmoured; a defender spawnpoint within range with a tower floor above it.

### 7.1 Steps

1. Fire a bomb so that D1 (armoured) and D2 (unarmoured) stand at the same distance. **Expected:** D1 takes clearly
   less; both are pushed away from the impact, weaker towards the edge. (A28)
2. Fire a boulder. **Expected:** full damage in a small core, then a steep drop; Projectile Protection helps. (A28)
3. Fire a fire bomb and an incendiary bolt. **Expected:** players in the area are set alight with no fall-off; ground
   fire appears where it has line of sight (with #615). (A28)
4. Fire a rotten carcass. **Expected:** everyone in the radius gets the same poison; armour doesn't help. (A28)
5. Raise one ammo type's armour-piercing factor and repeat step 7.1.1. **Expected:** D1's damage goes up. (A28)
6. Fire at the defender spawnpoint with D1 inside its safe zone and D2 on the floor above, outside the sphere.
   **Expected:** D1 takes no damage, poison, fire or knockback; D2 is hit. (A29)

## 8. Phase 8: page credential and API relay (#789, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 8.0 Preconditions

1. Deployed: phases 1–6, knk-web-api and knk-plugin from `next` with the SignalR hub connected.
2. Settings: `siege.weapons.enabled: true`; plugin key configured on both sides.
3. Accounts and data: A1 and A2; a built attacker trebuchet; a browser.

### 8.1 Steps

1. As A1, right-click the trebuchet and open the page link. **Expected:** the page opens and A1's targeting session
   starts. Open the same link again in another tab. **Expected:** refused: the token is used. (A30)
2. Wait more than five minutes after getting a new link before opening it. **Expected:** refused: expired. (A30)
3. Fire from the page. **Expected:** the shot happens in game within a moment; the page shows the reload. (A31)
4. Click fire on the page and "aim in game" fire at the same moment (A1 on two devices). **Expected:** at most one shot
   per reload, paid once. (A31)
5. Stop the plugin's SignalR connection (or stop the server) and press fire. **Expected:** the page says the server is
   unreachable; nothing fires and nothing is charged. (A34)

## 9. Phase 9: targeting mode on the map page and snapshot tiles (#790, tier:3)

*Draft from the design (2026-11-19); the link updates it to what was built and tags the automated steps.*

### 9.0 Preconditions

1. Deployed: phases 1–8, the tactical map (#613), the tile proxy, a rendered snapshot of the scenario.
2. Settings: `siege.weapons.enabled: true`.
3. Accounts and data: Admin, A1, A2, D1; a built attacker trebuchet.

### 9.1 Steps

1. As Admin, start the snapshot render for the scenario. **Expected:** the render finishes and the scenario shows the
   snapshot's date. (A33)
2. As A1, open the targeting page from the trebuchet. **Expected:** range rings (max and min), the targeting circle
   at the current spread, ammo types with prices, A1's siege points, the reload countdown and the fire button. (A32)
3. Move the circle over the defenders' spawn zone. **Expected:** the zone is shaded and "Be advised: projectiles don't
   harm players inside their spawn zone." shows; firing is still allowed. (A32)
4. Pan and zoom outside the scenario area, and request a tile URL outside it directly. **Expected:** the view stops at
   the area; the direct request is refused. (A33)
5. Request a tile without a credential (private window). **Expected:** refused. (A33)
6. Check the markers. **Expected:** A1 sees A2's live marker and gate and objective markers, never D1's. (A33)
