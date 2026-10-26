# Form wizard: footer, unsaved-changes guard, blur validation, Save on any step, drafts per admin (#109, #186, #64) — smoke test

**Status:** Not run yet — waiting for the developer's test (2026-10-26)
**Last updated:** 2026-10-26
**Issues:** [PandiO/knk-workspace#109](https://github.com/PandiO/knk-workspace/issues/109) (footer, guard, validation, Save
on any step, single-line input) · [#186](https://github.com/PandiO/knk-workspace/issues/186) (drafts and workflow
sessions per admin + cleanup) · [#64](https://github.com/PandiO/knk-workspace/issues/64) (FormWizard debug logs only)
**Branches:** `claude/form-wizard-edit-mode` in knk-web-app (on `main` `7ba0f4b`), knk-web-api (on `master` `6f08383`) and
knk-workspace (these docs, the cleanup script). No migration, no setting. Test web app and API together: the web app
no longer sends a user id, and the API takes it from the login.
**Chain:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) link 5; report
[2026-10-26-ux-realtime-chain.md](../reports/2026-10-26-ux-realtime-chain.md).

Check out `claude/form-wizard-edit-mode` in knk-web-app (`npx npm@11 ci` if needed, `npm start`) and knk-web-api
(`dotnet run`). You need **two admin accounts** with `knk.admin.content` (and `knk.admin.world` for the workflow
session check), called A and B below, ideally in two browsers. Keep the network tab and a SQL client on the dev DB open.
Record each step in **Findings** at the end.

Handy SQL:
`SELECT Id, UserId, EntityTypeName, Status, ParentProgressId, CreatedAt FROM FormSubmissionProgresses ORDER BY Id DESC LIMIT 8;`
`SELECT Id, UserId, EntityTypeName, CreatedAt FROM workflow_sessions ORDER BY Id DESC LIMIT 5;`

## 1. Footer

1. As A, Dashboard → Town → **New Town**. Expected: Cancel form, Previous, Save Draft and Next sit in a bar at the
   bottom of the form; scrolling a long step keeps the bar at the bottom of the window. No "Cancel form" button above
   the form any more.
2. Narrow the window to phone width. Expected: the buttons stack, nothing overflows sideways.

## 2. Single-line fields

1. In the Town form: **Name** is a one-line box (Enter adds no line break); clicking the label "Name" puts the cursor in
   it. A description field (any field whose name ends in Description or Lore, e.g. an item blueprint's
   DefaultDisplayDescription) is still a text area.
2. Entity setup → a form configuration → edit a String field: the field editor shows **Multi-line text** (on for
   …Description/…Lore, off otherwise). Turn it on for Name, save, open the form: Name is a text area. Turn it off again.

## 3. Blur validation and the error summary

1. Click into Name and tab out without typing. Expected: "Name is required" under the field at once.
2. Type a name and tab out. Expected: the message goes.
3. Clear Name again and press **Next**. Expected: a red box at the top of the fields, "Fix this field to continue",
   with the link "Name is required"; the page scrolls to it. Click the link: the cursor is in Name.
4. If a form has a step completion condition (e.g. one from the KNG-186 test), break it and press Next. Expected: the
   condition's message is shown in the form (red banner at the top), not only as a toast.

## 4. Unsaved changes: ask only when something changed

1. Open a new Town form and, without typing, click **Dashboard** in the nav. Expected: you leave at once, no question.
2. Open it again and press **Cancel form** without typing. Expected: you leave at once (nothing created, nothing changed).
3. Open it again, type a name, click **Dashboard** in the nav. Expected: "Leave this form?" with **Stay** and **Leave
   form**. Stay: the form and the typed name stay. Again → Leave form: you are on the dashboard.
4. Type a name, then click a **breadcrumb** crumb. Expected: the same question (link 3's L3-2 is closed by this).
5. Type a name, then press the browser's **Back**. Expected: the same question.
6. Type a name, then **reload** the page (F5) or close the tab. Expected: the browser's own "Leave site?" question.
7. Type a name, press **Save Draft** (the "Progress saved" box), then click Dashboard. Expected: no question (the draft
   holds everything). Type one more letter: the question is back.
8. Type a name, press **Cancel form**. Expected: "Leave this form?" (Stay / Leave form); Leave form goes back to the
   dashboard. With an entity created in a child form, Cancel shows the keep/delete prompt as before (KNG-162).
9. Fill the form and **Submit**. Expected: back on the dashboard with the toast, **no** "Leave this form?" in between.

## 5. Save on any step (edit mode)

1. Dashboard → Town → **Edit** a town whose form has more than one step. Expected: on every step but the last there is
   **Save changes** next to Save Draft and Next; on the last step only Submit.
2. Change the name on step 1 and press **Save changes**. Expected: the town is saved (toast "Town updated.", back on the
   dashboard), with the values of the other steps unchanged (check the row or the detail page).
3. Edit a town again, clear a required field on a **later** step (go there, clear it, go back with Previous), then on
   step 1 press Save changes. Expected: the form jumps to that step, shows "Fix "{step}" before saving." and the summary;
   nothing is saved.
4. Creating a new entity: no Save changes button (Submit on the last step as before).

## 6. Drafts belong to the admin who made them (#186)

1. As A, open a new Town form, type a name, **Save Draft**. SQL: the newest FormSubmissionProgresses row has A's user id
   (not 1). The network tab: the POST body has no `userId`.
2. As B, open Entity setup → Town. Expected: A's draft is **not** in B's Saved Progress. As A: it is.
3. Opening a form with a world-task field creates a workflow session: SQL `workflow_sessions` newest row has the user id
   of whoever opened the form.
4. Relationship drafts are still shared on purpose: as A, start a Gate door draft for a gate structure (Save Draft in the
   child form); as B, edit that gate structure: the Gate doors field still lists A's draft, now with A's name ("by A").

## 7. Cleanup of the old user-1 rows (after deploy, on the alpha DB)

Only after the API and web app of this branch are deployed, and after a backup
([alpha-go-live.md](alpha-go-live.md) § 3 step 1):

1. Run [`scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql`](../../scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql)
   as its header says (`mysql -uroot -p knightsandkings_alpha < …`, or phpMyAdmin with foreign key checks ticked). If you
   run it days after the deploy, first set `@fixed_since` to the deploy time (UTC), so user 1's own new rows stay.
2. Expected: the first result lists every user-1 workflow session and draft and what happens to it; catalog-scan
   sessions and sessions whose world task's temporary region is still used by a domain are **KEEP** with the reason.
   The last result counts them.
3. Run it again. Expected: only the kept sessions, nothing deleted.
4. Saved Progress for any admin no longer shows the old shared drafts.

## Findings

| Step | Result | Notes |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |
| 7 | | |
