# Overview map — BlueMap in the web app for players, staff and moderation

**Status:** **Decided 2026-11-18** (developer). Proposed the same day; no open questions.
**Last updated:** 2026-11-20 (fix link F3, #826 and #825, built on `claude/overview-map-f3-map-drawing` in knk-web-app and knk-workspace, in review: O36–O42, § 4 items 1–2, § 5 rules 4–5, as built in § 6.3.5); 2026-11-19 (fix link F2, #757 and #809, built on `claude/overview-map-f2-panel-fixes` in knk-web-app and knk-workspace, in review: O34, O35, § 5 rules 12 and 14, as built in § 6.3.5 and § 6.3.8); 2026-11-18 (phase 7, #743, built on `claude/overview-map-moderation` in knk-web-app and knk-workspace, in review; as built in § 6.3.8); 2026-11-18 (phase 6b, #742, built on `claude/overview-map-gate-buttons` in knk-web-app and knk-workspace, in review; as built in § 6.3.6); 2026-11-18 (phase 6a, #741, built on `claude/overview-map-gate-commands` in knk-web-api and knk-plugin, in review; as built in § 6.2.10 and § 7.5); 2026-11-18 (phase 4b, #739, built on `claude/overview-map-players-page` in knk-web-app and knk-workspace, in review; as built in § 6.3.6); 2026-11-18 (phase 5, #740, built on `claude/overview-map-staff-details` in knk-web-app and knk-workspace, in review; as built in § 6.3.3); 2026-11-18 (phase 4a, #738, built on `claude/overview-map-players-api` in knk-plugin and knk-web-api, in review; as built in § 6.2.9 and § 7.4); 2026-11-18 (phase 3, #737, built on `claude/overview-map-page` in knk-web-app and knk-workspace, in review; as built in § 6.3.5, deploy notes in the closed-alpha runbook Phase 10); 2026-11-18 (phase 2, #736, built on `claude/overview-map-public-api` in knk-web-api, in review; as built in § 6.2.8); 2026-11-18 (phase 1, #735, built on `claude/overview-map-outlines` in knk-plugin and knk-web-api, in review, not in `next` yet; stored shape in § 6.1.1); 2026-11-18 (§ 3.1.10: existing NAS render container, migration to the alpha stack; Decided; phases filed as #735–#743; first version from the working draft of 2026-11-17 and the design session of 2026-11-18)
**Issue:** [PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732); phases as sub-issues in § 11.
**Dependencies:** the offline BlueMap tile pipeline ([BLUEMAP_EVALUATION.md](BLUEMAP_EVALUATION.md) § 5–7); the SignalR
game hub (#66, built); managed WorldGuard regions (`docs/architecture/managed-worldguard-regions.md`, built); gate
structures and siege matches (built).
**Authority:** the developer's voice discussion of 2026-11-17 ([PUBLIC_OVERVIEW_MAP_DRAFT.md](PUBLIC_OVERVIEW_MAP_DRAFT.md))
and answers of 2026-11-18. This spec supersedes the draft where they differ (draft 7.7: no BlueMap plugin on the game
server, O15). This document is the canonical specification, not a claim that the proposed entities, endpoints or
behaviour exist.

Related: [DESIGN.md](DESIGN.md) (in-game maps, M2–M5), [DECISION-map-data-source.md](DECISION-map-data-source.md),
[../siege-minigame/SIEGE_WEAPONS.md](../siege-minigame/SIEGE_WEAPONS.md) § 8 (#613 tactical map),
[../territory/DESIGN.md](../territory/DESIGN.md) (#689, #690 outlines).

## 1. Goal and scope

1. **Goal:** anyone can open a map of Knights and Kings in the web app, find towns, districts and structures, click
   them for information and watch online players move. Logged-in staff see more and act from the same map: operate a
   gate, open a player's moderation actions. The map is built so new custom actions plug in without touching BlueMap.
2. **In scope (v1):**
    1. The `/map` page with BlueMap's viewer in an iframe and a bridge script (O14).
    2. Town, district and structure pins, labels, the town region flash and toggle, public info panels (O04–O06, O16).
    3. Region outlines reported by the plugin and stored by the API (O15).
    4. Live players with per-viewer visibility, in-game name format, tags and minigame arena pins (O07, O08, O13).
    5. Staff detail in the panel through a compact display-configuration renderer (O16).
    6. Gate quick actions as live commands (O17).
    7. A player context panel with the moderation page's actions (O11).
3. **Out of scope:**
    1. Teleport from the map (draft 10.2–10.3): its own design pass with its own nodes (#733).
    2. The siege tactical and targeting map: #613.
    3. Territory outlines: #689 / #690, which reuse this foundation.
    4. In-game battle map tables: #224.
    5. Create and full update of entities: they stay in the form wizard (O09).
    6. Hover tooltips: BlueMap is click-driven (draft 5.1).

## 2. Decision log

| ID | Date | Who | Decision |
|---|---|---|---|
| O01 | 2026-11-12 | developer | BlueMap is the renderer (in-game maps M2). |
| O02 | 2026-11-17 | developer | The map is public, no login; only properties safe for anyone appear (draft 2.2). |
| O03 | 2026-11-17 | developer | Info panel data is fetched from knk-web-api on click; no live push for the panel (draft 2.3). |
| O04 | 2026-11-17 | developer | Pin labels are always visible or visible from a zoom level, not only on click (draft 2.4). |
| O05 | 2026-11-17 | developer | Towns: pin + name label; click flashes the town region two or three times; panel toggle shows the whole town region with its districts as extrude markers; districts labelled with display name, never the region id (draft § 3). Showing all districts at once is to be reviewed after the first test. |
| O06 | 2026-11-17 | developer | Structures: pin labelled with entity type and subtype; panel shows name, description, state; a gate adds its doors (open/closed) and possibly health (draft § 4). |
| O07 | 2026-11-17 | developer | Live players with head and name, refresh configurable (default about 1–2 s); staff/owner-mode players hidden from anonymous viewers and from logged-in viewers without the in-game visibility node; a permitted viewer sees them as normal players with a mode tag; label format as in game: [group] in group colours, title, username; tags owner mode, staff mode, AFK, short minigame tag (draft § 7). |
| O08 | 2026-11-17 | developer | ~~Anonymous viewers see only the short minigame tag; the minigame's name is shown to logged-in viewers only (draft 7.9).~~ Superseded by O31. |
| O09 | 2026-11-17 | developer | Permitted staff get extra details and quick actions in the panel, gated by the existing area permission nodes, no new nodes where one exists; create and full update stay in the form wizard (draft § 8, 9.2). |
| O10 | 2026-11-17 | developer | Three roles share one BlueMap foundation: player view, admin tool, siege view; the siege view stays the separate team-only page (#613) (draft § 9). |
| O11 | 2026-11-17 | developer | Permitted staff can open a player context panel with the moderation page's actions, reusing its endpoints and nodes; teleport is a desire with its own later design pass (draft § 10). |
| O12 | 2026-11-18 | developer | v1 covers all four parts (public pins and panels, live players, staff quick actions, moderation panel), built in phases that each merge on their own; teleport stays After v1. |
| O13 | 2026-11-18 | developer | Players in a running minigame are not shown with their positions on the overview map: the arena gets one pin with the player count instead (for example "Siege: 12 players"), so the map can't be used to scout. |
| O14 | 2026-11-18 | developer (delegated to agent) | Hosting: a `/map` page in knk-web-app with every panel and action in React, and BlueMap's unmodified viewer in an iframe. A small bridge script loaded into BlueMap (webapp `scripts`) only draws markers, flashes and toggles regions, moves the camera and reports clicks, over a versioned postMessage protocol. Panels and actions plug into a map action registry (entity type → panel widgets and actions, each with its permission node), because the developer plans many more custom actions; new actions never touch the BlueMap side. (Developer: "I plan a lot more custom action features … I go with what you recommend"; alternatives in 2.1.) |
| O15 | 2026-11-18 | developer | Data source: our own API, no BlueMap Paper plugin on the game server. knk-plugin reports positions, AFK and mode over the SignalR game hub and domain region outlines when they change; knk-web-api filters per viewer and serves the map endpoints; the bridge script draws everything. BlueMap is offline tiles plus viewer only. Supersedes the draft's 7.7 assumption that the BlueMap plugin must run on the game server. (Matrix in [DECISION-map-data-source.md](DECISION-map-data-source.md).) |
| O16 | 2026-11-18 | developer | Panel: a fixed, allow-listed public DTO per type from a public map endpoint, shown by small React widgets; for staff with the type's read node, a new compact mode of the display-configuration renderer below it, plus the action registry's live widgets and actions. Public fields change only through code review. |
| O17 | 2026-11-18 | developer | Gate quick actions are live commands (open, close, toggle, repair, per door or the whole gate): new API command endpoints sent to the plugin over the game hub and executed at once with the normal animation, gated by `knk.gate.admin`; refused while a siege match runs on that gate. `knk.admin.world` only unlocks the extra details. |
| O18 | 2026-11-18 | agent | Structure pin position: the structure's `Location` (its spawn point) when set, otherwise the 2D centroid of its region outline; with neither, no pin. Town and district pins follow the same rule. (alternatives in 2.1) |
| O19 | 2026-11-18 | agent | Label distances are configuration, not code: `Map:Labels:<Town|District|Structure|Arena>:MaxDistance` in the API, sent to the bridge with the markers. Defaults: town labels at every zoom, district and structure labels only when close (BlueMap distance about 1500 and 600 blocks). (alternatives in 2.1) |
| O20 | 2026-11-18 | agent | A district's "display name" is `Domain.Name`; the region id is `WgRegionId`. No new `DisplayName` field. (alternatives in 2.1) |
| O21 | 2026-11-18 | agent | Live players reach the browser by REST polling of `GET api/Map/players` at the configured interval (default 2 s). The API builds one snapshot per tick for each audience (anonymous, logged in, may see hidden players) and answers from it, never filtering per request. (alternatives in 2.1) |
| O22 | 2026-11-18 | agent | "May see hidden players" is the in-game rule of `ModeService`: the viewer holds `knk.mode.staff` or `knk.mode.owner` (or `*`), resolved by the API's permission resolver for the logged-in user. No new node. (alternatives in 2.1) |
| O23 | 2026-11-18 | agent | Name labels follow `ChatLineFormat`: `[OWNER]` / `[STAFF]` for holders of those nodes, otherwise the premium-tier or group title, then the username, with the group's `ChatPrimaryColor` / `ChatSecondaryColor`. The API returns the parts and colour codes; the web app turns `&` codes into CSS colours. Tags (owner mode, staff mode, AFK) are separate fields. (alternatives in 2.1) |
| O24 | 2026-11-18 | agent | A minigame arena pin sits at the match's objective (for a siege: the gate structure's pin position) and shows the live participant count. Only running matches get a pin. (alternatives in 2.1) |
| O25 | 2026-11-18 | agent | The player context panel opens for a viewer holding any moderation node (`knk.freeze`, `knk.unfreeze`, `knk.kick`, `knk.ban`, `knk.admin.user.manage`); each action shows under its own node through `useActionGate`, reusing `usePlayerFreeze` / `usePlayerKickBan` and the existing endpoints, with a link to the full player profile page. (alternatives in 2.1) |
| O26 | 2026-11-18 | agent | BlueMap's web app and tiles are served by Nginx on the web app's own origin under `/bluemap/`, so the iframe and the page share one origin and the bridge checks `event.origin` against it. (alternatives in 2.1) |
| O27 | 2026-11-18 | agent | Everything is off by default: API `Map:Enabled` (public map endpoints and the page's config), `Map:LivePlayers:Enabled`, `Map:GateCommands:Enabled`; plugin `map.reporting.enabled` (default `false`) and `map.reporting.interval-ticks` (default `40`, 2 s). The web app shows the nav entry only when the API says the map is on. (alternatives in 2.1) |
| O28 | 2026-11-18 | agent | Region outlines are persisted in a new table `map_region_outlines` (region id, world, 2D points, min Y, max Y, updated at; additive migration), written by the plugin on startup reconcile and whenever a domain region changes, so the map keeps its outlines while the game server is down. (alternatives in 2.1) |
| O29 | 2026-11-18 | agent | Public map endpoints get their own per-IP rate-limit policy `map` (default 120 per minute: player polling at 2 s is 30), configured by `RateLimiting:Map:PermitPerMinute`. (alternatives in 2.1) |
| O30 | 2026-11-18 | agent | v1 shows all districts at once when a town is toggled on, without fade-in (O05); the smoke test has a step for the developer to judge it, and a change is a follow-up issue. (alternatives in 2.1) |
| O31 | 2026-11-18 | developer | Everyone, anonymous viewers included, sees the in-game minigame tag on an arena pin, for example "[Siege] 12 players". No team or match detail is public. Supersedes O08. |
| O32 | 2026-11-18 | developer | Public panel fields (draft 6.1): town: name, description, number of districts; district: name, description, town; structure: name, description, type and subtype, district and town, street and house number; gate: plus per door name, open/closed, destroyed, health bar, and "under siege" while a match runs. Door health is shown always, also during a siege. |
| O33 | 2026-11-18 | developer | Teleport from the map is filed as idea #733 for its own design pass. |
| O34 | 2026-11-19 | developer | "Open profile" in the player context panel stays visible for every viewer of the panel, but is **disabled, with a tooltip** that says why ("You need access to player profiles (knk.admin.user.manage) to open this.") for a viewer without the profile page's node `knk.admin.user.manage`; viewers with it keep the working link. A deliberate exception to the map's staff-action rule (actions a viewer may not take are hidden, not disabled: § 6.3.5, § 6.3.8), because a kick-only moderator otherwise lands on a no-access page (#809). |
| O35 | 2026-11-19 | agent | Escape inside BlueMap's iframe: the bridge reports it to the page as the new v1 map → page type `escapePressed` (empty payload; additive under O14, no v1 meaning changed), and the page closes the open panel on it, the same as its own Escape listener (#757). (alternatives in 2.1) |
| O36 | 2026-11-19 | developer | Regions are drawn like the spike's `wg2bluemap` markers (#826), for the town flash and "Show region": outlines simplified (points on a straight line dropped), volumes without edge lines plus one line marker along the top of each outline, and a town as a flat shape with holes where its districts are, so a click inside a district reaches the district; districts stay see-through volumes. Replaces "extrude markers" for the town in O05. ("I found the default extrude marker jagged and overwhelming … Maybe we can re-use that when we show the town region marker.") |
| O37 | 2026-11-19 | developer | Fewer dots when zoomed out (#825): district and structure dots hide beyond their label's distance (O19), as their labels do; town dots always show. Grouping nearby dots into clusters is not built and stays an idea for a design pass (#825). |
| O38 | 2026-11-20 | agent | A town's holes are the district regions on the same world whose outline centre lies inside the town outline; the bridge decides by position because the v1 region payload has no town of a district (O14 keeps v1 unchanged). (alternatives in 2.1) |
| O39 | 2026-11-20 | agent | A town's flat shape lies at the town pin's height (its spawn location), else the terrain height under the outline's centre, else y 64. (alternatives in 2.1) |
| O40 | 2026-11-20 | agent | The town flash uses the same style as "Show region" (flat shape and outline line), and the bridge keeps its own colours (`COLORS`) and `depthTest: false`, so a region shows through hills. (alternatives in 2.1) |
| O41 | 2026-11-20 | agent | District and structure volumes are clamped to y 20..120 (the spike's default); a region entirely outside that range keeps its own range. Outline line width 3 for towns, 2 for the others. (alternatives in 2.1) |
| O42 | 2026-11-20 | agent | Arena dots (#739) always show, like town dots: the arena is the one live pin and has no other marker; O37 names districts and structures only. (alternatives in 2.1) |

### 2.1 Agent decisions: alternatives

1. **O18 pin position.** Chosen: spawn location, else region centroid, because the spawn point is where a player
   arrives and staff already set it, while the centroid covers structures without one.
    1. (a) Always the centroid: an L-shaped or ring region puts the pin outside the structure.
    2. (b) Always the spawn: structures without a `Location` would have no pin.
2. **O19 label distances.** Chosen: API configuration, because the developer wants to tune after a first test without
   a build.
    1. (a) Hard-coded in the bridge script: every change is a web app release.
    2. (b) Per-entity setting in the database: no need yet for per-town values.
3. **O20 district name.** Chosen: `Domain.Name`, because it already is the human name and the region id is a separate
   field.
    1. (a) A new `DisplayName` column: a schema change for a name that already exists.
4. **O21 player transport.** Chosen: polling against per-audience snapshots, because anonymous viewers have no JWT
   and the web hub requires one; snapshots keep the cost flat in the number of viewers.
    1. (a) SignalR push on `/api/hubs/web`: anonymous hub connections would be a new auth mode on that hub.
    2. (b) Filtering per request: cost grows with every open map.
    3. (c) Server-sent events: one more transport to run behind the proxy for little gain at a 2 s interval.
5. **O22 visibility node.** Chosen: the in-game nodes, because the draft asks for the same node as in game (7.3) and
   O09 forbids new nodes where one exists.
    1. (a) A map-only node: two rules for one secret that could drift apart.
6. **O23 name format.** Chosen: the chat line format, because the draft asks for the in-game format (7.5) and the
   API already resolves the colours into `UserSummary`.
    1. (a) The tab-list team format: it puts title and prestige in a footer, which a map label doesn't have.
    2. (b) Rendering the whole label in the API as HTML: mixes markup into the API and blocks restyling.
7. **O24 arena pin.** Chosen: the objective's position, because sieges are fought around the gate and the data exists.
    1. (a) The centroid of the scenario area: scenario bounds are not on every match record yet.
8. **O25 moderation gate.** Chosen: any moderation node opens the panel, each action under its own node, because a
   moderator with only `knk.kick` should still get the kick button.
    1. (a) Gate the panel on `knk.admin.user.manage` like the page: excludes kick- or freeze-only moderators.
9. **O26 hosting.** Chosen: same origin under `/bluemap/`, because it removes CORS and gives the bridge one fixed
   origin to trust.
    1. (a) A `map.` subdomain: a second certificate and a cross-origin message check for no benefit now.
10. **O27 flags.** Chosen: one flag per part, off by default, because each phase merges on its own and live players
    and gate commands carry the most risk.
    1. (a) One `Map:Enabled` flag: gate commands could not be held back while the public map is on.
11. **O28 outline storage.** Chosen: a table, because the public map must work while the game server restarts.
    1. (a) Memory only, resent on connect: an API restart during server downtime empties the map.
    2. (b) A JSON file next to the tiles: a second write path outside the API.
12. **O29 rate limit.** Chosen: a dedicated policy, because the `lookup` limit (20 per minute) is below one map's
    polling rate.
    1. (a) No limit: a public endpoint without one breaks the default the API keeps everywhere else.
13. **O30 districts.** Chosen: show all at once in v1, because the developer marked it for review after the first
    test (draft 3.6).
    1. (a) Build a fade-in now: work that the review may drop.
14. **O35 Escape in the iframe.** Chosen: the bridge reports Escape as a new message type, because it works wherever
    the focus is inside the map (after a click on a pin, a player or the map itself while a panel is open), leaves
    the focus where the viewer put it, and is additive to the frozen v1 protocol (an older page ignores it, an older
    bridge never sends it).
    1. (a) The page moves focus to the panel when it opens: a later click on the map (to pan with the panel open, or
       on another pin of the same panel) puts the focus back in the iframe and Escape stops working again; it would
       also take the keyboard away from BlueMap's own controls on every open.
    2. (b) A new protocol version for it: v2 for one additive type breaks the older side for nothing.
15. **O38 town holes.** Chosen: by position (a district outline whose centre lies inside the town outline), because
    it works for the flash and "Show region" alike and needs no protocol change.
    1. (a) A `townId` on the region payload: a change to the v1 `setMarkers` message the link may not make (O14).
    2. (b) The other regions of the same "Show region" group: the flash shows the town alone and would get no holes,
       so a click inside a district during the flash would open the town.
16. **O39 flat town height.** Chosen: the town pin's height, else the terrain under the centre, else 64, because the
    spawn location is a known ground-level point the API already sends.
    1. (a) The outline's `minY`: a full-height WorldGuard region has `minY` -64, under the world.
    2. (b) The terrain height under the centre only: unknown until that tile has loaded, and the centre of a town on
       a hill or by the sea can be far off its streets.
    3. (c) A fixed height in `webapp.conf` like the spike's `town-y`: one height for every town, and a deploy step.
17. **O40 flash style, colours and depth.** Chosen: the flash looks like "Show region", the bridge's colours stay, and
    `depthTest` stays off, because one look for one region is easier to read and the colours already match the pin
    dots.
    1. (a) Flash as a volume: the jagged look the developer asked to replace.
    2. (b) The spike's gold (230, 180, 40) and blue (60, 140, 255): no clear gain, and the pin dots would no longer
       match their regions.
    3. (c) `depthTest` on as in the spike: the flat town shape would hide under hills and buildings.
18. **O41 volume heights.** Chosen: clamp to 20..120 and keep the own range of a region entirely outside it, because a
    full-height region otherwise becomes a wall into the sky, while a district high in the mountains still shows where
    it is.
    1. (a) No clamp: full-height districts stand 384 blocks tall.
    2. (b) The spike's fallback to 20..120 for a region outside the range: draws it where it is not.
19. **O42 arena dots.** Chosen: always shown, because an arena pin is the live match marker and O37 names districts
    and structures only.
    1. (a) Hide by the arena label distance: a running match would vanish from the zoomed-out map.

## 3. Current state and legacy behaviour

1. **Built today (V3, read on `next` 2026-11-18):**
    1. Entities: `Domain` (Name, Description, WgRegionId, WorldName, Location) with `Town`, `District`, `Structure`
       and `GateStructure : Structure` (GateDoors, IsSiegeObjective, CurrentSiegeId, `*Override` fields); `GateDoor`
       (Name, HealthCurrent, HealthMax, IsDestroyed, OpenedState, IsActive, IsInvincible). No anonymous read endpoint
       for any of them; reads need `knk.admin.world` or the plugin key.
    2. Gates: `PUT api/GateDoors/{id}/state` and `/health` are the plugin persisting state, not commands;
       `PATCH api/GateStructures/{id}/overrides` (`knk.gate.admin`) stores overrides applied after a match; repair is
       in game only (`/gatedoor repair here`).
    3. Realtime: `/api/hubs/game` (plugin key) with `ReportRoster`, `PlayerJoined`, `PlayerLeft` feeding the in-memory
       `PresenceRegistry` (uuid, name, world; no coordinates); `/api/hubs/web` (JWT) with doorbell events.
    4. Modes: `ModeService` (knk-paper `modes/`), `User.ActiveMode` (None, Staff, Owner); vanished players are seen by
       holders of `knk.mode.staff` / `knk.mode.owner`. AFK: `AfkTracker` (knk-core) and `StatisticsService.isAfk`;
       the API gets only AFK time totals. Siege tag: `ScoreboardUtil.setSiegeTag` (" [Siege]").
    5. Name format: `ChatLineFormat` (knk-paper `chat/`); colours from `PermissionGroup.ChatPrimaryColor`,
       `ChatSecondaryColor`, `NameColor`, resolved into `UserSummary`.
    6. Web app permissions: `useStaffAccess.ts` (`usePermission`, `usePermissions`, `useAnyAreaNode`) and
       `useActionGate.ts`; nodes checked through `GET api/Users/{id}/permissions/check`.
    7. Display configurations: `DisplayWizard` (`src/components/DisplayWizard/`), page-sized, no compact mode;
       `DisplaySection`, `DisplayField`, `useTemplateParser` and `DisplayPreview.orderedSections()` are reusable.
       Reads need an area node.
    8. Moderation: `UserModerationPage` and `PlayerProfilePage` (`knk.admin.user.manage`), actions freeze
       (`knk.freeze`), unfreeze (`knk.unfreeze`), kick (`knk.kick`), ban (`knk.ban`), mode toggle; kick and ban reach the
       plugin as `PlayerKick` / `PlayerBan`. No teleport endpoint.
    9. BlueMap: no code in any component repo. `scripts/bluemap/wg2bluemap.py` builds static town and district
       marker sets from `regions.yml`; the offline render runs on the NAS.
    10. **A BlueMap render container already exists on the NAS** (developer, 2026-11-18): the standalone
        `ghcr.io/bluemap-minecraft/bluemap` container `bluemap-test`, started by hand with `docker run` (not part of
        a Compose stack), with config, data, tiles and a world copy under `/mnt/fast/knk-alpha/bluemap/`
        (`config/`, `data/`, `web/`, `world/`) and its viewer on port 8100. It holds the test render of a
        2,000 × 2,000 area ([BLUEMAP_EVALUATION.md](BLUEMAP_EVALUATION.md) § 6–7). Nothing new has to be set up for
        rendering: it may only need **migrating into the `knk-alpha` stack** as a Compose service (pinned image
        version instead of `latest`, the same folders mounted, render threads at most 4), with Nginx serving its
        `web/` folder under `/bluemap/` (O26). The full-world render (about 20 hours, about 40 GB) is an operations
        step, not a chain link.
2. **V1/V2:** neither legacy version had a web map (no Dynmap or BlueMap code in `knk-v1-archive` or `knk-v2-archive`).
   Nothing to keep or drop.
3. **Related open work:** #224 (in-game maps), #613 (siege tactical map, shares the bridge and tiles), #357 (spot
   picker), #689 / #690 (territory outlines through the same marker path), #66 (realtime), #653 (usability testing).

## 4. Player and admin experience

1. **Anyone (no login).** The header has a "Map" entry. `/map` shows the 3D BlueMap view. Town pins with names are
   visible at every zoom; district and structure pins and their labels appear when zoomed in (O37). Online players move with their head
   and name label. Where a siege runs, one pin reads "[Siege] 12 players" instead of the participants (O31).
2. **Clicking a town.** Its region flashes two or three times and disappears: a flat surface with a clean outline,
   open where its districts are (O36). A side panel (bottom sheet on a phone) shows the public town fields and a "Show
   region" toggle. On: the town region and all its districts stay visible, the districts as see-through volumes with
   an outline along the top, labelled with their names.
3. **Clicking a structure.** The panel shows name, description, type and subtype; for a gate, each door with
   open/closed, destroyed and a health bar.
4. **Clicking a player.** Anonymous and ordinary viewers get the name card (label and tags). A moderator gets the
   player context panel: freeze, unfreeze, kick, ban as their nodes allow, and "Open profile" (disabled, with a tooltip
   saying why, without the profile page's node, O34). Escape or × closes the panel, also when the keyboard focus is
   inside the map after a click there (O35).
5. **Staff with the type's read node** (for example `knk.admin.world`) see an "Details" section under the public part,
   rendered from the type's default display configuration in compact form, with "Open full page" to
   `/display/<type>/<id>`.
6. **Gate admins** (`knk.gate.admin`) see buttons per door and for the whole gate: Open, Close, Toggle, Repair. The
   door animates in game; the panel re-reads the state after the command's result. During a siege match on that gate
   the buttons are disabled with "Gate is in a running siege".
7. **Staff who may see hidden players** see staff- and owner-mode players as normal players with a "Staff mode" or
   "Owner mode" tag; everyone else does not see them at all.

## 5. Rules

1. **Public data is an allow-list (O02, O16).** Public map DTOs are separate types; a field reaches them only through
   code review. The allow-list is O32.
2. **Fresh on click (O03).** The panel fetches its entity when clicked; markers load once per page view and when the
   map's marker version changes (§ 6.2.1).
3. **Pins (O18, O20).** Every town, district and structure with a pin position gets a pin; label = `Domain.Name`;
   structures add type and subtype ("Structure, Gate"). Domains without a region outline and without a location get
   no pin and are listed in the API log once per start.
4. **Labels (O04, O19, O37).** Label distances come from the API configuration. District and structure dots use
   their label's distance too; town and arena dots always show (O42).
5. **Town flash and toggle (O05, O30).** A click flashes the town outline two or three times (configurable,
   default 3, 400 ms each); the toggle shows the town's outline and all its districts until switched off or another
   town is toggled. Both draw the town as a flat shape with holes for its districts and the districts as volumes,
   each with one outline line (O36, O38–O41).
6. **Live players (O07, O15, O21).** The plugin reports, per online player, uuid, world, x, y, z, yaw, AFK, active
   mode and minigame id every `map.reporting.interval-ticks`; the API keeps the latest report per player and drops a
   player on `PlayerLeft` or after three missed intervals.
7. **Visibility (O07, O22).** A player in staff or owner mode appears only in the "may see hidden" snapshot, tagged.
   Anonymous viewers and logged-in viewers without the node never receive them, not even in the response body.
8. **Minigames (O13, O24, O31).** A player in a running match is left out of every snapshot except the "may see hidden"
   one; the match gets an arena pin with the in-game tag and the participant count, the same for every viewer.
9. **Name labels (O23).** As `ChatLineFormat`, with AFK, staff mode and owner mode as tags.
10. **Staff detail (O16).** Shown when the viewer holds the type's read node; rendered from the type's default display
    configuration in compact mode; actions there are links to the full page, never inline edits.
11. **Gate commands (O17).** `knk.gate.admin` (or the plugin key); refused with 409 while a siege match runs on the gate,
    with 503 when no game server is connected, with 400 for a door of another gate. Each command is audit-logged
    with the user. The panel shows the plugin's result (done, refused with reason, timed out after 5 s).
12. **Moderation (O11, O25, O34).** Panel opens with any moderation node; each action under its own node and the
    existing endpoint; the API's own rules still decide. "Open profile" is the one exception to hiding staff actions (§ 6.3.5, § 6.3.8): it
    is disabled, with a tooltip, without `knk.admin.user.manage` (O34).
13. **Action registry (O14).** Each entity type registers public widgets, staff widgets and actions (label, node,
    handler). The bridge never knows about actions.
14. **Bridge protocol (O14).** Messages are versioned (`{v: 1, type, payload}`), accepted only from the page's own
    origin (O26). Page → map: `setMarkers`, `flashRegion`, `showRegions`, `hideRegions`, `setPlayers`, `focus`. Map →
    page: `ready`, `markerClicked {kind, id}`, `playerClicked {uuid}`, `cameraChanged`, `escapePressed {}` (added to v1
    on 2026-11-19 as a new type, O35: Escape while the focus is inside the iframe). New types may be added to v1;
    an existing type's meaning never changes, and each side ignores types it does not know.
15. **Flags (O27).** With `Map:Enabled` off the public map endpoints answer 404 and the nav entry is hidden.

## 6. Data and API

1. **Entities and fields:**
    1. New `MapRegionOutline`: Id, WgRegionId (unique per world), WorldName, PointsJson (2D polygon), MinY, MaxY,
       UpdatedAt. Additive migration (O28). As built (#735): table `map_region_outlines`, unique (WorldName,
       WgRegionId), region ids lower case; `PointsJson` is `[[x,z],...]` in block coordinates (a cuboid's four corners,
       a polygon's points), read with `MapOutlinePoints.Parse`; plus a nullable `DomainId` (the domain naming the
       region as main region or sub-region when it was stored, SET NULL on delete), a hint next to the domain's own
       `WgRegionId`.
    2. No change to Domain, GateStructure or GateDoor.
    3. In memory: `MapPlayerRegistry` (latest report per player) beside `PresenceRegistry`, and the per-audience
       snapshots (O21).
2. **Endpoints** (new `MapController`, route `api/Map`; every public one `[AllowAnonymous]`, rate limit `map`):
    1. `GET api/Map/config`: enabled parts, label distances, flash settings, polling interval, marker version.
       Anonymous.
    2. `GET api/Map/markers`: pins and outlines (towns, districts, structures, arenas) with their public labels.
       Anonymous. Cached; the marker version changes when an outline or a domain changes (`EntityChanged`).
    3. `GET api/Map/towns/{id}`, `GET api/Map/districts/{id}`, `GET api/Map/structures/{id}`: public panel DTOs
       (structure includes gate doors for a gate). Anonymous.
    4. `GET api/Map/players`: the caller's audience snapshot. Anonymous allowed; a valid JWT selects the logged-in
       or "may see hidden" snapshot.
    5. `POST api/GateStructures/{id}/commands` `{action: open|close|toggle|repair, doorId?}`:
       `[RequirePermission(GateAdmin)]` (plugin key not needed: the plugin executes, it doesn't call). Sends
       `GateCommand` on the game hub and waits up to 5 s for `GateCommandResult`.
    6. Game hub additions: plugin → API `ReportMapPlayers(list)`, `ReportRegionOutlines(list)`,
       `GateCommandResult`; API → plugin `GateCommand`.
    7. The new `[AllowAnonymous]` routes join the pinned allow-list in `EndpointAccessRulesTests`; the command
       endpoint gets its rule test.
    8. **As built (#736):** `config`, `markers`, `towns/{id}`, `districts/{id}`, `structures/{id}` in
       `Controllers/MapController.cs`, with the DTOs in `Dtos/MapDtos.cs` (field sets pinned by
       `MapPublicDtoFieldTests`). Settings: `Map:Enabled` (default false: every route 404 before the action runs),
       `Map:Labels:<Town|District|Structure|Arena>:MaxDistance` (0 / 1500 / 600 / 1500; 0 = every zoom, sent as
       `null`), `Map:Flash:Count` / `DurationMs` (3 / 400), `Map:Markers:CacheSeconds` (30),
       `RateLimiting:Map:PermitPerMinute` (120). The marker version is a hash of the marker content, rebuilt at most
       every `CacheSeconds`, so a changed domain or outline gets a new version without an `EntityChanged` hook.
       Outline points are served as stored (block coordinates, inclusive); the bridge draws them through the block
       centres (+0.5). A centroid pin has `y: null` (the bridge picks the height). `config.livePlayers` and
       `config.gateCommands` are present and always off until phases 4a and 6a wire their flags.
    9. **As built (#738):** `GET api/Map/players` in `MapController` (anonymous, `map` rate limit, 404 while
       `Map:Enabled` or `Map:LivePlayers:Enabled` is off, `Cache-Control: no-store`), DTOs `MapPlayersDto`
       (`intervalMs`, `players`, `arenas`), `MapPlayerDto` (`uuid`, `world`, `x`, `y`, `z`, `yaw`, `label`, `afk`,
       `mode`, `minigame`), `MapPlayerLabelDto` (`rankTag`, `braced`, `bracedBold`, `name`, `bracketColor`,
       `textColor`, `&` codes) and `MapArenaDto` (`minigame`, `label`, `playerCount`, `pin`). Game hub
       `ReportMapPlayers({intervalMs, players: [{uuid, world, x, y, z, yaw, afk, mode, minigame, matchId}]})`, kept in
       `Services/Map/MapPlayerRegistry` only while the flag is on; `PlayerLeft` drops a player at once, three missed
       intervals drop them too. `MapPlayerSnapshots` builds the three audience snapshots at most once per
       `Map:LivePlayers:PollIntervalMs` (2000) on the first request after the tick; labels are cached per player for
       `Map:LivePlayers:LabelCacheSeconds` (60). An unknown mode value counts as hidden. An arena pin sits at the
       match's first objective gate with a map pin, else the scenario's lowest gate id with one; a running match is a
       `SiegeMatch` created or in progress (as "under siege", § 6.2.8). `config.livePlayers` follows the flag.
    10. **As built (#741):** `Controllers/GateCommandsController.cs` (`POST api/GateStructures/{id}/commands`, own
        controller on the `api/GateStructures` prefix, `[RequirePermission(GateAdmin)]` pinned in
        `EndpointAccessRulesTests`), `Services/Map/GateCommandService` and the singleton `GateCommandWaiter`. Body
        `{action, doorId?}` (action in any case); answer `GateCommandResponseDto` `{commandId, gateId, doorId, action,
        result, message, doors[]}` with `result` `done` / `refused` (200, the game server's answer and message),
        `siege` (409), `timeout` (504); refusals before sending: 404 `GateCommandsOff` (flag off: nothing sent, nothing
        audited), 400 `ValidationFailed` (unknown action), 404 `GateNotFound`, 400 `DoorNotOfGate` (unknown door or a
        door of another gate), 409 `GateInSiege` (the gate's `CurrentSiegeId` is a match created or in progress, as
        "under siege" in § 6.2.8), 503 `NoGameServerConnected`. Hub: API → plugin `GateCommand` v1 to every connected
        game server, payload `{commandId, gateId, doorId, action, staffUserId, staffUsername}`; plugin → API
        `GateCommandResult({commandId, result, message, doors: [{doorId, state, healthCurrent, healthMax, destroyed,
        outcome, reason}]})`, the first answer per id wins, late ones are ignored, ignored while the flag is off. Audit:
        `AuditAction.GateCommandSent` (65) with subject `GateStructure` / gate id, details `commandId`, `action`,
        `doorId`, `result` (`done`, `refused`, `siege`, `no-game-server`, `timeout`), `message`, `gameServers`; written
        for every command past validation (400 and 404 write none). Settings `Map:GateCommands:Enabled` (false),
        `Map:GateCommands:TimeoutSeconds` (5, 1..30); `config.gateCommands.enabled` follows the flag. The doors of a
        gate for staff (L8): the existing `GET api/GateStructures/{id}/doors` (`GateDoorsController`, any login or the
        plugin key) gives door ids, names and states.
3. **Web app:**
    1. Route `/map` (public in `routeTable.ts`), page `pages/MapPage.tsx`, `components/map/` with `BlueMapFrame`
       (iframe + bridge client), `MapPanel`, `mapActionRegistry.ts`, public widgets per type, `GateDoorsWidget`,
       `PlayerCard`, `PlayerModerationPanel`.
    2. The bridge script lives in knk-web-app `public/bluemap-bridge/bridge.js` and is deployed into BlueMap's
       `webapp.conf` `scripts` (deploy note).
    3. Compact display mode: a `compact` prop on the display renderer (no header, collapsed collections, links
       instead of actions) used by `MapPanel`.
       **As built (#740):** `DisplayWizard` `compact` (passed on to `DisplaySection` and `CollectionSection`; default
       false, the detail page unchanged): no header, every collection a collapsed `<details>` with its name and count,
       values read-only with links to related records, no buttons, hot edit or pickers, and no checks of the nodes of
       those actions. `components/map/staffDetailsRegistrations.tsx` adds a staff widget `staff-details` under
       `knk.admin.world` to town, district and structure (`addWidget`); it renders "Details" with "Open full page" to
       `/display/<type>/<id>?returnTo=/map`, where the type is `Town`, `District`, `Structure` or, for a gate,
       `GateStructure`. The widget (`widgets/StaffDetailsWidget.tsx`) is a lazily loaded chunk, mounted only once the
       viewer's node check says allowed, so anonymous viewers and viewers without the node load neither the renderer
       nor a display configuration (A17, e2e `overview-map-staff-details.spec.ts`).
    4. Playwright specs with the mocked API: pins, panel, toggle, anonymous player list, staff panel, gate buttons,
       moderation panel. The iframe side is mocked by a fake bridge.
    5. **As built (#737):** `pages/map/MapPage.tsx`; `components/map/` with `BlueMapFrame`, `bridgeProtocol.ts`
       (the v1 message types and the page-side guard), `mapMarkers.ts` (markers DTO → bridge payload, outline points
       +0.5), `MapPanel`, `mapActionRegistry.ts` (public widgets, staff widgets and actions per kind, each with its node;
       staff widgets and actions are hidden, not disabled, for viewers without the node), `defaultMapRegistrations.ts`
       and `widgets/` (town, district, structure, `GateDoorsWidget`), `useMapAvailability` (one `api/Map/config` per page
       load; 404 or failure = off). The page polls `config` every 60 s and reloads markers when `markerVersion` changes.
       The town toggle is the bridge region group `town-toggle`; region keys are `<kind>:<id>`. Signed out there is no
       top bar, so the "Map" entry is a link on the start page; signed in it is in the bar; both only while the map is on.
       The bridge (`public/bluemap-bridge/bridge.js`, BlueMap v5.29, spike result on #737) uses its own marker sets
       `knk-pins`, `knk-regions`, `knk-players`, keeps them through BlueMap's 10 s `live/markers.json` reload, draws pins
       as HTML markers (a dot always, the label with `maxDistance`; since F3 the dot too for districts and structures),
       regions as extrude markers (since F3 as below), picks a centroid pin's
       height with `terrainHeightAt`, and maps BlueMap map ids to game worlds with `bridge.js?worlds=<mapId>:<world>`
       (a map id equal to the world name needs none). `setPlayers` draws name labels and reports `playerClicked`, for
       #739. The specs run the real bridge in a fake BlueMap web app (`e2e/fixtures/map.ts`). Hosting: nginx serves
       BlueMap's static `web/` with `X-Frame-Options: SAMEORIGIN` on `/bluemap/` only; BlueMap renders as a profile-gated
       Compose job (closed-alpha runbook Phase 10).
       **Escape in the iframe (#757, O35):** the bridge listens for `keydown` on its own window (capture phase, key
       repeats ignored, the key still reaches BlueMap) and posts `escapePressed {}`; `parseBridgeMessage` accepts it
       and `MapPage` closes the open panel on it, as its own `window` Escape listener does while the focus is on the
       page. Tests: Jest `bridgeProtocol`; e2e `overview-map.spec.ts` (place panel) and `overview-map-players.spec.ts`
       (name card), both pressing Escape after a click inside the map frame.
       **Region drawing and far dots (fix link F3, #826 and #825; O36–O42):** the bridge's `regionMarkers`, used by the
       flash and "Show region", draws each outline the way the spike's `scripts/bluemap/wg2bluemap.py` did. Points on a
       straight line between their neighbours are dropped (`simplifyOutline`). A town outline is a `shape` marker at
       `shapeY` = the town pin's `y`, else `terrainHeightAt` of the outline's centre, else 64, with `holes` for every
       district outline on the same world whose centre lies inside it (`districtHoles`), and `lineWidth: 0`. Any other
       kind is an `extrude` marker with `lineWidth: 0`, its `shapeMinY`/`shapeMaxY` clamped to 20..120 (`clampVolume`;
       a range entirely outside keeps its own). Each outline also gets one `line` marker (`<id>|outline`) closed along
       the top (the shape's height or the volume's `maxY`), width 3 for towns and 2 otherwise; both markers report the
       region's click. Colours stay `COLORS`, `depthTest: false`. In `renderPins` the dot of a `district` or
       `structure` pin carries the pin's `maxDistance` like its label; town and arena dots carry none. The pure helpers
       are exposed as `window.__knkBridgeGeometry` for Jest. Protocol v1 unchanged. Tests: Jest `bridgeGeometry`; e2e
       `overview-map.spec.ts` ("Show region" draws the town flat …, district and structure dots hide …, the flash's
       marker types; the fake BlueMap keeps each marker's data, `__fake.markerData`).
    6. **As built (#739):** `components/map/useLivePlayers.ts` polls `GET api/Map/players` (`mapClient.getPlayers`,
       the JWT when logged in) only while `config.livePlayers.enabled`: at once, then every `intervalMs` of the last
       answer (else `pollIntervalMs`), clamped to 0.5–60 s, one request at a time, skipped while the tab is hidden;
       three failed polls in a row clear the players. `mapPlayers.ts` turns each player into the v1 `setPlayers` entry
       with two optional fields (O14 unchanged): `parts` (the `ChatLineFormat` line `[RANK]-{braced}- name`, the `&`
       codes read with the web app's legacy-text parser into `#RRGGBB` and bold/italic/underline/strikethrough) and
       `tags` (`staff` "Staff mode", `owner` "Owner mode", `hidden` "Hidden mode", `minigame`, `afk` "AFK"); `label`
       stays the plain text. Arena pins: `mapMarkers.toArenaPins` (kind `arena`, id = position in the list, label
       distance `labels.arena`), sent with `setMarkers` only when the arenas change. The bridge draws each player as
       one HTML marker at head height (y + 1.8): label (only `#RRGGBB` colours accepted), tags, head; AFK dims it. The
       head is `bridge.js?heads=<address with {uuid}>` when set in `webapp.conf`, else BlueMap's `assets/steve.png`.
       `playerClicked` opens `MapPlayerPanel` with `PlayerCard` (label and tags from the snapshot, no request); it takes
       `children` for the moderation panel (#743). One panel at a time: a player click closes a place's panel and the
       other way round. Tests: Jest `mapPlayers`, `useLivePlayers`, `PlayerCard`; e2e `overview-map-players.spec.ts`.
    7. **As built (#742):** `components/map/gateCommandRegistrations.tsx` adds a staff widget `gate-commands` under
       `knk.gate.admin` to `structure`, visible for a gate while `config.gateCommands.enabled` is on;
       `MapPanelContext.gateCommands.enabled` comes from the page's shared `api/Map/config` answer
       (`useMapAvailability`, no extra request), and `visible(data, context)` now also gets the context. The widget
       (`widgets/GateCommandsWidget.tsx`, `apiClients/gateCommandClient.ts`) reads door ids from
       `GET api/GateStructures/{id}/doors`, offers Open, Close, Toggle and Repair for the whole gate (no `doorId`) and per
       door, sends `POST api/GateStructures/{id}/commands`, shows the result (`done`, `refused` with the message, 409
       as "Gate is in a running siege", 503, 504 and other errors with the API's message) and then re-reads the panel
       and the door list. Disabled with "Gate is in a running siege" while the public panel's `underSiege` is true or
       after a 409 (until the panel is opened again or `underSiege` goes from true to false). It is placed above the
       staff details. A panel reload now keeps the current data and widgets on screen until the fresh data arrives
       (a new selection still shows "Loading…"). Anonymous viewers make no permission call; without the node or with
       the flag off no door or command request is made (e2e `overview-map-gate-commands.spec.ts`).
    8. **As built (#743):** `components/map/PlayerModerationPanel.tsx` is the `children` of `MapPlayerPanel` for the
       clicked player. It asks the five nodes (`knk.freeze`, `knk.unfreeze`, `knk.kick`, `knk.ban`,
       `knk.admin.user.manage`) through the shared per-page permission cache once a player is clicked and renders
       nothing until one is allowed: anonymous viewers make no request, a viewer without any node makes only those
       checks. Then it reads the player's account by Minecraft UUID with the existing `GET api/Users/uuid/{uuid}`
       (`userManagementClient.getByUuid`, any login; the same lookup the API's map labels use), because the moderation
       endpoints and the profile take the user id; a 404 says the player has no web account yet. A "Moderation" section
       shows "Freeze…" or "Unfreeze" (by the frozen state, as on the profile; with the reason while frozen), "Kick…"
       and "Ban…", each only under its own node (hidden, not disabled), through the profile's unchanged
       `usePlayerFreeze` and `usePlayerKickBan` (same dialogs, endpoints and toasts; a freeze change re-reads the
       account), and "Open profile" to `/admin/users/<id>` (the profile page keeps its own `knk.admin.user.manage`
       gate). No API change. Tests: Jest `PlayerModerationPanel`, e2e `overview-map-moderation.spec.ts` (A20, A21).
       **"Open profile" without the profile node (#809, O34):** the panel reads `knk.admin.user.manage` from the same
       `usePermissions` statuses it already asks (no extra request). Allowed: the link, unchanged. Otherwise a button
       with `aria-disabled="true"` (not a link, goes nowhere) described by a `role="tooltip"` text "You need access to
       player profiles (knk.admin.user.manage) to open this." (`PROFILE_DENIED_TOOLTIP`), shown on hover, keyboard
       focus and tap (a tap keeps it until the focus leaves); Escape hides the tooltip first, a second Escape closes
       the panel.

## 7. Plugin

1. **`knk-core` (Bukkit-free):**
    1. `MapReportingService`: builds the player report and the outline report from two ports; decides the interval
       and the "missed" rule; no Bukkit types.
    2. Ports `OnlinePlayerSnapshotPort` (uuid, world, x, y, z, yaw, AFK, mode, minigame id) and `RegionOutlinePort`
       (outline of a region id).
    3. `GateCommandHandler`: validates a received command against gate state and the running match, calls the
       existing gate open/close/repair operations through their existing ports, returns a result.
2. **`knk-paper` adapters:** `PaperOnlinePlayerSnapshot` (reads players on the main thread, sends off it), a
   WorldGuard `RegionOutlineAdapter` on `WorldGuardIntegration`, hooks into the managed-region reconciler and the
   region rename path to resend outlines, the hub client registrations in `realtime/RealtimeService`.
3. **Configuration:** `map.reporting.enabled: false`, `map.reporting.interval-ticks: 40`. Gate commands follow the
   API flag; the plugin only answers commands it receives.
4. **As built (#738):** knk-core `map/OnlinePlayerSnapshotPort`, `OnlinePlayerPosition` and the player report in
   `MapReportingService` (`collectPlayers` on the main thread, `sendPlayers` off it; positions to 0.1 block, yaw in
   whole degrees, mode `none` / `staff` / `owner`, minigame `siege` with the API's match id; split below the hub limit;
   one empty report when the server empties). knk-paper `map/PaperOnlinePlayerSnapshot` (AFK from player statistics,
   mode from `ModeService`, match from `SiegeService.runningMatchOf` / `runningMatchApiId`) and
   `MapReporting.startPlayerReports` (timer of `interval-ticks`, wrapped in `PluginMetrics.timed("map.player_snapshot")`,
   send on an async task). `interval-ticks` is clamped to 10..1200.
5. **As built (#741):** knk-core `gates/command/GateCommandHandler` (Bukkit-free; on the main thread): refuses with
   `siege` while the gate structure is held by a siege lockdown (`SiegeGateController.lobbyIdOf`), refuses a door that is
   not a loaded door of the gate or a gate without loaded doors, then per door the in-game rules: inactive doors are
   skipped, a destroyed door doesn't open, a door already in the asked state is `already`, a moving door doesn't
   toggle; open/close/toggle through `GateManager.openGate` / `closeGate` (the normal animation, persisted when it ends),
   repair through `GateCommandSupport.repair` (as `/gate repair`: full health, not destroyed, persisted). `done` when at
   least one door acted or already was so, else `refused`. knk-api-client `realtime/GateCommandEvents`; knk-paper
   `realtime/GateCommandRealtimeSync` (command id seen once, handler on the main thread, answer over the hub), wired in
   `KnKPlugin.registerGateCommandSync`. No plugin setting.

## 8. Platform-specific parts

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| Reading online players, positions, AFK | Bukkit `Player`, scheduler | `knk-paper` `map/PaperOnlinePlayerSnapshot` | `OnlinePlayerSnapshotPort` |
| Region outlines | WorldGuard regions | `knk-paper` `map/RegionOutlineAdapter` | `RegionOutlinePort` |
| Executing a gate command | Block animation of the gate | existing `knk-paper` gate code | existing gate ports, via `GateCommandHandler` |
| Tiles and 3D viewer | BlueMap renders Minecraft worlds | NAS render pipeline, Nginx, bridge script | none: no game logic; the API, panels and registry are engine-neutral |

## 9. Risks and integration checks

1. **Main thread:** reading every player every 2 s must stay a cheap snapshot on the main thread with sending off it;
   wrap it in `PluginMetrics.timed` and check with the metrics (#101).
2. **Public surface:** first anonymous endpoints for world data; the allow-list DTOs and the access tests are the
   guard. Check that no `UserSummary` field beyond the label parts reaches the anonymous snapshot.
3. **Coordinates of players are public** (O07): an informed choice of the developer; staff, owner mode and match
   participants are excluded.
4. **Tiles vs. live data:** tiles are a snapshot (M5); a new building shows its pin before its blocks render.
5. **BlueMap upgrades:** the bridge uses BlueMap's web app API (markers, camera); pin the BlueMap version in the
   deploy notes and recheck the bridge on upgrades.
6. **Check before building:** BlueMap's web app lets a script add marker sets and listen to clicks at runtime, and a
   per-player layer can be drawn as HTML markers (phase 3 spike in its first hour; fallback: the bridge draws
   players as POI markers).
7. **Existing NAS render container** (§ 3.1.10): phase 3's deploy notes migrate `bluemap-test` into the
   `knk-alpha` Compose stack instead of setting up a new renderer. Changes on the NAS go through the developer
   (`knk-deploy`, ask before each change); the link writes the Compose service and Nginx block as deploy notes and
   does not run them.
8. **Siege tactical map (#613)** reuses the bridge and must keep its own token and area lock; the overview map never
   shows team markers.

## 10. Acceptance checklist

| ID | Check | Phase |
|---|---|---|
| A01 | With `map.reporting.enabled` on, the plugin sends every domain's outline at startup; the API stores one row per region id and world. | 1 |
| A02 | Re-running a town's region step or a rename updates its stored outline within one reconcile. | 1 |
| A03 | With `Map:Enabled` off, every `api/Map` route answers 404. | 2 |
| A04 | `GET api/Map/markers` anonymously returns towns, districts and structures with name labels, structures with type and subtype, pins at the spawn location or else the centroid. | 2 |
| A05 | Public panel DTOs contain only the O32 fields (test asserts the exact property set per type). | 2 |
| A06 | The 121st public map request in a minute from one IP gets 429. | 2 |
| A07 | `/map` loads without login, shows the BlueMap view and the town pins with labels at every zoom; district and structure labels only when close. | 3 |
| A08 | Clicking a town flashes its outline three times and opens the panel; the toggle shows the town and all its districts with their names, never a region id. | 3 |
| A09 | Clicking a gate shows its doors with open/closed, destroyed and health bar. | 3 |
| A10 | Bridge messages from another origin are ignored. | 3 |
| A11 | An online player in no mode appears for anonymous viewers within one interval and moves as they move. | 4 |
| A12 | A player in staff or owner mode is absent from the anonymous and plain logged-in responses (body checked) and present, tagged, for a viewer with `knk.mode.staff`. | 4 |
| A13 | AFK shows as a tag within one interval of going AFK. | 4 |
| A14 | A player in a running siege match is absent from the public layers; the arena pin reads "[Siege] <count> players" for anonymous and logged-in viewers alike. | 4 |
| A15 | Name label matches the in-game chat format and colours for an owner, a staff member, a premium player and a default player. | 4 |
| A16 | A player who quits disappears within three intervals. | 4 |
| A17 | A viewer with `knk.admin.world` sees the compact "Details" section of a structure; a viewer without it doesn't, and no display configuration request is made. | 5 |
| A18 | A `knk.gate.admin` holder opens, closes, toggles and repairs a door from the panel; the door animates in game and the panel shows the new state. | 6 |
| A19 | The command endpoint refuses without `knk.gate.admin` (403), during a running siege on the gate (409) and without a connected game server (503); each command is audit-logged. | 6 |
| A20 | A viewer with only `knk.kick` clicks a player and sees only Kick and a disabled "Open profile" with its tooltip (O34); kicking works as on the moderation page. | 7 |
| A21 | A viewer without any moderation node gets only the name card. | 7 |
| A22 | Registering a new action for a type in `mapActionRegistry` shows it in the panel under its node with no change to the bridge script. | 3 |

## 11. Phases

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | Region outlines: knk-core reporting, WorldGuard adapter, hub method, `map_region_outlines` table | A01–A02 | knk-plugin, knk-web-api | tier:3 | `map.reporting.enabled` | #735 | — |
| 2 | Public map API: config, markers, panel DTOs, rate limit, access tests | A03–A06 | knk-web-api | tier:3 | `Map:Enabled` | #736 | 1 |
| 3 | Map page: iframe, bridge script and protocol, pins, labels, flash and toggle, public panels, action registry, deploy notes: migrate the existing NAS `bluemap-test` container into the `knk-alpha` stack and serve `/bluemap/` (§ 3.1.10) | A07–A10, A22 | knk-web-app (deploy notes in knk-workspace) | tier:2 | `Map:Enabled` | #737 | 2 |
| 4a | Live players backend: plugin player reports, registry, per-audience snapshots, arena pins | A11–A16 (API side) | knk-plugin, knk-web-api | tier:3 | `Map:LivePlayers:Enabled` | #738 | 2 |
| 4b | Live players layer in the page, name labels and tags | A11–A16 (page side) | knk-web-app | tier:2 | `Map:LivePlayers:Enabled` | #739 | 3, 4a |
| 5 | Staff detail: compact display renderer in the panel | A17 | knk-web-app | tier:2 | none (node-gated) | #740 | 3 |
| 6a | Gate commands backend: endpoint, hub command, plugin handler | A18–A19 (API and plugin) | knk-web-api, knk-plugin | tier:3 | `Map:GateCommands:Enabled` | #741 | 2 |
| 6b | Gate command buttons in the panel | A18 (page) | knk-web-app | tier:2 | `Map:GateCommands:Enabled` | #742 | 3, 6a |
| 7 | Player context panel with moderation actions | A20–A21 | knk-web-app | tier:2 | none (node-gated) | #743 | 4b |

Feature tier: **tier:3** (new public API surface, schema change, a new hub stream from the game server).

Smoke test: [guides/overview-map-smoke-test.md](../../guides/overview-map-smoke-test.md) 

## 12. Open questions

None: 12.1 (anonymous minigame tag) became O31, the public field list O32, teleport O33.

### After v1

1. District fade-in, if the review of O30 asks for it.
2. Teleport from the map (PandiO/knk-workspace#733).
3. Other structure subtypes' widgets and actions through the registry.
4. Grouping nearby pin dots into cluster markers when zoomed out (#825, O37): needs a design pass.
