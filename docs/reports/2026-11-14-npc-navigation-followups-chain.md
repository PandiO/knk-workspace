# NPC navigation follow-ups chain — progress report

**Status:** In review: every link merged into `next`; developer smoke tests, the option-B decision and promotion open (2026-11-16) · **Last updated:** 2026-11-16

**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358), links
[#519](https://github.com/PandiO/knk-workspace/issues/519) (L1),
[#520](https://github.com/PandiO/knk-workspace/issues/520) (L2),
[#521](https://github.com/PandiO/knk-workspace/issues/521) (L3),
[#522](https://github.com/PandiO/knk-workspace/issues/522) (L4), fix links #592 (L5), #593 (L6), #594 (L7).
**Charter:** [handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md).
**History:** [first NPC navigation chain report](2026-11-13-npc-navigation-chain.md) (Phases 1–4 and #490 merged into
`next`; developer tests done 2026-11-14).

## 1. Waiting for the developer

Every link is merged into `next` (2026-11-16): L1–L6 and the movement links M1–M7. Build knk-plugin `next`
`cc5262ff` or later and check the startup line `0.1.0+<sha>`. Merge the `config.yml` keys (YAML in the changelog and
the configuration reference § 4.27), then restart. In test order:

1. **Smoke test tonight with all movement keys on** (`corridor-steering`, `local-legs-clearance`,
   `group-formation-keeping: elastic`, `plaza-lines`, `crowd-awareness`). Steps on #622, #623, #624, #625 and #626.
   The group of 20 in ranks on `quarry-to-keep` covers most of it. Name a plaza for #625.
2. **Collision (M7, #627):** the real-client push test (comment 6912759522). Its last step decides whether
   `npc.navigation.collidable` can become default on; today it stays false (block 4.15 decision 5).
3. **Earlier steps still open:** L2 #520 step 10 (now with L6), L3/L5 #592 steps 3–5, L4 #522, the #490 audit.
4. **Decisions for you:**
   1. **Option B** (decision 30), after the smoke tests.
   2. **Squeeze minimum with collision on** (0.7 to keep rows from overlapping; block 4.15 § 6).
   3. **M6 decision 6.1** (corridor grid instead of `WalkSearch`).
   4. **Review of the agent decisions** in blocks 4.5–4.15 § 6.
5. **Promotion of `next`** once the tests pass; then the issues close.
6. **Docs:**
   1. #658 for M1–M7 is in its own session (session_01R1w2UsvN2p9uCZqKQGjgrH).
   2. #590 (L2–L4 leftovers) waits for your test results.
7. **Filed along the way:** #636 (a follower that never settles), #657 (door-mouth rule), #586 (intermittent fake-player log line in CI).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Design: corners, narrowed formations, toggle | #519 | Merged into next (2026-11-15, design approved by the developer) | knk-workspace `96f47820` → `next` `4a97fd3b` | PandiO/knk-workspace#546 | docs only (no CI); Codex at its usage limit | create_session session_01R1w2UwysEMwCYnxwCpkx3p (2026-11-15) |
| L2 Follower recheck and guard, no gate push | #520 | Merged into next (2026-11-15, by the manager session) | knk-plugin `651d8bff` → `next` `11e07d64`; knk-workspace → `next` `43a2328c` | PandiO/knk-plugin#31, PandiO/knk-workspace#536 | PR head green (build, paper-boot); `next` runs 43662028862, 43662028855 pending at the coordinator check | create_session session_01R1w2Ux2KpS7H3FidwDEZmp (2026-11-14) |
| L3 Wall-corner steering and recovery | #521 | Merged into next (2026-11-15) | knk-plugin `51072e94` → `next` `5dc88cfd`; knk-workspace `4308aaf1` → `next` `51bf5952` | PandiO/knk-plugin#36, PandiO/knk-workspace#557 | PR head green (build, paper-boot with Citizens, 19 scenarios); Codex at its usage limit | create_session session_01R1w2Uv1rEnwPko4Tq83xyL (2026-11-15) |
| L4 Narrowed formations, followers-finish-trip toggle | #522 | Merged into next (2026-11-15) | knk-plugin `f965af06` → `next` `deb7ff49`; knk-workspace `bce76405` → `next` `ee9894ef` | PandiO/knk-plugin#39, PandiO/knk-workspace#584 | `build` green on `f965af06`; `paper-boot` green on one run, the other failed only the log check (#586, re-run); 31 scenarios; Codex at its usage limit | create_session session_01R1w2Uur6M3a3CaVDWJWCw7 (2026-11-15) |
| L5 Fix: stair corner, ranks row at the landing | #592 | Merged into next (2026-11-15) | knk-plugin `011b1745` → `next` `8ad9df66`; knk-workspace `4a819546` → `next` `8bad205a` | PandiO/knk-plugin#43, PandiO/knk-workspace#599 | PR CI green on `011b1745` (build, paper-boot with 34 scenarios, both runs); Codex at its usage limit | create_session session_01R1w2UxAFomY5DQ18vRtAH6 (2026-11-15) |
| L6 Fix: follower access with overlapping gate region | #593 | Merged into next (2026-11-15) | knk-plugin `736b91c2` → `next` `3c3d481e`; knk-workspace `fed2b672` → `next` `a63d76ba` | PandiO/knk-plugin#45, PandiO/knk-workspace#604 | PR head green (build, paper-boot with 35 scenarios); the push run's log check hit #586 and was re-run; Codex at its usage limit | create_session session_01R1w2UuimaZUvf6HRSGtpmp (2026-11-15) |
| L7 Fix: test walkers drown (#490) | #594 | Dropped (#490 audit clean on the right build; #594 closed) | — | — | — | — |
| L8 Design: movement quality (steering, formation keeping, crowding, plaza road lines) | #603 | Merged into next (2026-11-15; design decided by the developer, 15 questions) | knk-workspace `e8836db0` → `next` `61c29c16` | PandiO/knk-workspace#605 | docs only (no CI); Codex at its usage limit | create_session session_01R1w2Uv7BDN1HKCV2gWe5Mz (2026-11-15) |
| M1 Evidence and diagnostics | #621 | Merged into next (2026-11-15) | knk-plugin `3ce748e0` → `next` `a527c980`; knk-workspace `1310c3d9` → `next` `a8dbfa80` | PandiO/knk-plugin#47, PandiO/knk-workspace#632 | PR head green (build, paper-boot with 45 scenarios, both runs); Codex at its usage limit | create_session session_01R1w2Uv6Untjy5RbmJTDd1T (2026-11-15) |
| M2 Corridor steering (option A) | #622 | Merged into next (2026-11-15) | knk-plugin `4e247835` → `next` `0fa74a67`; knk-workspace `a837776d` → `next` `8927eab2` | PandiO/knk-plugin#48, PandiO/knk-workspace#633 | PR head green (build, paper-boot with 45 scenarios, both runs); Codex at its usage limit | create_session session_01R1w2UszyqgMVxpBHaUa2oH (2026-11-15) |
| M6 Clearance-aware local legs (add-on D) | #623 | Merged into next (2026-11-15) | knk-plugin `8fa83e09` → `next` `625c2c9c`; knk-workspace `f65d3c69` → `next` `e0783664` | PandiO/knk-plugin#49, PandiO/knk-workspace#634 | PR head green (build, paper-boot with 45 scenarios); Codex at its usage limit | create_session session_01R1w2UuwfDNhwngWZJue8wZ (2026-11-15) |
| M3 Formation keeping | #624 | Merged into next (2026-11-16) | knk-plugin `94b30146` → `next` `138ebc66`; knk-workspace `1b4692ed` → `next` `a428eb3e` | PandiO/knk-plugin#50, PandiO/knk-workspace#635 | PR head green (build, paper-boot with 45 scenarios; one #586 log-check re-run); Codex at its usage limit | create_session session_01R1w2UufiGFpPfGevZxvtVD (2026-11-15) |
| M5 Plaza lines | #625 | Merged into next (2026-11-16) | knk-plugin `727f020b` → `next` `3f116188`; knk-workspace `f5aa56e6` → `next` `f9be4963` | PandiO/knk-plugin#51, PandiO/knk-workspace#637 | PR head green (build, paper-boot with 45 scenarios, push and PR runs 43792722751, 43793671690); #586 did not hit; Codex at its usage limit | create_session session_01R1w2UwSt9YZCZUtsk5fQjU (2026-11-16) |
| M4 Crowd awareness | #626 | Merged into next (2026-11-16); option-B checkpoint with the developer | knk-plugin `8c864f7a` → `next` `a35fed5a`; knk-workspace `9f09cf23` → `next` `5b8125e5` | PandiO/knk-plugin#52, PandiO/knk-workspace#638 | push and PR runs on `8c864f7a` green (build, paper-boot with 45 scenarios; runs 43799206281, 43800089307); #586 did not hit; 45/45 locally; Codex at its usage limit | create_session session_01R1w2UsvLHZouJWudj4FxjT (2026-11-16) |
| M7 Collision with push resistance | #627 | Merged into next (2026-11-16); `collidable` stays false | knk-plugin `6393aa37` → `next` `cc5262ff`; knk-workspace `dc8a91c5` → `next` `8e3d7d06` | PandiO/knk-plugin#57, PandiO/knk-workspace#656 | push and PR runs on `6393aa37` green (build, paper-boot with 48 scenarios); Codex at its usage limit | create_session session_01R1w2UtyxLznso8wdydHmQf (2026-11-16) |
| L9 Fix: running groups ignore a realtime district deny | #668 | In review (PRs open, not merged) | knk-plugin `76259d86`; knk-workspace `1dffa06d` | PandiO/knk-plugin#61, PandiO/knk-workspace#669 | push and PR runs on `76259d86` green (build, paper-boot with 48 scenarios; runs 43941362118, 43944997333); #586 did not hit; 48/48 locally; Codex at its usage limit | create_session session_01R1w2UvV75PszFp2o3mNoHB (2026-11-16) |
| B1 Evidence: snapshot command (B1a), whole stair house and replay (B1b) | #670 | B1a merged into next (2026-11-16, `0f039203`); B1b in review (PRs open, not merged) | B1a: knk-plugin `1d9e3209`, knk-workspace `383cd24d`; B1b: knk-plugin `6d81d59a`, knk-workspace `6684a815` (both merged `next` after B1a) | PandiO/knk-plugin#62, PandiO/knk-workspace#691 (B1a); PandiO/knk-plugin#63, PandiO/knk-workspace#692 (B1b) | #62: build and paper-boot green (both runs); #63: green on `99c27a40` (19 min), head `6d81d59a` pending; 50/50 scenarios locally in 15 min 23 s; Codex at its usage limit | create_session session_01R1w2Uvzb6xQBt2SwiokGoe (2026-11-16) |
| B2 Stretch handover in 3D, appended, bridged from the feet | #671 | In review (PRs open, not merged) | knk-plugin `a30ac085`; knk-workspace `cbff95cc` | PandiO/knk-plugin#64, PandiO/knk-workspace#693 | `build` and `paper-boot` (50) green on `a30ac085` (runs 43988727914, 43988727937); 50/50 locally; Codex at its usage limit | create_session (2026-11-16) |
| B4 Waypoints and group slots at the real stair heights; jumps by upward speed | #673 | In review (PRs open, not merged) | knk-plugin `2a261289`; knk-workspace `73160c65` | PandiO/knk-plugin#65, PandiO/knk-workspace#694 | `build` and `paper-boot` (50) green on `2a261289` (push run 44008785404, PR run 44008842004); 50/50; Codex at its usage limit | create_session (2026-11-17) |
| B3 Crowd turns judged in 3D; the guard counts from the last entry | #672 | In review (PRs open, not merged) | knk-plugin `89eeb3eb`; knk-workspace `bcf7a3d9` | PandiO/knk-plugin#66, PandiO/knk-workspace#696 | `build` and `paper-boot` (50) green on `89eeb3eb` (push run 44017052199, PR run 44019311124); climb let go 0 in CI and three local runs; 27/27 `npc-*` locally; Codex at its usage limit | create_session session_01R1w2UwCdu4jcMQD9mXoQv8 (2026-11-17) |
| B5 Group followers under a leader a flight above: shaped path kept on the walk | #699 | In review (PRs open, not merged) | knk-plugin `6b186840`; knk-workspace `33add9f8` | PandiO/knk-plugin#67, PandiO/knk-workspace#716 | `build` and `paper-boot` (50) green on `6b186840` (push and PR runs); docs no CI; Codex at its usage limit | create_session session_01R1w2UvW8pwfjEAwo5hVKp1 (2026-11-17) |
| C1 Off-road starts and ends with the walk search, walked like the road line | #700 | In review (PRs open, not merged) | knk-plugin `b7608662`; knk-workspace `bafe631f` (`next` `ce0f65ec` merged in) | PandiO/knk-plugin#71, PandiO/knk-workspace#721 | `build` and `paper-boot` (59) green on `b7608662` (runs 44225040650, 44225046762, 44225040520, 44225046831); one red `paper-boot` on `ced61331` fixed (doorway jam); docs no CI; Codex at its usage limit | create_session (2026-11-17) |
| E1 Exit rules checked while NPCs walk | #701 | In review (PRs open, not merged) | knk-plugin `de1c8a6a`; knk-workspace `a827abc6` | PandiO/knk-plugin#74, PandiO/knk-workspace#725 | `build` and `paper-boot` (61) green on `de1c8a6a` (push and PR runs); both new scenarios fail on `next`'s walking checks, pass with E1; docs no CI; Codex at its usage limit | create_session (2026-11-18) |

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

19. **L5 checked and merged** (2026-11-15). § 6 held. The new scenario `npc-ledge-corner` fails on `next` (a line point
    over the drop was snapped 7 blocks down by `HopPlanner.snapNear`'s fallback) and passes with the fix, which is valid
    evidence on any jar. `npc-landing-ranks` fails on `next` only with a line that cuts the turn, so #492 is not
    confirmed reproduced, as the PR and block 4.5 say. Tests 2788/2804 → 2806/2824, 0 failed. CI `build` and `paper-boot`
    green with 34 scenarios. No Codex findings (usage limit). Merged PandiO/knk-plugin#43 → `8ad9df66` and
    PandiO/knk-workspace#599 → `8bad205a`. The `ci.md` change in the docs PR is the scenario count, which is in scope.
    L6 and L7 stay on hold until the developer's rerun (decisions 17 and 18).

20. **Developer's rerun on the right build** (2026-11-15 afternoon, relayed by the manager; comments on #490, #520,
    #521, #522). The #490 audit is clean, so L7 (#594) is dropped and the issue closed. #520 step 9 works but step 10
    fails on `next`, so L6 (#593) started at once (realtime path, cf. #533, and the `gate_2000131` overlap). #521 has a
    new hard spot at 1414 49 -503, and ranks fold in the 3-wide stair house. #522 failed (`group_fold 26` vs
    `group_narrow 2`; a group jammed at the stair-house entrance for more than 2 minutes). Developer's verdict: "No
    success. This needs way better pathfinding, more intelligent situational awareness and better formation keeping."
21. **Design pass for movement quality** (developer decision 2026-11-15, via the manager; the developer's answer to
    the question this session had open). Chosen: design link L8 (#603, knk-workspace only), with steering and lookahead,
    formation keeping (narrow before fold), crowding and yielding, and plaza road lines, the real spots as scenarios,
    and implementation links planned in the plan's Phase 7. It replaces further patch links for the formation and stuck
    problems. L8 runs alongside L6 (no shared files). Alternatives: (a) targeted fix links first; (b) pause the movement
    work after L6. The #522 issue and the docs session #589 wait for the design.

22. **L6 checked and merged** (2026-11-15). The realtime path was the cause (#533); the gate-region overlap was ruled
    out by tests. The new scenario fails on `next` without the fix. Tests 2806/2824 → 2816/2830, CI green (35
    scenarios; one #586 re-run). `next` had moved by an unrelated teleport-audit fix that merged cleanly. Merged
    PandiO/knk-plugin#45 → `3c3d481e`, PandiO/knk-workspace#604 → `a63d76ba`.
23. **L8 design decided and merged** (2026-11-15). The developer went through the 15 questions one by one in the
    coordinator session and asked for industry research before the steering decision (L8's research report). Decided:
    Phase 4c (not Phase 7); option A with add-on D, B only after a checkpoint; corridor-half-width 4; wall-clearance
    0.8 / 0.35; squeeze minimums 0.6 / 1.0; fold only as a last resort; stairs as wide as they fit with a step per
    lane; look-ahead depth + 4; lanes by access rules; first come at chokepoints (future: authority values, closed
    formations first); collision off for now, designed for (M7, push resistance; future: collision on); plaza lines on
    the NPC side, builder later; one key per link; WorldEdit schematic as evidence; order M1 → M2 → M6 → M3 → M5 →
    M4 → B checkpoint → M7. Merged PandiO/knk-workspace#605 → `61c29c16`. Sub-issues #621–#627 created; M1 started.

24. **Schematic delivered and M1 merged** (2026-11-15). Cloud sessions can't download GitHub attachment URLs (proxy
    403), so the developer uploaded the zip to the coordinator session. The coordinator pushed the .schem as data to
    knk-plugin `evidence/stairhouse-schematic` (`8438ce87`, no PR), and M1 took it from there. M1's § 6 check held:
    tests 2816/2832 → 2830/2851, 45 scenarios green in CI (timeouts raised), the developer's entrance jam reproduced as
    a baseline. Merged PandiO/knk-plugin#47 → `a527c980` and PandiO/knk-workspace#632 → `a8dbfa80`. M2 started.

25. **M2 checked and merged** (2026-11-15). § 6 held: tests 2830/2851 → 2853/2852, 45 scenarios green in CI with the
    stair-house and jagged singles asserting (12/12, 0 stuck spells, longest still at most 0.6 s), corridor share about
    0.005 ms per NPC per tick, behind `corridor-steering` (off). Codex at its usage limit. Merged PandiO/knk-plugin#48 →
    `0fa74a67` and PandiO/knk-workspace#633 → `8927eab2`. M6 started.

26. **M6 checked and merged** (2026-11-15). § 6 held: tests 2853/2852 → 2866/2853, 45 scenarios green, the ladder
    freed by K&K's own leg, all stair-house legs K&K's, behind `local-legs-clearance` (off). Merged PandiO/knk-plugin#49 →
    `625c2c9c` and PandiO/knk-workspace#634 → `e0783664`. M6 decision 6.1 (the leg searches a corridor grid instead of
    the plan's `WalkPathfinder`/`WalkSearch`) is put to the developer for confirmation. Chosen: merge without waiting,
    because it is reversible behind the key and § 7.1 merges on the checks. Alternatives: (a) hold the merge for the
    developer (blocks M3 on a reversible detail). M3 started.

27. **M3 checked and merged** (2026-11-16). § 6 held: tests 2866/2853 → 2880/2854, 45 scenarios green (one #586
    re-run), `npc-stairhouse-group` asserting. With `elastic` on the developer's stair house: folds 1 → 0, leader 27 s
    → 7.5–8 s, entrance jam 23.7 s → 0.4 s; the unsteady group of 9 on the jagged straight 5 stuck spells → 0. Merged
    PandiO/knk-plugin#50 → `138ebc66` and PandiO/knk-workspace#635 → `a428eb3e`. M5 started.

28. **M5 checked and merged** (2026-11-16). M5 went idle once before opening its PRs and was nudged (skill § 5.3).
    § 6 held: tests 2880/2854 → 2899/2859, 45 scenarios green, `npc-plaza-line` asserting (+40 % → +4 % over the
    obstacle-aware shortest line), behind `plaza-lines` (off). #636 (a follower that never settles) filed. Merged
    PandiO/knk-plugin#51 → `3f116188` and PandiO/knk-workspace#637 → `f9be4963`. M4 started.

29. **M4 checked and merged** (2026-11-16). § 6 held: tests 2899/2859 → 2921/2860, 45 scenarios green on the push
    and PR runs, `npc-doorway-crowd` and `npc-stairhouse-group` asserting (doorway 12/12 with 0 stuck spells, collision
    off and on). Merged PandiO/knk-plugin#52 → `a35fed5a` and PandiO/knk-workspace#638 → `5b8125e5`. The
    option-B checkpoint (plan 4c.4 item 8) goes to the developer next.

30. **Option-B checkpoint** (developer decision 2026-11-16, coordinator session). With A, D and turn-taking on, the
    five scenes no longer need B (entrance 23.7 → 0.4 s, 0 folds, 0 stuck spells at the jagged wall and the doorway,
    plaza +40 % → +4 %); what B would add is smoother curves and steering strays back. Chosen: **leave B for now and
    decide after the developer's smoke tests tonight** with all keys on; start M7 meanwhile. Alternatives: (a) plan a
    B link now; (b) drop B entirely. M7 started (session_01R1w2UtyxLznso8wdydHmQf).

31. **M7 checked and merged; chain done** (2026-11-16). § 6 held: tests 2921/2860 → 2955/2865, 48 scenarios green on
    the push and PR runs (`MIN_SCENARIOS` 48), the collision policy chosen by scenario (per-entity exemptions), players
    can't push NPCs and a pushed guard never falls. `collidable` stays false: four older scenarios fail with it on
    (block 4.15 decision 5), so the end-of-link condition for the default wasn't met. Merged PandiO/knk-plugin#57 →
    `cc5262ff` and PandiO/knk-workspace#656 → `8e3d7d06`. #589 had already been closed for L1–L4 (its leftover is
    #590), so a new documentation issue #658 covers M1–M7, with its docs session started. Tracker row set to In
    review.

32. **Smoke test 2026-11-16 failed** (jar `0.1.0+0d9c55d6`, logs uploaded to the coordinator session). Problem A: L6's
    fix doesn't reach a running group on the real path. The deny arrives as the access-rules sync, there are 0 event
    replans and 19 of the 20 group NPCs are IDLE. L6's scenario faked a different message. **L9 #668 started**
    (session_01R1w2UvV75PszFp2o3mNoHB). Problem B: no visible improvement:
    1. falls at 1412 66 -537 and 1412 49 -501;
    2. jumps on stairs;
    3. a 39-NPC queue at 1412 74 -536;
    4. stuck at 1410 49 -503.

    A read-only root-cause pass runs in the coordinator session on the logs and the exact code. No B fix starts before
    the plan goes to the developer and the manager.
33. **Test material from the real world** (developer decision 2026-11-16, coordinator session). The scenes differ from
    the real world in the hand-drawn road line, the fake API data and partial geometry. Chosen: replay the real route
    on a snapshot of the dev world in CI. The **first B link adds `/knk npc nav snapshot <route>`**, which writes a zip
    with the route's region files (here `r.2.-1.mca`, `r.2.-2.mca`), the stored route line, the road network in the
    box, and the domain rules and WorldGuard regions from the plugin's caches. The developer uploads it to the
    coordinator session; scenarios replay the real runs on it. It starts after L9, one knk-plugin link at a time.
    Alternatives: (a) a full dev server with API and seeded database in CI (most faithful, heavy, a later nightly job);
    (b) `/knk scenario run` on the dev server (real but manual, a complementary self-check); (c) the developer copies
    region files by hand (no road export exists, so the line would still be missing).

34. **Root cause of the movement failures** (2026-11-16, a read-only pass in the coordinator session on the developer's
    logs and `next` `0d9c55d6`).
    1. **Main cause: the stretch handover.** `NpcNavigationService` hands out the next stretch when the NPC is within 4
       blocks of the stretch end, measured horizontally only. `follow()` replaces the waypoints not yet walked.
       `WaypointChain` bridges the join from the last waypoint, not from the NPC's feet. On the Keep stair's stacked
       hairpins this skips flights and heads across the stairwell, as traces 69 and 81 show. It explains the falls
       at 1412 66 -537 and 1412 49 -500 (followers copy the leader's fall into the group path), the stuck spot at
       1410 49 -503 and the entrance trouble.
    2. **Separate causes:**
       1. `CrowdControl` turns are judged horizontally only. A holder that fell under the landing never passes, so
          the 30 s guard releases the 39-NPC queue at 1412 74 -536.
       2. The stair "jumps" are mostly half-block step-ups that the trace flags as jumps. The 12 real ones come from
          whole-block waypoint heights at the flight entries.
    3. **Why no scenario caught it:** M1's hand-drawn line stops at y 51; the scene route is a single stretch, so no
       handover ever runs; it enters from the north instead of the east; and the upper landings lie outside the box.
    4. **Plan, after L9, one knk-plugin link at a time:**
       1. B1: evidence, the snapshot command (decision 33) plus the stair-house line extended along the real route with
          short stretches, failing on today's `next`.
       2. B2: the stretch handover (3D progress, append instead of replace, bridge from the feet, an unbridgeable step
          becomes a local leg, no falls copied into the group path).
       3. B3: 3D crowd turns.
       4. B4: waypoints at the real stair surface heights, and jump detection by upward speed.
    5. Sent to the developer and the manager before any B link starts. Asked the developer for a second schematic
       (x 1397–1423, y 48–87, z -553..-486) and whether `group-formation-keeping` was `elastic`; the logs suggest
       `levels`.
35. **Developer answers, B1 scope and the test configuration** (2026-11-16, coordinator session).
    1. The schematic of 2026-11-15 already holds both flights of the stair house (x 1407–1418, y 49–79,
       z -549..-487), so no second schematic is needed. B1 places the scene box around that whole schematic, upper
       landings included, instead of M1's box (y 46–69).
    2. The snapshot also takes the **domains along the route** (developer request): every Town, District, Structure
       and gate whose WorldGuard region touches the route's box, with its id, name and type, its region id and shape
       (cuboid corners or polygon points with min and max y, whole, not clipped to the box), parent, priority, entry
       and exit rules (`knk-allow-entry`, `knk-allow-exit`) and the gate's open or closed state. The replay builds
       these regions and the matching fake API data, so access rules (#506, L9) can be tested on the real layout.
    3. The developer's dev-server `config.yml` was missing every key added since 2026-11-14. During the failed smoke
       test the server ran `stationary-ticks` and `no-progress-ticks` 60 (default 40 since L3), `group-spacing` 2.0
       (default 1.5) and no `group-formation-keeping`, so `levels`, not `elastic`; the M3 squeeze and look-ahead
       keys were not set either. The coordinator merged the file for the developer (`next` defaults, the dev
       server's own values kept, the old defaults replaced). The next smoke test runs on the merged file.
36. **L9 checked and merged; B links created** (2026-11-16). § 6 held: CI `build` and `paper-boot` (48) green on
    head `76259d86`, diff reviewed (a region-query supplier asked for on use; scenarios read regions through the live
    module), Codex at its usage limit. Merged knk-plugin#61 → `a78fcce8`, knk-workspace#669 → `6e92b112`; retest
    steps on #668. Side effect noted for B: per-region `npc.navigation` overrides never applied to NPCs before L9.
    Created B1 #670, B2 #671, B3 #672, B4 #673 (sub-issues of #358) and started B1. B2–B4 are fixes; the manager has
    the plan (decision 34).
37. **B1 checked and merged; B2 started** (2026-11-16). B1a (snapshot command) merged early at the developer's request
    (knk-plugin#62 → `0f039203`, knk-workspace#691 → `21e3e103`); the developer took the snapshot at 21:25 UTC
    (evidence branch `evidence/smoke-2026-11-16`). B1b (replay and scenes) § 6 held: CI `build` and `paper-boot` (50)
    green on `6d81d59a`, production change only the gate-type fix of the snapshot taker; merged knk-plugin#63 →
    `80902942`, knk-workspace#692 → `2da5d798`. On `next` the replay shows a group of 20 with 32 stuck spells and 6
    followers lost while a leader alone arrives; the schematic climb with short stretches shows the falls, the
    handovers onto another level and the guard-released turn. These are B2's pass/fail proof.
38. **B2 checked and merged; B4 before B3** (2026-11-17). § 6 held: CI `build` and `paper-boot` (50) green on
    `a30ac085`, no debug code in the diff, core changes reviewed (`Trail`, `WaypointChain.split`, the gap leg,
    `NavGroup.leaderFell`). Merged knk-plugin#64 → `36ea2da0`, knk-workspace#693 → `a8e77d7d`.
    Climb: falls 42 → 0, handovers onto another level 446 → 0. Replay: 0 falls everywhere; the group of 20 on the
    stored settings still has 26 stuck spells and 3 lost, caused by slots at whole-block heights on flight 5 (half-block
    steps; evidence on #673). No guard release without a fall occurred, so B3's case was not seen. Order changed: B4
    (#673, stair heights, now also slot heights) runs next, then B3 (#672) only if the replay or the climb still shows
    a crowd-turn fault. Alternative: B3 first as planned (rejected: it would fix nothing the tests show).
39. **B4 checked and merged; B3 started** (2026-11-17). § 6 held: CI `build` and `paper-boot` (50) green on
    `2a261289`, no debug code, core diff reviewed (`NavGeometry.onSurface` on every waypoint list the mover gets, slot
    heights at the surface, the slot-point settle once the leader arrived). Merged knk-plugin#65 → `a3f0ebae`,
    knk-workspace#694 → `0664b1ee`. Replay group on the stored settings: 0 lost (now a check), stuck spells 26 → 6,
    none a crowd turn. Climb: 0 jumps toward a waypoint (the 160 left are Minecraft's own stair hops, reported apart,
    B4 decision 5.5). B3 is needed: on the crowded climb the 30 s guard let queues go in 4 of 6 runs without a fall
    (longest queue 18). B3 (#672) started with that as its proof. Filed by B4: #695 (jumps at the hall entry stair with
    the smoke test's settings, report only).
40. **B3 checked and merged; fix links done** (2026-11-17). § 6 held: CI `build` and `paper-boot` (50) green on
    `89eeb3eb` (push and PR runs), no debug code, `CrowdControl` diff reviewed (a place's fitted floor, `LEVEL_GAP`
    1.5, off-level holders and followers, the guard counted from the last entry). Merged knk-plugin#66 → `e69dba6a`,
    knk-workspace#696 → `6be8222c`. Climb: 0 let go by the guard (was 3–6), 0 falls, 0 handovers onto another level,
    0 jumps toward a waypoint, 0 stuck, 0 lost. For the developer's review: B3 decision 5.4 (the 30 s guard now counts
    30 s in which nobody entered the place, not 30 s since arrival; a place nobody enters still releases after 30 s).
    Open: the developer's smoke test of `quarry-to-keep` on `next` `e69dba6a` (#358 comment), #695 (report only), the
    option-B decision, the `collidable` default, promotion.
41. **Developer decision on B3 5.4: accepted** (2026-11-17, coordinator session; recorded on #672). Also checked
    for the developer: the NPC walking checks (recheck, trespass guard, follower lanes; L9) apply the entry rule of
    every region mapped to a domain, whatever its type (town, district, structure, gate). Exit rules hold where a
    route is planned, from the NPC's position, but the walking checks do not re-check them (`DomainEntryRule` is
    entry only; the module's own warning says "exit rules hold only where a route is planned").
42. **Developer smoke test of 2026-11-17 on `e69dba6a`; links B5 and C1** (evidence on knk-plugin
    `evidence/smoke-2026-11-16` under `.../evidence/2026-11-17/`).
    1. Passed: the leader alone through the stair house (no fall, no skipped flight, no stop at 1410 49 -503, arrives;
       about 4 small hops after a stair step, added to #695); the access change mid-group (#668), completely; the
       singles of the crowd step.
    2. Failed: a `ranks` group (elastic) on the second-last flight; the leader ended up one flight directly above its
       group and the followers looped on the flight below ("off its lane at 1413 67 -539: its own leg back to 1416 69
       -542" repeated). Same in the crowd step. Link **B5** (#699) started.
    3. New route `northern-wearway-upper-keep-tower`: the road part went well; the ~100-block off-road end through the
       throne room and up a spiral staircase failed (stuck at 1405 85 -510). Link **C1** (#700, off-road legs with the
       walk navigator's search) after B5. The developer's question about off-road parts is answered in the coordinator
       session; the exit-rule gap (decision 41) waits for the developer's answer.
    4. The developer noted that there are no places on the test routes narrow enough to make groups queue; a route for
       that comes later. Collision stayed off.
43. **Developer answers, 2026-11-17.** (1) The exit-rule gap runs as its own link E1 (#701) after C1. (2) Idea filed:
    NPCs avoid drops that would hurt them, the cost scaling with the drop, read from cells already captured (#702,
    future, `idea`). (3) The developer is designing road graph and knk navigator improvements (walk legs, plaza
    navigation) in a separate session, implementation from 2026-11-18. C1 therefore uses the walk navigator through its
    entry points without changing its code, and the coordinator reads that design before C1 starts (comment on #700).
44. **Order with the off-road navigation design #698 (developer decision 2026-11-17).** The coordinator had missed
    #698's sessions board row (on the board since 14:11 UTC; a keyword search instead of a match by issue and files;
    the board-fetch rule is being fixed on `claude/board-fetch-before-read`). #698's phase 1 moves the corridor code and
    `NavWorld`, `NavPoint`, `NavGeometry` and `HopPlanner`'s floor helpers to `core/navigation/shape/`; its long walks
    (clusters, O32) cover most of C1. Agreed order: B5 → #698 phase 1 → a narrowed C1 (today's walk search within its
    caps, road join by reachability, hops as fallback) → E1. NPC use of #698's long walks moves into that design's v1.
    Recorded on #698 and #700. Alternative: C1 as filed first (rejected: it would collide with the move and duplicate
    the long walks).
45. **B5 checked and merged; C1 waits for #698's L2** (2026-11-17). § 6 held: CI `build` and `paper-boot` (50) green on
    `6b186840`, no debug code, no files in `core/roads/walk` (the off-road chain's L1), `GroupPath.addShaped` reviewed.
    Merged knk-plugin#67 → `55ea7df3`, knk-workspace#716 → `c54786ac`. Cause: corridor-shaped line points cut the
    stacked hairpin across the stairwell, so the group path skipped flight 5's top and followers looped off their
    lanes. Replay on the 2026-11-17 snapshot: 21 off-lane legs → 0, 0 looping, 0 lost. For the developer's review: B5
    decisions 5.1 and 5.2. The off-road chain's coordinator (session_01R1w2UuBBnWjqekMFxEMefN) was told; its L2 (#704,
    the move to `core/navigation/shape/`) starts now; C1 starts when L2 is merged (decision 44).
46. **C1 checked and merged; E1 started** (2026-11-18). § 6 held: CI `build` and `paper-boot` (59) green on
    `b7608662`, no debug code, no edits in `core/roads/walk`, `paper/navigation` or `core/navigation/shape` (the off-road
    chain's areas), walk searches on the walk executor, merged clean into `next` after two rounds of mechanical
    conflicts (MIN_SCENARIOS, `PaperScenariosTest`) with the off-road chain's L4 and L10 step 1. Merged knk-plugin#71 →
    `65c7d6d3`, knk-workspace#721 → `b0bd7f4a`. Keep tower: leader stuck → arrives 53.4 s, group of 20 arrives 59.1 s,
    0 lost; the spiral fits the walk caps (172–180 of 220 blocks), so no acceptance case for #698's NPC phase. Detour
    and ravine fail before, arrive after. Also fixed: the replay Anvil reader dropped 26.x block states since B1; open
    doors were walls. For the developer's review: C1 decisions 5.3, 5.4, 5.10. E1 (#701) started.
47. **E1 checked and merged; chain back to In review** (2026-11-18). § 6 held: CI `build` and `paper-boot` (61) green on
    `de1c8a6a`, no debug code, no edits in the off-road chain's areas or in `core/roads/route` and `core/regions`; the
    exit rule comes from `DomainAvailability.exitDeniedRegions` through `DomainEntryRule`'s new `RegionRule`. Merged
    knk-plugin#74 → `7aef3de4`, knk-workspace#725 → `7a397e15`. For the developer's review: E1 decisions 5.1, 5.4, 5.5.
    Filed by E1: #724 (a cache refresh's first event with the map empty; in the off-road chain's area, offered to its
    coordinator). Docs follow-up #726 for L9, B1–B5, C1 and E1 with its docs session started. Open: the developer's
    retest (smoke guide sections B5, C1, E1), the review decisions of B5, C1 and E1, #695, #702, #724, the option-B
    decision, the `collidable` default, promotion.
48. **R1 started for #724** (2026-11-18). The off-road chain's coordinator does not take #724 (no link of theirs covers
    the cache-refresh path) and agreed it runs in this chain; R1 keeps any `paper/navigation` edit to the refresh path,
    away from guidance-v2, and reports the files first.

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
    4. CI on PandiO/knk-plugin#43 at `011b1745`: `build` and `paper-boot` green on both runs (43723978874, 43723978935, 43723382198, 43723382240). Codex at its usage limit on both PRs (said on both).
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

### 4.6 L6 — Followers enter a district whose entry was removed, with a gate region over its entry (#593: #506, #533)

1. **Scope done** (behind `npc.navigation.enabled`, no new config key).
    1. **Candidate 1, the realtime path, is the cause.** A district's AllowEntry changed in the web app arrives as `EntityChanged` (KnKPlugin's handler clears the region → domain map) and `DomainAccessChanged` (only `DomainAccessFlagSync`). Neither told NPC navigation. `NavGroup` kept its per-region verdicts from before the change (cleared only by `rulesChanged`), the NPC checks count a region missing from the map as open, and the followers walked in with `trespasses 0`. The new `NavGroupDomainRulesTest`, run with the event left out of the realtime path (`next`'s behaviour), fails: `npc-11 entered the district at x=50.17`.
    2. **Why the refresh didn't stop them either.** On the right jar the refresh path works with the gate region (tested). The likely reason is that it came after the outside followers had walked in under the stale verdicts. The developer's log is not in the issue, so this is inferred from the code and the tests.
    3. **Candidate 2, the overlapping gate region, is not the cause.** `DomainAvailability.mayEnter` judges each region on its own, and `DomainAccessEvaluator` has no priority, so a step into `district_1000004` and `gate_2000131` at once needs both allowed. The API's parent decisions carry their own `allowEntry` (swagger `DomainRegionDecisionDto`), so warming the gate region after the district keeps the district's deny (tested). A gate region without a domain is open but does not hide the district's deny (tested).
    4. **Candidate 3, the group recheck:** correct once the event arrives. The leader inside replans nobody, and the followers' lanes are rechecked in the next tick.
    5. **knk-plugin.**
        1. `RegionDomainResolver.refreshRegions(world, regions)`: re-asks each region now, keeping the cached entry until the answer is in.
        2. `paper/navigation/NavigationDomainChanges`: the four domain types' `EntityChanged` and `DomainAccessChanged` ask, coalesced under one key, for a second `DomainCacheRewarm` over `refreshRegions`, which then sends the availability event (only while NPC navigation runs). It is wired in `KnKPlugin.registerConfigSync` (field `navigationDomainRewarm` set in `initializeNavigation`).
        3. `core/npc/nav/DomainEntryRule`: `NavigationAccess.mayEnter(AccessSubject)` moved to core, unchanged.
        4. `NpcNavigationService.onAvailabilityChanged`: the NPC's own trespass guard takes a fresh look, as L2 did for followers. The new scenario had caught `TRESPASS` for a leader that crossed in the second before the denial arrived.
        5. Scenario `npc-group-realtime-entry`, `MIN_SCENARIOS` 35.
    6. **knk-workspace.** Changelog entry; plan Phase 4 known limit 4 and step 10 (realtime on, no refresh, partly automated); `ci.md` § 7.1. No new key, so configuration reference § 4.27 is unchanged. Developer test steps are posted on #593.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l6` at `736b91c2`: 2 commits on `next` `8ad9df66`.
    2. knk-workspace `claude/npc-followups-l6` at `fed2b672`: 2 docs commits on `next`.
3. **PRs.** PandiO/knk-plugin#45 (`Closes` #593 and #533, `Part of` #506) and PandiO/knk-workspace#604 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `8ad9df66` core 2806, api-client 344 (2 skipped), paper 2824 (18 skipped). Result on `736b91c2`: core 2816 (+10), api-client 344, paper 2830 (+6). 0 failures.
    2. New tests:
        1. `NavGroupDomainRulesTest` (5): realtime, `DomainAccessChanged` and refresh paths with the gate region, a gate region without a domain, the per-region step.
        2. `RegionDomainResolverTest` +3.
        3. `NpcNavigationRulesTest` +2.
        4. `NavigationDomainChangesTest` (6).
        5. `PaperScenariosTest` updated for 35.
    3. Scenarios, locally (Paper 26.3 b205, WorldEdit, WorldGuard, Citizens b4269, `--min-scenarios 35 --npc-navigation`): on `57cadeb4`, 34/35, with `npc-group-realtime-entry` failing `trespasses 1` (the leader, fixed in `736b91c2`). On `736b91c2`, 35/35, log check passed.
    4. CI on `736b91c2`: the PR runs `build` 43729074620 and `paper-boot` 43729074545 are green. The push run's `paper-boot` 43728303099 passed 35/35 scenarios but its log check hit #586 (`ScnRejoiner … Failed to check duplicate`), so its failed job was re-run.
    5. Known reds: none. Codex: at its usage limit (said on the PR).
5. **Decisions (DESIGN § 4.3).**
    1. *How the realtime path reaches the NPCs.* Chosen: re-ask the roads' regions in place (`refreshRegions`) after the coalescer's delay, then the availability event, because the last known rule keeps serving until the answer is in. Alternatives: (a) `warmCache` after the existing clear only (the `DomainAccessChanged` path does not clear, so a stale "allowed" would stay); (b) also clear on `DomainAccessChanged` (changes the map for players too); (c) an immediate event before the re-warm, as the refresh path does (answers from an empty map, all open, which is no better than the stale verdicts).
    2. *Which events.* Chosen: `EntityChanged` for Town, District, Structure and DomainSubRegion, and `DomainAccessChanged`, all under one coalescer key, so one save gives one re-warm. Alternatives: (a) `EntityChanged` only (misses a change that arrives only as `DomainAccessChanged`); (b) per-event keys (two re-warms per save).
    3. *Leader's guard.* Chosen: an availability event resets an NPC's guard regions to where it stands, as `NavGroup.rulesChanged` does for followers. Alternatives: (a) leave it (a false trespass for any NPC crossing in the second before the change arrives); (b) make the scenario start the change earlier (hides a real guard flaw).
    4. *Shared entry rule.* Chosen: move `NavigationAccess.mayEnter(AccessSubject)` into core `DomainEntryRule`, so the group tests read the rules as the server does. Alternatives: (a) a copy in the test sim (could drift); (b) knk-paper tests over the core `GroupSim` (test fixtures are not shared between modules).
    5. *Scenario API.* Chosen: the real router, coalescer, `NavigationDomainChanges` and `DomainCacheRewarm`, with a fake API answering 10 ticks later and the outside/inside split taken at the event. Alternatives: (a) `ScenarioNpcRules.deny` (does not exercise the realtime wiring); (b) the split at the web-app change (counts followers who enter during the API's second as failures).
6. **Out of scope, noted.**
    1. The re-warm covers the road network's regions only. A region the group's path passes that no road edge lists, and that is not a parent of one, stays unknown (open) after a realtime clear. Not filed: not seen, and the gate region's answer registers its parent district anyway.
    2. If step 10 still fails, check the district's road rule ("Ignored" for roads skips its rule on roads, rev. 7 Part C). This is noted in the #593 test steps.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration. Deploy the plugin and check the startup line `0.1.0+<sha>`.
    2. Run the developer test steps on #593 (plan Phase 4 step 10: realtime on, without `/knk cache refresh`, then once with it) and post the stats and the log there.
9. **Notes for later links.**
    1. `RegionDomainResolver.refreshRegions` and `NavigationDomainChanges` are reusable for any realtime rule change that NPC navigation must hear of.
    2. `NpcNavigationService.onAvailabilityChanged` now reads each NPC's regions (one WorldGuard query per NPC per event).
    3. L8 and the movement links: nothing of theirs touched (`RouteFollower`, `HopPlanner`, `WaypointChain`, `CornerClearance`, formations, lanes).

### 4.8 L8 — Design: movement quality (steering, formation keeping, crowding, plaza road lines) (#603)

1. **Scope done** (docs only, on knk-workspace `claude/npc-followups-l8`).
    1. `IMPLEMENTATION_PLAN.md` Phase 7 "Movement quality" reworked: 7.1 what the code on knk-plugin `next` `8ad9df66` does today, 7.2 approaches, 7.3 proposed decisions, 7.4 links M1–M5 (scope, tier, repos, keys off by default, automated-first tests, done-when) and a short developer test on `quarry-to-keep` and `south-gate-short`, 7.5 the real places as scenarios, 7.6 the earlier Phase 7 items, 7.7 fifteen questions; the phase-table row (depends on 4b, size L, NAV-24–NAV-28).
    2. `BEHAVIOR_MODEL.md` § 2: NAV-24 (steering with look-ahead; amends NAV-19's "straights may hug a wall"), NAV-25 (formation keeping), NAV-26 (situational awareness), NAV-27 (plaza lines), NAV-28 (tick budget), all "proposed".
    3. `docs/CHANGELOG.md`: one line.
    4. **Code findings** (knk-plugin `next` `8ad9df66`):
        1. Folds outnumber narrowings because in `NavGroup.decideWidth` the column skips the hysteresis while narrower widths need it; a width must fit at every point under the whole group (about 12 blocks for 20 in ranks of 3); many points are column-only (`GroupPath.stair` at every full-block step, lanes whose WorldGuard region set differs from the path's, `LANE_CLEARANCE` failures at jagged walls with half-block shifts only); there is no squeeze, no look-ahead and no hold on re-forming (folds and re-forms in pairs, 26 and 26).
        2. On a width change follower *i* keeps index *i* in the new slot list (`levelSlots.get(level).get(i)`), so followers cross each other's lines on a fold.
        3. Straights get no clearance (corner clearance acts at turns of 30° or more only), and the skeleton line wanders towards indentations; all singles walk the same line, so they catch the same jutting piece.
        4. `collidable: false` by default, so a doorway jam is K&K's logic (no ordering at an open doorway, waiting not told from stuck), not bodies pushing.
        5. The road-graph builder is knk-plugin `knk-core/.../core/roads/build/` (`TileBuilder`, `SkeletonGraph`, `Rdp`); `SkeletonGraph` collapses a plaza into one junction, so routes cross a plaza through its middle. NPC lines are `Route.polyline()` as is (knk-paper `paper/navigation/NavigationService`); `TrailCentring` (KNG-76) is applied to the player trail only.
2. **Commits and heads.** knk-workspace `claude/npc-followups-l8` at `939ebd8`: 1 docs commit on `next` `8bad205a`.
3. **PRs.** PandiO/knk-workspace#605 (`Closes #603`, `Part of` #508, #493, #521, #522), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-workspace: docs only. The relative links I added resolve (navigation DESIGN, configuration reference § 4.27, the knk-test-writer skill, the charter, the BEHAVIOR_MODEL anchor).
    2. Known reds: none. Codex: at its usage limit, so no review (said on the PR).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the design goes.* Chosen: Phase 7 "Movement quality" reworked in place, the earlier outline kept as 7.6, because the prompt names it and the work is movement quality. Alternatives: (a) a new Phase 4c (4b is closed scope); (b) a separate design file (the charter binds the plan).
    2. *Steering.* Chosen: corridor shaping of each ~32-block stretch (clearance by distance transform, look-ahead with body width plus clearance, string pulling, doorway alignment) before Citizens walks it: per-stretch cost, shared by NPCs on the same stretch, pure knk-core over `NavWorld`. Alternatives: (a) a K&K step controller (per-tick steering, new port; kept as the fallback in 7.6); (b) ORCA or velocity obstacles (per-tick velocity control, doorway deadlocks, built for colliding agents); (c) flow fields (one per goal); (d) more corner rules (straights and funnels stay unsolved).
    3. *Formation keeping.* Chosen: fit from the corridor's free width, squeeze to minimum spacings before narrowing, look-ahead of the formation's depth plus 4 blocks, the same hysteresis for every change with lane merging for short spots, stairs 2 abreast with a step per lane, lanes judged by access rules, slots re-assigned by place on every change, fold reasons counted. Alternatives: (a) only make the column wait for the hysteresis; (b) flocking without slots; (c) the Hungarian method (same answer here at more cost).
    4. *Crowding.* Chosen: an occupancy hash every 5 ticks, chokepoints taken in turns (in it, column order, group before single, first come), yielding on narrow stretches, waiting not counted as stuck, `collidable: false` kept. Alternatives: (a) ORCA; (b) first come only; (c) separation only; (d) `collidable: true`.
    5. *Plaza lines.* Chosen: string pulling across the plaza's footprint on the NPC side (M5), the graph unchanged. Alternatives: (a) through-edges in `SkeletonGraph` (players' trail too; more edges, a builder version bump and rebuilds); (b) a plaza mesh in the road data (API schema change); (c) walked lines (NAV-18).
    6. *Flags.* Chosen: one key per link, off by default. Alternatives: (a) one master key.
    7. *Evidence.* Chosen: a scenario scene loaded from a WorldEdit schematic (WorldEdit is on `paper-boot`), with synthetic stand-ins for the jagged straight, the doorway and the plaza, and M1's scenarios in report mode until the later links turn their checks into assertions. Alternatives: (a) hand-built approximations only (L5's way; the stair house is too irregular to rebuild from a description); (b) a block-dump command.
    8. *Link order.* Chosen: M1 evidence, M2 corridor, M3 formations and M5 plazas (both need the corridor), M4 crowding. Alternatives: (a) formations first (they need the corridor's fit); (b) crowding before formations.
6. **Out of scope, noted.** None filed. L6's passages (plan Phase 4 step 10 and known limit 4) untouched.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Approve the design and answer the questions (on #603 or with the coordinator). No `config.yml` key or migration in this link.
    2. Optional, for M1: the evidence on #603 (comment 6896780713): the stair-house schematic with exact WorldEdit commands, a trace at 1414 49 -503, a trace and the fold lines at the entrance, the plaza to test, the `collidable` value.
    3. Questions (proposed defaults with alternatives):
        1. **Where the work goes:** Phase 7 "Movement quality" reworked (proposed). Alternatives: (a) a new Phase 4c; (b) a separate design file.
        2. **Steering:** corridor shaping of the waypoint line before it is handed over, Citizens keeps walking it (proposed). Alternatives: (a) a K&K step controller now (per-tick steering); (b) ORCA or velocity obstacles.
        3. **`corridor-half-width`:** 4 blocks (proposed). Alternatives: (a) 3; (b) 6.
        4. **`wall-clearance`:** 0.8 block from the body's centre to a wall, on straights too where the road allows, which changes NAV-19's "straights may hug a wall" (proposed). Alternatives: (a) 0.6; (b) 1.0; (c) turns only, as today.
        5. **Squeeze limits:** `group-lateral-spacing-min` 0.75 and `group-spacing-min` 1.0 (proposed). Alternatives: (a) 0.8 and 1.25; (b) no squeeze.
        6. **Fold rule:** a column only where 2 abreast squeezed does not fit for longer than `group-width-hysteresis-blocks`; shorter places are passed by lanes merging (proposed). Alternatives: (a) fold at once, as today; (b) fold at once only at gate doors.
        7. **Stairs:** 2 abreast on flights wide enough where each lane has its own steps, else a column (proposed). Alternatives: (a) always a column (L4 decision 4); (b) also 3 abreast on wide flights.
        8. **`group-lookahead-blocks`:** the formation's depth plus 4 blocks (proposed). Alternatives: (a) a fixed 8; (b) a fixed 12.
        9. **Lanes and regions:** a lane needs the follower's access rules to allow it, not the same region set as the path (proposed). Alternatives: (a) keep the region equality; (b) ignore regions for lanes.
        10. **Turn order at a chokepoint:** in it, then the group's column order, a group before a single, then first come (proposed). Alternatives: (a) first come only; (b) singles before groups.
        11. **Bodies:** `collidable: false` stays the default (proposed). Which value does the dev server run? Alternatives: (a) `true`.
        12. **Plaza lines:** string pulling across plazas on the NPC side now, link M5 (proposed). Which plaza and route should the test use? Alternatives: (a) also through-edges in the road-graph builder later, for the players' trail; (b) only the builder change.
        13. **Flags:** one key per link, off by default, turned on by a later PR after your test (proposed). Alternatives: (a) one master key `movement-quality`.
        14. **Evidence:** a WorldEdit schematic of the stair house and its surroundings, with the commands in the comment on #603 (proposed). Alternatives: (a) synthetic scenes only; (b) a block-dump command in M1 instead.
        15. **Order:** M1 → M2 → M3 → M5 → M4 (proposed). Alternatives: (a) M3 before M2; (b) M4 before M3.
9. **Notes for later links.**
    1. M1: `/knk npc nav trace` gets `# corridor:` lines next to L5's `# waypoints:`; the fold-reason counters are counting only, no behaviour.
    2. M2: build the corridor where the stretch is prepared (NAV-14) and cache it per route stretch, so 50 singles on `quarry-to-keep` share it; keep `CornerClearance` and `WaypointChain` as safety nets after the shaped line.
    3. M3: `GroupPath.levels/widest/shift` and `NavGroup.decideWidth`/`firstMisfit`/`narrowLasts` are the places to change; L3's lane continuity (`continuous`) and L4's `LANE_RETURN`, door queue and step back stay.
    4. L6 (#593) and its access code are not touched by this design; M3's lane rule (access verdicts) must use whatever L6 settles for overlapping regions.
10. **Update 2026-11-15: developer answers and the steering research** (coordinator's message).
    1. Q1: a new Phase 4c. The design moved from Phase 7 into Phase 4c (4c.1–4c.6; the old 7.6 "carried over" list dropped), and Phase 7 is identical to `next`'s again. BEHAVIOR_MODEL references and the changelog line follow.
    2. Q2 (steering): research first. New report `docs/reports/2026-11-15-npc-movement-research.md` covers Minecraft's navigation, Citizens, Baritone, Recast/Detour, Unity and Unreal agents, Reynolds and context steering, RVO/ORCA, RTS flow fields and formations, grid techniques, and stuck handling, each mapped onto K&K. Options: (A) shape the line per stretch on a clearance map, Citizens walks it; (B) A plus short-horizon K&K steering every few ticks; (C) a K&K step controller every tick; add-on (D) a clearance-aware K&K search for local legs and recovery. The decision matrix (§ 5.1) gives A 39, B 38, C 29 of 45.
    3. Q3 and Q4 restated per option and on hold. New detail: `wall-clearance` is a preferred margin with a hard minimum of 0.35, because Recast-style hard erosion would close one-block doors.
    4. Heads: knk-workspace `claude/npc-followups-l8` at `2f86ce3` (`d21733f` restructure and report, then a merge of `origin/next` with L6 and siege weapons; changelog and plan header conflicts additive, both kept). L6's plugin change does not touch `GroupPath`, `NavGroup` or the steering code, so 4c.1 still holds. The PR description is updated, and `@codex review` was asked.
    5. Agent decisions: (a) *Option set.* Chosen: three options that all share the clearance map, plus D as an add-on, because the research shows the layers are separable. Alternatives: a flat list of techniques (harder to choose from); flow fields or ORCA as options (they fail K&K's many-goal routes and doorways, per the report § 3.7–3.8). (b) *Matrix reading.* Chosen: state that the matrix leans to A first, then B, and leave the choice to the developer, as the coordinator asked.
11. **Final (2026-11-15): all fifteen questions decided by the developer.** Q2 option A with add-on D (B at a checkpoint on the real-spot scenarios); Q3 corridor half width 4; Q4 wall clearance 0.8, hard minimum 0.35; Q5 squeeze 0.6 lateral and 1.0 rows; Q6 fold last; Q7 stairs as wide as the formation fits with a step per lane; Q8 look-ahead depth + 4; Q9 lanes by access rules; Q10 first come (authority and closed formations as future updates); Q11 collision off for now, on after M7; Q12 plaza lines NPC side now, builder through-edges later; Q13 one key per link; Q14 WorldEdit schematic; Q15 M1 → M2 → M6 → M3 → M5 → M4 → B checkpoint → M7. New links M6 (clearance-aware local legs) and M7 (push resistance; research report § 6). Plan 4c, BEHAVIOR_MODEL NAV-24–NAV-28 and the changelog say "decided 2026-11-15". Head knk-workspace `claude/npc-followups-l8` `e8836db0`, contains `next`; PR #605 description updated; the coordinator merges.

### 4.9 M1 — Evidence and diagnostics: schematic scenes (the developer's stair house), report-mode scenarios, fold reasons, corridor trace (#621)

1. **Scope done** (plan 4c.4 item 1 and 4c.5; no behaviour change, no new key, `npc.navigation.enabled` stays off by default).
    1. **Scene loader** (knk-paper `paper/scenario/SceneSchematic`). It reads WorldEdit's Sponge schematics (v3, v2) from `knk-paper/src/main/resources/scenario-scenes/` without WorldEdit and pastes them into a scenario box (air skipped, blocks outside the box counted). `worldMin()`, `origin()` and `local()` map real coordinates. I checked it against a file saved by WorldEdit 7.4.6 on the paper-boot server, which is now a test resource.
    2. **Scenes.**
        1. The developer attached `knk-stairhouse-schem.zip` to #603 at 20:20, while this link was under way. This session could not download it (the GitHub proxy allows only repository endpoints; the `user-attachments` URL returns 403), so I first built a stand-in from the plan.
        2. The coordinator then put the file on knk-plugin `evidence/stairhouse-schematic` `8438ce87`. The stair house now runs on the **developer's schematic** and the stand-in is removed.
        3. The file covers 1407 49 -549 to 1418 79 -487 (12 × 31 × 63), not the requested 1400 46 -515 to 1424 66 -482, and its copy origin lies outside it.
        4. It is pasted in the frame box = real − (1400, 46, −515) at box (7, 3, −34). The rows north of −515 and the blocks above y 69 are left out (8,501 blocks). It gets a stone floor at real y 48 under its footprint, because the copy starts at y 49, one block above the street's floor.
        5. The road line is hand-drawn on the walkable middle: the street → the entrance 1413 −508 (4 wide at feet height) → the straight at 1414 −503 (6 wide there) → the 3-wide passage 1411–1413 −502…−500 → two steps (−499, −495) → the hall at feet 51. It stops there; the upper flights are not walked yet.
        6. The jagged straight, the doorway (two 9 × 9 rooms) and the plaza (15 × 15, four 3-wide roads, a 2 × 2 well on the W→N chord) are synthetic by design. `tools/scenario-scenes/make_standins.py` writes them, with the same bytes on every run.
        7. `NpcMovementScene` holds the lines, starts, goals and watched areas, and `NpcMovementSceneTest` checks that each stands on its schematic's floor, the developer's included.
    3. **Scenarios.** `npc-stairhouse-singles`, `npc-stairhouse-group`, `npc-jagged-straight`, `npc-doorway-crowd` and `npc-plaza-line` run in report mode: one `KNK-NPC-REPORT` line per phase, then pass. Each is registered twice, with `collidable` off and on (`…-collision-on`), so there are 45 scenarios. `ScenarioNpcs` gained additive code: K&K's tick cost per NPC and the removal of singles.
    4. **Fold reasons** (decision 2.8, counting only). `NpcNavigationMetrics.FoldReason` has `stair`, `narrow`, `door`, `rules` and `edge`. The reason is judged at the first path point where the width given up fails (`GroupPath.misfitReason`: the lane try nearest to fitting names it; `NavGroup.foldReason`: a route gate door's box first). It appears in the log line ("… too narrow for 2 abreast (stair) at …"), in the groups line of `/knk npc nav stats` and in the metric `knk_npc_nav_group_width_reasons_total{change,reason}`.
    5. **Trace.** A `# corridor:` line follows each `# waypoints:` line: `x y z total left right` per waypoint (knk-core `npc/nav/corridor/FreeWidth`, an exact grid walk across the line to a body-stopping face or a drop, at most 4 a side).
    6. **CI** (`paper-boot.yml`). `MIN_SCENARIOS` 45, `--expect-timeout 1200`, job timeout 30 minutes (was 20), and a step that copies the report lines into the job summary. I chose to raise the timeouts instead of adding a second step. A whole local run takes 9.5 minutes, against 6 min 40 s for the 35 before. The ten runs walk 3,632 ticks (about 3 min).
    7. **knk-workspace.** Changelog, plan 4c.4 item 1.5 (status), plugin-scenarios.md § 1, § 3 item 7 and § 7, ci.md § 7 and § 7.1.
2. **Commits and heads.** knk-plugin `claude/npc-movement-m1` at `3ce748e0` (5 commits, base `next` `3c3d481e`, still the head of `next`). knk-workspace `claude/npc-movement-m1` at `1310c3d9` (3 commits plus a merge of `origin/next` `35454b3`, an unrelated siege PR, no conflicts; base `next` `61c29c16`).
3. **PRs.** PandiO/knk-plugin#47 (`Closes` #621) and PandiO/knk-workspace#632 (`Part of` #621), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `3c3d481e` was core 2816, api-client 344 (2 skipped), paper 2832 (18 skipped). Result: core 2830 (+14), api-client 344, paper 2851 (+19), 0 failures. New tests:
        1. `NavGroupFoldReasonsTest` 5
        2. `GroupPathTest` +4
        3. `FreeWidthTest` 5
        4. `SceneSchematicTest` 10
        5. `NpcMovementSceneTest` 5
        6. `NpcMovementReportTest` 3
        7. `NpcNavRunnerTest` +1, plus the corridor assertion
        8. `NavGroupWidthsTest` with the reason in the text
        9. `PaperScenariosTest` for 45
    2. Scenarios, run locally (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269): baseline on `next` 35/35. On the branch 45/45 with `--min-scenarios 45 --npc-navigation --expect-timeout 1200`, and the log check passed.
    3. CI on PandiO/knk-plugin#47: `build` and `paper-boot` green on both runs at `0cf7ea1a` (stand-in; runs 43758587514, 43758550071) and at `3ce748e0` (the developer's schematic; runs 43760374130, 43760369908), 45/45 each, log check passed, the report step wrote the summary; #586 did not hit.
    4. Known reds: none. Codex: at its usage limit on both PRs, also for the `@codex review` asked after the schematic push; said on both PRs, finished without it (developer decision 2026-11-14).
5. **Today's numbers, the baseline M2–M4 must improve on** (local run on `3ce748e0`, the stair house on the developer's schematic; collision off → on; "still" means standing in one block while it should walk; K&K nav is K&K's main-thread time per NPC per tick).
    1. `npc-stairhouse-singles` (12 both ways, street ↔ hall)
        1. Arrived 12/12 → 12/12.
        2. Trips: mean 8.3 s, longest 9.6 s → mean 9.3 s, longest 12.2 s.
        3. Stuck spells: 0 → 0.
        4. Longest still single: 0.5 s → 1.4 s.
        5. On the straight 1414 −503: 0.5 s → 0.5 s. In the entrance: 0.3 s → 0.4 s.
        6. Falls 0. K&K nav 0.19 → 0.014 ms (the first run's figure includes Citizens' start-up on few NPC ticks).
        7. The developer's 50 singles stuck at 1414 −503 do not show with 12 NPCs on this line.
    2. `npc-stairhouse-group` (20 in ranks of 3, street → hall, once)
        1. Leader arrived after 27.0 s → 27.0 s.
        2. Width changes: **1 fold, reason `stair`**, at box 12 2 15 (real 1412 −500, the foot of the first step). The group stayed a column from there: 0 narrows, 0 reforms.
        3. **Longest follower still in the entrance 1413 −508: 23.7 s → 23.5 s.** That is the developer's jam, reproduced: the column waits in the entrance while the front climbs the steps.
        4. Furthest behind its slot 0.8 → 0.6 blocks; lost 0; rejoins 0.
        5. Stuck spells 0 (waiting is not counted as stuck). K&K nav 0.003 → 0.002 ms.
    3. `npc-jagged-straight`
        1. 12 singles: arrived 12/12 → 12/12, mean 12.3 → 13.8 s, stuck spells 0 → 0, longest still 0.4 → 1.1 s.
        2. Group of 9 in ranks of 3: leader 17.3 s → 9.5 s.
        3. 0 folds, 0 narrows (3 abreast all the way) → the same.
        4. Group stuck spells: 3 (near a wall 2, 1 not freed) → 0.
        5. Lag 0.9 → 0.9; lost 0 → 0.
        6. K&K nav 0.005 → 0.005 ms.
    4. `npc-doorway-crowd` (6 + 6 through a one-block doorway)
        1. Arrived 11/12 (1 `Failed`) → 12/12.
        2. Longest still near the doorway: 11.7 s (box 11 1 6, the west room's corner by the door) → 2.3 s.
        3. Overlap in the doorway: 21 ticks, at most 4 at once → 44 ticks, at most 4. With collision on, bodies still share the doorway's cell while they pass.
        4. Stuck spells 2 (1 not freed) → 1.
        5. K&K nav 0.037 → 0.048 ms.
    5. `npc-plaza-line` (3 singles, west road to north road)
        1. Arrived 3/3 → 3/3.
        2. The walked length on the plaza is +40 to 41 % over the chord (14.6–14.8 against 10.4–10.5).
        3. Closest to the well: 2.50 blocks, because the line goes round through the centre and never comes near it. The same with collision on.
    6. Tick cost. K&K nav stays under 0.03 ms per NPC per tick, except in the crowded runs (the doorway: 0.037 and 0.048; the stair-house singles with collision on: 0.050). The figure includes the per-tick port calls to Citizens and spreads stretch preparation over few NPC ticks, so it reads higher than `/knk npc nav stats` on 50 NPCs. Read it as a trend, not the budget check.
6. **Decisions (DESIGN § 4.3).**
    1. *Reading schematics.* Chosen: a small Sponge v2/v3 reader of our own (gzip NBT, palette, varints), with Bukkit's `createBlockData` for the paste, so the loader runs in MockBukkit and unit tests without WorldEdit's platform. Alternatives: (a) WorldEdit's `ClipboardFormats` reader (needs the WorldEdit platform; MockBukkit can't test it); (b) only a block dump of our own (the developer would need a new command instead of `//schem save`).
    2. *Where the scenes live.* Chosen: `knk-paper/src/main/resources/scenario-scenes/`, because the scenarios ship in the main jar; the files are small (299–577 bytes each). Alternatives: (a) `src/test/resources` (not in the jar the server runs); (b) downloading them at run time (network in CI).
    3. *Stand-ins as schematics.* Chosen: the synthetic scenes are `.schem` files written by a Python generator, so the loader runs in every scenario and the developer's file drops in the same way. Alternatives: (a) Java scene builders as L5's `NpcLedgeScene` (the loader would go untested in Paper); (b) hand-edited files (not reviewable).
    4. *The developer's schematic: placement, floor and line.* Chosen: the same frame as the plan's coordinates (box = real − (1400, 46, −515)), with the rows outside the box dropped. A stone floor at y 48 under the footprint, since the copy starts at y 49. A hand-drawn line on the walkable middle from the street into the hall, checked point by point against the file. Alternatives: (a) ask for a new copy of the requested box (waits on the developer); (b) shift the file to fit more of the house (the plan's coordinates would no longer map); (c) the road graph's real line (needs the developer's trace or road data, which the scenario road does not have); (d) the upper flights too (needs more line through a multi-storey house; left for M2 with the developer's trace).
    5. *Collision variants.* Chosen: each scenario registered twice (`…-collision-on`), so both run in CI and fail or report separately. Alternatives: (a) a scenario option on `run` (CI runs `all` only); (b) both settings inside one scenario (twice the run time in one step, harder to read).
    6. *Report mode output.* Chosen: a `KNK-NPC-REPORT` line per phase in the server log, copied into the job summary, ignored by `check_scenarios.py`. Alternatives: (a) put the numbers in the PASS line (would change the `KNK-SCENARIO` contract); (b) a separate file artifact only (not visible at a glance).
    7. *Ranks width.* Chosen: `group-ranks-width` 3 in these scenarios, matching the plan's "20 in ranks of 3" and the developer's runs. The code default is 2. Alternatives: (a) the default 2 (folds nothing on the jagged straight, so it says nothing about 3 abreast).
    8. *Fold reason when several apply.* Chosen: a route gate door first, then a step on the path, then the lane try nearest to fitting (edge before rules before narrow), at the first point where the width given up fails. Alternatives: (a) count every reason at every misfit point (several per fold; sums no longer match the folds); (b) only the centre shift's lane (misses the shift that came nearest).
    9. *Free width.* Chosen: an exact grid walk across the line at feet and head height, stopping at a body-stopping face, a drop, or after 4 blocks. Alternatives: (a) sampling every 0.1 block (approximate, more reads); (b) the full corridor distance transform (that is M2's job).
    10. *Scenario time.* Chosen: raise `--expect-timeout` to 1200 and the job timeout to 30 minutes. Alternatives: (a) a second step for the collision-on runs (two server boots, about 1.5 minutes more).
7. **Out of scope, noted.**
    1. The trace's tick cost reads high in crowded scenarios because it includes Citizens port calls (see 5.6). This is for M2–M4 to watch; nothing was filed.
    2. A `citizens-stress-test.md` anchor that `IMPLEMENTATION_PLAN.md` links to does not resolve. It was there before this link and is left as it is.
8. **Blockers.** None. The schematic attachment could not be downloaded from a cloud session (403 from the GitHub proxy); the coordinator put the file on a knk-plugin branch and the scenarios now use it.
9. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. Optional: a `/knk npc nav trace` of an NPC walking from the street into the stair house's upper flights, so the next link can take the real road line and extend the scene up the flights.
10. **Notes for later links.**
    1. The stair-house scene (`NpcMovementScene.stairHouse`) is the developer's file, walked only to the hall at feet 51. M2 can extend `houseLine()` up the flights (the house goes up to about real 64; the box keeps up to real 69), and `NpcMovementSceneTest` checks the new points. The scene's starts are on the street north of the entrance (real −515 to −511, 1409–1418), the only open ground in the box.
    2. Turning a report into a check: replace the scenario's `check("report …", … return null)` with real checks, and keep the `KNK-NPC-REPORT` line so the numbers stay visible.
    3. `FreeWidth` is the first piece of the corridor (`core/npc/nav/corridor/`); M2 can replace or reuse it.
    4. `GroupPath.misfitReason` gives `edge` for lanes that fail only on `LANE_CLEARANCE`. When M3 merges lanes, a merge counts as a reason too (decision 2.8).

### 4.10 M2 — Corridor steering on a clearance map, option A (#622)

1. **Scope done** (plan 4c.4 item 2 and decision 1, option A; behind the new key `corridor-steering: false`, and `npc.navigation.enabled` stays off by default; with the key off nothing changes).
    1. **knk-core `corridor/Corridor`.**
        1. It covers the cells within `corridor-half-width` (4) of a stretch's waypoints. They are flooded from the line's own cells with floor continuity (a step of at most a block, the body's headroom) and must be in a region set one of the line's points has.
        2. Everything else inside the strip is an obstacle: walls, fences, posts, drops, cells two or more blocks above or below, other regions. Cells beyond the strip are not looked at.
        3. Clearance is the distance to the nearest obstacle's square, capped at 2: a capped Euclidean distance transform. It is judged from the floor of the point's own cell, so a staircase works. Each cell centre's value is kept once asked.
        4. A line that passes the same column on two levels gets a corridor per piece. The corridor reads the world only through `NavWorld` while it is built.
    2. **knk-core `corridor/CorridorShaper`.**
        1. The line is looked at every 0.5 block. Each point moves square to the line, on its own floor, to the place nearest the road line that keeps `wall-clearance` (0.8). The places allowed over ±2 blocks are intersected first, so an indentation doesn't pull the line into it and a jutting piece is seen before it is reached.
        2. Where the road is narrower than twice the clearance, a point goes to the place with the most clearance, its middle. One-block doors stay open (the hard minimum 0.35 is the key's lower bound).
        3. **Chokepoints.** A chokepoint is a place where the narrowest width through a point, over 12 directions, is under 2 blocks for at most 3 blocks, with wider road before and after it. It gets three pinned waypoints on its axis: 1.5 blocks before, in its middle (both across and along), and 1.5 after. That stretch is walked with waypoint margin 0.35.
        4. **String pulling.** From each anchor, the furthest point whose straight step stays in the corridor is taken. The step must also keep floor continuity, keep the body's corners in the corridor, and keep the least clearance of the points it passes (at most `wall-clearance`). The search gallops then halves, and every step taken is checked.
        5. The route's last point stays where it is.
        6. **Cache.** Shaped stretches are cached for 600 ticks, at most 512, keyed by the stretch's waypoints and the options. Every NPC whose stretch has the same waypoints shares one. Counters: `shaped`, `shared`, nanoseconds and reads.
    3. **Wiring.**
        1. `RouteFollower.next(world, blocks, floorY, cornerClearance, Steering)` shapes a stretch before corner clearance and the waypoint chain, which stay as the safety net (decision 4). The shaper starts from the road line's own position inside each waypoint's block, not the block centre.
        2. `Stretch.chokepoints` carries the count, and `Settings.marginFor` picks 0.35 when there is one.
        3. `NpcNavigationService` holds one shaper (`corridors()`).
        4. `NavigationSettings` gets `corridor-steering` (false), `corridor-half-width` (4, 1–8) and `wall-clearance` (0.8, 0.35–2), with `config.yml` comments and layer tests.
    4. **Groups keep today's line.** `NavGroupService` tells the service which movers are group members (`setUnshapedMembers`).
    5. **Scenarios.**
        1. The singles of `npc-stairhouse-singles` and `npc-jagged-straight` (collision off and on) run with the key on and check: all 12 arrive, 0 stuck spells, nobody still longer than 3 s, no fall, corridor steering really shaped, and its cost at most 0.03 ms per NPC per tick (`NpcMovementReport.singlesFailures`).
        2. The report lines gain `corridor shaped N, shared N, X ms per NPC per tick`.
        3. The jagged straight's group phase stays in report mode (M3). The scenario count stays 45.
    6. **knk-workspace.**
        1. Changelog entry with the YAML.
        2. Configuration reference § 4.27: the three keys, the `corner-clearance` and `waypoint-margin` texts, the YAML block and the § 2.1 row.
        3. Plan 4c.4 item 2.4: status, before/after and the developer test.
        4. `plugin-scenarios.md` § 7 and `ci.md` § 7.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m2` at `4e247835`: 4 commits on `next` `a527c980`, which is still the head of `next`.
    2. knk-workspace `claude/npc-movement-m2` at `a837776`: 1 docs commit on `next`, still its head.
3. **PRs.** PandiO/knk-plugin#48 (`Closes` #622) and PandiO/knk-workspace#633 (`Part of` #622), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `a527c980`: core 2830, api-client 344 (2 skipped), paper 2851 (18 skipped).
        2. Result: core 2853 (+23), api-client 344, paper 2852 (+1), 0 failures.
        3. New tests:
            1. `CorridorTest` 8: a 3-wide road, a jutting wall piece, a post, a one-block doorway, a drop, a step with a wall two up, another region, the strip's end.
            2. `CorridorShaperTest` 10: off a wall, the jagged straight straightened with the clearance, the chord on an open square (within 2 %), the doorway's three waypoints, a one-block passage through its middle, a ledge, a flight of stairs, the route's end, two levels, the cost (reads bounded per stretch; a second NPC reads nothing; rebuilt after the reuse time).
            3. `RouteFollowerCorridorTest` 5.
            4. `NpcNavigationConfigTest` +1.
    2. Scenarios, local (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269, `--min-scenarios 45 --npc-navigation --expect-timeout 1200`).
        1. Baseline on `next`: 45/45.
        2. On the branch, every movement check held in all four runs.
        3. The last local run failed only the cost check, then set at 0.01 ms: 0.0105 ms on the server's first, cold run, 0.004–0.005 ms warm. The bound is now the plan's 0.03 ms budget (decision 5.7).
    3. CI on PandiO/knk-plugin#48 at `4e247835`: `build` and `paper-boot` green on both runs (43765936833, 43765936845, 43766089003, 43766089025), 45/45 scenarios, log check passed; #586 did not hit.
    4. Known reds: none. Codex: at its usage limit on both PRs (said on both); finished without it.
5. **Before (M1's baseline, block 4.9 § 5, reproduced on `next` here) → after (key on); collision off → on.**
    1. `npc-stairhouse-singles` (12 both ways).
        1. Arrived: 12/12 → 12/12, both settings.
        2. Trips, mean and longest: 8.3 s and 9.6 s → 6.8 s and 7.6 s (off); 9.3 s and 12.2 s → 7.2 s and 8.1 s (on).
        3. Stuck spells: 0 → 0.
        4. Longest still single: 0.5 → 0.5 s (off); 1.4 → 0.6 s (on).
        5. On the straight 1414 −503: 0.5 → 0.4 s (off); 0.5 → 0.5 s (on).
        6. In the entrance: 0.3 → 0.3 s, both settings.
        7. Falls: 0.
        8. Corridor: 18 shaped, 6 shared; 0.0105 ms (first run) and 0.0051 ms per NPC per tick.
    2. `npc-jagged-straight`, singles.
        1. Arrived: 12/12 → 12/12.
        2. Trips, mean: 12.3 → 7.7 s (off); 13.8 → 8.0 s (on).
        3. Stuck spells: 0 → 0.
        4. Longest still: 0.4 → 0.3 s (off); 1.1 → 0.4 s (on).
        5. Corridor: 19 shaped, 17 shared; 0.0046 and 0.0042 ms per NPC per tick.
    3. `npc-jagged-straight`, group of 9 (not shaped, report mode).
        1. Collision on: exactly the baseline. Leader 9.5 s, 0 folds, 0 stuck spells.
        2. Collision off: leader 17.3 → 23.4 s, stuck spells 3 → 5, lost 0 → 1.
        3. The group's stretches are not shaped: the corridor counts don't rise in that phase. The singles before it are faster, so the group starts on a different tick, and this group was already unsteady at baseline (3 spells). M3 owns it.
    4. Whole K&K nav figure: stair house 0.094 / 0.041 → 0.114 / 0.054 ms; jagged 0.0078 / 0.0047 → 0.0121 / 0.0104 ms. That is the baseline's start-up noise plus the corridor's share, over shorter trips (fewer NPC ticks to spread the shaping over).
6. **Decisions (DESIGN § 4.3).**
    1. *Obstacles.* Chosen: a cell is an obstacle when a body can't reach it from the line with floor continuity, or its floor is more than a step from the point's floor. Full-block steps on the walk are floor, not walls. Alternatives: (a) `blocksBody` at feet height as the wall test (counts every full-block stair step as a wall, so lines on stairs would be pushed sideways); (b) faces only across the heading (misses jutting pieces between samples).
    2. *Regions.* Chosen: a cell must carry a region set that one of the line's points has, so the corridor is shareable between NPCs. Alternatives: (a) each NPC's access verdicts (a corridor per NPC, no sharing; M3's lane rule uses verdicts); (b) ignore regions (a line could move into a region the NPC may not enter).
    3. *Indentations.* Chosen: intersect the allowed places over ±2 blocks, then take the one nearest the road line. Alternatives: (a) the medial position everywhere (pulls the line into every notch on wide roads); (b) a moving average of offsets (softens the move a jutting piece needs).
    4. *Chokepoint width.* Chosen: the narrowest width through a point over 12 directions (a door taken diagonally is still one block wide), and the middle along the axis too. Alternatives: (a) the width square to the line (misses doors crossed at an angle; caught by the doorway test).
    5. *Margin.* Chosen: 0.35 for the whole stretch that has an aligned chokepoint, because the mover port has one margin per list. Alternatives: (a) a per-waypoint margin (a new port method, and Citizens has one margin per target list).
    6. *Groups.* Chosen: group members keep today's line until M3. Alternatives: (a) shape the leader too. In the first local run the collision-on group's leader took 26.3 s instead of 9.5 s and had 6 stuck spells, because the group path follows the raw route line.
    7. *Cost check.* Chosen: the corridor's own share at most the plan's 0.03 ms per NPC per tick. Alternatives: (a) 0.01 ms (failed at 0.0105 ms on a cold first run; would be flaky on CI); (b) the whole K&K figure under 0.03 (already above it on `next` in these short runs, M1 § 5.6).
    8. *Cache.* Chosen: 600 ticks, at most 512 stretches, keyed by the exact waypoints. Alternatives: (a) per route and stretch index (NPCs that start elsewhere have other stretch bounds); (b) no expiry (a door or a build changes the corridor).
    9. *Scenario variants.* Chosen: the two scenarios run with the key on in both collision variants (45 scenarios, no extra CI time); "before" numbers come from M1's baseline, reproduced locally. Alternatives: (a) four more key-off variants (about 1.5 minutes more CI).
7. **Out of scope, noted.**
    1. `/knk npc nav stats` has no corridor line yet (the counts are in `NpcNavigationService.corridors()` and the scenario reports). Nothing filed; a later link can add it with M3's or M4's stats.
    2. The collision-off group of 9 on the jagged straight is unsteady with or without this link (§ 5.3), and is M3's to check.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add `corridor-steering: false`, `corridor-half-width: 4`, `wall-clearance: 0.8` under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #622: `quarry-to-keep` with 50 singles and the key on.
10. **Notes for later links.**
    1. **M6 (local legs):**
        1. `Corridor.cellClearance(x, z)` is the clearance per cell.
        2. `clearanceAt(x, z[, cap])` gives it for any point.
        3. `floorAt(x, z)` gives the floor; `reach(x, z, dx, dz, max)` gives line of sight with floor continuity, to the exact face.
        4. A corridor for any line comes from `Corridor.build(world, feet, halfWidth)`. The shaped stretch's corridors are `ShapedLine.corridors()`; `corridorAt(feet)` finds the one under an NPC.
        5. The shared shaper is `NpcNavigationService.corridors()`.
    2. **M3 (formations):**
        1. `Corridor.freeWidth(feet, heading)` gives the free width across the path at any point (left, right, to the exact face).
        2. `ShapedLine.freeWidths()` has it per shaped waypoint.
        3. Group members are kept off the corridor by `NavGroupService` → `NpcNavigationService.setUnshapedMembers`. Remove that when the group path uses the corridor; then build the group path from the leader's shaped line.
    3. `FreeWidth.at` (M1's trace) still uses its own grid walk. `Corridor.freeWidth` gives the same answer inside a corridor.

### 4.11 M6 — Clearance-aware local legs and recovery, add-on D (#623)

1. **Scope done** (plan 4c.4 item 6 and decision 8, add-on D; behind the new key `local-legs-clearance: false`, and `npc.navigation.enabled` stays off by default; with the key off nothing changes but three new counters).
    1. **One place for every local leg.** Short trips, the hops to and from the road, a follower's own leg back (`NavGroup.rejoin` is a navigation order of its own) and the ladder's local leg all go through `NpcNavigationService.planHop`. Once the leg's capture and access are ready (`LocalLegPreparer`), K&K searches the leg itself when the key is on.
    2. **knk-core `corridor/LocalLegSearch`.**
        1. *Grid.* A `Corridor` round the straight line from the NPC to the hop, flooded from both ends with floor continuity. It is 6 blocks either side; a longer leg gets half its length plus 2, at most 12, so a turn round a corner fits. WorldGuard regions don't shape it: `Corridor.build(world, feet, halfWidth, anyRegion)` is a new, additive overload, and the leg's `CellAccess` decides where the NPC may go.
        2. *Search.* A* over the corridor cells: 8 directions, a diagonal only past two open flanking cells within a step, at most 2048 cells expanded. A cell is entered only when `LocalLeg.allows` it (the subject's gate, door and region verdicts, the captured box) and its centre keeps the body's half width (0.3; a one-block door keeps 0.5). Entering costs the length, the access's own extra cost, and 5 per block of clearance the cell lacks to `wall-clearance`.
        3. *Smoothing* (Theta*-style, on the result). From each anchor, take the furthest path cell whose straight step stays in the corridor with floor continuity (`Corridor.reach`), keeps L5's rule (`NavGeometry.straightWalkable`), passes only allowed cells (the body's corners too), and keeps the least clearance of the cells it replaces (at most `wall-clearance`; within 0.75 block of its ends, the end cell's own, so a leg can start beside a wall). The last waypoint is the hop's own point.
    3. **Wiring.**
        1. The mover walks a found leg as a waypoint list (`follow`, `waypoint-margin`).
        2. A watchdog watches progress along it every 20 ticks, because waypoint lists report no stuck (NAV-17). It opens a stuck spell after `no-progress-ticks`; while a recovery try runs, `supervise` judges it as before.
        3. The rule recheck reads the leg's waypoints instead of the engine's `pathAhead`.
        4. When K&K finds nothing, the engine's search walks the leg as before, with a log line `… local leg from … to …: K&K found no path (reason, cells), the engine searches`.
    4. **Counts.** Events `LOCAL_LEG_KNK`, `LOCAL_LEG_ENGINE` and `LOCAL_LEG_NONE` (an engine leg is counted `engine` once its search answered, `none` when it reported no path). `/knk npc nav stats` has `local legs: k&k N, engine N, none N`; `NpcNavigationService.localLegs()` has the search counters (searches, found, cells, nanoseconds, reads).
    5. **Key.** `local-legs-clearance` (false) in `NavigationSettings` with its `config.yml` comment; `NpcNavigationService.Settings` gains the component, and a 14-argument constructor keeps the old callers.
    6. **Scenarios** (no existing check lowered).
        1. `npc-stuck-ladder` runs with the key on. A new check: freed by the local leg, `LOCAL_LEG_KNK ≥ 1`, no engine leg, no `none`, no `recovery_no_path`. A new report line.
        2. `npc-stairhouse-singles` runs with the key on, collision off and on. A new check: no `none`, no `recovery_no_path`.
        3. Every movement report line gains `local legs k&k N, engine N, none N`. The scenario count stays 45.
    7. **knk-workspace.**
        1. The changelog entry with the YAML.
        2. Configuration reference § 4.27 and § 2.1 (the #622 row now says in `next`).
        3. Plan 4c.4 item 6.4: status, before → after and the developer test.
        4. `plugin-scenarios.md` § 2 item 3 and § 7, `ci.md` § 7.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m6` at `8fa83e09`: 3 commits on `next` `0fa74a67`, which is still the head of `next`.
    2. knk-workspace `claude/npc-movement-m6` at `f65d3c6`: 1 docs commit on `next` `8927eab`, still its head.
3. **PRs.** PandiO/knk-plugin#49 (`Closes` #623) and PandiO/knk-workspace#634 (`Part of` #623), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `0fa74a67`: core 2853, api-client 344 (2 skipped), paper 2852 (18 skipped).
        2. Result: core 2866 (+13), api-client 344, paper 2853 (+1), 0 failures.
        3. New tests:
            1. `LocalLegSearchTest` 7: the margin past a jagged wall, a one-block door, floor continuity round a ledge corner, a step up and down, a denied region (no leg into it, a detour round a denied patch), the leg's box, the cell budget and the reads.
            2. `NpcNavigationLocalLegsTest` 6: key off is the engine's; key on walks K&K's waypoints round a post; the fallback and `none`; `engine` counted once; the watchdog opens a spell without progress, and none with progress.
            3. `NpcNavigationConfigTest` +1: the key in every layer.
    2. Scenarios, local (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269, `--min-scenarios 45 --npc-navigation`).
        1. Baseline on `next`: 45/45.
        2. Branch: 45/45 on two runs.
        3. A key-off run of the same build (the two scenarios' key set to false locally, not committed) failed only the new `npc-stuck-ladder` check, with `engine 1`. The check tells the two apart.
    3. CI on PandiO/knk-plugin#49: `build` and `paper-boot` green on the PR head `8fa83e09` (runs 43771719471, 43771719446; 45/45 scenarios, log check passed), and on the earlier push of `claude/npc-movement-m6` (43769751783, 43769751784); #586 did not hit.
    4. Known reds: none. Codex: at its usage limit on both PRs (said on both); finished without it.
5. **Before (key off) → after (key on)**, the same build, local runs; collision off / on where the scenario has both.
    1. `npc-stuck-ladder` (no collision variant).
        1. Freed: by the local leg both times (back-off 0, side-step 0, local leg 1, replan 0, not freed 0); 2 steps per spell.
        2. The ladder's local leg: `engine 1` → `k&k 1, engine 0, none 0`.
        3. `recovery_no_path`: 0 → 0.
        4. K&K's search: 1 search, found, 3 cells expanded, 6.6 ms (the first search in the server, JIT included).
    2. `npc-stairhouse-singles` (12 both ways).
        1. Local legs: `engine 4` → `k&k 4, engine 0, none 0`, both settings.
        2. `recovery_no_path`: 0 → 0. Stuck spells: 0 → 0.
        3. Arrived: 12/12 → 12/12.
        4. Trips, mean and longest: 6.8 s and 7.6 s → 6.8 s and 7.3 s (off); 7.2 s and 8.1 s → 7.2 s and 8.1 s (on).
        5. Longest still single: 0.5 → 0.4 s (off); 0.6 → 0.8 s (on). The check allows 3 s.
        6. Whole K&K nav figure: 0.158 / 0.075 → 0.027 / 0.014 ms per NPC per tick. This is mostly start-up noise of the first runs in a server, not this link.
    3. Unchanged elsewhere (key off): `npc-doorway-crowd` gives exactly the baseline's numbers in every run, including its one failed trip with collision off (11/12, report mode, M4's). It walks 17 / 13 engine legs, a place where the key could be tried later.
6. **Decisions (DESIGN § 4.3).**
    1. *The walk grid.* Chosen: the leg's `Corridor` cells, the NPC's walk grid on the `NavWorld` port, with the same floor rules as M2 and L5. The leg's `CellAccess` is the same verdict object `WalkSearch` reads. Alternatives: (a) `core/roads/walk/WalkSearch` on the walk capture's `WalkTerrain` with a clearance `CellAccess`. That needs the terrain carried in `LocalLeg` and a second world model next to `NavWorld`, and the scenarios' leg preparer (`ScenarioNpcs`) has no capture, so the scenarios couldn't run it. (b) A new grid of its own (duplicates the corridor's distance transform). The plan names `WalkPathfinder`; this is for the developer to confirm.
    2. *Where it runs.* Chosen: the main thread, when the prepared leg is handed over, bounded by the cell budget (2048). Alternatives: (a) the walk executor (needs the corridor's world reads taken on the main thread first; more moving parts); (b) no budget (an unreachable target would search the whole corridor).
    3. *Corridor width.* Chosen: 6 either side, half the leg's length plus 2 for longer legs, at most 12. At a fixed 6, an L-shaped leg round a corner failed in a test. Alternatives: (a) `corridor-half-width` (4, too narrow for a detour); (b) the whole capture box (more reads for every leg).
    4. *Regions.* Chosen: the corridor ignores regions (`anyRegion`) and the leg's access decides. Alternatives: (a) M2's rule, a region set one of the line's ends has, which would block legs that cross a third region the NPC may enter.
    5. *Clearance cost.* Chosen: 5 per block lacking to `wall-clearance`, so only cells right beside a wall cost more (+1.5 at 0.8), and a leg moves a block off a wall where there is room. Alternatives: (a) WalkSearch's flat `wallCost` (ignores how close); (b) a hard `wall-clearance` minimum (closes 1-wide doors and 2-wide passages).
    6. *Drops.* Chosen: none; a step is at most one block up or down (L5's floor continuity). Alternatives: (a) drops of 2–3 blocks like player navigation (L5 keeps NPCs on their floor).
    7. *Counting `none`.* Chosen: an engine leg counts `none` when the engine reports no path, else `engine` once it arrived, got stuck otherwise or the order moved on. Alternatives: (a) count `engine` at hand-over and `none` as a subset (the three would not add up to the legs).
    8. *Watchdog.* Chosen: progress means the leg's remaining length (nearest point, then along it) shrinks by 0.5 block between looks; after `no-progress-ticks` without, a spell opens like on the line. Alternatives: (a) distance to the hop only (a detour round a wall looks like no progress).
    9. *Scenario variants.* Chosen: the two named scenarios turn the key on in place; the "before" numbers come from a local key-off run of the same build. Alternatives: (a) key-off variants in CI (more CI time, the job is near its timeout).
7. **Out of scope, noted.**
    1. `npc-doorway-crowd` walks 13–17 engine legs with the key off; trying the key there belongs to M4 (crowding), whose scenario it is.
    2. The group of 9 on the jagged straight with collision off is still unsteady (5 stuck spells, 1 lost, as in M2's runs); it walks no local legs, so it is M3's (as M2 noted).
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add `local-legs-clearance: false` under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #623 (comment 6902738383): `quarry-to-keep` with 50 singles and a group of 20, with the key on.
    3. Confirm decision 6.1 (the corridor grid instead of `WalkSearch`), or ask for alternative (a).
10. **Notes for later links.**
    1. **M3 (formations):** the corridor API is unchanged apart from the additive `Corridor.build(…, anyRegion)`. Group members still walk the unshaped line; a follower's own leg back is a K&K leg when the key is on.
    2. **M4 (crowding):** `LocalLegSearch.Grid.extra` is where an occupancy cost per cell would go; the leg avoids a cell when its access cost rises.
    3. **M7 (collision):** a pushed NPC's walk back can use `LocalLegSearch` directly (it needs only `NavWorld`, a `LocalLeg` and `wall-clearance`).

### 4.12 M3 — Formation keeping: elastic widths, squeeze, look-ahead, fold last (#624)

1. **Scope done** (plan 4c.4 item 3 and decision 2, with the developer's values of 2026-11-15; behind the new key `group-formation-keeping: levels|elastic`, default `levels`; `npc.navigation.enabled` stays off by default; with `levels` nothing changes but a `merges 0` in the stats line).
    1. **Fit** (knk-core `GroupPath.fit`): per group path point, the free width left and right across the path, to the exact face of a wall, a drop, a cell of another step height on a flight, or a region the group's access rules deny, at most 4 a side; looked up once per point. A width fits where its lanes at `group-lateral-spacing-min` plus 0.35 each side fit.
    2. **Squeeze:** neighbours as far apart as the road allows, from `group-lateral-spacing` down to `group-lateral-spacing-min` (0.6); the formation's centre off the path's centre where that keeps the outer lanes `wall-clearance` (0.8) from the faces, never under 0.35. Rows close up from `group-spacing` towards `group-spacing-min` (1.0) in quarter steps while the stretch squeezes; a column walks at the closed-up gap.
    3. **Decision** (`NavGroup.decideElastic`): over the stretch from the rearmost slot to the formation's depth plus `group-lookahead-blocks` (4) ahead of the leader. A width is given up only for a tight place longer than `group-width-hysteresis-blocks` (measured half way to the neighbouring points), for the widest width without one, the column last; a wider width when the stretch has none for it. Same rule for the column (L8 finding 1 fixed).
    4. **Merges:** a shorter tight place is passed with the lanes kept inside the free width (hard margin); logged (`merges its lanes for N blocks: … (reason) at …`) and counted once as the new event `GROUP_MERGE` with its reason (`WIDTH_CHANGES` now has fold, narrow, merge; metric label `merge`; the groups stats line `merges N (reasons)`; the scenario reports `merges`).
    5. **Lanes:** each lane keeps within the bands of the points a path step behind to `LANE_RETURN` ahead, the preferred margin first, then the hard one.
    6. **Stairs:** no rule of their own; on a flight only cells at the path's step height count (reason `stair` when a lane has no step of its own).
    7. **Rules:** a lane cell in other regions is allowed when the group's cached verdicts (the leader's subject) let it enter; the fits are forgotten on a rule change.
    8. **Re-assignment** (`NavGroup.reassign`): on every width change, followers by place (foremost first, each row by side) to the new width's slots sorted by back then side (L8 finding 2 fixed).
    9. **Group path on the corridor** (decision 1.5; M2's note 10.2.3): each route point goes onto the line the shared `CorridorShaper` gives for its chunk of 20 points (one path point per route point kept, so the leader's index mapping is unchanged). The leader keeps the unshaped route (`setUnshapedMembers` unchanged).
    10. **Keys:** `group-formation-keeping`, `group-lateral-spacing-min`, `group-spacing-min`, `group-lookahead-blocks` in `NavigationSettings` (`GroupSettings.Keeping`) with `config.yml` comments and the layer test.
    11. **Scenarios:** `npc-stairhouse-group` (corridor and local-leg keys on too) and the group phase of `npc-jagged-straight` run elastic and check item 3.3 (`NpcMovementReport.groupFailures`: leader arrived, folds at most the 1-wide places measured with M1's `FreeWidth`, no spell open or not freed, none near a wall; failures list the spell lines); the stair house also checks 4c.5 item 3 (no follower still in the entrance over 10 s). `npc-group-narrows` runs elastic with its expectations moved to the squeeze. Scenario count stays 45.
    12. **knk-workspace:** changelog with the YAML, configuration reference § 4.27 and § 2.1, plan 4c.4 item 3.4 (status, before → after, developer test).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m3` at `94b30146`: 5 commits on `next` `625c2c9c`, still the head of `next`.
    2. knk-workspace `claude/npc-movement-m3` at `1b4692ed`: 2 docs commits on `next` `e0783664`, still its head.
3. **PRs.** PandiO/knk-plugin#50 (`Closes` #624, `Part of` #522, #493) and PandiO/knk-workspace#635 (`Part of` #624, #522, #493), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `625c2c9c` core 2866, api-client 344 (2 skipped), paper 2853 (18 skipped); result core 2880 (+14), api-client 344, paper 2854 (+1), 0 failures. New: `NavGroupElasticTest` 14 (every case of item 3.2, the rows closing up, the column 0.8 off a wall, reads per point bounded and none on a second look), `NpcNavigationConfigTest` +1. Changed: `NpcNavRunnerTest` (merges), `GroupSim` (walls and floor heights).
    2. Scenarios, local (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269, `--scenarios --npc-navigation --min-scenarios 45`): baseline on `next` 45/45, the log check failed only on #586 (a player scenario's API error); branch 45/45, log check passed; the converted `npc-group-narrows` passed again alone.
    3. CI on PandiO/knk-plugin#50: `build` green on both runs (43781096479, 43781152888); `paper-boot` green on run 43781152887 (45/45, log check passed). Run 43781096517 passed 45/45 but its log check hit #586 (a player scenario's API error, also on my local baseline on `next`); its one re-run (job 133021397522) went green. Said on the PR.
    4. Known reds: none. Codex: at its usage limit on both PRs (said on both); finished without it.
5. **Before (`next`, `levels`; M1's baseline reproduced) → after (`elastic`); collision off / on.**
    1. `npc-stairhouse-group` (20 in ranks of 3):
        1. Folds 1 (`stair`, box 12 2 15, real 1412 -500) → 0; the line has 0 1-wide places; 3 abreast all the way, 0 narrows, 0 merges.
        2. Leader 27.0 / 27.0 s → 7.5 / 8.0 s.
        3. Longest follower still in the entrance 1413 -508: 23.7 / 23.5 s → 0.4 / 0.4 s.
        4. Furthest behind its slot 0.8 / 0.6 → 1.0 / 0.9 blocks; lost 0; stuck spells 0 → 0.
        5. Intermediate run (elastic, group path on the raw line): collision off 3 spells not freed, 1 lost; fixed by the shaped group path and the band smoothing.
    2. `npc-jagged-straight`, group of 9:
        1. Collision off: leader 23.4 → 9.7 s; stuck spells 5 (2 near a wall, 3 not freed, 1 left behind) → 0; lost 1 → 0. This is M2's and M6's unsteady group: elastic alone did not change it (identical numbers on the raw line); the cause was a follower crossing a notch's wall corner (a lane pulled into a one-sided notch for one point) and the last follower short of a slot measured along the wobbling skeleton line.
        2. Collision on: 9.5 → 9.8 s, 0 → 0 spells.
        3. 0 folds both ways, before and after.
    3. K&K nav figure in these runs 0.01–0.03 ms per NPC per tick (start-up included, M1 § 5.6); the group's fits are cached per path point.
6. **Decisions (DESIGN § 4.3).**
    1. *Fit source.* Chosen: a lateral grid walk per group path point (floor continuity, stairs at the path's step, access verdicts), cached per point. Alternatives: (a) M2's `Corridor.freeWidth` (needs a corridor per group stretch with the regions of the line, not the group's verdicts; decision 2.6 asks for verdicts); (b) M1's `FreeWidth` (no regions, no step rule).
    2. *`group-lookahead-blocks`.* Chosen: the key is the 4 blocks past the formation's depth (the decided "depth + 4"), default 4, 0–32. Alternatives: (a) the whole distance as one number (depends on group size).
    3. *Merges.* Chosen: lanes clamped into the free width with the hard margin, no change of the slots' distance along the path. Alternatives: (a) a zipper with an along offset per merged lane (more state per follower; with collision on, bodies in one row converge for the length of the tight place: reported for M4/M7).
    4. *Tight place length.* Chosen: half way to the points before and after it, so a 1-block place is about 1.5 blocks and a 4-block gate about 4.5. Alternatives: (a) first to last point (a 1-point place has length 0, a 4-block gate 3: not over the hysteresis 3).
    5. *Row squeeze.* Chosen: the gap follows the lateral squeeze over the stretch, in quarter steps; the column at `group-spacing-min`. Alternatives: (a) rows only at the squeeze's end (abrupt); (b) the column at `group-spacing` (a longer column through 1-wide places).
    6. *Reason mapping.* Chosen: door (gate box) first, then the fit's nearer side: step → `stair`, region → `rules`, drop → `edge`, wall or unloaded → `narrow`. Alternatives: (a) keep L4's `misfitReason` (judges lane points, not the fit).
    7. *Group path shaping.* Chosen: route points moved onto the shared shaper's line per chunk of 20, one path point per route point; the leader still walks the unshaped route. Alternatives: (a) shape the leader too (M2's first run: slower with collision on); (b) rebuild the path from the shaped stretch the leader walks (breaks the leader-to-path index mapping); (c) no shaping (the jagged group kept its stuck spells).
    8. *Access subject for lanes.* Chosen: the leader's name with the group's profile (members share a profile). Alternatives: (a) per follower (a fit per follower, no shared cache).
    9. *npc-group-narrows.* Chosen: converted to elastic in place; L4's fixed widths stay covered by `NavGroupWidthsTest`. Alternatives: (a) an elastic copy (46 scenarios, more CI time near the 30-minute timeout).
    10. *Stair-house entrance check.* Chosen: asserted now (0.4 s against 10 s). Alternatives: (a) leave it to M4 (plan 4c.4 item 4.3).
7. **Out of scope, noted.**
    1. With collision on, a merge brings a row's bodies into the same cell for the length of the tight place; M4 (turn-taking) or M7 (collision) should look at it. Not filed.
    2. The scene's stair-house line has no 1-wide place, so the scenarios show no fold at all; a fold at a 1-wide place is covered by the knk-core gate test and `npc-group-narrows`. The developer's run on `quarry-to-keep` checks the real route's narrow places.
    3. `plugin-scenarios.md` § 7 and `ci.md` § 7 (which scenarios run elastic): left for the docs session.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add `group-formation-keeping: levels`, `group-lateral-spacing-min: 0.6`, `group-spacing-min: 1.0`, `group-lookahead-blocks: 4` under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #624 (comment 6904056605): `quarry-to-keep` and `south-gate-short` with a group of 20 in ranks and the key on.
10. **Notes for later links.**
    1. **M4 (crowding):** the entrance jam is gone in the scenarios with formation keeping alone (0.4 s), so there is nothing left of it for M4 to fix on this scene. Turn-taking at real chokepoints and merges under collision remain.
    2. **M5 (plazas):** the group path uses `CorridorShaper` per chunk (`NavGroup.shapedLinePoint`); plaza widening of the corridor will reach groups through it.
    3. `GroupPath.fit` and `NavGroup.elasticWidest` are the per-point cache; `forgetFits()` on rule changes.

### 4.13 M5 — Plaza lines: string pulling across plaza junctions, NPC side (#625)

1. **Scope done** (plan 4c.4 item 5, decision 6, NAV-27; behind the new key `plaza-lines: false`, with `npc.navigation.enabled` still off by default; nothing changes with the key off; the road-graph builder is untouched, 4c.7 stays a future update).
    1. **Which junctions.** The road plan names every junction a route passes (`RoadPlanner.PlazaCrossing`; knk-paper `NavigationService.plazaCrossingsOf`): a designed plaza's centre with its `PlazaRadius`, every other junction with radius 0. The stored network doesn't mark automatic plazas, so the NPC side measures each junction with 16 rays over standable floor in its regions and takes the fourth shortest as the open radius. A junction no wider than `corridor-half-width` is a street junction and is left alone (under 800 reads, no corridor). A plaza's footprint is the open radius less `wall-clearance` (a designed plaza's radius as given), at most `plaza-corridor-blocks` (16).
    2. **The line** (knk-core `corridor/PlazaLine`). The stretch's corridor also covers the footprint (`Corridor.build(…, discs)`, additive). From where the route enters the footprint to where it leaves (never past a pinned chokepoint waypoint) it runs a bounded A* on M2's clearance map: 8 directions, never under 0.35, 10 per block lacking to the clearance, at most 4,096 cells. The A* path is string pulled by line of sight and its bends are slid to the tangent points. A step keeps the least clearance of the cells it replaces, less only near an end that has less itself. Regions the route doesn't pass are obstacles (M2's rule). The plaza points are pinned, and their line indexes are the entry's or the exit's, so the corner clearance at the junction's turn leaves them alone.
    3. **Stretches.** A stretch that would end on a plaza holds the way across it, at most one stretch more (a street grid must not chain). Group chunks likewise, at most a chunk more either way.
    4. **Singles.** The plaza line is part of the shaped stretch with `corridor-steering`; without it only the plaza part changes (`Options.plazaOnly`), the rest stays at the block centres.
    5. **Groups.** The group path takes the plaza line per chunk (`elastic`: the full shape; `levels`: the plaza only), and the leader's stretches get it too (plaza only, since the leader's line is otherwise unshaped). Both keep the formation's half width plus `wall-clearance` (`NavGroup.plazaClearance`, 1.8 for 3 abreast at 1.0) through `NpcNavigationService.setPlazaClearance` and `plazaOptions(leaderId)`.
    6. **Keys:** `plaza-lines` (false) and `plaza-corridor-blocks` (16, 4–32) in `NavigationSettings` and `NpcNavigationService.Settings` (a 15-argument constructor keeps the old callers), with `config.yml` comments and the layer test.
    7. **Scenario** `npc-plaza-line` (collision off and on) turns the key on and asserts. Singles: all arrive, walked within 5 % of the shortest line that keeps `wall-clearance` from the well, well ≥ 0.55, at least 2 from the junction, a plaza line placed. A new group phase (7 in ranks of 3, `elastic`): the leader arrives within 10 % of the line round the well with the group's clearance and at least 1 from the junction, no member under 0.35 from the well, M3's group checks with 0 folds, shaping in the phase ≤ 0.03 ms per NPC per tick. The scenario count stays 45.
    8. **knk-workspace:** changelog with the YAML, configuration reference § 4.27 and § 2.1, plan 4c.4 item 5.4.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m5` at `727f020b`: 8 commits on `next` `138ebc66`, still the head of `next`.
    2. knk-workspace `claude/npc-movement-m5` at `f5aa56e`: 3 docs commits on `next` `a428eb3`, still its head.
3. **PRs.** PandiO/knk-plugin#51 (`Closes` #625) and PandiO/knk-workspace#637 (`Part of` #625), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `138ebc66`: core 2880, api-client 344 (2 skipped), paper 2854 (18 skipped).
        2. Result: core 2899 (+19), api-client 344, paper 2859 (+5), 0 failures.
        3. New tests:
            1. `PlazaLineTest` 10: the scenario plaza's chord within 5 % (+1.9 %; M2 alone +39.6 %); straight through the junction when it is on the chord; a well on the chord passed at 0.75; a group's line 1.8 off it; a region the line doesn't pass kept out of; a designed radius; a narrow-street junction is no plaza; plaza-only mode; the cost (about 3,700 reads per plaza stretch, 38 cells, a second NPC reads nothing); the open radius.
            2. `RouteFollowerPlazaTest` 5.
            3. `NavGroupPlazaTest` 4.
            4. `PlazaGeometryTest` 3.
            5. `NpcNavigationConfigTest` +1, `NpcRoadPlanningTest` +1.
    2. Scenarios, local (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269, `--scenarios --npc-navigation --min-scenarios 45 --expect-timeout 1200`).
        1. Baseline on `next` 45/45.
        2. Branch head `727f020b`: 45/45, log check passed.
        3. An earlier branch run failed `npc-corners-walk`, three times in a row, with my settle-tolerance fix for #636 in. With it reverted the scenario passes (decision 5.8).
    3. CI on PandiO/knk-plugin#51 at `727f020b`: `build` and `paper-boot` green on the push run (43792722765, 43792722751) and the PR run (43793671677, 43793671690), 45/45 scenarios, log check passed; #586 did not hit. Codex: at its usage limit on both PRs (said on both); finished without it.
    4. Known reds: none.
5. **Before (`next`, M1's baseline reproduced) → after (key on); collision off / on.**
    1. `npc-plaza-line`, 3 singles from the west road to the north road.
        1. Walked on the plaza: +40–41 % over the chord (14.6–14.8 against 10.4–10.5), through the junction (0.0–0.1) → +4 % over the shortest line keeping 0.8 from the well and +11 % over the chord (the well stands on the chord), 2.7–2.8 from the junction.
        2. Well: 2.50 → 0.73–0.75 / 0.64–0.75.
        3. A key-off run of the same build fails the new singles checks.
    2. The group of 7 in ranks of 3 (new phase).
        1. Key off: the leader walks the V (+21 % over its line round the well, through the junction).
        2. Key on: +6 %, 1.5 from the junction, 0 folds, 3 abreast; closest member to the well 0.58 / 0.55.
        3. The leader stands at the goal after about 7 s either way. The group's result comes after 7.7 s (key off), 26.4 s (key on, collision off, #636) and 7.0 s (collision on).
    3. Cost. Corridor shaping in the group phase 0.0016–0.0076 ms per NPC per tick. The singles' phase is the server's first plaza shaping: 0.024–0.029 on a fresh server, reported. A plaza stretch takes about 1.3 ms to shape once (M2's plain stretch 0.65 ms) and is shared; amortised over a stretch's walk that is about 0.008 ms per NPC per tick.
6. **Decisions (DESIGN § 4.3).**
    1. *Automatic plazas.* Chosen: every junction on the route is a candidate, measured by 16 rays on the NPC side (the fourth shortest ray). Alternatives: (a) designed plazas only (the developer's plazas are probably automatic); (b) the builder's plaza flag in the API (schema change); (c) a `NavWorld` method for the road floor material, to bound the footprint by road blocks (new port method). Caveat: a junction in open ground without walls measures as a plaza, and the NPC may cut its corner over the grass within 16 blocks.
    2. *The search.* Chosen: A*, line-of-sight pulling and bend refinement on M2's clearance map. Alternatives: (a) M2's string pull in a wider corridor (jumps only between line points: +21 % round the well in the first try); (b) full Theta* (a line-of-sight check per expansion).
    3. *Scenario reference.* Chosen: within 5 % of the shortest line that keeps `wall-clearance` from the well, the plain chord % reported. Alternatives: (a) 5 % of the chord (impossible with M1's well on the chord); (b) move the well (M1's scene is the baseline).
    4. *Groups' clearance.* Chosen: the formation's half width plus `wall-clearance`, at most 2 (the corridor's cap). Alternatives: (a) `wall-clearance` only (the outer lanes squeeze or merge at the well).
    5. *Without corridor steering.* Chosen: plaza lines work alone (plaza-only mode). Alternatives: (a) only with `corridor-steering`.
    6. *Cost check.* Chosen: the group phase's share ≤ 0.03; the singles' phase reported. Alternatives: (a) the whole run (0.024–0.029 cold, flaky against 0.03).
    7. *Footprint edge.* Chosen: open radius less `wall-clearance`. Alternatives: (a) the full radius (the entry point lay in the road's opening in the plaza wall).
    8. *The settle bug.* Chosen: filed as #636 and left as it is on `next`. Alternatives: (a) a shared settle tolerance (fixed the 20 s wait but made `npc-corners-walk` fail: the patrolling group turns round sooner and a follower stands 4 s at the stair corner).
7. **Out of scope, noted.**
    1. #636 (filed): a follower 0.1–0.2 short of its slot never settles; the group reports arrival after its 20 s settle time.
    2. `plugin-scenarios.md` § 7 and `ci.md` § 7: `npc-plaza-line` now asserts and has a group phase. Left for the docs session.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add `plaza-lines: false` and `plaza-corridor-blocks: 16` under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #625 (comment 6905814391): name a plaza and a route across it, then trace one NPC with `/knk npc nav trace 60` and walk a group of 9 across.
10. **Notes for later links.**
    1. **M4 (crowding):** `PlazaLine.search` is a small A* over corridor cells. An occupancy cost per cell would go into its cell cost (next to `CLEARANCE_COST`) if crowds should spread over a plaza.
    2. **#636** needs `npc-corners-walk` looked at together with the fix (the turnaround right after arriving).
    3. In production every junction on a route is measured once per stretch shaping (rays, cached with the stretch). Watch `corridors().reads()` on a dense street grid.

### 4.14 M4 — Crowd awareness: narrow places taken in turns, yielding, waiting is not stuck (#626)

1. **Scope done** (plan 4c.4 item 4, decision 3, NAV-26; behind the new key `crowd-awareness: false`, with `npc.navigation.enabled` still off by default; with the key off no hash is built and no NPC is held; authority values and closed formations first (4c.7) are not built, only the hook `CrowdControl.earlier`).
    1. **Occupancy** (knk-core `crowd/Occupancy`). Every 5 ticks the service hashes the feet cell of every spawned registered NPC in one pass, group followers included; lookups are O(1). It counts shared cells, the most NPCs in one cell, and the closest two bodies in one cell.
    2. **Narrow places and turns** (knk-core `crowd/CrowdControl`). A run on the NPC's way ahead, 6 blocks looked at, where M1's `FreeWidth` is under 2 blocks.
        1. The way ahead is its route line, its K&K leg or the engine's `pathAhead`. The doorway scene's trips are all short local legs.
        2. NPCs that see the same cells share one place. Its axis is the first way through it.
        3. The NPC arrives at 4 blocks. One direction at a time: an NPC already in the place first, then first come across both directions. Same direction: FIFO, and the one ahead is a block in first.
        4. The others are held: stopped and sent to a queue spot 1.5 blocks before the place plus a block per NPC ahead, a block to the right where the floor allows, further back while the way is still narrow.
        5. A turn ends 0.5 past the place. A leader keeps its turn until its followers are through. A queue lets go after 30 s.
        6. The free-width cache per cell and heading is cleared every 10 s and on a gate change.
    3. **Oncoming.** An NPC in a place without a turn, while one of the other direction entered first, steps back out to its queue spot (`yield`).
    4. **Waiting is not stuck.** A held NPC is in state WAITING and the watchdog does not watch it. A single or follower behind another NPC within 1.5 blocks counts a wait instead of a stuck spell; an engine leg is walked again after 20 ticks. After 30 s behind the same jam it is stuck after all.
    5. **Recovery.** Back-off, side-step and local-leg targets skip occupied cells, for singles and followers. `LocalLegSearch.Grid.extra` costs an occupied cell 4 and the smoothing does not cut through it (M6's note).
    6. **Stats and metrics.** `crowd: waits N, yields N, longest queue N` in `/knk npc nav stats`; `crowd_wait` and `crowd_yield` in the metrics.
    7. **Scenarios.** `npc-doorway-crowd` runs with `crowd-awareness` and `local-legs-clearance` on and asserts:
        1. all arrive;
        2. 0 stuck spells;
        3. at most 3 s of wait per NPC that went first;
        4. none let go after 30 s;
        5. nobody still over 3 s outside a queue.

        `npc-stairhouse-group` adds the key and the crowd checks. Both report the crowd numbers, the shared cells and the crowd's cost. `ScenarioNpcs`' longest still leaves out crowd-held NPCs.
    8. **knk-workspace:** changelog, configuration reference § 4.27 and § 2.1, plan 4c.4 item 4.4 (status, tests, before → after, developer test) and the 4c.4 developer test steps 1 and 5.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m4` at `8c864f7a`: 4 commits on `next` `3f116188`, still the head of `next`.
    2. knk-workspace `claude/npc-movement-m4` at `9f09cf2`: 1 commit on `next` `f9be496`, still the head.
3. **PRs.** PandiO/knk-plugin#52 (`Closes` #626) and PandiO/knk-workspace#638 (`Part of` #626), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`: core 2899 → 2921 (+22), api-client 344 → 344 (2 skipped), paper 2859 → 2860 (+1, 18 skipped), 0 failures. New tests:
        1. `CrowdControlTest` 12
        2. `NpcNavigationCrowdTest` 6
        3. `NavGroupCrowdTest` 3
        4. `LocalLegSearchTest` +1
        5. `NpcNavigationConfigTest` +1
    2. Scenarios, run locally (Paper 26.3 b205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269, `--min-scenarios 45 --npc-navigation --expect-timeout 1200`): baseline on `next` 45/45, branch 45/45, log check passed.
    3. CI: push and PR runs on `8c864f7a`, `build` and `paper-boot` green (45 scenarios; paper-boot runs 43799206281 and 43800089307). #586 did not hit.
    4. Known reds: none. Codex: at its usage limit on both PRs; said on both, finished without it.
5. **Before (`next`, M1's baseline reproduced) → after; collision off / on.**
    1. `npc-doorway-crowd`, before with all keys off:
        1. 11/12 arrived (1 `Failed`) / 12/12.
        2. Stuck spells 2 (1 not freed) / 1.
        3. Longest still by the door 11.7 / 2.3 s.
        4. Overlap in the doorway 21 ticks, 4 at once / 44 ticks, 4 at once.
    2. Control run with `local-legs-clearance` alone:
        1. 12/12 both.
        2. Trips 3.7 / 6.9 s mean.
        3. Overlap 19 ticks, 5 at once / 34 ticks, 3 at once.
        4. Stuck spells 0 / **6** (5 near a wall): fails the M4 check with collision on.
    3. After, with crowd awareness:
        1. 12/12 both, **0 / 0 stuck spells**.
        2. Waits 7, yields 0, longest queue 7 (both sides).
        3. Longest wait 7.8 / 8.3 s, which is **1.5 s per NPC that went first**. None let go.
        4. Longest still outside a queue 0.4 / 0.4 s.
        5. Overlap 5 ticks / 8 ticks, at most 2 at once (the same direction a block apart).
        6. Trips 6.3 / 6.6 s mean. Turn-taking costs time where bodies could pass through each other.
    4. `npc-stairhouse-group` (20 in ranks of 3, the M2–M6 keys) is unchanged: leader 7.5 / 8.0 s, 0 folds, entrance 0.4 / 0.4 s, 0 stuck spells, 0 waits. The line has no narrow place.
    5. **M3's note (lane merges with collision on), checked with the hash.**
        1. Two NPCs share a cell in 22 / 19 of 29 / 31 looks.
        2. In 10 / 7 looks two bodies in one cell stand closer than 0.6 (closest 0.05 / 0.19), so with collision on the squeezed rows still overlap.
        3. Left for M7 (push resistance; how Citizens' `collidable` separates NPCs).
    6. Cost: crowd awareness's own share is 0.0015–0.0063 ms per NPC per tick. The core test bounds the hash under 0.003 ms per NPC per tick for 1,000 NPCs.
6. **Decisions (DESIGN § 4.3).**
    1. *What is narrow.* Chosen: free width under 2 blocks (the corridor's chokepoint width, decision 1.4), with no length limit, so a 1-wide passage of any length is one place, one direction at a time. Alternatives: (a) only places of 3 blocks or less (decision 1.4's chokepoint; a long 1-wide passage would have no turns and NPCs would meet in it); (b) under 1.3 (two squeezed bodies; a 1.5-wide passage would let NPCs meet head-on).
    2. *First come across directions.* Chosen: the earliest waiter of either direction goes next, so traffic alternates when both sides queue. Alternatives: (a) batch one direction while it has waiters (faster: the doorway's 12 would take about half the time, but an NPC on the other side could wait for a whole column); (b) first come per direction only, the direction switching when one side is empty (starves the other side under steady traffic).
    3. *Arrival distance and queue spots.* Chosen: arrival at 4 blocks along the way; spots 1.5 + k blocks before the place, a block to the right of the line (else left, else on the line), further back while the way is narrow. Alternatives: (a) spots on the corridor cells with the most clearance (needs a corridor per place; the side offset gives the same in rooms and streets); (b) no spots, waiting where the NPC stands (queues bunch in the doorway's mouth and block the way out with collision on).
    4. *Followers.* Chosen: followers don't ask for turns. Their leader asks, and keeps the turn until no follower is in the place or 1.5 blocks before it. Alternatives: (a) every follower asks (singles would cut into the column between two followers; the slots fight the queue spots); (b) groups before singles (proposed first; the developer chose first come, 4c.7).
    5. *Others in a place.* Chosen: only NPCs with a turn (and their followers) block a place; an NPC standing in it without one (idle, another key scope) does not. Alternatives: (a) any NPC in the place blocks it (deadlock behind an idle NPC in a door).
    6. *Turn ends.* Chosen: 0.5 past the place's end. Alternatives: (a) 0.8 (the first try: 2.8 s of wait per NPC ahead in the doorway, close to the 3 s check).
    7. *Deadlock guard.* Chosen: a queue lets an NPC go after 30 s (logged and counted); a turn held 30 s is dropped. Alternatives: (a) no guard (a stuck NPC in a door would hold everyone).
    8. *Waiting behind someone.* Chosen: another NPC's cell within 1.5 blocks along the way when the watchdog fires (or the engine reports a local-leg NPC stuck in one block): one wait, no spell; an engine leg is walked again after 20 ticks; after 30 s of the same jam it is a spell. Alternatives: (a) any NPC within 1.5 blocks in any direction (an NPC beside a stuck one would never be helped); (b) no limit (a real jam would never get recovery).
    9. *The doorway scenario's keys.* Chosen: `crowd-awareness` with `local-legs-clearance` (and `corridor-steering`, which does nothing for these local legs), because every trip there is a short local leg and the engine's legs clip the door frame. Alternatives: (a) `crowd-awareness` alone (would mix M4's numbers with the engine's corner trouble, M1's 11.7 s); the control run above separates the two.
    10. *"Nobody waits longer than the queue needs".* Chosen: the longest wait divided by the NPCs that entered before it (those in the place when it arrived included) at most 3 s, and longest still outside a queue at most 3 s (held NPCs left out of `ScenarioNpcs`' still measure). Alternatives: (a) longest still under 10 s for everyone (the 7th in a doorway queue legitimately waits about 8 s; a bigger queue would fail it).
    11. *Overlap in the doorway with collision on.* Chosen: reported, not asserted (the same direction a block apart can put 2 in the door's cell for a few ticks). Alternatives: (a) assert at most 1 (flaky).
7. **Out of scope, noted.**
    1. With collision on, bodies of one squeezed row still overlap (5.5): for M7. Not filed.
    2. `plugin-scenarios.md` § 7 and `ci.md` § 7: the two scenarios now assert with crowd awareness. Left for the docs session.
    3. #636 did not block this link.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add `crowd-awareness: false` under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #626 (comment 6906731496): `quarry-to-keep` with 50 singles, a one-block door with traffic both ways, a group of 20 against 10 singles, the cost line.
10. **Notes for later links.**
    1. **Option B checkpoint (plan 4c.4 item 8):** with the keys on, the doorway's head-on traffic is solved by turns (0 stuck spells both ways, 0 yields needed). What remains dynamic: trips are slower with collision off (6.3 vs 3.7 s mean), and strays in open rooms are not handled; nothing needed B in the five scenes.
    2. **M7 (collision):** `NpcNavigationService.occupancy()` gives positions, shared cells and the closest pair per look; `waitsBehind(...)` tells waiting from stuck for a pushed NPC too; recovery already skips occupied cells.
    3. **4c.7 (authority, closed formations first):** change `CrowdControl.earlier` (the only place two NPCs are ordered); a closed formation's followers could take tickets of their own through `setGroupMembers`.
    4. The free-width cache is keyed by cell and one of eight headings; a gate change clears it (`onGateChanged`). Other block changes (a door block placed by a player) wait up to 10 s.

### 4.15 M7 — Collision on: push resistance and recovery (#627)

1. **Scope done** (plan 4c.4 item 7, research report § 6; push resistance runs whenever `npc.navigation.collidable` is on; **`collidable` stays `false` by default**, item 10; `npc.navigation.enabled` still off by default).
    1. **Collision policy** behind the knk-core port `NpcCollisionPolicy`, chosen by the scenario `npc-collision-policy` on Paper 26.3 b205 with Citizens b4269:
        1. The Paper adapter `BukkitCollisionPolicy` uses Paper's per-entity collidable exemptions. Every online player is exempt from every NPC with collision on, kept up to date on joins, quits and respawns.
        2. A scripted player carries an NPC 2.85–3.80 blocks with collision on and no policy; with the policy the NPC moves 0.00, and two NPCs 0.2 apart are still pushed to 1.06.
        3. On the team caveats of research § 6.4: Citizens put the NPCs on no server team. Bukkit `FOR_OTHER_TEAMS` (vanilla `pushOtherTeams`) kept the player out. `FOR_OWN_TEAM` (vanilla `pushOwnTeam`, the research's suggestion) did not, because the names read backwards.
    2. **Push detection** (`push/PushWatch`): a move the NPC's own walk doesn't explain (speed, back against its road line, sideways after a contact, away from a standing spot), with one push per episode. Stair steps and turns are its own walk. The contacts come from Citizens' `NPCCollisionEvent` and Paper's `EntityPushedByEntityAttackEvent`. An unreported push with an NPC within 1.5 blocks counts as that NPC's jostle.
    3. **Return:** straight back, else along its footsteps (`RecentSteps`), else a local leg through the planning queue (`LocalLegSearch` with `local-legs-clearance`, M6 note 10.3), then on along its route. An NPC with no order returns to its post, and a group follower is left to its group. The teleport home comes last, after `push-teleport-ticks`, and only out of every player's sight (`NpcSight`, Paper `BukkitNpcSight`).
    4. **Edge guard** (`push/EdgeGuard`, L5's drop rule): queue spots of NPCs with bodies skip cells next to a drop. A push towards a drop, checked on every look of the push, sends the NPC back and exempts the pushing player at once.
    5. **Repeated pushes** (`push/PushLedger`, with `players-push-npcs`): 3 pushes in 200 ticks exempt the player for 1200 ticks.
    6. **Attack knockback** stays; the NPC walks back. Citizens' NPCs are protected by default, so only unprotected ones are knocked back.
    7. **New keys:** `players-push-npcs` (false), `push-return` (true), `push-exempt-after` (3), `push-exempt-window-ticks` (200), `push-exempt-ticks` (1200), `push-teleport-ticks` (600). The stats line `pushes: ...` and the events `pushed`, `push_returned`, `push_exempt`, `push_teleport` are new.
    8. **M4 use** (block 4.14 § 10.2): `occupancy()` is unused. Push resistance reads positions directly, and only when a push happens. `waitsBehind` is unchanged. Recovery's occupied-cell rule applies to the walk back too, since it runs through the same ladder and leg code.
    9. **knk-workspace:** the changelog with the YAML, configuration reference § 4.27 and § 2.1, plan 4c.4 item 7.4 (status, tests, before → after, why the default stays off, developer test) and 4c.7 item 3.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-m7` at `6393aa37`: 2 commits on `next` `a35fed5a`, then `next` `4b80cbd0` merged in (CI and agent files, mechanical).
    2. knk-workspace `claude/npc-movement-m7` at `dc8a91c5`: 1 commit, then `next` merged in (the changelog conflict was two new entries; I kept both).
3. **PRs.** PandiO/knk-plugin#57 (`Closes` #627) and PandiO/knk-workspace#656 (`Part of` #627), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`, all with 0 failures:
        1. core 2921 → 2955 (+34).
        2. api-client 344 → 344 (2 skipped).
        3. paper 2860 → 2865 (+5, 18 skipped).
    2. New tests:
        1. `PushWatchTest` 12, `PushLedgerTest` 4, `EdgeGuardTest` 4, `NpcNavigationPushTest` 14.
        2. `BukkitCollisionPolicyTest` 4 (MockBukkit).
        3. `NpcNavigationConfigTest` +1.
        4. `PaperScenariosTest` updated.
    3. Scenarios run locally (`--min-scenarios 48 --npc-navigation`): baseline on `next` 45/45, branch 48/48 in 10 min 5 s. `MIN_SCENARIOS` is raised to 48; the 30-minute job timeout is kept.
    4. CI: the push and PR runs on `6393aa37` are green (`build`, `paper-boot` with 48 scenarios). #586 did not hit. Codex is at its usage limit on both PRs; I said so on both and finished without it.
5. **Numbers** (local, collision on, all 4c keys as in M4).
    1. The 4c.5 scenarios pass with collision on as with it off:
        1. Stair-house singles 12/12 with 0 stuck spells (31 NPC jostles, 0 returns).
        2. The stair-house group of 20: 0 folds, 0 stuck spells.
        3. The jagged straight 12/12, and its group of 9, with 0 stuck spells (34 jostles, 4 returns).
        4. The doorway crowd 12/12 with 0 stuck spells.
        5. The plaza at +4 %.
    2. `npc-guard-ledge-push`:
        1. Players never push: the guard moved 0.00.
        2. With `players-push-npcs`: pushed 0.68, the player exempted at the edge, the guard 0.83 from the drop at most, never fell, back within 0.21 of its post.
        3. Repeated pushes: the third exempts, the fourth moves it 0.00.
        4. Knockback: 0.62 off its line, back on it in 0.5 s, seen as an attack.
    3. `npc-door-column`: 12/12, 2.0 s of wait per NPC ahead, 2 stuck spells at the frame freed in 1.0 and 2.5 s. The same run with collision off has 0. Filed as #657.
    4. Squeezed rows (scope item 8), `npc-stairhouse-group`: with collision on, bodies are under 0.6 apart in 7 of 31 looks (closest 0.19); with it off in 10 of 29 (closest 0.05). Not made to hold (decision 6).
6. **Decisions (DESIGN § 4.3).**
    1. *Collision mechanism.* Chosen: per-entity collidable exemptions for players. They worked in the scenario, touch no team, and the per-player exemption of item 5 is the same call. Alternatives:
        1. (a) A K&K team with `FOR_OTHER_TEAMS`. It worked too, but Citizens sends its own per-NPC client teams for name tags, an entity is on one team only, and other plugins use teams.
        2. (b) `FOR_OWN_TEAM`. It lets players push.
        3. (c) Inverting: NPCs not collidable, with every other NPC exempt. It also worked, but needs an O(n²) exemption list.
    2. *Players' bodies.* Chosen: by default, players never push NPCs, and `players-push-npcs: true` is the realistic mode. Item 5 (repeated pushes) only applies there, because with exemptions players can't push at all. Alternatives:
        1. (a) Players always collide, with push resistance only. In the probe a player carried the NPC 2.85 blocks, so a guard near a ledge would fall before a return could act.
    3. *Key names*, since the plan names only `collidable`. Chosen: `players-push-npcs`, `push-return`, `push-exempt-after`, `push-exempt-window-ticks`, `push-exempt-ticks`, `push-teleport-ticks`, with the defaults 3 pushes in 10 s, 60 s exempt, 30 s before a teleport. Alternatives:
        1. (a) Fewer keys, with constants for the exemption window and length. These are values the developer will want to tune on the dev server.
    4. *Which pushes start a walk back.* Chosen: a player, an attack or something unknown always does. Another NPC does only towards a drop, or for an NPC at its post moved a block or more. A group follower never does. Alternatives:
        1. (a) Every push. That gave 13 returns and extra jostling in the door column.
        2. (b) No NPC pushes at all. Then a guard at its post would be shoved away for good by a passing column.
    5. *Return order details.* Chosen: straight back where that is a straight walk, before the footsteps. A push's track is not footsteps, and the straight line is the push reversed, checked by L5's floor continuity. An NPC standing without an order goes back by a K&K order home when there is no straight way. Alternatives:
        1. (a) Footsteps first, as the plan words it. They are only recorded every 5 ticks while moving, so a 0.5-block push often has none.
        2. (b) The engine's rule-free `walkTo`. That breaks NAV-02.
    6. *Squeezed rows with collision on.* Chosen: recorded why not. Holding 0.6 needs slots wider than the body (0.7), and that changes which roads M3 squeezes 3 abreast into, a decision M3's developer already took (0.6). Alternatives:
        1. (a) Raising `group-lateral-spacing-min` to 0.7 when collision is on.
    7. *The column check.* Chosen: "no jam beyond the queue" means all arrive, at most 3 s of wait per NPC ahead, nobody still longer than 3 s outside a queue, none let go, and every stuck spell freed within 3 s. The door-mouth cause is M4's and filed as #657. Alternatives:
        1. (a) 0 stuck spells as in `npc-doorway-crowd`. That fails on M4's door-mouth rule. Two tries in `CrowdControl` (1.6 spacing for bodies, a fresh-turn guard) changed nothing and were reverted.
    8. *The default.* Chosen: `collidable` stays `false`. The literal condition (every 4c.5 scenario passes with collision on) holds, but a trial with collision on everywhere failed `npc-ledge-corner` (an NPC shoved off #491's corner fell), `npc-corners-walk` (a fall, 3 spells not freed), `npc-group-narrows` and `npc-stuck-ladder` (its scripted push is undone by design). Alternatives:
        1. (a) Turn it on, and pin those four scenarios to collision off. That hides a fall at a real place of the dev world.
    9. *Scripted pushes.* Chosen: the fake player is teleported in 0.12-block steps each tick. Its movement packets are refused on Paper 26.3 (`Invalid move player packet received`). `ScenarioPlayer.move()` is unused elsewhere and was left alone. Alternatives:
        1. (a) Fix `NmsFakePlayer.move`. That is outside scope (#540's framework).
7. **Out of scope, noted.**
    1. #657: the door-mouth claim with bodies.
    2. `ScenarioPlayer.move()` is refused on Paper 26.3 (above). Not filed; for the docs session.
    3. Pushes on an NPC walking off its road line are judged only by speed, so a slow push by a player there is not seen. This is moot with players never pushing, and is in the plan's note.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. `config.yml`: add the seven keys under `npc.navigation` (YAML in the changelog and § 4.27). No migration.
    2. The developer test is on #627 (comment 6912759522) and in plan 4c.4 item 7.4.11. It decides the default, with item 7.4.10's list.
    3. Review decisions 2, 4, 6 and 8.
10. **Notes for later links, and for the docs session.**
    1. **Before `collidable` can default on:**
        1. Turns on 1-wide flights and ledges next to a drop.
        2. The squeeze margin (decision 6).
        3. #657.
        4. `npc-stuck-ladder` and the L3–L5 scenarios run with collision on as well.
    2. **The docs session** (#589, to be rescoped) should cover M1–M7:
        1. `docs/guides/developer/plugin-scenarios.md`:
            1. the schematic scenes (M1);
            2. the report-mode lines and the asserting checks per scenario (M2–M5, M7);
            3. scripted pushes (`ScenarioPushes`) and `CitizensBootstrap.entity`/`setProtected`;
            4. the refused `move()`.
        2. `docs/guides/developer/ci.md` § 7: 48 scenarios, timings.
        3. An admin or ops guide for `/knk npc nav stats`: the `corridor`, `local legs`, `crowd:` and `pushes:` lines.
        4. BEHAVIOR_MODEL NAV-24–NAV-28 status rows, NAV-26 with M7's push resistance.
        5. The feature register and site/wiki rows for Phase 4c.
        6. A smoke-test guide in `docs/guides/` assembled from the plan's 4c.4 developer tests M1–M7, every step in full.

### 4.16 L9 — Running groups ignore a realtime district deny: the NPC checks had no WorldGuard regions (#668)

1. **Scope done** (behind `npc.navigation.enabled`, no new config key).
    1. **The gap between L6's scenario and the real path.** `KnKPlugin.registerCommands()` starts `NpcNavigationModule` (about line 1086 of `onEnable`) before `regionTracker` is built (about line 1125). The module took `regionTracker.regionIds()` at start: `null` on every server. So `BukkitNavWorld.regionsAt` always returned an empty set, and every NPC rule check saw no region: the leader's way-ahead recheck, the trespass guard, and the followers' lanes and guard. The scenarios built their own `new RegionIds()` (`ScenarioNpcs`), and the core sim has its own region function, so no test read regions as the server does.
    2. **The five questions.**
        1. `npcNavigation.navigating()` is true once `/knk npc nav group 20` has run (route following is built on first use).
        2. The realtime wiring runs on the hub's real events (`registerConfigSync` runs after `initializeNavigation`).
        3. The rewarm's region set comes from the road edges. The router's own `you may not enter Residential District` comes from those edges' tags, so `district_1000004` and `gate_2000131` are in it.
        4. `onAvailabilityChanged` reaches `NavGroup.rulesChanged`, and the follower recheck runs, but it found nothing denied with no regions.
        5. `/knk cache refresh` triggers the same recheck, through the same empty-region world.
    3. **This explains every symptom.** `replans: recheck 0, event 0` and `trespasses 0` (no entry was ever seen). Only the router's next plan blocked the group. Blocking at spawn and the release on re-allow worked, because the router uses the edges' tags. The per-region `npc.navigation` override scopes (`regionsOuterToInner`) never applied to NPCs either.
    4. **The developer's question (the op's entry bypass): no.** `navGroup` takes the profile from the command's argument, else `default`, never from the sender. Every NPC check judges an `NpcAccessSubject` with `bypassesDomainRules() = profile.bypassDomainRules()`, which is false in the shipped `default`. Tested (`NavGroupDomainRulesTest`, `NpcNavigationModuleRegionsTest`).
    5. **knk-plugin.**
        1. `NpcNavigationModule` takes a `Supplier<RegionIds>`. `rulesWorld()` builds the rule checks' world when route following is built, and `regionsOuterToInner` asks too. It logs `[NPC] no WorldGuard region query …` when there is none.
        2. `BukkitNavWorld.knowsRegions()`.
        3. `KnKPlugin` passes `() -> regionTracker.regionIds()`.
        4. `ScenarioServices.npcRules()`: `ScenarioNpcs` with domain rules reads regions through the live module.
    6. **knk-workspace.** The changelog entry, and plan Phase 4 known limit 4 and step 10 (automated parts, startup-log check). Retest steps and the answer are posted on #668 (comment 6927589358).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-followups-l9` at `76259d86`: 1 commit on `next` `0d9c55d6`.
    2. knk-workspace `claude/npc-followups-l9` at `1dffa06d`: 1 docs commit on `next`.
3. **PRs.** PandiO/knk-plugin#61 (`Closes` #668, `Part of` #506 and #593) and PandiO/knk-workspace#669 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `0d9c55d6` core 2955, api-client 344 (2 skipped), paper 2866 (18 skipped). Result on `76259d86`: core 2956 (+1), api-client 344, paper 2869 (+3). 0 failures.
    2. New tests:
        1. `NpcNavigationModuleRegionsTest` (3).
        2. `NavGroupDomainRulesTest` +1 (the NPCs' subjects).
    3. Scenarios, locally (Paper 26.3, pinned WorldEdit, WorldGuard, Citizens b4269, `--min-scenarios 48 --npc-navigation`):
        1. This branch with `next`'s start-time wiring: 46/48. `npc-group-realtime-entry` fails (`knk-sc-22002 entered the district`), and so does `npc-group-access-change` (`entered the region`).
        2. With the fix: 48/48, log check passed.
    4. CI: the push run on `76259d86` is green (`build`, `paper-boot`). The PR run is green too (`paper-boot` 43944997333). #586 did not hit. Codex: at its usage limit (said on both PRs).
    5. A probe, not committed: L6's core test with all five movement keys on and `ranks` passes. So the core logic was never the problem.
    6. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Fix.* Chosen: a supplier asked for on use, because it is the smallest change and it keeps `KnKPlugin`'s start order. Alternatives:
        1. (a) Move the NPC module's start after the region tracker. That reorders `registerCommands` and its takeovers, which is riskier.
        2. (b) Let the module build its own `new RegionIds()`. That is a second query, which R8 wants shared.
    2. *Test on the real path.* Chosen: scenarios read regions through the live module's `rulesWorld()`, so they fail on `next`'s wiring. Alternatives:
        1. (a) A scenario that drives the whole hub, API and road network. There is no road network or API in CI, so the plugin's rewarm sends no event.
        2. (b) A MockBukkit test of `KnKPlugin.onEnable` order. That is not feasible without the whole plugin.
    3. *Warning.* Chosen: one warning when route following is built without regions. Alternative:
        1. (a) Refuse to run. That is too strict for servers without WorldGuard.
6. **Out of scope, noted.**
    1. The coordinator's note 32 says 19 of the 20 group NPCs were IDLE. Followers are registered with the navigation service without an order of their own, so IDLE is their normal service state. Not filed.
    2. The movement problems (B) are untouched.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration. Per-region `npc.navigation` overrides now take effect for NPCs.
    2. The retest steps on #668 (plan Phase 4 step 10): no `[NPC] no WorldGuard region query` line, outside followers stop, `trespasses 0`.
9. **Notes for later links.**
    1. Anything the NPC module needs from `onEnable` after `registerCommands` must be a supplier.
    2. The B links' snapshot replay should read regions through `ScenarioServices.npcRules()`.

### 4.17 B1 — Evidence: the snapshot command (B1a), the whole stair house on the real line, the developer's snapshot replayed (B1b) (#670)

1. **Scope done.** The coordinator split the link at 20:40: B1a (the command, merged) and B1b (scene and replay, on `claude/npc-movement-b1-scene`). The coordinator's messages of 20:18 and 20:22 reached this session only at 21:08.
    1. **B1a, `/knk npc nav snapshot <route>`** (knk-plugin #62, merged into `next` `0f039203`).
        1. Node `knk.admin.npc`. It is refused while `npc.navigation.enabled` is off. It needs road navigation, not Citizens.
        2. It writes `plugins/KnightsAndKings/npc-snapshots/<route>-<UTC>.zip` with:
            1. the road line for the default NPC profile;
            2. the stretches handed out from the start;
            3. gate crossings and plazas;
            4. the roads in the box;
            5. the WorldGuard regions touching the box, whole, with parent, priority, flags, the cached domain data and gate doors;
            6. the settings with their layers;
            7. a manifest;
            8. the region files the box touches, copied off the main thread after a save.
        3. Model and zip format live in knk-core `core/npc/nav/snapshot/`; the Paper side is `NavSnapshotTaker`. Docs: the commands guide and the changelog (#691, merged).
        4. The developer took the first snapshot at 21:25.
    2. **B1b, the scene.**
        1. `SizedScene` and `ScenarioScene.Box` let a scenario ask for a bigger box.
        2. The whole stair house sits in `STAIRHOUSE_BOX` (32 × 40 × 72, frame real − (1400, 46, −553)).
        3. `NpcMovementScene.CLIMB` is the **real road line**: the `# waypoints:` lines of the developer's traces 69 (reversed), 87 and 63. The traces arrived at 21:08 on `evidence/smoke-2026-11-16` `2e46cb90`; the first version used a line found on the schematic. The eight traces are test resources (`.log`, `git add -f`).
        4. `npc-stairhouse-climb` is the light scene, in report mode: a group of 20 with 20 singles, `stretch-blocks` 8, and the smoke test's settings (decision 35.3).
        5. `ClimbWatch` reports falls, places skipped, handovers onto another level, the 30 s guards (including a turn dropped by `STALE_TICKS`, which the crowd does not count), and where each NPC got to.
    3. **B1b, the replay.**
        1. `AnvilRegion` reads `.mca` files without the server, including Minecraft 26.x palettes (block state strings, each wrapped in `{"": ...}` in mixed lists).
        2. `SnapshotReplay` (with `SnapshotRegions`) places the blocks, builds the regions, and gives fake access rules, the line, gates, plazas and settings.
        3. **The developer's snapshot of `quarry-to-keep`** (21:25, plugin `0f039203`, 17.5 MB, `evidence/smoke-2026-11-16` `4a7bcca9`) is committed **trimmed**: `tools/scenario-scenes/trim_snapshot.py` keeps the 30 chunks round the stair house, in 371 KB.
        4. **`npc-replay-quarry-to-keep`** is the main replay. It checks the replay: 111,286 blocks placed, 13 regions seen by the NPC checks, settings known. It then reports a leader alone and a group of 20, once with the stored settings and once with the smoke test's.
        5. `make_snapshot_sample.py` writes a sample made from the schematic; it is kept for the unit tests.
    4. **B1a fix in B1b.** The dev server's gate domains have type `GateStructure`, so the taker recorded no gate door states. The taker and `isGate` now treat that type as a gate.
    5. **CI.** `MIN_SCENARIOS` 50, `--expect-timeout 1800`, job timeout 40 minutes. Docs: plugin-scenarios § 1 and § 3 items 7.5 and 8, ci.md § 7, the changelog (#692).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-b1`: `1d9e3209` (merged).
    2. knk-plugin `claude/npc-movement-b1-scene`: `6d81d59a`.
    3. knk-workspace `claude/npc-movement-b1`: `383cd24d` (merged).
    4. knk-workspace `claude/npc-movement-b1-scene`: `6684a815`.
3. **PRs.**
    1. B1a: PandiO/knk-plugin#62 and PandiO/knk-workspace#691 (`Part of`), merged.
    2. B1b: PandiO/knk-plugin#63 (`Part of`) and PandiO/knk-workspace#692 (`Closes #670`), base `next`, not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `a78fcce8`: core 2956, api-client 344 (2 skipped), paper 2869 (18 skipped).
        2. B1a: core 2968 (+12), paper 2874 (+5).
        3. B1b: paper 2885 (+11). 0 failures.
        4. New tests:
            1. `NavSnapshotZipTest` 4, `SnapshotBoxTest` 4, `SnapshotPartsTest` 4, `NavSnapshotTakerTest` 5.
            2. `AnvilRegionTest` 5: the sample block for block; the developer's 26.x files, where 85% of the schematic's blocks are the same with their state.
            3. `SnapshotReplayTest` 4.
            4. `NpcMovementSceneTest` +2: the climb on the stairs and in order; every point is in a trace.
    2. CI.
        1. #62: `build` and `paper-boot` green on both runs.
        2. #63: run 43958612478 green on `99c27a40`, with the earlier set of 50 (`paper-boot` 19 min).
        3. The head `6d81d59a` was pending at the time of this block.
    3. Scenarios, locally: 50/50 on the earlier set (15 min 23 s). `npc-replay-quarry-to-keep` passes in 354 s.
    4. **What shows on `next`.**
        1. **The schematic climb** (real line, short stretches, the smoke test's settings):
            1. Falls from 1411 51 −496 to 1411 49 −500, the smoke test's fall spot: 30 with a group of 20, 78 with the crowd.
            2. Handovers onto another level: 37 for a leader alone, 434 with the crowd.
            3. **A turn dropped by the 30 s guard** (the group's leader, 30.3 s at 1409 54 −499).
            4. Stuck spells near 1411 50 −499, the smoke test's stuck spot.
            5. These numbers come from the three-phase run; CI now runs only the crowd phase.
        2. **The real replay** (real blocks, 32-block stretches, no crowd):
            1. Stored settings: the leader alone arrives in 54.7 s with no falls and 1 handover onto another level (on the street slope). In the group of 20, the leader arrives in 87.0 s, followed by **32 stuck spells and 6 followers lost**; 9 followers end on flight 5 and the −536 landing.
            2. Smoke-test settings: the leader alone is the same. The group's leader arrives in 67.3 s with 0 stuck spells; 5 members reach the top hall and the rest are spread over flights 4 and 5.
            3. So the handover and fall faults need the crowd and short stretches. A single leader or group on 32-block stretches does not trigger them on the real blocks.
    5. Known reds: none. Codex was at its usage limit (said on #62).
5. **Decisions (DESIGN § 4.3).**
    1. *The scene's route line.* Chosen: the traces' `# waypoints:` lines going up, with duplicates at stretch joins dropped. East of x 1418 the scene keeps its own flat street, because the real street falls to 1433 44 −516 beyond the schematic. Alternatives: (a) the line found on the schematic (used until the traces arrived; it showed the faults more weakly); (b) the snapshot's road polyline on the schematic (the replay already runs it on the real blocks).
    2. *The real snapshot in the repository.* Chosen: trimmed to the stair house (371 KB) with a deterministic tool, committed in main resources so it ships in the jar the scenarios run from; the full 17.5 MB zip stays on the evidence branch. Alternatives: (a) the whole zip in the jar (17.5 MB in every jar); (b) fetch it from the evidence branch in CI (network and a second source of truth; local runs need it too).
    3. *Which scene runs where.* Chosen: both in `paper-boot`. The real replay (leader and group, two configurations, about 6 minutes) is the main evidence. The schematic climb keeps only its crowd phase (about 2.5 minutes), because only the crowd with short stretches shows the falls, the handovers onto another level and the guard. The sample replay left CI. Alternatives: (a) only the replay (the faults would not show); (b) every phase of both (about 4 minutes more).
    4. *Two configurations in the replay.* Chosen: the stored settings (the merged dev config) and the smoke test's (decision 35.3), so B2 sees whether a fix holds in both. Alternative: (a) the stored settings only.
    5. *Short stretches in the climb.* Chosen: `stretch-blocks` 8, so handovers fall on the hairpins. Alternatives: (a) 32, which the real replay already runs.
    6. *Box for the whole house.* Chosen: a scenario-sized box (`SizedScene`). Alternatives: (a) two stacked 32 × 24 × 32 boxes; (b) a bigger default for every scenario.
    7. *Snapshot refused while the flag is off.* Chosen: refuse, like every `nav` action, which keeps `NpcNavigationModuleDisabledTest`'s invariant. Alternative: (a) allow it without the flag.
    8. *Stretches in the snapshot.* Chosen: as handed out from the start (`stretchesNote` says so). Alternatives: (a) the line only; (b) a recorded NPC's own (that is the trace's job).
    9. *Region files.* Chosen: search the world folder for `region/r.x.z.mca` and keep each path. Alternative: (a) a fixed `region/` path (it breaks with 26.x dimension folders).
    10. *Gate type.* Chosen: any domain type containing "gate" (`gate`, `GateStructure`). Alternative: (a) an exact list of type names.
6. **Out of scope, noted.**
    1. The crowd's own `let go` counter stays 0. The guard that fired drops a turn (`STALE_TICKS`), and the crowd does not count that; `ClimbWatch` does. For B3. Not filed.
    2. The traces were missing from `evidence/smoke-2026-11-16` at the start (`*.log` is git-ignored). The coordinator added them at `2e46cb90`.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. After B1b is merged into `next`, take a new `/knk npc nav snapshot quarry-to-keep`. The first one has no gate door states (the `GateStructure` fix). Then trim it with `trim_snapshot.py` and replace the committed zip.
9. **Notes for later links.**
    1. B2 to B4 turn the `ClimbWatch` numbers into checks:
        1. in `npc-stairhouse-climb`: handovers onto another level 0, falls 0, no turn dropped by the guard;
        2. in `npc-replay-quarry-to-keep`: the group arrives, no stuck spells, nobody lost.
    2. A new snapshot: run `trim_snapshot.py IN OUT 1391 36 -559 1454 96 -480` and commit OUT as `scenario-snapshots/quarry-to-keep-stairhouse.zip`. A scene is at most 64 wide along x.
    3. `NpcMovementScene.CLIMB` and `make_snapshot_sample.py`'s `CLIMB` hold the same line; change both together. A new trace file needs `git add -f`.

### 4.18 B2 — Stretch handover in 3D, appended, bridged from the feet; gaps as local legs; no leader fall in the group path (#671)

1. **Scope done** (decision 34.1, plan § 4c.8). Behind `npc.navigation.enabled` (off by default); no new key.
    1. **Handover by 3D progress.** knk-core `Trail` keeps the waypoint list the mover was given and the index of the one the NPC walks to: the nearest in 3D from the current one on, or the next once reached (0.6) or passed, never back. `NpcNavigationService.watch` hands out the next stretch once fewer than `HANDOVER_DISTANCE` (4) blocks are left along those waypoints in 3D. Without a list (after a crowd hold, a push or a recovery move), it uses the 3D distance to the stretch end.
    2. **Appended, not replaced.** `Trail.appended` puts the new stretch after the waypoints not yet walked. `Trail.fromFeet` drops only those the NPC is already past: its feet beyond the waypoint along the next step, no further from the next waypoint than the waypoint is, on its level, and the next one a straight walk.
    3. **Bridged from the feet.** `WaypointChain.split` starts at the NPC's feet when it is on the ground.
    4. **An unbridgeable step becomes a local leg.** `split` returns the gap. The list is cut before it. When the cut list is walked, `startGapLeg` sends a local leg to the waypoint after the step, then the follower restarts where the NPC stands. Logged (`no walk from … to … on the line, a local leg takes that step`) and counted (`gapLegs()`, in the scenario report lines).
    5. **No leader fall in the group path.** `NavGroup.leaderFell`: a leader with a route line that is more than 1.75 blocks below the lower of its path point and the one before has fallen. Its points stay out of the path. After 30 s below, the path follows it as before. Counted as `leaderFalls()`.
    6. **Proof turned into checks** (`ClimbWatch.failures`).
        1. `npc-stairhouse-climb` fails on a fall from a climb place, a handover onto another level, a turn dropped by the 30 s guard after its holder fell, a group leader that does not arrive, and a lost follower.
        2. `npc-replay-quarry-to-keep` fails on the same for the leader alone and the group in both configurations, except lost followers (item 6.1).
        3. "Onto another level" is now judged on the list the NPC walks: the waypoint it walks to next after a handover is 2.5 blocks or more above or below its feet. B1's measure (the new stretch's waypoint nearest the feet horizontally) is still reported as `new stretches starting off the feet level (B1's measure)`. Decision 5.3 explains why.
    7. **The group failure in the real replay (prompt § 2.6): a separate cause, not fixed here.**
        1. With B2, the replay group has 0 falls and 0 handovers onto another level, but followers are still lost (stored settings: 26 stuck spells, 3 lost).
        2. The cause is on flight 5 (x 1408–1410, z −544…−534), which is built of alternating bottom slabs and full blocks: each step is half a block. When the leader stops in the top hall, the rear rows' slots lie on that flight, by design. The slots stand at whole-block heights, for example feet 73 over a slab whose surface is 72.5.
        3. Followers 0.5–1 block short of their slots get the same two waypoints every 5 ticks and do not progress. Their no-progress spell backs them off down the flight, and the ladder's local leg finds `no point ahead on its floor to aim at` (every point ahead on a half-block stair is on a higher floor). They are then lost.
        4. Evidence: run log with traces at real 1409.6 72.5 −541.6 (knk-sc-14, -16, -19). Proposal on [#673](https://github.com/PandiO/knk-workspace/issues/673#issuecomment-6931558660): slots at real surface heights, a follower within a block of its slot on the same flight counts as settled, and `PathTargets.ahead` accepts a point a step above.
        5. Not small and not in the handover code, so lost followers stay report-only in the replay (the climb checks them).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-b2`: `ce1def6b`, `fd88545f`, `36822ec4`, `b3cf6a91`, head **`a30ac085`**.
    2. knk-workspace `claude/npc-movement-b2`: head **`cbff95cc`**.
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#64 (`Part of #671`).
    2. PandiO/knk-workspace#693 (`Closes #671`).
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `80902942`: core 2968, api-client 344 (2 skipped), paper 2885 (18 skipped).
        2. Result: core 2987 (+19), api-client 344, paper 2885; 0 failures.
        3. New tests: `TrailTest` 10 (index, never back, the flight above not taken for the NPC's place, rest in 3D, a stretch end right above is still a flight away, appended, duplicate join, waypoints already passed dropped, one not reached kept, nothing ahead skipped).
        4. `WaypointChainTest` +5 (split, the join from the feet, a gap handed back, a gap at the feet, the level above as a gap).
        5. `NpcNavigationServiceTest` +3 (appended, no handover from a flight below the stretch end, a gap walked as a local leg).
    2. Scenarios, locally (Paper 26.3 b205, Citizens b4269, `--npc-navigation`): **50/50 on the final head.**
    3. **Before (`next`) → after.**
        1. `npc-stairhouse-climb`:
            1. falls 42 → 0;
            2. handovers onto another level 446 → 0 (B1's measure → 0);
            3. stuck spells 117 → 2;
            4. lost 0 → 0;
            5. no turn dropped by the guard;
            6. top hall reached 11 → 25 of 40;
            7. leader 86.0 → 100.7 s.
        2. `npc-replay-quarry-to-keep`:
            1. The leader alone: 1 → 0 handovers onto another level, 54.7 → 56.7 s.
            2. The group with the stored settings: stuck spells 32 → 26, lost 6 → 3, 0 falls.
            3. The group with the smoke test's settings: 0 stuck spells, 0 lost.
    4. **Three regressions found and fixed on the way** (each deterministic, checked against `next` twice):
        1. With plain appending, `npc-jagged-straight-collision-on` failed: the leader walked back to a corner zig it was past, into its followers.
        2. With the join cut ahead to any straight-walkable waypoint within 3 blocks, `npc-stairhouse-group` (off and on) failed: L5's corner clearance was skipped.
        3. With "passed" judged by projection only, `npc-jagged-straight` failed: a row stayed 0.6 short of its slots and the group waited out its 20 s settle (#636).
    5. CI: `build` and `paper-boot` (50 scenarios) green on `a30ac085` (runs 43988727914, 43988727937).
    6. Known reds: none. Codex: at its usage limit (said on #64).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the NPC is on its list.* Chosen: the service keeps the list and estimates the index itself, nearest in 3D, never back (`Trail`). Alternatives: (a) a `waypointIndex()` on `NpcMover` read from Citizens (a port change, and Citizens' navigator does not expose it cleanly); (b) the follower's line index (it knows the line, not the bridged waypoints).
    2. *Handover distance.* Chosen: keep 4 blocks, now in 3D along the waypoints left. Alternatives: (a) hand out only at the list's end (a stop at every join); (b) a new key (not needed, prompt: no new key unless needed).
    3. *What "onto another level" measures.* Chosen: the next waypoint the NPC walks to after a handover, on the list it was given. B1's measure stays in the report. With 3D handovers, a correct stretch going up the next flight is a flight above the NPC before it gets there, so B1's measure would count correct handovers. Alternatives: (a) B1's measure as the check (it would fail correct behaviour); (b) hand out only within 2.5 blocks of rise of the end to satisfy it (the stop at every join again).
    4. *Joining at the feet.* Chosen: drop only waypoints already passed (beyond along the next step and no further from the next waypoint). Alternatives, both tried: (a) keep everything (failed `npc-jagged-straight-collision-on`); (b) cut ahead to the furthest straight walk within 3 blocks (skipped corner clearance, failed `npc-stairhouse-group`).
    5. *Unbridgeable step.* Chosen: cut the list before it, walk to the cut, then a local leg to the waypoint after the step, then restart the line where the NPC stands. Only steps from the feet are checked when the NPC is on the ground (a jump or fall mid-air is not a gap). Alternatives: (a) a local leg at once from wherever the NPC is (it would skip the walkable part); (b) a replan (heavier, same result).
    6. *A leader's fall.* Chosen: 1.75 blocks below the lower of its path point and the one before, path frozen up to 30 s, then as before. Alternatives: (a) the nearest line point instead of the path (on stacked flights the flight below is on the line); (b) no time limit (a leader that never comes back would freeze its group); (c) the engine's vertical speed (NaN on some engines).
    7. *Lost followers in the replay.* Chosen: report-only with the cause and proposal on #673. Alternatives: (a) fail on them (the replay would stay red for a cause outside B2); (b) fix slot heights here (B4's scope, not small).
6. **Out of scope, noted.**
    1. The half-block stair follower failure (item 1.7): proposed for B4 on #673.
    2. The line's own zigs on the jagged straight (corner clearance on a 3-wide road) are walked now. Before, a handover cut them. Not filed; noted for B4's look at waypoint heights and shapes.
    3. #636 (a follower just short of its slot never settles) showed up again in the third regression; not changed here.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. The smoke test on `quarry-to-keep` with the group of 20 and the singles (plan § 4c.4 developer test) after B2 is merged, preferably after B3 and B4.
    3. Review the decisions above, mainly 5.3 (what "onto another level" means now) and 5.7.
9. **Notes for later links.**
    1. B3: the climb still runs the crowd. A turn dropped by the guard without a fall stays report-only (`ClimbWatch.staleTurns`). B3 can make it a check.
    2. B4: start from the #673 comment. The replay's lost followers are the check to turn on (`NpcSnapshotReplayScenario`, the comment at the lost check).
    3. `npc-jagged-straight` (collision off) is sensitive to the leader's final approach because of #636: a group can wait 20 s for a follower 0.6 short of its slot, against the scenario's 30 s.

### 4.19 B4 — Waypoints and group slots at the real stair heights; jumps by upward speed (#673)

1. **Scope done** (prompt § 2, plan § 4c.8 item 2). Behind `npc.navigation.enabled` (off by default); no new key.
    1. **Waypoints at the walking surface** (knk-core `NavGeometry.onSurface`, `NavWorld.surfaceY`; knk-paper `BukkitNavWorld.surfaceY`). Every list handed to `NpcMover.follow` goes at the top of the floor block's step: the box that spans the whole cell.
        1. A bottom slab or an upright stair goes at half a block.
        2. An upside-down stair or a full block goes at a whole block.
        3. A path block goes at 0.9375.
        4. Where two waypoints, or the feet and the first waypoint, rise more than a step (`STEP_UP` 0.6), the cell on the line whose surface lies between them goes in.
        5. Planning, `Trail` and the handover keep `floor + 1`, as B2 measured them.
    2. **Group slots at the surface.** The follower lists go through the same rule, so a slot on flight 5 is at feet 72.5, not 73.
    3. **Recovery's point ahead on a half-block stair.** `NavGeometry.jumpFits` counts a rise of at most a step at the surface as no jump, so the low-headroom rule no longer refuses half-block steps under the flight above (`PathTargets.ahead`). Recovery and rejoin take the floor from the feet with `NavGeometry.floorYOf`: feet 72.5 stand on the block at 72, not 71.
    4. **A follower at its slot's point is settled** (`NavGroup.atSlotPoint`, `SLOT_REACHED` 1.0). Once the leader's trip has ended, a follower within a block across of its slot's point and less than a block above or below it at the surface is settled: an open spell ends as freed, and it is not lost.
        1. The cause, from a diagnostic added to the spell line: all lost followers stood 0.46–0.95 blocks from the same slot point on flight 5 (real 1409 72 −542), half a block under it, but 2–6 blocks behind it along the group path.
        2. The group path passes there more than once, so their place on the path was the earlier pass.
        3. They were sent round the loop and stalled. Their spells ran to `no point ahead on its floor`, because the point ahead must lie 3 blocks along the path before the slot. They ended lost.
        4. This is the "settled" part of B2's proposal on #673.
    5. **Jumps by upward speed** (knk-core `JumpDetector`: 0.3 blocks per tick upward, a jump takes off at 0.42; without the engine's speed, the rise per tick off the ground). It is used in `/knk npc nav trace` (`JUMP`) and in `ClimbWatch`.
    6. **The engine's stair hops told apart** (`ClimbWatch.stairHopsIn`). Citizens uses Minecraft's move control. It jumps in two cases:
        1. A target more than 0.6 above the feet within a block. Waypoint heights are about this case.
        2. Whenever the block at the feet has a collision top above them: on a stair's step, under its upper half. No waypoint height removes this one.

        A jump whose take-off position stands inside a stair block below its top counts as a stair hop and is reported apart.
    7. **Checks.**
        1. `npc-replay-quarry-to-keep` fails on a lost follower, with their run-log lines in the reason, and reports where each stuck spell opened.
        2. `npc-stairhouse-climb` fails on a jump toward a waypoint on the flights and their entries.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-b4`: 8 commits, from `4f91ce87` to head **`2a261289`** (base `next` `36ea2da0`).
    2. knk-workspace `claude/npc-movement-b4`: head **`73160c65`** (base `next` `a8e77d7d`).
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#65 (`Part of #673`).
    2. PandiO/knk-workspace#694 (`Closes #673`).
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `36ea2da0`: core 2987, api-client 344 (2 skipped), paper 2885 (18 skipped).
        2. Result on `2a261289`: core 3004 (+17), api-client 344, paper 2891 (+6). 0 failures.
        3. New tests:
            1. `NavGeometrySurfaceTest` 10: floor under feet, slab top, full block unchanged, idempotent, no floor, list unchanged, half-block stair rises half a block a step, half step under low headroom, the step between two waypoints, the step from the feet.
            2. `JumpDetectorTest` 5.
            3. `PathTargetsTest` +1: the point ahead up a half-block stair under a low flight.
            4. `NavGroupTest` +1: slots on a half-block stair are sent at the slab's top.
            5. `BukkitNavWorldSurfaceTest` 6.
    2. Scenarios: CI only. Locally Citizens could not load its Adventure libraries (Maven Central answered 429 in this container). Pre-seeding them from a mirror was refused by the session's permission classifier, so it was not done. The CI log artifacts were read instead.
    3. CI on `2a261289`: `build` green; `paper-boot` green on the push run 44008785404 and the PR run 44008842004 (50/50). Six `paper-boot` runs in all, while iterating. Run 3 failed on purpose with the new checks before the slot-point fix.
    4. **Before (B2's numbers on `next`) → after (final head; the run before in brackets).**
        1. Replay, group of 20, stored settings:
            1. Lost: 3 → **0** (0).
            2. Stuck spells: 26 → 6 (4).
            3. Where they opened: 4 on the street at the start (1436 42..43 −512) while the group forms up, 3–7.75 behind their slots; 2 on flight 5's loop, 0.96 from the slot's point.
            4. Crowd: longest queue 1, nothing let go.
            5. 0 falls, 0 handovers onto another level. The leader arrives in 71.1 s.
        2. Replay, group, smoke test's settings: 0 lost, 0 stuck, 0 falls (as with B2).
        3. Replay, leader alone (both configurations): 0 jumps toward a waypoint, 1–2 engine stair hops, 57.6 s.
        4. Climb (group of 20 with 20 singles):
            1. Jumps toward a waypoint on the flights and their entries: **0**. All 160 jumps are engine stair hops.
            2. Falls, handovers onto another level, stuck spells and lost followers: 0.
            3. The leader arrives in 76.2 s (B2: 100.7).
        5. The steps on the way, for the record:
            1. Slabs at their surface only: climb 328 jumps at climb places, all kinds; replay lost 3, stuck 16.
            2. Stairs at their step: climb 84 jumps, every one an engine stair hop.
            3. The slot-point rule: replay lost 4 → 0.
    5. Known reds: none. Codex: at its usage limit on both PRs (said on each).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the surface height is applied.* Chosen: only on the lists handed to the mover (`NpcMover.follow`). Planning, `Trail`, the handover and the group path keep `floor + 1`. Alternatives:
        1. (a) Surface heights everywhere in planning. Every `blockY() - 1` floor rule would read a slab's block as the one below: a large, risky change.
        2. (b) In the Paper mover only (`CitizensNpcMover.follow`). Not testable in knk-core, and the engine-free logic would sit in the adapter.
    2. *A stair's height.* Chosen: its step (the box that spans the cell, 0.5). Alternatives:
        1. (a) The highest box under the body's footprint (1.0 at a stair's middle). Tried in the first runs: the move control jumps for a target a whole block up within a block.
        2. (b) The lowest box (wrong for upside-down stairs).
    3. *Steps between waypoints.* Chosen: insert the in-between surface cells on the line where two waypoints, or the feet and the first, rise more than 0.6. Alternatives:
        1. (a) Leave sparse waypoints (the jumps stay).
        2. (b) Resample every list to one point per block (many more waypoints for every NPC).
    4. *Followers lost on flight 5.* Chosen: once the leader's trip has ended, a follower at its slot's point (within 1 block across, less than 1 up or down: Citizens' own default arrival margin) is settled. Alternatives:
        1. (a) Fix the group path's loop on flight 5. Its cause is upstream (the leader's path), and the stall comes from judging along the path.
        2. (b) Let `PathTargets.ahead` aim at the slot itself when it is closer than 3 blocks. That is a leg into a place it already stands at.
        3. (c) The same rule while the leader walks too. It would stop followers that should keep walking past their slots.
    5. *What counts as a "real jump".* Chosen: a jump by upward speed that does not take off from a stair's step. The engine's stair hops are reported, not failed. Alternative:
        1. (a) Fail on every jump. The climb could never pass: the hop is vanilla move control behaviour that no waypoint changes.
    6. *Jump threshold.* Chosen: 0.3 blocks per tick upward (a jump takes off at 0.42, then 0.33). Alternatives:
        1. (a) 0.4 (the second tick of a jump could be missed when the first is skipped).
        2. (b) The old rise > 0.2 (counts half-block steps).
    7. *Where the replay checks jumps.* Chosen: the climb fails on jumps toward a waypoint; the replay reports them. Alternative:
        1. (a) Fail the replay too. 56 remain with the smoke test's settings; cause not established, #695.
    8. *Lost followers' reason.* Chosen: their run-log lines go into the failure text, and the spell line logs where the follower stands against its slot. Alternative:
        1. (a) Rely on the NPC log files (not uploaded by CI).
6. **Out of scope, noted.**
    1. **#695** (filed): with the smoke test's settings, the replay's group jumps toward a waypoint at the hall entry's stair (1412 50 −495), 56 in the last run, report only. Guess: Citizens moves on to the next waypoint within its 1-block margin and passes the step's waypoint.
    2. **The climb's crowd releases** (B3, #672): the 30 s guard let 0, 3, 3, 3, 0 and 6 queues go over the six runs. No fall, no dropped turn; longest queue 18, longest wait 30 s.
    3. Docs follow-ups for the docs session:
        1. `docs/architecture/npc-navigation.md`: the surface rule and the slot-point settle.
        2. The admin guide: the trace's `JUMP` column.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. The smoke test on `quarry-to-keep` (plan § 4c.4) after B4, and B3 if it runs. Watch the rear rows on flight 5 settle in place, and no hop at the flight entries apart from the stair steps' own.
    3. Review decisions 5.1, 5.4 and 5.5 above.
9. **Notes for later links.**
    1. B3: the climb shows crowd guard releases without a fall (item 6.2), varying per run. `ClimbWatch.staleTurns` stays empty (no turn is dropped), so the release is the crowd's own `let go` counter (`crowd().overdue()`). Look at whether the holder of the turn stands on another flight in 3D when the guard fires. Make it a check once fixed.
    2. The replay's spell line (`... stuck at x y z, n blocks behind its slot at ... (d away)`) and the report's `stuck spells opened` show where a group stalls; real coordinates = scene coordinates − (scene origin) + (1391, 36, −559).
    3. The 4 spells at the start (1436 42 −512) happen while the group forms up from its spawn bunch; not looked into.

### 4.20 B3 — Crowd turns judged in 3D; the 30 s guard counts from the last entry (#672)

1. **Scope done** (prompt § 2, plan § 4c.8 item 3). Behind `npc.navigation.enabled` and `crowd-awareness` (both off by default); no new key.
    1. **Diagnostic first** (knk-core `CrowdControl.releases()`, `longWaits()`; `ClimbWatch.releases`, `longWaits`). Each release by the guard records where the NPC let go stood, the place (its middle and its cells' feet levels) and every holder of a turn there in 3D. That covers height above the place, progress, distance across, whether it blocks, whether it counts as passed and which followers keep its turn. Each waiting ticket counts what held it (an oncoming holder, an earlier waiter or the spacing rule) with that NPC's position and level. The climb and the replay report both lines.
    2. **Cause 1, 3D** (CI `paper-boot` 44012059768 on the unchanged rules, climb let go 6). All 6 releases were at flight 1's top (real 1410 54 −500, a one-cell place). The only holder was the group's leader `knk-sc-32000` on the landing above flight 2 (1409 59 −491 and 1409 60 −492), 5.5 to 6 blocks above the place. Horizontally its progress was −8.2, so the spacing rule ("the one ahead is a block into the place") read it as just inside the entry. Its followers in the place (1409 54 −499, 1410 55 −501) kept its turn. The singles going the same way waited behind a leader a flight up. No fall and no oncoming NPC was involved.
    3. **Fix 1: a place has a floor** (`CrowdControl.Place.levelGap`, `LEVEL_GAP` 1.5). The floor is flat, or a flight's slope fitted to the cells' feet levels along the axis (at most 1 per block). Before and after the cells the band spans the end's level and the slope carried on for up to 4 blocks, so landings and the flight's own steps count. Feet 1.5 or more off the band are on another level: a step (1) or a jump (1.25) still counts, a floor stacked 3 or more blocks away does not.
        1. A holder on another level has passed: its turn ends unless a follower on the place's floor still keeps it.
        2. A holder on another level never stops a waiter of its own direction (spacing). It stops one of the other direction only while a follower of its turn is still in the place.
        3. A follower on another level keeps no turn.
    4. **Cause 2, not 3D** (CI 44014280706 on `a775efc4` and locally: let go 3, the same three). Every NPC that held them stood on the place's floor (levels −0.5 to +1.0): the 18 singles queued in single file at the same one-wide top, each going once the one ahead was a block into the place. The queue drained at about 2 s per NPC, within M4's own bound of 3 s per NPC that went first. The last three passed 30 s since their arrival while it kept moving.
    5. **Fix 2: the guard counts from the last entry.** A queue lets an NPC go after 30 s in which nobody entered the place (from its arrival or the last entry, whichever is later). A place nobody enters still lets the queue go after 30 s. `longest wait` stays counted from arrival. Log line: "… waited 30 s at a narrow place without the queue moving: goes".
    6. **Check.** `npc-stairhouse-climb` fails on any NPC let go by the guard, with why.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-b3`: 3 commits, `3e7d70bb` (diagnostic), `a775efc4` (3D), head **`89eeb3eb`** (guard; base `next` `a3f0ebae`).
    2. knk-workspace `claude/npc-movement-b3`: head **`bcf7a3d9`** (base `next` `0664b1ee`).
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#66 (`Part of #672`).
    2. PandiO/knk-workspace#696 (`Closes #672`).
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `a3f0ebae`: core 3004, api-client 344 (2 skipped), paper 2891 (18 skipped).
        2. Result on `89eeb3eb`: core 3011 (+7), api-client 344, paper 2891. 0 failures.
        3. New knk-core `CrowdControlTest` cases (+7):
            1. A queue that moves is no deadlock (and the guard still fires once nothing moves for 30 s).
            2. A holder a floor above or under the place has left its turn.
            3. One that fell under it too.
            4. A step or a jump keeps the turn.
            5. No queue behind a leader on the floor above (the oncoming one still waits while its follower is inside).
            6. A follower a floor up keeps no turn.
            7. A flight's place rises with its steps; flights 3 and 8 blocks above are another level.

            The guard test also checks the release record.
    2. Scenarios.
        1. CI `paper-boot` on `89eeb3eb`: push run 44017052199 50/50, and the PR run 44019311124 50/50 (climb let go 0, 76.2 s).
        2. Local: Paper 26.3 b205 with Citizens b4269 (Citizens loaded its libraries this time). The climb alone three times, and all 27 `npc-*` scenarios once (27/27).
    3. **Climb, queue let go by the 30 s guard.**
        1. B4's six runs: 0, 3, 3, 3, 0 and 6.
        2. Diagnostic on the unchanged rules: 6 (cause 1).
        3. Fix 1 only: 3 (cause 2), in CI and locally.
        4. **Final head: 0** (CI push run and three local runs).
        5. Longest queue 18, longest wait 30.0 → 36.0 s at 2.1 s per NPC ahead.
        6. Falls, handovers onto another level, jumps toward a waypoint, stuck spells and lost followers stay 0. The leader arrives in 76.2 s; 173 engine stair hops (report only, B4 decision 5.5).
        7. The local runs give the same numbers each time (76.2 s, 18, 36.0 s).
    4. **Replay `npc-replay-quarry-to-keep`: unchanged.** The diagnostic run on the old rules and the local run on the final code give the same numbers: nothing let go, longest queue 1, 0 lost, 0 falls. The group's 6 stuck spells on the stored settings (street start and flight 5, as B4) are unchanged. So are its jumps toward a waypoint (report only): 3 on flight 2 with the stored settings, 56 at the hall entry with the smoke test's (#695).
    5. M4's crowd scenarios pass (`npc-doorway-crowd` and its collision-on twin 1.5 s per NPC ahead, `npc-door-column` 2.0 s, nothing let go).
    6. Known reds: none. Codex: at its usage limit on both PRs (said on each).
5. **Decisions (DESIGN § 4.3).**
    1. *How "the place's own level" is judged.* Chosen: a floor fitted to the place's cells along its axis (flat or a flight's slope), with a band from the ends' level to the slope carried on 4 blocks, and 1.5 blocks off it as another level. Alternatives:
        1. (a) A fixed band around the place's first cell (`cy`). Wrong on a flight: the far end of a 4-step place is 3 blocks up.
        2. (b) 3D distance to the nearest cell. A holder on the flight beside a hairpin landing is close in 3D but on its own level; a queue spot below the flight is far.
        3. (c) Interpolating the route's own waypoint heights. The crowd code has no route, only the NPC's way ahead.
    2. *`LEVEL_GAP` 1.5.* Chosen: a step (1) and a jump (1.25) count, a floor stacked 3 or more blocks away does not. Alternatives:
        1. (a) 1.0 (a jump on a stair would read as off the floor and end the turn).
        2. (b) 2.5 (the climb's level measure). A flight 3 blocks over a narrow passage would still count.
    3. *A holder off the floor whose followers are in the place.* Chosen: its turn is kept for them (they are the column), but it stops nobody of its own direction. Alternatives:
        1. (a) Release it at once. Oncoming NPCs would meet its followers in the place.
        2. (b) Keep the old behaviour. That is cause 1.
    4. *Cause 2: the guard measured from the last entry.* Chosen: the 30 s (developer decision, 4c.4 decision 3) is kept and counted while the queue does not move, which is what a deadlock guard is for. The M4 decision text is annotated, not rewritten. Alternatives:
        1. (a) A longer `MAX_WAIT_TICKS` (60 s). It only moves the limit: a longer queue fails again, and a real deadlock waits longer.
        2. (b) Single-file entry: go once the one ahead is a block ahead of you, not a block into the place. It changes the developer's turn rule, and throughput is not the fault: 2.1 s per NPC is within M4's 3 s bound.
        3. (c) Propose a follow-up instead. The prompt says to fix it here when it is in the crowd code.
    5. *Waiters off the floor.* Chosen: not judged by level (unchanged). Alternative:
        1. (a) Drop a waiter's ticket when it leaves the floor. A long queue's spots lie on the steps below the place, so that would drop real waiters (known limit, plan 4c.8 item 3.7.2).
    6. *Diagnostics kept in production code.* Chosen: the release and long-wait records stay (20 each, cleared with the counts, read by the scenarios). Alternative:
        1. (a) Remove them after the fix. The next guard release would again come without a cause.
6. **Out of scope, noted.**
    1. The replay's 3 jumps toward a waypoint on flight 2 (1415 57 −494, 1414 56 −498) with the stored settings are there before and after this link. Report only; noted on #695, which covers the hall entry's 56 with the smoke test's settings.
    2. Docs follow-ups for the docs session: `docs/architecture/npc-navigation.md` (a place's floor, the guard from the last entry).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. The smoke test on `quarry-to-keep` (plan § 4c.4) after B3, with `crowd-awareness` on. Watch the crowd at flight 1's top (1410 54 −500): a long single file drains without "… without the queue moving: goes" lines.
    3. Review decision 5.4 (the guard counted from the last entry changes how a developer-decided rule is read) and 5.2.
9. **Notes for later links.**
    1. `why the guard let them go (B3)` and `waits of 10 s or more (B3)` in the climb and replay reports name every holder and blocker in 3D. Use them before guessing at a crowd fault.
    2. Local scenario runs worked in this container (Citizens' libraries loaded). `tools/paper-boot/boot-test.sh` with `knk scenario run <name>` (a local copy that replaces `run all`) runs one scenario in about 4 minutes; `npc-*` runs 27 in about 12.

### 4.21 B5 — A group's shaped path kept on the walk on stacked flights (#699)

1. **Scope done** (prompt § 1, sub-issue #699). Behind `npc.navigation.enabled` (off by default), and only with `group-formation-keeping: elastic` or `plaza-lines`; no new key.
    1. **Reproduced on the real blocks.** `npc-replay-quarry-to-keep` now replays the snapshot of 2026-11-17 19:34 (with the gate doors). With the stored settings (the developer's: `elastic`, `crowd-awareness` on, `collidable` off) its group of 20 walks on to the route's end in the keep (1421 85 −516), as the developer's did, so the leader goes on past the flights while the rear ranks still climb them. On `next` every one of the 19 followers left its lane at flight 5's top (1410 74 −537) and took an own leg back: 21 in all. The scenario passed before only because it did not look.
    2. **Cause.** An `elastic` group (or one with `plaza-lines`) builds its path from corridor-shaped line points (`NavGroup.shapedLinePoint`, the route line pulled straight in 2D). A dump of the group path: from mid flight 5 (1410.5 72 −541.5) its next point was the far end of the landing above (1415 74 −536.4); the flight's top and the landing were missing. A log of each shaped point against the line's own point showed why: two shaped points lay over the stairwell (no floor near the path's last floor, so `GroupPath.addSnapped` repeated the point before), and the next eight all projected onto the landing's far end. A follower at the flight's top was judged against a path point 5 blocks across the stairwell (more than its lane allows), so it was off its lane. Where the shaped line lands on the hall floor beside a flight (the hall at feet 66 under flight 4's first steps), the path and the lanes run a level below the flight: the developer's step 3 log has slots at 1417 66 −538 there.
    3. **How the leader got a flight above.** It did not walk wrong: the leader went on along its line while its followers, judged against the broken path, stood or walked back down. With `group-regroup-blocks` 24 it waited on the passage right above flight 4 for a follower 24 or more blocks behind (along the path), timed out after 30 s, walked a tick and waited again, for 4 minutes.
    4. **Fix** (knk-core `GroupPath.addShaped`, used by `NavGroup.trackLeader`). A shaped point goes into the group path only where it has a floor near the path's last point, at most a block above or below the floor of the line's own point, and a straight walk (`NavGeometry.straightWalkable`, the body's width) leads to it from the path's last point. Otherwise the line's own point goes in (`addSnapped`, as without shaping). Generic: no coordinates, any stacked stair, landing or ramp.
    5. **Checks.** The replay's group fails on an own leg back from off the lane on the flights and landings (`NpcMovementScene.climbPlaceAt` > 0) and on a looping follower (three or more own legs back from one block), and reports both (`followers off their lane on the stair house (B5)`, `looping followers (B5)`).
    6. **Snapshot.** `trim_snapshot.py IN OUT 1391 36 -559 1454 96 -480`, as B1 (30 chunks, 370,602 bytes); nothing else changed. `SnapshotReplayTest` updated (plugin `e69dba6a`, 101 line points, gate doors recorded).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-b5` (base `next` `e69dba6a`): `938b775e` (fix and unit tests), `d402d865` (replay), `6b186840` (test update), head **`6b186840`**.
    2. knk-workspace `claude/npc-movement-b5` (base `next` `35005d6b`): head **`33add9f8`**.
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#67 (`Part of #699`).
    2. PandiO/knk-workspace#716 (`Closes #699`).
4. **Tests, baseline → result.**
    1. `./gradlew build -x deployToDevServer`: baseline on `next` `e69dba6a` core 3011, api-client 344 (2 skipped), paper 2891 (18 skipped); result core 3015 (+4), api-client 344, paper 2891; 0 failures.
    2. New: `GroupPathTest` +4 (a shaped point over the stairwell gives way to the line's own point; one on the hall floor two blocks under the step gives way; one across a void on the same floor gives way; one on one floor with a straight walk is kept). Three fail on the old code.
    3. Scenarios, locally (Paper 26.3 b205, Citizens b4269, `--npc-navigation`).
        1. Old core with the new checks: `npc-replay-quarry-to-keep` **fails** (21 own legs back from off the lane, all at flight 5's top).
        2. This branch: **50/50** in 17 min 16 s.
        3. Replay group to the route's end, stored settings: off the lane 21 → 0, looping 0, lost 0, leader 123.8 → 105.5 s, stuck spells 4 → 4 (on the street while it forms up, as since B4), jumps toward a waypoint 4 → 4, falls 0.
        4. Replay group, the 2026-11-16 smoke settings (`levels`): 0 off the lane, 0 lost, 0 stuck, 70.5 s; 63 jumps at the hall entry (#695, report only; 56 in B4's run).
        5. `npc-stairhouse-climb` unchanged (76.2 s, 0 falls, 0 let go, 0 stuck, 0 lost).
    4. CI: knk-plugin#67 on `6b186840`: `build` and `paper-boot` (50 scenarios) green on the push run (44178102216, 44178102371) and the PR run (44178163338, 44178163361). knk-workspace has no docs CI.
    5. Codex: at its code-review usage limit on both PRs (said on each); finished without its review.
5. **Decisions (DESIGN § 4.3).**
    1. *Where to fix.* Chosen: where shaped points enter the group path (`GroupPath.addShaped`), so lanes, slots, rejoin targets and the off-lane judgement all see a path on the walk. Alternatives: (a) make the off-lane check and the follower's place on the path 3D-aware (they were right: the path was wrong); (b) turn shaping off for groups on stairs (loses corridor steering's wall clearance for groups everywhere a flight is near); (c) fix `CorridorShaper` to shape in 3D (the shaper serves the leader alone too, which passes; larger and riskier).
    2. *Which shaped points stay.* Chosen: a floor near the path's last point, within a block of the line's own point's floor, and a straight walk from the path's last point. Alternatives: (a) the very same floor block as the line's own point (tried: refused shaped points on the hall-entry stair, jumps toward a waypoint 4 → 35, stuck spells 4 → 15); (b) only "has a floor" (keeps the jump across the stairwell to the landing's far end, which has a floor).
    3. *A refused shaped point.* Chosen: the line's own point, snapped as without shaping. Alternative: (a) repeat the point before (today's fallback; that is what skipped the flight).
    4. *Reproduction.* Chosen: the replay's group to the route's end with the stored settings, from the same street start. Alternatives: (a) start further back, past the south gate's plaza, like the developer's group (tried: the fake road's there-and-back loop is walked the wrong way round from there, a harness quirk, known limit 4c.8 item 4.7.4); (b) `npc-stairhouse-climb` (its schematic has no hall floor under flights 4 and 5).
    5. *The check.* Chosen: fail on any own leg back from off the lane on the flights and landings, and on three or more own legs back from one block anywhere (looping). Alternatives: (a) only looping (on `next` the replay has 21 off-lane legs but no loop, so it would pass); (b) any own leg back anywhere (the street's forming-up spells would fail it).
    6. *Group walk length.* Chosen: `GROUP_TICKS` 240 s for both configurations (the walk to the keep takes 105–124 s). Alternative: (a) a separate walk (3 more minutes of CI).
    7. *Evidence files.* Chosen: not copied into test resources (no test reads them; they stay on `evidence/smoke-2026-11-16`). Alternative: (a) copy the 2026-11-17 traces with `git add -f`, as B1 did for its traces (B1's were the climb's line).
6. **Out of scope, noted.**
    1. Lanes beside a flight's first step can still lie on a floor a block lower (the rule allows a block); plan 4c.8 item 4.7.2. No run showed it after the fix.
    2. A follower's place on the path is searched forward only (`NavGroup.WINDOW`); one that ends up a flight below its place is still sent an own leg back (item 4.7.3).
    3. The replay's fake road walks the there-and-back loop the wrong way from a start past the south gate's plaza (item 4.7.4); test harness only.
    4. #695 (jumps at the hall entry with `levels`): 63 in this run, unchanged by B5.
    5. Docs follow-up for the docs session: `docs/architecture/npc-navigation.md`, the shaped group path rule.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration.
    2. The retest: `docs/guides/npc-movement-smoke-test.md`, section "Link B5" (smoke test of 2026-11-17 steps 2 and 3 again, with the same keys).
    3. Review decisions 5.1 and 5.2.
9. **Notes for later links.**
    1. The replay's group now walks to the route's end; its report lines `followers off their lane on the stair house (B5)` and `looping followers (B5)` show where a group's followers leave the path.
    2. C1 (off-road legs): the snapshot box reaches y 96; the replay window ends at z −480 and x 1454 (a scene is at most 64 wide along x). A start north of the house needs the harness's loop fixed first (item 6.3).

### 4.22 C1 — Off-road starts and ends with the walk navigator's search, walked like the road line (#700)

1. **Scope done** (#700 with its second comment, decision 44; plan § 4c.8 item 5). Behind `npc.navigation.enabled` (off by default); no new key. No file in `core/roads/walk`, `paper/navigation` or `core/navigation/shape` changed; `ArchitectureGuardTest` green.
    1. **The walk search for every off-road leg.** knk-core port `OffRoadWalks`, used by `NpcNavigationService` for an off-road start, an off-road goal (also one right above or below the road's end) and a walk-only trip. Paper `NpcWalkPlanner` calls `WalkSnapshotService`, `WalkAccessFactory` (the NPC's access subject) and today's `WalkSearch` with `navigation.walk`'s budget. Its parts come from `KnKPlugin` through `NpcNavigationModule.setWalkSources` and `ScenarioServices.npcWalks`.
    2. **The road join by reachability.** The walk to the road arrives at any road point within 32 blocks along it, the first the search reaches. The walk to the goal starts at the road's end and is tried from up to 3 points further back (every 8 blocks). Both walks run at once.
    3. **Walked like the road line.** A found walk is spliced into the `RouteFollower` line: stretches, 3D handover, join from the feet, walking surface. A group's followers take it as their path. The walk's cells are marked as walked: no corridor shaping, no corner clearance (both cut a spiral in 2D), each on its own floor; the group path takes them unshaped too.
    4. **Hops stay the fallback**, counted (`offRoadWalks()`, `offRoadHops()`) and logged with the search's numbers and the walked cells.
    5. **The snapshot box** (`SnapshotBox.aroundRoute`) covers the route's from and to plus the margins.
    6. **Two fixes the tower needed:**
        1. `BukkitNavWorld.passable`: an open door or fence gate is no wall for NPC floors, headroom and "blocks a body". The tower's open door at 1405 104 −494 was a gap neither local leg could take.
        3. Waypoints through an open doorway (`CitizensNpcMover`, `BukkitNavWorld.openingCentre`): moved to the middle of the 13/16 opening the panel leaves; a body passes only within about 0.1 of it. CI found the jam once in two runs before the fix.
        2. The planner's body check: a found path is checked against the NPC's body rule; failing cells are closed and the search runs again, at most 4 times (an open trapdoor's panel). On an unloaded chunk the box is captured once more with a margin of 4.
    7. **Replay harness fix** (`AnvilRegion`). Minecraft 26.x writes non-default block states as `{id, properties}` palette entries. They were dropped from **every** replay since B1: stairs not facing north, top slabs, open doors. The quarry replay now places 122 011 blocks instead of 111 286, and still passes.
    8. **Scenarios** (four new, `MIN_SCENARIOS` 59 with the off-road chain's scenarios):
        1. `npc-replay-keep-tower`: the developer's snapshot trimmed to x 1391..1454, y 66..130, z −559..−480 (`keep-tower.zip`, 371 KB, keeps the goal and the spiral). A leader alone and a group of 20 in ranks, from the keep's road.
        2. `npc-offroad-detour`, `npc-offroad-upstairs` (two-turn spiral in a curtain wall, with a group of 5) and `npc-offroad-ravine`.
        3. `-Dknk.scenario.offRoadHops=true` leaves the walk search out (the before run).
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-c1` at **`b7608662`** (base `next` `c45c16bb`; `origin/next` merged in three times, up to `ce0f65ec` with the off-road chain's L3, L4 and L10 step 1; mechanical conflicts only: `KnKPlugin.initializeWalkPaths`, `MIN_SCENARIOS`, `PaperScenariosTest`'s count).
    2. knk-workspace `claude/npc-movement-c1` at **`bafe631f`** (base `next`, `origin/next` merged up to the same point; the changelog and the commands guide's header kept both sides).
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#71 (`Part of #700`).
    2. PandiO/knk-workspace#721 (`Closes #700`).
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `c45c16bb`: core 3033, api-client 344 (2 skipped), paper 2904 (18 skipped).
        2. Result on the final head `b7608662` (with `next` `ce0f65ec`): core 3111, api-client 344 (2 skipped), paper 2946 (18 skipped); 0 failures. C1's own tests are core +14 and paper +11 (one more for the doorway rule); the rest came with the off-road chain's links.
        3. New tests: `NpcNavigationOffRoadWalksTest` 10, `RouteFollowerWalkedTest` 3, `SnapshotBoxTest` +1, `NpcWalkPlannerTest` 8, `BukkitNavWorldBlocksTest` +1, `AnvilRegionTest` +1.
    2. **Scenarios, before (hops) → after** (local, Paper 26.3 b205, Citizens b4269):
        1. `npc-replay-keep-tower`: the leader **fails**, "stuck at 1406 85 −510: retries and replans used up" (the developer's 1405 85 −510) → **arrives in 53.4 s**, 0 stuck, 0 falls. The group of 20 arrives in 59.1 s: 0 lost, 0 stuck, every follower on the tower top (y 113).
        2. `npc-offroad-detour`: fails (order failed, stuck) → 28.3 s.
        3. `npc-offroad-ravine`: fails (order failed, stuck) → 19.1 s.
        4. `npc-offroad-upstairs`: 1 stuck spell, 50.1 s → 0 stuck, 41.5 s; the group of 5 in 42.0 s.
        5. Before = this branch with `offRoadHops`, so the harness fix and the open-door rule are in both runs.
    3. **The spiral fits the caps** (prompt § 3.2). Road end to goal: 172–180 blocks walked against a cap of 220–223 (`max-length` 144 plus `climb-allowance` 5 × 29 blocks of rise), 4 432 expansions against 20 000. It is no acceptance case for #698's NPC phase.
    4. Whole suite: 54/54 locally on the pre-merge head `87ccc5bd` (23 min with boot). CI on knk-plugin#71: on `ced61331` `build` green twice, `paper-boot` green once (44212713839) and red once (44212627665: the tower replay's followers jammed on the open door's panel, item 1.6.3). On `2a2e626f`: `build` (44218253937) and `paper-boot` with 55 scenarios (44218253973) green. On the final head `b7608662`: `build` (44225040650, 44225046762) and `paper-boot` with **59 scenarios** (44225040520, 44225046831) green, push and PR runs. Not #720 (the runs started after 01:00 UTC).
    5. Known reds: none. Codex: at its usage limit on both PRs (said on each); finished without its review.
5. **Decisions (DESIGN § 4.3).**
    1. *How a walk is walked.* Chosen: splice it into the route line, so B2/B4's handover, bridge and surface heights and the group path apply unchanged. Alternatives: (a) a waypoint list handed to the mover as one local leg (no handover, no group path); (b) the walk cut into hops (the bridge gaps today's hops have).
    2. *Walked cells unshaped.* Chosen: no corridor shaping or corner clearance on walk cells, own floor first. Alternatives: (a) shape them like road points (cut the tower's spiral and gave a 3.6-block gap); (b) B5's `addShaped` guard on the leader's stretches too (the shaper still pulls a 1-wide spiral off it).
    3. *Road join.* Chosen: one search with every road point within 32 blocks along the road as a goal, aimed at the router's snap; for the goal, up to 4 searches from the end and further back. Alternatives: (a) a search back from the goal (moves are not reversible: drops); (b) a new road plan from the reached point (a second router call for little gain); (c) more join points (larger box and cap).
    4. *The open-door rule in `BukkitNavWorld`.* Chosen: open doors and fence gates passable everywhere in NPC navigation. Alternatives: (a) only on walk cells (two body rules for one NPC); (b) leave it (the tower's door stays a gap; the engine leg failed there too).
    5. *Body check.* Chosen: check a found path on the main thread and search again with the failing cells closed, at most 4 times. Alternatives: (a) change the walk capture's passability (forbidden, `paper/navigation`); (b) scan the whole box on the main thread (too much work per leg).
    6. *NPC movement profile.* Chosen: the walk settings' with doors per the access profile, no ladders, no wading. Alternatives: (a) the player profile unchanged (Citizens' waypoint following does not climb ladders; water drowns NPCs, #490).
    7. *`walk-only-blocks`.* Chosen: unchanged at 64 (within the walk search's caps; the narrowed scope does not ask for it). Alternative: (a) 96, the players' start-leg reach (a default change for a case no test shows).
    8. *Scenario scenes.* Chosen: scenes enlarged until the before run fails on behaviour (Citizens' Minecraft search stops at 1 024 blocks), and "no stuck spell" as a check. Alternative: (a) only "the walk search planned it" (passes the hops version on behaviour).
    9. *Fixing `AnvilRegion` in this link.* Chosen: fix it, since the tower replay needs its stairs, and rerun the quarry replay (passes). Alternative: (a) a separate issue first (C1's proof would wait on it).
    10. *Doorway waypoints.* Chosen: the Citizens mover moves a waypoint in an open doorway to the opening's middle, from the block's collision boxes (one place every list passes). Alternatives: (a) treat open doors as walls again (the tower gap returns); (b) narrow groups to a column earlier at doors (lateral drift of 0.1 still jams); (c) a new `NavWorld` method (`core/navigation/shape` is the off-road chain's).
6. **Out of scope, noted.**
    1. A replan from inside an off-road walk plans the whole route again (the walk back to the road first); no run showed it after the fixes (plan item 5.13.3).
    2. A gate door on an off-road walk is not one of the route's gates for event replans (item 5.13.2).
    3. Docs follow-up for the docs session: `docs/architecture/npc-navigation.md`, `plugin-scenarios.md` (four scenarios, `offRoadHops`, the replay's `{id, properties}`), the admin guide's log lines.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration; `navigation.walk.enabled` stays true (it already must for NPC local legs).
    2. The retest: `docs/guides/npc-movement-smoke-test.md`, section "Link C1" (the tower route, an off-road start, a new snapshot).
    3. Review decisions 5.3, 5.4 and 5.10.
9. **Notes for later links.**
    1. E1: an off-road walk's cells are in the route line, so the recheck and the trespass guard look at them like road points.
    2. #698's NPC phase: hook long walks in at `OffRoadWalks` (the service needs no change); `NpcWalkPlanner` is the only caller of the walk search for NPCs.
    3. Replays made before this link lacked every `{id, properties}` block; numbers from B1–B5's replays were taken on that world.

### 4.23 E1 — Exit rules checked while NPCs walk, not only where a route is planned (#701)

1. **Scope done** (#701, decision 41; plan Phase 4 known limit 4). Behind `npc.navigation.enabled` (off by default); no new key. No file in `core/roads/walk`, `paper/navigation`, `core/navigation/shape`, `core/roads/route` or `core/regions` changed.
    1. **One rule, the router's.** `DomainEntryRule.of` returns a new `RegionRule`: the entry predicate as before, plus `mayLeave` and `exitDenied` for the regions the NPC stands in. They come from `DomainAvailability.exitDeniedRegions` over the shared `DomainAccessEvaluator`, for every domain type. The new default `AccessRules.regionRule(subject)` reads them. `StepCheck` judges one step: an entry before an exit, and the rule is asked for only when a step crosses a region border.
    2. **`NpcNavigationService`** (a leader or a single NPC):
        1. the recheck of the way ahead (`way ahead is closed by exit <region>`);
        2. `allowedPart` (the walk to the blocking element is cut at the edge, inside);
        3. `mayStand`;
        4. the trespass guard (`TRESPASS <npc> left <region> at x y z (…)`).
    3. **`NavGroup`**: follower lanes (`laneAllowed`), waypoints (`mayEnterAll`, `sendTrip`), `mayStand` and the follower guard. Exit verdicts are cached per set of regions stood in and cleared with the entry verdicts. Waypoints that leave a region mark the follower for the periodic recheck, as entering ones do.
    4. **Paper**: no code change. `NavigationAccess.mayEnter` already returns `DomainEntryRule.of(...)`, and road navigation's `accessRules()` passes the object on, so the exits arrive on a server. `NpcExitRuleAccessTest` pins this and the agreement with the router per profile.
    5. **Profile**: `bypass-domain-rules`, an allow list naming the region, and a domain whose rule does not apply to roads let the NPC leave (tested). The realtime and refresh paths wake NPCs as for entry: they are type-agnostic, and the scenarios drive both.
    6. **Scenarios** (`MIN_SCENARIOS` 59 → 61):
        1. `npc-exit-denied-leader`: an NPC alone, exit denied through realtime `EntityChanged`, allowed again through the cache-refresh path.
        2. `npc-group-exit-denied`: a group of 8 half inside, both ways through realtime.
        3. Helper `ScenarioDomainRules` (fake API, the plugin's map, `NavigationDomainChanges`, `DomainCacheRewarm`).
        4. `ScenarioNpcs.plan` answers BLOCKED from inside a region the NPC may not leave, as the router does (no other scenario denies an exit).
    7. **knk-workspace**:
        1. The changelog entry.
        2. Plan Phase 4 known limit 4 and the new developer test step 15 (exit denied mid-trip, a leader and a group half inside; automated parts tagged).
        3. The smoke test's "Link E1" section.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-movement-e1` at **`de1c8a6a`** (1 commit, base `next` `65c7d6d3`; `origin/next` unchanged at the PR).
    2. knk-workspace `claude/npc-movement-e1` at **`a827abc6`** (1 docs commit, base `next` `b0bd7f4a`).
3. **PRs** (base `next`, not merged).
    1. PandiO/knk-plugin#74 (`Closes #701`).
    2. PandiO/knk-workspace#725 (`Part of #701`).
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`.
        1. Baseline on `next` `65c7d6d3`: core 3111, api-client 344 (2 skipped), paper 2946 (18 skipped).
        2. Result on `de1c8a6a`: core 3126 (+15), api-client 344 (2 skipped), paper 2948 (+2); 0 failures.
        3. New tests: `DomainEntryRuleTest` 11, `NavGroupExitRulesTest` 4 (an NPC alone, a group of 16 half inside, the guard counting a follower carried out, the bypass), `NpcExitRuleAccessTest` 2; `PaperScenariosTest` updated for 61.
    2. **Before → after.**
        1. `NavGroupExitRulesTest` against `next`'s `NavGroup` and `NpcNavigationService`: 3 of 4 fail (the NPC "left Old Town at x=50.17"; follower npc-7 "left Old Town at x=50.01") → 4/4 pass.
        2. Scenarios, local (Paper 26.3 b205, the pinned WorldEdit, WorldGuard, Citizens b4269, `--npc-navigation`), with `next`'s walking checks in the jar: `npc-exit-denied-leader` FAIL ("left the district … furthest x …026.5") and `npc-group-exit-denied` FAIL ("knk-sc-4 left the district") → with E1: PASS (373 and 239 ticks), log check passed.
    3. CI on `de1c8a6a`: `build` green (134555657727); `paper-boot` (61) green (push run 134555658454, PR run 134561833704; `build` PR run 134561833367).
    4. Known reds: none. Codex: at its usage limit on both PRs (said on both).
    5. Local toolchain note: Maven Central answered an intermittent 404 through the proxy, which Gradle does not retry. A local retrying mirror in the scratchpad (`~/.gradle/init.d`) fixed it; nothing in the repos.
5. **Decisions (DESIGN § 4.3).**
    1. *How the exits reach the walking checks.* Chosen: `DomainEntryRule.of` returns a `RegionRule` and `AccessRules.regionRule` reads it, because the exits are the router's own and `paper/navigation` (the off-road chain's area) stays untouched. Alternatives: (a) a new `AccessRules.mayLeave` port answered in `NavigationAccess`, `PolicyFactory` and `accessRules()` (three edits in `paper/navigation`, which needs the coordinator's OK); (b) a second exit check in core over the map (ruled out by the brief).
    2. *A step's verdict.* Chosen: an entry is checked before an exit, and the rule is asked for only when the step crosses a region border, so a recheck that crosses nothing costs what it did. Alternative: (a) always build the rule (one more map lookup per region stood in, every check).
    3. *Trespass on exit.* Chosen: the same `TRESPASS` event and counter with the verb `left`, so `trespasses 0` covers both. Alternative: (a) a separate event and stats line (a metrics name and docs change for the same rule).
    4. *Periodic follower recheck.* Chosen: waypoints that leave a region mark the follower like entering ones, so a rule change without an event is seen for exits too (the lane is re-handed every `max(20, recheck-ticks)` while they do). Alternative: (a) entry only (exits would hold only through events).
    5. *Scenario road.* Chosen: the fake road answers BLOCKED from inside a region the NPC may not leave, as `DomainAvailability` does, or the leader's replan would find a route and walk out (the tolerated path). Alternatives: (a) the real router on a fake network (no network or API in a scenario); (b) followers only (the brief asks for a leader).
    6. *Paths in the scenarios.* Chosen: the leader's deny through realtime and its restore through the cache refresh, and the group both ways through realtime, so both paths are driven. Alternative: (a) `ScenarioNpcRules`-style fake data (does not exercise the plugin's realtime and refresh classes).
6. **Out of scope, noted.**
    1. Filed #724: `/knk cache refresh` sends its first event with the map empty, so held NPCs can cross a denied edge before the re-warm's answers arrive, and the guard does not count it. It is on `next` for entry today, and exit has the same parity. Probe: 7 held → 5 held after the refresh, 0 trespasses. It needs `paper/navigation` or a core change.
    2. `docs/guides/developer/ci.md` § 7.1 still says 50 scenarios (61 now); the admin guide's trespass line should name `left`. Both are for the docs sub-issue.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing in `config.yml`, no migration. Deploy and check the startup line `0.1.0+<sha>`.
    2. Plan Phase 4 developer test step 15 (or the smoke test's "Link E1" section): exit denied mid-trip on a real district through the web app, for a leader alone and a group half inside, then allowed again; once with `/knk cache refresh`. Post the stats and the log on #701.
    3. For review: decisions 5.1, 5.4 and 5.5.
9. **Notes for later links.**
    1. Ask `ports.rules().regionRule(subject)` (or `StepCheck`) for a step, not `mayEnter` alone, so exits hold.
    2. A fake `AccessRules` whose `mayEnter` is not a `RegionRule` allows every exit; use `DomainEntryRule.of` or `RegionRule.of(enter, exitDenied)` in tests that need exits.
    3. `ScenarioDomainRules` gives any scenario the realtime and refresh paths over a fake API.
