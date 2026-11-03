# Entity lists: table state and tabs in the URL, rows as links, "Drafts (n)" and "New with" (#39, #177 follow-up) — smoke test

**Status:** Written 2026-11-01 for knk-web-app `claude/entity-lists-url-state`; run by the developer 2026-11-03: every step
works or is accepted, after one fix (4.2, knk-web-app `d72194b`; Findings below). Not merged
**Last updated:** 2026-11-03
**Issues:** [PandiO/knk-workspace#39](https://github.com/PandiO/knk-workspace/issues/39) (page/search/sort and tabs in the
URL, rows as links, `aria-sort`) · [#177](https://github.com/PandiO/knk-workspace/issues/177) follow-up ("Drafts (n)", "New
with: {config}")
**Branches:** knk-web-app `claude/entity-lists-url-state` (on `main` `b3b415d`); knk-workspace `claude/entity-lists-url-state`
(these docs). No API or plugin change, no migration, no setting.
**Chain:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) link 9; report
[2026-10-26-ux-realtime-chain.md](../reports/2026-10-26-ux-realtime-chain.md) (link 9 block).

Web app only: check out `claude/entity-lists-url-state` in knk-web-app, `npx npm@11 ci` if needed, `npm start`, against the
dev API on trunk. Log in as an admin with `knk.admin.content` (sections 1–5) and `knk.admin.lootbox.manage` (section 6).
Pick a type with more than 10 rows and a published default display configuration (e.g. Street or Category); it is
called **X** below. Record each step in **Findings** at the end.

## 1. Page, search and sort in the URL

1. Open `/dashboard/X`. Expected: the URL has no `?…`; page 1.
2. Go to page 2. Expected: URL `/dashboard/X?page=2`, the table on page 2.
3. Click the **Name** header twice. Expected: `&sort=name` (ascending), then `&sort=name&dir=desc`; a third click removes
   both (unsorted). Page stays as the table puts it.
4. Type a search term (e.g. `no`). Expected: about half a second after the last key the URL gets `q=no` and `page`
   goes away (page 1).
5. Refresh. Expected: same search, sort and page; the search box shows the term.
6. Copy the URL into a new tab. Expected: the same view.
7. Browser **Back**. Expected: the page before the dashboard (the table changes replaced the entry instead of adding
   one per page or letter).
8. Pick another type in the explorer. Expected: its bare `/dashboard/{type}` (page 1, no search); Back returns to X with
   its search and sort.
9. Edit `page=99` into the URL. Expected: the table moves to its last page (URL `page=<last>`).

## 2. Coming back from a form or the detail page keeps the view

1. On `/dashboard/X?page=2&sort=name&dir=desc`, click ✏️ **Edit** on a row, change nothing, **Cancel**. Expected: back on
   page 2, same sort.
2. Same with Edit → Submit. Expected: back on page 2, same sort, success toast, the row updated.
3. **New X** → Cancel. Expected: back on page 2.
4. 👁 **View** → detail page **Back**, and the breadcrumb's "X" crumb. Expected: back on page 2 with the sort.
5. With a search term: Edit → Submit. Expected: back with the search term in the box and the URL.

## 3. Rows as links

1. Hover the first cell of a row. Expected: it's a link (underline on hover, the address in the status bar:
   `/display/X/{id}?returnTo=…`).
2. Click it. Expected: the detail page in the same tab (no full page reload).
3. Middle-click it, and Ctrl/Cmd-click it. Expected: the detail page in a new tab; the dashboard tab stays.
4. Ctrl/Cmd-click or middle-click elsewhere on the row (not on the buttons). Expected: new tab with the detail page.
5. Plain click elsewhere on the row. Expected: the detail page, as before.
6. Keyboard: Tab into the table. Expected: the sortable headers and the row links get a focus ring; Enter on a header
   sorts, Enter on a row link opens the detail page.
7. A type with the "no display configuration" marker: no links in its rows, row click still does nothing (as before).
8. In a form, open a picker table (e.g. Street's District field). Expected: rows select as before (no links), paging
   and search work, and **the URL does not change** while paging or searching in the picker; no "Leave this form?"
   question.
9. Screen reader (optional): a sorted column header is announced as sorted ascending/descending.

## 4. "New with: {config}"

Needs a type with a second, non-default form configuration (add one on the Entity setup page with ⚙ if needed).

1. `/dashboard/X`: a small ▾ button is attached to **New X**. A type with only its default configuration has none.
2. Click ▾. Expected: "New with" lists the other configurations A–Z (with their description); Escape closes it and the
   focus goes back to ▾; ArrowDown/ArrowUp move through the list; a click outside closes it.
3. Pick one. Expected: the form opens with **that** configuration (its steps), breadcrumb "Dashboard › X › New X";
   Cancel and Submit come back to the dashboard view it was opened from.
4. A type without a default configuration but with others: New goes to the Entity setup page with the notice (as
   before); ▾ lists all of them.
5. Edit the URL to `/forms/X?configId=999999`. Expected: the Entity setup page with the error toast "That form
   configuration was not found…", no form.

## 5. "Drafts (n)"

1. Open New X, fill the first step, **Save Draft**, leave the form (Cancel → Leave form). Expected: on the dashboard a
   **Drafts (1)** chip next to New.
2. Click it. Expected: "Resume a draft" lists the draft: configuration name, "Step n · Paused", the last update;
   newest first when there are several. "All saved progress (Entity setup)" opens `/forms/X`.
3. Pick the draft. Expected: the form opens on the saved step with the saved values; Cancel/Submit come back to the
   dashboard.
4. Submit it. Expected: back on the dashboard, the chip is gone (or counts one less): completed drafts are not counted.
5. Log in as another admin. Expected: the first admin's drafts are not counted (Saved Progress is per admin, #186).
6. Compare with the Entity setup page's Saved Progress for X: the chip counts the same drafts minus Completed and
   Abandoned ones.

## 6. Tabs in the URL

1. `/admin/lootboxes`: pick **Odds**. Expected: URL `?tab=odds`; refresh keeps Odds. Pick **Types** (the default):
   `?tab` is removed.
2. Open `/admin/lootboxes?tab=log` directly. Expected: the Drop log tab. `?tab=nonsense`: the Types tab.
3. `/admin/users` (Moderation): pick **Recently demoted**. Expected: `?tab=demoted`. Click a player's name. Expected:
   the profile; **Back** returns to Recently demoted.
4. Middle-click / Ctrl-click a player's name on any moderation tab. Expected: the profile in a new tab. A plain click on
   the rest of the row still opens the profile.
5. Switching tabs doesn't add history entries: Back from `/admin/users?tab=demoted` after switching tabs a few times
   leaves the page.

## Findings

| Step | Result | Notes |
|---|---|---|
| 1 | Works | All 9 steps. |
| 2 | Works | All 5 steps. |
| 3 | Works | All 9 steps. |
| 4 | Works / accepted, one fix | 4.1 works. 4.2 works, but long configuration names were cut off and hovering didn't show the full name (most configurations differ only at the end of their name) → fixed in knk-web-app `d72194b`: the "New with" and "Resume a draft" menus let names and descriptions wrap in a wider menu (18–28rem, never wider than the screen), and every item shows its full name and description on hover. 4.3 and 4.4 accepted. 4.5 works. |
| 5 | Works / accepted | 5.1–5.4 work. 5.5 and 5.6 accepted. |
| 6 | Works | All 5 steps. |
