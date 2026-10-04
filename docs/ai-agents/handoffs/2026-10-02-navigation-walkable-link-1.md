Read docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md first and follow it; it overrides anything below.

Implement link 1 — KNG-27 reconciliation end to end (verification, docs, tracker, baselines, feature branch, progress
report, handoff to link 2), as link 1 of the chain.

State you start from: knk-plugin `origin/claude/road-navigation` `075ae94`, knk-web-app `6414e18`, knk-web-api `c029186`
(charter §9). Workspace `main` has `docs/specs/navigation/LAST_MILE_PATHFINDING.md` (KNG-51 design, all decisions made except
the live test of §11-5) and does **not** yet record that §5.5 items 1-6 landed. No test baselines recorded yet.
What this link must produce for link 2: the feature branch `claude/navigation-walkable-path` in knk-plugin (created from
`claude/road-navigation` + trunk), the baseline test counts per module (knk-core, knk-api-client, knk-paper) in the
progress report, and a tracker row for the chain.
Phase-specific reading: `IMPLEMENTATION_PLAN.md` §5.5 (the six items and their "Verify" steps),
`docs/guides/road-navigation-smoke-test.md` (Findings), the commits named in charter §5 "Link specifics".
Open flags: the developer committed to `claude/road-navigation` on 2026-10-02 (17:13-18:00 CEST) and may continue — merge it
in before you finish. Item 6's residual cases and item 5's live rebuild can only be confirmed by the developer in game.
Known risks: a stale tracker (the 2026-10-01 "paused" KNG-27 row) — correct it, don't build on it; knk-paper may not
compile in the cloud (charter §1.4).
Next after you: link 2 — KNG-51 Phase A.
