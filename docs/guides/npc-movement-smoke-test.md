# NPC movement quality, Phase 4c links M1–M7 — smoke test

**Status:** Written 2026-11-16 for knk-plugin `next` `cc5262ff` (links M1–M7 merged into `next`, behind
`npc.navigation.enabled` and each link's own key, all off by default); only the steps no plugin scenario checks; not
run yet (the developer's run with every key on is planned for 2026-11-16)
**Last updated:** 2026-11-17 (link B5 section, [#699](https://github.com/PandiO/knk-workspace/issues/699)); 2026-11-16 (assembled from the developer tests of implementation plan 4c.4, PandiO/knk-workspace#658)
**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358) (links
[#621](https://github.com/PandiO/knk-workspace/issues/621)–[#627](https://github.com/PandiO/knk-workspace/issues/627));
post results on the link's sub-issue or [#603](https://github.com/PandiO/knk-workspace/issues/603)
**Related:** [NPC navigation admin guide](admin/npc-navigation-admin-guide.md) (the keys and the stats lines),
[implementation plan 4c.4](../specs/npc-platform/IMPLEMENTATION_PLAN.md) (each link's developer test),
[writing a plugin scenario § 1](developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines) (what the scenarios
check)

About 90 minutes for a full run (several 10-minute walks). Record each step as works / doesn't, with the `stats`
output.

## What the scenarios already check (not repeated here)

CI's `paper-boot` job runs these on a real Paper server with Citizens, collision off and on
([CI § 7.1](developer/ci.md#71-in-plugin-scenarios)); the steps below cover only what they can't: the real dev world,
50 NPCs for 10 minutes, a real client and how it looks.

1. `npc-stairhouse-singles` and `npc-jagged-straight`: 12 singles with `corridor-steering` on arrive with 0 stuck
   spells, nobody still over 3 s, no fall, within the cost budget; `npc-stairhouse-singles` also no local leg without
   a path (`local-legs-clearance`).
2. `npc-stairhouse-group`, the group of `npc-jagged-straight`, `npc-plaza-line`'s group and `npc-group-narrows`:
   `elastic` groups fold only at 1-wide places, no stuck spell left open or near a wall.
3. `npc-doorway-crowd` and `npc-stairhouse-group`: with `crowd-awareness`, 0 stuck spells, no wait longer than the
   queue ahead needs, nobody let go after 30 s.
4. `npc-plaza-line`: the singles cross within 5 % of the shortest line that keeps clear of the well.
5. `npc-collision-policy`, `npc-guard-ledge-push` and `npc-door-column`: with `collidable`, a scripted player never
   moves an NPC; with `players-push-npcs` a pushed guard on a wall walk never falls and walks back; 12 singles pass a
   one-block door.

## Setup

1. A dev server with Citizens 2.0.44 build 4269, the knk-plugin jar from `next` (at least `cc5262ff`), the dev
   world with its road network and the routes `quarry-to-keep` and `south-gate-short`, and an op account with a real
   client.
2. Merge the `npc.navigation` keys from the [configuration reference § 4.27](admin/plugin-configuration.md#427-npc)
   into the server's `config.yml` and set `npc.navigation.enabled: true`.
3. For steps 1–9 turn on: `corridor-steering: true`, `local-legs-clearance: true`,
   `group-formation-keeping: elastic`, `plaza-lines: true`, `crowd-awareness: true`. Leave `collidable: false` until
   step 10. Restart.
4. `/knk npc status` lists each of these keys with the value you set and the layer `global`.
5. `/knk npc nav baseline` before spawning anything.

## Steps

1. **Singles on the real stair house (M2, M6, M4).** `/knk npc nav route load quarry-to-keep`,
   `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 50`, wait 10 minutes. Look: nobody stuck at
   1414 49 -503 or in the stair-house entrance (1413 49 -508); NPCs walk the straights off the wall and through the
   middle of doorways. Then `/knk npc nav stats`: `not freed 0`, `longest still` under 3 s, `local legs: k&k` well
   above `engine` and `none 0`, `engine found no path 0`, `crowd: waits` above 0 where NPCs meet at narrow places
   and `yields` 0 or a few, no stuck spell for an NPC that only waited.
2. **Cost (all links).** In the `stats` of step 1: `K&K navigation on the main thread … (N ms per NPC)` under 0.03.
3. **NPCs meeting in a door (M4).** Stand by a one-block door on the route (or the south gate's door where it is one
   block wide) and watch NPCs meet there: one direction at a time, the others waiting a block to the side of the line,
   nobody standing in the door while another waits for it, nobody walking through another. `stats`: `longest queue`
   is the most that met there.
4. **A group on the stair house (M3).** `/knk npc nav clear`, `/knk npc nav stats reset`,
   `/knk npc nav group 20 ranks`, 10 minutes on `quarry-to-keep`. Look: the group tightens before the stair house
   instead of folding, walks the 3-wide parts 3 abreast (2 with the code default `group-ranks-width: 2`), folds only
   where one NPC fits, no jam at the entrance. `stats` groups line: `folds` at most the number of 1-wide places per
   trip, each with its reason; `merges` with reasons; `not freed 0`. Note how it looks.
5. **A group at a gate (M3).** `/knk npc nav route load south-gate-short`, `/knk npc nav group 20 ranks`: pairs or
   threes through the 2-wide gate without folding, a column only for a 1-wide door, queued a spacing apart.
6. **A group against oncoming singles (M4).** `/knk npc nav route load quarry-to-keep`, `/knk npc nav clear`,
   `/knk npc nav stats reset`, `/knk npc nav spawn 10`, then `/knk npc nav group 20 ranks`. Singles coming the other
   way wait at a narrow place until the whole group is through; no follower opens a stuck spell for waiting (`stuck
   spells` in `stats` stay at the baseline).
7. **NPCs leaving a stuck spot (M6).** During steps 1 and 4, any NPC that gets stuck at the stair house leaves by a
   leg that keeps off the walls (watch, or `/knk npc nav trace` on it).
8. **A plaza (M5).** Name a plaza on the dev world and a route across it (plan 4c.6 item 12: the developer names it
   here). `/knk npc nav route load <the route>`, `/knk npc nav clear`, `/knk npc nav spawn 10`,
   `/knk npc nav trace 60` on one NPC: its `# waypoints:` cross the plaza on a straight line from where the road
   enters to where it leaves, not through the middle, and keep off a well or stall. Then `/knk npc nav group 9 ranks`
   across it: the group takes the same line, 0 folds.
9. **Corridor trace (M1).** In the trace file of step 8 (`npc-logs/`), every `# waypoints:` line is followed by a
   `# corridor:` line with each waypoint's free width (total, left, right).
10. **Bodies, players never push (M7).** Set `collidable: true` (the keys of step 3 still on), restart.
    `/knk npc nav spawn 1` next to you on flat ground and walk into it from every side: the NPC does not move, you
    feel at most a nudge.
11. **Bodies by a drop (M7).** Stand on a wall walk or a stair landing beside a drop on `quarry-to-keep` with
    `/knk npc nav spawn 10` and walk into the NPCs: none moves, none falls.
12. **Players push (M7).** Set `players-push-npcs: true`, restart, repeat step 10: the NPC is pushed and walks back to
    where it stood; after the third push within 10 s you pass through it (the log says
    `collision between them off for 60 s`). Push one towards the drop of step 11: you pass through it at once and it
    doesn't fall.
13. **Knockback (M7).** Make an NPC unprotected (`/npc select`, `/npc protect`) and hit it while it walks: it is
    knocked back and walks back to its line.
14. **Push counters (M7).** `/knk npc nav stats`: the `pushes:` line counts your pushes, `returned` grows with them,
    `teleported` 0 while you watch.
15. **The default for bodies (M7).** Report whether NPCs jostling each other on the dev world's stairs and gates look
    natural, and whether any falls. This and plan 4c.4 item 7.4.10 decide whether `collidable` turns on by default;
    together with steps 1–8 they also decide whether option B (plan 4c.4 item 8) is needed.

## Link B5: a group of 20 up the stair house to the keep (retest of 2026-11-17 steps 2 and 3)

Added 2026-11-17 for knk-plugin `claude/npc-movement-b5` ([#699](https://github.com/PandiO/knk-workspace/issues/699));
run it on `next` once B5 is merged. Same setup as above (steps 1–9 keys on, `collidable: false`). 2 of 3 steps partly
automated (tagged); every step can still be run by hand; not run yet. About 15 minutes; 10 minutes for the untagged
step only.

1. [partly automated: `npc-replay-quarry-to-keep`, the group of 20 to the route's end with the stored settings; by
   hand: the whole route from the quarry, how it looks] **A `ranks` group of 20.** `/knk npc nav route load
   quarry-to-keep`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20 ranks`. Follow the group
   up the stair house and stand by flights 4 and 5 (the flights under the top passage, 1408–1416 67–76 −548…−534).
   Look: the followers climb flight 4, cross the landing at −546, climb flight 5 and cross the landing at −536 behind
   their leader; none walks back down a flight it climbed; the leader never stands on the passage over flight 4 while
   its followers mill about below it. The group reaches the keep (1421 85 −516). In the `npc-logs/` run log: no
   "is off its lane" line at the stair house, no follower with the same "its own leg back" line again and again, no
   "group … walks on: a follower did not close up". `stats` groups line: `own legs back` near 0, `left behind 0`.
2. [partly automated: the same scenario's checks (followers off their lane on the flights and landings, looping
   followers); by hand: the crowd of 40] **The group with 20 singles.** `/knk npc nav clear`, `/knk npc nav spawn 20`,
   then `/knk npc nav group 20 ranks`. The singles and the group both arrive; the group as in step 1.
3. **How it looks** (manual: game feel). Whether the group still looks like a formation on the flights (a column on the
   stairs, pairs on the landings), and anything odd at the first steps of flight 4, where the hall floor lies a block
   below the step (plan 4c.8 item 4.7.2).

## After the run

Set `collidable` and `players-push-npcs` back to `false` unless you keep testing them. Post the `stats` output, the
run log from `npc-logs/` and your notes.
