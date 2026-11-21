# Harvesting — Player Guide

**Status:** Draft · **Last updated:** 2026-11-21 (first version, player harvesting P8 #134, production chain L22)
**Checked against:** knk-plugin `claude/production-p8` (in review, not in `next` yet; you see nothing of this until staff
switch production on and write harvest rules, and it has not been tried on a live server yet)
**Related:** [player handbook](player-handbook.md), [territory player guide](territory-player-guide.md),
[production kinds § 6-§ 7](../../specs/production-storage-transport/PRODUCTION_KINDS.md) (the design),
[plugin configuration § 4.31](../admin/plugin-configuration.md#431-production) (for staff)

Mines, quarries, farms and loggers are production structures. Each has one or more **yield areas**: the rock it digs,
the fields it farms, the forest it cuts. You can work in those areas and harvest what the structure produces. Harvesting
counts as **working for the town**: you keep a share of what you harvest as your pay, and the rest goes straight into the
structure's storage for the town.

## 1. Who it is for

Everyone who meets a structure's **harvest rule**. Each kind of structure has its own rules, set by staff. A rule says:

1. **What** you may harvest: blocks (stone, an ore, ripe wheat, oak logs) or animals (cows, sheep).
2. **Who** may: everyone, or only players with a permission (for example a job or a town role) or a title.
3. **With what**: any tool, or a tool of a kind (a pickaxe, an axe, shears) and a lowest tier (stone, iron, diamond).
4. **How often**: some rules have a short cooldown in each area.

If you don't meet a rule, you can't break its blocks in the area. Everything else in the area is protected as usual:
outside the rules, you can't build or break in a structure's land unless you are allowed to anyway.

## 2. Harvesting

1. Go into a structure's yield area. Staff can show you where it is; most areas are the structure's own land, a
   logger's forest can be a circle around it.
2. Break a block (or kill an animal) the rule names, with the right tool.
3. Nothing drops on the ground. A moment later your share arrives in your inventory with a line in chat, for example
   **"+2 Cobblestone (your share of the harvest)"**. If your inventory is full, the rest falls at your feet.
4. If you logged out before the share arrived, you get it when you join again.

What you get is always the rule's item (for example cobblestone for mined stone, wheat for wheat), not the vanilla
drop. The town gets the rest of the harvest.

## 3. Blocks grow back

Every harvested block comes back after a while (often a minute or so; longer when the area has been harvested a lot):

| You harvest | Meanwhile you see | Then |
|---|---|---|
| Ore or rock | A depleted block (stone, bedrock or netherrack) | The ore or rock is back |
| A ripe crop | The crop replanted, small | It is fully grown again |
| A flower | Nothing (air) | The flower is back |
| A log | The **whole tree** comes down at once, and a sapling stands where it grew. The sapling doesn't grow on its own | The same tree is back, exactly as it was |

1. You can't break a block that is waiting to grow back: you see **"This block is regenerating."**
2. A block only comes back where nothing else was put in the meantime, and never on top of you: step aside if you are
   standing where it should be.

## 4. When you can't harvest

You see **"You can't harvest this here:"** followed by the reason:

| Reason | What to do |
|---|---|
| "you need the permission ..." | The rule is for players with that permission (a job or role). Ask your town or staff |
| "you need the title ... or higher" | Earn the title first |
| "needs a pickaxe" (or another tool) | Hold the right tool |
| "needs an iron tool or better" | Use a better tool |
| "it isn't ripe yet" | Wait until the crop is fully grown |
| "wait 10 s" | The rule has a cooldown in this area |
| "production at ... is switched off" | The structure is paused by its owners or staff |
| "... is exhausted for now; come back later" | The area has been harvested out (only on servers where staff turned this on) |
| "your account is still loading" | You just joined; try again in a moment |

If you see **"Your harvest at ... was not booked"**, the server could not count that harvest (for example a rule was
switched off a moment ago). You got nothing for it, and the block still grows back.

## 5. Why the structure slows down

Each area has a resource pool. Heavy harvesting empties it for a while, and the structure then produces less on its own
(never less than half) until the pool fills up again. A good rule still leaves the town better off when you work: the
town's share of your harvest is more than what the structure loses.
