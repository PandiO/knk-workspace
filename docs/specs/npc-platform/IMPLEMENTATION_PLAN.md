# NPC navigation adapter (Citizens) — Implementation Plan

**Status:** In progress since 2026-11-13 (Phase 1, developer go-ahead; parent issue [#358](https://github.com/PandiO/knk-workspace/issues/358)). Proposed 2026-11-11. Plans the shared NPC navigation capability only (K&K plans, Citizens moves); behavior, guards, garrisons and combat are separate work. Developer answers to Q1–Q7 on 2026-11-12; see "Decisions".
**Last updated:** 2026-11-13 (implementation started: parent issue #358, stair release gate, Phase 1 breakdown with the NPC event audit, CitizensAPI pin, coexistence with the Siege Survival NPC core); 2026-11-12 (Phase 0 done, Q8 decided, NAV-17 in Phase 2, NAV-18 walked lines in Phase 7); 2026-11-12 (Phase 0 route-following spike, metrics and config layering in Phase 1, NAV-14/15/16, Q8; Q4 formations decided; Phase 7b travel bubble first; Phase 7b abstract movement outside loaded areas, spread spawns and targeted replans, from the unloaded-chunk runs; developer answers Q1–Q7; road network components and the router's BLOCKED result from the unloaded-chunk test)
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

## Phase 3 — Rules stay binding (plugin)

Goal: a route planned under old rules is never walked under new ones (NAV-02), and blocked NPCs wait cheaply in the right place (NAV-03, NAV-04).

- **Recheck** every 40 ticks: the way ahead (the rest of Citizens' path, then the hops) against the current rules from the NPC's regions; a denied region or a closed gate ahead → replan (port the spike's `deniedAhead`). Time-sliced: a fixed number of NPCs per tick, never all at once.
- **Events:** `NavigationService.onGateChanged` and `onAvailabilityChanged` (and permission changes for the NPC's subject from Phase 5) notify the NPC service through a listener port, not the spike's ad-hoc hook. Replan only NPCs whose route crosses what changed (the gate, the domain): the periodic availability refresh replanned every spike NPC every 3–5 minutes for nothing (NAV-13). Replans go through the planning queue.
- **Partial route to the blocking element:** the router already returns it: `RouteResult.Status.BLOCKED` carries the route "to the last reachable point" and an explanation naming the blocked element (`BlockedExplainer`); player navigation uses it (`NavigationSession`). Walk that partial route, then WAITING with the blocking element. (The spike treated `BLOCKED` like no route, so its NPCs stopped in their tracks.) The blocking element's open event wakes the NPC (no polling); a slow safety timer (5 s) as a fallback.
- **Trespass guard** as a runtime assertion and metric (port the spike's `checkTrespass`): an NPC in a region its current rules deny is logged and counted; in dev builds also stopped and replanned.
- `NavigationResult.BLOCKED` carries the blocking element, so behavior (BEHAVIOR_MODEL §8, §17 gate confrontation) decides what to do.

**Tests:** recheck finds a newly denied region ahead and ignores regions behind; a gate event replans only NPCs whose route uses that gate; blocked → walks to the gate → waits → resumes on open; trespass counter on a fake world.

**Done when:** the stress test guide's tests A and B pass on the dev server with the production code: 0 trespasses, NPCs waiting **at** the gate or district edge, waiting cost ≤ 0.02 ms per NPC.

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
