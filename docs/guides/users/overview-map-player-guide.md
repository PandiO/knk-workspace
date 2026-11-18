# Overview map — Player Guide

**Status:** Current · **Last updated:** 2026-11-18 (first version, the overview map chain #732, docs PandiO/knk-workspace#766)
**Checked against:** knk-web-app `next` `eff6ed9`, knk-web-api `next` `6094276`, knk-plugin `next` `3e04ba8f` (not
released; the map is off until staff turn it on, and no step has been run on a live server yet)
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

## 2. Moving around

The map is BlueMap's 3D view of the world. Drag to look around, scroll (or pinch) to zoom. The landscape is a
snapshot that staff render from time to time, so a building put up today may not show on the map yet. The pins,
names and players on top of it are current.

## 3. Towns, districts and buildings

1. **Pins and names.** Every town, district and building with a known place has a pin with its name.
   1. Town names show at every zoom.
   2. District names appear when you zoom in (about 1500 blocks away); building names closer still (about 600).
      Their pins stay when the names fade out.
   3. A building's label has its name over its type, for example "Structure" or "Structure, Gate".
2. **Click a town** (its pin or its name). Its outline flashes three times and disappears, and a panel opens with the
   town's name, description and number of districts.
3. **Show region.** In the town's panel, turn on **Show region**: the town's outline and every district of the town
   stay on the map, each district with its name. They stay when you close the panel; click the town again and turn
   the switch off to hide them.
4. **Click a district** for its name, description and town.
5. **Click a building** for its name, type, district, town, street address and description.
6. **Gates.** A gate's panel also lists its **Doors**: each door is Open, Closed, Opening, Closing or Jammed, says
   "Destroyed" when it is, and has a health bar ("Health current / max"). During a siege on that gate the panel says
   **Under siege**.
7. **Closing the panel:** the × at its top. Escape also closes it, but only after you click somewhere on the page
   outside the map: right after a click inside the map, Escape doesn't reach the page (known issue
   [#757](https://github.com/PandiO/knk-workspace/issues/757)). Clicking another pin replaces the panel.

## 4. Players on the map

Staff can switch this part on separately; without it the map shows places only.

1. **Online players** show as a head with their name above it, at their place in the world, and move along about
   every 2 seconds. A player in another world isn't on this map.
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

## 5. What others see of you

1. While you're online and staff have the player layer switched on, everyone who opens the map sees your head and
   name label where you are, and an AFK tag when you're idle. There is no setting to hide yourself from the map; you
   are hidden while you play in a siege match (only the match's pin shows).
2. Clicking you gives others only your name card (the same label as in chat, and your tags).
3. Staff see a little more, as in game: staff who may see staff mode see players in staff mode, owner mode or a
   match with a tag. Staff with moderation rights can freeze, kick or ban from the map, with the same rules, reasons
   and records as from the website's player pages (see [ranks and chat § 8](ranks-and-chat-player-guide.md)).

## 6. When something looks wrong

1. **No players on the map, only places:** the player layer is off on this server, or the game server is down.
2. **A building has no pin:** it has no spawn location and no region yet; staff can fix that.
3. **A district's extra part (an expansion region) is missing from its outline:** a known gap for areas drawn before
   the map was switched on ([#750](https://github.com/PandiO/knk-workspace/issues/750)); it shows once staff redraw
   that part.
4. **A town's new name doesn't show:** the map picks up changes within about a minute and a half without reloading.
5. **The landscape is out of date:** the 3D world is re-rendered from time to time (§ 2).

## Changes

1. 2026-11-18: first version (the overview map chain #732, links L1–L9; docs PandiO/knk-workspace#766)
