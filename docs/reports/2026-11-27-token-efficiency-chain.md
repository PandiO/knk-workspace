# Token efficiency chain — progress report

**Status:** Running (2026-11-27) · **Last updated:** 2026-11-27

**Issue:** [PandiO/knk-workspace#987](https://github.com/PandiO/knk-workspace/issues/987), links
[#1019](https://github.com/PandiO/knk-workspace/issues/1019) (L0),
[#1020](https://github.com/PandiO/knk-workspace/issues/1020) (L1),
[#1021](https://github.com/PandiO/knk-workspace/issues/1021) (L2),
[#1026](https://github.com/PandiO/knk-workspace/issues/1026) (L3),
[#1024](https://github.com/PandiO/knk-workspace/issues/1024) (L4),
[#978](https://github.com/PandiO/knk-workspace/issues/978) (L5),
[#1022](https://github.com/PandiO/knk-workspace/issues/1022) (L6),
[#1023](https://github.com/PandiO/knk-workspace/issues/1023) (L7),
[#1025](https://github.com/PandiO/knk-workspace/issues/1025) (L8).
**Charter:** [handoffs/TOKEN_EFFICIENCY_CHAIN.md](../ai-agents/handoffs/TOKEN_EFFICIENCY_CHAIN.md).

## 1. Waiting for the developer

1. Nothing yet. Known gate ahead: L6 (#1022) changes the cloud environment's setup script, which needs your approval
   in the environment approval prompt.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L0 session token audit procedure | #1019 | In review (PRs open, not merged) | `claude/token-audit-1019`: `f6dba762` (4 commits on `main` `aa404246`); `claude/token-audit-1019-next`: `c91e7539` (1 commit on `next`) | [#1037](https://github.com/PandiO/knk-workspace/pull/1037) (`main`), [#1038](https://github.com/PandiO/knk-workspace/pull/1038) (`next`) | none (docs) | create_session `session_01R1w2UuT7VcXg1qRF2cqKDV` (§ 3.3) |
| L1 slim the session board | #1020 | Not started (gate: L0 merged) | — | — | — | — |
| L2 lighter start-up reading | #1021 | Not started (gate: L0 merged) | — | — | — | — |
| L3 stop waking finished sessions | #1026 | Not started (gate: L0 merged) | — | — | — | — |
| L4 coordinator hand-over, fewer wake-ups | #1024 | Not started (gate: L0 and L3 merged) | — | — | — | — |
| L5 reuse catalogue | #978 | Not started (gate: L0 merged) | — | — | — | — |
| L6 fewer set-up turns | #1022 | Not started (gate: L1–L5 merged; developer approval) | — | — | — | — |
| L7 one docs session per chain | #1023 | Not started (gate: L1–L5 merged) | — | — | — | — |
| L8 smoke-run session | #1025 | Not started (gate: L1–L5 merged) | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model applies (`next` exists and carries merged chain work, among it this
   chain's plan, PandiO/knk-workspace#1027 merge `b15366fb`), with the charter's exception that every link changes
   agent workflow files and therefore branches from knk-workspace `main`, opens its PR into `main`, and I merge it
   into `main` and then `main` into `next` through a PR (skill § 7.10). The parts on feature-doc paths (L5's
   catalogue, L8's guide format, and any edit to the `next`-only evidence report) go into `next` in their own PR.
   Alternatives: (a) old rules, the developer merges everything — rejected, the charter and skill § 7.10 put these
   merges with the coordinator; (b) everything through `next` — rejected, "Branches" rule 11 keeps workflow files on
   `main` first.
2. **Overlap at first run.** Chosen: no overlap. Board read fresh from `origin/main` (`aa404246`) on 2026-11-27: no
   "In progress" row claims knk-workspace `.claude/`, `docs/ai-agents/`, `AGENTS.md`/`CLAUDE.md`, the board or the
   archive script (two old rows name component-repo `CLAUDE.md` files, which this chain does not touch).
   Alternatives: (a) treat those two rows as claims — rejected, other repos and finished work.
3. **Route for L0.** Chosen: `create_session` with knk-workspace as `source_url`; L0 needs no other repository, so
   no `add_repo` attach is at risk (skill § 4.1.4). Alternatives: (a) subagent — kept as the fallback.
4. **Binding documents live on `next` only.** The plan and the trial report are not on `main` (checked 2026-11-27).
   Chosen: link prompts tell links to read them from `origin/next`. Alternatives: (a) merge `next` into `main` first —
   rejected, never merge into trunk outside § 7.10.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.0 L0 — Session token audit procedure (#1019)

1. **Scope done.**
    1. knk-workspace `main` branch: new `docs/ai-agents/session-token-audit.md`, the § 1b recipe as six steps (accounting fields from result events, transcript walk, reading buckets, read before the first edit, edit fields, result row). It adds Edit-tool vs Bash edits, output tokens per edit, idle vs rework wake-ups and restarts, and records the § 1b and Phase 8 reference plus a second reference from this rerun. Changelog entry under Unreleased.
    2. knk-workspace `next` branch: new dated report `docs/reports/2026-11-27-session-token-audit.md` with the rerun on landmark-domain L1 #983, L2 #984 and L4 #986 (acceptance items 1 and 2).
2. **Commits and heads.** knk-workspace `claude/token-audit-1019` at `f6dba762` (4 commits, base `main`); `claude/token-audit-1019-next` at `c91e7539` (1 commit, base `next`).
3. **PRs.** [#1037](https://github.com/PandiO/knk-workspace/pull/1037) into `main` (`Closes #1019`), [#1038](https://github.com/PandiO/knk-workspace/pull/1038) into `next` (`Part of #1019`). Not merged.
4. **Tests, baseline → result.**
    1. knk-workspace: docs only. The links resolve on `next`; the procedure's links to the plan, the trial report and the new report are `next`-only paths, so they resolve on `main` after the `main` → `next` → trunk round.
    2. Rerun medians (3 links): $15.38, 187 turns (160 requests), 88k → 388k context, 40.9M re-read, 21k instructions, 74k code, 51k read before the first edit at turn 45, edits 2 Edit tool / 29 Bash, 4.9k / 1.1k output tokens per edit, idle wake-ups after done 2. Every § 1b field was reproduced. Baseline (§ 1b): $17.85, 193 turns, 87k → 494k, 57M, 36k, 73k, 74k at turn 50.
    3. Cost of the run (acceptance item 3): 365k subagent tokens (about 122k per link, twice the plan's 60k estimate) plus about 12k in this session.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the numbers go.* Chosen: a new dated report on `next` in its own branch and PR (prompt § 1 item 3 option), because reports are never overwritten and the plan allows a new dated report. Alternatives: (a) append to trial report § 1b on `next` — rewrites a closed, dated report.
    2. *Sessions measured.* Chosen: landmark-domain L1, L2 and L4 (2026-11-22), the most recent finished single-session implementation links. Alternatives: (a) siege shop links — older; (b) landmark L3 — split over two sessions by a network block; (c) six links — the issue asks for 3 and cost had to stay low.
    3. *Baseline for later links.* Chosen: compare each phase with both § 1b and this rerun, because the 2026-11-22 bucket boundaries were never written down and instructions read already differ (21k vs 36k) before any phase. Alternatives: (a) § 1b only — mixes a definition change with the phase effect; (b) replace § 1b — plan § 2 says revise targets, not measurements.
    4. *Output tokens per edit.* Chosen: allocation by visible characters, thinking left out, because the transcript's per-message `output_tokens` is a streaming snapshot. Alternatives: (a) read `stream_event` pages for exact usage — several times the pages; (b) share thinking by `thinking_duration_ms` — not reliably present.
    5. *Fixes from the rerun went into the procedure before the PR* (turns vs requests, restart detection, paging, worktree edits, bucket gaps, idle vs rework). Alternatives: (a) ship the first draft and file a follow-up — later links would measure with a known-wrong step.
6. **Out of scope, noted.** Plan § 4: code reading was about 25 % of re-reads in L4 by the rough § 1b estimate (median 22 %), right at the reopen line for #977. Reported here for the coordinator; no reopen proposed on one link.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging #1037 into `main` (then `main` → `next`) and #1038 into `next`.
9. **Notes for later links.**
    1. Measure with `docs/ai-agents/session-token-audit.md`, one subagent per session, in parallel. Budget about 120k tokens per implementation link for the full recipe; step 1 alone (cost, turns, context, wake-ups) is about 6–8k per session and needs no subagent.
    2. Compare against both references in the procedure's § 4. Without a phase merged, three links already spread from $8 to $23, so use at least 3 links that started after your phase merged into `main`.
    3. L3 (Phase 4) target: count only **idle** wake-ups after the hand-over. L1's 8 post-hand-over results were mostly rework (base merges, conflicts).
    4. L4 (Phase 8): restarts (`process_turn_index` 0) rebuild the cache; L4 #986 paid $2.66 for one.
