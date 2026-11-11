# NPC navigation adapter (Citizens) — Implementation Plan

**Status:** Proposed 2026-11-11, not started. Plans the shared NPC navigation capability only (K&K plans, Citizens moves); behavior, guards, garrisons and combat are separate work. The phase order and the open questions (Q1–Q7) need the developer's go before Phase 1.
**Last updated:** 2026-11-11
**Issue:** [PandiO/knk-workspace#241](https://github.com/PandiO/knk-workspace/issues/241) (verification: desk check #242, spike #243, benchmark #244); parent [KNG-36](https://linear.app/kngpandi/issue/KNG-36/design-shared-npc-traits-and-pathfinding-platform), [#146](https://github.com/PandiO/knk-workspace/issues/146), [#234](https://github.com/PandiO/knk-workspace/issues/234)
**Sources:** [BEHAVIOR_MODEL.md §2](BEHAVIOR_MODEL.md#2-fit-with-the-platform-design) (requirements NAV-01–NAV-11) and §13; [DESIGN.md](DESIGN.md) §2, §6, §7, §9; [desk check and spike report](../../reports/2026-11-10-citizens-desk-check-and-spike.md); [Citizens stress test guide](../../guides/citizens-stress-test.md); [verdict on #244](https://github.com/PandiO/knk-workspace/issues/244#issuecomment-6806008046); code read at knk-plugin `main` `33122cf` and the spike `claude/citizens-spike` `ac3c356`.

**Branches:** one standing branch per repo, `claude/npc-navigation`, created only when a phase first touches that repo (knk-plugin from `main`; knk-web-api from `master` and knk-web-app from `main` from Phase 5). Claim the work in `ACTIVE_SESSIONS.md` first. The spike branch `claude/citizens-spike` is **never merged**: port its pieces with tests, don't cherry-pick.

**Build notes:** `./gradlew build -x deployToDevServer` in knk-plugin (plain `build` deploys). Gradle runs on Java 21 and compiles with the Java 25 toolchain. CitizensAPI stays `compileOnly`, non-transitive, never shaded (OSL-3.0); Citizens is a `softdepend`, and the plugin must load and run without it (NPC navigation then reports "unavailable").

| Phase | Repos | Size | Depends on | Shippable alone | Requirements |
|---|---|---|---|---|---|
| 1 — Runtime and guard rails | plugin | M | Q1, Q2 | yes (no gameplay) | NAV-08, NAV-10 |
| 2 — Navigate one NPC | plugin | L | 1; Q3 | yes (admin command) | NAV-01, NAV-03, NAV-11 |
| 3 — Rules stay binding | plugin | M | 2 | yes | NAV-02, NAV-03, NAV-04 |
| 4 — Groups | plugin | M | 3; Q4 | yes | NAV-05 |
| 5 — NPC access identity | web-api, plugin, web-app | L | 2; Q5, DESIGN O06 | yes | NAV-09 |
| 6 — Detours and hidden routes | web-api, plugin, web-app | L | 3; Q6 | yes | NAV-06 |
| 7 — Movement quality | plugin | M | 2 | yes | NAV-07, NAV-11 |
| 8 — Benchmark gate | plugin (dev server) | S | 3, 4 (5–7 as built) | — | §13 budgets |

Phases 5, 6 and 7 are independent of each other and can run in any order after their dependencies. Guards (BEHAVIOR_MODEL §16) need at least Phases 1–5.

---

## Phase 1 — Runtime and guard rails (plugin)

Goal: Citizens is wired in safely, and NPCs can exist without touching player systems. No navigation yet.

**knk-core** (Bukkit-free, new package `net/knightsandkings/knk/core/npc/nav/`):
- `NpcMover` port: spawn/despawn a mover, set a hop target with an examiner, cancel, position, "is navigating". The behavior and navigation layers only see this port (DESIGN §2 platform-adapter boundary); no Citizens type in knk-core.
- `NavigationResult` (ARRIVED, BLOCKED with reason and blocking element, FAILED with reason, CANCELLED) for DESIGN §6's failure policy.

**knk-paper** (new package `paper/npc/`):
- `CitizensNpcRuntime`: in-memory registry (`CitizensAPI.createInMemoryNPCRegistry`, `SHOULD_SAVE = false`), created only when Citizens is enabled; shutdown removes it. Per-NPC defaults from NAV-10: pathfinder `CITIZENS` (configurable `CITIZENS_ASYNC`), `destinationTeleportMargin(-1)`, a K&K stuck action (never teleport), stationary ticks, `pathDistanceMargin(1.5)`, `PATHFINDER_OPEN_DOORS = false`.
- `CitizensNpcMover` implements `NpcMover`.
- `NpcEntities.isNpc(Entity)` (`hasMetadata("NPC")`), and an **audit of every player listener** (NAV-08). At least `listeners/WorldGuardRegionListener` (the 10 API calls per second in the 200-NPC run), session/telemetry tracking, player notifications, permissions sync, combat tag, vanish and chat. `HubRulesListener` already filters NPCs. Each one: skip NPCs, with a test.
- Config `npc.navigation.*` in `config.yml`: enabled (default off), pathfinder, max plans in flight, hop spacing (16), recheck ticks (40), stationary ticks (60).
- Startup log line: Citizens version or "Citizens not present: NPC navigation unavailable".

**Tests:** runtime off without Citizens; listener audit tests (an NPC `PlayerMoveEvent` does not reach the region resolver); config defaults.

**Done when:** the plugin loads with and without Citizens, and a spawned test NPC walking about makes no API calls and no player-system side effects.

## Phase 2 — Navigate one NPC (plugin)

Goal: one NPC walks a K&K-planned route under a caller-supplied ruleset (DESIGN §6), hop by hop.

**knk-core:**
- `AccessSubject` port: what the access code needs from a mover (identity, bypass, permissions/gate rights, current regions). `NavigationAccess.policyFor`, `WalkAccessFactory` and `GateAvailability` take a `Player` today; add overloads that take an `AccessSubject`, with a `PlayerAccessSubject` adapter so player navigation is unchanged. Until Phase 5, NPCs use a **configured access profile** (template-level allow/deny lists; Q3), never a borrowed player.
- `HopPlanner`: road route polyline → hops every N blocks, floor-snapped (spike `CitizensSpike.resample` / `snapToFloor`), plus the off-road stretch to the goal.
- `NpcNavigationService`: per-NPC state machine (IDLE → QUEUED → PLANNING → MOVING → WAITING / PAUSED), a planning queue with a limit on plans in flight, bounded retries per hop (DESIGN §6: 3), and a `NavigationResult` back to the caller.

**knk-paper:**
- `KnkBlockExaminer`: the composite examiner (port `SpikeExaminer`): the K&K `CellAccess` first (NOT_STANDABLE / IMPASSABLE), then Citizens' `MinecraftBlockExaminer` and `DoorExaminer` (only when the ruleset allows doors), cells outside the capture box blocked; check and strip foreign examiners after each `setTarget`.
- Road planning through the existing router (`AStarRouter`) with the NPC's position for the exit rules (port the spike's `spikeRoadPolyline` as a proper API on `NavigationService` or a new `NpcRoutePlanner`).
- **No route → WAITING** (NAV-03); never a straight-line fallback across terrain. An end too far from a road → walk-only leg, short hops.
- Chunk unload → PAUSED, respawn → replan (NAV-11).
- Admin command `/knk npc nav <spawn|goto|stats|clear>` for testing, replacing `/knk npcspike` (from/to, stored routes and stats as in the spike).

**Tests:** `HopPlanner` (spacing, stairs, end snapping); state machine (retry budget, waiting, pause/resume) against a fake `NpcMover`; examiner ordering (a K&K veto beats a later PASSABLE); `PlayerAccessSubject` gives the same verdicts as today.

**Done when:** on the dev server, one NPC and then 50 walk the stored `south-gate` route back and forth with the spike's numbers or better (about 0.03 ms per NPC, no examiner leaks).

## Phase 3 — Rules stay binding (plugin)

Goal: a route planned under old rules is never walked under new ones (NAV-02), and blocked NPCs wait cheaply in the right place (NAV-03, NAV-04).

- **Recheck** every 40 ticks: the way ahead (the rest of Citizens' path, then the hops) against the current rules from the NPC's regions; a denied region or a closed gate ahead → replan (port the spike's `deniedAhead`). Time-sliced: a fixed number of NPCs per tick, never all at once.
- **Events:** `NavigationService.onGateChanged` and `onAvailabilityChanged` (and permission changes for the NPC's subject from Phase 5) notify the NPC service through a listener port, not the spike's ad-hoc hook. Replans go through the planning queue.
- **Partial route to the blocking element:** reuse player navigation's blocked handling (`NavigationSession`, `BlockedExplainer`): plan to the last allowed point before the gate or region edge, walk there, then WAITING with the blocking element. The blocking element's open event wakes the NPC (no polling); a slow safety timer (5 s) as a fallback.
- **Trespass guard** as a runtime assertion and metric (port the spike's `checkTrespass`): an NPC in a region its current rules deny is logged and counted; in dev builds also stopped and replanned.
- `NavigationResult.BLOCKED` carries the blocking element, so behavior (BEHAVIOR_MODEL §8, §17 gate confrontation) decides what to do.

**Tests:** recheck finds a newly denied region ahead and ignores regions behind; a gate event replans only NPCs whose route uses that gate; blocked → walks to the gate → waits → resumes on open; trespass counter on a fake world.

**Done when:** the stress test guide's tests A and B pass on the dev server with the production code: 0 trespasses, NPCs waiting **at** the gate or district edge, waiting cost ≤ 0.02 ms per NPC.

## Phase 4 — Groups (plugin)

Goal: groups plan once (NAV-05, developer request).

- `NavGroup`: a leader (or a few scouts) plans the road route; followers get the same hops with a formation offset (column by default; Q4) and follow the leader's progress. One blocked state, one wake-up for the group.
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

- Waypoints on stair landings and turns: from the road geometry (vertices on stairs) or a walk-grid scan of the hop's stretch; a hop target never on a stair corner.
- Stuck handling: classify stuck spots (log position and the hop), try one local walk-pathfinder leg around the spot before counting a retry.
- Run the stress test guide's test C (unloaded chunks) on the production code.
- Measure `CITIZENS` vs `CITIZENS_ASYNC` and `PLAYER` vs `MANNEQUIN` (Q2).

**Done when:** stuck events per trip on the clean route drop well below the spike's 3.5, and test C passes (pauses = resumes, no NPC stuck for good).

## Phase 8 — Benchmark gate (dev server, then closed alpha)

- Repeat the spike scenarios with the production code: 50, 100 and 200 NPCs walking; gate closed and reopened; access removed and restored; groups; unloaded chunks.
- Metrics through `PluginMetrics` (KNG-232): ms per NPC, plans per second, queue wait, stuck per trip, trespasses (must be 0), waiting NPCs.
- Confirm BEHAVIOR_MODEL §13's proposed budgets (≤ 10 ms per tick at 100 active guards) and write them into §13 as decided; recheck later on the live host.

## Open questions

| ID | Question | Proposal |
|---|---|---|
| Q1 | Where the code lives: packages in knk-core/knk-paper, or a new Gradle module (`knk-npc`)? | Packages first (`core/npc/nav/`, `paper/npc/`); split later if the NPC platform grows. |
| Q2 | Entity type and pathfinder: `PLAYER` or `MANNEQUIN`; `CITIZENS` or `CITIZENS_ASYNC`? | Start with `PLAYER` and `CITIZENS` (what the spike measured); compare in Phase 7. |
| Q3 | NPC access before Phase 5: a configured profile per template, or wait for Phase 5? | Configured profile (allow/deny region and gate lists), so Phases 2–4 aren't blocked. |
| Q4 | Group formation: column, pairs, loose cluster; per group type? | Column by default; formation per assignment later. |
| Q5 | Gate pass-through for NPCs (DESIGN §7, O07): part of Phase 5 or its own phase? | Its own follow-up after Phase 5; guards first use gates they may open. |
| Q6 | Who may use hidden routes and how they're authored? | Flags on road edges in the web-app road editor; who may use them by faction/side and role. |
| Q7 | Citizens release pinning: which snapshot, and the update check on each Minecraft update? | Pin a timestamped 2.0.44 snapshot; test each update on the dev server with the planned Paper build first (desk check report §8.6). |
