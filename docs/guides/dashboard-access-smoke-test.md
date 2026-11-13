# Dashboard access model — smoke test

**Status:** Ready to run (API § 1–7, web app § 8). Not run yet: **accepted by the developer 2026-11-13 without a live
test**, scheduled in closed alpha test run 2 (checklist § 4c). AM1 and AM2 merged 2026-11-12 (knk-web-api `master`
`bc97b7d`); AM3 merged 2026-11-13 (knk-web-app `main` `e02ee79`, knk-web-api `master` `45043a7`, also on `next`).
AM4 (living docs, the [admin guide to the ranks](admin/dashboard-access-admin-guide.md)) done 2026-11-13 (#366).
**#371 (developer 2026-11-13, knk-web-app `claude/form-wizard-content-only-371`, not merged):** the form wizard and
create/edit are back on `knk.admin.content` (LAM3-1 reverted, answers #368); § 8 steps 6, 7, 9, 19 describe that.
**#374 (developer 2026-11-13, knk-web-api and knk-web-app `claude/api-writes-need-content-374`, not merged):** the API
refuses creates, edits and link changes without `knk.admin.content` too, and the detail page's Select / Unlink / Add
need it; § 2.2 and § 8 step 9b.
Known: a `knk.admin.user.manage`-only
rank can't load the Permission Group list (#369, § 8.1 step 4).
**Last updated:** 2026-11-13 (§ 2.2 and § 8 step 9b: the API asks for `knk.admin.content` on create, edit and link changes, #374); 2026-11-13 (§ 8 steps 6, 7, 9, 19 and 9a: create/edit need `knk.admin.content`, #371); 2026-11-13 (AM4 docs done, #368/#369 noted, architecture anchors; docs #366); 2026-11-13 (status: merged, accepted without a live test, in test run 2); 2026-11-12 (§ 0 role accounts and deploy, § 2.1 configuration deletes, § 3 refusal codes, § 8 web
app, § 9 docs impact; chain 3 link AM3); 2026-11-12 (AM1+AM2 merged); 2026-11-08 (§ 7 read gating and lookups, chain 3 link AM2); 2026-11-08 (draft with the AM1 API steps, chain 3 link AM1)
**Design:** [specs/dashboard-access-model/DESIGN.md](../specs/dashboard-access-model/DESIGN.md) · as built:
[web-api architecture § 5.1](../architecture/web-api-architecture.md#51-dashboard-access-model-pandioknk-workspace280-am1-merged-2026-11-12-am3-2026-11-13)
and [§ 5.2](../architecture/web-api-architecture.md#52-read-gating-per-area-and-lookups-pandioknk-workspace280-am2-merged-2026-11-12)
**Issue:** [PandiO/knk-workspace#280](https://github.com/PandiO/knk-workspace/issues/280)
**Branches (AM3):** knk-web-app `claude/dashboard-access-280` and knk-web-api `claude/dashboard-access-280`, both fresh
from their trunks (`main` `1371951`, `master` `bc97b7d`); AM1 and AM2 are already in `master`.

## 0. Before you start

- **Deploy AM1–AM3 together, API first** (design § 5). AM1 and AM2 are on `master` already; AM3 adds a small API
  change (configuration deletes, a refusal code) and the web app. Deploy the AM3 API branch, then the AM3 web app, in
  the same window: the merged web app (`main` `1371951`) still loads `GET api/Metadata` for players (a 403 on every
  page) and shows Delete buttons the API refuses. No migration, no setting, no plugin change in AM3.
- **Back up** the database: the migration `SeedDashboardActionNodes` (AM1) is data only and has a Down, but a backup is
  the quick way back.
- **Role accounts** (AM4 uses the same). Log in with each in its own browser profile; for the API steps copy its access
  token for `curl` (`Authorization: Bearer …`).

  | Account | How | Expect in the web app |
  |---|---|---|
  | **owner** | user 1 (`*`) | everything, also bulk delete and handing out `knk.admin.delete.bulk` |
  | **Admin** | Admin group (`knk.admin.*` on the alpha) | every area, delete, bulk delete, export |
  | **Staff** | Staff group only (`knk.admin.user.manage`, `knk.kit.manage`, `knk.siege.admin.*`, freeze, …) | dashboard with users, permission groups, kits and siege types; no Delete, no Export, no bulk Delete |
  | **content-only** | a test group with only `knk.admin.content` (the migration backfills `knk.admin.delete` + `knk.admin.export`) | content types; Delete and Export; no bulk Delete |
  | **world-only** | a test group with only `knk.admin.world` (backfilled the same way) | world types; Delete and Export; no bulk Delete; no Entity setup lists |
  | **player** | Default group only | no Dashboard link; no 403 on `api/Metadata` in the network tab |

  For § 7 also a config-only rank (`knk.admin.config`) and a kit-only rank (`knk.kit.manage`).
- The plugin runs with `api.auth.type: apikey` (design § 6).

## 1. Migration (API)

1. Note the grants before the deploy (`SELECT HolderId, Node, Value FROM permission_grants WHERE Node LIKE 'knk.admin.delete%' OR Node = 'knk.admin.export';`).
2. Start the new API (the migration runs on startup like the others).
3. Check:
   - [ ] **Admin**: on the alpha (Admin holds `knk.admin.*`) **no new rows**; on a database made by migrations only it has
     `knk.admin.delete`, `knk.admin.delete.bulk`, `knk.admin.export`.
   - [ ] **Staff group**: no `knk.admin.delete`, no `knk.admin.export`.
   - [ ] the content-only and world-only ranks (and any user with an explicit area node): `knk.admin.delete` and
     `knk.admin.export`, never `knk.admin.delete.bulk`.
   - [ ] a holder that had a deny of `knk.admin.delete` (or `knk.admin.delete.*`) keeps the deny and gets no grant.

## 2. Single delete (API)

For each role, `DELETE` one test record per area it holds (`api/Categories/{id}`, `api/Towns/{id}`, `api/Kits/{id}`,
`api/SiegeScenarios/{id}`, `api/road-profiles/{id}`, `api/Users/{id}`, `api/PermissionGroups/{id}`):

- [ ] owner and Admin: 204.
- [ ] content-only rank: 204 on a category, 403 "Requires the knk.admin.world permission." on a town.
- [ ] world-only rank: the reverse.
- [ ] Staff: 403 "Requires the knk.admin.delete permission." on a kit, a siege scenario, a road profile and a user
  (it could delete those before AM1 — expected, developer decision).
- [ ] a refusal by a database constraint still answers 409 with "… is still used by …".
- [ ] the plugin (apikey) still syncs: `/knk` commands that write (road edits, user groups, discovery reset) work.

### 2.1 Form and display configuration deletes (AM3, LV7-8)

Developer decision 2026-11-12: deleting a whole form or display configuration needs `knk.admin.delete` on top of
`knk.admin.content`.

- [ ] Admin: `DELETE api/FormConfigurations/{id}` and `DELETE api/DisplayConfigurations/{id}` of a test configuration
  answer 204 (or the existing "still used" refusal).
- [ ] A rank with `knk.admin.content` but a deny of `knk.admin.delete` (`knk.admin.delete = false`): 403 "Requires the
  knk.admin.delete permission." on both; saving, publishing and duplicating configurations still work.
- [ ] Deleting a step, field, section or validation rule inside the builder is unchanged (no `knk.admin.delete`).

### 2.2 Create, edit and link changes need `knk.admin.content` (#374)

Developer decision 2026-11-13: area staff work with the content available. Use the world-only rank (no
`knk.admin.content`), a world + content account and the Staff group; `{town}`, `{street}` are test records.

1. [ ] world-only, `POST api/Towns` with a minimal town and `PUT api/Towns/{town}` with the town as read: 403,
   `code: "NoWriteAccess"`, `nodes: ["knk.admin.world", "knk.admin.content"]`, message "Creating or editing Town
   requires knk.admin.world and knk.admin.content.".
2. [ ] world-only, `POST api/Relationships/Town/{town}/streets/link` with `{ "relatedId": {street} }` (and `…/unlink`):
   403 `NoWriteAccess` "Changing links of Town requires knk.admin.world and knk.admin.content.".
3. [ ] world + content: steps 1 and 2 succeed (201 / 200 / 200).
4. [ ] content-only: `POST api/Towns` → 403 "Requires the knk.admin.world permission." (the area node still counts).
5. [ ] Staff: `PUT api/Kits/{id}` and `POST api/SiegeScenarios` → 403 naming `knk.admin.content`; the Staff player
   profile's freeze, balance change, kick and ban still work; `PUT api/Users/{id}` (own profile) is unchanged.
6. [ ] Not affected for the world-only rank: `DELETE api/Towns/{id}` (with `knk.admin.delete`), export, reads and
   lookups as in § 2, § 4 and § 7.
7. [ ] Not affected: a road rank creates and edits a road profile on the roads page; an Admin without a direct
   `knk.admin.content` grant but with `knk.admin.*` creates a town.
8. [ ] The plugin (apikey) still writes: create a lootbox spawn area in-game, set a gate door's state, and a `/knk`
   command that creates a location or domain; no 403 in the API log.
9. [ ] `GET api/Metadata/Town` (as Admin): `actionNodes.create` and `actionNodes.edit` are
   `["knk.admin.world", "knk.admin.content"]`; `relationships[streets].nodes` the same; Permission Group's
   `actionNodes.create` stays `["knk.admin.user.perm"]`.

## 3. Bulk delete (API)

`POST api/Dashboard/bulk-delete` with `{ "entityType": "Category", "ids": [ … ] }`:

- [ ] owner: 200 `{ deleted, refused }`; a still-used row is in `refused` with the "still used by" reason and
  `"code": "InUse"` (AM3; other refusals `Refused`, `NotFound` or `Failed`), the others are gone. One audit entry `DashboardBulkDelete` on the owner's audit log (player profile → audit).
- [ ] Admin on the alpha: 200 (bulk through `knk.admin.*`).
- [ ] content-only rank: 403 "Requires the knk.admin.delete.bulk permission."
- [ ] `"entityType": "User"` or `"PermissionGroup"` as the owner: 400 `BulkDeleteNotAllowed`.
- [ ] 101 ids: 400 `TooManyIds`; an unknown type: 404.
- [ ] the plugin key without a web login: 401.

## 4. Export (API)

`POST api/Dashboard/export` with `{ "entityType": "Town", "query": { "searchTerm": "", "sortBy": "name" } }`:

- [ ] Admin and the world-only rank: 200, every town in name order, `truncated: false`; one `DashboardExport` audit
  entry (type, scope `search`, count).
- [ ] with `"ids": [ … ]`: only those rows, in the search's order, scope `selection`.
- [ ] content-only rank on `Town`: 403 "Requires the knk.admin.world permission."; Staff: 403 "Requires the
  knk.admin.export permission."
- [ ] `"entityType": "RoadProfile"`: 400 `ExportNotAvailable`.

## 5. Granting (API or the web app's player profile)

- [ ] Admin grants `knk.admin.delete` or `knk.admin.export` to a player: allowed.
- [ ] Admin grants `knk.admin.delete.bulk`, `knk.admin.delete.*` or `knk.admin.*`: 403 "Only the owner can hand out bulk
  delete."; the owner can.
- [ ] Admin assigns a group that carries `knk.admin.*` or bulk delete: refused (rank or owner-only); the owner can.
- [ ] a user-level deny `knk.admin.delete.bulk = false` on an Admin: their bulk delete answers 403 (the user beats the
  group's wildcard).
- [ ] **Staff and groups above its rank** (developer 2026-11-08): as Staff, add or remove the Moderator or Admin group
  on a player, change a node of the Moderator or Admin group, and edit (`PUT api/PermissionGroups/{id}`) one of them:
  each 403 with "You can only … groups ranked below your own."; the same on a group below Staff works (if Staff holds
  its nodes).

## 6. Metadata and live updates (API)

- [ ] `GET api/Metadata/entities/Town`: `area: "World"`, `accessNode: "knk.admin.world"`, `readNodes` with
  `knk.admin.config` and `knk.admin.road`, `deletable`, `bulkDeletable`, `exportable` true, `actionNodes.delete` =
  `["knk.admin.world","knk.admin.delete"]`. `PermissionGroup`: no `bulkDelete`, writes on `knk.admin.user.perm`.
- [ ] With realtime on: a world-only rank's open dashboard refreshes when someone else saves a town, not when someone
  saves a category; a content-only rank the reverse. A bulk delete sends one event per row; the table refreshes once
  (AM3 coalesces).

## 7. Read gating and lookups (API, AM2)

No migration, no setting. With the accounts of § 0 (plus the config-only, kit-only and player accounts):

- [ ] **Full reads per area.** World-only: `GET api/Towns` 200, `GET api/ItemBlueprints` 403 with
  `"code":"NoReadAccess","entityType":"ItemBlueprint"` and the read nodes in `nodes`; `POST api/Domains/search` 200.
  Content-only: the reverse (`POST api/Towns/search` 403, `GET api/Categories` 200).
- [ ] **Cross-area pages.** Config-only: `GET api/Locations`, `GET api/Towns`, `GET api/Districts`,
  `GET api/Structures` 200 (Game settings), `GET api/Streets` 403. Kit-only: `POST api/ItemBlueprints/search`,
  `GET api/Grades`, `GET api/Categories` 200, `GET api/Tags` 403. A discovery-only rank: `GET api/Domains` 200,
  `GET api/Domains/access-rules` 403.
- [ ] **Lookups.** World-only: `POST api/Lookup/ItemBlueprint/search` with `{ "searchTerm": "sword" }` → items with
  `id`, `label`, maybe `detail` (category · grade), nothing else; `GET api/Lookup/Clan/<id>` → `{ id, label }`.
  `POST api/Lookup/User/search` with part of someone's **email** finds nobody; with part of their username finds them,
  label = username, no email anywhere. `POST api/Lookup/Nope/search` 404, `POST api/Lookup/CategoryTag/search` 400
  `LookupNotAvailable`. The player: 403 on all of these.
- [ ] **Wizard for any area node.** Kit-only (or world-only): open the form of a type of their area; the form loads
  (form configuration, metadata), field validation answers (no 403 on `api/field-validation-rules/validate` or
  `validate-batch`), the draft saves and shows in "Saved progress". Before AM2 a world-only user got 403 on
  validation. Content-only still creates and edits form configurations; world-only gets 403 on
  `POST api/FormConfigurations` and on `GET api/FormConfigurations/<id>/export`.
- [ ] **Stays as it was.** The player: leaderboards, a public player profile, the guides' enchantment info, their own
  account page (`GET api/Users/<own id>`, own permission checks) load; `GET api/Metadata/entities` is 403 (AM3 stops
  asking for it without an area node; until then a console error is expected). Lootbox pages for a lootbox manager,
  user pages for `knk.admin.user.manage` unchanged.
- [ ] **Grant changes apply at once.** Give the world-only account `knk.admin.content` on the player profile (or a
  group it is in): `GET api/ItemBlueprints` answers 200 straight away (the read cache is dropped). Take it away: 403
  again straight away. A change made directly in the database shows within 30 s.
- [ ] **The plugin.** On the dev server with `api.auth.type: apikey`: towns, districts, structures, streets, locations,
  domains, gates and doors, kits (`/kit`), menus, item blueprints and enchantments load; a world task started from the
  web is found by its code (`/knk task <code>`) and completes; siege lobbies and scenario readiness load; road surveys
  and the compass work. Nothing in the plugin log says 401 or 403.

## 8. Web app (AM3)

Deploy the AM3 web app with the AM3 API. Themes: run 8.1–8.4 once in `current`, then glance at 8.2 and 8.4 in `brand`
and at 390 px width (phone): nothing scrolls sideways, the bulk dialogs fit.

### 8.1 Who opens the dashboard (decision 8)

1. [ ] **player:** the bar shows Home, Leaderboards, Guides only. Open any page with the network tab open: no request to
   `api/Metadata/entities` or `api/EntityTypeConfiguration` (before AM3 each page load got a 403 there). `/dashboard`
   shows "Staff only — This page needs one of these permissions: knk.admin.content, knk.admin.world, …".
2. [ ] **world-only:** the bar shows **Dashboard**; the explorer lists only world types (Domain, Town, District,
   Structure, Street, Location, gates, sub-regions). Typing `/dashboard/Category` in the address bar falls back to a
   world type. The sidebar has no Minecraft catalogue.
3. [ ] **content-only:** only content types; `/dashboard/Town` falls back to a content type.
4. [ ] **Staff:** Dashboard opens with User, Permission Group, Kit and the siege types; no world or content types.
5. [ ] **Admin / owner:** every type, as before.

### 8.2 Disabled actions with "Requires <node>" (decision 11)

6. [ ] **Staff** on User: the rows' **Delete** is greyed out; hover says "Requires knk.admin.delete". **Edit** opens
   the player profile (enabled without `knk.admin.content`, #371). **New** is greyed out with "Requires
   knk.admin.content" under the header. In the bar **Export CSV** is disabled with "Requires knk.admin.export" next to it. No
   **Delete (n)** appears when rows are ticked. The ⚙ (Entity setup) is disabled with "Requires knk.admin.content".
7. [ ] **Staff** on Permission Group: **New** and **Edit** need `knk.admin.user.perm` **and** `knk.admin.content`
   (#371): disabled with "Requires …" naming the ones the Staff group doesn't hold.
8. [ ] **content-only** on Category: New, Edit, Delete and Export enabled; ticking rows shows **no** Delete (n).
9. [ ] **world-only** (#371, LAM3-1 reverted): on Town, **New Town** is greyed out; hover and the line under the
   header say "Requires knk.admin.content"; no **New with** menu. A row's **Edit** is greyed out with "Requires
   knk.admin.content"; **View**, **Delete** (with `knk.admin.delete`) and **Export CSV** (with `knk.admin.export`)
   work as before. A town's detail page: **Edit** greyed out with the same hint. Open `/forms/Town`,
   `/forms/Town?autoOpen=true` and `/forms/Town/edit/<id>` directly: each is refused with "Staff only" naming
   `knk.admin.content`.
   9a. [ ] **world + content** (an account holding both): New Town, New with and Edit open the Town form; a draft
   saves; the edit saves.
   9b. [ ] **world-only** (#374), a town's detail page: the Streets section's **Add…**, a street's **Unlink** and the
   Location's **Change…** / **Unlink** are greyed out with "Requires knk.admin.content" (the hint line under the
   section says so); **Delete** of a street (with `knk.admin.delete`) still works. **world + content**: Add… links a
   street, Unlink removes the link.
10. [ ] **content-only**, Entity setup of a type (⚙): a form configuration's ⋯ → **Delete** works as before. With a
    user-level deny `knk.admin.delete = false` on that account (reload after the change): the Delete item is greyed out
    with "Requires knk.admin.delete", for form and display configurations alike (LV7-8).

### 8.3 Single and bulk delete (#205)

11. [ ] **Admin**, single delete: a row's Delete asks "Delete Street "Main Street"?" in a red dialog; Delete → toast
    "Street "Main Street" was deleted."; the row is gone. A street that is still used → "Delete Failed" with the reason
    and **Show what uses it** (as before, V6).
12. [ ] **Admin**, bulk: tick three streets, one of them still used by a structure. The bar shows **Delete (3)** (red)
    before Export. Click → "Delete 3 Streets?" (count and type named). Confirm → toast "Deleted 2 of 3 Streets; 1
    weren't deleted." and a dialog "Deleted 2 of 3 Streets" listing the used street with its reason and **Show what
    uses it** (opens the list of structures; a link opens the structure). Close: the refused street is still ticked, the
    two deleted ones are gone from the table and the selection.
13. [ ] **Admin**, all deletable: tick three unused rows → Delete (3) → toast "Deleted 3 …", no dialog, selection empty.
14. [ ] **owner**, a large selection: tick rows on several pages (more than 100 if the test data has them) → one
    confirm; the button shows "Deleting… n / N" while it runs in chunks of 100; the audit log of the owner (player
    profile → Activity) has one "Bulk delete on the dashboard" entry per chunk with the type, counts and ids.
15. [ ] **Admin** on User or Permission Group: no Delete (n) at all (one at a time only, decision 6).
16. [ ] A **user-level deny** `knk.admin.delete.bulk = false` on the Admin account (reload): no Delete (n) anywhere;
    single Delete still works.

### 8.4 Export through the endpoint, refused reads, pickers

17. [ ] **content-only**, Category, nothing ticked: Export CSV → one `POST api/Dashboard/export` in the network tab, the
    file `Category-<date>.csv` with the table's columns in table order and the current sort (V2's format unchanged:
    comma, UTF-8 with BOM, `'` before formula-like text). The owner's audit log has "Dashboard export" (type, rows,
    "(search)").
18. [ ] Tick three rows in a different order than the table shows, export: the file lists them **in the order you
    ticked them**, with their current values ("(selection)" in the audit entry).
19. [ ] **content-only**, a form of a content type with a field that picks a record of another area (for example a
    world type; world-only accounts no longer open forms, #371): the picker shows "Names only: the full … table needs
    one of: …" and still finds records by name (lookup mode, V6); **Create New** for that field is not offered (it
    needs that type's create node). A picker of a content type keeps the full table and Create New.
20. [ ] **world-only**, a refused read shows words instead of "Failed to load data": open `/display/Category/<id>` →
    "You don't have access to this Category." with "Requires one of: knk.admin.content, …" (V5's detail page); a table
    of another area's type (for example a picker's **Open full table** if one is offered) says "You don't have access
    to Category. Requires one of: …".
21. [ ] **Unchanged pages:** Game settings for a config-only rank (spawn and hub options list towns and locations),
    Domain discovery, Road network, Lootboxes, a player profile's kits for Staff — each loads for its own node.
22. [ ] **Live updates:** with two browsers (Admin and world-only) on Town, a save by Admin refreshes the world-only
    table ("Updated by …"); a bulk delete of towns refreshes it once, not once per row.

## 9. Docs impact

**#374:** this guide § 2.2 and step 9b, the design (status, § 4.3, § 4.7, § 7) and the CHANGELOG entry ship with the
branch. At merge, for the `documentation` sub-issue: web-api architecture § 5.1 (`ChangeNodes`,
`RequireDashboardChange`, relationship nodes), web-app architecture (`withContentNode` on relationship nodes), the
[admin guide to the ranks](admin/dashboard-access-admin-guide.md) (who needs `knk.admin.content` to edit; Staff and kits
or siege setup), the staff web app guide (greyed-out Select / Unlink / Add) and the feature register row.

**AM3:** written before merge; the rest went to the `documentation` sub-issue #366 at merge (with AM4's list) and was done there
on 2026-11-13: the admin guide to the ranks, the staff web app guide, both architecture docs, the design status, entity
lists § 7, realtime § S4, the register and the guides index.

- **This guide:** § 0 role accounts and deploy, § 2.1, § 3 refusal codes, § 8 (done on the AM3 branch).
- **Design** (`specs/dashboard-access-model/DESIGN.md`): status line (AM3 built); § 4.7 "not covered" now leaves out
  whole form/display configurations (LV7-8); § 7 the 2026-11-12 decisions (done on the AM3 branch).
- **CHANGELOG:** Unreleased entry for AM3 with Admin steps (done on the AM3 branch; moves under the merge date).
- **web-app architecture** (`architecture/web-app-architecture.md`): `useEntityAccess` / `useViewableTypes`,
  `RouteAccess` `staffAny` and `AREA_NODES`, metadata only for area-node holders (`useAnyAreaNode`,
  `loadedEntityMetadata`), bulk delete (`dashboardClient`, `utils/bulkDelete.ts`, `BulkDeleteResultDialog`), export via
  `POST api/Dashboard/export` (`readExportRows`), `readRefusalMessage`, `fetchByIdOrLookup`, Entity setup for
  non-content staff, configuration Delete gate. (AM4)
- **web-api architecture** § 5.1: configuration deletes need `knk.admin.delete`; bulk-delete refusals carry `code`. (AM4)
- **Staff web app guide** (`guides/admin/staff-web-app-guide.md`): § 1 dashboard per area (no longer "every type for
  `knk.admin.content`"), hidden/disabled Delete and bulk Delete, § 3 Export through the API (audited), § 10
  troubleshooting rows (missing area node, refused Delete, "You don't have access to …"). (AM4 / docs issue)
- **Admin guide to the ranks** (new, AM4): which node does what, owner-only bulk, Staff without delete/export,
  configuration deletes.
- **Entity lists smoke test § 7** (V2 export): the rows now come from the export endpoint (one request, audited).
- **Realtime smoke test § S4**: accounts per area (comment on #280).
- **Feature register** row for #280/#205: AM3 built; merge column at merge.
