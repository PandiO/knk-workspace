# Custom Enchantment Combat Values — Admin Guide

**Status:** Living document — update in place as the code changes. Describes the trunks (knk-plugin `main`,
knk-web-api `master`, knk-web-app `main`): package B (#151, #155, #156) merged 2026-10-26 and live-tested 2026-10-27;
later sections note their own state
**Last updated:** 2026-11-03 (§ 5: #211 keeps the swirl particles, knk-plugin `main` `8f11bed5`); 2026-11-03 (status lines: B, G, #211 merged; § 1/§ 3/§ 6: #201/#202 merged; § 6 grey cooldown bars, navigation bar on top); 2026-11-02 (§ 1/§ 3: Flash Chaos's Slowness and Nausea as combat values, form seed v3, #201; § 6: ability cooldown boss bars, #202; in review on `claude/enchantments-201-202`, knk-plugin `ed704eff`, knk-web-api `8a02258`, knk-web-app `d058aea`, **not merged, not live-tested**); 2026-11-02 (§ 5: invisible players' armour and held items hidden, #211, in review on `claude/invisibility-full-hide`, not merged); 2026-10-27 (§ 5 round 2: name tags hidden while blinded and the invisible player's own tag, red
`Frozen by <staff> for: <reason>` bar, #169/#170, in review on `claude/alpha-run-1-effects`, knk-plugin `9bc2b31`, not
merged); 2026-10-27 (§ 5: effect boss bars and the flash_chaos name-tag blackout, knk-plugin `911eb2a`); 2026-10-26 (PandiO/knk-workspace#151, #156, #155)
**Companion docs:** [ability definition reference](../../specs/custom-enchantments/ABILITY_DEFINITION_REFERENCE.md),
[package B report](../../reports/alpha-tests/25-10-2026/2026-10-26-package-b-enchantments-freeze.md)

Since [#151](https://github.com/PandiO/knk-workspace/issues/151) an admin sets, per custom enchantment, how often its
effect goes off, how long it lasts, how that grows per level and the cooldown of the player who used it. The values
live on the enchantment definition in knk-web-api and are edited in the web app; the plugin reads them without a
restart. [#156](https://github.com/PandiO/knk-workspace/issues/156) made the defaults weaker (closed alpha test run 1:
freeze spam that couldn't be countered).

## 1. Where to edit

Web app → Enchantment definitions → edit a **custom** enchantment → step **Combat values**. The step comes with the
form seed `EnchantmentDefinition - Default (seed v3)` (#201; v2 has the step without Flash Chaos's two fields): import it
once from the form configuration list (Import / seeds, `EnchantmentDefinition`) and make it the default (v1 and v2 can
stay or be deleted). A form without a field leaves its stored value alone when it saves.

| Field | Meaning | Used by |
|---|---|---|
| Chance at level I (%) | Chance, 0-100, that a hit sets the effect off at level I | On-hit enchantments: Poison, Wither, Freeze, Blindness, Confusion, Strength |
| Chance per extra level (percentage points) | Added per level above I; may be negative. Result kept between 0 and 100 % | Same |
| Cooldown | On: after the effect goes off (or the ability is used), the same player can't set it off again until the cooldown ran out, on any target. Off: no cooldown; the length is kept | All |
| Cooldown length (seconds) | 0-86400 | All |
| Duration at level I (seconds) | How long the effect lasts at level I (0.05 = one tick) | Poison, Wither, Freeze, Blindness, Confusion, Strength, Resistance, Invisibility; Flash Chaos: its **Slowness** (#201) |
| Level multiplier | Share of the level-I duration added per extra level: 1 = level × the level-I duration, 0.5 = ×1.5 and ×2 at levels II and III, 0 = the same at every level | Same as duration; Flash Chaos: both its Slowness and its Nausea |
| Effect level (Flash Chaos: Slowness) | 1-10: the Slowness level Flash Chaos gives (1 = Slowness I) | Flash Chaos only (#201) |
| Second effect duration at level I (seconds) (Flash Chaos: Nausea) | 0-3600: how long Flash Chaos's Nausea lasts at level I | Flash Chaos only (#201) |

At level *n*: chance = level-I chance + (*n* − 1) × chance per level; duration = level-I duration × (1 + multiplier ×
(*n* − 1)). Apart from Flash Chaos's Slowness level, potion strength (amplifier) is not configurable here; Flash Chaos's
Nausea stays level II, because the game draws Nausea the same at every level. The area damage of Chaos / Flash Chaos
is not configurable here either. A Flash Chaos duration of 0 leaves that debuff out. Cleaving
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
values in effect at its level: `chance 15%, duration 2.25s, cooldown 20s`; for Flash Chaos a second line
`effect level 1, second effect 12.5s` (config `messages.cmd-info-tuning-effects`).

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
| Chaos | — | — | — | — | 90 s |
| Flash Chaos (#201) | — | — | Slowness 5 s, 0; level I | — (max I) | 90 s |
| Health Boost, Armor Repair | — | — | — | — | 120 s |

Flash Chaos's Nausea defaults to 12.5 s (second effect duration). Its Slowness I 5 s and Nausea II 12.5 s were
hard-coded before #201; the defaults keep them. An existing database gets them at the next API start (the columns are
new, so empty).

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

## 5. What players see: boss bars and hidden name tags (#169, #170)

Merged 2026-11-01 (round 2, `9bc2b31`) and live-tested by the developer the same day (#169, #170).

**Boss bars ([#170](https://github.com/PandiO/knk-workspace/issues/170)).** A player hit by a timed debuff from a custom
enchantment gets one boss bar per effect, `Poison · 4s`, counting down (refreshed every 5 ticks):

| Source | Bar |
|---|---|
| Poison, Wither, Freeze, Blindness, Confusion | `Poison`, `Wither`, `Frozen`, `Blindness`, `Nausea` · remaining time |
| Flash Chaos (on players around the user) | `Slowness` and `Nausea`, for their combat values (default 5 s and 12.5 s, #201) |
| Staff `/freeze` | static, full **red** bar `Frozen by <staff> for: <reason>` (no timer) until `/unfreeze`; back on the next join while still frozen |

The staff freeze bar names the staff member who froze the player. It says `staff` instead when that isn't known: a
freeze from the console, by a staff member who is vanished (owner/staff mode, so the bar doesn't give them away), from
the web app, or from before a server restart (only the reason is stored with the user). A relog on the same server run
keeps the name. Without a reason the bar reads just `Frozen by <staff>`; a reason over 60 characters is cut with `…`.
The Player manager's freeze button uses the reason `Frozen by a member of staff`.

The same effect again restarts its bar (no second bar). A bar follows the real effect: milk or an early unfreeze ends
it, a longer copy of the potion from elsewhere keeps its longer time. Timed bars go on death, every bar on quit. The
durations are the combat values above (§ 1, § 3), so a change in the web app changes the bar too. The bars are the
plugin's own, next to the navigation bar and any other boss bar. Creatures get nothing. Self-buffs (Strength,
Resistance, Invisibility) have no bar: they are not debuffs.

**Blinded players see no name tags ([#169](https://github.com/PandiO/knk-workspace/issues/169)).** A player blinded by
the **Blindness** enchantment sees no other player's name tag for as long as the blindness lasts (its combat-value
duration); other players' views don't change. A second blindness hit extends it. It ends early when the blindness is
gone (milk), on death and on quit. The tab list, the sidebar (siege timer and objectives) and the health below names
stay. **Flash Chaos** and plain **Chaos** don't hide name tags (developer decision 2026-10-27; Flash Chaos keeps its
Slowness and Nausea).

How (for staff debugging): the blinded player is shown a private copy of their own scoreboard (the rank board, or their
siege team's board in a match) with every team's name tag set to hidden; the copy follows the real board every second
and the real board comes back afterwards. A siege match that starts or ends meanwhile swaps the board behind the copy.

**Invisible players' own name tag ([#169](https://github.com/PandiO/knk-workspace/issues/169)).** While the
**Invisibility** ability is active, the user's name tag is hidden from other players, and it shows again when the
invisibility ends (also by milk or death). The game does this itself for an invisible player, except for players on the
same scoreboard team when that team may "see friendly invisibles". The rank teams (`default`, `owner`, `staff`,
`tier_<id>`) now have that turned off, so players of the same rank no longer see an invisible player's tag (or
see-through body). In a siege match, **teammates still see their invisible teammate** (name tag and see-through body);
the other teams don't. Nobody is moved between teams for this.

**Invisible players' armour and held items ([#211](https://github.com/PandiO/knk-workspace/issues/211); merged
2026-11-02, knk-plugin `main` `da422f3b`; swirls back on in `8f11bed5`, 2026-11-03; in review, not live-tested).** Vanilla Invisibility still shows armour
and held items. While the **Invisibility** ability is active, players who don't see through it get empty armour and
hands for the user instead (per-viewer equipment packets; the user's real items don't change). The user **stays in
the tab list** and can still be hit; owner/staff mode's `hidePlayer` isn't used because it also removes the tab entry.
Who still sees everything: siege teammates (see-through body, tag and equipment) and spectators. The ability's potion keeps
its swirl particles (developer decision 2026-11-03). It ends when the invisibility ends (time, milk, death, a command) and on plugin disable;
on quit the ability's invisibility is removed, so after a relog everyone sees the player. Arrows stuck in the body
can still show; the client draws them from entity data that Paper has no per-viewer API for (to check live).

## 6. Ability cooldown bars (#202)

Merged 2026-11-03 (knk-plugin `main` `4f29e9c3`); tested by the developer the same day. Grey bars and the navigation bar on top (`7e43fb87`) still need a live re-check.

The player who used an ability gets a **grey** boss bar (white bar, grey text; boss bars have no grey) with its remaining cooldown, `Flash Chaos cooldown · 1:28`
(`m:ss` from one minute up, seconds below), counting down until it can be used again:

| Ability | Bar |
|---|---|
| Chaos, Flash Chaos, Health Boost, Armor Repair, Resistance, Invisibility (right-click) | `<Name> cooldown` |
| Freeze (on hit, per attacker) | `Freeze cooldown`, after a hit that froze someone |
| Cleaving's charged right-click strike | `Cleaving strike cooldown` (length from `gates.cleaving.charged-cooldown-seconds`) |

The other on-hit enchantments (Poison, Wither, Blindness, Confusion, Strength) keep their cooldown without a bar. The
length is the cooldown that was applied (§ 1/§ 3; with the cooldown switched off there is no bar). Using the ability
again after it is ready restarts the bar. The bar follows the cooldown store: `/ce cooldown clear [player]` removes it
at once. It stays through death (the cooldown keeps running), goes on quit and comes back on join while the cooldown
still runs (then full at the time left). The bars sit next to the debuff bars (§ 5) and the staff freeze bar; the
navigation bar always stays on top of them (developer, 2026-11-03).


## 7. Death messages for Chaos and Flash Chaos kills (#222)

In review on `claude/death-messages-222` (knk-plugin `13c0a205`, 2026-11-03), **not merged, not live-tested**.

A player killed by **Chaos** or **Flash Chaos** gets a death message that names the ability and the player who used
it, instead of vanilla's melee `<victim> was slain by <player>`:

`Steve was killed with Flash Chaos by Alex`

Only a death inside the ability's own hit counts (developer decision 2026-11-03). Every other death keeps the vanilla
message: Poison or Wither over time, a fall or another hit shortly after a custom-enchantment hit, and a normal sword
kill. In a siege match there is still no death message (the match clears it, as before). The kill is credited as
before: the ability damages with its user as the source, so the killer, the PvP statistics (#164) and the siege kill
handling are unchanged.

The text is in the plugin's `config.yml`, read at every death (so `/ce reload` applies a change; no API or web-app
setting):

```yaml
custom-enchantments:
  death-messages:
    enabled: true                    # false = vanilla messages for these kills too
    default: "%victim% was killed with %enchantment% by %player%"
    overrides:                       # optional, per enchantment id
      chaos: "%victim% was blown apart by %player%'s %enchantment%"
```

Placeholders: `%victim%`, `%player%` (who used the ability), `%enchantment%` (its display name, `Chaos` /
`Flash Chaos`); `&` colour codes work. An override that is empty uses the default. The names are plain player names
(no rank prefix).
