# Citizens stress test — NPC hybrid navigation

**Status:** Desk check done (go with caveats) and spike built on 2026-11-10. Dev-server runs ("Tonight") not done yet.
**Last updated:** 2026-11-10
**Issue:** [PandiO/knk-workspace#241](https://github.com/PandiO/knk-workspace/issues/241): desk check [#242](https://github.com/PandiO/knk-workspace/issues/242), spike [#243](https://github.com/PandiO/knk-workspace/issues/243), benchmark [#244](https://github.com/PandiO/knk-workspace/issues/244)
**Branch:** knk-plugin `claude/citizens-spike` `db81b0c` (throwaway, **never merge**), on `main` `33122cf4`
**Spec:** [BEHAVIOR_MODEL §2 and §13](../specs/npc-platform/BEHAVIOR_MODEL.md#2-fit-with-the-platform-design), [DESIGN §9](../specs/npc-platform/DESIGN.md#9-navigation-reuse-and-platform-audit)
**Results:** [desk check and spike report](../reports/2026-11-10-citizens-desk-check-and-spike.md). Its §9 has the exact command for each step below.

The developer's plan for the Citizens verification (2026-11-10), kept as written apart from the status notes and links. The test doesn't need the guard NPC to be built yet. It uses plain player-shaped Citizens NPCs on top of the K&K navigation that already exists.

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

## This afternoon: spike branch, in Claude Code (only if the desk check says go) — **done 2026-11-10, not run on a server**

A throwaway branch in knk-plugin that is **never merged**: `claude/citizens-spike`.

- Citizens as a compile-only dependency. → CitizensAPI `2.0.44-20261020.020503-8`, `compileOnly`, non-transitive; Citizens as softdepend.
- A debug command that spawns N player-shaped NPCs and walks them along routes from K&K navigation (road graph and walk pathfinder), passing the waypoints to Citizens. → `/knk npcspike`. Two modes: `hop` (road route in 16-block legs walked by Citizens' A*) and `dense` (walk-pathfinder cells as a waypoint list).
- A block examiner that applies a K&K movement ruleset and domain/gate access rules. → `SpikeExaminer`: the K&K `CellAccess` in front of Citizens' examiners.
- Benchmark hooks: timing per NPC, path time, stuck counter. → `/knk npcspike stats [label]`, plus a CSV row in the server log.

## Tonight: run the tests on the dev server

Commands: [report §9](../reports/2026-11-10-citizens-desk-check-and-spike.md#9-tonight-commands-per-step-of-the-plan). Before step 1, install Citizens 2.0.44 (a 26.3 build from 2026-11-01 or later) with the config settings in [report §8](../reports/2026-11-10-citizens-desk-check-and-spike.md#8-caveats-the-adapter-must-own-and-the-spike-must-test). To watch MSPT, TPS and heap alongside, see [performance metrics and capacity](performance-metrics-and-capacity.md).

1. Build and deploy the spike branch to the dev server. Check that Citizens loads cleanly.
2. Spawn 10 NPCs on a castle-map route. Check that they follow it and that the timing and stuck counters report data.
3. Step up to 50, then 100 NPCs (100 is the main target). Record the tick cost per NPC, MSPT/TPS, path time and stuck count at each step.
4. If 100 looks healthy, run 200 (the stress test).
5. If there's time, run the behaviour scenarios:
   - A gate closes mid-route (replanning, block examiner).
   - Access permission is removed mid-route (rules stay binding).
   - A route goes through unloaded chunks (pause and resume, no stuck NPCs).
   - Many route requests at once (queueing, path time).
   - Walls, stairs, ladders, doors.
6. Write the numbers into the issue for step 3 ([#244](https://github.com/PandiO/knk-workspace/issues/244)).

Also from the desk check: compare `pathfinder citizens` with `citizens_async`, `player` with `mannequin`, and `dense` with and without `recheck`. Check that examiner leaks stay 0 and that no NPC ever passes a closed gate.

## Later

- Run the same scenarios with siege attackers as plain mobs, for comparison.
- Repeat on the closed alpha. Results are indicative only, so recheck on the live host later.
