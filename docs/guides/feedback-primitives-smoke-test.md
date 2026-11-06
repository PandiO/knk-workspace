# Web app feedback primitives: Dialog, confirm, toasts (#33) — smoke test

**Status:** Written 2026-11-05 for knk-web-app `claude/feedback-primitives-33`; not merged, not run
**Last updated:** 2026-11-06 (§ 3: child-form leave question, LW2-2)
**Issues:** [PandiO/knk-workspace#33](https://github.com/PandiO/knk-workspace/issues/33) (toasts, one accessible
`Dialog`, confirm with danger and a required reason; sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24))
**Branches:** knk-web-app `claude/feedback-primitives-33` (on `main` `a7b231d`); knk-workspace `claude/feedback-primitives-33`
(these docs). No API or plugin change, no migration, no setting.
**Chain:** [UX_CHAIN_2.md](../ai-agents/handoffs/UX_CHAIN_2.md) link W2; report
[2026-11-05-ux-chain-2.md](../reports/2026-11-05-ux-chain-2.md) (W2 block). Design notes:
[web-app architecture § Feedback](../architecture/web-app-architecture.md#feedback-toasts-dialogs-and-confirms).

Web app only: check out `claude/feedback-primitives-33` in knk-web-app, `npx npm@11 ci` if needed, `npm start`, against
the dev API on trunk. Log in as an admin with `knk.admin.content`. Run the sections in the `current` and the `brand`
theme (cogwheel theme switcher), once with the page background on and once off (same menu, "Background image"), and
sections 1–3 once at phone width (browser dev tools, 390 px). Use a spare type (e.g. Category) for the deletes. Record each
step in **Findings** at the end.

What changed for you: every overlay (messages, confirms, child forms, the builders' editors and pickers, the import
panel, the two drawers) is one dialog that behaves the same way; success after a save or delete is a toast at the
bottom right instead of a box that closes after 3 s.

## 1. Confirm with danger (Entity setup)

1. Dashboard → a spare type → ⚙ (Entity setup). On a form configuration you can lose (create one with **Create Form** if
   needed), open ⋯ → **Delete**. A box "Delete this form configuration?" opens with a red top edge, a warning icon, a
   red **Delete** and focus (a ring) on **Cancel**.
2. Press Tab a few times: focus goes × → Cancel → Delete → × … and never reaches the page behind. Shift+Tab goes back.
3. Press **Escape**: the box closes, nothing is deleted, and focus is back on the ⋯ button of that row.
4. Open it again and click the dark area outside the box: it closes, nothing is deleted.
5. Open it again → **Delete**: the box closes, the row is gone and a green toast "The form configuration has been
   removed." shows at the bottom right. No second box.
6. The page doesn't scroll while the box is open (scroll wheel over the dark area), and scrolls again after.

## 2. Toasts

1. Hover the toast from 1.5 before it goes: it stays while the pointer is on it and leaves about 5 s after the pointer
   moves away. × closes it at once.
2. **Save Draft** in an open form (dashboard → **New {type}** → type a name → **Save Draft**): a toast "Your draft has been
   saved. You can continue later." and the form stays open; no box over the form.
3. Display configuration → ⋯ → **Publish** (on a draft) and **Delete**: a toast each, no box.
4. **Default Table Columns** → change a column → **Save Columns**: a toast "Default table columns have been updated…".
5. A form or display builder (Entity setup → ⋯ → **Edit**) → **Save Configuration**: you are back on Entity setup at
   once with the toast "Configuration updated successfully." (no 3 s box first).
6. With the API stopped (or offline in dev tools), reload the dashboard: the red error toast still shows, and stays
   about 8 s.

## 3. Child forms and nested dialogs

1. Open a form with a relationship field that has **Create new** (e.g. Street → District, or Gate Structure → Street).
   **Create new** opens "Create New {Type}"; focus is in its first field.
2. Click outside the child form: it stays open (nothing typed is lost). Without typing anything, the × closes it at once
   (no question).
3. Open it again, open a dropdown list inside it and press **Escape**: only the list closes. Press **Escape** again
   (nothing typed): the child form closes at once and focus is back on **Create new**.
4. **Unsaved changes ask first** (LW2-2, developer's decision 2026-11-06). Open the child form again and type a name.
   Press **Escape**: a red "Leave this form?" opens over the child form ("Changes you haven't saved are lost…") with
   focus on **Stay**. **Stay** (or Escape on the question) keeps the child form open with the name still there. Escape
   again → **Leave form**: the child form closes. Repeat with the ×: the same question. Type a name and clear it again,
   then Escape: it closes at once (no change). The parent form's own leave question (a link or Cancel form) is unchanged.
5. In a child form, make the save fail (e.g. a name that is already taken, or the API stopped) so "Save Failed" opens
   over the child form: **Escape** closes only the error, the child form stays.
6. While a child form saves (Submit), the × is disabled and Escape does nothing.

## 4. Editors, pickers, import, drawers

1. Form builder → a step → **Add field** / edit a field: "New Field" / "Edit Field" opens; click outside does nothing,
   Escape closes it; the footer (Cancel / Save Field) stays visible while the long form scrolls.
2. Form builder → **From Template** (step or field), display builder → **From Template** (section or field): the list
   cards can be picked with Tab + Enter (a ring and a pressed look), then **Add Step** / **Add Field** / **Add Section**.
3. Entity setup → **Import / Seeds**: the import dialog opens with focus on its first checkbox; **Check** a seed;
   while it runs Escape and the × do nothing.
4. Minecraft catalogue (needs attention) → **Merge into…** on a row: the picker opens with focus in the search field;
   Escape closes it; picking a target opens the confirm ("Merge this material?", red).
5. Invitations → **Redemptions** on a link: a drawer on the right; click outside or Escape closes it, focus back on the
   button.
6. Owner → Telemetry → an event: the drawer shows the event name as its heading and is above the navigation bar;
   click outside or Escape closes it.
7. A domain without a world (KNG-111 world prompt) and a world-task rescan that conflicts (scan conflict) open their
   questions in the same style (if easy to reach; otherwise skip).

## 5. Themes and background

1. In `brand`, the dialogs are white with the orange focus ring on the first button and the red **Delete**; the dark
   backdrop covers the navigation bar too.
2. With the page background on, a dialog stays solid white (no image showing through); the toast too.
3. At phone width, a dialog fits the screen with a margin, its body scrolls and its buttons stay visible.

## Findings

| Step | Result | Note |
|---|---|---|
| | | |
