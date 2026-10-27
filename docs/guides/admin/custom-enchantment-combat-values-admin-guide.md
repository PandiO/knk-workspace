# Custom Enchantment Combat Values — Admin Guide

**Status:** Living document — update in place as the code changes. Describes the package branches
`claude/alpha-run-1-enchantments` (knk-web-api `0ecbe53`, knk-web-app `de93b69`, knk-plugin `fcb2e08a`); **not merged,
not deployed, not live-tested**
**Last updated:** 2026-10-27 (§ 5: effect boss bars and the flash_chaos name-tag blackout, #169/#170, in review on
`claude/alpha-run-1-effects`, knk-plugin `911eb2a`, not merged); 2026-10-26 (PandiO/knk-workspace#151, #156, #155)
**Companion docs:** [ability definition reference](../../specs/custom-enchantments/ABILITY_DEFINITION_REFERENCE.md),
[package B report](../../reports/alpha-tests/25-10-2026/2026-10-26-package-b-enchantments-freeze.md)

Since [#151](https://github.com/PandiO/knk-workspace/issues/151) an admin sets, per custom enchantment, how often its
effect goes off, how long it lasts, how that grows per level and the cooldown of the player who used it. The values
live on the enchantment definition in knk-web-api and are edited in the web app; the plugin reads them without a
restart. [#156](https://github.com/PandiO/knk-workspace/issues/156) made the defaults weaker (closed alpha test run 1:
freeze spam that couldn't be countered).

## 1. Where to edit

Web app → Enchantment definitions → edit a **custom** enchantment → step **Combat values**. The step comes with the
form seed `EnchantmentDefinition - Default (seed v2)`: import it once from the form configuration list (Import / seeds,
`EnchantmentDefinition`) and make it the default (v1 has no such step; it can stay or be deleted). A form without the
step leaves the stored values alone when it saves.

| Field | Meaning | Used by |
|---|---|---|
| Chance at level I (%) | Chance, 0-100, that a hit sets the effect off at level I | On-hit enchantments: Poison, Wither, Freeze, Blindness, Confusion, Strength |
| Chance per extra level (percentage points) | Added per level above I; may be negative. Result kept between 0 and 100 % | Same |
| Cooldown | On: after the effect goes off (or the ability is used), the same player can't set it off again until the cooldown ran out, on any target. Off: no cooldown; the length is kept | All |
| Cooldown length (seconds) | 0-86400 | All |
| Duration at level I (seconds) | How long the effect lasts at level I (0.05 = one tick) | Poison, Wither, Freeze, Blindness, Confusion, Strength, Resistance, Invisibility |
| Level multiplier | Share of the level-I duration added per extra level: 1 = level × the level-I duration, 0.5 = ×1.5 and ×2 at levels II and III, 0 = the same at every level | Same as duration |

At level *n*: chance = level-I chance + (*n* − 1) × chance per level; duration = level-I duration × (1 + multiplier ×
(*n* − 1)). Potion strength (amplifier) and the area damage of Chaos / Flash Chaos are not configurable here. Cleaving
ignores the step: its numbers are in the plugin's `config.yml` (`gates.cleaving`). Right-click abilities (Chaos, Flash
Chaos, Health Boost, Armor Repair, Resistance, Invisibility) always go off; only their cooldown (and duration where
listed) applies.

**Empty fields.** At every start the API writes the default into an empty field of a built-in custom enchantment; a
value you set is never overwritten. So clearing a field resets it to the default at the next API start. Until then,
and whenever the plugin can't reach the API, the plugin uses its built-in value, which is the same default.

The API refuses values out of range (400 with the reason).

## 2. When the plugin picks a change up

The plugin reloads the values at startup, every `custom-enchantments.tuning-refresh-minutes` (config.yml, default 5)
and on `/ce reload`. A failed load keeps the previous values. `/ce info` (item in hand) shows each custom enchantment's
values in effect at its level: `chance 15%, duration 2.25s, cooldown 20s`.

## 3. Defaults (#156)

| Enchantment | Chance I / per level | Levels I-III | Duration I, multiplier | Levels I-III | Cooldown |
|---|---|---|---|---|---|
| Poison | 10 % / +5 | 10 / 15 / 20 % | 3 s, 0.5 | 3 / 4.5 / 6 s | 8 s |
| Wither | 10 % / +5 | 10 / 15 / 20 % | 2 s, 0.5 | 2 / 3 / 4 s | 8 s |
| Confusion | 10 % / +5 | 10 / 15 / 20 % | 3 s, 0.5 | 3 / 4.5 / 6 s | 8 s |
| Blindness | 20 % / +10 | 20 / 30 / 40 % | 2 s, 0.5 | 2 / 3 / 4 s | 10 s |
| Freeze | 10 % / +5 | 10 / 15 / 20 % | 1.5 s, 0.5 | 1.5 / 2.25 / 3 s | 20 s |
| Strength | 15 % / +15 | 15 / 30 % (max II) | 15 s, 0 | 15 s | 120 s |
| Resistance | — | — | 10 s, 0.5 | 10 / 15 s (max II) | 120 s |
| Invisibility | — | — | 10 s, 0 | 10 s | 90 s |
| Chaos, Flash Chaos | — | — | — | — | 90 s |
| Health Boost, Armor Repair | — | — | — | — | 120 s |

Before #156 the on-hit effects had 15 % per level (15/30/45 %), level × 3 s (wither × 2 s) and no cooldown, and
Blindness went off on every hit. The defaults are a proposal for test run 2; tune them in the web app.

## 4. Freeze and flight (#155)

A frozen player is held in place, also in mid-air. While frozen (by the Freeze enchantment or a staff `/freeze`) the
player is allowed to fly, for that player only, so the server's flight check doesn't kick them, and they can't start
flying with it. Their own setting comes back when the last freeze ends, when they leave and when the plugin stops. A
freeze also ends when the player leaves or dies. With this deployed the server-wide `allow-flight` (the alpha's
`ALLOW_FLIGHT: "TRUE"` workaround) can go back to false.

Known limit: a staff `/fly on` given to a frozen player who couldn't fly before is taken away again when the freeze
ends.

## 5. What the victim sees: boss bars and the flash blackout (#169, #170)

In review on knk-plugin `claude/alpha-run-1-effects` (`911eb2a`), **not merged, not live-tested**.

**Boss bars ([#170](https://github.com/PandiO/knk-workspace/issues/170)).** A player hit by a timed debuff from a custom
enchantment gets one boss bar per effect, `Poison · 4s`, counting down (refreshed every 5 ticks):

| Source | Bar |
|---|---|
| Poison, Wither, Freeze, Blindness, Confusion | `Poison`, `Wither`, `Frozen`, `Blindness`, `Nausea` · remaining time |
| Flash Chaos (on players around the user) | `Slowness` (5 s) and `Nausea` (12.5 s) |
| Staff `/freeze` | static, full `Frozen` bar (no timer) until `/unfreeze`; back on the next join while still frozen |

The same effect again restarts its bar (no second bar). A bar follows the real effect: milk or an early unfreeze ends
it, a longer copy of the potion from elsewhere keeps its longer time. Timed bars go on death, every bar on quit. The
durations are the combat values above (§ 1, § 3), so a change in the web app changes the bar too. The bars are the
plugin's own, next to the navigation bar and any other boss bar. Creatures get nothing. Self-buffs (Strength,
Resistance, Invisibility) have no bar: they are not debuffs.

**Flash blackout ([#169](https://github.com/PandiO/knk-workspace/issues/169)).** A player caught by **Flash Chaos** no
longer sees other players' name tags for as long as the nausea lasts (12.5 s); other players' views don't change. A
second flash extends the blackout. It ends early on death and quit. The tab list, the sidebar (siege timer and
objectives) and the health below names stay. Plain **Chaos** has no blinding debuff (damage and knockback only), so it
doesn't hide name tags.

How (for staff debugging): the victim is shown a private copy of their own scoreboard (the rank board, or their siege
team's board in a match) with every team's name tag set to hidden; the copy follows the real board every second and the
real board comes back afterwards. A siege match that starts or ends during a blackout swaps the board behind the copy.

