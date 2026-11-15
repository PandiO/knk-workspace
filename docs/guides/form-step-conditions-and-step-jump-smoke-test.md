# Form builder step conditions (#88) and clickable wizard steps (#68) — smoke test

**Status:** 29 of 36 steps automated in CI (tagged `[automated: …]`; [#511](https://github.com/PandiO/knk-workspace/issues/511), 2026-11-14: the builder, wizard and step-jump Jest tests and the API's health tests); every step can still be run by hand; manual steps not run. Untagged, by hand only: saving and publishing in the builder (§ 1.1, 1.3, 1.4, 3.2), § 5.7, § 6.1–6.2. Earlier: Written 2026-11-13; **merged into `next` 2026-11-13** (knk-web-app `next` `1f848f7` (knk-web-app#12), knk-web-api `next` `31abe2d` (knk-web-api#14), knk-workspace `next` `c68df65` (#379); branches `claude/issues-68-88-readiness-wapo57`), on the trunk when the developer promotes `next`; **not run by the developer**. Run it on `next`.
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-14 (#413 retest and #488, knk-web-app `claude/wizard-messages-413-488`, not merged yet: § 2 step 1, § 3 step 3 and § 5 step 2 — no message above Next, summary and field mark; new § 5 step 2a, Go to → back → jump again); 2026-11-14 (§ 2 step 1 and § 5 step 2: field mark and Go to after the #413/#414 fix; § 3 steps 1–3 use a field the metadata doesn't require, developer run 2026-11-13); 2026-11-13 (merged into `next`; § 3 step 5, § 4 steps 2, 3, 5 and 6 from the merged code: list fields, emptied lists, health check in step order and on the working copy, what the form does with hand-written JSON; docs #395)
**Issues:** [PandiO/knk-workspace#88](https://github.com/PandiO/knk-workspace/issues/88) (KNG-274: step conditions in
the step editor, Entry conditions enforced) ·
[PandiO/knk-workspace#68](https://github.com/PandiO/knk-workspace/issues/68) (KNG-184: click a step to jump to it,
rules run on pre-filled forms) · staff guide: [§ 5.1](admin/staff-web-app-guide.md#51-the-steps-of-a-form-next-clicking-a-step-and-what-stops-you) and [§ 7.1](admin/staff-web-app-guide.md#71-step-conditions)

About 25 minutes for a full manual run, about 5 for the untagged steps. **No migration, no setting, no plugin change.** The API change is one extra check in the
configuration health panel; the web app works against an API without it.

You need:

- **A** — the owner or an Admin account (holds `knk.admin.content`).
- The dev database with the seeded **District** form (step "Region and access" with **Allow entry**), a Town with a
  WorldGuard region and a District inside it (the District seed carries a blocking `RegionContainment` rule on the
  region).
- The plugin running for § 5.1–5.3; stop it for § 5.4.
- Two browser windows: the form builder and the wizard.

## 1. Author a "before leaving" condition (#88)

1. Entity setup → **District** → open the default form in the builder → select the step **Region and access**. Under
   the step's Display Conditions there is a **Step conditions** card that says "No conditions".
2. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("builds the acceptance condition")] **Add condition**. Expected: *When* = "Before leaving this step (Next / Submit)", **active** ticked, one rule
   "Allow entry / is / ticked", and a red note "Add a message … Needed before you can publish".
3. **Save**. Expected: the draft saves (a draft may hold an unfinished condition).
4. **Publish**. Expected: refused with `Step "Region and access" has a "before leaving" condition without a message`.
5. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx`] Type the message `Allow entry before you continue.` The red note goes; the card says "1 condition" and
   "In words: Allow entry is ticked". **Publish** and confirm.
6. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("keeps a Boolean value a boolean")] SQL or the network tab: the stored condition is
   `{"conditions":[{"fieldName":"AllowEntry","operator":"Equals","value":true}],"logic":"AND"}` with `isActive` true
   (`value` is the boolean `true`, not the text).
7. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("shows stored conditions as the same rows")] Reload the builder and open the step again. Expected: the same rows.

## 2. The wizard enforces it, and says so where you look (#88)

1. [automated: `src/components/FormWizard/__tests__/FormWizard.validationMessages.ui.test.tsx` ("the screenshot case"), `e2e/form-wizard.spec.ts` (summary and field mark in the browser)] Dashboard → District → **New District**, fill step 1, go to **Region and access**, leave **Allow entry** unticked,
   **Next**. Expected (#488): you stay on the step, and the message shows in three places, each once: the summary
   at the top ("Fix this problem to continue", the message as a link that puts the focus on Allow entry), **under**
   the Allow entry checkbox in red with the field's red box (#414), and one toast. **Nothing above the Next button**
   and no red banner. Also leave **Region** empty: the summary says "Fix these 2 problems to continue" and lists
   "Region is required" and the condition's message, each field shows its own message, and the toast says "Fix the 2
   problems on this step to continue."
2. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("the mark goes when the condition holds")] Tick **Allow entry** (and fill Region), **Next**. Expected: the condition's line leaves the summary and the field
   as soon as you tick it; Next opens the next step.
3. [automated: `src/components/FormWizard/__tests__/FormWizard.stepCompletionCondition.ui.test.tsx` ("a condition the admin switched off")] Builder: untick **active** on the condition (the card says "1 condition, 1 off"), Save, Publish. Wizard (new
   form): Next passes with Allow entry unticked. Switch it back on and publish.

## 3. Entry conditions (#88)

1. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("writes an Entry condition over a field from an earlier step")] Builder, on the **third** step of the District form: **Add condition**, *When* = "Before entering this step", tick
   **from an earlier step**, a field **F** of step 1 that is **not required**, operator **is not empty**, message
   `Fill in F first.` (Name can't be used: the entity's metadata requires it, so it can't be made optional; developer
   run 2026-11-13.) Expected: no value box ("no value needed"); "In words: F (earlier step) is not empty". An Entry
   condition publishes without a message too.
2. Publish. If step 1 has no optional field, use another form whose first step has one.
3. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("Next: an Entry condition on step 3 … stops Next on step 2"), `src/components/FormWizard/__tests__/FormWizard.validationMessages.ui.test.tsx` ("in the summary only, as text")] Wizard: leave F empty, Next to step 2, **Next**. Expected: refused on step 2 with the message in the summary at
   the top (as text, not a link: F is not on this step) and one toast; nothing above the button (#488). Go back, fill
   in F, Next twice: step 3 opens.
4. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("with all / any for two rules")] Add a second rule to any condition. Expected: a **match all / any** switch appears; with one rule it is hidden.
5. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` (list fields offer only is empty / is not empty), `src/components/FormWizard/__tests__/FormWizard.requiredList.ui.test.tsx` (an emptied list counts as empty)] A list field: on a form with a list field or a linked record (for example SiegeScenario), add a
   "before leaving" rule on that field. Expected: only **is empty** and **is not empty** are offered, no value box. With
   "is not empty" published: add an entry to the list in the wizard and remove it again, **Next**. Expected: refused
   (an emptied list counts as empty).

## 4. Guard rails in the builder (#88)

1. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("flags a rule whose field is no longer on the step")] Rename or remove the field a rule reads (e.g. remove **Allow entry** from the step, in a draft). Expected: the
   rule's field box is red, shows the stored name with "(missing)" and says the rule can never hold.
2. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/StepConditionHealthTests.cs` ("Condition_OnAFieldThatIsNotOnTheStep_IsAWarning", "WorkingCopy_FollowsStepOrderJsonToo", "SwitchedOffCondition_IsOnlyInformation")] **Configuration health** panel (under the builder, section General): it lists a warning `Step 'Region and
   access': a "before leaving" condition reads the field 'AllowEntry', which is not on this step. The condition can
   never hold; pick another field or remove the rule.` It checks the working copy, so it shows before Save too.
   Saving and publishing still work. Untick **active** on the condition. Expected: the line ends with "The condition
   is switched off, so the form skips it." Put the field back (or Discard the draft).
3. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("shows JSON that is not the rule shape as text"), knk-web-api `Tests/knkwebapi_v2.Tests/Services/StepConditionHealthTests.cs` ("JsonThatIsNotTheBuilderShape_IsNotJudged")] Hand-written JSON: with the API, store a condition whose `conditionJson` is not the rule shape (for example
   `{"anyOf":[{"field":"AllowEntry","eq":true}]}`). Expected: the builder shows it as text in a box with a note, and
   saving the step leaves the JSON unchanged. In the wizard this condition is not checked: Next passes
   ([#397](https://github.com/PandiO/knk-workspace/issues/397)).
4. [automated: `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx` ("offers only the operators the wizard evaluates")] Operators offered: is, is not, is greater than, is less than, contains, is empty, is not empty — nothing else.
5. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/StepConditionHealthTests.cs` ("FromPreviousStep_FollowsStepOrderJson_NotTheStoredOrder")] Step order: in a draft, reorder the steps so the step with the condition's field comes **after** the step whose rule reads it
   "from an earlier step". Expected: the rule turns red and the health panel warns `… which is not on an earlier
   step.` (the check follows the order of the steps as shown, not the order they were created in). Move it back.
6. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/StepConditionHealthTests.cs` ("FromPreviousStep_LooksAtEarlierStepsOnly"), `src/components/FormConfigBuilder/__tests__/StepConditionBuilder.test.tsx`] The same rule pointed at a field of a **later** step is not offered: the field list of "from an earlier step" only
   holds the fields of the steps before this one.

## 5. Clickable steps (#68)

1. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("stops on the current step and says which field is missing")] **New District**, step 1 empty: click step 3 in the strip. Expected: a dialog `Can't go to "<step 3>" yet`,
   "Finish "<step 1>" first:" with "Name is required"; the field shows its message; no "Go to" button.
2. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("stops at the first step in between that fails", "a jump stopped by a condition: Go to lands with the field marked", the #413 block), `src/components/FormWizard/__tests__/FormWizard.validationMessages.ui.test.tsx` ("a step-jump stop: after Go to …")] Fill step 1, leave **Allow entry** unticked on step 2 (don't open it), click step 3. Expected: the dialog names
   **Region and access** with the condition's message and a button **Go to Region and access**. ×, Close and Go to
   all respond (#413: before the fix the dialog locked while the progress saved). Press Go to: step 2 opens at once
   with the same summary at the top and the same message under the Allow entry field as after Next (§ 2 step 1), no
   toast and nothing above the Next button (#488); the progress saves in the background, and a failed save shows in
   the wizard's banner (the next Next saves again).

   **2a.** [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx`, the #413 block, also under StrictMode as on the dev server] Go to → back → jump again (#413 retest 2026-11-14; run it on the dev server, `npm start`, where it locked, and
   on the deployed build). From step 2 after Go to, go back to step 1 with **Previous**, click step 3. Expected: the
   dialog opens with ×, **Close** and **Go to Region and access** all enabled; Close closes it. Click step 3 again,
   **Go to**, then click step 1 **in the strip** and step 3 again: the buttons work again. At 390 px do the same
   through the "Step x of n" list.
3. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("a blocking rule on a step in between stops the jump")] A blocking rule in between: edit a District whose region is **outside** its town (or change the region in a
   draft), then from step 1 click the last step. Expected: the dialog names the step with the region rule and the
   rule's message; **Go to** opens it with the message on the field.
4. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("a rule that could not run (game server unreachable) is a notice, not a stop")] Stop the plugin, repeat 3 with a region that is fine. Expected: the jump **goes through**, and a dialog says
   "Not checked: the game server could not be reached" with the rule it skipped. Start the plugin again.
5. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("a warning never stops the jump")] A non-blocking rule (a warning) on a step in between never stops the jump; it is listed under "Warnings (these
   don't stop you)" after you land.
6. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("going back is always allowed")] **Back** is always allowed: from step 3 click step 1 with step 3 unfinished. No dialog, values kept.
7. A step hidden by a display condition is not in the strip and is not checked.
8. [automated: `src/components/FormWizard/__tests__/FormWizard.validationMessages.ui.test.tsx` ("a many-to-many step …"), `src/utils/forms/__tests__/stepJumpCheck.test.ts`] A many-to-many step (SiegeScenario → **Gates**) with an entry whose required field is empty stops a jump over it
   and names the entry.
9. [automated: `src/components/FormWizard/__tests__/WizardStepHeader.test.tsx` ("renders every step as a button, with the current one marked", "makes the steps in the narrow-screen list buttons too")] Keyboard: Tab reaches every step; Enter or Space activates it; the current step is announced as current
   (`aria-current="step"`). At 390 px: the "Step x of n" label opens the list, and every row in it jumps the same way.
10. [automated: `src/components/FormWizard/__tests__/WizardStepHeader.test.tsx` ("disables the steps while the form is saving")] While the form is submitting, the steps can't be clicked.

## 6. Pre-filled forms (#68)

1. **Edit** an existing District (network tab open). Expected: right after the form loads, one `validate-batch`
   request per step that has rules, before any field is touched; nothing is saved by it.
2. Click straight to the last step. Expected: it opens when no blocking rule fails; a step whose rule failed on load
   shows the rule's message when you open it.
3. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("a resumed draft runs the rules of every step once")] Resume a saved draft (**Saved drafts**): the same single run on load.
4. [automated: `src/components/FormWizard/__tests__/FormWizard.stepJump.ui.test.tsx` ("a new, empty form runs no rules when it loads")] A new, empty form: no `validate-batch` on load.

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
