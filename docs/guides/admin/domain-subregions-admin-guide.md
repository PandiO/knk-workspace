# Domain sub-regions — admin guide

**Status:** Draft v1. Describes the unmerged feature branches `claude/domain-expansion-regions-s46gvf`: knk-web-api `6d438bf`, knk-plugin `46f805e`, knk-web-app `4b88565`. Not live-tested yet; see the [smoke test](../domain-subregions-smoke-test.md).
**Last updated:** 2026-10-23
**Linear:** [KNG-253](https://linear.app/kngpandi/issue/KNG-253) (design) and phases [KNG-254](https://linear.app/kngpandi/issue/KNG-254) to [KNG-259](https://linear.app/kngpandi/issue/KNG-259)
**Design:** [`specs/domain-subregions/DESIGN.md`](../../specs/domain-subregions/DESIGN.md)

## What it is for

A domain (town, district, structure, gate) has one **main region**. Sub-regions are extra WorldGuard regions for a shape one region can't hold.

**Example.** A garrison gate is a round tower with a square house at its base:
- the house is the main region;
- the tower is a sub-region, drawn with `//sel cyl`.

The domain is the union of its regions:
- Walking between the house and the tower is not leaving or entering the gate: no message, no access check.
- A door location in the tower counts as inside the gate.
- Discovery and analytics count the gate once.

## Adding a sub-region

1. Create the domain as usual, with its main region, and **save it**. The Sub-regions list is only usable once the domain exists, like a gate's doors.
2. Edit the domain and open the last step, **Sub-regions**. Choose **Create New**: the sub-region form opens with the domain filled in.
3. Optionally give it a name ("Tower"). Then use **Send to Minecraft** on *Region* and claim the task in game.
4. In game, select the area with WorldEdit:
   - `//sel cuboid`, `//sel poly`, or `//sel cyl` for a round part.
   - A cylinder is stored as a polygon along its block outline. The chat says how many corners it got.
   - `//sel ellipsoid` and `//sel convex` work too. An ellipsoid is stored with the width of its middle slice over its full height.
   - Then type `save`. Or type `select <region>` to adopt an existing region, such as an imported v1 `town_5,2` part.
5. Finish the sub-region form. On save the region is renamed `domain_<domain id>_sub_<sub-region id>`. The game server makes it a copy of the main region at once.

**Rules checked on save:**
- the region must be drawn in the domain's world;
- it can't be any domain's main region or another domain's sub-region;
- a domain with sub-regions can't move to another world.

**Not checked yet** ([KNG-261](https://linear.app/kngpandi/issue/KNG-261)): whether the sub-region lies inside the parent domain, or touches the domain's other regions. Check those yourself.

## What is shared with the main region

The **main region is the source of truth**. Every sub-region gets the main region's:
- priority;
- every flag: category flags, your own `/rg flag` values such as `pvp allow` or a greeting, and the KnK access flags;
- owners and members.

It also gets the main region as its WorldGuard parent.

**Set flags on the main region only.** A flag set by hand on a sub-region is replaced at the next sync.

The sync runs:
- every 5 minutes (`regions.access.sync.interval-minutes`);
- at startup;
- on `/knk regions repair`;
- right after a region is renamed.

`/knk regions sync` runs it now and reports what it did:

```
Domain access sync: 12 domain rule(s): 1 region(s) updated, ...
Sub-regions: 1 domain(s) with sub-regions: 1 sub-region(s) updated, 0 unchanged, 0 not found
```

Domain data (AllowEntry/AllowExit, enter and leave messages, discovery, warp settings) belongs to the domain, so it is the same for all of its regions.

## Changing or removing a sub-region

- **New shape.** Open the sub-region in the domain's list and use **Replace via Minecraft**. The new shape replaces the old one under the same name, keeping its flags (as KNG-103 does for main regions).
- **Remove.** Remove it from the list. Its WorldGuard region stays for now.
  - Within 10 minutes (two syncs) it stops counting as part of the domain: its access flags and parent are removed, and it gets `knk-orphaned-since`.
  - 14 days later the daily cleanup deletes it (`regions.temp-retention.days`).
  - Until then you can take it back with `select domain_<id>_sub_<n>` in a new sub-region task.
- **Deleting a domain** orphans all of its sub-regions the same way.
- `/knk regions temp` lists orphaned sub-regions. `/knk regions temp purge [hours]` deletes those orphaned longer than `hours`.

## Things to know

- `/rg info domain_<id>_sub_<n>` shows the parent (the main region), `knk-domain-id` and the copied flags.
- `/navigate <domain> region` targets the main region. A domain whose roads ignore its entry rule only exempts its main region for now ([KNG-260](https://linear.app/kngpandi/issue/KNG-260)).
- Don't roll the API back to a version before KNG-254 while sub-regions exist. It would list none, and the game server would orphan them all.
- Import the form seeds first: `DomainSubRegion`, then the new Town/District/Structure (seed v2) and GateStructure (seed v3) versions. Make the new versions the defaults.
