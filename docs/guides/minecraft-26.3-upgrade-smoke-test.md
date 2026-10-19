# Minecraft 26.3 upgrade — smoke test

**Status:** In progress. Steps 1–4 passed (server logs of 2026-10-18, see **Findings**). For the dev server live test
of [KNG-182](https://linear.app/kngpandi/issue/KNG-182) before it merges.
**Last updated:** 2026-10-19
**Branch:** knk-plugin `claude/mc-26.2-upgrade` (it targets 26.3 despite the name). Test a build that includes
KNG-193 (`bddb907c` or later), so the drawbridge keyframes are covered on 26.3 too.
**Related:** [gate smoke test](gate-smoke-test.md) · [road navigation smoke test](road-navigation-smoke-test.md) ·
[hub smoke test 2026-10-17](../reports/2026-10-17-hub-smoke-test.md) ·
[siege checklist](../reports/2026-09-26-siege-smoke-test-checklist.md) ·
[alpha runbook Phase 4](closed-alpha-deployment-runbook.md#phase-4--prepare-the-minecraft-service)

This is a broad, shallow pass over everything the 1.21.10 → 26.3 jump can touch. It goes deeper in the places the
compiler and unit tests can't cover:

- the world storage conversion;
- names looked up at runtime (block data, materials, sounds);
- the vanilla behaviour the plugin relies on (anvil input, clocks, server list).

Run it on the dev server with the plugin jar from the branch. Use a **second, non-op account** wherever a step says
so (ops pass every permission check). Note each failure under **Findings** with its step number.

## 0. Before you start

The setup as of 2026-10-19:

- **Server:** the 26.3 test server is a copy, `MinecraftServer/Servers/DEV_SERVER_26.3`, on Paper 26.3 build 205. Its
  `start-server.ps1` picks the installed Temurin 25. `DEV_SERVER_1.21.10` stays unconverted and is the way back to
  1.21.10. The conversion is one-way, and Paper **deletes** each old world folder once it has imported it.
- **Plugins:** FastAsyncWorldEdit **2.16.1**, WorldGuard **7.0.20**, and WorldEditSelectionVisualizer 2.1.10, which
  is untested on 26.3: see that it loads. AutoPluginLoader is not on the copy.
- **Plugin jar:** build from the branch with `devServerDirectory` pointing at `DEV_SERVER_26.3` (a local
  `gradle.properties` change). Run Gradle 8.14 on JDK 21 (`JAVA_HOME="C:/Program Files/Java/jdk-21"`); it compiles
  with the Temurin 25 toolchain. Then run `./gradlew :knk-paper:dev`, or copy the ~10.9 MB shadow jar.
- **Client:** Java Edition **26.3**.

Pre-flight on the 1.21.10 folder before the copy, checked read-only on 2026-10-19:

- `world_KNK-DEV` has no `DIM-1`/`DIM1` folder of its own, so Paper's "Refusing to overwrite existing migrated file"
  failure ([Paper #13750](https://github.com/PaperMC/Paper/issues/13750)) should not occur.
- Every world has a `uid.dat`, so world UUIDs survive.
- No world's `paper-world.yml` has overrides.

## 1. First start: the conversion

1. Start the server. Expect Paper's "World storage migration is required" alert and a 30-second pause. After that,
   expect `Starting legacy CraftBukkit import for world 'world_KNK-DEV_nether'` / `Completed …` lines, and the same
   for `world_KNK-DEV_the_end`. There should be no `Refusing to overwrite` and no stack trace.
2. When KnK enables, it loads `knk_hub` (the only world in `worlds.load`). Expect `Completed legacy CraftBukkit import
   for world 'knk_hub'`, then `[KnK Worlds] knk_hub: loaded (normal)`.
3. On disk, `world_KNK-DEV/dimensions/minecraft/` holds `overworld`, `the_nether`, `the_end` and `knk_hub`, and the
   old root folders of those three worlds are gone. `hub` is not in `worlds.load`, so it stays where it is,
   unconverted.
4. Log scan from start to "Done": KnK, FAWE and WorldGuard enable without `SEVERE` lines or exceptions. Search for
   `NoSuchMethodError`, `NoClassDefFoundError`, `Invalid`, `Unknown`, `Could not`. `version` shows 26.3, and
   `plugins` lists FastAsyncWorldEdit, WorldGuard and KnightsAndKings in green.
5. The managed-region repair at startup reports its counts with no failures, and `/knk health` shows the API as
   reachable.

## 2. Second start: the world loader (KNG-182 fix)

6. Restart. `[KnK Worlds] knk_hub: loaded (normal)` again. Before the fix this start logged
   `knk_hub: created (normal, void)`, and a world with `create: false` would have been reported missing, keeping
   players out.

## 3. World identity

Paper keeps the world names and UUIDs. These steps prove that nothing keyed by them lost its world.

7. `/tp` into each world: `world_KNK-DEV`, `world_KNK-DEV_nether`, `world_KNK-DEV_the_end`, `knk_hub`. Builds are
   intact.
8. `/rg list -w <world>` for each: the same regions as before. WorldGuard stores them per world name.
9. Teleport across worlds, then `/back`: you return to the spot. `/back` remembers worlds by UUID.
10. `/warp <town>` and `/knk location tp` to a location outside the main world: you land on the right spot.
11. Web app, Game Settings, runtime worlds: the same world names and their settings blocks. The Folder column shows
    the dimension folder (`overworld`, `the_nether`, `the_end`, `knk_hub`) for worlds not stored before. Expected:
    the column is display-only.

## 4. Joining, chat and commands (Adventure 5)

12. A fresh account joins: hub admission places it before it appears. The welcome and the `/account link` button
    show, and clicking the button runs the command.
13. `/knk help`: the page links click through. Tab completion works for `/knk`, `/gate`, `/navigate` and `/warp`.
    Namespaced forms (`knightsandkings:msg`) stay hidden.
14. `/msg <other> test`: delivered, and the console does **not** show the text (the Log4j private-message filter).
15. `/minecraft:tell <other> hi`, then normal chat from both: no "Chat disabled due to broken chain"
    ([KNG-25](https://linear.app/kngpandi/issue/KNG-25)).
16. `/staffmode on`, while the non-op account looks at the server list: the online count and player sample leave the
    staff player out, and a MOTD `{online}` agrees.

## 5. Items, menus and enchantments

17. `/menu`: menus open, and items show their names, lore and banner patterns. Do a menu step that asks for typed
    text (the anvil input): typing works, and the Cancel slot cancels. This relies on vanilla anvil behaviour.
18. Items catalogue ([KNG-175](https://linear.app/kngpandi/issue/KNG-175)): items show their default enchantments.
    `/kit get <name>` gives items with the right material, enchantments and grade lore.
19. `/lootbox`: open a box. The reel, the decoys with enchantments and the token item all look right.
20. Put the `chaos` custom enchantment on a weapon (`/ce add`) and hit a mob: the effect runs and deals damage, with
    no exception in the log.
21. `/siege join`, then `/siege leave` (or a short siege): the inventory is stored and restored.

## 6. Offline inventory ([KNG-13](https://linear.app/kngpandi/issue/KNG-13))

22. For a player who hasn't joined since the upgrade, `/inventory open <player>` and `/enderchest <player>` show their
    items. They are read from `world_KNK-DEV/players/data`. Editing is refused with the data-version message, by
    design.
23. That player joins once and quits: an edit now saves, and on their next join they have the edited inventory.

## 7. Gates and siege

Gate door snapshots are block-data strings saved under 1.21.x. Paper doesn't upgrade them, so watch the log here.

24. Every gate: `/gate open`, `close` and `toggle`. Doors render fully in both states, and the log has no invalid
    block data warnings. For the drawbridge (door 14), repeat the main lower/raise steps of
    [gate smoke test](gate-smoke-test.md) §3. KNG-193's keyframed plank passed there on 1.21.10 on 2026-10-19.
25. Run [gate smoke test](gate-smoke-test.md) §2 steps 8–12 (player, mob, item, and a horse with rider in the opening
    while it closes). The rider stays on the vehicle; this uses a teleport flag that 26.x deprecated.
26. Damage a door until it breaks and let it respawn: health, fire effects and sound work.
27. A short siege run from the [siege checklist](../reports/2026-09-26-siege-smoke-test-checklist.md).

## 8. WorldEdit and WorldGuard (FAWE 2.16.1, WorldGuard 7.0.20)

28. Web app form wizard, region step: make a selection with the wand and capture it. The region is created with the
    KnK parent, priority and flags.
29. Re-run a region step ([KNG-103](https://linear.app/kngpandi/issue/KNG-103)): the old region is replaced, with no
    "target region name already exists".
30. `/knk regions repair` reports no failures, and `/knk regions temp` reports.
31. `/gatedoor capture <door>` with a selection works.
32. Walk into a region you haven't discovered: the discovery message shows, with its sound and particles
    (`UI_TOAST_CHALLENGE_COMPLETE`, `HAPPY_VILLAGER`; both names checked against 26.3).

## 9. Navigation and roads

33. `/navigate <town>`: the route and the `DUST` trail show, and walk legs avoid regions you can't leave.
    `/navigate stop` ends it.
34. A quick pass of the [road navigation smoke test](road-navigation-smoke-test.md) if roads changed since its last
    run.

## 10. Game Settings and hub

35. Lock the time of `knk_hub` only: the hub stays at the set time, and `world_KNK-DEV` keeps its day/night cycle.
    Clocks are per world since 26.1. Unlock: the hub's cycle resumes.
36. Weather rules and per-world spawn still apply after a restart.
37. Hub: regeneration (if a hub rule enables it), a portal, `/hub return`, and `/spawn` as the hub rules allow.

## 11. Performance

38. Fly through new terrain for about ten minutes: `/tps` stays near 20 and `/mspt` stays reasonable, with no
    watchdog warnings, and memory settles.

## Expected differences (not failures)

- The old root folders `world_KNK-DEV_nether`, `world_KNK-DEV_the_end` and `knk_hub` are gone. Everything lives under
  `world_KNK-DEV/dimensions/` and `world_KNK-DEV/players/`.
- Game Settings' Folder column reads the dimension folder name for worlds not stored before.
- Each world has its own clock (Paper's `time.affects-all-worlds` setting changes that).
- The web app's material list is still the 1.21.4 export (1537 entries in knk-web-api
  `Data/minecraft_material_catalog.json`). It lacks 279 materials 26.3 has (copper tools, shelves, cinnabar …), and
  its `minecraft:chain` no longer exists (renamed `iron_chain` in 1.21.9). An item template using `minecraft:chain`
  doesn't resolve; that was already the case on 1.21.10.

## Findings

| Run | Step | Result | Follow-up |
|---|---|---|---|
| 2026-10-18 (server logs, read 2026-10-19) | 1 | **Pass.** First boot was on Paper 26.2 build 134 at 19:52. `Completed Vanilla import` for `world_KNK-DEV`, and `Completed legacy CraftBukkit import` for the nether and the end. No `Refusing to overwrite`. | — |
| 2026-10-18 | 2 | **Pass.** On 26.3 with KnK at 21:07: `Completed legacy CraftBukkit import for world 'knk_hub' (minecraft:knk_hub)`, then `[KnK Worlds] knk_hub: loaded (normal)`. | Plugin jar from `6ccafaa6` (`api-version: "26.3"`). |
| 2026-10-18 | 3 | **Pass.** `world_KNK-DEV/dimensions/minecraft/` holds `overworld`, `the_nether`, `the_end`, `knk_hub`; the old root folders are gone, and `hub` is untouched. | — |
| 2026-10-18 | 4 | **Pass (log part).** The 21:07 run has 0 SEVERE/ERROR lines. Its 12 warnings are known: gate data (gate 29 has no doors, door 12 has sheared reference points), the gate 14/15 animation "fell outside GeometryWidth/Height/Depth bounds" lines that the 1.21.10 server also logs, a disabled siege lobby, and the dev SSL notice. | `plugins` / `version` not checked yet. |
| | 6 | **To do.** No second KnK start after the `knk_hub` import yet: this is the step that checks the KNG-182 loader fix. | — |
