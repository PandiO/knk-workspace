---
name: knk-test-writer
description: Write the automated tests for a Knights and Kings (K&K) change and keep the developer's manual check short. Use when you implement or fix a K&K feature, write or update a smoke-test guide, fill in a PR's Testing section, or backfill tests for an existing smoke test.
---

# K&K test writer: automated first

Developer decision 2026-11-14: every change ships its proof in the automated suites; the developer's evening check
covers only what no suite can check (global instructions, "Testing: automated first"). This skill is how.

## 1. List what the change must prove

1. Write down each behaviour the change adds or alters, as the smoke steps you would hand the developer: "staff
   without `knk.admin.content` see Delete greyed out", "a gate opens when its lever is pulled", "the API answers 403 for
   …". Include refusals and edge cases, not only the happy path.
2. For a backfill: take the steps of the existing smoke-test guide (`docs/guides/*smoke-test*.md`).

## 2. Pick the suite for each step

Take the first row that fits. A step can need two (logic in a unit test, the screen in an e2e spec).

| Step is about | Suite | Where | Run |
|---|---|---|---|
| What a web page shows or does: buttons, greyed-out actions, forms, navigation, error messages, the 401 → refresh path | Playwright e2e, mocked API | knk-web-app `e2e/*.spec.ts`; mocks via the `api` fixture of `e2e/support/mockApi.ts`; data in `e2e/fixtures/` typed with `src/types/` DTOs | `npm run typecheck:e2e`, `npm run test:e2e` (CI job `e2e`) |
| Web-app logic without a page: hooks, helpers, reducers, a component's states | Jest + Testing Library | next to the code (`__tests__/`) | `npm run test:ci` |
| An API rule: access (403/401), validation, a service's result, a migration's data | xUnit | knk-web-api `Tests/knkwebapi_v2.Tests/` (`Api/`, `Services/`, `Security/`, `Migrations/`, `MySql/` needs `KNK_TEST_MYSQL`) | `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` |
| Plugin logic without Bukkit: rules, calculations, state machines, plans | JUnit | knk-plugin `knk-core/src/test/` | `./gradlew :knk-core:test` |
| Plugin code that touches Bukkit: listeners, commands, menus, a cache | JUnit + MockBukkit (test-only, developer decision 2026-11-14) or Mockito | knk-plugin `knk-paper/src/test/` | `./gradlew :knk-paper:test` |
| What happens in the world over ticks: blocks, regions, entities, a gate moving, a round advancing | Plugin scenario on a real Paper server (PandiO/knk-workspace#421) | knk-plugin scenario framework; guide "Writing a plugin scenario" in `docs/guides/developer/` | CI job `paper-boot` runs every scenario |
| The plugin starts at all with WorldGuard/WorldEdit | Paper boot test | `.github/workflows/paper-boot.yml` | CI job `paper-boot` |
| Game feel, visuals, sound, a real Minecraft client, Bedrock, real alpha data, a real mail inbox | Manual only | the smoke-test guide | the developer |

Until the scenario framework (#421) is on the branch you build on, a world step is "manual, scenario later": keep it in
the guide and name it in the PR so a later backfill picks it up.

## 3. Write the tests

1. **Playwright:**
   1. Start from a spec in `e2e/` that is close (for example `dashboard.spec.ts`).
   2. Log in with `startLoggedIn` and `mockSession` from `e2e/fixtures/auth.ts`, and register only the endpoints the
      page calls with `api.on` / `api.json`.
   3. An unmocked call is listed on the test; turn on `test.use({ strictApi: true })` once the
      spec is complete.
   4. Use role-based selectors (`getByRole`, `getByLabel`), Playwright's auto-wait, no `waitForTimeout`.
   5. Typed fixtures only: a DTO change must break `typecheck:e2e`.
   6. One behaviour per test, named for what the user sees.
2. **Unit tests:** follow the neighbouring tests' style. Plugin tests never build a `Location` around an inline
   `mock(World.class)`; keep the mocked `World` in a field (knk-plugin `CLAUDE.md`).
3. **Scenarios:** follow the scenario guide. Give the scenario a fake data gateway instead of the API, assert on world
   and plugin state, and report `KNK-SCENARIO PASS|FAIL`.
4. **A test that finds a real bug** in code you are not changing: file an issue with the failing case. In a backfill,
   don't fix behaviour. In a feature, fix it if it is in scope.
5. Run each new test once failing (break the behaviour or invert the assertion) so you know it can fail, then green.

## 4. Smoke-test guide: every step, tagged

Developer decision 2026-11-15: a guide keeps every step with its full manual instructions, so the developer can still
test everything by hand; steps a suite covers carry a tag, so they can also be skipped.

1. Write each step in full, as if no test existed. Never shorten or drop a step because it is automated.
2. Put the tag at the start of a step a suite covers, naming the test:
   `3. [automated: e2e/dashboard-access.spec.ts] As Staff without knk.admin.delete, open …` or, when only part of the
   step is covered, `[partly automated: <test>; by hand: <what is left>]`.
3. A step without a tag is manual only; add a few words on why (game feel, real client, needs a player, …).
4. Status line: how many steps are automated, that every step can still be run by hand, and whether the developer ran
   the rest, e.g. "12 of 20 steps automated in CI (tagged); every step can still be run by hand; manual steps not run".
   Give the time for a full manual run and for the untagged steps only.
5. A change whose steps are all automated still gets its guide section, all steps tagged.
6. **A designed feature already has a draft section per phase**, written by the design session from the spec's
   acceptance items and sized to the tier (`knk-design` § 6.4, template `knk-design/smoke-section-template.md`). Start
   from it: update the steps to what you built, keep every step in full, tag the ones your tests cover, and drop the
   "Draft from the design" line.

## 5. PR Testing section

Fill the template's Testing section as:

1. **Automated:** the new and changed tests per suite, and which behaviour each covers; baseline → result counts.
2. **Manual only:** the guide link and the steps left (count), or "none".
3. **Scenario later:** world steps waiting for the scenario framework, if any.

A behaviour change without a test in the right suite is not ready to merge (coordinator check, knk-coordinator § 6).
