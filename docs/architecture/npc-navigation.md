# NPC navigation in knk-plugin (Citizens adapter)

**Status:** Current · **Last updated:** 2026-11-15 (Phase 4b: followers at doors and district edges, wall corners and the recovery ladder, narrowed formations, followers that finish their trip, the stats lines; PandiO/knk-workspace#589)
**Checked against:** knk-plugin `next` `deb7ff49` (Phases 1–4, the Phase 1 follow-ups and Phase 4b: links L2 `11e07d64`,
L3 `5dc88cfd`, L4 `deb7ff49`). None of it is on trunk yet.
**Applies to:** knk-plugin `next` only. Everything below runs only with `npc.navigation.enabled: true` (default
`false`). The developer tests of Phases 2–4 ([#360](https://github.com/PandiO/knk-workspace/issues/360),
[#361](https://github.com/PandiO/knk-workspace/issues/361), [#377](https://github.com/PandiO/knk-workspace/issues/377))
the Phase 1 audit re-run ([#490](https://github.com/PandiO/knk-workspace/issues/490)) and the Phase 4b tests
([#520](https://github.com/PandiO/knk-workspace/issues/520), [#521](https://github.com/PandiO/knk-workspace/issues/521),
[#522](https://github.com/PandiO/knk-workspace/issues/522)) are still open, so this is not live-tested behaviour. The
plugin scenarios on CI's Paper server with Citizens check part of it (§ 11).
**Related:** [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md) (phases, decisions Q1–Q8, developer
tests, known limits; Phase 4b for the follow-ups); [behavior model § 2](../specs/npc-platform/BEHAVIOR_MODEL.md)
(requirements NAV-01–NAV-23); [plugin architecture](plugin-architecture.md); chain progress reports
([Phases 1–4](../reports/2026-11-13-npc-navigation-chain.md),
[follow-ups](../reports/2026-11-14-npc-navigation-followups-chain.md)), with what each link built and its agent
decisions; parent issue
[#358](https://github.com/PandiO/knk-workspace/issues/358).

This page describes how the code is split and how a navigation order runs. The settings are in the
[plugin configuration reference § 4.27](../guides/admin/plugin-configuration.md), the commands in the
[commands guide](../guides/users/commands.md) (`/knk npc`), the metric panels in the
[performance metrics guide § 4.2](../guides/performance-metrics-and-capacity.md) and the load tests in the
[Citizens stress test guide](../guides/citizens-stress-test.md). They are not repeated here.

## 1. The split: K&K plans, Citizens moves

K&K plans the route on its own road graph with its own rules (gates, domain access, siege lockdown). The Citizens
plugin only moves the NPC's body along what K&K hands it. Citizens is optional: the plugin loads and runs without it,
and `/knk npc status` then says why NPC navigation is unavailable.

| Layer | Package | What it holds | Engine types |
|---|---|---|---|
| Core | `knk-core` `core/npc/nav/` | The navigation service (state machine, planning queue, watchdog, retries), the route follower, hop planner, layered settings, access subjects and profiles, metrics, and the ports the engine implements | None (decision Q1: Bukkit-free, engine-neutral) |
| Groups | `knk-core` `core/npc/nav/group/` | Groups that plan once: leader, followers in formation slots, narrowing to fewer abreast and folding into a column where the way is narrow, followers that finish their trip | None |
| Adapter | `knk-paper` `paper/npc/citizens/` | `CitizensBootstrap`, `CitizensNpcRuntime` (the K&K NPC registry), `CitizensNpcMover`, `KnkBlockExaminer` | The only package that names Citizens types |
| Wiring | `knk-paper` `paper/npc/nav/` | `NpcNavigationModule` (start and stop, `/knk npc`), config, the Bukkit implementations of the ports, the test drivers, the event audit, run files, `NpcEntities` | Bukkit, no Citizens |

1. **Build:** CitizensAPI is `compileOnly`, non-transitive and never shaded (Citizens is OSL-3.0; the server provides
   the jar). The version is `citizensApiVersion` in `gradle.properties` (2.0.44, the build for Minecraft 26.3, server
   build 4269); bump it together with the server's Citizens jar. `plugin.yml` lists Citizens under `softdepend`.
2. **Loading without Citizens:** `CitizensBootstrap` has no Citizens type in its signature, so `NpcNavigationModule`
   can call it on a server without Citizens. The Citizens classes are only loaded once Citizens is enabled.
3. **Start:** `KnKPlugin` calls `NpcNavigationModule.start(...)` once, inside a `try` block, so a failure only logs a
   warning (`[NPC] navigation module failed to start`) and the rest of the plugin keeps running. The module always
   registers `/knk npc` (permission `knk.admin.npc`, op by default, see
   [plugin permission checks § 4](plugin-permission-checks.md#4-bukkit-only-checks-and-vanilla-commands)). With the
   flag off it starts nothing else: no task, listener, Citizens call or world query.
   `NpcNavigationModuleDisabledTest` checks that with the shipped `config.yml`.
4. **Route following is built on first use**, the first `/knk npc nav` command, not at startup. It needs road
   navigation (`navigation.enabled`) and walk paths (`navigation.walk.enabled`), because local legs use player
   navigation's walk capture. Without them `/knk npc nav` says which one is missing.

## 2. Ports

The core reaches the server only through these interfaces. All of them are called on the main thread unless noted.

| Port (`core/npc/nav/`) | Paper implementation | What it answers |
|---|---|---|
| `NpcMover`, `NpcMoverFactory` | `CitizensNpcMover`, created by `CitizensBootstrap` | Spawn, walk a stretch of waypoints (`follow(waypoints, margin)`: Citizens moves on to the next waypoint only within `waypoint-margin`; local legs keep Citizens' own margin) or a local leg, stop, despawn. The listener's `stuck(mover, StuckKind)` says what made Citizens give up: `STATIONARY` (its stationary check) or `NO_PATH` (a path search that found nothing). The factory is absent without Citizens |
| `RoadPlanner` | `NavigationService.planRoadFor` (road router with the subject's access policy) | The road part of a route on the K&K road graph, with the gate crossings on it; needs no loaded chunks (NAV-14) |
| `LocalLegPreparer` | `NpcLegPreparer` on the walk capture (`WalkLegPreparer.capture`) | Captures the terrain box around a short leg and decides gate, door and region access in it; never loads chunks |
| `NavWorld` | `BukkitNavWorld` | Floors, loaded chunks and region ids; `freeHeight` (headroom above a floor: a slab overhead gives 2.5) and `blocksBody` (a cell that stops a body; bottom slabs and upright stairs are steps, not walls) for corner clearance and the recovery ladder; never loads a chunk |
| `AccessRules` | Player navigation's access code (`NavigationAccess`) | The rules as they are now, asked while an NPC walks: may it enter a region, does a gate door block it, and the door's box (`doorBox`, from `GateDoorBounds`), so a walker in that box when the door starts moving is known to be in its way |
| `AccessSubject` | `PlayerAccessSubject` (players), `NpcAccessSubject` with an `NpcAccessProfile` (NPCs) | Who moves, as far as the access rules care, so an NPC never borrows a player's rights |
| `RuleChangeListener` | Registered on road navigation with `addRuleChangeListener` | A gate changed state, or availability changed (domain cache refresh, siege lockdown start or end). It may be called off the main thread; the module moves the call to the main thread |

Player navigation keeps its own `Player` methods. The `AccessSubject` overloads of `NavigationAccess`,
`WalkAccessFactory` and `WalkLegPreparer` share the same private rule code, and tests compare the player and subject
verdicts case by case (report block 4.1 § 5.4).

## 3. How one order runs

`NpcNavigationService` keeps a state per NPC (`NpcNavState`: `IDLE`, `QUEUED`, `PLANNING`, `MOVING`, `WAITING`,
`PAUSED`; `SIMULATED` is reserved for Phase 7b). The metrics use these names in lower case.

1. **Queue and plan.** An order waits for a planning slot (`max-plans-in-flight`). The road route is planned on the
   road graph for the NPC's access subject, from where it stands. A goal within `hop-blocks` horizontally **and** at
   most 2 blocks up or down is a short trip: one local leg with no road plan (a goal right above or below, such as the
   top of a stair house, gets a road plan). A trip with an end too far from any road is walked in short hops only when the whole trip is at most
   `walk-only-blocks` long; otherwise the order fails. There is never a straight-line fallback across terrain.
2. **Follow the road line (trail mode, decision Q8).** `RouteFollower` turns the road line into floor points and hands
   the mover one stretch (`stretch-blocks`) of waypoints at a time. The next stretch is prepared before the current
   one ends. Only the stretch ahead is looked at in the world.
3. **Local legs.** The off-road ends, short trips and recovery legs use Citizens' own path search, cut into hops by
   `HopPlanner`. `KnkBlockExaminer` puts K&K's verdicts in front of Citizens' examiners: a cell the leg blocks (a
   closed gate, a denied region, a door the NPC may not open, anything outside the captured box) is impassable before
   Citizens is asked. Examiners that Citizens adds by itself are removed and counted as `examiner_leak`
   (must stay 0).
4. **Watchdog and failure.** If Citizens reports the NPC stationary (`stationary-ticks`) or it makes no progress along
   the line (`no-progress-ticks`), it is stuck and runs the recovery ladder (§ 5.2). When the ladder's steps are used
   up, the route is dropped, the NPC waits `no-route-wait-ticks` and plans again from where it stands, at most twice
   per order (`MAX_REPLANS`). After that the order ends as `FAILED`, and the caller gets a `NavigationResult`. What
   happens next is for the behaviour layer to decide.
5. **Unloaded chunks.** An NPC whose chunk unloads is `PAUSED` and resumes when the chunk loads again. A way ahead that
   is not loaded makes it wait (`unloaded_wait`).

## 4. Rules stay binding (Phase 3)

1. **Recheck.** Every `recheck-ticks`, a walking NPC's way ahead is checked against the current gate and access
   rules. A denied region or a closed gate ahead makes it plan the route again. `rule-checks-per-tick` caps the number
   of NPCs checked per tick.
2. **Events.** A gate change or an availability change reaches the NPCs through `RuleChangeListener`. An NPC waiting at
   a closed gate or a district edge is woken by the change itself, not only by its wait timer.
3. **Trespass guard.** An NPC that is inside a region its current rules deny is always logged and counted. With
   `stop-on-trespass: true` (meant for dev servers) it is also stopped and its route planned again.
4. **Access profiles** (`access-profiles.<id>`, until NPCs get their own permission identity in Phase 5):
   `bypass-domain-rules`, `open-doors`, `allow-regions`, `deny-regions` (deny wins). NPCs pass open gates only and
   are never siege lockdown members; gate pass-through for NPCs is open question Q5, after Phase 5.

## 5. Wall corners and stuck recovery (Phase 4b, link L3)

### 5.1 Steering round corners (NAV-19)

1. **Corner clearance** (`CornerClearance`, used by `RouteFollower`). A turn is a line point where the heading changes
   by 30° or more over the next three points. For the turn point and the two points either side of it, the waypoint
   moves outwards, at most `corner-clearance` blocks (default 1.0, 0 = off), to the cell that keeps the most distance
   from walls on the inside of the turn. It only moves to a cell that is standable, keeps floor continuity with its
   neighbours, lies in the same regions as the line point and from which the straight walk to its neighbours stays
   standable. Where the road is too narrow, the waypoint goes as far out as the road allows. Straight stretches are
   left alone: a road line may run along a wall.
2. **Through the corner point.** Stretches are handed to Citizens with `waypoint-margin` (default 0.5), so the NPC
   reaches the corner point before it heads for the next one. Citizens' own default of 1 block made NPCs cut stair
   corners diagonally and fall off ledges ([#491](https://github.com/PandiO/knk-workspace/issues/491)).
3. **No shortcuts, enough headroom.** K&K never leaves a corner point out of a stretch unless the straight walk between
   its neighbours is standable for the body's width, with headroom and floor continuity. A step up of a full block
   (not a slab or stair) needs 3 free blocks above the take-off cell; corner clearance and recovery never pick a cell
   that lacks it.

### 5.2 The recovery ladder (NAV-20, NAV-21)

1. **Targets on the NPC's own floor** (`PathTargets`). A recovery leg, a follower's own leg back and an off-road hop
   aim at a point **along the path ahead** of the NPC (never behind its place on it), with floors chained point by
   point from the floor it stands on (2 blocks per point at most), at least 3 blocks ahead, standable, with headroom,
   in regions it may enter, and at most `hop-blocks` along the path. A target on the flight above or below is never
   picked ([#492](https://github.com/PandiO/knk-workspace/issues/492)).
2. **A stuck spell** (`RecoveryLadder`, one per NPC) starts with the first stuck report: Citizens' stationary check or
   the watchdog's "no progress". Later reports join it; a path search that found nothing (`NO_PATH`) ends the current
   try but starts no new spell. The NPC takes one step per try, waiting `recovery-wait-ticks` between tries:
   1. **Back-off:** 2 blocks back along its own last footsteps (`RecentSteps`, the last 8 blocks), then the rest of
      the stretch again.
   2. **Side-step:** one block straight away from the nearest blocking cell (diagonally back if that cell is not
      standable), then the rest of the stretch again.
   3. **Local leg ahead:** one Citizens leg under K&K's rules to the target of item 1.
   4. **Replan** (§ 3 item 4).
3. Steps 1–3 count against `max-retries` (3: each once; 1: only the back-off). A step that cannot be taken (no
   footsteps behind, no free cell beside, no target ahead) is skipped without a wait and not counted. A try has worked
   when the NPC got at least 1 block further along the path within `no-progress-ticks`; the spell ends there, freed
   by that step. A new stuck within 2 blocks of where the last spell started, within 30 s, continues that ladder
   where it stopped.
4. **Followers** run the same ladder inside the group, with their own leg back (aimed ahead on their own floor, never
   past their slot) as step 3. A side-step goes away from the path's centre, so the followers behind keep their slots
   and walk on. A follower whose ladder is used up or that is left behind waits on a free cell beside its lane; its
   tries are spaced out, doubling from `no-route-wait-ticks` up to 60 s, and start again from the beginning after any
   progress or a gate or access event.
5. **Run log.** One line per try and one when the spell ends, the count never past the cap, for example
   `<npc> stuck (stationary) at x y z, wall at x y z (north): step 1 of 3 back-off`,
   `<npc> freed at x y z by side-step (2 steps, 1.4 s)` and `<npc> not freed at x y z: replanning (steps used up)`.
   Positions that repeat show the hard spots.

## 6. Groups (Phase 4, Phase 4b)

`NavGroupService` sits on top of the navigation service's public methods. A group's leader is an ordinary order, and
each follower walks the leader's path in a slot of the group's formation (`column`, `ranks`, `cluster`,
`escort-ring`). A follower that falls too far behind gets its own leg back (`group-rejoin-blocks`,
`group-regroup-blocks`, `group-catch-up-speed`). After a rule change the leader plans again once for the whole group,
and the followers' lanes are checked again. The group takes its `group-*` settings once, from the leader's settings
layers. The service ticks once per server tick, before the navigation service.

### 6.1 Widths (NAV-22, link L4)

1. **Spacing.** `group-lateral-spacing` (default 1.0, shoulder to shoulder) is the gap between neighbours in a row;
   `group-spacing` (default 1.5) the gap between rows and in the column. At 1.0, 3 abreast need a road 3 blocks wide.
2. **Each formation has a list of widths**, widest first, and the group walks in the widest that fits:
   1. `ranks`: `group-ranks-width` abreast, then one fewer, down to 2, then the column.
   2. `cluster`: 3, 2, column.
   3. `escort-ring`: the rings while the road is wide enough for them; then rows of 3 with the leader in the middle of
      the second row; then 2 abreast (a pair ahead, the leader, pairs behind); then a column with one escort ahead of
      the leader and the rest behind.
   4. `column`: one width.
3. **Fit.** A width fits at a path point when its outermost lanes have a standable floor within a block of the path's
   height, in the same regions, with each lane point 0.2 block from a block edge across the path. The lanes may shift
   half a block at a time to either side to fit (a path line that hugs a wall still fits 3 abreast). A path point
   where the floor steps up or down a block (stairs) is walked as a column. Lanes return to the path's centre 2
   blocks before a point where they have no floor, so followers step in behind each other before a narrow opening.
   The group's width is the narrowest fit over the stretch under it. Each path point caches its widest fitting width
   and shift, worked out once, so the tick cost stays that of Phase 4.
4. **Hysteresis** (`group-width-hysteresis-blocks`, default 3). Folding into a column is immediate (gates, doors,
   stairs). A narrower width of 2 abreast or more is taken only when it lasts longer than the hysteresis along the
   path; a shorter bump (a lamp post, a stall) is passed by the outer lanes stepping onto the lane next to them. A
   wider width is taken only when it fits under the group plus the hysteresis ahead. A group's first look after a new
   order takes the fitting width at once.
5. **Events and log lines:** `group_narrow` (`group <n> (<leader>, <size> NPCs) narrows to 2 abreast: the path is too
   narrow for 3 abreast at x y z`), `group_widen`, `group_fold` (`… folds into a column: the path is too narrow for
   2 abreast at x y z`) and `group_reform` (`… takes up 2 abreast again at x y z`).

### 6.2 Followers at doors and district edges (links L2 and L4)

1. **Followers check the rules too.** A follower's way ahead is rechecked like a single NPC's, and the trespass guard
   counts followers. Followers that a closed or closing door or a denied district stops wait a block or two short of
   it and walk on when the rule allows; the leader walks on without waiting for them.
2. **Queue.** Held followers queue a spacing apart behind the first of them, counted from the last point before the
   door or edge, so they don't press into each other.
3. **A moving door.** The gate event comes at the start of an animation. A follower in the 1-block margin before a
   door that starts moving steps back out of the margin and waits like a held follower; only one standing under the
   door walks on out of it. No NPC is moved by the door (no `[GateSafety] Moved` line).
4. **Domain cache refresh.** `/knk cache refresh` empties the region → domain map before the NPCs hear the event, and
   an unknown domain counts as open. While NPC navigation runs, `DomainCacheRewarm` (knk-paper `navigation/`) warms
   the map again and sends a second availability event, so the followers' recheck sees the new rules.

### 6.3 Followers that finish their trip (NAV-23, link L4)

`group-followers-finish-trip` (default `false`; the test command sets it per group with `finish-trip` or
`follow-leader`) decides what followers still on their way do when the leader has arrived and the group gets its next
order (the test driver turns the group back at the route's end):

1. **`false`:** every follower takes its place on the new path at once; followers that had not reached the goal skip
   the rest of the trip. A follower that stands on the leader's new route beyond the part already on the group's path
   (held at a gate when the group turned back) waits there and falls in when the column reaches it.
2. **`true`:** every follower that has not reached its slot at the goal keeps the old path from its place to that slot
   as its own trip (`FINISHING`), with the same lanes, rule checks, door box and trespass guard. It waits at a door or
   district edge that stops it, and walks on when the rule allows. At its slot it fires the member listener
   `NavGroup.onMemberArrived(member, goal)` (for later behaviour, such as a courier handing over goods), logs
   `<npc> (group <n>) finished its trip at x y z` and counts `group_finish_trip`; then it follows the group's
   current order. The leader does not wait for finishing followers. A finishing follower that gets stuck gets its
   waypoints again; after `max-retries` such tries it gives the trip up and follows the group (`… gives up its trip
   at x y z`).
3. **Scope:** only followers still on their way when the leader has arrived. An order that replaces a running one
   before the leader arrived, and a cancelled or failed order, release the followers as before.

## 7. Settings layers

`NavigationSettings` resolves each per-NPC key from the most specific layer that sets it: code default → global
(`npc.navigation`) → world → region (WorldGuard region or domain id; the innermost region wins) → template →
assignment. Every resolved value records the layer it came from, and `/knk npc status` shows that layer. Templates have
no source yet; they come with the behaviour layer. The only assignment so far is the formation given to
`/knk npc nav group <n> <formation>`. The keys and their ranges are in the configuration
reference § 4.27. Values out of range are rejected at start and logged as `[NPC] config ...`.

## 8. NPCs and the player listeners

Citizens' player-shaped NPCs are `Player` instances, so player listeners receive them too. `NpcEntities.isNpc(entity)`
is the one check every guard uses: it is true for any entity with the `NPC` metadata key, which Citizens and most NPC
plugins set. The guards have one early return at the top of a handler. They apply whether or not
`npc.navigation.enabled` is on, and to other plugins' NPCs too (report block 4.4 § 5.5).

| Listener | NPC skipped as |
|---|---|
| `WorldGuardRegionListener` (region tracking) | the player who moves |
| `AdminFreezeListener`, `TeleportWarmupListener`, `DomainEffectDamageListener`, `FallStatisticsListener` | victim |
| `CombatTagListener`, `SiegeCombatListener`, `TelemetryListener`, `CombatStatisticsListener.onDamage` | victim or attacker |
| `CombatStatisticsListener.onPlayerDeath` / `onEntityDeath` / `onShoot` | the dead player / the killer of a mob / the shooter |
| `EnchantmentCombatListener`, `JoinLoadingRestrictionListener`, `AfkActivityListener` | attacker only: enchantment effects still hit an NPC like a mob, and a player who is still loading still cannot hit one |

Left unguarded on purpose: `GateSuffocationGuard` (moves an NPC out of a gate door too), `HubRulesListener` (the hub's
damage rules protect NPCs and stop NPC hits on players there) and `GlobalRegionProtectionListener` (an NPC still
cannot break a protected item frame).

Consequences to know:

1. Hits by or on NPCs are not counted in combat statistics at all. A player killed by an NPC still counts as killed by
   a player in the death statistics: [#494](https://github.com/PandiO/knk-workspace/issues/494).
2. `SiegeCombatListener` ignores hits by or on NPCs, so NPC combat in a siege (Siege Survival) needs its own rule.

`/knk npc audit start|stop|report` (`NpcEventAudit`) counts, per event type, the events whose player or entity is an
NPC, and lists the plugin's listeners that receive them, with the damage causes. A listed listener receives the event
but is not proof that it acts: the guarded ones return at once for an NPC.

## 9. Runtime files, metrics and threads

1. **Files** under `plugins/KnightsAndKings/`: `npc-routes.yml` (the test routes of `/knk npc nav`; the spike's
   `npcspike-routes.yml` is taken over on first use) and `npc-logs/` (a log per server start with every stuck event
   and its position, the `/knk npc nav stats` output, per-NPC traces and the audit reports).
2. **K&K is the source of truth.** `CitizensNpcRuntime` keeps K&K's NPCs in memory and uses an in-memory Citizens
   registry, so nothing goes into Citizens' saves. Test NPCs are gone after a restart.
3. **Metrics.** `NpcNavigationMetrics` counts whenever NPC navigation runs (it feeds `/knk npc nav stats`). It is
   exported on the plugin's metrics endpoint only with `metrics.enabled`. A once-per-second task publishes the
   per-world state counts and its own main-thread cost. The Phase 4b events are listed in § 10.
4. **Threads.** The service, groups, mover and world queries run on the main thread. Road plans and the domain part of
   a leg capture complete on other threads and are handed back to the main thread. Spawns are spread out by
   `NpcSpawnQueue` (`spawns-per-tick`).

## 10. Counters and the stats lines (Phase 4b)

`/knk npc nav stats` prints, among others, these two lines (also written to the run file in `npc-logs/`):

1. **Stuck spells:** `stuck near a wall: N, freed by: back-off a / side-step b / local leg c / replan d, not freed e |
   stuck elsewhere: M (same split) | steps per stuck: mean x, max k | engine found no path n | longest still s.s s at
   x y z | falls f`. "Near a wall" means a cell that stops a body touches the NPC's cell or the next one in its walking
   direction.
2. **Groups:** `groups g (n NPCs, <formations>): trips t | widths: narrows N, widens N | folds N, reforms N, folded now
   N | abreast now k | finished trips N (finishing now N) | own legs back …, left behind …, leader waited …, furthest
   behind its slot … blocks | road plans per group event: max r | local legs at once: max l`.

The events behind them (`knk_npc_nav_events_total{event=…}` on the metrics endpoint):

1. `stuck_engine` and `stuck_no_progress` count **spells**, one per spell, by what reported it first (before L3 they
   counted every Citizens cancel, retries included: the `stuck_engine 14456` of #491).
2. `freed_back_off`, `freed_side_step`, `freed_local_leg`, `freed_replan` and `not_freed` end them; `recovered` stays
   as their sum for old dashboards. A knk-core test checks that `stuck_engine + stuck_no_progress = recovered +
   not_freed + open spells`.
3. `recovery_no_path` counts Citizens path searches that found nothing; `fell` counts a navigating NPC whose feet
   dropped 3 or more blocks below the path's floor (Paper's fall distance on landing).
4. `group_narrow`, `group_widen`, `group_fold`, `group_reform` and `group_finish_trip` (§ 6).

## 11. Tests

1. **knk-core JUnit** with a fake `NavWorld` and `NpcMover`: corner clearance, the #491 stair-corner geometry,
   `PathTargets` on stacked flights, the ladder's order, spacing, cap and counting, the slot layouts of every width,
   step-down and hysteresis, the per-point cache and the finish-trip toggle.
2. **knk-paper MockBukkit/Mockito:** `BukkitNavWorld.freeHeight` and `blocksBody`, the mover's margin and stuck kinds,
   the keys and their layers, the group command's toggle word.
3. **Plugin scenarios** on CI's `paper-boot` server with a pinned Citizens build: `npc-corners-line`,
   `npc-corners-walk`, `npc-stuck-ladder`, `npc-group-narrows`, `npc-group-gate-finish-trip` and
   `npc-group-access-change` on the corner scene, and the three road scenarios of #543. See
   [Writing a plugin scenario](../guides/developer/plugin-scenarios.md). The look of the widths on real roads, the
   spacing and a column of 20 at a real gate are the developer's manual steps (plan 4b.3, developer test).

## 12. Not built yet

Phases 5–8 of the [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md): an NPC access identity in the
API and web app (5), detours and hidden routes (6), movement quality (7) and movement outside loaded areas (7b), and
the benchmark gate (8). There is no gameplay NPC yet: `/knk npc test` and `/knk npc nav` are test drivers that stand
in for the behaviour layer. The plan's "Known limits" notes under Phases 2–4 and 4b list what the merged phases do not
do; for Phase 4b: corner clearance needs room (on a 1-wide stair the NPC still walks next to the wall and the ladder
frees it), the waypoint margin applies to whole stretches, a group narrows as a whole (single lanes only step aside
for a short bump), and a single NPC or leader in a closing door's box is
[#534](https://github.com/PandiO/knk-workspace/issues/534).
