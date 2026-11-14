# Siege — Player Guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, written from the default branches, PandiO/knk-workspace#297)
**Checked against:** knk-plugin `main` `57884e97`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d`
**Related:** [player handbook](player-handbook.md), [commands reference § Sieges](commands.md#sieges),
[menus](menus-player-guide.md), [statistics and match pages](statistics-player-guide.md),
[gate structures](gate-structures-player-guide.md), [custom enchantments](custom-enchantments-player-guide.md),
admin side: [authoring a siege scenario](../authoring-a-siege-scenario.md)

A siege is a team match in a town or castle. Players are split into teams, usually **attackers** and **defenders**.
The attackers try to take the objectives, the defenders try to hold them until the time runs out. You fight with your
own gear, and after the match you get it back exactly as it was, plus your rewards.

Everything here is in the released game (the default branches) unless it says otherwise. Staff can change most
numbers per scenario or in the siege settings, so the numbers below are the starting values.

## Contents

1. [Joining a siege](#joining-a-siege)
2. [Before the match: hub, teams and spawn](#before-the-match-hub-teams-and-spawn)
3. [Objectives and winning](#objectives-and-winning)
4. [Fighting](#fighting)
5. [Gates](#gates)
6. [The navigation compass](#the-navigation-compass)
7. [Your gear, kits and enchantments](#your-gear-kits-and-enchantments)
8. [What you can't do during a siege](#what-you-cant-do-during-a-siege)
9. [Leaving and coming back](#leaving-and-coming-back)
10. [The end of the match](#the-end-of-the-match)
11. [Rewards](#rewards)
12. [Match history](#match-history)
13. [Messages and what they mean](#messages-and-what-they-mean)
14. [Coming / not yet released](#coming--not-yet-released)

## Joining a siege

Anyone with a player account can play (`knk.siege.play`, which every player has).

**Find a lobby.** A *lobby* runs one siege after another. Open the main menu and click **Siege Minigame**, or type
`/siege`. The **Siege** menu lists every lobby with its scenario, players, stage and timer. Click a lobby to open its
**Siege information** menu and join from there, or type `/siege join <lobby>` (leave the name out when only one lobby
can be joined). `/siege info [lobby]` gives the same overview in chat.

**When you can join.** Only while the lobby is in **Matchmaking**. When matchmaking starts, everyone online gets
"Matchmaking for &lt;lobby&gt; has started!" with the scenarios to vote between and a clickable join command, and reminders
follow at 4 min 50 s, 60, 30 and 15 seconds before the start. After joining you see
`You joined <lobby> (n/max). The siege begins in …`.

**Voting.** Each round offers a few scenarios (maps). Vote in the information menu or with `/siege vote`: without a
choice it lists them as clickable lines; `/siege vote 2`, `/siege vote <name>` or `/siege vote random` vote. Voting for
your current choice again withdraws your vote. Voting closes 30 seconds before the start, and 25 seconds before the
start the scenario is drawn: most votes win, ties are broken at random, and if **Random** has more votes than any
scenario a scenario that wasn't on the list is picked.

**Requirements.** A scenario can need a minimum title, and it has a maximum number of players. Before the draw the
largest maximum of the candidates counts. At the draw, players below the drawn scenario's title, or the last to join
once it is full, are taken out of the round with a message. If too few players are left for the drawn scenario, the
round is called off and the lobby waits for the next one.

**Skipping the wait.** `/siege skip [lobby]` ends a lobby's cooldown so matchmaking starts, or cuts matchmaking down
to 60 seconds. It is a rank perk (`knk.siege.skip`, see the [commands reference](commands.md#sieges)).

## Before the match: hub, teams and spawn

The timeline, counted back from the start:

| When | What happens |
|---|---|
| 30 s before | Voting closes: "Voting is closed. You will be teleported to the hub in …" |
| 25 s before | The scenario is drawn and announced. Joining is closed from here. |
| 15 s before | You are teleported to the **siege hub** (the scenario's gathering point). Your inventory, XP, health, effects and position are saved: "Your inventory and position are saved and will be restored after the siege." You are put in Survival with flying off. |
| 10 s before | Teams are split: "You are on team &lt;Team&gt; (defenders)." or "(attackers)". If your team has more than one place to start, the **Choose a spawnpoint** menu opens. |
| Start | Title **The siege begins!** with "You fight for &lt;Team&gt;", the match length and the objectives in chat, and your team's start message on the action bar. You are teleported to the spawn you chose. |

**Teams.** Players are dealt out by title, strongest first, in a snake order (1-2-3, 3-2-1, …), so teams end up the same
size (at most one apart) and veterans are spread over them; players with the same title are shuffled. Some scenarios
have more than two teams; teams in the same *alliance* fight on the same side.

**Spawn choice.** Your spawn is where you start and where you respawn. The options are your team's spawnpoints and,
when the scenario allows it, objectives your team holds. Ignore the menu and you get your team's default spawn. Change
it any time with `/siege spawn [option]` or in `/siege menu` → **Change spawnpoint**. An objective that is being
captured can't be picked ("being captured, can't spawn here"). If your team loses the objective you chose, you go back
to the default spawn: "Your team lost X: you respawn at your team's spawnpoint again. Change it in /siege menu".

**Your siege menu.** `/siege menu` (also `/siegemenu` or `/sgm`, or plain `/siege`) opens **Siege information**: the
joined players before the match, the objectives during it (**Objective information**), your team and the join/leave
button.

**What you see.** Only siege players get the siege sidebar: the lobby name, `Team: <name>`, `Time left: mm:ss` and each
objective with its percentage, green when your side holds it and red when not, ⚑ for the main objective and ⚔ while
someone is attacking it. In the tab list siege players have their team name in front and `[kills/deaths]` behind.
Everyone else sees a gold ` [Siege]` tag behind your name until you are back.

## Objectives and winning

**Capture points.** Each objective has a ring on the ground with a banner and a floating percentage. Each second, the
attackers standing alive in the ring push the points down and the defenders in it push them back up; more players
count, but each extra player counts for less than the first. When the points reach zero, the closest attacker
captures it: "&lt;name&gt; captured X!" for their side, "Lost objective X to &lt;Team&gt;!" for the other. With today's
numbers one attacker alone takes a full main objective in about 50 seconds, and holding it needs more defenders than
attackers.

- **Contested:** as soon as one attacker is inside the ring. You hear it and see it in chat ("X is being captured by
  &lt;Team&gt;! (n%)"), on the sidebar (⚔) and on the label above the objective.
- **Main objective:** taking it ends the match at once. Capturing a side objective first lowers the main objective's
  points (by 40 % in total, split over the side objectives), so side objectives make the main one easier.
- **Recapture:** in some scenarios a captured objective can be taken back; in others it is lost for good. The main
  objective is always final.
- An objective can come with a gate: when it is captured, the gate goes to the capturing team (see [Gates](#gates)).

**Match length.** 75 seconds per player at the start, at least 5 and at most 30 minutes (per scenario).

**Who wins:**

1. The side that captures the main objective, at once.
2. When the time runs out: the side holding the main objective(s), normally the defenders. If that is undecided, the
   side holding the most objectives; then the side with the defender team; otherwise it is a draw.
3. When one side has no players left, the other side wins. If too few players are left in total, the match ends and is
   decided as above.
4. A match stopped by staff, a server restart or a loss of the game's services is **aborted**: no winner and no
   rewards.

**Final countdown.** In the last 15 seconds the action bar shows "The siege ends in N seconds" with a tick each
second, the last 5 also as a big number, and the sidebar time turns red.

## Fighting

- You can only hurt enemies in your own match. Teammates and allies can't be hurt (you hear a low note). Siege players
  and other players can't hurt each other: "You can't attack players who are in a siege."
- Nobody can be hurt inside their own team's spawn area: "You can't hurt players inside their spawn area!" and "You
  can't hurt players while you are inside your spawn area!"
- **Headshots:** an arrow or other projectile that hits high on an enemy does 1.5× damage ("Headshot!").
- **Death:** you keep your inventory and level, nothing drops and there is no death message. You respawn at once at
  your spawn choice, with full health and food.
- Your team hears about your kills at 5, 10 and 15 kills and for killstreaks over 3. The killer sees "You killed
  &lt;name&gt;" on the action bar.

## Gates

Gates in the siege area play a part (how gates work in general: [gate structures](gate-structures-player-guide.md)):

| Gate | Who opens and closes it | Who can damage it |
|---|---|---|
| A siege gate owned by your side | Your side: right-click it. It opens and closes again by itself after a few seconds; right-click again to keep it open longer. | Only the enemy |
| A siege gate owned by the enemy | Only them: "This gate is held by the enemy." | You, if the gate can be damaged |
| Any other gate in the siege area | Nobody: it is held open for the match ("This gate is held open during the siege …") | Nobody |

- Destroyed siege gates stay down until the match ends. An objective behind a destroyed gate can still be captured.
- When an objective with a gate is captured, the gate goes to the capturing team and is set open (or as the scenario
  says).
- Damage you do to enemy gates counts for your [rewards](#rewards): direct hits, arrows, TNT you lit and your share of
  fires you started. The [Cleaving](gate-structures-player-guide.md#cleaving-the-siege-enchantment-for-gate-doors)
  enchantment is made for this.
- All gates go back to how they were before the match when it ends.

**If you are not in the match:** you can walk around the siege area as usual; you just can't fight siege players or use
the siege gates. Siege gates near you (within 96 blocks) show as open to you, and walking into one that is really closed
carries you across it. (A version where non-players see every gate as it was before the match is on the way:
[Coming](#coming--not-yet-released).)

## The navigation compass

Some sieges give you a **navigation compass** at the hub ("You received a … Once the match starts, right-click it to be
guided to the objectives; shift-right-click stops the guidance."). Whether you get one is set per lobby or scenario;
it is off unless staff turn it on. With a full inventory you get a warning instead.

- It works once the match has started ("The navigation compass works once the siege match has started.").
- **Right-click** picks the next target: `Compass 2/5: Keep Gate (defend, under attack, 62% held)`. **Shift-right-click**
  stops the guidance or starts it again.
- Targets come in this order: objectives under attack, then your side's job (defenders: objectives to hold; attackers:
  objectives to capture), then the rest, then your team's spawn. If an objective is behind a closed gate, attackers are
  led to that gate first.
- `/navigate` (`/nav`) also works in a match, but only to the match's own destinations.
- The compass is taken away again when your inventory is restored after the match.

## Your gear, kits and enchantments

- **You bring your own gear.** Nothing is cleared at the start, and siege kits are not handed out: there is no kit
  mode yet ([Coming](#coming--not-yet-released)). Whatever you lose, use or break during the match comes back at the
  end, because your saved inventory replaces the one you played with.
- **Kits:** don't claim a kit from the menu during a siege: the items go into your siege inventory and are gone when it
  is restored, while the claim, cooldown or cost still count (known bug,
  [PandiO/knk-workspace#451](https://github.com/PandiO/knk-workspace/issues/451)). `/kit` itself is blocked in a match.
- **Custom enchantments** on your gear work as usual
  ([custom enchantments guide](custom-enchantments-player-guide.md)). Your siege teammates keep seeing you while you
  are invisible.
- **Siege enchantment books.** Now and then a **Siege Enchantment** book (a vanilla enchantment, level 1–2) drops inside
  an objective's ring. Only players of that match can pick it up. Right-click it to choose an item (menu **Apply
  &lt;enchantment&gt;**), or click it onto an item in your inventory: "Enchantment applied. It is removed again after the
  siege." Every siege enchantment and every leftover book disappears when your inventory is restored.
- **Lootboxes:** you can't open them during a siege ("open it once the siege is over"); an item you win is kept for you
  until the siege is over.

## What you can't do during a siege

From the hub teleport until you are restored after the match:

- **Commands:** only `/siege`, `/siegemenu` (`/sgm`), `/navigate` (`/nav`) and the siege's allowed list work, by
  default `/msg`, `/r`, `/staffchat` and `/menu`: "You can't use that command during a siege. Allowed: …"
- **Teleports:** "You can't teleport during a siege. Use /siege leave to leave it." There is no `/back` to a siege death.
- **Items:** you can't drop items, pick items up (siege books excepted), use chests, ender chests, villagers or other
  storage, item frames or armour stands, or place storage blocks. This keeps your saved inventory from being copied.

## Leaving and coming back

- **`/siege leave`** (or the leave button in the menu): before the match it just takes you out. During the match your
  inventory and position are restored at once and you get **no rewards**; it counts as a loss in your statistics.
  After the match (the waiting time at the hub) it only skips the wait: your result and rewards are kept.
- **Disconnecting** at the hub or during the match: your inventory is restored right away, but your place is kept for
  **5 minutes** (a server setting). Log back in within that time, with the same round still on, and you are back on your
  team: title **Back in the siege!** Your kills, deaths and captures carry over. Come back later and you are returned to
  where you were before the siege.
- **After a crash or restart** you get your pre-siege inventory and position back when you join: "You were returned to
  where you were before your last siege, with your pre-siege inventory."

## The end of the match

1. Everyone online hears who won: "&lt;Teams&gt; won the siege &lt;lobby&gt; - &lt;why&gt;".
2. Every siege player is taken to the siege hub (respawned first if dead) and sees **Victory!**, **Defeat** or **Draw**
   with "The siege is over".
3. You get your result line (see [Rewards](#rewards)) and "You return to where you were in 30 seconds, with your own
   inventory. Leave now with /siege leave". The sidebar shows **Match over** and **Return in**.
4. After the wait (30 seconds by default) your inventory, XP, health and position are restored and the lobby cools
   down before the next round.

## Rewards

The server works out your rewards when the match ends. You only get them if you are still in the match at the end.
Starting values per scenario:

| For | Coins | XP | Gems |
|---|---|---|---|
| Your side wins | 100 | 10 | 1 |
| Each objective your team holds at the end that it didn't hold at the start | 50 | 5 | — |
| Each objective you captured yourself (once per objective, recaptures don't pay again) | 50 | 5 | — |
| Each full 100 HP of damage you did to enemy gates | 10 | 1 | — |
| Taking part: active (not AFK) for at least 75 % of your time in the match | 25 | 3 | — |

- Coins are multiplied by your personal and rank multipliers (premium ranks included); XP and gems are not. The XP can
  raise your title, with its usual title bonus.
- Your match time runs from when you first joined the match to its end, time away after a disconnect included. AFK time
  (automatic or `/afk`) doesn't count as active.
- A draw or a loss still pays everything except the win reward. An aborted match pays nothing.

**The result line.** At the end you get one line, for example
`[Siege] Victory! 5 kills · 2 deaths · +120 coins, +12 XP [details] [match page]`. Hover over **[details]** to see
everything: why the match ended, your team, kills, deaths, best kill streak, objectives captured, gate damage, active
time of match time, and each reward with what earned it (win, objectives gained by your team, objectives you captured,
gate damage in full steps, taking part). **[match page]** opens the match on the website (only on servers that have the
website address set).

If the server takes a few seconds, the line comes first and `Your rewards: …` follows. If the game's services were
unreachable, the hover says the result is kept and paid automatically later. A match that couldn't be recorded at the
draw grants no rewards ("no rewards are granted this round").

## Match history

- **In game:** `/siege history` lists your last 5 finished matches, newest first: date, Win/Loss/Draw/Left/Aborted, the
  scenario, your team and your kills and deaths, each with a **[details]** link to its match page, then a link to your
  public profile. With no matches yet: "You haven't finished a siege match yet. Join one with /siege join". The links
  only appear on servers that have the website address set.
- **On the website:** your **public profile** (`/players/<name>`; from **Account** → **Statistics** → **Public
  profile**) has a **Siege matches** table with your last 20 matches: Date, Scenario, Team, Result, Kills, Deaths and
  **Details**. Results read Win, Loss, Draw, Left early or Aborted.
- **The match page** (`/siege/matches/<number>`) shows the result, why it ended, when and how long, the objectives, and
  per team every player's kills, deaths, best streak, captures, gate damage, active time and rewards.
- Profiles and match pages are public. Numbers a player keeps private show as `Hidden`; signed-out visitors see no
  personal numbers. How to choose what others see, and the Siege leaderboards: [statistics guide](statistics-player-guide.md).

## Messages and what they mean

Siege messages start with a red `[Siege]`.

| Message | Meaning |
|---|---|
| `… is already under way; join the next round.` | Matchmaking is over for this round. Wait for the next matchmaking. |
| `… opens for the next round in …` | The lobby is cooling down. |
| `… is full (N players).` | The round has its maximum number of players. |
| `You need at least the title T to join …` | The scenario has a title requirement. |
| `You are already in another siege.` | Leave that one first (`/siege leave`). |
| `You aren't in a siege. Join one with /siege join <lobby>.` | `/siege menu` only works while you are in a siege. |
| `Voting is closed for this round.` | The scenario is being drawn or has been drawn. |
| `This lobby doesn't allow a Random vote.` | Pick one of the listed scenarios. |
| `Too late to skip in …` | The siege starts soon anyway; skipping can't shorten it further. |
| `This gate is held by the enemy.` | Only the side that owns a siege gate can open it. |
| `This gate is part of the siege …` | You aren't in that match, so you can't use its gates. |
| `In a siege you can only fight enemies in your own match.` | The player is in another match. |
| `There is no fighting outside the running match.` | PvP only counts during the match itself, not at the hub or after it. |
| `Your siege history couldn't be loaded right now; try again later.` | The game's services didn't answer. |

## Coming / not yet released

These are not on the default branches yet; don't expect them in game:

1. **Siege Survival** ("Defend the Castle"): endless NPC waves, gate repair and a match economy
   ([PandiO/knk-workspace#41](https://github.com/PandiO/knk-workspace/issues/41), branch `claude/siege-survival`, in
   review).
2. **Gates as they were before the match for non-players**, so nobody outside the match gets through a gate that was
   closed before it ([#213](https://github.com/PandiO/knk-workspace/issues/213)), and per-door pass-through styles
   ([#167](https://github.com/PandiO/knk-workspace/issues/167)); both on `claude/siege-pregame-gate-view`, in review.
3. **Kit mode:** a lobby that hands out a kit instead of using your own gear
   ([#125](https://github.com/PandiO/knk-workspace/issues/125), planned).
4. In `next`, not yet released: a kit that staff grant you from the website while you are in a siege is held back and
   given to you after the siege ([#261](https://github.com/PandiO/knk-workspace/issues/261)).
5. Scheduled lobbies (sieges at set times) are designed but not built; only continuous lobbies run.
