# Siege overnight chain — morning report

**Status:** Chain started 2026-09-26 (evening). Each chain session appends its phase section and rewrites the
Morning summary. Rules: `docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md`.
**Last updated:** 2026-09-26 (skeleton, before link 1)

## Morning summary

_Not started yet. Link 1 (Phase 6) replaces this section._

| Phase | State | Branch heads after it | Stopped because |
|---|---|---|---|
| 6 — Match persistence and rewards | not started | | |
| 7a — Gate integration + area lockdown | not started | | |
| 8b — Siege menus | not started | | |
| 7b — Non-member gate view | not started | | |
| 9 — Seeds and docs (non-live parts) | not started | | |

### Review first
_(ranked decisions from all phases)_

### Smoke-test order for the morning
1. Redeploy: plugin from knk-plugin `claude/siege-minigame` (`./gradlew :knk-paper:dev`, after checking
   `ACTIVE_SESSIONS.md`; note the shared checkout may be on another branch - use a worktree), web-api from its
   `claude/siege-minigame` branch.
2. Apply any new web-api migrations to the dev DB (developer only).
3. `/siege admin reload`.
4. Phase 5 steps still open from playtest round 1: 4 (inventory guards, incl. the owner/staff-mode exemption),
   7 (friendly fire, safe zones, headshots), 10 (main-objective capture win), 14 (crash test), 16 (book chooser by
   right-click). Plan: Phase 5 status → "Manual live verification".
5. Each new phase's checklist, in plan order (added below by each link).

## Phase sections

_(appended by each link: commits per repo, tests vs baseline, flagged decisions with review-first ones marked,
discrepancies, short live checklist, risks, how the next link was started)_
