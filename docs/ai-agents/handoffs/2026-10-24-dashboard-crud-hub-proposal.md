# Dashboard as the CRUD hub — proposal and plan

**Status:** Proposal, waiting for the developer's decisions (no code written)
**Date:** 2026-10-24
**Issues:** [KNG-60](https://linear.app/kngpandi/issue/KNG-60) (return to origin, raised to High), [KNG-145](https://linear.app/kngpandi/issue/KNG-145) ("New X" on every list, list state in the URL), parent roadmap [KNG-140](https://linear.app/kngpandi/issue/KNG-140)
**Code basis:** knk-web-app `main` @ `b7c0e88` (2026-10-24)

## To file in Linear

Linear refused a new issue on 2026-10-24 ("exceeded the free issue limit for this workspace"), so the
proposal below lives here and as a comment on KNG-145 until the developer makes room. Needed:

- **One issue** "Dashboard as the CRUD hub: New + settings (⚙) on the entity header, forms open without
  the explorer and return to the dashboard, flat explorer list" — priority High, related to KNG-60,
  KNG-145, KNG-140, KNG-147. Body = sections "Developer request" to "Open decisions" below.
- KNG-145: move "New X on the Dashboard" into that issue; KNG-145 keeps page/search/sort/tab state in
  the URL, rows as links, bulk actions.

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

## Open decisions (reversible defaults proposed)

1. Route for the type: `/dashboard/:entityName` (proposed) or `/dashboard?type=`.
2. Success feedback after Submit: keep the 3 s auto-close modal on the form (proposed, target now
   `returnTo`), or return at once and show a toast on the Dashboard.
3. "New" when the type has no default form configuration: go to `/forms/{type}`, which already shows the
   "No default configuration" warning and the config list (proposed), or disable the button (needs one
   more call per type).
4. Nav label "Forms" → "Entity setup" (or similar): now, or with NAV-5.
