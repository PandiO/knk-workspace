# Player statistics chain — link 5 handoff

**Date:** 2026-10-03 · **Written by:** link 4 (`session_01GiwQhoD6EA3m9WvVPmdU3d`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 5 — Read surfaces + leaderboards** end to end (code, tests, commits, push to
claude/kind-dijkstra-y9d279, progress report, handoff) as link 5 of the chain.

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: plan `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md` (binding; read
  the "Link 2/3/4 status" notes at the end), DESIGN.md §F.1, §F.4, §F.10, §F.11, progress report with the Link 4 block
  (decisions L4-1 … L4-12).
- knk-web-api `claude/kind-dijkstra-y9d279` head `12ae516` (= `master` `ae0b3ad` + links 2-4). Baseline: 1,849 tests,
  1,787 passed, the same 5 known pre-existing failures (listed in the link 2/3 report blocks), 57 skipped.
- knk-plugin `claude/kind-dijkstra-y9d279` head `65a0e7d` (= `main` `ee7824c` + links 3-4). Gradle baseline, all green:
  knk-core **1,269**, knk-api-client **153** (2 skipped), knk-paper **1,043** (14 skipped). The Maven hosts were
  reachable; first build ~2 min, then `--offline`.
- knk-web-app `claude/kind-dijkstra-y9d279`: untouched by the chain so far (created 2026-10-03 from `main`). Record its
  baseline first (`npm ci`, `npm run test:ci`, `npm run build`; the nav hotfix row in `ACTIVE_SESSIONS.md` mentions 16
  pre-existing failures on `main` at one point — verify).
- Trunks: check `docs/ACTIVE_SESSIONS.md` on workspace `main` and `git fetch` every repo first; at the end of link 4
  knk-plugin `main` was still `ee7824c`, knk-web-api `master` `ae0b3ad`.
- Toolchain notes (worked in link 4): `sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0` (and
  `mysql-server` if you need a live smoke test — see the link 3 handoff for the `dotnet ef`/`dotnet run` recipe);
  `~/.gradle/gradle.properties` per charter §1.4. Clone with `--depth 60 --no-single-branch` so trunk merges work.
  Avoid `cat` without input in shell commands (it blocks on stdin).

**What earlier links say this link must wire:**
- API reads already exist (link 2): `GET api/statistics/users/{id}` (viewer-filtered; `period`/`date`), title history,
  catalog, visibility GET/PUT (atomic, 409 with `current`). Link 5 adds leaderboard snapshots, `LeaderboardsController`,
  `PlayersController` public profile (plan §1.2, §3.2, §4, §8 link 5).
- Plugin: `C/ports/api/StatisticsApi` has `postBatch`, `getCatalog`, `getVisibility`, `updateVisibility`; **add
  `getUserStatistics` and `getTitleHistory`** (L3-9) with DTOs/mapper in knk-api-client. `UserCommand.statisticsLines` /
  `ProfileView.getStatisticsLines()`, `StatisticsMenuFeature` (`statistics.main`), `LeaderboardsMenuFeature`,
  `LeaderboardsApi` + impl, `/leaderboard` (`/lb`) — plan §5.2 link-5 rows and §5.3; menu seeds in knk-web-api
  `MenuTemplateSeed.Statistics.cs` (link 3 created it with `statistics.visibility`), test mirror
  `knk-paper/src/test/resources/menu/content-seeds.json` regenerated (`ContentSeedFixture`), `profile.main` slot 5.
- Every link-4 metric is already being sent by the plugin; `deaths_by_cause.*` are internal (never shown). Siege wins/
  losses/draws/objectives and siege kills/deaths/streaks come from the API projection.

**Phase-specific reading:** plan §1.2, §3.2, §4 (leaderboard job/options), §5.2 link-5 rows, §5.3, §6 (nodes), §8
"Link 5" (acceptance criteria 1-5 and test list), §9 risks ("Link 5 spans three repos" — if it can't finish, the staff
panel and leaderboard web page move to link 6, recorded in the report); DESIGN.md §F.4 (visibility), §F.11 (leaderboards
incl. repeat-victim cap, ranks, ties), "Leaderboards (recommendation adopted)".

**Open flags that affect this link:** L1-3 (anonymous visitors see only always-public fields), L1-4, L2-5 (hidden totals
returned as `value: null` with visible contexts), L2-6 (profile playtime lifetime), L2-12 (ledger backfill), L3-9 (read
methods yours), L3-15 (menu caches settings 5 s), L4-1 (damage received capped like dealt), L4-3 (rejoined Siege member is
one row).

**Known risks:** three repos in one link — keep the cut in §9 in mind; menu seeds are create-only (reset script in every
live checklist); `MenuTemplateSeed` changes need the test mirror regenerated; the web app must not add npm dependencies
(charts = Tailwind/SVG); visibility must be enforced by the API on every read (the client only renders what it gets).

**Next after you:** link 6 — diagnostic telemetry + privacy (knk-web-api, knk-plugin, knk-web-app).
