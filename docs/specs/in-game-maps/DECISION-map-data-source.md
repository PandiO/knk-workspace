# Decision matrix: overview map data source

**Status:** Decided 2026-11-18 (developer), option 1; log id O15 in [OVERVIEW_MAP_DESIGN.md](OVERVIEW_MAP_DESIGN.md).
**Last updated:** 2026-11-18
**Question:** Where do the overview map's markers (towns, districts, structures) and live players come from? It has to
be settled now because it decides whether a Bukkit plugin joins the game server and which repos the phases touch.

## 1. Options

1. **Our API, no BlueMap plugin.** knk-plugin reports player positions, AFK and mode over the SignalR game hub
   (`/api/hubs/game`) and domain region outlines when they change. knk-web-api keeps them, filters per viewer and
   serves the map endpoints. A bridge script inside BlueMap's viewer draws everything. BlueMap is offline tiles plus
   the viewer only.
2. **BlueMap Paper plugin plus an API filter.** The BlueMap plugin runs on the game server for live players and
   markers. knk-web-api proxies its `players.json` and drops hidden players. Region markers come from a script.
3. **Static export plus API players.** Region shapes are exported by the offline render pipeline
   (`scripts/bluemap/wg2bluemap.py`) with each render. Live players come from our API as in option 1.

## 2. Considerations and weights

1. **Per-viewer visibility** (25): hidden staff, minigame players (O13) and the name format (O07) are filtered on the
   server for each viewer.
2. **Platform independence** (20): how much K&K would rebuild on another engine.
3. **Freshness of markers** (15): a new or edited town shows without a re-render.
4. **Effort to build and maintain** (20): code to write, moving parts on the game server.
5. **Fit with what exists** (20): the SignalR game hub, `PresenceRegistry`, the managed-region reconciler, the
   offline BlueMap pipeline.

## 3. Matrix

(Score 1–5; weighted total = sum of score × weight / 5, out of 100.)

| Consideration | Weight | 1. Our API | 2. BlueMap plugin + filter | 3. Static export + API |
|---|---|---|---|---|
| Per-viewer visibility | 25 | 5 | 3 | 5 |
| Platform independence | 20 | 5 | 2 | 4 |
| Freshness of markers | 15 | 5 | 4 | 2 |
| Effort to build and maintain | 20 | 3 | 3 | 4 |
| Fit with what exists | 20 | 4 | 2 | 4 |
| **Weighted total** | 100 | **88** | **56** | **79** |

## 4. Notes per option

1. **Our API.** Positions ride the existing game hub next to `ReportRoster`; the API already holds an in-memory
   `PresenceRegistry`. Region outlines come from WorldGuard through the plugin's existing region wrapper and are cached
   by region id, so they stay current after a region step is re-run. Most code, but all of it in our repos and
   engine-neutral at the API and web app side.
2. **BlueMap plugin.** BlueMap's player layer is the same for every viewer, so the filter has to rewrite its output;
   AFK, minigame and group colours still need our data. Adds a Bukkit plugin and its upgrades to the game server.
3. **Static export.** Cheapest for regions, but a town created between renders has no outline, and the export has to
   run where `regions.yml` is.

## 5. Recommendation and outcome

Option 1, chosen by the developer on 2026-11-18 (O15).
