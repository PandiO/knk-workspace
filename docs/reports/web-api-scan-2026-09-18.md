# knk-web-api — Codebase Scan (2026-09-18)

**Status:** Dated scan report — do not overwrite; a re-scan produces a new dated file (see `docs/guides/v3-codebase-scan-instructions.md`)
**Method:** Read-only pass per `v3-codebase-scan-instructions.md` §2. Three parallel sub-scans (endpoints+callers; services/repositories/EF Core/migrations; legacy code+plugin integration) each read every source file in scope directly — controllers, services, repositories, `Properties/KnKDbContext.cs`, all `Models/`, all `Migrations/`, `Dtos/`, plus cross-repo caller checks against `knk-web-app/src` and `knk-plugin`. No files were modified in any repo.
**Convention:** "called by X" means literal code building that route was found in X. "no caller found — verify" means both `knk-web-app/src` and `knk-plugin` were grepped for the route and nothing was found — it does not mean the endpoint is provably dead (an external tool, admin script, or Swagger/curl use could still hit it).

---

## 1. Feature / functionality inventory

### 1.1 Endpoint table (34 controllers)

| Controller | Verb(s) | Route(s) | Purpose | Auth | Caller(s) |
|---|---|---|---|---|---|
| **AdminClientsController** | GET / GET / GET / POST | `api/admin/clients`, `.../{clientType}/{clientId}`, `.../all`, `.../cleanup` | Client-activity dashboard data + stale-client purge | `[Authorize(Policy="RequireAdmin")]` class-level | none found — verify (no dashboard built yet) |
| **AuthController** | POST/POST/POST/GET/PUT/POST/POST/POST | `api/Auth/{login,refresh,logout,me,update,validate-token,forgot-password,reset-password}` | Login/refresh/logout/self-service account update, password reset | `[AllowAnonymous]` on login/refresh/logout/validate-token/forgot/reset-password; `[Authorize]` on me/update | web-app for all except `validate-token` (none found — verify) |
| **CategoriesController** | GET/GET/GET/POST/PUT/DELETE/POST | `api/Categories[...]`, `/{id}/children`, `/search` | Item-category catalog CRUD + hierarchy + paged search | none | web-app (all) |
| **DisplayConfigurationsController** | GET×5/POST/PUT/DELETE/POST | `api/DisplayConfigurations[...]`, `/entity/{name}[/all]`, `/entity-names`, `/{id}/publish` | Entity display-template CRUD, draft→publish | none | web-app (all) |
| **DisplayFieldsController** | GET×2/POST/PUT/DELETE/POST | `api/DisplayFields/reusable`, `/{id}`, `/{id}/clone` | Reusable display-field template CRUD + clone (copy/link mode) | none | web-app (all) |
| **DisplaySectionsController** | GET×2/POST/PUT/DELETE/POST | `api/DisplaySections/reusable`, `/{id}`, `/{id}/clone` | Reusable display-section template CRUD + clone | none | web-app (all) |
| **DistrictsController** | GET×2/POST/PUT/DELETE/POST | `api/Districts[...]`, `/search` | District CRUD + paged search | none | web-app (all); plugin: GetById + search → **both** |
| **DomainsController** | GET×2/POST/PUT/DELETE/GET/POST | `api/Domains[...]`, `/by-region/{name}`, `/search-region-decisions` | Base Domain CRUD + WorldGuard-region→domain lookup | none | GetAll/GetById/Create/Update/Delete: **none found — verify**; `by-region`/`search-region-decisions`: **plugin only**. Web-app's `Dominions` enum value (`enums.ts:72`) is itself unused. |
| **EnchantmentDefinitionsController** | GET×2/POST/PUT/DELETE/POST | `api/EnchantmentDefinitions[...]`, `/search` | Enchantment-definition catalog CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **EntityTypeConfigurationController** | GET×5/POST/PUT/DELETE | `api/EntityTypeConfiguration[...]`, `/by-entity/{name}`, `/merged/{name}`, `/merged/all` | Admin overlay (icon/color/visibility) merged onto reflection-derived entity metadata | none | web-app (all) |
| **FieldValidationRulesController** | GET×3/POST/PUT/DELETE/POST×5/GET×2 | `api/field-validation-rules[...]` + 2 legacy absolute routes under `api/field-validations/*` | Validation-rule CRUD, execution, placeholder resolution, dependency-path validation, config health-check | none | web-app (all of the `field-validation-rules` routes); the 2 `field-validations/*` absolute-route actions: **none found — verify**, look like a superseded duplicate of `.../validate` |
| **FormConfigurationsController** | GET×7/POST×3/PUT/DELETE | `api/FormConfigurations[...]`, `/{name}[/all]`, `/entity-names`, `/reusable-{steps,fields}`, `/{id}/steps/add-from-template`, `/steps/{id}/fields/add-from-template` | Form-wizard template CRUD + reusable step/field composition | none | web-app (all) |
| **FormFieldsController** | GET×2/POST/PUT/DELETE | `api/FormFields[...]` | Reusable form-field template CRUD | none | web-app (all) |
| **FormStepsController** | GET×2/POST/PUT/DELETE | `api/FormSteps[...]` | Reusable form-step template CRUD | none | web-app (all) |
| **FormSubmissionProgressController** | GET×3/POST/PUT/DELETE | `api/FormSubmissionProgress[...]`, `/entity`, `/user` | In-progress wizard draft CRUD | none | web-app (all) |
| **GameSettingsController** | GET/PUT/PUT | `api/GameSettings`, `/runtime-worlds` | Singleton global game-settings row | none | web-app (all); `runtime-worlds` has no plugin caller despite being Minecraft-world config — verify whether the plugin should read it at startup |
| **GateDoorsController** | GET×5/POST×3/PUT×4/DELETE×2 | `api/GateStructures/{id}/doors`, `api/GateDoors[...]`, `/{id}/{state,health,operational-settings,region}`, `/{id}/{openedS,s}napshots[/bulk]` | Siege gate-door CRUD, open/close + health + operational state, region link update, block-snapshot management | none | web-app: all except `/region`; plugin: get/create-list/state/health/operational-settings/region → several **both**, `/region` = **plugin only** |
| **GateStructuresController** | GET×3/POST/PUT/DELETE/POST/PATCH | `api/GateStructures[...]`, `/domain/{id}`, `/search`, `/{id}/overrides` | Siege gate-structure CRUD + search + cascading door-override toggles | none | web-app (all); plugin: GetAll/GetById/GetByDistrict/overrides → **both** |
| **HealthController** | GET | `api/Health` | Minimal "process is up" ping, no dependency checks | none | **plugin** (via a guessed/unverified contract per the plugin's own code comments) |
| **HealthCheckController** | GET/GET | `health/live`, `health/ready` | Liveness + DB-aware readiness probes | none | none found — verify (likely external infra, not app code) |
| **ItemBlueprintsController** | GET×2/POST/PUT/DELETE/POST | `api/ItemBlueprints[...]`, `/search` | Item-blueprint CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **LocationsController** | GET×2/POST/PUT/DELETE/POST | `api/Locations[...]`, `/search` | World-coordinate record CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **MetadataController** | GET×3 | `api/Metadata/entities[/{name}]`, `/entity-names` | Form-configurable entity metadata for the form builder | none | web-app (all) |
| **MinecraftBlockRefsController** | GET×2/POST/PUT/DELETE/POST | `api/MinecraftBlockRefs[...]`, `/search` | Block-reference CRUD + search | none | web-app (all); no plugin caller found for this controller |
| **MinecraftEnchantmentRefsController** | GET×3/POST×2/PUT/DELETE/POST | `api/MinecraftEnchantmentRefs[...]`, `/hybrid`, `/get-or-create`, `/search` | Enchantment-reference CRUD + hybrid catalog/DB picker + idempotent persist-from-catalog | none | web-app (all) |
| **MinecraftMaterialRefsController** | GET×3/POST×2/PUT/DELETE/POST | `api/MinecraftMaterialRefs[...]`, `/hybrid`, `/get-or-create`, `/search` | Material-reference CRUD + hybrid picker + persist-from-catalog | none | GetAll/GetById/Create/Update/Delete/search: web-app; plugin: GetById → **both**; `/hybrid` and `/get-or-create`: **none found — verify** (the web-app client is missing these two calls even though its enchantment-ref sibling has matching ones — looks like an incomplete port) |
| **RegionsController** | POST | `api/Regions/rename` | WorldGuard region rename, explicitly documented as plugin-called | none | **plugin only** |
| **StreetsController** | GET×2/POST/PUT/DELETE/POST | `api/Streets[...]`, `/search` | Street CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **StructuresController** | GET×2/POST/PUT/DELETE/POST | `api/Structures[...]`, `/search` | Structure CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **TestDisplayController** | GET/DELETE | `api/test/display-repositories`, `/test/cleanup` | Hard-coded integration-test harness against Display* repositories; `cleanup` bulk-deletes any config whose name contains "Test" | none | none found — verify (dev-only tool; unauthenticated bulk-delete is a real production risk if ever exposed) |
| **TownsController** | GET×2/POST/PUT/DELETE/POST | `api/Towns[...]`, `/search` | Town CRUD + search | none | web-app (all); plugin: GetById + search → **both** |
| **UsersController** | GET×4/POST×7/PUT×6/DELETE | `api/Users[...]` (17 actions total — see notes) | Full account lifecycle: CRUD, Minecraft-account linking/merging, password/email change, coins, gate-passthrough preference, link codes | `[Authorize]` on `link-minecraft-account` only | mixed — see notes below |
| **WeatherForecastController** | GET | `WeatherForecast` (no `api/` prefix) | ASP.NET Core template scaffolding — 5 rows of fake weather data | none | none found — verify (safe-to-delete template leftover) |
| **WorkflowsController** | GET/POST/GET×3/POST×3/PUT/DELETE | `api/Workflows[...]`, `/health`, `/{id}[/resume,/progress,/finalize]`, `/by-guid/{guid}`, `/{id}/steps/{stepKey}/complete`, `/{id}/steps/{stepNumber}` | Workflow-session orchestration for the hybrid web/plugin create-edit flow | none | web-app for all except `/health` and `/by-guid/{guid}` (both: none found — verify) |
| **WorldTasksController** | POST×2/GET×4/POST×5/DELETE | `api/WorldTasks[...]`, `/from-field`, `/by-link-code/{code}`, `/status/{status}`, `/session/{id}`, `/user/{id}/search`, `/search`, `/{id}/{status,claim,complete,fail}` | Headless/plugin-executed task queue: create, claim, complete/fail, status search | none | web-app for all except `/from-field` (none found — verify); plugin: get-by-id/by-link-code/status/claim/complete/fail → **both** |

**UsersController notes:** `GetByUuid`/`GetByUsername` (summary lookups, doc-commented "Minecraft plugin uses this") and `PUT .../coins` (by UUID), `.../gate-passthrough-method`, `.../change-password`, `.../update-email`, `POST .../validate-link-code/{code}` are all **plugin-only** — no web-app UI flow was found for self-service password/email change, which is worth flagging as a possible gap. `POST .../merge` is called correctly by the plugin, but the web-app's own `mergeAccounts` client method posts to a non-existent `api/Auth/merge` instead (bug, not evidence of no caller — see §2.6). `POST .../check-duplicate` expects a JSON body (`DuplicateCheckDto`) but the plugin sends the same data as query params with an empty `{}` body — this will not model-bind server-side as written; worth a real bug check.

### 1.2 "No caller found — verify" endpoints (deduplicated)

1. All 4 `AdminClientsController` actions — likely intended for a not-yet-built admin dashboard.
2. `AuthController.ValidateToken` (`POST api/Auth/validate-token`).
3. `DomainsController`: `GetAll`, `GetById`, `Create`, `Update`, `Delete` (only `by-region`/`search-region-decisions` are used, by the plugin).
4. `FieldValidationRulesController`'s two `field-validations/*` absolute-route actions — likely legacy duplicates of `.../validate`.
5. `HealthCheckController`: `health/live`, `health/ready` (plausible external-infra callers, outside these two repos).
6. `MinecraftMaterialRefsController`: `/hybrid`, `/get-or-create` — sibling enchantment-ref controller's equivalents *are* called; looks like an incomplete client port, not intentional.
7. `TestDisplayController`: both actions (expected — dev harness).
8. `UsersController`: `PUT .../{id}/coins` (int-id variant; the UUID variant is plugin-only).
9. `WeatherForecastController.Get` — template scaffolding.
10. `WorkflowsController`: `GET .../health`, `GET .../by-guid/{guid}`.
11. `WorldTasksController.CreateFromField` (`POST .../from-field`) — DTO shape suggests it was meant for the dynamic form/workflow wizard flow, but the web-app always uses the plain `Create` action instead.

### 1.3 Confirmed broken/dead web-app→API client calls (found while cross-referencing callers)

These are web-app bugs, not evidence the server endpoint lacks a caller — noted here because they surfaced during the same cross-reference pass:

- `authClient.ts` `mergeAccounts` → posts to `api/Auth/merge` (doesn't exist); the real endpoint is `api/Users/merge` (`UsersController.cs:671`), which the plugin calls correctly.
- `authClient.ts` `requestLinkCode` → posts to `api/Users/request-link-code` (doesn't exist anywhere); the real route is `generate-link-code`.
- `displayConfigClient.ts` `clone` (for `DisplayConfigurationDto`) → posts to `api/DisplayConfigurations/{id}/clone` (doesn't exist — only `DisplayFieldsController`/`DisplaySectionsController` have `clone`).
- `displayConfigClient.ts` `addReusableSectionToConfiguration`/`addReusableFieldToSection` → post to routes that don't exist on `DisplayConfigurationsController`/`DisplaySectionsController` (the real `add-from-template` routes only exist on `FormConfigurationsController`, for form steps/fields — looks copy-pasted from the forms feature and never repointed).

### 1.4 Service inventory (`Services/`, ~40 concrete classes)

| Service | Responsibility | Used by |
|---|---|---|
| `AuthService` | Login/refresh/logout/current-user | `AuthController` |
| `CachedDependencyResolutionService` | Memory-caches `DependencyResolutionService` results | `FieldValidationRulesController` (via `IDependencyResolutionService`) |
| `CategoryService` | Category CRUD, icon-material validation | `CategoriesController` |
| `DependencyPathResolver` | Walks multi-layer entity-relationship paths | **no consumers found anywhere — orphaned, verify** |
| `DependencyResolutionService` | Resolves dependency paths against a form snapshot; field-entity alignment health check | wrapped by `CachedDependencyResolutionService` |
| `DisplayConditionEvaluator` | Evaluates display-condition trees for field/step visibility | `FormSubmissionProgressService` |
| `DisplayConfigurationService` / `DisplayFieldService` / `DisplaySectionService` | CRUD for display templates/fields/sections | matching controllers |
| `DistrictService` / `DomainService` / `StreetService` / `StructureService` / `TownService` | CRUD for the Domain-hierarchy entities; region-name finalization via `IRegionService` | matching controllers |
| `EnchantmentDefinitionService` / `ItemBlueprintService` | Catalog CRUD, cross-validated against material/enchantment refs | matching controllers |
| `EntityTypeConfigurationService` | Merges reflection metadata with admin overlay config | `EntityTypeConfigurationController` |
| `FieldValidationRuleService` | Validation-rule CRUD + config-health checks | `FieldValidationRulesController` |
| `FieldValidationService` (`IFieldValidationService`) | Executes field validations w/ placeholder resolution | **registered in DI but no controller/service injects it — orphaned, verify; appears duplicated by `ValidationService`** |
| `FormConfigurationService` / `FormFieldService` / `FormStepService` / `FormTemplateReusableService` / `FormTemplateValidationService` | Form-wizard template CRUD + reuse/validation | matching controllers |
| `FormOrdering` (static) | Orders steps/fields via `*OrderJson` GUID arrays | internal helper |
| `FormSubmissionProgressService` | Draft-progress state, strips hidden-field values before persisting | `FormSubmissionProgressController`, `RetentionPolicyService` |
| `GameSettingsJson` (static) | Fixed-options JSON (de)serialize helper | `GameSettingsService` |
| `GameSettingsService` | Singleton game-settings row management | `GameSettingsController` |
| `GateDoorService` / `GateStructureService` | Siege gate CRUD | matching controllers; `WorldTaskService` |
| `InMemoryClientActivityStore` | Rolling 60-min per-client request metrics | `AdminClientsController`, `ClientActivityMiddleware` |
| `LinkCodeService` | Account-link code generation/validation | `UserService` |
| `LocationService` | World-coordinate CRUD | `LocationsController` + several Domain-hierarchy services |
| `MetadataService` (singleton) | Reflection-based form metadata discovery | `MetadataController`, `FormConfigurationService` |
| `MinecraftBlockRefService` / `MinecraftEnchantmentRefService` / `MinecraftMaterialRefService` | Reference-row CRUD validated against catalogs | matching controllers |
| `MinecraftEnchantmentCatalogService` / `MinecraftMaterialCatalogService` (singletons) | Load static JSON catalogs from `Data/` | ref services, `CategoryService`, `ItemBlueprintService` |
| `PasswordResetDeliveryService` (dev, logs only) / `SmtpPasswordResetDeliveryService` | Password-reset delivery, chosen by `Email:Provider` config | `AuthService` |
| `PasswordService` | Bcrypt hashing + OWASP 2023 strength checks | `AuthService`, `UserService` |
| `PathResolutionService` | Shared entity-path navigation | `FieldValidationRulesController`, `PlaceholderResolutionService` |
| `PlaceholderResolutionService` | Resolves `{Placeholder}` tokens in messages | `FieldValidationRulesController`, `ValidationService` |
| `RegionService` (`IRegionService`) | Outbound HTTP client to the plugin's WorldGuard region API (rename/containment) | `RegionsController`, `DomainService`, `DistrictService` |
| `RetentionPolicyService` (`BackgroundService`) | Daily purge of old `FormSubmissionProgress` rows | hosted service |
| `StreetService` / `StructureService` / `TownService` | see above | |
| `TokenService` | JWT access/refresh token issuance & validation | `AuthController`, `AuthService` |
| `UserService` | Account management, OWASP rules, Minecraft account linking | `UsersController` |
| `ValidationMethods/*` (4 classes) | `IValidationMethod` implementations (conditional required/value-match, location-in-region, region-containment) | `ValidationService` (injected as `IEnumerable<IValidationMethod>`) |
| `ValidationService` | Dispatches validation-rule execution across the 4 methods above | `FieldValidationRulesController` |
| `WorkflowService` | Orchestrates workflow sessions/step progress (does not persist entities itself, by design) | `WorkflowsController`, `WorldTaskService` |
| `WorldTaskService` | Creates/manages world tasks, routes gate-block-scan results to `GateDoorService` | `WorldTasksController`, `WorkflowService` |

**Also dead**: `DependencyInjection/ObservabilityServiceCollectionExtensions.cs` (`AddObservability`/`AddOpenTelemetryInstrumentation`) is defined but never called anywhere — `Program.cs` duplicates the same setup inline instead.

### 1.5 Repository inventory (`Repositories/`, 25 concrete classes)

All 25 are thin EF Core LINQ wrappers over `KnKDbContext` (confirmed by reading each — no raw SQL anywhere). None are orphaned; every one is reachable from at least one controller, either through its service or via direct injection (`FormConfigurationsController`, `TestDisplayController` inject repositories directly, bypassing the service layer for those specific calls). One cosmetic-only oddity: `WorkflowRepository`/`WorldTaskRepository` implement their interfaces via a fully-qualified name (`Interfaces.IWorkflowRepository`) instead of a `using` statement.

### 1.6 EF Core entities & relationships

`KnKDbContext` declares 35 `DbSet<T>` + 4 join/composite tables (`TownStreet`, `DistrictStreet`, `gate_structure_guard_spawn_locations`, `ItemBlueprintDefaultEnchantment`). Summary by cluster:

- **Accounts**: `User` (1→N `LinkCode`, Restrict; unique Username/Email/Uuid).
- **World hierarchy** (TPT inheritance — `Town`/`District`/`Structure` all inherit from `Domain`, each with its own table): `Domain` (1→1 `Location`, cascade) → `Town` (1→N `District`, N→N `Street` via `TownStreet`) → `District` (N→1 `Town` required/Restrict, N→N `Street` via `DistrictStreet`, 1→N `Structure`) → `Structure` (N→1 `Street` required/Restrict, N→1 `District` required/Restrict).
- **Siege/gates**: `GateStructure : Structure` (N→N guard-spawn locations, 1→N `GateDoor` cascade, N→1 icon material Restrict) → `GateDoor` (N→1 `GateStructure` cascade; 6 nullable `Location` FKs Restrict; N→1 material fallback Restrict; 1→N `GateBlockSnapshot`/`GateOpenedBlockSnapshot` cascade; unique `(GateStructureId, Name)`).
- **Items/abilities**: `Category` (self-referencing hierarchy, N→1 material icon Restrict), `ItemBlueprint` (N→1 material icon Restrict, N→N `EnchantmentDefinition` via `ItemBlueprintDefaultEnchantment` with a `Level` column), `EnchantmentDefinition` (N→1 `MinecraftEnchantmentRef` optional, 1→1 `AbilityDefinition` cascade), `AbilityDefinition` (1→1 `EnchantmentDefinition` unique FK; static `CanonicalCatalog` + idempotent `SeedCanonicalAsync` at startup), `MinecraftMaterialRef`/`MinecraftBlockRef`/`MinecraftEnchantmentRef` (DB-backed curated subsets, unique `NamespaceKey`) — distinct from the non-EF `MinecraftMaterialCatalogEntry`/`MinecraftEnchantmentCatalogEntry` POCOs loaded from `Data/*.json`.
- **Form builder**: `FormConfiguration` (1→N `FormStep` cascade, unique `ConfigurationGuid`) → `FormStep` (N→1 `FormConfiguration` cascade/nullable, 1→N `FormField` cascade, 1→N `StepCondition` cascade, self-referencing parent/child cascade, N→1 `SubConfiguration` Restrict optional, 1→N `DisplayConditionGroup`) → `FormField` (N→1 `FormStep` cascade/nullable, 1→N `FieldValidation`/`FieldValidationRule` cascade, self N→1 `DependsOnField` Restrict, 1→N `DisplayCondition` as `UsedInDisplayConditions` Restrict — "removing a field other conditions read must fail loudly"). `DisplayConditionGroup`/`DisplayCondition` target a step or field (cascade) and read another field's earlier value (Restrict). `FormSubmissionProgress` (N→1 `User` cascade, N→1 `FormConfiguration` cascade, self N→1 `ParentProgress` Restrict for nested sub-wizards; indexed on `ParentProgressId` and `(Status, CompletedAt)`).
- **Display templates**: `DisplayConfiguration` (1→N `DisplaySection` cascade; index `(EntityTypeName, IsDefault)`, `IsDraft`) → `DisplaySection` (N→1 config cascade/nullable, 1→N `DisplayField` cascade, self parent/sub-section cascade) → `DisplayField` (N→1 section nullable; supports `${...}` interpolation).
- **Misc**: `EntityTypeConfiguration` (standalone, unique `EntityTypeName`), `GameSettings` (singleton row `Id="global"`, several JSON blob columns), `WorkflowSession` (N→1 `User` cascade, optional N→1 `FormConfiguration` Restrict, 1→N `StepProgress`/`WorldTask`; **only entity with `[Timestamp] RowVersion`**), `StepProgress` (N→1 session cascade, unique `(WorkflowSessionId, StepKey)`), `WorldTask` (N→1 session cascade, optional N→1 assigned user Restrict; `[Obsolete]` `PayloadJson` still live — see below).
- **Non-DB POCOs** (no DbSet): `PagedQuery`/`PagedResult<T>`, `PlaceholderPath`, `MinecraftMaterialCatalogEntry`/`MinecraftEnchantmentCatalogEntry`, `Models/ClientActivity/*` (in-memory rate-limit/observability structs, never persisted).

**`WorldTask.PayloadJson`** — `[Obsolete("Use InputJson/OutputJson instead")]` (`Models/WorldTask.cs:38`) yet still actively read/written in `Mapping/WorkflowMappingProfile.cs:51,59`, `Controllers/WorldTasksController.cs:127,135`, `Services/WorldTaskService.cs:46,67,133`, `Properties/KnKDbContext.cs:812`, and `knkwebapi_v2.http:60,91`. This is an incomplete migration, not dead code — don't drop the column without confirming no live data still depends on it.

### 1.7 Migration history assessment

38 migrations from `20251223135917_InitialCreate` through `20260913154909_RenameGateDoorRegionFields`, chronologically clean, content matches names, and `KnKDbContextModelSnapshot.cs` matches current `Models/` (spot-checked). A ~5.5-month gap between `20260307161759_RefactorGateStructureLocationReferences` and `20260823125535_AddDisplayConditions` is consistent with the project's evenings/weekends cadence, not a red flag.

**Two anomalies**, both schema-correct but process-irregular:
- `20260131165938_AddGateAnimationSystem.cs` — missing its `.Designer.cs` companion; no `[Migration]`/`[DbContext]` attributes anywhere for it.
- `20260222161000_AddSubConfigurationIdToFormStep.cs` — also missing its `.Designer.cs`; unusually carries `[DbContext(typeof(KnKDbContext))]`/`[Migration(...)]` directly on the main class (normally Designer-file-only), suggesting it was hand-created or hand-patched rather than generated via `dotnet ef migrations add`.

### 1.8 Raw SQL / ORM bypass

None found. Repo-wide grep for `FromSqlRaw`, `FromSqlInterpolated`, `ExecuteSqlRaw`, `ExecuteSqlInterpolated`, raw `MySqlConnection`/`SqlConnection`, Dapper, `IDbConnection` returned zero matches. All 25 repositories use EF Core LINQ exclusively.

### 1.9 Integration with knk-plugin (summary — full detail in the architecture doc §6)

- **plugin → API** (dominant direction): hand-written OkHttp/Jackson REST client (`knk-api-client`) covering Users/Towns/Districts/Streets/Structures/Locations/EnchantmentDefinitions/ItemBlueprints/MinecraftMaterialRefs/Domains(partial)/GateStructures/GateDoors/WorldTasks/Health. Auth defaults to **no** bearer token (`config.yml` → `api.auth.type: none`); no login/refresh flow exists client-side, so a configured token would silently expire after the API's 30-minute access-token lifetime unless specially issued as long-lived.
- **API → plugin** (confirmed exception to the "no push" assumption in both repos' CLAUDE.md): `Services/RegionService.cs` calls into a `com.sun.net.httpserver.HttpServer` the plugin runs (`RegionHttpServer.java`, default port 8081) for WorldGuard region rename/containment checks.
- **Headless task polling**: `HeadlessWorldTaskPoller.java` polls every 5s (backing off to 60s idle) rather than being pushed to — flagged in the plugin's own code comments as a known gap, candidate for a future SignalR-based push.
- **Health check mismatch**: the plugin calls `api/Health` (`HealthController`, no dependency checks) via what its own comments call a guessed/unverified contract, rather than the API's real `health/live`/`health/ready` probes (`HealthCheckController`).

---

## 2. Legacy / orphaned code report

### 2.1 Orphaned services

- **`Services/DependencyPathResolver.cs`** — plain class, no interface, zero references anywhere in the repo outside its own definition. Appears superseded by `PathResolutionService`. Verify before deleting.
- **`Services/FieldValidationService.cs`/`IFieldValidationService`** — registered in DI by the reflection convention scan but never injected by any controller or service; its apparent purpose (execute field validations with placeholder resolution) looks fully duplicated by `ValidationService` + `PlaceholderResolutionService`, which the controller actually uses. Verify before deleting.
- **`DependencyInjection/ObservabilityServiceCollectionExtensions.cs`** — `AddObservability`/`AddOpenTelemetryInstrumentation` extension methods, never called anywhere; `Program.cs` duplicates the same logic inline.

### 2.2 Orphaned/duplicate DTOs

- **`Dtos/Forms/FieldValidationRuleDtos.cs`** (namespace `knkwebapi_v2.Dtos.Forms`) duplicates most of `Dtos/FieldValidationRuleDtos.cs` (namespace `knkwebapi_v2.Dtos`), including a `ValidateFieldDto` class that exists nowhere else. Repo-wide grep for `using knkwebapi_v2.Dtos.Forms` and `Dtos.Forms` found zero hits outside the file's own namespace declaration — every real consumer (`FieldValidationRuleService`, `IFieldValidationRuleService`, `FieldValidationRuleProfile`, `FieldValidationRulesController`) uses the top-level `Dtos` namespace exclusively. Strong deletion candidate, verify with the developer first in case it's a work-in-progress refactor target.
- No other superseded DTO duplicates were found among the ~35 files in `Dtos/`.

### 2.3 Dead/scaffolding controllers

- **`WeatherForecastController.cs`** — confirmed unmodified ASP.NET Core template boilerplate (`:21-31`, 5 rows of random fake data, non-standard route with no `api/` prefix). No caller anywhere. Safe to delete.
- **`TestDisplayController.cs`** (`api/test/*`) — a real, working integration-test harness against the Display* repositories, not disguised production logic. Its `DELETE api/test/cleanup` action bulk-deletes any `DisplayConfiguration` whose name contains `"Test"`, unauthenticated. Not dead code — a live footgun if ever reachable outside local dev. Recommend deleting or gating behind an environment check + auth before any shared/prod deployment.
- **`HealthController` vs. `HealthCheckController`** — not accidental duplication. `HealthController` is a legacy/ad-hoc ping the plugin happens to call via a guessed contract; `HealthCheckController` is the real infra-facing liveness/readiness surface with no found caller. Recommend pointing the plugin at `health/live` and retiring `HealthController` once that happens.

### 2.4 Config / package entries with no wiring

- **`Microsoft.EntityFrameworkCore.SqlServer`** (`knkwebapi_v2.csproj:21`) — zero `UseSqlServer`/SQL-Server-API usage anywhere. Confirmed unused; safe to remove. (This confirms the suspicion already noted in this repo's own `CLAUDE.md`.)
- **`Telemetry:Prometheus`** (`appsettings.json:48-51`, `appsettings.Development.json:34-37`, both `Enabled: true`) — deserializes fine via `TelemetryOptions.cs:58-68` but nothing in `Program.cs`/`DependencyInjection/` ever maps a `/metrics` endpoint; `Program.cs:186` has an explicit unresolved TODO. **This contradicts the claim in `knk-web-api/CLAUDE.md` and `OBSERVABILITY.md` that Prometheus metrics are exposed at `/metrics`** — that line is stale/aspirational and should be corrected in a documentation follow-up.
- Otherwise, `appsettings.json`/`appsettings.Development.json` are internally consistent with what `Program.cs`/DI actually binds — no other MySQL/Hibernate-era leftover keys found.

### 2.5 TODO / FIXME / commented-out code

| Location | Note |
|---|---|
| `Controllers/AdminClientsController.cs:12` | Stale TODO ("add `[Authorize(Policy="RequireAdmin")]` when auth is in place") contradicted by that exact attribute already present at line 20. |
| `Program.cs:147,186` | TODOs for real auth binding (placeholder `RequireAdmin` policy check works today but is explicitly called a placeholder) and for the never-implemented Prometheus exporter endpoint. |
| `Services/AuthService.cs:130,149` | TODOs re: refresh-token persistence/revocation "when repository is available" — refresh tokens are issued but not server-side revocable today. Security-relevant gap, not just dead code. |
| `Services/UserService.cs:480` | TODO: audit-trail logging (Phase 4, not implemented). |
| `Services/WorkflowService.cs:123` | TODO: step validation + draft persistence not implemented. |
| `Services/WorldTaskService.cs:559-573` | Commented-out validation loop; a `NOTE:` explains validation is currently a no-op stub — "we trust the plugin validation and return success." |
| `Repositories/FormStepRepository.cs:41`, `Repositories/FormFieldRepository.cs:39` | Identical TODO about future entity-type-tag filtering. |
| `DependencyInjection/ObservabilityServiceCollectionExtensions.cs:38-39,60-75` | Commented-out hosted-service registration (referenced `ClientActivityCleanupService` class not found in repo — unverified exhaustively) and a 12-line commented-out OTLP/Prometheus wiring block, both never activated. |
| `Models/Item/EnchantmentDefinition.cs:38-39` | Commented-out future `AppliedToInstances` navigation property — harmless forward-looking stub. |

No `#if false` blocks exist anywhere in the repo. `#pragma warning disable 612,618` only appears in EF-generated `*.Designer.cs`/snapshot files (normal boilerplate, not a cleanup target).

### 2.6 Stray files / dev-only scripts

- **`Prompts/REQUIREMENTS_DISPLPAYCONFIG_VERSION2.md`** (note the typo "DISPLPAYCONFIG") — confirmed **0 bytes**, a stray empty duplicate of `Prompts/REQUIREMENTS_DISPLAYCONFIG_VERSION2.md` (the real, 2,943-line authoritative spec, which itself supersedes the shorter `REQUIREMENTS_DISPLAYCONFIG.md` draft). Safe to delete.
- **`test-api.sh`, `test-phase3-4.sh`, `knkwebapi_v2.http`** — confirmed ad-hoc manual developer smoke-test scripts (curl-based) against a locally running instance. Confirmed **no `.github/workflows/` directory and no CI config of any kind exists in this repo** — none of these three files are wired into any build/CI step.
- **141 leftover `Console.WriteLine("[VALIDATION_TRACE_BACKEND] ...")` debug-trace statements** across `Services/ValidationMethods/RegionContainmentValidator.cs` (53), `Services/RegionService.cs` (38), `Services/ValidationMethods/LocationInsideRegionValidator.cs` (29), `Services/ValidationService.cs` (21) — functionally harmless but worth a cleanup pass; looks like leftover ad-hoc debug tracing alongside the proper `ILogger` calls.

### 2.7 Auth lifecycle gap (flagged during the plugin-integration check, not strictly "dead code" but relevant to correctness)

The plugin's bearer token is a statically-configured value in `config.yml` with no login/refresh flow anywhere in `knk-api-client`. The API's access tokens expire after 30 minutes (`Security:Jwt:AccessTokenMinutes`), and server-side refresh-token revocation is itself an unimplemented TODO (`AuthService.cs:130,149`). A standard 30-minute JWT pasted into the plugin's config would start failing an hour into a Minecraft server's uptime unless a specially-issued long-lived token is in actual use — this could not be confirmed from the code alone and needs an operational check.

---

## 3. Items needing human follow-up (uncertain / needs a decision)

1. **Confirm whether the plugin's configured bearer token is a normal 30-minute JWT or a specially-issued long-lived one** — §2.7. If it's a normal token, plugin↔API auth is silently broken most of the time in production.
2. **Decide the fate of `TestDisplayController`** — it is live and destructive (`api/test/cleanup`), not just inert scaffolding. Needs a decision before any shared/prod deployment, not just a docs note.
3. **Update `knk-web-api/CLAUDE.md`, `knk-plugin/CLAUDE.md`, and `OBSERVABILITY.md`** — all three currently make claims contradicted by this scan: no API→plugin push channel (there is one, via `RegionService`↔`RegionHttpServer`) and Prometheus metrics exposed at `/metrics` (never wired up).
4. **Verify before deleting**: `Services/DependencyPathResolver.cs`, `Services/FieldValidationService.cs`/`IFieldValidationService`, `Dtos/Forms/FieldValidationRuleDtos.cs`, `Prompts/REQUIREMENTS_DISPLPAYCONFIG_VERSION2.md` (this one is 0 bytes — essentially risk-free), the `Microsoft.EntityFrameworkCore.SqlServer` package reference, `WeatherForecastController.cs`. All read as genuinely unused based on repo-wide reference search, but per audit convention this is "verify," not a green light to delete unilaterally.
5. **`UsersController.CheckDuplicate` (`POST .../check-duplicate`) model-binding mismatch** — plugin sends query params + empty JSON body against a `[FromBody]` DTO parameter; this looks like it would fail to bind correctly. Worth an actual runtime check, not just a docs flag.
6. **Web-app client bugs** (§1.3) — four confirmed dead/broken client calls in `authClient.ts`/`displayConfigClient.ts`. These belong to the knk-web-app scan's legacy-code section too, but are noted here since they surfaced during this pass.
7. **No `[Authorize]` on almost any controller** — confirm this is an intentional trust model for now (pre-MVP, internal use) rather than an oversight, since it's broader than what the CLAUDE.md conventions imply.
