# Statistics and Public Profile — Player Guide

**Status:** Living document — update in place as the game changes
**Last updated:** 2026-11-13 (§ Your data: link to what happens in game, PandiO/knk-workspace#184); 2026-11-11 (first version, PandiO/knk-workspace#302; checked against knk-plugin `main` `121030f`,
knk-web-api `master` `b5e57fa` and knk-web-app `main` `9a85238`)

Knights and Kings keeps statistics of how you play: playtime, kills, deaths, siege results, distance travelled,
discoveries, coins and more. You can look at your own, share them on a public profile and climb the leaderboards. You
decide which of them other players may see.

## Where to see them

| Where | What |
|---|---|
| `/stats` | Your own statistics in chat (all time) |
| `/stats <player>` | Another player's, as far as they let you see them |
| Main menu → your head → **Statistics** | The statistics menu, with periods and leaderboards |
| `/leaderboard` (`/lb`) | The leaderboards menu; `/lb <board> [weekly\|monthly\|lifetime]` for one board |
| `/siege history` | Your last 5 finished siege matches, each with a `[details]` link to the web app |
| Web app → **Leaderboards** (`/leaderboards`) | The top 25 per board, for this week, this month or all time |
| Web app → `/players/<name>` | A player's **public profile**: their statistics, title history and siege matches |
| Web app → **Account** → **Statistics** | Everything about yourself, links to your public profile, and your privacy settings (only once your account is linked to Minecraft) |

The web pages can be opened without signing in; what a visitor sees depends on who they are (see below).

## What is counted

Statistics are kept per period (today, this week, this month, all time; weeks start on Monday) and, for combat and
minigames, separately for the **open world** and **siege** matches.

| Group | Statistics |
|---|---|
| Activity | Active playtime, AFK time, logins |
| Combat | Player kills, creature kills, deaths, damage dealt and received (to/from players and creatures), arrows fired, headshots, highest killstreak |
| Minigames | Wins, losses, draws, objectives captured, gate-door damage |
| Exploration | Distance on foot, flying and in a vehicle, highest survived fall, discoveries |
| Progression | XP gained, coins and gems earned and spent, title history |

How some of them are counted:

- **AFK:** after 5 minutes without doing anything, or with `/afk`, you are AFK (`[AFK]` in the tab list). AFK time
  doesn't count as active playtime, and distance isn't counted while you are AFK.
- **Creative and spectator mode** count playtime only.
- **Kills:** creatures from spawners, spawn eggs or breeding don't count. Kills in a siege match come from the match
  result. On the leaderboards, at most 3 kills of the same player per day count (your own statistics count them all).
- **Killstreak:** player kills without dying in between; any death or leaving the server ends it. Only your highest
  streak is kept.
- **Siege results:** a win, loss or draw for the team you were on at the end; leaving a match early counts as a loss.
- **Distance:** teleports and world changes don't count. Swimming counts as on foot.
- **Highest fall:** only a fall that hurt you and that you survived.
- **Gate-door damage:** the health you took off gates, also by arrows, TNT or fire you started.

## Who sees what

Some things are **always public**: your title, experience (XP), coins and gems balances, active playtime, AFK time and
when you first joined. Everything else is **hidden until you choose otherwise**.

For each statistic you choose **Nobody**, **Friends** or **Everyone**:

- **Nobody** (the default): only you (and staff) see it.
- **Everyone** means every **signed-in** player. Only then do you appear on that statistic's leaderboard. Visitors
  who aren't signed in never see more than the always-public things.
- **Friends** can already be chosen but shows nothing yet: there is no friends system yet.

Many combat and minigame statistics can also be set **per game**, for example player kills visible for sieges only.

**Where to change it:**

- Web app → **Account** → **Statistics** → **Who may see my statistics**: a dropdown per statistic, per-game settings,
  and group buttons such as **Set all listed to Everyone** (with a confirmation).
- In game: `/stats settings`, or main menu → your head → **Statistics privacy**. Click a row to change it.
  Per-game settings can only be changed on the web.

**Chat tokens:** `#kills`, `#stats` and the other chat tokens show what other signed-in players may see. If you share
a statistic of your own that is private, the server asks first: **Make public & send**, **Send without** or **Never
ask** (see the [chat tokens guide](../chat-tokens.md)).

## Leaderboards

The boards are active playtime, XP gained, player kills, creature kills, siege wins, objectives captured, gate-door
damage, distance on foot / flying / in a vehicle, discoveries and highest killstreak (several also per open world or
siege). They are updated every few minutes. Playtime and XP rank everyone; every other board only ranks players who
show that statistic to **Everyone**. Equal values share a rank, and whoever reached it first is listed first. Weekly
boards start again every Monday, monthly boards every month. A signed-out visitor sees only the playtime and XP boards
(`Sign in to see this leaderboard.`).

## The siege match page

Every finished siege match has its own page (`/siege/matches/<number>`), linked from `/siege history`, your public
profile and the result message at the end of a match. It shows the result, why the match ended, the objectives and,
per team, each player's kills, deaths, best streak, captures, gate damage, active time and rewards. Numbers a player
keeps private show as `Hidden`.

## Your data

You can ask for your data to be deleted on the web app's **Account** page (**Delete my data…**), confirmed by email,
with a few days to change your mind. What is deleted, and what happens if you are online when it runs, is in the
[account guide](PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md#can-i-delete-my-account).

## Messages

| Message | Meaning |
|---|---|
| `<name> keeps their other statistics private.` | You see only what is always public for that player |
| `You're not ranked here (only players who show this statistic to everyone rank).` | Set the statistic to Everyone to appear on that board |
| `Not computed yet - check back in a few minutes.` | The board hasn't been worked out yet |
| `Your account isn't loaded yet - try again in a moment.` | Right after joining |
| `No player found named '<name>'.` | Check the spelling |
