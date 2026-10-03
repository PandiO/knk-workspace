# Player statistics chain — link 7 handoff

**Date:** 2026-10-03 · **Written by:** link 6 (`session_01Y76s776YpnJ6PKqYFU23As`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 7 — World analytics + final write-up** end to end (code, tests, commits, push to
claude/kind-dijkstra-y9d279, progress report incl. the **final summary**, no further handoff) as link 7 of the chain.
This is the **last link — stop after the write-up** (charter §5 "Link 7", §6.3).

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: plan `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md` (binding; read
  the "Link 2/3/4/5/6 status" notes at the end), DESIGN.md §F (D10/D11), progress report with the Link 6 block
  (L6-1 … L6-23, follow-up list, live checklist).
- knk-web-api `claude/kind-dijkstra-y9d279` head `8b67e2c` (= `master` `ae0b3ad` + links 2-6). Baseline: **2,009** tests,
  1,942 passed, the same **5** known pre-existing failures (listed in the link 2 block), 62 skipped. Latest migration
  `20261003045617_AddDiagnosticTelemetryAndPrivacy`. MySQL-gated: `TeleportChargeMySqlTests` ×5 fail on trunk too.
- knk-plugin `claude/kind-dijkstra-y9d279` head `aa42247` (= `main` `ee7824c` + links 3-6). Gradle, all green: knk-core
  **1,294**, knk-api-client **163** (2 skipped), knk-paper **1,087** (14 skipped). Maven hosts reachable; first build
  ~2-3 min, then `--offline`.
- knk-web-app `claude/kind-dijkstra-y9d279` head `4c6e0ca` (= `main` `fc66101` + links 5-6). Baseline: **458** tests,
  453 passed, the same **5** pre-existing failures (FormWizard ×3, `LoginForm`, `useEnrichedFormContext`); `npm run build`
  passes with pre-existing warnings. **`npm ci` fails on trunk** (lock misses `yaml@2.9.1`): `npm install`, then
  `git checkout package-lock.json` (don't commit the lock). Jest can't resolve `react-router-dom` — mock it with
  `{ virtual: true }` (see `OwnerTelemetryPage.test.tsx`).
- Trunks at the end of link 6: knk-web-api `master` `ae0b3ad`, knk-plugin `main` `ee7824c`, knk-web-app `main` `fc66101`
  (check `docs/ACTIVE_SESSIONS.md` on workspace `main` and `git fetch` every repo first).
- Toolchain notes (worked in links 5-6): `add_repo` (access `push`) for the three code repos, then
  `git clone --depth 50 -b claude/kind-dijkstra-y9d279 …`; trunk refs need `git fetch origin +refs/heads/<t>:refs/remotes/origin/<t>`.
  `sudo apt-get install -y dotnet-sdk-8.0 mysql-server` (~5 min, run in the background), `sudo service mysql start`,
  `CREATE USER 'knk'@'localhost' IDENTIFIED BY 'knk'; GRANT ALL ON *.*`; `dotnet tool install --global dotnet-ef
  --version '8.*'`. Build the API with **`dotnet build knkwebapi_v2.csproj`** (the `.sln` points at a lower-case `tests/`
  path and fails on Linux). Migrations: `ConnectionStrings__MySqlDbConnection="Server=localhost;Database=knk_dev;User=knk;
  Password=knk;Allow User Variables=True;" dotnet ef migrations add <Name> --project knkwebapi_v2.csproj` (build first, then
  `dotnet ef database update` to prove it applies). MySQL-gated tests: `KNK_TEST_MYSQL="Server=localhost;User=knk;Password=knk;Allow User Variables=True;"`.
  Record baselines on a **clean worktree** (`git worktree add /home/user/api-base HEAD`) while you edit — a build running
  in your working copy picks up half-written files. Live API: `dotnet build knkwebapi_v2.csproj -o <dir>` and run
  `dotnet <dir>/knkwebapi_v2.dll` with `Security__PluginApiKey=smoke ASPNETCORE_URLS=http://localhost:5294`; stop it by
  PID (`pkill -f …` matching your own command line kills your shell). Owner calls in a smoke test: plugin key +
  `X-Acting-User-Id` of a user with a **direct** grant row in `permission_grants` (users need a `permission_holders` row first).
  `~/.gradle/gradle.properties` per charter §1.4. Write sources with the file tools, not heredocs.

**What earlier links say this link must wire:**
- Plan §1.4 (migration `AddWorldAnalytics`, anonymous aggregates only — no user ids, so GDPR erasure needs no change),
  §3.4 (`WorldAnalyticsController`, all reads owner(`knk.owner.analytics.view`) — `OwnerPermissions.AnalyticsView` exists),
  §4 link-7 row + `WorldAnalytics` config, §5.1 `world-analytics:` block, §5.2 link-7 rows, §8 link 7.
- **Menu funnels:** register a `MenuFunnelRecorder implements MenuObserver` with `MenuService.addObserver(...)` (see how
  `KnKPlugin` registers `telemetryHooks` right after the menu service is created). Calls arrive on the main thread:
  `menuOpened(player, menuKey, parentMenuKey)`, `menuBack(player, from, to)`, `menuClosed(playerId, menuKey)`,
  `actionExecuted(player, menuKey, actionTypeId, slot, outcome SUCCEEDED|DENIED|FAILED)`. Steps per plan §1.4
  (`opened`, `action:<actionTypeId>`, `back`, `closed`). Menu keys added in link 5 (`statistics.main`,
  `statistics.leaderboards`, `statistics.leaderboard`) flow through it like every other menu.
- **Owner page:** `OwnerRoute` + `OwnerOnlyNotice` exist (`src/components/OwnerRoute.tsx`); add an
  `OWNER_ANALYTICS_VIEW_NODE` (`knk.owner.analytics.view`) and a nav entry like Diagnostics (`node:` gated). Heatmap =
  `<canvas>` (no new npm dependencies).
- **Domain interactions:** `OnRegionEnterEvent`/`OnRegionLeaveEvent` (`P/regions/WorldGuardRegionTracker`) + discovery
  grants (`DiscoveryEffects.setGrantObserver` is taken by telemetry — add a second observer or a list rather than
  replacing it).
- **Movement sampling:** exclude AFK (`StatisticsService.isAfk`), spectators and excluded game modes; aggregate cells in
  memory, flush every `flush-interval-seconds` off the main thread, never across a local midnight (catalogue `timeZone`).
- **Final write-up (charter §5 "Link 7"):** Summary block of the progress report (what was built, decisions to review
  ranked — start from the "Review first" list, which links 1-6 keep appending to), the **combined live checklist**
  (links 3-7 each wrote one), merge order (API → plugin → app; migrations first: `AddPlayerStatistics`, `AddLeaderboards`,
  `AddDiagnosticTelemetryAndPrivacy`, `AddWorldAnalytics`), the GDPR follow-up list from the Link 6 block,
  `docs/FEATURE_REGISTER.md`, `docs/CHANGELOG.md` (unmerged branch noted), tracker row moved to "Recently completed"
  (nothing merged), Linear comment on KNG-34.

**Phase-specific reading:** plan §1.4, §3.4, §4 (link-7 row, `WorldAnalytics` config), §5.1 `world-analytics:`, §5.2
link-7 rows, §7 analytics budget, §8 "Link 7"; DESIGN.md D10/D11 and §F.15 (180-day retention); the Link 6 block of the
progress report (MenuObserver contract, owner page pattern).

**Open flags that affect this link:** L1-19 (retention defaults), L5-9 (job switches pattern), L6-14 (correlation only
while telemetry is on — analytics doesn't need it), L6-21 (owner pages: display check by wildcard, API exact grant).

**Known risks:** four repos (all of them) — if code can't finish, the write-up still must (the last link may only leave
items over as a written follow-up list, charter §0); movement sampling must stay ≤ 1 sample / player / 10 s and allocate
nothing per move event (use a timer, not `PlayerMoveEvent`); no user ids or names in any analytics table or payload;
menu seeds are create-only (reset in the live checklist if you add menus).

**Next after you:** none — link 7 is the last link. Stop after the write-up; start no further session.
