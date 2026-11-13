# Menus — Player Guide

**Status:** Living document — update in place as the game changes
**Last updated:** 2026-11-13 (§ Kits: kits a staff member gives you from the web app, PandiO/knk-workspace#261, in
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
| **Player manager** | Staff only |
| **Exit** (top right) | Closes the menu |

### Kits

Each kit shows what is in it, its cost and whether you can claim it now: `Click to claim`, `Available again in 4m 10s`
(counting down), or a red reason. A **premium kit** is bought once with gems: click it, then **Confirm** (or
**Cancel**) — the chat asks `Buy the kit "<name>" for N gems? Click Confirm or Cancel.` After buying you claim it like
any other kit. Claimed items go into your inventory; what doesn't fit is **dropped at your feet**. (When that happens you may see a technical line like `placed=… dropped=…` in chat; it will be replaced by a readable message, [#321](https://github.com/PandiO/knk-workspace/issues/321).)

**Kits a staff member gives you.** Staff can give you a kit from the web app as well as in game. You don't need to do
anything to receive it, and it doesn't cost you anything:

- **Online:** the items arrive within a few seconds, with the chat line `A staff member gave you the "<kit>" kit.`
- **Offline:** they arrive a few seconds after your next join, one chat line per kit, in the order they were given.
- **In a siege** (lobby or match): nothing arrives while you play, because your siege inventory is replaced when the
  siege ends. The kit arrives right after the siege has given your own inventory back.

The items go into your inventory the same way as a claimed kit; if something doesn't fit, you also see `Some of it
didn't fit and was dropped at your feet.` A kit is handed over once, never twice. A kit staff give you starts that
kit's waiting time for your own claim, as if you had claimed it. (Since PandiO/knk-workspace#261; part of the next
release, not live yet. Kits given from the web app before that release don't arrive by themselves: ask staff to give
them again.)

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

The **Player manager** tile (needs `knk.admin.user.manage`) manages players ranked below you: balances (staged until
you type a reason in chat), titles, groups, staff mode, salary, freeze, kick and ban. How menus are built and changed:
the [menu authoring admin guide](../admin/menus-admin-guide.md).
