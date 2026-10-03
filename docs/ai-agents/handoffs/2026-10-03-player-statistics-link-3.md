# Player statistics chain — link 3 handoff

**Date:** 2026-10-03 · **Written by:** link 2 (`session_01M59wGLFhAji7UwGaZuoAdR`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 3 — Plugin foundation** end to end (code, tests, commits, push to claude/kind-dijkstra-y9d279, progress
report, handoff) as link 3 of the chain.

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: plan `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md` (binding;
  read its new "Link 2 status" note at the end — public shape changes L2-2/L2-5/L2-7/L2-9), DESIGN.md §F, progress
  report with the Link 2 block.
- knk-web-api `claude/kind-dijkstra-y9d279` head `b13ff0c` (= trunk `master` `ae0b3ad` + 4 link-2 commits). The branch
  did **not** exist when link 2 started — check knk-plugin's branch the same way (`git ls-remote origin
  claude/kind-dijkstra-y9d279`); if missing, create it from `origin/main` and record it as `L3-n`.
- knk-plugin: trunk `main` moved since the chain start (KNG-28 `db474e4`, KNG-29 `ee7824c` and the Codex session's
  Siege combat/command-completion work — check `docs/ACTIVE_SESSIONS.md` on workspace `main`). Merge `origin/main`
  first. No executed plugin baseline exists yet: you record the first one (charter §1.5).
- API test baseline after link 2: 1,839 tests, 1,777 passed, 5 known pre-existing failures (listed in the report),
  57 skipped. MySQL-gated: 57, 52 passed, 5 pre-existing `TeleportChargeMySqlTests` failures.
- Toolchain notes from link 2: `sudo apt-get update` before `sudo apt-get install -y dotnet-sdk-8.0` (the first install
  404'd without it). Build the API with `dotnet build knkwebapi_v2.csproj` (the `.sln` references `tests/` lower case).
  `sudo apt-get install -y mysql-server` works in the container: `sudo service mysql start`, create a user, then
  `KNK_TEST_MYSQL="Server=localhost;User=…;Password=…" dotnet test … --filter Category=requires-mysql`; also lets you
  run the API locally (`ConnectionStrings__MySqlDbConnection=…`, `Security__PluginApiKey=…`, `Telemetry__Enabled=false`)
  for a smoke test of the plugin's DTOs against the real endpoints.

**What link 3 must build** (plan §5.1, §5.2 link-3 rows, §5.3 `statistics.visibility` + `profile.main` slot 6, §8 "Link 3"):
- knk-api-client: `StatisticsApi` port + `StatisticsApiImpl extends BaseApiImpl`, DTOs/mapper mirroring
  knk-web-api `Dtos/StatisticsDtos.cs` (camelCase JSON; enums as names: `"Nobody"|"Friends"|"Everyone"`,
  `"Quit"|"ServerStop"|"Kick"`; session `type` `"start"|"end"`).
- knk-core: `StatisticsMetric`, `StatisticsContext`, `StatisticsBuffer`, `StatisticsBatch`, `StatisticsSpool`,
  `StatisticsRecorder`, `AfkTracker`, `MovementClassifier`, `FallRule` (pure, tested).
- knk-paper: `StatisticsService`, `StatisticsContextResolver`, session/AFK/movement/fall listeners, `AfkPresentation`,
  `/afk`, `StatisticsFlushTask`, `StatisticsVisibilityMenuFeature` (+ view), `/stats settings`; config `statistics:`.
- knk-web-api (small): `Models/Menu/MenuTemplateSeed.Statistics.cs` chained into `CanonicalTemplates()`, `profile.main`
  header slot 6 tile; regenerate the plugin's `content-seeds.json` mirror.

**API contract facts the plugin must respect (verified by link 2's tests and live smoke):**
- `POST api/statistics/batches` (`X-API-Key`): ≤ 2,000 entries in total; 200 with `{ batchId, duplicate, accepted,
  rejected: [{ section, index, code }] }`; **400 = final** (no batchId / too many entries); **503
  `StatisticsDisabled` = keep spooled**; 401/403 = key problem (spool). A replayed batch id answers `duplicate: true`
  (delete the spool file).
- Codes: `UnknownMetric, NotPluginWritable, InvalidContext, OutOfRange, TooOld, InFuture, UnknownSession,
  InvalidInterval, UnknownUser, InvalidEntry`. Rejections are final per entry (log, don't retry).
- Sections: `counters` only take sum metrics with `PluginInput=Counter` (not `pvp_kills`, not `logins`, not durations);
  `records` only `highest_killstreak` / `highest_fall`; `pvpKills` is the only way to send `pvp_kills`; `logins` is
  derived by the API from session `start` entries. `pvp_kills`/`deaths`/`highest_killstreak` in context `siege` are
  rejected (`NotPluginWritable`). Non-contextual metrics (distance.*, highest_fall) need `context: ""`.
- Durations: `active_playtime`/`afk_time`, `[from, to)` inside a session of the **same user** that the API knows (its
  `start` in the same or an earlier batch), `from ≥` session start, length ≤ 86,400 s, not older than 7 days, not more
  than 300 s in the future. Send the `start` before any duration of that session (same batch is fine).
- Values: counters > 0, records ≥ 0, `MaxPerEntry` per metric (durations 86,400; distances/damage 100,000; counts
  10,000) — split larger accumulations over entries.
- `GET api/statistics/catalog` (anonymous): `{ timeZone, contexts, metrics, settings, groups }` — groups are
  `activity, combat, minigames, exploration, progression` with their `settingKeys` (the menu's five groups).
- `GET/PUT api/statistics/users/{id}/visibility` with `X-Acting-User-Id: <the player>` (without it: 401; another
  player: 403). PUT body `{ changes: [{ settingKey, context: "", expected, visibility }] }` (≤ 64, atomic). 409 body:
  `{ error: "VisibilityConflict", message, current: <StatisticsVisibilityDto> }` — refresh the menu from `current`.
  `settings[].contexts[]` lists overrides and contexts with data (`isOverride`); `friendsAvailable: false`.
- Reads (`GET api/statistics/users/{id}` etc.) are for link 5; pass `X-Acting-User-Id` = the viewing player.

**Open flags that affect this link:** L1-1 (AFK rule), L1-2 (salary unchanged), L1-11 (streak reset on quit —
link 4), L1-13 (movement segments), L1-15 (first join: the API takes the earliest session start), L2-2 (codes),
L2-10 (a late duration reopens an API-timed-out session — so flush accrued time even after a long API outage).

**Known risks:** Siege/menu files under concurrent change on plugin `main` (merge first, add new files/hooks); the
menu seed is create-only (live checklist: content-menu reset); keep `statistics.enabled: false` a true no-op (no
listener, task or command registered); no I/O on the main thread; tests follow the `knk-plugin/CLAUDE.md` World-mock
rule; knk-paper may be "not compiled" if the Maven hosts are blocked (charter §1.4 — not a blocker).

**Next after you:** link 4 — combat, gates and Siege reconciliation (knk-plugin; API tests).
