# Lootbox spawn areas drawn in the web form — smoke test checklist

**Status:** Written 2026-11-05 for #34; API and plugin parts merged into `next` 2026-11-13 from `claude/plugin-chains-into-next` (knk-plugin `next` `745fcf6`, knk-web-api `next` `c20899c`); not run
**Last updated:** 2026-11-13 (setup: builds from `claude/plugin-chains-into-next`); 2026-11-05
**Issue:** [PandiO/knk-workspace#34](https://github.com/PandiO/knk-workspace/issues/34)
**Related:** [managed-worldguard-regions.md](../architecture/managed-worldguard-regions.md) §7 "Lootbox spawn areas", lootbox
[DESIGN](../specs/lootboxes/DESIGN.md) §3.4

A region drawn through the LootboxSpawnArea form's region task is renamed from `tempregion_worldtask_<n>` to
`lootbox_area_<id>` when the form is saved, stretched to the world's full build height, and kept by the 14-day temp-region
cleanup. `<id>` is the area's id (shown in the web app's URL or `/knk lootbox area info <name>`). Use an op or the console for
`/rg` and `/knk` commands. Write down any step that fails, with its server and API log lines.

## 0. Setup

1. Back up `plugins/WorldGuard/worlds/*/regions.yml` and the dev database.
2. Deploy the API and the plugin from `claude/plugin-chains-into-next` (or `next` once it is merged; both; no setting for
   #34). Apply the API's pending migrations first (`dotnet ef database update`: #269's `AddTempRegionReleases` comes
   with it; #184's `AddPrivacyErasureEvents` is already on `master`).
3. Import the form seed `LootboxSpawnArea - Default (seed v2)` (`Data/FormConfigurationSeeds/LootboxSpawnArea.json`) and make
   it the default for LootboxSpawnArea (keep or delete v1 by hand).

## 1. New area on a drawn region

1. Web app: new LootboxSpawnArea with the v2 form. "Area and region" says a drawn region becomes `lootbox_area_<id>`.
2. Region field: Send to Minecraft; in game make a WorldEdit selection a few blocks high (e.g. Y 64–68) and complete the task.
   `/rg list` shows `tempregion_worldtask_<n>`.
3. Fill World, finish the form and save.
4. Expected: the area's region in the web app is `lootbox_area_<id>`; `/rg info lootbox_area_<id>` exists, the temp region is
   gone, and its bounds reach the world's min and max build height (e.g. Y -64 to 319) with the drawn outline. The server log
   shows `Successfully renamed region from tempregion_worldtask_<n> to lootbox_area_<id> in <world>: renamed (Y … to …)`.
5. Enable the area with an allowed type; `/knk lootbox area info <name>` lists the region and its bounds; a box spawns there
   (or `/knk lootbox spawn` in it).

## 2. Re-run the region step

1. Edit the area, "Replace via Minecraft" on the Region field, draw a visibly different shape, save.
2. Expected: still `lootbox_area_<id>` with the new shape at full height; no `tempregion_worldtask_*` and no second region left
   behind; the log says `replaced the previous lootbox_area_<id> in place`. A flag set on it before (`/rg flag lootbox_area_<id>
   greeting hi`) is still there.
3. Edit and save only a limit (Max active): the region is not touched (no rename line in the log).

## 3. Selected regions are left alone

1. New area, Region: `select <a town's region>` (e.g. `domain_1`). Save: the area keeps `domain_1`; nothing is renamed.
2. In game `/knk lootbox area create market` → `lootbox_market` as before. Edit it in the web app and save: still
   `lootbox_market`.
3. In game `/knk lootbox area create area_7`: refused ("reserved"). In the web app, naming an area `area_7` is refused too;
   `area_north` is fine.

## 4. Server down at save, then recovery

1. Draw a region for a new area (task completed), stop the Minecraft server, save the form. The save succeeds; the area keeps
   `tempregion_worldtask_<n>` (API log: failed to finalize).
2. Start the server. `/knk regions temp`: that region is listed under "Used by a domain or lootbox area", not as unused.
3. `POST /api/Regions/finalize-temp-names` (plugin key or `knk.admin.regions`): the area is renamed to `lootbox_area_<id>`
   (counted in `renamed`). Saving the area again would do the same.

## 5. Cleanup keeps an area's temp region

Only if step 4 can be repeated without step 4.3: with the area still on its temp name, `/knk regions temp purge 1` (after an
hour) does **not** delete it ("used by a domain or lootbox area"). A temp region no domain and no area uses is still purged.

## 6. Delete

1. `/knk lootbox area delete <name>` twice on an area from §1: the area and `lootbox_area_<id>` are removed.
2. A delete from the web app keeps `lootbox_area_<id>` in WorldGuard (as for `lootbox_<name>`); `/rg remove` it.
