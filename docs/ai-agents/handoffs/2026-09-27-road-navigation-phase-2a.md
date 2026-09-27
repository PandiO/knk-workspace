Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 2a — knk-plugin core: shared extractions (R1, R2, R3, R4, R6) + Bukkit-free guard
test** from docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests, commits, push to
`claude/road-navigation`, plan status block, progress report, handoff), as **link 2** of the chain.

State you start from:
- **Phase 1 is done** (link 1, 2026-09-27): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master`
  `ccc8c02`), CI green, 1627 tests passing (+103) with the 5 known failures. Its status block in the plan (under
  "Phase 1 — knk-web-api") documents the API contract under "What later phases must wire" — you don't need it for
  2a, but Phase 2e will.
- **knk-plugin:** `claude/road-navigation` does **not** exist yet — create it from `origin/main` (`eb1d68c`,
  lootboxes merge; fetch first, trunk may have moved) and push it with `-u` (charter §1.2). Nothing of road
  navigation is in the plugin yet.
- **knk-web-app:** untouched; not needed for this phase.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 2a section, refresh the summary table) and the tracker row in `docs/ACTIVE_SESSIONS.md` ("Road navigation
  (KNG-27) — implementation chain", already naming Phase 2a as in progress — update its file list/status as you go).
- **Baselines to record before changing anything:** `./gradlew :knk-core:test` (and `./gradlew build -x
  deployToDevServer` if the network allows) — the plan says all green; write the exact counts in your status block.

What earlier phases say Phase 2a must wire: nothing — Phase 1 is server-side only. Your extractions are consumed by
2b/2c/2d (BlockKey, Polygon2D, closedFootprint, GateStateListener, DomainAccessEvaluator); keep the public names
exactly as plan §2 rows R1, R2, R3, R4, R6 spell them, so the later links can code against them without reading
your diff.

Phase-specific reading: plan §0, §1, §2 rows R1-R6 (and R7 for context), "Phase 2 → 2a" (all six items), §7 risk
row "KNG-17 merge conflicts" (keep the R6 extraction minimal: move the two private methods, delegate); DESIGN §4
(plugin architecture, where `C/roads/` and `C/navigation/` will live) and §6.7 (what `DomainAccessEvaluator` feeds
later). Existing tests to keep green untouched except imports: `knk-core/src/test/java/.../core/gates/
{GateSpatialIndexTest,GateFrameCalculatorTest,GateFrameCalculatorRegionModeTest,GateManagerTest}.java`.
`SimpleRegionTransitionService` has **no tests** — write characterisation tests first (2a item 5).

Open flags that affect this phase: none from Phase 1. Watch: `knk-core` has `paper-api` on its compile classpath,
so the compiler won't stop a `org.bukkit` import in the new files — the guard test (2a item 6) must. KNG-17
(`origin/claude/teleport`) also edits `SimpleRegionTransitionService.previewAccess`; don't touch that method, and
note in your status block that the teleport merger must point `previewAccess` at the evaluator (R6).

Known risks:
- **Network:** in link 1's container both `https://repo.papermc.io/repository/maven-public/` and
  `https://maven.enginehub.org/repo/` returned HTTP 000 (blocked by the proxy) on 2026-09-27 ~19:45 UTC, despite
  charter §9 saying they were allowed. Re-check per charter §1.5. If still blocked, Gradle can't resolve `paper-api`,
  so use the scratch-build fallback of plan §0.4 for knk-core (javac + JUnit console launcher from Maven Central,
  stub `org.bukkit.util.Vector` for `C/gates/*`, `C/util/VectorMath`, `C/util/CoordinateParser`,
  `C/domain/gates/{BlockSnapshot,CachedGateDoor}`), and say "not compiled with Gradle" in the status. Not a blocker.
- **Toolchain:** Java 21 is expected (`java -version`); the Gradle wrapper needs to download Gradle — check
  `services.gradle.org` reachability too. Link 1 found `apt-get` from the Ubuntu archive works if you need packages.
- **Behaviour changes are defects here:** every extraction must leave the old callers' tests green without edits
  (plan §0.2). One commit per extraction (R1, R2, R3, R4, R6 = five commits, plus the characterisation-test commit
  and the guard-test commit).

Next after you: **Phase 2b** (survey maths — `C/roads/survey/`). Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-2b.md` and start it per charter §6.
