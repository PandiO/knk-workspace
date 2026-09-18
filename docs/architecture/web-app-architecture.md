# knk-web-app — Architecture

**Status:** Living document — reflects actual code, updated in place on each rescan
**Last updated:** 2026-09-18 (scan basis: `knk-web-app` @ `4ff5dc6`, branch `claude/web-app-codebase-scan-4yqibi`)
**Source scan:** `docs/reports/web-app-scan-2026-09-18.md`

## Stack

- React 18 + TypeScript, bootstrapped with **Create React App** (`react-scripts` 5.0.1) —
  not Vite, not Next.js.
- Routing: `react-router-dom` v7 (`BrowserRouter`/`Routes`/`Route`), all defined in
  `src/App.tsx`.
- Styling: Tailwind CSS utility classes + `@fluentui/react-components` (Fluent UI) —
  both are actually used, not one superseding the other.
- Drag-and-drop: `@dnd-kit/*` (used in `FormWizard`, `FormConfigBuilder`,
  `DisplayConfigBuilder` for reorderable steps/sections/fields).
- Icons: `lucide-react`.
- Reactive error bus: `rxjs` — a single `Subject`-like `logging.errorHandler` used to
  surface toast-style errors app-wide (see `src/App.tsx` lines 40–58).
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
2. **Display engine** (`DisplayWizard/`, `DisplayConfigBuilder/`) — same pattern for
   read-only entity detail views, driven by `DisplayConfigurationDto`
   (`displayConfigClient`).

A third, older, simpler config path — `src/config/objectConfigs.tsx`, a static
TypeScript map of `ObjectConfig` per entity type (fields, icons, validators,
formatters) — still drives `ObjectDashboard` (the `/dashboard` list/CRUD view) and the
"Create New" menu in `Navigation`. It currently only covers 11 entity types
(`location, town, district, structure, street, category, itemType,
minecraftblockref, minecraftmaterialref, gatestructure, gatedoor`), while the
form/display engines pull their entity list from the backend's live metadata endpoint
(`metadataClient.getAllEntityMetadata`), so the two config systems are not the same
list and can drift — see `docs/reports/web-app-scan-2026-09-18.md` for the "two
competing config systems" note under Legacy/Orphaned.

Entity metadata itself (which fields exist on which backend entity, display config,
validation rules) is fetched once per session and cached at module scope by
`hooks/useEntityMetadata.ts`, then merged with `EntityTypeConfigurationDto` (per-entity
icon/color/sort overrides, authored via the — currently unrouted —
`EntityTypeConfigurationPage`).

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
    DisplayWizard/          — generic read-only detail-view engine
    DisplayConfigBuilder/   — admin UI to author DisplayConfigurationDto records
    ObjectDashboard/        — legacy static-config-driven list/CRUD dashboard
    ObjectTypeExplorer/     — left-nav entity type picker used by ObjectDashboard
    PagedEntityTable/       — generic server-paged table, used by both dashboard and forms
    PathBuilder/            — path/reference picker for cross-entity field bindings
    Workflow/               — WorldTask/job polling UI (siege/world-mutation background tasks)
    minecraft/              — hybrid pickers for Minecraft material/enchantment refs
    auth/                   — multi-step registration form, login form, password strength meter
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
  no websockets/SSE observed anywhere in `src/` (the `Workflow/TaskStatusMonitor` and
  `WorldTask`-related code poll via `worldTaskClient`, not push — see scan report,
  though note `TaskStatusMonitor` itself is currently unreferenced/orphaned).
- **knk-plugin**: no direct contact — the web app never talks to the plugin. The only
  connection is indirect, via `knk-web-api`, through the Minecraft-account link-code
  flow described above.

## Known structural risks (see scan report for full detail/citations)

- Two independent, only-partially-overlapping "which entities exist" registries
  (`config/objectConfigs.tsx` static map vs. the live `metadataClient` bundle) —
  adding an entity to one does not automatically add it to the other.
- `pages/admin/EntityTypeConfigurationPage.tsx` is fully built but has no route in
  `App.tsx` and no link in `Navigation.tsx` — currently unreachable in the running app.
- `DisplayWizardPage`'s `edit`/`create` action handlers navigate to `/form/...`
  (singular), but the only matching routes are `/forms/...` (plural) — these two
  actions are effectively dead ends in the UI today.
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
