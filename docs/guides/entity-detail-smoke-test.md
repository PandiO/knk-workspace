# Entity detail page: real Select / Unlink / Add, separate Delete, readable values and errors (#188, #189) — smoke test

**Status:** Written 2026-11-09 for knk-web-app and knk-web-api `claude/entity-detail-188-189` (chain 3 link V5); **merged 2026-11-12** (knk-web-api `master` `bc97b7d` and knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (test on the default branches, docs #343); 2026-11-12 (merged with V7); 2026-11-09
**Issues:** [PandiO/knk-workspace#188](https://github.com/PandiO/knk-workspace/issues/188) (relationship actions),
[PandiO/knk-workspace#189](https://github.com/PandiO/knk-workspace/issues/189) (readability); access model
[#280](https://github.com/PandiO/knk-workspace/issues/280)

About 10 minutes for the manual steps left. Steps marked `[automated]` run in CI (knk-web-app Playwright
`e2e/entity-detail.spec.ts`, CI job `e2e`, and the Jest tests in `src/components/DisplayWizard/__tests__/`, CI job
`build-and-test`); you don't repeat them. **One new API endpoint pair, no migration, no setting.** Since the 2026-11-12 merge, test it
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

1. *(Manual, a look: plain text under small grey labels, not boxes that look disabled.)* As **A**, open a town's detail
   page. An empty value is a grey "-" (automated in `src/components/DisplayWizard/__tests__/DisplayField.readable.test.tsx`).
2. [automated] Each collection item links to its own detail page, Back returns; a related value links too: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
3. [automated] Counts and paging: "Showing 1 to 12 of 14 streets", Previous / Next; an empty collection says "No
   streets yet." and still offers Add…: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/CollectionSection.test.tsx`
4. [automated] Hot edit: Enter saves, Escape saves nothing; a refusal shows under the field: `e2e/entity-detail.spec.ts`,
   `src/components/DisplayWizard/__tests__/DisplayField.editGate.test.tsx`
5. [automated] Readable errors: "This Town (#999999) doesn't exist." with Back; no detail page set up; "You don't have
   access to Town "Cinix"." with "Requires one of: …"; "… couldn't be loaded." with Try again: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`

## 2. Unlink never deletes (#188)

1. [automated] Unlink asks a plain (not red) question "Unlink "Main Street"?" naming the town; Cancel does nothing:
   `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
2. [automated] Unlink → toast ""Main Street" unlinked.", the street leaves the list, and no delete request is sent:
   `e2e/entity-detail.spec.ts`
3. [automated] **Districts** of the town: Unlink and Add… disabled with "A District always belongs to one Town: …":
   `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` ("shows a link the API refuses (a required parent) disabled, with the reason")

## 3. Add and Select (#188)

1. [automated] **Streets → Add…**: "Add a Street to "Cinix"" with the focus in the search, already linked streets say
   **Linked**, the list follows the typing: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
2. [automated] **Add** on a street: toast ""Market Lane" added.", the street is in the list: `e2e/entity-detail.spec.ts`
3. [automated] **Move:** a category that has another parent asks "Move "Axes" here?"; Move here links it with move: `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
4. *(Manual, not automated yet.)* **Cycles:** on a category, Parent category → Change…/Select…, pick one of its own
   children: refused in a toast ("A Category can't be inside itself …"), nothing changes.
5. *(Manual, not automated yet.)* **Icons:** on an item blueprint or category, Icon → Change… works; **Unlink** is
   disabled: "An icon is required: select another one."
6. *(Manual, not automated yet.)* **Tags:** on an item blueprint, Tags → Add… a tag, then Unlink it: the tag itself
   still exists (Dashboard → Tag).

## 4. Delete is separate and gated (#188, #280)

1. [automated] An item's red **Delete** asks "Delete Street "Harbour Road"?" … "This can't be undone."; Cancel deletes
   nothing: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
2. *(Manual, not automated yet.)* A category with children: Delete → refused; the dialog offers **View children** and
   **Reassign parent** as before.
3. [automated] Without `knk.admin.delete`: the items' **Delete** disabled with "Delete: Requires knk.admin.delete";
   **Unlink** and **Add…** still work: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`
4. [automated] With `knk.admin.world` but not `knk.admin.content` (#374): Add… and Unlink disabled with the
   requirement, Delete still works: `e2e/entity-detail.spec.ts`, `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx`. The API's 403 `NoWriteAccess` on a direct call:
   knk-web-api `Tests/knkwebapi_v2.Tests/Security/DashboardChangeAccessRulesTests.cs`

## 5. Themes and phone width

1. *(Manual: visual check of the themes.)* Repeat 1.1, 3.1 and 4.1 in the `current` and `brand` themes, with the page
   background on and off.
2. [automated] At 390 px no sideways scrolling: `e2e/entity-detail.spec.ts`. Glance during 5.1 that the buttons wrap and the picker fits.

**Known:** the collection pager at 390 px is tight ("Page 1 of 2" wraps), as noted on #187 for the dashboard pager.
