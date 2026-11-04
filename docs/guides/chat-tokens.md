# Chat tokens (#hand, #stats, #kills, …) — guide and smoke test

**Status:** Written 2026-11-04 for the `claude/chat-tokens-233` branches; not merged, not run in game
**Last updated:** 2026-11-04
**Issue:** [PandiO/knk-workspace#233](https://github.com/PandiO/knk-workspace/issues/233) (decisions in the
[issue comment](https://github.com/PandiO/knk-workspace/issues/233#issuecomment-6630208467) and below)
**Branches:** `claude/chat-tokens-233` in knk-plugin (on `main` `8f11bed`), knk-web-api (on `master` `c4c7772`),
knk-web-app (on `main` `603843d`) and knk-workspace (these docs). Two API migrations (one nullable column, one data-only
node seed); deploy the API before the plugin.

## 1. What players get

A player types a token in public chat, a private message (`/msg`, `/r`) or staff chat. The token becomes a value in
`[brackets]`, and hovering it shows the details. The rest of the message is unchanged, and one message can contain several tokens.

| Token | Shows | Hover |
|---|---|---|
| `#hand` | `[item name]` (and `x3` for a stack) | the item's own tooltip: name, lore, enchantments, custom enchantments |
| `#stats` | `[Steve's stats]` | title, XP, coins/gems, playtime, and kills, deaths, K/D, best streak, wins and discoveries when public |
| `#kills` | `[12 kills]` | player kills per context (open world, Siege), creature kills when public |
| `#deaths` | `[4 deaths]` | deaths |
| `#kd` | `[K/D 3.00]` | player kills per death; no deaths = the kill count |
| `#streak` | `[best streak 7]` | highest killstreak |
| `#wins` | `[5 wins]` | wins per minigame, losses and draws when public |
| `#playtime` | `[3h 25m played]` | active and AFK time, first join |
| `#balance` | `[5,600 coins]` | coins and gems |
| `#title` | `[Knight]` | title |
| `#xp` | `[1,234 XP]` | experience |
| `#discoveries` | `[12 discoveries]` | towns, districts, structures |
| `#location` | `[world 120, 64, -30]` | world and block coordinates (typing it is the opt-in) |
| `#tokens` | nothing | the list of tokens the sender may use, shown only to them; a message that is only `#tokens` isn't sent |

**Someone else's statistics:** `#kills@Steve` (token first, then `@name`). Works for online and offline players.
Unknown names stay as typed. The label names the player: `[Steve: 12 kills]`.

**What text counts as a token:** names are case-insensitive. A token glued to a word (`abc#hand`, `#handy`), a colour code
(`&#FF0000`), an unknown name (`#lol`), or a broken target (`#kills@`) stays as typed. `#hand`, `#location` and `#tokens`
don't take a target.

## 2. Privacy: the same as `/stats <player>`

A statistics token shows what `/stats <player>` shows another signed-in player: the always-public profile (title, XP,
coins/gems, playtime) plus only the metrics the player set to *everyone* (`/stats settings`). Kills, deaths and the other
metrics stay **private by default**: knk-web-api has no stored setting = Nobody (`StatisticsVisibilityRules`, player-statistics
DESIGN § F.4). To get that view also for the player themselves, the plugin reads
`GET api/statistics/users/{id}?audience=public`.

- **Someone else's private statistic** shows as `[Steve: player kills private]`.
- **Your own private statistic:** the message is held and only you see
  `Your player kills is private, so your message wasn't sent yet. [Make public & send] [Send without] [Never ask]`.
  - *Make public & send*: sets that setting to *everyone* (metric level and any hidden per-context override), then sends.
  - *Send without*: sends once with the token as plain text.
  - *Never ask*: sends with plain text now and never asks again for that setting. This is stored per player in
    `plugins/KnK/chat-token-consent.yml` on that server. `/stats settings` still changes the visibility.
  - The buttons work for 60 s and are clicked, not typed (`/chattoken <id> <public|plain|never>`).
  - A held message goes out when answered, so it lands after messages sent in between.

## 3. Limits and permissions (admins)

- **Game Settings page → Chat Tokens** (web app): *Most tokens per message* (0–20) and *Cooldown for statistics tokens
  (seconds)* (0–3600). Both **0 = off, the default**. Tokens over the limit stay as typed. Within the cooldown, statistics tokens
  are sent as text and the sender is told how many seconds are left. Item, location and help tokens have no cooldown.
- **Nodes:** `knk.chat.token.<name>` per token (e.g. `knk.chat.token.location`). The API migration `SeedChatTokenNodes`
  grants `knk.chat.token.*` to the Default group, so everyone has every token. A deny grant takes one away from a group.
  `knk.chat.tokens.bypass` (Staff, Moderator, Admin) skips both limits. It is deliberately outside `knk.chat.token.*`.

## 4. How it works (plugin)

- Registry and pure logic in `knk-core/.../core/chat/tokens/`:
  - `ChatToken` (the token list and nodes) and `ChatTokenParser` (one regex; tokens are found on the Adventure component, so colour codes don't matter).
  - `ChatTokenViews` (label and hover lines from the public statistics view).
  - `ChatTokenCooldowns` and `ShareConsent`.
- Paper glue in `knk-paper/.../paper/chat/tokens/`:
  - `ChatTokenService` (expand, resolve, share prompt).
  - `ChatTokenListener`: public chat at HIGH, `ignoreCancelled`, so chat-capture and world-task prompts never expand tokens. It also prefetches statistics on join.
  - `ChatTokenExpander`, used by `MessagingService` and `StaffChatCommand`.
  - `ChatStatisticsCache`, `ShareConsentFile` and `ChatTokenCommand`.
- `PlayerListener.onChat` now renders the chat line from the event's final message, so the token listener can replace it.
- **Speed:** statistics come from a per-player cache of the public view, read at most every 60 s (the plugin uploads
  statistics every 60 s) and warmed on join. On a miss, chat (an async thread) waits at most 1 s per value. A value
  that isn't there by then stays as typed. Chat order is kept. Item and position are read on the main thread.
  Kills from the last upload window (≤ 60 s) aren't shown yet. Adding them locally was dropped because it double-counts
  around an upload.

## 5. Smoke test

Setup: API on `claude/chat-tokens-233` with `dotnet ef database update` (adds `game_settings.ChatTokenSettingsJson`
and the node seed), the web app and the plugin from the same branch. Two players, A and B (B not staff). A has
some kills and deaths.

| # | Step | Expected |
|---|---|---|
| 1 | A holds an enchanted, renamed sword with lore; types `look #hand` | `look [name]`; hover shows the full item tooltip (also for B) |
| 2 | A types `#hand` with an empty hand | `#hand` as plain text |
| 3 | A types `&cred #hand and #xp` | colour kept; both tokens replaced |
| 4 | A types `#tokens` | nothing in public chat; A sees the token list |
| 5 | A (kills private) types `gg #kills` | message not sent; A sees the three buttons |
| 6 | A clicks *Send without* | `gg #kills` sent as plain text; next `#kills` asks again |
| 7 | A types `#kills`, clicks *Make public & send* | sent as `[n kills]`; `/stats A` from B now shows player kills; `/stats settings` shows Everyone |
| 8 | A types `#deaths`, clicks *Never ask*; then types `#deaths` again | plain text both times, no second prompt |
| 9 | B types `#kills@A` and `#deaths@A` | `[A: n kills]` with hover; `[A: deaths private]` |
| 10 | B types `#stats@A`, `#playtime@A`, `#balance@A` | values with hovers; `#stats` hover lists only public metrics |
| 11 | B types `#kills@NoSuchPlayer`, `#hand@A`, `#lol` | all plain text |
| 12 | A logs off; B types `#xp@A` | still shown (offline lookup) |
| 13 | `/msg B #hand` and `/r #xp` | expanded for both sides and for social spy |
| 14 | Staff: `/sc #hand #kills` | expanded for staff-chat recipients |
| 15 | Game Settings → Chat Tokens: max 1, cooldown 10; save. B types `#xp #title` | `[xp] #title`; a second statistics token within 10 s is text with a "can be used again in" note |
| 16 | Staff with `knk.chat.tokens.bypass` repeats 15 | no limits |
| 17 | Deny `knk.chat.token.location` on the Default group; B types `#location` | plain text; `#tokens` no longer lists it |
| 18 | Start a world-task chat prompt (or another chat-capture prompt) and answer with `#hand` | the answer is taken as typed, not expanded |
| 19 | Stop the API; A types `#kills` | after about 1 s the line is sent with `#kills` as text; no error to the player |
