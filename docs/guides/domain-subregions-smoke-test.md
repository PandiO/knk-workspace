# Domain sub-regions — smoke test checklist

**Status:** To test. Written for the unmerged branches `claude/domain-expansion-regions-s46gvf`: knk-web-api `6d438bf`, knk-plugin `808acc4`, knk-web-app `4b88565`.
**Last updated:** 2026-10-23
**Linear:** [KNG-259](https://linear.app/kngpandi/issue/KNG-259) (P6); covers [KNG-254](https://linear.app/kngpandi/issue/KNG-254) to [KNG-258](https://linear.app/kngpandi/issue/KNG-258)
**Related:** [admin guide](admin/domain-subregions-admin-guide.md), [design](../specs/domain-subregions/DESIGN.md)

## 0. Setup

1. Back up `plugins/WorldGuard/worlds/*/regions.yml` and the dev database.
2. Deploy the API branch and run `dotnet ef database update`. The migration is `DomainSubRegions`.
3. Deploy the plugin: `./gradlew :knk-paper:dev`.
4. Run the web app branch.
5. Import the form seeds: `DomainSubRegion`, then `Town`, `District`, `Structure` (seed v2) and `GateStructure` (seed v3). Make those the defaults.
6. Pick a test district. Have a non-op account without `knk.region.bypass` ready.

## 1. Garrison: house plus round tower

1. Create a GateStructure "Garrison Test" in the district. Its region is the house, drawn as a cuboid. Save it.
2. Edit it. In **Sub-regions**, choose Create New, name it "Tower", and use Send to Minecraft. In game, `//sel cyl`, select a circle next to the house that touches it, then `save`.
   - **Expect:** chat says "The cylinder is stored as a polygon with N corners".
3. Finish the sub-region form and save.
   - **Expect:** `/rg list` shows `domain_<gate>_sub_<n>`, and no `tempregion_worldtask_*` is left.
   - **Expect:** `/rg info domain_<gate>_sub_<n>` shows:
     - parent = `domain_<gate>`;
     - the same priority as the gate (30);
     - the gate's flags;
     - after the next sync (≤ 5 min, or `/knk regions sync` after 5 s), `knk-allow-entry`, `knk-allow-exit`, `knk-domain-name` and `knk-domain-id = <gate id>`.
4. `//sel poly`, then `/rg select domain_<gate>_sub_<n>`.
   - **Expect:** the selection follows the circle, not the box around it.

## 2. One domain for messages, access and discovery

1. As the non-op player, walk into the house, then into the tower, then back.
   - **Expect:** one enter message for the gate, nothing at the house/tower border, and one leave message when leaving the last part.
2. Set the gate's **Allow exit** off in the web app, then run `/knk regions sync`.
   - **Expect:** walking house → tower → house is allowed.
   - **Expect:** walking out of the tower or the house into the street is refused.
3. Set **Allow entry** off.
   - **Expect:** entering from the street is refused at the house and at the tower.
   - **Expect:** an op still passes.
4. On a fresh account, enter the gate through the tower only.
   - **Expect:** the gate is discovered once, with its reward.

## 3. Flag and member sync

1. `/rg flag domain_<gate> greeting Hello`, `/rg addmember domain_<gate> <player>`, then `/knk regions sync`.
   - **Expect:** `/rg info` of the tower shows the greeting and the member.
   - **Expect:** the sync reports `1 sub-region(s) updated`, and a second `/knk regions sync` reports `0 updated, 1 unchanged`.
2. `/rg flag domain_<gate>_sub_<n> pvp allow`, then `/knk regions sync`.
   - **Expect:** the tower's `pvp` is back to the gate's value.
3. Restart the server.
   - **Expect:** startup logs the access sync. The tower keeps everything.

## 4. Doors and containment

1. Add a gate door whose location is in the tower part.
   - **Expect:** the location check passes: it is inside the gate.
2. Re-run the gate's **main** region step with a new house shape.
   - **Expect:** the tower's parent is still `domain_<gate>`.
3. Re-run the tower's task (Replace via Minecraft) with a bigger circle.
   - **Expect:** same name `domain_<gate>_sub_<n>`, the new shape, the same flags. No temp region is left.

## 5. Remove, orphan, purge

1. Remove the tower from the gate's Sub-regions list.
2. Run `/knk regions sync` twice, at least 5 s apart.
   - **Expect:** the second run logs "newly orphaned".
   - **Expect:** `/rg info` of the tower shows no parent, no `knk-*` access flags and no `knk-domain-id`, and does show `knk-orphaned-since`.
   - **Expect:** walking in is no longer a gate entry.
3. `/knk regions temp`.
   - **Expect:** the tower is under "Orphaned sub-regions not old enough yet".
4. `/knk regions temp purge 1` straight away.
   - **Expect:** it is kept.
5. Adopt it again: a new sub-region task on the gate, then `select domain_<gate>_sub_<n>`, then save.
   - **Expect:** it gets a new name `domain_<gate>_sub_<m>`.
   - **Expect:** the mark is gone after the next sync.
   - **Expect:** it is a copy of the gate again.
6. Optional, with a test value of `regions.temp-retention.days: 1`, or by setting `knk-orphaned-since` to an old timestamp by hand: the daily cleanup or `purge 1` deletes an orphan whose mark is older than the cutoff.

## 6. Rules on save

1. Add a sub-region drawn in another world.
   - **Expect:** 400 "The region was drawn in world …".
2. Use `select` on another domain's region.
   - **Expect:** 400 "already belongs to …".
3. Try to change the world of a domain that has sub-regions.
   - **Expect:** refused, with "its sub-regions are in world …".
