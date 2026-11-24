# Landmarks as a Domain subtype — smoke test

**Status:** §§ 1–5 built and merged into `next` (2026-11-22: knk-web-api `8cc4511b`, `55d187d8`, `3bc3cfd5`; knk-plugin `14645895`; knk-web-app `8c9c3553`), not run by the developer. Fix link L4b (2026-11-24, in review): Landmark form seed v4 (the warp step for every area kind, LD26) in §§ 1, 4 and 5, and § 3.2 carried over from the off-road guide (#1009). § 1 is tier:3: run it before `next` is promoted. Steps tagged by the links. The branch names in the section notes are the links' branches, now merged.
**Last updated:** 2026-11-24 (fix link L4b: seed v4 with the warp step for every area kind, LD26, #1003, in § 1.0 item 3.4, § 1 steps 2–3, § 4.0, § 4 steps 1 and 4, § 5, and § 5 step 6, a point and a linked landmark as warp destinations; new § 3.2 with the steps of off-road §§ 6, 6.5 and 7 that §§ 1–5 did not cover, on the new model, #1009); 2026-11-22 (§ 1.0 item 1, steps 2, 3 and 14 aligned with L3, L4 and seed v3, asked by the chain coordinator, docs #1008); 2026-11-22 (status: all sections merged into `next`, docs #1008); 2026-11-22 (§ 3 updated to what L3 built, steps tagged, #985); 2026-11-22 (§ 5 added, fixes #952 and #1003; § 1.0 and § 4.0 name seed v3, L1b); 2026-11-22 (§ 4 updated to what L4 built, steps tagged, #986); 2026-11-22 (§ 2 updated to what L2 built, steps tagged, #984); 2026-11-22 (§ 1 updated to what L1 built, steps tagged, #983); 2026-11-22 (draft from the design, phases 1–4)
**Design:** [specs/landmark-domain/DESIGN.md](../specs/landmark-domain/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976)

## 1. Phase 1: API model, migration, area kinds and parent (#983, tier:3)

*Built by link L1 (2026-11-22), knk-web-api `claude/landmark-domain`. tier:3: run every step before `next` is
promoted. Steps tagged `[automated: …]` run in CI (knk-web-api xUnit, CI job Build and test; the migration also in
the Migrations workflow on a fresh MySQL 8 database): skip them or run them by hand. `[partly automated: …; by hand:
…]` names the part only a person can check.*

### 1.0 Preconditions

1. Deployed: knk-web-api from `next` with migration `LandmarkAsDomain` applied to the dev DB; knk-web-app and
   knk-plugin from `next` (the region task and the rename run through the plugin). Every phase (L1–L4 and L1b) is in
   `next`, so the plugin and web app read the landmark-domain fields.
2. Settings: none new.
3. Accounts and data:
    1. A staff account with `knk.admin.world`, `knk.admin.world.landmark`, `knk.admin.content` and
       `knk.admin.delete` ("landmark staff"; `knk.admin.world` only for the domain dashboard of steps 12–13, the
       landmark API and form need only the other three).
    2. A staff account with `knk.admin.world`, `knk.admin.content` and `knk.admin.delete` but without
       `knk.admin.world.landmark` ("domain staff").
    3. A test town with a region and a spawn point in the dev world, and a crown land with a region (Territory V1 on
       `next`).
    4. The Landmark form seed v4 imported and made the default for Landmark: the form configuration list, Import /
       seeds, `Landmark` ("Landmark - Default (seed v4)", #1003, LD26; it supersedes seeds v3 and v2, which need not be
       imported), Make default. The seed v1 configuration, an imported v2 or v3 and the developer's edited form stay as
       they were; switch them off as default.

### 1.1 Steps

1. [partly automated: `Migrations/LandmarkAsDomainTests`, the Migrations workflow (Up, Down, Up on a fresh
   database); by hand: the dev DB] Before the migration, note that the dev DB has landmark rows (the landmark list
   shows them). Apply the migration and reload the landmark list. **Expected:** the list is empty; the migration
   reported no error; towns, districts and structures are all still there with their regions. (A02)
2. [partly automated: `LandmarkServiceTests.Create_APoint_IsADomainOfTypeLandmark_WithoutARegion_AndTheDomainDefaults`,
   `FormConfigurationSeedFilesTests.LandmarkSeed_V4_ShowsTheOwnRegionParts_OnlyForAnOwnRegion_AndTheWarpStepForEveryArea`
   (the seed's conditions); by hand: the seed v4 form] As landmark staff, open a new landmark form. **Expected:** it is
   "Landmark - Default (seed v4)": Area offers `Point`, `Own region` and `Linked domain's area` (`None`, `OwnRegion`,
   `LinkedDomain`; the last only once a parent with a region is picked); there is no Extent, Region id or Radius field.
   The steps depend on the area: with `Point` or `Linked domain's area` they are Landmark, Location, Area (no Region
   field) and Warp destination (the last step); with `Own region` the Region field shows and Area is followed by Access
   and messages, Warp destination and Sub-regions. (A01, A17, LD25, LD26, #1003)
3. [partly automated: `LandmarkServiceTests.Create_APoint_IsADomainOfTypeLandmark_WithoutARegion_AndTheDomainDefaults`;
   by hand: the form] Create a landmark with the seed v4 form: a name, a description, a pin captured in game, Area `None`,
   no parent. **Expected:** it saves; `GET api/landmarks/{id}` shows `areaKind` `None`, `wgRegionId` null,
   `allowEntry` and `allowExit` true, `showEnterLeaveMessages` and `teleportEnabled` false; `GET api/Domains/{id}`
   returns the same id as a domain (the Landmark fields with it) and `WgRegionId` null. (A01)
4. [automated: `RegionStillRequiredTests.ATownWithoutARegion_IsRefused_AndNothingIsSaved`,
   `DomainsControllerLandmarkTests.APlainDomainWrite_WithoutARegion_IsStillA400`] As domain staff, try to create a
   town without a region (`POST api/Towns` without `wgRegionId`, or the town form with the region left empty).
   **Expected:** refused with "WgRegionId is required."; nothing is saved. (A01)
5. [automated: `LandmarkServiceTests.Create_OnATownsSpawn_CopiesTheLocation_AndLeavesTheTownsAlone`] Create a
   landmark whose pin is the test town's spawn point (`POST api/landmarks` with the town's `locationId`).
   **Expected:** it saves with a new Location at the same spot; the town keeps its spawn. (LD17)
6. [partly automated: `LandmarkRegionRenameTests.Create_WithADrawnRegion_RenamesItToDomainId_AsALandmark_InThePinsWorld`;
   by hand: in game] Create a landmark with Area `OwnRegion`: Send to Minecraft on the Region field, draw a round
   area with `//sel cyl` in game, confirm, and submit the form. **Expected:** `/rg info domain_<id>` (the landmark's
   id) shows a cylinder-shaped (polygon) region; the landmark's region field shows `domain_<id>`; no
   `tempregion_worldtask_*` region is left after the cleanup. (A04)
7. [partly automated: `LandmarkRegionRenameTests.SubRegion_OfALandmark_BecomesDomainIdSubN_AsACopyOfItsMainRegion`;
   by hand: in game] Edit the landmark of step 6, add a sub-region in the Sub-regions step (draw a second region) and
   save. **Expected:** the sub-region is named `domain_<id>_sub_<n>`; `/rg info` shows `domain_<id>` as its parent.
   (A04)
8. [automated: `LandmarkServiceTests.LinkedDomain_SavesOnlyWithAParentThatHasARegion_AndOwnsNoRegion`] Create a
   landmark with Area `LinkedDomain` and the test town as parent. **Expected:** it saves; `GET api/landmarks/{id}`
   shows no region of its own (`wgRegionId` null), `parentDomainId` the town. (A03)
9. [automated: `LandmarkServiceTests.LinkedDomain_SavesOnlyWithAParentThatHasARegion_AndOwnsNoRegion`] Try Area
   `LinkedDomain` without a parent, then with the point-only landmark of step 3 as parent. **Expected:** both refused
   with "Area Linked domain's area needs a parent with a region."; nothing is saved. (A03)
10. [automated: `DomainParentWalkTests.SearchRegionDecisions_TopDown_PutsTheLandmarkInnermost_WithItsParentChain`,
    `DomainParentWalkTests.ByRegion_ALandmarkSubRegion_ResolvesToTheLandmark`,
    `DomainParentWalkTests.ByRegion_ACrownLandRegion_ResolvesWithoutParents_AndEnds`] Give the landmark of step 6 the
    test town as parent. Call `POST api/Domains/search-region-decisions` (`topDownHierarchy: true`) with the town's
    region and the landmark's region, then with the town's region and the landmark's sub-region of step 7, then with
    the crown land's region; and `GET api/Domains/by-region/<region>?world=<world>` for the landmark's region, its
    sub-region and the crown land's region. **Expected:** every call answers at once; the search lists the town at
    key 0 and the landmark at key 1 with the town as its parent decision (`matchedSubRegionId` set for the
    sub-region); the crown land answers nothing in the search and itself without parents in `by-region`; the API's
    memory stays flat. (A05, #981)
11. [automated: `LandmarkServiceTests.Parent_CanBeALandmark_ButNeverItselfOrADescendant`] Create a landmark "Dais"
    with the landmark of step 6 as parent, then try to give the landmark of step 6 "Dais" as parent. **Expected:** the
    first saves; the second is refused with "… a landmark can't be its own ancestor."; nothing changes. (LD23)
12. [automated: `DomainsControllerLandmarkTests.UpdateAndDelete_OnALandmark_WithoutTheLandmarkNode_Are403_AndChangeNothing`]
    As domain staff, open the landmark of step 3 from the domain dashboard (or call `PUT api/Domains/{id}` with a new
    name), then try to delete it (`DELETE api/Domains/{id}`). **Expected:** both refused with 403 "This domain is a
    landmark: changing it requires the knk.admin.world.landmark permission."; nothing changes. (A06)
13. [automated: `DomainsControllerLandmarkTests.UpdateAndDelete_OnALandmark_WithTheLandmarkNode_RunTheLandmarkRules`,
    `LandmarkServiceTests.UpdateFromDomain_SavesTheDomainFields_ThroughTheLandmarkRules`] As landmark staff, rename
    the same landmark through `PUT api/Domains/{id}`, then try a name longer than 100 characters and a name another
    landmark in the same world already has. **Expected:** the first rename saves (area, parent and preference
    unchanged); the other two are refused with 400 "Name can be at most 100 characters." and "A landmark named "…"
    already exists in world …". (A06)
14. [partly automated: `LandmarkCommandArgsTest.theRadiusFormIsRefused_WithTheWayToARoundRegion`,
    `LandmarkAdminCommandTest.createWithARadius_IsRefusedWithTheUsageLine`, `LandmarkServiceTests.Write_ARadius_IsRefused`
    (the API's own refusal, for a client that still sends a radius); by hand: in game] With the plugin from `next`
    (L3) and `navigation.landmarks: true`, run `/knk landmark create Well` where you stand, then
    `/knk landmark create Pond radius 5`, then `/navigate Well`. **Expected:** `Well` is created as a point (`areaKind`
    `None`; "Created landmark Well (#<id>) …"); the radius form is refused by the plugin with "The radius area is gone:
    draw a round region with //sel cyl, then use region <id>." and the usage line `/knk landmark create <name> [region
    <id>] | …` (no landmark is created); `/navigate Well` leads to it. § 3 step 6 checks the rest of `/knk landmark`.
    (LD08, A15)

## 2. Phase 2: API lists, discovery, warps and realtime (#984, tier:2)

*Built by link L2 (2026-11-22), knk-web-api `claude/landmark-domain-integration`. tier:2. Steps tagged
`[automated: …]` run in CI (knk-web-api xUnit, CI job Build and test; tests under `MySql/` in the mysql-tests job, the
migration also in the Migrations workflow on a fresh MySQL 8 database): skip them or run them by hand. `[partly
automated: …; by hand: …]` names the part only a person can check. Test classes: `LandmarkDomainIntegrationTests`
(`Services/`), `LandmarkDomainSearchMySqlTests` (`MySql/`), `AddLandmarkDiscoveryRuleTests` (`Migrations/`),
`ConfigEntityEventTests` (`Realtime/`). The web app's type column and filter are § 4 (L4), the plugin's side of
discovery, warps and realtime § 3 (L3).*

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with phases 1 and 2, migrations `LandmarkAsDomain` and
   `AddLandmarkDiscoveryRule` applied to the dev DB; knk-web-app from `next`.
2. Settings: none new.
3. Accounts and data:
    1. Landmark staff of § 1.0 item 3.1, also holding `knk.admin.discovery` (discovery rules and overrides).
    2. A player account that has discovered nothing yet (its user id; "the player").
    3. The landmarks of § 1: the point landmark of step 3, the own-region landmark of step 6 ("the tower", with the
       sub-region of step 7 and the test town as parent since step 10), the `LinkedDomain` landmark of step 8 and
       "Dais" of step 11 (parent: the tower). A second landmark with its own region and no override ("the second
       own-region landmark"; create it like step 6).
    4. A tool to call the API: the Swagger page of the dev API, or `curl` with the staff login cookie; the discovery
       grant of step 5 needs the plugin's API key (`X-API-Key`).

### 2.1 Steps

1. [automated: `LandmarkDomainIntegrationTests.Search_ListsLandmarks_WithTheTypeLandmark`] As landmark staff, call
   `POST api/Domains/search` with `{"pageNumber":1,"pageSize":100}`. **Expected:** the landmarks of § 1 are in the
   list with `"domainType": "Landmark"`; towns, districts and structures keep their own types. (A07)
2. [automated: `LandmarkDomainIntegrationTests.Search_TheTypeFilter_KeepsOnlyThatType_AndCountsOnlyThose`,
   `LandmarkDomainIntegrationTests.Search_TheTypeFilter_IsTheExactType_TakesSeveral_AndAnUnknownTypeMatchesNothing`,
   `LandmarkDomainSearchMySqlTests.TheTypeFilter_AndTheSubtreeFilter_Translate`] Call the same search with
   `"filters": {"domainType": "Landmark"}`, then with `"Structure"`, then `"Town,GateStructure"`, then `"Castle"`.
   **Expected:** only landmarks, and `totalCount` counts only them; `Structure` lists plain structures without the
   gate structures; the third lists towns and gate structures; `Castle` lists nothing (`totalCount` 0). (A07)
3. [automated: `LandmarkDomainIntegrationTests.Search_ExcludeSubtreeOf_LeavesOutTheLandmarkAndItsDescendants`,
   `LandmarkDomainSearchMySqlTests.TheTypeFilter_AndTheSubtreeFilter_Translate`] Call the search with `"filters":
   {"domainType": "Landmark", "excludeSubtreeOf": "<id of the tower>"}`. **Expected:** neither the tower nor "Dais" is
   listed; the other landmarks are. (LD20, the parent picker of § 4)
4. [partly automated: `LandmarkDomainIntegrationTests.TheLandmarkRule_IsListedAndDisabled_AndCanBeEdited`,
   `AddLandmarkDiscoveryRuleTests.Up_SeedsOneDisabledLandmarkRule_AndChangesNoSchema`,
   `LandmarkDomainSearchMySqlTests.TheMigrations_SeedTheLandmarkRule_Disabled`; by hand: the web app page] Open the
   discovery reward settings in the web app (or `GET api/discovery-rewards`). **Expected:** a `Landmark` rule is listed
   last and is disabled, with small XP and coin rewards, no gems and no ancestors. Leave it disabled. (A08)
5. [automated: `LandmarkDomainIntegrationTests.ALandmarkWithItsOverrideOn_IsDiscovered_OneWithout_IsNot`,
   `LandmarkDomainIntegrationTests.OnlyALandmarkWithItsOwnRegion_IsADiscoveryNode`] Turn the tower's discovery
   override on (the overrides list in the web app, or `PUT api/discovery-rewards/overrides/<id of the tower>` with
   `{"isEnabled": true}`). Then, as the game server would on entering both regions, call `POST
   api/users/<player id>/discoveries` with the plugin key and `{"wgRegionIds": ["domain_<id of the tower>",
   "domain_<id of the second own-region landmark>"], "worldName": "<the dev world>", "source": "RegionEnter"}`.
   **Expected:** `granted` holds the tower alone with `domainType` `Landmark` and its reward; the second landmark is
   under `skipped` with reason `Disabled`. A call with `"domainIds": [<id of the LinkedDomain landmark>]` grants
   nothing (skipped as `NotADomain`: it is discovered as its parent). (A08)
6. [automated:
   `LandmarkDomainIntegrationTests.ALandmarkWithItsWarpOn_IsADestinationOfTypeLandmark_WithItsPrice_AfterTheOtherTypes`]
   On the tower, switch the warp on with a price of 1 gem and save (landmark form, Warp step, or `PUT
   api/landmarks/<id>`). Call `GET api/teleport-destinations?userId=<player id>`. **Expected:** the tower is listed with
   `"domainType": "Landmark"` and `"priceGems": 1`, after the towns, districts and structures; landmarks without their
   warp on are not listed. (A09)
7. [automated: `LandmarkDomainIntegrationTests.RequiresDiscovery_StaysLockedWhileDiscoveryIsOff_AndUnlocksAfterTheDiscovery`]
   On the second own-region landmark (no override), switch the warp on with "Requires discovery" and call the
   destinations for the player. Then turn its override on, grant it as in step 5 and call the destinations again.
   **Expected:** first `available` false with `lockCode` `NotDiscovered` (with discovery off nothing can unlock it);
   after the grant `available` true. (A09)
8. [partly automated: `ConfigEntityEventTests.Map_ALandmarkChange_IsSentLikeTheOtherDomains_KeyedByItsOwnRegion`,
   `ConfigEntityEventTests.Interceptor_ALandmarkSave_SendsEntityChangedLandmark`; by hand: the dev server] With the
   dev server connected to the API's game hub, rename the tower. **Expected:** the game server receives an
   `EntityChanged` event of type `Landmark` with the tower's id and its region id as the key (the plugin acts on it
   from L3, § 3 step 8; before that only its realtime log shows it). (A16, API side)

## 3. Phase 3: plugin (#985, tier:2)

*Built by link L3 (2026-11-22), knk-plugin `claude/landmark-domain`. tier:2. Steps tagged `[automated: …]` run in CI
(knk-plugin job `build`: knk-core JUnit and knk-paper MockBukkit/Mockito tests; job `paper-boot`: the plugin scenarios
on a real Paper server with WorldGuard): skip them or run them by hand. `[partly automated: …; by hand: …]` names the
part only a person can check. Test classes: knk-core `LandmarkRegionKindTest`, `LandmarkTransitionMessagesTest`,
`DomainEffectDamageTest`, `AccessFlagSyncTest`, `LandmarkExtentTest`, `LandmarkWeightsTest`, `LandmarkProviderTest`,
`LandmarkCommandArgsTest`, `WarpTargetsTest`, `NavigationModelSnapshotTest`; knk-api-client `LandmarksApiImplTest`;
knk-paper `LandmarkAdminCommandTest`, `NavigationServiceLandmarkTest`, `ModelLandmarksTest`,
`HandleDestinationsLandmarkTest`, `DiscoveryLandmarkTest`, `LandmarkRealtimeTest`, `WgRegionIdTaskOutputTest`;
scenario `landmark-region-is-managed-under-its-parent`.*

### 3.0 Preconditions

1. Deployed: knk-plugin from `next` with phase 3 on the dev server; knk-web-api from `next` with phases 1 and 2
   (migrations `LandmarkAsDomain` and `AddLandmarkDiscoveryRule` applied); knk-web-app from `next` (phase 4), so the
   landmark form has the Area, Access and messages, Warp and Sub-regions steps. After the deploy, run
   `/knk regions repair` once as staff.
2. Settings: `navigation.landmarks: true` in the dev server's `config.yml` (only steps 5, 6 and 8 need it; the other
   steps work with it off). No new key.
3. Accounts and data:
    1. Landmark staff of § 1.0 item 3.1, also holding `knk.admin.discovery`, in game with `knk.admin.world.landmark`
       ("staff").
    2. A normal player account that has discovered nothing yet ("the player"), with `knk.navigate` granted (it is
       `default: false` since #845) and some gems for step 7.
    3. The test town of § 1.0 with a region and a spawn point. For step 5 item 3 the town also needs a sub-region
       (the town form's Sub-regions step); without one, skip that item.
    4. Three landmarks, made with the landmark form:
        1. "the wild tower": Area `OwnRegion`, a region drawn in the wilderness (outside every town), no parent, and a
           sub-region drawn right next to its main region (the Sub-regions step). Allow entry and Allow exit on,
           messages off, discovery override off, warp off.
        2. "the town well": Area `OwnRegion`, a small region drawn inside the test town, the test town as parent.
        3. "the market cross": Area `LinkedDomain`, the test town as parent, a pin somewhere in the town.

### 3.1 Steps

1. [partly automated: `AccessFlagSyncTest.aLandmarksOwnRegionGetsTheAccessFlagsAndDomainId_APointIsSkipped`,
   `LandmarkTransitionMessagesTest.aLandmarkWithEntryOff_KeepsThePlayerOut_LikeAnyDomain`; by hand: the dev server]
   As staff, switch Allow entry off on the wild tower and save; wait a minute for the access sync (or run
   `/knk regions repair`). Run `/rg info domain_<id of the wild tower>` and `/rg info domain_<id>_sub_<n>` (its
   sub-region). Then walk the player into the main region, and into the sub-region. **Expected:** both regions show
   the flags `knk-allow-entry deny`, `knk-allow-exit allow` and `knk-domain-id <id of the wild tower>`; the player is
   kept out of both with the domain's no-entry message, as at a town with entry off. Switch Allow entry on again and wait
   for the sync: the player walks in. (A10)
2. [partly automated: `DomainEffectDamageTest.aLandmarkNeverMakesASafeZone_InTheWildernessItHurts_InATownTheTownDecides`;
   by hand: the damage in game] With the player in survival mode, stand in fire, then in lava, then drink a poison
   potion, first inside the wild tower's region, then inside the town well's region. **Expected:** inside the wild
   tower the player takes fire, lava and poison damage as anywhere in the wilderness; inside the town well there is no
   effect damage, as anywhere in the town (unless the town has `knk-effect-damage allow`). (A11)
3. [partly automated: `LandmarkTransitionMessagesTest.withMessagesOff_EnteringAndLeavingALandmarkShowsNothing`,
   `LandmarkTransitionMessagesTest.withMessagesOn_OneEnterAndOneLeave_NothingBetweenItsSubRegions`,
   `LandmarkTransitionMessagesTest.aTownsMessageStillWins_AndALandmarkInsideTheTownSpeaksOnlyForItself`; by hand: the
   messages in game] With messages off on the wild tower, walk the player into its main region, across into its
   sub-region and out. Then, as staff, switch "Show enter and leave messages" on for the wild tower and save; wait a few
   seconds (the realtime change) and walk the same way again. Finally walk from outside the town into the town well's
   region, then out of it while staying in the town, with the town well's messages on. **Expected:** with messages off
   nothing is shown for the landmark; with messages on, one "You are now entering <name>." on entering, nothing when
   crossing into the sub-region, one "You are now leaving <name>." on leaving. Entering the town and the well at once
   shows the town's message; leaving the well inside the town shows "You are now leaving <name of the well>." (A12)
4. [partly automated: `LandmarkRegionKindTest.theRepairGivesALandmarkItsParentAndPriority_AndRestoresThem`,
   `LandmarkRegionKindTest.theLandmarkTypeIsItsOwnKind_AtTheStructureFloor_WithoutFlags`, scenario
   `landmark-region-is-managed-under-its-parent`; by hand: the dev server's regions] As staff, run
   `/rg info domain_<id of the town well>` and `/rg info domain_<id of the wild tower>`. Then set the well's priority
   to 0 and remove its parent (`/rg setpriority domain_<id> 0`, `/rg setparent domain_<id>`), run
   `/knk regions repair` and `/rg info` again. **Expected:** the well's parent is the town's main region and its
   priority is the town region's priority + 10, at least 30 (a town at 10 gives 30); the wild tower has no parent and
   priority 30; neither has a category flag of its own (no `pvp`, `entry`, `mob-spawning`), so the town's `pvp deny`
   applies in the well. After the repair the well's parent and priority are back. (A13)
5. [partly automated: `LandmarkProviderTest.theCatalogueSkipsLandmarkDomains_SoEachLandmarkIsListedOnce`,
   `LandmarkProviderTest.anAreaWithSubRegions_IsItsMainRegion_WithTheOthersAsArrival`,
   `NavigationServiceLandmarkTest.anAreaIsReachedInsideASubRegion`,
   `NavigationServiceLandmarkTest.aLinkedDomainAreaIsReachedInTheParentsSubRegion`,
   `NavigationServiceLandmarkTest.standingInASubRegionIsAlreadyThere`; by hand: the routes in game] With the player:
    1. Type `/navigate ` and press Tab. **Expected:** each of the three landmarks is offered once (no second entry as a
       domain).
    2. From a spot outside both, `/navigate <name of the wild tower>` and walk into its sub-region first (not its main
       region). **Expected:** the route leads to the main region; arrival is announced on entering the sub-region.
    3. `/navigate <name of the market cross>` from outside the town and walk into the town (into its sub-region, if
       the town has one). **Expected:** arrival on entering the town's main region, and also on entering the town's
       sub-region.
    4. Standing inside the wild tower's sub-region, `/navigate <name of the wild tower>`. **Expected:** "You are
       already in <name of the wild tower>." (no route). (A14)
6. [automated: `LandmarkCommandArgsTest.theRadiusFormIsRefused_WithTheWayToARoundRegion`,
   `LandmarkAdminCommandTest.createWithARadius_IsRefusedWithTheUsageLine`,
   `LandmarkAdminCommandTest.linkNeverTakesOrOffersTheLandmarkItself_ButAnotherLandmarkCanBeTheParent`,
   `LandmarkAdminCommandTest.showTellsTheAreaAndTheParent`] As staff, run `/knk landmark create Test radius 10`, then
   `/knk landmark link <name of the wild tower> ` and press Tab, then `/knk landmark link <name of the wild tower>
   <name of the wild tower>`, then `/knk landmark link <name of the wild tower> <name of the test town>` and
   `/knk landmark show <name of the wild tower>`. **Expected:** the radius form is refused with "The radius area is
   gone: draw a round region with //sel cyl, then use region <id>." and the usage line (no landmark is created); Tab
   offers domains (other landmarks too) but not the wild tower itself; linking it to itself is refused with "A landmark
   can't be its own parent."; linking to the town answers "Linked … to <town> (Town)."; `show` lists "region
   domain_<id> and 1 sub-region", "Parent: <town> (Town) #<id>" and "Enter and leave messages: on" (step 3 switched them on). Unlink it again
   afterwards (`/knk landmark unlink <name of the wild tower>`): it is a wilderness landmark in step 7. (A15)
7. [partly automated: `DiscoveryLandmarkTest.aLandmarkIsCalledALandmark`,
   `DiscoveryLandmarkTest.theSummaryCountsLandmarks_ForPlayersAndStaff_ThoughTheTypeRuleIsOff`,
   `WarpTargetsTest.aLandmarkIsAWarpTarget_ByNameOrWithTheTypeWordLandmark`; by hand: the dev server] As staff, turn
   the wild tower's discovery override on (the overrides list, or § 2 step 5) and switch its warp on with a price of
   1 gem. Walk the player into the wild tower for the first time, then open the discoveries menu (`/discoveries`).
   Walk away and run `/warp landmark:<name of the wild tower>`. Then switch "Requires discovery" on for the town well
   (with its warp on and its override off) and try `/warp landmark:<name of the town well>` with the player.
   **Expected:** one "You discovered the landmark <name>!" with its reward (once only); the menu lists it with the
   type "Landmark" and a lodestone icon, and the summary line "Landmarks: 1/<n>" (staff see the same line, not
   "Disabled"); the warp takes the player there for 1 gem; the town well is refused as not discovered. (A08, A09)
8. [partly automated: `LandmarkRealtimeTest.aLandmarkChange_ClearsTheCaches_AndRefreshesTheModelOncePerBurst`; by
   hand: the realtime path] With the dev server connected to the API's game hub, rename the market cross in the web
   app, wait a few seconds and use `/navigate` tab completion in game. **Expected:** the new name shows without a
   restart or `/knk cache refresh`; the server log shows the realtime `EntityChanged` for `Landmark`. (A16)
9. [automated: `WgRegionIdTaskOutputTest.theResultCarriesTheRegionsBoundingBox`] As staff, open a new production area
   in the web app with shape Region, leave the bounds empty, use Send to Minecraft on Region id and draw the region in
   game. **Expected:** the world task's result (the task list in the web app, or `GET api/WorldTasks/<id>`) has
   `bounds` with `minX` … `maxZ` of the drawn region; with the web-app part of #951 the form fills the empty bounds
   from it and the first save works. (#951)

### 3.2 Carried over from the off-road guide (#1009)

*Moved here on 2026-11-24 by fix link L4b: the developer decided on
[#1009](https://github.com/PandiO/knk-workspace/issues/1009) that the landmark sections of the
[off-road smoke test](navigation-offroad-smoke-test.md) (§ 6 landmark entity, #708; § 6.5 drawn landmark regions,
#944/#945; § 7 landmark weights, #709) close as superseded by this section, once every step they test that §§ 1–5 do
not is here. Each step is rewritten on the landmark-domain model (Area `Point`, `Own region` or `Linked domain's area`;
a parent; `domain_<id>` regions; no radius) and names the off-road step it comes from; the off-road guide lists where
each of its steps went and why the others were dropped. Steps 1–7 are API and web app, 8–18 in game, 19–26 the route
weights, 27 the flag. Tags as in § 3: knk-web-api tests run in CI job Build and test, knk-web-app specs in the `e2e`
job, knk-plugin tests in `build` and the scenarios in `paper-boot`. tier:2. About 60 min for every step by hand, 30 min
for the parts no suite covers.*

Preconditions, besides § 3.0:

1. Deployed as § 3.0 item 1, with the Landmark form seed v4 as the default form (§ 1.0 item 3.4).
2. Settings in the dev server's `config.yml` (restart after a change): `navigation.landmarks: true` and
   `navigation.destination-engine: true` for steps 8–27; `navigation.walk.enabled: true` and
   `navigation.preference-max: 4.0` (both the shipped defaults) for steps 19–26; `navigation.walk-links: true` for step
   26 only.
3. Accounts:
    1. Staff and the player of § 3.0 item 3; staff also with `knk.admin.regions` (step 17), the player also with
       `knk.navigate.mode.shortest` (step 20).
    2. Domain staff of § 1.0 item 3.2 (no `knk.admin.world.landmark`), also in game with the same grants.
    3. A staff account with only `knk.admin.content` ("content-only staff").
    4. A browser or `curl` without a login (step 1).
4. Data:
    1. The test town and the three landmarks of § 3.0 item 3.4 (the wild tower with its sub-region, the town well, the
       market cross).
    2. "Nether portal": a point landmark in the nether (`/knk landmark create Nether portal` as staff, standing
       there).
    3. "The town's namesake": a point landmark with exactly the test town's name (a landmark may share a town's name).
    4. Two WorldGuard regions in the dev world that no domain uses: `keep_throne` around the throne room of the keep and
       `keep_hall` around another room (`//sel cuboid`, then `/rg define <id>`). The keep, the courtyard and the other
       scenes are those of the off-road guide's introduction.
    5. For steps 19–21 and 25: two corridors of the keep that lead to the same place within about 40 blocks (a walk
       leg, not a road) and "Keep library", a point landmark at their far end (`/knk landmark create Keep library`
       standing there). "East corridor": a landmark made with the form, Area `Own region`, Send to Minecraft on Region
       and the shorter corridor selected in game from floor to ceiling (`//sel cuboid` or `//sel poly`, then `save`),
       Route preference 2.0; after Submit its region is `domain_<id>`. Wait a few seconds (the realtime change) or run
       `/knk cache refresh`.
    6. For step 12: a siege match you can start with the player in it (siege smoke tests).

Steps:

1. [automated: knk-web-api `EndpointAccessRulesTests.AllowAnonymous_IsLimitedToTheAllowList`, `ReadAccessRulesTests`
   (`LandmarksController.GetAll` and `GetById` = P), `DashboardChangeAccessRulesTests` (`LandmarksController.Create`
   and `Update`), `DeleteAccessRulesTests` (`LandmarksController.Delete`),
   `LandmarkServiceTests.GetAll_ByWorld_IgnoresCase_AndSortsByName`, `LandmarksControllerTests.GetAll_PassesTheWorld`]
   Without logging in, open `<api>/api/landmarks?world=<dev world>` in a browser (or `curl -s`), then
   `<api>/api/landmarks/<id of the wild tower>`; then, still without a login, `POST <api>/api/landmarks` with
   `{"name":"x","locationId":1}`. **Expected:** both reads answer `200`; the list holds the dev world's landmarks
   sorted by name (the world name in any letter case works), not "Nether portal"; each landmark has `id`, `name`,
   `world`, `location`, `areaKind`, `wgRegionId`, `subRegionIds`, `parentDomainId`, `parentDomainName`, `preference`
   and `navigationEnabled`; reads are limited to 120 a minute per IP (`RateLimiting:Map:PermitPerMinute`). The `POST`
   answers `401` and creates nothing. (LD19; from off-road § 6.1 steps 1–2)
2. [automated: knk-web-api `LandmarkServiceTests.Name_IsUniquePerWorld_IgnoringCase`,
   `LandmarkServiceTests.Name_OfATown_DoesNotBlockALandmark`, `LandmarkServiceTests.OwnRegion_NeedsARegion_AndOwnsIt`,
   `LandmarkServiceTests.OwnRegion_ARegionAnotherDomainHolds_IsRefused_InThatWorld`,
   `LandmarkServiceTests.Preference_OutsideTheRange_IsRefused`, `LandmarkServiceTests.Preference_TheBounds_AreAllowed`]
   As staff, with the landmark form (or `POST api/landmarks`), try: a point landmark named like the wild tower in other
   letter case in the dev world; the same name with a pin in the nether; Area `Own region` with the Region field
   empty; Area `Own region` with the test town's region id typed in; Route preference 0.2, then 4.5; then 0.25 and 4.0.
   **Expected:** the same name in the dev world is refused with "A landmark named "…" already exists in world …"; the
   nether one saves; the empty region is refused with "Area Own region needs a region: draw one or name an existing
   region."; the town's region with "Region '<id>' in world '<world>' already belongs to <town> (#<id>)."; 0.2 and 4.5
   with "Preference must be from 0.25 to 4."; 0.25 and 4.0 save. Delete the landmarks this step saved. (LD16, LD18;
   from off-road § 6.1 step 3)
3. [automated: knk-web-app `e2e/landmarks.spec.ts` "the search box asks the API with the search term"; knk-web-api
   `LandmarkServiceTests.Search_FiltersByParentWorldNavigationAndArea_AndMatchesTheParentsName`] As staff, open the
   landmark list (dashboard, type Landmark) and type into the search box a part of the wild tower's name, then the
   nether's world name, then a part of the test town's name. **Expected:** the list narrows to the wild tower; then to
   "Nether portal" and any other nether landmark; then to the landmarks whose parent is the test town (the town well,
   the market cross) and the town's namesake. (from off-road § 6.2 step 1; the list's columns are § 4 step 7)
4. [automated: knk-web-app `e2e/landmarks.spec.ts` "Add landmark needs the landmark node, and says which"; knk-web-api
   `DashboardAccessTests.Metadata_CreateAndEdit_AreTheChangeNodes`, `DashboardChangeAccessRulesTests`
   (`LandmarksController.Create` and `Update`)] Log in to the web app as domain staff. Open the landmark list, then the
   test town's page. **Expected:** the dashboard lists Landmark (domain staff hold `knk.admin.world`), but Create and
   Edit are greyed out with "Requires knk.admin.world.landmark"; on the town's page Add landmark in the Landmarks panel
   is greyed out with the same hint. A save sent anyway (`POST api/landmarks`) answers `403`. (O26, A06; from off-road
   § 6.2 step 5; the same staff through `api/Domains` is § 1 step 12)
5. [automated: knk-web-app `e2e/landmarks.spec.ts` "content-only staff do not get the landmark type"] Log in as
   content-only staff and open `/dashboard/Landmark`. **Expected:** the dashboard opens another type; its explorer has
   no Landmark type. (O26; from off-road § 6.2 step 6)
6. [partly automated: knk-web-api `LandmarkServiceTests.Delete_RemovesTheLandmark_AndLeavesThePinToTheRetentionCheck`;
   knk-web-app `e2e/landmarks.spec.ts` "says when no landmark has the town as parent"; by hand: the delete in the web
   app] As staff, create a point landmark "Scrap" with the wild tower as parent and open the wild tower's page: its
   Landmarks panel lists "Scrap". Delete "Scrap" from the landmark list (its row, Delete, confirm) and open the wild
   tower's page again. **Expected:** a message says "Scrap" was deleted; it is gone from the list; the wild tower's
   panel says "No landmarks have <name of the wild tower> as their parent."; `GET api/landmarks/<its id>` answers
   `404`; its Location stays and later shows in the orphaned-Location list (KNG-80), like a deleted domain's. (from
   off-road § 6.2 step 7)
7. [automated: knk-web-api `LandmarkServiceTests.DeletingTheParent_MakesTheChildrenTopLevel_AndALinkedAreaAPoint`,
   `LandmarkServiceTests.DeletingAParentTown_ClearsTheLink`,
   `LandmarkAsDomainTests.Up_KeysLandmarksByTheDomainId_AndTheParentIsClearedOnDelete`] As staff, create "Old palace"
   (Area `Own region`, a small region drawn with Send to Minecraft), then "Old throne" (parent "Old palace", Area
   `Linked domain's area`) and "Old well" (parent "Old palace", Area `Point`). Delete "Old palace". **Expected:** "Old
   throne" and "Old well" stay and are top level (no parent); "Old throne" is now Area `Point` (`areaKind` `None`), since
   the area it pointed to went with its parent. Delete both afterwards. (LD09, LD16; from off-road § 6.2 step 8)
8. [partly automated: knk-plugin `LandmarkAdminCommandTest.createTakesTheNameTheRegionAndThePlayersPosition`,
   `LandmarkAdminCommandTest.listShowsThePlayersWorld`, `LandmarkAdminCommandTest.theApisRefusalIsShown`,
   `LandmarksApiImplTest.createSendsTheNameThePinAndTheAreaInTheApisNewWords`; knk-web-api
   `LandmarkRegionRenameTests.Create_OnAnExistingRegion_KeepsItsId`,
   `LandmarkServiceTests.OwnRegion_ARegionAnotherDomainHolds_IsRefused_InThatWorld`; by hand: the dev server] As staff
   in game, stand in the throne room and run `/knk landmark create Throne room region keep_throne`, then
   `/knk landmark list`, then `/knk landmark create Throne copy region keep_throne`. In the web app, create "Hall" with
   Area `Own region` and `keep_hall` typed into Region. **Expected:** "Created landmark Throne room (#<id>) region
   keep_throne."; the list shows "#<id> Throne room region keep_throne"; after a reload the web app's landmark list
   shows it with Area Own region and Region `keep_throne`; the copy is refused with the API's reason ("Region
   'keep_throne' … already belongs to Throne room (#<id>)."); "Hall" keeps `keep_hall`. No `domain_<id>` region appears
   for either: a typed region keeps its id. (A04, LD14; from off-road § 6.3 step 1 and § 6.5 step 6)
9. [automated: knk-plugin `LandmarkAdminCommandTest.linkTakesADomainByNameOrId_andAnAmbiguousNameAsksForTheId`,
   `LandmarkAdminCommandTest.moveMovesTheSameLocationAndKeepsTheDomain`,
   `LandmarkAdminCommandTest.showFindsANameWithSpacesOrAnId`,
   `LandmarksApiImplTest.anUpdateKeepsTheParentAndMovesTheSameLocation`] Run `/knk landmark link Throne room <name of
   the test town>` (the town's namesake has the same name), then `/knk landmark link Throne room #<id of the test
   town>`. Stand a few blocks away, run `/knk landmark move Throne room`, then `/knk landmark show Throne room`.
   **Expected:** the first link answers "Several domains are called <name>; use its #id: …" with both ids and changes
   nothing; the second answers "Linked Throne room to <town> (Town)."; the move answers "Moved Throne room to where you
   stand."; `show` gives the new position, "region keep_throne" and "Parent: <town> (Town) #<id>": the move keeps the
   parent. (A15; from off-road § 6.3 steps 2–3; the rest of `link` and `show` is § 3.1 step 6)
10. [partly automated: knk-plugin `LandmarkAdminCommandTest.theMetadataGatesOnTheLandmarkNode`,
    `CommandRegistryPermissionsTest.withoutTheNodeTheSubcommandDoesNotRun`,
    `CommandRegistryPermissionsTest.help_listsTheOtherCommandsTheSenderMayUse`; by hand: the dev server's grants] As
    domain staff in game, run `/knk landmark create Test`, then `/knk help`. **Expected:** "You don't have permission"
    and nothing is created; `/knk help` does not list `landmark`. (O26; from off-road § 6.3 step 4)
11. [partly automated: knk-paper `NavigationServiceLandmarkTest.withoutAnExtentEightBlocksAwayIsNotThereYet`,
    `HandleDestinationsLandmarkTest.noExtentIsAPlainPoint_aRegionExtentIsTheRegion`; by hand: walking with a real
    client] As staff, stand at a gate and run `/knk landmark create Old gate` (a point). As the player, run
    `/navigate Old gate` from further away and walk towards the pin, stopping about 8 blocks before it, then walk on.
    **Expected:** 8 blocks away the navigation is still running; it ends with "You have arrived at Old gate." only
    within `navigation.arrive-distance` (4 blocks) of the pin. (LD22; from off-road § 6.3 step 6, its point half: the
    radius half is gone, LD08 and § 1 step 14)
12. [partly automated: knk-core `LandmarkProviderTest.tabCompletionOffersOnlyLandmarksThePlayerMayNavigateTo`,
    `LandmarkProviderTest.enabledLandmarksOfThePlayersWorldAreListedByName`,
    `LandmarkProviderTest.resolvesByNameAndIdAndTheBypassListsThemInAMatch`; by hand: tab completion as typed and the
    siege match] As the player in the dev world, type `/navigate ` and press Tab, then `/navigate landmark:` and Tab.
    As staff, untick "Offer in /navigate" on the town well in the web app and wait a few seconds; press Tab again. Run
    `/navigate Nether portal`. Then start the siege match with the player in it and press Tab after `/navigate ` again;
    do the same with a staff account in staff mode in the match. **Expected:** the dev world's landmarks the player may
    navigate to are offered ("Throne", "Old", "Keep", …); after the untick the town well is not offered; "Nether portal"
    is never offered in the dev world and `/navigate Nether portal` answers "Nether portal is in another world."; during
    the match no landmark is offered to the player, while staff mode lists them. Tick "Offer in /navigate" on the town
    well again and end the match. (A14; from off-road § 6.3 step 7)
13. [automated: knk-paper `NavigationServiceLandmarkTest.aLandmarkSessionSurvivesReValidationAndARename`,
    `NavigationServiceLandmarkTest.disablingTheLandmarkEndsTheSessionWithDestinationNotAllowed`,
    `NavigationServiceLandmarkTest.deletingTheLandmarkEndsTheSessionWithDestinationNotAllowed`; knk-core
    `LandmarkProviderTest.aSessionSurvivesARenameAndEndsWhenTheLandmarkIsDeletedOrDisabled`] As the player, start
    `/navigate Old gate`. As staff, rename it in the web app to "Old west gate" and wait a few seconds; then untick its
    "Offer in /navigate" (or delete it). **Expected:** the rename keeps the navigation going under the new name; after
    the untick or the delete the navigation ends within a few seconds (at most a minute without the game hub) with the
    message that the landmark is no longer part of the destinations. (A16; from off-road § 6.3 step 8)
14. [partly automated: knk-plugin `LandmarkAdminCommandTest.unlinkSendsNoDomain_deleteDeletes`,
    `LandmarksApiImplTest.deleteSendsADelete`, knk-core
    `NavigationModelLandmarksTest.aDeletedLandmarkLeavesTheModelOnTheNextRefresh`; by hand: the dev server] As staff,
    run `/knk landmark delete Throne room`. **Expected:** "Deleted landmark Throne room (#<id>)."; within a few seconds
    it is gone from `/knk landmark list`, from the test town's Landmarks panel in the web app and from `/navigate` tab
    completion (the command refreshes the model). (from off-road § 6.3 step 9)
15. [partly automated: knk-web-api
    `FormConfigurationSeedFilesTests.LandmarkSeed_IsV4_WithTheAreaKinds_AndDrawsItsRegionOnWgRegionId`,
    `TempRegionReleaseTests.IsRegionTask_ByTaskType_OnAnyField`; knk-plugin
    `WorldTaskHandlerRegistryTest.theRegionTaskOnAFieldNotNamedWgRegionId_findsTheRegionHandler`; by hand: the form and
    the task start] As staff, open a new landmark form, pick Area `Own region` and look at the Region field; use Send to
    Minecraft on it and claim the task in game with its code (`/knk task <code>`). **Expected:** the Region field has
    Send to Minecraft; its help text says a region drawn there is renamed to `domain_<id>` on save and that running the
    step again on a saved landmark replaces it; a region id can still be typed in instead; the task starts in game (no
    "This game server has no handler for task type 'ReagionCreate' …"). Cancel the task. Since seed v2 the landmark's
    region is on `WgRegionId`, like every domain's; the region task on a field with another name (#944) stays covered by
    the tests named. (A04, #944; from off-road § 6.5 step 1)
16. [partly automated: knk-web-api `LandmarkRegionRenameTests.Update_AfterARerun_ReplacesTheLandmarksOwnDomainRegionInPlace`;
    knk-plugin scenario `landmark-region-rerun-replaces-in-place`; by hand: drawing with a real client] As staff, edit
    the wild tower, go to the Area step, use Send to Minecraft on Region again, draw a clearly different shape in game
    and Submit. **Expected:** the region is still `domain_<id of the wild tower>`; `/rg info domain_<id>` shows the new
    outline and Y range with the wild tower's flags (`knk-allow-entry`, `knk-domain-id`), parent and priority as
    before; `/knk regions temp` lists no `tempregion_worldtask_*` left from it; navigation to the wild tower ends in the
    new shape at once (region shapes are read live). (A04, KNG-103; from off-road § 6.5 step 5)
17. [partly automated: knk-web-api `LandmarkRegionRenameTests.Create_WhenThePluginIsUnreachable_StillSaves`,
    `LandmarkRegionRenameTests.FinalizeAll_RenamesLandmarksStillOnATempName_AfterTheirParents`,
    `TempRegionReleaseTests.ListDue_ARegionSomethingNames_IsKept`; knk-plugin
    `TempRegionRetentionLookupTest.aLandmarksRegion_IsKeptByTheDomainLookup`; by hand: stopping the game server] As
    staff, start a new landmark "Courtyard" with Area `Own region`, draw its region in game (`save`), then stop the
    Paper server (or its connection to the API) before you click Submit; Submit, then start the server again. Run
    `/knk regions temp`, then call `POST api/Regions/finalize-temp-names` as staff. **Expected:** the landmark saves on
    `tempregion_worldtask_<n>`; `/knk regions temp` lists that region under "Used by a domain, lootbox area, landmark or
    production area (POST /api/Regions/finalize-temp-names renames them)" and the daily cleanup keeps it; the finalize
    call lists the landmark under `renamed` and the landmark shows `domain_<id>` (a new landmark, so no `domain_<id>`
    existed to replace; a re-run left on a temp name is § 5 step 4). (A04, #952; from off-road § 6.5 step 7)
18. [automated: knk-web-api `TempRegionReleaseTests.CancellingAHeldRegionTask_ReleasesItsRegion_AnUnclaimedOneDoesNot`,
    `TempRegionReleaseTests.DeletingADraft_ReleasesItsDrawnRegions_WithWorldAndServer`,
    `TempRegionReleaseTests.CancellingAHeldRegionTaskOnALandmarkRegionIdField_ReleasesItsRegion`; knk-plugin
    `TempRegionReleasePassTest.removesUnusedReleasedRegions_settlesMissingAndKeptOnes`] Start a new landmark's form,
    pick Area `Own region`, draw a region on its Region field, then cancel the task in the web app (or delete the draft
    in Saved Progress) instead of submitting. **Expected:** within about 10 minutes the server log says `Removed temp
    region <world>/tempregion_worldtask_<n> (…)` and the region is gone. (from off-road § 6.5 step 8)
19. [partly automated: knk-core `WalkPreferenceWeightsTest.anAreaWithAPreferenceOfTwoIsWalkedAround`; knk-paper
    `NavigationServiceLandmarkWeightsTest.inPreferredTheGardenWeightsTheWalkCells`; by hand: the keep] As the player,
    stand at the near end of the two corridors and run `/navigate Keep library`. **Expected:** the walk trail takes the
    longer corridor: in `preferred`, the default mode, the East corridor's region (Route preference 2.0) is avoided.
    (LD22; from off-road § 7 step 1)
20. [partly automated: knk-paper `NavigationServiceLandmarkWeightsTest.shortestAndEfficientIgnoreTheWeights`,
    `NavigationServiceLandmarkWeightsTest.forModeAddsTheWeightsInPreferredOnly`; by hand: the keep] Run
    `/navigate Keep library shortest`, then `/navigate Keep library efficient`. **Expected:** both take the shorter
    corridor through the East corridor: `shortest` and `efficient` ignore the weights. (from off-road § 7 step 2)
21. [partly automated: knk-core `LandmarkWeightsTest.onlyLandmarksWithAnAreaAndAWeightInTheWorldBecomeAreas`,
    `WalkPreferenceWeightsTest.noWeightsIsTheSearchAsBefore`; by hand: the refresh and the keep] As staff, set the East
    corridor's Route preference to 1.0 in the web app and wait a few seconds (or `/knk cache refresh`); as the player,
    navigate as in step 19. Then give "Keep library" (a point) Route preference 2.0 and navigate again. Set the East
    corridor back to 2.0 afterwards. **Expected:** the shorter corridor both times: a weight of 1.0 is no weight, and a
    point landmark has no area to weight. (from off-road § 7 step 3)
22. [automated: knk-core `LandmarkWeightsTest.overlappingAreasMultiplyCappedByPreferenceMaxBothWays`,
    `LandmarkWeightsTest.aRegionCountsByTheFeetBlock`, `WalkPreferenceWeightsTest.aCellInsideCostsItsMoveTimesThePreference`;
    knk-paper `LandmarksConfigTest.preferenceMaxIsReadAndABadValueIsTheDefault`] Make two landmarks with Area
    `Own region` whose round regions overlap in one hall: Send to Minecraft on Region, `//sel cyl` with the centre and
    the radius in game, then `save`; Route preference 3.0 each. **Expected:** a cell in both costs 4 times its move
    (3 × 3 = 9, capped at `navigation.preference-max` 4.0); with `preference-max: 10` and a restart it costs 9 times. Two
    of 0.25 cost 0.25 times, not 0.0625. (LD08: a round area is a cylinder region; from off-road § 7 step 4)
23. [automated: knk-core `WalkPreferenceWeightsTest.anAreaWithAPreferenceBelowOneDrawsThePathIn`,
    `WalkPreferenceWeightsTest.theHeuristicStaysAdmissibleTheFoundCostIsTheOptimum`,
    `LandmarkWeightsTest.theHeuristicScaleIsTheSmallestMultiplierInForce`] A landmark with Area `Own region` over a side
    lane and Route preference 0.5. **Expected:** the walk trail is drawn through the lane where it is not much longer,
    and the path found is still the cheapest one (the heuristic stays admissible). (off-road DESIGN § 5.4.4; from
    off-road § 7 step 5)
24. [partly automated: knk-core `LandmarkWeightsTest.anAreaOfSeveralRegions_IsOneUnion_WeightedOnceWhereTheyOverlap`,
    `LandmarkWeightsTest.anAreaWhoseRegionsAreAllUnknown_IsLeftOut_AndOneKnownRegionIsAPlainRegionArea`; knk-paper
    `ModelLandmarksTest.theWeightedAreasOfAWorldWithRegionsResolved`,
    `ModelLandmarksTest.aLinkedDomainArea_GetsTheParentsSubRegions_FromTheServer`; by hand: the routes] As staff, give
    the wild tower (its own region and the sub-region next to it) Route preference 2.0. As the player, navigate to a
    point past it on a walk leg (no road between) whose straight line crosses both its main region and its sub-region.
    Set the wild tower back to 1.0, give the market cross (`Linked domain's area`, the test town) Route preference 2.0
    and navigate across the town's edge, through the town's sub-region if it has one. Set the market cross back to 1.0.
    **Expected:** in `preferred` the walk goes around the wild tower's main region and its sub-region alike, and a cell
    where the two overlap costs 2 times its move, not 4: the area's regions are one union, weighted once; the market
    cross weights the town's main region and its sub-regions the same way. So a sub-region or a linked area needs no
    weights step of its own. (LD22, #985; new for #1009 item 3)
25. [automated: knk-core `NavigationModelSnapshotTest.aLandmarksPreferenceSurvivesTheRoundTrip`,
    `NavigationModelSnapshotTest.theAreasRegionsAreWritten_AndAFileFromBeforeReadsAnOldRegionExtentAsThatRegion`,
    `NavigationModelSnapshotTest.aSchemaOneFileWrittenBeforePhaseFiveTwoReadsTheMissingPreferenceAsOne`,
    `NavigationModelLandmarksTest.theSnapshotKeepsTheLandmarksAcrossARestart`] With the East corridor at Route
    preference 2.0, stop the API (or the game server's connection to it), restart the Paper server and, before the API
    answers, press Tab after `/navigate ` as the player and navigate as in step 19. **Expected:** the landmarks are
    offered and the weight still applies: the navigation model comes from its offline snapshot
    (`offline/navigation-model.json` in the plugin's data folder), which keeps each landmark's area regions and
    preference. A snapshot written before landmark-domain reads an old region extent as that one region, and one from
    before phase 5.2 reads every landmark with no weight. Start the API again. (from off-road § 7 step 7)
26. [automated: knk-core `WalkLinkLandmarkNodesTest.aLandmarkOnTheBoundaryMakesItALinkEndWithInferredConnections`,
    `WalkLinkLandmarkNodesTest.aBlockedStoredLinkRemovesThePair`, `LandmarkLinkNodesTest`; knk-paper
    `NavigationServiceLandmarkWeightsTest.landmarkNodesReachTheWalkLinkCandidates`,
    `ModelLandmarksTest.theLinkNodesAreKeptPerSnapshotAndLandmarkList`] With `navigation.walk-links: true`, pin a
    landmark (any area kind: its pin counts) on a road node at one side of the courtyard where that node is a tile
    boundary. **Expected:** the node becomes a walk-link end like a junction (`/knk road status` counts a link search
    across the courtyard). No stored landmark-to-landmark links exist in v1 (off-road O05). (from off-road § 7 step 8)
27. [automated: knk-paper `LandmarkAdminCommandTest.withTheFlagOffNothingHappens`,
    `LandmarksConfigTest.theShippedConfigHasTheKeySwitchedOff`, `LandmarksConfigTest.aMissingKeyOrConfigMeansOff`,
    `NavigationServiceLandmarkWeightsTest.withLandmarksOffTheWalkIsTodays`,
    `NavigationServiceLandmarkWeightsTest.aLandmarkFarFromTheLegOrNoneGivesNoWeights`,
    `NavigationServiceLandmarkWeightsTest.aFailingLookupMeansNoWeightsNotNoWalk`; knk-core
    `NavigationModelLandmarksTest.withTheFlagOffTheSectionStaysEmpty`,
    `WalkLegDefaultTranscriptTest.theDefaultModeIsTodaysWalkLegs`] Set `navigation.landmarks: false` and restart. As
    staff run `/knk landmark list`; as the player press Tab after `/navigate ` and navigate as in step 19.
    **Expected:** "Landmarks are off on this server (navigation.landmarks: false in config.yml)."; no landmark is
    offered; the server log's model line names no landmarks; the walk takes the shorter corridor, exactly the walk
    without landmarks. Set it back to `true` and restart. (LD24; from off-road § 6.3 step 10 and § 7 step 6)

## 4. Phase 4: web app (#986, tier:2)

*Built by link L4 (2026-11-22), knk-web-app `claude/landmark-domain`. tier:2. Steps tagged `[automated: …]` run in CI
(knk-web-app: Playwright with a mocked API in the `e2e` job, Jest in Build and test): skip them or run them by hand.
`[partly automated: …; by hand: …]` names the part only a person can check. Specs: `e2e/landmark-domain.spec.ts`
("the domain list", "a landmark's page", "the landmark form", the #951 test) and `e2e/landmarks.spec.ts`; Jest:
`utils/__tests__/landmarks.test.ts`, `utils/forms/__tests__/landmarkForm.test.ts`,
`utils/forms/__tests__/regionTaskBounds.test.ts`, `components/landmarks/__tests__/DomainLandmarksPanel.test.tsx`.*

### 4.0 Preconditions

1. Deployed: knk-web-app from `next` with phases 1 and 2 of the API (§ 1 and § 2 deployed). For step 8 also the
   plugin of phase 3 (§ 3, #985), which sends the drawn region's bounding box.
2. Settings: none new.
3. Accounts and data:
    1. Landmark staff of § 1.0 item 3.1 (with `knk.admin.world`: the parent picker and the world check read
       `api/Domains`).
    2. The landmarks of § 1 and § 2: the point landmark of § 1 step 3, "the tower" (own region, parent the test town),
       "Dais" (parent the tower), the `LinkedDomain` landmark of § 1 step 8.
    3. The Landmark form seed v4 as the default form (§ 1.0 item 3.4): its Region field and its "Access and
       messages" and "Sub-regions" steps show only with `Own region`; its "Warp destination" step shows for every area
       kind ([#1003](https://github.com/PandiO/knk-workspace/issues/1003), LD26, § 5 step 5).

### 4.1 Steps

1. [partly automated: `landmark-domain.spec.ts` "shows the region, access and sub-region steps only with Own region,
   and the warp step for every area (A17, LD26)", on a mocked form with those conditions, and
   `FormConfigurationSeedFilesTests.LandmarkSeed_V4_ShowsTheOwnRegionParts_OnlyForAnOwnRegion_AndTheWarpStepForEveryArea`
   for the seed's conditions; by hand: the real seed v4 form, see 4.0 item 3.3] As landmark staff, open a new landmark
   form, fill the name and go to the Area step. Pick `Point` and click Next; go back with Previous, pick `Own region`
   and step through with Next. **Expected:** with `Point` there is no Region field and Next leads to "Warp destination"
   (its "Warp destination" switch is there), which is the last step (Submit, no Next); with `Own region` the Region
   field shows and Next leads to "Access and messages", "Warp destination" and "Sub-regions". (A17, LD26)
2. [automated: `landmark-domain.spec.ts` "offers Linked domain's area only with a parent that has a region (A17)",
   `landmarkForm.test.ts`] In the same form, leave the parent empty and open the Area options; go back, pick the test
   town as parent, open the Area options again and pick `Linked domain's area`; go back and pick the point landmark of
   § 1 step 3 as parent instead. **Expected:** without a parent the options are `Point` and `Own region`, with the line
   "Linked domain's area is offered once the parent has a region."; with the town `Linked domain's area` is offered and
   the Region field goes when it is picked; with the point landmark as parent the Area field shows "Area Linked
   domain's area needs a parent with a region." until another area is picked, and the option is gone after that. (A17)
3. [automated: `landmark-domain.spec.ts` "shows each domain with its type, and the type filter keeps one type
   (A07)", `landmarks.test.ts`] Open the domain list (dashboard, type Domain). Then pick `Landmark` in the type filter
   next to the search box. **Expected:** a Type column (Town, District, Structure, Gate, Landmark, …); after the filter
   only landmarks, the tower, "Dais" and the others of § 1. (A07)
4. [automated: `landmark-domain.spec.ts` "edits a landmark with the landmark form, and a town with the domain form
   (DESIGN § 4.3)", `landmarks.test.ts` "opens a landmark row …"] In the domain list, click Edit on the tower's row;
   go back and click Edit on the test town's row. **Expected:** the tower opens in the landmark form
   (`/forms/Landmark/edit/<id>`, "Landmark - Default (seed v4)"), the town in the domain form as before. With a Domain display configuration the rows are links, and the tower's row
   opens the landmark's page (`/display/Landmark/<id>`). (DESIGN § 4.3)
5. [automated: `landmark-domain.spec.ts` "the parent picker shows the type and leaves out the landmark and its
   descendants (A18)", "a new landmark offers every domain as parent"] Edit the tower in the landmark form and click
   the Parent field. **Expected:** each option shows its type ("Type: Town", "Type: Landmark", …); neither the tower
   nor "Dais" is offered; in a new landmark's form every domain is offered. (A18)
6. [automated: `landmark-domain.spec.ts` "lists its child landmarks, not the landmark itself",
   `DomainLandmarksPanel.test.tsx`, `landmarks.spec.ts` "a town's page"] Open the test town's page, then the tower's
   page. **Expected:** the town's Landmarks panel lists the tower and the `LinkedDomain` landmark (not "Dais"); the
   tower's panel lists "Dais" and not the tower itself; a landmark without children says "No landmarks have <name> as
   their parent.". (DESIGN § 6.3 item 3)
7. [automated: `landmarks.spec.ts` "lists the landmarks with world, point, parent, area, region and /navigate"] Open
   the landmark list (dashboard, type Landmark). **Expected:** columns World, Point, Parent, Area, Region and In
   /navigate; the tower shows "<town> (Town)", "Own region" and `domain_<id>`; the `LinkedDomain` landmark "Linked
   domain's area" and no region; the point landmark "Point". (LD16)
8. [partly automated: `landmark-domain.spec.ts` "a drawn region's bounding box fills the empty bounds and keeps typed
   ones (#951)", `regionTaskBounds.test.ts`; by hand: with the plugin of § 3] Open a new production area (Shape
   `Region`), type 99 into MaxY, then Send to Minecraft on Region id and draw a new region in game. **Expected:** after
   the task completes the region id is filled, MinX, MinY, MinZ, MaxX and MaxZ hold the drawn region's box, MaxY keeps
   99; the area saves at the first Submit. With a plugin before § 3 nothing is filled, as before. (#951)
9. [by hand] Open the discovery settings and the overrides card. **Expected:** the `Landmark` rule is last and
   disabled (§ 2 step 4); "Add override" offers the landmarks with the type word Landmark; the player discoveries
   filter and the stats card list Landmark last. (A08, web side)

## 5. Fixes picked up by the chain (#952, #1003)

*Built by fix link L1b (2026-11-22), knk-web-api `claude/landmark-domain-952` (charter § 3 item 8.1 and #1003);
step 5 changed and step 6 added by fix link L4b (2026-11-24), knk-web-api and knk-web-app
`claude/landmark-warp-step-1003`: seed v4, the warp step for every area kind (developer decision LD26 on #1003). #952 is
tier:2, #1003 tier:1. Steps tagged `[automated: …]` run in CI (knk-web-api xUnit, CI job Build and test; knk-web-app
Playwright in the `e2e` job): skip them or run them by hand. `[partly automated: …; by hand: …]` names the part only a
person can check. Tests: `Services/TempNameHealTests`, `Services/Lootbox/LootboxAreaRegionRenameTests`,
`Services/DomainSubRegionTests`, `Services/FormConfigurationSeedFilesTests`, `Services/LandmarkDomainIntegrationTests`.*

### 5.0 Preconditions

1. Deployed: knk-web-api from `next` with this fix, knk-web-app and knk-plugin from `next` (the region task, the
   rename and `replaceRegionId` run through the plugin; KNG-103 is on `next`).
2. Settings: none new.
3. Accounts and data:
    1. Landmark staff of § 1.0 item 3.1, with `knk.admin.regions` too (for `POST api/Regions/finalize-temp-names`
       and `/rg info`), and an operator in game.
    2. A lootbox spawn area made through its form with a drawn region, so it is on `lootbox_area_<id>` (lootbox area
       region smoke test, `guides/lootbox-area-region-smoke-test.md`); note its id.
    3. The Landmark form seed v4 as the default form (§ 1.0 item 3.4).

### 5.1 Steps

1. [partly automated: `TempNameHealTests` (the guard and the first save), the game server; by hand: the failed save]
   Open the lootbox area's form, Send to Minecraft on its Region field and draw a clearly different region in game
   (`save`). Before you click Submit, stop the Paper server (or its connection to the API). Submit. **Expected:** the
   form saves; the area's region is `tempregion_worldtask_<n>` (the area list or `GET api/LootboxSpawnAreas/<id>`);
   the API log says the plugin did not rename it. Start the server again: `/rg info lootbox_area_<id>` still shows the
   old shape. (#952, the state the issue describes)
2. [partly automated: `TempNameHealTests.FinalizeAll_HealsEveryOwnerKind_ButNotADomainsOwnName`; by hand: the game
   server] Call `POST api/Regions/finalize-temp-names` as that staff account. **Expected:** the response lists the area
   under `renamed`, not `failed`; the area is on `lootbox_area_<id>` again; `/rg info lootbox_area_<id>` shows the
   shape drawn in step 1 with the old region's flags and owners; `/rg info tempregion_worldtask_<n>` finds no region;
   the API log line reads "Finalizing region name for lootbox spawn area <id>: tempregion_worldtask_<n> ->
   lootbox_area_<id> (…, replacing lootbox_area_<id>)". (#952)
3. [partly automated: `TempNameHealTests.LootboxArea_ASaveThatKeepsTheTempName_ReplacesItsOwnFinalName`,
   `LootboxAreaRegionRenameTests.Update_WithTheSameTempRegion_RetriesTheRename_ReplacingItsOwnFinalName`; by hand: the
   game server] Repeat step 1, then instead of step 2 open the area's form again and Submit without changing anything.
   **Expected:** as step 2: the save heals the area. (#952)
4. [automated: `TempNameHealTests` (`ProductionArea_…`, `SiegeWeaponSpot_…`, `SubRegion_…`, the `…IsNotReplaced`
   guards, `FinalizeAll_HealsEveryOwnerKind_ButNotADomainsOwnName`)] The same heal for a Region-shaped production
   area (`production_area_<id>`), a siege weapon spot (`siege_spot_<id>`) and a domain sub-region
   (`domain_<id>_sub_<n>`); a final name that a domain, sub-region, lootbox area, production area or siege spot names
   is not replaced (the row keeps its temp name, as before); a first save names nothing to replace; a domain's own
   `domain_<id>` (a landmark's too) is not healed, so a domain in this state still needs the manual way out of
   `architecture/managed-worldguard-regions.md` § 7. (#952)
5. [partly automated: `FormConfigurationSeedFilesTests.LandmarkSeed_V4_ShowsTheOwnRegionParts_OnlyForAnOwnRegion_AndTheWarpStepForEveryArea`,
   `FormConfigurationSeedFilesTests.LandmarkSeed_IsV4_WithTheAreaKinds_AndDrawsItsRegionOnWgRegionId`,
   `FormConfigurationSeedFilesTests` (every seed's dry run), `e2e/landmark-domain.spec.ts` "shows the region, access
   and sub-region steps only with Own region, and the warp step for every area (A17, LD26)"; by hand: the imported
   form] Open the form configuration list and check that "Landmark - Default (seed v4)" is the default for Landmark (an
   imported v3 is not the default). Open a new landmark form (with the test town as parent), go to the Area step and
   pick `Point` and click Next, then go back and pick `Linked domain's area` and click Next, then go back and pick
   `Own region` and step through with Next. **Expected:** with `Point` and `Linked domain's area` there is no Region
   field and Next leads to "Warp destination", the last step; with `Own region` the Region field shows and Next leads to
   "Access and messages", "Warp destination" and "Sub-regions". (A17, LD26, #1003)
6. [partly automated: knk-web-api
   `LandmarkDomainIntegrationTests.APointLandmark_AndALinkedOne_WithTheirWarpOn_AreDestinations_AtTheirPins`; knk-plugin
   `WarpTargetsTest.aLandmarkIsAWarpTarget_ByNameOrWithTheTypeWordLandmark`; by hand: the dev server] As landmark staff,
   edit the point landmark of § 1 step 3 and the `LinkedDomain` landmark of § 1 step 8: in the "Warp destination" step
   switch "Warp destination" on (price 0) and save each. Call `GET api/teleport-destinations?userId=<a player's id>`;
   then, as that player in game, run `/warp landmark:<name of the point landmark>`, walk away and run
   `/warp landmark:<name of the LinkedDomain landmark>`. **Expected:** both are listed with `"domainType": "Landmark"`
   and `available` true; each warp takes the player to that landmark's pin (a point landmark has no region, and the
   linked one warps to its own pin, not to its parent's spawn). Switch both warps off again. (LD26, #1003)
