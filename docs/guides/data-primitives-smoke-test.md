# Web app data and format primitives: tables, formats, labels, settings pages (#187) — smoke test

**Status:** Written 2026-11-05 for knk-web-app `claude/data-primitives-187` (chain 2 link W3); **merged 2026-11-12** (knk-web-app `main` `1371951`); not run by the developer
**Last updated:** 2026-11-12 (merged; run on `main`, docs #339); 2026-11-06 (numbers in the browser's language, LW3-1)
**Issues:** [PandiO/knk-workspace#187](https://github.com/PandiO/knk-workspace/issues/187) (`DataTable`/`Pager`,
`format.ts`, `Field`, `SettingsPage` shell; sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24))
**Branches:** merged 2026-11-12 into knk-web-app `main` `1371951` (with #33, #30 and chain 3 V1–V7, whose settings
pages build on this shell: see the [settings pages smoke test](settings-pages-smoke-test.md)); the feature branch was
knk-web-app `claude/data-primitives-187`. No
API or plugin change, no migration, no setting.
**Chain:** [UX_CHAIN_2.md](../ai-agents/handoffs/UX_CHAIN_2.md) link W3; report
[2026-11-05-ux-chain-2.md](../reports/2026-11-05-ux-chain-2.md) (W3 block). Design notes:
[web-app architecture § Data and format primitives](../architecture/web-app-architecture.md#data-and-format-primitives-tables-pager-formatting-fields-settings-pages).

Web app only: knk-web-app `main` (from `1371951`), `npx npm@11 ci` if needed, `npm start`, against
the dev API on trunk. Log in as an admin with `knk.admin.content`, `knk.admin.config`, `knk.siege.admin.manage` and the
moderation node. Because the branch contains #33, the [feedback primitives smoke test](feedback-primitives-smoke-test.md)
can run on the same checkout. Run the sections in the `current` and the `brand` theme (cogwheel theme switcher), once
with the page background on and once off ("Background image" in the same menu), and sections 2 and 4 once at phone
width (browser dev tools, 390 px). Record each step in **Findings** at the end.

What changed for you: the dashboard and moderation lists share one table and pager; dates show in your own time and
numbers in your browser's language (`1,234,567` in English, `1.234.567` in Dutch); Game Settings and Siege configuration have one header with "n unsaved changes", Discard and
Save (n), and ask before you lose changes.

## 1. Dashboard table (it now draws through `DataTable`/`Pager`)

1. Dashboard → a type with a display configuration (e.g. Domain). The table looks as before (same columns, ⋯/👁/✎/🗑
   on the right, pager below when there are more than 10 rows).
2. Click a column header: it sorts ascending (arrow up), again descending, a third time unsorted; the URL follows
   (`?sort=…&dir=desc`). Tab to a header and press Enter: it sorts too.
3. Click a row's first cell (the link): its detail page opens in the app. Back: the same page, search and sort.
4. Ctrl/Cmd-click or middle-click the first cell: the detail page opens in a new tab; the dashboard stays.
5. Click elsewhere on a row: it opens like the link. Click the row's 🗑: only the delete question opens.
6. Next / Previous under the table: "Page 2 of n", the URL has `?page=2`.
7. Open a form with a picker (e.g. a Town's district list → Select): pick rows; selected rows get the green edge and
   check mark, a row created in this form is under "Created in this form" with a New badge, as before.

## 2. Player moderation

1. Moderation → **All players**: one table with Username, Email, Status, Coins and XP; coins and XP are right-aligned
   and read like `12,345` in an English browser, `12.345` in a Dutch one (LW3-1, developer's decision 2026-11-06:
   numbers follow the browser's language). Switch the browser's language (Chrome: Settings → Languages, put Dutch
   first and restart; Firefox: Settings → Language) and reload to see the other form.
2. Under it: "Showing 1 to 20 of n players", Previous, "Page 1 of x", Next. Next and Previous load the other pages.
3. The search box is named by its label (screen reader, or click the label: the cursor goes into the box). Search with
   a name; Enter works.
4. Click a player's name: their profile opens. Ctrl-click: in a new tab. Click elsewhere on the row: the profile opens.
5. **By group / online**, **Premium expiring soon**, **Recently demoted**: the same table style; "Last seen", "Expires"
   and "When" are your local date and time (e.g. "5-11-2026, 21:52" with a Dutch browser), not UTC text. Clicking the
   "Currently online only" text ticks its box.
6. At 390 px: the header buttons (Balance log …) wrap onto more lines; the page does not scroll sideways (a wide
   table scrolls inside its own box).

## 3. Dates and numbers elsewhere

1. A detail page (Dashboard → a row → 👁): a date field such as Created shows a date and time in your own time, not
   `2026-11-05T20:52:02`. A configured integer field shows `1,234,567` (English browser) or `1.234.567` (Dutch).
2. Account → Transactions: the time column is your local date and time (was UTC text like `2026-11-05 20:52`), and the
   same moment as the Balance log shows for that entry.
3. Balance log, Currency alerts, Orphaned Locations, a transaction's detail page: dates look as before; amounts and
   counts follow the browser's language like the moderation list (`12.345` in Dutch). Pages not on `format.ts` yet
   (statistics, roads, lootbox counts) still show `12,345` in every language.

## 4. Settings pages on the shell (Siege configuration, Game Settings)

1. Siege configuration: a header with the title, "Last saved {date}." and "No unsaved changes."; Discard and Save are
   off. Scroll: the header stays under the navigation bar, solid also with the background image on.
2. Change Headshot multiplier: the field gets an amber border, its section a "Changed" mark, the header
   "1 unsaved change." and **Save (1)**. Type letters into Attack base: the field shows "Whole number required." and
   Save is off; correct it.
3. Click a navigation link (e.g. Dashboard): "Leave without saving?" in red, focus on **Stay**. Stay keeps the page and
   the value; open it again and **Leave** goes. Back to Siege configuration, change a value again and press the browser's
   Back: the same question.
4. With a change, reload the page (F5) or close the tab: the browser asks. Without changes it doesn't.
5. **Discard**: "Discard 1 unsaved change?"; Cancel keeps it, Discard restores the saved value. **Reload** with a change
   asks the same way; without a change it reloads at once.
6. Change two values and **Save (2)**: a toast "Saved 2 settings." at the bottom right, the header is back to "No
   unsaved changes." with the new "Last saved" time. Reload the page: the values stayed.
7. Game Settings: the same header ("Game Manager Settings"; "Game settings" since #30). Change the MOTD: "1 unsaved change.", Server List MOTD
   gets "Changed". Change a world's weather: "2 unsaved changes.", that world's card gets "Changed". Save: toast "Game
   settings saved.". Clicking a label (Join Announcement, Default GameMode, Clear Weight …) puts the cursor in its field.
8. Game Settings refusal: pick a hub spawn in another world (or anything the API refuses) and Save: the API's reason
   shows in red under the header buttons, the changes stay; fix it and Save again — the message goes.
9. Data retention at the bottom still saves with its own button; it is not counted in the header.
10. At 390 px: the header is compact (title, last saved / changes line, a Reload icon, Discard, Save (n) on one row),
    the fields are full width, nothing scrolls sideways.

## 5. Themes and background

1. In `brand` with the background on: the tables, pager and settings cards are the translucent cards of #231, the
   sticky settings header and the questions are solid; the primary buttons are orange, focus rings visible.
2. With the background off, both themes: the same layout on the plain page colour.

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
