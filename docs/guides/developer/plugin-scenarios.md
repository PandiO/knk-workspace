# Writing a plugin scenario

**Status:** Active (in knk-plugin `next` since `309d3580`, 2026-11-14; not on trunk yet) · **Last updated:** 2026-11-16 (§ 1: the checks of the NPC movement scenarios since links M3, M4, M5 and M7, the three collision scenarios of M7 (48 scenarios), scripted pushes with `ScenarioPushes`; § 5.2 item 3: `move()` is refused on Paper 26.3; checked against knk-plugin `next` `cc5262ff`, docs [#658](https://github.com/PandiO/knk-workspace/issues/658)); 2026-11-15 (§ 2 item 3 and § 7: `npc-stuck-ladder` and `npc-stairhouse-singles` with `local-legs-clearance` on, report lines with the local legs, #623); 2026-11-15 (§ 7: the singles of `npc-stairhouse-singles` and `npc-jagged-straight` are checks with corridor steering on, #622); 2026-11-15 (§ 1, § 3 item 7 and § 7: scenes pasted from WorldEdit schematics (`SceneSchematic`, the developer's stair house), the five NPC movement scenarios in report mode with collision off and on, `KNK-NPC-REPORT` lines, 45 scenarios, [#621](https://github.com/PandiO/knk-workspace/issues/621)); 2026-11-15 (§ 1: `player-heal-needs-grant`, 32 scenarios with #522's, [#580](https://github.com/PandiO/knk-workspace/issues/580)); 2026-11-15 (§ 1 and § 4.7: the six NPC follow-up scenarios on the corner scene, `ScenarioNpcs` with access rules and gate crossings, `ScenarioNpcRules`, the short-trip rule; checked against knk-plugin `next` `deb7ff49`, [#589](https://github.com/PandiO/knk-workspace/issues/589)); 2026-11-15 (§ 5 rewritten: scripted players, `scene.player(...)`, six player scenarios; § 1, § 3.5, § 4.8, § 6 `run player-*`, new § 8 headless bot tests kept off, [#540](https://github.com/PandiO/knk-workspace/issues/540)); 2026-11-15 (§ 1, § 3.5, § 4.6, § 4.7 and § 6: NPC navigation scenarios on Citizens and a fake road network, `ScenarioRoadNpcs`, [#543](https://github.com/PandiO/knk-workspace/issues/543)); 2026-11-15 (§ 1 "Then" step 4: smoke-guide tag format, every step kept in full); 2026-11-14 (§ 1, § 3 and § 4: the scenarios and helpers of the plugin backfill, [#511](https://github.com/PandiO/knk-workspace/issues/511)); 2026-11-14 (§ 5 links #540); 2026-11-14 (first version, [PandiO/knk-workspace#421](https://github.com/PandiO/knk-workspace/issues/421))
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

The shipped scenarios are fuller examples (`PaperScenarios` lists all 32): `GateOpenCloseScenario`,
`GateClosingMovesEntityOutScenario` and `GlobalRegionExplosionScenario` (the full version of the example above, with a
control inside a region) came with the framework; the backfill of
[#511](https://github.com/PandiO/knk-workspace/issues/511) added seven gate-safety scenarios (`GateClosingKeepsSidesScenario`
and the others named `Gate…Scenario`: mobs, a dropped item and a minecart as stand-ins for players), two region-callback
scenarios (`LootboxAreaRenameScenario`, `LootboxAreaReplaceScenario`), the temp-region sweep
(`TempRegionSweepScenario`) and three lootbox spawn scenarios (`LootboxSpawnOnGroundScenario`,
`LootboxSpawnUnderRoofScenario`, `LootboxSwitchedOffScenario`). The NPC navigation follow-ups added six scenarios on
the corner test scene (`NpcCornerScene`, § 4.7), walked by real Citizens NPCs through the helper `ScenarioNpcs`
([implementation plan 4b.2 item 18 and 4b.3 item 14](../../specs/npc-platform/IMPLEMENTATION_PLAN.md)):

1. `npc-corners-line` (`NpcCornersLineScenario`, [#521](https://github.com/PandiO/knk-workspace/issues/521); needs no
   Citizens): K&K's half on the real blocks: stretches with corner clearance, recovery targets on the NPC's own floor,
   the shortcut check at the stair corner.
2. `npc-corners-walk` (`NpcCornersWalkScenario`, #521): 6 single NPCs and a group of 6 in `ranks` walk the scene for
   90 s; no NPC stands still longer than 3 s, every stuck spell is freed within 2 steps, nobody falls or trespasses,
   and the stuck counters add up.
3. `npc-stuck-ladder` (`NpcStuckLadderScenario`, #521): an NPC pushed into a corner walled in on three sides frees
   itself within the cap, the run log's count never passes it, and no two tries come within `recovery-wait-ticks`.
   Since link M6 ([#623](https://github.com/PandiO/knk-workspace/issues/623)) it runs with `local-legs-clearance` on:
   the ladder's local leg frees it, found by K&K's own search, with no engine leg and no `recovery_no_path`; it logs a
   `KNK-NPC-REPORT` line (how it was freed, the local legs).
4. `npc-group-narrows` (`NpcGroupNarrowsScenario`, [#522](https://github.com/PandiO/knk-workspace/issues/522)): a group
   of 9 in `cluster` walks the scene's 3-, 2- and 1-wide passages: 3 abreast, 2 abreast, a column and 3 abreast again,
   in that order; a one-block post on the north road changes nothing; no trespass, no fall, no stuck spell left open.
5. `npc-group-gate-finish-trip` (`NpcGroupGateFinishTripScenario`, #522): a scenario portcullis across the east road
   closes behind the leader of a group of 6 and opens after the group turned back. With `group-followers-finish-trip:
   true` the held followers reach their slots at the goal first (the member listener once each); with `false` they
   follow the leader at once. Nobody is moved by the door; no trespass.
6. `npc-group-access-change` (`NpcGroupAccessChangeScenario`, #522; [#520](https://github.com/PandiO/knk-workspace/issues/520)'s
   behaviour, now in CI): a group of 6 walks into a scenario WorldGuard region; entry is removed when half the column
   is inside. The followers outside stop at the edge, the ones inside walk on, all follow when entry returns; no
   trespass.

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

[#540](https://github.com/PandiO/knk-workspace/issues/540) added six scenarios with scripted players (§ 5):

1. `player-command-needs-grant` (`PlayerCommandNeedsGrantScenario`): two players with fake accounts type `/feed`; the
   one without `knk.feed` in-house is refused ("You don't have permission to use this command.") and stays hungry,
   the one granted it is fed and told "Replenished 16 hunger.".
2. `player-chat-group-colours` (`PlayerChatGroupColoursScenario`): a player whose account has the title Knight and the
   chat colours `&b`/`&6` says "hello there"; another player receives `-{Knight}- ScnSpeaker: Hello there` with title
   and name aqua and the brackets gold; a player holding `knk.mode.staff` in-house is shown as `[STAFF] …`
   ([#260](https://github.com/PandiO/knk-workspace/issues/260)).
3. `player-join-loading-hold` (`PlayerJoinLoadingHoldScenario`): a joining player (through `AsyncPlayerPreLoginEvent`
   and the server's player list) is told "Loading your account...", let go with "You're all set!" in SURVIVAL and no
   longer invulnerable; an owner (`knk.mode.owner`) is never held; a rejoin is held again.
4. `player-menu-click` (`PlayerMenuClickScenario`): two fake InventoryMenu templates (§ 4.8); a click on a button whose
   `actionPermission` the player lacks does nothing, the open button opens the second menu without the item landing
   on the cursor or in the inventory, its close button closes it.
5. `player-tp-into-closed-gate` (`PlayerTpIntoClosedGateScenario`, gate smoke test § 2 step 16): `/tp` into a closed
   door's blocks is refused without `knk.teleport.staff`; with it the survival player is moved out by the teleport
   hook before any suffocation event, at full health.
6. `player-rejoin-in-closed-gate` (`PlayerRejoinInClosedGateScenario`, step 17): an owner logs out in an open
   doorway, the door closes, and on the rejoin the join hook moves them out before any suffocation event.

Each was seen failing with its behaviour broken: the in-house check always allowing (the refused player was fed),
the brackets in the primary colour, `JoinLoadingGuard.hold` skipped, `MenuClickListener` not cancelling the click (the
button landed in the inventory) and the gate guard's teleport/join check skipped (one suffocation event each).
`player-command-needs-grant` first used `/heal` and found that on a server with WorldGuard the plain `/heal` was
WorldGuard's command ([#580](https://github.com/PandiO/knk-workspace/issues/580)). K&K now takes that label over at
startup (`CommandLabelTakeover`), and #580 added a seventh player scenario:

7. `player-heal-needs-grant` (`PlayerHealNeedsGrantScenario`): the server's plain `heal` label is K&K's and
   `worldguard:heal` stays WorldGuard's; three players with fake accounts and 4 health type `/heal`: the one without
   `knk.heal` in-house is refused by K&K ("You don't have permission to use this command.", not WorldGuard's "You
   don't have permission to do that.") and stays hurt, the one granted it and an op without it are healed with
   "Replenished 16 health.", and the granted one is healed again with `/knightsandkings:heal`. It failed on CI
   before the takeover (WorldGuard's refusal, and an op healed by WorldGuard) and passes with it.

[#621](https://github.com/PandiO/knk-workspace/issues/621) (link M1 of the NPC navigation follow-ups chain,
[implementation plan 4c.5](../../specs/npc-platform/IMPLEMENTATION_PLAN.md#4c5-evidence-the-real-places-as-scenarios))
added five NPC movement scenarios in **report mode**: they measure today's movement, log one `KNK-NPC-REPORT` line per
phase (§ 7) and pass whatever the numbers are; the later movement links turn the numbers they fix into checks. Each
is registered twice, with `npc.navigation.collidable` off (its name) and on (the name with `-collision-on`), with
`group-ranks-width` 3, on a scene pasted from a schematic (§ 3 item 7). Since link M2
([#622](https://github.com/PandiO/knk-workspace/issues/622)) the singles of `npc-stairhouse-singles` and
`npc-jagged-straight` run with `corridor-steering` on and are checks: all arrive, 0 stuck spells, nobody still longer
than 3 s, no fall, corridor steering's cost at most 0.03 ms per NPC per tick (`NpcMovementReport.singlesFailures`);
they still log their report line, now with a `corridor` part (stretches shaped, shared, cost). Since link M6
([#623](https://github.com/PandiO/knk-workspace/issues/623)) `npc-stairhouse-singles` also runs with
`local-legs-clearance` on and checks that no local leg ends without a path (`NpcMovementReport.localLegFailures`), and
every report line has a `local legs k&k N, engine N, none N` part:

8. `npc-stairhouse-singles`: on the developer's schematic, 12 singles at once, 6 from the street through the stair
   house's entrance (1413 49 -508), along the straight (1414 49 -503) and up two steps into the hall, 6 back out. Reports arrivals, stuck spells, the longest
   still single and the longest stand on the straight and in the entrance.
9. `npc-stairhouse-group`: a group of 20 in `ranks` from the street through the entrance into the hall, once. Reports the leader's result,
   the folds and narrowings with their reasons and places, the longest a follower stood in the entrance, lag and
   rejoins.
10. `npc-jagged-straight`: 12 singles both ways on a 3-wide straight with one-block notches, a lantern on a post and a
    stair block beside it, then a group of 9 in `ranks`.
11. `npc-doorway-crowd`: 6 singles from each of two rooms through a one-block doorway at once. Reports the ticks with
    two or more NPCs in the doorway's cell and the longest still near it.
12. `npc-plaza-line`: 3 singles cross a 15 × 15 plaza from the west road to the north road on the road graph's line
    (to the junction in the middle and out). Reports the walked length on the plaza against the chord and how close
    they came to the well.

Every line also has falls, trespasses, `recovery no path` and K&K's navigation time per NPC per tick. The first
numbers are the baseline in the chain report's M1 block.

The later movement links ([#624](https://github.com/PandiO/knk-workspace/issues/624) M3,
[#626](https://github.com/PandiO/knk-workspace/issues/626) M4, [#625](https://github.com/PandiO/knk-workspace/issues/625)
M5) turned the rest into checks; every phase still logs its report line. The keys each scenario runs with
(`NpcMovementReport.settings(...)`; `collidable` as its name says, `group-ranks-width` 3) and what fails it, as on
knk-plugin `next` `cc5262ff`:

| Scenario | Keys on | Fails when |
|---|---|---|
| `npc-stairhouse-singles` | `corridor-steering`, `local-legs-clearance` | a single doesn't arrive, a stuck spell, anyone still over 3 s, a fall, corridor cost over 0.03 ms per NPC per tick (`singlesFailures`); a local leg without a path (`localLegFailures`) |
| `npc-stairhouse-group` | `corridor-steering`, `local-legs-clearance`, `group-formation-keeping: elastic`, `crowd-awareness` | the leader doesn't arrive, more folds than 1-wide places on the line (measured with M1's `FreeWidth`), a stuck spell open, not freed or near a wall (`groupFailures`); a follower in the entrance over 10 s; any stuck spell, a wait longer than 3 s per NPC that went first, an NPC let go after 30 s (`crowdFailures`) |
| `npc-jagged-straight` | `corridor-steering`, `elastic` | the singles as above; the group of 9 with any fold or a stuck spell open, not freed or near a wall |
| `npc-doorway-crowd` | `corridor-steering`, `local-legs-clearance`, `crowd-awareness` | `crowdFailures` |
| `npc-plaza-line` | `elastic`, `plaza-lines` (not `corridor-steering`) | a single walks over 5 % more than the shortest line that keeps `wall-clearance` from the well, comes closer to the well than that clearance less 0.25 (the engine's walking slack), or within 2 blocks of the junction; its group of 7 in ranks of 3 also on the line round the well (at most 10 % over it, 1 block from the junction) and with no fold or stuck spell left (`groupFailures`) |

`npc-group-narrows` (L4) runs `elastic` since M3, with its expectations moved to the squeeze (no narrowing in the
2-wide passage, the column at the 1-wide one, 3 abreast after). [#627](https://github.com/PandiO/knk-workspace/issues/627)
(M7) added three scenarios with collision on, all with scripted players:

13. `npc-collision-policy` (`NpcCollisionPolicyScenario`): the scenario that chose the collision policy, kept as its
    regression. A fake player walks straight through a standing NPC and two NPCs start 0.2 apart: with collision off
    the player passes and the NPCs stay overlapped; with collision on (players never push) the NPC moves 0.00 and the
    two NPCs push each other apart; with `players-push-npcs` (and `push-return` off) the player carries the NPC, the
    reference.
14. `npc-guard-ledge-push` (`NpcGuardLedgePushScenario`): a guard at its post on a wall walk beside a 7-block drop. A
    fake player walks into it: without `players-push-npcs` it doesn't move; with it the player is exempted at the edge,
    the guard never falls and is back at its post; the third push within the window exempts the player and the
    fourth moves the guard 0.00; an attack knocks a walking, unprotected guard off its line and it walks back.
15. `npc-door-column` (`NpcDoorColumnScenario`): 12 singles one way through a one-block door with `corridor-steering`,
    `local-legs-clearance` and `crowd-awareness` on. Fails unless all arrive, no wait is longer than 3 s per NPC
    ahead, nobody stands still over 3 s outside a queue, none is let go after 30 s and every stuck spell is freed
    within 3 s. Stuck spells are allowed: the first two NPCs at the door mouth can both claim it and shove each other
    against the frame ([#657](https://github.com/PandiO/knk-workspace/issues/657)).

**Scripted pushes** (`ScenarioPushes.sweep(scene, player, from, to)`, knk-paper `scenario/scenarios/`): the fake
player walks through the NPC at 0.12 blocks a tick (about 2.4 blocks a second, a slow push) by a short
`ScenarioPlayer.teleport(...)` every tick; the server works collisions out from the bodies' boxes each tick, so a
teleport this short pushes like walking. It does not use `move()`, which Paper 26.3 refuses (§ 5.2 item 3).
`ScenarioPushes.ticks(from, to)` gives the sweep's length. To reach a Citizens NPC's body or let an attack land, use
`CitizensBootstrap.entity(mover)` and `CitizensBootstrap.setProtected(mover, false)` (Citizens' NPCs are protected by
default, so an attack neither hurts nor knocks them back).

With `collidable` on for every NPC scenario (a trial, not on CI), `npc-ledge-corner`, `npc-corners-walk`,
`npc-group-narrows` and `npc-stuck-ladder` fail; only the scenarios above run with collision on. That is why
`collidable` stays off by default ([implementation plan 4c.4 item 7.4.10](../../specs/npc-platform/IMPLEMENTATION_PLAN.md)).

A scenario must fail when its behaviour breaks (report-mode scenarios excepted until a link gives them checks). For the backfill each behaviour was broken once on a local server (the
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
   entities the scene does not remove); `ScenarioNpcs` and `ScenarioNpcRules` (real NPCs walking the corner scene,
   with access rules and gate crossings of their own, § 4.7). Scripted players come from the scene itself:
   `scene.player(name, …)` (§ 5).
6. **Where:** `testing.scenarios.origin` (default 30000, 100, 30000) in the main world (or `testing.scenarios.world`);
   scene *n* of a run sits 64 × *n* blocks further along x. Keep it far from anything built.
7. **A scene from a WorldEdit schematic** ([#621](https://github.com/PandiO/knk-workspace/issues/621)): put the
   `.schem` file in knk-paper `src/main/resources/scenario-scenes/` (it ships in the plugin jar, as the scenarios
   do), then `SceneSchematic.fromResource("name.schem").paste(scene, x, y, z)` pastes it with its lowest corner at
   box position (x, y, z), without physics. Air is not placed (the box starts empty) and blocks outside the box are
   left out and counted (`Pasted(placed, outsideTheBox)`), so a place a little larger than 32 × 24 × 32 still fits.
   1. **Making one:** in the world, as an op with WorldEdit, `//pos1 x,y,z`, `//pos2 x,y,z`, stand where the scene's
      reference point should be, `//copy`, `//schem save <name>`; the file is in `plugins/WorldEdit/schematics/`.
      `SceneSchematic` reads WorldEdit's Sponge format (version 3, which WorldEdit 7.3 and later save, and version 2)
      without WorldEdit itself, so it also runs in unit tests. It keeps the block states and leaves out block
      entities (sign texts, chest contents), entities and biomes.
   2. **Real coordinates:** `worldMin()` is the real position of the schematic's lowest corner and `origin()` the
      local position of the player who copied it; `local(realX, realY, realZ)` turns a place someone named (1414 49
      -503) into schematic coordinates.
   3. **A block the server doesn't know** (a schematic from a newer Minecraft) fails the paste with its name.
   4. **Synthetic scenes:** `tools/scenario-scenes/make_standins.py` in knk-plugin writes the NPC movement scenes in
      the same format (deterministic bytes: rerun it after a change and commit the files). `NpcMovementScene` holds the
      points the scenarios use for each scene (the road line, starts, goals, watched areas), and
      `NpcMovementSceneTest` checks that each of them stands on a floor of its schematic.
   5. **The developer's stair house:** `knk-stairhouse.schem` (copied in the dev world, 1407 49 -549 to
      1418 79 -487) is pasted in the frame box = real − (1400, 46, −515) at box (7, 3, −34), with a stone floor at
      real y 48 under its footprint (the copy starts one block above the street's floor). Rows outside the box are
      left out. `NpcMovementScene` draws its road line by hand from the street through the entrance (1413 −508) and
      the straight (1414 −503) up two steps into the hall. When the developer posts a trace, put its waypoints in.
      MockBukkit can't paste it (it knows no lantern properties), so only the Paper scenarios do.

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
   result) and ticked every server tick, groups first, as the live module does. The #543 road scenarios
   (`ScenarioRoadNpcs`) use open access rules: they test movement.
   1. **The corner scene** (`NpcCornerScene` in knk-paper `scenario/`): one loop of about 60 blocks with a 3-wide road
      and an inside 90° corner between walls, an outside corner, 2-wide and 1-wide passages, a staircase with a 90°
      turn at a ledge (slabs before and beside the corner, a 7-block drop outside) and a landing with 2.5 blocks of
      headroom. On a test server, `/knk npc nav scene corners` builds it at `testing.scenarios.origin` (only while
      `testing.scenarios.enabled` is true) and saves the route `corner-scene`; the scene has no road, so NPCs walk that
      route as off-road legs.
   2. **`ScenarioNpcs`** starts K&K's navigation service and groups on Citizens' movers (a registry of its own, beside
      the module's) with a fake road: the scene's route line, walked forward round its loop. Local legs get open cell
      access in a box round them. It keeps a run log with ticks, watches how long each NPC stands in one block
      (`longestStillTicks`), checks that the stuck counters add up (`countersAddUp`), can `push` an NPC into a corner
      and `trace` one. `ScenarioNpcs.start` fails the step with the reason when Citizens is missing.
   3. **Rules and gates.** `ScenarioNpcs.start(scene, loop, settings, rules, gates)` takes access rules of its own and
      the gate crossings on the scene's road (a plan whose line passes one names its door). `ScenarioNpcRules` is
      those rules: fake region data (`deny(regionId)`, `allow(regionId)`; an NPC already in the region may stay) and a
      scenario gate's real state and box from the plugin's gate cache (a door that is not open blocks NPCs). After a
      rule changes, send the event yourself: `rulesChanged()` (availability) or `gateChanged(doorId)`.
   4. **An order within `hop-blocks` (16) of the start is a short trip:** one local leg, and a scenario's local legs
      know no gates (open cell access). A scenario that tests a gate puts the goal further away, so the leader walks
      a road route with the gate crossing on it.
   5. **Citizens on CI:** `paper-boot` downloads a pinned Citizens build (URL and SHA-256 in the workflow's `env`, the
      build that matches `citizensApiVersion`) and turns `npc.navigation.enabled` on
      ([CI § 7.2](ci.md#72-citizens-on-the-ci-server)). Bump the pin together with `citizensApiVersion`.

8. **Primed caches** (#540): where a live service reads a cache in front of the API, a scenario may put fake data
   into that cache as if the API had just answered, and take it out again in a cleanup.
   `services().permissions().prime(set)` (a fake account's in-house grants; § 5 does it for you),
   `services().users().put(summary)` (a fake account) and `services().menuTemplates().prime(template)` with
   `evict(key)` (a fake InventoryMenu, opened with `services().menus().openMenu(player, key)`). Ids stay negative;
   primed data lives until its cache's TTL (30 s for permissions), long enough for a scenario.

## 5. Players

Since [#540](https://github.com/PandiO/knk-workspace/issues/540) (developer decision 2026-11-15) a scenario can script
players: a server-side fake player that joins the real server, so join and quit events, permission attachments and
the plugin's own join handling run as for a real player. A headless bot client that speaks the real protocol is there
too, but off (§ 8).

```java
ScenarioPlayer refused = scene.player("ScnNoFeed", p -> p.account(scene.fakeId(1)));
ScenarioPlayer granted = scene.player("ScnFeeder", p -> p.account(scene.fakeId(2)).grant("knk.feed"));
plan.act("both join", () -> { refused.join(); granted.join(); })
    .await("both are online", 200, () -> refused.online() && granted.online())
    .act("put them on the floor", () -> { refused.teleport(12.5, 2, 16.5); granted.teleport(20.5, 2, 16.5); })
    .act("the refused player types /feed", () -> refused.command("feed"))
    .await("they are refused", 60, () -> refused.received("You don't have permission to use this command."));
```

### 5.1 Setting a player up (before the join)

1. `scene.player(name)` or `scene.player(name, setup)`: one player per name (3 to 16 letters, digits or `_`; the
   shipped scenarios start theirs with `Scn`). The UUID is the one an offline-mode server gives that name
   (`ScenarioPlayer.uuidOf(name)`). Creating one does no work, so it may happen in `define`.
2. `account(scene.fakeId(n))`: a fake account (negative id) in the live user cache, so the plugin finds a user for the
   player; `account(UserSummary)` for one with a title, chat colours or groups (its uuid must be the player's).
3. `grant(nodes…)` and `deny(nodes…)`: the fake account's in-house permission set, primed into the live permission
   cache as the user's own grants (§ 4.8). Every other node is undeclared, so refused. Without an account a non-op
   player's in-house checks can't be made at all ("can't be checked right now"), as on a server whose API is down.
4. `op()`: joins as a server operator (ops pass every in-house check); the scene takes the op back.
5. `withoutPreLogin()`: skips `AsyncPlayerPreLoginEvent`. By default it fires first, off the server thread, so the
   admission gate and the account lookup at pre-login run; a refusal ends the join and `loginRefusal()` has the text.

### 5.2 What a player does and sees

1. `join()` (await `online()` in the next step), `quit()` (the quit event fires and the player is saved now; a later
   `join()` loads that saved position, inventory and game mode again, like a rejoin).
2. `command("feed")` and `chat("hello")` go through `Player#chat`: the command preprocess event, dispatch with its
   permission checks; the chat events, the plugin's renderer and the viewers.
3. `teleport(x, y, z)` (scene coordinates, cause PLUGIN, the teleport event fires) and `move(x, y, z)` (meant as a
   movement packet, so the server's movement checks and `PlayerMoveEvent` run; a fake player has no gravity or physics
   of its own). **`move()` does not work on Paper 26.3:** the server refuses the fake player's movement packets
   (`Invalid move player packet received`, found by link M7, #627), so no scenario uses it. Walk a player with short
   teleports instead, as `ScenarioPushes` does (§ 1); the fix is [#659](https://github.com/PandiO/knk-workspace/issues/659).
4. `click(rawSlot)`, `rightClick`, `shiftClick`: a container-click packet in the open inventory (top inventory first),
   so the server's click handling, `InventoryClickEvent` and the plugin's listeners run.
5. `messages()`, `received(text)`, `find(text)`, `clearMessages()`, `recentMessages()`: every chat line, system
   message, action bar, title and disconnect reason the server sent, decoded from its packets
   (`Message.plain()`, `Message.colorOf(part)` for colours). `player()`, `location()`, `inventory()` and
   `openInventory()` read the live Bukkit player.
6. The join's loading hold ends with the action bar "You're all set!": await it before a step a held player can't do
   (opening a menu, breaking blocks). Owners and ops are not held.
7. When the scene closes every player quits and its fake data is taken back (account, grants, op, its saved player
   files). The server log gets "Scenario player <name> received: […]" with the last messages, for a failed run.

### 5.3 How it works, and what it skips

`NmsFakePlayer` in knk-paper `scenario/` is the only class that touches the server's internals (NMS), by reflection on
Paper's Mojang-mapped classes; Netty is a compile-only dependency. It builds a `ServerPlayer` with a `Connection` whose
channel is an in-memory Netty `EmbeddedChannel`, loads the player's saved data (else the world spawn), adds the
connection to the server's connection list (so the server ticks it like a real one) and calls
`PlayerList.placeNewPlayer`. The fake client answers keep-alives, teleport confirmations and "world loaded"; every
other packet is read for messages and dropped. The class is loaded only when a scenario creates a player, and
scenarios exist only with `testing.scenarios.enabled`, so a real server never touches it.

What a fake player skips: the handshake and login packets, the configuration phase (resource packs, known packs, the
server's spawn preparation and `AsyncPlayerSpawnLocationEvent`, so the hub admission's spawn choice does not run) and
the server's ban, whitelist and full-server checks. Movement physics, chunk loading and anything a real client renders
are not there. The bot tests (§ 8) cover the real login path once they are on.

**No reachable API:** the plugin's join handling creates accounts for unknown players, so `join()` fails the step
while knk-web-api is reachable ("fake players would get real accounts"). Run player scenarios on a server without the
API, as CI does. The answers the fake grants give reach the offline security store under the negative ids, which never
match a real account.

### 5.4 When a Paper update breaks it

A renamed server class, field, method or constructor fails the first step that creates a player with
`Paper's server internals changed: method net.minecraft…placeNewPlayer(…) not found (fake players, scenario/NmsFakePlayer; …)`.
Nothing else in the plugin is affected. To fix it:

1. Start the new Paper jar once (`java -Dpaperclip.patchonly=true -jar paper.jar`) and read the patched server jar
   under `versions/<version>/` with `javap -cp versions/<version>/paper-<version>.jar <class>` (Paper ships
   Mojang-mapped names), or read the class in Paper's repository at the new version's tag.
2. Find the new name or signature of the member the message names and change its lookup in `NmsFakePlayer.Nms`; the
   flow (create the player, load its data, place it, decode packets) is in `connect`, `poll` and `click`.
3. The members most likely to move: `PlayerList.placeNewPlayer` and the spawn preparation it follows
   (`PrepareSpawnTask` in 26.x), `CommonListenerCookie.createInitial`, the `ServerPlayer` constructor, the packet
   records (`ServerboundContainerClickPacket`, `ServerboundMovePlayerPacket$Pos`, the chat packets), and the Netty
   version (`nettyVersion` in knk-plugin's `gradle.properties`: the one under `libraries/io/netty/netty-transport/` of
   the server).
4. Run `knk scenario run player-*` on a local server (§ 6) until all six pass.

What still needs a real player (keep these manual in the smoke-test guides): game feel, visuals and sound, a real
client's movement and rendering, Bedrock, real alpha data.

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
   `knk scenario run <name>`, or a prefix with a star for several (`knk scenario run player-*`, #540). The player
   scenarios need a server without a reachable knk-web-api (§ 5.3). Results are in the console and `logs/latest.log`; a player who starts a run sees them in
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

Report-mode scenarios ([#621](https://github.com/PandiO/knk-workspace/issues/621)) log their numbers in a line of
their own, which `check_scenarios.py` ignores and the `paper-boot` job copies into its summary:

```text
KNK-NPC-REPORT npc-doorway-crowd | 6 + 6 singles through the doorway | scene npc-doorway.schem, 2253 blocks | arrived 12/12 | ...
```

The scenario's name, the phase, then `key value` pairs separated by `|`. Positions are box coordinates with the
floor's height (`13 2 7`).

## 8. Headless bot tests

Added with [#540](https://github.com/PandiO/knk-workspace/issues/540) and **off** until Mineflayer supports Minecraft
26.3 (how to switch them on: [CI § 7.3](ci.md#73-headless-bot-tests-off-until-mineflayer-supports-263)). A bot test
is a Mineflayer bot that joins the CI server through the real protocol in offline mode, for what the fake players skip:
the login and configuration phases, admission, the server's spawn choice.

1. **Where:** knk-plugin `tools/bot-tests/tests/<name>.mjs`, exporting `name` (lower-case words joined by hyphens),
   `description` and `async run(ctx)`. `ctx.join(username)` connects a bot (quit again after the test) and returns a
   `TestBot` with `chat(text)`, `command(line)`, `waitForMessage(textOrRegex, timeoutMs)`, `received(text)`,
   `waitForWindow()`, `clickWindowSlot(slot)`, `quit()` and the Mineflayer `bot`. `expect(condition, reason)` and
   `freshName(prefix)` (a new player each run) come from `lib/harness.mjs`.
2. **Example:** `first-join`: a new bot joins, waits for "Loading your account" and "You're all set!", quits and joins
   again.
3. **Run locally** (Node 22): `npm ci` in `tools/bot-tests`, then `node run.mjs --host 127.0.0.1 --port 25565` against
   a running offline-mode server, or `tools/paper-boot/boot-test.sh … --bot-tests tools/bot-tests` (runs them after the
   scenarios and checks the `KNK-BOT` lines). `npm test` runs the harness's own unit tests, `npm run support` says
   whether the pinned and the newest client list 26.3.
