# Ranks, titles and chat — player guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#301)
**Checked against:** knk-plugin `main` `57884e97`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d`; not
yet checked in game
**Related:** [player handbook](player-handbook.md), [commands reference](commands.md), [chat tokens](../chat-tokens.md),
[menus](menus-player-guide.md), [statistics and public profile](statistics-player-guide.md); for staff: [ranks,
permissions and moderation (admin)](../admin/ranks-permissions-moderation-admin-guide.md)

What your rank, premium tier and title mean, how chat looks and works, and how private messages, ignoring and staff
oversight work. Everything here is for every player unless it says otherwise.

## 1. Rank, premium tier and title: three different things

| | What it is | How you get it | Where you see it |
|---|---|---|---|
| **Title** | Your standing, from your experience (XP): Serf, Peasant, … Knight or Dame, … King or Queen, One of the Seven | Play: XP comes from discoveries, sieges, rewards and more | Chat, the tab list's footer, `/stats`, your profile (your head in `/menu`), the website |
| **Rank** | Which commands and perks you have. Every player starts on **Default** | Default is automatic. **Alpha Tester** comes with an invitation to the closed alpha | Nowhere by name; you notice it in what you can use |
| **Premium tier** | A paid rank on top of Default's perks: **Noble**, **Royal**, **Dragon Blood** | Given by staff. There is no shop for it in the game or on the website yet | Chat, your name's colour, the tab list's footer, the **Premium tiers** tile in `/menu` |

Staff have their own ranks (Staff, Moderator, Admin) and the owner sits above them; see § 4.

## 2. Titles and XP

1. Your title follows your XP: you hold the highest title whose XP you have reached. On the seed data the first title,
   **Serf**, starts at 0 XP, **Peasant** at 2,500, **Knight / Dame** at 10,000 and the last, **One of the Seven**, at
   160,000. The full list with the XP each needs is in your profile (`/menu` → your head → titles): reached titles have
   `✔`, your current one glows, and each shows "Required XP", "Salary" and its promotion bonus.
2. Titles have a male and a female name (Knight / Dame, King / Queen). You get the female name when your account's
   gender is set to female; otherwise the male name. There is no screen or command to set it yourself yet.
3. **Promotion.** When your XP passes a title you get "✦ Promoted! ✦" with the old and the new title, a sound and
   particles, and a one-time **title bonus** in coins, gems and XP, paid once per title ever. Passing several titles
   at once says so ("N tiers at once!"). If you were offline, you see it when you next join.
4. **Demotion.** Staff can lower your XP. You then see "Demoted" with the old and new title. A title's bonus is paid only once ever, so
   reaching the same title again pays nothing.
5. **Prestige XP.** Past the last title, extra XP counts as prestige XP. It shows in the tab-list footer
   (`(+N prestige XP)`) and in your profile. It has no levels or rewards yet.
6. **Salary.** Each title pays a salary in coins about once an hour while you play: "Salary (Knight): 4800 ×1.2 Royal =
   +N coins". Your premium tier and any personal bonus multiply it. Time offline counts too, but less for each hour
   away (a day away pays about four hours) and nothing after 30 days.
7. Some kits, warps and sieges need a certain title ("You need at least the title T to join X.").

## 3. Premium tiers

1. The tiers, lowest first: **Noble**, **Royal**, **Dragon Blood**. You hold one rank at a time: getting a premium tier
   replaces Default, a higher tier replaces a lower one, and when a tier ends you go back to **Default** (not to the
   tier you had before).
2. **What a tier gives** (on the closed alpha's seed data):
   1. A salary multiplier: Noble ×1.1, Royal ×1.2, Dragon Blood ×1.5.
   2. Chat and name colours (§ 5) and the tier's name in front of your title in chat.
   3. Lootbox tokens when the tier starts (if staff set any up for it).
   4. Commands: `/siege skip` (Noble), `/tpahere` and `/back` (Dragon Blood). Whether Royal and Dragon Blood also get
      Noble's perks depends on the server's data: on the dev seed they do; a server built from scratch gives each tier
      only Default's perks plus its own. That is an open decision (PandiO/knk-workspace#430); see the [commands
      reference § How access works](commands.md#how-access-works).
   5. Teleport prices, warmups and cooldowns can differ per tier, and some warps and premium kits need a tier.
3. A tier can be permanent or end on a date. The tab-list footer shows it, with "(until yyyy-MM-dd)" when it ends.
   The **Premium tiers** tile in `/menu` lists every tier with its salary multiplier, and yours.
4. When staff change your rank in game you see "✦ Your rank is now Royal!". A change made on the website, or a tier
   that runs out, shows only in your colours and tab list, without a message (PandiO/knk-workspace#466).

## 4. Staff ranks and the owner

1. **Staff**, **Moderator** and **Admin** are staff ranks; each has everything of the one below it. The **owner** holds
   every permission. Staff ranks don't replace your Default or premium rank: a staff member has both.
2. Staff and the owner show `[STAFF]` or `[OWNER]` in front of their name in chat, and their name is blue (staff) or
   dark purple (owner) in the tab list (PandiO/knk-workspace#466 asks whether that should follow their mode instead).
3. **Staff mode and owner mode** hide staff from players: they are gone from the tab list, the server list's player
   count and `/msg`, and no join or leave message is shown. Commands treat them as offline ("No online player named
   '…'."). Other staff still see them.
4. Staff can't be ignored ("You can't ignore staff."), and some staff tools can't be used on a staff member of the
   same or a higher rank.

## 5. Chat

### 5.1 What a chat line looks like

| Who | Chat line |
|---|---|
| A player on Default | `-{Knight}- Alice: Hello` |
| A premium player | `-{Royal Knight}- Alice: Hello` (the tier's name before the title) |
| Staff | `[STAFF]-{Knight}- Alice: Hello` (title in bold) |
| The owner | `[OWNER]-{King}- Alice: Hello` |

1. **Colours.** The brackets and the name/title have the colours of your premium tier, or Default's: on the seed data
   Default is green, Noble yellow and gold, Royal aqua and blue, Dragon Blood red. Your message takes your name's colour.
   Staff and owner lines have fixed colours. A staff group's own colours aren't used yet (PandiO/knk-workspace#260, in
   review, not merged).
2. Your first letter is capitalised.
3. **Colour codes.** You can colour your message with `&` codes, for example `&cred` or `&lbold` (PandiO/knk-workspace#466
   asks whether this should need a permission). Private messages are always plain text.
4. **Mentions.** A player whose name is in your message hears a ping (at most one every 5 seconds per player).
5. **Chat tokens.** Type `#hand`, `#location`, `#stats`, `#kills`, `#title` and more to show your held item, your
   position or a statistic; others hover over it for the details. `#tokens` lists them (only you see that list). If a
   token would show a statistic you keep private, your message waits and you choose **Make public & send**, **Send
   without** or **Never ask**. Add `@name` to show another player's public statistic: `#kills@Bob`. Tokens work in
   public chat, private messages and staff chat. Details: [chat tokens](../chat-tokens.md).
6. **Join and leave messages** ("Alice joined the server.") are set by the server and can differ per rank.

### 5.2 The tab list

Your name in the tab list has your rank's colour: owner dark purple, staff blue, premium players their tier's colour,
everyone else Default's (grey on the seed data). The tab list shows only 16 colours, so a custom shade is rounded to the
nearest. `[AFK]` follows the name of a player who is away (`/afk`, or 5 minutes idle), and `[Siege]` that of a player in
a siege. The footer shows your own title, prestige XP and premium tier.

## 6. Private messages

1. `/msg <player> <message>` (also `/tell`, `/w`, `/m`, `/pm`, `/whisper`, `/message`). You see `[me -> Bob] hi`, Bob sees
   `[Alice -> me] hi` and a sound. Click a message to answer. Messages longer than 256 characters are cut.
2. `/reply <message>` (`/r`) answers the last player you messaged or who messaged you. "Nobody to reply to." means there
   is no one yet; "Bob is no longer online." that they left.
3. You can only message players who are online. A player in staff mode reads as offline, unless they messaged you
   first: then `/r` reaches them.
4. **Slow down.** At most 5 messages in 5 seconds, and the same text to the same player within 10 seconds counts as
   spam: "Slow down — you can send another message in Ns."
5. **Moderators can read private messages.** Every private message is logged for 30 days, and staff with social spy
   see them as they are sent (§ 8).

## 7. Ignoring a player

1. `/ignore <player>` hides that player's private messages **and** their public chat from you, and their mentions don't
   ping you. It works on offline players too. They aren't told: their private message seems sent to them, but you
   never get it.
2. `/ignore` without a name lists who you ignore and since when. `/ignore <player>` again, or `/unignore <player>`,
   stops ignoring them.
3. You can't ignore yourself or staff. A full list says "Your ignore list is full - /unignore someone first."
4. Your list is kept on the server, so it survives a relog.

## 8. What staff can see and do

So you know what to expect:

1. **Social spy.** Staff with social spy see private messages between other players as they are sent, also between
   players who ignore each other.
2. **The private-message log** keeps every private message for 30 days. On the seed data only the owner can read it on the website,
   and each read is logged.
3. **Freeze.** Staff can freeze a player who breaks the rules: you then can't walk away, chat, use commands or take
   damage, and a red bar shows who froze you and why ("You have been frozen: <reason>"). You can still message staff
   with `/msg` and `/r` ("You can only message staff while frozen."). A freeze lasts until a staff member lifts it, also
   across a relog ("You have been unfrozen.").
4. **Kick and ban** are the server's own `/kick` and `/ban`.
5. There is no mute: a player who must stop chatting is frozen (PandiO/knk-workspace#466).

## 9. Messages you may see

| Message | Meaning |
|---|---|
| "No online player found named '…'." | The player is offline, in staff mode, or doesn't exist |
| "You can't message yourself." | — |
| "Slow down — you can send another message in Ns." | The message rate limit (§ 6.4) |
| "You can only message staff while frozen." | You're frozen; only staff can be messaged |
| "You are frozen and cannot chat." / "You are frozen and cannot use commands. You can still /msg staff." | You're frozen (§ 8.3) |
| "You can't ignore staff." | Staff can't be ignored |
| "Your ignore list is still loading - try again in a moment." | You've only just joined |
| "Statistics tokens can be used again in Ns; they were sent as text." | Chat token cooldown ([chat tokens](../chat-tokens.md)) |
| "That command is disabled." | `/me` and `/teammsg` are turned off on this server |
