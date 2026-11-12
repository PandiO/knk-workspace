# Citizens stress test — NPC hybrid navigation

**Status:** Done 2026-11-11: **go with caveats** (Citizens hop mode with the K&K examiner in front). Load and rule checks pass; the caveats are in [the verdict on #244](https://github.com/PandiO/knk-workspace/issues/244#issuecomment-6806008046).
**Last updated:** 2026-11-12
**Issue:** [PandiO/knk-workspace#241](https://github.com/PandiO/knk-workspace/issues/241): desk check [#242](https://github.com/PandiO/knk-workspace/issues/242), spike [#243](https://github.com/PandiO/knk-workspace/issues/243), benchmark [#244](https://github.com/PandiO/knk-workspace/issues/244)
**Branch:** knk-plugin `claude/citizens-spike` `ac3c356` (throwaway, **never merge**), on `main` `33122cf4`
**Spec:** [BEHAVIOR_MODEL §2 and §13](../specs/npc-platform/BEHAVIOR_MODEL.md#2-fit-with-the-platform-design), [DESIGN §9](../specs/npc-platform/DESIGN.md#9-navigation-reuse-and-platform-audit)
**Results:** [desk check and spike report](../reports/2026-11-10-citizens-desk-check-and-spike.md) (its §9 has the commands of the first plan); run results in [#244](https://github.com/PandiO/knk-workspace/issues/244).

The developer's plan for the Citizens verification (2026-11-10), kept as written apart from the status notes and links, followed by the results so far and the steps for the next session. The test doesn't need the guard NPC to be built yet. It uses plain player-shaped Citizens NPCs on top of the K&K navigation that already exists.

## Now (during work): desk check, in Claude Code — **done 2026-11-10**

Give this step to a Claude Code session in knk-workspace and knk-plugin. It should:

- Read knk-plugin to find the exact Paper version it targets. → Paper `26.3.build.205-stable`.
- Check that a Citizens build exists for that version, and for the planned Minecraft 26.2 update. Note how quickly Citizens followed past Minecraft releases. → Citizens 2.0.44 supports 26.1–26.3. The 26.2 update is already done: the plugin is on 26.3. Citizens' first build usually came 0–2 days after a release.
- Check the licence terms for using Citizens as a compile-only dependency. → OSL-3.0. Compile-only, never shaded or patched.
- Check the hooks: waypoint lists (`Navigator.setTarget(Iterable<Vector>)`), custom block examiners, door handling, stuck events and actions, async pathfinding. → All exist, with caveats. Waypoint lists skip examiners and doors. Examiners can't veto unless K&K's is the only one.
- Check persistence: can Citizens' own NPC saving be turned off, with an in-memory registry, so the K&K database stays the source of truth? → Yes (`createInMemoryNPCRegistry`).
- Check the player-shaped entity type and the trait API, against DESIGN §2's platform-adapter boundary. → `PLAYER` or `MANNEQUIN`; the trait API fits a thin adapter. Gap: K&K access is player-bound, so NPCs need their own access subject (DESIGN §7).
- Write a dated report in `docs/reports/` and update BEHAVIOR_MODEL §2. → [Report](../reports/2026-11-10-citizens-desk-check-and-spike.md); BEHAVIOR_MODEL §2 updated.
- Conclude go, no-go, or go with caveats, and list anything the spike must test. → **Go with caveats**, report §8.

## This afternoon: spike branch, in Claude Code (only if the desk check says go) — **done 2026-11-10**

A throwaway branch in knk-plugin that is **never merged**: `claude/citizens-spike`.

- Citizens as a compile-only dependency. → CitizensAPI `2.0.44-20261020.020503-8`, `compileOnly`, non-transitive; Citizens as softdepend.
- A debug command that spawns N player-shaped NPCs and walks them along routes from K&K navigation (road graph and walk pathfinder), passing the waypoints to Citizens. → `/knk npcspike`. Two modes: `hop` (road route in 16-block legs walked by Citizens' A*) and `dense` (walk-pathfinder cells as a waypoint list).
- A block examiner that applies a K&K movement ruleset and domain/gate access rules. → `SpikeExaminer`: the K&K `CellAccess` in front of Citizens' examiners.
- Benchmark hooks: timing per NPC, path time, stuck counter. → `/knk npcspike stats [label]`, plus a CSV row in the server log.

Added on 2026-11-11 after the first runs (`60c4ad5`, `ac3c356`):

- `recheck` works in hop mode (default 40 ticks, as player navigation): the way ahead is checked against the current entry rules and the NPC replans when it enters a denied region.
- Gate changes and availability changes (the triggers of player navigation's re-check) replan every spike NPC at once; the log says `[NpcSpike] rules changed (…)`.
- A **trespass counter**: once a second, every NPC's newly entered regions are checked against the current entry rules. `stats` shows `TRESPASSES n`; the first 20 are logged as `[NpcSpike] TRESPASS …`. "Examiner leaks" was renamed "foreign examiners stripped", which is all it ever counted.
- `set noroute wait|line` (default `wait`): with no allowed road route the NPC waits and asks again every 5 s, or when the rules change, instead of walking straight-line hops across the terrain.
- Route ends are stored in `plugins/KnightsAndKings/npcspike-routes.yml` and restored after a restart. `from`/`to` log their coordinates. Named routes: `/knk npcspike route save|load|delete <name>`, `route list`.

## Tonight: run the tests on the dev server — **runs on 2026-11-10/11, see below**

Commands: [report §9](../reports/2026-11-10-citizens-desk-check-and-spike.md#9-tonight-commands-per-step-of-the-plan). Before step 1, install Citizens 2.0.44 (a 26.3 build from 2026-11-01 or later) with the config settings in [report §8](../reports/2026-11-10-citizens-desk-check-and-spike.md#8-caveats-the-adapter-must-own-and-the-spike-must-test). To watch MSPT, TPS and heap alongside, see [performance metrics and capacity](performance-metrics-and-capacity.md).

1. Build and deploy the spike branch to the dev server. Check that Citizens loads cleanly. → Done.
2. Spawn 10 NPCs on a castle-map route. Check that they follow it and that the timing and stuck counters report data. → Done.
3. Step up to 50, then 100 NPCs (100 is the main target). Record the tick cost per NPC, MSPT/TPS, path time and stuck count at each step. → 50 done; 100 skipped (bracketed by 50 and 200).
4. If 100 looks healthy, run 200 (the stress test). → Done.
5. If there's time, run the behaviour scenarios:
   - A gate closes mid-route (replanning, block examiner). → Done, rerun pending (see below).
   - Access permission is removed mid-route (rules stay binding). → **Failed**, rerun pending (see below).
   - A route goes through unloaded chunks (pause and resume, no stuck NPCs).
   - Many route requests at once (queueing, path time).
   - Walls, stairs, ladders, doors. → Stairs seen in passing (stuck spots below).
6. Write the numbers into the issue for step 3 ([#244](https://github.com/PandiO/knk-workspace/issues/244)). → 200-hop posted; the rest still to post.

Also from the desk check: compare `pathfinder citizens` with `citizens_async`, `player` with `mannequin`, and `dense` with and without `recheck`. Check that examiner leaks stay 0 and that no NPC ever passes a closed gate.

## Results so far (2026-11-10/11)

Baseline 2.34 ms (no NPCs). All runs in hop mode with the default settings unless noted.

| Run | NPCs | MSPT mean / p95 | ms per NPC | Trips | Stuck | Notes |
|---|---|---|---|---|---|---|
| 200-hop | 200 | 8.52 / 10.79 | 0.031 | 672 | 5,256 | 20 TPS; start point was a choke point; region lookups flood the API (about 10/s) |
| 50-hop-clean | 50 | 4.55 / 7.56 | 0.044 | 100 | 347 | start moved to open road; stuck per trip 3.5 (was 7.8) |
| gate-closed-hop | 50 | 22.75 / 41.91 | 0.408 | 50 | 1,355 | nobody passed (seen); 0 blocked by K&K: the gate is solid, the K&K rule was not tested |
| gate-reopened-hop | 50 | 7.45 / 15.05 | 0.102 | 90 | 985 | recovered; 760 "no path to hop" near the gate |
| 50-dense (short route) | 50 | 3.76 / 4.90 | 0.028 | 15 | 1,500 | most NPCs never moved: capture box over 64 chunks; examiner 0 calls |
| access-removed | 50 | 20.24 / 37.35 | 0.358 | 40 | 2,677 | **failed: about 2/3 walked into the denied district**; K&K blocked 224,497 cells for the rest |
| 50-hop-6-entry-deny | 50 | 46.98 / 85.81 | 0.893 | 0 | 7,196 | entry left denied by mistake; straight-line fallback took NPCs over ice to the island |
| 50-hop-h6 | 50 | 4.12 / 5.47 | 0.036 | 71 | 424 | `hop 6` is worse (6.0 stuck per trip): not a route-choice problem |
| access-removed-v2 | 50 | 3.37 / 3.89 | 0.014 | 0 | 0 | **pass**: `ac3c356`, baseline 2.67; event replan, NPCs wait, 0 trespasses |
| access-restored-v2 | 50 | 3.82 / 5.34 | 0.023 | 100 | 294 | continued at once |
| gate-closed-v2 | 50 | 3.68 / 4.56 | 0.020 | (100) | (352) | **pass**: nobody passed, NPCs wait; cumulative counters |
| gate-reopened-v2 | 50 | 4.29 / 5.86 | 0.032 | (200) | (597) | moved again when the opening animation finished |
| chunks (2026-11-12) | 20 | 3.85 / 4.85 | 0.099 | 20 | 1,439 | view distance 25: no chunk unloads; almost all stuck events at one spot on the return (1373 53 -69 → hop 1377 52 -84) |
| chunks-v2 | 20 | 2.04 / 2.51 | 0.011 | 0 | 0 | view/simulation 10: all NPCs stopped at the edge of the loaded area (capture refuses unloaded chunks); spawning 20 at once: 48.8 ms tick |
| chunks-v3 | 20 | 3.77 / 5.81 | 0.101 | 19 | 72 | **pass**: walked with the NPCs, teleported away and back: pauses 57 = resumes 57 |

What this shows:

- **Load passes.** Walking NPCs cost 0.03–0.04 ms each; 200 stayed at 20 TPS.
- **NPCs that cannot reach their goal are expensive** (0.36–0.89 ms each), because every retry runs Citizens' A* until it gives up. The real build needs a wait state woken by gate and access events, group navigation (one leader plans for the group), and bounded detours on the K&K road graph (including hidden routes), not Citizens' A*.
- **Access removed mid-route failed** because a hop leg kept the access it was planned with, and once inside, the entry rule no longer applies. The spike now rechecks (see above); the rerun decides.
- **Stuck spots are Citizens' movement on stair corners** (a turn where a corner meets a wall and a one-block step next to a stair, for example 1411 50 -496), not route choice. NPCs get through eventually. Likely fix in the real build: K&K waypoints on stair landings and turns.
- **Dense mode is dropped**: it skips the K&K examiner, hits the 64-chunk capture limit, and got stuck about 100 times per trip.
- **Rule checks pass with the recheck (v2 runs):** 0 trespasses with entry removed and with the gate closed; waiting NPCs cost 0.014–0.020 ms each. Gap: NPCs stop where they are, while player navigation leads to the edge of the region or the gate; the real adapter should walk to the blocking element, then wait.

**Verdict (2026-11-11): go with caveats.** The caveats the real build must own (recheck and event replans, wait state, partial route to the blocking element, group navigation, bounded detours on the road graph, stair corners, NPCs out of player region handling, NPC access identity, no dense mode) are listed in [the verdict on #244](https://github.com/PandiO/knk-workspace/issues/244#issuecomment-6806008046).

## Rule-check rerun (done 2026-11-11: tests A and B pass, C not run)

Deploy `claude/citizens-spike` `ac3c356` or later (`./gradlew :knk-paper:dev`). The startup line shows `KnightsAndKings 0.1.0+ac3c356…`.

**Before you start**

1. Check that the access subject has no `knk.region.bypass`: `/knk npcspike stats` warns if they do.
2. Save the routes once (they survive restarts from now on):
   - Outside the town → just behind the South Gate (South Gate Square): `/knk npcspike from`, `/knk npcspike to`, `/knk npcspike route save south-gate`.
   - Start on open road → just inside The Keep past the Keep Gate: `/knk npcspike from`, `/knk npcspike to`, `/knk npcspike route save keep-gate`.
3. With no NPCs: `/knk npcspike baseline`.
4. During each test, copy the in-game `stats` output (the `TRESPASSES`, `failures:` and settings lines): only the CSV row goes to the log.

**Test A: access removed mid-route (deciding test)**

1. Make sure the subject may enter the Residential District. `/knk npcspike route load south-gate`, `/knk npcspike clear`, `/knk npcspike reset`, `/knk npcspike spawn 50 hop`. Wait about 2 min.
2. While NPCs are walking, remove entry to the Residential District.
3. Watch the log for `[NpcSpike] rules changed (availability)`: it tells whether the change arrives as an event or only through the 40-tick recheck. Watch the NPCs: the ones outside should stop at the district edge; the ones already inside may finish their trip and leave, but must not come back in.
4. After 3 min: `/knk npcspike stats access-removed-v2`.
5. Restore entry. Waiting NPCs should continue within about 5 s. After 2 min: `/knk npcspike stats access-restored-v2`.

**Pass:** `TRESPASSES 0`, nobody re-enters, and MSPT close to the walking cost (not the 20–47 ms of the earlier runs). If there are `TRESPASS` lines, their timestamps against the moment you removed entry show how long the plugin's domain cache takes to catch up.

**Test B: Keep Gate closed mid-route**

1. `/knk npcspike route load keep-gate`, `clear`, `reset`, `spawn 50 hop`. Wait until several NPCs are on their way to the gate.
2. `/gate close keep gate`. Expect `[NpcSpike] rules changed (gate door …)` in the log and NPCs waiting at the gate.
3. After 3 min: `/knk npcspike stats gate-closed-v2`.
4. `/gate open keep gate`. Watch the gateway for 2 min: where do NPCs stand, and do they get through? After 3 min: `/knk npcspike stats gate-reopened-v2`.

**Pass:** nobody on the keep side while the gate is closed (by eye too), MSPT well below the earlier 22.75 ms, and trips climbing again after reopening. Fewer "no path to hop" after reopening than the earlier 760.

**Test C: unloaded chunks**: **pass** on 2026-11-12 (chunks-v3: pauses 57 = resumes 57). Earlier runs showed NPCs stop at the edge of the loaded area (NAV-12). To test pause and resume, go **with** the NPCs to the far part of the route, then teleport back to spawn so their chunks unload, wait 2 min and go back. Original steps:

1. A route of 150+ blocks (save it as `long`), `spawn 20 hop`.
2. Fly well away (more than the view distance) for 2 min, then come back.
3. `/knk npcspike stats chunks`.

**Pass:** `chunk-unload pauses` equals `resumes`, and no NPC stands still for good.

**Finishing:** `/knk npcspike clear`. Send the server log and the chat stats; the results go to [#244](https://github.com/PandiO/knk-workspace/issues/244) with a go or no-go recommendation.

**Decision rule:** go when tests A and B pass with zero trespasses. No-go (or rethink) if an NPC ever enters a region or crosses a gate the current rules deny.

## Later

- Run the same scenarios with siege attackers as plain mobs, for comparison.
- Repeat on the closed alpha. Results are indicative only, so recheck on the live host later.
- Tuning, not needed for the decision: `citizens` vs `citizens_async` at 100 NPCs, `player` vs `mannequin`, `set inflight 1` vs `16`, doors on and off.
