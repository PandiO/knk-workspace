# Off-road navigation and landmarks chain — progress report

**Status:** Running (2026-11-17) · **Last updated:** 2026-11-17

**Issue:** [PandiO/knk-workspace#698](https://github.com/PandiO/knk-workspace/issues/698), links
[#703](https://github.com/PandiO/knk-workspace/issues/703) (L1), [#704](https://github.com/PandiO/knk-workspace/issues/704) (L2),
[#710](https://github.com/PandiO/knk-workspace/issues/710) (L3), [#711](https://github.com/PandiO/knk-workspace/issues/711) (L4),
[#705](https://github.com/PandiO/knk-workspace/issues/705) (L5), [#706](https://github.com/PandiO/knk-workspace/issues/706) (L6),
[#707](https://github.com/PandiO/knk-workspace/issues/707) (L7), [#708](https://github.com/PandiO/knk-workspace/issues/708) (L8),
[#709](https://github.com/PandiO/knk-workspace/issues/709) (L9), [#712](https://github.com/PandiO/knk-workspace/issues/712) (L10)
**Charter:** [handoffs/NAVIGATION_OFFROAD_CHAIN.md](../ai-agents/handoffs/NAVIGATION_OFFROAD_CHAIN.md).
**Spec:** [specs/navigation-offroad/DESIGN.md](https://github.com/PandiO/knk-workspace/blob/next/docs/specs/navigation-offroad/DESIGN.md)
on `next` (Decided 2026-11-17).

## 1. Waiting for the developer

1. **L1 (#703) live measurements:** L1 is in `next` (plugin `04506d8c`). Deploy from `next`, add
   `max-chunks-per-request: 64` under `navigation.walk:`, run smoke guide § 1 (also on #703; long legs need
   `/forceload`) and fill `docs/reports/2026-11-17-offroad-navigation-measurements.md`. L5 waits for its budgets; if
   option A fits the keep, the coordinator asks you before L6 (O32).
2. **Decision to confirm (from the NPC chain's comment on #698, 2026-11-17):** NPC use of the long walks (walk links
   and clusters, O32) moves from "after v1" into v1, as the phase after phase 3. It has no sub-issue or link in this
   chain yet; the spec's § 14 and § 15 need the change in a docs PR. Proposal: a design follow-up (sub-issue of #698)
   once L6 is designed in detail; not scheduled in this chain until you say so.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 0 measurements | #703 | Merged into next (2026-11-17); waits for the developer's live measurements and the filled report | knk-plugin `claude/offroad-measurements` `71a43bc1`; knk-workspace `claude/offroad-measurements` `2337d3a4` | [knk-plugin#68](https://github.com/PandiO/knk-plugin/pull/68) → `next` `04506d8c`, [#717](https://github.com/PandiO/knk-workspace/pull/717) → `next` `a6240f5d` | green (build, paper-boot on `71a43bc1`) | create_session `session_01R1w2Uub8CZ7NuvatVUifP7` (2026-11-17) |
| L2 Phase 1 shared shaping package | #704 | Merged into next (2026-11-17) | knk-plugin `claude/offroad-shape-package` `0d0cff84`; knk-workspace `claude/offroad-shape-package` `ef17bcc3` | [knk-plugin#69](https://github.com/PandiO/knk-plugin/pull/69) → `next` `c45c16bb`, [#718](https://github.com/PandiO/knk-workspace/pull/718) → `next` `d8ebd9f4` | green (build, paper-boot) | create_session `session_01R1w2UwTnENVNKzfaXudBUh` (2026-11-17) |
| L3 Phase 6.1 trail corners | #710 | Running (started 2026-11-17 23:05 from plugin `next` `c45c16bb`) | `claude/offroad-trail-corners` | — | — | create_session `session_01R1w2Uv9tRTPyjZsFJNWGec` (2026-11-17) |
| L4 Phase 6.2 anchored particles, winding back | #711 | Not started (gate: L3 in `next`) | `claude/offroad-trail-cursor` | — | — | — |
| L5 Phase 2 walk links | #705 | Not started (gate: L1 done, L4 in `next`) | `claude/offroad-walk-links` | — | — | — |
| L6 Phase 3 hierarchical walk search | #706 | Not started (gate: L5 in `next`; O32 question first if L1 says option A fits) | `claude/offroad-hierarchical` | — | — | — |
| L7 Phase 4 route modes | #707 | Not started (gate: L5 in `next`) | `claude/offroad-route-modes` | — | — | — |
| L8 Phase 5.1 landmark entity | #708 | Waiting (destination engine #96, #103, #69 not in `next`, O27) | `claude/offroad-landmarks` | — | — | — |
| L9 Phase 5.2 landmark weights | #709 | Not started (gate: L7 and L8 in `next`) | `claude/offroad-landmark-weights` | — | — | — |
| L10 Phase 7 plaza lines | #712 | Not started (gate: L3 and L4 in `next`) | `claude/offroad-plaza-lines` | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   into `next` after the checks), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and
   knk-web-app (checked 2026-11-17). Alternative: the old rules (developer merges); not applicable.
2. **Model for link sessions.** Chosen: `claude-opus-5-5`, the coordinator's own model (`get_session`), for every link,
   because the design leaves no model choice and the tier:3 links change game feel in shared navigation code.
   Alternatives: (a) a smaller model for the tier:1/tier:2 links (L1, L7); rejected for now, the counters sit in the
   walk search's hot loop and L2 is a 120-file move where a wrong import costs a red `next`; (b) per-link choice later;
   kept open.
3. **L2 waits for NPC B5 (#699) (overlap, § 2.4 of the skill).** Checked 2026-11-17 on knk-plugin: the only NPC branch
   not in `next` is `claude/npc-movement-b5` (`d402d865`, 2 commits, no PR yet). It changes
   `core/npc/nav/group/GroupPath.java` (adds `import ...core.npc.nav.NavGeometry` and new code on `NavWorld`,
   `NavPoint`, `NavGeometry`), `NavGroup.java`, `GroupPathTest`, `paper/scenario/SnapshotReplay`,
   `NpcSnapshotReplayScenario`. L2 moves exactly those types to `core/navigation/shape` and rewrites the import lines of
   the same files, so the change is on the same lines and B5's new code would not compile after L2. Chosen: L2 starts
   once B5 is merged into `next` (the order the developer agreed with the NPC chain on 2026-11-17, its report
   decision 44 and its comment on #698), and L2 re-runs the § 3.4 import check on that `next`. Alternatives: (a) start
   L2 now and let B5 merge `next` afterwards; rejected, it breaks B5's compile and conflicts with an active session;
   (b) start L2 now on a branch that only lands after B5; rejected, it would need a non-mechanical rebase of a 120-file
   move.
4. **Route for L1.** Chosen: `create_session` (variant A), because L1 needs one repository besides knk-workspace
   (knk-plugin). Alternative: a subagent; kept as the fallback if the attach is refused.
5. **One plugin navigation link at a time.** L1 adds counters to `core/roads/walk/WalkSearch` and the walk capture
   (navigation code), and the skill allows one running link per component repo. Chosen: L2 starts when B5 is in
   `next` **and** L1's plugin PR is merged into `next` (L1's session is then done; only the developer's live
   measurements remain, which are not a running link), so "L1 and L2 in parallel" (O23) holds for the developer's
   measurement time without two sessions in knk-plugin. Alternatives: (a) L2 beside a running L1 when their files are
   disjoint; rejected, the prompt's "one plugin navigation link at a time" and the skill's one link per repo; (b) L2
   only after L1 is done (report written); rejected, it would wait on the live work for nothing.

6. **L1 merged into `next` (2026-11-17).** § 6 checks held: heads matched, `build` and `paper-boot` green on
   `71a43bc1`, scope inside #703 (plus `NavigationService`, logged by the link as decision 3, additive), no Codex
   findings (usage limit). The plugin branch was 4 commits behind `next` (B5) with a clean merge, so the PR was merged
   as is. The workspace PR conflicted in `docs/CHANGELOG.md` (B5's entry beside L1's): mechanical, resolved on the
   feature branch by merging `origin/next` and keeping both entries (`2337d3a4`), then merged. Alternatives: (a) send
   it back to the link; rejected, a two-entry changelog conflict is mechanical (skill § 7.3).
7. **L2 started (2026-11-17 22:12).** B5 is in `next` (`55ea7df3`, rev-list count 0) and L1's plugin PR is merged, so
   the hold of decision 3 is lifted. The NPC chain's coordinator confirmed it starts no `core/npc/nav` link until L2
   is merged. L2 re-runs the § 3.4 import check on the current `next` (B5's `GroupPath.addShaped` added uses of
   `NavGeometry.straightWalkable` and `HopPlanner.surfaceNear`).
8. **L2 merged into `next` (2026-11-17 23:05).** § 6 checks held: heads matched, branch contained `next`, `build` and
   `paper-boot` (every `npc-*` scenario) green on `0d0cff84`, `next` CI green after L1, the diff checked as a pure move
   (12 renames, import rewrites, `HopPlanner` helpers delegating to `NavGeometry`, `PlazaCrossing` extracted), tests
   +1 (the package guard), no Codex findings (usage limit). The NPC chain's coordinator is told (C1 may start from
   `next` `c45c16bb`). Alternative: wait for a Codex review; rejected, the developer's usage-limit rule applies.
9. **L3 started (2026-11-17 23:05).** Gate "L2 merged into `next`" checked (merge commit `c45c16bb`). The prompt
   requires the flag-off identity of the walk search's costs (a test) and keeps `TrailRenderer`/`NavigationService`
   changes additive for L4. Overlap: the NPC chain's C1 (#700) may run beside L3 in `core/npc/nav`; L3 touches no
   `core/npc/nav` file and changes to shape-package classes stay additive and are reported.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Phase 0: walk search and capture counters, measurement steps (#703)

1. **Scope done.**
    1. knk-plugin knk-core `core/roads/walk/`: `WalkSearchStats` on every `WalkSearch` result (expansions, cells
       touched, search ns from an injectable clock, the cap that ended the search, `lengthPruned`); `WalkResult.stats()`
       and `withStats`; `WalkMeasurements` (last 512 searched requests, max/p95/p50, recent list, reset, status lines).
       Two clock reads per search, nothing added inside the expansion loop; `toString()` unchanged.
    2. knk-plugin knk-paper: `WalkSnapshotService` reports per capture chunks, cache hits, main-thread µs and wait
       (`WalkCapture.stats()`); `WalkLegPreparer` completes with `NavigationService.PreparedWalk`; `NavigationService`
       records search, capture and queue time per searched request on the walk thread; `/knk road status` shows
       `walk search:`, `walk cost:` (3 lines) and `walk recent:` (5 lines) under `walk paths:`; `/knk road status
       reset`; new key `navigation.walk.max-chunks-per-request` (default 64, the former constant; 1 to 1024).
    3. knk-workspace: smoke-test guide § 1 (nine steps, the developer's measurement run), report skeleton
       `docs/reports/2026-11-17-offroad-navigation-measurements.md` (DESIGN § 9.1 to § 9.3 as tables, the three
       questions with proposed decision rules), plugin configuration reference, changelog (Unreleased), DESIGN § 9.2
       note; the steps also as a comment on #703.
2. **Commits and heads.** knk-plugin `claude/offroad-measurements` at `71a43bc1` (2 commits, base `next` at
   `187f97ec`); knk-workspace `claude/offroad-measurements` at `c275c84d` (1 commit, base `next` at `b9c0a7fc`).
3. **PRs.** [PandiO/knk-plugin#68](https://github.com/PandiO/knk-plugin/pull/68),
   [PandiO/knk-workspace#717](https://github.com/PandiO/knk-workspace/pull/717), base `next`, both
   `Part of PandiO/knk-workspace#703` (the issue stays open until the report is filled). Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`): baseline on `next` `187f97ec` knk-core 3 011, knk-paper
       2 891 (18 skipped), knk-api-client 344 (2 skipped); result knk-core 3 028 (+17), knk-paper 2 904 (+13, 18
       skipped), knk-api-client 344 (2 skipped); no failures. PR CI: `build` green on the first push; the runs for
       the head were still running when this block was written (the coordinator checks them).
    2. knk-workspace: docs only; every relative link added resolves on the branch.
    3. Known reds: none.
    4. Codex: at its code-review usage limit on both PRs (its comments of 2026-11-17); finished without its review
       (developer decision 2026-11-14), said so on both PRs. No findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Output home.* Chosen: `/knk road status` (the sub-issue says so), with `/knk road status reset` so one scene
       is read at a time. Alternatives: (a) a separate `/knk road walkstats` subcommand; not needed; (b) a log file
       per request; harder to read in game, and logs grow.
    2. *How option A's long legs are measured.* Chosen: config only: `navigation.max-snap-distance` raised to 450 on
       the dev server (direct mode walks to any point destination within it) plus the new key
       `navigation.walk.max-chunks-per-request` (a 400 block diagonal leg needs about 441 chunks; the old limit was a
       constant 64). Default 64, so nothing changes until a test server raises it. Alternatives: (a) a staff probe
       command `/knk road walkprobe <x y z>` running one search with given caps; new behaviour outside the link's
       scope; (b) raising the constant; it would change production; (c) measure only up to 64 chunks; question 1
       would stay unanswered for the long legs.
    3. *Where requests are recorded.* Chosen: in `NavigationService` on the walk thread (where the search runs and
       the queue wait is known), a file beyond the prompt's list (counters, capture service, status command). The
       change is additive (a record, one method, three lines in `requestWalk`). Alternatives: (a) record inside
       `WalkSearch`; it does not know the capture or the queue; (b) a decorating `WalkPathfinder`; it cannot see the
       capture counters either.
    4. *Capture time of a shared chunk.* Chosen: a chunk two requests wait for counts for both, so each request shows
       its own cold cost. Alternative: count it once for the first request; a request's cost would depend on timing.
    5. *Percentiles.* Chosen: nearest rank over the last 512 searched requests. Alternatives: (a) all-time
       aggregates; one scene could not be read alone (reset covers that); (b) a histogram; more code for no gain at
       these counts.
    6. *Decision rules in the report* (proposals for the developer, § 4 and § 5 of the report): option A fits the
       keep when run 2 finds the longest route without a cap within 400 ms, the capture keeps the tick under 50 ms
       and the wait is at most 2 s; cluster size from the µs per expansion and the edges a first request computes.
       Alternative: leave the questions open without rules; the developer would have to derive them after the run.
6. **Out of scope, noted.** None filed. Follow-ups for the docs issue at merge: the navigation admin guide could
   mention `/knk road status reset`; the feature register has no off-road row yet.
7. **Blockers.** None. The live run is the developer's (not a blocker).
8. **At merge / what the developer must do.**
    1. Merge knk-plugin#68 and #717 into `next` (the coordinator).
    2. Deploy: add under `navigation.walk:` and restart:

       ```yaml
           max-chunks-per-request: 64
       ```

    3. Run the measurement steps of the
       [smoke test § 1](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/navigation-offroad-smoke-test.md#1-phase-0-measurements-703-tier1)
       (also on #703) and fill the report; then answer its three questions (charter § 2.3; O32 if option A fits).
    4. Optionally comment `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L5 and L6: the budgets come from the filled report § 3.3; `WalkMeasurements` and `/knk road status` are the
       place to add link and cluster counters (DESIGN § 9.3.5).
    2. Cloud builds: Maven Central rate-limited this session (random 404 and 429 on jars). A local Gradle init script
       (`~/.gradle/init.d/`, not committed) that points Maven Central at Google's mirror
       `https://maven-central.storage-download.googleapis.com/maven2/` fixed it.
    3. Walk legs use loaded chunks only; any live measurement of long legs needs `/forceload`.

### 4.2 L2 — Phase 1: shared shaping package `core/navigation/shape` (#704)

1. **Scope done.**
    1. knk-plugin knk-core: `Corridor`, `CorridorShaper`, `FreeWidth`, `PlazaLine` (from `core/npc/nav/corridor/`) and
       `NavWorld`, `NavPoint`, `NavGeometry` (from `core/npc/nav/`) moved with `git mv` to `core/navigation/shape/`;
       `RoadPlanner.PlazaCrossing` became the top-level record `shape/PlazaCrossing`; imports rewritten everywhere
       (121 files: 107 modified, 12 renames, 2 new, `PlazaCrossing` and the package description).
    2. § 3.4 leftovers: `HopPlanner.floor`, `feet`, `floorNear` and `CONTINUITY_RANGE` live in `NavGeometry`;
       `HopPlanner` delegates, so every NPC call site is unchanged and `NavGeometry` no longer imports `HopPlanner`.
       `GridWorld` is a public test fixture in the shape test package, used by the four moved tests and by
       `LocalLegSearchTest`.
    3. `ArchitectureGuardTest.sharedShapingPackageDoesNotUseNpcPackages`: `core/navigation/shape` references nothing
       from `core/npc` (A26). The shape package is also inside the existing Bukkit-free guard (`navigation`).
    4. knk-workspace: `docs/architecture/npc-navigation.md` § 1 (a "Shape" layer row, the port table) and § 12 (package
       note, `shape/…` paths); smoke test § 2 (what was built, 4 of 4 steps tagged automated, a new step 4 for the
       package rule); DESIGN § 3.4.4 (the re-run import check); CHANGELOG (Unreleased).
2. **Import check re-run on `next` `04506d8c` (prompt § 2.3), differences from `e69dba6`.**
    1. The same 84 files import the moving classes (explicit or fully qualified imports) at both commits; no file was
       added or dropped.
    2. B1 to B4's `Trail`, `JumpDetector`, `crowd/CrowdControl`, `NpcSnapshotReplayScenario`,
       `NpcStairhouseClimbScenario` and `ClimbWatch` already existed at `e69dba6`, so the design session's throwaway
       check covered them. Of these the move changed `Trail` (same package as the primitives, now imports them),
       `CrowdControl`, `ClimbWatch` and `NpcSnapshotReplayScenario`; `JumpDetector` and `NpcStairhouseClimbScenario`
       name no moving class (they reach it through other NPC classes) and are unchanged.
    3. Since `e69dba6` only B5 (`55ea7df3`) and L1 changed code; B5's `GroupPath.addShaped` added calls to
       `NavGeometry.straightWalkable` (moved), `HopPlanner.surfaceNear` (stays in `HopPlanner`) and `HopPlanner.feet`
       (now delegating). L1 touched no moving class.
    4. The design session counted 120 files and 11 renames; this move has 121 files and 12 renames (the package
       description of the new package is new; `GridWorld` and the four tests move as renames).
3. **Commits and heads.** knk-plugin `claude/offroad-shape-package` at `0d0cff84` (1 commit, base `next` `04506d8c`);
   knk-workspace `claude/offroad-shape-package` at `ef17bcc3` (1 commit, base `next` `a6240f5d`).
4. **PRs.** [PandiO/knk-plugin#69](https://github.com/PandiO/knk-plugin/pull/69) (`Closes PandiO/knk-workspace#704`),
   [PandiO/knk-workspace#718](https://github.com/PandiO/knk-workspace/pull/718) (`Part of`), base `next`. Not merged.
5. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`): baseline on `next` `04506d8c` knk-core 3 032, knk-paper
       2 904 (18 skipped), knk-api-client 344 (2 skipped); result knk-core 3 033 (+1: the new guard test), knk-paper
       2 904 (18 skipped), knk-api-client 344 (2 skipped); no failures. Per class the lists are the same apart from
       the four moved test classes (`CorridorTest`, `CorridorShaperTest`, `FreeWidthTest`, `PlazaLineTest`), which
       changed package only.
    2. Paper-boot NPC scenarios: not run locally; relied on the PR's CI: `build` and `paper-boot` green on `0d0cff84` (both the push and the pull-request runs; `paper-boot` runs every `npc-*` scenario, 2026-11-17 22:41).
    3. knk-workspace: docs only; no new relative links, anchors unchanged.
    4. Known reds: none.
    5. Codex: at its code-review usage limit on both PRs (its comments of 2026-11-17 22:22); finished without its
       review (developer decision 2026-11-14), said so on both PRs. No findings to handle.
6. **Decisions (DESIGN § 4.3).**
    1. *`LocalLegSearch`.* Chosen: stays in `core/npc/nav/corridor/`, as O11 and § 3.4 say (NPC legs on the main
       thread, uses `HopPlanner` and `LocalLeg`; moving it would pull NPC classes into the shared package or need a
       new port). Alternatives: (a) move it and its `HopPlanner`/`LocalLeg` uses behind an interface; new code in a
       no-behaviour-change link, and the player side has its own walk search; (b) move it with an import of
       `core/npc`; breaks A26.
    2. *Where the floor helpers go.* Chosen: into `NavGeometry` as O11 names them (`floor`, `feet`, `floorNear`,
       `CONTINUITY_RANGE`), `HopPlanner` keeps delegating methods and its constant, so no call site changes and the
       merge stays mechanical for the NPC chain. Alternatives: (a) move only `floorNear` and `CONTINUITY_RANGE` (the two
       `NavGeometry` uses); `feet`/`floor` would then live where the player side cannot use them; (b) rewrite every
       `HopPlanner.feet`/`floor` call site to `NavGeometry`; 43 more changed call sites in NPC files for no gain.
    3. *Tests of the moved classes.* Chosen: `CorridorTest`, `CorridorShaperTest`, `FreeWidthTest`, `PlazaLineTest` and
       `GridWorld` move to the shape test package (they test package-private parts of their classes);
       `NavGeometrySurfaceTest` stays in the NPC test package because it is built on the NPC fixture `FakeNavWorld`.
       Alternatives: (a) leave all tests in place; they would need the moved classes' package-private members made
       public; (b) also move `NavGeometrySurfaceTest` and `FakeNavWorld`; `FakeNavWorld` serves 18 other NPC test files.
    4. *The A26 check.* Chosen: a test method in the existing `ArchitectureGuardTest` (a plain source scan; the prompt
       allows one where a package-rule test exists). Alternative: none; ArchUnit is not on the classpath and the
       prompt rules out new infrastructure.
    5. *Older docs naming the old paths.* Chosen: updated the living docs (architecture § 1 and § 12) and added
       DESIGN § 3.4.4; left `docs/specs/npc-platform/IMPLEMENTATION_PLAN.md` (Phase 4c) as it is, because it is the
       dated plan of what was built then, and DESIGN § 3.4.1 to 3.4.3 (the code check at `e69dba6`). Alternative:
       rewrite the paths there too; it would falsify what those sections record.
7. **Out of scope, noted.** None filed.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. Merge knk-plugin#69 and #718 into `next` (the coordinator). No `config.yml` key, no migration, no admin step.
    2. Smoke test § 2 is fully automated; on the next dev deploy, a glance at the startup log is enough.
    3. Optionally comment `@codex review` on both PRs once the Codex limit resets.
10. **Notes for later links.**
    1. L3 (6.1) and the NPC chain's C1: the shared types are in `net.knightsandkings.knk.core.navigation.shape`;
       `HopPlanner.feet`/`floor`/`floorNear` still work but `NavGeometry` holds them, so new code in the shape package
       uses `NavGeometry`. `GridWorld` (shape test package, public) is the test world for corridor and shaping tests.
    2. `ArchitectureGuardTest` fails as soon as a file in `core/navigation/shape` names `core.npc`; a `WalkTerrainNavWorld`
       for the player side belongs in core outside `core/npc`.
    3. The Google Maven Central mirror init script of L1's note 9.2 was used again here; the build ran without 429s.
