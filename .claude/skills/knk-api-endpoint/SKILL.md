---
name: knk-api-endpoint
description: Add or change an endpoint in knk-web-api, the Knights and Kings (K&K) ASP.NET Core API. Use when asked to add a K&K API endpoint, controller action, route, service method, repository query, DTO or AutoMapper mapping, or to expose something new to the web app or the plugin. Covers the layers (controller, service, repository with interfaces, DTOs, AutoMapper profile, DI registration), the default-deny access rule every write needs and the pinned access tests (EndpointAccessRulesTests, ReadAccessRulesTests, DashboardChangeAccessRulesTests, DeleteAccessRulesTests), rate limits, a migration when the schema changes, the xUnit tests and the docs triggers. For a whole new entity across API, web app and plugin use knk-entity-scaffold instead.
---

# K&K API endpoint

A recipe for one endpoint (or a few) in knk-web-api, built from the code on its `main`. Every pattern below names a real
file to copy; open it before you write. For a brand-new entity with its dashboard, forms and plugin side, follow
[`knk-entity-scaffold`](../knk-entity-scaffold/SKILL.md), which uses this skill for its API part.

Read first: knk-web-api `AGENTS.md` and `CLAUDE.md` (default-deny, staff nodes, rate limits, secrets), then the
[global instructions](../../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) "Testing: automated first". Code skeletons
are in [templates.md](templates.md).

## 1. Decide before you write

1. **Who calls it?** The web app (a logged-in staff member or player), the plugin (the `X-API-Key` service key), both,
   or anonymous. This decides the access rule (§ 3).
2. **Read or write?** GET/HEAD/OPTIONS are reads; everything else, a POST search included, is a write to the
   default-deny filter (`Attributes/DefaultCallerRequiredFilter.cs`).
3. **Existing controller or new?** Add to the resource's controller when the route belongs there (`api/Towns/...`).
   A new resource gets its own `Controllers/<Plural>Controller.cs` with `[Route("api/[controller]")]`. No API
   versioning exists; don't add one.
4. **Schema change?** A new column or table means a migration (§ 5). Data cleanups are scripts the developer runs after
   a backup, never migrations (knk-link § 2.5).

## 2. The layers, with the files to copy

The cleanest full pipeline is **Tag** (content area). Districts (`Controllers/DistrictsController.cs`) shows the same
shape in the world area with field selection on `GetById`.

| Layer | Folder (namespace) | Copy from | Notes |
|---|---|---|---|
| Controller | `Controllers/` (`KnKWebAPI.Controllers`) | `TagsController.cs` | Thin: call the service, map exceptions to status codes. Never return EF entities. |
| Service + interface | `Services/`, `Services/Interfaces/` | `TagService.cs`, `ITagService.cs` | Business rules, validation, cascades, orchestration. Throws `ArgumentException` (400), `KeyNotFoundException` (404), `InvalidOperationException` (409 business rule). |
| Repository + interface | `Repositories/`, `Repositories/Interfaces/` | `TagRepository.cs`, `ITagRepository.cs` | Data access only: query shaping, `Include`s, paging, `SaveChangesAsync`. No business rules. |
| DTOs | `Dtos/<Entity>Dtos.cs` | `TagDtos.cs` | `Read`/`Create`/`Update`/`List`/`Nav` classes with `[JsonPropertyName("camelCase")]`. A `NavDto` carries only the primitive fields another DTO needs, so there are no circular references. |
| AutoMapper | `Mapping/<Entity>MappingProfile.cs` | `TagMappingProfile.cs` | Picked up by `AddAutoMapper(Assembly.GetExecutingAssembly())`; no registration. Ignore `Id` on create. |
| DI | `DependencyInjection/ServiceCollectionExtensions.cs` | the `ITagRepository`/`ITagService` lines | `AddScoped` for the repository and the service. |
| DbContext | `Properties/KnKDbContext.cs` | `DbSet<Tag> Tags`, `modelBuilder.Entity<Tag>` | Only for a new table: table name in snake_case (`ToTable("tags")`). |

Paged lists: the controller takes `[FromBody] PagedQueryDto` on `POST {resource}/search`, the service maps it to
`PagedQuery`, the repository returns `PagedResult<T>`, the service maps back to `PagedResultDto<TListDto>`
(`TagRepository.SearchAsync`: search term, `SortBy` switch, `Skip`/`Take`).

**World tasks** (data captured in Minecraft, e.g. a location): the plugin sends the raw capture as the task's
`OutputJson`; `WorkflowService.FinalizeAsync` only checks that every step is complete. The entity's own service reads
the output (`WorkflowService.ExtractLocationDataFromTaskOutput` or similar) when it creates or updates the parent, so a
related row (a `Location`) exists only once the parent is saved and an abandoned workflow leaves no orphans.

## 3. The access rule (default-deny)

Every MVC action needs the plugin key or a logged-in user unless it has `[AllowAnonymous]`, and every write also
needs an explicit rule, or it answers 403 "This endpoint has no access rule." Pick the first that fits:

1. **A dashboard type's CRUD** (the entity is in `Attributes/DashboardAccess.cs`): class-level
   `[RequireServiceOrPermissionForWrites(StaffPermissions.ManageContent)]` (or `ManageWorld`, ...) and
   `[DashboardReads("<Type>")]`; `[RequireDashboardChange("<Type>")]` on the primary create and update;
   `[RequireServiceOrPermission(StaffPermissions.Delete)]` on the primary delete. Exactly as `TagsController`.
2. **Staff-only action:** `[RequirePermission(StaffPermissions.X)]`, or `[RequireServiceOrPermission(...)]` when the
   plugin calls it too. Nodes are constants in `StaffPermissions` (`Attributes/RequirePermissionAttribute.cs`); a new
   node gets a constant there with a comment naming the issue.
3. **Game server only:** `[RequirePluginService]` (for example `PlayerNotificationsController`).
4. **A player's own record:** `[RequireServiceSelfOrPermission(...)]`, or `[RequireServiceOrLoggedIn]` when the action
   itself checks ownership.
5. **Anonymous:** `[AllowAnonymous]` only with a reason, a rate limit, and the action added to `AnonymousAllowList`
   in `Tests/knkwebapi_v2.Tests/Security/EndpointAccessRulesTests.cs` (the test fails both ways).

Granting nodes or groups goes through `PermissionEscalationGuard`; never write grants around it.
Rate limits: `[EnableRateLimiting(RateLimitingSetup.AuthPolicy)]` or `(RateLimitingSetup.LookupPolicy)`
(`Configuration/RateLimitingSetup.cs`, the policies `"auth"` and `"lookup"`) on auth-like and lookup-like endpoints,
above all anonymous ones (`AdmissionController.CheckClaim`).

### 3.1 The pinned access tests

These tests pin every endpoint, so a new one makes them fail until you decide. Update them in the same commit:

1. `Security/EndpointAccessRulesTests.cs`: every write has a rule; `[AllowAnonymous]` matches the allow-list.
2. `Security/ReadAccessRulesTests.cs`: every read (GET, HEAD, a POST search) is in `Pinned` with its category, `F <Type>`
   for a dashboard type's reads, `D` for the default rule (any logged-in user or the plugin key), `U` for a stricter
   rule, `G` for the game server, `P` public. If the plugin calls the read, add it to `PluginReads`.
3. `Security/DashboardChangeAccessRulesTests.cs`: a dashboard type's create and update in `ChangeActions`.
4. `Security/DeleteAccessRulesTests.cs`: a dashboard type's primary delete in `PrimaryDeletes`; any other DELETE in
   `ConfigurationDeletes` or `Exempt`.

## 4. Steps

1. Branch per knk-link (from `next` once the branch model applies); baseline `dotnet build` and
   `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`.
2. DTOs, then the repository method (+ interface), then the service method (+ interface), then the mapping.
3. The controller action with its HTTP attribute, route (`{id:int}` constraints), access rule and status codes
   (`Ok`, `CreatedAtRoute` with a named `GetById` route, `NoContent`, `NotFound`, `BadRequest(ex.Message)`,
   `Conflict(new { code, message })`).
4. DI registration for a new service or repository.
5. The access tests of § 3.1, then the behaviour tests of § 6.
6. Migration if the schema changed (§ 5).
7. Rerun build and tests; compare with the baseline.
8. Docs (§ 7) and the PR (knk-link § 3).

## 5. Migration (only when the schema changes)

1. `dotnet ef migrations add <PascalCaseName>` from the repo root; at most one per link, additive (knk-link § 2.5).
   Never hand-write the `Designer.cs` or edit `KnKDbContextModelSnapshot.cs` by hand.
2. Read the generated `Up` and `Down`: column types and lengths for MySQL, defaults for existing rows, indexes.
3. A migration test in `Tests/knkwebapi_v2.Tests/Migrations/` reads `new <Migration>().UpOperations`
   (`AddDomainDiscoveryTests.cs`): the tables, unique indexes and seeded rows you meant.
4. CI's `Migrations (fresh DB)` workflow (`.github/workflows/migrations.yml`) applies every migration to an empty
   MySQL 8; watch it on the PR.
5. A default grant of a new node to a group is a data migration with precedent (`SeedStaffKickBanNodes`,
   `SeedCommandPermissionNodes`): only when the design or the developer decided who gets it.

## 6. Tests (automated first)

Use the [`knk-test-writer`](../knk-test-writer/SKILL.md) skill to sort behaviours into suites; for an endpoint that is
mostly xUnit in `Tests/knkwebapi_v2.Tests/`:

1. **Service rules** in `Services/<Entity>ServiceTests.cs`: Moq the repository, real AutoMapper with the profile
   (`GradeServiceTests.cs`): validation errors, not-found, the happy path, cascades.
2. **Controller results** in `Api/<Controller>Tests.cs` when the action maps results itself
   (`TitleBracketsControllerTests.cs`): status codes and bodies.
3. **Access behaviour** per role through the real filters when the rule is unusual (the `Pipeline` helper and
   `FakePermissions` in `ReadAccessRulesTests.cs`, `Api/RequireServiceOrPermissionAttributeTests.cs`).
4. **Mapping** in `Mapping/` when a profile has custom members (`TownMappingProfileTests.cs`).
5. **MySQL-only behaviour** (unique indexes, collation) in `MySql/`, which needs `KNK_TEST_MYSQL` and skips without it;
   say so in the PR when it was skipped.
6. A new web page that calls the endpoint gets its Playwright spec in knk-web-app (knk-test-writer § 2); the API tests
   don't cover what a page shows.

Run each new test once failing (break the rule or invert the assertion), then green.

## 7. Docs and PR

1. Docs triggers (knk-web-api `AGENTS.md`): a new or changed endpoint means `docs/specs/api/` and the architecture docs
   in knk-workspace; a migration means the seed (`knk-dev-db-seed`) and the migration steps in
   `docs/guides/production-installation.md`; a new setting or secret means the configuration and secret tables there.
2. The PR template's Docs impact and Admin steps (migration to apply, new node to grant), changelog entry in
   knk-workspace `docs/CHANGELOG.md`.
3. Testing section per knk-test-writer § 5.

## 8. Checklist

1. Access rule on every new action; the four pinned tests updated.
2. No EF entity returned; DTOs with `JsonPropertyName`; a `NavDto` instead of a nested full DTO.
3. Business rules in the service, data access in the repository.
4. DI registered; mapping profile covers every DTO direction.
5. Migration generated by `dotnet ef`, read, tested; or none needed.
6. Service and access tests, each seen failing once.
7. No secrets in code, settings, fixtures or logs.
8. Docs impact, Admin steps and changelog filled in.
