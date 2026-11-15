# Entity detail page: real Select / Unlink / Add, separate Delete, readable values and errors (#188, #189) — smoke test

**Status:** 15 of 20 steps automated in CI (tagged, 2 of them partly; [#511](https://github.com/PandiO/knk-workspace/issues/511), 2026-11-14); every step can still be run by hand; manual steps not run. Written for knk-web-app and knk-web-api `claude/entity-detail-188-189` (chain 3 link V5); **merged 2026-11-12** (knk-web-api `master` `bc97b7d` and knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (test on the default branches, docs #343); 2026-11-12 (merged with V7); 2026-11-09
**Issues:** [PandiO/knk-workspace#188](https://github.com/PandiO/knk-workspace/issues/188) (relationship actions),
[PandiO/knk-workspace#189](https://github.com/PandiO/knk-workspace/issues/189) (readability); access model
[#280](https://github.com/PandiO/knk-workspace/issues/280)

About 30 minutes for a full manual run, about 10 for the untagged steps and the by-hand parts. Steps tagged
`[automated: …]` run in CI (knk-web-app Playwright `e2e/entity-detail.spec.ts`, CI job `e2e`, and the Jest tests in
`src/components/DisplayWizard/__tests__/`, CI job `build-and-test`): skip them or run them by hand. **One new API endpoint pair, no migration, no setting.** Since the 2026-11-12 merge, test it
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

1. [partly automated: `src/components/DisplayWizard/__tests__/DisplayField.readable.test.tsx` (an empty value is a grey "-"); by hand: the look, plain text under small grey labels, not boxes that look disabled] As **A**, open a town's detail page (Dashboard → Town → a row). Values are plain text under small grey labels, not
   grey boxes that look like disabled inputs. An empty value is a grey "-".
2. [automated: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`] **Links:** the first value of a related section (Spawn location) and of each collection item (a street's name) is a
   link to that record's detail page; middle-click opens a new tab, a plain click goes there and **Back** returns to the
   town. A related value inside a field ("(from Town)") links too.
3. [automated: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/CollectionSection.test.tsx`] **Counts and paging:** each collection's title has a count ("Streets 14"). With more than 12 items a pager shows
   under the list ("Showing 1 to 12 of 14 streets", Previous / Next). An empty collection says "No streets yet." and still
   offers Add… and Create New.
4. [automated: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayField.editGate.test.tsx`] **Hot edit:** a field with a pencil (configured "editable in display"): click it, type, press **Enter** → saved, the
   value updates. Click it again, type, press **Escape** → nothing saved. A refusal shows in red under the field.
5. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`] **Readable errors:**
   - Open `/display/Town/999999`: "This Town (#999999) doesn't exist." with **Back**, no "Error: …".
   - Open the detail page of a type without a display configuration: "There is no detail page set up for … yet."
   - As **C** (content only), open a town's URL: "You don't have access to Town "Cinix"." with "Requires one of:
     knk.admin.world, knk.admin.config, knk.admin.road." (the name comes from the lookup).
   - Stop the API and reload: "… couldn't be loaded." with **Try again**.

## 2. Unlink never deletes (#188)

1. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`] As **A**, in the town's **Streets**, click **Unlink** on a street. The question is not red: "Unlink "Main Street"?"
   — ""Main Street" stays as it is; only its link to Town "Cinix" is removed." **Cancel**: nothing happens.
2. [automated: `e2e/entity-detail.spec.ts` (also that no delete request is sent)] Unlink again → **Unlink**: a green toast ""Main Street" unlinked.", the street leaves the list, the count drops.
   Open Dashboard → Street: **the street still exists**.
3. [automated: `DisplayWizard.relationships.test.tsx` ("shows a link the API refuses (a required parent) disabled, with the reason")] **Districts** of the town: Unlink and Add… are disabled; the line under the buttons says "A District always belongs to
   one Town: …". (A district can't exist without its town; delete it or move it on its own Edit page.)

## 3. Add and Select (#188)

1. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`] **Streets → Add…**: a dialog "Add a Street to "Cinix"" with a search box (focus in it). Results show name and one
   detail line; streets already on the town say **Linked**. Type part of a name: the list follows after a short pause.
   More than 10 results: a pager in the dialog.
2. [automated: `e2e/entity-detail.spec.ts`] Click **Add** on a street: toast ""Market Lane" added.", the dialog closes, the street is in the list.
3. [automated: `DisplayWizard.relationships.test.tsx`] **Move:** open a category, Child categories → Add…, pick a category that has another parent: "Move "Axes" here?"
   naming the current parent. **Move here** → it is now under this category (and gone from the old one). Cancel keeps it
   where it was.
4. *(Manual, not automated yet.)* **Cycles:** on a category, Parent category → Change…/Select…, pick one of its own children: refused in a toast ("A
   Category can't be inside itself …"), nothing changes.
5. *(Manual, not automated yet.)* **Icons:** on an item blueprint or category, Icon → Change… works; **Unlink** is disabled: "An icon is required:
   select another one."
6. *(Manual, not automated yet.)* **Tags:** on an item blueprint, Tags → Add… a tag, then Unlink it: the tag itself still exists (Dashboard → Tag).

## 4. Delete is separate and gated (#188, #280)

1. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`] As **A**, on a collection with "Delete item" switched on (Streets in this test), each item has a red **Delete** next to
   Unlink. Click it: a red question "Delete Street "Harbour Road"?" — "… itself is deleted, everywhere, not only unlinked
   from "Cinix". This can't be undone." Cancel. (Delete and confirm only on a throwaway record.)
2. *(Manual, not automated yet.)* A category with children: Delete → refused; the dialog offers **View children** and **Reassign parent** as before.
3. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`] As **S** (no `knk.admin.delete`): the header's **Delete** and every item's **Delete** are disabled; the header says
   "Delete: Requires knk.admin.delete", the collection "Delete: Requires knk.admin.delete". **Unlink** and **Add…** still
   work (they are edits: `knk.admin.world`).
4. [automated: `e2e/entity-detail.spec.ts`, `DisplayWizard.relationships.test.tsx`; the API's 403 on a direct call: knk-web-api `Tests/knkwebapi_v2.Tests/Security/DashboardChangeAccessRulesTests.cs`] Optional, with an account that holds `knk.admin.world` but not `knk.admin.content` (the world-only rank, #374): on a
   district (#409: a town's streets come from its districts), the Streets section's Add… and Unlink are disabled with
   "Requires knk.admin.content", Delete (with `knk.admin.delete`) still works; calling
   `POST api/Relationships/District/<id>/streets/link` directly answers 403 `NoWriteAccess`.

## 5. Themes and phone width

1. *(Manual: visual check of the themes.)* Repeat 1.1, 3.1 and 4.1 in the `current` and `brand` themes, with the page background on and off.
2. [partly automated: `e2e/entity-detail.spec.ts` (no sideways scrolling at 390 px); by hand: the buttons wrap, the picker fits, the pager's Next is reachable] At 390 px: no sideways scrolling, the buttons wrap, the picker fits the screen, the pager's Next is reachable.

**Known:** the collection pager at 390 px is tight ("Page 1 of 2" wraps), as noted on #187 for the dashboard pager.
