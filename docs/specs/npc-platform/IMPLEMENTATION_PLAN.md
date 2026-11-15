# NPC navigation adapter (Citizens) — Implementation Plan

**Status:** In progress since 2026-11-13 (Phase 1, developer go-ahead; parent issue [#358](https://github.com/PandiO/knk-workspace/issues/358)). Proposed 2026-11-11. Plans the shared NPC navigation capability only (K&K plans, Citizens moves); behavior, guards, garrisons and combat are separate work. Developer answers to Q1–Q7 on 2026-11-12; see "Decisions".
**Last updated:** 2026-11-15 (Phase 4b designed, sub-issue [#519](https://github.com/PandiO/knk-workspace/issues/519): wall corners and the stuck recovery ladder for link L3 (#521), narrowed formations and the followers-finish-trip toggle for link L4 (#522), what the code does today; defaults decided by the developer 2026-11-15); 2026-11-14 (Phase 1 follow-ups, sub-issue #490: damage listener guards, the damage cause, the Windows metrics check, the audit re-run); 2026-11-13 (Phase 4 built on `claude/npc-navigation`, sub-issue #377: status, known limits, developer test); 2026-11-13 (Phase 3 built on `claude/npc-navigation`, sub-issue #361: status, known limits, developer test); 2026-11-13 (Phase 2 built on `claude/npc-navigation`, sub-issue #360: status, what differs from the spike, developer test); 2026-11-13 (implementation started: parent issue #358, stair release gate, Phase 1 breakdown with the NPC event audit, CitizensAPI pin, coexistence with the Siege Survival NPC core); 2026-11-12 (Phase 0 done, Q8 decided, NAV-17 in Phase 2, NAV-18 walked lines in Phase 7); 2026-11-12 (Phase 0 route-following spike, metrics and config layering in Phase 1, NAV-14/15/16, Q8; Q4 formations decided; Phase 7b travel bubble first; Phase 7b abstract movement outside loaded areas, spread spawns and targeted replans, from the unloaded-chunk runs; developer answers Q1–Q7; road network components and the router's BLOCKED result from the unloaded-chunk test)
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
| 4b — Wall corners, narrowed formations, finish-trip toggle | plugin | M | 4 (with #520) | yes | NAV-19–NAV-23 |
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
- **NPC event audit** (`/knk npc audit start|stop|report`): while on, a monitor on every registered event type counts events whose player or entity is an NPC, by event type, and writes the report to `plugins/KnightsAndKings/npc-logs/`. Run with test NPCs walking a route (1.5), then guard exactly the listeners that react to the event types it finds, with a test each. Expected from the spike: the region tracking behind `listeners/WorldGuardRegionListener` (10 region lookups per second for 200 NPCs). 79 listener files react to player events on `main`; most likely never see an NPC, which the audit confirms instead of guessing. The developer's audit (2026-11-14, [#490](https://github.com/PandiO/knk-workspace/issues/490)) also named 14 listeners of `EntityDamageEvent`; their damage handlers are guarded since then (see Status).
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

**Status (2026-11-14, [#490](https://github.com/PandiO/knk-workspace/issues/490)):** developer test steps 1–3 done on `next`; the audit found `EntityDamageEvent` from NPCs (615 in 3 minutes for 50 test NPCs) reaching 14 K&K listeners, and 18,420 `EntityAirChangeEvent` (no K&K listener).
1. **Guards** (`NpcEntities.isNpc`, one early return per handler, a test each): `AdminFreezeListener`, `TeleportWarmupListener`, `DomainEffectDamageListener` and `FallStatisticsListener` (NPC victim); `CombatTagListener`, `SiegeCombatListener`, `CombatStatisticsListener` and `TelemetryListener` (NPC victim or attacker; `CombatStatisticsListener` also a player death of an NPC, a mob killed by an NPC and an NPC's bow shot); `EnchantmentCombatListener`, `JoinLoadingRestrictionListener` and `AfkActivityListener` (NPC attacker). Not guarded, because they protect the world or the entity rather than a player: `GateSuffocationGuard` (moves an NPC out of a gate door too), `HubRulesListener` (hub damage rules), `GlobalRegionProtectionListener` (item frames, paintings, armor stands). The guards hold for any entity with the `NPC` metadata, whether or not `npc.navigation.enabled` is on.
2. **Why NPCs took damage:** all 615 were plain `EntityDamageEvent` (no attacker; a hit would be `EntityDamageByEntityEvent`). The likely cause is the Phase 1 test walkers (1.5): their spot search took water as room for a body (water is passable), so some walkers were sent to the bottom of ponds and stood there drowning; Citizens' `protected` flag is on by default and cancels the damage, so they never died. Drowning fits the numbers: one drowning NPC makes about 20 air changes per damage event. Fixed: a spot needs two passable, dry, not waterlogged blocks above its floor. Not a Phase 2 route issue (the test walkers do not follow routes). The audit report now lists the damage causes, so the re-run confirms or refutes this.

**Developer test (Phase 1):**
1. Deploy `claude/npc-navigation`; in `config.yml` set `npc.navigation.enabled: true` (and `metrics.enabled: true` to see `/metrics`). Startup log: `[NPC] navigation: Citizens 2.0.44-SNAPSHOT (build 4269), override scopes {…}`. Without Citizens, or disabled: `[NPC] navigation unavailable: <reason>`.
2. `/knk npc status`: running, and every setting with its layer (`default`, `global`, `world …`, `region …`). Optional: add a `regions.<region id>.recheck-ticks: 20` override, restart, stand in that region: status shows `20 (region <id>)`.
3. `/knk npc audit start`, then `/knk npc test spawn 50 24` somewhere with regions (inside a town), let them walk 5 minutes, then `/knk npc audit report`. The report (also in `plugins/KnightsAndKings/npc-logs/`) lists each event type NPCs triggered and which K&K listeners received it. Expected: `WorldGuardRegionListener` listed for `PlayerMoveEvent` but no `[KnK Resolver] resolveRegionsFromApi` flood in the server log (the guard).
4. With metrics on: `curl <metrics address>/metrics | grep knk_npc_nav` shows `knk_npc_nav_npcs{world,state}` and the event counters. On Windows (PowerShell, default address `127.0.0.1:9225`; add `-Headers @{ Authorization = "Bearer <token>" }` when `metrics.token` is set): `(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:9225/metrics).Content -split '\n' | Select-String knk_npc_nav`.
5. `/knk npc test clear`; restart without Citizens (or `enabled: false`): plugin loads, status says why it's off.

Send the audit report file; the listeners it names get guards (with tests) before Phase 1 closes.

**Audit re-run after the guards (#490):** deploy `next` with #490 merged, then `/knk npc audit reset`, `/knk npc audit start`, `/knk npc test spawn 50 24` in the same town, 3–5 minutes, `/knk npc audit report`, `/knk npc test clear`.
1. The report still lists the 14 listeners for `EntityDamageEvent` if NPCs take any damage: it shows who receives an event type, not who acts. Bukkit also shares one handler list between `EntityDamageEvent` and `EntityDamageByEntityEvent`, so a listener for hits is listed for plain damage it is never called with.
2. What to look at instead: (a) the far smaller `EntityDamageEvent` and `EntityAirChangeEvent` counts (expected: a few falls, no drowning); (b) the new `causes:` line under each damage event type (expected: no `DROWNING`; `SUFFOCATION` or `FALL` in numbers would point at the walkers' spots or at gates, worth a note on #490); (c) the NPCs leave nothing in player systems: no statistics rows for the `knk-test-*` NPCs, no combat tag, freeze or teleport warmup effects, no telemetry `combat.hit` events for them.
3. If `DROWNING` still shows up in numbers, the cause is not the spot search: post the report on #490.

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

Sub-issue: [#377](https://github.com/PandiO/knk-workspace/issues/377). Branch: knk-plugin `claude/npc-navigation` (continues Phase 3). Requirement: NAV-05; Decision Q4.

**Status (2026-11-13):** built on knk-plugin `claude/npc-navigation`; full suite green (core 2621, api-client 324, paper 2587; 38 and 6 new tests). Not yet run on a server, and neither are Phases 2 and 3 it builds on. Everything stays off while `npc.navigation.enabled` is false: the group service is built together with route following (the first `/knk npc nav` use).

1. **Where (knk-core `core/npc/nav/group/`, no engine types):** `Formation`, `GroupSettings`, `NavGroup`, `NavGroupService` and the group's path (`GroupPath`). The group layer sits on top of `NpcNavigationService`'s public surface (`navigate`, `cancel`, `state`, `followerOf`, `blockingOf`); Phase 2 and 3 code is unchanged apart from three additions: six keys in `NavigationSettings`, five events in `NpcNavigationMetrics`, and the port method `NpcMover.setSpeedFactor` (Citizens' speed modifier; an engine that cannot change speed ignores it).
2. **Plans once:** only the group's leader (its first member) has an order in the navigation service. It plans the road route, is rechecked, is blocked and is woken like a single NPC, so a gate or access change costs a group one plan in one planning slot, whatever its size, and the group has one blocked state and one wake-up: the leader's. The followers have no route and no plan.
3. **The group's path and the slots:** the path is the leader's route line while it is on it (the same points the leader walks, plus 12 blocks of the line ahead of it) and the leader's own footsteps off the road (off-road legs, recovery legs). A follower's slot is a distance behind the leader along that path and an offset to the side of it; the follower gets its lane as waypoint lists (no path search), handed on before the one in hand ends. At the start the column unwinds from where the group stands: a follower sets out when the path is long enough for its slot.
4. **Formations (Q4; `group-formation`, per group through the settings' layers including template and assignment):** `column` (single file, `group-spacing` apart; the default), `ranks` (rows of `group-ranks-width` behind the leader; 2 = pairs), `cluster` (rows of three, each slot nudged up to a quarter spacing off its place, the same every time), `escort-ring` (eight around the leader at 1.25 spacings, then rings of 16, 24, …; the first escorts ahead, behind, right and left).
5. **Folding:** a lane point is used only where an NPC can stand there and on the way out from the path (a floor within one block of the path's height), and only where it lies in the same WorldGuard regions as the path's own point. Where the path under the group (from the rearmost slot to the foremost) is narrower than the formation, the whole group walks as a column (`group_fold`) and takes up its formation again when the leader is the formation's depth past the narrow place (`group_reform`). A lane leaves the path's centre one point after a narrow place and is back on it one point before the next.
6. **Falling behind:** a follower more than a block behind its slot walks at `group-catch-up-speed` until it is back; one ahead of its slot waits for it. A follower further than `group-rejoin-blocks` from its lane, or without progress along the path for `no-progress-ticks`, plans its own leg back (`group_rejoin`): one order in the navigation service to the path point nearest its slot that one local leg (`hop-blocks`) reaches, never the whole route. After three failed legs in a row the group goes on without it (`group_lost`) and it keeps trying every `no-route-wait-ticks`, at once after a gate or access change.
7. **The leader waits:** when a follower is more than `group-regroup-blocks` behind its slot the leader stops (`group_regroup`) until every follower is within half of that, at most 30 seconds; then its order is given again (one more road plan for the group). Followers the group goes on without, followers stopped by a rule and followers whose chunk is unloaded are not waited for.
8. **Rules for followers:** before a follower is sent on, every region on its lane that it does not stand in yet is asked about with the current rules, judged from the regions it stands in; it stops before the first one it may not enter and walks on when the rule allows it. Its waypoints are handed out again after a gate or availability event, and every `recheck-ticks` when they cross into a region.
9. **Results:** `NavGroup.navigate(goal, onResult)` reports `Blocked` once per blocking element and then one final result: `Arrived` when the leader arrived and the followers reached their slots (or 20 seconds passed), `Failed` or `Cancelled` as the leader's order ended. A new order replaces the running one; `remove` takes a member out (without its leader the next follower leads and the order is given again).
10. **Test driver:** `/knk npc nav group <n> [formation] [profile]` spawns n NPCs near the route's start as one group that walks the stored route back and forth; the formation named there is the group's assignment layer, without one the `group-formation` setting at the route's start counts. `/knk npc nav stats` has a `groups` line; `goto`, `patrol` and `clear` order and remove groups too.
11. **Known limits:**
    1. A gate that closes between the leader and its followers (#507, the push fixed in link L2 of the follow-ups chain, #520): the gate's state event comes when the close starts, and the group keeps the doors of the leader's routes, passed ones too. A follower that still has to pass the door stops a block short of the door's box (`AccessRules.doorBox`: its closed footprint and its captured closed and opened regions, from the gate code's `GateDoorBounds`); one already within that block of the box walks on out of it, so the closing door pushes nobody. Stopped followers count as stopped by a rule: the leader walks on without waiting for them, and they follow when the gate opens (the leader may wait for them once). What remains: a follower within about a step of the margin when the close starts may still walk on through; a door without captured regions has its closed footprint as its box, which for a drawbridge leaves out the plank's swing; a single NPC or leader standing in the box when the door starts closing replans there and is moved out by the gate like a player (#534). Whether followers finish their trip after the leader turned back is the toggle of link L4 (developer decision 2026-11-14 on #507).
    2. An order back the way the group came turns the column round through itself: the leader walks back past its followers, each sets out when its slot has passed it. There is no about-face with the rearmost NPC leading.
    3. A formation folds as a whole; it does not squeeze into narrower ranks. At `group-spacing: 2` pairs need a road 3 blocks wide, a cluster and an escort ring one of 6: on narrower roads they walk as a column all the way.
    4. Followers and the rules (#506, link L2 of the follow-ups chain): a gate or availability event hands every follower its waypoints again in the next tick (not at the group's next 5-tick turn); a follower whose way ahead is now denied stops at the edge, the ones inside walk on. Followers have a trespass guard of their own: an entry into a region the current rules deny is logged (`TRESPASS <npc> entered <region> at x y z (a follower of group <n>)`) and counted in `rules: trespasses`; it does not stop the follower (`stop-on-trespass` is for NPCs with an order of their own), and an event first takes a fresh look so entries made under the old rules are not judged by the new. After `/knk cache refresh` the region → domain map is warmed again for every world's road regions and a second availability event follows (only while NPC navigation runs): the NPC checks never ask the API, a region of unknown domain is open to them, and before this they saw every district as open until the road tags' next pass, up to a minute. A realtime domain change made in the web app without `/knk cache refresh` still empties that map without warming it again (#533).
    5. A follower whose chunk unloads stays behind until the chunk is loaded again (movement outside loaded areas is Phase 7b).
    6. One leader, no scouts. Off the road the followers have no look-ahead and walk in short stretches; slots ahead of the leader (escort ring) exist on the road line only.
    7. The groups' main-thread time is part of `K&K navigation on the main thread` in `/knk npc nav stats`, not of the `knk_npc_nav_main_thread_seconds` histogram.

**Developer test (Phase 4):**
1. Run the Phase 2 and Phase 3 tests first: groups walk on top of them. Deploy the build. In `config.yml`: `npc.navigation.enabled: true`, `metrics.enabled: true`, and merge the six `group-*` keys (the YAML is in the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc)). `/knk npc status` lists `group-formation = column`, `group-spacing = 2.0`, `group-ranks-width = 2`, `group-rejoin-blocks = 4.0`, `group-regroup-blocks = 24.0` and `group-catch-up-speed = 1.3`, each with its layer.
2. With no NPCs out, wait a minute, then `/knk npc nav baseline`.
3. **A column of 20.** `/knk npc nav route load south-gate`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20`. Look:
    1. The first NPC out leads. The others set out one after the other and walk single file, two blocks apart, down the middle of the road; nobody stops and starts while the leader walks.
    2. At the route's end the leader rests a second and walks back past its column; each follower turns in behind it (known limit 2).
    3. After three trips `/knk npc nav stats`: `groups 1 (20 NPCs, column): trips 3`, `own legs back` low (compare it with `stuck: … no progress`), `left behind 0`, `most plans at once 1`, `orders failed 0`, `engine block rules removed 0`.
    4. `tick: … -> N ms per NPC` and `K&K navigation on the main thread: … (N ms per NPC)`: at or below the Phase 2 numbers for 20 single NPCs.
4. **A column of 50.** `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 50`, 6 minutes, `/knk npc nav stats`. The column is about 100 blocks long; `trips` counts the group's trips. Compare `tick … ms per NPC` with Phase 2's 50 single NPCs (the spike's `trail-50`: 0.014–0.020).
5. **Each formation, 20 and 50 NPCs.** For `ranks`, `cluster` and `escort-ring` in turn: `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20 <formation>`, three trips, `/knk npc nav stats`; then the same with 50. Look:
    1. `ranks`: pairs, one NPC either side of the road's middle, rows two blocks apart. With `group-ranks-width: 4` (restart): rows of four where the road is 7 blocks wide, a column where it is not.
    2. `cluster`: a loose crowd behind the leader, three abreast, not a grid.
    3. `escort-ring`: eight NPCs around the leader, two of them walking ahead of it; with 20 the other eleven on a second, wider ring. On a road narrower than 6 blocks this is a column (known limit 3): try `group-spacing: 1.5`.
    4. `stats`: `folds` equals `reforms` (or is one more while folded), `folded now 0` on the open road, `own legs back` and `left behind` as for the column, `most plans at once 1`.
    5. The log (`npc-logs/<time>_npc-nav.log`) has `group <n>: leader knk-nav-<n>, <n> followers, <formation>, spacing 2.0, group-formation from assignment`, and a line for every fold with its position.
6. **The fold at a gate.** With the Keep Gate open: `/knk npc nav route load keep-gate`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20 ranks`. Stand at the gate. Look:
    1. The group goes single file before the gate (log: `group <n> … folds into a column: the path is too narrow for ranks 2 wide, spacing 2.0 at x y z`), passes it, and stands in pairs again when the leader is a formation's length past it (`… takes up its formation again`).
    2. Nobody walks into the gate posts or the wall beside the gate.
    3. After the gate the rear of the column walks faster until it is back in its rows; the leader may wait for it (`leader waited 1`).
    4. Repeat with 50 and with `escort-ring`.
7. **The fold on stairs.** `/knk npc nav route load quarry-to-keep`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20 ranks`, both directions, then 50. Stand in the stair house (1408–1416, y 49–62, z −489…−503) and at the upper staircase. Look:
    1. The group is a column before the first flight, stays one through both flights and the U-turn, and reforms on the road above.
    2. The stair release gate's points for the followers too: nobody stands still in a flight longer than 3 seconds, nobody jumps in circles, nobody hops to the flight above or below.
    3. `stats`: `own legs back` per trip against Phase 2's `stuck: no progress` per trip for single NPCs (the spike: 1.3 per trip per NPC); the log has every own leg with its position. Followers walk waypoints without the leader's recovery leg, so the hard spots show here first.
8. **A gate closing ahead of the group: one replan, one wake-up.** `/knk npc nav route load keep-gate`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 50`. When the leader is on its way to the gate: `/gate close keep gate`. Look:
    1. The leader walks to the gate and waits there; the column closes up behind it, everybody in its slot; nobody is on the keep side.
    2. The log has one `… way ahead is closed by gate <id> (event) …: route planned again` line and one `group <n> (knk-nav-<n>, 50 NPCs) blocked: … [gate <name> (<id>)]` line, not fifty.
    3. `/knk npc nav stats` right after: `replans: … event 1`, `reported blocked 1`, `walked to the blocking element 1`, `waiting there now 1`, `most plans at once 1`, `planning queue 0`.
    4. A minute later: `waits: no allowed route` rose by about 12 (the leader's 5-second timer), not by 600.
    5. `/gate open keep gate`: the group sets out when the gate is open; `woken by its event 1`.
    6. **The number to compare with the spike:** the spike replanned 50 NPCs separately for one event and its planning queue wait was 1.3 s at p95 with 4 plans in flight. Here the event is one plan: `most plans at once 1`, and on the metrics endpoint `knk_npc_nav_queue_wait_seconds_count` rises by 1 for the event with the sample in the lowest bucket (`knk_npc_nav_queue_wait_seconds_bucket{le="0.0005"}` to `{le="0.05"}`: the plan started in the tick it was asked for or the next).
9. **A gate closing in the middle of the group** (known limit 1, #507). A short route through the south gate (there is no stored `south-gate` route: stand a few blocks outside the gate, `/knk npc nav from`, walk 30 blocks inside, `/knk npc nav to`, `/knk npc nav route save south-gate-short`), `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20`. Stand beside the gate. When the leader is about 10 blocks past the door, `/gate toggle` the south gate. Look:
    1. While the door closes no NPC is moved by it: none jumps sideways out of the doorway, and the server log has no `[GateSafety] Moved` line for an NPC. The followers that had still to pass stand a block or two short of the door; one that was in the doorway walks on through.
    2. The leader walks on to the route's end without waiting (`leader waited 0`); `left behind` does not rise for the stopped followers.
    3. `/gate toggle` again: the stopped followers walk through and follow the leader wherever it is (it may already be on its way back: followers follow the leader, developer decision 2026-11-14 on #507). `rules: trespasses 0`. Post the log.
10. **An access change in the middle of the group** (known limit 4, #506). `/knk npc nav route load quarry-to-keep`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20`. When about half the column is inside the Residential District, remove entry to it (web app) and `/knk cache refresh`. Look: within a second the NPCs outside stop at the district's edge and none enters; the NPCs inside walk on; the server log has `[KnK Resolver] warmCache: completed` after the refresh; `rules: trespasses 0` and no `TRESPASS` line (followers are counted now). Restore entry and `/knk cache refresh`: they follow, the leader waits for them once at most (`leader waited` up by 1 or 0). Post the `stats` output and the log.
11. **A follower pushed off its slot.** With a group of 20 walking:
    1. Put a two-block pillar on the road right in front of a follower. After 3 seconds (`no-progress-ticks`) the log says `<npc> (group <n>) made no progress for 60 ticks at x y z: its own leg back to the group's path`; the NPC walks round the pillar, back to the path and faster until it is in its slot. `stats`: `own legs back 1 (now 0)`, `replans` unchanged (no road plan for it).
    2. Let water flow across the road so it carries a follower more than 4 blocks (`group-rejoin-blocks`) off the road: `<npc> (group <n>) is off its lane at x y z: its own leg back …`.
    3. Wall a follower in (blocks all round): three failed legs later `stats` shows `left behind 1 (now 1)` and the log `… could not get back to the group's path …: the group goes on without it, it keeps trying`; the leader waited at most 30 seconds. Free it: it walks after the group.
12. `/knk npc nav goto` (the group walks to you, in formation), `/knk npc nav patrol` (back on the route). `/knk npc nav spawn 20` next to a group: single NPCs and groups walk the same route.
13. With metrics on: `curl <metrics address>/metrics | grep 'knk_npc_nav_events_total{event="group_'` shows `group_fold`, `group_reform`, `group_rejoin`, `group_regroup` and `group_lost`.
14. **Off.** `npc.navigation.enabled: false` and restart: `/knk npc nav group 20` answers `NPC navigation unavailable: npc.navigation.enabled is false`.

Post the `stats` output of steps 3, 4, 5, 7 and 8, your notes on steps 6, 9 and 11, and the run log on [#377](https://github.com/PandiO/knk-workspace/issues/377).

## Phase 4b — Wall corners, narrowed formations, followers that finish their trip (plugin, follow-ups)

Goal: NPCs and groups get round the wall corners, stair corners and landings of a medieval town without getting stuck or falling, free themselves in a few cheap steps when they do get stuck, and walk in formations that fit the road; groups can be told to let their followers finish the trip.

Sources: the developer's Phase 2 and Phase 4 tests on `next` (2026-11-14, results on [#360](https://github.com/PandiO/knk-workspace/issues/360) and [#377](https://github.com/PandiO/knk-workspace/issues/377)); [#508](https://github.com/PandiO/knk-workspace/issues/508) (wall corners), [#491](https://github.com/PandiO/knk-workspace/issues/491) (stair corner), [#492](https://github.com/PandiO/knk-workspace/issues/492) (with its three comments), [#493](https://github.com/PandiO/knk-workspace/issues/493) (with the developer's two comments), [#507](https://github.com/PandiO/knk-workspace/issues/507) (developer decision 2026-11-14). Requirements: [BEHAVIOR_MODEL.md § 2](BEHAVIOR_MODEL.md#navigation-adapter-requirements-from-the-spike-2026-11-11) NAV-19–NAV-23. Built by the [NPC navigation follow-ups chain](../../ai-agents/handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md): link L3 ([#521](https://github.com/PandiO/knk-workspace/issues/521)) does 4b.2, link L4 ([#522](https://github.com/PandiO/knk-workspace/issues/522)) does 4b.3, each behind `npc.navigation.enabled` (off by default). It builds on Phase 4 with link L2 ([#520](https://github.com/PandiO/knk-workspace/issues/520): the followers' recheck and trespass guard, the door box, `DomainCacheRewarm`).

**Status (2026-11-15):** design (link L1, [#519](https://github.com/PandiO/knk-workspace/issues/519)), approved by the developer 2026-11-15 with every proposed default (4b.4); not built. L3 starts once this design and L2 are in `next`.

### 4b.1 What the code does today

Read on knk-plugin `next` at `b2c5dff0` and checked again at `11e07d6` (2026-11-15, L2 merged: the code named here is unchanged) and in Citizens2 / CitizensAPI `master` (the navigator, the A* strategy and `NavigatorParameters`).

1. **Why NPCs cut the stair corner (#491).** K&K's line keeps the corner (`HopPlanner.resampleKeepingCorners`, points every 1.5 blocks, `RouteFollower.STEP`). Citizens follows a waypoint list with `AStarNavigationStrategy` and moves on to the next waypoint as soon as the NPC is within `distanceMargin` of the current one horizontally and less than a block from it vertically (`NavigatorParameters.withinMargin`). K&K never sets that margin, so it is Citizens' default of 1 block (`npc.pathfinding.default-distance-margin`); K&K only sets `pathDistanceMargin(1.5)`, the goal of a path search. The NPC therefore turns towards the point after the corner a block before it, walks the diagonal, and on a ledge the diagonal crosses air: point 267 → 270 in the trace, then the 7-block fall. The trace's best index stays at 267 because the watchdog updates it every 20 ticks only; the shortcut is the engine's, not K&K's.
2. **Why the recovery target lies on another floor (#492).** Three places pick a target by horizontal distance or snap it to the nearest floor at any height:
    1. `NpcNavigationService.planRoad` treats an order whose goal is within `hop-blocks` (16) horizontally as a short trip: one local leg to the goal, no road (`direct = from.horizontalDistance(to)`). The leader at 1425 48 -516, at the bottom of the stair house, had the route's end 1421 85 -516 four blocks away horizontally and 37 blocks up, so its leg aimed at 1421 84 -516 (the goal's floor), which no path search reaches. A group leader gets a fresh order after every regroup wait (`NavGroup.closeUp` → `orderLeader`), which is how it got there. This is the "hop floor 1421 84 -516".
    2. `NavGroup.rejoin` aims a follower's own leg at the first group path point, counted back from its slot, within `hop-blocks − 2` blocks horizontally and 6 blocks up or down: nothing about the follower's floor or whether a body gets there. From 1433 44 -518 that was 1424 48 -520 (9–10 blocks across, 4 up, past the landing's corner). The order then takes path 1 as a short trip, with the same failing leg.
    3. `RouteFollower.recoveryTarget` takes the line point nearest the NPC by horizontal distance (not the height-weighted `nearestIndex` the watchdog uses) and snaps the point 4 further along with `HopPlanner.snapToFloor` (the nearest floor up to 12 blocks above or below the line point's own height). On stacked flights both can pick the flight above or below. `HopPlanner.hops` (off-road legs) also snaps without floor continuity.
3. **Why "retry 4 of 3", four in one second, every 5 s (#492).** `onStuck` logs `retries + 1` before it checks the cap: the fourth line is the moment the retries are used up, not a fourth try (the off-by-one is in the log; the cap itself holds at 3). There is no wait between tries: each one is queued at once, and when the local leg's target is unreachable Citizens' search ends in its first ticks with `CancelReason.STUCK` (`AStarNavigationStrategy` returns STUCK for an empty open set or the iteration limit), which K&K takes as a new stuck. Four lines in a second. Then the NPC waits `no-route-wait-ticks` (5 s) and plans again: the same short trip, the same failing leg, twice (`MAX_REPLANS`); the order fails, and the test driver orders again (`FAILED_RETRY_TICKS`). So the burst repeats every 5 s for as long as the run lasts.
4. **What `stuck_engine 14456` and `recovered 0` count (#491).** `stuck_engine` counts every Citizens STUCK cancel while an NPC is MOVING: Citizens' stationary check (`stationary-ticks`, 60 ticks in one block) **and** every failed path search of a retry. `stationary-ticks` and `no-progress-ticks` are both 60 and the watchdog looks every 20 ticks, so Citizens nearly always reports first (`stuck_no_progress 0`). `recovered` counts only a recovery leg started from the line that arrives; a retry of an off-road hop and an NPC that the 5-second replan got going again are not counted. Most of the 14456 are therefore failed searches of recovery legs (four per burst), and `recovered 0` says that no recovery leg from the line reached its target: the NPCs walked the corner on the replan, the "second try" the developer saw. L3 confirms this reading with the split counters of 4b.2 item 7, on the same route, before and after its change.
5. **What `most plans at once 2–3` measures (#492).** The stats line shows the server-wide maximum of queued plus running plans (`NpcNavRunner.sampleService`): road plans, local legs, followers' own legs and their retries alike. 2–3 is the leader's new order after a regroup wait plus followers' failing legs at the same moment. A group event still costs one road plan: step 8 passed with `replans: event 1`. The stat is wrong for the question, not the group.
6. **What `group_rejoin 481` counts (#492).** Each own leg back that fails (four instant retries, two replans 5 s apart) ends in `rejoinFailed`, the next one starts 40 ticks later, and after `MAX_REJOINS` (3) the follower is left behind but keeps trying every `no-route-wait-ticks`, without end, each try a new `group_rejoin`. Eight followers at the landing for a whole session give hundreds.
7. **Why the followers turned back with the leader (#507).** The test driver turns the group round at the route's end with a new order. `NavGroup.navigate` ends the old order (`finish`), clears the group's path (`resetPath`) and releases every follower; the new path starts where the leader stands. Followers that had not reached the end (held at the gate) stand ahead of their slots on the new path, wait until the leader passes them and fall in behind it. Turning back is a side effect of the reset, not a rule.
8. **Why formations fold so early (#493).** `Formation.rows` uses `group-spacing` both between rows and between neighbours in a row, and the group knows one width only (`Formation.halfWidth`): it fits or the group walks as a column. `GroupPath.wide` caches the answer for one half width per path point.

### 4b.2 Link L3 (#521): wall corners and stuck recovery (#508, #491, #492)

**Steering (NAV-19):**
1. **Corner clearance** (knk-core `RouteFollower.next`, new port method `NavWorld.freeHeight(world, x, floorY, z)` and `NavWorld.blocksBody(world, x, y, z)`, answered on Paper by `BukkitNavWorld` with the examiner's block rules). A turn is a line point where the heading changes by 30° or more over the next three points. For the turn point and the two points either side of it, the waypoint keeps at least `corner-clearance` (1.0 block, decided by the developer 2026-11-15) between the NPC's centre and the face of any cell that stops a body at feet or head height on the inside of the turn: it moves outwards, at most `corner-clearance` blocks, to a cell that is standable, keeps floor continuity with its neighbours and lies in the same WorldGuard regions as the line point. Where the road is too narrow for the full clearance, the waypoint goes as far out as the road allows. Straight stretches are left alone: a road line may run along a wall. Waypoints stay at block centres.
2. **Turns through the corner point.** The mover follows a stretch with `waypoint-margin` (0.5 block, decided by the developer 2026-11-15): Citizens moves on to the next waypoint only within that distance of the current one. New port method `NpcMover.follow(waypoints, margin)`; Paper sets `distanceMargin` on the navigator's local parameters right after `setTarget`, so local legs keep Citizens' default.
3. **Shortcuts.** K&K never leaves a corner point out of a stretch unless every cell the body's width (0.6 block) crosses on the straight line between its neighbours is standable, has the body's headroom and keeps floor continuity with both ends. (Today K&K drops only points that snap into the same block; the shortcut came from the engine's margin, item 2.)
4. **Low headroom.** A waypoint where the body must rise a full block (not a slab or stair step, which it steps up) needs 3 free blocks above the take-off cell for the jump; corner clearance and recovery never pick a cell that lacks it as a turn or recovery point. The landing at 1433 44 -517 has 2.5 (a slab in the upper half of the third block). L3 checks in a trace there whether Citizens jumps anyway (`JUMP` lines with no rise of a full block) and reports it.

**Targets on the NPC's own floor (NAV-20; fixes 4b.1 item 2):**

5. One rule, in a new knk-core helper (`PathTargets`), for the recovery leg, a follower's own leg back and the short-trip test:
    1. A target is a point **along the path** (the route line for an NPC with an order, the group's path for a follower), searched forward from the NPC's place on it (its `nearestIndex`, height counted), never backwards past the place.
    2. Floors are chained point by point from the floor the NPC stands on with `HopPlanner.snapNear` (continuity 2 blocks per point, as stretches do), so the chain stays on the NPC's floor; a point with no floor within continuity ends the search.
    3. The target is the first such point at least 3 blocks along the path ahead of the NPC whose cell is standable, has the body's headroom and lies in regions the current rules let it enter; at most `hop-blocks` along the path.
    4. The short trip of `planRoad` needs both `horizontal ≤ hop-blocks` **and** a height difference of at most `HopPlanner.CONTINUITY_RANGE` (2); otherwise the road plans the trip.
    5. Off-road hops (`HopPlanner.hops`) chain their floors with `snapNear` from the NPC's floor too.

**The recovery ladder (NAV-20; fixes 4b.1 item 3):**

6. A stuck spell starts when Citizens reports stuck while the body has not moved (stationary) or the watchdog sees no progress along the path (NAV-17); further reports during the spell join it. The NPC takes these steps in order, one per try:
    1. **Back-off:** walk back along its own last footsteps (K&K keeps the NPC's last 8 block positions with floor continuity) 2 blocks, then the rest of the stretch again from there, corner clearance applied.
    2. **Side-step:** the blocking face is the nearest cell within 1 block that stops a body at feet or head height, looked for in the walking direction first; the NPC steps one block straight away from it (diagonally back if that cell is not standable), then the rest of the stretch again.
    3. **Local leg ahead:** one Citizens A* leg under K&K's rules (`LocalLeg`) to the point item 5 picks, then back on the line after it.
    4. **Replan:** the route is dropped and planned again from where the NPC stands, through the planning queue (`MAX_REPLANS` per order as today; then the order fails and the caller decides).
7. **Spacing, cap and counting.**
    1. Between two tries the NPC waits `recovery-wait-ticks` (20, decided by the developer 2026-11-15); a try has worked when the NPC has come at least 1 block further along the path within `no-progress-ticks` of its start, and the spell ends there.
    2. Steps 1–3 count against `max-retries` (3, unchanged): with 3 every step is tried once, with 1 only the back-off, then the replan. A step that cannot be taken (no footsteps behind, no free cell to the side, no target ahead) is skipped without a wait and not counted.
    3. A failed engine path search ends that try (`recovery_no_path`): it is not a new stuck spell and starts no new count. Paper tells the two apart: new port signal `NpcMover.Listener.stuck(mover, StuckKind)` with `STATIONARY` (Citizens' stationary check) and `NO_PATH` (`CancelReason.STUCK` while the strategy has no path yet).
    4. A new stuck within 2 blocks of the last spell's spot within 30 s continues that spell's ladder where it stopped instead of starting again at the back-off.
    5. Log, one line per try and one when the spell ends, the count never past the cap: `<npc> stuck (stationary|no progress 40 ticks) at x y z, wall at x y z (north): step 1 of 3 back-off`; `<npc> freed at x y z by side-step (2 steps, 1.4 s)`; `<npc> not freed at x y z: replanning (steps used up)`.
8. **Faster detection** (decided by the developer 2026-11-15): `stationary-ticks` and `no-progress-ticks` from 60 to 40, so a stuck NPC starts its first step after 2 s and the acceptance's "no NPC still for more than 3 s" can hold.

**Followers (NAV-20):**

9. A follower that is stuck (no progress for `no-progress-ticks`, or Citizens' stationary stuck) runs the same ladder inside the group: back-off along its own footsteps, side-step, then its own leg back (today's `rejoin`) aimed at the group path's nearest reachable point **ahead** of it by item 5's rule (on its floor, never past its slot), then a replan of that leg. A follower off its lane (`group-rejoin-blocks`) skips straight to the own leg.
10. A follower never holds up the ones behind it: the followers behind keep their slots and walk on; a side-step goes to the side away from the path's centre; a follower whose ladder is used up or that is left behind waits on a free standable cell beside the lane (within 2 blocks), not on it. With `collidable: false` (the default) NPCs pass through each other anyway; this matters with `collidable: true` and for the stats.
11. A left-behind follower's tries are spaced out (decided by the developer 2026-11-15: doubling from `no-route-wait-ticks` up to 60 s, back to the start after any progress or a gate or access event), and a try never aims again at a target that failed from the same spot.

**Accounting (NAV-21; fixes 4b.1 items 4 and 5):**

12. Events (`NpcNavigationMetrics`, `knk_npc_nav_events_total{event=…}`): `stuck_engine` and `stuck_no_progress` count spells (one per spell, by what reported it first); `freed_back_off`, `freed_side_step`, `freed_local_leg`, `freed_replan` and `not_freed` end them; `recovered` stays as their sum (old dashboards keep working); `recovery_no_path` counts failed engine searches; `fell` counts a navigating NPC whose feet dropped 3 or more blocks below the path's floor there (Paper reports the fall distance on landing). Invariant, checked by a test: `stuck_engine + stuck_no_progress = recovered + not_freed + open spells`.
13. "Near a wall": a cell that stops a body at feet or head height touches the NPC's cell or the next cell in its walking direction.
14. `/knk npc nav stats`, replacing today's `stuck:` part: `stuck near a wall: N, freed by: back-off a / side-step b / local leg c / replan d, not freed e | stuck elsewhere: M (same split) | steps per stuck: mean x, max k | engine found no path n | longest still s.s s at x y z | falls f`. The group line's `most plans at once` becomes `road plans per group event: max r | local legs at once: max l` (a group event's road plans counted per group; local legs server-wide).
15. The run log has every stuck spell with position, wall face, the steps taken and the outcome, so positions that repeat show the hard spots.

**Config keys** (per-NPC settings in `NavigationSettings`, layers global → world → region → template → assignment, read at restart; L3 adds each to `config.yml` with a comment, a layer test, the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc) per-NPC table and its YAML block, and the PR's deploy notes):

| Key | Default | Range | § 4.27 entry to add |
|---|---|---|---|
| `corner-clearance` | `1.0` (decided 2026-11-15) | 0–2; 0 = off | "Blocks an NPC keeps between itself and a wall on the inside of a turn of its route, as far as the road allows; straight stretches may run along a wall" |
| `waypoint-margin` | `0.5` (decided 2026-11-15) | 0.2–1.5 | "How close an NPC comes to a route waypoint before it heads for the next one; smaller walks turns through the corner point, Citizens' own default is 1" |
| `recovery-wait-ticks` | `20` (decided 2026-11-15) | 0–200 | "Ticks between two recovery steps of a stuck NPC (back-off, side-step, local leg, replan)" |
| `stationary-ticks` | `60` → `40` (decided 2026-11-15) | 10–1200 | changed default and text: "Ticks in one block before Citizens reports stuck; the first recovery step starts then" |
| `no-progress-ticks` | `60` → `40` (decided 2026-11-15) | 20–1200 | changed default |
| `max-retries` | `3` | 0–10 | changed text: "Recovery steps of a stuck NPC before its route is planned again: 1 back-off, 2 side-step, 3 local leg ahead" |

**Tests (knk-test-writer; the suite that proves each behaviour):**

16. knk-core JUnit (fake `NavWorld`, fake `NpcMover`):
    1. Corner clearance: an inside corner against a wall moves the turn's waypoints out by the clearance; a 2-wide stair keeps them as far out as it can; a straight stretch along a wall is untouched; the moved waypoint keeps floor continuity and its regions.
    2. The #491 geometry (three corner blocks at one height, a slab before, a slab beside, a 7-block drop outside): the stretch keeps the corner point, and the shortcut check refuses the diagonal.
    3. `PathTargets`: the #492 cases as fake worlds: a leader below the route's end (1425 48 -516 under 1421 85 -516) gets a road plan, not a short trip; a follower beside a landing gets a target ahead on its own floor, never the flight above; stacked flights never give a target on another floor.
    4. The ladder: the order back-off → side-step → local leg → replan; one step per try with `recovery-wait-ticks` between them (fake clock); the log's count never passes the cap; `NO_PATH` ends a try without a new spell; a stuck at the same spot within 30 s continues the ladder; skipped steps are not counted.
    5. Accounting: the invariant of item 12 over a scripted run; `freed_*` by the step that worked; the stats line.
    6. Followers: the same ladder; the own leg aims ahead on the follower's floor; the followers behind keep walking; a left-behind follower's tries double up to 60 s and reset on progress or an event; `group_rejoin` stays bounded in a scripted hour.
17. knk-paper MockBukkit/Mockito: `BukkitNavWorld.freeHeight` and `blocksBody` (a slab overhead gives 2.5; a fence blocks); `CitizensNpcMover.follow` sets the margin on the local parameters only; the mover reports `STATIONARY` and `NO_PATH` from the cancel event; the new keys and their layers.
18. Plugin scenarios on a real Paper server (#421, on knk-plugin `next` with the #511 scenarios; guide "Writing a plugin scenario"); the world steps are scenarios, not "scenario later". CI's `paper-boot` server has no Citizens today, so L3 first adds a pinned Citizens build to `.github/workflows/paper-boot.yml` like WorldGuard (URL plus SHA-256, compile-only use unchanged; decided by the developer 2026-11-15, 4b.4 question 9) and registers each scenario in `PaperScenarios` with `MIN_SCENARIOS` raised. L3's scenarios, on the corner test scene (item 19):
    1. `npc-corners-line` (needs no Citizens): K&K's half on the real blocks: stretches with corner clearance, `PathTargets` targets on the NPC's own floor, the shortcut check at the stair corner.
    2. `npc-corners-walk`: 6 single NPCs and a group of 6 in `ranks` walk the scene for 90 s; assert no NPC still for more than 3 s, every stuck spell freed in at most 2 steps, no falls, trespasses 0, the counters of item 12 adding up.
    3. `npc-stuck-ladder`: an NPC walled in on three sides at a corner frees itself by back-off or side-step, the log's count never passes the cap, and no two tries come within `recovery-wait-ticks`.
    If the pinned build cannot be fetched in CI, L3 reports that as a blocker; meanwhile scenarios 2 and 3 can run on the dev server with `/knk scenario run`.
19. **The corner test scene** (`NpcCornerScene` in knk-paper `scenario/`, used by the scenarios and by a dev command `/knk npc nav scene corners`, which builds it at `testing.scenarios.origin` in `testing.scenarios.world` only while `testing.scenarios.enabled` is true and saves the route `corner-scene`). One loop, about 60 blocks: a 3-wide road with an inside 90° corner against walls on both sides and a wall-hugging straight; an outside corner round a building's corner; a 2-wide and a 1-wide passage (also L4's narrowing test); a staircase with a 90° turn at a ledge, a slab before the corner and a slab beside it and a 7-block drop on the outside (the 1411 73 -537 corner); a landing beside a wall with 2.5 blocks of headroom under an overhanging floor and a slab step before it (the 1433 44 -517 landing); a U-turn flight like the stair house.
20. Manual only (developer): the 10-minute load with 50 singles and a group of 20 on `quarry-to-keep` and on the scene (game feel and the real stair house), below.

**Known limits:**

21. Corner clearance needs room: on a 1-wide stair the NPC still walks next to the wall, and the ladder is what gets it free.
22. The waypoint margin applies to whole stretches; Citizens has no margin per waypoint.
23. Walked lines from players (NAV-18) and a K&K step controller stay Phase 7.

**Developer test (L3):**
1. Deploy the build with L3. In `config.yml` merge the keys above (the YAML in the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc)). `/knk npc status` lists `corner-clearance 1.0`, `waypoint-margin 0.5`, `recovery-wait-ticks 20`, `stationary-ticks 40`, `no-progress-ticks 40`, each with its layer.
2. With no NPCs out, wait a minute, then `/knk npc nav baseline`.
3. **The stair corner (#491).** `/knk npc nav route load quarry-to-keep`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`, 10 minutes, both directions. Stand at the upper stair house corner 1411 73 -537 and run `/knk npc nav trace 60` once. Look:
    1. Nobody falls at the corner: each NPC walks into the corner square and then turns (the trace shows the corner cell between points 267 and 270).
    2. `/knk npc nav stats`: `falls 0`; `longest still` under 3.0 s; `steps per stuck: max` 2 or less; `not freed 0`; `orders failed 0`.
    3. The run log has a line for every stuck spell with its wall face and the step that freed it.
4. **The landing and the stair house (#492, #508).** Same run, at 1433 44 -517 and in the stair house (1408–1416, y 49–62, z −489…−503; 1418 49 -519). Look: no NPC stays at the landing; no log line aims at another floor (`step 3 of 3 local leg to x y z` with y within 2 blocks of the NPC's); no "retry 4 of 3" and no burst of lines in one second; `stuck near a wall` against `trips`.
5. **A group of 20 in `ranks`.** `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20 ranks`, 10 minutes on `quarry-to-keep`. Look: the group completes trips (`groups … trips` above 0); followers stuck at the landing get free in two steps and walk on, the ones behind them pass; `own legs back` and `left behind` low; `road plans per group event: max 1`; `group_rejoin` in the tens at most, not hundreds (`curl … | grep group_rejoin`).
6. **The leader below the route's end (#492, third comment).** In the same run, watch the leader when it waits for its group at the bottom of the stair house: after the wait it walks on up the stairs; the log has no local leg to 1421 84 -516.
7. **The corner scene.** With `testing.scenarios.enabled: true` on the dev server: `/knk npc nav scene corners`, `/knk npc nav route load corner-scene`, `/knk npc nav spawn 50`, 10 minutes, then `/knk npc nav clear`, `/knk npc nav group 20 ranks`, 10 minutes. After each: `/knk npc nav stats` with `longest still` under 3.0 s, `steps per stuck: max` 2 or less, `falls 0`, `trespasses 0`.
8. **The short route through the south gate.** `/knk npc nav route load south-gate-short` (saved in Phase 4 step 9), `/knk npc nav spawn 20`, 3 minutes: the gate posts and the wall beside the gate get no stuck spells (`stuck near a wall` 0 or freed by back-off).
9. **Off.** `npc.navigation.enabled: false` and restart: as in Phase 2 step 10.

Post the `stats` output of steps 3, 5 and 7, a trace from step 3 and the run log on #521.

**Done when:** the acceptance of #508 holds on the corner scene and on `quarry-to-keep`: 50 singles and a group of 20 in `ranks` for 10 minutes each, no NPC still for more than 3 s, every stuck freed within 2 recovery steps, no falls; nobody falls at 1411 73 -537 (#491); the group completes trips on `quarry-to-keep` (#492); the counters add up (item 12).

### 4b.3 Link L4 (#522): narrowed formations and followers that finish their trip (#493, #507)

**Spacing (NAV-22):**
1. `group-lateral-spacing` (new, 1.0, decided by the developer 2026-11-15): blocks between neighbours in a row, shoulder to shoulder. At 1.0, 3 abreast need a road 3 blocks wide and 2 abreast one 2 wide; at 1.25 the same; at 1.5, 3 abreast need 4 blocks.
2. `group-spacing` keeps its name and becomes the gap between rows and in the column (default 1.5, today 2.0; decided by the developer 2026-11-15).

**Widths (NAV-22):**

3. Each formation has a list of widths (NPCs abreast), widest first; the group walks in the widest one that fits and becomes a column only where 2 abreast doesn't fit:
    1. `ranks`: `group-ranks-width`, then one fewer, down to 2, then the column.
    2. `cluster`: 3, 2, column. The loose nudge is at most a quarter of the lateral spacing and points inwards for the outer lanes, so it never makes a width wider than it fits.
    3. `escort-ring` (decided by the developer 2026-11-15, 4b.4 question 3): the rings while the road is wide enough for the rings in use (the first ring's radius 1.25 × the lateral spacing, so at 1.0 eight escorts fit a 3-wide road); then rows of 3 with the leader in the middle of the second row (a row of three ahead of it, one escort either side of it, rows of three behind); then 2 abreast (a pair ahead, the leader, pairs behind); then a column with one escort ahead of the leader and the rest behind.
    4. `column`: one width.
4. **Fit.** A width fits at a path point when its outermost lanes (± its half width) have a standable floor within one block of the path's height in the same regions (today's `GroupPath.wide` rule). The group's width is the narrowest fit over the stretch under it (rearmost slot to foremost, plus one block), as today.
5. **Hysteresis** (`group-width-hysteresis-blocks`, 3, decided by the developer 2026-11-15):
    1. Narrowing to a column is immediate (gates, doors, stairs).
    2. A narrower width that is still 2 abreast or more is taken only when it lasts longer than the hysteresis along the path; a shorter bump (a lamp post, a market stall) is passed by the lanes that don't fit stepping onto the lane next to them for those points (today's `lanePoint` already falls back), and the group keeps its width.
    3. A wider width is taken only when it fits over the stretch under the group plus the hysteresis ahead of the foremost slot.
6. **Tick cost unchanged.** Each path point stores the widest width that fits there, worked out once (lazily, for the group's lateral spacing) instead of one cached half width; the window scan stays one pass. A knk-core test counts the world queries per path point (at most one per width, once). `/knk npc nav stats` compares with Phase 4: `K&K navigation on the main thread … ms per NPC` within noise of 0.0021 ms.
7. **Events and logs:** `group_narrow` (to a narrower width, still 2 abreast or more), `group_widen` (to a wider one from 2 abreast or more), `group_fold` (to the column) and `group_reform` (from the column to 2 abreast or more). Log lines: `group <n> (<leader>, <size> NPCs) narrows to 2 abreast: the path is 2 wide at x y z`, `… widens to 3 abreast at x y z`, `… folds into a column: the path is too narrow for 2 abreast at x y z`, `… takes up 2 abreast again at x y z`. The stats line: `widths: narrows N, widens N | folds N, reforms N, folded now N | abreast now k`.

**Followers that finish their trip (NAV-23, developer decision 2026-11-14 on #507):**

8. `group-followers-finish-trip` (new, default `false`, decided by the developer 2026-11-15; a group setting resolved for the leader like the other `group-*` keys, so a world, region, NPC template or assignment can set it; the test command takes it as `/knk npc nav group <n> [formation] [profile] [finish-trip|follow-leader]`).
9. `false` (today's behaviour, now a rule): when the group's order ends and the next one starts, every follower takes its place on the new path; followers that had not reached the goal skip the rest of the trip. The new path's search for a follower's place starts at the new order's first point, so it never depends on where the old path lay (4b.1 item 7).
10. `true`: when the leader has arrived, every follower that has not reached its slot at the goal keeps the old path from its place to that slot as its own trip (a short list of path points; state `FINISHING`). It walks it with the same lanes, rule checks, trespass guard, door box and recovery as a following follower, waits at a door or district edge that stops it and walks on when the rule allows (L2's held followers), and when it reaches its slot it reports (`NavGroup` member listener `onMemberArrived(npc, goal)`, for behaviour such as a courier handing over goods), logs `<npc> (group <n>) finished its trip at x y z` and counts `group_finish_trip`. Then it follows the group's current order from wherever the group is (an own leg back if it is further than `group-rejoin-blocks`). The leader does not wait for finishing followers (they count like held followers, not in its regroup wait), and the group's result for the old order comes as today.
11. Scope (decided by the developer 2026-11-15, 4b.4 question 7): the toggle applies to a follower that is still on its way when the leader has arrived; an order that replaces a running order before the leader arrived, `Cancelled` and `Failed` release followers as today.

**Config keys** (L4 adds each to `NavigationSettings`, `config.yml` with a comment, a layer test, the [configuration reference § 4.27](../../guides/admin/plugin-configuration.md#427-npc) per-NPC table and YAML block, and the PR's deploy notes; restart):

| Key | Default | Range | § 4.27 entry to add |
|---|---|---|---|
| `group-lateral-spacing` | `1.0` (decided 2026-11-15) | 1–8 | "Blocks between neighbours in a row of a group's formation (1 = shoulder to shoulder); 3 abreast need a road 1 + 2 × this wide, rounded down to whole blocks" |
| `group-spacing` | `2.0` → `1.5` (decided 2026-11-15) | 1–8 | changed text: "Blocks between the rows of a formation and between NPCs in a column" |
| `group-width-hysteresis-blocks` | `3` (decided 2026-11-15) | 0–16 | "A group changes to a narrower width (still 2 abreast or more) or a wider one only when it lasts this many blocks along the path; a column at a gate or a stair is taken at once" |
| `group-followers-finish-trip` | `false` (decided 2026-11-15) | true/false | "When the leader turns back, followers still on their way finish their trip to the goal first and then rejoin the group (couriers); false: they follow the leader at once" |

Also § 4.27's `group-formation` and `group-ranks-width` texts: the formations narrow before they fold.

**Tests (knk-test-writer):**

12. knk-core JUnit:
    1. `Formation`: every width of every formation (slot positions, half widths, depth, front) at lateral spacing 1.0 and row spacing 1.5; the narrowed `escort-ring` shapes; the cluster nudge never widens a width.
    2. `NavGroup` on fake worlds: a road 3 → 2 → 1 → 3 wide gives narrow, fold, reform, widen in that order with the logs and events; a one-block bump changes nothing; a 2-block widening changes nothing; a gate one block long folds at once; world queries per path point bounded.
    3. The toggle: off, a follower held at a gate when the leader turns back follows the new order; on, it finishes to its slot at the goal after the gate opens, `onMemberArrived` fires once, then it follows; the leader does not wait for it; a replaced order before the leader arrived releases it; held by a region (L2) behaves the same.
13. knk-paper MockBukkit/Mockito: the new keys and their layers; the group command's `finish-trip` argument.
14. Plugin scenarios (with Citizens in `paper-boot` from L3, 4b.2 item 18), registered in `PaperScenarios`:
    1. `npc-group-narrows`: a group of 9 in `cluster` on the corner scene's 3-, 2- and 1-wide passages: 3 abreast, 2 abreast, column and back in that order, no switch at the one-block bump, trespasses 0, no stuck spell left open.
    2. `npc-group-gate-finish-trip`: a group of 6 through a scenario gate (the `ScenarioGates` helper) that closes behind the leader and opens after it turned back: with `group-followers-finish-trip: true` the held followers reach their slots at the goal first (`onMemberArrived` once each), with `false` they follow the leader at once; nobody is moved by the door; trespasses 0.
    3. `npc-group-access-change`: a group of 6 entering a scenario region whose entry is removed mid-group (fake access data, the `ScenarioRegions` helper): the followers outside stop at the edge, the ones inside walk on, all follow when entry returns; trespasses 0 (L2's behaviour, now in CI).
15. Manual only: how it looks (game feel), developer steps below.

**Known limits:**

16. Slots ahead of the leader still exist on the road line only (Phase 4 known limit 6).
17. A group narrows as a whole; single lanes stepping aside for a short bump is the only per-lane squeeze.

**Developer test (L4):**
1. Deploy the build with L3 and L4. Merge the four keys above. `/knk npc status`: `group-lateral-spacing 1.0`, `group-spacing 1.5`, `group-width-hysteresis-blocks 3`, `group-followers-finish-trip false`, each with its layer.
2. With no NPCs out, wait a minute, then `/knk npc nav baseline`.
3. **Narrowing on the corner scene** (`npc-group-narrows` checks the order in CI; this step is how it looks). `/knk npc nav scene corners`, `/knk npc nav route load corner-scene`, `/knk npc nav group 20 cluster`, three trips; then `escort-ring`; then `ranks` with `group-ranks-width: 3` (restart). Look: 3 abreast on the 3-wide road, 2 abreast in the 2-wide passage, a column in the 1-wide passage and on the stairs, the widest width again after; the log has `narrows`, `folds`, `takes up`, `widens` lines in that order; no switching on the scene's one-block bump.
4. **`quarry-to-keep` and the south gate.** `/knk npc nav route load quarry-to-keep`, `/knk npc nav stats reset`, `/knk npc nav group 20 escort-ring`, 10 minutes; then `ranks` and `cluster`. Look: the bridge and the 3-wide roads 3 abreast, the stair house a column; `widths: narrows …, folds …`; `trips` rising; `stuck near a wall` no higher than with L3 alone; `trespasses 0`; `tick … ms per NPC` and `K&K navigation on the main thread` within noise of the Phase 4 numbers. Then `south-gate-short` with `ranks`: pairs through the gate without folding (#493 comment 1).
5. **Spacing.** On the open road the rows are 1.5 blocks apart and the NPCs in a row shoulder to shoulder; compare with `group-lateral-spacing: 1.25` and `group-spacing: 2.0` (restart) and say which looks right.
6. **Followers finish their trip (#507).** `/knk npc nav route load south-gate-short`, `/knk npc nav group 20 ranks finish-trip`. When the leader is past the gate, `/gate toggle` the south gate; when the leader has turned back at the route's end, `/gate toggle` again. Look: the held followers walk through to the route's end first (`… finished its trip at x y z` lines, `group_finish_trip` up by their number), then turn and follow the group. Repeat without `finish-trip`: they follow the leader at once (Phase 4 step 9).
7. **The #490 audit re-run** (once the #486 session's walker fix is in `next`, charter note 6): Phase 1 "Audit re-run after the guards", and post the report on #490.
8. With metrics on: `curl <metrics address>/metrics | grep 'knk_npc_nav_events_total{event="group_'` shows `group_narrow`, `group_widen`, `group_fold`, `group_reform`, `group_finish_trip`.

Post the `stats` output of steps 3, 4 and 6, your notes on step 5 and the run log on #522.

**Done when:** on 3-wide roads `cluster`, `escort-ring` and `ranks` (width 3) walk 3 abreast, on 2-wide roads 2 abreast, at gates and on stairs a column, reformed after; no more trespasses or stuck spells than with today's fold; tick cost per NPC unchanged (#493); the toggle behaves as decided and is covered by tests (#507).

### 4b.4 Defaults, decided by the developer 2026-11-15

Each value below was proposed with its alternatives while the developer was away; on 2026-11-15 the developer chose the proposed value for every one ([decision on #519](https://github.com/PandiO/knk-workspace/issues/519)). The alternatives stay as the record.

1. **`group-lateral-spacing` 1.0** (shoulder to shoulder; 3 abreast fit a 3-wide road). Alternatives: (a) 1.25 (still fits 3 abreast on a 3-wide road, a little looser); (b) 1.5 (3 abreast need 4 blocks).
2. **`group-spacing` (rows and column) from 2.0 to 1.5.** Alternatives: (a) 1.0 (tightest; a column of 20 is 20 blocks long); (b) keep 2.0.
3. **Narrowed `escort-ring`:** rows of 3 with the leader in the middle of the second row, then 2 abreast and a column as the road narrows (4b.3 item 3.3). Alternatives: (a) the leader in the front row; (b) fold straight to a column.
4. **Toggle `npc.navigation.group-followers-finish-trip: false`**, overridable per group (world, region, template and assignment layers, and the group command). Alternatives: (a) the shorter name `group-finish-trip`; (b) default `true`.
5. **`corner-clearance` 1.0 block.** Alternatives: (a) 0.5 (only the cell next to the wall, waypoints at block centres move rarely); (b) 1.5; (c) 0 (off: rely on the margin and the ladder).
6. **`waypoint-margin` 0.5 block.** Alternatives: (a) 0.35 (closer to the corner point, more risk of circling a waypoint on a slab); (b) 0.75; (c) keep Citizens' 1.0 and only densify waypoints at turns.
7. **Retry spacing and the toggle's scope.** `recovery-wait-ticks` 20 (1 s). Alternatives: (a) 10; (b) 40. Toggle scope: only followers still on their way when the leader has arrived. Alternative: (c) also when an order replaces a running one before the leader arrived.
8. **Stuck detection** `stationary-ticks` and `no-progress-ticks` from 60 to 40 (2 s), so "no NPC still for more than 3 s" can hold. Alternatives: (a) 30; (b) keep 60 and read the acceptance as "freed within 3 s after the stuck is noticed".
9. **Citizens in CI's `paper-boot` server** (a pinned build with its SHA-256, compile-only use unchanged, never shaded) so the NPC scenarios walk real NPCs. Alternatives: (a) only the K&K half as a scenario (no Citizens), the walking stays a developer step; (b) a separate, optional CI job with Citizens.
10. **`group-width-hysteresis-blocks` 3.** Alternatives: (a) 0 (switch at every change); (b) 5.
11. **A left-behind follower's tries:** doubling from 5 s up to 60 s, reset by progress or an event. Alternatives: (a) every 5 s as today (the 481 rejoins); (b) a fixed 30 s.
12. **Escort ring size:** the first ring's radius 1.25 × the lateral spacing (eight escorts fit a 3-wide road at 1.0). Alternative: (a) 1.25 × `group-spacing`, as today (a 5-wide road at 1.5).

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
