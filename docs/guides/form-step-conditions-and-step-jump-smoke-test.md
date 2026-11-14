# Form builder step conditions (#88) and clickable wizard steps (#68) — smoke test

**Status:** Written 2026-11-13; **merged into `next` 2026-11-13** (knk-web-app `next` `1f848f7` (knk-web-app#12), knk-web-api `next` `31abe2d` (knk-web-api#14), knk-workspace `next` `c68df65` (#379); branches `claude/issues-68-88-readiness-wapo57`), on the trunk when the developer promotes `next`; **not run by the developer**. Run it on `next`.
**Last updated:** 2026-11-14 (§ 2 step 1 and § 5 step 2: field mark and Go to after the #413/#414 fix; § 3 steps 1–3 use a field the metadata doesn't require, developer run 2026-11-13); 2026-11-13 (merged into `next`; § 3 step 5, § 4 steps 2, 3, 5 and 6 from the merged code: list fields, emptied lists, health check in step order and on the working copy, what the form does with hand-written JSON; docs #395)
**Issues:** [PandiO/knk-workspace#88](https://github.com/PandiO/knk-workspace/issues/88) (KNG-274: step conditions in
the step editor, Entry conditions enforced) ·
[PandiO/knk-workspace#68](https://github.com/PandiO/knk-workspace/issues/68) (KNG-184: click a step to jump to it,
rules run on pre-filled forms) · staff guide: [§ 5.1](admin/staff-web-app-guide.md#51-the-steps-of-a-form-next-clicking-a-step-and-what-stops-you) and [§ 7.1](admin/staff-web-app-guide.md#71-step-conditions)

About 25 minutes. **No migration, no setting, no plugin change.** The API change is one extra check in the
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
2. **Add condition**. Expected: *When* = "Before leaving this step (Next / Submit)", **active** ticked, one rule
   "Allow entry / is / ticked", and a red note "Add a message … Needed before you can publish".
3. **Save**. Expected: the draft saves (a draft may hold an unfinished condition).
4. **Publish**. Expected: refused with `Step "Region and access" has a "before leaving" condition without a message`.
5. Type the message `Allow entry before you continue.` The red note goes; the card says "1 condition" and
   "In words: Allow entry is ticked". **Publish** and confirm.
6. SQL or the network tab: the stored condition is
   `{"conditions":[{"fieldName":"AllowEntry","operator":"Equals","value":true}],"logic":"AND"}` with `isActive` true
   (`value` is the boolean `true`, not the text).
7. Reload the builder and open the step again. Expected: the same rows.

## 2. The wizard enforces it, and says so where you look (#88)

1. Dashboard → District → **New District**, fill step 1, go to **Region and access**, leave **Allow entry** unticked,
   **Next**. Expected: a toast with the message, the same message in red **above the Next button** (it stays after
   the toast is gone), and you stay on the step. Since #414 the **Allow entry** field itself also shows the message in
   red with the field's error styling, like a field validation rule.
2. Tick **Allow entry**, **Next**. Expected: the next step opens and the red note is gone.
3. Builder: untick **active** on the condition (the card says "1 condition, 1 off"), Save, Publish. Wizard (new
   form): Next passes with Allow entry unticked. Switch it back on and publish.

## 3. Entry conditions (#88)

1. Builder, on the **third** step of the District form: **Add condition**, *When* = "Before entering this step", tick
   **from an earlier step**, a field **F** of step 1 that is **not required**, operator **is not empty**, message
   `Fill in F first.` (Name can't be used: the entity's metadata requires it, so it can't be made optional; developer
   run 2026-11-13.) Expected: no value box ("no value needed"); "In words: F (earlier step) is not empty". An Entry
   condition publishes without a message too.
2. Publish. If step 1 has no optional field, use another form whose first step has one.
3. Wizard: leave F empty, Next to step 2, **Next**. Expected: refused on step 2 with the message (toast and above
   the button). Go back, fill in F, Next twice: step 3 opens.
4. Add a second rule to any condition. Expected: a **match all / any** switch appears; with one rule it is hidden.
5. A list field: on a form with a list field or a linked record (for example SiegeScenario), add a
   "before leaving" rule on that field. Expected: only **is empty** and **is not empty** are offered, no value box. With
   "is not empty" published: add an entry to the list in the wizard and remove it again, **Next**. Expected: refused
   (an emptied list counts as empty).

## 4. Guard rails in the builder (#88)

1. Rename or remove the field a rule reads (e.g. remove **Allow entry** from the step, in a draft). Expected: the
   rule's field box is red, shows the stored name with "(missing)" and says the rule can never hold.
2. **Configuration health** panel (under the builder, section General): it lists a warning `Step 'Region and
   access': a "before leaving" condition reads the field 'AllowEntry', which is not on this step. The condition can
   never hold; pick another field or remove the rule.` It checks the working copy, so it shows before Save too.
   Saving and publishing still work. Untick **active** on the condition. Expected: the line ends with "The condition
   is switched off, so the form skips it." Put the field back (or Discard the draft).
3. Hand-written JSON: with the API, store a condition whose `conditionJson` is not the rule shape (for example
   `{"anyOf":[{"field":"AllowEntry","eq":true}]}`). Expected: the builder shows it as text in a box with a note, and
   saving the step leaves the JSON unchanged. In the wizard this condition is not checked: Next passes
   ([#397](https://github.com/PandiO/knk-workspace/issues/397)).
4. Operators offered: is, is not, is greater than, is less than, contains, is empty, is not empty — nothing else.
5. Step order: in a draft, reorder the steps so the step with the condition's field comes **after** the step whose rule reads it
   "from an earlier step". Expected: the rule turns red and the health panel warns `… which is not on an earlier
   step.` (the check follows the order of the steps as shown, not the order they were created in). Move it back.
6. The same rule pointed at a field of a **later** step is not offered: the field list of "from an earlier step" only
   holds the fields of the steps before this one.

## 5. Clickable steps (#68)

1. **New District**, step 1 empty: click step 3 in the strip. Expected: a dialog `Can't go to "<step 3>" yet`,
   "Finish "<step 1>" first:" with "Name is required"; the field shows its message; no "Go to" button.
2. Fill step 1, leave **Allow entry** unticked on step 2 (don't open it), click step 3. Expected: the dialog names
   **Region and access** with the condition's message and a button **Go to Region and access**. ×, Close and Go to
   all respond (#413: before the fix the dialog locked while the progress saved). Press Go to: step 2 opens at once
   with the message above the Next button and on the Allow entry field (#414); the progress saves in the background,
   and a failed save shows in the wizard's banner (the next Next saves again).
3. A blocking rule in between: edit a District whose region is **outside** its town (or change the region in a
   draft), then from step 1 click the last step. Expected: the dialog names the step with the region rule and the
   rule's message; **Go to** opens it with the message on the field.
4. Stop the plugin, repeat 3 with a region that is fine. Expected: the jump **goes through**, and a dialog says
   "Not checked: the game server could not be reached" with the rule it skipped. Start the plugin again.
5. A non-blocking rule (a warning) on a step in between never stops the jump; it is listed under "Warnings (these
   don't stop you)" after you land.
6. **Back** is always allowed: from step 3 click step 1 with step 3 unfinished. No dialog, values kept.
7. A step hidden by a display condition is not in the strip and is not checked.
8. A many-to-many step (SiegeScenario → **Gates**) with an entry whose required field is empty stops a jump over it
   and names the entry.
9. Keyboard: Tab reaches every step; Enter or Space activates it; the current step is announced as current
   (`aria-current="step"`). At 390 px: the "Step x of n" label opens the list, and every row in it jumps the same way.
10. While the form is submitting, the steps can't be clicked.

## 6. Pre-filled forms (#68)

1. **Edit** an existing District (network tab open). Expected: right after the form loads, one `validate-batch`
   request per step that has rules, before any field is touched; nothing is saved by it.
2. Click straight to the last step. Expected: it opens when no blocking rule fails; a step whose rule failed on load
   shows the rule's message when you open it.
3. Resume a saved draft (**Saved drafts**): the same single run on load.
4. A new, empty form: no `validate-batch` on load.

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
