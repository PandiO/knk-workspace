# Navigation walkable-path chain — progress report

**Status:** running (link 1 done; link 2 next)
**Last updated:** 2026-10-02 (link 1)
**Charter:** [`docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md`](../ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md)
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) (reconcile), [KNG-51](https://linear.app/kngpandi/issue/KNG-51) (implement)
**Design:** [`docs/specs/navigation/LAST_MILE_PATHFINDING.md`](../specs/navigation/LAST_MILE_PATHFINDING.md)

This file is append-only: each link adds its own section below; only the summary and the header are refreshed.

## Summary for the developer

| Link | Phase | State | Branch heads | Details |
|---|---|---|---|---|
| 1 | KNG-27 reconciliation | **done** 2026-10-02 | knk-plugin `claude/navigation-walkable-path` `d8507a3` (= `claude/road-navigation` `075ae94` + 1 test commit); workspace `main` | [Link 1](#link-1--kng-27-reconciliation) |
| 2 | KNG-51 Phase A (`knk-core roads/walk/`) | next | — | — |
| 3 | KNG-51 Phase B (knk-paper capture, cell access) | not started | — | — |
| 4 | KNG-51 Phase C (`DirectLeg`, walk trail, config) | not started | — | — |

**Review first**
1. `IMPLEMENTATION_PLAN.md` "§5.5 status" — all six fix-plan items are code-complete on `claude/road-navigation`; every
   item's live "Verify" step is still yours. Item 6 skipped the planned "catalogue residual cases after item 5 is
   verified live" step (items 5 and 6 landed together), so your rebuild re-test is the first real check.
2. Stretches recorded with `/knk road record` before `8b6d678` sit one block too deep — re-record them.
3. Plugin `9dccb58` and API `c029186` must be deployed together (an older plugin can't parse the `Pruned` node kind).

**Test when you have time:** pull `claude/navigation-walkable-path` in knk-plugin; `./gradlew build -x deployToDevServer`;
`./gradlew :knk-paper:dev`; then the live checklist (link 1's is the KNG-27 re-test below; links 2-4 add theirs).

## Link 1 — KNG-27 reconciliation

**Session:** Claude Code cloud session, 2026-10-02 ~19:00-20:00 UTC. Started from the link-1 handoff
(`2026-10-02-navigation-walkable-link-1.md`).

### Setup
- Heads at start (unchanged during the link): knk-plugin `origin/claude/road-navigation` `075ae94` (trunk `main`
  `27b4236` contained), knk-web-app `6414e18`, knk-web-api `c029186`. `claude/road-navigation-smoke-test-bugs-fagl4i`
  is still identical to `claude/road-navigation` in all three repos. No new developer commits after 18:00 CEST.
- Created knk-plugin **`claude/navigation-walkable-path`** from `origin/claude/road-navigation` `075ae94`; `origin/main`
  was already contained (no merge commit). Pushed with `-u`. Push checks: plugin feature branch ✔, workspace `main` ✔.
- Network: `repo.papermc.io`, `maven.enginehub.org`, Maven Central all 200 — **knk-paper compiles in the cloud**.

### Baselines (for links 2-4) — knk-plugin `075ae94`, `./gradlew build -x deployToDevServer`, BUILD SUCCESSFUL

| Module | Tests | Failures | Skipped |
|---|---|---|---|
| knk-core | **1561** | 0 | 0 |
| knk-api-client | **184** | 0 | 2 |
| knk-paper | **1088** | 0 | 14 |

After link 1 (`d8507a3`): knk-core 1561, knk-api-client 184, **knk-paper 1089** (+1, link 1's test). Links 2-4 compare
against these numbers. Counted from `*/build/test-results/test/*.xml`.

Other repos (read/run only, no changes): knk-web-api `c029186` `dotnet test` (SDK 8 installed in the session): 1631
passed / 5 failed / 42 skipped — the 5 are the known non-road baseline failures. knk-web-app `6414e18`: road suites
(`components/admin/roads`, `components/roads`) 16/16; `npm ci` fails on a stale lockfile (`yaml@2.9.1` missing) and
`@testing-library/dom` is not a declared dependency — both pre-existing, not KNG-27's.

### §5.5 verification
Per item (commits, code vs plan, tests, live status): `IMPLEMENTATION_PLAN.md` → "§5.5 status". Short form:

| Item | Commit(s) | Code | Tests | Live |
|---|---|---|---|---|
| 1 FeedbackModal | web-app `6414e18` | ✔ (only call site in the road tree) | ✔ | click-through |
| 2 region goals follow the road | plugin `6a73945` | ✔ | ✔ | needs live |
| 3 direct-mode re-check | plugin `6a73945` (+ link 1 test `d8507a3`) | ✔ | ✔ (gap closed) | needs live |
| 4 "already in X" | plugin `6a73945` | ✔ (WorldGuard containment, checked first) | ✔ | needs live (4-case matrix) |
| 5 plaza = one junction | plugin `9f66fea` | ✔ | ✔ | live rebuild |
| 6 cleanup survives rebuild | plugin `ef556e2`, `6a8caa7`, `9dccb58`, `075ae94`; web-api `8523ec8`, `c029186` | ✔ (locked-node reach instead of an exclusion zone; plan left it open) | ✔ | residual cases need live |

### Commits
- knk-plugin `claude/navigation-walkable-path`: `d8507a3` — test `theLastLegAfterTheRoadsEndUsesTheDirectReCheck`
  (item 3's "the `arrivedAtRouteEnd` handoff participates in the recheck" had no test; test only, behaviour unchanged).
- knk-workspace `main`: tracker claim; `IMPLEMENTATION_PLAN.md` "§5.5 status" + header; smoke-test guide
  cross-references for findings B, C, D, E, G and Phase 4/5 findings 1-7, plus a "rebuild re-test (2026-10-02)" block
  reconstructed from the developer's commits; KNG-27 tracker row corrected (the 2026-10-01 "paused" row was stale);
  this report; link 2's handoff.

### Flagged decisions
- **L1-1:** the link-1 test commit lives on `claude/navigation-walkable-path`, not on `claude/road-navigation` (the chain
  never pushes there). It reaches trunk when this branch does; cherry-pick `d8507a3` if you merge
  `claude/road-navigation` first and want it there.
- **L1-2:** nothing else was fixed. Open items found but out of §5.5 scope (written up, not fixed): finding D (upload
  timeout), finding E (no node/tile delete; restart for builder settings), `/knk road node info here`, a "prefer the
  domain's Location" option (smoke-test finding 4).

### Discrepancies
- The tracker and the workspace docs did not record any of the §5.5 work (corrected).
- Item 6 deviates from the plan's sketch (exclusion zone per locked node) — it uses a build-wide `locked-node-reach`
  (default 8) and duplicate absorption; the plan left the radius question open, so this is within scope.
- knk-web-api `master` has 19 commits `claude/road-navigation` lacks — merge before merging to trunk.

### Live checklist (developer) — KNG-27 re-test
1. Full restart (builder keys are read only in `onEnable`; new keys `navigation.builder.plaza-growth` default 2,
   `locked-node-reach` default 8); rebuild tile 2,-2 and a
   known problem plaza → one junction per plaza, no "Boundary node … not on the tile border".
2. Merge a duplicate junction pair, rebuild the tile → stays merged. Prune a spur (`/knk road node prune`), rebuild →
   stays out; `unprune` brings it back.
3. Re-record stretches recorded before `8b6d678`.
4. `/navigate` to a District/Structure region with roads nearby, from several sides → trail follows the road, short
   last leg only; a region with no road near it → straight line (or refusal beyond 48 blocks).
5. Stand inside a cuboid and a polygon region (mid-height, boundary block, stacked level) → "You are already in X".
6. Direct mode: walk away → "heading away … recalculating"; routed: leave the road → "You left the road"; reach a
   road's end short of the target and walk away → the same "heading away" message.
7. Web app: delete a road profile → FeedbackModal, failure keeps the modal open.
8. Then resume Phase 4 item 20 of the smoke test. The straight line through terrain (finding 1) stays until KNG-51.

### Risks
- None of items 2-6 has been seen working in game yet; links 2-4 build on `recheckDirect` (item 3) — if the live test
  finds it wrong, link 4's `DirectLeg` refactor is where it gets corrected.
- The developer may keep committing to `claude/road-navigation`; links 2-4 merge it at start and before their final push.

### Next link
Link 2 — KNG-51 Phase A. Handoff: `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-2.md`. How it was
started: see the line below (added after the start).
