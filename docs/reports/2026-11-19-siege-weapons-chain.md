# Siege weapons chain — progress report

**Status:** Running (2026-11-19) · **Last updated:** 2026-11-19

**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354), links
[#782](https://github.com/PandiO/knk-workspace/issues/782) (L1), [#783](https://github.com/PandiO/knk-workspace/issues/783) (L2),
[#784](https://github.com/PandiO/knk-workspace/issues/784) (L3), [#785](https://github.com/PandiO/knk-workspace/issues/785) (L4),
[#786](https://github.com/PandiO/knk-workspace/issues/786) (L5), [#787](https://github.com/PandiO/knk-workspace/issues/787) (L6),
[#788](https://github.com/PandiO/knk-workspace/issues/788) (L7), [#789](https://github.com/PandiO/knk-workspace/issues/789) (L8),
[#790](https://github.com/PandiO/knk-workspace/issues/790) (L9).
**Charter:** [handoffs/SIEGE_WEAPONS_CHAIN.md](../ai-agents/handoffs/SIEGE_WEAPONS_CHAIN.md).

## 1. Waiting for the developer

1. Nothing yet. Known ahead: L3 needs siege points (#356), the siege shop (#611) and the schematic and snapshot
   pipeline (#614) merged into `next`; on 2026-11-19 all three are open issues without a design or chain. When L2 is
   merged and that gate is still closed, the coordinator reports it as a blocker for L3 and asks whether to schedule
   designs for them through the manager. L9 needs the siege tactical map (#613); L7's ground fire needs siege fire (#615).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Entities, API, form seeds, unlocks | #782 | Running | `claude/siege-weapons-l1`: (not pushed yet) | — | — | subagent of the coordinator (decision 3: two component repos), started 2026-11-19 |
| L2 Spots through world tasks | #783 | Not started (gate: L1 merged into `next`) | — | — | — | — |
| L3 Buying, placement, paste, restore | #784 | Not started (gates: L2; #356, #611, #614) | — | — | — | — |
| L4 Damage, wreck, cooldown, statistics | #785 | Not started | — | — | — | — |
| L5 Ballista direct fire | #786 | Not started | — | — | — | — |
| L6 Trebuchet and catapult in game | #787 | Not started | — | — | — | — |
| L7 Ammo effects | #788 | Not started (#615 for ground fire only) | — | — | — | — |
| L8 Page credential and API relay | #789 | Not started | — | — | — | — |
| L9 Targeting mode on the map page | #790 | Not started (gates: L8; #613) | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   with a merge commit), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and knk-web-app
   (checked 2026-11-19; `next` heads: API `935fe8cc`, web app `3432e6ef`, workspace `87eacf42`). Alternatives:
   (a) old rules (default branch, developer merges), which apply only while CI is missing; (b) stacking links on each
   other's unmerged branches, which the charter does not allow.
2. **Link model.** Chosen: every link session runs on the coordinator's model (set explicitly in `create_session`),
   because the charter leaves it to the coordinator and every link but L2 is tier:3. Alternatives: (a) a smaller model
   for L2 (tier:2), rejected for consistency of the chain; (b) leave it implicit, which the skill forbids.
3. **L1 route.** Chosen: subagent of this coordinator session (variant B), because L1 needs two repositories besides
   knk-workspace (knk-web-api and knk-web-app) and the skill (§ 4.1.4.2) sends such links the subagent route from the
   start, after the Auto-mode classifier refused a multi-repo attach on #511. Alternatives: (a) `create_session` with
   two `add_repo` calls, likely but not certain to be approved; (b) split L1 into an API and a web-app session,
   which the charter does not plan.
4. **Overlap, L1 vs Production chain (#22) L0 #141.** L0 adds one additive migration and `ItemBlueprint` changes in
   knk-web-api from `next`; its branch was not pushed yet on 2026-11-19. Both chains change `Migrations/` (model
   snapshot) and may touch `Properties/KnKDbContext.cs`. Chosen: not a blocker (different entities and lines); L1
   keeps its `KnKDbContext` edits in its own block, merges the latest `origin/next` first, generates its migration
   last and regenerates it if another migration lands in `next` before its merge; the Production coordinator is told
   that L1 carries a migration. Alternatives: (a) wait for L0 to merge first, which serialises two chains for a
   mechanical conflict; (b) ask Production to wait, which changes another chain's plan (developer's call).
5. **Overlap, L1 vs Siege Survival (#41) `claude/siege-survival`.** That API branch (11 commits not in `next`, no link
   running) adds a large block to `KnKDbContext` and new `Models/Siege/Survival/*`. L1 changes `SiegeScenario`,
   `SiegeTeam` and adds new `Models/Siege/` files. Chosen: not a blocker (claim not active, additive edits); L1 adds
   its properties and `KnKDbContext` configuration in separate blocks, without reformatting neighbouring lines.
   Alternatives: (a) put the weapons entities in their own `Models/Siege/Weapons/` folder only (still allowed if the
   link prefers); (b) block until Survival merges, rejected because it has no date.
6. **Overlap, L1 vs dashboard table fields (#608).** That row claims `src/config/objectConfigs.tsx` in knk-web-app but
   waits for the developer's design OK. Chosen: not a blocker; L1 adds its own object config entries without touching
   the permissiongrant entry. Alternatives: (a) wait, rejected (not active).

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
