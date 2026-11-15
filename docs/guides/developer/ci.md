# CI: what runs on every push and how to mark a known failure

**Status:** Active · **Last updated:** 2026-11-14 (§ 7 and § 7.1: 16 scenarios, `MIN_SCENARIOS` 16, plugin backfill [#511](https://github.com/PandiO/knk-workspace/issues/511), in knk-plugin `next`); 2026-11-14 (§ 1.1.2: the `requires-bukkit` tests run in CI with MockBukkit, [#499](https://github.com/PandiO/knk-workspace/issues/499), in knk-plugin `next`); 2026-11-14 (plugin scenarios in `paper-boot.yml`, § 7.1, [#421](https://github.com/PandiO/knk-workspace/issues/421), in knk-plugin `next`); 2026-11-14 (web app end-to-end tests: `e2e.yml`, § 1.1.3, [#423](https://github.com/PandiO/knk-workspace/issues/423)); 2026-11-14 (plugin Paper boot test `paper-boot.yml`, § 1, § 1.1.2 and § 7, [#420](https://github.com/PandiO/knk-workspace/issues/420)); 2026-11-13 (workflows renamed "Build and test"; Codex review comments are not CI, § 1); 2026-11-13 (§ 4 the CI run decides, § 5 reading runs as an agent, § 6 the Node.js 20 warning, [#363](https://github.com/PandiO/knk-workspace/issues/363)); 2026-11-13 (first version, [PandiO/knk-workspace#362](https://github.com/PandiO/knk-workspace/issues/362), docs follow-up of [#327](https://github.com/PandiO/knk-workspace/issues/327); checked against knk-web-api `master` `210f731`, knk-web-app `main` `33d68f8`, knk-plugin `main` `e8b651d`)

The GitHub workflows of the component repos are the automated gate for every change. They run on every push (all
branches), every pull request and on manual dispatch (`workflow_dispatch`). Under the
[branch model](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#branches-releases-and-risk-tiers) a link or feature pull
request goes into `next` only with these checks green, and `ci.yml` on knk-web-api `main` and knk-web-app `main` is
the start condition of that branch model (developer decision 2026-11-12,
[AI agent workflow design § 6](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci)).

## 1. Workflows per repo

| Repo | Workflow | What it does |
|---|---|---|
| knk-web-api | `.github/workflows/ci.yml` ("Build and test", named "CI" until 2026-11-13; added by [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12)) | .NET 8 (`actions/setup-dotnet` 8.0.x): `dotnet restore` of `knkwebapi_v2.csproj` and the test project, `dotnet build knkwebapi_v2.csproj`, then `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter "Category!=KnownFailure"`. The TRX results are uploaded as the `api-test-results` artifact, also when the tests fail. Timeout 30 minutes. |
| knk-web-api | `.github/workflows/migrations.yml` ("Migrations (fresh DB)") | Older than `ci.yml`. Starts a MySQL 8.0 service, applies every EF Core migration to the empty database, checks that the model snapshot has no pending changes (`dotnet ef migrations has-pending-model-changes`), rolls every migration back to 0 and applies them again. |
| knk-web-app | `.github/workflows/ci.yml` ("Build and test", named "CI" until 2026-11-13; added by [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9)) | Node 22 with the npm cache: `npx --yes npm@11 ci` (the lock file is valid for npm 11 only), `npm run test:ci` (`react-scripts test --watchAll=false --passWithNoTests`), `npx tsc --noEmit`, and `npm run build` with `CI=true`, so build warnings fail the job. Timeout 20 minutes. |
| knk-web-app | `.github/workflows/e2e.yml` ("End-to-end tests", job `e2e`; added by [#423](https://github.com/PandiO/knk-workspace/issues/423)) | Playwright end-to-end tests in Chromium against the production build with a mocked API (§ 1.1.3). Not a required check. Timeout 10 minutes. |
| knk-plugin | `.github/workflows/build.yml` ("Build") | Older than this setup. Java 25 compiles and tests, Java 21 runs Gradle: `./gradlew build` with the dev-server deploy pointed at a throwaway folder. |
| knk-plugin | `.github/workflows/paper-boot.yml` ("Paper boot test", [#420](https://github.com/PandiO/knk-workspace/issues/420)) | Builds the shaded jar, starts a real Paper 26.3 server with it, WorldGuard and WorldEdit, and fails unless KnK enables without errors; then runs every in-plugin scenario on that server and fails on any failed or missing one ([#421](https://github.com/PandiO/knk-workspace/issues/421)). Details in § 7. Timeout 10 minutes. |
| knk-workspace | none | Docs and configuration only. |

The "Codex Review Summary" comments on pull requests come from the ChatGPT Codex connector app, set up in the
developer's ChatGPT Codex settings. They are a separate code review, not one of these workflows and not a GitHub
status check, but agents must still handle every finding before a merge into `next` (fix it, or answer on its thread
why not, and resolve the thread; [global instructions, "Branches" rule 4](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#branches-releases-and-risk-tiers)).
See also [agent tooling § 1](agent-tooling.md#1-what-is-configured).

Both `ci.yml` workflows cancel an earlier run of the same branch and event when a new push arrives.

### 1.1 Tests that CI does not run

1. **MySQL tests of the API.** Tests marked `[MySqlFact]` (`Tests/knkwebapi_v2.Tests/MySql/MySqlTestDatabase.cs`) and
   the other `requires-mysql` tests skip themselves when the `KNK_TEST_MYSQL` environment variable is unset. The CI test
   job has no database and sets no `KNK_TEST_MYSQL`, so they show as skipped (88 at the setup on 2026-11-12). Run them
   locally against a scratch server, for example
   `KNK_TEST_MYSQL="Server=localhost;User=knk_test;Password=…" dotnet test …`; the user needs the right to create and
   drop databases named `KNK_TEST_MYSQL_DB_PREFIX`* (default `knk_test_`). Fresh-database migration bugs are caught by
   `migrations.yml` instead.
2. **Plugin tests tagged `requires-bukkit`: none any more** ([#499](https://github.com/PandiO/knk-workspace/issues/499),
   in knk-plugin `next` since `0810a6c7`, 2026-11-14). The seven test files that `excludeTags` kept out of `test`
   (52 tests, 32 failing on 2026-11-14: Bukkit statics without a server, stale stubs and expectations) pass and run in
   `test`, so `build.yml` runs them; the tags, `excludeTags` and the `taggedTest` task are gone. Tests that need Bukkit
   statics (`Registry`, `Material.isSolid()`, `Bukkit.getScheduler()`) start a MockBukkit server themselves
   (`MockBukkit.mock()` / `unmock()`, test-only dependency, developer decision 2026-11-14;
   [plugin architecture § Testing](../../architecture/plugin-architecture.md#testing)). A few tests are still
   `@Disabled` because WorldEdit/WorldGuard are not on the test classpath (the 18 skipped).
3. **Web app end-to-end tests** run in CI since 2026-11-14 ([#423](https://github.com/PandiO/knk-workspace/issues/423)):
   the workflow `.github/workflows/e2e.yml` (job `e2e`, Chromium only, timeout 10 minutes) installs with npm 11, type
   checks the specs and mocks (`npm run typecheck:e2e`), installs Chromium (`npx playwright install --with-deps
   chromium`), builds with `CI=true` and runs `npx playwright test` with one retry. The API is **mocked** in the specs
   (`page.route`), so the job needs no API or database; a real API in a container is not used (decision in #423). The
   HTML report is the `playwright-report` artifact of every run; traces and screenshots of failed tests are the
   `playwright-traces` artifact. What CI still does not cover: flows without a spec (everything except registration,
   login with the refresh path, the town list on the dashboard and the first form wizard step), other browsers, and
   the real API contract beyond the DTO types. The job is not a required check of the ruleset; adding it is the
   developer's call. Specs, commands and how to debug a failure:
   [web app testing § 3](web-app-testing.md#3-end-to-end-tests-playwright).

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

## 7. Plugin: the Paper boot test

`paper-boot.yml` in knk-plugin ([#420](https://github.com/PandiO/knk-workspace/issues/420),
[DESIGN § 6.3](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci)) proves on every push and pull request that the
shaded plugin starts on a real server, then runs the in-plugin scenarios on it (§ 7.1). The job takes about
1.5 minutes with three scenarios (2026-11-14: jar build 33 s; server boot, 15 s settle, scenarios, stop and both
checks 33 s; the scenarios themselves took about 4 s of it). The 16 scenarios since the backfill of
[#511](https://github.com/PandiO/knk-workspace/issues/511) take about 45 s on a local run, most of it the three lootbox
spawn scenarios, which wait for the spawn scheduler's one-second tries.

1. **Build:** `./gradlew :knk-paper:shadowJar -PgitCommit=<8-character commit>` (JDK 25 toolchain, Gradle on JDK 21,
   as `build.yml`). The script refuses a jar without `knk-core` classes: `build -x deployToDevServer` leaves the
   unshaded jar under the same name ([#500](https://github.com/PandiO/knk-workspace/issues/500)).
2. **Downloads, pinned and SHA-256 checked** in the workflow's `env`: Paper 26.3 build 205 (the `paperApiVersion` of
   `gradle.properties`) from PaperMC's Fill API, WorldEdit 7.4.6 and WorldGuard 7.0.20 (the versions `knk-paper`
   compiles against) from Modrinth. The downloads and Paper's Minecraft files are cached by those hashes. When
   `paperApiVersion` or the WorldEdit/WorldGuard versions change, update the URL and hash here too: the build's
   number and `sha256` are at `https://fill.papermc.io/v3/projects/paper/versions/<version>/builds/<build>`, Modrinth
   lists each file's hashes (`sha512`, compare it, then take `sha256sum` of the file).
3. **Server** (`tools/paper-boot/boot-test.sh`): accepted EULA, offline mode, bound to 127.0.0.1, a superflat world
   without structures, view distance 2. KnK runs with its shipped `config.yml`, changed in one place:
   `api.auth.api-key` gets a dummy value (KnK refuses to start with `type: apikey` and an empty key). **No API runs:**
   `api.base-url` stays `http://localhost:5294/api`, so the plugin starts in its API-down state. Startup behaviour on
   real servers is unchanged; no plugin code changed for this.
4. **Pass/fail** (`tools/paper-boot/check_log.py`, checked by its own unit tests in the same job). After "Done", the
   script waits 15 seconds for asynchronous startup work, sends `stop` and checks `logs/latest.log`. It fails when:
    1. the version-stamp line (`KnightsAndKings 0.1.0+<commit> (commit <commit>)`,
       [#136](https://github.com/PandiO/knk-workspace/issues/136)) is missing or names another commit;
    2. `KnightsAndKings Plugin Enabled!` is missing, WorldGuard or WorldEdit wasn't enabled, or the server didn't
       reach "Done";
    3. a log entry from KnK, WorldGuard or WorldEdit is an `ERROR` or carries a stack trace. Entries caused by the
       unreachable API (`Failed to connect to localhost/<address>:5294`, whatever address `localhost` resolves to)
       are excused and counted: 5 to 7 per run on 2026-11-14 (menu template validation, siege recovery, world tasks,
       compass settings);
    4. the server doesn't stop within 90 seconds, or `KnightsAndKings Plugin Disabled!` is missing.
5. **On failure** read the annotations of the "Boot the server, check the log and run the plugin scenarios" step (and
   the scenario table in the job summary), then the `paper-boot-log` artifact (`latest.log` and the server's stdout;
   uploaded on every run, kept 14 days).
6. **Run it locally** (needs JDK 25, `unzip`, `python3`): put `paper.jar` and the two plugin jars in an empty folder
   (`plugins/`), build the shaded jar, then
   `tools/paper-boot/boot-test.sh --server-dir <folder> --plugin-jar knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar --java <jdk25>/bin/java`.
   The folder is a throwaway: the script writes `eula.txt`, `server.properties` and the KnK config. Add `--scenarios`
   to run the scenarios as CI does.
7. **Console hooks:** `--console-command` sends a console command once the server is up, `--expect-line <regex>` waits
   for a log line (the run stops waiting once every expected line is there), and `--fail-line <regex>` fails at once on
   a matching line. `--scenarios` (§ 7.1) is built on them.
8. **Required check:** not yet. Once it is stable, the developer adds the check `paper-boot` (the job of "Paper boot
   test") to knk-plugin's "Trunk and next" ruleset.

### 7.1 In-plugin scenarios

[#421](https://github.com/PandiO/knk-workspace/issues/421), [DESIGN § 6.3.2](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci);
in knk-plugin `next` (`309d3580`, 2026-11-14), not on trunk yet. How to write one:
[writing a plugin scenario](plugin-scenarios.md).

1. **What runs:** the boot step passes `--scenarios --min-scenarios "$MIN_SCENARIOS" --expect-timeout 180`. The script
   sets `testing.scenarios.enabled: true` in the KnK config (off in the shipped `config.yml`), and after the 15 s
   settle sends `knk scenario run all` to the console. The plugin runs every scenario one after the other and logs
   `KNK-SCENARIO START <name>`, then `KNK-SCENARIO PASS <name> (<n> ticks)` or `KNK-SCENARIO FAIL <name>: <reason>`,
   and finally `KNK-SCENARIO SUMMARY passed=<p> failed=<f> total=<t>`. The script waits for the summary line (at most
   180 s), stops the server and runs both checks.
2. **Pass/fail** (`tools/paper-boot/check_scenarios.py`, with its own unit tests in the "Test the log check" step): the
   job fails on any `FAIL` line, a scenario that started without a result, a missing summary line, a summary that
   doesn't match the lines, or fewer than `MIN_SCENARIOS` scenarios (16 since the #511 backfill, 2026-11-14; raise it in the workflow's boot
   step when you add one, so a scenario that silently stops registering is caught). A failed scenario doesn't stop the
   run: every result is in the log and in the table the check writes to the job summary. The boot check of § 7 item 4
   still applies, so an `ERROR` a scenario causes fails the job too.
3. **The scenarios** (2026-11-14): `gate-open-close` (a portcullis from fake API data opens and closes through the live
   animation task), `gate-closing-moves-entity-out` (KNG-106: a pig in the doorway is moved out by the closing door
   and never suffocates), `global-region-explosion` (TNT breaks nothing outside every region, but does inside a
   temporary WorldGuard region). Each was checked to fail with its behaviour broken.
4. **Server setting:** `server.properties` gets `pause-when-empty-seconds=-1`, so the server keeps ticking with nobody
   online (vanilla pauses an empty server after 60 s).

## Related

- [Agent tooling](agent-tooling.md): the Stop hook that compiles changed component repos in a session, before CI runs.
- [`knk-link` skill](../../../.claude/skills/knk-link/SKILL.md) (baseline tests, the pull request) and
  [`knk-coordinator` skill](../../../.claude/skills/knk-coordinator/SKILL.md) (CI green before merging into `next`).
- [Documentation maintenance](DOCUMENTATION_MAINTENANCE.md).
- [Production installation](../production-installation.md) § 10: the release and deploy stages that come after CI (plans, not built).
