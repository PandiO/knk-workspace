# knk-entity-scaffold checklist

Every file a new entity `Widget` touches, with the Tag file to copy (all on each repo's `main`). Tick each in the PR;
write "not needed" with the reason for the ones you skip.

## 1. knk-web-api

1. `Models/<Folder>/Widget.cs` with `[FormConfigurableEntity("Widget")]` (`Models/Item/Tag.cs`; relations:
   `Models/District.cs`).
2. `Properties/KnKDbContext.cs`: `DbSet<Widget> Widgets`, `modelBuilder.Entity<Widget>` with `ToTable("widgets")`.
3. `Migrations/<timestamp>_AddWidgets.cs` from `dotnet ef migrations add AddWidgets`, plus
   `Tests/knkwebapi_v2.Tests/Migrations/AddWidgetsTests.cs`.
4. `Dtos/WidgetDtos.cs`: `WidgetReadDto`, `WidgetCreateDto`, `WidgetUpdateDto`, `WidgetListDto`, `WidgetNavDto`
   (`Dtos/TagDtos.cs`).
5. `Repositories/Interfaces/IWidgetRepository.cs`, `Repositories/WidgetRepository.cs` (`TagRepository.cs`).
6. `Services/Interfaces/IWidgetService.cs`, `Services/WidgetService.cs` (`TagService.cs`).
7. `Mapping/WidgetMappingProfile.cs` (`TagMappingProfile.cs`).
8. `Controllers/WidgetsController.cs` (`TagsController.cs`).
9. `DependencyInjection/ServiceCollectionExtensions.cs`: `AddScoped` for repository and service.
10. `Attributes/DashboardAccess.cs`: an `Entries` line (and `ExtraReadNodes` if other pages read it).
11. `Attributes/DashboardLookups.cs`: a `ByType` entry.
12. `Services/RelationshipService.cs` `RelationshipCatalog`: only for relations edited on the detail page.
13. `Realtime/RealtimeEntityChangeMap.cs` `EntityTypes`: only when the plugin caches it.
14. `Data/FormConfigurationSeeds/Widget.json` + the README row; `Data/DisplayConfigurationSeeds/Widget.display.json` if
    needed.
15. Tests: `Security/ReadAccessRulesTests.cs` (`Pinned`, `PluginReads`), `Security/DashboardChangeAccessRulesTests.cs`,
    `Security/DeleteAccessRulesTests.cs`, `Security/DashboardAccessTests.cs` (`WebAppDeletes`),
    `Services/WidgetServiceTests.cs`.

## 2. knk-web-app

1. `src/types/dtos/widget/WidgetDtos.ts` (`src/types/dtos/tag/TagDtos.ts`).
2. `src/utils/enums.ts`: `Controllers.Widgets`, `WidgetOperation`.
3. `src/apiClients/widgetClient.ts` (`tagClient.ts`).
4. `src/utils/entityApiMapping.ts`: five `case 'widget':` branches (search, fetch by id, update, delete, create).
5. `src/config/objectConfigs.tsx`: `columnDefinitionsRegistry.widget` if the table needs more columns.
6. `e2e/fixtures/widgets.ts` typed with `WidgetDto`; `e2e/widgets.spec.ts` (`e2e/dashboard.spec.ts`,
   `e2e/dashboard-access.spec.ts`).
7. Jest tests for any new helper or component logic.

## 3. knk-plugin (when it reads the entity)

1. `knk-core/.../core/domain/<area>/KnkWidget.java` (`domain/item/KnkTag.java`).
2. `knk-core/.../core/ports/api/WidgetsQueryApi.java` (`TagsQueryApi.java`).
3. `knk-api-client/.../api/dto/WidgetDto.java` (`TagDto.java`).
4. `knk-api-client/.../api/mapper/WidgetMapper.java` (`TagMapper.java`).
5. `knk-api-client/.../api/impl/WidgetsQueryApiImpl.java` extending `BaseApiImpl` (`ClansQueryApiImpl.java`).
6. `knk-api-client/.../api/client/KnkApiClient.java`: field, constructor, `getWidgetsQueryApi()`.
7. `knk-core/.../core/dataaccess/WidgetsDataAccess.java` (`TagsDataAccess.java`).
8. `knk-paper/.../paper/dataaccess/DataAccessFactory.java`: `createWidgetsDataAccess`.
9. `knk-paper/.../paper/config/KnkConfig.java` `EntityCacheSettings`, `ConfigLoader.java`, `config.yml`
   `cache.entities.widgets`.
10. `knk-paper/.../paper/KnKPlugin.java`: query API and data access fields and wiring; `EntityChangeRouter` handler if
    realtime.
11. Tests: `knk-api-client/src/test/.../impl/WidgetsQueryApiImplTest.java` or a mapper test, a `knk-core` gateway test,
    `knk-paper/src/test/.../dataaccess/DataAccessFactoryWidgetsTest.java`, a `ConfigLoader` test.

## 4. knk-workspace

1. `docs/specs/api/` and the feature's spec or architecture doc.
2. `docs/guides/production-installation.md` migration steps; `docs/guides/admin/plugin-configuration.md` cache keys.
3. Smoke-test guide section with automated steps tagged (knk-test-writer § 4).
4. `docs/CHANGELOG.md` entry.
