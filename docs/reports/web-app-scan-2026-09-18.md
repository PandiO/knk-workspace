# knk-web-app — Codebase Scan

**Date:** 2026-09-18
**Scope:** `knk-web-app` only, per `docs/guides/v3-codebase-scan-instructions.md` §1
**Method:** Read-only. Static grep/reference checks against the working tree of
`knk-web-app` at commit `4ff5dc6` (branch `claude/web-app-codebase-scan-4yqibi`), plus
`git log` for file provenance. No `npm install`/`npm start`/`npm run build` was run —
all "unused"/"broken" claims below are static-reference findings, not runtime-verified,
per the ground rules ("label as appears unused — verify" where not runtime-confirmed).
**Companion doc:** `docs/architecture/web-app-architecture.md` (structural summary,
updated in place); this report is the raw, dated findings it's built from.

---

## 1. Sitemap / route table

All routes are declared in `src/App.tsx`. "Linked from nav" = present in
`src/components/Navigation.tsx`'s visible links (only shown when `isLoggedIn`).

| Path | Page component | Protected? | Linked from nav? |
|---|---|---|---|
| `/` | `LandingPage` | No | Yes ("Home") |
| `/auth/register` | `RegisterPage` | No | No (reached via login page link) |
| `/auth/register/success` | `RegisterSuccessPage` | No | No (post-register redirect) |
| `/auth/login` | `LoginPage` | No | No (reached when logged out / via redirect) |
| `/auth/forgot-password` | `ForgotPasswordPage` | No | No (reached via login page link) |
| `/auth/reset-password` | `ResetPasswordPage` | No | No (reached via emailed link) |
| `/account` | `AccountManagementPage` | Yes | Yes (account dropdown) |
| `/dashboard` | `ObjectDashboard` | Yes | Yes ("Dashboard") |
| `/forms` | `FormWizardPage` (browse, no auto-open) | Yes | Yes ("Forms") |
| `/forms/:entityName` | `FormWizardPage` (browse entity, no auto-open) | Yes | via `/forms` |
| `/forms/:entityName/edit/:entityId` | `FormWizardPage` (edit) | Yes | via table row actions |
| `/admin/form-configurations` | `FormConfigListPage` | Yes | Yes ("Form Builder") |
| `/admin/form-configurations/new` | `FormConfigBuilder` | Yes | via list page |
| `/admin/form-configurations/edit/:id` | `FormConfigBuilder` (edit) | Yes | via list page |
| `/admin/display-configurations` | `DisplayConfigListPage` | Yes | Yes ("Display Builder") |
| `/admin/display-configurations/new` | `DisplayConfigBuilder` | Yes | via list page |
| `/admin/display-configurations/edit/:id` | `DisplayConfigBuilder` (edit) | Yes | via list page |
| `/admin/game-settings` | `GameSettingsPage` | Yes | Yes ("Game Settings") |
| `/display/:entityName/:id` | `DisplayWizardPage` | Yes | via dashboard/table "view" actions |

**Dead route candidate:** `src/pages/admin/EntityTypeConfigurationPage.tsx` (162 lines,
full CRUD UI for per-entity icon/color/sort-order config, built against
`entityTypeConfigurationClient`) has **zero** references anywhere in `src/` besides its
own file — not in `App.tsx`'s route table, not in `Navigation.tsx`. It is unreachable
in the running app. (`grep -rn "EntityTypeConfigurationPage" src/` → only its own
definition file.)

**Broken in-app navigation (verify at runtime):** `src/pages/DisplayWizardPage.tsx`
lines 14 and 20 call `navigate(`/form/${...}`)` (singular "form"), but no route named
`/form/...` exists — only `/forms/...` (plural). The `edit` and `create` actions
surfaced from any `DisplayWizard` action button are dead ends. The `view` action
(line 17, `/display/${...}`) is correct and matches the real route. `select`/`unlink`/
`add`/`remove` actions (lines 22–37) are stubs that only `console.log` — see §4.

## 2. Component inventory

Usage counts are static reference counts (`grep -rl <ComponentName> src --include=*.tsx
--include=*.ts`, excluding the file's own definition) — not a runtime/bundler trace, so
a component reached only via a dynamic string or reflection would be undercounted (none
observed in this codebase; all component usage found was direct JSX/import).

| Component | Purpose | Used by | Status |
|---|---|---|---|
| `Navigation` | Top nav bar, shown when logged in | `App.tsx` | Active |
| `ProtectedRoute` | Auth gate wrapper for routes | `App.tsx` (11 routes) | Active |
| `ErrorView` | Toast-style error display | `App.tsx` (via `logging.errorHandler`) | Active |
| `FeedbackModal` | Generic success/error/info modal | 13 files across pages/builders | Active |
| `ObjectDashboard` | Legacy static-config-driven entity list/CRUD | `App.tsx` (`/dashboard`) | Active |
| `ObjectTypeExplorer` | Entity-type side list for `ObjectDashboard` | `ObjectDashboard`, 2 others | Active |
| `PagedEntityTable` | Generic server-paged/sortable table | 11 files (dashboard, forms, builders) | Active |
| `FormWizard` (+ 9 files in `FormWizard/`) | Generic config-driven create/edit engine | `FormWizardPage` and peers | Active |
| `FormConfigBuilder` (+ 8 files) | Admin authoring UI for form configs | `App.tsx` (2 routes) | Active |
| `DisplayWizard` (+ 5 files in `DisplayWizard/`) | Generic config-driven read-only detail view | `DisplayWizardPage` | Active |
| `DisplayConfigBuilder` (+ 5 files) | Admin authoring UI for display configs | `App.tsx` (2 routes) | Active |
| `PathBuilder` / `SearchablePathBuilder` | Cross-entity reference/path picker | Form/display builders | Active (has a `.stories.tsx` — no Storybook config found in repo, see §3) |
| `HybridEnchantmentPicker` / `HybridMaterialPicker` | Minecraft-ref hybrid pickers (known ref + free text) | `FormWizard` field renderers | Active |
| `Workflow/WorldBoundFieldRenderer` | Renders world-coordinate-bound form fields | `FormWizard` | Active |
| `Workflow/TaskStatusMonitor` | Poll/display a background `WorldTask` job's status | *(none)* | **Orphaned — 0 references** |
| `Workflow/WizardStepContainer` | Generic step-container layout | *(none)* | **Orphaned — 0 references** |
| `auth/*` (FormStep1–3, FormStepper, LoginForm, RegisterForm, LinkCodeDisplay, PasswordStrengthMeter) | Multi-step registration + login forms | `pages/auth/*` | Active |
| `minecraft/*` | See Hybrid pickers above | — | Active |
| `shared/LinkModeSelector` | Toggle between reference-by-ID vs. inline-object modes | *(none)* | **Orphaned — 0 references** |
| `DynamicForm.tsx` | Older generic form renderer, pre-dates `FormWizard` | *(none)* | **Orphaned — 0 references, and imports non-existent modules** (`apiClients/districts`, `apiClients/streets`, `apiClients/locations` — see §4) |
| `ObjectView.tsx` | Older generic detail-view renderer, pre-dates `DisplayWizard` | *(none)* | **Orphaned — 0 references** |
| `MultiSelectDropdown` | Multi-select input | `DynamicForm.tsx` only (itself orphaned) | **Orphaned in practice** — only consumer is unreferenced |
| `SearchableDropdown` | Searchable single-select input | `DynamicForm.tsx` only (itself orphaned) | **Orphaned in practice** |
| `ImageUploadModal` | Image upload modal | 1 file (verify which — not traced further this pass) | Active, low usage |
| `Slideshow` | Image slideshow | 1 file | Active, low usage |

## 3. Hooks & state management

| Hook/Context | Purpose | Used by |
|---|---|---|
| `contexts/AuthContext.tsx` (`AuthProvider`, `useAuth`) | Sole app-wide state via Context; owns user/session | `App.tsx`, `ProtectedRoute`, `Navigation`, `AccountManagementPage`, `auth/*`, 13 files total |
| `hooks/useAuth.ts` | Thin re-export of `contexts/AuthContext`'s `useAuth` | Same call sites as above (no separate logic) |
| `hooks/useEntityMetadata.ts` | Fetches + module-scope-caches the entity metadata bundle (`metadataClient` + `entityTypeConfigurationClient`, merged) | `App.tsx`, `ObjectDashboard`, `PagedEntityTable`, `EntityTypeConfigurationPage`, 6 files total |
| `hooks/useEnrichedFormContext.ts` | Enriches form context with resolved metadata/relationships | 3 files in `FormWizard/` |
| `hooks/useRelationshipDrafts.ts` | Tracks in-progress many-to-many / child-entity relationship edits before save | 4 files in `FormWizard/` |
| `hooks/useAutoLogin.ts` | Auto-login hook | **0 references** — `AuthContext.tsx` implements auto-login inline (calling `authService.autoLogin()` directly in a `useEffect`) rather than through this hook; appears superseded before ever being wired in |

No Redux/Zustand — confirmed, matching `CLAUDE.md`.

## 4. Feature-flagged / half-built / stub UI

- `pages/DisplayWizardPage.tsx` (lines 22–37): `select`, `unlink`, `add`, `remove`
  action cases are `console.log`-only stubs with `// TODO` comments — the display
  wizard's relationship-editing actions are not implemented yet.
- `pages/DisplayWizardPage.tsx` (lines 14, 20): `edit`/`create` actions navigate to a
  route path (`/form/...`) that doesn't exist (see §1) — functionally the same as
  unimplemented, just without a TODO marking it.
- `pages/FormWizardPage.tsx` line 120: `const userId = '1'; // TODO: Get from auth
  context` — the form-submission-progress feature (`formSubmissionClient`, "saved
  progress") is hardcoded to user ID `1` rather than reading the real logged-in user
  from `AuthContext`. This likely means saved-progress tracking is effectively
  single-user / non-functional per-user today — **verify at runtime**, since it's a
  functional gap, not just a lint issue.
- `components/Workflow/WorldBoundFieldRenderer.tsx` line 755: `// TODO: Fetch existing
  regions from API` — region list for world-bound fields appears to be
  hardcoded/incomplete pending a real endpoint.

No `#if`-style or block-commented-out UI was found (this app has no preprocessor;
checked for large commented JSX blocks and found none of note beyond the small stray
duplicate-`navigate()`-call artifacts noted in §5).

## 5. Legacy / orphaned / duplicate code

### Confirmed orphaned (0 static references outside their own file)

| File | Lines | Note |
|---|---|---|
| `src/components/DynamicForm.tsx` | 383 | Predecessor to `FormWizard`. Imports `apiClients/districts`, `apiClients/streets`, `apiClients/locations` — **none of these files exist** under those names anymore (the current names are `districtClient.ts`, `streetClient.ts`, `locationClient.ts`). This file would fail to type-check/compile if it were ever included in a build step that checks unreferenced files — **appears unused and broken — verify whether `npm run build` actually errors on it** (not run in this pass; see architecture doc's tsconfig note). Strong removal candidate either way, since even if it somehow still compiles, nothing renders it. |
| `src/components/ObjectView.tsx` | 411 | Predecessor to `DisplayWizard`. Imports resolve fine (unlike `DynamicForm.tsx`), just unreferenced. |
| `src/components/shared/LinkModeSelector.tsx` | 50 | No call sites found. |
| `src/components/Workflow/TaskStatusMonitor.tsx` | — | No call sites found; would need to be wired into a page to show `WorldTask` progress. |
| `src/components/Workflow/WizardStepContainer.tsx` | — | No call sites found. |
| `src/hooks/useAutoLogin.ts` | — | No call sites found; auto-login logic lives inline in `AuthContext.tsx` instead. |
| `src/apiClients/formFieldClient.ts` | 39 | No call sites found. `formConfigClient.ts` (12 references) appears to handle field CRUD as part of a composite `FormConfigurationDto` payload instead — **appears superseded, verify** by checking whether the backend still exposes a standalone `FormFields` endpoint that's simply not called from the client, vs. one this client was written for and abandoned. |
| `src/apiClients/formStepClient.ts` | 39 | Same pattern/caveat as `formFieldClient.ts`, for `FormSteps`. |
| `src/apiClients/itemBlueprintClient.ts.orig` | — | A stray `.orig` file (merge/patch leftover) sitting next to the real `itemBlueprintClient.ts`. Not a `.ts`/`.tsx` file so it isn't imported by anything, but it's dead weight in the tree — safe, low-risk deletion candidate. |
| `src/pages/admin/EntityTypeConfigurationPage.tsx` | 162 | Not orphaned in the "nothing imports it" sense — it's simply not routed (see §1). Fully built; likely just needs an `App.tsx` route + nav link to become live, unless it was deliberately pulled. |

### Components used only by an already-orphaned component

`MultiSelectDropdown.tsx` and `SearchableDropdown.tsx` each have exactly one
reference in the tree, and that reference is `DynamicForm.tsx` (itself orphaned, see
above). If `DynamicForm.tsx` is removed, these two become orphaned as well — worth
handling in the same cleanup pass rather than two separate ones.

### Duplicate implementations of the same UI pattern

- **Generic form rendering, twice over:** `DynamicForm.tsx` (orphaned, static
  `objectConfigs`-driven) vs. the active `FormWizard/` engine (backend-config-driven).
  Classic copy-paste-drift-then-abandon pattern the scan instructions call out —
  confirmed here, not just suspected.
- **Generic detail-view rendering, twice over:** `ObjectView.tsx` (orphaned) vs. the
  active `DisplayWizard/` engine. Same pattern as above.
- **Two field-editor implementations that look structurally identical:**
  `components/FormConfigBuilder/FieldEditor.tsx` and
  `components/DisplayConfigBuilder/FieldEditor.tsx` are separate files with the same
  name, same apparent responsibility (edit a single field's config) for two sibling
  config systems (form vs. display). Not verified line-by-line for how much they
  actually share vs. diverge — **flag for a closer diff pass** to see if they could be
  unified, rather than assuming either is fine as-is.
- **Two "reusable selector" pairs**, same shape: `ReusableFieldSelector.tsx` +
  `ReusableSectionSelector.tsx`/`ReusableStepSelector.tsx` exist once under
  `FormConfigBuilder/` and once under `DisplayConfigBuilder/` — same caveat as above.

### Two competing "which entities exist" registries

`src/config/objectConfigs.tsx` (static map, 11 entity types, hand-maintained) vs. the
live metadata bundle from `hooks/useEntityMetadata.ts` (backend-driven, unbounded
entity list). `ObjectDashboard`/`Navigation`'s "Create New" menu use the static list;
`FormWizardPage`/`FormConfigListPage`/`DisplayConfigListPage` use the live list. An
entity added to the backend's form/display config system today will **not**
automatically appear in the dashboard or "Create New" menu until someone also adds it
to `objectConfigs.tsx` by hand. This is a design-level risk, not a bug in either file
individually — flagging for a decision (retire the static map in favor of driving
`ObjectDashboard` off live metadata too, or accept the split deliberately).

### Repo-hygiene items (not "code", but found during the scan)

- `test_output.txt` (17.5 MB) is **tracked in git** (`git ls-files` confirms), not
  gitignored, and reads like a raw `npm test`/Jest run dump accidentally committed in
  the same commit as `CLAUDE.md` (`b5474cc`). Bloats every clone of the repo for no
  benefit — recommend removing it and adding it to `.gitignore` if it's a recurring
  local artifact.
- `eslint.config.js` (flat config) — already flagged as unused/leftover in this repo's
  own `CLAUDE.md`; confirmed still present and still not wired to any `package.json`
  script.
- `tsconfig.app.json`, `tsconfig.node.json`, `tsconfig-deps.json` alongside a
  project-references-style root `tsconfig.json` (`"files": []`, `"references": [...]`)
  — this is Vite's typical scaffolding shape, not Create React App's. Given CRA is
  confirmed as the actual build tool (`react-scripts` in `package.json` scripts), this
  set of tsconfig files may be leftover scaffolding similar to `eslint.config.js`, or
  it may genuinely affect editor/type-checking behavior — **not resolved in this
  pass, flagged as uncertain** (see architecture doc).
- `test-password-strength.js` (repo root, plain JS, not under `src/` or `cypress/`) —
  looks like an ad hoc manual test script, not part of any test runner config. Worth
  confirming it's not needed before removing.

### Outdated/unused dependencies (`package.json`)

Checked each `dependencies`/`devDependencies` entry for at least one import site:

- All runtime `dependencies` have live import sites (`@dnd-kit/*` in form/display
  builders, `@fluentui/react-components` widely, `lucide-react` widely, `react-router-dom`
  in `App.tsx`, `rxjs` in the error bus, `web-vitals` in `reportWebVitals.ts`).
  `scheduler` has no direct import found in `src/` — it's a transitive React
  dependency commonly pinned explicitly for version-conflict reasons; **not** flagging
  as removable without checking why it was pinned (could be intentional).
- `cra-template-typescript` in `dependencies` (not `devDependencies`) is CRA
  scaffolding metadata, not a runtime dependency of the app — normally harmless but
  worth moving to `devDependencies` or removing in a cleanup pass; it has no import
  site by design.
- No dead devDependencies found — `cypress`, `typescript`, `tailwindcss`,
  `autoprefixer`, `postcss`, testing-library packages, and the `@types/*` packages all
  correspond to actually-used tooling/config files in the repo.

## 6. API surface actually called (by resource)

All 25 files in `src/apiClients/` follow the same shape: a class extending
`ObjectManager`, whose methods call `this.invokeServiceCall(data, operation,
Controllers.<X>, httpMethod)` (see architecture doc §"Data flow"). Reference counts
below are static call-site counts for each client within `src/` (not endpoint-level
granularity — see the `knk-web-api` scan for the actual controller/route inventory to
cross-reference against).

| Client | Backend controller (`Controllers` enum) | Call sites in `src/` |
|---|---|---|
| `authClient` | `Auth` / `Users` (split across methods) | 5 |
| `metadataClient` | `Metadata` | 19 |
| `fieldValidationRuleClient` | `field-validation-rules` | 15 |
| `formConfigClient` | `FormConfigurations` | 12 |
| `formSubmissionClient` | `FormSubmissionProgress` | 9 |
| `displayConfigClient` | `DisplayConfigurations`/`DisplaySections`/`DisplayFields` | 5 |
| `workflowClient` | `Workflows` | 4 |
| `worldTaskClient` | `WorldTasks` | 3 |
| `districtClient`, `enchantmentDefinitionClient`, `entityTypeConfigurationClient`, `locationClient`, `minecraftBlockRefClient`, `minecraftEnchantmentRefClient`, `minecraftMaterialRefClient`, `structureClient`, `townClient` | (respective enum values) | 2 each |
| `categoryClient`, `gameSettingsClient`, `gateDoorClient`, `gateStructureClient`, `itemBlueprintClient`, `streetClient`, `userClient` | (respective enum values) | 1 each |
| `formFieldClient`, `formStepClient` | `FormFields`, `FormSteps` | **0** (see §5 — orphaned) |

## 7. Summary of highest-value findings

1. **Two dead-end navigation actions** in `DisplayWizardPage` (`/form/...` typo vs.
   real `/forms/...` routes) — cheap, high-confidence fix.
2. **`EntityTypeConfigurationPage` is fully built but unrouted** — likely just needs
   wiring, not rebuilding, to become a usable admin screen.
3. **`DynamicForm.tsx`/`ObjectView.tsx` (and their exclusive dependents
   `MultiSelectDropdown`/`SearchableDropdown`)** are a confirmed superseded-generation
   of the form/display engines — highest-confidence deletion candidate in this repo
   (794 combined lines, one with broken imports).
4. **Hardcoded `userId = '1'`** in `FormWizardPage` — a real functional gap in the
   saved-progress feature, not just cleanup.
5. **`test_output.txt`** — 17.5 MB accidentally committed; trivial to fix, meaningful
   clone-size win.
6. **Two parallel "entity registry" systems** (`objectConfigs.tsx` vs. live metadata)
   — a design decision to make, not a bug, but worth flagging before more entities are
   added to only one side.
