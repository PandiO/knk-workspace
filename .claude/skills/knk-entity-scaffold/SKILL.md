---
name: knk-entity-scaffold
description: Scaffold a new Knights and Kings (K&K) entity across knk-web-api, knk-web-app and knk-plugin, or finish one whose model exists ("I created the model, scaffold the rest"). Use when asked to add a new K&K entity, record type, reference-data table or dashboard type end to end.
---

# K&K entity scaffold

A new entity across the three component repos, built from the code on each repo's `main`. The reference entity is
**Tag** (a content-area dashboard type with the full pipeline in all three repos); a world-area type with relations is
**District**. Pick the one closest to yours and open its files as you go. The API part is the
[`knk-api-endpoint`](../knk-api-endpoint/SKILL.md) recipe applied to a whole CRUD controller; read that skill first.
Per-repo file lists are in [checklist.md](checklist.md).

Read first: `AGENTS.md` and `CLAUDE.md` of each repo you change, the
[dashboard access model](../../../docs/specs/dashboard-access-model/DESIGN.md) § 4 (areas, nodes, read categories)
and the [global instructions](../../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) "Testing: automated first" and
"Branches". One branch name in every repo; PRs per knk-link § 3.

## 1. Inputs to settle first

Write these down (in the design, the issue or the PR); take the most reversible default where nobody decided, and log
it as an agent decision (knk-link § 5):

1. **Name** (singular PascalCase `Widget`, table `widgets`, route `api/Widgets`, web type `widget`).
2. **Fields** with types, required or optional, limits.
3. **Relations:** many-to-one (`TownId` + `Town`), one-to-many collections, many-to-many through a join entity
   (`CategoryTag`, `ItemBlueprintTag`).
4. **Cascade rules:** what create and update do to related rows, what delete does (cascade, restrict with a 409, set
   null). Copy the reference entity's behaviour unless told otherwise.
5. **Dashboard area** (`Content`, `World`, `Kits`, `Lootboxes`, `Siege`, `Roads`, `Players` in
   `Attributes/DashboardAccess.cs`) and so its node (`knk.admin.content`, `knk.admin.world`, ...). Deletable? Exported?
6. **Who reads it:** web app only, or the plugin too (then the plugin side, § 4). Does the plugin cache it and need
   realtime invalidation?
7. **World-captured data** (a location, a region) through a world task? Then the world-task rule of knk-api-endpoint
   § 2 applies: the parent's service creates the related row on save, never the workflow.

## 2. knk-web-api

1. **Model** in `Models/` (a feature folder like `Models/Item/` is fine) with `[FormConfigurableEntity("Widget")]` on the
   class, so `MetadataService` lists it for the form builder and the dashboard. On relations:
   `[RelatedEntityField(typeof(Town))]` on both the FK and the navigation, `[NavigationPair(nameof(Town))]` on the FK
   (`Models/District.cs`).
2. **DbContext** (`Properties/KnKDbContext.cs`): a `DbSet<Widget> Widgets` and a `modelBuilder.Entity<Widget>` block with
   key, `ToTable("widgets")`, lengths, precision, indexes and the delete behaviour of each relation.
3. **Migration:** `dotnet ef migrations add AddWidgets`, read it, test it (knk-api-endpoint § 5).
4. **DTOs, repository, service, mapping, controller, DI** exactly as knk-api-endpoint § 2 with the Tag files. The read
   DTO nests related rows as `NavDto`s (`TagNavDto`), never full DTOs, so there are no cycles. Cascades live in the
   service; the repository only loads and saves.
5. **Dashboard registry** (`Attributes/DashboardAccess.cs` `Entries`):
   `Type("Widget", DashboardArea.Content, Content, Del<IWidgetService>(...), Lists<IWidgetService, WidgetListDto>(...))`,
   or `ViewOnly(...)` for a type without delete. Cross-area readers go in `ExtraReadNodes`.
6. **Lookup** (pickers and labels, `api/Lookup`): an entry in `Attributes/DashboardLookups.cs`
   (`["Tag"] = Of<ITagService>((s, id) => s.GetByIdAsync(id), Name)`).
7. **Relations editable on the detail page** go through `RelationshipCatalog` in `Services/RelationshipService.cs`.
8. **Realtime** (only when the plugin caches the type): add it to `RealtimeEntityChangeMap.EntityTypes`
   (`Realtime/RealtimeEntityChangeMap.cs`) with its natural key or null, so a save sends `EntityChanged`.
9. **Seeds:** a default form in `Data/FormConfigurationSeeds/Widget.json` (format and authoring guide:
   [DEFAULT_FORM_SEEDS.md](../../../docs/specs/form-configurations/DEFAULT_FORM_SEEDS.md) § 3-4; copy `Tag.json`), a row
   in that folder's `README.md`, and a display seed in `Data/DisplayConfigurationSeeds/` when the detail page needs more
   than the default. `FormConfigurationSeedFilesTests` and `DisplayConfigurationSeedFilesTests` dry-run every file.
10. **Pinned tests** (they fail until the type is in them): `ReadAccessRulesTests.Pinned` (`F Widget` for each read),
    `DashboardChangeAccessRulesTests.ChangeActions`, `DeleteAccessRulesTests.PrimaryDeletes`, and
    `DashboardAccessTests.WebAppDeletes` (the types the web app's `getDeleteFunctionForEntity` handles). Plugin reads go
    into `ReadAccessRulesTests.PluginReads`.
11. **Tests:** `Services/WidgetServiceTests.cs` (validation, not-found, cascades, delete rules), a mapping test for
    custom members, a migration test. A MySQL-only rule (a unique index) in `MySql/`.

## 3. knk-web-app

The dashboard, detail page and form wizard are metadata-driven: once the API lists the type and the web app can call
it, `/dashboard/widget`, the detail page and `/forms/widget` work without a page of their own.

1. **Types:** `src/types/dtos/widget/WidgetDtos.ts` with `WidgetDto` and `WidgetListDto` matching the API's JSON names
   (`src/types/dtos/tag/TagDtos.ts`).
2. **Enums** (`src/utils/enums.ts`): `Widgets = 'Widgets'` in `Controllers`, and a `WidgetOperation` enum like
   `TagOperation`.
3. **API client:** `src/apiClients/widgetClient.ts`, a singleton on `ObjectManager` with `getAll`, `getById`, `create`,
   `update`, `delete`, `searchPaged` (`tagClient.ts`). All calls go through the client layer, never `fetch` in a
   component.
4. **Entity mapping** (`src/utils/entityApiMapping.ts`): a `case 'widget':` in each of `getSearchFunctionForEntity`
   (wrapped in `withPagedQueryMapping`), `getFetchByIdFunctionForEntity`, `getUpdateFunctionForEntity`,
   `getDeleteFunctionForEntity` and `getCreateFunctionForEntity`. Without them the dashboard shows the type but cannot
   list or save it.
5. **Columns** (optional): a `widget` entry in `columnDefinitionsRegistry` in `src/config/objectConfigs.tsx` when the
   table needs more than id and name (`clan`, `bannerdesign`). Add to `objectConfigs` itself only when the type needs the
   legacy built-in form; the real form is the FormConfiguration.
6. **A custom page** only when the generic framework can't do it; reuse `ObjectDashboard`, `DisplayWizard`, `FormWizard`.
   Styling is Tailwind only.
7. **Tests:**
   1. **Playwright** (`e2e/`, mocked API, [web app testing § 3](../../../docs/guides/developer/web-app-testing.md)): a
      typed fixture in `e2e/fixtures/` built from `WidgetDto`, and a spec like `e2e/dashboard.spec.ts`:
      `startLoggedIn` + `mockSession` from `e2e/fixtures/auth.ts`, `mockContentDefaults(api)` from
      `e2e/fixtures/content.ts`, `accessMetadata('Widget', CONTENT)` from `e2e/fixtures/dashboardAccess.ts` for the
      area's buttons, then `api.on('POST', 'Widgets/search', ...)`. Cover: the list shows the rows, search asks the API,
      staff without the area node don't see it, the create form saves (`POST Widgets` body). Turn on `strictApi` once
      the spec mocks every call.
   2. **Jest** next to any helper or component logic you add (`__tests__/`).
   3. Run `npm run typecheck:e2e`, `npm run test:ci`, `npx tsc --noEmit`, `CI=true npm run build`, `npm run test:e2e`.
   Dependency changes only with npm 11 (`npx npm@11 ...`).

## 4. knk-plugin (only when the plugin reads the entity)

The plugin reads; writes stay in the API and web app unless the design says otherwise. World operations (regions,
blocks, locations in the world) stay in the plugin.

1. **Domain record** in `knk-core/src/main/java/net/knightsandkings/knk/core/domain/<area>/KnkWidget.java`
   (`domain/item/KnkTag.java`).
2. **Port** in `knk-core/.../core/ports/api/WidgetsQueryApi.java` returning `CompletableFuture`s
   (`TagsQueryApi.java`: `search(PagedQuery)`, `getById(int)`).
3. **DTO and mapper** in `knk-api-client/src/main/java/net/knightsandkings/knk/api/`: `dto/WidgetDto.java` (a record
   with `@JsonProperty` names matching the API), `mapper/WidgetMapper.java` (`toCore`, `mapPagedList`, null-safe;
   `TagMapper.java`).
4. **Implementation** `api/impl/WidgetsQueryApiImpl.java` **extending `BaseApiImpl`** (`get`, `getOrNull`, `parse`;
   `ClansQueryApiImpl.java`). `TagsQueryApiImpl` predates `BaseApiImpl`; don't copy its hand-written OkHttp code.
5. **Client wiring:** a field, constructor line and `getWidgetsQueryApi()` in
   `knk-api-client/.../api/client/KnkApiClient.java`.
6. **Gateway:** `knk-core/.../core/dataaccess/WidgetsDataAccess.java` with its `BaseCache`, `DataAccessExecutor` and
   `FetchPolicy` (`TagsDataAccess.java`); `createWidgetsDataAccess` in `knk-paper/.../paper/dataaccess/DataAccessFactory.java`;
   an `EntitySettings widgets` in `KnkConfig.EntityCacheSettings` with its default; a `cache.entities.widgets` block in
   `config.yml`; the field and `dataAccessFactory.createWidgetsDataAccess(...)` in `KnKPlugin`.
7. **Realtime:** register the cache on `EntityChangeRouter` (`knk-core/.../core/realtime/EntityChangeRouter.java`,
   `router.on("Widget", ...)` in `KnKPlugin.entityChangeRouter`) when the API sends `EntityChanged` for it (§ 2.8).
8. **Tests:** a mapper or impl test in `knk-api-client/src/test/` parsing real API JSON (`CategoriesQueryApiImplTest`,
   `GradeMapperTest`); a gateway test in `knk-core/src/test/.../dataaccess/` (cache hit, miss, stale) with a fake port
   (`DistrictsDataAccessTest`); a
   `DataAccessFactory<Feature>Test` in `knk-paper/src/test/.../dataaccess/` for the configured settings; a
   `ConfigLoader` test for the new cache block. Then `./gradlew build -x deployToDevServer`.
9. **Deploy notes:** the `cache.entities.widgets` YAML in the PR's Admin steps and the
   [plugin configuration reference](../../../docs/guides/admin/plugin-configuration.md) (existing servers never get new
   keys, `saveDefaultConfig()`). A new command that shows the entity follows
   [`knk-plugin-command`](../knk-plugin-command/SKILL.md).

## 5. Order of work and PRs

1. API first (model, migration, pipeline, registry, pinned tests), green; push.
2. Web app against the API's DTOs; Playwright specs with mocked API; push.
3. Plugin last, against the API's JSON; push.
4. One PR per repo against the same base; the knk-workspace PR (docs, changelog) carries `Closes #<issue>`, the
   others `Part of #<issue>` (knk-link § 3.3).
5. Use the [`knk-test-writer`](../knk-test-writer/SKILL.md) skill for the Testing section and the smoke-test guide:
   what a staff member does in the dashboard is Playwright, the rules are xUnit, plugin reads are unit tests; only a
   real server or client check stays manual.

## 6. Docs

1. knk-workspace `docs/specs/api/` for the new endpoints and the spec or architecture doc of the feature.
2. Migration: the dev seed (`knk-dev-db-seed`) and the migration steps in
   [production installation](../../../docs/guides/production-installation.md).
3. A new node, area member or permission: the [dashboard access admin guide](../../../docs/guides/admin/dashboard-access-admin-guide.md).
4. Plugin config keys: § 4.9. Changelog entry in `docs/CHANGELOG.md`; the PR template's Docs impact and Admin steps
   (import the form seed, apply the migration, paste the YAML).
