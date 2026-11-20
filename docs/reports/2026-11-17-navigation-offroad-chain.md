# Off-road navigation and landmarks chain — progress report

**Status:** Running, waiting for the developer (2026-11-18) · **Last updated:** 2026-11-19 (F2 block); 2026-11-18 (L9 block); 2026-11-18 (L5 block); 2026-11-18 (L8 step A block)

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

1. **L1 (#703):** report done (#770). Still open there: the tick time during a large capture (spark during scene 4) and step 8 (concurrency); they do not block L5.
2. **Decision to confirm (from the NPC chain's comment on #698, 2026-11-17):** NPC use of the long walks (walk links
   and clusters, O32) moves from "after v1" into v1, as the phase after phase 3. It has no sub-issue or link in this
   chain yet; the spec's § 14 and § 15 need the change in a docs PR. Proposal: a design follow-up (sub-issue of #698)
   once L6 is designed in detail; not scheduled in this chain until you say so.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 0 measurements | #703 | Done (2026-11-18): report filled by the developer's runs, #770 in `next`; tick time and step 8 still open on #703 | knk-plugin `claude/offroad-measurements` `71a43bc1`; knk-workspace `claude/offroad-measurements` `2337d3a4` | [knk-plugin#68](https://github.com/PandiO/knk-plugin/pull/68) → `next` `04506d8c`, [#717](https://github.com/PandiO/knk-workspace/pull/717) → `next` `a6240f5d` | green (build, paper-boot on `71a43bc1`) | create_session `session_01R1w2Uub8CZ7NuvatVUifP7` (2026-11-17) |
| L2 Phase 1 shared shaping package | #704 | Merged into next (2026-11-17) | knk-plugin `claude/offroad-shape-package` `0d0cff84`; knk-workspace `claude/offroad-shape-package` `ef17bcc3` | [knk-plugin#69](https://github.com/PandiO/knk-plugin/pull/69) → `next` `c45c16bb`, [#718](https://github.com/PandiO/knk-workspace/pull/718) → `next` `d8ebd9f4` | green (build, paper-boot) | create_session `session_01R1w2UwTnENVNKzfaXudBUh` (2026-11-17) |
| L3 Phase 6.1 trail corners | #710 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 8) | knk-plugin `claude/offroad-trail-corners` `9dd3ee5f`; knk-workspace `claude/offroad-trail-corners` `daffbc1d` | [knk-plugin#70](https://github.com/PandiO/knk-plugin/pull/70) → `next` `54dfe8d7`, [#719](https://github.com/PandiO/knk-workspace/pull/719) → `next` `d07deabf` | green (build; paper-boot on re-run, #720) | create_session `session_01R1w2Uv9tRTPyjZsFJNWGec` (2026-11-17) |
| L4 Phase 6.2 anchored particles, winding back | #711 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 9) | knk-plugin `claude/offroad-trail-cursor` `1925cf73`; knk-workspace `claude/offroad-trail-cursor` `cb7b55f8` | [knk-plugin#72](https://github.com/PandiO/knk-plugin/pull/72) → `next` `580aafa1`, [#722](https://github.com/PandiO/knk-workspace/pull/722) → `next` `ff8cf291` | green (build, paper-boot) | create_session `session_01R1w2UwkAiptAq4cPVFVBTS` (2026-11-18) |
| L5 Phase 2 walk links | #705 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 3) and confirmation of the road-first defaults | knk-plugin `claude/offroad-walk-links` `5b4f666d`; knk-workspace `06b3f92a` | [knk-plugin#85](https://github.com/PandiO/knk-plugin/pull/85) → `3977329c`, [#774](https://github.com/PandiO/knk-workspace/pull/774) → `e2cac646` | green (build, paper-boot) | create_session `session_01R1w2UsbXwf6jzEc33aVwLL` (2026-11-18) |
| L6 Phase 3 hierarchical walk search | #706 | On hold as the fallback (developer, 2026-11-19, O32: option A and a better rural road network) | `claude/offroad-hierarchical` | — | — | — |
| L7 Phase 4 route modes | #707 | Merged into next (2026-11-18); waits for the developer's smoke § 5 (steps 2, 3, 9) and the node grants | knk-plugin `claude/offroad-route-modes` `d374b016`; knk-workspace `ed01ab75` | [knk-plugin#86](https://github.com/PandiO/knk-plugin/pull/86) → `a94332d9`, [#775](https://github.com/PandiO/knk-workspace/pull/775) → `dd09f782` | green (build, paper-boot) | create_session `session_01R1w2UveW7t8KTUAYeD5kAa` (2026-11-18) |
| L8 Phase 5.1 landmark entity | #708 | Merged into next (2026-11-18); waits for the developer's live test (tier:3, smoke § 6) | knk-web-api `d331bdf4`, knk-web-app `b50c4134`, knk-plugin `be9e3a74`, knk-workspace `eb3321a9` (`claude/offroad-landmarks`) | [knk-web-api#50](https://github.com/PandiO/knk-web-api/pull/50) → `935fe8cc`, [knk-web-app#54](https://github.com/PandiO/knk-web-app/pull/54) → `3432e6ef`, [knk-plugin#83](https://github.com/PandiO/knk-plugin/pull/83) → `5fd81466`, [#763](https://github.com/PandiO/knk-workspace/pull/763) → `7722cc76` | green (all jobs) | subagent of the coordinator (three component repos; resumed once after the usage limit) |
| L9 Phase 5.2 landmark weights | #709 | Merged into next (2026-11-18); waits for the developer's smoke § 7 steps 1–3 | knk-plugin `claude/offroad-landmark-weights` `636c9f32`; knk-workspace `9d0c926f` | [knk-plugin#87](https://github.com/PandiO/knk-plugin/pull/87) → `c7be34fb`, [#776](https://github.com/PandiO/knk-workspace/pull/776) → `99fef23d` | green (build; paper-boot after one #695 flake on the PR run) | create_session `session_01R1w2Ut1P9c2jGxRYC3weCJ` (2026-11-18) |
| L10 Phase 7 plaza lines | #712 | Merged into next (step 1 and step 2, 2026-11-18); waits for the developer's smoke § 10.2 | knk-plugin `claude/offroad-plaza-lines` `28ad18c5`; knk-workspace `d7e4e834` | step 1: [knk-plugin#73](https://github.com/PandiO/knk-plugin/pull/73) → `ce0f65ec`, [#723](https://github.com/PandiO/knk-workspace/pull/723) → `c7f61e9e`; step 2: [knk-plugin#84](https://github.com/PandiO/knk-plugin/pull/84) → `4daa0c84`, [#769](https://github.com/PandiO/knk-workspace/pull/769) → `2e0c04d4` | green (build, paper-boot) | create_session `session_01R1w2Ussca79jpGCPqzcTf8` (2026-11-18) |
| F1 walk-search fixes (#771 items 1, 2) | #771 | Merged into next (2026-11-19); waits for the developer's smoke § 12; the storage hall by road stays open (#780) | knk-plugin `claude/offroad-walk-fixes-771` `321daf6b`; knk-workspace `8fdfe392` | [knk-plugin#88](https://github.com/PandiO/knk-plugin/pull/88) → `cee53213`, [#778](https://github.com/PandiO/knk-workspace/pull/778) → `d1850c7a` | green (build, paper-boot) | create_session `session_01R1w2Ut7LKtBrvQw9bA3mVQ` (2026-11-19) |
| F2 road goal and route ends (#780 b, #771 items 3–5) | #780, #771 | Merged into next (2026-11-19); waits for the developer's smoke § 13 | knk-plugin `claude/offroad-route-ends-f2` `ebc63265`; knk-workspace `441dd7cc` | [knk-plugin#94](https://github.com/PandiO/knk-plugin/pull/94) → `6311de11`, [#813](https://github.com/PandiO/knk-workspace/pull/813) → `05b8edc3` | green (build, paper-boot) | create_session `session_01R1w2UtLzNFzgycUAEB8mVd` (2026-11-19; resumed once after the usage limit) |
| F3 smoke-test failures of 2026-11-19 (#780, #771, #710) | #780, #771, #710 | Running (started 2026-11-20 09:09 from plugin `next` `4e296797`) | `claude/offroad-smoke-fixes-f3` | — | — | create_session `session_01R1w2UsZsisbttfNE2dkTV3` (2026-11-20) |
| F2 road goal and route ends (#780 b, #771 items 3–5) | #780, #771 | Merged into next (2026-11-19); waits for the developer's smoke § 13 | knk-plugin `claude/offroad-route-ends-f2` `ebc63265`; knk-workspace `441dd7cc` | [knk-plugin#94](https://github.com/PandiO/knk-plugin/pull/94) → `6311de11`, [#813](https://github.com/PandiO/knk-workspace/pull/813) → `05b8edc3` | green (build, paper-boot) | create_session `session_01R1w2UtLzNFzgycUAEB8mVd` (2026-11-19; resumed once after the usage limit) |
| F3 smoke-test failures of 2026-11-19 (#780, #771, #710) | #780, #771, #710 | In review (2026-11-20); waits for the coordinator's merge and the developer's smoke § 14; § 12 step 3a not reproduced (diagnostics added) | knk-plugin `claude/offroad-smoke-fixes-f3` `64b4de3b`; knk-workspace `e7e6d306` | [knk-plugin#100](https://github.com/PandiO/knk-plugin/pull/100), [#851](https://github.com/PandiO/knk-workspace/pull/851) | green (build, paper-boot, push and PR runs, on `64b4de3b`) | create_session `session_01R1w2UsZsisbttfNE2dkTV3` (2026-11-20) |

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
28. **L1 done and L5 started (2026-11-18 20:13).** The developer's runs filled the measurements report (PR #770, merged
    into `next` by the smoke test session): option A fits the keep with conditions (walk caps on walk legs only, never
    `max-snap-distance`; tick time still to measure), cluster 1×1 chunk, DESIGN § 9.3 budgets hold except 22–30 KB
    per chunk. Gate "L1 done" counted as met for L5 (the budgets are set; tick time and step 8 are open on #703).
    Alternative: wait for the tick time; rejected, L5's budgets do not depend on it and L5 is behind its flag. The
    developer's road-first wish (#698, 19:57) is in L5's scope as a flag-gated planner rule with config defaults for the
    developer to confirm (it belongs to the mixed routes of § 5.1/§ 5.2, O12). Before L6 the coordinator asks the
    developer the O32 question (option A fits the keep). Out-of-scope findings of the runs filed as #771. The engine
    and NPC coordinators are told; L5 holds the plugin slot.
29. **L5 merged into `next` (2026-11-18 21:15).** § 6 checks held: heads matched, branches contained `next`, `build`
    and `paper-boot` green on `5b4f666d`, flag-off path checked in the diff (`startWalkLinks` returns before wiring
    when `navigation.walk-links` is off; the old router entries delegate with a null link source), no NPC, shape or
    destinations file touched, no public walk-search signature changed, NPC plans never take a walk link (test),
    route code off `computeRoute`/`begin`, no Codex findings (usage limit). For the developer: the road-first
    defaults `road-first-share` 0.6 and `road-first-max-ratio` 1.5 and O28's 40/2.0 to confirm.
30. **L7 started, L6 held (2026-11-18 21:16).** Gates: L6 and L7 both open after L5. L6 waits for the developer's O32
    answer (asked on #698 and in the session at 20:13). L7 (tier:2, no flag, default = today) takes the plugin slot;
    the mode rides the shared route request so engine L5's removal of the old path stays mechanical. Alternative:
    start L6 as decided (option B) without the answer; rejected, charter § 2.3 says ask first.
31. **L7 merged into `next` (2026-11-18 22:06), L9 started (22:07).** L7 § 6 checks held: heads matched, branches
    contained `next`, `build` and `paper-boot` green on `d374b016`, golden transcripts written on `next` `3977329c`
    with the old API prove default = `preferred` = today (O24), no NPC/shape/destinations/`RoadPlanner` file in the
    diff, mode parsing shared by both `/navigate` branches and tested on the engine path, nodes `default: op` (grants
    are the developer's), no Codex findings (usage limit). L9's gate (L7 and L8 in `next`) is open; landmark nodes in
    clusters stay a seam for L6. Engine and NPC coordinators told.
32. **L9 merged into `next` (2026-11-18 23:30).** § 6 checks held: heads matched, branches contained `next`, `build`
    green; `paper-boot` green on the push run (62 scenarios) and on the re-run of the PR run, whose first attempt
    failed only `npc-stairhouse-climb` ("jumps toward a waypoint on the flights"), the open NPC flake #695; L9
    changes no NPC main code (one NPC test added). Accepted the re-run because the failing scenario is the known flake
    and the push run of the same head passed. Alternative: hold the merge for a third run; rejected, two green runs on
    one head. Flag off and modes other than `preferred` unchanged (L7 golden transcripts green), NPC walk legs equal
    with landmarks on (test), no Codex findings (usage limit).
33. **The chain waits for the developer (2026-11-18 23:30).** In `next`: L1–L5 and L7–L10. Only L6 (#706) is left; it
    waits for the developer's O32 answer. No link is running; the shared plugin slot is free (told the engine and NPC
    coordinators).
34. **O32 answered by the developer (2026-11-19): option A, L6 on hold as the fallback.** Reason: the resource
    production feature needs NPC transports from wilderness structures (mines, lumberjacks) to storage in Cinix (keep
    storage hall; one near the Merchants district / spawn). The developer extends the rural road network so these
    routes ride roads with short walk legs at the ends (players and NPCs, C1). L6 starts only if a transport route
    still fails with the roads in. NPC use of long walks waits with L6 (NPC coordinator told).
35. **Fix link F1 started (2026-11-19 06:12, developer's go):** #771 items 1 (scene 1 stuck at 1417 59 -489 on the
    way to the keep storage hall, a transport destination) and 2 (open trapdoor over a ladder). Tier:2, no flag
    (bug fixes); #771 added as a sub-issue of #698. The trapdoor fix also reaches NPC walk legs (wanted; NPC scenarios
    are the guard). Items 3–5 stay open. Engine and NPC coordinators told.
36. **F1 merged into `next` (2026-11-19 07:10).** § 6 checks held for the plugin PR (heads matched, branch contained
    `next`, `build` and `paper-boot` green on both runs, no NPC/destinations/shape file, golden transcripts and flag-off
    tests unchanged, no Codex findings). The docs PR was sent back once: its smoke steps used `max-snap-distance` 600,
    which the developer ruled out for real routes; the shipped-settings run then showed that scene 1 by road still ends
    on the stair house's lower landing (straight-line road goal), which F1 does not fix. Filed as #780 (sub-issue of
    #698) with two options for the developer: (a) a road to the hall (data, fits the road-network plan), (b) choose
    the road goal by walk reachability (code). The watchtower roof works at shipped limits. Engine and NPC coordinators
    told; the NPC chain files its own follow-up for the hatch in the NPC body check.
37. **Fix link F2 started (2026-11-19 12:26, developer's go).** Developer decisions: #780 both (a: a road to the
    keep storage hall, the developer's; b: road goal by walk reachability, F2) and #771 items 3–5 into F2. Every
    behaviour change sits behind a key off by default (item 3: `trail-leg-spacing` also with `guidance-v2` off,
    default 3.0), so today's routes and L7's golden transcripts stay as they are. Alternatives: (a) unflagged bug
    fixes; rejected, the road-goal change alters many routes and the chain's rule 1 keeps new behaviour behind keys;
    (b) separate links for #780 and #771; rejected, items 4 and 5 sit in the same route-end code. Engine, NPC and
    siege weapons coordinators told; F2 holds the plugin navigation slot.
38. **F2 merged into `next` (2026-11-19 14:33).** § 6 checks held: heads matched, branches contained `next`, `build`
    and `paper-boot` green on both runs of `ebc63265`, every change behind keys off by default
    (`road-goal-reachable`, `road-goal-candidates`, `road-to-its-end`) and `trail-leg-spacing` 3.0, no NPC,
    destinations or shape file, golden transcripts and flag-off tests unchanged, smoke § 13 at shipped settings, no
    Codex findings (usage limit). C1's NPC join is private and could not leave the dead end; F2 applies the same
    principle for players (NPC coordinator told; a shared rule is their call). #780 closes on promotion; #771 stays
    open until the developer's test tells which cause of item 5 they saw. The plugin slot is free.
39. **Developer's live smoke test, 2026-11-19 evening (summary on #698).** Passed: #780 (b) (storage hall reached by
    road with the key on), #771 item 2 (hatch both ways; closed hatch never passed), #771 item 3 (`trail-leg-spacing`,
    developer chose 2.0 for the dev server), #710 shape on the spiral stair and a corridor corner. Failed: (1) the
    road-goal rule stops the road too early (Keep Tower Roof walk 202 vs 161; watchtower goal not moved) and repeats
    the first turn message 4× with the keys on; (2) a 0-expansion first walk search from plain roof floor on the
    Garrison Watchtower Roof; (3, provisional) with `guidance-v2` on, an open normal door near 1404 104 -494 is not
    crossed. Developer kept `road-goal-reachable` and `road-to-its-end` off until fixed. Not run: § 8 steps 6–7, § 9,
    § 10.2, § 3, § 5, § 6, § 7, L1's open items.
40. **Fix link F3 started (2026-11-20 09:09)** for the four failures (skill § 8: a failed live test gets a fix link).
    The NPC coordinator is told that #710's spiral shape passed (their wait) but the flag-on door crossing is a
    provisional failure, and that G1 (#814) should wait for F3's `RoadGoalChoice` change. Non-navigation findings of
    the session (SignalR `TerritoryChanged` bind error, InventoryMenu validation for duel/arena menus) are reported to
    the developer for the owning chains.

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

### 4.8 L5 — Phase 2: walk links, route as a leg list, block-change hook (#705)

1. **Scope done.** Everything is behind `navigation.walk-links`, off by default.
    1. knk-core `core/roads/route/`:
        1. `WalkLinkId`: its own id space, a separate type with value ≥ 2^62 (O17).
        2. `WalkLink`: a path in network convention, length, walk cost, regions, gate doors and the chunks of its box widened by one block; `tagsEdge()` is a probe for the access policy.
        3. `WalkLinkSource`: the router port.
        4. `Route.LinkStep`, `WalkLinkStretch`, `legs()` (road and walk-link legs in any order), `buildPieces`, `stepPolylineStart`, `walkLinkAt`. A road-only route is built by the unchanged `build`.
        5. `AStarRouter.route(request, links)` and `routeOrExplain(request, links)`.
        6. `AccessPolicy.checkWalkLink`; `CompositeAccessPolicy` does not cache it.
        7. `Maneuver.Kind.WALK` ("Leave the road and walk across").
    2. knk-core `core/roads/links/`:
        1. `WalkLinkCandidates`: range 40, ratio 2.0, junctions, end points, anchors and named nodes in one component (O28).
        2. `WalkLinkCache`: per player, TTL 600, retry 600, `claim`, per-chunk invalidation, `dropNone`, LRU of 4 096 entries.
        3. `WalkLinkPlanner` (per request), `WalkLinkCounters`, `RoadFirstRule`.
        4. The port `core/roads/walk/TerrainChangeListener` (O18).
        5. `NavigationSession.onWalkLinksFound`.
    3. knk-paper:
        1. `NavigationService`, new section "walk links and mixed routes":
            1. The planner goes into `computeRoute`, and the wanted links are searched after the route.
            2. A FIFO queue of at most 32 searches; at most `max-concurrent-searches - 1` run at once (at least 1).
            3. Captures and access go through the walk preparer.
            4. A found link is tagged on the main thread, cached, and the session asks for an improvement.
            5. The D13 re-check covers links; a gate or availability change drops the "none" entries; a network change clears the world.
            6. Road-first runs in `walkDelivered` for a found direct path.
        2. `TrailRenderer` draws link stretches on the road trail's fixed spots in the leg colour.
        3. `walk/WalkTerrainListener`: place, break, burn, fade, form, explosions, pistons, entity changes; MONITOR, batched per chunk every 20 ticks.
        4. `walk/WalkLinkTagger`: WorldGuard regions every second point, gate doors at feet and head.
        5. Eight config keys, `NavigationConfig.WalkLinksConfig`, `/knk road status` lines, the `roadFirst` message, and the `KnKPlugin.startWalkLinks` wiring.
    4. knk-workspace:
        1. Smoke test § 3: 14 steps, 13 automated (5 in part).
        2. Plugin configuration § 4.15 and § 2.1.
        3. CHANGELOG (Unreleased).
        4. DESIGN § 5.2.6 (road-first) and § 5.2.7 (as built).
    5. Kept stable for the NPC chain: the public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and the shape package. `core/navigation/destinations` and the engine-handle code are untouched.
2. **Commits and heads.** knk-plugin `claude/offroad-walk-links` at `5b4f666d` (2 commits, base `next` at `4daa0c84`); knk-workspace `claude/offroad-walk-links` at `06b3f92a` (2 commits, base `next` at `79b118ef`).
3. **PRs.** [PandiO/knk-plugin#85](https://github.com/PandiO/knk-plugin/pull/85) (`Closes #705`), [PandiO/knk-workspace#774](https://github.com/PandiO/knk-workspace/pull/774) (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`): baseline on `next` `4daa0c84` was knk-core 3 343, knk-api-client 358 (2 skipped), knk-paper 3 096 (18 skipped), all green. The result on the branch is knk-core 3 382 (+39), knk-api-client 358, knk-paper 3 111 (+15), no failures. CI on `5b4f666d`: build and paper-boot green (runs 44394049451, 44394049111; the push runs 44394040072, 44394039949 green too).
    2. New tests:
        1. knk-core: `WalkLinkIdTest`, `WalkLinkCandidatesTest`, `WalkLinkCacheTest`, `WalkLinkRoutingTest`, `RoadFirstRuleTest`, one `NavigationSessionTest`.
        2. knk-paper: `NavigationServiceWalkLinksTest` (10, including the flag-off transcript, the road-to-walk handover and an NPC plan without links), `WalkTerrainListenerTest` (MockBukkit, 4), one `ConfigLoaderNavigationTest`.
    3. L3, L4 and L10's flag-off identity tests and the engine's handle tests are unchanged and green.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *How "lazy" works with an asynchronous walk search.* Chosen: the first route is today's road route; the A\* records the unsearched candidates it met with a lower bound (cost to the From node + straight × cheapest factor + heuristic from the To node). The candidates whose bound beats the found route are searched afterwards, at most `walk-link-searches-per-route` (4, cheapest first). A found link makes the session ask for an improvement (kept unless clearly shorter). This keeps the router synchronous and pure, and the first trail as fast as today. Alternatives: (a) hold the first route until the link searches return: a delay of one or more walk searches for every navigation; (b) search every candidate of every expanded node: far more searches than useful.
    2. *Whose access a cached link carries.* Chosen: cache per player, because the walk search used that player's cell access (WorldGuard door use, gates, regions). The link's regions and gate doors are judged by the player's access policy at every route and by D13. Alternatives: (a) one link for everyone, searched with open access and re-checked cell by cell per player: needs the player's door and region answers for the link's box on the main thread at each route; (b) a link per access fingerprint: no such fingerprint exists today.
    3. *Probe edge for the policy.* Chosen: the policies judge edges, so a link's tags go in a probe `RoadEdge` with id `Integer.MIN_VALUE`. It is never in a snapshot or route, and `CompositeAccessPolicy.checkWalkLink` does not touch its per-edge-id cache. Alternatives: (a) a second method on every policy for tags: more surface for the same answer; (b) a probe id from the link: link ids are not ints (O17).
    4. *Which nodes are link ends.* Chosen: junctions, end points, anchors and named nodes of one network component; split and boundary nodes are plumbing (the same rule as maneuvers), pruned nodes are not routed on. Alternatives: (a) every node: gate split nodes would give links that start at a door; (b) also across components: the router refuses different components before searching, so such links could never be used without changing that rule.
    5. *Link cost.* Chosen: walk cost × max(1, cheapest road factor), and never below straight × cheapest factor, which keeps the heuristic admissible. Alternatives: (a) walk length only: below the heuristic when every class cost is above 1; (b) a separate config factor: a key nobody asked for.
    6. *Concurrency (budget 5).* Chosen: link searches share the walk pool, at most `max-concurrent-searches - 1` at once (1 with the shipped 2), queue of 32, skipped beyond that and counted ("dropped first under load", § 9.3.4). Alternatives: (a) as many as the pool: a walk leg could wait behind two link searches; (b) a separate pool: more threads than the measured budget.
    7. *Block-change hook.* Chosen: MONITOR place, break, burn, fade, form, block and entity explosions, pistons and entity block changes, one batch per chunk every 20 ticks. A link's chunks are its path's box widened by one block. A gate or rule change drops every "none"; a network change clears the world (node ids may mean other places). WorldEdit is left to the TTL. Alternatives: (a) also physics and liquid flow: too frequent for what changes a walk path; (b) a WorldEdit extent hook like the road dirty tracker: more code for a rare staff action that the TTL covers.
    8. *Road-first rule (the developer's wish, #698, 2026-11-18).* Chosen: only in direct mode (within `max-snap-distance`, unchanged), once per navigation after the first found walk path. Lengths in walked blocks; the walks to and from the road are estimated at 1.5 × straight, as in L4's join point. Keys `road-first-share` 0.6 ("most of the way") and `road-first-max-ratio` 1.5 ("similar cost"), **for the developer to confirm.** Alternatives: (a) compare routing costs: class factors make the numbers hard to read; (b) search the two end walks before deciding: two more walk searches for a question asked once; (c) share 0.5 / ratio 2.0: takes the road where it is clearly the longer way; (d) share 0.75 / ratio 1.25: misses scenes 1 to 3's 75 to 80 % road share at the edge.
    9. *Trail of a link stretch.* Chosen: the road trail's fixed 1.5 spots inside a link drawn as points in the leg colour, not centred on a road (O20: off-road legs in the leg colour). Alternatives: (a) the anchored walk trail at 3.0 from the link's start: two anchor systems on one route window; (b) road colour: hides that the player leaves the road.
    10. *Plugin scenario.* Chosen: none. The scenario framework has no loaded courtyard world with a road graph, so building one is more than "cheap"; the core and service tests cover the rules and steps 1, 2 and 5 to 8 are live. Alternative: (a) a scenario that builds a courtyard and a hand-made snapshot: a day's work for a check the developer's live test makes anyway.
    11. *Budgets (report § 3.3).* Budget 1: link captures go through `WalkSnapshotService` within its tick budget. Budget 2: a link search is a plain walk search within the `walk:` budget, so the 150 ms p95 holds for ≤ 40-block links. Budget 3: not used (no hierarchical search). Budget 4 (memory, 22 to 30 KB per chunk): it applies to the clusters of L6; walk-link entries hold only paths (about 4 096 × a few hundred bytes); captured chunks are the walk capture's 256-chunk cache. Budget 5: as in decision 6. Budget 6: the `/knk road status` link lines.
    12. *Destination engine (coordinator note, 2026-11-18).* Chosen: the walk-link code hangs off the shared session path (`computeRoute`, reached from `begin`) and direct mode's `walkDelivered`. Road-first builds its goals like `tryRoadsInstead` does, from the leg's target and a `Destination.point` value. Nothing uses `navigate(Player, Destination)`, `setHandleOnly`, `NavigationDestinations`, `NavigationEligibility`, `MatchNavigationScope` or `EndReason.SIEGE`, so #747's removal stays mechanical. Alternative: (a) a hook in the raw `navigate(Player, Destination)` entry: removed later.
    13. *NPC plans (coordinator note, NPC chain).* Chosen: no per-request option is needed. Only the player's `computeRoute` passes a `WalkLinkPlanner`; `planRoadFor` (the NPC port) keeps calling `routeOrExplain(request)` without a link source, so NPC plans are today's with the flag on or off. Road-first lives in the player's direct mode only. Tested by `NavigationServiceWalkLinksTest.anNpcRoadPlanNeverTakesAWalkLink`. Alternative: (a) a `RouteRequest` option: a field on a shared record for a difference the call site already makes.
    14. *Road-to-walk handover (coordinator note, the developer's scene 3).* Checked: with the flag on, the last walk leg starts only at the road's end (within `arrive-distance` of it). A walk link is part of the route, not a leg that takes over. Tested by `theRoadTrailKeepsTheLeadUntilTheRoadsEnd`. The flag-off case is #771 item 5, untouched.
6. **Out of scope, noted.**
    1. None filed. The coordinator's list (#771: scene 1 stuck, trapdoor over ladder, sparse trail in grass, road overshoot, garrison gate end) is untouched.
    2. Known limits of this phase:
        1. WorldEdit edits are caught by the TTL only.
        2. A link searched for one player is not shared with others.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-18 20:40), so the link finished without its review, as the developer decided on 2026-11-14. This is said on both PRs.
8. **At merge / what the developer must do.**
    1. Under `navigation:` add the keys below and restart. They change nothing while `walk-links` is false.
       ```yaml
         walk-links: false
         walk-link-range: 40
         walk-link-ratio: 2.0
         walk-link-ttl-seconds: 600
         walk-link-retry-seconds: 600
         walk-link-searches-per-route: 4
         road-first-share: 0.6
         road-first-max-ratio: 1.5
       ```
    2. Live test (tier:3): set `walk-links: true` and restart, then run smoke test § 3. Pick a courtyard (two junctions at most 40 apart, more than twice that by road), a region on it and a gate on its exit. Steps 1, 2, 5 to 9 and 12 are manual; step 9 is scene 7 for road-first.
    3. Confirm or change `road-first-share` 0.6 and `road-first-max-ratio` 1.5 after step 9, and `walk-link-range` and `walk-link-ratio` (O28).
9. **Notes for later links.**
    1. L6 (hierarchical search):
        1. Clusters can reuse `TerrainChangeListener`; `WalkTerrainListener` takes one target, so wrap the cache and the clusters in a composite listener.
        2. The walk-link entries are not the cluster cache; budget 4 is L6's.
    2. L7 (route modes):
        1. A link's routing cost is set in `WalkLinkPlanner`; `shortest` would use `link.length()` and `efficient` its walk cost.
        2. Make `Route.buildPieces` and `ManeuverBuilder.buildWithLinks` mode-aware if needed.
    3. L9 (landmark nodes): `WalkLinkCandidates.takesPart` decides which nodes are link ends.
    4. L10's note (one `PlazaTrail` per leg or one over the joined polyline): a route with links has one joined polyline (the link paths are part of it), so the plaza crossings are projected onto it as before.
    5. Local builds: the Maven Central mirror init script (L1's note) worked again.

### 4.9 L7 — Phase 4: route modes shortest, efficient, preferred (#707)

1. **Scope done.** No flag (tier:2); the default `preferred` is today's routing exactly (O24).
    1. knk-core (Bukkit-free, DESIGN § 11):
        1. `roads/route/RouteMode`: the words, the nodes `knk.navigate.mode.<word>`, the road factor per mode (`preferred` multiplies in today's order, so the numbers are bit-identical), a walk link's cost per mode, `lengthOnlyWalk()`, and the seam `usesPreferenceWeights()` (true for `preferred` only) for L9.
        2. `RouteRequest.mode` (the old 4-argument constructor and `of(...)` default to `preferred`), `withMode`; `withPolicy`/`withStart` keep the mode.
        3. `RoadNetworkSnapshot.costFactor/edgeCost/minCostFactor(..., mode)`; the old methods are the default mode. `AStarRouter` prices edges, the heuristic (the mode's smallest factor, DESIGN § 5.4.4) and the route by the request's mode. `Route.mode()`; `truncated` and `withVerdicts` rebuild in the route's mode.
        4. `MovementProfile.forMode(mode)` (the same instance for `preferred` and `efficient`) and `lengthOnly()` (no jump, drop, door, wall or clearance cost; water and ladders at 1; what the mover can do unchanged).
        5. `WalkLinkPlanner(..., minFactor, mode)`: a link costs `mode.linkCost(link)` (its walked length in `shortest`, its walk cost otherwise) × max(1, the mode's cheapest road factor).
    2. knk-paper:
        1. `NavigationService.navigate(Player, AllowedDestination, RouteMode)` and `navigate(Player, Destination, RouteMode)`; both reach the shared `begin(player, destination, mode)`, which puts the mode on `Active`. It reaches `computeRoute`, the road-first and roads-instead requests, walk legs (`forMode` on the walk thread, before the search) and link prices (`linkPlanner`). The old 2-argument entries call the new ones with the default.
        2. `NavigateCommand`: `parseRoute` (mode word before the trailing `spawn`/`region`), the node check through `CommandPermissions.whenAllowed` (set by `KnKPlugin.setModePermissions`), completion of the held words through `hasForCompletion`, on both paths (engine on and off). Without a word the command makes exactly today's call.
        3. `plugin.yml`: usage, and the three nodes with `default: op`.
    3. knk-workspace: smoke test § 5 (9 steps, 8 automated, 2 in part), commands guide, navigation admin guide § 1, permission checks § 4, plugin configuration § 4.15 (no key), DESIGN § 5.4.7, CHANGELOG (Unreleased).
    4. Coordinator additions (2026-11-18): (a) destination engine: the mode-word parsing, node check and completion live once in `NavigateCommand` (`parseRoute`, `withMode`, `addTrailingWords`, `endsWithRouteMode`), called from both branches; the engine path has its own tests (`NavigateCommandRouteModeTest.throughTheEngine…`), so #747 deletes the flag-off branch's call sites without moving this code; (b) NPC chain: `RoadPlanner`'s port and `planRoadFor` are unchanged (not in the diff); NPC plans route in the default `preferred` with today's costs.
    5. Kept stable: the public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and the shape package (additions only). `core/navigation/destinations` untouched (the handle needs no field: the mode is a `navigate` argument). Nothing lives in code only the raw entry uses, so #747's removal of `navigate(Player, Destination)` stays mechanical (its mode overload goes with it).
2. **Commits and heads.** knk-plugin `claude/offroad-route-modes` at `d374b016` (1 commit, base `next` at `3977329c`); knk-workspace `claude/offroad-route-modes` at `ed01ab75` (1 commit, base `next` at `e2cac646`).
3. **PRs.** [PandiO/knk-plugin#86](https://github.com/PandiO/knk-plugin/pull/86) (`Closes #707`), [PandiO/knk-workspace#775](https://github.com/PandiO/knk-workspace/pull/775) (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `3977329c` knk-core 3 382, knk-api-client 358 (2 skipped), knk-paper 3 111 (18 skipped), all green. Result: knk-core 3 399 (+17), knk-api-client 358 (2 skipped), knk-paper 3 126 (+15, 18 skipped), no failures. CI on `d374b016`: `build` and `paper-boot` green on the push runs (44403197365, 44403197359) and the pull-request runs (44403286273, 44403284686), 2026-11-18 22:02 UTC.
    2. New tests:
        1. Default = today (O24): golden transcripts written on `next` `3977329c` with the pre-phase API only (`knk-core/src/test/resources/route-modes/`, 276 KB): road routing (five scenes, every node pair, mid-edge starts, a shut gate with the explainer's partial routes, a multi-goal request), routing with walk links off and on (four link cases, the wanted bounds), walk legs (doors, gate, gap, water, ladder, stairs, drop, fields; three profiles). `RouteModeDefaultTranscriptTest`, `LinkRouteDefaultTranscriptTest`, `WalkLegDefaultTranscriptTest` compare the default and `preferred` character for character; switching the default to `efficient` fails them (checked).
        2. Per mode: `RouteModeTest` (A09 road scene with three different roads, A11, factors, admissibility with a multiplier below 1, rebuilt routes), `WalkRouteModeTest`, `WalkLinkRouteModeTest`.
        3. knk-paper: `NavigateCommandRouteModeTest` (9), `NavigationServiceRouteModeTest` (6); a mutation run (mode dropped in `computeRoute`, node check bypassed) failed 6 of them.
    3. L3, L4, L5 and L10's flag-off identity tests, the engine's handle tests and the NPC tests are unchanged and green.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the mode travels.* Chosen: a `RouteRequest` field (default `preferred`) plus a field on the session set in the shared `begin`, and an extra `navigate(..., RouteMode)` overload per entry; the old signatures delegate with the default. Alternatives: (a) a field on `AllowedDestination`: changes the engine's handle (keep-out area) and leaves the raw entry without it; (b) a `RouteMode` on `RouterParameters`: one value per server, not per navigation.
    2. *`shortest` on walk legs.* Chosen: every move priced as one block per block walked, and the wall and clearance costs dropped too ("length only", § 5.4.1); the shaping of the drawn trail is unchanged (it reads only what the mover can do). Alternatives: (a) keep the wall/clearance cost: it is a profile extra cost, not length; (b) drop doors etc. from the walkable set: the spec says they stay passable.
    3. *Walk links in `shortest`.* Chosen: the cached link keeps the path its search found with today's profile and is priced by its walked length; one cache for all modes. Alternatives: (a) a link cache per mode: twice the searches and memory for a mode few use; (b) price by walk cost in every mode: `shortest` would ignore a short shortcut with a door.
    4. *Refusal message.* Chosen: `CommandPermissions.whenAllowed`'s "You don't have permission to use this command." (and "can't be checked right now" during an API outage), checked once the destination is resolved. Alternatives: (a) a mode-specific line via `hasAsync`: loses the outage answer; (b) check before resolving: refuses a destination whose name merely ends in a mode word.
    5. *Word order.* Chosen: strictly `<dest> [mode] [spawn|region]` (DESIGN § 4.4); after `spawn`/`region` a mode word is part of the name; a lone word is a name. Through the engine, a name not found with the words split is tried whole (as for `spawn`). Alternatives: (a) accept both orders: `region` could not be part of a name any more.
    6. *Siege match on the old path (engine off).* Chosen: no mode word there (the match names are matched on the whole text, as today). Alternative: (a) split the mode there too: changes today's match matching.
    7. *Default-equals-today proof.* Chosen: golden transcripts generated on the base branch by helper files that use only the old API, kept as test resources (276 KB in all after trimming polylines to steps, size and length). Alternatives: (a) compare the default with `preferred` on the branch only: proves nothing about today; (b) a hash of the transcript: tiny but no diff to read when it breaks.
    8. *Node grants.* Chosen: `default: op` in `plugin.yml`, no seed; the PR proposes staff only (prompt). Alternative: (a) the default player group in the seed (O25's text): the prompt leaves it to the developer.
    9. *Plugin scenario.* Chosen: none; the routing is pure core logic covered by the transcripts and per-mode tests, and the command by the Mockito command tests. `MIN_SCENARIOS` unchanged. Alternative: (a) a scenario with a fake player typing the words: a real server for what the command tests already pin.
6. **Out of scope, noted.** None filed. `/navigate` explanations (`explain`, `/knk road why`) route in the default mode.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-18 21:36 and 21:37 UTC), so the link finished without its review, as the developer decided on 2026-11-14; said on both PRs.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml` (no key); restart after the deploy.
    2. Grant `knk.navigate.mode.shortest`, `knk.navigate.mode.efficient`, `knk.navigate.mode.preferred` to the groups that should choose modes (proposal: staff only for now; the default group later through a knk-web-api seed if wanted). Without a grant only operators can type a word.
    3. Live test (about 15 minutes): smoke test § 5, steps 2, 3 and 9 (a road pair with a test multiplier, the stair house), the rest is automated.
9. **Notes for later links.**
    1. L9 (#709): `RouteMode.usesPreferenceWeights()` is the seam; the mode reaches the walk request in `NavigationService.forMode` (walk thread), where a weight lookup can wrap the request. `RouteMode.PREFERRED` and `EFFICIENT` share the walk profile today, so `forMode` is the place where they part. Keep the default transcripts green: with no preference landmark a `preferred` walk must stay today's.
    2. #747 (engine L5): `navigate(Player, Destination, RouteMode)` goes with `navigate(Player, Destination)`; the command's old path calls it in one place.

### 4.10 L9 — Phase 5.2: landmark preference weights, landmark nodes in the walk planner (#709)

1. **Scope done.** Everything is behind `navigation.landmarks` (off by default). Tier 2, no migration.
    1. knk-core (Bukkit-free, DESIGN § 11):
        1. `roads/walk/WalkCellWeights` (port: a multiplier per cell, the heuristic's scale, `NONE`).
        2. `WalkRequest.weights` (a new last component, default `NONE`, old constructor kept), `withWeights`, `reachBox()` (the box of the length cap's ellipsoid).
        3. `WalkSearch`: the cost of entering a cell × its multiplier; the heuristic × `minMultiplier()`; with `NONE` the loop is today's.
        4. `landmarks/LandmarkWeights`: `areas(...)` (main thread, Region extents through a shape lookup), `within(box)` (walk thread), product held between `1 / preference-max` and `preference-max`.
        5. `landmarks/LandmarkLinkNodes` and `WalkLinkCandidates(snapshot, range, ratio, landmarkNodes, connections)`: landmark nodes as link ends, blocked stored pairs dropped (`LandmarkConnections.INFERRED` in v1, O05).
        6. The model's `Landmark.preference` (+ `weighted()`, the 5.1 constructor kept), `KnkLandmark.toModel()` carries it, snapshot `LandmarkFile.preference` (schema 1, a missing field reads 1.0).
    2. knk-paper:
        1. `NavigationService.Landmarks` port and `setLandmarks`, `walkWeights` (main thread, `preferred` only), `forMode(request, mode, weights)` (walk thread), `candidatesFor` with landmark nodes.
        2. `navigation/engine/ModelLandmarks` (model landmarks, WorldGuard shapes, link nodes kept per snapshot and landmark list).
        3. `LandmarksConfig.preferenceMax`, `config.yml` `navigation.preference-max: 4.0`, the `KnKPlugin` wiring (only with the flag on).
    3. knk-workspace: smoke test § 7 (8 steps, 7 automated, 3 in part), plugin configuration § 4.15 and § 2.1, CHANGELOG (Unreleased), DESIGN § 5.4.8.
    4. NPC walk legs (the NPC chain coordinator's addition, relayed 2026-11-18 22:07): landmark weights enter only through `NavigationService.forMode` in `preferred`; `NpcWalkPlanner` builds its own requests (no weights) and is unchanged. Test: knk-paper `NpcWalkPlannerTest.anNpcWalkLegHasTheSameCostAndPathWithLandmarkWeightsOnOrOff` (same path and cost, while the same request as a weighted player leg goes round). Guards: the paper-boot scenarios `npc-replay-keep-tower`, `npc-offroad-detour`, `npc-offroad-ravine`, `npc-offroad-upstairs`.
    5. Kept stable: the public signatures of `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile`, the shape package (additions only); `RoadPlanner`'s port and `planRoadFor` untouched; `core/navigation/destinations` and the engine handle untouched; nothing on the old `/navigate`-only path.
2. **Commits and heads.** knk-plugin `claude/offroad-landmark-weights` at `636c9f32` (2 commits, base `next` `a94332d9`); knk-workspace `claude/offroad-landmark-weights` at `9d0c926f` (1 commit, base `next`).
3. **PRs.** [PandiO/knk-plugin#87](https://github.com/PandiO/knk-plugin/pull/87) (`Closes #709`), [PandiO/knk-workspace#776](https://github.com/PandiO/knk-workspace/pull/776) (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `a94332d9` knk-core 3 399, knk-api-client 358 (2 skipped), knk-paper 3 126 (18 skipped), all green; result knk-core 3 423 (+24), knk-api-client 358 (one assertion now expects the preference in the model), knk-paper 3 137 (+11) on `7c04ed16`, plus 1 (`NpcWalkPlannerTest`, 9 of 9 green) on `636c9f32`, 0 failures. CI on `636c9f32`: see the PR.
    2. New: knk-core `LandmarkWeightsTest`, `WalkPreferenceWeightsTest` (A10 avoid/attract, admissibility against a Dijkstra, no weights = today cell by cell), `LandmarkLinkNodesTest`, `WalkLinkLandmarkNodesTest`, two `NavigationModelSnapshotTest`; knk-paper `NavigationServiceLandmarkWeightsTest` (7), `ModelLandmarksTest` (3), one `LandmarksConfigTest`. With the multiplier or the heuristic scale removed, `WalkPreferenceWeightsTest` fails.
    3. L7's golden transcripts and L3/L4/L5/L10's flag-off identity tests unchanged and green. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *What the multiplier multiplies.* Chosen: the whole cost of entering a cell (move, water, door, wall or clearance), not the access verdict. Alternative: (a) the move only; a door in a weighted hall would cost as outside.
    2. *Lower bound of overlaps.* Chosen: `1 / preference-max` (0.25). Alternative: (a) none; 0.25 × 0.25 = 0.0625 weakens the heuristic for little gain.
    3. *Heuristic scale.* Chosen: the product of the weights below 1.0 near the leg, at least the floor, at most 1.0. Alternatives: (a) the spec's "above 1.0 when all weights are above 1.0": cells outside every area cost 1.0, so this is admissible only if the extents covered the search area, never known; (b) the smallest single weight: not a bound where weights below 1.0 overlap.
    4. *Walk links.* Chosen: no weights on link searches; a cached link is shared across modes (L7), a weighted one would leak into `efficient`. Alternative: (a) weighted searches in `preferred` with a cache per mode: twice the cache for a rare case.
    5. *A landmark not offered as a destination.* Chosen: still weights its area (the weight is about the place). Alternative: (a) ignore it: ties two staff settings together.
    6. *"On the road".* Chosen: the nearest road node within 4 across and 3 up or down; never a split node (routing time only) or a tombstone; a boundary node takes part when a landmark stands on it. Alternative: (a) every node inside the extent: a plaza of link ends.
    7. *Per-request lookup.* Chosen: shapes resolved on the main thread per walk request (a few landmarks, `WorldGuardRegionShapes`), cut to the reach box on the walk thread; per cell a box test per kept area. Alternative: (a) a per-request cell grid: memory for every capture where a few box tests suffice.
    8. *No paper-boot scenario.* Chosen: core search tests and MockBukkit service tests (cheap, deterministic); the keep is the developer's live step. Alternative: (a) a scenario with a fixed model and a built hall: not cheap with the model refresher in the way.
6. **Out of scope, noted.** None filed. Landmark nodes in the cluster graph (§ 5.3.3) are L6's (#706, not built): the seam is `LandmarkLinkNodes` plus `NavigationService.Landmarks`. The trail's shaping (phase 6.1) can cut a corner of a weighted area; the search path itself respects it.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-18 22:22 UTC), so the link finished without its review (developer decision 2026-11-14); said on both PRs.
8. **At merge / what the developer must do.**
    1. Under `navigation:` in the plugin's `config.yml`, next to `landmarks:`, add `preference-max: 4.0` and restart (no effect while `landmarks` is false).
    2. Live test (about 15 minutes): smoke test § 7 steps 1 to 3 in the keep (two corridors, the shorter one in a region landmark with `Preference` 2.0 set in the web app), with `landmarks: true` and `destination-engine: true`.
9. **Notes for later links.**
    1. L6 (#706): landmark nodes join the abstract graph per § 5.3.3; `LandmarkLinkNodes` finds road nodes only, a cluster node needs the landmark's pin (`ModelLandmarks` has the model). Hierarchical refinement searches should get the request's `weights` (`WalkRequest.withWeights` keeps them through the `with*` methods).
    2. #747 (engine L5): nothing of L9 is on the old path.

### 4.11 F1 — walk-search fixes (#771)

1. **Scope done.** #771 items 1 and 2, tier:2, no flag (they make valid routes work), no config key, no migration. Items 3 to 5 stay open on #771.
    1. **Item 1, scene 1 stuck at 1417 59 -489.** The hypothesis was **wrong**: the storage hall is a point Location (L1's run 2 note 5), so no region target was re-derived. The real cause, reproduced on the keep snapshot `quarry-to-keep-stairhouse.zip`:
        1. The first search (from the snapshot's edge on the way from spawn) finds the way: up the keep stair house's lower flights, passing 3 to 4 blocks from the stuck spot, out south to about z -551, round through the courtyard and back to the hall. It is about 410 blocks; the runs had 371 to 416.
        2. A recompute happens when the player is more than `recompute-distance` off the path, or the path is `chunk-ttl-seconds` old. Run from inside the keep, it captured only the box round the player and the hall, and capped the length for a 17-block leg. The way runs about 60 blocks south of that box and is much longer than the cap.
        3. The result: NO_PATH with run 2's limits and FALLBACK (length) with the shipped ones, at margin 16 and at margin 48, from the stuck spot and from on the first path alike. This matches the runs' "the search area closes inside the capture box". The player was on or next to the first path, so the answer to the run's open question is "on the first path".
        4. **Fix:** a walk leg keeps its last found path (`DirectLeg.foundPath`, kept after a failed search too). Its next request carries a `WalkRecomputeHint` (knk-core):
            1. The rest of the path, from the player's nearest point on it, stays in the capture: `WalkBox.including`, with `WalkLegPreparer.HINT_MARGIN` 3, unless that goes over `max-chunks-per-request`.
            2. Its length stays in the cap: `WalkBudget.withLengthAtLeast`, set to the remaining length plus twice the player's distance from the path plus 8.
            3. On the snapshot the box grows from 9 to 18 chunks (margin 16) or from 49 to 56 (margin 48), and the recompute finds the way again (290 blocks).
            4. Both `guidance-v2` paths go through `requestWalk`, so flag off and flag on are both fixed. The first search of a leg has no hint and is exactly as before.
    2. **Item 2, open trapdoor over a ladder.** At the watchtower the hatch is an open spruce trapdoor at 1400 107 -540, with a ladder at 1400 99..106 -540 below it; the roof floor is at 106. Passability is by material name (`Material.isCollidable`), so the open trapdoor was a solid block and the roof was shut in. On the `keep-tower.zip` snapshot that gives exactly the runs' 44 cells.
        1. **Fix:** an open trapdoor directly above a climbable is climbable (`WalkCells.isClimbableHatch`, `PassabilityRules.isTrapdoor`): passable and never a floor.
        2. The capture reads the open state from the chunk snapshot through `SpanExtractor.BlockSource.isOpen`, a default method (`Openable.isOpen()` on the server). It is asked for trapdoors only.
        3. A closed trapdoor stays solid: it can be stood on and is never passed. There is no door-like access rule for trapdoors today (`isHandOpenableDoor` excludes them), so "otherwise blocked" applies. An open trapdoor with no climbable below is unchanged.
        4. Both layouts pass, up and down: the hatch in the roof above the ladder, and the hatch at feet level above a ladder that reaches the roof (the watchtower).
    3. **NPC walk legs.** The trapdoor rule reaches their captures (the same `WalkChunkExtractor`), as wanted. The recompute hint does not: NPC legs use `WalkLegPreparer.capture`, not `prepare`. The NPC body check (`NpcWalkPlanner.BodyCheck`) still treats an open trapdoor's panel as blocking, so an NPC plan through a hatch is still checked as before. paper-boot `npc-*` outcomes: see item 4.
    4. Kept stable (additions only): the public signatures of `WalkLegPreparer` (new 6-argument `prepare`, the 5-argument one delegates), `NavigationService.WalkPreparer` (a default 6-argument `prepare`), `WalkSearch`/`WalkPathfinder` (untouched), `MovementProfile` (untouched) and the shape package (untouched). `core/navigation/destinations`, the engine handle, `core/npc` and `paper/npc` are untouched.
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-walk-fixes-771` at `321daf6b` (2 commits, base `next` `c7be34fb`).
    2. knk-workspace `claude/offroad-walk-fixes-771` at `f2c94b7e` (1 commit, base `next`).
3. **PRs.** [PandiO/knk-plugin#88](https://github.com/PandiO/knk-plugin/pull/88) and [PandiO/knk-workspace#778](https://github.com/PandiO/knk-workspace/pull/778), both `Part of #771`, base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`, baseline on `next` `c7be34fb`:
        1. knk-core 3 423 → 3 435 (+12).
        2. knk-paper 3 138 → 3 147 (+9, 18 skipped as before).
        3. knk-api-client 358 → 358.
        4. 0 failures; known reds: none.
    2. New tests:
        1. knk-core `WalkTrapdoorHatchTest` (8): up, down, closed, closed still a floor, no ladder below, hatch at feet level, the rule's truth table, material names alone unchanged.
        2. knk-core `WalkRecomputeHintTest` (4).
        3. knk-paper `WalkDevWorldFixesTest` (3, on the two dev-world snapshots: scene 1's recompute today versus with the hint, at both margins and with the shipped limits; scene 8 at 44 cells before and found down and up after).
        4. knk-paper `WalkLegPreparerTest` +3, `NavigationServiceTest` +2 (the hint on recompute, kept after a failed search, `guidance-v2` on), `WalkSnapshotServiceTest` +1 (the open state from the snapshot).
    3. Unchanged and green: L7's golden transcripts (`WalkLegDefaultTranscriptTest`), L3/L4/L5/L9/L10's flag-off identity tests, the engine's handle tests and the NPC unit tests. No golden transcript changed.
    4. CI on `321daf6b`: green: build and paper-boot (both the push and the PR runs, every `npc-*` scenario included), no re-run needed. No `npc-*` scenario outcome changed.
5. **Decisions (DESIGN § 4.3).**
    1. *How the recompute keeps the way.* Chosen: carry the last found path into the next request (box and length cap), so the search can still find a better way. Alternatives: (a) keep drawing the old path when a recompute fails: the player's drift is not followed, and a stale path survives terrain changes; (b) the coordinator's "pick the region point reachable": not the cause, since the target is a point.
    2. *Which part of the found path.* Chosen: from the player's nearest point on it to its end. Alternative: (a) the whole path: the box would reach back to spawn for nothing.
    3. *Box margin round the hint's path.* Chosen: 3 blocks (headroom 2 plus a step aside); the chunks are captured whole anyway. Alternative: (a) the full `capture-margin`: more chunks for no gain on the known way.
    4. *Over `max-chunks-per-request`.* Chosen: the leg's own box, as before (the cap stays a hard limit). Alternative: (a) a TOO_LARGE capture: a straight line instead of a search.
    5. *Length floor.* Chosen: remaining length + 2 × the player's distance from the path + 8, through `maxLength`/`detourAllowance` raised just enough. Alternative: (a) only the box: with the shipped limits (`max-length` 144) the 17-block leg's cap (about 130) still cuts the 290-block way.
    6. *Hatch facing.* Chosen: the trapdoor's facing is not asked (vanilla climbs it only when it faces like the ladder, but a player passes an open hatch either way). Alternative: (a) require matching facing: needs another block-state read for a case the dev world does not have.
    7. *Iron trapdoors.* Chosen: an open one over a ladder counts too (open is open, however it was opened). Alternative: (a) wooden only: an open iron hatch would block a path a player can take.
    8. *Where the open state comes from.* Chosen: the chunk snapshot at capture time, trapdoors only. Alternative: (a) a material-name convention: the open state is not a material.
6. **Out of scope, noted.**
    1. Toggling a trapdoor fires no block event that `WalkTerrainListener` sees, and the chunk cache does not hear of it either. A walk capture keeps the state it read for up to `chunk-ttl-seconds` (10 s). This is the same as doors today and is not filed.
    2. With the shipped limits, scene 1's first search and scenes 8 and 9 are budget questions (O32: option A on walk legs), not this link's.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-19 06:31 and 06:32 UTC), so the link finished without its review (developer decision 2026-11-14); said on both PRs.
8. **At merge / what the developer must do.**
    1. Nothing to configure.
    2. Live test, about 15 minutes: smoke test § 12 steps 1 and 3, with run 2's walk limits and `max-snap-distance` 600. Restore the limits afterwards.
        1. Scene 1 from spawn to "Keep storage hall": not stuck at 1417 59 -489.
        2. Garrison Watchtower Roof to Keep Tower Roof and back, through the open hatch.
9. **Notes for later links.**
    1. A future walk change that clears `DirectLeg` state must keep `foundPath` across failed searches. It is the only memory of a way that runs outside the leg's box.
    2. #771 items 3 to 5 (trail spacing, road overshoot, road-to-walk handover) are untouched.

### 4.12 F2 — road goal and route ends (#780, #771 items 3–5)

1. **Scope done.** #780 option (b) and #771 items 3, 4 and 5; tier:2. Every behaviour change is behind a key that is off by default, or has a default equal to today's. No migration.
    1. **#780 (b), `navigation.road-goal-reachable` (false), `road-goal-candidates` (12).**
        1. The candidates are today's straight-line goal plus the nearest point of each road edge within `max-snap-distance` (plain 3D), nearest first. Points within 1 block of an earlier one are skipped. At most 12 (knk-core `RoadGoalChoice`).
        2. Each candidate gets one walk search to the destination, with the shipped `walk:` limits and the normal walk capture. The searches run one at a time per navigation on the walk executor.
        3. The reached candidates are routed to from the player on the routing thread. The least road length plus walk length wins.
        4. The first route is today's. A different goal replaces it through `NavigationSession.onNetworkChanged`, taken as it is (silent).
        5. If no candidate is reached, today's goal stays.
        6. The last walk leg starts with the chosen walk path as its `foundPath`, so the first search carries F1's `WalkRecomputeHint`.
        7. Point destinations only. It hangs off `begin` and `onNetworkChanged`, the shared path; nothing is on the raw `/navigate` entry. It reads only the session's `Destination` (kind, target), as `HandleDestinations` builds it.
    2. **Reproduced on `quarry-to-keep-stairhouse.zip`** (its `roads.json` loaded as the road graph):
        1. Today's goal is edge 2000000033 at 1415 58 -490. The walk from there ends in FALLBACK at the shipped limits.
        2. With the key on, the goal is the end of edge 2000000017 (1421 84 -521): 347 blocks by road plus 97 on foot, and the last leg is found.
        3. 6 of the about 30 per-edge candidates within 48 blocks are reached at the shipped limits. All of them are in the keep's courtyard (y 80 to 84).
    3. **#771 item 4 (scene 2) has the same cause, under the same key.** The straight-line goal for the tower roof (edge 2000000019 at 1411.5 84 -516) lies about 10 blocks past the end of edge 2000000017, where the walk to the stair leaves the road. On `keep-tower.zip` the chosen goal makes the road part 72 blocks shorter and road plus walk 38 blocks shorter. The snapshot's graph routes from spawn the long way round, so the chosen point there is earlier on that route.
    4. **#771 item 5: two causes in the code, neither depends on `guidance-v2`.**
        1. The road goal: the road part ends at a straight-line point while the road goes on. The #780 key fixes this.
        2. `onNetworkChanged` (called on every live-edge-tag swap) re-resolves goals. Within `max-snap-distance` it switched a running road session to direct mode, so a walk leg started from mid-road. New key `navigation.road-to-its-end` (false): `resolveGoals(..., keepRoad)` keeps road goals instead.
        3. Checked and ruled out on the snapshot: the session's 3D `isAtEnd` firing early. No point of the scene 3 route comes within 9 blocks of its end before the end.
        4. Which cause the developer saw is for smoke § 13 step 4. So the plugin PR says `Part of #771`.
    5. **#771 item 3.** `TrailRenderer.drawPath` (the flag-off walk trail) uses `trail-leg-spacing`. The default stays 3.0 (`LEG_SPACING`); 1.5 to 2.0 is suggested in the deploy notes.
    6. **NPC.** `planRoadFor` and `NpcWalkPlanner` are unchanged (tested). No NPC, shape or destinations file was touched. The `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile` and `RoadPlanner` signatures are untouched.
    7. **How the rule relates to the NPC chain's C1 road join** (coordinator note):
        1. C1 (`NpcNavigationService`, its decision 5.3) starts the NPC's walk to the goal at the road's end, then retries from up to 3 points further back along the same route. It takes the first reachable point.
        2. That code is private and NPC-specific, so there is no core class to reuse. Stepping back along the stair-house route could not leave #780's dead end either.
        3. F2 applies the same principle (the goal chosen by walk reachability) to players. Its candidates come from all edges near the destination, and the least total length wins, not the first reached.
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-route-ends-f2` at `ebc63265` (2 commits, base `next` `55804b11`).
    2. knk-workspace `claude/offroad-route-ends-f2` at `441dd7cc` (1 commit, base `next` `8487a058`).
3. **PRs.**
    1. [PandiO/knk-plugin#94](https://github.com/PandiO/knk-plugin/pull/94): `Closes #780`, `Part of #771`.
    2. [PandiO/knk-workspace#813](https://github.com/PandiO/knk-workspace/pull/813): `Part of`.
    3. Both have base `next`; neither is merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`, baseline on `next` `55804b11`:
        1. knk-core 3510 → 3514 (+4).
        2. knk-paper 3200 → 3210 (+10, 18 skipped, as before).
        3. knk-api-client 368 → 368.
        4. 0 failures; no known reds.
    2. New tests:
        1. knk-core `RoadGoalChoiceTest` (4).
        2. knk-paper `NavigationServiceRouteEndsTest` (9, on both dev-world snapshots with the real walk search and the shipped limits; test fixture `DevWorldSnapshot`).
        3. knk-paper `TrailRendererTest` +1.
    3. Unchanged and green: L7's golden transcripts, the L3/L4/L5/L9/L10 flag-off identity tests, F1's tests, the engine's handle tests and the NPC unit tests.
    4. CI on `ebc63265`: green. Build and paper-boot passed on both the push run and the PR run, every `npc-*` scenario included. No re-run was needed, and no `npc-*` outcome changed.
5. **Decisions (DESIGN § 4.3).**
    1. *When the choice is made.* Chosen: today's route first; the chosen goal replaces it when the searches answer, as walk links do (L5 decision 1). Alternatives:
        1. (a) Hold the session until the searches return: a second or more with no trail at every start.
        2. (b) Choose at the road's end: by then the road part has been driven to the wrong place.
    2. *Candidates.* Chosen: the nearest point per road edge within `max-snap-distance`, today's point first, at most 12. Alternatives:
        1. (a) Within `max-destination-distance` (256): many more far edges for no gain.
        2. (b) Polyline vertices too: more searches for points the per-edge nearest point usually matches.
        3. (c) One multi-goal walk search back from the destination: walk moves are not reversible (drops), as C1 found.
    3. *Cost to compare.* Chosen: route length plus walk length, in walked blocks, as L5's road-first rule does. Alternatives:
        1. (a) Routing cost plus walk cost: class factors and walk penalties make the totals hard to read.
        2. (b) A goal-cost offset inside the A* (`RouteRequest` addition): changes the shared router for one caller.
    4. *Search pacing.* Chosen: one candidate search at a time per navigation, so a walk leg always finds a walk thread. Alternative: (a) all at once on the pool: up to 12 searches ahead of a player's walk leg.
    5. *Re-routing to the new goal.* Chosen: `onNetworkChanged` (a silent route, taken as it is; its `NavigationRerouteEvent` carries reason NETWORK_CHANGED). Alternative: (a) a new `RouteReason`: every switch over the enum would need a case, for the same behaviour.
    6. *Item 5's network-swap cause.* Chosen: its own key, because it is a different cause from the road goal. Alternative: (a) fold it into `road-goal-reachable`: one switch for two unrelated changes.
    7. *Region destinations under `road-to-its-end`.* Chosen: the region's crossings when the region would switch to direct mode. Alternative: (a) leave regions out: the same mid-road switch happens for regions.
6. **Out of scope, noted.**
    1. The choice has no `/knk road status` line; it logs at FINE only.
    2. The snapshots' road graphs hold only the edges through their box. The live route from spawn differs (the snapshot routes the long way round), so the live numbers are for § 13.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-19 13:49 UTC), so the link finished without its review (developer decision 2026-11-14). This is said on both PRs.
8. **At merge / what the developer must do.**
    1. Merge the three keys into `config.yml` (all off = no change); YAML in the PR.
    2. Live test, about 25 minutes: smoke § 13 steps 1, 3, 4 and 5.
        1. Shipped settings, with `road-goal-reachable` and `road-to-its-end` set to true.
        2. `trail-leg-spacing` 1.5 or 2.0 for step 5.
        3. Never raise `max-snap-distance`.
    3. Decide whether to keep the two keys on and which spacing to use.
9. **Notes for later links.**
    1. The engine chain's removal of the raw entry (#747) is not affected: F2 uses `begin` and `onNetworkChanged` only.
    2. NPC long walks (#698's NPC phase) could reuse `RoadGoalChoice.candidates`/`best` for an NPC's road goal; that is the NPC chain's call.


### 4.13 F3 — smoke-test failures of 2026-11-19 (#780, #771, #710)

1. **Scope done.** The four failures of the developer's live runs of 2026-11-19 (smoke § 8, § 12, § 13), tier:2, no migration.
    1. **Road goal too early (#780, #771 items 4 and 5), behind `road-goal-reachable`.**
        1. Reproduced on `keep-tower.zip`: with F2's rule (least road + walk) the tower roof's goal is the garrison exit (edge 2000000003 at 1399 80 -532, 198 walked; live 202), and the watchtower's goal stays under the watchtower. The snapshot routes the long way through the Keep Upper Stairhouse and the Keep Garrison, as the live route did.
        2. New key `navigation.road-goal-walk-weight` (4.0, 1..100): the score is road + weight × walk (`RoadGoalChoice.best(options, walkWeight)`, `Option.score`).
        3. New candidates: `RoadGoalChoice.candidatesAlongRoad`. These are the per-edge points plus the network nodes reached from today's goal's edge ends, breadth first, without leaving `max-snap-distance`. Nearest first, today's first, at most `road-goal-candidates`. Node #74 is now a candidate.
        4. Result on the snapshot, tower roof: the road goes into the Keep Gate (1421 84 -521), 161 walked. That is the least walk of the 9 candidates (node #74: 168).
        5. Result on the snapshot, watchtower: the goal moves to 1417 81 -546, 86 walked instead of 124.
        6. One INFO line per choice lists every candidate with its road, walk and score, and marks the chosen one.
        7. `candidates` and `best(options)` are unchanged (for the NPC chain's G1, #814).
    2. **First turn said 4× (#780), behind either route-end key.**
        1. Cause: `routeAdopted` reset the announced maneuvers on every adoption, including the silent NETWORK_CHANGED ones (the goal choice, live-tag swaps).
        2. Fix: `Active.spokenManeuvers` survives silent replacements while a key is on. A maneuver with the same text within 2 blocks is not said again.
        3. With the keys off, a swap still repeats the turn, as today (pinned).
    3. **0 expansions from the watchtower roof (#771, § 12 step 3a): not reproduced.**
        1. On the merged snapshots (`keep-tower` blocks over `quarry-to-keep-stairhouse`'s), every roof floor cell reaches every road point within 60 blocks (pinned). This includes the cells with a snow layer.
        2. 0 expansions means the start or target cell check failed. A new INFO line names which, with both positions.
        3. Suspect for the repeat run: the sheared "Keep Stair House" gate door (ID 2) on the road the start leg aims at, 45 blocks away.
    4. **Open door not crossed (#710, § 8), unflagged (it only makes a valid route work).**
        1. Not `guidance-v2`: both flags cross the door on the snapshot from every point along the way, with the real leg boxes.
        2. Cause: `WalkAccessFactory` asked WorldGuard's door check for every door block, open ones too. The § 8 run's player (MrBedue) may not use the keep's doors. With the door denied, the snapshot gives the live picture (NO_PATH, partial trail to the door) with either flag.
        3. Fix: `WalkChunk.openDoorBlocks` and `WalkCapture.openDoorBlocks` (additions) record the open state. The player's door check is asked for closed doors only.
        4. NPC subjects keep their own door answer, unchanged.
    5. Kept stable (additions only): `WalkLegPreparer`, `WalkSearch`/`WalkPathfinder`, `MovementProfile`, `RoadGoalChoice`, the shape package, `RoadPlanner`'s port. No `core/npc`, `paper/npc`, destinations, production or siege file was touched.
2. **Commits and heads.**
    1. knk-plugin `claude/offroad-smoke-fixes-f3` at `64b4de3b` (3 commits, base `next` `4e296797`).
    2. knk-workspace `claude/offroad-smoke-fixes-f3` at `e7e6d306` (1 commit, base `next` `e50b423f`).
3. **PRs.** [PandiO/knk-plugin#100](https://github.com/PandiO/knk-plugin/pull/100) and [PandiO/knk-workspace#851](https://github.com/PandiO/knk-workspace/pull/851), base `next`, `Part of` #780, #771, #710. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`, baseline on `next` `4e296797`:
        1. knk-core 3541 → 3544 (+3).
        2. knk-paper 3229 → 3240 (+11, 18 skipped as before).
        3. knk-api-client 366 → 366.
        4. 0 failures; no known reds.
    2. New tests:
        1. knk-core `RoadGoalChoiceTest` +3.
        2. knk-paper `NavigationServiceRouteEndsTest` +9 (test fixture `DevWorldSnapshot.merged`).
        3. knk-paper `WalkAccessFactoryTest` +2 (`WalkCaptureTest.FakeWorld` gains open block states).
    3. Unchanged and green: L7's golden transcripts, the flag-off identity tests, F1/F2's tests, the engine's handle tests, the NPC tests. No golden changed.
5. **Decisions (DESIGN § 4.3).**
    1. *Walk over road.* Chosen: road + k × walk, k a key, default 4. Alternatives:
        1. (a) Least walk, near-ties broken by the longer road: on the snapshot it picks the dead-end node 34 for the watchtower, an overshoot like #771 item 4.
        2. (b) Least walk only: any long road detour would win.
    2. *k = 4.* Chosen because it is the smallest round weight that turns both live failures on the snapshot, with a margin. The tower roof is 1088 against 1107 for the next candidate. Alternatives:
        1. (a) 2: the garrison exit still loses only narrowly.
        2. (b) 10: a few blocks of walk would justify long road detours.
    3. *Onward candidates.* Chosen: network nodes reached from today's goal's edge ends without leaving `max-snap-distance`, merged with the per-edge points nearest first. Alternative: (a) only the next node past today's goal along the route: needs the route's direction, and misses the Keep Gate's split points.
    4. *Tower roof end point.* Chosen: assert the road into the Keep Gate (x ≥ 1413, z ≥ -523) with the least walk, rather than node #74 itself. From node #74 the walk is 7 blocks longer, and #771 item 4 had asked for no overshoot past the walk's start. Alternative: (a) force node #74: contradicts the "start walking as late as useful" rule by the numbers.
    5. *Repeated turn.* Chosen: remember the maneuvers said and skip the same text at the same node, behind the route-end keys. Alternative: (a) keep the counter across NETWORK_CHANGED: a replacement's maneuver list may shift indexes.
    6. *Open doors.* Chosen: the capture records the open state and only the player path skips the check. Alternatives:
        1. (a) Skip for every subject: changes NPC access, outside this link's area.
        2. (b) Behind `guidance-v2`: the cause is not the flag.
    7. *Failure 3.* Chosen: diagnostics plus a pinned negative result. Alternative: (a) change `WalkGrid`'s gate-footprint floor rule on suspicion: it is shared with the road builder and not proven.
6. **Out of scope, noted.**
    1. With the route-end keys off, a live-tag network swap still repeats the turn message (today's behaviour).
    2. The "Keep Stair House" gate door's sheared reference points (warned at every start) may remove a floor from the walk grid. To check with § 14 step 3's INFO line before filing.
7. **Blockers.** None. Codex reached its code-review usage limit on both PRs (its comments of 2026-11-20 09:37 UTC), so the link finished without its review (developer decision 2026-11-14); said on both PRs. CI on `64b4de3b`: build and paper-boot green on the push and PR runs, no re-run.
8. **At merge / what the developer must do.**
    1. Add `navigation.road-goal-walk-weight: 4.0` under `navigation:` (YAML in the plugin PR).
    2. Live test, about 25 minutes: smoke § 14 steps 1 to 5. Use shipped settings and `max-snap-distance` 48; route-end keys on for steps 1 to 3; player MrBedue with `guidance-v2` on, then off, for steps 4 and 5.
9. **Notes for later links.**
    1. `RoadGoalChoice.best(options)` stays F2's rule. G1 (#814) should use `best(options, walkWeight)` if NPCs ought to walk as little as players.
    2. Door access now depends on the door's open state at capture time. A door toggled within `chunk-ttl-seconds` (10 s) keeps its captured state, as before.
