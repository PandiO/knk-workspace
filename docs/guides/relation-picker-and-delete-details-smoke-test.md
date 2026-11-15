# Form wizard relation picker and "Show what uses it" on refused deletes (#191, #44, #289) — smoke test

**Status:** 27 of 32 steps automated in CI (tagged `[automated: …]`, one of them `[partly automated: …]`; § 4.8–4.12 and § 5.3 "Show what uses it" on Entity setup, bulk delete rows and skipped created entities in `e2e/entity-setup-delete-details.spec.ts`, `e2e/dashboard-access.spec.ts` and Jest, #289, 2026-11-15; [#511](https://github.com/PandiO/knk-workspace/issues/511), 2026-11-14: the picker in its Jest tests, "Show what uses it" in `e2e/dashboard-access.spec.ts` and Jest; § 6.2–6.3 list field cards in `e2e/form-wizard-list-field.spec.ts`, #290, 2026-11-15); every step can still be run by hand; manual steps not run. Untagged, by hand only: the unchanged-pages check § 3, the collection item's Delete § 4.5, themes § 6.1. Written 2026-11-09 for knk-web-app and knk-web-api `claude/picker-details-191-44` (chain 3 link V6); **merged 2026-11-12** (knk-web-api `master` `bc97b7d` and knk-web-app `main` `1371951`, with V7); written before the backfill
**Last updated:** 2026-11-15 (§ 4.8–4.12, § 5.3: "Show what uses it" for a refused form configuration delete, bulk delete rows and "skipped: in use", #289, knk-web-app and knk-web-api `claude/show-what-uses-it-289`, PRs into `next`, automated); 2026-11-15 (§ 6.2–6.3 list field cards at 390 px, #290, automated); 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-15 (§ 4.5 on a district's Streets: a town's Streets have no Delete since #409, docs #559); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (test on the default branches, docs #344); 2026-11-12 (merged with V7); 2026-11-09
**Issues:** [PandiO/knk-workspace#191](https://github.com/PandiO/knk-workspace/issues/191) (search-as-you-type relation
picker), [PandiO/knk-workspace#44](https://github.com/PandiO/knk-workspace/issues/44) (FeedbackModal "Show details");
access model [#280](https://github.com/PandiO/knk-workspace/issues/280); more refusals [#289](https://github.com/PandiO/knk-workspace/issues/289)

About 35 minutes for a full manual run, about 5 for the untagged steps. **One new API endpoint (`GET api/EntityReferences/{type}/{id}/rows`), no migration, no setting.** Since the
2026-11-12 merge, test it on knk-web-api `master` (from `bc97b7d`) and knk-web-app `main` (from `1371951`). The feature
branches were `claude/picker-details-191-44` in both repos.

You need:
- **A** — the owner or an Admin account.
- **C** — a staff account with `knk.admin.content` (and `knk.admin.delete` for § 4) but **without** `knk.admin.world`,
  `knk.admin.config` and `knk.road.manage`: it reads streets and districts only through lookups.
- A test database with a few streets and districts, and one street that a structure uses (for § 4).
- For § 4.8: a form configuration that another form opens as a sub-form (Entity setup → a form → a field or step with
  **Sub-configuration** set to it). For § 4.11–4.12: a district that a structure uses.
- Optional: a phone or the browser's 390 px view; the themes `current` and `brand` (`?theme=brand`), the page background on
  and off (`?bg=off`).

## 1. Picker: search as you type (#191), as A

1. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "fetches nothing until the box is used"] Dashboard → Structure → **New Structure**. The Street field shows **Create New** and a search box "Search Street…";
   there is no "Select instance" button and no table under the field. Nothing is fetched yet (network tab: no
   `Streets/search` until you use the box).
2. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`] Click into the box: a list of the first 8 streets opens under it, with a second line (the table's default columns) and
   at the bottom "8 of n shown. Keep typing …" and **Open full table**.
3. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "searches after a pause", "picks with the arrow keys and Enter"] Type part of a street name: the list follows after a short pause. ↓ ↓ Enter picks the second match; the list closes,
   the green card shows the street and its ID, and the box now says "Search to replace …".
4. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "closes the list on Escape without closing the dialog"] In the box, press Escape with the list open: only the list closes. Press Escape again in a child form (Create New): now
   the child form asks to close, as before.
5. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "adds and removes in a list, and stops at the maximum"] Districts (a list field): click a district, then another: both appear under "Selected (2)" and stay ticked in the list;
   click a ticked one to remove it. With a maximum set on the field (Entity setup → field → Max selection), the other
   rows grey out once it is reached.
6. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "opens the full table with the filters and pinned rows"] **Open full table**: the old table opens in a dialog (search, sort, pages, Category filter on item blueprints, the
   rows created in this form on top). For a single field a click picks and closes it; for a list, tick rows and press
   Done.
7. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "lists the rows this form created first, marked New"] **Created in this form** (KNG-136): in a Gate structure form, Create New → Street, and inside it Create New →
   District; save both. Back in the gate form, click the Districts box: "Created in this form" lists the new district
   with a New badge on top; typing filters it like the other rows.
8. [automated: `src/utils/forms/__tests__/pickerFilters.test.ts`, `src/components/FormWizard/__tests__/RelationPicker.test.tsx`] A field with picker filters (siege scenario → team → spawnpoint; a scenario's owner team) still lists only the
   matching rows (e.g. teams of this scenario).

## 2. Picker without a read node (lookup mode, #280), as C

1. Open a form with a Street or District field: `/forms/Structure?autoOpen=true` (the route needs `knk.admin.content`).
2. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "searches api/Lookup without a read node"] Click into the Street box: the list shows street names with one detail line (the town), no **Open full table**, and
   the line "Names only: the full Street table needs one of: knk.admin.world, knk.road.manage."
3. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "picks a bare reference"] Pick one: the card shows the name and ID. (Saving a Structure needs `knk.admin.world`, so Submit is refused by the
   API for C; that is the write rule, not the picker. A form of C's own area with a field to another area saves the id.)
4. [automated: `src/components/FormWizard/__tests__/RelationPicker.test.tsx`, "refuses filters that would narrow the list"; `src/utils/forms/__tests__/relationPicker.test.ts`] A field whose picker filters narrow the list (e.g. a siege team scoped to a scenario) says "This list is narrowed by
   … which only the full … search can do. Requires one of: …" instead of offering every row. (A `prefer…` filter only
   ordered the list and is ignored.)

## 3. Nothing else changed

1. A form without relation fields, a Minecraft material/enchantment picker and the banner layers field look and work
   as before.
2. Edit an existing Structure: the Street card shows the saved street; replacing it works as in § 1.

## 4. "Show what uses it" on a refused delete (#44), as A

1. [automated: `e2e/dashboard-access.spec.ts`, `src/components/ObjectDashboard/__tests__/ObjectDashboard.test.tsx`] Dashboard → Street → the trash icon on a street a structure uses → Delete. The red dialog says "This street can't be
   deleted: it is still used by 1 structure. …" and has **Show what uses it**. Nothing is fetched until you press it.
2. [automated: `e2e/dashboard-access.spec.ts`, `src/components/__tests__/FeedbackModal.details.test.tsx`] Press it: a spinner, then "1 structure" with the structure's name as a link (and a short detail line). The Close
   button stays visible while the list scrolls. **Hide details** / **Show what uses it** again shows it without loading
   again.
3. [automated: `e2e/dashboard-access.spec.ts`] Click the structure's link: the dialog closes and its detail page opens; Back returns to the dashboard.
4. [automated: `src/pages/__tests__/DisplayWizardPage.header.test.tsx`, "a delete refused because the town is in use"] Detail page of the same street → header **Delete** → the same dialog (no longer a short toast) with the same list.
5. Detail page of a district that has that street → Streets section → an item's red **Delete** on that street → the
   same dialog. (A town's Streets section has no Delete since [#409](https://github.com/PandiO/knk-workspace/issues/409):
   its streets come from the districts.)
6. [automated: `src/components/__tests__/ReferenceDetails.test.tsx`, "says how many more there are"] A street with more than 20 structures (if you have one): "… and n more." under the list.
7. [automated: `e2e/dashboard-access.spec.ts`, `ReferenceDetails.test.tsx` ("recognises only the still in use refusal")] A delete that fails for another reason (e.g. stop the API: "An error occurred while deleting.") has no Show button.
8. [automated: `e2e/entity-setup-delete-details.spec.ts`, "a form configuration used as a sub-form: the refusal offers \"Show what uses it\" with the fields and steps, named by their form"; `src/pages/__tests__/FormWizardPage.deleteConfig.test.tsx`] ([#289](https://github.com/PandiO/knk-workspace/issues/289)) Entity setup (`/forms/<type>`) of the form
   configuration that another form opens as a sub-form → its **⋯** menu → **Delete** → **Delete**. The red "Delete
   failed" dialog says "This form configuration can't be deleted: it is still used by 1 form field that opens it as a
   sub-form …" and has **Show what uses it**; nothing is fetched until you press it. Press it: "1 form field that opens
   it as a sub-form" with the field's label and a line naming its form and step (e.g. "Field of the form "Kingdom form"
   (Kingdom), step "Towns""); a step is named likewise ("Step of the form …", or "Reusable step template"). The names
   are not links. The configuration is still in the list.
9. [automated: `e2e/entity-setup-delete-details.spec.ts`, "a form configuration delete that fails for another reason has no \"Show what uses it\""; `FormWizardPage.deleteConfig.test.tsx`] A form configuration delete that fails for
   another reason (e.g. stop the API) shows "Delete failed" without **Show what uses it**.
10. [automated: `e2e/dashboard-access.spec.ts`, "bulk Delete: \"Show what uses it\" on an in-use row loads its list on request; a row refused by a rule has none (#289)"; `ObjectDashboard.test.tsx`] Dashboard → Street → tick the street a structure uses and
    one more → **Delete (2)** → **Delete 2 Streets**. In the result dialog the in-use street has **Show what uses it**
    beside its name (a row refused for another reason has none). Press it: "1 structure" with its name as a link, under
    the row's reason; **Hide** hides it and **Show what uses it** shows it again without loading again. Click the link:
    the dialog closes and the structure's page opens.
11. [automated: `e2e/entity-setup-delete-details.spec.ts`, "deleting a draft and its entities: a skipped entity offers \"Show what uses it\" with every reference, and a row opens"] Start a Gate structure form, Create New → Street, inside it Create
    New → District, save both, then **Save draft** and leave. Build a structure in that district (or link one to it).
    Entity setup → Saved Progress → the draft's trash icon → **Delete draft and them**. The report says "Deleted 1 of
    2." and "District '…': skipped: in use (used by Structure.DistrictId)" with **Show what uses it**; the deleted
    street has none. Press it: the structure, as a link (every reference, also links that would be removed with the
    district, as the in-use check counted them). Click it: the report closes and the structure's page opens.
12. [automated: `e2e/entity-setup-delete-details.spec.ts`, "cancelling a form and deleting what it created: a skipped entity offers \"Show what uses it\" with every reference"; `src/components/FormWizard/__tests__/CreatedEntitiesPrompt.usesIt.test.tsx`] The same with **Cancel form** instead of a draft: in the
    open form (new or resumed) with a created district that a structure uses → **Cancel form** → **Delete them**: the
    skipped district offers **Show what uses it** with the same list; **Done** leaves the form as before.

## 5. "Show what uses it" as C (rows of other areas)

1. [automated: `ReferenceDetails.test.tsx`, "names rows of a type the viewer can not open without a link, with the nodes"] As C, delete a content record that a record of another area uses (e.g. a category or item blueprint a kit uses, if
   C has `knk.admin.delete`): the list names the kit without a link and says "Opening kits requires one of: …".
2. [automated: `ReferenceDetails.test.tsx`, "counts the rest"] Drafts (saved form progress) that use the record are only counted ("2 saved drafts — These records aren't listed
   here."), for everyone.
3. [partly automated: knk-web-api `Tests/knkwebapi_v2.Tests/Api/EntityReferencesControllerTests.cs` (rows of other
   areas, "FormFieldsAndSteps_WithoutKnkAdminContent_AreOnlyCounted"), `ReferenceDetails.test.tsx` ("shows the API's
   reason when the list can't be loaded"); by hand: a real account] ([#289](https://github.com/PandiO/knk-workspace/issues/289))
   The lists of § 4.8 and § 4.10–4.12 follow the same rules as § 5.1–5.2. By hand: as an account with
   `knk.admin.world`, `knk.admin.delete` and `knk.admin.delete.bulk` but without `knk.admin.content`, repeat § 4.10 on a
   street that a record of another area uses: that record is named without a link with "Opening … requires one of: …"
   (or only counted without any area node), and drafts are only counted. A record whose own type the viewer can't read
   answers "You don't have access to <Type>. Requires one of: …" under its row instead of a list.

## 6. Themes and phone width

1. Repeat § 1.2, § 1.6 and § 4.2 with `?theme=brand` and with `?bg=off`, and at 390 px: the list fits the screen
   (no sideways scrolling), long names wrap, the dialog's Close stays visible.
2. [automated: `e2e/form-wizard-list-field.spec.ts`, "at 390 px › the selected card keeps the name readable and both
   buttons reachable"] ([#290](https://github.com/PandiO/knk-workspace/issues/290)) At 390 px, in Districts (a list field)
   of § 1.5, pick a district with a long name (e.g. "Old Harbour Market Quarter"), then press Escape to close the list.
   The card under "Selected (1):" shows the initial, the whole name (it wraps onto a second line instead of being cut to
   one letter) and the ID; × and **Edit instance** sit on their own line under the name, both fully on screen, and the
   page does not scroll sideways. Press ×: the card goes. (Without Escape the first tap outside the open list only closes
   it, [#570](https://github.com/PandiO/knk-workspace/issues/570).)
3. [automated: `e2e/form-wizard-list-field.spec.ts`, "at desktop width › the selected card stays one row: name, ×, Edit
   instance"] At desktop width the same card stays one row: initial, name with its ID under it, then × and **Edit
   instance** on the right, as before.
