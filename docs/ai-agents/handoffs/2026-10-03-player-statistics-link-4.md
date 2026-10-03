# Player statistics chain — link 4 handoff

**Date:** 2026-10-03 · **Written by:** link 3 (`session_013GjXWw1R62Nzv6Tjoodejy`) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md first (branch claude/kind-dijkstra-y9d279) and follow it;
it overrides anything below.

Implement **link 4 — Combat, gates and Siege reconciliation** end to end (code, tests, commits, push to
claude/kind-dijkstra-y9d279, progress report, handoff) as link 4 of the chain.

**State you start from.**
- knk-workspace `claude/kind-dijkstra-y9d279`: plan `docs/specs/player-statistics/IMPLEMENTATION_PLAN.md` (binding; read
  the "Link 2 status" and new "Link 3 status" notes at the end), DESIGN.md §F.6-§F.8, progress report with the Link 3
  block (decisions L3-1 … L3-15).
- knk-plugin `claude/kind-dijkstra-y9d279` head `e75d9b7` (= `main` `ee7824c` + 6 link-3 commits; the branch did not
  exist before link 3). Gradle baseline after link 3, all green: knk-core **1,242**, knk-api-client **152** (2 skipped),
  knk-paper **1,011** (14 skipped). The Maven hosts (papermc, enginehub) were reachable, so knk-paper compiles in the
  cloud; first build ~3 min, then use `--offline`.
- knk-web-api `claude/kind-dijkstra-y9d279` head `c95572a` (= `master` `ae0b3ad` + link 2 + the link-3 menu seed).
  Baseline: 1,845 tests, 1,783 passed, the same 5 known pre-existing failures (listed in the report), 57 skipped.
- Trunks: check `docs/ACTIVE_SESSIONS.md` on workspace `main` and `git fetch` every repo first — knk-plugin `main` was
  still `ee7824c` at the end of link 3, but other sessions push Siege/command work there.
- Toolchain notes: `sudo apt-get update` then `sudo apt-get install -y dotnet-sdk-8.0 mysql-server` (both work);
  build the API with `dotnet build knkwebapi_v2.csproj`; `dotnet tool install --global dotnet-ef --version 8.*` +
  `dotnet ef database update` on a local MySQL DB, then `dotnet run --no-build` (it listens on `http://localhost:5294`
  from launchSettings) with `ConnectionStrings__MySqlDbConnection=…`, `Security__PluginApiKey=…`,
  `Telemetry__Enabled=false`; create users with `POST api/Users` + `X-API-Key` + a `uuid`. Link 3 smoke-tested the
  plugin client this way with a throwaway JUnit test in knk-api-client (deleted afterwards). Don't `pkill -f` a pattern
  that also matches your own shell command.

**What link 3 left for you to wire (plugin):**
- `KnKPlugin#getStatisticsService()` → `net.knightsandkings.knk.paper.statistics.StatisticsService` (null when
  `statistics.enabled: false` — then register nothing, like `startStatistics()` does).
  - `addCounter(Player, StatisticsMetric, double)` — summed per minute in the player's current context
    (`StatisticsContextResolver`: `siege` while in a running match, else `open_world`; non-contextual metrics are stored
    with `""` automatically).
  - `addRecord(Player, StatisticsMetric, double)` — e.g. `HIGHEST_KILLSTREAK` (open world only; Siege streaks are
    projected by the API).
  - `pvpKill(Player killer, Player victim)` — the killer/victim pair in the killer's context; returns false when a user id
    is unknown. **Skip running-match members** (§F.6): the API rejects `pvp_kills`/`deaths`/`highest_killstreak` in
    context `siege` with `NotPluginWritable` (verified live by link 3).
  - Offline credit (a fire igniter who logged off, §F.8): `service.buffer().addCounter(userId, metric, context, value, at)`
    with the user id stored at ignition — the session-based methods drop facts of players without a session.
  - `excluded(Player)` (game-mode exclusion), `isAfk(UUID)`, `contextOf(Player)`, `now()`.
- `StatisticsMetric` already has every link-4 key (`PVE_KILLS`, `DEATHS`, `DEATHS_BY_CAUSE_*`, `DAMAGE_DEALT_*`,
  `DAMAGE_RECEIVED_*`, `ARROWS_FIRED`, `HEADSHOTS`, `HIGHEST_KILLSTREAK`, `GATE_DAMAGE`, `PVP_KILLS`) with the API's
  `MaxPerEntry`; the buffer splits larger sums.
- Config: add `combat`, `gates`, `siege` records to `KnkConfig.StatisticsConfig` (its canonical constructor normalizes
  nulls; keep `defaults()`), `ConfigLoader.loadStatistics` keys per plan §5.1, the `statistics:` block in `config.yml`,
  and extend `ConfigLoaderStatisticsTest`. Every hook needs its switch (`statistics.combat.enabled`,
  `statistics.gates.enabled`/`fire-attribution`, `statistics.siege.report-departed-members`).
- Register listeners inside `KnKPlugin.startStatistics()` (after the existing ones).

**Phase-specific reading:** plan §5.1 (combat/gates/siege config), §5.2 link-4 rows and edits, §8 "Link 4" (acceptance
criteria 1-6 and the test list), §9 risks; DESIGN.md §F.6 (match results, leavers), §F.7 (combat attribution, killstreak
L1-11), §F.8 (gate damage incl. fire attribution); source audit sections on `SiegeService`, `HealthSystem`,
`GateFireSystem`, `GateDamageConsequenceListener`, `SiegeCombatListener`, `CombatTagListener`.

**Open flags that affect this link:** L1-9 (damage cap, `CUSTOM` excluded), L1-10 (PvE spawn-reason exclusions),
L1-11 (streak resets on quit), L1-12 (gate damage = effective loss), L2-2 (rejection codes), L2-13 (several participant
rows of one user count once; any early leave → loss), L3-3 (facts of players with an unknown user id are held in
memory), L3-14 (per-minute aggregation).

**Known risks:** Siege/gate files under concurrent change on plugin `main` (merge first; keep edits to `SiegeService`,
`HealthSystem`, `GateFireSystem`, `GateDamageConsequenceListener` minimal and isolated; recompute headshots in a new
listener rather than editing `SiegeCombatListener`); gate HP outcomes must stay byte-for-byte identical (compare HP
sequences with the sink on and off); the Siege completion payload change (departed members) needs the API tests listed
in plan §8; tests follow the `knk-plugin/CLAUDE.md` World-mock rule; damage events can't be constructed in unit tests
(the damage-type registry needs a server) — mock `EntityDamageEvent`/`EntityDamageByEntityEvent` as link 3's
`StatisticsListenersTest` does.

**Next after you:** link 5 — read surfaces + leaderboards (knk-web-api, knk-plugin, knk-web-app).
