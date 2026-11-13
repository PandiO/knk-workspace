# Form builder step conditions (#88) and clickable wizard steps (#68) — smoke test

**Status:** Written 2026-11-13 for the branches `claude/issues-68-88-readiness-wapo57` (knk-web-app, knk-web-api, knk-workspace), pull requests into `next`; **not run by the developer, not merged**
**Last updated:** 2026-11-13
**Issues:** [PandiO/knk-workspace#88](https://github.com/PandiO/knk-workspace/issues/88) (KNG-274: step conditions in
the step editor, Entry conditions enforced) ·
[PandiO/knk-workspace#68](https://github.com/PandiO/knk-workspace/issues/68) (KNG-184: click a step to jump to it,
rules run on pre-filled forms)

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
   the toast is gone), and you stay on the step.
2. Tick **Allow entry**, **Next**. Expected: the next step opens and the red note is gone.
3. Builder: untick **active** on the condition (the card says "1 condition, 1 off"), Save, Publish. Wizard (new
   form): Next passes with Allow entry unticked. Switch it back on and publish.

## 3. Entry conditions (#88)

1. Builder, on the **third** step of the District form: **Add condition**, *When* = "Before entering this step", tick
   **from an earlier step**, field **Name**, operator **is not empty**, message `Give the district a name first.`
   Expected: no value box ("no value needed"); "In words: Name (earlier step) is not empty". An Entry condition
   publishes without a message too.
2. For this test only, make **Name** not required (or use a form whose first step can be left empty). Publish.
3. Wizard: leave Name empty, Next to step 2, **Next**. Expected: refused on step 2 with the message (toast and above
   the button). Go back, fill in the Name, Next twice: step 3 opens.
4. Add a second rule to any condition. Expected: a **match all / any** switch appears; with one rule it is hidden.

## 4. Guard rails in the builder (#88)

1. Rename or remove the field a rule reads (e.g. remove **Allow entry** from the step, in a draft). Expected: the
   rule's field box is red, shows the stored name with "(missing)" and says the rule can never hold.
2. **Configuration health** panel: after Save it lists a warning `Step 'Region and access': a "before leaving"
   condition reads the field 'AllowEntry', which is not on this step.` Saving and publishing still work. Put the
   field back (or Discard the draft).
3. Hand-written JSON: with the API, store a condition whose `conditionJson` is not the rule shape (for example
   `{"anyOf":[{"field":"AllowEntry","eq":true}]}`). Expected: the builder shows it as text in a box with a note, and
   saving the step leaves the JSON unchanged.
4. Operators offered: is, is not, is greater than, is less than, contains, is empty, is not empty — nothing else.

## 5. Clickable steps (#68)

1. **New District**, step 1 empty: click step 3 in the strip. Expected: a dialog `Can't go to "<step 3>" yet`,
   "Finish "<step 1>" first:" with "Name is required"; the field shows its message; no "Go to" button.
2. Fill step 1, leave **Allow entry** unticked on step 2 (don't open it), click step 3. Expected: the dialog names
   **Region and access** with the condition's message and a button **Go to Region and access**. Press it: step 2
   opens with the message above the Next button.
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
