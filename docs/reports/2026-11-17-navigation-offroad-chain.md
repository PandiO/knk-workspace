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

1. **L1 (#703) live measurements:** once L1's counters are in `next`, run the five scenes (keep, stair house,
   courtyard, 200 and 400 block open-country legs) with `/knk road status`; L1 writes the steps on #703. L5 waits for
   the report's budgets.
2. **Decision to confirm (from the NPC chain's comment on #698, 2026-11-17):** NPC use of the long walks (walk links
   and clusters, O32) moves from "after v1" into v1, as the phase after phase 3. It has no sub-issue or link in this
   chain yet; the spec's § 14 and § 15 need the change in a docs PR. Proposal: a design follow-up (sub-issue of #698)
   once L6 is designed in detail; not scheduled in this chain until you say so.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 0 measurements | #703 | In review (counters and steps done; the live run and the filled report are the developer's) | knk-plugin `claude/offroad-measurements` `71a43bc1`; knk-workspace `claude/offroad-measurements` `c275c84d` | [knk-plugin#68](https://github.com/PandiO/knk-plugin/pull/68), [#717](https://github.com/PandiO/knk-workspace/pull/717) | local build green; PR CI see § 4.1 | create_session `session_01R1w2Uub8CZ7NuvatVUifP7` (2026-11-17) |
| L2 Phase 1 shared shaping package | #704 | Not started (waits for NPC B5 #699 in `next`, § 3.3) | `claude/offroad-shape-package` | — | — | — |
| L3 Phase 6.1 trail corners | #710 | Not started (gate: L2 in `next`) | `claude/offroad-trail-corners` | — | — | — |
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
