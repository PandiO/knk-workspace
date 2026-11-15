# Form and Display builders: save in place, Publish, Duplicate, generate, preview (#71) — smoke test

**Status:** Written 2026-11-09 for knk-web-app and knk-web-api `claude/builders-71` (chain 3 link V7); run by the developer 2026-11-11/12: § 0–10 pass (§ 4.5, 9, 10 accepted; § 1.2 Save and close fixed in web `321e170`; § 3.4 is a note). **Merged 2026-11-12** (knk-web-api `master` `bc97b7d`, knk-web-app `main` `1371951`). **§ 11 (#291, validation rules in the draft):** 8 of 8 steps automated in CI (tagged, 2 of them partly: the real wizard); every step can still be run by hand; manual steps not run. Written 2026-11-15 for knk-web-api and knk-web-app `claude/builder-draft-rules-291` (Chain 3 follow-ups chain link L4), in review
**Last updated:** 2026-11-15 (§ 11 validation rules in the draft and add-from-template removed, #291); 2026-11-12 (smoke test result, merged)
**Issues:** [PandiO/knk-workspace#71](https://github.com/PandiO/knk-workspace/issues/71) (KNG-147: CRUD-11 save in
place, CRUD-12 scaffold and Duplicate, CRUD-13 preview, CRUD-14 explicit Publish); access model
[#280](https://github.com/PandiO/knk-workspace/issues/280)

About 35 minutes. **One additive migration (`AddConfigurationDrafts`), six new endpoints per controller, no setting.**
Both branches are stacked:

- knk-web-api `claude/builders-71` contains V6 `claude/picker-details-191-44` (and through it V5, AM1 + AM2
  `claude/dashboard-access-280`, P1, R1, X1's API). Deploy it with (or after) those, then `dotnet ef database update`.
- knk-web-app `claude/builders-71` contains V6 (and through it V5 … V1 and chain 2's X1 with W1–W4).

You need:
- **A** — the owner or an Admin account (holds `knk.admin.content`).
- A test database with the usual seeded form and display configurations (e.g. **Town**), a few towns, and one saved
  wizard draft on the Town form (start "New Town", fill a step, **Save Draft**).
- Two browser windows: one on the builder, one on the wizard / detail page, to see what staff see.
- Optional: a phone or the browser's 390 px view; the themes `current` and `brand` (`?theme=brand`), the page background on
  and off (`?bg=off`).

## 0. After the migration: nothing changed

1. Entity setup → **Town**: every form configuration is listed as before, without a **Draft** badge; the default still has
   the star. Dashboard → Town → **New Town** opens the same form as before.
2. Open a Town detail page: the same sections as before.

## 1. Save in place (CRUD-11), as A

1. Entity setup → Town → the default form's ⋯ → **Edit**. The builder opens with a header: **Form builder: …**, a green
   **Published** badge, "No unsaved changes.", **Save** and **Save and close** disabled (hover: "No unsaved changes.") and
   **Publish…** disabled with "Publish: Nothing to publish: the published version is up to date."
2. Rename a step (or a field label). The header says **Unsaved changes.**; **Save** and **Save and close** are enabled.
3. **Save**: a toast "Draft saved. Staff keep the published version until you publish."; you **stay in the builder**; the
   badge reads **Published · changes not published** with "Draft saved <time>".
4. In the other window open **New Town**: the wizard still shows the **old** step name.
5. Back in the builder: change something else, press **Save and close**: it saves and returns to Entity setup; the row
   shows **Unpublished changes**.
6. Open it again: your changes are there (the saved draft, not the published version).

## 2. Leave without saving

1. In the builder change the description, then click **Entity setup** in the breadcrumb: "Leave without saving?"
   → **Stay** keeps you there with the change; **Leave** goes.
2. Change something again and press the header's **Close**: the same question. With nothing changed, Close leaves at once.
3. Change something and reload the page (F5): the browser asks before leaving.

## 3. Publish with what changes (CRUD-14)

1. Open the form with saved changes (§ 1). Press **Publish…**: a dialog "Publish the changes to "…"?" lists what changes
   for staff ("1 step changed: …", "2 fields added: …", "Renamed from … to …"), and, because of your saved wizard draft,
   "1 saved draft continues on the new version; values of removed fields aren't used."
2. **Cancel** changes nothing. **Publish**: toast ""…" is published: staff get it from now on."; the badge is
   **Published** again.
3. In the other window open **New Town** again: the new step name shows now. Resume your saved wizard draft: it opens on
   the new version.
4. *Note, nothing to do:* the **Field name** box only offers the type's properties, so a field that isn't a Town property
   can't be made in the builder. The API's "Can't publish: …" refusal (the dialog stays open, nothing changes for staff)
   is covered by the API tests only.
5. Uncheck **Default form for Town (from the next Publish)**, Save, Publish…: the dialog says it stops being the default.
   Cancel and tick it again (or publish and make it the default again on Entity setup).
6. Unsaved changes are saved first: change a label, press **Publish…** directly (without Save): the dialog shows the
   change; after Publish the wizard has it.

## 4. A new form is a draft until its first Publish

1. Entity setup → Town → **Create Form**. The builder says **New**. Add a step (or use § 5), press **Save**: toast
   "Draft saved. Publish it when it is ready."; the address changes to `/admin/form-configurations/edit/<id>`; the badge
   says **Draft** ("Never published: staff can't use this form yet.").
2. Entity setup → Town: the new row has a **Draft** badge, **Use** is disabled ("Publish it in the builder first"), the ⋯
   menu has no **Set Default** and **Duplicate** is disabled.
3. Dashboard → Town: the **New with** menu doesn't list it; **New Town** still opens the default form.
4. Back in the builder: **Publish…** → "Publish "…"?" ("From now on staff can use this form …") → **Publish**. Entity
   setup: the Draft badge is gone, **Use** works, **New with** lists it.
5. Optional: create a second new form with **Create Form as Default**, Save and Publish: the dialog says it becomes the
   default for Town, replacing the old one; afterwards the star moved.

## 5. Generate from metadata (CRUD-12)

1. In a new or existing form builder: **More** → **Generate from metadata…**. A dialog lists Town's properties under
   "Values → step "General"" and "Links to other records → step "Links"", with what each becomes (Text, Whole number,
   Yes / no, Choice, "Domain picker", …) and Required. Properties the form already has are left out ("Leave out
   properties this form already has", untick to see them). **Not generated (n)** lists the rest with the reason (Id and
   timestamps "Set by the system.", collections "need a many-to-many step …").
2. Untick one, press **Add n fields**: new steps appear at the end of the list; toast "Added … Save to keep them." Edit them
   like any step; **Save** keeps them.
3. In the display builder the same dialog makes **Details**, **Related** (the related record's name, e.g. Domain) and one
   collection section per collection (e.g. **Streets**).

## 6. Duplicate (CRUD-12)

1. In the builder of a published form: **More** → **Duplicate…**: name "<name> (copy)", "A copy of the published version
   …". Change the name, **Duplicate**: toast "… created as a draft."; the copy opens in the builder with a **Draft** badge.
2. The copy has the same steps, fields, conditions and validation rules (open a field's rules); the original is unchanged
   (still the default). Publish the copy: it is a second Town form, not the default.
3. Entity setup → a published form's ⋯ → **Duplicate** does the same in one click ("<name> (copy)") and opens the copy.
4. Duplicate is off with unsaved changes ("Save or discard your changes first.") and on a form that was never published
   ("Publish it first: …").

## 7. Discard unpublished changes

1. Make and **Save** a change on a published form. **More** → **Discard unpublished changes…** → red question → **Discard**:
   toast "Back to the published version."; the builder shows the published version, the badge **Published**.

## 8. Preview (CRUD-13)

1. In the form builder press **Preview**: on a wide screen a panel opens next to the builder ("Preview of the working copy:
   nothing you enter here is saved …"). Step select with Back / Next; the fields as the wizard draws them, filled with
   **Sample values**. Rename a field label in the builder: the preview follows at once.
2. **A real Town**: search "Cin…" in the box, pick a town: "Showing Cinix (ID 4)." and the preview shows its values
   (a link field shows the linked record). **Empty**: the fields as a new form opens.
3. Type into a preview field and press Next: nothing is saved (no wizard draft appears on Entity setup), no in-game task is
   offered.
4. Display builder → **Preview**: the detail page with sample values (two items per collection); **A real Town** shows the
   town's real values and streets; the View buttons do nothing here.
5. At 390 px the preview sits under the builder; the page doesn't scroll sideways.

## 9. Access

1. The builders still need `knk.admin.content` to open (route gate). If you have an account with Entity setup access but
   without `knk.admin.content` (only possible once AM3 widens the route), its Save, Save and close, Publish, Duplicate,
   Discard and Generate are disabled with "Save, Publish and Duplicate: Requires knk.admin.content".
2. API (optional, with a token without `knk.admin.content`): `PUT api/FormConfigurations/<id>/draft`,
   `POST …/publish`, `POST …/duplicate` and `GET …/<id>/builder` answer 403.

## 10. Themes and phone width

1. Repeat § 1.1–1.3 and § 8.1 with `?theme=brand`, and with `?bg=off`.
2. At 390 px: the header is not sticky (it scrolls away), every button wraps, the **More** menu fits the screen, the Publish
   and Generate dialogs scroll inside themselves, and the page never scrolls sideways.

## 11. Validation rules in the draft ([#291](https://github.com/PandiO/knk-workspace/issues/291))

About 10 minutes for the whole section, about 3 minutes for the by-hand parts of § 11.2 and § 11.4. Deploy knk-web-api
and knk-web-app together, **API first** (an older API ignores the rules in the draft, so they would be lost on Save).
No migration, no setting. You need **A** and the Town form with at least two fields on one step (e.g. a town and a
location field), and the wizard window from the start of this guide.

1. [automated: e2e/form-builder-draft-rules.spec.ts, "a field that only exists in the draft gets a rule, saved with the draft"]
   As A, open the Town form in the form builder. Select a step, **Add Field**, give it a name, label and type and press
   **Save Field** (the field now exists only in the draft). Open it again with its pencil (**Edit field <label>**). Under
   **Cross-Field Validation Rules** there is no "Save this field first" notice, but the line "Rules are part of the draft:
   … staff get them when you publish." Press **+ Add Rule**, keep **Location Inside Region**, type an error message and
   press **Add Rule**: the rule appears with the badge **Not published**. Press **Save Field**, then **Save** in the
   toolbar: toast "Draft saved. Staff keep the published version until you publish."
2. [partly automated: e2e/form-builder-draft-rules.spec.ts, "a field that only exists in the draft gets a rule, saved
   with the draft" (nothing is written to `api/field-validation-rules`) and knk-web-api
   `FormConfigurationDraftRulesTests`, "SaveDraft_KeepsRuleChangesInTheDraft_TheWizardKeepsThePublishedRules"; by hand:
   the real wizard] In the wizard window, Dashboard → Town → **New Town**: the form is the published one (the new field
   is not there) and every published rule behaves as before.
3. [automated: knk-web-api `FormConfigurationDraftRulesTests`, "SaveDraft_KeepsRuleChangesInTheDraft_TheWizardKeepsThePublishedRules"]
   Back in the builder, open a published field that has a rule: change the rule's error message (**Edit** → **Save
   Rule**), press **Save Field** and **Save**. In the wizard, trigger that rule: it still shows the **old** message.
4. [partly automated: e2e/form-builder-draft-rules.spec.ts, "Publish names the new rule and publishes the saved draft";
   knk-web-api `FormConfigurationDraftRulesTests`, "Publish_AppliesRuleAddsUpdatesAndDeletes_ByFieldGuid"; by hand: the
   wizard after Publish] Delete one other published rule (**Delete** → confirm "The rule is removed from the draft; the
   published form keeps it until you publish.") and **Save Field**. Press **Publish…**: under "What changes for staff"
   the list ends with "Validation rules: 1 added, 1 changed, 1 removed." Press **Publish**. Reopen the fields: no rule
   shows **Not published**. In the wizard (start **New Town** again) the new field has its rule, the changed rule shows
   the new message and the deleted rule is gone.
5. [automated: knk-web-api `FormConfigurationDraftRulesTests`, "Discard_DropsTheRuleChanges"] Add a rule to any field,
   **Save Field**, **Save**. **More** → **Discard unpublished changes…** → **Discard**: the field's rules are the
   published ones again (the added rule is gone).
6. [automated: src/utils/forms/__tests__/draftValidationRules.test.ts, "refuses to publish a rule whose dependency left
   the form"; knk-web-api `FormConfigurationDraftRulesTests`, "Publish_RefusesARuleWhoseDependencyIsNoLongerInTheForm_AndChangesNothing"]
   Give a field a rule that **Depends On Field** another field of this form (pick a dependency path), **Save Field**.
   Delete the dependency field from the step and press **Publish…**: refused with "The <type> rule on "<label>" depends
   on a field that is no longer in the form. Edit or delete the rule." Nothing is published. Edit the rule (or put the
   field back) and the Publish question opens again.
7. [automated: knk-web-api `FormConfigurationDraftRulesTests`, "Publish_OfADraftSavedWithoutRules_KeepsThePublishedRules"]
   Only if a form had a saved draft from before this deploy: open it in the builder. Its fields show the **published**
   rules (none marked **Not published**). **Publish** it: the rules are unchanged in the wizard.
8. [automated: knk-web-api `FormConfigurationDraftRulesTests`, "AddFromTemplateEndpoints_AreGone"] Optional, API with an
   admin token: `POST api/FormConfigurations/<id>/steps/add-from-template` and
   `POST api/FormConfigurations/steps/<stepId>/fields/add-from-template` answer 404 (removed). **Add from template** in
   the builder still copies a template step or field into the draft (§ 1), live only after **Publish**.
