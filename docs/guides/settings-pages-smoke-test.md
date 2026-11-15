# Settings pages: units and help, confirms on risky switches, lootbox preview, three pages on the settings shell (#26) — smoke test

**Status:** automated in CI; manual steps not run. Written 2026-11-08 for knk-web-app `claude/settings-pages-26` (chain 3 link V4); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7); 22 of 26 steps automated 2026-11-14 ([#511](https://github.com/PandiO/knk-workspace/issues/511)); left: the game-server halves of 2.5 and 3.4 (1.6's runs as a plugin scenario since 2026-11-14), steps 3.5, 3.6, 4.2 and the themes
**Last updated:** 2026-11-14 (§ 1 step 6's game half: plugin scenario, plugin backfill #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (test on `main`, docs #342); 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#26](https://github.com/PandiO/knk-workspace/issues/26) (SET-5, SET-6 and #38's
lootbox preview / "1 in N" odds); the shell is [#187](https://github.com/PandiO/knk-workspace/issues/187)'s `SettingsPage`

About 10 minutes for the manual steps left. Steps marked `[automated]` run in CI: the Playwright spec
`e2e/settings-pages.spec.ts` in knk-web-app (CI job `e2e`, mocked API) and the Jest tests next to the pages (CI job
`build-and-test`); you don't repeat them. **No API change, no migration, no setting.** Since the 2026-11-12 merge, test it on knk-web-app `main`
(from `1371951`); the feature branch was `claude/settings-pages-26`.

You need:
- **A** — the owner or an Admin account (holds `knk.admin.lootbox.manage`, `knk.admin.currency.policy`, `knk.admin.road`,
  `knk.admin.config`, `knk.siege.admin.manage`).
- A test game server is optional: steps 1.6, 2.5 and 3.4 can be checked in game.
- Do it on a test or dev database: steps switch lootboxes and payments off and on again.

Each migrated page has the same header: title, "Last saved …", "n unsaved changes", Reload, Discard, **Save (n)**.

## 1. Lootboxes → Settings

1. [automated] The tab's own header **Lootbox settings** (h2 under the page title), the cards, "No unsaved changes.":
   `e2e/settings-pages.spec.ts`, `src/pages/admin/__tests__/LootboxSettingsTab.v4.test.tsx`
2. [automated] Units and help; the announce thresholds as choices with **Never** and what each means:
   `LootboxSettingsTab.v4.test.tsx`
3. [automated] A change: "1 unsaved change.", Limits **Changed**; the Areas tab asks "Leave without saving?" with focus
   on Stay; Stay keeps the value, Leave switches: `LootboxSettingsTab.v4.test.tsx`, `e2e/settings-pages.spec.ts`
4. [automated] A sidebar link with a change asks the same (Stay / Leave); closing or reloading the tab asks the browser's
   question, without a change it doesn't: `e2e/settings-pages.spec.ts`
5. [automated] The announcement previews with sample values, "(the default)" for an empty template, `{loot}` named as not
   filled in: `LootboxSettingsTab.v4.test.tsx`
6. [automated] Unticking **Lootboxes enabled** asks "Switch lootboxes off?" (red); Cancel saves nothing; **Switch off and
   save** saves with the toast "Lootbox settings saved." and a clean header: `e2e/settings-pages.spec.ts`,
   `LootboxSettingsTab.v4.test.tsx`. [automated] The game half: after the runtime refresh reads lootboxes switched off, the
   plugin's spawn scheduler asks for no more boxes (it did while they were on): knk-plugin plugin scenario
   `lootbox-switched-off-spawns-nothing` (CI `paper-boot`). *(Manual)* against the real API: switch it on again.
7. [automated] A refused save shows the API's reason in red in the header and keeps the value:
   `e2e/settings-pages.spec.ts`
8. [automated] A type's Enabled/Disabled chip asks "Disable {type}?" / "Enable {type}?"; the action switches it:
   `src/pages/admin/__tests__/LootboxesPage.test.tsx`, `src/components/lootbox/__tests__/LootboxTypesTab.gate.test.tsx`
9. [automated] Unticking a grant rule asks "Switch this rule off?" naming the trigger and tokens; Cancel keeps it:
   `src/pages/admin/__tests__/LootboxTokensTab.test.tsx`
10. [automated] Small chances show "1 in N", 50% and more don't: `src/utils/__tests__/settingsUnits.test.ts`,
    `LootboxesPage.test.tsx` (odds table)

## 2. Currency policy

1. [automated] One header for both currencies, Coins and Gems as cards: `e2e/settings-pages.spec.ts`,
   `src/pages/admin/economy/__tests__/CurrencyPolicyPage.test.tsx`
2. [automated] Units (coins, gems, s, h, bp) and what a value means ("= 2.5%", "= no fee", "= 10 min"):
   `CurrencyPolicyPage.test.tsx`, `settingsUnits.test.ts`
3. [automated] **Lowest sender title** lists the titles lowest first with None, and saves the pick:
   `CurrencyPolicyPage.test.tsx`
4. [automated] A Coins and a Gems change: "2 unsaved changes.", both cards **Changed**; a sidebar link asks, Stay keeps
   both; Save (2) sends both and shows "Saved the coins and gems policies.": `e2e/settings-pages.spec.ts`,
   `CurrencyPolicyPage.leave.test.tsx`
5. [automated] Unticking the coins kill switch asks "Switch coins payments off?" in red; Cancel saves nothing; the
   question is worded by direction: `CurrencyPolicyPage.test.tsx`. *(Game, manual: a player's command, simulated
   players [#540](https://github.com/PandiO/knk-workspace/issues/540).)* With payments off, `/pay` with coins answers
   that transfers are switched off; switch it on again.
6. [automated] A policy changed since loading: the header says "Coins: This policy was changed since you loaded it …",
   Save stays off, **Reload current policy** shows the current values: `e2e/settings-pages.spec.ts`,
   `CurrencyPolicyPage.test.tsx`

## 3. Road network

1. [automated] The header (Reload, Discard, Save) and the Navigation defaults / compass cards:
   `e2e/settings-pages.spec.ts`, `src/pages/admin/__tests__/RoadsAdminPage.settings.test.tsx`
2. [automated] A default destination no longer saves at once; "1 unsaved change.", the card **Changed**:
   `RoadsAdminPage.settings.test.tsx`, `e2e/settings-pages.spec.ts`
3. [automated] A compass change makes "2 unsaved changes."; leaving asks (Stay keeps both); **Discard** puts both back:
   `e2e/settings-pages.spec.ts`, `RoadsAdminPage.settings.test.tsx`
4. [automated] Save (2): toast "Saved 2 changes. The game server picks them up within a minute." and both requests:
   `e2e/settings-pages.spec.ts`. *(Game, manual: a player's command and compass,
   simulated players #540.)* Within a minute `/navigate <town>` without spawn/region uses the new default; the new
   compass material works.
5. *(Manual, not automated yet.)* Records keep their own Save: a stretch's **Save stretch #n**, a profile's **Save
   profile**; not counted in the header, no question before leaving (LV4-4).
6. *(Manual, not automated yet.)* Switch world to one that doesn't exist: the error shows under Overview and the World
   field stays usable.

## 4. Units on Siege and Game settings

1. [automated] Siege settings: ticks with "= 1 s" for 20, ‰ with "= 3%" for 30, the side-capture reduction "= 40%"
   for 0.4: `e2e/settings-pages.spec.ts`; the conversions themselves: `settingsUnits.test.ts`
2. *(Manual, not automated yet.)* Game settings → a world: **Locked Time** shows **ticks** and "= 00:00 (midnight)" for
   18000; the hub's healing/feeding intervals show their seconds in brackets (the conversion is in
   `settingsUnits.test.ts`).

## 5. Themes, background and phone width

1. *(Manual: visual check of the themes.)* Repeat 1.1, 2.1 and 3.1 with the theme switch on **current** and **brand**,
   and with the page background on and off. Headers, Changed marks, units and the dark preview read well in each.
2. [automated] At 390 px no settings page scrolls sideways: `e2e/settings-pages.spec.ts`. Glance during 5.1 that the
   sticky header shows Reload as an icon and the questions fit the screen.

