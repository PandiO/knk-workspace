# Reusable systems — catalogue

**Status:** Current · **Last updated:** 2026-11-27 (first version, PandiO/knk-workspace#978; entry points checked
against `next` of knk-web-app `8be9e24`, knk-web-api `e06fd5c` and knk-plugin `2c5d584`)

The systems K&K built to be reused, on one page. Design sessions check it before writing a spec (the spec's "Reuse"
section), links check it before hand-building, coordinators check it when a link is finished. Not using a system
whose "required when" fits is allowed only where its "exception when" fits, and is then a decision log row with the
reason. Paths: web app under `src/`, API at the repo root, plugin `paper` = `knk-paper/.../knk/paper`, `core` =
`knk-core/.../knk/core`, `api` = `knk-api-client/.../knk/api`.

## 1. Entity create and edit: FormWizard and FormConfiguration

1. **For:** staff and admin create/edit of any entity, as a multi-step form built from a `FormConfiguration` and the
   entity metadata the API exposes. Brings drafts and resume, child forms, M2M joins, relation pickers, validation,
   step conditions and world-task fields for free.
2. **Required when:** a web page creates or edits rows of an entity (any form with inputs and a Save). New entities
   get `[FormConfigurableEntity]` and a default form seed (knk-entity-scaffold).
3. **Exception when:** a single action rather than an entity edit (approve/reject, kick, reset), a singleton settings
   record, a bulk operation, a read-only or telemetry view, or an in-game-only flow. "Edited through dedicated
   endpoints" is not an exception on its own (the roads opt-out in `navigation/IMPLEMENTATION_PLAN.md` is the case
   that led to this page).
4. **Entry points:**
   1. Web app: `components/FormWizard/FormWizard.tsx` (`FormWizard`), hosted by `pages/FormWizardPage.tsx` on
      `/forms/:entityName` (create) and `/forms/:entityName/edit/:entityId` (edit) (`routes/routeTable.ts`); open it
      by navigating there. Builder `components/FormConfigBuilder/FormConfigBuilder.tsx`; which forms a dashboard type
      offers: `hooks/useDashboardFormOptions.ts`.
   2. API: `Attributes/FormConfigurationAttributes.cs` (`FormConfigurableEntity`, `RelatedEntityField`,
      `NavigationPair`); `Controllers/MetadataController.cs` + `Services/MetadataService.cs` (`api/metadata/entities`);
      `FormConfigurations`/`FormSteps`/`FormFields` controllers and services, `FormConfigurationDraftService`;
      `FormSubmissionProgressController` (drafts); seeds `Services/FormConfigurationPortabilityService.cs` with
      `Data/FormConfigurationSeeds/*.json`.
5. **Current specs:** [web-app architecture § form engine](web-app-architecture.md),
   [FORM_WIZARD_SESSION_CONCEPTS](../specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md),
   [DEFAULT_FORM_SEEDS](../specs/form-configurations/DEFAULT_FORM_SEEDS.md) (seed authoring).

## 2. Detail views and lists: DisplayConfiguration, DisplayWizard, ObjectDashboard

1. **For:** read-only detail pages (`DisplayWizard`, sections and fields from a `DisplayConfiguration`, with display
   conditions) and the generic entity list (`ObjectDashboard`, columns from `objectConfigs`, calls via
   `entityApiMapping`, paged `POST api/<Entity>/search`).
2. **Required when:** a page shows one entity's details or lists an entity type for staff.
3. **Exception when:** a dashboard that aggregates several types, a map or live view, or a player-facing page with
   its own design.
4. **Entry points:**
   1. Web app: `components/DisplayWizard/DisplayWizard.tsx`, `pages/DisplayWizardPage.tsx` (`/display/:entityName/:id`),
      `components/DisplayConfigBuilder/DisplayConfigBuilder.tsx`, `components/ObjectDashboard/ObjectDashboard.tsx`
      (`/dashboard/:entityName`), `config/objectConfigs.tsx`, `utils/entityApiMapping.ts`.
   2. API: `DisplayConfigurations`/`DisplaySections`/`DisplayFields` controllers and services,
      `DisplayConfigurationPortabilityService` with `Data/DisplayConfigurationSeeds/*.display.json`,
      `Services/DisplayConditionEvaluator.cs`; paging `Models/PagedQuery.cs`, `Dtos/PagedQueryDtos.cs`.
5. **Current specs:** [web-app architecture § display configurations](web-app-architecture.md),
   [DEFAULT_FORM_SEEDS § 5.1](../specs/form-configurations/DEFAULT_FORM_SEEDS.md) (display seeds).

## 3. Relations: RelationPicker, lookups, M2M editor, child forms

1. **For:** choosing related entities in a form (search box, pinned rows of the form session), editing many-to-many
   joins, and creating a related entity inside the form.
2. **Required when:** a field points at other entities. Store the relation as a foreign key or a join entity, not as
   a JSON id list, so the picker, display and dependency rules work on it.
3. **Exception when:** the value is not an entity (a free list of names, a Minecraft material from the catalogue).
4. **Entry points:**
   1. Web app: `components/FormWizard/RelationPicker.tsx` (+ `utils/forms/relationPicker.ts`, `pickerFilters.ts`),
      `ManyToManyRelationshipEditor`, `JoinEntityFormModal`, `ChildFormModal` (same folder),
      `components/DisplayWizard/RelationshipPickerDialog.tsx`.
   2. API: `Controllers/LookupController.cs` (`POST api/lookup/{entityType}/search`) + `Services/LookupService.cs`,
      configured in `Attributes/DashboardLookups.cs`; `RelatedEntityField` / `NavigationPair` attributes.
5. **Current specs:** [web-app architecture § relation picker](web-app-architecture.md),
   [m2m-editor-current-spec](../specs/form-configurations/m2m-editor-current-spec.md).

## 4. Validation, conditions and reusable steps (inside FormWizard)

1. **For:** field validation rules run by the API (rule types such as `LocationInsideRegion`, `RegionContainment`,
   `ConditionalRequired`), dependencies between fields, placeholders in messages, the validation result log, step
   conditions and step jump, and steps or fields reused across forms (copy or link).
2. **Required when:** a form needs a rule across fields or against other data, or repeats a step another form has.
   Add a rule type (`IValidationMethod`) rather than checking in a custom page or a controller only.
3. **Exception when:** a plain per-field check the form field already offers (required, range, regex, email).
4. **Entry points:**
   1. API: `Models/FormConfiguration/FieldValidationRule.cs`, `Services/ValidationService.cs`,
      `Services/ValidationMethods/` (`IValidationMethod`), `DependencyResolutionService`, `PlaceholderResolutionService`,
      `Models/StepCondition.cs`; reusable steps and fields via `FormStep.IsReusable`/`SourceStepId` and
      `GET api/formconfigurations/reusable-steps`, `reusable-fields`.
   2. Web app: `apiClients/fieldValidationRuleClient.ts`, `utils/forms/fieldRuleValidation.ts`,
      `hooks/useEnrichedFormContext.ts`, `utils/placeholderInterpolation.ts`, `utils/forms/stepConditions.ts`,
      `utils/forms/stepJumpCheck.ts`, `FormConfigBuilder/ValidationRuleBuilder.tsx`, `ReusableStepSelector.tsx`.
   3. Auto-fill: there is no general auto-fill yet; the only cross-field fill is the ItemScan result inside
      `FormWizard.tsx` (`applyItemScanResult`, not exported). A feature that needs one proposes it as a FormWizard
      extension.
5. **Current specs:** [form-validation QUICK_REFERENCE](../specs/form-validation/QUICK_REFERENCE.md) and
   [README](../specs/form-validation/README.md). The phase reports in that folder are history.

## 5. World tasks, including WorldGuard regions

1. **For:** a form field whose value comes from the game: a location, a WorldGuard region (new from a selection or
   existing), a block scan. The web app creates a `WorldTask`, a player claims it in game (`/knk task`) or a headless
   handler runs it, the result fills the field. Regions start as `tempregion_worldtask_<id>` and are renamed to
   `domain_<id>` (or `domain_<id>_sub_<n>`) on save; the plugin then sets parent, priority and flags.
2. **Required when:** any web flow needs a location, region or other in-game capture for an entity.
3. **Exception when:** the capture is part of a purely in-game flow with no web form (a command or menu does it).
4. **Entry points:**
   1. Web app: `components/Workflow/WorldBoundFieldRenderer.tsx`, triggered by a field whose `settingsJson` has
      `worldTask.enabled`; task types `utils/forms/worldTaskTypes.ts`, lifecycle `utils/forms/worldTaskLifecycle.ts`.
   2. API: `Models/WorldTask.cs` (`WorldTaskStatuses`), `Controllers/WorldTasksController.cs`,
      `Services/WorldTaskService.cs`, `WorldTaskSweepService`, `Services/DomainRegionNameFinalizer.cs`,
      `Services/RegionService.cs`, `TempRegionReleaseService`.
   3. Plugin: `paper/tasks/WorldTaskHandlerRegistry.java` with `IWorldTaskHandler` (`IHeadlessWorldTaskHandler`),
      `LocationTaskHandler`, `WgRegionIdTaskHandler`; `paper/realtime/WorldTaskRealtimeSync.java`;
      `paper/commands/KnkTaskClaimCommand.java`; managed regions `paper/regions/managed/ManagedRegionsBootstrap.java`
      and `core/regions/managed/ManagedRegionReconciler.java`.
5. **Current specs:** [world-tasks README](../specs/world-tasks/README.md),
   [managed WorldGuard regions](managed-worldguard-regions.md) § 7. Files there marked "Historical" are history.

## 6. Plugin building blocks

Required for any plugin feature that needs the same thing; an exception is a decision log row.

| Need | Use | Spec |
|---|---|---|
| Read API data with cache | `paper/dataaccess/DataAccessFactory.java`, `core/dataaccess/DataAccessExecutor.java` | [plugin cache system](plugin-cache-system.md) |
| Call the API | `api/impl/BaseApiImpl.java` (every `*ApiImpl`) | [plugin API client pattern](plugin-api-client-pattern.md) |
| Permission check | `paper/permissions/KnkPermissible.java` | [plugin permission checks](plugin-permission-checks.md) |
| Inventory menu | `paper/menu/MenuService.java` on `core/menu/` | [inventory-menu spec](../specs/inventory-menu/) |
| Cache invalidation on change | `core/realtime/EntityChangeRouter.java` | [plugin cache system](plugin-cache-system.md) |
| World behaviour test | `core/scenario/ScenarioRegistry.java`, `/knk scenario` | [plugin scenarios](../guides/developer/plugin-scenarios.md) |

## 7. Web app building blocks

`components/Dialog.tsx`, `hooks/useConfirm.tsx` (`ConfirmDialog`), `components/FeedbackModal.tsx`,
`components/Pager.tsx`, `components/DataTable.tsx`, `components/PagedEntityTable/`, `components/SearchableDropdown.tsx`.
Use these before writing a new dialog, confirm, toast-like modal, pager or table.
