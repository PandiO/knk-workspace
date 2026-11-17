# Public overview map (BlueMap in the web app) — working draft

**Status:** Working draft (not a design, nothing decided in detail, no code). Written from the developer's voice discussion of 2026-11-17. Several positions are the developer's first visualisation and are to be revisited after the first test. Input for a design session (`knk-design` skill).
**Last updated:** 2026-11-17
**Issue:** none yet (related: [#224](https://github.com/PandiO/knk-workspace/issues/224) in-game maps, #613 siege tactical map, #689 / #690 territory)
**Related:** [DESIGN.md](DESIGN.md) (in-game maps, BlueMap decision M2–M4), [BLUEMAP_EVALUATION.md](BLUEMAP_EVALUATION.md), [../siege-minigame/SIEGE_WEAPONS.md](../siege-minigame/SIEGE_WEAPONS.md) §8, [../territory/DESIGN.md](../territory/DESIGN.md), `scripts/bluemap/wg2bluemap.py`

## 1. Goal

The web app shows the BlueMap interface as a general, public overview map of Knights and Kings. It shows towns, districts and structures, and clicking them gives information about the underlying entity.

## 2. Decided

2.1 BlueMap is the renderer (chosen over Dynmap, confirmed 2026-11-12, mainly for storage and setup fit).

2.2 The map is fully public for now, no login. Only properties the developer is comfortable showing to anyone may appear in the info panel.

2.3 Info panel data is fetched from knk-web-api when the user clicks, so it is always up to date. No live push for now.

2.4 Pin labels (town names and others) are always visible, or visible from a certain zoom level, not only on click. BlueMap supports this with marker labels and min/max distance values.

## 3. Towns

3.1 A town is shown as a pin on the map with its name as a label.

3.2 Clicking the pin flashes the town's WorldGuard region as an extrude marker two or three times, then it disappears again.

3.3 The info panel then offers a toggle button to show or hide the marker for the entire town region.

3.4 Turning the town region on also displays the extrude markers of that town's districts.

3.5 Districts are labelled with their display name, never the WorldGuard region name.

3.6 **Work in progress:** showing all districts at once when the town is toggled on, possibly with a gradual fade-in, is only the developer's current visualisation. To be judged after the first test and possibly changed.

## 4. Structures

4.1 A structure is shown as a pin. The label shows the structure entity type and subtype, for example Structure, Gate.

4.2 Pin position is left to the design session. Options named: the structure's default spawn point, or a centre point computed on the 2D grid from the structure's WorldGuard region.

4.3 Clicking a structure shows an info panel: name, description, state. For a gate structure this includes its gate doors, whether they are open or closed, and possibly health.

4.4 The exact property list per entity type is still to be defined. Everything must be safe to show publicly.

## 5. Notes from the existing docs

5.1 BlueMap shows marker info on click only. Hover tooltips would need a custom web app script, so the click-driven design fits native behaviour. Custom script is only needed for the flash animation and the region toggle.

5.2 `scripts/bluemap/wg2bluemap.py` already produces town and district markers: towns as a flat shape with holes for districts, districts as extrude volumes. Region marker tests ran on 2026-11-12 ([BLUEMAP_EVALUATION.md](BLUEMAP_EVALUATION.md) §8).

5.3 Territory outlines from the chunk cache are planned through the marker API ([territory design](../territory/DESIGN.md), issues #689 and #690).

5.4 The siege tactical and targeting map (#613) is a separate, team-only page.

## 6. Open questions

6.1 Which properties exactly per entity type are shown in the info panel (towns, districts, gate structures, later other structure subtypes)?

6.2 Structure pin position: spawn point or computed region centre?

6.3 Zoom thresholds for when town, district and structure pins and labels appear.

6.4 How the flash animation and toggle are built in BlueMap's web app (custom script spike).

6.5 Where the info panel lives: inside the BlueMap page, or in the surrounding web app layout.

6.6 Whether districts stay shown all at once, to be reviewed after the first test.

## 7. Live player view

7.1 Online players are shown on the map and move in real time as they move in game, with the player head and name, as BlueMap does natively.

7.2 Position refresh interval is configurable, default about every one to two seconds, so it can be tuned to the performance load.

7.3 Visibility follows the in-game rules. A player in staff mode or owner mode is hidden from every viewer who is not logged in. A logged-in viewer sees them only with the same permission node that grants that visibility in game.

7.4 A viewer who is allowed to see a hidden player sees them as a normal player. The staff or owner mode shows only as a tag in the name.

7.5 Name label format, matching the in-game format: the permission group name in square brackets, styled with that group's colours from the Minecraft plugin template, then the title name, then the username.

7.6 State tags are added to the name: owner mode, staff mode and AFK. A player in a minigame gets only a short bracketed minigame tag in the name. The description names the specific minigame, for example Siege.

7.7 Technical note: BlueMap's built-in player layer is the same for every viewer, so it cannot hide staff per viewer. The map page should fetch the visible players from the server, filtered by who is asking, as the siege tactical map already plans (public live-player layer switched off, [SIEGE_WEAPONS.md](../siege-minigame/SIEGE_WEAPONS.md) §8). This needs the web session tied to the viewer's permission nodes. The standalone Docker renderer cannot show live players, so the BlueMap Paper plugin must run on the game server alongside the offline tiles.

7.8 The web app already fetches a user's permission nodes (visible on its user management page). Design must check that this works for the map page; if not, it needs implementing.

7.9 Anonymous viewers see only the short bracketed minigame tag on a player in a minigame. The description naming the specific minigame (for example Siege) is shown to logged-in viewers only, so the public map reveals no team or match detail.

## 8. Permitted viewers: details and quick actions

8.1 Viewers with the right permissions get extra detail and quick actions in the info panel. For a gate structure they can expand additional details and open, close or toggle its gate doors, and repair it. Other entity types get their own actions later.

8.2 Permissions reuse the recently added area permission nodes, which divide staff areas of responsibility. Examples named: a content node with sub-nodes (item blueprints, kits and their items) and a world area node (changing or adding domain entity types).

8.3 Design task: look up these area nodes in the codebase and take them over for the map. Decide which node gates which detail or action. Do not invent new nodes where one exists.

8.4 Open question for the design session: reuse display configurations for the panel? A display configuration is an admin-made template that says which properties of an entity the web app shows and which actions are attached (edit, delete, detach, link and so on). Reusing gives one source of truth and automatic coverage of new entity types. The risk is that the view engine is tuned to full pages.

8.5 Developer's current lean: the view engine is probably too page-sized, so build a separate, concise map panel renderer that takes display configurations as input and renders a compact view. Map-specific live widgets can sit on top for special types such as the gate (door state, health, open, close, toggle and repair). The design session checks the web app's display configuration code and decides, with a decision matrix.

## 9. Roles of the map

9.1 **Player view:** an extra immersive dimension of Knights and Kings. Players view the map, find points of interest and lore, and see information that is useful in game. Game aspects may be added to the map later.

9.2 **Admin tool:** staff perform quick operations through the visual map, limited by the area permission nodes: quick edits and state changes, such as the open state of a gate door. Create and full update stay in the form wizard, not on the map.

9.3 **Siege view:** the siege tactical and targeting map is a third role, an extra immersive game feature on top of the siege minigame. It stays a separate team-only page, as in the siege weapons design (#613).

9.4 All three roles share one BlueMap foundation, the offline snapshot tiles and the marker API.

## 10. Player moderation from the map

10.1 For permitted staff, clicking a player on the map opens a context panel with the same moderation options as the web app's player moderation page: freeze, ban, kick and the rest of that page's actions.

10.2 Wanted: a teleport function in the player context panel. A "teleport to" dropdown lists destinations such as the hub, spawn, towns and possibly other players.

10.3 The teleport feature needs its own extra admin permission nodes, to be defined in a separate design pass. Here it is only documented as a desire, not designed.

10.4 Moderation actions reuse the existing moderation endpoints and permission nodes where they exist. The design session checks what the player moderation page already uses.
