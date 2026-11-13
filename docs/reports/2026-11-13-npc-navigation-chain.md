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
3. **For review, not blocking (decision 3 below):** the binding documents (implementation plan, BEHAVIOR_MODEL,
   stress test guide) exist only on knk-workspace `claude/nice-feynman-pvy1j3`, not on `main` or `next`. L1 brings
   them into `next` with its docs PR (branch `claude/npc-navigation`, cut from that branch). This also brings the
   behavior-model docs of PR #235 (in review against `main`) into `next`. Say so if they should stay out.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Phase 2: one NPC walks a K&K route | #360 | Not started | `claude/npc-navigation`: knk-plugin `8b36a942` (Phase 1 head) | none | none | |
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

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
