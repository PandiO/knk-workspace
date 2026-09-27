Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 2b — knk-plugin core: survey maths (`C/roads/survey/`: `SurveySample`,
`SurveyStats`, `ProfileLearner`)** from docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests,
commits, push to `claude/road-navigation`, plan status block, progress report, handoff), as **link 3** of the chain.

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`), 1627 tests
  (+103) with the 5 known failures. Its "Phase 1 status" block documents the API contract under "What later phases
  must wire" — for you the relevant line is: profile/survey `stats` is an **opaque JSON object** on the API side
  (Jackson `JsonNode`/`Map` in Phase 2e; `null` on a profile PUT keeps it). The bootstrap profile *Default road* has
  `StatsJson = {}`. So **you define the `StatsJson` shape** with `SurveyStats` (plan D5) — keep it flat, string
  material names, integer counts, a `version` field, and document it in your status block for 2e and Phase 5.
- **Phase 2a is done** (link 2, 2026-09-27): knk-plugin `claude/road-navigation` **`db962a4`** (cut from `main`
  `eb1d68c`; 7 commits `35252c7` … `db962a4`), knk-core **1085 tests green** (baseline 1024) — via the plan §0.4 scratch
  build, **not Gradle** (see risks). It added `C/util/BlockKey`, `C/util/Polygon2D`, `GateManager.closedFootprint`,
  `GateStateListener`, `C/regions/DomainAccessEvaluator` and `ArchitectureGuardTest`. Your new package `C/roads/` is
  **already scanned by the guard**: any `org.bukkit` import or reference in a code line under `C/roads/**` fails
  `ArchitectureGuardTest`. Nothing in 2a is an input to 2b (2b is pure maths); details in the plan's "Phase 2a status".
- **knk-web-app:** untouched; not needed.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 2b section, refresh the summary table — 2b row is "in progress (link 3)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 2b in progress with `core/roads/survey/*`; update as you go).
- **Baseline to record:** knk-core 1085 tests at `db962a4` (re-measure with the scratch build before changing anything;
  `./gradlew :knk-core:test` will fail on `paper-api` resolution — record that too).

What earlier phases say Phase 2b must wire: nothing — 2b produces pure classes that 2c (`ProfileMatcher` uses the
learned profile roles/widths), 2e (`SurveyStats` ↔ `StatsJson`) and Phase 3 (`RoadSurveySession` produces
`SurveySample`s, the admin command runs `ProfileLearner` and PUTs) consume. **Keep the names exactly as plan §2b spells
them** (`SurveySample`, `SurveyStats`, `SurveyStats.merge(SurveyStats)`, `ProfileLearner.learn(SurveyStats) →
ProposedProfile`) and put every threshold in named constants at the top of `ProfileLearner`.

Phase-specific reading: plan §0, §1 (D5 especially), §2 (R28 `SiegeFloor.floorY` if you need a floor snap — you
probably don't in 2b), "Phase 2 → 2b" (the whole section: sample record fields, stats buckets 0-1 / 2-5 / 6-7,
run-end counts, overlay counts, width histogram, sample count, merge; learner rules with thresholds 0.6 / 15% / 2× /
5% / 10% / 1% / 5th-95th percentile; the four required test scenarios a-d), "Phase 2a status" (guard test, scratch
build recipe). DESIGN §5.1 (profiles, material roles Surface/Edge/Accent/Overlay, ambiguity), §5.3 (survey walk:
cross-section −7…+7, what a sample records, what "run" and "run end" mean), §3.1 (`RoadProfile` fields the
`ProposedProfile` must map onto: class, materials with roles + ambiguous flag, `WidthMin`/`WidthMax`), §3.2
(`RoadSurvey`). Web-api `W/Dtos/RoadDtos.cs` (`RoadProfileDto`, `RoadMaterialDto`, `RoadSurveyDto`) on
knk-web-api `claude/road-navigation` if you want to align `ProposedProfile`'s field names with the DTOs 2e will map to
(read-only; don't change the API).

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): the exact `StatsJson` layout, how
`ProposedProfile` represents "ambiguous" materials (DESIGN §5.1 says a flag per material), rounding of percentile widths
(integers, ≥ 1). Take the reversible default and number it in your status block.

Known risks:
- **Network (same as links 1 and 2):** `https://repo.papermc.io/repository/maven-public/` and
  `https://maven.enginehub.org/repo/` return HTTP 000 (proxy 403 on CONNECT, policy denial) — re-check per charter
  §1.5; if still blocked, use the scratch build (recipe in the plan's "Phase 2a status" block: throwaway Gradle
  project, real `knk-core/src/{main,test}/java` as source sets + `stub/org/bukkit/util/Vector.java`, Maven Central
  only, `workingDir = knk-core`). Maven Central answers **429** to Gradle's parallel downloads through the proxy:
  put `org.gradle.workers.max=2`, `systemProp.org.gradle.internal.repository.max.tentatives=12`,
  `systemProp.org.gradle.internal.repository.initial.backoff=2000` in `~/.gradle/gradle.properties` before the first
  run, then use `--offline`. Say "not compiled with Gradle" in your status if that's how you tested. Not a blocker.
- **Toolchain:** Java 21 is present (`openjdk 21.0.10`), Gradle wrapper 8.10.2 downloads fine (`services.gradle.org`
  reachable), `apt-get` works if you need anything.
- **Scope:** `C/roads/survey/` only — no builder (2c), no API client (2e), no paper code. Don't touch `C/gates`,
  `C/regions` (2a is done; KNG-17 edits `SimpleRegionTransitionService.previewAccess` — leave that file alone).
- **Bukkit-free:** materials are plain `String` names (`Material.name()` is applied on the paper side in Phase 3);
  the guard test enforces it.
- **Tests are the deliverable:** the plan's four scenarios (a) stone-brick road with andesite kerbs on grass →
  Surface/Edge/terrain split, (b) 1-wide gravel path in a forest, (c) cobblestone kerb next to a cobblestone house
  floor → ambiguous, (d) merge(two surveys) == learn on the concatenation — plus round-trip of `SurveyStats` through
  its JSON form (use Jackson, already a knk-core dependency, or Gson — both are on the classpath).

Next after you: **Phase 2c** (builder — `C/roads/build/`; large; may be split at commit boundaries per charter §5).
Write `docs/ai-agents/handoffs/<date>-road-navigation-phase-2c.md` and start it per charter §6.
