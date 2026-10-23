# Domain sub-regions — smoke test checklist

**Status:** **Passed 2026-10-23** (developer, sections 0-7). One bug was found: a gate's edit form listed no sub-regions; it was fixed in knk-web-api `503c541` and re-checked. Merged: knk-web-api `master` `779629e`, knk-plugin `main` `9dfd7aae`, knk-web-app `main` `bf0d142`.
**Last updated:** 2026-10-23 (v2: deploy order, first-sync and cache timing, form and display checks, other domain types, finalize-temp-names, new shapes on main regions)
**Linear:** [KNG-259](https://linear.app/kngpandi/issue/KNG-259) (P6); covers [KNG-254](https://linear.app/kngpandi/issue/KNG-254) to [KNG-258](https://linear.app/kngpandi/issue/KNG-258)
**Related:** [admin guide](admin/domain-subregions-admin-guide.md), [design](../specs/domain-subregions/DESIGN.md) §13

`<gate>` is the test gate's domain id and `<n>` the sub-region's id. Use the server console or an op for `/rg` and `/knk` commands, and a **non-op account without `knk.region.bypass`** for every walking step. Write down any step that fails, with its server log lines.

## 0. Setup

1. Back up `plugins/WorldGuard/worlds/*/regions.yml` and the dev database.
2. Deploy the API branch: `dotnet ef database update`, which applies migration `DomainSubRegions`. Start the API.
3. Deploy the plugin branch with `./gradlew :knk-paper:dev` and start the server.
   - **Expect:** the startup log has a `[KnK Access] Region access sync` line with no errors.
   - From now on every domain region carries `knk-domain-id`: check `/rg info` on any domain region.
4. Run the web app branch (`npm start`).
5. Import the form seeds, in this order (Form configurations, then Import / seeds):
   - `DomainSubRegion`;
   - `Town`, `District` and `Structure` seed v2;
   - `GateStructure` seed v3.
   Make the four new versions the defaults.
6. Import the display seeds `Structure` and `GateStructure` seed v2, and make them the defaults.
7. Pick a test district in the dev world.

## 1. Garrison: house plus round tower

1. Create a GateStructure "Garrison Test" in the test district. Draw its region (the house) as a cuboid and submit.
   - **Expect:** `/rg info domain_<gate>` shows parent = the district's region and priority 30.
2. Edit the gate. Its last step is **Sub-regions**; choose **Create New**.
   - **Expect:** the sub-region form opens with *Domain* already filled in as "Garrison Test".
3. Name it "Tower". On *Region*, use Send to Minecraft and claim the task in game. Then `//sel cyl`, select a circle (radius 4-6) that touches the house, and type `save`.
   - **Expect:** chat says "The cylinder is stored as a polygon with N corners." and the task completes.
4. Finish the sub-region form.
   - **Expect:** it appears in the Sub-regions list.
   - **Expect:** `/rg list` shows `domain_<gate>_sub_<n>` and no `tempregion_worldtask_*` from this task.
   - **Expect:** the server log has `Sub-region domain_<gate>_sub_<n> set up as a copy of domain_<gate>`.
5. `/rg info domain_<gate>_sub_<n>`.
   - **Expect:** parent = `domain_<gate>`; priority = the gate's (30); the gate's flags, including `knk-allow-entry`, `knk-allow-exit`, `knk-domain-name` and `knk-domain-id = <gate>`.
6. `/rg select domain_<gate>_sub_<n>`.
   - **Expect:** the selection is a polygon following the circle, not a square box.
7. Open the gate's display page.
   - **Expect:** a **Sub-regions** section lists "Tower" with `domain_<gate>_sub_<n>`, and Edit opens its form.

## 2. One domain: messages, access, discovery

Wait about a minute after section 1 so the game server has looked up the new region.

1. As the non-op player, walk street → house → tower → house → street.
   - **Expect:** one enter message for the gate, nothing at the house/tower border, and one leave message at the street.
2. Walk street → tower directly, and back.
   - **Expect:** the same enter/leave messages.
3. In the web app set the gate's **Allow exit** off, save, then run `/knk regions sync`.
   - **Expect:** walking house ↔ tower is allowed.
   - **Expect:** leaving the house or the tower to the street is refused, with "You are not allowed to leave Garrison Test.".
4. Set **Allow exit** back on and **Allow entry** off, then run `/knk regions sync`.
   - **Expect:** entering from the street is refused at both the house and the tower.
   - **Expect:** an op passes.
   - Then set Allow entry back on.
5. On an account that hasn't discovered the gate, enter through the tower only.
   - **Expect:** the gate is discovered once, with its reward, and walking on into the house gives nothing new.

## 3. Flag and member sync

1. Run `/rg flag domain_<gate> greeting Hello`, `/rg addmember domain_<gate> <player>`, then `/knk regions sync`.
   - **Expect:** the sync reports "Sub-regions: … 1 sub-region(s) updated".
   - **Expect:** `/rg info` of the tower shows the greeting and the member.
2. Run `/knk regions sync` again.
   - **Expect:** "0 sub-region(s) updated, 1 unchanged".
3. `/rg flag domain_<gate>_sub_<n> pvp allow`, then `/knk regions sync`.
   - **Expect:** the tower's `pvp` is back to the gate's value (unset or deny).
4. Restart the server and wait for the startup sync.
   - **Expect:** the tower still has everything from step 1. `/knk regions repair` reports no failures.
5. Clean up: `/rg flag domain_<gate> greeting` and `/rg removemember domain_<gate> <player>`, then `/knk regions sync`.
   - **Expect:** both are gone from the tower too.

## 4. Doors, containment and re-runs

1. Add a gate door. Capture its location inside the **tower** part.
   - **Expect:** the location check passes, with no "outside the gate" message.
2. Capture another door location outside both parts.
   - **Expect:** it is reported outside, as before.
3. Re-run the gate's **main** region step (Replace via Minecraft on *Region*) with a slightly different house, then save the gate.
   - **Expect:** still `domain_<gate>`, and the tower's parent is still `domain_<gate>`.
4. Re-run the tower's task (Edit the tower, Replace via Minecraft) with a bigger circle, then save.
   - **Expect:** the same name `domain_<gate>_sub_<n>` with the new shape and the same flags.
   - **Expect:** no temp region is left, and the log says "replaced the previous domain_<gate>_sub_<n> in place".

## 5. Remove, orphan, re-adopt, purge

1. Remove the tower from the gate's Sub-regions list.
2. Run `/knk regions sync`, wait at least 5 s, and run it again.
   - **Expect:** the second run logs "Orphaned sub-regions: 1 sub-region(s) newly orphaned".
   - **Expect:** `/rg info` of the tower shows no parent, no `knk-allow-*` / `knk-domain-name` / `knk-domain-id`, and `knk-orphaned-since`.
3. Wait about a minute, then walk from the street into the tower area as the non-op player.
   - **Expect:** no gate enter message, and no refusal even if Allow entry is off.
4. `/knk regions temp`.
   - **Expect:** the tower is under "Orphaned sub-regions not old enough yet".
   - Note the `knk-orphaned-since` value. Restart the server and check `/rg info` again.
   - **Expect:** the same value. The mark survives a restart, so the 14 days don't start over.
5. `/knk regions temp purge 1`.
   - **Expect:** the tower is kept (it was orphaned just now).
6. Adopt it again: on the gate, Create New sub-region, claim the task, type `select domain_<gate>_sub_<n>`, then finish the form.
   - **Expect:** it is renamed `domain_<gate>_sub_<m>`, with the new row's id.
   - **Expect:** after the next sync it is a copy of the gate again and has no `knk-orphaned-since`.
7. Optional, for deletion: remove it again and orphan it (step 2). Then either set `/rg flag domain_<gate>_sub_<m> knk-orphaned-since 1` or set `regions.temp-retention.days: 1` and wait a day. Then `/knk regions temp purge 1`.
   - **Expect:** "Orphaned sub-regions deleted: …", and `/rg list` no longer has it.
8. Optional: delete the whole test gate in the web app.
   - **Expect:** its sub-regions are orphaned on the next two syncs, like step 2.

## 6. Rules on save

1. Add a sub-region to the gate, but draw it in another world.
   - **Expect:** saving the sub-region fails with "The region was drawn in world …, but Garrison Test is in world …".
2. Add a sub-region with `select <the district's region>`.
   - **Expect:** it fails with "Region '…' … already belongs to …".
3. Try to set the gate's world to another world while it has a sub-region.
   - **Expect:** refused, with "its sub-regions are in world …".

## 7. Other domain types and shapes

1. Give the test **district** a sub-region drawn with `//sel poly`.
   - **Expect:** it is a copy of the district: parent = the district's region, priority 20, and the district's flags.
   - **Expect:** walking between the district and its sub-region gives no district message, while structures inside still give theirs.
2. Draw a new structure's **main** region with `//sel cyl`.
   - **Expect:** a polygon region (shapes apply to main regions too).
3. Optional: `//sel ellipsoid` gives a polygon, and chat mentions "its top and bottom are covered as wide as its middle".
4. Optional, rename retry: stop the server, add a sub-region in the web app (the rename fails, so it stays `tempregion_worldtask_*`), start the server, then `POST /api/Regions/finalize-temp-names`.
   - **Expect:** the sub-region is renamed and counted in `renamed`.

## Known limits (not failures)

- **Placement checks.** Whether a sub-region lies inside the parent domain or touches its own domain isn't checked yet ([KNG-261](https://linear.app/kngpandi/issue/KNG-261)).
- **Navigation** only knows the main region ([KNG-260](https://linear.app/kngpandi/issue/KNG-260)).
- **Timing.** An admin's flag on the main region reaches the sub-regions within 5 minutes, or at once with `/knk regions sync`.
