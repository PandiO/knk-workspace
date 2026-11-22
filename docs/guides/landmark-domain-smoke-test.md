# Landmarks as a Domain subtype — smoke test

**Status:** § 1 built (L1, 2026-11-22, on `next`, not run by the developer); § 2 built (L2, 2026-11-22, on `claude/landmark-domain-integration`, not run by the developer); § 3 draft from the design; § 4 built (L4, 2026-11-22, on knk-web-app `claude/landmark-domain`, not run by the developer). Steps tagged by the links.
**Last updated:** 2026-11-22 (§ 4 updated to what L4 built, steps tagged, #986); 2026-11-22 (§ 2 updated to what L2 built, steps tagged, #984); 2026-11-22 (§ 1 updated to what L1 built, steps tagged, #983); 2026-11-22 (draft from the design, phases 1–4)
**Design:** [specs/landmark-domain/DESIGN.md](../specs/landmark-domain/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976)

## 1. Phase 1: API model, migration, area kinds and parent (#983, tier:3)

*Built by link L1 (2026-11-22), knk-web-api `claude/landmark-domain`. tier:3: run every step before `next` is
promoted. Steps tagged `[automated: …]` run in CI (knk-web-api xUnit, CI job Build and test; the migration also in
the Migrations workflow on a fresh MySQL 8 database): skip them or run them by hand. `[partly automated: …; by hand:
…]` names the part only a person can check.*

### 1.0 Preconditions

1. Deployed: knk-web-api from `next` with migration `LandmarkAsDomain` applied to the dev DB; knk-web-app and
   knk-plugin from `next` (the region task and the rename run through the plugin). The plugin and web app still use
   the off-road landmark fields until L3 (#985) and L4 (#986); see the deploy notes in the changelog entry for what
   that means in between.
2. Settings: none new.
3. Accounts and data:
    1. A staff account with `knk.admin.world`, `knk.admin.world.landmark`, `knk.admin.content` and
       `knk.admin.delete` ("landmark staff"; `knk.admin.world` only for the domain dashboard of steps 12–13, the
       landmark API and form need only the other three).
    2. A staff account with `knk.admin.world`, `knk.admin.content` and `knk.admin.delete` but without
       `knk.admin.world.landmark` ("domain staff").
    3. A test town with a region and a spawn point in the dev world, and a crown land with a region (Territory V1 on
       `next`).
    4. The Landmark form seed v2 imported and made the default for Landmark: the form configuration list, Import /
       seeds, `Landmark` ("Landmark - Default (seed v2)"), Make default. The seed v1 configuration and the
       developer's edited form stay as they were; switch them off as default.

### 1.1 Steps

1. [partly automated: `Migrations/LandmarkAsDomainTests`, the Migrations workflow (Up, Down, Up on a fresh
   database); by hand: the dev DB] Before the migration, note that the dev DB has landmark rows (the landmark list
   shows them). Apply the migration and reload the landmark list. **Expected:** the list is empty; the migration
   reported no error; towns, districts and structures are all still there with their regions. (A02)
2. [partly automated: `LandmarkServiceTests.Create_APoint_IsADomainOfTypeLandmark_WithoutARegion_AndTheDomainDefaults`;
   by hand: the v2 form] As landmark staff, open a new landmark form. **Expected:** it is "Landmark - Default (seed
   v2)": Area offers `None`, `OwnRegion` and `LinkedDomain`; there is no Extent, Region id or Radius field; the steps
   are Landmark, Location, Area, Access and messages, Warp destination, Sub-regions. (A01, LD25)
3. [partly automated: `LandmarkServiceTests.Create_APoint_IsADomainOfTypeLandmark_WithoutARegion_AndTheDomainDefaults`;
   by hand: the form] Create a landmark with the v2 form: a name, a description, a pin captured in game, Area `None`,
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
14. [partly automated: `LandmarkServiceTests.Write_ReadsThe708Names_WhenTheNewOnesAreNotSent`,
    `LandmarkServiceTests.Write_ARadius_IsRefused`; by hand: in game] With the plugin from `next` (before L3), run
    `/knk landmark create Well` where you stand, then `/knk landmark create Pond radius 5`, then `/navigate Well`.
    **Expected:** `Well` is created as a point (`areaKind` `None`); the radius form is refused with "The radius area
    is gone: draw a round region with //sel cyl instead."; `/navigate Well` leads to it. (compatibility until L3)

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

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: the plugin from `next` on the dev server, with the API and web app of phases 1 and 2.
2. Settings: `navigation.landmarks: true`.
3. Accounts and data: landmark staff; a normal player account; a wilderness landmark with its own region and one with
   its own region inside the test town (the town as parent).

### 3.1 Steps

1. Switch Allow entry off on the wilderness landmark, wait for the access sync (or `/knk regions repair`) and walk
   into its region with the player. **Expected:** the player is kept out with the domain's no-entry message; with
   Allow entry on again, the player walks in. (A10)
2. With the player, stand in fire and lava inside the wilderness landmark region, then inside the landmark in the
   town. **Expected:** in the wilderness landmark the player takes damage as outside it; in the town landmark no effect
   damage, as anywhere in the town. (A11)
3. With messages off on the wilderness landmark, walk in and out; switch "Show enter and leave messages" on, give it
   a sub-region next to the main region, and walk in, across into the sub-region, and out. **Expected:** nothing with
   messages off; with messages on, one enter message, nothing when crossing into the sub-region, one leave message.
   (A12)
4. As staff, run `/rg info domain_<id>` for the town landmark, then `/knk regions repair` and again `/rg info`.
   **Expected:** parent = the town's main region, priority = the town region's priority + 10, no category flags;
   unchanged after the repair. (A13)
5. With the player, `/navigate` with tab completion, then navigate to the wilderness landmark and walk into its
   sub-region first; navigate to the linked-domain landmark of § 1 step 6 and walk into the town. **Expected:** each
   landmark is offered once; arrival is announced on entering the sub-region; the linked-domain landmark arrives on
   entering the town. (A14)
6. As staff, `/knk landmark create Test radius 10`, then `/knk landmark link <wilderness landmark> <test town>` with
   tab completion. **Expected:** the radius form is refused with the usage line; `link` sets the town as parent and
   does not offer the landmark itself. (A15)
7. With the override of § 2 step 5 on, walk the player into that landmark for the first time; then `/warp
   landmark:<name>` from elsewhere; switch "requires discovery" on and try with a player who has not discovered it.
   **Expected:** a discovery message and reward once; the warp works with its price; the undiscovered player is
   refused. (A08, A09)
8. Rename a landmark in the web app and use `/navigate` tab completion in game. **Expected:** the new name shows
   within a few seconds, without a restart. (A16)

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
    3. The Landmark form seed v2 as the default form. Its Region field and its "Access and messages", "Warp
       destination" and "Sub-regions" steps have no display conditions until seed v3
       ([#1003](https://github.com/PandiO/knk-workspace/issues/1003)): for step 1, add the condition "Area equals
       OwnRegion" to those four in the form builder (or import seed v3 once it exists).

### 4.1 Steps

1. [partly automated: `landmark-domain.spec.ts` "shows the region, access, warp and sub-region steps only with Own
   region (A17)", on a mocked form with those conditions; by hand: the real seed form, see 4.0 item 3.3] As landmark
   staff, open a new landmark form, fill the name and go to the Area step. Pick `Point`, then `Own region`, and step
   through with Next. **Expected:** with `Point` there is no Region field and Area is the last step (Submit, no Next);
   with `Own region` the Region field shows and Next leads to "Access and messages", "Warp destination" and
   "Sub-regions". (A17)
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
   (`/forms/Landmark/edit/<id>`, "Landmark - Default (seed v2)"), the town in the domain form as before. With a Domain display configuration the rows are links, and the tower's row
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
