# Landmarks as a Domain subtype — smoke test

**Status:** § 1 built (L1, 2026-11-22, on `claude/landmark-domain`, not run by the developer); § 2–§ 4 draft from the design. Steps tagged by the links.
**Last updated:** 2026-11-22 (§ 1 updated to what L1 built, steps tagged, #983); 2026-11-22 (draft from the design, phases 1–4)
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

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with phases 1 and 2; knk-web-app from `next`.
2. Settings: none new.
3. Accounts and data: landmark staff; the landmarks of § 1.

### 2.1 Steps

1. Open the domain list in the dashboard. **Expected:** the landmarks are listed with the type `Landmark`;
   filtering on that type shows only landmarks. (A07)
2. Open the discovery settings. **Expected:** a `Landmark` type rule exists and is disabled; a landmark has no
   discovery until its override turns it on. Turn the override on for the own-region landmark of § 1 step 4. (A08)
3. On the same landmark, switch the warp on with a price of 1 gem and save. **Expected:** the teleport destinations
   (`GET api/TeleportDestinations` or the warp list in the web app) list it with the type word `landmark` and the
   price. (A09)
4. Edit a landmark's name while the dev server runs. **Expected:** the API sends a realtime change for the landmark
   (the plugin log shows it received a `Landmark` change). (A16, API side)

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
7. With the override of § 2 step 2 on, walk the player into that landmark for the first time; then `/warp
   landmark:<name>` from elsewhere; switch "requires discovery" on and try with a player who has not discovered it.
   **Expected:** a discovery message and reward once; the warp works with its price; the undiscovered player is
   refused. (A08, A09)
8. Rename a landmark in the web app and use `/navigate` tab completion in game. **Expected:** the new name shows
   within a few seconds, without a restart. (A16)

## 4. Phase 4: web app (#986, tier:2)

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: knk-web-app from `next` with phases 1 and 2 of the API.
2. Settings: none.
3. Accounts and data: landmark staff; the test town with a landmark as child.

### 4.1 Steps

1. Open a new landmark form and switch Area between `None`, `Own region` and `Linked domain's area`. **Expected:** the
   sub-region, access, messages, discovery and warp steps show only with `Own region`. (A17)
2. Open the domain list and filter on the type `Landmark`. **Expected:** a type column, and only landmarks after the
   filter. (A07)
3. Open the parent picker of a landmark that has a child landmark. **Expected:** domains show their type; the landmark
   itself and its child are not offered. (A18)
4. Open the test town's page, then the child landmark's page. **Expected:** the town lists its landmark; the landmark's
   page does not list itself as its own landmark.
