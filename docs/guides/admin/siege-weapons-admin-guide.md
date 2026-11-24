# Siege Weapons — Admin Guide

**Status:** Current · **Last updated:** 2026-11-22 (first version: weapon spots as WorldGuard regions, #988, docs PandiO/knk-workspace#999)
**Checked against:** knk-web-api `next` `c647daf7`, knk-plugin `next` `822eb39b`, knk-web-app `next` `1d7c23bf` (not
released; phases 1 and 2 of siege weapons only, so weapons can't be bought, placed or fired yet; none of the manual
steps of the [siege weapons smoke test](../siege-weapons-smoke-test.md) have been run live yet)
**Related:** [siege weapons spec](../../specs/siege-minigame/SIEGE_WEAPONS.md) (the rules and decisions, W76 for spots
as regions), [authoring a siege scenario](../authoring-a-siege-scenario.md),
[siege shop admin guide § 4](siege-shop-admin-guide.md#4-siege-weapon-unlocks) (weapon unlocks),
[plugin configuration § 4.13](plugin-configuration.md#413-siege),
[managed WorldGuard regions § 7 "Siege weapon spots"](../../architecture/managed-worldguard-regions.md#siege-weapon-spots-pandioknk-workspace988-knk-web-api-next-c647daf7-knk-plugin-next-822eb39b-not-live-tested)
(developer side)

Siege weapons are built in phases. What is in `next` now:

1. **Phase 1 (#782):** weapon templates, ammo types and weapon unlocks as data in the web app, edited from the
   dashboard. The steps are in the [smoke test § 1](../siege-weapons-smoke-test.md#1-phase-1-entities-api-form-seeds-and-unlocks-782-tier3);
   unlock prices and titles are in the [siege shop admin guide § 4](siege-shop-admin-guide.md#4-siege-weapon-unlocks).
2. **Phase 2 (#783, #799, #988):** **weapon spots**, the places in a scenario where a team may put a weapon. Since #988
   a spot **is a WorldGuard region**: you draw it in the spot form with the normal region world task. This guide covers
   spots.

Players don't see spots yet: buying and placing weapons is phase 3 ([#784](https://github.com/PandiO/knk-workspace/issues/784)).

## 1. What you need

1. **knk-web-api** from `next` with the migrations `20261119100022_AddSiegeWeapons` (#782) and
   `20261122171115_DropSiegeWeaponSpotBounds` (#988) applied. The second drops the six bounds columns of
   `siege_weapon_spots`; only `next` test databases ever had them.
2. **API settings** (optional, the defaults are in `appsettings.json`): `RegionQueries:Enabled` (default `true`) and
   `RegionQueries:TimeoutSeconds` (default 5, 1..30). In an `api.env` file: `RegionQueries__Enabled`,
   `RegionQueries__TimeoutSeconds` ([production installation § 4.3](../production-installation.md#43-api-configuration-file--etcknkapienv)).
   These let the API ask the game server about a region over the game hub; nothing in the world changes.
3. **knk-plugin** from `next`, connected to the API's realtime hub (`realtime.enabled: true`; the startup log says it
   connected). For the site check also `siege.weapons.enabled: true` under `siege:` in `config.yml`, then a restart.
   With it on the log says "Siege weapons are on (siege.weapons.enabled): the weapon spot site check
   (SpotSiteCheckQuery) is answered." Leave it `false` on live servers until the smoke test has been run.
4. **The form seeds**, imported in this order with "make default": `SiegeAmmoType`, `SiegeWeaponTemplateAmmoType.join`,
   `SiegeWeaponTemplate`, `SiegeWeaponSpot`, `UserSiegeWeaponUnlock`. A database that imported `SiegeWeaponSpot` before
   #988 has the old form (six bounds fields, the spot task): delete "SiegeWeaponSpot - Default (seed v1)" and import it
   again, or make the form-designer changes in the [changelog](../../CHANGELOG.md) entry of #988.
5. **Permissions:** in the web app `knk.siege.admin.manage` and `knk.admin.content` to create and edit spots,
   `knk.admin.delete` as well to delete one. In game, to draw a region: the world task (`/knk task <code>`) and
   WorldEdit.
6. **A scenario** with its teams, and its town (or hub location) in the world where you draw the spots. The API looks
   for the region in the scenario's world: the town's world, else the hub location's.

## 2. Weapon spots

### 2.1 Creating a spot

1. In the web app open the scenario, go to its **Siege weapons** step and use **Create New** on Weapon spots.
2. **General:** pick the **Team** (only this scenario's teams are listed; attackers and defenders can both have spots),
   give a **Name** (shown in the spot picker later, e.g. "North wall tower") and optionally an **Order**.
3. **Place and size:**
   1. **Region** (required): click **Send to Minecraft**. In game, claim the code with `/knk task <code>`; the game says
      "[WorldTask] Define a WorldGuard region." Select a box with the WorldEdit wand (`//sel cuboid`) exactly as big as
      the weapon may be, **its bottom on the layer the weapon stands on**, and type `save`. The game answers "Region
      created: tempregion_worldtask_<id>" and "✓ Task completed!", and within a few seconds the form's Region shows
      that name. To use a region that already exists, type `select <region>` instead (or type its id in the field).
   2. **Facing:** the direction the weapon points (the way it shoots). The size is measured across and along it, so a
      change of facing can change the class.
   3. **Size class:** read-only. The form shows it under Region; the API works it out again on every save.
4. Click **Submit**. A region drawn through the task is renamed to **`siege_spot_<id>`** in the scenario's world;
   reopening the spot shows the new name, and `/rg info siege_spot_<id>` in game shows the box. A region you picked
   with `select` keeps its name.

### 2.2 Size classes

The class is the largest one the region fits for its facing, measured as width across the facing × length along it ×
height, in blocks:

| Class | Width | Length | Height |
|---|---|---|---|
| Small | 7 | 9 | 5 |
| Medium | 7 | 9 | 8 |
| Large | 9 | 15 | 16 |

For North or South the width is the region's size along x (east-west) and the length along z; for East or West it is
the other way round. So a box 7 along x, 5 high and 9 along z is Small facing North or South, and too small facing
East or West. A polygon counts as its bounding box, and the form adds "The region is a polygon; its bounding box
counts, so draw a box to be sure the weapon fits." Draw a cuboid.

### 2.3 What the two checks on Region say

Both checks ask the game server and run when you leave the Region field or click **Re-run validation**.

1. **Size check** (blocks Submit):
   1. "Size class Small: the region is 7 wide x 9 long x 5 high facing North." The region fits.
   2. "The region is too small for a weapon facing East: 9 wide x 7 long x 5 high, the small class needs at least 7
      wide x 9 long x 5 high." Draw a bigger box or change the facing. The save is refused with the same reason.
   3. "Region '…' doesn't exist on the game server." Check the name and the world (the scenario's town world). The
      save is refused.
2. **Site check** (a warning, never blocks): a weapon is pasted into the spot exactly, so it warns when the floor under
   the region isn't solid ("The floor isn't solid: n of 63 blocks under the spot are air or not solid, so a weapon
   would hang in the air.") or the space isn't clear ("The volume isn't clear: n blocks inside the spot would be
   replaced by the weapon (they come back when it is removed)."). With a clean site it says "The floor is solid and the
   space is clear." Only a game server with `siege.weapons.enabled` on answers it.
3. **"Validation could not be completed"** (an amber box) means the check couldn't run, not that it failed. The reason
   follows, for example:
   1. "No game server is connected, so … wasn't checked." Start the game server or wait until it has connected.
   2. "No answer from the game server within 5 s, so … wasn't checked." The server is busy or the site check is off
      (`siege.weapons.enabled: false`; the site check adds "The game server answers only with siege.weapons.enabled
      on.").
   3. "Region queries to the game server are switched off (RegionQueries:Enabled), so … wasn't checked."
   You can still Submit. The spot keeps the size class it had (a new spot: Small, the form's default), and phase 3 works the
   class out again from the region before a weapon is placed. Save the spot again once the game server answers to get
   the right class on record.

### 2.4 Editing, re-drawing and deleting

1. **Change the facing:** open the spot, change Facing, Submit. The class is worked out again.
2. **Draw again:** send the Region task again and draw a new box. On Submit the new region becomes `siege_spot_<id>`
   and the old drawn region is replaced. A region changed in game with `/rg redefine` keeps its name; save the spot
   again so the class follows the new size.
3. **Delete a spot:** use delete on the spot (needs `knk.admin.delete`). **Its region stays in the world**; remove it
   in game with `/rg remove siege_spot_<id>` if you don't need it ([#989](https://github.com/PandiO/knk-workspace/issues/989)
   will handle this).

## 3. A safe test

On a test server, not during a match:

1. Make a test scenario with two teams, its town in the world you test in.
2. Create a spot, draw a 7 × 5 × 9 box (x × y × z) on flat open ground and keep the facing North: the form shows Size
   class Small and "The floor is solid and the space is clear." Submit, then reopen: Region is `siege_spot_<id>`.
3. Set Facing to East and re-run validation: the size check says too small and Submit is refused. Set it back.
4. Delete the test spot and remove its region with `/rg remove siege_spot_<id>`.

The full checklist is the [smoke test § 2](../siege-weapons-smoke-test.md#2-phase-2-spots-as-worldguard-regions-783-799-988-tier3).

## 4. Effects on existing data

1. `DropSiegeWeaponSpotBounds` drops `MinX`..`MaxZ` of `siege_weapon_spots`. A spot keeps its region, facing and class;
   a spot saved with bounds but no region has no place any more and needs a region before phase 3.
2. The custom `SiegeWeaponSpot` world task of #799 is gone: an old form that still has it can't be used for new spots
   (re-import the seed, § 1 item 4).
3. Nothing is written to the world except the rename of a drawn region to `siege_spot_<id>`.

## 5. Troubleshooting

1. **The form keeps saying "Validation could not be completed".** Check that the game server is connected to the
   realtime hub (its startup log) and `RegionQueries:Enabled` is on. For the site check alone,
   check `siege.weapons.enabled` and restart after changing it.
2. **"Region '…' doesn't exist on the game server" for a region you can see in game.** The region is in another world
   than the scenario's town (or hub location). Draw it in that world, or fix the scenario's town.
3. **The spot still shows `tempregion_worldtask_<n>` after Submit.** The rename failed (the API log says why). Save the
   spot again, or run `POST api/Regions/finalize-temp-names`. Do this within 14 days: the plugin's daily temp-region
   cleanup doesn't know spots yet and deletes the temp region after 14 days ([#989](https://github.com/PandiO/knk-workspace/issues/989)).
4. **The size class is wrong after a region was changed in game.** Save the spot again; the class is only worked out on
   save (and again in phase 3 before a weapon is placed).
5. **The old form with six bounds fields still opens.** The database has the seed from before #988; § 1 item 4.

## Changes

1. 2026-11-22: first version, weapon spots as WorldGuard regions (#988), docs #999
