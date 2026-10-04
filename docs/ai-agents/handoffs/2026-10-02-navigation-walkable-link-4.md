Read docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md first and follow it; it overrides anything below.

Implement link 4 — KNG-51 Phase C (`DirectLeg` refactor, walk path in direct mode, `TrailRenderer.drawPath`, config,
messages, kill switch; final write-up) end to end (code, tests, commits, push to claude/navigation-walkable-path,
progress report, final write-up) as link 4 of the chain — the last link.

State you start from (written by link 3, 2026-10-02 ~20:05 UTC container clock — re-check before relying on it):
- knk-plugin `claude/navigation-walkable-path` `aa320e5` = link 2's `ad311ae` + five link-3 commits (`beec0e1` core cell
  access, `905987b` capture, `12c834a` snapshot service + `navigation.walk` config, `d08c341` `NavigationAccess.gateAvailability`
  extraction, `aa320e5` access factory). `origin/claude/road-navigation` `075ae94` and `origin/main` `27b4236` were merged
  ("already up to date") before the final push: fetch and merge both again (charter §1.2). The repo may not be in your
  container: `add_repo` PandiO/knk-plugin (push), clone the feature branch, then fetch the two other branches by refspec
  (a `--branch` clone is single-branch).
- Test counts on `aa320e5` (`./gradlew build -x deployToDevServer`, green): knk-core **1628**, knk-api-client **184**
  (2 skipped), knk-paper **1116** (14 skipped). Re-create `~/.gradle/gradle.properties` per charter §1.4; Maven Central
  may 429 on a fresh container — retry, then `--offline`.
- Progress report `docs/reports/2026-10-02-navigation-walkable-chain.md` has link 3's section (decisions L3-1 … L3-10,
  "What link 4 must wire"); the design's §10 has "Phase A status" and "Phase B status" notes.
What earlier links say this link must wire (full list: report → "Link 3" → "What link 4 must wire"):
- First the behaviour-neutral refactor: direct-mode fields of `NavigationService.Active` (`directBest`,
  `lastDirectRecalcTick`, `recheckDirect`, message `directRecalculating`) into `DirectLeg` (design §7), existing tests
  green, own commit.
- Construction in `KnKPlugin` next to `NavigationAccess`: `WalkSnapshotService(navigation.passabilityRules(
  ChunkSnapshotSurfaceGrid.bukkitCollidable()), navigation.walk(), TickBudget.server(), System::currentTimeMillis)`
  `.start(this)` / `.stop()`; `WorldGuardWalkAccess.factory(access)`; one shared `WalkSearch`. Inject them into
  `NavigationService.Deps` behind small ports so `NavigationServiceTest` can fake them (fake `WalkPathfinder`, §12).
- Per leg, main thread: `GateCellsIndex.of(gateManager, world)`, `WalkBox.around(...)`,
  `walkSnapshots.capture(WalkSnapshotService.of(world), gates, box)` (not `ready()` → FALLBACK);
  `walkAccessFactory.prepare(player, world, gates, capture, headroom)`. Routing thread: `access.resolve()` (domain lookups
  may block — never on the main thread, L3-5), `WalkRequest` with `walk.profile()`, `walk.budget()`, goal
  `WalkGoal.within(target, arriveDistance)` or `RegionShape::containsFloor`; `find` in try/catch (exception → FALLBACK,
  L3-8); deliver through `deps.mainThread()` with the generation check; cancel a pending capture future when the leg is
  replaced.
- `TrailRenderer.drawPath(viewer, List<double[]> floorPoints)` (design §7: same windowing as `drawRoute`, leg colour,
  `LEG_SPACING`, no per-point `floorOf`); `drawDirect` stays the fallback.
- Recompute triggers (§7): heading away (existing), > `recompute-distance` (6) from the path, target moved,
  gate/availability event for an active direct leg, path older than `chunk-ttl-seconds`-ish 10 s; never per tick, never
  while a request is in flight. `NO_PATH` and `FALLBACK` both keep the straight line (L2-1, decision §11-5).
- `config.yml` `navigation.walk:` block with every key and its default (bundled-config test pins `NavigationConfig.defaults()`);
  `enabled: false` must reproduce today's behaviour exactly (kill switch) — test it.
- The routing executor is single-threaded (`knk-navigation-routing`), so `max-concurrent-searches` is effectively 1 unless
  you give walk searches their own bounded executor; decide and record.
Phase-specific reading: `LAST_MILE_PATHFINDING.md` §5 (threading), §7 (all), §8 (throttle), §9, §10 Phase C row + the
Phase A/B status notes, §11-5, §12 (knk-paper tests + in-game matrix + definition of done). Code: knk-paper
`navigation/NavigationService` (`startDirect`, `tickDirect`, `recheckDirect`, `arrivedAtRouteEnd`, `computeRoute`/`deliver`,
`Active`), `TrailRenderer` (`drawRoute`, `drawLeg`, `drawDirect`), `navigation/walk/*` (start at `WalkSnapshotService` and
`WalkAccessFactory` class comments), `KnKPlugin` navigation wiring (~line 1180-1235); knk-core `roads/walk/WalkSearch`,
`WalkRequest`, `WalkResult`, `WalkPath`. Tests: `NavigationServiceTest` (mocked `World` kept in a field), `TrailRendererTest`.
Open flags that affect this link: decision §11-5 (no partial path) still awaits the developer's live test — keep
`NO_PATH`/`FALLBACK` → straight line, put it first on the live checklist. L2-1 … L2-10 and L3-1 … L3-10 are reversible
defaults; don't change them without a reason recorded in the report.
Known risks: changing shipped direct-mode behaviour (the refactor must be neutral; `enabled: false` = today); main-thread
cost of capture + access (measure with `WalkSnapshotService.stats()` — consider a debug line); WorldGuard door answers are
only mock-tested; the developer may commit to `claude/road-navigation` while you work — merge it before the final push.
Final write-up (charter "Link 4"): summary for the developer, the combined live checklist (decision §11-5 first, then
the §12 in-game matrix), merge order (branch → trunk) and which branches to delete afterwards; set the report's status to
finished.
Next after you: none — last link. Stop after the write-up.
