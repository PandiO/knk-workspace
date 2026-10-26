# Dashboard return, submit pending state and success toast (#177 link 1, #58) — smoke test

**Status:** Not run yet — waiting for the developer's test (2026-10-26)
**Last updated:** 2026-10-26
**Issues:** [PandiO/knk-workspace#177](https://github.com/PandiO/knk-workspace/issues/177) (link 1) ·
[#58](https://github.com/PandiO/knk-workspace/issues/58)
**Branches:** knk-web-app `claude/kng-60-dashboard-hub` (on `main` `0d61270`); knk-workspace `claude/kng-60-dashboard-hub`
(these docs). No API or plugin change, no migration, no setting.
**Chain:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) link 1; report
[2026-10-26-ux-realtime-chain.md](../reports/2026-10-26-ux-realtime-chain.md).

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
2. Open a form from the **Forms** page (`/forms/PermissionGroup`, a configuration or Saved Progress) and Cancel.
   Expected: unchanged behaviour — you stay on the Forms page with the lists reloaded.
3. Submit a form opened from the **Forms** page (no `returnTo`). Expected: `/dashboard/PermissionGroup` with the toast
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
