# NPC navigation chain — charter

**Status:** Ready to start (2026-11-13); first chain under the `next` branch model (agent workflow setup #327, merged 2026-11-13).
**Last updated:** 2026-11-13 (rewritten for the `next` branch model after the setup chain merged)
**Issues:** parent [PandiO/knk-workspace#358](https://github.com/PandiO/knk-workspace/issues/358); sub-issues per link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-13-npc-navigation-chain.md](../../reports/2026-11-13-npc-navigation-chain.md) (the coordinator creates it from the template).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace `next`).

## 0. Binding documents

1. [specs/npc-platform/IMPLEMENTATION_PLAN.md](../../specs/npc-platform/IMPLEMENTATION_PLAN.md), in progress since 2026-11-13: the phase texts "Phase 2 — Navigate one NPC" (L1) and "Phase 3 — Rules stay binding" (L2), the stair release gate at the top, the Decisions table (Q1–Q8), the Phase 1 section for what L1 builds on.
2. [specs/npc-platform/BEHAVIOR_MODEL.md § 2](../../specs/npc-platform/BEHAVIOR_MODEL.md#2-fit-with-the-platform-design), requirements NAV-01–NAV-18 (L1: NAV-01, 03, 11, 13, 14, 15, 17; L2: NAV-02, 03, 04, 13), and [specs/npc-platform/DESIGN.md](../../specs/npc-platform/DESIGN.md) § 2 (platform-adapter boundary), § 6 (automatic navigation, failure policy, caller-supplied ruleset) and § 7.
3. Evidence: [guides/citizens-stress-test.md](../../guides/citizens-stress-test.md) (results table, Phase 0 section) and the Phase 0 results on [#244](https://github.com/PandiO/knk-workspace/issues/244). The spike branch knk-plugin `claude/citizens-spike` (`4060870`) is reference only: port its pieces with tests, never merge or cherry-pick it.
4. The sub-issue text **and its comments** (decisions added later live there), and #359's comments (the developer's Phase 1 test and audit report).

## 1. Links

Phase 1 (#359) was built by the design session and is in review; the chain continues on the same standing branch.

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | [#360](https://github.com/PandiO/knk-workspace/issues/360) | tier:3 | Phase 2: one NPC walks a K&K route in trail mode: `AccessSubject` port and NPC access profile, `RouteFollower` one stretch ahead with floor continuity, `HopPlanner` for recovery, `NpcNavigationService` (state machine, planning queue, bounded retries, results), progress watchdog, `KnkBlockExaminer`, road planning with the NPC's position, waiting only on rule blocks, pause/resume, spawns spread over ticks, `/knk npc nav` replacing the spike command. | knk-plugin (knk-workspace for docs) | `claude/npc-navigation` (continue it; head `8b36a942` at charter time, cut from `main` `121030fe`: merge `origin/next` into it first) | `next` | `npc.navigation.enabled` (default off) | now |
| L0 | [#359](https://github.com/PandiO/knk-workspace/issues/359) | tier:1 | Phase 1 follow-ups: guards (with a test each) on the listeners the developer's NPC event audit names, and anything else the Phase 1 test finds. Small; skipped if the audit names nothing. | knk-plugin | `claude/npc-navigation` | `next` | same | the developer's Phase 1 test result is on #359 **and** L1 merged into `next` (one link per component repo) |
| L2 | [#361](https://github.com/PandiO/knk-workspace/issues/361) | tier:3 | Phase 3: rules stay binding: time-sliced recheck of the way ahead, gate and availability events through a listener port with targeted replans, partial route to the blocking element then waiting woken by its open event, trespass guard and metric, `NavigationResult.Blocked` with the blocking element. | knk-plugin (knk-workspace for docs) | `claude/npc-navigation` | `next` | same | L1 merged into `next`, and L0 merged or skipped |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/claude/npc-navigation` is 0 in knk-plugin (and in knk-workspace when the link changed docs there), after the coordinator merged the link's PR with a merge commit (skill § 7).
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed (skill § 6), the full plugin suite is at or above the baseline (Phase 1 baseline: core 2507, api-client 324 with 2 skipped, paper 2535 with 18 skipped, 0 failures).
3. The developer's gates, recorded on the sub-issues: the Phase 1 test and audit report on #359 (opens L0); the dev-server runs of the Phase 2 "Done when" (50 NPCs on a stored route, the stair-house route without visible jumping in circles) on #360; the gate and access runs of the Phase 3 "Done when" on #361. A link writes the test checklist for its phase (the plan's "Developer test" style); it never waits for the live test itself.

Order and parallelism: one link at a time (one component repo). L0 slots in between L1 and L2 when the developer's Phase 1 result is in; if it is not in by the time L1 is done, L2 starts and L0 runs after it.

## 3. Chain notes

1. **Rule set in force.** #328 (CI on the API and web-app trunks) closed on 2026-11-13, so the `next` branch model should apply: base `next`, PRs target `next`, the coordinator merges a passed link into `next` with a merge commit, the issue stays `status:in-review` until the developer promotes `next`. The coordinator runs the skill § 1.3 check at its first run and records the result as its first decision; if the check fails, the old rules hold (base `main`, nobody in the chain merges) until it passes.
2. **Standing branch.** Every link continues knk-plugin `claude/npc-navigation` (one branch per repo for the feature). A link starts from the branch's current head and merges `origin/next` into it first (never rebase); Phase 1 was cut from `main` `121030fe`, and `next` has moved since (the setup chain's merges). One PR per link against `next`; after the merge the next link continues the same branch, so each PR shows only its own link.
3. **Separate from the Siege Survival NPC core.** `claude/siege-survival` (unmerged) has `core/npc/` (stats, profiles) and `paper/npc/` (mob goals). Navigation stays in `core/npc/nav/` and `paper/npc/citizens/`; links don't touch the siege branch's files. Overlap on `main`: `KnKPlugin` (additive hunks only, keep to the NPC block) and `listeners/*` guards (one `isNpc` check at the top of a handler).
4. **Engine neutrality (developer Q1).** No Citizens or Bukkit type outside `paper/npc/citizens/` and the Paper wiring; everything the engine provides goes through the `NpcMover` port and its siblings in `core/npc/nav/`. New engine needs → a new port method, not a leak.
5. **Stairs are tested alongside.** The stair release gate (plan, top) binds L1: trail mode with floor continuity and the watchdog as in the spike; the L1 report lists what the developer should look at in the stair house. The developer's stair-house dump and trace (spike `/knk npcspike dump|trace`, posted on #244 or #360) are input for L1 when available; L1 does not wait for them.
6. **Metrics and settings are already there** (Phase 1): links add instruments to `NpcNavigationMetrics` and keys to `NavigationSettings` rather than new mechanisms; every new key gets a `config.yml` comment and a test for its layer.
7. **Model for link sessions:** the coordinator's own model, from `get_session` → `session_context.model`, passed explicitly to `create_session`.
8. **First chain on the new workflow.** The setup chain (#327, in review) merged its skills, hooks and archive script on 2026-11-13 after a trial on `claude/agent-setup-trial` (findings on #331 and #332, fixed). This chain is the first full run: the coordinator reports every place where a skill, hook, template or instruction does not hold up as a numbered comment on #327 (or the matching sub-issue #330–#332) with the evidence, besides the chain's own report. The `tier:1/2/3` labels did not exist on 2026-11-13; creating them is a developer step.
