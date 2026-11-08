# Dashboard access model — view, create, edit, delete, bulk delete and export

**Status:** Proposed design, **no code**. Waiting for the developer's answers to the open questions (§7).
**Last updated:** 2026-11-08 (first version, chain 3 link D1)
**Issue:** [PandiO/knk-workspace#280](https://github.com/PandiO/knk-workspace/issues/280) (blocks the bulk delete part of
[#205](https://github.com/PandiO/knk-workspace/issues/205)); roadmap [#24](https://github.com/PandiO/knk-workspace/issues/24).
**Related:** alpha hardening D7 and WP1/WP3 ([alpha-hardening/IMPLEMENTATION_PLAN.md](../alpha-hardening/IMPLEMENTATION_PLAN.md)
§ 1.3, § 8), admin IA #30 (chain 2 W4), realtime S4 #183 (chain 2 X1, [realtime-signalr/DESIGN.md](../realtime-signalr/DESIGN.md)
§ 6.5), [2026-10-26 command permission scan](../../reports/2026-10-26-command-permission-scan.md) (alpha groups).
**Code basis (read only):** knk-web-api `master` `2e3dfeb` and `claude/realtime-web-live-183` `4eb4275`; knk-web-app
`claude/admin-ia-30` `156b7e3` and `claude/realtime-web-live-183` `3852f14` (contains W1–W4); knk-plugin `main`.

## 1. Today's model (as found in the code)

### 1.1 How a node resolves

- `PermissionResolutionService` (knk-web-api `Services/PermissionResolutionService.cs`) walks the holder chain: the user's
  own grants first, then their groups (a member group before its parents, then weight). The **first holder with any
  matching grant decides**.
- Matching (`TryMatch`, line 61): an exact grant wins. A trailing `*` matches every node that starts with the text
  before it, and also the bare node (`knk.gate.*` matches `knk.gate`). Among wildcards, the longer prefix wins. A bare
  `*` matches everything, least specifically. Inside one holder, a deny beats a grant of the same specificity
  (`BestMatchAtHolder`, line 99).
- A **bare node is not a wildcard**: a grant of `knk.admin.content` does **not** match `knk.admin.content.delete`, and a
  grant of `knk.admin.delete` does **not** match `knk.admin.delete.bulk`. A grant of `knk.admin.delete.*` matches both
  `knk.admin.delete` and `knk.admin.delete.bulk`.
- Owner nodes in `OwnerPermissions.ExactGrantOnly` (`Attributes/OwnerPermissions.cs`) refuse wildcards (D24). The web
  app mirrors this with `EXACT_GRANT_OWNER_NODES` in `src/hooks/useStaffAccess.ts`.

### 1.2 API rules

- **Default-deny** (`Attributes/DefaultCallerRequiredFilter.cs`, global). Every MVC action needs the plugin key or a
  logged-in user unless it has `[AllowAnonymous]`. Every write (non-GET) also needs an explicit rule
  (`IKnkAccessRule`, `[Authorize]`), or it answers 403 "This endpoint has no access rule."
- **Reads are open to any logged-in user** unless an action has a stricter rule. This includes every dashboard list,
  POST search (`IsSearch`, line 81) and detail read.
- **`RequireServiceOrPermissionForWrites(node)`** (same file, line 123) is the class rule of the generic CRUD
  controllers. Its writes need the plugin key or a web user with `node`; reads and POST `…/search` stay open.
- Method attributes **add up** with the class rule. Both filters run, so a method rule on such a controller means
  "class node **and** method node". `UsersController` already relies on this, for example
  `[RequirePermission(ManageUsers)] [RequirePermission(UserGroups)]` on `DELETE {id}/groups/{groupId}`.
- **Nodes** (`Attributes/RequirePermissionAttribute.cs`, `StaffPermissions`):
  - `ManageContent = "knk.admin.content"` (line 98) and `ManageWorld = "knk.admin.world"` (line 103) come from D7.
  - Each one covers create, edit and delete alike. There is no separate delete node.
  - The only existing precedent for a delete node is `knk.admin.location.orphans.delete` (line 129, KNG-80: "Delete is
    its own, higher-privilege node").

| Area | Node | Controllers (class rule unless noted) |
|---|---|---|
| Content | `knk.admin.content` | BannerDesigns, BannerLayers, Categories, Clans, DisplayConfigurations, DisplayFields, DisplaySections, EnchantmentDefinitions, EntityTypeConfiguration, FieldValidationRules, FormConfigurations, FormFields, FormSteps, Grades, ItemBlueprints, MenuTemplates, MinecraftBlockRefs, MinecraftEnchantmentRefs, MinecraftMaterialRefs, Tags (`ForWrites`); FormSubmissionProgress (drafts) and MinecraftCatalog (`RequirePermission`, reads too) |
| World | `knk.admin.world` | Districts, DomainSubRegions, Domains, GateDoors, Locations, Streets, Structures, Towns, Workflows, WorldTasks (`ForWrites`); GateStructures (method `RequireServiceOrPermission`); Presence online-staff (`RequirePermission`) |
| Kits | `knk.kit.manage` (not under `knk.admin`) | Kits create/update/delete (method rules) |
| Lootboxes | `knk.admin.lootbox.manage` | LootboxTypes, LootboxSpecialEntries, LootboxSpawnAreas, LootboxTokenGrants, ItemInstances, LootboxConfiguration (`RequirePermission`, reads too) |
| Siege | `knk.siege.admin.manage` (not under `knk.admin`) | SiegeScenarios, SiegeTeams, SiegeLobbies, SiegeObjectives, SiegeSpawnpoints, SiegeConfiguration |
| Roads | `knk.admin.road` | RoadProfiles, RoadSeeds, RoadNodes, NavigationSettings |
| Players | `knk.admin.user.manage`; `knk.admin.user.perm` for groups and grants | Users (`DELETE {id}` is `RequireServiceOrPermission(ManageUsers)`, line 1381), PermissionGroups, PermissionGrants |

- **Tests that pin the rules:**
  - `Tests/.../Security/EndpointAccessRulesTests.cs` checks that every write has a rule and pins the `[AllowAnonymous]`
    allow-list.
  - `Tests/.../Api/RequireServiceOrPermissionAttributeTests.cs` `ProtectedRoutes` pins the exact node of named actions.
  - `Tests/.../Security/ForWritesSearchTests.cs` checks that POST search counts as a read.
- **The plugin** passes every `RequireServiceOrPermission*` rule with its key and is never node-checked. Its only DELETE
  calls (`knk-api-client` `RoadNetworkCommandApiImpl`, `DiscoveriesApiImpl`, `UserIgnoresApiImpl`,
  `UsersCommandApiImpl`) go to roads, discovery, ignores and user groups/grants, never to a dashboard type's delete.
- **Bulk:** no bulk delete endpoint exists. `GateDoors/{id}/snapshots/bulk` is a plugin write of block snapshots, not a
  delete.

### 1.3 Escalation guard

`Services/PermissionEscalationGuard.cs` applies to web users only; the plugin bypasses it in `EscalationGuardHttp`:

- **Granting, denying or revoking a node** (`CanGrantNodeAsync`, line 58) needs the actor to hold that node, resolved
  with wildcards. An Admin with `knk.admin.*` can therefore hand out any `knk.admin.<x>`, including new ones. Only a
  `*` holder may change their own permissions.
- **Adding someone to a group, or removing them** (`CanAssignGroupAsync`) needs two things:
  - the group ranks below the actor's highest group (Weight);
  - the actor holds every granted node in its parent chain. Denies don't count, and premium groups are exempt for
    holders of `knk.admin.user.group.premium`.
- **Making a group a parent** (`CanInheritFromGroupAsync`) needs the actor to hold every node of the parent chain.
- The guard has **no per-node exceptions** today. Any node is grantable by anyone who holds it.

### 1.4 Default groups and their nodes

Groups and grants come from seed migrations (knk-web-api `Migrations/`) and from the alpha database's hand seed. The
alpha seed holds holder ids 1–9:

- user 1 is the owner;
- 2 Noble, 3 Royal, 4 Dragon Blood;
- 5 Default;
- 6 Moderator, 7 Admin, 8 Staff;
- 9 Alpha Tester.

On the alpha, Staff → Moderator → Admin inherit from each other ([command permission scan](../../reports/2026-10-26-command-permission-scan.md) § 1, and
`SeedCommandPermissionNodes` doc comment).

| Group (weight) | Source | Nodes relevant here |
|---|---|---|
| Owner (user 1, no group) | alpha seed, roles § 8 | `*`. Everything, including future nodes. |
| Admin (100) | `SeedLocationRetentionStaffGroups`; alpha: `knk.admin.*` (roles § 8) | `knk.admin.*` on the alpha, so it holds `knk.admin.content`, `knk.admin.world` and any future `knk.admin.<x>`. Migrations alone give it only `knk.admin.location.*` (orphans, delete, run, retention, tp), `knk.admin.statistics.view`, `knk.admin.privacy.request`, `knk.admin.invites`, `knk.admin.item.more`, `knk.gamemode.*` and so on. **No migration seeds `knk.admin.content` or `knk.admin.world` to anyone.** |
| Moderator (50) | `SeedLocationRetentionStaffGroups`, `SeedStatisticsStaffNodes`, `SeedCommandPermissionNodes` | location orphans/keep/tp, `knk.admin.statistics.view`, `knk.gamemode.others`, `knk.fly.others`, … Neither area node. |
| Staff | alpha seed, `SeedCommandPermissionNodes` | `knk.admin.user.manage`, `knk.kit.manage`/`knk.kit.give`, `knk.siege.admin.*`, `knk.tasks`, `knk.admin.item`, … Neither area node (as far as the scan lists). It does hold `knk.kit.manage` and `knk.siege.admin.manage`, so Staff can already delete kits and siege setup through the API. |
| Default (0), Alpha Tester (1), Noble/Royal/Dragon Blood (premium) | `SeedDefaultPermissionGroup`, `SeedAlphaTesterGroup`, `AddUserFeaturesPhase5PremiumTiers` | player nodes only |

In practice, on the alpha **only the owner and Admin can use the dashboard and write content or world data**. Staff
can write kits and siege setup and can delete users (`knk.admin.user.manage`) through the API, but can't open the
dashboard.

### 1.5 Web app

- **Route table** (`src/routes/routeTable.ts` on `claude/admin-ia-30`, chain 2 W4, unmerged):
  - `dashboard`, `dashboardType`, `entitySetup*`, `entityEdit`, `entityDetail` and the builders all have
    `access: staff(CONTENT_PERMISSION_NODE)` (lines 122–137).
  - `RouteAccess` takes **one node** (`{ kind: 'staff'; node }`).
  - So world-only staff (`knk.admin.world` without `knk.admin.content`) can't open the dashboard, although the API
    would let them write world types.
- **`ObjectDashboard`** (`src/components/ObjectDashboard/ObjectDashboard.tsx` on X1):
  - the header shows "New {Type}" (line 381) for every known type;
  - every row gets View, Edit and Delete (`rowActions`, line 488);
  - nothing checks a node, and only View is disabled (no display configuration);
  - `handleDelete` (line 299) uses `FeedbackModal`, calls `getDeleteFunctionForEntity` (`src/utils/entityApiMapping.ts`
    line 283; it covers content, world, kits, lootboxes, siege, users and permission groups) and shows
    `apiRefusalReason` on failure;
  - the API's 403 is the only enforcement.
- **`PagedEntityTable`** has `selectionConfig` (row-click selection, used by the wizard pickers). It ignores `rowHref`
  while selecting (#205 note), so the dashboard needs a checkbox column instead.
- **`usePermission` / `usePermissions`** (`src/hooks/useStaffAccess.ts`):
  - they ask the API once per user and node per page load, sharing a cache (`permissionChecks`, line 53);
  - wildcards resolve on the server;
  - only `allowed`/`denied` is cached, and a rank change applies after a reload;
  - `usePermissions(nodes)` (line 132) answers several nodes at once, which the sidebar uses.

### 1.6 Realtime (X1, `claude/realtime-web-live-183`)

- `Realtime/RealtimeWebChangeMap.cs` turns one save into web `EntityChanged {type, id, op}` events for every
  `[FormConfigurableEntity]` type. Each event names a `WebNode`:
  - `DefaultNode = knk.admin.content` (line 32) for every dashboard type;
  - `knk.admin.user.manage` for users, memberships, grants and the audit log;
  - nothing for `NotSent` types (ledger, kit purchases and claims, item instances, ignores).
- A delete is just `op: "Deleted"`. More than `CollapseAbove = 50` of one type in one save becomes one event without an
  id.
- `Realtime/RealtimeWebAudience.cs` checks a receiver with the same `CheckAsync` as REST, cached 30 s
  (`WebPermissionCacheSeconds`). `RealtimeDispatchService` sends a node-gated message only to connections whose user
  holds the node.
- So the audience is **who may view**. Delete rights never change who gets an event.

## 2. Goals and the developer's wishes

From #280 and the #205 decisions of 2026-11-06:

1. **A thought-out system** that decides who may view the dashboard, create, edit, delete and bulk delete.
2. **Dedicated delete nodes:** `knk.admin.delete` for single deletes and `knk.admin.delete.bulk` for bulk delete.
   **Bulk delete is a separate permission from single delete.**
3. **Bulk delete is for owners and admins only.**
4. **Bulk delete leans towards all types.**
5. **Export** (#205): the table's columns in table order with the readable values. With nothing selected it exports the
   current search across all pages, keeping the sort. It needs **view access only**, so it can ship before this design
   (chain 3 V2).
6. **Existing grants keep working.** Seeds and migrations are additive only.
7. Enforced **in the API** (rules pinned by tests), **in the web app** (route table, buttons, bulk bar) and **in
   realtime**.

Not goals: changing the plugin's in-game permissions; gating API reads per area (see Q9); per-record ownership rules.

## 3. Alternative models

The actions are view, create, edit, delete one, bulk delete and export. In every model:

- view and export follow the dashboard gate;
- create and edit stay on the area node;
- the plugin keeps passing with its key.

**A — Global action nodes on top of the area nodes.**
- Delete one = area node **and** `knk.admin.delete`.
- Bulk delete = area node **and** `knk.admin.delete` **and** `knk.admin.delete.bulk`.
- The area keeps meaning "create and edit everything in this area". The two action nodes say *what kind* of write is
  allowed on top of that.

**B — Per-area action nodes.**
- Delete = `knk.admin.content.delete`, `knk.admin.world.delete`, `knk.kit.manage.delete`,
  `knk.siege.admin.manage.delete`, `knk.admin.lootbox.manage.delete`, … each with a `.bulk` child.
- The area node alone still means create and edit.

**C — Per-type nodes.**
- `knk.admin.entity.<type>.<view|create|edit|delete|delete.bulk>` for each of the roughly 40 dashboard types.
- The area nodes act as umbrellas through a resolver fallback, or are replaced.

| Criterion | A — global action nodes | B — per-area action nodes | C — per-type nodes |
|---|---|---|---|
| Matches the developer's names | Yes, exactly `knk.admin.delete` and `knk.admin.delete.bulk` | No, names per area | No |
| Backward compatibility | Area nodes keep create and edit. Delete needs one extra node; a backfill grants it to every explicit area holder, so nobody loses a delete | Same backfill, but per area (one node per area holder) | Needs a resolver change (area node implies its types) or a large backfill. The area nodes lose meaning |
| Ease of granting | 2 new nodes, one grant each | 2 × 7 areas = 14 new nodes | ~200 nodes; needs a picker UI that doesn't exist yet (KNG-62) |
| Expressiveness | "Deletes whatever they can edit". Can't say "delete world but not content" for someone who edits both | Delete per area | Everything per type |
| Escalation guard | Unchanged per node. One small rule for bulk (Q4) | Unchanged; the bulk rule is needed per area | Unchanged; huge group node sets make the "holds every node" group check slow and brittle |
| Wildcards | `knk.admin.*` (Admin) and `*` (owner) cover both. `knk.admin.delete.*` = single + bulk. Kits and siege are outside `knk.admin`, but the delete node is global, so that doesn't matter | `knk.admin.*` covers the `knk.admin.*` areas only. `knk.kit.manage.delete` and `knk.siege.admin.manage.delete` need `knk.kit.*` / `knk.siege.*`, so Admin would not get them | `knk.admin.entity.*` covers all; per-type wildcards work |
| Realtime audience | No change: the audience is "who may view" | No change | Natural per-type audience, but every type needs a node mapping |
| Web app checks | 3 nodes per screen (area, delete, bulk) | 3 nodes per area | Up to 5 per type |
| Cost | Small: attributes, one migration, one guard rule, one bulk endpoint | Medium | Large |

**A is the smallest model that meets every wish**, and it stays open to B later. A per-area delete node can be added
next to `knk.admin.delete` as an extra requirement without renaming anything, with the same AND pattern.

## 4. Recommended model (A)

### 4.1 Nodes

New constants in `StaffPermissions`:

| Constant | Node | Meaning | Matched by |
|---|---|---|---|
| `Delete` | `knk.admin.delete` | Delete **one** record of a dashboard type whose area node you hold | `knk.admin.delete.*`, `knk.admin.*`, `knk.*`, `*` |
| `DeleteBulk` | `knk.admin.delete.bulk` | Delete **several** records in one action (bulk bar); also needs `Delete` and the area node | `knk.admin.delete.*`, `knk.admin.*`, `knk.*`, `*` |

Unchanged:

- **Area nodes:** `knk.admin.content`, `knk.admin.world`, `knk.kit.manage`, `knk.admin.lootbox.manage`,
  `knk.siege.admin.manage`, `knk.admin.road`, and `knk.admin.user.manage`/`knk.admin.user.perm`. Each keeps meaning
  view, create and edit in its area.
- **No node for view, create, edit or export** beyond the area nodes (Q8, Q10).

The rules per action:

| Action | API rule | Web app shows it when the user holds |
|---|---|---|
| View (list, detail) | reads unchanged: any logged-in user (Q9) | the dashboard gate (Q8) and, per type, its area node |
| Export (CSV) | none of its own (existing reads) | view |
| Create, edit | area node (unchanged) | area node |
| Delete one | area node **and** `knk.admin.delete` | area + `knk.admin.delete` |
| Bulk delete | new bulk endpoint: `knk.admin.delete.bulk` **and** `knk.admin.delete` **and** each type's area node | area + delete + bulk |

### 4.2 Default group assignments

| Group | Delete one | Bulk delete | How |
|---|---|---|---|
| Owner (`*`) | yes | yes | wildcard, nothing to seed |
| Admin | yes | yes | `knk.admin.*` on the alpha. The migration also grants both nodes to `Admin` unless already covered (`GrantSql` skips covered nodes, so it's a no-op on the alpha and real on a migrations-only database) |
| Moderator | only where it holds an area node explicitly (backfill) | no | backfill, Q3 |
| Staff | yes for what it already deletes today (kits, siege setup, users), through the backfill, since it holds `knk.kit.manage`, `knk.siege.admin.manage` and `knk.admin.user.manage` explicitly | no | backfill, Q3 |
| Default, Alpha Tester, premium | no | no | — |
| Any user holding an area node directly | yes (backfill) | no | backfill |

A "content editor" or "builder" rank is not seeded (none exists). The developer creates it with `knk.admin.content` or
`knk.admin.world` and, if wanted, `knk.admin.delete`.

### 4.3 How existing grants keep working

- **Create and edit:** unchanged. The area node still gates them.
- **Single delete:** the migration's backfill gives `knk.admin.delete` to every holder (user or group) with an
  explicit, active, granted area node that a dashboard delete checks. A holder already covered by a wildcard or an
  explicit deny is skipped. So on day one everybody who can delete today still can. The developer then removes the
  node where they don't want it (Q3 option B skips the backfill instead).
- **Bulk delete:** new, so nobody loses anything. Only `*` and `knk.admin.*` get it, plus the explicit Admin grant.
- **Denies** work as usual:
  - a user-level `knk.admin.delete.bulk = false` beats a group's `knk.admin.*`, because the user is first in the chain;
  - inside the Admin group, an exact deny beats its own `knk.admin.*`, because it is more specific.
- **Plugin:** unchanged. `RequireServiceOrPermission` passes the key, and the plugin deletes no dashboard type.

### 4.4 Escalation guard

- No change for `knk.admin.delete`. Like any node, it can only be handed out by someone who holds it, never to oneself,
  and only in groups ranked below one's own.
- **`knk.admin.delete.bulk` gets one rule (Q4 recommendation B):** only a `*` holder may grant or deny it, or a wildcard
  that covers it (`knk.admin.delete.*`, `knk.admin.*`, `knk.*`). That keeps "owner and admin only" true: an Admin can't
  pass bulk delete to a Moderator.
  - **Side effect:** an Admin can no longer grant `knk.admin.*` to anyone. On today's alpha nobody but the owner does.
  - **Implementation:** `CanGrantNodeAsync` checks a short `OwnerGrantOnly` list, plus "a wildcard whose prefix covers
    a listed node".
  - `HoldsEveryGroupNodeAsync` needs no change. A group containing the node can only be assigned by someone who holds
    it, which is Admin (rank blocks peers) or the owner.

### 4.5 Migration and seed plan (additive only)

One data migration in knk-web-api, `SeedDashboardDeleteNodes`, built with `dotnet ef migrations add` and with no
schema change:

1. **Admin grants:** `GrantSql("Admin", "knk.admin.delete")` and `GrantSql("Admin", "knk.admin.delete.bulk")` (the
   helper from `SeedCommandPermissionNodes`). Each is skipped when Admin or an ancestor already has a grant, a deny or a
   covering wildcard.
2. **Backfill:** grant `knk.admin.delete` (value 1, no expiry) to every holder in `permission_grants` with an active
   grant (value 1, not expired) of `knk.admin.content`, `knk.admin.world`, `knk.kit.manage`,
   `knk.admin.lootbox.manage`, `knk.siege.admin.manage`, `knk.admin.road`, `knk.admin.user.manage` or
   `knk.admin.user.perm`.
   - Skip a holder that already has a grant or deny of `knk.admin.delete`, or a wildcard covering it.
   - A group's members inherit the grant through the group. Per Q5 the list is every area a dashboard delete checks.
3. **Down:** removes only the value-1, no-expiry `knk.admin.delete` / `knk.admin.delete.bulk` grants on the holders it
   could have touched. It never touches a deny, as the earlier seed migrations do. Like those, Down can't tell a grant
   it added from one added by hand afterwards with the same shape; this is documented in the migration comment.
4. **Tests:**
   - a unit test of the SQL shape, like `Tests/.../Migrations/SeedCommandPermissionNodesTests.cs`;
   - a `[MySqlFact]` like `MySql/SeedCommandPermissionNodesMySqlTests.cs` covering: alpha shape (`knk.admin.*` on
     Admin → no rows), migrations-only shape (rows on Admin), backfill on Staff and on a user with `knk.admin.world`,
     deny respected, idempotent re-run.

### 4.6 Enforcement points

**API (knk-web-api):**

- **Constants** `StaffPermissions.Delete` and `DeleteBulk`.
- **One registry,** `DashboardAccess` (new, e.g. `Attributes/DashboardAccess.cs`). It maps each dashboard type
  (`[FormConfigurableEntity]` with a delete endpoint) to its area node, whether single delete is allowed and whether
  bulk delete is allowed. Three places read it:
  - the bulk endpoint;
  - `RealtimeWebChangeMap.NodeFor` (if Q8 = B);
  - the metadata endpoint (`EntityMetadataDto` gains `accessNode`, `deletable`, `bulkDeletable`), so the web app learns
    each type's node instead of hard-coding it.
- **Single delete:** `[RequireServiceOrPermission(StaffPermissions.Delete)]` on the `[HttpDelete("{id}")]` action of
  every dashboard-type controller. Lootbox controllers use `RequirePermission`, since the plugin never calls them. The
  class or method area rule stays, so a delete is area AND delete.
  - **Content:** Categories, Tags, Grades, ItemBlueprints, EnchantmentDefinitions, BannerDesigns, BannerLayers, Clans,
    MinecraftBlockRefs, MinecraftMaterialRefs, MinecraftEnchantmentRefs.
  - **World:** Domains, Towns, Districts, Structures, Streets, Locations, GateStructures, GateDoors
    (`DELETE GateDoors/{id}` only), DomainSubRegions.
  - **Other areas:** Kits, LootboxTypes, LootboxSpecialEntries, LootboxSpawnAreas, SiegeScenarios, SiegeTeams,
    SiegeLobbies, SiegeObjectives, SiegeSpawnpoints, RoadProfiles; Users `DELETE {id}` and PermissionGroups
    `DELETE {id}` (Q5).
  - **Not covered** (they stay on their area node): builder parts (FormSteps, FormFields, DisplaySections,
    DisplayFields, FieldValidationRules), whole Form/Display configurations and MenuTemplates (edited in their builders,
    not on the dashboard), your own drafts (FormSubmissionProgress), WorldTasks and Workflows (lifecycle endpoints),
    plugin-only deletes, and link deletes (user groups, grants, gate snapshots).
- **Bulk delete** (Q7 = A): `POST api/Dashboard/bulk-delete` with `{ entityType, ids[] }`.
  - **Rules:** `[RequirePermission(DeleteBulk)]` and `[RequirePermission(Delete)]` (web users only). In code, the area
    node of `entityType` from `DashboardAccess` (403 when missing), and `bulkDeletable` (400 for an excluded type).
  - **Limits:** at most 100 ids; rate-limited like the lookup policy.
  - **Execution:** each id goes through the type's own service `DeleteAsync` in its own save, so the existing delete
    checks, dependents and `DeleteConstraintExceptionFilter` messages apply per row.
  - **Response:** `{ deleted: [id], refused: [{ id, reason }] }`.
  - **Audit:** one `AuditLogEntry` (actor, type, count, ids).
  - **Realtime:** one save per row, so N `EntityChanged` events. The web hook coalesces a burst into one refresh.
- **Tests:**
  - a new `Security/DeleteAccessRulesTests`:
    - every `HttpDelete` on a controller of a `DashboardAccess` type carries `Delete`;
    - every other `HttpDelete` is on a pinned exemption list;
    - the registry covers every `getDeleteFunctionForEntity` type (types listed by name);
  - `ProtectedRoutes` entries for the bulk endpoint and a sample per area;
  - `EndpointAccessRulesTests` stays green (the new endpoint has rules);
  - `PermissionEscalationGuardTests` for the bulk rule (Admin can't grant `knk.admin.delete.bulk` or `knk.admin.*`,
    owner can, Admin can grant `knk.admin.delete`);
  - bulk endpoint tests:
    - 403 without bulk, without delete, and without the area of the type;
    - 400 for an excluded type or more than 100 ids;
    - per-row refusal text;
    - the audit entry.

**Web app (knk-web-app):**

- **`useEntityAccess(type)`** (new hook on `usePermissions`) returns `{ view, create, edit, delete, bulkDelete, export }`
  from the type's `accessNode` (metadata), `knk.admin.delete` and `knk.admin.delete.bulk`. It is one cached check per
  node.
- **Route table** (Q8 = B):
  - `RouteAccess` gains `{ kind: 'staffAny'; nodes: string[] }`;
  - `dashboard`, `dashboardType` and `entityDetail` take the list of area nodes;
  - `entitySetup*` and the builders stay on `knk.admin.content`;
  - `SIDEBAR_NODES` and `TOP_NAV_NODES` read the list;
  - the type explorer lists only types whose area node is held.
- **Header:** "New {Type}" and "New with" are shown when `create` holds, else disabled with "Requires <node>" (Q11).
- **Row actions:** Edit as `edit`; Delete as `delete`, disabled with "Requires knk.admin.delete" or the area node.
  `handleDelete` moves to `useConfirm` with `danger` (W2), unchanged otherwise.
- **Selection and bulk bar:** V2 builds the checkbox column (rows stay links) and the bar with Export (`view`). This
  design adds "Delete (n)" to the bar only with `bulkDelete` and `bulkDeletable`; it is hidden otherwise.
  - The confirmation names the count and the type, with danger styling. A typed confirmation above 25 rows is an
    option in Q6.
  - It calls the bulk endpoint, lists `refused` with their reasons, keeps the refused rows selected and refreshes the
    table.
- **Export:** see § 4.7. There is no delete link.
- **Tests:**
  - `useEntityAccess` under each node combination;
  - the dashboard hides or disables New, Edit, Delete and the bulk Delete accordingly;
  - the route table's `staffAny` gate;
  - the explorer filter;
  - the bulk flow: confirm, partial refusal, refresh.

**Realtime:**

- Delete nodes change nothing: a `Deleted` event goes to whoever may view the type.
- If Q8 = B, `RealtimeWebChangeMap.NodeFor` returns the type's area node from `DashboardAccess` instead of
  `DefaultNode`. World-only staff then get world events and no content events, matching what their dashboard shows.
- Test: `RealtimeWebChangeMapTests` per area.
- The 30 s audience cache means a revoked view node stops events within 30 s (unchanged).

### 4.7 What export needs

- **Permission:** view of the type (developer, #205). There is no node of its own (Q10 = A), because the same data is
  already readable by any logged-in user through the API. The dashboard gate is what limits it in practice. User rows
  stay behind `knk.admin.user.manage` (their area).
- **Data:**
  - the table's columns in table order, with the readable values the table shows (same formatter);
  - selected rows, or with nothing selected the current search across all pages with its sort, fetched page by page
    from the existing POST `…/search`.
- **Limits:** a cap with a clear message (V2 decides; 10 000 rows is a reasonable default) and a cancel button while
  pages load.
- **No API change.** V2 can ship before this design is approved.
- **Optional later:** an audit entry per export would need a small API endpoint. Not proposed.

## 5. Implementation plan

Links run after the developer answers §7. Chain 3 V2 (export and checkbox column) does not wait for them.

| Link | Repo | What | Test points |
|---|---|---|---|
| AM1 | knk-web-api | Constants; `DashboardAccess` registry; `Delete` rule on every dashboard delete; migration `SeedDashboardDeleteNodes` (Admin + backfill); guard rule for bulk; metadata `accessNode`/`deletable`/`bulkDeletable`; `POST api/Dashboard/bulk-delete` with audit; realtime `NodeFor` per area (Q8 = B) | `DeleteAccessRulesTests`, `ProtectedRoutes`, `EndpointAccessRulesTests`, guard tests, migration SQL + `[MySqlFact]`, bulk endpoint tests, `RealtimeWebChangeMapTests`; full suite vs baseline (#99 reds) |
| AM2 | knk-web-app (on V2) | `useEntityAccess`; route table `staffAny` + explorer filter (Q8 = B); header and row actions by access; bulk Delete in V2's bar; `useConfirm` for delete; types from metadata | hook, dashboard, route-table, explorer and bulk-flow tests; `test:ci`, `tsc`, `CI=true` build, `lint:colors` not growing; themes `current`/`brand` |
| AM3 | knk-workspace | Living docs: web-api and web-app architecture (access model), admin guide for ranks (which node does what), smoke test `guides/dashboard-access-smoke-test.md`, CHANGELOG; this design's status | smoke test: Owner, Admin, Staff and a world-only user each try view/create/edit/delete/bulk; Admin can't grant bulk; deny on a user wins; backfill kept a Staff kit delete |

Deploy AM1 before or together with AM2. An old web app against the new API only sees more 403s on delete for holders
without the node; with the backfill there are none on day one.

## 6. Risks and notes

- **Users and permission groups on the dashboard:** today any holder of `knk.admin.user.manage` (Staff on the alpha)
  can delete a user account through the API, and the dashboard's mapping offers it. With Q5 = B that also needs
  `knk.admin.delete`, which the backfill gives to Staff. The developer may want to remove it from Staff afterwards.
- **Global delete node:** with A, someone who edits both content and world can delete both. If that's ever too coarse,
  add `knk.admin.delete.<area>` later as an extra AND (model B) without renaming.
- **Wildcard `knk.admin.delete.*`** means single + bulk, so it should only be granted by the owner (it falls under the
  Q4 rule).

## 7. Open questions for the developer

Each has a recommendation (**rec.**).

1. **Which model?**
   - A) global `knk.admin.delete` / `knk.admin.delete.bulk` on top of the area nodes (**rec.**);
   - B) per-area delete nodes (`knk.admin.content.delete`, …);
   - C) per-type nodes.
2. **Does bulk delete also need the single-delete node?**
   - A) yes: bulk = area + `knk.admin.delete` + `knk.admin.delete.bulk`, so a deny on delete also stops bulk (**rec.**);
   - B) no: bulk = area + `knk.admin.delete.bulk`.
3. **Who keeps single delete on day one?**
   - A) everyone who can delete today: backfill `knk.admin.delete` to every explicit area-node holder (**rec.**);
   - B) only owner and Admin (no backfill; Staff loses kit, siege and user deletes);
   - C) backfill to the Admin group only.
4. **Who may hand out `knk.admin.delete.bulk`?**
   - A) anyone who holds it (guard as today, so an Admin could give it to a Moderator);
   - B) only the owner (`*`), also for wildcards covering it such as `knk.admin.*` (**rec.**);
   - C) exact grant only (wildcards don't match it, like D24), seeded to Admin.
5. **Which deletes need `knk.admin.delete`?**
   - A) only content and world types;
   - B) every dashboard type, including kits, lootboxes, siege, roads, users and permission groups (**rec.**);
   - C) B without users and permission groups (they keep their own rules).
6. **Which types allow bulk delete?**
   - A) all dashboard types;
   - B) all except users and permission groups (**rec.**);
   - C) only leaf types without dependents;
   - D) A or B, plus a typed confirmation above 25 rows.
7. **How is bulk delete enforced?**
   - A) a new API endpoint that checks `knk.admin.delete.bulk`, max 100 ids, per-row results, one audit entry (**rec.**);
   - B) the web app sends one delete per row, so the bulk node is only checked in the UI.
8. **Who may open the dashboard?**
   - A) holders of `knk.admin.content`, as today;
   - B) holders of any area node; each sees only their area's types, and live updates follow the area (**rec.**);
   - C) a new `knk.admin.dashboard` node, seeded to holders of `knk.admin.content`.
9. **Should API reads (lists, details) be gated per area too?**
   - A) no, they stay "any logged-in user"; the dashboard gate is in the UI (**rec.**; the wizard pickers read across
     areas);
   - B) yes, every GET needs the area node, which needs a separate audit of the pickers and the plugin.
10. **Does export get its own node?**
    - A) no, export follows view (**rec.**, as decided for #205);
    - B) `knk.admin.export` for all types;
    - C) `knk.admin.export` only for user rows.
11. **Buttons for an action you may not do:**
    - A) hide them;
    - B) show New, Edit and Delete disabled with "Requires <node>", and hide the bulk Delete (**rec.**; like View
      without a display);
    - C) disable everything, bulk Delete included.
