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

1. The L1 design questions (asked in the coordinator session); then the approval of the L1 design, which opens L3 and
   L4.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Design: corners, narrowed formations, toggle | #519 | Not started | — | — | — | — |
| L2 Follower recheck and guard, no gate push | #520 | Not started | — | — | — | — |
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

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
