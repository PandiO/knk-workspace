# Production, storage and transport — smoke test

**Status:** Draft from the design (2026-11-16); no steps run. § 0 (item identity, #141): 7 of 14 steps automated
in CI and 4 partly (tagged); every step can still be run by hand; manual steps not run. § 1.1-1.2 (territory API,
#326): 19 of 19 steps automated in CI (tagged; step 1.2.6 needs a connected server to check by hand); every step can
still be run by hand; not run. § 1.3 (territory plugin, #689): 7 of 14 steps automated and 7 partly (tagged; step 14
waits for #802); not run. § 1.4 (territory web app, #690): 13 of 15 steps automated in CI and 2 partly (tagged);
every step can still be run by hand; not run. § 2.1 (stock core API, #97): 15 of 17 steps automated in CI and 2 partly
(tagged); every step can still be run by hand; not run. § 2.2 (stock web app, #675): 14 of 17 steps automated in CI
and 3 partly (tagged); every step can still be run by hand; not run. § 3.1 (world API, #91): 14 of 16 steps
automated in CI and 2 partly (tagged); every step can still be run by hand; not run. § 3.3 (world plugin, #677): 6 of
11 steps automated (one through a plugin scenario on a real Paper server) and 5 partly (tagged); not run. § 3.2 (world
web app, #676): 8 of 12 steps automated in CI and 4 partly (tagged); every step can still be run by hand; not run. § 4.1 (production
engine API, #86): 16 of 18 steps automated in CI and 2 partly (tagged); every step can still be run by hand; not
run. § 4.2 (production engine web app, #678): 13 of 16 steps automated in CI and 3 partly (tagged); every step can
still be run by hand; not run. § 5.1 (yield areas API, #138): 17 of 18 steps automated in CI and 1 partly (tagged);
every step can still be run by hand; not run. § 5.2 (surveys plugin, #679): 7 of 15 steps automated (one through a plugin
scenario on a real Paper server), 7 partly and 1 manual (tagged); not run. § 5.3 (yield areas web app, #680): 9 of 12 steps automated in CI, 2
partly (tagged) and 1 by hand; every step can still be run by hand; not run. § 6.1 (transport API, #79): 18 of 20 steps automated in CI
and 2 partly (tagged); every step can still be run by hand; not run. § 6.2 (transport lanes plugin, #681): 3 of 14
steps automated, 10 partly and 1 manual (tagged); not run. § 6.3 (transport web app, #682): 10 of 16 steps
automated in CI, 5 partly (tagged) and 1 by hand; every step can still be run by hand; not run. § 7.1 (terminals and menus API, #683): 15 of 20 steps automated in CI, 4 partly and 1 by hand (tagged); every step can still be run by hand; not run. § 7.2 (terminals, displays and menus plugin, #74): 7 of 20 steps automated (one through a plugin scenario on a real Paper server), 11 partly and 2 by hand (tagged); not run. § 8.1 (delivery and inbox API, #60): 16 of 20 steps automated in CI, 3 partly and 1 by hand (tagged); every step can still be run by hand; not run. § 8.2 (reward inbox plugin, #684): 7 of 17 steps automated (two also through plugin scenarios on a real Paper server) and 10 partly (tagged); every step can still be run by hand; not run. § 9.1 (harvesting API, #685): 18 of 21 steps automated in CI and 3 partly (tagged); every step can still be run by hand; not run. § 9.2 (harvesting plugin, #134): 10 of 22 steps automated (four through plugin scenarios on a real Paper server), 10 partly and 2 by hand (tagged); not run. § 10.1 (town logistics API, #127): 21 of 24 steps automated in CI and 3 partly (tagged); every step can still be run by hand; not run. § 10.2 (town logistics web app, #686): 18 of 22 steps automated in CI, 3 partly and 1 by hand (tagged); every step can still be run by hand; not run. § 11.1 (shops API, #248): 25 of 28 steps automated in CI and 3 partly (tagged); every step can still be run by hand; not run. § 11.2 (shop menus plugin, #687): 5 of 16 steps automated (three of them also through a plugin scenario on a real Paper server), 10 partly and 1 by hand (tagged); every step can still be run by hand; not run. § 11.3 (shops web app, #688): 11 of 15 steps automated in CI and 4 partly (tagged); every step can still be run by hand; not run. Other sections not yet automated (the links tag them).
**Last updated:** 2026-11-21 (§ 11.2 shop menus plugin, link L26, #687; § 11 intro); 2026-11-21 (§ 11 and § 11.3 intros: L25 and L27 in `next`; § 11.1 step 22: the reversal is 400 `NotReversible`, partly automated; § 10.3 intro: L25b in `next`; admin guide link, docs #939); 2026-11-21 (§ 11.3 shops web app, link L27, #688); 2026-11-21 (§ 11 shops API, link L25, #248; § 11.2 and § 11.3 drafts for L26 and L27); 2026-11-21 (§ 10.2 town logistics web app, link L24, #686); 2026-11-21 (§ 9 and § 9.2 intros and preconditions: L21 and L22 in `next`, rules through the API until #913; § 4 step 14 partly automated by `player-harvest-tree`, docs #922); 2026-11-21 (§ 10 town logistics API, link L23, #127; § 10.2 draft for L24); 2026-11-21 (§ 9.2 harvesting plugin, link L22, #134); 2026-11-21 (§ 8 and § 8.2 intros: L19 and L20 merged into `next`, links to the architecture page and admin guide, docs #915); 2026-11-21 (§ 9 harvesting API, link L21, #685, with #900; § 9.2 draft for L22); 2026-11-21 (§ 8.2 reward inbox plugin, link L20, #684); 2026-11-20 (§ 8 delivery and inbox API, link L19, #60, with #883 and #890; § 8.2 draft for L20); 2026-11-20 (§ 7.2 terminals, displays and menus plugin, link L18, #74); 2026-11-20 (§ 7 terminals and menus API, link L17, #683; § 7.2 draft for L18); 2026-11-20 (§ 6.2 transport lanes plugin, link L15, #681); 2026-11-20 (§ 6.3 transport web app, link L16, #682); 2026-11-20 (§ 6 transport API, link L14, #79; § 6.2 and § 6.3 drafts for L15 and L16); 2026-11-20 (§ 5.2 surveys plugin, link L12, #679); 2026-11-20 (§ 5.3 yield areas web app, link L13, #680); 2026-11-19 (§ 5 yield areas API, link L11, #138; § 5.1 step 18: #831); 2026-11-19 (§ 4.2 production engine web app, link L10, #678); 2026-11-19 (§ 4.1 production engine API, link L9, #86); 2026-11-19 (§ 3 intro, § 3.0, § 3.2 and § 3.3 intros: builds from `next`; § 3.3 precondition 4: `/knk regions repair` needs `knk.admin.regions`, `/knk territory rebuild` `knk.admin.world.territory`; docs #830); 2026-11-19 (§ 3.2 world web app, link L7, #676); 2026-11-19 (§ 3.3 world plugin, link L8, #677); 2026-11-19 (§ 3.1 world API, link L6, #91); 2026-11-19 (§ 2.2 stock web app, link L5, #675); 2026-11-19 (§ 2 stock core API, link L4, #97); 2026-11-19 (§ 1.0 and § 1.3 preconditions: builds from `next` instead of the link branches; guides: [territory admin guide](admin/territory-admin-guide.md), docs #806); 2026-11-19 (§ 1.4 territory web app, link L3, #690); 2026-11-19 (§ 1.3 territory plugin, link L2, #689); 2026-11-19 (§ 1 territory API, link L1, #326); 2026-11-19 (§ 0 item identity, link L0, #141); 2026-11-16 (draft from the design, territory and phases P1-P12)
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

All three links are merged into `next` (2026-11-19): L6, the API (knk-web-api `next` `fcfced27`, migration
`AddProductionWorld`, § 3.1); L7, the web app forms with region capture and the town picker, the structure pages and
the flagged-structure filter (#676, knk-web-app `next` `18385344`, § 3.2); L8, the managed-region kinds and the
territory lookup the placement rule P-2 asks (#677, knk-plugin `next` `8ebb30be`, § 3.3). Use builds from `next`. How
staff use it: [warehouses and production structures admin guide](admin/production-world-admin-guide.md). § 3.1 runs
with a REST client (or Swagger) against the API; P-2 reports "not checked" until a game server with the L8 build and
`production.enabled` answers the lookup. 16 steps in § 3.1: 14
automated in CI and 2 partly (tagged); every step can still be run by hand; manual steps not run. Full manual run about
45 minutes; the untagged parts of the partly tagged steps about 10 minutes. § 3.2 is L7's, the web app (12 steps, 8
automated, 4 partly); § 3.3 is L8's (11 steps, 6 automated, 5 partly).

### 3.0 Preconditions

1. knk-web-api from `next` with migrations `AddStockCore` and `AddProductionWorld` applied
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

### 3.2 Steps (web app #676)

Built in link L7 (knk-web-app, merged into `next` `18385344`). The tags name tests in knk-web-app
`e2e/production-world.spec.ts` (Playwright, mocked API; the mocks use the same data, with other numbers where noted),
`e2e/form-builder-draft-rules.spec.ts` and the Jest tests next to the code. Extra preconditions: § 3.0, and § 3.1
step 1 (the `Warehouse` and `ProductionStructure` form and display seeds imported, "make default"); for the region
capture of steps 1 and 4 a game server with knk-plugin connected, and for a real P-2 answer in steps 4 and 5 the P2c
build (§ 3.3). Log in to the web app as **Staff** (holds `knk.admin.world`, `knk.admin.content` and
`knk.economy.admin`) unless a step says otherwise. 12 steps: 8 automated, 4 partly (tagged); every step can still be
run by hand; not run. Full manual run about 40 minutes; the untagged parts about 15 minutes.

1. [partly automated: `the forms › saves a warehouse in a district with its region drawn in game (A06, A23)`; by
   hand: drawing the region in game with a real client] Open the dashboard, type **Warehouse**, press Create (the form
   comes from the `Warehouse` seed). Step **General information**: Name "Market warehouse", a description; Next. Step
   **Placement**: District "Market" and Street "Main" (picked from the lists), House number 3, Town (rural) left empty;
   Next. Step **Region and access**: press **Send to Minecraft** on Region, claim the task in game (`/knk task-claim
   <code>` if it isn't offered to you), select an area inside Market with WorldEdit and confirm. **Expected:** the
   Region field fills with `tempregion_worldtask_<n>` and the result names the world. Finish the remaining steps and
   press Submit. **Expected:** "Warehouse created." and back on the dashboard; the warehouse is saved with Market as its
   district and no town, its region is renamed `domain_<id>`, and its world comes from the region's world task (no
   question about the world). (A06, A23)
2. [automated: `dashboard › lists the warehouses with their town, placement, deliveries and priority`] On the dashboard
   type **Warehouse**. **Expected:** columns Town, Placement, District, Accepts deliveries, Priority, Territory flag and
   World; the Market warehouse shows Phoenix, District, Market, Yes, 0 (the seed's priority; the test uses 10) and "-"
   as Territory flag.
3. [automated: `the detail pages › a warehouse in a district: its address, town, deliveries and delivery storage`] View
   the Market warehouse. **Expected:** below the details a **Placement** panel: Placement "In district Market, Main 3"
   with Market as a link, Town "Phoenix (through its district)", the region, Deliveries "Accepts deliveries, priority
   0" and Delivery storage "Market warehouse - deliveries" linked to its storage page. Then the **Territory and
   loyalty** panel ("Inside its town's territory"), a **Storages** panel listing "Market warehouse - deliveries"
   (Purpose Delivery, Total units 0) and a **Stock: Market warehouse - deliveries** panel ("No stackable stock.").
4. [partly automated: `the forms › saves a rural production structure with only its town and shows the placement
   warning (A06, R2)`; by hand: the region in game and the territory lookup of a real game server] Create a
   **ProductionStructure** "Quarry" with its form: on **Placement** leave District, Street and House number empty and
   pick **Phoenix** under Town (rural); on **Region and access** capture a region outside the districts but inside
   Phoenix territory (as in step 1); on **Production** keep Level 1; Submit. **Expected:** "ProductionStructure
   created." with no placement warning (with the P2c plugin connected and `production.enabled` on); the save sends the
   town only (no district, no street), and the world comes from the region (or from Phoenix, the rural structure's
   parent). (A06)
5. [partly automated: `the forms › saves a rural production structure with only its town and shows the placement
   warning (A06, R2)`; by hand: the P-2 answer of a real game server] Create a production structure "Outpost" the same
   way, with Phoenix as its town but its region outside Phoenix territory. **Expected:** it saves ("ProductionStructure
   created.") and a warning stays on screen until closed: "Saved with a placement warning: P-2: the production
   structure's region is not inside its town's territory (or part of it is contested)." Without a game server answering
   the lookup the warning says the territory could not be checked instead. (A06, R2)
6. [automated: `the forms › a refused save shows the API's reason: both a district and a town (A06)`] Create a
   production structure "Both" with District "Market" **and** Town (rural) "Phoenix", a region typed by hand, and
   Submit. **Expected:** "Submit failed": "The form could not be submitted. A structure is either in a district
   (districtId) or rural (townId): set exactly one of the two." Nothing is saved; close the message, clear Town and pick
   a street and house number, or clear the district, and Submit again. (A06)
7. [automated: `dashboard › lists the production structures: a rural one with its town and road connection, one in a
   district (A06, D5)`] After § 3.1 steps 8 and 9 (the Quarry contested and not connected), on the dashboard type
   **ProductionStructure**. **Expected:** columns Town, Placement, District, Level, Production, Road connection,
   Territory flag and World; the Quarry shows Phoenix, Rural, no district, level 1, On, **Unconnected** and "In a
   contested zone"; a production structure in Market (the Mill of § 3.1 step 10 before it moved) shows District,
   Market and Road connection "In a district". (#65: unconnected producers)
8. [automated: `the detail pages › a rural production structure: its town, the contested and road warnings, the flag
   and its output storage (A06, A07)`] View the Quarry. **Expected:** the **Placement** panel starts with **Warnings**:
   "Not connected to its town's road network: automatic transport is held." and "Its land is contested: it keeps its
   town and keeps producing."; Placement "Rural, in its town's territory (no district or street)", Town "Phoenix" as a
   link, Road connection "Not connected to its town's roads (measured …)", Production "On, level 1", Workers present "2
   of 2" (the test uses 1 of 2) and Delivers to (the preferred warehouse as a link after § 3.1 step 11, else "The nearest
   warehouse of its town that accepts deliveries"). The **Territory and loyalty** panel shows "In a contested zone"
   with the conflict as a link and Phoenix as its own town. The **Storages** panel lists "Quarry - output" (Purpose
   Output) linked to its storage page, and the **Stock: Quarry - output** panel shows the 5 Stone of § 3.1 step 12 with
   Adjust stock and Move stock on. (A06, A07, R3)
9. [automated: `the detail pages › a production structure in a district has no warnings and uses its town's roads`]
   As **World staff** (holds `knk.admin.world`, not `knk.economy.admin`), view a production structure in Market (the
   Mill before it moved, or a new one with District Market, Street Main, House number 2). **Expected:** "No
   warnings.", Placement "In district Market, Main 2", Town "Phoenix (through its district)", Road connection "In a
   district: uses its town's roads", the territory panel "Inside its town's territory", and in its stock panel Adjust
   stock and Move stock are off ("Requires knk.economy.admin").
10. [automated: `dashboard › the structure list shows the flagged structures through the Territory flag filter (A07)`;
    Jest `PagedEntityTable.categoryFilter.test.tsx` (the filter on all three types)] On the dashboard type
    **Structure**. **Expected:** the columns Placement and Territory flag after World, and a **Territory flag
    filter** next to the search box. Choose "Flagged: in a contested zone". **Expected:** only the Quarry is listed
    (with "In a contested zone"). Choose "Flagged: outside its town's territory". **Expected:** only structures flagged
    outside their town's territory (the Outpost after § 3.3 step 9). The Warehouse and ProductionStructure lists have the
    same filter; "All structures" lists everything again. (A07)
11. [automated: `form-builder-draft-rules.spec.ts › the rule builder offers InsideTerritory as a warning with the town
    holder config`; Jest `ValidationRuleBuilder.test.tsx › keeps a saved InsideTerritory rule selected with its own
    settings`] As **Admin**, open the form configuration `ProductionStructure - Default (seed v1)` in the form builder
    and edit the field Region. **Expected:** its rules list P-1 (Region Containment) and P-2; Edit on P-2 shows
    Validation Type **Inside Territory** with its config `{"holderKind": "Town", "holderIdPath": "Id"}` and "Block step
    progression" off. Cancel, press **+ Add Rule** and choose Validation Type **Inside Territory**. **Expected:** the
    config fills with the town holder (`holderKind` Town, `holderIdPath` Id), the error message "The region is not
    inside {townName}'s territory (or part of it is contested).", "Block step progression on validation failure" is off
    (placement rules warn by default) and a help line says the game server answers it and that it never blocks a save
    while it can't be checked. Cancel without saving the form. (A06, R2)
12. [partly automated: knk-web-api `StructureSubtypeServicesTests.Update_MovesAStructureFromItsDistrictToRural_AndKeepsItsStorages`
    (the save); by hand: the edit form in the web app] View the Mill (in Market), press **Edit**; on **Placement** clear
    District, Street and House number and pick **Rivertown** under Town (rural); on **Production** set Level 4; Submit.
    **Expected:** "ProductionStructure updated."; the Placement panel shows "Rural, in its town's territory (no district
    or street)" with Town Rivertown, Production "…, level 4", and the Storages panel still lists the same "Mill - output"
    storage.

### 3.3 Steps (plugin #677)

Built by link L8 (knk-plugin, merged into `next` `8ebb30be`). No new `config.yml` key: everything below runs
with the existing switch `production.enabled` (plugin configuration § 4.31). Extra preconditions:

1. The plugin build from `next` on a test server with WorldGuard, connected to the API of 3.0: the API's
   `MinecraftPlugin:BaseUrl` points at the plugin's region HTTP server (`region-http.bind-address`/`port`, default
   `127.0.0.1:8081`) and both share the plugin key (`api.auth.api-key` = the API's `Security:PluginApiKey`).
2. Territory set up as in § 1.3 preconditions 2-4 (Phoenix with Market, range 200; Rivertown), the plugin `production`
   block merged, `enabled: false` at first. API game setting `production.enabled` on.
3. The § 3.1 objects with regions drawn in game: **Market warehouse** (inside Market), **Quarry** (rural, Phoenix,
   within 200 blocks of Market's edge), **Outpost** (rural, Phoenix, more than 200 blocks from every Phoenix district).
   Note their `wgRegionId`s and Phoenix's and Rivertown's ids.
4. In game: **Staff** with `knk.admin.world`, `knk.admin.world.territory` (for `/knk territory rebuild`) and
   `knk.admin.regions` (for `/knk regions repair`), and WorldGuard's `/rg info`; **Member** and
   **Visitor** for the PvP check. For steps 5-7 a shell on the game server host (`curl`).

Full manual run about 30 minutes; the untagged and partly tagged parts about 15 minutes.

1. [partly automated: knk-plugin `ProductionManagedRegionTest.withProductionOff_everythingIsAsBeforeP2c`,
   `TerritoryLookupHandlerTest.withProductionOff_bothRoutesAnswer503_territoryUnavailable_withoutReadingARegion`; by
   hand: the log of a real repair] With `production.enabled: false`, as Staff type `/knk regions repair`, then
   `/rg info <Quarry's region>`. **Expected:** the repair log names `Structure#<Quarry> 'Quarry': its District (id null)
   is unknown or has no region; no parent set` as before P2c; the quarry's region is not given the production kind's
   flags (no `entry` flag added). On the host, `curl -s -H "X-API-Key: <key>"
   "http://127.0.0.1:8081/api/territory/contains-location?holderKind=Town&holderId=<Phoenix>&x=0&z=0"` answers HTTP 503
   with `{"inside":null,"available":false,"reason":"territory is off on this game server (production.enabled: false)"}`,
   and § 3.1 step 5 (the Outpost) still says the P-2 rule was "not checked". (A21)
2. [automated: `ProductionManagedRegionTest.withProduction_aRuralStructure_isTopLevel_inItsTownsWorld_withoutAWarning`,
   `ProductionManagedRegionTest.theRepair_givesTheRuralRegionItsFloorPriority_noParent_andTheResourceProductionFlags`,
   plugin scenario `rural-structure-region`] Set `production.enabled: true`, restart, wait for the startup repair (or
   type `/knk regions repair`), then `/rg info` on the Quarry's, the Market warehouse's and a production structure in
   Market's (the Mill of § 3.1 step 10, before it moved) regions. **Expected:** the Quarry: no parent, priority 30
   (`RESOURCE_PRODUCTION` floor), flag `entry: ALLOW`; the repair log lists it as `ProductionStructure#<id> 'Quarry'
   (rural, Town#<Phoenix>)` with no "unknown district" warning. The warehouse: parent Market's region, priority 30, no
   flags added (kind `STRUCTURE`). A production structure in Market: parent Market's region, priority 30, `entry:
   ALLOW`. (P2c, production DESIGN § 3.4)
3. [automated: plugin scenario `rural-structure-region` (the WorldGuard PvP query at both spots)] As Member, hit
   Visitor while both stand inside the Quarry's region, then while both stand inside the Market warehouse.
   **Expected:** at the Quarry the hit does damage (no parent region, so no town `pvp deny` is inherited; the world
   default applies); at the warehouse it is refused (Phoenix's `pvp deny`). (Production DESIGN § 3.4, confirmed
   2026-11-11)
4. [partly automated: `ProductionManagedRegionTest.theSubtypes_mapToTheirKinds_onlyWithProduction`; by hand: the
   creation hook on a real region step] Create a new rural production structure for Phoenix with region capture (the
   web app form of § 3.2, or a WorldTask region step from the API) and finish the region in game. **Expected:** the log
   shows `[KnK Regions] New region <id> as RESOURCE_PRODUCTION: ...`; `/rg info <id>` shows priority 30 and
   `entry: ALLOW`, with no parent.
5. [automated: `TerritoryLookupHandlerTest.aRegion_insideItsTownsTerritory_isTrue_outsideOrPartlyOutside_isFalse`,
   `TerritoryLookupTest.aRegion_isInside_onlyWhenEveryColumnIsOwned`, `TerritoryLookupTest.theRegionsUnion_withItsSubRegions_isChecked`]
   On the host: `curl -s -H "X-API-Key: <key>"
   "http://127.0.0.1:8081/api/territory/contains-region/<Quarry's region>?holderKind=Town&holderId=<Phoenix>&world=world"`,
   then the same for the Outpost's region, then the Quarry's with `holderId=<Rivertown>`. **Expected:** HTTP 200 each;
   the Quarry for Phoenix `{"inside":true,"holder":"Town <Phoenix>","columns":<n>,"notOwned":0}`; the Outpost
   `"inside":false` with a `reason` naming how many columns Phoenix does not own and the first one; the Quarry for
   Rivertown `"inside":false`. A region with sub-regions is checked as their union.
6. [automated: `TerritoryLookupHandlerTest.aLocation_isAnsweredFromTheCache_inTheDefaultWorldWithoutAWorld`,
   `TerritoryLookupTest.aLocation_isInside_whenItsColumnIsOwnedByTheHolder`,
   `TerritoryLookupTest.contestedColumns_countAsNotOwned`] Stand at three spots and note the block x/z (F3): in Phoenix
   territory, in the wilderness, and in contested land (§ 1.3 step 8). For each: `curl -s -H "X-API-Key: <key>"
   "http://127.0.0.1:8081/api/territory/contains-location?holderKind=Town&holderId=<Phoenix>&x=<x>&z=<z>"`.
   **Expected:** `"inside":true,...,"owner":"Town <Phoenix>","contested":false`; then `"inside":false,...,"owner":null`;
   then `"inside":false,...,"contested":true` (contested land counts as not owned). Without `world` the server's
   default world is used.
7. [automated: `TerritoryLookupHandlerTest.badRequests_unknownRegions_andMissingKeys_areNamed`,
   `TerritoryLookupTest.parse_readsTheHolderAndColumn_andNamesTheFirstProblem`] Send step 5's request without the
   `X-API-Key` header, with `holderKind=Duchy`, and for a region id that does not exist. **Expected:** 401; 400 naming
   `holderKind`; 404 `region <id> not found`. (The API shows every non-200 answer as "not checked", never a block.)
8. [partly automated: knk-web-api `InsideTerritoryValidatorTests` (the client's URLs and answers),
   `PlacementRulesTests.P2_RuralOutsideItsTownsTerritory_WarnsByDefault_AndSaves`; knk-plugin
   `TerritoryLookupHandlerTest` (the plugin's answers); by hand: the two together] With the plugin connected, repeat
   § 3.1 step 5 (the Outpost) and step 3 (a quarry inside the territory, with another name), then § 3.1 step 6 with P-2
   blocking. **Expected:** the Outpost saves with the P-2 warning "not inside its town's territory" (no longer "not
   checked"); the quarry saves without a P-2 warning; with P-2 blocking the Outpost answers 400. Switch P-2 back to a
   warning. (A06, R2)
9. [partly automated: `TerritoryServiceTest.ruralStructures_areFlaggedThroughTheirTownId_fromTheStructureSearch`,
   `StructuresMapperTest.theSearchRows_carryTheTown_ruralRowsHaveNoDistrictOrStreet`; by hand: the flags in the API]
   As Staff, `/knk territory rebuild`, then `GET api/Territory/structures/<Outpost>` and `<Quarry>`. Raise Rivertown's
   power until its territory overlaps the Quarry (§ 1.3 step 8) and rebuild again. **Expected:** the Outpost is
   flagged `OutsideTerritory`, the Quarry has no flag; after the overlap the Quarry is `Contested` with the conflict id,
   keeps town Phoenix and `productionEnabled` true (`GET api/ProductionStructures/<Quarry>` shows the contested
   warning). The log line `Report for world: ... flagged structure(s)` counts the rural structures. (A07, R3)
10. [automated: `ProductionManagedRegionTest.aStructureMovedFromItsDistrictToRural_keepsItsOldParent_theRepairNeverClearsOne`]
    Move the Mill from Market to rural Rivertown (§ 3.1 step 10), then `/knk regions repair` and `/rg info <Mill's
    region>`. **Expected:** priority 30, but its old parent (Market's region) is kept: the repair never clears a parent.
    Remove it by hand with `/rg setparent <Mill's region>` (no parent argument); a second repair leaves it without a
    parent.
11. [partly automated: `ProductionManagedRegionTest.withProductionOff_everythingIsAsBeforeP2c`; by hand: the restart]
    Set `production.enabled: false` again and restart; type `/knk regions repair`. **Expected:** the regions keep what
    the repair set while it was on (the repair only adds); no lookup answers (503 again); the Quarry is reported with
    the old "unknown district" warning. (A21)

## 4. Phase P3: production engine (#86 API, #678 web app; tier:3)

Built so far: link L9, the API (knk-web-api, migration `AddProductionEngine`; branch `claude/production-p3`, PR into
`next`). The kind, level, line, modifier, climate zone and weather editors, the structure's production view with the
cycle trace and the upgrade button are link L10 (#678, § 4.2); § 4.1 runs with a REST client (or Swagger) against
the API and the generic forms of the seeds. 18 steps in § 4.1: 16 automated in CI and 2 partly (tagged); every step can
still be run by hand; manual steps not run. Full manual run about 60 minutes (most of it waiting for cycles; `POST
api/Production/run-now` settles at once); the untagged parts of the partly tagged steps about 10 minutes. The tests are
in knk-web-api `Tests/.../Services/Production/ProductionEngineTests.cs`, `ProductionModifierWeatherUpgradeTests.cs`,
`Api/ProductionEngineControllersTests.cs`, `Migrations/AddProductionEngineTests.cs` and, with `KNK_TEST_MYSQL`,
`MySql/ProductionEngineMySqlTests.cs` (four sweeps racing on the same lines settle each period once). The developer
waived the smoke gates of L4 and L6 on 2026-11-19; the coordinator reads that as covering this link too (it builds on L6).

### 4.0 Preconditions

1. knk-web-api with the migrations up to `AddProductionEngine` applied (`dotnet ef database update`). The migration
   seeds the catalogue: eight kinds (Farm, Logger, Quarry, Mine, Fishery, Flower farm, Florist, Animal farm; Hunter is
   not in V1) with ten levels each, the climate zone "Default climate" without odds (always clear), and the weather
   types Rain, Storm and Drought with example effects.
2. Game setting `production.enabled` on (web app game settings, or `PUT api/GameSettings` section `production`), except
   in step 18. Engine timing at its defaults (section `production.engine`): `baseCycleMinutes` 10, `catchUpCapHours`
   24, `weatherDayMinutes` 20 (a vanilla Minecraft day).
3. Callers: a **Staff** token with `knk.admin.world`, `knk.admin.content` and `knk.economy.admin`; a **Visitor** token
   (no staff nodes); the plugin key for step 12.
4. The quarry **Quarry** from § 3.1 step 3 (rural in Phoenix): note its id and the id of its Output storage. Its Output
   storage capped at 100 units (`PUT api/Storages/<id>` with `maxUnits` 100). Two workers (the default).
5. Item identity (§ 0) deployed: note the blueprint ids of **Cobblestone** and **Coal**. A player **Steve** with at
   least 1,000 coins.

### 4.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms and pages in the web app]
   As Staff, import the form and display seeds `ProductionKind`, `ProductionKindLevel`, `ProductionLine`,
   `ProductionModifier`, `ClimateZone` and `WeatherType`, and the new versions `ProductionStructure - Default (seed
   v2)` (form and display), `ItemBlueprint - Default (seed v2)` (form) and `Storage - Default (seed v2)` (display), each
   with "make default". **Expected:** each imports; the ProductionStructure form's "Production" step has a "Production
   kind" picker before "Level"; the ItemBlueprint form's "Item in game" step has "Storage weight" after "Max stack
   size"; a storage's page lists its stock by blueprint name, not id (#819). (A23)
2. [automated: `ProductionModifierWeatherUpgradeTests.TheSeededCatalogue_HasEightKindsWithTenLevelsEach_AndNoHunter`]
   `GET api/ProductionKinds`. **Expected:** the eight kinds, each with `levels` 1-10 (level 1 `yieldMultiplier` 1, level
   2 1.15, … level 10 2.35; `cycleSpeedMultiplier` 1 to 1.45); no Hunter. `GET api/ClimateZones` lists "Default
   climate" with `isDefault` true and no `weatherOdds`. (A09)
3. [automated: `ProductionEngineTests.ANewStructure_GetsItsKindsWorkers_StoragesAndLevelCaps`]
   `PUT api/ProductionStructures/<Quarry>` with the quarry's body and `"productionKindId": 3` (Quarry). **Expected:**
   204; `GET` shows `productionKind` `{ "id": 3, "name": "Quarry" }`. A `productionKindId` that doesn't exist is 400. A
   structure created with a kind gets the kind's `defaultWorkers` and the storages in its `defaultStoragesJson` next to
   its Output storage.
4. [automated: `ProductionModifierWeatherUpgradeTests.Lines_AreConfiguredOnlyInP3_OnePerBlueprint_AndKeepTheirStructure`]
   `POST api/ProductionLines` with `{ "productionStructureId": <Quarry>, "itemBlueprintId": <Cobblestone>,
   "configuredRatePerHour": 60 }`. **Expected:** 201; `rateSource` `Configured`, `status` `Running`, `accrued` 0,
   `nextSettleAt` 10 minutes after `anchorAt`. A second line for Cobblestone on the quarry is 400; `rateSource`
   `Derived` is 400 (P4).
5. [automated: `ProductionEngineTests.Accrual_IsDriftFree_OverSixHoursOfTenMinuteSweeps_EvenWhenTheSweepRunsLate`,
   `ProductionEngineTests.ASweepOnlySettlesDueLines_AndASecondSettleAtTheSameMoment_ProducesNothingMore`,
   `ProductionEngineTests.ARunNowSweep_SettlesEveryLine_NotOnlyTheDueOnes`]
   Wait 10 minutes (the sweep runs every minute), or `POST api/Production/run-now`. Then
   `GET api/ProductionStructures/<Quarry>/production`. **Expected:** the Output storage holds 10 Cobblestone (1 per
   minute); the line shows `baseRatePerHour` 60, one modifier "Level 1" (Multiply 1), `workerFactor` 1,
   `effectiveRatePerHour` 60 and no `notProducingReasons`; `recentCycles` has one record with `elapsedSeconds` 600,
   `emitted` 10, `accepted` 10 and a `stockTransactionId` whose reason is `Production` (from `SYS_PRODUCTION`). The next
   `nextSettleAt` is 20 minutes after `anchorAt` even if the sweep ran a few seconds late (no drift). (A08)
6. [automated: `ProductionModifierWeatherUpgradeTests.Additions_ComeBeforeMultiplications_AndTheTraceListsThemInThatOrder`]
   `POST api/ProductionModifiers` with `{ "name": "Plus 40", "scope": "Global", "effect": "Add", "value": 40 }` and
   with `{ "name": "Half", "scope": "Global", "effect": "Multiply", "value": 0.5 }`. Wait an hour (or settle after an
   hour). **Expected:** 50 more Cobblestone ((60 + 40) × 0.5; multiplying first would give 70); the cycle's `modifiers`
   list "Plus 40", "Level 1", "Half" in that order. Delete both modifiers. (A08)
7. [automated: `ProductionModifierWeatherUpgradeTests.Scopes_MatchTheStructuresTownTerritoryItselfOrItsLine`,
   `…AnotherTownsModifier_DoesNotApply_AndAKingdomModifierFollowsTheTown`,
   `…Targets_MatchTheBlueprintCategoryOrKind`, `…TheActiveWindow_StartsInclusive_AndEndsExclusive`,
   `…ModifierValidation_NeedsAnExistingScopeRow_AndTheTargetsField`]
   Create a modifier Multiply 2 with scope `Town` and `scopeRefId` Rivertown, then one with scope `Town` Phoenix and
   target `Category` `Stone`, then one with an `activeUntil` in the past. **Expected:** only the Phoenix one doubles the
   rate (the production view shows it); a `Town` scope without `scopeRefId` or with an unknown town is 400. Delete them.
8. [automated: `ProductionEngineTests.TheLevelModifier_MultipliesTheRate_AndTheTraceListsIt`,
   `ProductionEngineTests.ANewStructure_GetsItsKindsWorkers_StoragesAndLevelCaps`]
   Raise the quarry to level 2 (`PUT api/ProductionStructures/<Quarry>` with `"level": 2`). Wait an hour. **Expected:**
   the trace shows "Level 2" (Multiply 1.15): 69 Cobblestone per hour. `POST api/ProductionKindLevels/search` with
   filter `productionKindId` 3: level 2's `maxAreaSize` (327680) is above level 1's (262144). When level 2 has an
   `outputMaxUnits` or `transportCapacity`, the structure's Output storage and transport capacity take them on the
   level change (the seeded levels leave them as they are). (A09)
9. [automated: `ProductionEngineTests.ANewStructure_GetsItsKindsWorkers_StoragesAndLevelCaps`,
   `ProductionModifierWeatherUpgradeTests.UpgradesStopAtLevel10_AndNeedAKind`]
   Try to set level 11 (`PUT` with `"level": 11`). **Expected:** 400; levels are 1-10. An upgrade of a level-10
   structure is 409. (A09)
10. [automated: `ProductionModifierWeatherUpgradeTests.AnUpgrade_PaysItsResourcesAndCoins_AndRaisesTheLevel`,
    `…AnUpgradeThatCantBePaid_ChangesNothing`]
    `PUT api/ProductionKindLevels/<Quarry level 3>` with `{ "upgradeCoins": 1000, "items": [ { "role": "UpgradeCost",
    "itemBlueprintId": <Cobblestone>, "amount": 20 } ] }`. Then `POST api/ProductionStructures/<Quarry>/upgrade` with
    `{ "payerUserId": <Steve> }`. **Expected:** 200 with `fromLevel` 2, `toLevel` 3, `coinsPaid` 1000; Steve has 1,000
    coins fewer (reason `PRODUCTION_UPGRADE`); 20 Cobblestone left the Output storage to `SYS_CONSUMPTION` with reason
    `Upgrade`. Repeat with too little stock: 409 and nothing changes; without `payerUserId`: 400.
11. [automated: `ProductionEngineTests.AFullOutputStorage_StallsTheLineWithoutAccruing_AndItResumesWithoutCatchUp`]
    Let the Output storage fill to 100. **Expected:** the line's `status` is `BlockedFull` and the production view says
    "The Output storage is full …"; the cycle that filled it shows the units it could not take (`emitted` above
    `accepted`); more time passes without anything accruing. (A08, D4)
12. [partly automated: `ProductionEngineTests.AFullOutputStorage_StallsTheLineWithoutAccruing_AndItResumesWithoutCatchUp`,
    `ProductionEngineTests.BlockedAndResumed_AreQueuedAsNotifications`; by hand: the pending notifications]
    Empty the storage (`POST api/StockTransactions/adjust` with a negative amount). Wait 10 minutes, then another 10.
    **Expected:** at the first settle the line is `Running` again with nothing produced for the stalled time; after the
    next 10 minutes 10 (× the level multiplier) Cobblestone. `GET api/PlayerNotifications/pending` with the plugin key
    lists a `ProductionLineStatusChanged` for `BlockedFull` and one for `Running`. (A08)
13. [automated: `ProductionEngineTests.WorkerFactor_IsPresentOverTotal`,
    `ProductionEngineTests.SetWorkersPresent_SettlesFirst_SoTheTimeBeforeCountsAtTheOldFactor`]
    `PUT api/ProductionStructures/<Quarry>/workers` with `{ "workersPresent": 1 }`, wait an hour, then `0`, wait an hour.
    **Expected:** half the rate with one of two workers, nothing with none; the production view says "Only 1 of 2
    workers present: 50% output" and "All workers are away"; `workersPresent` 3 is 400. Set it back to 2.
14. [automated: `ProductionEngineTests.Inputs_AreTakenFromTheInputStorage_AndAMissingInputBlocksTheLine`]
    Give the Mine kind `"defaultStoragesJson": "[{\"purpose\":\"Input\",\"name\":\"inputs\"}]"`, create a rural mine of
    that kind and a line for Cobblestone at 60 per hour with `"inputs": [ { "itemBlueprintId": <Coal>,
    "amountPerHour": 30 } ]`. Wait an hour. **Expected:** `BlockedInputs` with "Not enough Coal in the Input storage".
    Put 100 Coal into its Input storage, wait 10 minutes and then an hour: `Running`, 60 Cobblestone, 70 Coal left, 30
    Coal moved to `SYS_CONSUMPTION` with reason `ProductionInput`. (V2 defect 12)
15. [automated: `ProductionModifierWeatherUpgradeTests.TheWeather_IsRolledOncePerZoneAndDay_AndItsEffectIsAModifierInTheTrace`,
    `…ARoll_IsIdenticalOnReplay_AndTheStoredRowWinsWhenTheOddsChange`,
    `…ATownInItsOwnZone_GetsThatZonesWeather_AndRollAll_RollsEachZoneOnce`,
    `…ClimateZones_KeepExactlyOneDefault_AndOddsAtMost100`]
    `PUT api/WeatherTypes/<Storm>` with `"effects": [ { "category": "Stone", "effect": "Multiply", "value": 0.5 } ]` and
    `PUT api/ClimateZones/1` with `"weatherOdds": [ { "weatherTypeId": <Storm>, "chancePercent": 100 } ]`. Wait an hour.
    **Expected:** the quarry produces half; the trace lists "Storm in Default climate (Stone)" (source `Weather`);
    `GET api/ClimateZones/1` lists `rolls`, one per 20-minute day, all Storm; `POST api/ClimateZones/rolls/search`
    lists the same. Odds that add up to more than 100 are 400; deleting the default zone is 409. Set the odds back to
    none.
16. [automated: `ProductionEngineTests.TheStructureSwitch_AndTheLineSwitch_PauseWithoutAccruing`]
    `PUT` the quarry with `"productionEnabled": false`, wait an hour, switch it on again. Then `PUT
    api/ProductionLines/<line>` with `"enabled": false` and back. **Expected:** `Paused` while off, nothing accrues for
    that time, and production resumes from the moment it is switched on.
17. [automated: `ProductionEngineTests.CatchUp_IsCapped_AndTheTraceSaysHowMuchWasSkipped`]
    Stop the API for more than a day (or test on a copy). **Expected:** at the first settle after the restart the line
    accrues at most 24 hours (`catchUpCapHours`); the cycle record says "Catch-up capped at 24 h" and how many seconds
    were skipped.
18. [automated: `ProductionEngineTests.TheFeatureOff_SettlesNothing_AndTheOverviewSaysSo`,
    `ProductionEngineControllersTests.RunNow_Is409WhileTheFeatureIsOff_And200WhileOn`,
    `ProductionEngineControllersTests.Settle_Is409WhileOff_ProductionViewIs404ForAMissingStructure_AndWorkersAreChecked`,
    `ReadAccessRulesTests`, `EndpointAccessRulesTests`, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`]
    Turn `Production:Enabled` off and wait one interval. **Expected:** nothing accrues and no weather is rolled; `POST
    api/Production/run-now` and `POST api/ProductionLines/<line>/settle` are 409; the production view says
    "Production is turned off for the whole server"; the kind, line and modifier CRUD still work. As Visitor, `POST
    api/ProductionKinds` is 403; as Staff without `knk.economy.admin`, the upgrade is 403. (A21)

### 4.2 Steps (web app #678)

Built in link L10 (knk-web-app, branch `claude/production-p3b`, PR into `next`). The tags name tests in knk-web-app
`e2e/production-engine.spec.ts` (Playwright, mocked API; the mocks use the same names with other numbers: a 10/h
Cobblestone line, a Festival of +2/h, Rain × 0.5, one of two workers present) and the Jest tests next to the code
(`src/utils/__tests__/productionEngine.test.ts`, `src/apiClients/__tests__/productionEngineClients.test.ts`). Extra
preconditions: § 4.0 and § 4.1 step 1 (the production form and display seeds imported, "make default"); the quarry has
the kind Quarry (§ 4.1 step 3). Log in to the web app as **Staff** (holds `knk.admin.world`, `knk.admin.content` and
`knk.economy.admin`) unless a step says otherwise. 16 steps: 13 automated, 3 partly (tagged); every step can still be
run by hand; not run. Full manual run about 45 minutes; the untagged parts about 10 minutes.

1. [automated: `dashboard › lists the kinds with their area model, category, default workers and structures`] Open the
   dashboard and type **ProductionKind**. **Expected:** columns Name, Area model, Resource category, Default workers,
   Structures and Active; eight kinds, Quarry with `ExclusiveVolume`, Stone, 2 and 1 structure (the quarry).
2. [automated: `kinds and levels › a kind's page lists its levels with multipliers, caps, upgrade cost and unlocks
   (A09)`] View the kind **Quarry**. **Expected:** below the details a **Levels** panel with levels 1 to 10, each with
   its yield (level 2 "× 1.15"), cycle speed, max area ("No cap" when 0), output cap, upgrade coins, upgrade cost and
   unlocks; each "Level n" links to the level's page. (A09)
3. [partly automated: `kinds and levels › edits a level's unlocks and upgrade cost; the list replaces the stored one (G8,
   G17)`; by hand: the level's own values with its seeded form] Open Quarry's **Level 2**. Press Edit and set Yield
   multiplier 1.2 and Upgrade coins 500; save. **Expected:** the details show 1.2 and 500. In the **Unlocks and upgrade
   cost** panel press **Add item**, keep Role "Upgrade cost", search "Cobble" under Blueprint and pick Cobblestone; with
   Amount empty the panel says "An upgrade cost needs a whole amount above 0." and **Save items** stays off. Enter 64.
   Press **Add item** again, pick Role "Unlock" (Amount turns off) and Blueprint Coal. Press **Save items**.
   **Expected:** "Level 2 items saved."; the list shows both rows after the reload and the kind's Levels panel shows
   "64 × Cobblestone" and "Coal" on level 2. (G8, A09)
4. [partly automated: `dashboard › lists the lines with their rate and state, a blocked one in words (D4)`; by hand:
   creating the line with the seeded ProductionLine form] On the quarry's page press **Add a production line** in the
   Production panel; the ProductionLine form opens. Pick the quarry, Output Coal, Rate 30; submit. **Expected:** back on
   the quarry's page; on the dashboard type **ProductionLine**: the Coal line with Structure "Quarry", Output "Coal",
   Rate "30/h", Status "Running" (a line whose storage is full shows "Blocked: output storage full").
5. [automated: `a line › shows its state and adds an input taken per hour; the list replaces the stored one`] Open the
   Coal line. **Expected:** a **Production line** panel with the structure (linked), the output and rate, State
   "Running", Accrued, Last settled and Next settle. Press **Add input**, pick Cobblestone and Per hour 0.5, press
   **Save inputs**. **Expected:** "Inputs saved."; the input stays after the reload and Save inputs turns off.
6. [automated: `a line › Settle now settles the line; while production is off the API's reason is shown (A21)`] Press
   **Settle now**. **Expected:** "Settled: <accepted> of <emitted> accepted." (or "Settled: nothing was due."), and the
   Latest cycles table gets a row when anything accrued. Turn `production.enabled` off in the game settings and press
   Settle now again. **Expected:** "Production is turned off (Production:Enabled)." in the panel. Turn it back on.
   (A21)
7. [partly automated: `dashboard › lists the modifiers with their scope, effect and window`; by hand: creating the
   modifier with the seeded ProductionModifier form] Create a **ProductionModifier** "Festival": Scope Town, Scope ref
   the id of Phoenix, Target Any, Effect Add, Value 2, Active from today. **Expected:** on the dashboard (type
   ProductionModifier) the row shows Scope "Town #<Phoenix id>", Effect "+2/h", Active "From <date>" and Enabled "Yes".
8. [automated: `weather › a climate zone: odds at most 100% with the rest clear, a town added, the stored rolls`] Open
   the climate zone **Default climate**. **Expected:** a **Weather** panel: "The default zone: towns in no other zone
   use it.", "No weather types: always clear." and the stored rolls (Day, From, Until, Weather, Roll; "Clear" when no
   type was rolled). Press **Add weather type**, pick Rain, Chance 80; press it again, pick Storm, Chance 30.
   **Expected:** "The chances add up to 110%: at most 100%." and **Save odds** is off. Set Storm to 10. **Expected:**
   "Together 90%; clear 10%."; Save odds saves both. Under Towns search "Phoenix", press **Add town** and **Save
   towns**. **Expected:** "Towns saved."; Phoenix is listed and linked.
9. [automated: `weather › a weather type's effects per category`] Open the weather type **Rain**. **Expected:** an
   **Effects** panel with its seeded effects. Press **Add effect**: a second row with the same category and effect says
   "A category has the same effect twice."; pick Category Stone, Effect Multiply, Value 0.5 (the row shows "× 0.5") and
   press **Save effects**. **Expected:** "Effects saved."
10. [automated: `the production structure page › shows each line's rate with its modifiers in order and why the blocked
    one is not producing (A08, D4)`] Open the quarry's page (with Rain rolled today, or roll it with step 15's Run
    production now after setting Rain to 100% for the test). **Expected:** a **Production** panel: Kind "Quarry"
    (linked), Level "1 of 10", the climate zone and Weather today. Under Lines, the Cobblestone line with its state and
    rate and a table: Base rate 60/h, "Admin: Festival +2/h" = 62/h, "Weather: Rain" for Stone "× 0.5" = 31/h,
    Workers present "× 100%" (or 50% with one away), and the Effective rate. Fill the Output storage to its cap (100);
    after the next settle the line shows "Blocked: output storage full" with the reason under it. (A08, D4)
11. [automated: `the production structure page › the cycle trace lists each applied modifier, the workers and the ledger
    transaction (A08, #65)`] In the Production panel's **Latest cycles** table press **Trace** on a Cobblestone cycle.
    **Expected:** the cycle's period, rate, "accepted of emitted", state after and shortfall; the trace lists the base
    rate, each modifier in the order applied, the workers present ("2 of 2"), the accrual before and after, the inputs
    taken and a link to the ledger transaction. A blocked cycle shows "0 of n" with the reason. (A08)
12. [automated: `the production structure page › the structure-wide reasons when production is off`] Turn
    `production.enabled` off and reload the quarry's page. **Expected:** "Not producing" with "Production is turned off
    for the whole server" (the API's wording); turn it back on. (A21)
13. [automated: `the production structure page › sets the workers present within the structure's total`] Under
    **Workers** enter 3. **Expected:** "A whole number from 0 to 2." and Save workers is off. Enter 1 and press **Save
    workers**. **Expected:** "Workers present: 1."; the Workers present column of the Placement panel shows "1 of 2" and
    the Workers present step of each line's rate shows "× 50%".
14. [automated: `the production structure page › upgrades with the cost shown first; a refused upgrade shows the API's
    reason (A09)`, `the production structure page › staff without knk.economy.admin see the cost but cannot upgrade`]
    Under **Upgrade** the panel shows "Level 2 costs 500 coins and 64 × Cobblestone." (step 3). **Upgrade to level 2**
    is off until a payer is picked: search "Steve" under "Paid by (coins)" and pick him; leave "Resources from" empty
    (the Output storage). Press **Upgrade to level 2**, then **Pay and upgrade**. With fewer than 64 Cobblestone in the
    Output storage **Expected:** the API's reason (409) in the panel and nothing paid. Fill it to 64 or more and press
    Pay and upgrade again. **Expected:** "Upgraded from level 1 to 2, 500 coins paid, resources: transaction #<id>." with
    the transaction linked; Level "2 of 10"; Steve has 500 coins less. As a staff member without `knk.economy.admin`
    the cost is shown but the button is off with "Requires knk.economy.admin". (A09)
15. [automated: `game settings › Run production now reports what the sweep did`] As Admin open **Game settings**.
    **Expected:** a **Production engine** card with Base cycle 10, Catch-up cap 24 and Weather day 20. Press **Run
    production now**. **Expected:** "<n> lines settled, <a> of <e> units accepted, <w> weather rolls." (With production
    off the button is off: "Production is off: nothing runs".)
16. [automated: `game settings › keeps the engine timing on a save of another section, and saves a changed one`, Jest
    `territory helpers › keeps the production engine timing, so a save does not reset it (#678)`] Set Base cycle 5 and
    save; then change only "Blocks per power point" in the Production and territory card and save. **Expected:** after a
    reload Base cycle is still 5 (`GET api/GameSettings` shows `production.engine.baseCycleMinutes` 5). Weather day 0
    shows "production.engine.weatherDayMinutes must be a whole number between 1 and 10080." and Save is off. Set Base
    cycle back to 10 and save.

## 5. Phase P4: yield areas and surveys (#138 API, #679 plugin, #680 web app; tier:3)

Built so far: link L11, the API (knk-web-api, migration `AddProductionYieldAreas`; branch `claude/production-p4`, PR into
`next`). The survey runner, `/knk production survey|area show` and the `CaptureRadius` world task are link L12 (#679,
§ 5.2);
the area capture, survey viewer and Hybrid override editor are link L13 (#680). Until then § 5.1 runs with a REST client
(or Swagger) against the API, the plugin's part played by `POST api/ProductionAreas/<id>/surveys` with the plugin key.
18 steps in § 5.1: 17 automated in CI and 1 partly (tagged); every step can still be run by hand; manual steps not run.
The web app part (§ 5.3, link L13) is built: 12 steps, 9 automated in CI, 2 partly and 1 by hand.
Full manual run about 45 minutes (an hour of it waiting, or `POST api/Production/run-now`); the untagged part of the
partly tagged step about 5 minutes. The tests are in knk-web-api `Tests/.../Services/Production/ProductionYieldTests.cs`,
`Api/ProductionYieldControllersTests.cs`, `Services/Production/PlacementRulesTests.cs` (#831),
`Migrations/AddProductionYieldAreasTests.cs` and, with `KNK_TEST_MYSQL`, `MySql/ProductionYieldMySqlTests.cs`. The
developer waived the smoke gates of L4 and L6 on 2026-11-19; the coordinator reads that as covering this link too (it
builds on L9, whose smoke test is open).

### 5.0 Preconditions

1. knk-web-api with the migrations up to `AddProductionYieldAreas` applied. The migration gives every production kind
   a survey profile (version 1: Farm `CROP`, Logger `TREE` and `SAPLING`, Quarry and Mine `BLOCK`, Fishery `WATER`,
   Flower farm and Florist `FLOWER`, Animal farm `ENTITY`) and a primary multiplier of 1.5. Production structures that
   existed before keep yield source `Configured`; new ones are `Hybrid` (P-D1).
2. Everything of § 4.0, with `Production:Enabled` on except in step 17: the quarry **Quarry** from § 4 (Configured,
   its Cobblestone line), a **Staff** token (`knk.admin.world`, `knk.admin.content`), a **Visitor** token and the plugin
   key.
3. Blueprints **Oak log**, **Birch log**, **Stick** and **Apple** (shadow blueprints from § 0 or made by hand); note
   their ids.
4. The level caps seeded by `AddProductionEngine`: Logger level 1 radius 32 (level 2: 36), Quarry and Mine level 1
   volume 262,144 (64 × 64 × 64).

### 5.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms and pages in the web app]
   As Staff, import the form and display seeds `ProductionArea` and `ProductionYieldOverride`, the display seed
   `AreaSurvey`, and the new versions `ProductionKind - Default (seed v2)` (form and display), `ProductionStructure -
   Default (seed v3)` (form and display) and `Structure - Default (seed v3)` (form), each with "make default".
   **Expected:** each imports; the ProductionKind form has a "Yield" step (survey profile, primary multiplier); the
   ProductionStructure form has "Yield source" after "Production kind"; the Structure form's "Placement" step has
   "Town (rural)" and no required district fields (#831). (A23)
2. [automated: `AddProductionYieldAreasTests.Up_AddsColumnsWithDefaults_ExistingStructuresStayConfigured`,
   `Up_SeedsASurveyProfilePerKind_AndChangesNothingElse`]
   `GET api/ProductionStructures/<Quarry>` and `GET api/ProductionKinds/2`. **Expected:** the quarry's `yieldSource` is
   `Configured` and it still produces its Cobblestone; the Logger kind has `surveyProfileJson`
   `{"unitTypes":["TREE","SAPLING"]}`, `surveyProfileVersion` 1, `primaryMultiplier` 1.5, an empty `yieldTable`.
3. [automated: `ProductionYieldTests.TheKindsYieldTableAndProfile_AreChecked_AndAProfileChangeRaisesItsVersion`]
   `PUT api/ProductionKinds/2` with `"yieldTable": [ { "unitKey": "TREE:OAK:LARGE", "itemBlueprintId": <Oak log>,
   "ratePerUnitPerHour": 2 }, { "unitKey": "TREE:OAK:*", "itemBlueprintId": <Oak log>, "ratePerUnitPerHour": 1 },
   { "unitKey": "TREE:BIRCH:*", "itemBlueprintId": <Birch log>, "ratePerUnitPerHour": 1 }, { "unitKey": "TREE:OAK:*",
   "itemBlueprintId": <Stick>, "ratePerUnitPerHour": 0.5, "byproductChance": 0.2 } ]`. **Expected:** 204; `GET` lists
   the four rows. A unit key `TREE:*:LARGE` or a `byproductChance` of 2 is 400; a changed `surveyProfileJson` raises
   `surveyProfileVersion` to 2, the same profile again doesn't.
4. [automated: `ProductionYieldTests.AnArea_OverTheLevelsCap_IsRefusedWithTheMaximum_AndALevelUpAllowsMore`,
   `…Shapes_ComputeTheirBoundingBoxAndSize_AndNeedTheirFields`, `…ARadius_CentresOnTheStructuresLocation_AndAStructureWithoutKindHasNoArea`]
   Create the rural logger **Logger A** in Phoenix with `"productionKindId": 2` (no yield source). Then `POST
   api/ProductionAreas` with `{ "productionStructureId": <Logger A>, "name": "Forest", "shape": "Radius", "radius": 33,
   "centerX": 0, "centerY": 64, "centerZ": 0 }`. **Expected:** the logger's `yieldSource` is `Hybrid`; the area is 400
   "The area is 33 (radius); level 1 of Logger allows at most 32." With `"radius": 20` it is 201 with `size` 20,
   `sizeUnit` `radius`, `maxSize` 32, `exclusive` false and the bounding box −20..20; without a centre it centres on
   the structure's Location. (A11, G6)
5. [automated: `ProductionYieldTests.ANewArea_IsDueOnCreation_ThenOnceADay_AndOnRequestFirst`]
   `GET api/ProductionAreas/survey-due` with the plugin key. **Expected:** the Forest area with `trigger` `Creation`,
   the Logger kind's `surveyProfileJson` and `surveyProfileVersion`, and `overlappingSharedAreas` empty. (A10)
6. [automated: `ProductionYieldTests.Derived_MaterializesALinePerYieldedOutput_AndProducesWhatTheForestHolds`,
   `…ASurveyReport_ChecksItsUnits_AndALateOlderSurveyStaysInTheHistoryOnly`]
   `POST api/ProductionAreas/<Forest>/surveys` with the plugin key and `{ "contentHash": "abc", "units": [ { "unitKey":
   "TREE:OAK:LARGE", "count": 10 }, { "unitKey": "TREE:OAK:SMALL", "count": 4 }, { "unitKey": "TREE:BIRCH:MEDIUM",
   "count": 6 }, { "unitKey": "TREE:SPRUCE:LARGE", "count": 3 } ] }`. **Expected:** 200 with `trigger` `Creation` and
   `materialization.linesCreated` three lines (Oak log, Birch log, Stick) with `rateSource` `Hybrid`; survey-due no longer
   lists the area. `GET api/ProductionStructures/<Logger A>/yield`: Oak log 24 per hour (10 large × 2, exact row beats
   the prefix, + 4 small × 1), Birch log 6, Stick 1.4 (14 oaks × 0.5 × 0.2, a share, not a roll), each with its
   contributions (area, unit, count, share, row, rate); `unmatchedUnitKeys` `TREE:SPRUCE:LARGE`. A unit key with a space,
   a negative count, `sharedBy` 0 or a key listed twice is 400. (A10)
7. [automated: `ProductionYieldTests.Derived_MaterializesALinePerYieldedOutput_AndProducesWhatTheForestHolds`]
   Wait an hour, or `POST api/Production/run-now` an hour later. **Expected:** the Output storage holds 24 Oak log,
   6 Birch log and 1 Stick; the cycle records show `rateSource` `Hybrid` and `baseRatePerHour` from the survey.
8. [automated: `ProductionYieldTests.ATreeInTwoLoggersAreas_YieldsHalfToEach`]
   Create **Logger B** with a radius area centred 10 blocks east. `GET api/ProductionAreas/<Forest>/overlaps` and
   survey-due. **Expected:** each lists the other's area (B's due entry under `overlappingSharedAreas`). Report A's
   survey with 6 `TREE:OAK:LARGE` (`sharedBy` 1) and 4 `TREE:OAK:LARGE` with `"sharedBy": 2`, B's with the same 4 shared
   trees. **Expected:** A's Oak log base is 16 (6 × 2 + 4 × 2 ÷ 2), B's 4, each shared contribution with `share` 0.5:
   the shared trees yield 8 per hour in total, however many loggers crowd them. (A11, G7)
9. [automated: `ProductionYieldTests.Hybrid_PinsExclusionsAndScales_ApplyAfterTheSurvey`]
   `POST api/ProductionYieldOverrides` with `{ "productionStructureId": <Logger A>, "itemBlueprintId": <Apple>, "kind":
   "Pin", "value": 5 }`, then an `Exclude` of Birch log and a `Scale` 0.5 of Oak log. **Expected:** the Apple line exists
   at once with `rateSource` `Hybrid`, whatever the survey says; the yield view shows Oak log derived 16 → base 8
   (Scale), Birch log Exclude → 0, Apple Pin 5. A second override for the same blueprint or a pin of 0 is 400. Delete
   the pin: the Apple line stays with a base of 0. (A10)
10. [automated: `ProductionYieldTests.ANewArea_IsDueOnCreation_ThenOnceADay_AndOnRequestFirst`,
    `Api/ProductionYieldControllersTests.AreasSurveysAndTheYieldView_AnswerWithTheRightStatus`]
    "Survey now": `POST api/ProductionStructures/<Logger A>/survey` (optionally `{ "productionAreaId": <Forest> }`).
    **Expected:** 200 with the area, `surveyRequestedAt` set and `surveyRequestTrigger` `Admin`; survey-due lists it
    with `trigger` `Admin`; the next report has `trigger` `Admin` and is a new row in `POST api/AreaSurveys/search`
    (filter `productionAreaId`), which lists every survey of the area, newest first. (A10)
11. [automated: `ProductionYieldTests.AConfiguredStructure_IsNeverSurveyed`]
    Give the Quarry an area (`"shape": "Cuboid"`, two corners). **Expected:** no `surveyRequestedAt`; the quarry never
    appears in survey-due; `POST api/ProductionStructures/<Quarry>/survey` and a survey report for its area are 409
    "The structure is Configured: it is never surveyed (G5)". (A10, G5)
12. [automated: `ProductionYieldTests.ANewArea_IsDueOnCreation_ThenOnceADay_AndOnRequestFirst`]
    Leave Logger A's area for a day after its last survey. **Expected:** survey-due lists it with `trigger`
    `Scheduled` after 24 hours, not before. (A10)
13. [automated: `ProductionYieldTests.TheTrend_ListsEachUnitKeyPerSurvey_OldestFirst`]
    Report a second survey with fewer oaks (the forest cut down), then `GET api/AreaSurveys/trend?productionAreaId=<Forest>`.
    **Expected:** the surveys oldest first and per unit key a count per survey (0 where a key is missing); the next
    settle runs at the lower rate, and an output the survey no longer yields keeps its line at base 0
    (`materialization.linesWithoutYield`).
14. [automated: `ProductionYieldTests.ExclusiveAreasOfTheSameModel_MayNotOverlap_SharedOnesMay`,
    `MySql/ProductionYieldMySqlTests`]
    Give the Quarry a pit (cuboid 0..20) and create a Mine with a shaft that cuts into it. **Expected:** 409 "The area
    overlaps the exclusive area 'Pit' of Quarry: exclusive ExclusiveVolume areas may not overlap."; next to it or in
    another world it is 201; the two loggers' radii overlap without complaint.
15. [automated: `ProductionYieldTests.MinLevelRows_StartAtTheirLevel_AndPrimaryOutputs_GetTheKindsMultiplierInTheTrace`]
    `PUT api/ProductionKinds/2` with `"primaryMultiplier": 2, "primaryOutputs": [ { "itemBlueprintId": <Oak log> } ]`
    and a row `TREE:OAK:*` → Apple with `"minLevel": 3`; raise a Derived logger to level 3. **Expected:** the Apple line
    appears only at level 3; the Oak log trace lists "Primary output of Logger" (source `Primary`, Multiply 2), other
    outputs and Configured lines don't get it.
16. [automated: `ProductionYieldTests.DerivedIgnoresOverrides_AndSwitchingToConfigured_TurnsSurveyLinesIntoConfiguredOnes`,
    `…AConfiguredLine_OnAHybridStructure_KeepsItsRate`]
    Switch Logger A to `"yieldSource": "Derived"`, then `"Configured"`. **Expected:** as Derived the yield view notes
    that the Hybrid overrides are ignored; as Configured its lines become `Configured` (rate kept, 0 unless staff set
    one) and the yield view says it is never surveyed. A source the kind doesn't allow is 400; a `Derived` line on a
    Hybrid structure is 400; a Configured line staff made on a Hybrid structure keeps its rate
    (`materialization.skippedConfigured`).
17. [automated: `ProductionYieldTests.WhileTheFeatureIsOff_NothingIsDue_AndReportsAreRefused_ButAreasCanBeEdited`,
    `Api/ProductionYieldControllersTests.WhileTheFeatureIsOff_TheQueueIsEmpty_AndReportsAre409`, `ReadAccessRulesTests`,
    `EndpointAccessRulesTests`, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`]
    Turn `Production:Enabled` off. **Expected:** survey-due is an empty list and a survey report is 409; areas,
    overrides and kinds can still be edited. As Visitor, `POST api/ProductionAreas` is 403. (A21)
18. [automated: `PlacementRulesTests.AnUpdate_ReturnsThePlacementWarnings_AsCreateDoes`,
    `…PlainMessage_DropsTheParameterSuffix_OnlyWhenThereIsOne`, `…TheStructureSeedV3_HasATownField_SoARuralStructureCanBeMadeFromIt`,
    `Api/ProductionYieldControllersTests.AreasSurveysAndTheYieldView_AnswerWithTheRightStatus`]
    #831: `PUT api/ProductionStructures/<Quarry>` (or a warehouse) with its body. **Expected:** 200 with the saved
    structure and its `placementWarnings` (it was 204); with `"level": 42` the 400 body is `{ "error": "level must be 1
    to 10." }` without " (Parameter 'dto')"; a rural plain structure can be made from the Structure form v3.

### 5.2 Steps (plugin #679)

Built by link L12 (knk-plugin branch `claude/production-p4b`, PR into `next`). Everything runs only with
`production.enabled: true`; the new keys are `production.surveys.*` (plugin configuration § 4.31, YAML in the
changelog). Extra preconditions:

1. The plugin build from `next` on a test server with WorldGuard, connected to the API of 5.0 with the plugin key
   (`api.auth.api-key` = the API's `Security:PluginApiKey`). The `production` block merged with its `surveys` keys;
   `enabled: false` at first. API `Production:Enabled` on.
2. In the world, near spawn, made by hand: a small forest (at least five oak and two birch trees of different sizes, a
   few saplings), a 20 × 20 stone pit with some coal and iron ore, a wheat and carrot field on farmland, a pond of at
   least 50 water blocks, a fenced pasture with four sheep and two cows.
3. Through the API (§ 5.1, until the web app link L13): production structures **North logger** (Logger, Hybrid) with a
   `Radius` area of 24 around the forest's centre, **South logger** (Logger, Hybrid) whose `Radius` area overlaps the
   forest's east half, **Pit** (Quarry, Hybrid) with a `Cuboid` area over the stone pit, **Farm**, **Pond** (Fishery)
   and **Pasture** (Animal farm), each Hybrid with an area over its part, and the § 4 **Quarry** (Configured). Note
   their ids and their areas' ids.
4. In game: **Staff** with `knk.admin.world` and `knk.admin.world.production` (both in `knk.admin.*`); a WorldTask code
   flow as for other world tasks (`/knk task <code>`).
5. For step 13: `metrics.enabled: true` and its port reachable (performance metrics guide).

Full manual run about 60 minutes; the untagged and partly tagged parts about 30 minutes. The tests are in knk-plugin
`knk-core/.../production/survey/` (`SurveyCounterTest`, `SurveyAreasTest`, `CaptureRadiusTest`),
`knk-api-client/.../ProductionSurveyApiImplTest`, `knk-paper/.../production/` (`SurveyRunnerTest`, `SurveyConfigTest`),
`knk-paper/.../commands/ProductionAdminCommandTest` and the plugin scenario `production-area-survey` (a real Paper
server, CI job `paper-boot`).

1. [partly automated: knk-plugin `ProductionAdminCommandTest.offWithoutProductionEnabled`, `SurveyConfigTest`; by hand:
   the log] With `production.enabled: false`, start the server and as Staff type `/knk production survey <North
   logger>`. **Expected:** "Production is off on this server (production.enabled: false)."; the log has no
   "Yield-area surveys are on" line and the API's access log shows no `survey-due` reads. (A21)
2. [partly automated: `SurveyConfigTest.theValuesAreRead`; by hand: the log] Set `production.enabled: true`, restart.
   **Expected:** the log line `Yield-area surveys are on (production.enabled): queue every 5 min, 2 chunks per tick,
   notable change after 64 blocks.`; about 30 s after start the plugin reads `GET api/ProductionAreas/survey-due`.
3. [partly automated: `CaptureRadiusTest`; by hand: the task in game] Create a world task of type `CaptureRadius` for
   a new Logger area (from the web app once L13 is in, or `POST api/WorldTasks` with `taskType` `CaptureRadius`), claim
   it with `/knk task <code>`, stand at the forest's centre and type `radius 24` in chat. **Expected:** green particles
   draw the circle around you; typing `radius 999` is refused ("The radius must be 1 to 256 blocks."); `center` after a
   few steps moves the circle; `confirm` completes the task with `shape` `Radius`, `worldName`, `centerX/Y/Z` and
   `radius` 24 in its output (the web app form or `GET api/WorldTasks/<id>`). `cancel` hands the task back.
4. [partly automated: plugin scenario `production-area-survey` (real blocks, snapshots on the main thread, counting on
   its own thread), `SurveyRunnerTest.aSurveyCapturesWithinTheTickBudget_countsAndReports`; by hand: the API's rows]
   After creating the areas of precondition 3, wait up to `poll-minutes` (or type `/knk production survey status`).
   **Expected:** each Hybrid area is surveyed once (trigger `Creation`): `GET api/AreaSurveys` lists one survey per area
   with `contentHash`, a note `plugin survey: blocks …, trees …` and units such as `TREE:OAK:MEDIUM`, `TREE:BIRCH:SMALL`,
   `SAPLING:OAK` (loggers), `BLOCK:STONE`, `BLOCK:COAL_ORE`, `BLOCK:IRON_ORE` (Pit), `CROP:WHEAT`, `CROP:CARROTS`
   (Farm), `WATER:<biome>` with extra `columns`, `avgDepth` and `openSkyShare` (Pond) and `ENTITY:SHEEP` 4,
   `ENTITY:COW` 2 (Pasture). The structures' yield (`GET api/ProductionStructures/<id>/yield`) explains its lines from
   these units once their kinds have yield table rows. (A10)
5. [automated: `ProductionAdminCommandTest.surveyAsksTheApiForTheStructure_andStatusShowsTheQueue`,
   `ProductionSurveyApiImplTest.requestSurveyAndAreas_useTheirRoutes`; by hand: the replies in chat] As Staff type
   `/knk production survey <North logger>`. **Expected:** "Asking the API to survey structure #<id>...", then "Queued 1
   area(s); you will hear each result here." and within a few seconds a green "Survey #<area> … of structure #<id> North
   logger: N rows, M units (…); survey #<n>, lines +a ~b". A new survey row with trigger `Admin`. (A10)
6. [partly automated: `ProductionSurveyApiImplTest.report_refusedWhileTheApiFlagIsOff_failsWith409`; the API side in
   § 5.1; by hand: the reply] Type `/knk production survey <Quarry>` (Configured). **Expected:** "Survey not requested:
   API 409: …Configured…"; no survey row for the Quarry, ever. (A10, G5)
7. [automated: `SurveyRunnerTest.aScheduledSurveyWaitsForLoadedChunks_aRequestedOneLoadsThem`,
   `SurveyRunnerTest.scheduledLoadsChunksLetsTheDailySurveyLoadThem_andUngeneratedChunksAreLeftOut`] Let a day pass
   (or set an area's last survey back by more than 24 h in the database) while nobody is near the Pit, then type
   `/knk production survey status`. **Expected:** the Pit's line says "skipped, N of N chunks not loaded (a Scheduled
   survey waits for loaded chunks; production.surveys.scheduled-loads-chunks)"; walk to the Pit and wait for the next
   queue read: one survey with trigger `Scheduled` that day. With `scheduled-loads-chunks: true` it is surveyed
   without anyone there. (A10, P-D2)
8. [partly automated: `SurveyAreasTest.notableChangesFireAtTheThresholdOncePerCooldown`,
   `SurveyRunnerTest.afterANotableChangeTheReportSaysSo_andOverlapsSplitTheUnits`; by hand: the survey row] Break 64
   stone blocks inside the Pit's area. **Expected:** within seconds a survey with trigger `NotableChange` and 64 fewer
   `BLOCK:STONE`; breaking 64 more within 30 minutes (`notable-cooldown-minutes`) asks for no further survey. (A10)
9. [automated: `SurveyCounterTest.sharedUnitsAreReportedPerSharedByCountingDistinctOtherStructures`, plugin scenario
   `production-area-survey` (a tree inside another structure's radius)] Survey North logger (`/knk production survey`).
   **Expected:** trees in the east half (inside South logger's area too) are reported in rows with `sharedBy` 2, the
   others with `sharedBy` 1; the API's yield explanation shows a share of 0.5 for the former. (A11, G7)
10. [automated: `SurveyCounterTest.treesAreLogClustersWithLeavesBySpeciesAndSize`,
    `…mixedTreesGoToTheMajoritySpeciesAndDiagonalBranchesJoin`, `…aLogClusterOverMaxLogsIsABuilding`,
    `…strippedLogsAndSaplings`] Build a log cabin (more than 400 logs, no leaves) and a three-log fence post in North
    logger's area, then survey it. **Expected:** neither counts as a tree; the note says "log buildings skipped 1"
    when the cabin's logs touch leaves, otherwise nothing. (PRODUCTION_KINDS § 8.2)
11. [automated: `SurveyRunnerTest.anAreaOverTheCapIsSkipped`, `SurveyAreasTest.settingsRefuseAreasOverTheCaps`]
    Set `production.surveys.max-area-chunks: 4`, restart and survey North logger. **Expected:** "skipped, the area spans
    N chunks (production.surveys.max-area-chunks 4)"; no survey row. Set it back.
12. [partly automated: `ProductionAdminCommandTest.wrongArgumentsGetTheUsage_andAShowDrawsTheStructuresAreas`; by
    hand: the particles] Type `/knk production area show <Pit>` and `/knk production area show <North logger> 0 10`.
    **Expected:** the chat lists each area (shape, exclusive or shared, bounds); orange particles outline the Pit and
    green ones the logger's circle at your feet height for 30 s (10 s for the second), seen only by you.
13. [manual] With metrics on, survey all areas at once (`/knk production survey <id>` for each) and watch
    `knk_task_duration_seconds{task="production.survey.capture"}` and the TPS. **Expected:** no main-thread spike from
    block reads: the capture task stays in the low milliseconds per tick (two chunk snapshots); counting runs on the
    `KnK-survey` thread.
14. [partly automated: `SurveyCounterTest.placeholdersCountAsTheirOriginal`, scenario `player-harvest-tree` (the overlay
    reads a felled log as `OAK_LOG`); by hand: a survey after a harvest] Harvest ore in the
    Pit (regenerating placeholders) and survey it. **Expected:** the survey counts the ore that waits to regenerate as
    present (no drop in `BLOCK:COAL_ORE`). Needs a coal ore harvest rule (§ 9.2); P8 is in knk-plugin `next` `6f6c915f`.
15. [automated: `SurveyCounterTest.theSameWorldGivesTheSameHash`] Survey the Pit twice without changing it.
    **Expected:** both surveys have the same `contentHash`.

### 5.3 Steps (web app #680)

Built in link L13 (knk-web-app, branch `claude/production-p4c`, PR into `next`). The tags name tests in knk-web-app
`e2e/production-yield.spec.ts` (Playwright, mocked API; the mocks use a quarry with a "Quarry pit" cuboid of 320 of
400 blocks, a shared "North slope" radius and the Mill's "Mill wood" overlapping it, Cobblestone from stone and Coal
from coal ore) and the Jest tests next to the code (`src/utils/__tests__/productionYield.test.ts`,
`src/apiClients/__tests__/productionYieldClients.test.ts`). Extra preconditions: § 5.0 and § 5.1 steps 1-9 (the seeds
imported with "make default", Logger A with its Forest area, a survey, the overrides; Logger B). Log in to the web app as
**Staff** (holds `knk.admin.world` and `knk.admin.content`) unless a step says otherwise. 12 steps: 9 automated, 2
partly (tagged), 1 by hand (step 3); every step can still be run by hand; not run. Full manual run about 40 minutes; the untagged parts
about 15 minutes (the in-game parts wait for the survey runner of #679).

1. [automated: `dashboard › lists the areas with their structure, shape, size and last survey`] Open the dashboard and
   type **ProductionArea**. **Expected:** columns Name, Structure, Model, Shape, Exclusive, Size, Enabled and Last
   survey; Logger A's Forest with `Radius`, "Shared", size 20 and its survey time; an area never surveyed says "Never".
2. [partly automated: `the area form › an area over the level's cap is refused with the maximum (A11, G6)`; by hand: the
   structure picker and a saved area] Open Logger A's page and press **Add area** in the **Yield** panel (the
   ProductionArea form). Pick Logger A, name "Forest 2", Shape Radius, Radius 33, no centre; submit. **Expected:** "The
   form could not be submitted. The area is 33 (radius); level 1 of Logger allows at most 32." Change the radius to 10
   and submit. **Expected:** saved; the area centres on the logger's Location and is listed in the Yield panel as
   "10 of 32 radius". (A11, G6)
3. Area capture in game (by hand): as Admin, in the
   form builder open "ProductionArea - Default (seed v1)" and on the **WorldGuard region** field turn on "Requires
   in-game action" with type `RegionClaim` (the seed has no world task on it yet, see #680). Make an area with Shape
   Region, press the world task button and claim a region in game; fill the bounds (Min/Max X, Y, Z) from the region.
   **Expected:** the region id is filled in from the game and the area saves with its bounding box. The `CaptureRadius`
   world task (stand at the centre, set the radius) comes with #679 and is not in the web app yet. (A10)
4. [automated: `the production structure page › shows the yield source, the areas against the level cap and why each
   rate is what it is (A10, #65)`] View Logger A. **Expected:** below the Production panel a **Yield** panel: "Yield
   source Hybrid." with a sentence on where the rates come from; an **Areas** table (each name links to the area page,
   its shape, "20 of 32 radius", Exclusive or Shared, the last survey); under **Outputs and why each rate is what it is**
   one block per output: Oak log "Surveyed 16/h, Scale × 0.5 → base 8/h." (a primary output adds "then the primary
   multiplier as a modifier") and a link to its line; **Show the survey units** lists area, unit, the matched yield row, count,
   share ("1/2 (shared)" for Logger B's trees), rate per unit, chance and rate per hour; **Surveyed but producing
   nothing** lists `TREE:SPRUCE:LARGE`. (A10, #65)
5. [automated: `the production structure page › the Hybrid override editor pins, changes and removes an override per
   output`] In the Oak log block set **Override** to Pin, leave the value empty (**Save override** stays off), enter 12
   and save. **Expected:** "Override saved: Pin 12/h."; the block says "Pin 12/h → base 12/h". On Birch log (Exclude)
   pick Scale 0.5, save: "Override saved: Scale × 0.5."; pick "None (the survey's rate)" and save: "Override removed.";
   the base is the surveyed rate again. A refused save (a pin of 0) shows the API's reason. (A10)
6. [automated: `the production structure page › pins an output the survey does not yield`] Under **Pin an output the
   survey doesn't yield** search "Apple", keep Pin, enter 5 and press **Add override**. **Expected:** the Apple output
   appears with base 5/h and its line, whatever the survey says. (A10)
7. [automated: `the production structure page › Survey now asks the game server to survey the enabled areas; a refusal
   shows the API's reason`] Press **Survey now**. **Expected:** "Survey requested for 1 area: the game server surveys at
   its next poll."; the area shows "(survey requested)". With every area disabled the button is off; a refusal shows
   the API's sentence (for example "The structure has no enabled area to survey."). With #679 running, a new survey row
   appears once the game server has surveyed. (A10)
8. [automated: `the production structure page › a Configured structure is never surveyed: no Survey now and no outputs
   list (A10, G5)`] View the **Quarry** (`Configured`). **Expected:** "Yield source Configured. … The structure is never
   surveyed."; "A Configured structure is never surveyed, so there is no Survey now (G5)."; no Survey now button and no
   outputs list. (A10, G5)
9. [automated: `an area and its surveys › shows the size against the cap, the plot with its overlaps, the composition,
   the trend and the history`] Open the Forest area. **Expected:** an **Area and surveys** panel: the structure link, the
   model and shape, "20 of 32 radius" with "The level allows at most 32 radius.", Shared; **From above** a plot of the
   circle with Logger B's area dashed and a table of the overlapping areas (each linked); **Latest survey** with its
   composition (unit, count, share of the survey with a bar, "Shared by 2" or "Own"), largest first; **Trend** with per
   unit the first and latest count, the change and a small line; **Survey history** newest first, each linked. (A10)
10. [automated: `an area and its surveys › Survey this area now asks for this area only`] Press **Survey this area now**.
    **Expected:** "Survey requested: the game server surveys the area at its next poll."; only this area is asked for.
11. [automated: `a survey › lists what the game server counted, largest first`] Open a survey from the history.
    **Expected:** a **Composition** panel with the area link, time, trigger, profile version, total units and the
    composition table.
12. [partly automated: `a kind's yield table › edits the yield table and primary outputs; the lists replace the stored
    ones (G17)`; by hand: the survey profile and primary multiplier on the kind's form] View the kind **Logger**.
    **Expected:** a **Yield table** panel with the profile version and primary multiplier and the rows of § 5.1 step 3.
    Press **Add row**, enter unit key `TREE:*:LARGE`: the panel says "Row <n>: a unit key is parts of letters, digits and _
    joined by ":", optionally ending in ":*" (or just "*")." and **Save yield table** stays off. Enter `tree:birch:*`
    (saved in capitals), pick Stick, rate 0.1, chance 0.5. **Add primary output** Oak log; save. **Expected:** "Logger:
    yield table saved."; after the reload the row reads `TREE:BIRCH:*`; Logger A's Yield panel shows the Stick rate
    from the birches too. Edit the kind with its form and change the survey profile: the version goes up by one.

## 6. Phase P5: transport core, simulated (#79 API, #681 plugin, #682 web app; tier:3)

Built so far: link L14, the API (knk-web-api, migration `AddTransportCore`; branch `claude/production-p5`, PR into
`next`). The lane measurer (`/knk logistics lanes measure`, the headless job, road connection updates) is link L15
(#681, § 6.2, built: 14 steps, 3 automated, 10 partly and 1 manual); the order list and detail, the manual order
form and the dry run in the web app are link L16 (#682, § 6.3, built: 16 steps, 10 automated in CI, 5 partly and 1
by hand). § 6.1 runs with a REST client (or Swagger), the web app's pages or both; lanes are measured by the plugin
(or typed in by Staff with the web app's lane form) and the road connection is set by the plugin or with
`PUT api/ProductionStructures/<id>/road-connection`. 20 steps in § 6.1: 18 automated in CI and 2 partly (tagged);
every step can still be run by hand; manual steps not run. Full manual run of § 6.1 about 45 minutes (most of it
waiting for trips, or `POST api/TransportOrders/run-now`); the untagged parts of the partly tagged steps about 10
minutes. The tests are in
knk-web-api `Tests/.../Services/Production/TransportTests.cs`, `TransportLanesAndSettingsTests.cs`,
`Api/TransportControllersTests.cs`, `Migrations/AddTransportCoreTests.cs` and, with `KNK_TEST_MYSQL`,
`MySql/TransportMySqlTests.cs`. The developer waived the smoke gates of L4 and L6 on 2026-11-19; the coordinator reads
that as covering this link too (it builds on L9, whose smoke test is open).

### 6.0 Preconditions

1. knk-web-api with the migrations up to `AddTransportCore` applied (`dotnet ef database update`).
2. Everything of § 4.0, with `Production:Enabled` on except in step 19: the rural quarry **Quarry** in Phoenix (kind
   Quarry, its Cobblestone line, Output storage capped at 100, two workers), a **Staff** token (`knk.admin.world`,
   `knk.admin.content`), a **Visitor** token and the plugin key. Note the ids of Quarry, its Output storage, and the
   blueprints **Cobblestone** and **Coal**.
3. Two rural warehouses of Phoenix: **North** and **South** (`POST api/Warehouses` with `"townId": <Phoenix>`); note
   their ids and their delivery storages (`defaultStorageId`). Cap North's delivery storage at 1,000 units (`PUT
   api/Storages/<id>` with `maxUnits` 1000); South stays uncapped.
4. A second rural producer **Bare quarry** in Phoenix (kind Quarry) with no road: `PUT
   api/ProductionStructures/<Bare quarry>/road-connection` with `{ "roadConnection": "Unconnected" }`.
5. Game setting section `production.transport` at its defaults (`GET api/GameSettings`): `walkingSpeedBlocksPerSecond`
   4.317 (a vanilla player's walk), `defaultCarrierCapacity` 64, `defaultThresholdPercent` 75, `defaultThresholdUnits`
   64, `unmeasuredRouteFactor` 1.4, `fallbackDistanceBlocks` 200, `awaitingSpaceMinutes` 30, `maxReroutes` 2,
   `laneMaxAgeHours` 24.
6. To keep the numbers below exact, pause Quarry's Cobblestone line (`PUT api/ProductionLines/<id>` with `"enabled":
   false`) except in steps 6 and 7, and switch Quarry's automatic transport off (`PUT api/ProductionStructures/<id>`
   with `"automaticTransport": false`) except in steps 8-10. Put stock into an Output storage with `POST
   api/StockTransactions/adjust` (needs `knk.economy.admin`).

### 6.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms and pages in the web app]
   As Staff, import the form and display seeds `TransportOrder` and `TransportLane` with "make default".
   **Expected:** both import; the TransportOrder form is read only (manual orders are made through the API or the
   web app's manual order form, #682); the TransportLane form asks for From, To and the road distance. (A23)
2. [automated: `TransportLanesAndSettingsTests.TheDueList_HasEveryProducerToWarehousePair_AndWarehousePairs_UntilMeasured_ThenStaleAfterTheMaxAge`]
   With the plugin key, `GET api/TransportLanes/due`. **Expected:** the pairs Quarry → North, Quarry → South, Bare
   quarry → North, Bare quarry → South and North → South, each `"reason": "Missing"` with both structures' positions
   (null when a structure has no location). Then `POST api/TransportLanes/report` with `{ "lanes": [ {
   "fromStructureId": <Quarry>, "toStructureId": <North>, "roadDistance": 431.7, "straightDistance": 300,
   "routeEdgeIds": [5, 6, 7] }, { "fromStructureId": <South>, "toStructureId": <Quarry>, "roadDistance": 863.4 }, {
   "fromStructureId": <North>, "toStructureId": <South>, "roadDistance": 215.85 } ] }`. **Expected:** `{ "created": 3,
   "updated": 0 }`; the due list no longer has those three pairs (a lane counts in both directions); `POST
   api/TransportLanes/search` lists them with `source` Plugin.
3. [automated: `TransportLanesAndSettingsTests.LaneValidation`, `TransportControllersTests.Create_400_Cancel_409_And_404s`]
   As Staff, `POST api/TransportLanes` with the Quarry → North pair again. **Expected:** 409 (one lane per direction;
   edit it instead). A lane from a structure to itself, or a reachable lane without `roadDistance`, is 400. A lane
   with `"reachable": false` and no road distance is saved and is never used as a route.
4. [automated: `TransportTests.AManualOrder_MovesSourceToTransitToStop_WithTheLedgerBalancedAtEveryStep_AndTakesRoadLengthOverSpeed`,
   `TransportTests.ADryRun_WritesNothing_AndExplainsThePlan`]
   Put 50 Cobblestone into Quarry's Output storage. `POST api/TransportOrders/dry-run` with `{ "sourceStorageId":
   <Quarry output>, "stops": [ { "storageId": <North delivery>, "lines": [ { "itemBlueprintId": <Cobblestone>,
   "amount": 40 } ] } ] }`. **Expected:** `valid` true, `carrierStructureId` Quarry, `carrierCapacity` 64, one leg of
   431.7 blocks, `distanceSource` Lane, 100 seconds; no order, storage or ledger row is written. (G14)
5. [automated: same as step 4; `GET api/StockTransactions/reconcile` is clean]
   `POST api/TransportOrders` with the same body. **Expected:** 201, status Planned, an event "Created". Then `POST
   api/TransportOrders/run-now`. **Expected:** the order is InTransit; `GET api/TransportOrders/<id>`: `inTransit`
   holds 40 Cobblestone in the order's own transit storage ("Transport #<id> cargo"), Quarry's Output holds 10, North
   0; `etaAt` = `departedAt` + 100 s; events Created, Assigned, Loaded, Departed; Quarry has 1 of 2 workers present.
   After 100 seconds, run-now again. **Expected:** Delivered; North holds 40; the cargo line reads requested 40, loaded
   40, delivered 40; events ArrivedAtStop, Delivered, WorkerReturned, Completed; 2 of 2 workers present. The
   reconciler (`GET api/StockTransactions/reconcile`) is clean after each run, and the ledger shows one TransportLoad
   and one TransportDeliver transaction with source `TransportOrder <id>`. (A12)
6. [automated: `TransportTests.AWorkerCarryingAnOrder_LowersOutputTo50Percent_BothAway_StopIt_AndItRecoversOnReturn`]
   Un-pause Quarry's line, uncap its Output storage, and make the Quarry → North lane 25,900 blocks (an hour and 40
   minutes at walking speed). Create a manual order of 10 Cobblestone to North and run-now. Wait an hour (or set the
   clock) and run `POST api/Production/run-now`; read `GET api/ProductionStructures/<Quarry>/production`. **Expected:**
   1 of 2 workers present; the latest cycle record has worker factor 0.5 and half the output. (A12)
7. [automated: same as step 6]
   Create a second manual order of 10 to South and run-now. **Expected:** 0 of 2 workers present; the next settle has
   worker factor 0 ("All workers are away"). When both orders are Delivered, 2 of 2 are present again and the next
   settle has worker factor 1. Pause the line again and set the lane back to 431.7. (A12)
8. [automated: `TransportTests.TheThreshold_FiresOneAutomaticOrder_SizedByTheWorkersCapacity_ToTheNearestWarehouseByRoad`]
   Switch Quarry's automatic transport on. Put 74 Cobblestone into its Output storage and read `GET
   api/ProductionStructures/<Quarry>/transport`. **Expected:** no trigger reason (threshold 75 of the cap of 100), and
   no order after run-now. Add 6 Coal. **Expected:** the view's trigger reasons say the Output holds 80 units, at or
   over the threshold of 75; `destinationWarehouseId` is North (the nearest by road); `wouldCreate` is a plan of 64
   Cobblestone (the worker's capacity, largest line first). Nothing is written by the view. Run-now. **Expected:** one
   order, origin Automatic, 64 Cobblestone to North. Add 60 more and run-now again: **Expected:** no second order; the
   view's held reasons say "Automatic order #<id> is still under way (one at a time per structure)". (V2 defects 7-9)
9. [automated: `TransportTests.ABlockedFullLine_AndTheDistinctCap_AreTriggersToo`,
   `TransportTests.ThePreferredWarehouse_WinsOverTheNearest_WhenItHasRoom`]
   With Quarry's Output below the threshold: set its line's status to BlockedFull (the engine does this when the
   Output is full), or cap the Output's distinct items at the number it holds. **Expected:** the view lists "Line(s)
   blocked full" or "as many different items as it may" as a trigger. Set Quarry's warehouse preference to Preferred
   with South. **Expected:** `destinationWarehouseId` South. With preference Nearest and North's delivery storage
   capped below the cargo, South is chosen (a warehouse with room comes first).
10. [automated: `TransportTests.AnUnconnectedRuralProducer_HoldsTransport_FillsUp_AndStops_WithBothWarnings`,
    `TransportTests.ADistrictProducer_NeedsNoRoadConnection`]
    Let Bare quarry produce for three hours (`POST api/Production/run-now`) and run the transport sweep. **Expected:**
    its Output holds 100 and its line is BlockedFull; no automatic order; `GET
    api/ProductionStructures/<Bare quarry>/transport` warns "Not connected to its town's road network: automatic
    transport is held (D5)" and "The Output storage is full"; `GET api/ProductionStructures/<Bare quarry>` has both
    warnings too. A rural structure whose road connection is Unmeasured is held the same way. Set its road connection
    to Connected: the next sweep plans its order. A producer in a district needs no road connection. (A13, D5)
11. [automated: `TransportTests.AFullStop_WaitsThenReroutesToAnotherWarehouseOfTheTown`]
    Switch Quarry's automatic transport off again. Cap North's delivery storage at 30 (empty it first). Put 50 into
    Quarry's Output and create a manual order of 50 to North; run-now, wait 100 s, run-now. **Expected:** AwaitingSpace
    ("Stop 1 has no room for 20 unit(s)"); North holds 30, the transit storage 20; nothing is dropped. After 30 minutes
    (`awaitingSpaceMinutes`) and a run-now: **Expected:** Rerouted to South with a new stop of 20 (stop 1 Partial),
    InTransit with a 50-second leg (North → South 215.85 blocks). After it: Delivered, South holds 20, the reconciler
    is clean. (V2 defect 2)
12. [automated: `TransportTests.WithNowhereToGo_TheCargoComesBack_AndAFullSourceBlocksTheReturnUntilItHasRoom`]
    Repeat step 11 with South's `acceptsDeliveries` off. **Expected:** after the wait the carrier carries on and,
    with no stop left, turns back: Returning with a 100-second leg. Fill Quarry's Output to 95 before it arrives.
    **Expected:** ReturnBlocked: 5 go back, 15 stay in the transit storage (never dropped). Take 50 out of the Output
    and run-now. **Expected:** Returned; the cargo line reads loaded 50, delivered 30, returned 20; 2 of 2 workers
    present; the reconciler is clean. (V2 defect 2)
13. [automated: `TransportTests.EachStopGetsItsOwnPlannedAmounts_AndAShortLoadServesTheFirstStopsFirst`]
    Put 25 into Quarry's Output and create an order with two stops: 20 to North, then 10 to South. Run-now.
    **Expected:** loaded 25 (the source held less than asked); the stops' planned amounts are 20 and 5. After each
    arrival North gets 20 and South 5, never more. (V2 defect 3)
14. [automated: `TransportTests.CancelWhilePlanned_EndsCancelled_WithoutStockMoves`,
    `TransportTests.NothingToLoad_CancelsTheOrder_AndTheWorkerStays`]
    Create an order with `"executeAfter"` an hour ahead and `POST api/TransportOrders/<id>/cancel` with `{ "reason":
    "test" }`. **Expected:** Cancelled with the reason; no stock moved; a second cancel is 409. An order whose source
    holds none of the cargo ends Cancelled at loading ("Nothing to load"), the worker never leaves.
15. [automated: `TransportTests.CancelInTransit_TurnsBack_TakingAsLongAsItWalked_AndReturnsEverything`,
    `TransportTests.CancelWhileAwaitingSpace_ReturnsTheRest_FromTheStop`]
    Create an order of 10 to North, run-now, wait 30 seconds and cancel it. **Expected:** Returning, back in 30 seconds
    (the way it came); cancel again is 409 "already returning"; after it: Returned with "Cancelled: the cargo is back
    in the source", the Output holds its 10 again, 2 of 2 workers present, the reconciler is clean. An order cancelled
    while AwaitingSpace brings back what it could not deliver over the lane. (A12)
16. [automated: `TransportTests.ARestartMidTransit_ContinuesWhereItWas_WithoutMovingAnythingTwice`]
    Create an order of 10 to North, run-now, and restart the API while it is in transit; wait an hour and run-now.
    **Expected:** Delivered once (North 10, the Output 10), exactly one TransportLoad and one TransportDeliver
    transaction for the order.
17. [automated: `TransportTests.InvalidManualOrders_AreRefusedWithTheirReasons`, `TransportTests.AWorkerCarriesAtMostItsCapacity`,
    `TransportTests.AFromAWarehouse_IsCarriedWithoutAWorker_AndARepeatedClientKeyMakesOneOrder`]
    Try manual orders: no stop; a stop that is the source or a system storage; an amount of 0; an unknown blueprint;
    origin Automatic; 65 units with Quarry as carrier. **Expected:** each is 400 with its reason ("carries at most
    64" for the last). An order from North's delivery storage to South with `"origin": "Quest"` and `"clientKey":
    "quest-42"`, sent twice: **Expected:** one order; it is carried without a worker (no production structure holds
    the source); it is delivered after 50 seconds.
18. [automated: `TransportTests.WithoutALane_TheRouteIsTheStraightDistanceTimesTheFactor_AndWithoutPositionsTheFallback`,
    `TransportTests.ALaneIsReadInBothDirections_AndAnUnreachableLaneIsNotARoute`]
    Dry-run an order between two structures without a lane. **Expected:** without locations the leg is the fallback
    200 blocks ("Fallback"); with both locations 500 blocks apart it is 700 blocks ("Estimated", × 1.4), with a
    warning "no measured lane". (G14)
19. [automated: `TransportTests.WithTheFlagOff_NothingMoves_ButManualOrdersAndCancelWork`,
    `TransportControllersTests.RunNow_Is409WhileOff_And200WhileOn`]
    Switch `Production:Enabled` off. **Expected:** `POST api/TransportOrders/run-now` is 409; the background sweep
    makes no automatic order and moves no order (a Planned one stays Planned); `GET api/TransportLanes/due` is empty;
    manual orders, dry runs, lanes and cancel still work. Switch it back on. (A21)
20. [partly automated: `ReadAccessRulesTests`, `EndpointAccessRulesTests`, `DashboardChangeAccessRulesTests`,
    `DeleteAccessRulesTests` (the rules are pinned); by hand: the calls below]
    As Visitor, `POST api/TransportOrders`, `POST api/TransportOrders/<id>/cancel`, `POST api/TransportLanes/report`
    and `GET api/TransportOrders/<id>`. **Expected:** 403 for each (writes need `knk.admin.world` or the plugin key,
    reads the World area); with the plugin key `GET api/TransportLanes/due` and `POST api/TransportLanes/report` work.

### 6.2 Steps (plugin #681)

Built by link L15 (knk-plugin branch `claude/production-p5b`, PR into `next`). Everything runs only with
`production.enabled: true`; the new keys are `production.logistics.lanes.*` (plugin configuration § 4.31, YAML in the
changelog). The plugin measures lanes with the road router over the navigation road snapshot (read-only) and sets the
road connections the API holds automatic transport by (D5). Extra preconditions:

1. The plugin build from `next` on a test server, connected to the API of § 6.0 with the plugin key
   (`api.auth.api-key` = the API's `Security:PluginApiKey`). The `production` block merged with its `logistics` keys,
   with `interval-minutes: 0` (only on the command) and `enabled: false` at first. API `Production:Enabled` on.
2. The world's road network built and loaded on the server (navigation admin guide; `/knk road reload`), with one
   connected network that passes within 20 blocks of **Quarry**, **North** and **South**. **Bare quarry** stands more
   than 48 blocks from any road. Each of the four structures has a Location (the web app's structure form, or `PUT
   api/ProductionStructures/<id>` / `PUT api/Warehouses/<id>` with a location). Note how far apart they are by road:
   `/navigate` from Quarry to North shows the road length.
3. No lanes of these structures yet: delete the three lanes typed in at § 6.1 step 2 (`DELETE api/TransportLanes/<id>`
   as Staff, ids from `POST api/TransportLanes/search`), so `GET api/TransportLanes/due` lists the five pairs again.
4. In game: **Staff** with `knk.admin.world.production` (in `knk.admin.*` and `knk.admin.world.*`), and a player
   **Visitor** without it.
5. For step 12: `metrics.enabled: true` and its port reachable (performance metrics guide).

Full manual run about 40 minutes; the untagged and partly tagged parts about 20 minutes. The tests are in knk-plugin
`knk-core/.../production/transport/` (`LaneMeasurerTest` over a built road network, `LaneJobTest` with a fake API,
`RoadConnectionBookTest`), `knk-api-client/.../TransportLanesApiImplTest`, `knk-paper/.../production/LaneConfigTest`
and `knk-paper/.../commands/LogisticsAdminCommandTest` (MockBukkit). No plugin scenario: measuring reads only the road
snapshot and the API, no blocks or entities, so the in-game steps below are the real-server check.

1. [partly automated: knk-plugin `LogisticsAdminCommandTest.offWithoutProductionEnabled`, `LaneConfigTest`; by hand:
   the log] With `production.enabled: false`, start the server and as Staff type `/knk logistics lanes measure`.
   **Expected:** "Production is off on this server (production.enabled: false)."; the log has no "Lane measurer is on"
   line and the API's access log shows no `TransportLanes/due` reads. (A21)
2. [partly automated: `LaneConfigTest.theValuesAreRead_andClamped`; by hand: the log] Set `production.enabled: true`,
   restart. **Expected:** the log line `Lane measurer is on (production.enabled): only on /knk logistics lanes measure,
   100 pairs per run, road connections on.`; no lane is read until the command.
3. [partly automated: `LaneJobTest.aRun_reportsEveryMeasuredPair_skipsTheUnmeasurable_andSetsTheProducersRoadConnection`,
   `LogisticsAdminCommandTest.measureRunsNow_reportsTheLanes_andTellsTheSenderTheResult_A13`; by hand: in game] As
   Staff, `/knk logistics lanes measure`. **Expected:** "Reading the lane list and measuring over the road
   network...", then within a few seconds a yellow line "Lanes (command by Staff, … s ago): 5 due, 3 reachable, 2
   without a road, 0 skipped; API created 5, updated 0; road connections sent 2", lines per pair ("#<Quarry> Quarry →
   #<North> North: <n> blocks by road", "#<Bare quarry> Bare quarry → #<North> North: no road (#<Bare quarry> is more
   than 48 blocks from a road)"), and "Structure #<Quarry> is now Connected" and "Structure #<Bare quarry> is now
   Unconnected: its automatic transport is held". North and South get no road connection of their own (warehouses;
   the API answers 404 and the plugin stops asking). The server log has the same summary under `[Lanes]`. (A12, A13)
4. [partly automated: `LaneMeasurerTest.aReachableLane_isTheWalkToTheRoad_theRoadRoute_andTheWalkFromIt_withItsEdgesInOrder`,
   `TransportLanesApiImplTest.report_sendsReachableLanesWithTheirRoadDistance_andUnreachableOnesWithout`; by hand: the
   API] As Staff, `POST api/TransportLanes/search`. **Expected:** five lanes with `source` Plugin and `measuredAt` now.
   Quarry → North is `reachable` with a `roadDistance` close to the `/navigate` length of precondition 2 plus the few
   blocks between each structure's location and the road, never less than its `straightDistance`, and lists its
   `routeEdgeIds`. Both Bare quarry lanes are not reachable and have no road distance. `GET api/TransportLanes/due` is
   empty. (A12)
5. [partly automated: knk-web-api `TransportTests.AManualOrder_MovesSourceToTransitToStop_WithTheLedgerBalancedAtEveryStep_AndTakesRoadLengthOverSpeed`;
   by hand: the dry run] `POST api/TransportOrders/dry-run` from Quarry's Output to North's delivery storage (§ 6.1 step
   4). **Expected:** one leg with `distanceSource` Lane, its distance the measured road distance, and its seconds that
   distance ÷ 4.317; no "no measured lane" warning. (A12)
6. [partly automated: knk-web-api `TransportTests.AnUnconnectedRuralProducer_HoldsTransport_FillsUp_AndStops_WithBothWarnings`;
   by hand: the API] `GET api/ProductionStructures/<Bare quarry>/transport`. **Expected:** `roadConnection`
   Unconnected and the warning "Not connected to its town's road network: automatic transport is held (D5)". Quarry
   reads Connected and has no such warning. (A13)
7. [partly automated: `RoadConnectionBookTest.oneReachableLaneConnects_everyLaneUnreachableDisconnects_noLaneIsNotJudged`;
   by hand: in game] Build a road from the network to within 20 blocks of Bare quarry and let the road network pick it
   up (`/knk road reload`). Delete Bare quarry's two lanes (`DELETE api/TransportLanes/<id>`), then `/knk logistics
   lanes measure`. **Expected:** "2 due, 2 reachable, 0 without a road"; "Structure #<Bare quarry> is now Connected";
   its transport view no longer warns, and the next transport sweep may plan its automatic order (§ 6.1 step 10).
   (A13, D5)
8. [automated: `LaneJobTest.anUnchangedConnection_isNotSentAgain_andAWarehouseIsAskedOnlyOnce`, `LaneJobTest.oneRunAtATime_aSecondCallGetsTheRunningOne`]
   Type `/knk logistics lanes measure` twice quickly. **Expected:** the second answers "A lane run is already going;
   you'll hear its result."; with nothing due: "0 due …" and "Nothing due: every lane is measured and fresh (or the
   API's production flag is off)."; no road connection is sent again.
9. [automated: `LogisticsAdminCommandTest.statusBeforeAnyRun_andTheUsageAndCompletion`, `LogisticsAdminCommandTest.measureRunsNow_reportsTheLanes_andTellsTheSenderTheResult_A13`]
   `/knk logistics lanes status`. **Expected:** "Lane measurer: only on /knk logistics lanes measure, 100 pairs per run;
   lanes known since start: 5" and the last run's summary. Tab completion offers `lanes`, then `measure` and `status`.
10. [partly automated: `LaneConfigTest`; by hand: the log, about 5 minutes] Set `interval-minutes: 1` and restart.
    Delete Quarry → South's lane. **Expected:** about two minutes after start, and then every minute, the log has
    `[Lanes] Run (schedule): …`; the first scheduled run measures and reports Quarry → South again ("1 due, 1
    reachable"). Set it back to 60.
11. [automated: `LaneMeasurerTest.noPosition_orNoRoadNetworkLoaded_isSkipped_neverReportedAsNoRoad`,
    `LaneMeasurerTest.differentWorlds_areUnreachable_withoutAStraightDistance`, `LaneMeasurerTest.roadsThatDoNotJoin_areUnreachable`]
    Optional by hand: a structure without a Location, or in a world without a road network, is skipped ("skipped, #<id>
    has no location" / "no road network loaded for world …"), stays due and keeps its road connection; a warehouse in
    another world is a lane without a road.
12. [manual] With `metrics.enabled: true`, run step 3's measure again after deleting the lanes. **Expected:** the
    metrics have `knk_task_duration_seconds` for `task="production.lanes.measure"`; the server's tick time does not
    move (measuring runs on the `KnK-lanes` thread; the main thread only starts the run and prints the answer).
13. [partly automated: `LogisticsAdminCommandTest.metadataGatesOnTheProductionNode`; by hand: in game] As Visitor,
    `/knk logistics lanes measure`. **Expected:** refused for lack of permission; nothing is read or sent.
14. [partly automated: knk-plugin `SurveyCounterTest.anOverlapSharesOnlyTheUnitTypesItsStructureCounts_875`,
    `ProductionSurveyApiImplTest.surveyDue_readsEachOverlapsUnitTypes_fromUnitTypesOrItsProfile_875`; by hand once
    the API sends the overlaps' unit types (#875)] With § 5.2's **Farm** area overlapping **North logger**'s radius,
    `/knk production survey <Farm>`. **Expected:** the farm's crops inside the logger's radius are reported with
    `sharedBy` 1 (the logger counts no crops); trees inside it would be `sharedBy` 2. Before the API sends the unit
    types, the crops read `sharedBy` 2 as in § 5.2.

### 6.3 Steps (web app #682)

Built in link L16 (knk-web-app, branch `claude/production-p5c`, PR into `next`). The tags name tests in knk-web-app
`e2e/transport.spec.ts` (Playwright, mocked API; the mocks use the Quarry with its Output storage, the warehouses North
and South with their delivery storages, order 701 on the road to North over a measured lane, order 702 delivered to both
and order 703 waiting for room at South) and the Jest tests next to the code (`src/utils/__tests__/transport.test.ts`,
`src/apiClients/__tests__/transportClients.test.ts`). Extra preconditions: § 6.0 and § 6.1 steps 1-15 (the seeds
imported with "make default", the lanes reported, orders made, delivered, re-routed, returned and cancelled), so the
lists below have real rows. Log in to the web app as **Staff** (holds `knk.admin.world` and `knk.admin.content`) unless a
step says otherwise. 16 steps: 10 automated, 5 partly (tagged), 1 by hand (step 16); every step can still be run by hand;
not run. Full manual run about 40 minutes; the untagged parts about 15 minutes (most of it waiting for a trip, or
`POST api/TransportOrders/run-now`).

1. [automated: `the order list › lists the orders newest first with status in words, route and units, each linking to
   its page (A12)`] In the admin sidebar (group World) open **Transport orders** (`/admin/transport/orders`).
   **Expected:** a table with Order, Status, Origin, From, To, Units, Created and ETA, newest first; statuses in words
   ("On the road", "Waiting for room", "Delivered"), a waiting order with its reason under the status, To as the stops
   joined with " → ", Units as "20 of 20 delivered" (plus "returned" when some came back); each order number links to
   the order's page; a **New manual order** button. (A12)
2. [automated: `the order list › filters by open, status, origin, structure and storage through the URL`] Pick Open or
   final "Open", Status "Waiting for room", Origin "Automatic", type Quarry's Output storage id in **Storage id** and
   press **Apply filters**. **Expected:** the URL carries the filters (a reload keeps them) and only matching orders are
   listed; **Clear** lists everything again. Open `/admin/transport/orders?structureId=<Quarry>`: only Quarry's orders
   (source, stop or carrier).
3. [partly automated: `an order › shows the status, cargo, the route with distance sources and the timeline oldest first
   (A12)`; by hand: compare with the API] Open the order of § 6.1 step 4 (delivered to North). **Expected:** below the
   details a **Transport** panel: the status in words; From (the source storage, linked, at its structure); Carried by
   ("A worker of Quarry, up to 64 units" or "A simulated carrier"); the cargo storage; created, runs after, departed
   and completed times; a **Cargo** table per blueprint (requested, loaded, delivered, returned, lost); "On the road
   now: nothing"; a **Route** with each stop (its storage linked, its status, "431.7 blocks (measured lane)", arrived
   or ETA, delivered of planned per blueprint); **Carriers** (mode, workers, speed, capacity, assigned and back); a
   **Timeline** oldest first (Created, Carrier assigned, Loaded, Departed, Arrived at a stop, Delivered, Worker back,
   Completed), each with its message, the stop and a link to its stock transaction. By hand: the timeline matches the
   order's `events` in `GET api/TransportOrders/<id>`, and each transaction link opens the move. (A12)
4. [automated: `an order › an estimated leg, a re-route and a wait are shown in words; a final order has no Cancel`]
   Open the re-routed order of § 6.1 step 11 while it waits. **Expected:** "Waiting for room" with its reason and the
   waiting time; the first stop Skipped, the next one "re-routed from <first stop>"; a leg without a lane says
   "(estimated (straight line × factor))", one without positions "(fallback distance)"; Re-routes 1. Open a delivered
   order: **Expected:** no Cancel button.
5. [automated: `an order › Cancel says what happens, sends the reason and shows the API's refusal`] Make an order with
   `executeAfter` an hour ahead (step 6) and open it; press **Cancel the order**. **Expected:** "Nothing is loaded yet:
   the order ends Cancelled."; type a reason and press **Cancel the order now**: the status becomes Cancelled, the
   timeline gets "Cancel requested" and "Cancelled" with the reason, the button is gone. On an order on the road the
   sentence is "The cargo is loaded: the carrier turns back and the order ends Returned." and the status becomes
   Returning. A refusal (409, e.g. already returning) shows the API's sentence.
6. [partly automated: `the manual order page › fills the source and carrier from a structure page, dry-runs first, then
   makes the order once (G17)`; by hand: the made order] Put 40 Cobblestone into Quarry's Output storage. Open Quarry's
   page and press **New order from here** in the Transport panel. **Expected:** the **New transport order** page with
   Source storage "Quarry - output" and Carrier "Quarry" filled in; Make the order is off and the problems list says
   "Stop 1: pick its storage.". As stop 1 pick South's delivery storage, item Cobblestone, amount 64, and press **Dry
   run**. **Expected:** a **Dry run** section: "The order can be made.", the warnings (only 40 of 64 at the source;
   an estimated route if no lane), the carrier with workers present, capacity and speed, cargo 64 units with the trip
   time, a cargo table ("40 (short)") and a legs table (South's storage, distance with its source, time, the drops, the
   room). Type a note: Make the order is off again until the next **Dry run**; then press **Make the order**.
   **Expected:** "Transport order #<n> made." and the order's page opens; by hand: it is Manual with the note, and a
   double click made one order (the request carries a `clientKey`).
7. [automated: `the manual order page › a plan with errors can't be made, and the API's refusal of a create is shown`]
   Empty Quarry's Output storage and dry-run the same order. **Expected:** "The order can't be made." with the API's
   errors (no Cobblestone at the source); Make the order stays off. If the stock goes away between the dry run and the
   create, the API's refusal sentence is shown on the page.
8. [automated: `the manual order page › two stops with two items each are sent in visiting order`] Make an order with
   stop 1 South (64 Cobblestone, 4 Coal; **Add an item to stop 1**) and stop 2 North (10 Cobblestone; **Add a stop**),
   then dry-run. **Expected:** the plan has two legs in that order, each with its own drops (no V2 defect 3);
   **Remove stop 2** and **Remove item 2** take them out again. The source storage can't be a stop, and one storage
   can't be two stops (the problems list says so).
9. [automated: `a production structure's transport › shows the missing road and the full Output as warnings and why
   the trigger is held (A13)`] Open **Bare quarry** (unconnected, § 6.0 precondition 4) once its Output is full.
   **Expected:** below the Yield panel a **Transport** panel: **Transport warnings** with the missing road (D5) and the
   full Output storage; Automatic transport On; Road connection Unconnected; Output "100 / 100 units" (linked); Trigger
   at 75 units; "A worker carries 64 units"; Workers "2 of 2 present, 0 away carrying"; Goes to the warehouse it would
   use; under **Automatic trigger now** why it would send an order and why it is held (no road connection); Open orders;
   "All orders of this structure" (the order list filtered by the structure) and "New order from here"; a **Lanes**
   table. (A13)
10. [automated: `a production structure's transport › shows the order the trigger would make now`] Open **Quarry**
    with its automatic transport on, Output over the threshold and a free worker (do not run the sweep).
    **Expected:** no warnings; under Automatic trigger now the reason and **The order the trigger would make** (the
    plan as in step 6: the units sized by the worker's capacity, the nearest or preferred warehouse, the trip time).
    As a staff member without `knk.admin.world`: no "New order from here" and no "Add a lane".
11. [partly automated: `dashboard › lists the orders with status in words and the lanes with their distances (A23)`;
    by hand: the lane form] Open the dashboard and type **TransportLane**. **Expected:** columns From, To, Road
    distance, Straight, Source and Measured; the lanes of § 6.1 step 2 with Source Plugin ("Unreachable" for an
    unreachable one). Press Create (the seeded TransportLane form): From Bare quarry, To North, road distance 500;
    save. **Expected:** listed with Source Manual and in Bare quarry's Lanes table; the same pair again is refused
    (409, one lane per direction); edit and delete it (delete needs `knk.admin.delete`). Type **TransportOrder**:
    **Expected:** the orders with status in words and "20 of 20" delivered; no Create button and no edit or delete
    (orders are made on the manual order page). (A23)
12. [automated: `dashboard › lists production structures with their kind's name (#838)`] Type **ProductionStructure**
    on the dashboard. **Expected:** a **Kind** column with each structure's kind name.
13. [automated: `the production page's cycles (#838) › names the blueprints a cycle consumed and links to all cycle
    records`] On a production structure whose line takes inputs (§ 4.1), open a cycle's trace in **Latest cycles**.
    **Expected:** the inputs by blueprint name ("3 × Wheat"), not by id; **All cycle records** opens the
    ProductionCycleRecord list on the dashboard.
14. [automated: `game settings › shows and keeps the transport section on a save of another section, and saves a
    changed one`; Jest `territory.test.ts › keeps the transport settings, so a save does not reset them (#682)`] Open
    **Game settings**. **Expected:** a **Transport** card with walking speed, carrier capacity, trigger threshold (%),
    trigger for uncapped Output, unmeasured route factor, fallback distance, wait at a full stop, re-routes per order
    and lane max age, with the stored values (§ 6.0 precondition 5). Change the production engine's base cycle and
    save: the transport values are sent back unchanged. Type 11 re-routes: "production.transport.maxReroutes must be a
    whole number between 0 and 10." and Save is off; type 3 and save: `GET api/GameSettings` has 3.
15. [partly automated: `game settings › Run transport now reports the sweep, and the API's 409 while production is
    off`; by hand: production off] With production on press **Run transport now** in the Transport card.
    **Expected:** "<n> orders created, <m> moved on." (and "<k> failed" when some failed). Turn production off and
    save: the button is off with "Production is off: no order moves". A refusal of the run (403 without
    `knk.admin.world`, 409 while production is off) shows the API's sentence in the card.
16. End to end (by hand): with production on, Quarry connected, its automatic transport on and its Cobblestone line
    running, wait until its Output passes the threshold (or put stock in), press **Run transport now** and open
    Quarry. **Expected:** the new order under Open orders, Workers "1 of 2 present, 1 away carrying"; its page shows
    Carrier assigned, Loaded, Departed on the timeline and an ETA; after the trip (run the sweep again past the ETA)
    Arrived at a stop, Delivered, Worker back and Completed, the cargo delivered at the warehouse's storage and the
    worker present again. (A12)

## 7. Phase P6: terminals, displays, menus, commands (#683 API, #74 plugin; tier:2)

Built so far: link L17, the API (knk-web-api, migration `AddStorageContainers`), and link L18, the game server part
(knk-plugin branch `claude/production-p6`: `/knk storage bind`, the terminal and display views, the Structures menus and
their buttons; § 7.2). § 7.1 runs with a REST client (or Swagger) against the API, sending what the
game server will send: the plugin key and, for a player, `X-Acting-User-Id: <user id>`. 20 steps in § 7.1: 15 automated
in CI, 4 partly and 1 by hand (tagged); every step can still be run by hand; not run. § 7.2 is the plugin part. Full
manual run of § 7.1 about 30 minutes; the untagged parts about 10 minutes. The tests are in knk-web-api
`Tests/.../Services/Production/TerminalsAndMenusTests.cs` (`TerminalsAndMenusTests`, `ProductionAreaRegionBoundsTests`),
`Services/MenuTemplateProductionSeedTests.cs` and `Migrations/AddStorageContainersTests.cs`. Tier:2; the developer's
waiver of the smoke gates (2026-11-19) is read by the coordinator as covering the later links.

### 7.0 Preconditions

1. knk-web-api with the migrations up to `AddStorageContainers` applied (`dotnet ef database update`), restarted once
   (the production menus and the main menu's "Structures" tile are seeded at startup).
2. Everything of § 6.0: the rural quarry **Quarry** in Phoenix with its Output storage, the warehouses **North** and
   **South** with their delivery storages, the blueprints **Cobblestone** and **Coal**, `Production:Enabled` on except
   in step 8 and 14.
3. Accounts: **Staff** (`knk.admin.world`, `knk.admin.content`), **Member** (no staff node; give it
   `knk.town.member.<Phoenix id>`, the town membership until town roles, #246) and **Visitor** (nothing). Note their
   user ids. The game server's calls are the plugin key (`X-API-Key`) with `X-Acting-User-Id` naming the player.
4. North's delivery storage: `PUT api/Storages/<id>` with `unitsPerSlot` 200 and no cap.

### 7.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms in the web app]
   As Staff, import the form and display seeds `StorageContainer`, and the form seeds `StockTransaction` (seed v2) and
   `ProductionArea` (seed v2), each with "make default". **Expected:** all import; the StorageContainer form asks for
   the storage and the mode, then the world, the block position, the block type and "Double chest". (A23)
2. [automated: `TerminalsAndMenusTests.BindingContainers_SetsTheCapToSlotsTimesUnitsPerSlot_AndUnbindingTheLastKeepsIt`]
   As Staff, `POST api/StorageContainers` with `{ "storageId": <North delivery>, "mode": "Terminal", "containerType":
   "Chest", "isDouble": true, "worldName": "world", "x": 1, "y": 64, "z": 0 }`. **Expected:** 201, `slots` 54,
   `storageContainerSlots` 54, `storageMaxUnits` 10800 (54 × 200). Bind a barrel at x 3 as a Display. **Expected:** North's
   delivery storage is capped at 16200. Delete the barrel: 10800 again; delete the chest too: the cap stays 10800 (a
   fixed cap again, nothing trimmed). Bind the chest again and set the storage's `unitsPerSlot` to 300: the cap becomes
   54 × 300 = 16200. A storage without `unitsPerSlot` keeps its own cap when a chest is bound. (DESIGN § 4.4)
3. [automated: `TerminalsAndMenusTests.Binding_RefusesSystemStorages_ATakenBlock_AndADoubleBarrel`]
   Bind a container to a system storage (`SYS_WORLD`), a second container on the same block, and a double barrel.
   **Expected:** 400, 409 ("That block is already bound"), 400. `GET api/StorageContainers/by-block?world=world&x=1&y=64&z=0`
   returns the chest; an unbound block is 404.
4. [automated: `TerminalsAndMenusTests.ATerminal_PutsAndTakesThroughTheLedger_OnceperKey_ForMembersAndStaffOnly`]
   With the plugin key and `X-Acting-User-Id: <Member>`, `POST api/StorageContainers/<chest>/put` with `{
   "itemBlueprintId": <Cobblestone>, "amount": 10, "idempotencyKey": "click-1" }`, twice. **Expected:** the first is
   Applied, the second `replayed` true; North holds 10. Then `POST .../take` with 4 and key "click-2" as Staff.
   **Expected:** North holds 6; the ledger has one Deposit (actor Member) and one Withdraw (actor Staff) transaction with
   source `StorageContainer <chest id>`, `SYS_WORLD` on the other side; the reconciler is clean. `GET
   .../<chest>/terminal` as Member: one entry, Cobblestone 6. (A14)
5. [automated: `TerminalsAndMenusTests.ATerminalTake_OfMoreThanThereIs_MovesWhatThereIs_AndADisplayIsNoTerminal`]
   Take 5 when the storage holds 3. **Expected:** `accepted` 3, the line rejects 2 with `NotEnoughStock`. A put without
   `idempotencyKey` is 400; `GET .../<display>/terminal` is 409 (a display is no terminal).
6. [partly automated: `TerminalsAndMenusTests.ATerminal_PutsAndTakesThroughTheLedger_OnceperKey_ForMembersAndStaffOnly`
   (the viewer check); by hand: the 400]
   As Visitor (`X-Acting-User-Id: <Visitor>`), `GET .../<chest>/terminal` and `POST .../take`. **Expected:** 403 for
   both, nothing moves. A put or take without `X-Acting-User-Id` is 400 `ActingUserRequired`; a web user's token on
   these routes is 403 (game server only).
7. [automated: `TerminalsAndMenusTests.ADisplay_ShowsASampleProportionalToTheFillLevel`]
   Cap North's delivery storage at 1000 (unbind the chest first, or set `unitsPerSlot` back to none), put 300
   Cobblestone and 200 Coal into it, bind a Display chest and `GET api/StorageContainers/<display>/display` with the
   plugin key. **Expected:** `fillRatio` 0.5, `filledSlots` 14 of 27, items Cobblestone 8 stacks and Coal 6. An empty
   storage's display: `fillRatio` 0, no items. (A14)
8. [automated: `TerminalsAndMenusTests.WithTheFlagOff_TerminalsMoveNothing_ButBindingAndReadsWork`]
   Switch `Production:Enabled` off. **Expected:** put and take are 409 `ProductionDisabled`; binding, the terminal view
   and the display still work. Switch it back on. (A21)
9. [automated: `TerminalsAndMenusTests.TheOverview_ListsProducersAndWarehouses_WithStatuses_AndFilters`,
   `TerminalsAndMenusTests.ThePublicStatus`]
   As Visitor, `POST api/StructureMenus/search` with `{ "pageSize": 50 }`. **Expected:** one row per production
   structure and warehouse: name, `structureType`, `kindName` ("Warehouse" for a warehouse), town, level, `products`,
   `status` and `statusText`. A rural producer that is not Connected is `NoRoad`; one with a line blocked full is
   `Full`; switched off, without a running line or with no worker present is `Stalled`. Filters `townId`,
   `structureType`, `status` and `productionKindId` and the search term narrow the list (Rivertown: none). (A24, API
   side)
10. [automated: `TerminalsAndMenusTests.AVisitor_GetsOnlyThePublicFields_AndTheResponseHoldsNoStockRatesWorkersOrOrders`]
    Put 40 into Quarry's Output. As Visitor, `GET api/StructureMenus/<Quarry>`. **Expected:** name, kind, town, level,
    products and status; `viewerSeesDetails` false and `detail` null: the body holds no stock, rates, workers or
    orders. `GET api/StructureMenus/<Quarry>/orders` is 403. The game server without `X-Acting-User-Id` gets the same
    public view. (A25)
11. [automated: `TerminalsAndMenusTests.MembersAndStaff_SeeRatesStorageWorkersWarningsAndOrders_OnlyStaffAreStaff`]
    Make a manual order of 10 from Quarry to North. As Member, then as Staff, `GET api/StructureMenus/<Quarry>`.
    **Expected:** `viewerSeesDetails` true, `detail` with 2 of 2 workers present and 0 away, the Cobblestone rate, the
    Output storage with Cobblestone 40, the warnings and `openOrderCount` 1; `viewerIsStaff` is false for Member and
    true for Staff. `GET .../orders` lists the order, newest first. North's menu lists its delivery storage and the
    order bound for it. (A26)
12. [automated: same as step 11]
    As Member, look for anything in the responses that changes something. **Expected:** none: the menu routes are
    reads; the staff buttons call the staff routes (step 13-15), which need `knk.admin.world` (403 for Member). (A26)
13. [automated: `TerminalsAndMenusTests.Retry_RunsAWaitingOrderNow_AndSendsACancelledOneAgainOnce`]
    As Staff, make a manual order with `executeAfter` an hour ahead and `POST api/TransportOrders/<id>/retry`.
    **Expected:** the order runs now (InTransit, event "Retried now by user <Staff>"); a second retry is 409 (on the
    road). Cancel another order and retry it twice. **Expected:** one new manual order with the same stops and amounts
    ("Retry of transport #<id>", client key `retry-of-<id>`), the same one both times. A delivered order's retry is 409.
    (M4)
14. [automated: `TerminalsAndMenusTests.Retry_Is409WhileTheFlagIsOff`]
    With `Production:Enabled` off, retry is 409 ("Production is switched off"). (A21)
15. [by hand]
    As Staff, the other staff buttons' routes: `POST api/ProductionStructures/<Quarry>/survey` (survey now, P4), `GET
    api/ProductionStructures/<Quarry>/transport` (the transport dry run, P5) and `POST api/TransportOrders/<id>/cancel`.
    **Expected:** each answers as in § 5.1 and § 6.1; as Member each is 403. (A26)
16. [automated: `MenuTemplateProductionSeedTests` (all)]
    On a fresh database, start the API and `GET api/MenuTemplates` (or open the menu editor). **Expected:**
    `structures.overview` (searchable, facets Town, Kind and Status, rows open `structures.structure` with
    `ctx.structureId`), `structures.structure` (details header; Productions, Workers, Warnings and Transport orders
    shown only when `structure.getSeesDetails` is true; Storages list; a Staff row behind `knk.admin.world` with survey
    now, dry run and area outline) and `structures.orders` (staff cancel or retry with a confirm); the main menu has the
    "Structures" tile in slot 18. On a database seeded before, a restart adds the tile once. (A27)
17. [automated: `ProductionAreaRegionBoundsTests.ARegionArea_WithoutBounds_TakesThemFromTheRegionOutline`,
    `FormConfigurationSeedFilesTests`]
    With the game server's outline of a region `pit_region` stored (`map_region_outlines`), `POST api/ProductionAreas`
    with shape Region, `wgRegionId` "Pit_Region" and no bounds. **Expected:** the bounds are the region's (x and z from
    its points, y from its height) and the size follows; a region without an outline still needs the bounds (400). The
    ProductionArea form seed v2 has "Send to Minecraft" on the region (RegionClaim) and the radius (CaptureRadius, a
    known world task type now). (#877)
18. [automated: `ProductionAreaRegionBoundsTests.TheStructureList_HasTheYieldSource`]
    `POST api/ProductionStructures/search`. **Expected:** each row has `yieldSource` (Configured, Derived or Hybrid).
    (#877)
19. [partly automated: `FormConfigurationSeedFilesTests`; by hand: open a transaction in the web app]
    Open a ledger transaction with reason Upgrade in the StockTransaction form (seed v2). **Expected:** the Reason shows
    Upgrade. (#881)
20. [partly automated: `ReadAccessRulesTests`, `EndpointAccessRulesTests`, `DashboardChangeAccessRulesTests`,
    `DeleteAccessRulesTests` (the rules are pinned); by hand: the calls below]
    As Visitor with a web token, `POST api/StorageContainers` and `DELETE api/StorageContainers/<id>`. **Expected:** 403
    (writes need `knk.admin.world`, delete also `knk.admin.delete`). `POST api/StructureMenus/search` without any token
    is 401.

### 7.2 Steps (plugin, #74)

Built by link L18 (knk-plugin branch `claude/production-p6`, PR into `next`): `/knk storage bind|unbind|info|reload`,
storage terminals and display containers, the Structures tile, the structure menu and the transport orders list with
the staff buttons, and the `CaptureRadius` check of #877. 20 steps: 7 automated (one through the plugin scenario
`storage-display-double-chest` on a real Paper server), 11 partly and 2 by hand (tagged); every step can still be run by
hand; not run. Full manual run about 40 minutes; the untagged parts about 15 minutes. Tests: knk-plugin
`StorageTerminalModuleTest`, `StorageAdminCommandTest`, `StorageTerminalConfigTest`, `StructuresMenuFeatureTest`
(knk-paper), `TerminalLogicTest`, `StructureMenuTextTest`, `CaptureRadiusTest` (knk-core),
`StorageContainersApiImplTest`, `StructureMenusApiImplTest` (knk-api-client).

**Preconditions (in addition to § 7.0 and § 7.1 steps 1-2):**

1. The game server runs the plugin built from `claude/production-p6` (or `next` once merged) with `production.enabled:
   true`, `items.identity.enabled: true` and the `production.storage` block of the changelog entry. The API's
   `Production:Enabled` is on.
2. Staff also holds `knk.admin.world.production` (the `/knk storage` node; `knk.admin.world.*` covers it).
3. Phoenix has territory (§ 1.3) around the warehouse North, so the territory lookup knows Phoenix there.
4. Remove any binding § 7.1 left on the blocks you use (`DELETE api/StorageContainers/<id>`), then
   `/knk storage reload`.
5. In North, place an empty double chest (block A) and an empty barrel (block B). Note North's delivery storage id.

**Steps:**

1. [partly automated: knk-plugin `StorageAdminCommandTest.metadataGatesOnTheProductionNode`,
   `StorageContainersApiImplTest.bind_postsTheCanonicalBlock_andUnbindDeletes`; by hand: in game]
   As Staff, look at either half of chest A and type `/knk storage bind <North delivery id> terminal`. **Expected:**
   "Bound to North … as a Terminal (54 slots, container #<id>)". `/knk storage info` on the other half shows the same
   container ("Terminal of …, Chest, double, 54 slots"). Typing the bind again says "This block is already bound";
   binding a chest with an item in it says "Empty the container first". In the web app the container's block is the
   left half of the double chest. (A14, DESIGN § 6.3)
2. [partly automated: knk-plugin scenario `storage-display-double-chest`, `StorageTerminalModuleTest.aDisplayHoldsATaggedSample_andOpensReadOnly`;
   by hand: in game]
   Put 300 Cobblestone into North's delivery storage (§ 7.1 step 4 or a terminal put), then look at barrel B and type
   `/knk storage bind <North delivery id> display Stock`. **Expected:** "Bound to Stock as a Display (27 slots, …)";
   within a second the barrel holds full stacks of Cobblestone spread over its slots, as many as the API's `filledSlots`
   (`GET api/StorageContainers/<id>/display`).
3. [automated: knk-plugin `StorageTerminalModuleTest.aBoundChestOpensAsATerminal_anUnboundChestStaysAChest`]
   As Member, right-click chest A. **Expected:** a menu "Terminal: North …" opens, not the chest: Cobblestone with
   "Amount: 300" (a stack's picture) in the first slot, the chest item at the bottom middle with "300 of … units (…%)"
   and "Page 1 of 1"; no page arrows. A chest that is not bound opens as a normal chest. (A14)
4. [automated: knk-plugin `StorageTerminalModuleTest.take_givesTheAcceptedUnits_withOneKeyPerClick`,
   `TerminalLogicTest.take_leftIsAStack_rightIsOne_shiftIsWhatFits_neverMoreThanStockOrRoom`]
   In the terminal, left-click the Cobblestone, then right-click it. **Expected:** 64 and then 1 Cobblestone land in
   Member's inventory, chat says "Took 64 Cobblestone" and "Took 1 Cobblestone", the entry shows "Amount: 235". With 3
   free slots, shift-click: 192 more (what fits). The ledger (web app, North's delivery storage) has one Withdraw per
   click, actor Member, source `StorageContainer <id>`. (A14)
5. [automated: knk-plugin `StorageTerminalModuleTest.put_holdsTheItemsBack_andReturnsWhatTheApiRefused`,
   `StorageTerminalModuleTest.put_aLostAnswerIsSentAgainWithTheSameKey_onlyOnce`]
   With the terminal open, click a stack of 32 Cobblestone in Member's own inventory, then right-click another stack.
   **Expected:** the 32 leave the inventory and "Put in 32" appears; the right click puts 1. Cap North's delivery storage
   just above its current stock (`PUT api/Storages/<id>` with `maxUnits`) and put a stack of 64: only what fits goes in,
   the rest comes back ("Put in 10 (54 back: the storage is full)"). Remove the cap again. (A14)
6. [automated: knk-plugin `StorageTerminalModuleTest.put_isRefusedWithoutItemIdentity_forUnknownUniqueDamagedOrEnchantedItems`]
   Try to put a renamed item (anvil), a damaged pickaxe, an enchanted vanilla pickaxe and a unique item. **Expected:**
   each is refused with its message (menus player guide § Storage terminals and displays) and stays in the inventory.
   With `items.identity.enabled: false` (restart) every put says "Item identity is off on this server". Unique items in
   the list can't be taken out in game either ("use the web app").
7. [automated: knk-plugin `StorageTerminalModuleTest.anApiRefusalOfTheTerminalIsTold`,
   `StorageContainersApiImplTest.put_aForbiddenPlayerIs403`]
   As Visitor, right-click chest A. **Expected:** no menu; chat says "Only members of this storage's town, its owner and
   staff can use this terminal." As Staff (not a member) the terminal opens. (A14, A26)
8. [partly automated: knk-plugin scenario `storage-display-double-chest` (a hopper under a bound double chest moves
   nothing, under an unbound chest it does), `StorageTerminalModuleTest.aDisplayHoldsATaggedSample_andOpensReadOnly`;
   by hand: in game]
   As Member, right-click barrel B, try to drag or shift-click an item out, and place a hopper under it. **Expected:** a
   read-only "Display: Stock" menu opens; nothing can be taken; the hopper stays empty.
9. [partly automated: knk-plugin `TerminalLogicTest.throttle_runsOncePerInterval_andKeepsTheLastAskForLater`; by hand:
   in game]
   Take 128 Cobblestone through terminal A, wait 30 seconds and look into barrel B. **Expected:** the barrel shows fewer
   stacks (the sample follows the fill level). Leave the area until the chunk unloads, change the stock in the web app,
   come back: the barrel shows the new sample on arrival. (DESIGN § 6.2)
10. [partly automated: knk-plugin `StorageTerminalModuleTest.boundBlocksCantBeBroken`; by hand: TNT]
    As Staff, try to break chest A and barrel B; set off TNT next to them inside a region where TNT is allowed.
    **Expected:** breaking is refused ("This terminal is bound to … Unbind it first (/knk storage unbind)."); the
    explosion leaves both blocks (and the barrel's sample is never dropped).
11. [partly automated: `StorageContainersApiImplTest.bind_postsTheCanonicalBlock_andUnbindDeletes`; by hand: in game]
    Look at barrel B and type `/knk storage unbind`. **Expected:** "Unbound Stock (container #<id>)", the barrel is
    empty, `/knk storage info` says "Not bound." Bind a chest in the web app (StorageContainer form) and type `/knk
    storage reload`: "<n> bound container(s)." and it opens as a terminal.
12. [automated: knk-plugin `StructuresMenuFeatureTest.theThreeSeededMenusAndTheHub_validateAgainstTheRegisteredFeature`,
    `StructuresMenuFeatureTest.townFilter_startsOnThePlayersTown_onlyWhenOpenedFromOutside`]
    As Member standing in Phoenix's territory, open the main menu and click **Structures** (crafting table, slot 18).
    **Expected:** the overview lists every production structure and warehouse (Quarry with a cobblestone, North with a
    chest); the header and the compass say "Town: Phoenix", so only Phoenix's structures show. In the wilderness the
    overview opens with "Town: all". Going back from a structure keeps the filter you chose. (A24)
13. [partly automated: knk-plugin `StructuresMenuFeatureTest.overview_sendsTheFacetsAsApiFilters_byName_andActsForThePlayer`,
    `StructureMenuTextTest.facets_cycleByName_andTheApiFiltersById`; by hand: in game]
    Click the compass until "Town: all", click the hopper (Kind) and the redstone torch (Status), search "qua" with the
    sign, then click the barrier. **Expected:** each click narrows the list (chat says "Kind: Quarry" and so on, the
    header lines follow), the barrier clears all three filters. (A24)
14. [automated: knk-plugin `StructuresMenuFeatureTest.structureMenu_aVisitorSeesOnlyThePublicPart_aMemberTheDetailAndStorages`,
    `StructureMenuTextTest.publicLines_showKindTownLevelProductsAndStatus`, `StructureMenuTextTest.detailLines_areEmptyWithoutTheDetail_andFullWithIt`]
    As Visitor, click Quarry. **Expected:** the structure menu shows Quarry's kind, town, level, "Produces:
    Cobblestone" and its status only; no Productions, Workers, Warnings or Transport orders items and no storage list.
    As Member: also "Cobblestone: … per hour", "Present: 2 of 2", the warnings ("No warnings." when none), the Output
    storage with "Filled: 40 of …" and "Cobblestone: Amount: 40", and "Transport orders" with "1 open order". (A25,
    A26)
15. [partly automated: knk-plugin `StructuresMenuFeatureTest.orders_aVisitorsForbiddenReadIsALine_staffSeeTheirButtons`,
    `StructureMenuTextTest.orders_showCargoFromToStateAndArrival_andTheStaffRules`; by hand: in game]
    As Member, click **Transport orders**. **Expected:** the list of § 7.1 step 11's order: "Transport #<id>: InTransit"
    with cargo, from, to and "Arrives: in N min"; no staff hint; clicking it does nothing. (A26)
16. [partly automated: knk-plugin `StructuresMenuFeatureTest.staffActions_checkTheNode_andCallTheirTools`,
    `StructuresMenuFeatureTest.dryRunLines_sayWhatWouldHappen`; by hand: in game]
    As Staff, open Quarry's menu. **Expected:** a bottom row with **Survey now** (chat: "Asking the API to survey
    structure #… … Queued 1 area(s)" and later the result), **Transport dry run** (chat: "Transport dry run (nothing
    changes)", the output, threshold and the reasons, "Would create an order: …" or "Would create no order now.") and
    **Show area outline** (particles along the area for 30 s). Member sees no bottom row. (M4, A26)
17. [partly automated: knk-plugin `StructuresMenuFeatureTest.cancelAndRetry_needAStaffAccount_andRepaint`,
    `StructuresMenuFeatureTest.pending_onlyForAStructuresConfirmation`, `StructureMenusApiImplTest.cancelAndRetry_postForTheStaffMember`;
    by hand: in game]
    As Staff, in Quarry's transport orders, click a waiting order. **Expected:** chat asks "Cancel transport #<id>?" and
    Confirm and Cancel appear; Confirm cancels it ("Transport #<id> cancelled.", the list shows Cancelled). Click it
    again: "Retry transport #<id>?"; Confirm sends it again ("Transport #<id> retried."). An order on the road shows
    only "click to cancel"; a delivered one has no hint. (M4)
18. [by hand]
    Right-click a quarry worker NPC. **Expected:** nothing yet: production structures have no worker NPC entity in the
    plugin (workers are counted by the API), so the menu opens only from the overview. This part of A25 waits for worker
    NPCs (noted on #74).
19. [partly automated: knk-plugin `StorageAdminCommandTest.offWithoutProductionEnabled`,
    `StorageTerminalConfigTest.aServerWithoutTheBlock_usesTheDefaults_andIsOffWithoutTheSwitch`; by hand: in game]
    Set `production.enabled: false` and restart. **Expected:** the main menu has no Structures tile; `/knk storage info`
    says "Production is off on this server"; chest A opens as a normal (empty) chest; barrel B keeps its last sample
    but is no longer protected (unbind displays before switching off for good). Switch it back on. (A21)
20. [by hand; the handler's output is pinned by knk-plugin `CaptureRadiusTest`]
    In the web app, create a production area with shape Radius and click "Send to Minecraft" on the radius. As Staff,
    claim the task (`/knk task <code>`), stand at the centre and type `radius 24`, then `confirm`. **Expected:** the form
    fills the centre (x, y, z), the world and the radius 24; saving it gives the area those bounds. (#877)

## 8. Phase P7: item delivery, reward inbox, deposit/withdraw (#60 API, #684 plugin; tier:3)

Built so far: link L19, the API (knk-web-api, migration `AddItemDelivery`; merged into `next` `2952d0c7`, PR
PandiO/knk-web-api#70), with the P5 read additions of #890 and placement rule P-3 for production areas (#883). The game server part
(`/inbox`, the inbox view, kit and lootbox delivery through the inbox) is link L20 (#684, § 8.2); § 8.1 runs with a
REST client (or Swagger) against the API, sending what the game server sends: the plugin key and, for a player,
`X-Acting-User-Id: <user id>`. 20 steps in § 8.1: 16 automated in CI, 3 partly and 1 by hand (tagged); every step can
still be run by hand; not run. § 8.2 (the plugin, L20): 17 steps, 7 automated and 10 partly (its times are in § 8.2). § 8.1 takes about 35 minutes by hand; its untagged parts
about 10 minutes. The tests are in knk-web-api `Tests/.../Services/Stock/ItemDeliveryServiceTests.cs`,
`Api/InboxControllersTests.cs`, `Services/Production/ProductionAreaPlacementTests.cs`,
`Services/Production/TransportReadNamesTests.cs` (`TransportReadNamesTests`, `SurveyOverlapUnitTypesTests`),
`Migrations/AddItemDeliveryTests.cs` and, with `KNK_TEST_MYSQL`, `MySql/ItemDeliveryMySqlTests.cs` (one inbox per player, one
delivery per key and the cap under concurrent deliveries). Tier:3; the developer's waiver of the smoke gates (2026-11-19) is read by the
coordinator as covering the later links.

### 8.0 Preconditions

1. knk-web-api with the migrations up to `AddItemDelivery` applied (`dotnet ef database update`), `Production:Enabled`
   on except in steps 15 and 16.
2. Accounts: **Staff** (`knk.economy.admin`), **Member** (no staff node) and **Gold** (a player in a premium-tier
   permission group **Gold**, `isPremiumTier` true). Note their user ids and Gold's group id. The game server's calls are
   the plugin key (`X-API-Key`) with `X-Acting-User-Id` naming the player.
3. The blueprints **Oak log** (storage weight 1) and **Stone** (storage weight 2), and one unique item: an
   `ItemInstance` **Dawnbreaker** of a sword blueprint that is in no storage.
4. Game settings: `PUT api/GameSettings` with the production section's `delivery` set to `{ "inboxBaseCapUnits": 100,
   "stashBaseCapUnits": 0, "expiryDays": 30, "reminderDaysBefore": [7, 1], "warnAtPercent": [80, 95], "premiumTiers": [ {
   "permissionGroupId": <Gold>, "inboxCapUnits": 500, "stashCapUnits": 200 } ] }` (the other production sections as
   they are).

### 8.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the pages in the web app]
   As Staff, import the form and display seeds `ItemDelivery` and the form seed `ProductionArea` (seed v3), each with
   "make default". **Expected:** all import; an ItemDelivery opens read only with its lines (requested, inboxed, lost,
   claimed, expired, remaining). (A23)
2. [automated: `ItemDeliveryServiceTests.TheSettings_AreValidated_AndAMissingSectionKeepsTheStoredOne`]
   `GET api/GameSettings`. **Expected:** `production.delivery` as set in § 8.0 step 4. A save without the `delivery`
   section keeps it; `reminderDaysBefore: [30]` (not below `expiryDays`) or the same group twice in `premiumTiers` is 400.
3. [automated: `ItemDeliveryServiceTests.ADelivery_MovesTheItemsIntoTheInbox_AndTellsThePlayer`]
   With the plugin key, `POST api/ItemDeliveries` with `{ "userId": <Member>, "reason": "Lootbox", "sourceType":
   "LootboxClaim", "sourceRef": "77", "idempotencyKey": "lootbox-77", "lines": [ { "itemBlueprintId": <Oak log>,
   "amount": 40 }, { "itemBlueprintId": <Stone>, "amount": 5 } ] }` (what the game server could not place).
   **Expected:** 200, `status` Inboxed, `inboxedUnits` 45, `lostUnits` 0, `expiresAt` 30 days ahead. Member now has a
   Player storage with purpose Inbox, capped at 100; the ledger has one RewardInbox transaction from `SYS_WORLD`
   (source `LootboxClaim 77`). `GET api/PlayerNotifications/pending` has an `InboxUpdated` for Member: event Delivered,
   `fillPercent` 50 (40 + 5 × 2), no `warningPercent`. (A15)
4. [automated: `ItemDeliveryServiceTests.ARetry_AppliesOnce_AndTheSameKeyWithAnotherRequestIs409`]
   Send step 3 again. **Expected:** the same delivery with `replayed` true; the inbox still holds 40 and 5. The same key
   with 41 oak logs is 409 `IdempotencyKeyReuse`.
5. [automated: `ItemDeliveryServiceTests.AtTheHardCap_TheOverflowIsLostToSysLoss_WithALossNotificationAndAWarningBefore`]
   On a fresh Member inbox, deliver 85 oak logs (key `a`), then 10 oak logs and 5 stone (key `b`), then 5 stone (key
   `c`). **Expected:** `a`: Inboxed, the notification has `warningPercent` 80. `b`: PartlyLost: 10 oak logs and 2 stone in
   the inbox, 3 stone lost, an InboxOverflow transaction `SYS_WORLD` → `SYS_LOSS` of 3 stone; the notification has
   `lostUnits` 3 (the loss notification) and `warningPercent` 95. `c`: Lost, nothing in the inbox, no RewardInbox
   transaction. The reconciler stays clean (`GET api/StockTransactions/reconcile`). (A15)
6. [automated: `ItemDeliveryServiceTests.APremiumTier_RaisesTheCaps_AndAnExpiredTierNoLonger`]
   `GET api/Inbox/<Member>` and `GET api/Inbox/<Gold>` with the plugin key. **Expected:** `capUnits` 100 for Member and
   500 for Gold (`premiumTierGroupId` Gold); a 300-unit delivery to Gold fits whole. When Gold's membership ends, a new
   delivery sees the base cap again; nothing already in the inbox is trimmed. (A15)
7. [automated: `ItemDeliveryServiceTests.AClaim_WithRoomForHalf_TakesHalf_OldestLotFirst_AndTheRestStays`]
   Deliver 20 oak logs to Member (key `old`), a day later 20 more (key `new`). With the plugin key and
   `X-Acting-User-Id: <Member>`, `POST api/Inbox/<Member>/claim` with `{ "idempotencyKey": "click-1", "lines": [ {
   "itemBlueprintId": <Oak log>, "amount": 25 } ] }` (room for 25). **Expected:** `result.accepted` 25, an InboxClaim
   transaction to `SYS_WORLD`; 15 stay; the `old` delivery shows claimed 20, the `new` one claimed 5 and remaining 15;
   `view.entries` shows 15 with `nextExpiresAt` of the `new` delivery. The same click again replays; asking for 64 claims
   the 15 there are (`NotEnoughStock` for the rest). (A15)
8. [automated: `ItemDeliveryServiceTests.AUniqueReward_IsAStockUnitInTheInbox_AndKeepsItsIdentityWhenClaimed`]
   Deliver Dawnbreaker (`"lines": [ { "itemInstanceId": <Dawnbreaker> } ]`). **Expected:** a stock unit in Member's
   inbox; the inbox entry shows its custom name. Delivering it again while it is in the inbox is 400. Claim it: the unit
   leaves the inbox and the instance keeps its name and enchantments.
9. [partly automated: `ItemDeliveryServiceTests.Reminders_GoOutBeforeExpiry_ThenExpiredItemsMoveToSysLoss`; by hand:
   the SQL and the sweep]
   On a test database, deliver 30 oak logs and 4 stone and claim 10 oak logs. Set the lots to expire in 6 days:
   `UPDATE item_delivery_lines SET ExpiresAt = UTC_TIMESTAMP(6) + INTERVAL 6 DAY WHERE ItemDeliveryId = <id>;` then, as
   Staff, `POST api/Inbox/sweep`. **Expected:** `remindersSent` 1 and an `InboxUpdated` ExpiryReminder for Member
   (`expiringUnits` 24); a second sweep sends none. Set `ExpiresAt` to 12 hours ahead and sweep: the 1-day reminder.
   Set it to an hour ago and sweep: `expiredLines` 2, `expiredUnits` 24, two InboxExpired transactions inbox →
   `SYS_LOSS`, an `InboxUpdated` Expired with `lostUnits` 24; the lines show expired 20 and 4, remaining 0. The API
   also sweeps every hour. (A15, D7)
10. [automated: `ItemDeliveryServiceTests.TheStash_IsSeparate_DepositsUpToItsCap_AndWithdrawsOncePerKey`]
    With the plugin key and `X-Acting-User-Id: <Member>`, `POST api/Inbox/<Member>/stash/deposit` with key `d0` and 1
    oak log. **Expected:** Rejected `CapacityFull` (no stash without a premium tier). For Gold, deposit 250 (key `d1`):
    200 accepted (cap 200), a Stash storage separate from the inbox, a Deposit transaction. As Staff (web token),
    `.../stash/withdraw` 50 with key `w1`, twice: one Withdraw transaction (actor Staff), 150 left.
11. [automated: `InboxControllersTests.StaffDeliver_FromTheWeb_AndTheGameServerClaims_ForTheNamedPlayerOnly`]
    As Staff with a web token, `POST api/ItemDeliveries` with reason Gift. **Expected:** 200, actor User (Staff). A claim
    with `X-Acting-User-Id` of another player, or without it, is 400 `ActingUserRequired`.
12. [automated: `InboxControllersTests.TheStash_NeedsTheNamedPlayer_OrAWebStaffMember`]
    A stash deposit from the game server naming another player is 400; from Staff's web token it is answered.
13. [partly automated: `ReadAccessRulesTests`, `EndpointAccessRulesTests` (the rules are pinned),
    `InboxControllersTests.TheRoutes_CarryTheirAccessRules`; by hand: the calls below]
    As Member with a web token: `GET api/Inbox/<Member>` is 200, `GET api/Inbox/<Gold>` is 403, `POST api/ItemDeliveries`
    and `POST api/Inbox/sweep` are 403, `POST api/Inbox/<Member>/claim` is 403 (game server only). `POST
    api/ItemDeliveries/search` as Staff lists the deliveries (filters `userId`, `reason`, `status`, `open`).
14. [automated: `ItemDeliveryServiceTests.ALockedInbox_RefusesTheDelivery_AndNothingMoves`]
    Lock Member's inbox (`PUT api/Storages/<inbox>` with `lockedUntil` an hour ahead) and deliver. **Expected:** 409;
    nothing moves, no delivery is recorded.
15. [automated: `ItemDeliveryServiceTests.WithTheFlagOff_NothingMoves_ButTheViewsWork`,
    `InboxControllersTests.WithTheFlagOff_MovesAre409_AndTheViewWorks`]
    Switch `Production:Enabled` off. **Expected:** delivery, claim and stash moves are 409 `ProductionDisabled`; `GET
    api/Inbox/<Member>` still answers; the sweep moves nothing. Switch it back on. (A21)
16. [by hand]
    With `Production:Enabled` off, grant Member a kit on the web player profile ("Grant"). **Expected:** today's delivery
    (#261): the kit claim is pending and the game server hands the kit over when Member is online. Kit and lootbox
    delivery don't go through the inbox while either flag is off (§ 8.2 steps 16 and 17). (A21)
17. [automated: `ProductionAreaPlacementTests` (all)]
    Import `ProductionArea` seed v3 as default. For a rural structure in Phoenix, `POST api/ProductionAreas` with a
    Region area whose region is outside Phoenix's territory. **Expected:** 201 with `placementWarnings` naming Phoenix's
    territory (P-3, warning by default). For a structure in district Market, a Region area outside the district's
    region warns; a Cuboid is checked by its four corners, a Radius by its centre and the four points one radius away.
    Make the rule blocking (the form's rule, `isBlocking`): the save is 400 and nothing is saved. With the game server
    offline the area saves with a "not checked" warning; with `Production:Enabled` off the territory half is skipped.
    (#883)
18. [automated: `TransportReadNamesTests.TheStructureView_NamesItsDestinationWarehouse_AndThePlanItsCarrier`,
    `TransportReadNamesTests.ACycleRecord_NamesItsStructure`]
    `GET api/ProductionStructures/<Quarry>/transport`, `POST api/TransportOrders/dry-run` and `GET
    api/ProductionCycleRecords/<id>`. **Expected:** `destinationWarehouseName`, `carrierStructureName` and
    `productionStructureName` next to their ids. (#890)
19. [automated: `TransportReadNamesTests.TheDueLanes_SayWhichEndIsAProducerAndWhichAWarehouse`]
    With the plugin key, `GET api/TransportLanes/due`. **Expected:** each row has `fromKind` (Producer or Warehouse) and
    `toKind` (Warehouse). (#890)
20. [automated: `SurveyOverlapUnitTypesTests.TheSurveyQueuesOverlaps_CarryTheirKindsUnitTypes`,
    `TransportReadNamesTests.TheUnitTypes_AreReadFromTheKindsSurveyProfile`]
    A Derived logger's forest overlapped by a farm's shared area: `GET api/ProductionAreas/survey-due`. **Expected:** the
    overlap carries `unitTypes` `["CROP"]` (the farm kind's survey profile). (#890, #875)

### 8.2 Steps (plugin, #684)

Built by link L20 (knk-plugin, merged into `next` `bdd8b463`, PR PandiO/knk-plugin#113; how it works:
[item delivery architecture](../architecture/production-item-delivery.md), staff: [reward inbox admin guide](admin/reward-inbox-admin-guide.md)): `/inbox` and the reward inbox view (claim
with partial space), the inbox notices (loss, near-cap warning, expiry reminders, expiry), the join summary, and kit and
lootbox items that don't fit going to the inbox instead of the ground, all behind `production.enabled`. 17 steps: 7
automated (two of them also through the plugin scenarios `player-kit-overflow-inbox` and `player-inbox-claim-partial` on a
real Paper server) and 10 partly (tagged); every step can still be run by hand; not run. Full manual run about 40
minutes; the untagged parts about 15 minutes. Tests: knk-plugin `RewardInboxTest`, `InboxModuleTest`, the inbox tests in
`KitGrantDeliveryTest`, `KitGrantFlowTest` and `LootboxDeliveryTest` (knk-paper), `InboxLogicTest` (knk-core),
`ItemDeliveryApiImplTest` (knk-api-client).

**Preconditions (in addition to § 8.0):**

1. The game server runs the plugin built from `next` (`bdd8b463` or later) with `production.enabled:
   true`, `items.identity.enabled: true` and the `production.inbox` block of the changelog entry. The API's
   `Production:Enabled` is on and has `AddItemDelivery` applied; the delivery settings are those of § 8.0 step 4 (inbox
   cap 100 for Member, 500 for Gold).
2. A kit **Starter** in the web app: contents 16 bread (slot 0), 8 bread (slot 1) and an iron sword (slot 2). Member may
   claim it (no cooldown, no cost).
3. A lootbox type that gives **Bread ×16** (a stackable item) and one that gives a non-stackable sword (a unique item
   with an instance). For steps 4 and 5 set `lootboxes.full-inventory: drop-owned` in the plugin `config.yml` (restart);
   with the default `refuse` a full inventory can't open a box at all.
4. **Full inventory** below means: all 36 inventory slots hold something other than bread or swords (for example dirt).
5. Note Member's user id; `GET api/Inbox/<Member>` (plugin key) shows the inbox at any time.

**Steps:**

1. [automated: `RewardInboxTest.kitWithAFullInventory_leftoversGoToTheInbox_notTheGround`, plugin scenario
   `player-kit-overflow-inbox`]
   As Member with a full inventory, type `/kit get Starter`. **Expected:** nothing lands on the ground; the chat says
   `Kit "Starter" claimed to Member.` and `25 items didn't fit and went to your reward inbox (/inbox).`
   `GET api/Inbox/<Member>` shows Bread 24 and the sword 1; the delivery (`POST api/ItemDeliveries/search`) has reason
   Kit, source `Kit Starter` and a key `kit-<kit id>-u<Member>-…`. (A15)
2. [partly automated: `KitGrantDeliveryTest.withTheInboxOn_theKitPlacesThroughTheRouter_keyedByItsClaim`; by hand: the
   grant from the web app]
   Member stays online with a full inventory. As Staff, grant Starter to Member on the web app's player profile
   ("Grant", #261). **Expected:** within a few seconds `A staff member gave you the "Starter" kit.` and the inbox line of
   step 1; the delivery's key is `kit-claim-<claim id>`; nothing on the ground. (A15)
3. [partly automated: `KitGrantDeliveryTest.withTheInboxOn_aPlayerWhoLeftAfterTheTake_getsTheKitInTheInbox`,
   `RewardInboxTest.offlineKit_goesToTheInboxWhole`, plugin scenario `player-kit-overflow-inbox` (offline part); by
   hand: the grant while offline, the first join]
   Member logs out with a full inventory; Staff grants Starter again. Member joins. **Expected:** the kit is handed over
   a few seconds after the join (#261): whatever fits is placed, the rest is in the inbox with the inbox line. A brand
   new player who leaves before their starter kit (grant on first join) was placed finds it in their inbox on the next
   join instead of losing it. (A15)
4. [partly automated: `LootboxDeliveryTest.withTheInboxOn_leftoversGoToTheRouter_andTheConfirmationWaitsForIt`,
   `RewardInboxTest.lootboxLeftovers_areConfirmedAfterTheInboxAnswered`; by hand: opening a box in game]
   With a full inventory, open a token of the Bread ×16 box. **Expected:** the opening reel runs as usual; the 16 bread go
   to the inbox with `16 items didn't fit and went to your reward inbox (/inbox).`; nothing on the ground. The lootbox
   claim in the web app shows delivery method Inventory with the note `16 to the reward inbox (delivery #<id>)`. (A15)
5. [partly automated: `LootboxDeliveryTest.withTheInboxOn_aUniqueItemStillDropsOwnerLocked`; by hand: in game]
   With a full inventory, open a token of the sword box. **Expected:** the sword drops at Member's feet, owner-locked (as
   before; unique items can't be claimed back from the inbox in game yet, #897); the claim shows DroppedOwned.
6. [partly automated: `InboxModuleTest.open_showsTheEntries_theExpiry_andTheInfo`; by hand: how it looks]
   Type `/inbox`. **Expected:** a double-chest view titled `Reward inbox`: each entry as its item with `Waiting: <amount>`
   and the first expiry (`24 expire in 30 days`); the ender chest at the bottom shows `Filled: <used> of 100 (<n>%)` (storage weights count), the page
   and how to claim; arrows when there are more than 45 entries. A unique entry says `Unique items can't be claimed in
   game yet`. Items can't be taken out by dragging.
7. [automated: plugin scenario `player-inbox-claim-partial`, `InboxModuleTest.claim_withPartialSpace_asksForWhatFits_andPlacesIt`]
   Leave room for 10 bread only (one slot with 54 bread, the others full), then shift-click the bread. **Expected:**
   `Claimed 10 items Bread`; your inventory now has 64 bread in that slot; the inbox shows 10 fewer (the oldest first,
   § 8.1 step 7); nothing on the cursor. (A15)
8. [automated: `InboxModuleTest.claim_placesExactlyWhatTheApiAccepted_withOneKeyPerClick`]
   With room, left-click the bread (a stack of 64, or what is left), then right-click it (one). **Expected:** each click
   is one claim with its own key (`inbox-claim-u<Member>-…`); exactly what the API accepted lands in the inventory; when
   the inbox had less than asked, the line ends with `(the inbox has less than that)`.
9. [automated: `InboxModuleTest.claim_withAFullInventory_isRefusedWithoutACall`, plugin scenario
   `player-inbox-claim-partial`]
   With a full inventory, click the bread. **Expected:** `Your inventory is full. Make room, then claim again.`; nothing
   leaves the inbox.
10. [automated: `InboxModuleTest.claim_ofAUniqueItem_isRefusedInGame`]
    Click a unique entry (for example the Dawnbreaker of § 8.1 step 8). **Expected:** `Unique items can't be claimed in
    game yet; ask a staff member.`; nothing moves.
11. [automated: `InboxModuleTest.duringASiege_theInboxDoesNotOpen`]
    Join a siege lobby and type `/inbox`. **Expected:** `You can't claim rewards during a siege. Your inbox waits for
    you.`; no view opens.
12. [partly automated: `InboxModuleTest.notices_lossWarningReminderExpiry`, `InboxModuleTest.open_nearlyFull_warns`,
    `RewardInboxTest.theLoss_isToldFirst_andTheDeliveryIsRemembered`; by hand: the real deliveries]
    Empty Member's inbox, then deliver 85 oak logs, then 10 oak logs and 5 stone, as in § 8.1 step 5 (or claim kits with
    a full inventory until the inbox nears 100). **Expected:** in game, after the first delivery (gold) `Your reward inbox
    is 80% full. Claim items with /inbox before new rewards are lost.`; after the second (red first) `Your reward inbox is
    full: 3 items were lost.`, then the arrival line and the 95% warning. `/inbox` repeats the warning when it opens. A
    reward the server itself sent is told once (where it went and what was lost), not again by the notice. (A15)
13. [partly automated: `InboxModuleTest.notices_lossWarningReminderExpiry`; by hand: the SQL and the sweep of § 8.1 step 9]
    Move the lots' expiry as in § 8.1 step 9 and sweep. **Expected:** in game (gold) `24 items in your reward inbox
    expire in 6 days. Claim them with /inbox.` and later the 1-day reminder; after expiry (red) `24 items in your reward
    inbox expired and are gone.`, and the entries are gone from `/inbox`. A player offline at the time sees the lines at
    the next join. (A15, D7)
14. [automated: `InboxModuleTest.joinSummary_saysWhatWaits`]
    With items in the inbox, log out and in. **Expected:** about five seconds after the join `You have <n> items in your
    reward inbox (/inbox).`, plus `Some of them expire in <time>.` when something expires within 7 days and the warning
    when the inbox is nearly full. Nothing for an empty inbox; nothing with `production.inbox.join-summary: false`.
15. [partly automated: knk-web-api `ItemDeliveryServiceTests.APremiumTier_RaisesTheCaps_AndAnExpiredTierNoLonger`; by
    hand: the view]
    As Gold, type `/inbox`. **Expected:** the fill shows `of 500`; Member's shows `of 100`. (A15)
16. [partly automated: `RewardInboxTest.productionDisabled_fallsBackToTodaysDrop`,
    `InboxModuleTest.claim_whileTheApiIsSwitchedOff_takesNothing`; by hand: switching the API's flag]
    Switch the API's `Production:Enabled` off and leave the plugin's on. With a full inventory, `/kit get Starter`.
    **Expected:** the leftovers drop at your feet with `Some of it didn't fit and was dropped at your feet.` (today's
    delivery; the server log says the API's flag is off). `/inbox` still opens; a claim says `The reward inbox is
    switched off on the server right now.` and takes nothing. Switch the flag back on.
17. [partly automated: `InboxModuleTest.theCommand_withTheFlagOff_saysTheInboxIsOff`,
    `KitGrantDeliveryTest.withTheRouterAnsweringNull_theFlagOffPathIsTodays`,
    `KitGrantFlowTest.withTheInboxOff_aGiveToAPlayerWhoLeft_isAsBefore`, `RewardInboxTest.withoutAnOverflow_theKitDropsAtTheFeetAsBefore`,
    plugin scenario `player-kit-overflow-inbox` (control); by hand: the web grant and a lootbox]
    Set `production.enabled: false` in the plugin `config.yml` and restart. **Expected:** `/inbox` says `The reward inbox
    is not switched on on this server.`; `/kit get Starter` with a full inventory drops the rest at your feet; a kit
    granted from the web app (#261) is handed over as before; a lootbox with `drop-owned` drops its leftovers
    owner-locked; no call to `api/ItemDeliveries` or `api/Inbox` in the API log. (A21, #261)

## 9. Phase P8: player harvesting and block regeneration (#685 API, #134 plugin; tier:3)

Built so far: link L21, the API (knk-web-api, migration `AddPlayerHarvesting`; in `next`), with placement rule P-3 for
Polygon areas (#900), and link L22, the game server part (knk-plugin, in `next` `6f6c915f`, PR PandiO/knk-plugin#114): the
harvest listener, placeholders and the regeneration queue, § 9.2. § 9.1 runs with a REST client (or Swagger) against the
API, sending what the game server sends: the plugin key (`X-API-Key`). 21 steps in § 9.1: 18 automated in CI and 3
partly (tagged); every step can still be run by hand; not run. § 9.2 is the plugin part (22 steps). Full manual run of § 9.1 about 35
minutes; the untagged parts about 10 minutes. The tests are in knk-web-api
`Tests/.../Services/Production/ProductionHarvestTests.cs`, `Api/HarvestControllersTests.cs`,
`Services/Production/ProductionAreaPlacementTests.cs` (#900), `Migrations/AddPlayerHarvestingTests.cs` and, with
`KNK_TEST_MYSQL`, `MySql/PlayerHarvestMySqlTests.cs` (one pool per area and every draw counted under concurrent
harvests, one booking per key). Tier:3; the developer's waiver of the smoke gates (2026-11-19) is read by the
coordinator as covering the later links.

How it works, in short (PRODUCTION_KINDS § 6-7): a **harvest rule** per production kind says what players may break,
what a break yields and how much of it the player keeps (the **worker's share**, 25% by default); the rest goes into
the structure's Output storage. Each break draws its **pool cost** from the area's **resource pool**; the structure
produces at `floor + (1 − floor) × fill` (floor 0.5, P-D6) until the pool regenerates. The game server reports each
harvest; the API books the split once per idempotency key and answers how many units the player gets and when the
block comes back.

### 9.0 Preconditions

1. knk-web-api with the migrations up to `AddPlayerHarvesting` applied (`dotnet ef database update`),
   `Production:Enabled` on except in step 18.
2. Accounts: **Staff** (`knk.admin.world`), **Member** and **Sam** (players, no staff node). Note their user ids. The
   game server's calls use the plugin key (`X-API-Key`).
3. The § 4 quarry: a rural production structure **Quarry** in Phoenix of kind Quarry (id 3), level 1, with an Output
   storage capped at 100 units and one Configured line **Cobblestone** at 60 per hour. An area **Pit** on it (`POST
   api/ProductionAreas`, shape Cuboid, 10 × 10 × 10). The blueprint **Cobblestone** (storage weight 1).
4. Game settings: `PUT api/GameSettings` with the production section's `harvest` set to `{ "defaultPoolCapacity": 1000,
   "defaultRegenHoursToFull": 12, "maxEntriesPerReport": 200 }` (the other production sections as they are).

### 9.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the pages in the web app]
   As Staff, import the form and display seeds `HarvestRule` and `ResourcePool`, the display seed `PlayerHarvest`, and
   `ProductionKind` seed v3 (form and display), each with "make default". **Expected:** all import; the HarvestRule
   form has four steps (rule, who may harvest, yield, regeneration); the ProductionKind form shows "Pool floor" (0.5)
   on the Yield step. (A23)
2. [automated: `ProductionHarvestTests.HarvestSettings_AreValidated_AndKeptWhenAClientOmitsThem`]
   `GET api/GameSettings`. **Expected:** `production.harvest` as set in § 9.0 step 4. A save without the `harvest`
   section keeps it; `defaultRegenHoursToFull: 0` is 400.
3. [automated: `ProductionHarvestTests.ARule_IsValidated_AndCannotBeDeletedOnceItHasHarvests`]
   As Staff, `POST api/HarvestRules` with `{ "productionKindId": 3, "name": "Stone", "targetKind": "Block", "targets":
   ["stone", "*_cobblestone"], "yieldItemBlueprintId": <Cobblestone>, "yieldPerBreak": 1, "workerShare": 0.25,
   "poolCost": 1, "placeholder": "DepletedBlock", "placeholderMaterial": "bedrock", "regenSeconds": 60,
   "requiredPermission": "knk.harvest.quarry" }`. **Expected:** 201; the targets come back upper case (`STONE`,
   `*_COBBLESTONE`), `placeholderMaterial` `BEDROCK`. The same name in the same kind is 400; `workerShare: 1.5`, a target
   with a space, a permission with a space and an unknown `minTitleBracketId` are 400; moving the rule to another kind
   is 400.
4. [automated: `ProductionHarvestTests.TheCatalogue_ListsTheEnabledRules_AndTheAreasOfTheirKinds_WithThePoolFill`]
   With the plugin key, `GET api/Harvest/catalog`. **Expected:** `featureEnabled` true; `rules` has Stone (a switched-off
   rule is not listed); `areas` has Pit with Quarry's id, kind 3, its shape and bounds, and `poolFill` 1 (no pool yet).
5. [automated: `ProductionHarvestTests.AHarvest_IsSplitAtOnce_WorkersShareToTheWorld_TheRestToOutput_BothAsPlayerHarvest`]
   With the plugin key, `POST api/Harvest/reports` with `{ "entries": [ { "idempotencyKey": "h-1", "userId": <Member>,
   "harvestRuleId": <Stone>, "productionAreaId": <Pit>, "breaks": 4 } ] }`. **Expected:** 200, the entry `Applied` with
   `workerUnits` 1 (the player gets 1 cobblestone), `townUnits` 3, `townAccepted` 3, `regenSeconds` 60. The ledger has
   two PlayerHarvest transactions (source `PlayerHarvest h-1`): 1 cobblestone `SYS_PRODUCTION` → `SYS_WORLD` and 3
   `SYS_PRODUCTION` → Quarry's Output. `GET api/StockTransactions/reconcile` is clean. (A16)
6. [automated: `ProductionHarvestTests.TheFirstHarvest_MakesTheAreasPool_Full_ThenDrawsThePoolCost_NotBelowZero`]
   `POST api/ResourcePools/search` with filter `productionAreaId` = Pit, then `GET api/ResourcePools/<id>`.
   **Expected:** one pool made by the first harvest: `capacity` 1000 (no survey: the default), `current` 996 (4 breaks ×
   cost 1), `regenPerHour` 83.33 (full in 12 hours), `poolFloor` 0.5. A harvest that costs more than is left takes the
   pool to 0, not below. (A16)
7. [automated: `ProductionHarvestTests.Fractions_AccruePerPlayerAndRule_LikeLineAccrual`]
   Report four entries of 1 break each for Member (keys `f-1` to `f-4`) and one for Sam (`s-1`). **Expected:** Member's
   entries pay 0, 0, 0, 1 units (the quarters carry over) and send 0, 1, 1, 1 to Output; Sam's entry pays 0 and sends 0
   (his fractions are his own).
8. [automated: `ProductionHarvestTests.AReport_IsIdempotentPerEntry_AndAKeyWithAnotherHarvestIsRejected`]
   Send step 5 again, together with a new entry `h-2` (4 breaks) and an entry with an unknown rule. **Expected:** `h-1`
   `Replayed` with the same numbers (nothing moves again), `h-2` `Applied`, the third `Rejected` with "not found". Key
   `h-1` with 5 breaks is `Rejected` ("a different harvest"); two entries with the same key in one report are 400.
9. [automated: `ProductionHarvestTests.EntriesTheApiMayNotBook_AreRejected_WithAReason`]
   Report entries with a switched-off rule, a rule of another kind (a Logger rule in Pit), an unknown user and an
   unknown area; then switch Quarry's production off (`productionEnabled` false) and report a valid entry.
   **Expected:** each `Rejected` with its reason; nothing is booked and no pool is made for these. Switch Quarry's
   production back on.
10. [automated: `ProductionHarvestTests.AFullOutput_LosesTheTownsShare_ButThePlayerIsStillPaid_F10`]
    Fill Quarry's Output to 98 of 100 units, then report 8 breaks. **Expected:** `workerUnits` 2, `townUnits` 6,
    `townAccepted` 2, `townLost` 4, a `shortfallReason` saying the rest is lost to the town; the player is still paid
    (F10). The reconciler stays clean.
11. [automated: `ProductionHarvestTests.ThePoolStep_SlowsTheStructure_DownToTheFloor_AndTheTraceShowsIt`]
    Set Pit's pool to `current` 0 (`PUT api/ResourcePools/<id>` with `{ "current": 0 }`), wait for a cycle (or `POST
    api/ProductionLines/<Cobblestone>/settle`), then `GET api/ProductionStructures/<Quarry>/production`. **Expected:** the
    line's `poolFactor` is 0.5 plus half the pool's fill (0.5 at an empty pool), its `effectiveRatePerHour` 60 × that,
    and a reason "Player harvesting has drawn down the resource pool: …% output until it regenerates"; the newest cycle
    record (`GET api/ProductionCycleRecords/<id>`) has the same `poolFactor`. Production never stops. (A16, P-D6)
12. [automated: `ProductionHarvestTests.TheHarvest_SettlesTheStructureFirst_SoTheTimeBeforeCountsAtTheOldFactor`]
    With a full pool and an hour since the last settle, report a harvest that empties the pool. **Expected:** a cycle
    record for that hour with `poolFactor` 1 (the time before the harvest at full speed); the next settle uses the
    lower factor.
13. [partly automated: `ProductionHarvestTests.Pool_RegeneratesLazily_UpToItsCapacity`,
    `ProductionHarvestTests.TheFirstHarvest_MakesTheAreasPool_Full_ThenDrawsThePoolCost_NotBelowZero`; by hand: the
    wait]
    After step 11, wait an hour and `GET api/ResourcePools/<id>`. **Expected:** `current` about 83 higher (regeneration
    is worked out on read, up to the capacity), `fill` and `poolFactor` up, `hoursToFull` about 11. (A16)
14. [automated: `ProductionHarvestTests.ANewSurvey_SetsThePoolsCapacity_KeepingItsFill`]
    For a Hybrid logger with a surveyed Radius area (§ 5.1 steps), harvest once, then report a new survey with twice
    the units (`POST api/ProductionAreas/<id>/surveys`). **Expected:** the first harvest made the pool with `capacity` =
    the latest survey's total units; after the new survey the capacity doubles and the fill is kept. With
    `capacityFromSurvey` false (staff typed a capacity) a survey leaves the capacity alone. (§ 6.3, L11 note)
15. [automated: `ProductionHarvestTests.StaffMakeAndTuneAPool_OnePerArea`]
    As Staff, `POST api/ResourcePools` with `{ "productionAreaId": <another area>, "capacity": 500 }`, then a second pool
    for the same area, then `PUT` with `{ "current": 125, "regenPerHour": 0 }` and with `{ "capacity": 0 }`.
    **Expected:** 201 (full, `capacityFromSurvey` false); 409 (one pool per area); `fill` 0.25, `poolFactor` 0.625,
    `hoursToFull` null; 400.
16. [automated: `ProductionHarvestTests.TheBalance_ComparesTheTownsShare_WithTheProductionLostUntilThePoolRefills`,
    `ProductionHarvestTests.TheBalance_UsesANewPoolsDefaults_ForAnAreaWithoutAPool`]
    Set Pit's pool to capacity 1000 and `regenPerHour` 100, then `GET api/HarvestRules/<Stone>/balance`. **Expected:**
    for Pit: `baseRatePerHour` 60, `townSharePerBreak` 0.75, `lostPerBreak` 0.00015 (60 × 0.5 × 1/1000 × 1/100 ÷ 2),
    `netPositive` true, no warnings. Make a rule with `poolCost` 100 and `workerShare` 0.5 and set the regeneration to 1
    per hour: `lostPerBreak` 150, `netPositive` false and a warning naming Quarry / Pit. With regeneration 0:
    `lostPerBreak` null and a "does not regenerate" warning. An area without a pool uses a new pool's defaults
    (`poolExists` false). (F9)
17. [automated: `ProductionHarvestTests.ThePoolStep_SlowsTheStructure_DownToTheFloor_AndTheTraceShowsIt`]
    `PUT api/ProductionKinds/3` with `{ "poolFloor": 1 }`, settle the line. **Expected:** `poolFactor` 1 whatever the
    pool holds (harvesting no longer slows Quarry). `poolFloor: 1.5` is 400. Set it back to 0.5.
18. [automated: `ProductionHarvestTests.WithProductionOff_ReportsAre409_AndTheCatalogueIsEmpty`,
    `HarvestControllersTests.Results_MapTo400_404_And409WhileOff`]
    Switch `Production:Enabled` off. **Expected:** `POST api/Harvest/reports` is 409 `ProductionDisabled`; `GET
    api/Harvest/catalog` answers `featureEnabled` false with empty lists; rules and pools can still be read and edited.
    Switch it back on. (A21)
19. [partly automated: `ReadAccessRulesTests`, `EndpointAccessRulesTests`, `DeleteAccessRulesTests`,
    `DashboardChangeAccessRulesTests` (the rules are pinned), `HarvestControllersTests.TheRoutes_CarryTheirAccessRules`;
    by hand: the calls below]
    As Member with a web token: `POST api/Harvest/reports` is 403 (game server only), `POST api/HarvestRules` and `PUT
    api/ResourcePools/<id>` are 403, `GET api/PlayerHarvests/<id>` is 403. As Staff: `POST api/PlayerHarvests/search`
    lists the harvests (filters `userId`, `harvestRuleId`, `productionStructureId`, `productionAreaId`); `DELETE
    api/HarvestRules/<Stone>` is 409 (it has harvests: switch it off instead) and needs `knk.admin.delete`.
20. [automated with `KNK_TEST_MYSQL`: `PlayerHarvestMySqlTests` (all)]
    On a MySQL test database, send ten reports for Pit at the same time (ten players, and again one player), and one
    key eight times at once. **Expected:** one pool; every pool cost counted; the players' fractions add up; one booking
    for the key; the reconciler clean.
21. [automated: `ProductionAreaPlacementTests.APolygonArea_IsCheckedByEachOfItsPoints`,
    `ProductionAreaPlacementTests.PolygonPoints_ReadsPointsJsonOrAPointsList_AndNeedsThree`]
    With `ProductionArea` seed v3 the default, `POST api/ProductionAreas` for the rural Logger with shape Polygon and
    points `[{"x":0,"z":0},{"x":20,"z":0},{"x":30,"z":20},{"x":0,"z":20}]` inside Phoenix's territory, then one with a
    point outside. **Expected:** the first saves without warnings; the second saves with a `placementWarnings` entry
    naming Phoenix's territory (P-3, each point checked); moving the point back inside on update clears it. (#900)

### 9.2 Steps (plugin, #134)

Built by link L22 (knk-plugin, in `next` `6f6c915f`, PR PandiO/knk-plugin#114): the harvest listener for blocks and
entities against the API's catalogue, the WorldGuard and global-region pass for qualified harvests, placeholders and
the disk-persisted regeneration queue (whole felled trees restored by snapshot), batched harvest reports with one
idempotency key per entry, the worker's share handed to the player, the messages and `/knk production harvest
status|refresh`, all behind `production.enabled`. 22 steps: 10 automated (four of them also through the plugin scenarios
`player-harvest-regenerate` and `player-harvest-tree` on a real Paper server), 10 partly and 2 by hand (tagged); every
step can still be run by hand; not run on a live server (the two scenarios pass on a local Paper 26.3 server with
WorldGuard 7.0.20). Full manual run about 60 minutes; the untagged parts about 25 minutes. Tests: knk-plugin
`HarvestGateTest`, `RegenQueueTest`, `HarvestOutboxTest`, `TreeFellerTest`, `HarvestAreaIndexTest`, `HarvestRuleTest`
(knk-core), `HarvestApiImplTest` (knk-api-client), `HarvestModuleTest`, `GlobalRegionProtectionListenerTest`,
`ProductionAdminCommandTest` (knk-paper).

**Preconditions (in addition to § 9.0):**

1. The game server runs the plugin built from `next` (`6f6c915f` or later) with `production.enabled:
   true`, `items.identity.enabled: true` and the `production.harvest` block of the changelog entry (restart). The API has
   `AddPlayerHarvesting` applied and `Production:Enabled` on.
2. The Quarry of § 9.0 has its managed region (a `RESOURCE_PRODUCTION` region, which denies `block-break` to
   non-members) and the area **Pit** is a `Region` area on it, or a `Cuboid` area inside it. Pit holds stone.
3. Harvest rules (`POST api/HarvestRules`; the web app pages are #913):
   1. **Quarry stone**: kind Quarry, targets `STONE`, tool Pickaxe (any tier), permission `knk.harvest.quarry`, yield
      Cobblestone 4 per break, worker's share 0.25, pool cost 1, placeholder DepletedBlock with material `BEDROCK`,
      regeneration 60 s.
   2. **Logs**: kind Logger, targets `*_LOG`, any tool, no permission, yield Oak log 1, placeholder Sapling,
      regeneration 120 s; a Logger structure with a `Radius` area **Forest** (radius 16) around a few oak trees outside
      every region.
   3. **Wheat**: kind Farm, targets `WHEAT`, minimum age 7, any tool, placeholder Replant, regeneration 60 s; a Farm with
      an area **Field** over ripe and unripe wheat.
   4. **Cows** (for step 21): kind Farm, target kind Entity, targets `COW`, placeholder None; two cows in Field.
4. Accounts: **Member** holds `knk.harvest.quarry` (an in-house grant), **Visitor** holds nothing, **Staff** holds
   `knk.admin.world.production`. None is a member of the Quarry's region.
5. Note Member's user id. `GET api/PlayerHarvests/search` and the Quarry's Output storage show the bookings.

**Steps:**

1. [partly automated: `HarvestModuleTest.statusDescribesTheModule`, `ProductionAdminCommandTest`; by hand: the live
   catalogue]
   As Staff, type `/knk production harvest refresh`, then `/knk production harvest status`. **Expected:** "Catalogue
   read: 4 rules, 3 areas"; the status shows the API flag on, the rules and areas, no area left out, 0 jobs and 0
   entries waiting.
2. [automated: plugin scenario `player-harvest-regenerate`, `HarvestModuleTest.aQualifiedBreakIsHarvestedAndPaidWhenTheApiAnswers`]
   As Member, holding an iron pickaxe, mine a stone block in Pit. **Expected:** the block breaks although the region
   denies building; no stone or cobblestone drops; the block turns to bedrock; within about 2 s the chat says "+1
   Cobblestone (your share of the harvest)" and one cobblestone is in the inventory (4 × 0.25). (A16)
3. [partly automated: `HarvestModuleTest.aQualifiedBreakIsHarvestedAndPaidWhenTheApiAnswers`, `HarvestOutboxTest`; by
   hand: the API rows]
   **Expected** after step 2: `api/PlayerHarvests/search` has one harvest of Member, rule Quarry stone, area Pit, 1 break,
   key `harvest-<server id>-<uuid>`; the Quarry's Output holds 3 more Cobblestone; the pool of Pit dropped by 1. Mine
   five more stones within 2 s: **Expected:** one harvest with 5 breaks (one entry), 5 cobblestone paid. (A16, F10)
4. [automated: plugin scenario `player-harvest-regenerate`, `RegenQueueTest.aDueJobIsRestoredWhereThePlaceholderStands`]
   Wait 60 s (the answer's `regenSeconds`; longer when the rule scales with the pool). **Expected:** the stone is back
   where the bedrock was. (A16, § 7)
5. [automated: `HarvestModuleTest.aBlockWaitingToRegenerateIsRefused`, `HarvestGateTest.aBlockWaitingToRegenerateCannotBeBroken`]
   As Member, mine a stone, then try to mine the bedrock in its place. **Expected:** refused with "This block is
   regenerating."; nothing reported.
6. [partly automated: `HarvestGateTest.anUnqualifiedPlayerIsRefusedWithTheReason`, `HarvestRuleTest.toolsHaveAClassAndATier`;
   by hand: the message in game]
   As Member, hit a stone in Pit with an empty hand, then with a shovel. **Expected:** refused each time with "You can't
   harvest this here: needs a pickaxe."; nothing reported.
7. [automated: plugin scenario `player-harvest-regenerate`, `HarvestModuleTest.anUnqualifiedPlayerIsRefusedAndNothingIsReported`]
   As Visitor, holding a pickaxe, mine a stone in Pit. **Expected:** the stone stays; "You can't harvest this here: you
   need the permission knk.harvest.quarry."; nothing reported. Break a dirt block in Pit: **Expected:** refused by
   WorldGuard's region message, as before harvesting existed.
8. [partly automated: `HarvestModuleTest.staffAndBlocksOutsideTheAreasAreLeftAlone`; by hand: WorldGuard's answer]
   As Staff, mine a stone in Pit. **Expected:** WorldGuard decides as before (staff with region rights break it with
   vanilla drops); nothing reported, no placeholder.
9. [automated: plugin scenario `player-harvest-tree`, `TreeFellerTest.aLogFellsItsWholeTree`]
   As Member, break the bottom log of an oak in Forest (outside every region). **Expected:** the whole tree (logs and its
   leaves) disappears at once, nothing drops, an oak sapling stands at its base; one harvest with as many breaks as the
   tree had logs; the share arrives. Bone meal on the sapling does nothing. After 120 s the same tree is back, leaf for
   leaf. (A16, P-D8)
10. [partly automated: `TreeFellerTest.tooManyLogsIsNotATreeAndALonePlacedLogNeither`; by hand: a log building]
    Build a small hut of 300 oak logs in Forest and break one log as Member. **Expected:** only that log is harvested
    (more than `tree-max-logs` 256 is not a tree): air or a sapling there, the hut stays.
11. [partly automated: `HarvestGateTest.cropsMustBeRipeAndTheCooldownHolds`; by hand: the crop in game]
    As Member, break an unripe wheat in Field. **Expected:** refused, "it isn't ripe yet". Break a ripe one.
    **Expected:** no vanilla drop, the wheat is replanted small at once, the share (wheat) arrives; after 60 s it is ripe
    again.
12. [partly automated: `RegenQueueTest.surveysSeeTheOriginalMeanwhile`, `HarvestModuleTest.aQualifiedBreakIsHarvestedAndPaidWhenTheApiAnswers`;
    by hand: the survey]
    Mine ten stones in Pit, then at once type `/knk production survey <Quarry id>`. **Expected:** the survey's
    `BLOCK:STONE` count is the same as before the mining: blocks waiting to regenerate count as stone (§ 3.2, L12).
13. [automated: plugin scenario `player-harvest-regenerate` (a module restart), `RegenQueueTest.jobsSurviveARestart`,
    `HarvestModuleTest.jobsReportsAndSharesSurviveARestart`]
    Mine three stones, then restart the server within 60 s. **Expected:** the startup line "Player harvesting is on
    (production.enabled): 3 blocks waiting to regenerate, …"; the stones come back on time after the restart. (§ 7)
14. [partly automated: `RegenQueueTest.anUnloadedChunkWaitsUntilItLoads`, `RegenQueueTest.aFelledTreeComesBackWholeOnlyWhenEveryChunkIsLoaded`;
    by hand: the chunk unload]
    Mine a stone, then fly more than 20 chunks away (or log out alone) so Pit's chunks unload, and come back after 2
    minutes. **Expected:** `/knk production harvest status` showed the job waiting for its chunk while you were away; the
    stone is back as soon as the chunk loads. (§ 7)
15. [automated: `RegenQueueTest.aPlayerInTheBlockPostponesTheRestore`, `RegenQueueTest.aChangedBlockIsNeverOverwritten`]
    As Staff (who may build in Pit), put a dirt block where a harvested stone's bedrock is. **Expected:** when it is due
    the dirt stays and the job is dropped (a changed block is never overwritten). Then, with a rule whose placeholder is
    Air (a flower), stand in a harvested flower's spot when it is due. **Expected:** the flower does not come back while
    you stand there and is back within 5 s after you step away. (§ 7)
16. [partly automated: `HarvestGateTest.aSwitchedOffStructureOrAnEmptyPoolRefuses`; by hand: the pool and production]
    Set Pit's pool to 0 (`PUT api/ResourcePools/<id>` current 0) and mine a stone. **Expected:** with
    `deny-at-empty-pool: false` the harvest is booked and the Quarry produces at its floor (§ 9.1 step 11); with
    `deny-at-empty-pool: true` (restart) refused with "Quarry is exhausted for now; come back later".
17. [automated: `HarvestModuleTest.aFailedReportIsSentAgainWithTheSameKey`, `HarvestOutboxTest.anEntryWithoutAnswerIsSentAgainWithTheSameKeyAfterAPause`]
    Stop the API, mine two stones, wait 20 s, start the API. **Expected:** no share while the API is down (status:
    entries waiting); after the API is back the share arrives once; `api/PlayerHarvests` has one harvest per key.
18. [automated: `HarvestModuleTest.anOfflinePlayersShareWaitsUntilTheyJoin`]
    Stop the API, mine a stone, log out, start the API, wait 10 s and log in. **Expected:** the share arrives about 2 s
    after joining.
19. [automated: `HarvestModuleTest.aRejectedEntryPaysNothing`]
    Switch Quarry stone off (`PUT api/HarvestRules/{id}` with `enabled: false`) and mine a stone at once (before the next catalogue read). **Expected:** "Your
    harvest at Quarry was not booked: …", no share; the stone still regenerates. After `/knk production harvest
    refresh` stone is no longer a harvest (WorldGuard refuses Member as before).
20. [partly automated: `HarvestModuleTest.withTheApiFlagOffBreaksBehaveAsBefore`, `HarvestModuleTest.a409DropsTheReportAndPaysNothing`;
    by hand: the API setting]
    Turn the API's `Production:Enabled` off and type `/knk production harvest refresh`. **Expected:** "… (the API's flag
    is off)"; Member's breaks in Pit are refused by WorldGuard as before; nothing is reported. Turn it on again. (A21)
21. [by hand]
    As Member, kill a cow in Field. **Expected:** no vanilla drops; one harvest under Cows; the share (the rule's
    blueprint) arrives. As Visitor, hit a cow in Field: **Expected:** refused with the reason.
22. [by hand]
    Set `production.enabled: false` and restart. **Expected:** no "Player harvesting is on" startup line; breaks in Pit
    and Forest behave exactly as before this link (WorldGuard and the global-region protection decide, vanilla drops);
    `/knk production harvest status` says production is off; the files in `plugins/KnightsAndKings/production/harvest/`
    are left alone. (A21)

## 10. Phase P9: town logistics (#127 API, #686 web app; tier:3)

Built so far: link L23, the API (knk-web-api, migration `AddTownLogistics`; in `next`), and link L24, the web app
(knk-web-app branch `claude/production-p9b`, PR into `next`; § 10.2): the policy and rule editor, the planner dry-run
view, the town supply view, the consumer and warehouse panels. § 10.1 runs with a REST client (or Swagger) against the
API. 24 steps in § 10.1: 21 automated in
CI and 3 partly (tagged); every step can still be run by hand; not run. Full manual run about 50 minutes (most of it
setting up stock and waiting for trips, or `POST api/TransportOrders/run-now`); the untagged parts about 15 minutes.
The tests are in knk-web-api `Tests/.../Services/Logistics/LogisticsPlannerTests.cs`, `LogisticsPolicyTests.cs`,
`Migrations/AddTownLogisticsTests.cs` and, with `KNK_TEST_MYSQL`, `MySql/LogisticsMySqlTests.cs` (four planner runs of
one town racing make one reservation and one collection order). Tier:3; the developer's waiver of the smoke gates
(2026-11-19) is read by the coordinator as covering the later links.

How it works, in short ([TOWN_LOGISTICS](../specs/production-storage-transport/TOWN_LOGISTICS.md) § 2-5): a
**consumer** is a structure with an Input or Merchandise storage. A **replenishment setting** gives a consumer storage
a min (reorder point) and max (target level) per blueprint. Every 10 minutes per town (and on demand) the **planner**
finds the consumer lines at or below their min (stock plus what is on the way), serves them by **priority class**
(Critical, High, Normal, Low) and then by road distance, and **reserves** up to the max at the warehouse of the
consumer's **service area** (else the nearest one with stock). **Reserves** (saving rules, in units or days of cover,
town-wide or per warehouse) are never reserved. The consumer's **own worker** collects the reservation as a transport
order with origin Distribution (P5), so its output drops while the worker is away. A reservation not collected within
30 minutes is released at the next run. Every decision has an explanation. The rules sit in a **versioned policy** per
town (a save is a new version); admins keep **default templates** per town size and specialization and apply them.

### 10.0 Preconditions

1. knk-web-api with the migrations up to `AddTownLogistics` applied (`dotnet ef database update`), `Production:Enabled`
   on except in step 5.
2. Everything of § 6.0: Phoenix with the rural warehouses **North** and **South** (note their delivery storages), the
   rural **Quarry** with its road connection `Connected`, a **Staff** token (`knk.admin.world`, `knk.economy.admin`), a
   **Visitor** token and the plugin key. Blueprints **Coal** (used as "flour" below) and **Iron ore** ("bread"), storage
   weight 1.
3. Two consumers in Phoenix's district **Market**: production structures **Bakery** and **Garrison** (`POST
   api/ProductionStructures` with `"districtId": <Market>`, a street and house number), two workers each, no lines. Give
   each an Input storage: `POST api/Storages` with `{ "name": "Bakery inputs", "kind": "Domain", "domainId": <Bakery>,
   "purpose": "Input", "maxUnits": 500 }` (and the same for Garrison). Note both storage ids.
4. Lanes (`POST api/TransportLanes`): Bakery → North 431.7 blocks (100 s at the default walking speed), Bakery → South
   863.4, Garrison → North 431.7, Garrison → South 215.85.
5. Put stock into a warehouse with `POST api/StockTransactions/adjust` (`knk.economy.admin`). Between steps, empty what
   a step left behind the same way, or release open reservations (step 20), so each step starts from the numbers it
   names.

### 10.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms and pages in the web app]
   As Staff, import the form and display seeds `LogisticsPolicy`, `ConsumerReplenishment`, `LogisticsRule`,
   `LogisticsReservation` and `LogisticsPlannerRun` with "make default". **Expected:** all import; the
   ConsumerReplenishment form asks for the storage, blueprint, min, max, priority class and the switch; the rule,
   reservation and planner run forms are read only; the planner run page lists its plan explanation. (A23)
2. [automated: `AddTownLogisticsTests.TheLogisticsSettings_HaveTheirDefaults_AndAreChecked`]
   `GET api/GameSettings`. **Expected:** the production section's `logistics`: `plannerIntervalMinutes` 10,
   `reservationMinutes` 30, `consumptionWindowDays` 7, `defaultReorderHours` 4, `defaultTargetHours` 12,
   `runRetentionDays` 14. A save without the `logistics` section keeps it; `plannerIntervalMinutes: 0` is 400.
3. [automated: `LogisticsPolicyTests.ReplenishmentSettings_AreForConsumerStoragesOnly_OnePerBlueprint`]
   As Staff, `POST api/ConsumerReplenishments` with `{ "storageId": <Bakery inputs>, "itemBlueprintId": <Coal>,
   "reorderPoint": 20, "targetLevel": 60 }`. **Expected:** 201 with `structureId` = Bakery and `priorityClass` null.
   The same storage and blueprint again is 409; North's delivery storage or Bakery's Output storage as `storageId` is
   400 ("Input or Merchandise"); `reorderPoint` 9 with `targetLevel` 5 is 400.
4. [automated: `LogisticsPolicyTests.OnlyTheV1RuleTypes_AndEachRuleIsChecked`]
   `POST api/LogisticsPolicies` with `{ "name": "Phoenix logistics", "scope": "Town", "townId": <Phoenix>, "rules": [ {
   "type": "Ceiling" } ] }`. **Expected:** 400 naming the V1 types and "Later, #324". Also 400: a Reserve without
   `units` or `daysOfCover`, a warehouse Reserve without `warehouseId`, `priorityClass` "Urgent", a ServiceArea without
   `areaKind` or with a district of another town, a Replenishment rule with min above max, `activeUntil` before
   `activeFrom`. Nothing is saved.
5. [automated: `LogisticsPlannerTests.WithTheFlagOff_TheDryRunWorks_ButNothingRuns`]
   Turn `Production:Enabled` off. Put 100 Coal into North. `POST api/Logistics/towns/<Phoenix>/dry-run`.
   **Expected:** 200, `featureEnabled` false, `dryRun` true, the entry for Bakery inputs and Coal `Reserved` 60 at
   North; nothing is written (no reservation, order or run). `POST api/Logistics/towns/<Phoenix>/run-now` is 409
   `ProductionDisabled`; the supply view's `nextRunAt` is null. Turn `Production:Enabled` back on. (A21)
6. [automated: `LogisticsPlannerTests.AConsumerAtItsReorderPoint_GetsAReservation_AndItsOwnWorkerCollectsIt`]
   `POST api/Logistics/towns/<Phoenix>/run-now`. **Expected:** 200 with a `runId`; Bakery's Coal entry `Reserved`,
   shortfall 60, reserved 60, warehouse North, the explanation names "replenishment setting #<id>". `POST
   api/LogisticsReservations/search` with `townId` lists one `Open` reservation of 60 at North's delivery storage for
   Bakery inputs. North still holds 100 Coal (a reservation holds stock without moving it). `POST
   api/TransportOrders/search` with `origin` Distribution lists one order: source North's delivery storage, carrier
   Bakery, one stop Bakery inputs with 60 Coal; the reservation names it. (A17)
7. [automated: `LogisticsPlannerTests.AReservationCantBeTakenTwice_ASecondRunSeesItWaiting`]
   `run-now` again. **Expected:** the entry is `AlreadyReserved` ("An open reservation is waiting for its worker"); still
   one reservation and one Distribution order. (A17)
8. [automated: `LogisticsPlannerTests.AConsumerAtItsReorderPoint_GetsAReservation_AndItsOwnWorkerCollectsIt`]
   `POST api/TransportOrders/run-now`. **Expected:** the collection order is `InTransit`; Bakery's `workersPresent` is
   1; North holds 40 Coal. After 100 seconds `run-now` again: `Delivered`, Bakery inputs hold 60 Coal, Bakery's
   `workersPresent` is 2. The ledger reconciles (`GET api/StockTransactions/reconcile` clean). (A17)
9. [automated: `LogisticsPlannerTests.TheWorkerAway_LowersTheConsumersOutput_LikeAProducers`]
   Give Bakery a Configured line (Cobblestone, 60 per hour) and its lane to North 25,920 blocks (100 minutes), empty
   Bakery inputs and repeat steps 6 and 8 up to the departure. Wait an hour of game time (or `POST
   api/Production/run-now` an hour later). **Expected:** Bakery's newest cycle record has `workerFactor` 0.5 while its
   worker is away (DESIGN § 7.7). (A17)
10. [automated: `LogisticsPlannerTests.AConsumerAtItsReorderPoint_GetsAReservation_AndItsOwnWorkerCollectsIt`]
    After the delivery of step 8, `run-now` 10 minutes later. **Expected:** the result's `collected` lists the
    reservation; it is `Collected` with `collected` 60 and no open key; the Coal entry is `NotNeeded` (60 is above the
    min). (A17)
11. [automated: `LogisticsPlannerTests.ARunStoresItsExplanation_ADryRunWritesNothing`]
    With 100 Coal in North, Bakery inputs empty and Garrison inputs holding 50 Coal (setting min 0, max 10), `run-now`
    and `GET api/LogisticsPlannerRuns/<runId>`. **Expected:** trigger `Manual`, `demandLines` 1, `reservationsCreated` 1,
    `ordersCreated` 1, `shortfalls` 0; one entry (lines above their min are not stored): Bakery, Coal, North,
    `Reserved`; the explanation reads "min 20, max 60", "short 60; Normal priority (the default)", "Reserved 60 of 60 at
    North" and "collected by its own worker"; the summary "1 reserved (60 units) in 1 collection order(s)". (A17)
12. [automated: `LogisticsPlannerTests.ATownReserve_IsNeverBreached_AndTheRestGoesToTheNextConsumer`]
    With 100 Coal in North and settings 20/60 for both Bakery and Garrison, `POST api/LogisticsPolicies` with `{ "name":
    "Phoenix logistics", "scope": "Town", "townId": <Phoenix>, "rules": [ { "type": "Reserve", "itemBlueprintId": <Coal>,
    "units": 70, "reason": "Keep some back" } ] }`, then `run-now`. **Expected:** 30 reserved in all (100 − 70); the
    consumer that got nothing is `HeldByReserve` and its explanation names "town reserve 70 (rule #<id>)"; the plan's
    `policySource` is `Town`. Another run 10 minutes later still holds 30 in all.
13. [automated: `LogisticsPlannerTests.AReserveInDaysOfCover_UsesTheAverageDailyOutflow`]
    Put 170 Coal into North, then take 70 out again (adjust −70: 10 a day over the 7-day window). Replace the policy's
    rule with `{ "type": "Reserve", "itemBlueprintId": <Coal>, "daysOfCover": 3 }` (step 14) and set both consumers to
    20/50. Dry run, then `GET api/Logistics/towns/<Phoenix>/supply`. **Expected:** 70 reserved in all (100 − 30); the
    supply line for Coal has stock 100, `reserveUnits` 30, `available` 70, `outflowPerDay` 10, `daysOfCover` 10, and a
    line per warehouse.
14. [automated: `LogisticsPolicyTests.ASave_MakesANewVersion_TheOldOneStaysForTheHistory`]
    `PUT api/LogisticsPolicies/<v1>` with `{ "reason": "Bread reserve 14 days", "rules": [ { "type": "Reserve",
    "itemBlueprintId": <Iron ore>, "daysOfCover": 14 }, { "type": "Reserve", "itemBlueprintId": <Coal>, "units": 50 } ]
    }`. **Expected:** 200 with version 2 (current, `basedOnPolicyId` v1, the reason), rules numbered 1 and 2; `GET
    api/LogisticsPolicies/<v1>` is no longer current, names v2 as `supersededByPolicyId` and still has its one rule;
    `GET api/LogisticsPolicies/<v1>/versions` lists 2 then 1. `PUT` on v1 again is 409 ("not the current version"); a
    second town policy for Phoenix is 409; the dry run uses v2 (`policyVersion` 2).
15. [automated: `LogisticsPlannerTests.UnderScarcity_TheHigherClassIsServedFirst`]
    With 50 Coal in North, settings 20/60 for both consumers and a town rule `{ "type": "PriorityClass", "structureId":
    <Garrison>, "priorityClass": "Critical" }`, `run-now`. **Expected:** Garrison `Critical`, `PartlyReserved` 50;
    Bakery `Normal`, `HeldByReserve` 0 with "50 already reserved" in its explanation; Garrison is listed first. Setting
    Garrison's replenishment `priorityClass` to Low makes the setting win over the rule. (A17)
16. [automated: `LogisticsPlannerTests.AWarehousesLocalReserve_SendsTheConsumerToAWarehouseThatCanCoverIt`,
    `LogisticsPolicyTests.AWarehousePolicy_HoldsLocalReservesForItsWarehouse`]
    With 100 Coal in North, 50 in South and Bakery at 0/40, add a warehouse reserve (in the town policy: `{ "type":
    "Reserve", "scope": "Warehouse", "warehouseId": <North>, "itemBlueprintId": <Coal>, "units": 90 }`, or as a
    warehouse policy `{ "scope": "Warehouse", "warehouseId": <North>, ... }`). Dry run. **Expected:** Bakery is
    `Reserved` 40 at South (North can spare only 10); the explanation names "local reserve 90". A warehouse policy only
    takes local reserves and service areas (a PriorityClass rule in it is 400).
17. [automated: `LogisticsPlannerTests.AServiceArea_ChoosesTheWarehouse_AndTheNearestStepsInWhenItHasNone`]
    With 100 Coal in each warehouse and Bakery at 0/40, a town rule `{ "type": "ServiceArea", "areaKind": "District",
    "districtId": <Market>, "warehouseId": <South> }`, dry run. **Expected:** Bakery is served from South (North is
    nearer), "its service area (rule #<id>)". Empty South: served from North. `GET
    api/Logistics/towns/<Phoenix>/service-areas`: Market → South (`Rule`), the rural territory `Nearest`, Quarry →
    North (nearest by road).
18. [automated: `LogisticsPlannerTests.AProducersServiceArea_IsItsInboundPreference`]
    With a town rule `{ "type": "ServiceArea", "areaKind": "Rural", "warehouseId": <South> }`, Quarry's automatic
    transport on and 80 Cobblestone in its Output, `POST api/TransportOrders/run-now`. **Expected:** the automatic order
    goes to South (without the rule: North, § 6.1).
19. [automated: `LogisticsPlannerTests.TheWorkersCapacity_BoundsTheCollection_OneOrderCarriesSeveralLines`]
    With 100 Coal and 100 Iron ore in North and Bakery at 0/50 for both, `run-now`. **Expected:** one collection order
    with 50 Coal and 14 Iron ore (the worker carries 64 by default); Iron ore `PartlyReserved` with "carries at most 64".
20. [automated: `LogisticsPlannerTests.StaffRelease_CancelsTheReservationAndItsOrder_OnlyBeforeLoading`]
    With two open reservations (Bakery and Garrison), `POST api/LogisticsReservations/<Bakery's>/release` with `{
    "reason": "test" }`. **Expected:** `Cancelled`, its order `Cancelled`, the status reason names the user and "test";
    releasing it again is 409. After `POST api/TransportOrders/run-now` loads Garrison's order, releasing Garrison's is
    409 ("already loaded").
21. [automated: `LogisticsPlannerTests.AReservationNotCollectedBeforeItsExpiry_IsReleasedAtTheNextRun_AndItsOrderCancelled`]
    Set Bakery's `workersPresent` to 0 (`PUT api/ProductionStructures/<Bakery>/workers`), 100 Coal in North, Bakery at
    20/60, `run-now`. **Expected:** the planned order warns "No worker of Bakery is free now" and waits (`Planned`). A
    run 20 minutes later releases nothing; a run 31 minutes after the first lists one released reservation ("Not
    collected within 30 minutes … (F11)"), its order is `Cancelled`, and the same run reserves again (a new open
    reservation). North still holds 100 Coal; the ledger reconciles.
22. [automated: `LogisticsPlannerTests.WithoutSettings_MinAndMaxComeFromTheLinesInputs`,
    `LogisticsPlannerTests.ARuralConsumerWithoutARoad_IsHeld_AndNoStockIsSaid`,
    `LogisticsPolicyTests.ARuleOutsideItsWindow_DoesNotApply_AndAReplenishmentRuleSetsDefaultsForAGroup`]
    Without a replenishment setting, give Bakery a line that consumes 2.5 Coal per hour; dry run and `GET
    api/Logistics/consumers/<Bakery>`. **Expected:** min 10, max 30 (4 and 12 hours of input), `settingSource`
    `Inputs`. A town Replenishment rule for Bakery (min 5, max 25) gives `Rule`; a setting gives `Setting` (the setting
    wins, then the rule, then the inputs). A rule with `activeFrom` tomorrow does not apply. A rural consumer
    without a road connection is `NotConnected`; with no Coal anywhere a line is `NoStock`.
23. [automated: `LogisticsPolicyTests.ADefaultTemplate_IsUsedWithoutATownPolicy_AndApplyingOneCopiesItsRules`]
    Delete Phoenix's policy (`DELETE api/LogisticsPolicies/<id>`, every version goes). `POST api/LogisticsPolicies` with
    `{ "name": "Farming village", "scope": "Template", "specialization": "Crops", "townSize": "Village",
    "isDefaultTemplate": true, "rules": [ { "type": "Reserve", "itemBlueprintId": <Coal>, "units": 80 } ] }` and a
    second default template "Mining town" (specialization Ore, reserve 90). **Expected:** only Mining town is the
    default now; a template with a service area is 400. A dry run uses it (`policySource` `DefaultTemplate`). `POST
    api/LogisticsPolicies/<Farming village>/apply` with `{ "townId": <Phoenix> }` makes Phoenix's policy v1 with its
    rule ("From template \"Farming village\" v1"); applying Mining town makes v2; the dry run now says `Town`.
24. [partly automated: `LogisticsPlannerTests.TheSchedule_PlansEachTownWithAWarehouseEvery10Minutes_AndPrunesOldRuns`,
    `LogisticsPolicyTests.TheRoutes_CarryTheirAccessRules`, `Results_MapTo400_404_And409WhileOff`, the pinned
    `ReadAccessRulesTests`, `DashboardChangeAccessRulesTests`, `DeleteAccessRulesTests`, with `KNK_TEST_MYSQL`
    `LogisticsMySqlTests.RacingRuns_ReserveOnce_AndMakeOneCollectionOrder`; by hand: wait for the schedule on a running
    API] With `Production:Enabled` on, leave the API running 25 minutes and `POST api/LogisticsPlannerRuns/search` with
    `townId` Phoenix. **Expected:** `Scheduled` runs about 10 minutes apart (a town without a warehouse gets none); the
    supply view's `nextRunAt` is the last run + 10 minutes. With the Visitor token, every logistics read and write is 403;
    a write without a token is 401. (A17, A21)

### 10.2 Steps (web app #686)

Built in link L24 (knk-web-app, branch `claude/production-p9b`, PR into `next`). The tags name tests in knk-web-app
`e2e/logistics.spec.ts` (Playwright, mocked API; the mocks use Phoenix with the warehouses North and South, the
consumers Bakery and Garrison in Market with their Input storages, Coal and Iron ore, Phoenix's policy v2 with a town
reserve of 70 Coal and a Critical Garrison, the template "Farming village", reservation 600 with its collection order
710 and planner run 300) and the Jest tests next to the code (`src/utils/__tests__/logistics.test.ts`,
`src/apiClients/__tests__/logisticsClients.test.ts`). Extra preconditions: § 10.0 and § 10.1 steps 1-3 (the seeds
imported with "make default", Bakery's replenishment setting), so the pages below have real rows; for step 21
`Production:Enabled` on. Log in to the web app as **Staff** (holds `knk.admin.world`, `knk.admin.delete` and
`knk.admin.config`) unless a step says otherwise. 22 steps: 18 automated, 3 partly (tagged), 1 by hand (step 21);
every step can still be run by hand; not run. Full manual run about 45 minutes; the untagged parts about 20 minutes
(most of it waiting for the scheduled planner and a collection trip, or `POST api/TransportOrders/run-now`).

1. [partly automated: `a town's logistics › shows the supply per item across the warehouses, the reservations, the
   policy and the runs (A17, #65)`; by hand: compare with the API] Put 100 Coal into North and make the town reserve
   of § 10.1 step 12, then run the planner once (step 4). Open Phoenix's page (`/display/Town/<Phoenix>`).
   **Expected:** below the territory panel a **Town logistics** panel: Policy in force "the town's policy (#<id>)"
   linking to the policy's page; Warehouses "North, South" (each linked); Last run with its time, trigger and summary
   (linked to the run's page); Next run (the last run + 10 minutes); a **Low supply** box for items with nothing
   available or under 3 days of cover. A **Supply** table per item: Stock, Held by reserves, Reserved, Available, In /
   day, Out / day, Days of cover ("No outflow" without outflow) and By warehouse ("North: 100 (available 0); South: 0
   (available 0)"). **Open reservations** (reservation, consumer, item, collected of amount, warehouse, status with
   priority, expiry, collection order linked, Release). **Service areas** (each district, the rural territory and each
   structure with the warehouse that serves it and "Service area rule #<id>" or "Nearest by road"). **Recent planner
   runs** (the last five, linked). By hand: the numbers match `GET api/Logistics/towns/<Phoenix>/supply` and
   `.../service-areas`. (A17)
2. [automated: `a town's logistics › without knk.admin.world the panel is not shown and nothing is read`] Log in as a
   staff member who can open towns but lacks `knk.admin.world` (for example a road manager with `knk.admin.road`) and
   open Phoenix's page. **Expected:** no Town logistics panel; the browser's network tab shows no `api/Logistics`
   request.
3. [automated: `a town's logistics › a dry run explains every consumer line, why the bakery got nothing, and writes
   nothing (A17)`] With the data of § 10.1 step 15 (50 Coal in North, both consumers at 20/60, Garrison Critical),
   press **Dry run** on Phoenix's panel. **Expected:** "Dry run: nothing was written. Policy: Phoenix logistics v<n>
   (the town's policy)."; the plan's summary and warnings (with production off: the dry-run warning); **Consumer
   lines** in the order the planner served them, Garrison first: each with the consumer (linked), its storage, the
   item, the outcome in words ("Partly reserved", "Held by a reserve", "Not needed", "No stock", "No worker", ...), a
   line "<class> priority · stock <n> (with what is on the way) · min <n>, max <n> from its replenishment setting ·
   short <n> · reserved <n> at North · rules #<ids>" and the planner's own explanation; **Collection orders** ("Garrison
   collects from North with its own worker (2 of 2 present, carries up to 64 units)" with "30 × Coal"). "Only the lines
   that didn't get everything" hides the lines that got what they needed. By hand: `POST
   api/LogisticsReservations/search` with `townId` lists no new reservation (nothing was written). (A17)
4. [automated: `a town's logistics › Run the planner now stores a run and reads the town again; the API's refusal is
   shown`, `a town's logistics › while production is off Run now is off and no run is scheduled`] With
   `Production:Enabled` on, press **Run the planner now**. **Expected:** "Run #<id> stored." (linked) and the plan
   below it; the supply, reservations and runs are read again. With `Production:Enabled` off (restart the API):
   **Expected:** Next run says "Production is off: no scheduled runs (a dry run still works)", Run the planner now is
   off and Dry run still works; a 409 from the API is shown as its sentence. (A17, A21)
5. [automated: `a town's logistics › Release ends an open reservation with a reason; the API's 409 once loaded is
   shown`] With an open reservation (step 4), press **Release** on its row. **Expected:** a box "Releasing reservation
   #<id> ends it Cancelled with its collection order; ..." with a reason field; type "test" and press **Release now**:
   "Reservation #<id> released." and the row is gone. For a reservation whose order has loaded (after `POST
   api/TransportOrders/run-now`) the API's sentence is shown and nothing changes.
6. [automated: `a town's logistics › Apply a template copies its rules into the town policy (D-L3)`] Make the template
   "Farming village" of § 10.1 step 23 (or step 12 below). On Phoenix's panel press **Apply a template**. **Expected:**
   a list of the templates with their specialization, size, default flag and rule count; Apply to this town stays off
   until one is picked. Pick "Farming village", type a reason, press **Apply to this town**. **Expected:** "Template
   applied: Phoenix logistics is now v<n>."; the Policy in force link opens the new version with the template's rules.
   (D-L3)
7. [automated: `a policy › shows its rules, its version and every version (A23)`] Open Phoenix's policy (the link in
   step 1). **Expected:** a **Policy rules** panel below the details: For "Town: Phoenix" (linked), Version "v<n>
   (current) · based on #<id>", Saved, Reason; each rule as an editable row (its type, then only the fields that type
   uses, its active window and its reason), with "Saved as: <the API's one-line summary>"; Save as a new version is off
   while nothing changed; a **Versions** table newest first, each older version linked. (A23)
8. [automated: `a policy › a save sends the whole rule list with its reason and opens the new version (A23)`] On the
   current version pick **New rule** "Reserve (saving rule)" and press **Add the rule**. **Expected:** "Rule <n>: pick
   the blueprint." under the rules and Save stays off. Pick Iron ore, Keep "Days of cover", 14, reason "Bread for two
   weeks"; move the rule up with its arrow; type "Bread reserve 14 days" as the reason for this version and press
   **Save as a new version**. **Expected:** the page of the new version opens with "Saved as version <n+1>."; the
   rules are in the new order; the old version is in Versions. By hand: `GET api/LogisticsPolicies/<old>` is no longer
   current. (A23)
9. [automated: `a policy › a service area and a refused save: the API's sentence is shown`] Add a **Service area**
   rule. **Expected:** "pick the district" and "pick the warehouse that serves it" listed. Pick the district Market and
   a warehouse of another town, save. **Expected:** the API's sentence ("Rule <n>: warehouse <id> is not a warehouse of
   this town.") and the edit stays. Pick South instead and save: a new version; step 1's Service areas table shows
   "District Market · South · Service area rule #<id>".
10. [automated: `a policy › a superseded version is read only and links to the next one`] Open an older version from
    Versions. **Expected:** "This version was replaced on <date>; it is kept for the history and can't be edited. Next
    version: #<id>." (linked); the rules as a numbered list of summaries; no New rule or Save.
11. [automated: `a policy › a template sends its specialization, size and default flag, and applies to a town
    (D-L3)`] Open the template "Farming village". **Expected:** For "Template: Crops, Village (default)"; the
    Specialization, Town size and default fields; New rule offers Reserve, Priority class and Replenishment defaults
    only (a template has no service areas); an **Apply to a town** box (pick Phoenix, Apply the template: "Applied:
    Phoenix logistics v<n>." linked). Change Town size to Town and save: the new version keeps Crops and the default
    flag. (D-L3)
12. [partly automated: `the Town logistics page › lists the policies and templates, filters them, and opens a town
    (A23)`; by hand: the seeded form] In the admin sidebar (group World) open **Town logistics** and press **New policy
    or template**. **Expected:** the seeded LogisticsPolicy form; make a template "Mining town" (scope Template,
    specialization Ore, size Town, default on): it is saved without rules and its page opens; add a Reserve of 90 Coal
    there and save (v2). By hand: the dashboard's LogisticsPolicy list shows it; editing the name in the seeded form
    makes a new version that keeps the rules. (G17, A23)
13. [automated: `the Town logistics page › lists the policies and templates, filters them, and opens a town (A23)`]
    On **Town logistics** (`/admin/logistics`). **Expected:** a table of policies (name linked, For, Version, Rules,
    Saved, Reason), current versions only; **For** narrows to town, warehouse or template policies and **Versions** adds
    the superseded ones; links to consumer settings, reservations, planner runs and all rules on the dashboard; pick
    Phoenix under "A town's supply and planner" and press **Open the town**: Phoenix's page with its Town logistics
    panel. (A23)
14. [automated: `a consumer's supply › shows its demand with where each min and max came from, its workers and its
    warehouse (A17)`] Open Bakery's page (`/display/ProductionStructure/<Bakery>`). **Expected:** a **Supply (as a
    consumer)** panel: warnings (a worker away); Collected by "Its own workers: <present> of <total> present, each
    carries up to 64 units"; Served by its warehouse (linked) and where that came from; a link to the town's logistics;
    **Demand** per Input or Merchandise storage: per item Stock, On the way, Min, Max, Priority and "Min and max from"
    (its replenishment setting, a Replenishment rule, or its line inputs (4 h / 12 h)), lines at or below their min
    highlighted; the **Replenishment settings** table. (A17)
15. [automated: `a consumer's supply › adds a setting after checking it, edits one and deletes one`] Press **Add a
    setting**, keep the storage, pick Iron ore, min 30 and max 25. **Expected:** "The min is above the max." and Save
    the setting off. Min 5, priority High, **Save the setting**: "Setting for Iron ore saved." and the demand line now
    says "its replenishment setting". **Edit** Coal's setting (min 30), save; **Delete** it: "Setting for Coal deleted:
    the min and max come from a rule or the line inputs again." (Delete needs `knk.admin.delete`.)
16. [automated: `a consumer's supply › a structure without an Input or Merchandise storage is not a consumer`] Open the
    Quarry's page. **Expected:** "Not a consumer: it has no Input or Merchandise storage, ..." and nothing else in the
    panel.
17. [automated: `a warehouse's logistics › lists what it serves, its warehouse policy and its open reservations`] Open
    South's page. **Expected:** a **Logistics** panel: Warehouse policy (linked, or "None (the town's policy applies).
    Make a warehouse policy"), a link to the town; **Serves** (the areas from step 1 served by South); **Open
    reservations at this warehouse** with Release.
18. [automated: `a planner run and a reservation › a run's page lists its counts and the explanation of every line,
    with the reservation and order it made (A17)`] Open a run from Recent planner runs. **Expected:** below the details
    a **Plan explanation** panel: the town (linked), when and why it ran (Scheduled or Manual), the policy version
    (linked), "<n> lines at or below their min, <n> reserved, <n> orders, <n> released, <n> collected, <n> short", and
    each stored line as in step 3 with links to its reservation and collection order. (A17)
19. [automated: `a planner run and a reservation › a reservation's page says what is held for whom and releases it`]
    Open a reservation. **Expected:** a **Reservation** panel: status in words (with its reason once closed), "<collected>
    of <amount> <item> collected", the warehouse storage and the consumer storage (linked), made by run #<id>, the
    expiry, the collection order with its status, the planner's explanation, and **Release the reservation** while
    open (as in step 5; the status turns Cancelled and the order Cancelled).
20. [automated: `game settings › shows and keeps the logistics section on a save of another section, and checks a
    changed one`; Jest `logistics helpers › checks the logistics settings like the API and keeps them in the
    production section`] Open **Game settings** (`knk.admin.config`). **Expected:** a **Town logistics** card: planner
    interval 10, reservation expiry 30, consumption window 7, default min and max in hours of input 4 and 12, keep
    runs 14 (or the stored values); a save of another section sends the logistics section back unchanged. Set the
    default min to 20: "production.logistics.defaultReorderHours must be at most defaultTargetHours." and Save is off.
21. [by hand] With `Production:Enabled` on, Bakery inputs empty and 100 Coal in North (no reserve), wait for the
    scheduled planner (up to 10 minutes) and then `POST api/TransportOrders/run-now`. **Expected:** Phoenix's panel shows
    a Scheduled run with one reservation for Bakery; Bakery's panel lists it under Open reservations and its workers
    show one away; the collection order (linked from the reservation) is on the road (§ 6.3 step 3); after the trip the
    reservation is Collected and Bakery's demand line for Coal shows the stock. (A17)
22. [partly automated: `a town's logistics › a dry run explains every consumer line, why the bakery got nothing, and
    writes nothing (A17)`; by hand: the scarcity against the API] Make Coal scarce (§ 10.1 step 15: 50 Coal, both
    consumers at 20/60, Garrison Critical) and run a dry run. **Expected:** Garrison is listed first and gets 50
    ("Partly reserved"); Bakery is "Held by a reserve" with "50 already reserved" in its explanation. (A17)

### 10.3 Steps (API follow-ups #928, link L25b)

Built in link L25b (migration `AddTownLogisticsProfile`), merged into knk-web-api `next` 2026-11-21 (`e02bf557`). Same
preconditions as § 10.0 (with `AddTownLogisticsProfile` applied), a REST client and the Staff token. 5 steps, all
automated in CI (knk-web-api `Tests/.../Services/Logistics/LogisticsFollowUpsTests.cs`, `Api/LookupFiltersTests.cs`);
every step can still be run by hand; not run. Manual run about 15 minutes.

1. [automated: `LogisticsFollowUpsTests.ATownsProfile_StartsEmpty_AndSuggestsTheTemplateForItsSizeAndSpecialization`,
   `TheProfileEndpoints_Answer404ForAnUnknownTown_And400ForAnUnknownLabel`]
   Make three templates (`POST api/LogisticsPolicies`, `"scope": "Template"`, `"rules": []`): "General" (no labels,
   `"isDefaultTemplate": true`), "Village" (`"townSize": "Village"`) and "Farming village" (`"townSize": "Village",
   "specialization": "Crops"`). `GET api/LogisticsPolicies/towns/<Phoenix>/profile`. **Expected:** `townSize` and
   `specialization` null, `suggestedTemplateMatch` `Default` with General. `PUT` the same route with `{ "townSize":
   "Village", "specialization": "Crops" }`: `Exact`, Farming village. `PUT { "specialization": "Fish" }`: the size stays
   Village, `Size`, Village. `PUT { "townSize": "City" }`: `Default`, General. `PUT { "townSize": "", "specialization":
   "" }` clears both. `"townSize": "Metropolis"` is 400, an unknown town 404; nothing is applied to the town's policy.
2. [automated: `LogisticsFollowUpsTests.APutWithoutLabels_KeepsThem_AndAnEmptyStringClearsThem`]
   `PUT api/LogisticsPolicies/<Farming village>` with only `{ "reason": "Rules only", "rules": [] }`. **Expected:** the
   new version still has `townSize` Village, `specialization` Crops and its default flag as before. A `PUT` with
   `"specialization": ""` clears it (general); `"townSize": "City"` on a town policy is 400.
3. [automated: `LogisticsFollowUpsTests.ThePlannersReads_CarryTheStructureType_AndTheItemAndStorageNames`,
   `StructureTypes_NameTheMostSpecificType_AndSkipUnknownIds`, `AShop_IsNamedShop_NotProductionStructure`]
   Put 100 Coal into North and give Bakery inputs min 20, max 60 (§ 10.1 step 3). `POST
   api/Logistics/towns/<Phoenix>/dry-run`. **Expected:** the entry has `consumerStructureType` `ProductionStructure`;
   the order has `consumerStructureType`, `consumerStorageName` "Bakery inputs" and `warehouseStorageName` North's
   delivery storage. After `run-now`, `POST api/LogisticsReservations/search`, the planner run, `GET
   api/Logistics/consumers/<Bakery>` (`structureType`) and the service areas (`structureType` on structure entries) carry
   the type; a shop's is `Shop`, a warehouse's `Warehouse`.
4. [automated: same test as step 3]
   In the dry run of step 3, look at the order's `lines`. **Expected:** each line has `itemBlueprintName` (Coal) next to
   `itemBlueprintId` and `amount`; reservation rows have `consumerStorageName`, `warehouseStorageId` and
   `warehouseStorageName`.
5. [automated: `LogisticsFollowUpsTests.TheStorageSearch_FiltersByTown_ThroughItsDistrictsAndStructures`, the pinned
   `LookupFiltersTests.LookupFilters_ArePinnedPerType_AndNeverOnUsers` table]
   `POST api/Lookup/Storage/search` with `filters: { "townId": "<Phoenix>" }` (and the same for `ConsumerReplenishment`
   and `LogisticsRule`). **Expected:** only storages held by Phoenix, its districts or its structures (Bakery inputs,
   North's delivery storage, a rural structure's storages); Rivertown gives none of them. `Warehouse`, `District` and
   `Structure` already filter by `townId`.

## 11. Phase P10: shops (#248 API, #687 plugin menus, #688 web app; tier:3)

Built so far: link L25, the API (knk-web-api, migration `AddShops`), merged into `next` 2026-11-21 (knk-web-api
`289f4d4b`), and link L27, the web app pages (#688, § 11.3), merged into `next` 2026-11-21 (knk-web-app `11832d6b`).
The shop menus are link L26 (#687, knk-plugin, built from the legacy V1 shop menus by the developer's decision of
2026-11-21, § 11.2; not merged yet). Admins: [shops
admin guide](admin/shops-admin-guide.md); developers: [shops architecture](../architecture/shops.md). § 11.1 runs with a REST client (or Swagger) against
the API. 28 steps
in § 11.1: 25 automated in CI and 3 partly (tagged); every step can still be run by hand; not run. Full manual run
about 45 minutes; the untagged parts about 10 minutes. The tests are in knk-web-api
`Tests/.../Services/Shops/ShopTradingTests.cs`, `ShopSupplyTests.cs`, `ShopAdminTests.cs`,
`Migrations/AddShopsTests.cs` and, with `KNK_TEST_MYSQL`, `MySql/ShopsMySqlTests.cs` (two players racing for the last
units: one is charged; a purchase whose goods can't be taken rolls its payment back). Tier:3 (money); the developer's
waiver of the smoke gates (2026-11-19) is read by the coordinator as covering the later links.

How it works, in short ([shops DESIGN](../specs/shops/DESIGN.md) § 2-5, § 9.1): a **shop** is a structure with a
**Merchandise** and an **Input** storage, a **shop type** (its accepted categories and levels), a kind (**Trading** or
**Processing**), a level, a tax modifier and a buy-back percentage (default 50). In the API a shop is a production
structure underneath, so it has its own **worker** (restocking) and can run **processing lines** (Input → Merchandise)
on the production engine. Admins fill a **static catalogue**: a blueprint or one unique item, an optional static price,
Stocked (from Merchandise) or Unlimited (never sold out, the fallback before the supply chain is live). The **sell price**
is the static price, else the blueprint's midpoint base price × tax modifier × level price multiplier (a unique item
adds 10% of the base price per enchantment level). A **purchase** is confirmed by the player and runs in one database
transaction: the coins go from the player to the town's **town account** (currency `AccountKind.Town`), the goods leave
Merchandise. Players **sell** items of the accepted categories for sell price × buy-back %, paid from the town account;
a sold unique item is resold as that exact item. The town planner **restocks** a shop's stocked catalogue blueprints at
its level's default min/max with the shop's own worker. **Hourly trade stats** are rolled up from the ledger.

### 11.0 Preconditions

1. knk-web-api with the migrations up to `AddShops` applied (`dotnet ef database update`), `Production:Enabled` on
   except where a step turns it off.
2. Everything of § 10.0: Phoenix with district **Market** and the rural warehouses **North** and **South**, a **Staff**
   token (`knk.admin.world`, `knk.admin.content`, `knk.economy.admin`), a **Visitor** token and the plugin key.
3. Categories **Food** and **Weapons**, and **Swords** with Weapons as its parent (`POST api/Categories`).
   Blueprints: **Coal** ("flour", base price 4-6, category Food), **Iron ore** ("bread", base price 18-22, Food),
   **Diamond** ("sword", base price 90-110, Swords, max stack 1), **Cobblestone** (no base price). Storage weight 1.
4. Players **Ann** with 1000 coins and **Bob** with 50 coins (staff grants with `POST api/currency/admin/adjustments`,
   or the web app's balance editor). Note their user ids.
5. Put stock into storages with `POST api/StockTransactions/adjust` (`knk.economy.admin`). Between steps, empty what a
   step left behind the same way, so each step starts from the numbers it names.
6. The purchase and sale routes (`quote`, `purchase`, `sell-quote`, `sell`) take the plugin key: send them with
   `X-API-Key`, as the game server does after the player confirmed in the shop menu.

### 11.1 Steps (API)

1. [partly automated: knk-web-api `FormConfigurationSeedFilesTests`, `DisplayConfigurationSeedFilesTests` (every seed
   dry-runs and imports); by hand: open the forms and pages in the web app]
   As Staff, import the form and display seeds `ShopType`, `ShopTypeLevel`, `Shop`, `ShopCatalogueEntry`,
   `ShopTradeStat` and `TownAccount` with "make default" (in that order). **Expected:** all import; the Shop form has the
   placement steps of a warehouse plus the shop step (type, kind, level, tax modifier, buy-back %, workers, processing
   switch, hide sold out, shopkeeper spawn); the ShopTradeStat and TownAccount forms are read only; the Shop page lists
   its catalogue and the ShopType page its levels. (A23)
2. [automated: `AddShopsTests.TheShopSettings_HaveTheirDefaults_AndANullSectionKeepsTheStoredOne`,
   `ShopAdminTests.TheShopSettings_AreValidated`]
   `GET api/GameSettings`. **Expected:** the production section's `shops`: `enchantmentPercentPerLevel` 10,
   `statsLookbackHours` 2. A save without the `shops` section keeps it; `enchantmentPercentPerLevel: -1` is 400.
3. [automated: `ShopAdminTests.AShopType_HasAUniqueName_ItsCategories_AndCantBeDeletedWhileUsed`]
   As Staff, `POST api/ShopTypes` with `{ "name": "Bakery", "defaultKind": "Processing", "acceptedCategoryIds":
   [<Food>] }` and `{ "name": "Weaponsmith", "defaultKind": "Trading", "acceptedCategoryIds": [<Weapons>] }`.
   **Expected:** 201 each with `acceptedCategories` naming the category. A second "Bakery" is 409; an unknown category
   id or `defaultKind` "Bank" is 400. As Visitor the same call is 403.
4. [automated: `ShopAdminTests.ALevel_IsOncePerType_AndItsCapsReachTheShopsAtThatLevel`]
   `POST api/ShopTypeLevels` for Bakery: level 1 `{ "priceMultiplier": 1, "merchandiseMaxUnits": 200, "inputMaxUnits":
   300, "reorderPointUnits": 10, "targetUnits": 40 }` and level 2 `{ "priceMultiplier": 1.5, "cycleSpeedMultiplier": 2,
   "yieldMultiplier": 1.5, "inputCostMultiplier": 0.5, "merchandiseMaxUnits": 400 }`. **Expected:** 201 each. Level 1
   again is 409; `priceMultiplier` 0 or `targetUnits` below `reorderPointUnits` is 400.
5. [automated: `ShopTradingTests.AShop_GetsMerchandiseAndInputStorages_CappedByItsLevel_AndItsOwnWorker`]
   `POST api/Shops` with `{ "name": "Bakery shop", "districtId": <Market>, "streetId": <street>, "houseNumber": 9,
   "shopTypeId": <Bakery> }` and a rural `{ "name": "Weaponsmith", "townId": <Phoenix>, "shopTypeId": <Weaponsmith> }`.
   **Expected:** 201; Bakery shop is `Processing`, level 1, `workersTotal` and `workersPresent` 1, `effectiveTownId`
   Phoenix, `storages` a Merchandise (capped at 200) and an Input storage (300); Weaponsmith is `Trading`. `GET
   api/ProductionStructures/<Bakery shop>` shows `automaticTransport` false and `yieldSource` Configured. `PUT` with
   `"level": 2` raises the Merchandise cap to 400.
6. [automated: `ShopAdminTests.AShop_ValidatesItsPricingFields`]
   `PUT api/Shops/<Bakery shop>` with `buyBackPercent` 120, `taxModifier` 0 or `kind` "Bank". **Expected:** 400 each;
   `buyBackPercent` 25 saves (set it back to 50).
7. [automated: `ShopTradingTests.TheCatalogue_ListsABlueprintOnce_AndAUniqueItemOnce`]
   `POST api/ShopCatalogueEntries` with `{ "shopId": <Bakery shop>, "itemBlueprintId": <Iron ore> }`. **Expected:** 201,
   `stockMode` Stocked. The same blueprint again is 409. An entry with an `itemInstanceId` takes the instance's blueprint;
   the same instance in a second shop is 409; a unique item with `stockMode` Unlimited is 400.
8. [automated: `ShopTradingTests.TheOffer_ShowsEntriesAndMerchandise_WithPriceAndStock_SoldOutGreyedOrHidden`]
   Add a Coal entry with `"staticPrice": 9`; put 5 Iron ore and 1 Diamond into Bakery shop's Merchandise. `GET
   api/Shops/<Bakery shop>/offer`. **Expected:** town Phoenix, `buysFromPlayers` true; Iron ore 20 coins (Formula), stock
   5; Coal 9 coins (Static), `soldOut` true; Diamond 100 coins (no entry, from Merchandise). With `"hideSoldOut": true`
   on the shop, Coal is not listed. (A18)
9. [automated: `ShopTradingTests.AStaticPrice_Wins_AndTheLevelAndTaxModifiersApplyToTheFormula`]
   Set Bakery shop to level 2 and `taxModifier` 1.1. **Expected:** the offer shows Iron ore at 33 (20 × 1.1 × 1.5) and
   Coal still at 9. Set it back to level 1, tax 1. (A18)
10. [automated: `ShopTradingTests.BasePrice_IsTheMidpoint`, `ShopTradingTests.SellPrice_StaticWins_ElseFormulaRounded_AtLeastOne`]
    Check the price rule on the offer: a blueprint with base price 2-3 sells at 3 (2.5 rounded half away from zero), one
    with 0.1 at 1, one with no base price is not on offer. (A18)
11. [automated: `ShopTradingTests.APurchase_MovesCoinsToTheTownAccount_AndTheGoodsOutOfMerchandise_Together`]
    Put 10 Iron ore into Merchandise. With the plugin key, `POST api/Shops/<Bakery shop>/quote` with `{ "userId": <Ann>,
    "itemBlueprintId": <Iron ore>, "amount": 3 }`. **Expected:** `unitPrice` 20, `totalPrice` 60, `refusal` null.
12. [automated: `ShopTradingTests.APurchase_MovesCoinsToTheTownAccount_AndTheGoodsOutOfMerchandise_Together`]
    `POST api/Shops/<Bakery shop>/purchase` with the same body plus `"expectedUnitPrice": 20, "confirmed": true,
    "idempotencyKey": "buy-1"`. **Expected:** 200, `totalPrice` 60, `deliverTo` Inventory, `coinsAfter` 940; Merchandise
    holds 7; `GET api/TownAccounts/by-town/<Phoenix>` shows 60 coins and `reconciled` true; its `ledger` lists one
    SHOP_PURCHASE leg 0 → 60. The stock transaction has reason ShopSale, source Shop / <Bakery shop id>, actor Ann. (A18)
13. [automated: `ShopTradingTests.APurchase_IsIdempotent_OnItsKey`]
    Send step 12's purchase again. **Expected:** 200 with `replayed` true and the same transaction ids; Ann still has
    940 and Merchandise 7. The key with Bob as `userId` is 409 `IdempotencyKeyReuse`.
14. [automated: `ShopTradingTests.APurchase_IsRefused_WithoutTakingAnything`]
    As Bob: a purchase with `"confirmed": false` is 409 `NotConfirmed`; with `expectedUnitPrice` 19 409 `PriceChanged`;
    11 units 409 `NotEnoughStock`; 3 units (60 coins, Bob has 50) 409 `InsufficientFunds`. **Expected:** every time
    nothing moves: Bob 50, the town account and Merchandise unchanged. (A18)
15. [automated: `ShopTradingTests.ASoldOutItem_AndAnItemWithoutPrice_AreRefused`]
    Quote an entry with no stock, a Cobblestone entry (no price) and a blueprint the shop doesn't list. **Expected:**
    `refusal` SoldOut, NotForSale, NotForSale.
16. [automated: `ShopTradingTests.AnUnlimitedEntry_NeverSellsOut_AndWorksWhileProductionIsOff`]
    Turn `Production:Enabled` off. Add an entry Iron ore `"staticPrice": 15, "stockMode": "Unlimited"` to a shop without
    stock and buy 4. **Expected:** 200, 60 coins to the town account; the stock move is SYS_ADJUSTMENT → SYS_WORLD. With
    `"deliverTo": "Inbox"` the purchase is 409 `ProductionDisabled`. Turn it back on. (A21)
17. [automated: `ShopTradingTests.APurchaseToTheInbox_DeliversIt_ThroughP7`]
    Buy 2 Iron ore with `"deliverTo": "Inbox"`. **Expected:** 200 with an `itemDeliveryId`; `GET api/Inbox/<Ann>` holds
    the 2 Iron ore; Merchandise lost 2. A purchase that doesn't fit the inbox is 409 `InboxFull` and nothing moves.
18. [automated: `ShopTradingTests.SellingToAShop_PaysHalfTheSellPrice_FromTheTownAccount`]
    `POST api/Shops/<Bakery shop>/sell-quote` with `{ "userId": <Bob>, "lines": [ { "itemBlueprintId": <Iron ore>,
    "amount": 4 } ] }`. **Expected:** `unitPrice` 10 (half of 20), `total` 40, `accepted` and `townCanPay` true. Then
    `POST .../sell` with `"confirmed": true, "expectedTotal": 40, "idempotencyKey": "sell-1"`. **Expected:** Bob +40;
    the town account −40 (`reconciled` true); 4 Iron ore more in Merchandise (reason ShopBuyBack). The same request again
    is a replay. (A18)
19. [automated: `ShopTradingTests.AShop_RefusesCategoriesItDoesntBuy_AndAcceptsSubCategories`]
    Sell-quote a Diamond to Bakery shop and to Weaponsmith. **Expected:** Bakery shop: `CategoryNotAccepted`; Weaponsmith
    (buys Weapons, Diamond is in Swords under Weapons): 50 coins. A sale with an Iron ore line and a Diamond line at
    Bakery shop is 409 `CategoryNotAccepted` and nothing moves (all lines or none).
20. [automated: `ShopTradingTests.ASoldEnchantedItem_BecomesAStockUnit_AndIsResoldAsThatExactItem`]
    Create a Diamond item instance with Sharpness 2 and Unbreaking 1 (`POST api/ItemInstances`), not in any storage. Bob
    sells it to Weaponsmith (`"lines": [ { "itemInstanceId": <id> } ]`, `expectedTotal` 65). **Expected:** 65 coins
    (sell price 100 × 1.3 = 130, half); the instance is a stock unit in Weaponsmith's Merchandise with both
    enchantments; the offer lists that exact item at 130 with its enchantments. Ann buys it (`"itemInstanceId": <id>`,
    `expectedUnitPrice` 130): it leaves Merchandise and its owner is Ann; it is no longer on offer.
21. [automated: `ShopTradingTests.SellingNeedsProductionEnabled_AndATownThatCanPay_AndRoom`]
    With `Production:Enabled` off, `sell-quote` is 409 `ProductionDisabled`. On again: a sale while the town account
    can't pay is 409 `TownFundsInsufficient`; 201 Iron ore into a Merchandise capped at 200 is 409 `NoRoom`; nothing
    moves either time. (A21)
22. [partly automated: `ShopTradingTests.TheTownReasons_PostOnlyThroughATownAccount_AndCantBeReversed` (the service
    refuses with `NotReversible`); by hand: the HTTP status]
    As Staff, try `POST api/currency/admin/transactions/<the purchase's public id>/reverse` with a note of at least 10
    characters. **Expected:** 400 with `code` `NotReversible` (the currency routes answer this code with 400) (a town leg can't be reversed yet; a correction is a new shop posting). Postings with SHOP_PURCHASE
    through any other currency route are refused.
23. [automated: `ShopSupplyTests.AProcessingShop_TurnsFlourIntoBread_FromInputIntoMerchandise`]
    `POST api/ProductionLines` for Bakery shop: Iron ore at 10 per hour with the input Coal 20 per hour. Put 100 Coal
    into its Input storage. An hour later (`POST api/Production/run-now`). **Expected:** Merchandise +10 Iron ore, Input
    80 Coal; `GET api/ProductionStructures/<Bakery shop>/production` shows the Merchandise storage as the output; the
    ledger reconciles.
24. [automated: `ShopSupplyTests.TheShopLevel_SetsProcessingSpeedYieldAndInputCost`]
    At level 2 the same hour gives 15 Iron ore for 10 Coal (yield × 1.5, inputs × 0.5).
25. [automated: `ShopSupplyTests.ATradingShop_DoesntProcess_AndNothingRunsWhileProductionIsOff`,
    `ShopSupplyTests.WhileTheWorkerIsAway_ProcessingSlows_AndSellingGoesOn`]
    Make Bakery shop `Trading`: its line is `Paused` ("A trading shop doesn't process"). Back to Processing with two
    workers, one away (`PUT api/ProductionStructures/<Bakery shop>/workers`): the hour gives 5; buying still works. With
    `Production:Enabled` off nothing settles. (F6, A21)
26. [automated: `ShopSupplyTests.ARestock_IsReservedAtTheWarehouse_AndCollectedByTheShopsOwnWorker`,
    `ShopSupplyTests.AnAdminSetting_OverridesTheLevelDefault`]
    Lane Bakery shop → North 431.7 blocks; put 100 Iron ore into North; keep the Iron ore entry Stocked and Merchandise
    empty. `POST api/Logistics/towns/<Phoenix>/run-now`. **Expected:** the Merchandise / Iron ore entry is `Reserved` 40
    (level 1's default max) with `settingSource` ShopLevel; a Distribution order carried by Bakery shop. `POST
    api/TransportOrders/run-now`: the shop's `workersPresent` 0; 100 seconds later the 40 Iron ore are in Merchandise
    and the worker is back; the ledger reconciles. A consumer replenishment setting on the Merchandise storage (min 5,
    max 25) wins over the level default. (A17)
27. [automated: `ShopSupplyTests.TheHourlyStats_MatchTheLedger_AndARebuildIsIdempotent`,
    `ShopSupplyTests.TheStats_CountProcessingOutputAsSupply_AndTheJobWaitsForProduction`]
    After an hour with 5 Iron ore sold (Ann 3, Bob 2) and 1 bought back, wait for the job (every 10 minutes) or `POST
    api/ShopTradeStats/rebuild` with `{ "shopId": <Bakery shop>, "from": "<hour>", "to": "<hour + 2>" }`. **Expected:**
    `POST api/ShopTradeStats/search` with `shopId` shows one row for that hour: 5 sold, revenue 100, 1 bought back for
    10, 2 customers, average price 20, stock at the end 6, `townPlayerCount` null; no rows for the empty hours. A second
    rebuild gives the same row. Processing output counts as supplied. With `Production:Enabled` off the job writes
    nothing. (A18)
28. [partly automated: `ShopsMySqlTests` with `KNK_TEST_MYSQL`; by hand: the real game-server timing]
    Two players buy the last 3 units 2 each at the same moment. **Expected:** one purchase succeeds; the other is 409
    `NotEnoughStock` and that player keeps their coins; the town account holds one payment and is reconciled. (A18)

### 11.2 Steps (plugin #687)

Built in link L26 (knk-plugin, branch `claude/production-p10b`, not merged yet). The tags name tests in knk-plugin:
knk-core `core/production/shop/*Test` (JUnit), knk-api-client `ShopsApiImplTest`, knk-paper `ShopServiceTest`,
`SellModuleTest` (MockBukkit, a stand-in shops API with the bakery's bread, flour and a unique sword),
`ShopMenuSeedsTest` (the seeded menus of `content-seeds.json` against the plugin), `ShopAdminCommandTest`, and the
scenario `player-shop-sell-and-buy` (a real Paper server in CI's `paper-boot` job, a scripted player and a stand-in
shops API). Extra preconditions: § 11.0 and § 11.1 steps 1, 3-5 and 7 (Bakery with its catalogue: Bread as an
Unlimited entry at a static price, some Merchandise stock, the type accepting Food), the shop menu seeds imported (below),
the plugin with `production.enabled: true` and `items.identity.enabled: true` (selling needs item identity), the API's
`Production:Enabled` on, and a player **Ann** (with coins) who holds `knk.admin.world.production` for `/knk shop`. 16
steps: 5 automated, 10 partly (tagged), 1 by hand; every step can still be run by hand; not run. Full manual run about
30 minutes; the untagged parts about 15 minutes.

Admin step first: import the menu templates `shops.shop`, `shops.item` and `shops.confirm` (knk-web-api seeds them on
start; on an existing database they are created when missing, as every menu seed). Deploy the plugin before the API, or
the menus fail the plugin's validation.

The layouts are the legacy V1 shop menus (developer decision 2026-11-21 on #687; legacy
[inventory-menu-screens § 3.7](../specs/legacy/inventory-menu-screens.md)):

1. **Shop menu** (V1 "Products of X"), 6 rows: slot 0 Financial (your coins), 3 Sell chest (only when the shop buys),
   4 the shop's information (anvil), 8 Back; rows 2 to 5 the catalogue, paged with arrows in 45 and 53.
2. **Item information** (V1 item info), 1 row: 0 Financial, 3 Amount (chest), 4 the item, 5 the price (name tag),
   6 the description (map), 8 Back.
3. **Purchase confirmation** (V1 sale confirmation), 2 rows: 4 the confirmation (book), 8 Back, 10 Confirm to the reward
   inbox (ender chest), 12 Confirm (green terracotta), 13 the item, 14 Cancel (red terracotta).
4. **Sell menu** (V1 "Sell items to X"), 4 rows: 0 Financial, 3 Sell (chest, with the total), 4 the shop's information,
   5 how to sell (book), 8 Back; slots 19 to 25 hold the stacks you picked.

Steps:

1. [partly automated: `ShopServiceTest.open_readsTheOfferAndOpensTheShopMenu`, `ShopMenuSeedsTest.shopMenu_keepsTheLegacyHeaderAndPagesTheCatalogue`,
   `ShopAdminCommandTest.opensTheShopForAPlayer`; by hand: the real menu] As Ann type `/knk shop <Bakery id>`.
   **Expected:** "Opening shop #<id>..." and the shop menu: Financial shows Ann's coins; the anvil "Information about
   Bakery" lists Type Bakery, Kind, Level, Town Phoenix and "Buys items from players"; the catalogue shows each item as
   the real item with "Price: <n> coins each", "Stock: plenty" (Unlimited) or the number, and "Click here for more
   information". A pinned entry glows and says "Featured" and comes first. (A18)
2. [partly automated: `ShopTextTest.rowLines_followTheLegacyPriceStockAndClickLines`; by hand: the greyed item] Make an
   entry sold out (empty its Merchandise stock, § 11.0 item 5) and reopen. **Expected:** the item is greyed out with
   "Stock: 0" and "Sold out" (F5); with **Hide sold out** on the shop (web app) it is not listed at all.
3. [partly automated: `ShopMenuSeedsTest.theThreeShopMenus_validateAgainstTheRegisteredFeature`; by hand: paging] Give
   the shop more than 36 offered items (catalogue entries or Merchandise stock). **Expected:** arrows in slots 45 and 53
   page through the catalogue ("Page 1/2").
4. [partly automated: `ShopServiceTest.view_cyclesTheAmountAndShowsTheTotal`, `ShopAmountsTest`; by hand: the real
   clicks] Click Bread. **Expected:** the item information menu: "Amount: 1" (chest), Bread in the middle, the name tag
   "This item costs: <n> coins" with stock, amount, total and "Click here to buy", the map with the item and how the
   price is set. Click the chest: 8, 16, 32, 64, then 1 again; the total follows.
5. [automated: `ShopServiceTest.purchase_toTheInventory_sendsThePriceSeenAndPlacesWhatWasBought`, scenario
   `player-shop-sell-and-buy`] With "Amount: 8" click the name tag, then **Confirm** (green). **Expected:** the
   confirmation book says "Are you sure you want to buy 8 x Bread?" with the price each and the total (the API's
   `quote`); after Confirm Ann has 8 Bread more, the chat says "You bought 8 x Bread for <total> coins. You have
   <n> coins left." and the item information menu is back. Phoenix's town account gained the total (web app, town
   account page; § 11.1 step 7). (A18)
6. [automated: `ShopServiceTest.purchase_toTheInbox_placesNothing`] Buy again with the ender chest **Confirm: to your
   reward inbox**. **Expected:** nothing lands in the inventory; the chat says it waits in the reward inbox; `/inbox`
   shows the Bread.
7. [partly automated: `ShopServiceTest.purchase_priceChanged_asksAgainWithTheNewPrice`; by hand: the real price change] Open
   the confirmation, then (web app) change Bread's static price, then click Confirm. **Expected:** "The price changed.
   Check the new price and confirm again."; nothing is bought; the book now shows the new price and "The price changed
   from <old>. Confirm again to buy."; a second Confirm buys at the new price.
8. [partly automated: `ShopServiceTest.purchase_everyOtherRefusalIsToldAndNothingIsPlaced`; by hand: with Bob] As **Bob**
   (50 coins) try to buy 64 Bread. **Expected:** the name tag says "You need <n> coins more"; Confirm answers "You don't
   have enough coins. Nothing was charged."; nothing moves. (A18)
9. [partly automated: `ShopServiceTest.purchase_refusedWithoutACall_fullInventoryUniqueItemSiege`; by hand: the real
   inventory] Fill Ann's inventory, then confirm a purchase into the inventory. **Expected:** "Your inventory has no
   room for <n>. Make room, or send it to your reward inbox."; nothing is bought. A unique item (§ 11.1's bought-back
   sword) is listed with its enchantments and "Unique item", but its name tag says it can't be bought in game yet
   (#897), and so does the confirmation.
10. [partly automated: `SellModuleTest.open_showsTheLegacyLayout`; by hand: the real menu] Back in the shop menu click
    the chest **Sell items to this shop**. **Expected:** the sell menu "Sell items to Bakery": coins, the Sell chest
    ("Price: 0 coins", "Add items first"), the anvil, the book "How to sell" and Back. A shop whose type accepts no
    categories, or with the API's `Production:Enabled` off, has no Sell chest.
11. [automated: `SellModuleTest.pick_quotesTheLinesAndShowsThePrices`, scenario `player-shop-sell-and-buy`] Click 20
    Bread and a unique enchanted sword in Ann's inventory. **Expected:** they show in slots 19 and 20 with "Buy-back:
    <n> coins each" and "For these 20: <n> coins"; the Sell chest shows the total and "Click here to sell". The items
    stay in Ann's inventory. Clicking a picked stack takes it out again.
12. [automated: `SellModuleTest.sell_sellsAtTheTotalShownAndTakesTheItems`, scenario `player-shop-sell-and-buy`] Click
    the Sell chest. **Expected:** "You sold 2 item stacks for <total> coins. You now have <n> coins."; the bread and the
    sword are gone; the menu closes; Bakery's Merchandise holds them (web app), the sword as that exact item; the town
    account paid the total. (A18)
13. [partly automated: `SellModuleTest.sell_refusesARefusedLineWithoutACall`; by hand: a real category] Pick an item
    the shop doesn't buy (Cobblestone, not Food). **Expected:** its stack says "This shop doesn't buy items of that
    kind." and the Sell chest "Take out the marked items to sell"; a click on Sell sells nothing.
14. [partly automated: `SellModuleTest.sell_refused_givesTheItemsBack`, `SellModuleTest.sell_inventoryChanged_dropsThePickAndAsksAgain`;
    by hand: an empty town account] Empty Phoenix's town account (or pick more than it holds), then sell. **Expected:**
    "The town can't pay that much right now." and every item is still in Ann's inventory. Moving a picked stack in the
    inventory before clicking Sell drops it from the sale with "Your inventory changed; check the sale and click
    again."
15. [automated: `SellModuleTest.pick_refusesUnresolvedDamagedAndEnchantedPlainItems`] Click a damaged tool, a renamed
    item and a plain item with an enchantment. **Expected:** "Damaged items can't be sold to a shop", "This item isn't in
    the item catalogue." and "Enchanted items can't be sold as plain items"; none is picked.
16. [by hand] Set `production.enabled: false` and restart. **Expected:** `/knk shop 1` answers "Production is off on
    this server (production.enabled: false)." and the three shop menus are blocked in `/knk menu`. Turn it back on.

### 11.3 Steps (web app #688)

Built in link L27 (knk-web-app), merged into `next` 2026-11-21 (`11832d6b`). The tags name tests in knk-web-app
`e2e/shops.spec.ts` (Playwright, mocked API; the mocks use the Processing shop "Phoenix bakery" of shop type Bakery at
level 2 in Market, its Input and Merchandise storages, the categories Food and Tools, Bread and Apple, a bought-back
enchanted Diamond sword, Phoenix's town account with 1,250 coins and three town legs, two sales and a buy-back in the
stock ledger, and trade stats for 10:00 and 11:00 UTC) and the Jest tests next to the code
(`src/utils/__tests__/shops.test.ts`, `src/apiClients/__tests__/shopClients.test.ts`). Extra preconditions: § 11.0 and
§ 11.1 steps 1, 3-5, 7-8, 12 and 18 (the seeds imported with "make default", the shop types Bakery and Weaponsmith with
their levels, Bakery shop with its catalogue and stock, a purchase by Ann and a sale by Bob), so the pages below have real rows; for
step 12 `Production:Enabled` on (the stats job). Log in to the web app as **Staff** (holds `knk.admin.world`,
`knk.admin.content` and `knk.admin.delete`) unless a step says otherwise. 15 steps: 11 automated, 4 partly (tagged);
every step can still be run by hand; not run. Full manual run about 30 minutes; the untagged parts about 15 minutes
(most of it waiting for the hourly stats, or using **Rebuild from the ledger**).

1. [automated: `dashboard › lists the shop types with their categories and levels, the shops and the town accounts
   (A23)`] Open **Dashboard → ShopType**, then **Shop** and **TownAccount**. **Expected:** the shop types with ID, Name,
   Default kind, Accepted categories (the count, or "None (buys nothing)"), Levels and Active; the shops with their
   town, placement, district, Level, Processing (On or Off), territory flag and world; the town accounts with Town,
   Balance ("<n> coins") and Updated. (A23)
2. [automated: `a shop type › lists its accepted categories and its levels with multipliers, caps and the default min
   and max`] Open Bakery's page (`/display/ShopType/<Bakery>`). **Expected:** below the details an **Accepted
   categories and levels** panel: the accepted categories as chips (each linked to the category's page) and a
   **Levels** table, one row per level in order: Level (linked to the level's page), Speed, Yield, Input cost and Price
   ("× 1.5"), Merchandise cap, Input cap, Per slot ("-" for none) and Min / max ("10 / 40").
3. [automated: `a shop type › a category is added and one removed, and the whole list is saved as
   acceptedCategoryIds`, `a shop type › the API's refusal of a category list is shown`] On Bakery's panel type "Wea" in
   **Add a category**, pick **Weapons**, then remove **Food** with its ×. **Save the categories** is off until the
   list changed. Save. **Expected:** "Accepted categories saved: Weapons."; the request is `PUT api/ShopTypes/<Bakery>`
   with only `{ "id": <Bakery>, "acceptedCategoryIds": [<Weapons>] }` (the whole list; the other fields kept). A
   refused save shows the API's sentence (for example "Category 13 not found."). Put Food back the same way and save.
4. [automated: `a shop type › a level is added after its checks, edited and deleted (levels on the production level
   pattern)`, `a shop type › without knk.admin.delete a level can be edited but not deleted`, `a shop type › without
   knk.admin.content the categories and levels are read only, with the node named`] Press **Add a level**:
   the form offers the next free level (3) with every multiplier 1. Type level 2, price × 0 and a default max below
   the default min. **Expected:** "Level problems": "The shop type already has level 2.", "The price multiplier is
   above 0 and at most 100.", "The default max is below the default min."; **Save the level** is off. Correct them
   (level 3, price × 1.5, Merchandise cap 2560) and save. **Expected:** "Level 3 saved; shops of this type at that level
   use it now."; the table has a level 3 row; an empty cap is sent as 0 (no cap). **Edit level 2**, clear Units per
   slot, save: `PUT api/ShopTypeLevels/<id>` with `unitsPerSlot` 0. **Delete level 3**: "Level 3 deleted.". As a staff
   member without `knk.admin.delete`, Delete is off and Edit works. Without `knk.admin.content` (creates and edits need
   it with `knk.admin.world`, as on every dashboard type), Add a level, Edit, the category ×, the picker and Save the
   categories are off with "Requires knk.admin.content"; the same holds for the catalogue's Add an entry and Edit.
5. [automated: `a shop type › a type without categories buys nothing; without levels its shops use × 1`] Open a shop
   type without categories or levels (create "General store" with the seeded form). **Expected:** "None: its shops
   buy nothing from players." and "No levels yet: its shops use × 1 and no caps."
6. [partly automated: knk-web-app `shopClients.test.ts` (the registry sends the form's create, update and delete to
   `api/Shops`, `api/ShopTypes`, `api/ShopTypeLevels` and `api/ShopCatalogueEntries`); by hand: run the seeded forms]
   Create a shop with **Dashboard → Shop → New** (the seeded form of § 11.1 step 1): placement in Market on a street
   with a house number, shop type Bakery, kind empty (the type's default). Edit Bakery with its form and save.
   **Expected:** the shop opens on its page with kind Processing; Bakery's save keeps its accepted categories (the form
   sends none) and its levels. (A23)
7. [automated: `a shop › shows its kind, type and level, prices, worker, storages, town account and what it offers now
   (A18)`] Open Bakery shop's page (`/display/Shop/<Bakery shop>`). **Expected:** a **Shop** panel: Kind "Processing
   (Input → Merchandise, then sells)"; Shop type and level "Bakery, level 1" (the type linked); Prices "tax × 1, buys
   back at 50%"; Worker "1 of 1 present" (while it is away restocking: "0 of 1 present: away restocking, processing is
   lowered (selling goes on)"); Storages, the Input and Merchandise storages linked with their purpose; Town account
   "Phoenix: <n> coins" linked to the account's page. **Offer now**: "What players see in the shop menu; sold-out items
   are greyed out. It buys from players in its accepted categories." and a table per item: the price in coins, where it
   comes from (static price, formula, no price), the stock ("Unlimited" for an Unlimited entry) and notes ("Pinned",
   "Sold out" with the row struck through, "In stock, no entry", "Bought back, resold as this item" with the
   enchantments after the name). It matches `GET api/Shops/<Bakery shop>/offer` (§ 11.1 step 8). (A18)
8. [automated: `a shop › the shop without a town account yet says it opens with the first sale`] Open the Weaponsmith
   (rural, no sale yet). **Expected:** Town account "No account yet: it opens with the first sale".
9. [automated: `a shop › the catalogue lists pinned entries first and is edited: add, a refused add, edit and
   delete`] On Bakery shop's page, the **Catalogue** table lists pinned entries first, then by order: Item, Static
   price ("9 coins" or "Formula"), Stock (Stocked or Unlimited), Pinned, Order, On. Press **Add an entry**: "Pick an
   item, or give a unique item's instance id."; type a unique item's instance id and pick Unlimited: "A unique item is
   one item: it can't be Unlimited."; pick Stocked, a static price of 400, save. **Expected:** "Catalogue entry for
   <item> saved."; the entry and the offer show it. Add Coal again: the API's 409 sentence is shown. **Edit the entry
   for** Iron ore: price 5, Pinned, save (`PUT` without shop or item: an entry keeps them). **Delete the entry for**
   Iron ore: "Catalogue entry for Iron ore deleted."
10. [partly automated: `a shop › lists its sales and buy-backs from the stock ledger filtered by the shop (DESIGN §
    9)`; by hand: make a purchase and a sale with § 11.1 steps 12 and 18] Make a purchase as Ann and a sale as Bob, then
    reload Bakery shop's page. **Expected:** **Sales and buy-backs**, newest first: Transaction (linked to its ledger
    page), When, What ("Sale" or "Buy-back"), Units and Note; the request is `POST api/StockTransactions/search` with
    `sourceType` Shop and `sourceRef` the shop's id. Pages of 20 with Newer and Older.
11. [partly automated: `a town account › shows its balance, that it matches the ledger, and every town leg newest first
    with the shop`, `a town account › a balance that does not match its ledger is flagged`; by hand: compare with the
    API] Follow the town account link. **Expected:** a **Balance and ledger** panel: Town (linked), Balance "<n> coins",
    Ledger check "Matches the last ledger entry" (else "Does not match: the ledger says <n> coins" in warning colour);
    the **Ledger** newest first: When, Reason ("Shop purchase", "Shop buyback"), Amount ("+48", "-20"), Balance after,
    Player ("User #<id>"), Source ("Shop #<id>" linked to the shop) and the transaction id; pages of 25. By hand: the
    rows match `GET api/TownAccounts/<id>/ledger` and Ann's coins went down by the purchase. (A18)
12. [partly automated: `a shop › the hourly trade stats as a chart with totals, per item, over a range, and rebuilt
    from the ledger (A18)`; by hand: wait for the hourly rollup or press Rebuild, compare with the ledger] After the
    purchase and sale of step 10, wait for the next 10-minute stats run (or press **Rebuild from the ledger**) and open
    **Trade stats per hour** on Bakery shop's page. **Expected:** Range "Last 24 hours" and Item "All items": a line
    "Last 24 hours, all items: <n> sold for <n> coins, <n> bought back for <n> coins, <n> supplied."; a bar chart of
    every UTC hour (sold, bought back, supplied; hover a bar for its numbers); the rows per hour and item (Hour "2026-11-21
    10:00 UTC", Item, Sold, Revenue, Bought back, Paid, Supplied, Stock at end). Pick an item: the line, chart and rows
    show only it. Pick "Last 7 days": the request's `from` is 7 days before the end of the current hour. **Rebuild from
    the ledger**: "Rebuilt <n> hours from the ledger: <n> rows written, <n> removed." By hand: the units and coins match
    the ledger of steps 10 and 11 for that hour. (A18)
13. [automated: `a shop › a range without trade says so`] Open the Weaponsmith's page. **Expected:** "No trade in this
    range." and a line of zeros.
14. [automated: `a shop › its processing view and its restocking as a consumer, from the production structure
    panels`] Scroll below the Shop panel on Bakery shop's page. **Expected:** the **Production** panel of a production
    structure (the shop's processing view, lines and workers; a Trading shop's lines are paused) and **Supply (as a
    consumer)**: the Merchandise storage's demand per stocked catalogue item with the min and max from "its shop level's
    default min and max", what is on the way, the worker who collects and the open reservations with Release
    (§ 10.2 steps 12-14).
15. [automated: `a shop › without knk.admin.world the shop panels are not shown and the offer is not read`] Log in as a
    staff member without `knk.admin.world` who can open the page. **Expected:** no Shop panel; the network tab shows
    no `offer` or `ShopTradeStats` request.

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
