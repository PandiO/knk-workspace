# NPC movement quality, Phase 4c links M1–M7 — smoke test

**Status:** Written 2026-11-16 for knk-plugin `next` `cc5262ff` (links M1–M7 merged into `next`, behind
`npc.navigation.enabled` and each link's own key, all off by default); only the steps no plugin scenario checks; not
run yet (the developer's run with every key on is planned for 2026-11-16)
**Last updated:** 2026-11-20 (link H1 section, [#779](https://github.com/PandiO/knk-workspace/issues/779)); 2026-11-18 (link R1 section, [#724](https://github.com/PandiO/knk-workspace/issues/724)); 2026-11-18 (link E1 section, [#701](https://github.com/PandiO/knk-workspace/issues/701)); 2026-11-18 (link C1 section, [#700](https://github.com/PandiO/knk-workspace/issues/700)); 2026-11-17 (link B5 section, [#699](https://github.com/PandiO/knk-workspace/issues/699)); 2026-11-16 (assembled from the developer tests of implementation plan 4c.4, PandiO/knk-workspace#658)
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

## Link C1: off-road ends with the walk search (retest of 2026-11-17 step 5)

Added 2026-11-18 for knk-plugin `claude/npc-movement-c1` ([#700](https://github.com/PandiO/knk-workspace/issues/700));
run it on `next` once C1 is merged. Same setup as above (steps 1–9 keys on, `collidable: false`). 2 of 4 steps partly
automated (tagged); every step can still be run by hand; not run yet. About 20 minutes; 10 minutes for the untagged
steps only.

1. [partly automated: `npc-replay-keep-tower`, a leader alone and a group of 20 from the keep's road on the replayed
   snapshot; by hand: the whole route from its start] **One NPC up the keep tower.** `/knk npc nav route load
   northern-wearway-upper-keep-tower`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 1`. Follow
   it: after the road it walks through the throne room, through the open door at 1405 104 −494 and up the spiral
   staircase to the goal (1401 113 −502), without stopping at 1405 85 −510. In the `npc-logs/` run log: one line
   "off-road walk to the goal … from the road at …: N cells (… blocks walked, … expansions, cap … blocks, body check:
   …)" and no "walked in hops"; no "engine found no path". `stats`: `orders failed 0`.
2. [partly automated: the same scenario's group of 20; by hand: the group from the route's start, how it looks]
   **A `ranks` group of 20 up the tower.** `/knk npc nav clear`, then `/knk npc nav group 20 ranks`. The leader arrives;
   the followers come up the spiral behind it in single file and end on the tower's top or the last turns of the
   stair; `stats` groups line: `lost 0`, `left behind 0`.
3. **An off-road start** (manual: needs a start the scenarios do not have). Set the route's start a few blocks inside
   a building beside a road whose nearest point is behind a wall (`/knk npc nav route from` standing there), the end on
   the road. `/knk npc nav spawn 1`: the NPC walks out through the building's door and joins the road where it can
   reach it, not at the point behind the wall. Log: "off-road walk from … joins the road at …".
4. **A new snapshot of the tower route** (manual: the command on the dev server). `/knk npc nav snapshot
   northern-wearway-upper-keep-tower`; its `manifest.json` box reaches above y 113 (the goal) and round the route's
   start (1279 64 −621). Put the zip on the evidence branch.

## Link E1: exit denied mid-trip

Added 2026-11-18 for knk-plugin `claude/npc-movement-e1` ([#701](https://github.com/PandiO/knk-workspace/issues/701));
run it on `next` once E1 is merged. Same setup as above; the movement keys don't matter for this section. Realtime on
(the web app and the server connected to the hub). 2 of 3 steps partly automated (tagged); every step can still be run
by hand; not run yet. About 15 minutes; 5 minutes for the untagged step only. The full steps, with what to look for in
`stats` and the log, are plan Phase 4 developer test step 15.

Pick a district a stored route leaves, with nothing else denied on the way, or save a short one from inside a district
to a point 30 blocks outside it (`/knk npc nav from`, walk out, `/knk npc nav to`, `/knk npc nav route save
exit-short`).

1. [partly automated: `npc-exit-denied-leader` (realtime deny, allowed again through a cache refresh), knk-core
   `NavGroupExitRulesTest`; by hand: the real web app, hub and API, a real district, the log] **A leader alone.**
   `/knk npc nav route load exit-short`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 1`.
   When the NPC is about 10 blocks from the edge, still inside, set the district's AllowExit to false in the web app
   (no `/knk cache refresh`). Look: within about a second it stops at the edge, inside; the `npc-logs/` run log has
   "way ahead is closed by exit <region> (event)"; `stats` `rules: trespasses 0`. Set AllowExit back to true: it walks
   out to the route's end.
2. [partly automated: `npc-group-exit-denied` (both ways through realtime), knk-core `NavGroupExitRulesTest`; by hand:
   a group of 20 on a real district, the log] **A group half inside.** `/knk npc nav clear`, `/knk npc nav stats
   reset`, `/knk npc nav group 20`. When the leader and a few followers are out and the rest are still inside, set
   AllowExit to false. Look: the followers inside stop at the edge, inside, and none leaves; the leader and the ones
   out walk on (`leader waited 0`); no `TRESPASS` line, `trespasses 0`. Set AllowExit back to true: the rest walk out
   and follow.
3. **The refresh path** (manual: needs the real `/knk cache refresh`). Repeat step 2 with `/knk cache refresh` right
   after each change: the same result, and `[KnK Resolver] warmCache: completed` in the log. A held follower that walks
   out in the half second right after the refresh was the known gap #724, fixed by link R1 (see the next section).

## Link R1: a cache refresh while NPCs are held at an edge

Added 2026-11-18 for knk-plugin `claude/npc-movement-r1` ([#724](https://github.com/PandiO/knk-workspace/issues/724));
run it on `next` once R1 is merged. Same setup as above; the movement keys don't matter for this section. Realtime on
(the web app and the server connected to the hub). 2 of 3 steps partly automated (tagged); every step can still be run
by hand; not run yet. About 15 minutes; 5 minutes for the untagged step only.

1. [partly automated: `npc-group-cache-refresh-held` (followers held inside a district they may not leave, a cache
   refresh with the rules unchanged, the fake API answering 2 s later), knk-core `NavGroupCacheRefreshTest`
   (entry and exit, followers and a single NPC); by hand: the real web app, hub and API, a real district, the log]
   **Followers held at the edge, then a refresh.** `/knk npc nav route load quarry-to-keep` (or your `exit-short`),
   `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav group 20`. When about half the column is inside the
   Residential District, set its AllowEntry to false in the web app (no refresh yet). Wait until the outside followers
   stand still at the edge. Then run `/knk cache refresh` three times, a few seconds apart. Look: none of the held
   followers enters, not even for a block, during or after each refresh; the log has `[KnK Resolver] warmCache:
   completed` after each one; no `TRESPASS` line; `stats` `rules: trespasses 0`. Set AllowEntry back to true: they
   follow.
2. [partly automated: knk-core `NavGroupCacheRefreshTest` (`anNpcHeldInADistrictItMayNotLeaveStaysHeldThroughACacheRefresh`
   and the entry case); by hand: a real NPC, district and API] **A single NPC held at the edge, then a refresh.**
   `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 1` on `exit-short`. When the NPC is about 10
   blocks from the edge, still inside, set the district's AllowExit to false. When it stands at the edge, run
   `/knk cache refresh`. Look: it stays inside at the edge; `trespasses 0`. Set AllowExit back to true: it walks out.
3. **A real change with a refresh at once** (manual: the real order of the realtime hub and the refresh). Repeat step 1,
   but run `/knk cache refresh` within a second of setting AllowEntry back to true. Look: the followers follow within
   about a second of the refresh (they switch to the new answers when the re-warm's event comes, not before); no
   `TRESPASS` line.

## Link H1: a ladder and a roof hatch on an NPC's off-road leg

Added 2026-11-20 for knk-plugin `claude/npc-movement-h1` ([#779](https://github.com/PandiO/knk-workspace/issues/779));
run it on `next` once H1 is merged. Same setup as above; the movement keys don't matter for this section. 4 of 6 steps
automated or partly automated (tagged); every step can still be run by hand; not run yet. About 20 minutes; 10 minutes
for the untagged steps only.

Setup:

1. Build or pick a tower whose only way onto the roof is a ladder on an inside wall and a wooden trapdoor in the roof
   right above the ladder's top. Place the trapdoor so that, when open, its panel lies against the same wall as the
   ladder; Minecraft lets a player climb through it then. Stand on the road nearest the tower and run
   `/knk npc nav from`. Stand on the roof, a few blocks from the hatch, and run `/knk npc nav to` and
   `/knk npc nav route save hatch-tower`.
2. Add a second access profile without door opening to `config.yml` (it is a map: no new key), then restart:

   ```yaml
   npc:
     navigation:
       access-profiles:
         no-doors:
           bypass-domain-rules: false
           open-doors: false
           allow-regions: []
           deny-regions: []
   ```

Steps:

1. [automated: `npc-ladder-hatch`, trip "hatch open, open-doors"] **Open hatch, a default NPC.** Open the hatch by hand.
   `/knk npc nav route load hatch-tower`, `/knk npc nav clear`, `/knk npc nav stats reset`, `/knk npc nav spawn 1`. The
   NPC walks off the road into the tower, climbs the ladder, passes through the hatch and steps onto the roof. It
   stops near the goal and does not stand still at the ladder's foot. In the `npc-logs/` run log you see one line
   "off-road walk to the goal … body check: 0 cells closed …", and no "walked in hops" or "engine found no path".
   `stats` shows `orders failed 0` and no stuck spells.
2. [automated: `npc-ladder-hatch`, trip "hatch open, no open-doors"] **Open hatch, an NPC that may not open doors.**
   The hatch is still open. `/knk npc nav clear`, `/knk npc nav spawn 1 no-doors`. The same as step 1: an open hatch
   is no door to open.
3. [automated: `npc-ladder-hatch`, trip "hatch closed, open-doors"] **Closed hatch, a default NPC.** Close the hatch by
   hand, then `/knk npc nav clear`, `/knk npc nav spawn 1`. On its way up the ladder, the NPC opens the hatch with the
   trapdoor sound just before its head reaches it, climbs through and arrives on the roof. About 1.5 s after it has
   left the hatch, the hatch closes again by itself.
4. [partly automated: `npc-ladder-hatch`, trip "hatch closed, no open-doors"; by hand: what the order ends with]
   **Closed hatch, an NPC that may not open doors.** The hatch is closed. `/knk npc nav clear`,
   `/knk npc nav spawn 1 no-doors`. The NPC never opens the hatch and never gets onto the roof. The log shows "off-road
   walk to the goal …: NO_PATH …, walked in hops". Known: the order then ends as arrived under the roof
   ([#848](https://github.com/PandiO/knk-workspace/issues/848)). Note what `stats` says.
5. **Climbing down** (manual: no scenario walks down). Save the reverse route (`/knk npc nav from` on the roof,
   `/knk npc nav to` on the road, `/knk npc nav route save hatch-tower-down`), close the hatch, then
   `/knk npc nav route load hatch-tower-down`, `/knk npc nav clear`, `/knk npc nav spawn 1`. The NPC spawns on the
   roof, opens the hatch beside it, climbs down the ladder and walks out to the road. It must not fall down the shaft.
6. **Game feel** (manual: needs a real client). Watch steps 1 and 3 from the roof and from the ladder's foot. The climb
   looks like a player's: no hopping on the ladder and no sliding back down. The hatch opens before the head touches
   it, not while the NPC is still on the ground.

## After the run

Set `collidable` and `players-push-npcs` back to `false` unless you keep testing them. Post the `stats` output, the
run log from `npc-logs/` and your notes.
