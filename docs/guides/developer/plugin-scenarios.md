# Writing a plugin scenario

**Status:** Active (in knk-plugin `next` since `309d3580`, 2026-11-14; not on trunk yet) · **Last updated:** 2026-11-15 (§ 1, § 3.5, § 4.6, § 4.7 and § 6: NPC navigation scenarios on Citizens and a fake road network, `ScenarioRoadNpcs`, [#543](https://github.com/PandiO/knk-workspace/issues/543)); 2026-11-15 (§ 1 "Then" step 4: smoke-guide tag format, every step kept in full); 2026-11-14 (§ 1, § 3 and § 4: the scenarios and helpers of the plugin backfill, [#511](https://github.com/PandiO/knk-workspace/issues/511)); 2026-11-14 (§ 5 links #540); 2026-11-14 (first version, [PandiO/knk-workspace#421](https://github.com/PandiO/knk-workspace/issues/421))
**Related:** [CI § 7.1](ci.md#71-in-plugin-scenarios) (how CI runs them), [plugin architecture § Testing](../../architecture/plugin-architecture.md#testing),
[`knk-test-writer` skill](../../../.claude/skills/knk-test-writer/SKILL.md) (which suite a behaviour belongs in),
[AI agent workflow design § 6.3](../../specs/ai-agent-workflow/DESIGN.md#6-testing-and-ci),
[plugin configuration § 4.28](../admin/plugin-configuration.md#428-testing)

A plugin scenario proves world behaviour on a real Paper server: it builds a small scene (blocks, a region, entities,
the data the plugin would get from the API), plays it out over server ticks and asserts the result. CI runs every
scenario after the Paper boot test, so a feature that is checked this way no longer needs the developer's evening
test in game. Use one for what unit tests can't show: blocks moving, regions deciding, entities being moved, state
changing after a delay (global instructions, "Testing: automated first").

## 1. A scenario in under 30 lines

A class in knk-plugin `knk-paper/src/main/java/net/knightsandkings/knk/paper/scenario/scenarios/` (imports left out):

```java
public final class TntOutsideRegionsScenario implements Scenario<ScenarioScene> {
    @Override public String name() { return "tnt-outside-regions"; }
    @Override public String description() { return "TNT outside every region breaks no blocks"; }

    @Override
    public void define(ScenarioPlan plan, ScenarioScene scene) {
        AtomicReference<TNTPrimed> tnt = new AtomicReference<>();
        plan.act("build a stone wall", () -> {
                for (int x = 0; x < 5; x++) scene.block(10 + x, 2, 10).setType(Material.STONE, false);
            })
            .act("prime TNT next to it", () -> {
                tnt.set(scene.spawn(12.5, 2, 11.5, TNTPrimed.class));
                tnt.get().setFuseTicks(10);
            })
            .await("the TNT exploded", 60, () -> !tnt.get().isValid())
            .check("the wall is intact", () -> {
                for (int x = 0; x < 5; x++)
                    if (scene.block(10 + x, 2, 10).getType() != Material.STONE) return "block " + x + " broke";
                return null;
            });
    }
}
```

Then:

1. Register it in `PaperScenarios.registry()` (the order there is the order of `run all`).
2. Raise `MIN_SCENARIOS` in the boot step of `.github/workflows/paper-boot.yml` by one.
3. Break the behaviour once (comment out the rule, invert the check) and see the scenario fail, then restore it
   (knk-test-writer § 3.5).
4. In the smoke-test guide, tag the step it covers and keep the step's full manual text:
   `[automated: plugin scenario <name>] <the step as written>`, or `[partly automated: plugin scenario <name>; by hand:
   <what is left>]` when a player still has to check part of it (developer decision 2026-11-15).

The shipped scenarios are fuller examples (`PaperScenarios` lists all 22): `GateOpenCloseScenario`,
`GateClosingMovesEntityOutScenario` and `GlobalRegionExplosionScenario` (the full version of the example above, with a
control inside a region) came with the framework; the backfill of
[#511](https://github.com/PandiO/knk-workspace/issues/511) added seven gate-safety scenarios (`GateClosingKeepsSidesScenario`
and the others named `Gate…Scenario`: mobs, a dropped item and a minecart as stand-ins for players), two region-callback
scenarios (`LootboxAreaRenameScenario`, `LootboxAreaReplaceScenario`), the temp-region sweep
(`TempRegionSweepScenario`) and three lootbox spawn scenarios (`LootboxSpawnOnGroundScenario`,
`LootboxSpawnUnderRoofScenario`, `LootboxSwitchedOffScenario`). The NPC follow-ups of
[#521](https://github.com/PandiO/knk-workspace/issues/521) added three corner scenarios on a generated scene
(`NpcCornersLineScenario`, `NpcCornersWalkScenario`, `NpcStuckLadderScenario` with `NpcCornerScene` and the helper
`ScenarioNpcs`, which starts a Citizens registry of its own and follows the scene's route line;
[implementation plan 4b.2 item 18](../../specs/npc-platform/IMPLEMENTATION_PLAN.md)).
[#543](https://github.com/PandiO/knk-workspace/issues/543) added three NPC navigation scenarios on a fake road graph
(§ 4.6, § 4.7), from the NPC developer tests of the [implementation plan](../../specs/npc-platform/IMPLEMENTATION_PLAN.md):

1. `npc-walks-road-route` (`NpcWalksRoadRouteScenario`): one NPC is sent along a straight road of 25 blocks; it
   arrives within 1.5 blocks of the goal, the road route was handed to it in stretches (not walked as off-road hops),
   and no stuck event fired.
2. `npc-keeps-to-road-around-obstacle` (`NpcKeepsToRoadScenario`): a stone block stands on the straight line between
   start and goal, the road makes a wide U around it; the NPC is never more than 2 blocks from the road's centre line
   (the open grass between block and road is shorter) and arrives. Measured: 0.37 blocks at most (0.08 with the
   #521 corner clearance on `next`).
3. `npc-group-keeps-spacing` (`NpcGroupSpacingScenario`): a leader and two followers in a column, 2 blocks apart, walk
   a straight road; neighbours stay between 1 and 4 blocks apart while walking (half and twice the spacing; measured
   1.64 to 2.72) and end within 1 block of the 2-block spacing (measured 1.94 and 2.0; 2.5 and 2.0 on `next` with
   #521).

A scenario must fail when its behaviour breaks. For the backfill each behaviour was broken once on a local server (the
side rule, the other-door rule, the suffocation guard, the predictive push, the region rename, the lootbox area lookup,
the spawn height, the web switch and others) and the matching scenario failed; for the NPC scenarios (#543) the road
graph ignored (the planner answering "no road network": all three failed), the column formation's slots at a third of
their distance (the group scenario failed with gaps of 0.14 blocks) and the road line never walked (the mover ignoring
its waypoints: all three failed, the obstacle one with the NPC 4 blocks off the road); a scenario that kept passing was changed
until it didn't (for example `gate-side-by-side-doors` needed walls in front of both doors, or the nearest spot was
never the other door's opening). Where a fallback could hide a broken behaviour, assert that the fallback never ran:
the gate scenarios count suffocation events, cancelled ones included, so a mob the guard rescued still fails.

## 2. Steps

`ScenarioPlan` (knk-core `net.knightsandkings.knk.core.scenario`) collects the steps; every method returns the plan.

| Step | What it does |
|---|---|
| `act(description, runnable)` | Runs once. |
| `expect(description, condition)` | Fails with "expected: <description>" when false. |
| `expectEquals(description, actualSupplier, expected)` | Fails with "<description>: expected X, was Y". |
| `check(description, supplier)` | The supplier returns null to pass, or the failure reason ("3 of 9 cells are still stone"). |
| `waitTicks(n)` | Lets the server run `n` ticks (20 ticks = 1 second). |
| `await(description, timeoutTicks, condition)` | Checks every tick until true; fails with "timed out after N ticks waiting for: <description>". |
| `cleanup(description, runnable)` | Always runs at the end, also after a failure, last added first. |

1. Acts and checks that follow each other run in the **same tick**; only `waitTicks` and `await` let time pass. Prefer
   `await` with a generous timeout over a fixed wait: it is as fast as the server and still bounded.
2. The first failing step ends the scenario; an exception in any step fails it too, with the step's description and
   the exception. Throw `ScenarioAssertionError("reason")` from your own helpers for a reason without the class name.
3. `define` runs once per run before the first step. Build nothing there: do the work in `act` steps, so a failure is
   reported as a step. Hold objects the steps create in an `AtomicReference` (see the example).
4. Everything runs on the server thread.

## 3. The scene

Each scenario gets a `ScenarioScene`: an empty box of 32 × 24 × 32 blocks (x, y, z), given out by `PaperScenarioHost`.

1. **Coordinates** are relative to the box's lowest corner: x and z from 0 to 31, y from 0 to 23. `scene.block(x, y, z)`
   and `scene.location(x, y, z)` turn them into world blocks and locations; `worldX/Y/Z` give the absolute numbers
   for data that carries world coordinates.
2. **Before and after** the scenario the box is cleared to air (no physics) and every entity in it except players is
   removed. Its chunks are force-loaded for the run, so blocks and entities tick without a player nearby.
3. **Your cleanup** is only for state that lives outside the box: a gate in the gate cache, a WorldGuard region, a
   changed setting. Register it with `plan.cleanup(...)` right after the step that creates it.
4. **Helpers:** `scene.spawn(x, y, z, Pig.class)` (removed with the scene); `scene.onEvent(EntityDamageEvent.class,
   handler)` listens at MONITOR priority, cancelled events included, until the scene closes; `scene.fakeId(n)` gives
   a negative id for fake API data; `scene.uniqueName(suffix)` a name for a region or other plugin state;
   `scene.services()` the live plugin services (§ 4).
5. **Shared helpers** in the scenarios package: `ScenarioGates` (portcullises in up to four id slots and any depth,
   `stillPig`, `overlaps`, `unharmedProblem`, `countSuffocation`), `ScenarioRegions` (WorldGuard regions in scene
   coordinates, `shapeProblem`, and `callRename`, the `POST /Regions/rename` knk-web-api sends to the plugin's region
   callback server, answered on the main thread, so `await` its future), `ScenarioFakes.port` (an in-memory port, § 4)
   and `ScenarioLootboxes` (the plugin's own lootbox runtime and spawn scheduler on fake API data, recording where it
   asks for boxes); `ScenarioRoadNpcs` (NPC navigation on a fake road network, § 4.7: lays grass and a 3-wide dirt-path
   road along the scene (x, z) points you give, spawns Citizens NPCs, sends one or a group, measures the distance from
   the road's centre line and counts the navigation's events; `close()` as a cleanup, because NPCs are player
   entities the scene does not remove).
6. **Where:** `testing.scenarios.origin` (default 30000, 100, 30000) in the main world (or `testing.scenarios.world`);
   scene *n* of a run sits 64 × *n* blocks further along x. Keep it far from anything built.

## 4. Fake data instead of the API

Scenarios never need a running knk-web-api. They drive the plugin's **live** services (the ones the server ticks and
calls) and hand them the data the API would have sent:

1. **DTO-fed loaders** (gates and others built from API DTOs by an adapter in knk-paper): build the DTO the API would
   return and pass it to the same adapter the loader uses. `ScenarioGates.loadPortcullis` builds a `GateStructureDto`
   with one door and calls `GateLoaderAdapter.loadAndCacheStructure`, so the real `GateManager`, animation task, safety
   guard and spatial index handle it. `Portcullis.unload()` removes it again (a cleanup step).
2. **Data-access ports** (`knk-core/.../core/ports/api/*Api` interfaces, read through `core/dataaccess/*DataAccess`):
   implement the port in memory (a small class or a lambda per method the feature calls) and give that to the service
   under test, built inside the scenario, instead of the plugin's API-backed instance. Swap nothing in the live plugin.
   `ScenarioFakes.port(LootboxesQueryApi.class, Map.of("getRuntimeConfig", args -> …))` answers the named methods and
   fails on any other, so a scenario never leans on an answer it didn't define. `ScenarioLootboxes` builds a
   `LootboxRuntime` and `LootboxSpawnScheduler` this way; `TempRegionSweepScenario` gives a `TempRegionRetentionTask` a
   fake lootbox lookup and sweeps report-only (a deleting sweep would touch the test server's other temp regions).
3. **Callbacks the API makes to the plugin** (`RegionHttpServer`): call them over HTTP like the API does
   (`ScenarioRegions.callRename`, with the plugin's `api.auth.api-key`), never block the main thread on the answer.
4. **Ids are negative** (`scene.fakeId(n)`, from -421 000 000 down). A test server may still be connected to the dev
   API, and some code writes state back (a gate's open state after its animation); a negative id matches no real row.
   On the CI server those write-backs fail with a warning ("Failed to persist gate state"), which is expected.
5. **A service a scenario needs** goes into `ScenarioServices` as a supplier (read lazily, because some services start
   after the command is registered) and is wired in `KnKPlugin.registerScenarioCommand`. Since #543 it has the live
   road navigation service (`roadNavigation()`, for its walk capture) and the Citizens mover factory (`npcMovers()`,
   which fails the step with the reason `/knk npc status` gives when NPC navigation is off).
6. **A road network** (#543) is the road graph the router reads, a `RoadNetworkSnapshot` built in scene coordinates
   (floor points, one edge with an endpoint node at each end), and it reaches the NPCs through the navigator's own
   adapter: `NavigationService.planRoadFor` on a road navigation service the scenario builds with that snapshot as its
   network and every road open. Snapping, network components, the A* router and the route line are the live code.
7. **NPC navigation** (#543): the NPCs are spawned and moved by the live Citizens adapter, so the server needs Citizens
   and `npc.navigation.enabled: true` (CI sets both, [CI § 7.2](ci.md#72-citizens-on-the-ci-server)). Local legs are
   prepared by the live walk capture (`navigation.enabled` and `navigation.walk.enabled`, both on by default). The
   state machine (`NpcNavigationService`) and the groups (`NavGroupService`) are the plugin's classes, built inside the
   scenario with the code defaults of every per-NPC setting (a test server's `npc.navigation` keys don't change the
   result) and ticked every server tick, groups first, as the live module does. Access rules are open: these
   scenarios test movement; rules (a closed gate, a denied district) are a later scenario on the same helper.

## 5. Players

There are no players yet ([#540](https://github.com/PandiO/knk-workspace/issues/540) tracks simulated players). Paper
26.3 has no supported fake-player API, and a fake network connection is out of scope for now. What works without one: blocks, regions, mobs and other entities, plugin state, events, console commands.
What needs simulated players later (keep these steps manual, "scenario later", in the smoke-test guide): commands run
by a player and their permission checks, menus and clicks, chat, joining and leaving, a player being moved, damaged or
teleported. A mob often stands in for a player's body (the gate scenarios use a pig), but not for anything a player
does.

## 6. Running scenarios

1. **On a test server** (a local throwaway server, never the shared dev world with builds, the alpha or production):
   set in `plugins/KnightsAndKings/config.yml`

   ```yaml
   testing:
     scenarios:
       enabled: true
   ```

   (and, for the NPC scenarios, `npc.navigation.enabled: true` with the Citizens jar in `plugins/`), restart, then
   from the console (or as an op): `knk scenario list`, `knk scenario run all` or
   `knk scenario run <name>`. Results are in the console and `logs/latest.log`; a player who starts a run sees them in
   chat too. The startup log warns while the switch is on. One run at a time. With the switch off the command doesn't
   exist ("Unknown command: scenario"). With nobody online, set `pause-when-empty-seconds=-1` in `server.properties`,
   or vanilla stops ticking the server after 60 s.
2. **Like CI, on your machine** (JDK 25, `python3`, `unzip`): put `paper.jar` and the WorldEdit, WorldGuard and
   Citizens jars in an empty folder (`plugins/`; the pinned URLs are in the workflow's `env`), build with
   `./gradlew :knk-paper:shadowJar`, then
   `tools/paper-boot/boot-test.sh --server-dir <folder> --plugin-jar knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar --java <jdk25>/bin/java --scenarios --npc-navigation`.
   About three minutes with the NPC scenarios (the #521 corner walk alone takes 90 s); it prints the result table. Details: [CI § 7](ci.md#7-plugin-the-paper-boot-test).
3. **In CI:** every push and pull request runs all scenarios in the `paper-boot` job ([CI § 7.1](ci.md#71-in-plugin-scenarios)).
   The job summary shows the table; the `paper-boot-log` artifact has the full log.

## 7. Report lines

The contract between the plugin (`ScenarioReport` in knk-core) and `tools/paper-boot/check_scenarios.py`; change both
together:

```text
KNK-SCENARIO START gate-open-close
KNK-SCENARIO PASS gate-open-close (44 ticks)
KNK-SCENARIO FAIL gate-open-close: timed out after 100 ticks waiting for: the door is OPEN
KNK-SCENARIO SUMMARY passed=2 failed=1 total=3
```

Names are lower-case words joined by hyphens; `all` is reserved. A reason is always one line.
