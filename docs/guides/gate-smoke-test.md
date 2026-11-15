# Gates — smoke test checklist

**Status:** Living checklist; automated in CI; manual steps not run (the § 2 steps automated on 2026-11-14 for
[#511](https://github.com/PandiO/knk-workspace/issues/511) passed in the developer's live test of 2026-10-10 and now run as plugin
scenarios in CI `paper-boot`; their player halves wait for simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540)). Section 2 (gate safety, [KNG-105](https://linear.app/kngpandi/issue/KNG-105) / [KNG-106](https://linear.app/kngpandi/issue/KNG-106)) **passed 2026-10-10** (developer live test, all steps 1-20 accepted) and is **merged**: knk-plugin `main` merge `8457657` (`b95b1c6` KNG-105, `f157372` KNG-106; [handoff](../ai-agents/handoffs/2026-10-10-gate-safety-kng-105-106.md)).
**Last updated:** 2026-11-14 (§ 2 steps 8, 9, 10, 11, 12, 14, 15, 16 and 18: the mob, item and vehicle parts as plugin
scenarios, [#511](https://github.com/PandiO/knk-workspace/issues/511), in knk-plugin `next`); 2026-11-14 (§ 2 steps 11 and 20: the automated parts, plugin scenarios, [#421](https://github.com/PandiO/knk-workspace/issues/421), in knk-plugin `next`); 2026-10-19 (section 3, drawbridges, [KNG-193](https://linear.app/kngpandi/issue/KNG-193): passed on gate door 14; merged)
**Related:** [gate commands](../architecture/gate-commands.md) (its §6 is the KNG-77/78/79 command checklist, passed 2026-10-09), [gate specs](../specs/gate-structure-animation/)

Run these on the dev server after deploying the plugin (`./gradlew :knk-paper:dev`). Use a test gate with at least
two doors: one sliding door (a portcullis) at least two blocks deep, and, if available, a drawbridge (`ROTATION`).
Do every "survival" step in **survival mode**: creative hides damage.

## 1. Gate commands

The command checklist (layers, `here`, look-at, permissions) is [gate-commands.md §6](../architecture/gate-commands.md#6-live-checklist-developer--passed-2026-10-09).

## 2. Gate safety (KNG-105, KNG-106) — passed 2026-10-10

**Teleport targets (KNG-105)**

1. Close a door. `/gatedoor tp <door>` in survival: you land on the ground right in front of or behind the door, facing it, never inside it, and take no damage. The reply is "Teleported next to door '…'".
2. Open the door and repeat: you land in front of or behind the opening, not in it.
3. A door built against a wall (one face blocked): `/gatedoor tp` puts you on the free face.
4. A door with no standable ground within 4 blocks (e.g. in the air, or walled in on all sides): `/gatedoor tp` refuses with "No safe spot to stand within 4 blocks of door '…'; not teleporting." and you don't move.
5. A gate **with** a spawn point (its Location set in the web app, the point `/warp` and `/navigate <gate> spawn` use): `/gate tp <gate>` puts you on that spot. The reply is "Teleported to the spawn point of gate '…'".
6. A gate **without** a spawn point: `/gate tp <gate>` puts you next to its first door (lowest id), and the reply says "(it has no spawn point set)".
7. A gate whose spawn point is in a world that isn't loaded: the reply says so and you go to the door instead.

**Moving doors (KNG-106)**

8. [automated] A mob in each half of a closing portcullis's opening is moved out on the side it stood on, unharmed and
   never caught by the door, also when a wall makes the other side nearer: plugin scenario
   `gate-closing-keeps-mobs-on-their-side`. Manual: the same as a survival player (a player's own movement and view;
   simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540)).
9. [automated] A mob across both layers of a door two blocks deep ends up outside its whole depth, unharmed: plugin
   scenario `gate-deep-door-moves-mob-out`. Manual: the same as a player (#540).
10. [automated] A mob in the inside half of the opening stays on the inside, not pushed through: plugin scenario
    `gate-closing-keeps-mobs-on-their-side` (its south pig). Manual: the same as a player (#540).
11. [automated] A mob in the opening ends up outside the door: plugin scenario `gate-closing-moves-entity-out`
    ([#421](https://github.com/PandiO/knk-workspace/issues/421)). [automated] A dropped item in the opening is moved out
    before the door's blocks land on it and still exists: plugin scenario `gate-closing-moves-item-out`.
12. [automated] A minecart with a mob in it is moved out of the opening with the mob still riding it: plugin scenario
    `gate-closing-moves-vehicle-with-rider`. Manual: a player on a horse or in a minecart (#540).
13. Drawbridge: stand where the bridge comes down and lower it, then stand on it and raise it. You are moved out of the arc each time, onto solid ground, not into the moat or lava.
    Manual: the scenarios have no fake drawbridge (`ROTATION`) door yet, and the player part needs #540.
14. [automated] Two portcullises side by side: a mob moved out of one is never put into the other's opening, even when
    that opening is the nearest free spot: plugin scenario `gate-side-by-side-doors`. Manual: the same as a player (#540).
15. [automated] Opening a portcullis doesn't move the mobs standing right in front of and behind it: plugin scenario
    `gate-opening-leaves-neighbours`. Manual: the same as a player (#540).

**Already inside door blocks (KNG-106)**

16. [automated] A mob put into the middle of a closed door's blocks is moved out within two seconds at full health (its
    suffocation damage cancelled): plugin scenario `gate-blocks-never-suffocate`. Manual: `/tp` as a survival player
    (the teleport hook only runs for players, #540).
17. Log out while standing in an opening, have someone close the door, log back in: you are moved out on join, without damage.
    Manual: needs a player who joins (#540).
18. [automated] A mob in an ordinary stone block still takes suffocation damage (the control in the same scenario):
    plugin scenario `gate-blocks-never-suffocate`. Manual: the same as a player (#540).
19. Optional: set `gates.safety.door-suffocation-damage: true`, restart, repeat step 16: you are still moved out, but take the vanilla suffocation damage first.

**Regression**

20. Opening, closing, pass-through (`/gate passthrough`), gate damage and the health display behave as before.
    [automated] Opening and closing a portcullis: plugin scenario `gate-open-close` (CI `paper-boot`, [#421](https://github.com/PandiO/knk-workspace/issues/421)). Pass-through, damage and the display stay manual.

**Live test, 2026-10-10 (developer): all steps 1-20 accepted.**

**Decision (accepted with the live test, 2026-10-10):** gate door blocks never cause suffocation damage by default
(`gates.safety.door-suffocation-damage: false`); the entity is moved out in the same tick anyway.

## 3. Drawbridges — keyframed plank (KNG-193) — passed 2026-10-19 on gate door 14

**Live test, 2026-10-19 (developer):** gate door 14 (entity 14, Outer Gate) only, steps 1-5: "works perfectly". The
cardinal 4×6 drawbridge, the arched drawbridge, the switch toggle and the fall-backs (steps 6-11) were **accepted without
a run**; run them when such a door is first built. Merged the same day: knk-plugin `main` `79be4882`, knk-web-api
`master` `2d71155` (seed v2). Next: [KNG-194](https://linear.app/kngpandi/issue/KNG-194) deletes the old path (D6).

Design: [DRAWBRIDGE_KEYFRAME_ANIMATION.md](../specs/gate-structure-animation/DRAWBRIDGE_KEYFRAME_ANIMATION.md) §9
step 5. On knk-plugin `main` since `79be4882`; the switch is `gates.rotation.keyframes-enabled`
(`config.yml`, default `true`, read at startup). The old path is deleted only after this section passes (D6).

Before the run: check the live dev database against the 2026-10-07 seed (door 14 is the only `ROTATION` door there
and has an open scan). Every diagonal `ROTATION` door **without** an open scan now gets a deck counted in blocks
(D1), which reaches further than before: check its landing area first. The server log at startup names every door
that got keyframes ("keyframed plank with N keyframes") and every one that kept the per-block path, with the reason.

**Entity 14 (Outer Gate, 4 wide × 8 tall, 45°, open scan)** — 4 open/close cycles:

1. Every step of the swing is one straight 4-wide plank (21 steps, about every 4-5 ticks); no block lags behind or
   catches up on its own.
2. The deck lands exactly on the 49 scanned open blocks (strips of 4 and 3, the far strip 3 wide and centred), with the
   open scan's own log axes; closed, the 32 scanned blocks are back, with `axis=y` logs in the hinge row throughout.
3. No jam (`/gatedoor info`), no orphaned blocks anywhere along the arc after each cycle.
4. Survival: a player standing in the landing area is moved out before the deck comes down; a player on the deck is
   moved off before it rises (KNG-106 still applies).
5. Hit the moving plank mid-swing: the hit registers on the door (spatial index follows the keyframes).

**Cardinal 4 × 6 drawbridge (never tested before)** — build one on a cardinal hinge, no open scan, Ref 2 straight
above the anchor (KNG-132), and run steps 1-5: 11 steps, 24 blocks closed and 24 open, the deck 6 blocks long.
Then set `MotionDistanceBlocks` to 9, reload the gates and open it: the deck is 9 blocks long.

**Arched drawbridge** — build one in an arched opening (e.g. 7 wide × 9 tall, column heights 7,8,9,9,9,8,7):

6. Set `GeometryDefinitionMode = REGION`, capture the closed door with `//sel convex` + `/gatedoor capture <door>
   closed`, set `ScanMaterialWhitelist` ("Door materials" in the seed v2 form) to the door's materials, scan.
7. Open and close it 2×: the closed door is exactly the arch (57 blocks); the apex row is present in every step; the
   wall corners above the arch never move; the open deck is the arch laid flat.
8. Optional: a one-block hole (a window) in the door stays open in both resting frames.

**Switch and fall-backs**

9. With every drawbridge **closed** (the closed frame is the scanned door on both paths; an open deck without an
   open scan differs between them, so switching while open can leave stray deck blocks), set
   `gates.rotation.keyframes-enabled: false` and restart: entity 14 swings as before (the per-block path, Mechanism 1
   and the open-scan blend). Close it, set the switch back to `true`, restart: the plank is back.
10. A `DOUBLE_DOORS` door, or a `ROTATION` door whose Ref 2 KNG-132 refuses, logs "keeps the per-block rotation path"
    once at load and behaves as before.

**Regression**

11. Section 2 steps 8-15 and 20 on the drawbridge; a `VERTICAL` portcullis is unchanged.

