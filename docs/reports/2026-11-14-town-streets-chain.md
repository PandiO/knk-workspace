# Town streets from districts chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-14

**Issue:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409), links
[#514](https://github.com/PandiO/knk-workspace/issues/514) (L1),
[#515](https://github.com/PandiO/knk-workspace/issues/515) (L2),
[#516](https://github.com/PandiO/knk-workspace/issues/516) (L3).
**Charter:** [handoffs/TOWN_STREETS_CHAIN.md](../ai-agents/handoffs/TOWN_STREETS_CHAIN.md).

## 1. Waiting for the developer

1. After L1: approve the design note and decide what happens to each orphan `TownStreet` row (run the SQL check on
   the dev and alpha databases). The coordinator will ask.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started | Test rule |
|---|---|---|---|---|---|---|---|
| L1 Design note and data check | #514 | Not started | — | — | — | — | automated first, `main` `aa4208b3` |
| L2 Implementation | #515 | Not started | — | — | — | — | — |
| L3 Smoke tests and changelog | #516 | Not started | — | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set in force.** Chosen: the `next` branch model (links base on and target `next`, the coordinator merges a
   passed link into `next` with a merge commit), because the skill § 1.3 check passed on 2026-11-14:
   `.github/workflows/ci.yml` is on knk-web-api `origin/main` and knk-web-app `origin/main`. Alternatives: (a) the
   old rules (nobody in the chain merges), only if the check had failed.
2. **Heads at the first run (2026-11-14).** `next`: knk-web-api `b9ce7f05`, knk-web-app `8918eba0`, knk-plugin
   `a760c4a4`, knk-workspace `511b494d`; knk-workspace `main` `aa4208b3`.
3. **Testing rule version.** Chosen: "Testing: automated first" with the knk-test-writer skill, as merged on
   knk-workspace `main` in `aa4208b3` (PR #512, 2026-11-14), applied from L1 on, because the developer's instruction
   of 2026-11-14 says to apply it as soon as it lands and it landed before the first link. Alternatives: (a) the
   interim rule (unit tests plus an e2e spec per changed page), now superseded.
4. **Links and tiers.** Chosen: three sub-issues as the developer's prompt splits them: L1 #514 tier:3, L2 #515
   tier:3, L3 #516 tier:1 + `documentation`, because L3 changes docs only. Alternatives: (a) L3 tier:3 like the
   parent; (b) fold L3 into L2 (essential docs ship with L2 anyway; L3 keeps the smoke-test move separate as asked).
5. **No feature flag for tier:3 work.** Chosen: no flag, with the data check, backup step and migration `Down` as the
   safety net (charter § 3.2), because a dropped table and a derived read-only property cannot be switched off by
   configuration. Alternatives: (a) keep `TownStreet` and only hide the link behind a flag, dropping the table in a
   later release (two migrations, contradicts the developer's "drop the table"); (b) a flag that switches the DTO
   between stored and derived lists (keeps the drift problem alive).
6. **Overlap check.** No "In progress" row claims `Town`, `TownStreet` or the town detail page; chain 3's V5 claim on
   `RelationshipService.cs` is merged and idle. Chosen: no blocker; L2 keeps to the `Town.Streets` entry.
   Alternatives: (a) wait for chain 3 to close its row (it has no open work on that file).
7. **Developer gate after L1.** Chosen: the coordinator asks the developer with AskUserQuestion once L1's note and
   SQL are on the branch, and records the answer on #515, because a link session's question may go unseen.
   Alternatives: (a) the L1 link asks itself.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
