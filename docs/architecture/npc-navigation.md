# NPC navigation in knk-plugin (Citizens adapter)

**Status:** Current · **Last updated:** 2026-11-14 (written for Phases 1–4 on knk-plugin `next`, PandiO/knk-workspace#496)
**Checked against:** knk-plugin `next` `bd7b78a8` (Phases 1–4 and the Phase 1 follow-ups). None of it is on trunk yet.
**Applies to:** knk-plugin `next` only. Everything below runs only with `npc.navigation.enabled: true` (default
`false`). The developer tests of Phases 2–4 ([#360](https://github.com/PandiO/knk-workspace/issues/360),
[#361](https://github.com/PandiO/knk-workspace/issues/361), [#377](https://github.com/PandiO/knk-workspace/issues/377))
and the Phase 1 audit re-run ([#490](https://github.com/PandiO/knk-workspace/issues/490)) are still open, so this is
not live-tested behaviour.
**Related:** [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md) (phases, decisions Q1–Q8, developer
tests, known limits); [behavior model § 2](../specs/npc-platform/BEHAVIOR_MODEL.md) (requirements NAV-01–NAV-18);
[plugin architecture](plugin-architecture.md); [chain progress report](../reports/2026-11-13-npc-navigation-chain.md)
(what each phase built, with the agent decisions); parent issue
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
| Groups | `knk-core` `core/npc/nav/group/` | Groups that plan once: leader, followers in formation slots, folding into a column where the way is narrow | None |
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
| `NpcMover`, `NpcMoverFactory` | `CitizensNpcMover`, created by `CitizensBootstrap` | Spawn, walk a stretch of waypoints or a local leg, stop, despawn; the factory is absent without Citizens |
| `RoadPlanner` | `NavigationService.planRoadFor` (road router with the subject's access policy) | The road part of a route on the K&K road graph; needs no loaded chunks (NAV-14) |
| `LocalLegPreparer` | `NpcLegPreparer` on the walk capture (`WalkLegPreparer.capture`) | Captures the terrain box around a short leg and decides gate, door and region access in it; never loads chunks |
| `NavWorld` | `BukkitNavWorld` | Floors, loaded chunks and region ids; never loads a chunk |
| `AccessSubject` | `PlayerAccessSubject` (players), `NpcAccessSubject` with an `NpcAccessProfile` (NPCs) | Who moves, as far as the access rules care, so an NPC never borrows a player's rights |
| `RuleChangeListener` | Registered on road navigation with `addRuleChangeListener` | A gate changed state, or availability changed (domain cache refresh, siege lockdown start or end). It may be called off the main thread; the module moves the call to the main thread |

Player navigation keeps its own `Player` methods. The `AccessSubject` overloads of `NavigationAccess`,
`WalkAccessFactory` and `WalkLegPreparer` share the same private rule code, and tests compare the player and subject
verdicts case by case (report block 4.1 § 5.4).

## 3. How one order runs

`NpcNavigationService` keeps a state per NPC (`NpcNavState`: `IDLE`, `QUEUED`, `PLANNING`, `MOVING`, `WAITING`,
`PAUSED`; `SIMULATED` is reserved for Phase 7b). The metrics use these names in lower case.

1. **Queue and plan.** An order waits for a planning slot (`max-plans-in-flight`). The road route is planned on the
   road graph for the NPC's access subject, from where it stands. A goal within `hop-blocks` is one local leg with no
   road plan. A trip with an end too far from any road is walked in short hops only when the whole trip is at most
   `walk-only-blocks` long; otherwise the order fails. There is never a straight-line fallback across terrain.
2. **Follow the road line (trail mode, decision Q8).** `RouteFollower` turns the road line into floor points and hands
   the mover one stretch (`stretch-blocks`) of waypoints at a time. The next stretch is prepared before the current
   one ends. Only the stretch ahead is looked at in the world.
3. **Local legs.** The off-road ends, short trips and recovery legs use Citizens' own path search, cut into hops by
   `HopPlanner`. `KnkBlockExaminer` puts K&K's verdicts in front of Citizens' examiners: a cell the leg blocks (a
   closed gate, a denied region, a door the NPC may not open, anything outside the captured box) is impassable before
   Citizens is asked. Examiners that Citizens adds by itself are removed and counted as `examiner_leak`
   (must stay 0).
4. **Watchdog and failure.** If an NPC makes no progress along the line, it is stuck. A hop or stretch is retried
   `max-retries` times. Then the route is dropped, the NPC waits `no-route-wait-ticks` and plans again from where it
   stands, at most twice per order (`MAX_REPLANS`). After that the order ends as `FAILED`, and the caller gets a
   `NavigationResult`. What happens next is for the behaviour layer to decide.
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

## 5. Groups (Phase 4)

`NavGroupService` sits on top of the navigation service's public methods. A group's leader is an ordinary order, and
each follower walks the leader's path in a slot of the group's formation (`column`, `ranks`, `cluster`,
`escort-ring`). Where the path is too narrow for the formation, the group folds into a column and forms up again
afterwards. A follower that falls too far behind gets its own leg back (`group-rejoin-blocks`, `group-regroup-blocks`,
`group-catch-up-speed`). After a rule change the leader plans again once for the whole group, and the followers'
lanes are checked again. The group takes its `group-*` settings once, from the leader's settings layers. The service
ticks once per server tick, before the navigation service.

## 6. Settings layers

`NavigationSettings` resolves each per-NPC key from the most specific layer that sets it: code default → global
(`npc.navigation`) → world → region (WorldGuard region or domain id; the innermost region wins) → template →
assignment. Every resolved value records the layer it came from, and `/knk npc status` shows that layer. Templates have
no source yet; they come with the behaviour layer. The only assignment so far is the formation given to
`/knk npc nav group <n> <formation>`. The keys and their ranges are in the configuration
reference § 4.27. Values out of range are rejected at start and logged as `[NPC] config ...`.

## 7. NPCs and the player listeners

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

## 8. Runtime files, metrics and threads

1. **Files** under `plugins/KnightsAndKings/`: `npc-routes.yml` (the test routes of `/knk npc nav`; the spike's
   `npcspike-routes.yml` is taken over on first use) and `npc-logs/` (a log per server start with every stuck event
   and its position, the `/knk npc nav stats` output, per-NPC traces and the audit reports).
2. **K&K is the source of truth.** `CitizensNpcRuntime` keeps K&K's NPCs in memory and uses an in-memory Citizens
   registry, so nothing goes into Citizens' saves. Test NPCs are gone after a restart.
3. **Metrics.** `NpcNavigationMetrics` counts whenever NPC navigation runs (it feeds `/knk npc nav stats`). It is
   exported on the plugin's metrics endpoint only with `metrics.enabled`. A once-per-second task publishes the
   per-world state counts and its own main-thread cost.
4. **Threads.** The service, groups, mover and world queries run on the main thread. Road plans and the domain part of
   a leg capture complete on other threads and are handed back to the main thread. Spawns are spread out by
   `NpcSpawnQueue` (`spawns-per-tick`).

## 9. Not built yet

Phases 5–8 of the [implementation plan](../specs/npc-platform/IMPLEMENTATION_PLAN.md): an NPC access identity in the
API and web app (5), detours and hidden routes (6), movement quality (7) and movement outside loaded areas (7b), and
the benchmark gate (8). There is no gameplay NPC yet: `/knk npc test` and `/knk npc nav` are test drivers that stand
in for the behaviour layer. The plan's "Known limits" notes under Phases 2–4 list what the merged phases do not do.
