# In-game maps — battle map tables and siege-engine targeting

**Status:** Direction chosen by the developer (2026-11-03). **Not designed in detail, no code.** Numbers in §6 are estimates and have not been measured.
**Last updated:** 2026-11-03 (first version, from the developer conversation the same day)
**Issue:** [PandiO/knk-workspace#224](https://github.com/PandiO/knk-workspace/issues/224)
**Related:**
- #41 siege survival, #23 siege PvE
- #66 realtime channel
- #101 performance metrics, #77 load testing
- #32 VPS hosting
- other map uses: #78 road navigation, #65 logistics map, #124 trade/treasury, #53 transport routes
- #126 Conquest

**Authority:** the developer's conversation of 2026-11-03. Plugin facts (MapBrowser, WebGUI, WebDisplay) come from their public project pages, checked the same day. Resource figures are rough estimates, not benchmarks.

## 1. Goal

Players choose a target on a **map** for siege engines such as trebuchets and ballistas. The map is shown in game on a **battle map table**: item-frame maps in a siege command post, a castle throne room, and similar rooms.

The same tables are used for other views as well. Which area and which view a table shows depends on context:

- during a siege: the siege area
- otherwise: for example taxes, or a town's trade routes

There are **no permanent walls of preloaded maps**.

Out of scope here: the siege engines themselves (projectile, reload, damage to gates and objectives). They have no design or issue yet (#224 "Open points").

## 2. Decisions (developer, 2026-11-03)

| ID | Decision |
|---|---|
| M1 | **Vanilla clients first.** The plugin targets the vanilla experience. A modded-client path is a later option (§5.3), for example alongside a Lord of the Rings mod. The aim is to support both eventually. |
| M2 | **Dynmap renders the world** and is used for more features than this one. |
| M3 | **The targeting UI is a web page** built on Dynmap. It is shown in game through a server-side browser plugin (MapBrowser, §4). The developer already has a web-based targeting system. One codebase then serves both the in-game maps and the browser maps. |
| M4 | **Dynmap is chosen over vanilla `MapRenderer` maps** (§5.1), even with the extra RAM and CPU. Reasons: configurability, scaling to other map uses, and reuse of the web code. Costs are kept in check with the efficiency rules in §6.2. |
| M5 | **Battle maps are snapshots.** They don't need to show the current terrain or siege damage. A medieval hand-drawn map wouldn't either. Tiles are pre-rendered offline (§7). |
| M6 | **For the open beta, the browser runs on a separate VPS** (§6.3), not on the Paper host. |

## 3. How it works

1. A table is a grid of item frames holding maps. MapBrowser draws a browser page onto those maps. The page is Chromium, run server-side through JCEF.
2. When a player clicks the table, MapBrowser traces their line of sight to the frame and works out the map pixel. It then forwards that click to the page.
3. The page is the targeting page (Dynmap or a page built on its tiles). It turns the pixel into world X/Z and sends the target to knk-plugin.
4. The plugin aims the siege engine. Any feedback, such as a crosshair or a range ring, is drawn by the page.

**Player identity.** The browser runs on the server, so the page doesn't know who clicked. The plugin opens each page with a **per-session token** in the URL, linked to the player, the siege engine and the match. Each click carries that token.

The transport for clicks is still open: a direct plugin HTTP endpoint, or through knk-web-api and the realtime channel (#66).

**Context switch.** The plugin decides what a table shows: which page, centre, zoom and markers. It loads that page when the context changes, for example when a siege starts in that town.

Dynmap's web UI is HTML/JS. Its markers API (areas, lines, icons) covers overlays such as objectives, engine range or trade routes.

## 4. Plugin options checked (2026-11-03)

| Option | Clients | How | Notes |
|---|---|---|---|
| **MapBrowser** (Spigot/Paper; Modrinth, GitHub `Steve3184/MapBrowser`) | Vanilla | JCEF Chromium on the server, drawn onto item-frame maps; forwards clicks | **Chosen path.** Map resolution is low (128×128 per map) and refresh is limited. Fine for maps and dashboards, poor for video. |
| WebDisplay (GitHub `cyoung06/WebDisplay`) | Vanilla | Same idea | Older; fallback if MapBrowser doesn't fit. |
| **WebGUI** (GitHub `yayokorea/webgui-paper`) | Modded (Fabric/NeoForge + Paper companion) | Chromium in the **client** | Sharp and smooth, but players must install the mod. The Paper companion only acts for players who have it, so it can run alongside MapBrowser (M1). |

## 5. Alternatives

### 5.1 Vanilla maps without Dynmap or a browser (fallback)

Vanilla maps can be fully dynamic:

- With a custom `MapRenderer`, a frame can show any map, be re-centred, or have anything drawn onto it.
- With packets, different players can see different maps on the same frame.
- Clicks are detected the same way MapBrowser does it: a ray trace to the frame, then the pixel.

**Cost** (§6.4) is close to zero. One map is about 16 KB, terrain is cached, only changed areas are sent, and nothing runs in Chromium.

**Downside:** it is all custom work. You build the terrain rendering (you could reuse Dynmap's tile images), click handling and every UI element yourself. None of the web code is reused.

The developer rejected this for now (M4) because of that work and the per-scenario maintenance. It stays the fallback if the browser costs turn out too high.

### 5.2 Dynmap in an ordinary browser only

Not suitable for targeting at a table in game. It is still useful on the web app for other map views.

### 5.3 Modded clients (later)

WebGUI renders on the client, so the server pays no Chromium cost for those players. It is the path for modded play (M1).

## 6. Resource cost (estimates, unmeasured)

### 6.1 How it scales

RAM scales with the number of **open pages**, not with the number of players. Chromium runs:

- one renderer process per page, roughly 100–200 MB for a Dynmap page (more with heavy marker layers)
- plus a fixed base of about 300 MB for the browser engine

Many players watching one table cost about as much as one player. Per viewer, the extra cost is **CPU and bandwidth**: every frame is rendered, converted to the map palette and sent to each viewer. Bigger tables and faster refresh make this worse.

**Peak example from the conversation:** about 100 players, 10 sieges at once, one table per team = **20 open pages**. That comes to about **2.5–4.5 GB of extra RAM**, plus noticeable CPU for converting and sending frames.

### 6.2 Efficiency rules (to apply)

- Start a page only when a player is near the table, and close it when the room is empty.
- Use a low refresh rate. Targeting doesn't need a high frame rate.
- Share one page between all viewers of a table.
- Keep tables small (a few maps wide).
- Do frame conversion off the Paper main thread.

### 6.3 Browser host on a separate VPS (M6)

All of Chromium's RAM and rendering move off the game server. Paper only receives frames and passes them on as map packets, which is cheap off the main thread.

Conditions:
- Put the VPS in the same data centre, or at least the same region, as the Paper server, so clicks and frames have low latency. The alpha is moving to an OVH VPS in the EU (#32).
- It costs a second machine.
- Dynmap's own tile rendering still runs where Dynmap runs (see §7).

Measure it with the performance metrics (#101) and the load test plan (#77).

### 6.4 Vanilla comparison

- Memory: one map is 16 KB, a 3×3 table under 150 KB, 20 tables a few MB.
- CPU and bandwidth: terrain is rendered once and cached, then only small changed areas are redrawn and sent.

## 7. Tile pipeline (snapshot, M5)

- **Full render offline:** on a copy of the world on another machine, or while the server is down. Then copy the tiles to production. Dynmap's config, world names and map definitions must be **identical** on both sides, or the tiles won't line up.
- **Live updates:** not needed (M5). Turn off or limit Dynmap's update triggers on production, and re-render offline from time to time instead. Siege block damage doesn't exist yet. If it is added, the snapshot maps deliberately won't show it.
- **Storage:**
  - Flat files are at least as fast as MySQL for serving tiles.
  - MySQL's advantage is management: one thing to back up or share instead of hundreds of thousands of small files, and several servers can read the same tiles.
  - For a static snapshot, the cheapest option is **exporting the tiles as static files and serving them with Nginx**. The targeting page loads them from there.
  - Not decided yet.

## 8. Next steps

Tracked in #224. To be split into sub-issues when picked up:

1. **Spike:** MapBrowser and Dynmap on the dev server.
   - The table shows the page.
   - Clicks land on the right map pixel.
   - Measure RAM and CPU per page.
2. **Targeting page:** convert a click to X/Z, attach the session token, send it to the plugin.
3. **Plugin:** a battle-map table model (entity or config), the context switch, and the start/stop rules from §6.2.
4. **Tile pipeline:** offline render, then copy to production; choose a storage option (§7).
5. **Hosting:** Chromium host on a VPS (§6.3).
6. **Separately:** design the siege engines themselves (new issue).
