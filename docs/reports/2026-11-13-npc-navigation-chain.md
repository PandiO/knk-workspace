# NPC navigation chain — progress report

**Status:** Running (2026-11-13) · **Last updated:** 2026-11-13

**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358), links
[#360](https://github.com/PandiO/knk-workspace/issues/360) (L1),
[#359](https://github.com/PandiO/knk-workspace/issues/359) (L0),
[#361](https://github.com/PandiO/knk-workspace/issues/361) (L2).
**Charter:** [handoffs/NPC_NAVIGATION_CHAIN.md](../ai-agents/handoffs/NPC_NAVIGATION_CHAIN.md).

## 1. Waiting for the developer

1. **Phase 1 test and audit report on #359** (implementation plan, "Phase 1 → Developer test"; the steps are in `next`
   now). It opens L0, which runs after L2.
2. **Phase 2 test on the dev server** (implementation plan, "Phase 2 → Developer test", in `next`): one NPC, 50 NPCs
   on the stored route, the stair house (release gate). Deploy knk-plugin `next` (`50bf7ff7`), merge the
   `npc.navigation` block into the server's `config.yml` (YAML in knk-plugin#17 and the configuration reference
   § 4.27), `enabled: true` only for the test, Citizens build 4269 installed. Post the `stats` output and the run log
   on #360. What to look at in the stair house: block 4.1 § 8.3.
3. **Review of L1's agent decisions** (block 4.1 § 5, twelve entries); the ones that change behaviour: 5.1 (replan
   twice after the retries, then fail), 5.2 (walk-only trips up to 64 blocks, else fail), 5.5 (access profile
   fields; NPCs pass open gates only).
4. **Stair-house dump and trace** on #244 or #360, when available; L2 looks for them but does not wait.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 2: one NPC walks a K&K route | #360 | Merged into next 2026-11-13 (knk-plugin `50bf7ff7`, knk-workspace `424f1fa3`); #360 stays `status:in-review` until the developer's live test and the promotion of `next` | `claude/npc-navigation`: knk-plugin `49b5cedb`, knk-workspace `5c8587b` | [knk-plugin#17](https://github.com/PandiO/knk-plugin/pull/17), [knk-workspace#370](https://github.com/PandiO/knk-workspace/pull/370) | knk-plugin `build` green on `49b5cedb` (run 43398822498); knk-workspace has no CI | create_session session_01R1w2Uv2Ze28fr2rkqUz98C (`source_revision` `next`) |
| L0 Phase 1 follow-ups | #359 | Not started (gate: the developer's Phase 1 result on #359; L1 is merged; runs after L2, one link per repo) | | none | none | |
| L2 Phase 3: rules stay binding | #361 | In review (finished 2026-11-13; live test by the developer open) | `claude/npc-navigation`: knk-plugin `8df2d839`, knk-workspace `a05f7bf` | [knk-plugin#18](https://github.com/PandiO/knk-plugin/pull/18), [knk-workspace#375](https://github.com/PandiO/knk-workspace/pull/375) | knk-plugin `build` green on `8df2d839` (runs 43403427418, 43403523663); knk-workspace has no CI | create_session session_01R1w2Uvt1jBnAv84KX3hf7q (`source_revision` `next`) |

## 3. Coordinator decisions

1. **Rule set in force.** Chosen: the `next` branch model (links base on and target `next`, the coordinator merges a
   passed link into `next` with a merge commit, issues stay `status:in-review` until the developer promotes `next`),
   because the skill § 1.3 check passed on 2026-11-13: `.github/workflows/ci.yml` is on knk-web-api `origin/master`
   and on knk-web-app `origin/main`. Alternatives: (a) the old rules (base `main`, nobody in the chain merges), only
   if the check had failed.
2. **Heads at the first run (2026-11-13).** knk-plugin `main` and `next` `e8b651d1`, `claude/npc-navigation`
   `8b36a942` (2 commits ahead of `next`, 2 behind, merges cleanly); knk-workspace `main` `b18ff4a4`, `next`
   `17748b8b`, `claude/nice-feynman-pvy1j3` `90991c4a`. Push dry runs passed for knk-workspace `main` and knk-plugin
   `claude/npc-navigation`.
3. **Where the links' workspace docs go.** The binding documents are only on knk-workspace
   `claude/nice-feynman-pvy1j3` (no PR of its own; PR #235 covers its ancestor `claude/npc-behavior-model` against
   `main`). Chosen: L1 creates knk-workspace `claude/npc-navigation` from that branch's head, merges `origin/next`
   into it and opens a PR against `next`, because the charter's gate expects a knk-workspace `claude/npc-navigation`
   merged into `next`, the links must update the plan, and later links (started from `next`) then find the binding
   documents in their checkout. A trial merge of the branch with `next` conflicts in 7 files; 6 are files the branch
   does not change against `main` (take the `next` side), 1 is `guides/performance-metrics-and-capacity.md` (one hunk,
   keep both sides). The link checks that the PR's diff against `next` holds only NPC documents; anything else is a
   blocker. Alternatives: (a) links commit their docs on `claude/nice-feynman-pvy1j3` without a PR: breaks the "PR per
   changed repo" check and keeps the documents out of `next`; (b) a fresh docs branch from `next` with the files
   copied: loses the history and contradicts the standing-branch rule; (c) wait for the developer to merge the design
   branch: stalls L1 for a docs question that is reversible.
4. **L1's plugin PR also carries Phase 1.** Phase 1 (`83d2bba8`, `8b36a942`) has no PR and is not in `next`, so L1's
   PR against `next` shows Phase 1 and Phase 2 together (charter § 3.2 expected one link per PR). Chosen: accept it
   and have the PR say `Closes PandiO/knk-workspace#360` and `Part of PandiO/knk-workspace#359`, because everything is
   behind `npc.navigation.enabled` (off by default) and the developer's Phase 1 test runs on the same branch.
   Alternatives: (a) a separate Phase 1 PR merged first: Phase 1 is still waiting for the developer's test and this
   coordinator does not check work it did not start; (b) hold L1 until Phase 1 is merged: contradicts the charter
   gate "now".
5. **Overlap: Siege Survival chain** (`claude/siege-survival`, unmerged, `core/npc/` and `paper/npc/`). Chosen: not a
   blocker, as the charter § 3.3 says: navigation stays in `core/npc/nav/` and `paper/npc/citizens/`, `KnKPlugin`
   edits stay additive inside the NPC block, listener guards are one `isNpc` check at the top of a handler.
   Alternatives: (a) block L1 until Siege Survival merges: the claims are on different packages, so the merge stays
   mechanical.
6. **Tier labels.** `tier:1`, `tier:2` and `tier:3` existed at the first run (2026-11-13). Applied: #360 and #361
   `tier:3`, #359 `tier:1`. No alternative.

7. **Design docs into trunk, then trunk into `next` (developer, 2026-11-13; replaces decision 3's route).** The
   developer decided that the docs that sat on a feature branch before the implementation started are merged into
   `main` and `main` into `next`; everything changed since the implementation started follows the standard link
   route into `next`. Done by the coordinator: PR #372 merged `claude/nice-feynman-pvy1j3` at `aa6f171f` (the last
   commit before "implementation started") into `main` (`0f927155`), ten NPC doc files, `main`'s version kept for
   files the branch did not change; PR #373 merged `main` into `next` (`01bfb265`). The later commits on that branch
   (Phase 1 status, stair release gate, Phase 1 test steps, metric panels) and L1's own docs stay on knk-workspace
   `claude/npc-navigation` and reach `next` through L1's docs PR; L1 merges `origin/next` into that branch again.
   Alternatives: (a) merge the branch head `90991c4a`: it holds docs written after the implementation started,
   which the developer wants on the link route; (b) leave it to L1's docs PR (decision 3): superseded.

8. **L1 checked and merged (2026-11-13).** Skill § 6: block and heads match, both branches contain `next`, PRs
   knk-plugin#17 and knk-workspace#370 with the template, CI `build` green on `49b5cedb`, tests above the baseline
   (core 2507 → 2562, paper 2535 → 2570, 0 failures), scope within #360 and Phase 1 (outside the NPC packages only
   `KnKPlugin` +18 lines, the `WorldGuardRegionListener` guard with its test, `gradle.properties`,
   `build.gradle.kts`), flag `npc.navigation.enabled` false in the shipped `config.yml`, #360 `status:in-review`.
   Merged with merge commits: knk-plugin `50bf7ff7`, knk-workspace `424f1fa3`. Accepted as is: three docs files
   beyond the coordinator's list (L1 decision 5.12, essential docs). Small defects, not fixed: knk-workspace#370's
   body lacks the `---` / generated-by footer and both PR bodies use dashes inside template sections. No alternative
   to merging: tier:3 work behind an off flag merges once the checks hold (skill § 7.1).
9. **L2 before L0.** Chosen: start L2 (#361) now, because the developer's Phase 1 result is not on #359 and the
   charter § 2 says L2 then starts and L0 runs after it. Alternatives: (a) wait for the Phase 1 result: idles the
   chain for a tier:1 link.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Phase 2: one NPC walks a K&K route (#360)

1. **Scope done.**
    1. knk-plugin, knk-core `core/npc/nav/` (no Bukkit or Citizens types): `AccessSubject` port, `NpcAccessProfile`,
       `NpcAccessSubject`, `SubjectRegionAvailability`; `RouteFollower` (the road line one stretch ahead, floor
       continuity); `HopPlanner` (off-road and recovery hops, floor-snapped); `NpcNavigationService` (state machine,
       planning queue with `max-plans-in-flight`, bounded retries and replans, `NavigationResult` to the caller, the
       progress watchdog); `NpcSpawnQueue`; ports `RoadPlanner`, `LocalLegPreparer`, `LocalLeg`, `NavWorld`;
       `NpcMover.walkTo(target, leg)`. `NavigationSettings` got `hop-blocks`, `max-retries`, `no-route-wait-ticks`,
       `walk-only-blocks`; `NpcNavigationMetrics` got the events `stretch`, `unloaded_wait`, `examiner_leak`,
       `failed`.
    2. knk-plugin, knk-paper navigation: `PlayerAccessSubject`; `AccessSubject` overloads on
       `NavigationAccess.policyFor` / `gateAvailability`, `WalkAccessFactory.prepare`, `WalkLegPreparer.capture`
       (the `Player` versions are unchanged); `NavigationService.planRoadFor` and `walk()`.
    3. knk-plugin, knk-paper `paper/npc/citizens/`: `KnkBlockExaminer`, the rule-bound `CitizensNpcMover.walkTo`
       that removes and reports examiners Citizens adds on its own. `paper/npc/nav/`: `NpcLegPreparer`,
       `BukkitNavWorld`, `NpcNavRunner` (`/knk npc nav`), `NpcRouteStore`, `NpcNavLog`; `NpcNavigationConfig`
       (`spawns-per-tick`, `access-profiles`); `NpcNavigationModule` wiring; `config.yml` and `plugin.yml`.
       `KnKPlugin`: one changed line inside the NPC block. No listener changed.
    4. knk-workspace: branch `claude/npc-navigation` from `claude/nice-feynman-pvy1j3` `90991c4` with `next` merged
       in; Phase 2 status and developer test in the implementation plan; configuration reference § 4.27; commands
       guide; stress test guide (spike command → production command); metric panels; changelog draft.
    5. Inert while `npc.navigation.enabled` is false: `NpcNavigationModuleDisabledTest` starts the module with the
       shipped `config.yml` and no Bukkit server; any task, listener, Citizens call or world query would fail it.
2. **Commits and heads.** knk-plugin `claude/npc-navigation` at `49b5cedb` (Phase 1 `83d2bba8`, `8b36a942`; merge
   of `next` `432645f5`; Phase 2 `d216281c`, `f32f7ed1`, `49b5cedb`; base `next` at `e8b651d1`). knk-workspace
   `claude/npc-navigation` at `5c8587b` (merge of `next` `2dd2183`, docs `764d64d`, second merge of `next`
   `5c8587b` after the coordinator put the design documents into `next`; base `next` at `01bfb26`; the diff
   against `next` is 6 files).
3. **PRs.** [knk-plugin#17](https://github.com/PandiO/knk-plugin/pull/17) (`Closes #360`, `Part of #359`; shows
   Phases 1 and 2 together) and [knk-workspace#370](https://github.com/PandiO/knk-workspace/pull/370) (`Part of
   #360`; the earlier design documents reached `next` through #372 and #373), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`, Gradle on JDK 21, JDK 25 toolchain): baseline at
       `432645f5` core 2507, api-client 324 (2 skipped), paper 2535 (18 skipped), 0 failures; result at `49b5cedb`
       core 2562 (+55), api-client 324 (2 skipped), paper 2570 (+35, 18 skipped), 0 failures. CI `build` run
       43398822498 green on `49b5cedb`.
    2. knk-workspace: docs only; the links added were checked by hand.
    3. Known reds (also red on the base): none.
5. **Decisions (DESIGN § 4.3).**
    1. *What happens when the retries of a hop or stretch are used up.* Chosen: drop the route, wait
       `no-route-wait-ticks`, plan again from where the NPC stands, at most twice per order
       (`NpcNavigationService.MAX_REPLANS`), then `FAILED`, because NAV-17 says "bounded retries, then wait and
       replan" and DESIGN § 6 says "report a failed result; behavior owns the response": both hold this way.
       Alternatives: (a) `FAILED` right after the retries: stricter reading of § 6, but every hard stair spot would
       end the order; (b) replan without a limit (the spike): an order could loop for ever; (c) a config key for
       the replan limit: one more key nobody asked for, easy to add later.
    2. *A trip with an end too far from a road, or no road network.* Chosen: walk-only hops when the trip is at
       most `walk-only-blocks` (default 64) long, else `FAILED`, because the plan says "an end too far from a road
       → walk-only leg, short hops" and "never a straight-line fallback across terrain": a bound keeps both.
       Alternatives: (a) always walk-only hops (the spike): an NPC sent far away crosses terrain in a straight
       line; (b) always `FAILED`: contradicts the plan's walk-only leg.
    3. *Short trips.* Chosen: a goal within `hop-blocks` is one local leg without a road plan, because a road
       plan for 10 blocks only adds a detour to the road and back. Alternatives: (a) always plan a road: more
       plans and odd detours; (b) a separate key: not needed yet.
    4. *Where `PlayerAccessSubject` lives and how player navigation stays unchanged.* Chosen: the adapter in
       knk-paper (it names `Player`; the plan lists it under knk-core), and the `Player` methods keep their own
       code path while the subject overloads share the same private rule code; tests compare the verdicts case by
       case. Alternatives: (a) route the `Player` methods through the subject: one code path, but it changes
       player navigation's call order in a tier:3 link with no live test; (b) a Bukkit-free adapter in core with
       suppliers: more indirection for the same result.
    5. *What an access profile holds.* Chosen: `bypass-domain-rules`, `open-doors`, `allow-regions`,
       `deny-regions` (deny wins); NPCs pass open gates only and are never siege lockdown members, because gate
       pass-through for NPCs is Q5 (after Phase 5). Alternatives: (a) per-gate allow lists: an NPC cannot use a
       gate door yet, so the list would promise something the mover cannot do; (b) no lists, only the domain
       rules: the plan asks for allow/deny lists.
    6. *`spawns-per-tick` default.* Chosen: 2 (about 5 ms per tick at the spike's 2.4 ms per spawn).
       Alternatives: (a) 1: 50 NPCs take 2.5 s, safest; (b) 5: about 12 ms per tick.
    7. *When route following is built.* Chosen: on the first `/knk npc nav` use, because `KnKPlugin` creates the
       road navigation service elsewhere and nothing should run before it is needed. Alternatives: (a) at
       startup: an ordering dependency inside `KnKPlugin` and a tick task that runs for nothing.
    8. *NPC counters without `metrics.enabled`.* Chosen: they count whenever NPC navigation runs (they feed
       `/knk npc nav stats`) and are exported only with `metrics.enabled`. Alternatives: (a) a second set of
       counters in the test driver: two sources for the same numbers.
    9. *Router call.* Chosen: `AStarRouter.routeOrExplain`, so `BLOCKED` exists and names the blocking element
       (the spike used `route`, which only says `NO_ROUTE`). Alternatives: (a) `route` as the spike: Phase 3 would
       have to change it anyway and `NavigationResult.Blocked` would have no element.
    10. *Settings per NPC.* Chosen: resolved once at spawn (world and regions at the spawn spot). Alternatives:
        (a) resolve again on every plan: region overrides would follow the NPC; left for when templates exist.
    11. *Not ported from the spike.* Chosen: no `dump`, `set <key>`, `run`, CSV row, hop or dense mode,
        `keeploaded`; `trace` and stored routes are ported, and `npcspike-routes.yml` is taken over once.
        Alternatives: (a) port `dump`: about 60 lines of block dumping that the spike build can still do.
    12. *Docs beyond the coordinator's list.* Chosen: `CHANGELOG.md`, the configuration reference and the commands
        guide are in the workspace PR, because the skill § 2.11 and knk-plugin `AGENTS.md` require them with a
        config or command change. Alternatives: (a) leave them for the docs sub-issue: the config keys would have
        no reference at merge.
6. **Out of scope, noted.** No issue filed. For the docs sub-issue at merge: `FEATURE_REGISTER.md` row,
   `architecture/plugin-permission-checks.md` (`knk.admin.npc`), production installation (Citizens as an optional
   plugin). PR #235 (behavior model against `main`) overlaps with knk-workspace#370.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge the `npc.navigation` block into the dev server's `config.yml` (YAML in knk-plugin#17 and the
       configuration reference § 4.27); `enabled: true` only for the test.
    2. Run the Phase 2 developer test (implementation plan) and post the `stats` output and the run log on #360.
    3. Stair house (release gate), what to look at: (a) no NPC still in a flight for more than 3 s; (b) no jumping
       in circles; (c) no hop to the flight above or below at the U-turn; (d) recoveries that do not repeat on the
       same spot; (e) `stuck: no progress` per trip against the spike's 86 in 67 trips; (f) the positions in
       `npc-logs/<time>_npc-nav.log` (the spike's hard spots: 1410–1414 49–50 −500…−503, 1413–1415 69–71
       −545…−549); (g) one or two `/knk npc nav trace 60` files from the U-turn. One thing to watch closely: the
       next stretch is handed over within 4 blocks of the end of the current one (as in the spike), so when a
       hand-over falls on a U-turn the NPC cuts up to 4 blocks of the line.
    4. If off-road legs report `stuck: engine` at once (no path), check Citizens' pathfinding range: the Phase 1
       runtime leaves it at Citizens' default (the spike raised it to at least hop + capture margin + 8).
9. **Notes for later links.**
    1. L2 (Phase 3): the recheck, event replans, the walk to the blocking element and the trespass counter are
       not built. Hooks that exist: `RoadPlan` of `BLOCKED` already carries the partial line and the blocking
       element (not walked yet); the events `TRESPASS`, `REPLAN_RECHECK`, `REPLAN_EVENT` and the key
       `recheck-ticks` exist and are unused; `NavWorld.regionsAt` gives an NPC's regions. Missing: a `mayEnter`
       for an `AccessSubject` on `NavigationAccess` and a listener port for gate and availability events.
    2. L0: Phase 2 changed no listener. Route NPCs are named `knk-nav-<n>`, test walkers `knk-test-<n>`.
    3. Before merging `next` into a branch in knk-workspace, deepen the clone (`git fetch --depth=1000 origin
       <branches>`): the session's clone is shallow and a shallow merge base gave 14 conflicts instead of 1.

### 4.2 L2 — Phase 3: rules stay binding (#361)

1. **Scope done.**
    1. knk-plugin, knk-core `core/npc/nav/` (no Bukkit or Citizens types): the ports `AccessRules` (the rules as
       they are now) and `RuleChangeListener` (the listener port for gate and availability changes);
       `BlockingElement`; `RoadPlanner.RoadPlan` with the blocking element, the gates on the route
       (`GateCrossing`) and a still-blocked check; `NpcMover.pathAhead()`. `NpcNavigationService`: rule checks a
       few NPCs per tick (the recheck of the way ahead and the trespass guard), `onGateChanged` and
       `onAvailabilityChanged` that mark only the NPCs they concern, the walk along the partial route to the
       blocking element, the wait there woken by the element's open event with `no-route-wait-ticks` as the
       fallback, `NavigationResult.Blocked` with the typed element. `NavigationSettings` got `stop-on-trespass`;
       `NpcNavigationMetrics` got the events `rule_check`, `blocked_walk`, `woken` (`trespass`, `replan_recheck`
       and `replan_event` are counted now).
    2. knk-plugin, knk-paper: `NavigationAccess.mayEnter(AccessSubject)`, `gateBlocks`, `edgeBlocked` (the
       router's rule code, from caches); `NavigationService.accessRules()` and `addRuleChangeListener`, called at
       the top of `onGateChanged` and `onAvailabilityChanged` (player navigation is otherwise unchanged);
       `roadPlanOf` fills the gates, the blocking element and the check; `CitizensNpcMover.pathAhead`;
       `NpcNavigationConfig.ruleChecksPerTick` (`rule-checks-per-tick`); module wiring (the listener is added
       when route following is built and removed on stop; events hop to the main thread); a `rules:` line in
       `/knk npc nav stats`; `config.yml` comments. `KnKPlugin` and every listener are untouched.
    3. knk-workspace: Phase 3 status, known limits and developer test in the implementation plan; configuration
       reference § 2.1 and § 4.27; metric panels; tests A and B on the production code in the stress test guide;
       changelog draft.
    4. Inert while `npc.navigation.enabled` is false: `NpcNavigationModuleDisabledTest` now also verifies that
       road navigation is never touched (no listener, no rules port) and that no rule check is counted.
2. **Commits and heads.** knk-plugin `claude/npc-navigation` at `8df2d839` (`4a030786` core, `8df2d839` paper;
   `origin/next` `50bf7ff7` merged in first, a fast-forward). knk-workspace `claude/npc-navigation` at `a05f7bf`
   (on `origin/next` `424f1fa`, a fast-forward; `git diff --stat origin/next HEAD` was empty before the change
   and is 5 files after it).
3. **PRs.** [knk-plugin#18](https://github.com/PandiO/knk-plugin/pull/18) (`Closes #361`) and
   [knk-workspace#375](https://github.com/PandiO/knk-workspace/pull/375) (`Part of #361`), base `next`. Not
   merged.
4. **Tests, baseline → result.**
    1. knk-plugin (`./gradlew build -x deployToDevServer`, Gradle on JDK 21, JDK 25 toolchain): baseline at
       `50bf7ff7` core 2562, api-client 324 (2 skipped), paper 2570 (18 skipped), 0 failures; result at `8df2d839`
       core 2583 (+21), api-client 324 (2 skipped), paper 2581 (+11, 18 skipped), 0 failures. CI: `build` green on `8df2d839` (push run 43403427418, PR run 43403523663).
    2. knk-workspace: docs only; the links added were checked by hand.
    3. Known reds (also red on the base): none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the recheck gets the current rules.* Chosen: a core port `AccessRules` (entry rule per region for
       a subject, gate rule per door) answered by `NavigationAccess` with the router's own rule classes from
       caches, because the recheck and the router must agree and a check must not block the main thread.
       Alternatives: (a) build the subject's full road policy per check: reads every gate of the network per NPC
       every 40 ticks; (b) the rules re-implemented in the core: two sources of truth.
    2. *What an availability event does.* Chosen: it replans nobody by itself; every NPC with an order is marked
       for an early rule check, and only those with something denied ahead, or whose blocking element opened,
       plan again, because the event names no element and the spike replanned every NPC on every cache refresh
       for nothing (NAV-13). Alternatives: (a) replan every NPC (the spike); (b) give
       `NavigationService.onAvailabilityChanged` the changed domain: changes its callers in `KnKPlugin` and the
       siege code, outside this link.
    3. *The time slice.* Chosen: one server-wide key `rule-checks-per-tick` (10), NPCs an event concerns first,
       then round robin over NPCs whose `recheck-ticks` are up; with too few the checks come later, never all at
       once. Alternatives: (a) a fixed phase per NPC (id modulo `recheck-ticks`): no upper bound per tick;
       (b) no key, a constant: 500 NPCs would need a code change.
    4. *`NavigationResult.Blocked`.* Chosen: its `blockingElement` is now a `BlockingElement` record (kind, id,
       name, the gate doors and regions of the blocked stretch) in place of the string, because behavior needs
       the kind and the door id for a gate confrontation. Alternatives: (a) keep the string and add fields:
       two ways to say the same; nothing but the test driver used the string yet.
    5. *When the caller hears `Blocked`.* Chosen: when the plan arrives, once per element (again when another
       element blocks), so behavior can decide before the NPC has walked there. Alternatives: (a) on arrival at
       the element: behavior waits for a walk it may not want; (b) both: two results for one block;
       `waitsAtBlock(moverId)` answers "is it there yet".
    6. *Where the partial route ends.* Chosen: the router's partial route, cut before the first point in a
       region the NPC may not enter, because the router's last reachable node can lie past a district's edge and
       the NPC would trespass or be turned around by its own recheck. Alternatives: (a) the partial route as it
       is; (b) walk on along the blocked stretch to the exact boundary or gate: needs the blocked edge's
       geometry and the gate's position, a later refinement (known limit 1 in the plan).
    7. *Waking a blocked NPC.* Chosen: on an event the cheap question "does the blocked stretch still block this
       subject?" (one edge's verdict); a different gate that now lets the NPC through also wakes it; the
       fallback is a full plan every `no-route-wait-ticks` (100 = 5 s, the existing key). Alternatives: (a) a
       new key for the safety timer: one more key for the same 5 s; (b) no timer: a missed event would strand
       the NPC.
    8. *The trespass guard.* Chosen: entries are counted (a region the NPC stands in now and not at its last
       check, denied by the current rules judged from where it came from), as in the spike; stopping and
       replanning is the key `stop-on-trespass`, default false, because a "dev build" cannot be told from a
       production build at runtime. Alternatives: (a) default true: an NPC stopped inside a region plans from
       inside, where the entry rule no longer applies, so it changes little and adds stops in production;
       (b) count every check while inside: one mistake would count for ever.
    9. *The recheck and the router disagree.* Chosen: the router is the authority; the element is not asked
       about again for that order until the next gate or availability event, a log line says so, the trespass
       guard keeps watching. Alternatives: (a) replan at every recheck: the NPC stutters for ever; (b) fail the
       order: a lane the router knows to be free would end orders.
    10. *Where a gate is on the route.* Chosen: at the end of the gate's road stretch, so the gate is ahead
        until the NPC has passed the whole stretch. Alternatives: (a) the gate's real position: needs a gate
        geometry port; (b) the stretch's middle: an NPC between the middle and the gate would walk into a
        closing gate.
    11. *Local legs.* Chosen: the recheck reads the rest of the engine's path through `NpcMover.pathAhead()`
        (regions only). Alternatives: (a) prepare every local leg again on any gate event: every NPC on a local
        leg for every gate anywhere; (b) no recheck of local legs: the plan names "the rest of Citizens' path".
    12. *How far ahead.* Chosen: 96 blocks of the route line (64 points), every gate still to pass.
        Alternatives: (a) the whole rest of the route: a region lookup per 1.5 blocks of a long route every
        40 ticks; (b) a key: nobody asked for one.
    13. *New instruments.* Chosen: `rule_check`, `blocked_walk`, `woken`, for the tuning of
        `rule-checks-per-tick` and to see whether events or the timer wake NPCs. Alternatives: (a) only the
        three events L1 left: the developer test could not tell an event wake from a timer wake.
6. **Out of scope, noted.** No issue filed.
    1. A road network rebuilt while NPCs walk (`NavigationService.onNetworkChanged`) is not an event for NPCs;
       they notice at their next plan. Not in Phase 3's text; for Phase 7 or its own issue.
    2. Exit rules (a domain that forbids leaving) are judged at planning time only, as in the spike.
    3. No developer result, stair-house dump or trace was on #359, #360, #244 or #361 at the start or at the
       end, so none was used; L0 stays closed.
    4. For the docs sub-issue at merge, as L1: `FEATURE_REGISTER.md`, `architecture/plugin-permission-checks.md`,
       production installation.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge two keys into the dev server's `config.yml` under `npc.navigation`: `rule-checks-per-tick: 10` and
       `stop-on-trespass: false` (`true` for the Phase 3 test). The YAML is in knk-plugin#18 and in the
       configuration reference § 4.27.
    2. Run "Phase 3 → Developer test" in the implementation plan (gate runs, access runs, the refresh that
       replans nobody, the trespass counter) and post the `stats` output and the run log on #361.
    3. Look at where NPCs stand at the Keep Gate: at the gate or some blocks before it (known limit 1). If it
       is too far, the refinement is decision 6 (b).
9. **Notes for later links.**
    1. L0: Phase 3 changed no listener and no line of `KnKPlugin`.
    2. Phase 4 (groups): `NpcNavigationService.blockingOf` and `waitsAtBlock` say what blocks a mover and
       whether it stands at it; `onGateChanged` and `onAvailabilityChanged` are the only entry points for rule
       changes, both main thread.
    3. Phase 5 (permissions of the NPC's subject): a permission change is a third `RuleChangeListener` method
       and a mark like `eventAvailability`.
    4. Installing `openjdk-25-jdk-headless` makes `java` point at JDK 25; run Gradle with
       `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`.
    5. A fresh knk-plugin clone knows only `main`: `git remote set-branches --add origin next
       claude/npc-navigation` and a `--depth=1000` fetch of both before the checkout.
