Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

**Start condition (charter §4.7, plan §0.5):** KNG-17 (teleport, `origin/claude/teleport`) must be on knk-plugin
trunk. Check first: `git -C <knk-plugin> fetch origin main && git -C <knk-plugin> ls-tree -r --name-only origin/main |
grep core/teleport/WarpTargets`. **Written 2026-09-28 by link 8, when it was NOT on trunk** (`main` still `eb1d68c`):
if it still isn't, do not start — say so in the progress report and stop. If it is, you are **link 9**.

Implement road navigation **Phase 4 — knk-plugin paper: `/navigate`** from docs/specs/navigation/IMPLEMENTATION_PLAN.md
(the "Phase 4" section: R22/R21/R20 extractions from the teleport code, the R6 follow-up, `NavigationDestinations`,
`NavigateCommand`, `NavigationService`, live changes incl. D13, the siege read-only accessors R24/R39,
`TrailRenderer` + `NavigationHud`, the four events, `NavigationMessages`, tests), end to end (code, tests, commits,
push to `claude/road-navigation`, plan status block, progress report, handoff), as **link 9** of the chain. Phase 4
is "M-L": charter §5 allows a split at a commit boundary — a natural one is **4a** = trunk merge + R22/R21/R20/R6
extractions + `NavigationDestinations` + `NavigateCommand` (parse, resolve, refuse) and **4b** = `NavigationService`
+ availability + live changes + trail/HUD + events. If you split, mark the status "partial" naming exactly which
classes, tests and behaviours exist and hand the rest to link 10 as `…-phase-4b.md`.

**First step of the code work: merge trunk into `claude/road-navigation`** (`git merge origin/main`, no rebase).
Expected conflicts (plan §0.5, Phase 2a status): `KnKPlugin` (teleport's inline data-access construction vs Phase 3's
`initializeRoads()` fields — keep one instance each, R18) and `SimpleRegionTransitionService` (teleport's
`previewAccess` vs Phase 2a's `DomainAccessEvaluator` extraction — make `previewAccess` delegate to the evaluator and
feed its `knk.region.bypass` predicate into the evaluator's bypass input, R6). Resolve mechanically, keep both sides'
behaviour, run the scratch build's knk-core tests before adding anything.

**knk-paper compiles only where `repo.papermc.io` and `maven.enginehub.org` are reachable** (charter §1.5). In links
1-8 both were denied by the cloud network policy; Phase 3's paper code is therefore **not compiled** yet — the
developer's local `./gradlew build -x deployToDevServer` is its real compile. If you also cannot compile: same rule —
careful reading, "not compiled" in the status, Bukkit-free pieces (destination name resolution, session bookkeeping,
HUD text, re-plan rate limits) behind helpers the plan §0.4 scratch build can run (a third scratch project for the
Bukkit-free paper files exists in link 7's recipe — see the Phase 3 progress-report section). Prefer running this
phase on the developer's machine if that is an option.

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`); nothing
  for Phase 4 to change. Read-only clone: `GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 --branch claude/road-navigation
  https://github.com/PandiO/knk-web-api /home/user/pandio/knk-web-api`.
- **Phases 2a-2e and 3 are done** (links 2-7): knk-plugin `claude/road-navigation` **`96f4c62`** (as of 2026-09-28;
  trunk `main` was `eb1d68c` — it will have moved when KNG-17 merged: fetch). knk-core **1374** tests, knk-api-client
  **174** (2 live-only skips), knk-paper Bukkit-free scratch tests **34** (+17 Mockito tests written, not run) — all
  via the §0.4 scratch build.
- **Phase 5 is done** (link 8): knk-web-app `claude/road-navigation` `9dbb481` (cut from `main` `f56d421`); nothing
  for Phase 4 to change; street names reach the plugin through Phase 3's `StreetCache` (60 s refresh).
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (status
  "finished for now"; set it back to "running", append your Phase 4 section, refresh the summary table — the 4 row is
  "waiting for KNG-17") and the tracker row in `docs/ACTIVE_SESSIONS.md` (in "Recently completed"; add a new "In
  progress" row for Phase 4 naming the files, or move the row back).

What earlier phases say Phase 4 must wire (read every "→ 4" note in the plan's status blocks):
- **2d (router/session; "Phase 2d status → What later phases must wire → 4")** — per request build
  `CompositeAccessPolicy.of(new StaticFlagsAvailability(), new GateAvailability(gateState, passRule), new
  DomainAvailability(evaluator, lookup, regionIdsAt(player), bypass))`; `GateState` from `GateManager.getGate(id)` →
  `GateView(id, structure name, getCurrentState(), isJammed(), isEffectivelyDestroyed(), isEffectivelyAllowPassThrough(),
  SiegeGateController.isLocked(getGateStructureId()), canCarryNonMember(door))` (R5, R24, R39); `PassRule` =
  `GatePassThroughRules.canPass(player, door)` (R25); `new Snapper(snapshot, routerParameters).snap(feet)` (refuse
  with the DESIGN messages when empty; direct mode within 48 blocks); goals: point → `Snapper.snapFloor`, named node →
  `SnapPoint.atNode`, region → `RegionClosestPoint.goals(RegionShape.polygon/cuboid(...), snapshot)` (refuse "already
  in X" when `containsFloor(player)`); `new AStarRouter(snapshot).routeOrExplain(RouteRequest.of(start, goals, policy,
  parameters))` → `RouteResult` (route or `BlockedExplainer` explanation); `NavigationSession` (feet position in,
  floor blocks out; `SessionParameters` from config; `NavigationEffect`s applied on the main thread R12);
  `ManeuverBuilder`/`EtaEstimator` for the HUD; re-route rate limits (decision 15: 60 ticks off-route/blocked, 200
  ticks and > 15 % shorter for "something opened"). Everything in **floor-block** coordinates (feet = floor + 1).
- **3 (paper admin side; "Phase 3 status → What later phases must wire → 4")** — `plugin.getRoadNetworkCache()
  .snapshot(world)` (floor-y network, swapped atomically; `addListener` for swaps → re-plan), `NavigationConfig` via
  `config.navigation()` (`routerParameters()`, `sessionParameters()`, `trail()`),
  `plugin.getRegionTracker().regionIds().at(player.getLocation())` for `DomainAvailability`,
  `plugin.getRegionDomainResolver()`, `gateManager.addStateListener` (fires on every mutation path now — R4),
  `ParticleDraw.polyline(player, points, spacing, Particle.DUST, dustOptions)` for the trail (R9), `KnkLocations`
  (R10), `TickBudget` (R11), `RoadMessages` conventions for `NavigationMessages` (R26), `knk.navigate` node (declared
  in `plugin.yml`, default true), `/knk road why <destination> [--as <player>]` to implement in `RoadAdminCommand`.
- **2a (R6)** — after the trunk merge, teleport's `previewAccess` delegates to `DomainAccessEvaluator`; its
  `knk.region.bypass` predicate becomes the evaluator's bypass input (also `DomainAvailability`'s).
- **Teleport branch (R20-R22; plan §2 rows)** — `BlockProbe` → `C/util/BlockProbe`, `SurfaceGrid extends BlockProbe`
  (it already declares the five methods with the same semantics, incl. exclusive `maxY`); `WarpTargets` →
  `C/util/NamedTargets<T>` generalisation, `WarpTargets` a thin wrapper; `SpawnDestinationResolver.ownLocation` →
  `C/navigation/DomainLocationResolver`; teleport tests stay green without edits beyond imports.
- **Siege (R24, R39; plan §0.2's allowed edits)** — `siegeGates` field + getter in `KnKPlugin`, and the read-only
  `SiegeGateController.canCarryNonMember(CachedGateDoor)` extraction (its two callers use it). Coordinate via
  `ACTIVE_SESSIONS.md` first (§0.5); siege tests green; nothing else in siege changes.

Phase-specific reading: plan §0 (esp. 0.2 siege rules, 0.5), §1 rows D2, D13, §2 rows R5, R7, R12-R15, R19-R28, R39,
"Phase 4" whole, the 2a/2d/3 status blocks' "→ 4" notes; DESIGN §6 (whole: command forms, route computation, closest
point of a region, guidance, maneuvers, events, availability), §4 config keys, §7 `/knk road why`. knk-plugin: the
teleport code once on trunk (`C/teleport/*`, `P/teleport/*`), `P/discovery/DiscoveryEligibility` (R23),
`P/discovery/DiscoveryFlushTask` (R27), `P/commands/PayCommand` + `KnKPlugin.registerTabCommand` (R14),
`P/events/*` (custom event style), `P/siege/SiegeService` observers (R24), `P/siege/SiegeMessages.command` (R26).

Open flags that affect this phase: D2 (siege areas are *not* blocked; a siege-locked gate is passable when the
siege's own non-member rule would carry the player — R39); D13 (2-second gate re-check on active routes besides the
listener); Phase 2d decisions 7-8 (blocked start edge → no route with an explanation; "Guiding you to the gate" ends
at the junction before the gate edge) and 10 (a no-exit domain ends the route on the last edge inside).

Known risks:
- **The trunk merge is the biggest unknown** — KNG-17 conflicts in `KnKPlugin` and `WorldGuardRegionTracker` /
  `SimpleRegionTransitionService`; keep Phase 3's `initializeRoads()` intact and R18's one-instance-each rule.
- **Phase 3 is uncompiled Paper code** — if trunk's build runs here for the first time, expect the one-line slips
  listed in the plan's "Phase 3 status → Developer to-do" before your own code compiles.
- **Siege** is being playtested in parallel: only the two mechanical edits above, each in its own commit.
- **Main-thread cost:** routing off-thread (api-client executor), effects via R12; `TickBudget` for the trail.
- **Size:** "M-L" — commit and push after each logical part (merge; extractions R22/R21/R20/R6; destinations +
  command; service + availability; live changes; trail + HUD; events + messages; tests).

Next after you: **last link** — after Phase 4 the chain is complete (charter §top). Write the closing handoff listed
in plan §8 ("a short handoff in `docs/ai-agents/handoffs/` listing branches to delete") and stop; the developer
merges phase by phase after testing.
