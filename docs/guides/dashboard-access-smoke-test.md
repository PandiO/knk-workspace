# Dashboard access model — smoke test

**Status:** automated in CI; manual steps not run. 2026-11-14 ([#511](https://github.com/PandiO/knk-workspace/issues/511)): 35 checks marked `[automated]` with their test (web app § 8 in Playwright and Jest, API § 2.2, § 3, § 4 and § 7 in the API's xUnit tests); the rest is manual (migration on a real database, the plugin, live realtime, the Staff group's real metadata). Earlier: ready to run (API § 1–7, web app § 8). Not run yet: **accepted by the developer 2026-11-13 without a live
test**, scheduled in closed alpha test run 2 (checklist § 4c). AM1 and AM2 merged 2026-11-12 (knk-web-api `master`
`bc97b7d`); AM3 merged 2026-11-13 (knk-web-app `main` `e02ee79`, knk-web-api `master` `45043a7`, also on `next`).
AM4 (living docs, the [admin guide to the ranks](admin/dashboard-access-admin-guide.md)) done 2026-11-13 (#366).
**#371 (developer 2026-11-13, knk-web-app `claude/form-wizard-content-only-371`, not merged):** the form wizard and
create/edit are back on `knk.admin.content` (LAM3-1 reverted, answers #368); § 8 steps 6, 7, 9, 19 describe that.
**#374 (developer 2026-11-13, knk-web-api and knk-web-app `claude/api-writes-need-content-374`, merged into `next`
2026-11-13: API `b65e66d`, web app `ca1959d`; not live-tested; guides in docs #385):** the API
refuses creates, edits and link changes without `knk.admin.content` too, and the detail page's Select / Unlink / Add
need it; § 2.2 and § 8 step 9b.
**#383 (developer 2026-11-13, knk-web-app `claude/content-gate-toggles-383`, not merged):** the lootbox Types tab's
Enable/Disable, the roads page's Create New Street and the detail page's hot edit are greyed out without it; § 8 step 9c.
Known: a `knk.admin.user.manage`-only
rank can't load the Permission Group list (#369, § 8.1 step 4).
**Last updated:** 2026-11-14 (`[automated]` marks with their tests, backfill #511); 2026-11-13 (§ 8 step 9c: lootbox toggle, Create New Street and hot edit greyed out without `knk.admin.content`, #383); 2026-11-13 (§ 2.2 and § 8 step 9b: the API asks for `knk.admin.content` on create, edit and link changes, #374); 2026-11-13 (§ 8 steps 6, 7, 9, 19 and 9a: create/edit need `knk.admin.content`, #371); 2026-11-13 (AM4 docs done, #368/#369 noted, architecture anchors; docs #366); 2026-11-13 (status: merged, accepted without a live test, in test run 2); 2026-11-12 (§ 0 role accounts and deploy, § 2.1 configuration deletes, § 3 refusal codes, § 8 web
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

1. [automated] (`Tests/knkwebapi_v2.Tests/Security/DashboardChangeAccessRulesTests.cs`, `AreaNodeWithoutContent_Is403_WithTheNodes`) world-only, `POST api/Towns` with a minimal town and `PUT api/Towns/{town}` with the town as read: 403,
   `code: "NoWriteAccess"`, `nodes: ["knk.admin.world", "knk.admin.content"]`, message "Creating or editing Town
   requires knk.admin.world and knk.admin.content.".
2. [ ] world-only, `POST api/Relationships/Town/{town}/streets/link` with `{ "relatedId": {street} }` (and `…/unlink`):
   403 `NoWriteAccess` "Changing links of Town requires knk.admin.world and knk.admin.content.".
3. [automated] (`DashboardChangeAccessRulesTests.cs`, `AreaNodeAndContent_Passes`) world + content: steps 1 and 2 succeed (201 / 200 / 200).
4. [automated] (`DashboardChangeAccessRulesTests.cs`, `ContentWithoutTheAreaNode_Is403`) content-only: `POST api/Towns` → 403 "Requires the knk.admin.world permission." (the area node still counts).
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
- [automated] content-only rank: 403 "Requires the knk.admin.delete.bulk permission.": `Tests/knkwebapi_v2.Tests/Api/DashboardControllerTests.cs` (`BulkDelete_NeedsBothActionNodes_AndAWebLogin`)
- [automated] `"entityType": "User"` or `"PermissionGroup"` as the owner: 400 `BulkDeleteNotAllowed`: `DashboardControllerTests.cs`
- [automated] 101 ids: 400 `TooManyIds`; an unknown type: 404: `DashboardControllerTests.cs`
- [automated] the plugin key without a web login: 401: `DashboardControllerTests.cs`

## 4. Export (API)

`POST api/Dashboard/export` with `{ "entityType": "Town", "query": { "searchTerm": "", "sortBy": "name" } }`:

- [ ] Admin and the world-only rank: 200, every town in name order, `truncated: false`; one `DashboardExport` audit
  entry (type, scope `search`, count).
- [automated] with `"ids": [ … ]`: only those rows, in the search's order: `DashboardControllerTests.cs` (`Export_OfASelection_ReturnsTheSelectedRowsInTheSearchOrder`); the audit scope stays in the line above
- [automated] (`DashboardControllerTests.cs`, `Export_WithoutTheTypesAreaNode_Is403`, `Export_NeedsTheExportNode_AndAWebLogin`) content-only rank on `Town`: 403 "Requires the knk.admin.world permission."; Staff: 403 "Requires the
  knk.admin.export permission."
- [automated] `"entityType": "RoadProfile"`: 400 `ExportNotAvailable`: `DashboardControllerTests.cs` (`Export_OfATypeWithoutAList_Is400`)

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

- [automated] (`Tests/knkwebapi_v2.Tests/Security/ReadAccessRulesTests.cs`: `WorldOnly_CantReadItems_ButCanLookThemUp`, `ContentOnly_CantReadWorldData`, `Refusal_NamesTheType_AndItsReadNodes`) **Full reads per area.** World-only: `GET api/Towns` 200, `GET api/ItemBlueprints` 403 with
  `"code":"NoReadAccess","entityType":"ItemBlueprint"` and the read nodes in `nodes`; `POST api/Domains/search` 200.
  Content-only: the reverse (`POST api/Towns/search` 403, `GET api/Categories` 200).
- [automated] (`ReadAccessRulesTests.cs`: `ConfigOnly_ReadsWhatGameSettingsNeeds`, `CrossAreaPages_ReadOnlyWhatTheyNeed`) **Cross-area pages.** Config-only: `GET api/Locations`, `GET api/Towns`, `GET api/Districts`,
  `GET api/Structures` 200 (Game settings), `GET api/Streets` 403. Kit-only: `POST api/ItemBlueprints/search`,
  `GET api/Grades`, `GET api/Categories` 200, `GET api/Tags` 403. A discovery-only rank: `GET api/Domains` 200,
  `GET api/Domains/access-rules` 403.
- [automated] (`Tests/knkwebapi_v2.Tests/Api/LookupControllerTests.cs`, `ReadAccessRulesTests.cs`) **Lookups.** World-only: `POST api/Lookup/ItemBlueprint/search` with `{ "searchTerm": "sword" }` → items with
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
- [automated] (`ReadAccessRulesTests.cs`, `ReadChecks_AreCached_AndForgottenWhenGrantsChange`) **Grant changes apply at once.** Give the world-only account `knk.admin.content` on the player profile (or a
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

1. [automated] `e2e/dashboard-access.spec.ts`, `e2e/admin-navigation.spec.ts` **player:** the bar shows Home, Leaderboards, Guides only. Open any page with the network tab open: no request to
   `api/Metadata/entities` or `api/EntityTypeConfiguration` (before AM3 each page load got a 403 there). `/dashboard`
   shows "Staff only — This page needs one of these permissions: knk.admin.content, knk.admin.world, …".
2. [automated] `e2e/dashboard-access.spec.ts`, `src/components/ObjectDashboard/__tests__/ObjectDashboard.test.tsx` **world-only:** the bar shows **Dashboard**; the explorer lists only world types (Domain, Town, District,
   Structure, Street, Location, gates, sub-regions). Typing `/dashboard/Category` in the address bar falls back to a
   world type. The sidebar has no Minecraft catalogue.
3. [automated] `e2e/dashboard-access.spec.ts` **content-only:** only content types; `/dashboard/Town` falls back to a content type.
4. [ ] *(Manual: which types the Staff group's nodes open comes from the real API's metadata; the filtering itself is automated in `e2e/dashboard-access.spec.ts`.)* **Staff:** Dashboard opens with User, Permission Group, Kit and the siege types; no world or content types.
5. [automated] `e2e/dashboard-access.spec.ts` (an admin's explorer and actions) **Admin / owner:** every type, as before.

### 8.2 Disabled actions with "Requires <node>" (decision 11)

6. [automated] `e2e/dashboard-access.spec.ts`, `ObjectDashboard.test.tsx` **Staff** on User: the rows' **Delete** is greyed out; hover says "Requires knk.admin.delete". **Edit** opens
   the player profile (enabled without `knk.admin.content`, #371). **New** is greyed out with "Requires
   knk.admin.content" under the header. In the bar **Export CSV** is disabled with "Requires knk.admin.export" next to it. No
   **Delete (n)** appears when rows are ticked. The ⚙ (Entity setup) is disabled with "Requires knk.admin.content".
7. [automated] `ObjectDashboard.test.tsx` ("disables New and Edit for a type whose area node is missing"), `src/hooks/__tests__/useEntityAccess.test.ts` **Staff** on Permission Group: **New** and **Edit** need `knk.admin.user.perm` **and** `knk.admin.content`
   (#371): disabled with "Requires …" naming the ones the Staff group doesn't hold.
8. [automated] `e2e/dashboard-access.spec.ts` (export), `useEntityAccess.test.ts` **content-only** on Category: New, Edit, Delete and Export enabled; ticking rows shows **no** Delete (n).
9. [automated] `e2e/dashboard-access.spec.ts`, `ObjectDashboard.test.tsx` **world-only** (#371, LAM3-1 reverted): on Town, **New Town** is greyed out; hover and the line under the
   header say "Requires knk.admin.content"; no **New with** menu. A row's **Edit** is greyed out with "Requires
   knk.admin.content"; **View**, **Delete** (with `knk.admin.delete`) and **Export CSV** (with `knk.admin.export`)
   work as before. A town's detail page: **Edit** greyed out with the same hint. Open `/forms/Town`,
   `/forms/Town?autoOpen=true` and `/forms/Town/edit/<id>` directly: each is refused with "Staff only" naming
   `knk.admin.content`.
   9a. [automated] `ObjectDashboard.test.tsx` ("enables New and Edit for the area node plus knk.admin.content"); the saved draft and edit are the form wizard's own tests **world + content** (an account holding both): New Town, New with and Edit open the Town form; a draft
   saves; the edit saves.
   9b. [automated] `e2e/entity-detail.spec.ts` ("world-only (#374)"), `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` **world-only** (#374), a town's detail page: the Streets section's **Add…**, a street's **Unlink** and the
   Location's **Change…** / **Unlink** are greyed out with "Requires knk.admin.content" (the hint line under the
   section says so); **Delete** of a street (with `knk.admin.delete`) still works. **world + content**: Add… links a
   street, Unlink removes the link.
   9c. [automated] for the lootbox toggle: `src/components/lootbox/__tests__/LootboxTypesTab.gate.test.tsx`; Create New Street: `src/components/admin/roads/__tests__/RoadEdgesCard.streetGate.test.tsx`; hot edit: `src/components/DisplayWizard/__tests__/DisplayField.editGate.test.tsx` **Pages outside the form wizard** (#383). **lootbox-only** (`knk.admin.lootbox.manage`, no
   `knk.admin.content`), Lootboxes → Types: each type's **Enabled/Disabled** toggle is greyed out; hover and the line
   above the table say "Requires knk.admin.content". **world-only**, Roads → road edges, a row's Edit → Street
   dropdown: **Create New Street** is greyed out with the same hint; the street pick, Save and the **Road profiles**
   card's Add / Edit (`knk.admin.road`) still work. **world-only**, a town's detail page: a field's ✎ (hot edit, only
   where the display configuration marks a field "editable in display") is greyed out with the same hint. **With `knk.admin.content` added:** the toggle switches the type (confirm dialog),
   Create New Street creates and selects the street, ✎ saves.
10. [automated] `src/pages/__tests__/FormWizardPage.deleteConfig.test.tsx` ("disables a configuration's Delete with Requires knk.admin.delete"), `FormConfigurationTable.delete.test.tsx` **content-only**, Entity setup of a type (⚙): a form configuration's ⋯ → **Delete** works as before. With a
    user-level deny `knk.admin.delete = false` on that account (reload after the change): the Delete item is greyed out
    with "Requires knk.admin.delete", for form and display configurations alike (LV7-8).

### 8.3 Single and bulk delete (#205)

11. [automated] `e2e/dashboard-access.spec.ts` **Admin**, single delete: a row's Delete asks "Delete Street "Main Street"?" in a red dialog; Delete → toast
    "Street "Main Street" was deleted."; the row is gone. A street that is still used → "Delete Failed" with the reason
    and **Show what uses it** (as before, V6).
12. [automated] `e2e/dashboard-access.spec.ts`, `ObjectDashboard.test.tsx` **Admin**, bulk: tick three streets, one of them still used by a structure. The bar shows **Delete (3)** (red)
    before Export. Click → "Delete 3 Streets?" (count and type named). Confirm → toast "Deleted 2 of 3 Streets; 1
    weren't deleted." and a dialog "Deleted 2 of 3 Streets" listing the used street with its reason and **Show what
    uses it** (opens the list of structures; a link opens the structure). Close: the refused street is still ticked, the
    two deleted ones are gone from the table and the selection.
13. [automated] `ObjectDashboard.test.tsx` ("sends a large selection in chunks of 100 and ends with a toast when all were deleted") **Admin**, all deletable: tick three unused rows → Delete (3) → toast "Deleted 3 …", no dialog, selection empty.
14. [ ] *(Manual for the audit entries: they need the real API and database; the chunks of 100 and "Deleting… n / N" are automated in `ObjectDashboard.test.tsx` and `src/utils/__tests__/bulkDelete.test.ts`.)* **owner**, a large selection: tick rows on several pages (more than 100 if the test data has them) → one
    confirm; the button shows "Deleting… n / N" while it runs in chunks of 100; the audit log of the owner (player
    profile → Activity) has one "Bulk delete on the dashboard" entry per chunk with the type, counts and ids.
15. [automated] `e2e/dashboard-access.spec.ts` (User), `useEntityAccess.test.ts` ("never bulk deletes users") **Admin** on User or Permission Group: no Delete (n) at all (one at a time only, decision 6).
16. [automated] `e2e/dashboard-access.spec.ts` (the effect of the deny; that the API's check honours a user-level deny over a group wildcard is § 5) A **user-level deny** `knk.admin.delete.bulk = false` on the Admin account (reload): no Delete (n) anywhere;
    single Delete still works.

### 8.4 Export through the endpoint, refused reads, pickers

17. [automated] `e2e/dashboard-access.spec.ts` (one `POST api/Dashboard/export`, the file name), `src/utils/__tests__/tableExport.test.tsx` (columns, order, format); the audit entry: `DashboardControllerTests.cs` **content-only**, Category, nothing ticked: Export CSV → one `POST api/Dashboard/export` in the network tab, the
    file `Category-<date>.csv` with the table's columns in table order and the current sort (V2's format unchanged:
    comma, UTF-8 with BOM, `'` before formula-like text). The owner's audit log has "Dashboard export" (type, rows,
    "(search)").
18. [automated] `src/components/ObjectDashboard/__tests__/DashboardSelectionBar.test.tsx`, `tableExport.test.tsx` ("keeps the order it was ticked in") Tick three rows in a different order than the table shows, export: the file lists them **in the order you
    ticked them**, with their current values ("(selection)" in the audit entry).
19. [automated] `src/components/FormWizard/__tests__/RelationPicker.test.tsx` ("searches api/Lookup without a read node") **content-only**, a form of a content type with a field that picks a record of another area (for example a
    world type; world-only accounts no longer open forms, #371): the picker shows "Names only: the full … table needs
    one of: …" and still finds records by name (lookup mode, V6); **Create New** for that field is not offered (it
    needs that type's create node). A picker of a content type keeps the full table and Create New.
20. [automated] for the detail page's words: `e2e/entity-detail.spec.ts` ("You don't have access" with the nodes), `DisplayWizard.relationships.test.tsx`; the full table's refusal stays manual **world-only**, a refused read shows words instead of "Failed to load data": open `/display/Category/<id>` →
    "You don't have access to this Category." with "Requires one of: knk.admin.content, …" (V5's detail page); a table
    of another area's type (for example a picker's **Open full table** if one is offered) says "You don't have access
    to Category. Requires one of: …".
21. [ ] **Unchanged pages:** Game settings for a config-only rank (spawn and hub options list towns and locations),
    Domain discovery, Road network, Lootboxes, a player profile's kits for Staff — each loads for its own node.
22. [automated] for the page: `ObjectDashboard.test.tsx` ("bumps the table's live key once per burst"); manual only with two browsers on a live hub **Live updates:** with two browsers (Admin and world-only) on Town, a save by Admin refreshes the world-only
    table ("Updated by …"); a bulk delete of towns refreshes it once, not once per row.

### 8.5 Row actions in view and the right-click menu (#404, #405, #406)

knk-web-app PR knk-web-app#17 (merged into `next` 2026-11-14). Automated in CI (`e2e/dashboard-row-actions.spec.ts`,
plus the Jest tests `DataTable.rowsAndMenu.test.tsx` and the #406 block in `ObjectDashboard.test.tsx`); manual steps
not run.

1. [automated] Every row has the same edge and row line, no grey left edge from the second row on (#404):
   `dashboard-row-actions.spec.ts`.
2. [automated] At 390 px the row's Edit button stays in view (#405): `dashboard-row-actions.spec.ts`.
3. [automated] A right-click on a row opens View, Edit, Delete and Export as CSV; Escape closes it (#406).
4. [automated] Without `knk.admin.delete` / `knk.admin.export` those items are greyed out with "Requires <node>", like
   the row's buttons.
5. [automated] Shift+F10 on a focused row link opens the menu, ArrowDown moves, Escape gives the focus back.
6. [automated, Jest] Ctrl/Cmd + right-click and rows without items keep the browser's menu; a ticked row's menu says
   "Delete N Towns" / "Export N Towns as CSV" and acts on the selection; bulk Delete needs `knk.admin.delete.bulk`.
7. Manual (looks, both themes): on a type with many columns (Town, Structure), scroll the table sideways at desktop
   width and at 390 px: the checkbox column stays left and View / Edit / Delete stay right, the columns scroll under
   them with a soft shadow on the edge only while something is under it, and nothing shows through the sticky cells
   on hover or when a row is selected. Run once in `current` and once in `brand`.
8. Manual (real data): Export as CSV from the menu on an unticked row gives a file with that row only; with two rows
   ticked, the menu's export has both. Delete from the menu asks the same confirmation as the row button.

### 8.6 The PermissionGrant table (#408)

knk-web-api and knk-web-app branches `claude/permission-grant-table-408` (PRs into `next`, not merged). Automated in
CI (knk-web-app `e2e/permission-grants.spec.ts`, Jest `permissionGrantClient.test.ts`; knk-web-api
`PermissionGrantReadGateTests`, `PermissionGrantRepositoryTests`); manual steps not run. Deploy the API and the web app
together: an old API refuses the table's search without `knk.admin.user.perm`.

1. [automated] Owner/Admin: Dashboard → Permission Grant lists the grants with ID, Node, Effect (Granted/Denied),
   Holder and Expires (UTC): `e2e/permission-grants.spec.ts`.
2. [automated] Next shows page 2; a column header sorts through the API (ascending, then descending); the search box
   finds grants by node: `e2e/permission-grants.spec.ts`, `PermissionGrantRepositoryTests`.
3. [automated] `POST api/PermissionGrants/search`, `GET` and `GET {id}` need `knk.admin.user.manage` (the type's view
   node); a web user with only `knk.admin.user.perm` gets 403; writes stay on `knk.admin.user.perm`:
   `PermissionGrantReadGateTests`.
4. [automated] A rank with `knk.admin.user.manage` but not `knk.admin.user.perm` reads the table; New and Edit are
   disabled with "Requires knk.admin.user.perm"; there is no Delete action: `e2e/permission-grants.spec.ts`.
5. [automated] A rank without `knk.admin.user.manage` isn't offered the type (the URL falls back to a type it may see);
   when the API refuses the read anyway, the table says "You don't have access to … Requires …" instead of "Failed to
   load data": `e2e/permission-grants.spec.ts`.
6. Manual (real data, deployed together): as the owner on `next`, open Permission Grant: the rows match the grants of a
   player you know (their profile's Permissions tab) and of the Staff group, a group row shows "Group #<id>", and
   sorting by Expires puts never-expiring grants first ascending. Why manual: the real database and deploy, not the
   mocked API.
7. Manual (real rank): with a test rank that holds `knk.admin.user.manage` but not `knk.admin.user.perm` (the alpha's
   Staff, if it lacks `perm`), open the table: it loads and New / Edit are greyed out. Why manual: real permission
   resolution and the deployed API's gate.

## 9. Docs impact

**#383:** this guide step 9c and the CHANGELOG entry ship with the branch. At merge, for the `documentation`
sub-issue: the staff web app guide (lootbox Types toggle, roads Create New Street and hot edit greyed out without
`knk.admin.content`), web-app architecture (`changeNodesOf` / `useTypeChangeGate` in `useEntityAccess`) and the admin
guide to the ranks (lootbox and road ranks need `knk.admin.content` for those).

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
