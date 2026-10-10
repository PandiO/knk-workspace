# Road navigation — smoke test checklist (KNG-27)

**Status:** In progress — Phase 1, 3, 5 passed (with findings); Phase 4 partially run, then blocked. **Fixes for the
2026-10-01 findings are implemented (2026-10-02)** on `claude/road-navigation-smoke-test-bugs-fagl4i` in knk-web-app,
knk-web-api and knk-plugin — see "Fixes implemented (2026-10-02)" at the end of Findings for what to re-test before
resuming Phase 4 items 20+. The direct-mode straight line through terrain (finding 1) stays open as KNG-51.
**2026-10-04:** after the reset — findings H (rural road with grass holes: record it) and I (edges through the ground
at plaza junctions: fixed in the builder, rebuild needed). **Evening:** finding L (Brink's west junction and #3588
lost to junction clustering; builder 5 with a correction report — re-test list at the end of Findings).
**2026-10-05:** rev. 6 Part B (curated tiles) **live-tested and passed** (runs 1-3 under "Curated tiles (rev. 6 Part
B)"; findings M1-M3 fixed). Folded into the standing branches: knk-web-api `claude/road-navigation` `176b9d3`, knk-plugin
`claude/navigation-walkable-path` `c6a6d14`. **Next:** sections 4 (Phase 4 from "Availability" on, plus the `[~]` items)
and 5, together with the KNG-51 walkable-path checklist (`docs/reports/2026-10-02-navigation-walkable-chain.md`,
"Combined live checklist"), on that deployment. Then the trunk merge of the whole feature.
**2026-10-07:** Phase 4 + KNG-51 live test started — see "Phase 4 / KNG-51 live test (2026-10-07)": findings N1 (no
gates among the destinations) and N2 (walk paths cut off by the length cap) fixed in knk-plugin `b793b48` / `0a0f4a1`
and verified live; A5 (the 13 m wall case, Northern Gate) passed. **2026-10-08:** A3, A4, A6 passed; findings N3
(recorded road through the South Gate had no gate), N4 (a district made after the build was not avoided) and the
partial-path decision (A1) fixed in knk-plugin `d369ad4`/`f2baf4e`/`a4892db`, on top of a merge of every trunk.
Run 3 (same day): A1, A7, A8 confirmed live; findings N5 (false "arrived" at a partial route's end), N6 (a blocked
start edge could not be left) and N7 (walk trail hugging corners) fixed in knk-plugin `3561034`/`b6257a9`/`ff5edf09`.
Run 4 (same day): the rest of A-D run; N8-N12 fixed in knk-plugin `62cbc36`..`d24f6c1`; follow-ups KNG-73, KNG-74,
KNG-75; still open: C6 (siege), and re-checks of the run 4 fixes.
**Merged to the default branches 2026-10-08** (knk-plugin `main` `f9026cb`, knk-web-api `master` `4c570fa`, knk-web-app
`main` `b51eba0`) on the developer's go-ahead after run 5; work continues on the standing branches (C3, A8/A9 below).
**2026-10-09:** the follow-up fixes N10-N14 (runs 6-9: C3 and A8/A9) passed and are merged to knk-plugin `main` too
(the API and the web app did not change). Only C6 (siege) remains of the checklist.
**2026-10-09 (later):** rev. 7 Part A (the routing view) implemented on knk-plugin `claude/navigation-walkable-path`
`893e33da`, not live-tested - "Rev. 7 Part A — routing view" at the end of Findings (V1-V6).
**2026-10-09 (evening):** KNG-73, rev. 7 Part C and Part A step 1 live-tested (runs 1-3 under "Rev. 7 Part A —
routing view") and **merged to trunk** (API `6d160aa`, web app `e2ba784`, plugin `54878783`).
**2026-10-09 (late):** rev. 7 Part A step 2 (the N6/N10/N14 patches removed) live-tested (W1-W8) and merged to knk-plugin
`main` `723d21f4`.
**2026-10-09 (night):** KNG-104 (the navigator's domain cache refreshes) live-tested and merged to knk-plugin `main`
`1159ae5d`.
**2026-10-10:** KNG-108 (a height allowance in the walk length cap, tall buildings) on knk-plugin
`claude/dazzling-dijkstra-94leyd` `8e0a83d` live-tested: H1-H3 pass, H5 accepted; H4's shut-in box very close to a road
fails (N18, the KNG-75 step 1 start-leg rule, not KNG-108) - "KNG-108" in Findings. Not merged yet.
**Last updated:** 2026-10-10
**Sources:** the "Developer to-do" blocks of Phases 1, 3, 4 and 5 in `docs/specs/navigation/IMPLEMENTATION_PLAN.md`;
progress report `docs/reports/2026-09-27-road-navigation-chain.md`. If this file and a plan block disagree, the plan wins.

Tick boxes as you go; write the failing step and what you saw under **Findings** at the bottom.

## 0. Preparation (once, ~30 min)

Branch heads to test: knk-web-api `claude/road-navigation` `77e0a29`, knk-plugin `claude/road-navigation` `4e3f8af`,
knk-web-app `claude/road-navigation` `9dbb481`. Nothing is merged to trunk yet.

- [ ] Pull `claude/road-navigation` in all three repos. Keep trunk checkouts elsewhere (or use worktrees).
- [ ] **Plugin build:** `./gradlew build -x deployToDevServer`. Expect knk-core 1545, knk-api-client 184 (2 skipped),
      knk-paper 1074 (14 skipped), all green. Red here means stop and tell me.
- [ ] **Dev DB backup** (the migration adds six `road_*` tables and one profile row).
- [ ] **web-api:** `dotnet ef database update` on the branch; set `Security:PluginApiKey`; run the API.
- [ ] **Plugin config:** `navigation.enabled: true` (the bundled `config.yml` section has the DESIGN defaults) and the
      plugin's API key matches the API's `Security:PluginApiKey`.
- [ ] **Permissions:** yourself `knk.admin.road` (admin) and `knk.navigate` (default true; test once *without* it
      too). A second test account with neither, plus one with `knk.region.bypass` if you can.
- [ ] **web-app:** `CYPRESS_INSTALL_BINARY=0 npm install && npm start` (`npm ci` is broken on trunk).
- [ ] **Street form (dev DB step for Phase 5):** Forms → Street → builder → add last step "Road", one field on `Id`,
      label "Road", Integer, read-only, not required, `settingsJson` `{"displayPanel":"streetRoad"}`.
- [ ] **Dev server:** `./gradlew :knk-paper:dev`; check the log shows "Road navigation (admin side) initialized" and
      "Road navigation (/navigate) initialized", and no stack traces.
- [ ] **Test world needs:** one real town with several streets and named structures; a Location and a Town/District/
      Structure with a spawn Location; a **gate** on a road (ideally with an alternative route around it); a
      **tunnel or bridge** if one exists; a domain with `allowEntry=false` (create a throwaway one); a spot > 48 blocks
      from any road.

## 1. Phase 1 — API sanity (Swagger, ~5 min)

Full payloads are in the plan's "Phase 1 status → Developer to-do". Header `X-API-Key` for writes.

- [x] `GET api/road-profiles` lists *Default road*.
- [x] `PUT api/road-tiles/world/0/0/graph` (payload 1) → 200, `nodesCreated: 3`.
- [x] `GET api/road-tiles/world/0/0/graph` → 200 with `ETag: "1"`; again with `If-None-Match: "1"` → 304.
- [x] `PUT api/road-tiles/world/1/0/graph` (payload 2) → `stitchEdges: 1`; `GET api/road-network/meta?world=world`
      shows one component of 5 nodes.
- [x] `POST api/road-tiles/world/1/0/dirty` → `dirty: true`; `POST api/road-edges/search` with
      `{"filters":{"stale":"true"}}` lists that tile's edges.
- [x] `GET api/Streets/{id}` shows `edgeCount` / `totalLength`.
- [ ] **Delete these fake tiles before Phase 3** (or use a different world name) so they don't pollute the real network.
      **Blocked:** no API route exists to delete a road tile/node (only `PUT`/`DELETE api/road-edges/{id}`). Left the
      `world` x=0,z=0 and x=1,z=0 fake tiles in place; needs a direct dev-DB delete or Phase 3's real world to use a
      different name.

## 2. Phase 3 — build the real network (in game, ~45 min)

Run first: `/navigate` needs this network.

- [x] `/knk road status` → enabled.
- [x] **Survey three road types:** `/knk road survey start "Kardenna main street"`, walk 2-3 min (action bar samples
      climb only while walking on the ground), `/knk road survey stop` → proposal in chat → click **Save**. Repeat for a
      wilderness road and a trail (`survey start` without a name → `save <name>`).
      Did 3/4 surveys, works; the town has a lot of square/open plaza-like road areas and the surveyor already looked
      like it was producing rough proposals there (expected — surveys aren't meant to handle open plazas well).
- [x] `/knk road profile list` / `show <name>`; new profiles are class Road ×1.0 until you edit them (web app or
      `/knk road profile`).
- [x] `/knk road build radius 1500` around the town (include the tunnel/bridge) → action-bar progress, per-tile chat
      summary with clickable teleports.
      Works okay after tweaking `navigation.builder` config (junction-cluster-radius, ambiguous-reach, etc. — see
      Finding F below for the settings used).
- [x] `/knk road show` → coloured polylines, pillars at junctions, action-bar label when looking at an edge;
      `/knk road show all` on a bridge.
      Works after triage and manual cleanup: pruned duplicate junctions, locked the good ones, recorded stretches
      the builder missed, labelled roads/junctions. See the 2026-10-01 rebuild-persistence finding below — this
      cleanup does **not** survive a rebuild.
- [x] Name at least the places you will navigate to: `/knk road node name Market` on a junction.
- [x] `/knk road street "<street>" --continue` on an edge you stand on → "and N more".
- [x] Break a road block → within 30 s `/knk road tiles` lists the tile DIRTY; `/knk road build dirty` keeps names.
- [x] WorldEdit `//set` across a road → tile dirty.
- [x] `/knk road edge set here close` → overlay turns red; `open` again.
- [~] `/knk road reload`; restart the server mid-`build all` → the queue resumes and skips tiles built before.
      Resume-after-restart works, **but**: every duplicate junction/stale node pruned before the restart is back
      after the rebuild. No way yet to make manual cleanup (merges, locks, recorded edges) stick across a full
      rebuild of a tile. See Findings.

## 3. Phase 5 — web app (~10 min)

Full text in the plan's "Phase 5 status → Developer to-do".

- [x] "Roads" appears in the nav for `knk.admin.road`; `/admin/roads` loads world `world`: profiles, tiles, edges.
- [x] Stretches: "Unlabelled only" → Edit → pick a street → "Continue along the road" → Save → green notice with N more.
- [x] Create New Street from an edge; Rename opens the Street form.
- [x] Edit cost 0 → refused; cost 2 + Closed → row shows ×2 and Closed in red (and `/knk road show` turns it red
      after the next cache refresh or `/knk road reload`).
- [x] New profile with material suggestions (`DIRT_PATH`), town scope; duplicate name → API's 400 message; delete.
      **Finding (2026-10-01):** the delete button uses the browser's native `window.confirm()`
      (`RoadProfilesCard.tsx:152`) instead of the app's `FeedbackModal.tsx` component — inconsistent with the rest of
      the admin UI, should be swapped.
- [x] Street edit form shows the Road panel; an unsaved street shows the "save first" note.
- [x] Unknown world → empty tables, no error. Without the node: nav link hidden, page says "Staff only".
- [x] **Rename a street here** and confirm the new name shows up in `/navigate` messages within ~60 s (street names
      refresh every minute).

## 4. Phase 4 — `/navigate` (in game, ~45 min)

Use two accounts where noted. Watch the console for exceptions the whole time, and `/tps` at the end.

**Basics**
- [x] `/navigate` alone → "not navigating" plus usage. `/nav` works as an alias.
- [x] Tab completion: names one word at a time, `stop`, `type:name` forms for shared names (e.g. `town:Market` vs
      `district:Market`), `spawn` / `region` after a complete name.
- [x] Without `knk.navigate` → permission message. From the console → "only players".
- [x] Unknown name → "No place called…" plus clickable "Did you mean" suggestions. Ambiguous name → clickable
      `type:name` choices.

**Destinations** (each: "Navigating to X - N m. Follow the trail; [Stop]", gold trail ahead only *you* see, boss bar
"→ X · N m · ~T" with progress, action-bar arrow)
- [~] A Location by name and by `location:#id`.
      Works, **but** see "Phase 4/5 — live smoke test (2026-10-01)" in Findings: the direct-mode (< 48 block)
      straight trail cuts through terrain/obstacles in hilly, alley-dense areas, and doesn't recompute when the
      player moves away from the target until `/navigate` is re-run.
- [~] A Town → its spawn Location; the same Town with `region` → the route ends where the road enters the region.
      Same two bugs as the Location case above.
- [~] From *inside* that region → "You are already in X".
      **Does not work** — instead of the "already in" message, it draws a straight line to some point inside the
      region (the undesired line from the bug above).
- [~] A District and a Structure (Structure needs its Location via `locationId`).
      District has the same obstacle-ignoring straight-line bug, and the point it heads for inside the region looks
      arbitrary — not the domain's default Location and not the closest-to-the-player region point. Structure (via
      its Location) works much better: the real road is followed to within ~13 m of the destination, where the
      remaining leg is walkable but not a road (would need climbing a wall that was further away than that 13 m
      point) — ending the session there isn't acceptable when the target is a specific Location with no direct line
      of sight or walking line. See Findings for the proposed direction (closest walkable region point / last-mile
      pathfinding).
- [x] `street:<name>` → ends on the street; `node:<name>` → ends on the node.
- [x] A domain with neither Location nor region → "has no location and no region".
- [x] A place in another world → "is in another world".

**Guidance**
- [~] Walk the route: "In 12 m: Turn left onto …" chat lines once each; the boss bar label switches to the maneuver
      within 20 blocks; tunnel → "Go down into the tunnel", bridge → "Cross the bridge".
      Works well enough; did not encounter a tunnel or bridge during this session, so the maneuver text for those is
      still untested.
- [~] Arrival: chime + "You have arrived at X"; boss bar and trail disappear.
      Works, but tied to the Destinations findings above — arrival at an unintended point isn't really "arrival".
- [~] Leave the road for > 2 s → "You left the road - recalculating."; the trail follows the new route.
      The action-bar arrow and boss bar guidance kept working, but the "You left the road - recalculating." chat
      message did not appear when it should have — needs a check for a dropped/suppressed message path.
- [x] `/navigate` while navigating replaces the session; no-arg shows status with a clickable [Stop]; `/navigate stop`.

**Refusals and direct mode (DESIGN §6.2)**
- [x] Stand > 48 blocks from any road → "You're too far from a road - get within 48 blocks of one."
- [ ] Target > 48 blocks from any road → "X is too far from any road." — not run this session, accepted as spec'd.
- [~] Target within 48 blocks of you → straight trail, no road ("X is N m away"); arrival at the target.
      This is the direct-mode straight-line bug (see Destinations above) — the single highest-priority item to fix
      before continuing. In towns with height differences and small alleys, a 48-block straight line is not
      acceptable; it should keep following walkable paths right up to the destination.
- [x] Destination beyond the road's end but within 48 → routed, then a straight last leg (other colour, sparser).

**Blocked (2026-10-01):** everything from here down (Availability, Ending, Admin and events, Performance) could not
be meaningfully tested — the direct-mode/last-mile pathfinding bug makes most destinations unreliable to reach, and
the network can't be iterated on further until pruned junctions/endpoints stop reappearing on rebuild (Phase 3,
item 11). Fix both before resuming. See Findings.

**Availability and live changes (DESIGN §6.7)**
- [ ] Close a gate on the route (`/knk gate close`) → within ~2 s "The West Gate is closed - recalculating." and either a
      detour or "No open route to X - the West Gate is closed. Guiding you to the gate."
- [ ] Open the gate again → "A shorter route opened - following it now." (only if > 15 % shorter, at most every 10 s).
- [ ] Close a gate *silently* by a path that fires no event (e.g. siege override) and confirm the 2-second re-check
      still catches it.
- [ ] Pass-through gate → "Hint: right-click the West Gate to pass." and the route goes through it.
- [ ] Domain with `allowEntry=false` as the destination → "You may not enter X. Guiding you to its edge." and the
      route ends at the last edge outside; with `knk.region.bypass` the route goes in.
- [ ] Standing in a domain with `allowExit=false` → routes stay inside / say why.
- [ ] **Siege:** a locked gate in an active siege area counts as passable for a non-member (carried through, per plan
      D2), and joining a siege lobby ends navigation ("… you joined a siege"); `/navigate` is refused while in a lobby.
- [ ] Rebuild a tile mid-route (`/knk road build here`) → the session survives or ends with a clear message; no
      exception.

**Ending**
- [ ] Die → ended. `/tp`, `/spawn` or `/back` more than 16 blocks → ended; a short hop < 16 → still navigating.
- [ ] Change world → ended. Quit and rejoin → no leftover boss bar. Frozen player → refused.
- [ ] 30 minutes (`navigation.max-session-minutes`; lower it in config to test) → timeout message.

**Admin and events**
- [ ] `/knk road why <destination>` lists the route and every non-open verdict; `--as <player>` shows that player's
      route (try the account without the bypass); from the console without `--as` it asks for a player.
- [ ] `/knk cache refresh` reloads the destination catalogue; a Town created in the web app appears in tab completion
      within ~60 s.
- [ ] Optional: a throwaway listener for `NavigationStartEvent` / `NavigationRerouteEvent` / `NavigationArriveEvent` /
      `NavigationEndEvent` (or watch that cancelling Start refuses silently).

**Performance**
- [ ] Three or more players navigating at once: `/tps` stays healthy, no console warnings, trails only visible to
      their owner.
- [ ] Server restart while someone navigates → clean shutdown log, no boss bar stuck on rejoin.

## 5. Regression spot checks (KNG-17 merge and the extractions)

- [ ] `/spawn`, `/warp <town>`, `/warps` tab completion, `/tpa`, `/back` behave as before (teleport now shares
      `NamedTargets`, `DomainLocationResolver`, `BlockProbe`).
- [ ] Walking into a domain with `allowEntry=false` / out of `allowExit=false` still shows "You are not allowed to
      enter/leave X."; teleport into one is refused up front unless `knk.region.bypass`.
- [ ] Siege: start a match; gates lock and unlock; a non-member walks through a locked gate; nothing else changed.
- [ ] `/knk gate open|close|force`, gate destroy/repair, gate pass-through by right-click still work.

## 6. If something fails

Note: the exact step, what you typed, the chat/HUD text you saw, and the console stack trace if any. The likely
weak spots (unit-tested but never run on a server): thread hops, boss bar / particle rates, WorldGuard region shapes
on odd regions, and the per-session gate re-check with hundreds of gate doors. Every one of the 18 Phase 4 decisions
is reversible in the plan's status block.

## Findings

### Phase 1 — API sanity (2026-09-29): all pass

Ran the full checklist against knk-web-api `claude/road-navigation` `77e0a29` on the dev DB (migration + PluginApiKey
already applied). All six checks passed exactly as specced: `road-profiles` lists *Default road*; tile `0,0` PUT →
`nodesCreated: 3`; GET → `ETag: "1"` then `304` on `If-None-Match`; tile `1,0` PUT → `stitchEdges: 1` and
`road-network/meta` → one component of 5 nodes; `dirty` → `true` and `road-edges/search {"stale":"true"}` lists both
of that tile's edges; `Streets/{id}` → `edgeCount: 0`, `totalLength: 0` (expected, no labels yet).

**Gap found:** the last prep bullet ("delete these fake tiles before Phase 3") has no way to be done through the
API — there is no `DELETE` route for a road tile or road node (only `PUT`/`DELETE api/road-edges/{id}`). Left tiles
`world` `0,0` and `1,0` in place. If Phase 3 builds the real network under the world name `world`, this test data
will coexist with it; either add a tile/node delete route, or clean up with a direct dev-DB delete before relying on
`road-network/meta` counts.

### Phase 3 — build the real network (2026-09-29): blocked, not workable

1. `/knk road status` → enabled. Pass.
2. Surveys: did 3 of the 4 prescribed surveys (main street, wilderness road, trail), all completed and saved fine.
   The test town has a lot of square/open plaza-style road areas; the surveyor already visibly struggled to produce
   clean proposals there (rough centreline through an open area rather than a real road) — plausibly expected
   behaviour for a linear-survey tool on non-linear plazas, not necessarily a bug.
3. `/knk road profile list` / `show` → pass.
4. `/knk road build radius 1500`: many tiles logged `Tile X,X not built: no seeds: no domain Location, survey or
   admin seed in or near this tile`. Likely explanation: the town sits on an island with few roads/seeds around it,
   so tiles beyond the town have nothing to seed from. Needs triage — is a tile-with-no-seed skip the intended
   behaviour (D-something in the plan), or should build-radius pull seeds from farther away / from the town centre
   outward?
5. `/knk road show`: **failing, not usable as a base to fine-tune.** Way too many junctions and stale nodes; several
   town roads don't connect where they visibly should; some of the most obviously-a-road segments were not built at
   all. This isn't something to patch by hand in-game — points at a bug in tile stitching, junction detection, or
   the road-graph builder itself. Triaged on 2026-09-30, see "Phase 3 — rebuild attempts and triage" below.

**Net effect:** stopped Phase 3 here — the built network is not fine-tunable, so nothing downstream of it (naming
nodes, `/navigate` in Phase 4, web-app stretches in Phase 5 that depend on real edges) can be meaningfully tested
until the build quality issue is root-caused and fixed.

### Phase 3 — rebuild attempts and triage (2026-09-30)

Tuned `navigation.builder` and the profiles, then rebuilt around Cinix (`world_KNK-DEV`, tiles 1,-2 / 2,-2 / 2,-1 /
3,-1). Every tile failed to upload. Findings, in order of impact:

**A. Profiles flooded the road mask (trigger, data problem).** Tile 2,-2 went from 7,111 cells / 132 nodes (last good
build, 2026-09-29 18:25) to 231,647 cells / over 2,300 nodes, with `Cell cap reached; the mask is incomplete` on every
tile. A floor block is road when *any* enabled profile lists it as Surface, Edge or Accent, and it is ambiguous only
when *every* profile listing it says so (`ProfileSet`, DESIGN §5.1). The profiles contained:
- `GRASS_BLOCK` as a non-ambiguous Edge (profile *Cinix Keepstreet*): all grass terrain counted as road.
- Roof/building materials with ~0 % share kept as Accent (`OAK_STAIRS` 0.00/0.00, `POLISHED_DIORITE_STAIRS`,
  `STONE_SLAB`, `RED_TERRACOTTA`, `SPRUCE_LOG`).
- `STONE_BRICKS`, `COBBLESTONE`, `GRAVEL` marked ambiguous in some profiles but not in *Cinix rural road* / *Stonebrick
  bridge*, so they stayed non-ambiguous overall. Adding ambiguous flags in one profile has no effect while another
  profile lists the material as non-ambiguous.

Remedy (developer): remove `GRASS_BLOCK` and the near-zero accents, mark stone brick / cobblestone and their stair and
slab variants ambiguous in every profile, keep `DIRT` non-ambiguous (it is a road block ~95 % of the time here).
Roads made only of stone brick (bridge, Keepstreet stair house) then need `/knk road record`. "Cell cap reached" in a
tile summary is the early warning for a flooded mask.

Design questions raised: should a near-zero-share Accent still count as road? Should one profile's "non-ambiguous"
override every other profile? Should the survey refuse terrain materials (grass) as Edge?

**B. Bug: a Boundary node placed off the tile border (code, `SkeletonGraph`).** **→ Fixed on `claude/road-navigation`
2026-10-02:** knk-plugin `9f66fea` (a straddling plaza/cluster chain is extended to the node centre, both tiles cut on
the shared border; test `aPlazaStraddlingTheTileBorderGetsItsBoundaryNodeOnTheBorder`); a second cause — a Boundary node
taking a locked inner node's position — fixed by the developer in `6a8caa7`. Needs a live rebuild of tile 2,-2. Error:
`Boundary node 'n2347' at (1025, -530) is not on the tile border` (tile 2,-2 spans x 1024..1535). A plaza or
junction cluster is one node covering many spans; its position is one centre span. `traceChains` starts a chain at the
*member* span next to the road, while `cutAtTileBorder` decides inside/outside from the node's *centre*
(`nodeInside(chain.from)`). When such a node straddles the tile border with its centre outside, the chain's first span
is already inside, so `boundaryNode()` mints a Boundary node at that member span, which can be anywhere inside the
plaza/cluster. Larger `junction-cluster-radius` makes clusters wider and hits this more often (it first showed at
radius 6); the flooded mask (A) produced giant plazas that hit it at any radius. Fix direction: split multi-span nodes
at the tile border, or place the Boundary node at the chain's real border crossing; add a test with a plaza and a
cluster straddling a tile border.

Two attempted patches were tried and reverted, both uncommitted: (1) re-mint a Boundary only when a reused Endpoint is
off the border — wrong path, no effect; (2) snap every Boundary node to the nearest border line — turned the error into
`Two payload nodes share position (1024, 90, -564)` (several chains leaving one plaza snapped onto the same point) and
bent edge geometry. Both were based on wrong theories.

**C. Design issue: a plaza produces ~10 junctions plus stray edges.** **→ Fixed on `claude/road-navigation`
2026-10-02** (fix plan §5.5 item 5): knk-plugin `9f66fea` — plaza footprint grown by each core span's clearance plus
`navigation.builder.plaza-growth` (default 2); a junction next to a plaza joins it; golden fixture 8 junctions → 1.
Leftover two-arm junctions are joined into one edge (`075ae94`), leftover spurs can be pruned (`/knk road node prune`,
`9dccb58` + knk-web-api `c029186`). Needs a live rebuild of a problem plaza. Plazas are typically ~20 blocks wide here.
`collapsePlazas` only marks spans whose *own* local width (`2·dt − 1`) exceeds `widthMax`, which is the plaza's core;
the 3–4 block band along the edges stays ordinary road. The skeleton of an irregular plaza sends a branch toward every
corner, bump, lamp post, planter or step on its outline, and those branches fork in the edge band, outside the core,
so each fork becomes its own junction around the plaza. Obstacles inside the plaza (fountain, trees) make skeleton
loops, and `splitLoopsAndParallels` inserts a junction on each. `junction-cluster-radius` cannot absorb these into the
plaza: `clusterJunctions` never walks into a plaza node, so a large radius only merges the fake junctions with each
other (and raises the risk of B).
- Workaround: `min-spur-length` 10–12 prunes the edge-band branches (real dead ends shorter than that go too);
  `junction-cluster-radius` back to 4–5; clean leftovers by hand with `node merge` + `node lock`.
- Fix direction: make the plaza footprint the whole area within reach of its core (every mask span within `dt` of a
  plaza span) so all skeleton branches inside it belong to the plaza node, and let `clusterJunctions` merge
  candidates next to a plaza into it.

**D. Upload timeout on a huge tile.** *(Not addressed — not part of the §5.5 fix plan; open as of 2026-10-02.)* Tile 3,-1 (249,305 cells, 2,521 nodes, 3,858 edges) failed in the plugin with
`SocketTimeoutException`, but the API finished and committed it (`GET api/road-tiles` shows v1 built 20:03:05). A
client-side failure can therefore leave a stored graph; this one is junk from the flooded mask and must be rebuilt
once the profiles are fixed.

**E. Operational notes.** `navigation.builder` values in `config.yml` are read only in `onEnable` — a full restart is
needed, `/knk road reload` only refreshes the network cache. There is no command or API route to delete a road node
or a road tile (only `node merge`, `edge delete`; a deleted Detected edge returns on the next rebuild).
*Update 2026-10-02:* a dead end can now be pruned so it stays out of later builds — `/knk road node prune|unprune`
(knk-plugin `9dccb58`, knk-web-api `c029186`; deploy both together, an older plugin can't parse the `Pruned` kind).
There is still no route to delete a node or a tile, and builder settings still need a restart.

**F. Result after fixing the profiles (A).** With `junction-cluster-radius: 10`, `min-spur-length: 6`,
`ambiguous-reach: 2` and the cleaned profiles: a big improvement. Far fewer junctions and edges, and more real
roads are mapped. Some stray edges and junctions still need cleaning, and some endpoints remain (understandable ones).
Next: lower `junction-cluster-radius` and raise `min-spur-length` to 10–12. After further tuning and manual cleanup
the network looks good (end of session 2026-09-30); Phase 3's remaining checklist items and Phases 4/5 are still to
run.

Final `navigation.builder` settings used: `junction-cluster-radius: 5`, `min-spur-length: 12`, `ambiguous-reach: 2`
(other builder keys at their defaults: `tile-size: 512`, `tile-margin: 32`, `max-cells-per-tile: 250000`,
`snapshot-chunks-per-tick: 4`). The network was **not rebuilt** after the manual cleanup (duplicate junctions merged,
gaps between endpoints recorded). Expect on the next rebuild of those tiles: recorded edges and their end nodes stay;
node merges inside one tile hold only where the builder produces a single junction there again, otherwise the
duplicates come back and need merging again. Worth checking with one `/knk road build tile` before relying on it.

Manual cleanup lessons:
- `node merge` does not re-trace the road: every edge of the merged-away node gets its end point replaced by the kept
  node's position (`MergeNodesAsync`), so a merge across a wall or a tile seam draws a straight line through the wall,
  and the kept node is locked. Undo by rebuilding the merged-away node's tile (and its neighbour), then
  `node unlock`. Use merge only for two nodes of one junction a few blocks apart in open space.
- Two Boundary nodes that face each other across a seam but are further apart than the API's stitch rule (±1 block in
  x/z and y) stay unconnected; bridge them with `/knk road record` along the real road.
- Endpoint pairs < 5 blocks apart matched `ambiguous-reach: 2` (an ambiguous-only stretch longer than 2×reach cuts the
  road); raising it to 3 or recording the gap fixes them.

**G. `/knk road show` action-bar identification is unreliable (usability bug).** **→ Fixed on `claude/road-navigation`
2026-10-02:** knk-plugin `ae2f1e8` — the node whose pillar is closest to the view ray (≤ 1.5 blocks, up to the overlay
radius), else the first edge under the ray, else the `here` node marked "(here)". The requested `/knk road node info
here` was **not** added. Walking around and looking at
nodes often shows no id. Cause (`RoadOverlayRenderer.lookedAt` / `describeAt`): it is not a line-of-sight check. Once
per overlay tick (20 ticks) it takes the single point exactly `LOOK_DISTANCE` = 12 blocks along the view direction
and labels a node only if one is within 3 blocks (3D) of that point, else an edge within 4 blocks. A node nearer or
farther than ~12 blocks, or one you look down at from close by (the point then lies underground), is never labelled.
The `here` commands use yet another rule (nearest node within 6 blocks of the feet), so what the bar shows and what
`node name` / `node lock` act on can differ. Improve: pick the node closest to the view *ray* (e.g. within ~1.5 blocks
of it, up to the overlay radius), fall back to the nearest node at the feet, and consider a `/knk road node info`
(or clickable ids in chat) that lists the nearest nodes/edges with ids. Developer note: once you know the
12-block rule, aiming at plazas works fine; in tunnels it is impractical. Requested: `/knk road node info here`.
Side effect seen in test: aiming at a node pillar often shows `Edge #…`. When the 12-block point misses the node by
more than 3 blocks, the label falls back to the nearest edge within 4 blocks, and every node has edges ending at it.
The yellow gate-crossing marker is also drawn as a pillar but belongs to an edge, which adds to the confusion.

### Phase 4/5 — live smoke test (2026-10-01): blocked on direct-mode pathfinding and rebuild persistence

Ran Phase 5 (web app) in full and Phase 4 (`/navigate`) through the Refusals/direct-mode section, then stopped —
items 20 onward (Availability, Ending, Admin and events, Performance) are not meaningfully testable until the two
blockers below are fixed. Also re-ran Phase 3's restart/resume step and confirmed a gap already flagged as a risk in
Finding F.

*Cross-references added 2026-10-02 (walkable-path chain, link 1): each finding below names the commit on
`claude/road-navigation` that addresses it; the full verification is in `IMPLEMENTATION_PLAN.md` "§5.5 status".
Nothing is merged to trunk; every fix still needs the live re-test noted there.*

**1. Direct-mode straight line ignores terrain (DESIGN §6.2, the "off-road leg" hard 48-block limit).** **→ Not fixed
yet — split out as KNG-51** (design `docs/specs/navigation/LAST_MILE_PATHFINDING.md`, implemented by the walkable-path
chain on knk-plugin `claude/navigation-walkable-path`). Whenever the
player or the destination is within 48 blocks (straight-line, not walking distance), the trail and route go in a
dead-straight line to the target — through walls, down cliffs, across gaps. This reproduces on: Location destinations,
Town spawn, Town+`region`, and District/Structure region destinations. It's already called out as a known v1
limitation in the DESIGN doc and the Linear issue ("Direct straight-line mode only applies within 48 blocks of the
target... Pathing stays Phase 6"), but in practice, in a town with real height differences and small alleys, it reads
as broken rather than a minor rough edge — it should keep following a walkable path (not necessarily a road) right up
to the destination instead of cutting a straight line once within 48 blocks. Candidate direction: a local A* /
walkable-path fallback for the off-road leg(s), same as the last-mile case in finding 4 below — these two may share
one fix.

**2. Direct-mode route is never re-evaluated as the player moves.** **→ Fixed 2026-10-02** (§5.5 item 3): knk-plugin
`6a73945`, `NavigationService.recheckDirect` — "You're heading away from X - recalculating." Per DESIGN §6.2/§6.4 the straight leg is supposed
to be "re-drawn as the player moves" and the general re-route rule is "more than `reroute-distance` off the route for
`reroute-after-ticks` → recompute". In testing, once a session starts in or enters direct mode, walking *away* from
the destination does not trigger a recompute — the player has to run `/navigate` again to get an updated route/ETA.
Likely cause: the periodic re-route check only fires on lateral deviation from the current route polyline, not on the
remaining distance to the goal growing. Needs a periodic refresh (e.g. re-derive the direct-mode leg every
`trail-period-ticks` instead of only recomputing on deviation).

**3. "You are already in X" does not fire.** **→ Fixed 2026-10-02** (§5.5 item 4): knk-plugin `6a73945` — checked
first, with WorldGuard's own block containment (`RegionShapes.containsFeet`). Navigating to a Town with `region` while already standing inside that
region should say "You are already in X" (DESIGN §6.3) and stop; instead it computed a straight-line route to some
point inside the region. Needs a repro with a concrete town/region and a look at the "already inside" check in
`NavigationService`/region resolution — this may be the same code path as finding 1 if "already inside" falls through
to direct mode instead of returning early.

**4. District/Structure region destination picks an arbitrary point, not the closest walkable one.** **→ Region part
fixed 2026-10-02** (§5.5 item 2): knk-plugin `6a73945`, `NavigationService.regionGoals` — a region is routed along the
road to where it enters the region (nearest by road), else to the road's nearest approach plus a short last leg; fully
direct only within 8 blocks or when no road helps. The walkable last mile for a Location (the ~13 m climb) is **KNG-51**.
The optional "prefer the domain's default Location" setting was not added. For a District
(and likely other domains using the region-destination path), the route heads for some fixed point inside the
WorldGuard region rather than the domain's default Location *or* the point of the region closest to the player. Per
DESIGN §6.3 the intent is "closest point of a region"; this needs verifying against `RegionShape`/the multi-goal A*
goal selection — if goals are being generated but biased toward a corner (e.g. `getPoints()[0]` or min corner) rather
than genuinely nearest-to-player, that's the bug. Preferred fix (developer): default to the closest walkable region
point relative to the player; consider a per-domain or global setting to prefer "domain default Location" instead
where that reads better (e.g. a Town's spawn). For a Structure resolved via its own Location (not a region), the road
is followed correctly to within ~13 m of the destination, where the final leg is walkable but off-road and would
require climbing — stopping there isn't acceptable for a Location target with no direct sightline/walking line.
Candidate direction: a last-mile walkable-path search (A* over blocks, not just the road graph) for the final leg,
respecting the player's `AccessPolicy` (gates/domains) the same way the road router does. Likely shares an
implementation with finding 1's walkable off-road leg.

**5. "You left the road - recalculating." message missing.** **→ Explained 2026-10-02** (§5.5 item 3): the routed
message was never broken (regression test `aRoutedSessionStillSaysYouLeftTheRoad`, `6a73945`); direct mode had no
re-check at all and now has its own message (finding 2). The action-bar arrow and boss bar correctly kept
updating after leaving the road, but the chat message that should accompany it (DESIGN §6.7 live-changes style,
"The West Gate closed — recalculating.") never appeared for the road-departure case specifically. Needs a check for
whether that message path is implemented/wired at all versus just suppressed by a rate limit.

**6. Rebuild does not keep manually pruned/merged junctions pruned.** **→ Fixed in code 2026-10-02, residual cases
need a live check** (§5.5 items 5 and 6): plaza fragmentation `9f66fea`; locked nodes absorb rebuilt duplicates
(`ef556e2`, `navigation.builder.locked-node-reach` default 8); a recording locks the detected nodes it snaps to
(knk-web-api `8523ec8`); developer follow-ups `6a8caa7`, `9dccb58`/`c029186` (prune), `075ae94` (two-arm junctions).
Phase 3 item 11 (restart mid-build, then a full
rebuild) confirms the risk already written up in Finding F: duplicate junctions and stale nodes cleaned up by hand
(`node merge`, `node lock`, recorded edges) reappear after the tile is rebuilt from scratch. There is currently no way
to make manual cleanup stick across a rebuild. This blocks further Phase 3 iteration and should be fixed alongside
finding C (plaza junction fragmentation) — the right fix likely prevents the duplicates from being generated in the
first place (better plaza/cluster recognition) rather than only preserving today's manual edits.

**7. web-app: profile delete uses the browser's native `confirm()`.** **→ Fixed 2026-10-02** (§5.5 item 1):
knk-web-app `6414e18`, `FeedbackModal`; no other `window.confirm(` left in the road-admin tree. `RoadProfilesCard.tsx:152` calls
`window.confirm(...)` for the delete action instead of the app's existing `FeedbackModal.tsx` component used
elsewhere for destructive confirmations. Small UI consistency fix.

**Net effect:** stop Phase 4 live testing at "Refusals and direct mode". Fix findings 1/2 (direct-mode pathfinding and
re-evaluation) and 6 (rebuild persistence) before resuming Availability/Ending/Admin/Performance — most of those
checks depend on reaching a destination reliably and on a network that doesn't need re-cleaning after every rebuild.

**Fix plan:** see `docs/specs/navigation/IMPLEMENTATION_PLAN.md` §5.5 "Fix plan before resuming the live smoke test
(2026-10-01)" for the prioritized, scoped plan covering all of the above (the direct-mode/last-mile pathfinding
item was split into its own Linear issue, related to KNG-27).

### Fixes implemented (2026-10-02) — re-test before resuming Phase 4

Branch `claude/road-navigation-smoke-test-bugs-fagl4i` in knk-web-app, knk-web-api and knk-plugin (merge into
`claude/road-navigation` first; no migration). Details, decisions and test counts: plan §5.5 "5.5 status".

| Finding | Fix | Re-test |
|---|---|---|
| 7 (profile delete `confirm()`) | `FeedbackModal`; it was the only `window.confirm` in the road admin | §3 profile delete |
| 4 (region goal "arbitrary", straight through terrain) | Region destinations follow the road to where it enters the region; straight only when the region is within 8 blocks or nearer than any road | §4 District / Town `region` from 30-40 blocks with a road nearby; `/knk road why` |
| 3 ("already in X" missing) | Checked first, with WorldGuard's own containment (same as the region tracker) | §4 "From inside that region", cuboid + polygon, several heights |
| 2 + 5 (direct mode never re-checks; "left the road" missing) | Direct mode re-checks every 2 s: "You're heading away from X - recalculating."; the routed message was never broken (it was direct mode) | §4 walk away from a < 48-block Location; leave the road on a routed session |
| C (plaza = ~10 junctions) | Plaza footprint grows over its edge band (`navigation.builder.plaza-growth`, 2); junctions forking at a plaza's edge join it | §2 rebuild the Cinix plaza tiles |
| B (Boundary node off the tile border) | A plaza straddling the border is cut on the border in both tiles | §2 rebuild tiles 1,-2 / 2,-2 / 2,-1 / 3,-1 |
| 6 / F (manual cleanup lost on rebuild) | Locked nodes absorb rebuilt duplicates within `locked-node-reach` (8); recording an edge locks the nodes it snaps to | §2 merge + lock, record, rebuild twice |
| G (`/knk road show` labels) | Names the node pillar along the view ray at any distance, else the edge under it, else the node at your feet "(here)" | §2 `/knk road show` |
| 1 (direct line through terrain) | **Not fixed** — KNG-51 | — |

Not addressed (not bugs in the fix plan): A (profile data), D (client timeout on a 250 k-cell tile — rebuild it once
the profiles are clean), E (no tile/node delete route; builder config read only at start-up), the Phase 1 "delete the
fake tiles" gap, and the requested `/knk road node info here` command.

### Re-test of the fixes (2026-10-02)

- **§1 web app:** all three pass.
- **§2 build all:** tiles 1,-2 / 2,-1 / 3,-1 built with fewer plaza junctions. **Tile 2,-2 failed:** `Boundary node 'n70'
  at (1418, -520) is not on the tile border`. Root cause: locked junction #7 "Brink" sits 7 blocks inside the south
  border; the new locked-node reach (8) let the builder's border node take #7's id and position. **Fixed** in knk-plugin
  `6a8caa7` (a border node never takes a locked inner node). After rebuilding 2,-2, check Brink: if it is left without
  edges, `node unlock` it and rebuild, and name the new junction instead.
- **§2 cleanup:** spurs in a small, oddly shaped plaza come back on every rebuild. That plaza is probably narrower than
  the profiles' `widthMax`, so it is never detected as a plaza, and its spurs are longer than `min-spur-length` (12).
  Merging them into the junction is the wrong tool. **New:** `/knk road node prune [id]` / `unprune [id]` (below).
- **§2 merge across tiles:** merging a mid-road junction into one 15 blocks away in another tile left a second edge
  "spawning" on the road (a merge re-points edge ends without re-tracing). Undo: `node unlock` the kept node and
  rebuild both tiles; then prune the stub that makes the mid-road point a junction. Merge only two nodes of one
  junction, a few blocks apart, in open space, in one tile.
- **§2 recording:** edge #5293 (3589 → 3601) was saved, downloaded and drawn at once, but it lies on top of two
  earlier recordings of the same stretch (#5236 3582 → 3589, #5240 3589 → 3596) and recorded edges are drawn in
  their street colour, so nothing new was visible. Clean-up: keep one recording of that stretch
  (`/knk road edge delete <id>` for the others).

**Node prune** (branch `claude/road-node-prune` in knk-web-api `c029186` and knk-plugin `9dccb58`, on top of the fix
branch; **deploy both together** — an older plugin can't read the new node kind). `/knk road node prune [id]` (no id:
the nearest endpoint within 6 blocks) removes the dead end ending there and leaves a *Pruned* tombstone (a dark brown
pillar); every later build leaves the dead end nearest the tombstone (within `locked-node-reach`, 8) out, and a
junction left with two arms dissolves. Only endpoints; refused when a recorded edge ends there. `unprune [id]` deletes
the tombstone and the next build brings the dead end back. No migration.

Merged 2026-10-02: `claude/road-node-prune` into `claude/road-navigation-smoke-test-bugs-fagl4i`, and that into
`claude/road-navigation` (knk-web-api `c029186`, knk-web-app `6414e18`, knk-plugin `075ae94` after the two fixes
below). The prune branches and worktrees are removed.

- **Recordings drawn inside the road** (town road, bridge, land): the recorder stored `floor(y − ε) − 1`, one block
  below the floor block every other part of the network uses. **Fixed** in knk-plugin `8b6d678`: the recorder now uses
  the survey's floor rule (full block, slab, dirt path, the block under a carpet/snow layer; mid-air on a ladder: the
  block under the feet). **Recordings made before the fix stay a block too deep** (and so do the Anchor nodes created
  at their ends) — re-record them, or correct them in the database.
- **Junction #3615 in a straight road with two edges (#5286, #5287):** steps after spur pruning (loop/parallel split,
  tile-border cut, an arm merged into a locked node) can leave a two-arm junction. **Fixed** in knk-plugin `075ae94`:
  the builder joins such a junction's two edges into one, unless it is locked, joining would make a loop or a duplicate
  pair, or it had three or more edges last build. Rebuild tile 2,-1 and #3615 is gone.

### Re-test, part 2 (2026-10-03) — edge and junction prune

Rebuilding tile 2,-2 after unlocking Brink (#7): plaza junctions whose edges had all been deleted with
`/knk road edge delete` came back on every rebuild (a deleted detected edge is traced again — finding E). Config
experiment first: `plaza-growth: 4`, `min-spur-length: 15` helped a bit, not enough.

**New (2026-10-03):** knk-plugin `3f13c41` on `claude/navigation-walkable-path` and knk-web-api `6947e2a` on
`claude/road-navigation`, **deploy both together**, no migration:
- `/knk road edge prune <id|here>` removes a detected edge for good. It leaves a *PrunedEdge* tombstone (dark brown
  pillar, "pruned edge") on the middle of the edge, and every later build leaves out the chain passing within 3 blocks
  of it. Junctions and dead ends left with no edges go with it. A junction left with two arms is joined on the next
  build.
- `/knk road node prune <id>` on a junction lists its detected edges and prunes them all after **[Confirm]** (this cuts
  any road through it). With no id it still picks the nearest dead end first, then a junction. Recorded and stitch
  edges are never pruned; a named junction is refused.
- `/knk road node unprune [id]` works for both tombstone kinds; `edge delete` on a detected edge now points to `edge prune`.
- Re-test: prune a stub, a loop side and a whole fake plaza junction on 2,-2; rebuild the tile twice → they stay out;
  `unprune` one → it returns on the next build.

### After the reset (2026-10-04) — missing rural road, edges through the ground

Data wiped with `road-navigation-reset.sql`, 3 new surveys/profiles ("Cinix rural main" #7 unscoped, "Cinix town main"
#8 and "Cinix keep stairs" #9 scoped to town 5), tiles 2,-2 / 1,-2 / 2,-1 built 10:00-10:01. Analysed from the DB rows
and a read-only copy of region files `r.1.-2`/`r.2.-2`, replaying the builder's span/step/corner rules over the real
blocks. (The road tables were reset again at ~10:25, after the rows were saved.)

**H — "Cinix rural main" mostly missing (endpoints #3760 ↔ #3778): data, not a builder bug.**
- Not the ambiguous flag: rural main's Surface `GRAVEL` is unambiguous (only STONE_BRICKS, its stairs and
  CRACKED_STONE_BRICKS are flagged). Not the town scope (#7 has none). Not the seeds (22 Survey seeds, all on a span)
  or the cell cap.
- The trail itself is patchy: gravel/andesite/cobble/dirt with grass holes. **179 of 556 breadcrumbs stand on
  GRASS_BLOCK, in 116 stretches of 1-4 blocks** (the survey stats agree: 599 of 1661 centre cells are grass). A grass
  block is no road span, so each hole cuts the mask: replayed from the 22 seeds the road falls apart into 21 islands
  (largest 697 spans) and only seeded islands get built; 66 of 556 breadcrumbs lay within 4 blocks of an edge. The build
  summary's "survey coverage: N walked point(s) got no road" line is this.
- A generic gap rule does not fit: bridging 1-block holes still leaves 7 islands; 2-block bridging leaks into the
  meadow (1.5 k → 155 k spans).
- **Fix (admin, no code):** walk the trail with `/knk road record start` … `stop` (DESIGN §5.10, a Recorded edge that
  survives rebuilds; start and stop next to the built ends at #3760 / #3778 so they snap to those nodes), then
  `/knk road edge prune` the stray island edges along it. Or fill the grass holes in the trail with gravel and rebuild
  — the cleaner road for the builder, but 100+ spots.

**I — edges through the ground at a plaza junction: builder bug, fixed.**
- Every edge at plaza junction #3752 (1418, 48, -520) began with one straight segment of 18-24 blocks climbing 3-6
  (#5641, 5649, 5651, 5655, 5656 and #5642's last segment), through 8-20 solid blocks (the plaza floor, cobblestone
  stairs, stone bricks); the rest of their geometry was clean. Junction #3777 (964, 68, -544, tile 1,-2) the same: 32-41 blocks, up to
  9 of climb, up to 24 blocks buried. #5542 was gone before the analysis.
- Cause: a plaza (and a junction cluster) is one Junction at its core, while its chains start where its footprint ends —
  `plaza-growth: 4` and `junction-cluster-radius: 5` make that far — and `TileBuilder.polyline` closed the gap with one
  straight line, diagonally through the plaza's stairs and hill.
- **Fixed** on knk-plugin `claude/navigation-walkable-path` (not pushed): `89016e4` closes the chain onto its node along
  the mask (shortest walk over mask links; a node off the mask keeps the straight line); `4eb6aae` adds a build warning
  *"Edge runs through the ground / floats above the ground from here"* with a teleport for whatever is left; `09eed88`
  builder version 2 (stored on the tile, nothing compares it yet — rebuild by hand). Tests: TileBuilderTest +2;
  Gradle core 1636 / api-client 184 / paper 1133 green (was 1634 / 184 / 1133).
- **J — duplicates at Brink after the rebuild (later 2026-10-04): builder bug, fixed.** The road data was restored
  to its pre-reset state from the binlog (`db-backups/2026-10-04_road-network_pre-reset_restore.sql`); an earlier
  import of the 10-01 phpMyAdmin dump had left `road_nodes`/`road_edges` without keys (API: "Field 'Id' doesn't have a
  default value"), repaired with `2026-10-04_road-nodes-edges_restore-keys.sql`. The rebuild then drew 7-8 edges
  overlapping up Brink's east stairs: anchor #3588 at the stair foot lay inside Brink's plaza footprint and
  `SkeletonGraph.placeAnchors` let it take over the plaza junction 21 blocks away, so every plaza arm started at the
  anchor (yesterday's straight lines #5462-#5467 were the same bug). Fixed in knk-plugin `f04c004` (builder version
  3): an anchor takes over a node only within `nodeMatchDistance`, otherwise it gets its own node plus the footprint's
  exits within that reach. Replayed offline on the real blocks with the current tombstones/anchors/locks: Brink keeps
  its own arms; #10012 becomes the west meeting point. Left as is: the east stairs keep two lanes (Brink → #3588 and
  Brink → the eastern-place junction), because the skeleton forks high on the wide staircase.
- **K — designed plazas (rev. 5, 2026-10-04): new feature, not yet live-tested.** Instead of tuning `plaza-growth` and
  pruning fragments, mark the plazas: `/knk road node plaza <radius> [id]` makes a Junction or Anchor the centre of a
  plaza (locked); the next build makes every road block within the radius one junction exactly on that node, with an
  edge per exit that follows the road to the centre. `/knk road node move <id>` moves a node to where you stand (same
  tile); `unplaza [id]` clears a plaza. `navigation.builder.auto-plazas: false` turns the width guess off entirely.
  Needs the migration `AddRoadNodePlazaRadius` applied, knk-web-api `2edcb1f` and knk-plugin `38886df`. Steps: implementation plan §5.6.
- **Re-test:** deploy the jar (`./gradlew :knk-paper:dev`; API unchanged, `6947e2a`), rebuild 2,-2 and 1,-2 (and
  2,-1) → the edges at the plaza around (1418, 48, -520) and junction #3777 at (964, 68, -544) follow the stairs/ramps in `/knk road show`; read the summary for
  the new warnings and teleport to any.

### Build v202 analysed (2026-10-04 evening) — finding L

**Developer report.** After the migration and the deploy, tile 2,-2 was rebuilt (v202, builder 4, 15:48 UTC) with
designed plazas at Northern Gate Square #3587 and Merchants Square #3693 (radius 12):
- The west junction below Brink is gone. Edges #10069 (Brink → #3587) and #10074 (Brink → #3638 → Southern Gate) run
  side by side, 1 block apart, and split at about (1404, 45, -515).
- #3588 joins only Brink and the southern road. Merchants Square runs to Brink directly (#10075, beside #10068).
- A new junction #10028 has one edge, to #3693.
- Question: are the last 24 hours of changes and config tuning making things better?

**Method: offline replay.** The real `TileBuilder` ran on copies of region files `r.{0..3}.{-3..0}`, extracted with the
server's own `CompactSurfaceGrid`/`SpanExtractor`. The builder inputs (profiles, seeds, breadcrumbs, Domain Locations,
neighbour Boundary nodes, the tile's nodes, edges and tombstones) were exported read-only from the dev DB, with the
live builder config. The replay reproduced v202 exactly: 28 nodes, 25 edges, the same geometry and warnings. Variants
then isolated the cause.

**L1 — cause: junction clustering pulled a road fork 20 blocks away into Brink.** Data:
- With all 27 tombstones left out, the Brink topology is identical. The tombstones only remove 19 nodes and 23 edges of
  spurs and loops elsewhere, so **they are not the cause**.
- A raw build (no tombstones, locks, anchors, plazas or previous graph) forks the same way. So does a designed Brink
  plaza (radius 12) with `auto-plazas: false`.
- With `junction-cluster-radius: 3` instead of the live 5, the west junction comes back at (1395, 45, -514), and #3588
  gets Brink, Merchants and the southern road. That is the intended graph.
- Mechanism: junction candidates cluster by single linkage. On Brink's wide stairs a chain of forks, each within 5 steps
  of the next, made one cluster over 20+ blocks. A cluster with any member near a plaza joined the plaza as a whole. So
  the west fork became part of Brink, and its two roads became two Brink edges that the mask closing (`89016e4`) draws
  side by side. The east stairs did the same.
- No single radius fixes it. Radius 3 doubles the junctions on tiles 1,-2 (12 → 24) and 2,-1 (5 → 10). Strict
  (complete-linkage) clustering fixes Brink but gives tile 1,-2 43 junctions.
- Yesterday's "hub #3588" was bug J: the anchor took over Brink's plaza 21 blocks away. Its arms were straight lines
  through the ground (#5462-#5467, #5495, and a 42-block leg of #5478). The I/J fixes made the edges follow the road,
  which made the hidden duplicate arms visible.

**Fixes** on knk-plugin `claude/navigation-walkable-path` (not pushed), builder version 5:

| Commit | Change |
|---|---|
| `4bc6946` | A plaza junction is never dissolved or turned into an Endpoint (a plaza with one or two exits is still a place; Brink's other arms are in tile 2,-1). |
| `8c9cb7e` | Only the members of a junction cluster that fork at a plaza's edge join the plaza. The rest form their own junction(s). |
| `19bf4b1` | A thin loop around an obstacle (both sides within 3 blocks the whole way) collapses into one lane. This removes the Northern Gate pair #10026/#10027 and a loop beside Brink. Ring roads and blocks of houses are still split. |
| `2672558` | A non-plaza junction left with one arm is emitted as an Endpoint (a guard). |
| `8fe661a` | **Correction report.** The build notes, per tombstone, anchor and designed plaza, what it did. A prune that matches nothing becomes the warning "Prune matched nothing (stale; unprune it) (node N)" with a teleport. The summary gets a line "corrections: N prune(s) (U used, S stale), A anchor(s), P designed plaza(s)". |
| `5d9a5e9` | Builder version 5. |

Gradle: core 1646, api-client 185, paper 1137, all green.

**Replay with builder 5 on today's data:**

| Tile | Builder 4 (live) | Builder 5 |
|---|---|---|
| 2,-2 | 28 nodes | 29 nodes, 9 junctions |
| 1,-2 | 14 nodes | 7 nodes |
| 2,-1 | 25 nodes | 20 nodes |

In tile 2,-2 at Brink:
- West junction at (1395, 45, -514): Northern Gate #3587 (78.6 m), Brink (26.4 m), and the Southern Gate road via #3638.
- Brink → #3588 (24.2 m).
- #3588: Brink, Merchants #3693 (51.5 m), and the southern road via #3639.
- The Northern Gate loop is gone.

Side effect at the keep top: the 13-block dead end towards (1400, 82, -506) is now pruned as a spur
(`min-spur-length: 15`). Its tile 2,-1 half (#3527 → #3543, edge #5154) then ends at a Boundary with no partner.

**L2 — #10028 is the rest of Merchants Square, not a broken junction.**
- #3693 stands at the square's corner (1441, 42, -563). The square's middle is near (1433, 42, -556).
- The radius-12 circle misses the far side, and the automatic plaza rule makes that part a separate plaza with one exit.
- Data fix: stand in the middle and run `/knk road node move 3693`, or run `/knk road node plaza 16 3693`.

**L3 — stale tombstones (builder 5, today's data):**
- Tile 2,-2: 10 of 27 match nothing (#3567, #3629, #3691, #3697, #3712, #3713, #3718, #3719, #3722, #3728).
- Tile 2,-1: 3 of 4 match nothing (#3612, #3613, #3614).
- #3712/#3713 hid the Northern Gate loop that the thin-loop rule now removes on its own.
- One far match to check: #3726 "left out the dead end 6.8 blocks away".

**Re-test (developer):**
1. Build and deploy the jar (a plain `./gradlew build --offline` deploys to the dev server), then restart.
2. Rebuild 2,-2, then 2,-1 and 1,-2.
3. Read the summary's "corrections:" line. Run `/knk road node unprune <id>` for every stale prune warning (they match
   nothing, so removing them is safe), then rebuild.
4. `/knk road show` at Brink: one west junction, #3588 as the meeting point, no parallel lanes on the stairs, no
   Northern Gate loop.
5. Move #3693 to the square's middle (or radius 16) and rebuild: #10028 should be gone.
6. Keep top: if the dead end towards (1400, 82, -506) is a real path, record it (`/knk road record`).

Keep `junction-cluster-radius: 5`; with the new rule it no longer swallows distant forks. A designed plaza on Brink is
optional now.

### Curated tiles (rev. 6 Part B) — live re-test (passed 2026-10-05)

Plan §5.7. **Prerequisites:**
- The finding L re-test above is done with the builder-5 jar.
- `road_tiles` is backed up.
- Migration `AddRoadCuratedTiles` is applied, with a go-ahead.
- API and plugin from `claude/road-curated-tiles-nsrorb` are deployed.

Use the build with `--offline -x deployToDevServer` and copy the jar yourself, or `./gradlew :knk-paper:dev`.

- [ ] **State after the migration.** `/knk road tiles` shows 2,-2 and 2,-1 as `curated` (they hold admin data) and
      "with builder 5". A tile without admin data (1,-2 today) is not curated.
- [ ] **No change, no proposal.** `/knk road build tile 2 -2` without changing anything. The summary says "no changes
      against the curated graph" (or lists a few items; note which and why). Nothing in the graph changes.
- [ ] **A config change becomes a proposal.** Change one builder value that changes Brink: for example
      `junction-cluster-radius: 3`, then restart (the builder config is read at start). Run `/knk road build tile 2 -2`.
      - The summary says "is curated - rebuilt … as a proposal of N change(s)", with [review] / [accept all] /
        [reject all] and the first items with teleports.
      - `/knk road show` draws the items: added green, removed red, changed/moved yellow.
      - Looking at one shows "Proposal 2,-2 · 3 added edge …" in the action bar.
      - The graph itself is unchanged: `/navigate` routes as before.
- [ ] **Accept some.** `/knk road proposal accept <n>` (or a kind: `added`). Only those items change in
      `/knk road show`; the rest stay pending under the same numbers (`/knk road proposal`).
- [ ] **Reject some.**
      - Rejecting a "removed edge" item keeps the edge: it shows as confirmed, its ends are locked.
      - Rejecting an "added" item puts it on the rejected list (`/knk road proposal rejected`).
      - Rebuild the tile: neither comes back.
      - `/knk road proposal unreject 1` and `/knk road edge unconfirm <id>` bring them back on the next rebuild.
- [ ] **Finish the review.** When the last item is accepted or rejected, the message says "it now counts as built with
      vN". `/knk road tiles` shows the new builder version and no DIRTY.
- [ ] **Edit, then accept an old item.** Make a proposal; move or prune something one of its items touches; then accept
      that item. It is skipped with a reason ("… was changed since"), and your edit stays.
- [ ] **Uncurate is one-shot.** `/knk road tile uncurate` on 1,-2, rebuild it: the build writes directly (normal
      summary), and `/knk road tiles` shows it curated again.
- [ ] **Kill switch.** `navigation.builder.curated-tiles: false`, restart, rebuild 2,-2: a direct upload, as before
      rev. 6. Set it back to `true`.
- [ ] **Restart.** Make a proposal, restart the server, `/knk road proposal`: it is still there (stored in the API).

#### Re-test run 1 (2026-10-05, developer) — steps through 19

- **Parts 1-3:** finding L re-test passed. West junction #10031 at (1395, 45, -514) has edges to Brink (#10087),
  Northern Gate #3587 (#10089) and Southern Gate #3638 (#10097). #3588 has Merchants (#10093) and the south road
  (#5385). No parallel lanes. #3693 was moved to the middle of the square, and the tile rebuilt. Stale prunes were
  unpruned. Backup taken (with `--set-gtid-purged=OFF`). The migration curated 2,-2 and 2,-1; 1,-2 and 3,-1 stayed
  Detected. Open warnings, not blocking:
  - 2,-2: "Edge runs through the ground" at (1122, 66, -553), and a new stale prune #10044 at (1384, 43, -579).
  - 2,-1: "Seed has no road span within reach" at (1418, 42, -174).
- **Finding M1 — domain noise.** Step 14 (an unchanged rebuild) proposed 4 "domains [5, 8] → [5]" changes. Domain ids
  are looked up from the WorldGuard regions through a cache that can miss a region at build time.
  **Fixed in knk-plugin `fa8fcb5`:** a changed edge compares `regionIds` (what the router reads), not `domainIds`.
- **Finding M2 — no clear undo, confusing numbers.** A rejected removal had no undo under `proposal`; only
  `/knk road edge unconfirm` existed. "rejected 1 item(s) (9)" printed the item number, but `unreject` wanted the
  position in the rejected list. **Fixed in `fa8fcb5`:**
  - Items read "item 3: …". Rejected entries read "R1: …", removals included, and record the nodes their rejection
    locked.
  - `/knk road proposal unreject R1` (alias `unconfirm`) undoes any rejection: it unconfirms the edge and unlocks
    exactly those nodes, or stops hiding the change.
  - Messages say "rejected item 9 → R1" and "accepted item 6 - applied to the road graph".
- **Step 19 note.** Item 6 (edge #10089, profile #1 → #3) was **accepted**, not confirmed. An accept has no undo;
  revert it by hand with `/knk road edge set 10089 profile 1`. A later rebuild proposes #1 → #3 again, which can then
  be rejected.

#### Re-test run 2 (2026-10-05, developer) — steps 14-23

- With knk-plugin `fa8fcb5`: step 14 (radius 5) gave "no changes". Step 15 (radius 3) proposed 7 real changes and no
  domain noise.
- A fresh backup that includes `road_tile_proposals` was taken first, so steps 17-21 can be undone by restoring it.
- Steps 17-22 passed: accept, reject (R1/R2, kept and hidden), unreject R1 (proposed again on rebuild), the later
  edit winning (skipped item), finishing a review, and surviving a restart. The "(locked)" overlay label in 18.3 was
  not found in game, but was accepted.
- **Finding M3 — stale `/knk road tiles`.** Step 23: after uncurate and a direct build, 1,-2 was Curated in the
  database, but the list still showed it uncurated. The cached tile list was never refreshed after a build.
  **Fixed in knk-plugin `c6a6d14`:** a build upload refreshes the tile list, and `/knk road tiles` fetches a fresh one
  before printing.

#### Re-test run 3 (2026-10-05, developer) — steps 24 and the restore: passed

- Step 24 (kill switch): with `curated-tiles: false`, a direct upload as before rev. 6.
- Restored the curated backup with `mysql … -e "source …"`. 2,-2 and 2,-1 are Curated again; 1,-2 and 3,-1 are
  Detected. A rebuild of 2,-2 proposes nothing, and no proposals are pending.
- **Result:** curated tiles pass the live re-test. Folded into knk-web-api `claude/road-navigation` (`176b9d3`) and
  knk-plugin `claude/navigation-walkable-path` (`c6a6d14`) by fast-forward.

### Phase 4 / KNG-51 live test (2026-10-07)

Deployment under test: knk-web-api `claude/road-navigation` `176b9d3`, knk-plugin `claude/navigation-walkable-path`
`c6a6d14` (then the fixes below). Checklist: handoff `docs/ai-agents/handoffs/2026-10-07-navigation-live-test-debug.md`
("Remaining checklist": A = KNG-51 walk paths, B = KNG-27 fix leftovers, C = Phase 4, D = regressions).

**Before the debug session (developer):** prep done (`navigation.walk` in the server config); A1 skipped (no
unreachable destination available); A2 (kill switch) accepted; A3 `/nav Northern Gate Square` from The Keep followed
the roads (routed mode, so no walk-path test); A4 reported working, but only meaningful in direct mode. A5 and the
walk-path check were blocked by N1 and N2.

- **Finding N1 — no Structures among the `/navigate` destinations.** All four Structures in the dev DB are gates
  (`gate_structures` rows 11-14, Keep Stair House included). `POST /api/Domains/search` reports them as
  `domainType: "GateStructure"`, and `NavTarget.Type.ofDomainType` only knew town/district/structure, so the catalogue
  dropped them. Separately, `structure:` + Tab completed nothing: the `type:name` form was offered only for names two
  items share.
  **Fixed in knk-plugin `b793b48`** (developer decision: gates are Structures, and also answer to their own word and a
  nickname): a gate is `structure:Keep Gate`, `gatestructure:Keep Gate` or `gate:Keep Gate`. `type:` + Tab lists every
  item of that type or alias (`structure:` → `structure:Keep`, then `Gate`); teleport's completion shares this.
  Gates are located through `/api/Structures/{id}`, which returns gates (checked live). A shared, possibly
  configurable nickname table for `/warp` as well is backlog item 10 (`docs/backlog/QOL_BUGFIX_BACKLOG.md`).
- **Finding N2 — direct mode kept the straight line.** `/nav Merchant Square` (Location 8, (1430, 43, -553)) from
  (1425.5, 49, -526.6), 27 m away: "walk paths" went from `requested 0 … budget 0` to `requested 1, budget 1`
  (15 chunks captured, 1814 µs each). So capture worked and the search gave up. An offline replay of the server's
  capture and search on a copy of the region files (`WalkReplayTest`, knk-plugin `tools/road-replay/README.md`,
  "Walk path replay") gave `FALLBACK (length cap, 1701 expansions)`. The cap was min(96, 1.75 × 27.5) = 48, and the
  only walkable way round the building is 67.7 blocks (east out of the courtyard, down x = 1440, west into the
  square), found in 863 expansions without the cap.
  **Fixed in knk-plugin `0a0f4a1`** (developer decision): the cap is now min(`max-length`, max(1.75 × d,
  d + `detour-allowance`)), with `navigation.walk.detour-allowance: 48` (0 = the old rule). The replay finds the
  67.7-block path with the new defaults. The server config needs no change (a missing key means 48).

**Deploy for the rest of the checklist:** knk-plugin `claude/navigation-walkable-path` `831ac4a` (includes both fixes;
`./gradlew :knk-paper:dev`). The API is unchanged.

**After the fixes (developer, knk-plugin `831ac4a`):**
- N1 verified: `/nav structure:` + Tab lists the Structures; `/nav gate:Keep Gate` works.
- N2 verified: `/nav Merchant Square` from the same spot follows the way round the building; "found" goes up.
- **A5 passed:** the 2026-10-01 "13 m wall" case was the Northern Gate. The last stretch after the road's end takes
  exactly the path the developer expected.
- **A1 (decision §11-5):** the developer **prefers a partial path** over the straight line, but had no unreachable
  destination to test with. Partial paths are not implemented (v1 returns no partial path), so this reopens §11-5;
  see the spec. Tip for the test: `/navigate <x> <y> <z>` to a spot inside a sealed room or on an unreachable roof.
- Next: A3/A4 in direct mode, A6-A14, B, C, D.

**Run 2 (2026-10-08, developer, knk-plugin `831ac4a`):**
- **A1:** `/nav 1420 104 -503` → "No place called …". `/navigate` has no coordinate form, by design (DESIGN §6.1:
  nothing asks for coordinates); the tip in this guide was wrong. Decision: **implement partial paths**
  (LAST_MILE_PATHFINDING §11-5) — **done in knk-plugin `d369ad4`**. Still to test with an unreachable destination,
  for example a Location (web app) on a roof or in a closed room.
- **A3, A4:** pass. **A6:** passes as far as could be judged.
- **Finding N3 — a closed gate is ignored (A7).** From (1437, 45, -444), `/nav Merchant Square` with the South Gate
  closed followed the road through the gate, with no message. The road through the gate is **edge 10139, a recorded
  stretch**: it carries the gate's region (`gate_2000131`) but `GateDoorIdsJson = []`. `/knk road record stop`
  uploaded recordings with no gate doors (only the build tags them), so `GateAvailability` never saw door 13. Only
  10139 crosses a gate among the three recorded edges.
  **Fixed:** knk-plugin `a4892db` (a recording stores the gate doors its walked points pass) and `f2baf4e` (live tags,
  below, also cover the existing edge without a database write).
- **Finding N4 — a closed district is routed through (A8).** District 16 "Navigation Test" (`domain_16`,
  AllowEntry/AllowExit false) was created at 16:32 and is on **no** edge: routes know a domain only from the region
  ids stored on each edge at build or record time. (Walk paths in direct mode ask WorldGuard live and would respect
  it.) The other half of the report — being let into a region and then told a rule blocks the way out — is the
  KNG-55/56 bypass, now merged into the standing branches with trunk.
  **Fixed in knk-plugin `f2baf4e`** (developer decision: live tags): the plugin re-tags every edge from the world
  (WorldGuard regions every 2 blocks at feet level, gate-door cells every half block) when a world's network changes
  and every minute, within 200 lookups per tick, and the router uses the stored tags plus these. A change re-checks
  the active routes. `/knk road status` has a "live tags" line (edges with extra tags, regions and gate doors added).

**Branches updated from trunk (2026-10-08):** knk-plugin `a823934` (conflicts in `WorldGuardRegionTracker`,
`SimpleRegionTransitionService`, `plugin.yml`, two teleport tests; navigation now uses the same `knk.region.bypass`
predicate as KNG-56's `DomainAccessService`), knk-web-api `fa234f7` (no conflicts; snapshot consistent), knk-web-app
`48120ed` (no conflicts), knk-workspace `02628b2`. Tests after the merge: Gradle core 1739 / api-client 206 / paper
1289 green. web-api 9 failures, all already failing on master (8, time-dependent currency/activity tests and
FormWizard path tests) or on the branch before the merge (`RoadNetworkServiceTests.Validation_GeometryFarFromItsNode`).
web-app 6 failing suites, all already failing on main (5) or on the branch before the merge
(`RoadsAdminPage › deletes a profile after confirmation`).

**Run 3 (2026-10-08, developer, knk-plugin `a4892db`, API `fa234f7`):**
- **A1 works** (partial path to the closest reachable spot, then a straight line). Remark: the walk trail rounds corners
  so tightly that it sometimes seems to stop → **finding N7**.
- **A7 works** (the closed South Gate is seen: "No open route to Merchant Square - the South Gate is closed. Guiding
  you to the gate."), but the messages are wrong → **finding N5**:
  - Standing ~6 blocks from the closed gate: start message, "No open route", then at once "You have arrived at Merchant
    Square".
  - From ~30 blocks away on the bridge: the trail led to the gate; ~15 blocks on, "A shorter route opened" with a trail
    off the bridge onto the ice, then at once "You have arrived at Merchant Square" while still on the bridge. (The only
    other way is a drop onto the frozen lake and the harbour docks, not a road.)
- **A8:** standing in front of district 16, `/nav` said "You have arrived" at once, although a ~200-block road detour
  exists (the way through the district is ~30) → **findings N5 and N6**.
- **Finding N5 — a partial route's end counted as arrival.** `NavigationSession` gave `ArrivedEffect` within
  arrive-distance of *any* route's end, partial ones included, so the runtime said "You have arrived at <destination>"
  (or started the last off-road leg towards the target). Also, while a route was partial every improvement re-check
  adopted whatever came back, so the same partial route returned as "A shorter route opened" (the live tags' re-check
  every minute triggers this); and the trail drew a straight leg from the gate on to the target (across the ice).
  **Fixed in knk-plugin `3561034`:** the end of a partial route says once "End of the open route to X: <reason>. The
  route continues when it opens - /navigate stop to end." and keeps guiding; only a full route replaces a partial one
  ("The way to X is open again - following it now."); no straight leg after a partial route.
- **Finding N6 — standing on a blocked edge.** In both cases the player stood on the blocked edge itself (edge 10139
  through the South Gate; the road into district 16). The router never left a blocked start edge (Phase 2d decision),
  so the partial route was empty - hence the instant "arrived" - and the detour back along the road was never found.
  **Fixed in knk-plugin `b6257a9`:** each part of the start edge, from the player to a node, is tagged from the world
  (regions, gate doors) and checked on its own; the router walks the open side (`RouteRequest.StartSides`), the
  explainer and the re-check honour it. In A8 the route now goes back and takes the detour; in front of the South Gate
  the result is "End of the open route ...: the South Gate is closed".
- **Finding N7 — the walk trail hugs corners.** The search minimised length only, so paths ran along walls and cut
  diagonally past corner blocks; the trail then vanished behind the corner. **Fixed in knk-plugin `ff5edf09`:**
  `navigation.walk.wall-cost: 1.0` - a step beside a wall (8 neighbours, feet or head height) costs one block extra.
  Replay of the Merchant Square leg: one block off the walls, 72.7 blocks (was 67.7), within the cap.

**Deploy for run 4:** knk-plugin `claude/navigation-walkable-path` `ff5edf09` (API unchanged, `fa234f7`).

**Run 4 (2026-10-08, developer, knk-plugin `ff5edf09`):** N5, N6, N7 confirmed. A9 with interact rights, A10, A11,
A14 pass; A12, A13 accepted. B3 passes; B4 accepted. C1.1, C1.5, C2, C8, C9, C10, C11 pass; C5, C7 accepted;
C3 passes apart from N10. D1, D3, D4 pass. **C6 (siege) not run yet** - to do later: a locked gate is passable for
non-members, joining a lobby ends navigation, `/navigate` is refused in a lobby.
- **Finding N8 — a blocked walk path fell back to the straight line (A8, A9).** When regions, closed doors or gates
  leave no walkable way, direct mode drew the straight line through them. The developer wants it said instead,
  "conventional" on purpose (secret passages). **Fixed in knk-plugin `f1d0ad2`:** a search that ran and found no way
  says "No conventional path to X found." once per leg and draws no straight line - the partial path when there is
  one, else no trail. A search that could not run (chunks not loaded, an error) keeps the straight line.
- **B1, B2, C1.2-C1.4 - spawn vs region.** The "weird corner" of B1 and the district spawn of B2 are the default
  mode: a domain without `spawn`/`region` goes to its spawn Location; `region` goes to the closest point of the region
  along the cheapest road route (works, C1.4). The developer wants the default configurable per domain type with
  per-domain overrides, in the web app: **KNG-73**. **Finding N9 — "already in" only in region mode (B2).** Standing in
  Merchant's District, `/nav Merchant's District` guided to its spawn. **Fixed in knk-plugin `e3f34ea`:** without
  `spawn`, being in the domain's region is "You are already in X"; with `spawn` the spawn point stays the target.
- **Finding N10 — a gate behind the player blocked the route (C3).** Through the gate, still near it on the
  destination's side, the gate closing (or `/knk gate open` animating it - OPENING counts as blocked) gave "blocked
  by the closed gate". The re-check judged every step, also the ones already walked. **Fixed in knk-plugin `eed5d03`:**
  steps behind the player are skipped; on the current step only the stretch ahead counts.
- **Finding N11 — no pass-through for the developer (C4).** No hint, and the route stopped at the gate.
  `GateAvailability` required the door's AllowPassThrough on top of the right-click rule, but `knk.gate.admin` passes
  any door (it "bypasses AllowPassThrough"). And the gate rules read only Bukkit permissions, not KnK's model (ops,
  API grants with wildcards). **Fixed in knk-plugin `62cbc36` (+ test `91abc1b`):** the route follows the right-click
  rule; nodes are checked with Bukkit's or KnK's permissions. Who passes: a gate admin (`knk.gate.admin`, ops by
  default) any door; anyone else a door with AllowPassThrough and `knk.gate.passthrough.use`.
- **Finding N12 — "No road connects you to X" 15 blocks from a road.** The snapper took the nearest edge; the dev
  network has short stretches the build left on their own (components of 2-5 nodes near town, e.g. component 2601 at
  x 1530-1552, z -434..-412), so the start was in no goal's component. **Fixed in knk-plugin `d24f6c1`:** the start is
  re-snapped to a road that connects to a goal within the snap distance (or a point target to the start's network).
- **D2:** works; the refusal message should also go to chat, it fights the navigation arrow in the action bar:
  **KNG-74**.
- **Off-road destinations further than 48 blocks** ("X is too far from any road", also when standing on a road): the
  destination must be within `max-snap-distance` (48) of a road, and a target within 48 blocks of the player is
  direct mode only. Combining road + walk legs (a walk leg from the player to the road too) is feasible in steps:
  **KNG-75**.

**Deploy for run 5:** knk-plugin `claude/navigation-walkable-path` `d24f6c1` (API unchanged, `fa234f7`).

**Run 5 (2026-10-08, developer, knk-plugin `d24f6c1`):** B2 (N9), C4 (N11) and N12 confirmed; C6 later.
- **C3 still fails (N10 follow-up).** "It still seems to use the original nav's starting point to check the gate's
  state." Cause: the re-check judged a step by its whole edge unless the player had already moved along it. A route
  that starts in the middle of edge 10139 on the town side of the South Gate only walks from the player to the town
  node, but the step's edge carries the gate door (door 13: x 1426-1428, z -454..-452, y 45-48; the edge runs
  (1418,-463) → (1451,-429) through it), so a closing gate blocked it. **Fixed on the standing branch, knk-plugin
  `a8ec1ec`:** every blocked step is checked on the part it walks (from the player or its entry to its exit).
- **A8/A9 - a road route exists.** The test target was within 48 blocks, so direct mode searched only a walk path
  (bounded by the detour allowance and 96 blocks) and never the road network, although walking back and round by road
  reaches it (**finding N13**). **Fixed on the standing branch, knk-plugin `758dbc5`:** when the walk search finds no
  way, the router is asked once; a road route turns it into a routed navigation ("No walkable way straight to X -
  following the roads instead.") with a walk path for the last leg; without one, "No conventional path".

**Deploy for run 6 (re-check C3, A8/A9):** knk-plugin `claude/navigation-walkable-path` `758dbc5` (API unchanged).
These two fixes are not on trunk yet.

**Run 6 (2026-10-09, developer):** "C3 and A8/A9 show no improvement". The server log shows that the tests from 13:07
to 13:16 ran on the jar from before the deploy (jar written 13:18, restart 13:19). After the restart there is one
short C3 run (MrBedue `/nav South Gate`, `/nav Merchant's Square`, gate open 13:20:57 / close 13:21:13, positions not
logged), and no A8/A9 run. Temporary INFO diagnostics added in knk-plugin `1fae2af` ("[Navigation] Re-check",
"Walk path", "Roads instead") for the re-test; to be removed afterwards.

**Run 7 (2026-10-09, developer, knk-plugin `1fae2af`):** C3 by the developer's procedure - MrBedue runs `/nav
Merchant's Square` in front of the South Gate on the bridge, the gate opens, MrBedue walks through and stops about
2 blocks past the gate region on the town side, the gate closes - still "blocked by the South Gate". Diagnostic:
`step 0/7 edge #10139 backward along 39.9..0.0, step starts at 0.0 of the route, walked 34.8, blocked: the South Gate
is closing -> BLOCKS the route`. The stretch still ahead (along 5.1 → 0, about (1421,-459) → (1418,-463)) is past
the door (along ≈ 14) and outside `gate_2000131`, so the part check should have said open. **Cause:**
`CompositeAccessPolicy` caches verdicts per edge id; the part (an edge object with edge 10139's id and its own tags)
got the whole edge's cached verdict. The open-side check of a blocked start edge (N6) had the same flaw. **Fixed in
knk-plugin `b6cb699`** (`AccessPolicy.checkPart`, evaluated without the per-id cache); the service tests now run the
production part path, including this procedure. A8/A9 was not re-tested in run 7.

**Run 8 (2026-10-09, developer, knk-plugin `b6cb699`):** **C3 passes.** A8/A9 (MrBedue in front of district 16,
`/nav South Gate`): with the gate open it works (the open side of the blocked start road is used); with the gate
**closed** the navigation ended at once (13:49:08, no re-check lines). The developer: the default destination is the
gate's spawn Location, which is reachable with the gate closed; and even without a way, guide as close as possible,
as for a destination behind a closed gate.
- **Finding N14.** South Gate's spawn (1421.4, 49, -450.3) is just on the town side of the door line and snaps onto
  edge 10139 at along ≈ 12 (door ≈ 14). The router treats a blocked edge as a whole, so the goal on it was
  unreachable; the explainer then took the all-open route - straight through district 16 - and its first block was
  the start road itself. **Fixed in knk-plugin `9391780`:** goal sides (the open stretch from a node to a goal on a
  blocked edge is used, tagged from the world like the start sides); and with no open route the explainer prefers the
  route the player's real policy allows to the reachable point nearest the goal, when it ends at least 8 blocks closer
  than the all-open route's first block - its reason is the first block on the way on from there.

**Run 9 (2026-10-09, developer, knk-plugin `9391780`): all pass** - A8/A9 with the South Gate closed (around district
16 to the gate's spawn) and the closest-point guidance. The temporary diagnostics are removed (`10b9a16`). The
follow-up fixes since the first trunk merge (C3: `a8ec1ec`, `b6cb699`; A8/A9: `758dbc5`, `9391780`) are merged to
knk-plugin `main` (see the header). Still open: C6 (siege).

**Finding N15 (2026-10-09, developer) — "too far from any road" for a target above a road.** From (1419, 82, -550),
`/nav Keep Tower Roof` (Location 79 at (1410, 113, -506)) said "Keep Tower Roof is too far from any road." The player
stands on road edge 5487 (0.3 away); the straight distance is 54.6, so not direct mode. The target is **29.7** blocks
(3D) from the nearest road (edge 10088 at (1410, 84, -516), 28 blocks below the roof), but the snapper weights height ×4
(`snap-vertical-weight`), which measures **112** > 48. **Fixed 2026-10-09, live-tested by the developer (passes)
and merged to knk-plugin `main` `9f466a9f`:** `claude/kng-75-offroad-destinations` `5d674a20` (merges cleanly with
rev. 7 Part A). A destination
snaps with its own `navigation.destination-snap-vertical-weight` (default 1, plain 3D): its goal, its re-snap into the
start's network (also `/knk road why`) and the N13 roads-instead retry. The player's start keeps ×4 (bridge case); the
48-block limit stays. Gradle core 1753 / api-client 206 / paper 1310 green.
- [x] **N15 re-test (passed 2026-10-09):** deploy that branch (`./gradlew :knk-paper:dev`). From (1419, 82, -550), `/nav Keep Tower Roof`
  → a road route to below the keep, then a walk path up; or "No conventional path" if there is no walkable way up
  within the walk budget (intended, not a refusal). `/knk road why Keep Tower Roof` should show the route too.

Next: KNG-75 proper (walk legs at both ends, destinations further than 48 blocks off-road), handoff
`docs/ai-agents/handoffs/2026-10-09-navigation-offroad-destinations.md`.
- **Road trail on the Brink stairs to #3588** hugs the road's border; wanted: centred road trails, wider corners,
  stairs/slabs preferred on inclines - **KNG-76**.

**Deploy for run 3:** knk-plugin `claude/navigation-walkable-path` `a4892db` and knk-web-api `claude/road-navigation`
`fa234f7` (the merged plugin needs KNG-56's `GET /api/Domains/access-rules`). The dev DB lacks trunk's KNG-59
migration `UniquePermissionGrantHolderNode` (it deletes duplicate permission grants); navigation does not need it.

### KNG-108 — walk paths through tall buildings (live-tested 2026-10-10: H1-H3, H4.1 pass, H5 accepted)

knk-plugin `claude/dazzling-dijkstra-94leyd` `8e0a83d` (on `main` `973aa68b`). Gradle core 1841 / api-client 219 /
paper 1414 green; the new search test fails without the change. The API and the web app are unchanged. A walk path
may now be `navigation.walk.climb-allowance` (5) blocks longer per block of height between start and target, above
`max-length` too. The Keep Tower Roof leg (finding N17: a spiral stair, 168 blocks for 29 of height, cap 77.6) gets a
cap of 217.6. The replay found that path inside today's capture box in 1642 expansions, so the box and the expansion
budget stay as they are.

Deploy: `./gradlew :knk-paper:dev` from that branch, restart. The server's `config.yml` needs no change (the new key
defaults to 5); a written-out `climb-allowance: 0` turns it off.
- [x] **H1** On the Keep Tower Roof (1410, 113, -506), `/nav` somewhere far: a full walk path down the spiral stair
  to the keep road (edge 10088), **no** "Having trouble determining the route - guiding you to the nearest road."
  and no partial path. Walk it down: the road guidance starts at the road, no "You left the road".
- [x] **H2** The other way: a destination on the roof (make a Location there if there is none) from the keep road or
  further: the last leg is a full walk path up the stair, **no** "No conventional path to X found.".
- [x] **H3** `/knk road status` after H1/H2: the walk-path "budget" count does not go up for these legs.
- [~] **H4** Regression: a level target behind a building (Merchant Square from ~27 blocks, N2) and a shut-in box
  (step 1 S4: "No conventional path to the road found.") as before. **Run 1:** the building passes; the shut-in box
  passes a little away from the road but **not very close to it** - finding **N18** below. Not a KNG-108 regression.
- [x] **H5** (accepted without running) Optional: `climb-allowance: 0` in the server's `config.yml`, restart, H1 again: the "Having trouble"
  message is back (the old cap). Set it back afterwards.

**N18** (run 1, 2026-10-10; known since step 1 S4 run 1): boxed in **very close to a road**, nothing says "No
conventional path to the road found."; a little further away it does. Cause: within `reroute-distance` (8) of the route
`NavigationService.aimStartLeg` aims no walk leg to the road at all (KNG-75 step 1 design: on the route, today's straight
line), so no search runs that could find the player shut in. KNG-108 only changes the cap of a search that runs, and a
shut-in box exhausts its area whatever the cap. A player stuck next to a road gets the road guidance with no warning.
Follow-up, not part of KNG-108.

If H1 still runs out of budget: replay the leg (`tools/road-replay/README.md`, "Walk path replay"; `walk.txt` with
`start=1410.5,113,-506.5`, `target=1410.5,84,-516`, `max-length=144`): the report now prints the height and the cap.

### KNG-75 step 2 — destinations up to 256 blocks off-road (live-tested 2026-10-10: B1-B6 pass; merged)

**Merged to knk-plugin `main` `8f2b7c30`** (merged-tree Gradle core 1786 / api-client 212 / paper 1395 green). KNG-75
is done. Branch `claude/kng-75-offroad-destinations` `6c036eaf` (on `main` `c4141f90`: `fec8e4b2` replay batch mode,
`7b8a11cc` walk length cap 144 and 64-chunk capture, `6c036eaf` destinations). Gradle core 1786 / api-client 212 / paper
1395 green; each new test fails without its fix. Measurement and decisions:
[report 2026-10-10](../reports/2026-10-10-kng75-walk-leg-measurement.md), KNG-75 comments. With walk paths on, a
destination may be `max-destination-distance` (256) from a road; within `destination-walk-range` (96) of the road's end
the last leg is a walk path; further, "No conventional path to X found." and the HUD arrow alone, until the player is
within 96 - then a walk path.

**Before deploying:** the server's `plugins/KnightsAndKings/config.yml` has `walk: max-length: 96` written out - change
it to **144** (or delete the line), else the old cap stays. The new keys need no entry. Deploy: `./gradlew :knk-paper:dev`
from `Repository/_worktrees/knk-plugin-kng75`, restart.
- [x] **B1** 48-96 off-road, reachable: Location 72 at (1500, 54, -636) is 83.6 from the road (1447, 42, -572); give it a
  name in the web app (it is "Location"), then `/nav <name>` from afar: by road, then a walk path (the replay found 96
  blocks). Before: "too far from any road".
- [x] **B2** 48-96 off-road, unreachable: `/nav East Gate Square` (Location 7, 75.8 off-road; its spot is inside solid
  andesite): by road, then "No conventional path to East Gate Square found.", no straight line. Afterwards fix its y.
- [x] **B3** 96-256 off-road: a new Location 100-250 blocks from any road (in the wild). `/nav` it: no straight line
  from the road's end on (also not while on the road); at the road's end "No conventional path to X found." once, no
  trail, the HUD arrow and distance point at it. Walk towards it: within 96 blocks a walk path appears (no second
  message); reaching it is the arrival.
- [x] **B4** More than 256 from any road (e.g. "Orphan test" at (1, 2, 3)): "… is too far from any road."
- [x] **B5** Step 1 with the bigger capture: stand 85-95 blocks diagonally off a road, `/nav` somewhere far: a walk path
  to the road, not a straight line; `/knk road status` "not captured" does not go up.
- [x] **B6** Regression: Keep Tower Roof (N15) and a nearby target (direct mode) as before.

### KNG-75 step 1 — a walk path from the player to the road (live-tested, merged 2026-10-09)

**All pass (run 2, 2026-10-09) and merged to knk-plugin `main` `c4141f90`** (merged-tree Gradle core 1786 / api-client
212 / paper 1389 green). Branch `claude/kng-75-offroad-destinations`: `be0267bf` (step 1), `c923aa3d` (N16),
`2273ffaa` (N17). The API and the web app are unchanged. First pushed as `be0267bf` (core 1780 / api-client 209 /
paper 1369 green). With walk paths on, a player
off the road gets a walk path to where the route starts instead of a straight line, and may start up to
`navigation.max-start-distance` (96) blocks from a road in plain 3D (was 48, with height ×4). The height weight still
picks the road (bridge case). The session waits while the player walks to the road. Decisions: KNG-75 comment of
2026-10-09. The server's `config.yml` needs no change (the default 96 applies).

Deploy: `./gradlew :knk-paper:dev` from the worktree `Repository/_worktrees/knk-plugin-kng75`, restart. One jar at a
time: test this and KNG-104 one after the other (or ask for a combined test build).
- [x] **S1** Stand 20-40 blocks off a road in open ground, `/nav` somewhere far: the trail is a walk path (leg colour)
  to the road, then the route from the road on. No "You left the road" while walking to it; on the road the usual
  guidance (maneuvers, HUD progress) starts.
- [x] **S2** Stand 50-90 blocks from the nearest road (before: "get within 48 blocks"): `/nav` works. A long diagonal
  leg may be too large to capture (49 chunks) and keep the straight line - note the distance if so (input for step 2a).
- [x] **S3** (run 2 passes) High above a road, e.g. the Keep Tower Roof (1410, 113, -506): `/nav` somewhere far is not refused; the walk
  path goes down (stairs/ladders) to the keep road.
  **Run 1 (2026-10-09): routed, the right road and trail, but two findings:** **N16** "You left the road -
  recalculating" while following the walk trail down - past the end of a budget-cut partial path the start leg
  counted as heading away; fixed `c923aa3d` (heading away needs both: farther along the leg and farther from the route).
  **N17** "No conventional path to the road found." with a correct trail: the walk replay (`WalkReplayTest`, roof
  (1410.5, 113, -506.5) to the snap point (1410.5, 84, -516) on edge 10088) shows the only way down is the spiral
  stair, **168 blocks for 29 of height**; the length cap is 77.6 (1.75 × 29.6, or + 48, at most 96) → out of budget,
  partial path. Without the cap it is found in 1642 expansions. **Developer decision 2026-10-09:** no larger budget now;
  out of budget on the way to the road says "Having trouble determining the route - guiding you to the nearest road."
  and keeps the partial path (`2273ffaa`); the height allowance is later QOL,
  [KNG-108](https://linear.app/kngpandi/issue/KNG-108). Re-test S3 on `2273ffaa`: that message, no "You left the road".
- [x] **S4** (run 2 passes; run 1: fails - a 1x1 box of spruce logs, 2 high, corners open; the developer suspected diagonal
  corner-cutting. The real `WalkSearch` on that box returns NO_PATH after 1 expansion, so the corner rule holds; what
  was shown is being asked: a box within 8 blocks of the route gets no walk leg at all, only today's straight line)
  Shut in with no way out (a closed room, or fenced in): "No conventional path to the road found." once,
  the route from the road on, no straight line; walking out once a door opens, the navigation carries on.
- [x] **S5** While walking to the road, walk off the other way: the walk leg goes, about 2 s later "You left the road -
  recalculating" and a new walk path to the road now nearest.
- [x] **S6** More than 96 blocks from any road: "You're too far from a road - get within 96 blocks of one."
- [x] **S7** `/knk road status`: the walk-path line counts the walk to the road as well ("walking", "computing").
- [x] **S8** Regression: standing on the road, `/nav` as before (no walk leg); a nearby target (direct mode) as before.

### KNG-76 — centred road trails, wider corners, stairs on slopes (live-tested and merged 2026-10-10)

knk-plugin `claude/kng-76-centred-trails` `fc670d1a` (on `main` `c4141f90`; the API and the web app are unchanged; no
rebuild needed). Gradle core 1793 / api-client 212 / paper 1392 green. The route trail is drawn through
`TrailCentring`: each point looks across the road (up to 3 blocks each side) and moves to the middle of the road cells
there (a profile floor material with room above, at the trail's height or one off); on a slope to the middle of the
stair and slab cells. Only the drawn trail changes - not the graph or the route.

**Why (analysis 2026-10-09):** the stairs from Brink down to #3588 are two blocks wide (rows z -517 and -516, between a
ledge and a wall); edge #10068 lies on the northern row, so the trail ran half a block off-centre, along the edge.
Whole-block geometry cannot hold the middle of an even-width road. Offline on the dev world the centred trail runs at
about z -516.0 there (it was -516.5).

Deploy: `./gradlew :knk-paper:dev` from that branch, restart.
- [ ] **T1** From Brink, `/nav Merchant's Square` (down the stairs to #3588): on the stairs the trail runs down their
  middle, not along the northern edge.
- [ ] **T2** A straight three-block road: the trail stays in the middle, without wobbling.
- [ ] **T3** A bend in a narrow road: the trail keeps off the inner edge (a wider corner).
- [ ] **T4** A wide road or a plaza: the trail is where it was.
- [ ] **T5** A slope with stairs or slabs on one side and full blocks on the other: the trail is on the stairs.
- [ ] **T6** Navigating for a while: no lag (the trail reads a few hundred blocks per draw per player).

**Run 1 (2026-10-09, `fc670d1a`): T1-T5 pass, T6 no lag.** Findings:
- **T1 used a walk path, not the road trail:** by design. A destination within `max-snap-distance` (48 blocks) of the
  player is direct mode - a walk path only (Merchant's Square is about 35 blocks from Brink; the same `/nav` was direct
  mode on 2026-10-07, finding N2). Not a KNG-76 change. To see the road trail on the stairs, navigate to a place more
  than 48 blocks away whose route runs down them (`/knk road why <player>` lists edge #10068 when it does).
- **T6: the centred trail twitched right in front of the player.** Each redraw sampled the route from the player's
  position, so the points slid along the road and got other sideways shifts, and the first points were smoothed with
  fewer neighbours. **Fixed in `3cc403d2`:** the trail points sit on fixed spots of the route (every 1.5 blocks from its
  start) and are centred with a margin of spots either side, so a redraw puts every particle where it was.
- [ ] **T6b** Walk along a road while navigating: the particles stay in place as the trail moves on with you; no
  sideways jumps in front of you.
- [ ] **T1b** A road route down the Brink stairs (destination more than 48 blocks away): the trail runs down their middle.

**Run 2 (2026-10-10, developer, `3cc403d2`): T6b and T1b pass.** With run 1's T1-T5 every check has passed. **Merged to
knk-plugin `main` `d0167a6d`** (with `main`'s KNG-75 step 2 merged in first; Gradle core 1793 / api-client 212 / paper 1400
green).

### Rev. 7 follow-up — "Ignored" regions cut no roads (live-tested and merged 2026-10-09)

knk-plugin `claude/kng-92-ignored-regions-no-cuts` (on `main` `1159ae5d`; the API and the web app are unchanged): `71fcbba6`
(the filter) and `aff6ec74` (run-1 fix). Gradle core 1784 / api-client 209 / paper 1367 green. A region whose domain's
"Entry rule on roads" is `Ignored` (houses, shops along a street) no longer cuts the road in the routing view; the router
already ignored its rule.

**Run 1 (2026-10-09, `71fcbba6`):** I1 done; I2 only the "+region" count dropped (9 → 7), the cut count stayed at
"13 cut into 45 pieces"; I3 routed east (the log shows it before the restart too: MrBedue at Navigation Test's border at
22:15:46; a `/nav` right after a change can still use the old catalogue, which loads in the background); I4 route west
again, numbers unchanged. **Cause:** the filter looked the region's domain up in the region → domain cache, which
`/knk cache refresh` empties since KNG-104 - right after a refresh the region was unknown and kept cutting - and a change
waited for the next live-tag pass (a minute). An offline replay of the cut on the dev data (regions only) confirms that
without `domain_16` edge #5385 (Wearway) is not cut: one edge and two pieces fewer. **Fixed in `aff6ec74`:** the
`/navigate` catalogue now keeps each domain's region id and answers "is this region Ignored" itself, and a catalogue
load that changes the set recuts the roads at once.

Deploy: `./gradlew :knk-paper:dev` from that branch, restart, wait for "… cut into N pieces" in `/knk road status`.
- [ ] **I1** Every rule on `Applies`: note the live-tags line of `/knk road status` (edges cut, pieces).
- [ ] **I2** Set "Navigation Test" to `Ignored` (its "Road Access Override"), `/knk cache refresh`, wait a few seconds:
  `/knk road status` shows one edge and two pieces fewer than in I1 (Wearway, #5385, no longer cut). `/knk road why`
  on a route along Wearway shows that edge without a `blocks …` stretch.
- [ ] **I3** `/nav South Gate` from Brink (run it twice if the first was within a second of the refresh): the east
  road through Navigation Test; walking in, the border still refuses entry.
- [ ] **I4** Back to `Applies`, `/knk cache refresh`, a few seconds: I1's numbers again, and the route goes west.

**Run 2 (2026-10-09, developer, `aff6ec74`): I1-I4 pass.** I2: "15 edge(s) with extra tags (+7 region, +3 gate door),
13 cut into 45 pieces" became "14 … (+6 region …), 12 cut into 42 pieces" - Wearway (#5385, three pieces) is no longer cut
(the guide's "two pieces fewer" was off by one: the count is of the pieces of cut edges). I3 east through Navigation
Test, I4 back to the first numbers and west. **Merged to knk-plugin `main` `eea80099`** (with `main`'s KNG-80 merged in
first; Gradle core 1784 / api-client 212 / paper 1382 green).

### KNG-104 — the navigator's domain cache refreshes (live-tested and merged 2026-10-09)

knk-plugin `claude/kng-104-domain-cache-refresh` `132ce69a` (on `main` `5b1cc8b8`; the API and the web app are
unchanged). Gradle core 1784 / api-client 209 / paper 1365 green. A region whose cached domain is older than the cache
TTL (1 minute) is re-asked in the background when navigation looks it up; a region the API no longer knows is
forgotten; `/knk cache refresh` clears the map. Before, a change to AllowEntry/AllowExit reached navigation only after
a restart ([KNG-104](https://linear.app/kngpandi/issue/KNG-104), run 1 finding P1).

Deploy: `./gradlew :knk-paper:dev` from that branch, restart. A test account without `knk.region.bypass`.
- [ ] **D1** "Navigation Test" denies entry: from Brink, `/nav South Gate` takes the west road (Kardenna end).
- [ ] **D2** In the web app, allow entry on "Navigation Test". **No restart, no cache refresh.** Wait a minute, then
  `/nav South Gate` again (twice if the first still goes west: the first lookup only starts the refresh): it now
  takes the shorter east road through the district.
- [ ] **D3** Deny entry again while navigating along the east road: within about a minute and a re-check (every 2 s)
  the route changes ("… may not enter Navigation Test - recalculating", or the west road).
- [ ] **D4** Allow entry once more, then `/knk cache refresh` at once: the next `/nav South Gate` goes east straight away.
- [ ] **D5** The server log shows no `resolveRegionsFromApi` burst per route for regions that do have a domain (one
  refresh per region per minute at most).

**Run 1 (2026-10-09, developer): D1-D4 pass, D5 accepted.** No findings. **Merged to knk-plugin `main` `1159ae5d`.**

### Rev. 7 Part A step 2 — the patches removed (implemented 2026-10-09, to test)

knk-plugin `claude/navigation-walkable-path` `9fa14394` (= `main` `54878783` + step 2; the API and the web app are
unchanged). Gradle core 1761 / api-client 209 / paper 1316 green. The workarounds for whole-edge verdicts are gone:
start sides (N6), goal sides (N14), the part re-check and its cache bypass (N10). The routing view now carries those
cases on its own. New: a player standing at a node whose snapped edge is blocked (a junction, or the block right
before a door) leaves from that node.

Deploy: `./gradlew :knk-paper:dev` from that branch, restart. **Wait until `/knk road status` shows "… cut into N
pieces"** (a few seconds on Cinix): until the first live-tag pass the stored network is used, and without the patches
the gate road then counts as closed along its whole length.
- [ ] **W1 (N6, bridge side)** Close the South Gate. Stand on its road on the bridge side, a few blocks from the door.
  `/nav` to a place back over the bridge: a normal route, no "No open route", no "arrived". `/nav` to a place behind
  the gate: "Guiding you to the gate", ending at the door.
- [ ] **W2 (N6, town side)** The same on the town side of the closed gate, `/nav` into town: a normal route.
- [ ] **W3 (at the node)** Gate closed. Stand on the block right in front of the door (where the trail of W1 ended),
  `/nav` back into town or over the bridge: a route at once, no "No open route".
- [ ] **W4 (N14)** Gate closed, from town: `/nav South Gate` (its spawn lies on the town side of the door) reaches it
  with a full route, no partial-route message.
- [ ] **W5 (N10/C3)** Gate open, `/nav` from the bridge to a place in town. Walk through, stop a few blocks past the
  door, close the gate: no message, guidance goes on. Then from in front of the gate with the route through it, close
  it: "… closed - recalculating" and a detour or guidance to the gate.
- [ ] **W6 (A7)** A closed gate on a shortcut: detour; open it: the shorter route comes back within about 2 s.
- [ ] **W7 (C5)** A district with `allowEntry=false`: guided to its edge; with bypass the route goes in. One with
  `allowExit=false`, from inside: routes stay inside.
- [ ] **W8** `/knk road why <player>` on a route through the gate: lines as in V6 (`edge #10139 blocks …`).

**Run 1 (2026-10-09, developer, plugin `9fa14394`):** deploy and the live-tag wait done; **W1** (both directions), **W2**,
**W3**, **W4**, **W7**, **W8** pass. **W5** (a gate closing behind the player, N10/C3) and **W6** (A7) were not run;
the unit tests cover both on the routing view (`NavigationServiceTest.throughTheOpenGateThenItClosesBehindThePlayer`,
`aRouteStartingPastTheGateOnItsEdgeIsNotBlockedByIt`, `aClosedGateOnTheRouteTriggersARerouteWithTheReason`), and V4
(C3, A7) passed with step 1. No findings. **Merged to knk-plugin `main` `723d21f4`.** **W5 and W6 pass** (developer,
2026-10-09, on trunk): every W step has passed.

### KNG-73 — configurable default destination (implemented 2026-10-08, to test)

Branch `claude/kng-73-road-navigation-n92vlm` in knk-web-api (`a04d614`, on trunk `4c570fa`), knk-plugin (`290b122`, on
`claude/navigation-walkable-path` `758dbc5` + trunk) and knk-web-app (`a7ddc65`, on trunk `b51eba0`). Not merged.
Tests: web-api 1846 pass (the 4 failures fail on `master` too), Gradle core 1744 / api-client 208 / paper 1302 green,
web-app tsc clean, road/admin tests green except `RoadsAdminPage › deletes a profile after confirmation` (fails on
`main` too: it still expects `window.confirm`).

Deploy: API with migration `AddDomainNavigationDefaults` (adds `domains.NavigationDefaultOverride` and
`domain_navigation_defaults`, every type seeded `Spawn` - nothing changes until a default is changed), the plugin jar,
the web app.
- [ ] **K1** `/admin/roads` → "Navigation defaults": four rows (Towns, Districts, Structures, Gates), all `Spawn`,
  0 overrides. Set Districts to `Region`.
- [ ] **K2** Run `/knk cache refresh` (otherwise the first `/nav` a minute later still uses the old catalogue and
  only starts its refresh). From outside a district:
  `/nav <district>` guides to the nearest edge of its region (as `/nav <district> region` did);
  `/nav <district> spawn` still goes to its spawn Location.
- [ ] **K3** Standing inside the district: `/nav <district>` says "You are already in …" (both defaults).
- [ ] **K4** Form Builder: add the field "Navigation Default Override" to the Town form (and the others as wanted).
  Set one town to `Region` while Towns stay `Spawn`: that town goes to its region, other towns to their spawn;
  the Towns row counts 1 override. Clearing the field (empty choice) makes the town follow its type again.
- [ ] **K5** Edit a gate or town with a form *without* the field: its override stays as it was.

#### Rev. 7 Part C — entry rule on roads (KNG-92, implemented 2026-10-09, to test with KNG-73)

On the same branches: knk-web-api `79e2b63` (one more column and override in the same `AddDomainNavigationDefaults`
migration - `domain_navigation_defaults.RoadAccess`, `domains.RoadAccessOverride`, every type seeded `Applies`), knk-plugin
`ccb04891` (on a merge of `main` `fd869aa`), knk-web-app `1368115`. Tests: web-api 1855 pass, 9 fail as on `master` (incl.
`Validation_GeometryFarFromItsNode`); Gradle core 1754 / api-client 209 / paper 1310 green; web-app tsc clean, road/admin
tests green except the known `RoadsAdminPage › deletes a profile after confirmation`. Nothing changes until a rule is set
to `Ignored`. [REV7_PROPOSAL.md](../specs/navigation/REV7_PROPOSAL.md) §4.
- [ ] **R1** `/admin/roads` → "Navigation defaults": an "Entry rule on roads" column, all `Applies`, 0 overrides. Changing
  it leaves the default destination as it was (and the other way round).
- [ ] **R2** Pick a structure (or district) whose region a road passes through, with `AllowEntry` off, and a test account
  without `knk.region.bypass`. `/nav` to a place beyond it: the route avoids that road (or "You may not enter X", as today).
- [ ] **R3** Set that type (or, via the Form Builder field "Road Access Override", only that domain) to `Ignored`, then
  `/knk cache refresh`. The same `/nav` now routes along the road through the region; walking in, the border still
  refuses entry (KNG-56). Its row counts 1 override when done per domain; clearing the field follows the type again.
- [ ] **R4** Set it back to `Applies` (or clear the override) and refresh: the route avoids the road again.

Run 1 (2026-10-09): K1-K3 pass, K4/K5 and R1 accepted; R2/R3 blocked by P2 (gate regions unresolvable, fixed API
`1ff8dba`), R4 no other route. Details and the other findings (P1, P3) in the guide on `main`, after V6.

### Rev. 7 Part A — routing view (implemented 2026-10-09, to test)

knk-plugin `claude/navigation-walkable-path` `893e33da` (= `main` `fd869aa` + Part A; the API and the web app are
unchanged). Gradle core 1762 / api-client 206 / paper 1306 green. [REV7_PROPOSAL.md](../specs/navigation/REV7_PROPOSAL.md)
§2, KNG-92. Navigation now routes on a view of the network cut at every gate door and region border the live tags
find; the admin side (overlay, `/knk road …` except `why`) still shows the stored edges. The N6/N10/N14 patches are
still in; they go in a second step once this passes.

Deploy: `./gradlew :knk-paper:dev` from that branch. Give the live tags a minute after the restart (or a network
change) before testing.
- [ ] **V1** `/knk road status` → "live tags": `… N cut into M pieces` - expect a few edges (4 gates plus district
  borders on Cinix).
- [ ] **V2 (the gap Part A closes)** Close the South Gate and `/nav` to a place behind it from the bridge side:
  "Guiding you to the gate" now ends **at the gate** (within a block or two), not at the bridge-side node about 34
  blocks before it (edge 10139).
- [ ] **V3** A road that clips a district you may not enter (N4's district 16 if it touches a road, or make a
  region over one end of a road with `AllowEntry` off): the stretch outside the district stays usable; a destination
  on it is reached without a detour. Into the district: "Guiding you to its edge" ends just outside it.
- [ ] **V4** Re-run C3 (a gate closes on the route; opening it gives the shorter route back), C4 (pass-through hint
  and route through the gate), C5 (`allowEntry=false` → to the edge; bypass → in; `allowExit=false` → routes stay
  inside), A7 (closed gate on the shortcut → detour; opening → back within ~2 s) and A8 (a region you may not enter
  → around it).
- [ ] **V5** N6, N10, N14 cases: standing on the road of a closed gate (either side), a gate closing behind you, a
  destination on the open side of a closed gate - same results as runs 7-9.
- [ ] **V6** `/knk road why <player>` on a route through a gate: blocked lines read `edge #10139 blocks 31-34` (the
  stored edge and the stretch), not a large synthetic id. No extra "Continue"/"Take the stairs" lines mid-road.

**Run 1 (2026-10-09, developer; one deployment of `claude/kng-73-road-navigation-n92vlm` in all three repos, plugin
`eb30322e` = KNG-73 + Part C + Part A):** K1-K3 pass, K4/K5 accepted (one town only); R1 accepted; V1, V2 pass; V4
C3/C4/C5 pass, A7 accepted. Not passed: R2/R3 (P2), V3, V4 A8 and V5 (P1). Analysis from the server log and the dev DB
(read-only):
- **P1 — the west road round the island was blocked by an orphaned region (V3, A8, V5).** From Brink to the South Gate
  there are two ways to node 3589: east over #5385 (Wearway, through "Navigation Test", `domain_16`, entry and exit
  denied) and west over #5228 (Kardenna end). The west one crosses `domain_17`. "Road clipping district" (17) was
  created on `domain_17` with entry denied; at 16:18:57 the navigator cached that. Re-running its region step at
  16:19:50 made `tempregion_worldtask_227`, whose rename to `domain_17` failed ("target region name already exists"),
  so the DB now points at `tempregion_worldtask_227` and `domain_17` is an orphan on the road. The navigator's
  region → domain cache (`RegionDomainResolver`, `getDomainByRegionIdNoRefresh`) is never cleared, and a lookup that
  finds no domain does not evict, so `domain_17` kept "entry denied" until a restart - also after allowing entry on
  the district. Both ways blocked → the explainer guided along the shorter all-open way, east, to Navigation Test's
  edge (the west alternative was not 8 blocks closer). Not a Part A/C fault. Follow-ups: the region-step re-run
  should replace the old region; the resolver should evict a region the API no longer knows and refresh stale
  entries for the navigator.
- **P2 — gates and Keep Gate were never seen by the navigator (R2/R3).** `POST api/Domains/search-region-decisions`
  picked Town/District/Structure by exact type name, so GateStructure regions (the gates; Keep Gate and Keep Stair
  House are GateStructures on the dev DB) answered `{}`: routing and walk paths treated Keep Gate as open, only the
  border refused. **Fixed in knk-web-api `1ff8dba`** (a GateStructure takes the Structure place). The region tracker
  now also sees gates (enter/leave messages for gate regions).
- **P3 — crash after a reload: `unknown road edge 5385` in `ManeuverBuilder` (16:28:37).** Until the first live-tag
  pass the stored network serves, then the routing view, whose edge ids differ; the session kept its old route and
  ManeuverBuilder. **Fixed in knk-plugin `d24f9649`**: a network change drops in-flight results and takes the route
  computed on the new network as it is (silent unless it blocks or opens the way).
- **Web app:** "(i)" tooltips on both Overrides columns, knk-web-app `06ba989` (developer request).
- **Re-test after deploying `d24f9649` / `1ff8dba` / `06ba989`:** remove the orphan `domain_17` (`/rg remove domain_17`)
  and restart the server (clears the navigator's domain cache), then R2/R3 with Keep Gate, V3, A8, V5.

**Run 2 (2026-10-09, after the restart with `d24f9649`/`1ff8dba`/`06ba989`):** V4 passes. With "Road clipping district"
denying entry on `tempregion_worldtask_227` (1/3 of the road's width), `/nav South Gate` takes the west road past it.
Follow-up issues: KNG-103 (region step re-run leaves the old region), KNG-104 (navigator domain cache never refreshes).
- **P4 — a region over part of the road's width blocks it when it covers the centreline.** Moved to `domain_17` (2/3
  of the width), the west road counts as blocked again and the route goes east. The router judges a road by its
  centreline (#5228 runs along z = -477 there): `domain_17` (z -479..-477) covers it, `tempregion_worldtask_227`
  (z -479..-478) does not. Not a wall cost: the road router has none (that is the walk path's). Proposed fix: tag a
  region on a stretch only where it covers the whole road width, and shift that piece's line to the free side
  where it covers part - decision pending.
- **First leg a straight line** (from the South Gate's spawn to the road): by design today; the walk path for the
  first leg is KNG-75 step 1 (another session, `claude/kng-75-offroad-destinations`). The earlier walk path was the
  last leg, navigating *to* the gate.

**Run 3 (2026-10-09, developer): R2, R3, V5, V6 pass.** With R1/R4, K1-K5, V1-V4 from runs 1-2 every check of KNG-73,
Part C and Part A step 1 has passed (C6, siege, is still open from the KNG-27 checklist). **Merged to trunk 2026-10-09:**
knk-web-api `master` `6d160aa`, knk-web-app `main` `e2ba784`, knk-plugin `main` `54878783`. Next: Part A step 2, the patch
removal: implemented, steps W1-W8 under "Rev. 7 Part A step 2" above.

### Phase 3 — rebuild re-test (2026-10-02, developer; recorded from the commit messages)

Not written up here at the time; reconstructed by the walkable-path chain (link 1) from the developer's commits on
knk-plugin / knk-web-api `claude/road-navigation`, 17:13-18:00 CEST.
- Tile 2,-2 failed with `Boundary node 'n70' at (1418, -520) is not on the tile border`: the new locked-node reach let a
  border node claim locked junction #7 "Brink". **Fixed** `6a8caa7`.
- Spurs in a small, oddly shaped plaza returned on every rebuild. **Fixed** with `/knk road node prune|unprune`
  (plugin `9dccb58`, API `c029186`).
- Recorded stretches (town road, bridge, land) were drawn through the road blocks — the recorder stored the block
  under the floor. **Fixed** `8b6d678`; **re-record stretches recorded before it**.
- Junction #3615 sat in a straight road with two edges and could not be pruned. **Fixed** `075ae94` (two-arm junctions
  are joined into one edge unless locked, a loop split, or the previous build gave it 3+ edges).

---

## Prompt for a fresh Claude Code session

Use this if you want a session to prepare the environment and walk you through the test, or to triage what you found.
*(The branch heads in the prompt are from 2026-09-29; the current ones are in the header above.)*

> Read `docs/guides/road-navigation-smoke-test.md` in the knk-workspace repository (branch main), then the plan's
> "Phase 1/3/4/5 status → Developer to-do" blocks in `docs/specs/navigation/IMPLEMENTATION_PLAN.md` and the report
> `docs/reports/2026-09-27-road-navigation-chain.md`. Road navigation (KNG-27) is implemented on branch
> `claude/road-navigation` in knk-web-api (`77e0a29`), knk-plugin (`4e3f8af`) and knk-web-app (`9dbb481`); nothing is
> merged to trunk. I am running the live smoke test on my dev server tonight. Do NOT merge anything to trunk, do not
> touch a real database, do not deploy to a server, and never force-push.
>
> Mode A — prep: check out the three branches, run `./gradlew build -x deployToDevServer` and the web-app/web-api
> builds, confirm the counts in section 0, and report anything red or missing (config keys, plugin.yml nodes, the
> Street form step). Fix nothing outside `claude/road-navigation`.
>
> Mode B — triage: I will paste findings from the checklist (step, what I saw, console output). For each, find the
> cause in the code (plugin `paper/navigation/*`, `paper/roads/*`, `core/roads/*`, `core/navigation/*`; web-api
> `Services/Roads/*`; web-app `pages/admin/RoadsAdminPage.tsx`), say whether it is a bug, a config/data problem, or an
> intended behaviour (cite the plan's decision number), and for real bugs push a minimal fix with a test to
> `claude/road-navigation` in one commit per bug, then update the plan's status block and the report. Keep a running
> list of what is fixed, what is open and what is not a bug.
