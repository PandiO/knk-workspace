# Road navigation — smoke test checklist (KNG-27)

**Status:** Ready to run (written 2026-09-29, after chain link 9)
**Last updated:** 2026-09-29
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

- [ ] `GET api/road-profiles` lists *Default road*.
- [ ] `PUT api/road-tiles/world/0/0/graph` (payload 1) → 200, `nodesCreated: 3`.
- [ ] `GET api/road-tiles/world/0/0/graph` → 200 with `ETag: "1"`; again with `If-None-Match: "1"` → 304.
- [ ] `PUT api/road-tiles/world/1/0/graph` (payload 2) → `stitchEdges: 1`; `GET api/road-network/meta?world=world`
      shows one component of 5 nodes.
- [ ] `POST api/road-tiles/world/1/0/dirty` → `dirty: true`; `POST api/road-edges/search` with
      `{"filters":{"stale":"true"}}` lists that tile's edges.
- [ ] `GET api/Streets/{id}` shows `edgeCount` / `totalLength`.
- [ ] **Delete these fake tiles before Phase 3** (or use a different world name) so they don't pollute the real network.

## 2. Phase 3 — build the real network (in game, ~45 min)

Run first: `/navigate` needs this network.

- [ ] `/knk road status` → enabled.
- [ ] **Survey three road types:** `/knk road survey start "Kardenna main street"`, walk 2-3 min (action bar samples
      climb only while walking on the ground), `/knk road survey stop` → proposal in chat → click **Save**. Repeat for a
      wilderness road and a trail (`survey start` without a name → `save <name>`).
- [ ] `/knk road profile list` / `show <name>`; new profiles are class Road ×1.0 until you edit them (web app or
      `/knk road profile`).
- [ ] `/knk road build radius 1500` around the town (include the tunnel/bridge) → action-bar progress, per-tile chat
      summary with clickable teleports.
- [ ] `/knk road show` → coloured polylines, pillars at junctions, action-bar label when looking at an edge;
      `/knk road show all` on a bridge.
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

_(fill in during the test)_

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
