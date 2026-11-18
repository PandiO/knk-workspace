# Off-road navigation and landmarks — smoke test

**Status:** Draft from the design (2026-11-17); no steps run. Phase 0 (§ 1): 1 of 9 steps automated; phase 1 (§ 2): 4 of 4 steps automated; phase 6.1 (§ 8): 6 of 8 steps automated (3 of them in part); phase 6.2 (§ 9): 11 of 11 steps automated (3 of them in part); phase 7 step 1 (§ 10.1): 4 of 7 steps automated (3 of them in part), the looking is the developer's; the other phases not yet automated (the links tag them).
**Last updated:** 2026-11-18 (§ 10 phase 7 split into step 1, built by link L10, #712: the staff preview and the developer's viewing steps on Cinix and Brink, and step 2, the trail, not built yet); 2026-11-18 (§ 9 phase 6.2 updated to what link L4 built, #711: eleven steps, all automated, three in part); 2026-11-17 (§ 8 phase 6.1 updated to what link L3 built, #710: eight steps, six automated); 2026-11-17 (§ 2 phase 1 updated to what link L2 built, #704: every step automated); 2026-11-17 (§ 1 phase 0 updated to what link L1 built, #703: the measurement steps and the `/knk road status` lines); 2026-11-17 (draft from the design, phases 0, 1, 2, 3, 4, 5.1, 5.2, 6.1, 6.2, 7)
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

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: plugin build from `next` with phase 2.
2. Settings: `navigation.walk.enabled: true`, `navigation.walk-links: true`, `walk-link-range: 40`,
   `walk-link-ratio: 2.0`.
3. Accounts and data: a player account without staff nodes; a staff account; the courtyard scene; a WorldGuard region
   on the courtyard that the player account can be denied entry to; a gate on the courtyard's other exit that can be
   closed.

### 3.1 Steps

1. As the player, stand in the field outside the town and `/navigate` to a building on the far side of the courtyard.
   **Expected:** one trail: a walk leg to the road, the road, a walk leg across the courtyard, the road again, and a
   walk leg into the building, in that order. (A02)
2. Walk the whole route. **Expected:** the HUD shows one route, and no "recalculating" while you stay on the trail.
   (A02)
3. Navigate between two road nodes that are close in a straight line and also close by road (for example, along one
   straight street). **Expected:** no walk link; the route stays on the road. (A03)
4. Navigate between two road nodes more than 40 blocks apart in a straight line, with a long road between them.
   **Expected:** no walk link. (A03)
5. As staff, deny the player entry to the courtyard region; as the player, navigate again as in step 1. **Expected:**
   the route goes around by road; no walk leg crosses the courtyard. (A04)
6. As staff, allow entry again and close the gate on the courtyard's exit; as the player, navigate again.
   **Expected:** no walk link through the closed gate. (A04)
7. Open the gate. As staff, build a wall across the courtyard shortcut, wait a few seconds, and navigate again as the
   player. **Expected:** the shortcut is no longer offered; the next route searches again and goes around. (A05)
8. Remove the wall and navigate again. **Expected:** the shortcut comes back. (A05)
9. Turn `navigation.walk-links` off, reload as the deploy notes say, and navigate as in step 1. **Expected:** today's
   route: walk leg, road, walk leg only.

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

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: plugin build from `next` with phase 4; the seed with the mode nodes in the default group.
2. Settings: no new flag.
3. Accounts and data: a player account with all three `knk.navigate.mode.*` nodes; a second player without
   `knk.navigate.mode.shortest`; the stair house with a ramp beside the spiral stair; a road edge with a cost
   multiplier set (`/knk road edge set <id> cost 3`).

### 5.1 Steps

1. As the first player, `/navigate <dest>` with no mode word. **Expected:** the same route as before the phase
   (`preferred`). (A11)
2. `/navigate <dest> shortest`, `/navigate <dest> efficient` and `/navigate <dest> preferred` to a place where the
   spiral stair and the ramp both lead, and past the weighted road edge. **Expected:** `shortest` takes the spiral
   stair, `efficient` may take the ramp, and `preferred` avoids the weighted edge. (A09)
3. `/navigate <dest> preferred region`. **Expected:** the mode word and the trailing `region` both work. (A09)
4. As the second player, `/navigate <dest> shortest`. **Expected:** the no-permission message; no navigation starts.
   Tab completion after the destination does not offer `shortest`. (A09)
5. In a world with no road cost multipliers, compare `preferred` and `efficient` for the same pair. **Expected:** the
   same route. (A11)

## 6. Phase 5.1: landmark entity (#708, tier:3)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 6.0 Preconditions

1. Deployed: API with the `landmarks` migration; web app; plugin build from `next` with phase 5.1; the destination
   engine P1, P2 and P3 (#96, #103, #69).
2. Settings: `navigation.landmarks: true`.
3. Accounts and data: a staff account with `knk.admin.world.landmark`; a staff account without it; a player account;
   the keep as a structure domain; a WorldGuard region `keep_throne` around the throne room.

### 6.1 Steps

1. As staff with the node, stand in the throne room and run `/knk landmark create Throne room region keep_throne`.
   **Expected:** a confirmation; `/knk landmark list` shows it. (A12)
2. `/knk landmark link <keep domain>`, then `/knk landmark show Throne room`. **Expected:** the domain is shown.
   (A12)
3. In the web app as the same staff member, open the landmark list, rename it to "Throne hall" and save; open the
   keep's domain page. **Expected:** the new name; the landmark is listed on the domain page. (A12)
4. As staff without the node, try to create a landmark in game and in the web app. **Expected:** refused in both;
   nothing is created. (A12)
5. Without logging in, read `GET api/landmarks?world=<world>`. **Expected:** the list is returned (anonymous read).
   (A12)
6. As the player, `/navigate Throne hall` from outside the keep and walk there. **Expected:** navigation ends when you
   enter the `keep_throne` region. (A13)
7. As staff, create a landmark with `radius 5` and one with no extent; navigate to each as the player. **Expected:**
   arrival inside the radius, and within the arrive distance of the pin. (A13)
8. As the player, type `/navigate ` and press tab. **Expected:** landmarks of this world you may navigate to are
   offered; a landmark with `NavigationEnabled` off, one in another world, and (during a siege match) all landmarks are
   not. (A14)
9. As staff, delete the landmark. **Expected:** it disappears from the list, the domain page and tab completion. (A12)

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

*Step 1 built 2026-11-18 (link L10, knk-plugin `claude/offroad-plaza-lines`): the plaza line in knk-core
(`PlazaCurve` in `core/navigation/shape`: a curve from where a route enters a plaza to where it leaves, pulled towards
the plaza node by `plaza-pull` 0.35, checked on the plaza's clearance map, regions and floor, with `PlazaLine`'s A*
guided by the curve when the curve does not fit; plazas only, by the NPC rule) and a staff preview,
`/knk road plazaline [<plaza or junction>]`, that draws the lines for 10 seconds and writes their lengths to chat. The
trail does not use plaza lines yet: the developer looks at them on Cinix and Brink first (O16, risk 12.5), § 10.1. Step
2 (the trail uses them, § 10.2) starts after the developer's OK on #712. With `navigation.plaza-lines` off (the default)
routes, trails, the session and NPC movement are exactly as before. Of § 10.1's 7 steps, 4 are automated (3 of them
in part); the looking is the developer's.*

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

### 10.2 Step 2: the trail uses the plaza lines (after the developer's OK; not built yet)

1. Settings: `navigation.guidance-v2: true`, `navigation.plaza-lines: true`, `plaza-pull` as chosen in § 10.1 step 5.
2. As the player, navigate through Cinix's plaza, entering on one road and leaving on a road at a right angle.
   **Expected:** the trail takes the rounded line from road to road that bends towards the plaza's middle, neither
   along the edges nor to the centre and back; it keeps clear of walls and objects. (A22)
3. Navigate through the plaza with the stall or well on the crossing line. **Expected:** the trail goes around the
   obstacle, not through it. (A23)
4. Navigate through the street T junction. **Expected:** no plaza line; the road trail as today. (A22)
5. Compare the HUD distance and the maneuver announcements with the flag on and off for the same route.
   **Expected:** the same distance, ETA and maneuvers. (A25)
6. Turn `navigation.plaza-lines` off, restart and repeat step 2. **Expected:** today's line through the plaza node.
   (A24)

## 11. Phase 8: persisted walk tiles (#713)

Written when phase 8's scope is designed, after the phase 0 report and phase 3.
