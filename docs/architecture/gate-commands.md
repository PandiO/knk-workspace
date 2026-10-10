# Gate commands — `/gate` (structure) and `/gatedoor` (door), `here` and look-at targets

**Status:** Implemented, **live-tested by the developer and merged to trunk 2026-10-09**: knk-plugin `main` merge `5b1cc8b` (feature `b9e9d58` + review fixes `0bf6f15`), knk-web-api `master` merge `6192af0` (`983f1cd`, `9ea328d`). Linear [KNG-77](https://linear.app/kngpandi/issue/KNG-77), [KNG-78](https://linear.app/kngpandi/issue/KNG-78), [KNG-79](https://linear.app/kngpandi/issue/KNG-79)
**Last updated:** 2026-10-10 (KNG-105/106 live-tested and merged, knk-plugin `main` `8457657`: safe `tp` targets, door collision safety; checklist in [gate-smoke-test.md](../guides/gate-smoke-test.md) §2)
**Related:** [gate specs](../specs/gate-structure-animation/) (GateStructure/GateDoor model, decisions 5.0-B/5.0-D); the dated [command catalog](../specs/user-features/COMMAND_CATALOG_V3.md) §2 describes the tree before KNG-77

## 1. Layout decision: two sibling roots

A gate is a **GateStructure** with one or more independently animating **GateDoors** (gate item 5). Before KNG-77, every `/knk gate` subcommand addressed a door, which was confusing once structures had several doors. Now:

| Root | Alias | Acts on | Code |
|---|---|---|---|
| `/knk gate <sub> <structure>` | `/gate` | the structure and **all** of its doors | `commands/GateCommand` |
| `/knk gatedoor <sub> <door>` | `/gatedoor` | exactly **one** door | `commands/GateDoorCommand` |

The issue recommended sibling roots over a nested `/knk gate door ...` literal, and that is what was built. `/gate door` can't clash with a structure named "door", each root completes one entity type, and the permission nodes map onto the roots. The command framework made both layouts equally cheap: `KnkAdminCommand.registerSubcommand` with a tab completer, and `KnKPlugin.registerKnkShortcut` for the aliases. The aliases run `/knk gate|gatedoor` itself, so the permission warm-up and checks are identical.

`16` means a different entity in each layer: `/gate repair 16` is gate structure 16, and `/gatedoor repair 16` is door 16. Help, usage lines, tab completion and errors always name the expected entity. If you give a structure command a door id (or the reverse), the error says what the id is and which command to use instead.

## 2. Command tree

`<structure>` = structure id or name (multi-word names allowed), or `here`.
`<door>` = door id or name, `<structure> <door>` (decision 5.0-D), or `here`.
`[ ]` = the target may be left out; see §4.

**`/gate` (alias of `/knk gate`)**

| Subcommand | Permission | Function |
|---|---|---|
| `open [structure]` | `knk.gate.open.<structureId>` or `knk.gate.open.*` | Opens every door. Skips (and lists) doors that are inactive or destroyed. Reports how many doors are moving and how many were already open. |
| `close [structure]` | `knk.gate.close.<structureId>` or `.*` | Closes every door. |
| `toggle [structure]` | the open or close node, whichever the toggle does | If **any active door is open or opening, all doors close**; otherwise all doors open. |
| `info [structure]` | none | Shows the structure id, siege objective, the overrides that are set, and each door's state and HP. |
| `list` | none | Lists structures with their door count, open/closed counts and distance. |
| `repair [structure]` | `knk.gate.admin` | Every door to full health, not destroyed. Warns if the override `destroyed=true` still applies. |
| `tp <structure>` | `knk.gate.admin` | [KNG-105](https://linear.app/kngpandi/issue/KNG-105) (merged 2026-10-10): the structure's spawn point (its `Domain.Location`, the point `/warp` and `/navigate … spawn` use, looked up through `GET /api/Structures/{id}` + its Location) when set; otherwise a safe spot next to its first door (lowest id), as `/gatedoor tp`. The reply says which and why. Before: the first door's anchor. |
| `override <structure> <field> <value\|clear>` | `knk.gate.admin` | Unchanged from before (fields `active`, `destroyed`, `invincible`, `canrespawn`, `openedstate`). |
| `reload [district <id>]` | `knk.gate.admin` | Unchanged (was `admin reload`). |
| `passthrough <default\|instant\|teleport>` | none (player) | Unchanged: the player's own pass-through method. |

**`/gatedoor` (alias of `/knk gatedoor`)**

| Subcommand | Permission | Function |
|---|---|---|
| `open\|close\|toggle [door]` | `knk.gatedoor.<open\|close>.<doorId>` or `.*`, **or** the matching `knk.gate.*` node for the door's structure | Same as the old door commands. `toggle` flips the target state: open or opening closes, closed or closing opens. |
| `info [door]` | none | Door details. |
| `list [structure]` | none | Every door, or one structure's doors. |
| `repair [door]` | `knk.gatedoor.admin` or `knk.gate.admin` | One door. |
| `tp <door>` | same | [KNG-105](https://linear.app/kngpandi/issue/KNG-105) (merged 2026-10-10): the nearest standable spot within 4 blocks of the door's region (§4: closed footprint plus captured regions, so never in an open door's opening either), preferring its front and back faces, facing the door; no safe spot = refused with a message. Before: the door's anchor, inside a closed door's blocks. Search: `core/gates/safety/GateSafeSpotFinder` (shared with KNG-106), paper `gates/GateSafeSpots`. |
| `health <door> <amount>` | same | |
| `active <door>`, `invincible <door>` | same | Toggles the door flag. |
| `capture\|redefine <door> [closed\|opened]` | same | WorldEdit region capture (was `/knk gate door capture\|redefine`). |

**Mixed-state toggle (structure):** if any active door is open or opening, the whole gate closes; otherwise it opens. Inactive doors don't count towards the decision. One press always ends with the gate shut when any part of it was open (`core/gates/target/GateToggle`, tested in `GateTargetMathTest` and `GateCommandTest`).

**Deprecated forms, kept for one release:** `/knk gate admin <health|repair|tp|active|invincible> ...` runs the `/gatedoor` command (these always meant one door). `/knk gate admin reload|override` runs `/gate reload|override`, and `/knk gate door capture|redefine` runs `/gatedoor capture|redefine`. Each prints which command to use instead. **Clean break:** `/knk gate open|close|info <id>` now means a **structure** id. `<structure> <door>` selectors there get the "this is a door, use `/gatedoor`" hint.

## 3. Permission nodes

- **Structure layer:** `knk.gate.open.<structureId>` / `knk.gate.open.*`, `knk.gate.close.<structureId>` / `knk.gate.close.*`, and `knk.gate.admin` (default op).
- **Door layer:** `knk.gatedoor.open.<doorId>` / `knk.gatedoor.open.*`, `knk.gatedoor.close.<doorId>` / `knk.gatedoor.close.*`, and `knk.gatedoor.admin` (default op; a `plugin.yml` child of `knk.gate.admin`).
- **A structure grant covers that structure's doors, and the admin nodes cover open/close/toggle.** `knk.gate.admin` covers every gate and door; `knk.gatedoor.admin` covers every door but not whole gates. The code checks this explicitly (`GateCommandSupport.mayControlDoor`/`mayControlStructure`, `isDoorAdmin`), so it also holds for in-house grants, which don't see `plugin.yml` children.
- **Breaking:** before KNG-77, `knk.gate.open.<id>` / `knk.gate.close.<id>` meant a **door** id; now the id is a **structure** id. No code, permission catalog or seed data uses per-id gate nodes (checked 2026-10-08). **To do (developer, outstanding at merge):** check the live LuckPerms/Bukkit permissions and the in-house `PermissionGrants` table for `knk.gate.open.<n>` / `knk.gate.close.<n>`, and rename any you find to `knk.gatedoor.open.<n>` / `knk.gatedoor.close.<n>`. Otherwise such a holder loses door n and gains structure n. `/gate open <n>`, where n is also a door of another gate, prints a note pointing to `/gatedoor`.
- Per-id nodes are warmed (`CommandPermissions.warm`) after the target is resolved, so a fresh in-house grant isn't refused on a cold cache.

## 4. Implicit targets: `here` (KNG-78) and look-at (KNG-79)

**A door's region.** Doors are not WorldGuard regions. The "region" is `paper/gates/GateDoorBounds`: the box spanned by the door's blocks in the **closed** position (`GateManager.closedFootprint`, whatever the current state), unioned with its captured `ClosedRegionData`/`OpenedRegionData`. So an **open** gate, whose opening holds no blocks, still has the opening as its region. A door with neither falls back to its anchor block.

**`here`** can stand in for `<structure>` or `<door>` in every subcommand (players only):
1. Find the doors whose region is within `gates.here.radius` (default **15**) blocks, measured to the region's **closest point**. Standing inside it counts as 0.
2. **One** candidate is used directly. **Several** get a clickable list in chat, sorted by distance (door id/name, gate, distance). Each line runs the same command with the explicit id, so permissions are checked again when it is clicked. **None** gives an error that states the radius.
3. In `/gate`, several doors of the same structure count as one candidate.
4. `gates.here.ambiguity: nearest` picks the closest instead of asking (default `prompt`).

**Look-at.** When `open`, `close`, `toggle`, `info` or `repair` are given no target, at either layer and for players only:
1. One block ray trace (`World.rayTraceBlocks`, up to `gates.lookat.max-distance`, default **12**, fluids and passable blocks ignored) finds what blocks the view.
2. A ray–box test against the door regions picks the region entered first. A door behind the hit block is hidden; a closed door's own block lies inside its region; an open gate's opening is entered with no block hit. A region the eye is already **inside** (standing in an open opening, or on a lowered drawbridge) counts only when the looked-at block lies in it. Otherwise standing in one gate would pick that gate whichever way you face.
3. If nothing is in sight, the `here` logic runs; if that finds nothing, the usage message is shown.

The setting-changing commands (`health`, `active`, `invincible`, `capture`, `redefine`, `override`) and `tp` never infer a target. They need an explicit id/name or `here`. Every reply names the resolved door and gate (for example "Using the door you're looking at: door 'Left' (#16) of gate 'North Gate'"), so a wrong guess shows straight away. `gates.lookat.enabled: false` turns look-at off.

**Worlds.** A door saved with a blank world counts as being in the server's primary world (the world the animation falls back to). It is never matched in other worlds at the same coordinates.

**Cost.** Both run only when a command runs: one ray trace plus one box per loaded door in the player's world. Never per tick, never in a listener, never on tab completion (`GateCommandTargetsTest.tabCompletionNeverRayTraces`). The geometry is Bukkit-free in `knk-core` `core/gates/target/` (`GateBox`, `GateTargetMath`, `GateToggle`).

**Reserved keyword.** `here` is rejected as a GateStructure or GateDoor name by knk-web-api (`Services/GateNameRules.cs`). The check runs on create and update in `GateStructureService` and `GateDoorService`, and on renames through `PUT /api/Domains/{id}` and `PUT /api/Structures/{id}` when the entity is a GateStructure. The check trims and ignores case; other domains may still be called "here". On load, the plugin warns in the log about any door or structure already named "here" (`GateManager.warnIfReservedName`); such a gate can still be reached by its id.

## 5. Config (`config.yml`)

```yaml
gates:
  here:
    radius: 15          # blocks, to the region's closest point
    ambiguity: prompt   # prompt | nearest
  lookat:
    enabled: true
    max-distance: 12    # capped at 64
  safety:
    door-suffocation-damage: false   # KNG-106: true keeps vanilla suffocation damage from door blocks
```

**Door safety (KNG-106, merged 2026-10-10, knk-plugin `main` `8457657`).** While a door animates,
`GateAnimationTask` asks `CollisionPredictor` for the cells the door fills from the previous update through the next two
(`core/gates/safety/GateSweep`: every frame in between, the box between consecutive positions so a drawbridge's arc is
covered, plus the resting frame's cells when the window reaches it; closing counts frames down). Every entity overlapping
them (players, mobs, items, vehicles with their riders; not spectators, displays or hanging entities) is moved by
`EntityEvacuator` to the nearest standable spot within 6 blocks, on its own side of the door when there is room, outside
the rest of the sweep, every current gate block and other nearby doors' regions; with no spot it gets the old velocity
push, now away from the door on its own side. `GateSuffocationGuard` moves anyone found inside gate blocks (suffocation
tick, join, teleport) out and, by default, cancels that suffocation damage (decision accepted with the live test). Live checklist (passed 2026-10-10):
[gate-smoke-test.md](../guides/gate-smoke-test.md) §2.

## 6. Live checklist (developer) — passed 2026-10-09

1. `/gate list`, `/gatedoor list`, `/gatedoor list <structure>`: the ids shown match the web app.
2. A gate with two doors: `/gate open <structure>` opens both. `/gatedoor close <door>` closes one. `/gate toggle` with one door open closes both; run it again and both open.
3. `/gate` and `/gatedoor` behave exactly like `/knk gate` and `/knk gatedoor`, and Tab completes subcommands, `here`, and structure or door ids/names.
4. Stand within 15 blocks of one gate: `/gate toggle here` works, and `/gatedoor repair here` asks you to pick when two doors are in range. Clicking a line runs the command for that door.
5. Far from any gate, `here` says "No gate door within 15 blocks".
6. Look at a **closed** door and run `/gatedoor toggle` with no target: that door opens. Look through the now **open** opening and run `/gatedoor toggle` again: it closes. With a wall in between, the command falls back to `here`. Stand inside an open opening and look at another gate: the other gate is picked.
7. `/gate repair` while looking at a gate repairs all its doors.
8. A player with only `knk.gate.open.<structureId>` can open that gate and each of its doors, but not other gates. A player with only `knk.gatedoor.open.<doorId>` can open just that door. A non-op staff member with an in-house `knk.gatedoor.admin` grant can open, repair and tp any door, but can't run `/gate open` on a whole gate.
9. The deprecated `/knk gate admin repair <door>` still works and prints the replacement command.
10. In the web app, renaming a gate or door to "here" fails with a 400 message.

**Live test, 2026-10-09 (developer): all steps passed.** Tested on the branches before merging:
- **KNG-77:** command layers, toggle (including mixed state), info, list, repair, tp, aliases, tab completion, wrong-layer hints, deprecated forms and per-layer permissions.
- **KNG-78:** `here` with one, several or no candidates; one gate with several doors; nearest mode; standing inside the opening; a trailing argument; the console; the reserved name in the web app.
- **KNG-79:** look-at on closed and open doors; the wall fallback to `here`; standing in one gate and looking at another; nothing in sight; commands that need a target; maximum distance; look-at switched off.
- **Regression:** pass-through, damage and animation are unaffected.

Findings, both filed as follow-ups rather than blocking the merge:
- `tp` can put the player inside a closed door's blocks, and `/gate tp` should prefer the structure's spawn point: [KNG-105](https://linear.app/kngpandi/issue/KNG-105).
- In survival, players take damage from solid or moving gate door blocks (closing on them, or after a teleport into them). Review the push-to-safety and collision code (`CollisionPredictor`, `EntityPusher`, `EntityEvacuator`): [KNG-106](https://linear.app/kngpandi/issue/KNG-106).
- **Permissions:** the developer wants the gate nodes seeded into the admin group. Neither the dev seed (`knk-dev-db-seed`: groups Noble, Royal, Dragon Blood, Default, Staff) nor the migrations has a group named Admin, and no group holds gate nodes yet; `knk.*` is on the owner's user account. Open question: which group, and as a data migration in the style of `SeedCurrencyPlayerNodes`.
