# knk-web-api — Architecture

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-09-18 (based on a full read-only code scan; see `docs/reports/web-api-scan-2026-09-18.md` for the raw findings this doc summarizes)

## 1. Stack & shape

- ASP.NET Core on .NET 8, single Web SDK project at the repo root (`knkwebapi_v2.csproj`); test project under `Tests/knkwebapi_v2.Tests/` excluded from the main build.
- EF Core via `Pomelo.EntityFrameworkCore.MySql` against MySQL — the only configured/used provider (`Program.cs:51`, `options.UseMySql(...)`). The `.csproj` also references `Microsoft.EntityFrameworkCore.SqlServer` (`knkwebapi_v2.csproj:21`); a repo-wide search found **zero** `UseSqlServer`/SQL-Server-specific API calls — this package reference is confirmed dead weight, not in-use anywhere.
- AutoMapper for DTO↔entity mapping (`Mapping/*Profile.cs`, one profile per feature area).
- JWT bearer auth (`Microsoft.AspNetCore.Authentication.JwtBearer`), configured under `Security:Jwt` in `appsettings.json` (issuer `knk-api`, audience `knk-app`; `AccessTokenMinutes: 30`).
- OpenTelemetry wired into `Program.cs` directly; a parallel `DependencyInjection/ObservabilityServiceCollectionExtensions.cs` (`AddObservability`/`AddOpenTelemetryInstrumentation`) exists but is **never called** — `Program.cs` duplicates that logic inline instead. Treat `Program.cs` as the source of truth for observability wiring, not that extensions file.
- No API versioning (plain `api/[controller]` routes), no raw SQL/ORM bypass anywhere in the repo (confirmed by grep for `FromSqlRaw`/`ExecuteSqlRaw`/Dapper/raw ADO.NET — zero hits; all 25 repositories are thin EF Core LINQ wrappers over `KnKDbContext`).

## 2. Structure

```
Controllers/         34 controllers, plain api/[controller] routing
Services/            ~40 services + Services/Interfaces/ + Services/ValidationMethods/
Repositories/        25 repositories (thin EF Core wrappers) + Repositories/Interfaces/
Dtos/                ~35 files, one per entity/feature (+ Dtos/Forms/ — see §6, orphaned)
Mapping/             AutoMapper profiles, one per feature area
Models/              EF Core entities (35 DbSets + join/composite entities) + Models/ClientActivity/,
                     Models/FormConfiguration/, Models/Item/ non-DB or extension POCOs
Migrations/          38 migrations + KnKDbContextModelSnapshot.cs
Properties/          KnKDbContext.cs (the DbContext — not under Data/ or Models/)
Data/                Static JSON reference catalogs (Minecraft material/enchantment data) — not the
                     data-access layer, just seed/lookup content loaded by singleton catalog services
Configuration/       Strongly-typed options classes (ClientActivityOptions, EmailSettings,
                     SecuritySettings, TelemetryOptions)
DependencyInjection/  ServiceCollectionExtensions.cs (DI convention scan) +
                     ObservabilityServiceCollectionExtensions.cs (dead — see above)
Middleware/          ClientActivityMiddleware.cs (per-request activity tracking for AdminClients)
Attributes/          FormConfigurationAttributes.cs ([FormConfigurableEntity] etc., drive MetadataService)
Enums/, Json/        Cross-cutting enum/JSON-converter support
Prompts/             Design-doc drafts (DisplayConfig requirements) — see §6, one stray empty duplicate
```

## 3. Data flow

Standard layered flow for almost every feature: `Controller` → `Service` (business rules, AutoMapper) → `Repository` (EF Core LINQ over `KnKDbContext`) → MySQL. Two notable direct-injection exceptions bypass the service layer: `FormConfigurationsController` and `TestDisplayController` inject repositories directly.

Cross-cutting pieces that sit beside this pipeline:
- **`MetadataService`** (singleton) reflects over `[FormConfigurableEntity]`-annotated models to drive the dynamic form builder (`MetadataController`, `FormConfigurationService`).
- **Catalog services** (`MinecraftMaterialCatalogService`, `MinecraftEnchantmentCatalogService`, both singletons) load static JSON from `Data/*.json` — distinct from the DB-backed `MinecraftMaterialRef`/`MinecraftEnchantmentRef` tables, which are curated subsets of the full catalog.
- **`RetentionPolicyService`** — the only `BackgroundService`/`IHostedService` in the API; a daily job purging `FormSubmissionProgress` rows older than 14 days.
- **Validation pipeline**: `ValidationService` dispatches to 4 `IValidationMethod` implementations (`ConditionalRequiredValidator`, `ConditionalValueMatchValidator`, `LocationInsideRegionValidator`, `RegionContainmentValidator`), with `PlaceholderResolutionService`/`PathResolutionService` resolving `{Placeholder}` tokens and dependency-path expressions used in validation messages. A separate, apparently-unused `FieldValidationService`/`IFieldValidationService` exists and looks like a superseded duplicate of this same responsibility (no controller injects it — see §6).

## 4. EF Core / database layer

`Properties/KnKDbContext.cs` declares 35 `DbSet<T>` entities plus 4 many-to-many/composite join tables configured inline (`TownStreet`, `DistrictStreet`, `gate_structure_guard_spawn_locations`, `ItemBlueprintDefaultEnchantment`). Charset/collation: `utf8mb4_general_ci`/`utf8mb4`.

Key structural facts worth knowing before touching the model:

- **`Domain` is a TPT (table-per-type) base**: `Town`, `District`, and `Structure` all inherit from `Domain` (each with its own `ToTable()`), not TPH — a query against `Domain` alone won't see subtype-specific columns without EF Core issuing the corresponding join.
- **Siege/gate cluster**: `GateStructure : Structure` → 1→N `GateDoor` (cascade) → 1→N `GateBlockSnapshot`/`GateOpenedBlockSnapshot` (cascade, two separate tables by design, not a discriminator). `GateStructure` has many nullable `*Override` fields that cascade down to its doors when set. `GateDoor` deliberately keeps `GateNameDisplayModeOverride`/`StatusDisplayModeOverride` as int-backed enums (not `HasConversion<string>()` like its siblings) — there's an explicit in-code comment warning that string-converting them would corrupt existing data. Don't "fix" that inconsistency without a data migration.
- **Form-builder cluster**: `FormConfiguration` → `FormStep` (self-referencing parent/child for reusable sub-wizards, plus an optional `SubConfiguration` link) → `FormField` (self-referencing `DependsOnField`) → `FieldValidation`/`FieldValidationRule`. `DisplayConditionGroup`/`DisplayCondition` attach to either a step or a field and read another field's value earlier in the form. `FormSubmissionProgress` supports nested sub-form wizards via a self-referencing `ParentProgress`.
- **`WorkflowSession`** is the only entity with a `[Timestamp] RowVersion` (optimistic concurrency) — a deliberate choice given it drives the plugin/web-app hybrid create-edit workflow (see §5).
- **Item/ability cluster**: `ItemBlueprint` ↔ `EnchantmentDefinition` via `ItemBlueprintDefaultEnchantment` (composite key, extra `Level` column); `EnchantmentDefinition` 1↔1 `AbilityDefinition` (custom-ability extension, with a static `CanonicalCatalog` + idempotent `SeedCanonicalAsync` run at startup).
- **`WorldTask.PayloadJson`** is marked `[Obsolete("Use InputJson/OutputJson instead")]` (`Models/WorldTask.cs:38`) but is still actively read/written in `WorkflowMappingProfile.cs`, `WorldTasksController.cs`, `WorldTaskService.cs`, `KnKDbContext.cs`, and the manual `.http` test file — treat this as a migration-in-progress, not dead code; don't remove the column without confirming no rows still depend on it.

**Migration history**: 38 migrations, chronologically clean (no out-of-order timestamps, content matches names, snapshot matches current `Models/`) with one caveat — `20260131165938_AddGateAnimationSystem.cs` and `20260222161000_AddSubConfigurationIdToFormStep.cs` are both missing their `.Designer.cs` companion, and the latter has its `[Migration]`/`[DbContext]` attributes unusually inlined into the main file rather than in a Designer file. This suggests both were hand-created/patched rather than produced by `dotnet ef migrations add`; their actual schema effect is correct and reflected in `KnKDbContextModelSnapshot.cs`, so this is a hygiene note, not a correctness bug — see the reading guide before adding a new migration by hand.

## 5. Talks to knk-web-app

Browser clients call the API over REST with a bearer token attached (`src/services/serviceCall.ts` on the web-app side). Every controller except `AdminClientsController`, `AuthController.Me`/`Update`, and `UsersController.LinkMinecraftAccount` has **no** `[Authorize]` attribute — JWT bearer auth is configured globally but most actions don't actually require it. This is broader than the CLAUDE.md's implication that JWT auth gates the API generally; verify with the developer whether this is intentional (internal-tool-style trust) or a gap before shipping wider access.

The web-app is the primary caller for almost every CRUD controller (Towns/Districts/Streets/Structures/Categories/DisplayConfigurations/FormConfigurations/GameSettings/etc.) and for the form-builder/validation/workflow machinery. See the endpoint table in the scan report for the full caller breakdown, including several confirmed **broken web-app client calls** (routes the frontend posts to that don't exist server-side — e.g. `authClient.ts`'s `mergeAccounts` posts to a non-existent `api/Auth/merge` instead of the real `api/Users/merge`).

## 6. Talks to knk-plugin

Contrary to what both this repo's and knk-plugin's CLAUDE.md currently say ("no webhook/push model" / "no polling/webhook indirection found"), the integration is **not purely plugin-calls-API**:

- **plugin → API** (the dominant direction): the plugin's `knk-api-client` module makes hand-written REST calls (OkHttp + Jackson, not OpenAPI-generated) covering Users, Towns, Districts, Streets, Structures, Locations, EnchantmentDefinitions, ItemBlueprints, MinecraftMaterialRefs, Domains (`by-region`/`search-region-decisions` only), GateStructures, GateDoors, WorldTasks, and Health. Auth is a statically-configured bearer token (`config.yml` → `api.auth.bearer-token`, **defaulting to `type: none`**, i.e. no `Authorization` header at all unless explicitly configured) via `BearerAuthProvider` — there is no login/refresh flow on the plugin side, so a configured token will silently start failing after the API's 30-minute access-token lifetime unless it's a specially-issued long-lived token. Confirm this operationally; it can't be verified from the code alone.
- **API → plugin (a real, working exception)**: `Services/RegionService.cs` makes outbound HTTP calls (`MinecraftPlugin:BaseUrl`, defaulting to `http://localhost:8081` — a C# fallback not present in either `appsettings.json`) into a small `com.sun.net.httpserver.HttpServer` the plugin itself runs (`knk-paper/.../http/RegionHttpServer.java`, started in `KnKPlugin.java:296-301`) for WorldGuard region rename/containment checks, triggered synchronously from Town/District/Street entity create/rename flows. This is the one confirmed push channel from API to plugin — **update both repos' CLAUDE.md files** to reflect this rather than trusting the "no push model" claim.
- **Headless world-task polling**: the plugin polls for tasks it needs to execute (`HeadlessWorldTaskPoller.java`, 5s interval backing off to 60s when idle) rather than being notified — the plugin's own source comments already flag this as a known gap ("should eventually be replaced by the API pushing a notification, e.g. SignalR"). There is no SignalR/WebSocket/Hub anywhere in this repo today.
- **`HealthController` (`api/Health`)** is what the plugin actually calls for its health check (`HealthApiImpl.java`), via a route the plugin's own comments call a guessed/unverified contract. The API's "real" liveness/readiness surface is `HealthCheckController` (`health/live`, `health/ready`, checks DB connectivity) — no caller was found for it in either repo, consistent with it being meant for external infra (k8s/docker healthchecks) rather than app-to-app calls. Consider pointing the plugin at `health/live` instead, and treat `HealthController` as retirable once that happens.

## 7. Known architectural debt to be aware of before extending this repo

- `Microsoft.EntityFrameworkCore.SqlServer` package reference — unused, safe to remove.
- `DependencyInjection/ObservabilityServiceCollectionExtensions.cs` — dead code; `Program.cs` has its own inline duplicate of the same wiring.
- `Services/DependencyPathResolver.cs` and `Services/FieldValidationService.cs`/`IFieldValidationService` — no controller/service caller found anywhere; both look superseded by `PathResolutionService`/`ValidationService` + `PlaceholderResolutionService` respectively.
- `Dtos/Forms/FieldValidationRuleDtos.cs` — a second, near-duplicate set of `FieldValidationRuleDto`-family classes in a `Dtos.Forms` namespace that nothing references; the real one lives in `Dtos/FieldValidationRuleDtos.cs`.
- `Telemetry:Prometheus` config (`appsettings*.json`) is not wired to any actual `/metrics` endpoint — `Program.cs:186` has an explicit unresolved TODO for it. **This repo's own `CLAUDE.md` and `OBSERVABILITY.md` claiming "Prometheus metrics exposed at `/metrics`" is stale/aspirational**, not current fact.
- `FieldValidationRulesController` exposes two extra absolute-route actions (`/api/field-validations/validate-field`, `/api/field-validations/rules/{ruleId}/placeholders`) on a different base path than the rest of the controller (`field-validations` vs. `field-validation-rules`) — no caller found; looks like a legacy/duplicate of the controller's own `.../validate` action.
- `TestDisplayController` (`api/test/*`) is a live, unauthenticated integration-test harness with a `DELETE api/test/cleanup` action that bulk-deletes any `DisplayConfiguration` whose name merely contains `"Test"` — a real footgun if this ever reaches a shared/prod environment. Not hypothetical dead code; it works today.
- `WeatherForecastController` is unmodified ASP.NET Core template scaffolding with no real caller — safe to delete.

Full detail, file:line citations, and the complete endpoint/service/repository/entity tables are in `docs/reports/web-api-scan-2026-09-18.md`. Practical "how to work in this repo" guidance is in `docs/guides/web-api-reading-guide.md`.
