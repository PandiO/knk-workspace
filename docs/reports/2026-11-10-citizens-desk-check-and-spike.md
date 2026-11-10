# Citizens desk check and spike branch — 2026-11-10

**Status:** Desk check done (verdict: **go with caveats**); spike built and compiled, unit-tested, **not run on a server**. The spike branch is local only: this session could not push to knk-plugin (see §7).
**Last updated:** 2026-11-10
**Issue:** [PandiO/knk-workspace#242](https://github.com/PandiO/knk-workspace/issues/242) (desk check) and [#243](https://github.com/PandiO/knk-workspace/issues/243) (spike), parent [#241](https://github.com/PandiO/knk-workspace/issues/241); spec [BEHAVIOR_MODEL §2, §13](../specs/npc-platform/BEHAVIOR_MODEL.md) on `claude/npc-behavior-model` (PR #235)
**Base:** knk-plugin `main` `33122cf4`; Citizens2 `master` `62b9265d` (2026-11-01, version `2.0.44-SNAPSHOT`); CitizensAPI `master` `e776141` (2026-10-20); Citizens Maven repo `maven.citizensnpcs.co`; Paper build list (`fill.papermc.io`).

**Source limits.** Everything below was read from the Citizens source and the Maven/Paper metadata, not from a running server. Minecraft 1.21.x release dates are from memory and were not rechecked; the 26.x dates come from Paper's first build of each version (26.3) and web sources (26.1, 26.2). Licence notes are a reading of the licence text, not legal advice.

## 1. Summary

| Question (#242) | Answer | Verdict |
|---|---|---|
| Paper version knk-plugin targets | Paper API `26.3.build.205-stable` (Minecraft 26.3), Java 25, `api-version: "26.3"` | — |
| Citizens build for it | Yes: Citizens 2.0.44 has `v26_1_R1`, `v26_2_R1`, `v26_3_R1` modules; dev builds published as timestamped snapshots, newest 2026-11-01 | OK |
| "Planned 26.2 update" | **Stale premise.** The KNG-182 branch is called `claude/mc-26.2-upgrade` but targets 26.3 and is merged; the plugin is on 26.3 already. The next update is whatever follows 26.3 | Note |
| How fast Citizens followed releases | First build 0–2 days after each release since 1.21.2; 12 days at the 26.1 version-scheme change; fixes follow for weeks (§2) | OK |
| Licence for compile-only use | OSL-3.0 (Citizens2 and CitizensAPI). Compile against the API, don't shade or modify Citizens (§3) | OK |
| `Navigator.setTarget(Iterable<Vector>)` | Exists, but **without pathfinding**: no block examiners, no door opening, no replanning on that path (§4.1) | Caveat |
| Custom block examiners | Exist, but Citizens combines them "first PASSABLE wins": a K&K examiner can only veto if it is the **only** examiner and wraps Citizens' ones (§4.2) | Caveat |
| Door handling | `DoorExaminer` opens and closes doors and fence gates on A* paths; off by default (§4.3) | OK |
| Stuck events and actions | `NavigationStuckEvent`, replaceable `StuckAction`; stuck detection is **off** by default; the built-in teleport action would skip gates (§4.4) | Caveat |
| Async pathfinding | `CITIZENS_ASYNC`: A* on a worker pool over chunk snapshots; new (2025-09) and had leak fixes in 2026-07 (§4.5) | Caveat |
| Persistence off | `CitizensAPI.createInMemoryNPCRegistry` + `SHOULD_SAVE=false`; nothing written to `saves.yml` (§5) | OK |
| Player-shaped entity, trait API vs DESIGN §2 | `PLAYER` or `MANNEQUIN`; trait API fits a thin platform adapter (§6) | OK |

**Outcome: go with caveats.** The hybrid (K&K plans, Citizens moves) is possible on the current versions. Citizens' defaults don't keep the K&K rules binding on their own. The adapter has to own six things, listed in §8. The spike puts all six in place and counts any breach.

## 2. Versions and release lag

knk-plugin `main` builds against `io.papermc.paper:paper-api:26.3.build.205-stable` (`gradle.properties`), Java 25 toolchain, `plugin.yml` `api-version: "26.3"`. Citizens 2.0.44 (`pom.xml`) builds `v26_1_R1`, `v26_2_R1` and `v26_3_R1`. The Maven repo has only snapshots (`2.0.44-SNAPSHOT`), but keeps every timestamped build since `2.0.44-20260917.123000-1`, so a build can be pinned exactly. CitizensAPI's newest is `2.0.44-20261020.020503-8`.

| Minecraft | Release | First Citizens commit for it | Lag |
|---|---|---|---|
| 1.21.2 | 2024-10-22 | 2024-10-24 "Initial update to 1.21.2" | 2 d |
| 1.21.4 | 2024-12-03 | 2024-12-04 "Update to 1.21.4" | 1 d |
| 1.21.6 | 2025-06-17 | 2025-06-18 "Initial update to 1.21.6" | 1 d |
| 1.21.7 | 2025-06-30 | 2025-06-30 "Update to 1.21.7" | 0 d |
| 1.21.9 | 2025-09-30 | 2025-10-01 "Initial 1.21.9 update. Known issue with player skins." | 1 d |
| 1.21.10 | 2025-10-07 | 2025-10-08 | 1 d |
| 1.21.11 | 2025-12-09 | 2025-12-10 "Preliminary update" | 1 d |
| 26.1 | 2026-03-24 | 2026-04-05 "Update to 26.1 (preliminary)" | 12 d |
| 26.2 | 2026-06-16 | 2026-06-18 "Initial update to 26.2 (untested)"; fixes 07-07, 08-31 | 2 d |
| 26.3 | 2026-09-15 (Paper build 3) | 2026-09-17 "Initial 26.3 update. Still need to fix player advancements" | 2 d |

For comparison, Paper's first **stable** 26.3 build came on 2026-10-11, 26 days after release, and 26.2's on 2026-07-26. K&K waits for Paper stable anyway, so Citizens has not been the slower dependency. The real risk is the "initial/untested" quality of the first builds: after a Minecraft update, test the Citizens dev build with the Paper build you plan to run before upgrading the server.

## 3. Licence

Citizens2 and CitizensAPI are both under the **Open Software License 3.0** (`LICENSE` in both repos). OSL is a copyleft licence for *derivative works of Citizens*. Its §5 ("External Deployment") also counts running a modified copy for others over a network as distribution.

How that affects K&K:

- **Compile-only against the API, not shaded, not modified:** the server admin installs the Citizens jar, and the K&K jar has no Citizens code in it. Many closed plugins use Citizens like this. The spike does exactly this (`compileOnly(...) { isTransitive = false }`).
- **Don't fork or patch Citizens and run the fork.** Under §5 we would then have to publish the source of the modified Citizens. Workarounds belong in K&K code (the adapter), not in a patched Citizens.
- **Don't copy Citizens source into knk-plugin.** That includes copying `DoorExaminer` instead of calling it.
- knk-plugin has no licence file (all rights reserved). Nothing in OSL conflicts with that as long as the points above hold.

This is a reading of the licence text, not legal advice. If K&K ever sells or redistributes the plugin itself, ask someone qualified.

## 4. Hooks

### 4.1 Waypoint lists: `Navigator.setTarget(Iterable<Vector>)`

It exists (`CitizensAPI ai/Navigator.java:150`). The Javadoc says it moves between the points "using the Citizens movement logic *without* pathfinding". The implementation (`Citizens2 npc/ai/CitizensNavigator.java:401`) picks the strategy by the pathfinder type:

- `CITIZENS` / `CITIZENS_ASYNC` → `AStarNavigationStrategy(npc, path, params)`, which wraps the list in `new Path(list)` with **empty callbacks** (`Path.java:28`);
- `MINECRAFT` (the **default** of `npc.pathfinding.pathfinder-type`) → `MCNavigationStrategy`, vanilla navigation between the points.

What this means for K&K:

- No Citizens block examiner sees a waypoint path, so the K&K rules hold only as far as the K&K planner applied them when it planned.
- Citizens does not open doors on it. No door or ladder callbacks are attached.
- Citizens never replans it. A gate that closes after planning is just a wall: the NPC walks into it and gets stuck. K&K must recheck the path itself, as player navigation does every `RECHECK_TICKS` = 40 ticks.
- K&K walk points are floor positions (`WalkPath.points()`). Citizens wants feet positions, so add +1 to y.

So waypoint lists suit **dense** K&K walk paths on open ground, plus a K&K recheck. For long road routes with doors and gates, the better split is K&K road route → **hops** that Citizens' A* walks under the K&K examiner (§4.2). The spike builds and measures both modes.

### 4.2 Custom block examiners

`BlockExaminer` has `canStandAt`, `isPassable` (`PASSABLE`/`IMPASSABLE`/`IGNORE`) and `getCost`. You add one with `NavigatorParameters.examiner()` and clear them with `clearExaminers()`. How Citizens combines them (`CitizensAPI astar/pathfinder/VectorNode.java:183`):

- the **first** examiner that answers `STANDABLE` wins, and so does the **first** that answers `PASSABLE`;
- an `IMPASSABLE` answer **does not veto**. Citizens moves on to the next examiner, and `MinecraftBlockExaminer` will usually say `PASSABLE`.

On every `setTarget`, Citizens copies the default parameters into fresh local parameters and **appends** examiners (`CitizensNavigator.java:375–388`):

- `FallingExaminer` when the fall distance ≠ −1;
- `DoorExaminer` when the NPC's `PATHFINDER_OPEN_DOORS` metadata, or the setting `npc.pathfinding.citizens.open-doors`, is on;
- `BoundingBoxExaminer` when `check-bounding-boxes` is on.

An appended `DoorExaminer` would answer `PASSABLE` for a door that K&K denies.

**How to keep DESIGN §6/§7 binding:**

1. Install **one** examiner that puts the K&K access first and wraps Citizens' own (`MinecraftBlockExaminer`, `DoorExaminer`, …). A cell K&K blocks is `NOT_STANDABLE`/`IMPASSABLE` before any Citizens examiner is asked.
2. Set `PATHFINDER_OPEN_DOORS = false` per NPC so Citizens doesn't append its own door examiner. Keep fall distance −1 and bounding boxes off.
3. After `setTarget`, check that the local examiners are exactly the K&K one. The spike counts any extra examiner as an **examiner leak**.

The K&K side is ready for this. `core/roads/walk/CellAccess` is cost-or-blocked per **feet** cell: the same convention as a Citizens `PathPoint` vector, where `MinecraftBlockExaminer` checks the block below as the floor. It is built on the main thread per request and is immutable, so it is safe on Citizens' worker threads. It already combines `GateCellAccess` (gate states via `GateAvailability`), `DoorCellAccess` (WorldGuard use/interact) and `DeniedRegionAccess` (domain entry/exit and the "no way out" rule). Its verdicts are only decided inside the capture box, so cells outside the box must be blocked.

Examiners apply only to Citizens' own A* (`CITIZENS`/`CITIZENS_ASYNC`). With `MINECRAFT` they are ignored, so the pathfinder type must be pinned.

### 4.3 Doors

`DoorExaminer` makes bottom door halves and fence gates passable and attaches a `DoorOpener` callback. The callback opens the door as the NPC reaches it and closes it after, with sound and an arm swing. It works on A* paths only, not on waypoint lists (§4.1), and is off by default (`open-doors: false`). K&K GateStructures are not doors: `GateCellAccess` handles them as open/blocked from the gate state. Door opening by an NPC changes the shared world, so every player sees the door open. That fits a guard. For a tutorial-only pass-through (DESIGN §7) it doesn't, and that case stays open.

### 4.4 Stuck events and stuck actions

- `NavigationStuckEvent` carries the `StuckAction` and lets a listener replace it. A `StuckAction.run(npc, navigator)` returns whether to continue. `NavigationCancelEvent` carries the `CancelReason` (`STUCK`, `NPC_DESPAWNED`, `REPLACE`, `PLUGIN`, …), and `NavigationCompleteEvent` fires on arrival.
- Stuck detection is the stationary timer (`stationaryTicks`). Its default is **−1 = off** (`npc.default.stationary-duration`), so the adapter must set it.
- The built-in `TeleportStuckAction` **teleports the NPC to the target**, which would skip a closed gate or a denied domain. It is off by default (`npc.pathfinding.default-stuck-action: none`). K&K must never turn it on, and must install its own action. The same goes for `destinationTeleportMargin`: keep it −1.
- A failed A* search also ends as `STUCK`, so "no path" and "physically stuck" look the same to a listener. The K&K adapter has to tell them apart, for example by whether the path was ever found.

### 4.5 Async pathfinding

`PathfinderType.CITIZENS_ASYNC` (`npc.pathfinding.pathfinder-type`) runs A* on a `ForkJoinPool` over chunk snapshots from `AsyncChunkCache`. The cache TTL defaults to 5 s, and the result comes back on the main thread. Sync `CITIZENS` time-slices instead: 250 blocks per tick (`blocks-per-tick`), at most 1024 (`maximum-search-blocks`). Things to watch:

- Examiners run on worker threads, so the K&K examiner must not touch Bukkit. `CellAccess` doesn't.
- The snapshot cache can be up to 5 s stale. The K&K veto still holds because gate verdicts come from `CellAccess`, but the physical blocks Citizens sees may be stale.
- `AsyncChunkCache.fetchChunkSnapshotAsync` calls `getChunkAtAsync(x, z, true, …)`, which can **load chunks**. The spike must check this on the unloaded-chunk route.
- It is young: the async API came in 2025-09 and had a leak fix in 2026-07 (#3319, "limit A* iterations and fix async pathfinding leaks"). Benchmark both types.

## 5. Persistence

- `CitizensAPI.createInMemoryNPCRegistry(name)` gives a named registry backed by `MemoryNPCDataStore`, so nothing goes to `saves.yml`. Also set `NPC.Metadata.SHOULD_SAVE = false` (`AbstractNPC.java:349` skips saving then). `removeNamedNPCRegistry` on disable.
- Chunk handling covers **every** registry (`EventListen` iterates `getNPCRegistries()`). On chunk unload the NPC despawns (`DespawnReason.CHUNK_UNLOAD`) and its navigation is cancelled (`NPC_DESPAWNED`). Citizens respawns it when the chunk loads again but does **not** resume the route, so K&K must replan on `NPCSpawnEvent`. Keeping chunks loaded (`KEEP_CHUNK_LOADED`) is no answer for ~720 guards.
- After a restart the in-memory NPCs are gone, which is what we want: K&K respawns active guards from its own database. That makes the K&K database the source of truth.

## 6. Entity type and trait API against DESIGN §2

- **Entity:** `EntityType.PLAYER` is a fake server player, with tab-list and skin packets and a full player tick. Minecraft 1.21.9+ also has `MANNEQUIN`, a player-shaped entity without a connection. Citizens supports it as an NPC type and has a `MannequinTrait`. It may be cheaper per NPC, so the spike can spawn either. Citizens NPCs have no vanilla AI by default (`USE_MINECRAFT_AI = false`).
- **Traits:** `Trait` is abstract (`Listener`, `Runnable`). It has `run()` every tick, `onSpawn`/`onDespawn` and `load`/`save(DataKey)`, and is registered through the trait factory.
- **Fit with DESIGN §2.** K&K behaviour and NPC-01 capabilities stay in `knk-core` and don't know Citizens. A thin platform adapter in `knk-paper` maps "move to X under ruleset R" onto `Navigator` plus the K&K examiner, and maps Citizens events back to K&K navigation results (arrived, blocked with reason, stuck). Use Citizens traits only as hooks, never for state or persistence. If the executor is ever swapped, only that adapter changes.
- **Gap found:** K&K access is **player-bound** today. `WalkAccessFactory.prepare(Player, …)`, `PolicyFactory.policyFor(Player, …)` and `GateAvailability` all take a `Player`, so an NPC has no identity in the permission system yet (DESIGN §7). The spike uses the admin who spawns the NPCs as a stand-in. Real guards need an NPC access subject first.

## 7. Spike branch (#243)

**Where:** knk-plugin, local branch `claude/citizens-spike`, one commit `5aca937` on `main` `33122cf4`. It was **not pushed**: this session had read access to knk-plugin only. A push-access request was refused by the session's permission check. The patch (`knk-plugin-citizens-spike-5aca937.patch`) and the built jar (`KnightsAndKings-0.1.0+5aca937-citizens-spike.jar`) are in the session scratchpad. To publish the branch, give a session push access to `PandiO/knk-plugin`, or apply the patch with `git am` and push from a local clone. It is a throwaway branch: **never merge it**.

**What it adds** (≈1,200 lines, 11 files):

- `build.gradle.kts`: `compileOnly("net.citizensnpcs:citizensapi:2.0.44-20261020.020503-8") { isTransitive = false }` from `maven.citizensnpcs.co/repo`. `plugin.yml`: `Citizens` as softdepend.
- `paper/npcspike/` — `CitizensSpike` (in-memory registry, controller, events, metrics), `SpikeExaminer` (the composite examiner of §4.2), `SpikeMetrics`, `NpcSpikeCommand`, and `NpcSpikeBootstrap` (the only class `KnKPlugin` names; the plugin still loads without Citizens).
- `NavigationService`: two spike-only accessors, `spikeWalk()` and `spikeRoadPolyline(subject, world, from, to)`, which runs the road router with the subject's access policy on the routing executor. `KnKPlugin`: 3 small hunks (field, capture margin, registration and shutdown).
- Test `SpikeExaminerTest`, 6 tests: a blocked cell is vetoed before the inner examiners are asked; an allowed cell is decided by them; outside the box is blocked; access cost adds to the inner cost; hop resampling; percentiles.

**Modes:**

- **dense:** the K&K walk pathfinder plans the whole leg with the subject's gate, door and domain access. Citizens follows it with `setTarget(Iterable<Vector>)`. Optional `recheck N` replans every N ticks.
- **hop** (default, the BEHAVIOR_MODEL §2 hybrid): the K&K road router plans the route, which is cut into hops of `hop` = 16 blocks. Before each hop the walk preparer captures the box and builds the `CellAccess`. Citizens' A* then walks the hop under `SpikeExaminer`. With no road route, the whole trip is one direct hop.

**Rules the spike enforces:** pathfinder type pinned to `CITIZENS` (or `citizens_async`); `PATHFINDER_OPEN_DOORS = false`, with doors handled inside `SpikeExaminer`; its own stuck action (counts, stops, then K&K replans up to 3 times per DESIGN §6 bounded retry); stationary timer 60 ticks; `destinationTeleportMargin = −1`; an examiner-leak check after every `setTarget`; and replanning after a chunk-unload despawn.

**Metrics** (`/knk npcspike stats [label]`; with a label it also logs a CSV row):

- server tick mean, p95 and max, from `ServerTickEndEvent`, plus TPS;
- a no-NPC **baseline** and ms per NPC = (mean − baseline) / N;
- the spike's own main-thread µs per tick;
- K&K plan time (queued → target set) and queue wait;
- Citizens A* time (target → path), walk expansions, trip time;
- trips, hops, stuck, replans, recheck replans, chunk-unload pauses and resumes, examiner leaks;
- examiner calls, mean µs and K&K blocks;
- failures by reason.

**Verification here:** with JDK 25 (Gradle itself on JDK 21), `./gradlew test :knk-paper:shadowJar -x deployToDevServer` passes: knk-core 2476, knk-api-client 321 (2 skipped), knk-paper 2510 (18 skipped; the 6 spike tests included), 0 failures. The shaded jar has no `net/citizensnpcs` classes, and `plugin.yml` lists Citizens as softdepend. **Not run on a server**: whether Citizens 2.0.44 loads on the dev server, and every number, is for tonight.

## 8. Caveats the adapter must own (and the spike must test)

1. **Pin the Citizens config:** `pathfinder-type` CITIZENS or CITIZENS_ASYNC (never MINECRAFT), `open-doors: false`, `default-stuck-action: none`, `check-bounding-boxes: false`, `allowed-fall-distance: -1`, destination teleport margin −1.
2. **One composite examiner**, with the K&K veto first. Test: examiner leaks stay 0. A gate closed before planning is never crossed. A denied domain is never entered.
3. **Waypoint lists need a K&K recheck.** Test: in dense mode, close a gate mid-route with `recheck 0` and then `recheck 40`. Count stuck events vs clean replans.
4. **Never teleport.** Test: no NPC ends up on the far side of a closed gate.
5. **Resume after chunk unload** is K&K's job. Test: a route through unloaded chunks shows pauses = resumes and no NPC stuck for good. Also check whether `citizens_async` loads chunks.
6. **Release risk:** pin a timestamped snapshot. Test each Minecraft update on the dev server with the planned Paper build before upgrading.
7. **Async maturity:** benchmark `citizens` vs `citizens_async` at 100 NPCs. Watch memory and the worker pool.
8. **NPC access subject** (DESIGN §7) is needed before real guards. The spike's stand-in is the admin.
9. **Door opening is world-visible.** Fine for guards; tutorial pass-through stays open.

Also to measure: `PLAYER` vs `MANNEQUIN` cost per NPC; crowding with `collide on`; many simultaneous route requests (`set inflight 1|4|16`).

## 9. Tonight: commands per step of the plan

Install Citizens 2.0.44 (build for 26.3, ≥ 2026-11-01) on the dev server, with the config pins of §8.1. Deploy the spike jar, then:

| Plan step | Commands |
|---|---|
| 1. Loads cleanly | Startup log: `[NpcSpike] /knk npcspike registered`, no Citizens errors; `/plugins` |
| 2. 10 NPCs on a castle route | Stand at A: `/knk npcspike from`; at B: `/knk npcspike to`; with no NPCs: `/knk npcspike baseline`; `/knk npcspike spawn 10 hop`; after ~2 min `/knk npcspike stats 10-hop` |
| 3. 50, 100 | `/knk npcspike spawn 40 hop` → `stats 50-hop`; `spawn 50 hop` → `stats 100-hop`; repeat with `clear`, `set pathfinder citizens_async`, `dense` and `mannequin` as time allows; `reset` between runs |
| 4. 200 | `spawn 100 hop` → `stats 200-hop` |
| 5a. Gate closes mid-route | Route through a gate; close it while NPCs are on the way; watch stuck/replans/failures, and that nobody passes |
| 5b. Access removed mid-route | Take the subject's (your) entry right for a domain on the route; same counters |
| 5c. Unloaded chunks | Long route, walk away so the chunks unload; check pauses = resumes when you return |
| 5d. Many requests | `set inflight 1`, then `16`; `spawn 50`; compare queue wait and plan time |
| 5e. Walls, stairs, ladders, doors | Routes over each; `set doors off` vs `on` |
| 6. Numbers into #244 | Copy the `[NpcSpike] CSV` rows from the server log |

The CSV header: `label,npcs,mspt_mean,mspt_p95,tps,baseline_ms,ms_per_npc,spike_us_tick,plan_p50_ms,plan_p95_ms,citizens_path_p95_ms,trips,stuck,replans,failures,examiner_leaks`.
