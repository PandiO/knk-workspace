# NPC navigation follow-ups chain — progress report

**Status:** Running: fix links after the developer's retest (2026-11-15) · **Last updated:** 2026-11-15

**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358), links
[#519](https://github.com/PandiO/knk-workspace/issues/519) (L1),
[#520](https://github.com/PandiO/knk-workspace/issues/520) (L2),
[#521](https://github.com/PandiO/knk-workspace/issues/521) (L3),
[#522](https://github.com/PandiO/knk-workspace/issues/522) (L4), fix links #592 (L5), #593 (L6), #594 (L7).
**Charter:** [handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md).
**History:** [first NPC navigation chain report](2026-11-13-npc-navigation-chain.md) (Phases 1–4 and #490 merged into
`next`; developer tests done 2026-11-14).

## 1. Waiting for the developer

**Rerun needed first:** the 2026-11-15 retest probably ran an old jar (decision 17). Check the plugin's startup line `0.1.0+<sha>` names `028504d` or later, then rerun #521 steps 3–5, #520 step 10 and the #490 audit.

**Retest 2026-11-15 (manager's relay, comments on #520, #521, #490):** L3 fails at the #491 stair corner and the #492 landing; L2 step 10 fails (#506, overlapping gate region); the #490 audit still shows DROWNING 809. Fix links L5–L7 run one at a time. #522 (L4) is not tested yet. The steps below stay valid for what isn't being fixed.

Every link is merged into `next` (2026-11-15). Build knk-plugin from `next` `deb7ff49` or later, merge the new
`config.yml` keys (YAML in the changelog and the configuration reference § 4.27; `stationary-ticks` and
`no-progress-ticks` 40, `group-spacing` 1.5), restart. In test order:

1. **L2 (#520):** Phase 4 steps 9 and 10 (gate closing mid-group, access change mid-group).
2. **L3 (#521):** the corner and recovery steps on `quarry-to-keep` (the stair corner 1411 73 -537, the 1433 44 -517
   landing) and the short south-gate route.
3. **L4 (#522):** narrowed formations, the followers-finish-trip toggle, and the #490 audit re-run
   (`/knk npc test spawn 50 24`, no `DROWNING` in `causes:`).
4. **Review of the agent decisions:** blocks 4.2 § 5, 4.3 § 5 (13), 4.4 § 5 (8). Behaviour-changing: 4.2 decisions 1–3
   (followers stop short of a door; cache re-warm; the follower guard counts but does not stop); 4.3 decisions 1, 5, 6,
   8; 4.4 decisions 2 (stairs as a column), 5 (toggle off: a held follower waits on the leader's new route), 6 (a
   follower in the margin before a moving door steps back, changing L2's rule).
5. **Promotion of `next`** once the tests pass; then the issues #519–#522, #506, #507, #508, #491, #492, #493 close.
6. Docs: #589, in its own docs session (session_01R1w2UvjZEQ5uyXDYDCqAfs).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Design: corners, narrowed formations, toggle | #519 | Merged into next (2026-11-15, design approved by the developer) | knk-workspace `96f47820` → `next` `4a97fd3b` | PandiO/knk-workspace#546 | docs only (no CI); Codex at its usage limit | create_session session_01R1w2UwysEMwCYnxwCpkx3p (2026-11-15) |
| L2 Follower recheck and guard, no gate push | #520 | Merged into next (2026-11-15, by the manager session) | knk-plugin `651d8bff` → `next` `11e07d64`; knk-workspace → `next` `43a2328c` | PandiO/knk-plugin#31, PandiO/knk-workspace#536 | PR head green (build, paper-boot); `next` runs 43662028862, 43662028855 pending at the coordinator check | create_session session_01R1w2Ux2KpS7H3FidwDEZmp (2026-11-14) |
| L3 Wall-corner steering and recovery | #521 | Merged into next (2026-11-15) | knk-plugin `51072e94` → `next` `5dc88cfd`; knk-workspace `4308aaf1` → `next` `51bf5952` | PandiO/knk-plugin#36, PandiO/knk-workspace#557 | PR head green (build, paper-boot with Citizens, 19 scenarios); Codex at its usage limit | create_session session_01R1w2Uv1rEnwPko4Tq83xyL (2026-11-15) |
| L4 Narrowed formations, followers-finish-trip toggle | #522 | Merged into next (2026-11-15) | knk-plugin `f965af06` → `next` `deb7ff49`; knk-workspace `bce76405` → `next` `ee9894ef` | PandiO/knk-plugin#39, PandiO/knk-workspace#584 | `build` green on `f965af06`; `paper-boot` green on one run, the other failed only the log check (#586, re-run); 31 scenarios; Codex at its usage limit | create_session session_01R1w2Uur6M3a3CaVDWJWCw7 (2026-11-15) |
| L5 Fix: stair corner, ranks row at the landing | #592 | In review (PRs open, not merged) | knk-plugin `011b1745`; knk-workspace `4a819546` | PandiO/knk-plugin#43, PandiO/knk-workspace#599 | local: build green, 34/34 scenarios (log check: #586's intermittent WARN); PR CI pending | create_session session_01R1w2UxAFomY5DQ18vRtAH6 (2026-11-15) |
| L6 Fix: follower access with overlapping gate region | #593 | On hold (developer's rerun on the current jar; then gate: L5 merged) | — | — | — | — |
| L7 Fix: test walkers drown (#490) | #594 | On hold (developer's rerun on the current jar; then gate: L6 merged) | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set in force.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator
   merges a passed link into `next`), because the first NPC chain confirmed CI on the API and web-app trunks on
   2026-11-13 and the developer's starting prompt states it. Alternatives: (a) re-run the skill § 1.3 check by attaching
   knk-web-api and knk-web-app (not done: this chain touches neither, and nothing has removed that CI since); (b) the
   old rules (developer merges), which no longer apply.
2. **Testing rule version.** Chosen: global instructions "Testing: automated first" and the knk-test-writer skill as on
   `main` at `8576b1be` (landed 2026-11-14 before the first link started), named in every link prompt. Alternatives:
   (a) the interim rule from the manager's correction (unit tests plus e2e per page), superseded once the rule landed.
3. **One link sub-issue per link** (#519–#522 under #358) that names the scope issues it closes. Chosen because L2 and
   L4 each split #507, and L3 closes three issues. Alternatives: (a) scope links by the bug issues directly (no
   one-to-one link issue for L1, L2 and L4); (b) a new parent issue for the follow-ups (the developer named #358).
4. **Branches.** Chosen: one branch per link, `claude/npc-followups-l<n>` from `next`. Alternatives: (a) the first
   chain's standing branch `claude/npc-navigation` (L1 and L2 run together, so they would share a workspace branch);
   (b) one branch per repo for the whole chain (same problem).
5. **Old coordinator's tracker row** (handed over by the manager 2026-11-14; the old coordinator session is being
   archived). Chosen: one row for both chains: this chain's row replaces the old one and keeps the first chain's
   remaining state (Phases 1–4 in `next`, tests done, promotion waits only on #486), so the overlap check sees one NPC
   coordinator. Alternatives: (a) move the old row to the November archive now (the developer has not accepted the
   first chain yet; skill § 9.4 archives only after that); (b) keep both rows with a pointer (two NPC coordinator rows
   for the overlap check).
6. **Overlap with the #486 fix session** (knk-plugin `claude/erasure-first-join-486-retest`, three commits on `next`,
   no PR at start): it changes `NpcMoverFactory`, `CitizensNpcMover`, `CitizensNpcRuntime`, `DryBlockExaminer`,
   `NpcTestWalkers`, `KnKPlugin`. Chosen: L2 starts now and keeps out of those lines (additive edits elsewhere in a
   shared file are allowed, skill § 2.4), because #506 and the gate push live in the group service, the navigation
   service's rule events and the gate code. Alternatives: (a) wait for that branch to merge (delays L2 for no line
   overlap); (b) stack L2 on that branch (DESIGN § 5.4 reserves stacking for uncertain work).
7. **Asking the L1 questions before L1 starts.** Chosen: ask the developer the known open points of #493, #507 and
   #508 now and give L1 the answers, so its design is drafted to them; questions L1 finds later go through the
   coordinator. Alternatives: (a) let L1 draft first and ask afterwards (a second round for points already known).

8. **L1 started without the developer's answers** (2026-11-15). The questions of decision 7 could not be asked: the
   session's worker restarted while they were open, and the developer is away overnight. Chosen: start L1 with the
   coordinator's proposed defaults written into the design as "proposed, awaiting the developer" (side gap 1.0, row gap
   1.5, narrowed `escort-ring` with the leader mid second row, `group-followers-finish-trip: false`), and put the
   questions to the developer with the design approval, which gates L3 and L4 anyway. Supersedes decision 7.
   Alternatives: (a) wait for the developer before starting L1 (loses the night); (b) let L1 decide the defaults itself
   without marking them (the developer asked to settle them).
9. **L2 merged by the manager session** (manager's message 2026-11-15 01:08 UTC: it updated PandiO/knk-plugin#31 with
   `next` and merges it, then PandiO/knk-workspace#536, after CI). Chosen: leave the merge to the manager and run the
   § 6/§ 7 checks afterwards. Alternatives: (a) merge myself (two sessions merging the same PR).

10. **L2 check after the manager's merge** (2026-11-15). § 6 held: both branches are in `next` (rev-list counts 0),
    tests above the baseline (core 2700, paper 2689, 0 failures), CI green on the combined PR head, scope matches #520,
    decisions logged in block 4.2, behind `npc.navigation.enabled`. Codex did not review (usage limit, comment on
    knk-plugin#31), so the merge went ahead without it (developer decision 2026-11-14). CI on `next` was still running
    at the check and is checked at the next check-in. Recorded as merged by the manager session.
11. **Scenario framework on `next`** (#421 and the #511 scenarios, knk-plugin#35, 2026-11-15). L3 and L4 write their
    world steps (corner scene, gate and access group tests) as plugin scenarios, not "scenario later". Told L1 so its
    test sections plan for them.

12. **L1 checked, merge held for the developer's approval** (2026-11-15). § 6 held: PR #546 into `next` contains
    `next` (`43a2328`), docs only (changelog, BEHAVIOR_MODEL § 2 NAV-19–NAV-23, plan Phase 4b), 12 questions with
    proposed defaults and alternatives, Codex skipped for its usage limit. Chosen: hold the merge until the developer
    approves, because the charter's L3 gate is "L1 approved and merged" and L1 was told the coordinator merges after
    approval. Alternatives: (a) merge now as "proposed" (skill § 7.1 merges every tier at once; but the design would
    then sit in `next` with twelve unconfirmed defaults, and a change to them is a second PR). CI on knk-plugin `next`
    after L2: `build` and `paper-boot` green (runs 43662028862, 43662028855).

13. **L1 approved and merged** (2026-11-15). The developer approved the design with all twelve proposed defaults
    (coordinator session; recorded on #519). L1 marked them decided (`96f47820`), and the coordinator merged
    PandiO/knk-workspace#546 into `next` (`4a97fd3b`, merge commit). L3's gate is open: L1 and L2 are in `next`
    (rev-list counts 0) and no knk-plugin PR is open. L3 started with create_session.

14. **L3 checked and merged** (2026-11-15). § 6 held: plugin branch contains `next`, tests 5839 → 5878 (0 failed),
    CI `build` and `paper-boot` green on the PR head with 19 scenarios including the three NPC ones and the pinned
    Citizens build (6.11 automated proof), scope matches #521, thirteen decisions logged, behind the flag, Codex skipped
    for its usage limit. The docs branch was 35 commits behind `next` with a changelog conflict (both sides added
    entries at the top): mechanical, so the coordinator merged `origin/next` into it keeping both (`4308aaf1`, skill
    § 7.3). Merged PandiO/knk-plugin#36 → `5dc88cfd` and PandiO/knk-workspace#557 → `51bf5952`. L4's gate opened;
    L4 started.

15. **L4 checked and merged; chain done** (2026-11-15). L4 was sent back once to merge `next` (knk-plugin#38 / #540
    conflicted in `paper-boot.yml` and the scenario count test). After that the plugin branch contained `next`, CI
    `build` and `paper-boot` green on `f965af06`, no Codex findings (usage limit), tests 2756 → 2777 core and 2782 →
    2789 paper, the three L4 scenarios in the run. `next` in knk-workspace moved again during the check (changelog
    conflict, both sides added entries): mechanical, the coordinator merged `origin/next` into the docs branch
    (`bce76405`). Merged PandiO/knk-plugin#39 → `deb7ff49` and PandiO/knk-workspace#584 → `ee9894ef`, at the
    manager's request so #522 could join the developer's test round. Documentation sub-issue #589 opened and its docs
    session started (session_01R1w2UvjZEQ5uyXDYDCqAfs).

16. **Fix links after the developer's retest** (2026-11-15, relayed by the manager). Chosen: three fix links,
    L5 (#592: #491 corner, #492 ranks row), L6 (#593: #506 step 10 with overlapping district/gate regions), L7 (#594:
    #490 drowning walkers), one knk-plugin link at a time, in that order, because the stair corner is the release gate
    and the most users' problem. Each link reproduces the real geometry or setup in a scenario first, since L2's and
    L3's green suites missed these failures. Alternatives: (a) rerun L3 and L2 as subagents with what failed (skill
    § 8.2; the failures are new findings with the real geometry rather than a failed check, so new links with their own
    issues track them better); (b) one link for all three (three unrelated areas, a long serial link); (c) L6 first
    (smaller, but the corner blocks the stair release gate). The manager fixes the CRLF config test (knk-plugin#41)
    itself.

17. **Retest may have run an old jar** (manager, 2026-11-15 ~13:25). The developer's 13:33 log still shows a line
    that knk-plugin#29 removed: `./gradlew :knk-paper:dev` failed on the Windows CRLF test (fixed in knk-plugin#41), so
    the old jar stayed deployed. Chosen: L5 continues only with the scenarios built from the real geometry against
    `next`. It fixes what fails there; if they pass, it pushes them as coverage, reports "not reproduced" and stops.
    L6 and L7 are on hold until the developer confirms the version line and reruns on `028504d` or later.
    Alternatives: (a) interrupt L5 entirely (loses the scenario work, which is valid on any jar); (b) carry on as
    scoped (risks fixing code that isn't broken).

18. **Old jar confirmed** (manager, 2026-11-15 13:52). The developer's server ran `0.1.0+a760c4a4`, which is
    knk-plugin `next` from before #29, L2 (#31), L3 (#36) and L4 (#39). None of the 2026-11-15 NPC retest results is
    evidence against L2–L4. Corrections are posted on #520, #521 and #490. Decision 17 stands until the developer's rerun
    on `028504d` or later.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Design: wall corners, recovery, narrowed formations, finish-trip toggle (#519)

1. **Scope done.**
    1. `docs/specs/npc-platform/BEHAVIOR_MODEL.md` § 2: NAV-19 (corner clearance, turns through the corner point, shortcuts only over standable cells, low headroom), NAV-20 (the recovery ladder back-off → side-step → local leg ahead on the NPC's own floor → replan, spaced and capped, for followers too), NAV-21 (stuck accounting that adds up), NAV-22 (formations narrow 3 → 2 → 1 before they fold), NAV-23 (followers may finish their trip).
    2. `docs/specs/npc-platform/IMPLEMENTATION_PLAN.md`: Phase 4b and its row in the phase table. 4b.1 says what the code does today. 4b.2 is L3 (#521) and 4b.3 is L4 (#522); each has config keys (default, layer, § 4.27 entry), tests per suite, developer test steps on `quarry-to-keep` and `south-gate-short`, and a "done when". 4b.4 holds the proposed defaults. L2's Phase 4 passages are untouched.
    3. Code findings (knk-plugin `next` `b2c5dff0`, rechecked at `11e07d6` with L2 merged):
        1. #491: Citizens' movement margin (`distanceMargin`) is its default of 1 block and K&K never sets it, so NPCs leave a corner a block early.
        2. #492: three places pick the recovery target on another floor: `planRoad`'s short trip uses horizontal distance, `NavGroup.rejoin` uses horizontal distance (14) and 6 blocks up or down, and `RouteFollower.recoveryTarget` uses the horizontally nearest point with `snapToFloor`.
        3. "Retry 4 of 3": the log prints before the cap check, so the cap really holds at 3. There is no wait between tries, and a failed A* comes back as `CancelReason.STUCK`.
        4. `stuck_engine` counts failed searches too; `recovered` counts only line recovery legs that arrived.
        5. `most plans at once` is the server-wide queued + running count over all plans.
        6. `group_rejoin 481` comes from endless 5-second retries.
        7. #507: a new order resets the group's path.
    4. `docs/CHANGELOG.md`: one line.
2. **Commits and heads.** knk-workspace `claude/npc-followups-l1` at `b2d586a`: 4 commits (the last plans the L3 and L4 world steps as plugin scenarios, after the coordinator's note) plus a merge of `origin/next` at `43a2328` (L2's docs; the changelog conflict was mechanical, both kept). Base `next` at `7f08836`.
3. **PRs.** PandiO/knk-workspace#546 (`Closes #519`, `Part of #508, #493, #507`), base `next`. Not merged; it waits for the developer's approval.
4. **Tests, baseline → result.**
    1. knk-workspace: docs only. The links I added resolve (BEHAVIOR_MODEL anchor, charter, configuration reference § 4.27).
    2. Known reds: none. Codex: at its usage limit, no review (said on the PR).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the follow-up goes.* Chosen: a new Phase 4b after Phase 4, split 4b.2 (L3) and 4b.3 (L4), because L2 edits Phase 4's known limits and steps and coordinator note 1 asks for new sections. Alternatives: (a) follow-up sections inside Phase 2 and Phase 4 (touches lines next to L2's); (b) a separate design file (the charter binds the plan).
    2. *Requirement IDs.* Chosen: NAV-19–NAV-23 in the BEHAVIOR_MODEL table, evidence from the 2026-11-14 tests. Alternatives: (a) amend NAV-07, NAV-15 and NAV-17 (mixes the spike's evidence with the new).
    3. *Recovery cap.* Chosen: the existing `max-retries` (3) counts ladder steps 1–3, and the replan follows. A step that can't be taken is skipped and not counted. Alternatives: (a) a new key per step; (b) a separate cap for the whole ladder.
    4. *A failed engine search.* Chosen: it ends the current try (`recovery_no_path`, a new `StuckKind.NO_PATH` from the mover) and is not a new stuck spell. Alternatives: (a) keep counting it as `stuck_engine` (the 14456).
    5. *The "own floor" rule.* Chosen: one helper (`PathTargets`) that searches forward along the path, chains floors with `snapNear` from the NPC's floor, and is used for recovery legs, followers' own legs and the short-trip test (which also needs a height difference ≤ 2). Alternatives: (a) fix the three call sites separately; (b) an A* reachability check per candidate (cost).
    6. *Corner turns.* Chosen: Citizens' movement margin per stretch (`waypoint-margin`) plus corner clearance at turns. Alternatives: (a) denser waypoints at turns with the 1-block margin (still cuts about a third of a block); (b) a K&K step controller (Phase 7).
    7. *Stats for plans.* Chosen: `road plans per group event` and `local legs at once` replace `most plans at once`. Alternatives: (a) keep the one number and explain it.
    8. *Width hysteresis.* Chosen: a column at once, narrower widths ≥ 2 and wider widths only when they last `group-width-hysteresis-blocks`. Short bumps are passed by lanes stepping onto the next lane. Alternatives: (a) a time-based hold; (b) no hysteresis.
    9. *Finish-trip mechanics.* Chosen: a `FINISHING` follower keeps the old path to its slot at the goal, walks it under the same rules, reports `onMemberArrived`, then follows; the leader doesn't wait for it. Alternatives: (a) the leader waits for finishers (slows couriers' escorts); (b) followers walk to the goal point itself instead of their slot (crowding).
    10. *Corner test scene.* Chosen: one generated scene (`NpcCornerScene`) shared by the scenarios and a dev command at `testing.scenarios.origin`, with L4's narrow passages in it. Alternatives: (a) a copy of the dev world's stair house (not reproducible in CI).
6. **Out of scope, noted.** None filed. The Citizens-in-CI question (4b.4 question 9) is for the developer.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Approve the design (on #519 or with the coordinator), and answer the questions below. The answers go into plan 4b.4 before L3 and L4 start.
    2. No `config.yml` key, no migration in this link.
    3. Questions (proposed defaults with alternatives):
        1. `group-lateral-spacing` 1.0. Alternatives: (a) 1.25; (b) 1.5.
        2. `group-spacing` from 2.0 to 1.5. Alternatives: (a) 1.0; (b) keep 2.0.
        3. Narrowed `escort-ring`: rows of 3 with the leader in the middle of the second row, then 2 abreast, then a column. Alternatives: (a) the leader in the front row; (b) fold straight to a column.
        4. `npc.navigation.group-followers-finish-trip: false`, per group (layers and group command). Alternatives: (a) the name `group-finish-trip`; (b) default `true`.
        5. `corner-clearance` 1.0. Alternatives: (a) 0.5; (b) 1.5; (c) 0 (off).
        6. `waypoint-margin` 0.5. Alternatives: (a) 0.35; (b) 0.75; (c) keep 1.0 and densify waypoints at turns.
        7. `recovery-wait-ticks` 20. Alternatives: (a) 10; (b) 40. The toggle applies after the leader arrived only. Alternative: (c) also on a replaced order.
        8. `stationary-ticks` and `no-progress-ticks` 60 → 40. Alternatives: (a) 30; (b) keep 60.
        9. A pinned Citizens build in CI's `paper-boot` server. Alternatives: (a) only the K&K half as a scenario; (b) a separate optional CI job.
        10. `group-width-hysteresis-blocks` 3. Alternatives: (a) 0; (b) 5.
        11. A left-behind follower's tries double from 5 s to 60 s. Alternatives: (a) every 5 s; (b) a fixed 30 s.
        12. The escort ring's radius is 1.25 × the lateral spacing. Alternative: (a) 1.25 × `group-spacing`.
9. **Notes for later links.**
    1. L3: the corner cut is Citizens' `distanceMargin`, so set it on the navigator's local parameters after `setTarget`. Confirm the 4b.1 item 4 reading of `stuck_engine` with the split counters before changing behaviour.
    2. L3 and L4: the world steps are plugin scenarios (plan 4b.2 item 18, 4b.3 item 14: `npc-corners-line`, `npc-corners-walk`, `npc-stuck-ladder`, `npc-group-narrows`, `npc-group-gate-finish-trip`, `npc-group-access-change`). CI's `paper-boot` server has no Citizens, so L3 adds a pinned build first; with question 9 answered (a), the walking scenarios run on the dev server with `/knk scenario run`.
    3. L4: `GroupPath.wide` caches one half width per point; store the widest fitting width per point to keep the tick cost.

### 4.2 L2 — Follower recheck and trespass guard, no gate push on followers (#520)

1. **Scope done.**
    1. **#506 root cause.** The group code already rechecked follower lanes on an event (its knk-core test passed). On the server, `/knk cache refresh` clears the region → domain map (the "region domains" hook) before the "navigation routes" availability event. The NPC checks use `getDomainByRegionIdNoRefresh` and treat an unknown domain as open, so every district looked open until the road tags' next pass (up to a minute), and the whole column walked in. Followers had no trespass guard, so `trespasses 0` hid it.
    2. **knk-plugin `paper/navigation`.** New `DomainCacheRewarm` refresh hook, registered in `KnKPlugin` after "navigation routes" and active only while NPC navigation runs (`NpcNavigationModule.navigating()`). It warms the map for every world's road regions, then sends the availability event once more on the main thread.
    3. **knk-plugin `core/npc/nav/group/NavGroup`.** An event makes the group look in the next tick and re-hand every follower's waypoints. Followers get a trespass guard (`Event.TRESPASS`, log `TRESPASS … (a follower of group n)`); an event takes a fresh look first. The doors of the leader's routes are kept (`NpcNavigationService.gateDoorsOf`). A follower stops 1 block short of the box of a door that blocks it now (new port `AccessRules.doorBox`, Paper answers with `GateDoorBounds` through `NavigationAccess` and `NavigationService.PolicyFactory`). One already in the box walks on out, uninterrupted.
    4. **#507 gate event.** `GateManager.closeGate` fires the state event at the **start** of an animated close, and `notifyAnimationCompleted` fires again at the end. The push came from followers, who had no gate check: they walked their waypoints into the moving door and `GateAnimationTask` evacuated them.
    5. **#490 `EntityDamageByEntityEvent 33`:** not explained by the gate push. The animation teleports or sets a velocity and never damages. Door suffocation would be a plain `EntityDamageEvent` (SUFFOCATION), cancelled by `GateSuffocationGuard`. A by-entity event needs a damager (a mob, a player, a projectile).
    6. **knk-workspace.** `docs/CHANGELOG.md` entry; `IMPLEMENTATION_PLAN.md` Phase 4 known limits 1 and 4 and developer test steps 9 and 10 (routes `quarry-to-keep` and a saved short route through the south gate). No new key, so configuration reference § 4.27 is unchanged. Developer test steps are posted on #520.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l2` at `2be0bf13`: 3 commits on base `next` at `a760c4a4`.
    2. knk-workspace `claude/npc-followups-l2` at `46e8f67`: 1 docs commit plus a merge of `origin/next` at `a89d9cb`. The changelog conflict was mechanical, and both sides were kept. The merge commit has git's default message, without the session trailers.
3. **PRs.** PandiO/knk-plugin#31 (`Closes #520`, `Closes #506`, `Part of #507`) and PandiO/knk-workspace#536 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` core 2695, api-client 338 (2 skipped), paper 2683 (18 skipped). Result core 2700 (+5), api-client 338 (2 skipped), paper 2689 (+6, 18 skipped). 0 failures. CI push runs `build` 43648929001 and `paper-boot` 43648928936 green.
    2. New tests:
        1. knk-core `NavGroupTest`: access change mid-column of 20 (#506 acceptance, trespasses 0); trespass guard counts a follower carried in; gate closing mid-group pushes nobody and the rest follows on opening; a door without a box holds nobody; the leader's route doors.
        2. knk-paper: `NavigationAccessSubjectTest` (door box; a door that started closing blocks an NPC); `NpcRoadPlanningTest` (doorBox delegation); `DomainCacheRewarmTest` (4 cases).
        3. World steps are "scenario later": #421's framework is not on `next`.
    3. Known reds: none.
    4. Codex: at its usage limit on both PRs, so no review (said on both PRs).
5. **Decisions (DESIGN § 4.3).**
    1. *Gate push.* Chosen: followers stop a block short of a blocking door's box and leave the box if they are in it, all in the NPC layer, because the gate keeps its timing for players and sieges. Alternatives: (a) the gate waits or jams while an NPC is in its sweep (changes gate behaviour for everybody); (b) skip NPCs in `handleEntityPush` and let `GateSuffocationGuard` move them (still a push, plus suffocation ticks); (c) stop at a fixed distance before the route's gate crossing point (that point is the end of the gate's road stretch, not the door, so it could stop NPCs inside the doorway).
    2. *Door geometry.* Chosen: a new `AccessRules.doorBox` port (default empty) answered by `GateDoorBounds`, because core needs no Bukkit type and unknown doors keep the old behaviour. Alternatives: (a) a `NavWorld` method (the world port knows no gates); (b) door positions in `RoadPlanner.GateCrossing` (changes the planner record and every caller).
    3. *Stale cache after a refresh.* Chosen: re-warm the roads' regions and send a second availability event, only while NPC navigation runs. Alternatives: (a) NPC checks ask the API for unknown regions (request storms for regions without a domain, an event loop); (b) refresh the map in place instead of clearing it (changes KNG-104 semantics for everybody); (c) leave it to the road tags' pass (the bug).
    4. *Follower trespass guard.* Chosen: log and count, no stop (`stop-on-trespass` stays for NPCs with their own order); an event takes a fresh look first. Alternatives: (a) stop and re-send the follower (it is inside by then, and re-sending walks it on anyway); (b) no fresh look (counts entries made under the old rules, seen in the first test run).
    5. *Leader and followers held by a door.* Chosen: like followers held by a region, the leader does not wait for them, so the group splits and they follow on opening. Step 9 of the plan now expects `leader waited 0` instead of a 30 s wait. Alternatives: (a) the old wait of up to 30 s for a door that may stay closed.
    6. *Event latency.* Chosen: an event makes the group's next tick run at once instead of at its 5-tick turn. Alternatives: (a) keep the turn (followers walk up to a block before the re-send, seen in the first test run).
    7. *Plan edits.* Chosen: only Phase 4 known limits 1 and 4 and steps 9 and 10, not the "Last updated" header or item 8, so the L1 merge stays mechanical (coordinator note 3). Alternatives: (a) update item 8 and the header too.
6. **Out of scope, noted.** #533 (a realtime domain change clears the map without re-warm or event), #534 (a single NPC or leader in a door's box when it starts closing stops there and is evacuated).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. No `config.yml` key, no migration. Deploy the plugin.
    2. Run the developer test steps on #520 (plan Phase 4 steps 9 and 10) and post the stats and the log there.
9. **Notes for later links.**
    1. L3 and L4: `NavGroup` now has `routeDoors`, `doorBoxes`, `doorVerdicts`, `rulesPending`, `Follower.regions`, `guardTick` and `leavingDoor`. A follower with `leavingDoor` is not stopped until its waypoints end, and `rulesChanged()` reads each follower's regions.
    2. L4 toggle: followers held by a door or region are not counted in `maxLag` or `settled`, so the group's order arrives without them. A "finish the trip" toggle must decide what a held follower does after the order ends.
    3. KnKPlugin: one additive block after the "navigation routes" hook (line about 1924), away from the #486 branch's hunk.

### 4.3 L3 — Wall-corner steering and stuck recovery (#521: #508, #491, #492)

1. **Scope done** (implementation plan 4b.2 items 1–19, behind `npc.navigation.enabled`, decided defaults of 4b.4).
    1. **Steering (knk-core).**
        1. `CornerClearance` and `RouteFollower.next(…, clearance)`: at turns, waypoints keep `corner-clearance` 1.0 from walls on the inside.
        2. `NavGeometry.straightWalkable`: the shortcut check.
        3. `NavGeometry.jumpFits`: the low-headroom rule.
        4. `NpcMover.follow(waypoints, margin)` with `waypoint-margin` 0.5 (Paper: set on Citizens' local parameters right after `setTarget`).
    2. **Own-floor targets.** `PathTargets` is used for the recovery leg, a follower's own leg back (never past its slot, never again at a target that failed from the same spot) and the short trip (it now also needs a height difference of at most 2). `HopPlanner.hops` chains floors with `snapNear`, and `HopPlanner.floorNear` is the strict chain.
    3. **The ladder.** `RecoveryLadder` (pure, fake clock), `RecoveryMoves` (blocking face, near a wall, side-step) and `RecentSteps` (footsteps, falls). The order is back-off → side-step → local leg → replan, with `recovery-wait-ticks` between tries and the cap counted the same way in the log. A `NO_PATH` report ends a try without opening a new spell, and a stuck within 2 blocks and 30 s continues the ladder.
    4. **Followers.** The same ladder runs in `NavGroup`. The side-step goes away from the path's centre, a left-behind follower waits beside its lane, and its tries double up to 60 s. Citizens' stuck reports for followers reach the group through `NpcNavigationService.setIdleStuckListener`.
    5. **Accounting.**
        1. Stuck is counted per spell. New events: `freed_back_off`, `freed_side_step`, `freed_local_leg`, `freed_replan`, `not_freed`, `recovery_no_path`, `fell`.
        2. `recovered` is now the sum of the `freed_*` events, and the gauge `knk_npc_nav_stuck_spells_open` counts open spells.
        3. `NpcNavigationMetrics.SpellStats` makes the new stats line. The group line shows `road plans per group event` and `local legs at once`.
    6. **Ports** (engine-neutral): `NavWorld.freeHeight`/`blocksBody` (Paper: `BukkitNavWorld`), `NpcMover.follow(…, margin)`, `NpcMover.fallDistance()`, `MoverListener.stuck(mover, StuckKind)` (Paper: from the strategy's path in Citizens' cancel event).
    7. **Config.** `corner-clearance`, `waypoint-margin` and `recovery-wait-ticks` are new; `stationary-ticks` and `no-progress-ticks` default to 40; `max-retries` is reworded. All are in `config.yml` with comments, with a layer test.
    8. **Scenarios.**
        1. `NpcCornerScene` and the scenarios `npc-corners-line`, `npc-corners-walk` and `npc-stuck-ladder`, run through `ScenarioNpcs`: its own navigation service on a Citizens registry of its own, with the scene's loop line as a fake road.
        2. `paper-boot.yml`: pinned Citizens 2.0.44 build 4269 (URL plus SHA-256 `e6b0a0e3…`), `MIN_SCENARIOS` 19, `--expect-timeout` 360, job timeout 15 min.
        3. `/knk npc nav scene corners` builds the scene on a test server.
    9. **knk-workspace docs.**
        1. `docs/CHANGELOG.md`: the entry with the #491 metrics explanation and the admin YAML.
        2. Configuration reference § 4.27 and § 2.1.
        3. Plan 4b.2: status, differences, developer test steps limited to what no scenario checks.
    10. **The metrics of #491.** `stuck_engine 14456` counted every Citizens STUCK cancel while an NPC moved: its stationary check and every failed path search of a retry (four per burst, a burst every 5 s). `recovered 0` counted only recovery legs that arrived, and none did, because each aimed at another floor. The NPCs got free on the 5-second replan (the "second try"). The same numbers now read as spells and the steps that freed them.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l3` at `51072e94`: 3 commits on base `next` `11e07d64`.
    2. knk-workspace `claude/npc-followups-l3` at `81569658`: 1 docs commit plus a merge of `origin/next` (`66c7c910`, town streets). The changelog merged automatically; the merge commit has git's default message.
3. **PRs.** PandiO/knk-plugin#36 (`Closes` #521, #508, #491, #492) and PandiO/knk-workspace#557 (`Part of` them), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` 5839 tests, 0 failed, 20 skipped. Result 5878, 0 failed, 20 skipped.
    2. Three old service tests asserted the old retry loop and were rewritten for the ladder. `NpcNavRunnerTest` and `PaperScenariosTest` were updated for the new stats line and the 19 scenarios.
    3. New tests:
        1. knk-core: `CornerClearanceTest`, `PathTargetsTest`, `RecoveryLadderTest` and `RecentStepsTest`; ladder, counter-invariant and continuation tests in `NpcNavigationServiceTest`; follower-ladder, left-behind spacing and own-leg-ahead tests in `NavGroupTest`; the stats line in `NpcNavigationMetricsTest`.
        2. knk-paper: `BukkitNavWorldBlocksTest` (Mockito blocks, because MockBukkit's `BlockMock.isPassable()` is not implemented and a `WorldMock` test is skipped); margin and stuck-kind tests in `CitizensNpcMoverPathTest`; the new keys in every layer in `NpcNavigationConfigTest`.
    4. **Plugin scenarios on a real server, run locally.** Paper 26.3 build 205 with WorldEdit, WorldGuard and Citizens build 4269, through `tools/paper-boot/boot-test.sh --scenarios`: 19/19 passed. `npc-corners-walk`: 0 stuck spells, 56 arrivals, longest still 0.45 s, 0 falls. `npc-stuck-ladder`: 324 ticks.
    5. CI on PandiO/knk-plugin#36 at `51072e94`: `build` and `paper-boot` passed (the pinned Citizens build was fetched and checked; 19 scenarios).
    6. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Inside of a turn.* Chosen: the direction from the incoming to the outgoing heading. A waypoint moves to the whole block within the clearance that keeps the most distance from walls on that side, only when straight walks to its neighbours stay standable. Alternatives: (a) offset along the bisector by a fixed amount (ignores where the walls are); (b) move every waypoint near any wall (would move the straight along the wall, which the design forbids).
    2. *What stops a body* (`blocksBody`). Chosen: not passable, except a bottom slab or an upright stair (steps). Alternatives: (a) Bukkit collision shapes (not available in MockBukkit, harder to test); (b) only full solid blocks (fences would not count).
    3. *Continuation spot.* Chosen: within 2 blocks of where the last spell **started**. Alternatives: (a) where it ended (a freed NPC is already past the spot, so the next stuck there would start over).
    4. *A follower's own leg with nothing ahead.* Chosen: start over with the excluded targets; if there is still only the point it stands on, count a failed try without an order. Alternatives: (a) an order to its own place (it "arrived" at once and reset the left-behind spacing: found by the 20-minute `NavGroupTest`).
    5. *Lane continuity.* Chosen: a lane waypoint more than a block above or below the waypoint before it (or the follower's feet) becomes the path's centre. Alternatives: (a) leave the lanes to L4 (the `npc-corners-walk` scenario fails with a fall); (b) tighten `GroupPath.wide` (L4's fit rule, 4b.3 item 4).
    6. *Falls.* Chosen: a drop of 3 or more counts only when the engine's fall distance reached 1.5 at one look (new port `NpcMover.fallDistance()`, NaN for engines that cannot tell). Alternatives: (a) only the drop between two looks (counted a flight walked between two looks as a fall: seen on the server); (b) look every tick (more main-thread work for every NPC).
    7. *Back-off after a push.* Chosen: footsteps break at a jump of more than 2.5 blocks, and the first back step must be a straight walk. Alternatives: (a) any footstep (it walked into the wall behind the pocket: seen on the server).
    8. *`npc-stuck-ladder`'s check.* Chosen: "freed by a step of the ladder within the cap, no back-off through the wall", not "freed by back-off or side-step". On a real server a body pushed into a pocket walled on three sides is pinned in its inside corner. A one-block side-step does not reach a straight line out; the local leg does. Alternatives: (a) a geometry the side-step solves (not "walled in on three sides"); (b) a simulated stuck (no real body).
    9. *Scenario road.* Chosen: the scenarios drive their own navigation service with the scene's loop line as the road, and open cell access for local legs. Alternatives: (a) draw a road in the road graph per scene (needs the API and road tables); (b) use the navigation module (off in CI, needs `navigation.walk.enabled`).
    10. *`/knk npc nav scene corners`.* Chosen: build the scene and save the route `corner-scene` (start to the stair corner); the 10-minute scene load is not a developer step because the scene has no road (the scenarios walk its loop). Alternatives: (a) add a scene road to the test driver (a second planner in `NpcNavRunner`).
    11. *Scene without a U-turn flight.* Chosen: leave it out (the box is 32 × 32); stacked flights are covered by `PathTargetsTest`. Alternatives: (a) a second scene box.
    12. *`road plans per group event`.* Chosen: the most road plans one group's members had waiting or running at once. Alternatives: (a) count plans in a window after each group event (more state for the same answer: a group event's plans start together).
    13. *Framework changes* (coordinator note 2). `CitizensBootstrap.start(plugin, registryName)` and `CitizensBootstrap.teleport` (additive), `CitizensNpcRuntime` with a registry name, the workflow's Citizens download and timeouts. The scenario framework's own code is unchanged.
6. **Out of scope, noted.** Followers in `ranks` repeatedly plan "off its lane" own legs on the scene's flights (seen in the `npc-corners-walk` log: x 4, z 9–14 and the south flight). They get back without a stuck spell, but it is group/lane behaviour for L4 (4b.3 fit and widths). Item 4: whether Citizens jumps at the 1433 44 -517 landing is developer step 4 (no dev world in CI).
7. **Blockers.** None. The pinned Citizens build is fetched and SHA-256 checked in CI.
8. **At merge / what the developer must do.**
    1. Merge the `config.yml` keys (YAML in the changelog and § 4.27), and set `stationary-ticks` and `no-progress-ticks` to 40 where the old 60 is still written. Restart.
    2. Run the developer test (L3) steps posted on #521 and post the stats, the traces and the run log there.
    3. Codex: at its usage limit on both PRs, so no review (noted on both PRs).
9. **Notes for L4.**
    1. `NavGroup` now has per-follower `ladder`, `steps`, `recoveryMove`, `tryMark`, `engineStuck`, `lostRetryTicks`, `failedTarget` and `failedFrom`. `send()` puts lane points through `continuous(…)` (the lane continuity guard); keep it when widths change.
    2. `GroupSettings` has `maxRetries`, `recoveryWaitTicks` and `waypointMargin` (an 8-argument constructor is kept). Formation and slot code is unchanged.
    3. The `npc-corners-walk` scene has 3-, 2- and 1-wide parts (east side, z 4–27) for `npc-group-narrows`; `ScenarioNpcs.patrolGroup` takes a formation.
    4. The "off its lane" loops on flights (item 6) are worth a look with the new width rule.

### 4.4 L4 — Narrowed formations and the followers-finish-trip toggle (#522: #493, #507)

1. **Scope done** (implementation plan 4b.3 items 1–15, behind `npc.navigation.enabled`, decided defaults of 4b.4).
    1. **Widths (knk-core `group/`).**
        1. `Formation(type, spacing, lateralSpacing, ranksWidth)` and `Formation.Width`; `widths()` lists them widest first. `ranks` goes from `group-ranks-width` down to 2, `cluster` 3 then 2, `escort-ring` as its rings (radius 1.25 × lateral), then rows of 3 with the leader in the middle of the second row, then 2 abreast, then a column with one escort ahead.
        2. The cluster nudge is at most a quarter spacing and points inwards for the outer lanes.
    2. **Fit and cache.** `GroupPath.levels`, `widest(i)` and `shift(i, level)` work out the widest fitting width and the lane shift per width once per path point. `stair(i)` makes a step point fit only the column. Lane points keep `LANE_CLEARANCE` 0.2 from a block edge without a floor.
    3. **Hysteresis.** `NavGroup.decideWidth` makes one pass over the stretch from the rearmost slot to the foremost plus the hysteresis. A column is taken at once; a narrower width (2 abreast or more) only when the narrow part lasts longer than `group-width-hysteresis-blocks`; a wider one only when it fits the stretch plus the hysteresis ahead. A new order takes the fitting width at once.
    4. **Lanes.** The slot side plus the point's shift. A lane is back on the centre `LANE_RETURN` (2 blocks) before a point where it has no floor, and it must also exist at the neighbouring points with this point's offset.
    5. **Events, logs, stats.** `GROUP_NARROW`, `GROUP_WIDEN`, `GROUP_FINISH_TRIP` (with `GROUP_FOLD`/`GROUP_REFORM`); the log lines of 4b.3 item 7; the groups line has `widths: narrows N, widens N | folds N, reforms N, folded now N | abreast now k | finished trips N (finishing now N)`.
    6. **The toggle.** `group-followers-finish-trip` in `NavigationSettings` and `GroupSettings`, the group command's `finish-trip|follow-leader`, and the state `FINISHING`.
        1. When an order ends with Arrived, followers still on their way keep the old path's lanes to their slot as a trip, with region and door checks, the trespass guard and their old order's doors.
        2. `NavGroup.MemberListener.onMemberArrived`, the log `finished its trip at`, then the follower follows the group.
        3. The leader does not wait for finishing followers; a replaced, cancelled or failed order releases them.
        4. Off: a follower on the leader's new route beyond the known path waits for the column (no own leg to the old goal).
    7. **Config.** `group-lateral-spacing` 1.0, `group-width-hysteresis-blocks` 3, `group-followers-finish-trip` false and `group-spacing` 1.5 in `config.yml` with comments.
    8. **Scenarios.** `npc-group-narrows`, `npc-group-gate-finish-trip` and `npc-group-access-change` on the L3 corner scene; `ScenarioNpcRules` (fake region data, the scenario gate's real state and box); `MIN_SCENARIOS` 25 (with #543's three); `--expect-timeout` 600, job timeout 20 min.
    9. **Docs** (knk-workspace `claude/npc-followups-l4`).
        1. `CHANGELOG.md` entry with the admin YAML.
        2. Configuration reference § 4.27 and § 2.1.
        3. Plan: Phase 4 known limits 1 and 3, the 4b.3 status and differences, and the L4 developer test steps including the #490 audit re-run.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l4` at `becf379c`: 3 commits and a merge of `origin/next` `8e3f82c7` (#543; conflicts in `PaperScenarios`, its test and `paper-boot.yml`, resolved by keeping both sides). Base `next` `5dc88cfd`.
    2. knk-workspace `claude/npc-followups-l4` at `95ff61c0`: 2 docs commits and a merge of `origin/next` `e7c40f54` (the changelog and the plan header, both kept). The merge commits have git's default message.
3. **PRs.** PandiO/knk-plugin#39 (`Closes` #522, #493, #507) and PandiO/knk-workspace#584 (`Part of` them), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`:
        1. Baseline on `next` `5dc88cfd`: core 2756, api-client 340 (2 skipped), paper 2782 (18 skipped).
        2. Result after merging `next` `8e3f82c7`: core 2777, api-client 340 (2 skipped), paper 2789 (18 skipped).
        3. 0 failures both times.
    2. New tests:
        1. knk-core: `FormationTest` (widths, layouts, narrowed ring, nudge) and `GroupPathTest` (cache looked up once, shifts, stairs, edge clearance).
        2. knk-core: `NavGroupWidthsTest` (3 → 2 → 1 → 2 → 3, bump, short widening, 1-block gate, cluster and ring on 3-wide) and `NavGroupFinishTripTest` (off, on, door still opening, replaced order, district edge).
        3. knk-core: `NavGroupTest` (under-door rule); `NavigationSettingsTest` (keys, layers).
        4. knk-paper: `NpcNavigationConfigTest` (keys in every layer, shipped `config.yml`) and `NpcNavGroupArgsTest`.
    3. Changed tests:
        1. `NavGroupTest` uses a 2.0 column (the default is 1.5 now). Its yard test expects a shift instead of a fold, and the gate test expects the step back.
        2. The `NpcNavRunnerTest` stats line, and 25 scenarios in `PaperScenariosTest`.
    4. **Plugin scenarios on a real server**, run locally: Paper 26.3 build 205 with WorldEdit, WorldGuard and Citizens build 4269, through `tools/paper-boot/boot-test.sh --scenarios --npc-navigation --min-scenarios 25`: 25/25 passed (`npc-group-narrows` 327 ticks, `npc-group-gate-finish-trip` 841, `npc-group-access-change` 232; L3's `npc-corners-walk` passes too).
    5. CI on PandiO/knk-plugin#39 at `becf379c`: `build` and `paper-boot` green (25 scenarios).
    6. Known reds: none.
    7. Codex: at its usage limit on both PRs, so no review (said on both PRs).
5. **Decisions (DESIGN § 4.3).**
    1. *Fit with a lane shift.* Chosen: lanes may shift half a block at a time up to the width's half width, and each lane point needs a floor 0.2 block to either side across the path. Alternatives: (a) today's rule only (the corner scene's 2-wide passage and wall-hugging north road never fit 2 or 3 abreast); (b) shift the whole formation by the road's measured centre (more world queries per point).
    2. *Cost per point.* Chosen: the widest width and the shift per width cached per point. The world looks per point and width are bounded and asked once, but there are more than one per width because of the shifts. Alternatives: (a) exactly one look per width without shifts (see 1).
    3. *Narrowing log text.* Chosen: `narrows to 2 abreast: the path is too narrow for 3 abreast` (the width that no longer fits). Alternatives: (a) `the path is 2 wide` (wrong at a lateral spacing other than 1).
    4. *Stairs.* Chosen: a path point where the floor steps a block is walked as a column, however wide the flight (plan item 3 names stairs with gates; lanes on the scene's 2-wide flight left a follower stuck). Alternatives: (a) 2 abreast on wide flights (failed on the server).
    5. *Lane return.* Chosen: back on the centre 2 blocks before a place without a floor for the lane. Alternatives: (a) one path point before (followers cut a 1-wide opening's wall corner: `npc-corners-walk` and `npc-group-narrows` failed).
    6. *Finishing follower's recovery.* Chosen: waypoints again after a stuck report or `no-progress-ticks`; it gives the trip up after `max-retries` tries and follows the group. Alternatives: (a) the full ladder (its steps are tied to the group path and the slot, a large change for a rare case).
    7. *Who finishes.* Chosen: followers in `FOLLOWING` that are not left behind and not in a stuck spell; ones on an own leg back are released as before. Alternatives: (a) every follower (an own leg's order would have to be cancelled and turned into a trip).
    8. *Toggle off.* Chosen: a held follower that stands on the leader's new route beyond the known path waits for the column. Alternatives: (a) today's own leg to the leader, i.e. to the old goal (the #507 symptom, found by `NavGroupFinishTripTest`).
    9. *Door margin before a moving door* (changes L2's rule). Chosen: a follower in the 1-block margin before a door that starts moving steps back out of it and is held; only one under the door walks on out. Alternatives: (a) L2's "walk on out" for both (on the server a closing portcullis blocks a body a third of the way in, and followers a block short were pressed against it); (b) only a slower scenario door (hides it).
    10. *Queue.* Chosen: followers stopped by a door or an edge stop a spacing behind each other, counted from the last point before it; a follower that already stands too close does not step back. Alternatives: (a) all to the same point (bodies pressed together, stuck spells); (b) step back too (moving held followers count as lag and the leader waited).
    11. *Held finishing follower.* Chosen: it looks again every group turn. Alternatives: (a) only on events (a door still opening at its event blocked it for good).
    12. *Scenario harness* (coordinator note 3). Chosen: additive hooks in `ScenarioNpcs` (rules and gate crossings in `start`, `rulesChanged`, `gateChanged`, `everyTick`, `dismiss`, `groupSettings`, `patrolGroup` with settings), with regions seen only by scenarios with rules of their own; the scenario framework's own code is unchanged. Alternatives: (a) the real navigation module (off in CI, needs the API's road tables).
    13. *Gate scenario.* Chosen: a 3 s portcullis, a goal past `hop-blocks` (a shorter order is one local leg without gates), the close when the leader is 4.5 blocks past (closer, the service still counts the crossing as ahead and replans), and for follow-leader the check "no follower finishes a trip". Alternatives: (a) "never past the goal's z" (wrong: the group's new route runs past it).
6. **Out of scope, noted.**
    1. A follower within about a step of the margin when a door starts closing may walk on into it before it steps back (Phase 4 known limit 1).
    2. The navigation service's progress index lags the leader by up to 20 ticks, so a gate event right after the leader passed a door replans its route (seen in the gate scenario; harmless but one plan). Not filed: it is the 4b.1 item 1 watchdog spacing, no wrong behaviour was seen.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge the `config.yml` keys (YAML in the changelog and § 4.27) and set `group-spacing: 1.5` where 2.0 is still written. Restart.
    2. Run the developer test steps posted on #522 (they include the #490 audit re-run with `/knk npc test spawn 50 24`; check that `causes:` shows no `DROWNING`) and post the stats, notes and run log there, the audit report on #490.
9. **For the docs session** (the chain's last link; the `documentation` sub-issue).
    1. Plugin scenarios guide: the six NPC scenarios (L3, #543, L4), `ScenarioNpcs` with rules and gate crossings, `ScenarioNpcRules`, and the rule that an order under `hop-blocks` is a short trip without gates.
    2. Admin/NPC guide: formations and their widths, the hysteresis, the toggle and `onMemberArrived` for later behaviour (couriers), the queue and the step back at doors, and the stats line.
    3. Feature register and guides index: NPC navigation Phase 4b (L3, L4) status after the developer's tests.
    4. `BEHAVIOR_MODEL.md` NAV-22/NAV-23: mark them built once tested.
10. **Merge of `next`, 2026-11-15 (coordinator's § 6 check).**
    1. knk-plugin: merged `origin/next` with PandiO/knk-plugin#38 (#540, six player scenarios) into `claude/npc-followups-l4` → `f965af06`. Conflicts in `paper-boot.yml` and `PaperScenariosTest`, both sides kept: 31 scenarios, `MIN_SCENARIOS` 31, `--expect-timeout` 600 with #540's bot-tests line, job timeout 20 min.
    2. knk-workspace: merged `origin/next` → `59f5f3b2`. The changelog conflict was additive; the L4 entry now says 31 scenarios.
    3. Tests after the merge: core 2788, api-client 340 (2 skipped), paper 2796 (18 skipped), 0 failures. Locally 31/31 scenarios passed.
    4. CI on `f965af06`: `build` green twice. `paper-boot` green on one run (43713989156). On the other run (43713985090) all 31 scenarios passed but the server-log check failed on an error from a #540 player scenario's fake player against the unreachable API; I filed #586 and re-ran that failed job.
    5. The re-run went green (job 132813641643): `build` and `paper-boot` green on both runs at `f965af06`. The coordinator merged PandiO/knk-plugin#39 into `next` (`deb7ff49`) and resolves the workspace changelog conflict and PandiO/knk-workspace#584 itself; L4 pushes nothing more to `claude/npc-followups-l4`.

### 4.5 L5 — Stair corner and the ranks row at the landing, retest fix (#592: #491, #492, #508)

1. **Scope done** (behind `npc.navigation.enabled`, no new config key).
    1. **Evidence on `next`, not on the developer's trace.** The coordinator found that the retest probably ran an older jar. I rebuilt both spots in their real geometry (`NpcLedgeScene`, one scenario box each) and ran them on `next` `8cbf5b32` with only the scenario files added:
        1. `npc-ledge-corner` fails on `next`. With a road line that cuts the turn, a waypoint lands on the ground below the corner. With that check skipped, 4 NPCs walk off: 0 arrivals, all pinned under the east flight. A line through the cells' centres does not fail, which is why L3's scene missed it.
        2. `npc-landing-ranks` (12 in `ranks`, one trip up) **passes** on `next` with a line along the flights' middle and a flat approach (not reproduced). It **fails** with a line that cuts the inside of the landing's turn: the trip ends `Failed` in the pit, with 5 spells not freed. In the scene the leader is caught too, unlike on the dev server. Whether this is the cause at 1433 44 -518 waits for the developer's rerun.
        3. On `next` the `falls` counter stays 0 for Citizens NPCs even after 7-block falls.
    2. **Cause (the 4 questions of the prompt).**
        1. Line points cutting the corner: yes, that is the trigger. Over the drop, `HopPlanner.snapNear` found no floor within 2 blocks and fell back to the nearest floor within 12, the ground, and the next waypoints chained along the ground.
        2. The best-index jump: not causal. `bestIndex` only feeds the watchdog. Citizens follows the waypoint list as given and skips no point.
        3. `straightWalkable` does see the ledge, but it only guarded waypoints that corner clearance moved; nothing checked the steps between waypoints.
        4. L3's scenes passed because their line runs through the cells' centres, so no line point lies over air.
    3. **knk-core.**
        1. `HopPlanner.surfaceNear`: a route point's floor is its own column near the previous floor or the line's height, else the nearest walkable column within a block, else none.
        2. `RouteFollower` skips a point with no walk beside it.
        3. `WaypointChain.bridged` makes every step (and the join from the last stretch) a straight walk, inserting the turns of a breadth-first search over the cells in a box round the two waypoints.
        4. `CornerClearance` counts a drop on the inside of a turn as a wall.
        5. `GroupPath.addSnapped` follows the same rule, repeating the point before when there is no walk.
        6. `NavGroup` passes lane waypoints (and a finishing trip's) through `WaypointChain`.
    4. **Falls.** New port `NpcMover.verticalSpeed()` (Citizens: entity velocity). In `RecentSteps`, a look in the air at 0.55 blocks per tick or faster downwards counts as falling in one go. Verified on `next`: `falls 4`, "fell 6.0 blocks".
    5. **knk-paper.** `NpcLedgeScene`, `npc-ledge-corner`, `npc-landing-ranks`, `ScenarioNpcs.group` (additive), trace `# waypoints:` lines, `MIN_SCENARIOS` 34.
    6. **knk-workspace.** Changelog entry, plan 4b.2 (L5 status, L3 test steps 3–5, automated steps 12–13), CI guide § 7.1.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l5` at `011b1745`: 4 commits plus a merge of `origin/next` (#41, #42; no conflicts). Base `next` `8cbf5b32`.
    2. knk-workspace `claude/npc-followups-l5` at `4a819546`: 2 docs commits plus a merge of `origin/next` (#595, #596). The changelog conflict was additive and both entries are kept.
3. **PRs.** PandiO/knk-plugin#43 (`Closes` #592, `Part of` #491, #492, #508) and PandiO/knk-workspace#599 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `8cbf5b32` core 2788, api-client 340 (2 skipped), paper 2804 (18 skipped). On `6d292dbb`: core 2802, paper 2804. After the merge on `011b1745`: core 2806, api-client 344 (2 skipped), paper 2824 (18 skipped). 0 failures each time.
    2. New tests: `LedgeCornerTest` (5), `WaypointChainTest` (6), `GroupPathTest` +1, `RecentStepsTest` +2, `CitizensNpcMoverPathTest` +1; trace assertion in `NpcNavRunnerTest`.
    3. Scenarios, locally (Paper 26.3 b205, WorldEdit, WorldGuard, Citizens b4269), with `boot-test.sh --scenarios --min-scenarios 34 --npc-navigation` on `6d292dbb`: 34/34 passed, all L3, L4 and #543 NPC scenarios included. The log check flagged one stack-traced WARN from a #540 fake player's teleport audit against the unreachable API: #586's intermittent, not from this change.
    4. CI on PandiO/knk-plugin#43: pending at the time of writing.
    5. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *A route point over a drop.* Chosen: the nearest walkable column within a block, else leave the point out (`surfaceNear`), because a waypoint on another level is never right. Alternatives: (a) keep `snapNear`'s 12-block fallback but refuse beyond 2 (the point stays in the air at the line's height and Citizens walks off towards it); (b) only drop the point (loses the turn on a cutting line).
    2. *Steps that are no straight walk.* Chosen: a breadth-first search over the cells in a box 3 blocks round the two waypoints (side at most 24, steps of 1 up or down, the body's headroom), its turns as waypoints, and the step left alone without a path. Alternatives: (a) try only the two L-shaped corners (fails on a long gap such as the cutting line's 5 blocks over air); (b) a local leg through the engine's search (a plan per stretch, asynchronous).
    3. *Drops in corner clearance.* Chosen: a cell on the inside of a turn with no floor within 2 blocks counts as a wall. Alternatives: (a) walls only, relying on the bridge (the body still brushes the ledge's edge at the turn); (b) a separate clearance for ledges (a new config key).
    4. *Group path over a drop.* Chosen: repeat the point before, because `trackLeader` maps line indexes to path indexes one to one. Alternatives: (a) skip the point (breaks that mapping).
    5. *Telling a fall from a stair step.* Chosen: vertical speed of 0.55 blocks per tick or faster at a look in the air. Alternatives: (a) feet 1.5 below the last ground look (counts full-block staircases: `RecentStepsTest`'s stair case); (b) look every tick while airborne (main-thread cost); (c) file it instead (the developer's `falls 0` check stays meaningless).
    6. *The landing scene's line.* Chosen: a line that cuts the inside of the turn, the variant that fails on `next`. Variants with a centre line, a flat approach and 20 members passed on `next`. Alternatives: (a) no failing landing scenario until the developer's schematic (the prompt asks for a failing reproduction); (b) claim the centre-line variant reproduces #492 (it does not).
    7. *Landing scenario shape.* Chosen: 12 in `ranks`, one trip up. Checks: the leader arrives, `maxLag` ≤ 2.5 and nobody lost, nobody still at the landing for over 3 s while the leader walks, spells freed within 2 steps, rejoins ≤ 6 (spawned followers rejoin once at the start). Alternatives: (a) patrol both ways (the leader's turnaround through its own column holds followers: noise); (b) 20 members (a column of 20 does not fit past the landing in a 32-block box).
    8. *Trace waypoint lines.* Chosen: add them (diagnostic, additive), so a trace shows whether a waypoint cuts a turn. Alternatives: (a) none (the question of #592 could not be answered from a trace).
6. **Out of scope, noted.**
    1. A request on #592 for WorldEdit schematics of both spots (optional, nothing waits on it).
    2. A correction on #592: the earlier reading of the trace may concern an older jar.
    3. Nothing posted on #491, #492 or #521.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`.
    2. Retest on a jar whose version line shows the deployed commit: the L3 steps 3–5 as posted on #592, with the traces' `# waypoints:` lines and the stats.
    3. If the landing still stops the group, the trace next to it shows whether the road line cuts that turn.
9. **Notes for later links.**
    1. L6 and L7: nothing of theirs touched (no access-rule or test-walker code).
    2. `WaypointChain.bridged(world, from, waypoints)` is reusable for any waypoint list.
    3. `NpcMover.verticalSpeed()` is the fall signal for Citizens.
