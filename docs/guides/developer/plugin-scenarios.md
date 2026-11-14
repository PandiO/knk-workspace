# Writing a plugin scenario

**Status:** Active (in knk-plugin `next` since `309d3580`, 2026-11-14; not on trunk yet) · **Last updated:** 2026-11-14 (first version, [PandiO/knk-workspace#421](https://github.com/PandiO/knk-workspace/issues/421))
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
4. In the smoke-test guide, mark the step it covers: `[automated] … : plugin scenario <name>`.

The three shipped scenarios are fuller examples: `GateOpenCloseScenario`, `GateClosingMovesEntityOutScenario` and
`GlobalRegionExplosionScenario` (the full version of the example above, with a control inside a region).

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
5. **Where:** `testing.scenarios.origin` (default 30000, 100, 30000) in the main world (or `testing.scenarios.world`);
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
3. **Ids are negative** (`scene.fakeId(n)`, from -421 000 000 down). A test server may still be connected to the dev
   API, and some code writes state back (a gate's open state after its animation); a negative id matches no real row.
   On the CI server those write-backs fail with a warning ("Failed to persist gate state"), which is expected.
4. **A service a scenario needs** goes into `ScenarioServices` as a supplier (read lazily, because some services start
   after the command is registered) and is wired in `KnKPlugin.registerScenarioCommand`.

## 5. Players

There are no players yet. Paper 26.3 has no supported fake-player API, and a fake network connection is out of scope
for now. What works without one: blocks, regions, mobs and other entities, plugin state, events, console commands.
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

   restart, then from the console (or as an op): `knk scenario list`, `knk scenario run all` or
   `knk scenario run <name>`. Results are in the console and `logs/latest.log`; a player who starts a run sees them in
   chat too. The startup log warns while the switch is on. One run at a time. With the switch off the command doesn't
   exist ("Unknown command: scenario"). With nobody online, set `pause-when-empty-seconds=-1` in `server.properties`,
   or vanilla stops ticking the server after 60 s.
2. **Like CI, on your machine** (JDK 25, `python3`, `unzip`): put `paper.jar` and the WorldEdit and WorldGuard jars in
   an empty folder (`plugins/`), build with `./gradlew :knk-paper:shadowJar`, then
   `tools/paper-boot/boot-test.sh --server-dir <folder> --plugin-jar knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar --java <jdk25>/bin/java --scenarios`.
   About 35 seconds; it prints the result table. Details: [CI § 7](ci.md#7-plugin-the-paper-boot-test).
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
