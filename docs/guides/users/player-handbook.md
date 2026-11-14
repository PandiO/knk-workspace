# Knights and Kings — Player Handbook

**Status:** Current · **Last updated:** 2026-11-14 (Your account: link to the account player guide, PandiO/knk-workspace#299)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `f445d21`, knk-web-app `main` `3ba747d`
**Related:** [commands reference](commands.md), [menus](menus-player-guide.md), [guides index](../README.md)

Welcome to Knights and Kings, a medieval Minecraft world of towns, castles and sieges. This handbook gets you from
your invitation to your first siege. Each part of the game has a short summary here and a link to its own guide when
you want the details.

The game is in a **closed alpha**: you need an invitation, things change often and some features are still missing.
Everything described here is in the released game unless it says otherwise.

## Contents

1. [Getting started](#getting-started)
2. [The hub](#the-hub)
3. [The menu](#the-menu)
4. [Your account](#your-account)
5. [Getting around](#getting-around)
6. [Discoveries](#discoveries)
7. [Money, kits and lootboxes](#money-kits-and-lootboxes)
8. [Ranks and chat](#ranks-and-chat)
9. [Statistics and leaderboards](#statistics-and-leaderboards)
10. [Custom enchantments](#custom-enchantments)
11. [Gates](#gates)
12. [Siege](#siege)
13. [Building and protection](#building-and-protection)
14. [Getting help](#getting-help)

## Getting started

You need three things: an **invitation**, an **account on the website** and **Minecraft Java Edition 26.3**. The
website also mentions Bedrock: whether Bedrock players can join depends on the server's crossplay setup, so ask the
person who invited you.

### 1. Sign up with your invitation

Staff invite you in one of two ways:

1. **A personal invitation email.** Open its link. The page **Accept your invitation** has your email address filled
   in; choose a password and accept the alpha rules.
2. **A shared invitation code** (`KNK-XXXXX-XXXXX`) posted for your group. Go to the website's `/join` page
   (**Join the closed alpha**), type the code into **Invitation code** (the dashes are added for you), then choose your
   email and password.

Both pages show **What happens next**, the same steps as below.

### 2. Sign in through Cloudflare (if asked)

The closed alpha's website is protected by Cloudflare. After signing up you may see Cloudflare's page asking for your
email. Type the **same address** you signed up with. Cloudflare (not Knights and Kings) emails you a **6-digit code**;
check your spam folder. Enter it and this device stays signed in for 30 days.

### 3. Join the server and link your Minecraft account

1. In Minecraft, add the server `play.knightsandkings.net` and join it.
2. The first time, the server turns you away with a screen like: *"Knights & Kings is invite-only. Go to …/link and
   enter `K7QH-M2XA` (valid 15 minutes)."*
3. On the website's **Link your Minecraft account** page, enter that code. Your Minecraft name now shows on your
   account.
4. Join again. You're in, with a welcome message and your starter kits. The chat says which web account (for example
   `st***@gmail.com`) your Minecraft account is linked to. If that isn't you, tell staff right away.

Joined the server before you signed up? That works too: note the code from the screen, open **/link**, and the site
keeps the code while you sign up with your invitation.

**Never give a code to anyone. Staff never ask for your codes or your password.**

### Played here before the invitations?

Your Minecraft account was carried over and you join without a code. To get a web login, type `/account link` in
game. It gives you an 8-character code (valid 20 minutes). On the website open **Register**, click **Already playing
and got a code from /account link?**, and enter the code with your email and a password. If you already have a web
login, enter the code under **Link Minecraft Account** on your **Account** page instead. Codes only go from the game
to the website, never the other way.

## The hub

When you join you normally arrive in the **hub**, a separate, peaceful area. In the hub:

1. You can't fight or take damage, and you usually heal and get fed over time.
2. You can't build or break blocks, or open chests and other storage. Doors, dropping and picking up items and your
   own inventory work as normal.
3. You walk into a **portal** to enter the game world. You arrive at your rank's join spot, or the server's default
   one. A portal works only when the game services are up and your account has loaded; if not, it tells you to wait.

`/hub` takes you back to the hub from the game world, with the same warmup as `/spawn` (see
[Getting around](#getting-around)).

If the game's services go down while you play, you may be moved to the hub (the server's setting decides) and kept
there until they are back. You then get a clickable offer to return to where you were (`/hub return`); nothing moves you back without you clicking.
If you were in a siege match, that match is stopped.

## The menu

Most things have a menu. When you join and when you respawn you get a **nether star called `Menu (click to open)`**
in the right-most hotbar slot: click it, or type `/menu`. You can't drop it and you keep it when you die. With a
completely full inventory you only get the star once there is room (rejoin or respawn); `/menu` always works. The
main menu has a tile for your profile (your head), kits, sieges, the item catalogue, premium tiers, discoveries and
teleports.

Full guide: [Menus](menus-player-guide.md). Every command: [commands reference](commands.md).

## Your account

Your account joins your Minecraft player and your web login. In game, `/account` (`/acc`) shows your username, email,
coins, gems and experience. On the website, the **Account** page shows the same, plus your transaction history and,
once your Minecraft account is linked, your discoveries and statistics, and lets you change your email and password, link your Minecraft account and log out on
all devices. Forgot your password? Use **Forgot password** on the **Log in** page.

<!-- Guide link (PandiO/knk-workspace#299): add the account player guide link on the next line. -->
> **Full guide:** [Your account: invitation, linking, login and password](account-player-guide.md).

## Getting around

1. `/spawn` takes you to spawn; `/hub` to the hub.
2. `/warp` (or the **Teleport to points on the map** tile) opens the teleport menu; `/warp <place>` teleports you to a
   town, district or structure. Some places need a title, a premium tier or that you discovered them first, and some
   cost gems.
3. `/tpa <player>` asks to teleport to another player; they click **[Accept]** or **[Deny]**.
4. `/navigate <place>` shows a particle trail and a boss bar along the roads. It doesn't teleport you; you walk.
   `/navigate stop` ends it.

By default, teleports have a **warmup** (5 seconds: don't move or take damage), a **cooldown** (30 seconds between teleports of
the same kind) and are blocked for 10 seconds after a PvP hit and during a siege. Your rank can shorten these.

<!-- Guide link (PandiO/knk-workspace#298): add the navigation and teleports player guide link on the next line. -->
> **Full guide:** [navigation and teleports player guide](navigation-and-teleports-player-guide.md).

## Discoveries

Walk into a town, district or structure for the first time and you **discover** it, which can earn you coins and XP. Some
warps only open once you have discovered the place. See yours with `/discoveries` (`/disc`), the **Discoveries** tile
in the menu, or your **Account** page on the website. For your first 10 minutes on the server, discoveries are
announced together in one summary afterwards; you get the rewards straight away.

## Money, kits and lootboxes

1. **Coins** are the everyday money; **gems** are the premium currency. `/balance` (`/bal`) shows both. `/pay
   <player> <amount>` sends coins (gems can't be sent), `/baltop` shows the richest players, and `/transactions`
   (`/tx`) your history.
2. **Kits** are bundles of items. `/kit list` shows them, `/kit get <name>` claims one (each kit has its own rules,
   such as a cooldown, a cost or a rank), and `/kit purchase <name>` buys a premium kit once with gems. New players
   get starter kits on their first join. The **Kits** tile in the menu does the same with clicks.
3. **Lootboxes** appear in the world: right-click one to open it. `/lootbox odds <category>` shows what a box can
   give. There may be a daily limit, which resets at 00:00 UTC.

<!-- Guide link (PandiO/knk-workspace#300): add the economy player guide link on the next line. -->
> **Full guide:** coming soon (currency, kits, lootboxes and discoveries). Until then, see
> [commands reference § Money](commands.md#money).

## Ranks and chat

1. **Titles** come from experience (XP), which you earn by playing. Some kits, warps and sieges need a certain title. Your title and the
   progress to the next one are in your profile (your head in the menu) and in `/stats`.
2. **Ranks** decide which commands you can use. Everyone starts with the default rank. The **premium tiers** (Noble,
   Royal and Dragon Blood) add perks. On the closed alpha these include
   `/siege skip` (Noble) and `/tpahere` and `/back` (Dragon Blood). The **Premium tiers** tile shows them. Staff ranks are Staff, Moderator and Admin.
3. **Private messages:** `/msg <player> <message>`, `/reply` (`/r`) to answer, `/ignore <player>` to stop seeing
   someone. Moderators can read private messages.
4. **Chat tokens:** type `#hand`, `#stats` or `#kills` in chat to show your held item or a statistic; others hover
   over it for the details. If a token would show a statistic you keep private, you're asked first. See [chat tokens](../chat-tokens.md).
5. `/afk` marks you away. You also go AFK after 5 minutes idle (if the server has AFK on).

<!-- Guide link (PandiO/knk-workspace#301): add the ranks and chat player guide link on the next line. -->
> **Full guide:** coming soon (ranks and chat). Until then, see
> [commands reference § Chat and private messages](commands.md#chat-and-private-messages).

## Statistics and leaderboards

The game counts how you play: playtime, kills, deaths, siege results, distance, discoveries and more. `/stats` shows
yours; `/leaderboard` (`/lb`) opens the leaderboards. On the website, **Leaderboards** shows the top players and
`/players/<name>` a player's public profile. You decide who sees each statistic (Nobody, Friends or Everyone) with
`/stats settings` or on your **Account** page. There is no friends list yet, so Friends shows a statistic to nobody
for now.

Full guide: [Statistics and public profile](statistics-player-guide.md).

## Custom enchantments

Besides the vanilla ones, Knights and Kings has its own enchantments: some trigger when you hit, others are abilities
you use with a right-click. You get them from enchantment books, kits and lootboxes. `/ce info` lists the custom
enchantments on the item in your hand with their current values. The website's **Guides** page shows the live numbers.

Full guide: [Custom enchantments](custom-enchantments-player-guide.md).

## Gates

Castles and towns have gates that open and close with an animation. You can pass a closed gate you're allowed
through by right-clicking it; `/gate passthrough` sets how. In a siege, gates can be damaged, set on fire and
destroyed. `/gate list` and `/gate info` show the gates and their state.

Full guide: [Gate structures](gate-structures-player-guide.md).

## Siege

Sieges are team matches: attackers try to take a castle's objectives, defenders try to hold them. Type `/siege` or
click the **Siege Minigame** tile to see the lobbies, and click one or type `/siege join <lobby>` to join it (the
name can be left out when only one lobby is open). In the lobby you can vote for the
next scenario with `/siege vote` and choose where you start with `/siege spawn`. Sieges that use it give you a navigation
compass that points the way to the objectives. During a match only `/siege`, `/siegemenu`, `/navigate` and the commands the
siege allows work; `/siege leave` leaves it (you
get your items and position back, but no rewards). After a match, `/siege history` shows your results with a link to
the match page on the website.

<!-- Guide link (PandiO/knk-workspace#297): add the Siege player guide link on the next line. -->
> **Full guide:** [Siege player guide](siege-player-guide.md): joining, teams, objectives, gates, rewards and match history.

## Building and protection

Most of the world is protected. Outside towns and other areas you can't break or place blocks, or use crafting
blocks; doors, gates, chests and other storage still work. Inside a town, district or structure its own rules apply.
Inside towns and other areas you also take no damage from fire, lava, poison and similar effects, except where PvP is
allowed there.

## Getting help

1. **Ask staff in game.** Staff can be hidden while they work and then show as offline, so if `/msg` can't find
   anyone, ask in public chat.
2. **Read the guides.** The website's **Guides** page and the guides linked above. The
   [commands reference](commands.md) explains every command and what its refusals mean.
3. **Something went wrong?** Tell staff what you did, what you expected and what happened instead. Messages like
   "the KnK service is unreachable" mean the game's services are briefly down; wait a moment and try again.
4. **Stay safe.** Never share your password or a code from the server or `/account link`. Staff never ask for them.

## Changes

1. 2026-11-14: Siege: link to the Siege player guide (PandiO/knk-workspace#297)
2. 2026-11-14: Getting around: link to the navigation and teleports player guide (PandiO/knk-workspace#298)
3. 2026-11-13: first version, replaces the archived Dutch v1 manual (PandiO/knk-workspace#296)
