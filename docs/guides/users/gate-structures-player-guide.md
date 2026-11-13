# Gate Structures — Player Guide

**Status:** Living document — update in place as the game changes
**Last updated:** 2026-11-10 (§ Cleaving: the siege enchantment for gate doors; its numbers are set by staff and shown on the web app's Guides page, PandiO/knk-workspace#259/#306); 2026-10-25 (invincible gates can't be set on fire either)

Gates, drawbridges, and portcullises are animated, damageable barriers built into walls around towns and districts — and a central part of sieges. Here's what you'll actually experience with them.

## Getting through a gate

- **`/knk gate info <name>`** — check a gate's state, health, and type. Works for anyone, no permission needed.
- **`/knk gate list`** — see every gate near you and how far away it is.
- If a gate allows pass-through and you have permission, **right-clicking it while it's closed** will let you through — how depends on your chosen mode:
  - **Default** — the gate swings/slides fully open, stays open for a few seconds, then auto-closes on its own. Right-clicking again while it's open or opening just resets that timer.
  - **Instant Open** (needs the instant-open permission) — only the blocks directly in your path vanish for a moment, letting you step straight through without waiting for the whole gate to animate; they reappear once you're past.
  - **Teleport** — you're moved straight to the other side; the gate itself never animates.
- Set your preferred mode any time with **`/knk gate passthrough <default|instant|teleport>`**. If you pick `instant` without the permission for it, you'll just get `default` behavior instead — no error, it quietly falls back.

## Animation

Gates move smoothly and rigidly — a swinging drawbridge or double door doesn't fall apart mid-motion, and if a gate has a custom-built open position (some do), it settles into that exact shape by the time it finishes opening, not just an approximation. You'll hear a chest-open/close sound (slowed down) when a gate starts animating.

**If a gate gets stuck** (someone built a block in its path, for example), it'll show as **jammed** — it stops advancing but keeps trying every moment to continue. Clear whatever's blocking it and it resumes automatically; nobody needs to "unjam" it manually.

## Combat and sieges

Gates have their own health and can be damaged and destroyed like any siege objective:

- Hitting a gate (melee, arrows, explosions, or breaking its blocks directly) chips away at its health.
- Setting a gate on fire (fire arrows, fire charges) burns continuously — the longer it burns and the more of it is alight, the more damage it racks up per tick, so leaving a gate burning is a real ongoing threat, not a one-time hit.
- Some gates are **invincible** and can't be damaged at all (useful for gates an admin doesn't want contested) — you'll just see your hits do nothing, and fire arrows, fire charges, flint and steel or a Fire Aspect weapon won't set them alight at all.
- When a gate's health hits zero, it's **destroyed**: its blocks vanish with an explosion effect, and (for gates that can respawn) it rebuilds itself automatically after a set amount of time, restoring full health. A server-wide message announces it when a gate comes back.
- A destroyed gate that can't respawn stays down until an admin repairs it.

### Cleaving: the siege enchantment for gate doors

**Cleaving** (levels I–IV) is a custom enchantment for a melee weapon, made for attacking gates. It does nothing to
players or mobs.

- **Boosted hits:** your melee hits on a gate door deal extra gate damage. With today's numbers that is +25 % per
  level (+25 % at I up to +100 % at IV).
- **Charged strike:** right-click a gate door while the strike is ready. You hear wood breaking and see splinters,
  the action bar says **Cleaving strike!** and the gate takes several boosted hits' worth of damage at once (5x at
  level I, then 6x, 7x and 8x). With a netherite sword (no Sharpness) that is 50, 72, 98 and 128 HP of a 500 HP gate.
- **Cooldown:** after a strike, it has to recharge (60 s at level I, then 50, 40 and 30 s). A boss bar,
  **Cleaving strike cooldown**, counts it down; right-clicking too early shows **Cleaving strike ready in N s** and
  the click works as a normal click on the gate. The cooldown is your own; other players' strikes don't affect it.
- A defender can't hurt their own gate with it: a right-click on your own gate opens it as usual, with no strike and
  no cooldown. Invincible gates take no damage, and only Survival-mode players can strike.

**The numbers can change.** Staff set Cleaving's bonus, strike and cooldown per level in the web app, so the values
above are only the starting values. To see the numbers that apply now:

- open **Guides → Custom enchantments and abilities** in the web app (`/guides/enchantments`, no sign-in needed);
  Cleaving is under **Siege enchantments**, with its numbers per level;
- or hold the weapon and run `/ce info`. Under Cleaving's line it shows, for your item's level, a line like
  `gate hits +25%, charged strike 5x, strike cooldown 60s` (`off` when the strike has no cooldown).

## Notes

- Only Survival-mode players can damage or interact with gates for combat purposes — Creative/Spectator/Adventure doesn't count, so you won't accidentally damage a gate while flying around in Creative.
- Snow that settles on top of a gate's blocks (from natural weather) is cleared automatically as the gate moves, so you won't see snow left floating in mid-air after a gate opens or closes.
- Siege-specific gate behavior (capturing a gate as an objective, guard NPCs defending it) is planned but **not live yet** — if you see references to it, that's forward-looking design, not something you can do in-game today.
