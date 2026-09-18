# knk-web-api — Reading Guide

**Status:** Living document — update in place
**Last updated:** 2026-09-18 (companion to `docs/architecture/web-api-architecture.md` and `docs/reports/web-api-scan-2026-09-18.md`)

Practical onboarding for a new session (human or agent) picking up work in `knk-web-api`. Read the architecture doc first for the big picture; this doc is about how to actually move around and change the code safely.

## Commands you'll actually use

- `dotnet restore` / `dotnet build` / `dotnet run` — the single Web SDK project at the repo root (`knkwebapi_v2.csproj`). `./run-with-swagger.sh` is the local dev helper.
- `dotnet test tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` — the test project is excluded from the main build via `DefaultItemExcludes`, so it won't build/run as part of a plain `dotnet build`/`dotnet run`.
- `dotnet ef migrations add <Name>` / `dotnet ef database update` — see the migration gotcha below before hand-editing anything migration-related.
- `test-api.sh` / `test-phase3-4.sh` / `knkwebapi_v2.http` at the repo root are **ad-hoc manual smoke-test scripts**, not part of any CI (there is no CI in this repo — no `.github/workflows/` exists). Useful for poking at a locally running instance, not for verifying correctness before a push.

## How to trace a feature end-to-end

Almost everything follows: `Controller` → `Service` (business logic + AutoMapper) → `Repository` (EF Core LINQ over `KnKDbContext`) → MySQL. Start at the controller for the feature you care about, follow the injected service interface into `Services/`, then the repository interface into `Repositories/`. Two controllers skip the service layer and inject repositories directly — `FormConfigurationsController` and `TestDisplayController` — don't be surprised if you can't find a service method for something they do.

If the feature touches validation, the extra hop is: `FieldValidationRulesController` → `ValidationService` → one of the 4 `Services/ValidationMethods/*` classes (`ConditionalRequiredValidator`, `ConditionalValueMatchValidator`, `LocationInsideRegionValidator`, `RegionContainmentValidator`), with `PlaceholderResolutionService`/`PathResolutionService` resolving `{Placeholder}` tokens and dependency-path expressions along the way. Don't confuse this with `Services/FieldValidationService.cs` — that's a second, apparently-dead implementation of overlapping functionality that no controller actually calls (see the scan report §2.1); the live path is `ValidationService`.

If the feature touches the dynamic form builder or entity display templates, `MetadataService` (reflection over `[FormConfigurableEntity]`-annotated models in `Attributes/FormConfigurationAttributes.cs`) is the thing that makes new entities "form-configurable" without per-entity boilerplate — check there before writing a new controller/service pair for a form-builder-adjacent feature.

## Where things actually live (vs. where you might guess)

- The `DbContext` is `Properties/KnKDbContext.cs` — not under `Data/` or `Models/`.
- `Data/` holds static JSON reference catalogs (Minecraft material/enchantment data), not the data-access layer. The catalog services (`MinecraftMaterialCatalogService`, `MinecraftEnchantmentCatalogService`, both singletons) load from there; the DB-backed `MinecraftMaterialRef`/`MinecraftEnchantmentRef`/`MinecraftBlockRef` tables are curated subsets validated against those catalogs, not the same data.
- `Prompts/` holds design-doc drafts, not prompt templates for an LLM feature — `REQUIREMENTS_DISPLAYCONFIG_VERSION2.md` is the current authoritative DisplayConfig spec; ignore the shorter `REQUIREMENTS_DISPLAYCONFIG.md` (superseded draft) and the 0-byte typo'd `REQUIREMENTS_DISPLPAYCONFIG_VERSION2.md` (stray duplicate, flagged for deletion in the scan report).
- There are **two health controllers** — `HealthController` (`api/Health`, no dependency checks, what the plugin currently calls via a guessed contract) and `HealthCheckController` (`health/live`/`health/ready`, checks DB connectivity, meant for external infra like k8s/docker healthchecks). If you're adding a new consumer that needs to know "is the API actually healthy," use `HealthCheckController`'s routes, not `HealthController`.

## Conventions to follow when adding a new feature

- **DTO naming**: one file per entity/feature in `Dtos/` (`<Entity>Dtos.cs`, usually containing the read DTO, `Create*Dto`, `Update*Dto`, and a list/paged variant). Don't create a second namespace-scoped duplicate the way `Dtos/Forms/FieldValidationRuleDtos.cs` did — that's flagged as dead code precisely because it forked instead of extending the existing `Dtos/FieldValidationRuleDtos.cs`.
- **Mapping**: one AutoMapper profile per feature area in `Mapping/`, registered automatically (check `DependencyInjection/ServiceCollectionExtensions.cs` for the AutoMapper assembly-scan setup) — you shouldn't need to hand-register a new profile.
- **DI registration**: `DependencyInjection/ServiceCollectionExtensions.cs` uses a reflection-based convention scan (classes ending in `Service`/`Repository` that implement a matching `I*` interface get auto-registered). This is why `FieldValidationService` ended up registered despite having no caller — the convention scan doesn't know a class is dead, it just registers anything shaped right. If you add a class that follows the naming convention but isn't meant for DI, either don't implement the interface pattern or explicitly exclude it.
- **Migrations**: always generate with `dotnet ef migrations add <Name>` and let it produce the paired `.Designer.cs` file. Two existing migrations (`20260131165938_AddGateAnimationSystem`, `20260222161000_AddSubConfigurationIdToFormStep`) are missing their Designer file, apparently from being hand-created/patched — their schema effect is correct, but don't treat them as a template for how to add a migration by hand; use the CLI tool.
- **Enum-backed columns**: most `GateDoor` enum fields use `HasConversion<string>()`, but `GateNameDisplayModeOverride`/`StatusDisplayModeOverride` are deliberately left int-backed — there's an in-code comment warning that converting them to string would corrupt existing data. If you touch that model, respect that split rather than "fixing" the inconsistency.
- **Obsolete-but-live fields**: `WorldTask.PayloadJson` is `[Obsolete]` but still read/written in ~5 places (mapping profile, controller, service, DbContext, manual `.http` tests). If you're touching `WorldTask`, migrate remaining `PayloadJson` usages to `InputJson`/`OutputJson` rather than adding new ones, but don't drop the column without confirming no live data depends on it.

## Auth model — what's actually enforced today

JWT bearer auth is configured globally (`Security:Jwt` in `appsettings.json`, HS256, 30-minute access tokens), but almost no controller actually requires it: only `AdminClientsController` (class-level `RequireAdmin` policy), `AuthController.Me`/`Update`, and `UsersController.LinkMinecraftAccount` have `[Authorize]` anywhere. Don't assume a new endpoint is protected just because the JWT middleware is registered — you need to add `[Authorize]` explicitly. Refresh tokens are issued but not server-side revocable yet (`AuthService.cs:130,149` are open TODOs) — keep that in mind if you're building anything that assumes a logout actually invalidates a refresh token.

## Integration points to know about before changing cross-repo contracts

- **knk-web-app** calls almost every controller directly over REST with a bearer token. Before renaming a route or changing a request/response shape, grep `knk-web-app/src/apiClients/*.ts` for it — and note that a few client calls are already broken today (`authClient.ts`'s `mergeAccounts`/`requestLinkCode`, `displayConfigClient.ts`'s `clone`/`addReusable*` — see the scan report §1.3), so "the web-app doesn't call this" isn't always evidence an endpoint is safe to remove; check both directions.
- **knk-plugin** calls this API via a hand-written REST client (`knk-api-client`), not an OpenAPI-generated one, so nothing here regenerates client code for you — a route rename requires a manual matching edit in `knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/*.java`.
- There **is** a reverse-direction call: `Services/RegionService.cs` calls out to a small HTTP server the plugin itself runs (`RegionHttpServer.java`, default port 8081) for WorldGuard region operations. If you're told "the API never pushes to the plugin," that's stale — this is the one confirmed exception, and both repos' CLAUDE.md files should eventually be corrected to mention it.
- The plugin's bearer token is a static value in its `config.yml` with no refresh flow — if plugin↔API calls start failing intermittently in a way that smells like auth, check token expiry before assuming it's a network/config issue (see the scan report §2.7 for why this is flagged as an open question rather than a confirmed bug).

## Things that look risky but are real, working code (don't "clean up" without a decision)

- `TestDisplayController` (`api/test/*`) is a live integration-test harness, and its `DELETE api/test/cleanup` action does an unauthenticated bulk-delete of any `DisplayConfiguration` whose name contains `"Test"`. It's not hypothetically dangerous — it works today. Don't assume "test" in the name means safe to ignore in a security pass.

## Where to go next

- Full endpoint/service/repository/entity tables with file:line citations: `docs/reports/web-api-scan-2026-09-18.md`.
- Big-picture architecture, data flow, and cross-repo integration narrative: `docs/architecture/web-api-architecture.md`.
- Before starting new work, check `docs/ACTIVE_SESSIONS.md` for anything overlapping your intended scope, per the global agent instructions.
