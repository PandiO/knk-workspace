# Overview map — smoke test

**Status:** Draft · **Last updated:** 2026-11-19 (§ 3 step 4, § 5 step 7: Escape also after a click inside the map, #757; § 9 steps 1, 3 and 4: "Open profile" disabled with a tooltip without `knk.admin.user.manage`, #809; fix link F2); 2026-11-18 (§ 3 step 1: opening `/bluemap` itself goes to `/map`, #737); 2026-11-18 (§ 3 step 4: Escape only with the focus on the page, #757; docs #766)
**Coverage:** Written from the design 2026-11-18; no steps run. § 1 updated to what L1 built (7 steps, all partly automated, tagged), § 2 to what L2 built (7 steps: 2 automated, 5 partly automated, tagged), § 3 to what L3 built (11 steps: 1 automated, 9 partly automated, 1 manual only, tagged), § 4 to what L4 built (9 steps: 1 automated, 5 partly automated, 3 manual visibility steps), § 5 to what L5 built (8 steps: 1 automated, 7 partly automated, tagged), § 6 to what L6 built (7 steps: 2 automated, 5 partly automated, tagged), § 7 to what L7 built (10 steps: 4 automated, 6 partly automated), § 8 to what L8 built (9 steps: 3 automated, 6 partly automated), § 9 to what L9 built (8 steps: 3 automated, 4 partly automated, 1 manual only; since F2, #809: 3 automated, 5 partly automated); every section is now updated to what was built.
**Design:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md) · **Issue:**
[PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732)
**Guides:** [player](users/overview-map-player-guide.md), [admin](admin/overview-map-admin-guide.md)

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
   open `https://app.knightsandkings.net/bluemap` and `https://app.knightsandkings.net/bluemap/`. **Expected:** both
   go to `/map` (a 302; BlueMap only opens inside the map page's frame, under the app's header); in `/map` the frame's
   request for `/bluemap/` answers 200 with `X-Frame-Options: SAMEORIGIN` (developer tools, Network), any other page
   `DENY`; `/bluemap/settings.json` opened in a tab lists the bridge script under `scripts`.
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
4. [partly automated: e2e `"Show region" shows the town and all its districts by name, and hides them again (A08)`,
   `Escape closes the panel after a click inside the map frame (#757)`, Jest `bridgeProtocol` "accepts escapePressed
   ..."; by hand: the verdict, Escape on the real BlueMap viewer] Turn on "Show region". **Expected:** the town outline
   and every district of that town stay visible, each district labelled with its name, never a region id
   (`domain_...`). Close the panel with the ×: the regions stay. Click the town again: the switch is on. Click once on
   the map itself (inside the map, not on the panel) and press Escape: the panel closes, also with the keyboard focus
   inside the map ([#757](https://github.com/PandiO/knk-workspace/issues/757), O35); the regions stay. Click the town
   again and turn the switch off: the regions disappear. Judge whether showing all districts at once works and note
   your verdict for a follow-up (O30). (A08)
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

*Built by link L4 (knk-plugin and knk-web-api branches `claude/overview-map-players-api`, PRs into `next`). 8 steps:
steps 2, 3 and 5 are full manual steps (the visibility checks: the developer's live run of them on
[#738](https://github.com/PandiO/knk-workspace/issues/738) gates the merge of phase 4b, L5), the other 5 are partly
automated (tagged); the by-hand parts need a real Paper server, real accounts and a real siege match. The suites cover
every audience's response body, the plugin report, the drop rules and the labels. Not run yet. Full manual run about
40 minutes.*

Tests named below: knk-web-api `Tests/knkwebapi_v2.Tests` `Api/MapPlayersPipelineTests`,
`Services/Map/MapPlayerSnapshotsTests`, `Services/Map/MapPlayerRegistryTests`, `Services/Map/MapPlayerLabelsTests`,
`Services/Map/MapLivePlayerDataTests`, `Realtime/RealtimeHubTests`; knk-plugin
`knk-core/.../core/map/MapReportingServicePlayersTest` and `knk-paper/.../paper/map/PaperOnlinePlayerSnapshotTest`.

### 4.0 Preconditions

1. Deployed: phase 2 (§ 2), the API and the plugin from `next`. The plugin is connected to the game hub
   (`realtime.enabled: true`; the API log shows `Game server <id> connected to the realtime hub`).
2. Settings:
   1. API (`/etc/knk/api.env`, production installation guide § 4.3; restart the API after a change):
      `Map__Enabled=true`, `Map__LivePlayers__Enabled=true`. Leave `Map__LivePlayers__PollIntervalMs=2000` and
      `Map__LivePlayers__LabelCacheSeconds=60` at their defaults.
   2. Plugin `config.yml` (plugin configuration reference § 4.29; restart the server after a change):
      ```yaml
      map:
        reporting:
          enabled: true
          interval-ticks: 40
      ```
      The log shows `[KnK Map] Live player report every 40 ticks`.
3. Accounts: player A (no mode, no staff nodes), B (a staff member who holds `knk.mode.staff` and can enter
   `/staffmode`), C (the owner, holds `knk.mode.owner`), a premium player P and a default player D; web logins for
   the **player** (no staff nodes) and the **staff viewer** (holds `knk.mode.staff`). A siege scenario whose objective
   gate has a map pin (§ 2 step 3), ready to start.
4. Calls: `curl -s https://<host>/api/Map/players | jq` without a token; with a token add
   `-H "Authorization: Bearer <token>"` (the access token the web app sends; copy it from the browser's network tab).

### 4.1 Steps

1. [partly automated: `MapReportingServicePlayersTest.report_carriesEveryFieldOfSpecRule6_rounded`,
   `movement_isSeenInTheNextReport`, `PaperOnlinePlayerSnapshotTest.snapshot_readsWorldPositionYawAndDefaults`,
   `startPlayerReports_sendsEveryIntervalOffTheMainThread`, `RealtimeHubTests.GameHub_ReportMapPlayers_KeepsThePlayers_PlayerLeftDropsThem`,
   `MapPlayerSnapshotsTests.PlainPlayer_ShowsWithPositionLabelAndNoAccountFields`,
   `OneBuildPerTick_ForAllAudiences_ThenMovementAndAfkShowNextTick`; by hand: a real server] With player A online
   (no mode), call `GET api/Map/players` without a token. Move A 20 blocks and call it again after 2 s.
   **Expected:** 200 with `intervalMs: 2000`; A is in `players` with `uuid`, `world`, `x`, `y`, `z` (to 0.1 block),
   `yaw`, `label` and `afk: false`, `mode: null`, `minigame: null`, and nothing else (no account id, no email). The
   second response shows the new position. (A11)
2. B enters `/staffmode`. Call the endpoint without a token, then with the **player** token. **Expected:** B is absent
   from both response bodies: search the raw JSON for B's UUID and B's name, and for `"staff"`: no hit. A is still
   listed. (A12; the suites check the same in `MapPlayersPipelineTests.Anonymous_And_PlainLogin_GetOnlyThePublicPlayers_RawBody`
   and `MapPlayerSnapshotsTests.PublicAudiences_NeverReceiveModeOrMatchPlayers_NotEvenInTheBody`, but this live run
   is the check that gates phase 4b.)
3. Call it with the **staff viewer** token. **Expected:** B is listed with `mode: "staff"`. C in `/ownermode` is
   listed with `mode: "owner"`. A is listed with `mode: null`. Then B leaves `/staffmode`: within 2 s B is in the
   anonymous response again, with `mode: null`. (A12; in the suites: `MapPlayersPipelineTests.StaffViewer_GetsHiddenPlayersTagged_RawBody`,
   `MapPlayerSnapshotsTests.MaySeeHidden_GetsEveryoneTagged`.)
4. [partly automated: `MapReportingServicePlayersTest.report_carriesEveryFieldOfSpecRule6_rounded`,
   `PaperOnlinePlayerSnapshotTest.snapshot_readsAfkModeAndRunningMatch`,
   `MapPlayerSnapshotsTests.OneBuildPerTick_ForAllAudiences_ThenMovementAndAfkShowNextTick`; by hand: the plugin's
   AFK detection (player statistics on)] A stays idle until the plugin marks them AFK, or uses `/afk`.
   **Expected:** `afk: true` for A within one interval (2 s, plus up to 2 s of the API's snapshot tick). (A13)
5. Start a siege match with A in it. Call the endpoint without a token and with the **player** token. **Expected:** A
   is absent from both (search the raw JSON for A's UUID: no hit). `arenas` has one entry with
   `minigame: "Siege"`, `label: "[Siege] <count> players"` (`<count>` = the match's participants online) and a `pin`
   at the objective gate's map pin (the gate's spawn location or outline centre, as in `GET api/Map/markers`), the
   same for both callers. With the **staff viewer** token A is listed with `minigame: "Siege"`, and the arena entry
   is the same. After the match ends A is back in the public response and `arenas` is empty. (A14; in the suites:
   `MapPlayerSnapshotsTests.ArenaPin_IsTheSameForEveryAudience`, `MapLivePlayerDataTests.Arena_AtTheObjectiveGate_WithTheParticipantCount`,
   `NoArena_ForAnEndedMatch_AnUnknownMatchIdOrAGateWithoutPin`.)
6. [partly automated: `MapPlayerLabelsTests.Owner_FixedOwnerColours_TitleBold`,
   `Staff_AGroupsOwnChatColourReplacesTheFixedOne_FieldByField`, `PremiumMember_TierBeforeTitle_GroupColours`,
   `DefaultMember_TitleOnly_DefaultColoursWithoutGroupColours`, `MapLivePlayerDataTests.Labels_OwnerStaffPremiumAndUnknown`;
   by hand: real groups and colours] With the **staff viewer** token, compare the `label` of C (owner), B (staff), P
   (premium) and D (default) with their in-game chat lines. **Expected:** the same parts: `rankTag` `OWNER` / `STAFF`
   for holders of `knk.mode.owner` / `knk.mode.staff` (else null); `braced` = the text inside `-{ }-` (the title;
   for P the tier name before the title), `bracedBold: true` for owner and staff; `name`; `bracketColor` and
   `textColor` the same `&` colour codes as the chat line (owner `&6` / `&5`, staff `&3` / `&9`, members their group
   colours, else `&2` / `&a`, unless a group of the player set its own). A label change in game shows within 60 s
   (the label cache). (A15)
7. [partly automated: `MapPlayerRegistryTests.Remove_OnPlayerLeft_DropsAtOnce`,
   `Live_DropsAPlayerAfterThreeMissedIntervals`, `MapPlayerSnapshotsTests.QuitPlayer_IsGoneWithinThreeIntervals`,
   `RealtimeHubTests.GameHub_ReportMapPlayers_KeepsThePlayers_PlayerLeftDropsThem`; by hand: a real quit] A quits.
   **Expected:** A is gone from every response within three intervals (6 s), normally on the next snapshot tick
   (`PlayerLeft`). (A16)
8. [partly automated: `PaperOnlinePlayerSnapshotTest.startPlayerReports_sendsEveryIntervalOffTheMainThread` (send
   off the main thread), `MapReportingServicePlayersTest.manyPlayers_areSplitBelowTheHubMessageLimit`; by hand: the
   metrics] With 20 or more players online, read the plugin metrics (with `metrics.enabled: true`, `GET /metrics` on the
   metrics port, `knk_task_duration_seconds{task="map.player_snapshot"}`) during step 1. **Expected:** the snapshot takes well under
   1 ms per run; no noticeable tick time. Note the number. (§ 9.1)
9. [automated: `MapPlayersPipelineTests.Off_Answers404_AndReadsNothing`,
   `RealtimeHubTests.GameHub_ReportMapPlayers_IgnoredWhileLivePlayersOff`,
   `MapReportingServicePlayersTest.off_readsAndSendsNothing`,
   `PaperOnlinePlayerSnapshotTest.startPlayerReports_offDoesNotSchedule`] With `Map__LivePlayers__Enabled=false`
   (or absent) call the endpoint. **Expected:** 404; `GET api/Map/config` shows `livePlayers.enabled: false`. With the
   plugin's `map.reporting.enabled: false` the log has no `Live player report` line. (O27)

## 5. Phase 4b: live players layer (#739, tier:2)

*Built by link L5 (knk-web-app branch `claude/overview-map-players-page`, PR into `next`). 8 steps: 1 automated, 7
partly automated (tagged). The suites run the page against a mocked `GET api/Map/players` (answering per audience as
the API's snapshots do) and the fake BlueMap web app that loads the real bridge script; a real server, real accounts,
real colours on the real viewer and a real siege match are checked by hand. Not run yet. Full manual run about
20 minutes.*

Tests named below: knk-web-app `e2e/overview-map-players.spec.ts` (Playwright, "e2e") and the Jest suites in
`src/components/map/__tests__/` (`mapPlayers`, `useLivePlayers`, `PlayerCard`).

### 5.0 Preconditions

1. Deployed: phases 3 and 4a (§ 3.0, § 4.0), the web app from `next`.
2. Settings: as § 4.0 (API `Map__Enabled=true`, `Map__LivePlayers__Enabled=true`; plugin `map.reporting.enabled: true`).
   Optional: player heads from a skin service, `heads=<address with {uuid}>` on the bridge line of BlueMap's
   `webapp.conf` ([closed-alpha runbook Phase 10](closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737)
   step 3); without it every player has BlueMap's default head.
3. Accounts: as § 4.0 (players A, B, C, P, D; web logins **player** and **staff viewer**).

### 5.1 Steps

1. [partly automated: e2e `players appear with head and name label and move with the next poll (A11)`, Jest
   `useLivePlayers` "polls right away and then every interval ..."; by hand: a real server] As **anonymous**, open
   `/map` with player A online and walking. **Expected:** A's head with the name label above it, on A's position;
   it moves along about every 2 s. A player in another world is not on this BlueMap map. (A11)
2. [partly automated: e2e `labels have the in-game chat format and colours; AFK shows as a tag (A13, A15)`, Jest
   `mapPlayers` › `labelParts (A15)`, `styleOfCodes`; by hand: real groups and colours] Look at the labels of C
   (owner), B (staff, not in a mode), P (premium) and D (default), next to their in-game chat lines.
   **Expected:** the same text and colours: `[OWNER]-{title}- C` with gold brackets and dark purple text, title bold;
   `[STAFF]-{title}- B` dark aqua and blue (or the staff group's own chat colours); `-{tier title}- P` in the tier's
   colours; D in green (or the Default group's colours). (A15)
3. [partly automated: e2e `labels have the in-game chat format ...` (AFK part), Jest `mapPlayers` › `playerTags`; by
   hand: the plugin's AFK detection] D goes AFK (idle, or `/afk`). **Expected:** within about 4 s an "AFK" tag shows
   under D's label and D's label and head are dimmed; it goes away when D moves again. (A13)
4. [partly automated: e2e `logged in: the token goes with every poll and staff viewers see mode players tagged (A12)`,
   `anonymous: mode players the API leaves out are not drawn (A12)`; by hand: the real audiences] B enters
   `/staffmode`, C `/ownermode`. **Expected:** as **anonymous** and as the **player** account, B and C are not on the
   map. As the **staff viewer**, B shows with a "Staff mode" tag and C with "Owner mode". When B leaves staff mode,
   B shows again for everyone within about 4 s, without a tag. (A12)
5. [partly automated: e2e `a running siege shows one arena pin instead of its participants (A14)`, Jest `mapPlayers` ›
   `arena pins (A14)`; by hand: a real match] Start a siege match with A in it, then look at the objective gate as
   **anonymous** and as the **player**. **Expected:** A is not on the map; one pin at the gate reads
   "[Siege] <count> players", its label visible within about 1500 blocks. The **staff viewer** sees A with a "Siege"
   tag and the same arena pin. After the match the pin is gone and A is back. (A14)
6. [partly automated: e2e `a player who quits disappears with the next poll (A16)`; by hand: a real quit] A quits.
   **Expected:** A's head and label are gone within about 6 s (normally at the next poll). (A16)
7. [partly automated: e2e `clicking a player opens the name card with the label and tags only (§ 4.4)`, `Escape closes
   the name card after the click on the player inside the map frame (#757)`, `on a phone the name card is a bottom
   sheet and the page does not scroll sideways`, Jest `PlayerCard`; by hand: the real viewer and a phone] Click D's head or label as **anonymous**. **Expected:** a panel "Player details" with D's name,
   the coloured label and the tags (for example "AFK"), and nothing else (no position, no buttons). Clicking a town
   replaces it with the town's panel; the × closes it. Click D again (the keyboard focus is now inside the map) and
   press Escape: the card closes as well ([#757](https://github.com/PandiO/knk-workspace/issues/757), O35). On a phone
   it opens as a bottom sheet. (A11)
8. [automated: e2e `live players off (Map:LivePlayers:Enabled false): no players request and no player layer (O27)`,
   Jest `useLivePlayers` "makes no request and returns null while the flag is off"] With
   `Map__LivePlayers__Enabled=false` the map shows no players and no arena pins, and the browser's network tab shows
   no `api/Map/players` request. (O27)

## 6. Phase 5: staff details (#740, tier:2)

*Built by link L6 (knk-web-app branch `claude/overview-map-staff-details`, docs on knk-workspace
`claude/overview-map-staff-details`; PRs into `next`). 7 steps: 2 automated, 5 partly automated (tagged); every step
can still be run by hand. The suites run the map page against a mocked API and a fake BlueMap web app (as § 3); real
display configurations, a real render and a real phone are checked by hand. No flag: the section follows the node
`knk.admin.world`. The live run waits for § 3 (the NAS render). Not run yet. Full manual run about 10 minutes; the
untagged parts about 5.*

Tests named below: knk-web-app `e2e/overview-map-staff-details.spec.ts` (Playwright, "e2e") and the Jest suites
`src/components/map/__tests__/staffDetails.test.tsx` ("Jest `staffDetails`") and
`src/components/DisplayWizard/__tests__/DisplayWizard.compact.test.tsx` ("Jest `DisplayWizard.compact`").

### 6.0 Preconditions

1. Deployed: phase 3 as in § 3.0 (the map on: `Map__Enabled=true`), the web app from `next`.
2. Data: the test data above. The types have a default display configuration: `Structure` and `GateStructure` are
   seeded by the API; for `Town` and `District` create one in the display builder if you want to check step 3 fully.
3. Accounts: **world staff** (`knk.admin.world` only), the **player**, and **anonymous**.

### 6.1 Steps

1. [partly automated: e2e `a structure shows "Details" in compact form under the public part, with "Open full page"
   (A17)`, Jest `staffDetails` "shows "Details" under the public part for a viewer with knk.admin.world (A17)"; by
   hand: a real display configuration] As **world staff**, open `/map` and click the structure that is not a gate.
   **Expected:** the panel shows the public part as before (name, type, district, town, address, description) and
   under it a "Details" section with "Open full page". The section shows the type's default display configuration in
   compact form: no heading with the configuration's name or description, small read-only sections with their
   values. "Open full page" opens `/display/Structure/<id>`; its Back button returns to `/map`. (A17)
2. [partly automated: e2e `details are read-only: links instead of buttons, no hot edit`, `collections are collapsed
   and open on a click, their items as links`, Jest `DisplayWizard.compact`; by hand: the real configuration's
   sections] In the same "Details" section. **Expected:** no buttons at all (no Edit, Select, Unlink, Add, Delete,
   Create New, no pencil on a field). A related record (for example the district) is a link to its detail page.
   Every list (collection) is collapsed under its name with the number of items; clicking the name opens it and shows
   the items, each as a link to its own detail page.
3. [partly automated: Jest `staffDetails` "uses the gate's own type for a gate, and Town / District for those panels";
   by hand: the real pages] Click the gate structure, then the town, then a district. **Expected:** the gate's
   "Details" shows the gate display configuration (`GateStructure`) and "Open full page" opens
   `/display/GateStructure/<id>`; the town's and the district's open `/display/Town/<id>` and `/display/District/<id>`.
   A type without a default display configuration shows a one-line message in the section instead of the details;
   the public part stays.
4. [automated: e2e `a logged-in player without knk.admin.world sees no "Details" and no display configuration is
   requested (A17)`, Jest `staffDetails` "mounts nothing for a viewer whose node is denied (A17)"] As the **player**,
   open the browser's developer tools (Network), open `/map` and click the same structure. **Expected:** the public
   panel only, no "Details" section. The network list has no request to `api/DisplayConfigurations/...` and none to
   `api/Structures/...`. (A17)
5. [automated: e2e `an anonymous viewer sees no "Details", and no permission or display configuration request is made
   (A17)`, Jest `staffDetails` "mounts nothing for a viewer whose node is unauthenticated (A17)"] As **anonymous**,
   repeat step 4. **Expected:** no "Details" section; no request to `api/Users/.../permissions/check`, to
   `api/DisplayConfigurations/...` or to `api/Structures/...`. (A17)
6. [partly automated: e2e `on a phone the details fit the bottom sheet without sideways scrolling`; by hand: a real
   phone] As **world staff** on a phone, repeat step 1. **Expected:** the "Details" section is inside the bottom sheet,
   which scrolls vertically; nothing scrolls sideways; the × closes the panel.
7. [partly automated: Jest `DisplayWizard.compact` "the full page keeps its header and buttons (default mode
   unchanged)", the existing detail page suites (e2e `entity-detail.spec.ts`, `town-detail.spec.ts`); by hand: a look]
   As **world staff**, open a structure's detail page from the dashboard. **Expected:** unchanged: the page header with
   the name, Edit and Delete, the sections with their buttons and the pencil on editable fields, lists not collapsed.

## 7. Phase 6a: gate commands backend (#741, tier:3)

*Built by link L7 (knk-web-api and knk-plugin branches `claude/overview-map-gate-commands`, PRs into `next`). 10 steps:
4 automated, 6 partly automated (tagged); the by-hand parts need a real Paper server with the gate in the world, a
real siege match and a real audit log. The suites cover the access rule, every refusal, the timeout, the audit entry,
the hub round trip and the plugin handler with the real gate manager. Not run yet. Full manual run about 30 minutes;
without the automated steps about 20.*

Tests named below: knk-web-api `Tests/knkwebapi_v2.Tests` `Services/Map/GateCommandServiceTests`,
`Api/GateCommandsPipelineTests`, `Security/EndpointAccessRulesTests`, `Realtime/RealtimeHubTests`; knk-plugin
`knk-core/.../core/gates/command/GateCommandHandlerTest`, `knk-api-client/.../api/realtime/GateCommandEventsTest` and
`knk-paper/.../paper/realtime/GateCommandRealtimeSyncTest`.

### 7.0 Preconditions

1. Deployed: the API and the plugin from `next`, with the game server connected to the game hub
   (`realtime.enabled: true`; the API log shows `Game server <id> connected to the realtime hub`). No plugin setting:
   the plugin answers every command it receives.
2. Settings: API (`/etc/knk/api.env`, production installation guide § 4.3; restart the API after a change):
   `Map__GateCommands__Enabled=true`. Leave `Map__GateCommands__TimeoutSeconds=5` at its default. `Map__Enabled` is not
   needed for this endpoint (it is for the panel in § 8).
3. Accounts: **gate admin** (holds `knk.gate.admin`), **world staff** (holds `knk.admin.world` only), and an account
   with `knk.admin.user.manage` to read the audit log. The test gate (id `<gate>`) has two doors (`<door 1>`,
   `<door 2>`, from `GET api/GateStructures/<gate>/doors`), both closed and active. A door of another gate:
   `<foreign door>`. Stand next to the gate in game.
4. Calls: `curl -s -X POST https://<host>/api/GateStructures/<gate>/commands -H "Authorization: Bearer <token>"
   -H "Content-Type: application/json" -d '{"action":"open","doorId":<door 1>}' -w "\n%{http_code}\n"` (the access
   token the web app sends; copy it from the browser's network tab). Leave `doorId` out for the whole gate.

### 7.1 Steps

1. [partly automated: `GateCommandServiceTests.ACommand_IsPublishedToTheGameServers_AndTheResultAnswers`,
   `RealtimeHubTests.GameHub_GateCommand_RoundTrip_TheResultAnswersTheEndpoint`,
   `GateCommandHandlerTest.openOneDoor_StartsItsOpeningAnimation_OnlyThatDoor`,
   `GateCommandRealtimeSyncTest.open_RunsOnTheMainThread_AnimatesTheDoor_AndAnswersDone`; by hand: the animation in a
   real world] As **gate admin**, send `{"action":"open","doorId":<door 1>}`. **Expected:** 200 within a second with
   `result: "done"`, a `message` like `Gate '<name>' open: <door 1 name> started.` and `doors[0]` with
   `state: "opening"`, `outcome: "started"`. Door 1 opens in game with its normal animation; door 2 stays closed. The
   plugin log shows `[KnK Gates] Web gate command open gate <gate> door <door 1> by <user>: done`. After the animation
   `GET api/GateStructures/<gate>/doors` shows door 1 with `openedState` open (persisted when the animation ends). (A18)
2. [partly automated: `GateCommandHandlerTest.close_StartsTheClosingAnimation`,
   `toggle_OpensAClosedDoor_AndClosesAnOpenOne_SkipsAMovingOne`, `openWithoutADoor_OpensEveryDoorOfTheGate_NotOtherGates`,
   `alreadyInTheAskedState_IsDone_AndNothingMoves`, `GateCommandServiceTests.WithoutADoor_TheCommandIsForTheWholeGate`;
   by hand: real animations] Send `close` for door 1, then `toggle` for door 1 twice (wait for each animation), then
   `open` without `doorId`. **Expected:** each answers 200 `done` and acts as named; the last one opens both doors
   (`doors` lists both, door 1 `already` if it was open). A `toggle` sent while the door still moves answers `refused`
   with the door's `reason: "moving"`. (A18)
3. [partly automated: `GateCommandHandlerTest.repair_UsesTheSharedRepair_FullHealthNotDestroyed`,
   `GateCommandRealtimeSyncTest.repair_PersistsHealthAndState_LikeGateRepair`; by hand: real damage] Damage door 1 in
   game until it is destroyed (or `/gatedoor health <door 1> 0`), then send `{"action":"repair","doorId":<door 1>}`.
   **Expected:** 200 `done`, `doors[0]` with `outcome: "repaired"`, `healthCurrent` = `healthMax`, `destroyed: false`;
   in game the door is whole and its health display full; `GET api/GateStructures/<gate>/doors` shows the same. Before
   the repair, `open` for the destroyed door answers 200 `refused` with `reason: "destroyed"`. (A18)
4. [automated: `GateCommandsPipelineTests.WithoutKnkGateAdmin_Is403_EvenWithKnkAdminWorld_AndNothingRuns`,
   `Anonymous_Is401_AndNothingRuns`, `EndpointAccessRulesTests.GateCommands_ArePinnedToKnkGateAdmin_WebOnly`] Send a
   command as **world staff**, and once without a token. **Expected:** 403 `Requires the knk.gate.admin permission.`
   and 401; nothing changes in game and no audit entry is written. (A19)
5. [partly automated: `GateCommandServiceTests.DuringASiegeMatchOnTheGate_Is409_NothingSent_Audited`,
   `ASiegeSeenByTheGameServer_Is409`, `GateCommandHandlerTest.underASiegeLockdown_IsRefusedAsSiege_AndNothingChanges`,
   `GateCommandRealtimeSyncTest.underASiegeLockdown_AnswersSiege_AndTheDoorStays`; by hand: a real match] Start a siege
   match whose scenario uses the gate and send `open` as **gate admin**. **Expected:** 409 with
   `error: "GateInSiege"`, `message: "Gate is in a running siege."`; nothing changes in game. A command for another
   gate still works. After the match ends (gates restored) the command works again. (A19)
6. [automated: `GateCommandServiceTests.NoGameServer_Is503_NothingSent_Audited`] Stop the game server (or set
   `realtime.enabled: false` and restart it) and send `open`. **Expected:** 503 `NoGameServerConnected`. (A19)
7. [automated: `GateCommandServiceTests.ADoorOfAnotherGate_Is400_AndNothingIsSent`,
   `GateCommandHandlerTest.aDoorOfAnotherGate_OrAnUnknownDoor_IsRefused_NothingMoves`] Send
   `{"action":"open","doorId":<foreign door>}` to `<gate>`. **Expected:** 400 `DoorNotOfGate`; nothing moves. An
   unknown action (`"explode"`) is 400 `ValidationFailed`. (A19)
8. [partly automated: `GateCommandServiceTests.EveryCommand_IsAuditLogged_WithUserActionDoorAndResult`; by hand: the
   real log] With the audit-log account, call `GET api/audit-log?subjectType=GateStructure&subjectId=<gate>` (or open
   the audit log page). **Expected:** one `GateCommandSent` entry per command of steps 1–3, 5 and 6, newest first,
   each with the gate admin as actor and details `commandId`, `action`, `doorId` (left out for the whole gate),
   `result` (`done`, `refused`, `siege`, `no-game-server`), `message` and `gameServers`. Steps 4 and 7 wrote none.
   (A19)
9. [automated: `GateCommandServiceTests.NoResult_TimesOutWith504_AndALateResultIsIgnored`] (A game server that does not
   answer within 5 s.) **Expected:** 504 with `result: "timeout"`; the audit entry says `timeout`; a late answer is
   ignored. Not reproducible by hand without a stalled server; the suite covers it. (§ 5 rule 11)
10. [automated: `GateCommandServiceTests.Off_Is404_SendsNothing_AuditsNothing`, `TheFlag_IsOffByDefault`,
    `RealtimeHubTests.GameHub_GateCommandResult_IgnoredWhileOff`, `MapPublicServiceTests.Config_GateCommands_FollowsItsFlag`]
    With `Map__GateCommands__Enabled=false` (or absent), send a command. **Expected:** 404 `GateCommandsOff`, nothing
    changes in game, no audit entry; `GET api/Map/config` (with `Map__Enabled=true`) shows `gateCommands.enabled: false`,
    and `true` once the flag is on. (O27)

## 8. Phase 6b: gate command buttons (#742, tier:2)

*Built by link L8 (knk-web-app branch `claude/overview-map-gate-buttons`, docs on knk-workspace
`claude/overview-map-gate-buttons`; PRs into `next`). 9 steps: 3 automated, 6 partly automated (tagged); every step
can still be run by hand. The suites run the map page against a mocked API and a fake BlueMap web app (as § 3); the
door animating in game, a real siege match and a real phone are checked by hand. Behind the API's
`Map:GateCommands:Enabled` (§ 7.0), read by the page from `config.gateCommands.enabled`. Not run yet. Full manual run
about 20 minutes; the untagged parts about 12.*

Tests named below: knk-web-app `e2e/overview-map-gate-commands.spec.ts` (Playwright, "e2e") and the Jest suite
`src/components/map/__tests__/gateCommands.test.tsx` ("Jest `gateCommands`").

### 8.0 Preconditions

1. Deployed: phase 3 as in § 3.0 (the map on: `Map__Enabled=true`) and phase 6a as in § 7.0 (the game server connected
   to the game hub, `Map__GateCommands__Enabled=true`); the web app from `next`. Reload `/map` after changing a setting:
   the page reads `api/Map/config` once per load.
2. Data: the test gate with two doors, both closed and active; stand next to it in game.
3. Accounts: **gate admin** (`knk.gate.admin` only), **world staff** (`knk.admin.world` only), the **player** and
   **anonymous**.

### 8.1 Steps

1. [partly automated: e2e `sees Open, Close, Toggle and Repair for the whole gate and per door (A18)`, Jest
   `gateCommands` "a knk.gate.admin holder sees Open, Close, Toggle and Repair for the whole gate and per door (A18)";
   by hand: the real doors] As **gate admin**, open `/map` and click the gate. **Expected:** under the public "Doors"
   part a "Gate commands" section with a "Whole gate" row and one row per door (name, state, "Destroyed" when it is),
   each with Open, Close, Toggle and Repair, all enabled. No "Details" section (that needs `knk.admin.world`). (A18)
2. [partly automated: e2e `opens a door: the command carries its doorId, the result shows and the panel shows the new
   state (A18)`, Jest `gateCommands` "sends a door command with its doorId, shows the result and reads the panel and the
   doors again"; by hand: the animation in game] Click Open on door 1. **Expected:** the door opens in game with its
   normal animation. Under the buttons the result appears ("Done: ..." with the game server's message), and the
   public "Doors" part and the door's row show the new state ("Opening", then "Open" after clicking the gate again).
   (A18)
3. [partly automated: e2e `closes, toggles and repairs; a whole-gate command has no doorId (A18)`, Jest `gateCommands`
   "sends a whole-gate command without a doorId and shows a refusal with its reason"; by hand: the doors in game] Click
   Close on door 1, then Toggle in the "Whole gate" row, then damage door 2 in game and click Repair on door 2.
   **Expected:** each command shows its result; door 1 closes; Toggle moves both doors; door 2 is repaired and its
   health bar is full after the panel re-reads. (A18)
4. [partly automated: e2e `shows a refusal, "no game server" and a time-out as the API words them`, Jest `gateCommands`
   "shows "no game server" and the time-out from the API"; by hand: a stopped game server] Stop the game server (or its
   hub connection) and click Open on the whole gate. **Expected:** the result says no game server is connected; the
   buttons work again for the next click. Start the server again. (§ 5 rule 11)
5. [partly automated: e2e `during a siege match every button is disabled with "Gate is in a running siege"`,
   `a 409 from the API (siege started meanwhile) disables the buttons too`, Jest `gateCommands` "disables every button
   with "Gate is in a running siege" while the public panel says under siege"; by hand: a real match] Start a siege
   match on the gate and click the gate again. **Expected:** the public part says "Under siege"; "Gate is in a running
   siege" shows above the buttons and every button is greyed out with the same text as its tooltip. With the panel
   already open when the match starts, the next click gives "Gate is in a running siege" and disables the buttons.
   End the match and click the gate again: the buttons work. (A18)
6. [automated: e2e `with Map:GateCommands:Enabled off there are no buttons and no door or command request`, Jest
   `gateCommands` "is hidden without the node, for anonymous viewers, for a structure that is not a gate and with the
   flag off"] Set `Map__GateCommands__Enabled=false`, restart the API and reload `/map` as **gate admin**; click the
   gate. **Expected:** only the public "Doors" part; the Network tab has no request to `api/GateStructures/...`.
   Turn the setting on again.
7. [automated: e2e `a logged-in player without knk.gate.admin sees the doors but no buttons, and no door ids are
   requested`] As **world staff**, then as the **player**, click the gate. **Expected:** no "Gate commands" section
   (world staff sees "Details"); the Network tab has no request to `api/GateStructures/...`. (A18)
8. [automated: e2e `an anonymous viewer sees the doors, no buttons, and no permission, door or command request is
   made`] As **anonymous**, click the gate. **Expected:** the public "Doors" part only; no request to
   `api/Users/.../permissions/check` or `api/GateStructures/...`.
9. [partly automated: e2e `on a phone the buttons fit the bottom sheet without sideways scrolling`; by hand: a real
   phone] As **gate admin** on a phone, repeat step 1. **Expected:** the buttons wrap inside the bottom sheet, which
   scrolls vertically; nothing scrolls sideways.

## 9. Phase 7: player moderation panel (#743, tier:2)

*Built by link L9 (knk-web-app branch `claude/overview-map-moderation`, docs on knk-workspace
`claude/overview-map-moderation`; PRs into `next`; step 3 and "Open profile" since fix link F2, #809). 8 steps: 3
automated, 5 partly automated (tagged);
every step can still be run by hand. The suites run the map page against a mocked API (live players, the account read by UUID and the
moderation endpoints) and the fake BlueMap web app with the real bridge script; the kick, ban and freeze in game, the
profile page behind "Open profile" and a real phone are checked by hand. No flag of its own: it needs the live players
layer (§ 5, `Map:LivePlayers:Enabled`) and is gated by the viewer's nodes. Not run yet. Full manual run about
15 minutes; the untagged parts about 10.*

Tests named below: knk-web-app `e2e/overview-map-moderation.spec.ts` (Playwright, "e2e") and the Jest suite
`src/components/map/__tests__/PlayerModerationPanel.test.tsx` ("Jest `PlayerModerationPanel`").

### 9.0 Preconditions

1. Deployed: phases 3, 4a and 4b as in § 5.0 (API `Map__Enabled=true`, `Map__LivePlayers__Enabled=true`; plugin
   `map.reporting.enabled: true`), the web app from `next`, the game server connected to the game hub (kick, ban and
   freeze reach the game through it, as from the profile page).
2. Data: player A online in game, with a web account (the account the map reads by A's Minecraft UUID). A second
   Minecraft account B to ban, which you can unban afterwards with `/pardon B` in game.
3. Accounts: the **kick moderator** (`knk.kick` only), the **player** account (no staff nodes), **anonymous**, and a
   **full moderator** holding `knk.freeze`, `knk.unfreeze`, `knk.kick`, `knk.ban` and `knk.admin.user.manage`.

### 9.1 Steps

1. [partly automated: e2e `a viewer with only knk.kick sees only Kick and a disabled "Open profile"; kicking works as
   on the profile (A20, #809)`, Jest `PlayerModerationPanel` "with only knk.kick: Kick and a disabled "Open profile"
   with its tooltip; kick sends the reason (A20, #809)"; by hand: the real account] As the **kick moderator**, open
   `/map` and click A. **Expected:** under A's name card a "Moderation" section with only a "Kick…" button, and
   "Open profile" shown greyed out (disabled, not a link). (A20, O34)
2. [partly automated: same tests; by hand: the kick in game] Click "Kick…", enter a reason and confirm. **Expected:**
   the same dialog as on the player profile ("Kick A?", optional reason); a toast "A is being kicked"; A is disconnected
   in game and sees the reason; A's profile audit log lists the kick with your name, as from the profile page. (A20)
3. [partly automated: e2e `a viewer with only knk.kick sees only Kick and a disabled "Open profile"; kicking works as
   on the profile (A20, #809)` (hover, focus, click), Jest `"Open profile" without the profile node (#809)` (hover,
   focus, tap, Escape); by hand: a real phone, a screen reader if you have one, the profile page for the full
   moderator] As the **kick moderator**, point at the greyed-out "Open profile", then reach it with Tab, then tap it
   on a phone. **Expected:** each time a tooltip "You need access to player profiles (knk.admin.user.manage) to open
   this."; nothing opens and the address stays `/map`; with the focus on it, Escape hides the tooltip and a second
   Escape closes the panel. Then, as the **full moderator**, click A and "Open profile". **Expected:** a normal link;
   A's player profile page (`/admin/users/<id>`) opens. (O34,
   [#809](https://github.com/PandiO/knk-workspace/issues/809))
4. [partly automated: e2e `a viewer with every moderation node freezes, unfreezes and bans from the panel`, Jest
   `PlayerModerationPanel` "with knk.admin.user.manage: the working link, no tooltip (unchanged)", "freeze posts the
   reason and reads the account again", "a frozen player shows the reason
   and Unfreeze for a knk.unfreeze holder"; by hand: the freeze in game] With A back online, as the **full moderator**
   click A. **Expected:** "Freeze…", "Kick…", "Ban…" and a working "Open profile" link. Click "Freeze…", enter a reason and
   confirm: toast "A is frozen", A can no longer move in game, and the section shows "Frozen. Reason: <reason>" with
   "Unfreeze" in place of "Freeze…". Click "Unfreeze" and confirm: toast "A is unfrozen", A can move again. (§ 5 rule 12)
5. [partly automated: e2e same test, Jest `PlayerModerationPanel` "with every node: Freeze, Kick and Ban; ban asks a
   reason and posts it"; by hand: the ban in game] With B online, click B and "Ban…", enter a reason and confirm.
   **Expected:** the dialog "Ban B permanently?" with a required reason; toast "B is banned"; B is kicked with the ban
   screen and cannot rejoin. Lift it with `/pardon B` in game.
6. [automated: e2e `a logged-in viewer without any moderation node gets only the name card (A21)`, Jest
   `PlayerModerationPanel` "without any moderation node: nothing beyond the name card, no account read (A21)"] As the
   **player** account, click A. **Expected:** only the name card (label and tags), no "Moderation" section; in the
   Network tab only the five `api/Users/<your id>/permissions/check` requests for the moderation nodes, no
   `api/Users/uuid/...` and no moderation request. (A21)
7. [automated: e2e `anonymous viewers get only the name card and make no permission or account request (A21)`, Jest
   `PlayerModerationPanel` "anonymous: renders nothing and reads no account"] As **anonymous**, click A. **Expected:**
   only the name card; no request to `api/Users/...` at all. (A21)
8. [automated: e2e `on a phone the panel is a bottom sheet and the page does not scroll sideways`] As the **full
   moderator** on a phone (or a 390 px wide window), click A. **Expected:** the name card and the "Moderation" section
   in the bottom sheet, which scrolls vertically; the buttons wrap; nothing scrolls sideways.

## Changes

1. 2026-11-19: § 3 step 4 and § 5 step 7: Escape closes the panel also after a click inside the map, #757; § 9 steps
   1, 3 and 4: "Open profile" disabled with a tooltip without `knk.admin.user.manage`, #809 (fix link F2)
2. 2026-11-18: § 3 step 4: Escape only with the focus on the page, #757; docs #766
3. 2026-11-18: § 9 to what L9 built, #743
4. 2026-11-18: § 5 to what L5 built, #739
5. 2026-11-18: § 8 to what L8 built, #742
6. 2026-11-18: § 7 to what L7 built, #741
7. 2026-11-18: § 6 to what L6 built, #740
8. 2026-11-18: § 4 to what L4 built, #738
9. 2026-11-18: § 3 to what L3 built, #737
10. 2026-11-18: § 2 to what L2 built, #736
11. 2026-11-18: § 1 to what L1 built, #735
12. 2026-11-18: draft from the design, phases 1, 2, 3, 4a, 4b, 5, 6a, 6b, 7
