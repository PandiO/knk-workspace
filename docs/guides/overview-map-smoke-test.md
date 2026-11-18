# Overview map — smoke test

**Status:** Draft from the design (2026-11-18); no steps run. § 1 updated to what L1 built (7 steps, all partly automated, tagged), § 2 to what L2 built (7 steps: 2 automated, 5 partly automated, tagged), § 3 to what L3 built (11 steps: 1 automated, 9 partly automated, 1 manual only, tagged); the other sections are not automated yet (the links tag them).
**Last updated:** 2026-11-18 (§ 3 to what L3 built, #737); 2026-11-18 (§ 2 to what L2 built, #736); 2026-11-18 (§ 1 to what L1 built, #735); 2026-11-18 (draft from the design, phases 1, 2, 3, 4a, 4b, 5, 6a, 6b, 7)
**Design:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md) · **Issue:**
[PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732)

Accounts used throughout:

1. **Anonymous:** a private browser window, not logged in.
2. **Player:** a logged-in web account linked to a Minecraft player with no staff nodes.
3. **World staff:** holds `knk.admin.world` only.
4. **Gate admin:** holds `knk.gate.admin` only.
5. **Kick moderator:** holds `knk.kick` only.
6. **Staff viewer:** holds `knk.mode.staff`.

Test data: one town with at least two districts, a structure with a spawn location, a structure without one, and a
gate structure with two doors.

## 1. Phase 1: region outlines (#735, tier:3)

*Built by link L1 (knk-plugin and knk-web-api branches `claude/overview-map-outlines`, PRs into `next`). 7 steps, all
partly automated (tagged): the suites cover the plugin's reports, the hub method and the table; a real Paper server
with WorldGuard, the game hub and MySQL is checked by hand. Every step can still be run by hand; not run yet. Full manual
run about 30 minutes.*

Tests named below: knk-plugin `knk-core` `MapReportingServiceTest`, `ManagedRegionRepairServiceTest`, `knk-paper`
`RegionOutlineAdapterTest`; knk-web-api `MapRegionOutlineServiceTests`, `RealtimeHubTests`, `AddMapRegionOutlinesTests`.

### 1.0 Preconditions

1. Deployed: the API from `next` with the `AddMapRegionOutlines` migration applied (new table `map_region_outlines`),
   and the plugin build from `next`.
2. Settings: plugin `config.yml` `realtime.enabled: true` (the reports travel over the game hub) and the new block
   ```yaml
   map:
     reporting:
       enabled: true
   ```
   Existing servers don't get the block by themselves: paste it (plugin configuration reference § 4.29).
3. Data: the test town, its districts and the structures above, each with a WorldGuard region.
4. To read the table: `SELECT WgRegionId, WorldName, MinY, MaxY, DomainId, UpdatedAt, LEFT(PointsJson, 80) FROM
   map_region_outlines ORDER BY WorldName, WgRegionId;`

### 1.1 Steps

1. [partly automated: `ManagedRegionRepairServiceTest.theAfterRunListenerGetsTheDomainRegionsOfEveryRun`,
   `MapReportingServiceTest.startup_sendsEveryDomainRegionWithPointsAndYRange`, `RegionOutlineAdapterTest`,
   `RealtimeHubTests.GameHub_ReportRegionOutlines_StoresOneRowPerRegion`,
   `MapRegionOutlineServiceTests.StartupReport_StoresOneRowPerRegionWithPointsYRangeAndDomainLink`; by hand: a real
   server, WorldGuard and MySQL] Start the game server and wait for the startup repair (`[KnK Regions] Managed-region
   repair: …` in the server log). **Expected:** the server log shows `[KnK Map] Region outlines (domain regions): <n>
   outline(s), 0 removed, …`; the API log shows `Game server <id> reported region outlines: <n> stored, …`. The table
   has one row per domain region id and world, with points (four corners for a cuboid region, the polygon's points
   otherwise), min Y, max Y and `DomainId` set to the domain. (A01)
2. [partly automated: `MapRegionOutlineServiceTests.ReportingAgain_UpdatesInPlaceWithoutDuplicates_AndKeepsUnchangedRowsUntouched`;
   by hand: a real restart] Restart the game server. **Expected:** the same rows, no duplicates; rows whose region did
   not change keep their `UpdatedAt` (the API log counts them as unchanged). (A01)
3. [partly automated: `MapReportingServiceTest.reRunOfARegionStep_replacesInPlace_andNeverRemovesTheFinalName`,
   `MapRegionOutlineServiceTests.RedefinedInPlace_RemovedNamesTheSameRegion_TheRowIsKept`; by hand: the world task in
   game] In the web app, re-run the Region and Location step of one district and draw a different shape in game.
   **Expected:** right after the step, that district's row has the new points and a newer `UpdatedAt`; the server log
   shows `[KnK Map] Region outlines (region domain_<id>): 1 outline(s), 1 removed, …` (the removed one is the temp
   name). (A02)
4. [partly automated: `MapReportingServiceTest.rename_sendsTheNewOutlineAndRemovesTheOldNames`,
   `MapRegionOutlineServiceTests.Rename_StoresTheNewIdAndRemovesTheOldRow`; by hand: the world task flow] Create a new
   structure through the form wizard so its `tempregion_worldtask_<n>` is renamed to `domain_<id>`. **Expected:** a
   row for `domain_<id>` with the structure's `DomainId`; no row for `tempregion_worldtask_<n>`. (A02)
5. [partly automated: `MapReportingServiceTest.startup_sendsEveryDomainRegionWithPointsAndYRange`; by hand: the
   command] Change a region by hand (`/rg redefine domain_<id>` with a new selection), then run `/knk regions repair`.
   **Expected:** that row has the new points after the repair (the repair resends every domain region; a hand edit
   alone is not reported until then).
6. [partly automated: `MapReportingServiceTest.notConnected_isReportedAndTheReconnectResendsTheCurrentOutlines`; by
   hand: an API restart] With the game server running, stop the API, empty the table (`DELETE FROM
   map_region_outlines;`), and start the API again. **Expected:** once the plugin's hub reconnects (server log
   `Realtime resync after reconnect: …`), the rows are back.
7. [partly automated: `MapReportingServiceTest.offByDefault_readsAndSendsNothing`; by hand: the restart] Set
   `map.reporting.enabled: false` and restart. Change a region (step 3 or 5). **Expected:** the server log shows
   `[KnK Map] Map reporting off (map.reporting.enabled=false)`, no `[KnK Map] Region outlines` line, and the row does
   not change. (flag)

## 2. Phase 2: public map API (#736, tier:3)

*Built by link L2 (knk-web-api branch `claude/overview-map-public-api`, PR into `next`). 7 steps: 2 automated, 5
partly automated (tagged); the by-hand parts need a real API with MySQL behind Nginx. The suites cover the routes, the flag, the
rate limit and the exact public field sets; a real database with the phase 1 outlines and a real client IP are checked
by hand. Every step can still be run by hand; not run yet. Full manual run about 20 minutes.*

Tests named below, all in knk-web-api `Tests/knkwebapi_v2.Tests`: `Api/MapControllerPipelineTests`,
`Api/MapPublicDtoFieldTests`, `Services/Map/MapPublicServiceTests`, `Security/EndpointAccessRulesTests`,
`Security/ReadAccessRulesTests`.

### 2.0 Preconditions

1. Deployed: phase 1 (the `map_region_outlines` table filled by the plugin, smoke § 1 step 1), and the API from `next`.
2. Settings (environment file of the API, `/etc/knk/api.env`, production installation guide § 4.3; restart the API
   after a change): `Map__Enabled=true`. Leave the other `Map__*` keys at their defaults (label distances 0 / 1500 /
   600 / 1500, flash 3 × 400 ms, marker cache 30 s) and `RateLimiting__Map__PermitPerMinute=120`.
3. Data: the test town with two districts, a structure with a spawn location, a structure without one, and the gate
   structure with two doors, all with stored outlines. Note their ids from the web app.
4. Calls without a token, for example `curl -s https://<host>/api/Map/markers | jq`.

### 2.1 Steps

1. [automated: `MapControllerPipelineTests.MapOff_EveryRouteAnswers404_AndReadsNothing`,
   `MapControllerPipelineTests.MapOffByDefault_WithoutAnySetting_EveryRouteAnswers404`] With `Map__Enabled=false` (or
   the key absent), call `GET api/Map/config`, `GET api/Map/markers`, `GET api/Map/towns/{id}`,
   `GET api/Map/districts/{id}` and `GET api/Map/structures/{id}` without a token. **Expected:** 404 for every one.
   (A03)
2. [partly automated: `MapControllerPipelineTests.MapOn_EveryRouteAnswersAnonymously`,
   `EndpointAccessRulesTests` (the anonymous allow-list), `ReadAccessRulesTests` (pinned `P`); by hand: the deployed
   API] With `Map__Enabled=true`, call `GET api/Map/config` without a token. **Expected:** 200 with `enabled: true`, a
   16-character `markerVersion`, `labels` `{town: null, district: 1500, structure: 600, arena: 1500}`, `flash`
   `{count: 3, durationMs: 400}`, `livePlayers.enabled: false` and `gateCommands.enabled: false`.
3. [partly automated: `MapPublicServiceTests.Markers_ListTownsDistrictsAndStructures_LabelledWithTheirNames`,
   `Markers_StructuresCarryTypeAndSubtype`, `Markers_PinAtTheSpawnLocation_ElseAtTheOutlineCentroid`,
   `Markers_ShapeIsTheMainRegionThenCurrentSubRegions_StaleAndUnlinkedRowsIgnored`; by hand: real outlines] Call
   `GET api/Map/markers` without a token. **Expected:** 200. `towns` has the test town, `districts` its two districts
   (with the town's `townId`), `structures` the three structures, each with `name` = its name, never a region id
   (search the raw JSON for `domain_`: no hit). Structures have `type: "Structure"`; the gate has `subtype: "Gate"`
   and `typeLabel: "Structure, Gate"`, the others `subtype: null` and `typeLabel: "Structure"`. The structure with a
   spawn location has `pin.source: "location"` at that location (x, y, z); the one without has `pin.source:
   "centroid"`, `y: null`, at the centre of its outline. Each item's `outlines` starts with its main region; the points
   match the phase 1 rows. A domain with neither a location nor an outline is not listed, and the API log has one
   `Overview map: domain <id> (<name>) has no spawn location and no region outline` line for it after the first call
   (not repeated on later calls). (A04)
4. [automated: `MapPublicDtoFieldTests.PublicDto_HasExactlyThePinnedFields`, `EveryPublicMapDto_IsPinned`,
   `NoPublicMapDto_NamesARegionOwnerOrPermission`, `MapPublicServiceTests.TownPanel_NameDescriptionAndDistrictCount_Only`,
   `DistrictPanel_NameDescriptionAndTown_Only`, `StructurePanel_PlainStructure_HasNoGate`,
   `StructurePanel_Gate_AddsDoorsWithStateDestroyedHealth_AndUnderSiege`, `Panels_UnknownOrWrongTypeIds_AreNull`]
   Call `GET api/Map/towns/{townId}`, `GET api/Map/districts/{districtId}` and `GET api/Map/structures/{gateId}`
   without a token. **Expected:** only the O32 fields. Town: `id`, `name`, `description`, `districtCount` (2).
   District: `id`, `name`, `description`, `townName`. Structure: `id`, `name`, `description`, `type`, `subtype`,
   `districtName`, `townName`, `streetName`, `houseNumber`, `gate`. For the gate, `gate` has `underSiege` and `doors`,
   each door only `name`, `openState` (`open`, `closed`, `opening`, `closing` or `jammed`), `isDestroyed`,
   `healthCurrent` and `healthMax`; a plain structure has `gate: null`. No region ids, owner data or other internal
   ids. A town id on `structures/{id}`, or an unknown id, answers 404. (A05)
5. [partly automated: `MapPublicServiceTests.StructurePanel_Gate_StructureOverridesWin_AndAFinishedMatchIsNoSiege`;
   by hand: a real match] Start a siege match on the gate and call `GET api/Map/structures/{gateId}` again.
   **Expected:** `underSiege: true` while the match is created or running, door health still shown; after the match
   ends, `false`.
6. [partly automated: `MapPublicServiceTests.Markers_VersionChangesWhenAnOutlineChanges`,
   `Markers_AreReusedForCacheSeconds_ThenRebuilt`; by hand: the deployed API] Note `markerVersion` from
   `GET api/Map/config`, rename the test town in the web app, wait 30 seconds (the marker cache) and call it again.
   **Expected:** a different `markerVersion`, and `GET api/Map/markers` shows the new name.
7. [partly automated: `MapControllerPipelineTests.MapPolicy_Refuses121stRequestInAMinute_With429`,
   `MapPolicy_PermitIsConfigurable`; by hand: the real client IP behind Nginx] From one machine, send 121 requests
   to `GET api/Map/markers` within one minute (`for i in $(seq 121); do curl -s -o /dev/null -w "%{http_code}\n"
   https://<host>/api/Map/markers; done | sort | uniq -c`). **Expected:** 120 × 200 and 1 × 429 (with a `Retry-After`
   header). From a second machine (another IP) in the same minute: 200. (A06)

## 3. Phase 3: map page (#737, tier:2)

*Built by link L3 (knk-web-app branch `claude/overview-map-page`, deploy notes on knk-workspace
`claude/overview-map-page`; PRs into `next`). 11 steps: 1 automated, 9 partly automated, 1 manual only (tagged). The
suites run the page against a mocked API and a fake BlueMap web app that loads the real bridge script; a real render,
real zooming and a real phone are checked by hand. **The live run waits for the developer's NAS change** (runbook
Phase 10: the `bluemap-test` container moved into the `knk-alpha` stack, `/bluemap/` served, the full-world render).
Not run yet. Full manual run about 20 minutes.*

Tests named below: knk-web-app `e2e/overview-map.spec.ts` (Playwright, "e2e") and the Jest suites in
`src/components/map/__tests__/` (`bridgeProtocol`, `mapMarkers`, `mapActionRegistry`, `GateDoorsWidget`,
`useMapAvailability`).

### 3.0 Preconditions

1. Deployed: phases 1 and 2, the web app from `next`, and
   [closed-alpha runbook Phase 10](closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737):
   the render service `bluemap` in the `knk-alpha` stack (BlueMap v5.29), nginx serving `web/` under `/bluemap/`,
   `webapp.conf` with `client-decompression: true` and `scripts: ["/bluemap-bridge/bridge.js?worlds=<map id>:<world>"]`,
   and a render that covers the test town.
2. Settings: API `Map__Enabled=true` (`/etc/knk/api.env`, restart the API). Other `Map__*` keys at their defaults.
3. Data: the test data above, with outlines stored (smoke § 1) and the town's spawn location set.

### 3.1 Steps

1. [manual only: deployment] On the NAS: `docker ps --format '{{.Names}}' | grep -i bluemap` shows no `bluemap-test`;
   `docker compose --profile bluemap config --services` lists `bluemap`. In a browser (through Cloudflare Access),
   open `https://app.knightsandkings.net/bluemap/`. **Expected:** BlueMap's viewer shows the rendered area; the
   response of `/bluemap/` has `X-Frame-Options: SAMEORIGIN` (developer tools, Network), any other page `DENY`;
   `/bluemap/settings.json` lists the bridge script under `scripts`.
2. [partly automated: e2e `the start page links to the map, and /map shows pins with labels by zoom (A07)`,
   `logged in with the map on: the bar has a Map entry that opens the map`; by hand: the real render and zoom] As
   **anonymous**, open the start page. **Expected:** "Explore the world on the map" with a link; it opens `/map` with
   the 3D map, no login. As the **player**, the top bar has a "Map" entry that opens it. Town pins have their names at
   every zoom. Zoom out far: district and structure labels fade out, their pins stay; zoom in on the town: district
   names appear (within about 1500 blocks), structure labels (name over "Structure" or "Structure, Gate") within about
   600. Pins of another world are not on this map. (A07)
3. [partly automated: e2e `clicking a town flashes its outline three times and opens its public panel (A08)`,
   Jest `mapActionRegistry` "shows the town panel ..."; by hand: the real flash] Click the town pin (or its label).
   **Expected:** the town's outline flashes three times (about 0.4 s each) and disappears. The panel on the right
   shows the town's name, description and number of districts. (A08)
4. [partly automated: e2e `"Show region" shows the town and all its districts by name, and hides them again (A08)`;
   by hand: the verdict] Turn on "Show region". **Expected:** the town outline and every district of that town stay
   visible, each district labelled with its name, never a region id (`domain_...`). Close the panel (× or Escape):
   the regions stay. Click the town again: the switch is on; turn it off: the regions disappear. Judge whether
   showing all districts at once works and note your verdict for a follow-up (O30). (A08)
5. [partly automated: e2e `clicking a gate shows its doors with open/closed, destroyed and a health bar (A09)`, Jest
   `GateDoorsWidget`; by hand: real gate data] Click the gate structure. **Expected:** the panel shows its name,
   "Structure, Gate", district, town and address, and a "Doors" list: each door with Open/Closed (or Opening,
   Closing, Jammed), "Destroyed" when destroyed, and a health bar with "Health current / max". No buttons (gate
   commands come with #742). During a siege match on that gate: "Under siege", health still shown. (A09)
6. [partly automated: e2e `on a phone the panel opens as a bottom sheet and the page does not scroll sideways`; by
   hand: a real phone] On a phone, repeat steps 3 and 5. **Expected:** the panel opens as a bottom sheet over the
   lower part of the screen, the map stays usable above it, the × closes it, no sideways scrolling. (A07)
7. [partly automated: e2e `bridge messages from another origin or another window are ignored (A10)`, Jest
   `bridgeProtocol`; by hand: the console] On `/map`, open the developer tools console and run
   `window.postMessage({ v: 1, type: 'markerClicked', payload: { kind: 'town', id: <town id> } }, '*')`.
   **Expected:** nothing opens (the page only listens to the map's own frame on its own origin). Clicking the pin
   still opens the panel. (A10)
8. [partly automated: e2e `the bridge keeps its pins when BlueMap reloads its own marker file`; by hand: the real
   viewer] Stay on `/map` for at least 30 seconds without reloading. **Expected:** the pins and labels stay (BlueMap
   reloads its own marker file every 10 seconds; the bridge's pins must survive it).
9. [partly automated: e2e `a new marker version reloads the markers (§ 5 rule 2)`; by hand: the deployed API] Keep
   `/map` open, rename the test town in the web app (another tab), wait about 90 seconds (30 s marker cache plus the
   page's 60 s check). **Expected:** the town's label shows the new name without reloading the page.
10. [automated: Jest `mapActionRegistry` "shows a newly registered action only to a viewer holding its node ... (A22)",
    "hides the action without the node and from anonymous viewers", "shows a staff widget under its node ..."]
    Registering a new action for a type in `mapActionRegistry` shows it in the panel under its node, with no change to
    the bridge script. (A22; code-level, nothing to do by hand.)
11. [partly automated: e2e `map off (Map:Enabled false)` › `anonymous: no map link on the start page, and /map says
    not available`, `logged in: the bar has no Map entry`, Jest `useMapAvailability`; by hand: the deployed API] Set
    `Map__Enabled=false`, restart the API, reload the web app. **Expected:** no "Map" entry in the bar, no map link on
    the start page; `/map` shows "The map is not available." and loads no iframe. (A07)

## 4. Phase 4a: live players backend (#738, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: phase 2, the API and plugin from `next`.
2. Settings: `Map:LivePlayers:Enabled=true`. Plugin `map.reporting.enabled: true`, `map.reporting.interval-ticks: 40`.
3. Accounts: players A (no mode), B (a staff member who can enter staff mode) and C (owner); a siege scenario ready to
   start.

### 4.1 Steps

1. With player A online, call `GET api/Map/players` without a token. Move A 20 blocks and call it again after 2 s.
   **Expected:** A is listed with world and position, and the second response shows the new position. (A11)
2. B enters `/staffmode`. Call the endpoint without a token, then with the **player** token. **Expected:** B is absent
   from both response bodies (check the raw JSON). (A12)
3. Call it with the **staff viewer** token. **Expected:** B is listed with the tag "Staff mode". C in `/ownermode` is
   listed with "Owner mode". (A12)
4. A stays idle until the plugin marks them AFK, or uses `/afk`. **Expected:** the AFK tag appears within one interval.
   (A13)
5. Start a siege match with A in it. Call the endpoint without a token and with the **player** token. **Expected:** A
   is absent from both. One arena entry at the gate reads "[Siege] <count> players" for both callers. (A14)
6. Compare the label parts for C (owner), B (staff), a premium player and a default player with their in-game chat
   lines. **Expected:** the same bracket or title, name and colour codes. (A15)
7. A quits. **Expected:** A is gone within three intervals (6 s). (A16)
8. Watch the plugin's performance metrics for the reporting task during step 1 with 20 or more players online.
   **Expected:** no noticeable tick time. Note the number. (§ 9.1)

## 5. Phase 4b: live players layer (#739, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: phases 3 and 4a, the web app from `next`.
2. Settings: as § 4.0.

### 5.1 Steps

1. As **anonymous**, open `/map` with player A online and walking. **Expected:** A's head and name label move along
   about every 2 s. (A11)
2. Look at labels for an owner, a staff member, a premium player and a default player. **Expected:** the same format
   and colours as their in-game chat lines. AFK shows as a tag. (A13, A15)
3. B is in staff mode. **Expected:** B is not on the map for anonymous or the **player** account. The **staff viewer**
   sees B as a normal player with the "Staff mode" tag. (A12)
4. During a siege match, look at the gate. **Expected:** the participants are not shown. One pin reads
   "[Siege] <count> players". (A14)
5. Click player A as **anonymous**. **Expected:** a name card with the label and tags only. (A11)

## 6. Phase 5: staff details (#740, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 6.0 Preconditions

1. Deployed: phase 3, the web app from `next`. Structures have a default display configuration.

### 6.1 Steps

1. As **world staff**, click a structure. **Expected:** a "Details" section under the public part shows the display
   configuration in compact form, with "Open full page" leading to `/display/Structure/<id>`. (A17)
2. As the **player** account, click the same structure. **Expected:** no "Details" section. The browser's network tab
   shows no display-configuration request. (A17)

## 7. Phase 6a: gate commands backend (#741, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 7.0 Preconditions

1. Deployed: phase 2, the API and plugin from `next`, with the game server connected.
2. Settings: `Map:GateCommands:Enabled=true`.
3. Accounts: **gate admin**, **world staff**. The test gate's doors start closed. Stand next to the gate in game.

### 7.1 Steps

1. As **gate admin**, call `POST api/GateStructures/{id}/commands` `{action: "open", doorId: <door 1>}`.
   **Expected:** 200 with the result "done". Door 1 opens in game with its normal animation, and its stored state is
   open. (A18)
2. Repeat with `close`, `toggle`, and `open` without `doorId`. **Expected:** each acts as named, and the last one opens
   every door. (A18)
3. Damage door 1 in game, then send `repair`. **Expected:** health is back to full and the door is no longer destroyed.
   (A18)
4. Send a command as **world staff**. **Expected:** 403, and nothing changes. (A19)
5. Start a siege match on the gate and send `open` as **gate admin**. **Expected:** 409 "Gate is in a running
   siege", and nothing changes. (A19)
6. Stop the game server and send `open`. **Expected:** 503. (A19)
7. Send a `doorId` of another gate. **Expected:** 400. (A19)
8. Read the audit log. **Expected:** one entry per command with the user, the action, the door and the result. (A19)
9. With `Map:GateCommands:Enabled=false`, send a command. **Expected:** the endpoint refuses, and nothing changes.
   (flag)

## 8. Phase 6b: gate command buttons (#742, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 8.0 Preconditions

1. Deployed: phases 3 and 6a, the web app from `next`. Settings as § 7.0.

### 8.1 Steps

1. As **gate admin**, open `/map` and click the gate. **Expected:** Open, Close, Toggle and Repair per door and for the
   whole gate. (A18)
2. Click Open on door 1. **Expected:** the door opens in game, and the panel shows "open" after the result. (A18)
3. Start a siege on the gate. **Expected:** the buttons are disabled with "Gate is in a running siege". (A18)
4. As **world staff**, click the gate. **Expected:** no command buttons. (A18)

## 9. Phase 7: player moderation panel (#743, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 9.0 Preconditions

1. Deployed: phase 4b, the web app from `next`. Player A is online.
2. Accounts: **kick moderator**, the **player** account, and a staff member holding every moderation node.

### 9.1 Steps

1. As the **kick moderator**, click A on the map. **Expected:** the panel shows only Kick and "Open profile". (A20)
2. Click Kick. **Expected:** A is kicked in game, the same as from the moderation page. (A20)
3. As the staff member with every moderation node, click a player. **Expected:** Freeze, Unfreeze, Kick, Ban and
   "Open profile". Freeze works as on the moderation page. (A20)
4. As the **player** account, click A. **Expected:** only the name card. (A21)
