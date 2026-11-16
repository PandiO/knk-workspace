# NPC navigation in knk-plugin (Citizens adapter)

**Status:** Current · **Last updated:** 2026-11-16 (§ 12 new: Phase 4c movement quality, links M1–M7, each behind its own key; § 10 and § 11 extended; PandiO/knk-workspace#658)
**Checked against:** knk-plugin `next` `cc5262ff` (Phases 1–4, the Phase 1 follow-ups, Phase 4b: links L2 `11e07d64`,
L3 `5dc88cfd`, L4 `deb7ff49`; Phase 4c: links M1–M7, last `cc5262ff`). None of it is on trunk yet.
**Applies to:** knk-plugin `next` only. Everything below runs only with `npc.navigation.enabled: true` (default
`false`). The developer tests of Phases 2–4 ([#360](https://github.com/PandiO/knk-workspace/issues/360),
[#361](https://github.com/PandiO/knk-workspace/issues/361), [#377](https://github.com/PandiO/knk-workspace/issues/377))
the Phase 1 audit re-run ([#490](https://github.com/PandiO/knk-workspace/issues/490)) and the Phase 4b tests
([#520](https://github.com/PandiO/knk-workspace/issues/520), [#521](https://github.com/PandiO/knk-workspace/issues/521),
[#522](https://github.com/PandiO/knk-workspace/issues/522)) and of Phase 4c ([#621](https://github.com/PandiO/knk-workspace/issues/621)–[#627](https://github.com/PandiO/knk-workspace/issues/627))
are still open, so this is not live-tested behaviour. The
plugin scenarios on CI's Paper server with Citizens check part of it (§ 11).
**Related:** [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md) (phases, decisions Q1–Q8, developer
tests, known limits; Phase 4b for the follow-ups); [behavior model § 2](../specs/npc-platform/BEHAVIOR_MODEL.md)
(requirements NAV-01–NAV-28); [plugin architecture](plugin-architecture.md); chain progress reports
([Phases 1–4](../reports/2026-11-13-npc-navigation-chain.md),
[follow-ups](../reports/2026-11-14-npc-navigation-followups-chain.md)), with what each link built and its agent
decisions; parent issue
[#358](https://github.com/PandiO/knk-workspace/issues/358).

This page describes how the code is split and how a navigation order runs. The settings are in the
[plugin configuration reference § 4.27](../guides/admin/plugin-configuration.md), the commands in the
[commands guide](../guides/users/commands.md) (`/knk npc`), the metric panels in the
[performance metrics guide § 4.2](../guides/performance-metrics-and-capacity.md), the load tests in the
[Citizens stress test guide](../guides/citizens-stress-test.md) and turning it on, the movement keys and reading the
stats on a server in the [NPC navigation admin guide](../guides/admin/npc-navigation-admin-guide.md). They are not
repeated here.

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
5. Phase 4c (§ 12): `group_merge` and the reasons per width change
   (`knk_npc_nav_group_width_reasons_total{change, reason}`: `door`, `stair`, `rules`, `edge`, `narrow`);
   `local_leg_knk`, `local_leg_engine`, `local_leg_none`; `crowd_wait`, `crowd_yield`; `pushed`, `push_returned`,
   `push_exempt`, `push_teleport`. The stats print them as `local legs: k&k N, engine N, none N`,
   `crowd: waits N, yields N, longest queue N`, `pushes: N (players N, attacks N), returned N, exempted N (now N),
   teleported N`, and `merges N (reasons)` in the groups line. Corridor steering has no stats line of its own: its
   shaped and shared stretches and cost (`CorridorShaper.shaped()` and friends) show in the scenarios' report lines.

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
4. **Phase 4c:** knk-core `CorridorTest`, `CorridorShaperTest`, `RouteFollowerCorridorTest`, `LocalLegSearchTest`,
   `NpcNavigationLocalLegsTest`, `NavGroupElasticTest`, `PlazaLineTest`, `RouteFollowerPlazaTest`, `NavGroupPlazaTest`,
   `CrowdControlTest`, `NpcNavigationCrowdTest`, `NavGroupCrowdTest`, `PushWatchTest`, `PushLedgerTest`,
   `EdgeGuardTest`, `NpcNavigationPushTest`; knk-paper `NpcNavigationConfigTest` (every key in every layer),
   `BukkitCollisionPolicyTest`, `PlazaGeometryTest`, `NpcMovementSceneTest`. Scenarios on scenes pasted from WorldEdit
   schematics (`SceneSchematic`, the developer's `knk-stairhouse.schem` and three generated stand-ins):
   `npc-stairhouse-singles`, `npc-stairhouse-group`, `npc-jagged-straight`, `npc-doorway-crowd`, `npc-plaza-line`
   (each also `…-collision-on`) and `npc-collision-policy`, `npc-guard-ledge-push`, `npc-door-column`; the keys and
   checks of each are in [writing a plugin scenario § 1](../guides/developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines).
   The real dev world, 50 NPCs for 10 minutes and a real client are the
   [NPC movement smoke test](../guides/npc-movement-smoke-test.md).

## 12. Movement quality (Phase 4c, links M1–M7)

Plan [Phase 4c](../specs/npc-platform/IMPLEMENTATION_PLAN.md) (designed by link L8, #603; requirements NAV-24–NAV-28).
Every feature has its own key and is off by default; with all keys at their defaults the code walks as Phase 4b.
Decided: steering option A with add-on D. Open: option B (a short-horizon steering layer, plan 4c.4 item 8) and
whether `collidable` turns on by default; both wait for the developer's tests.

### 12.1 The corridor (M1, M2: `corridor-steering`)

1. **`corridor/FreeWidth`** (M1): the free width across a line at a point, left and right, to a wall, post, full-block
   step or drop, at most 4 a side. `/knk npc nav trace` writes it as a `# corridor:` line after each `# waypoints:`
   line; M3 and M4 judge widths with it.
2. **`corridor/Corridor`**: the standable cells within `corridor-half-width` of a stretch's waypoints, flooded from the
   line with floor continuity (a step of at most a block, the body's headroom) and in the regions the line passes;
   everything else in the strip is an obstacle. Each cell's clearance is its distance to the nearest obstacle (capped
   at 2), judged from its own floor, so stairs work. A line that passes one column on two levels gets a corridor per
   piece.
3. **`corridor/CorridorShaper`**: samples the line every 0.5 block and moves each point square to the line to the
   place nearest the road line that keeps `wall-clearance` (looking ±2 blocks along, so a notch doesn't pull it and a
   jutting piece is seen early), the most clearance where the road is narrower than twice it. A chokepoint (under 2
   blocks for at most 3 blocks, wider before and after) gets three pinned waypoints on its axis and the stretch the
   waypoint margin 0.35. String pulling then joins the points by the longest straight steps that stay in the corridor.
   Corner clearance (§ 5.1) and the waypoint chain run on the result. The route's last point never moves.
4. **Cost and sharing:** one shape per stretch, cached 600 ticks and shared by every NPC whose stretch has the same
   waypoints (`NpcNavigationService.corridors()`). The leader of a group keeps its unshaped route; with `elastic` the
   group path is shaped per chunk of 20 points (§ 12.3).

### 12.2 K&K's local legs (M6: `local-legs-clearance`)

**`corridor/LocalLegSearch`**: every local leg goes through the service's hop planning (short trips, hops to and from
the road, a follower's own leg back, the ladder's local leg). K&K builds a corridor round the straight line to the hop
(6 blocks either side, up to 12 for long legs; regions don't shape it) and runs a bounded A* (8 directions, no corner
cut, at most 2048 cells). A cell must be allowed by the leg's `CellAccess`, keep the body's half width, and costs 5
per block of clearance it lacks to `wall-clearance` (4 more for an occupied cell with crowd awareness). The path is
smoothed by line of sight and walked as a waypoint list, with a watchdog on progress (waypoint lists report no stuck,
NAV-17). When K&K finds nothing, Citizens' search walks the leg as before.

### 12.3 Elastic formations (M3: `group-formation-keeping: elastic`)

`levels` (the default) is § 6.1. With `elastic` the group decides its width per group path point from the free width
across the path (`GroupPath.fit`, looked up once per point; walls, drops, cells of another step on a flight, regions the
group's rules deny):

1. **Squeeze:** neighbours stand from `group-lateral-spacing` down to `group-lateral-spacing-min` (0.6) apart, the
   formation's centre sits off the path's centre to keep its outer lanes `wall-clearance` from faces (never under
   0.35), and rows close up towards `group-spacing-min` in quarter steps.
2. **Look-ahead and hysteresis:** the width is decided from the rearmost slot to the formation's depth plus
   `group-lookahead-blocks` ahead. A width is given up only for a tight place longer than
   `group-width-hysteresis-blocks`, the column too; shorter ones are passed with the lanes merged (`merges`).
3. **Stairs, rules, lanes:** on a flight a width fits only when each lane has a step of its own (reason `stair`); a
   lane may enter another region when the leader's access verdicts allow it (reason `rules`); a lane keeps within the
   bands from a step behind to 2 blocks ahead.
4. **Re-assignment:** on a width change followers get the new slots by their place, so nobody overtakes.
5. **Reasons:** each narrow, fold and merge is logged and counted with `door`, `stair`, `rules`, `edge` or `narrow`.

### 12.4 Plaza lines (M5: `plaza-lines`)

The road plan names every junction a route passes (`RoadPlanner.PlazaCrossing`, knk-paper
`NavigationService.plazaCrossingsOf`), designed plazas with their `PlazaRadius`. Automatic plazas are measured on the
NPC side: 16 rays from the junction over standable floor; a junction whose open radius is no more than
`corridor-half-width` is a street junction and left alone. The stretch's corridor is widened by the plaza's footprint
(at most `plaza-corridor-blocks`), and **`corridor/PlazaLine`** runs a bounded A* (at most 4,096 cells) from where the
line enters the footprint to where it leaves, string-pulls it and slides its bends to the tangent points round
obstacles; regions the route line doesn't pass stay obstacles. The plaza's points are pinned. With `corridor-steering`
off only the plaza part changes. A group's path and its leader take the line with the formation's half width plus
`wall-clearance` as margin (`NavGroup.plazaClearance`). The road graph and the players' trail are unchanged (builder
through-edges are a future update, plan 4c.7).

### 12.5 Crowd awareness (M4: `crowd-awareness`)

1. **`crowd/Occupancy`**: every 5 ticks one pass hashes the feet cell of every spawned NPC (followers included);
   lookups are O(1).
2. **`crowd/CrowdControl`**: a narrow place is a run of points on the NPC's way ahead (6 blocks looked at) where the
   free width is under 2 blocks; NPCs that see the same cells share it, and the first way through gives its axis and
   so each NPC's direction. An NPC within 4 blocks may enter when no NPC of the other direction has a turn, it is the
   earliest waiting, and the last of its own direction is a block in; otherwise it walks to its queue spot (1.5 blocks
   before the place plus a block per NPC ahead, a block to the right where the floor allows). A turn ends 0.5 past the
   place; a leader keeps it until its followers are through. A queue lets an NPC go after 30 s. `CrowdControl.earlier`
   is the single place that orders two NPCs, the hook for authority and closed formations later (plan 4c.7).
3. **Oncoming:** an NPC in a narrow place without a turn while the other direction entered first steps back out
   (`yield`).
4. **Waiting is not stuck:** a held NPC is not watched; a watchdog or engine stuck report with another NPC within 1.5
   blocks along the way counts a wait instead of a stuck spell (after 30 s behind the same NPC it is stuck after all).
   Recovery steps and local-leg targets skip occupied cells.

### 12.6 Bodies and push resistance (M7: `collidable` and the `push-*` keys)

1. **Collision policy** (knk-core port `NpcCollisionPolicy`, knk-paper `BukkitCollisionPolicy`): with `collidable` on,
   every online player is in each NPC's collidable exemptions (Paper's `LivingEntity#getCollidableExemptions`, kept up
   to date on joins, quits and respawns), so players never move NPCs while NPCs push each other. Chosen by the
   scenario `npc-collision-policy` over a scoreboard team (Citizens sends its own per-NPC teams for name tags, an entity
   is on one team only, and `FOR_OWN_TEAM` let players push). With `players-push-npcs` players collide too.
2. **`push/PushWatch`** (every 2 ticks per NPC with collision on): a move the NPC's own walk doesn't explain is a push:
   faster than 0.4 blocks a tick (plus 0.15), more than 0.2 back against its road line, more than 0.25 sideways right
   after a contact, or 0.4 from where a standing NPC stands. Height is never judged (stairs and hops are its own walk).
   One push per 20-tick episode. Contacts come from Citizens' `NPCCollisionEvent` and Paper's
   `EntityPushedByEntityAttackEvent` (not cancelled, so knockback stays); an unreported push with an NPC within 1.5
   blocks is that NPC's jostle.
3. **Return** (`push-return`): straight back where that is a straight walk (L5's floor continuity), else along
   `RecentSteps`, else a local leg, then on along the route; an NPC with no order walks back to its post; a follower is
   left to its group's slot walks; other NPCs' jostles are the crowd's business unless towards a drop or moving an NPC
   at its post a block or more. After `push-teleport-ticks` a teleport home, only while no player within 64 blocks has
   a line of sight (`NpcSight`, knk-paper `BukkitNpcSight`).
4. **`push/EdgeGuard`**: queue spots skip cells next to a drop; a push towards a drop always sends the NPC back and,
   with `players-push-npcs`, exempts the pusher at once.
5. **`push/PushLedger`**: with `players-push-npcs`, `push-exempt-after` pushes by one player within
   `push-exempt-window-ticks` exempt that player from that NPC for `push-exempt-ticks`.

### 12.7 Limits of Phase 4c

1. `collidable` stays `false` by default: one NPC's body can shove another off a 1-wide flight or ledge (a trial with
   collision on everywhere failed `npc-ledge-corner`, `npc-corners-walk`, `npc-group-narrows` and, by design,
   `npc-stuck-ladder`). Missing before it can turn on: turns on 1-wide flights and ledges by a drop, the squeeze margin
   below, the L3–L5 scenarios with collision on, and the developer's push test (plan 4c.4 item 7.4.10).
2. With collision on, squeezed `elastic` rows still overlap (slots exactly 0.6, a body width, apart); 0.7 would hold
   them but changes which roads take 3 abreast, a decision for the developer.
3. The door mouth with bodies: [#657](https://github.com/PandiO/knk-workspace/issues/657). A group's arrival waits for
   its settle time when followers stop 0.1–0.2 short of their slots: [#636](https://github.com/PandiO/knk-workspace/issues/636).
4. Off its road line (a back-off, a queue walk, a winding leg) a push is judged by speed only, so a slow push there is
   not seen; moot while players never push.
5. The stair house in the scenarios stops at the hall; its upper flights are not walked yet.

## 13. Not built yet

Phases 5–8 of the [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md): an NPC access identity in the
API and web app (5), detours and hidden routes (6), movement quality (7) and movement outside loaded areas (7b), and
the benchmark gate (8). There is no gameplay NPC yet: `/knk npc test` and `/knk npc nav` are test drivers that stand
in for the behaviour layer. The plan's "Known limits" notes under Phases 2–4 and 4b list what the merged phases do not
do; for Phase 4b: corner clearance needs room (on a 1-wide stair the NPC still walks next to the wall and the ladder
frees it), the waypoint margin applies to whole stretches, a group narrows as a whole (single lanes only step aside
for a short bump), and a single NPC or leader in a closing door's box is
[#534](https://github.com/PandiO/knk-workspace/issues/534).
