# Siege Survival — Implementation Plan

**Status:** Planned; documentation only. No gameplay code implemented in KNG-50's design publication.
**Last updated:** 2026-09-30
**Linear:** [KNG-50](https://linear.app/kngpandi/issue/KNG-50/siege-survival-endless-npc-waves-gate-repair-and-match-economy), child of KNG-37; shared NPC platform dependency KNG-36.
**Design:** [DESIGN.md](DESIGN.md) is authoritative for gameplay. Proposed integration choices and open clarifications remain explicitly marked there.
**Documentation branch:** `codex/kng-50-siege-survival-design`; publish to workspace main explicitly authorized by Pandi. Future code work must claim its own files and check standing branches before starting.

## 1. Before implementation

Read current AGENTS.md and shared instructions; refresh ACTIVE_SESSIONS and publish a feature-scoped claim. Refresh the actual default branch of every affected repository (workspace main, plugin main, API master, app main at this design date); never infer shipped behavior from a stale handoff or unmerged feature branch.

Inspect current Siege actor/roster/capture/lifecycle, player vault and inventory guards, gate animation/health/ownership APIs, lootbox roll/reel and pending delivery, ledger/rewards and FormConfiguration authoring. Record reusable paths and actual required changes. Check KNG-36's minimal NPC vertical slice before selecting an adapter; keep actor identity distinct from persistent User rows. KNG-27 can supply high-level routes only after its status and fitness are verified.

Resolve DESIGN section 13 clarifications in the issue, preserving the confirmed gameplay. Author a representative Defend the Castle scenario with multiple gate lines, alternate routes, several NPC spawnzones, lane routepoints and repair/shop/box points. No reward amounts until Pandi supplies progression targets.

## 2. Phases and deliverables

| Phase | Work | Exit condition |
|---|---|---|
| 1 — contracts/config | Add survival mode settings, role-aware readiness, wave/difficulty/special profiles, NPC zones/lanes and purchase references. Design immutable match configuration and result/checkpoint contracts. | CRUD and configured location rules validate a castle scenario; PvP scenario validation unchanged. |
| 2 — wave runtime/NPC slice | Implement wave queue/alive accounting, intermission respawn/spectating, wipe/main-objective termination, lane traversal, gate breach and NPC capture membership. | One complete wave, breach and capture work on the castle; no NPC-team auto-forfeit. |
| 3 — repairs/frontier | Add shared repair work, contributor channel, completion/animation integration, ownership cancellation and objective-driven zone frontier. | A04–A08 pass, including destroyed-door reconstruction and general entity collision tests. |
| 4 — BOTH equipment modes/economy | Preserve own-gear safeguards; add match loadout, death drops, pickup lifetime/cleanup, personal balance, transfers, fixed purchases and Mystery Box match adapter. | A09–A11 pass; no real inventory/instance/currency leaks. Both modes are required for first release. |
| 5 — specials/rewards/recovery | Add both special schedules, configurable reward inputs, API settlement/idempotency, persistent results/pending payout and restoration/restart behavior. | A01/A12–A14 pass; reward calibration preview works and final rates await review. |
| 6 — authoring/UX/telemetry | Extend existing forms/menus/HUD/history; document admin and player flows, repair timing/special previews, debug metrics. | A15 passes and complete castle scenarios exist for both equipment modes. |
| 7 — live validation/balance | Execute acceptance matrix, regression and load/fault checks; collect representative match data; derive economy tables from developer targets. | Developer verifies gameplay and balance; only then mark implemented/ready to merge code. |

Do not split the first release by deferring one inventory mode or Mystery Box. Phases describe implementation order, not permission to ship an incomplete requested mode. Publish status and handoffs with exact commits, actual verification and remaining live checks after each phase.

## 3. Validation and recovery plan

Pure/core checks: additive repair work and pause/cancel semantics; wave queue completion; difficulty composition; explicit/interval schedule resolution; spawnzone prerequisites/recapture; reached-versus-completed accounting. API checks: configuration/readiness, authoritative reward calculation, duplicate/retried settlement, atomic match transfers/purchases and one-roll-one-delivery. Regression checks: ordinary Siege player-only PvP, inventory restore, drop guards, non-member gates, lootbox world quotas/claims, ledger and title progression.

Live castle checks: NPC and player obstruction handling at reconstructed/closing gates, large NPC bounding boxes, mobs crowding narrow lanes, alternate routes and blocked-but-breakable paths, repaired closures requiring reroute, side-objective progression, two repairers under combat, last-player death/main capture race, intermission pickup/spawn selection and Mystery Box interruption.

Fault checks: API loss during start/repair purchase/result reporting; plugin restart while inventory is replaced or a box reel is running; duplicate request delivery; cleanup and settlement retries; disconnect/no remaining humans; chunk unload and stuck enemies. Restore ordinary player/gate state without issuing duplicate equipment or rewards. Proposed first release aborts on restart instead of promising match resume.

Load checks: expected and late-wave worst-case live NPCs, spawn backlog, dropped items, path request count, core/server tick time and multiple lobbies. Establish measured budgets with KNG-36 before declaring limits sufficient. Bound queues and prefer paced spawning over dropping planned enemies as 'kills'.

Documentation-only publication validation: confirm every 2026-09-30 decision is represented; verify referenced paths and issue links; check formatting and diff whitespace. No compile/build/live checks are claimed by this publication.

## 4. Future implementation handoff

Claim KNG-50 under ACTIVE_SESSIONS; inspect current defaults and KNG-36. Read DESIGN sections 2–9 before touching existing Siege defaults. Record resolutions to section 13. Implement in a standing feature branch per affected repo; update this plan with per-phase commits and results. Complete tests and live castle verification, refresh admin/player guides, add feature-register/changelog entries where the KNG-33 workflow has landed, and request the developer's code merge decision. This design publication authorizes documentation on main; it does not imply gameplay implementation or deployment.

