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
| L0 session token audit procedure | #1019 | Running | `claude/token-audit-1019`: not pushed yet | — | — | create_session `session_01R1w2UuT7VcXg1qRF2cqKDV` (§ 3.3) |
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
