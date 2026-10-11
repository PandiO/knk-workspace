# KNG-34 player statistics — smoke test handoff (local session)

**Date:** 2026-10-10 · **Written by:** coordinator session `session_01VPBn2FkTWsZwbyyc3Y5RYY` · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)
**For:** a Claude Code session on the developer's machine, with the dev server, the database and the developer at hand.

## Your job

Guide the developer through the KNG-34 smoke test, record every result, fix what fails, and — when everything passes and
the developer says so — merge the feature into the trunks. The developer plays the in-game steps; you prepare, check
logs, the database and the API, and keep the record. Ask for one step (or a small group) at a time and wait for the
result. Check the dates and branch heads below against reality before trusting them (global instructions, "Authority
and freshness").

## Read first

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and each repo's `AGENTS.md`/`CLAUDE.md`.
2. `docs/ACTIVE_SESSIONS.md` on `main` — claim the row (see below) before changing anything.
3. **The checklist:** `docs/guides/player-statistics-smoke-test.md` (on `claude/kind-dijkstra-y9d279`). It is the script
   for this session and the place where results go (Findings table).
4. `docs/specs/player-statistics/DESIGN.md` — decisions D1-D23 and §F are binding; check a surprising behaviour against
   them before calling it a bug.
5. `docs/reports/2026-10-03-player-statistics-chain.md` — the summary, "Decisions to review" (things that look odd but
   are deliberate), the 2026-10-10 trunk-merge block, and the per-link blocks when you need the details of a part.

## State you start from (2026-10-10)

- Branch **`claude/kind-dijkstra-y9d279`** in all four repos; trunks merged in on 2026-10-10. Heads: knk-web-api
  `66c01cb`, knk-plugin `598b5bd3`, knk-web-app `8c367a2`, knk-workspace: the commit that added this file or later.
  The developer may have merged more small fixes to the trunks since — merge `origin/<trunk>` into the branch first in
  every repo (knk-web-api `master`, the others `main`). Conflicts so far were always both sides adding things: keep both.
- **knk-plugin was never compiled in the cloud** after the trunk merges (Maven Central rate limits). The first build is
  yours: `./gradlew build -x deployToDevServer`. The merge resolutions to look at first if it fails: `KnkConfig`
  (record = navigation + statistics + telemetry + worldAnalytics, with all shorter constructors), `ConfigLoader`,
  `KnkApiClient`, `UserCommand` (`VisiblePlayers` + the `settings` suggestion), `KnKPlugin.onDisable`.
- knk-web-api: builds; tests 2364 passed / 4 failed (pre-existing: `ClientActivityStore`, `FieldValidation`,
  `PathResolution` ×2) / 71 skipped; no pending model changes. knk-web-app: `tsc` clean; tests 619 passed / 5 failed
  (also red on `main`).
- New since the review: D21 (discovery counts follow enabled types), D22 (migration `SeedStatisticsStaffNodes`: Moderator
  `knk.admin.statistics.view`; Admin also `knk.admin.privacy.request`), D23 (data deletion clears the player's name on
  road-builder proposals).

## Rules for this session

- **Tracker:** add an "In progress" row on `main` for "KNG-34 smoke test" naming the branch and this session; update it
  when you pause, finish or merge.
- **Fixes** for failed steps go on `claude/kind-dijkstra-y9d279` in the repo concerned, with a test where the logic can
  be tested, one commit per finding, the finding number in the message; push, redeploy, re-run the step and anything it
  touches. A failure that needs a design change or a new decision goes to the developer first, with a recommendation.
- Something that fails on trunk too is not KNG-34's: note it in Findings and leave it.
- Never `force`-push, rewrite history or delete branches. Back up the database before the first API start.
- Keep `docs/guides/player-statistics-smoke-test.md` current after each group of steps (status line, Findings), commit it
  on the branch.

## When everything passes

Only on the developer's explicit go: follow §6 "Merge" of the checklist (order knk-web-api → knk-plugin → knk-web-app →
knk-workspace; merge trunk into the branch once more, rebuild/retest, then merge into the trunk), then update the
CHANGELOG (Unreleased entry → merge date), the FEATURE_REGISTER rows, the guide's status, the tracker (move to Recently
completed) and Linear KNG-34 (comment; Done if the developer agrees).

## After the merge (not in this session unless the developer asks)

Follow-ups the developer postponed until after the merge (progress report, "Suggested alignment changes", items 4-6):
road-tile ETag read failures not reported as `api.call_failed`; optional navigation and domain-access-refusal
telemetry/analytics; world analytics briefly dropping batches for regions renamed from `tempregion_worldtask_*`;
command correlation ids not crossing async permission checks.
