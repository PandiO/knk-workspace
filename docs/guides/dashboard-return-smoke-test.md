# Dashboard as the CRUD hub: return, submit pending state, toast, New/Configure, breadcrumbs, detail header, Create New (#177 links 1–2, #58, #81, #39) — smoke test

**Status:** Not run yet — waiting for the developer's test (2026-10-26)
**Last updated:** 2026-10-26 (sections 8–14 added for #177 link 2 = chain link 3)
**Issues:** [PandiO/knk-workspace#177](https://github.com/PandiO/knk-workspace/issues/177) (links 1 and 2) ·
[#58](https://github.com/PandiO/knk-workspace/issues/58) · [#81](https://github.com/PandiO/knk-workspace/issues/81) (detail
page header) · [#39](https://github.com/PandiO/knk-workspace/issues/39) (Create New menu only)
**Branches:** knk-web-app `claude/kng-60-dashboard-hub` (on `main` `0d61270`); knk-workspace `claude/kng-60-dashboard-hub`
(these docs). No API or plugin change, no migration, no setting.
**Chain:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) links 1 and 3; report
[2026-10-26-ux-realtime-chain.md](../reports/2026-10-26-ux-realtime-chain.md). Sections 1–7 are link 1, 8–14 link 3;
both are on the same branch and can be tested in one sitting.

Web app only: check out `claude/kng-60-dashboard-hub` in knk-web-app, `npx npm@11 ci` if needed, `npm start`, against
the dev API on trunk. Log in as an admin with `knk.admin.content`. Keep the browser's network tab open for step 4, and a
SQL client on the dev DB for step 5. Record each step in **Findings** at the end.

Handy SQL, used below as **"the draft"**:
`SELECT Id, EntityTypeName, EntityId, Status, UpdatedAt FROM FormSubmissionProgresses ORDER BY Id DESC LIMIT 5;`

## 1. The dashboard type is in the URL

1. Open **Dashboard** from the nav. Expected: the URL becomes `/dashboard/{type}` for the type it opens on (the first
   time: the first A–Z type with a published default display configuration, as before). The nav's Dashboard link is
   highlighted.
2. Pick **PermissionGroup** (or any other type) in the explorer. Expected: URL `/dashboard/PermissionGroup`, its table.
3. Refresh the page. Expected: still PermissionGroup.
4. Click another nav item, then **Dashboard** again. Expected: back on PermissionGroup (last viewed type).
5. Open `/dashboard/NoSuchType` by hand. Expected: no table for NoSuchType (no failing request); the URL is replaced by
   the last viewed or default type.
6. Pick two types one after the other, then press browser **Back**. Expected: the previous type.

## 2. Edit → Submit returns to the type, with a toast

1. On `/dashboard/PermissionGroup` click ✏️ **Edit** on a row. Expected: the form opens on
   `/forms/PermissionGroup/edit/{id}?returnTo=%2Fdashboard%2FPermissionGroup`.
2. Change a field, go through the steps, **Submit**. Expected: back on `/dashboard/PermissionGroup` at once (no
   "Form completed" modal), the row shows the new value, and a green toast bottom right: "{Type} updated." that goes
   away after about 5 s.
3. Repeat with a type whose form has one step only (Submit on the first page). Same result.

## 3. Cancel returns to the type

1. From `/dashboard/PermissionGroup` open ✏️ Edit, change something, **Cancel form** → **Leave form**. Expected: back on
   `/dashboard/PermissionGroup`, nothing saved (the row shows the old value).
2. Open a form from the **Entity setup** page (`/forms/PermissionGroup`, a configuration or Saved Progress) and Cancel.
   Expected: unchanged behaviour — you stay on the Entity setup page with the lists reloaded.
3. Submit a form opened from the **Entity setup** page (no `returnTo`). Expected: `/dashboard/PermissionGroup` with the toast
   (before: the dashboard on its first type after a 3 s modal).

## 4. Submit pending state

Use a slow save: Chrome DevTools → Network → throttling **Slow 3G** (or Offline after the last Next, then back online).

1. On the last step click **Submit**. Expected: the button reads "Submitting…" with a spinner and is disabled; next to
   it "Saving {Type}…"; **Previous**, **Save Draft** and **Cancel form** are disabled.
2. Click Submit again (and press Enter) while it is pending. Expected: the network tab shows **one** create/update
   request for the entity.
3. When the save returns: the page leaves for the dashboard with the toast (step 2).

## 5. A refused save leaves the draft not Completed

1. Make the API refuse a save: any create or update the API answers with a 4xx and a reason, e.g. a siege
   configuration that breaks a save-time rule.
2. Submit. Expected: the form stays open with "Submit failed" and the API's reason; Submit is enabled again.
3. Run **the draft**. Expected: the draft of this form is `InProgress`, **not** `Completed` (before: `Completed`).
4. Fix the value and Submit again. Expected: saved, back on the dashboard; the draft is now `Completed`.
5. In a form with a child "Create new" (e.g. a GateStructure's door), make the child's save fail. Expected: the child
   modal stays open with the reason (unchanged); the child's own draft is not `Completed`.

## 6. Child forms opened from a display page still return there

1. On a display page that offers "create" for a child (parent/child flow, `?parentEntityTypeName=…`), create the child
   and Submit. Expected: back on `/display/{parent}/{id}` with the success toast (no modal).

## 7. Error toasts unchanged

1. Stop the API and open the dashboard. Expected: the red error toasts as before, next to any green one.

## 8. Dashboard header: New {Type} and Configure (#177 link 2)

1. On `/dashboard/Town`: next to the title a **New Town** button and a cogwheel (tooltip "Configure Town: form and
   display configurations, default columns").
2. **New Town**. Expected: `/forms/Town?autoOpen=true&returnTo=%2Fdashboard%2FTown`, the default form open. Fill it in,
   Submit. Expected: back on `/dashboard/Town`, toast "Town created.", the new row in the table.
3. **New Town** again, **Cancel form** → Leave. Expected: back on `/dashboard/Town`, nothing created.
4. Cogwheel. Expected: `/forms/Town` with the explorer, Default Table Columns, form and display configurations, Saved
   Progress. Edit a form configuration in the builder and Save / Cancel: back on `/forms/Town` as before.
5. A type **without a default form configuration** (or remove the default of a test type for a moment): **New {Type}**.
   Expected: the Entity setup page of the type with the yellow notice "To create a new {Type}, this type needs a default
   form configuration: …"; no form opens.
6. A type with **no rows** (or search the table for nothing, then clear the search). Expected: the empty table says
   "No {Type} yet." with a **New {Type}** button; with a search that matches nothing it says "No results found".

## 9. Flat explorer with the "no display configuration" marker

1. On the dashboard the explorer is **one A–Z list** (no "Entities" / "Without display configuration" headings).
2. Types without a published default display configuration show a small crossed-out eye; hovering it says "No display
   configuration – set one up via ⚙".
3. Pick such a type. Expected: its table shows; the 👁 **View** button is greyed out with the same tooltip and clicking
   a row does nothing; Edit, Delete and New work.
4. A type with a display configuration: View and the row click open the detail page (section 11).

## 10. An open form hides the explorer and shows a breadcrumb

1. From `/dashboard/Town` ✏️ Edit "Cinix" (any town). Expected: no explorer on the left; above the form a breadcrumb
   **Dashboard › Town › Edit Cinix** (shows "Edit #id" for a moment while the name loads).
2. Click **Town** in the breadcrumb. Expected: back on `/dashboard/Town` without the "Leave this form?" question and
   nothing saved (the draft stays in Saved Progress as before). **Dashboard** goes to `/dashboard` (last viewed type).
3. Edit again and press the browser **Back** button. Expected: `/dashboard/Town`.
4. On `/forms/Town` open a configuration (or resume Saved Progress). Expected: no explorer; breadcrumb **Entity setup ›
   Town › New Town**. Click **Town**: the configuration lists come back with the explorer.

## 11. Detail page header (#81)

1. From `/dashboard/Town` click 👁 View (or the row). Expected: `/display/Town/{id}?returnTo=%2Fdashboard%2FTown`; the
   heading is the town's **name** (before: the display configuration's name), "TOWN" above it, a breadcrumb
   **Dashboard › Town › Cinix**, and the browser tab "Cinix · Town · Knights & Kings".
2. **Back**. Expected: `/dashboard/Town`. Open `/display/Town/{id}` without `returnTo` by hand: Back goes to
   `/dashboard/Town` too.
3. **Edit**. Expected: the form with breadcrumb **Dashboard › Town › Cinix › Edit Cinix**; change a field, Submit.
   Expected: back on the detail page with the toast and the new value.
4. **Delete** on a disposable entity. Expected: a red confirm "Delete Town "…"?" naming it; Cancel does nothing;
   Delete removes it, toast "Town "…" deleted.", back on `/dashboard/Town`.
5. **Delete** on an entity the API refuses to delete (one in use, e.g. a Town with districts). Expected: a red toast with
   the API's reason; you stay on the page.
6. Edit / view / create actions inside the detail page's sections (child entities) open their pages and come back to
   this detail page.

## 12. User rows open the player profile

1. `/dashboard/User` → ✏️ Edit on a row. Expected: `/admin/users/{id}` (the staff player profile); its Back returns to the
   dashboard. Needs `knk.admin.user.manage` like the profile itself.
2. **New User** still opens the generic User form (until #72/#148).

## 13. Create New menu from the entity metadata

1. Click **Create New** in the nav. Expected: a filter box with the cursor in it and an A–Z list of every type the app
   can create, including Item blueprint, Kit, Grade, Tag, Enchantment definition, the siege types and Domain sub region;
   **no** "Item Type".
2. Type "gate". Expected: only the gate types. ArrowDown / ArrowUp move the highlight, **Enter** opens the highlighted
   type's default form; Escape closes the menu (focus back on the button).
3. Pick a type, then press the browser **Back** once. Expected: the page you were on (before: Back had to be pressed
   twice, the menu navigated twice).
4. Submit the form opened from the menu. Expected: `/dashboard/{type}` with the toast. Cancel: the same dashboard type.

## 14. "Entity setup"

1. The nav link that said **Forms** says **Entity setup** and is highlighted on `/forms/...`; the tab title on
   `/forms/...` is "Entity setup · Knights & Kings". The route is still `/forms`.

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
| 8 | | |
| 9 | | |
| 10 | | |
| 11 | | |
| 12 | | |
| 13 | | |
| 14 | | |
