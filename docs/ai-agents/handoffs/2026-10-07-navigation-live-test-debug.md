# Handoff: road navigation live test — debug walk paths and Structure destinations

**Status:** Ready, 2026-10-07. Prompt for a Claude Code session **on the developer's machine** (knk-workspace with
the component repos checked out, dev DB, dev server and world reachable).
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51).
**Last updated:** 2026-10-07

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first. The rows
"Road navigation (KNG-27) rev. 6 Part B" and "Navigation walkable-path chain" are the relevant ones; add a short row
for this debug session when you start. Then read:
1. `docs/specs/navigation/LAST_MILE_PATHFINDING.md` §4-§9 (walk rules, search, direct mode, capture, config).
2. `docs/reports/2026-10-02-navigation-walkable-chain.md`, "Combined live checklist (developer)".
3. `docs/guides/road-navigation-smoke-test.md` section 4 (Phase 4) and the header.

## State

| Repo | Branch | Head | Deployed |
|---|---|---|---|
| knk-web-api | `claude/road-navigation` | `176b9d3` | yes (all road migrations applied, incl. `AddRoadCuratedTiles`) |
| knk-plugin | `claude/navigation-walkable-path` | `c6a6d14` | yes (compiled and deployed on this commit) |
| knk-web-app | `claude/road-navigation` | unchanged | — |
| knk-workspace | `main` | `c637350` or later | — |

- These standing branches now contain road navigation (KNG-27), the walkable paths (KNG-51) and curated tiles
  (rev. 6 Part B). Curated tiles passed their live test on 2026-10-05.
- Nothing of road navigation is on trunk yet. Trunk is 2 commits ahead in the API and in the plugin; the trunk merge
  comes after this live test.
- Commit fixes to the **standing branches** above, one commit per fix, each with a test. Push them, and tell the
  developer which commit to deploy.

## The live test so far (2026-10-07, developer)

This is the "Part 2" checklist (KNG-51 + Phase 4 leftovers; full list at the end of this file):
- **Prep.** The server config has the `navigation.walk` section.
- **A1 (unreachable target, decision §11-5):** could not run; every available destination is reachable. Skipped.
- **A2 (kill switch):** accepted.
- **A3:** `/nav Northern Gate Square` from "The Keep" followed the roads to the right place. That is **routed mode**,
  though, not a walk-path test.
- **A4 (multi-level plaza):** reported as working, but A3/A4 are only meaningful in direct mode (see Problem 2).
- **A5 (the 2026-10-01 "13 m wall" Structure case):** blocked by Problem 1.
- **Walk-path check:** blocked by Problem 2.

## Problem 1 — no Structures among the `/navigate` destinations

**Facts:**
- The dev DB has four Structures:

  | Id | Name | LocationId | Location (x, y, z) |
  |---|---|---|---|
  | 14 | Northern Gate | 47 | (1386.3, 52, -588.2) |
  | 13 | South Gate | 39 | (1421.4, 49, -450.3) |
  | 11 | Keep Gate | 76 | (1428.7, 90, -516.7) |
  | 12 | Keep Stair House | 36 | (1416, 72, -532) |

  Query used:
  `SELECT d.Id, d.Name, d.LocationId, l.X, l.Y, l.Z FROM structures s JOIN domains d ON d.Id = s.Id LEFT JOIN locations l ON l.Id = d.LocationId;`
- `/nav structure:` + Tab completes nothing.
- The console shows the catalogue load: `POST /api/Domains/search` and `POST /api/Locations/search`, both 200, page
  size 200. The response bodies were not logged.

**What the code says (read in the cloud, not yet verified on the server):**
- **Tab completion.** `NamedTargets.complete` (knk-core `core/util/NamedTargets.java`) offers the `type:name` form
  **only for names two items share**. Unique names are offered bare, so typing `structure:` matches nothing by
  design. Check: `/nav Keep` + Tab, and `/nav Keep Stair House` should find the Structure.
- **Gates are dropped.** knk-web-api `GateStructure : Structure`. The domain search maps `DomainType` from
  `GetType().Name` (`Mapping/DomainMappingProfile.cs`), so a gate comes back as `"GateStructure"`. The plugin's
  `NavTarget.Type.ofDomainType` (knk-paper `navigation/NavTarget.java`) knows only `town`, `district` and `structure`.
  It returns null for `GateStructure`, and `NavigationDestinations.refresh` drops the item. So Northern Gate, South
  Gate and Keep Gate are probably not destinations at all.
  - Check which rows are gates in the DB: find the gate table via `KnKDbContext` (`Entity<GateStructure>` →
    `ToTable`).
  - Check the response: log the `/api/Domains/search` body (`DomainCatalogQueryApiImpl`), or POST the same body
    yourself with the plugin's `X-API-Key`.

**Decide with the developer, then fix:**
1. **Should gate structures be `/navigate` destinations?** The likely answer is yes: map `gatestructure` to STRUCTURE,
   or add a GATE type with its own `type:` word. Tests in `NavTargetTest` / `NavigationDestinationsTest`.
2. **Completion:** should a `type:` prefix list every item of that type, e.g. `structure:` + Tab →
   `structure:Keep`…? Small change in `NamedTargets.complete`, with a test; tab completion is shared with teleport,
   so check its tests too.
3. Then run A5. The 2026-10-01 case was a Structure reached via its Location, where the road ended about 13 m short
   behind a wall. "Keep Stair House" (1416, 72, -532) or one of the gates is the likely candidate; ask the developer.

## Problem 2 — walk paths not used in direct mode

**Facts:**
- `/nav` to a destination within about 40 blocks, with terrain in between, still shows the straight line.
- The "found" counter on `/knk road status` ("walk paths" line) did not go up.
- The plugin is `c6a6d14`, with a `navigation.walk` config section present.

**Code path** (knk-paper `navigation/NavigationService.java`):
- `startDirect` draws the straight line, then `requestWalk` if `walkEnabled()`. `walkEnabled()` needs
  `deps.walk() != null` (built by `KnKPlugin.initializeWalkPaths`, null when `navigation.walk.enabled` was false at
  start-up) and `config.walk().enabled()`.
- `requestWalk` counts REQUESTED. It captures through `navigation/walk/WalkLegPreparer.prepare`; a null request
  counts NOT_CAPTURED, an exception FAILED. The search runs on the walk executor: `WalkPathfinder` / knk-core
  `roads/walk/WalkSearch`, `WalkGrid`, `MovementProfile`.
- `walkDelivered` turns the result into FOUND (the trail switches to the path) or NO_PATH / FALLBACK (straight
  line).
- `walkStatus()` prints `requested / found / no path / budget / not captured / failed`, plus the capture description.

**First step: let the counters tell you where it stops.** Have the developer copy the whole "walk paths" line from
`/knk road status` before and after one direct-mode `/nav`. A direct-mode start says "X is N m away" in chat, not
"Navigating to X - N m".

| What moves | Where to look |
|---|---|
| "walk paths: off (…)" | Config not read, or the walk services were not started. Check `ConfigLoader` for the `navigation.walk` keys and `KnKPlugin.initializeWalkPaths`. |
| REQUESTED does not move | `startDirect` / `recheckDirect` not reached: routed mode, or the direct leg is created elsewhere. |
| REQUESTED and NOT_CAPTURED | `WalkLegPreparer`: capture box size (`capture-margin`, `max-length` 96, `max-length-factor`), unloaded chunks, the capture queue. |
| REQUESTED and FAILED | Console stack traces ("[Navigation] Walk capture/search failed"). |
| REQUESTED and NO_PATH or budget | The walk rules: start/goal snapping of the feet and target floors, the collision predicate (shared with the road builder's `PassabilityRules`, curated collidable list), `max-drop`, `max-expansions` 20000, doors and region access (`WorldGuardWalkAccess`). |

There is a `FINE` log line per result. Make it visible (logger level), or add a temporary INFO line while debugging.

**Reproduce offline where possible.** knk-core has `WalkSearch`/`WalkGrid` tests in the ASCII-layer fixture style. For
a world reproduction, the replay harness reads real region files (`knk-plugin/tools/road-replay/README.md`,
`RoadReplayTest`), and its Anvil reader and `CompactSurfaceGrid` capture can feed a `WalkGrid` for one start/target
pair. Confirm the cause from data and code, and report it, before changing shared walk or builder code.

## Remaining checklist after the fixes

Prep: keep `/knk road status` handy (walk-path counters and the capture µs per chunk). Direct mode means a target
within 48 blocks, or the last stretch after a road's end.

**A. Walkable paths (KNG-51)**
- **A1:** an unreachable target → straight line, and the "no path" or "budget" counter goes up. Get the developer's
  verdict: straight line or a partial path? Record it in `LAST_MILE_PATHFINDING.md` §11-5.
- **A3:** a town alley with height differences → the trail follows it, with no line through walls.
- **A4:** a multi-level plaza → the path stays on the right level and uses the stairs or ramps.
- **A5:** the 13 m wall case → the last stretch goes around the wall. This case is part of the definition of done.
- **A6:** cliffs → drops of 3 blocks or less only; never 4 or more.
- **A7:** a closed gate on the shortcut → detour or straight line. Opening it → the path takes it within about 2 s.
- **A8:** a region you may not enter → the path goes around it.
- **A9:** a door without interact rights → the path avoids it; with interact rights or bypass it goes through.
- **A10:** a ladder shortcut → the path climbs it.
- **A11:** blocks placed or broken on the path → corrected within about 10 s, or at once when the player is more
  than 6 blocks off the path.
- **A12:** a target at the edge of a low view distance → straight line, "not captured" goes up, no chunk loads.
- **A13:** `/tick rate 5` while a path is computed → no hitch; the straight line shows until the path arrives.
- **A14:** a detour that first leads away → no "heading away" message; walking off the path → the message. The HUD
  arrow follows the path. Note the capture µs per chunk.

**B. KNG-27 fix leftovers**
- **B1:** District and Structure region destinations from several sides → the trail follows the road, with a short
  last stretch.
- **B2:** standing inside a cuboid and a polygon region (mid-height, boundary block, stacked level) → "You are
  already in X".
- **B3:** direct mode, walking away → "heading away … recalculating". Routed, off the road for more than 2 s →
  "You left the road – recalculating." (missing on 2026-10-01).
- **B4 (optional):** web app, delete a throwaway road profile → FeedbackModal; a failure keeps it open.

**C. Phase 4, still open** (guide section 4)
- **C1:** re-check the `[~]` destination items with walk paths: Location by name and by `location:#id`, Town and
  Town + `region`, District, Structure, and arrival.
- **C2:** target more than 48 blocks from any road → "X is too far from any road."
- **C3:** a gate closes on the route → recalculation, or guidance to the gate. Opening it → a shorter route if more
  than 15 % shorter.
- **C4:** a pass-through gate → the right-click hint, and the route goes through it.
- **C5:** `allowEntry=false` → guided to the edge; with bypass the route goes in. `allowExit=false` → routes stay
  inside, or the player is told why.
- **C6:** siege → a locked gate counts as passable for non-members; joining a lobby ends navigation; `/navigate` is
  refused in a lobby.
- **C7:** `/knk road build here` mid-route, on a curated tile (only a proposal) and on an uncurated tile → no
  exception.
- **C8:** ending a session → death; `/tp`, `/spawn` or `/back` over 16 blocks (but not under); world change; quit
  and rejoin (no stuck boss bar); `max-session-minutes: 1` → timeout.
- **C9:** `/knk road why <dest>`, with `--as <player>`, and from the console.
- **C10:** `/knk cache refresh` → a new web-app Town appears in tab completion within about 60 s.
- **C11:** three players navigating at once (healthy `/tps`, trails private); a restart mid-session (clean log).

**D. Regression checks** (guide section 5)
- **D1:** `/spawn`, `/warp`, `/warps` tab completion, `/tpa`, `/back`.
- **D2:** allowEntry / allowExit messages, and refused teleports.
- **D3:** a siege match (gates lock and unlock, non-members pass).
- **D4:** `/knk gate open|close|force`, destroy and repair, right-click pass-through.

## Rules

- Build with `./gradlew build --offline -x deployToDevServer` (plain `build` deploys), or `./gradlew :knk-paper:dev`
  to deploy on purpose. Tests: never build a `Location` around an inline `mock(World.class)`; keep the World in a
  field.
- knk-web-api: build and test with `--artifacts-path <scratch>` if the Visual Studio debugger holds `bin/Debug`.
  The dev DB is read-only unless the developer approves a write; migrations need a go-ahead each time.
- Never run the road reset script, and never import the old phpMyAdmin dump.
- Record the findings in the smoke-test guide under a new "Phase 4 / KNG-51 live test (2026-10-07)" heading. Number
  them N1, N2 …; M1-M3 were curated tiles. Update the tracker row.
- Keep messages to the developer short; they work through the checklist between other work.
