# Arena duels — admin setup and player guide

**Status:** Draft for the live test · **Last updated:** 2026-10-25 (P9: battlegrounds, spectator areas and the lobby are arena areas, not domains; spectate teleport; DESIGN rev. 6) · [KNG-197](https://linear.app/kngpandi/issue/KNG-197), guide from [KNG-222](https://linear.app/kngpandi/issue/KNG-222)

**Branch only.** Arena duels are on the `claude/arena-duels` branches of knk-web-api, knk-web-app and knk-plugin (all three include their trunk as of 2026-10-25; the plugin's trunk `main` has Minecraft 26.3 since KNG-182 merged). Nothing is merged or live-tested yet. Check the [feature register](../FEATURE_REGISTER.md) before treating anything here as shipped.

**Background:** [DESIGN](../specs/arena-duels/DESIGN.md) (rules and the reasons for them), [IMPLEMENTATION_PLAN](../specs/arena-duels/IMPLEMENTATION_PLAN.md), the [chain report](../reports/2026-10-21-arena-duels-chain.md) (what each phase built, deviations), and the [smoke-test checklist](arena-duels-smoke-test.md).

Contents: [1. What duels are](#1-what-duels-are) · [2. Admin setup](#2-admin-setup) · [3. Reviews, restrictions and the review policy](#3-reviews-restrictions-and-the-review-policy) · [4. Staff commands](#4-staff-commands) · [5. Player how-to](#5-player-how-to) · [6. Troubleshooting](#6-troubleshooting)

---

## 1. What duels are

Two players fight one-on-one on a battleground inside an arena. Before the fight they agree on stakes (coins and items) and a gear mode, in a short exchange of offers. When the invitee accepts, the stakes are taken from both players at once and held until the result. The winner gets the pot less the arena's fee. A draw or a cancel gives each player back exactly what they put in.

- **Where:** an arena is a structure (an `Arena` domain). Inside it are its **areas**: one or more **battlegrounds** where the fights happen, a **lobby** where duelists wait, and optionally a **spectator area** (the stands). Duelists go to the arena's **exit** afterwards. Areas are not domains: walking in or out of one shows no message and gives no discovery; only the arena itself does.
- **Gear modes** (the arena decides which are offered):

  | Mode | What happens |
  |---|---|
  | Own gear, keep | You fight with your own gear and keep it, win or lose. |
  | Own gear, drop | You fight with your own gear. **The loser's whole inventory goes to the winner.** |
  | Fixed kit | Both fight with the kit named in the offer. Your own inventory is stored and given back afterwards. |
  | Kit choice | Each duelist picks a kit from the arena's list during the warmup. Your own inventory is stored and given back. |

- **A match:** accept → stakes taken → both teleport to the lobby (normal 5 s teleport warmup) → **warmup** in the lobby (30 s by default; kit pick in kit-choice mode) → wait for a free battleground → **countdown** on the battleground (10 s, frozen, no damage) → **fight** → result, a short linger for the winner, exit teleport.
- **PvP:** only the two duelists can hurt each other, and only during the fight. It works even when the arena is in a town that denies PvP. Nobody else can hit them, and they can't hit anyone else.

---

## 2. Admin setup

### 2.1 Before you start

- **Permissions**
  - Arena, arena area and area region forms: `knk.admin.world` (web app).
  - Duel review pages, the review policy and duel restrictions: `knk.admin.duel.review` (web app and `/knk duel review` in game). `knk.admin.*` includes it. It is not seeded into any group.
  - Staff duel commands (`/knk duel list|cancel|refund`) and the staff bypass of the duel teleport and command guards: `knk.admin.duel`.
  - Players: `knk.duel` (default true) for `/duel`, `/duels` and `/arena`.
- **Deploy** the three `claude/arena-duels` branches (API, web app, plugin). The API applies three migrations on start: `AddArenas`, `AddDuelMatches` and `ReplaceArenaChildDomainsWithAreas` (P9: drops the rev. 2–5 battleground and spectator-area tables, their domain rows and `arenas.LobbyLocationId`, and adds `arena_areas` and `arena_area_regions`; an arena made with the older branch keeps its settings but loses its battlegrounds, spectator areas and lobby point). On its first start it also adds the duel menu templates (`duel_matches`, `duel_match_detail`, `arena_main`, `duel_challenge`); these are create-only seeds, so they never overwrite a template you edited.
- **Import the form seeds** in the web app (**Import / seeds**), in this order: `ArenaKit.join`, `Arena`, `ArenaAreaRegion`, `ArenaArea`. (The `ArenaBattleground` and `ArenaSpectatorArea` seeds are gone; delete their form configurations if an older branch imported them.)
- **Kits** you want to offer in kit modes must exist already (the normal kit pages).
- **Plugin config** (`config.yml`, `duels:`) holds only technical knobs; everything about gameplay is set per arena in the web app. Defaults:

  ```yaml
  duels:
    enabled: true
    invite: { max-incoming: 3, send-cooldown-seconds: 10 }
    agreed-draw-window-seconds: 15
    command-allow-list: [/duel, /msg, /r, /staffchat]   # the only commands in the countdown and the fight
    item-blocklist: [WRITTEN_BOOK, BARRIER, COMMAND_BLOCK, STRUCTURE_VOID, DEBUG_STICK]
    refuse-filled-containers: true                       # shulker boxes and bundles must be empty to be staked
    announce: { cooldown-seconds: 120 }                  # one warmup broadcast per duelist per 2 minutes
    api-timeout-seconds: 10
    result-retry-seconds: 30
    held-refresh-seconds: 300
  ```

  The announcement texts can be changed under `duels.announce.templates` (the commented block in `config.yml` lists the placeholders). Restart to apply a change.

### 2.2 The arena domain

An arena is created like any other structure, in the web app's **Arena** form. There is no migration or seed for v1's `arena_2`: you create it in the form and point it at the existing WorldGuard region.

1. **General**: name, key (unique, e.g. `arena_2`), district and street, the region, the spawn point and the exit.
   - **Region:** for an existing region, type its id (`/rg list` in the arena's world; `arena_2` for the v1 arena). For a new one, use **Send to Minecraft** to draw a temp region; it is renamed `domain_<id>` when you save. Extra parts of the arena go in the last step's **Sub-regions** (KNG-253, as for any domain).
   - **Spawn point** is the arena's own Location. **Exit** is where duelists go after the match; empty means the spawn point. Use **Send to Minecraft** to capture each point where you stand. There is no lobby field any more: the lobby is an area (§2.5).
   - **Duels enabled:** off for a new arena (the form's default, and the API saves a new arena with it off when it isn't sent). Turn it on once the lobby area exists and at least one battleground is enabled (§2.7).
2. **Negotiation & stakes**: `MaxOffers` (1–6, default 3: offer, counter, final offer), `OfferSeconds` (60 per turn), coin and item stakes on or off, `MaxCoinStake` (10,000 per side), `MaxItemStacks` (9 per side), `MinStakeRatioPercent` (50: the smaller side's stake must be worth at least half the larger; 0 = off), `FeePercent` (5, range 0–20; taken only from the coin pot of a decisive result).
3. **Eligibility & abuse limits**: minimum account age and title for anyone staking (empty = the `/pay` rule), `MaxStakedDuelsPerPairPerDay` (3), `PairCooldownMinutes` (10), `DailyCoinWinCap` (25,000; 0 = off).
4. **Gear & kits**: which gear modes the arena offers (at least one), and the default mode (must be one of them). Drop mode is off by default.
5. **Eligible kits**: the kits offered in the two kit modes, in order. Drag to reorder. The first kit is the default in kit-choice mode, used when a player doesn't pick. A kit mode needs at least one kit. Kits skip their own requirements in the arena (title, cost, cooldown): the list is the only gate, so it doubles as a kit try-out. A kit an arena offers can't be deleted on the kit page until it is removed here.
6. **Timing & queue**: `WarmupSeconds` (30), `CountdownSeconds` (10), `FightTimeLimitSeconds` (300; 0 = no limit, at the limit the match is a draw with a full refund), `MaxWaitSeconds` (180 waiting for a free battleground, then cancel and refund), `WinnerLingerSeconds` (5), `MaxQueuedMatches` (3 accepted matches not yet on a battleground; the next accept is refused).
7. **Announcements**: `AnnounceMatches` (the arena's broadcast switch) and `AnnounceFriendly` (also broadcast duels without stakes).
8. **Battlegrounds, spectator areas and lobby**: the arena's **Areas** (owned list, added after the arena is saved, §2.3) and its **Sub-regions**.

The form refuses: no gear mode, a kit mode without kits, a default mode that isn't allowed, `MaxOffers` outside 1–6, a fee over 20, a ratio over 100, duels on without a usable lobby (§2.5), and a location in another world.

After saving, the region gets its place in the managed hierarchy at the next startup repair or `/knk regions repair`: the arena under its district, priority 40 (see [managed regions](../architecture/managed-worldguard-regions.md) §4–§5). The arena is a normal domain: entering it shows its name, gives the arena discovery, and it is a `/navigate` target.

### 2.3 Areas and their regions

Battlegrounds, the spectator area and the lobby are all **areas** of the arena, made in one form (**Arena area**, from the arena's last step or on its own):

1. **General**: the arena, the **kind** (`BATTLEGROUND`, `SPECTATOR` or `LOBBY`), a key (unique within the arena, e.g. `north`, `stands`, `lobby`), a name (shown in menus, the boss bar and messages; empty = the key), the order, and **Enabled** (off for a new area).
2. **Battleground spawns** (battlegrounds only): spawn A (challenger) and spawn B (opponent).
3. **Arrival and spectating** (spectator areas and the lobby): the **arrival location** where a teleport lands; for a spectator area also the **minimum title** and the **gem price** of the spectate teleport (§2.6).
4. **Regions**: one or more regions, added after the area's first save. Each is drawn with **Send to Minecraft** (a world task, like a domain's sub-region) or adopted by typing an existing id. On save the region is **renamed** `arena_<arenaId>_<kind>_<n>` (`battleground`, `spectator` or `lobby`; `n` is the region row's id). Running a region's world task again replaces that region in place.

Rules the API checks:

- Fields of another kind are cleared on save (a spectator area switched to a battleground keeps no arrival point). The kind can't be changed while the area has regions.
- At most one lobby per arena. Keys are unique within the arena.
- A region must be in the arena's world, and its id may not belong to any domain (main region or sub-region) or to another area. The arena's own region can't be added.
- Spawns and the arrival location must be in the world of the area's regions.
- An enabled battleground needs both spawns and at least one region; its last region can't be removed while it is enabled.

**The area is the union of its regions.** A battleground drawn as two parts (for example two boxes around an L-shaped floor) is one battleground: walking from one part into the other is not leaving it.

What the server does with area regions (after the repair, or right after the rename): parent = the arena's region; battlegrounds priority 50 with `pvp allow` and `entry allow`; spectator areas priority 50 (floor 40) with `entry allow`; the lobby priority 50 with `entry allow`. No `knk-allow-entry` or other domain flags: who may enter is decided by the duel runtime (§2.4–§2.6), not by WorldGuard. An area region no arena lists any more (its row, area or arena deleted) is unhooked after two checks and deleted by the daily temp-region cleanup after `regions.temp-retention.days` (14); `/knk regions temp` lists it until then, and it can be adopted again with its id.

### 2.4 Battlegrounds

Add one area of kind `BATTLEGROUND` per fighting floor:

- **Order** is the allocation order: the first free enabled battleground gets the next match.
- For v1's arena, adopt the existing ids of the eight flagged battlegrounds as their regions (`arena_2,<part>-battleground`; check with `/rg list`). They are renamed `arena_<id>_battleground_<n>`, and v1's `entry deny` is replaced by `entry allow` at the repair. The `regions.managed.extra-regions` entries for `arena_2` are not needed.
- Capture spawn A and spawn B with **Send to Minecraft**, then turn **Enabled** on.

Who may be on a battleground: nobody, except the two duelists of the match it is allocated to, from the countdown teleport until the exit teleport. Others are refused walking, riding, gliding, by pearl, chorus fruit or teleport ("This battleground is reserved for a duel."). The duelists can't leave during the countdown and the fight; the exit teleport at the end has its own pass. Duelists trying to walk, pearl or ride out get "You can't leave the battleground during a duel." Staff with `knk.region.bypass` can walk in to watch; the combat rule still keeps them out of the fight. Battlegrounds give no discovery reward, no enter/leave message and are not `/navigate` targets.

### 2.5 The lobby

Exactly one area of kind `LOBBY`, with a region over the waiting room and an **arrival location** (where both duelists land after the accept). It must be **enabled and have an arrival location** before duels can be turned on, and while duels are on it can't be disabled, lose its arrival or be deleted.

While a match of this arena is in its warmup, only duelists of the arena's matches (and `knk.region.bypass` staff) may enter the lobby; everyone else is refused ("The arena lobby is reserved for the duelists during a warmup."). Otherwise it is open. A player already standing in the lobby when a warmup starts is not moved out.

### 2.6 The spectator area and the spectate teleport

A spectator area is optional (0..n per arena; normally one). Without one, players can still watch from wherever they can see the battlegrounds, but **Spectate** buttons are disabled.

- Draw the stands as the area's regions. They are free to walk into for everyone.
- Set the **arrival location** to make the area reachable by teleport. Optional conditions of that teleport: **Minimum title to spectate** and **Spectate price (gems)**. They apply only to the teleport, not to walking in.

**Spectate** in the arena menu (`/arena`), the **[Spectate]** button in the warmup broadcast, **Go to the spectator area** in a match's detail and `/duels spectate <arena>` all start the same teleport: the normal teleport warmup (cancelled by moving or damage), no cooldown. Which area: the arena's first enabled spectator area (by order) with an arrival location. If the area has a title or price, the plugin asks the API first: a player below the title is refused with the reason and nothing is charged; otherwise the gems are charged before the warmup ("Paid 5 gems to watch; refunded if you don't arrive.") and refunded when the teleport doesn't happen. Staff with the teleport bypass nodes (`knk.teleport.bypass.requirements`, `knk.teleport.bypass.cost`) skip them, as for warps. Duelists can't spectate during their own duel. The stands are not in `/warp` (a future improvement, [KNG-240](https://linear.app/kngpandi/issue/KNG-240)).

Players standing in the stands (or anywhere in the arena: its region, its sub-regions or any area) see the arena's duel sidebar while a match is live, and the boss bar of the newest fight.

### 2.7 Turning it on and a first test

1. Create the lobby (enabled, arrival, region), enable at least one battleground with both spawns and a region, set the exit, then turn **Duels enabled** on and save.
2. Restart the game server (or `/knk regions repair`) so the regions get their parent, priority and flags. Check with `/rg info` on a battleground region: name `arena_<id>_battleground_<n>`, parent the arena's region, priority 50, `pvp allow`, `entry allow`, no `knk-allow-entry`.
3. With two accounts, stand inside the arena and run `/duel <other player> quick`; accept from the chat line. Follow the match to the exit. The full test is the [smoke-test checklist](arena-duels-smoke-test.md).

The plugin reads arenas through a cache (15 minutes); a new invite refreshes the arena first, so a settings change applies to the next negotiation. A match keeps the settings it was accepted with, including the fee.

### 2.8 Hub menu

There is no hub tile for duels yet. Players use `/arena` and `/duels`. If you want a tile, it is a small change to the hub menu seed (an `OpenTile` to `duel_matches`), or add one through the menu editor.

---

## 3. Reviews, restrictions and the review policy

Duels can be thrown to move coins or items between accounts. The rules make that expensive (fee, ratio rule, pair limits, daily cap, eligibility), and suspicious results are flagged for staff. All of this is in the web app under **Duels** (`/admin/duels`; the **Duels** button on Player moderation). It needs `knk.admin.duel.review`.

### 3.1 Flags and holds

**Who sees the verdict** (developer, 2026-10-21): the signals, their numbers and the tier are shown only to staff with `knk.admin.duel.review` (and the game server). Players see a match's plain review state (none, flagged, held, released, voided) and its result. Duel announcements stay public, subject to the arena's toggles.

Only value-moving results are scored: coin or item stakes, or drop mode. Friendly duels never are. The API looks at the fight's telemetry and the players' history:

| Signal | Means |
|---|---|
| S1 one-sided damage | the loser dealt under 10% of the winner's damage |
| S2 short fight | under 10 s |
| S3 unarmed loser | own-gear mode, the loser had no weapon and no armour |
| S4 passive loser | the loser never swung |
| S5 one-way pair | the same player won the pair's last 3 value-moving duels |
| S6 funnel | the winner took value from 3+ different young accounts (under 7 days) within 7 days |

- **Tier 1, flagged:** any signal. The result is **paid**, marked Flagged, and a `DUEL_FLAG` alert appears on the currency alerts page and in game for staff with the alerts node.
- **Tier 2, held:** the same pair (either direction), or the same winner against different opponents, collects 2 flags within 7 days. **Nothing is paid** until staff release or void it, and a `DUEL_HOLD` alert appears. While the hold is open, new staked duels between that pair (or with that winner) are refused; friendly duels still work. Both players are told the result is pending review.
- **A first flag never holds**, however large the pot.
- **Acknowledging** a `DUEL_FLAG` alert on the alerts page means "false positive": that flag stops counting.
- The currency monitor also raises `R10` (one-way duel payouts within a pair).

### 3.2 Acting on a result

Open the match from the history (filters: arena, player, status, review) or from its alert's **Duel #id** link.

| Result | Action | Effect |
|---|---|---|
| Held | **Release** | paid as normal (pot less fee to the winner; items and spoils delivered) |
| Held | **Void** (reason required) | each side gets its own stake back, no fee; spoils go back to the loser |
| Paid | **Revert** (reason required) | the payout is taken back from the winner as far as their balance allows; the loser is refunded first; the fee is reversed. Undelivered items go back to their owners. The page shows what was recovered and what is **still missing** |
| Paid | **Confiscate** (reason required) | as Revert, but the recovered coins go to the system account `SYS_CONFISCATED` (kept apart from fee income in `SYS_FEES`) and undelivered items are destroyed; the fee stays |
| Any | **Clear escalation** (pair or winner) | acknowledges the open flags, so they stop counting |

A voided, reverted or confiscated result no longer counts for duel statistics, and counts as a confirmed flag. Items already delivered can't be pulled back automatically; take them out with `/inventory` or `/enderchest`. Every action is in the audit log with the staff member and reason. In game, `/knk duel review <match> release|void [reason]` does the same for held results and delivers to online players at once.

### 3.3 Duel restrictions

**Duels → Restrictions** (`/admin/duels/restrictions`) bars a player, or one specific pair, from **value-moving** duels until an optional end date. Friendly duels stay allowed. The player sees the reason and the end date when an invite or accept is refused. Restrictions show on the player's staff profile (**Duel restrictions** card), and can be lifted early.

| Situation | Tool |
|---|---|
| A suspected alt pair, or a player farming value through duels | a duel restriction, with an end date |
| Abuse across the economy (duels plus `/pay` and trading) | the currency transfer lock (also blocks staking) |
| Serious or confirmed cheating | freeze |

### 3.4 The review policy

**Duels → Policy** (`/admin/duels/policy`) holds the thresholds for S1–S6 (each can be switched off), the escalation count (2, range 2–20) and window (7 days). It is global: it follows players, not arenas. If someone else saved it after you opened the page, saving asks you to reload.

---

## 4. Staff commands

| Command | Node | Does |
|---|---|---|
| `/knk duel list` | `knk.admin.duel` | running matches (token, #id, phase, coins), and held or unclaimed escrow |
| `/knk duel cancel <match>` | `knk.admin.duel` | cancel a running match, full refund, at any phase but the lock-in itself |
| `/knk duel refund <match>` | `knk.admin.duel` | the same as cancel (a finished, paid result is reverted in the web app instead) |
| `/knk duel review <match> release\|void [reason]` | `knk.admin.duel.review` | release or void a held result |

`<match>` is the API id or the first 8 characters of the token. Staff with `knk.admin.duel` can also teleport a duelist and run any command during a duel.

**Files** on the game server (`plugins/KnightsAndKings/`): `duel-escrow/<token>.yml` (staked items and spoils until delivered; `pending-results/` for results the API hasn't confirmed), `duel-vault/<uuid>.yml` (a duelist's own inventory during a kit duel), `duel-toggles.yml` (players who turned invites off). Don't edit or delete them while the server runs; on startup the plugin settles them with the API (`abort-unfinished` refunds unfinished matches; held results stay held).

---

## 5. Player how-to

### 5.1 Challenging someone

1. Go to an arena. You have to **stand inside the arena** to send a challenge.
2. Type `/duel <player>`, or open `/arena` and click **Challenge a player**. The proposal editor opens.
   - `/duel <player> quick` sends an invite straight away: no stakes, the arena's default gear mode.
3. In the editor:
   - **Gear mode**: click to cycle through the modes this arena allows. Drop mode means the loser's inventory goes to the winner.
   - **Kit** (fixed-kit mode): pick the kit both of you will use.
   - **Items**: click an item in **your own** inventory to stake it. It stays in your inventory until the duel starts; it is only marked "Staked in this offer". Click its icon in the editor to take it out again. You can't add the other player's items; they add their own when they counter.
   - **Coins**: the −/+ buttons, or the middle button to type an exact amount. You set both sides.
   - The top row shows the fee and any warnings (not enough coins, a pair limit, a new account, the stake ratio).
4. **Send**. The other player gets a chat message with the stakes and **[View] [Accept] [Counter] [Decline]**.

### 5.2 Answering a challenge

- **Accept** starts the duel with that offer. You can accept from anywhere, but not while you're in combat, in a siege or another duel, frozen or dead.
- **Counter** opens the editor with the offer filled in, so you can change it and send it back. The number of offers is limited (3 by default: offer, counter, final offer); the last one can only be accepted or declined.
- **Decline** ends it. Doing nothing does too: each offer expires after 60 s, with a warning 10 s before.
- Only the newest offer can be accepted: an old **[Accept]** button says the offer is no longer current.
- `/duel toggle` turns duel invites off (and on again). People you ignore can't challenge you either.

### 5.3 What happens when you accept

- **Your stakes are taken at once** (coins and items, from both players). If something is missing (an item you dropped, not enough coins), nothing is taken and the duel doesn't start.
- **Both of you teleport to the lobby** with a normal teleport warmup. Moving cancels the teleport, and that cancels the duel with a full refund.
- **Warmup in the lobby:** you can walk and chat, but not fight, teleport away, use `/spawn` or `/hub`, drop items or put them in chests. In kit modes your own inventory is stored safely and you get the kit; you can't eat or drink kit items yet. In kit-choice mode, pick your kit with `/duel kit` (or the clickable prompt); without a pick you get the arena's first kit.
- If all battlegrounds are busy, the boss bar shows your place in line. After 3 minutes the duel is cancelled and refunded.
- **Countdown on the battleground:** 10 s, you can look around but not move or take damage.
- **Fight:** any death loses. You can't leave the battleground or teleport. Only `/duel`, `/msg`, `/r` and `/staffchat` work. `/duel draw` offers a draw; if your opponent also types it within 15 s, it's a draw.
- **Time limit:** 5 minutes by default. At the limit the duel is a draw.

### 5.4 Results

| Result | Coins | Items |
|---|---|---|
| Win | you get both coin stakes, less the arena's fee (5% by default) | both item stakes (and, in drop mode, the loser's inventory) |
| Loss | lost | your stake is lost; in drop mode, your inventory too |
| Draw (agreed, time limit, both die at once) | everyone gets their own back, no fee | everyone gets their own back |
| Cancel (before the countdown: a quit, a failed teleport, no free battleground, staff) | everyone gets their own back | everyone gets their own back |

- **Quitting** before the countdown cancels the duel. Quitting during the countdown or the fight **forfeits**: your opponent wins (and in drop mode gets your inventory).
- The loser respawns at the arena exit. The winner stays a few seconds and is then teleported to the exit. Your own gear comes back in kit modes; nothing from the kit stays with you.
- **Winnings** go to your inventory, then your ender chest if it's full. Anything left waits for `/duel claim` (or **My claims** in `/arena`).
- **"Pending review":** some results are checked by staff before they are paid out. You'll be told; the stakes stay safe until staff decide.
- If the server goes down or loses the website connection during a duel, the duel is cancelled. Your items come back at once (on your next join after a crash) and coins are refunded when the connection is back.

### 5.5 Watching duels

- Every duel is announced when the warmup starts (unless the arena turned it off): **[Spectate]** teleports you to the stands (after the usual warmup; the arena may ask for a minimum title or a few gems, which the message tells you before you pay), **[Details]** shows the stakes, kits and both players' stats. Walking into the stands is always free.
- `/duels` lists the live duels; click a head for the details.
- `/arena` shows the arena's rules, its queue and live duels, **Spectate**, **Challenge a player** and **My claims**.
- In the stands you see the duel sidebar and a boss bar for the newest fight. You can't hit the duelists and they can't hit you.

### 5.6 Statistics

Duel wins, losses and draws are on your profile and **visible to everyone by default**. You can hide them in your statistics settings (web or in game, the "Duel" context). A forfeit counts as a loss. Cancelled duels count nothing. A result staff void later is taken back out.

---

## 6. Troubleshooting

| Message or symptom | Cause |
|---|---|
| "Stand inside an arena to challenge a player." | The challenger must be inside an enabled arena's region. |
| "That player doesn't accept duel invites." | `/duel toggle` is on, or they ignore you. |
| "The arena is full (3/3 waiting)…" | `MaxQueuedMatches` matches are waiting for a battleground. |
| "Duel not started: X no longer has every staked item." | An item was moved or dropped after it was staked. Nothing was taken. |
| An API refusal (pair cooldown, daily limit, new account, review hold, restriction, stake ratio) | The API checks every rule again at accept; its message names the player and the rule. Nothing was taken. |
| "You are in a duel." on `/spawn`, `/hub`, `/warp`, a siege join | Duelists can't teleport or join a siege from the accept until the exit. |
| Nobody can enter a battleground, not even the duelists | The region still has v1's `entry deny` (or another region's owner rule): run `/knk regions repair` and check `/rg info` for `entry allow`. |
| Anyone can walk into a battleground | The region isn't one of the battleground area's regions (check the area's Regions list and that it was renamed `arena_<id>_battleground_<n>`), or the plugin hasn't refreshed the arena yet (15-minute cache; a restart reads it fresh). |
| "This battleground is reserved for a duel." on a battleground with no match | Expected: battlegrounds are closed whenever no match holds them. Staff need `knk.region.bypass`. |
| "The arena lobby is reserved for the duelists during a warmup." | A match of the arena is in its warmup; the lobby opens again when it moves on. |
| Spectate disabled, or "Walk to … to watch" | The arena has no enabled spectator area, or it has no arrival location. |
| Spectate refused with a title or price message | The spectator area's minimum title or gem price; nothing was charged. |
| "Duels enabled" refused on save | The arena has no enabled lobby area with an arrival location. |
| Winnings missing | `/duel claim`; staff: `/knk duel list` shows unclaimed and held escrow. |
