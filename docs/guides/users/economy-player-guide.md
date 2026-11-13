# Coins, gems, kits, lootboxes and discoveries — Player Guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#300)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d` (desk
check of the code, not a live test). Amounts are the seed defaults; staff can change them.
**Related:** [player handbook](player-handbook.md), [commands reference](commands.md), [menus guide](menus-player-guide.md),
[statistics guide](statistics-player-guide.md), [economy admin guide](../admin/economy-admin-guide.md)

This guide explains the money of Knights and Kings (coins and gems), how you earn and spend it, and three things that
hand out items or rewards: **kits**, **lootboxes** and **discoveries**. For each one you find how to get it, what it
costs, how often you can do it, what goes wrong, and what other players see.

## Contents

1. [Coins and gems](#1-coins-and-gems)
2. [Paying another player: `/pay`](#2-paying-another-player-pay)
3. [Your balance and history](#3-your-balance-and-history)
4. [Kits](#4-kits)
5. [Lootboxes](#5-lootboxes)
6. [Discoveries](#6-discoveries)
7. [When something doesn't work](#7-when-something-doesnt-work)

## 1. Coins and gems

| | Coins | Gems |
|---|---|---|
| What they are | The everyday money | The premium currency |
| You start with | 250 | 50 |
| Can you send them to a player? | Yes, with `/pay` | No |
| Most you can hold | 999,999,999 | 999,999 |

You also have **experience (XP)**. XP isn't money: it decides your **title** (Serf, Peasant, and so on up), and your
title decides your salary.

**How you earn coins and gems:**

1. **Salary** (coins). Every title has a salary per hour. You are paid when you join and then every hour you stay
   online. Time you were offline also pays a little: the first hour away pays a full hour, the second half an hour,
   the third a third, and so on (at most 30 days are counted). The chat shows a line like
   `Salary (Peasant): … = +N coins`. A premium tier or your rank can multiply it.
2. **Title bonuses** (coins and gems), once, the first time you reach each title.
3. **Discoveries** (coins, gems and XP), the first time you enter a town, district, structure or gate. See
   [§ 6](#6-discoveries).
4. **Sieges** (coins, and gems for a win). See the [Siege guide](siege-player-guide.md).
5. **Other players**, with `/pay` (coins only).
6. **Staff**, for events or as compensation. The chat says `Granted by <staff> … – <reason>`.

**How you spend them:**

1. **Kits** that have a price per claim (coins or gems), and **premium kits**, bought once with gems ([§ 4](#4-kits)).
2. **Teleports**: a destination can cost gems, and `/tpa` and `/back` can cost coins when the server sets a price.
   See the [commands reference § Travel](commands.md#travel-and-teleporting).

There is no shop and no selling of items yet. Lootboxes cost nothing and give items, not money.

## 2. Paying another player: `/pay`

```
/pay <player> <amount>
/pay <player> <amount> coins
```

The amount is a whole number without separators or decimals (`/pay Steve 500`, not `500.00` or `1,000`). The other
player may be offline. When the payment goes through you see
`Sent 500 coins to Steve. Balance: 1,234` and Steve sees `You received 500 coins from <you>.` (If Steve is offline, they
see that line when they next join. A server restart in between can lose that message, but never the payment:
[#461](https://github.com/PandiO/knk-workspace/issues/461).)

**Large payments ask first.** From 100,000 coins the chat asks
`Send 100,000 coins to Steve? [Confirm] [Cancel] (expires in 60s)`. Click **[Confirm]** or **[Cancel]**, or type
`/pay confirm` or `/pay cancel`. A new `/pay` cancels a question that is still open.

**The limits** (unless staff changed them):

| Rule | Coins |
|---|---|
| Smallest payment | 10 |
| Largest payment | 1,000,000 |
| Sent per 24 hours | 2,000,000 |
| Received per 24 hours (by the other player) | 4,000,000 |
| Time between two payments | 5 seconds |
| Payments per hour | 20 |
| Before you can send at all | your account is 48 hours old and you have the title **Peasant** (2,500 XP) |
| Fee | none |

**Gems** can't be sent: `/pay Steve 5 gems` answers `Gems can't be transferred.`

**When a payment is refused**, the message says why. The common ones:

| Message | What it means |
|---|---|
| `You only have N coins.` | Not enough coins. |
| `Send between 10 and 1,000,000 coins at a time.` | The amount is outside the limits. |
| `Daily limit reached - you can send N more coins (resets in …).` | You hit the 24-hour send limit. |
| `Steve can't receive that much more coins today.` | Steve hit the 24-hour receive limit. |
| `Slow down - you can pay again in …` | You paid too quickly, or 20 times this hour. |
| `Your account must be 48h old and reach Peasant before sending coins.` | Your account is too new, or your title too low. |
| `Coin transfers are switched off right now.` | Staff switched payments off for a while. |
| `Your account can't send payments right now.` / `Steve can't receive payments right now.` | A payment lock by staff. |
| `You can't pay yourself.` / `No player found named Steve.` | As it says. |
| `That payment request expired - send it again.` | You confirmed after 60 seconds. |
| `We couldn't confirm the payment. Check /transactions before trying again.` | The server didn't answer in time. Check `/transactions`: the payment may have gone through. Don't pay twice. |

## 3. Your balance and history

| Where | What you see |
|---|---|
| `/balance` (`/bal`, `/money`) | `Balance: 1,234 coins \| 56 gems` |
| `/balance Steve` | Steve's coins and gems |
| `/baltop [coins\|gems] [page]` | The richest players, 10 a page |
| `/transactions [coins\|gems\|xp] [page]` (`/tx`) | Your history, newest first: when, the change, what it was ("to Steve", "Salary", "Claimed kit …"), and the balance after |
| When you join | Your balance line |
| The menu, **your head** tile | Coins, gems, XP and your title progress |
| `#balance` in chat | Shows `[N coins]`, with coins and gems on hover. `#balance@Steve` shows Steve's. |
| The web app, **Account** | Coins and gems, and **View transaction history** (`/account/transactions`: show Everything, Coins, Gems or XP) |
| The web app, a player's public profile | Their coins and gems |

**Who can see your balance:** everyone. `/balance <player>`, `#balance@<player>` and the public profile show coins and
gems whatever your statistics privacy settings are
([#322](https://github.com/PandiO/knk-workspace/issues/322)). Your transaction history is only yours (and staff's).

## 4. Kits

A kit is a set of items: armour, a weapon and some extra items. Some are free, some cost coins or gems each time, and
**premium kits** are bought once with gems and then claimed for free.

**Getting a kit:**

1. **In the menu:** open the menu (the nether star, or `/menu`) and click **Kits**. Click a kit to claim it.
2. **By command:** `/kit list` shows every kit with `available` or the reason you can't claim it, and its cost.
   `/kit get <name>` claims one (the name is not case-sensitive and may contain spaces).
3. **Your first join:** new players get the starter kits (`You received your starter kit!`) once.

**The kit tooltip** (hover a kit in the Kits menu) shows, top to bottom:

1. the kit's description;
2. `Contents:` with the armour and hand items (`- Helmet: Iron Helmet`, … `- Hand: Iron Sword`, `- Shield: …`);
3. `Other contents:` with the other items, wrapped over at most 6 lines; if there are more, the last line says
   `… and N more` (since alpha run 1, [#172](https://github.com/PandiO/knk-workspace/issues/172));
4. `Cost: N coins` (or gems) when the kit has a price per claim;
5. what you can do: `Click to claim`, or for an unbought premium kit `One-time price: N gems` and
   `Click to buy this kit`, or in red why you can't (for example `Requires the 'Knight' title or higher.`);
6. while the kit is on cooldown, a red line that counts down: `Available again in 4m 10s`.

A kit you can't claim is greyed out. Every kit is shown, also the ones your rank can't claim yet.

**Rules a kit can have:**

| Rule | What happens |
|---|---|
| A minimum title | `Requires the 'Knight' title or higher.` |
| A rank (permission group) | `Requires membership in the 'Archers' permission group.` |
| A permission | `Requires the 'knk.kit.archer' permission.` |
| A cooldown | After a claim you wait. The chat shows `Kit is on cooldown until <date and time>` (a long technical date for now, [#455](https://github.com/PandiO/knk-workspace/issues/455)); the menu shows the countdown. A kit staff gave you, and your starter kit, also start the cooldown. |
| A price per claim | Paid each claim, in coins or gems: `Insufficient Coins to claim this kit.` if you can't. |

**Premium kits:** click the kit in the menu; the chat asks `Buy the kit "<name>" for N gems? Click Confirm or Cancel.`
Click **Confirm** in the menu (or **Cancel**). By command: `/kit purchase <name>` (`/kit buy`), then
`Purchased "<name>" for N gems. Use /kit get <name> to claim it.` After buying, claiming that kit has no cooldown and
no cost. Check you meet the kit's title and rank rules **before** you buy: the purchase doesn't check them yet, and
the menu offers the buy line even when you can't claim the kit
([#454](https://github.com/PandiO/knk-workspace/issues/454)).

**Where the items go:** armour into the armour slots, the hand item into the slot you hold, the rest into your
inventory, topping up stacks first. What doesn't fit is **dropped at your feet**, so make room before you claim. When
that happens you may see a technical line `placed=… dropped=…`
([#321](https://github.com/PandiO/knk-workspace/issues/321)).

**What others see:** nothing; claims aren't announced. A kit a staff member gives you says
`You received the "<name>" kit.` Kit prices and purchases show in your `/transactions`.

A kit staff grant you from the web app (the **Grant** button on your profile) is not placed in your inventory on the
released version ([#261](https://github.com/PandiO/knk-workspace/issues/261)). In `next`, not yet released: such a
kit is handed over when you are online, or when you next join (after a siege if you are in one).

## 5. Lootboxes

Lootboxes are glowing, slowly turning boxes with a coloured label, such as `Rare Swords Lootbox ★★★`, that appear now and
then in certain areas of the world. Each box has a **grade** of ★1 to ★10; a higher grade gives better items. Nearby
you see gold particles and hear a soft sound every few seconds.

**Getting one: two steps.**

1. **Pick it up.** Click the box (right or left click) within 5 blocks, with a free inventory slot. It becomes a
   **lootbox token** in your inventory: `You picked up a Rare Swords Lootbox ★★★! Right-click it to open.` The first player to
   click it gets it. You don't have to open it now.
2. **Open it.** Hold the token and right-click. A chest window opens with a spinning reel that slows down and stops on
   your item; it goes into your inventory (`You opened a Rare Swords Lootbox ★★★ and found [Golemheart Sword]!`). Close the
   window early and you get the item at once. If you leave during the spin, you get it when you next join.

A lootbox costs nothing and has no key or cooldown. It gives **items only** (weapons, armour, books and so on; better
items can have custom enchantments), never coins or gems. A box can also hold a rare **special** item.

(`/lootbox` itself still says "right-click one to open it"; the click picks it up as above,
[#458](https://github.com/PandiO/knk-workspace/issues/458).)

**Tokens from elsewhere:** joining a premium tier or getting a kit can also give you tokens
(`You received N lootbox(es) - right-click to open.`), and staff can give you tokens or open a box for you. Tokens
can be traded and given to other players like any item. A token can't be placed or used for crafting.

**How many a day:** unless staff changed it, you can **pick up** 10 boxes and **open** 10 tokens per day; both reset
at 00:00 UTC (`You've opened 10 lootboxes today — the limit resets at 00:00 UTC.`). Tokens from tiers, kits and
staff count towards the opening limit. Some box types have their own lower limit.

**What a box can give:** `/lootbox odds <category> [stars]` lists the items and chances for a box type, for example
`/lootbox odds Swords 3`. `/lootbox` lists the categories.

**When you can't:**

| Message | What it means |
|---|---|
| `Your inventory is full — make room to open this lootbox.` | You need a free slot (opening the last token of a stack frees its own slot). |
| `Get closer to open this lootbox.` / `You can't reach this lootbox from there.` | More than 5 blocks away, or no line of sight. |
| `You can't open lootboxes during a siege - open it once the siege is over.` | Not during a siege. |
| `Someone else got there first.` / `This lootbox has crumbled away.` | Another player took it, or it expired (a box stays 30 minutes by default). |
| `Lootboxes are switched off right now.` | Staff switched lootboxes off; your tokens keep until they are on again. |
| `You can't open lootboxes in staff or owner mode.` | Leave staff mode first. |
| `This lootbox was revoked by staff - it crumbles away.` | Staff withdrew that token. |

**Sieges:** no boxes appear in a running siege, and you can't pick up or open one while you play. If your reel ends
just as you enter a siege, the item is kept: `Your lootbox item is kept safe - you get it as soon as the siege is
over.`

**Protected areas:** you can pick up a box inside a town or other protected area even if you aren't a member there.

**What others see:**

1. Players nearby see particles and hear sounds when you open a token; a very good drop gets fireworks.
2. A good drop is announced to everyone: `Steve found [Golemheart Sword] in a Legendary Swords Lootbox ★★★★★!` (by default for
   items of ★5 and better, and always for a special). Hover the item name to see it.
3. A high-grade box appearing can be announced too: `A Mythic Swords Lootbox ★★★★★★ appeared in Market Square!` (by
   default from ★6; most box types only go up to ★5).

## 6. Discoveries

The first time you enter a **town**, **district**, **structure** or **gate**, you discover it and get a one-time
reward of XP, coins and (for towns and districts) gems.

**What you see:** a sound and particles (a firework for a town), then one chat line per place:
`You discovered the district Market in Oakvale!` followed by the reward lines, for example
`  Reward: 650 ×1.2 Royal = +780 coins` and `  Reward: +12 XP`. Entering a structure for the first time can also
discover the district and town around it, each with its own reward.

**How big the reward is:** it depends on the kind of place and on your title, because the coins are a number of hours
of your salary. Default ranges:

| Place | XP | Coins (hours of your salary) | Gems |
|---|---|---|---|
| Town | 1 to 4 % of a title step | 2 to 8 hours | 5 to 15 |
| District | 0.5 to 2 % | 0.5 to 2 hours | 1 to 3 |
| Structure, gate | 0.05 to 0.25 % | 0.05 to 0.25 hours | none |

Your premium tier and rank multipliers apply on top. Staff can give single places other rewards.

**When it doesn't count:** in creative or spectator mode, in staff mode, while frozen, while you are in a siege lobby
or match, and while your account is still loading. Walk into the place again later. Each place pays only once per
account.

**New players:** in your first 10 minutes on the server the discovery messages are held back (the rewards are paid at
once). Afterwards one line sums them up: `While settling in you discovered 4 place(s). See them all with
/discoveries.`

**If the server is busy:** discoveries made while the game server can't reach the web server are saved and paid later;
the chat then says `While the server was busy you discovered N place(s):` with the totals.

**Seeing your discoveries:**

1. `/discoveries` (`/disc`), or the **Discoveries** tile in the menu: your counts per type (`Towns: 3/5`), what you
   earned, your latest discovery, and a list of places. Discovered places show their name, where they are, the date
   and the reward. Undiscovered towns show their name; smaller places show `???` and `Somewhere in <town>`. The
   **Type** and **Show** buttons filter the list.
2. The web app, **Account → Discoveries** (when your Minecraft account is linked): a progress bar per type, your total
   rewards and your last 10 places.
3. Some warps can only be used once you discovered the place ([commands reference § Travel](commands.md#travel-and-teleporting)).

**What others see:** discoveries are not announced. `#discoveries` in chat shows `[N discoveries]`. Your counts appear
on your public profile and the discoveries leaderboard only as far as your statistics privacy settings allow (default
**Nobody**); see the [statistics guide](statistics-player-guide.md).

## 7. When something doesn't work

| Problem | What to do |
|---|---|
| `Your account isn't loaded yet - try again in a moment.` | Wait a few seconds after joining. |
| `You don't have permission to do that.` on a kit command | Your rank can't use that command; ask staff. |
| `The economy service can't be reached right now — try again in a moment. Nothing was paid.` | The web server is down; nothing happened. |
| A kit dropped items on the ground | Your inventory was full; pick them up. |
| A payment's result is unclear | Check `/transactions` before paying again. |
| Your balance looks wrong | Check `/transactions`, then ask staff with the date and amount. |

Staff can look up your history, correct a balance and reverse a payment; see the
[economy admin guide](../admin/economy-admin-guide.md).
