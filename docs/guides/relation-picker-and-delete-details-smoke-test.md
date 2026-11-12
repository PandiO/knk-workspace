# Form wizard relation picker and "Show what uses it" on refused deletes (#191, #44) — smoke test

**Status:** Written 2026-11-09 for knk-web-app and knk-web-api `claude/picker-details-191-44` (chain 3 link V6); **merged 2026-11-12** (knk-web-api `master` `bc97b7d` and knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-12 (test on the default branches, docs #344); 2026-11-12 (merged with V7); 2026-11-09
**Issues:** [PandiO/knk-workspace#191](https://github.com/PandiO/knk-workspace/issues/191) (search-as-you-type relation
picker), [PandiO/knk-workspace#44](https://github.com/PandiO/knk-workspace/issues/44) (FeedbackModal "Show details");
access model [#280](https://github.com/PandiO/knk-workspace/issues/280)

About 25 minutes. **One new API endpoint (`GET api/EntityReferences/{type}/{id}/rows`), no migration, no setting.** Since the
2026-11-12 merge, test it on knk-web-api `master` (from `bc97b7d`) and knk-web-app `main` (from `1371951`). The feature
branches were `claude/picker-details-191-44` in both repos.

You need:
- **A** — the owner or an Admin account.
- **C** — a staff account with `knk.admin.content` (and `knk.admin.delete` for § 4) but **without** `knk.admin.world`,
  `knk.admin.config` and `knk.road.manage`: it reads streets and districts only through lookups.
- A test database with a few streets and districts, and one street that a structure uses (for § 4).
- Optional: a phone or the browser's 390 px view; the themes `current` and `brand` (`?theme=brand`), the page background on
  and off (`?bg=off`).

## 1. Picker: search as you type (#191), as A

1. Dashboard → Structure → **New Structure**. The Street field shows **Create New** and a search box "Search Street…";
   there is no "Select instance" button and no table under the field. Nothing is fetched yet (network tab: no
   `Streets/search` until you use the box).
2. Click into the box: a list of the first 8 streets opens under it, with a second line (the table's default columns) and
   at the bottom "8 of n shown. Keep typing …" and **Open full table**.
3. Type part of a street name: the list follows after a short pause. ↓ ↓ Enter picks the second match; the list closes,
   the green card shows the street and its ID, and the box now says "Search to replace …".
4. In the box, press Escape with the list open: only the list closes. Press Escape again in a child form (Create New): now
   the child form asks to close, as before.
5. Districts (a list field): click a district, then another: both appear under "Selected (2)" and stay ticked in the list;
   click a ticked one to remove it. With a maximum set on the field (Entity setup → field → Max selection), the other
   rows grey out once it is reached.
6. **Open full table**: the old table opens in a dialog (search, sort, pages, Category filter on item blueprints, the
   rows created in this form on top). For a single field a click picks and closes it; for a list, tick rows and press
   Done.
7. **Created in this form** (KNG-136): in a Gate structure form, Create New → Street, and inside it Create New →
   District; save both. Back in the gate form, click the Districts box: "Created in this form" lists the new district
   with a New badge on top; typing filters it like the other rows.
8. A field with picker filters (siege scenario → team → spawnpoint; a scenario's owner team) still lists only the
   matching rows (e.g. teams of this scenario).

## 2. Picker without a read node (lookup mode, #280), as C

1. Open a form with a Street or District field: `/forms/Structure?autoOpen=true` (the route needs `knk.admin.content`).
2. Click into the Street box: the list shows street names with one detail line (the town), no **Open full table**, and
   the line "Names only: the full Street table needs one of: knk.admin.world, knk.road.manage."
3. Pick one: the card shows the name and ID. (Saving a Structure needs `knk.admin.world`, so Submit is refused by the
   API for C; that is the write rule, not the picker. A form of C's own area with a field to another area saves the id.)
4. A field whose picker filters narrow the list (e.g. a siege team scoped to a scenario) says "This list is narrowed by
   … which only the full … search can do. Requires one of: …" instead of offering every row. (A `prefer…` filter only
   ordered the list and is ignored.)

## 3. Nothing else changed

1. A form without relation fields, a Minecraft material/enchantment picker and the banner layers field look and work
   as before.
2. Edit an existing Structure: the Street card shows the saved street; replacing it works as in § 1.

## 4. "Show what uses it" on a refused delete (#44), as A

1. Dashboard → Street → the trash icon on a street a structure uses → Delete. The red dialog says "This street can't be
   deleted: it is still used by 1 structure. …" and has **Show what uses it**. Nothing is fetched until you press it.
2. Press it: a spinner, then "1 structure" with the structure's name as a link (and a short detail line). The Close
   button stays visible while the list scrolls. **Hide details** / **Show what uses it** again shows it without loading
   again.
3. Click the structure's link: the dialog closes and its detail page opens; Back returns to the dashboard.
4. Detail page of the same street → header **Delete** → the same dialog (no longer a short toast) with the same list.
5. Town detail page → Streets section → an item's red **Delete** on that street → the same dialog.
6. A street with more than 20 structures (if you have one): "… and n more." under the list.
7. A delete that fails for another reason (e.g. stop the API: "An error occurred while deleting.") has no Show button.

## 5. "Show what uses it" as C (rows of other areas)

1. As C, delete a content record that a record of another area uses (e.g. a category or item blueprint a kit uses, if
   C has `knk.admin.delete`): the list names the kit without a link and says "Opening kits requires one of: …".
2. Drafts (saved form progress) that use the record are only counted ("2 saved drafts — These records aren't listed
   here."), for everyone.

## 6. Themes and phone width

1. Repeat § 1.2, § 1.6 and § 4.2 with `?theme=brand` and with `?bg=off`, and at 390 px: the list fits the screen
   (no sideways scrolling), long names wrap, the dialog's Close stays visible.
