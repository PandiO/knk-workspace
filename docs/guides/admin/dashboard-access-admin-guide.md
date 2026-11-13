# Dashboard access, staff ranks and area nodes — admin guide

**Status:** Living document — update in place. Describes knk-web-api `master` `45043a7` and knk-web-app `main` `e02ee79`
(the dashboard access model, [#280](https://github.com/PandiO/knk-workspace/issues/280) AM1–AM3, and bulk delete,
[#205](https://github.com/PandiO/knk-workspace/issues/205); merged 2026-11-12/13). **Not live-tested:** the developer
accepted it on 2026-11-13 without a live test; the [dashboard access smoke test](../dashboard-access-smoke-test.md) is
scheduled in closed alpha test run 2 ([checklist § 4c](../../reports/alpha-tests/test-run-2/test-run-2-checklist.md)).
**Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#366)

Who may see, create, edit, delete, bulk delete and export what on the web app's **Dashboard**, and how to set a rank
up for it. For how the pages themselves work see the [staff web app guide](staff-web-app-guide.md); for in-game
commands and their nodes see the [commands reference](../users/commands.md). The design and its decisions are in
[the access model design](../../specs/dashboard-access-model/DESIGN.md).

## 1. Before you start

- Rights are **permission nodes** held by a user or a group (a rank). A user has their own grants, then those of their
  groups and the groups' parents; the first holder in that chain with a matching grant decides. A trailing `*`
  matches everything below it: `knk.admin.*` matches every `knk.admin.<x>` node, `*` matches every node.
- The web app only decides what it **offers**: it hides or disables what you can't do. The API checks the same nodes
  on every request, so a hand-typed address or a direct API call is refused the same way.
- **After a node change**, a web user's reads follow at once; the buttons follow after a reload of the page. A change
  made directly in the database shows within 30 seconds.
- Deploy notes and the changes for existing groups: [CHANGELOG 2026-11-12 and 2026-11-13](../../CHANGELOG.md).

## 2. Area nodes: one per part of the dashboard

Each dashboard type belongs to one **area**. The area's node means **view, create and edit** of its types. Holding any
one area node opens the Dashboard; the explorer then lists only the types of the areas you hold.

| Area | Area node | Types on the dashboard | Bulk delete possible |
|---|---|---|---|
| Content | `knk.admin.content` | Category, Tag, Grade, Item blueprint, Enchantment definition, Banner design, Banner layer, Clan, Minecraft block/material/enchantment references | yes |
| World | `knk.admin.world` | Domain, Town, District, Structure, Street, Location, Gate structure, Gate door, Domain sub-region | yes |
| Kits | `knk.kit.manage` | Kit | yes |
| Lootboxes | `knk.admin.lootbox.manage` | Lootbox type, special entry, spawn area | yes |
| Siege | `knk.siege.admin.manage` | Siege scenario, team, lobby, objective, spawnpoint | yes |
| Roads | `knk.admin.road` | Road profile | yes |
| Players | `knk.admin.user.manage` (changing permission groups: `knk.admin.user.perm`) | User, Permission group | **no**, one at a time only |

Link rows, snapshots and similar records are listed under their area but are view-only. The registry that decides all
this is `Attributes/DashboardAccess.cs` in knk-web-api; the web app reads it from the metadata, so nothing is
hard-coded per type.

**Reading another area's records.** Without a type's area node you can't open its list or detail page ("You don't have
access to Category. Requires one of: …"). Two exceptions keep the other pages working:

- Some pages need a few types of another area in full, so those page nodes also count as a **read node** of that type
  (for example `knk.admin.config` reads towns and locations for Game settings; `knk.kit.manage` reads item blueprints,
  grades and categories). The full list is in [the design § 4.6.2](../../specs/dashboard-access-model/DESIGN.md).
- In a form, a link field to a type of another area searches **by name only** ("Names only: the full Street table
  needs one of: …"), and that field offers no **Create New**. Any area node allows these name lookups.

## 3. Action nodes: delete, bulk delete, export

| Node | Allows | Needs as well | Who can hand it out |
|---|---|---|---|
| `knk.admin.delete` | Delete **one** record (a row's Delete, the detail page's Delete); also deleting a whole form or display configuration in Entity setup | the type's area node (`knk.admin.content` for configurations) | anyone who holds it |
| `knk.admin.delete.bulk` | **Delete (n)**: several rows in one action, up to 100 per request (the web app sends larger selections in chunks) | `knk.admin.delete` and the area node; never for users and permission groups | **only the owner** |
| `knk.admin.export` | **Export CSV** of the dashboard's rows (the selection, or the whole search, at most 10,000 rows); each export is in the audit log | the area node | anyone who holds it |

`knk.admin.delete.*` matches both delete nodes. Deleting a step, field, section or rule inside a builder is not a
delete in this sense and needs only `knk.admin.content`.

**Bulk delete is the owner's to hand out.** Nobody but a `*` holder can grant, deny or revoke
`knk.admin.delete.bulk`, or any wildcard that covers it (`*`, `knk.*`, `knk.admin.*`, `knk.admin.delete.*`). The same
goes for adding someone to a group whose nodes (or its parents' nodes) cover it. The API answers "Only the owner can
hand out bulk delete." So **an Admin can no longer grant `knk.admin.*`**, and only the owner puts someone in the Admin
group.

## 4. What each rank can do

As seeded on the closed alpha (Staff → Moderator → Admin inherit from each other, lowest first; the Admin group holds
`knk.admin.*`; the migration `SeedDashboardActionNodes` adds
`knk.admin.delete` and `knk.admin.export` to every user and group with an explicit area node, except the Staff group;
see [the design § 4.5](../../specs/dashboard-access-model/DESIGN.md)).

| Rank | Dashboard | Create, edit | Delete one | Bulk delete | Export | Entity setup lists and builders |
|---|---|---|---|---|---|---|
| **Owner** (user 1, `*`) | every type | everything | yes | yes | yes | yes |
| **Admin** group (`knk.admin.*`) | every type | everything | yes | yes | yes | yes |
| **Staff** group, and **Moderator** (on the alpha Moderator inherits Staff's nodes) | User, Permission group, Kit, the siege types (its own nodes: `knk.admin.user.manage`, `knk.kit.manage`, `knk.siege.admin.*`, …) | in those areas | **no** (disabled: "Requires knk.admin.delete") | no | **no** (disabled: "Requires knk.admin.export") | no ("Entity setup needs knk.admin.content") |
| **Area staff** (a builder or content rank with one area node, backfilled) | that area's types | in that area | yes, in that area | no | yes, in that area | only with `knk.admin.content` |
| Default, Alpha Tester, premium ranks | no Dashboard link ("Staff only") | — | — | — | — | — |

Staff could delete kits, siege setup, road profiles and users through the API before #280; it can't any more unless a
Staff member is given `knk.admin.delete` (developer decision 2026-11-08). Freeze, kick, ban and balance changes are
unchanged.

**Form wizard for every area.** New, New with, Edit and Drafts open the form wizard (`/forms/<Type>`, `/forms/<Type>/edit/<id>`),
which opens for **any** area node, so area staff create and edit their own types there. The Entity setup lists, the
form and display builders and the Minecraft catalogue stay `knk.admin.content` only. This differs from the design
(which kept those routes on `knk.admin.content`) and waits for a developer decision:
[#368](https://github.com/PandiO/knk-workspace/issues/368).

## 5. Ranks above and below you: the escalation guard

A web user (not the plugin) changes permissions only within their own reach:

- **Grant, deny or revoke a node** on someone: you must hold that node yourself, and you can't change your own
  permissions (only `*` can).
- **Add or remove a group** on someone: the group must rank **below your own highest group** (its weight), and you
  must hold every node it grants, parents included. Premium ranks are exempt from the node check for holders of
  `knk.admin.user.group.premium`.
- **Change a group** (its grants, its name and weight, its parent, or delete it): only a group ranked below your own
  highest group, also after the change (you can't raise a group to your rank). "You can only change groups ranked
  below your own."
- **Owner-only:** `knk.admin.delete.bulk` and the wildcards covering it (§ 3).

So Staff can't touch the Moderator or Admin groups, an Admin can make Moderators and Staff but not other Admins, and
only the owner changes the Admin group or hands it out. In game, `/knk user <player> group|perm …` checks its own nodes
and rank ("Outrank" in the [commands reference](../users/commands.md)).

## 6. Giving someone an area node

**One person** (web app, needs `knk.admin.user.perm` and the node yourself): **Admin → Player moderation**, open the
player's profile, **Permissions** tab → **Grant/deny node**: type the node (for example `knk.admin.world`), **Grant**.
The expiry is filled in as one day from now; clear it for a permanent grant. Add `knk.admin.delete` and
`knk.admin.export` too if they should delete and export (the migration only backfilled holders that existed at the
deploy). In game: `/knk user <player> perm grant knk.admin.world`.

**A builder or content group** (a rank for several people):

1. Pick or create the group. A new group goes in with **Dashboard → Permission group → New** (needs
   `knk.admin.user.perm`); give it a weight below your own rank.
2. Give the group its nodes. There is no web screen for a group's nodes yet
   ([#50](https://github.com/PandiO/knk-workspace/issues/50)): the owner or an Admin sets them through
   the API with the group's id as the holder (holder ids are shared by users and groups):
   `PUT api/PermissionGrants/by-node` with `{ "holderId": <group id>, "node": "knk.admin.world", "value": true }`, and
   the same for `knk.admin.delete` and `knk.admin.export`. Never add `knk.admin.delete.bulk` unless the owner does it
   on purpose.
3. Add the members: the player profile's **Groups** card (**Select a group…**, optional expiry), or in game
   `/knk user <player> group add <group>`.
4. Check it: log in as a member (or ask one). The bar shows **Dashboard**, the explorer lists only the area's types,
   and a type of another area in the address bar falls back to one of theirs.

**Taking it away:** revoke the node or remove the membership the same way; the member's reads stop at once, and the
buttons after a reload.

## 7. Safe test procedure

On the dev server, with test accounts per rank (owner, Admin, Staff, a content-only and a world-only rank, a player),
run the [dashboard access smoke test](../dashboard-access-smoke-test.md): § 0 lists the accounts, § 1–7 the API checks,
§ 8 the web app (about 30 minutes). Back up the database before a deploy that includes the migration. Try a bulk
delete on test records first: it can't be undone, and each refused row stays selected with its reason.

## 8. Common problems

| You see | Why | What to do |
|---|---|---|
| No **Dashboard** in the bar; `/dashboard` says "Staff only — This page needs one of these permissions: …" | No area node | Grant the area node of the types they work on (§ 6) |
| The explorer doesn't list a type; its address falls back to another type | No area node for that type's area | Grant that area's node |
| Delete greyed out: "Requires knk.admin.delete" | No delete node | Grant `knk.admin.delete`, or ask someone who has it |
| No **Delete (n)** when rows are ticked | No `knk.admin.delete.bulk` (owner-only), or the type is User or Permission group | Ask the owner; users and groups are deleted one at a time |
| **Export CSV** disabled: "Requires knk.admin.export" | No export node | Grant `knk.admin.export` |
| "Only the owner can hand out bulk delete." | The node or group covers `knk.admin.delete.bulk` | Only the owner can do this |
| "You can only hand out or remove groups ranked below your own." / "… change groups ranked below your own." | The group ranks at or above your highest group | Ask someone ranked higher |
| "Entity setup needs knk.admin.content" | Area staff open Entity setup's lists | Expected; New/Edit/Drafts still open the form ([#368](https://github.com/PandiO/knk-workspace/issues/368)) |
| Permission group listed, but its table answers "Requires the knk.admin.user.perm permission." | Known bug [#369](https://github.com/PandiO/knk-workspace/issues/369): the list needs `knk.admin.user.perm` | Grant `knk.admin.user.perm`, or wait for the fix |
| A form's link field has no Create New | No create node for the related type | Expected; ask someone of that area to create the record |
| The top bar's **Create New** offers a type you can't create | Known gap [#353](https://github.com/PandiO/knk-workspace/issues/353) | Use the dashboard's **New** |
