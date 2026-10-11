# Player statistics chain — link 6 handoff

**Date:** 2026-10-03 · **Written by:** link 5 (`session_01HnVoNfWS1zecanekJBqQnp`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 6 — Diagnostic telemetry + privacy** end to end (code, tests, commits, push to
claude/kind-dijkstra-y9d279, progress report, handoff) as link 6 of the chain.

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: plan `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md` (binding; read
  the "Link 2/3/4/5 status" notes at the end), DESIGN.md §F.12-§F.15, progress report with the Link 5 block (L5-1 … L5-16).
- knk-web-api `claude/kind-dijkstra-y9d279` head `2dec32b` (= `master` `ae0b3ad` + links 2-5). Baseline: **1,905** tests,
  1,841 passed, the same **5** known pre-existing failures (listed in the link 2 block), 59 skipped. Latest migration
  `20261003040910_AddLeaderboards`.
- knk-plugin `claude/kind-dijkstra-y9d279` head `5481327` (= `main` `ee7824c` + links 3-5). Gradle baseline, all green:
  knk-core **1,275**, knk-api-client **159** (2 skipped), knk-paper **1,060** (14 skipped). Maven hosts reachable; first
  build ~3 min, then `--offline`.
- knk-web-app `claude/kind-dijkstra-y9d279` head `00d978e` (link 5 created the branch from `main` `fc66101`). Baseline:
  **445** tests, 440 passed, the same **5** pre-existing failures (FormWizard ×3, `LoginForm`, `useEnrichedFormContext`);
  `npm run build` passes with pre-existing warnings. **`npm ci` fails on trunk** (lock file misses `yaml@2.9.1`): run
  `npm install` and `git checkout package-lock.json` afterwards (don't commit the lock). Jest can't resolve
  `react-router-dom` — tests mock it with `{ virtual: true }` (see `LeaderboardsPage.test.tsx`).
- Trunks at the end of link 5: knk-web-api `master` `ae0b3ad`, knk-plugin `main` `ee7824c`, knk-web-app `main` `fc66101`
  (check `docs/ACTIVE_SESSIONS.md` on workspace `main` and `git fetch` every repo first).
- Toolchain notes (worked in link 5): the three code repos may need `add_repo` (access `push`) before pushing — a 403 on
  `git push --dry-run` means the repo isn't attached to the session yet; `sudo apt-get install -y dotnet-sdk-8.0` and
  `mysql-server` (`sudo service mysql start`; `CREATE USER 'knk'@'localhost' IDENTIFIED BY 'knk'; GRANT ALL ON *.*`);
  `dotnet tool install --global dotnet-ef --version 8.*` — `dotnet ef migrations add` needs a reachable MySQL (server
  autodetect): `ConnectionStrings__MySqlDbConnection="Server=localhost;Database=knk_dev;User=knk;Password=knk;Allow User
  Variables=True;"`. MySQL-gated tests: `KNK_TEST_MYSQL="Server=localhost;User=knk;Password=knk;Allow User Variables=True;"`.
  Live API: `Security__PluginApiKey=smoke ASPNETCORE_URLS=http://localhost:5294 dotnet run --no-build --project
  knkwebapi_v2.csproj --no-launch-profile` (stop it by PID — `pkill -f knkwebapi_v2` also kills your own shell).
  `~/.gradle/gradle.properties` per charter §1.4. Write sources with the file tools, not heredocs.

**What earlier links say this link must wire:**
- Plan §1.3 (migration `AddDiagnosticTelemetryAndPrivacy`), §3.3 (`TelemetryController`, `PrivacyController`), §4
  link-6 rows (ingestion queue/writer, query, catalogue, retention, `ApiFailureTelemetryMiddleware`,
  `PrivacyDeletionService` + due job, `POST api/statistics/rebuild` owner(`knk.owner.telemetry.manage`) — the service
  `IStatisticsRebuildService.RebuildAsync(projection, userId?)` exists since link 2), §5.1 `telemetry:` config, §5.2
  link-6 rows (emitter, buffer, flush, config poller, `MenuObserver` hook, `SiegeMatchObserver` default methods,
  `X-Correlation-Id`), §6 owner nodes (`RequireOwnerPermission` exists; constants in `Attributes/OwnerPermissions.cs`),
  §8 link 6 (acceptance criteria 1-5, test list). Web: `OwnerRoute`, `/owner/telemetry`, `/owner/privacy`.
- **GDPR deletion scope additions from link 5:** delete the user's `leaderboard_snapshot_entries` rows (snapshots hold
  user ids; or delete and let the next refresh rebuild), every statistic row of the user incl. the internal
  `pvp_kills.ranked` daily/total rows, and clear `player_stat_profiles` exclusion columns (or the row). Kill-pair rows
  where the user is killer **or** victim.
- Menu keys added in link 5 (`statistics.main`, `statistics.leaderboards`, `statistics.leaderboard`) flow through the
  `MenuObserver` hook like every other menu.

**Phase-specific reading:** plan §1.3, §3.3, §4 (link-6 rows + `DiagnosticTelemetry`/`Privacy` config), §5.1 telemetry
block, §5.2 link-6 rows, §6, §7 telemetry budget, §8 "Link 6"; DESIGN.md §F.12 (event contract + catalogue), §F.13
(owner-only access), §F.14 (GDPR scope — flagged L1-18), §F.15 (retention), "Diagnostic and balance telemetry", "First
vertical slice" (Siege). knk-web-api `OBSERVABILITY.md` (no player ids in metric labels).

**Open flags that affect this link:** L1-17 (owner nodes exact grant), L1-18 (GDPR scope + auto-execution 3 days before
due), L1-19 (retention defaults), L1-23 (telemetry buffered and dropped, never spooled), L2-11 (owner nodes must be
granted directly on the user), L5-2 (`pvp_kills.ranked` must be deleted with the user's statistics), L5-9 (leaderboard
job switch).

**Known risks:** three repos again — if it can't finish, the web owner pages move to link 7 (charter §0, record it);
telemetry must never block gameplay (bounded buffer, drop with a counter, I/O off the main thread); no chat text, command
arguments, IPs, tokens or raw bodies in events (tests assert it); `AuditAction` values are appended only (never
renumber); GDPR deletion is irreversible for the player — keep it behind the owner node, dry-run counts in the result,
idempotent execute; menu seeds are create-only (reset in the live checklist if you add menus).

**Next after you:** link 7 — world analytics + final write-up (all four repos; the last link — stop after the write-up).
