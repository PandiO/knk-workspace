# Siege shop and siege points — smoke test

**Status:** Draft from the design (2026-11-20); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-20 (draft from the design, phases 1–4, 5a, 5b)
**Design:** [specs/siege-shop/DESIGN.md](../specs/siege-shop/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611),
[#356](https://github.com/PandiO/knk-workspace/issues/356), [#859](https://github.com/PandiO/knk-workspace/issues/859)

Accounts used throughout: **Admin** (web app staff with the siege admin and content permissions, op in game), **A1**
and **A2** (two players on the attacking team), **D1** (a player on the defending team). Write down any step that
fails, with the server log lines.

## 1. Phase 1: shared match ledger and siege points earning (#866, tier:3)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 1.0 Preconditions

1. Deployed: knk-web-api from `next` with the phase 1 migration applied; knk-plugin built from `next`.
2. Settings: `siege.points.enabled: true` in the plugin's `config.yml`; `SiegeConfiguration` with the default earn
   amounts (kill 100, streak step 0.1 cap 1.5, assist 40 with 4 damage in 10 s, death 15, 1 point per 5 gate HP, 3
   per capture %, capture 100, trickle 10 per 60 s) and **Allow teammate transfers** off.
3. Accounts and data: A1, A2, D1; a Ready Siege scenario with at least one gate and one capturable objective; a lobby
   that can start with three players.

### 1.1 Steps

1. A1, A2 and D1 join and the match starts. **Expected:** each player's sidebar shows "Siege points: 0"; each sees
   only their own number. (A04, A10)
2. A1 kills D1 with a sword. **Expected:** A1's action bar shows "+100 kill · 100"; D1's shows "+15 death · 15". (A05,
   A07)
3. A2 hits D1 for at least 2 hearts, then within 10 s A1 kills D1. **Expected:** A1 gets the kill (×1.1 as the 2nd of
   the streak: 110), A2 gets "+40 assist". (A05, A06)
4. A2 hits D1 for half a heart only, then A1 kills D1 within 10 s. **Expected:** no assist for A2. (A06)
5. A2 hits D1 for 2 hearts, waits 15 s, then A1 kills D1. **Expected:** no assist for A2. (A06)
6. A1 keeps killing D1 until six kills in a row. **Expected:** kills 2–6 pay 110, 120, 130, 140, 150; a 7th still pays
   150. (A05)
7. D1 kills A1. **Expected:** A1's next kill pays 100 again (streak reset). (A05)
8. Friendly fire is off; A1 jumps from a height and dies. **Expected:** A1 gets "+15 death"; no kill points to anyone.
   (A07)
9. A1 damages a gate door by 50 HP. **Expected:** A1 earns 10 points. (A08)
10. A1 and A2 stand in an objective's capture radius while it moves 10 % towards the attackers. **Expected:** each
    earns 30 points; D1, standing outside the radius, earns nothing. D1 then enters and pushes it back 5 %. **Expected:**
    D1 earns 15. (A08)
11. The attackers capture the objective with A1 inside and A2 outside. **Expected:** A1 earns 100 for the capture; A2
    does not. (A08)
12. A2 stands still at spawn for two minutes while A1 keeps playing. **Expected:** A1 gets "+10" each minute; A2 gets
    nothing. (A09)
13. `/siege points` as A1. **Expected:** balance, earned and spent this match, matching the action bar totals. (A10)
14. `/siege pay A2 50` as A1. **Expected:** refused, transfers are off in PvP Siege. Admin turns **Allow teammate
    transfers** on and a new match starts; repeat. **Expected:** A1 −50, A2 +50; `/siege pay A2 999999` is refused
    and nothing changes; `/siege pay D1 10` is refused (not a teammate). (A01, A03)
15. The match ends. **Expected:** the result shows siege points earned and spent per participant; in the next match
    everyone starts at 0. (A04, A11)
16. Admin sets `siege.points.enabled: false` and restarts; play a kill. **Expected:** no siege points line, no action
    bar points, `/siege points` says the feature is off. (A12)
17. Retry safety (A02) is checked by the ledger tests only: a charge repeated with the same retry id debits once.

## 2. Phase 2: shop catalogue entities, scenario overrides and web app forms (#867, tier:2)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with the phase 2 migration and seeds; knk-web-app from `next`.
2. Settings: none.
3. Accounts and data: Admin; one Siege scenario; the siege weapon templates of the weapons phase 1.

### 2.1 Steps

1. Admin opens Siege → Shop entries. **Expected:** the seeded PvP Siege entries (ender pearl, splash healing II, golden
   apple, regeneration, three weapons) and their Survival copies, under the seeded categories. (A13)
2. Admin edits the ender pearl's price to 350 and saves. **Expected:** saved; the list shows 350. (A13)
3. Admin creates an Item entry with a weapon template instead of an item blueprint. **Expected:** refused with a clear
   message; nothing saved. (A14)
4. On the scenario, Admin hides the golden apple, overrides the pearl's cap to 4 and adds a scenario-only entry. Open
   `GET api/SiegeShop/catalogue?mode=Siege&scenarioId=<id>`. **Expected:** no golden apple, the pearl with cap 4 and
   the other fields from the default, the scenario-only entry present. (A15)
5. In the same response, look at a weapon entry with an empty price. **Expected:** its price is the template's
   `MatchPrice` (200 by default). (A16)

## 3. Phase 3: shop menus and purchases in the plugin (#868, tier:3)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: phases 1 and 2; knk-plugin from `next` with this phase.
2. Settings: `siege.points.enabled: true`, `siege.shop.enabled: true`; to test weapon entries also
   `siege.weapons.enabled: true`.
3. Accounts and data: A1, A2, D1; the seeded catalogue with the ender pearl at 300, +50 linear, cooldown 20 s +10 s
   exponential ×1.5, cap 8; A1 has not unlocked the trebuchet. A Siege Survival scenario for step 13.

### 3.1 Steps

1. In a running match A1 types `/siege shop`, then opens `/siege menu` → Shop. **Expected:** the shop opens both
   ways, anywhere on the map, with the balance in the title, categories Siege weapons and Consumables, no empty Magic
   category. (A17)
2. A1 with 400 points buys an ender pearl. **Expected:** 300 charged, 1 pearl in the inventory, the line now shows
   350, "bought 1/8" and a 20 s cooldown. (A18, A20, A21)
3. A1 clicks the pearl again during the cooldown. **Expected:** "Cooldown: N s"; nothing charged. (A19)
4. After the cooldown, A1 with 100 points clicks the pearl. **Expected:** "Not enough siege points: 100/350";
   nothing charged. (A19)
5. A1 earns enough and buys pearls until the cap. **Expected:** prices 350, 450, 600, 800, …; cooldowns 30, 45, 67.5 s
   …; after the 8th, "Limit reached: 8 per match". (A20, A21, A22)
6. A1 fills every inventory slot and buys a healing potion. **Expected:** "Inventory full"; nothing charged. (A19)
7. A1 clicks the trebuchet entry. **Expected:** shown as locked with "unlock in /menu → Minigames → Siege unlocks";
   nothing charged, no spot picker. (A26)
8. During the match Admin changes the pearl's price in the web app. **Expected:** the shop keeps the old price; the
   next match uses the new one. (A23)
9. The match ends while A1 holds 3 unused pearls. **Expected:** the pearls are gone after the gear restore; no
   refund; the result shows spent points. (A11, A24)
10. In a new match A1's pearl price, cooldown and count start over. **Expected:** 300, no cooldown, 0/8. (A22)
11. A1 throws a bought pearl over the castle wall. **Expected:** vanilla behaviour, A1 lands inside. (P04)
12. The telemetry for the test run shows a `siege.shop.purchase` event per purchase with entry, price and purchase
    number. (A11)
13. In a Siege Survival match (after the Survival branch has merged): A1 earns siege points from NPC kills, buys a
    pearl in `/siege shop`, then buys at a purchase point and rolls the Mystery Box. **Expected:** all three charge the
    same balance; `/siege shop` opens the siege shop even next to a purchase point. (A17, A25)

## 4. Phase 4: siege weapon unlocks with coins and title level (#869, tier:2)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: phase 2; knk-web-api, knk-web-app and knk-plugin from `next` with this phase.
2. Settings: the trebuchet template with unlock price 1000 coins and minimum title level set to A1's title + 1; the
   ballista with 500 coins and no minimum.
3. Accounts and data: A1 with 1200 coins and a web account.

### 4.1 Steps

1. Outside a match A1 opens the main menu → Minigames → Siege unlocks. **Expected:** each template with price,
   minimum title and state; the trebuchet says "Needs title …". (A27)
2. A1 clicks the trebuchet. **Expected:** refused for the title level; coins unchanged. (A27)
3. A1 clicks the ballista and confirms, double-clicking fast. **Expected:** one charge of 500 coins, the ballista shows
   "Unlocked". (A27)
4. A1 joins a match and opens the main menu's Siege unlocks. **Expected:** unlocking is refused during a match; the
   shop's ballista entry is no longer locked. (A26, A28)
5. On the web app A1 opens their profile → Siege unlocks. **Expected:** the same list; the ballista unlocked;
   unlocking another type there charges coins once. (A27)

## 5. Phases 5a and 5b: menu item settings (#870, #871, tier:2)

*Draft from the design (2026-11-20); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: knk-web-api and knk-web-app with phase 5a; knk-plugin with phase 5b (and phase 3 for the shop target).
2. Settings: the seeded menu item settings (default clicks open `main`; siege match overrides open
   `siege.information` and, on shift-right, `siege.shop`).
3. Accounts and data: Admin; A1 online in the hub.

### 5.1 Steps

1. Admin opens the game settings page → Menu item, changes the name and sets shift-left to run `siege points`, then
   saves. **Expected:** A1's item shows the new name within seconds, without a restart, in the same slot. (A29)
2. Outside a match A1 right-clicks the item. **Expected:** the main menu opens. (A30)
3. In a running PvP match A1 right-clicks, then shift-right-clicks the item. **Expected:** the siege menu, then the
   siege shop. In a Survival match the same. (A30)
4. With the API stopped, restart the plugin and join as A1. **Expected:** the menu item is given from the `config.yml`
   keys and opens the main menu. (A31)
