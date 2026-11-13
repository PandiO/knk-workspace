# In-game commands

**Status:** Current · **Last updated:** 2026-11-13 (desk check of the rank columns, `/lb` and `/pay` against the code, PandiO/knk-workspace#316, not yet checked in game; `/knk npc`, on the `next` branch, PandiO/knk-workspace#359 and #360)
**Checked against:** knk-plugin `main` `57884e9` (`knk-paper/src/main/resources/plugin.yml`, `knk-paper/.../paper/commands/`), rank seed migrations in knk-web-api `master` `f445d21`
**Related:** [plugin permission checks](../../architecture/plugin-permission-checks.md), [command permission scan 2026-10-26](../../reports/2026-10-26-command-permission-scan.md), [COMMAND_CATALOG_V3](../../specs/user-features/COMMAND_CATALOG_V3.md) (design notes), [chat tokens](../chat-tokens.md), [plugin configuration reference](../admin/plugin-configuration.md) (the `config.yml` keys behind warmups, cooldowns and limits), [gate structures player guide](gate-structures-player-guide.md), [v1 commands](../../specs/legacy/commands-v1.md) (history)

This page lists every Knights and Kings command on the game server: what it does, who can use it and what the main
refusals mean. The first part is for players, the second for staff. Vanilla Minecraft commands aren't listed; only ops
can use them (`/minecraft:<command>`).

## How access works

- **Ranks.** Your rank (permission group) decides which commands you can use. The game asks the web API for your
  permissions when you join and keeps them for 30 seconds. A rank change made in the web app reaches the game within
  that time. The "Who" columns below name the lowest rank that holds the command **on the closed alpha's seed data**. A
  rank also gets everything from the ranks it inherits from: Staff → Moderator → Admin. The premium ranks (Noble,
  Royal, Dragon Blood) and Alpha Tester each inherit from Default, **not from each other** (seed migration
  `PremiumRanksInheritDefault`; the alpha's database is still to be checked, PandiO/knk-workspace#316): a command
  marked Noble or Dragon Blood is that rank's alone. Whether Royal and Dragon Blood should get Noble's perks is
  PandiO/knk-workspace#430. A rank's own grants come from
  the seed data for now (editing them in the web app is PandiO/knk-workspace#50); staff give one player an extra
  permission with `/knk user <player> perm grant <node>`. "Everyone" means the Default rank. "Ops only" means no
  rank holds it yet.
- **What you see.** `/knk help`, tab completion and the `/` command list only show what you can use. A command you
  can't use answers **"You don't have permission to use this command."** Some commands check a second, more specific
  permission and answer **"You don't have permission to do that."**
- **Service down.** If the game can't reach the web API it says **"Your permissions can't be checked right now (the
  KnK service is unreachable) - try again in a moment."** Money commands say "The economy service can't be reached
  right now — try again in a moment." Nothing happens in either case.
- **"Your account isn't loaded yet - try again in a moment."** You've only just joined. Wait a second and try again.
- **Vanished players** (staff in staff or owner mode) read as offline in almost every command: "No online player
  named '…'."

## Player commands

### Menus, account and statistics

| Command | Who | What it does |
|---|---|---|
| `/menu` | Everyone | Opens the Knights and Kings menu. |
| `/discoveries` (`/disc`) | Everyone | Opens the towns, districts and structures you have discovered. |
| `/account` (`/acc`) | Everyone | Shows your account: username, email (or "Not linked"), coins, gems and experience. |
| `/account link` | Everyone | Gives you a link code (XXXX-XXXX, click it to copy) for the website. It is valid for 20 minutes. Enter it when you register at the website, or on your Account page if you already have a web login. You can ask for a new code once a minute. Link codes are entered on the website, never in game, and staff never ask for yours. |
| `/stats [player]`, `/user statistics [player]` (`/u stats`) | Everyone | Your title, progress to the next title, coins, gems, XP, prestige and gameplay statistics, or another player's (online or offline). For another player you only see the statistics they share with everyone. |
| `/stats settings` | Everyone | Choose who may see each of your statistics: Nobody, Friends or Everyone. (Friends doesn't show anything to anyone yet.) |
| `/leaderboard [board] [weekly\|monthly\|lifetime]` (`/lb`) | Everyone | Opens the leaderboards. With a board name it shows that board for the period, weekly by default, and your own place. You are only ranked on statistics you share with everyone. |
| `/afk` | Everyone | Marks you AFK (`[AFK]` in the tab list). AFK time doesn't count as active playtime. Moving, chatting or `/afk` again brings you back. You also go AFK on your own after 5 minutes idle. |

Common replies: "No player found named '…'." · "Not computed yet - check back in a few minutes." (a new leaderboard) ·
"AFK is disabled." (turned off on this server).

### Chat and private messages

| Command | Who | What it does |
|---|---|---|
| `/msg <player> <message>` (`/tell`, `/w`, `/m`, `/pm`, `/whisper`, `/message`) | Everyone | Sends a private message. You see `[me -> Bob]` and they see `[Alice -> me]`. Click a message to reply. Messages are cut at 256 characters. |
| `/reply <message>` (`/r`) | Everyone | Replies to the last person you messaged or who messaged you. |
| `/ignore [player]` | Everyone | Without a name: lists who you ignore. With a name: ignores that player, or stops ignoring them if you already do. You no longer see their private messages or their chat. Works on offline players. |
| `/unignore <player>` | Everyone | Stops ignoring a player on your list. |
| `/chattoken …` | Everyone | Not typed: it is the button behind the question you get when a [chat token](../chat-tokens.md) such as `#kills` would show one of your private statistics. Your choices are **Make public & send**, **Send without** (the token stays plain text) or **Never ask**. The buttons work for 60 seconds. |

- **Private messages may be read by moderators.** They are logged, and staff with social spy see them.
- Rate limit: 5 messages in 5 seconds, and the same text to the same player within 10 seconds counts as spam: "Slow
  down — you can send another message in Ns."
- If the player ignores you, your message isn't delivered, but you aren't told. Staff can't be ignored: "You can't
  ignore staff."
- While you are frozen you can only message staff: "You can only message staff while frozen."
- Other replies: "You can't message yourself." · "Nobody to reply to." · "Your ignore list is full - /unignore
  someone first."

### Travel and teleporting

| Command | Who | What it does |
|---|---|---|
| `/spawn` | Everyone | Teleports you to spawn. That is your rank's spawn if it has one, else the server spawn. |
| `/hub` | Everyone | Teleports you to the hub. |
| `/warp` (`/point`) | Everyone | Opens the teleport menu. |
| `/warp <place>`, `/warps`, `/warp list` | Everyone | Teleports you to a town, district or structure that is set up as a destination, or lists them. A place can need a title, a premium tier or that you discovered it first, and it can cost gems. You pay when you arrive, and you are refunded if the teleport fails. If two places share a name, use `town:Name` or `district:Name`. |
| `/tpa <player>` | Everyone | Asks to teleport to a player. They get clickable [Accept] [Deny] buttons. The request expires after 30 seconds. |
| `/tpaccept [player]` (`/tpyes`), `/tpdeny [player]` (`/tpno`) | Everyone | Answers the newest request, or the named player's. `/tpa accept\|deny` does the same. |
| `/tpcancel` | Everyone | Withdraws your request, or stops a teleport you are waiting for. |
| `/tpahere <player>` | Dragon Blood | Asks a player to teleport to you. |
| `/back` | Dragon Blood | Takes you back to where you died, within 5 minutes and once per death. A rank can also be given `/back` after a warp, a `/tpa` or a `/spawn`/`/hub` (staff set this up). |
| `/navigate <place> [spawn\|region]` (`/nav`) | Everyone | Shows a particle trail and a boss bar along the roads to a place, town, district, structure, street or road point. It is not a teleport. `/navigate` alone shows where you are going; `/navigate stop` ends it. |

How player teleports work:
- **Warmup.** "You need to wait 5 seconds before teleporting... Don't move." Moving, taking damage or dying cancels it
  ("Teleport cancelled: you moved."). Some ranks wait 3 seconds or not at all.
- **Cooldown.** After a teleport you wait 30 seconds before the next one of the same kind: "You can teleport again in
  N s." Your rank can change this.
- **Combat.** No teleporting within 10 seconds of a PvP hit: "You were in combat N s ago; wait M s."
- **Price.** A teleport that costs something says so when the warmup starts. If you can't pay: "You can't afford the
  … this teleport costs!"
- **Other refusals.** "You can't teleport while frozen." · "You can't teleport during a siege. Use /siege leave to
  leave it." · "The destination isn't safe right now." · a region's own message, else "You can't teleport there."
- **Navigation replies.** "You're too far from a road - get within 48 blocks of one." · "No road connects you to
  X." · "You can't navigate while you are in a siege." Inside a siege match you can only navigate to the match's
  places.

### Money

| Command | Who | What it does |
|---|---|---|
| `/balance [player]` (`/bal`, `/money`) | Everyone | Shows your coins and gems, or another player's. |
| `/pay <player> <amount> [coins\|gems]` | Everyone | Pays a player coins. They can be offline. A large amount (100,000 coins or more unless the server changed it) asks you to click [Confirm] or [Cancel], or type `/pay confirm` / `/pay cancel`; the question expires after 60 seconds. Gems can't be paid. |
| `/baltop [coins\|gems] [page]` | Everyone | The richest players, 10 a page. |
| `/transactions [coins\|gems\|xp] [page]` (`/tx`) | Everyone (another player's: Staff) | Your coin, gem and XP history, newest first. |

The server sets the payment limits. Unless staff changed them: at least 10 and at most 1,000,000 coins a payment,
2,000,000 coins sent a day, 5 seconds between payments and 20 an hour, and your account must be 48 hours old with at
least the first title. The refusal says which limit you hit, for example "Daily limit reached - you can send N more
coins (resets in …)." or "You only have N coins." The amount must be a whole number from 1 to 999,999,999, with no separators. If a
payment can't be confirmed: "We couldn't confirm the payment. Check /transactions before trying again."

### Kits, lootboxes and custom enchantments

| Command | Who | What it does |
|---|---|---|
| `/kit list` | Everyone | Lists the kits, whether you can claim each one, and its cost or premium price. |
| `/kit get <name>` | Everyone | Claims a kit. The kit's own rules (rank, title, cooldown, cost) apply. |
| `/kit purchase <name>` (`/kit buy`) | Everyone | Buys a premium kit once with gems. After that you claim it with `/kit get`. |
| `/lootbox` | Everyone | How lootboxes work: right-click one in the world to open it. There may be a daily limit, which resets at 00:00 UTC. |
| `/lootbox odds <category> [stars]` | Everyone | What a box of that category can give, with chances. |
| `/ce info` (`/customench info`) | Everyone | Lists the custom enchantments on the item in your hand. See below. |

`/ce info` shows, for each enchantment, its level and your remaining cooldown. Under it are the combat values at
that level: chance, duration and cooldown, plus the area damage for Chaos and Flash Chaos. For Cleaving it is a line
like `gate hits +25%, charged strike 5x, strike cooldown 60s` (PandiO/knk-workspace#259). See the
[gate structures player guide](gate-structures-player-guide.md#cleaving-the-siege-enchantment-for-gate-doors). Using
an enchantment's ability needs that enchantment's permission (`customenchantments.<id>`), which staff give to a rank or a player.

Note: `/lb` opens the leaderboards, not the lootboxes. Both commands declare it, so /lootbox loses it
(PandiO/knk-workspace#310).

### Sieges

| Command | Who | What it does |
|---|---|---|
| `/siege` | Everyone | Opens the siege menu: your lobby, or the list of lobbies. |
| `/siege join [lobby]` | Everyone | Joins a lobby. You can leave out the name when there is only one. |
| `/siege leave` | Everyone | Leaves your siege. During a match your items and position are restored and you get no rewards. After the match your result and rewards are kept. |
| `/siege menu`, `/siegemenu` (`/sgm`) | Everyone | Opens your siege's information menu. |
| `/siege info [lobby]` | Everyone | A summary in chat: countdown, players, teams, objectives, your kills and deaths. |
| `/siege vote [number\|name\|random]` | Everyone | Votes for the next scenario. Without a choice it lists them. Voting for your current choice again withdraws your vote. |
| `/siege spawn [option]` | Everyone | Chooses where you start and respawn. An objective that is being captured can't be picked. |
| `/siege history` | Everyone | Your last finished matches, with links to the website. |
| `/siege skip [lobby]` | Noble (only; PandiO/knk-workspace#430) | Skips a lobby's cooldown so matchmaking starts, or shortens matchmaking. |

- **Commands during a match.** In the hub and during a match only `/siege`, `/siegemenu`, `/navigate` and the
  commands the siege allows work: "You can't use that command during a siege. Allowed: …"
- **Join refusals.** "X is already under way; join the next round." · "X is full (N players)." · "You need at least
  the title T to join X." · "You are already in another siege." Siege refusals start with `[Siege]`. A refusal for a
  missing permission names the permission: "You don't have permission to do that (knk.siege.skip)."

### Gates

| Command | Who | What it does |
|---|---|---|
| `/gate list`, `/gatedoor list [gate]` | Everyone | Lists the gates (or the doors) and whether they are open. |
| `/gate info [gate\|here]`, `/gatedoor info [door\|here]` | Everyone | Details of a gate or a door: state, health, siege objective. |
| `/gate passthrough <default\|instant\|teleport>` | Everyone | Chooses how you go through a closed gate you may pass when you right-click it. |
| `/gate open\|close\|toggle [gate\|here]`, `/gatedoor open\|close\|toggle [door\|here]` | Players given a gate | Opens or closes a gate you control. Staff give this per gate. |

Without a name, the gate you are looking at is used, else the nearest one within 15 blocks. `here` always uses the
nearest; if several are close you get a clickable list. "You don't have permission to open gate 'N' (#id)." means the
gate isn't yours to control. More in the [gate structures player guide](gate-structures-player-guide.md).

## Staff and admin commands

Nodes are in-house permissions unless marked. "Who" is the lowest seeded rank (Staff → Moderator → Admin inherit).
Admin holds `knk.admin.*`, which covers every `knk.admin.<x>` node. Commands that act on another player check rank:
**"outrank"** means your highest rank must be above theirs ("You cannot act on a player of equal or higher rank."),
**"same rank or lower"** allows equals ("You cannot act on a player of higher rank."). Holders of
`knk.admin.user.manage.all` (the owner) and the console skip both rank checks.

### Modes and moderation

| Command | Node | Who | What it does |
|---|---|---|---|
| `/staffmode [on\|off] [onquit]` (`/sm`), `/ownermode …` (`/om`) | `knk.mode.staff`, `knk.mode.owner` | Staff; owner | Hides you from everyone without a mode node. The mode is saved and restored on your next join. `onquit` (or `oq`) only changes it for your next join, so there is no join or leave message. Turning one mode on switches off the other. `/sm help` lists the forms. |
| `/freeze <player> <reason…>` | `knk.freeze` | Staff | Locks the player's movement, chat, commands (except `/msg` and `/r` to staff) and damage until unfrozen. Works on offline players from their next join. Outrank. |
| `/unfreeze <player>` | `knk.unfreeze` | Staff | Ends a freeze. Outrank. |
| `/staffchat <message>` (`/sc`) | `knk.staffchat` | Staff | Sends one message, `[Staff] name: message`, to every online holder of the node. It is not a channel you stay in. |
| `/socialspy [on\|off]` (`/spy`) | `knk.socialspy` | Staff | Shows you other players' private messages (`[Spy] A -> B: …`). It is on by default and kept across restarts. Messages to or from holders of `knk.socialspy.exempt` (the owner) stay hidden from spies without that node. |

Related nodes: `knk.msg.bypass.ratelimit` (no message rate limit), `knk.msg.bypass.ignore` (messages reach players who
ignore you), `knk.msg.unignorable` (can't be ignored), `knk.notify.joinattempt` (a chat line when a join is refused),
`knk.region.bypass` (enter and leave where a region forbids it), `knk.region.bypass.containers` (open storage where a
region forbids it, Moderator), `knk.hub.bypass` (build in the hub, Admin). All of these are Staff unless noted.

### Teleporting players

All of these are instant: no warmup, cost, cooldown or combat check. They are logged. `-s` (needs
`knk.teleport.staff.silent`) skips the message to the other player; while vanished you are always silent. Region and
siege rules still apply. A frozen player **can** be moved (PandiO/knk-workspace#309).

| Command | Node | Who | What it does |
|---|---|---|---|
| `/tp <player> [-s]`, `/knk tp <player>` | `knk.teleport.staff` or `knk.admin.tp` | Staff | Teleports you to the player. Same rank or lower. |
| `/tp <x> <y> <z> [world] [yaw pitch]` | `knk.teleport.staff` | Staff | Teleports you to coordinates; `~` means relative. |
| `/tp <player> <target> [-s]` | `knk.teleport.staff.others` | Staff | Moves one player to another. Same rank or lower, for both. |
| `/tphere <player> [-s]` | `knk.teleport.staff.others` | Staff | Brings the player to you. |
| `/spawn <player>`, `/hub <player>`, `/warp <place> <player>` | `knk.teleport.staff.others` | Staff | Sends the player to their spawn, the hub or a destination. A destination ignores its requirements and price. |
| `/back <player> [-s]` | `knk.teleport.staff.back.others` | Ops only | Sends the player to their latest `/back` place. Same rank or lower. |
| `/tp all <player>`, `/tphere all`, `/spawn all`, `/hub all` | `knk.teleport.all.tp\|tphere\|spawn\|hub` | Moderator | Moves every online player of your rank or lower, apart from you, exempt players and players in staff or owner mode. |
| `/knk location tp <id>` | `knk.admin.location.tp` | Moderator | Teleports you to a Location by its id. |

Players holding `knk.teleport.exempt.<hub|spawn|tp|tphere>` (or `.exempt.*`), or in staff or owner mode, can't be
moved by those commands: "X is exempt from being teleported by others." The `all` forms skip them, and only the
owner's override moves them one by one. Rank perks for player teleports: `knk.teleport.warmup.short` (3 s),
`.bypass.warmup`, `.bypass.cooldown`, `.bypass.combat`, `.bypass.cost`, `.bypass.requirements`, and
`knk.teleport.back.warps|teleport|spawn|all` for more kinds of `/back`.

### Players: game mode, flight, health, inventories

| Command | Node | Who | What it does |
|---|---|---|---|
| `/gamemode <mode> [player]` (`/gm`; modes `s`/`c`/`a`/`sp` or `0`–`3`) | `knk.gamemode.<mode>`, `knk.gamemode.others` | survival and spectator: Staff; others: Moderator; all modes: Admin | Sets your game mode, or a player's (that also needs the mode's node). |
| `/fly [on\|off] [player]` | `knk.fly`, `knk.fly.others` | Staff; others: Moderator | Toggles or sets flight. |
| `/heal [player\|all]`, `/feed [player\|all]` | `knk.heal`, `.others`, `.all` (and `knk.feed…`) | Ops only | Full health and fire out, or full food. |
| `/enderchest [player]` (`/ec`) | `knk.enderchest`, `knk.enderchest.open` | own: ops only; others: Moderator | Opens your ender chest, or a player's. Offline players' saved chests are written back when you close it. Outrank. |
| `/inventory open <player>` (`/inv`, `/invsee`) | `knk.inventory.open` | Moderator | Opens a player's inventory, which you can edit. Works offline. Outrank. |
| `/inventory clear <player> confirm` | `knk.inventory.clear` | Admin | Empties the whole inventory, armour included. Without `confirm` it only explains what it will do. Outrank. |

### Money, kits and lootboxes (staff)

| Command | Node | Who | What it does |
|---|---|---|---|
| `/transactions <player>` | `knk.transactions.others` | Staff | Another player's coin, gem and XP history. (`/balance <player>` needs `knk.balance.others`, which every player has.) |
| `/knk user <player> info` | any `knk.admin.user.*` | Staff | The player's coins, gems, XP and title. |
| `/knk user <player> coins\|gems set\|add\|remove <amount> <reason…>` | `knk.admin.user.coins\|gems` | Staff | Changes a balance through the ledger; the reason is required. The daily grant cap applies unless you hold `knk.admin.currency.unlimited`. No rank check (PandiO/knk-workspace#315). |
| `/knk user <player> xp set\|add\|remove <amount> [reason]` | `knk.admin.user.xp` (raising XP also needs `.coins` and `.gems`) | Staff | Changes XP and so the title. Title bonuses are paid. |
| `/knk user <player> group add\|remove <group> [2h\|90m\|3d]` | `knk.admin.user.group` | Staff | Adds or removes a rank membership; leave the duration out for permanent. Outrank. |
| `/knk user <player> perm grant\|revoke <node> [duration]` | `knk.admin.user.perm` | Staff | Grants or revokes one node on the player. Outrank. |
| `/knk user <player> history [coins\|gems\|xp] [page]`, `/knk currency history <player> …` | `knk.admin.user.history`, `knk.admin.currency.history` | Staff | The player's ledger, with transaction ids. |
| `/knk currency reverse <txId> [--partial] <reason…>` | `knk.admin.currency.reverse` | Staff | Reverses a transaction. The reason needs at least 10 characters. `--partial` reverses what is left when part was spent. |
| `/knk currency lock <player> <reason…>`, `unlock <player>` | `knk.admin.currency.lock` | Staff | Blocks or allows the player's payments. |
| `/knk currency alerts [all] [page]`, `alerts ack <id>` | `knk.admin.currency.alerts` | Staff | Currency anomaly alerts. |
| `/pay …` with `knk.pay.bypass` | `knk.pay.bypass` | Staff | Event payouts that skip the payment limits. |
| `/kit give <player> <name>` | `knk.kit.give` | Staff | Gives a kit to an online player, skipping their cooldown and cost. |
| `/kit manage` | `knk.kit.manage` | Staff | Points to the web app's Kit form; kits aren't edited in game. |
| `/knk lootbox spawn <category> [stars]`, `despawn [id\|nearest]`, `list [area]`, `tp <id>` | `knk.lootbox.admin.<action>` | Staff | Places a box where you stand (ignoring caps), removes one (the nearest within 16 blocks), lists or visits boxes. |
| `/knk lootbox give <player> <category> [stars]`, `token <player> <category> [stars\|any] [1-64]` | `knk.lootbox.admin.give\|token` | Staff | Opens a box for the player, or gives them token items. Refused while the player is in a siege. |
| `/knk lootbox area create\|list\|info\|delete <name>`, `reload` | `knk.lootbox.admin.area\|reload` | Staff | Spawn areas from a WorldEdit selection (`delete` asks you to repeat it within 10 s). `reload` re-reads the settings. |

### Custom enchantments, items and world tasks

| Command | Node | Who | What it does |
|---|---|---|---|
| `/ce add <enchantment> <level>` | `customenchantments.command.add` and that enchantment's node | Ops only | Adds a custom enchantment to the held item, up to its max level. |
| `/ce remove <enchantment>` | `customenchantments.command.remove` | Ops only | Removes it from the held item. |
| `/ce info <player>` | `customenchantments.command.info.others` | Ops only | The enchantments on a player's held item. |
| `/ce cooldown clear [player]` | `customenchantments.command.cooldown.clear(.others)` | Ops only | Clears enchantment cooldowns. |
| `/ce reload` | `customenchantments.command.reload` | Ops only | Reloads the config and the combat values from the API. |
| `/knk item rename <name>` | `knk.admin.item` | Staff | Renames the held item (`&` colour codes work). |
| `/knk item lore add <text>`, `lore set <line> <text>`, `lore remove <line>` | `knk.admin.item` | Staff | Edits the held item's lore. **`set` inserts** at that line and moves the rest down. |
| `/knk item enchantments list\|vanilla\|search\|apply …` | `knk.admin.item` | Staff | Browses the enchantment catalogue and applies one to the held item. |
| `/knk item more [amount]` | `knk.admin.item.more` | Admin | Fills the held stack, or gives another stack or exactly `amount`. Items with an instance id get new ids from the API. |
| `/knk itemblueprints list\|search\|get\|give <id> [player]` (`/knk ib`) | `knk.admin.itemblueprints` | Staff | Browses item blueprints and gives the item. |
| `/knk tasks [status]` | `knk.tasks` | Staff | Lists world tasks (default Pending). |
| `/knk task <code>` (`task-claim`), `itemscan claim <code>`, `kitscan claim <code>` | `knk.tasks` | Staff | Claims a world task with the code from the web app and starts it. One open task at a time; type `cancel` to hand it back. Claiming by number needs `knk.tasks.any`, which only works for ops (PandiO/knk-workspace#311). |
| `/knk task accept\|decline <id>` | `knk.tasks` | Staff | Answers a task offer sent from the web app. |
| `/knk task-status <id\|code>` | `knk.tasks` | Staff | A task's status and details. |

### Gates and sieges (staff)

| Command | Node | Who | What it does |
|---|---|---|---|
| `/gate repair\|tp [gate\|here]` | `knk.gate.admin` | Ops only | Repairs every door of the gate, or teleports to the gate's spawn point (else next to a door). |
| `/gate override <gate> <active\|destroyed\|invincible\|canrespawn\|openedstate> <value\|clear>` | `knk.gate.admin` | Ops only | Sets a gate-wide override that applies to all its doors. |
| `/gate reload [district <id>]` | `knk.gate.admin` | Ops only | Reloads the gates from the API. |
| `/gatedoor repair\|tp\|health <n>\|active\|invincible\|capture\|redefine <door>` | `knk.gatedoor.admin` (or `knk.gate.admin`) | Ops only | Single-door admin. `capture`/`redefine [closed\|opened]` start a WorldEdit region capture. |
| `/gate open\|close …` for any gate | `knk.gate.open.*`, `knk.gate.close.*` (or per gate `knk.gate.open.<id>`; doors `knk.gatedoor.open.<id>`) | Ops only | Gate control. A toggle needs the node for the way it goes. |
| `/siege admin list` | `knk.siege.admin.list` | Staff | Every lobby with its phase, lock, rotation and members. |
| `/siege admin start\|stop <lobby> [reason]`, `skip <lobby>`, `kick <player>` | `knk.siege.admin.control` | Staff | Starts matchmaking, stops a round (members restored, no rewards; it stays stopped until started), skips a phase, removes a member. |
| `/siege admin reload` | `knk.siege.admin.reload` | Staff | Refreshes the siege config for lobbies not in a match. |
| `/siege admin manage` | `knk.siege.admin.manage` | Staff | Points to the web-app forms; sieges aren't edited in game. |
| `/siege join <player> [lobby] [team]` | `knk.siege.admin.join` | Admin | Puts a player into a round, also at the hub or in a running match, skipping the capacity and title rules. |
| (any command during a match) | `knk.siege.bypass.commands` | Staff | Skips the siege's command list. |

The gate nodes are held by no rank on the alpha seed: Admin's `knk.admin.*` doesn't cover `knk.gate.*`. Give them to a
player per gate with `/knk user <player> perm grant knk.gate.open.<id>` (and `.close.<id>`).

### Server tools (`/knk`)

`/knk help [page|command]` lists what you can use, 8 lines a page (the console sees everything). Unknown subcommands
answer "Unknown command: <name>". Every node below is held by Admin through `knk.admin.*`. Other ranks are noted.

| Command | Node | What it does |
|---|---|---|
| `/knk health` | `knk.admin.health` | API connectivity (UP/DOWN), queue depths and a live API health probe. |
| `/knk cache [refresh]` | `knk.admin.cache` | Cache statistics; `refresh` drops cached settings such as the spawn. |
| `/knk regions repair\|sync\|temp [purge [hours]]` | `knk.admin.regions` | Re-applies the managed WorldGuard settings to every KnK region, runs the domain access sync, or reports leftover temporary regions. **`temp purge` deletes** them (older than 24 h by default) **without asking**. |
| `/knk towns\|districts\|streets list [page] [size]`, `/knk town\|district\|street <id>` | `knk.admin.towns` … `knk.admin.street` | Lists towns, districts or streets, or shows one. |
| `/knk locations list [page] [size]`, `/knk locations <id>`, `/knk location here` | `knk.admin.locations`, `knk.admin.location` | Lists Locations, or prints your own position. |
| `/knk location orphans [page]` | `knk.admin.location.orphans` (Moderator) | Orphaned Locations waiting for review; Keep or delete them in the web app. |
| `/knk clans list\|info <id>\|banner <id>\|design <id>` | `knk.admin.clans` | Clan data; `banner`/`design` give you the banner item. |
| `/knk menu open <key>\|page\|search\|filter\|broken` | `knk.admin.menu` | Menu test tools; `broken` lists menus blocked at startup. |
| `/knk discovery list <player> [page]\|reset <player> <domainId>\|status` | `knk.admin.discovery` (Staff) | A player's discoveries. `reset` forgets one so it can be discovered and rewarded again; the reward isn't taken back. |
| `/knk road …` | `knk.admin.road` (Staff) | Road network tools: surveys, building tiles, editing nodes and edges, proposals, `why <destination>`. |
| `/knk npc status\|audit start\|stop\|report\|test spawn <n> [radius]\|test clear` | `knk.admin.npc` (op by default) | NPC navigation (on the `next` branch, off by default: `npc.navigation.enabled`): status and each setting with the layer it came from, the NPC event audit, wandering test NPCs. Without Citizens or with the switch off, `status` says why. |
| `/knk npc nav from\|to\|route list\|save\|load\|delete <name>\|baseline\|spawn <n> [profile]\|group <n> [formation] [profile]\|goto\|patrol\|stats [reset]\|trace [npc] [seconds]\|clear` | `knk.admin.npc` | Route following for testing: set a route's ends, spawn NPCs that walk it back and forth (two spawns per tick), read the counters, trace one NPC. `group` spawns the NPCs as one group that walks the route in a formation (`column`, `ranks`, `cluster` or `escort-ring`; without one, the `group-formation` setting): the first NPC leads and plans the route, the others follow in their slots. Files go to `plugins/KnightsAndKings/npc-logs/`. See the implementation plan's developer tests for [single NPCs](../../specs/npc-platform/IMPLEMENTATION_PLAN.md#phase-2--navigate-one-npc-plugin) and [groups](../../specs/npc-platform/IMPLEMENTATION_PLAN.md#phase-4--groups-plugin). |
| `/knk gate …`, `/knk gatedoor …` | as `/gate` | The same as `/gate` and `/gatedoor`. |

## Known differences from the descriptions

These came up while checking this page against the code. The page above describes what the code does.

- PandiO/knk-workspace#309: staff teleports move frozen players, although plugin.yml says the freeze guard applies.
- PandiO/knk-workspace#310: `/lb` is /leaderboard; /lootbox's alias is lost.
- PandiO/knk-workspace#311: some nodes are checked only by Bukkit (`knk.tasks.any`, `/account`, `/menu`,
  `/discoveries`, the `/ce` root; `knk.navigate` can't be taken away from a rank), and some only from the cache
  (siege nodes, `/kit`, `/ce … <player>`).
- PandiO/knk-workspace#312: some commands find or name vanished players (`/siege admin kick`, `/ce … <player>`,
  `/fly`, `/gamemode`, `/heal`, `/feed`, `/kit give`, `/knk itemblueprints give`, `/knk lootbox give|token`).
- PandiO/knk-workspace#313: usage and reply texts that don't match. Among them: `/account create` is listed but
  doesn't exist, `/knk task-status` prints the wrong usage, and the same command can give two different "no
  permission" texts.
- PandiO/knk-workspace#314: `/gatedoor health 0` doesn't destroy the door; `/gate override active|destroyed` fires
  no state change.
- PandiO/knk-workspace#315 (decision): `/siege skip` works on any lobby; `/knk user … coins|gems|xp` has no rank check.
- PandiO/knk-workspace#430 (decision): the premium ranks each inherit from Default, so Royal and Dragon Blood don't get
  Noble's `/siege skip`, although the teleport design expects Noble's perks to reach the higher tiers.

The rank columns were checked against the seed migrations on 2026-11-13 (PandiO/knk-workspace#316), not yet in game.
The grants made by hand in the alpha's seed database (for example Dragon Blood's `/tpahere` and `/back`, and the
Staff → Moderator → Admin chain) still need that check.
