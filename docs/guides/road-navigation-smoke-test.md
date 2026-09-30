# Road navigation — smoke test checklist (KNG-27)

**Status:** In progress — Phase 1 passed; Phase 3 network usable after profile and builder tuning (see Findings); Phases 4, 5 not run yet
**Last updated:** 2026-09-30
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
- [~] **Survey three road types:** `/knk road survey start "Kardenna main street"`, walk 2-3 min (action bar samples
      climb only while walking on the ground), `/knk road survey stop` → proposal in chat → click **Save**. Repeat for a
      wilderness road and a trail (`survey start` without a name → `save <name>`).
      Did 3/4 surveys, works; the town has a lot of square/open plaza-like road areas and the surveyor already looked
      like it was producing rough proposals there (expected — surveys aren't meant to handle open plazas well).
- [x] `/knk road profile list` / `show <name>`; new profiles are class Road ×1.0 until you edit them (web app or
      `/knk road profile`).
- [~] `/knk road build radius 1500` around the town (include the tunnel/bridge) → action-bar progress, per-tile chat
      summary with clickable teleports.
      Many tiles logged `Tile X,X not built: no seeds: no domain Location, survey or admin seed in or near this tile`.
      Likely because the town is on an island with sparse roads around it (few/no seeds outside town bounds) —
      needs triage: is this expected behaviour for sparse-seed tiles, or should radius-build seed from a wider net?
- [ ] `/knk road show` → coloured polylines, pillars at junctions, action-bar label when looking at an edge;
      `/knk road show all` on a bridge.
      **Failing:** overlay shows way too many junctions and stale nodes; roads inside the town don't connect properly
      and some of the most obvious street segments weren't built at all. Not workable to fine-tune by hand as-is —
      needs a code fix, not just re-surveying/re-building. Root cause not yet triaged.
- [ ] Name at least the places you will navigate to: `/knk road node name Market` on a junction.
- [ ] `/knk road street "<street>" --continue` on an edge you stand on → "and N more".
- [ ] Break a road block → within 30 s `/knk road tiles` lists the tile DIRTY; `/knk road build dirty` keeps names.
- [ ] WorldEdit `//set` across a road → tile dirty.
- [ ] `/knk road edge set here close` → overlay turns red; `open` again.
- [ ] `/knk road reload`; restart the server mid-`build all` → the queue resumes and skips tiles built before.

## 3. Phase 5 — web app (~10 min)

Full text in the plan's "Phase 5 status → Developer to-do".

- [ ] "Roads" appears in the nav for `knk.admin.road`; `/admin/roads` loads world `world`: profiles, tiles, edges.
- [ ] Stretches: "Unlabelled only" → Edit → pick a street → "Continue along the road" → Save → green notice with N more.
- [ ] Create New Street from an edge; Rename opens the Street form.
- [ ] Edit cost 0 → refused; cost 2 + Closed → row shows ×2 and Closed in red (and `/knk road show` turns it red
      after the next cache refresh or `/knk road reload`).
- [ ] New profile with material suggestions (`DIRT_PATH`), town scope; duplicate name → API's 400 message; delete.
- [ ] Street edit form shows the Road panel; an unsaved street shows the "save first" note.
- [ ] Unknown world → empty tables, no error. Without the node: nav link hidden, page says "Staff only".
- [ ] **Rename a street here** and confirm the new name shows up in `/navigate` messages within ~60 s (street names
      refresh every minute).

## 4. Phase 4 — `/navigate` (in game, ~45 min)

Use two accounts where noted. Watch the console for exceptions the whole time, and `/tps` at the end.

**Basics**
- [ ] `/navigate` alone → "not navigating" plus usage. `/nav` works as an alias.
- [ ] Tab completion: names one word at a time, `stop`, `type:name` forms for shared names (e.g. `town:Market` vs
      `district:Market`), `spawn` / `region` after a complete name.
- [ ] Without `knk.navigate` → permission message. From the console → "only players".
- [ ] Unknown name → "No place called…" plus clickable "Did you mean" suggestions. Ambiguous name → clickable
      `type:name` choices.

**Destinations** (each: "Navigating to X - N m. Follow the trail; [Stop]", gold trail ahead only *you* see, boss bar
"→ X · N m · ~T" with progress, action-bar arrow)
- [ ] A Location by name and by `location:#id`.
- [ ] A Town → its spawn Location; the same Town with `region` → the route ends where the road enters the region.
- [ ] From *inside* that region → "You are already in X".
- [ ] A District and a Structure (Structure needs its Location via `locationId`).
- [ ] `street:<name>` → ends on the street; `node:<name>` → ends on the node.
- [ ] A domain with neither Location nor region → "has no location and no region".
- [ ] A place in another world → "is in another world".

**Guidance**
- [ ] Walk the route: "In 12 m: Turn left onto …" chat lines once each; the boss bar label switches to the maneuver
      within 20 blocks; tunnel → "Go down into the tunnel", bridge → "Cross the bridge".
- [ ] Arrival: chime + "You have arrived at X"; boss bar and trail disappear.
- [ ] Leave the road for > 2 s → "You left the road - recalculating."; the trail follows the new route.
- [ ] `/navigate` while navigating replaces the session; no-arg shows status with a clickable [Stop]; `/navigate stop`.

**Refusals and direct mode (DESIGN §6.2)**
- [ ] Stand > 48 blocks from any road → "You're too far from a road - get within 48 blocks of one."
- [ ] Target > 48 blocks from any road → "X is too far from any road."
- [ ] Target within 48 blocks of you → straight trail, no road ("X is N m away"); arrival at the target.
- [ ] Destination beyond the road's end but within 48 → routed, then a straight last leg (other colour, sparser).

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

**B. Bug: a Boundary node placed off the tile border (code, `SkeletonGraph`).** Error:
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

**C. Design issue: a plaza produces ~10 junctions plus stray edges.** Plazas are typically ~20 blocks wide here.
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

**D. Upload timeout on a huge tile.** Tile 3,-1 (249,305 cells, 2,521 nodes, 3,858 edges) failed in the plugin with
`SocketTimeoutException`, but the API finished and committed it (`GET api/road-tiles` shows v1 built 20:03:05). A
client-side failure can therefore leave a stored graph; this one is junk from the flooded mask and must be rebuilt
once the profiles are fixed.

**E. Operational notes.** `navigation.builder` values in `config.yml` are read only in `onEnable` — a full restart is
needed, `/knk road reload` only refreshes the network cache. There is no command or API route to delete a road node
or a road tile (only `node merge`, `edge delete`; a deleted Detected edge returns on the next rebuild).

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

**G. `/knk road show` action-bar identification is unreliable (usability bug).** Walking around and looking at
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

---

## Prompt for a fresh Claude Code session

Use this if you want a session to prepare the environment and walk you through the test, or to triage what you found.

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
