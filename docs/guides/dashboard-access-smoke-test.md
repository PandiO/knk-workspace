# Dashboard access model — smoke test

**Status:** Draft (AM1 and AM2, API part). AM4 finishes it once AM3 (web app) is built; until then the steps run
against the API with `curl` or Swagger. Not run yet. AM1 and AM2 **merged 2026-11-12** into knk-web-api `master` `bc97b7d` (with V5–V7); AM3 (web app) and AM4 not built.
**Last updated:** 2026-11-12 (AM1+AM2 merged); 2026-11-08 (§ 7 read gating and lookups, chain 3 link AM2); 2026-11-08 (draft with the AM1 API steps, chain 3 link AM1)
**Design:** [specs/dashboard-access-model/DESIGN.md](../specs/dashboard-access-model/DESIGN.md) · as built:
[web-api architecture § 5.1](../architecture/web-api-architecture.md#51-dashboard-access-model-pandioknk-workspace280-am1--branch-claudedashboard-access-280-not-merged)
and [§ 5.2](../architecture/web-api-architecture.md#52-read-gating-per-area-and-lookups-pandioknk-workspace280-am2--branch-claudedashboard-access-280-not-merged)
**Issue:** [PandiO/knk-workspace#280](https://github.com/PandiO/knk-workspace/issues/280)
**Branches:** knk-web-api `claude/dashboard-access-280` (contains P1 `claude/kit-grant-delivery-261` with chain 2's R1,
and chain 2's X1 API `claude/realtime-web-live-183`)

## 0. Before you start

- **Deploy AM1–AM3 together, API first** (design § 5). AM1 alone changes behaviour already: every dashboard delete now
  needs `knk.admin.delete`, and Staff loses delete (developer decision). Run the API part on a dev database first.
- **Back up** the database: the migration `SeedDashboardActionNodes` is data only and has a Down, but a backup is the
  quick way back.
- **Five accounts** (AM4 uses the same): the owner (`*`), an Admin (Admin group), a Staff member (Staff group only), a
  content-only rank (a group with `knk.admin.content`), a world-only rank (a group with `knk.admin.world`). For § 7
  also a config-only rank (`knk.admin.config`), a kit-only rank (`knk.kit.manage`) and a player without staff nodes. Log in with
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

To be written by AM4: open the dashboard per role and see only your area's types; full read vs lookup in pickers ("You
don't have access to <type>" on a refused read); New/Edit/Delete disabled with "Requires <node>"; bulk "Delete (n)"
hidden without the nodes; export through the endpoint; Game settings, discovery, roads and lootbox pages still load for
their own nodes.
