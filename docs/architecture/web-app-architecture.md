# knk-web-app — Architecture

**Status:** Living document — reflects actual code, updated in place on each rescan
**Last updated:** 2026-09-18 (scan basis: `knk-web-app` @ `4ff5dc6`, branch `claude/web-app-codebase-scan-4yqibi`); spot edits 2026-10-09 (ObjectTypeExplorer, KNG-61), 2026-10-10 (FormWizard Boolean fields, KNG-53), 2026-10-12 (FormWizard child forms, KNG-133, KNG-134; List edit load, step header, List validation, KNG-135, KNG-137, KNG-164; form session registry, KNG-136; cancel / delete-draft prompt, KNG-162; form configuration export/import, KNG-138); 2026-10-17 (form wizard chain merged to `main`; smoke-test follow-ups KNG-166..169, KNG-172, KNG-173: step strip, confirmations and refusals, rule builder parent forms, picker columns, metadata refresh); 2026-10-22 (display configuration export/import; KNG-195 hybrid picker submit); 2026-10-23 (step completion conditions run, KNG-186); 2026-10-23 (validation result log, batch validate, Re-check, KNG-269); 2026-10-25 (toast region, world-task polling; UX re-evaluation in `reports/2026-10-25-web-app-ux-reevaluation.md`); 2026-10-26 (dashboard type in the URL, `returnTo`, submit pending state, success toast — PandiO/knk-workspace#177 link 1, #58); 2026-10-26 (dashboard header New/Configure, flat explorer with marker, open form without the explorer + breadcrumb, detail page header, metadata-driven Create New, "Entity setup" — #177 link 2, #81, #39); 2026-10-26 (dashboard explorer: one scrollbar, favourite types — #194, branch `claude/dashboard-explorer-194`, not merged)
**Source scan:** `docs/reports/web-app-scan-2026-09-18.md`

## Stack

- React 18 + TypeScript, bootstrapped with **Create React App** (`react-scripts` 5.0.1) —
  not Vite, not Next.js.
- Routing: `react-router-dom` v7 (`BrowserRouter`/`Routes`/`Route`), all defined in
  `src/App.tsx`.
- Styling: Tailwind CSS utility classes only. Fluent UI (`@fluentui/react-components`)
  was removed 2026-10-08 (KNG-71): only its provider was used. Shared component classes in
  `src/index.css`: `.btn` (`inline-flex`, `gap-2`; an icon's own `mx` margin is dropped under it) with
  `.btn-primary` / `-secondary` / `-tertiary` / `-danger`, `.panel`, `.input`. Colours in `tailwind.config.js`:
  `primary` (`DEFAULT`, `light`, `dark`), `secondary`, `accent`, `surface`. `@tailwindcss/forms` is **not** installed:
  a field written `rounded-md border-gray-300 …` gets its 1px border from a zero-specificity base rule in `index.css`
  (#38, 2026-10-26, branch `claude/styling-quick-wins-38`); `src/__tests__/tailwindStyles.test.ts` compiles the CSS
  and checks these. Tokens follow in #95.
- Drag-and-drop: `@dnd-kit/*` (used in `FormWizard`, `FormConfigBuilder`,
  `DisplayConfigBuilder` for reorderable steps/sections/fields).
- Icons: `lucide-react`.
- Reactive error bus: `rxjs` — a single `Subject`-like `logging.errorHandler` used to
  surface toast-style errors app-wide (`src/components/ToastRegion.tsx`, mounted in `App.tsx`). Success toasts go through `toast.success()`
  (`src/utils/toast.ts`, its own `Subject`; green, 5 s; #177 link 1); the full feedback kit is #33.
- No Redux/Zustand/MobX — state is local `useState`/`useEffect` plus one React Context
  (`AuthContext`) for auth, plus a small manual in-memory cache in
  `hooks/useEntityMetadata.ts` (module-level `metadataBundleCache` /
  `metadataBundlePromise`, not React state).
- Testing: Jest + React Testing Library (`react-scripts test`), 38 `*.test.ts(x)` files;
  Cypress for e2e (2 specs: `hello-world.cy.ts`, `registration.cy.ts`).

## High-level shape

The app is **metadata/config-driven** rather than having one hand-built page per
entity. Two parallel generic engines carry most of the CRUD surface:

1. **Form engine** (`FormWizard/`, `FormConfigBuilder/`) — renders a create/edit form
   for any backend entity from a `FormConfigurationDto` fetched from the API
   (`formConfigClient`), rather than a hardcoded form-per-entity. `FormConfigBuilder`
   is the admin UI for authoring those configurations.
   **Boolean fields** (KNG-26, KNG-53): a checkbox can't show "no value", so every path that seeds
   step data (new form, resumed draft, edit form, child/join prefill, a field shown by a condition)
   holds a real boolean - the authored default, else `false` - via `seededFormFieldValue`
   (`utils/forms/formFieldDefaultValue.ts`). Required means "value is present", so an unchecked box
   (`false`) passes; "must be ticked" would be a separate validation rule.
   **Child forms** (KNG-133, decision D1 = A; merged to `main` 2026-10-17 with the form wizard chain,
   branch `claude/wonderful-darwin-u39k1o`): "Create New" / "Edit instance" on a relationship field opens `ChildFormModal` with a nested
   `FormWizard`. When the child completes, its entity is saved at once through its own create/update
   API for every **List** field (owned collection or not) and every **Object** field except a single
   **Location**, which stays an embedded value saved with its parent
   (`utils/forms/childPersistence.ts` → `shouldPersistChildOnComplete`). Many-to-many steps save
   created entities themselves (`ManyToManyRelationshipEditor.handleCreateRelatedEntity`).
   `normalizeFormSubmission` sends relationships as ids and throws `UnsavedRelationshipValueError`
   (naming the field) for an id-less entity in an Object (not Location) or List field, so nothing is
   dropped silently; the wizard shows the message and doesn't mark the progress Completed.
   **Edit instance** (KNG-134): `handleOpenChildForm` hands the child the instance the
   parent holds (`initialValues`) and whether its edits live only in the parent (`editingInMemory`:
   a child not saved on completion, i.e. an embedded Location). Without an id the child form is
   seeded from it (title "Edit …"); with an id and `editingInMemory` the nested `FormWizard` loads
   from the database and lays the held values over it (`overlayFieldValues`); otherwise the database
   is the source (`utils/forms/childEditSeed.ts`). "Replace via Minecraft" keeps an existing Location
   id, and a world task a child inherits onto its first field spreads an object result over the
   child's fields of the same name (`utils/forms/worldTaskFieldValue.ts`). `ListField` keys, removes
   and edits items by position/client key, not by id (`utils/forms/listItemKeys.ts`).
   **List fields in edit mode** (KNG-135): `resolveObjectFieldValueForEdit`
   (`utils/forms/objectFieldEditValue.ts`) also pairs List relationship fields across `XIds` / `Xs`:
   an `XIds`-authored field takes the DTO's `Xs` objects (bare ids become `{ id }`), an `Xs`-authored
   field falls back to `{ id }`s from `XIds`. The edit load and Edit-instance seeding both use it.
   **List validation** (KNG-164): `validateField` sends List fields to
   `utils/forms/listFieldValidation.ts`: a required List needs at least one item, `minSelection` /
   `maxSelection` are enforced (null or 0 = no limit), an owned child collection is skipped until its
   parent is saved. **Step header** (KNG-137, KNG-168): `FormWizard/WizardStepHeader.tsx` shows
   step names in the progress bar (truncated, hidden below `md`) and keeps the step name as the
   title in edit mode under a small "Edit {entity}" heading; Boolean fields render their description.
   A strip with more steps than fit scrolls sideways (current step kept in view, ‹ › only on a side
   that hides steps, `stepStripOverflow`). Below `sm` a compact "Step 3 of 9 · Name" label and bar
   replace the circles; the label is a disclosure button listing every step (done / current / to do),
   closed again on a step change. Steps are not clickable yet (KNG-184). **Step completion conditions** (KNG-186): `handleNext` runs a step's `Completion` conditions (`ConditionEvaluator.evaluateConditions` over the step's data) unless the condition's `isActive` is explicitly `false`; until 2026-10-23 the API sent `false` for every condition, so none ever ran. `FormConfigurationDto.isActive` is gone (the API never had the column; `parentFormFields.ts` filters on `isDefault` only). **Validation result log** (KNG-269): Next validates a step's rule-bearing fields with one `validate-batch` request that names the subject (`entityName` + `entityId` in edit mode, else `FormSubmissionProgress` + the saved draft id; `FormWizard.validationSubject`), so the API can answer a rule from its log of the last run. A result with `metadata.fromCache` shows "checked … ago" (`utils/forms/validationResultAge.ts`) and a **Re-check** button, which re-runs that field with `force: true`; the debounced per-field run on change keeps using `validate`.
   **World-task values** (KNG-167): a capture spread over a child's fields keeps a Name the admin
   typed (`utils/forms/worldTaskFieldValue.ts`); rule placeholders built from an Object field use
   the entity's name, not the object (`utils/placeholderExtraction.ts`, KNG-173).
   **Form session registry** (KNG-136): the exported `FormWizard` wraps its body in a
   `FormSessionScope` (`contexts/FormSessionContext.tsx`). The first wizard with no session above it
   (normally `FormWizardPage`'s) owns the registry for its lifetime; wizards nested in
   `ChildFormModal`/`JoinEntityFormModal` join it and add their entity name to the form path.
   `handleChildFormComplete` and `ManyToManyRelationshipEditor.handleCreateRelatedEntity` register
   what a child saved (`useFormSession().register`: type, id or a concept key for an embedded value,
   display DTO, origin form path + field, `created`/`updated`, order). `ObjectField`/`ListField` get
   the created, non-embedded entries of their `objectType` as `pinnedRows` plus a `refreshKey`
   (`hooks/useSessionPinnedRows.ts`; Locations are never pinned). `PagedEntityTable` shows them in a
   "Created in this form" section with a New badge, filtered by the search term and the query's
   filters on the client and de-duplicated against the page (`utils/forms/sessionPinnedRows.ts`);
   rows are keyed and selected by id (`isSameSelection`), not by array index.
   **What a form created, and cancelling it** (KNG-162): the root wizard of a session
   (`formPath.length === 1`, no `parentProgressId`; `hooks/useCreatedEntitiesProvenance.ts`) sends
   `createdEntitiesJson` with every progress save (`utils/forms/createdEntities.ts`: type, id, label
   fields, origin, creation order); resuming that draft seeds the registry (`seed()`), so pickers pin
   the entities again. `FormWizardPage` wraps the wizard in `FormSessionRoot` (a registry without a
   form-path entry) next to `FormWizard/FormCancelAction.tsx` ("Cancel form"); deleting a draft from
   Saved Progress reads the summary's `createdEntitiesJson`. Both show `CreatedEntitiesPrompt` (Keep =
   default, Delete); Delete runs `utils/forms/deleteCreatedEntities.ts`: newest first, the API's
   `entity-references` check (entities still pending in the run ignored), then the entity's normal
   delete (`getDeleteFunctionForEntity`); in use / 409 = skipped and reported. Cancel never deletes
   the draft; nothing is deleted automatically.
   **Submit and the way back** (#177 link 1, #58): a form opened from another page carries
   `?returnTo=` (`utils/returnTo.ts`: `editFormPath`/`newFormPath`/`withReturnTo`, same-origin paths
   only via `sanitizeReturnTo`). On the last step the wizard saves the progress as `InProgress`, then
   **awaits** `onComplete` (the page's `handleComplete`, which saves the entity and returns
   `true`/`false`), and marks the progress `Completed` only after a successful save, then calls
   `onCompleted`. A refused save (false or a throw) leaves the draft `InProgress`, so the cleanup of
   completed progress never deletes a draft whose entity doesn't exist. During that window Submit reads
   "Submitting…" and is disabled (a ref guards re-entry), Previous / Save Draft / the page's Cancel are
   disabled (`onSubmittingChange`), and a "Saving {Type}…" line shows. After `onCompleted` the page goes
   straight to the parent display page (child creation), else `returnTo`, else `/dashboard/{type}`,
   with a success toast ("{Type} created." / "updated."); the old 3 s success modal is gone. Cancel
   (`handleLeaveForm`) goes to the parent display page, else `returnTo`, else stays on the Entity setup
   page (`/forms`).
   **Open form** (#177 link 2): while the wizard is open, `FormWizardPage` hides the
   `ObjectTypeExplorer` and shows a breadcrumb (`components/Breadcrumbs.tsx`) built by
   `utils/breadcrumbs.ts` `formTrail` from `returnTo` ("Dashboard › Town › Edit Cinix"; without
   `returnTo`: "Entity setup › Town › New Town"). The trail is plain `{label, to?}[]` data so the admin
   layout (#30) can render it later; `useEntityLabel` fetches the edited entity's name (else "#id"). A
   crumb leaves the form without the Cancel question. The configuration lists keep the explorer.
   "New" (`?autoOpen=true`) on a type without a default form configuration shows "To create a new
   {Type}, this type needs a default form configuration" (#177 decision 3). The page title and nav label
   are **"Entity setup"** (route `/forms` unchanged, decision 4).
   `ChildFormModal` returns `false` from its `onComplete` on a failed child save for the same reason.
   **Export / import** (KNG-138): the form configuration list (`FormWizard/FormConfigurationTable.tsx`)
   has **Export JSON** per row (downloads the API's portable `knk-formconfig/1` file,
   `utils/forms/formConfigPortability.ts`) and **Import / Seeds**, which opens
   `FormWizard/FormConfigurationImportPanel.tsx`: choose a file or a bundled seed, the API dry-runs it,
   the result (problems, warnings, default handling) is shown, and Import is offered only after a
   passing dry run with the current "make default" choice. `formConfigClient.importConfiguration` /
   `importSeed` resolve with the result body on a 400/409 refusal instead of raising the global error
   toast. Deleting a form configuration (KNG-172) warns how many saved drafts go with it
   (`utils/forms/formConfigDeleteConfirm.ts`, from the API's `entity-references`); the API detaches its
   form sessions and removes its drafts, so only real uses (another form opening it as a sub-form)
   refuse the delete.
   **Display configurations** (merged 2026-10-22): `FormWizard/DisplayConfigurationTable.tsx` has the
   same **Export JSON** per row (`knk-displayconfig/1`, `utils/displayConfigPortability.ts`) and
   **Import / Seeds** (`FormWizard/DisplayConfigurationImportPanel.tsx`). Both import panels are thin
   wrappers around the shared `FormWizard/ConfigurationImportPanel.tsx` (dry run first, result shown,
   Import only after a passing dry run); the display one adds the draft option.
   `displayConfigClient.exportConfiguration` / `getSeeds` / `importConfiguration` / `importSeed`.
   **Catalog pickers on submit (KNG-195):** `normalizeFormSubmission` sends a
   `HybridMinecraftEnchantmentRefPicker`, and an Object picker on MinecraftMaterialRef/BlockRef/EnchantmentRef
   (which runs the hybrid search), as `{field}Id` + `{field}NamespaceKey`; a catalog row that isn't saved yet
   (id 0) goes by namespace key only, and the API creates the ref.
   **Confirmations and refusals** (KNG-169, KNG-82): no `window.confirm`/`alert` is left. Questions
   go through `hooks/useConfirm.tsx` (`const [confirm, confirmModal] = useConfirm()`, a
   `FeedbackModal` with confirm/cancel labels and a red `danger` button); the configuration tables
   hand a delete to the page, which asks once. A refused operation shows the API's reason
   (`utils/apiRefusalReason.ts`; the API's 409 names what still uses the item), never "please try
   again". A `FeedbackModal` without `onContinue` shows a single Close button.
   **Rule builder** (`FormConfigBuilder/ValidationRuleBuilder.tsx`): "Depends On Field" also lists
   the fields of the forms this one is opened from (`utils/forms/parentFormFields.ts`: default
   configurations with an owned-child List or M2M step of this entity, up to 3 levels); a dependency
   path then starts at that parent's entity. The filter does not use `isActive`, which the API never
   sets (KNG-186).
2. **Display engine** (`DisplayWizard/`, `DisplayConfigBuilder/`) — same pattern for
   read-only entity detail views, driven by `DisplayConfigurationDto`
   (`displayConfigClient`).

**Dashboard as the CRUD hub** (`ObjectDashboard`, `/dashboard`; #177): the selected type is in the
URL as `/dashboard/:entityName` and bare `/dashboard` reopens the last viewed type from localStorage
`knk.dashboard.lastEntityType` (`utils/lastDashboardType.ts`, link 1). Next to the type's title:
**"New {Type}"** (`newFormPath(type, returnTo)`) and a cogwheel **"Configure {Type}"** to the type's
Entity setup page (`/forms/{type}`); "New {Type}" is also the empty state of the table
(`PagedEntityTable` `emptyState`, shown only without a search or filter). The explorer is one flat
list: types without a published default display configuration get a muted marker ("No display
configuration – set one up via ⚙", `ObjectTypeExplorer` `marked`), and for them View and the row
click are disabled with the same hint. Only the explorer's list scrolls (the sidebar column is `overflow: hidden` and
the explorer's `aside` is `min-h-0`; it used to show two scrollbars, #194). A star on each type toggles it as a
**favourite** (`ObjectTypeExplorer` `favourites`): favourites are listed first under "Favourites", sorted like the rest,
which follows below; they are kept per browser in localStorage `knk.dashboard.favouriteEntityTypes`
(`utils/dashboardFavourites.ts`; per account on the API can come later). The Entity setup page's explorer has no stars.
View opens `/display/{type}/{id}?returnTo=…`, Edit
`/forms/{type}/edit/{id}?returnTo=…`, except **User rows: Edit opens the player profile**
`/admin/users/{id}` (`utils/returnTo.ts` `entityEditPath`; the generic User form stays for create
until #72/#148).

**Detail page** (`DisplayWizardPage`, #81): `EntityDetailHeader` replaces the heading that showed the
display configuration's name: the entity's own name (`utils/entityLabel.ts`), its type, a breadcrumb
(`detailTrail`), **Back** to `returnTo` (else `/dashboard/{type}`), **Edit** coming back to the page and
**Delete** with a confirmation naming the entity (success toast, then Back's target). The tab title is
"{name} · {Type}". `DisplayWizard` takes the header as `renderHeader(entity)`.

**Create New menu** (`components/CreateNewMenu.tsx`, #177 link 2 / #39 CRUD-2): built from the entity
metadata — every type with a create client in `utils/entityApiMapping.ts`
(`hasCreateFunctionForEntity`), A–Z — instead of the hand-kept list in `config/objectConfigs.tsx`,
which offered `itemType` (no API mapping) and missed about 15 types. A pick opens the default form and
comes back to the dashboard on that type. A filter box gets focus on open (ArrowUp/ArrowDown, Enter,
Escape). Without metadata the built-in list is the fallback.

A third, older, simpler config path — `src/config/objectConfigs.tsx`, a static
TypeScript map of `ObjectConfig` per entity type (fields, icons, validators,
formatters) — still gives `ObjectDashboard` and the pickers their built-in table columns
(`getColumnDefinitions`), the Create New menu its icons, and the dashboard its type list when the
metadata can't be loaded. Its type list (19 types, including the unmapped `itemType`) is not the
backend's live metadata list (`metadataClient.getAllEntityMetadata`), which the dashboard, the
explorer, the Create New menu and the form/display engines use — see
`docs/reports/web-app-scan-2026-09-18.md` for the "two competing config systems" note under
Legacy/Orphaned.

Entity metadata itself (which fields exist on which backend entity, display config,
validation rules) is fetched once per session and cached at module scope by
`hooks/useEntityMetadata.ts`, then merged with `EntityTypeConfigurationDto` (per-entity
icon/color/sort overrides, authored via the — currently unrouted —
`EntityTypeConfigurationPage`). Each hook instance holds its own copy; a `refresh()` (e.g. after
saving default table columns) notifies every mounted instance, so an open picker picks the change up
without remounting.

**Picker columns** (KNG-166): `PagedEntityTable` shows the entity's saved default table columns
(Entity setup page → Default Table Columns) or else the built-in columns of
`config/objectConfigs.tsx` (District: Town, World; Street: Districts, Towns; Structure and
GateStructure: street + number, District, Town). Built-in columns read the list DTO's flat field and
fall back to the full DTO's nested shape (`utils/forms/pickerRowValues.ts`), so pinned and searched
rows match. A saved key (a metadata field name such as "Town") is matched to the built-in column with
the same key, key + "Name", or the same label (`utils/forms/savedColumns.ts`). Saving no columns clears
them ("Use built-in columns"; the API stores an empty list as none).

## Directory map

```
src/
  App.tsx                 — route table + top-level error toast plumbing
  pages/                  — one component per route (see reading guide for the table)
    admin/                — GameSettingsPage (routed), EntityTypeConfigurationPage (NOT routed)
    auth/                 — login/register/forgot/reset pages + barrel index.ts
  components/
    FormWizard/            — generic create/edit engine (config-driven)
    FormConfigBuilder/      — admin UI to author FormConfigurationDto records
    DisplayWizard/          — generic read-only detail-view engine; `EntityDetailHeader` (name, Back/Edit/Delete, #81)
    DisplayConfigBuilder/   — admin UI to author DisplayConfigurationDto records
    ObjectDashboard/        — legacy static-config-driven list/CRUD dashboard
    ObjectTypeExplorer/     — left-nav entity type picker (ObjectDashboard, FormWizardPage): search, A–Z/Z–A sort, optional groups (unused since #177 link 2), `marked` entries, `favourites` with a star per type (#194, dashboard only), settings in localStorage (KNG-61)
    PagedEntityTable/       — generic server-paged table, used by both dashboard and forms
    PathBuilder/            — path/reference picker for cross-entity field bindings
    Workflow/               — WorldTask/job polling UI (siege/world-mutation background tasks)
    minecraft/              — hybrid pickers for Minecraft material/enchantment refs
    auth/                   — multi-step registration form, login form, password strength meter
    currency/               — ledger table, Adjust balance card, and StaffNoteField: the reason field of every staff form
                              that needs MIN_STAFF_NOTE_LENGTH characters (live "n / 10 characters" counter, message after
                              a submit with a short note; the form keeps its button enabled and checks isStaffNoteValid, KNG-126)
    shared/, DynamicForm.tsx, ObjectView.tsx, ... — see scan report for orphan status
  contexts/AuthContext.tsx  — the only Context; owns user/isLoggedIn/login/register/logout/refresh
  hooks/                    — useAuth (re-export of AuthContext), useEntityMetadata (cache),
                              useEnrichedFormContext, useRelationshipDrafts, useAutoLogin (unused)
  apiClients/               — one REST client class per backend resource (25 files), all
                              extending ObjectManager (see Data flow below)
  services/
    serviceCall.ts          — low-level fetch wrapper (headers, JSON parsing, error shape)
    authService.ts          — auth orchestration used by AuthContext (token storage side effects)
  utils/
    tokenService.ts         — localStorage/sessionStorage token persistence
    config-helper.ts         — ConfigurationHelper.gatewayApiUrl → appConfig.api.baseUrl
    enums.ts                 — Controllers enum (maps client → backend controller route segment)
  config/
    appConfig.ts              — base API URL config (not a REACT_APP_* env var)
    objectConfigs.tsx          — legacy static per-entity-type config (see above)
  types/
    dtos/<resource>/           — one folder per backend resource, hand-maintained DTOs
    uiObjectConfig/, domain/    — form/display config domain types + mappers
  prompts/                    — checked-in Markdown design/requirements docs for past features
                                (not app code — arguably belongs under knk-workspace docs, see
                                reading guide)
```

## Data flow: web-app → web-api

Every REST call goes through the same three-layer stack:

1. **Resource client** (`src/apiClients/<resource>Client.ts`) — a thin class extending
   `ObjectManager`, exposing typed methods (e.g. `authClient.login(...)`,
   `townClient.getAll()`). Each method calls `this.invokeServiceCall(data, operation,
   controller, httpMethod)`.
2. **`ObjectManager.invokeServiceCall`** (`src/apiClients/objectManager.ts`) — wraps the
   call in a `Promise` with a 15s manual timeout, builds `InvokeServiceArgs`, and hands
   off to `serviceCall.invokeApiService`. Logs errors through `logging.errorHandler`,
   which is what feeds the toast UI in `App.tsx`.
3. **`ServiceCall.invokeApiService`** (`src/services/serviceCall.ts`) — builds the final
   URL as `{ConfigurationHelper.gatewayApiUrl}/{controller}[/{operation}]`, attaches
   `Authorization: Bearer <token>` from `tokenService.getAccessToken()` when present,
   sends `credentials: 'include'` (cookies, for refresh-token flow), and does the actual
   `fetch`.

The `controller` segment for each resource comes from the `Controllers` enum
(`src/utils/enums.ts`), e.g. `Controllers.Auth = 'Auth'`, `Controllers.GateStructures =
'GateStructures'` — this enum is the single source of truth mapping a client to its
backend route and should be cross-checked against `knk-web-api`'s actual controller
names when doing cross-repo work (not verified against knk-web-api in this pass — see
Uncertain items below).

Base URL resolution: `ConfigurationHelper.gatewayApiUrl` (`src/utils/config-helper.ts`)
→ `appConfig.api.baseUrl` (`src/config/appConfig.ts`) — confirmed **not** wired through
a `REACT_APP_*` environment variable, matching the note already in this repo's
`CLAUDE.md`.

## Auth

- `AuthProvider` (`src/contexts/AuthContext.tsx`) wraps the whole app in `App.tsx` and
  owns `user`, `isLoggedIn`, `login`, `register`, `logout`, `refresh`.
- On mount, `AuthProvider` calls `authService.autoLogin()`, which tries
  `GET /Auth/me` and, on failure, tries a refresh-token flow
  (`POST /Auth/refresh`, cookie-based) before retrying `me`.
- `ProtectedRoute` (`src/components/ProtectedRoute.tsx`) gates every non-public route:
  shows a spinner while `isLoading` or while a silent refresh is in flight, then
  redirects to `/auth/login` (preserving `location.state.from`) if still unauthenticated.
- Access tokens: `tokenService` (`src/utils/tokenService.ts`) stores the bearer token in
  `localStorage` when "remember me" was set at login, `sessionStorage` otherwise; a
  separate `RememberMe`/`RememberMeExpiresAt` pair in `localStorage` tracks whether the
  remembered session is still within its window.
- Registration auto-logs the user in afterward (`authService.register` calls
  `this.login(...)` with `rememberMe: true` once registration succeeds).
- Minecraft-account linking (`authClient.generateLinkCode` /
  `requestLinkCode` / `linkAccount` / `linkMinecraftAccount`) is implemented
  client-side and exposed through `AccountManagementPage` and the registration flow's
  `LinkCodeDisplay` — this is the web-app half of the plugin's link-code account
  merge feature; the plugin/API side of this was not verified in this pass.

## Talks to (other components)

- **knk-web-api**: REST only, JWT bearer + a refresh cookie, as above. No GraphQL,
  no websockets/SSE anywhere in `src/`. World-task status is polled every 2 s by
  `components/Workflow/WorldBoundFieldRenderer.tsx` (`TaskStatusMonitor` was deleted) and catalog scans
  every 3 s; the SignalR plan replaces both ([`specs/realtime-signalr/DESIGN.md`](../specs/realtime-signalr/DESIGN.md), #66; 2026-10-25).
- **knk-plugin**: no direct contact — the web app never talks to the plugin. The only
  connection is indirect, via `knk-web-api`, through the Minecraft-account link-code
  flow described above.

## Known structural risks (see scan report for full detail/citations)

- Two independent, only-partially-overlapping "which entities exist" registries
  (`config/objectConfigs.tsx` static map vs. the live `metadataClient` bundle) —
  adding an entity to one does not automatically add it to the other.
- `pages/admin/EntityTypeConfigurationPage.tsx` is fully built but has no route in
  `App.tsx` and no link in `Navigation.tsx` — currently unreachable in the running app.
- ~~`DisplayWizardPage`'s `edit`/`create` action handlers navigate to `/form/...`~~ —
  fixed: they go to `/forms/...` with a `returnTo` to the detail page (#177 link 2, #81).
- `components/DynamicForm.tsx` and `components/ObjectView.tsx` are large (383 and 411
  lines), fully unreferenced, and (for `DynamicForm.tsx`) import three apiClient
  modules — `apiClients/districts`, `apiClients/streets`, `apiClients/locations` —
  that no longer exist under those names in the codebase. They read as the
  predecessors to `FormWizard`/`DisplayWizard` left behind after that migration.

## Uncertain / needs a follow-up pass

- Whether `tsconfig.app.json`/`tsconfig.node.json`/`tsconfig-deps.json` (Vite-style
  project-reference layout) are actually honored by `react-scripts` 5, or are dead
  scaffolding like the already-flagged unused `eslint.config.js` — if `react-scripts`
  ignores them, `DynamicForm.tsx`'s broken imports may or may not surface as a type
  error in `npm run build`. Not run in this read-only pass; worth a quick `npm run
  build` check before relying on this doc's compile-safety assumptions.
- The `Controllers` enum route-segment values were not cross-checked against
  `knk-web-api`'s actual controller route attributes in this pass — do that as part of
  the `knk-web-api` scan or the consolidated cross-repo report.
- Whether the Minecraft-account link-code feature described above is actually
  consumed by `knk-plugin` today (this scan only covers `knk-web-app`).
