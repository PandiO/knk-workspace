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
3. **L3 (#710) live test (tier:3):** L3 is in `next` (plugin `54dfe8d7`). Deploy with `navigation.guidance-v2: false`
   and under `navigation.walk:` `clearance-cost: 5`, `wall-clearance: 0.8`, `curve: true`; then set
   `guidance-v2: true`, restart and follow smoke test § 8 (manual steps 1, 3 and 6: the stair house, a keep corner and
   a 1-wide door, `/knk road status` with the tick time). It can be combined with L4's test once L4 is in `next`.
2. **Decision to confirm (from the NPC chain's comment on #698, 2026-11-17):** NPC use of the long walks (walk links
   and clusters, O32) moves from "after v1" into v1, as the phase after phase 3. It has no sub-issue or link in this
   chain yet; the spec's § 14 and § 15 need the change in a docs PR. Proposal: a design follow-up (sub-issue of #698)
   once L6 is designed in detail; not scheduled in this chain until you say so.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 0 measurements | #703 | Merged into next (2026-11-17); waits for the developer's live measurements and the filled report | knk-plugin `claude/offroad-measurements` `71a43bc1`; knk-workspace `claude/offroad-measurements` `2337d3a4` | [knk-plugin#68](https://github.com/PandiO/knk-plugin/pull/68) → `next` `04506d8c`, [#717](https://github.com/PandiO/knk-workspace/pull/717) → `next` `a6240f5d` | green (build, paper-boot on `71a43bc1`) | create_session `session_01R1w2Uub8CZ7NuvatVUifP7` (2026-11-17) |
| L2 Phase 1 shared shaping package | #704 | Merged into next (2026-11-17) | knk-plugin `claude/offroad-shape-package` `0d0cff84`; knk-workspace `claude/offroad-shape-package` `ef17bcc3` | [knk-plugin#69](https://github.com/PandiO/knk-plugin/pull/69) → `next` `c45c16bb`, [#718](https://github.com/PandiO/knk-workspace/pull/718) → `next` `d8ebd9f4` | green (build, paper-boot) | create_session `session_01R1w2UwTnENVNKzfaXudBUh` (2026-11-17) |
| L3 Phase 6.1 trail corners | #710 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 8) | knk-plugin `claude/offroad-trail-corners` `9dd3ee5f`; knk-workspace `claude/offroad-trail-corners` `daffbc1d` | [knk-plugin#70](https://github.com/PandiO/knk-plugin/pull/70) → `next` `54dfe8d7`, [#719](https://github.com/PandiO/knk-workspace/pull/719) → `next` `d07deabf` | green (build; paper-boot on re-run, #720) | create_session `session_01R1w2Uv9tRTPyjZsFJNWGec` (2026-11-17) |
| L4 Phase 6.2 anchored particles, winding back | #711 | In review (2026-11-18); waits for the coordinator's merge, then the developer's live test (tier:3, smoke § 9) | knk-plugin `claude/offroad-trail-cursor` `1925cf73`; knk-workspace `claude/offroad-trail-cursor` `cb7b55f8` | [knk-plugin#72](https://github.com/PandiO/knk-plugin/pull/72), [#722](https://github.com/PandiO/knk-workspace/pull/722) | green (build, paper-boot on `1925cf73`) | create_session `session_01R1w2UwkAiptAq4cPVFVBTS` (2026-11-18) |
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
10. **Overlap with NPC C1 (#700), 2026-11-17 23:06.** C1 started from `next` `c45c16bb` on `claude/npc-movement-c1`;
    its coordinator says C1 calls `WalkLegPreparer` and the walk search but edits no file in `core/roads/walk`,
    `paper/navigation` or `core/navigation/shape`, and asks first if it must. Chosen: L3 continues and keeps the
    public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder` and the shape classes stable (additions
    only), so both merges stay mechanical; told to L3. Alternatives: (a) pause L3 until C1 merges; rejected, the files
    are disjoint; (b) let L3 change signatures and fix C1 afterwards; rejected, it would break C1's compile.
11. **L3 merged into `next` (2026-11-18 00:43).** § 6 checks held: heads matched, branch contained `next`, `build`
    green, `paper-boot` green on re-run; the first runs crossed midnight UTC and failed only on the log rollover (all
    51 scenarios passed), filed by L3 as #720. Accepted the re-run as proof, because the failure was in the log check,
    not a test. Alternatives: (a) require a new commit; rejected, nothing to change; (b) fix #720 first; rejected, out
    of scope and the re-run is the documented workaround. Flag off by default with identity tests (A16), no Codex
    findings (usage limit), public signatures stable for C1. The NPC coordinator is told.
12. **`trail-leg-spacing` default (L4).** DESIGN § 7.6 says 1.5, § 7.2.2 and decision O20 say 3.0 (found by L3).
    Chosen: 3.0, because O20 is a recorded decision and § 7.2.2 states the rule; L4 corrects § 7.6 in its docs PR.
    Alternative: ask the developer; rejected, the decision log already settles it and the value is a config key.
13. **L4 started (2026-11-18 00:43).** Gate "L3 merged into `next`" checked (merge commit `54dfe8d7`).

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

### 4.3 L3 — Phase 6.1: walk-trail corners, clearance cost, shaping and curve (#710)

1. **Scope done.** Everything is behind `navigation.guidance-v2`, off by default.
    1. knk-core `core/roads/walk/`:
        1. `MovementProfile` gets `clearanceCost` (default 0) and `wallClearance` (default 0.8); the old constructors keep them.
        2. `WalkClearance`: the clearance of a standing cell, judged by the clearance map's rule: a column is an obstacle when it has no standing cell within a step of the cell's floor.
        3. `WalkSearch`: when the clearance cost is above 0 it replaces the wall cost; at 0 the search is unchanged.
        4. `WalkTerrainNavWorld`: a Bukkit-free `NavWorld` over the captured terrain, with standing cells as the search sees them and access respected.
        5. `WalkPathShaper`:
            1. Runs are cut at ladders and drops.
            2. Each run is shaped by `CorridorShaper` (strip 8, wall-clearance, hard minimum 0.35).
            3. Parts are cut where a stair turns over itself and chained from the end of the previous part.
            4. Corners are drawn as checked curves.
    2. knk-paper:
        1. config: `navigation.guidance-v2` (false), `walk.clearance-cost` (5), `walk.wall-clearance` (0.8) and `walk.curve` (true). `WalkConfig.profile(boolean)` returns today's profile exactly when the flag is off.
        2. `WalkLegPreparer` builds requests with that profile; `KnKPlugin` passes the flag.
        3. `NavigationService`:
            1. The walk thread shapes the found or partial path from the request's own terrain, and the leg draws the trail.
            2. If shaping fails, or nothing comes out of it, the leg draws the cells.
            3. `/knk road status` ends the `walk paths:` line with `shaped N (mean X ms)`.
        4. `TrailRenderer`: doc only. The spacing stays 3.0 and the leg colour stays (O20). The road trail is unchanged.
        5. A new paper-boot scenario `walk-trail-stairhouse`; `MIN_SCENARIOS` is now 51.
    3. The shape package is not changed (A26).
    4. knk-workspace:
        1. Smoke test § 8: eight steps, six automated (three in part).
        2. Plugin configuration reference § 4.15 and § 2.1.
        3. CHANGELOG (Unreleased).
        4. DESIGN § 7.1.6 "as built".
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-trail-corners` at `9dd3ee5f`: three commits (core, paper, scenario) on `next` `c45c16bb`.
    2. knk-workspace `claude/offroad-trail-corners` at `daffbc1d`: one commit on `next` `d8ebd9f4`.
3. **PRs.** Both target `next`. Not merged.
    1. [PandiO/knk-plugin#70](https://github.com/PandiO/knk-plugin/pull/70): `Closes PandiO/knk-workspace#710`.
    2. [PandiO/knk-workspace#719](https://github.com/PandiO/knk-workspace/pull/719): `Part of`.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`):
        1. knk-core 3 033 → 3 050 (+17: `WalkClearanceTest` 8, `WalkPathShaperTest` 9).
        2. knk-paper 2 904 → 2 911 (+7, 18 skipped).
        3. knk-api-client 344 → 344 (2 skipped).
        4. No failures.
    2. A16 (flag off is today's behaviour):
        1. A clearance cost of 0 gives the same search result, expansions and stats over five scenes: open field, corner, wall with a gap, spiral stair, ladder.
        2. With the flag off, the leg draws exactly the cell points.
        3. The preparer's profile and `WalkConfig.profile(false)` equal today's profile.
    3. A15:
        1. On a 3-wide spiral stair, the trail stays at least 0.7 from the newel (0.8 less the shaper's tolerance) and never comes under 0.35.
        2. On the stair house (scenario), see 4.4.
    4. A27:
        1. The NPC shaper and the player shaper give the same line on one scene: `CorridorShaper` over `GridWorld` vs `WalkTerrainNavWorld`, and `WalkPathShaper`.
        2. The scenario shapes on another thread from the capture only.
    5. `walk-trail-stairhouse` in a local paper-boot run (Paper 26.3 build 205, without Citizens, the new scenario only): PASS.
        1. 0 % of the trail's points were under 0.7 from a wall, post or drop on the live blocks, against 44.7 % of today's path.
        2. 33 corners, 29 of them rounded.
        3. Shaping took 39 to 81 ms (cold JVM).
        4. CI on `9dd3ee5f`: `build` green; `paper-boot` (all 51 scenarios, A26 included) green on the re-runs of 2026-11-18. The first runs crossed midnight UTC and failed only on the `latest.log` rollover (all 51 passed), filed as [#720](https://github.com/PandiO/knk-workspace/issues/720).
    6. Known reds: none.
    7. Codex: at its code-review usage limit on both PRs (2026-11-17 23:52), so neither has a Codex review (developer decision 2026-11-14). This is said on both PRs; no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *The search's clearance.* Chosen: per cell centre, from the clearance map's obstacle rule (a column without a standing cell within a step, access included), memoised per search. A cell beside a wall lacks 0.3 (cost 1.5); a cell diagonal to a corner lacks 0.09.
        1. Consequence: on a 3-wide spiral the inner ring stays cheaper than the middle ring at cost 5, so the guarantee comes from the shaper, as DESIGN § 7.1.2 has it.
        2. Alternatives:
            1. Clearance of the cell's whole square instead of its centre. Rejected: it does not match the NPC search the design names (`LocalLegSearch`).
            2. A higher default cost. Rejected: the design sets 5. The developer may raise `walk.clearance-cost` after the live test.
    2. *Stairs that turn over themselves.* Chosen:
        1. A run is cut where a cell comes within 3 columns of an earlier one whose floor differs by more than their distance.
        2. Each part is shaped from where the previous part's shaped line ended.
        3. Without this, the shaper's own split left an unchecked jump over the newel. A straight stair never cuts.
        4. Alternatives:
            1. Cut only where the same column repeats. Rejected: a full turn's corridor saw the start column four floors below as a wall.
            2. Change the shaper. Rejected: NPC code, A26.
    3. *The curve.* Chosen: a quadratic Bézier per corner, reaching up to 2 blocks before and after the corner (at most half of each side).
        1. Every point of the drawn chords is checked every 0.05 blocks and must keep the clearance the shaped line has there, never under 0.35.
        2. A failing corner is tried at half the width, then kept sharp.
        3. Alternatives:
            1. Chaikin over the whole line. Rejected: it cuts long segments' corners blocks early, then fails the check often.
            2. Catmull-Rom. Rejected: it overshoots outwards at sharp turns.
            3. Moving a failing sample back to the line. Rejected: it leaves kinks.
    4. *A15's tolerance.* Chosen: test against `wall-clearance` less 0.1 and the hard minimum strictly. The shared shaper's string pulling keeps its points' clearance less 0.05 and checks every 0.25 blocks, so at a convex corner a line can pass about 0.09 under 0.8.
        1. Alternative: repair the line in `WalkPathShaper`. Rejected: more code for a few hundredths, and the NPC line has the same tolerance.
    5. *Strip half width.* Chosen: 8, as DESIGN § 7.1.5 says.
        1. Alternative: 4, the NPC default. Rejected: the design names 8.
    6. *Extra keys `walk.wall-clearance` and `walk.curve`.* Chosen: added, because DESIGN § 7.6 lists them. The prompt named only `walk.clearance-cost`.
        1. Alternative: constants. Rejected: the design makes them keys.
    7. *Where shaping is hooked in.* Chosen: in `NavigationService.requestWalk` on the walk thread, after `measureWalk`. Legs near the road (KNG-124), which draw nothing, are not shaped. The trail goes to the main thread with the result. The additive pieces for L4 are a `walkDelivered` overload, an extra `adoptWalkResult` parameter and a separate section, "shaped walk trails".
        1. Alternative: a decorating `WalkPathfinder`. Rejected: the leg then could not keep the cells as a fallback.
    8. *Shaping counter.* Chosen: two `AtomicLong`s in `NavigationService`, shown in `walkStatus()`.
        1. Alternative: inside `WalkMeasurements`. Rejected: that changes L1's sample record for a field only phase 6 fills.
    9. *Build aid.* Chosen: a scratchpad Gradle init script passed with `-I`. It adds Google's Maven Central mirror as an extra repository, because Maven Central answered random 404s through the proxy (as L1's note 9.2 says). Not committed.
6. **Out of scope, noted.**
    1. DESIGN § 7.6 lists `trail-leg-spacing` as 1.5, while O20 and § 7.2 say 3.0. That is for L4.
    2. Follow-ups for the docs issue at merge: npc-navigation § 12 (the player side uses the shape package), the player guide, the register.
    3. None filed.
7. **Blockers.** None. The live test is the developer's.
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-plugin#70 and #719 into `next` after CI is green.
    2. Deploy: add the keys below and restart. The flag stays off until the live test.

       ```yaml
       navigation:
         guidance-v2: false
         walk:
           clearance-cost: 5
           wall-clearance: 0.8
           curve: true
       ```

    3. Live test, [smoke test § 8](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/navigation-offroad-smoke-test.md#8-phase-61-walk-trail-corners-710-tier3):
        1. Set `guidance-v2: true` and restart.
        2. On the stair house and in the keep: watch the trail on the stair, at a corridor corner and through a 1-wide door (steps 1 to 4).
        3. Run `/knk road status` while watching the tick time (step 6).
        4. Set the flag off again to confirm today's trail (step 7).
    4. Optionally comment `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L4 (#711):
        1. With the flag on, `DirectLeg.path` holds the shaped trail: floor points, not block centres. `TrailRenderer.drawPath`, `project` and `remainingOf` work on it unchanged.
        2. The anchors of § 7.2 can be laid on it.
        3. The hook in `NavigationService` is in its own section ("shaped walk trails"), so L4's cursor work stays separate.
    2. L10 (plaza lines): `WalkPathShaper` calls `CorridorShaper` without plazas (`Options(halfWidth, wallClearance)`). Plaza lines would pass `withPlazas` and the junctions.
    3. Local paper-boot runs work in the cloud session:
        1. Fetch the pinned Paper, WorldEdit and WorldGuard jars from `paper-boot.yml`.
        2. Run `tools/paper-boot/boot-test.sh` with `--scenarios`. A copy whose `run all` names one scenario takes about a minute.

### 4.4 L4 — Phase 6.2: anchored walk-trail particles, progress and cursor, winding back (#711)

1. **Scope done.** Everything is behind `navigation.guidance-v2`, off by default.
    1. knk-core `core/navigation/`:
        1. `PolylineCursor`: a player's place on a polyline, followed with continuity.
            1. Within a window the nearest point wins.
            2. Between two branches at least 3 blocks apart along the line and within 0.75 of the same distance, the one nearer the previous cursor wins.
            3. A far point is taken only by the caller's rule. On the route, when the old stretch is beyond `reroute-distance`. On a walk path, when the player is nearer it by more than 1 block, beyond a 3-block window.
            4. Off the line the cursor stays.
        2. `NavigationSession`: with `CursorParameters` (`cursor-jump`) it keeps two numbers.
            1. A monotone progress, `along()`, drives the ETA and the percentage.
            2. A `cursor()` follows the player both ways. The trail, the HUD distance, the arrow, the maneuver ahead, the off-route distance and `remainingBlocks()` come from it.
            3. A new route starts the cursor at 0.
            4. The old constructor, or `null`, is today's session.
        3. `JoinPoint`: the join point with the least remaining cost, 1.5 × the straight distance plus the route left after the point, within `max-start-distance`.
    2. knk-paper:
        1. `TrailRenderer.anchoredWindow` and `drawPath(viewer, path, cursor)`: one particle exactly at each anchor every `trail-leg-spacing` from the path's start, using the new `ParticleDraw.points`. The leg colour stays.
        2. `NavigationService`, in its own section ("anchored walk trails and winding back"):
            1. Sessions get `config.cursorParameters()`, which is null with the flag off.
            2. Walk legs keep a cursor, and their trail, HUD distance and arrow come from it.
            3. A direct walk leg within `walk.recompute-distance` of its path stays. Beyond it, the leg is recomputed from the player, with the target re-derived, at most once per `reroute-min-interval`.
            4. The start leg's N16 "heading away" is replaced by the distance to its path. Beyond it, the leg ends and the session re-routes.
            5. The walk to the road aims at the join point.
            6. The D13 re-check's "walked already" uses `cursor()`.
        3. Config:
            1. `navigation.trail-leg-spacing` (3.0, 0.5 to 16) and `navigation.cursor-jump` (12, positive).
            2. `NavigationConfig.withTrail` and `withCursorJump`.
            3. `TrailConfig` keeps its 4-argument constructor.
        4. A new paper-boot scenario, `walk-trail-cursor-stairhouse`. `MIN_SCENARIOS` is now 52.
    3. Kept: KNG-124, N17, rev. 9, the partial path rule. Legs without a path (the straight line, no way) keep today's rules. NPC navigation is untouched.
    4. The public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and the shape package are unchanged. The only change outside the files I own: L3's scenario helpers `overFloor` and `describe` became package-private (they were private).
    5. knk-workspace:
        1. Smoke test § 9: 11 steps, all tagged automated, 3 of them in part.
        2. Plugin configuration reference: § 4.15 and § 2.1.
        3. CHANGELOG (Unreleased).
        4. DESIGN § 7.6: `trail-leg-spacing` corrected from 1.5 to 3.0, as O20 and § 7.2.2 say (found by L3).
        5. DESIGN "as built" notes: § 7.2.4 and § 7.5.9.
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-trail-cursor` at `1925cf73`: three commits (core, paper, scenario) on `next` `54dfe8d7`.
    2. knk-workspace `claude/offroad-trail-cursor` at `cb7b55f8`: one commit on `next` `d07deabf`.
3. **PRs.** Both target `next`. Not merged.
    1. [PandiO/knk-plugin#72](https://github.com/PandiO/knk-plugin/pull/72): `Closes PandiO/knk-workspace#711`.
    2. [PandiO/knk-workspace#722](https://github.com/PandiO/knk-workspace/pull/722): `Part of`.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`):
        1. knk-core 3 050 → 3 071 (+21: `PolylineCursorTest` 10, `JoinPointTest` 5, `NavigationSessionCursorTest` 6).
        2. knk-paper 2 911 → 2 924 (+13, 18 skipped).
        3. knk-api-client 344 → 344 (2 skipped).
        4. No failures.
        5. Two of L3's flag-on tests now verify the three-argument `drawPath` (same path content). Its flag-off identity tests are unchanged.
    2. A16:
        1. `NavigationSessionCursorTest.withTheFlagOffTheSessionIsTodays`: a 149-tick session transcript (forwards, back, off the road with a re-route, on round the turn), the same with the old constructor and `null`, today's numbers pinned.
        2. `NavigationServiceTest.withTheFlagOffTheNewKeysChangeNothing`: trail, HUD, chat and events call for call, with `trail-leg-spacing` 1.5 and `cursor-jump` 4 against the defaults.
        3. Two tests pin today's road walk-back and today's heading away of the start leg.
    3. A17: anchors fixed on redraw and on a step (`TrailRendererTest`, and the scenario on the stair house's live floor).
    4. A18: `NavigationServiceTest.withGuidanceV2WalkingBackOnTheRoadDrawsTheRoadTrailFromThePlayer` and the session test. The trail is drawn from 40 after walking 60 forward and 20 back; the HUD shows 160; the progress stays at 60; there is no walk leg and no re-route.
    5. A19: `JoinPointTest` (ahead, behind, the road behind the player on a U-turn) and the service test (30 off the road joins about 27 ahead).
    6. A20: `PolylineCursorTest` (a loop that passes its start again; a switchback, including a player standing between the arms).
    7. A21:
        1. A walk leg walked forwards and back: one search, no "heading away", the cursor wound back to 3.
        2. Beyond the recompute distance: recomputed, at most once per 60 ticks.
        3. The start leg walked back along stays.
    8. Local paper-boot run (Paper 26.3 build 205, without Citizens, the new scenario only): `walk-trail-cursor-stairhouse` PASS. The cursor stayed within a block of the player's place on the shaped trail walked up and back down with a sideways wobble, and every anchor was over walkable floor.
    9. CI on `1925cf73`: `build` green and `paper-boot` green (all 52 scenarios, the NPC movement scenarios included).
    10. Known reds: none.
    11. Codex: at its code-review usage limit on both PRs (2026-11-18 01:08 UTC), so neither has a Codex review (developer decision 2026-11-14). This is said on both PRs; no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Cursor continuity on the route (§ 7.5.2).* Chosen: within `cursor-jump`, the nearest point wins. Two branches at least 3 apart along the route that are within 0.75 of the same distance go to the one nearer the previous cursor. Taken literally, "smallest change from the previous cursor wins" keeps the cursor on a corner the player has passed: the previous segment's end point stays within `reroute-distance` for blocks (shown in `PolylineCursorTest.aCornerDoesNotHoldTheCursorBack`). Alternatives:
        1. The literal rule. Rejected for that reason.
        2. Plain nearest point. Rejected: a player standing between the arms of a switchback flickers between them (risk 12.4).
    2. *A new route's cursor starts at 0.* Chosen because a route starts where the player joins the road. A loop that passes its start again then keeps the first pass. A player who is far along (after a network change) is found by the far rule. Alternative: the nearest point at the first tick. Rejected: it takes the second pass of a loop through the start.
    3. *What the cursor drives and what the progress drives.* Chosen:
        1. The cursor drives the trail, the HUD distance, the arrow, the maneuver ahead, the off-route distance, `remainingBlocks()` (and so the improvement check) and the D13 "walked already". A gate that closes ahead of a player who walked back past it re-routes.
        2. The progress drives the ETA and the percentage.
        3. A maneuver is still announced in chat once, through the service's announced index, which only grows.
        4. Alternatives:
            1. D13 from the progress (today's number). Rejected: it would ignore a gate the player must pass again.
            2. The ETA from the cursor. Rejected: § 7.5.2 names the progress for it.
    4. *Join point cost (§ 7.5.4).* Chosen: 1.5 × the straight distance, plus the route length left, over every block of the route within `max-start-distance`. It is used whenever a route is adopted with the player off it. With a factor of 1 the point nearest the destination always wins, because a straight line is never longer than the road. Alternatives:
        1. A walk search per candidate. Rejected: far too costly on the main thread's budget.
        2. A config key for the factor. Not added: the design names no key; easy to add after the live test.
    5. *Walk legs beyond `recompute-distance` (§ 7.5.5).*
        1. Chosen for a direct leg: recompute silently from the player's position, with the target re-derived, at most once per `reroute-min-interval`, keeping the old path drawn until the new one arrives. The smoke-test draft expected a "recalculating" message; that message belongs to "heading away", which the design replaces.
        2. Chosen for the walk to the road: the leg ends, and the session's off-route re-route brings a new route and a new join point. A player who walks off towards another road may get a different road.
        3. Alternatives:
            1. Keep the message. Rejected: it says "heading away", which no longer applies.
            2. Re-aim the start leg on the same route. Rejected: it would ignore a better road nearby.
    6. *Legs without a path.* Chosen: the straight line, NO_PATH and PENDING keep today's `best` rule. There is no path polyline to measure, and the straight line is redrawn from the player anyway. Alternative: never recompute them. Rejected: a region or street target would not be re-derived for a player who drifted.
    7. *Particles exactly at the anchors.* Chosen: the new `ParticleDraw.points`. `ParticleDraw.polyline` resamples from the first point with a carry, so on a curve particles would fall between anchors. Alternative: `polyline` with the anchors as vertices. Rejected for that reason.
    8. *What `trail-leg-spacing` covers.* Chosen: the anchored walk trail only. Straight legs stay at 3.0, like today's `drawLeg`. The design names the walk trail. Alternative: every off-road leg. Rejected: a straight leg is redrawn from the player and has no anchors.
    9. *Walk-path cursor window and margin.* Chosen: 3 blocks (§ 7.2.3) and 1 block for "really nearer". On the stair house the flight above is about 3 blocks away, and the scenario keeps the cursor within a block. Alternative: a margin of 0.5. Rejected: a wobble near a wall could switch flights.
6. **Out of scope, noted.**
    1. The plugin configuration reference § 2.1 still lists L3's #710 row as "in review, not in `next` yet", but it is merged (`54dfe8d7`). Left for the docs issue.
    2. Docs follow-ups at merge: the player guide (the walk trail and winding back), the register.
    3. None filed.
7. **Blockers.** None. The live test is the developer's.
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-plugin#72 and #722 into `next` after CI is green.
    2. Deploy: add the keys below and restart. The flag stays off until the live test.

       ```yaml
       navigation:
         guidance-v2: false
         trail-leg-spacing: 3.0
         cursor-jump: 12
       ```

    3. Live test, [smoke test § 9](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/navigation-offroad-smoke-test.md#9-phase-62-anchored-particles-and-winding-back-711-tier3), which can be combined with L3's § 8:
        1. Set `guidance-v2: true` and restart.
        2. In the keep and on the stair house, stand still and step along a walk trail; the particles stay put (steps 1 to 3).
        3. On a road, walk 40 forward and 20 back; the trail is drawn from you, with no walk leg (step 4).
        4. Step 15 off the road; the walk to the road leads to the join point, usually a little ahead (step 6).
        5. Walk back along a walk leg, then 7 or more blocks off it (steps 8 and 9).
        6. Set the flag off again to confirm today's behaviour (step 10).
    4. Optionally comment `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L5 (walk links, route as a leg list):
        1. `NavigationSession.cursor()` and `PolylineCursor` work on the route's polyline.
        2. A route made of legs needs one cumulative polyline, or a cursor per leg with the far rule across legs.
        3. `JoinPoint.choose` takes any polyline.
    2. L10 (plaza lines): the road trail is still drawn by `centredWindow` from `cursor()`. A plaza line that changes the drawn polyline must keep the cursor's along on the route polyline (A25: length, ETA and maneuvers unchanged).
    3. Local paper-boot runs: a copy of `boot-test.sh` whose `knk scenario run all` names one scenario. `run` takes a single name.
