# Overview map — Player Guide

**Status:** Current · **Last updated:** 2026-11-20 (live-tested 2026-11-19 on dev and the alpha: labels and dots, the start view over Cinix, player heads, sub-region outlines, screenshot placeholders; docs #767); 2026-11-19 (§ 3 item 7: Escape also works right after a click inside the map, #757, fix link F2); 2026-11-18 (first version, the overview map chain #732, docs PandiO/knk-workspace#766)
**Checked against:** knk-web-app `main` `31a6896d` (v0.4), knk-web-api `main` `75b84343` (v0.4), knk-plugin `main`
`2411d785` (v0.3). Live-tested 2026-11-19: the [smoke test](../overview-map-smoke-test.md) §§ 1–9 on dev and the
map page on the closed alpha
**Related:** [player handbook](player-handbook.md), [overview map admin guide](../admin/overview-map-admin-guide.md),
[design](../../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md)

The website has a 3D map of the Knights and Kings world. You can look around, find towns, districts and buildings,
see which players are online and where, and see where a siege is being fought. You don't need to log in to use it.

## 1. Opening the map

1. Go to **`/map`** on the website (for example `https://app.knightsandkings.net/map`).
   1. Not logged in: the start page says "Explore the world on the **map**." Click **map**.
   2. Logged in: click **Map** in the top bar.
2. While the closed alpha runs, the whole website sits behind the Cloudflare sign-in
   ([player handbook § Sign in through Cloudflare](player-handbook.md#2-sign-in-through-cloudflare-if-asked)). Once
   past it, the map needs no Knights and Kings account.
3. No "Map" entry, no link on the start page, or `/map` says "The map is not available.": the map is switched off on
   this server. Nothing is wrong with your account.
4. The map works on a phone too. Its panel then opens as a sheet over the lower part of the screen; the map stays
   usable above it.

> **Screenshot to come:** `player-map-start.png` (the `/map` page as a visitor who is not logged in: the start view over Cinix with town pins and names). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![the `/map` page as a visitor who is not logged in: the start view over Cinix with town pins and names](../images/overview-map/player-map-start.png) -->


## 2. Moving around

The map is BlueMap's 3D view of the world. It opens over the town of Cinix. Drag to look around, scroll (or pinch)
to zoom. The landscape is a
snapshot that staff render from time to time, so a building put up today may not show on the map yet. The pins,
names and players on top of it are current.

## 3. Towns, districts and buildings

1. **Pins and names.** Every town, district and building with a known place has a pin with its name.
   1. Town names show at every zoom.
   2. District names appear when you zoom in (about 1500 blocks away); building names closer still (about 600).
      The names fade by distance; the pins (dots) stay at every zoom, so a zoomed-out map shows many dots without
      names. Hiding or grouping the dots when zoomed out is an idea for later
      ([#825](https://github.com/PandiO/knk-workspace/issues/825)), not part of the map yet.
   3. A building's label has its name over its type, for example "Structure" or "Structure, Gate".
2. **Click a town** (its pin or its name). Its outline flashes three times and disappears, and a panel opens with the
   town's name, description and number of districts.
3. **Show region.** In the town's panel, turn on **Show region**: the town's outline and every district of the town
   stay on the map, each district with its name. They stay when you close the panel; click the town again and turn
   the switch off to hide them. Outlines only show this way (the flash or Show region); the map has no other
   permanent region shapes. Drawing a town's region as a flat shape with a single outline along the top is an idea
   for later ([#826](https://github.com/PandiO/knk-workspace/issues/826)).
4. **Click a district** for its name, description and town.
5. **Click a building** for its name, type, district, town, street address and description.
6. **Gates.** A gate's panel also lists its **Doors**: each door is Open, Closed, Opening, Closing or Jammed, says
   "Destroyed" when it is, and has a health bar ("Health current / max"). During a siege on that gate the panel says
   **Under siege**.
7. **Closing the panel:** the × at its top, or Escape, also right after a click inside the map. Clicking another pin
   replaces the panel. On a phone the panel is a sheet at the bottom of the screen.

> **Screenshot to come:** `player-labels-zoom.png` (zoomed in on a town: district and building names over their dots, next to a zoomed-out view with dots only). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![zoomed in on a town: district and building names over their dots, next to a zoomed-out view with dots only](../images/overview-map/player-labels-zoom.png) -->

> **Screenshot to come:** `player-town-show-region.png` (a town's panel with Show region on: the town outline and its districts with their names). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![a town's panel with Show region on: the town outline and its districts with their names](../images/overview-map/player-town-show-region.png) -->

> **Screenshot to come:** `player-gate-doors.png` (a gate's panel with its Doors: state, health bar and, if one is, a destroyed door). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![a gate's panel with its Doors: state, health bar and, if one is, a destroyed door](../images/overview-map/player-gate-doors.png) -->

> **Screenshot to come:** `player-phone-sheet.png` (the map on a phone with a building's panel open as a sheet over the lower part of the screen). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![the map on a phone with a building's panel open as a sheet over the lower part of the screen](../images/overview-map/player-phone-sheet.png) -->

## 4. Players on the map

Staff can switch this part on separately; without it the map shows places only.

1. **Online players** show as their own head (the face of their Minecraft skin) with their name above it, at their
   place in the world, and move along about every 2 seconds. A player in another world isn't on this map. The heads
   come from a public skin service (on the closed alpha: Minotar); if it can't find a skin, the player shows with a
   default head.
2. **Name labels** look like the player's name in the in-game chat, in the same colours: rank tag, title and name,
   for example `[OWNER]-{title}- Name` or `-{tier title}- Name`.
3. **Tags.** A player who is away from the keyboard has an **AFK** tag, and their head and name are dimmed. The tag
   goes away when they move again.
4. **Sieges.** Players in a running siege match are not drawn one by one. Instead one pin at the match's gate reads,
   for example, "[Siege] 12 players". It disappears when the match ends, and the players show again.
5. **Hidden staff.** Staff in staff mode or owner mode are not on the map for you, the same as in game.
6. **Click a player** for a **Player details** card: their coloured name label and tags. It never shows anything
   else about them, and their position is only what you see on the map.
7. A player who leaves the server disappears from the map within a few seconds.

> **Screenshot to come:** `player-live-players.png` (online players as heads with coloured name labels, one with the AFK tag, and an arena pin "[Siege] n players"). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![online players as heads with coloured name labels, one with the AFK tag, and an arena pin "[Siege] n players"](../images/overview-map/player-live-players.png) -->

> **Screenshot to come:** `player-card.png` (the Player details card after a click on a player). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![the Player details card after a click on a player](../images/overview-map/player-card.png) -->

## 5. What others see of you

1. While you're online and staff have the player layer switched on, everyone who opens the map sees your head and
   name label where you are, and an AFK tag when you're idle. There is no setting to hide yourself from the map; you
   are hidden while you play in a siege match (only the match's pin shows).
2. Your head is loaded by each viewer's browser from the skin service (§ 4 item 1), by your Minecraft UUID. That
   service sees the request; it gets nothing else from Knights and Kings.
3. Clicking you gives others only your name card (the same label as in chat, and your tags).
4. Staff see a little more, as in game: staff who may see staff mode see players in staff mode, owner mode or a
   match with a tag. Staff with moderation rights can freeze, kick or ban from the map, with the same rules, reasons
   and records as from the website's player pages (see [ranks and chat § 8](ranks-and-chat-player-guide.md)).

## 6. When something looks wrong

1. **No players on the map, only places:** the player layer is off on this server, or the game server is down.
2. **A building has no pin:** it has no spawn location and no region yet; staff can fix that.
3. **A district's extra part (an expansion region) still shows after staff removed it:** a removed part stays in
   the outline until the district's next full outline report; tell staff.
4. **A town's new name doesn't show:** the map picks up changes within about a minute and a half without reloading.
5. **The landscape is out of date:** the 3D world is re-rendered from time to time (§ 2).

## Changes

1. 2026-11-20: live-tested 2026-11-19 on dev and the alpha: § 2 start view over Cinix; § 3 names fade, dots stay
   (idea #825), outlines only from the flash and Show region (idea #826); § 4 heads from a skin service; § 5 item 2
   what the skin service sees; § 6 item 3 (sub-regions are now reported, #750); screenshot placeholders (#767)
2. 2026-11-19: § 3 item 7: Escape closes the panel also right after a click inside the map (fix link F2, #757)
3. 2026-11-18: first version (the overview map chain #732, links L1–L9; docs PandiO/knk-workspace#766)
