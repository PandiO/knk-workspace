# Web app testing

**Status:** Current · **Last updated:** 2026-11-15 (smoke-guide tag format, every step kept in full); 2026-11-14 (smoke-test backfill specs and helpers, [PandiO/knk-workspace#511](https://github.com/PandiO/knk-workspace/issues/511)); 2026-11-14 (§ 3: `dashboard-row-actions.spec.ts` listed, 16 tests; #404–#406, docs [#526](https://github.com/PandiO/knk-workspace/issues/526)); 2026-11-14 (end-to-end tests on Playwright instead of Cypress, in CI, [PandiO/knk-workspace#423](https://github.com/PandiO/knk-workspace/issues/423)); 2026-11-13 (moved from knk-web-app `TESTING.md`, rewritten against knk-web-app `next` `ff9db4b`, PandiO/knk-workspace#304)
**Moved from:** `knk-web-app/TESTING.md` at `ff9db4b` ([source](https://github.com/PandiO/knk-web-app/blob/ff9db4b/TESTING.md)) and rewritten against the
current code: that file described only the first registration tests (2026-01), a `mockAuthClient.ts` that no longer
exists, E2E tests that wrote real users to the database, and an example GitHub workflow with Node 18 that was never the
real CI. The two companion files are in the archive: [TEST_README.md](../../archive/knk-web-app/TEST_README.md) and
[TESTING_IMPLEMENTATION_SUMMARY.md](../../archive/knk-web-app/TESTING_IMPLEMENTATION_SUMMARY.md).

This guide covers the automated tests of `knk-web-app` (React + TypeScript, Create React App). The README of the repo
keeps a short quick start; the API and plugin tests are described in their repos' `CLAUDE.md` / `AGENTS.md`.

## 1. Commands

All from the knk-web-app root (`package.json` scripts):

| Command | What it runs |
|---|---|
| `npm test` | Jest (through `react-scripts test`) in watch mode, for development |
| `npm run test:ci` | Jest once, no watch (`--watchAll=false --passWithNoTests`); this is what CI runs |
| `npm run test:coverage` | Jest once with a coverage report in `coverage/` |
| `npx tsc --noEmit` | Type check; CI runs it too |
| `CI=true npm run build` | Production build with ESLint warnings treated as errors, as in CI |
| `npm run test:e2e` | Production build, then the Playwright end-to-end specs in Chromium with a mocked API (§ 3) |
| `npx playwright test` | The end-to-end specs against the existing `build/` (no rebuild); add a file name or `-g "<test name>"` to run fewer |
| `npm run test:e2e:ui` | The same specs in Playwright's UI mode (watch, time travel, pick locators), against the existing `build/` |
| `npm run typecheck:e2e` | Type check of the specs and their mocks (`e2e/tsconfig.json`); CI runs it |
| `npm run test:all` | `test:ci`, then `test:e2e` |

Install dependencies with npm 11 (`npx npm@11 ci`): the lock file is valid for npm 11 only (knk-web-app `CLAUDE.md`).

Useful Jest options: `npm test -- RegisterForm` runs the files matching a name, `npm test -- -t "validation"` the tests
whose name matches, and `npm test -- --clearCache` clears Jest's cache.

## 2. Unit and component tests (Jest + React Testing Library)

1. Test files sit next to the code in `__tests__/` folders or as `*.test.ts(x)` (about 300 files; the largest groups are
   `components/FormWizard/__tests__`, `utils/forms/__tests__`, `utils/__tests__` and `apiClients/__tests__`).
2. `src/setupTests.ts` loads `@testing-library/jest-dom`, adds `TextEncoder`/`TextDecoder` for react-router v7 and pins
   number formatting to `en-US`, so expected text such as "12,345" doesn't depend on the machine's locale.
3. Shared helpers in `src/test-utils/`:
   1. `test-helpers.tsx`: `renderWithProviders` wraps a component in the `AuthProvider`.
   2. `permissions.ts`: `mockHeldNodes(mocks, nodes)` makes the mocked `usePermission` / `usePermissions` /
      `useStaffAccess` answer as if the user held exactly those permission nodes.
   3. `fakeRealtime.tsx`: a stand-in for the SignalR web hub; `hub.emit(type, payload)` delivers an event and
      `hub.reconnect()` runs the reconnect handlers.
4. API clients are mocked per test with `jest.mock('../../apiClients/<client>')`; there is no shared mock API client.
5. Prefer accessible queries (`getByRole`, `getByLabelText`), wait for async updates with `waitFor` / `findBy…`, and keep
   tests independent of each other's order.

## 3. End-to-end tests (Playwright)

Playwright Test (`@playwright/test`, pinned in `package.json`) replaced Cypress on 2026-11-14
([PandiO/knk-workspace#423](https://github.com/PandiO/knk-workspace/issues/423),
[AI agent workflow design § 6](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci)).

1. **What runs.** `playwright.config.ts` serves the production build (`build/`) with
   `e2e/support/serve-build.mjs` (a small Node server with the single-page fallback, no extra dependency) on
   `http://127.0.0.1:4173` (`E2E_PORT` changes the port) and runs the specs in `e2e/*.spec.ts` in Chromium only.
   Locally an already running server on that port is reused.
2. **The API is mocked.** Every request to `/api/...` is answered by the `api` fixture (`e2e/support/mockApi.ts`,
   built on `page.route`), so the specs need no API, no database and no network. A spec registers what it needs with
   `api.json(method, path, body)` or `api.on(method, path, handler)` (path relative to `/api/`, a string or a regex;
   the last registration wins, so a test can override a `beforeEach` mock) and checks what the page sent with
   `api.calls(method, path)` (body, query and bearer token of each call). A request without a mock gets a 404
   `{ error: 'NoMock' }` and is listed on the test as the annotation "unmocked API requests" in the HTML report; run a
   spec with `test.use({ strictApi: true })` to make such a request fail the test.
3. **Mocks typed with the DTOs.** The fixtures in `e2e/fixtures/` (`auth.ts` users and login responses, `content.ts`
   the empty lookups every content page makes, `forms.ts` a two-step form configuration, `players.ts` the staff player
   profile and the moderation search, `settings.ts` the settings pages) and the mock bodies in the
   specs are typed with the DTOs in `src/types/`. `npm run typecheck:e2e` (and the CI job) fails when a DTO changes and
   a mock no longer matches; Playwright itself only strips the types.
4. **Helpers.** `startLoggedIn(page, token)` puts an access token in `sessionStorage` before the first page load (a
   login without remember-me); `mockSession(api, user, allowed)` answers `Auth/me` and the permission checks
   (`allowed(node)` decides each node) and refuses the realtime hub's negotiate call, so pages run with realtime off.
   `expectNoSidewaysScroll(page)` (`e2e/support/layout.ts`) checks that nothing scrolls the page sideways, for the
   smoke tests' "at 390 px" steps (set the size with `page.setViewportSize`).
5. **The specs** (89 tests in knk-web-app `next` with batches 1–4 of #511, about a minute after the build):
   1. `registration.spec.ts`, ported from the Cypress spec: an invalid link code, registering and landing on
      `/account` (the exact request body is checked), a duplicate email shown on the email field.
   2. `login.spec.ts`: a player logs in and lands on `/account`; a wrong password shows the generic message; an
      expired access token: the permission checks get 401, the app refreshes once (`POST Auth/refresh`) and retries
      with the new token, so a content admin lands on the dashboard; a refused refresh ends the session and opens
      `/auth/login?returnTo=%2Faccount&reason=expired` with the "session expired" banner
      (`src/services/serviceCall.ts`, `src/services/sessionRefresh.ts`). That last test does not pin the number of
      refresh calls: requests already in flight each refresh again after the refusal
      ([#502](https://github.com/PandiO/knk-workspace/issues/502)).
   3. `dashboard.spec.ts`: `/dashboard/town` lists the towns of `POST Towns/search`, and the search box sends the
      search term.
   4. `form-wizard.spec.ts`: `/forms/town`, "Use" on the configuration: "Next" with an empty required field shows
      the error summary and the field error and saves nothing; a filled step saves the draft
      (`POST FormSubmissionProgress` with the step's values and the workflow session) and opens step 2; "Previous"
      keeps the values.
   5. `dashboard-row-actions.spec.ts` (PandiO/knk-workspace#404, #405, #406): on `/dashboard/town`, every row has the
      same 1px row line and no left border; at 390 px wide the row's Edit button stays in the viewport (sticky actions
      column); a right-click on a row opens View, Edit, Delete and Export as CSV and Escape closes it; without
      `knk.admin.delete` / `knk.admin.export` (the Town metadata's `actionNodes` are mocked) those items are
      `aria-disabled` with "Requires <node>", like the row's Delete button; Shift+F10 on the focused row link opens the
      menu with the focus on its first item, ArrowDown moves, Escape gives the focus back to the link. The Jest tests
      `components/__tests__/DataTable.rowsAndMenu.test.tsx` and the #406 block in `ObjectDashboard.test.tsx` cover the
      rest (Ctrl/Cmd + right-click, rows without items, the selection's Delete and Export).
   6. `player-profile.spec.ts` (smoke-test backfill [#511](https://github.com/PandiO/knk-workspace/issues/511)): the
      staff player profile's header and tabs (tab in the URL, kept on reload, arrow keys), freeze with a required
      reason and unfreeze, the Activity timeline and paged audit log, actions greyed out without their node, and
      Moderation → All players (UUID search, server sort and paging in the URL, Back, Recently opened).
   7. `settings-pages.spec.ts` (#511): Lootboxes → Settings, Currency policy, Road network and Siege settings in the
      admin layout: the unsaved-changes count, the leave question from a sidebar link and from the browser's Back, the
      browser's own question on close or reload, Save with its toast, a refused and a stale save, units, phone width.
   8. `admin-navigation.spec.ts` (#511): the top bar per role, the `/admin` overview, the grouped sidebar and its
      "Admin pages" menu below 1280 px, breadcrumbs, tab titles, the old builder URLs, a staff account with only some
      nodes and a player.
   9. `dashboard-access.spec.ts` (#511): the explorer per area (typed metadata with the API's area and action nodes in
      `e2e/fixtures/dashboardAccess.ts`), actions greyed out with "Requires <node>", the form routes refused without
      `knk.admin.content`, single and bulk delete with a refused row, a user-level bulk deny, export through
      `POST api/Dashboard/export`, and a delete refused as in use with "Show what uses it" (loaded only on request).
   10. `entity-detail.spec.ts` (#511): a town's detail page (`e2e/fixtures/entityDetail.ts`: a display configuration
      with a hot-edit field and a Streets collection, relationship and lookup mocks that change the town): links,
      counts and paging, hot edit, Unlink that never deletes, Add from the lookup, Delete as its own question, the
      gates without `knk.admin.delete` / `knk.admin.content`, readable errors, phone width.
   11. `data-table.spec.ts` (#511): the shared table and confirm on the dashboard: sorting and paging in the URL, the
      row link and row click with Back, the confirm's focus (Cancel first, Tab kept inside, Escape back to its
      button), and numbers in the browser's language (`test.use({ locale: 'nl-NL' })`).
6. **Writing a spec.** Use role-based locators (`getByRole`, `getByLabel`, `getByTestId` where a test id exists) and
   web-first assertions (`await expect(locator).toBeVisible()`, `toHaveURL`); never `waitForTimeout`. To find the calls
   a page makes, open it in a spec and look at the "unmocked API requests" annotation or `api.requests`.
   Two browser-only cases from the backfill: the browser's own "leave site?" question is checked with
   `page.on('dialog')` and `page.close({ runBeforeUnload: true })` after the page shows its unsaved change (the
   handler is attached on that render); a test of the app's leave question on **Back** must arrive by a click in the
   app, not a second `page.goto`, so Back stays a client-side navigation.
   When a spec automates a smoke-test step, tag the step in its guide and keep its full manual text
   (`N. [automated: <test path>] <the step as written>`, or `[partly automated: <test path>; by hand: <what is left>]`;
   developer decision 2026-11-15, [knk-test-writer skill](../../../.claude/skills/knk-test-writer/SKILL.md) § 4).
7. **Browser.** Install Chromium once with `npx playwright install chromium`. With a Chromium that is already
   installed (a cloud session has one at `/opt/pw-browsers/chromium`), set `PLAYWRIGHT_CHROMIUM_PATH` to it instead;
   do not run `playwright install` in a cloud session. Pass `--trace off` to skip traces locally unless you are
   debugging a failure; the default keeps a trace only for a failed test.
8. **Output** (git-ignored): `playwright-report/` (HTML report, `npx playwright show-report`) and `test-results/`
   (traces, screenshots and error context of failed tests; open a trace with `npx playwright show-trace <zip>`).
9. **Real API (not set up).** The specs run only against mocks (decision in #423). A later opt-in config against a
   local API with a seeded database is possible but does not exist yet.

## 4. Continuous integration

CI runs on every push and pull request (`.github/workflows/ci.yml`, job `build-and-test`): Node 22,
`npx --yes npm@11 ci`, `npm run test:ci`, `npx tsc --noEmit` and `CI=true npm run build`. The job is a required check on
`main` and `next`. The end-to-end tests run in their own workflow (`.github/workflows/e2e.yml`, job `e2e`, timeout 10
minutes): the same install, `npm run typecheck:e2e`, `npx playwright install --with-deps chromium`,
`CI=true npm run build` and `npx playwright test` with one retry; the HTML report is uploaded as the
`playwright-report` artifact on every run, traces and screenshots as `playwright-traces` when a test fails. The `e2e`
job is not a required check (yet). The [CI guide](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/developer/ci.md)
describes all three repos' workflows (in knk-workspace `next`, not yet on `main`).

## 5. Troubleshooting

1. **A test passes alone but fails in the suite:** look for a module mock or global state (locale, timers, storage)
   that another file changes; reset it in `afterEach`.
2. **"TextEncoder is not defined":** the test bypasses `src/setupTests.ts`; run it through `npm test`, not plain `jest`.
3. **`npm ci` rejects the lock file:** you are on npm 10; use `npx npm@11 ci`.
4. **Playwright: "Executable doesn't exist":** no Chromium for this Playwright version; run
   `npx playwright install chromium`, or set `PLAYWRIGHT_CHROMIUM_PATH` to an installed Chromium.
5. **Playwright: a page shows "No build in build/" or old code:** `npx playwright test` serves the existing `build/`;
   run `npm run test:e2e` (or `npm run build`) after changing the app.
6. **Playwright: port 4173 is taken** by another program: set `E2E_PORT`, for example `E2E_PORT=4180 npm run test:e2e`.
7. **An end-to-end test fails in CI only:** download the `playwright-traces` artifact of the run and open the trace
   with `npx playwright show-trace`.

## Changes

1. 2026-11-14: § 3 lists `dashboard-row-actions.spec.ts` (#404–#406), docs #526
2. 2026-11-14: end-to-end tests on Playwright instead of Cypress, in CI, #423
3. 2026-11-13: moved from knk-web-app `TESTING.md`, rewritten against knk-web-app `next` `ff9db4b`, #304
