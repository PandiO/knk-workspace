# Settings pages: units and help, confirms on risky switches, lootbox preview, three pages on the settings shell (#26) — smoke test

**Status:** Written 2026-11-08 for knk-web-app `claude/settings-pages-26` (chain 3 link V4); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-12 (test on `main`, docs #342); 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#26](https://github.com/PandiO/knk-workspace/issues/26) (SET-5, SET-6 and #38's
lootbox preview / "1 in N" odds); the shell is [#187](https://github.com/PandiO/knk-workspace/issues/187)'s `SettingsPage`

About 25 minutes. **No API change, no migration, no setting.** Since the 2026-11-12 merge, test it on knk-web-app `main`
(from `1371951`); the feature branch was `claude/settings-pages-26`.

You need:
- **A** — the owner or an Admin account (holds `knk.admin.lootbox.manage`, `knk.admin.currency.policy`, `knk.admin.road`,
  `knk.admin.config`, `knk.siege.admin.manage`).
- A test game server is optional: steps 1.6, 2.5 and 3.4 can be checked in game.
- Do it on a test or dev database: steps switch lootboxes and payments off and on again.

Each migrated page has the same header: title, "Last saved …", "n unsaved changes", Reload, Discard, **Save (n)**.

## 1. Lootboxes → Settings

1. Open Admin → Lootboxes → **Settings**. The tab shows its own header **Lootbox settings** (Reload, Discard, Save) under
   the page title, then three cards: Lootboxes, Limits, Announcements. "No unsaved changes."
2. **Units and help:** Max active boxes and Boxes per player per UTC day show **boxes** right of the input and one line
   of help under it. The two announce thresholds are choices: "★1 and better" … "★10 and better", **Never**. Pick Never for
   drops: the line under it says no drop is announced, specials still are.
3. **Dirty and leave:** change Max active boxes. The header says "1 unsaved change.", the Limits card shows **Changed**.
   Click the **Areas** tab: "Leave without saving? 1 unsaved change in Lootbox settings will be lost." with focus on
   **Stay**. Stay: still on Settings with your value. Click Areas again → **Leave**: the Areas tab opens. Back on Settings
   the old value is shown.
4. Change a value and click a sidebar link (e.g. Road network): the same question. Change a value and reload the browser:
   the browser asks.
5. **Preview:** under Drop announcement a dark line shows the message with sample values ("Steve found [Golemheart Sword]
   in a Weapons Lootbox ★★★★★!") in its colours. Empty the Spawn announcement: its preview says "(the default)" and shows
   the default text. Type `{loot}` into a template: the help says it is not filled in by the game.
6. **Risky switch:** untick **Lootboxes enabled**, Save (1): "Switch lootboxes off?" in red, saying nothing spawns and no
   box can be claimed. **Cancel**: nothing saved, still 1 unsaved change. Save again → **Switch off and save**: a green
   toast "Lootbox settings saved.", "No unsaved changes." *(Game)* After the next runtime refresh nothing spawns. Tick it
   again, Save → "Switch lootboxes on?" (not red) → Switch on and save.
7. **Refusal:** set Max active boxes to a value the API refuses (if it has a cap) or stop the API and Save: the reason
   shows in red in the header, the value stays.
8. **Types** tab: click a type's **Enabled/Disabled** chip: "Disable {type}?" / "Enable {type}?" says what happens; Cancel
   changes nothing, the action button switches it.
9. **Token items** tab → Grant rules: untick a rule's Enabled: "Switch this rule off?" names the trigger and the tokens;
   Cancel keeps it ticked.
10. **Odds** tab: small chances show "1 in N" under the percentage (specials' own chance and "Gives it", grades' "Of the
    box", items' "Of the box"); chances of 50% and more show no "1 in N".

## 2. Currency policy

1. Open Admin → Economy → **Currency policy**. One header for both currencies; Coins and Gems are cards with Switches,
   Payments, Limits per player, Balances and grants.
2. **Units:** amounts show **coins** / **gems**, Confirm window and Cooldown **s**, Sender account age **h**, Transfer fee
   **bp**. Type 250 in Transfer fee: the help ends "= 2.5%"; 0 says "= no fee". Type 600 in Cooldown: "= 10 min".
3. **Lowest sender title** is a list of the titles, lowest first ("Peasant (from 0 XP)" …) with **None**. Pick one, Save:
   reload the page, it is kept.
4. **Dirty and leave:** change a Coins and a Gems value: "2 unsaved changes.", both cards **Changed**. Click a sidebar link:
   "Leave without saving?"; Stay keeps both. Save (2): toast "Saved the coins and gems policies."
5. **Kill switch:** untick Coins **Payments switched on (kill switch)**, Save (1): "Switch coins payments off?" in red,
   saying no player can send coins with /pay until switched on again. Cancel: nothing saved. Save → **Switch off and
   save**. *(Game)* `/pay` with coins answers that transfers are switched off. Tick it again, Save → "Switch coins
   payments on?" (not red) → Switch on and save.
6. **Stale policy:** open the page in two tabs. In tab 1 change Signup grant and Save. In tab 2 change Maximum payment
   and Save: the header says "Coins: This policy was changed since you loaded it …", Save stays off, the Coins card shows
   the same text with **Reload current policy**. Click it: tab 1's values show.

## 3. Road network

1. Open Admin → **Road network**. The header has Reload, Discard, Save; the cards are Overview (World, Switch world, the
   counts), Road profiles, Tiles, Stretches, **Navigation defaults**, **Navigation compass**.
2. **Navigation defaults:** change Towns' Default destination. It no longer saves at once: the select gets an orange
   border, the card **Changed**, the header "1 unsaved change."
3. **Compass:** change the Material. "2 unsaved changes." Click a sidebar link: "Leave without saving?"; Stay keeps both.
   **Discard** → Discard: both go back.
4. Change both again and Save (2): toast "Saved 2 changes. The game server picks them up within a minute." *(Game)* within
   a minute `/navigate <town>` without spawn/region uses the new default; the new compass material works.
5. **Records keep their own Save:** edit a stretch (pencil): its button is **Save stretch #n**; profiles have **Save
   profile**. These are not counted in the header and don't ask before leaving (LV4-4).
6. Switch world to one that doesn't exist: the error shows under Overview and the World field stays usable.

## 4. Units on Siege and Game settings

1. Siege settings: Capture fields show **points/s**, timeline and skip fields **s**, the respawn delay **ticks** with
   "= 1 s" for 20, the book drop chance **‰** with "= 3%" for 30, the headshot multiplier **×**; side-capture reduction says
   "= 40%" for 0.4.
2. Game settings → a world: **Locked Time** shows **ticks** and "= 00:00 (midnight)" for 18000; the hub's healing/feeding
   intervals show their seconds in brackets.

## 5. Themes, background and phone width

1. Repeat 1.1, 2.1 and 3.1 with the theme switch on **current** and **brand**, and with the page background on and off.
   Headers, Changed marks, units and the dark preview read well in each.
2. At **390 px** (phone or the browser's device mode): no page scrolls sideways; the sticky header shows Reload as an icon;
   the unit boxes sit right of their inputs; the leave and switch questions fit the screen.
