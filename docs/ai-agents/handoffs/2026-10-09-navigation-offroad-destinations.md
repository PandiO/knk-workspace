# Handoff: off-road destinations — KNG-75 findings, the destination-snap quick fix, then KNG-75

**Status:** Ready, 2026-10-09. Prompt for a Claude Code session **on the developer's machine** (knk-workspace with the
component repos under `Repository/`, dev DB, dev server), **with Linear access**.
**Linear:** [KNG-75](https://linear.app/kngpandi/issue/KNG-75) (walk legs at both ends of a route, and destinations more
than 48 blocks off-road); parent [KNG-27](https://linear.app/kngpandi/issue/KNG-27) / [KNG-51](https://linear.app/kngpandi/issue/KNG-51).
**Last updated:** 2026-10-09

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first. Add a row for this
work, scoped to KNG-75, before editing.

**Check for overlap before coding.** Two other sessions touch navigation:
- **KNG-73** (cloud): `NavTarget`, `NavigationDestinations`, API/web-app per-type settings.
- **Rev. 7** (`docs/specs/navigation/REV7_PROPOSAL.md`; a separate session runs the decisions, handoff
  `2026-10-09-navigation-rev7-decisions.md`). Its Part A would rework routing in knk-core (`RoutingView`, `EdgeTagging`,
  `LiveEdgeTags`) and remove `RouteRequest.StartSides/GoalSides`.

This work touches `Snapper` / goal resolution (`NavigationService.resolveGoals`) and the direct leg. It does not
overlap KNG-73. If rev. 7 Part A has a claim by the time you start, coordinate the `Snapper` / `NavigationService`
changes through the tracker. Don't implement on top of an unmerged Part A.

Then read:
1. `docs/guides/road-navigation-smoke-test.md`, finding **N15** (under "Phase 4 / KNG-51 live test (2026-10-07)"), and
   the run 4 note on off-road destinations.
2. `docs/specs/navigation/LAST_MILE_PATHFINDING.md` §5 (budget, detour allowance), §7 (direct mode), §11-7 (Phase D
   scope).
3. `docs/specs/navigation/DESIGN.md` §6.2-§6.3 (snapping, direct mode, goals).

## State

Road navigation and walk paths are merged and live-tested:
- knk-plugin `main` `fd869aa` or later (includes KNG-74);
- knk-web-api `master` `4c570fa`;
- knk-web-app `main` `b51eba0`.

Standing branches: knk-plugin `claude/navigation-walkable-path` (`10b9a16`, a few merge commits behind `main`; merge
`origin/main` into it first), knk-web-api / knk-web-app `claude/road-navigation`. This work should need the plugin only.

## Task 1 — add the findings to KNG-75 (Linear)

Post this as a comment on KNG-75 (and check its state; it was Backlog when created on 2026-10-08):

> **Live test 2026-10-09 (developer), finding N15.** From (1419, 82, -550), `/nav Keep Tower Roof` (Location 79 at
> (1410, 113, -506)) says "Keep Tower Roof is too far from any road." Within 48 blocks of the target the walk path is
> used; beyond that, nothing.
>
> Measured on the dev DB:
> - the player stands on road edge 5487 (0.3 blocks away);
> - the straight distance to the target is 54.6, so not direct mode (48);
> - the target is **29.7** blocks (3D) from the nearest road: edge 10088 at (1410, 84, -516), the keep road 28
>   blocks below the roof;
> - the snapper weights height ×4 (`navigation.snap-vertical-weight: 4`), so it measures **112** > 48 → refused.
>
> So this case is not "far from a road" but the height weight, which exists so a road under a bridge doesn't snap to
> the bridge above it. For a **destination** the last leg is a walk path, which handles height (stairs, ladders), so the
> weight works against us there.
>
> Plan: (1) quick fix - snap destinations without the height weight, or with a lower one; (2) then this issue proper:
> walk legs at both ends, destinations further than 48 blocks off-road.

Move KNG-75 to In Progress when you start Task 2.

## Task 2 — quick fix: destination snapping without the ×4 height weight

**Where:**
- `NavigationService.resolveGoals` (knk-paper `navigation/`) snaps a POINT destination with
  `snapper.snapFloor(floor…)`, using `routerParameters.snapVerticalWeight()` (4) and `maxSnapDistance()` (48).
- `core/roads/route/Snapper` takes the weight from `RouterParameters`.
- The direct leg after the road's end starts when the target is within `maxSnapDistance` in **plain 3D**
  (`arrivedAtRouteEnd`).

**Proposal (confirm with the developer, briefly, before coding):**
- Destinations (POINT; NODE needs none; REGION goals already come from the region's road entries) snap with a separate
  weight: `navigation.destination-snap-vertical-weight`, default **1** (plain 3D).
- The player's start keeps ×4. That is where a road under a bridge must not snap to the bridge.
- Keep the 48-block limit.

**Also check:**
- `connectedGoals` (re-snap into the start's component) uses the same destination weight.
- `/knk road why` uses the same goals.
- A destination 28 blocks *above* a road now gets a road route plus a walk leg. If the walk search can't climb there
  within its budget (length cap ~78 for a 30-block leg, 20 000 expansions), the player gets "No conventional path"
  for the last leg, with a partial path where there is one. That is the intended behaviour, not a refusal.

**Tests:**
- `NavigationServiceTest`: a target 30 blocks above a road in the test network is routed (with ×4 it was refused).
- The bridge case: a start under a bridge still snaps to the road below.
- `ConfigLoaderNavigationTest`: the new key.
- Check each test fails without its fix.

**Live re-test for the developer:** from (1419, 82, -550), `/nav Keep Tower Roof`. Expect a road route to below the
keep, then a walk path up, or "No conventional path" if there is no walkable way up.

Commit on `claude/navigation-walkable-path`, build with `./gradlew build --offline -x deployToDevServer`, push, tell
the developer the commit to deploy, and record the result in the guide (N15).

## Task 3 — KNG-75 proper (after the quick fix is live-tested, and if not blocked)

The scope from the issue's feasibility notes, in steps:
1. **Walk leg at the start.** A player off-road within 48 blocks gets a walk path to the road's start point instead of
   the straight line, with the same mechanism as the last leg (`DirectLeg`, `WalkLegPreparer`). Likely shape: a direct
   leg before the routed session, ending at the route's start snap point, then the session.
2. **Destinations up to ~96 blocks off-road.** A separate `max-destination-distance`, bounded by the walk search's
   `max-length` (96), the capture box (`WalkSnapshotService`, a chunk limit per request) and the expansion budget.
   Measure the capture cost for a 96-block leg first (`WalkReplayTest` on copied region files,
   `tools/road-replay/README.md`).
3. **Further than that:** chained walk legs. This is KNG-36 territory; ask the developer, don't build it unasked.

Open questions to ask the developer first (from the issue):
- What should the player see when the destination is beyond the walk range?
- Should the 48-block player limit grow too, once the first leg is a walk path?

Make it one commit per step, with tests, and a live re-test per step.

## Rules

**Builds:**
- Plugin: `./gradlew build --offline -x deployToDevServer`; a plain `build` deploys. Deploy on purpose with
  `./gradlew :knk-paper:dev`.
- Test summary: count the XML results under `*/build/test-results/test/`.

**Data:**
- The dev DB is read-only unless the developer approves a write. There is no `mysql` in PATH: use the Workbench client
  with a temporary `--defaults-extra-file` built from `Repository/knk-web-api/appsettings.json`, and delete it
  afterwards.

**Live tests:**
- Check the deployed jar's time against the server restart in `logs/latest.log` before concluding a fix failed.
- Temporary INFO diagnostics at the decision points worked well for hard cases (see `1fae2af` / `10b9a16`).

**Process:**
- Every new test must fail without its fix. The C3 bug (a per-id policy cache) was hidden by a test fake.
- Keep messages to the developer short.
