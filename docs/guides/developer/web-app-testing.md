# Web app testing

**Status:** Current · **Last updated:** 2026-11-13 (moved from knk-web-app `TESTING.md`, rewritten against knk-web-app `next` `ff9db4b`, PandiO/knk-workspace#304)
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
| `npm run cypress:open` | Cypress, interactive |
| `npm run cypress:run` / `npm run test:e2e` | Cypress headless (`cypress:run:chrome` and `cypress:run:firefox` pick a browser) |
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

## 3. End-to-end tests (Cypress)

1. Specs are in `cypress/e2e/`. There is one: `registration.cy.ts`, registration with a link code from the game server
   (invalid code, register and land on `/account`, duplicate email on the email field).
2. The spec stubs the API with `cy.intercept`, so it needs only the dev server (`npm start` on
   `http://localhost:3000`, the `baseUrl` in `cypress.config.ts`) and writes nothing to a database.
3. Cypress is not part of CI; run it by hand when you change the registration flow.

## 4. Continuous integration

CI runs on every push and pull request (`.github/workflows/ci.yml`, job `build-and-test`): Node 22,
`npx --yes npm@11 ci`, `npm run test:ci`, `npx tsc --noEmit` and `CI=true npm run build`. The job is a required check on
`main` and `next`. The [CI guide](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/developer/ci.md)
describes all three repos' workflows (in knk-workspace `next`, not yet on `main`).

## 5. Troubleshooting

1. **A test passes alone but fails in the suite:** look for a module mock or global state (locale, timers, storage)
   that another file changes; reset it in `afterEach`.
2. **"TextEncoder is not defined":** the test bypasses `src/setupTests.ts`; run it through `npm test`, not plain `jest`.
3. **`npm ci` rejects the lock file:** you are on npm 10; use `npx npm@11 ci`.
4. **Cypress can't reach the app:** start `npm start` first and check that it serves on port 3000.
