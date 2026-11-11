# Custom Enchantments — Player Guide

**Status:** Living document — update in place as the game changes
**Last updated:** 2026-11-11 (first version, PandiO/knk-workspace#302; checked against knk-plugin `main` `121030f` and
knk-web-app `main` `9a85238`)

Knights and Kings adds its own enchantments on top of the vanilla ones: weapons that poison, freeze or blind on a hit,
and items with a right-click ability such as a blast around you or a quick heal. This guide explains how to get them,
how they work and what you see. Staff tune the numbers (chances, durations, cooldowns, damage), so the values below are
the **starting values**; the live numbers are always here:

- **Web app → Guides → Custom enchantments and abilities** (`/guides/enchantments`), open without signing in. It lists
  every enchantment with its chance, cooldown, effects and damage per level.
- **`/ce info`** with the item in your hand: the values in effect at that item's level.

## Getting a custom enchantment

### Enchantment books

An enchantment book shows `Teaches: <Enchantment> <level>` (for example `Teaches: Poison II`) and
`Right-click to choose an item to enchant.` Books don't work in an anvil.

1. Hold the book (either hand) and **right-click** the air or a block.
2. A screen `Apply <Enchantment> <level>` lists the items in your inventory that can take it, the ones you can
   enchant now first. Custom enchantments only go on items with durability: weapons, tools, armour, bows and shields.
3. Click an item marked `Click to apply …`. The book is used up and you hear the enchanting table.

What the item lines mean:

- `✘ Can't apply …` with a reason under it: the item already has the enchantment at that level or higher
  (`Already has …`), the enchantment can't go on that kind of item, or the book doesn't work on this server.
  Clicking it only repeats the reason.
- `Grade limit: only up to <level>` / `Click to review`: the item's grade allows a lower level than the book. A
  `Grade limit - apply anyway?` screen tells you which level you would get; **Apply** uses up the book, **Cancel**
  keeps it. (On this server the grade limit applies to vanilla enchantments; custom enchantments are normally not
  limited by grade.)
- An item that already has the enchantment gets the higher of the two levels.
- **Bonus level:** with some luck (1 in 5 by default) the book gives one level more than it says, never above the
  enchantment's maximum: `Enchantment applied - lucky, a bonus level: <level>!`

If nothing you carry can take the enchantment you see `Nothing in your inventory can hold <Enchantment>.`

### Other ways

- **Kits, lootboxes and items from staff** can come with custom enchantments already on them.
- An item that has a custom enchantment **can't be enchanted at an enchanting table** any more.
- Staff can add an enchantment with `/ce add`; players can't.

### How it shows on an item

A custom enchantment is a grey lore line right under the item's vanilla enchantments, for example `Poison II` or
`Flash Chaos I`. Vanilla and custom enchantments sit side by side and both work.

## Using them

### On-hit enchantments

**Poison, Wither, Freeze, Blindness, Confusion, Strength.** They work on **melee hits with the weapon in your main
hand**, against players and mobs. Arrows and other projectiles don't set them off. Each hit has a chance to set the
effect off; after it goes off, a cooldown keeps it from going off again for a while (on any target). There is no
message while one is on cooldown.

| Enchantment | Levels | Effect (on the one you hit, unless noted) | Starting values (I / II / III) |
|---|---|---|---|
| Poison | I–III | Poison II. Poison can't kill: it stops at half a heart | 10 / 15 / 20 % chance; 3 / 4.5 / 6 s; 8 s cooldown |
| Wither | I–III | Wither II; it can kill | 10 / 15 / 20 %; 2 / 3 / 4 s; 8 s cooldown |
| Freeze | I–III | **Frozen**: held in place (also in mid-air), you can still look around | 10 / 15 / 20 %; 1.5 / 2.25 / 3 s; 20 s cooldown |
| Blindness | I–III | Blindness; the blinded player also sees no other player's name tag | 20 / 30 / 40 %; 2 / 3 / 4 s; 10 s cooldown |
| Confusion | I–III | Nausea (the screen wobbles) | 10 / 15 / 20 %; 3 / 4.5 / 6 s; 8 s cooldown |
| Strength | I–II | **You** get Strength I / II, so your own hits deal more damage | 15 / 30 %; 15 s; 2 min cooldown |

### Right-click abilities

**Chaos, Flash Chaos, Health Boost, Armor Repair, Resistance, Invisibility.** Hold the item in your **main hand** and
**right-click** the air or a block. An ability always goes off, then needs its cooldown. While it cools down,
right-clicking tells you `<n> seconds remaining`, and a grey boss bar `<Ability> cooldown · 1:28` counts down (it stays
through death and comes back when you rejoin).

| Ability | What it does | Starting values |
|---|---|---|
| Chaos | A blast around you: damage to every player and creature within the damage radius, everyone within the knockback radius is thrown back, gate doors near you are damaged too | 40 damage within 3 blocks (armour lowers it), knockback within 5 blocks; 90 s cooldown |
| Flash Chaos | A stronger blast: damage within the damage radius, knockback within the knockback radius, and players there get Slowness and Nausea | 60 damage within 3 blocks, knockback within 5, Slowness I for 5 s, Nausea for 12.5 s; 90 s cooldown |
| Health Boost | Heals you over a second and a half | 6 health (3 hearts); 2 min cooldown |
| Armor Repair | Repairs every piece of armour you wear to full durability | 2 min cooldown |
| Resistance | You take less damage from every source | Resistance I / II for 10 / 15 s; 2 min cooldown |
| Invisibility | You turn invisible: other players don't see you, your armour, what you hold or your name tag. You stay in the tab list and can still be hit; siege teammates still see you | 10 s; 90 s cooldown |

A player has 20 health (10 hearts), so a Chaos or Flash Chaos blast at its starting values is very dangerous. A player
killed by one shows in chat as `Steve was killed with Flash Chaos by Alex using [Storm Blade]` (hover over the item to
see it).

### Cleaving (sieges)

**Cleaving** (I–IV) is the siege enchantment for gate doors: boosted melee hits on doors and a right-click charged
strike. It does nothing to players. See the [gate structures player guide](gate-structures-player-guide.md#cleaving-the-siege-enchantment-for-gate-doors).

## What you see

- **Debuff bars:** a player hit by a timed effect gets a boss bar per effect counting down: `Poison · 4s`, `Wither`,
  `Frozen`, `Blindness`, `Nausea`, `Slowness`. Milk ends the effect and its bar; death ends them too.
- **Cooldown bars:** grey bars for every right-click ability, for Freeze (`Freeze cooldown`, after a hit that froze
  someone) and for Cleaving's strike. The other on-hit enchantments keep their cooldown without a bar.
- **`/ce info`** (everyone can use it): `Custom enchantments on held item:`, then per enchantment its name, level,
  cooldown left and a line with the values in effect (`chance 15%, duration 2.25s, cooldown 20s`); Flash Chaos, Chaos
  and Flash Chaos's blast, and Cleaving get an extra line with their own numbers.

## Where they don't work

- **Combat safezones:** towns and districts are safezones unless PvP is allowed there. A player standing in a
  safezone is not hit or affected by on-hit enchantments or by a Chaos / Flash Chaos blast (mobs still are). There is
  no message. Self-buffs such as Health Boost work everywhere.
- **Permissions:** using an ability needs the rank permission for it (staff grant `customenchantments.use.*` to the
  ranks that may use them). Without it, right-clicking simply does nothing. On-hit enchantments need no permission.
- **Creative mode:** the server can switch custom enchantments off for players in creative mode.

## Known issues

- **Cleaving IV doesn't work yet:** a level-IV Cleaving item isn't recognised (no boosted hits, no strike, not listed
  by `/ce info`). Levels I–III work. Tracked in [#318](https://github.com/PandiO/knk-workspace/issues/318).

## For staff

How the numbers are set, when the server picks a change up and what each field means: the
[custom enchantment combat values admin guide](../admin/custom-enchantment-combat-values-admin-guide.md). All
`/ce` commands: the [commands reference](commands.md).
