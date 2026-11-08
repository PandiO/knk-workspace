# Dashboard access model — smoke test

**Status:** Draft (AM1, API part). AM4 finishes it once AM2 (read gating, lookups) and AM3 (web app) are built; until
then the steps run against the API with `curl` or Swagger. Not run yet.
**Last updated:** 2026-11-08 (draft with the AM1 API steps, chain 3 link AM1)
**Design:** [specs/dashboard-access-model/DESIGN.md](../specs/dashboard-access-model/DESIGN.md) · as built:
[web-api architecture § 5.1](../architecture/web-api-architecture.md#51-dashboard-access-model-pandioknk-workspace280-am1--branch-claudedashboard-access-280-not-merged)
**Issue:** [PandiO/knk-workspace#280](https://github.com/PandiO/knk-workspace/issues/280)
**Branches:** knk-web-api `claude/dashboard-access-280` (contains P1 `claude/kit-grant-delivery-261` with chain 2's R1,
and chain 2's X1 API `claude/realtime-web-live-183`)

## 0. Before you start

- **Deploy AM1–AM3 together, API first** (design § 5). AM1 alone changes behaviour already: every dashboard delete now
  needs `knk.admin.delete`, and Staff loses delete (developer decision). Run the API part on a dev database first.
- **Back up** the database: the migration `SeedDashboardActionNodes` is data only and has a Down, but a backup is the
  quick way back.
- **Five accounts** (AM4 uses the same): the owner (`*`), an Admin (Admin group), a Staff member (Staff group only), a
  content-only rank (a group with `knk.admin.content`), a world-only rank (a group with `knk.admin.world`). Log in with
  each in its own browser profile and copy its access token for `curl` (`Authorization: Bearer …`).
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

## 3. Bulk delete (API)

`POST api/Dashboard/bulk-delete` with `{ "entityType": "Category", "ids": [ … ] }`:

- [ ] owner: 200 `{ deleted, refused }`; a still-used row is in `refused` with the "still used by" reason, the others
  are gone. One audit entry `DashboardBulkDelete` on the owner's audit log (player profile → audit).
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

## 7. Web app (AM3) and read gating (AM2)

To be written by AM4: open the dashboard per role and see only your area's types; full read vs 403 vs lookup in
pickers; New/Edit/Delete disabled with "Requires <node>"; bulk "Delete (n)" hidden without the nodes; export through the
endpoint; Game settings, discovery, roads and lootbox pages still load for their own nodes.
