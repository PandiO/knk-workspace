# knk-web-api — Architecture

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-11-13 (`StepConditionHealth` in the configuration health check, #88 in `next` `31abe2d`, docs #395); 2026-11-13 (§5.1/§5.3: create, edit and link changes need the write node and `knk.admin.content`, `ChangeNodes`, `RequireDashboardChange`, #374 in `next` `b65e66d`, docs #385); 2026-11-13 (§5.1/§5.2 merged: AM1+AM2 in `master` `bc97b7d`, AM3 in `45043a7`; §5.1 configuration deletes need `knk.admin.delete`, bulk-delete refusal codes — docs #366); 2026-11-12 (§5.3–§5.5 and §6 web live updates merged 2026-11-12 in `master` `bc97b7d`, §6 web audience per area node since AM1 — docs #341, #343–#345); 2026-11-06 (§6: `Realtime:WebLiveUpdatesEnabled` switch, #183); 2026-11-05 (§6: web live updates, `EntityChanged`/`PresenceChanged` gated per node — #183, branch `claude/realtime-web-live-183`); 2026-11-09 (§5.5 form and display builder drafts, Publish and Duplicate, #71 — branch `claude/builders-71`, not merged); 2026-11-09 (§5.4 what still uses a record, rows behind a refused delete's "Show details", #44 — branch `claude/picker-details-191-44`, not merged); 2026-11-09 (§5.3 relationships for the entity detail page, #188 — branch `claude/entity-detail-188-189`, not merged); 2026-11-08 (§5.2 read gating per area and lookups, AM2 of #280 — branch `claude/dashboard-access-280`, not merged); 2026-11-08 (§5.1 dashboard access model, AM1 of #280 — branch `claude/dashboard-access-280`, not merged); 2026-11-05 (#239 offer permission check, #240 Send again merged); 2026-11-04 (#239, #240 on a feature branch); 2026-11-02 (§6: config and entity events, `ReportWorlds` — #182, branch `claude/realtime-signalr`); 2026-11-02 (§6: world tasks over the hubs, presence endpoints — #181, branch `claude/realtime-signalr`); 2026-11-01 (world-task state machine, task codes, sweep, tasks anchored to the draft — #180, branch `claude/world-task-hardening`); 2026-10-26 (§6: realtime hubs, #178 S1 and #179 S2 on a feature branch); 2026-09-18 (based on a full read-only code scan; see `docs/reports/web-api-scan-2026-09-18.md` for the raw findings this doc summarizes); spot edits 2026-10-12 (FormField selection limits, KNG-164; created-entity provenance, reference check and DELETE 409 filter, KNG-162; FormConfiguration export/import and bundled seeds, KNG-138; the first seeds and stronger seed tests, KNG-139); 2026-10-26 (drafts and workflow sessions owned by the logged-in caller, PandiO/knk-workspace#186); 2026-10-17 (form wizard chain merged to `master`; smoke-test follow-ups: refusal reasons, KNG-169; FormConfiguration delete, KNG-172; region rule messages, KNG-173; validation result metadata, GateStructure house number, rule dependency path on update); 2026-10-22 (KNG-139 priority 2/3 seeds and DisplayConfiguration export/import; KNG-195 form submit fixes; gate warp settings, KNG-229); 2026-10-23 (step condition / field validation `IsActive`, KNG-186); 2026-10-23 (validation result log and validate-batch, KNG-269); 2026-10-25 (§6 plugin auth, health probe and RegionHttpServer callers corrected from the SignalR inventory); 2026-11-04 (ConditionalRequired ConfigJson contract, `FieldValidationService` removed, PandiO/knk-workspace#99)

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
- **Validation pipeline**: `ValidationService` dispatches to 4 `IValidationMethod` implementations (`ConditionalRequiredValidator`, `ConditionalValueMatchValidator`, `LocationInsideRegionValidator`, `RegionContainmentValidator`), with `PlaceholderResolutionService`/`PathResolutionService` resolving `{Placeholder}` tokens and dependency-path expressions used in validation messages. A dependency that holds only an id is replaced by the saved record for the validator (`ResolveDependencyRecordAsync`), but the result's `Metadata.DependencyValue` echoes the value the form sent: a tracked entity can carry navigations that point back at each other and failed to serialise ("possible object cycle"). A failed `RegionContainment`/`LocationInsideRegion` rule appends what it must be inside ("Must be inside District "The Keep" (region district_1000006).", `ValidationMethods/RegionRuleMessages.cs`, KNG-173); "wrong world" and "region doesn't exist" can't be told apart from "outside" yet (KNG-187). `UpdateFieldValidationRuleDto` carries `DependencyPath` (it was dropped on update before 2026-10-17). **Result log** (KNG-269): `ValidationService` keeps the most recent run of each rule per *subject* (the entity being edited, or the draft `FormSubmissionProgress` before it exists; the request's `subjectType`/`subjectId`, without which nothing is stored) in `FieldValidationRunLogs` (`Models/FormConfiguration/FieldValidationRunLog.cs`, `Services/ValidationResultLog/`, migration `AddFieldValidationRunLogs`, unique on rule + subject, cascade from the rule). A run is answered from the row while its `RuleHash` (SHA-256 over type, canonical `ConfigJson`, dependency field/path, blocking, messages) and `InputHash` (canonical JSON of the field value plus the resolved dependency reduced to the properties the validator declares in `IValidationMethod.DependencyPropertiesRead`) still match; a validator with `ReadsExternalState` (the two region validators) has its rows expire after `ValidationResultLog:ExternalStateTtlHours` (24). `force` on the request bypasses the lookup (the wizard's Re-check), `Metadata.FromCache`/`ExecutedAt` tell the caller, a "couldn't check" result (`FailureReason`) is never stored, and `DomainRegionNameFinalizer` drops the rows about a domain whose region changed. `POST validate-batch` validates every rule-bearing field of a step in one request. `SavedEntityRuleValidator` (readiness) passes no subject, so it always runs live. Rows older than `RetentionDays` (30) are purged on the hour. A separate, apparently-unused `FieldValidationService`/`IFieldValidationService` exists and looks like a superseded duplicate of this same responsibility (no controller injects it — see §6).
  - `ConditionalRequiredValidator` and `ConditionalValueMatchValidator` share one condition vocabulary (`Services/ValidationMethods/ConditionOperators.cs`: `equals`, `notEquals`, `greaterThan`, `lessThan`, `contains`, `in`), case-insensitive and compared by text, so a config's `true` matches a form's `"true"`. ConditionalRequired's ConfigJson is `{"condition":{"op","value","property"?}}` (developer decision 2026-11-04, PandiO/knk-workspace#99); `property` picks the field of a loaded dependency record (default `Id`). The older flat `{"operator"/"op","value"}` form is still read.

## 4. EF Core / database layer

`Properties/KnKDbContext.cs` declares 35 `DbSet<T>` entities plus 4 many-to-many/composite join tables configured inline (`TownStreet`, `DistrictStreet`, `gate_structure_guard_spawn_locations`, `ItemBlueprintDefaultEnchantment`). Charset/collation: `utf8mb4_general_ci`/`utf8mb4`.

Key structural facts worth knowing before touching the model:

- **`Domain` is a TPT (table-per-type) base**: `Town`, `District`, and `Structure` all inherit from `Domain` (each with its own `ToTable()`), not TPH — a query against `Domain` alone won't see subtype-specific columns without EF Core issuing the corresponding join.
- **Siege/gate cluster**: `GateStructure : Structure` → 1→N `GateDoor` (cascade) → 1→N `GateBlockSnapshot`/`GateOpenedBlockSnapshot` (cascade, two separate tables by design, not a discriminator). `GateStructure` has many nullable `*Override` fields that cascade down to its doors when set. `GateDoor` deliberately keeps `GateNameDisplayModeOverride`/`StatusDisplayModeOverride` as int-backed enums (not `HasConversion<string>()` like its siblings) — there's an explicit in-code comment warning that string-converting them would corrupt existing data. Don't "fix" that inconsistency without a data migration.
- **Form-builder cluster**: `FormConfiguration` → `FormStep` (self-referencing parent/child for reusable sub-wizards, plus an optional `SubConfiguration` link) → `FormField` (self-referencing `DependsOnField`) → `FieldValidation`/`FieldValidationRule`. `StepCondition` and `FieldValidation` carry an `IsActive` column (KNG-186, migration `FormConditionAndValidationIsActive`, default true so existing rows stay active): before 2026-10-23 the flag existed on the DTOs only and `FormMappingProfile` ignored it, so the API sent `isActive: false` for every condition and validation and the web app, which runs a condition only while it is active, never ran a step completion condition. It is mapped both ways (absent in a request = active), kept by `FormConfigurationRepository.UpdateAsync`, `FormTemplateReusableService` and export/import (written only as `"isActive": false`, so older seed files are unchanged and import as active). `FormConfigurationDto.IsActive` was dropped: `FormConfiguration` has no such column and nothing read it. `DisplayConditionGroup`/`DisplayCondition` attach to either a step or a field and read another field's value earlier in the form. `FormSubmissionProgress` belongs to the logged-in caller (#186): `POST api/FormSubmissionProgress` takes the owner from the JWT (`ClaimsPrincipal.GetUserId`) and ignores the body's `userId` (401 without a user); `GET .../entity?mine=true` (or the old `userId` parameter, whatever its value) and `GET .../user` list the caller's rows only; without `mine`/`userId` the list shows every owner (the relationship-drafts view, which names the owner); an update keeps the stored owner. Before the fix the web app sent `userId = 1` for everyone; `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql` (knk-workspace) removes those rows once. `FormSubmissionProgress` supports nested sub-form wizards via a self-referencing `ParentProgress`; a root progress records what its child forms created in the nullable `CreatedEntitiesJson` (KNG-162, migration `AddFormSubmissionProgressCreatedEntities`; written by the web app, an update without it keeps the stored value). `EntityReferenceService` (`GET api/FormSubmissionProgress/entity-references/{type}/{id}?ignore=Type:id`) counts every row that still references an entity, generically over the EF model (plain FKs whatever their delete behaviour, many-to-many join rows; owned types excluded), and the global `DeleteConstraintExceptionFilter` turns a `DbUpdateException` on any DELETE, and EF's "association has been severed" `InvalidOperationException` (a required relationship of a tracked dependent, e.g. a Street loaded with its Structures), into 409 `DbConstraint`. Its message names what still uses the item, from the same reference check with `blockingOnly: true` ("This street can't be deleted: it is still used by 1 structure. …", KNG-169); the generic text stays when the entity or check can't be resolved. A primary-key link between a table-per-type subtype and its base (District.Id → Domain.Id) is not counted as a use. Controllers leave such refusals to the filter (LocationsController keeps its own `LocationInUseException` 409). `FormField` stores `MinSelection` / `MaxSelection` / `CanCreate` / `IncrementValue` as nullable columns (KNG-164, migration `AddFormFieldSelectionLimits`; before that they were DTO-only and dropped on save); `FormConfigurationRepository.UpdateAsync` and `FormTemplateReusableService` copy fields property by property, so a new `FormField` column must be added there too — and to `FormConfigurationPortabilityService` (export and import copy fields property by property as well).
- **FormConfiguration export/import** (KNG-138, spec `specs/form-configurations/DEFAULT_FORM_SEEDS.md` §3): `FormConfigurationPortabilityService` writes and reads portable `knk-formconfig/1` files (`Dtos/FormConfigurationPortableDtos.cs`): GUIDs instead of ids, array order = step/field order, display conditions by source field GUID, validation rules with `dependsOn` = a field GUID (plus `configurationGuid` for a field of another configuration, e.g. a parent form), `subConfigurationRef` by `configurationGuid`. Endpoints on `FormConfigurationsController`: `GET {id}/export`, `POST import?dryRun=&makeDefault=`, `GET seeds`, `POST seeds/{name}/import` (writes behind `knk.admin.content`, the class rule). Import never overwrites (an existing `configurationGuid` → 409 `AlreadyImported`, nothing written), resolves every reference and runs `FormTemplateValidationService` before writing (400 `Invalid` lists every problem), builds the configuration through `FormConfigurationRepository.AddAsync`, then adds the validation rules, all in one transaction (relational providers); `IsDefault` only when the entity has none or `makeDefault=true` (old default unset in the same transaction). Bundled seeds are the `*.json` files in `Data/FormConfigurationSeeds/` (content root; copied to the build/publish output like the other `Data/` catalogs), imported on request only; `FormConfigurationSeedFilesTests` dry-runs and imports every file in dependency order, and checks that each imports without warnings, has every foreign key the entity needs on create (or lists why not) and resolves its references. Seeds shipped (KNG-139): GateStructure (no House number: `GateStructureDto.HouseNumber` is nullable, null = not on the form, a new gate keeps 0 and an update keeps the stored number; seed v2 adds the warp, /navigate and road-access fields, KNG-229, and `GateStructureService` applies the warp settings like `StructureService`), GateDoor and the siege set; since 2026-10-22 also the priority 2/3 set (domain family, people, items, kits and lootboxes, 30 files). List and import order in the folder's README; per-step changes and decisions in `reports/2026-10-19-kng-139-seed-review-notes.md`.
- **DisplayConfiguration export/import** (follow-up to KNG-138/139, merged 2026-10-22; format spec = knk-web-api `Data/DisplayConfigurationSeeds/README.md`): `DisplayConfigurationPortabilityService` writes and reads `knk-displayconfig/1` files (`Dtos/DisplayConfigurationPortableDtos.cs`): section/field GUIDs, array order = section/field order, sub-sections nested. Endpoints on `DisplayConfigurationsController`: `GET {id}/export`, `POST import?dryRun=&makeDefault=&asDraft=`, `GET seeds`, `POST seeds/{name}/import` (writes behind `knk.admin.content`). Same rules as the form import: never overwrites a `configurationGuid` (409 `AlreadyImported`), default only when the entity has none or `makeDefault=true`, published unless `asDraft=true`. Fields and sections are checked against the model through `MetadataService`; an element marked `metadataCheck: "warn"` (it follows the read DTO on purpose) only warns. Seeds: `Data/DisplayConfigurationSeeds/*.display.json` (7 files); `DisplayConfigurationSeedFilesTests` imports each and checks that only "warn" elements warn and that export gives the file back.
- **Form submit binding (KNG-195):** `Json/NullableEnumConverterFactory` (registered before `JsonStringEnumConverter`) reads `""` as null for every nullable enum, so the wizard's empty Enum option no longer fails the whole body. `UserDto` → `User` ignores the freeze, email-verified and created-via fields and writes Gender / IsActive / gate pass-through only when sent. `StructureDto` carries an inline `location` (created or updated like a gate's). ItemBlueprint/Category accept `iconMaterialRefNamespaceKey` and EnchantmentDefinition `minecraftEnchantmentRefNamespaceKey` for catalog rows that aren't saved yet; an EnchantmentDefinition update without `abilityDefinition` keeps the ability.
- **FormConfiguration delete** (KNG-172, `FormConfigurationRepository.DeleteAsync`): one SaveChanges that detaches the configuration's `WorkflowSession`s (history kept), removes its drafts and the sub-form drafts under them at any depth, and removes the validation rules and display conditions of its own steps and fields first (rules with `DependsOnFieldId` and conditions with `SourceFormFieldId` on the same configuration are Restrict and required, so EF and MySQL refused to delete the fields otherwise). Only a real use refuses the delete: another configuration opening it as a sub-form, or a rule/condition elsewhere reading one of its fields.
- **`WorkflowSession`** belongs to the logged-in caller who starts it (`POST api/Workflows` replaces the body's `userId` with the JWT user, #186); only a game-server call without a user names the owner in the body (and must). The API creates catalog-scan sessions itself for the requesting admin. It is the only entity with a `[Timestamp] RowVersion` (optimistic concurrency) — a deliberate choice given it drives the plugin/web-app hybrid create-edit workflow (see §5).
- **World tasks** (PandiO/knk-workspace#180, branch `claude/world-task-hardening`, not merged): `WorldTaskService` is a state machine (`Models/WorldTask.cs` `WorldTaskStatuses`: Pending → InProgress → Completed/Failed, release → Pending, cancel → Cancelled, expiry → Expired) with `Status` as concurrency token plus a `RowVersion`, so a second claim or a lost race answers 409 (`WorldTaskConflictException`) and a refused result 422 (`WorldTaskRejectedException`). The task code (`LinkCode`) comes from `RandomNumberGenerator`, is unique among open tasks and checked on a code claim; claim modes code/id/headless/offer. New columns: creator from the JWT, claimer uuid/user, `ExpiresAt`, `LeaseUntil`, `ReleaseCount`, `FormSubmissionProgressId`, `AppliedAt`, the WT2 offer columns; `FormSubmissionProgress.WorkflowSessionId` (one session per draft). `WorldTaskSweepService` (section `WorldTasks`) expires, releases lapsed leases and removes abandoned sessions. Reference: [`specs/world-tasks/README.md` § Lifecycle](../specs/world-tasks/README.md#lifecycle-and-endpoints-pandioknk-workspace180).
- **Item/ability cluster**: `ItemBlueprint` ↔ `EnchantmentDefinition` via `ItemBlueprintDefaultEnchantment` (composite key, extra `Level` column); `EnchantmentDefinition` 1↔1 `AbilityDefinition` (custom-ability extension, with a static `CanonicalCatalog` + idempotent `SeedCanonicalAsync` run at startup).
- **`WorldTask.PayloadJson`** is marked `[Obsolete("Use InputJson/OutputJson instead")]` (`Models/WorldTask.cs:38`) but is still actively read/written in `WorkflowMappingProfile.cs`, `WorldTasksController.cs`, `WorldTaskService.cs`, `KnKDbContext.cs`, and the manual `.http` test file — treat this as a migration-in-progress, not dead code; don't remove the column without confirming no rows still depend on it.

**Migration history**: 38 migrations, chronologically clean (no out-of-order timestamps, content matches names, snapshot matches current `Models/`) with one caveat — `20260131165938_AddGateAnimationSystem.cs` and `20260222161000_AddSubConfigurationIdToFormStep.cs` are both missing their `.Designer.cs` companion, and the latter has its `[Migration]`/`[DbContext]` attributes unusually inlined into the main file rather than in a Designer file. This suggests both were hand-created/patched rather than produced by `dotnet ef migrations add`; their actual schema effect is correct and reflected in `KnKDbContextModelSnapshot.cs`, so this is a hygiene note, not a correctness bug — see the reading guide before adding a new migration by hand.

## 5. Talks to knk-web-app

Browser clients call the API over REST with a bearer token attached (`src/services/serviceCall.ts` on the web-app side). Every controller except `AdminClientsController`, `AuthController.Me`/`Update`, and `UsersController.LinkMinecraftAccount` has **no** `[Authorize]` attribute — JWT bearer auth is configured globally but most actions don't actually require it. This is broader than the CLAUDE.md's implication that JWT auth gates the API generally; verify with the developer whether this is intentional (internal-tool-style trust) or a gap before shipping wider access.

The web-app is the primary caller for almost every CRUD controller (Towns/Districts/Streets/Structures/Categories/DisplayConfigurations/FormConfigurations/GameSettings/etc.) and for the form-builder/validation/workflow machinery. See the endpoint table in the scan report for the full caller breakdown, including several confirmed **broken web-app client calls** (routes the frontend posts to that don't exist server-side — e.g. `authClient.ts`'s `mergeAccounts` posts to a non-existent `api/Auth/merge` instead of the real `api/Users/merge`).

### 5.1 Dashboard access model (PandiO/knk-workspace#280; AM1 merged 2026-11-12, AM3 2026-11-13)

Design: [specs/dashboard-access-model/DESIGN.md](../specs/dashboard-access-model/DESIGN.md) (model A, decided 2026-11-08).
AM1 built the **actions**, AM2 the read gating per area and the lookup endpoints (§ 5.2), AM3 the web app (see
[web-app architecture](web-app-architecture.md#dashboard-access-model-in-the-web-app-pandioknk-workspace280-am3-205-bulk-delete))
and two small API changes below. Merged: AM1+AM2 in `master` `bc97b7d` (2026-11-12), AM3 in `45043a7` (2026-11-13);
deploy the API before the web app. **Not live-tested:** the [smoke test](../guides/dashboard-access-smoke-test.md) is
in closed alpha test run 2 (checklist § 4c). Admin view: [dashboard access admin guide](../guides/admin/dashboard-access-admin-guide.md).

- **Nodes** (`StaffPermissions`): `Delete = knk.admin.delete` (delete one), `DeleteBulk = knk.admin.delete.bulk`,
  `Export = knk.admin.export`. The area nodes mean view in their area, and create and edit together with
  `knk.admin.content` since #374 (see **Create, edit and link changes** below):
  `knk.admin.content`, `knk.admin.world`, `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`,
  `knk.admin.road`, `knk.admin.user.manage` (`knk.admin.user.perm` for permission-group writes).
- **Registry** `Attributes/DashboardAccess.cs`: one entry per `[FormConfigurableEntity]` type, plus `RoadProfile`.
  Each holds the area, area node, write node, read nodes (area node first, then the cross-area page nodes of the
  design's § 4.6.2, enforced from AM2), whether it is deletable and bulk deletable, and delegates to the type's own
  delete and search (the same service calls as its `DELETE {id}` and `POST …/search`). Link rows, snapshots and other
  `[FormConfigurableEntity]` types are view-only entries. `Security/DashboardAccessTests` pins the coverage.
- **Create, edit and link changes (PandiO/knk-workspace#374, in `next` `b65e66d` 2026-11-13, PR knk-web-api#15; not
  yet on `master`; not live-tested, [smoke test § 2.2](../guides/dashboard-access-smoke-test.md#22-create-edit-and-link-changes-need-knkadmincontent-374)):**
  developer decision 2026-11-13, "Area staff should not be able to change forms at this point. They only work with the
  content available." Each registry entry has `ChangesNeedContent` (default true) and `ChangeNodes`: all-of
  `[WriteNode, knk.admin.content]` (just the write node when that is `knk.admin.content` already, or when
  `changesNeedContent: false`). **Exempt:** `User` (Edit is the player profile, its own endpoints),
  `PermissionGroup`, `PermissionHolder`, `PermissionGrant`, `UserPermissionGroup` (`knk.admin.user.perm` with the
  escalation guard) and `RoadProfile` (the roads page edits it; no form).
  - `[RequireDashboardChange("<Type>")]` (`Attributes/RequireDashboardChangeAttribute.cs`, `DashboardChangeFilter`, an
    `IKnkAccessRule`) sits on the **primary create and update action** of 29 types, next to the controller's own area
    rule: the Content, World, Kits, Lootboxes and Siege types of the registry (BannerLayer and DomainSubRegion
    included). It reads the entry at request time: the plugin key passes (the game server checks its own nodes),
    anonymous → 401, an unknown type name → 403 "This endpoint has no access rule." (fails closed), a missing node →
    403 `{ error: "Forbidden", code: "NoWriteAccess", entityType, nodes, message }`, message "Creating or editing Town
    requires knk.admin.world and knk.admin.content.". `Security/DashboardChangeAccessRulesTests` pins the endpoint list
    and the filter.
  - **Only the primary create/update.** Other writes of a type keep their own rules: gate door state, a domain's world
    backfill, lootbox in-game spawn areas, delete, bulk delete, export, reads, lookups, the player profile's freeze,
    balance, kick and ban. A per-action attribute rather than the class-level write rule, because that rule also
    covers delete (decision in the "Link #374" block of the [chain 3 report](../reports/2026-11-08-ux-chain-3.md)).
  - The **metadata's** `actionNodes.create`/`edit` and every relationship's `nodes` (§ 5.3) are `ChangeNodes`, so the
    web app's gates and the API agree. No migration and no setting; no config switch (alternative (b) of #374 not
    taken).
  - Two pages outside the form wizard use these endpoints and aren't gated beforehand: the lootbox Enable/Disable
    toggle (`PUT api/LootboxTypes/{id}`) and the roads page's "New street" (`POST api/Streets`):
    [#383](https://github.com/PandiO/knk-workspace/issues/383).
- **Single delete:** every deletable type's `DELETE {id}` carries `RequireServiceOrPermission(Delete)`
  (`RequirePermission` on the lootbox controllers) on top of its class or method area rule, so a delete is area node
  AND `knk.admin.delete`; users (`knk.admin.user.manage`) and permission groups (`knk.admin.user.perm`) included.
  `Security/DeleteAccessRulesTests` pins the primary delete per type and an exemption list for every other DELETE
  (builder parts, menus, drafts, world-task/workflow lifecycle, link deletes, plugin-only and player-own deletes).
  **Configuration deletes (AM3, LV7-8, developer decision 2026-11-12):** `DELETE api/FormConfigurations/{id}` and
  `DELETE api/DisplayConfigurations/{id}` also carry `RequireServiceOrPermission(Delete)`, so deleting a whole
  configuration is `knk.admin.content` AND `knk.admin.delete` (pinned in `ConfigurationDeletes`); deleting a step,
  field, section or rule inside a builder stays exempt.
- **`POST api/Dashboard/bulk-delete`** (`DashboardController`, web users only): `RequirePermission(DeleteBulk)` and
  `RequirePermission(Delete)`, then the type's area node in the action (403), `bulkDeletable` (400
  `BulkDeleteNotAllowed` for users, permission groups and view-only types), 1–100 distinct positive ids (400), unknown
  type 404. `DashboardActionService` deletes each id through the type's own delete in its **own DI scope**, so a refused
  row doesn't poison the next save; the answer is `{ deleted: [id], refused: [{ id, reason, code }] }` with the single
  delete's wording (not found; the business rule's message; the `DeleteConstraintExceptionFilter` "still used by …"
  text from `EntityReferenceService`; a generic text for anything else, never the exception's). `code` (AM3, additive;
  `DashboardBulkDeleteRefusalDto`) is `InUse` (still used: the web app offers "Show what uses it"), `NotFound`,
  `Refused` (a business rule) or `Failed`. One `AuditLogEntry`
  `DashboardBulkDelete` (target = actor; type, requested, deleted ids, refused count). Rate limit: the `lookup` policy.
  Each row is its own save, so realtime sends one `EntityChanged` per row.
- **`POST api/Dashboard/export`** (web users only): `RequirePermission(Export)` and the area node in the action. Body
  `{ entityType, ids?, query?: { searchTerm, filters, sortBy, sortDescending } }`; reads the type's own search in pages
  of 500 in the requested sort, at most 10 000 rows (`truncated: true` beyond); with `ids` it scans the search (with the
  query, if given) for those rows and returns them in its order (scan limit 100 000 rows). Answer
  `{ items, total, truncated }`, rows exactly as the type's search returns them (the web app formats the CSV with the
  table's columns). 400 for a type without a search (`RoadProfile`, link rows) and for more than 10 000 ids. One
  `AuditLogEntry` `DashboardExport` (type, scope `selection`/`search`, count, truncated; never the rows).
- **Metadata** (`EntityMetadataDto`, `GET api/Metadata/entities…`): `area`, `accessNode`, `writeNode`, `readNodes`,
  `deletable`, `bulkDeletable`, `exportable`, `lookupSearchable`, `lookupGettable` (AM2) and `actionNodes` (`view`
  (AM2: the area node, the dashboard lists the type), `create`, `edit` (= `ChangeNodes` since #374), `delete`, `bulkDelete`, `export` → every node
  the action needs; an action the type doesn't allow is left out), from the registry.
- **Escalation guard** (`PermissionEscalationGuard`): `OwnerGrantOnly = { knk.admin.delete.bulk }`. Granting,
  denying or revoking it, or a wildcard that covers it by the resolver's rules (`*`, `knk.*`, `knk.admin.*`,
  `knk.admin.delete.*`, also `x.*` for the bare `x`), needs `*` ("Only the owner can hand out bulk delete."); so do
  assigning a group and inheriting from a group whose granted chain covers it (premium ranks included). So **Admins
  can no longer grant `knk.admin.*`** or hand out a group carrying it. `knk.admin.delete` and `knk.admin.export` stay
  grantable by anyone who holds them. **Rank (developer 2026-11-08, Staff):** besides handing out and removing
  groups, a web user now also changes a group's grants (`CanGrantNodeAsync` on a group holder) and creates, edits or
  deletes a group (`CanChangeGroupAsync`, the group as it is and its new Weight) only below their own highest group.
- **Migration `SeedDashboardActionNodes`** (data only): Admin gets the three nodes unless its chain decides them (the
  alpha: `knk.admin.*`, nothing added); every group and user with an active explicit area-node grant gets
  `knk.admin.delete` and `knk.admin.export`, **except the Staff group**; a holder whose chain (for a user: own grants,
  then every active group and its parents) has a grant, deny or covering wildcard is skipped. Bulk delete is never
  backfilled. Down removes only value-1 grants without expiry.
- **Realtime:** `RealtimeWebChangeMap.NodeFor` returns the type's **area node** (a base type's event, `Domain` for a
  saved `Town`, uses the base type's area), so live updates follow the area; users, memberships, grants and the audit
  log stay on `knk.admin.user.manage`, `NotSent` types unchanged. Delete nodes don't change the audience.

### 5.2 Read gating per area and lookups (PandiO/knk-workspace#280, AM2, merged 2026-11-12)

Design § 4.6 and Appendix A. Before AM2 every dashboard read was open to any logged-in user (the default rule); now
each read endpoint has exactly one **category**, worked out from its attributes by `ReadAccess.Of`
(`Attributes/ReadAccess.cs`) and pinned per endpoint in `Security/ReadAccessRulesTests` (298 read endpoints: every
GET/HEAD, every POST search and every POST that carries a read rule of its own; a new one fails the test until it is
pinned):

| Code | Category | Rule | Count |
|---|---|---|---|
| F | full read | `[DashboardReads("<Type>")]` on the controller (or the action): one of the type's **read nodes** (area node + the design's § 4.6.2 page nodes), or the plugin key. Records outside the registry read with an area: `[DashboardReads(DashboardArea.Content)]` (menus, builder export/seeds), `World` (world-task lists, the domain admin reads) | 101 |
| L | lookup | `[RequireServiceOrAnyAreaNode(ReadCategory.Lookup)]`: any area node or the plugin key (`api/Lookup`, `Clans/default-for-town`) | 3 |
| R | form runtime | `[RequireServiceOrAnyAreaNode]`: form/display configurations, steps, fields, sections, entity type configuration, metadata, validation rule GETs and the validation/resolve POSTs, banner pattern keys, workflow health | 43 |
| O | own records | any area node + the ownership the action checks: drafts `[RequireAnyAreaNode]` (web only, was `knk.admin.content`), own world tasks and workflow sessions `[RequireServiceOrAnyAreaNode(ReadCategory.OwnRecords)]` | 13 |
| P | public | `[AllowAnonymous]`, unchanged (leaderboards, statistics, players, public siege matches, enchantment info, health, auth) | 16 |
| G | game server | `[RequirePluginService]`, unchanged | 13 |
| U | stricter | the action's or controller's own rule, unchanged (lootboxes, users and groups, self reads, currency admin, owner nodes, `[Authorize]`) | 83 |
| D | outside the model | the default rule, unchanged: reads that aren't dashboard types (game, siege, salary and navigation settings, currency of a player, roads other than profiles, title brackets, siege match history, presence `me`) | 26 |

- **"Any area node"** is `DashboardAccess.AreaNodes`: `knk.admin.content`, `knk.admin.world`, `knk.kit.manage`,
  `knk.admin.lootbox.manage`, `knk.siege.admin.manage`, `knk.admin.road`, `knk.admin.user.manage`.
- **Precedence** (`ReadAccess.Of`): `[AllowAnonymous]` → P; `[RequirePluginService]` → G; on the action an any-area
  rule → L/R/O, another access rule or `[Authorize]` → U, `[DashboardReads]` → F; then the same on the controller;
  else D. `RequireServiceOrPermissionForWrites` and `RequireServiceOrLoggedIn` never decide a read. A filter that isn't
  the deciding rule for the action steps aside, so a class-level `[DashboardReads]` doesn't add to an action's own rule.
- **Writes are unchanged.** `DashboardReads` is not an `IKnkAccessRule`, so a write without a rule still gets the
  default-deny 403. `RequireServiceOrPermissionForWrites` also skips a POST whose action carries a read rule (the
  validation POSTs, `Domains/world/resolve`); the builder writes stay `knk.admin.content`, world writes
  `knk.admin.world`.
- **Refusal:** 403 `{ error: "Forbidden", code: "NoReadAccess", entityType, nodes, message: "You don't have access to
  <Type>. Requires one of: …" }`; the any-area rules answer 403 "Requires a staff area permission (any of …)".
- **Player summaries:** `GET api/Users/uuid/{uuid}` and `username/{username}` need `knk.admin.user.manage` or the plugin
  key (F `User`). Self reads (`GET api/Users/{id}`, `…/permissions/check|effective`) stay
  `RequireServiceSelfOrPermission`.
- **Checks:** `PermissionResolutionService.CheckAnyAsync(userId, nodes)` resolves several nodes on one holder chain;
  `IPermissionReadCache` (singleton) memoises per request and caches each (user, node) answer 30 s, for reads only.
  `PermissionGrantService` (a user holder: that user; a group: everyone), `UserPermissionGroupService` (that user) and
  `PermissionGroupService` (everyone) drop the cached answers at the calls that publish S2's `UserPermissionsChanged` /
  `PermissionGroupChanged`, also without a realtime sink. Anything else (an expiring grant) shows within 30 s.
- **Lookups** (`Controllers/LookupController.cs`, `Services/LookupService.cs`, `Attributes/DashboardLookups.cs`):
  - `POST api/Lookup/{entityType}/search` `{ searchTerm, page, pageSize ≤ 50 }` → `{ items: [{ id, label, detail? }],
    total }` through the type's own search (no filters, no sort); `GET api/Lookup/{entityType}/{id}` → `{ id, label,
    detail? }` through its own get by id.
  - Label and detail are read by property name from what the service returns (one short line: a domain's parent and
    world, a location's world and coordinates, an item's category and grade, …; at most 120 characters).
  - **Users:** the label is the username, no detail; the search term goes to the `username` filter, so a lookup never
    matches (or shows) an email.
  - Unknown type 404 `UnknownEntityType`; a registry type without a lookup (link rows, snapshots, other view-only
    entries; search for types without a search such as banner layers or road profiles) 400 `LookupNotAvailable`.
    No rate limit (like the searches it replaces).
- **The plugin** passes every gated read with its key (`api.auth.type: apikey`); `ReadAccessRulesTests` lists every
  GET and search POST of knk-plugin's `knk-api-client` and runs them through the filters.

### 5.3 Relationships: Select / Unlink / Add (PandiO/knk-workspace#188, merged 2026-11-12)

The entity detail page changes a link without editing the rest of the record and without ever deleting the related
record.
- **Catalog** (`Services/RelationshipService.cs` `RelationshipCatalog`): every navigation of every `DashboardAccess` type,
  read from the EF model once per model, with its storage: `ForeignKey` (a column on the record), `Children` (the related
  row's column), `Many` (a hidden link table such as `TownStreet`), `LinkRow` (a link entity whose key is the two ids and
  that stores nothing else, e.g. `ItemBlueprintTag`; one with a level or weight is a record of its own) or `Other`.
- **What may change** is a reviewed list, `RelationshipCatalog.Supported` (pinned by `RelationshipServiceTests`): category
  parent / child categories / tags / icon, item blueprint category / grade / tags / icon, town and district streets, a
  street's districts and town. Their update services only check that the related row exists (reviewed 2026-11-09).
  Everything else answers with a reason: required parents ("A District always belongs to one Town: …"), domain
  locations and teleport settings (the world is resolved from them), gates, kits, lootbox and siege setup, the players
  area (escalation guard). Icons can be replaced, not removed. Adding a pair is one line after a look at the type's
  update service.
- **Endpoints** (`Controllers/RelationshipsController.cs`, writes only, no new read):
  - `POST api/Relationships/{entityType}/{id}/{property}/link` `{ relatedId, move? }`: sets the column, the related
    row's column or adds the link row. Already linked → `changed: false`. A child of another parent → 409
    `AlreadyLinked` `{ currentId }` until `move: true`. A parent chain that would loop → 400 `Cycle`.
  - `POST …/unlink` `{ relatedId }` (required for a collection): clears the column, the related row's column, or
    removes the link (-table) row. Not linked → 404 `NotLinked` (a reference: `changed: false`).
  - 404 `UnknownEntityType` / `UnknownRelationship` / `NotFound` / `RelatedNotFound`, 400 `RelationshipNotEditable` with
    the reason, 409 `Conflict` when the database refuses.
- **Access** (`Attributes/RequireRelationshipWriteAttribute.cs`, an `IKnkAccessRule`): web users only (the plugin key
  alone 403), the type's change nodes and, for `Children`, the related type's change nodes too (`nodes` per
  relationship); never `knk.admin.delete`. Since #374 (in `next` `b65e66d`) the change nodes are `ChangeNodes` of
  § 5.1: the write node **and** `knk.admin.content` (a town's streets: `["knk.admin.world", "knk.admin.content"]`).
  Missing → 403 `{ code: "NoWriteAccess", entityType, nodes, message }`, message "Changing links of Town requires
  knk.admin.world and knk.admin.content.".
- **Metadata:** `EntityMetadataDto.relationships` `[{ property, relatedType, kind, storage, canLink, canUnlink,
  linkReason?, unlinkReason?, nodes, relatedIdField?, relatedNavigation? }]`.
- **Realtime:** the existing interceptor publishes the changed row (`Modified` on the record or on the child);
  link-table and link-row changes publish nothing of their own, so other admins' open pages refresh on their next
  change or reload (LV5-6).
- **Display import:** `showDeleteButton` is a known button key; Select/Unlink/Add/Remove are no longer reported as
  hidden.

### 5.4 What still uses a record: rows for "Show details" (PandiO/knk-workspace#44, merged 2026-11-12)

A delete the database refuses answers 409 `{ code: "DbConstraint", message, references: [{ referencedBy, count }] }`
(`DeleteConstraintExceptionFilter`, KNG-162/KNG-172). The rows behind those counts are fetched only when the admin asks:
- **Endpoint** (`Controllers/EntityReferencesController.cs`): `GET api/EntityReferences/{entityType}/{id}/rows`
  `?referencedBy=Structure.StreetId&take=20` → `{ entityTypeName, id, groups: [{ referencedBy, entityType, count, listed,
  readable, nodes, reason?, rows: [{ id, label, detail? }], more }] }`. Only the references that stop a delete (the
  refusal message's own rule, `EntityReferenceService.BlocksDelete`); `take` 1–50 per group (default 20), sorted by id.
  Read-only.
- **Access** (`Attributes/RequireReferenceReadAttribute.cs`, an `IKnkAccessRule`, read category **U** in
  `ReadAccessRulesTests`): one of the route type's `ReadNodes`, web users only (anonymous 401, the plugin key alone 403,
  no read node 403 `NoReadAccess`, a type outside `DashboardAccess` 404 `UnknownEntityType`). A custom rule because the
  nodes depend on the route's type.
- **What a group shows** (`Services/EntityReferenceRowsService.cs`): never more than the lookup label
  (`ILookupService.GetAsync`, a user's username only):
  - rows of a type the caller reads in full (any of its read nodes): labels, `readable: true` (the web app links them);
  - rows of another dashboard type: labels when the caller holds any area node (what `api/Lookup` gives them anyway),
    `readable: false`; otherwise only `count`, `listed: false` and the nodes that would read them;
  - rows that aren't a dashboard type (drafts, form fields, workflow sessions) and rows without a single id: counted only
    ("These records aren't listed here."), so other users' drafts never show.
- `EntityReferenceService.GetReferencingRowsAsync` shares the loop with the counts (the ids of the referencing rows, for a
  join row the other side's id); counts and rows always agree.

### 5.5 Builder drafts, Publish and Duplicate (PandiO/knk-workspace#71, merged 2026-11-12)

The form and display builders save in place without changing what staff use: a configuration's **rows** (steps,
fields; sections, fields) are always the **published** version the form wizard, "New with", child forms, pickers,
saved wizard drafts and detail pages read. The builder's working copy waits beside them until **Publish**.
- **Storage** (migration `AddConfigurationDrafts`, additive): `FormConfigurations.IsDraft` (default `false`: every
  existing row and every import stays published), `DraftJson`, `DraftSavedAt`, `PublishedAt`;
  `DisplayConfigurations.DraftJson`, `DraftSavedAt`, `PublishedAt` (display configurations already had `IsDraft`).
  `DraftJson` is the builder's `FormConfigurationDto` / `DisplayConfigurationDto` as JSON (`Services/ConfigurationDraftJson.cs`,
  at most 2 MB); `IsDraft` means **never published** (made in the builder or duplicated).
- **Services** (`FormConfigurationDraftService`, `DisplayConfigurationDraftService`):
  - *Builder state*: working copy = `DraftJson` else the rows; plus the published DTO (null while never published), the
    entity's current published default, and for forms the open wizard drafts (`InProgress`/`Paused`) on this configuration.
  - *Create draft*: a row with name and entity only (`IsDraft`, never the default, no steps) and the copy in `DraftJson`.
  - *Save draft*: stores the copy, no validation (a draft may be unfinished); the entity can't change; a never-published
    row takes the copy's name and description (Entity setup lists it).
  - *Publish* (one transaction): applies the copy through the existing `UpdateAsync` (forms: every check a builder save
    ran before, refused as "Can't publish: …"; display: `UpdateSections`), moves the default when the copy asks for it
    (unsets the others), clears the copy, `IsDraft = false`, `PublishedAt = now`. Nothing unpublished → 400. Display's
    older Publish of a draft without a copy (Entity setup) goes through the same method.
  - *Discard*: drops the copy (not for a never-published configuration without rows).
  - *Duplicate*: the portable export of the rows (KNG-138 / knk-displayconfig/1, so conditions and validation rules come
    along), every own GUID replaced (`WithNewGuids`), imported through `ImportDraftCopyAsync` as a never-published copy
    that is never the default; "<name> (copy)" unless a name is given. Refused while there are no rows yet.
- **Endpoints** (both `FormConfigurationsController` and `DisplayConfigurationsController`): `GET {id}/builder`
  (read category **F** `knk.admin.content` in `ReadAccessRulesTests`, like export and seeds), `POST drafts`,
  `PUT {id}/draft`, `POST {id}/draft/discard`, `POST {id}/publish`, `POST {id}/duplicate` (writes under the class rule
  `RequireServiceOrPermissionForWrites(knk.admin.content)`). No delete was added; configuration deletes keep their
  `knk.admin.content` rule (#280 DESIGN § 4.7 "not covered").
- **Runtime reads** never get a never-published form: `GET api/FormConfigurations`, `GET {entityName}` (list) and
  `GET {entityName}/all` take `includeDrafts` (default `false`; only Entity setup asks for them), the default
  (`defaultOnly`) and `entity-names` skip them in the repository. `GET {id}` still returns the row (empty steps for a
  never-published one). A legacy `PUT {id}` refuses to make a never-published form the default and keeps the saved copy's
  default flag in step (`SyncDraftDefaultAsync`, also for display).
- **Templates**: the web app no longer calls `{configId}/steps/add-from-template` / `steps/{stepId}/fields/add-from-template`
  (they wrote into the published rows); the endpoints stay for other callers.
- **Consumers checked**: the plugin's `knk-api-client` reads no form or display configuration (world tasks carry their
  own input JSON); API-side `FormSubmissionProgressService`, `FieldValidationRuleService`/`DependencyResolutionService`
  (health checks by id), `WorldTaskRepository` (form name), portability export/seeds and the realtime map all read the rows,
  i.e. the published version.
- **Step conditions in the configuration health check** (PandiO/knk-workspace#88, in `next` `31abe2d` since 2026-11-13):
  `Services/StepConditionHealth.cs` reports a step-condition rule that reads a field which is not on its step, or for
  "from an earlier step" not on any earlier step, walking the steps in `StepOrderJson` order. `FieldValidationRuleService`
  calls it for the saved configuration (`GET api/field-validation-rules/health-check/configuration/{configId}`) and for the
  builder's working copy (`POST …/health-check/configuration/draft`). Severity `Warning`, or `Info` when the condition is
  switched off; it never blocks a save or a publish. Only JSON in the builder's shape is judged.

## 6. Talks to knk-plugin

Contrary to what both this repo's and knk-plugin's CLAUDE.md currently say ("no webhook/push model" / "no polling/webhook indirection found"), the integration is **not purely plugin-calls-API**:

- **plugin → API** (the dominant direction): the plugin's `knk-api-client` module makes hand-written REST calls (OkHttp + Jackson, not OpenAPI-generated) covering Users, Towns, Districts, Streets, Structures, Locations, EnchantmentDefinitions, ItemBlueprints, MinecraftMaterialRefs, Domains (`by-region`/`search-region-decisions` only), GateStructures, GateDoors, WorldTasks, and Health. *Corrected 2026-10-25:* auth is the service key header `X-API-Key` (`ApiKeyAuthProvider`, `config.yml` `api.auth`), compared constant-time to `Security:PluginApiKey` by `[RequirePluginService]` / `[RequireServiceOrPermission]` (KNG-64); an optional `X-Acting-User-Id` names the player. The bearer-token description above was the 2026-09-18 state.
- **API → plugin (a real, working exception)**: `Services/RegionService.cs` makes outbound HTTP calls (`MinecraftPlugin:BaseUrl`, defaulting to `http://localhost:8081` — a C# fallback not present in either `appsettings.json`) into a small `com.sun.net.httpserver.HttpServer` the plugin itself runs (`knk-paper/.../http/RegionHttpServer.java`, started in `KnKPlugin.java:595-599`; loopback bind and `X-API-Key` since KNG-64) for WorldGuard region rename/containment checks: rename from `DomainRegionNameFinalizer` on create **and update** of Town/District/Structure/Domain/GateStructure/DomainSubRegion, and synchronous containment queries from form validation (`LocationInsideRegionValidator`, `RegionContainmentValidator`). Current sync inventory and the SignalR plan: [`reports/2026-10-25-realtime-sync-inventory.md`](../reports/2026-10-25-realtime-sync-inventory.md), [`specs/realtime-signalr/DESIGN.md`](../specs/realtime-signalr/DESIGN.md) (#66). This is the one confirmed push channel from API to plugin — **update both repos' CLAUDE.md files** to reflect this rather than trusting the "no push model" claim.
- **Realtime hubs (#178 S1; branch `claude/realtime-signalr`, not merged):** `Realtime/` adds SignalR in the API
  process: `/api/hubs/game` (plugin key via the `KnkRealtimeGameServer` policy, `X-Knk-Server-Id`; presence methods
  `ReportRoster`/`PlayerJoined`/`PlayerLeft` write `User.IsOnline`/`LastSeenAt`, players of a server gone > 60 s
  are marked offline) and `/api/hubs/web` (JWT; `access_token` query string on this path only). Services publish
  through `IRealtimePublisher` (bounded queue, `seq` per connection). **S2 (#179, same branch):** the user-state
  events (`UserPermissionsChanged`, `PermissionGroupChanged`, `UserBalancesChanged`, `UserFrozenChanged`,
  `UserModeChanged`, `UserChanged`) go through the scoped `IRealtimeEventSink`, which holds an event raised inside a
  database transaction until it commits (`RealtimeTransactionEvents`, an EF Core transaction interceptor on
  `KnKDbContext`); `IPlayerNotificationQueue` is `HubPlayerNotificationQueue`, which pushes a notification to the
  player's server at once and keeps the in-memory queue behind `api/PlayerNotifications` (design §6.7). Hubs are not MVC
  actions, so `DefaultCallerRequiredFilter`/`EndpointAccessRulesTests` don't cover them; their rules are on the
  endpoints (`RealtimeSetup.MapKnkRealtimeHubs`) and tested in `Tests/.../Realtime/RealtimeHubTests.cs`.
  **WT2 (#181, same branch):** `POST api/WorldTasks` takes `deliver` (auto/code/queue/replace/{userId});
  `Services/WorldTaskRealtime` (`IWorldTaskRealtime`, scoped) looks up presence (`PresenceRegistry.ConnectedServerOf`)
  and publishes through the sink: `WorldTaskOffered`/`WorldTaskCancelled`/`WorldTaskOfferWithdrawn`/`WorldTaskCreated`
  to the game hub, `WorldTaskUpdated` to the web groups `task:{id}` + `user:{creator}` and `CatalogScanUpdated`
  (`RealtimeEvent.WebGroups`, `IRealtimePublisher.PublishToWebGroups`, one send per connection). Game hub invocation
  `WorldTaskOfferResult`; `ReportRoster`/`PlayerJoined` offer waiting tasks; web hub `JoinTask`/`LeaveTask` (creator or
  `knk.admin.world`). New reads: `GET api/WorldTasks/active-for-me`, `GET api/Presence/me`,
  `GET api/Presence/online-staff` (`knk.admin.world`). The sweep times unanswered offers out
  (`WorldTasks:OfferTimeoutSeconds`, 120). DESIGN §8.8.
  *#239/#240 (merged 2026-11-05):* offer state `NoPermission` for the `no-permission` answer (`unavailable` → Declined);
  `POST api/WorldTasks/{id}/offer` (`WorldTaskService.OfferAgainAsync`, `OfferTaskDto`) re-delivers a waiting task
  through the same `DeliverAsync` as a new one, with a fresh expiry.
  **S3 (#182, same branch):** `Realtime/RealtimeEntityChangeInterceptor`, an EF Core save interceptor on `KnKDbContext`,
  maps every successful save (`Realtime/RealtimeEntityChangeMap`) to `EntityChanged {type, id, op, key}` for the cached
  types and to `DomainAccessChanged`, `GameSettingsChanged`, `SiegeConfigChanged`, `LootboxConfigChanged`,
  `TeleportDestinationsChanged`, `NavigationSettingsChanged`, `RoadNetworkChanged`, `TelemetryConfigChanged`, and hands
  them to the same after-commit sink (no service changes; option C would swap only the sink). `GateChanged` comes from
  `GateStructureService`/`GateDoorService` definition edits (not from runtime state or siege lockdown writes). Game hub
  invocation `ReportWorlds` = `PUT api/GameSettings/runtime-worlds` over the hub. DESIGN §6.8.
  **S4 (#183, merged 2026-11-12, `master` `bc97b7d`; smoke test § S4 not run):** the same interceptor also feeds
  `Realtime/RealtimeWebChangeMap` (while a web connection is open): web `EntityChanged {type, id, op, actorUserId,
  actorName}` for every `[FormConfigurableEntity]` type and its dashboard base types, `PresenceChanged {userId, online,
  serverId, lastSeenAt}` when `User.IsOnline` changes. Each names a node (`RealtimeEvent.WebNode` →
  `PublishToWebHolders` → `RealtimeMessage.RequiredNode`); the dispatcher sends it only to web connections whose user
  holds it (`Realtime/RealtimeWebAudience`: `IPermissionResolutionService.CheckAsync`, cached
  `Realtime:WebPermissionCacheSeconds`, 30; fail closed): since #280 AM1 (same merge) the type's **area node** from
  `DashboardAccess` (§ 5.1; `RealtimeWebChangeMap.NodeFor`, `knk.admin.content` only for a type outside the registry),
  or `knk.admin.user.manage` for users, their permission rows, the audit log and presence; a base type's event (a Town
  also sends `Domain`) carries the base type's own area node; ledger and game-server-only types are never sent. The profile
  summary gains `presence {online, lastSeenAt}`. `Realtime:WebLiveUpdatesEnabled` (default `true`) switches the web
  events off (none built or sent; game-server events and the profile's `presence` stay; decision 2026-11-06). DESIGN §6.9.
- **Headless world-task polling**: the plugin polls for tasks it needs to execute (`HeadlessWorldTaskPoller.java`, 5s interval backing off to 60s when idle) rather than being notified — the plugin's own source comments already flag this as a known gap ("should eventually be replaced by the API pushing a notification, e.g. SignalR"). There is no SignalR/WebSocket/Hub anywhere in this repo today. *#180:* the poller now claims a scan (claim mode `headless`) before it runs it, and every claim the plugin holds is renewed by `POST api/WorldTasks/{id}/heartbeat`; `claim`, `complete`, `fail`, `release`, `heartbeat` and `GET open?serverId=` are game-server only (`[RequirePluginService]`).
- *Corrected 2026-10-25:* the plugin's `ApiConnectivityMonitor` probes `GET /health/ready` every 10 s (`config.yml` `api.connectivity`), so the paragraph below is the 2026-09-18 state. **`HealthController` (`api/Health`)** was what the plugin called for its health check (`HealthApiImpl.java`), via a route the plugin's own comments call a guessed/unverified contract. The API's "real" liveness/readiness surface is `HealthCheckController` (`health/live`, `health/ready`, checks DB connectivity) — no caller was found for it in either repo, consistent with it being meant for external infra (k8s/docker healthchecks) rather than app-to-app calls. Consider pointing the plugin at `health/live` instead, and treat `HealthController` as retirable once that happens.

## 7. Known architectural debt to be aware of before extending this repo

- `Microsoft.EntityFrameworkCore.SqlServer` package reference — unused, safe to remove.
- `DependencyInjection/ObservabilityServiceCollectionExtensions.cs` — dead code; `Program.cs` has its own inline duplicate of the same wiring.
- `Services/DependencyPathResolver.cs` — no controller/service caller found anywhere; looks superseded by `PathResolutionService`. (`Services/FieldValidationService.cs`/`IFieldValidationService`, the other one listed here, was removed 2026-11-04, PandiO/knk-workspace#99.)
- `Dtos/Forms/FieldValidationRuleDtos.cs` — a second, near-duplicate set of `FieldValidationRuleDto`-family classes in a `Dtos.Forms` namespace that nothing references; the real one lives in `Dtos/FieldValidationRuleDtos.cs`.
- `Telemetry:Prometheus` config (`appsettings*.json`) is not wired to any actual `/metrics` endpoint — `Program.cs:186` has an explicit unresolved TODO for it. **This repo's own `CLAUDE.md` and `OBSERVABILITY.md` claiming "Prometheus metrics exposed at `/metrics`" is stale/aspirational**, not current fact.
- `FieldValidationRulesController` exposes two extra absolute-route actions (`/api/field-validations/validate-field`, `/api/field-validations/rules/{ruleId}/placeholders`) on a different base path than the rest of the controller (`field-validations` vs. `field-validation-rules`) — no caller found; looks like a legacy/duplicate of the controller's own `.../validate` action.
- `TestDisplayController` (`api/test/*`) is a live, unauthenticated integration-test harness with a `DELETE api/test/cleanup` action that bulk-deletes any `DisplayConfiguration` whose name merely contains `"Test"` — a real footgun if this ever reaches a shared/prod environment. Not hypothetical dead code; it works today.
- `WeatherForecastController` is unmodified ASP.NET Core template scaffolding with no real caller — safe to delete.

Full detail, file:line citations, and the complete endpoint/service/repository/entity tables are in `docs/reports/web-api-scan-2026-09-18.md`. Practical "how to work in this repo" guidance is in `docs/guides/web-api-reading-guide.md`.
