# Production, storage and transport — smoke test

**Status:** Draft from the design (2026-11-16); no steps run. § 0 (item identity, #141): 7 of 14 steps automated
in CI and 4 partly (tagged); every step can still be run by hand; manual steps not run. § 1.1-1.2 (territory API,
#326): 19 of 19 steps automated in CI (tagged; step 1.2.6 needs a connected server to check by hand); every step can
still be run by hand; not run. § 1.3 (territory plugin, #689): 7 of 14 steps automated and 7 partly (tagged; step 14
waits for #802); not run. § 1.4 (territory web app, #690): 13 of 15 steps automated in CI and 2 partly (tagged);
every step can still be run by hand; not run. Other sections not yet automated (the links tag them).
**Last updated:** 2026-11-19 (§ 1.4 territory web app, link L3, #690); 2026-11-19 (§ 1.3 territory plugin, link L2, #689); 2026-11-19 (§ 1 territory API, link L1, #326); 2026-11-19 (§ 0 item identity, link L0, #141); 2026-11-16 (draft from the design, territory and phases P1-P12)
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

1. knk-web-api from the branch with migration `AddTerritory` applied (`dotnet ef database update`).
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

Built by link L2 (knk-plugin branch `claude/production-t-b`). Extra preconditions:

1. The plugin build from that branch on a test server with WorldGuard, connected to the API of 1.0 (realtime on:
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

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 2.0 Preconditions

1. Item identity (#141) deployed; the "Uncurated" category holds the generated vanilla blueprints. (A04)
2. Two domain storages for Phoenix, **S1** (capacity 100) and **S2** (capacity 50).

### 2.1 Steps

1. As Staff, open the create form for a storage in the web app on a fresh database. **Expected:** the form comes from
   the seed and saves. (A23)
2. Adjust S1 by +64 oak logs with the adjust dialog. **Expected:** S1 shows 64; the ledger explorer shows one
   `AdminAdjust` move with the staff account. (A01)
3. Move 30 oak logs S1 → S2. **Expected:** S1 34, S2 30; one ledger transaction with a debit and a credit. (A01)
4. Repeat the same move request with the same idempotency key (dev tool or retry). **Expected:** applied once only.
   (A01)
5. Move 40 oak logs S1 → S2 (S2 has room for 20). **Expected:** refused in strict mode; in `Partial` mode 20 move and
   20 are reported as rejected. (A02)
6. Deposit an enchanted sword into S1, move it to S2, withdraw it. **Expected:** the same unit (same id, same
   enchantments) at every step. (A03)
7. Run the reconciler. **Expected:** no differences. (A01)
8. With the clock moved 31 days on a test database, run the roll-up. **Expected:** `Production` moves older than 30
   days are summed per line per day; storage totals are unchanged; other move kinds keep every row. (A22)
9. As Visitor, call a stock move endpoint. **Expected:** refused (403).

## 3. Phase P2: world: rural structures, warehouse, production structure (#91 API, #676 web app, #677 plugin; tier:3)

*Draft from the design (2026-11-16); the links update it to what was built and tag the automated steps.*

### 3.0 Preconditions

1. Territory (§ 1) deployed. Placement rules P-1 to P-3 seeded as warnings.

### 3.1 Steps

1. As Staff, create a warehouse inside a Phoenix district with the web app form and region capture. **Expected:** saved
   with `DistrictId` set and `TownId` empty; effective town Phoenix. (A06)
2. Create a rural quarry outside the districts but inside Phoenix territory, picking Phoenix as its town. **Expected:**
   saved with `TownId` set and `DistrictId` empty. (A06)
3. Try to save a structure with both a district and a town. **Expected:** refused with a validation message. (A06)
4. Create a rural structure outside any Phoenix territory. **Expected:** a warning (P-1), saved. (A06)
5. As Admin, set that rule to blocking and try again. **Expected:** refused with the rule's message. (A06)
6. Make the quarry's land contested (§ 1 step 5). **Expected:** the quarry keeps Phoenix as its town, is flagged on its
   page and listed on the conflict. (A07)
7. In game, check the quarry's WorldGuard region. **Expected:** managed kind `RESOURCE_PRODUCTION`, no parent; PvP
   allowed inside. (P2c)

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
