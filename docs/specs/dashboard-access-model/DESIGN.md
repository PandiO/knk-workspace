# Dashboard access model — view, create, edit, delete, bulk delete and export

**Status:** **Implemented** — decided 2026-11-08 (record in § 7), built in chain 3 links AM1–AM4 and merged:
AM1+AM2 (API) into knk-web-api `master` `bc97b7d` on 2026-11-12, AM3 (web app, the LV7-8 change of § 4.7, #205 bulk
delete) into knk-web-app `main` `e02ee79` and knk-web-api `master` `45043a7` on 2026-11-13 (the developer accepted it
directly into trunk; `next` fast-forwarded). AM4 (docs) done 2026-11-13 in the documentation issue
[#366](https://github.com/PandiO/knk-workspace/issues/366). **Not live-tested:** the
[smoke test](../../guides/dashboard-access-smoke-test.md) is in closed alpha test run 2 (checklist § 4c). As built:
[web-api architecture § 5.1](../../architecture/web-api-architecture.md#51-dashboard-access-model-pandioknk-workspace280-am1-merged-2026-11-12-am3-2026-11-13),
[§ 5.2](../../architecture/web-api-architecture.md#52-read-gating-per-area-and-lookups-pandioknk-workspace280-am2-merged-2026-11-12),
[web-app architecture](../../architecture/web-app-architecture.md#dashboard-access-model-in-the-web-app-pandioknk-workspace280-am3-205-bulk-delete);
admin view: [dashboard access admin guide](../../guides/admin/dashboard-access-admin-guide.md). **AM3's deviation LAM3-1
is reverted** (developer 2026-11-13, [#371](https://github.com/PandiO/knk-workspace/issues/371), knk-web-app branch
`claude/form-wizard-content-only-371`, not merged): the form wizard routes `/forms/:type` and `/forms/:type/edit/:id`
are back on `knk.admin.content` as § 4.3 has it, and in the web app create and edit of every type also need
`knk.admin.content` (§ 7). **#374** (developer 2026-11-13, knk-web-api and knk-web-app branches
`claude/api-writes-need-content-374`, not merged): the API asks for `knk.admin.content` on create, edit and link changes
too (§ 4.3, § 7). Answers [#368](https://github.com/PandiO/knk-workspace/issues/368). Known gaps: #352 (material picker in world/lootbox forms),
#353 (top bar Create New per area), #369 (Permission Group's list needs `knk.admin.user.perm`). Developer 2026-11-08:
the backfill (§ 4.5) **skips the Staff group**, and nobody changes a group ranked at or above their own (§ 4.4).
**Last updated:** 2026-11-13 (the API asks for `knk.admin.content` on create, edit and link changes, § 4.3, § 4.7,
§ 7, #374); 2026-11-13 (LAM3-1 reverted, § 7, #371); 2026-11-13 (status: implemented and merged, AM4 docs, LAM3-1 deviation #368; docs #366); 2026-11-12 (AM3 built; § 4.7 form/display configuration deletes need `knk.admin.delete`, developer
decision on LV7-8; § 7 addendum); 2026-11-12 (AM1+AM2 merged); 2026-11-08 (AM2 built); 2026-11-08 (AM1 built, Staff decision); 2026-11-08 (decided version, with read gating per area, `knk.admin.export` and the read-endpoint
appendix); 2026-11-08 (first version, chain 3 link D1)
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

## 2. Goals and decisions

### 2.1 What the developer asked for

From #280 and the #205 decisions of 2026-11-06:

1. **A thought-out system** that decides who may view the dashboard, create, edit, delete and bulk delete.
2. **Dedicated delete nodes:** `knk.admin.delete` for single deletes and `knk.admin.delete.bulk` for bulk delete.
   **Bulk delete is a separate permission from single delete.**
3. **Bulk delete is for owners and admins only.**
4. **Bulk delete leans towards all types.**
5. **Export** (#205): the table's columns in table order with the readable values. With nothing selected it exports the
   current search across all pages, keeping the sort.
6. **Existing grants keep working.** Seeds and migrations are additive only.
7. Enforced **in the API** (rules pinned by tests), **in the web app** (route table, buttons, bulk bar) and **in
   realtime**.

### 2.2 Decisions of 2026-11-08

| # | Decision |
|---|---|
| 1 | Model A: global `knk.admin.delete` / `knk.admin.delete.bulk` on top of the area nodes. |
| 2 | Bulk delete needs the area node, `knk.admin.delete` and `knk.admin.delete.bulk`. |
| 3 | `knk.admin.delete` is backfilled to every explicit area-node holder (additive migration). |
| 4 | Only the owner (`*`) may grant `knk.admin.delete.bulk`, also through wildcards that cover it. |
| 5 | Every dashboard type needs `knk.admin.delete` to delete, users and permission groups included. |
| 6 | Bulk delete is allowed for every type except users and permission groups. |
| 7 | Bulk delete has its own endpoint, `POST api/Dashboard/bulk-delete`: at most 100 ids, a result per row, one audit entry. |
| 8 | Any area node opens the dashboard. Each user sees only their area's types, and live updates follow the same rule. |
| 9 | **Every API read (lists and details) of a dashboard type needs its area node.** The proposal had recommended keeping reads open. |
| 10 | **A new node, `knk.admin.export`, is needed to export any type.** The proposal had recommended no node. |
| 11 | An action the user may not do: New, Edit and Delete show disabled with "Requires <node>"; the bulk Delete button is hidden. |

Not goals: changing the plugin's in-game permissions; per-record ownership rules beyond the existing ones (drafts,
world tasks, workflow sessions).

## 3. Alternative models (A chosen, decision 1)

The actions are view, create, edit, delete one, bulk delete and export. In every model:

- view, create and edit stay on the area node (view became gated per area by decision 9, § 4.6);
- export got its own node by decision 10 (§ 4.8), which works the same in every model;
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
| Escalation guard | Unchanged per node. One small rule for bulk (decision 4) | Unchanged; the bulk rule is needed per area | Unchanged; huge group node sets make the "holds every node" group check slow and brittle |
| Wildcards | `knk.admin.*` (Admin) and `*` (owner) cover both. `knk.admin.delete.*` = single + bulk. Kits and siege are outside `knk.admin`, but the delete node is global, so that doesn't matter | `knk.admin.*` covers the `knk.admin.*` areas only. `knk.kit.manage.delete` and `knk.siege.admin.manage.delete` need `knk.kit.*` / `knk.siege.*`, so Admin would not get them | `knk.admin.entity.*` covers all; per-type wildcards work |
| Realtime audience | No change: the audience is "who may view" | No change | Natural per-type audience, but every type needs a node mapping |
| Web app checks | 3 nodes per screen (area, delete, bulk) | 3 nodes per area | Up to 5 per type |
| Cost | Small: attributes, one migration, one guard rule, one bulk endpoint | Medium | Large |

Model A was chosen (decision 1). It is the smallest model that meets every wish, and it stays open to B later: a
per-area delete node can be added next to `knk.admin.delete` as an extra requirement, without renaming anything, by
the same AND pattern.

## 4. Decided model

### 4.1 Nodes

New constants in `StaffPermissions`:

| Constant | Node | Meaning | Matched by |
|---|---|---|---|
| `Delete` | `knk.admin.delete` | Delete **one** record of a dashboard type whose area node you hold | `knk.admin.delete.*`, `knk.admin.*`, `knk.*`, `*` |
| `DeleteBulk` | `knk.admin.delete.bulk` | Delete **several** records in one action; also needs `Delete` and the area node. **Only the owner hands it out** (§ 4.4) | `knk.admin.delete.*`, `knk.admin.*`, `knk.*`, `*` |
| `Export` | `knk.admin.export` | Export rows of a dashboard type whose area node you hold (§ 4.8) | `knk.admin.*`, `knk.*`, `*` |

The area nodes are unchanged. Each one now means **view**, create and edit in its area; view is new (decision 9):
`knk.admin.content`, `knk.admin.world`, `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`,
`knk.admin.road`, `knk.admin.user.manage` (users and viewing permission groups) and `knk.admin.user.perm` (permission
group writes).

### 4.2 One registry: `DashboardAccess`

A new static registry in knk-web-api (for example `Attributes/DashboardAccess.cs`) is the single source of truth. It
has one entry per `[FormConfigurableEntity]` type, holding:

- **area** and **area node:** view, create, edit, and the realtime audience;
- **read nodes:** the area node plus the "consumer" page nodes of § 4.6.2;
- **deletable** and **bulk deletable;**
- **delegates to the type's own services:** search, get by id, delete, and a label selector (`Name`, `DisplayName`,
  `Username`, `Key`, …).

| Area | Area node | Types (dashboard) | Bulk delete |
|---|---|---|---|
| Content | `knk.admin.content` | Category, Tag, Grade, ItemBlueprint, EnchantmentDefinition, BannerDesign, BannerLayer, Clan, MinecraftBlockRef, MinecraftMaterialRef, MinecraftEnchantmentRef | yes |
| World | `knk.admin.world` | Domain, Town, District, Structure, Street, Location, GateStructure, GateDoor, DomainSubRegion | yes |
| Kits | `knk.kit.manage` | Kit | yes |
| Lootboxes | `knk.admin.lootbox.manage` | LootboxType, LootboxSpecialEntry, LootboxSpawnArea | yes |
| Siege | `knk.siege.admin.manage` | SiegeScenario, SiegeTeam, SiegeLobby, SiegeObjective, SiegeSpawnpoint | yes |
| Roads | `knk.admin.road` | RoadProfile | yes |
| Players | `knk.admin.user.manage` (write of groups: `knk.admin.user.perm`) | User, PermissionGroup | **no** (decision 6) |

- **Other `[FormConfigurableEntity]` types** (link rows such as CategoryTag, snapshots, ledger and audit rows,
  SiegeMatch, …) also get an entry with their area, so that the explorer and realtime have an area for them. They are
  marked view-only (`deletable: false`).
- **Three places use the registry:** the bulk-delete, export and lookup endpoints; `RealtimeWebChangeMap.NodeFor`; and
  the metadata endpoint. `EntityMetadataDto` gains `area`, `accessNode`, `readNodes`, `deletable` and `bulkDeletable`,
  so the web app never hard-codes a node per type.
- **A test** checks that every `[FormConfigurableEntity]` type is in the registry (or on a pinned internal list), and
  that every type `getDeleteFunctionForEntity` handles is `deletable`.

### 4.3 Rules per action

| Action | API rule (web users; the plugin passes with its key unless noted) | Web app |
|---|---|---|
| Open the dashboard | — (UI only) | route open to holders of **any** area node; the explorer lists only types whose area node is held (decision 8) |
| View (list, search, detail) | the type's **read nodes** (§ 4.6) | shown for its area's types |
| Pick or label another type (pickers, relation labels) | **lookup** endpoints: any area node (§ 4.6.3) | lookup mode when the full read isn't allowed |
| Create, edit | the type's **change nodes**: write node **and** `knk.admin.content` (#374, § 7); User, Permission Group and RoadProfile: write node only | New / New with / Edit disabled with "Requires <node>" without them (#371) |
| Change a link (detail page Select / Unlink / Add) | the owner's change nodes, plus the related type's when the related row changes (#374) | disabled with "Requires <node>" without them |
| Delete one | area node **and** `knk.admin.delete` | Delete disabled with "Requires knk.admin.delete" (or the area node) |
| Bulk delete | `POST api/Dashboard/bulk-delete`: `knk.admin.delete.bulk` **and** `knk.admin.delete` **and** the type's area node; web users only | "Delete (n)" in the selection bar, **hidden** without all three or for users/groups |
| Export | `POST api/Dashboard/export`: `knk.admin.export` **and** the type's area node; web users only | Export in the selection bar, disabled with "Requires knk.admin.export" |

### 4.4 Groups, grants and the escalation guard

**Default assignments** (all additive, § 4.5):

| Group | Delete one | Bulk delete | Export | How |
|---|---|---|---|---|
| Owner (`*`) | yes | yes | yes | wildcard |
| Admin | yes | yes | yes | `knk.admin.*` on the alpha. Plus an explicit grant of all three where it isn't covered (a migrations-only database) |
| Every holder of an explicit area node (groups and users: Staff, any content/world rank, …) | yes (backfill, decision 3) | no | yes (backfill, like decision 3) | migration |
| Moderator, Default, Alpha Tester, premium | only through an explicit area node | no | same | — |

**Guard rule for bulk delete** (decision 4), in `PermissionEscalationGuard`:

- **New list.** `OwnerGrantOnly = { "knk.admin.delete.bulk" }`. A node is *covered* when it equals a listed node, or is
  a wildcard that matches one by `TryMatch` rules (`*`, `knk.*`, `knk.admin.*`, `knk.admin.delete.*`, …).
- **Granting.** `CanGrantNodeAsync`: granting, denying or revoking a covered node needs `*`. The message is "Only the
  owner can hand out bulk delete."
- **Groups.** `CanAssignGroupAsync` and `CanInheritFromGroupAsync` need `*` when the group's parent chain grants a
  covered node. Otherwise a group made by the owner could carry bulk delete to people an Admin picks.
- **Effect on Admins.** An Admin can no longer grant `knk.admin.*`, `knk.admin.delete.*` or `knk.*`, nor assign a group
  that carries them. Assigning such a group was already blocked by rank for the Admin group itself. `knk.admin.delete`
  and `knk.admin.export` stay grantable by anyone who holds them, as every node is today.
- **The plugin** is not guard-checked (unchanged). The in-game `/knk user perm` checks its own nodes.

**Denies work as usual.** A user-level `knk.admin.delete.bulk = false` beats a group's `knk.admin.*`, because the user
comes first in the chain. An exact deny inside the Admin group beats its own `knk.admin.*`, because it is more
specific.

### 4.5 Migration and seed (additive only)

One data migration in knk-web-api, `SeedDashboardActionNodes`, made with `dotnet ef migrations add`. It changes no
schema.

1. **Admin:**
   - `GrantSql("Admin", node)` for `knk.admin.delete`, `knk.admin.delete.bulk` and `knk.admin.export`, using the helper
     from `SeedCommandPermissionNodes`.
   - Each grant is skipped when Admin or an ancestor already has a grant, a deny or a covering wildcard. On the alpha
     that means all three are skipped (`knk.admin.*`).
2. **Backfill:**
   - **Who:** every holder (user or group) with an active, explicit grant (value 1, not expired) of `knk.admin.content`,
     `knk.admin.world`, `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`, `knk.admin.road`,
     `knk.admin.user.manage` or `knk.admin.user.perm`.
   - **What:** `knk.admin.delete` and `knk.admin.export`, each value 1 with no expiry.
   - **Skipped:** a holder (or an ancestor group) that already has a grant or deny of the node, or a covering wildcard.
   - **Not backfilled:** `knk.admin.delete.bulk`. Nobody loses anything, because it's new.
3. **Down:** removes only value-1, no-expiry grants of the three nodes on the holders it could have touched. It never
   touches a deny. Like the earlier seed migrations, Down can't tell its own grant from an identical one added by hand
   later; the migration comment says so.
4. **Effect on the alpha:**
   - **Admin:** nothing changes (wildcard).
   - **Staff:** ~~gets `knk.admin.delete` and `knk.admin.export`~~ — **skipped (developer, 2026-11-08):** Staff keeps
     balance changes, freeze, kick and ban, but gets no delete (and no export from the backfill). It therefore stops
     deleting kits, siege setup, road profiles and users after the deploy, unless a Staff member holds an area node
     themselves.
   - **Owner:** nothing changes.

### 4.6 Read gating per area (decision 9)

#### 4.6.1 What changes

- **Before:** every read of a dashboard type was open to any logged-in user (default rule).
- **After:**
  - **Full reads** (`GET` list and detail, sub-resource `GET`s and `POST …/search`) need one of the type's **read
    nodes**, or the plugin's key.
  - **Lookups** (§ 4.6.3) and **form runtime** reads (§ 4.6.4) need **any area node**.
  - **Public, plugin-only and self** reads keep their rules.
- **The categories, per endpoint, are in Appendix A:**

| Category | Rule | Examples |
|---|---|---|
| **F** full read | the type's read nodes or the plugin key | `GET api/Towns`, `GET api/ItemBlueprints/{id}`, `POST api/Domains/search` |
| **L** lookup | any area node or the plugin key | new `POST api/Lookup/{type}/search`, `GET api/Lookup/{type}/{id}`; `GET api/Clans/default-for-town/{townId}` |
| **R** form runtime | any area node or the plugin key | form/display configurations, metadata, entity type configuration, validation rules and their `validate`/`resolve` POSTs, banner pattern keys |
| **O** own records | any area node + the existing ownership check | drafts (`FormSubmissionProgress`), workflow sessions, `WorldTasks/active-for-me`, a task by its session |
| **P** public | `[AllowAnonymous]`, unchanged | `EnchantmentDefinitions/public/info`, Leaderboards, Players, SiegeMatches, Auth, Health, invitation and claim checks, `validate-link-code`, `check-duplicate` |
| **G** game server | `RequirePluginService`, unchanged | `WorldTasks/open`, kit claim/purchase, lootbox spawn and token writes |
| **U** already stricter | the action's own rule, unchanged | Lootbox reads (`knk.admin.lootbox.manage`), user and permission group reads (`knk.admin.user.manage` or self) |

- **Self reads stay as they are:**
  - `GET api/Users/{id}` and `…/permissions/check|effective` stay `RequireServiceSelfOrPermission(ManageUsers)`, which
    the web app's `AuthContext` and `usePermission` depend on;
  - currency, data deletion and title brackets aren't dashboard types and keep their own rules.
- **Player summaries.** `GET api/Users/uuid/{uuid}` and `username/{username}` (public view, no email) become **F** with
  `knk.admin.user.manage`, or the plugin key. The web app doesn't call them: player-facing pages use the anonymous
  `PlayersController`.
- **Player-facing web pages read no dashboard type.** Checked in knk-web-app `src/pages/{account,guides,leaderboards,players,siege}`,
  `AccountManagementPage`, `AccountTransactionsPage` and `LandingPage`: they use the anonymous controllers, the
  currency controller and auth. The enchantment guide uses `public/info`.

#### 4.6.2 Read nodes: who else may read a type in full

Some admin pages outside an area read another area's records in full. They keep working because their own page node is
added to the type's read nodes. These are reads only; writes stay on the area node.

| Types | Area node | Also readable with | Why (knk-web-app) |
|---|---|---|---|
| Location, Town, District, Structure | `knk.admin.world` | `knk.admin.config` | Game settings builds spawn and hub options from all four lists (`pages/admin/GameSettingsPage.tsx`, `components/admin/gameSettings/locationReferenceOptions.ts`) |
| Domain | `knk.admin.world` | `knk.admin.discovery` | discovery overrides list domains (`components/admin/discovery/DiscoveryOverridesCard.tsx`) |
| Town, Street | `knk.admin.world` | `knk.admin.road` | road profiles and edges (`components/admin/roads/RoadProfilesCard.tsx`, `RoadEdgesCard.tsx`) |
| MinecraftMaterialRef | `knk.admin.content` | `knk.admin.road` | road material input (`components/admin/roads/MaterialKeyInput.tsx`) |
| ItemBlueprint, EnchantmentDefinition, Category, Grade | `knk.admin.content` | `knk.kit.manage`, `knk.admin.lootbox.manage` | kit contents and lootbox pools show items, enchantments and grades (`FormWizard.tsx` item and enchantment search, `components/lootbox/LootboxDropLogTab.tsx`, `CategoryFilterSelect.tsx`) |
| Kit | `knk.kit.manage` | `knk.admin.lootbox.manage`, `knk.admin.user.manage` | lootbox token tab; the player profile's "available kits" (`LootboxTokensTab.tsx`, `pages/admin/PlayerProfilePage.tsx`) |
| every other type | its area node | — | — |

- **What stays blocked:** a page that already writes another area's type keeps needing that area's write node. For
  example, creating a street from the road edges card needs `knk.admin.world`, as it does today.
- **Rule for later:** a new cross-area page adds its node here and to Appendix A. The read-rules test (§ 4.7) pins the
  list.

#### 4.6.3 Pickers and labels across areas

The developer asked how a picker that references another area's type should behave. **Decided: minimal lookups for any
staff.** A picker never needs another area's full records, and requiring every area's node would make a world builder
also need `knk.admin.content` just to pick a Clan.

- **Endpoints (category L):**
  - `POST api/Lookup/{entityType}/search` takes `{ searchTerm, page, pageSize ≤ 50 }` and returns
    `{ items: [{ id, label, detail? }], total }`.
  - `GET api/Lookup/{entityType}/{id}` returns `{ id, label, detail? }`.
  - Both are implemented once, through the registry's search and label delegates.
  - `detail` is one short, non-sensitive line (a domain's parent, a location's world and coordinates); users get their
    username only, never an email.
- **Who:** holders of any area node, or the plugin. The entity type must be in the registry; unknown types return 404.
- **Web app:**
  - **Pickers:** when the user holds a read node of the related type, the picker works as today (full table, filters).
    Otherwise it switches to **lookup mode**: a search box and a Name column, with no filters.
  - **"Create new" from a picker** is shown only with that type's create (area) node.
  - **Labels:** `useEntityLabel`, the wizard's related-entity fetch for join entries (`FormWizard.tsx`, around line
    2319) and the display wizard's related values fall back to `GET api/Lookup/{type}/{id}` without a full read. The
    link to the detail page shows only with that area's node.
- **Not a follow-up question:** decided as above.

#### 4.6.4 Form runtime reads, drafts and own records

The wizard and the display pages need these reads for every type a user may edit, so they are open to **any area
node** (category R/O), not only `knk.admin.content`:

- **Configurations:** `FormConfigurations`, `DisplayConfigurations`, `FormSteps`, `FormFields`, `DisplaySections`,
  `DisplayFields`, `EntityTypeConfiguration` GETs, and `Metadata`.
- **Validation and resolution POSTs:** `FieldValidationRules` `validate`, `validate-batch`, `resolve-placeholders`,
  `resolve-dependencies`, `validate-path`, `health-check/configuration/draft` and `api/field-validations/validate-field`.
  - **Today** these POSTs count as writes under the class rule `ForWrites(knk.admin.content)`. So a world-only user
    already gets 403 on validation.
  - **Change:** they get an explicit "any area node" rule, and `RequireServiceOrPermissionForWritesFilter` skips actions
    that carry it.
- **Drafts:** `FormSubmissionProgress`, today `RequirePermission(knk.admin.content)` on the whole controller, becomes
  any area node. Ownership stays as it is (#186: drafts are the caller's).
- **World-task and workflow reads of your own:** `WorldTasks` `active-for-me`, `session/{id}`, `session/{id}/open`,
  `by-link-code` and `{id}`, and `Workflows` `{id}`, `by-guid`, `{id}/progress`. A lootbox manager drawing a spawn area
  in game reads their own task. The by-status and search lists stay **F** (`knk.admin.world`).
- **Builder writes stay `knk.admin.content`:** configurations, steps, fields, validation rules, import and seeds.

#### 4.6.5 How it's built

- **Class attribute.** A new `[DashboardReads("<TypeName>")]` (an `IKnkAccessRule`) on each dashboard-type controller.
  - It reads the type's read nodes from the registry.
  - It gates GET/HEAD and POST search (`IsSearch`), lets the plugin key pass, and passes any action that carries
    `[AllowAnonymous]`, `RequirePluginService`, a stricter rule, or one of the method attributes below.
- **Method attributes:**
  - `[RequireServiceOrAnyAreaNode]` for categories L and R;
  - `[RequireServiceOrAnyAreaNode(OwnRecords = true)]` for category O. The ownership check stays inside the action.
- **`PermissionResolutionService.CheckAnyAsync(userId, nodes)`** builds the holder chain once and returns the first
  allowed node.
- **Read check cache.**
  - A per-request memo, plus a 30 s per-(user, node) memory cache for **read** checks only, like
    `RealtimeWebAudience`.
  - Writes stay uncached.
  - The cache drops a user's entries when their grants, memberships or a group's grants change, at the same service
    calls that already publish S2's `UserPermissionsChanged` / `PermissionGroupChanged`.
  - A revoked read therefore stops within 30 s at most, and immediately when the change goes through those services.

### 4.7 Enforcement points

**API (knk-web-api):**

- **Constants:** `Delete`, `DeleteBulk`, `Export`; the `DashboardAccess` registry; metadata fields (§ 4.2).
- **Create and edit (#374):** `DashboardTypeAccess.ChangeNodes` = the write node and `knk.admin.content`
  (`ChangesNeedContent`, off for User, PermissionGroup, PermissionHolder, the Players link rows and RoadProfile).
  `[RequireDashboardChange("<Type>")]` on the primary create and update action of every other type checks all of them
  (the plugin key passes; 403 `NoWriteAccess` with `nodes`), next to the class or method area rule. Pinned in
  `Security/DashboardChangeAccessRulesTests`. The metadata's `actionNodes.create`/`edit` and the relationship
  descriptors' `nodes` (`RelationshipService`, enforced by `RequireRelationshipWrite`) use the same list. Other writes
  of a type (gate door state and health, a domain's world backfill, gate overrides, plugin-only endpoints) keep their
  rules.
- **Single delete:** `[RequireServiceOrPermission(StaffPermissions.Delete)]` (lootbox controllers: `RequirePermission`)
  on the primary `DELETE {id}` of every registry type that is `deletable`. The class or method area rule stays, so a
  delete is area AND delete.
  - **Content:** Categories, Tags, Grades, ItemBlueprints, EnchantmentDefinitions, BannerDesigns, BannerLayers, Clans,
    MinecraftBlockRefs, MinecraftMaterialRefs, MinecraftEnchantmentRefs.
  - **World:** Domains, Towns, Districts, Structures, Streets, Locations, GateStructures, `DELETE GateDoors/{id}`,
    DomainSubRegions.
  - **Other areas:** Kits, LootboxTypes, LootboxSpecialEntries, LootboxSpawnAreas, SiegeScenarios, SiegeTeams,
    SiegeLobbies, SiegeObjectives, SiegeSpawnpoints, RoadProfiles; `DELETE api/Users/{id}`,
    `DELETE api/PermissionGroups/{id}` (decision 5).
  - **Whole form and display configurations** (developer 2026-11-12, LV7-8 of #71): `DELETE api/FormConfigurations/{id}`
    and `DELETE api/DisplayConfigurations/{id}` also need `knk.admin.delete`, on top of `knk.admin.content`. Pinned in
    `DeleteAccessRulesTests.ConfigurationDeletes`; Entity setup shows their Delete disabled with "Requires …" (AM3).
  - **Not covered** (they keep their rules): builder parts (steps, fields, sections, validation rules), MenuTemplates, your own
    drafts, world-task and workflow lifecycle endpoints, plugin-only deletes, and link deletes (user groups, grants, gate
    snapshots).
- **Bulk delete:** `POST api/Dashboard/bulk-delete` with `{ entityType, ids[] }` (decision 7).
  - **Rules:** `[RequirePermission(DeleteBulk)]` and `[RequirePermission(Delete)]` on the action. In code: the type's
    area node (403), `bulkDeletable` (400 for users and groups), and at most 100 distinct ids (400).
  - **Execution:** each id goes through the type's own `DeleteAsync` in its own save, so dependents and
    `DeleteConstraintExceptionFilter` messages apply per row.
  - **Response:** `{ deleted: [id], refused: [{ id, reason }] }`.
  - **Audit:** one `AuditLogEntry` (actor, type, count, ids, refused count).
  - **Rate limit:** the lookup policy.
- **Export:** `POST api/Dashboard/export`, see § 4.8.
- **Read gating:** § 4.6.5 on every controller in Appendix A; lookup endpoints `api/Lookup/...`.
- **Guard:** the `OwnerGrantOnly` rule (§ 4.4).
- **Realtime:** `RealtimeWebChangeMap.NodeFor(type)` returns the registry's **area node** instead of
  `DefaultNode = knk.admin.content` (decision 8). `NotSent` and the user-managed types are unchanged.
  - Delete nodes don't change the audience: a `Deleted` event goes to whoever may view the type.
  - A bulk delete is one save per row, so N events. The web hook coalesces them into one refresh.
- **Tests:**
  - **`Security/DeleteAccessRulesTests`:**
    - every `HttpDelete` of a deletable registry type carries `Delete`;
    - every other `HttpDelete` is on a pinned exemption list;
    - registry coverage.
  - **`Security/ReadAccessRulesTests`:**
    - every GET/HEAD and POST-search action of a registry controller is in exactly one category of § 4.6.1, pinned
      like the anonymous allow-list;
    - behaviour: a world-only user gets 403 on `GET api/ItemBlueprints` and 200 on
      `POST api/Lookup/ItemBlueprint/search`; a config-only user gets 200 on `GET api/Locations`; the plugin key gets
      200 everywhere; anonymous stays 401.
  - **Existing suites:** `ProtectedRoutes` entries for the new endpoints and a sample per area; `EndpointAccessRulesTests`
    green; `ForWritesSearchTests` extended to the runtime POSTs.
  - **`PermissionEscalationGuardTests`:**
    - an Admin can't grant or deny `knk.admin.delete.bulk`, `knk.admin.delete.*` or `knk.admin.*`;
    - an Admin can't assign a group that carries them;
    - the owner can do all of these;
    - an Admin can grant `knk.admin.delete` and `knk.admin.export`.
  - **Migration:** SQL-shape unit tests and a `[MySqlFact]` like `SeedCommandPermissionNodes*Tests` (alpha shape → no
    Admin rows; migrations-only shape → Admin rows; backfill on Staff and on a user with `knk.admin.world`; deny
    respected; idempotent).
  - **Bulk and export endpoint tests:** each missing node → 403; excluded type → 400; more than 100 ids → 400; per-row
    refusal text; cap; audit entries.
  - **`RealtimeWebChangeMapTests`:** per area.
  - **`PermissionResolutionService.CheckAnyAsync`** and the read cache, including invalidation.

**Web app (knk-web-app):**

- **`useEntityAccess(type)`.** A new hook on `usePermissions` that returns
  `{ view, read, create, edit, delete, bulkDelete, export }`.
  - It reads the type's `accessNode`, `readNodes`, `deletable` and `bulkDeletable` from metadata, plus
    `knk.admin.delete`, `knk.admin.delete.bulk` and `knk.admin.export`.
  - It makes one cached check per node.
- **Route table (`src/routes/routeTable.ts`):**
  - `RouteAccess` gains `{ kind: 'staffAny'; nodes: string[] }`;
  - `dashboard`, `dashboardType`, `entityDetail` and `entityEdit` take the list of area nodes;
  - `entitySetup*` and the builders stay on `knk.admin.content`;
  - `SIDEBAR_NODES` and `TOP_NAV_NODES` read the list.
- **Explorer:** lists only types whose area node is held. A type in the URL without the node shows the existing
  fallback.
- **Header and rows** (decision 11):
  - "New {Type}" / "New with" are disabled with "Requires <node>" without `create`;
  - Edit is disabled without `edit`;
  - Delete is disabled with "Requires knk.admin.delete" (or the area node);
  - `handleDelete` moves to `useConfirm` with `danger`.
- **Selection bar** (V2 builds the checkbox column and the bar):
  - **"Delete (n)"** is **hidden** without `bulkDelete` and for users and permission groups.
  - **The confirmation** names the count and the type and uses danger styling. It calls the bulk endpoint in chunks of
    100, lists the refused rows with their reasons, keeps them selected and refreshes the table.
  - **Export** is disabled with "Requires knk.admin.export" without the node (§ 4.8).
- **Pickers, labels and detail links:** § 4.6.3.
- **Cross-area pages** (Game settings, discovery, roads, lootboxes, the player profile): no change, because their nodes
  are read nodes (§ 4.6.2).
- **A 403 on a read** shows "You don't have access to <type>" instead of the generic error.
- **Tests:**
  - `useEntityAccess` under each node combination;
  - the route table's `staffAny` gate and the explorer filter;
  - disabled states and their hints;
  - the bulk flow (confirm, partial refusal, refresh, chunking);
  - picker lookup mode and the label fallback;
  - export through the endpoint.

### 4.8 Export (decision 10)

- **Node:** `knk.admin.export` for every type, together with the type's area node.
- **Enforced on the server**, which is consistent with decision 7.
  - **Endpoint:** `POST api/Dashboard/export` with
    `{ entityType, ids? | query: { searchTerm, filters, sortBy, sortDescending } }`. It returns
    `{ items: DTO[], total, truncated }`.
  - **Rules:** `[RequirePermission(Export)]` plus the type's area node from the registry. Web users only.
  - **Reading:** the endpoint reads through the type's own search service in pages of 500, in the requested sort.
  - **Cap:** 10 000 rows, with `truncated: true` beyond that.
  - **Audit:** one `AuditLogEntry` (actor, type, scope `selection`/`search`, count).
  - **Cost:** small. It reuses the registry delegates that the bulk delete needs anyway.
- **Formatting stays in the web app.** The CSV is built from the returned rows with the table's own columns, in table
  order, using the formatters the table uses for its readable values (#205 decision). That way the file matches what
  the user saw. A server-side CSV would duplicate every formatter.
- **Limit of the control:** a user who holds the area node can still page through the ordinary search. The export node
  controls the one-click dump of a whole search and records it in the audit log; it is not a data barrier. Hiding data
  is the read nodes' job (§ 4.6).
- **Default groups:** the owner (`*`); Admin (`knk.admin.*`, plus the seed grant); every explicit area-node holder
  (backfill, § 4.5). Anyone who holds it may grant it (normal guard rules).
- **Chain 3 V2** (#205 export) is built before AM1. It builds the CSV on the client from the list reads, as planned,
  but shows Export only to holders of `knk.admin.export`: the button is disabled with "Requires knk.admin.export"
  otherwise.
  - Until the migration runs, only the owner and Admin hold the node, through their wildcards.
  - AM3 then switches V2's data source to the export endpoint.

## 5. Implementation plan

One feature branch per repo, `claude/dashboard-access-280`. Each link merges the trunk first, plus the unmerged branches
it builds on; merge only, never rebase.

| Link | Repo | Gate | What | Test points |
|---|---|---|---|---|
| **AM1** — actions | knk-web-api | Developer's go; no other link changing knk-web-api at the same time (P1, P3 and V5–V7 are ordered by the coordinator). Merges X1 `claude/realtime-web-live-183` if it is still unmerged (it changes `RealtimeWebChangeMap`) | constants; `DashboardAccess` registry for every `[FormConfigurableEntity]` type; `Delete` rule on every deletable type's `DELETE {id}`; guard `OwnerGrantOnly` (nodes, groups, inheritance); migration `SeedDashboardActionNodes`; `POST api/Dashboard/bulk-delete` and `POST api/Dashboard/export` with audit; metadata `area`/`accessNode`/`readNodes`/`deletable`/`bulkDeletable`; realtime `NodeFor` per area | `DeleteAccessRulesTests`, `ProtectedRoutes`, `EndpointAccessRulesTests`, guard tests, migration SQL + `[MySqlFact]`, bulk and export endpoint tests, `RealtimeWebChangeMapTests`; full suite vs baseline (known #99 reds) |
| **AM2** — read gating | knk-web-api (same branch) | AM1 done | `[DashboardReads]` on every registry controller; `[RequireServiceOrAnyAreaNode]` (L/R/O) per Appendix A; the `ForWrites` filter skips runtime POSTs; `FormSubmissionProgress` to any area node; lookup endpoints `api/Lookup/{type}/search` and `{id}`; `CheckAnyAsync`; read check cache with invalidation; user summaries to `knk.admin.user.manage` | `ReadAccessRulesTests` (categories pinned; behaviour per role), lookup tests (label, detail, no email, 404 for unknown type), cache tests, `ForWritesSearchTests`; full suite vs baseline |
| **AM3** — web app | knk-web-app | chain 3 V2 done (AM3 merges V2's branch if it is unmerged; V2 contains X1); AM2 pushed (the contract is final) | `useEntityAccess`; route table `staffAny` and explorer filter; disabled New/Edit/Delete with hints; bulk "Delete (n)" in V2's bar (hidden without the nodes); `useConfirm` for delete; export through `POST api/Dashboard/export` with V2's CSV formatter; picker lookup mode and label fallback; readable 403 on reads; nodes from metadata | hook, route table, explorer, dashboard states, bulk flow, picker and label tests; `test:ci`, `tsc`, `CI=true` build, `lint:colors` not growing; themes `current`/`brand` with page background on and off |
| **AM4** — docs and smoke test | knk-workspace | AM3 done | living docs: web-api architecture (access model, registry, read categories), web-app architecture (`useEntityAccess`, lookups); admin guide for ranks (which node does what, owner-only bulk); new `guides/dashboard-access-smoke-test.md`; CHANGELOG; this design's status ("built") | smoke test with five accounts (owner, Admin, Staff, a content-only rank, a world-only rank): open the dashboard and see your types; full read vs 403 vs lookup in pickers; create, edit, delete and bulk delete per role; export with and without the node; Admin can't grant bulk; a user deny beats Admin's wildcard; Game settings, discovery, roads and lootbox pages still load for their own nodes; the plugin (apikey) still syncs; live updates per area |

**Deploy** AM1, AM2 and AM3 together, API first in the same window. AM2's read gating would break an old web app's
pickers for staff without the other areas' nodes. The migration is additive, and nothing needs to be run by hand.

## 6. Risks and notes

- **More permission checks.** Every dashboard read now does a permission check. The request memo, the 30 s read cache
  and `CheckAnyAsync` keep it to about one database round trip per user per half minute.
- **A missed cross-area read.** A page that reads another area in a way not listed in § 4.6.2 would answer 403 for staff
  without that area. To catch it: `ReadAccessRulesTests` pins every endpoint, the smoke test runs every admin page per
  role, and the web app shows a readable 403.
- **The plugin must use `api.auth.type: apikey`.** In `bearer` mode it isn't the plugin service and would need nodes
  for every read. The alpha uses `apikey`. AM4 adds this to the production checklist.
- **Admins hand out less.** After decision 4, Admins can no longer grant `knk.admin.*` (or any wildcard covering bulk
  delete). On today's alpha only the owner does that.
- ~~**Staff keep deleting users** through the backfill~~ — decided 2026-11-08: the backfill skips the Staff group, so
  Staff no longer deletes kits, siege setup, road profiles or users (§ 4.5).
- **Export isn't a data barrier** (§ 4.8). It controls the one-click dump and audits it.
- **`knk.admin.delete.*`** means single + bulk, so it falls under the owner-only rule.

## 7. Decision record (2026-11-08)

The proposal's questions and the developer's answers. (rec. = what the proposal recommended)

1. **Model:** A, global action nodes (rec. A).
2. **Bulk needs the single-delete node:** yes (rec. A).
3. **Who keeps single delete on day one:** backfill to every explicit area-node holder (rec. A).
4. **Who may hand out bulk:** only the owner, wildcards included (rec. B).
5. **Which deletes need `knk.admin.delete`:** every dashboard type, users and groups included (rec. B).
6. **Bulk types:** all except users and permission groups (rec. B).
7. **Bulk enforcement:** a new API endpoint (rec. A).
8. **Dashboard view:** any area node; per-area types and live updates (rec. B).
9. **API reads:** **gated by the area node** (B; the proposal recommended A, open reads). Designed in § 4.6.
10. **Export node:** **`knk.admin.export`** (B; the proposal recommended A, no node). Designed in § 4.8.
11. **Disallowed actions:** disabled with "Requires <node>", bulk Delete hidden (rec. B).

**Settled while turning the answers into the design** (no further question):

- **Pickers:** minimal lookups (id, label, one detail line) for any area node (§ 4.6.3).
- **Export:** enforced on the server (`POST api/Dashboard/export`), with CSV formatting in the web app (§ 4.8). Default
  holders: owner, Admin, and explicit area-node holders.
- **Consequences of decision 8 that widen access** (no data beyond what an area holder needs to use the wizard):
  - drafts, validation POSTs and form/display configuration reads open to any area node instead of `knk.admin.content`
    only (§ 4.6.4);
  - cross-area page nodes added as read nodes (§ 4.6.2).
- **Owner-only rule:** it also covers group assignment and inheritance, not only direct grants (§ 4.4).

**Open questions:** none.

**Later decisions (2026-11-12, comment on #280):** the Admin group stays editable only by a higher rank (the owner;
AM1's LAM1-1 stays); deleting a form or display configuration also needs `knk.admin.delete` (§ 4.7, built in AM3);
the safety follow-ups #348 (sudo mode), #349 (trash / soft delete), #350 (owner notifications) and #351 (Head Admin
rank) are separate issues, not part of AM3.

**Later decision (2026-11-13, #371): LAM3-1 reverted.** The developer: "Area staff should not be able to change forms
at this point. They only work with the content available." AM3 had opened the form wizard routes for any area node
(LAM3-1, question #368). Now:

1. `/forms/:type` and `/forms/:type/edit/:id` need `knk.admin.content` again (§ 4.3, § 1.5).
2. In the web app, create and edit of every dashboard type need the type's own create/edit nodes **and**
   `knk.admin.content`: the dashboard's New, New with and Edit, the detail page's Edit are disabled with "Requires
   knk.admin.content"; a picker's Create New is hidden (decision 11's pattern). Edit of a user opens the player profile
   and keeps `knk.admin.user.manage` alone.
3. Unchanged: view, read, the explorer per area, lookups, delete, bulk delete, export, the player profile.
4. The API is unchanged: it still accepts writes per area (§ 4.3, `actionNodes.create`/`edit`). Whether the API should
   also ask for `knk.admin.content` is a separate proposal (see the #371 report). **Decided: yes, #374 below.**

**Later decision (2026-11-13, #374): the API asks for `knk.admin.content` too.** The developer accepted the #374
proposal (points 1, 2 and 5): the web app's gate is not a security boundary, so the API refuses creates and edits of
dashboard types by area staff without `knk.admin.content`. Coordinator defaults (reversible, flagged in the link
report), and the link's own choices:

1. One rule in the registry, `ChangeNodes` = write node **and** `knk.admin.content`; no config switch (#374
   alternative b not taken). Reverting is one flag per type.
2. Not for User (Edit is the player profile, its own endpoints), Permission Group (stays `knk.admin.user.perm` with the
   escalation guard) and the other Players types; not for RoadProfile (the roads page edits it, no form; link
   decision).
3. The detail page's Select / Unlink / Add are changes: they need the same nodes, in the API and in the web app
   (greyed out with "Requires knk.admin.content", decision 11's pattern).
4. Only the primary create (`POST`) and update (`PUT {id}`) of each type, the endpoints the web app's create and update
   clients call (nested ones included: a gate door, banner layer, siege team, objective or spawnpoint created under its
   parent); other writes keep their rules (link decision).
5. Unchanged: delete, bulk delete, export, reads, lookups, the Staff player profile's freeze, balance, kick and ban, the
   plugin (`api.auth.type: apikey`). No migration: `SeedDashboardActionNodes` (§ 4.5) seeded only `knk.admin.delete`
   and `knk.admin.export`. Effect on the alpha: Admin (`knk.admin.*`) and the owner keep everything; the Staff group
   stops creating and editing kits and siege setup through the web and the API (in-game commands use the plugin key);
   the lootbox page's Enable/Disable toggle (a `PUT` of the type) needs `knk.admin.content` too.

## Appendix A — Read endpoints per area and their category

- **Source:** knk-web-api `master` `2e3dfeb`, every GET and every read-like POST (`search`, `validate`, `resolve`,
  health check) of the controllers behind the dashboard types and the form runtime. Routes are relative to the
  controller's `api/<Name>` unless they start with `/`.
- **Categories** (§ 4.6.1): **F** full read (read nodes or plugin key), **L** lookup and **R** form runtime (any area
  node or plugin key), **O** own records (any area node + ownership), **P** public, **G** game server only, **U** the
  action's existing stricter rule.
- **Today:** everything marked F, L, R or O is open to any logged-in user, except the R POSTs, which need
  `knk.admin.content`.

### A.1 Content — `knk.admin.content`

| Controller | Endpoints | Category |
|---|---|---|
| BannerDesigns | `GET /`, `GET {id}`, `GET {id}/layers`, `POST search` | F |
| BannerDesigns | `GET pattern-keys` | R |
| BannerLayers | `GET {id}` | F |
| Categories | `GET /`, `GET {id}`, `GET {id}/children`, `POST search` | F (+ kits, lootbox) |
| Clans | `GET /`, `GET {id}`, `POST search` | F |
| Clans | `GET default-for-town/{townId}` | L (the Town form's default) |
| EnchantmentDefinitions | `GET /`, `GET {id}`, `POST search` | F (+ kits, lootbox) |
| EnchantmentDefinitions | `GET public/info` | P |
| Grades | `GET /`, `GET {id}`, `POST search` | F (+ kits, lootbox) |
| ItemBlueprints | `GET /`, `GET {id}`, `POST search` | F (+ kits, lootbox) |
| MenuTemplates | `GET /`, `GET {id}`, `GET by-key/{key}` | F (not a dashboard type; area content; the plugin reads by key with its key) |
| MinecraftBlockRefs | `GET /`, `GET {id}`, `POST search` | F |
| MinecraftEnchantmentRefs | `GET /`, `GET {id}`, `POST search` | F |
| MinecraftMaterialRefs | `GET /`, `GET {id}`, `POST search` | F (+ road) |
| Tags | `GET /`, `GET {id}`, `POST search` | F |
| MinecraftCatalog | all | U (`knk.admin.content`, unchanged) |

### A.2 Form runtime (writes stay `knk.admin.content`)

| Controller | Endpoints | Category |
|---|---|---|
| FormConfigurations | `GET /`, `GET {id}`, `GET {entityName}`, `GET {entityName}/all`, `GET entity-names`, `GET reusable-steps`, `GET reusable-fields` | R |
| FormConfigurations | `GET {id}/export`, `GET seeds` | F `knk.admin.content` (builder tools) |
| DisplayConfigurations | `GET /`, `GET {id}`, `GET entity/{entityName}`, `GET entity/{entityName}/all`, `GET entity-names` | R |
| DisplayConfigurations | `GET {id}/export`, `GET seeds` | F `knk.admin.content` |
| FormSteps, FormFields | `GET /`, `GET {id}` | R |
| DisplaySections, DisplayFields | `GET reusable`, `GET {id}` | R |
| EntityTypeConfiguration | `GET /`, `GET {id}`, `GET by-entity/{name}`, `GET merged/{name}`, `GET merged/all` | R |
| FieldValidationRules | `GET {id}`, `GET by-field/{fieldId}`, `GET by-configuration/{configId}`, `GET /api/field-validations/rules/{ruleId}/placeholders`, `GET entity/{entityName}/properties`, `GET health-check/configuration/{configId}` | R |
| FieldValidationRules | `POST validate`, `POST validate-batch`, `POST resolve-placeholders`, `POST resolve-dependencies`, `POST validate-path`, `POST health-check/configuration/draft`, `POST /api/field-validations/validate-field` | R (explicit rule; the `ForWrites` filter skips them) |
| Metadata | `GET entities`, `GET entity-names`, `GET entities/{name}` | R |
| FormSubmissionProgress (drafts) | `GET entity`, `GET user`, `GET {id}`, `GET {id}/world-tasks`, `GET entity-references/{type}/{id}` and its writes | O (today the whole controller is `knk.admin.content`) |

### A.3 World — `knk.admin.world`

| Controller | Endpoints | Category |
|---|---|---|
| Domains | `GET /`, `GET {id}`, `POST search`, `POST search-region-decisions`, `GET by-region/{regionName}`, `GET access-rules`, `GET world/missing` | F (+ discovery for `GET /`, `{id}`, `search`) |
| Domains | `POST world/resolve` | F (a read-like POST used by forms; explicit rule) |
| Towns | `GET /`, `GET {id}`, `POST search` | F (+ config, road) |
| Districts | `GET /`, `GET {id}`, `POST search` | F (+ config) |
| Structures | `GET /`, `GET {id}`, `POST search` | F (+ config) |
| Locations | `GET /`, `GET {id}`, `POST search` | F (+ config) |
| Streets | `GET /`, `GET {id}`, `GET {id}/road`, `POST search` | F (+ road) |
| DomainSubRegions | `GET by-domain/{domainId}`, `GET {id}` | F |
| GateStructures | `GET /`, `GET {id}`, `GET domain/{domainId}`, `POST search` (today `RequireServiceOrLoggedIn`) | F |
| GateDoors | `GET GateStructures/{id}/doors`, `GET GateDoors/{id}`, `POST GateDoors/search` (today `RequireServiceOrLoggedIn`), `GET GateDoors/{id}/snapshots`, `GET GateDoors/{id}/openedSnapshots` | F |
| WorldTasks | `GET status/{status}`, `POST search`, `POST user/{userId}/search` | F |
| WorldTasks | `GET {id}`, `GET by-link-code/{code}`, `GET session/{id}`, `GET session/{id}/open`, `GET active-for-me` | O (creator, session owner, or `knk.admin.world`, as #180/#186 check today) |
| WorldTasks | `GET open` | G |
| Workflows | `GET {id}`, `GET by-guid/{guid}`, `GET {id}/progress` | O |
| Workflows | `GET health` | R |
| Presence | `GET online-staff` | U (`knk.admin.world`) |

### A.4 Kits — `knk.kit.manage`

| Controller | Endpoints | Category |
|---|---|---|
| Kits | `GET /`, `GET {id}`, `POST search` (today `RequireServiceOrLoggedIn`) | F (+ lootbox, user.manage) |
| Kits | `GET available?userId=` | F (+ user.manage; the plugin with its key) |

### A.5 Lootboxes — `knk.admin.lootbox.manage`

| Controller | Endpoints | Category |
|---|---|---|
| LootboxTypes, LootboxSpecialEntries, LootboxSpawnAreas | `GET /`, `GET {id}`, `POST search`; LootboxTypes `GET odds`, `GET {id}/odds` | U (already `knk.admin.lootbox.manage`) |

### A.6 Siege — `knk.siege.admin.manage`

| Controller | Endpoints | Category |
|---|---|---|
| SiegeScenarios | `GET /`, `GET {id}`, `POST search` (today `RequireServiceOrLoggedIn`), `GET {id}/readiness` (both routes), `GET {id}/teams`, `GET {id}/objectives` | F |
| SiegeTeams | `GET {id}`, `POST search`, `GET {id}/spawnpoints` | F |
| SiegeLobbies | `GET /`, `GET {id}`, `POST search` | F |
| SiegeLobbies | `GET runtime-config` (both routes) | F (the plugin reads it with its key) |
| SiegeObjectives, SiegeSpawnpoints | `GET {id}` | F |
| SiegeMatches | all | P (unchanged) |

### A.7 Roads — `knk.admin.road`

| Controller | Endpoints | Category |
|---|---|---|
| RoadProfiles (`api/road-profiles`) | `GET /`, `GET {id}` | F |

### A.8 Players — `knk.admin.user.manage`

| Controller | Endpoints | Category |
|---|---|---|
| Users | `GET /`, `GET search`, `POST search`, `GET {id}/profile-summary` | U (already `knk.admin.user.manage`) |
| Users | `GET {id}`, `GET {id}/permissions/check`, `GET {id}/permissions/effective` | U (self or `knk.admin.user.manage`) |
| Users | `GET uuid/{uuid}`, `GET username/{username}` | F `knk.admin.user.manage` (today any logged-in user; the web app doesn't call them) |
| Users | `GET check-duplicate`, `POST validate-link-code/{code}` | P |
| PermissionGroups | `GET /`, `GET {id}`, `GET {id}/permissions/check`, `GET {id}/expiring-memberships` | U (`knk.admin.user.manage`) |
| PermissionGroups | `POST search` | U (`knk.admin.user.perm`) |

### A.9 New endpoints

| Endpoint | Rule |
|---|---|
| `POST api/Lookup/{entityType}/search`, `GET api/Lookup/{entityType}/{id}` | L: any area node or the plugin key |
| `POST api/Dashboard/bulk-delete` | `knk.admin.delete.bulk` + `knk.admin.delete` + the type's area node; web users only |
| `POST api/Dashboard/export` | `knk.admin.export` + the type's area node; web users only |
