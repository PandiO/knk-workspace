# Off-road navigation and landmarks — smoke test

**Status:** Draft from the design (2026-11-17); no steps run. Phase 4 (§ 5): 8 of 9 steps automated (2 in part); Phase 2 (§ 3): 13 of 14 steps automated (5 in part); Phase 5.1 (§ 6): 21 of 22 steps automated (6 in part); Phase 0 (§ 1): 1 of 9 steps automated; phase 1 (§ 2): 4 of 4 steps automated; phase 6.1 (§ 8): 6 of 8 steps automated (3 of them in part); phase 6.2 (§ 9): 11 of 11 steps automated (3 of them in part); phase 7 step 1 (§ 10.1): 4 of 7 steps automated (3 of them in part), viewed by the developer 2026-11-18; phase 7 step 2 (§ 10.2): 9 of 9 steps automated (3 of them in part); the other phases not yet automated (the links tag them).
**Last updated:** 2026-11-18 (§ 5 phase 4 built by link L7, #707: nine steps, eight automated, two in part); 2026-11-18 (§ 3 phase 2 built by link L5, #705: fourteen steps, thirteen automated, five in part); 2026-11-18 (§ 10 phase 7: step 1 viewed by the developer, O33; § 10.2 step 2 built by link L10, #712: nine steps, all automated, three in part); 2026-11-18 (§ 6.3 phase 5.1 step B, link L8: the in-game steps); 2026-11-18 (§ 6 phase 5.1 updated to what link L8 step A built, #708: API and web steps, plugin steps marked step B); 2026-11-18 (§ 10 phase 7 split into step 1, built by link L10, #712: the staff preview and the developer's viewing steps on Cinix and Brink, and step 2, the trail, not built yet); 2026-11-18 (§ 9 phase 6.2 updated to what link L4 built, #711: eleven steps, all automated, three in part); 2026-11-17 (§ 8 phase 6.1 updated to what link L3 built, #710: eight steps, six automated); 2026-11-17 (§ 2 phase 1 updated to what link L2 built, #704: every step automated); 2026-11-17 (§ 1 phase 0 updated to what link L1 built, #703: the measurement steps and the `/knk road status` lines); 2026-11-17 (draft from the design, phases 0, 1, 2, 3, 4, 5.1, 5.2, 6.1, 6.2, 7)
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

## 7. Phase 5.2: landmark preference weights (#709, tier:2)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 7.0 Preconditions

1. Deployed: plugin build from `next` with phases 4 and 5.2.
2. Settings: `navigation.landmarks: true`.
3. Accounts and data: a player account; two corridors of the keep that lead to the same place, the shorter one
   covered by a landmark with a region and `Preference` 2.0.

### 7.1 Steps

1. As the player, `/navigate <place>`. **Expected:** the trail takes the longer corridor (the weighted one is avoided
   in `preferred`). (A10)
2. `/navigate <place> shortest`. **Expected:** the trail takes the shorter, weighted corridor. (A10)
3. As staff, set the landmark's `Preference` back to 1.0 and navigate again. **Expected:** the shorter corridor.
   (A10)

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
