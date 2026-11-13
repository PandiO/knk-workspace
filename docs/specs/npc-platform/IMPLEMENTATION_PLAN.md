# NPC navigation adapter (Citizens) — Implementation Plan

**Status:** In progress since 2026-11-13 (Phase 1, developer go-ahead; parent issue [#358](https://github.com/PandiO/knk-workspace/issues/358)). Proposed 2026-11-11. Plans the shared NPC navigation capability only (K&K plans, Citizens moves); behavior, guards, garrisons and combat are separate work. Developer answers to Q1–Q7 on 2026-11-12; see "Decisions".
**Last updated:** 2026-11-13 (Phase 3 built on `claude/npc-navigation`, sub-issue #361: status, known limits, developer test); 2026-11-13 (Phase 2 built on `claude/npc-navigation`, sub-issue #360: status, what differs from the spike, developer test); 2026-11-13 (implementation started: parent issue #358, stair release gate, Phase 1 breakdown with the NPC event audit, CitizensAPI pin, coexistence with the Siege Survival NPC core); 2026-11-12 (Phase 0 done, Q8 decided, NAV-17 in Phase 2, NAV-18 walked lines in Phase 7); 2026-11-12 (Phase 0 route-following spike, metrics and config layering in Phase 1, NAV-14/15/16, Q8; Q4 formations decided; Phase 7b travel bubble first; Phase 7b abstract movement outside loaded areas, spread spawns and targeted replans, from the unloaded-chunk runs; developer answers Q1–Q7; road network components and the router's BLOCKED result from the unloaded-chunk test)
**Issue:** implementation [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358) (one sub-issue per phase); verification [#241](https://github.com/PandiO/knk-workspace/issues/241) ( desk check #242, spike #243, benchmark #244); parent [KNG-36](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform), [#146](https://github.com/PandiO/knk-workspace/issues/146), [#234](https://github.com/PandiO/knk-workspace/issues/234)
**Sources:** [BEHAVIOR_MODEL.md §2](BEHAVIOR_MODEL.md#2-fit-with-the-platform-design) (requirements NAV-01–NAV-11) and §13; [DESIGN.md](DESIGN.md) §2, §6, §7, §9; [desk check and spike report](../../reports/2026-11-10-citizens-desk-check-and-spike.md); [Citizens stress test guide](../../guides/citizens-stress-test.md); [verdict on #244](https://github.com/PandiO/knk-workspace/issues/244#issuecomment-6806008046); code read at knk-plugin `main` `33122cf` and `121030fe` (2026-11-13), the spike `claude/citizens-spike` `ac3c356`…`4060870`, and the Siege Survival branch `claude/siege-survival` `f6db7a36` (NPC core).

**Branches:** one standing branch per repo, `claude/npc-navigation`, created only when a phase first touches that repo (knk-plugin from `main`; knk-web-api from `master` and knk-web-app from `main` from Phase 5). Claim the work in `ACTIVE_SESSIONS.md` first. The spike branch `claude/citizens-spike` is **never merged**: port its pieces with tests, don't cherry-pick.

**Build notes:** `./gradlew build -x deployToDevServer` in knk-plugin (plain `build` deploys). Gradle runs on Java 21 and compiles with the Java 25 toolchain. CitizensAPI stays `compileOnly`, non-transitive, never shaded (OSL-3.0); Citizens is a `softdepend`, and the plugin must load and run without it (NPC navigation then reports "unavailable").

**Release gate: stairs (developer, 2026-11-12/13).** NPCs must not visibly jump in circles or stall on stairs; erratic jumping on easy stairs is unacceptable for production. Reference: the stair house on the `quarry-to-keep` route (two U-turn flights, 1408–1416, y 49–62, z −489…−503) and the staircase at 1399–1421, y 73–85. Gate: on that route, no NPC stalls in a staircase longer than one watchdog period (3 s), no visible jumping in circles, and stuck events per trip in the stair house well below the spike's (2026-11-12: 86 stuck in 67 trips, mostly the stair house). The gate is checked in Phase 8 and must pass before guards ship; stair quality is tested alongside implementation from Phase 2 on.

**Next to the Siege Survival NPC core:** `claude/siege-survival` (not merged) has a Bukkit-free NPC core in `core/npc/` (stats, profiles, modifiers) and `paper/npc/` (mob goals, `NpcPlatform`). Navigation lives in its own subpackages, `core/npc/nav/…` and `paper/npc/citizens/…`, so the two merge without touching each other's files.

| Phase | Repos | Size | Depends on | Shippable alone | Requirements |
|---|---|---|---|---|---|
| 0 — Route-following spike | plugin (spike branch) | S | — | — (decides Q8) | NAV-15, NAV-12 |
| 1 — Runtime, guard rails and metrics | plugin | M | Q1, Q2 | yes (no gameplay) | NAV-08, NAV-10, NAV-16 |
| 2 — Navigate one NPC | plugin | L | 0, 1; Q3 | yes (admin command) | NAV-01, NAV-03, NAV-11, NAV-14, NAV-15, NAV-17 |
| 3 — Rules stay binding | plugin | M | 2 | yes | NAV-02, NAV-03, NAV-04 |
| 4 — Groups | plugin | M | 3; Q4 | yes | NAV-05 |
| 5 — NPC access identity | web-api, plugin, web-app | L | 2; Q5, DESIGN O06 | yes | NAV-09 |
| 6 — Detours and hidden routes | web-api, plugin, web-app | L | 3; hidden-routes issue (Q6) | yes | NAV-06 |
| 7 — Movement quality | plugin | M | 2 | yes | NAV-07, NAV-11, NAV-18 |
| 7b — Movement outside loaded areas | plugin | L | 3; BEHAVIOR_MODEL §13 level of detail | yes | NAV-12 |
| 8 — Benchmark gate | plugin (dev server) | S | 3, 4 (5–7 as built) | — | §13 budgets |

Phases 5, 6 and 7 are independent of each other and can run in any order after their dependencies. Guards (BEHAVIOR_MODEL §16) need at least Phases 1–5.

---

## Phase 0 — Route-following spike (spike branch)

Goal: prove how NPCs follow the K&K route as the trail draws it (NAV-15) before Phase 2 builds on it, and measure the travel bubble (NAV-12).

- Spike mode `trail`: the road polyline (and the K&K walk legs at the ends) resampled every 1–2 blocks, floor-snapped, handed to Citizens one stretch at a time (about 32 blocks) as a waypoint list; the next stretch is prepared before the NPC reaches the end of the current one (NAV-14). On stuck: one Citizens A* leg to the next waypoint, then back on the line.
- Compare with hop mode on the same routes: stuck per trip, time per trip, how far NPCs stray from the road centre, tick cost. If Citizens' waypoint following can't do stairs and steps well, try a K&K-driven step controller (Citizens only moves the body).
- Spike setting `keeploaded on|off` for the travel bubble: chunks held per NPC, tick cost, memory, whether NPCs keep moving at chunk borders.

**Status:** built on the spike branch, `9027991` and later (2026-11-12): `spawn <n> trail`, `set keeploaded on|off`, `set stretch N`, stray-from-road metric; test steps in the [stress test guide](../../guides/citizens-stress-test.md#phase-0-trail-mode-and-the-travel-bubble-next-session). **Done 2026-11-12** (spike up to `e09afb2`): Q8 decided (see Decisions); results in the [stress test guide](../../guides/citizens-stress-test.md) and [#244](https://github.com/PandiO/knk-workspace/issues/244). Spike additions found on the way: K&K progress watchdog (NAV-17), floor continuity between waypoints, run log files.

**Done when:** Q8 is answered with numbers.

## Phase 1 — Runtime, guard rails and metrics (plugin)

Goal: Citizens is wired in safely, NPCs can exist without touching player systems, and NPC navigation is measurable from the start. No route following yet (Phase 2).

Sub-issue: [#359](https://github.com/PandiO/knk-workspace/issues/359). Branch: knk-plugin `claude/npc-navigation` from `main` `121030fe`.

**1.1 Dependency and runtime** (knk-paper `paper/npc/citizens/`)
- CitizensAPI `2.0.44-20261020.020503-8` (`citizensApiVersion` in `gradle.properties`; the newest build for 26.3 on 2026-11-13, Q7), `compileOnly`, non-transitive, never shaded; repository `maven.citizensnpcs.co/repo`; Citizens as `softdepend` in `plugin.yml`.
- `CitizensNpcRuntime`: created only when Citizens is enabled and `npc.navigation.enabled`; in-memory registry (`createInMemoryNPCRegistry`, `SHOULD_SAVE = false`), removed on disable. Per-NPC defaults (NAV-10): pathfinder from config (`CITIZENS`), `destinationTeleportMargin(-1)`, a K&K stuck action that never teleports, stationary ticks, `pathDistanceMargin(1.5)`, `PATHFINDER_OPEN_DOORS = false`, `COLLIDABLE` from config. The only class that names Citizens types besides the mover.
- `CitizensNpcMover` implements the knk-core `NpcMover` port.
- Startup line: `NPC navigation: Citizens <version>` or `NPC navigation unavailable: <reason>` (no Citizens, disabled in config).

**1.2 Engine-neutral core** (knk-core `core/npc/nav/`, Bukkit-free, per Q1)
- `NpcMover` port: spawn and despawn, follow a waypoint list, walk to a point (local search), cancel, position, on-ground, "is moving", listeners for arrived / cancelled / despawned. Positions as plain records, no engine types.
- `NavigationResult` (ARRIVED, BLOCKED with reason and blocking element, FAILED with reason, CANCELLED) and `NpcNavState` (IDLE, QUEUED, PLANNING, MOVING, WAITING, PAUSED) for DESIGN §6's failure policy and the metrics.
- `NavigationSettings` with **layered overrides**: global default → world → region/domain → NPC template → assignment (BEHAVIOR_MODEL §15.3), each layer sparse; resolution returns the value and the layer it came from (for diagnostics). First settings: pathfinder, max plans in flight, stretch blocks, recheck ticks, stationary ticks, no-progress ticks, collidable, and the chunk-loading switch (NAV-12; read now, used in Phase 7b).

**1.3 NPCs out of player systems (NAV-08): measure, then guard**
- `NpcEntities.isNpc(Entity)` (`hasMetadata("NPC")`), the one check every guard uses.
- **NPC event audit** (`/knk npc audit start|stop|report`): while on, a monitor on every registered event type counts events whose player or entity is an NPC, by event type, and writes the report to `plugins/KnightsAndKings/npc-logs/`. Run with test NPCs walking a route (1.5), then guard exactly the listeners that react to the event types it finds, with a test each. Expected from the spike: the region tracking behind `listeners/WorldGuardRegionListener` (10 region lookups per second for 200 NPCs). 79 listener files react to player events on `main`; most likely never see an NPC, which the audit confirms instead of guessing. Combat events (damage, death, combat tag, statistics) are guarded when NPCs fight (later work); the audit lists them now.
- Related: #317 (no negative cache for regions without a domain) makes every lookup cost an API call; not fixed here, but the guard removes the NPC share.

**1.4 Metrics foundation (NAV-16)** (knk-core `core/npc/nav/NpcNavigationMetrics`, a `MetricsCollector` registered by `MetricsService`)
- Gauges: NPCs by state and world; chunks held for NPCs (Phase 7b fills it).
- Counters: arrivals, stuck (by kind: Citizens stuck, no progress), recoveries, retries used up, trespasses, replans (by cause).
- Histograms: route plan time (road graph), local plan time, queue wait, main-thread time spent on NPC navigation per tick.
- Names `knk_npc_nav_*`; a Grafana panel row next to the existing performance dashboard, with a section in `guides/performance-metrics-and-capacity.md`.

**1.5 Test command** (admin, `knk.admin.npc`): `/knk npc test spawn <n> [radius]` (player-shaped NPCs that walk to random points nearby with Citizens' own pathfinding, enough to exercise events and metrics), `/knk npc test clear`, `/knk npc status` (runtime, NPC counts by state, settings with their layer). Not a gameplay feature; Phase 2 replaces the walking with route following.

**1.6 Config** `npc.navigation.*` in `config.yml`: `enabled` (default false), the global layer of the settings above, `worlds.<world>.*` and `regions.<domain or region id>.*` override sections. Template and assignment layers come from code until templates exist.

**Tests:** settings layering and precedence; `NpcNavigationMetrics` output; runtime absent without Citizens (plugin loads, status says unavailable); one test per guarded listener (an NPC event does not reach it); the audit counts NPC events and ignores player events.

**Status (2026-11-13):** built on knk-plugin `claude/npc-navigation` `8b36a942` (core `83d2bba8`); full suite green (core 2507, api-client 324, paper 2535). The listener guard so far: `WorldGuardRegionListener` (the known one); the audit run decides the rest. The Grafana row is the PromQL table in `guides/performance-metrics-and-capacity.md` § 4.2. Not yet run on a server.

**Developer test (Phase 1):**
1. Deploy `claude/npc-navigation`; in `config.yml` set `npc.navigation.enabled: true` (and `metrics.enabled: true` to see `/metrics`). Startup log: `[NPC] navigation: Citizens 2.0.44-SNAPSHOT (build 4269), override scopes {…}`. Without Citizens, or disabled: `[NPC] navigation unavailable: <reason>`.
2. `/knk npc status`: running, and every setting with its layer (`default`, `global`, `world …`, `region …`). Optional: add a `regions.<region id>.recheck-ticks: 20` override, restart, stand in that region: status shows `20 (region <id>)`.
3. `/knk npc audit start`, then `/knk npc test spawn 50 24` somewhere with regions (inside a town), let them walk 5 minutes, then `/knk npc audit report`. The report (also in `plugins/KnightsAndKings/npc-logs/`) lists each event type NPCs triggered and which K&K listeners received it. Expected: `WorldGuardRegionListener` listed for `PlayerMoveEvent` but no `[KnK Resolver] resolveRegionsFromApi` flood in the server log (the guard).
4. With metrics on: `curl <metrics address>/metrics | grep knk_npc_nav` shows `knk_npc_nav_npcs{world,state}` and the event counters.
5. `/knk npc test clear`; restart without Citizens (or `enabled: false`): plugin loads, status says why it's off.

Send the audit report file; the listeners it names get guards (with tests) before Phase 1 closes.

**Done when:** the plugin loads with and without Citizens; `/knk npc test spawn 50` NPCs walking about for 5 minutes make no region API calls and no player-system side effects (audit report clean after the guards); `/metrics` shows the `knk_npc_nav_*` series; settings show the layer they came from.

## Phase 2 — Navigate one NPC (plugin)

Goal: one NPC walks a K&K-planned route under a caller-supplied ruleset (DESIGN §6), hop by hop.

**knk-core:**
- `AccessSubject` port: what the access code needs from a mover (identity, bypass, permissions/gate rights, current regions). `NavigationAccess.policyFor`, `WalkAccessFactory` and `GateAvailability` take a `Player` today; add overloads that take an `AccessSubject`, with a `PlayerAccessSubject` adapter so player navigation is unchanged. Until Phase 5, NPCs use a **configured access profile** (template-level allow/deny lists; Q3), never a borrowed player.
- `RouteFollower` (NAV-14, NAV-15): the K&K route (road polyline plus walk legs) as the line to follow, prepared one stretch ahead at a time; executed the way Phase 0 decides (Q8). `HopPlanner` (road route → hops every N blocks, floor-snapped; spike `resample` / `snapToFloor`) stays for Citizens' A* recovery legs. The road route itself is planned on the road graph without chunks; capture and local search only for the stretch ahead.
- `NpcNavigationService`: per-NPC state machine (IDLE → QUEUED → PLANNING → MOVING → WAITING / PAUSED), a planning queue with a limit on plans in flight, bounded retries per hop (DESIGN §6: 3), and a `NavigationResult` back to the caller.

**knk-paper:**
- `KnkBlockExaminer`: the composite examiner (port `SpikeExaminer`): the K&K `CellAccess` first (NOT_STANDABLE / IMPASSABLE), then Citizens' `MinecraftBlockExaminer` and `DoorExaminer` (only when the ruleset allows doors), cells outside the capture box blocked; check and strip foreign examiners after each `setTarget`.
- Road planning through the existing router (`AStarRouter`) with the NPC's position for the exit rules (port the spike's `spikeRoadPolyline` as a proper API on `NavigationService` or a new `NpcRoutePlanner`).
- **No route → WAITING** (NAV-03), but only when the rules are why: the router's `BLOCKED` (a usable route exists without the current rules) and `NO_ROUTE`. `DIFFERENT_COMPONENTS` (start and goal on road networks that don't connect) is not a rule block and never clears by waiting: report `FAILED("no road connects")` to the caller. The spike waited on it and its unloaded-chunk test never started (2026-11-12). Never a straight-line fallback across terrain. An end too far from a road → walk-only leg, short hops.
- Chunk unload → PAUSED, respawn → replan (NAV-11). A hop whose capture box reaches an unloaded chunk → WAITING at the edge until Phase 7b (NAV-12); never load chunks for a capture.
- Spawns spread over ticks: a fixed number per tick (NAV-13; 20 at once gave a 48.8 ms tick).
- Admin command `/knk npc nav <spawn|goto|stats|clear>` for testing, replacing `/knk npcspike` (from/to, stored routes and stats as in the spike).

**Tests:** `HopPlanner` (spacing, stairs, end snapping); state machine (retry budget, waiting, pause/resume) against a fake `NpcMover`; examiner ordering (a K&K veto beats a later PASSABLE); `PlayerAccessSubject` gives the same verdicts as today.

**Done when:** on the dev server, one NPC and then 50 walk the stored `south-gate` route back and forth with the spike's numbers or better (about 0.03 ms per NPC, no examiner leaks).

Sub-issue: [#360](https://github.com/PandiO/knk-workspace/issues/360). Branch: knk-plugin `claude/npc-navigation` (continues Phase 1).

**Status (2026-11-13):** built on knk-plugin `claude/npc-navigation`; full suite green (core 2562, api-client 324, paper 2570; 55 and 35 new tests). Not yet run on a server. Everything stays off while `npc.navigation.enabled` is false; route following is built on the first `/knk npc nav` use.

1. **knk-core `core/npc/nav/`:** `AccessSubject` (port), `NpcAccessProfile` and `NpcAccessSubject` (the configured profile, Q3), `SubjectRegionAvailability` (a subject's deny list on the road graph), `RouteFollower`, `HopPlanner`, `NpcNavigationService`, `NpcSpawnQueue`, and the ports `RoadPlanner`, `LocalLegPreparer`, `LocalLeg`, `NavWorld`. `NpcMover` got `walkTo(target, leg)` for local legs under K&K's rules.
2. **knk-paper:** `PlayerAccessSubject` and the `AccessSubject` overloads on `NavigationAccess.policyFor` / `gateAvailability`, `WalkAccessFactory.prepare` and `WalkLegPreparer.capture` (the `Player` versions are unchanged); `NavigationService.planRoadFor` (the road route with the subject's policy, through `AStarRouter.routeOrExplain`, so BLOCKED names the blocking element); `paper/npc/citizens/KnkBlockExaminer`; `paper/npc/nav/` `NpcLegPreparer`, `BukkitNavWorld`, `NpcNavRunner`, `NpcRouteStore`, `NpcNavLog`.
3. **How an order runs:** short trip (within `hop-blocks`) → one local leg. Otherwise the road route is planned on the road graph (no chunks); the NPC walks an off-road leg to the road if it starts more than 3 blocks from it, follows the road line in stretches of `stretch-blocks` (the next one handed over within 4 blocks of the end of the current one), and walks an off-road leg from the road's end to the goal. The watchdog looks every 20 ticks at how far along the line the NPC is; no progress for `no-progress-ticks` → one local leg to a point 4 line points ahead, then back on the line.
4. **Failure policy:** `max-retries` (3) recovery attempts per hop or stretch; then the route is dropped and planned again from where the NPC stands, at most twice per order; then the order ends as `FAILED` and the caller decides. `BLOCKED` and `NO_ROUTE` → `WAITING`, asked again every `no-route-wait-ticks` (100), the caller hears `Blocked` once. `DIFFERENT_COMPONENTS` → `FAILED("no road connects")`. An end too far from a road, or no road network: a walk-only trip in hops when it is at most `walk-only-blocks` (64) long, else `FAILED`. A stretch or a capture box that reaches an unloaded chunk → `WAITING` at the edge, never a failure, never a chunk load.
5. **Access profiles** (`npc.navigation.access-profiles.<id>`): `bypass-domain-rules`, `open-doors`, `allow-regions`, `deny-regions`. An NPC is judged from the regions it stands in, is never a siege lockdown member and passes open gates only (pass-through for NPCs is Q5).
6. **Not ported from the spike**, on purpose: the `dense` and `hop` modes (Q8 decided trail), `set <key>` at runtime (the keys are in `config.yml` with their layers), `set subject` (profiles instead), `keeploaded` (Phase 7b), the CSV row, and `dump` (the block dump around a spot; the spike build can still make one). The recheck of the way ahead, event replans, the walk to the blocking element and the trespass counter are Phase 3: until then a rule that changes while an NPC walks is only noticed at its next plan.

**Developer test (Phase 2):**
1. Deploy the build. In `config.yml`: `npc.navigation.enabled: true`, `metrics.enabled: true`, and merge the new keys (`spawns-per-tick`, `hop-blocks`, `max-retries`, `no-route-wait-ticks`, `walk-only-blocks`, `access-profiles`; the YAML is in the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc)). Road navigation and walk paths must be on (`navigation.enabled`, `navigation.walk.enabled`, both default true). `/knk npc status` lists the new keys with their layer, `spawns per tick 2` and `access profiles [default]`.
2. **Routes.** The first `/knk npc nav …` takes the spike's stored routes over (`npcspike-routes.yml` → `npc-routes.yml`, logged once). `/knk npc nav route list` should show `south-gate` and `quarry-to-keep`; otherwise stand at each end and use `/knk npc nav from`, `/knk npc nav to`, `/knk npc nav route save <name>`.
3. **One NPC.** With no NPCs out, wait a minute, then `/knk npc nav baseline`. `/knk npc nav route load south-gate`, `/knk npc nav spawn 1`. Look: it walks down the middle of the road, rests a second at the end and walks back. After a few trips `/knk npc nav stats`: `trips` rising, `stuck: engine 0, no progress 0` on the open road, `engine block rules removed 0`, `failures: none`.
4. **50 NPCs.** `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`. They appear two per tick (25 ticks), not at once: `tick … p95` should show no spike (the spike branch spawned 20 at once for a 48.8 ms tick). Let them walk 6 minutes, then `/knk npc nav stats`. Compare with the spike (`trail-50`, 2026-11-12): 0.014–0.020 ms per NPC (hop mode 0.035; the "Done when" is about 0.03), 0 examiner leaks, 0% of samples more than 2 blocks from the road line.
    1. `tick: … -> N ms per NPC`: at or below 0.03.
    2. `K&K navigation on the main thread: … (N ms per NPC)`: K&K's own share; expect a few µs per NPC.
    3. `engine block rules removed 0 (must be 0)`.
    4. `distance from the road line: … over 2 blocks 0.0%`.
    5. `orders failed 0`, `retries used up 0`, and `planning queue 0` once they all walk.
5. **Stair house** (the release gate at the top of this plan). `/knk npc nav clear`, `/knk npc nav route load quarry-to-keep`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`, 10 minutes, both directions. Stand in the stair house (two U-turn flights, 1408–1416, y 49–62, z −489…−503) and at the upper staircase (1399–1421, y 73–85) and look for:
    1. No NPC standing still in a flight for longer than 3 seconds (one watchdog period).
    2. No jumping in circles on a step or a landing.
    3. At the U-turn, no NPC that hops to the flight above or below it (floor continuity) or turns back down.
    4. A recovery: the NPC leaves the line for a few blocks and joins it again; it should not repeat on the same spot.
    5. `/knk npc nav stats`: `stuck: … no progress N` against `trips`: the spike had 86 stuck in 67 trips (1.3 per trip), all recovered. Expect the same or fewer, `recovered` equal to the stuck count, `retries used up 0`, `orders failed 0`.
    6. `plugins/KnightsAndKings/npc-logs/<time>_npc-nav.log` has every stuck event with its position. Positions that repeat are the hard spots (the spike's: 1410–1414 49–50 −500…−503 and 1413–1415 69–71 −545…−549).
    7. Stand at the U-turn and run `/knk npc nav trace 60`: the nearest NPC is traced every tick for 60 s into `npc-logs/<time>_trace_<npc>.log` (`JUMP` marks a jump). Post the log and one or two trace files on [#360](https://github.com/PandiO/knk-workspace/issues/360).
6. **Rules at planning time.** Add an access profile with a district on its deny list, restart, and spawn a few NPCs with it on a route through that district (`/knk npc nav spawn 5 outsider`): they wait (`waits: no allowed route`, `failures: {blocked: …}`), none enters. Close a gate on the route before spawning: the NPCs wait; open it: they start within 5 seconds. A gate that closes or a rule that changes **while** they walk is Phase 3 (stress test guide tests A and B, the trespass counter); skip it here.
7. **No road connects.** Put `to` on a road network that does not join the start's: `failures: {failed: no road connects …}`, the NPCs stay idle and the test driver asks again every 5 seconds only.
8. **Chunk unload** (test C). Walk along with the NPCs, then teleport far away and come back after a minute: `chunk-unload pauses N, resumes N` with equal numbers, and the NPCs walk on. NPCs at the edge of the loaded area wait (`way ahead not loaded`) and do not fail.
9. `/knk npc nav goto` (every NPC walks to you once), `/knk npc nav patrol` (back on the route).
10. **Off.** `npc.navigation.enabled: false` and restart: `/knk npc nav spawn 1` answers `NPC navigation unavailable: npc.navigation.enabled is false`; the same without Citizens.
11. With metrics on: `curl <metrics address>/metrics | grep knk_npc_nav_events_total` shows `stretch`, `unloaded_wait`, `examiner_leak` (0) and `failed` next to the Phase 1 events.

Post the `stats` output of steps 3, 4 and 5 (they are also in the run log) on #360.

## Phase 3 — Rules stay binding (plugin)

Goal: a route planned under old rules is never walked under new ones (NAV-02), and blocked NPCs wait cheaply in the right place (NAV-03, NAV-04).

- **Recheck** every 40 ticks: the way ahead (the rest of Citizens' path, then the hops) against the current rules from the NPC's regions; a denied region or a closed gate ahead → replan (port the spike's `deniedAhead`). Time-sliced: a fixed number of NPCs per tick, never all at once.
- **Events:** `NavigationService.onGateChanged` and `onAvailabilityChanged` (and permission changes for the NPC's subject from Phase 5) notify the NPC service through a listener port, not the spike's ad-hoc hook. Replan only NPCs whose route crosses what changed (the gate, the domain): the periodic availability refresh replanned every spike NPC every 3–5 minutes for nothing (NAV-13). Replans go through the planning queue.
- **Partial route to the blocking element:** the router already returns it: `RouteResult.Status.BLOCKED` carries the route "to the last reachable point" and an explanation naming the blocked element (`BlockedExplainer`); player navigation uses it (`NavigationSession`). Walk that partial route, then WAITING with the blocking element. (The spike treated `BLOCKED` like no route, so its NPCs stopped in their tracks.) The blocking element's open event wakes the NPC (no polling); a slow safety timer (5 s) as a fallback.
- **Trespass guard** as a runtime assertion and metric (port the spike's `checkTrespass`): an NPC in a region its current rules deny is logged and counted; in dev builds also stopped and replanned.
- `NavigationResult.BLOCKED` carries the blocking element, so behavior (BEHAVIOR_MODEL §8, §17 gate confrontation) decides what to do.

**Tests:** recheck finds a newly denied region ahead and ignores regions behind; a gate event replans only NPCs whose route uses that gate; blocked → walks to the gate → waits → resumes on open; trespass counter on a fake world.

**Done when:** the stress test guide's tests A and B pass on the dev server with the production code: 0 trespasses, NPCs waiting **at** the gate or district edge, waiting cost ≤ 0.02 ms per NPC.

Sub-issue: [#361](https://github.com/PandiO/knk-workspace/issues/361). Branch: knk-plugin `claude/npc-navigation` (continues Phase 2). Requirements: NAV-02, NAV-03, NAV-04, NAV-13.

**Status (2026-11-13):** built on knk-plugin `claude/npc-navigation`; full suite green (core 2583, api-client 324, paper 2581; 21 and 11 new tests). Not yet run on a server. Everything stays off while `npc.navigation.enabled` is false: the listener on road navigation is only added when route following is built (the first `/knk npc nav` use).

1. **Ports (knk-core `core/npc/nav/`):** `AccessRules` (the rules as they are now: the entry rule per region for a subject, and whether a gate door stops it), `RuleChangeListener` (the listener port: a gate changed, availability changed), `BlockingElement` (kind gate, domain, road or unknown; id; name; the gate doors and regions of the blocked road stretch). `RoadPlanner.RoadPlan` now carries the blocking element, the gate doors on the route with where each one's stretch ends, and a check "does the blocking element still block this subject?". `NpcMover.pathAhead()` gives the rest of the engine's path for a local leg.
2. **Paper:** `NavigationAccess.mayEnter(AccessSubject)`, `gateBlocks` and `edgeBlocked` (the same rule code as the router's policy, from caches, main thread); `NavigationService.accessRules()` and `addRuleChangeListener` (called at the top of `onGateChanged` and `onAvailabilityChanged`; player navigation itself is unchanged); `CitizensNpcMover.pathAhead`. `KnKPlugin` and the listeners are untouched.
3. **Rule checks, a few NPCs per tick** (`rule-checks-per-tick`, default 10; NPCs an event concerns first, then round robin): every `recheck-ticks` a walking NPC gets (a) the trespass guard and (b) the recheck of the way ahead: the rest of the engine's path on a local leg, the hops, the route line for the next 96 blocks, the tail, and every gate the route still has to pass, against the current rules judged from the regions the NPC stands in. Something denied ahead → the NPC stops, the route is dropped and planned again through the planning queue (`replan_recheck`).
4. **Events:** a gate event marks only the NPCs whose route passes that gate, the NPCs blocked by it, and the NPCs waiting at another blocking element (the gate may open another way). An availability event (no element is named: the domain cache was refreshed, a siege lockdown changed) marks every NPC with an order for an early rule check; nobody plans again for the event alone. Marked NPCs are looked at in the same time slice; only those with something denied ahead, or whose blocking element opened, plan again (`replan_event`).
5. **BLOCKED:** the caller hears `NavigationResult.Blocked` with the `BlockingElement` once (again when another element blocks). The NPC walks the router's partial route (`blocked_walk`), cut before the first point in a region it may not enter, and waits there. A gate or availability event wakes it when its element no longer blocks, or when another gate opened (`woken`); `no-route-wait-ticks` (5 s) is the fallback, and an NPC already at the element stays where it is. `NO_ROUTE` (no route even without the rules) still waits on the timer only.
6. **Trespass guard:** at every rule check, a region the NPC stands in now and did not stand in at its last check was entered; an entry the current rules deny (judged from the regions it came from) is logged (`TRESPASS <npc> entered <region> at x y z`) and counted (`trespass`, must stay 0). `stop-on-trespass: true` (dev servers) also stops the NPC and plans its route again. With `recheck-ticks: 0` the guard still looks every 40 ticks.
7. **When the recheck and the router disagree** (the recheck sees a denied region ahead, the router still routes that way: an edge with a free lane, for example): the router is the authority, the element is not asked about again for that order until the next gate or availability event, a log line says so, and the trespass guard keeps watching.
8. **Known limits:**
    1. The partial route ends at the last road node before the blocked stretch (earlier at a denied region's edge). At a gate on a long stretch the NPC can wait some blocks before the gate; the developer test looks at it.
    2. The recheck asks the entry rule and the gates. A domain that forbids leaving is judged when the route is planned, as in the spike.
    3. A gate that closes during an off-road leg is not rechecked (regions on the engine's path are): the gate's blocks stop the NPC and the stuck handling plans again.
    4. A road network rebuilt while NPCs walk is not an event for them yet; they notice at their next plan.

**Developer test (Phase 3):**
1. Deploy the build. In `config.yml`: `npc.navigation.enabled: true`, `metrics.enabled: true`, and merge the new keys `rule-checks-per-tick: 10` and `stop-on-trespass: true` (true for this test; the YAML is in the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc)). `/knk npc status` shows `rule checks per tick 10` and `stop-on-trespass = true (global)`. Use the default access profile (it follows the domains' rules); the routes `south-gate` and `keep-gate` are the stress test guide's (`/knk npc nav route list`; save `keep-gate` again if it is missing: open road → just inside The Keep past the Keep Gate).
2. With no NPCs out, wait a minute, then `/knk npc nav baseline`.
3. **Gate run 1: the gate closes ahead of walking NPCs (test B).** `/knk npc nav route load keep-gate`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`. When several NPCs are on their way to the gate: `/gate close keep gate`. Look:
    1. NPCs between you and the gate keep walking **to** the gate and stand there (the spike's NPCs stopped where they were). NPCs further back do the same when they get there.
    2. Nobody is on the keep side of the closed gate; NPCs that were already through finish their trip and wait on the inside on their way back.
    3. The log (`npc-logs/<time>_npc-nav.log`, the first lines also on the console): `… way ahead is closed by gate <id> (event) …: route planned again` and `… blocked: … [gate <name> (<id>)]`.
    4. After 3 minutes `/knk npc nav stats`: `rules: trespasses 0 (must be 0)`, `replans: … event N` about the number of NPCs that were heading for the gate (not 50 for every event), `walked to the blocking element N`, `waiting there now N`, `orders failed 0`.
    5. Waiting cost: `tick: … -> N ms per NPC` at or below 0.02 while they wait (the spike's `gate-closed-v2`: 0.020), and `K&K navigation on the main thread: … ms per NPC` a few µs.
4. **Gate run 2: the open event wakes them.** `/gate open keep gate`. The waiting NPCs start when the opening animation has finished (the spike's `gate-reopened-v2`), without waiting for the 5-second timer. After 3 minutes `/knk npc nav stats`: `woken by its event N` about the number that waited, `trips` rising again, `waiting there now 0`, trespasses 0.
5. **Gate run 3: the fallback.** Close the gate again and wait until NPCs stand at it. `/knk npc nav stats` twice, a minute apart: `waits: no allowed route` rises by about one per waiting NPC every 5 seconds (the safety timer asks again) while `stretches` and the NPCs' positions do not change: nobody walks back and forth at the gate.
6. **Access run 1: a district becomes unavailable ahead (test A, the deciding test).** Open the gate, `/knk npc nav clear`, `/knk npc nav route load south-gate`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`, 2 minutes. Then remove entry to the Residential District (the domain's entry rule in the web app) and run `/knk cache refresh` if the change does not arrive by itself. Look:
    1. NPCs outside walk to the district's edge and stand there, not in their tracks and not inside. NPCs already inside may finish their trip and leave; they do not come back in.
    2. The log: `… way ahead is closed by region <id> (event) …` right after the refresh; `(recheck)` instead means the change only arrived with the 40-tick recheck: note which.
    3. After 3 minutes `/knk npc nav stats`: `rules: trespasses 0 (must be 0)`, `orders failed 0`, `tick: … ms per NPC` at or below 0.02 (the spike's `access-removed-v2`: 0.014; `trail gate/access`: 0.021–0.027).
    4. A `TRESPASS` line in the log is a failure: post it with the time you removed entry (with `stop-on-trespass: true` that NPC stops and plans again).
7. **Access run 2: restored.** Restore entry (and `/knk cache refresh`). Waiting NPCs continue at once (`woken by its event N`), at the latest after 5 seconds. After 2 minutes `/knk npc nav stats` (the spike's `access-restored-v2`: 0.023 ms per NPC).
8. **The refresh replans nobody for nothing.** With 50 NPCs walking and no rule changed: `/knk npc nav stats reset`, `/knk cache refresh` three times, `/knk npc nav stats`: `replans: recheck 0, event 0`; `rule checks` rises by about 50 per refresh (the spike replanned every NPC on every refresh).
9. **Planning-time block.** With the gate closed before spawning: `/knk npc nav clear`, `/knk npc nav spawn 5`: they walk to the gate and wait there (Phase 2: they waited at the spawn point). Open it: they go on.
10. **The trespass counter stays 0** over all runs, also in `curl <metrics address>/metrics | grep knk_npc_nav_events_total`: `trespass 0`, and `rule_check`, `replan_recheck`, `replan_event`, `blocked_walk`, `woken` next to the earlier events.
11. **Off.** `npc.navigation.enabled: false` and restart: as in Phase 2 step 10; closing and opening gates logs nothing about NPCs.

Compare with the spike's rule-check reruns ([stress test guide](../../guides/citizens-stress-test.md), results table): `access-removed-v2` 0.014 ms per NPC and 0 trespasses, `access-restored-v2` 0.023, `gate-closed-v2` 0.020, `gate-reopened-v2` 0.032, `trail gate/access` 0.021–0.027; the gap the spike left (NPCs stopped where they were) should be gone. Post the `stats` output of steps 3, 4, 6 and 7 and the run log on [#361](https://github.com/PandiO/knk-workspace/issues/361).

## Phase 4 — Groups (plugin)

Goal: groups plan once (NAV-05, developer request).

- `NavGroup`: a leader (or a few scouts) plans the road route; followers get the same hops with a formation offset and follow the leader's progress. One blocked state, one wake-up for the group.
- `Formation` (Bukkit-free, configurable per group, template or assignment; Q4): column (default), pairs/ranks (soldiers), loose cluster, escort ring (octagon around the leader). Slot offsets are relative to the leader's heading on the route; where the road or walk grid is too narrow for a slot (gates, stairs, wall walks) the group folds into a column and reforms after.
- A follower that falls behind or gets stuck plans its own leg back to its slot (bounded), not the whole route.
- Event replans per group, not per NPC.

**Tests:** a 20-NPC group plans once; a gate closing blocks the group with one replan; a stuck follower rejoins.

**Done when:** a 50-NPC group's event replan finishes within one planning slot (the spike's 50 separate replans took 1.3 s at p95).

## Phase 5 — NPC access identity (web-api, plugin, web-app)

Goal: NPCs have their own rights in the K&K permission system (DESIGN §7, NPC-12, O06; NAV-09).

- **web-api:** an NPC (or NPC template) as a permission holder, with per-NPC exceptions for domain entry/exit and gate access (DESIGN NPC-12); endpoints to read effective NPC permissions; realtime "NPC permissions changed" event.
- **plugin:** `NpcAccessSubject` reading those permissions through `knk-api-client` (cache-first, like `EffectivePermissions`); replaces Phase 2's configured profile. Permission-change events feed Phase 3's replans.
- **web-app:** NPC permission editing on the NPC/template page (with BEHAVIOR_MODEL §16.6 military pages).
- Gate pass-through for NPCs (DESIGN §7 investigation steps 1–4, O07) is part of this phase or its own follow-up (Q5).

**Done when:** an NPC with entry to a district and one without behave differently on the same route, and removing the right mid-route stops it as in Phase 3.

## Phase 6 — Detours and hidden routes (web-api, plugin, web-app)

Goal: blocked NPCs look for another way, within limits, including routes not in plain sight (NAV-06, developer request).

- **Road data:** edge flags for hidden routes (secret passage, sewer, postern) with who may use them (faction, side, role; BEHAVIOR_MODEL §16.5) and edge tags (main road, wall walk; BEHAVIOR_MODEL §12.2). web-api schema and migration; web-app road editor fields.
- **Router:** a detour search on the K&K road graph with a maximum detour factor (route length vs the blocked route) and a maximum search cost; hidden edges only for movers allowed to use them, never shown to players' navigation.
- Behavior gets "blocked, detour available (length, risk)" vs "blocked, no detour" and decides (BEHAVIOR_MODEL §8); navigation doesn't take a detour on its own unless the assignment allows it (as DESIGN §6's "allow automatic alternative route", default off).

**Done when:** with the main gate closed, NPCs allowed to use a hidden passage take it within the detour limit, and others wait at the gate.

## Phase 7 — Movement quality (plugin)

Goal: fewer stuck events (NAV-07) and checked chunk handling (NAV-11).

- **Walked lines from players (NAV-18):** sample player positions on road segments (the plugin already sees them; store aggregated, not raw), build a per-segment walked line from enough samples (centre of the walked corridor, ordered along the segment), store it with the road network, and let `RouteFollower` prefer it over the geometric line. Measure stuck per trip on the staircases before and after.
- **K&K step controller** (only if walked lines aren't enough): K&K steers the NPC body tick by tick on stairs and corners (stair-aware turning and step-up), Citizens only animates.
- Waypoints on stair landings and turns: from the road geometry (vertices on stairs) or a walk-grid scan of the stretch; never a waypoint on a stair corner.
- Stuck handling: classify stuck spots (log position and the hop), try one local walk-pathfinder leg around the spot before counting a retry.
- Run the stress test guide's test C (unloaded chunks) on the production code.
- Measure `CITIZENS` vs `CITIZENS_ASYNC` and `PLAYER` vs `MANNEQUIN` (Q2).

**Done when:** stuck events per trip on the clean route drop well below the spike's 3.5, and test C passes on the production code as it did in the spike (v3, 2026-11-12: pauses 57 = resumes 57).

## Phase 7b — Movement outside loaded areas (plugin)

Goal: NPCs keep travelling where no player keeps the world loaded (NAV-12; BEHAVIOR_MODEL §13 level of detail). The developer prefers real walking all the way (2026-11-12), so the travel bubble comes first and abstract movement is the fallback.

- **Switch with overrides (developer decision 2026-11-12):** whether NPCs load chunks (bubble) or switch to simulated travel, from the Phase 1 config layering: global default, world, region/domain, template, assignment. Tuned from the metrics.
- **Travel bubble:** a travelling NPC gets Citizens' `KEEP_CHUNK_LOADED` (Citizens moves a force-load ticket with the chunk the NPC stands in), and K&K puts plugin chunk tickets on the next hop's capture box before capturing it (chunks loaded asynchronously, never generated) and removes them after the leg. A cap on NPCs with a bubble (config), released on arrival or when waiting; idle NPCs at posts never have one. Measure first with a spike setting: chunks loaded per NPC, tick cost, memory, whether NPCs keep moving at chunk borders.
- **Abstract mover (fallback, above the cap or for long journeys):** when the next hop reaches an unloaded area (or the NPC's chunk unloads), despawn the Citizens entity and continue along the K&K road route by time: route length ÷ speed, with waits at gates and denied regions by the same rules as Phase 3 (the road policy needs no chunks).
- **Materialize:** when the area around the NPC's computed position loads, spawn the entity there on a safe floor (DESIGN §6 spawn validation) and continue physically.
- Persist the abstract position with the NPC's state (K&K database is the source of truth), so a restart doesn't lose travelling NPCs.
- Never load chunks to move an NPC.

**Done when:** with the bubble, NPCs walk a route through unloaded areas all the way with no player near (tick cost within the §13 budget at the cap); above the cap, an NPC arrives in about the walking time and appears at the right place on the route when a player goes there midway.

## Phase 8 — Benchmark gate (dev server, then closed alpha)

- Repeat the spike scenarios with the production code: 50, 100 and 200 NPCs walking; gate closed and reopened; access removed and restored; groups; unloaded chunks.
- Metrics through `PluginMetrics` (KNG-232): ms per NPC, plans per second, queue wait, stuck per trip, trespasses (must be 0), waiting NPCs.
- Confirm BEHAVIOR_MODEL §13's proposed budgets (≤ 10 ms per tick at 100 active guards) and write them into §13 as decided; recheck later on the live host.
- **Stair release gate** (see the top of this plan): the stair house and the upper staircase on `quarry-to-keep` with 50 NPCs, both directions, 10 minutes; no stall longer than one watchdog period, no visible jumping in circles. Guards don't ship before it passes.

## Decisions (developer, 2026-11-12)

| ID | Question | Decision |
|---|---|---|
| Q1 | Where the code lives | **Decouple from the Minecraft API as far as reasonable, without over-engineering**: K&K may one day move to a dedicated or custom game engine. Reuse existing code. The NPC behavior and navigation models will grow a lot (traits, templates, functions). So: all navigation and NPC logic in Bukkit-free knk-core (`core/npc/…`, next to the engine-neutral router, walk pathfinder and `CellAccess` that already live there), with ports for everything the engine provides (mover, world/block queries, access subject, scheduler, events); Citizens and Bukkit only in knk-paper adapters (`paper/npc/…`). Packages grouped by concern (`nav`, `group`, `access`, later `template`, `trait`, `behavior`) so they can be lifted into their own Gradle module when the platform grows. |
| Q2 | Entity type and pathfinder | `PLAYER` and `CITIZENS` (as recommended); compare `MANNEQUIN` and `CITIZENS_ASYNC` in Phase 7. |
| Q3 | NPC access before Phase 5 | A configured access profile per template (accepted). |
| Q4 | Group formation | **Configurable formations.** Column is the default; pairs or ranks preferred for soldiers; a loose cluster; and an escort ring (an octagon around the leader in the centre, as bodyguards). Formation per group, template or assignment; narrow places (gates, stairs, wall walks) fold any formation into a column and reform after. |
| Q5 | Gate pass-through for NPCs | Its own follow-up after Phase 5 (agreed). Similar to players, but the permissions must be worked out; it ties into clans and NPC loyalty to towns and clans (BEHAVIOR_MODEL §16.5). |
| Q6 | Hidden routes | Hidden routes are not in the road graph today: they need their own issue (road data, authoring, who may use them). Phase 6 depends on it. |
| Q8 | How NPCs follow the K&K route (NAV-15) | **Decided 2026-11-12 from Phase 0:** Citizens waypoint lists along the K&K line, one ~32-block stretch at a time handed over early, floor continuity between waypoints, K&K progress watchdog (NAV-17) with a short Citizens A* recovery leg. Hop mode (Citizens A* per 16-block hop) only for off-road bits. Stairs stay the weak spot: walked lines from players (NAV-18), then a K&K step controller if needed (Phase 7). |
| Q7 | Citizens version | The latest stable Citizens build for 26.3, pinned. Citizens publishes timestamped snapshot builds only, so "stable" means the newest build for 26.3 at the time, pinned; test each Minecraft update on the dev server with the planned Paper build first (desk check report §8.6). |
