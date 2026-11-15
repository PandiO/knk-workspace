# Chain 3 follow-ups chain — progress report

**Status:** Running (2026-11-15) · **Last updated:** 2026-11-15

**Issue:** [PandiO/knk-workspace#564](https://github.com/PandiO/knk-workspace/issues/564), links
[#399](https://github.com/PandiO/knk-workspace/issues/399) (L1),
[#290](https://github.com/PandiO/knk-workspace/issues/290) (L2),
[#289](https://github.com/PandiO/knk-workspace/issues/289) (L3),
[#291](https://github.com/PandiO/knk-workspace/issues/291) (L4),
[#288](https://github.com/PandiO/knk-workspace/issues/288) (L5),
[#565](https://github.com/PandiO/knk-workspace/issues/565) (L6, part of #119)
**Charter:** [handoffs/CHAIN3_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/CHAIN3_FOLLOWUPS_CHAIN.md).

## 1. Waiting for the developer

1. **Before L6 (#565): kick and ban from the web?** Optional item 5 of the #119 API needs: a staff command relay to the
   game server (realtime `PlayerKick`/`PlayerBan` with reason, audited, with nodes). It changes moderation behaviour,
   so it needs your yes/no. Without an answer, L6 builds items 1–4 only.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Temp region releases | #399 | Not started | — | — | — | — |
| L2 List field cards at 390 px | #290 | Not started | — | — | — | — |
| L3 "Show what uses it" for more refusals | #289 | Not started | — | — | — | — |
| L4 Builder rules and templates into the draft | #291 | Not started | — | — | — | — |
| L5 Lookup applies picker filters | #288 | Not started | — | — | — | — |
| L6 Player profile API part | #565 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs into `next`, the coordinator merges),
   because `.github/workflows/ci.yml` is on `origin/main` of knk-web-api and knk-web-app (checked 2026-11-15).
   Alternatives: (a) old rules, developer merges: no longer apply once CI runs on both trunks.
2. **Bookkeeping on `main`.** Chosen: push bookkeeping commits directly to knk-workspace `main`, because global
   instructions "Branches" rules 9–10 (on `main` `d0a9baf9`) say the knk-workspace ruleset only blocks deletion and
   force pushes and a push dry run to `main` succeeds. Alternatives: (a) a bookkeeping PR merged by me, as the chain
   prompt suggested in case direct pushes are refused: the fallback if a real push is refused.
3. **#119 as a link.** Chosen: a new sub-issue #565 for the API part, because #119 is already a sub-issue of #24 and an
   issue has one parent; moving it would drop it from the UX roadmap. Alternatives: (a) re-parent #119 to #564;
   (b) link #119 without a sub-issue: the chain rules scope every link by its sub-issue.
4. **Tiers.** Chosen: as the developer listed them (#399, #290, #289 `tier:1`; #291, #288, #565 `tier:2`); parent
   #564 `tier:2` (highest of its links).
5. **Decisions in the developer's go.** Recorded on #291 (rules and add-from-template into the draft, option 2) and
   #288 (lookup applies narrowing filters, labels only), so the links don't ask again. Kick/ban for L6 is not settled
   by the go ("ask the developer before building anything that changes moderation behaviour beyond the issue"): asked
   in § 1, default without an answer is to leave it out. Alternatives: (a) let L6 ask: subagent links cannot ask
   (staff chain lesson, decision 11 of its report).
6. **Order and parallelism.** Chosen: L1 ∥ L2, then L3, L4, L5, L6 in the developer's order, because L1 is API-only
   and L2 web-only; L3 is web-only and waits for L2; L4–L6 change both repos. Alternatives: (a) run L3 in parallel
   with L1 if it needs no API: L1 holds knk-web-api only briefly, so the gain is small and L3 may need the API.
7. **Overlap check (2026-11-15).** No open PRs in knk-web-api or knk-web-app; no unmerged `claude/*` branch changes
   `TempRegionReleaseService` or `FormWizard/FieldRenderers.tsx`. The staff chain's L3 (#407) is running on
   `PlayerProfilePage.tsx`: not a blocker for L1–L5; L6 rechecks it and keeps to separate lines. Alternatives: (a) hold
   L6 until the staff chain finishes: decided at L6's start.
8. **Route.** Chosen: `create_session` (variant A) for L1 and L2 with model `claude-opus-5-5`, because each needs one
   component repo; subagents for L4–L6 (two component repos, coordinator skill § 4.1.4). Fallback a subagent.
9. **#387.** Not merged (PR #553 into `next` open): links use today's nodes and say so.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
