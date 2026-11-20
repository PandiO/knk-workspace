# Warehouses and Production Structures — Admin Guide

**Status:** Current · **Last updated:** 2026-11-20 (P-3 not built with P4's areas, #883, docs #882); 2026-11-19 (P3 pointers to the production engine admin guide; docs #839); 2026-11-19 (first version, production P2 #91/#676/#677, docs PandiO/knk-workspace#830)
**Checked against:** knk-web-api `next` `fcfced27`, knk-web-app `next` `18385344`, knk-plugin `next` `8ebb30be` (not
released; the game side is off until `production.enabled` is on; the manual steps of the
[smoke test § 3](../production-storage-transport-smoke-test.md#3-phase-p2-world-rural-structures-warehouse-production-structure-91-api-676-web-app-677-plugin-tier3)
have not been run live yet)
**Related:** [production DESIGN § 3.3–3.4](../../specs/production-storage-transport/DESIGN.md#33-world-entities) (the
rules), [production world architecture](../../architecture/production-world.md) (placement, lookup, region kinds, tests),
[API contract](../../specs/api/API_CONTRACT_PRODUCTION_WORLD.md), [territory admin guide](territory-admin-guide.md)
(holders, ranges, conflicts), [stock admin guide](stock-admin-guide.md) (storages, Adjust and Move), [staff web app
guide](staff-web-app-guide.md) (the dashboard and forms in general), [plugin configuration § 4.31](plugin-configuration.md#431-production)

Production phase P2 puts the production buildings in the world. A structure now stands either **in a district** (with
a street and house number, as before) or **rural**: out in its town's territory, with only a town. Two new structure
types belong to production:

1. A **warehouse** is a town's storage hub. It gets a delivery storage when it is created.
2. A **production structure** is a farm, logger, quarry or other producer. It gets an output storage when it is
   created. Its kind, production lines, cycles and upgrades are phase P3: see the [production engine admin
   guide](production-engine-admin-guide.md).

**Placement rules** warn when a structure's region sticks out of its district (P-1) or lies outside its town's
territory (P-2). They never refuse a save unless you make them blocking. Nothing produces yet, and players see nothing
new apart from the PvP rule around rural production structures (§ 6).

## 1. What you need

1. **knk-web-api** with migration `AddProductionWorld` applied (after `AddStockCore`;
   [production installation § 5.3](../production-installation.md#53-apply-the-migrations)). Existing structures keep
   their district, street and house number.
2. **knk-web-app** of the same `next` (or later).
3. **Seeds.** As content staff, import the form seeds `Warehouse` and `ProductionStructure` and the display seeds
   `Warehouse` and `ProductionStructure` (form and display configuration lists, Import / seeds) and make them the
   default ("make default").
4. **Stock core and territory** set up: the [stock admin guide](stock-admin-guide.md) for the storages, the
   [territory admin guide](territory-admin-guide.md) for towns, ranges and the switches.
5. **For the territory rule P-2 and the region kinds:** the knk-plugin build of `next` with `production.enabled: true`
   in `config.yml`, the API's game setting **Production enabled** ticked, and the API able to reach the plugin's region
   HTTP server (`MinecraftPlugin:BaseUrl` and the shared plugin key, as for region checks today). No new key in either.
6. **Nodes:**

   | To | Node(s) |
   |---|---|
   | See warehouses and production structures | `knk.admin.world` |
   | Create and edit them | `knk.admin.world` and `knk.admin.content` |
   | Delete them | `knk.admin.world` and `knk.admin.delete` |
   | Make a placement rule blocking (form builder) | admin (`*`) |
   | Adjust or move stock in their storages | `knk.economy.admin` ([stock admin guide § 1](stock-admin-guide.md#1-what-you-need)) |
   | `/knk regions repair` in game | `knk.admin.regions` |

## 2. Creating a warehouse or production structure

Open the **Dashboard**, type **Warehouse** or **ProductionStructure**, and press **Create**. The form comes from the
seed you imported.

1. **General information:** Name and description.
2. **Placement:** choose **one** of the two:
    1. **In a district:** District, Street and House number (picked from the lists). Leave **Town (rural)** empty.
    2. **Rural:** leave District, Street and House number empty and pick the town under **Town (rural)**.

   Both, or neither, is refused on Submit with "The form could not be submitted. A structure is either in a district
   (districtId) or rural (townId): set exactly one of the two." A rural structure with a street is refused too ("A
   rural structure (townId) has no street"). Close the message, fix the Placement step and Submit again.
3. **Region and access:** press **Send to Minecraft** on Region, claim the task in game (`/knk task-claim <code>` if it
   isn't offered to you), select the area with WorldEdit and confirm. The Region field fills with
   `tempregion_worldtask_<n>`; after the save it becomes `domain_<id>`. The world comes from the region's task. Allow
   entry, Allow exit and the entry rule on roads work as for any structure.
4. **The type's own step** (**Warehouse** or **Production**):
    1. Warehouse: **Accepts deliveries** (on by default) and **Priority** (0–1000; a town's warehouse with the higher
       priority is chosen first for deliveries, from phase P5 on).
    2. Production structure: **Level** (1–10), **Production on**, **Workers** (0–100, default 2), **Automatic
       transport**, **Transport threshold** and **Transport capacity** (empty = the planner's default), **Deliver to**
       (Nearest, or Preferred with a **Preferred warehouse**).
5. Spawn point, Navigate to and Sub-regions as for any structure. Press **Submit**.

**After the save** you see "Warehouse created." (or "ProductionStructure created."). A failed placement rule that is a
warning shows a message that stays until you close it: "Saved with a placement warning: P-2: the production
structure's region is not inside its town's territory (or part of it is contested)." The structure is saved; check its
region in game and redraw it if the warning is right.

**Storages:** the new warehouse gets a storage "<name> - deliveries" (purpose Delivery, its delivery storage); a
production structure gets "<name> - output" (purpose Output). Both are uncapped; set a cap on the storage's own page if
you want one ([stock admin guide § 2](stock-admin-guide.md#2-storages)).

**Editing:** **Edit** on the structure's page opens the same form. To move a structure out of its district, clear
District, Street and House number and pick a town under Town (rural); to move it in, the other way round. The
storages stay. In game the moved region keeps its old parent: see § 6 item 3. An edit shows "… updated." but no
placement warnings ([#831](https://github.com/PandiO/knk-workspace/issues/831)); view the page or re-run validation in the
form to see them.

## 3. Placement rules (P-1, P-2)

The seeded forms carry two rules on the **Region** field, both **warnings** (the admin sees them and can still save):

| Rule | Checks | Type |
|---|---|---|
| P-1 | A structure in a district has its region completely inside the district's region | Region Containment (depends on District) |
| P-2 | A rural structure's region lies inside its town's territory, and none of it is contested | **Inside Territory** (depends on Town) |

1. **The same rules run when the API saves** a structure, so a save from another tool can't skip them.
2. **Making a rule blocking:** as admin, open the form configuration (for example `ProductionStructure - Default (seed
   v1)`) in the form builder, edit the field **Region**, press **Edit** on the rule and tick **Block step progression on
   validation failure**; save the form configuration. A blocking rule refuses the save with its message.
3. **"Not checked":** when the game server can't answer (offline, `production.enabled` off in the plugin, the territory
   not built yet), the rule says the territory could not be checked and the structure is saved, **even when the rule
   is blocking**. An offline server never stops you from creating structures.
4. **Production off:** while the game setting **Production enabled** is off, P-2 is skipped (no warning, no lookup).
   You can still create, edit and delete warehouses and production structures.
5. **Adding Inside Territory to another form:** in the form builder press **+ Add Rule** on a region field and choose
   **Inside Territory**. The config fills with the town holder (`{"holderKind": "Town", "holderIdPath": "Id"}`), the
   message "The region is not inside {townName}'s territory (or part of it is contested).", and blocking off; set the
   dependency to the form's town field. The help line says the game server answers it and that it never blocks a save
   while it can't be checked. A rule on the structure's region checks every block column of the region and its
   sub-regions.
6. P-3 (production areas inside their structure's district or territory) is not built yet: P4 added the areas
   ([yield areas admin guide](production-yield-areas-admin-guide.md)) without the rule ([#883](https://github.com/PandiO/knk-workspace/issues/883)).

## 4. The dashboard and the structure pages

1. **Columns.** Warehouse: Town, Placement, District, Accepts deliveries, Priority, Territory flag, World.
   ProductionStructure: Town, Placement, District, Level, Production, Road connection, Territory flag, World. Structure
   (all types): Placement and Territory flag after World. Town is always the structure's town, also when it is in a
   district.
2. **Territory flag filter.** Next to the search box on the Structure, Warehouse and ProductionStructure lists: "All
   structures", "Flagged: in a contested zone", "Flagged: outside its town's territory". Use it to find the structures
   the game server's territory report flagged.
3. **A warehouse's or production structure's page** shows, below the details:
    1. **Placement:** first the **Warnings** of a production structure ("No warnings." when there are none):
        1. "Not connected to its town's road network: automatic transport is held." (rural, and the game server
           measured no road connection)
        2. "Its land is contested: it keeps its town and keeps producing."
        3. "Outside its town's territory: it keeps its town and keeps producing."

       Then Placement ("In district Market, Main 3" or "Rural, in its town's territory (no district or street)"),
       Town ("Phoenix (through its district)" or the rural town as a link), the region, and for a warehouse Deliveries
       ("Accepts deliveries, priority 0") and Delivery storage; for a production structure Road connection ("In a
       district: uses its town's roads", "Not measured yet", "Connected to its town's roads (measured …)" or "Not
       connected to its town's roads (measured …)"), Production ("On, level 1"), Workers present ("2 of 2") and Delivers to.
    2. **Territory and loyalty:** the flag, the conflict link and loyalty
       ([territory admin guide § 7](territory-admin-guide.md#7-structures-flag-and-loyalty)).
    3. **Storages:** every storage the structure holds, linked to its page, and one **Stock** panel per storage with
       Adjust stock and Move stock (greyed out without `knk.economy.admin`).
4. **Road connection** is measured by the game server from phase P5b on; you can't set it on the page. Until then it
   shows "Not measured yet" for rural structures.
5. **The generic Structure page** shows only the new columns and the filter; the placement panel is on the warehouse
   and production structure pages. The Structure form has no Town field yet, so a plain rural structure can only be made
   through the API ([#831](https://github.com/PandiO/knk-workspace/issues/831)).

## 5. Deleting

**Delete** on the list or page (needs `knk.admin.delete`):

1. The structure's own storages are deleted with it. If one of them **holds stock or has ledger history** the delete
   is refused ("This storage can't be deleted: it holds stock or has ledger history …") and nothing changes. Move its stock away first
   ([stock admin guide § 3.2](stock-admin-guide.md#32-move-stock)); a storage with history can't be deleted at all, so
   keep such a structure.
2. Deleting a warehouse sets every production structure that preferred it back to "the nearest warehouse".
3. A street or town a structure still uses can't be deleted: "This street can't be deleted: it is still used by 1
   structure. Remove or change those first."

## 6. In game

With the plugin's `production.enabled: true`:

1. **Run `/knk regions repair` once after turning it on** (or restart): it gives existing structures their region kind.
   A production structure's region becomes `RESOURCE_PRODUCTION` (flag `entry: ALLOW`); a warehouse's stays
   `STRUCTURE` (no flags). New structures get their kind when their region is created.
2. **Rural regions have no parent** and priority 30. So **PvP stays allowed** around rural structures (the world's
   default) and no town flags reach them; a structure in a district inherits its town's flags (for example `pvp deny`)
   as before. Players see no message about this.
3. **Moving a structure from a district to rural** keeps the old parent in WorldGuard: the repair never removes one.
   Clear it with `/rg setparent <region>` (no parent argument); a second repair leaves it without a parent
   ([#824](https://github.com/PandiO/knk-workspace/issues/824) will do it automatically).
4. **Territory flags** for rural structures come from the same territory report as for structures in a district: after
   `/knk territory rebuild` a rural structure outside its town's territory is flagged "Outside its town's territory",
   one on contested land "In a contested zone". It keeps its town and keeps producing.

With `production.enabled: false` nothing of this runs: production structures stay `STRUCTURE`, rural regions get the
old "unknown district" repair warning, and P-2 says "not checked".

## 7. A safe test

1. On a test server with the switches off, import the seeds (§ 1) and create a warehouse in a district and a rural
   production structure (§ 2). Check the storages on their pages (§ 4).
2. Turn the plugin's `production.enabled` and the game setting Production enabled on, restart, and run `/knk regions
   repair`. `/rg info <region>` on the rural structure: no parent, priority 30, `entry: ALLOW`.
3. Create a second rural production structure with its region well outside the town's territory: it saves with the
   P-2 warning. Make P-2 blocking (§ 3 item 2) and try again: refused. Make it a warning again.
4. Delete the test structures (their storages are empty).

The full checks are the [smoke test § 3](../production-storage-transport-smoke-test.md#3-phase-p2-world-rural-structures-warehouse-production-structure-91-api-676-web-app-677-plugin-tier3).

## 8. Effects on existing data

1. The migration only widens: district and street become optional and a town column is added. Every existing structure
   stays in its district with its street and house number; no warehouse or production structure exists until you
   create one.
2. Existing structure regions are not touched until `production.enabled` is on and the repair runs; then only regions
   of production structures get the `entry` flag.
3. Nothing in game uses the warehouses' or production structures' settings yet (P5); the API's production engine uses
   the level, workers and Production switch ([production engine admin guide](production-engine-admin-guide.md)).

## 9. Troubleshooting

| What you see | Why | What to do |
|---|---|---|
| "Submit failed": "… set exactly one of the two." | Both a district and a town, or neither | Clear one side on the Placement step (§ 2) |
| "… a rural structure (townId) has no street" | A street with no district | Clear Street and House number |
| "Saved with a placement warning: P-2 …" | The region is outside the town's territory or partly contested | Check `/knk territory here` on the spot; redraw the region, raise the town's power, or keep it as is |
| The P-2 warning says the territory could not be checked | The game server is offline, `production.enabled` is off in the plugin, the territory is not built yet, or the API can't reach the region HTTP server | Start the server, check `/knk territory status`, then "Re-run validation" |
| A blocking rule refuses a save you want | The rule is blocking | Make it a warning (§ 3 item 2), save, fix the region later |
| "… holds stock or has ledger history" on delete | A storage of the structure is not empty or has history | Move the stock away (stock admin guide), or keep the structure |
| A production structure's region has no `entry` flag | The repair ran with `production.enabled` off | Turn it on, restart, `/knk regions repair` |
| A rural structure still has its town's flags | It was moved from a district; the old parent stays | `/rg setparent <region>` (§ 6 item 3) |
| The warehouse or production structure list is missing from the dashboard | No `knk.admin.world`, or the display seeds are not imported | Grant the node; import the seeds (§ 1) |
| Adjust stock and Move stock are greyed out | No `knk.economy.admin` | Grant it (stock admin guide § 1) |

## Changes

1. 2026-11-19: first version (docs PandiO/knk-workspace#830).
2. 2026-11-19: pointers to the [production engine admin guide](production-engine-admin-guide.md) (docs PandiO/knk-workspace#839).
3. 2026-11-20: P-3 points to P4's areas and #883 (docs PandiO/knk-workspace#882).
