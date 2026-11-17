# Off-road navigation and landmarks — smoke test

**Status:** Draft from the design (2026-11-17); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-17 (draft from the design, phases 0, 1, 2, 3, 4, 5.1, 5.2, 6.1, 6.2, 7)
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

*Draft from the design (2026-11-17); the link updates it to what was built.*

Covered by the measurement report of #703. Quick pass: as staff, run `/knk road status` after one `/navigate` into the
keep. **Expected:** the walk counters (searches, expansions, capture µs, search µs) show non-zero values. (A01)

## 2. Phase 1: shared shaping package (#704, tier:2)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: plugin build from `next` with phase 1.
2. Settings: the NPC movement keys as on the dev server before (corridor steering and plaza lines on, as in the NPC
   movement smoke test).
3. Accounts and data: a staff account; the NPC movement test scenes.

### 2.1 Steps

1. As staff, run the NPC movement scenes of the NPC navigation smoke test (stair house route, plaza crossing, corridor
   steering). **Expected:** NPCs walk the same lines as before the move; no errors in the console. (A26)
2. As a player, run `/navigate` to a town gate with the off-road flags off. **Expected:** the trail looks as before.
   (A26)
3. Check the server log at startup. **Expected:** no class-loading or missing-class errors from the navigation or NPC
   packages. (A26)

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

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 8.0 Preconditions

1. Deployed: plugin build from `next` with phase 6.1.
2. Settings: `navigation.guidance-v2: true`, `walk.clearance-cost: 5`, `walk.wall-clearance: 0.8`,
   `walk.curve: true`.
3. Accounts and data: a player account; the stair house; the keep.

### 8.1 Steps

1. As the player, stand at the foot of the stair house's spiral stair and `/navigate` to its top. **Expected:** the
   trail keeps about a block from the inner wall (the newel) all the way up, where the stair allows it; it reads as a
   spiral, not a polygon. (A15)
2. Walk up slowly and watch the trail redraw. **Expected:** it stays off the inner wall on every redraw. (A15)
3. Navigate through a keep corridor with a right-angle turn. **Expected:** the trail rounds the corner with room to
   spare and never cuts through the wall. (A15)
4. Navigate through a 1-wide door. **Expected:** the trail goes through the door; the clearance does not close it.
   (A15)
5. Turn `navigation.guidance-v2` off, reload, and repeat step 1. **Expected:** today's trail, unchanged. (A16)
6. Turn it on again and navigate while staff watches `/knk road status`. **Expected:** the shaping time is reported,
   and the server's tick time does not rise noticeably. (A27)

## 9. Phase 6.2: anchored particles and winding back (#711, tier:3)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 9.0 Preconditions

1. Deployed: plugin build from `next` with phase 6.2 (and 6.1 when both are in).
2. Settings: `navigation.guidance-v2: true`, `trail-leg-spacing: 3.0`, `cursor-jump: 12`.
3. Accounts and data: a player account; the stair house; a road route of at least 100 blocks; a route with a loop or
   a switchback (a road that comes back near itself).

### 9.1 Steps

1. As the player, start a walk-leg navigation in the keep and stand still for ten seconds. **Expected:** the particles
   stay in the same places on every redraw; none slide. (A17)
2. Take one step forward. **Expected:** the particles ahead of you do not move; only the ones behind you disappear.
   (A17)
3. Walk around a corner close to the wall. **Expected:** no particles jump to the other side of the wall. (A17)
4. On the road route, walk 40 blocks forward, then turn and walk 20 blocks back along the road. **Expected:** the road
   trail is drawn again from where you stand; no walk leg to the far point; the HUD distance grows again. (A18)
5. Step off the road sideways by 15 blocks. **Expected:** a walk leg to the road; it leads to the join point with the
   least remaining cost, which may be behind you. (A19)
6. Walk the looped route through the place it passes twice. **Expected:** the trail stays on the branch you are on;
   it does not jump to the other pass. (A20)
7. On a walk leg, walk back two or three blocks along it. **Expected:** the leg is not recomputed; the trail is drawn
   from your position; no "heading away" message. (A21)
8. Walk off the walk leg by more than the recompute distance. **Expected:** the leg is recomputed from where you are,
   with a "recalculating" message. (A21)
9. Turn `navigation.guidance-v2` off, reload and repeat step 4. **Expected:** today's behaviour (the trail from the
   farthest point and a straight leg to it). (A16)

## 10. Phase 7: plaza lines for the players' trail (#712, tier:2)

*Draft from the design (2026-11-17); the link updates it to what was built and tags the automated steps.*

### 10.0 Preconditions

1. Deployed: plugin build from `next` with phases 6.1, 6.2 and 7.
2. Settings: `navigation.guidance-v2: true`, `navigation.plaza-lines: true`, `plaza-pull: 0.35`.
3. Accounts and data: a player account; the plazas of Cinix and Brink; a stall or a well on one plaza's crossing
   line; a street T junction.

### 10.1 Steps

1. As the player, navigate through Cinix's plaza, entering on one road and leaving on a road at a right angle.
   **Expected:** the trail takes a rounded line from road to road that bends towards the plaza's middle, neither
   along the edges nor to the centre and back; it keeps clear of walls and objects. (A22)
2. Navigate through the plaza with the stall or well on the crossing line. **Expected:** the trail goes around the
   obstacle, not through it. (A23)
3. Navigate through the street T junction. **Expected:** no plaza line; the road trail as today. (A22)
4. Compare the HUD distance and the maneuver announcements with the flag on and off for the same route.
   **Expected:** the same distance, ETA and maneuvers. (A25)
5. Turn `navigation.plaza-lines` off, reload and repeat step 1. **Expected:** today's line through the plaza node.
   (A24)

## 11. Phase 8: persisted walk tiles (#713)

Written when phase 8's scope is designed, after the phase 0 report and phase 3.
