# Dashboard as the CRUD hub — proposal and plan

**Status:** Implemented on knk-web-app `claude/kng-60-dashboard-hub` (plan steps 1 and 2 = #177 links 1 and 2, UX/realtime chain links 1 and 3, 2026-10-26); not merged, waiting for the developer's test. Step 3 is #39 (chain link 9). Filed as PandiO/knk-workspace#177 on 2026-10-25
**Date:** 2026-10-24
**Issues:** [KNG-60](https://linear.app/kngpandi/issue/KNG-60) (return to origin, raised to High), [KNG-145](https://linear.app/kngpandi/issue/KNG-145) ("New X" on every list, list state in the URL), parent roadmap [KNG-140](https://linear.app/kngpandi/issue/KNG-140)
**Code basis:** knk-web-app `main` @ `b7c0e88` (2026-10-24)

## Filed (2026-10-25)

The hub issue is [PandiO/knk-workspace#177](https://github.com/PandiO/knk-workspace/issues/177) (sub-issue of
#24). KNG-60 is [#58](https://github.com/PandiO/knk-workspace/issues/58), KNG-145 is
[#39](https://github.com/PandiO/knk-workspace/issues/39), KNG-140 is
[#24](https://github.com/PandiO/knk-workspace/issues/24). Re-checked on knk-web-app `main` `0d61270`
(2026-10-25): the analysis below still holds; two additions (completed-before-save and the error-only
`ToastRegion`) are in #177 and in the plan
[`2026-10-25-ux-dashboard-signalr-plan.md`](2026-10-25-ux-dashboard-signalr-plan.md), which supersedes the
"Implementation plan" section below for ordering.

## Developer request (2026-10-24)

Editing an entity from the Dashboard is a round trip that loses its place: Dashboard → type in the
ObjectTypeExplorer → ✏️ Edit → the form opens on `/forms/{type}/edit/{id}`. Cancel stays on the Forms
page; selecting another type in the explorer stays on the Forms page; Submit goes back to the Dashboard
but on the **first** type (today EnchantmentDefinition, the first A–Z type of the "Entities" group), not
the type just edited. Expected: Submit and Cancel return to the Dashboard on the same type (and, ideally,
the same page/search).

Proposed by the developer: the Dashboard becomes the primary page for CRUD of entities **and** of their
form/display configurations and default table columns. The Dashboard stays as it is, with two actions
next to the type's title: **New** (opens an empty default form) and a **settings cogwheel** that opens
`/forms/{type}` (the Forms page as it is today: default table columns, form and display configurations
with add/edit/delete/default/publish/export/import, saved progress). Because display configurations are
then one click away, the explorer's "Entities / Without display configuration" split matters less.

## Current behaviour (verified)

- `src/components/ObjectDashboard/ObjectDashboard.tsx`: `selectedType` is local `useState('')`; the
  default-selection effect falls back to `getDefaultEntityName` (first A–Z type with a published default
  display configuration) whenever the selection is empty, i.e. on every mount. `handleEdit` navigates to
  `/forms/${type}/edit/${id}` with no origin. No "New" action on the page (assessment CRUD-2).
- `src/pages/FormWizardPage.tsx`: `handleComplete` navigates to `/dashboard` with
  `state: { entityTypeName }`, which `ObjectDashboard` never reads (the KNG-60 "half a bug").
  `handleLeaveForm` (KNG-162 `FormCancelAction`) closes the wizard and reloads the Forms page for the same
  type; it never returns to the Dashboard. The explorer on the Forms page navigates to `/forms/{other}`.
- "New" exists only in the Navigation "Create New" menu (hard-coded `objectConfigs` list) →
  `/forms/{type}?autoOpen=true`, which the Forms page already handles (Use Case 4: auto-open the default
  configuration). A Dashboard "New" button therefore has a working target today.
- `PagedEntityTable` keeps page/search/sort in internal state (`initialQuery` only); no controlled mode.
- KNG-60's analysis predates KNG-162 (the wizard now has a Cancel) and the DisplayWizardPage `/form/...`
  dead routes are already fixed. The rest of KNG-60 still holds (comment left on the issue).
- No overlapping claim in `docs/ACTIVE_SESSIONS.md` on `ObjectDashboard` / `FormWizardPage` /
  `ObjectTypeExplorer`. KNG-269 (In Review) touches `FormWizard.tsx` validation, not the page.

## Proposed design

**Dashboard header** (`ObjectDashboard`): one row with the type title on the left and, on the right, a
primary **"New {Type}"** button and a secondary icon button **⚙ "Configure {Type}"** (`aria-label`,
tooltip). "New {Type}" is repeated in the table's empty state (CRUD-2). ⚙ goes to `/forms/{type}` (the
Forms page unchanged; later the nav label "Forms" can become "Entity setup" or similar under NAV-5).

**Forms opened from the Dashboard carry the origin**: Edit → `/forms/{type}/edit/{id}?returnTo=…`,
New → `/forms/{type}?autoOpen=true&returnTo=…` (KNG-60 `returnTo`, same-app paths only). Submit (success
modal `onContinue` / auto-close) and Cancel (`handleLeaveForm`) navigate to `returnTo`; fallback
`/dashboard/{type}` → `/forms/{type}` → `/dashboard`. The existing parent/child redirect to
`/display/{parent}/{id}` stays first.

**An open form does not show the explorer.** While a wizard is open on the Forms page, hide the
`ObjectTypeExplorer` and show a breadcrumb instead ("Dashboard › EnchantmentDefinition › Edit Sharpness"),
built from `returnTo`. The explorer during an edit only loses work; "pick another type" is what the
breadcrumb/Cancel are for. The config lists on `/forms/{type}` keep the explorer.

**Dashboard state in the URL**: route `/dashboard/:entityName` (mirrors `/forms/:entityName`);
`/dashboard` alone opens the last viewed type (localStorage, KNG-60 open decision 1) or else the current
default. Page/search/sort as query params in a later link (needs `PagedEntityTable` controlled mode:
`query` + `onQueryChange`).

**Explorer on the Dashboard**: one flat list (search + A–Z as today) instead of the two groups. Types
without a published default display configuration get a small muted marker (icon + tooltip "No display
configuration – set one up via ⚙"), and the row click / 👁 View are disabled for them with the same hint
(View needs a default display configuration; the Dashboard already fetches
`displayConfigClient.getAll(false)` for this). Default selection when nothing is remembered: first A–Z
type that has one (as today).

## Implementation plan (one branch in knk-web-app, e.g. `claude/kng-60-dashboard-hub`)

1. **KNG-60, trimmed to the type** (highest value, smallest diff): `/dashboard/:entityName` + last-viewed
   fallback; `returnTo` helper (`src/utils/returnTo.ts`, sanitised); Dashboard Edit passes it;
   `handleComplete` and `handleLeaveForm` honour it; refresh the table on return. Tests: sanitiser,
   Dashboard reads the type from the URL, FormWizardPage navigates to `returnTo` on complete and cancel.
2. **The hub issue**: header actions (New, ⚙), New in the empty state, form view without the explorer +
   breadcrumb, flat explorer with marker, View disabled without a display configuration.
3. **KNG-145 remainder** when wanted: `PagedEntityTable` controlled mode so page/search/sort survive the
   round trip too; rows as links; bulk actions.

## Acceptance criteria

- Dashboard → type X → ✏️ Edit → Submit: back on the Dashboard with X selected and the row updated.
  Same with Cancel, nothing saved.
- Dashboard → type X → New → Submit or Cancel: back on the Dashboard with X selected.
- ⚙ opens `/forms/X` with the config lists; Save/Cancel in the builders still return to `/forms/X`.
- While a form is open, the explorer is not shown; the breadcrumb returns to the origin.
- Browser Back from an open form returns to the Dashboard type it was opened from; refreshing
  `/dashboard/X` keeps X.
- Types without a published default display configuration are visible in the flat list, marked, and
  their View/row click is disabled with a hint.
- `returnTo` values that are absolute or protocol-relative URLs are ignored.

## Submit feedback (developer requirement, 2026-10-24; goes into link 1)

The developer has seen Submit give no feedback for several seconds, then the success modal, and
wondered whether the click registered. Cause (`src/components/FormWizard/FormWizard.tsx` ~L2447–2624):
`saving` ("Submitting…", button disabled) only covers `saveProgress(Completed)`; `finally` clears it,
then `onComplete?.(...)` fires without being awaited, and `FormWizardPage.handleComplete` runs the
real create/update (plus the domain world resolve) with no pending state. The button reads "Submit"
again and can be clicked twice.

Fix: `onComplete` returns a promise and the wizard awaits it inside the `saving` window (one
re-entrancy guard so a second click is a no-op); the Submit button stays "Submitting…" and disabled, the
step strip and Cancel are disabled too, and a short status line ("Saving {Type}…") appears next to the
button. The result then goes to `returnTo` with a toast (decision 2). Submit failure keeps the form open
with the API's reason, as today.

## Decisions taken (2026-10-24)

1. Route: `/dashboard/:entityName`; bare `/dashboard` reopens the last viewed type.
2. After a successful Submit: return at once to `returnTo` and show a success toast on the dashboard
   (no 3 s modal). Plus the submit-pending feedback above.
3. "New" on a type without a default form configuration goes to `/forms/{type}`.
4. Nav label "Forms" → **"Entity setup"** in link 2, with the ⚙ button: page title to match, route
   `/forms` unchanged, the living docs that say "Forms page" updated in place (`architecture/
   web-app-architecture.md`, `guides/web-app-reading-guide.md`, `guides/alpha-hardening-smoke-test.md`,
   `guides/authoring-a-siege-scenario.md`, `guides/developer/gate-structures-developer-guide.md`,
   `architecture/multiworld-follow-ups.md`). Saved Progress stays on the page for now.

## Follow-up (on the hub issue, after link 2)

Move the page's second role to the dashboard so `/forms/{type}` is purely setup: a **"Drafts (n)"**
chip next to New that lists this type's Saved Progress and resumes one, and a **"New with: {config}"**
dropdown on New for non-default form configurations. Until then those two actions are only on the
Entity setup page.

## Open decisions

None.
