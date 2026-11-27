# Session token audit: rerun on 3 landmark-domain links

**Status:** Final · **Last updated:** 2026-11-27
**Issue:** [PandiO/knk-workspace#1019](https://github.com/PandiO/knk-workspace/issues/1019) (L0 of the token
efficiency chain, [#987](https://github.com/PandiO/knk-workspace/issues/987)) · **Procedure:**
[`docs/ai-agents/session-token-audit.md`](../ai-agents/session-token-audit.md) (knk-workspace `main`, branch
`claude/token-audit-1019` until merged) · **Baseline:** [code-graph trial report § 1b](2026-11-22-code-graph-mcp-trial.md#1b-overhead-in-real-sessions-layer-3)
and [plan](../specs/ai-agent-workflow/TOKEN_EFFICIENCY_PLAN.md) § 3 Phase 8

This is the first run of the written procedure and the Phase 0 acceptance check: it reproduces every § 1b field on
3 recent implementation links and adds the edit fields. No phase of the plan had merged when these sessions ran
(22 November), so these are **baseline** numbers too, not a phase result.

## 1. Sessions

The three most recent finished implementation links with a single session each: Landmarks as a Domain subtype chain
([progress report](2026-11-22-landmark-domain-chain.md)) L1 (#983, tier:3, API model and migration), L2 (#984,
tier:2, API) and L4 (#986, tier:2, web app), all run on 2026-11-22. L3 was left out because it ran in two sessions
(the first blocked on network).

## 2. Results

| Session | Cost | Turns (requests) | Start → end context | Re-read | Instructions/plans read | Code read | Read before first edit (turn) | Edits: Edit tool / Bash | Output tokens per edit: Edit tool / Bash (median) | Edit share of output | Wake-ups after done: idle / rework (cost) | Restarts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| L1 #983 `session_01R1w2Uv1A4MYoi62zFJTnwz` | $22.94 | 252 (204) | 88k → 552k | 76.1M | 21k | 88k | 79k (46) | 15 / 30 | 3.9k / 0.8k | 59 % | 2 / 6 ($0.47 / $4.05) | 3 |
| L2 #984 `session_01R1w2Ux3HrcYVs53AugdtZW` | $8.43 | 132 (121) | 87k → 303k | 25.2M | 23k | 38k | 47k (45) | 2 / 17 | 5.9k / 1.1k | ~50 % | 0 / 0 ($0) | 0 |
| L4 #986 `session_01R1w2UtGykzTGpUL4Ksj6S6` | $15.38 | 187 (160) | 88k → 388k | 40.9M | 21k | 74k | 51k (38) | 2 / 29 | 4.9k / 1.5k | 56 % | 2, not split ($3.37, of which $2.66 a cache rebuild after a restart) | 1 |
| **Median** | **$15.38** | **187 (160)** | **88k → 388k** | **40.9M** | **21k** | **74k** | **51k (45)** | **2 / 29** | **4.9k / 1.1k** | **56 %** | **2** | **1** |

Exactness: cost, turns, requests, context, re-read tokens, the edit counts, the first-edit turn and the wake-up counts
and costs are exact (from result events and tool calls). The reading buckets are estimates, characters ÷ 4 and a
manual bucket choice, ±10–25 %. Output tokens per edit and the edit share are allocations, about ±40 % (procedure
§ 3 step 5). L1's Bash count includes 2 edits of the progress report through a worktree under the scratchpad, which
the subagent left out under the first draft of the rule (step 4.1 now counts them).

## 3. Against the baseline

| Metric | Baseline (§ 1b, 9 links) | This rerun (3 links) | Plan § 2 target |
|---|---|---|---|
| Cost per link | $17.85 | $15.38 | — |
| Turns | 193 | 187 | — |
| Context start → end | 87k → 494k | 88k → 388k | — |
| Re-read tokens per link | 57M | 40.9M | −20 % of the baseline |
| Instructions and plans read | 36k | 21k | ≤ 15k |
| Code read | 73k | 74k | — |
| Read before first edit | 74k, turn 50 | 51k, turn 45 | turn ≤ 25 |
| Edits: Edit tool / Bash | 6 / 35 in L29 | 19 / 76 (20 % through the Edit tool) | — |
| Wake-ups after done | 2 (docs P9), 5 (L21) | idle 2, 0, 2 | ≤ 1 |

What this says:

1. **The procedure reproduces every § 1b field** (acceptance item 1). Start context matches to within 1k (87–88k
   in every session).
2. **Spread between links is larger than the gap to the baseline.** L2 cost $8.43 and L1 $22.94; three links is a
   small sample, and these were smaller than the Production links. The lower re-reads (−28 %) and instructions read
   (21k vs 36k) come before any phase, so a phase check should not count them as its saving.
3. **Instructions read: part of the gap may be the definitions.** The 2026-11-22 buckets were not written down; the
   procedure now fixes them (the Skill-load text in, PR comments and coordinator messages out). Later reruns are
   compared with both baselines (agent decision 1 below).
4. **Most edits are Bash edits** (76 of 95), but a Bash edit is cheap: median 1.1k output tokens against 4.9k for an
   Edit-tool edit (mostly `Write` of a new file). Edit requests take about 56 % of the non-thinking output. A rule
   change towards the Edit tool would not obviously save output tokens; nothing to act on now.
5. **Start context share of re-reads** (start context × turns ÷ re-reads): 29 %, 46 % and 40 % (median 40 %, baseline
   ~30 %). In a shorter link the fixed start weighs more, which is what Phase 2 attacks.
6. **Code reading share of re-reads** (code read × ¾ of the turns ÷ re-reads, § 1b's estimate): 22 %, 15 % and 25 %
   (median 22 %). Plan § 4 reopens the code graph (#977) when a rerun shows code reading above 25 %; L4 sits right at
   that line (25.3 % by this rough estimate), the median is below it. Reported for the coordinator; no reopen
   proposed on one link.
7. **Wake-ups after the hand-over are not all waste.** L1 had 8 result events after its first "finished" message: 6
   were rework (merging `next` into both PR branches, CHANGELOG and finalizer conflicts, a MySQL run, $4.05), 2 idle
   ($0.47). The procedure now splits idle from rework; Phase 4's target is about the idle ones.
8. **Restarts are visible and costly.** L4's third result came after a worker restart and rebuilt the cache: $2.66
   of its $3.37 after the hand-over. The drop test in the first draft missed it; `process_turn_index` 0 is the signal.

## 4. Fixes to the procedure from this run

All in [`session-token-audit.md`](../ai-agents/session-token-audit.md) before its PR was opened:

1. `message.usage.output_tokens` on assistant events is a streaming snapshot (summing to 3–6k against 75–190k), so
   per-edit output is now an allocation by visible characters (step 5.2), stated as an estimate.
2. `num_turns` summed over results is higher than the number of model requests (252 vs 204); both are reported, and
   the first-edit turn uses requests.
3. Restarts are detected by `process_turn_index`, not by a drop in the cumulative fields.
4. One sweep with `kinds: ["result", "assistant", "user"]`; empty filtered pages with `has_more` true are paged
   through, and paging stops at the first user prompt.
5. Edits through a worktree under the scratchpad and generators that write tracked files count as edits.
6. Bucket gaps closed: the Skill-load text block counts as Instructions; PR comments, coordinator messages and
   `add_repo` results go in Other.
7. Wake-ups after the hand-over are split into idle and rework.

## 5. Cost of this run (acceptance item 3)

1. Three subagents, one per session, in parallel: 125.9k (L1, 11 pages), 115.5k (L2, 8 pages) and 123.3k tokens (L4,
   10 pages), **365k in all, about 122k per link**, 4–5 minutes each.
2. The parent session's own probing of result and assistant events: about 12k tokens.
3. That is about twice the plan's estimate of 60k per session (Phase 0). The procedure's § 1 now says 115–125k per
   implementation link. The accounting fields alone (step 1) cost about 6–8k per session and need no subagent: a
   phase whose target is only cost, turns or wake-ups can use step 1 only.

## 6. Agent decisions

1. *Sessions measured.* Chosen: landmark-domain L1, L2 and L4, the most recent finished implementation links with one
   session each, from one chain, so the start reading is comparable. Alternatives: (a) siege shop L1–L6 (20 November)
   — older, and close to the § 1b window; (b) include L3 — two sessions with a network block in between, which
   distorts set-up; (c) six links as the plan's "about 6" — the issue asks for at least 3 and the coordinator asked
   to keep the cost low.
2. *Where the numbers go.* Chosen: this new dated report on `next`, linked from the procedure and the L0 link block,
   rather than editing the trial report § 1b (reports are dated and never overwritten; plan Phase 0 allows "a new
   dated report"). Alternatives: (a) append to § 1b — would rewrite a closed report.
3. *Baseline for later links.* Chosen: later reruns compare against **both** the § 1b medians (the plan's reference)
   and this rerun's medians (same written definitions, so differences come from the phase). Alternatives: (a) § 1b
   only — mixes a definition change with the phase effect, especially for instructions read; (b) replace § 1b with
   this rerun — plan § 2 says to revise targets, not measurements, and three links is a small sample.
4. *Output tokens per edit.* Chosen: allocation by visible characters, thinking left out. Alternatives: (a) read the
   `stream_event` pages for exact per-request usage — several times the pages; (b) share thinking by
   `thinking_duration_ms` — one subagent did this, but the field isn't reliably present, so it is not reproducible.
