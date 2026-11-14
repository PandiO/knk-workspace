# Ranks, permissions and moderation — admin guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#301)
**Checked against:** knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d`, knk-plugin `main` `57884e97`; not
live-tested as a whole (the parts' own smoke tests are linked in § 9)
**Related:** [ranks, titles and chat (player guide)](../users/ranks-and-chat-player-guide.md) (what players see),
[dashboard access and ranks](dashboard-access-admin-guide.md) (area nodes, delete/export nodes, the escalation guard's
rank rule), [commands reference](../users/commands.md) (every command and node), [staff web app](staff-web-app-guide.md),
[plugin permission checks](../../architecture/plugin-permission-checks.md), [rank display spec](../../specs/user-features/RANK_DISPLAY.md),
[private messages design](../../specs/private-messages/DESIGN.md)

For staff and admins: how groups, ranks and premium tiers work, how to give someone a group, a rank or a permission
node in the web app and in game, what the escalation guard allows, the moderation tools (freeze, staff and owner
mode, staff chat, social spy, the private-message log, kick and ban) and what the audit log records. What players see
of all this is in the [player guide](../users/ranks-and-chat-player-guide.md); this guide doesn't repeat it.

## 1. Before you start

1. **Web app:** a web account linked to your Minecraft account with `knk.admin.user.manage` opens **Players & support →
   Player moderation** (`/admin/users`) and the player profiles. Changing groups needs `knk.admin.user.group`, changing
   nodes `knk.admin.user.perm`; freezing `knk.freeze` / `knk.unfreeze`. A button you lack the node for is greyed out with
   "Requires <node>".
2. **In game:** the same nodes, through `/knk user …`, `/freeze`, `/unfreeze` and the Player manager (`/menu` →
   **Player manager**, shown with `knk.admin.user.manage`).
3. **When changes arrive in game:** a change made in game (`/knk user`, Player manager) applies at once. A change made in
   the web app reaches the game within 30 seconds (the plugin's permission cache), or at once after `/knk cache
   refresh`; group and rank changes also redraw the player's chat colours and tab list within a few seconds.
4. **Who holds what on the closed alpha** is in the [commands reference](../users/commands.md) ("Who" columns) and, for
   the dashboard, in [dashboard access § 4](dashboard-access-admin-guide.md#4-what-each-rank-can-do).

## 2. Groups, ranks and premium tiers

A **permission group** holds permission nodes and can have one **parent** group whose nodes it inherits. Every player
is in one or more groups. Two kinds matter:

1. **Ranks:** **Default** and the **premium tiers** (groups with *Premium Tier* ticked: Noble, Royal, Dragon Blood). A
   player holds **exactly one rank**. The API enforces it for every caller: adding a rank removes the player's other
   active rank (audit "Group removed", with what replaced it); removing a premium tier puts the player back on Default,
   permanently. A temporary tier that ends puts the player on Default too, not on the tier they had before (the API's
   expiry sweep runs every 30 seconds).
2. **Other groups** (Alpha Tester, Staff, Moderator, Admin, a builder group): any number, added and removed freely,
   permanent or with an end date.

**Seeded groups.**

| Group | Weight | Parent | Premium | Comes from |
|---|---|---|---|---|
| Default | 0 | — | no | migration; every new account gets it |
| Alpha Tester | 1 | Default | no | migration; given by a redeemed invitation |
| Noble / Royal / Dragon Blood | 10 / 20 / 30 | Default (dev seed: Dragon Blood → Royal → Noble → Default) | yes | migration; salary multiplier 1.1 / 1.2 / 1.5 |
| Staff | (database) | — | no | **alpha and dev databases only**; no migration creates it |
| Moderator | 50 | Staff on the alpha | no | migration |
| Admin | 100 | Moderator on the alpha | no | migration; holds `knk.admin.*` |
| Owner | — | — | — | not a group: the owner's account holds `*` |

The premium chain differs per database: the migrations make each tier inherit only from Default, the dev seed chains
them (PandiO/knk-workspace#430, see the [commands reference § How access works](../users/commands.md#how-access-works)).
On a database built from migrations alone there is no Staff group, so the migrations that seed nodes on Staff skip it.

**Weight** orders the groups: the escalation guard compares weights (§ 4), and among a player's groups the
heavier one decides first when two disagree about a node. Keep staff groups above every rank and premium tier.

**Watch out:**

1. Default is found **by its name**. Don't rename it: new accounts, the one-rank rule and the colour fallback all look
   for "Default".
2. Don't remove Default from a player without giving them a premium tier: the web app allows it and the player is then
   left without a rank and without Default's nodes (`/pay`, sieges, chat tokens). The in-game Player manager refuses it
   (PandiO/knk-workspace#465).
3. Chat and tab-list colours come only from the player's premium tier, else from Default. A Staff or Moderator
   group's colours are stored but not used (PandiO/knk-workspace#260, in review, not merged). The group form's
   *Chat Prefix* and *Chat Suffix* are not used anywhere (#465).

## 3. Giving someone a group, a rank or a node

### 3.1 In the web app

Open **Player moderation**, search the player (username, email or UUID), open their profile, tab **Permissions**.

1. **Groups card** ("Groups (N active)"): pick a group in **Assign group** ("Select a group…"), optionally set
   **Expires (optional)**, click **Assign**. This is also how you set a rank or premium tier: assigning Noble, Royal or
   Dragon Blood replaces the player's Default or previous tier, without a warning on the page. The **X** ("Remove group")
   ends a membership. Needs `knk.admin.user.group`.
2. **Effective Permissions** card: every node the player has, with **Granted**/**Denied** and its **Source** ("Direct
   grant" or the group). To add one: type it in **Grant/deny node** (for example `knk.gate.open.12`), choose **Grant** or
   **Deny**, check **Expires**, click **Save**. **The expiry is filled in as one day from now**; click **Clear** for a
   permanent grant. The **X** on a direct grant removes it; an inherited row is changed on its group or by removing the
   membership. Needs `knk.admin.user.perm`.
3. **Overview → Premium Tier** lists the player's premium memberships; ended ones are struck through. **Player
   moderation → Premium expiring soon** lists tiers that end within the days you choose.

### 3.2 In game

| Command | Node | Notes |
|---|---|---|
| `/knk user <player> group add <group> [2h\|90m\|3d]` | `knk.admin.user.group` | Leave the duration out for permanent. Adding a rank replaces the other one. |
| `/knk user <player> group remove <group>` | `knk.admin.user.group` | Removing a premium tier puts them on Default |
| `/knk user <player> perm grant <node> [duration]` | `knk.admin.user.perm` | Grants only; a deny is set in the web app |
| `/knk user <player> perm revoke <node>` | `knk.admin.user.perm` | |
| Player manager → a player → **Groups** | `knk.admin.user.group` | A rank click asks "Set Steve's rank to Royal (replaces Default)?"; click **Confirm** |

You must **outrank** the player (your highest group heavier than theirs): "You cannot act on a player of equal or higher
rank." Holders of `knk.admin.user.manage.all` (the owner) and the console skip that check. The player is told "✦ Your
rank is now Royal!" or "✦ You have been added to Builders!"; a change made in the web app reaches them without a
message (PandiO/knk-workspace#466). After a premium change you see which tier the player now shows.

### 3.3 A group's own nodes, and new groups

1. **New group, name, weight, parent, premium flag, multipliers:** **Dashboard → Permission group → New** or **Edit**
   (needs `knk.admin.user.perm`; deleting needs `knk.admin.delete` too, and a group with child groups can't be deleted).
   *Parent Group Id* is a plain number: the parent group's id.
2. **A group's nodes** have no web screen yet (PandiO/knk-workspace#50). The owner or an Admin sets them through the
   API, as in [dashboard access § 6](dashboard-access-admin-guide.md#6-giving-someone-an-area-node) step 2.
3. **Colours** (`ChatPrimaryColor` for the title and name, `ChatSecondaryColor` for the `-{ }-` brackets, `NameColor`
   for the tab list; how to add them to the form: [rank display spec § 7](../../specs/user-features/RANK_DISPLAY.md#7-admin-how-to-editing-the-colors-in-the-web-app)):
   Minecraft `&` codes only, such as `&e` or `&6&l`. They only show for Default and premium tiers (§ 2). If the form configuration doesn't carry the colour fields,
   saving the group may blank them (PandiO/knk-workspace#465): check the colours after a save.
4. Changes to a group's nodes or settings are **not** in the audit log (PandiO/knk-workspace#464).

## 4. Permission nodes and the escalation guard

**How a node is decided.** A player's own grants come first, then their groups in precedence order (a group before
its parents, heavier groups first). The first holder with a matching grant decides. Within a holder the most specific
match wins (the exact node, else the longest `prefix.*`), and a deny beats a grant of the same specificity. `*` matches
everything. Nothing matching means no. Details: [plugin permission checks § 2](../../architecture/plugin-permission-checks.md).

1. Use a **deny** to take one node away from someone whose group grants it, for example a deny of
   `customenchantments.use.chaos` on a player whose rank holds `customenchantments.use.*`.
2. Prefer a wildcard that covers only what you mean: `knk.admin.*` covers every admin node, bulk delete included.
3. Hiding a command from `/knk help` and tab completion follows the same nodes; every command still checks when run.

**The escalation guard** (web app and API) limits what you can hand out:

1. **A node** (grant, deny or revoke): you must hold it yourself, and you can't change your own permissions.
2. **A group** (add or remove a membership): the group must weigh less than your own heaviest group, and you must hold
   every node it and its parents grant. Holders of `knk.admin.user.group.premium` can hand out premium tiers without
   holding the tiers' own nodes.
3. **A group's definition** (nodes, name, weight, parent, delete): only groups below your rank, also after the change.
4. **Bulk delete** (`knk.admin.delete.bulk` and every wildcard covering it) is owner-only.

The rank rule and the bulk-delete rule are explained in [dashboard access § 5](dashboard-access-admin-guide.md#5-ranks-above-and-below-you-the-escalation-guard).

**In game the guard doesn't apply.** `/knk user` and the Player manager check only their own node and that you outrank
the player, not which node or group you hand out. A staff member with `knk.admin.user.perm` can so far grant nodes
they don't hold (PandiO/knk-workspace#469, not yet checked live). Until that is fixed, give `knk.admin.user.perm` and
`knk.admin.user.group` only to people you would trust with `*`, and check the audit log (§ 7).

## 5. Moderation tools

### 5.1 Freeze

| Where | How |
|---|---|
| Web app | Player profile → **Freeze** (top right, or the **Moderation** tab's Freeze card) → type a **Reason** (required, up to 200 characters) → **Freeze**. **Unfreeze** asks no reason. |
| In game | `/freeze <player> <reason…>`, `/unfreeze <player>` |
| Player manager | the Freeze / Unfreeze button; the reason is always "Frozen by a member of staff" |

1. Nodes: `knk.freeze`, `knk.unfreeze` (seeded on Staff, so Moderator and Admin have them on the alpha). In game you must
   outrank the player.
2. The freeze is stored on the player, so it works on offline players ("Froze X (offline - takes effect on next join).")
   and survives a relog and a server restart. With realtime on, a freeze from the web app applies in game within a
   second or two; without it, at the player's next join.
3. **What a frozen player can't do:** walk to another block, teleport themselves (ender pearls, portals, `/tpa`,
   warps), chat, use commands other than `/msg` and `/r` to staff, take damage. Flight is allowed while frozen so they
   aren't kicked for floating.
4. **What they still can do:** break and place blocks, open doors and containers, use their inventory, drop items and
   attack (PandiO/knk-workspace#463). Staff teleports still move a frozen player (PandiO/knk-workspace#309).
5. The player sees "You have been frozen: <reason>" and a red bar "Frozen by <you> for: <reason>". The bar says "staff"
   for the console, a vanished staff member and the web app, and sometimes for a named freeze too (#463).
6. The profile shows **Frozen** with "Frozen since … by …" and the reason; the audit log records **Player frozen** with
   the reason and **Player unfrozen**.

### 5.2 Staff mode and owner mode

1. `/staffmode [on|off] [onquit]` (`/sm`, node `knk.mode.staff`) and `/ownermode …` (`/om`, `knk.mode.owner`). Both hide
   you from everyone without a mode node: the tab list, the server list's sample and count, `/msg`, tab completion, and
   the join or leave message. Turning one on turns the other off.
2. The mode is saved and comes back on your next join. `onquit` (`oq`) changes it only for your next join, so you can
   come or go without a message. If your node was taken away meanwhile, the mode is switched off at join.
3. While in a mode you join where you logged out, are exempt from other staff's teleports, can't claim lootboxes, and
   bypass container-access region rules.
4. **Talking in public chat gives you away**: your line is shown as usual (PandiO/knk-workspace#466).
5. Staff can switch another online player's mode: Player manager → **Mode** (`knk.admin.user.mode`, staff mode only), or
   the web profile's **Moderation** tab (**Visible (no mode)**, **Staff mode**, **Owner mode**). Each change is audited
   (**Vanish toggled**).

### 5.3 Staff chat, social spy and the private-message log

1. **`/staffchat <message>`** (`/sc`, `knk.staffchat`) sends one line, `[Staff] name: message`, to every online holder of
   the node. It isn't a channel you stay in, and it isn't logged anywhere (PandiO/knk-workspace#466).
2. **`/socialspy [on|off]`** (`/spy`, `knk.socialspy`) shows other players' private messages as `[Spy] Alice -> Bob: …`
   (`[Spy][ignored]` when the receiver ignores the sender). It is **on by default** and kept across restarts. Private
   messages to or from a holder of `knk.socialspy.exempt` (the owner) reach only spies who hold it too.
3. **The private-message log**: every `/msg` and `/r`, with whether it was delivered or blocked (ignored, rate-limited,
   frozen), is kept 30 days, on the game server (`plugins/KnightsAndKings/logs/private-messages-<date>.log`) and in the
   API. Read it on the player profile's **Privacy** tab (needs `knk.pmlog.read`, which no rank holds on the seed data:
   the owner only). Every read is audited (**Private messages viewed**).
4. Related nodes: `knk.msg.bypass.ratelimit` (no message rate limit), `knk.msg.bypass.ignore` (messages reach players who
   ignore you), `knk.msg.unignorable` (can't be ignored).

### 5.4 Kick and ban

1. The Player manager's **Kick** and **Ban** buttons (after **Confirm**) run the server's own `/kick` and `/ban` as you,
   with the text "You were kicked by a member of staff." / "You were banned by a member of staff.". You can also type
   `/kick` and `/ban` yourself.
2. They need the vanilla permissions `minecraft.command.kick` / `minecraft.command.ban`, which KnK groups can't grant:
   **in practice only ops can kick or ban** (PandiO/knk-workspace#460). A non-op gets the server's own refusal.
3. They have no KnK node, no KnK rank check and no KnK audit entry (#460). The web app can't kick or ban: the
   profile's **Kick and ban** card says so. Lift a ban with the server's `/pardon`.
4. A staff member with `knk.notify.joinattempt` gets a chat line when a banned player tries to join.
5. There is no mute; freeze is the way to stop someone chatting (PandiO/knk-workspace#466).

### 5.5 Other staff actions on a player

Balances, XP and titles, salary payouts, kits, inventories, teleports and game mode are in the [commands
reference § Staff and admin commands](../users/commands.md#staff-and-admin-commands). In the Player manager, balance
clicks are collected until you close the menu and type the reason in chat.

## 6. The Player manager (in game)

`/menu` → **Player manager** (needs `knk.admin.user.manage`). It lists the online players you outrank; holders of
`knk.admin.user.manage.all` see every account, offline ones too, and can search. Click a player for:

| Button | Node | Rank check |
|---|---|---|
| Coins, gems, XP steppers (reason typed in chat) | `knk.admin.user.coins`, `.gems`, `.xp` (raising XP needs all three) | menu only (PandiO/knk-workspace#315) |
| Title (sets XP to the title's minimum, confirmed) | `knk.admin.user.xp` (and coins and gems to raise) | menu only |
| Groups (ranks as a confirmed switch) | `knk.admin.user.group` | yes |
| Mode (visible or staff mode; the player must be online and hold the mode node) | `knk.admin.user.mode` | yes |
| Pay out salary | `knk.admin.user.salary` | yes |
| Freeze / Unfreeze | `knk.freeze` / `knk.unfreeze` | yes |
| Kick, Ban (confirmed) | vanilla, ops only (§ 5.4) | menu only (#460) |

"You can only manage players ranked below you." means you don't outrank them. How the menu is built: [inventory menus
(admin)](menus-admin-guide.md).

## 7. The audit log

1. **Where:** the player profile's **Activity** tab: **Timeline** (audit entries and, with `knk.admin.currency.history`,
   balance changes, newest first, with filter chips) and **Audit log** (a table: When, Action, By, Details, 25 per
   page, an **Action** filter). **Player moderation → Recently demoted** lists title demotions. There is no audit page
   across all players. Reading needs `knk.admin.user.manage`. Entries are kept 180 days.
2. **Recorded, with who did it:** group assigned and removed (also by the one-rank rule), grants added, changed and
   removed **on a player**, title changes, balance adjustments with the reason, salary payouts, freeze and unfreeze
   with the reason, mode changes, kit grants, staff teleports, lootbox spawns and grants, discovery resets, currency
   reversals and payment locks, private-message log reads, invitations, Minecraft link changes, admissions, dashboard
   bulk deletes and exports. A change made by the system (an expiry) has no actor ("system").
3. **Not recorded:** changes to a group's nodes and settings (#464), kick and ban (#460), staff chat, social spy
   toggles and ignore lists (#466).

## 8. Nodes in this guide

| Node | Allows | Seeded on (alpha) |
|---|---|---|
| `knk.admin.user.manage` | Player moderation, player profiles, the Player manager, the audit log | Staff |
| `knk.admin.user.manage.all` | Act on every player regardless of rank; see every account in the Player manager | the owner (`*`) |
| `knk.admin.user.group` | Add and remove group memberships | Staff |
| `knk.admin.user.group.premium` | Hand out premium tiers without holding their nodes | no rank |
| `knk.admin.user.perm` | Grant, deny and revoke nodes; create and edit groups | Staff |
| `knk.admin.user.mode`, `knk.admin.user.salary`, `knk.admin.user.coins`, `.gems`, `.xp`, `.info`, `.history` | The Player manager and `/knk user` actions of that name | Staff |
| `knk.freeze`, `knk.unfreeze` | Freeze and unfreeze | Staff |
| `knk.mode.staff`, `knk.mode.owner` | Staff mode, owner mode; seeing vanished staff; `[STAFF]` / `[OWNER]` in chat | Staff; the owner |
| `knk.staffchat`, `knk.socialspy` | Staff chat, social spy | Staff |
| `knk.socialspy.exempt` | Your private messages stay hidden from spies without it | the owner |
| `knk.pmlog.read` | Read the private-message log | the owner only |
| `knk.notify.joinattempt` | A chat line when a join is refused | Staff |

"Seeded on" follows the [commands reference](../users/commands.md) and the seed migrations; check your database
before relying on it.

## 9. Safe test procedure

On the dev server, with test accounts: the owner, an Admin, a Staff member, a Default player and a second Default player.

1. **Groups and ranks:** as the Admin, give the player Royal with an end date a few minutes ahead in the web app. In
   game their chat shows `-{Royal …}-` and their name turns aqua within seconds; after the end date (plus up to 30 s)
   they are back on Default. Then try to give a group that weighs as much as Admin: "You can only hand out or remove
   groups ranked below your own."
2. **Escalation in game (#469):** as Staff, try `/knk user <player> perm grant knk.admin.health` on the test player
   and report what happens on the issue; revoke it afterwards.
3. **Freeze:** follow the [player profile smoke test § 2](../player-profile-smoke-test.md#2-freeze-and-unfreeze); also
   freeze in game and from the Player manager, and check the audit log.
4. **Messages:** as the two players, `/msg` each other while Staff has social spy on; `/ignore`; send 6 messages in 5
   seconds. Check the **Privacy** tab as the owner.
5. **Staff mode:** as Staff, `/sm on`: the player no longer sees you in the tab list or the server list; `/sm off
   onquit`, relog: no join message.

Never test kick and ban on a real player. For dashboard rights use the [dashboard access smoke test](../dashboard-access-smoke-test.md).

## 10. Common problems

| You see | Why | What to do |
|---|---|---|
| "You cannot act on a player of equal or higher rank." | You don't outrank the player | Ask someone of a higher rank |
| "You can only manage players ranked below you." | The same, in the Player manager | As above |
| "You can't grant a permission you don't have." | Escalation guard (web) | Ask someone who holds the node |
| "You can only hand out or remove groups ranked below your own." | The group weighs as much as your rank or more | Ask someone ranked higher |
| "You can't hand out a group with permissions you don't have." | The group or a parent grants a node you lack | Ask someone ranked higher; for premium tiers, `knk.admin.user.group.premium` |
| "You can't change your own permissions." | Only `*` can | Ask another staff member |
| "Only the owner can hand out bulk delete." | The node or group covers `knk.admin.delete.bulk` | Only the owner |
| "expiresAt must be in the future (omit it for a permanent membership)." | The end date is in the past | Fix the date or clear it |
| "No PermissionGroup named 'X'." | `/knk user … group` with a wrong name | Check the name on the dashboard |
| "Default is the base rank - pick another rank to replace it." | Removing Default in the Player manager | Give another rank instead |
| A node change in the web app doesn't work in game yet | The 30-second permission cache | Wait, or `/knk cache refresh` |
| A grant you made is gone the next day | The web app's expiry defaults to one day | Grant again with **Clear** on the expiry |
| Colours of a Staff group don't show | Only Default and premium tiers' colours are used | PandiO/knk-workspace#260 |
| "The /kick command isn't available." or the server's own refusal | Kick and ban need vanilla op permissions | Ask an op (#460) |
| Frozen player still breaks blocks | Freeze doesn't cover building and interaction | Known gap #463 |
