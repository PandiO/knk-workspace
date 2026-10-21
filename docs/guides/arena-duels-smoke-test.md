# Arena duels (KNG-197) — smoke test

**Status:** To test · **Last updated:** 2026-10-21 · [KNG-222](https://linear.app/kngpandi/issue/KNG-222) (P8), phases [KNG-209](https://linear.app/kngpandi/issue/KNG-209)–[KNG-221](https://linear.app/kngpandi/issue/KNG-221)

**Design:** [DESIGN](../specs/arena-duels/DESIGN.md) · **Plan:** [IMPLEMENTATION_PLAN](../specs/arena-duels/IMPLEMENTATION_PLAN.md) Phase 8 · **Guide:** [arena-duels.md](arena-duels.md) · **Background:** [chain report](../reports/2026-10-21-arena-duels-chain.md) (per-phase details; the tag after each check, e.g. `P4·6`, is that phase's live check number in the report)

This is plan Phase 8's steps 1–15, with every live check the phase sections of the chain report added, sorted into the step they belong to, plus the siege regression check from P0 (§S) and the checks that fit no step (§X). Record each result in **Findings** at the end (pass / fail + what you saw). Use **non-op accounts** for every permission check: ops pass in-game checks.

**People:** **A** and **B** duel, **C** spectates (a plain player), **S** is staff (you, with `knk.admin.*`). A, B and C need some coins; give A and B a few distinct items (a named sword, armour).

---

## 0. Setup

### 0.1 Deploy from the branches

| Repo | Branch | Head to deploy |
|---|---|---|
| knk-web-api | `claude/arena-duels` | `57f26a2` (from `master` `2d71155`) |
| knk-web-app | `claude/arena-duels` | `6afaa8b` (from `main` `e30c815`) |
| knk-plugin | `claude/arena-duels` | `0f6dd1ca` (on the KNG-182 branch `claude/mc-26.2-upgrade` `88497649`; P8 changed only `CLAUDE.md`, so a `d8897a79` build is the same code) |

The plugin branch is built on **KNG-182** (Minecraft 26.3, Java 25). The dev server must be the 26.3 server from that branch ([minecraft-26.3-upgrade-smoke-test.md](minecraft-26.3-upgrade-smoke-test.md)); a 1.21 server won't load the jar.

1. [ ] **Back up the dev database.** Two migrations add tables and seed rows.
2. [ ] **API:** `dotnet build knkwebapi_v2.csproj` (a plain `dotnet build` at the root fails on Linux, KNG-223), `dotnet ef database update`, start it. Migrations `AddArenas` and `AddDuelMatches`.
   - [ ] Tables `arenas`, `arena_battlegrounds`, `arena_spectator_areas`, `arena_kits`, `duel_matches`, `duel_policies` (one row, defaults), `duel_restrictions` exist. (P2·1)
   - [ ] `discovery_reward_rules` has `Arena` and `ArenaSpectatorArea` (on) and `ArenaBattleground` (off). (P1·1)
   - [ ] `GET api/MenuTemplates/by-key/duel_matches` (and `duel_match_detail`, `arena_main`, `duel_challenge`) exist after the start. (P6·1)
3. [ ] **Web app:** `npx -y npm@11 ci`, then start or build. Import the form seeds (**Import / seeds**) in this order: `ArenaKit.join`, `Arena`, `ArenaBattleground`, `ArenaSpectatorArea`. (P1·2)
4. [ ] **Plugin:** `./gradlew build -x deployToDevServer -Porg.gradle.java.installations.paths=<JDK 25>` for the test counts, then deploy the jar to the 26.3 dev server (or a plain `./gradlew build`, which deploys). Start. Expected: no menu validation errors for the duel templates (P6·1); `duels:` block in `config.yml` with defaults (guide §2.1).
5. [ ] **Grants:** S has `knk.admin.*` (covers `knk.admin.world`, `knk.admin.duel`, `knk.admin.duel.review`). Keep a second staff account **S2** without `knk.admin.duel.review` for the permission checks. A, B and C have only the default player nodes.

### 0.2 Create `arena_2` (no seed: the developer chose the forms, KNG-197)

6. [ ] In game, `/rg list` in the arena's world: note `arena_2` and its 8 flagged `…-battleground` children. (P1·3)
7. [ ] **Arena form** (web app): name, key `arena_2`, its district and street, region `arena_2` (typed), **Duels enabled off**. Save. (P1·3)
8. [ ] **Battlegrounds**: from the arena's last step, add at least **three** of the eight (type the existing region ids), each disabled at first. Then, standing on each spawn, capture spawn A and spawn B with **Send to Minecraft** and enable it. (P1·3, P1·7)
9. [ ] **Spectator area**: create one with a temp region over the stands (**Send to Minecraft**). Location = the arrival point. **Teleport enabled** on, no conditions yet. (P1·7)
10. [ ] **Locations**: lobby (inside the arena, outside the battlegrounds) and exit (outside the arena) with **Send to Minecraft**.
11. [ ] **Eligible kits**: add two kits (call them **Knight** and **Archer**); pick one that normally needs a higher title than A has. Allow all four gear modes for now; default `OWN_GEAR_KEEP`.
12. [ ] Turn **Duels enabled** on. Save.
13. [ ] Restart the game server (or `/knk regions repair`). (P1·4)
    - [ ] `arena_2`: priority 40, parent its district.
    - [ ] Each battleground: priority 50, parent `arena_2`, `pvp allow`, `entry allow`; after the access sync, `knk-allow-entry deny`. v1's `entry deny` is gone.
    - [ ] The spectator area: renamed `domain_<id>`, parent `arena_2`, priority 50, no flags. (P1·7)
    - [ ] `/warp` lists the spectator area. (P1·7)
14. [ ] Set the town around the arena to `pvp deny` if it isn't already (the plan's precondition).

---

## 1. Settings

- [ ] The Arena form saves and validates. Refused: no gear mode; a kit mode without kits; `MaxOffers` 7; fee 21. (Plan 1, P1·6)
- [ ] Two eligible kits: drag their order, save, reload → the order sticks. Deleting one of them on the kit page is refused and names the arena. (P1·6)
- [ ] A battleground spawn in another world is refused. (P1·7)
- [ ] Change `MaxOffers` to **2**; in game the next negotiation allows only offer + one counter (offer 2/2 has no **[Counter]**). Set it back to **3**. (Plan 1, P1·6)
- [ ] **Gear mode button**: with two modes allowed, the editor cycles only through those two; with one, the label is fixed. Re-allow what the later steps need. (P5·4)

## 2. Negotiation

- [ ] A runs `/duel B` **outside** the arena → "Stand inside an arena to challenge a player."; inside → the editor opens. (P5·1)
- [ ] **Editor clicks**: shift-click, number keys, double-click and drag in the editor or on A's own inventory never move an item. A click on A's sword adds it with "Staked in this offer"; the sword stays in A's inventory. Clicking the icon removes it. B's items can't be added by A. (P5·2)
- [ ] **Coins**: −/+ for both sides; the anvil for an exact amount, capped at `MaxCoinStake`; A's balance shown as a hint. (P5·3)
- [ ] **Send** → B gets "offer 1/3, 60 s", both stakes, `[View] [Accept] [Counter] [Decline]`; A gets "Duel offer 1/3 sent". In drop mode the line reads in red capitals. (P5·6)
- [ ] **Counter** from chat → B's editor pre-filled; send → A gets offer 2/3; A counters → offer 3/3 **without** `[Counter]`, in chat and in the view. (Plan 2, P5·7, P3)
- [ ] An old `[Accept]` after a counter → "That offer is no longer current." (Plan 2, P5·7, P3)
- [ ] **Accept** at offer 3/3 works (continue in step 4, or cancel with `/knk duel cancel`).
- [ ] **Expiry**: leave an offer unanswered → at 10 s the receiver gets "… expires in 10 s" with the buttons once, then both get the expiry lines. (Plan 2, P5·8)
- [ ] **Decline** → both told; nothing moved. (Plan 2)
- [ ] **`/duel toggle`** on B → A's `/duel B` says "That player doesn't accept duel invites."; the toggle survives a restart. Same message when B ignores A. Toggle back. (Plan 2, P5·1)

## 3. Refusals

- [ ] B combat-tagged (hit a mob or another player) → accepting is refused. (Plan 3)
- [ ] B in a **siege lobby** → accepting is refused. (Plan 3)
- [ ] The other way round: a duelist (or a player negotiating) can't join a siege: "You are in a duel." / "You are negotiating a duel…". (P4·15)

## 4. Lock-in

- [ ] **Broke**: A stakes more coins than A has → refused; nothing is taken from either. (Plan 4)
- [ ] **Ratio**: 10,000 vs 0 at ratio 50 → the editor warns locally; sending is allowed (advisory) but the accept is refused by the API (`StakeRatioTooLow`). Items count at their blueprint's base price (KNG-224 notes the plugin can't value them yet). (Plan 4, P5·5)
- [ ] **Warnings** in the editor: a pair on cooldown, a new account or too few coins → the API's message in the warnings icon; the fee shows 5% of the pot. (P5·5)
- [ ] **Moved item**: A stakes a sword, B waits; A drops the sword; B accepts → "Duel not started: A no longer has every staked item." Nothing taken from B; no `duel-escrow/` file. (Plan 4, P5·9)
- [ ] **API refusal** (e.g. the pair on cooldown) → the accept is refused with the API's message; both players' items come back at once. (P5·10)
- [ ] **Success**: both stakes taken at accept; the staff ledger shows one `DUEL_STAKE` transaction with **two legs**; `SYS_DUEL` holds the pot; `duel-escrow/<token>.yml` shows `ESCROWED`. (Plan 4, P2·2, P4·1)

## 5. Queue cap

- [ ] Fill the arena to `MaxQueuedMatches` (3): set `WarmupSeconds` high, or disable all but one battleground and keep it busy. The invite warns "The arena is full (3/3 waiting)…"; the **fourth accept is refused before anything is taken**. (Plan 5, P3)

## 6. Lobby teleport

- [ ] Both lobby teleports start together (5 s warmup; no teleport cooldown afterwards; `/spawn` free again after the match). (P4·1)
- [ ] A moves during the warmup → both teleports cancelled, `TeleportFailed`; items back, coin refund visible in the staff ledger and in `/admin/duels`. (Plan 6, P4·2)

## 7. Warmup

- [ ] **Broadcast** to everyone: "⚔ Duel at arena_2: A vs B - own gear - stakes: …  [Spectate] [Details]"; hover shows what each does. [Details] opens the match detail; [Spectate] starts the stands' warp. (Plan 7, P6·2)
- [ ] **Spam cooldown**: the same duelists start another duel within 120 s → no second broadcast; after `duels.announce.cooldown-seconds` it broadcasts again. (P6·3)
- [ ] **Toggles**: `AnnounceFriendly` off → a duel without stakes isn't broadcast, a staked one is. `AnnounceMatches` off → nothing is broadcast; results go only to the duelists and the stands. Turn both back on. (P6·4)
- [ ] **`/duels`** (C): two heads per live duel, refreshed every second; "No duels right now" when empty. A head opens the detail: both cards (title, XP, playtime, duel W/L/D; PvP kills only if that player shows them: hide them in A's statistics settings and check), kits, coins, the real stake items with names and enchantments. (Plan 7, P6·9)
- [ ] **Teleports and commands** refused for duelists from the accept on: `/spawn`, `/warp`, `/home`, `/tpa` to a duelist, `/back`, `/hub` ("You are in a duel."). Staff `/tp` with `knk.admin.duel` passes. (Plan 7, P4·5)
- [ ] Duelists can't hit each other or be hit in the lobby. (Plan 7)
- [ ] **Sidebar and boss bar (duelists)**: from the accept on, "Your duel: vs B", stage and timer, gear and stakes, the arena's other live duels, "Queue: 1/3 waiting", "Battlegrounds: 1/8 busy". Boss bar: warmup countdown, "Waiting for a free battleground (#2 in line)" when full, "Get ready: 7", the fight timer (or "no time limit"), then "A won!". Both go at the exit and the normal board is back. (P6·6)
- [ ] **KIT_CHOICE**: the placeholder is the first eligible kit; the clickable prompt and `[Menu]`; `/duel kit Archer` → "You will fight with Archer", B sees "A picked Archer", the picker shows the opponent's pick; a pick in the countdown is refused; at the countdown the picker closes: "The kits are locked". No pick → the placeholder fights. (Plan 7, P4·7, P5·11, P3)
- [ ] **Kit consumables** can't be eaten or drunk in the warmup (kit modes). (P4·6)

## 8. Spectator area

- [ ] C reaches the stands **on foot**, by **`/warp`**, and from **`/arena` → Spectate** (and the detail's "Go to the spectator area"). Each runs the warp: 5 s warmup, then the teleport. (Plan 8, P6·8)
- [ ] Set a **gem price** on the warp → charged after the warmup. Set a **minimum title** C doesn't have → refused with the reason, nothing charged. Remove both. (Plan 8, P6·8)
- [ ] In the stands during a live duel: the arena's sidebar and the boss bar of the newest fight. Walking out removes both. A rank or premium change (which resets scoreboards) leaves the duel board alone. (P6·7)
- [ ] **`/arena`**: info, rules (gear modes, offers, stake limits, fee, ratio, pair limit, daily cap, timings), queue, live duels, Spectate (disabled without a warp), Challenge a player (disabled outside the arena; a click from outside says "Stand inside the arena…"), My claims (highlighted when something waits; a click collects it). The challenge picker lists online players, those in a duel greyed out; a pick opens the proposal editor. `/arena arena_2` from elsewhere; tab completion lists arenas. (P6·10, P5·13)
- [ ] `/navigate` lists the arena and the spectator area, not the battlegrounds. Walking into the arena gives the "arena" discovery message; a battleground gives none. (P1·8)

## 9. Countdown

- [ ] Both at their spawns, frozen (looking around works), no damage, 10 s titles and sounds; projectiles and pearls blocked. (Plan 9, P4·1)
- [ ] **FIXED_KIT**: the own inventory is cleared and stored on arrival in the lobby (`duel-vault/<uuid>.yml`); the kit is granted with no cost or cooldown, **even though A lacks the kit's title**; kit items can't be dropped or stored. (Plan 9, P4·6)

## 10. Fight

- [ ] PvP works inside the `pvp deny` town, **splash potions included** (the `DisallowedPVPEvent` path). (Plan 10, P4·3)
- [ ] C (or S without fighting) can't hit either duelist, and the duelists can't hit C. (Plan 10, P4·3)
- [ ] A custom enchantment (lifesteal, fire) triggers in the fight. (Plan 10, P4·3)
- [ ] Leaving is refused in the countdown and the fight: walk, ender pearl, chorus fruit, elytra, boat. (Plan 10, P4·4)
- [ ] A non-duelist can't walk, pearl or ride into a battleground (domain-access message); S with `knk.region.bypass` can walk in. (Plan 10, P4·4, P1·5)
- [ ] Only `/duel`, `/msg`, `/r`, `/staffchat` work in the countdown and the fight. (P4·1)
- [ ] The exit teleport at the end works. (P4·4)

## 11. Results, each mode

- [ ] **Keep** (staked): the winner gets both stakes after the linger at the exit; the loser respawns at the exit with their gear; `duel-escrow/` file gone. (Plan 11, P4·1)
- [ ] **Fee**: the ledger shows `DUEL_PAYOUT` (pot − 5%) and `DUEL_FEE` (`SYS_DUEL` → `SYS_FEES`, no player line); **Run reconciliation** on the currency monitor page finds nothing. (Plan 11, P2·3)
- [ ] **Result broadcast**: "A defeated B in 1:42 and won 665 coins + 2 items." after the payout. "B was defeated by A." reaches only the duelists and the stands. (P6·5)
- [ ] **Drop**: the loser's inventory isn't dropped on the ground; the winner receives it with the stakes after the linger, through the claim chain. (Plan 11, P4·10)
- [ ] **Kit**: after the fight both inventories are identical to before; no kit item left anywhere (inventory, armour, off-hand, ender chest). (Plan 11, P4·6)
- [ ] **Full inventory**: the payout goes to the ender chest, then waits for `/duel claim` (or **My claims**). (P4·11, P5·12)

## 12. Forfeit, draws, time limit

- [ ] **Quit in the fight** → the opponent wins ("won by forfeit" broadcast); in **drop** mode the winner gets the quitter's inventory. (Plan 12, P4·10, P6·5)
- [ ] **Kit mode, quit mid-fight**: the quitter's own inventory is back at once; on rejoin they are where they stood before the duel, and the vault file is gone. (P4·8)
- [ ] **Agreed draw**: `/duel draw` by one, the other within 15 s → draw, full refund, broadcast "drew at arena_2 (agreed draw)". After 15 s → only a new offer. `/duel draw` outside the fight → "You can offer a draw only during the fight". In drop mode a draw takes nothing. (Plan 12, P3, P5·12, P4·10, P6·5)
- [ ] **Time limit 30 s** → draw and full refund. (Plan 12)
- [ ] **Time limit 0** → no limit; the boss bar says "no time limit". (Plan 12)
- [ ] **Simultaneous death** (both on the same tick, e.g. one TNT) → draw with refund. (P3)
- [ ] Staff `/knk duel cancel <token>` refunds a running duel; the cancel line reaches only the duelists and the stands. (P5·14, P6·5)

## 13. Review

Thrown fight = the loser never swings, under 10 s, value-moving.

- [ ] **One thrown fight** → paid, `Review = Flagged`; `DUEL_FLAG` on the currency alerts page and in game for staff with the alerts node. (Plan 13, P2·4)
- [ ] **A second flagged result** between the same two (either direction, or the same winner against someone else) → held, nothing paid, `DUEL_HOLD`; both told "pending staff review" and the broadcast says "(pending review)"; items stay `HELD` in the spool. A new staked invite between them is refused (`ReviewHoldOpen`); a friendly duel still works. (Plan 13, P2·4, P4·13, P6·5)
- [ ] A held result shows **no** W/L. (P7·2)
- [ ] **Release** in the web app → paid; the winner gets the items within `held-refresh-seconds` or on rejoin; W/L now counts. (Plan 13, P2·6, P4·13, P7·2)
- [ ] **Void** another (reason required) → both stakes back, no fee; each side gets their own items back; a voided hold never counts for W/L. Both actions are in the audit log with S and the reason. (Plan 13, P2·6, P4·13, P7·2)
- [ ] **Acknowledge** the first flag as a false positive, play another thrown fight → flagged, **not** held. (Plan 13, P2·5)
- [ ] **Revert** a paid result after the winner spent part of it: the winner ends at 0, the loser gets back what was recovered first, "Still missing" shown; the next projection cycle takes the W and L back out. (P2·7, P7·3, P7·8)
- [ ] **Confiscate** another: the recovered coins land in **`SYS_CONFISCATED`** (not `SYS_FEES`; developer decision 2026-10-21), the fee stays in `SYS_FEES`; reconciliation finds nothing. (P2·7, P7·8)
- [ ] **`/admin/duels`** filters by arena, player name, status and review; S sees each match's signals, numbers and tier. (P7·8)
- [ ] **Clear escalation** (pair, then winner) → the pair's open `DUEL_FLAG` alerts show acknowledged. (P7·9)
- [ ] **Restrictions** (`/admin/duels/restrictions`): a player restriction with an end date refuses staked duels (message shows reason and date), allows friendly ones, ends at the date; a pair restriction (by name) refuses only that pair; both show on each player's staff profile; lift one; audit entries for both players of a pair. (P2·8, P7·10)
- [ ] **Policy** (`/admin/duels/policy`): change a threshold and save; save again from a second tab opened before → the reload message. (P7·11)
- [ ] **Alerts page**: the rule filter offers R10, Duel flagged, Duel held; a duel alert links its match. (P7·12)
- [ ] **R10**: three paid one-way duels between the same pair within 24 h → an `R10` alert on the next monitor cycle; `R7` doesn't fire for `DUEL_PAYOUT`. (P2·11)
- [ ] **In game**: `/knk duel review <id> release` as S2 (no `knk.admin.duel.review`) is refused; as S, the winner gets the items at once. (P5·14)
- [ ] **Web permissions**: S2 sees no Duels button, gets the no-access page on `/admin/duels`, no restrictions card on profiles, and 403 on release/void/revert/restrictions through the API; S passes. (P2·10, P7·13)
- [ ] **Review data is staff-only** (developer decision 2026-10-21): `GET api/DuelMatches/{id}` as A (a plain logged-in player) shows the review state (`flagged`, `held`, …) and the result, but **no** `reviewSignals`, `reviewDetails` or `reviewTier`; as S2 (no `knk.admin.duel.review`) also none; as S and with the plugin key, all three. The warmup and result broadcasts still reach everyone. (P2·10)

## 14. Recovery

- [ ] **Crash, own gear**: `kill -9` the server mid-fight → on restart the startup log shows `abort-unfinished` refunding the coins (held results untouched); items back on join. (Plan 14, P2·12)
- [ ] **Crash, kit mode** (`kill -9` during the warmup): on rejoin the kit is swept, the own inventory is back, the player is at their pre-duel spot. (Plan 14, P4·9)
- [ ] **Outage**: stop the API mid-warmup (and once mid-fight) until the outage action fires → the duel is aborted; gear and items come back at once; the coin refund arrives when the API is back (`pending-results/` empties). (Plan 14, P4·12)
- [ ] With the API stopped, the plugin still knows the arena (cached; `[Arenas]` in the log only on a cache miss). (P1·9)

## 15. Concurrency and stats

- [ ] **Two matches on two battlegrounds plus one waiting** (a third pair, or shorten the warmups): each fights on its own battleground; the third waits with "#1 in line" and gets the first free one. (Plan 15)
- [ ] **MySQL concurrency**: two simultaneous `complete` calls (same winner) for one match → one payout; two lock-ins of the same token → one match (`POST api/DuelMatches` twice with the same `publicToken` and `X-API-Key`). (P2·9)
- [ ] **W/L**: within one projection cycle (30 s) after a paid duel, the winner has `wins@duel` +1 and the loser `losses@duel` +1 (web profile statistics or the in-game menu, "Duel" context). A forfeit counts the quitter's loss; a time-limit or agreed draw a draw for both; a cancel or a restart abort nothing. (Plan 15, P7·1)
- [ ] **Visibility**: C sees A's duel W/L/D on the public profile without any setting; after A sets Wins → Duel to Nobody, the duel wins disappear; the wins total stays hidden throughout. (Plan 15, P7·4)
- [ ] Kills and deaths in the fight are stored as `pvp_kills@duel` / `deaths@duel`; warmup kills as open world. (P7·5)
- [ ] `/leaderboards` shows no duel board. (P7·6)
- [ ] `POST api/statistics/rebuild {"projection":"duel"}` reproduces the same numbers. (P7·7)

---

## S. Siege regression (P0)

P0 moved siege's hooks onto the shared minigame registry with no behaviour change. One siege round:

- [ ] **Outage release**: with a siege at the hub or in progress, stop the API until the outage action fires → the round is aborted ("…lost its connection…"), members get their things back and are moved; when the API returns, the lobby restarts matchmaking. (P0·1)
- [ ] **`/hub` refusal**: a member at the siege hub, in the match and during ENDING/COOLDOWN gets "You are in a siege."; a member still in matchmaking may use `/hub`. (P0·2)
- [ ] **Safezone enchant effects**: in a siege fought inside a town (PvP-safe region), custom enchantments still trigger on enemy hits; a hit inside a team's own spawn area is still refused. (P0·3)
- [ ] **Vault restore after a quit**: quit mid-match → inventory, XP and effects back at once; rejoin → at the pre-match spot; `siege-vault/<uuid>.yml` is gone. A vault file left from before this branch (if any on the dev server) restores on join. (P0·4)
- [ ] **Extras**: `/spawn` as a member is refused with the siege message; a match death gives no `/back`; the match scoreboard survives an hourly salary/rank refresh; lootbox tokens earned during the siege arrive after the restore. (P0·5)

## X. Checks outside the 15 steps

- [ ] **Lootbox**: a reel finishing mid-match says "kept safe" and arrives after the restore, not in the kit; opening a lootbox during a duel is refused. (P4·14)
- [ ] **Staff list**: `/knk duel list` shows running matches (token, #id, phase, coins) and held or unclaimed escrow. (P5·14)
- [ ] **Player permission**: a group without `knk.duel` gets "no permission" for `/duel` and `/arena`, and neither is in its tab list. (P5·15)

---

## Findings

| Step | Result | What you saw |
|---|---|---|
| | | |
