# NPC navigation chain — progress report

**Status:** Running (2026-11-13) · **Last updated:** 2026-11-13

**Issue:** [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358), links
[#360](https://github.com/PandiO/knk-workspace/issues/360) (L1),
[#359](https://github.com/PandiO/knk-workspace/issues/359) (L0),
[#361](https://github.com/PandiO/knk-workspace/issues/361) (L2).
**Charter:** [handoffs/NPC_NAVIGATION_CHAIN.md](../ai-agents/handoffs/NPC_NAVIGATION_CHAIN.md).

## 1. Waiting for the developer

1. **Phase 1 test and audit report on #359** (implementation plan, "Phase 1 → Developer test"). It opens L0. Until it
   is there, L0 stays closed and L2 follows L1.
2. **Stair-house dump and trace** (spike `/knk npcspike dump|trace`) on #244 or #360, when available. L1 uses them
   but does not wait.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 2: one NPC walks a K&K route | #360 | In review (finished 2026-11-13; live test by the developer open) | `claude/npc-navigation`: knk-plugin `49b5cedb`, knk-workspace `764d64d` | [knk-plugin#17](https://github.com/PandiO/knk-plugin/pull/17), [knk-workspace#370](https://github.com/PandiO/knk-workspace/pull/370) | knk-plugin `build` green on `49b5cedb` (run 43398822498); knk-workspace has no CI | create_session session_01R1w2Uv2Ze28fr2rkqUz98C (`source_revision` `next`) |
| L0 Phase 1 follow-ups | #359 | Not started (gate: developer's Phase 1 result on #359 and L1 merged into `next`) | `claude/npc-navigation`: knk-plugin `8b36a942` | none | none | |
| L2 Phase 3: rules stay binding | #361 | Not started (gate: L1 merged into `next`, L0 merged or skipped) | | none | none | |

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
   `claude/npc-navigation` at `764d64d` (merge of `next` `2dd2183`, docs `764d64d`; base `next` at `17748b8`).
3. **PRs.** [knk-plugin#17](https://github.com/PandiO/knk-plugin/pull/17) (`Closes #360`, `Part of #359`; shows
   Phases 1 and 2 together) and [knk-workspace#370](https://github.com/PandiO/knk-workspace/pull/370) (`Part of
   #360`; also carries the NPC design documents of #234 and #241), base `next`. Not merged.
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
