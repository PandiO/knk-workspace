# Production, storage and transport — smoke test

**Status:** Draft from the design (2026-11-16); no steps run. § 0 (item identity, #141): 7 of 14 steps automated
in CI and 4 partly (tagged); every step can still be run by hand; manual steps not run. § 1.1-1.2 (territory API,
#326): 19 of 19 steps automated in CI (tagged; step 1.2.6 needs a connected server to check by hand); every step can
still be run by hand; not run. § 1.3 (territory plugin, #689): 7 of 14 steps automated and 7 partly (tagged; step 14
waits for #802); not run. § 1.4 (territory web app, #690): 13 of 15 steps automated in CI and 2 partly (tagged);
every step can still be run by hand; not run. § 2.1 (stock core API, #97): 15 of 17 steps automated in CI and 2 partly
(tagged); every step can still be run by hand; not run. § 2.2 (stock web app, #675): 14 of 17 steps automated in CI
and 3 partly (tagged); every step can still be run by hand; not run. § 3.1 (world API, #91): 14 of 16 steps
automated in CI and 2 partly (tagged); every step can still be run by hand; not run. Other sections not yet automated
(the links tag them).
**Last updated:** 2026-11-19 (§ 3.1 world API, link L6, #91); 2026-11-19 (§ 2.2 stock web app, link L5, #675); 2026-11-19 (§ 2 stock core API, link L4, #97); 2026-11-19 (§ 1.0 and § 1.3 preconditions: builds from `next` instead of the link branches; guides: [territory admin guide](admin/territory-admin-guide.md), docs #806); 2026-11-19 (§ 1.4 territory web app, link L3, #690); 2026-11-19 (§ 1.3 territory plugin, link L2, #689); 2026-11-19 (§ 1 territory API, link L1, #326); 2026-11-19 (§ 0 item identity, link L0, #141); 2026-11-16 (draft from the design, territory and phases P1-P12)
**Design:** [specs/production-storage-transport/DESIGN.md](../specs/production-storage-transport/DESIGN.md) (§17
acceptance A01-A27, §18 links) · [territory](../specs/territory/DESIGN.md) · [shops](../specs/shops/DESIGN.md) ·
**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22)

Common preconditions for every section:

1. Deployed from `next`: knk-web-api with the phase's migrations applied, knk-web-app, the knk-plugin build.
2. Flags on for the test: API game setting `Production:Enabled = true`; plugin `config.yml` `production.enabled: true`.
3. Accounts: **Admin** (holds `*`), **Staff** (holds `knk.admin.world` and `knk.admin.content`), **Member** (a member
   of the test town, no staff nodes), **Visitor** (no town, no staff nodes).
4. Test data: town **Phoenix** with at least two districts, one marked capital; a second town **Rivertown**; a kingdom
   that holds both.

## 0. Item identity (#141 API and plugin; tier:3)

Built in link L0, merged into `next` 2026-11-19 (knk-web-api `7d213fd6`, knk-plugin `2ef256e7`). Admins: [item identity admin guide](admin/item-identity-admin-guide.md). Every obtainable vanilla material
has exactly one item blueprint (a generated "vanilla shadow" in the "Uncurated" category until an admin curates it,
D11/G4), and every item a player obtains resolves to one: instance tag, then blueprint tag, then the material's vanilla
match. The plain vanilla item is the canonical form and never carries a blueprint tag, so stacking stays vanilla's.
Full manual run about 45 minutes; the untagged steps only about 25 minutes.

### 0.0 Preconditions

1. knk-web-api with migration `AddItemIdentity` applied; a completed Minecraft catalogue scan of the test server's
   version (web app, Minecraft catalogue page, "Scan").
2. The plugin jar from `next`, with `items.identity` merged into `config.yml` (both keys `false` at first).
3. A curated stackable blueprint with a display name, e.g. **Phoenix Bread** (`minecraft:bread`, display name
   `&6Phoenix Bread`), and a kit that hands out 16 of it.
4. A REST client with a Staff token (`knk.admin.content`) and one with a Visitor token, or Swagger.

### 0.1 Steps

1. [automated: knk-web-api `MinecraftCatalogScanServiceTests.Ingest_GeneratesVanillaShadowBlueprints_ForObtainableItemsWithoutOne`,
   `VanillaShadowBlueprintsTests`] As Staff, run a catalogue scan and wait for "Completed". Call
   `GET api/ItemIdentity/report`. **Expected:** `obtainableMaterials` is well over 1,000, `unmatchedMaterials` is
   empty, `shadowMatches` + `curatedMatches` = `matchedMaterials` = `obtainableMaterials`. In the web app's item
   blueprint list, the category "Uncurated" holds blueprints such as "Oak Log" with an empty display name; no
   shadow exists for `minecraft:barrier`, `minecraft:command_block` or any spawn egg. (A04)
2. [automated: `VanillaShadowBlueprintsTests.Generate_LeavesCuratedMatches_AndIsIdempotent`] Call
   `POST api/ItemIdentity/shadows/generate` twice. **Expected:** both answer `created: 0` and the same
   `alreadyMatched`; no blueprint is added. (D11)
3. [automated: `ItemIdentityServiceTests.SetMatch_MovesTheMatchFromTheShadowToACuratedBlueprint`,
   `ItemIdentityMySqlTests.Generate_ThenMoveTheMatch_KeepsOneBlueprintPerMaterial`] Look up the id of
   `minecraft:bread` in the material catalogue, then call `PUT api/ItemIdentity/matches/<that id>` with
   `{ "itemBlueprintId": <Phoenix Bread's id> }`. **Expected:** the answer names the bread shadow as
   `previousBlueprintId`; `GET api/ItemIdentity/material-map` lists `minecraft:bread` with Phoenix Bread's id and
   `"shadow": false`; the report's `curatedMatches` went up by one. (A04)
4. [automated: `AddItemIdentityTests`, `ItemIdentityMySqlTests.UniqueIndex_AllowsManyUnmatchedBlueprints_ButOnlyOneMatchPerMaterial`]
   On the database run `SELECT VanillaMaterialMatchRefId, COUNT(*) FROM item_blueprints WHERE VanillaMaterialMatchRefId
   IS NOT NULL GROUP BY 1 HAVING COUNT(*) > 1;`. **Expected:** no rows. (A04)
5. [automated: `ItemIdentityControllerAccessTests`, `ReadAccessRulesTests`, `EndpointAccessRulesTests`] As Visitor,
   call `GET api/ItemIdentity/report`, `POST api/ItemIdentity/shadows/generate` and
   `POST api/ItemIdentity/conversion-counts`. **Expected:** 403 for all three; nothing changes.
6. [partly automated: knk-plugin `BlueprintItemAssemblerIdentityTest.identityOff_kitItemsAreBuiltAsBefore_withoutATag`,
   `ItemIdentityServiceTest.bundledConfig_shipsBothSwitchesOff`, `BlueprintTagTest.stampingIsOffByDefault_itemsAreBuiltAsBefore`;
   by hand: a real server] With both `items.identity` keys `false`, start the server, claim the Phoenix Bread kit and
   hold the bread. Run `/data get entity <you> SelectedItem`. **Expected:** no `[ItemIdentity]` line in the startup
   log; the bread has no `knightsandkings:knk_blueprint` in its custom data; kits and lootboxes behave as before.
7. Set `items.identity.enabled: true`, `convert-on-obtain: true` and `report-interval-minutes: 1`, restart.
   **Expected:** the log shows `[ItemIdentity] enabled; conversion hooks on` and
   `[ItemIdentity] material map: <n> materials with a blueprint` with n = the report's `matchedMaterials`.
   (Manual: a real server and API.)
8. [automated: `BlueprintItemAssemblerIdentityTest.identityOn_aCustomBlueprintItemIsTagged`] Claim the Phoenix Bread
   kit again and run `/data get entity <you> SelectedItem`. **Expected:** the custom data holds
   `"knightsandkings:knk_blueprint": <Phoenix Bread's id>`.
9. [automated: `BlueprintItemAssemblerIdentityTest.identityOn_aShadowBlueprintBuildsThePlainVanillaItem_whichStacksWithVanilla`,
   `BlueprintTagTest.aPlainItemStillStacksWithVanilla_andATaggedPlainOneDoesOnceNormalised`] Give yourself the
   "Oak Log" shadow with `/knk itemblueprints give`, then chop an oak log and pick it up. **Expected:** the given logs
   carry no blueprint tag and the picked-up log joins the same stack, exactly as in vanilla.
10. [partly automated: `ItemConversionListenerTest`; by hand: the real events on a server] Within one minute: mine a
    block, kill a cow, catch a fish, craft bread, trade with a villager, and open a chest you never opened since the
    restart (a world-generated loot chest if you have one). **Expected:** every item behaves and stacks as in vanilla;
    after a minute the log shows `[ItemIdentity] conversions since the last report: vanilla_match=<n>`, and
    `GET api/ItemIdentity/report?days=1` lists `block_drop`, `pickup`, `entity_death`, `fishing`, `craft`, `trade`
    and `container_open` with outcome `vanilla_match`. Opening the same chest again adds nothing to
    `container_open`. (A04)
11. [partly automated: `ItemConversionListenerTest.deathDrops_areNormalisedInPlace_andCustomItemsLeftAlone`,
    `ItemIdentityResolverTest.untaggedCustomItems_areUnresolved_withTheReason`; by hand: an anvil on a server] Rename
    a bread in an anvil, drop it and pick it up twice. **Expected:** the name stays; the log says once
    `[ItemIdentity] left alone (unresolved_custom_name): minecraft:bread from pickup`; the report's `topUnresolved`
    lists `minecraft:bread` with `unresolved_custom_name`.
12. [partly automated: `ItemIdentityServiceTest.convert_leavesPlainItemsAlone_stripsAStaleTag_andCountsTheStackSize`;
    by hand: the command] Give yourself a plain oak log with a stale tag:
    `/give @s oak_log[custom_data={PublicBukkitValues:{"knightsandkings:knk_blueprint":999}}] 4`, drop it and pick it
    up. **Expected:** it loses the tag on pickup and joins your plain oak log stack; the report counts it as
    `normalized`. (Retag rule.)
13. Claim a kit and open a lootbox token with the keys on (#261 must keep working). **Expected:** both deliver as
    before; customised items carry `knk_blueprint`, unique lootbox items also keep `knk_item_instance`; plain items
    carry no tag. (Manual: real delivery.)
14. Known limit: hold a Phoenix Bread claimed in step 6 (untagged) and one from step 8 (tagged). **Expected:** they do
    not stack, and the old one is reported as `unresolved_custom_name`. Follow-up:
    [PandiO/knk-workspace#791](https://github.com/PandiO/knk-workspace/issues/791). (Manual.)

## 1. Territory V1 (#326 API, #689 plugin, #690 web app; tier:3)

Built so far: link L1, the API (knk-web-api, migration `AddTerritory`, in `next`), link L2, the plugin (#689:
chunk cache, lookup, report; in `next`, steps 1.3), and link L3, the web app (#690: the territory dashboards and
forms, the town, conflict and structure pages, the production settings; steps 1.4). Map outlines wait for
[#802](https://github.com/PandiO/knk-workspace/issues/802). The API keeps the inputs (holders, regions, power, settings, awards)
and the results the game server reports (conflicts, structure flags); the game server computes the territory itself.
Full manual run of 1.2 about 30 minutes with a REST client, the untagged steps only about 5 minutes.

### 1.0 Preconditions

1. knk-web-api from `next` (`0d6e369a` or later) with migration `AddTerritory` applied (`dotnet ef database update`).
2. A REST client (or Swagger) with three callers: a **Staff** token (`knk.admin.world` and `knk.admin.content`), a
   **Visitor** token (no staff nodes), and the **plugin key** (`X-API-Key` = `Security:PluginApiKey`) for the steps
   that play the game server.
3. Test data: towns **Phoenix** (two districts, call them Old Town and Market) and **Rivertown** (one district), as in
   the common preconditions.
4. For 1.3: the plugin build of #689 (its own preconditions in 1.3).
5. For 1.4: the web app build of #690 against that API, the form and display seeds imported (1.2 step 17), and two
   web app accounts: **Admin** (holds `*`) and **Content staff** (`knk.admin.content` without `knk.admin.world`).

### 1.1 Settings

1. [automated: knk-web-api `ProductionSettingsTests.Defaults_FlagOff_AndTheDesignRanges`] As Staff, call
   `GET api/GameSettings`. **Expected:** `production.enabled` is `false` and `production.territory` is
   `{ "baseRange": 100, "powerFactor": 2, "capitalMultiplier": 1.5 }` (G16, territory DESIGN § 1).
2. [automated: `ProductionSettingsTests.Update_StoresTheSection_AndNullKeepsIt`,
   `ProductionSettingsTests.Update_OutOfBounds_IsRefused`] Send `PUT api/GameSettings` with the body of step 1's
   answer and `"production": { "enabled": true, "territory": { "baseRange": 100, "powerFactor": 2,
   "capitalMultiplier": 1.5 } }`. **Expected:** the answer shows `production.enabled: true`. Send it again with
   `"capitalMultiplier": 0.5`. **Expected:** 400 (`capitalMultiplier must be between 1 and 10`); nothing changes.

### 1.2 Steps (API)

1. [automated: `TerritoryHolderServicesTests.Kingdom_NameIsUniqueIgnoringCase_AndTrimmed`,
   `TerritoryHolderServicesTests.Province_NeedsAKingdom_AndItsNameIsUniqueThere`] As Staff, `POST api/Kingdoms`
   `{ "name": "Aurelia" }`, then `POST api/Provinces` `{ "name": "North", "kingdomId": <Aurelia> }`. **Expected:** 201
   for both; a second kingdom named `aurelia` answers 400.
2. [automated: `TerritoryHolderServicesTests.Town_ProvinceMustBeInTheTownsKingdom`,
   `TerritoryHolderServicesTests.Town_TerritoryFields_AreAppliedOnlyWhenPowerIsOnTheForm`] `GET api/Towns/<Phoenix>`,
   then `PUT api/Towns/<Phoenix>` with that body plus `"power": 50, "kingdomId": <Aurelia>, "provinceId": <North>`; do
   the same for Rivertown with `"power": 10, "kingdomId": <Aurelia>, "provinceId": null`. **Expected:** 204; a GET shows
   `power`, `kingdomName` "Aurelia" and Phoenix's `provinceName` "North". A PUT with a `provinceId` of a province in
   another kingdom answers 400. A PUT without `power` (an older town form) leaves all three as they are.
3. [automated: `TerritoryServiceTests.TownTerritory_ShowsTheEffectiveRanges`,
   `TerritoryRulesTests.Range_IsBasePlusPowerTimesFactor_AndTheCapitalIsMultiplied`] `PUT api/Districts/<Old Town>`
   with its body plus `"isCapital": true`. Call `GET api/Territory/towns/<Phoenix>`. **Expected:** `range` 200
   (100 + 50 × 2), `capitalRange` 300, Old Town listed with `range` 300 and Market with 200. (A05, G11)
4. [automated: `TerritoryHolderServicesTests.CrownLand_IsADomainOwnedByAKingdom_WithARange`] `POST api/CrownLands`
   `{ "name": "Royal forest", "description": "Hunting grounds", "wgRegionId": "<an existing region>", "worldName":
   "world", "kingdomId": <Aurelia>, "range": 80 }`. **Expected:** 201; the crown land is also a domain
   (`GET api/Domains/<id>` finds it). A range of -1 or 10001 answers 400. (G10)
5. [automated: `TerritoryServiceTests.Inputs_HoldEveryRegionWithItsHolderAndComputedRange`,
   `TerritoryServiceTests.Inputs_CrownLand_IsHeldByItsKingdom_WithItsOwnRange_AndRankTwo`,
   `TerritoryServiceTests.Inputs_Version_ChangesWithAnInput_AndOnlyThen`] With the plugin key, call
   `GET api/Territory/inputs`. **Expected:** `productionEnabled: true`; every district with its town as `holder`,
   `rank` 1 and the ranges of step 3 (sub-regions listed in `subRegionIds`); Royal forest under `crownLands` with
   holder `Kingdom` Aurelia, `rank` 2 and `range` 80; a `version`. Call it again: the same `version`. Change Phoenix's
   power to 20 (step 2) and call it again: a new `version` and Market's `range` 140.
6. [automated: knk-web-api `TerritoryRealtimeEventTests` (all)] With a game server connected to the realtime hub
   (or the hub log at Debug), change Phoenix's power. **Expected:** one `TerritoryChanged` event with scope
   `territory`. Changing only Phoenix's description sends none. (Manual check needs a connected server.)
7. [automated: `TerritoryServiceTests.Report_WithProductionOff_IsRefused_AndWritesNothing`] Turn
   `production.enabled` off (1.1 step 2). With the plugin key, `PUT api/Territory/report`
   `{ "world": "world", "overlaps": [ { "holderA": { "kind": "Town", "id": <Phoenix> }, "holderB": { "kind": "Town",
   "id": <Rivertown> }, "chunks": [[4,2],[5,2]] } ] }`. **Expected:** 409 with `code: "ProductionDisabled"`;
   `GET api/TerritoryConflicts` is empty. The admin reads of steps 1-5 still work. Turn the flag on again. (A21, G16)
8. [automated: `TerritoryServiceTests.Report_EqualRankOverlap_CreatesOneConflict_ThenUpdatesIt`] Send the report of
   step 7 again (flag on), then once more with a third chunk `[6,2]`. **Expected:** the first answer has
   `conflictsCreated: 1`, the second `conflictsUpdated: 1`; `GET api/TerritoryConflicts` lists one open conflict
   "Phoenix" / "Rivertown" with `chunkCount` 3. (A05)
9. [automated: `TerritoryServiceTests.Report_TownAgainstCrownLand_OrUnknownHolders_IsSkipped`] Report an overlap of
   Phoenix and `{ "kind": "Kingdom", "id": <Aurelia> }`. **Expected:** the answer lists it under `skipped` (crown land
   outranks towns); no conflict is created. (G10)
10. [automated: `TerritoryServiceTests.Report_FlagsStructures_ListsContestedOnesOnTheConflict_AndClearsThemLater`]
    Report step 8's overlap with `"structures": [ { "structureId": <a structure in Market>, "flag": "Contested",
    "holderA": { "kind": "Town", "id": <Phoenix> }, "holderB": { "kind": "Town", "id": <Rivertown> } } ]`.
    **Expected:** `GET api/TerritoryConflicts/<id>` lists the structure under `flaggedStructures`;
    `GET api/Territory/structures/<id>` shows `territoryFlag: "Contested"` and the conflict id; the structure's
    district (and so its town) is unchanged. Send a report without structures: the flag is cleared. (Territory § 4)
11. [automated: `TerritoryServiceTests.Report_AnOverlapThatIsGone_StaysOpen_ButIsMarkedNotOverlapping`] Send
    `{ "world": "world" }` (no overlaps). **Expected:** `conflictsNoLongerOverlapping: 1`; the conflict stays open
    with `stillOverlapping: false` (nothing is resolved automatically).
12. [automated: `TerritoryConflictServiceTests.Award_ToOneHolder_ResolvesIt_AndReachesTheInputs`,
    `TerritoryConflictServiceTests.Award_ToAThirdHolder_IsRefused`] As Staff,
    `POST api/TerritoryConflicts/<id>/resolve` `{ "resolution": "Awarded", "awardedHolder": { "kind": "Town", "id":
    <Phoenix> }, "note": "test" }`. **Expected:** status `Resolved`, `awardedHolder` Phoenix;
    `GET api/Territory/inputs` lists the award with the conflict's chunks; a `TerritoryChanged` event is sent. An award
    to Aurelia answers 400.
13. [automated: `TerritoryConflictServiceTests.Reopen_UndoesTheResolution`,
    `TerritoryConflictServiceTests.Redrawn_ResolvesWithoutAnAward_AndTwiceIsRefused`] `POST .../reopen`, then resolve
    with `{ "resolution": "Redrawn" }`. **Expected:** reopen clears the award (gone from the inputs); "Redrawn" resolves
    without an award; resolving again answers 409.
14. [automated: `TerritoryServiceTests.Loyalty_IsStored_AndClearedWithNull`] `PUT api/Territory/structures/<id>/loyalty`
    `{ "loyaltyTownId": <Rivertown> }`, then `{ "loyaltyTownId": null }`. **Expected:** the first answer shows
    `loyaltyTownName` "Rivertown" next to its own `townId` Phoenix; the second clears it. Nothing else happens (stored
    only in V1).
15. [automated: knk-web-api `EndpointAccessRulesTests`, `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests`,
    `DeleteAccessRulesTests`] As Visitor, call `POST api/Kingdoms`, `PUT api/Towns/<Phoenix>` with a new power,
    `POST api/TerritoryConflicts/<id>/resolve` and `GET api/Territory/inputs`; with the Staff token call
    `PUT api/Territory/report`. **Expected:** 403 for each; nothing changes. (Smoke 1.3 step 9)
16. [automated: `TerritoryHolderServicesTests.Kingdom_WithTowns_CannotBeDeleted`,
    `TerritoryHolderServicesTests.Province_WithTowns_CannotMoveKingdom_OrBeDeleted`] As Staff with `knk.admin.delete`,
    `DELETE api/Kingdoms/<Aurelia>` and `DELETE api/Provinces/<North>`. **Expected:** 409 naming what still belongs to
    them; nothing is deleted.
17. [automated: `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests`] In the web app's form
    configuration list, Import / seeds: import `Kingdom`, then `Province`, `CrownLand` and `TerritoryConflict` with
    "make default", and the four display seeds. **Expected:** each imports; `/forms/kingdom` and `/forms/crownland`
    open their create forms, and the crown land form's Region field offers Send to Minecraft. (A23, G17)

### 1.3 Steps (plugin #689)

Built by link L2 (knk-plugin `next` `55804b11`). Extra preconditions:

1. The plugin build from knk-plugin `next` on a test server with WorldGuard, connected to the API of 1.0 (realtime on:
   `realtime.enabled: true`, for steps 9 and 12).
2. The test data of 1.2 steps 1-5: Phoenix power 50 (Market range 200, Old Town capital range 300), Rivertown power 10
   (range 120), crown land Royal forest (Aurelia, range 80); the regions exist in the world. API game setting
   `production.enabled` on.
3. In game: **Staff** holds `knk.admin.world.territory` (or `knk.admin.*`); **Visitor** holds no staff node.
4. `production` block merged into `plugins/KnightsAndKings/config.yml` (plugin configuration § 4.31), `enabled: false`
   at first.

Full manual run about 40 minutes; the untagged and partly tagged parts about 25 minutes.

1. [partly automated: knk-plugin `TerritoryConfigTest.theBundledConfig_hasTheFeatureOff_withTheDocumentedDefaults`,
   `TerritoryAdminCommandTest.withProductionOff_everyFormSaysSo`,
   `CrownLandManagedRegionTest.withProductionOff_crownLandRegionsAreLeftAlone`; by hand: the log of a real start]
   Start the server with `production.enabled: false`. As Staff, type `/knk territory here` and `/knk regions repair`.
   **Expected:** no `[KnK Territory]` line in the log; `/knk territory here` answers "Territory is off on this server
   (production.enabled: false)."; the repair does not list the Royal forest region. (A21)
2. [partly automated: `TerritoryServiceTest.theFirstRefresh_buildsTheCache_warnsAboutAMissingRegion_andReports`,
   `TerritoryConfigTest.theValuesAreRead`; by hand: the log lines on a real server] Set `production.enabled: true`,
   restart. **Expected:** the log shows `[KnK Territory] On (production.enabled): first build in 5 s, ...`, then within
   about 10 s `[KnK Territory] Cache rebuilt (startup): <n> chunks (<s> split) in 1 world(s), version ...`. As Staff,
   `/knk territory status`. **Expected:** sources = the districts and crown lands with a region, `API
   Production:Enabled: true`; a district whose region does not exist is named in a warning line.
3. [automated: `TerritoryCacheBuilderTest.aColumnWithinRangeOfTheNearestEdge_belongsToTheTown_theNextOneIsWilderness`,
   `TerritoryCacheBuilderTest.theCapitalsLargerRange_reachesFurther`,
   `TerritoryShapeTest.insideAndOnTheEdge_isZero_outsideIsTheDistanceToTheNearestEdge`] As Staff, stand 150 blocks
   outside the nearest edge of Market's region and type `/knk territory here`. **Expected:** Phoenix. Stand 250 blocks
   from Old Town's edge and more than 200 from every other Phoenix district. **Expected:** Phoenix (capital range).
   Stand 350 blocks from every district. **Expected:** wilderness. (A05, G11)
4. [automated: `TerritoryCacheBuilderTest.aDiagonalBorder_changesPerBlockColumnInsideTheSplitChunk`,
   `TerritoryTrackerTest.insideASplitChunk_everyColumnIsLookedUp`, plugin scenario `territory-border-crossing`]
   Find Phoenix's border where it runs diagonally (near a slanted district edge or a corner) and type
   `/knk territory here` on both sides of it. **Expected:** the answer says `split` for that chunk, and the holder
   changes from one block column to the next, not at the 16-block chunk edge. (A05)
5. [automated: plugin scenario `territory-border-crossing`,
   `TerritoryListenerTest.crossingTheBorder_firesTheEvent_andShowsTheLine_movesInsideDoNot`,
   `TerritoryTrackerTest.leavingAndEntering_areChanges_movesInsideTheAreaAreNot`] As Visitor, walk out of Phoenix's
   territory into the wilderness, then back in; walk around inside it. **Expected:** leaving shows the action bar
   "Leaving Phoenix: wilderness", coming back "Entering the territory of Phoenix"; walking inside shows nothing.
6. [automated: `TerritoryCacheBuilderTest.crownLand_outranksTheTown_withoutAContest`,
   `TerritoryReportBuilderTest.townAgainstCrownLand_isNoOverlap`] Walk into the part of Royal forest's range that
   Phoenix's territory also reaches. **Expected:** the action bar "Entering the crown land of Aurelia";
   `/knk territory here` says "crown land of Aurelia"; after a `/knk territory rebuild`,
   `GET api/TerritoryConflicts` lists no conflict for it. (G10)
7. [automated: `CrownLandManagedRegionTest.withProductionEnabled_theRepairManagesCrownLandRegions_topLevel`,
   `CrownLandManagedRegionTest.crownLand_isItsOwnKind_atTheTownsFloor_withoutFlags`] As Staff, `/knk regions repair`,
   then `/rg info <Royal forest's region>`. **Expected:** priority 10, no parent, no flags added by the repair.
8. [partly automated: `TerritoryReportBuilderTest.anEqualRankOverlap_isReportedOnceWithEveryChunkItTouches`,
   `TerritoryServiceTest.theFirstRefresh_buildsTheCache_warnsAboutAMissingRegion_andReports`,
   `TerritoryApiImplTest.report_putsTheSnapshotWithTheKey_andReadsTheResult`; by hand: the conflict from a real server]
   Raise Rivertown's power (1.2 step 2) until its territory overlaps Phoenix's. **Expected:** within a few seconds the
   log shows `Cache rebuilt (TerritoryChanged)` and `Report for world: 1 overlap(s), ...; conflicts created 1`;
   `/knk territory here` in the overlap says "contested: Phoenix / Rivertown" and walking in shows "Entering contested
   land: Phoenix / Rivertown"; `GET api/TerritoryConflicts` lists one open conflict Phoenix / Rivertown whose chunks
   cover the overlap. (A05)
9. [partly automated: `TerritoryReportBuilderTest.structures_areFlaggedContestedOrOutside_andLeftAloneInTheirOwnTerritory`;
   by hand: the flags in the API] Have a Phoenix structure (with a region) standing in the overlap and one standing
   outside every territory, then `/knk territory rebuild`. **Expected:** `GET api/Territory/structures/<id>` shows
   `Contested` (with the conflict id) for the first and `OutsideTerritory` for the second; a structure in Phoenix's own
   land has no flag. Their districts and towns are unchanged. (Territory § 4)
10. [partly automated: `TerritoryCacheBuilderTest.twoTownsOverlapping_isContested_andAnAwardGivesItsChunksToOne`; by
    hand: the realtime path] Resolve the conflict by awarding it to Phoenix (1.2 step 12). **Expected:** within a few
    seconds the cache rebuilds; `/knk territory here` in the awarded chunks says Phoenix ("Awarded by an admin; also
    reached by 2 holders."); walking in shows "Entering the territory of Phoenix".
11. [automated: `TerritoryServiceTest.withTheApiFlagOff_nothingIsReported`,
    `TerritoryAdminCommandTest.status_showsTheCacheAndThatTheReportWasNotSent`,
    `TerritoryServiceTest.aRefusedReport_isLoggedAndNamed_notThrown`] Turn the API's `production.enabled` off (1.1
    step 2), then `/knk territory rebuild` and `/knk territory status`. **Expected:** the lookup still works; status
    shows `Last report: not sent: the API's Production:Enabled is off`; nothing is written to the conflicts. Turn it on
    again.
12. [partly automated: `TerritoryServiceTest.unchangedInputsAndShapes_skipTheRebuild_aNewVersionOrShapeOrForceDoesNot`;
    by hand: the event on a connected server] Change Phoenix's power to 20. **Expected:** within a few seconds the log
    shows `Cache rebuilt (TerritoryChanged)` with a new version; 150 blocks from Market is now wilderness (range 140).
    Change only Phoenix's description: no rebuild line.
13. [automated: knk-plugin `CommandRegistryPermissionsTest` (the `/knk` node check),
    `TerritoryAdminCommandTest.completesTheActions_andShowsUsageOtherwise`] As Visitor, type `/knk territory here`.
    **Expected:** "You don't have permission to use this command."; nothing else happens.
14. Not testable until [#802](https://github.com/PandiO/knk-workspace/issues/802) (API and map bridge): with
    `production.territory.map-outlines: true` and the overview map open, Phoenix, Rivertown and the crown land are
    outlined as the lookup says, contested land shown as contested; a power change redraws them within a minute. Keep
    `map-outlines: false` until then. [partly automated: `TerritoryOutlinesTest` (all),
    `TerritoryServiceTest.mapOutlines_areSentPerWorld_onlyWhenSwitchedOn`]

### 1.4 Steps (web app #690)

The tags name tests in knk-web-app `e2e/territory.spec.ts` (Playwright, mocked API). A full manual run takes about 25
minutes; the untagged parts of the two partly automated steps (the province form and the crown land region drawn in
game) about 5 minutes. The town's power, kingdom, province and capital districts are set on the town's page (Territory
panel); the seeded Town and District forms do not have those fields yet (seed follow-up on #690).

1. [automated: `game settings › shows the production flag and the range settings with an example (G11)`] As Admin,
   open **Game settings** (`/admin/game-settings`). **Expected:** a "Production and territory" card with "Production
   enabled" unticked, Base range (blocks) 100, Blocks per power point 2, Capital multiplier 1.5, and the line "A town
   of power 50: (100 + 50 × 2) = 200 blocks; its capital (100 + 50 × 2) × 1.5 = 300 blocks." (G11, G16)
2. [automated: `game settings › says which value the API would refuse`, `game settings › saves the flag and the
   ranges in the production section`] Type 0.5 as Capital multiplier. **Expected:** a red line
   "production.territory.capitalMultiplier must be between 1 and 10." and Save is off. Type 1.5 again, tick
   "Production enabled" and press Save. **Expected:** "Game settings saved."; after Reload the box is still ticked.
   (Untick it again at the end if the plugin #689 is not deployed, A21.)
3. [automated: `the form wizard › saves a kingdom through POST api/Kingdoms`, `dashboard › lists the kingdoms with
   their town and crown land counts`] Open the dashboard, type **Kingdom**, press Create; fill Name "Aurelia" and
   Description "The northern crown" and submit. **Expected:** the kingdom is saved; the Kingdom table lists Aurelia
   with columns Towns 0 and Crown land 0.
4. [partly automated: `dashboard › lists provinces with their kingdom and crown land with its kingdom and range`; by
   hand: the seeded Province form, the same form wizard path as step 3] Dashboard type **Province**, Create: Name
   "North", Kingdom "Aurelia" (picked from the list), submit. **Expected:** the Province table lists North with Kingdom
   Aurelia and Towns 0.
5. [automated: `the town page › saves power, kingdom and province with every other town setting left alone`, `the
   town page › shows the town's power, kingdom, province and effective ranges (A05, G11)`] Open Phoenix's page
   (dashboard Town, View). Below the details, the **Territory** panel shows Power 0, Kingdom None, Province None. Press
   **Edit territory**, set Power 50, Kingdom Aurelia, Province North (the list shows only Aurelia's provinces; changing
   the kingdom empties it), press **Save territory**. **Expected:** "Territory of Phoenix saved."; Power 50, Kingdom and
   Province link to Aurelia and North; Range "200 blocks; capital districts 300 blocks". Open Phoenix's edit form:
   its warp (teleport) and /navigate settings are unchanged. Do the same for Rivertown with Power 10, Kingdom Aurelia,
   Province None.
6. [automated: `the town page › marks a district as capital through its own save`] On Phoenix's Territory panel, under
   Districts, press **Make Old Town a capital**. **Expected:** "Old Town is now a capital district."; Old Town shows
   "Capital" and 300 blocks, Market 200 blocks. Opening Old Town's edit form shows its streets unchanged. (A05, G11;
   1.3 step 1)
7. [automated: `the town page › refuses a power out of range before saving`] Edit territory again and type -5 as
   Power. **Expected:** the hint under Power turns red and **Save territory** is off; Cancel leaves Power 50.
8. [partly automated: `the form wizard › saves crown land with its kingdom (picked from api/Kingdoms) and range
   (G10)`; by hand: the region step, which needs a connected game server] Dashboard type **CrownLand**, Create: Name
   "Royal forest", Description "Hunting grounds", Kingdom Aurelia (picker), Range (blocks) 80; next step **Region and
   access**: press Send to Minecraft, select the area in game with WorldEdit and confirm, keep Allow entry and Allow
   exit ticked, submit. **Expected:** the CrownLand table lists Royal forest with Kingdom Aurelia, Range (blocks) 80 and
   its world; in game the region is named `domain_<id>`. (G10)
9. [automated: `dashboard › lists the conflicts with their state, area size and flagged structures (A05)`, `the
   conflict page › shows the holders, the area and the flagged structures (A05)`] Needs an open conflict between
   Phoenix and Rivertown with a structure in it (1.2 steps 8 and 10 with the plugin key, or 1.3 step 5 in game).
   Dashboard type **TerritoryConflict**. **Expected:** a row "Phoenix vs Rivertown" with Status Open, Still overlapping
   Yes, the chunk count and Flagged structures 1. View it: the **Contested zone** panel shows the holders "Phoenix
   (town)" and "Rivertown (town)" as links, State Open, the world, the area as chunk and block ranges, when it was
   detected and last reported, and the flagged structure as a link. (A05)
10. [automated: `the conflict page › awards the area to one holder with a note, then reopens it`, `the conflict page
    › cancelling the question resolves nothing`] Type the note "Phoenix was there first", press **Award to Phoenix**
    and confirm in the question. **Expected:** "Conflict resolved."; State "Resolved: awarded to Phoenix (town)" and
    the resolved time with the note; `GET api/Territory/inputs` lists the award. Press **Reopen** and confirm.
    **Expected:** State Open; the award is gone from the inputs. Press Award to Rivertown and Cancel: nothing changes.
11. [automated: `the conflict page › marks the lines redrawn without an award`] Press **Mark the lines redrawn** and
    confirm. **Expected:** State "Resolved: lines redrawn"; no award in the inputs.
12. [automated: `the structure page › shows the flag with its conflict and the own town (A07)`] Open the flagged
    structure's page. **Expected:** a **Territory and loyalty** panel: Territory "In a contested zone (since …)",
    Conflict "Conflict #<id>" linking to the conflict, Own town Phoenix, Loyal to "Its own town". (A07)
13. [automated: `the structure page › sets and clears the loyalty (stored only)`] Pick Loyalty "Rivertown" (Phoenix,
    its own town, is not in the list) and press **Save loyalty**. **Expected:** "Loyalty saved."; Loyal to Rivertown.
    Pick "Its own town" and save: Loyal to "Its own town". Nothing else changes (stored only in V1).
14. [automated: `the structure page › clears the flag by hand`] Press **Clear flag**. **Expected:** "Flag cleared.";
    Territory "Inside its town's territory" and no Clear flag button. The game server's next report sets the flag
    again while it still applies.
15. [automated: `dashboard › content-only staff do not get the territory types`, `the town page › staff without
    knk.admin.world see the territory but cannot change it`, `the conflict page › staff without knk.admin.world cannot
    resolve`, `the structure page › staff without knk.admin.world see the flag but cannot change the loyalty`] Log in
    as **Content staff** (no `knk.admin.world`). **Expected:** the dashboard offers no Kingdom, Province, CrownLand or
    TerritoryConflict. Open Phoenix's page by its address: the API refuses the reads without `knk.admin.world`, so
    the Territory panel shows the refusal instead of values and offers no Edit territory or capital buttons; a
    conflict's and a structure's page likewise offer no award, redrawn, loyalty or Clear flag action. The API refuses
    the writes too (1.2 step 15). (1.3 step 9. The tests also check that with the reads allowed but no
    `knk.admin.world`, those buttons are shown off with "Requires knk.admin.world".)

## 2. Phase P1: stock core (#97 API, #675 web app; tier:3)

Built so far: link L4, the API (knk-web-api, migration `AddStockCore`; branch `claude/production-p1`, PR into `next`).
The web app screens (storage pages, adjust and move dialogs, the ledger explorer) are link L5 (#675), § 2.2; the § 2.1
steps run with a REST client (or Swagger) against the API. Stock moves only through `api/StockTransactions`; capacity,
missing stock and locks come back as a result with a status (200), never as an error. 17 steps: 15 automated in CI, 2
partly (tagged); every step can still be run by hand; manual steps not run. Full manual run about 40 minutes; the
untagged parts of the partly tagged steps about 10 minutes.

### 2.0 Preconditions

1. knk-web-api from the branch with migration `AddStockCore` applied (`dotnet ef database update`).
2. Item identity (#141) deployed; the "Uncurated" category holds the generated vanilla blueprints. Note the ids of
   **Oak log** and **Stone** (`GET api/ItemIdentity/material-map` or the blueprint list). (A04)
3. One enchanted sword as an item instance (for example from a lootbox claim); note its item instance id.
4. Callers: a **Staff** token holding `knk.admin.world`, `knk.admin.content` and `knk.economy.admin` (the economy node
   is not under `knk.admin`, so `knk.admin.*` does not grant it; only `*` or an explicit grant), a **World staff** token
   with `knk.admin.world` but without `knk.economy.admin`, and a **Visitor** token (no staff nodes).
5. Town **Phoenix** (common preconditions). The form and display seeds `Storage` and `StockTransaction` are imported
   (step 1).

### 2.1 Steps

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs, imports and is the default on a fresh database); by hand: open the form in the web app] As Staff, import
   the form seeds `Storage` and `StockTransaction` and the display seeds `Storage` and `StockTransaction` ("make
   default"). Open the create form for a storage in the web app. Create **S1**: kind Domain, domain Phoenix, max units
   100; and **S2**: kind Domain, domain Phoenix, max units 50 (or `POST api/Storages` with
   `{ "name": "S1", "kind": "Domain", "domainId": <Phoenix>, "maxUnits": 100 }`). **Expected:** the form comes from the
   seed and both storages save; their pages show holder Phoenix, total 0. (A23)
2. [automated: `StockLedgerMySqlTests.Migration_SeedsTheFiveSystemStorages`, `StorageServiceTests.SystemStorages_CannotBeEditedOrDeleted`]
   Call `POST api/Storages/search` with `{ "filters": { "kind": "Virtual" } }`. **Expected:** five storages
   `SYS_PRODUCTION`, `SYS_CONSUMPTION`, `SYS_LOSS`, `SYS_ADJUSTMENT`, `SYS_WORLD`. `DELETE api/Storages/<SYS_LOSS id>`
   answers 409.
3. [automated: `StockServiceTests.Adjust_PutsStockIn_FromSysAdjustment_AsOneAdminAdjustTransaction`, `StockControllersTests.Adjust_RecordsTheWebUserAsActor`]
   `POST api/StockTransactions/adjust` with `{ "storageId": <S1>, "itemBlueprintId": <Oak log>, "delta": 64, "note":
   "smoke 2.1.3" }`. **Expected:** status `Applied`; `GET api/Storages/<S1>` lists Oak log 64 and total units 64;
   `POST api/StockTransactions/search` with `{ "filters": { "reason": "AdminAdjust" } }` lists one transaction with
   your user id and the note; its one move goes from `SYS_ADJUSTMENT` to S1. (A01)
4. [automated: `StockServiceTests.Move_DebitsOneStorage_AndCreditsAnother_InOneTransaction`] `POST api/StockTransactions`
   with `{ "reason": "Distribution", "lines": [ { "fromStorageId": <S1>, "toStorageId": <S2>, "itemBlueprintId": <Oak
   log>, "amount": 30 } ] }`. **Expected:** `Applied`; S1 34, S2 30; `GET api/StockTransactions/<id>` shows one
   transaction with one move S1 → S2 of 30. (A01)
5. [automated: `StockServiceTests.Move_WithTheSameIdempotencyKey_AppliesOnce_AndReplaysTheFirstResult`, `StockServiceTests.Move_WithAKeyUsedForAnotherRequest_IsRefused`, `StockLedgerMySqlTests.TwentyParallelIdenticalRequests_ApplyOnce`, `StockLedgerMySqlTests.OneKeyAcrossDifferentStorages_TheUniqueIndexLetsOneApply`]
   Send a move of 2 oak logs S1 → S2 with `"idempotencyKey": "smoke-2-1-5"` twice. **Expected:** the second answer has
   `"replayed": true` and the same transaction id; S1 32, S2 32 (applied once). Send it a third time with amount 3 and
   the same key. **Expected:** 409 `IdempotencyKeyReuse`; nothing changes. (A01)
6. [automated: `StockServiceTests.Move_OverCapacity_IsRefusedAllOrNothing_AndPartialAcceptsWhatFits`, `StockLedgerMySqlTests.ParallelMovesIntoACappedStorage_NeverPassTheCap`]
   Move 40 oak logs S1 → S2 (S2 has room for 18). **Expected:** status `Rejected`, line `rejectReason: CapacityFull`,
   no transaction, nothing changes. Send it again with `"mode": "Partial"`. **Expected:** `PartiallyApplied`, accepted
   18, rejected 22 (`CapacityFull`); S2 50, S1 14. (A02)
7. [automated: `StockServiceTests.Capacity_CountsRawUnitsTimesStorageWeight`, `StorageServiceTests.StorageWeight_IsValidated_AndNullKeeps`]
   Set Stone's storage weight to 2 (`PUT api/ItemBlueprints/<Stone>` with its current body plus `"storageWeight": 2`).
   Create **S3** (Domain, Phoenix, max units 50) and send a Partial move of 30 Stone from `SYS_PRODUCTION` to S3 with
   reason `Production`. **Expected:** 25 accepted, 5 rejected (`CapacityFull`): capacity counts raw units × storage
   weight. A blueprint saved without `storageWeight` keeps its weight. (A02)
8. [automated: `StockServiceTests.UniqueItem_KeepsItsIdentity_ThroughDepositMoveAndWithdrawal`, `StockControllersTests.UniqueItem_LineWithoutAmount_MovesOne`]
   Deposit the enchanted sword: move `{ "fromStorageId": <SYS_WORLD>, "toStorageId": <S1>, "itemInstanceId": <sword> }`
   with reason `Deposit`; move it S1 → S2 (reason `Distribution`); withdraw it S2 → `SYS_WORLD` (reason `Withdraw`).
   **Expected:** after each step `GET api/Storages/<id>` lists the same item instance id under unique items in the
   storage it was moved to, and nowhere else; after the withdrawal no storage lists it; `POST
   api/StockTransactions/moves/search` with `{ "filters": { "itemInstanceId": "<sword>" } }` shows three moves of the
   same id; a second withdrawal from S2 is `Rejected` with `NotEnoughStock`. (A03)
9. [automated: `StockServiceTests.LockedStorage_RefusesMovesInAndOut_UntilTheLockEnds`, `StorageServiceTests.Update_ChangesCapacityAndLock_AndBumpsTheRowVersion`]
   Lock S2: `PUT api/Storages/<S2>` with its body plus `"lockedUntil": "<one hour from now, UTC>", "lockReason":
   "smoke"`. Move 1 oak log S2 → S1 (a lock stops moves out as well as in). **Expected:** `Rejected`, `rejectReason:
   Locked`. Clear the lock (`lockedUntil`
   null) and move again. **Expected:** `Applied`. An update that sends an old `rowVersion` answers 409.
10. [automated: `StockServiceTests.Reverse_WritesACompensatingCorrection_Once`, `StockServiceTests.Reverse_WhenTheStockIsGone_IsRejected`]
    `POST api/StockTransactions/<id of step 4>/reverse` with `{ "note": "smoke undo" }`. **Expected:** `Applied`; a new
    transaction with reason `Correction` and `reversesTransactionId` = the step 4 id; 30 oak logs move S2 → S1 (if S2
    still holds them; otherwise `Rejected`, `NotEnoughStock`, and nothing changes); the step 4 transaction is
    unchanged and its page shows `reversedByTransactionId`. Reversing it again with another `idempotencyKey` answers
    409.
11. [automated: `StockControllersTests.LedgerReads_DrillDownFromALineToItsMoves`] Pick S1's Oak log amount and call
    `POST api/StockTransactions/moves/search` with `{ "filters": { "storageId": "<S1>", "itemBlueprintId": "<Oak
    log>" } }` (and `rollups/search` with the same filters). **Expected:** the moves into S1 minus the moves out of S1
    (plus roll-up rows) add up to the amount on S1's page; each row names both storages and the blueprint.
12. [automated: `StockReconcilerAndRollupTests.Reconciler_IsClean_AfterEveryKindOfPath`, `StockReconcilerAndRollupTests.Reconciler_FindsALineThatWasChangedOutsideTheLedger`, `StockLedgerMySqlTests.AThousandConcurrentMoves_LoseNoUpdate_AndTheReconcilerIsClean`]
    `GET api/StockTransactions/reconcile`. **Expected:** `"clean": true` and every difference count 0: for every
    blueprint the amounts over all storages, system storages included, sum to zero, and every line equals the net of
    its moves. (A01)
13. [automated: `StockReconcilerAndRollupTests.Rollup_SumsOldProductionMovesPerLinePerDay_AndKeepsTotals`, `StockReconcilerAndRollupTests.Rollup_AddsToTheSameDaysRow_AndSkipsReversedTransactions`, `StockLedgerMySqlTests.Rollup_ReplacesOldProductionMoves_AndKeepsTheReconcilerClean`]
    On a test database only: move 5 oak logs `SYS_PRODUCTION` → S1 three times (reason `Production`) and once S1 → S2
    (reason `Distribution`), then date them 31 days back in SQL: `UPDATE stock_transactions SET CreatedAt =
    CreatedAt - INTERVAL 31 DAY WHERE Id IN (…); UPDATE stock_moves SET CreatedAt = CreatedAt - INTERVAL 31 DAY WHERE
    TransactionId IN (…);`. Note S1's total. `POST api/StockTransactions/rollup`. **Expected:** the three `Production`
    transactions are rolled up into one row per day and line (`rollups/search` shows amount 15, move count 3); their
    transactions and moves are gone; the `Distribution` transaction keeps its row; S1's total is unchanged; the
    reconciler stays clean. (A22)
14. [partly automated: `StockReconcilerAndRollupTests.MaintenanceJob_RunsOnlyWithProductionEnabled`; by hand: the log]
    With the game setting `production.enabled` off, leave the API running for more than an hour. **Expected:** no
    "Stock reconciler" or "Stock roll-up" log line; storages, adjust, move, reverse, reconcile and roll-up by hand
    still work. Turn it on: within the hour the reconciler runs (a warning only when it finds a difference) and the
    roll-up runs once a day. (A21, G16)
15. [automated: `StockControllersTests.AVisitor_CannotMoveStock_ButTheSearchIsLeftToTheReadRule`, `StockControllersTests.Ledger_WritesNeedTheEconomyNode_ReadsFollowTheStockTransactionType`, `ReadAccessRulesTests.EveryReadEndpoint_HasItsPinnedCategory`]
    As Visitor, call `POST api/StockTransactions` (step 4's body) and `POST api/StockTransactions/adjust`.
    **Expected:** 403. As World staff, the ledger reads (`search`, `moves/search`, `GET <id>`, `reconcile`) answer
    200 and the move, adjust, reverse and roll-up answer 403.
16. [automated: `StorageServiceTests.Delete_OnlyAnEmptyStorageWithoutHistory`, `StorageServiceTests.Update_KindOrHolder_OnlyWithoutStockOrHistory`, `StorageServiceTests.Create_WithAHolderThatDoesNotMatchTheKind_IsRefused`]
    `DELETE api/Storages/<S1>`. **Expected:** 409 (it has stock or history). Create an empty storage for a player and
    one for a clan (kind Player with `userId`, kind Clan with `clanId`) and delete the player one. **Expected:** 204. A
    storage with a holder field that doesn't match its kind (kind Domain with `userId`) answers 400; changing S1's kind
    answers 409.
17. [automated: `StockLedgerMySqlTests.AThousandConcurrentMoves_LoseNoUpdate_AndTheReconcilerIsClean`, `StockLedgerMySqlTests.FiftyParallelMovesOfTen_FromOneHundred_ExactlyTenSucceed`, `StockLedgerMySqlTests.AMoveInsideTheCallersTransaction_IsRolledBackWithIt`]
    Optional by hand: with S1 at 100 oak logs, send 50 moves of 10 S1 → S2 at the same time (a REST runner with
    parallel requests). **Expected:** exactly 10 are `Applied`, 40 `Rejected` with `NotEnoughStock`; S1 0, S2 +100;
    the reconciler is clean. (A01)

### 2.2 Steps (web app #675)

Built in link L5 (knk-web-app, branch `claude/production-p1b`). The tags name tests in knk-web-app
`e2e/stock.spec.ts` (Playwright, mocked API; the mocks use the same data with other numbers where noted). Run § 2.1
steps 1-2 first (seeds imported, the five system storages), or start from a fresh test database; the numbers below
assume S1 and S2 are created here. Log in to the web app as **Staff** (holds `knk.admin.world`, `knk.admin.content`
and `knk.economy.admin`) unless a step says otherwise. 17 steps: 14 automated, 3 partly (tagged); every step can still
be run by hand; not run. Full manual run about 35 minutes; the untagged parts about 10 minutes.

1. [automated: `the storage form › saves a storage from the seeded form through POST api/Storages (A23)`] Open the
   dashboard, type **Storage**, press Create (the form comes from the `Storage` seed). Step **Storage**: Name "S1",
   Kind Domain, Purpose General, Domain "Phoenix" (picked from the list); press Next; step **Capacity and lock**: Max
   units 100; Submit. Create **S2** the same way with Purpose Output, Max units 50 and Max distinct items 4.
   **Expected:** both storages save. (A23)
2. [automated: `dashboard › lists the storages with their kind, holder, fill against the cap and lock`] On the
   dashboard type **Storage**. **Expected:** columns Kind, Purpose, Holder, Total units, Distinct items and Locked; S1
   shows Domain, General, Phoenix and Total units "0 / 100"; the five system storages show Kind Virtual and their key
   as holder.
3. [automated: `the storage page › shows capacity in raw units × storage weight, the lock, the lines and the unique
   items (A02, A03)`] View S1. **Expected:** below the details a **Stock** panel: Holder "Phoenix (Domain, General)"
   with Phoenix as a link, Capacity used "0 of 100 raw units (0 %)", Total units 0, Distinct items 0, Lock "Not
   locked", "No stackable stock." and "No unique items.", and the buttons Ledger, Adjust stock and Move stock.
4. [automated: `the storage page › adjusts a line with a required note and re-reads the storage (A01)`] Press
   **Adjust stock**. In the dialog keep "Stackable item (blueprint)", search "oak" under Blueprint and pick **Oak
   log**, type 64 as Change (raw units). **Expected:** Adjust stays off while Note is empty. Type the note "smoke
   2.2.4" and press **Adjust**. **Expected:** "Applied (transaction #…): 64 moved." with "Line 1: … → S1: requested
   64, accepted 64"; Close; the panel lists Oak log 64 (storage weight 1, capacity used 64) and Capacity used "64 of
   100 raw units (64 %)". (A01) The test also checks that a second press after a lost answer sends the same
   idempotency key, so the adjustment applies once (`the storage page › sends the same idempotency key again when the
   first answer was lost (A01)`); a browser cannot drop an answer by hand.
5. [automated: `the storage page › a partial move over capacity accepts what fits and gives the reason per line
   (A02)`] On the Oak log line press **Move**. **Expected:** the dialog's line 1 has From storage S1 and Blueprint Oak
   log filled in. Search "S2" under To storage and pick it, Amount 30, keep Reason Distribution and Mode All or
   nothing, press **Move**. **Expected:** "Applied (transaction #…): 30 moved."; after Close, S1 lists Oak log 34.
6. [automated: `the storage page › a partial move over capacity accepts what fits and gives the reason per line
   (A02)`] Move again from the Oak log line: To storage S2, Amount 40, All or nothing. **Expected:** "Rejected:
   nothing moved and no transaction was written." and under line 1 "Capacity full: the storage is full (capacity in
   raw units × storage weight)" (S2 holds 30 of 50). Set Mode to **Partial** and press Move. **Expected:** "Partially
   applied (transaction #…): 20 moved, the rest refused." and "requested 40, accepted 20, refused 20" with Capacity
   full (the test's mock answers 18 and 22). S1 Oak log 14; S2 "50 of 50 raw units (100 %)". (A02)
7. [partly automated: `dashboard › the blueprint list shows each blueprint's storage weight (DESIGN § 4.4)`, `the
   storage page › shows capacity in raw units × storage weight, the lock, the lines and the unique items (A02, A03)`;
   by hand: setting the weight, because the seeded ItemBlueprint form has no Storage weight field yet (seed follow-up
   on #675)] Set Stone's storage weight to 2 (§ 2.1 step 7, `PUT api/ItemBlueprints/<Stone>`). Dashboard type
   **ItemBlueprint**. **Expected:** a Storage weight column with 1 for Oak log and 2 for Stone. On S1's page adjust +5
   Stone (note "smoke 2.2.7"). **Expected:** the Stone line shows Amount 5, Storage weight 2, Capacity used 10;
   Capacity used "24 of 100 raw units (24 %)" while Total units is 19. (A02)
8. [automated: `the storage page › takes a unique item out by its item instance id (A03)`, `the ledger explorer ›
   shows a unique item's moves by its item instance id (A03)`] On S1's page press **Adjust stock**, choose "Unique
   item (item instance)", type the enchanted sword's item instance id (§ 2.0 item 3), Change +1, note "smoke 2.2.8",
   Adjust. **Expected:** Applied; the **Unique items** table lists "#<id>" with its blueprint and name. Click "#<id>".
   **Expected:** the ledger explorer opens on Moves filtered by that item instance id, with one Admin adjust move
   SYS_ADJUSTMENT → S1 "Item #<id> (…)". Back on S1, press **Take out** on the sword. **Expected:** the dialog has the
   item instance id and Change -1 filled in; with a note, Adjust gives Applied and "No unique items." (A03)
9. [partly automated: `the storage page › a locked storage over its cap says so`, `the storage page › a move into a
   locked storage is refused with the reason Locked`; by hand: setting the lock in the seeded form] Edit S2 (dashboard,
   Edit): on **Capacity and lock** set Locked until to an hour from now and Lock reason "smoke"; save. View S2.
   **Expected:** Lock "Locked until <time>: smoke" and the line "A locked storage refuses moves in and out (result
   Locked) until the lock ends." Press Move stock, line 1 From S2 (filled in), To storage S1, Blueprint Oak log,
   Amount 1, Move. **Expected:** Rejected with "Locked: a storage is locked" under line 1 (the test also checks the
   second line of an all-or-nothing request: "Other line rejected: …"). Clear Locked until in the edit form and move
   again. **Expected:** Applied; S2 "49 of 50", S1 Oak log 15.
10. [automated: `the storage page › a locked storage over its cap says so`] Edit S2: Max units 40; save. **Expected:**
    S2's Capacity used reads "49 of 40 raw units (123 %) (over its cap: removals only)". Set Max units back to 50.
11. [automated: `the ledger explorer › drills down from a line to the moves that made it, with the net next to the line
    (A01)`] On S1's page click the Oak log amount **15**. **Expected:** Admin → Economy → **Stock ledger**
    (`/admin/stock/ledger?view=moves&storageId=<S1>&itemBlueprintId=<Oak log>`) on the Moves view; above the table
    "Oak log in S1: line amount 15" and "Moves in 65 − moves out 50 = 15 (matches the line)"; the column "Amount (±
    this storage)" shows +64 (Admin adjust), −30, −20 (Distribution) and +1; every row links its transaction and both
    storages. (A01)
12. [automated: `the ledger explorer › filters the transactions by reason and keeps the filter in the address`] Press
    **Transactions**, press Clear, pick Reason "Admin adjust" and press **Apply filters**. **Expected:** the address
    ends in `?reason=AdminAdjust`; only the adjustments of steps 4, 7 and 8 are listed, each with "User #<your id>
    (web)", its move count, amount and note. Reload: the filter stays.
13. [automated: `the transaction page › shows the moves with both storages and reverses it with a correction`] Clear
    the filter and open the step 5 transaction (Distribution, amount 30) by its "#" link. **Expected:** the detail page
    has a **Ledger entry** panel: Reason Distribution, Mode All or nothing, your name as actor, a Moves table "S1 → S2,
    Oak log, 30" with both storages as links, Reversed by "Not reversed". Press **Reverse**, type the note "smoke
    undo", press **Write the correction**. **Expected:** Reversed by "Transaction #<new>", no Reverse button any more;
    the new transaction's page shows Reason Correction and "Reverses Transaction #<step 5>"; S1 Oak log 45, S2 19.
14. [automated: `the transaction page › a correction that finds the stock gone is rejected and changes nothing`] Open
    the step 6 transaction (Partial, 20) and press Reverse, Write the correction. **Expected:** "Rejected: nothing moved
    …" with "Not enough stock: not enough stock in the source" (S2 holds 19); Reversed by stays "Not reversed".
15. [partly automated: `the ledger explorer › lists the roll-ups of old production moves with the same filters
    (A22)`; by hand: the dated moves, test database only] After § 2.1 step 13 (three Production moves of 5 oak logs
    into S1, dated 31 days back and rolled up), open the Stock ledger, press **Roll-ups**, type S1's id as Storage id
    and Oak log's as Blueprint id, Apply filters. **Expected:** one row: the day, Production, SYS_PRODUCTION → S1, Oak
    log, Amount 15, Moves 3, when it was rolled up; the line summary adds "+ roll-ups 15" and still matches S1's Oak
    log amount. (A22)
16. [automated: `the ledger explorer › runs the reconciler and the roll-up (#65 health)`] At the bottom of the Stock
    ledger, **Ledger health**: press **Run the reconciler**. **Expected:** "Clean: <n> lines and <m> unique items
    match the ledger." and the time it checked. Press **Roll up old production moves now**. **Expected:** "Roll-up
    done: <x> transactions and <y> moves from before <cutoff> became <z> roll-up rows. Totals are unchanged." (0s on
    a fresh database). Run the reconciler again: still clean. (A01, A22)
17. [automated: `the storage page › staff without knk.economy.admin see the stock but cannot adjust or move it`, `the
    transaction page › staff without knk.economy.admin cannot reverse`, `the ledger explorer › World staff without the
    economy node read the ledger but cannot roll up`, `the ledger explorer › economy staff without an area node open
    it from the admin sidebar`] Log in as **World staff** (`knk.admin.world`, no `knk.economy.admin`). **Expected:**
    S1's page shows the stock with Adjust stock, Move stock and each line's Adjust, Move and Take out off, titled
    "Requires knk.economy.admin"; a transaction's Reverse is off the same way; the Stock ledger lists transactions
    and runs the reconciler, but "Roll up old production moves now" is off. Log in as a member holding only
    `knk.economy.admin`: Admin → Economy lists **Stock ledger** and it opens. (The API refuses the writes on its own,
    § 2.1 step 15.)

## 3. Phase P2: world: rural structures, warehouse, production structure (#91 API, #676 web app, #677 plugin; tier:3)

Built so far: link L6, the API (knk-web-api, migration `AddProductionWorld`; branch `claude/production-p2`, PR into
`next`). The web app forms with region capture and the town picker are link L7 (#676); the managed-region kinds and the
territory lookup the placement rule P-2 asks are link L8 (#677). Until then § 3.1 runs with a REST client (or Swagger)
against the API, and P-2 reports "not checked" because no game server answers the lookup yet. 16 steps in § 3.1: 14
automated in CI and 2 partly (tagged); every step can still be run by hand; manual steps not run. Full manual run about
45 minutes; the untagged parts of the partly tagged steps about 10 minutes. § 3.2 and § 3.3 are the draft steps for L7
and L8.

### 3.0 Preconditions

1. knk-web-api from the branch with migrations `AddStockCore` and `AddProductionWorld` applied
   (`dotnet ef database update`).
2. Game setting `production.enabled` on (web app game settings, or `PUT api/GameSettings` section `production`), except
   in step 7.
3. Callers: a **Staff** token with `knk.admin.world`, `knk.admin.content` and `knk.admin.delete`; an **Admin** token
   (holds `*`) to change a form rule; a **Visitor** token (no staff nodes).
4. Town **Phoenix** with district **Market** (its region drawn in game, note its `wgRegionId`) and street **Main**; town
   **Rivertown** (common preconditions). Note the ids. Item identity (§ 0) deployed: note the id of **Stone**.
5. For the region checks by hand: a game server with knk-plugin connected (P-1 asks the plugin's region HTTP server;
   P-2 needs the P2c build, #677). Without it the rules report "not checked" and never block a save.

### 3.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports), `PlacementRulesTests` (the seeds' rules as imported); by hand: open the forms in the web app]
   As Staff, import the form seeds `Warehouse` and `ProductionStructure` and the display seeds `Warehouse` and
   `ProductionStructure` ("make default"). Open the form configuration `ProductionStructure - Default (seed v1)`.
   **Expected:** a "Placement" step with District, Street, House number and Town (rural); on the Region field two rules,
   P-1 `RegionContainment` (depends on District) and P-2 `InsideTerritory` (depends on Town), both with "Blocking" off.
   (A06, A23, R2)
2. [automated: `StructureSubtypeServicesTests.Warehouse_InADistrict_GetsItsDeliveryStorage_AndPhoenixAsEffectiveTown`]
   `POST api/Warehouses` with `{ "name": "Market warehouse", "description": "", "wgRegionId": "<a region inside
   Market>", "districtId": <Market>, "streetId": <Main>, "houseNumber": 3 }`. **Expected:** 201; `districtId` Market,
   `townId` null, `effectiveTownId` Phoenix, `isRural` false, `acceptsDeliveries` true; `storages` lists one storage
   with purpose `Delivery` and its id is `defaultStorageId`; `GET api/Storages/<that id>` shows kind `Domain` and the
   warehouse as holder. (A06)
3. [automated: `StructureSubtypeServicesTests.ProductionStructure_Rural_GetsItsOutputStorage_AndNoStreet`]
   `POST api/ProductionStructures` with `{ "name": "Quarry", "description": "", "wgRegionId": "<a region outside the
   districts, inside Phoenix territory>", "townId": <Phoenix> }`. **Expected:** 201; `townId` and `effectiveTownId`
   Phoenix, `districtId` and `streetId` null, `houseNumber` 0, `isRural` true; `level` 1, `productionEnabled` true,
   `workersTotal` 2, `warehousePreference` `Nearest`, `roadConnection` `Unmeasured`; one storage with purpose
   `Output`. (A06)
4. [automated: `StructureSubtypeServicesTests.BothOrNeither_DistrictAndTown_IsRefused`,
   `StructureSubtypeServicesTests.Rural_WithAStreet_AndDistrict_WithoutStreetOrHouseNumber_AreRefused`,
   `RuralStructureTests.StructureService_RefusesBothAndNeither_AndAnUnknownTown`,
   `ProductionWorldMySqlTests.CheckConstraint_RefusesBothAndNeither_AndAcceptsEach`] Send step 3's body with
   `"districtId": <Market>, "streetId": <Main>, "houseNumber": 1` added (both a district and a town), then with neither,
   then step 3's body with `"streetId": <Main>`; also `POST api/Structures` with both. **Expected:** each answers 400
   ("set exactly one of the two", "a rural structure has no street"); nothing is saved. The database refuses a row with
   both or neither too (check constraint `CK_structures_DistrictXorTown`). (A06)
5. [partly automated: `PlacementRulesTests.P2_RuralOutsideItsTownsTerritory_WarnsByDefault_AndSaves`,
   `PlacementRulesTests.BlockingRule_WhenTheGameServerIsOffline_DoesNotBlock_AndSaysItWasNotChecked`; by hand: with the
   P2c plugin connected] Create a rural production structure **Outpost** for Phoenix whose region lies outside Phoenix
   territory (step 3's body with another name and region). **Expected:** 201 (saved) with `placementWarnings` holding the
   P-2 message ("not inside its town's territory"). Without a game server answering the lookup the warning says "not
   checked" instead. (A06, R2)
6. [automated: `PlacementRulesTests.P2_SetToBlocking_RefusesTheSave`,
   `PlacementRulesTests.P1_WarehouseRegionOutsideItsDistrict_WarnsByDefault_AndBlocksWhenSet`,
   `PlacementRulesTests.P2_InsideTheTerritory_SavesWithoutWarnings`] As Admin, switch "Blocking" on for the P-2 rule of
   the `ProductionStructure` form (form configuration page, or `PUT api/FieldValidationRules/<id>` with
   `"isBlocking": true`) and send step 5 again with another name. **Expected:** 400 with the rule's message; no
   structure and no storage is created. Do the same for P-1 on the `Warehouse` form with a warehouse whose region
   sticks out of Market: a warning while not blocking, 400 once blocking. Switch both back to warnings afterwards. A
   blocking rule that can't be checked (game server offline) still saves, with "not checked". (A06, R2)
7. [automated: `PlacementRulesTests.ProductionOff_TheTerritoryRulePasses_WithoutALookup`,
   `InsideTerritoryValidatorTests.ProductionOff_Passes_WithoutAskingTheGameServer`] Turn the game setting
   `production.enabled` off and repeat step 6 with P-2 blocking. **Expected:** saved without a P-2 warning (the rule is
   skipped, no lookup is sent); warehouses and production structures can still be created, edited and deleted. Turn it
   back on. (A21)
8. [automated: `RuralStructureTests.ContestedLand_TheRuralStructureKeepsItsTown_AndIsFlagged`] Make the quarry's land
   contested: send the territory report of § 1.2 step 5 (`PUT api/Territory/report` with the plugin key, an overlap
   Phoenix/Rivertown) with `"structures": [ { "structureId": <Quarry>, "flag": "Contested", "holderA": { "kind":
   "Town", "id": <Phoenix> }, "holderB": { "kind": "Town", "id": <Rivertown> } } ]`. **Expected:** `GET
   api/ProductionStructures/<Quarry>` keeps `townId` Phoenix, shows `territoryFlag` `Contested` and the
   `territoryConflictId`, `productionEnabled` stays true, and `warnings` says its land is contested; `GET
   api/Territory/structures/<Quarry>` shows town Phoenix. (A07, R3)
9. [automated: `StructureSubtypeServicesTests.RoadConnection_IsSetByTheGameServer_AndUnconnectedRuralShowsAWarning`]
   `PUT api/ProductionStructures/<Quarry>/road-connection` with `{ "roadConnection": "Unconnected" }`. **Expected:** 200;
   `roadConnection` `Unconnected` with `roadConnectionMeasuredAt` set, and `warnings` says it is not connected to its
   town's road network. `{ "roadConnection": "Maybe" }` answers 400. (D5)
10. [automated: `StructureSubtypeServicesTests.Update_MovesAStructureFromItsDistrictToRural_AndKeepsItsStorages`]
    Create a production structure **Mill** in Market (district, street, house number 2), then `PUT
    api/ProductionStructures/<Mill>` with `"townId": <Rivertown>`, no district, street or house number, and `"level":
    4`. **Expected:** 204; it is now rural in Rivertown (`effectiveTownId` Rivertown, no street), level 4, with the same
    output storage.
11. [automated: `StructureSubtypeServicesTests.PreferredWarehouse_MustExist_AndPreferredNeedsOne`,
    `StructureSubtypeServicesTests.DeletingAWarehouse_ResetsProducersThatPreferIt_AndRemovesItsEmptyStorage`,
    `StructureSubtypeServicesTests.Level_OutsideOneToTen_IsRefused`] Set the quarry's `"warehousePreference":
    "Preferred"` without a `preferredWarehouseId`: 400; with the Market warehouse's id: saved. `"level": 11`: 400. Create
    a second, empty warehouse, prefer it from the quarry, then `DELETE api/Warehouses/<it>`. **Expected:** 204; the
    quarry falls back to `Nearest` with no preferred warehouse, and the warehouse's delivery storage is gone.
12. [automated: `StructureSubtypeServicesTests.Delete_WhileItsStorageHoldsStock_IsRefused_AndKeepsEverything`] Put 5
    Stone into the quarry's output storage (`POST api/StockTransactions/adjust` with `{ "storageId": <its output storage>,
    "itemBlueprintId": <Stone>, "delta": 5, "note": "smoke 3.1.12" }`), then `DELETE api/ProductionStructures/<Quarry>`.
    **Expected:** 409 (its storage holds stock or has ledger history); the quarry and its storage are unchanged.
13. [automated: `StructureSubtypeServicesTests.Search_FiltersByTownRuralAndFlag_AndListsTheEffectiveTown`,
    `RuralStructureTests.StructureService_Search_ListsTheEffectiveTown_AndFiltersRuralByTown`] `POST
    api/Warehouses/search` and `POST api/ProductionStructures/search` with `{ "filters": { "townId": "<Phoenix>" } }`,
    then `{ "filters": { "isRural": "true" } }` and `{ "filters": { "territoryFlag": "Contested" } }`; `POST
    api/Structures/search` with `{ "filters": { "isRural": "true" } }`. **Expected:** rows of Phoenix in a district
    and rural; the rural filter lists only structures without a district, each with `townId` and `townName` of its own
    town; the flag filter lists the quarry. (The game server's territory report reads `townId` from the structure search,
    so rural structures are checked too.)
14. [automated: `RuralStructureTests.RegionDecisions_ForARuralStructure_HaveNoParent`] `GET
    api/Domains/by-region/<the quarry's region>?world=world` and the same for the Market warehouse. **Expected:** the
    quarry's `parentDomainDecisions` is empty (no parent region: no town flags inherited, PvP stays allowed); the
    warehouse lists Market and Phoenix.
15. [automated: `ReadAccessRulesTests.EveryReadEndpoint_HasItsPinnedCategory`,
    `DashboardChangeAccessRulesTests.TheChangeRule_SitsOnExactlyThePinnedCreateAndUpdateActions`,
    `DeleteAccessRulesTests.EveryDeletableRegistryType_HasAPinnedPrimaryDelete`] As Visitor, `POST api/Warehouses` (step
    2's body) and `PUT api/ProductionStructures/<Quarry>/road-connection`. **Expected:** 403. As Staff without
    `knk.admin.delete`, `DELETE api/Warehouses/<id>` answers 403; reads (`GET`, `search`) need the World area node.
16. [automated: `AddProductionWorldTests.Up_OnlyWidensTheStructureColumns_AndAddsANullableTownId`,
    `ProductionWorldMySqlTests.DeletingAStreetOrTownAStructureUses_IsRefused_AndTheStructureKeepsIt`,
    `DeleteConstraintExceptionFilterTests.DeletingAStreetAStructureStillUses_Answers409WithTheReason`] After the
    migration, open an existing structure: its district, street and house number are unchanged. `DELETE api/Streets/<Main>`
    while the Market warehouse uses it. **Expected:** 409 "still used by 1 structure"; the warehouse keeps its street.

### 3.2 Steps (web app #676, draft)

1. As Staff, create a warehouse inside a Phoenix district with the web app form and region capture. **Expected:** saved
   with `DistrictId` set and `TownId` empty; effective town Phoenix. (A06)
2. Create a rural quarry outside the districts but inside Phoenix territory, picking Phoenix as its town. **Expected:**
   saved with `TownId` set and `DistrictId` empty; the rule builder offers `InsideTerritory`; the dashboard shows flagged
   structures. (A06)

### 3.3 Steps (plugin #677, draft)

1. In game, check the quarry's WorldGuard region. **Expected:** managed kind `RESOURCE_PRODUCTION`, no parent, its kind's
   floor priority; PvP allowed inside. The warehouse's region is kind `STRUCTURE` under Market. (P2c)
2. With the plugin connected, repeat § 3.1 step 5. **Expected:** the P-2 warning comes from the territory lookup
   (`GET /api/territory/contains-region/{regionId}?holderKind=Town&holderId=<Phoenix>`) instead of "not checked".

## 4. Phase P3: production engine (#86 API, #678 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 4.0 Preconditions

1. The quarry from § 3 with yield source `Configured`: 60 cobblestone per hour at level 1, output storage capacity 100.
   Two workers.

### 4.1 Steps

1. Wait one sweep interval (or run the sweep from the staff tools). **Expected:** cobblestone accrues at the configured
   rate; the cycle trace lists the base rate and each modifier (additions first, then multiplications). (A08)
2. Raise the quarry to level 2. **Expected:** the trace shows the level multiplier; the area cap grows. (A09)
3. Try to set level 11. **Expected:** refused; levels are 1-10. (A09)
4. Let the output storage fill to 100. **Expected:** the line stalls without accruing; the dashboard shows "full". (A08)
5. Empty the storage. **Expected:** production resumes from that moment, with no catch-up for the stalled time. (A08)
6. Turn `Production:Enabled` off and wait one interval. **Expected:** nothing accrues. (A21)

## 5. Phase P4: yield areas and surveys (#138 API, #679 plugin, #680 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 5.0 Preconditions

1. A logger with a captured radius area over a forest, yield source `Hybrid`; a second logger whose area overlaps the
   first one's; the quarry from § 4 left on `Configured`.

### 5.1 Steps

1. Create the logger. **Expected:** a survey runs on creation; the survey viewer lists trees by species and size; the
   production lines come from the survey. (A10)
2. As Staff, run `/knk production survey <logger>` and the web app "survey now" button. **Expected:** a new survey row
   each time. (A10)
3. Check the quarry (`Configured`). **Expected:** no survey has ever run for it. (A10, G5)
4. Leave the server running over the daily survey time with the logger's chunks loaded. **Expected:** one scheduled
   survey that day. (A10)
5. Cut down a large part of the forest. **Expected:** a resurvey after the notable-change threshold; lower rates. (A10)
6. Check a tree inside both loggers' areas. **Expected:** each logger counts half of it. (A11)
7. Try to capture an area larger than the level 1 maximum for the kind. **Expected:** refused with the maximum. (A11)
8. Add a Hybrid pin (always produce apples at 5 per hour). **Expected:** the line exists after the next materialization
   whatever the survey says. (A10)
9. Watch the tick metrics during a survey. **Expected:** no main-thread spike from block reads.

## 6. Phase P5: transport core, simulated (#79 API, #681 plugin, #682 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 6.0 Preconditions

1. The quarry connected by road to the Phoenix warehouse; lanes measured with `/knk logistics lanes measure`. A second
   producer with no road.

### 6.1 Steps

1. As Staff, create a manual order of 40 cobblestone from the quarry to the warehouse. **Expected:** the order goes
   through its lifecycle; the goods sit in transit storage while carried; the ledger balances at every step. (A12)
2. While one of the two workers carries the order, read the quarry's trace. **Expected:** output at 50%. (A12)
3. Create two orders at once. **Expected:** both workers away; output 0% until one returns. (A12)
4. Compare the trip time with the measured route length ÷ walking speed. **Expected:** they match. (A12, G14)
5. Fill the producer without a road. **Expected:** it stops when full; no automatic transport; warnings for the missing
   road and the full storage. (A13)
6. Cancel an order midway. **Expected:** goods return to the sender; ledger balanced. (A12)

## 7. Phase P6: terminals, displays, menus, commands (#683 API, #74 plugin; tier:2)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 7.1 Steps

1. As Staff, bind a chest in the warehouse as a terminal and another as a display. Open the terminal as Member.
   **Expected:** a paged menu of the storage; taking and putting items are ledger moves; the chest stays empty. Open
   the display: a read-only sample with the fill level. (A14)
2. As Member standing in Phoenix, open the main menu and click "Structures". **Expected:** the overview lists
   structures with search and filters; the town filter is set to Phoenix. Clear it: all structures. In the wilderness
   the filter starts empty. (A24)
3. Click the quarry in the overview, and right-click a quarry worker NPC. **Expected:** both open the structure menu
   with exact rates, storage contents, workers and warnings, and a transport orders entry. (A25, A26)
4. As Visitor, open the same structure menu. **Expected:** only name, kind, town, level, products and status; no
   orders entry. (A25)
5. As Member, look for action buttons. **Expected:** none. As Staff: survey now, dry run, cancel or retry an order,
   show the area outline; each works. (A26)
6. On a fresh database, open all three menus. **Expected:** they open from the seeded menu content. (A27)

## 8. Phase P7: item delivery, reward inbox, deposit/withdraw (#60 API, #684 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 8.1 Steps

1. As Admin, grant a kit to Member while Member is offline. **Expected:** at login the kit is in `/inbox`, not on the
   ground. (A15)
2. Grant a lootbox reward to Member with a full inventory. **Expected:** it goes to the inbox with a message. (A15)
3. Claim from the inbox with room for half the items. **Expected:** half claimed, the rest stays. (A15)
4. Fill the inbox to the hard cap, then grant one more item. **Expected:** the overflow is logged as `InboxOverflow` to
   `SYS_LOSS`, and Member gets a loss notification and a near-cap warning before that. (A15)
5. As a premium-tier player, check the cap. **Expected:** higher than for Member. (A15)
6. Move the clock 30 days on a test database. **Expected:** reminders were sent; expired items are moved out as
   `InboxExpired`. (A15)
7. Turn `production.enabled` off and grant a kit. **Expected:** today's delivery path (#261) still works.

## 9. Phase P8: player harvesting and block regeneration (#685 API, #134 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 9.1 Steps

1. As Member, mine iron ore inside the quarry's yield area. **Expected:** the ore drops; the block becomes the neutral
   placeholder (stone); the harvest is reported and the pool drops. (A16)
2. Wait for the regeneration time. **Expected:** the ore comes back. (A16)
3. Cut a tree inside the logger's area. **Expected:** a sapling placeholder, then the exact tree restored. (A16)
4. Harvest until the pool reaches its floor (0.5). **Expected:** further breaks are refused with a message. (A16)
5. Check the ledger. **Expected:** `PlayerHarvest` moves with the worker's share to Output; the town's net output is
   positive. (A16)
6. As Visitor, break blocks where the rules deny it. **Expected:** refused, nothing reported.

## 10. Phase P9: town logistics (#127 API, #686 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 10.1 Steps

1. As Staff, apply the town policy template for Phoenix's size. **Expected:** rules shown in the editor. (A17)
2. Run a planner dry run. **Expected:** a plan with an explanation per decision; nothing moves. (A17)
3. Wait for the 10-minute planner run. **Expected:** warehouses reserve stock; a consumer collects with its own worker
   (worker away, as in § 6). (A17)
4. Try to collect the same reservation twice. **Expected:** refused. (A17)
5. Make a good scarce. **Expected:** higher-priority consumers are served first. (A17)

## 11. Phase P10: shops (#248 API, #687 plugin menus, #688 web app; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 11.0 Preconditions

1. A Phoenix shop with a static catalogue; the developer's V1 shop menu templates imported; Phoenix's town account.

### 11.1 Steps

1. As Member, open the shop menu (`/knk shop <id>` until P11). **Expected:** info header and paged catalogue; prices at
   the midpoint base price with the shop's modifiers. (A18)
2. Buy an item. **Expected:** a confirmation first; then coins and stock move together; the coins go to Phoenix's town
   account. (A18)
3. Buy with too few coins. **Expected:** refused; nothing moves. (A18)
4. Sell items in the sell menu. **Expected:** the buy-back price per item and the total; confirmation; coins paid. (A18)
5. Open the web app trade stats after an hour. **Expected:** hourly stats per shop and blueprint match the ledger.
   (A18)

## 12. Phase P11: shopkeepers (#249; tier:2)

*Draft from the design (2026-11-16); the link updates it to what was built and tags the automated steps.*

### 12.1 Steps

1. Walk towards the shop. **Expected:** the shopkeeper spawns within 48 blocks, looks at you and greets you (with a
   cooldown). Right-click: the shop menu for that shop. (A19)
2. Walk more than 64 blocks away and wait 10 s. **Expected:** the shopkeeper despawns. (A19)
3. Restart the server, then kill the server process and start it. **Expected:** exactly one shopkeeper each time. (A19)
4. Try to hurt the shopkeeper. **Expected:** invulnerable. (R5)

## 13. Phase P12: display stalls (#250; tier:2)

*Draft from the design (2026-11-16); the link updates it to what was built and tags the automated steps.*

### 13.1 Steps

1. Stand at a display stall. **Expected:** items shown as item display entities. (A20)
2. Right-click an item. **Expected:** the shop item information menu, no purchase. (A20)
3. Shift-right-click. **Expected:** quick buy with a confirmation. (A20)
4. Sell out an item. **Expected:** greyed out. (A20)
5. Reload the chunk. **Expected:** no duplicate display entities. (A20)
