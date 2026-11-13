# Continuous integration (CI)

**Status:** Active · **Last updated:** 2026-11-13 (first version: the CI workflows of knk-web-api and knk-web-app,
[PandiO/knk-workspace#328](https://github.com/PandiO/knk-workspace/issues/328), docs in
[#363](https://github.com/PandiO/knk-workspace/issues/363))

What GitHub Actions runs in the component repos, how known failures are marked, and how an agent reads a run. This
describes the merged state: knk-web-api `master` = `next` at `210f731`, knk-web-app `main` = `next` at `33d68f8`
(PRs [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12) and
[knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9)). Design: [AI agent workflow](../../specs/ai-agent-workflow/DESIGN.md)
§ 6. The release and deploy stages (CD) are still plans: see [production installation](../production-installation.md) § 10.

CI on the API and web-app default branches is also the start condition of the `next` branch model
([global instructions § Branches](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#branches-releases-and-risk-tiers)):
feature branches start from `next`, and coordinators merge into `next` once CI and their link checks pass.

## 1. What runs where

All workflows run on every push (all branches), every pull request and on manual dispatch (`workflow_dispatch`, Actions
tab → the workflow → **Run workflow**). Nothing needs secrets or repository settings.

| Repo | Workflow | Job (check name) | Steps |
|---|---|---|---|
| knk-web-api | `.github/workflows/ci.yml` | `CI / build-and-test` | .NET 8 (`setup-dotnet` 8.0.x); `dotnet restore` of `knkwebapi_v2.csproj` and the test project; `dotnet build knkwebapi_v2.csproj`; `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter "Category!=KnownFailure"`. The TRX results are uploaded as the artifact `api-test-results`, also when the tests fail. Timeout 30 min. |
| knk-web-api | `.github/workflows/migrations.yml` | `Migrations (fresh DB) / fresh-database` | A MySQL 8.0 service container; applies every EF Core migration to an empty database, checks that the model snapshot has no pending changes, rolls all migrations back to 0 and re-applies them. |
| knk-web-app | `.github/workflows/ci.yml` | `CI / build-and-test` | Node 22 with the npm cache; `npx --yes npm@11 ci` (the lock file is valid for npm 11 only); `npm run test:ci` (Jest, `--watchAll=false --passWithNoTests`); `npx tsc --noEmit`; `npm run build` with `CI=true`, so ESLint warnings fail the build. Timeout 20 min. |
| knk-plugin | `.github/workflows/build.yml` | `Build / build` | JDK 25 (compiles and tests) and JDK 21 (runs Gradle 8.14); `./gradlew build` with `devServerDirectory` pointed at a throwaway folder. Compiles all modules and runs the unit tests. |

Both `ci.yml` files have a concurrency group per workflow, event and ref, so a newer push to the same branch cancels
the run still in progress. A pull request from a branch in the same repo runs twice (push and `pull_request`); both
must be green.

CI does **not** run: the API's `requires-mysql` tests (§ 2), the web app's Cypress end-to-end tests, the plugin's
`integration` / `requires-bukkit` tests that need a real server (DESIGN § 6.3, not built yet), or anything against
dev, alpha or a live Minecraft server. Smoke tests stay manual.

Making `CI / build-and-test` a required check in branch protection is optional and up to the developer (L1 report
§ 4.1 item 7); the workflows themselves don't need it.

## 2. MySQL tests skip themselves

API tests that need a real MySQL (row locks, transactions, unique indexes, triggers) are tagged
`[Trait("Category", "requires-mysql")]` and use `[MySqlFact]` (`Tests/knkwebapi_v2.Tests/MySql/MySqlTestDatabase.cs`).
They are skipped unless the environment variable `KNK_TEST_MYSQL` holds a connection string. The CI job sets no
`KNK_TEST_MYSQL` and has no database, so they show up as **skipped** in the test count (88 at the L1 run), not as
failures and not filtered out. To run them locally:

```bash
KNK_TEST_MYSQL="Server=localhost;User=knk_test;Password=…" \
  dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter Category=requires-mysql
```

The user needs to create and drop databases named `KNK_TEST_MYSQL_DB_PREFIX`* (default `knk_test_`); set
`KNK_SKIP_LEDGER_TRIGGERS=true` when the server has binary logging on and the user lacks SUPER. Migrations against a
real MySQL are covered separately by `migrations.yml`.

## 3. Known failures

A test that is red for a known reason and can't be fixed right away is marked, so it doesn't block every merge
(DESIGN § 6.2):

1. **API:** add `[Trait("Category", "KnownFailure")]` to the test. The `ci.yml` filter `Category!=KnownFailure`
   already excludes it; no workflow change is needed.
2. **Web app:** change `test(...)` / `it(...)` to `test.skip(...)` with a comment on the line above.
3. **Every mark names its tracking issue** in a comment, for example
   `// Known failure in CI: PandiO/knk-workspace#123`. One issue lists every marked test, labelled `bug` and
   `priority:high`. Remove the mark in the same change that fixes the test.

**No test is marked today** (2026-11-13), so no such issue exists. The four tests of #99 and the nl-NL and timing
reds recorded by earlier chains were green on the GitHub runner at the L1 run.

## 4. The CI run decides

A GitHub runner is not a developer machine and not the agent container: it runs Ubuntu in UTC with a default
(non-Dutch) culture, on different hardware. A test that depends on the culture (number and date formats), the time
zone or timing can be green locally and red in CI, or the other way round. When the two disagree, the **CI run on the
branch is the result that counts** for merging; fix the test so it pins its culture or time zone, or mark it as a known
failure with an issue (§ 3). Don't call a branch green from a local run alone.

## 5. Reading runs as an agent

The `github` MCP server ([agent tooling](agent-tooling.md) § 2, toolset `actions`) reads runs in `PandiO/*`. The
repository must be attached to the session (`add_repo`), otherwise the call is refused.

1. `actions_list` with `list_workflow_runs`, `resource_id` `ci.yml` (or `migrations.yml`, `build.yml`) and a
   `branch` filter: the runs of a branch, with status and conclusion.
2. `actions_get` with `get_workflow_run` and the run id: one run's details. For a pull request,
   `pull_request_read` with `get_check_runs` gives the checks of its head commit.
3. `actions_list` with `list_workflow_jobs` and the run id: the jobs and their steps, to see which step failed.
4. `get_job_logs` with `run_id` and `failed_only: true` (or a `job_id`) and `return_content: true`: the log tail of
   the failed job. `tail_lines` sets how much.
5. For the API, `list_workflow_run_artifacts` lists `api-test-results` (the TRX file) when the failing test names
   aren't clear from the log.

Never poll in a loop for a run to finish: a session watching a pull request gets CI results as events
(`subscribe_pr_activity`).

## 6. Known warnings

GitHub annotates every run with a warning that `actions/checkout@v4`, `setup-dotnet@v4`, `setup-node@v4` and
`upload-artifact@v4` target Node.js 20 and are forced onto Node.js 24 (also in `migrations.yml`). It does not fail a
run; a later bump to the next major versions of these actions clears it.
