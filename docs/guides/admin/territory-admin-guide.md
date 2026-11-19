# Territory — Admin Guide

**Status:** Current · **Last updated:** 2026-11-19 (first version, territory V1 #326/#689/#690, docs PandiO/knk-workspace#806)
**Checked against:** knk-web-api `next` `0d6e369a`, knk-plugin `next` `55804b11`, knk-web-app `next` `89751315` (not
released; off in game until both switches are on; the manual steps of the
[smoke test § 1](../production-storage-transport-smoke-test.md#1-territory-v1-326-api-689-plugin-690-web-app-tier3)
have not been run live yet)
**Related:** [territory DESIGN](../../specs/territory/DESIGN.md) (the rules), [territory architecture](../../architecture/territory.md)
(API contract, chunk cache, payloads, tests), [territory player guide](../users/territory-player-guide.md) (what players
see), [plugin configuration § 4.31](plugin-configuration.md#431-production), [game settings](../game-settings.md),
[staff web app guide](staff-web-app-guide.md) (the dashboard and forms in general)

Territory says which town or kingdom holds the land around its regions. Every district reaches out a number of blocks
from its WorldGuard region, its **range**; crown land reaches out its own range. The game server works out, chunk by
chunk, who holds each spot: one town, a kingdom (crown land beats towns), **contested** when two towns reach it, or
**wilderness** when nobody does. Staff set up the holders and ranges in the web app and settle contested zones. Later
production phases use territory to check where rural structures may stand.

## 1. What you need

1. **Nodes.** `knk.admin.world` for every territory change and read in the web app; creating and editing kingdoms,
   provinces and crown land also needs `knk.admin.content`; deleting needs `knk.admin.delete`. In game,
   `knk.admin.world.territory` for `/knk territory` (included in `knk.admin.world.*` and `knk.admin.*`). Content staff
   without `knk.admin.world` do not see the territory types.
2. **knk-web-api** with migration `AddTerritory` applied
   ([production installation § 5.3](../production-installation.md#53-apply-the-migrations)) and the form seeds
   `Kingdom`, `Province`, `CrownLand`, `TerritoryConflict` with their display seeds imported ("make default", `Kingdom`
   first).
3. **knk-web-app** from `next` (the territory dashboards, the town, conflict and structure panels, the settings card).
4. **knk-plugin** from `next` with the `production` block in `plugins/KnightsAndKings/config.yml` (§ 4). Realtime on
   (`realtime.enabled: true`) so changes reach the game server within seconds; without it they arrive with the next
   periodic check (10 minutes).
5. **WorldGuard** on the game server, and the districts' regions in place.

## 2. Setting up the holders

Do this in any order before you switch territory on; nothing changes in game while the switches are off.

### 2.1 Kingdoms and provinces

1. **Kingdom:** Dashboard, type **Kingdom**, **Create**: Name (required, unique, at most 100 characters) and
   Description. The Kingdom table shows each kingdom's towns and crown land counts.
2. **Province** (optional; a group of towns inside one kingdom): Dashboard, type **Province**, **Create**: Name
   (unique within its kingdom) and Kingdom (picked from the list). A province holds no land of its own.
3. A kingdom that still has towns, provinces or crown land can't be deleted ("This kingdom can't be deleted: it still
   has …"), and a province with towns can't be deleted or moved to another kingdom. Move or detach the towns first.

### 2.2 Towns: power, kingdom, capital districts

Open the town's page (Dashboard, type **Town**, **View**). Below the details is the **Territory** panel.

1. It shows Power, Kingdom, Province, the **Range** ("200 blocks; capital districts 300 blocks") and each district
   with its range.
2. **Edit territory**: set **Power** (0 to 1,000,000), **Kingdom** and **Province** (only the chosen kingdom's
   provinces are offered; changing the kingdom empties it), then **Save territory**. Only these fields are saved; the
   town's warp, navigation and other settings stay as they are.
3. Under **Districts**, **Make <district> a capital** marks a capital district (its range is multiplied, § 3);
   **Unmark <district> as capital** undoes it. A town may have more than one.
4. The Town and District forms do not have these fields yet; use the panel.

A province must be in the town's kingdom; the API refuses anything else ("Province '…' belongs to another kingdom").
Power is a number staff set by hand in V1: nothing in game raises or lowers it yet.

### 2.3 Crown land

Crown land is land a kingdom holds directly, such as a royal forest. It outranks towns: where a town's territory and
crown land meet, the crown land wins.

1. Dashboard, type **CrownLand**, **Create**: Name, Description, Kingdom (picker) and **Range (blocks)** (0 to
   10,000, measured from the region's edge).
2. Next step **Region and access**: press **Send to Minecraft**, claim the task in game, select the area with
   WorldEdit and confirm, as for a district. Keep Allow entry and Allow exit ticked unless the land should be closed.
3. Submit. The CrownLand table lists it with its kingdom, range and world; in game the region is named `domain_<id>`
   and gets the managed-region kind `CROWN_LAND` (top level, priority 10, no flags of its own) once
   `production.enabled` is on and the region repair runs.

Two crown lands of the same kingdom never conflict; crown lands of two kingdoms that meet are contested like two towns.

## 3. Range settings

Web app: **Game settings** (`/admin/game-settings`), card **Production and territory**.

| Setting | Default | Allowed | What it does |
|---|---|---|---|
| Production enabled | off | on/off | The API's production switch (`production.enabled`). Only the game server's conflict report waits for it; set-up works with it off |
| Base range (blocks) | 100 | 0–10,000 | The range of every district of a town with power 0 |
| Blocks per power point | 2 | 0–1,000 | Added to the range per point of town power |
| Capital multiplier | 1.5 | 1–10 | A capital district's range is the normal range times this |

Range of a district = base range + power × blocks per power point; a capital's is that × the capital multiplier. The
card shows a worked example: "A town of power 50: (100 + 50 × 2) = 200 blocks; its capital (100 + 50 × 2) × 1.5 = 300
blocks." A value outside the allowed range turns red and Save stays off. The range is measured from the nearest edge of
the district's region or any of its sub-regions, not from its centre.

## 4. Switching it on in game

Territory runs in game only when **both** switches are on: the plugin's `production.enabled` and the API's game
setting **Production enabled**.

1. Merge the `production` block into the plugin's `config.yml` (the plugin never adds keys to an existing file; keys
   and defaults in [plugin configuration § 4.31](plugin-configuration.md#431-production)), set
   `production.enabled: true`, keep `territory.map-outlines: false`
   ([#802](https://github.com/PandiO/knk-workspace/issues/802)), and restart.
2. Tick **Production enabled** in Game settings and save.
3. The server log shows "[KnK Territory] On (production.enabled): first build in 5 s, checks every 10 min, report on,
   map outlines off"; about 5 seconds later the first build. Then `/knk territory status` shows the chunks, the API's flag (`true`) and "Last report".
4. After that, the game server rebuilds by itself when territory data changes (realtime `TerritoryChanged`), every
   `territory.refresh-minutes` (10), and when you type `/knk territory rebuild`.

Turning it off: untick Production enabled (the server stops reporting conflicts, but keeps its cache and the entry
lines), or set `production.enabled: false` in the plugin and restart (nothing of territory runs).

## 5. Checking territory in game: `/knk territory`

| Command | What it shows |
|---|---|
| `/knk territory here` | Who holds the block column you stand on ("Territory at 210 -40 (chunk 13 -3, split): Phoenix"; also "crown land of Aurelia", "contested: Phoenix / Rivertown" or "wilderness"), whether the chunk is **split** (a border runs through it), the cache version. On awarded land also "Awarded by an admin; also reached by 2 holders." |
| `/knk territory status` | Chunks, split chunks and worlds in the cache, its version and build time, the number of sources and awards, the API's Production:Enabled, the last report, and up to five warnings (the rest in the server log) |
| `/knk territory rebuild` | Reads the territory data and the regions now, rebuilds, reports again, and answers with a summary |

With `production.enabled: false` every form answers "Territory is off on this server (production.enabled: false)."

## 6. Contested zones (conflicts)

When two towns (or two kingdoms' crown lands) reach the same land, the game server reports it after its next rebuild
and the API opens a **conflict** for that pair and world. Structures standing in it are flagged. Only staff close
conflicts; nothing is decided automatically.

1. **Find them:** Dashboard, type **TerritoryConflict**. Each row is "Phoenix vs Rivertown" with Status, Still
   overlapping, the chunk count and the number of flagged structures.
2. **Look at one:** **View** opens the **Contested zone** panel: the two holders (links), State, World, Area (chunks
   and block ranges), Overlap, when it was detected and last reported, and the flagged structures.
3. **Resolve it** (with an optional note, then confirm):
   1. **Award to <holder>**: the contested chunks go to that holder. The game server gets the award with its next
      rebuild (seconds with realtime on), and those chunks stop being contested.
   2. **Mark the lines redrawn**: closes the conflict without an award. Use it after you removed the overlap yourself,
      by lowering a town's power, moving a capital, or redrawing a region; the next rebuild then finds no overlap.
4. **Reopen** (on a resolved conflict, confirm): it is open again and an award is withdrawn, so the area is contested
   again. Refused when another open conflict exists for the same two holders in that world; resolve or delete that one
   first.
5. **Still overlapping: No** ("No longer reported by the game server (resolve it to close it)"): the overlap is gone,
   for example after a power change. The conflict stays open until you resolve it; **Mark the lines redrawn** is the
   usual answer.
6. **Delete** (needs `knk.admin.delete`): for a stale conflict. If the overlap still exists, the next report opens a new
   one.

An award covers the chunks of the conflict at the time it was resolved. If the towns grow later and overlap more, the
new chunks are contested again and appear in a new conflict.

## 7. Structures: flag and loyalty

Open a structure's page (Dashboard, type **Structure**, **View**); the **Territory and loyalty** panel shows:

1. **Territory:** "Inside its town's territory", "In a contested zone (since …)" with a link to the **Conflict**, or
   "Outside its town's territory" (wilderness, another town's land or crown land, also its own kingdom's). The flag is set by the game
   server's report and only warns: the structure keeps its town and nothing is blocked.
2. **Own town** (through its district) and **Loyal to**: pick another town and **Save loyalty**, or "Its own town".
   Loyalty is stored only in V1; it has no effect in game yet.
3. **Clear flag** removes the flag by hand. The next report sets it again while it still applies.

Only structures inside a district are checked; rural structures come with production phase P2
([#91](https://github.com/PandiO/knk-workspace/issues/91)). A structure's position is the centre of its region.

## 8. Safe test procedure

1. On a test server, with the switches off, create a kingdom, give two towns power and that kingdom, and mark one
   capital district (§ 2). Check the ranges on the Territory panel.
2. Turn both switches on (§ 4) and wait for the first build. Walk out of a district: the action bar says
   "Leaving <town>: wilderness" about range blocks past the region's edge; `/knk territory here` agrees.
3. Raise one town's power until its territory meets the other's; within seconds (realtime) the dashboard lists a
   conflict. Award it, check `/knk territory here` in the zone, then reopen and **Mark the lines redrawn** after
   lowering the power again.
4. Turn Production enabled off afterwards if the server should not report.

The full checks are the [smoke test § 1](../production-storage-transport-smoke-test.md#1-territory-v1-326-api-689-plugin-690-web-app-tier3).

## 9. Effects on existing data

1. The migration only adds: every town gets power 0 and no kingdom or province, no district is a capital, every
   structure is unflagged and loyal to its own town. Production starts off.
2. With power 0 and the default settings, every district reaches 100 blocks. Towns closer than about 200 blocks to
   each other therefore overlap as soon as territory is on: expect conflicts on the first report and settle them, or
   set the ranges first.
3. Crown land regions get the kind `CROWN_LAND` (priority 10, top level) from the region repair once
   `production.enabled` is on. Existing district and town regions are not touched.

## 10. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| `/knk territory` says "Territory is off on this server" | Plugin `production.enabled: false` | Set it to `true` and restart (§ 4) |
| `status` shows "API Production:Enabled: false" and no conflicts appear | The API's switch is off: the server builds territory but sends no report | Tick Production enabled in Game settings |
| A district or crown land is missing from the territory; `status` lists "region not found" | Its region doesn't exist in that world, or the record has no region | Redraw the region (Send to Minecraft) or fix the world name |
| `status` warns about the chunk budget | A source would pass `max-chunks-per-world` (500,000) | Lower the ranges, or raise the limit in `config.yml` |
| A change in the web app does not show in game | No realtime connection | Check `realtime.enabled`; wait for the periodic check or type `/knk territory rebuild` |
| A conflict stays open with Still overlapping No | Only staff close conflicts | Mark the lines redrawn (§ 6 item 5) |
| "Another open conflict exists for the same holders in this world" on Reopen | A newer conflict for the pair is open | Resolve or delete the newer one first |
| "This kingdom can't be deleted …" / "This province can't be deleted …" | It still has members | Move or detach its towns, provinces and crown land |
| The Territory panel shows a refusal instead of values | No `knk.admin.world` | Grant it (§ 1) |
| Edit on a conflict's page opens a form that can't be saved | Conflicts have no edit; they come from the game server | Use the Contested zone panel ([#807](https://github.com/PandiO/knk-workspace/issues/807)) |
