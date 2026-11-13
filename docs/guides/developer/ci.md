# CI: what runs on every push and how to mark a known failure

**Status:** Active · **Last updated:** 2026-11-13 (workflows renamed "Build and test"; Codex review comments are not CI, § 1); 2026-11-13 (§ 4 the CI run decides, § 5 reading runs as an agent, § 6 the Node.js 20 warning, [#363](https://github.com/PandiO/knk-workspace/issues/363)); 2026-11-13 (first version, [PandiO/knk-workspace#362](https://github.com/PandiO/knk-workspace/issues/362), docs follow-up of [#327](https://github.com/PandiO/knk-workspace/issues/327); checked against knk-web-api `master` `210f731`, knk-web-app `main` `33d68f8`, knk-plugin `main` `e8b651d`)

The GitHub workflows of the component repos are the automated gate for every change. They run on every push (all
branches), every pull request and on manual dispatch (`workflow_dispatch`). Under the
[branch model](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#branches-releases-and-risk-tiers) a link or feature pull
request goes into `next` only with these checks green, and `ci.yml` on knk-web-api `master` and knk-web-app `main` is
the start condition of that branch model (developer decision 2026-11-12,
[AI agent workflow design § 6](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci)).

## 1. Workflows per repo

| Repo | Workflow | What it does |
|---|---|---|
| knk-web-api | `.github/workflows/ci.yml` ("Build and test", named "CI" until 2026-11-13; added by [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12)) | .NET 8 (`actions/setup-dotnet` 8.0.x): `dotnet restore` of `knkwebapi_v2.csproj` and the test project, `dotnet build knkwebapi_v2.csproj`, then `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter "Category!=KnownFailure"`. The TRX results are uploaded as the `api-test-results` artifact, also when the tests fail. Timeout 30 minutes. |
| knk-web-api | `.github/workflows/migrations.yml` ("Migrations (fresh DB)") | Older than `ci.yml`. Starts a MySQL 8.0 service, applies every EF Core migration to the empty database, checks that the model snapshot has no pending changes (`dotnet ef migrations has-pending-model-changes`), rolls every migration back to 0 and applies them again. |
| knk-web-app | `.github/workflows/ci.yml` ("Build and test", named "CI" until 2026-11-13; added by [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9)) | Node 22 with the npm cache: `npx --yes npm@11 ci` (the lock file is valid for npm 11 only), `npm run test:ci` (`react-scripts test --watchAll=false --passWithNoTests`), `npx tsc --noEmit`, and `npm run build` with `CI=true`, so build warnings fail the job. Timeout 20 minutes. |
| knk-plugin | `.github/workflows/build.yml` ("Build") | Older than this setup. Java 25 compiles and tests, Java 21 runs Gradle: `./gradlew build` with the dev-server deploy pointed at a throwaway folder. |
| knk-workspace | none | Docs and configuration only. |

The "Codex Review Summary" comments on pull requests come from the ChatGPT Codex connector app, set up in the
developer's ChatGPT Codex settings. They are a separate code review, not one of these workflows, and do not gate a merge
([agent tooling § 1](agent-tooling.md#1-what-is-configured)).

Both `ci.yml` workflows cancel an earlier run of the same branch and event when a new push arrives.

### 1.1 Tests that CI does not run

1. **MySQL tests of the API.** Tests marked `[MySqlFact]` (`Tests/knkwebapi_v2.Tests/MySql/MySqlTestDatabase.cs`) and
   the other `requires-mysql` tests skip themselves when the `KNK_TEST_MYSQL` environment variable is unset. The CI test
   job has no database and sets no `KNK_TEST_MYSQL`, so they show as skipped (88 at the setup on 2026-11-12). Run them
   locally against a scratch server, for example
   `KNK_TEST_MYSQL="Server=localhost;User=knk_test;Password=…" dotnet test …`; the user needs the right to create and
   drop databases named `KNK_TEST_MYSQL_DB_PREFIX`* (default `knk_test_`). Fresh-database migration bugs are caught by
   `migrations.yml` instead.
2. **Plugin tests that need a real server.** Tests tagged `integration` or `requires-bukkit` are excluded by
   `excludeTags` in `knk-paper/build.gradle.kts`, and a few are `@Disabled` because WorldEdit/WorldGuard are not on the
   test classpath. They stay out until the boot test of
   [DESIGN § 6.3](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci) exists.
3. **Web app end-to-end tests** (Cypress, moving to Playwright) are not in CI.

## 2. Marking a known failure

A test that is red for a reason outside the change at hand is marked as a known failure, so it doesn't block merges
([DESIGN § 6.2](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci)). A mark is never a way to get a change's own
test green.

1. **File or reuse the issue first.** One GitHub issue in `PandiO/knk-workspace` lists every marked test, labelled `bug`
   and `priority:high`. Add the test to it, or create it if it doesn't exist yet. At the setup on 2026-11-12 no test was
   red, so no test is marked and the issue doesn't exist yet.
2. **API (xUnit):** add the trait and name the issue:

   ```csharp
   [Fact]
   [Trait("Category", "KnownFailure")] // PandiO/knk-workspace#<n>: <why it fails>
   public void Some_test() { … }
   ```

   The CI filter `Category!=KnownFailure` already excludes it, so no workflow change is needed. Locally the test still
   runs unless you pass the same filter.
3. **Web app (Jest):** skip it with the issue in the reason:

   ```ts
   // PandiO/knk-workspace#<n>: <why it fails>
   it.skip('does something', () => { … });
   ```

4. **Plugin (JUnit 5):** `@Disabled("PandiO/knk-workspace#<n>: <why it fails>")`.
5. When the test is fixed, remove the mark and the test's line from the issue; close the issue when it lists no tests.

## 3. When CI is red

1. Open the failed run from the pull request's checks. For the API, download the `api-test-results` artifact for the
   full TRX.
2. Reproduce locally with the same command as the workflow (table above). The web app needs npm 11
   (`npx npm@11 ci`); a lock file written by another npm version fails `npm ci`.
3. Fix the cause on the feature branch. Never skip, disable or mark a test to get the change's own pull request green;
   a mark (§ 2) is only for a red test the change didn't cause, with its issue.

## 4. The CI run decides

A GitHub runner is not a developer machine and not the agent container: it runs Ubuntu in UTC with a default
(non-Dutch) culture, on other hardware. A test that depends on the culture (number and date formats), the time zone or
timing can be green locally and red in CI, or the other way round; the nl-NL and timing reds recorded by earlier chains
were green on the runner at the setup. When the two disagree, the **CI run on the branch counts** for merging. Don't
call a branch green from a local run alone; fix the test so it pins its culture or time zone, or, if the change didn't
cause it, mark it (§ 2).

## 5. Reading runs as an agent

The `github` MCP server ([agent tooling](agent-tooling.md) § 2, toolset `actions`) reads runs in `PandiO/*`. The
component repository must be attached to the session (`add_repo`); otherwise the call is refused.

1. `actions_list` with `list_workflow_runs`, `resource_id` `ci.yml` (or `migrations.yml`, `build.yml`) and a `branch`
   filter: a branch's runs with status and conclusion. For a pull request, `pull_request_read` with `get_check_runs`
   gives the checks of its head commit.
2. `actions_get` with `get_workflow_run` and the run id: one run's details.
3. `actions_list` with `list_workflow_jobs` and the run id: the jobs and their steps, to see which step failed.
4. `get_job_logs` with `run_id`, `failed_only: true` and `return_content: true` (or a `job_id`): the log tail of the
   failed job; `tail_lines` sets how much.
5. For the API, `actions_list` with `list_workflow_run_artifacts` finds `api-test-results` (the TRX file) when the log
   doesn't make the failing tests clear.

Don't poll in a loop for a run to finish: a session that watches a pull request (`subscribe_pr_activity`) gets CI
results as events.

## 6. Known warning

Every run is annotated with a warning that `actions/checkout@v4`, `setup-dotnet@v4`, `setup-node@v4` and
`upload-artifact@v4` target Node.js 20 and are forced onto Node.js 24 (`migrations.yml` too). It doesn't fail a run; a
later bump to the next major versions of these actions clears it.

## Related

- [Agent tooling](agent-tooling.md): the Stop hook that compiles changed component repos in a session, before CI runs.
- [`knk-link` skill](../../../.claude/skills/knk-link/SKILL.md) (baseline tests, the pull request) and
  [`knk-coordinator` skill](../../../.claude/skills/knk-coordinator/SKILL.md) (CI green before merging into `next`).
- [Documentation maintenance](DOCUMENTATION_MAINTENANCE.md).
- [Production installation](../production-installation.md) § 10: the release and deploy stages that come after CI (plans, not built).
