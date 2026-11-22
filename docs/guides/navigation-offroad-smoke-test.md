# Off-road navigation and landmarks — smoke test

**Status:** Draft from the design (2026-11-17); no steps run. Drawn landmark regions (§ 6.5): 8 of 8 steps automated (2 in part); L7b (§ 15): step A 12 of 12 steps automated (2 in part), step B (§ 15.4) 5 of 8 automated (1 in part); F3 (§ 14): 8 of 8 steps automated (5 in part); F2 (§ 13): 7 of 9 steps automated (4 in part); F1 (§ 12): 5 of 7 steps automated (3 in part); Phase 5.2 (§ 7): 7 of 8 steps automated (3 in part); Phase 4 (§ 5): 8 of 9 steps automated (2 in part); Phase 2 (§ 3): 13 of 14 steps automated (5 in part); Phase 5.1 (§ 6): 21 of 22 steps automated (6 in part); Phase 0 (§ 1): 1 of 9 steps automated; phase 1 (§ 2): 4 of 4 steps automated; phase 6.1 (§ 8): 6 of 8 steps automated (3 of them in part); phase 6.2 (§ 9): 11 of 11 steps automated (3 of them in part); phase 7 step 1 (§ 10.1): 4 of 7 steps automated (3 of them in part), viewed by the developer 2026-11-18; phase 7 step 2 (§ 10.2): 9 of 9 steps automated (3 of them in part); the other phases not yet automated (the links tag them).
**Last updated:** 2026-11-21 (§ 6.5 drawn landmark regions, #944/#945: eight steps, all automated, two in part); 2026-11-21 (§ 15 enum follow-up of #852: `DefaultRouteMode` holds the enum names Shortest, Efficient and Preferred, the form field is an Enum field, § 15.3 step 2 for the rename migration, § 15.0 item 5 for player D and the road pair, § 15.4 count corrected to 5 of 8 with a clean-up step); 2026-11-20 (§ 15.4 L7b step B, the plugin uses a group's default route mode, #852: seven steps, four automated, one in part); 2026-11-20 (§ 15 L7b step A, a default route mode per permission group, #852: API, web and migration steps, eleven, all automated, two in part; in-game steps marked step B); 2026-11-20 (§ 14 F3, the smoke-test failures of 2026-11-19, #780, #771, #710: the road goal weighs the walk above the road, no repeated turn message, which end a 0-expansion search could not use, open doors passed without the door check, `trail-leg-spacing` shipped as 2.0: eight steps, all automated, five in part; shipped settings); 2026-11-19 (§ 13 F2, road goal by walk reachability, the road kept to its end and the flag-off walk-trail spacing, #780 and #771 items 3 to 5: nine steps, seven automated, four in part; shipped settings); 2026-11-19 (§ 12 F1, the walk-search fixes of #771 items 1 and 2: seven steps, five automated, three in part; shipped settings first, scene 1 by road recorded as known); 2026-11-18 (§ 7 phase 5.2 built by link L9, #709: eight steps, seven automated, three in part); 2026-11-18 (§ 5 phase 4 built by link L7, #707: nine steps, eight automated, two in part); 2026-11-18 (§ 3 phase 2 built by link L5, #705: fourteen steps, thirteen automated, five in part); 2026-11-18 (§ 10 phase 7: step 1 viewed by the developer, O33; § 10.2 step 2 built by link L10, #712: nine steps, all automated, three in part); 2026-11-18 (§ 6.3 phase 5.1 step B, link L8: the in-game steps); 2026-11-18 (§ 6 phase 5.1 updated to what link L8 step A built, #708: API and web steps, plugin steps marked step B); 2026-11-18 (§ 10 phase 7 split into step 1, built by link L10, #712: the staff preview and the developer's viewing steps on Cinix and Brink, and step 2, the trail, not built yet); 2026-11-18 (§ 9 phase 6.2 updated to what link L4 built, #711: eleven steps, all automated, three in part); 2026-11-17 (§ 8 phase 6.1 updated to what link L3 built, #710: eight steps, six automated); 2026-11-17 (§ 2 phase 1 updated to what link L2 built, #704: every step automated); 2026-11-17 (§ 1 phase 0 updated to what link L1 built, #703: the measurement steps and the `/knk road status` lines); 2026-11-17 (draft from the design, phases 0, 1, 2, 3, 4, 5.1, 5.2, 6.1, 6.2, 7)
**Design:** [specs/navigation-offroad/DESIGN.md](../specs/navigation-offroad/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#698](https://github.com/PandiO/knk-workspace/issues/698)

Scenes used throughout, on the dev world (the same builds as phase 0's measurements):

1. **Keep:** the big indoor build with wooden floors, several levels and corridors.
2. **Stair house:** the tower with the 3-wide spiral stair.
3. **Courtyard:** a courtyard where walking across is much shorter than the road around it.
4. **Open country:** a destination 200 blocks and one 400 blocks from the nearest road, over walkable ground with a
   lake or a cliff in between.
5. **Plazas:** the plazas of Cinix and Brink, and one street T junction (a 3-wide street meeting another).

Every phase is behind its own flag, off by default. With every flag off, navigation must behave exactly as before.

## 1. Phase 0: measurements (#703, tier:1)

*Updated by link L1 (2026-11-17) to what was built: the counters are on knk-plugin `claude/offroad-measurements`
(PR into `next`). 1 of 9 steps automated (tagged); every step can still be run by hand; not run yet. The live run
is the developer's: steps 2 to 8 fill the report
[reports/2026-11-17-offroad-navigation-measurements.md](../reports/2026-11-17-offroad-navigation-measurements.md).
Time: about 1 h 30 min for the whole run (two restarts included); step 1 alone 5 min.*

What `/knk road status` shows (staff, `knk.admin.road`), under the existing `walk paths:` line:

1. `walk search:` searched requests since the last reset, then over the last 512 of them: found, no path, budget
   (how many ended at `max-expansions` and at `max-length`), and `length-pruned` (searches that dropped steps at the
   length cap even if they arrived: a higher `max-length` could give another path).
2. `walk cost:` three lines with `max`, `p95` and `p50` of: search µs (the walk thread's search time) and queue µs
   (the wait for a free walk thread, `max-concurrent-searches`); expansions and cells (cells touched, expanded or
   not); capture µs (main-thread time spent extracting the request's chunks; cached chunks cost nothing), chunks
   per request and wait ms (from the request to the capture being ready; chunks are captured 4 per tick).
3. `walk recent:` the five newest requests, newest first, one line each: running number, outcome (and the cap that
   ended it), straight distance, path length, expansions, cells, chunks (cached), capture µs, search µs.
4. `/knk road status reset` clears these numbers (not the `walk paths:` outcome counters), so each scene is read on
   its own. A request that was not captured (`not captured` in `walk paths:`: a chunk not loaded, or more chunks
   than `max-chunks-per-request`) has no search and no line here.

### 1.0 Preconditions

1. Deployed: the plugin build from `next` with #703 on the dev server.
2. Settings for run 1: `navigation.walk.*` as shipped (`max-expansions: 20000`, `max-length: 144`,
   `max-chunks-per-request: 64`; merge the new key by hand, see the deploy notes) and `navigation.max-snap-distance: 48`.
3. Accounts and data: a staff account with `knk.admin.road`; the five scenes of the measurement report § 2 with a
   named `/navigate` destination at each target that resolves to a point: a Location, or a domain with `spawn`
   (`/navigate <name> spawn`). `/navigate` takes no coordinates, and streets and regions are not walked to directly
   (run 2 relies on direct mode). Write the start point and the destination of each scene in the report's § 2 table
   first.
4. Chunks: walk legs use loaded chunks only. For the open-country legs, load the whole box from start to target
   (plus 16 blocks) before the run: `/forceload add <x1> <z1> <x2> <z2>` (at most 256 chunks per command; repeat
   for a longer box), and `/forceload remove all` after the run.
5. Optional: `spark` or `/tps` open in a second window, to note the server's tick time during the long captures.

### 1.1 Steps

1. [automated: knk-paper `RoadAdminCommandTest$Status`, `NavigationServiceTest#walkSearchesAreMeasuredForRoadStatusAndTheTrailIsUnchanged`]
   Quick pass. As staff, stand 20 to 40 blocks from a named destination with no road between you and it, run
   `/knk road status reset`, then `/navigate <destination>`, wait until the trail follows the ground (about one
   second), and run `/knk road status`. **Expected:** `walk search: 1 searches since the last reset ...`, three
   `walk cost:` lines with non-zero `search µs`, `expansions`, `cells`, `capture µs` (0 when every chunk came from
   the cache) and `chunks`, and one `walk recent:` line `#<n> FOUND, <d> blocks straight, path <l>, ...`. The trail
   is the same as before the change. (A01)
2. Run 1, scene 1, keep (today's caps). Stand at the keep's entrance, `/knk road status reset`,
   `/navigate <the destination in the keep's farthest room>`. Wait until the trail is shown or "No conventional path"
   appears, stand still for 2 s, then `/knk road status`. Copy the first `walk recent:` line (the cold capture) and
   the three `walk cost:` lines into the report, table 3.1, row "keep, run 1". Then walk the route to the end and run
   `/knk road status` again: copy the `walk search:` line and the `walk cost:` lines (these now include the
   recomputes on the way) into the same row's "whole walk" cells. **Expected:** numbers in every cell; when the
   destination is more than 48 blocks away, today's route is road plus walk legs (each walk leg is one request).
3. Run 1, scene 2, stair house. As in step 2, from the bottom of the spiral stair to a destination at its top. Copy
   into row "stair house, run 1". **Expected:** as step 2; note `length-pruned` (the climb allowance is 5 blocks per
   block of height).
4. Run 1, scene 3, courtyard. As in step 2, from one side of the courtyard to a destination on the far side (the road
   goes round). Copy into row "courtyard, run 1". **Expected:** as step 2.
5. Run 1, scenes 4 and 5, open country 200 and 400 blocks. As in step 2, with destinations 200 and 400 blocks away
   over open ground with a lake or a cliff in between. Copy into rows "200, run 1" and "400, run 1". **Expected:**
   today's behaviour: the route uses the roads and only the legs at the ends are walk searches (at most 96 blocks).
6. Run 2, option A (raised caps, DESIGN § 5.6). Stop the server, set in `config.yml`:

   ```yaml
   navigation:
     max-snap-distance: 450        # measurement only: /navigate walks to anything within 450 blocks directly
     walk:
       max-expansions: 200000
       max-length: 600
       max-chunks-per-request: 512 # a 400-block diagonal leg + margin needs about 21 x 21 = 441 chunks
   ```

   and start it (every key needs a restart). Repeat steps 2 to 5 and copy into the "run 2" rows. **Expected:** each
   scene is one walk search from start to target. Note in the report: the `wait ms` of the cold capture (441 chunks
   at 4 per tick is about 5.5 s), the tick time while it runs, and whether a search ended at `max-expansions` or
   `max-length` (the `walk recent:` line names the cap).
7. Run 3, only if a run 2 search ended at `max-expansions`: set `max-expansions: 500000`, restart, repeat that scene
   and copy into its "run 3" row. **Expected:** the search arrives, or the report says how far it got.
8. Concurrency (optional, two staff accounts). With run 2's settings, both players `/navigate` to the 400-block
   destination within the same second. **Expected:** the second request's `queue µs` in `walk recent:` is about the
   first one's `search µs` (two walk threads: both run at once; a third waits).
9. Restore the shipped settings: `max-snap-distance: 48`, `max-expansions: 20000`, `max-length: 144`,
   `max-chunks-per-request: 64`; restart; `/forceload remove all`. Repeat step 1. **Expected:** step 1's result,
   and a destination 60 blocks away is routed over the road again (direct mode only within 48 blocks).

## 2. Phase 1: shared shaping package (#704, tier:2)

*Built 2026-11-17 (link L2, knk-plugin `claude/offroad-shape-package`): `Corridor`, `CorridorShaper`, `FreeWidth`,
`PlazaLine`, `NavWorld`, `NavPoint`, `NavGeometry` and `PlazaCrossing` (formerly `RoadPlanner.PlazaCrossing`) moved to
`knk-core` `core/navigation/shape/`; no behaviour change. Every step is covered by automated tests; the manual check
is one look at the startup log.*

### 2.0 Preconditions

1. Deployed: plugin build from `next` with phase 1.
2. Settings: the NPC movement keys as on the dev server before (corridor steering and plaza lines on, as in the NPC
   movement smoke test).
3. Accounts and data: a staff account; the NPC movement test scenes.

### 2.1 Steps

1. As staff, run the NPC movement scenes of the NPC navigation smoke test (stair house route, plaza crossing, corridor
   steering). **Expected:** NPCs walk the same lines as before the move; no errors in the console. (A26)
   [automated: knk-core NPC unit tests, among them `CorridorTest`, `CorridorShaperTest`, `FreeWidthTest`,
   `PlazaLineTest` (now in `core/navigation/shape`), `LocalLegSearchTest`, `RouteFollowerPlazaTest`; paper-boot
   scenarios `npc-stairhouse-climb`, `npc-stairhouse-group`, `npc-plaza-line`, `npc-keeps-to-road-around-obstacle`,
   `npc-replay-quarry-to-keep` and the other `npc-*` scenarios in CI's `paper-boot` job]
2. As a player, run `/navigate` to a town gate with the off-road flags off. **Expected:** the trail looks as before.
   (A26) [automated: knk-paper `TrailRendererTest`, `NavigationServiceTest`; the player trail does not use the moved
   classes yet]
3. Check the server log at startup. **Expected:** no class-loading or missing-class errors from the navigation or NPC
   packages. (A26) [automated: CI's `paper-boot` job starts the plugin on a Paper server and fails on such errors]
4. Package rule. **Expected:** `core/navigation/shape` imports nothing from `core/npc`. (A26) [automated: knk-core
   `ArchitectureGuardTest.sharedShapingPackageDoesNotUseNpcPackages`]

## 3. Phase 2: walk links and mixed routes (#705, tier:3)

*Built 2026-11-18 (link L5, knk-plugin `claude/offroad-walk-links`): with `navigation.walk-links` on, the road A* may
leave the road for a walk link between two road nodes that lie at most `walk-link-range` (40) blocks apart where the
road between them is more than `walk-link-ratio` (2.0) times the straight distance. Links are searched lazily: the
first route is today's; the candidates the A* met that could beat it (at most `walk-link-searches-per-route`, 4) are
searched off the main thread with the player's walk access, one at a time beside the walk legs, and cached for the
player; when one is found the session asks for a better route ("A shorter route opened - following it now."). The
route is then a list of legs (road, walk link, road), with the walk to the road and the last walk as before; the walk
link is drawn in the leg colour, and the instructions say "Leave the road and walk across" where it starts. A link is
offered only when the access policy lets the player through its regions and gate doors; a block change within a block
of its path drops it within a second (the block-change hook), otherwise it is kept `walk-link-ttl-seconds` (600); "no
link" is kept `walk-link-retry-seconds` (600) or until a gate or rule changes. Road-first: a target within
`max-snap-distance` (unchanged, 48) is reached over the road instead of one walk path when the road carries at least
`road-first-share` (0.6) of the way and the whole way is at most `road-first-max-ratio` (1.5) times the walk path (the
developer confirms both defaults). `/knk road status` shows three walk-link lines. With the flag off everything is as
before. 13 of 14 steps are automated, 5 of them in part; the developer's live test is steps 1, 2, 5 to 9 and 12 on the
dev world.*

### 3.0 Preconditions

1. Deployed: plugin build from `next` with phase 2 (knk-plugin PR for #705 merged).
2. Settings: under `navigation:` add (the defaults) `walk-links: true`, `walk-link-range: 40`, `walk-link-ratio: 2.0`,
   `walk-link-ttl-seconds: 600`, `walk-link-retry-seconds: 600`, `walk-link-searches-per-route: 4`,
   `road-first-share: 0.6`, `road-first-max-ratio: 1.5`; keep `navigation.walk.enabled: true` and
   `max-snap-distance: 48`. Restart the server (the navigation service reads these at startup; the log says "Walk
   links on (navigation.walk-links): range 40.0, ratio 2.0, ...").
3. Accounts and data: a player account without staff rights; a staff account; a courtyard where walking across is
   much shorter than the road round it (two road junctions at most 40 blocks apart in a straight line, more than twice
   that by road; the developer picks one in the town or the keep's bailey); a WorldGuard region on the courtyard whose
   domain can deny the player entry; a gate structure on the courtyard's other exit that can be closed; a field
   outside the town at least 10 blocks from any road.
4. Run `/knk road status reset` before each step that reads the counters.

### 3.1 Steps

1. As the player, stand in the field, about 15 blocks off the road, and `/navigate` to a building on the far side of
   the courtyard (a point at least 5 blocks off the road there). **Expected:** at first today's trail: a light blue walk
   leg to the road, the gold road trail round the courtyard. Within a few seconds "A shorter route opened - following
   it now." and the trail changes: the walk to the road, the road, a light blue stretch across the courtyard, the road
   again, and a light blue walk into the building, in that order; near the courtyard the HUD says "Leave the road and
   walk across". (A02) [automated in part: knk-paper
   `NavigationServiceWalkLinksTest.aRouteFromAFieldOverTheShortcutIsWalkRoadWalkRoadWalk`,
   `NavigationServiceWalkLinksTest.aFoundLinkGivesTheShortcutAcrossTheCourtyard`; knk-core
   `WalkLinkRoutingTest.aCachedLinkMakesTheRouteRoadWalkRoad`,
   `WalkLinkRoutingTest.theInstructionsSayWhereTheRouteLeavesTheRoad`; the look of the trail is manual]
2. Walk the whole route along the trail. **Expected:** one route on the HUD, no "You left the road - recalculating."
   while you follow the trail, also on the courtyard stretch (it is part of the route); the gold road trail leads until
   the road's end, and only there does the last light blue walk into the building begin; arrival at the building. Then
   `/knk road status`: **Expected:** "walk links: … 1 with links (1 links) …", "walk link searches: … 1 found …". (A02)
   [automated in part: knk-paper `NavigationServiceWalkLinksTest.aFoundLinkGivesTheShortcutAcrossTheCourtyard` (the
   status lines), `NavigationServiceWalkLinksTest.theRoadTrailKeepsTheLeadUntilTheRoadsEnd`; walking it is manual]
3. Navigate along one straight street between two junctions that are close by road as well (the road no more than
   twice the straight distance). **Expected:** no walk link; the route stays on the road; `/knk road status` shows no
   link search for it. (A03) [automated: knk-core `WalkLinkCandidatesTest.theRatioDecides`,
   `WalkLinkCandidatesTest.aRoadMoreThanTheRatioTimesTheStraightDistanceWithinRangeIsACandidate`]
4. Navigate past two junctions more than 40 blocks apart in a straight line with a long road between them.
   **Expected:** no walk link between them. (A03) [automated: knk-core `WalkLinkCandidatesTest.theRangeDecides`,
   `WalkLinkCandidatesTest.splitNodesOtherComponentsAndPlumbingTakeNoPart` (gate split nodes and other networks)]
5. As staff, deny the player entry to the courtyard region (its domain's access rules); as the player, navigate as in
   step 1. **Expected:** the route goes round by road; no light blue stretch crosses the courtyard. (A04) [automated:
   knk-core `WalkLinkRoutingTest.aLinkThroughARegionThePlayerMayNotEnterOrAClosedGateIsNotOffered` (the link's
   regions judged by the access policy), `WalkLinkRoutingTest.aCompositePolicyDoesNotMixALinkUpWithAnEdge`; with the
   real domain rules manual]
6. As staff, allow entry again and close the gate on the courtyard's exit; as the player, navigate again. **Expected:**
   no walk link through the closed gate; the road round it. Open the gate: within a few seconds (or at the next route)
   the shortcut can come back. (A04) [automated in part: knk-core
   `WalkLinkRoutingTest.aLinkThroughARegionThePlayerMayNotEnterOrAClosedGateIsNotOffered` (the gate's door on the link,
   closed and open), `WalkLinkCacheTest.aGateOrRuleChangeDropsTheNonesOnly`; the real gate is manual]
7. With the shortcut on the route, as staff build a wall of a few blocks across the courtyard on the link's line (or
   place one block in its way); as the player, navigate again after a second. **Expected:** the shortcut is no longer
   on the route; the route goes round by road at first; `/knk road status` shows "dropped 1 by block changes" (or
   more) and a new link search; if the walk search finds a way round the wall the shortcut comes back along it,
   otherwise not. (A05) [automated: knk-core `WalkLinkCacheTest.aBlockChangeInTheLinksBoxDropsItAndNothingElse`,
   `WalkLinkRoutingTest.aBlockChangeDropsTheLinkAndTheNextRouteSearchesAgain`; knk-paper
   `WalkTerrainListenerTest.blockChangesReachTheListenerOncePerChunkWithinASecond`,
   `NavigationServiceWalkLinksTest.aBlockChangeDropsTheLinkAndTheNextRouteSearchesAgain`; on the dev world manual]
8. Remove the wall and navigate again. **Expected:** the shortcut comes back (a new search finds it again; a block
   change dropped the old link). (A05) [automated: the same tests as step 7]
9. Road-first, scene 7 of the measurements: `/tp 1411 113 -504` (Keep Tower Roof) and `/navigate Keep storage hall`
   (19 blocks away, so direct mode). **Expected:** first "Keep storage hall is … away - follow the trail."; then either
   "Following the roads to Keep storage hall - they carry most of the way." and the road trail with walks at both ends
   (when a road carries at least 60 % of the way at no more than 1.5 times the walk path's length), or the walk path as
   today. `/knk road status`: "road-first: 1 road, 0 walk" or "0 road, 1 walk". Note which one you saw and whether it
   matches what you want; the two defaults are for you to confirm. [automated in part: knk-paper
   `NavigationServiceWalkLinksTest.roadFirstTakesTheRoadThatCarriesMostOfTheWay`,
   `NavigationServiceWalkLinksTest.roadFirstKeepsTheWalkWhenTheRoadGoesTheLongWayRound`; knk-core `RoadFirstRuleTest`;
   the scene's answer is manual]
10. Road-first across the courtyard: stand on one side of the courtyard and navigate to a point on the other side
    within 48 blocks. **Expected:** the walk path across, as today (the road goes the long way round); `/knk road
    status` "road-first: 0 road, 1 walk". [automated: knk-paper
    `NavigationServiceWalkLinksTest.roadFirstKeepsTheWalkWhenTheRoadGoesTheLongWayRound`]
11. `/knk road status` during steps 1 to 8. **Expected:** three lines "walk links", "walk link searches" (with mean and
    max search ms, within the 150 ms of the measurements report § 3.3 budget 2), "walk link cache" (links, none,
    searching, dropped, expired, evicted, road-first), and "walk link queue". [automated: knk-core
    `WalkLinkCacheTest.theCountersReadAsStatusLines`]
12. Tick time: with `/spark tps` (or the server's TPS) watch steps 1 and 7. **Expected:** no drop: link searches run
    off the main thread and their captures within the capture tick budget (budget 1). [manual]
13. NPCs: let an NPC walk a road route while the player navigates. **Expected:** the NPC moves exactly as before; NPC
    routes never take walk links. [automated: knk-paper `NavigationServiceWalkLinksTest.anNpcRoadPlanNeverTakesAWalkLink`; the unchanged NPC unit tests and paper-boot NPC scenarios]
14. Turn `navigation.walk-links` off, restart, and navigate as in step 1 and as in step 9. **Expected:** today's
    routes: walk leg, road, walk leg only, and direct mode within 48 blocks; `/knk road status` has no walk-link lines;
    the other walk-link keys change nothing. [automated: knk-paper
    `NavigationServiceWalkLinksTest.withTheFlagOffNothingChanges` (a transcript of trail, HUD, chat and events with
    other values of every walk-link key), `NavigationServiceWalkLinksTest.withTheFlagOffDirectModeStaysAsToday`;
    knk-core `WalkLinkRoutingTest.withoutALinkSourceTheRouterIsTodays`; every test of the suites unchanged]

## 4. Phase 3: hierarchical walk search (#706, tier:3)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: plugin build from `next` with phase 3.
2. Settings: `navigation.walk.hierarchical: true`, `navigation.walk-links: true`, the budgets set from the phase 0
   report.
3. Accounts and data: a player account; the keep and the open-country scenes; a second player who can stand far away
   to keep chunks loaded or unloaded.

### 4.1 Steps

1. As the player, stand at the keep's entrance hall and `/navigate` to a place on the top floor at least 250 blocks
   of walking away, with no road inside the keep. **Expected:** a walk trail through the corridors and up the stairs,
   found within the budget of the phase 0 report; no "No conventional path" message. (A06)
2. Run `/knk road status` as staff right after. **Expected:** the search time of that request is within the budget.
   (A06)
3. Compare with the plain search (staff turns `walk.hierarchical` off, raises the caps for a moment, navigates the
   same pair). **Expected:** the two route lengths differ by at most 5 percent. (A07)
4. As the player, navigate to the 200-block open-country destination. **Expected:** a smooth walk trail around the
   lake or the cliff, not a straight line through it. (A06)
5. Navigate to the 400-block destination with only part of the way loaded (no player near the far half).
   **Expected:** the trail covers the loaded part; the HUD arrow guides beyond it; no chunk is loaded by the search
   (watch the chunk count in `/knk road status` or the server's chunk count). (A08)
6. Walk on until the far part loads. **Expected:** the trail extends over the newly loaded part. (A08)
7. As staff, place a block that closes a corridor of the keep while the player navigates there. **Expected:** the
   next route avoids the closed corridor. (A06)

## 5. Phase 4: route modes (#707, tier:2)

*Built 2026-11-18 (link L7, knk-plugin `claude/offroad-route-modes`): `/navigate <destination>
[shortest|efficient|preferred] [spawn|region]`. Without a mode word the route is `preferred`, today's routing exactly
(O24), and needs no node. A typed word needs its node `knk.navigate.mode.<word>` (O25); a player without it gets "You
don't have permission to use this command." and no navigation starts; tab completion after a destination offers only
the words the player holds, after `spawn` and `region`. The mode prices road and walk legs alike: `shortest` length
only (doors, water, drops and ladders stay passable, with no extra cost); `efficient` the road class cost and the walk
profile's costs; `preferred` adds the road profile's and the edge's cost multiplier (`/knk road edge set <id> cost
<x>`). Walk links cost their walked length in `shortest`, their walk cost otherwise. Landmark preference weights are
phase 5.2 (§ 7). The mode works on both paths (`navigation.destination-engine` on or off) and stays for the
navigation's re-routes; NPC plans never use a mode. No flag, no config key. 8 of 9 steps are automated, 2 of them in
part; the developer's live test is steps 2, 3 and 9 (about 15 minutes).*

### 5.0 Preconditions

1. Deployed: plugin build from `next` with phase 4 (knk-plugin PR for #707 merged). Restart the server.
2. Settings: no new flag or config key.
3. Accounts and data:
    1. Player A: a player account holding `knk.navigate.mode.shortest`, `knk.navigate.mode.efficient` and
       `knk.navigate.mode.preferred` (granted through the in-house permissions: the web app's grants, or
       `/knk user` for a group, see the PR's Admin steps).
    2. Player B: a player account holding none of the three mode nodes (but `knk.navigate`, as every player).
    3. A road pair with two ways between them: one shorter, one longer, where you set a cost multiplier on an edge of
       the shorter way with `/knk road edge set <id> cost 3` (note the edge id from `/knk road edge` at your feet).
    4. The stair house with a ramp beside the spiral stair, and a destination at the top that both reach.

### 5.1 Steps

1. As player A, `/navigate <destination>` with no mode word, for the road pair. **Expected:** the same route and trail
   as before the phase: it avoids the weighted edge (`preferred`). (O24, A11) [automated: knk-core
   `RouteModeDefaultTranscriptTest.theDefaultModeIsTodaysRoadRouting`,
   `LinkRouteDefaultTranscriptTest.theDefaultModeIsTodaysRoutingWithWalkLinksOffAndOn`,
   `WalkLegDefaultTranscriptTest.theDefaultModeIsTodaysWalkLegs` (golden transcripts written on `next` before the
   phase); knk-paper `NavigateCommandRouteModeTest.withoutAModeWordTheCommandIsTodaysAndAsksForNoModeNode`]
2. As player A, `/navigate <destination> shortest`, then `/navigate <destination> efficient`, then `/navigate
   <destination> preferred`, for the road pair. **Expected:** `shortest` takes the shorter way over the weighted edge
   (its cost multiplier is ignored); `efficient` takes the way with the cheaper road classes and also ignores the
   multiplier; `preferred` avoids the weighted edge, as in step 1. The trail and the HUD follow each route. (A09)
   [automated in part: knk-core `RouteModeTest.theThreeModesTakeThreeDifferentRoads`; knk-paper
   `NavigationServiceRouteModeTest.theRawEntryRoutesInTheModeItIsGiven`,
   `NavigationServiceRouteModeTest.theEngineHandleRoutesInTheModeItIsGiven`; the routes on the dev world are manual]
3. As player A, in the stair house, `/navigate <top destination> shortest`, then the same with `efficient`. **Expected:**
   `shortest` leads up the spiral stair (the shorter climb); `efficient` may lead up the ramp, because the walk
   profile's wall and step costs make the narrow spiral dearer. (A09) [automated in part: knk-core
   `WalkRouteModeTest.shortestWalksThroughTheDoorEfficientAndPreferredGoRoundByTheGap` (the same rule on a door and a
   gap); knk-paper `NavigationServiceRouteModeTest.aWalkLegIsSearchedInTheMode`; the stair house is manual]
4. As player A, `/navigate <destination> preferred region` (a domain with a region). **Expected:** the navigation goes
   to the region (the trailing `region` still works after the mode word); `/navigate <destination> region shortest`
   is read as a destination called "<destination> region". (A09) [automated: knk-paper
   `NavigateCommandRouteModeTest.theModeWordStandsBeforeTheTrailingSpawnOrRegion`,
   `NavigateCommandRouteModeTest.aLoneWordIsAlwaysAName`, `NavigateCommandRouteModeTest.aTypedWordNeedsItsNode`]
5. As player B, `/navigate <destination> shortest`. **Expected:** "You don't have permission to use this command.";
   no navigation starts. `/navigate <destination>` still works. (O25) [automated: knk-paper
   `NavigateCommandRouteModeTest.aTypedWordNeedsItsNode`,
   `NavigateCommandRouteModeTest.withTheInHouseChecksTheTypedWordWaitsForTheirAnswer`,
   `NavigateCommandRouteModeTest.throughTheEngineTheWordReachesTheHandlesSession`]
6. As player B, type `/navigate <destination> ` and press Tab. **Expected:** only `spawn` and `region` (as before); as
   player A the same shows `spawn`, `region`, `shortest`, `efficient`, `preferred`; after a mode word only `spawn` and
   `region`. (O25) [automated: knk-paper `NavigateCommandRouteModeTest.completionOffersOnlyTheWordsThePlayerHolds`,
   `NavigateCommandRouteModeTest.throughTheEngineCompletionOffersTheHeldWords`]
7. As player A, `/navigate <destination> efficient`, then walk off the road a little and back so the navigation
   re-routes. **Expected:** the new route is still the `efficient` one. [automated: knk-paper
   `NavigationServiceRouteModeTest.aRerouteKeepsTheMode`]
8. In a world (or on a road pair) with no road cost multipliers, compare `preferred` and `efficient` for the same
   pair. **Expected:** the same route. (A11) [automated: knk-core
   `RouteModeTest.withoutMultipliersPreferredAndEfficientAreTheSameRoute`,
   `WalkLinkRouteModeTest.shortestTakesASlowShortcutEfficientAndPreferredKeepTheRoad`]
9. Remove the test multiplier again: `/knk road edge set <id> cost 1`. **Expected:** "/navigate <destination>" takes
   the shorter way again. (Clean-up; manual)

## 6. Phase 5.1: landmark entity (#708, tier:3)

*Step A built 2026-11-18 (link L8, knk-web-api and knk-web-app `claude/offroad-landmarks`, PRs into `next`): the
`landmarks` table (migration `AddLandmarks`), `api/landmarks` (anonymous `GET ?world=` and `GET {id}` under the `map`
rate limit, `POST search` for the dashboard, writes behind the new node `knk.admin.world.landmark` or the plugin key),
the default form seed `Landmark`, the dashboard type with its columns and a Landmarks list on every domain's detail
page. Step B built the same day (knk-plugin `claude/offroad-landmarks`): `/knk landmark …` and the `LandmarkProvider`
behind `navigation.landmarks`, § 6.3. API and web steps: 11 of 12 automated (tagged), 2 of them in part; not run by
hand yet. Time: about 25 min for the API and web steps (6.1 to 6.4), 20 min for step B's.*

Who may do what (DESIGN § 6.4, O26):

1. **Read** a landmark by world or by id: anyone, also without logging in (`GET api/landmarks?world=`,
   `GET api/landmarks/{id}`), 120 requests a minute per IP (`RateLimiting:Map:PermitPerMinute`).
2. **List** them on the dashboard (`POST api/landmarks/search`): the World area node `knk.admin.world` or
   `knk.admin.world.landmark`, or the plugin key.
3. **Create and edit**: `knk.admin.world.landmark` and `knk.admin.content` (the dashboard's change rule, #374), or the
   plugin key. **Delete**: `knk.admin.world.landmark` and `knk.admin.delete`, or the plugin key.
4. `knk.admin.world.landmark` is matched by `knk.admin.world.*`, `knk.admin.*` and `*`; a bare `knk.admin.world`
   grant does **not** include it (a grant without `*` matches only its own node).

### 6.0 Preconditions

1. Deployed: knk-web-api with the migration `AddLandmarks` applied (`dotnet ef database update`, or the API's
   migration on start); knk-web-app from the same `next`. For step B also: the plugin build from `next` with phase
   5.1 step B and the destination engine P1, P2 and P3 (#96, #103, #69), `navigation.destination-engine: true`.
2. Settings: none for the API and web app. Step B: `navigation.landmarks: true` and `navigation.destination-engine: true`
   in the plugin's `config.yml`, then restart.
3. Data: the form seed `Landmark` imported on the form configuration list (Import / seeds, "Landmark - Default
   (seed v1)"; it becomes the default when Landmark has none); the keep as a structure domain; a WorldGuard region
   `keep_throne` around the throne room.
4. Accounts: staff **A** with `knk.admin.world`, `knk.admin.world.landmark`, `knk.admin.content` and
   `knk.admin.delete` (or `knk.admin.*`); staff **B** with `knk.admin.world` and `knk.admin.content` but not
   `knk.admin.world.landmark`; a player account (step B).

### 6.1 API (A12)

1. Without logging in, open `<api>/api/landmarks?world=world` in a browser (or `curl -s`). **Expected:** `200` and a
   JSON list (empty before step 6.2.2); each landmark has `id`, `name`, `world`, `location` (x, y, z), `domainId`,
   `domainName`, `extentKind`, `regionId`, `radius`, `preference`, `navigationEnabled` and `kind`.
   [automated: knk-web-api `EndpointAccessRulesTests.AllowAnonymous_IsLimitedToTheAllowList`,
   `ReadAccessRulesTests` (`LandmarksController.GetAll` = P), `LandmarkServiceTests.Create_WithDefaults_ReturnsWhatThePluginNeeds`,
   `GetAll_ByWorld_IgnoresCase_AndSortsByName`]
2. Without logging in, `POST <api>/api/landmarks` with `{"name":"x","locationId":1}`. **Expected:** `401`; nothing is
   created. [automated: knk-web-api `EndpointAccessRulesTests`, `DashboardChangeAccessRulesTests`
   (`LandmarksController.Create`/`Update`), `DeleteAccessRulesTests` (`LandmarksController.Delete`)]
3. The rules, by hand or by request: a second landmark with the same name in the same world (any case), a `Region`
   area without a region id, a `Radius` of 0 or above 512, a preference outside 0.25 to 4.0. **Expected:** each is
   refused with `400` and the reason; the same name in another world is accepted.
   [automated: knk-web-api `LandmarkServiceTests` (17 tests)]

### 6.2 Web app (A12)

1. As staff A, open the dashboard and pick **Landmark** under World. **Expected:** the table has the columns ID, Name,
   World, Point, Domain, Area and In /navigate; the search box narrows the list by name, world or domain.
   [automated: knk-web-app `e2e/landmarks.spec.ts` "lists the landmarks with world, point, domain, area and /navigate",
   "the search box asks the API with the search term"]
2. Click **Create** (the Landmark form): Name "Throne room", Domain: the keep, Offer in /navigate on; on the Location
   step stand in the throne room in game and use Send to Minecraft; on the Area step choose Region and type
   `keep_throne`; Submit. **Expected:** "Landmark created."; the row shows the keep under Domain and Region under Area.
   [automated in part: `e2e/landmarks.spec.ts` "the landmark form saves through POST api/landmarks" (a one-step test
   form; the Location world task and the domain picker are the form wizard's own specs)]
3. Open the keep's detail page (Dashboard → Structure → the keep → View). **Expected:** below the details a
   **Landmarks** box lists "Throne room" with "Region · x y z · world"; the name opens the landmark's page.
   [automated: `e2e/landmarks.spec.ts` "lists the landmarks linked to the town, each linking to its page" (a town;
   every domain type shows the box, `DomainLandmarksPanel.test.tsx`)]
4. On the landmark's page click **Edit**, rename it to "Throne hall", Submit; reopen the keep's page. **Expected:** the
   new name in the table and in the keep's Landmarks box. (A12)
5. Log in as staff B. **Expected:** the dashboard lists Landmark (B holds `knk.admin.world`) but **Create** and **Edit**
   are greyed out with "Requires knk.admin.world.landmark"; on the keep's page **Add landmark** is greyed out with the
   same hint. A save sent anyway answers `403`. [automated: `e2e/landmarks.spec.ts` "Add landmark needs the landmark
   node, and says which"; knk-web-api `DashboardAccessTests.Metadata_CreateAndEdit_AreTheChangeNodes` (Landmark)]
6. As staff with only `knk.admin.content`. **Expected:** no Landmark in the dashboard's explorer.
   [automated: `e2e/landmarks.spec.ts` "content-only staff do not get the landmark type"]
7. As staff A delete "Throne hall" (its page → Delete → confirm). **Expected:** "Landmark "Throne hall" deleted."; it is
   gone from the table and from the keep's Landmarks box, which says "No landmarks are linked to <keep>.". Its Location
   stays and shows up later in the orphaned-Location list (KNG-80), like a deleted domain's.
   [automated in part: `LandmarkServiceTests.Delete_RemovesTheLandmark_AndLeavesThePinToTheRetentionCheck`,
   `e2e/landmarks.spec.ts` "says when no landmark is linked"]
8. Delete the keep's domain while a landmark is linked to it (on a copy, or a test structure). **Expected:** the
   landmark stays, without a domain. [automated: `AddLandmarksTests.Up_LocationRestricts_DomainIsClearedOnDelete`,
   `LandmarkServiceTests.DeletingTheDomain_ClearsTheLink`]

### 6.3 In game (step B, A12 to A14)

*Built 2026-11-18 (link L8 step B, knk-plugin `claude/offroad-landmarks`): `/knk landmark`, the destination engine's
`LandmarkProvider` and the landmarks section of the navigation model, all behind `navigation.landmarks`. For these
steps set both `navigation.landmarks: true` and `navigation.destination-engine: true` and restart. 10 of 10 steps
automated (4 of them in part); the live run (a real client walking, tab completion as typed) is the developer's.
About 20 min.*

1. As staff A, stand in the throne room and run `/knk landmark create Throne room region keep_throne`.
   **Expected:** "Created landmark Throne room (#<id>) region keep_throne."; `/knk landmark list` shows it; the web
   app's Landmark table shows it after a reload. (A12) [automated in part: knk-plugin
   `LandmarkAdminCommandTest.createTakesTheNameTheExtentAndThePlayersPosition`, `listShowsThePlayersWorld`;
   `LandmarksApiImplTest.createSendsTheNameThePinAndTheExtentInTheApisWords` (the API's answer is faked)]
2. `/knk landmark link Throne room <keep's name>`, then `/knk landmark show Throne room`. **Expected:** "Linked Throne
   room to <keep> (Structure)."; `show` lists the domain, the point, "region keep_throne" and "In /navigate: yes". A
   domain name several domains share answers with their `#id`s; `link Throne room #<id>` then works. (A12)
   [automated: `LandmarkAdminCommandTest.linkTakesADomainByNameOrId_andAnAmbiguousNameAsksForTheId`,
   `showFindsANameWithSpacesOrAnId`]
3. Stand a few blocks away and run `/knk landmark move Throne room`, then `/knk landmark show Throne room`.
   **Expected:** the new position; the domain link is kept. [automated:
   `LandmarkAdminCommandTest.moveMovesTheSameLocationAndKeepsTheDomain`]
4. As staff B (no `knk.admin.world.landmark`), `/knk landmark create Test`. **Expected:** "You don't have permission"
   and nothing is created; `/knk help` does not list `landmark`. (A12) [automated in part:
   `LandmarkAdminCommandTest.theMetadataGatesOnTheLandmarkNode`, the registry's check in `CommandRegistryPermissionsTest`]
5. As the player, `/navigate Throne room` from outside the keep and walk there. **Expected:** the trail leads to the
   keep; navigation ends with "You have arrived" as you step into the `keep_throne` region. (A13) [automated in part:
   `HandleDestinationsLandmarkTest.noExtentIsAPlainPoint_aRegionExtentIsTheRegion` (the region destination; region
   arrival is the existing WorldGuard check)]
6. As staff, `/knk landmark create Market well radius 5` at the well and `/knk landmark create Old gate` at a gate;
   as the player navigate to each. **Expected:** "Market well" ends as you come within 5 blocks of the well (also 1 to 4
   blocks off the point); "Old gate" only within the arrive distance (4 blocks). (A13) [automated:
   `NavigationServiceLandmarkTest.aRadiusExtentIsReachedInsideItsCylinder`,
   `withoutAnExtentEightBlocksAwayIsNotThereYet`, `standingInsideTheRadiusIsAlreadyThere`]
7. As the player type `/navigate ` and press tab; then `/navigate landmark:` and tab. **Expected:** this world's
   landmarks you may navigate to are offered ("Throne", "Market", "Old"). A landmark with "Offer in /navigate" off (set
   it in the web app, wait a minute or `/knk cache refresh`), one in another world, and every landmark during a running
   siege match are not offered; `/navigate <other-world landmark>` says it is in another world. Staff mode lists them
   even in a match. (A14) [automated: knk-core `LandmarkProviderTest.tabCompletionOffersOnlyLandmarksThePlayerMayNavigateTo`,
   `enabledLandmarksOfThePlayersWorldAreListedByName`, `resolvesByNameAndIdAndTheBypassListsThemInAMatch`]
8. Start `/navigate Old gate`, then in the web app untick "Offer in /navigate" on it (or delete it) and wait up to a
   minute (the model refresh). **Expected:** the navigation ends with the "no longer" message; renaming it instead
   keeps the navigation going. [automated: `NavigationServiceLandmarkTest.disablingTheLandmarkEndsTheSessionWithDestinationNotAllowed`,
   `deletingTheLandmarkEndsTheSessionWithDestinationNotAllowed`, `aLandmarkSessionSurvivesReValidationAndARename`]
9. As staff, `/knk landmark delete Throne room`. **Expected:** "Deleted landmark Throne room (#<id>)."; it is gone from
   `/knk landmark list`, the keep's Landmarks box in the web app and tab completion (within a few seconds: the command
   refreshes the model). (A12) [automated in part: `LandmarkAdminCommandTest.unlinkSendsNoDomain_deleteDeletes`,
   `NavigationModelLandmarksTest.aDeletedLandmarkLeavesTheModelOnTheNextRefresh`]
10. Set `navigation.landmarks: false`, restart. **Expected:** `/knk landmark list` says "Landmarks are off on this
    server"; no landmark is offered by `/navigate`; the server log's model line names no landmarks.
    [automated: `LandmarkAdminCommandTest.withTheFlagOffNothingHappens`, `LandmarksConfigTest`,
    `NavigationModelLandmarksTest.withTheFlagOffTheSectionStaysEmpty`]

### 6.4 Migration (A12, deploy)

1. On a copy of the production database, apply the migrations. **Expected:** one new table `landmarks`, no change to
   any other table; `Down` drops only `landmarks`. [automated: knk-web-api `AddLandmarksTests`; CI "Migrations (fresh
   DB)" on the API PR]

### 6.5 Drawn landmark regions (#944, #945, tier:2)

*Built 2026-11-21 (knk-plugin, knk-web-api and knk-web-app `claude/landmark-regions`, PRs into `next`): the region
world task runs on any field (the plugin finds its handler by task type, #944), and a region drawn on the Landmark
form's Region field becomes `landmark_<id>` on save, is replaced by a re-run and is kept by the temp-region cleanup, as
a domain's is (#945; [managed WorldGuard regions § 7 "Landmarks"](../architecture/managed-worldguard-regions.md)). 8 of 8
steps automated (2 of them in part); every step can still be run by hand; not run by hand yet. About 15 min for every
step, 8 min for the parts no suite covers (steps 2 and 4: drawing and walking with a real client).*

Preconditions, besides § 6.0: the API, web app and plugin from `next` with #944/#945; `navigation.landmarks: true` and
`navigation.destination-engine: true` for step 4. The Landmark form's Region field needs the region world task: a fresh
import of the seed has it; on a database that imported the seed before (the dev DB), add it in the form designer (Region
field → Requires in-game action → task type `ReagionCreate`) if it is not there yet.

1. As staff A open the Landmark form (Dashboard → Landmark → Create) and go to the **Area** step. **Expected:** the
   **Region** field has **Send to Minecraft** and its help text says a drawn region becomes `landmark_<id>` when you
   save; you can still type a region id into it. [automated: knk-web-api
   `FormConfigurationSeedFilesTests.LandmarkSeed_DrawsItsRegionThroughTheRegionTaskOnRegionId` (the seed); the form
   wizard renders a world task on any field in its own specs]
2. Fill in Name "Courtyard", a Location (Send to Minecraft on the Location step), Area = Region, then **Send to
   Minecraft** on Region. In game, claim the task with its code (`/knk task <code>`, shown in the form), select an L-shaped
   area with `//sel poly` from the ground to a few blocks up, type `save`. **Expected:** the task starts (no "This game
   server has no handler for task type 'ReagionCreate' (field RegionId)"); after `save` the form's Region field shows
   `tempregion_worldtask_<n>`. [partly automated: knk-plugin
   `WorldTaskHandlerRegistryTest.theRegionTaskOnAFieldNotNamedWgRegionId_findsTheRegionHandler`, knk-web-app
   `WorldBoundFieldRenderer.regionAnyField.test.ts` (the result fills RegionId); by hand: drawing with a real client]
3. Submit. **Expected:** "Landmark created."; the landmark's page shows the region `landmark_<id>` (its own id);
   in game `/rg info landmark_<id>` shows exactly the drawn outline and Y range and `/rg info tempregion_worldtask_<n>`
   finds nothing. [automated: knk-web-api
   `LandmarkRegionRenameTests.Create_WithADrawnRegion_RenamesItToTheLandmarkName_InThePinsWorld_AndStoresIt`;
   knk-plugin scenario `landmark-region-rename-keeps-drawn-bounds` (`LandmarkRegionRenameScenario`)]
4. As the player, wait a minute (or `/knk cache refresh` as staff), then `/navigate Courtyard` from outside and walk
   there. **Expected:** navigation ends with "You have arrived" as you step into the drawn region (anywhere in the L,
   not in its notch). [partly automated: scenario `landmark-region-rename-keeps-drawn-bounds` (the navigation's region
   shapes resolve `landmark_<id>` to the drawn L), `HandleDestinationsLandmarkTest.noExtentIsAPlainPoint_aRegionExtentIsTheRegion`;
   by hand: walking with a real client]
5. Edit "Courtyard", go to the Area step, **Send to Minecraft** on Region again, draw a different shape and submit.
   **Expected:** the region is still `landmark_<id>`; `/rg info landmark_<id>` shows the new shape; `/knk regions temp`
   lists no `tempregion_worldtask_*` left from it; navigation to "Courtyard" ends in the new shape (at once: region
   shapes are read live). [automated: knk-web-api
   `LandmarkRegionRenameTests.Update_AfterARerun_ReplacesTheLandmarksOwnRegionInPlace`,
   `Update_AfterARerun_OfALandmarkStillOnATempName_RemovesThatTempRegion`; knk-plugin scenario
   `landmark-region-rerun-replaces-in-place` (`LandmarkRegionReplaceScenario`)]
6. Create a landmark in the form with Area = Region and the region id `keep_throne` typed in, and one in game with
   `/knk landmark create Throne room region keep_throne`. **Expected:** both keep `keep_throne` as their region; no
   `landmark_<id>` region appears. [automated: knk-web-api `LandmarkRegionRenameTests.Create_OnAnExistingRegion_KeepsItsId`,
   `Rerun_KeepsARegionTheFormDidNotDraw`; knk-plugin
   `LandmarkAdminCommandTest.createTakesTheNameTheExtentAndThePlayersPosition`]
7. A landmark left on a temp name: stop the game server after drawing (step 2) and submit while it is down, then start
   it. **Expected:** the landmark is saved with `tempregion_worldtask_<n>`; `/knk regions temp` lists it under "Used by a
   domain, lootbox area or landmark" and the daily cleanup keeps it; `POST /api/Regions/finalize-temp-names` (staff with
   `knk.admin.regions`) answers `renamed: 1` and the landmark shows `landmark_<id>`. [automated: knk-web-api
   `LandmarkRegionRenameTests.Create_WhenThePluginIsUnreachable_StillSaves`, `FinalizeAll_AlsoRenamesLandmarksStillOnATempName`,
   `TempRegionReleaseTests.ListDue_ARegionSomethingNames_IsKept(landmark)`; knk-plugin
   `TempRegionRetentionLookupTest.theCleanupKeepsARegionALandmarkStandsOn_evenWithNoDomainOrArea`]
8. Start a new landmark's form, draw a region on its Region field (step 2), then cancel the task in the web app (or
   delete the draft in Saved Progress) instead of submitting. **Expected:** within about 10 minutes the server log says
   `Removed temp region <world>/tempregion_worldtask_<n> (…)` and the region is gone. [automated: knk-web-api
   `TempRegionReleaseTests.IsRegionTask_ByTaskType_OnAnyField`,
   `CancellingAHeldRegionTaskOnALandmarkRegionIdField_ReleasesItsRegion`; the plugin's release pass is
   `TempRegionReleasePassTest`]

## 7. Phase 5.2: landmark preference weights (#709, tier:2)

*Built 2026-11-18 (link L9, knk-plugin `claude/offroad-landmark-weights`), behind `navigation.landmarks` (off by
default). In the `preferred` route mode (the default) a landmark with an extent (a region or a radius) and a
`Preference` other than 1.0 multiplies the walk cost of every cell inside it: above 1.0 the walk search avoids the
area, below 1.0 it prefers it. `shortest` and `efficient` ignore the weights. Overlapping landmarks multiply, capped at
`navigation.preference-max` (default 4.0, and at its inverse 0.25 the other way). The weights apply to walk legs (the
walk from the player to the road, from the road to the destination, and direct mode); a cached walk link keeps the path
its search found without them (L7's rule). Landmarks standing on a road node (within 4 blocks across and 3 up or down)
also make that node a walk-link end (`navigation.walk-links`). NPC movement never uses the weights. 7 of 8 steps
automated (3 of them in part); the developer's live test is steps 1 to 3 in the keep (about 15 minutes).*

### 7.0 Preconditions

1. Deployed: plugin build from `next` with phases 4, 5.1 and 5.2 (knk-plugin PR for #709 merged); the API and web app
   with phase 5.1 (#708). Add to the plugin's `config.yml` under `navigation:` the key `preference-max: 4.0` (see the
   PR's Admin steps) and restart.
2. Settings: `navigation.landmarks: true` and `navigation.destination-engine: true`; `navigation.walk.enabled: true`
   (the shipped default).
3. Accounts and data:
    1. Player A: a player account (no mode node needed for steps 1 and 3; `knk.navigate.mode.shortest` for step 2).
    2. Staff A: an account with `knk.admin.world.landmark` and `knk.admin.content` (to edit a landmark in the web app).
    3. Two corridors of the keep that lead to the same place within about 40 blocks (a walk leg, not a road), the
       shorter one covered by a WorldGuard region (for example `keep_east_corridor`), and a destination at their far
       end (a landmark without an extent, "Keep library", or any point destination).
    4. As staff A: `/knk landmark create East corridor region keep_east_corridor`, then in the web app set its
       `Preference` to 2.0 and save; wait a minute or run `/knk cache refresh` (the navigation model refresh).

### 7.1 Steps

1. As player A, stand at the near end of the two corridors and run `/navigate Keep library`. **Expected:** the walk
   trail takes the longer corridor: the weighted one is avoided in `preferred`, the default mode. (A10)
   [automated in part: knk-core `WalkPreferenceWeightsTest.anAreaWithAPreferenceOfTwoIsWalkedAround`; knk-paper
   `NavigationServiceLandmarkWeightsTest.inPreferredTheGardenWeightsTheWalkCells`; the keep is manual]
2. `/navigate Keep library shortest` (player A needs `knk.navigate.mode.shortest`). **Expected:** the trail takes the
   shorter, weighted corridor: `shortest` ignores the weight. `/navigate Keep library efficient` does the same. (A10)
   [automated in part: knk-paper `NavigationServiceLandmarkWeightsTest.shortestAndEfficientIgnoreTheWeights`,
   `forModeAddsTheWeightsInPreferredOnly`; the keep is manual]
3. As staff A, set the landmark's `Preference` back to 1.0 in the web app, wait a minute (or `/knk cache refresh`), and
   as player A navigate again with no mode word. **Expected:** the shorter corridor again: a weight of 1.0 is no
   weight. (A10) [automated in part: knk-core `LandmarkWeightsTest.onlyLandmarksWithAnExtentAndAWeightInTheWorldBecomeAreas`,
   `WalkPreferenceWeightsTest.noWeightsIsTheSearchAsBefore`; the refresh and the keep are manual]
4. Two overlapping landmarks of `Preference` 3.0 each cover one hall. **Expected:** a cell in both costs 4 times its
   move (3 × 3 = 9, capped at `preference-max` 4.0); with `preference-max: 10` and a restart it costs 9 times. Two of
   0.25 cost 0.25 times, not 0.0625. [automated: knk-core
   `LandmarkWeightsTest.overlappingAreasMultiplyCappedByPreferenceMaxBothWays`,
   `WalkPreferenceWeightsTest.aCellInsideCostsItsMoveTimesThePreference`; knk-paper
   `LandmarksConfigTest.preferenceMaxIsReadAndABadValueIsTheDefault`]
5. A landmark with `Preference` 0.5 on a side lane. **Expected:** the walk trail is drawn through the lane where it is
   not much longer, and the path found is still the cheapest one (the heuristic stays admissible). (DESIGN § 5.4.4)
   [automated: knk-core `WalkPreferenceWeightsTest.anAreaWithAPreferenceBelowOneDrawsThePathIn`,
   `WalkPreferenceWeightsTest.theHeuristicStaysAdmissibleTheFoundCostIsTheOptimum`,
   `LandmarkWeightsTest.theHeuristicScaleIsTheSmallestMultiplierInForce`]
6. Set `navigation.landmarks: false` and restart; navigate as in step 1. **Expected:** the shorter corridor, exactly
   today's walk; no landmark is read for the walk. With the flag on, a world or leg without weighted landmarks is
   also today's. (A11, chain rule) [automated: knk-paper
   `NavigationServiceLandmarkWeightsTest.withLandmarksOffTheWalkIsTodays`,
   `aLandmarkFarFromTheLegOrNoneGivesNoWeights`, `aFailingLookupMeansNoWeightsNotNoWalk`; knk-core
   `WalkLegDefaultTranscriptTest.theDefaultModeIsTodaysWalkLegs`, `WalkPreferenceWeightsTest.noWeightsIsTheSearchAsBefore`]
7. Restart the server after step 1's setup (the model comes from its snapshot `offline/navigation-model.json`).
   **Expected:** the weight still applies before the API answers; a snapshot written before phase 5.2 loads every
   landmark with no weight. [automated: knk-core `NavigationModelSnapshotTest.aLandmarksPreferenceSurvivesTheRoundTrip`,
   `aSchemaOneFileWrittenBeforePhaseFiveTwoReadsTheMissingPreferenceAsOne`]
8. With `navigation.walk-links: true`, a landmark pinned on a road node at one side of the courtyard (§ 3) where that
   node is a tile boundary. **Expected:** the node becomes a walk-link end like a junction (`/knk road status` counts a
   link search across the courtyard). No stored landmark-to-landmark links exist in v1 (O05); landmark nodes in the
   hierarchical search's clusters come with phase 3 (#706). [automated: knk-core
   `WalkLinkLandmarkNodesTest.aLandmarkOnTheBoundaryMakesItALinkEndWithInferredConnections`,
   `aBlockedStoredLinkRemovesThePair`, `LandmarkLinkNodesTest`; knk-paper
   `NavigationServiceLandmarkWeightsTest.landmarkNodesReachTheWalkLinkCandidates`, `ModelLandmarksTest`; manual: none
   needed beyond § 3]

## 8. Phase 6.1: walk-trail corners (#710, tier:3)

*Built 2026-11-17 (link L3, knk-plugin `claude/offroad-trail-corners`): with `navigation.guidance-v2` on, the walk
search uses the clearance cost (`walk.clearance-cost` per block of clearance a cell lacks to `walk.wall-clearance`) in
place of `walk.wall-cost`; a found or partial walk path is then shaped on the walk thread by the shared
`CorridorShaper` over the captured terrain (`WalkTerrainNavWorld`, `WalkPathShaper` in knk-core `core/roads/walk/`)
and drawn with its corners as curves checked against the clearance map (`walk.curve`). The trail keeps the leg colour
and the 3.0 spacing (O20). The road trail is unchanged. 6 of 8 steps are automated; the developer's live test is steps
1, 3 and 6 on the dev world (the feel of the trail and the tick time).*

### 8.0 Preconditions

1. Deployed: plugin build from `next` with phase 6.1 (knk-plugin PR for #710 merged).
2. Settings: under `navigation:` set `guidance-v2: true`; under `navigation.walk:` keep (or add) `clearance-cost: 5`,
   `wall-clearance: 0.8`, `curve: true`; then restart the server (the walk services read these at startup).
3. Accounts and data: a player account without staff rights and a staff account (for `/knk road status`); the stair
   house and the keep on the dev world; walk paths on (`navigation.walk.enabled: true`).

### 8.1 Steps

1. As the player, stand at the foot of the stair house's stair, `/navigate` to a point on its top floor (a region or
   location there) and watch the walk trail (the light blue particles) while standing still. **Expected:** the trail
   keeps clear of the inner wall and the stair's edges, about a block from the inner wall where the stair is wide
   enough, and rounds each turn as a curve instead of cutting the inner corner. Where a flight is narrower than twice
   the clearance it runs in the middle of it. It never runs through a wall, over a stair well or off the steps. (A15)
   [automated in part: knk-core `WalkPathShaperTest.onASpiralStairOfWidthThreeTheTrailKeepsTheClearanceFromTheNewel`
   (a 3-wide spiral stair: at least 0.7 from the newel, never under 0.35); paper-boot scenario `walk-trail-stairhouse`
   (the developer's stair house schematic: over walkable floor everywhere, never under 0.35, at least 0.7 from walls,
   posts and drops; a local run had 0 % of the trail under 0.7 against 44.7 % of today's path)]
2. Walk up slowly and watch the trail redraw as you go (every half second). **Expected:** on every redraw it stays off
   the inner wall and follows the same curve; it does not flicker between the wall side and the middle. (A15)
   [automated: knk-paper `NavigationServiceTest.withGuidanceV2TheWalkLegDrawsTheShapedCurveOfItsPath` (every redraw
   draws the shaped trail of the current path); the redraw window itself is phase 6.2]
3. In the keep, `/navigate` to a room behind a corridor with a right-angle turn. **Expected:** the trail rounds the
   corner with room to spare on the inside and never cuts through the wall or a pillar. (A15)
   [automated in part: knk-core `WalkPathShaperTest.oneSceneThroughTheNpcShaperAndThePlayerShaperGivesTheSameLine`
   (a building's corner) and `WalkClearanceTest.theClearanceCostKeepsAPathOffTheFaceOfABuilding`]
4. Navigate through a 1-wide door. **Expected:** the trail goes through the door's middle; the clearance does not
   close the door off. (A15) [automated: knk-core `WalkClearanceTest.eachCellEnteredCostsTheClearanceItLacksTimesTheCost`
   (a 1-wide way is only dearer, never blocked) and the shaper's chokepoint alignment in `CorridorShaperTest`]
5. Navigate near a region you may not enter (a domain that denies you). **Expected:** the trail never moves onto the
   denied cells to gain clearance. [automated: knk-core
   `WalkPathShaperTest.theShapedLineNeverMovesOntoACellTheAccessBlocks`]
6. As staff, run `/knk road status reset`, navigate as the player to the stair house's top three times, then run
   `/knk road status`. **Expected:** the `walk paths:` line ends with `shaped N (mean X ms)`, N counting the walk paths
   drawn, X a few tens of milliseconds at most; the server's tick time (`/mspt` or the TPS in the tab list) does not
   rise noticeably while navigating, because the search and the shaping run on the walk threads. (A27)
   [automated in part: knk-paper `NavigationServiceTest.withGuidanceV2TheWalkLegDrawsTheShapedCurveOfItsPath` (the
   status line); scenario `walk-trail-stairhouse` (shaped on another thread from the capture only; local run 39 to
   81 ms); the tick time is manual]
7. Set `navigation.guidance-v2: false`, restart, and repeat step 1. **Expected:** today's trail exactly (the walk
   path's block centres, hugging the inner wall as before); `/knk road status` shows no `shaped` count. (A16)
   [automated: knk-paper `NavigationServiceTest.withGuidanceV2OffTheWalkLegDrawsTheCellsOfItsPathExactly`,
   `WalkLegPreparerTest.withGuidanceV2TheRequestCarriesTheClearanceCostAndWithoutItTodaysProfile`,
   `ConfigLoaderNavigationTest.withGuidanceV2OffTheWalkProfileIsTodaysExactly`]
8. With `guidance-v2: true`, set `walk.clearance-cost: 0` and restart. **Expected:** the walk search picks the same
   cells as with the flag off (the shaping still runs). (A16) [automated: knk-core
   `WalkClearanceTest.aClearanceCostOfZeroIsTodaysSearchExactly` (five scenes); scenario `walk-trail-stairhouse`
   (the stair house)]

## 9. Phase 6.2: anchored particles and winding back (#711, tier:3)

*Built 2026-11-18 (link L4, knk-plugin `claude/offroad-trail-cursor`): with `navigation.guidance-v2` on, a walk trail's
particles sit on fixed anchors every `trail-leg-spacing` blocks (3.0) from the walk path's start, drawn from the leg's
cursor, which follows the player along the path both ways and jumps more than 3 blocks only when the player really is
nearer the other place. The route session keeps a monotone progress (ETA, percentage, maneuvers already announced) and
a cursor that follows the player back along the road (continuity within `cursor-jump`, 12); the road trail, the HUD
distance and the maneuver ahead come from the cursor. A player off the road walks to the join point with the least
remaining cost. A walk leg stays while the player is within `walk.recompute-distance` (6) of its path, walking back
included; "heading away" is gone under the flag. With the flag off everything is as before. All 11 steps are
automated, 3 of them in part; the developer's live test is the feel of steps 1 to 4, 6, 8 and 9 on the dev world.*

### 9.0 Preconditions

1. Deployed: plugin build from `next` with phases 6.1 and 6.2 (knk-plugin PRs for #710 and #711 merged).
2. Settings: under `navigation:` set `guidance-v2: true` and keep (or add) `trail-leg-spacing: 3.0` and
   `cursor-jump: 12`; keep the phase 6.1 keys of § 8.0 under `navigation.walk:`; walk paths on
   (`navigation.walk.enabled: true`). Restart the server (the navigation service reads these at startup).
3. Accounts and data: a player account without staff rights; the keep and the stair house on the dev world; a road
   route of at least 100 blocks with a turn in it; if there is one, a road that loops back or makes a switchback near
   itself.

### 9.1 Steps

1. As the player, stand in the keep's entrance hall, `/navigate` to a room upstairs (a walk leg; light blue particles)
   and stand still for ten seconds. **Expected:** every redraw (twice a second) puts the particles in exactly the same
   places; none slide along the trail. (A17) [automated: knk-paper
   `TrailRendererTest.aRedrawWithThePlayerStillOrSteppingMovesNoParticleAhead`,
   `TrailRendererTest.drawPathWithACursorSpawnsOneParticleAtEachAnchorInTheLegColour`; scenario
   `walk-trail-cursor-stairhouse` (the anchors over the stair house's live floor)]
2. Take one step forward along the trail, then another. **Expected:** the particles ahead of you stay where they were;
   only the ones you pass disappear, and a new one appears at the far end of the trail. (A17) [automated: the same
   tests as step 1]
3. On the stair house's spiral stair, walk up close to the inner wall and round a turn. **Expected:** the trail ahead
   does not jump to the flight above or below or to the other side of a wall; it keeps following the flight you are
   on. (A17, § 7.2.3) [automated in part: knk-core `PolylineCursorTest.aWalkPathCursorJumpsOnlyWhenThePlayerIsReallyNearer`;
   scenario `walk-trail-cursor-stairhouse` (walked up and back down with a sideways wobble, the cursor within a
   block of the player's place on the trail); the look of it is manual]
4. On the road route, walk 40 blocks forward along the road, then turn and walk 20 blocks back along it. **Expected:**
   the road trail (gold) is drawn from where you stand, ahead of you towards the destination; there is no light blue
   walk leg and no straight line back to the far point; the HUD distance grows again as you walk back; the percentage
   stays; no "You left the road" message. (A18) [automated: knk-paper
   `NavigationServiceTest.withGuidanceV2WalkingBackOnTheRoadDrawsTheRoadTrailFromThePlayer`; knk-core
   `NavigationSessionCursorTest.walkingBackAlongTheRoadWindsTheCursorBackAndKeepsTheProgress`]
5. On the same route, walk back before the route's turn you already passed. **Expected:** the HUD shows the turn ahead
   again, but its chat message is not said a second time. (A18) [automated in part: knk-core
   `NavigationSessionCursorTest.theManeuverAheadComesFromTheCursor` (the turn ahead again); the chat line is said once
   by the service's announced index, unchanged]
6. Step off the road sideways by about 15 blocks and wait three seconds. **Expected:** "You left the road -
   recalculating.", then a light blue walk leg to the road. It leads to the road ahead of the nearest point (about 13
   blocks ahead when you stand 15 off a straight road), or behind you when the road there is the cheaper way on.
   (A19) [automated: knk-paper `NavigationServiceTest.withGuidanceV2ThePlayerOffTheRoadJoinsItAtTheLeastRemainingCost`;
   knk-core `JoinPointTest` (ahead, behind, the road behind the player on a U-turn)]
7. If there is a looped road or a switchback: walk the route through the place it passes twice (or along one arm of
   the switchback, close to the other). **Expected:** the trail stays on the branch you are on; it does not jump to
   the other pass. (A20) [automated: knk-core `PolylineCursorTest.aLoopKeepsTheCursorOnTheRightBranch`,
   `PolylineCursorTest.aSwitchbackDoesNotJumpToTheOtherArm`]
8. On a walk leg (step 1), walk forwards along it, then walk back several blocks along it. **Expected:** the leg is not
   recomputed and nothing is said; the trail is drawn from where you stand; no "You're heading away" message. Also on
   the walk to the road (step 6): walking back along it keeps it. (A21) [automated: knk-paper
   `NavigationServiceTest.withGuidanceV2AWalkLegIsNotRecomputedWhileThePlayerIsNearItAlsoWalkingBack`,
   `NavigationServiceTest.withGuidanceV2TheStartLegStaysWhileThePlayerWalksBackAlongIt`]
9. On a walk leg, walk more than 6 blocks away from its trail (through another door or across a field). **Expected:**
   within two seconds a new walk leg appears from where you are (the old trail stays until it does), with no message;
   at most one new leg every three seconds. On the walk to the road the leg ends instead, and after two seconds off
   the road "You left the road - recalculating." brings a new route and a new walk to its join point. (A21)
   [automated: knk-paper
   `NavigationServiceTest.withGuidanceV2AWalkLegBeyondRecomputeDistanceIsRecomputedAtMostOncePerInterval`,
   `NavigationServiceTest.withGuidanceV2TheStartLegStaysWhileThePlayerWalksBackAlongIt`; the feel is manual]
10. Set `navigation.guidance-v2: false`, restart, and repeat step 4. **Expected:** today's behaviour: the trail stays
    drawn from the farthest point you reached, with a straight light blue line from you to it; walking back along a
    walk leg says "You're heading away … recalculating". `trail-leg-spacing` and `cursor-jump` change nothing. (A16)
    [automated: knk-paper `NavigationServiceTest.withTheFlagOffTheNewKeysChangeNothing` (a full transcript of trail,
    HUD, chat and events with other values of both keys),
    `NavigationServiceTest.withTheFlagOffWalkingBackOnTheRoadKeepsTheTrailAtTheFarthestPoint`,
    `NavigationServiceTest.withTheFlagOffTheStartLegWalkedBackAlongIsHeadingAwayAsToday`; knk-core
    `NavigationSessionCursorTest.withTheFlagOffTheSessionIsTodays` (a transcript of today's session)]
11. NPCs: start an NPC walking a road route (any NPC with navigation) while a player navigates. **Expected:** the NPC
    moves exactly as before; nothing in this phase touches NPC navigation (§ 7.5.8). [automated: the unchanged NPC
    unit tests and the paper-boot NPC movement scenarios]

## 10. Phase 7: plaza lines for the players' trail (#712, tier:2)

*Step 1 built 2026-11-18 (link L10): the plaza line in knk-core (`PlazaCurve` in `core/navigation/shape`: a curve from
where a route enters a plaza to where it leaves, pulled towards the plaza node by `plaza-pull` 0.35, checked on the
plaza's clearance map, regions and floor, with `PlazaLine`'s A* guided by the curve when the curve does not fit; plazas
only, by the NPC rule) and the staff preview `/knk road plazaline [<plaza or junction>]`. The developer viewed the lines
on 2026-11-18 (§ 10.1, #712): "Cinix" is Brink and the South Gate plaza; a curve is taken down to 0.65 from an obstacle
(`plaza-curve-clearance`, O33). Step 2 built the same day (link L10): with `navigation.plaza-lines` on the road trail is
drawn along the plaza line where a route crosses a plaza (§ 10.2); the route, its length, the ETA, the maneuvers and
the HUD are unchanged. With the flag off (the default) everything is as before. § 10.1: 4 of 7 steps automated (3 in
part), done by the developer; § 10.2: 9 of 9 steps automated (3 in part), the look is the developer's.*

### 10.0 Preconditions

1. Deployed: plugin build from `next` with phase 7 step 1 (knk-plugin PR for #712 step 1 merged), or the branch
   `claude/offroad-plaza-lines` on the dev server.
2. Settings: none needed for the preview; it works with `navigation.plaza-lines: false`. To compare pulls, add under
   `navigation:` `plaza-pull: 0.35` and `plaza-guide-cost: 2` (the defaults) and restart after each change. Which
   junctions count as plazas and how far a plaza reaches come from `npc.navigation.corridor-half-width` (4) and
   `npc.navigation.plaza-corridor-blocks` (16); the clearance from `navigation.walk.wall-clearance` (0.8).
3. Accounts and data: a staff account with `knk.admin.road`; the road network of Cinix built (Brink, Northern Gate
   Square, Merchant's Square and the square on the quarry-to-keep route, node 39 in the snapshot of 2026-11-17); one
   street T junction (3-wide streets) for step 4.

### 10.1 Step 1: the developer looks at the lines (before the trail uses them)

1. Stand on Brink and type `/knk road plazaline Brink`. **Expected:** chat shows a header ("preview, the trail does not
   use them; plaza-pull 0.35, clearance 0.80") and one line per pair of roads meeting at Brink: `curve` (green
   particles), `A* line` (orange, the curve did not fit; chat says why), `no line` (the route keeps its bend), with the
   line's length against the chord (straight entry to exit) and the right angle (the road graph's bend through the
   node), and its least clearance. White particles show the road graph's bend, a light blue ring the plaza's edge, red
   particles a rejected curve. The particles stay 10 seconds; typing the command again replaces them. (A22, A23)
   [automated in part: knk-paper `PlazaLinePreviewTest.aNamedPlazaShowsEveryPairOfItsRoadsInChatAndAsParticlesForTenSeconds`;
   scenario `plaza-line-brink` (the lines on Brink's real blocks from the snapshot, logged); the look is manual]
2. Look at each line on Brink and judge four things. **Expected:**
    1. **No wall hugging:** the line keeps about a block from walls, fences, stall faces and the plaza's edge; it does
       not run along them.
    2. **No detour to the centre:** a turn bends gently towards the node; the line does not run to the node and back
       (that is the white bend), nor out to a corner of the square.
    3. **The clearance kept:** wells, lamp posts, stalls and trees are passed with room (`clearance at least` 0.75 or
       more on a curve; an A* line round an obstacle at least 0.35).
    4. **Regions respected:** the line never cuts through a house, shop, garden or gate region the road itself does
       not pass.

   [automated in part: knk-core `PlazaCurveTest` (A22 on the L, T and well scenes: the pull, the clearance, inside the
   footprint; A23 the stall; a region the route does not pass; a region it does pass between its sparse points);
   scenarios `plaza-line-brink`, `plaza-line-cinix-south-square`, `plaza-line-cinix-northern-gate-square` (every line
   found stays over walkable floor and at least 0.35 from a wall, post or drop on the live blocks); judging the shape
   is manual]
3. Do steps 1 and 2 on Cinix: `/knk road plazaline "Northern Gate Square"`, `/knk road plazaline "Merchant's Square"`
   and the square on the quarry-to-keep route (`/knk road plazaline <node id>`; `/knk road show` gives the id).
   **Expected:** as in step 2. Say on #712 which of these is the plaza you mean by "Cinix". (A22, A23)
4. `/navigate` to a place on the far side of a plaza (entering on one road, leaving on another at about a right angle),
   then type `/knk road plazaline` with no name. **Expected:** one line per junction of your route; a street junction
   says "a street junction (open floor no wider than the corridor), no plaza line"; your trail itself is unchanged
   (gold particles through the node as before). (A22, O19, A24) [automated: knk-core
   `PlazaCurveTest.aStreetTJunctionGetsNoPlazaLine`; knk-paper
   `PlazaLinePreviewTest.theRoutesPlazasArePreviewedWithoutTouchingTheSession`]
5. Optional, the pull (O30): set `navigation.plaza-pull: 0.2`, restart, repeat step 1 on one plaza; then `0.5`.
   **Expected:** at 0.2 the lines run closer to the straight entry-to-exit line, at 0.5 closer to the node. Say on
   #712 which pull looks right; the default stays 0.35 unless you choose another.
6. Report on #712: "OK" for the trail to use the lines (step 2), or what falls short (the plaza, the pair of roads,
   a screenshot). If the lines fall short, the fallback (builder through-edges, O29) is your decision.
7. With the preview done, walk a route across a plaza. **Expected:** the trail, the HUD distance, the ETA and the
   maneuvers are exactly as before phase 7 (step 1 changes no route, session or trail). (A24, A25) [automated in part:
   no trail, session or route code reads `plaza-lines` in step 1; knk-paper
   `ConfigLoaderNavigationTest.thePlazaLineKeysAreInConfigYmlOffWithTheDesignDefaultsAndAreChecked`,
   `PlazaCrossingsOfTest` (the route's plaza junctions unchanged)]

### 10.2 Step 2: the trail draws the plaza lines

Preconditions: plugin from `next` with phase 7 step 2 (knk-plugin PR for #712 step 2 merged). Under `navigation:` set
`plaza-lines: true` and keep (or add) `plaza-pull: 0.35`, `plaza-guide-cost: 2` and `plaza-curve-clearance: 0.65`;
restart. `guidance-v2` may be on or off (the road trail's spots are fixed along the route either way). A player account
without staff rights; a staff account with `knk.admin.road` for step 8.

1. As the player, `/navigate` to a place beyond Brink so the route enters Brink on one road and leaves on another at
   about a right angle (the quarry-to-keep route). Walk towards Brink. **Expected:** before you reach the square, the
   gold trail ahead bends from road to road along a rounded line pulled gently towards the node, not to the node and
   back and not along the square's edge; it is the green or orange line `/knk road plazaline Brink` shows for that
   pair of roads. (A22) [automated: knk-paper
   `NavigationServiceTest.withPlazaLinesTheTrailRoundsTheJunctionOnThePlazaLine` (the spot at the node drawn 35 % of
   the way from the chord's middle to the node), knk-core `PlazaTrailTest.spotsInsideACrossingMoveOntoItsLineByTheirShareOfTheWay`,
   `PlazaTrailTest.aPlazaCrossingIsPlacedOnTheRoutePolylineByItsEntryAndExit`; the look is manual]
2. Stand still on the square for ten seconds, then take a few steps along the trail. **Expected:** the particles on
   the square stay where they were on every redraw; they do not slide along the line. (A22, A17) [automated: knk-core
   `PlazaTrailTest.theSameAlongIsAlwaysTheSamePointSoParticlesStayPut`]
3. Do the same through the South Gate plaza (node 39) and Northern Gate Square. **Expected:** as in step 1; the lines
   keep clear of walls, wells, stalls and posts by about two thirds of a block or more (a curve), or go round them (an
   orange A* line, at least a third of a block from any obstacle). (A22, A23, O33) [automated in part: knk-core
   `PlazaCurveTest` (the L, T, well and stall scenes, `theCurveIsTakenDownToItsOwnClearance`); scenarios
   `plaza-line-brink`, `plaza-line-cinix-south-square`, `plaza-line-cinix-northern-gate-square` (every line over
   walkable floor and at least 0.35 from a wall, post or drop on the real blocks)]
4. Navigate through a plaza whose crossing line has a well, stall or tree on it (Merchant's Square from Wearway #19 to
   #35 has one). **Expected:** the trail goes round the obstacle, not through it. (A23) [automated: knk-core
   `PlazaCurveTest.aStallOnTheCurveGivesTheGuidedLineRoundIt`]
5. Navigate through a street T junction (3-wide streets). **Expected:** no plaza line; the road trail turns there as
   today. (A22, O19) [automated: knk-core `PlazaCurveTest.aStreetTJunctionGetsNoPlazaLine`]
6. On a route through a plaza, watch the HUD distance, the ETA and the turn announcements; then set
   `plaza-lines: false`, restart and walk the same route. **Expected:** the same distance, ETA, percentage and the
   same maneuver messages at the same places, with the flag on and off; only the drawn trail on the plazas differs.
   (A25) [automated: knk-paper `NavigationServiceTest.plazaLinesChangeNeitherTheRouteNorItsNumbers` (a transcript of
   the session's progress, the route length, the maneuvers, every HUD update and every chat line, flag on and off)]
7. With `plaza-lines: false` walk through a plaza. **Expected:** today's trail: through the node with its sharp bend.
   (A24) [automated: knk-paper `NavigationServiceTest.withPlazaLinesOffTheTrailIsDrawnAsToday`,
   `NavigationServiceTest.withoutAPlazaWorldTheFlagDrawsAsToday`, `TrailRendererTest.withoutAPlazaTrailTheRouteIsDrawnAsBefore`]
8. As staff, with `plaza-lines: true`, run `/knk road status` after the walks. **Expected:** a line
   "plaza lines: on; placed N of M crossings" with N at least the plazas you crossed with a line. [automated in part:
   knk-paper `NavigationServiceTest.withPlazaLinesTheTrailRoundsTheJunctionOnThePlazaLine` (the status text);
   `RoadAdminCommandTest` (the status lines)]
9. NPCs: start an NPC walking a road route across a plaza while a player navigates. **Expected:** the NPC moves exactly
   as before (its own plaza lines follow `npc.navigation.plaza-lines`). [automated: the unchanged NPC unit tests
   (`PlazaLineTest`, `RouteFollowerPlazaTest`, `NavGroupPlazaTest`) and the paper-boot `npc-plaza-line` scenarios]

## 11. Phase 8: persisted walk tiles (#713)

Written when phase 8's scope is designed, after the phase 0 report and phase 3.

## 12. F1: walk-search fixes from the phase 0 runs (#771 items 1 and 2, tier:2)

*Built 2026-11-19 (fix link F1, knk-plugin `claude/offroad-walk-fixes-771`, merged into `next`). No flag: both fixes
make valid routes work, with `guidance-v2` on and off. No config change.*

1. *Recompute keeps the found way.* A walk leg keeps its last found path. When the trail is recalculated (after drifting
   more than `recompute-distance` off it, or once it is `chunk-ttl-seconds` old), the search also captures the rest of
   that path and allows at least its length, so it can take the same way again. This fixes scene 1 in **direct mode**:
   one walk search from spawn, which happens only with a raised `max-snap-distance`. In the runs, every recalculation
   from inside the keep searched only the box round the player and the hall.
2. *Open trapdoor hatches.* An open trapdoor directly above a ladder is climbed like the ladder, so roof hatches are
   passed up and down. A closed trapdoor stays solid: it can be stood on and is never passed.

**Shipped settings and scene 1 (known, not fixed by F1).** With `max-snap-distance` 48, scene 1 is a road route plus a
last walk leg. The road graph's point nearest the hall in a straight line is on the keep stair house's lower landing
(edge 2000000033, about 1415 58 -490), 15 blocks below the hall and next to the old stuck spot. So the road part ends
there, and the last walk leg starts in that dead end with no earlier found path to keep. The only way from there to the
hall is about 290 blocks (out south and round through the courtyard). That is outside the leg's capture box and over
its length cap: FALLBACK at the shipped walk limits, and NO_PATH even with run 2's walk limits (the box closes). Reached
by the road, the hall stays unreachable until a road reaches the hall's floor, or the road goal of a point destination
is chosen among road points the destination can be walked to from (follow-up on #771). Step 1 records this. Fix link F2
(§ 13, #780) adds that choice behind `navigation.road-goal-reachable`.

5 of 7 steps automated (3 in part). The developer's live test is steps 1, 3 and 5 (about 20 minutes).

### 12.0 Preconditions

1. Deployed: plugin build from `next` with knk-plugin#88 (F1) merged. No config change.
2. Settings, **shipped first**: `max-snap-distance: 48` and the shipped walk limits (`walk.max-length` 144,
   `walk.detour-allowance` 48, `walk.max-expansions` 20000, `walk.max-chunks-per-request` as shipped),
   `navigation.walk.enabled: true`. The optional steps 2 and 4 use run 2's settings of the measurements report
   (`walk.max-length` 1000, `walk.detour-allowance` 600, `walk.max-expansions` 200000, `walk.max-chunks-per-request`
   800 and `max-snap-distance` 600: direct mode, as in the runs). Restore the shipped settings after them (O32: real
   routes never raise `max-snap-distance`).
3. Accounts: player A, and staff A with `knk.admin.road` (for `/knk road status`).
4. The dev world: the keep, the storage hall (Location 56), the Garrison Watchtower Roof (Location 53) with its hatch
   open (the spruce trapdoor at 1400 107 -540 over the ladder below it), and the Keep Tower Roof (Location 52). The
   road passes the watchtower at about 1399 80 -544, 26 blocks below the roof.

### 12.1 Steps

1. **Shipped settings.** As player A at spawn (1443 43 -567), run `/navigate Keep storage hall` and follow the trail.
   **Expected (known, not fixed by F1):** the road trail leads into the keep stair house and ends on its lower landing
   (about 1415 58 -490). The last walk leg then says "No conventional path to Keep storage hall found." because the hall
   is about 290 blocks of walking away (see "Shipped settings and scene 1" above). Note where the road trail ends; that
   is the follow-up's evidence. [automated in part: knk-paper `WalkDevWorldFixesTest` shows the walk from that landing
   closing inside the box; the road part is manual]
2. *Optional, run 2's settings (direct mode).* Same as step 1. **Expected:** one walk trail from spawn up the keep stair
   house's lower flights, out and round, into the storage hall; no stop at 1417 59 -489, no "No conventional path". Leave
   the trail on purpose for a few blocks in the lower flights and wait 5 s. **Expected:** the trail is redrawn from where
   you stand, back onto the way. Repeat with `navigation.guidance-v2: true` (restart): the same.
   [automated in part: knk-paper `WalkDevWorldFixesTest.scene1ARecomputeFromTheStuckSpotRefindsTheWayWithTheFoundPathsHint`
   and `scene1WithTheShippedLimitsTheHintAlsoLiftsTheLengthCap` (the keep snapshot);
   `NavigationServiceTest.aRecomputeCarriesTheFoundPathsHintAlsoAfterAFailedSearch` and
   `withGuidanceV2ARecomputeCarriesTheFoundPathsHintToo`; the walk in the world is manual]
3. **Shipped settings.** Stand on the Garrison Watchtower Roof and run `/navigate Keep storage hall` (or any
   destination reached over the road). **Expected:** the walk trail to the road goes down through the open hatch and
   the ladder to the road at about 1399 80 -544 (about 130 blocks of walking); no "No conventional path to the road".
   Then from spawn run `/navigate Garrison Watchtower Roof`. **Expected:** after the road part, the last walk leg ends on
   the roof, up the ladder and through the hatch. As staff A, `/knk road status`: the `walk recent:` lines show FOUND,
   not 44 cells. [automated in part: knk-paper `WalkDevWorldFixesTest.scene8TheWatchtowerHatchIsPassedDownAndUp`
   (44 cells without the open state); the roof-to-road leg at the shipped limits was checked on the same snapshot
   (found both ways, about 129 blocks); knk-core `WalkTrapdoorHatchTest`]
4. *Optional, run 2's settings.* On the watchtower roof, `/navigate Keep Tower Roof`, then back from the Keep Tower
   Roof. **Expected:** a walk trail down through the hatch, across and up the keep tower, and the reverse ending on the
   watchtower roof. At the shipped limits this pair is about 284 blocks of walking and over the cap (FALLBACK): a budget
   question, not the hatch. [automated: knk-paper `WalkDevWorldFixesTest.scene8TheWatchtowerHatchIsPassedDownAndUp`]
5. **Shipped settings.** Close the watchtower hatch and repeat step 3's first navigation from the roof (wait 10 s for
   the cached chunks to expire). **Expected:** "No conventional path to the road found.": a closed trapdoor is never
   passed. [automated: knk-core `WalkTrapdoorHatchTest.aClosedHatchIsNotPassedEitherWay` and
   `aClosedHatchIsStillAFloorOnTheRoof`]
6. An open trapdoor with no ladder below is not a way up or down. [automated: knk-core
   `WalkTrapdoorHatchTest.anOpenTrapdoorWithNoLadderBelowIsNotAWayUp`]
7. The first search of every walk leg is unchanged: L7's golden walk transcripts, the flag-off identity tests and the
   NPC unit tests stay green. NPC walk legs pass open hatches over ladders too; the NPC body check still treats the
   panel as blocking, as before. [automated: knk-core `WalkLegDefaultTranscriptTest`; knk-paper
   `WalkLegPreparerTest.withoutAHintTheBoxAndBudgetAreAsBefore`; the paper-boot `npc-*` scenarios]

## 13. F2: road goal and route ends (#780, #771 items 3 to 5, tier:2)

*Built 2026-11-19 (fix link F2, knk-plugin `claude/offroad-route-ends-f2`, in review). Every change is behind a key off
by default, or a default equal to today's: with the keys as shipped, routes, trails, sessions and NPC movement are as
before.*

1. *`navigation.road-goal-reachable` (#780 option (b), #771 item 4).* A point destination's road goal (where the road
   part ends and the last walk leg starts) is chosen by walk reachability. Up to `road-goal-candidates` (12) road
   points, one per road edge within `max-snap-distance` of the destination, today's nearest point among them, are each
   searched on foot to the destination within the shipped `walk:` limits, one search at a time off the main thread.
   Among the reached ones, the least road length plus walk length wins. The first route is today's; the chosen one
   replaces it silently once the searches answer. None reached: today's point. The last walk leg then starts with the
   chosen walk path as its hint (F1's `WalkRecomputeHint`).
    1. On the keep snapshot the hall's goal moves from the stair house's lower landing (edge 2000000033, 1415 58 -490;
       FALLBACK on foot) to the end of edge 2000000017 in the keep's courtyard (1421 84 -521): 347 blocks by road plus
       97 on foot.
    2. Scene 2 (#771 item 4) has the same cause: the straight-line goal lies past the point where the walk leaves the
       road. On the tower snapshot the road part gets 72 blocks shorter and road plus walk 38 blocks shorter.
2. *`navigation.road-to-its-end` (#771 item 5).* When the road network is swapped (live edge tags, a rebuild) while the
   player follows a road route within `max-snap-distance` of the destination, today's code switches to direct mode: a
   walk leg from where the player stands, partway along the road. With the key on the road route is kept, re-routed on
   the new network, and the last walk leg starts at the road's end. Scene 3's road goal itself is the first key's
   business (the straight-line goal on the road under the watchtower, from which the walk is longer than from the
   road by the garrison).
3. *`navigation.trail-leg-spacing` with `guidance-v2` off (#771 item 3).* The flag-off walk trail now uses the key's
   spacing too. The default stays 3.0 (today's); 1.5 to 2.0 is the suggested range for a trail that reads as a line in
   grass.

The developer's live test is steps 1, 3, 4 and 5 (about 25 minutes).

### 13.0 Preconditions

1. Deployed: plugin build from `next` with the F2 PR merged; `config.yml` with the keys of the deploy notes merged.
2. Settings: **shipped**: `max-snap-distance: 48` and the shipped walk limits (`walk.max-length` 144,
   `walk.detour-allowance` 48, `walk.max-expansions` 20000, `walk.max-chunks-per-request` 64), `walk.enabled: true`,
   `guidance-v2: false`. Never raise `max-snap-distance` for these steps (developer decision on #698). For steps 1 to 4:
   `road-goal-reachable: true` and `road-to-its-end: true` (restart). Restore `false` afterwards if they are not kept.
3. Accounts: player A.
4. The dev world: spawn (1443 43 -567), "Keep storage hall" (Location 56), "Keep Tower Roof" (Location 52), "Garrison
   Watchtower Roof" (Location 53, its hatch open).

### 13.1 Steps

1. As player A at spawn, `/navigate Keep storage hall` and follow the trail. **Expected:** for a second or two the trail
   of today's route shows (into the keep stair house); then the road trail leads up into the keep's courtyard instead,
   and ends there (about 1421 84 -521). The last walk leg finds the way down into the hall (about 100 blocks) and you
   arrive; no "No conventional path to Keep storage hall found." [automated in part: knk-paper
   `NavigationServiceRouteEndsTest.withTheKeyOnTheHallsRoadGoalIsOneTheHallIsReachedFrom` and
   `theLastLegFromTheChosenGoalStartsWithItsWalkPathAndReachesTheHall` (the keep snapshot, the real walk search with the
   shipped limits); following the trail is manual]
2. With `road-goal-reachable: false` the hall's road goal is today's dead end on the stair house's lower landing (§ 12
   step 1). [automated: knk-paper `NavigationServiceRouteEndsTest.withTheKeyOffTheHallsRoadGoalIsTodaysDeadEnd`]
3. From spawn, `/navigate Keep Tower Roof` (scene 2). **Expected:** the road trail ends where the walk trail starts up
   the stair; the road trail does not run on about 10 blocks past it with the walk trail coming back. [automated in part:
   knk-paper `NavigationServiceRouteEndsTest.scene2WithTheKeyOnTheRoadNoLongerRunsPastTheWalksStart` (the tower
   snapshot); what the trail looks like is manual]
4. From spawn, `/navigate Garrison Watchtower Roof` (scene 3) and follow the road trail to its end. **Expected:** the
   road trail leads all the way to the road's end; the walk trail starts only there, never while you still follow the
   road. Note where the road part ends (by the garrison or on the road under the watchtower): that is the evidence
   for #771 item 5. [automated in part: knk-paper
   `NavigationServiceRouteEndsTest.withRoadToItsEndTheRoadRouteIsKeptToItsEnd` and
   `withTheKeyOffANetworkSwapInsideMaxSnapSwitchesToDirectModeAsToday` (a network swap within 48 blocks); the trail in
   the world is manual]
5. Set `trail-leg-spacing: 1.5` (restart; `guidance-v2` stays `false`). Navigate to any destination with a walk leg in
   open grass (a target within 48 blocks across a field). **Expected:** the walk trail's particles are about 1.5 blocks
   apart and read as a line. Try 2.0, keep the value you prefer or set 3.0 back. [automated in part: knk-paper
   `TrailRendererTest.theFlagOffWalkTrailTakesTheLegSpacingAndItsDefaultIsTodays`; the look is manual]
6. With every F2 key as shipped (`false`, `false`, spacing 3.0) routes, trails, chat, walk searches and events are
   today's, call for call, whatever `road-goal-candidates` is. [automated: knk-paper
   `NavigationServiceRouteEndsTest.withTheKeysOffEverythingIsAsToday`; knk-core `WalkLegDefaultTranscriptTest` and the
   earlier links' flag-off identity tests, unchanged]
7. NPC road plans (`planRoadFor`) and the NPC walk planner keep today's road ends with the keys on; no walk search runs
   for them. [automated: knk-paper `NavigationServiceRouteEndsTest.anNpcRoadPlanKeepsTodaysEnds`; the paper-boot `npc-*`
   scenarios and both replays]
8. The candidate set and the choice: today's point first, one per road edge within reach, nearest first, the same place
   once, at most `road-goal-candidates`; the least road plus walk wins, a tie goes to the nearer point. [automated:
   knk-core `RoadGoalChoiceTest`]
9. `road-goal-candidates` outside 1 to 32 stops the plugin's config load with a message. [automated: knk-paper
   `NavigationServiceRouteEndsTest.theKeysAreReadAndValidated`]

## 14. F3: smoke-test failures of 2026-11-19 (#780, #771, #710, tier:2)

*Built 2026-11-20 (fix link F3, knk-plugin `claude/offroad-smoke-fixes-f3`, in review). It fixes the failures of the
developer's live runs of § 8, § 12 and § 13 on 2026-11-19 (comments of 20:32 to 21:04 UTC on #780, #771 and #710).*

1. *The road goal stopped the road too early (§ 13 steps 3 and 4).* With `road-goal-reachable: true` a candidate's
   score is now its road length plus `road-goal-walk-weight` (new key, default 4.0) times its walk length, the least
   winning: a block walked counts four times a block of road, so the road carries the route as far as it usefully goes
   and the walk starts as late as it can. The candidates now include the road's nodes onward from today's nearest
   point (within `max-snap-distance`), so the road past today's goal (e.g. node #74 at the end of Keepstreet) can be
   chosen. Every choice writes one INFO line to the console with each candidate's road and walk lengths.
    1. Keep Tower Roof (`keep-tower.zip`, the route from the snapshot's road the long way through the Keep Upper
       Stairhouse and the Keep Garrison, as live): with F2's road plus walk the goal was the garrison exit (1399 80
       -532, about 198 walked; live 202). Now the road goes on through the garrison and into the Keep Gate (1421 84
       -521, 161 walked, the shortest walk of all candidates; node #74's walk is 168).
    2. Garrison Watchtower Roof: with F2's rule the goal stayed on the road under the watchtower (124 walked). Now the
       road carries on round the garrison and the walk starts east of it (1417 81 -546, 86 walked).
2. *"In 6 m: Turn left onto Wearway" 4× before the player moved (§ 13 step 3).* Each silent route replacement (the
   road-goal choice, a live-tag network swap) said the first turn again. With either route-end key on, a replacement
   no longer repeats a maneuver already said (same text at the same node).
3. *0 expansions from the watchtower roof (§ 12 step 3a).* Not reproduced on the snapshots: from every roof floor cell,
   the snow layers included, the search to every road point within 60 blocks leaves its start. A search that never
   leaves its start now says at INFO which end was unusable ("no walkable cell near the start" or "... the target")
   with both ends' coordinates. One suspect for the repeat: the gate door "Keep Stair House" (ID 2), whose sheared
   reference points the plugin warns about at every start, lies on the road the roof's start leg aims at from 45 blocks
   (the stair house road at about 1414 64 -531).
4. *The open door at 1405 104 -494 was not crossed (§ 8 step 1).* The walk capture denied every door block the player
   may not open (WorldGuard use or interact), open doors included, so for a player without use rights in the keep the
   open spiral-stair door was a wall. This does not depend on `guidance-v2`: the flag-off runs that found the way were
   other runs. Now an open door is passed without the door check; a closed one is asked as before. NPC access is
   unchanged.

The developer's live test is steps 1 to 5 (about 25 minutes).

### 14.0 Preconditions

1. Deployed: plugin build from `next` with the F3 PR merged; `config.yml` with the deploy notes merged
   (`navigation.road-goal-walk-weight: 4.0`; `trail-leg-spacing: 2.0`, the new shipped default).
2. Settings: **shipped**: `max-snap-distance: 48` and the shipped walk limits (`walk.max-length` 144,
   `walk.detour-allowance` 48, `walk.max-expansions` 20000, `walk.max-chunks-per-request` 64), `walk.enabled: true`,
   `trail-leg-spacing: 2.0` (the developer's choice in § 13, shipped as the default since F3). Never raise `max-snap-distance` for these steps. For
   steps 1 to 3: `road-goal-reachable: true`, `road-to-its-end: true`, `guidance-v2: false` (restart).
3. Accounts: player A (the developer's usual player) and player B without WorldGuard use rights in the keep (MrBedue in
   the § 8 run).
4. The dev world: spawn (1443 43 -567), "Keep Tower Roof" (Location 52), "Garrison Watchtower Roof" (Location 53, its
   hatch open), "Keep storage hall" (Location 56); the spiral-stair door at 1405 104 -494 open.

### 14.1 Steps

1. As player A at spawn, `/navigate Keep Tower Roof` (scene 2). **Expected:** the chat says "In … m: Turn left onto
   Wearway" (or the first turn of the route) once, not 4×. After a second or two the road trail runs through the Keep
   Garrison and on into the Keep Gate, and ends there (about 1421 84 -521; or past the Keep Gate at node #74, if the
   live walk from there is shorter). The last walk leg is about 160 blocks, not 202. The console shows one line
   `[Navigation] <player>: road goal for Keep Tower Roof, <n> candidates (walk weight 4.0): …` with the candidates'
   road and walk numbers and `CHOSEN` at the goal used. Copy that line into the result comment. [automated in part:
   knk-paper `NavigationServiceRouteEndsTest.scene2TheRoadGoesIntoTheKeepGateAndTheWalkIsTheShortest`,
   `scene2WithF2sRoadPlusWalkTheRoadStopsAtTheGarrisonExitAsInTheSmokeTest` and
   `withTheKeysOnAReplacedRouteDoesNotRepeatAnAnnouncedManeuver` (the tower snapshot); the live route and the trail are
   manual]
2. As player A at spawn, `/navigate Garrison Watchtower Roof` (scene 3). **Expected:** the road part no longer ends on
   the road under the watchtower just past the Garrison Main Gate; the console line shows the chosen candidate with
   a shorter walk than the one under the watchtower (live 129 blocks). The walk leg goes up the ladder and through the
   hatch onto the roof. [automated in part: knk-paper
   `NavigationServiceRouteEndsTest.scene3TheWatchtowersWalkStartsWhereItIsShortest` and
   `scene3WithF2sRoadPlusWalkTheWatchtowerGoalStaysUnderTheWatchtowerAsInTheSmokeTest`; the live route is manual]
3. As player A on the Garrison Watchtower Roof, on plain roof floor away from the hatch (the § 12 step 3 spot), hatch
   open, `/navigate Keep storage hall`, then `/knk road status`. **Expected:** the walk to the road is found (down
   through the hatch). If it says "No conventional path to the road" again, copy the console line
   `[Navigation] Walk search #<n>: no walkable cell near the start|target (start feet …, target floor …)` and the
   `walk recent` line into the result comment: it names the unusable end and both positions. Repeat from two other
   spots on the roof. [automated in part: knk-paper
   `NavigationServiceRouteEndsTest.scene3aFromEveryRoofCellTheSearchToEveryNearbyRoadPointLeavesItsStart` and
   `aSearchThatNeverLeavesItsStartSaysWhichEndAtInfo`; the live run is manual]
4. Set `guidance-v2: true` (restart; `walk.clearance-cost: 5`, `walk.wall-clearance: 0.8`, `walk.curve: true` as in
   § 8). As player B at spawn, `/navigate Keep Tower Roof` with the spiral-stair door open. **Expected:** the last walk
   leg is found up the spiral stair, through the open door and onto the roof, without walking through the door first;
   no "No conventional path found." [automated in part: knk-paper
   `WalkAccessFactoryTest.anOpenDoorIsPassedWithoutThePlayersDoorCheck` and
   `NavigationServiceRouteEndsTest.theOpenKeepDoorBlocksTheWayWithEitherFlagOnlyWhenItIsDeniedAsIfShut` (the tower
   snapshot: the door denied as before gives the live NO_PATH with a partial trail to the door, with either flag); the
   live run is manual]
5. As player B, close the spiral-stair door and navigate to "Keep Tower Roof" again (wait 10 seconds after closing it:
   the walk capture keeps a chunk that long). **Expected:** "No conventional path found." as before: a closed door
   player B may not open still blocks the way. Open the door again afterwards. Then repeat step 4 with `guidance-v2:
   false` (the flag-off comparison § 8 step 7 asked for): the same result. [automated in part: knk-paper
   `WalkAccessFactoryTest.aClosedDoorIsStillThePlayersDoorCheck`; the live run is manual]
6. With the route-end keys off, routes, trails, chat and walk searches are today's (a network swap still repeats a
   turn, as today). [automated: knk-paper `NavigationServiceRouteEndsTest.withTheKeysOffEverythingIsAsToday` and
   `withTheKeysOffANetworkSwapStillRepeatsItAsToday`; knk-core `WalkLegDefaultTranscriptTest` and the earlier links'
   flag-off identity tests, unchanged]
7. The onward candidates and the weighted choice: today's point first, the road's nodes onward from it within reach,
   no place twice, at most `road-goal-candidates`; weight 1 is F2's rule, 4 picks the shorter walk.
   `road-goal-walk-weight` outside 1 to 100 stops the config load. [automated: knk-core `RoadGoalChoiceTest`; knk-paper
   `NavigationServiceRouteEndsTest.theKeysAreReadAndValidated`]
8. `trail-leg-spacing` ships as 2.0 (the developer's choice in § 13 step 5): the bundled `config.yml` and the code's
   default both say 2.0; a server's existing `config.yml` keeps its own value. [automated: knk-paper
   `ConfigLoaderNavigationTest.thePhase62KeysAreInConfigYmlWithTheDesignDefaultsAndAreChecked` and
   `TrailRendererTest.theLegSpacingDefaultsToTwoAndIsValidated`, `theFlagOffWalkTrailTakesTheLegSpacingAndItsDefaultIsTwo`]

## 15. L7b: default route mode per permission group (#852, tier:3)

*Step A built 2026-11-20 (link L7b, knk-web-api and knk-web-app `claude/offroad-group-route-mode`, PRs into `next`):
the nullable `DefaultRouteMode` on permission groups (migration `AddPermissionGroupDefaultRouteMode`), `defaultRouteMode`
in the group DTOs (the plugin reads it from `GET api/PermissionGroups`), the field on the PermissionGroup form seed
(step Group) and the dashboard's "Default route" column. Changing it is a group edit: `knk.admin.user.perm` (or the
plugin key) and `PermissionEscalationGuard`'s rank rule, unchanged. Step B (knk-plugin, after F3) makes `/navigate
<dest>` without a mode word use the default of the player's highest-weight group that has one (§ 15.4).
**Enum follow-up 2026-11-21** (developer decision, branches `claude/group-route-mode-enum`): `DefaultRouteMode` is the
enum `RouteMode` (`Shortest`, `Efficient`, `Preferred`), stored and sent by name, so the form field is an **Enum** field
(a String field fails the form's publish check against the entity); the data migration
`NormalizePermissionGroupDefaultRouteMode` renames stored lowercase words to the names. The plugin reads the name in any
case, so step B is unchanged. API, web and migration steps: 12 of 12 automated (tagged), 2 of them in part. Time: about
15 min for § 15.1 to § 15.3.*

### 15.0 Preconditions

1. Deployed: knk-web-api with the migrations `AddPermissionGroupDefaultRouteMode` and
   `NormalizePermissionGroupDefaultRouteMode` applied (`dotnet ef database update`) and knk-web-app from the same `next`.
   For § 15.4 also the plugin build with step B, and the API migration `SeedNavigateDefaultNode` (#845) applied before
   it: that plugin declares `knk.navigate` as `default: false`, so without the seed players who are not op can't
   `/navigate` at all.
2. Settings: none (no `api.env` key, no plugin `config.yml` key).
3. Data: the PermissionGroup form has the **Enum** field "Default route mode" with the settings JSON
   `{"enumValues": ["Shortest", "Efficient", "Preferred"], "emptyOptionLabel": "None (default: Preferred)"}` (a fresh
   import of the seed `PermissionGroup` has it; a form imported earlier gets it in the form designer, step Group, see the
   changelog entry's admin step 2; a String field added by hand before the follow-up is changed to Enum with these
   settings). The groups Default (weight 0) and Staff (weight 40) exist.
4. Accounts: staff **A** with `knk.admin.user.manage` and `knk.admin.user.perm` in a group ranked above Staff (or
   `*`); staff **B** with the same nodes whose highest group is Staff (so Staff is not below B's rank).
5. For § 15.4: player **D** (also player C), a second Minecraft account that has joined the server and is **not op**
   (an op holds every node, so a refused typed word can't show), at first only in Default; and a road pair where the
   modes take different routes (§ 5.0 item 3: an edge of the shorter way set to `cost 3`). Note the three routes once
   with typed words as an op (`/navigate <dest> shortest`, `efficient`, `preferred`) to compare against.

### 15.1 API

1. As staff A (logged in, or with the plugin key), `GET <api>/api/PermissionGroups`. **Expected:** `200`; every group
   has `"defaultRouteMode": null` right after the migrations. [automated: knk-web-api
   `PermissionGroupDefaultRouteModeTests.GetAllAsync_ThePluginsRead_CarriesTheDefault`,
   `ReadDto_SerializesAsDefaultRouteMode_NullWhenUnset`, `AddPermissionGroupDefaultRouteModeTests`]
2. `PUT <api>/api/PermissionGroups/<Staff id>` with Staff's current fields and `"defaultRouteMode": "Efficient"`, then
   `GET` it. **Expected:** `204`; the group now reads `"defaultRouteMode": "Efficient"` (the enum name; `"efficient"` or
   any other case is read as the same mode). [automated: `PermissionGroupDefaultRouteModeTests.UpdateAsync_AModeName_IsStored`,
   `UpdateAsync_TheFormsBody_SetsOrClears`]
3. The same `PUT` with `"defaultRouteMode": "fastest"`. **Expected:** `400`, a validation problem for
   `defaultRouteMode` from the JSON binding (the value is no `RouteMode`); the stored value is unchanged. A number that
   is no mode (`"defaultRouteMode": 7`) is also a `400`, "DefaultRouteMode must be one of Shortest, Efficient,
   Preferred, or empty for no default.". [automated: `Binding_AnotherWord_IsRefused`,
   `UpdateAsync_ANumberThatIsNoMode_IsRefusedAndNothingIsSaved`, `CreateAsync_ANumberThatIsNoMode_IsRefused`]
4. The same `PUT` without `defaultRouteMode`, then with `"defaultRouteMode": ""`. **Expected:** the first keeps
   `Efficient`; the second clears it (`null`), as does `"defaultRouteMode": null`. [automated:
   `UpdateAsync_Omitted_KeepsTheStoredDefault`, `UpdateAsync_BlankOrNull_ClearsTheDefault`]
5. As staff B, the same `PUT` on Staff with `"defaultRouteMode": "Shortest"`. **Expected:** `403` with the rank reason,
   as for any other change to a group not ranked below B's own; nothing changes. [automated in part: the rank rule is
   the existing group-edit check (`PermissionEscalationGuardTests`), which this field does not change; not tested for
   this field on its own]

### 15.2 Web app

1. As staff A open the dashboard and pick **Permission Group**. **Expected:** a "Default route" column, after Parent;
   Staff shows `Efficient` once set, a group without a default shows `-`. [automated: knk-web-app
   `e2e/permission-group-route-mode.spec.ts` "the dashboard shows each group's default route mode";
   `permissionGroupRouteMode.test.tsx`]
2. Edit Staff. **Expected:** on the Group step a "Default route mode" dropdown with "None (default: Preferred)",
   Shortest, Efficient and Preferred; the stored mode is selected. Pick `Efficient`, Submit. **Expected:** "Permission
   Group updated."; the dashboard row shows `Efficient`. [automated in part: `e2e/permission-group-route-mode.spec.ts`
   "editing a group shows its stored mode, and None clears it" (a one-step test form with the Enum field, mocked API);
   `FieldRenderers.emptyOption.test.tsx`]
3. Edit Staff again, pick "None (default: Preferred)", Submit. **Expected:** saved; the dashboard row shows `-` and
   `GET api/PermissionGroups/<id>` has `null`. [automated: the same e2e test (sends `""`) and
   `UpdateAsync_TheFormsBody_SetsOrClears`, `UpdateAsync_BlankOrNull_ClearsTheDefault`]
4. Create a group "Builders" with weight 50, no "Inherits from" and `Shortest`. **Expected:** "Permission Group
   created."; the row shows `Shortest`. (Builders is the higher-weight group of § 15.4 step 4.) [automated:
   `e2e/permission-group-route-mode.spec.ts` "a new group saves the picked mode through POST api/PermissionGroups",
   `CreateAsync_StoresTheDefaultOrNone`]
5. With a form configuration that has no "Default route mode" field (an older import), edit a group that has a
   default and Submit. **Expected:** the default stays. [automated: `UpdateAsync_Omitted_KeepsTheStoredDefault`]

### 15.3 Migration (deploy)

1. On a copy of the production database, apply the migrations. **Expected:** one new nullable column
   `permission_groups.DefaultRouteMode` (`varchar(16)`), null on every row, no other change; `Down` drops only that
   column. [automated: knk-web-api `AddPermissionGroupDefaultRouteModeTests`; CI "Migrations (fresh DB)" on the API PR]
2. On the dev database (where groups may hold a lowercase word from before the enum follow-up), apply
   `NormalizePermissionGroupDefaultRouteMode`. **Expected:** `shortest`, `efficient` and `preferred` become `Shortest`,
   `Efficient` and `Preferred`; null stays null; nothing else changes; `Down` turns the names back into the words.
   [automated: knk-web-api `NormalizePermissionGroupDefaultRouteModeTests`, `NormalizePermissionGroupDefaultRouteModeMySqlTests`
   (real MySQL, CI `mysql-tests`)]

### 15.4 In game (step B)

*Built 2026-11-20 (link L7b step B, knk-plugin `claude/offroad-group-route-mode`, PandiO/knk-plugin#103): the plugin
reads `defaultRouteMode` from `GET api/PermissionGroups` and, for `/navigate <dest>` without a mode word, uses the
default of the player's highest-weight active group that has one (a weight tie goes to the lower group id; an unknown
word counts as no default and is logged once at INFO; the value is read in any case, so the enum names of the 2026-11-21
follow-up need no plugin change). The lookup is cached per player and cleared on `PermissionGroupChanged` and on the
player's membership changes; on a cold cache the first run uses today's default while the cache fills, so no API call
blocks the command: after any group edit or membership change judge the second `/navigate` (pressing Tab after
`/navigate ` also fills the cache). No config key, no migration. Not covered: a siege match on the legacy path
(`navigateInMatch`) passes through no mode, so no group default applies there, as no typed word does today; on the
destination-engine path a found match destination does take it. In-game steps: 5 of 8 automated (1 in part; step 8 is the clean-up). Time:
about 10 min.*

1. Player C only in groups without a default (every group's default None): `/navigate <dest>`. **Expected:** the same
   route as before step B (`preferred`, L7's golden transcripts). [automated: knk-paper
   `NavigateCommandGroupRouteModeTest`, L7 goldens unchanged]
2. Set Staff's default to `Shortest` in the web app (§ 15.2) and give player D Staff without
   `knk.navigate.mode.shortest` (`/knk user <D> group add Staff`). D runs `/navigate <dest>` twice (the § 5 road pair
   shows the difference). **Expected:** the first run after the change may still use `preferred` while the cache fills;
   from the second run on the route is the `shortest` one, and no permission message appears. Then D types
   `/navigate <dest> ` and presses Tab: if `shortest`, `efficient` and `preferred` are offered, Staff holds the mode
   nodes and step 3 can't show; use a new group without nodes (weight 45) in place of Staff. [automated in part: the
   command part in `NavigateCommandGroupRouteModeTest`, the cache in `GroupRouteModeDefaultsTest`]
3. D types `/navigate <dest> efficient` without `knk.navigate.mode.efficient`. **Expected:** refused with "You don't
   have permission to use this command." as before; the group default does not grant typed words.
   [automated: `NavigateCommandGroupRouteModeTest`]
4. Change Staff's default to `Efficient` in the web app (fires `PermissionGroupChanged`). D runs `/navigate <dest>`
   (once to warm the cache, then again). **Expected:** the `efficient` route. Then set Builders (weight 50, § 15.2 step
   4) to `Shortest` and `/knk user <D> group add Builders`. **Expected:** `shortest` wins. Then set Builders to None.
   **Expected:** `efficient` again: a higher group with None is skipped. (If `efficient` and `shortest` take the same
   route on the road pair, the switches in this step can't be seen there.) [automated: knk-core
   `GroupRouteModeResolverTest`, `RouteModeInvalidationHooksTest`]
5. Remove D from every group with a default (`/knk user <D> group remove Builders`, then `remove Staff`, or in the web
   app), then `/navigate <dest>` twice. **Expected:** the `preferred` route again. (Manual: a real player and the live
   cache.)
6. Switch `navigation.destination-engine` in the plugin `config.yml` (the dev server runs with `true`; set `false` to
   test the legacy path, or the other way round), restart, and repeat steps 2 to 5. Set it back afterwards.
   **Expected:** the same results on both paths. [automated: the legacy and the engine path in
   `NavigateCommandGroupRouteModeTest`]
7. Watch an NPC route (any NPC walk from the NPC movement smoke test) while Staff has a default. **Expected:** NPC
   routes are unchanged; NPCs never take a group default. (Manual: NPC walks in the world.)
8. Clean-up: `/knk road edge set <id> cost 1` on the test edge, Staff's default back to None, Builders deleted or kept.
