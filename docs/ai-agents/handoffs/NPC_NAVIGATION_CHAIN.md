# NPC navigation chain — charter

**Status:** Ready to start (2026-11-13); first chain run under the trial of the new agent workflow (`claude/agent-setup-trial`).
**Last updated:** 2026-11-13
**Issues:** parent [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358); sub-issues per link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-13-npc-navigation-chain.md](../../reports/2026-11-13-npc-navigation-chain.md) (the coordinator creates it from the template).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace, on `claude/agent-setup-trial` until the setup branches are merged).

## 0. Binding documents

1. [specs/npc-platform/IMPLEMENTATION_PLAN.md](../../specs/npc-platform/IMPLEMENTATION_PLAN.md), in progress since 2026-11-13: the phase texts "Phase 2 — Navigate one NPC" (L1) and "Phase 3 — Rules stay binding" (L2), the stair release gate at the top, the Decisions table (Q1–Q8), the Phase 1 section for what L1 builds on.
2. [specs/npc-platform/BEHAVIOR_MODEL.md § 2](../../specs/npc-platform/BEHAVIOR_MODEL.md#2-fit-with-the-platform-design), requirements NAV-01–NAV-18 (L1: NAV-01, 03, 11, 13, 14, 15, 17; L2: NAV-02, 03, 04, 13), and [specs/npc-platform/DESIGN.md](../../specs/npc-platform/DESIGN.md) § 2 (platform-adapter boundary), § 6 (automatic navigation, failure policy, caller-supplied ruleset) and § 7.
3. Evidence: [guides/citizens-stress-test.md](../../guides/citizens-stress-test.md) (results table, Phase 0 section) and the Phase 0 results on [#244](https://github.com/PandiO/knk-workspace/issues/244). The spike branch knk-plugin `claude/citizens-spike` (`4060870`) is reference only: port its pieces with tests, never merge or cherry-pick it.
4. The sub-issue text **and its comments** (decisions added later live there), and #359's comments (the developer's Phase 1 test and audit report).

## 1. Links

Phase 1 (#359) was built by the design session and is in review; the chain continues on the same standing branch.

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | [#360](https://github.com/PandiO/knk-workspace/issues/360) | tier:3 | Phase 2: one NPC walks a K&K route in trail mode: `AccessSubject` port and NPC access profile, `RouteFollower` one stretch ahead with floor continuity, `HopPlanner` for recovery, `NpcNavigationService` (state machine, planning queue, bounded retries, results), progress watchdog, `KnkBlockExaminer`, road planning with the NPC's position, waiting only on rule blocks, pause/resume, spawns spread over ticks, `/knk npc nav` replacing the spike command. | knk-plugin (knk-workspace for docs) | `claude/npc-navigation` (continue it; head `8b36a942` at charter time) | `main` | `npc.navigation.enabled` (default off) | now |
| L0 | [#359](https://github.com/PandiO/knk-workspace/issues/359) | tier:1 | Phase 1 follow-ups: guards (with a test each) on the listeners the developer's NPC event audit names, and anything else the Phase 1 test finds. Small; skipped if the audit names nothing. | knk-plugin | `claude/npc-navigation` | `main` | same | the developer's Phase 1 test result is on #359 **and** L1 done (one link per component repo) |
| L2 | [#361](https://github.com/PandiO/knk-workspace/issues/361) | tier:3 | Phase 3: rules stay binding: time-sliced recheck of the way ahead, gate and availability events through a listener port with targeted replans, partial route to the blocking element then waiting woken by its open event, trespass guard and metric, `NavigationResult.Blocked` with the blocking element. | knk-plugin (knk-workspace for docs) | `claude/npc-navigation` | `main` | same | L1 done and L0 done or skipped |

## 2. Gates

1. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed (coordinator skill § 6), the full plugin suite is at or above the baseline (Phase 1 baseline: core 2507, api-client 324 with 2 skipped, paper 2535 with 18 skipped, 0 failures).
2. "Merged into `main`" is not a gate in this chain: under the rule set in force (see § 3.1) nobody in the chain merges; the links stack on the standing branch `claude/npc-navigation`, and the developer merges the branch as a whole (or per PR, in link order) after testing.
3. The developer's gates, recorded on the sub-issues: the Phase 1 test and audit report on #359 (opens L0); the dev-server runs of the Phase 2 "Done when" (50 NPCs on a stored route, the stair-house route without visible jumping in circles) on #360; the gate and access runs of the Phase 3 "Done when" on #361. A link writes the test checklist for its phase (the plan's "Developer test" style); it never waits for the live test itself.

Order and parallelism: one link at a time (one component repo). L0 slots in between L1 and L2 when the developer's Phase 1 result is in; if it is not in by the time L1 is done, L2 starts and L0 runs after it.

## 3. Chain notes

1. **Rule set in force.** The `next` branch model applies only once CI runs on the API and web-app default branches (coordinator skill § 1.3; #328 is in review). Until then: base `main`, PRs target `main`, nobody in the chain merges. The coordinator checks this at every link start and records the rule set in the progress report; if it flips mid-chain, later links branch from `next` and the coordinator says so in the report.
2. **Standing branch, stacked by design.** Every link continues knk-plugin `claude/npc-navigation` (one branch per repo for the feature, global instructions "Parallel sessions and branches" rule 3). A link starts from the branch's current head, never from `main`, and takes `main`'s updates by merge, never rebase. One PR per link against `main` is still opened (the developer merges in link order); the PR body says which links it depends on.
3. **Separate from the Siege Survival NPC core.** `claude/siege-survival` (unmerged) has `core/npc/` (stats, profiles) and `paper/npc/` (mob goals). Navigation stays in `core/npc/nav/` and `paper/npc/citizens/`; links don't touch the siege branch's files. Overlap on `main`: `KnKPlugin` (additive hunks only, keep to the NPC block) and `listeners/*` guards (one `isNpc` check at the top of a handler).
4. **Engine neutrality (developer Q1).** No Citizens or Bukkit type outside `paper/npc/citizens/` and the Paper wiring; everything the engine provides goes through the `NpcMover` port and its siblings in `core/npc/nav/`. New engine needs → a new port method, not a leak.
5. **Stairs are tested alongside.** The stair release gate (plan, top) binds L1: trail mode with floor continuity and the watchdog as in the spike; the L1 report lists what the developer should look at in the stair house. The developer's stair-house dump and trace (spike `/knk npcspike dump|trace`, posted on #244 or #360) are input for L1 when available; L1 does not wait for them.
6. **Metrics and settings are already there** (Phase 1): links add instruments to `NpcNavigationMetrics` and keys to `NavigationSettings` rather than new mechanisms; every new key gets a `config.yml` comment and a test for its layer.
7. **Model for link sessions:** the coordinator's own model, from `get_session` → `session_context.model`, passed explicitly to `create_session`.
8. **Trial of the agent workflow.** This chain is the first run of the setup chain's skills and tooling (#327: #330 skills, #331 tooling, #332 archive) from `claude/agent-setup-trial`. The coordinator pulls the setup branches' improvements into that branch before each link start (see the coordinator prompt) and reports every place where the skills, the hooks or the instructions did not hold up as a comment on the matching setup issue, with the evidence, in addition to the chain's own report.
