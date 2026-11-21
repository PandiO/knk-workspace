# Menus — Player Guide

**Status:** Living document — update in place as the game changes
**Last updated:** 2026-11-21 (new § Shops: the shop menus of production P10b in knk-plugin `next` `c349a53c`, PandiO/knk-workspace#687, docs PandiO/knk-workspace#966); 2026-11-21 (§ Reward inbox: in knk-plugin `next` `bdd8b463`, two more messages, a link to the admin guide, docs PandiO/knk-workspace#915); 2026-11-21 (§ Reward inbox and § Kits: items that don't fit go to the reward inbox, production chain L20, PandiO/knk-workspace#684, knk-plugin branch `claude/production-p7b`, not in `next` yet); 2026-11-21 (§ The menu item: what a click does in a siege, set on the game settings page; § Sieges: the
siege shop and Siege unlocks menus; siege shop chain #870, #871, #868, #869 in `next`, docs PandiO/knk-workspace#908); 2026-11-20 (§ Structures and § Storage terminals: in knk-plugin `next` `8e672ba6`, more terminal
messages, docs PandiO/knk-workspace#903); 2026-11-20 (§ Structures and § Storage terminals and displays, production chain L18,
PandiO/knk-workspace#74, knk-plugin branch `claude/production-p6`, not in `next` yet); 2026-11-13 (§ Kits: kits a staff member gives you from the web app, PandiO/knk-workspace#261, in
knk-plugin `next` `745fcf6`, not yet released); 2026-11-11 (first version, PandiO/knk-workspace#302; checked against knk-plugin `main` `121030f`; menu
texts are the seed defaults of knk-web-api `master` `b5e57fa`, staff can change them)

Most of what you do in Knights and Kings beyond walking and fighting has a menu: kits, your profile and titles, the
item catalogue, discoveries, teleports, statistics and sieges. This guide explains how to open them, how to move
around in them and what each one is for.

## Opening the menu

### The menu item

Every player gets a **nether star called `Menu (click to open)`** in the right-most hotbar slot when they join and
after they respawn. It is there for everyone, and especially for Bedrock and console players, who can't type commands
easily.

- **Right-click** or **left-click** it to open the main menu.
- Right-clicking a block that does something itself (a door, chest or button) uses that block. **Sneak and
  right-click** to open the menu there.
- In your own inventory screen (E), clicking the star closes the inventory and opens the menu.
- It can't be dropped, moved or put into a chest, and you keep it when you die. If one of your own items was in that
  slot when you joined, it was moved to a free slot. With a completely full inventory you don't get the star until
  there is room (rejoin or respawn).

**In `next`, not released yet** ([#870](https://github.com/PandiO/knk-workspace/issues/870),
[#871](https://github.com/PandiO/knk-workspace/issues/871)): the staff set the item's look and what each click does on
the web app's game settings page, so the name, material and slot may differ on your server, and a change reaches you
without a rejoin (a new slot at your next join or respawn). With the starting settings:

| Where you are | Right or left click | Shift + right click | Shift + left click, or a click in the inventory |
|---|---|---|---|
| Anywhere else | The main menu | The main menu | The main menu |
| At a siege's hub (team split, and the result after the match) | Your siege's **Information** menu | The main menu | The main menu |
| In a running PvP Siege match | Your siege's **Information** menu | The **siege shop** (as `/siege shop`) | The main menu |

While you are still waiting in matchmaking the item opens the main menu. In Siege Survival it will work as in a PvP
match once Siege Survival is released. If the game server can't reach the web server when it starts, every click opens
the main menu, as before.

### Commands

| Command | Opens |
|---|---|
| `/menu` | The main menu |
| `/discoveries` (`/disc`) | Your discoveries |
| `/warp` (no name) | The teleport menu |
| `/siege` (no arguments) | Your own siege's information menu, or the siege overview when you aren't in one |
| `/siege menu` (`/siegemenu`, `/sgm`) | Your siege's information menu (only while you are in a siege) |
| `/leaderboard` (`/lb`, no arguments) | The leaderboards |
| `/stats settings` | Who may see your statistics |
| `/inbox` | Your reward inbox (where production is switched on) |

All commands: the [commands reference](commands.md).

## The main menu

The main menu (`Knights and Kings`) has a tile for each part of the game. A tile only shows when its menu is
available, so a tile may be missing for a while after a server start.

| Tile | What you do there |
|---|---|
| **Your head** | Your profile: balances (coins, gems, experience, prestige XP), title progress and every title, statistics and statistics privacy |
| **Kits** | See all kits and claim one; buy premium kits once with gems |
| **Siege Minigame** | See running sieges and join one |
| **Item catalogue** | Every item in the game, shown as it would be given; search and filter by category |
| **Premium tiers** | Every premium tier and your own (salary multiplier, until when) |
| **Discoveries** | The places you discovered, their rewards, and how many are left per type |
| **Teleport to points on the map** | Teleport to spawn and to important places; prices are paid in gems |
| **Structures** | Farms, mines, workshops and warehouses: what they produce and how they are doing (only on servers with production switched on) |
| **Player manager** | Staff only |
| **Exit** (top right) | Closes the menu |

### Kits

Each kit shows what is in it, its cost and whether you can claim it now: `Click to claim`, `Available again in 4m 10s`
(counting down), or a red reason. A **premium kit** is bought once with gems: click it, then **Confirm** (or
**Cancel**) — the chat asks `Buy the kit "<name>" for N gems? Click Confirm or Cancel.` After buying you claim it like
any other kit. Claimed items go into your inventory; what doesn't fit is **dropped at your feet**, or, on servers where
the reward inbox is on, goes to your **reward inbox** (see below). (When that happens you may see a technical line like `placed=… dropped=…` in chat; it will be replaced by a readable message, [#321](https://github.com/PandiO/knk-workspace/issues/321).)

**Kits a staff member gives you.** Staff can give you a kit from the web app as well as in game. You don't need to do
anything to receive it, and it doesn't cost you anything:

- **Online:** the items arrive within a few seconds, with the chat line `A staff member gave you the "<kit>" kit.`
- **Offline:** they arrive a few seconds after your next join, one chat line per kit, in the order they were given.
- **In a siege** (lobby or match): nothing arrives while you play, because your siege inventory is replaced when the
  siege ends. The kit arrives right after the siege has given your own inventory back.

The items go into your inventory the same way as a claimed kit; if something doesn't fit, you also see `Some of it
didn't fit and was dropped at your feet.` A kit is never handed over twice. In the rare case that the server stops,
or you log out, at the very moment it is being handed over, it can be lost; then ask staff to give it again. A kit staff give you starts that
kit's waiting time for your own claim, as if you had claimed it. (Since PandiO/knk-workspace#261; part of the next
release, not live yet. Kits given from the web app before that release don't arrive by themselves: ask staff to give
them again.)

### Reward inbox

*On servers where staff switched production on (`production.enabled`); in knk-plugin `next` `bdd8b463`,
PandiO/knk-workspace#684, not released yet. For staff: the [reward inbox admin guide](../admin/reward-inbox-admin-guide.md).*

When a reward doesn't fit in your inventory, it waits for you in your **reward inbox** instead of dropping on the
ground: kit items (also kits staff give you, and your starter kit), lootbox items, and gifts from staff. If you were
offline when a kit was handed over, it is in your inbox too. The chat tells you: `25 items didn't fit and went to your
reward inbox (/inbox).`

1. **Open it** with `/inbox`. Each item shows how many wait (`Waiting: 24`) and when the first of them expires
   (`24 expire in 30 days`). The ender chest at the bottom shows how full the inbox is (`Filled: 49 of 100 (49%)`).
2. **Claim:** left-click an item to take a stack, right-click to take one, shift-click to take as much as fits in your
   inventory. Only what fits is taken; the rest stays in the inbox. The oldest items are taken first.
3. **It has a limit.** Rewards that arrive when the inbox is full are **lost**. You get a warning as it fills up (`Your
   reward inbox is 80% full. ...`) and a red message when something was lost. Premium ranks have a bigger inbox.
4. **Items expire 30 days** after they arrive. You get a reminder a week before and a day before; expired items are gone.
5. When you join with items waiting, the chat says how many (and whether some expire soon).
6. Unique items (for example a sword with its own name and enchantments) can't be claimed in game yet; they show in the
   inbox, and rewards like that still drop at your feet when your inventory is full.

| Message | Meaning |
|---|---|
| `Your inventory is full. Make room, then claim again.` | Nothing fits; nothing was taken |
| `Claimed 10 items Bread (the inbox has less than that)` | You got what was left |
| `You can't claim rewards during a siege. Your inbox waits for you.` | Claim after the siege |
| `The reward inbox is switched off on the server right now.` | Staff switched it off; your items stay in the inbox |
| `Unique items can't be claimed in game yet; ask a staff member.` | See point 6 |
| `Your reward inbox is full: 3 items were lost.` | The inbox was at its limit when a reward arrived |
| `Nothing claimed: your inbox is locked right now.` | Staff locked your inbox for a moment; try again later |
| `Your inventory filled up meanwhile: the rest was dropped at your feet.` | Something took the room while the claim ran; the rest lies at your feet |
| `The reward inbox is not switched on on this server.` | This server has no reward inbox; rewards drop at your feet as before |

### Profile and titles

Your profile is read-only. The title list shows every title: reached ones with `✔`, your current one glowing with
`» Name «`, and the ones ahead greyed out with how much XP you still need and their salary. **Statistics** opens your
statistics (also `/stats`), **Statistics privacy** who may see them; see the
[statistics player guide](statistics-player-guide.md).

### Teleports

Each destination shows its price (`free` or in gems) and any title or premium tier it needs, then `Available! Click
here to teleport` or `Locked! <reason>`. Clicking closes the menu and starts the teleport: it begins after a few
seconds, and **moving or taking damage cancels it**. The gems are charged when the teleport happens. The menu also
lists your pending `/tpa` requests.

### Sieges

The siege overview lists every siege with its scenario, players, stage and timer. Inside a siege, its information
menu lets you join or leave during matchmaking (leaving needs a second click within 3 seconds), vote, read the
objectives and change your spawnpoint. See the siege guides for the match itself.

In `next`, not released yet ([#868](https://github.com/PandiO/knk-workspace/issues/868),
[#869](https://github.com/PandiO/knk-workspace/issues/869)): during a running match the information menu has a
**Shop** button (emerald, top left) that opens the **siege shop** (its categories, then one category's offers; click an
offer to buy), on servers with the shop switched on. Outside a match the siege overview has a **Siege unlocks** button
(anvil, top left): every siege weapon type with its coin price, minimum title and your state; an unlockable one asks
you to **Confirm** first. Both are explained in the
[siege guide](siege-player-guide.md#siege-points-the-siege-shop-and-weapon-unlocks).

### Structures

*On servers with production switched on (in knk-plugin `next` `8e672ba6`, PandiO/knk-workspace#74; not released
yet).*

The **Structures** tile lists every production structure (farm, logger, quarry, mine, fishery, florist, pasture,
workshop) and every warehouse, one item each, with its kind, town, level, what it produces and its status:

| Status | Meaning |
|---|---|
| **Working** (green) | It produces |
| **Stalled** (gold) | Switched off, no line running, or no worker present |
| **No road** (red) | A structure outside a town that isn't connected to a road; its goods can't be carried away |
| **Full** (red) | A line stopped because its storage is full |

1. **Filters:** the compass cycles through the towns, the hopper through the kinds, the redstone torch through the
   statuses (after the last one: all again); the barrier clears all filters. The sign searches by name.
2. **Your town first:** when you open the list standing on a town's land, the Town filter starts on that town. In the
   wilderness it starts empty.
3. **A structure's menu:** click a structure. Everyone sees its name, kind, town, level, what it produces and its
   status. **Members of its town** and staff also see the exact rates per hour, its workers (present and away), its
   warnings, its storages with what they hold ("Amount: N") and a **Transport orders** button: open and recent orders
   with cargo, from, to, state and when they arrive.
4. You can't change anything here; staff have extra buttons (see "For staff").

Until town roles arrive, "member of a town" is a permission your town's staff give you.

### Storage terminals and displays

*Same servers and status as Structures.*

Some chests and barrels in warehouses and town vaults are bound to a storage:

1. **Terminal:** right-click it and you see the storage itself, page by page (the chest stays empty). Left-click an
   item to take a stack, right-click to take one, shift-click to take as much as fits in your inventory. To put
   something in, click it in your own inventory (right-click puts one). The middle item at the bottom shows how full the
   storage is. Only members of the storage's town (or the player it belongs to) and staff can use a terminal.
2. **Display:** right-click it and you see a sample of what the storage holds, as full as the storage is. You can't take
   anything out; its items are only a picture.
3. You can't break a bound chest or barrel, and hoppers don't take from it.

What a terminal refuses, and why:

| Message | Meaning |
|---|---|
| `Only members of this storage's town, its owner and staff can use this terminal.` | It isn't your town's |
| `This item isn't in the item catalogue (...)` | A renamed item or another plugin's item; it can't be stock |
| `Damaged items can't go into a terminal ...` / `Enchanted items can't go into a terminal ...` | They would come back repaired or without enchantments |
| `Unique items can't be put in a terminal in game yet; use the web app.` | Unique items move through the web app for now |
| `Production is switched off; the terminal moves nothing right now.` | Staff switched production off |
| `Nothing put in: the storage is full.` | The storage has no room; your items are back in your inventory |
| `Put in 40 (24 back: the storage is full)` | Only part fitted; the rest is back in your inventory (or at your feet when that is full) |
| `Nothing taken: not enough in stock.` | Someone took it first; the page shows what is left |
| `Your inventory is full.` | Make room before taking |
| `Unique items can't be taken out in game yet; use the web app.` | Unique items move through the web app for now |
| `That is a display sample, not a real item.` | Display items are only a picture |
| `The storage is busy or locked; try again in a moment.` | Another move happened at the same time, or staff locked the storage |
| `This container is no longer bound.` | Staff unbound it; it is a plain chest again |

### Shops

*On servers with production switched on (in knk-plugin `next` `c349a53c`, PandiO/knk-workspace#687; not released
yet).* Town shops sell goods for coins and buy goods back. **For now only staff can open a shop** (with
`/knk shop <shop id>`); shopkeepers that open it for every player come next.

**Buying:**

1. **The shop menu** shows your coins (gold ingot, top left), the shop's information (anvil: type, kind, level, town,
   whether it buys from players), a **Sell** chest when the shop buys, and **Back**. Below them the catalogue: each item
   as the real item with `Price: <n> coins each` and its stock (`Stock: plenty` when it never runs out). Featured items
   glow and come first; sold-out items are greyed out with `Sold out` (some shops hide them). Use the arrows for more
   pages.
2. **Click an item** for its information menu: the **Amount** chest (click it to step through 1, 8, 16, 32, 64), the
   item, the name tag `This item costs: <n> coins` with the stock, the amount and the total, and a map with the
   description and how the price is set. The amount is never more than the stock; a unique item is always one.
3. **Click the name tag** to open the confirmation: `Are you sure you want to buy 8 x Bread?` with the price each and
   the total. Then:
   1. **Confirm** (green): the items go into your inventory. Make room first; the shop checks.
   2. **Confirm: to your reward inbox** (ender chest): the items wait in your [reward inbox](#reward-inbox) and you
      claim them with `/inbox`.
   3. **Cancel** (red) or **Back**: nothing is bought.
4. After a purchase the chat says `You bought 8 x Bread for 160 coins. You have 340 coins left.` and you are back in
   the item's information menu. The coins go to the shop's town.
5. **The price changed?** If the price changed between the confirmation and your click, nothing is bought: you see
   `The price changed. Check the new price and confirm again.` and the confirmation shows the new price. Click Confirm
   again to buy at it.
6. **Unique items** (one exact item, for example an enchanted sword) are listed with their enchantments but can't be
   bought in game yet; ask staff.

**Selling:**

1. Click the **Sell** chest in the shop menu. The sell menu shows your coins, the Sell chest with the total, the shop's
   information, a book with how to sell, and Back.
2. **Click a stack in your own inventory** to add it to the sale (up to 7 stacks); it shows in the middle row with
   `Buy-back: <n> coins each` and `For these 20: <n> coins`. Click it in the menu to take it out again. **Your items
   stay in your inventory** until you sell.
3. A stack the shop won't buy is marked with the reason (for example `This shop doesn't buy items of that kind.`). The
   shop buys all of the sale or none of it: take the marked stacks out first.
4. **Click the Sell chest** (`Click here to sell`). The items leave your inventory, the chat says `You sold 2 item
   stacks for 60 coins. You now have 400 coins.`, and the menu closes. The shop's town pays you; a town that hasn't
   earned enough yet can't buy (`The town can't pay this much right now`).
5. If the sale is refused, every item is back in your inventory. If you moved a picked stack, you see `Your inventory
   changed; check the sale and click again.`

**No shopping during a siege:** `Shops are closed to you during a siege.` / `You can't sell to shops during a siege.`

What a shop refuses, and why:

| Message | Meaning |
|---|---|
| `You don't have enough coins. Nothing was charged.` (name tag: `You need <n> more`) | The total is more than you have |
| `Your inventory has no room for <n>. Make room, or send it to your reward inbox.` | Make room, or use the reward inbox button |
| `Your reward inbox is full.` | Claim what is in your inbox first |
| `This item is sold out.` / `The shop doesn't have that many in stock any more.` | Someone bought it first; pick a smaller amount or wait for restocking |
| `This item is no longer for sale here.` | The shop took it off its catalogue |
| `Unique items can't be bought in game yet; ask a staff member.` | See above |
| `This shop doesn't buy items from players.` | It has no Sell chest: its kind of shop buys nothing |
| `This shop doesn't buy items of that kind.` | The shop buys only some item categories (a bakery buys food) |
| `This item has no price, so the shop can't buy it.` / `This item isn't in the item catalogue.` | A renamed item, another plugin's item, or an item without a price |
| `Damaged items can't be sold to a shop ...` / `Enchanted items can't be sold as plain items ...` | Repair it first, or keep it: it would be resold repaired or lose its enchantments |
| `That is a display sample, not a real item.` | Display items are only a picture |
| `Soulbound items can't be sold.` / `That unique item is in a storage, not in your hands.` | Only items you carry and may give away can be sold |
| `The town can't pay that much right now.` | The town's account is low; sell less, or later |
| `The shop has no room for more of this.` | The shop's storage is full |
| `Selling to shops and buying into the reward inbox are switched off right now.` | Staff switched production off for now; buying into your inventory still works |
| `This shop belongs to no town, so it can't trade right now.` | Tell staff |
| `The shop's stock is busy right now. Try again in a moment.` | Another trade happened at the same moment |
| `The shop is still working out the price; click again in a moment.` | The price is still loading |
| `The shop didn't answer. If coins were taken, show staff this code: <code>` | Keep the code; staff can look it up |

Staff: setting shops up and testing them is in the [shops admin guide](../admin/shops-admin-guide.md#7-a-safe-test).

## Moving around in menus

- **Back / Exit:** the barrier at the top right. It says **Back** (to the menu you came from) or **Exit** (close).
  Escape always closes the menu.
- **Pages:** the arrows `Previous page` / `Next page` show `Page X/Y`. Shift-click an arrow to jump to the first page.
  While a page loads, the arrow turns into a clock.
- **Search:** click the sign. An anvil opens: type your search and click the paper on the right. Escape or the left
  item takes you back without searching; an empty search clears it. Shift-click the sign to clear the search.
- **Hints:** hold **sneak** while a menu is open to see what each click does (`Click: back`, `Shift-click: first page`,
  ...).
- Greyed-out items marked `(Unavailable)` can't be clicked. Some buttons ask `Click again to confirm!` first.
- Items in a menu are pictures: you can't take them out.

**Bedrock and console:** when one menu opens another, the first one closes and the next appears a moment later
(about a sixth of a second). That small pause is on purpose: without it, Bedrock closed the new menu straight away.

## When something doesn't work

| Message | Meaning |
|---|---|
| `Menus are unavailable right now.` / `That menu is unavailable right now.` | The game server can't reach the web server, or hasn't checked that menu since it started. Try again in a minute; teleports, leaderboards and sieges fall back to chat |
| `Couldn't load that page right now. Try again in a moment.` | The next page didn't load; you stay on the old one |
| `Your account isn't loaded yet - try again in a moment.` | Right after joining, your account is still loading |
| `You don't have permission to do that.` | Your rank can't use that button (for example buying premium kits) |
| `Something went wrong with that.` | The click failed; tell staff if it keeps happening |

## For staff

In a structure's menu, staff (`knk.admin.world`) get a bottom row: **Survey now**, **Transport dry run** (what the
automatic transport would do, in chat) and **Show area outline**; in its transport orders, click an order to cancel it
or to retry it (with Confirm and Cancel). Binding chests: `/knk storage bind` ([commands](commands.md), [storage terminals admin guide](../admin/production-storage-admin-guide.md)).

The **Player manager** tile (needs `knk.admin.user.manage`) manages players ranked below you: balances (staged until
you type a reason in chat), titles, groups, staff mode, salary, freeze, kick and ban. How menus are built and changed:
the [menu authoring admin guide](../admin/menus-admin-guide.md).
