# Settings pages: units and help, confirms on risky switches, lootbox preview, three pages on the settings shell (#26) — smoke test

**Status:** 22 of 26 steps automated in CI (tagged, 5 of them partly; [#511](https://github.com/PandiO/knk-workspace/issues/511), 2026-11-14); every step can still be run by hand; manual steps not run. Written 2026-11-08 for knk-web-app `claude/settings-pages-26` (chain 3 link V4); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7); by hand: the game-server halves of 2.5 and 3.4 (1.6's runs as a plugin scenario since 2026-11-14), steps 3.5, 3.6, 4.2 and the themes
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-14 (§ 1 step 6's game half: plugin scenario, plugin backfill #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (test on `main`, docs #342); 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#26](https://github.com/PandiO/knk-workspace/issues/26) (SET-5, SET-6 and #38's
lootbox preview / "1 in N" odds); the shell is [#187](https://github.com/PandiO/knk-workspace/issues/187)'s `SettingsPage`

About 25 minutes for a full manual run, about 10 for the untagged steps and the by-hand parts. Steps tagged
`[automated: …]` run in CI: the Playwright spec `e2e/settings-pages.spec.ts` in knk-web-app (CI job `e2e`, mocked API)
and the Jest tests next to the pages (CI job `build-and-test`): skip them or run them by hand. **No API change, no migration, no setting.** Since the 2026-11-12 merge, test it on knk-web-app `main`
(from `1371951`); the feature branch was `claude/settings-pages-26`.

You need:
- **A** — the owner or an Admin account (holds `knk.admin.lootbox.manage`, `knk.admin.currency.policy`, `knk.admin.road`,
  `knk.admin.config`, `knk.siege.admin.manage`).
- A test game server is optional: steps 1.6, 2.5 and 3.4 can be checked in game.
- Do it on a test or dev database: steps switch lootboxes and payments off and on again.

Each migrated page has the same header: title, "Last saved …", "n unsaved changes", Reload, Discard, **Save (n)**.

## 1. Lootboxes → Settings

1. [automated: `e2e/settings-pages.spec.ts`, `src/pages/admin/__tests__/LootboxSettingsTab.v4.test.tsx`] Open Admin → Lootboxes → **Settings**. The tab shows its own header **Lootbox settings** (Reload, Discard, Save) under
   the page title, then three cards: Lootboxes, Limits, Announcements. "No unsaved changes."
2. [automated: `LootboxSettingsTab.v4.test.tsx`] **Units and help:** Max active boxes and Boxes per player per UTC day show **boxes** right of the input and one line
   of help under it. The two announce thresholds are choices: "★1 and better" … "★10 and better", **Never**. Pick Never for
   drops: the line under it says no drop is announced, specials still are.
3. [automated: `LootboxSettingsTab.v4.test.tsx`, `e2e/settings-pages.spec.ts`] **Dirty and leave:** change Max active boxes. The header says "1 unsaved change.", the Limits card shows **Changed**.
   Click the **Areas** tab: "Leave without saving? 1 unsaved change in Lootbox settings will be lost." with focus on
   **Stay**. Stay: still on Settings with your value. Click Areas again → **Leave**: the Areas tab opens. Back on Settings
   the old value is shown.
4. [automated: `e2e/settings-pages.spec.ts`] Change a value and click a sidebar link (e.g. Road network): the same question. Change a value and reload the browser:
   the browser asks.
5. [automated: `LootboxSettingsTab.v4.test.tsx`] **Preview:** under Drop announcement a dark line shows the message with sample values ("Steve found [Golemheart Sword]
   in a Weapons Lootbox ★★★★★!") in its colours. Empty the Spawn announcement: its preview says "(the default)" and shows
   the default text. Type `{loot}` into a template: the help says it is not filled in by the game.
6. [partly automated: `e2e/settings-pages.spec.ts`, `LootboxSettingsTab.v4.test.tsx`; the game half (after the runtime refresh reads lootboxes switched off, the spawn scheduler asks for no more boxes) is the knk-plugin plugin scenario `lootbox-switched-off-spawns-nothing` (CI `paper-boot`); by hand: switching it on again against the real API] **Risky switch:** untick **Lootboxes enabled**, Save (1): "Switch lootboxes off?" in red, saying nothing spawns and no
   box can be claimed. **Cancel**: nothing saved, still 1 unsaved change. Save again → **Switch off and save**: a green
   toast "Lootbox settings saved.", "No unsaved changes." *(Game)* After the next runtime refresh nothing spawns. Tick it
   again, Save → "Switch lootboxes on?" (not red) → Switch on and save.
7. [automated: `e2e/settings-pages.spec.ts`] **Refusal:** set Max active boxes to a value the API refuses (if it has a cap) or stop the API and Save: the reason
   shows in red in the header, the value stays.
8. [automated: `src/pages/admin/__tests__/LootboxesPage.test.tsx`, `src/components/lootbox/__tests__/LootboxTypesTab.gate.test.tsx`] **Types** tab: click a type's **Enabled/Disabled** chip: "Disable {type}?" / "Enable {type}?" says what happens; Cancel
   changes nothing, the action button switches it.
9. [automated: `src/pages/admin/__tests__/LootboxTokensTab.test.tsx`] **Token items** tab → Grant rules: untick a rule's Enabled: "Switch this rule off?" names the trigger and the tokens;
   Cancel keeps it ticked.
10. [automated: `src/utils/__tests__/settingsUnits.test.ts`, `LootboxesPage.test.tsx` (odds table)] **Odds** tab: small chances show "1 in N" under the percentage (specials' own chance and "Gives it", grades' "Of the
    box", items' "Of the box"); chances of 50% and more show no "1 in N".

## 2. Currency policy

1. [automated: `e2e/settings-pages.spec.ts`, `src/pages/admin/economy/__tests__/CurrencyPolicyPage.test.tsx`] Open Admin → Economy → **Currency policy**. One header for both currencies; Coins and Gems are cards with Switches,
   Payments, Limits per player, Balances and grants.
2. [automated: `CurrencyPolicyPage.test.tsx`, `settingsUnits.test.ts`] **Units:** amounts show **coins** / **gems**, Confirm window and Cooldown **s**, Sender account age **h**, Transfer fee
   **bp**. Type 250 in Transfer fee: the help ends "= 2.5%"; 0 says "= no fee". Type 600 in Cooldown: "= 10 min".
3. [automated: `CurrencyPolicyPage.test.tsx`] **Lowest sender title** is a list of the titles, lowest first ("Peasant (from 0 XP)" …) with **None**. Pick one, Save:
   reload the page, it is kept.
4. [automated: `e2e/settings-pages.spec.ts`, `CurrencyPolicyPage.leave.test.tsx`] **Dirty and leave:** change a Coins and a Gems value: "2 unsaved changes.", both cards **Changed**. Click a sidebar link:
   "Leave without saving?"; Stay keeps both. Save (2): toast "Saved the coins and gems policies."
5. [partly automated: `CurrencyPolicyPage.test.tsx` (the question, worded by direction; Cancel saves nothing); by hand: the game half, `/pay` with coins while payments are off (a player's command, simulated players [#540](https://github.com/PandiO/knk-workspace/issues/540))] **Kill switch:** untick Coins **Payments switched on (kill switch)**, Save (1): "Switch coins payments off?" in red,
   saying no player can send coins with /pay until switched on again. Cancel: nothing saved. Save → **Switch off and
   save**. *(Game)* `/pay` with coins answers that transfers are switched off. Tick it again, Save → "Switch coins
   payments on?" (not red) → Switch on and save.
6. [automated: `e2e/settings-pages.spec.ts`, `CurrencyPolicyPage.test.tsx`] **Stale policy:** open the page in two tabs. In tab 1 change Signup grant and Save. In tab 2 change Maximum payment
   and Save: the header says "Coins: This policy was changed since you loaded it …", Save stays off, the Coins card shows
   the same text with **Reload current policy**. Click it: tab 1's values show.

## 3. Road network

1. [automated: `e2e/settings-pages.spec.ts`, `src/pages/admin/__tests__/RoadsAdminPage.settings.test.tsx`] Open Admin → **Road network**. The header has Reload, Discard, Save; the cards are Overview (World, Switch world, the
   counts), Road profiles, Tiles, Stretches, **Navigation defaults**, **Navigation compass**.
2. [automated: `RoadsAdminPage.settings.test.tsx`, `e2e/settings-pages.spec.ts`] **Navigation defaults:** change Towns' Default destination. It no longer saves at once: the select gets an orange
   border, the card **Changed**, the header "1 unsaved change."
3. [automated: `e2e/settings-pages.spec.ts`, `RoadsAdminPage.settings.test.tsx`] **Compass:** change the Material. "2 unsaved changes." Click a sidebar link: "Leave without saving?"; Stay keeps both.
   **Discard** → Discard: both go back.
4. [partly automated: `e2e/settings-pages.spec.ts` (the toast and both requests); by hand: the game half, `/navigate` and the compass (a player's command, simulated players #540)] Change both again and Save (2): toast "Saved 2 changes. The game server picks them up within a minute." *(Game)* within
   a minute `/navigate <town>` without spawn/region uses the new default; the new compass material works.
5. *(Manual, not automated yet.)* **Records keep their own Save:** edit a stretch (pencil): its button is **Save stretch #n**; profiles have **Save
   profile**. These are not counted in the header and don't ask before leaving (LV4-4).
6. *(Manual, not automated yet.)* Switch world to one that doesn't exist: the error shows under Overview and the World field stays usable.

## 4. Units on Siege and Game settings

1. [partly automated: `e2e/settings-pages.spec.ts` (ticks, ‰ and the side-capture reduction), the conversions in `settingsUnits.test.ts`; by hand: the **points/s**, **s** and **×** units] Siege settings: Capture fields show **points/s**, timeline and skip fields **s**, the respawn delay **ticks** with
   "= 1 s" for 20, the book drop chance **‰** with "= 3%" for 30, the headshot multiplier **×**; side-capture reduction says
   "= 40%" for 0.4.
2. *(Manual, not automated yet; the tick conversion itself is in `settingsUnits.test.ts`.)* Game settings → a world: **Locked Time** shows **ticks** and "= 00:00 (midnight)" for 18000; the hub's healing/feeding
   intervals show their seconds in brackets.

## 5. Themes, background and phone width

1. *(Manual: visual check of the themes.)* Repeat 1.1, 2.1 and 3.1 with the theme switch on **current** and **brand**, and with the page background on and off.
   Headers, Changed marks, units and the dark preview read well in each.
2. [partly automated: `e2e/settings-pages.spec.ts` (no page scrolls sideways); by hand: Reload as an icon, the unit boxes, the questions fit the screen] At **390 px** (phone or the browser's device mode): no page scrolls sideways; the sticky header shows Reload as an icon;
   the unit boxes sit right of their inputs; the leave and switch questions fit the screen.

