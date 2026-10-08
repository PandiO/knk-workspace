# Web app dead-code and cleanup analysis — 2026-10-08

Status: analysis complete. **Tier 1 and the Fluent UI removal are executed** on knk-web-app
`claude/ui-ux-assessment-discussion-66vc2l` (unmerged; see § 9). Tiers 2 and 3 are proposals.
Last updated: 2026-10-08
Linear: [KNG-71](https://linear.app/kngpandi/issue/KNG-71) (related: [KNG-63](https://linear.app/kngpandi/issue/KNG-63), [KNG-64](https://linear.app/kngpandi/issue/KNG-64))
Evidence base: knk-web-app `main` @ `84943ff`.

**Method:**
- Built an import graph with the TypeScript module resolver, starting at `src/index.tsx`. It follows static and dynamic
  imports, `require`, `jest.mock` and `jest.requireActual`.
- Cross-checked with knip 5, ts-prune and depcheck.
- Grepped every candidate's basename and identifiers across the repo, Cypress and the sibling repos.
- The Tier 1 deletion was simulated in a scratch copy and verified: `tsc --noEmit` clean, `react-scripts build` OK with
  an **unchanged main bundle hash** (the deleted code was never shipped), and Jest with no new failures.

Background: the project started from an AI web-designer tool. That explains the scaffolding leftovers, parallel
copies and "changed:/added:" edit-marker comments.

---

## 1. Summary

Of 389 tracked files under `src/`, 255 are reachable at runtime, **42 are unreachable** from both the entry and every test,
and **14 are reachable only from tests**.

| Group | Files | Lines | Size |
|---|---|---|---|
| Tier 1 — unreachable `src` code, CSS, SVG | 34 | 3,344 | 125 KB |
| Tier 1 — dead code + the tests that only cover it | 16 | 1,585 | 44 KB |
| Tier 1 — `src/prompts/*.md` (AI design notes inside `src/`) | 8 | 3,431 | 114 KB |
| Repo root + Cypress junk | 9 | — | **17.55 MB** (almost all `test_output.txt`) |
| Tier 2 (verify first) | — | ~2,500 | — |

**Top wins**
1. `test_output.txt`: a 17.5 MB UTF-16 Jest dump, tracked although `.gitignore` lists it.
2. The landing photos (`public/images/*.jpg`, 62 MB at 6832×3840). They are used, not dead; the alpha web work resizes
   them (KNG-69).
3. About 8.4k lines of dead `src` and notes, with zero runtime effect.
4. `@fluentui/react-components` is used only for `FluentProvider`: −13.55 kB gzip on the main bundle, −239 MB of
   `node_modules`. It also sets the Segoe UI font that overrides the intended one. **The developer decided to drop it
   (2026-10-08).**
5. The logging subsystem is a no-op: `registerConsoleLogger` is never called, so all `logger.*` calls are dropped. Only the
   `errorHandler` Subject is used, so `rxjs` and the undeclared `events` dependency can go (Tier 3).

## 2. Tier 1 — safe to delete (executed, § 9)

**Unreachable, no string references**

| Path | Lines | Why dead |
|---|---|---|
| `src/App.css`, `src/logo.svg`, `src/custom.d.ts` | 38 / 1 / 4 | CRA template leftovers. `custom.d.ts` only declares `*.svg` modules, and nothing imports an SVG once the logo is gone |
| `src/apiClients/itemBlueprintClient.ts.orig` | 44 | merge leftover |
| `src/apiClients/formFieldClient.ts`, `formStepClient.ts` | 40 + 40 | no importers |
| `src/components/DynamicForm.tsx` + `MultiSelectDropdown.tsx` | 384 + 206 | no importers (the dropdown is only used by `DynamicForm`) |
| `src/components/ObjectView.tsx` | 412 | no importers; links to a `/view/...` route that doesn't exist |
| `src/components/ObjectTypeExplorer/ObjectTypeExplorer.css` | 54 | never imported |
| `src/components/PathBuilder/SearchablePathBuilder.tsx`, `PathBuilder/index.ts` | 490 + 5 | only reachable through a barrel that nothing imports (`PathBuilder.tsx` itself is live) |
| `src/components/Workflow/TaskStatusMonitor.tsx`, `WizardStepContainer.tsx`, `src/types/workflow.ts` | 123 + 90 + 39 | no importers |
| `src/components/auth/LinkCodeDisplay.tsx`, `src/components/auth/index.ts` | 124 + 9 | barrel-only, the barrel unused |
| `src/components/shared/LinkModeSelector.tsx` | 51 | no references |
| `src/contexts/index.ts`, `src/hooks/useAutoLogin.ts` | 2 + 42 | no importers (duplicate `AuthContext` logic) |
| `src/pages/admin/EntityTypeConfigurationPage.tsx` | 497 | not routed, no nav link |
| `src/utils/dependencyPathResolver.ts`, `utils/forms/entityMetadataHelper.ts`, `utils/iconRegistry.ts` | 179 + 50 + 191 | no live importers |
| `src/types/Location.ts`, `types/domain/itemModels.ts`, 8 legacy `*CreateDTO`/`Overview` DTOs | ~260 | no importers (V1-style DTOs that only import each other) |
| `src/prompts/*.md` | 3,431 | AI notes. **Archived** to `knk-workspace/docs/archive/web-app-prompts/` before deletion |

**Dead code together with its only tests**
- `src/hooks/useAuth.ts` + `__tests__/useAuth.test.ts` (97 + 407). The app uses `contexts/AuthContext`.
- `src/types/uiObjectConfig/{UIFieldConfigurations,mappers}.ts` + their 2 tests. A defunct "UIObjectConfig" API.
- `src/data/testData.ts` (513) plus 9 `*ViewDTO`/item DTOs reachable only through it.

**Repo root**
- `test_output.txt` (17.5 MB)
- `test-password-strength.js`
- `eslint.config.js`: an unused Vite-style flat config whose plugins aren't installed. CRA lints from `package.json`'s
  `eslintConfig`.
- `cypress/e2e/hello-world.cy.ts`: looks for "Hello World", which doesn't exist.

**Small edits that go with Tier 1**
- Remove `reportWebVitals` (called without a callback, so `web-vitals` never loads).
- Remove the unused `.badge*` classes from `index.css`.

**Dependencies**
- Uninstall `cra-template-typescript`, `scheduler` (transitive through react-dom), `web-vitals` and
  `eslint-plugin-react-refresh`.
- Move `@testing-library/react` to `devDependencies`.
- **Fluent UI:** uninstall `@fluentui/react-components` and remove `FluentProvider` from `src/index.tsx`. The body font,
  size and colour then come from Tailwind and `index.css` (developer decision).

> **Lockfile caution.** `package-lock.json` is valid for **npm 11** (the developer's 11.6.2). npm 10 rejects it
> (`Missing: yaml@2.9.1`), and regenerating it with npm 10 only churns peer flags; this happened before and was reverted
> in `f077570`. Dependency changes are therefore made with `npx npm@11 …`. The same applies to production guide gap G2:
> `npm ci` works with npm 11, so CI should pin Node 22 + npm 11.

## 3. Tier 2 — verify first (proposals)

| # | Item | Size | What to check |
|---|---|---|---|
| 1 | `RegisterSuccessPage`, the `AuthClient` link-code methods, `LINK_CODE_EXPIRY_MINUTES`, `handleGenerateLinkCode` | ~350 | **Handled by KNG-69** (new code-based register flow) |
| 2 | `ImageUploadModal` + its landing-page state (fake upload) | ~250 | **Handled by KNG-69** (landing rewrite) |
| 3 | `src/config/objectConfigs.tsx`: the `fields`, `formatters` and `commonFields` sections, read only by dead `DynamicForm`/`ObjectView` and 2 config tests | ~870 + 105 test lines | Keep the keys, `label`, `icon` and the column registry (they drive the nav and dashboard). Confirm the gate tests aren't the only guard on the enum values |
| 4 | Duplicate `useEnrichedFormContext` inside `hooks/useEntityMetadata.ts` (lines 59–126, 329–576). The live hook is `hooks/useEnrichedFormContext.ts`, but the test targets the dead copy (2 cases already fail) | ~315 | Re-point the test at the live hook, then delete the copy |
| 5 | `ManyToManyRelationshipEditor` "create related" path: the modal is never opened; a test expects a removed button | ~110 | Product call: restore the button or delete the path and that test case |
| 6 | `utils/gateCoordinates.ts` (only its test uses it); `gateGeometry.ts` has its own parser | 65 | Check for upcoming gate work |
| 7 | `ConfigurationHealthPanel.test.simplified.tsx`, which duplicates the full test | 28 | Delete |
| 8 | **Cypress is broken.** `cypress.config.ts` calls a non-function default export, and specs use `/register` and `/login` instead of `/auth/...` | 297+ | Rewrite one smoke spec with Playwright (already available) or Cypress, or remove Cypress (−679 MB cache) |
| 9 | 86 API client methods without production callers (WorldTask ×10, DisplayConfig section/field CRUD ×12, Workflow ×5, …) | — | Low value; remove only together with the retired API endpoints |
| 10 | Unused enums in `utils/enums.ts`; `appConfig.useTestData`, `api.timeout` and `getConfig` are never read | ~60 | Delete (the alpha work touches `appConfig.ts`) |
| 11 | Undeclared dependencies: `events`, `@types/node`, `@testing-library/dom` | — | Declare them, or remove their use (`events` goes with the logging refactor) |

## 4. Tier 3 — refactor and consolidate (proposals)

- **Auth:** `contexts/AuthContext.tsx` becomes the only auth source. It has no unit test, so port a few cases from the
  deleted `useAuth.test.ts`.
- **Logging:** replace `utils/logging` (no-op logger plus an rxjs Subject) with a tiny typed pub/sub for `errorHandler`.
  Drop `rxjs` (including the internal-path import in `App.tsx:9`) and `events`. Render the error toasts from state; today
  they're held in a `useRef` and never shown (assessment X-1).
- **UI duplicates:**
  - 10 hand-rolled modals → shared `Modal` + `ConfirmDialog`.
  - 8 pagers (and 9 page-size constants) → one `Pager`.
  - Spinner markup in 50 files → `Spinner`.
  - Form and Display builder twins are 76–83% identical (`ReusableFieldSelector`, `ReusableStepSelector`/`SectionSelector`,
    `SortableStepItem`/`SectionItem`).
- **Utility duplicates:**
  - A Minecraft legacy-text parser in `FieldRenderers.tsx:479-654` vs the tested `admin/gameSettings/MinecraftLegacyPreview.tsx`.
  - About 7 date formatters plus about 30 inline `toLocale*` calls → `utils/format.ts`.
  - `toPascalCase`/`toCamelCase` ×2, `toNumber`/`parseCoordinate` ×3.
  - The `ObjectType` type declared ×3.
- **Dead exports in live files:**
  - 5 dead functions.
  - About 10 exports used only in their own file.
  - 39 unused exported types.
  - 22 double named/default exports.
  - 36 build-time ESLint warnings, mostly unused locals.
- **Bugs found while tracing:**
  - `DisplayWizardPage.tsx:14,20` navigates to the non-existent `/form/...` (assessment CRUD-15).
  - `FormWizardPage.tsx:120` hard-codes `userId = '1'` (CRUD-10).

## 5. Console, TODO and commented-code inventory (non-test `src/`)

- **`console.*` calls:** 242 in 53 files (78 `log`, 144 `error`, 17 `warn`).
- **Always-on debug wrappers:** six of them add about 65 more `console.log` calls:
  - `ManyToManyRelationshipEditor.tsx:60` (32 calls)
  - `FormWizard.tsx:93` (22)
  - `FieldRenderers.tsx:150,904,1150` (8)
  - `JoinEntityFormModal.tsx:32` (3)
- **Hard-coded debug block:** `isDebugField = Number(field.id) === 4` with `console.groupCollapsed` in `FormWizard.tsx` around line 2742.
- **Top offenders:** `FormWizard.tsx` (41), `FormWizardPage.tsx` (21), `LoginForm.tsx` (16), `WorldBoundFieldRenderer.tsx`
  (14), `PathBuilder.tsx` (12), `PlayerProfilePage.tsx` (12).
- **Secret-leaking logs:** `serviceCall.ts:112-113` (request params including the bearer header and body) and
  `objectManager.ts:23` (every response). **Removed by KNG-69.**
- **TODO/FIXME:** 6. Four are the `DisplayWizardPage` select/unlink/add/remove stubs; one is the hard-coded `userId`; one is
  "fetch existing regions".
- **Commented-out code:**
  - `ObjectDashboard.tsx:41-70`: 30 lines referencing components that no longer exist.
  - `types/dtos/forms/FormModels.ts:159-181`: pasted C#.
  - `serviceCall.ts:98-110`.
- **Other markers:** 58 AI edit-marker comments (`// changed:`, `added:`), 7 `eslint-disable`, 1 `@ts-ignore`, about 250 `any`.

## 6. Dependency audit

| Package | Status | Action |
|---|---|---|
| `cra-template-typescript`, `scheduler`, `web-vitals`, `eslint-plugin-react-refresh` | unused | uninstall (Tier 1) |
| `@fluentui/react-components` | 1 import (`FluentProvider`) | **uninstall (developer decision)** |
| `@testing-library/react` | test-only, listed in `dependencies` | move to dev |
| `rxjs`, `events` | one `Subject` / undeclared | Tier 3 logging refactor |
| `@types/node`, `@testing-library/dom` | used, undeclared | declare |
| `cypress` | broken specs only | fix or remove (Tier 2 #8) |
| `@babel/plugin-proposal-private-property-in-object`, `tailwindcss`/`postcss`/`autoprefixer`, `@dnd-kit/*`, `lucide-react`, `react-router-dom` | used or needed | keep |

## 7. Repo-root clutter

- `README.md` is still CRA boilerplate. Replace it with a short README pointing to `AGENTS.md`, `CLAUDE.md` and the env
  variables (KNG-69 adds the env section).
- `TESTING.md`, `TESTING_IMPLEMENTATION_SUMMARY.md` and `TEST_README.md` overlap and describe broken Cypress flows. Merge
  what's useful into `knk-workspace/docs/guides/`, then delete them.
- `.gitignore` lacks `cypress/videos` and `cypress/screenshots` (only relevant if Cypress stays).

## 8. Suggested order

1. **Hygiene and Tier 1** (done in § 9): root junk, unreachable files, prompt notes archived, unused dependencies,
   Fluent removal.
2. **Tier 2, one item at a time**, each verified with `tsc --noEmit`, `npm run test:ci` and `npm run build`:
   - `objectConfigs` shrink
   - the duplicate hook
   - the M2M path
   - enums and config
   - the Cypress decision
3. **Logging refactor**: drop rxjs and events, render toasts. This overlaps the assessment's X-1.
4. **Tier 3 shared components** (Modal, ConfirmDialog, Pager, Spinner, `format.ts`). Best done together with the UX
   roadmap's Phase 2 shared kit (assessment § 12) and the rebrand tokens.

Estimated total: Tier 1 + Tier 2 + logging is about −8k lines of `src`, −5 to −6 dependencies and −17.5 MB of repo
weight. Tier 3 is a further −1k to −2k lines, net of the new shared components.

## 9. Execution log

Executed on knk-web-app `claude/ui-ux-assessment-discussion-66vc2l`, on top of the KNG-69 alpha commits:

| Commit | What | Verification |
|---|---|---|
| `682e06d` chore(app): remove dead code and repo clutter | all Tier 1 files in § 2, `reportWebVitals`, the `.badge*` classes, the unused `components/auth/index.ts` barrel. KNG-69 had already removed `LinkCodeDisplay`, `RegisterSuccessPage` and `ImageUploadModal`. 64 files, −8,387 lines | `tsc --noEmit` clean |
| `f9f36ec` chore(deps): drop fluent ui and unused packages | `FluentProvider` removed; uninstalled `@fluentui/react-components`, `cra-template-typescript`, `scheduler`, `web-vitals`, `eslint-plugin-react-refresh`; `@testing-library/react` moved to dev (same locked 16.3.1). Lock edited with `npm@11 --package-lock-only`; `npm@11 ci --dry-run` passes | `test:ci`: 4 failed suites / 5 failed tests, the same pre-existing FormWizard + `useEnrichedFormContext` failures as `main`; 452 passing. `CI=false npm run build` OK, main bundle 280.6 → 266.5 kB gzip |

Not executed (needs product decisions, see § 3): `objectConfigs` shrink, the duplicate `useEnrichedFormContext`, the M2M
create path, Cypress, unused client methods, the logging refactor (rxjs and events), and Tier 3.
