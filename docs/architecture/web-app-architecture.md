# knk-web-app — Architecture

**Status:** Living document — reflects actual code, updated in place on each rescan
**Last updated:** 2026-11-13 (`test:ci` runs in the `Build and test` CI workflow; the "no CI workflow" note was stale); 2026-11-13 (step conditions in the builder #88 and clickable wizard steps #68, on `claude/issues-68-88-readiness-wapo57`, not merged); 2026-11-13 (detail page Select / Change / Unlink / Add need `knk.admin.content`, `withContentNode` kept as a no-op against an API with #374, knk-web-app `next` `ca1959d`, docs #385); 2026-11-13 (form wizard and create/edit back on `knk.admin.content`, #371, LAM3-1 reverted, knk-web-app `next` `e6ba115`, docs #378); 2026-11-13 (dashboard access model in the web app and bulk delete, #280 AM3 and #205, merged into `main` `e02ee79`: new section, export through `POST api/Dashboard/export`, `staffAny` routes, Dashboard link for any area node — docs #366); 2026-11-12 (chain 2 W1–W4 and X1 and chain 3 V1–V7 merged into `main` `1371951`; their sections below brought over and marked merged — docs issues #337–#345); 2026-11-05 (live updates on the dashboard, detail page, moderation list and profile — #183, branch `claude/realtime-web-live-183`, merged 2026-11-12); 2026-11-09 (form and display builders: Save keeps the builder open and stores a draft, Save and close, explicit Publish with what changes for staff, Duplicate, Generate from metadata, live preview, "Leave without saving?" — #71, branch `claude/builders-71`, not merged); 2026-11-09 (form wizard search-as-you-type relation picker with Open full table and a lookup mode for viewers without the type's read node, #191; FeedbackModal "Show details" and "Show what uses it" on a delete refused as in use, #44 — branch `claude/picker-details-191-44`, not merged); 2026-11-09 (entity detail page: real Select / Unlink / Add through `api/Relationships`, a separate Delete, actions disabled with "Requires …", values as text, related values as links, paged collections, readable load errors — #188, #189, branch `claude/entity-detail-188-189`, not merged); 2026-11-08 (settings pages: Lootbox settings tab, Currency policy and Road network on the SettingsPage shell, units and help, confirms on risky switches, lootbox announcement preview — #26, branch `claude/settings-pages-26`, not merged); 2026-11-08 (staff player profile: status strip, tabs, freeze/unfreeze, per-player timeline, paged audit log; moderation search by dashless UUID, sort, search in the URL, recently opened — #119, branch `claude/player-profile-119`, not merged); 2026-11-08 (dashboard checkbox selection and Export CSV behind `knk.admin.export` — #205 export part, branch `claude/dashboard-export-205`, not merged); 2026-11-08 (Entity setup at phone width, raw colours checked in `test:ci`, landing slideshow fade out → in, `usePrefersReducedMotion` — #266, #263, #258, branch `claude/web-fixes-266-263-258`, not merged); 2026-11-06 (Dashboard kept in the top bar — LW4-1, #30); 2026-11-06 (numbers in the viewer's locale — LW3-1, #187); 2026-11-06 (child form asks before closing with unsaved changes — LW2-2, #33); 2026-11-05 (admin information architecture: route-meta table, public/player/admin layout routes, grouped admin sidebar, breadcrumbs, `/admin` overview — #30, branch `claude/admin-ia-30`, stacked on #197 and #187 (which contains #33), not merged); 2026-11-05 (no "Entity setup" nav link, the Dashboard link is current on the content-tool pages — #197, branch `claude/nav-entity-setup-197`, not merged); 2026-11-05 (data and format primitives: `DataTable`/`Pager`, `utils/format.ts`, `Field`, `SettingsPage` shell with dirty state — #187, branch `claude/data-primitives-187`, stacked on #33, not merged); 2026-11-05 (feedback primitives: one accessible `Dialog`, `ConfirmDialog` with danger and a reason, general toasts, all overlays moved — #33, branch `claude/feedback-primitives-33`, not merged); 2026-11-05 (#239 offer permission check, #240 Send again merged); 2026-11-04 (#239, #240 on a feature branch); 2026-11-02 (`src/realtime/RealtimeProvider`, world tasks and catalogue scans over the web hub — #181, branch `claude/realtime-signalr`); 2026-11-01 (world tasks anchored to the draft, cancel/expired states, task code, builder task types — #180, branch `claude/world-task-hardening`); 2026-09-18 (scan basis: `knk-web-app` @ `4ff5dc6`, branch `claude/web-app-codebase-scan-4yqibi`); spot edits 2026-10-09 (ObjectTypeExplorer, KNG-61), 2026-10-10 (FormWizard Boolean fields, KNG-53), 2026-10-12 (FormWizard child forms, KNG-133, KNG-134; List edit load, step header, List validation, KNG-135, KNG-137, KNG-164; form session registry, KNG-136; cancel / delete-draft prompt, KNG-162; form configuration export/import, KNG-138); 2026-10-17 (form wizard chain merged to `main`; smoke-test follow-ups KNG-166..169, KNG-172, KNG-173: step strip, confirmations and refusals, rule builder parent forms, picker columns, metadata refresh); 2026-10-22 (display configuration export/import; KNG-195 hybrid picker submit); 2026-10-23 (step completion conditions run, KNG-186); 2026-10-23 (validation result log, batch validate, Re-check, KNG-269); 2026-10-25 (toast region, world-task polling; UX re-evaluation in `reports/2026-10-25-web-app-ux-reevaluation.md`); 2026-10-26 (dashboard type in the URL, `returnTo`, submit pending state, success toast — PandiO/knk-workspace#177 link 1, #58); 2026-10-26 (dashboard header New/Configure, flat explorer with marker, open form without the explorer + breadcrumb, detail page header, metadata-driven Create New, "Entity setup" — #177 link 2, #81, #39); 2026-10-26 (dashboard explorer: one scrollbar, favourite types — #194, branch `claude/dashboard-explorer-194`, merged into `main` `c3c0c9f`), 2026-10-26 (dashboard header row spacing — #195, branch `claude/dashboard-header-195`, merged into `main` `c3c0c9f`); 2026-10-26 (data router, unsaved-changes guard, sticky footer, blur validation + error summary, Save on any step in edit mode, single-line input, drafts owned by the login — #109, #186, #64 FormWizard part); 2026-10-27 (unsaved changes compared by value across all steps, Next's progress save no longer counts as saved — #109 fix round); 2026-11-01 (dashboard table state in the URL, rows as links, `aria-sort`, lootbox/moderation tab in the URL, "Drafts (n)" and "New with" — PandiO/knk-workspace#39, #177 follow-up, merged 2026-11-03); 2026-11-02 (design tokens and switchable themes — #95, merged 2026-11-03); 2026-11-03 (fix round after the live comparison: orange brand primary, heading font on player pages only, full-bleed auth pages); 2026-11-03 (explorer favourites are copies — #225, branch `claude/explorer-favourite-copies-225`, not merged); 2026-11-03 (explorer filter: display / form configuration — #226, merged 2026-11-04); 2026-11-03 (open form without the type overview card — #227, merged 2026-11-04)
**Source scan:** `docs/reports/web-app-scan-2026-09-18.md`

## Stack

- React 18 + TypeScript, bootstrapped with **Create React App** (`react-scripts` 5.0.1) —
  not Vite, not Next.js.
- Routing: `react-router-dom` v7. Since #30 (branch `claude/admin-ia-30`) every route is an entry of the
  **route-meta table** `src/routes/routeTable.ts` and `src/routes/AppRoutes.tsx` builds the `Routes` from it
  (see [Routes, layouts and the admin sidebar](#routes-layouts-and-the-admin-sidebar)); `src/App.tsx` only
  maps each route id to its page. Since #109
  `App` mounts a **data router** (`createBrowserRouter` with one catch-all route around those `<Routes>`,
  `RouterProvider`) instead of `BrowserRouter`, because `useBlocker` (the form wizard's leave guard) only
  works inside one. Tests that mock `react-router-dom` or use a `MemoryRouter` still work: the guard
  skips `useBlocker` without a data router (`hooks/useLeaveGuard.tsx`).
- Styling: Tailwind CSS utility classes only. Fluent UI (`@fluentui/react-components`)
  was removed 2026-10-08 (KNG-71): only its provider was used. Shared component classes in
  `src/index.css`: `.btn` (`inline-flex`, `gap-2`; an icon's own `mx` margin is dropped under it) with
  `.btn-primary` / `-secondary` / `-tertiary` / `-danger` / `-cta`, `.panel`, `.input`, `.field-error`. Every colour
  is a theme token (see [Design tokens and themes](#design-tokens-and-themes), #95, merged 2026-11-03). `@tailwindcss/forms` is **not** installed: a field written `rounded-md border-gray-300 …` gets its
  1px border from a zero-specificity base rule in `index.css` (#38); `src/__tests__/tailwindStyles.test.ts` compiles
  the CSS and checks these.
- Drag-and-drop: `@dnd-kit/*` (used in `FormWizard`, `FormConfigBuilder`,
  `DisplayConfigBuilder` for reorderable steps/sections/fields).
- Icons: `lucide-react`.
- Reactive error bus: `rxjs` — a single `Subject`-like `logging.errorHandler` used to
  surface toast-style errors app-wide (`src/components/ToastRegion.tsx`, mounted in `App.tsx`). Every other toast goes
  through `toast.success/info/warning/error()` (`src/utils/toast.ts`, #177 link 1, general since #33); see
  [Feedback: toasts, dialogs and confirms](#feedback-toasts-dialogs-and-confirms).
- No Redux/Zustand/MobX — state is local `useState`/`useEffect` plus one React Context
  (`AuthContext`) for auth, plus a small manual in-memory cache in
  `hooks/useEntityMetadata.ts` (module-level `metadataBundleCache` /
  `metadataBundlePromise`, not React state).
- Testing: Jest + React Testing Library (`react-scripts test`), 38 `*.test.ts(x)` files;
  Cypress for e2e (2 specs: `hello-world.cy.ts`, `registration.cy.ts`).

## Design tokens and themes

_Added 2026-11-02 for PandiO/knk-workspace#95 (rebrand phase 1), knk-web-app branch `claude/design-tokens-95` on
`main` `1c9524d`; merged 2026-11-03. How to compare the themes: [design-themes-comparison.md](../guides/design-themes-comparison.md)._

- **Tokens** live in `src/theme/tokens.css` (imported in `src/index.tsx` before `index.css`) as `"R G B"` CSS
  variables, one block per theme under `:root[data-theme="current" | "brand" | "proposal"]`; a bare `:root` is
  `current`. Two layers:
  - Neutral ramps `--gray-50…950` and `--slate-50…950`. `tailwind.config.js` maps Tailwind's `gray` and `slate` to
    them, so all ~2,600 gray/slate classes follow the theme without edits (Tailwind's own values in `current`).
  - Semantic tokens `--color-*`, Tailwind keys: `primary` (`DEFAULT`, `dark` hover, `light` icons only, `fg`; as text,
    border, ring or divide it reads `--color-primary-text`, `-text-dark` and `-line` through Tailwind's `textColor` /
    `borderColor` / `ringColor` / `divideColor`, because the `brand` fill orange is too light for text on white), `cta`
    (`DEFAULT`, `dark`, `fg`), `canvas` (page), `surface` (`DEFAULT`, `alt`, `hover`), `fg` (text), `muted`
    (secondary text), `line` (decorative borders), `field` (form field borders, 3:1), `focus` (rings), `backdrop`
    (`DEFAULT`, `fg`: behind the auth cards), `nav` (`DEFAULT`, `fg`, `muted`, `hover`, `line`, `accent`, `focus`; `--color-nav-action*` colours a `.btn-primary`
    inside the bar), and
    `danger` / `success` / `warning` / `info`, each with `DEFAULT` (text/icon/filled), `strong` (text on the tints),
    `soft` (alert background), `muted` (badge background), `line` (alert border) and `fg` (text on the filled colour;
    not for info). The key `primary` kept its name, so its ~580 uses switch with no component edit.
  - Fonts: `--font-body` (Tailwind `font-sans`, the body) and `--font-display` (Tailwind `font-display`): `h1` on
    player-facing pages only, no faux bold. A player-facing page calls `usePublicSurface()` (`src/theme/surface.ts`),
    which sets `data-surface="public"` on `<html>` while it is mounted; admin pages and the nav title keep the body
    font (developer's rule 2026-11-03; the brand guide sets no such limit). `current` keeps `'Inter', sans-serif` (Inter is never loaded: the Google `@import` in
    `index.css` comes after other rules, so the system sans renders, as before). Lato 2.015 and Cinzel are
    self-hosted under the OFL in `src/theme/fonts/` and only downloaded when a theme uses them. `brand` uses the
    Enchanted Land **demo** (personal-use licence, readme kept alongside; a webfont licence is needed once the
    project earns anything) with a `unicode-range` of the characters the demo draws, so its empty punctuation and
    accent glyphs fall back to Lato (guide § 2).
- **Switching:** `src/theme/themes.ts` (`THEMES`, `resolveInitialTheme`, `applyTheme`, `selectTheme`,
  `useActiveTheme`, `themePickerVisible`). `index.tsx` applies the theme before the first render. Order: `?theme=`
  (kept per tab in sessionStorage) → the picker's choice (localStorage `knk.theme`) → `current`; storage access is in
  try/catch. The switcher is `src/theme/ThemeSwitcher.tsx`, a cogwheel menu button with `menuitemradio`
  items, for every visitor (2026-11-04): `variant="nav"` in `Navigation.tsx` left of the account menu, and
  `variant="floating"` fixed top-right in `App.tsx` when logged out. `REACT_APP_THEME_PICKER=off` hides it
  (`themePickerVisible()`).
- **Contrast:** `src/theme/__tests__/contrast.test.ts` parses `tokens.css` and checks every text/background pair
  (4.5:1) and UI pair (field border, focus ring, nav underline, icons: 3:1) in every theme, plus that every theme
  defines the same tokens. A failing pair fails `npm run test:ci`.
- **Full-bleed public layout:** `.public-full-bleed` (auth pages' `<main>`, the landing root) is fixed to the
  window in `brand` and `proposal`, so the dark backdrop fills it; `current` keeps the padded layout.
- **Accessibility base rules** in `index.css` (all themes): a 2px `--color-focus` ring on every focused text field
  (specificity 0,1,1: it loses to a field's own `focus:ring-*`); `--color-field` on `border-gray-300` /
  `border-slate-300` fields; `--color-danger` (and a 1px width) on `border-red-300` fields; `.field-error` puts an
  alert icon (CSS mask) before a field's error text, so danger is never colour alone.
- **Migration tooling:** `scripts/codemods/tokens-95.js` swaps raw classes for tokens one for one (blue-600 →
  primary, red-600 → danger, gray-900 → fg, bg-white → surface, text-gray-400 → muted, …; `--sweep-only` does just
  the text-gray-400 sweep). It is idempotent: after merging a branch that still has raw classes, run it on the changed
  files. `npm run lint:colors` (`scripts/report-raw-colors.js`) counts raw palette classes per file against
  `scripts/raw-colors-baseline.json` and reports files that gained some (exit 0 unless given `--strict`). The same
  check runs in `npm run test:ci` (`src/__tests__/rawColorsBaseline.test.ts`, #263): a file over its baseline fails
  the tests, so fix it with the tokens rather than raising the baseline. `test:ci` also runs in the `Build and test`
  workflow on every push and pull request ([CI guide](../guides/developer/ci.md)).
  Migrated and unmigrated screens: guide § 5.
- **Reduced motion:** `hooks/usePrefersReducedMotion.ts` follows `prefers-reduced-motion: reduce` (live, without a
  reload). The landing page's `components/Slideshow.tsx` uses it: a change fades the shown image out to black and then
  the next one in (1250 ms each, same easing; the next image is preloaded and the shown one stays until it has
  loaded), and with reduced motion it swaps images without fades (#258). Slides are rendered in index order so React
  never moves a slide's node during its fade (a moved node drops its CSS transition).

## Feedback: toasts, dialogs and confirms

PandiO/knk-workspace#33 (chain 2 link W2; merged 2026-11-12 in `main` `1371951`; smoke test not run). Three primitives; use them instead of
building an overlay or a status banner by hand. **Rule for new code:** a new overlay is a `Dialog`; success after a
save or delete is a toast, not a `FeedbackModal`; every delete asks through `useConfirm` with `danger: true` (and
`confirmWithReason` when the audit log needs a reason).

| Need | Use | Where |
|---|---|---|
| News that needs no answer ("Town saved", "Copied", a change with Undo) | `toast.success/info/warning/error(message, { action?, durationMs? })` | `utils/toast.ts` → `components/ToastRegion.tsx` |
| A yes/no question, a delete | `const [confirm, confirmModal, confirmWithReason] = useConfirm()` | `hooks/useConfirm.tsx` → `components/ConfirmDialog.tsx` |
| A question that needs a reason for the audit log (MOD-2, #119) | `confirmWithReason({ …, reason: { hint, required?, minLength? } })` → the trimmed reason or `null` | same |
| A message the user must read (an error with the API's reason) | `FeedbackModal` | `components/FeedbackModal.tsx` |
| Anything else in an overlay: a form, an editor, a picker, a details drawer | `<Dialog>` | `components/Dialog.tsx` |

- **`Dialog`**: `role="dialog"` (or `alertdialog` for a question) with `aria-modal`, `aria-labelledby` (its `title`)
  and `aria-describedby` (its `description`). Focus moves in when it opens (`initialFocusRef`, else
  `[data-autofocus]`, else the body's first field, else the footer's first button), Tab and Shift+Tab stay inside, focus
  returns to the opener when it closes. Escape and the × close it; a backdrop click only with `closeOnBackdrop` (on for
  messages, questions and drawers; off for forms, editors and pickers, so a stray click keeps what was typed);
  `dismissible={false}` turns all three off while something saves. Nested dialogs (a child form's error) work: only the
  innermost reacts to Escape and keeps focus. Rendered in a portal on `<body>` at `z-[60]` (above the nav, below the
  toasts at `z-[100]`), page scroll locked. Header (title, description, optional icon, ×), a scrolling body and an
  optional footer that stays visible; `size` `sm`…`6xl`/`full`, `placement="right"` for a drawer. Theme tokens only;
  with the page background on (#231) its surface stays solid (`pageBackground.css` keeps `[aria-modal]` opaque).
- **Confirm**: `danger` makes the action red (`btn-danger`) and starts focus on Cancel; otherwise focus starts on the
  action. Escape, the × and a click outside answer no; with a reason field a click outside does nothing (the text would
  be lost). The reason field has a tied label, `aria-required`, and on an empty submit `aria-invalid` plus a
  `role="alert"` message, focus back in the field. The leave-form questions (`useLeaveGuard`, `FormCancelAction`) are
  danger. A child form (`ChildFormModal`) asks the same "Leave this form?" through `useConfirm` before Escape or the ×
  closes it when its wizard reports unsaved changes (`onDirtyChange`, the value snapshot of `formValuesSnapshot`);
  without changes it closes at once (LW2-2, developer's decision 2026-11-06). The question's text is in
  `utils/forms/leaveFormQuestion.ts`.
- **Toasts**: one per kind and text (a repeat restarts its timer), at most 4, in a polite `role="status"` region; each
  names its kind for screen readers ("Success: …"). 5 s (warning and error 8 s, with an action at least 10 s,
  `durationMs: null` until dismissed); the timer waits while the pointer or focus is on the toast. A plain
  `toast.error(message)` still goes through `logging.errorHandler` (≈45 call sites send there); with options it goes
  straight to the region. Success after a save or delete is a toast now, not a `FeedbackModal` with `autoCloseMs`
  (entity setup page, form/display builders, the wizard's Save Draft, the form submit since #177).
- **Overlays on the Dialog** (all 16 the 2026-10-25 re-evaluation counted): `FeedbackModal`, `ChildFormModal`,
  `JoinEntityFormModal`, `ScanConflictModal`, `DomainWorldPromptModal`, `CreatedEntitiesPrompt`,
  `ConfigurationImportPanel`, `MaterialMergeTargetDialog`, both builders' `FieldEditor` and `Reusable*Selector`
  (cards are `aria-pressed` buttons), the Invitations redemptions drawer and the telemetry event drawer. Not dialogs
  on purpose: the dashboard explorer's narrow-screen drawer (navigation below the bar), the theme and account
  popovers, and the inline confirmation panels with `role="dialog"` in the page flow (data deletion, privacy
  preview, statistics group change, the world-task busy check in `WorldBoundFieldRenderer`).
- The configuration tables' ⋯ menus give focus back to their trigger before an item runs, so a confirm opened from
  the menu returns focus to ⋯ instead of the top of the page.
- Tests: `components/__tests__/Dialog.test.tsx`, `overlaysOnDialog.test.tsx`, `ToastRegion.test.tsx`,
  `hooks/__tests__/useConfirm.test.tsx`. No jest-axe in the repo; roles, names, focus and keys are checked one by one.

## Data and format primitives: tables, pager, formatting, fields, settings pages

PandiO/knk-workspace#187 (chain 2 link W3; merged 2026-11-12 in `main` `1371951`; smoke test not run). Use these instead
of a hand-rolled `<table>`, pager, `toLocaleString`, unlabelled input or settings header.

| Need | Use | Where |
|---|---|---|
| A list of rows (sortable headers, rows that open a page) | `<DataTable columns rows rowKey sort onSortChange rowHref onRowClick …>` | `components/DataTable.tsx` |
| Pages under a list | `<Pager page pageSize totalCount onPageChange label? noun?>` | `components/Pager.tsx` |
| A server-paged entity list (dashboard, wizard pickers) | `PagedEntityTable` (fetching, query modes, selection, pinned rows) — draws through `DataTable`/`Pager` | `components/PagedEntityTable/` |
| A date, time or number on screen | `formatDateTime`, `formatDate`, `formatTime`, `formatNumber`, `formatPercent`, `numberFormat`; `parseApiDate` | `utils/format.ts` |
| A labelled control | `<Field label hint? error? required? inline? id?>` around the control (or a render function) | `components/Field.tsx` |
| A page of settings saved with one Save | `<SettingsPage …>` + `<SettingsSection title changed?>` | `components/SettingsPage.tsx` |

- **`DataTable`** (built from #39's work in `PagedEntityTable`, which now renders through it): with `rowHref` the
  link column (`linkColumn`, default the first) is a real `<a href>` — middle-click, Ctrl/Cmd-click and the keyboard
  work; a plain click on the link or anywhere on the row calls `onRowClick` (the caller navigates in the app);
  Ctrl/Cmd-click or middle-click on the row opens a new tab; controls inside a linked row keep their own clicks. A
  sortable header is a `<button>` inside `<th aria-sort>`; `nextSort(current, key)` gives asc → desc → off. Also
  `sections` with a heading row (the pickers' "Created in this form"), `leading`/`rowLeading` elements, `isRowSelected`
  styling, a `rowActions` column (sr-only "Actions" header), `empty`, `loading`, `caption` (the table's accessible
  name) and `density="compact"` for lists inside cards. Wide tables scroll inside their own container.
- **`Pager`**: a `<nav aria-label>` (default "Pagination") with "Showing a to b of n {noun}" from `sm` up, Previous,
  "Page x of y" (`aria-live="polite"`) and Next; numbers through `formatNumber`. The caller decides when to show it.
- **`utils/format.ts`, one locale policy**: numbers in the viewer's browser locale (`NUMBER_LOCALE` undefined:
  `1,234,567` in English, `1.234.567` in Dutch; LW3-1, developer's decision 2026-11-06, was a fixed `en-US`; tests pin
  `en-US` through `setNumberLocale` in `setupTests.ts`); dates and times in the viewer's own locale and zone
  (`DATE_LOCALE` undefined); missing or
  unreadable values as `-`. API dates without a zone (a MySQL `DATETIME`, `2026-11-05T20:52:02`) are **UTC**:
  `parseApiDate`/`parseUtc` read them so (was `parseUtc` in `components/currency/BalanceLedgerTable.tsx`); `new Date(…)`
  on them shifts by the UTC offset. A bare `2026-11-05` is a calendar date (`formatDate` shows that day). The six local
  `new Intl.NumberFormat('en-US')` constants (currency pages, retention, transactions) use the shared `numberFormat`.
  Call sites with their own `toLocaleString('en-US')` (statistics, roads, lootbox counts, siege) are not on it yet.
  The detail page's `DisplayField.formatValue` and template variables (`useTemplateParser`) show ISO date-times as a
  date and time whatever the field type (configurations often have none or `String`), numbers for `Integer`/`Number`/
  `Decimal`. Account → Transactions shows local time instead of raw UTC text.
- **`Field`**: generated id (`useId`) or a fixed `id`, `htmlFor`, `aria-describedby` for hint and error (keeps the
  control's own), `aria-invalid`, `required` with an `aria-hidden` star, the error as `role="alert"`; `inline` puts a
  checkbox before its label. `.input` has no padding of its own: add `px-3 py-2` (as the migrated pages do).
- **`SettingsPage`** (SET-4, SET-7): a sticky header (`top-16`, under the nav; solid with the page background on)
  with the title, "Last saved {when} by {who}", "n unsaved changes" (`aria-live`), optional Reload, Discard and
  Save (n). The page owns its values and passes `dirtyCount` (Siege's pattern: count against the saved values, mark
  changed fields, send only those); `canSave={false}` while a value is invalid. `onSave` may resolve a message: success
  is `toast.success(message ?? "Saved n changes.")`; a throw keeps the changes and shows `saveErrorMessage(error)`
  (default the API's reason) in the header as `role="alert"`. With changes: in-app navigation (links, Back/Forward) asks
  "Leave without saving?" through `useConfirm` (danger, focus on Stay; `NavigationBlocker`/`useHasDataRouter`
  exported by `hooks/useLeaveGuard.tsx`, so it needs App's data router), a reload or tab close gets the browser's
  question, Discard and Reload ask first. `loadError` replaces the form with a message and Retry (nothing can be saved
  over the real values, SET-1). On a phone the header drops the description and shows Reload as an icon.
  `SettingsSection` is a titled card with an optional "Changed" mark.
- **Migrated (first set):** dashboard and wizard pickers (`PagedEntityTable`); Player moderation (four tables, the
  All-players pager, filters on `Field`, dates/numbers, tokens; header buttons wrap at phone width); Game Settings
  (dirty state per group and per world, Discard, labels on `Field`, worlds table on `DataTable`; the data-retention
  card still saves on its own); Siege configuration; the detail page's values; the wizard's Integer/Decimal/DateTime
  inputs now have the id their label points at. **Left for later:** Lootbox Settings tab, Currency policy and Roads on
  the shell (#26; the lootbox tab loses edits on a tab switch, so it needs the shell inside a tab), the detail page's
  layout and child tables (#188/#189), player profile (#119), the other hand-rolled tables and pagers (Balance log,
  currency alerts, email log, invitations, location retention, lootbox drop log/tokens, discovery, roads), the
  remaining `toLocale*` calls and unlabelled labels (the wizard's list/object field groups, account pages).
- Tests: `components/__tests__/{DataTable,Field,SettingsPage}.test.tsx`, `utils/__tests__/format.test.ts`,
  `DisplayWizard/__tests__/DisplayField.format.test.tsx`, `FormWizard/__tests__/FieldRenderers.labels.test.tsx`, and
  the page tests of Game Settings, Siege and moderation.

## High-level shape

The app is **metadata/config-driven** rather than having one hand-built page per
entity. Two parallel generic engines carry most of the CRUD surface:

1. **Form engine** (`FormWizard/`, `FormConfigBuilder/`) — renders a create/edit form
   for any backend entity from a `FormConfigurationDto` fetched from the API
   (`formConfigClient`), rather than a hardcoded form-per-entity. `FormConfigBuilder`
   is the admin UI for authoring those configurations.
   **Boolean fields** (KNG-26, KNG-53): a checkbox can't show "no value", so every path that seeds
   step data (new form, resumed draft, edit form, child/join prefill, a field shown by a condition)
   holds a real boolean - the authored default, else `false` - via `seededFormFieldValue`
   (`utils/forms/formFieldDefaultValue.ts`). Required means "value is present", so an unchecked box
   (`false`) passes; "must be ticked" would be a separate validation rule.
   **Child forms** (KNG-133, decision D1 = A; merged to `main` 2026-10-17 with the form wizard chain,
   branch `claude/wonderful-darwin-u39k1o`): "Create New" / "Edit instance" on a relationship field opens `ChildFormModal` with a nested
   `FormWizard`. When the child completes, its entity is saved at once through its own create/update
   API for every **List** field (owned collection or not) and every **Object** field except a single
   **Location**, which stays an embedded value saved with its parent
   (`utils/forms/childPersistence.ts` → `shouldPersistChildOnComplete`). Many-to-many steps save
   created entities themselves (`ManyToManyRelationshipEditor.handleCreateRelatedEntity`).
   `normalizeFormSubmission` sends relationships as ids and throws `UnsavedRelationshipValueError`
   (naming the field) for an id-less entity in an Object (not Location) or List field, so nothing is
   dropped silently; the wizard shows the message and doesn't mark the progress Completed.
   **Edit instance** (KNG-134): `handleOpenChildForm` hands the child the instance the
   parent holds (`initialValues`) and whether its edits live only in the parent (`editingInMemory`:
   a child not saved on completion, i.e. an embedded Location). Without an id the child form is
   seeded from it (title "Edit …"); with an id and `editingInMemory` the nested `FormWizard` loads
   from the database and lays the held values over it (`overlayFieldValues`); otherwise the database
   is the source (`utils/forms/childEditSeed.ts`). "Replace via Minecraft" keeps an existing Location
   id, and a world task a child inherits onto its first field spreads an object result over the
   child's fields of the same name (`utils/forms/worldTaskFieldValue.ts`). `ListField` keys, removes
   and edits items by position/client key, not by id (`utils/forms/listItemKeys.ts`).
   **List fields in edit mode** (KNG-135): `resolveObjectFieldValueForEdit`
   (`utils/forms/objectFieldEditValue.ts`) also pairs List relationship fields across `XIds` / `Xs`:
   an `XIds`-authored field takes the DTO's `Xs` objects (bare ids become `{ id }`), an `Xs`-authored
   field falls back to `{ id }`s from `XIds`. The edit load and Edit-instance seeding both use it.
   **List validation** (KNG-164): `validateField` sends List fields to
   `utils/forms/listFieldValidation.ts`: a required List needs at least one item, `minSelection` /
   `maxSelection` are enforced (null or 0 = no limit), an owned child collection is skipped until its
   parent is saved. **Step header** (KNG-137, KNG-168): `FormWizard/WizardStepHeader.tsx` shows
   step names in the progress bar (truncated, hidden below `md`) and keeps the step name as the
   title in edit mode under a small "Edit {entity}" heading; Boolean fields render their description.
   A strip with more steps than fit scrolls sideways (current step kept in view, ‹ › only on a side
   that hides steps, `stepStripOverflow`). Below `sm` a compact "Step 3 of 9 · Name" label and bar
   replace the circles; the label is a disclosure button listing every step (done / current / to do),
   closed again on a step change. **Clickable steps** (PandiO/knk-workspace#68, on `claude/issues-68-88-readiness-wapo57`, not merged): with `onStepClick` the steps of `WizardStepProgress` and of the compact list are buttons (`aria-current="step"` on the current one). `FormWizard.handleStepClick` goes back without a check (`goToEarlierStep`); forward, `jumpForward` checks the current step and every visible step up to the target with the checks of Next (`validateField`, completion and entry conditions, `runValidationsForStep` in quiet mode, `manyToManyEntryIssues`) and stops at the first step that fails, in a `FeedbackModal` with "Go to <step>". `utils/forms/stepJumpCheck.ts` classifies a rule result: blocking stops, a warning or a rule that could not run (`metadata.failureReason`, e.g. `PluginUnreachable`) is only listed. A pre-filled form (edit mode, resumed draft) runs the rules of every visible step once after loading, in quiet mode: results are stored per field id, the current step's messages are untouched. **Step conditions** (KNG-186, #88): `advance` runs the current step's `Completion` conditions and, since #88, the next step's `Entry` conditions (`utils/forms/stepConditions.ts` `firstFailedStepCondition`, over `ConditionEvaluator.evaluateConditions`) unless the condition's `isActive` is explicitly `false`; a failure is shown in the banner, above the Next button and in a toast. Until 2026-10-23 the API sent `false` for every condition, so none ever ran. The builder authors them in `FormConfigBuilder/StepConditionBuilder.tsx` (rows ↔ `ParsedStepCondition` JSON, operators from `STEP_CONDITION_OPERATORS`; JSON in another shape is edited as text); `FormConfigBuilder.publishProblem` refuses a Completion condition without a message. `FormConfigurationDto.isActive` is gone (the API never had the column; `parentFormFields.ts` filters on `isDefault` only). **Validation result log** (KNG-269): Next validates a step's rule-bearing fields with one `validate-batch` request that names the subject (`entityName` + `entityId` in edit mode, else `FormSubmissionProgress` + the saved draft id; `FormWizard.validationSubject`), so the API can answer a rule from its log of the last run. A result with `metadata.fromCache` shows "checked … ago" (`utils/forms/validationResultAge.ts`) and a **Re-check** button, which re-runs that field with `force: true`; the debounced per-field run on change keeps using `validate`.
   **World-task values** (KNG-167): a capture spread over a child's fields keeps a Name the admin
   typed (`utils/forms/worldTaskFieldValue.ts`); rule placeholders built from an Object field use
   the entity's name, not the object (`utils/placeholderExtraction.ts`, KNG-173).
   **Form session registry** (KNG-136): the exported `FormWizard` wraps its body in a
   `FormSessionScope` (`contexts/FormSessionContext.tsx`). The first wizard with no session above it
   (normally `FormWizardPage`'s) owns the registry for its lifetime; wizards nested in
   `ChildFormModal`/`JoinEntityFormModal` join it and add their entity name to the form path.
   `handleChildFormComplete` and `ManyToManyRelationshipEditor.handleCreateRelatedEntity` register
   what a child saved (`useFormSession().register`: type, id or a concept key for an embedded value,
   display DTO, origin form path + field, `created`/`updated`, order). `ObjectField`/`ListField` get
   the created, non-embedded entries of their `objectType` as `pinnedRows` plus a `refreshKey`
   (`hooks/useSessionPinnedRows.ts`; Locations are never pinned). The relation picker (below, #191) and the full table
   behind its "Open full table" (`PagedEntityTable`) show them in a "Created in this form" section with a New badge, filtered by the search term and the query's
   filters on the client and de-duplicated against the page (`utils/forms/sessionPinnedRows.ts`);
   rows are keyed and selected by id (`isSameSelection`), not by array index.
   **What a form created, and cancelling it** (KNG-162): the root wizard of a session
   (`formPath.length === 1`, no `parentProgressId`; `hooks/useCreatedEntitiesProvenance.ts`) sends
   `createdEntitiesJson` with every progress save (`utils/forms/createdEntities.ts`: type, id, label
   fields, origin, creation order); resuming that draft seeds the registry (`seed()`), so pickers pin
   the entities again. `FormWizardPage` wraps the wizard in `FormSessionRoot` (a registry without a
   form-path entry) with `FormWizard/FormCancelAction.tsx` ("Cancel form", in the wizard's footer since #109); deleting a draft from
   Saved Progress reads the summary's `createdEntitiesJson`. Both show `CreatedEntitiesPrompt` (Keep =
   default, Delete); Delete runs `utils/forms/deleteCreatedEntities.ts`: newest first, the API's
   `entity-references` check (entities still pending in the run ignored), then the entity's normal
   delete (`getDeleteFunctionForEntity`); in use / 409 = skipped and reported. Cancel never deletes
   the draft; nothing is deleted automatically. Drafts and workflow sessions belong to the logged-in
   user (#186): the web app sends no user id (the `userId = '1'` constant and the `userId` props of
   `FormWizard`, `ChildFormModal`, `JoinEntityFormModal`, `ManyToManyRelationshipEditor` are gone); the
   API takes the owner from the token. Saved Progress asks for the caller's own drafts
   (`formSubmissionClient.getByEntityTypeName` sends `mine=true`); the relationship-drafts list
   (`useRelationshipDrafts`) still shows every staff member's drafts with their owner's name.
   **Footer, unsaved changes and validation** (#109): the wizard's actions sit in a footer that sticks
   to the bottom of the window (`data-testid="wizard-footer"`; the card has no `overflow-hidden`, which
   would stop `sticky`): the page's Cancel (`footerStart` slot), Previous, Save Draft, in edit mode
   **Save changes** on every step but the last, and Next/Submit. The wizard reports **unsaved changes**
   through `onDirtyChange`: the values of every step (hidden-stash values included) compared with a
   snapshot (`utils/forms/formValuesSnapshot.ts`; '' / null / undefined / [] are the same empty value,
   a number equals its text), taken just before the first change (in edit mode: the loaded entity) and
   re-taken only by **Save Draft** and a successful Submit / Save changes; the progress save behind Next
   does not (link 5 fix round, 2026-10-27: typing and clearing is no change, step 1's values still count
   on step 2). A mousedown on a footer button keeps the focus in the field, so a blur message can't
   move the button away under the click. `FormWizardPage` feeds it to `hooks/useLeaveGuard.tsx`: with unsaved changes
   a link, Back/Forward or any URL change asks "Leave this form?" (Stay / Leave form, `useBlocker`), a
   reload or closing the tab gets the browser's question (`beforeunload`), and the breadcrumb asks through
   `confirmLeave`; a successful submit and an already-confirmed Cancel call `allowLeave`. Cancel leaves
   at once when nothing was created or changed (the same value comparison). A field is validated on **blur** (message shown or
   cleared); its own validations run (`utils/forms/fieldRuleValidation.ts`: MinLength, MaxLength,
   Range, Regex, Email; Custom stays on the API). A refused Next/Save shows `FormWizard/FormErrorSummary.tsx`
   at the top of the fields, which takes the focus; each item links to (and focuses) its field
   (`wizard-field-{fieldName}` boxes). A failed completion condition or blocking rule is also shown on the
   form. **Save changes** checks the current step as Next does, then every other visible step
   (`findInvalidOtherStep`); a step that would refuse the save is shown with its messages, else the entity
   is saved through the same submit path as Submit. **String fields** are a one-line `<input>` tied to
   their label; a text area for settings `"multiline": true` (field editor toggle "Multi-line text"),
   for fields named …Description / …Lore without that setting, and for a value that already holds a line
   break (`utils/forms/stringFieldMultiline.ts`).
   **Submit and the way back** (#177 link 1, #58): a form opened from another page carries
   `?returnTo=` (`utils/returnTo.ts`: `editFormPath`/`newFormPath`/`withReturnTo`, same-origin paths
   only via `sanitizeReturnTo`). On the last step the wizard saves the progress as `InProgress`, then
   **awaits** `onComplete` (the page's `handleComplete`, which saves the entity and returns
   `true`/`false`), and marks the progress `Completed` only after a successful save, then calls
   `onCompleted`. A refused save (false or a throw) leaves the draft `InProgress`, so the cleanup of
   completed progress never deletes a draft whose entity doesn't exist. During that window Submit reads
   "Submitting…" and is disabled (a ref guards re-entry), Previous / Save Draft / the page's Cancel are
   disabled (`onSubmittingChange`), and a "Saving {Type}…" line shows. After `onCompleted` the page goes
   straight to the parent display page (child creation), else `returnTo`, else `/dashboard/{type}`,
   with a success toast ("{Type} created." / "updated."); the old 3 s success modal is gone. Cancel
   (`handleLeaveForm`) goes to the parent display page, else `returnTo`, else stays on the Entity setup
   page (`/forms`).
   **Open form** (#177 link 2): while the wizard is open, `FormWizardPage` hides the
   `ObjectTypeExplorer` and shows a breadcrumb (`components/Breadcrumbs.tsx`) built by
   `utils/breadcrumbs.ts` `formTrail` from `returnTo` ("Dashboard › Town › Edit Cinix"; without
   `returnTo`: "Entity setup › Town › New Town"). The trail is plain `{label, to?}[]` data; inside the admin
   layout it starts with the group crumb ("Content", #30). Since #30 the configuration lists show
   "Dashboard › Town › Entity setup" (`entitySetupTrail`, LW1-2); `useEntityLabel` fetches the edited entity's name (else "#id"). A
   crumb asks "Leave this form?" first when the form has unsaved changes (#109). The configuration lists keep the explorer.
   The type overview card (`FormWizard/EntityMetadataNavigator`: name, field count, "Fields") shows only on the
   configuration lists, not above an open form (#227); the breadcrumb then sits in the form card's centred column
   (`max-w-4xl mx-auto`, the same as `FormWizard`'s card), so both start at the same left edge.
   "New" (`?autoOpen=true`) on a type without a default form configuration shows "To create a new
   {Type}, this type needs a default form configuration" (#177 decision 3). The page title is
   **"Entity setup"** (route `/forms` unchanged, decision 4). It has **no nav link** since #197: it is opened
   with the dashboard's ⚙ on one type (or "All saved progress" in its "Drafts (n)" menu) and by URL; see
   **Navigation** below.
   `ChildFormModal` returns `false` from its `onComplete` on a failed child save for the same reason.
   **Export / import** (KNG-138): the form configuration list (`FormWizard/FormConfigurationTable.tsx`)
   has **Export JSON** per row (downloads the API's portable `knk-formconfig/1` file,
   `utils/forms/formConfigPortability.ts`) and **Import / Seeds**, which opens
   `FormWizard/FormConfigurationImportPanel.tsx`: choose a file or a bundled seed, the API dry-runs it,
   the result (problems, warnings, default handling) is shown, and Import is offered only after a
   passing dry run with the current "make default" choice. `formConfigClient.importConfiguration` /
   `importSeed` resolve with the result body on a 400/409 refusal instead of raising the global error
   toast. Deleting a form configuration (KNG-172) warns how many saved drafts go with it
   (`utils/forms/formConfigDeleteConfirm.ts`, from the API's `entity-references`); the API detaches its
   form sessions and removes its drafts, so only real uses (another form opening it as a sub-form)
   refuse the delete.
   **Display configurations** (merged 2026-10-22): `FormWizard/DisplayConfigurationTable.tsx` has the
   same **Export JSON** per row (`knk-displayconfig/1`, `utils/displayConfigPortability.ts`) and
   **Import / Seeds** (`FormWizard/DisplayConfigurationImportPanel.tsx`). Both import panels are thin
   wrappers around the shared `FormWizard/ConfigurationImportPanel.tsx` (dry run first, result shown,
   Import only after a passing dry run); the display one adds the draft option.
   `displayConfigClient.exportConfiguration` / `getSeeds` / `importConfiguration` / `importSeed`.
   **Catalog pickers on submit (KNG-195):** `normalizeFormSubmission` sends a
   `HybridMinecraftEnchantmentRefPicker`, and an Object picker on MinecraftMaterialRef/BlockRef/EnchantmentRef
   (which runs the hybrid search), as `{field}Id` + `{field}NamespaceKey`; a catalog row that isn't saved yet
   (id 0) goes by namespace key only, and the API creates the ref.
   **Confirmations and refusals** (KNG-169, KNG-82): no `window.confirm`/`alert` is left. Questions
   go through `hooks/useConfirm.tsx` (`const [confirm, confirmModal, confirmWithReason] = useConfirm()`,
   the `ConfirmDialog` since #33: an `alertdialog` with confirm/cancel labels, a red `danger` button and an
   optional reason field); the configuration tables
   hand a delete to the page, which asks once. A refused operation shows the API's reason
   (`utils/apiRefusalReason.ts`; the API's 409 names what still uses the item), never "please try
   again". A `FeedbackModal` without `onContinue` shows a single Close button.
   **Rule builder** (`FormConfigBuilder/ValidationRuleBuilder.tsx`): "Depends On Field" also lists
   the fields of the forms this one is opened from (`utils/forms/parentFormFields.ts`: default
   configurations with an owned-child List or M2M step of this entity, up to 3 levels); a dependency
   path then starts at that parent's entity. The filter does not use `isActive`, which the API never
   sets (KNG-186).
2. **Display engine** (`DisplayWizard/`, `DisplayConfigBuilder/`) — same pattern for
   read-only entity detail views, driven by `DisplayConfigurationDto`
   (`displayConfigClient`).

**Builders: draft, Publish, Duplicate, generate, preview** (`FormConfigBuilder/`, `DisplayConfigBuilder/`,
`components/configBuilder/`, `utils/configBuilder/`; PandiO/knk-workspace#71, merged 2026-11-12 in `main` `1371951`; smoke-tested by the developer 2026-11-11/12):
- **Opening** reads `GET {id}/builder` (`getBuilderState`): the working copy (saved draft, else the published version)
  and the published version. The toolbar (`BuilderToolbar`, sticky from `md`) says *New*, *Draft* (never published),
  *Published · changes not published* or *Published*, and "Unsaved changes." by value (a snapshot of the body Save
  sends, with step/section and field order as GUID arrays).
- **Save** stores the draft (`PUT {id}/draft`; the first Save of a new configuration `POST drafts`, then the route moves
  to `/edit/:id` without reloading) and stays; a toast says staff keep the published version. **Save and close** goes
  back to Entity setup. A draft only needs an entity and a name.
- **Publish…** runs the checks the old Save ran (steps, names, many-to-many, projection cycles), saves unsaved changes,
  then `PublishDialog` says what changes for staff (`summarizeFormPublish` / `summarizeDisplayPublish`: steps/sections
  and fields added, removed, changed, a rename, a new order, the default and the one it replaces, open wizard drafts that
  continue). Confirmed → `POST {id}/publish`, the builder reloads (new ids). A refusal stays in the dialog.
- **More**: *Generate from metadata…* (`ScaffoldDialog` on `DataTable` with selection; `planScaffold` sorts the type's
  metadata into values, links — a foreign key and its navigation are one — and collections, says what each becomes and
  what is left out and why; forms get a General and a Links step, displays Details, Related (the related record's name)
  and one collection section each; properties the configuration has are left out by default); *Duplicate…*
  (`DuplicateDialog`, the published version under a new name, opens the copy; off while never published or with unsaved
  changes); *Discard unpublished changes…* (danger confirm).
- **Preview** (toggle): next to the builder from `xl` (the list and editor stack until 1800 px), below it on a phone.
  `FormPreview` draws the steps with the wizard's `FieldRenderer` (step select, Back/Next) and keeps values on the page
  only — no progress, no world task, no Create New; display conditions are not applied (marked "Shown only when …").
  `DisplayPreview` draws `DisplaySection`s with clicks on buttons and links swallowed. Values: sample values
  (`previewData.ts`) or a real record picked with V6's `RelationPicker` and read with the type's own GET
  (`PreviewRecordSource`).
- **Leaving** with unsaved changes asks "Leave without saving?" (`useBuilderLeaveGuard`: the data router's blocker,
  `beforeunload`, the toolbar's Close), the `SettingsPage` question.
- **Access**: the routes stay behind `knk.admin.content` (W4); inside, Save, Save and close, Publish, Duplicate, Discard and
  Generate are disabled with "Requires knk.admin.content" (`useAllNodesGate`) when the node is missing.
- **Templates** ("Add from template") are copied into the working copy with new GUIDs; the builder no longer calls the
  API's add-from-template, which wrote into the published version.
- **Entity setup** lists never-published forms (`getByEntityTypeName(entity, false, true)`) with a *Draft* badge: Use and
  Set Default are off and `?configId=` never opens one; published ones with saved changes show *Unpublished changes*
  (display: "+ unpublished changes"); both menus have *Duplicate*. Everything else (the wizard, "New with", child forms,
  pickers, `useRelationshipDrafts`) keeps asking without drafts and gets the published version.

**Dashboard as the CRUD hub** (`ObjectDashboard`, `/dashboard`; #177): the selected type is in the
URL as `/dashboard/:entityName` and bare `/dashboard` reopens the last viewed type from localStorage
`knk.dashboard.lastEntityType` (`utils/lastDashboardType.ts`, link 1). Next to the type's title:
**"New {Type}"** (`newFormPath(type, returnTo)`) and a cogwheel **"Configure {Type}"** to the type's
Entity setup page (`/forms/{type}`), its main way in since #197 (no nav link). Title and buttons share one flex row (items centred, `min-h-9`, buttons `h-9`);
the dashboard has `pt-6`, because the page wrapper's top padding is exactly the app header's height, so explorer, title
row and table start level and clear of the header (#195). "New {Type}" is also the empty state of the table
(`PagedEntityTable` `emptyState`, shown only without a search or filter). The explorer is one flat
list: types without a published default display configuration get a muted marker ("No display
configuration – set one up via ⚙", `ObjectTypeExplorer` `marked`), and for them View and the row
click are disabled with the same hint. Only the explorer's list scrolls (the sidebar column is `overflow: hidden` and
the explorer's `aside` is `min-h-0`; it used to show two scrollbars, #194). A star on each type toggles it as a
**favourite** (`ObjectTypeExplorer` `favourites`): favourites are listed first under "Favourites", sorted like the rest,
and stay in the full list below ("All entity types") at their usual place too: copies, so the list always holds every
type (#225; both copies are starred and highlighted when selected); they are kept per browser in localStorage `knk.dashboard.favouriteEntityTypes`
(`utils/dashboardFavourites.ts`; per account on the API can come later). The Entity setup page's explorer has no stars.
A **filter** button next to the sort toggle (`ObjectTypeExplorer` `filters`, #226) offers **Display configuration**
(the marker's rule: a published default display configuration) and **Form configuration** (at least one, from
`GET api/FormConfigurations/entity-names`), each a labelled select Any / Yes / No in a compact inline panel; set filters narrow favourites and the list alike and
are kept per page like the sort (localStorage `objectTypeExplorer.dashboard.filters`). A filter whose data hasn't
loaded (or failed) is neither offered nor applied; its stored choice is kept for the next load.
View opens `/display/{type}/{id}?returnTo=…`, Edit
`/forms/{type}/edit/{id}?returnTo=…`, except **User rows: Edit opens the player profile**
`/admin/users/{id}` (`utils/returnTo.ts` `entityEditPath`; the generic User form stays for create
until #72/#148).

**Table state in the URL** (#39, merged 2026-11-03): the dashboard drives
`PagedEntityTable` in **controlled mode** (`query` + `onQueryChange`); page, search, sort and filters are query
parameters of `/dashboard/{type}` (`utils/tableQueryParams.ts`: `?page=2&q=north&sort=name&dir=desc&f.CategoryId=4`,
defaults left out). A change replaces the history entry (Back leaves the type rather than stepping through pages);
picking another type opens its bare URL (page 1, no search). View, Edit and the row links build their `returnTo`
from the location, so a form or detail page comes back to the same page, search and sort. A page past the end (a
shared link, rows deleted) moves to the last page. Without `query` the table keeps its own state, as the form
wizard's pickers (`FieldRenderers`, the Minecraft pickers) do; they never touch the URL, so the unsaved-changes guard
(which blocks query changes) is unaffected. **Rows as links** (`rowHref`): the first cell is an `<a href>` to the
detail page (middle-click, Ctrl/Cmd-click, keyboard), a plain click still goes through the app's navigation, and a
Ctrl-click or middle-click elsewhere on the row opens a new tab; only for types whose View works, and not while a row
click selects (the wizard pickers). Sortable headers are buttons (keyboard) with `aria-sort`.

**Checkbox selection and Export CSV** (#205 export part, merged 2026-11-12; since #280 AM3, merged 2026-11-13, the rows come from `POST api/Dashboard/export`, see the bullet **Export** below and [the access model section](#dashboard-access-model-in-the-web-app-pandioknk-workspace280-am3-205-bulk-delete)):
- **Selection:** the dashboard passes `selectionConfig={{ mode: 'multiple' }}` with `selectionStyle="checkbox"`, so
  `DataTable` draws a checkbox column (`selection` prop) and a header box for the rows shown (mixed when some are).
  Clicks in that cell never reach the row, so the row link, the row click and middle-click keep working. The pickers
  keep row-click selection (`selectionStyle` `row`, the default). `ObjectDashboard` holds the selected rows across
  pages and searches of the type; changing the type clears them, and a single Delete removes its row.
- **Bulk bar:** `PagedEntityTable`'s `renderSelectionBar` hands `ObjectDashboard/DashboardSelectionBar` the
  selection, the table's columns in table order (`effectiveColumns`), the query and the total. The bar shows
  "n selected" with Clear, or "None selected · Export takes all N results", and **Export CSV**. Its `actions` slot
  before Export holds AM3's "Delete (n)".
- **Export (AM3):** `utils/tableExport.ts` `readExportRows` makes **one** `POST api/Dashboard/export`
  (`apiClients/dashboardClient.ts`, 120 s timeout, LAM3-9): with a selection the ids without the query, then reorders
  the answer into **tick order** with current values (LV2-3, LAM3-4); with none the search in the table's sort. The cap
  is 10,000 rows (`EXPORT_ROW_LIMIT`, the endpoint's): the bar says so beforehand, and a toast afterwards (`truncated`).
  The button shows "Exporting N…"; Cancel drops the answer (the server still reads and audits it). V2's paging reader
  `readSearchRows` (pages of 100 through the type's list API) is gone.
- **CSV:** `buildTableCsv` writes the column labels, then each row's cell text (`utils/tableCells.tsx` `cellText`):
  a column's `render` read as text (`reactNodeToText`), Yes/No for booleans, an object's name, and empty for a
  missing value. `utils/csv.ts` does RFC 4180 quoting with CRLF, puts `'` before formula-like texts
  (`=`, `+`, `@`, `-` not followed by a number), and saves UTF-8 with a BOM as `<Type>-<yyyy-mm-dd>.csv`
  (local date, entity name).
- **Permission:** Export follows `useEntityAccess(meta).export` (the metadata's `actionNodes.export`: the area node and
  `knk.admin.export`); without it the button is disabled with "Requires …". The endpoint checks the same nodes and
  writes a `DashboardExport` audit entry.

**"Drafts (n)" and "New with"** (#177 follow-up): next to "New {Type}" a chevron lists the type's form
configurations other than the default ("New with"), and a "Drafts (n)" chip lists the caller's open drafts of the
type (Saved Progress without Completed/Abandoned, newest first; `hooks/useDashboardFormOptions.ts`,
`ObjectDashboard/DashboardHeaderMenu.tsx`). Both open the Entity setup page with `?configId=` / `?resume=` and
`returnTo` (`newFormWithConfigPath`, `resumeDraftPath`); `FormWizardPage` opens that configuration or draft once
its lists loaded (an unknown configuration shows an error toast and stays on the lists). The chip and chevron are
hidden when there is nothing to list; Saved Progress and the configuration lists stay on the Entity setup page.

**Entity setup at phone width** (#266): below `sm` the configuration lists' title and buttons stack and the buttons
wrap (`FormConfigurationTable`, `DisplayConfigurationTable`), as do the Default Table Columns row and the Saved
Progress rows; the tables scroll inside their card. A table's scroll box is `relative`, because an absolutely
positioned element without a positioned ancestor (the head's `sr-only` "Actions" label) is placed in page coordinates
and widens the whole page even inside an `overflow-x-auto` box; `.dashboard-content` (`ObjectDashboard.css`) is
`position: relative` for the same reason.

**Tabs in the URL** (#39): `/admin/lootboxes?tab=odds` and `/admin/users?tab=demoted` (`hooks/useTabParam.ts`;
the default tab is left out, an unknown value reads as the default, switching replaces the history entry). On the
moderation page the player names are links to the profile.

**Settings pages** (#26, merged 2026-11-12; the shell itself is #187's
`components/SettingsPage.tsx`, chain 2 W3): Game settings, Siege settings, **Lootboxes → Settings**, **Currency policy**
and **Road network** run on the `SettingsPage` shell — a sticky header with the title, "Last saved …", "n unsaved
changes", Reload, Discard, Save (n); with changes an in-app navigation asks "Leave without saving?" (red Leave, focus on
Stay) and a reload or closing the tab gets the browser's question; success is a toast, a refusal stays in the header.
- **Inside a tab** (`embedded`): the Lootbox settings tab is its own shell under the page's h1 (title as h2). A tab switch
  changes `?tab=` (`useTabParam`), which the shell's navigation blocker sees, so switching tabs with changes asks too;
  Stay keeps them.
- **Risky saves** (`confirmSave`): a page returns a question (or null) and the shell asks it, red unless it switches
  something on, before `onSave`; No keeps the changes and saves nothing. Used for the payments kill switch (per currency,
  both directions) and the lootbox master switch. Toggles that save at once ask with `useConfirm` before the request:
  a lootbox type's Enabled (`LootboxTypesTab`, `typeToggleQuestion`) and a token grant rule (`LootboxTokensTab`,
  `grantToggleQuestion`).
- **Units and help** (`utils/settingsUnits.ts`, `Field`'s `unit`): one spelling per unit (`UNIT`: ticks, s, h, ‰, bp, ×,
  ★, coins, gems, boxes) shown right of the input and read with it (`aria-describedby`), one line of help per field, and
  what the typed value means (`describeTicks` "= 1 s", `describeSeconds`/`describeHours` durations, `describePerMille` and
  `describeBasisPoints` as %, `describeWorldTime` "= 12:00 (noon)"), joined with `joinHint`. `formatOneIn` puts "1 in N"
  under small chances on the lootbox Odds tab.
- **Lootbox settings** (`components/lootbox/LootboxSettingsTab.tsx`): the PUT still sends the whole object; the two
  announce thresholds are choices "★n and better" / "Never" (`ANNOUNCE_NEVER` = 11); both announcement templates have a
  preview (`MinecraftLegacyPreview`, sample values `ANNOUNCEMENT_SAMPLE`, empty = the default template as the plugin's
  `LootboxAnnouncer` has it) and name placeholders the game doesn't fill in.
- **Currency policy** (`pages/admin/economy/CurrencyPolicyPage.tsx`): coins and gems as two sections with one Save (n);
  each changed policy is sent with the `updatedAt` it loaded, a 409 marks that currency stale (Save off, "Reload current
  policy" in its section), other refusals are named per currency in the header. The lowest sender title is a choice of
  the title brackets (`titleBracketClient.getAll`, `GET api/TitleBrackets`; a number input if they can't be loaded).
- **Road network** (`pages/admin/RoadsAdminPage.tsx`): the header saves the page's settings — the navigation defaults
  per domain type (a choice no longer saves on change) and the compass rule — as one batch, applying what saved and
  naming what was refused. `NavigationCompassCard` and `DomainNavigationDefaultsCard` only edit (the page holds saved
  values and drafts). Road profiles and stretches are records with their own Save (a stretch's is "Save stretch #n") and
  are not counted.

**Staff player profile** (`pages/admin/PlayerProfilePage.tsx` + `pages/admin/playerProfile/`, `/admin/users/:id`; #119,
web part merged 2026-11-12; the API part of #119 is not merged):
- **Status strip** (`PlayerStatusStrip`): chips for online / last seen (live through `PresenceChanged`, #183), no
  Minecraft account, mode, **Frozen**, **Payments locked**, premium tier, Deactivated, Not admitted, Minecraft-only and
  Email not verified, with **Freeze** / **Unfreeze** and Reload. While frozen a banner says since when, by whom (the latest
  `PlayerFrozen` audit entry) and why (`frozenReason`).
- **Freeze** (`usePlayerFreeze`): the frozen state comes from `GET api/Users/{id}` (`isFrozen`, `frozenReason`; the
  profile summary doesn't carry it). Freeze asks a required reason (max 200) in `confirmWithReason` and calls
  `PUT api/Users/{id}/freeze` (`knk.freeze`); Unfreeze is a plain confirm and `PUT …/unfreeze` (`knk.unfreeze`), which
  takes no reason yet. `UNFREEZE_TAKES_REASON` switches the confirm to an optional reason once the API stores one.
- **Tabs** (`ProfileTabs`, an ARIA tablist with arrow keys; `?tab=` through `useTabParam`, default Overview): Overview
  (account, title, premium, statistics), Economy (payment lock, Adjust balance, salary, kits, balance history),
  Permissions (groups, effective permissions), Moderation (freeze, mode, admission/web login, a note that kick and ban are
  game commands), Activity (timeline, audit log, discoveries), Privacy (private messages, data deletion). Only the open tab
  is mounted, so a panel's requests run when its tab opens.
- **Timeline** (`PlayerTimeline`, `utils/playerTimeline.ts`): `TimelineMerger` merges the audit log about the player
  (`GET api/audit-log?targetUserId=`) and, with `knk.admin.currency.history`, the balance ledger
  (`GET api/currency/admin/ledger?userId=`), newest first, 25 per "Load older"; an event is shown only once every source
  that has rows left has one at least as old. Filter chips per category (Moderation, Economy, Permissions, Progress,
  Account). Game sessions are not in it (no read endpoint).
- **Audit log** (`PlayerAuditLog`): `DataTable` + `Pager`, paged by the server (25 per page) with an action filter.
- **Actions without their node** are disabled with "Requires <node>" (`hooks/useActionGate.ts`, #280's rule):
  `knk.freeze`, `knk.unfreeze`, `knk.admin.user.group`, `knk.admin.user.perm`, `knk.kit.give`, `knk.admin.currency.lock`.
- **Live:** an `EntityChanged` for this `User` from someone else (a freeze in game, another staff member) re-reads the
  summary, the frozen state, the payment lock and the activity.
- **Robustness:** `normalizeProfileSummary` fills in a summary without groups, permissions, title or salary (an older
  API, a thin account) instead of crashing; "Back" is the layout's breadcrumb (no `navigate(-1)`).

**Moderation player search** (#119 MOD-5, `UserModerationPage` "All players"): the term (username, email or UUID, a
substring on the server) is sent trimmed, and a whole UUID without dashes gets its dashes (`utils/playerSearch.ts`).
Username, Email and Coins sort on the server (`sortBy`/`sortDescending`; `aria-sort`). Term, page and sort are in the URL
(`?q=&page=&sort=&dir=`, replace) so Back from a profile returns to them. **Recently opened** lists this viewer's last 8
profiles (`utils/recentPlayers.ts`, localStorage per account, this browser only).

**Detail page** (`DisplayWizardPage`, #81): `EntityDetailHeader` replaces the heading that showed the
display configuration's name: the entity's own name (`utils/entityLabel.ts`), its type, a breadcrumb
(`detailTrail`), **Back** to `returnTo` (else `/dashboard/{type}`), **Edit** coming back to the page and
**Delete** with a confirmation naming the entity (success toast, then Back's target). The tab title is
"{name} · {Type}". `DisplayWizard` takes the header as `renderHeader(entity)`.
Since #188 / #189 (merged 2026-11-12) the header's Edit and Delete follow the type's
metadata `actionNodes` (`useAllNodesGate`, all-of): a missing node disables the button with "Edit/Delete: Requires …"
under it (#280 rule).

**Detail page relationships and readability** (`components/DisplayWizard/`, #188, #189;
merged 2026-11-12):
- **Data:** `DisplayWizard` loads every type's metadata (`useEntityMetadata`). A section's relationship is the page
  type's `relationships` entry for its `relatedEntityPropertyName` (`detailPage.ts` `findRelationship`); a link row
  (`storage: linkRow`, e.g. `ItemBlueprintTag`) stands for its other side (`relatedType` `Tag`, id from
  `relatedIdField` / `relatedNavigation`).
- **Buttons** (`ActionButtons`): Select…/Change… (single), Add… (collection header), Unlink (single, and the
  configuration's "Remove" on items: never a delete), a separate red **Delete** on items (`showDeleteButton`, also in
  the section editor as "Delete item"), View, Edit, Create New (section only). Without a relationship entry (older
  API, unknown property) Select/Unlink/Add stay hidden. Each gate (`DisplaySection` `relationshipGate` /
  `deleteGateOf`): first what the API allows (`canLink`/`canUnlink`, else its `linkReason`/`unlinkReason`), then the
  nodes (`relationship.nodes`, the related type's `actionNodes.delete`). A disabled button has the reason as title and
  description; the section shows it once in text ("Change… and Unlink: …"), an item list once above the items.
- **Actions** (handled in `DisplayWizard`): Unlink asks a plain `useConfirm` ("… stays as it is; only its link … is
  removed") and calls `relationshipClient.unlink`; Delete asks a danger confirm and calls the related type's delete
  (a category refusal keeps the FeedbackModal with View children / Reassign parent); Select/Add open
  `RelationshipPickerDialog` (Dialog, `lookupClient.search` 10 per page, 250 ms after typing, linked rows marked
  "Linked") and call `relationshipClient.link`; a 409 `AlreadyLinked` asks "Move … here?" and retries with `move`.
  Success: a toast and a quiet re-read (`refetch(true)`).
- **Readability:** `DisplayField` renders a `<dt>`/`<dd>` pair (values as text, "-" muted when empty); hot edit saves
  with Enter, cancels with Escape. The first value of a related section or collection item, and every related-record
  value, links to `/display/{type}/{id}?returnTo=…` through `DetailLinksContext` when the viewer holds one of that
  type's `readNodes` (`usePermissions`), else plain text with "Opening X requires one of: …". Collections show a count
  in the title and 12 items per page with `Pager` (`COLLECTION_PAGE_SIZE`). Load errors keep `status`/`response`
  (`hooks/withCause.ts`) and `describeLoadProblem` words them: 403 `NoReadAccess` → "You don't have access to this
  Town" with the nodes (and the record's name from `GET api/Lookup/{type}/{id}` when `lookupGettable`), 404 → "doesn't
  exist" / "no detail page set up yet", anything else → "couldn't be loaded" with Try again.
- Clients: `apiClients/relationshipClient.ts` (`api/Relationships`), `apiClients/lookupClient.ts` (`api/Lookup`, also
  used by the wizard's relation picker, #191, and meant for AM3's picker lookup mode).

**"Show details" on refusals** (PandiO/knk-workspace#44; merged 2026-11-12):
`FeedbackModal` takes `details: { label?, load }`: a disclosure button (`aria-expanded`) in the Dialog's scrolling body,
so the footer stays in view; `load` runs on the first press only (spinner, then the result; an error line with Try
again); Hide/Show keeps the answer; focus still starts on the footer's first button. A delete refused as in use
(`utils/referenceDetails.ts` `isReferenceRefusal`: 409 with `code: "DbConstraint"`) offers **Show what uses it**
(`components/ReferenceDetails.tsx` `refusedDeleteDetails`, `apiClients/entityReferenceClient.ts` →
`GET api/EntityReferences/{type}/{id}/rows`) on the dashboard's row Delete, the detail page's header Delete (that
refusal is now a dialog instead of a toast) and an item's Delete on the detail page. Each group reads like the message
("23 structures", `referenceNoun`); rows link to their detail page when the API says `readable` (the dialog closes),
are plain text with "Opening … requires one of: …" otherwise, "… and n more" past 20, and groups the API only counts
show its reason.

**Navigation** (`components/Navigation.tsx`, since #30): the bar's links come from the route-meta table
(`topNav`): **Home**, **Leaderboards**, **Guides**, **Dashboard** for holders of the dashboard route's nodes
(any area node since #280 AM3, `TOP_NAV_NODES`; LW4-1, developer's decision 2026-11-06) and, last, for anyone holding the node
of at least one admin page, **Admin** (`/admin`). `navLayout.ts` picks labels, icons or a menu button by measured width. A link is the current
one (`aria-current="page"`, also in the menu panel) on its page and the pages below it in the table (`parent`: a
public profile lights up Leaderboards, the enchantment guide Guides; Dashboard on the dashboard, Entity setup, the
builders and the detail pages); Admin on every other page of the admin layout. The other admin pages are in the admin
sidebar (next section); the old `NAV_LINKS`, its hand-kept `nodeAccess`
map (which missed the invitations node, #262) and #197's `DASHBOARD_ACTIVE_ALSO` list are gone. Entity setup
(`/forms`), the builders and the detail pages have no link of their own: they sit under Dashboard in the table, so
Dashboard is the current bar and sidebar link there (LW1-1, LW4-1). Pages reached only from inside other pages: the account pages
(account menu), transaction details, siege matches and public profiles (links in lists), Entity setup (the
dashboard's ⚙ per type, "All saved progress").

## Dashboard access model in the web app (PandiO/knk-workspace#280 AM3, #205 bulk delete)

Merged 2026-11-13 (knk-web-app `main` `e02ee79`, with knk-web-api `master` `45043a7`; also on `next`). **Not
live-tested:** [dashboard access smoke test § 8](../guides/dashboard-access-smoke-test.md#8-web-app-am3), closed alpha
test run 2 checklist § 4c. Design: [DESIGN § 4.3, § 4.7, § 4.8](../specs/dashboard-access-model/DESIGN.md); API side:
[web-api architecture § 5.1, § 5.2](web-api-architecture.md#51-dashboard-access-model-pandioknk-workspace280-am1-merged-2026-11-12-am3-2026-11-13).
Decisions LAM3-1…12 in the [chain 3 report](../reports/2026-11-08-ux-chain-3.md). LAM3-1 (form wizard for any area node) was reverted by
[#371](https://github.com/PandiO/knk-workspace/issues/371) (knk-web-app `next` `e6ba115`, 2026-11-13; not yet on `main`). The web app only decides what it
offers; the API checks every call.

- **Nodes** (`hooks/useStaffAccess.ts`): `DELETE_PERMISSION_NODE` (`knk.admin.delete`), `DELETE_BULK_PERMISSION_NODE`
  (`knk.admin.delete.bulk`), `EXPORT_PERMISSION_NODE` (`knk.admin.export`) and `AREA_NODES`, the API's seven area
  nodes (`DashboardAccess.AreaNodes`; the API doesn't list them, keep both in step). `anyNodeStatus(statuses, nodes)`
  folds several answers; `useAnyAreaNode()` answers whether any area node is held (one cached check per node, shared
  with the nav and the route gates).
- **Per type from metadata** (`hooks/useEntityAccess.ts`): `entityAccessOf(meta, statuses)` / `useEntityAccess(meta)`
  turn the metadata's `actionNodes`, `readNodes`, `deletable`, `bulkDeletable` and `exportable` into gates `view`
  (area node), `read` (any read node), `create`, `edit`, `delete`, `bulkDelete`, `export` (all-of), each with
  `allowed`, `checking` and a `hint` ("Requires knk.admin.world and knk.admin.delete"; "Couldn't check …" on an error).
  Nothing is hard-coded per type. **Create and edit also need `knk.admin.content`** (#371, developer 2026-11-13: area
  staff work with the content that exists and don't change forms; reverts LAM3-1): `withContentNode(nodes)` adds it to
  the type's create/edit nodes, because both open the form wizard. Not for Edit of a User, which opens the player
  profile (`editOpensFormWizard`, `utils/returnTo.ts`). So a world-only account sees **New Town** and **Edit** disabled
  with "Requires knk.admin.content", and a content-only account still can't create a Town (it lacks
  `knk.admin.world`). The detail page's header Edit uses the same rule (`DisplayWizardPage`). Metadata without the
  access fields (an API before #280): create and edit need `knk.admin.content`, every other action is open (the API
  decides) except bulk delete and export. Since [#374](https://github.com/PandiO/knk-workspace/issues/374) (knk-web-app
  `next` `ca1959d`, knk-web-api `next` `b65e66d`, 2026-11-13) the API refuses creates and edits without
  `knk.admin.content` too and lists it in `actionNodes.create`/`edit`, so `withContentNode` is a no-op against it; it
  stays so the gates are right against an API without #374 and the two deploy in either order. `accessNodesOf(metas)` lists every node to ask, including the global action
  nodes the gates fall back to.
- **Detail page link buttons** (`components/DisplayWizard/DisplaySection.tsx`, #374): **Select…**, **Change…**,
  **Unlink** and **Add…** gate on `withContentNode(relationship.nodes)` through `useAllNodesGate`
  (`relationshipGate`): first what the API allows (`canLink`/`canUnlink` with its reason), then the nodes. Without
  `knk.admin.content` they are disabled with "Requires knk.admin.content", shown on hover and once in the section's
  hint line (`ActionButtons`). **Delete** of a related item keeps its own gate (`actionNodes.delete`). Not yet gated
  beforehand: the Lootboxes Types tab's Enable/Disable and Road network's "New street", which now need the content node
  in the API ([#383](https://github.com/PandiO/knk-workspace/issues/383)).
- **Metadata only for staff** (LAM2-9 fixed, LAM3-2): `useEntityMetadata` loads `GET api/Metadata` and the entity type
  configurations only once an area node answered yes (or the check failed; the API decides), not for "denied"; players
  never request them. `hooks/loadedEntityMetadata.ts` reads the already loaded metadata without asking (the picker's
  Create New gate, LAM3-10).
- **Dashboard** (`ObjectDashboard`): the explorer lists only types whose `view` gate is allowed (`useViewableTypes`), plus types whose check
  failed or that have no access fields (LAM3-6); a type of another area in the URL falls back to an allowed one. New /
  New with / Edit / Delete are disabled with the gate's hint; the ⚙ is disabled with "Requires knk.admin.content"
  for other area holders (LAM3-11). A single Delete asks with `useConfirm` (danger), a refusal keeps V6's error dialog
  with "Show what uses it", success is a toast and the row also leaves the bulk selection.
- **Bulk delete** (#205): "Delete (n)" (`btn-danger`) in `DashboardSelectionBar`'s `actions`, rendered only when the
  `bulkDelete` gate is allowed (hidden, not disabled; never for User and PermissionGroup). Confirm "Delete 3 Streets?"
  (no reason asked, LAM3-3), then `utils/bulkDelete.ts` sends the ids to `POST api/Dashboard/bulk-delete`
  (`dashboardClient.bulkDelete`, 120 s timeout) in chunks of 100 (`Deleting… n / N`), stops at the first failed call
  (429, network) and records the rest as not tried. Deleted ids leave the table and the selection; refused rows stay
  selected. `BulkDeleteResultDialog` (only when a row was refused or not tried) lists each refused row with its reason;
  `code: "InUse"` rows offer "Show what uses it" (V6's `ReferenceDetails`, LAM3-5). A toast in every case. The API
  sends one `EntityChanged` per deleted row; other open tables refresh once, because the live refresh is debounced
  (`realtime/liveUpdates.ts`, X1).
- **Routes and nav:** `staffAny` (see Routes below): the Dashboard link, the dashboard and the detail page open for
  any area node; the form wizard routes need `knk.admin.content` (#371); "Staff only" lists the nodes. `Navigation` and `routes/useAdminNav.ts` decide
  with `routeAllowed`, so any one node of a `staffAny` route shows its link. The top bar's **Create New** menu is unchanged (content holders, every type): #353.
- **Reads across areas:** a refused table read (`code: "NoReadAccess"`) says "You don't have access to Town. Requires one
  of: …" (`utils/readRefusal.ts` `readRefusalMessage`) in every `PagedEntityTable`, pickers' full tables included
  (LAM3-12). The open form's breadcrumb label (`useEntityLabel`) and the wizard's join-entry labels fall back to
  `GET api/Lookup/{type}/{id}` when the full read is refused (`utils/fetchOrLookup.ts` `fetchByIdOrLookup`). A
  picker's **Create New** shows only with the related type's create node plus `knk.admin.content` (`useCreateAllowed`;
  hidden on a "no", LAM3-8, #371); the wizard pickers'
  lookup mode is V6's (`relationAccess`). Other pickers (Minecraft material and enchantment, the category filter) keep
  the full read; the material picker in the GateStructure and LootboxType forms needs the content read nodes (#352).
- **Entity setup** (`FormWizardPage`): `/forms/:type` (lists and wizard) is behind `staff(knk.admin.content)`, so
  without it the route gate shows "Staff only" (#371 removed AM3's "Entity setup needs knk.admin.content" notice). Both configuration tables disable **Delete** with "Requires knk.admin.delete" without it
  (LV7-8; the API refuses it too).
- **Audit labels** (`auditDetails`): "Bulk delete on the dashboard" and "Dashboard export" with type, counts and ids.
- **Tests:** `useEntityAccess` (8), `bulkDelete` (5), `readRefusal` (2), `fetchOrLookup` (2), `ObjectDashboard` (#280
  per-type access, bulk flow, chunks, cancel), `DashboardSelectionBar` (endpoint), `tableExport`, `useEntityMetadata`,
  `routeTable`, `AdminLayout`, `FormWizardPage.deleteConfig`, `auditDetails`, the nav tests for area nodes.

## Routes, layouts and the admin sidebar

PandiO/knk-workspace#30 (chain 2 link W4; merged 2026-11-12 in `main` `1371951`; smoke test not run).

- **Route-meta table** (`src/routes/routeTable.ts`, `ROUTES`): one entry per route with `path`, `layout`
  (`public` | `player` | `admin`), `access` (`public`, `login`, `staff` + node, `owner` + node), `title`, and for
  admin pages `group` (Content, World, Players & support, Economy, Settings, Owner), `sidebar` (icon and a one-line
  description; only these are listed), `parent` (breadcrumb parent and link highlighting) and `breadcrumbs`
  (`page` when the page draws its own trail: open form, detail page). `topNav` marks the bar's links. `REDIRECTS`
  keeps old URLs (`/admin/form-configurations`, `/admin/display-configurations` → `/forms`). Helpers: `matchRoute`
  (react-router's ranking, so `/admin/users/balance-log` is the balance log, not a player profile), `lineageOf`,
  `isWithin`, `trailFor`, `SIDEBAR_ROUTES`, `ADMIN_NODES`, `TOP_NAV_ROUTES`. URLs and gates are the ones `App.tsx`
  had (pinned in `routes/__tests__/routeTable.test.ts`); a new page is one entry here plus its element in `App.tsx`
  (`RouteElements` is typed by the table's ids, so a missing page fails `tsc`).
- **Gates** (`routes/RouteGate.tsx`): `login` → `ProtectedRoute`, `staff` → `StaffRoute` (the node; "Staff only"
  without it), `staffAny` → `StaffRoute` with a list (any one opens it; "Staff only" lists the nodes; #280 AM3),
  `owner` → `OwnerRoute` (exact grants, D24). Display only: the API checks the same node. `nodesOf(access)` gives
  every node a route asks about, `routeAllowed(access, statuses)` the answer; `nodeOf` the first node (sidebar).
  `staffAny(AREA_NODES)` (`DASHBOARD_ACCESS`) is on `dashboard`, `dashboardType` and `entityDetail`. `entitySetup`
  (`/forms`), the form wizard routes `entitySetupType` (`/forms/:entityName`, also New / New with / Drafts) and
  `entityEdit` (`/forms/:entityName/edit/:id`), the builders and the Minecraft catalogue are
  `staff(knk.admin.content)` (#371 reverted AM3's LAM3-1, which had opened the wizard routes for any area node).
  Links into the wizard from other pages (the Lootboxes tabs' New/Edit, Road network's street Rename, a detail page
  section's edit and Create New) are not gated yet and lead to "Staff only" without the node:
  [#380](https://github.com/PandiO/knk-workspace/issues/380).
- **Layout routes** (`src/layouts/`, built by `routes/AppRoutes.tsx`): `PublicLayout` (landing, auth pages,
  invites, leaderboards, guides, public profiles, siege matches, the deletion confirmation, 404), `PlayerLayout`
  (`/account`, `/account/link`, `/account/transactions`), `AdminLayout` (`/admin`, the dashboard, Entity setup,
  builders, detail pages, `/admin/*`, `/owner/*`). Each has the page frame (`PageFrame`; admin is wider,
  `max-w-screen-2xl`), `RouteTitle` and its own `RouteErrorBoundary` (X-4): a crash leaves the bar and the sidebar
  working. An outer boundary in `App.tsx` only catches a crash of a layout itself. Logged out there is still no bar
  (LANDING_PAGE_NAVIGATION_ARCHITECTURE).
- **Titles**: `RouteTitle` sets `document.title` from the entry ("Road network · Knights & Kings"). It renders
  before the page, so a page with a better title still sets its own with `usePageTitle` (the detail page: entity
  and type; Entity setup; the landing page). The static `usePageTitle` calls in the pages are gone; the ten pages
  that had no title (Roads, Mail log, Invitations, Minecraft catalogue, Leaderboards, the owner pages, Orphaned
  Locations, public profiles) get one.
- **Admin sidebar** (`components/admin/AdminNavList.tsx` in `AdminLayout`): from `xl` a sticky panel left of the
  page; below `xl` an **Admin pages** button opens the same list (Escape, a click outside or a choice closes it).
  `routes/useAdminNav.ts` lists every sidebar page whose node the user holds, by group, through
  `usePermissions(ADMIN_NODES)` (`hooks/useStaffAccess.ts`: one cached check per node, shared with `usePermission`
  and the route gates). Economy pages and Orphaned Locations are listed by their own node (they used to be buttons
  on Moderation only); Invitations shows for `knk.admin.invites` (#262). A page's link is current on the pages
  below it (`parent`): Player moderation on a profile, Balance event log on a transaction, Dashboard on Entity
  setup, the builders and detail pages. The `/admin` overview (`pages/admin/AdminHomePage.tsx`) is the same list
  as a page, by group with each page's description; no sidebar next to it; "No admin pages" without any node.
- **Breadcrumbs**: `AdminLayout` draws `trailFor(route)` above the page: the group (linking to its section on
  `/admin`, `#admin-group-<id>`), the parents, the page ("Economy › Balance event log › Transaction"). A parent
  with the page's own title is left out (`/dashboard/Town` is "Content › Dashboard"). Pages with
  `breadcrumbs: 'page'` draw their own trail; the layout puts the group crumb in front through
  `BreadcrumbPrefixContext` (`components/Breadcrumbs.tsx`), so every admin trail starts with its group.
- **Height**: the dashboard and Entity setup fill the window (`ObjectDashboard.css`); `--admin-chrome` (the
  measured height of the row with the menu button and trail) is taken off, so the page doesn't scroll.

**Create New menu** (`components/CreateNewMenu.tsx`, #177 link 2 / #39 CRUD-2): built from the entity
metadata — every type with a create client in `utils/entityApiMapping.ts`
(`hasCreateFunctionForEntity`), A–Z — instead of the hand-kept list in `config/objectConfigs.tsx`,
which offered `itemType` (no API mapping) and missed about 15 types. A pick opens the default form and
comes back to the dashboard on that type. A filter box gets focus on open (ArrowUp/ArrowDown, Enter,
Escape). Without metadata the built-in list is the fallback.

A third, older, simpler config path — `src/config/objectConfigs.tsx`, a static
TypeScript map of `ObjectConfig` per entity type (fields, icons, validators,
formatters) — still gives `ObjectDashboard` and the pickers their built-in table columns
(`getColumnDefinitions`), the Create New menu its icons, and the dashboard its type list when the
metadata can't be loaded. Its type list (19 types, including the unmapped `itemType`) is not the
backend's live metadata list (`metadataClient.getAllEntityMetadata`), which the dashboard, the
explorer, the Create New menu and the form/display engines use — see
`docs/reports/web-app-scan-2026-09-18.md` for the "two competing config systems" note under
Legacy/Orphaned.

Entity metadata itself (which fields exist on which backend entity, display config,
validation rules) is fetched once per session and cached at module scope by
`hooks/useEntityMetadata.ts`, then merged with `EntityTypeConfigurationDto` (per-entity
icon/color/sort overrides, authored via the — currently unrouted —
`EntityTypeConfigurationPage`). Each hook instance holds its own copy; a `refresh()` (e.g. after
saving default table columns) notifies every mounted instance, so an open picker picks the change up
without remounting.

**Relation picker** (`components/FormWizard/RelationPicker.tsx`, PandiO/knk-workspace#191;
merged 2026-11-12): `ObjectField` and `ListField` show a search box (`role="combobox"`) instead
of the inline `PagedEntityTable` (an Object field's "Select instance"/"Replace instance" toggle is gone). Nothing is
fetched, and no permission is asked, until the box is used; then the first 8 matches
(`RELATION_PICKER_PAGE_SIZE`) after a 250 ms pause, the form session's pinned rows on top (KNG-136, same client-side
filtering), each with the first two configured default columns as a second line (`utils/forms/relationPicker.ts`
`optionDetail`, KNG-166). Arrow keys + Enter or a click pick; Escape closes the list only (the surrounding Dialog
ignores a handled Escape). Single: a pick replaces the value and closes the list. List: a pick adds or removes one row,
`maxSelection` disables the rest. **Open full table** opens the old table in a `Dialog` (pickerFilters, the category
filter, pinned rows, selection; a single pick closes it). **Access** (#280, `relationAccess`): with one of the related
type's metadata `readNodes` (or when the metadata names none) the type's own search; without one `lookupClient.search`
(`api/Lookup`, names and one detail line, no full table, picked as `{ id, name }` like an edit-loaded reference); a
type without a lookup says "can't be searched here. Requires one of: …". A lookup takes no filters: `prefer…` filters
are dropped, `excludeIds` is applied on the page, any other pickerFilter makes the picker say why instead of offering an
unfiltered list (`lookupFilterPlan`).

**Picker columns** (KNG-166): `PagedEntityTable` shows the entity's saved default table columns
(Entity setup page → Default Table Columns) or else the built-in columns of
`config/objectConfigs.tsx` (District: Town, World; Street: Districts, Towns; Structure and
GateStructure: street + number, District, Town). Built-in columns read the list DTO's flat field and
fall back to the full DTO's nested shape (`utils/forms/pickerRowValues.ts`), so pinned and searched
rows match. A saved key (a metadata field name such as "Town") is matched to the built-in column with
the same key, key + "Name", or the same label (`utils/forms/savedColumns.ts`). Saving no columns clears
them ("Use built-in columns"; the API stores an empty list as none).

## Directory map

```
src/
  App.tsx                 — maps each route id to its page; the shell (bar, toasts, background)
  routes/                 — routeTable.ts (route-meta table), AppRoutes, RouteGate, useRouteMeta, useAdminNav (#30)
  layouts/                — PublicLayout, PlayerLayout, AdminLayout (sidebar + breadcrumbs), PageFrame, RouteTitle (#30)
  pages/                  — one component per route (see reading guide for the table)
    admin/                — the admin pages (AdminHomePage = /admin overview, #30)
    auth/                 — login/register/forgot/reset pages + barrel index.ts
  components/
    FormWizard/            — generic create/edit engine (config-driven)
    FormConfigBuilder/      — admin UI to author FormConfigurationDto records
    configBuilder/          — the builders' shared toolbar, Publish/Duplicate/Generate dialogs, form and display previews (#71)
    DisplayWizard/          — generic detail-view engine; `EntityDetailHeader` (name, Back/Edit/Delete, #81); relationship actions and picker (#188), `detailPage.ts` (links, load problems, #189)
    DisplayConfigBuilder/   — admin UI to author DisplayConfigurationDto records
    ObjectDashboard/        — legacy static-config-driven list/CRUD dashboard; `DashboardSelectionBar` (bulk bar, Export CSV, #205)
    ObjectTypeExplorer/     — left-nav entity type picker (ObjectDashboard, FormWizardPage): search, A–Z/Z–A sort, optional groups (unused since #177 link 2), `marked` entries, `favourites` with a star per type, listed on top as copies (#194, #225, dashboard only), `filters` (Any/Yes/No selects, #226, dashboard only), settings in localStorage (KNG-61)
    ReferenceDetails.tsx    — what still uses a record, inside FeedbackModal's "Show what uses it" (#44)
    PagedEntityTable/       — generic server-paged table, used by the dashboard and the relation picker's "Open full table"; controlled mode (`query`/`onQueryChange`), `rowHref`, `aria-sort` (#39); `selectionStyle="checkbox"` + `renderSelectionBar` (#205); draws through `DataTable`/`Pager` (#187)
    DataTable.tsx, Pager.tsx, Field.tsx, SettingsPage.tsx — data and format primitives (#187); see § Data and format primitives
    PathBuilder/            — path/reference picker for cross-entity field bindings
    Workflow/               — WorldTask/job polling UI (siege/world-mutation background tasks)
    minecraft/              — hybrid pickers for Minecraft material/enchantment refs
    auth/                   — multi-step registration form, login form, password strength meter
    currency/               — ledger table, Adjust balance card, and StaffNoteField: the reason field of every staff form
                              that needs MIN_STAFF_NOTE_LENGTH characters (live "n / 10 characters" counter, message after
                              a submit with a short note; the form keeps its button enabled and checks isStaffNoteValid, KNG-126)
    shared/, DynamicForm.tsx, ObjectView.tsx, ... — see scan report for orphan status
  contexts/AuthContext.tsx  — the only Context; owns user/isLoggedIn/login/register/logout/refresh
  hooks/                    — useAuth (re-export of AuthContext), useEntityMetadata (cache),
                              useEnrichedFormContext, useRelationshipDrafts, useAutoLogin (unused)
  apiClients/               — one REST client class per backend resource (25 files), all
                              extending ObjectManager (see Data flow below)
  services/
    serviceCall.ts          — low-level fetch wrapper (headers, JSON parsing, error shape)
    authService.ts          — auth orchestration used by AuthContext (token storage side effects)
  utils/
    tokenService.ts         — localStorage/sessionStorage token persistence
    config-helper.ts         — ConfigurationHelper.gatewayApiUrl → appConfig.api.baseUrl
    enums.ts                 — Controllers enum (maps client → backend controller route segment)
    csv.ts, tableExport.ts, tableCells.tsx — CSV writing, export rows (selection / all pages, 10,000 cap), cell values as text (#205)
    playerTimeline.ts, playerSearch.ts, recentPlayers.ts — player profile timeline merger, moderation search, recently opened (#119)
  config/
    appConfig.ts              — base API URL config (not a REACT_APP_* env var)
    objectConfigs.tsx          — legacy static per-entity-type config (see above)
  types/
    dtos/<resource>/           — one folder per backend resource, hand-maintained DTOs
    uiObjectConfig/, domain/    — form/display config domain types + mappers
  prompts/                    — checked-in Markdown design/requirements docs for past features
                                (not app code — arguably belongs under knk-workspace docs, see
                                reading guide)
```

## Data flow: web-app → web-api

Every REST call goes through the same three-layer stack:

1. **Resource client** (`src/apiClients/<resource>Client.ts`) — a thin class extending
   `ObjectManager`, exposing typed methods (e.g. `authClient.login(...)`,
   `townClient.getAll()`). Each method calls `this.invokeServiceCall(data, operation,
   controller, httpMethod)`.
2. **`ObjectManager.invokeServiceCall`** (`src/apiClients/objectManager.ts`) — wraps the
   call in a `Promise` with a 15s manual timeout, builds `InvokeServiceArgs`, and hands
   off to `serviceCall.invokeApiService`. Logs errors through `logging.errorHandler`,
   which is what feeds the toast UI in `App.tsx`.
3. **`ServiceCall.invokeApiService`** (`src/services/serviceCall.ts`) — builds the final
   URL as `{ConfigurationHelper.gatewayApiUrl}/{controller}[/{operation}]`, attaches
   `Authorization: Bearer <token>` from `tokenService.getAccessToken()` when present,
   sends `credentials: 'include'` (cookies, for refresh-token flow), and does the actual
   `fetch`.

The `controller` segment for each resource comes from the `Controllers` enum
(`src/utils/enums.ts`), e.g. `Controllers.Auth = 'Auth'`, `Controllers.GateStructures =
'GateStructures'` — this enum is the single source of truth mapping a client to its
backend route and should be cross-checked against `knk-web-api`'s actual controller
names when doing cross-repo work (not verified against knk-web-api in this pass — see
Uncertain items below).

Base URL resolution: `ConfigurationHelper.gatewayApiUrl` (`src/utils/config-helper.ts`)
→ `appConfig.api.baseUrl` (`src/config/appConfig.ts`) — confirmed **not** wired through
a `REACT_APP_*` environment variable, matching the note already in this repo's
`CLAUDE.md`.

## Auth

- `AuthProvider` (`src/contexts/AuthContext.tsx`) wraps the whole app in `App.tsx` and
  owns `user`, `isLoggedIn`, `login`, `register`, `logout`, `refresh`.
- On mount, `AuthProvider` calls `authService.autoLogin()`, which tries
  `GET /Auth/me` and, on failure, tries a refresh-token flow
  (`POST /Auth/refresh`, cookie-based) before retrying `me`.
- `ProtectedRoute` (`src/components/ProtectedRoute.tsx`) gates every non-public route:
  shows a spinner while `isLoading` or while a silent refresh is in flight, then
  redirects to `/auth/login` (preserving `location.state.from`) if still unauthenticated.
- Access tokens: `tokenService` (`src/utils/tokenService.ts`) stores the bearer token in
  `localStorage` when "remember me" was set at login, `sessionStorage` otherwise; a
  separate `RememberMe`/`RememberMeExpiresAt` pair in `localStorage` tracks whether the
  remembered session is still within its window.
- Registration auto-logs the user in afterward (`authService.register` calls
  `this.login(...)` with `rememberMe: true` once registration succeeds).
- Minecraft-account linking (`authClient.generateLinkCode` /
  `requestLinkCode` / `linkAccount` / `linkMinecraftAccount`) is implemented
  client-side and exposed through `AccountManagementPage` and the registration flow's
  `LinkCodeDisplay` — this is the web-app half of the plugin's link-code account
  merge feature; the plugin/API side of this was not verified in this pass.

## Talks to (other components)

- **knk-web-api**: REST only, JWT bearer + a refresh cookie, as above. No GraphQL,
  no websockets/SSE anywhere in `src/`. World-task status is polled every 2 s by
  `components/Workflow/WorldBoundFieldRenderer.tsx` (`TaskStatusMonitor` was deleted) and catalog scans
  every 3 s; the SignalR plan replaces both ([`specs/realtime-signalr/DESIGN.md`](../specs/realtime-signalr/DESIGN.md), #66; 2026-10-25).
  *#181 (branch `claude/realtime-signalr`):* `src/realtime/RealtimeProvider.tsx` (mounted in `App.tsx` inside
  `AuthProvider`) keeps one `@microsoft/signalr` connection per logged-in tab to `${REACT_APP_API_BASE_URL}/hubs/web`
  (JWT from `tokenService` as `access_token`), reconnects, joins task groups again and tells components to re-read
  (`useRealtimeEvent`, `useRealtimeReconnected`, `joinTask`/`leaveTask`; without the provider nothing is connected).
  `WorldBoundFieldRenderer` renders from `WorldTaskUpdated` and polls 10 s while connected, 2 s while not; "Send to
  Minecraft" sends `deliver: 'auto'` after the busy check (`GET WorldTasks/active-for-me` + `GET Presence/me`, only while
  connected) with Queue / Hand off / Replace / Cancel; "Hand off to…" (`GET Presence/online-staff`); the offer state
  above the task code, folded while an offer is out. `MinecraftCatalogScanCard` reads the scan on `CatalogScanUpdated`
  (15 s safety poll while connected). DESIGN §8.8. *#239/#240 (merged 2026-11-05):* a waiting task's code card has
  "Send again" (presence + busy check, then `POST WorldTasks/{id}/offer`) and "Hand off to…" while the hub is
  connected; the busy panel and the picker re-deliver that task instead of creating one (`deliverTask`); the card
  shows only the `/knk task <code>` command; `offerNotice` covers `NoPermission`.
  *#183 (Realtime S4, merged 2026-11-12; smoke test § S4 not run):* `src/realtime/liveUpdates.ts` listens for
  `EntityChanged` and `PresenceChanged` (the API sends them only to holders of the type's area node since #280 AM1 —
  `knk.admin.content`, `knk.admin.world`, … — or `knk.admin.user.manage`): `useLiveEntityChanges` (one debounced call per burst of other staff's changes to a type or
  entity, a delete, or a reconnect; the context's `userId` skips your own) and `usePresenceChanges`. `ObjectDashboard`
  refetches its table quietly (`PagedEntityTable` `liveRefreshKey`, rows stay) with "Updated by … at …";
  `DisplayWizardPage` re-reads quietly (`useEntityData` `refetch(true)`) or says the entity was deleted;
  `UserModerationPage` updates the Online/Offline badges in place (`applyPresence`) and re-reads quietly on a bulk change
  or reconnect; `PlayerProfilePage` shows an online badge from the profile summary's `presence`. Tests use
  `src/test-utils/fakeRealtime.tsx`. DESIGN §6.9.
  *#180 (branch `claude/world-task-hardening`):* the panel stops polling once the task is closed (Completed, Failed,
  Cancelled, Expired) and offers "Cancel task" / "Start again"; tasks are anchored to the draft: `FormWizard` keeps the
  latest task per field (`fieldTasks`, loaded from `GET FormSubmissionProgress/{id}/world-tasks` on resume), saves the
  draft silently before a form's first task (`ensureWorldTaskAnchor`), applies a result that completed while the form
  was closed and marks it applied (`POST WorldTasks/{id}/applied`), and cancels its open tasks when the form is left;
  `utils/forms/worldTaskLifecycle.ts` (`resolveWorkflowSessionId`: a resumed draft keeps its session). The form builder
  offers only task types with a handler (`utils/forms/worldTaskTypes.ts`, default `LocationSelection`).
- **knk-plugin**: no direct contact — the web app never talks to the plugin. The only
  connection is indirect, via `knk-web-api`, through the Minecraft-account link-code
  flow described above.

## Known structural risks (see scan report for full detail/citations)

- Two independent, only-partially-overlapping "which entities exist" registries
  (`config/objectConfigs.tsx` static map vs. the live `metadataClient` bundle) —
  adding an entity to one does not automatically add it to the other.
- ~~`pages/admin/EntityTypeConfigurationPage.tsx` is fully built but has no route~~ — the file no longer
  exists (checked 2026-11-05, #30); every page is an entry of `routes/routeTable.ts`.
- ~~`DisplayWizardPage`'s `edit`/`create` action handlers navigate to `/form/...`~~ —
  fixed: they go to `/forms/...` with a `returnTo` to the detail page (#177 link 2, #81).
- `components/DynamicForm.tsx` and `components/ObjectView.tsx` are large (383 and 411
  lines), fully unreferenced, and (for `DynamicForm.tsx`) import three apiClient
  modules — `apiClients/districts`, `apiClients/streets`, `apiClients/locations` —
  that no longer exist under those names in the codebase. They read as the
  predecessors to `FormWizard`/`DisplayWizard` left behind after that migration.

## Uncertain / needs a follow-up pass

- Whether `tsconfig.app.json`/`tsconfig.node.json`/`tsconfig-deps.json` (Vite-style
  project-reference layout) are actually honored by `react-scripts` 5, or are dead
  scaffolding like the already-flagged unused `eslint.config.js` — if `react-scripts`
  ignores them, `DynamicForm.tsx`'s broken imports may or may not surface as a type
  error in `npm run build`. Not run in this read-only pass; worth a quick `npm run
  build` check before relying on this doc's compile-safety assumptions.
- The `Controllers` enum route-segment values were not cross-checked against
  `knk-web-api`'s actual controller route attributes in this pass — do that as part of
  the `knk-web-api` scan or the consolidated cross-repo report.
- Whether the Minecraft-account link-code feature described above is actually
  consumed by `knk-plugin` today (this scan only covers `knk-web-app`).
