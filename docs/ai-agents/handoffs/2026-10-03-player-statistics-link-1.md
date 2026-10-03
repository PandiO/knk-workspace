# Player statistics chain — link 1 handoff

**Date:** 2026-10-03 · **Written by:** coordinator session (chain start) · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

Read `docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md` first (branch `claude/kind-dijkstra-y9d279`) and follow it;
it overrides anything below.

Implement **link 1 — Design completion + implementation plan** end to end (audit report, finalized `DESIGN.md`, new
`IMPLEMENTATION_PLAN.md`, feature register, commits, push to `claude/kind-dijkstra-y9d279`, progress report, link 2
handoff, start link 2) as link 1 of the chain. Docs only: no code changes in this link.

**State you start from.**
- Feature branch `claude/kind-dijkstra-y9d279` exists in all four repos. Code repos are identical to trunk at chain
  start (knk-plugin `27b4236`, knk-web-api `ae0b3ad`, knk-web-app `fc66101`). knk-workspace: trunk `main` + the merged
  draft design + the chain docs (charter, this handoff, progress report).
- `docs/specs/player-statistics/DESIGN.md`: the draft player-facing decisions (2026-09-29) plus the binding
  "Developer decisions 2026-10-03" table D1-D13 and the leaderboard recommendation.
- No test baselines recorded yet — link 1 doesn't build; link 2 records the API and app baselines, link 3 the plugin's.

**Phase-specific reading.** The charter's §9 "Facts at chain start" (a code map of what already exists: ledger, Siege
match persistence, discoveries, audit log, permission model, menus, plugin hooks). Verify, don't trust: it is a
snapshot from a read-only scan.

**What link 1 must produce** (charter §5 "Link 1"): the source audit report, the finalized design, the implementation
plan with per-link file lists and acceptance criteria, feature register/spec hub updates, KNG-14/KNG-23 reconciliation.
Make the plan concrete enough that links 2-7 never have to re-decide data shapes: table/column names, endpoint routes
and DTOs, plugin class names and config keys, permission node names, event names. Keep each link's scope achievable in
one session; re-cut links 2-7 only under charter §0.

**Open flags that affect this link.**
- AFK mode (developer didn't answer): analyse V1 (`knk-v1-archive`) and V2 AFK behaviour; choose a reversible default.
- GDPR deletion scope: what is deleted vs. pseudonymized (ledger rows have accounting value; Siege match rows involve
  other players). Choose the most privacy-protective option consistent with keeping other players' records intact,
  and flag it.
- The owner concept: the web app has an "Owner" *ActiveMode* but no owner permission node; D12 needs dedicated nodes
  (e.g. `knk.owner.telemetry.view`) that the default staff groups don't get. Check how nodes are seeded/granted.
- Leaderboards: confirm the metric list against what links 3-4 can actually record.

**Known risks.** The plan is the contract for six code links — vague sections become repeated rework. Siege combat
code is being changed on trunk by another session (Codex, 2026-10-03); plan link 4's hooks as new listeners/event
subscriptions rather than edits inside their files where possible.

**Next after you:** link 2 — API foundation.
