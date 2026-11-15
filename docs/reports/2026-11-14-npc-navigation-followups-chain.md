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
2. The L1 design questions (proposed defaults in L1's design, questions on #519 once L1 posts them); then the approval
   of the L1 design, which opens L3 and L4.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Design: corners, narrowed formations, toggle | #519 | Running | — | — | — | create_session session_01R1w2UwysEMwCYnxwCpkx3p (2026-11-15) |
| L2 Follower recheck and guard, no gate push | #520 | Merged into next (2026-11-15, by the manager session) | knk-plugin `651d8bff` → `next` `11e07d64`; knk-workspace → `next` `43a2328c` | PandiO/knk-plugin#31, PandiO/knk-workspace#536 | PR head green (build, paper-boot); `next` runs 43662028862, 43662028855 pending at the coordinator check | create_session session_01R1w2Ux2KpS7H3FidwDEZmp (2026-11-14) |
| L3 Wall-corner steering and recovery | #521 | Not started (gate: L1 approved and merged, L2 merged) | — | — | — | — |
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

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

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
