# Siege Shop and Siege Points — one in-match shop paid with a per-match balance

**Status:** **Decided 2026-11-20** (developer). Open questions answered with the recommended options (§ 12); agent
decisions P10–P27 accepted with the approval. Phases split into sub-issues (§ 11).
**Last updated:** 2026-11-20 (Decided: open questions answered, phases with sub-issues #866–#871, smoke-test guide);
2026-11-20 (first version, design session with the developer: P01–P09 developer, P10–P27 agent)
**Issue:** [PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611) (siege shop),
[#356](https://github.com/PandiO/knk-workspace/issues/356) (siege points) and
[#859](https://github.com/PandiO/knk-workspace/issues/859) (menu item settings, designed here in § 4.3); phases as
sub-issues in § 11.
**Dependencies:** Siege minigame (built); Siege Survival's `MatchLedger` and purchase points (#41, built on the
unmerged `claude/siege-survival` branches); siege weapons phases 1–2 (#782, #783, in `next`); InventoryMenu template
engine (built); item blueprints (built); currency ledger (built); title/XP track (built); notable events (#612) for one
earn source.
**Authority:** the developer's answers in the design session of 2026-11-20 (P01–P09); earlier decisions this builds
on: siege weapons W13, W14, W20, W31–W34, W39, W50, W60, W61, W63, W67
([SIEGE_WEAPONS.md](../siege-minigame/SIEGE_WEAPONS.md)) and Siege Survival S12, S33, S34, S44, S58, S59
([siege-survival/DESIGN.md](../siege-survival/DESIGN.md)). P09 extends W32 (unlocks were coins only). This document is
the canonical specification, not a claim that the proposed entities, endpoints or behaviour exist.

Related:

1. [Siege minigame DESIGN](../siege-minigame/DESIGN.md): runtime (§ 5), death and kill credit (§ 6.6), gear restore
   (§ 9), menus (§ 10).
2. [Siege weapons](../siege-minigame/SIEGE_WEAPONS.md) § 5.1 (buying and placing) and § 7 (economy); phase 3 (#784)
   is blocked on this design.
3. [Siege Survival](../siege-survival/DESIGN.md) § 8 (match currency, purchase points, Mystery Box).
4. [User features](../user-features/DESIGN.md) § 3 (title/XP track) and #861 (alpha/beta reset policy).
5. [Menus admin guide](../../guides/admin/menus-admin-guide.md) and the menu item of #160.
6. #612 notable events, #651 balancing statistics.

## 1. Goal and scope

1. **Goal:** during a Siege or Siege Survival match every player has a **siege points** balance that starts at 0,
   grows from their own play and is spent in **one siege shop** with categories (siege weapons, consumables, later
   magic). Admins edit the catalogue per game mode in the web app and override it per scenario. Strong items are held
   in check by price, escalating prices, cooldowns and per-match caps. Siege weapon types are unlocked once, with
   coins and a minimum title level, from the main menu or the web app. The menu item (nether star) is configured on
   the web app's game settings page and opens the siege menu during a match.
2. **In scope (v1):**
    1. Shared match ledger for both modes (P01): balance, atomic charge, transfers, retry ids.
    2. Siege points earning in PvP Siege from personal play, capture progress and notable events (W34, W50).
    3. Balance display: per-player scoreboard line, action bar on change, `/siege points`.
    4. Teammate transfers behind a per-mode switch (P07).
    5. Shop catalogue: categories, entries pointing at an item blueprint or a siege weapon template, per-mode defaults,
       scenario overrides (P05), brakes (P06).
    6. The shop menu in both modes (P01, P02), with `/siege shop` and a `/siege menu` button.
    7. Siege weapon unlocks with coins and an optional minimum title level (P08, P09), from a main-menu entry and the
       web app.
    8. Menu item settings on the game settings page, with actions per click and situation overrides (P03, #859).
3. **Out of scope:**
    1. Placing a bought weapon on a spot and the build phase: siege weapons phase 3 (#784) uses this shop's purchase
       hook (§ 7.1.6).
    2. The magic category's content: the category exists, its entries come with the magic design (not filed yet).
    3. Notable event definitions and detection: #612 (this design only gives them an earn hook, P15).
    4. Siege Survival's purchase points and Mystery Box: they stay as built (P21); only their balance moves onto the
       shared ledger when the Survival branch merges.
    5. The alpha/beta reset policy and tester rewards: #861.
    6. Unlocks for non-weapon entries (items): later, if a strong item needs one (§ 12 After v1).

## 2. Decision log

| ID | Date | Who | Decision |
|---|---|---|---|
| P01 | 2026-11-20 | developer | **One shared match ledger, the shop in both modes.** Siege Survival's `MatchLedger` (knk-core, on the unmerged `claude/siege-survival` branch) moves into a shared Bukkit-free package in `next` and carries PvP siege points; Survival uses the same ledger when its branch merges. The siege shop menu opens in PvP Siege **and** Siege Survival in v1, next to Survival's purchase points and Mystery Box. |
| P02 | 2026-11-20 | developer | **Buy anywhere, any time** during a match: no spawn-zone rule and no combat lock. The shop opens with `/siege shop`, a button in `/siege menu`, and the menu item (P03). |
| P03 | 2026-11-20 | developer | **Menu item settings move to the game settings page** (#859, designed in this spec, § 4.3): enable, look, an **action per click** (left, right, shift-left, shift-right) and **overrides per situation**, so during a siege match the menu item opens the siege menu (and the shop). Its own issue and phase; the shop does not wait for it. |
| P04 | 2026-11-20 | developer | **Ender pearls are vanilla:** no landing restrictions, wall-skipping is allowed. They are balanced only through a high price and the entry's brakes (P06). |
| P05 | 2026-11-20 | developer | **Default catalogue per game mode, overrides per scenario.** The admin keeps one default list of shop entries for PvP Siege and a different one for Siege Survival; a scenario can override entries (§ 5.3). |
| P06 | 2026-11-20 | developer | **Three configurable brakes per entry** to gate strong items, each optional: (1) a **purchase cooldown** per buy of the entry's standard amount, configurable in duration **and** in progressive growth per purchase (linear, logarithmic or exponential); (2) a **cap per player per match**; (3) a **price increase** per purchase, configurable in the step **and** in progressive growth of the step (same curves). Formulas in § 5.4. |
| P07 | 2026-11-20 | developer | **Teammate transfers are a switch per game mode** on the siege admin settings in the web app: **off by default in PvP Siege**, on in Siege Survival (keeps S12/S44). The ledger rules for a transfer are Survival's (same live match, same team, atomic, no overdraft, retry-safe). |
| P08 | 2026-11-20 | developer | **Unlocks are bought outside the match:** from a new main-menu entry reached through the minigames tile of the main menu, and in the web app (player profile). In a match a locked shop entry shows that it is locked and where to unlock it. |
| P09 | 2026-11-20 | developer | **Unlocks need an optional minimum title level besides the coin price** (extends W32, which was coins only). Titles are the player level (vision § 5), so alpha/beta progression runs on the real title track; the reset policy and tester rewards that keep resets painless are #861. |
| P10 | 2026-11-20 | agent | **One name: "siege points" in both modes.** Survival's "match currency" / "match coins" texts become "siege points"; Survival is not live yet, so the rename is cheap and players learn one word. Survival's own amounts (S33 70 per kill, S34 1000 per roll) are unchanged. (Alternatives in 2.1.) |
| P11 | 2026-11-20 | agent | **The ledger moves unchanged.** Phase 1 copies `MatchLedger`, its request/result types and their tests from `claude/siege-survival` into `knk-core` `core/siege/economy/` with the same public API, so the Survival branch's merge only changes imports. (Alternatives in 2.1.) |
| P12 | 2026-11-20 | agent | **No crash recovery for balances.** A server restart already ends a PvP match without rewards (Siege DESIGN § 5.1) and aborts a Survival match (S59), so a balance never needs to outlive the plugin. Balances live in memory; totals earned and spent per player go into the match result. (Alternatives in 2.1.) |
| P13 | 2026-11-20 | agent | **Assist = damage in the last 10 s.** A member earns an assist when they dealt at least 4 damage (2 hearts) to an enemy within the 10 s before that enemy's death and did not land the killing blow. Every qualifying member gets one. Both numbers are settings. (Alternatives in 2.1.) |
| P14 | 2026-11-20 | agent | **Kill-streak multiplier.** The n-th kill of a streak pays `kill points × min(1 + streak step × (n − 1), streak cap)`; defaults step 0.1, cap 1.5 (the 6th kill and later pay 150). The streak is the roster's existing `killStreak`, which a death resets (W34). Weapon kills count the same (W60). (Alternatives in 2.1.) |
| P15 | 2026-11-20 | agent | **Earn sources as one calculator with an event hook.** `SiegePointsEarnCalculator` in knk-core turns roster and board events (kill, assist, death, gate damage, capture progress, capture, trickle tick) into credits; notable events (#612) call the same `credit(player, source, amount)` hook with their own configured amounts. Proposed defaults in § 5.2. (Alternatives in 2.1.) |
| P16 | 2026-11-20 | agent | **Capture progress pays the contributors.** Every capture step that moves an objective towards the stepping team's side pays each living member of that team inside the capture radius a fixed amount per percent moved (attackers taking it, defenders pushing it back alike), plus a capture bonus to the members inside at the moment of capture. (Alternatives in 2.1.) |
| P17 | 2026-11-20 | agent | **Trickle only for active players.** The trickle pays each member who was active in the last interval (the existing `CaptureActivityTracker` / contribution activity), so an AFK player at spawn earns nothing. (Alternatives in 2.1.) |
| P18 | 2026-11-20 | agent | **Per-player scoreboard for the balance line.** The siege sidebar becomes one board per member (team lines shared, plus "Siege points: N"); the action bar shows each change ("+100 kill · 650"). `/siege points` prints balance, earned and spent. (Alternatives in 2.1.) |
| P19 | 2026-11-20 | agent | **Catalogue model.** `SiegeShopCategory` (seeded: siege weapons, consumables, magic) and `SiegeShopEntry` with a **kind** (`Item` → `ItemBlueprint` and a quantity; `SiegeWeapon` → `SiegeWeaponTemplate`; later `MagicAction`), a game mode, a siege-point price and the brake fields. A weapon entry's empty price falls back to the template's `MatchPrice`. Ammo per shot stays on `SiegeAmmoType.PricePerShot` and is not a shop entry (W20). (Alternatives in 2.1.) |
| P20 | 2026-11-20 | agent | **Unlocks belong to the target, not the entry.** A weapon unlock stays per template (`UserSiegeWeaponUnlock`, `SiegeWeaponTemplate.UnlockPrice` from phase 1 of the weapons) and gains `UnlockMinTitleLevel`; both modes' weapon entries share it. Item entries have no unlock in v1. (Alternatives in 2.1.) |
| P21 | 2026-11-20 | agent | **Survival keeps its purchase points.** The in-world purchase points and Mystery Box stay as built and charge the same shared ledger; the siege shop is an extra place to buy in Survival. `/siege shop` always opens the siege shop; a purchase point opens by clicking its block (its in-range `/siege shop` use on the Survival branch moves to `/siege buy`). (Alternatives in 2.1.) |
| P22 | 2026-11-20 | agent | **Check, then charge, then give** (W67 for every entry): match live and the buyer a living member, entry available, unlock and title level, cap, cooldown, room in the inventory for the whole quantity, balance ≥ current price; only then the ledger charge with retry id `shop:{matchId}:{player}:{entryId}:{purchaseNo}`, then the item. A refusal charges nothing and says why. (Alternatives in 2.1.) |
| P23 | 2026-11-20 | agent | **No refunds; bought items end with the match.** Purchases are final (as W61 for weapons). Items bought in PvP Siege are cleared by the gear restore at match end (Siege D2, § 9.2) like anything else gained in the match; Survival tags them as match items (Survival § 8). The shop says so in its footer. (Alternatives in 2.1.) |
| P24 | 2026-11-20 | agent | **The shop is an InventoryMenu template menu** (`siege.shop`, `siege.shop.category`) with siege content sources and actions, like the other siege menus (Siege DESIGN § 10), not a plain Bukkit inventory like Survival's `PurchaseShop`. (Alternatives in 2.1.) |
| P25 | 2026-11-20 | agent | **The catalogue is frozen at match start** with the rest of the scenario configuration (Siege DESIGN § 5.1): the plugin fetches the effective catalogue for the mode and scenario once; admin edits apply from the next match. (Alternatives in 2.1.) |
| P26 | 2026-11-20 | agent | **Menu item: API settings with the config file as fallback.** The menu item's settings move into `GameSettings` (a `MenuItem` section); the plugin reads them with the game settings, applies changes without a restart, and uses the current `menus.menu-item.*` keys only when the API is unreachable at startup. Clicks map to actions `OpenMenu(key)`, `RunCommand(text)` or `None`; situations are a fixed list the plugin registers. (Alternatives in 2.1.) |
| P27 | 2026-11-20 | agent | **Statistics for balancing.** Each earn and purchase goes to the existing diagnostic telemetry (`siege.points.earned` with source, `siege.shop.purchase` with entry, price and purchase number), and the match result stores siege points earned and spent per participant (#651). (Alternatives in 2.1.) |

### 2.1 Agent decisions: alternatives

1. **P10 one name.** Chosen: "siege points" everywhere, because it is one shared ledger and one shop.
    1. (a) Keep "match currency" in Survival: two names for the same balance in the same shop.
2. **P11 move the ledger unchanged.** Chosen: copy with the same API, because the Survival branch is large and
   unmerged; an identical API keeps its merge to import changes.
    1. (a) Redesign the ledger for PvP needs: nothing PvP needs is missing (charge, transfer, retry ids, totals), and
       a new API means rewriting Survival's callers.
    2. (b) Wait for the Survival branch to merge first: blocks #784 on an unrelated review.
3. **P12 no balance recovery.** Chosen: memory only, because no match survives a restart in either mode.
    1. (a) Checkpoint balances to the API like Survival's checkpoint payload: work and API traffic for state that is
       thrown away at restart anyway. Survival's existing checkpoint keeps its balance field for its result screen.
4. **P13 assist.** Chosen: damage threshold within 10 s, because it is the common shooter rule and needs only a
   per-victim damage log.
    1. (a) Any hit counts: one arrow scratch earns an assist, farmable in team fights.
    2. (b) Only the last other damager: ignores real team play.
5. **P14 streak multiplier.** Chosen: linear step with a cap, because W34 asks for capped and resetting, and the
   roster already counts the streak.
    1. (a) Fixed streak bonuses at 3/5/10: steps feel arbitrary and are harder to tune.
6. **P15 one calculator.** Chosen: one Bukkit-free calculator with a credit hook, so every source is unit-tested and
   #612 plugs in without touching the shop.
    1. (a) Credits scattered in listeners: untestable and easy to double-count.
7. **P16 capture progress.** Chosen: per percent moved, to members in the radius, both directions, because it pays
   the players doing the objective work (W50) and defenders holding a point.
    1. (a) Only a bonus on capture: nothing for a long hold or a failed attempt.
    2. (b) Split among contributors: punishes bringing teammates.
8. **P17 active trickle.** Chosen: active members only, because a trickle should not reward AFK.
    1. (a) Everyone: AFK players bank points for a teammate (when transfers are on).
9. **P18 per-player board.** Chosen: per-player sidebar plus action bar, because #356 asks for the scoreboard and a
   team board cannot show a personal number.
    1. (a) Action bar only: gone after a few seconds; players ask "how much do I have?".
    2. (b) Balance only in the shop title: invisible until the shop is opened.
10. **P19 catalogue model.** Chosen: typed entry with a kind and nullable target references, because the form wizard
    handles nullable foreign keys well and each kind needs its own purchase handler.
    1. (a) One entity per kind (item offers, weapon offers): three lists to edit and three override tables.
    2. (b) A generic JSON payload: no form wizard validation, no foreign keys.
11. **P20 unlock on the target.** Chosen: per template, because W32 unlocks the weapon type, not one menu line, and
    the table already exists in `next`.
    1. (a) Per shop entry: two modes' entries for the same trebuchet would need two unlocks.
12. **P21 keep purchase points.** Chosen: leave them, because they are built, in review and are an in-world mechanic
    (wall buys) the shop does not replace.
    1. (a) Make purchase points sell shop entries: rework of reviewed code before it is even merged; § 12 After v1.
13. **P22 check before charge.** Chosen: W67's order for all kinds; a full inventory is refused rather than dropping
    items on the ground, because Siege forbids item pickup for members (§ 9.3) and dropped items would be lost.
    1. (a) Give what fits and drop the rest (Survival's `PurchaseShop` today): lost items in PvP.
14. **P23 no refunds.** Chosen: final purchases, because refunds of used consumables can't be checked and W61 already
    says so for weapons.
    1. (a) Refund unused items at match end: needs per-item tracking for a small gain.
15. **P24 template menu.** Chosen: InventoryMenu templates, because admins can restyle it, Bedrock handling and
    refresh come for free, and all other siege menus are templates.
    1. (a) Plain Bukkit inventory: quicker, but the Survival docs already plan to move those to templates (Phase 8b).
16. **P25 frozen catalogue.** Chosen: freeze at start, because prices changing mid-match feel unfair and the API is
    never on the purchase path.
    1. (a) Live updates over realtime: price changes during a match, and a purchase racing an edit.
17. **P26 menu item settings.** Chosen: API settings with the file as fallback, because #859 asks for the web app and a
    player must still get a working menu item when the API is down at startup.
    1. (a) API only: no menu item at all during an outage.
    2. (b) Free-form situation expressions: hard to validate; a fixed list covers the known cases.
18. **P27 statistics.** Chosen: reuse the diagnostic telemetry plus two result columns, because #651 is the consumer
    and the telemetry already records siege events per test run.
    1. (a) A purchase table in the API: a write per purchase for data the telemetry already holds.

## 3. Current state and legacy behaviour

1. **Built today (V3):**
    1. **Survival economy (unmerged, `claude/siege-survival` in knk-plugin and knk-web-api, last commits
       2026-11-08):** `knk-core` `core/survival/economy/MatchLedger` (per-match map of balances, `charge(ChargeRequest)`
       and `transfer(TransferRequest)` returning `LedgerResult.Accepted/Rejected` with reasons such as
       `INSUFFICIENT_BALANCE`, `RETRY_ID_CONFLICT`, `MATCH_ENDED`, `PAYER_IS_GHOST`; idempotent by retry id, main thread
       only), wrapped by `MatchEconomy` (earned/spent totals, `creditKill` via `KillRewardCalculator`).
       `knk-paper` `survival/purchase/PurchaseShop` (plain inventory, opened from a purchase-point block or
       `/siege shop` in range), `SurvivalPurchasePoint` / `SurvivalPurchaseOffer` (`ItemBlueprintId`, `Quantity`,
       `Price`) in the API, Mystery Box (`SurvivalMysteryBoxPoint.RollPrice = 1000`), checkpoints with
       `matchBalance`, action bar "+N match coins · balance X".
    2. **PvP Siege runtime (`next`):** `SiegeService` (`handleMemberDeath`, `recordGateDamage`, `onEndMatch`),
       `SiegeMatchRoster.recordDeath()` (kills, deaths, `killStreak`, `highestKillStreak`, `KillCredit`),
       `SiegeMatchContributions.addGateDamage` (with active time), `SiegeObjectiveBoard.step()` (`BoardStep`,
       `CaptureEvent`, `CaptureActivityTracker`), `SiegeMatchObserver` (start, second ticked, captured, member
       removed, ended), `SiegeScoreboardPresenter` (one board per team). **No assist tracking.** A restart ends the
       match (`ServerRestart`, no rewards).
    3. **Siege weapons phase 1–2 (`next`):** `SiegeWeaponTemplate.MatchPrice` (200, siege points) and `UnlockPrice`
       (1000, coins), `SiegeAmmoType.PricePerShot` (10), `UserSiegeWeaponUnlock` with plain CRUD (no coin debit yet).
    4. **Coins:** double-entry currency ledger (`ICurrencyService.SpendAsync`, `CurrencyReasons`, system account
       `SYS_SIEGE`); the pattern to copy is `KitService.PurchaseKitAsync` (users locked, balance check, spend with key
       `kit-purchase:{kitId}:{userId}`, purchase row in one transaction).
    5. **Menus:** template engine (`MenuTemplate`, `ActionRegistry`, `ConditionRegistry`,
       `MenuContentSourceRegistry`), closest examples `KitsMenuFeature` and `ItemsCatalogMenuFeature`;
       `SiegeMenuFeature` / `SiegeMenuBridge`.
    6. **Items:** `ItemBlueprint` (API) and `BlueprintItemAssembler.assemble` (plugin).
    7. **Menu item (#160):** `menus.menu-item.*` in `config.yml` (nether star, slot 8, opens `/menu` on right, left
       and inventory click), `MenuOpenerSettings` in `knk-core`. Read at startup.
    8. **Siege admin settings:** singleton `SiegeConfiguration` (capture rates, kill announcements, headshot
       multiplier, enchant drops), edited through the form wizard; Survival has `SiegeSurvivalSettings` on its branch.
    9. **Game settings page:** `GameSettings` with sections (hub, chat tokens, production, group overrides) and
       cards in the web app's `components/admin/gameSettings/`.
2. **V1/V2:** neither version had an in-match shop, a match balance or kill streaks paying anything. V1 had a gem
   shop menu (`Menu/GemShopClick`) that checked the balance and then removed gems in a second step (not atomic) and
   shopkeeper NPCs; V2's minigame model has no shop. Kept: nothing directly; the V1 check-then-remove race is what the
   ledger's atomic charge avoids. Dropped: nothing players relied on.
3. **Related open work:** #784 (weapons phase 3, blocked on this), #612 (notable events), #651 (balancing
   statistics), #614 (schematic pipeline, the other #784 blocker), #861 (alpha/beta reset policy), #451 (a kit
   claimed in a match is lost at restore: the same rule P23 makes explicit for shop items), #271 (survival scoreboard
   lines, touches the same presenter as P18), production shops #248/#687 (world shops with storages, a different
   feature; only menu conventions are shared).

## 4. Player and admin experience

### 4.1 Player in a match

1. The scoreboard shows **Siege points: 0** at match start. A kill shows "+100 kill · 100" on the action bar; a kill
   streak shows the multiplier ("+130 kill ×1.3 · 830").
2. The player opens the shop with `/siege shop`, the **Shop** button in `/siege menu`, or the menu item (shift-right
   by default during a match, § 4.3). Anywhere, any time (P02).
3. The shop shows its categories (Siege weapons, Consumables; Magic once it has entries) and the balance in the title.
   A category lists its entries: icon, name, quantity, **current price** (after increases), cooldown left, "bought
   2/8", and for a locked weapon "Locked: unlock in /menu → Minigames → Siege unlocks".
4. Clicking an item entry buys it at once when every check passes (P22): the price is charged, the items go into the
   inventory, the line updates. A refusal names the reason ("Not enough siege points: 420/600", "Inventory full",
   "Cooldown: 12 s", "Limit reached: 8 per match").
5. Clicking a siege weapon entry opens the spot picker of SIEGE_WEAPONS § 5.1 (built in #784).
6. With transfers on for the mode (P07), `/siege pay <player> <amount>` and a **Give points** button send points to a
   teammate in the same match.
7. `/siege points` prints balance, earned and spent this match.
8. At match end the balance is gone; bought items are removed with the gear restore (P23). The result screen shows
   siege points earned and spent.

### 4.2 Player outside a match: unlocks

1. Main menu → **Minigames** → **Siege unlocks** lists every weapon template with its coin price, minimum title,
   and "Unlocked" / "Unlock for 1000 coins" / "Needs title Squire".
2. Clicking an unlockable line asks for confirmation, then pays from the account (P08, P09). The same list and button
   are on the player's own profile in the web app.

### 4.3 Menu item settings (#859)

1. **Admin:** the web app's game settings page gets a **Menu item** card: enabled, who gets it (all, Bedrock only),
   give on join, keep on death, material, name, lore, slot, droppable, movable (the fields of today's
   `menus.menu-item.*`), and a **click table**: one action per click type (left, right, shift-left, shift-right,
   inventory click).
2. An action is one of: **Open menu** (a menu key, e.g. `main`, `siege.information`, `siege.shop`), **Run command**
   (a player command such as `siege shop`), or **Nothing**.
3. **Situation overrides:** a list of situations, each with its own partial click table. A click not set in the
   override uses the default table. Situations (fixed list, P26): `siege.hub` (in a siege hub or team split),
   `siege.match` (member of a running PvP match), `siege.survival.match` (member of a running Survival match). Later
   features add theirs (for example arena duels).
4. **Seeded defaults:** default table as today (left, right, inventory click → `main`). `siege.match` and
   `siege.survival.match`: left and right click → `siege.information`, shift-right → `siege.shop`. `siege.hub`: left
   and right → `siege.information`.
5. Saving the card applies to online players within seconds (no restart). With the API down at startup the plugin
   uses the `config.yml` keys, which keep working as the fallback.

### 4.4 Admin: catalogue and settings

1. Web app → Siege → **Shop categories** and **Shop entries** (form wizard, seeded form configurations): each entry
   has a game mode (PvP Siege / Siege Survival), category, kind, target (item blueprint and quantity, or weapon
   template), price, sort order, enabled, and the brakes (§ 5.4).
2. Scenario form → **Shop overrides** list: hide an entry for this scenario, change its price, quantity or brakes, or
   add a scenario-only entry.
3. Siege settings (`SiegeConfiguration`, the minigame admin page): siege points earn amounts (§ 5.2), assist window
   and threshold, streak step and cap, and **Allow teammate transfers** (off). Survival settings: **Allow teammate
   transfers** (on).
4. Siege weapon template form: **Unlock price (coins)** (exists) and **Minimum title level** (new, optional).

## 5. Rules

### 5.1 Ledger and balance

1. Every member of a running Siege or Survival match has a balance that starts at 0 and exists only for that match
   (P01, W33, S12). It never converts to coins.
2. All changes go through the shared `MatchLedger` (P11): charges and transfers are atomic on the main thread, never
   overdraw, and a repeated retry id returns the first result.
3. A member who leaves loses their balance (as in Survival). Survival ghosts can't earn, spend or receive (S20).
4. Balances are not recovered after a restart (P12).
5. Transfers (P07) only when the mode's switch is on: positive amount, both in the same live match and team, the
   receiver not a ghost.

### 5.2 Earning in PvP Siege (W34, W50, W60, P13–P17)

Proposed defaults, all in `SiegeConfiguration`, anchored on about 100 points per minute for a good player (W14):

| Source | Rule | Default |
|---|---|---|
| Kill | Killing blow on an enemy member, weapon kills included (W60) | 100 × streak multiplier |
| Streak multiplier | n-th kill of a streak: `min(1 + step × (n − 1), cap)`; reset on death (P14) | step 0.1, cap 1.5 |
| Assist | ≥ threshold damage to the victim within the window, not the killer (P13) | 40; 4 damage; 10 s |
| Death | Each own death (catch-up) | 15 |
| Gate damage | Per gate HP removed, from `SiegeMatchContributions` | 1 per 5 HP |
| Capture progress | Per percent moved towards the own side, each living member of that team in the radius (P16) | 3 per % |
| Capture | Members in the radius at the capture | 100 |
| Trickle | Every interval, each member active in it (P17) | 10 per 60 s |
| Notable event | Per event (#612), through the credit hook (P15) | set in #612 |

1. A kill by friendly fire, of a non-member, or a suicide pays nothing; a death by an enemy or the environment pays
   the death amount.
2. Survival earns as built (S33: 70 per NPC kill, ×1.1 headshot or crit); other sources stay out of Survival v1.

### 5.3 Catalogue resolution (P05, P19, P25)

1. The effective catalogue of a match = the mode's enabled default entries, minus entries the scenario hides, with
   the scenario's field overrides applied (each override field is nullable: empty keeps the default), plus the
   scenario's own entries.
2. Categories without visible entries are not shown.
3. The plugin fetches it once at match start and keeps it for the match (P25).
4. Weapon entries need `siege.weapons.enabled`; with the flag off they are left out.

### 5.4 Brakes (P06)

For one player, one entry, one match; `n` is the number of purchases of that entry so far (0 before the first).
Each grown step uses the entry's curve over the purchase number `i` (1, 2, 3, …):

| Curve | Step for purchase `i` |
|---|---|
| None | `s` |
| Linear | `s × i` |
| Logarithmic | `s × (1 + ln i)` |
| Exponential | `s × f^(i − 1)` (growth factor `f`, default 1.5) |

1. **Price:** `price(n) = base + Σ_{i=1..n} step_i`, with the price step `s` and the price curve; optional maximum
   price. Rounded to whole points. No price step = a fixed price.
2. **Cooldown:** after purchase number `k` the entry is locked for `cooldown(k) = base cooldown + Σ_{i=1..k−1}
   step_i` seconds, with the cooldown step and curve; optional maximum. Empty base cooldown = no cooldown.
3. **Cap:** at most `MaxPerMatch` purchases per player per match; empty = no cap.
4. Each purchase buys the entry's standard quantity (P06 "per standard amount").
5. All counters reset at match end. Example, ender pearl ×1, base 300, price step 50 linear: 300, 350, 450, 600,
   800; cooldown 20 s, step 10 s exponential ×1.5: 20, 30, 45, 67.5 s.

### 5.5 Purchase (P22, P23)

1. Order: match live and buyer a living member; entry in the effective catalogue; unlock and title level (weapons);
   cap; cooldown; room for the whole quantity (items) or the weapon flow's own checks (W67); balance ≥ current
   price. Then charge with retry id `shop:{matchId}:{player}:{entryId}:{n+1}`, then deliver.
2. A refusal charges nothing and tells the reason. A delivery that fails after the charge (should not happen after
   the checks) is logged and the charge reversed with a ledger credit using the same retry id plus `:reversal`.
3. Purchases are final; no refunds (P23, W61).
4. Bought items are ordinary items for the match; PvP restore clears them, Survival tags them by match id.

### 5.6 Unlocks (P08, P09, P20)

1. A weapon template can be bought only when the player has its unlock (W32). Operating a teammate's weapon needs
   none.
2. Unlocking needs title level ≥ `UnlockMinTitleLevel` (empty = none) and `UnlockPrice` coins; it is idempotent per
   player and template (key `siege-unlock:{templateId}:{userId}`), so a double click charges once.
3. Unlocks are bought only outside a match (P08).

### 5.7 Menu item (P03, P26)

1. The plugin works out the player's situation at click time from the registered situation checks, most specific
   first (`siege.survival.match`, `siege.match`, `siege.hub`); no match = default table.
2. The override's action for that click runs; an unset click falls back to the default table.
3. The item's existing rules stay: never dropped on the ground, never into containers, not placeable (#160).

## 6. Data and API

1. **Entities and fields (one additive migration per phase that needs it):**
    1. `SiegeShopCategory`: `Id`, `Key` (unique), `Name`, `IconMaterial`, `SortOrder`. Seeded: `siege-weapons`,
       `consumables`, `magic`.
    2. `SiegeShopEntry`: `Id`, `GameMode` (`Siege`, `SiegeSurvival`), `SiegeScenarioId` (null = mode default; set =
       scenario-only entry), `CategoryId`, `Kind` (`Item`, `SiegeWeapon`; `MagicAction` later), `ItemBlueprintId?`,
       `Quantity` (default 1), `SiegeWeaponTemplateId?`, `DisplayName?`, `IconMaterial?`, `Price?` (null only for
       weapons: template `MatchPrice`), `PriceStep?`, `PriceCurve`, `PriceGrowthFactor?`, `PriceMax?`,
       `CooldownSeconds?`, `CooldownStepSeconds?`, `CooldownCurve`, `CooldownGrowthFactor?`, `CooldownMaxSeconds?`,
       `MaxPerMatch?`, `SortOrder`, `Enabled`. Validation: the target matching the kind, non-negative numbers,
       factor > 1 for exponential.
    3. `SiegeScenarioShopOverride`: `Id`, `SiegeScenarioId`, `SiegeShopEntryId`, `Hidden`, and nullable overrides
       of `Price`, `Quantity`, `MaxPerMatch`, `CooldownSeconds`, `PriceStep`, `CooldownStepSeconds`, `SortOrder`.
       Unique (scenario, entry).
    4. `SiegeConfiguration` (additive columns): `PointsPerKill`, `PointsStreakStep`, `PointsStreakCap`,
       `PointsPerAssist`, `AssistMinDamage`, `AssistWindowSeconds`, `PointsPerDeath`, `GateHpPerPoint`,
       `PointsPerCapturePercent`, `PointsPerCapture`, `TrickleAmount`, `TrickleIntervalSeconds`,
       `PointTransfersEnabled` (false).
    5. `SiegeSurvivalSettings.PointTransfersEnabled` (true): added on the Survival branch at its merge (§ 9.2).
    6. `SiegeWeaponTemplate.UnlockMinTitleLevel` (int?, additive).
    7. `SiegeMatchParticipant`: `SiegePointsEarned`, `SiegePointsSpent` (additive).
    8. `GameSettings.MenuItem` (JSON column, like the other sections): the fields of § 4.3.1, `Clicks`
       (click → action), `Overrides` (situation → partial clicks).
2. **Endpoints** (default-deny; writes need the existing siege admin rule, reads by plugin key or signed-in admin):
    1. CRUD `api/SiegeShopCategories`, `api/SiegeShopEntries`, `api/SiegeScenarioShopOverrides` (with the access
       registry entries and pinned access tests).
    2. `GET api/SiegeShop/catalogue?mode=&scenarioId=`: the effective catalogue (§ 5.3) with resolved weapon prices.
    3. `POST api/SiegeWeaponUnlocks/purchase` `{ templateId }`: plugin key on behalf of a user, or the signed-in user
       for themselves; checks title level and coins, spends with reason `SIEGE_UNLOCK` and key
       `siege-unlock:{templateId}:{userId}`, writes the unlock row in the same transaction (the kit pattern). Returns
       the unlock or a refusal reason. Rate-limited like other purchases.
    4. `GET api/SiegeWeaponUnlocks/mine` (signed-in user) and `by-user/{userId}` (exists).
    5. `GameSettings` read/update gains the `MenuItem` section; the plugin picks up changes over the existing
       realtime channel.
    6. The match result DTO gains the two participant totals.
3. **Web app:** types, API clients and object configs for the three shop entities; the scenario's overrides list;
   the Menu item card on the game settings page (click table, overrides list, menu key picker); a **Siege unlocks**
   panel on the player's own profile; Playwright mocks and specs.

## 7. Plugin

1. **`knk-core` (Bukkit-free):**
    1. `core/siege/economy/`: `MatchLedger` and its types moved from Survival (P11); `MatchEconomy`-style totals.
    2. `SiegePointsEarnCalculator` (§ 5.2) and `AssistTracker` (per-victim damage log with the window).
    3. `ShopCatalogue` (frozen effective catalogue), `ShopBrakes` (price, cooldown, cap from § 5.4) and
       `ShopPurchaseService` (the check order of § 5.5 against ports for inventory room and delivery).
    4. `ShopPurchaseHandler` port per kind: `ItemPurchaseHandler` here, `SiegeWeaponPurchaseHandler` supplied by
       #784 (opens the spot picker and calls back to charge after its own checks).
    5. `MenuItemActionResolver`: situation + click → action (§ 5.7).
2. **`knk-paper` adapters:**
    1. `SiegePointsService` as a `SiegeMatchObserver` plus hooks in `handleMemberDeath`, `recordGateDamage` and the
       board step; the damage listener feeds `AssistTracker`.
    2. `SiegeScoreboardPresenter` split into per-player boards with the balance line (P18); action bar messages.
    3. Menu feature: menus `siege.shop` and `siege.shop.category`, content sources `siege.shop-categories`,
       `siege.shop-entries`, actions `siege.shop.buy`, `siege.points.give`, conditions for locked/available; the
       **Shop** button in `siege.information`; seeds in `MenuTemplateSeed.Siege`.
    4. `SiegeCommand`: `/siege shop`, `/siege points`, `/siege pay <player> <amount>` (P07).
    5. Main menu **Minigames → Siege unlocks** menu with the unlock purchase action (API call off the main thread).
    6. Menu item listener reads `MenuItem` settings from the game settings and runs the resolved action.
3. **Configuration:** `siege.points.enabled` (default `false`) gates earning, display and transfers in PvP;
   `siege.shop.enabled` (default `false`) gates the shop in both modes. Amounts and prices are API data, not
   `config.yml`. `menus.menu-item.*` stays as the startup fallback (P26). Deploy notes list all three.

## 8. Platform-specific parts

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| Listening to deaths, damage, gate damage | Bukkit events | `knk-paper` siege listeners, `SiegePointsService` | `SiegePointsEarnCalculator`, `AssistTracker` get plain events |
| Scoreboard and action bar | Bukkit scoreboard API | `knk-paper` `SiegeScoreboardPresenter` | none: display only |
| Shop menu rendering | Inventory GUI | `knk-paper` menu feature | menu engine ports (built); `ShopPurchaseService` |
| Inventory room check and item delivery | `ItemStack`, `BlueprintItemAssembler` | `knk-paper` `ItemPurchaseHandler` adapter | `ShopPurchaseHandler` |
| Menu item clicks | Bukkit interact and inventory events | `knk-paper` menu item listener | `MenuItemActionResolver` |
| Ender pearl behaviour | vanilla | none (P04) | none |

Ledger, earn rules, brakes, catalogue resolution, purchase order and the click resolver are all Bukkit-free.

## 9. Risks and integration checks

1. **Moving the ledger before Survival merges (P11).** Check that the copied `MatchLedger` keeps the exact public
   API; the Survival branch's merge must then only change imports. Note the move on #41 so its coordinator expects it.
2. **Survival settings column (P07).** `SiegeSurvivalSettings` exists only on the Survival branch; its transfer
   switch is added there at merge (default on), and until then Survival behaviour is unchanged.
3. **Per-player scoreboards (P18)** touch every siege board; check team colours, tab-list `[K/D]` suffixes and
   collision rules still apply per player, and that #271's survival lines fit.
4. **Healing items as blueprints.** Check `ItemBlueprint` can describe a potion's type (healing, regeneration,
   splash); if not, phase 2 adds the missing field before the consumables seed.
5. **Snowballing.** Kill points with streaks plus weapon kills (W60) may snowball; watch earned/spent per player in
   the balance runs (#651, P27).
6. **Ender pearls over walls (P04)** may change how attackers play; the price, cap and cooldown are the levers.
7. **Menu item realtime refresh** must not re-give or move items mid-fight; changing the look only re-renders the
   item in its slot.
8. **Assist log memory:** keep only the last window per victim; cleared on death and at match end.

## 10. Acceptance checklist

| ID | Check | Phase |
|---|---|---|
| A01 | A charge above the balance is refused and the balance is unchanged | 1 |
| A02 | Two charges with the same retry id debit once; the second returns the first result | 1 |
| A03 | A transfer is refused when the mode's switch is off (PvP default) and works when on; never overdraws | 1 |
| A04 | Balance starts at 0 for every member and is gone after match end | 1 |
| A05 | Kill pays 100; the 2nd–6th kill of a streak pays 110…150; the streak resets on death | 1 |
| A06 | An assist pays 40 only with ≥ 4 damage in the last 10 s, never to the killer | 1 |
| A07 | A death pays 15; friendly fire and suicide pay nothing | 1 |
| A08 | Gate damage pays 1 per 5 HP; capture progress pays 3 per % to own members in the radius, both directions; a capture pays 100 to those inside | 1 |
| A09 | Trickle pays only active members | 1 |
| A10 | The scoreboard shows each player's own balance; the action bar shows each change; `/siege points` prints balance, earned, spent | 1 |
| A11 | The match result stores siege points earned and spent per participant; telemetry has earn and purchase events | 1, 3 |
| A12 | With `siege.points.enabled` false nothing is earned or shown | 1 |
| A13 | Shop categories, entries and overrides can be created and edited in the web app through seeded forms | 2 |
| A14 | An entry whose target does not match its kind is refused by the API | 2 |
| A15 | The effective catalogue hides overridden-hidden entries, applies field overrides and adds scenario-only entries | 2 |
| A16 | A weapon entry without a price uses the template's `MatchPrice` | 2 |
| A17 | `/siege shop`, the `/siege menu` button and the menu item open the shop anywhere during a match, in both modes | 3 |
| A18 | A purchase with enough points charges the current price and gives the full quantity | 3 |
| A19 | Each refusal (points, inventory full, cooldown, cap, locked) charges nothing and names the reason | 3 |
| A20 | Price grows per § 5.4 for each curve; the maximum price holds | 3 |
| A21 | Cooldown grows per § 5.4 for each curve; the maximum cooldown holds | 3 |
| A22 | The per-match cap stops further purchases; all counters reset next match | 3 |
| A23 | Catalogue edits during a match apply only from the next match | 3 |
| A24 | Bought items are gone after the PvP restore; no refund at any point | 3 |
| A25 | Survival purchase points and the Mystery Box charge the same balance as the shop (after the Survival merge) | 3 |
| A26 | A locked weapon entry shows "Locked" and where to unlock it, and cannot be bought | 3, 4 |
| A27 | Unlock from the main menu and from the web app profile: needs the title level and the coins; a double click charges once | 4 |
| A28 | Unlocks cannot be bought during a match | 4 |
| A29 | The game settings page edits the menu item's look, clicks and overrides; changes reach online players without a restart | 5 |
| A30 | In a PvP or Survival match the menu item opens the siege menu on click and the shop on shift-right; outside, the main menu | 5 |
| A31 | With the API down at startup the menu item works from the `config.yml` keys | 5 |

## 11. Phases

Confirmed on approval 2026-11-20. Phases 1–4 are sub-issues of #611 (phase 1 builds #356); 5a and 5b of #859.

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | Shared ledger in `core/siege/economy`, siege points earning, assists, per-player board, `/siege points`, `/siege pay`, settings columns, participant totals | A01–A12 | knk-plugin, knk-web-api | tier:3 | `siege.points.enabled` | #866 | — |
| 2 | Shop catalogue: entities, overrides, effective catalogue endpoint, form seeds, web app forms; potion blueprint check | A13–A16 | knk-web-api, knk-web-app | tier:2 | none (data only) | #867 | — |
| 3 | Shop in the plugin: menus, item purchases with brakes, weapon purchase port for #784, Survival hook, telemetry | A17–A26 | knk-plugin | tier:3 | `siege.shop.enabled` | #868 | 1, 2 |
| 4 | Weapon unlocks: purchase endpoint with title level, main-menu Siege unlocks, web app profile panel | A26–A28 | knk-web-api, knk-plugin, knk-web-app | tier:2 | none | #869 | 2 |
| 5a | Menu item settings in the API and the game settings card (#859) | A29 | knk-web-api, knk-web-app | tier:2 | none | #870 | — |
| 5b | Menu item from the API in the plugin: clicks, situations, fallback, siege seeds | A29–A31 | knk-plugin | tier:2 | none | #871 | 5a, 3 |

#784 (weapons phase 3) needs phases 1–3; phases 2, 4 and 5a can run in parallel with phase 1.

Smoke test: [guides/siege-shop-smoke-test.md](../../guides/siege-shop-smoke-test.md) (draft from the design).

## 12. Open questions

None open. Answered on approval (2026-11-20, developer, recommended options):

1. **Default earn amounts:** (a) ship the § 5.2 proposals and tune them in the alpha balance runs (#651).
2. **Default catalogue seeds:** (a) seed in phase 2: PvP Siege consumables ender pearl ×1 (300, +50 linear, cooldown
   20 s +10 s exponential ×1.5, cap 8), splash potion of healing II ×1 (150, +25 linear, cooldown 10 s, cap 10),
   golden apple ×1 (200, +50 linear, cap 6), potion of regeneration ×1 (250, cap 4), plus the three weapon entries at
   their template prices; Siege Survival the same consumables at ×10 prices.
3. **Healing vs own-gear golden apples:** (a) own-gear rules stay; #651 watches healing items used.

### After v1

1. Purchase points selling shop entries in Survival (P21, alternative (a)).
2. Unlocks for item entries, if a strong item needs one (P20).
3. Magic category entries, with the magic design (not filed yet).
4. Siege Survival earn sources beyond kills (Survival § 8 "not in v1").
