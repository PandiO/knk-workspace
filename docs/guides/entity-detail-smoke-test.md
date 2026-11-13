# Entity detail page: real Select / Unlink / Add, separate Delete, readable values and errors (#188, #189) — smoke test

**Status:** Written 2026-11-09 for knk-web-app and knk-web-api `claude/entity-detail-188-189` (chain 3 link V5); **merged 2026-11-12** (knk-web-api `master` `bc97b7d` and knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-12 (test on the default branches, docs #343); 2026-11-12 (merged with V7); 2026-11-09
**Issues:** [PandiO/knk-workspace#188](https://github.com/PandiO/knk-workspace/issues/188) (relationship actions),
[PandiO/knk-workspace#189](https://github.com/PandiO/knk-workspace/issues/189) (readability); access model
[#280](https://github.com/PandiO/knk-workspace/issues/280)

About 30 minutes. **One new API endpoint pair, no migration, no setting.** Since the 2026-11-12 merge, test it
on knk-web-api `master` (from `bc97b7d`, with #280 AM1 + AM2) and knk-web-app `main` (from `1371951`). The feature
branches were `claude/entity-detail-188-189` in both repos.

You need:
- **A** — the owner or an Admin account.
- **S** — a staff account with `knk.admin.content` and `knk.admin.world` but **without** `knk.admin.delete` (the Staff
  group after AM1's migration, which skips Staff for delete).
- **C** — optional: a staff account with `knk.admin.content` only (no world node).
- A test database with a town that has a few streets and districts, a category tree, and an item blueprint with tags.
  The detail page's route still needs `knk.admin.content` (W4's route table; AM3 opens it to any area node).

Which links can change here (the API's reviewed list, `RelationshipCatalog.Supported`): a category's parent, child
categories, tags and icon; an item blueprint's category, grade, tags and icon; a town's and a district's streets, and a
street's districts and town. Everything else shows its buttons disabled with the reason (usually "Change this on the Edit
page."). A section only shows the buttons its display configuration switches on (Entity setup → Display → section →
Action Buttons; "Unlink item (Remove)" and the new "Delete item").

## 1. Reading the page (#189)

1. As **A**, open a town's detail page (Dashboard → Town → a row). Values are plain text under small grey labels, not
   grey boxes that look like disabled inputs. An empty value is a grey "-".
2. **Links:** the first value of a related section (Spawn location) and of each collection item (a street's name) is a
   link to that record's detail page; middle-click opens a new tab, a plain click goes there and **Back** returns to the
   town. A related value inside a field ("(from Town)") links too.
3. **Counts and paging:** each collection's title has a count ("Streets 14"). With more than 12 items a pager shows
   under the list ("Showing 1 to 12 of 14 streets", Previous / Next). An empty collection says "No streets yet." and still
   offers Add… and Create New.
4. **Hot edit:** a field with a pencil (configured "editable in display"): click it, type, press **Enter** → saved, the
   value updates. Click it again, type, press **Escape** → nothing saved. A refusal shows in red under the field.
5. **Readable errors:**
   - Open `/display/Town/999999`: "This Town (#999999) doesn't exist." with **Back**, no "Error: …".
   - Open the detail page of a type without a display configuration: "There is no detail page set up for … yet."
   - As **C** (content only), open a town's URL: "You don't have access to Town "Cinix"." with "Requires one of:
     knk.admin.world, knk.admin.config, knk.admin.road." (the name comes from the lookup).
   - Stop the API and reload: "… couldn't be loaded." with **Try again**.

## 2. Unlink never deletes (#188)

1. As **A**, in the town's **Streets**, click **Unlink** on a street. The question is not red: "Unlink "Main Street"?"
   — ""Main Street" stays as it is; only its link to Town "Cinix" is removed." **Cancel**: nothing happens.
2. Unlink again → **Unlink**: a green toast ""Main Street" unlinked.", the street leaves the list, the count drops.
   Open Dashboard → Street: **the street still exists**.
3. **Districts** of the town: Unlink and Add… are disabled; the line under the buttons says "A District always belongs to
   one Town: …". (A district can't exist without its town; delete it or move it on its own Edit page.)

## 3. Add and Select (#188)

1. **Streets → Add…**: a dialog "Add a Street to "Cinix"" with a search box (focus in it). Results show name and one
   detail line; streets already on the town say **Linked**. Type part of a name: the list follows after a short pause.
   More than 10 results: a pager in the dialog.
2. Click **Add** on a street: toast ""Market Lane" added.", the dialog closes, the street is in the list.
3. **Move:** open a category, Child categories → Add…, pick a category that has another parent: "Move "Axes" here?"
   naming the current parent. **Move here** → it is now under this category (and gone from the old one). Cancel keeps it
   where it was.
4. **Cycles:** on a category, Parent category → Change…/Select…, pick one of its own children: refused in a toast ("A
   Category can't be inside itself …"), nothing changes.
5. **Icons:** on an item blueprint or category, Icon → Change… works; **Unlink** is disabled: "An icon is required:
   select another one."
6. **Tags:** on an item blueprint, Tags → Add… a tag, then Unlink it: the tag itself still exists (Dashboard → Tag).

## 4. Delete is separate and gated (#188, #280)

1. As **A**, on a collection with "Delete item" switched on (Streets in this test), each item has a red **Delete** next to
   Unlink. Click it: a red question "Delete Street "Harbour Road"?" — "… itself is deleted, everywhere, not only unlinked
   from "Cinix". This can't be undone." Cancel. (Delete and confirm only on a throwaway record.)
2. A category with children: Delete → refused; the dialog offers **View children** and **Reassign parent** as before.
3. As **S** (no `knk.admin.delete`): the header's **Delete** and every item's **Delete** are disabled; the header says
   "Delete: Requires knk.admin.delete", the collection "Delete: Requires knk.admin.delete". **Unlink** and **Add…** still
   work (they are edits: `knk.admin.world`).
4. Optional, with an account that holds `knk.admin.content` but not `knk.admin.world`: on a town, Add… and Unlink are
   disabled with "Requires knk.admin.world"; calling `POST api/Relationships/Town/<id>/streets/link` directly answers 403
   `NoWriteAccess`.

## 5. Themes and phone width

1. Repeat 1.1, 3.1 and 4.1 in the `current` and `brand` themes, with the page background on and off.
2. At 390 px: no sideways scrolling, the buttons wrap, the picker fits the screen, the pager's Next is reachable.

**Known:** the collection pager at 390 px is tight ("Page 1 of 2" wraps), as noted on #187 for the dashboard pager.
