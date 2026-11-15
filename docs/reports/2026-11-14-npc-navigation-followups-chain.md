# NPC navigation follow-ups chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-14

**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358), links
[#519](https://github.com/PandiO/knk-workspace/issues/519) (L1),
[#520](https://github.com/PandiO/knk-workspace/issues/520) (L2),
[#521](https://github.com/PandiO/knk-workspace/issues/521) (L3),
[#522](https://github.com/PandiO/knk-workspace/issues/522) (L4).
**Charter:** [handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/NPC_NAVIGATION_FOLLOWUPS_CHAIN.md).
**History:** [first NPC navigation chain report](2026-11-13-npc-navigation-chain.md) (Phases 1–4 and #490 merged into
`next`; developer tests done 2026-11-14).

## 1. Waiting for the developer

1. Phase 4 test steps 9 and 10 for L2 (#520), on a plugin built from `next` `11e07d64` or later (steps on #520).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Design: corners, narrowed formations, toggle | #519 | Merged into next (2026-11-15, design approved by the developer) | knk-workspace `96f47820` → `next` `4a97fd3b` | PandiO/knk-workspace#546 | docs only (no CI); Codex at its usage limit | create_session session_01R1w2UwysEMwCYnxwCpkx3p (2026-11-15) |
| L2 Follower recheck and guard, no gate push | #520 | Merged into next (2026-11-15, by the manager session) | knk-plugin `651d8bff` → `next` `11e07d64`; knk-workspace → `next` `43a2328c` | PandiO/knk-plugin#31, PandiO/knk-workspace#536 | PR head green (build, paper-boot); `next` runs 43662028862, 43662028855 pending at the coordinator check | create_session session_01R1w2Ux2KpS7H3FidwDEZmp (2026-11-14) |
| L3 Wall-corner steering and recovery | #521 | Running | — | — | — | create_session session_01R1w2Uv1rEnwPko4Tq83xyL (2026-11-15) |
| L4 Narrowed formations, followers-finish-trip toggle | #522 | Not started (gate: L3 merged) | — | — | — | — |

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
