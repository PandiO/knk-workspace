# Off-road navigation and landmarks chain — progress report

**Status:** Running, waiting for the developer (2026-11-18) · **Last updated:** 2026-11-18 (L8 step A block)

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
   a 1-wide door, `/knk road status` with the tick time).
4. **L4 (#711) live test (tier:3):** L4 is in `next` (plugin `580aafa1`). Add under `navigation:` `trail-leg-spacing: 3.0`
   and `cursor-jump: 12`; with `guidance-v2: true` follow smoke test § 9 (particles stay put on the stair house and
   in the keep; on a road walk 40 forward and 20 back; walk back before a passed turn; step 15 blocks off the road;
   walk back along a walk leg, then 6+ blocks off it; flag off again). Combine with L3's § 8 in one session.
6. **L8 (#708) live test (tier:3):** apply `AddLandmarks`, import the "Landmark - Default (seed v1)" form seed, grant
   `knk.admin.world.landmark`, set `navigation.landmarks: true` and `navigation.destination-engine: true`, restart,
   smoke test § 6.1–6.4 (about 45 min). Confirm the node rule (plain `knk.admin.world` does not include it).
5. **L10 (#712) step 2 smoke test:** add `plaza-curve-clearance: 0.65` under `navigation:`, set `plaza-lines: true`, restart, smoke test § 10.2 (9 steps).
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
| L4 Phase 6.2 anchored particles, winding back | #711 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 9) | knk-plugin `claude/offroad-trail-cursor` `1925cf73`; knk-workspace `claude/offroad-trail-cursor` `cb7b55f8` | [knk-plugin#72](https://github.com/PandiO/knk-plugin/pull/72) → `next` `580aafa1`, [#722](https://github.com/PandiO/knk-workspace/pull/722) → `next` `ff8cf291` | green (build, paper-boot) | create_session `session_01R1w2UwkAiptAq4cPVFVBTS` (2026-11-18) |
| L5 Phase 2 walk links | #705 | Not started (L4 in `next`; waits for L1 done: the developer's filled measurements report) | `claude/offroad-walk-links` | — | — | — |
| L6 Phase 3 hierarchical walk search | #706 | Not started (gate: L5 in `next`; O32 question first if L1 says option A fits) | `claude/offroad-hierarchical` | — | — | — |
| L7 Phase 4 route modes | #707 | Not started (gate: L5 in `next`) | `claude/offroad-route-modes` | — | — | — |
| L8 Phase 5.1 landmark entity | #708 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 6) | knk-web-api `d331bdf4`, knk-web-app `b50c4134`, knk-plugin `be9e3a74`, knk-workspace `eb3321a9` (`claude/offroad-landmarks`) | [knk-web-api#50](https://github.com/PandiO/knk-web-api/pull/50) → `935fe8cc`, [knk-web-app#54](https://github.com/PandiO/knk-web-app/pull/54) → `3432e6ef`, [knk-plugin#83](https://github.com/PandiO/knk-plugin/pull/83) → `5fd81466`, [#763](https://github.com/PandiO/knk-workspace/pull/763) → `7722cc76` | green (all jobs) | subagent of the coordinator (three component repos; resumed once after the usage limit) |
| L9 Phase 5.2 landmark weights | #709 | Not started (gate: L7 and L8 in `next`) | `claude/offroad-landmark-weights` | — | — | — |
| L10 Phase 7 plaza lines | #712 | Merged into next (step 1 and step 2, 2026-11-18); waits for the developer's smoke § 10.2 | knk-plugin `claude/offroad-plaza-lines` `28ad18c5`; knk-workspace `d7e4e834` | step 1: [knk-plugin#73](https://github.com/PandiO/knk-plugin/pull/73) → `ce0f65ec`, [#723](https://github.com/PandiO/knk-workspace/pull/723) → `c7f61e9e`; step 2: [knk-plugin#84](https://github.com/PandiO/knk-plugin/pull/84) → `4daa0c84`, [#769](https://github.com/PandiO/knk-workspace/pull/769) → `2e0c04d4` | green (build, paper-boot) | create_session `session_01R1w2Ussca79jpGCPqzcTf8` (2026-11-18) |

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
14. **L4 merged into `next` (2026-11-18 01:36).** § 6 checks held: heads matched, branch contained `next`, `build` and
    `paper-boot` (52 scenarios) green on `1925cf73`, `next` CI green after L3, flag off with transcript tests (A16),
    § 7.6 corrected to 3.0, public signatures stable for C1, no Codex findings (usage limit).
15. **Next link after L4: L10, not L5.** Gates checked 2026-11-18 01:36: L5 needs "L1 done", and L1's report is not
    filled (the developer's live run); L6, L7 and L9 hang on L5; L8 on the destination engine (#96, #103, #69 not in
    `next`); L10's gate (L3 and L4 in `next`) is open. Chosen: start L10 in two steps: step 1 builds the plaza line
    and a staff preview with the flag off and ends with the developer's viewing on Cinix and Brink (O16, charter
    § 2.4); step 2 (trail use, A22–A25) only after the developer's OK, sent to the same session. Alternatives: (a)
    wait for L1's report and start L5; rejected, it idles the chain on live work; (b) build steps 1 and 2 at once;
    rejected, O16 says the developer sees the lines before the trail uses them. L10 will hold the one plugin slot
    while it waits; if L1's report arrives first, L5 waits for L10 (one plugin navigation link at a time).
16. **L10 step 1 merged into `next` (2026-11-18 02:40)**, so the developer can view the lines in game. § 6 checks
    held for step 1: heads matched, branch contained `next`, `build` and `paper-boot` (55 scenarios, NPC plaza and
    replay scenarios included) green on `97d1bafc`, `next` CI green after L4, the `NavigationService` change checked as
    a behaviour-preserving extraction (`plazaNodesOf`) plus a read-only `routePlazas`, `navigation.plaza-lines` read by
    nothing yet, shape changes additive, no Codex findings (usage limit). Alternative: keep step 1 unmerged until the
    developer's OK; rejected, the developer views the lines on a server deployed from `next`. The L10 session waits
    idle for the answers.
17. **The chain waits for the developer (2026-11-18 02:40).** No gate is open: L5 needs L1's filled report; L6, L7,
    L9 hang on L5; L8 on the destination engine; L10 step 2 on the viewing. No link is running.
18. **NPC C1 (#700) merged into knk-plugin `next` (2026-11-18 03:07, `65c7d6d3`, `MIN_SCENARIOS` 59);** E1 (#701)
    follows in `core/npc/nav` and `paper/npc/nav` only. Every later plugin link of this chain merges `next` first and
    tells the NPC coordinator when it starts (`MIN_SCENARIOS`, `PaperScenariosTest` merges). Data point from C1 for
    L1's report and O32: the tower's spiral staircase route fits within today's walk caps (172 to 180 blocks against
    220), so it is not an acceptance case for long walks.
19. **#724 (found by NPC E1, merged into `next` as `7aef3de4`): a `/knk cache refresh` sends its first availability
    event before the region map is re-warmed.** Not a link of this chain and outside L5–L10's scope. Chosen: leave it
    to the NPC chain, which offered to schedule it; told its coordinator to keep it to the refresh path and to say
    which files it touches before it starts. Alternatives: (a) add it to this chain as a link; rejected, scope by
    sub-issue (skill § 2.2) and it is NPC behaviour; (b) leave it unowned; rejected, the NPC chain offered.
20. **Destination engine design refresh started (2026-11-18 08:59, developer's request).** L8's gate (#96, #103,
    #69 in `next`) cannot open while the engine design (#25) is still "Proposed" with a stale § 2/§ 5 and no tiers or
    charter. The developer asked for the refresh; session `session_01R1w2UwPYjWLi9pVBpZtwUC` (docs only, `knk-design`
    skill) re-checks the design against `next`, adds the `LandmarkProvider` hook, judges the October P1 branch,
    prepares tiers, smoke guide and charter, and asks the developer to approve. The implementation chain is the
    manager's to schedule after approval. Alternative: a note on #25 for the manager to schedule; the developer chose
    to start it now.
21. **Destination engine design Decided (2026-11-18, developer, in the refresh session).** DESIGN on `next` `870bc43`,
    charter `docs/ai-agents/handoffs/DESTINATION_ENGINE_CHAIN.md` on `main` (`ddd11dc`), phase 4b filed as #747, tiers
    set. Its chain is not started (the manager's daily run schedules it; the developer did not say "start now").
    Shared rule from that charter § 2.2: at most one knk-plugin link touching navigation code at a time **across both
    chains**; before a plugin link starts here, check the board and the engine chain for a running link and agree the
    order with its coordinator. L8 (#708) waits for engine L1–L3 in `next` and must not run beside engine L3, L4 or L5.
22. **Plugin slot order with the destination engine chain (2026-11-18 11:39).** Its coordinator
    (`session_01R1w2UvZSm3y5hAXB8VfYuv`) started engine L1 (#96, `core/navigation/` destination classes,
    `ArchitectureGuardTest`). Chosen: engine L1 first; no off-road plugin navigation link starts until it is merged;
    when the developer's answers open L10 step 2 or L5, this coordinator asks the engine coordinator for the next free
    window (it offered to hold one). Alternative: claim the slot now for L10 step 2 or L5; rejected, both still wait for
    the developer, so the slot would sit idle.
23. **Engine L2 (#103) merged into `next` (2026-11-18 13:27, plugin `2f1c783e`); engine L3 (#69) gets the slot.** Its
    coordinator offered the window before L3. Chosen: decline, because L10 step 2 and L5 both still wait for the
    developer (no answers on #712 and #703 at 13:27), so the slot would sit idle. My next plugin link waits for engine
    L3's merge, which also opens L8 (#708); L8 then asks for a window before engine L4/4b. Alternative: take the
    window and start L10 step 2 with the curve clearance as a config key (option 2 offered to the developer at 08:5x,
    not answered); rejected without the developer's go.
24. **Engine L3 (#69) merged into `next` (2026-11-18 15:06, plugin `073fa4cf`): L8's gate is open.** Engine L4 (#62)
    and L8 must not run side by side in knk-plugin navigation code. Chosen: engine L4 takes the plugin slot now; L8
    starts at once in two steps: step A (knk-web-api: `landmarks` table, migration, `api/landmarks`, access rule
    `knk.admin.world.landmark`; knk-web-app: list, form, domain pages; docs), step B (knk-plugin: `LandmarkProvider`
    registered in `KnKPlugin.startDestinationEngine`, `/knk landmark`) after engine L4's merge, before engine L5.
    Step A shares no file with engine L4. Alternatives: (a) all of L8 after engine L4; rejected, it idles the API and
    web-app work; (b) all of L8 now and engine L4 after it; rejected, the engine chain asked first and L8's plugin part
    is the smaller half. Route: subagent (three component repos). Overlap noted: the overview map chain's additive
    API/web-app work in `next` (`map_region_outlines`, `/map`): L8 keeps `KnKDbContext`, `objectConfigs` and seeds
    additive and merges `next` before its migration.
25. **L8 merged into `next` (2026-11-18 16:5x), steps A and B.** § 6 checks held: heads matched `git ls-remote`,
    every branch merged cleanly with `next` (web app and workspace 5 behind, merge-tree clean), CI green on all four
    PRs, the migration additive (Up creates `landmarks`, Down drops it), flags off, no Codex findings (usage limit).
    Merged in dependency order API → web app → plugin → docs. The subagent stopped once at the usage limit and was
    resumed. Decision for the developer (L8 block § 4.6): a plain `knk.admin.world` grant does not match
    `knk.admin.world.landmark`. The engine coordinator is told the plugin slot is free.
26. **L10 step 2 started (2026-11-18 17:50).** The developer's viewing on #712 (16:31): "Cinix" = Brink and South
    Gate (#39); Brink node moved onto Keepstreet #71 (data fix by the developer); developer decision: a curve is
    accepted down to clearance 0.65 (a player is 0.6 wide), the A* hard minimum 0.35 stays; pull 0.35; step 2 OK.
    The plugin slot was free (engine L5 waits for the developer's engine test; told the engine and NPC coordinators).
    Same session as step 1 (`session_01R1w2Ussca79jpGCPqzcTf8`); the 0.65 threshold becomes a config key. Gate check:
    the stair-house door (edge #57) is a road edit, out of scope.
27. **L10 step 2 merged into `next` (2026-11-18 18:35).** § 6 checks held: heads matched, branches contained `next`,
    `build` and `paper-boot` green on `28ad18c5`, the flag-off path checked in the diff (`plazaTrail` returns null
    with the flag off, the old draw calls follow), A25 transcript test, shape change additive (`Options` 6th
    component, old constructor kept), O33 recorded, no Codex findings (usage limit). Engine and NPC coordinators told
    the plugin slot is free. No link of this chain runs now; L5 waits for the developer's measurements (#703).

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

### 4.5 L10 — Phase 7: plaza lines for the players' trail, step 1 (#712)

*Step 1 of 2: the plaza line and a staff preview. The developer views the lines on Cinix and Brink before the trail uses them (O16). Step 2 waits for the coordinator to pass on the developer's OK.*

1. **Scope done.** `navigation.plaza-lines` is new, off, and read by nothing yet. Routes, trails, the session and NPC movement are unchanged.
    1. knk-core `core/navigation/shape/PlazaCurve` (new, additive):
        1. The pulled cubic curve of DESIGN § 8.3: control points P0 + a·t0 and P1 − a·t1 with a = |P0P1|/3, both moved so that the middle lies at chord midpoint + pull × (node − chord midpoint). `plaza-pull` 0.35 (O30).
        2. The check of § 8.4, every 0.5 block, on `Corridor.build` round the route with the footprint as a disc.
        3. The fallback: `PlazaLine`'s A* guided by the curve, through a new additive overload `PlazaLine.search(..., guide, guideCost)`. The plain search is unchanged.
        4. Plazas only, by `CorridorShaper.resolve` (O19).
        5. The result kinds are CURVE, GUIDED, NONE, STREET and NOT_CROSSED. Each result carries where the line sits on the route polyline (`entryAlong`, `exitAlong`) for step 2, the lengths (line, chord, right angle), the least clearance and why the curve failed.
    2. knk-core `core/navigation/PlazaLinePreviews` (new): the passes through a named node (every pair of its roads, followed on through split nodes) or along a route, and the chat line.
    3. knk-paper:
        1. `/knk road plazaline [<plaza or junction>]` (`knk.admin.road`, `PlazaLinePreview`, wired into `RoadAdminCommand` and `KnKPlugin`). It draws for 10 seconds (green curve, orange A* line, red rejected curve, white road bend, light blue plaza edge), writes to chat and works with the flag off.
        2. Keys `navigation.plaza-lines` (false), `plaza-pull` (0.35) and `plaza-guide-cost` (2), in `NavigationConfig.PlazaLinesConfig`. `corridor-half-width` and `plaza-corridor-blocks` come from the NPC settings for the world (O19, § 8.7); the clearance is `navigation.walk.wall-clearance`.
        3. `NavigationService.routePlazas(Player)` (read only). `plazaCrossingsOf` is split into `plazaNodesOf` with no behaviour change.
        4. Scenarios `plaza-line-brink`, `plaza-line-cinix-south-square` and `plaza-line-cinix-northern-gate-square`, with two new trimmed snapshots of 175 KB each. `MIN_SCENARIOS` 52 → 55.
    4. knk-workspace:
        1. Smoke test § 10: step 1 (§ 10.1, 7 steps, 4 tagged automated, 3 of them in part) and step 2 (§ 10.2, not built).
        2. Plugin configuration reference § 4.15 and § 2.1, and the commands guide.
        3. CHANGELOG (Unreleased) and DESIGN § 8.10 "as built".
    5. Public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and the existing shape classes are unchanged (additions only).
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-plaza-lines` at `97d1bafc`: 4 commits (core, core, paper, scenarios) on `next` `580aafa1`.
    2. knk-workspace `claude/offroad-plaza-lines` at `d794c716`: 1 commit on `next` `ff8cf291`.
3. **PRs.** Both target `next`, with `Part of PandiO/knk-workspace#712` (step 1). Not merged.
    1. [PandiO/knk-plugin#73](https://github.com/PandiO/knk-plugin/pull/73).
    2. [PandiO/knk-workspace#723](https://github.com/PandiO/knk-workspace/pull/723).
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer --max-workers=1`):
        1. knk-core 3 071 → 3 097 (+26: `PlazaCurveTest` 18, `PlazaLinePreviewsTest` 8).
        2. knk-paper 2 924 → 2 935 (+11, 18 skipped).
        3. knk-api-client 344 → 344 (2 skipped).
        4. No failures. `PlazaLineTest` (10) and every NPC test are unchanged.
    2. A22: the L, T and well scenes (the pull exactly 35 % of the way, inside the footprint, clearance 0.75 or more, shorter than the right angle); a street T junction gives STREET.
    3. A23: the stall gives GUIDED round it; a region the route does not pass is kept out; nothing fitting gives NONE.
    4. A24 and A25: no trail, session or route code reads the flag in step 1 (`ConfigLoaderNavigationTest`, `PlazaCrossingsOfTest`).
    5. Local paper-boot (Paper 26.3 build 205, Citizens, NPC navigation on), the three scenarios one by one: all PASS. Lengths are against the right angle at the node.
        1. Brink: 1 curve (−53 %) and 3 A* lines (−14 to −28 %). The route's curve failed on a step of more than a block (a slope).
        2. The square on the quarry-to-keep route: 1 curve (−25 %) and 3 A* lines (0 to −32 %).
        3. Northern Gate Square: 7 A* lines (−7 to −49 %).
        4. Most rejected curves missed `wall-clearance` 0.8 by 0.06 to 0.16. The A* line is then nearly the chord, without the pull. Asked on #712 (question 2).
    6. CI on `97d1bafc`: `build` and `paper-boot` green on both the push and the pull-request runs (all 55 scenarios, the `npc-plaza-*` and snapshot-replay NPC scenarios included; 2026-11-18 02:35 UTC).
    7. Known reds: none.
    8. Codex: at its code-review usage limit on both PRs (2026-11-18 02:16 UTC), so neither has a Codex review (developer decision 2026-11-14). This is said on both PRs; no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *How much clearance the curve must keep.* Chosen: `wall-clearance` wherever the entry and exit allow it (less only near an end that has less, by the distance from it), and never under the hard minimum 0.35. A22 asks the line to keep `wall-clearance`. Alternatives: (a) only the hard minimum, as § 8.4 reads; more curves, but A22 would not hold; (b) L3's tolerance (0.7). Both are offered to the developer on #712.
    2. *Where the code lives.* Chosen: `PlazaCurve` in `core/navigation/shape`, next to `PlazaLine` and `Corridor`, which it uses package-privately (`CorridorShaper.resolve`); the preview's road-graph logic goes in `core/navigation/PlazaLinePreviews`. Alternatives: (a) `core/roads/walk` beside `WalkPathShaper`; a plaza line belongs to the road trail, not to a walk path, and would need `resolve` made public; (b) knk-paper; against spec § 11.
    3. *`WalkPathShaper` not used.* Chosen: the plaza line is not built through `WalkPathShaper`, which shapes walk legs over the captured terrain. The road trail's plaza line runs on the live world on the main thread, as M5's does. Alternative: shape road stretches through `WalkPathShaper` with plazas; that needs a walk capture of the road, a cost nothing else pays. This is for step 2 to revisit if the trail is shaped off the main thread.
    4. *Corridor seeds.* Chosen: the route is clipped by distance along it (entry − 4 to exit + 4 blocks) and densified to a point per block snapped to real floors (`NavGeometry.floorNear`). On Northern Gate Square the graph's sparse points shut the square's own region out of the corridor (found by the scenario). Alternatives: (a) the route's own points only, as M5 does with dense NPC waypoints; fails there; (b) ignore regions on the plaza; against § 8.4.
    5. *The node's centre.* Chosen: the node's block centre. A block corner is equally near three route points, and the first one won, shifting the footprint by a block (found by a test). Alternative: leave `PlazaCrossing` as given; the NPC side keeps that (unchanged).
    6. *Shared keys.* Chosen: `corridor-half-width` and `plaza-corridor-blocks` from the NPC settings for the world; the clearance from `navigation.walk.wall-clearance`. Alternative: new player keys; § 8.7 names the NPC key as shared.
    7. *The preview for a named node.* Chosen: every pair of the roads at the node, 40 blocks of each, followed through split nodes, so the developer sees all turns without navigating. Alternative: only the player's route; that needs a route per turn.
    8. *Snapshots for Cinix.* Chosen: two windows trimmed from the full evidence zips of 2026-11-17 (quarry-to-keep's square, node 39, radius 8; Northern Gate Square, node 37, radius 12). Brink is in the committed stair-house snapshot (node 6). Which plaza "Cinix" means is asked on #712. Alternative: no Cinix scenario; the prompt asks for both where a snapshot exists.
    9. *The scenarios' live check.* Chosen: over walkable floor between the line's end floors (±1) and at least 0.35 from a wall, post or drop; on the road's own cells, the road graph's floor. At (1384 -580) on Northern Gate Square the graph names floor 43, a stair block the walk rule does not call a floor, and the corridor seeds it as the NPC side does. Alternative: L3's helper as it is; it judged that stair as a 2-block wall.
    10. *Build aid.* Chosen: `--max-workers=1`, because parallel downloads through the proxy got random 404s from Maven Central. A scratchpad init script with Google's mirror (L1, L3) was refused by the session's permission check. Not committed.
6. **Out of scope, noted.**
    1. Step 1 found that the road graph can name a floor the walk rule does not stand on (a stair at Northern Gate Square, decision 5.9). It affects the NPC corridor in the same way. Not filed: no behaviour shown wrong yet.
    2. Docs follow-ups at merge: npc-navigation § 12.4 (the players' side uses the shape package), the player guide (step 2), the register.
7. **Blockers.** None. Step 2 waits for the developer's view (O16).
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-plugin#73 and #723 into `next` after CI is green (or holds them until step 2, as the coordinator decides).
    2. Deploy: nothing required. Optional, for the pull:

       ```yaml
       navigation:
         plaza-lines: false
         plaza-pull: 0.35
         plaza-guide-cost: 2
       ```

    3. View the lines (smoke test § 10.1): `/knk road plazaline Brink`, `"Northern Gate Square"`, `"Merchant's Square"`, the quarry-to-keep square. Answer the four questions on #712: which plaza "Cinix" is, the curve's clearance, the pull, and OK or what falls short.
    4. Optionally comment `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. Step 2 (this link):
        1. `PlazaCurve.Result.entryAlong` and `exitAlong` are horizontal distances along the polyline it was given. The trail must splice them into the drawn polyline while `NavigationSession.cursor()` keeps the route polyline's along (A25, L4's note 9.2).
        2. Cache per (plaza, entry, exit) for the route's life (§ 8.6).
    2. Local paper-boot: `knk scenario run <name>` per boot; three boots take about 3 minutes.

### 4.6 L8 — Phase 5.1: landmark entity, step A (API and web app) (#708)

1. **Scope done (step A).**
    1. knk-web-api:
        1. Model `Models/Landmark.cs`: `Name` (100), `LocationId` (RESTRICT), `DomainId` (SET NULL), `ExtentKind`/`Kind` stored as strings, `RegionId` (128), `Radius`, `Preference` (with a CHECK constraint from 0.25 to 4), `NavigationEnabled`, `CreatedAt`.
        2. The `KnKDbContext` block and the migration `20261118152046_AddLandmarks`, which only creates the `landmarks` table.
        3. DTOs (`LandmarkReadDto` with world, point, domain id and name, extent and flags for step B), repository, service, AutoMapper profile.
        4. `LandmarksController` at `api/landmarks`: anonymous `GET ?world=` and `GET {id}` under the `map` limit; `POST search` (F Landmark); writes through `RequireServiceOrPermissionForWrites(knk.admin.world.landmark)` plus `RequireDashboardChange` and `knk.admin.delete`.
        5. `StaffPermissions.LandmarkManage`; registry entry (World area, write node the landmark node); lookup with a `domainId` filter; DI; seed `Landmark.json` and its README row.
        6. The pinned access tests and the new service, controller and migration tests.
    2. knk-web-app:
        1. DTO types, `LandmarkClient` (`Controllers.Landmarks = 'landmarks'`) and the five `entityApiMapping` cases.
        2. Dashboard columns (World, Point, Domain, Area, In /navigate).
        3. `DomainLandmarksPanel` on every domain detail page, with Add landmark gated on `knk.admin.world.landmark` and `knk.admin.content`.
        4. Jest tests and `e2e/landmarks.spec.ts` (7). Mocks of `landmarks/search` added to the strict `town-detail` and `entity-setup-delete-details` specs.
    3. knk-workspace (`next` branch): smoke test § 6 (API and web steps in full, 11 of 12 automated with 2 in part, plugin steps marked "step B"), CHANGELOG (Unreleased) with the admin steps, dashboard access admin guide § 2, DESIGN § 6.4.4.
2. **Commits and heads.**
    1. knk-web-api `claude/offroad-landmarks` at `d331bdf` (1 commit, base `next` `6094276`).
    2. knk-web-app `claude/offroad-landmarks` at `b50c413` (1 commit, base `next` `de43f6b`).
    3. knk-workspace `claude/offroad-landmarks` at `97a71701` (1 commit, base `next` `d484361e`).
    4. All three contain the current `next` (checked again before opening the PRs).
3. **PRs.** [knk-web-api#50](https://github.com/PandiO/knk-web-api/pull/50), [knk-web-app#54](https://github.com/PandiO/knk-web-app/pull/54), [#763](https://github.com/PandiO/knk-workspace/pull/763), base `next`, all `Part of PandiO/knk-workspace#708` (step B's plugin PR closes it). Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: 4409 passed, 100 skipped → 4452 passed, 100 skipped (MySQL tests skip locally without `KNK_TEST_MYSQL`). CI is green: `build-and-test`, `mysql-tests` and `fresh-database` (migrations on an empty MySQL).
    2. knk-web-app: Jest 2720 → 2733; tsc and `typecheck:e2e` clean; build ok; Playwright 176 → 183 (two full runs green). CI is green: `build-and-test`, `e2e`.
    3. Known reds: none. One flake: `login.spec.ts` failed once in a loaded full run, then passed 3 of 3 alone and in two later full runs. It is not touched by this link.
    4. Codex: at its usage limit on all three PRs (2026-11-18 ~15:50 UTC), so there was no review. This is said on each PR.
5. **Decisions (DESIGN § 4.3).**
    1. *What "matched by knk.admin.world" means.* Chosen: `knk.admin.world.landmark` follows the resolver's rule: it is matched by `knk.admin.world.*`, `knk.admin.*` and `*`, and a bare `knk.admin.world` grant does not match it. The admin step says to grant it. This keeps one permission rule everywhere; O26 names only `knk.admin.*` and `*`. Alternatives: (a) an any-of rule that also lets a bare `knk.admin.world` write landmarks; needs a new attribute and a change to the dashboard's all-of change nodes; (b) a data migration granting the node to holders of `knk.admin.world`; against "only the additive table" (charter § 3.3).
    2. *Rate limit of the anonymous reads.* Chosen: the `map` policy (120/min per IP), the public-read budget. Alternatives: (a) `lookup` (20/min), which is shared with the game server's link-code calls from the same IP, and the plugin polls landmarks; (b) a new `landmarks` policy and setting; a new config key for little gain.
    3. *DESIGN's "like road network reads".* Road network reads are category D (logged in or plugin key), not anonymous. Chosen: anonymous, as § 6.4.1 and A12 say. Alternative: D like the roads; against A12's "its reads are anonymous".
    4. *Name unique per world.* Chosen: checked by the service, ignoring case, joined on the Location's world, plus a plain index on `Name`. Alternatives: (a) a `WorldName` column with a unique (world, name) index; adds a field § 6.3 doesn't have and must be kept in sync with the Location; (b) unique per table; stricter than the design.
    5. *Limits § 6.3 leaves open.* Chosen: radius above 0 and at most 512 blocks; a Region needs a region id of at most 128 characters; the field of the other extent is cleared on save. Alternative: no upper bound; a typo would make a landmark cover a town.
    6. *Delete.* Chosen: the landmark's Location stays and goes to the Location retention check (KNG-80), as a domain delete does. Alternative: delete the Location with the landmark; a picked shared Location would go too.
    7. *Update semantics.* Chosen: `name` is required; `domainId` is taken as sent (null unlinks); pin, extent, preference, navigation flag and kind keep their stored values when null. The `PUT` returns the saved landmark, not 204. Alternative: full replace; `/knk landmark move|link` in step B would then have to send everything.
    8. *Domain pages.* Chosen: a `DomainLandmarksPanel` under the detail page of every domain type (town, district, structure, gate structure, domain), fed by the search's `domainId` filter. Alternatives: (a) a `Landmarks` navigation collection on `Domain` shown by the display configuration; changes the domain model and DTOs; (b) only town, district and structure; § 6.1 says any domain.
    9. *Form seed.* Chosen: `LocationId` (a Location picker with the LocationSelection world task, like `SiegeSpawnpoint`), because `FormConfigurationSeedFilesTests` requires every non-nullable FK on the form. The API also takes an embedded `location`. Alternative: the embedded `Location` field like Structure; the seed test refuses it.
    10. *Plugin reads pinned now.* `LandmarksController.GetAll`/`GetById` are in `ReadAccessRulesTests.PluginReads`, so step B needs no API change. Alternative: add them in step B.
6. **Out of scope, noted.**
    1. No issue filed.
    2. Docs follow-ups for the `documentation` sub-issue at merge: `docs/specs/api/` landmark contract, the next release's migration list in `production-installation.md` § 5.3, a landmark admin how-to, the player guide (with step B), the register.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-web-api#50, knk-web-app#54 and #763 into `next` (the web app needs the API).
    2. Deploy: apply the migration `AddLandmarks`; import the form seed "Landmark - Default (seed v1)"; grant `knk.admin.world.landmark` to the ranks that make landmarks (`knk.admin.*` already has it).
    3. Smoke test § 6.1, § 6.2 and § 6.4 (about 25 min); § 6.3 after step B.
    4. Optionally comment `@codex review` on the three PRs once the Codex limit resets.
9. **Notes for later links.**
    1. Step B (this link): the plugin reads `GET api/landmarks?world=` (anonymous, but the plugin key works too) into the model's `Landmark` record. The fields map one to one: `extentKind` "None"/"Region"/"Radius" (`Landmark.Extent.parse`), `location.x/y/z`, `world`, `domainId`, `domainName`, `navigationEnabled`. Writes for `/knk landmark` go through `POST`/`PUT`/`DELETE api/landmarks` with the plugin key. The `PUT` keeps null fields, so `move` sends `name` and `locationId` or `location`, and `link`/`unlink` send `name` and `domainId`, with the current domain id resent on the other updates.
    2. L9: `Preference` is stored and validated (0.25 to 4.0, CHECK in the database); nothing reads it yet.

### 4.7 L8 — Phase 5.1: landmark entity, step B (plugin) (#708)

1. **Scope done (step B, started at once after step A on the coordinator's message; engine L4 #62 is in knk-plugin `next` `3e04ba8f`).**
    1. knk-api-client: `LandmarkDto` (with the write body), `LandmarkMapper`, `LandmarksApiImpl` (`api/landmarks`: list by world, get, create, update, delete), `KnkApiClient.getLandmarksApi()`.
    2. knk-core:
        1. `domain/landmarks/KnkLandmark` and `LandmarkWrite`, and the `ports/api/LandmarksApi` port.
        2. `landmarks/LandmarkExtent` (point, region or cylinder, Bukkit-free), `LandmarkConnections.INFERRED` (a seam only) and `LandmarkCommandArgs`.
        3. `navigation/engine/LandmarkProvider` (World scope; key `landmark:<id>`, detail `in <domain>`; Region extent as `Place.Region`, Radius as `Place.Point` with `arrivalRadius`, None as a plain point).
        4. `NavigationModelRefresher.Source.landmarks()` fills the reserved section. A failed read keeps the current landmarks; E16's snapshot schema 1 needed no change.
    3. knk-paper:
        1. The provider in `startDestinationEngine`'s World list, only with `navigation.landmarks` on.
        2. `NavigationModelRuntime.source(..., landmarksApi)`.
        3. `Destination.arrivalRadius` via `HandleDestinations`; `NavigationService` arrives inside the cylinder (start, session tick, direct-leg tick, route end; arrival lines only, no guidance-v2 section).
        4. `/knk landmark create|list|show|move|delete|link|unlink` (`commands/LandmarkAdminCommand`, `/knk` metadata node `knk.admin.world.landmark`, documented in `plugin.yml` under `knk.admin`).
        5. `config.yml` `navigation.landmarks: false`, `LandmarksConfig`.
    4. knk-workspace (same PR #763, `origin/next` merged in with one mechanical CHANGELOG conflict, both entries kept): smoke § 6.3 (10 steps, all tagged, 4 in part), CHANGELOG step B entry, plugin configuration § 2.1 and § 4.15, commands guide, DESIGN § 6.5.4.
2. **Commits and heads.** knk-plugin `claude/offroad-landmarks` at `be9e3a74` (1 commit, base `next` `3e04ba8f`); knk-workspace `claude/offroad-landmarks` at `eb3321a9` (step A commit, merge of `origin/next`, step B docs).
3. **PRs.** [knk-plugin#83](https://github.com/PandiO/knk-plugin/pull/83) into `next` with `Closes PandiO/knk-workspace#708`; [#763](https://github.com/PandiO/knk-workspace/pull/763) updated (title and body cover both steps, still `Part of`). Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`:
        1. knk-core 3316 → 3334 (+18).
        2. knk-api-client 351 → 358 (+7; 2 skipped both times).
        3. knk-paper 3065 → 3089 (+24; 18 skipped both times).
        4. 0 failures. The cylinder arrival test was seen failing with the check removed.
    2. CI on `be9e3a74`: `build` and `paper-boot` green on both the push and the pull-request runs (2026-11-18 16:43 UTC).
    3. Known reds: none.
    4. Codex: at its usage limit on knk-plugin#83 and again on #763 after `@codex review`; said on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *Core `Landmark`.* Chosen: the model's existing `navigation/model/Landmark` record (E16) is what the provider and snapshot use; the richer `domain/landmarks/KnkLandmark` (Location id, preference, domain type) is what `/knk landmark` reads and writes, with `toModel()`. Alternatives: (a) one record with every field; changes the snapshot record P2 pinned; (b) a third `core/landmarks/Landmark`; a duplicate of the model record.
    2. *Region extent.* Chosen: `Place.Region` (destination engine § 3.2.3, `InitialScopes` doc), arrival by the existing WorldGuard containment. The coordinator's "point place with an arrival radius" applies to Radius and None. Alternative: a point with the region attached; a second region arrival path.
    3. *Cylinder height.* Chosen: as many blocks up and down as the radius across (A13 doesn't say). Alternative: unbounded height; a landmark on one floor of a keep would count every floor.
    4. *Failed landmark read.* Chosen: keep the current model's landmarks and refresh the rest (log a warning). Alternative: fail the whole refresh like the other three parts; an API before step A (404) would then freeze the model.
    5. *The command with the flag off.* Chosen: registered, and every action answers "Landmarks are off on this server". Alternative: not registered; staff would see "unknown subcommand" with no reason.
    6. *Arguments.* Chosen: names with spaces; `link <landmark> <domain>` takes the longest landmark name that matches, then a domain by exact name or `#id` (an ambiguous name lists the ids); `#id` for landmarks everywhere. Alternative: quoted names; Bukkit doesn't parse quotes.
    7. *After a write.* Chosen: refresh the navigation model at once, so `/navigate` sees the change within seconds. Alternative: wait for the 60 s refresh.
    8. *`NavigationModelUnreadTest`.* Chosen: widen its allow-list by the six landmark files, with the reason in the class comment (they use the model's `Landmark` record or names; none is a navigation client). Alternative: copy `Landmark.Extent` into another package to stay outside the guard; a duplicate enum.
    9. *No paper-boot scenario.* Chosen: MockBukkit session tests for arrival and re-validation (cheap, deterministic); a scenario would need landmarks from the API on the boot server. `MIN_SCENARIOS` unchanged. Alternative: a scenario with a fixed model; not cheap with the model refresher in the way.
6. **Out of scope, noted.** None filed. Docs follow-ups at merge: the player guide (`/navigate` to a landmark), architecture of the navigation model's landmarks section, `docs/specs/api/` landmark contract, the register.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-web-api#50, knk-web-app#54, knk-plugin#83 and #763 into `next`. The plugin needs the API's `api/landmarks`; with an older API the read is a logged 404 and the section stays empty.
    2. Deploy: the API's migration `AddLandmarks`, the form seed `Landmark`, a grant of `knk.admin.world.landmark`; in the plugin's `config.yml` under `navigation:` add `landmarks: false` (true, with `destination-engine: true`, for the smoke test), then restart.
    3. Smoke test § 6.1 to § 6.4 (about 45 min).
9. **Notes for later links.**
    1. L9 (#709): `KnkLandmark.preference()` is read from the API but not in the model's `Landmark` record. Weights need it in the model, which means adding a field to the record and to `NavigationModelSnapshot.LandmarkFile`; snapshot schema 1 reads an unknown field as missing, so the field is additive. `LandmarkExtent.Cylinder.contains` and `LandmarkConnections` are the seams for the walk planner.
    2. The `/knk landmark` writes go through `api/landmarks` with the plugin key. The API's `PUT` keeps null fields except `domainId`, so `LandmarkWrite.from(landmark)` resends the domain.

### 4.5b L10 — Phase 7 step 2: the trail draws plaza lines (#712)

*Step 2, after the developer's view of the lines (#712, comment of 2026-11-18 16:31, recorded as O33) and the coordinator's go.*

1. **Scope done.** Everything is behind `navigation.plaza-lines`, off by default.
    1. knk-core:
        1. `core/navigation/PlazaTrail` (new): a route's plaza crossings, each with where the route passes its node. They are worked out lazily: one per redraw, when the trail's window comes within 24 blocks, once for the route's life (§ 8.6).
        2. `PlazaTrail.draw` moves the trail's spots inside a crossing onto its line by their share of the way.
        3. `segmentOf` places a `PlazaCurve.Result` on the route polyline in the route's own 3D measure.
    2. knk-core `PlazaCurve.Options.curveClearance` (O33): a curve is taken down to 0.65. The A* line keeps `wall-clearance` where it can and never goes under 0.35. Step 1's 5-argument constructor keeps its meaning.
    3. knk-paper:
        1. `NavigationService`, in a new section "plaza lines on the trail": a `PlazaTrail` per route on `Active`. `setPlazaLines(world, options)` is wired in `KnKPlugin` beside `navigationService.start()`. The three road-trail draws (`drawRouteFromPlayer` twice, `drawStartLeg` once) call the new overload only with the flag on and a plaza world; otherwise they make exactly the old calls. `plazaLineStatus()` is shown in `/knk road status`.
        2. `TrailRenderer.drawRoute(..., PlazaTrail)`, with `trailPointAlongs` and `centredWindowAlongs`. The old overloads are unchanged.
        3. Key `navigation.plaza-curve-clearance` (0.65); `PlazaLinesConfig` keeps a 3-argument constructor. The preview's header names both clearances.
    4. knk-workspace:
        1. DESIGN: decision O33, § 8.4, § 8.7, and § 8.11 as built.
        2. Smoke test § 10: step 1 viewed; § 10.2 with nine steps, all tagged automated, three in part.
        3. Plugin configuration reference § 4.15 and § 2.1; CHANGELOG.
    5. Untouched: `core/navigation/destinations`, the engine-handle code in `NavigationService`, NPC code, and the public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and the shape package (additions only).
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-plaza-lines` at `28ad18c5`: 2 commits on `next` `5fd81466` (the branch was fast-forwarded to it).
    2. knk-workspace `claude/offroad-plaza-lines` at `d7e4e834`: 1 commit on `next` `7722cc76`.
3. **PRs.** Both target `next`. Not merged.
    1. [PandiO/knk-plugin#84](https://github.com/PandiO/knk-plugin/pull/84): `Closes PandiO/knk-workspace#712`.
    2. [PandiO/knk-workspace#769](https://github.com/PandiO/knk-workspace/pull/769): `Part of`.
4. **Tests, baseline on `next` `5fd81466` → result.**
    1. knk-core 3 334 → 3 343 (+9). knk-paper 3 089 → 3 096 (+7, 18 skipped). knk-api-client 358 → 358 (2 skipped). No failures.
    2. A22: `NavigationServiceTest.withPlazaLinesTheTrailRoundsTheJunctionOnThePlazaLine` (the spot at the node is drawn 35 % of the way to the node; straight on, the line is the road) and the `PlazaTrailTest` cases.
    3. A23: `PlazaCurveTest` (the stall).
    4. A24: `withPlazaLinesOffTheTrailIsDrawnAsToday`, `withoutAPlazaWorldTheFlagDrawsAsToday`, and `TrailRendererTest.withoutAPlazaTrailTheRouteIsDrawnAsBefore`. All of L3's and L4's flag-off identity tests are unchanged and green.
    5. A25: `plazaLinesChangeNeitherTheRouteNorItsNumbers`. A transcript of the progress, the route length, the maneuvers, every HUD update and every chat line is equal with the flag on and off.
    6. Local paper-boot (the three real-plaza scenarios with 0.65): all PASS. The South Gate plaza now has 4 curves (was 1); Northern Gate Square 3 curves and 4 A* lines (was 7 A* lines); Brink is unchanged (its snapshot predates the node move).
    7. CI on `28ad18c5`: `build` and `paper-boot` green on the push and the pull-request runs (2026-11-18 18:26 UTC, no midnight crossing).
    8. Codex: at its usage limit on both PRs (2026-11-18 18:00 UTC), said on both; no findings.
5. **Decisions (DESIGN § 4.3).**
    1. *How the trail uses the line.* Chosen: the route's own spots (every 1.5 blocks from its start) inside a crossing are drawn at the same share of the way along the plaza line. The particles keep fixed spots, and the cursor and progress stay on the route polyline (L4's note 9.2, A25). Alternatives: (a) splice the line into the route polyline; that changes the length, the ETA and the cursor (against A25); (b) a separate polyline with its own cursor; more state for no gain on a 20 to 30 block stretch.
    2. *When a crossing is worked out.* Chosen: lazily on the main thread, one per redraw (every 10 ticks), when the window comes within 24 blocks of its node, then kept for the route. Alternatives: (a) all crossings at route adoption; several A* runs in one tick on long routes; (b) on the routing thread; `BukkitNavWorld` reads live blocks, which is main-thread only.
    3. *guidance-v2.* Chosen: the same drawing with the flag on or off. The road trail's spots are fixed along the route in both cases; with `guidance-v2` on they are drawn from L4's cursor. Alternative: plaza lines only with `guidance-v2`; the coordinator's note asks for the anchored trail with it on, not for a dependency.
    4. *The curve's threshold.* Chosen: a new key `plaza-curve-clearance` (0.65, O33), separate from `walk.wall-clearance`, which the A* line keeps. Alternative: lower `wall-clearance` for plazas; that would make the A* lines hug obstacles too.
    5. *The step-1 constructor of `Options`.* Chosen: it keeps the step-1 meaning (the curve keeps the A* clearance), so callers outside this link stay as they were; `defaults()` uses 0.65. Alternative: change it to 0.65; that is a silent change for a public constructor.
6. **Out of scope, noted.** The stair-house door choice at Brink is a road edit of edge #57 (the developer's note on #712), not done. Docs follow-ups at merge: npc-navigation § 12.4, the player guide, the register.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. The coordinator merges knk-plugin#84 and #769 into `next`. #84 closes #712; then the documentation sub-issue and the docs session (CLAUDE.md "Shipping a change").
    2. Deploy: add under `navigation:` and restart. Set `plaza-lines: true` to test.

       ```yaml
       navigation:
         plaza-lines: false
         plaza-pull: 0.35
         plaza-guide-cost: 2
         plaza-curve-clearance: 0.65
       ```

    3. Live test, smoke test § 10.2: Brink, the South Gate plaza and Northern Gate Square with `plaza-lines: true`; a street T junction; the HUD and turns flag on against flag off; then off again.
    4. Optionally comment `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L5 (route as a leg list): `PlazaTrail` measures in the route polyline's own 3D distance along it. A route of several legs needs one `PlazaTrail` per leg polyline, or one over the joined polyline.
    2. The real-plaza scenarios use snapshots from 2026-11-17. Brink's node has moved since; a new snapshot would show the developer's view.
