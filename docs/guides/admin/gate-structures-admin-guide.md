# Gate Structures — Admin Guide

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-10-27 (pass-through styles per door and the snap style, [PandiO/knk-workspace#167](https://github.com/PandiO/knk-workspace/issues/167), in review on `claude/alpha-run-1-gates`, not merged) — earlier: 2026-10-25 (troubleshooting: an invincible gate refuses ignition) — earlier: 2026-10-23 (open-door scan in step 5: empty open-door anchor, seed v3, scan refusal, KNG-268/270/271; decorated doors and jam troubleshooting, KNG-272/KNG-273) — earlier: 2026-10-22 (`gates.damage-cracks`; rest based on a full read-only code scan of `knk-plugin` `main`@`e6e428b` and `knk-web-app` `main`@`4ff5dc6`)
**Companion docs:** `docs/architecture/gate-structures-design.md` (mechanics), `docs/guides/developer/gate-structures-developer-guide.md` (implementation)

Everything a server admin needs to configure, author, and operate gate structures — in-game commands, permissions, `config.yml` tuning, and how to author a new gate through the web app.

## Authoring a gate (web app)

There's no dedicated "Gate" page — gates are managed through the generic admin form system, same as every other entity type.

1. Navigate to `/dashboard` (or the nav dropdown) and pick **Gate** to list/search existing gate structures, or **Gate Door** to work with doors directly.
2. **Create the GateStructure first** (name, description, district, street, optional guard spawn locations — guard/siege fields exist on the form but have no live gameplay effect yet, see the design doc §8). Save it.
3. Once saved, open the structure again and use the **Gate Doors** list field's "Create New" button to add one or more doors inline — this is disabled with a tooltip until the structure itself has been saved. Each door opens as its own nested form (in a modal), pre-linked to the parent structure.
4. In the door form, configure geometry, animation, health, display, and damage fields. **The static/simple form only offers `PLANE_GRID` and `FLOOD_FILL` for geometry mode** — `REGION` mode requires a backend-authored dynamic form (ask a developer if you need a region-shaped door and don't see the option).
5. For `PLANE_GRID`/`FLOOD_FILL` doors, once the door itself is saved, use the in-form "Start scan"/"Re-scan" button to run a block scan — this runs headless on the server (no in-game claim code needed), scanning the door's **closed** shape. If the door needs a custom open-state shape (Mechanism 2 — see design doc §4), a second "opened block scan" field does the same for the open anchor point. The open scan covers a box of the same width × height × depth, in the same directions, starting at the open anchor — so the open anchor is the corner of the opened door's box that matches the anchor's corner. Leave it **empty** when the door opens inside its own box: the scan then starts at the anchor (GateDoor form seed v3, KNG-270). If the open-door anchor is moved, cleared or its location edited, the old open scan is ignored (console warning) until you scan again. Before the open scan, build the open shape in the world; afterwards rebuild the closed one. A door that only rises and loses decoration (chains above a portcullis disappearing into the gatehouse) needs no open scan at all: set `MotionDistanceBlocks` and keep **Clip to geometry bounds** on, so blocks leaving the box are removed. For a REGION door, capture the opened region first with `/gatedoor capture <door> opened` — a scan without it is refused with that command ("Couldn't start", KNG-268). Scan lists show how many blocks were scanned.
6. If an admin abandons a door mid-form, it's saved as an in-progress draft; reopening the parent structure later shows it listed inline with who started it and when, with a "Continue" button to resume rather than starting a duplicate door.
7. For `REGION`-mode doors (dynamic form only) or any door needing a WorldEdit-captured footprint, use the in-game `/knk gate door capture`/`redefine` commands (below) instead of/in addition to the web form.

### Pass-through styles (PandiO/knk-workspace#167)

A door with "Allow pass-through" on offers a set of styles - **Animated** (the door animates open and shut),
**Snap** (the door blocks change to open at once and back after the pass-through time, no animation),
**Walk-path** (only the blocks in the player's way are removed; players also need `knk.gate.passthrough.instant`) and
**Teleport** (the player is put on the other side) - plus a **Default style**. A player's own style
(`/gate passthrough`, or the staff User form) is used when the door offers it, otherwise the door's default style, which is always
offered. Set them on the GateDoor form's "Pass-through" step (seed v4) or in the Gate Door object config; override them
for every door of a gate with `/gate override` (above) or `PATCH api/GateStructures/{id}/overrides`. Doors that existed
before #167 offer Animated, Walk-path and Teleport and default to Animated, so nothing changed until a door is edited.
The siege defender pass-through (#154) stays animated, the non-member carry stays teleport.

## Commands

All under `/knk gate ...`. A door is selected either by a bare id/name (when globally unique, or the structure has only one door) or `<gateStructure> <gateDoor>`.

| Command | Description | Permission |
|---|---|---|
| `/knk gate open <door>` | Starts the opening animation | `knk.gate.open.<doorId>` or `knk.gate.open.*` |
| `/knk gate close <door>` | Starts the closing animation | `knk.gate.close.<doorId>` or `knk.gate.close.*` |
| `/knk gate info <door>` | Prints id/type/state/active/destroyed/health/invincible/blocks/motion type/face direction | none — open to anyone |
| `/knk gate list` | Lists all cached gates with distance from the sender | none |
| `/knk gate passthrough <default\|snap\|instant\|teleport>` | Sets the sender's own preferred pass-through style (player-facing, see the player guide). Used at a door that offers it, otherwise the door's default style ([PandiO/knk-workspace#167](https://github.com/PandiO/knk-workspace/issues/167)) | none to set it; `instant` only actually takes effect with `knk.gate.passthrough.instant`, otherwise the door's default style is used |
| `/gate override <structure> passanimated\|passsnap\|passwalkpath\|passteleport <true\|false\|clear>` and `/gate override <structure> passdefault <default\|snap\|instant\|teleport\|clear>` | Structure-wide override of the pass-through styles every door offers, and of their default style ([PandiO/knk-workspace#167](https://github.com/PandiO/knk-workspace/issues/167)); `/gate info` lists active overrides, `/gatedoor info` a door's effective styles | `knk.gate.admin` |
| `/knk gate door capture <door> [closed\|opened]` | Starts a fresh WorldEdit region capture for a REGION-mode door — draw with `//sel poly`/`//sel cuboid`/`//sel convex`, then type `save` or `cancel` in chat | `knk.gate.admin` |
| `/knk gate door redefine <door> [closed\|opened]` | Re-loads the door's existing captured region into your active WorldEdit selection for editing, mirroring WorldGuard's own `/rg redefine` | `knk.gate.admin` |
| `/knk gate admin health <door> <amount>` | Force-sets current health (clamped 0..max) | `knk.gate.admin` |
| `/knk gate admin repair <door>` | Full heal and un-destroy | `knk.gate.admin` |
| `/knk gate admin tp <door>` | Teleports you to the door's anchor point | `knk.gate.admin` |
| `/knk gate admin reload [district <id>]` | Full reload of every gate from the API, or force-refresh one district | `knk.gate.admin` |
| `/knk gate admin active <door>` | Toggles the door's active state | `knk.gate.admin` |
| `/knk gate admin invincible <door>` | Toggles the door's invincible state | `knk.gate.admin` |
| `/knk gate admin override <structure> <field> <value\|clear>` | Sets or clears a **structure-level cascading override** — instantly changes every door's effective value without editing each door. Fields: `active`, `destroyed`, `invincible`, `canrespawn`, `openedstate` | `knk.gate.admin` |

Use `override` when you want a single action to affect every door on a structure at once (e.g. locking an entire gatehouse down) rather than editing doors one at a time — it's a temporary, reversible layer, not a data rewrite: `clear` restores each door's own stored value.

## Permissions

Defined in `plugin.yml`:

| Node | Default | Grants |
|---|---|---|
| `knk.gate.open.*` | `false` | Open any gate |
| `knk.gate.close.*` | `false` | Close any gate |
| `knk.gate.passthrough.use` | `false` | Base permission to trigger pass-through by right-clicking a closed, pass-through-enabled gate |
| `knk.gate.passthrough.instant` | `false` | Use the Instant Open pass-through mode specifically (without it, a player's `instant` preference silently falls back to `default`) |
| `knk.gate.admin` | `op` | All admin gate commands. Also grants full, unconditional pass-through access, bypassing both `AllowPassThrough` and the mode permissions. Implies `knk.gate.open.*`, `knk.gate.close.*`, `knk.gate.passthrough.use`, `knk.gate.passthrough.instant`. |

Per-door open/close permissions (`knk.gate.open.<doorId>`) are checked in code but have **no `plugin.yml` entry** — Bukkit's default-deny applies to unregistered nodes, so grant `knk.gate.open.*`/`.close.*` (or `knk.gate.admin`) rather than expecting a bare per-door node to work without a wildcard/OP grant. Admins with `knk.gate.admin` can also break gate blocks directly (normally protected against `BlockBreakEvent`).

## Config (`knk-paper/src/main/resources/config.yml`, `gates:` block)

```yaml
gates:
  state-sync-interval-seconds: 120        # periodic full state push to the API (safety net)
  display-cleanup-interval-seconds: 60    # periodic orphan/duplicate name-display repair
  fire-duration-seconds: 8                # how long an ignited block keeps burning
  fire-damage-per-tick: 2.0               # health damage per still-burning block, per tick
  fire-tick-interval-seconds: 1           # how often the fire system ticks
  damage-cracks:
    enabled: true                         # damaged gates show vanilla's 10 block-breaking crack stages over their HP (visual only)
  melee-damage:
    from-held-item: true                  # a click on a gate does what the held item does to a player (attack damage + Sharpness); false = flat 10
    multiplier: 1.0                       # scales the item damage for balance
  area-enchantment-radius-blocks: 5.0     # chaos / flash_chaos reach gates this far (entities: 3)
  passthrough-instant-open-radius-blocks: 1     # Instant Open: sideways search radius around the player
  passthrough-instant-open-timeout-seconds: 5   # Instant Open: safety-net auto-restore timeout
  rotationGapFill:
    rasterization-enabled: true           # server-wide kill switch for the automatic diagonal-hinge gap-fill
  world-sync:
    health-check-interval-seconds: 300    # periodic gate world/DB reconciliation interval
    health-check-batch-size: 15           # gates checked per reconciliation pass
```

Changing `rotationGapFill.rasterization-enabled` and the `world-sync`/`state-sync`/`display-cleanup` intervals takes effect on next plugin start (or `/knk gate admin reload` for gate state itself, though the interval settings are read once at task-scheduling time). Gates do **not** participate in the generic per-entity `cache: entities:` TTL/retry block elsewhere in `config.yml` — there's no gate-specific cache TTL to tune; the plugin loads gates fully at startup/on district entry and refreshes on the schedule above.

**Not configurable** (hardcoded in the plugin, would need a code change to adjust): the 0.5-block rigid-transform snap distance and the quintic residual taper shape (§4 of the design doc — purely a rendering-smoothness constant, not something admins should need to tune), 5-tick jam threshold, entity-push radius/threshold, gate open/close sound pitch, per-cause damage amounts (currently a flat 10.0 for every cause), block-scan throughput/size limits (`200`/`50` blocks-per-tick, `500`/`20` default scan block/radius caps, `20000` absolute cell ceiling), pass-through teleport vertical tolerance/safe-search radius, name-display offset constants.

## Troubleshooting

- **A gate won't open/close** — check `/knk gate info <door>` for `JAMMED` state first (a real player-placed block is blocking the animation path; clear it and the jam releases automatically). Since KNG-272 a door no longer jams on its own blocks of another material (decorated doors, chains above fences). A door with an open-state scan that jams at once may have a bad scan: check that `gate_opened_block_snapshots` starts at the open-door anchor (or the anchor when that is empty) and holds only the door's blocks and air. Since KNG-271 a sliding door's open scan is paired along the slide, so blocks no longer change columns. If not jammed, check `isActive`/`isDestroyed`/`isInvincible` — a structure-level override may be masking the door's own value; check with the structure's override state, not just the door.
- **A gate is invincible when it shouldn't be** — check for an active `IsInvincibleOverride` on the parent structure (`/knk gate admin override <structure> invincible clear` to remove it) before assuming the door's own setting is wrong.
- **A gate won't catch fire** — an effectively-invincible gate refuses ignition entirely (no fire, smoke or burn from flame arrows, fire charges, flint and steel or Fire Aspect; since 2026-10-25), and a gate that becomes invincible mid-burn goes out on the next fire tick. Check the door's `invincible` in `/knk gate info` and the structure's `IsInvincibleOverride`.
- **New gates in a district aren't loading** — gates load lazily on a player's first WorldGuard-region entry into that district, plus a full load at server startup. Use `/knk gate admin reload district <id>` to force a refresh without waiting for a player to trigger it.
- **A door's blocks look wrong after a scan** — the closed-state scan (`GateBlockScan`) and open-state scan (`GateOpenedBlockScan`) are independent; re-run the specific one that's wrong, not both by default.
