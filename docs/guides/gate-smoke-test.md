# Gates — smoke test checklist

**Status:** Living checklist. Section 2 (gate safety, [KNG-105](https://linear.app/kngpandi/issue/KNG-105) / [KNG-106](https://linear.app/kngpandi/issue/KNG-106)) **passed 2026-10-10** (developer live test, all steps 1-20 accepted) and is **merged**: knk-plugin `main` merge `8457657` (`b95b1c6` KNG-105, `f157372` KNG-106; [handoff](../ai-agents/handoffs/2026-10-10-gate-safety-kng-105-106.md)).
**Last updated:** 2026-10-10
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

8. Survival: stand in the opening of an open portcullis and close it. Before the bottom row reaches you, you are moved to the side of the door you were standing on (or to the other side when yours has no room), on the ground, unharmed.
9. Same with a door that is two or more blocks deep: you end up outside its whole depth, not between its layers.
10. Stand just behind the door (the inside face) and close it: you stay on the inside, you are not pushed through it.
11. Drop an item and spawn a mob (e.g. a pig) in the opening, then close the door: both end up outside the door, not inside the blocks.
12. Ride a horse or sit in a minecart in the opening and close the door: the vehicle moves with you on it.
13. Drawbridge: stand where the bridge comes down and lower it, then stand on it and raise it. You are moved out of the arc each time, onto solid ground, not into the moat or lava.
14. Two doors side by side: being moved out of one never puts you inside the other's opening.
15. Opening a door with you standing next to it doesn't move you.

**Already inside door blocks (KNG-106)**

16. Survival: `/tp` yourself into the blocks of a closed door (e.g. `/tp @s <x> <y> <z>` at the door's middle). You are moved out within a tick and take no suffocation damage. The server log shows `[GateSafety] Moved player … out of the blocks of gate door …`.
17. Log out while standing in an opening, have someone close the door, log back in: you are moved out on join, without damage.
18. Suffocating in a normal wall (not a gate) still hurts as usual.
19. Optional: set `gates.safety.door-suffocation-damage: true`, restart, repeat step 16: you are still moved out, but take the vanilla suffocation damage first.

**Regression**

20. Opening, closing, pass-through (`/gate passthrough`), gate damage and the health display behave as before.

**Live test, 2026-10-10 (developer): all steps 1-20 accepted.**

**Decision (accepted with the live test, 2026-10-10):** gate door blocks never cause suffocation damage by default
(`gates.safety.door-suffocation-damage: false`); the entity is moved out in the same tick anyway.
