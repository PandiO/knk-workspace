# NPC navigation (admin)

**Status:** Current · **Last updated:** 2026-11-16 (first version: turning NPC navigation on, the test commands, every movement key of Phase 4c and the stats lines; PandiO/knk-workspace#658, with #497)
**Checked against:** knk-plugin `next` `cc5262ff` (Phases 1–4, Phase 4b links L2–L4, Phase 4c links M1–M7). None of
it is on trunk yet.
**Applies to:** knk-plugin `next` only, with `npc.navigation.enabled: true` (default `false`). **Not live-tested:** the
developer tests of Phase 4b ([#520](https://github.com/PandiO/knk-workspace/issues/520),
[#521](https://github.com/PandiO/knk-workspace/issues/521), [#522](https://github.com/PandiO/knk-workspace/issues/522))
and of the movement links M1–M7 ([#621](https://github.com/PandiO/knk-workspace/issues/621)–[#627](https://github.com/PandiO/knk-workspace/issues/627))
are still open. What this page says comes from the code and the plugin scenarios on CI's Paper server with Citizens.
**Related:** [NPC navigation architecture](../../architecture/npc-navigation.md) (how it works),
[plugin configuration § 4.27](plugin-configuration.md#427-npc) (every key, its range and the YAML to paste),
[commands guide](../users/commands.md) (`/knk npc`), [NPC movement smoke test](../npc-movement-smoke-test.md),
[Citizens stress test](../citizens-stress-test.md), [implementation plan](../../specs/npc-platform/IMPLEMENTATION_PLAN.md)

There is no gameplay NPC yet. K&K plans NPC routes on the road graph and under the gate and access rules, and the
Citizens plugin moves the bodies. Today only staff test drivers use it (`/knk npc`), so players see test NPCs walking
roads and nothing else. This page is for the person who turns it on on a dev or test server.

## 1. Before you start

1. **Citizens.** Install the Citizens build K&K is built against: Citizens 2.0.44 for Minecraft 26.3, server build
   4269 (`citizensApiVersion` in knk-plugin `gradle.properties`; CI pins the same jar). Without it K&K starts normally
   and NPC navigation says why it is off.
2. **Road navigation.** `navigation.enabled` and `navigation.walk.enabled` must be on (§ 4.15 of the configuration
   reference); local legs need the walk capture. The routes run on the road graph, so the world needs a built road
   network ([navigation and teleports admin guide](navigation-and-teleports-admin-guide.md)).
3. **Permission.** Every `/knk npc` command needs `knk.admin.npc` (op by default).
4. **Config keys.** The plugin never adds new keys to an existing `config.yml`. Merge the `npc.navigation` block from
   [§ 4.27](plugin-configuration.md#427-npc) by hand, with the movement keys of Phase 4c, before you restart.

## 2. Turning it on and checking it

1. Set `npc.navigation.enabled: true` and restart. Every key under `npc.navigation` applies on restart only.
2. The startup log has `[NPC] navigation: Citizens 2.0.44-SNAPSHOT (build 4269), override scopes {…}`, or
   `[NPC] navigation unavailable: <reason>`. The reasons: `npc.navigation.enabled is false`, `Citizens is not
   installed`, `Citizens is installed but not enabled`, or `Citizens adapter failed: …` (with a stack trace in the
   log). A key with a wrong value is logged as `[NPC] config …` and skipped, so its default applies.
3. `/knk npc status` lists every setting with the layer it came from: the code default, the global layer
   (`npc.navigation`), `worlds.<world>`, `regions.<WorldGuard region or domain id>` (innermost wins), an NPC template
   or the assignment. Use it after every config change to see which value an NPC really gets.
4. **Turning it off:** `npc.navigation.enabled: false` and restart. Nothing runs then; `/knk npc` only reports. To
   turn off one movement feature, set its key back to its default (§ 4) for the server, a world or a region.

## 3. Test commands

The full syntax is in the [commands guide](../users/commands.md). The ones you use for a test:

1. `/knk npc nav route load <name>` (or `from` and `to` where you stand, then `route save <name>`) sets the route.
2. `/knk npc nav spawn <n> [profile]` spawns NPCs that walk the route back and forth, two spawns per tick.
3. `/knk npc nav group <n> [formation] [profile] [finish-trip|follow-leader]` spawns one group: the first NPC leads,
   the others follow in formation (`column`, `ranks`, `cluster`, `escort-ring`).
4. `/knk npc nav stats` prints the counters (§ 5), `/knk npc nav stats reset` starts them again,
   `/knk npc nav baseline` (before spawning) measures the server's tick without NPCs.
5. `/knk npc nav trace [npc] [seconds]` writes one NPC's path to a file: `# waypoints:` lines and, after each, a
   `# corridor:` line with each waypoint's free width across the line (total, left, right; at most 4 a side).
6. `/knk npc nav clear` removes the test NPCs.

Run files, traces and audit reports go to `plugins/KnightsAndKings/npc-logs/`.

**Access profiles** (`npc.navigation.access-profiles.<id>`) stand in for NPC permissions until Phase 5: whether an
NPC may ignore domain rules, open hand-openable doors on off-road legs, and which regions it may or may never enter.
NPCs never pass a closed gate, whatever the profile. The trespass guard logs and counts an NPC found in a region its
rules deny (the `rules: trespasses` count must stay 0); `stop-on-trespass: true` also stops it and plans again, for
dev servers.

## 4. The movement keys (Phase 4c)

Each feature has its own key and is off by default, so a server on `next` walks as before until you turn one on. All
are per-NPC settings: set them globally, per world or per region. Values, ranges and the YAML are in
[§ 4.27](plugin-configuration.md#427-npc).

| Key (default) | What it changes when on | What to watch |
|---|---|---|
| `corridor-steering` (`false`), with `corridor-half-width` (4) and `wall-clearance` (0.8) | Each stretch of the route line is moved off walls, posts and drops by `wall-clearance` where the road is wide enough (on straights too), straightened, and lined up through the middle of doorways and entrances (a waypoint 1.5 blocks before, one in it, one after). Narrower places are walked through their middle, so one-block doors stay open. A stretch is shaped once and shared by every NPC on it. Group members keep the leader's route; their group path is shaped with `elastic` (below) | NPCs walk straights away from the wall; `stuck near a wall` in `stats` stays low |
| `local-legs-clearance` (`false`) | Short trips, a follower's own leg back to its group and the recovery ladder's local leg are searched by K&K on its own walk grid, keeping `wall-clearance` where the gap allows, smoothed into a few straight steps. When K&K finds nothing, Citizens' search walks the leg as before | `local legs: k&k` well above `engine`, `none 0` |
| `group-formation-keeping` (`levels`), with `group-lateral-spacing-min` (0.6), `group-spacing-min` (1.0), `group-lookahead-blocks` (4) | `elastic`: a group fits its width to the free width across its path. Neighbours squeeze to 0.6 and rows close up to 1.0 before it narrows, it looks 4 blocks past its depth ahead, short tight places are passed with the lanes merged, and it walks as a column only where 2 abreast don't fit even squeezed. Stairs are walked as wide as each lane has its own step. `levels` is the Phase 4b behaviour | `merges` and `folds` with their reasons in the groups line; a column only at 1-wide places |
| `plaza-lines` (`false`), with `plaza-corridor-blocks` (16) | Where a route passes a plaza junction, the NPC walks the straight line from where the road enters the plaza to where it leaves, round wells, stalls and trees with `wall-clearance`, never into a region its line doesn't pass. Groups take the same line with their half width as margin. Works with or without `corridor-steering`; the players' trail is unchanged | `/knk npc nav trace`: the `# waypoints:` cross the plaza, not through its middle |
| `crowd-awareness` (`false`) | Narrow places on an NPC's way (under 2 blocks wide: a door, an arch, a passage) are taken in turns: one direction at a time, an NPC already in it first, then first come. The others wait a block apart, a block to the side of the line. Two NPCs meeting head-on inside one: the second to enter steps back out. A group's leader keeps the turn until its followers are through. Waiting is not counted as stuck; a queue lets an NPC go after 30 s (a deadlock guard) | `crowd: waits` above 0, `yields` 0 or a few, no stuck spell for a waiting NPC |
| `collidable` (`false`), with `players-push-npcs` (`false`), `push-return` (`true`), `push-exempt-after` (3), `push-exempt-window-ticks` (200), `push-exempt-ticks` (1200), `push-teleport-ticks` (600) | NPCs get bodies: they push and block each other. Players never move an NPC (each NPC is exempt from players' collision; no scoreboard team is touched); a real client still feels a slight nudge. Push resistance runs: a push the NPC's own walk doesn't explain is counted and logged with who did it, and the NPC walks back to its line or post (straight back, else along its footsteps, else a local leg; a teleport home after 600 ticks, and only while no player within 64 blocks can see it). Queue spots never stand next to a drop. With `players-push-npcs: true` players bump NPCs; a player who pushes one NPC 3 times within 10 s stops colliding with it for 60 s, at once when the push goes towards a drop | the `pushes:` line; no NPC falls |

**`collidable` stays off by default.** With bodies on, NPCs walking a 1-wide flight or ledge next to a drop can shove
each other off it, and push resistance can't undo that (a trial with collision on for every scenario failed
`npc-ledge-corner` and `npc-corners-walk` with a fall). Turn it on only per world or region where NPCs don't walk such
places, after a test there. Whether it becomes the default is open: it waits for the developer's tests and the items
of [implementation plan 4c.4 item 7.4.10](../../specs/npc-platform/IMPLEMENTATION_PLAN.md). Whether a short-horizon
steering layer (option B, plan 4c.4 item 8) is needed is open too.

Known limits of the merged code:

1. With `collidable` on, bodies in a squeezed `elastic` row still overlap at times (slots exactly a body width apart);
   holding them apart needs a wider minimum, a decision that is open (plan 4c.4 item 7.4.7).
2. With `collidable` and `crowd-awareness` on, the first two NPCs at a one-block door before a queue forms can both
   claim it and shove each other against the frame (freed within a few seconds): [#657](https://github.com/PandiO/knk-workspace/issues/657).
3. A group whose followers stand 0.1–0.2 short of their slots past the path's end reports its arrival only after its
   20 s settle time: [#636](https://github.com/PandiO/knk-workspace/issues/636).
4. There is no stats line for corridor steering itself: its shaped and shared stretches and its cost show in the
   plugin scenarios' report lines, and on a server only in the `K&K navigation on the main thread` figure.

## 5. Reading `/knk npc nav stats`

The same lines go to the run file in `npc-logs/`. The older lines (NPCs and states, tick, trips, stuck spells, waits,
rules, examiner, distance from the road line, groups) are explained in
[architecture § 10](../../architecture/npc-navigation.md#10-counters-and-the-stats-lines-phase-4b). The lines the
movement keys add or change:

1. `K&K navigation on the main thread: mean x µs per tick, p95 y µs (z ms per NPC)`: K&K's own cost. The budget for
   Phase 4c is 0.03 ms per NPC per tick.
2. `local legs: k&k N, engine N, none N` (`local-legs-clearance`): legs K&K's search found; legs Citizens' search
   walked (K&K found nothing, or the key is off); legs neither found (`none` should stay 0).
3. `crowd: waits N, yields N, longest queue N` (`crowd-awareness`): waits for a turn, behind another NPC or after
   stepping aside, counted once per wait; NPCs that stepped back out of a narrow place for one coming the other way;
   the most NPCs waiting at one place (both directions).
4. `pushes: N (players N, attacks N), returned N, exempted N (now N), teleported N` (`collidable`): pushes the NPCs'
   own walk doesn't explain, by players and by attacks; walks back that ended; players exempted from an NPC after
   repeated pushes (and how many still are); teleports home. All 0 with `collidable` off.
5. The groups line has `widths: narrows N (reasons), widens N, merges N (reasons)` and `folds N (reasons)`. The
   reasons are `door`, `stair`, `rules` (a region the group may not enter), `edge` (a drop) and `narrow` (a wall);
   `merges` only with `elastic`.

The metrics endpoint has the same events (`knk_npc_nav_events_total{event=…}`: `local_leg_knk`, `local_leg_engine`,
`local_leg_none`, `crowd_wait`, `crowd_yield`, `pushed`, `push_returned`, `push_exempt`, `push_teleport`) and
`knk_npc_nav_group_width_reasons_total{change, reason}`.

## 6. A safe test

1. On a dev server, not the alpha: merge the keys, set `npc.navigation.enabled: true`, restart, and check the
   startup line and `/knk npc status` (§ 2).
2. `/knk npc nav baseline`, then `/knk npc nav route load <route>`, `/knk npc nav stats reset` and
   `/knk npc nav spawn 10`. Watch them walk, then `stats`: `rules: trespasses 0`, `not freed 0`.
3. Turn on one movement key at a time (§ 4), restart and repeat with the numbers of the
   [NPC movement smoke test](../npc-movement-smoke-test.md), so a change in the counters has one cause.
4. `/knk npc nav clear` when done. The test NPCs are Citizens NPCs; `clear` removes them. Nothing is written to the
   API or the database, and existing data is not changed.

## 7. When something goes wrong

1. **`/knk npc` says navigation is unavailable:** read the reason (§ 2 item 2). With the switch on and Citizens
   installed, check the Citizens build.
2. **NPCs stand still at a wall or in an entrance:** `stats` stuck spells and `longest still … at x y z` name the
   spot. Try `corridor-steering` and `local-legs-clearance` there (a region override is enough), and post a
   `/knk npc nav trace` of one NPC with the issue.
3. **A group folds or jams where it should fit:** the groups line names the reason for each fold. Try
   `group-formation-keeping: elastic`.
4. **NPCs crowd a door or walk through each other:** `crowd-awareness`; with bodies on (`collidable`), see the known
   limits in § 4.
5. **An NPC fell or was pushed off a ledge:** with `collidable` on, turn it off for that world or region and report
   the spot; `falls` in the stuck-spells line counts them.
6. **`trespasses` above 0:** an NPC entered a region its rules deny, which must never happen. Turn on
   `stop-on-trespass` on the dev server, reproduce, and file a bug with the run file.
