Read docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md first and follow it; it overrides anything below.

Implement link 2 — KNG-51 Phase A (`knk-core roads/walk/`) end to end (code, tests, commits, push to
claude/navigation-walkable-path, progress report, handoff) as link 2 of the chain.

State you start from (written by link 1, 2026-10-02 ~20:00 UTC — re-check before relying on it):
- knk-plugin `claude/navigation-walkable-path` `d8507a3` = `claude/road-navigation` `075ae94` (trunk `main` `27b4236`
  contained) + one link-1 test commit. It exists and is pushed: check it out, pull, then merge `origin/claude/road-navigation`
  and `origin/main` (charter §1.2).
- Baselines on `d8507a3` (`./gradlew build -x deployToDevServer`, green): knk-core **1561**, knk-api-client **184**
  (2 skipped), knk-paper **1089** (14 skipped). knk-paper compiled in the cloud on 2026-10-02 (papermc/enginehub reachable);
  Gradle tuning in `~/.gradle/gradle.properties` per charter §1.4 may need re-creating in a fresh container.
- KNG-27 §5.5 items 1-6 are code-complete on `claude/road-navigation` (recorded in `IMPLEMENTATION_PLAN.md` "§5.5 status");
  `NavigationService.recheckDirect` exists (design §7). Workspace `main` has the progress report
  `docs/reports/2026-10-02-navigation-walkable-chain.md` with link 1's section.
What earlier links say this link must wire: nothing in knk-paper yet. Phase A is Bukkit-free and must leave knk-paper
behaviour unchanged. Deliver the types links 3-4 build on: `WalkGrid`, `MovementProfile`, `CellAccess` (cost-or-blocked,
`double extraCost(x,y,z)` + deny reason), `WalkSearch`, `WalkRequest`/`WalkResult`/`WalkPath`, `WalkPathfinder`
(design §3). The cell source the search reads must be something knk-paper can later back with captured chunks
(`SurfaceGrid`/`BlockProbe` are the existing ports; ladder and door cells need flags `CompactSpans` does not store
today — keep the core API able to express them, link 3 does the capture).
Phase-specific reading: `LAST_MILE_PATHFINDING.md` §2 (reuse table), §3, §4 (walkability rule incl. drops, doors,
water, ladders), §5 (search, budgets), §6 (`CellAccess` semantics only — adapters are link 3), §12 (core fixtures),
§13 (`MovementProfile` seam, `HEADROOM` → profile). Code: `knk-core/.../roads/build/SpanGrid.java` (`isSpan`,
`neighbourDy`, `neighbour`, `stepAllowed`, `cornerPath`, `HEADROOM`), `PassabilityRules.java`, `SurfaceGrid.java`,
`GateCells.java`, `util/BlockKey.java`, `util/BlockProbe.java`, `roads/route/AStarRouter.java` (pattern only);
tests `SpanGridTest`, `PassabilityRulesTest` (fixture style).
Order: (1) extraction commit — `WalkGrid` from `SpanGrid` with the road-material test left in `SpanGrid`, `SpanGrid`
delegates, existing tests green and unchanged (the proof); (2) `PassabilityRules` additions with tests; (3) the
search and its types; (4) fixtures per §12, incl. the 96×96 open-field timing recorded in the report and the design's
§10 "Phase A status" note.
Open flags that affect this link: decision §11-5 (no partial path) is agreed but awaits a live test — implement
`FALLBACK`/`NO_PATH`, no partial paths. Drop penalty 10/block, max drop 3, door +3, water ×3, ladder 2.0/block are
decided (§4, §11).
Known risks: the extraction must not change road-builder output (knk-core build tests are the guard); keep the
search Bukkit-free; the developer may commit to `claude/road-navigation` while you work — merge it before the final push.
Next after you: link 3 — KNG-51 Phase B.
