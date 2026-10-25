# Web app UX roadmap re-evaluation (KNG-140, PandiO/knk-workspace#24)

**Status:** Report (research only, no code changed)
**Date:** 2026-10-25
**Issues:** [#24](https://github.com/PandiO/knk-workspace/issues/24) (KNG-140) and its sub-issues; related [#58](https://github.com/PandiO/knk-workspace/issues/58) (KNG-60), [#39](https://github.com/PandiO/knk-workspace/issues/39) (KNG-145), [#177](https://github.com/PandiO/knk-workspace/issues/177) (dashboard CRUD hub)
**Code basis:** knk-web-app `main` @ `0d61270`, knk-web-api `master` @ `6f08383` (both 2026-10-25)
**Re-evaluates:** [2026-10-08-web-app-ux-assessment.md](2026-10-08-web-app-ux-assessment.md) (done on web-app `84943ff`)
**Plan that uses this report:** [2026-10-25-ux-dashboard-signalr-plan.md](../ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md)

Evidence: the assessment, the [cleanup analysis](2026-10-08-web-app-cleanup-analysis.md), CHANGELOG, ACTIVE_SESSIONS, the form
wizard chain, invitations and alpha reports. Paths without a prefix are in `knk-web-app/src/`; "API" = `knk-web-api/`.
Spot-checked by hand: drafts saved as user `'1'` (`pages/FormWizardPage.tsx:163`), the Game Settings / Siege route gates
(`App.tsx:171-181` default `knk.admin.user.manage` vs API `StaffPermissions.ServerConfig`), the error-only `ToastRegion`.

Status legend: **Done** / **Partly done** / **Still open** / **Obsolete** (the code it refers to is gone or changed
shape) / **Needs re-scoping**.

---

## 0. TL;DR

- Since 2026-10-08, these shipped: KNG-64 WP9, KNG-141 (alpha safety quick wins, merged 2026-10-18 in web-app `5404801`, although #24 still says "in progress"), KNG-71 (Fluent removed), the
  form wizard chain (KNG-133..138, 162, 164, 166..169, 172..174), KNG-39/82/94, KNG-61, KNG-186/269 and the invitations
  chain. Together they closed about a third of the findings the sub-issues cite: X-1 toast region, SET-1, SET-2, CRUD-7,
  the `/form/` route bug, CRUD-16 (mitigated by hiding the actions), X-4, NAV-2/3/4 (basic), the MKT-1/2 landing,
  all `window.confirm`/`alert`, step names (KNG-137), Cancel form (KNG-162), export/import (KNG-138), Display
  Draft/Publish, the explorer drawer (KNG-94).
- **The admin CRUD core is almost untouched**. CRUD-1, CRUD-2, CRUD-4, NAV-6, CRUD-5, CRUD-6 (guard and footer), CRUD-8,
  CRUD-11, CRUD-12, CRUD-13 (preview) and CRUD-15 (header) are all still open. That is the right focus for a closed alpha with a handful of
  admins.
- **Stale issue text is common.** #109 lists form wizard bugs that are all fixed, #71 lists KNG-138 and KNG-40, both done, #33 lists
  KNG-82 (done) and old counts, #139 says the alpha runs `Email:Provider=Log` (it has used real SMTP since Phase 9), and #24 says the quick wins are
  "in progress".
- **Recommended changes:** close none outright. Re-scope #38 (now tiny; fold it into #95 or do it as a 1-hour PR), #33 (the confirm half exists as
  `useConfirm`; refocus on Dialog a11y, success toasts, `format.ts`, and a required reason), #81 (the actions are already hidden; what is left
  is the header plus real link/unlink), #104 (the app sits behind Cloudflare Access, so SEO here is moot), #109 (split clickable steps
  into #68; keep footer, guard, blur validation and drafts), and #122 (the KNG-94 part is done). Merge #92 into the rebrand track with #95,
  and #117 stays parked.
- **Top priorities for the alpha:** the dashboard CRUD hub (#177/#58/#39) → #33 (toast and Dialog pieces only) → #109 (footer, guard, per-user drafts)
  → #71 (save in place) → #81 (header) → #30 (page titles, breadcrumbs, grouped nav) → #26 MOD-6 (two wrong route gates)
  → #83 think-aloud.

---

## 1. Findings fixed since the assessment (cross-reference)

| Finding | Now | Evidence |
|---|---|---|
| X-1 toast channel never rendered | Done (errors only) | `components/ToastRegion.tsx` (`aria-live="polite"`, subscribes to `logging.errorHandler`), mounted `App.tsx:303` |
| X-4 no error boundary | Done | `App.tsx:91` `RouteErrorBoundary`, `components/ErrorBoundary.tsx` |
| SET-1 load failure → editable defaults | Done | `pages/admin/GameSettingsPage.tsx:185-188,245-258` (blocking card + Retry) |
| SET-2 retention lowering, no confirm | Done | `components/admin/DataRetentionCard.tsx:12,32-87` (typed confirmation) |
| CRUD-7 number fields can't hold 0 | Done | `components/FormWizard/FieldRenderers.tsx:698,733,785,813` (`value ?? ''`) |
| CRUD-15 `/form/` dead route | Done | `pages/DisplayWizardPage.tsx:13-28` |
| CRUD-16 Remove deletes the related entity | Mitigated | `components/DisplayWizard/ActionButtons.tsx:17-22` `RELATIONSHIP_ACTIONS_AVAILABLE = false` |
| CRUD-14 `alert()`, `window.confirm`, double delete confirm | Done | 0 `alert(`/`window.confirm` in `src/`; `hooks/useConfirm.tsx` used in 7 files; `FormConfigurationTable.tsx:46-50` hands delete to the page (one prompt) |
| CRUD-8 KNG-53 boolean required | Done | CHANGELOG 2026-10-10 (`955fa20`) |
| CRUD-3 explorer search/sort/group, phone toggle (CRUD-4) | Done | `components/ObjectTypeExplorer/ObjectTypeExplorer.tsx:13-50,132-138,348-352` (groups, drawer, Escape); KNG-61, KNG-94 |
| CRUD-4 rows keyed by index | Done | `PagedEntityTable.tsx:524` (stable keys, KNG-136) |
| CRUD-5 step names | Done (KNG-137) | `components/FormWizard/WizardStepHeader.tsx` (names, `aria-current="step"` :105, :234; narrow list KNG-168) |
| CRUD-6 no Cancel | Partly (KNG-162) | `components/FormWizard/FormCancelAction.tsx`; rendered above the wizard `pages/FormWizardPage.tsx:1169-1172` |
| CRUD-12 duplicate / scaffold | Partly | export/import + bundled seeds: `FormConfigurationTable.tsx:82-88,235-245`, `DisplayConfigurationTable.tsx` (KNG-138/139) |
| CRUD-13/14 explicit Publish (display) | Partly | `DisplayConfigurationTable.tsx:166-170` Draft/Published badge, `:260-270` Publish |
| NAV-1/SEC-8 staff routes, landing, returnTo | Done | `App.tsx:124-170` `StaffRoute node={CONTENT_PERMISSION_NODE}`; `utils/returnTo.ts` |
| NAV-2 account menu on click, Logout on page | Done | `Navigation.tsx:348-405`; `AccountManagementPage.tsx:428-451` |
| NAV-3 404 | Done | `App.tsx:298`, `pages/NotFoundPage.tsx` |
| NAV-4 page titles | Partly | `hooks/usePageTitle.ts`; 26 pages set one, **10 do not** (see §4, N1) |
| MKT-1/2/3 short term | Done | `public/images` 2.7 MB total (was 62 MB); `public/index.html:9-18` title + description; `public/manifest.json`; `LandingPage.tsx:23-66` server address + Copy, how to join |
| X-6 Fluent | Done (KNG-71) | no Fluent in `package.json`; Inter is applied (`index.css:5-10`); `knk-web-app/CLAUDE.md:44` corrected |
| Shell logo hot-linked from Dropbox, React favicon | Done | `Navigation.tsx:301-310` `public/brand/knk-shield.png`; favicon replaced (`d100d84`) |
| X-12 dead code (most) | Done (KNG-71/64) | `ImageUploadModal`, `EntityTypeConfigurationPage`, `RegisterSuccessPage` gone |

---

## 2. Per sub-issue

### #38 KNG-142: styling quick wins (SET-11, X-8)

| Finding | Status | Evidence |
|---|---|---|
| `.btn` lacks `inline-flex items-center` | Still open (mitigated per call) | `index.css:39-43`; call sites add `flex items-center` themselves (e.g. `FormWizard.tsx:2737,2746,2755`, `Navigation.tsx:416`) |
| `primary-dark` undefined | Still open | `tailwind.config.js:7-10` defines only `DEFAULT`/`light`; **28 uses in 18 files**, including the primary CTAs on `AccountManagementPage.tsx` (4), `LoginForm.tsx` (3), `RegisterForm.tsx`, `ForgotPasswordPage.tsx`, `ResetPasswordPage.tsx`, and the non-danger button of every `FeedbackModal` (`FeedbackModal.tsx:166`), so none of them has a hover state |
| `btn-tertiary` undefined | Still open | one use: `FormWizard.tsx:2746` (Save Draft) |
| Game Settings input borders | Still open (not re-measured live) | `.input` uses `border-slate-300` (`index.css:60-63`); not verified visually |
| `text-gray-400` contrast | Still open, **worse** | 133 uses in 63 files (was about 109) |
| Lootbox announcement preview, "1 in N" odds | Still open | `MinecraftLegacyPreview` exists in `components/admin/gameSettings/` and is not reused in `components/lootbox/LootboxSettingsTab.tsx` |

Stale text: none; the counts are low.
**Recommendation:** keep it, but do it as one small PR now (about 1 h): define `primary-dark` and `btn-tertiary`, add `inline-flex items-center gap-2`
to `.btn`. Leave the `gray-400` sweep to #95 (tokens). The lootbox preview and odds bullets belong in #26 or the lootbox backlog, so move them.
**Priority: medium** (cheap, and every CTA and FeedbackModal button lacks a hover state).

### #33 KNG-143: shared component kit (X-2, X-3, X-5, X-9, X-10, SET-7, MOD-2 UI)

| Finding | Status | Evidence |
|---|---|---|
| X-2 feedback patterns | Partly done | `alert`/`confirm` are gone; `useConfirm` (`hooks/useConfirm.tsx`) supports `danger`. **No success toast**: `ToastRegion.tsx` is error-only (red border, `AlertCircle`, fed only by `errorHandler`). Success is still a blocking `FeedbackModal` with a 3 s auto-redirect: `FormWizardPage.tsx:551,623,720,755,892,997,1005`, `FormConfigBuilder.tsx:458-461` |
| ConfirmDialog with a required reason (MOD-2 UI) | Still open | `ConfirmOptions` (`useConfirm.tsx:4-14`) has no reason field |
| X-3 Dialog a11y | Still open | 16 files with `fixed inset-0` overlays and 12 with `role="dialog"`; **1** has `aria-modal` (`admin/minecraftCatalog/MaterialMergeTargetDialog.tsx:80`). `FeedbackModal.tsx:110-118`: no Escape, no focus trap, no initial focus, and the backdrop click closes it. In `ChildFormModal.tsx:222-223` and `JoinEntityFormModal.tsx:58-59`, the backdrop `onClick` sits under a full-screen `z-50` wrapper, so outside clicks probably do *not* close child forms now (❓ verify live; this contradicts CRUD-6's "backdrop closes child forms") |
| DataTable | Still open | the same `<tr onClick>` pattern in `PagedEntityTable.tsx:529-537`, `UserModerationPage.tsx:287-291`; no shared pager |
| SettingsPage shell | Still open | only `CurrencyPolicyPage.tsx`, Siege and Roads have a dirty state |
| X-10 `format.ts` | Still open | no `utils/format*`; `parseUtc` lives in a component (`components/currency/BalanceLedgerTable.tsx:11`) used by 5 files; 6 local `numberFormat` constants; `'en-US'` in 20 files |
| X-5 labels | Partly | 74 `htmlFor` across 277 `<label>` (was 53/221). The most-used field, the free-text string in FormWizard, has a `<label htmlFor={field.fieldName}>` (`FieldRenderers.tsx:434`) but its `<textarea>` has **no id** (`:458`) |

Stale text: "Remove the remaining `alert`/`confirm` (with KNG-82)" is done (KNG-82 merged 2026-10-17). "12 hand-rolled overlays"
is now 16. "53 of 221" is now 74 of 277.
**Recommendation: re-scope it.** Drop the alert/confirm bullet. Treat `useConfirm` as the ConfirmDialog API and extend it with
`requireReason` and danger styling. Split the issue in two:
**(a) "Feedback primitives"** (needed now by the dashboard hub): a success/info toast API (`toast.success()`) on `ToastRegion`,
an accessible `Dialog` that `FeedbackModal`, `ChildFormModal` and the builders' modals reuse, and `useConfirm` with a reason.
**(b) "Data/format primitives"** (later): `DataTable`/`Pager`, `format.ts`, a `<Field>` with `useId`, and the SettingsPage shell (this could move to #26).
**Priority: high** for (a), because it blocks the success toast that replaces the 3 s modal redirect in the CRUD hub; **medium** for (b).

### #30 KNG-144: admin IA (NAV-5, NAV-7, §4, X-4)

| Finding | Status | Evidence |
|---|---|---|
| NAV-5 flat IA | Still open, **worse** | `Navigation.tsx:25-53`: **16 flat links** (was 7) + Create New. `pickNavLayout` (`navLayout.ts`) degrades to icons or a menu when they don't fit, so on most laptop widths staff see 16 unlabeled icons |
| Economy only through Moderation | Still open | `UserModerationPage.tsx:195-219` (Balance log, Policy, Alerts, Invitations, Location orphans as buttons) |
| Moderation `exact` | Still open | `Navigation.tsx:45` (`exact: true`), so it isn't highlighted on `/admin/users/:id` or `/admin/economy/*` |
| Breadcrumbs | Still open | none in `src/` |
| Label/title mismatch | Partly | page titles now match ("Game settings", "Siege settings"); nav still says "Game Settings"/"Siege Settings" |
| Layout routes + error boundary per layout | Partly | one global `RouteErrorBoundary` (`App.tsx:91`); no layout routes; logged-out visitors get no nav on public pages (`App.tsx:86` `isLoggedIn && <Navigation>`, so `/leaderboards` and `/players/:username` have no header or home link) |
| NAV-7 double `navigate()` | Still open | `Navigation.tsx:157-158` and `:436-438` |
| NAV-7 Create New arrow keys | Still open | menu `tabIndex={-1}` with `onKeyDown` (`:424-429`), never focused |
| NAV-7 logged-in users on auth pages | Partly | `RegisterPage.tsx:23-25` redirects; forgot/reset don't |
| NAV-7 two `<h1>` | Done | the nav no longer has an `h1` (title is a `span`, `Navigation.tsx:311`) |

Stale text: "Several admin pages can only be reached by URL": every admin page now has a nav link or a Moderation
button; the real problem is that they are hidden behind Moderation. "error boundary each (X-4)": a global one exists.
**Recommendation: keep, and add explicitly:** a route-meta table that also drives `usePageTitle` (10 pages have no title,
N1), the grouping (Content: Dashboard/Forms/Catalogue · Gameplay: Game/Siege/Lootboxes/Discovery/Roads · Players:
Moderation/Invitations · Economy: Balance log/Policy/Alerts · Owner) and breadcrumbs that the form wizard and detail page share.
Fold NAV-7's double navigate into the CRUD-hub work (it is the Create New menu). **Priority: high** (it overlaps the CRUD hub;
16 icon-only links is real friction for staff).

### #39 KNG-145: entity lists (one line, per instructions)

CRUD-1 **still open** (`ObjectDashboard.tsx:49` `useState('')`, never reads `location.state`; `FormWizardPage.tsx:1004` still
sends `state.entityTypeName`), CRUD-2 **still open** (no toolbar "New"; Create New is a 19-type hard-coded list from
`config/objectConfigs.tsx`, used at `App.tsx:59-64`), CRUD-4 **still open** (`PagedEntityTable.tsx:529-537` `<tr onClick>`, `:651-658` no
`aria-sort`, icon buttons `title`-only `ObjectDashboard.tsx:~274-300`; keys and the phone toggle are fixed), NAV-6 **still open** (no admin page uses
`useSearchParams`; only auth pages and `FormWizardPage` do). Design: #177 and the 2026-10-24 dashboard handoff.

### #109 KNG-146: FormWizard edit mode (CRUD-5, 6, 8, 9, 10)

| Finding | Status | Evidence |
|---|---|---|
| CRUD-5 step names | Done (KNG-137) | `WizardStepHeader.tsx` |
| CRUD-5 clickable steps, jump | Still open; spelled out in **#68** | no `onClick` on step items in `WizardStepHeader.tsx` (only the disclosure and scroll buttons :69, :279, :296) |
| CRUD-5 Save on every step in edit mode | Still open | the Submit label appears only on the last visible step (`FormWizard.tsx:2762`) |
| CRUD-6 Cancel | Partly (KNG-162) | "Cancel form" sits *above* the wizard, outside it (`FormWizardPage.tsx:1169-1172`), and always asks "Leave this form?" even with no changes (`FormCancelAction.tsx` has no dirty check). After Cancel you stay on the Forms page, not the origin (`FormWizardPage.tsx:569-581`) |
| CRUD-6 actions at the top, no `<form>`, no sticky footer | Still open | `FormWizard.tsx:2733-2765` (toolbar in the header above the fields); no `<form>` |
| CRUD-6 unsaved guard | Still open | 0 `beforeunload` / `useBlocker` in `src/` |
| CRUD-8 blur validation | Still open | `onBlur={() => validateField(field)}` (`FormWizard.tsx:2942`) discards the returned string; the rules loop is still a placeholder (`:2386-2393`) |
| CRUD-8 Next silently does nothing | Partly | the step completion failure goes to `errorHandler` (`:2534`), which is now visible as a toast (X-1). An inline message is proposed in #88 item 5. No error summary or focus-first-error |
| CRUD-9 relation picker | Partly | still an inline `PagedEntityTable` (`FieldRenderers.tsx:1136,1435`); better columns (KNG-166) and pinned "Created in this form" rows (KNG-136) |
| CRUD-10 shared drafts | Still open | `FormWizardPage.tsx:163` `const userId = '1'`; the API trusts the client value (`FormSubmissionProgressController.cs:72-84`, service `:64-69`), so every admin's drafts are stored as user 1 |
| CRUD-10 two success landings | Still open | parent → display, else a modal + 3 s → `/dashboard` (`FormWizardPage.tsx:991-1007`); Cancel → Forms page |
| CRUD-10 single-line Name as textarea | Still open | `FieldRenderers.tsx:458-470` (`rows={3}`, no id) |

Stale text: "Coordinate with the open form wizard bugs (KNG-120, KNG-133, KNG-134, KNG-135) and KNG-53". **All of them are done**
(KNG-133..135 chain 2026-10-12/17, KNG-120 merged 2026-10-18, KNG-53 2026-10-10). "Builds on KNG-137" is also done.
**Recommendation: re-scope.** Move "clickable steps" to #68, which has the precise rules (link both ways). Keep: Save
from any step in edit mode, a sticky footer that holds Cancel (move `FormCancelAction` into it), a dirty flag (which also fixes
the always-shown "Leave this form?"), `useBlocker` + `beforeunload`, blur validation + error summary, per-user drafts
(server-side caller id, not client `userId`), and the textarea → input for single-line strings. Move CRUD-9 (combobox picker) to its own
low-priority issue. The success landing and Cancel return belong to #58 (returnTo); don't duplicate them. **Priority: high** (the footer,
guard and drafts sit on the CRUD-hub path).

### #71 KNG-147: builders (CRUD-11..14)

| Finding | Status | Evidence |
|---|---|---|
| CRUD-11 Save exits | Still open | `FormConfigBuilder.tsx:96-108,452-461` (success modal, auto `navigate(formsPagePath)` after 3 s); `DisplayConfigBuilder.tsx:80-96` same |
| CRUD-12 generate from metadata | Still open | no generator. **Partly** covered by bundled seeds plus Import (`ConfigurationImportPanel.tsx`, about 40 seed forms, CHANGELOG 2026-10-22) |
| CRUD-12 duplicate | Partly | Export JSON + Import works as a manual duplicate (`FormConfigurationTable.tsx:235-245`); no one-click Duplicate |
| CRUD-13 preview | Still open | no preview pane in either builder |
| CRUD-14 explicit Publish | Partly | Display configs: Draft/Published badge + Publish (`DisplayConfigurationTable.tsx:166-170,260-270`); the builder still has a "Save as draft" checkbox (`DisplayConfigBuilder.tsx:639-645`). Form configs have no draft concept |
| CRUD-14 make-default two-request client sequence | Still open | `FormConfigBuilder.tsx:426-445` (`getByEntityTypeName` → confirm → `handleRemoveDefault` → save) |
| CRUD-14 validation errors at the top, Save at the bottom | Still open (not re-measured) | `setError(...)` banner at the top (`FormConfigBuilder.tsx:353-390`) |

Stale text: "Related: KNG-138 (export/import) and KNG-40". Both are done; KNG-138 now *partly answers* Duplicate. Also missing:
the step condition editor (#88) lives in the same builder.
**Recommendation: keep, re-scoped:** (1) save in place + toast (needs #33a), (2) one-click Duplicate (a server-side clone,
or reuse the import path), (3) Generate from metadata, (4) Preview, (5) a server-side "make default" (one request). Note the overlap with #88
(`StepEditor`). **Priority: medium-high.** Save in place is S and high value; generate and preview are M–L and can wait for #83.

### #81 KNG-148: entity detail page (CRUD-15, 16, 17)

| Finding | Status | Evidence |
|---|---|---|
| CRUD-15 `/form/` route, TODO actions | Done / hidden | `DisplayWizardPage.tsx:13-28`; `ActionButtons.tsx:22` |
| CRUD-15 root sections get no Edit/Delete | Still open | `ActionButtons.tsx:34` returns null without `entityType`; root sections pass none |
| CRUD-15 entity name, Back, breadcrumb | Still open | the heading is the **display configuration's** name, not the entity's (`DisplayWizard.tsx:182` `{config.name}`); page title is the generic "Details" (`DisplayWizardPage.tsx:9`) |
| CRUD-16 Remove = delete | Mitigated (hidden), still to build | `ActionButtons.tsx:17-22`; the delete-on-remove handler is still present (`DisplayWizard.tsx:106-150`) |
| CRUD-17 raw "Error: {message}" | Still open | `DisplayWizard.tsx:45-50` |
| CRUD-17 hot edit `alert()` | Done | `DisplayField.tsx:21,174` inline `role="alert"` |
| CRUD-17 values look disabled, relations not links, collections unpaged | Still open (not re-measured live) | `DisplayField.tsx` / `CollectionSection.tsx` unchanged in shape |

Stale text: "The alpha quick-wins issue hides the broken relationship buttons for now" — done; the issue can say so.
**Recommendation: re-scope** into (a) the **page header** (entity display name, Edit → `/forms/:type/edit/:id?returnTo=`, Delete with
danger confirm, Back via returnTo, entity-specific `document.title`), which is part of the CRUD hub, and (b) **real Select/Unlink/Add**
(needs API support, M), and (c) readability polish. Do (a) with the dashboard work; (b) later. **Priority:** (a) high, (b) medium, (c) low.

### #26 KNG-149: settings (SET-3..6, MOD-6)

| Finding | Status | Evidence |
|---|---|---|
| SET-3 audit/author/concurrency/revert | Still open (except currency) | Game Settings: `settingsVersion` is a schema version, not a concurrency token (API `Services/GameSettingsService.cs:62`); no "last saved by" |
| SET-4 dirty indicator, unsaved guard | Still open on Game Settings and Lootbox | dirty logic only in `CurrencyPolicyPage.tsx`, Siege, Roads |
| SET-5 units/magic values | Still open | `LootboxSettingsTab.tsx:30-31` ("11 = never", "6 or more = off"), `SiegeConfigurationPage.tsx:74` (‰), `GameSettingsPage.tsx:492` (ticks), `CurrencyPolicyPage.tsx:193-198` raw "Sender title bracket id" |
| SET-6 risky toggles | Still open | kill switch is a plain checkbox saved with the form (`CurrencyPolicyPage.tsx:174-177`); lootbox type Enabled toggles at once (`LootboxTypesTab.tsx:81,170`); token rule toggle at once (`LootboxTokensTab.tsx:178`) |
| MOD-6 gating mismatch | Partly | most new routes are node-gated (`App.tsx:184-248`). **Still wrong:** `/admin/game-settings` and `/admin/siege-configuration` use the default `knk.admin.user.manage` (`App.tsx:171-181`, `Navigation.tsx:34-36` `staffOnly`), while the API needs `knk.admin.config` for every Game Settings write and the hub-domain read (API `Controllers/GameSettingsController.cs:33,42,68,85`) and `knk.siege.admin.manage` for the Siege PUT (`SiegeConfigurationController.cs:31`). A moderator sees an editable page, gets "The hub-eligible domains could not be loaded…" (a 403 read as an outage), and a refusal on Save |

Stale text: none material; "roads" is listed among the unaudited pages, which is still true.
**Recommendation: split.** **(a) MOD-6 route gates** (S: two `node=` props + nav `node:`, read-only mode) do now. **(b) SET-5/6**
(unit hints, confirms on the three toggles) is S–M and can use `useConfirm` today. **(c) SET-3** (API audit + concurrency + history) is M–L,
later. SET-4 goes with the #33b SettingsPage shell. **Priority:** (a) high (small, and it removes misleading errors), (b) medium, (c) low–medium.

### #122 KNG-150: performance and responsiveness (X-11, X-7)

| Finding | Status | Evidence |
|---|---|---|
| X-11 code splitting | Still open | 0 `React.lazy`/`lazy(` in `src/`; every page is imported statically in `App.tsx:1-56` |
| X-7 stacked padding | Still open | `App.tsx:87` `pt-16 p-8` + page containers |
| X-7 dashboard 30/70 split | Done | the explorer collapses to a drawer below the breakpoint (KNG-94) |
| X-7 phone overflow | Partly | lootbox and discovery tables now have `overflow-x-auto` (all tabs); **Moderation still doesn't** (`UserModerationPage.tsx:275`, 0 `overflow-x-auto` in the file) |

Stale text: "The ObjectTypeExplorer part is KNG-94" is done (merged 2026-10-17).
**Recommendation: keep it, but lower the priority.** The alpha sits behind Cloudflare Access with a handful of staff and testers, and anonymous bundle size
matters only once a public site is served from this app (see #104). Move the Moderation overflow fix to #119 (MOD-5).
**Priority: low.**

### #119 KNG-151: player profile for staff (MOD-3 part 1, MOD-4, MOD-5)

| Finding | Status | Evidence |
|---|---|---|
| MOD-4 one long page | Still open, **longer** | about 16 sections now (`PlayerProfilePage.tsx:416-888`: Access card (new, KNG-214), Account, Adjust balance, Groups, Premium, Permissions, Kits, Discoveries, Statistics, Ledger, PMs, Data deletion, Audit, …); `navigate(-1)` Back (`:344,:368`) |
| MOD-3 freeze/unfreeze, timeline, paged audit | Still open | no freeze UI (`grep -i freeze` in the page: 0) |
| MOD-2 errors drop the API message | Done | `apiRefusalReason(err)` at `:213,227,249,265,295,312,326` |
| MOD-2 remove group without confirm/aria-label | Still open | `:586-595` icon-only `X`, `title` only, no confirm. Revoke node has an aria-label (`:706`) but no confirm |
| MOD-5 rows not links, phone overflow | Still open | `UserModerationPage.tsx:287-291` `<tr onClick>`; no `overflow-x-auto` |
| MOD-5 tab in URL | Still open | `UserModerationPage.tsx:35` |
| KNG-39 duplicate panels | Done | ACTIVE_SESSIONS (merged 2026-10-17) |

Stale text: "Related: KNG-39" is done.
**Recommendation: keep.** Add the MOD-2 confirm/reason items here (they need the #33a reason confirm), plus the Moderation overflow.
**Priority: medium** (the support load with a handful of players is small, but the profile is the staff tool used most).

### #117 KNG-152: staff notes and support cases (MOD-3 phase 2)

Status: **still open**. Nothing exists (`components/currency/StaffNoteField.tsx` is the balance-adjust note, not player notes).
Stale text: none. **Recommendation:** keep it parked until the alpha bug reports show a need (as the issue says). **Priority: low.**

### #112 KNG-153: admin insights (SET-8, 9, 10)

| Finding | Status | Evidence |
|---|---|---|
| SET-9 KPIs/charts | Partly | owner-only world analytics, telemetry and player statistics exist (`pages/owner/OwnerAnalyticsPage.tsx`, `OwnerTelemetryPage.tsx`, `components/statistics/*`, KNG-34); no economy or lootbox KPIs, no admin overview |
| SET-8 economy settings page | Still open | — |
| SET-10 log totals, CSV, URL filters, time zone | Still open | no `useSearchParams` in admin pages; no CSV export |

Stale text: none ("reuse KNG-34" is now actionable: the data exists).
**Recommendation:** keep it. Re-scope SET-9 to "admin overview that reuses the KNG-34 aggregates + a currency minted/sunk tile".
**Priority: low** (closed alpha; the owner already has analytics).

### #108 KNG-154: player area `/me` (PLY-1..4, AUTH-5)

| Finding | Status | Evidence |
|---|---|---|
| PLY-1 raw UUID, unformatted balances, link CTA at the bottom | Still open | `AccountManagementPage.tsx:174-186` (raw `user.uuid`, `{user.coins}`), `:389-410` link card after the stats sections, `:420` UUID again |
| PLY-1 email verified shown | Done | `:285-289` badge |
| AUTH-5 labels/autocomplete/logout | Done | `:222-247` `htmlFor`/`autoComplete`; `:428-451` Log out / all devices |
| AUTH-5 no `<form>` (Enter does nothing) | Still open | no `<form`/`onSubmit` in the page |
| PLY-2 Reference column, raw UTC | Still open | `AccountTransactionsPage.tsx:124,131,138` (`toISOString()` sliced, `publicId` column) |
| PLY-3 progression | Partly | `MyStatisticsSection`, `MyDiscoveriesSection`, `/leaderboards`, `/players/:username`, `MyDataDeletionSection` added (KNG-34) |
| PLY-4 raw node on "Staff only" | Still open | `StaffRoute.tsx:48-50` |

Stale text: none. **Recommendation:** keep, but pull **PLY-4** (S) and the **AUTH-5 `<form>`** fix (S) into a quick PR. The `/me` split itself waits
for #83 feedback. **Priority: medium** for the quick bits, **low** for `/me`.

### #104 KNG-155: public site (MKT-3..5)

| Finding | Status | Evidence |
|---|---|---|
| MKT-3 meta/OG/sitemap/prerender | Partly | title, description and manifest done (`public/index.html:9-18`); no OG/Twitter tags, no sitemap, `robots.txt` allows all; no prerender |
| MKT-4 slideshow controls invisible, no reduced motion, no header for logged-out visitors | Partly | the landing uses `<Slideshow decorative>` (`LandingPage.tsx:101`), so no controls (obsolete); auto-advance has no `prefers-reduced-motion` (`Slideshow.tsx`); the logged-out header is still missing (`App.tsx:86`) |
| MKT-5 `RegisterSuccessPage`, two timers | Obsolete / Done | the page is deleted; register has one redirect timer (`pages/auth/RegisterPage.tsx:33`) |
| Guides, `/game/*` | Still open | — |

Stale context: the app at `app.knightsandkings.net` sits **behind Cloudflare Access** (2026-10-24 Phase 6 report §1). Only
the sign-up paths bypass it, so SEO, OG cards and prerendering in this CRA app have no audience. KNG-64 plan Q3 (a separate Astro site) is
effectively the answer.
**Recommendation: re-scope** to "separate public site (knightsandkings.net)", and drop the MKT-3 prerender/SEO work from the web app.
Keep the in-app bits small: a public header for logged-out pages and reduced motion. **Priority: low** until open beta.

### #98 KNG-156: content system

Status: **still open**; nothing built. Depends on the #104 decision. **Recommendation:** keep, but block it on #104. **Priority: low.**

### #95 KNG-157: rebrand tokens (§11.3–11.4)

| Item | Status | Evidence |
|---|---|---|
| Token layer | Still open | `tailwind.config.js:7-10` `primary #2563eb`; no CSS variables; `fontFamily.sans: Inter` (not Lato) |
| Undefined `primary-dark` | Still open | see #38 |
| Raw colour sweep | Still open | 133 `text-gray-400`; gray/slate mix |
| Fluent `BrandVariants` part | Obsolete | Fluent removed (KNG-71) |

Stale text: none, except that any Fluent mention in the report's §11.3 no longer applies.
**Recommendation:** keep, and merge #38's token parts in. Do it after #33a so new primitives use tokens. **Priority: low–medium**
(brand matters little in a staff-only alpha, but tokens make later restyling cheap).

### #92 KNG-158: rebrand phases 2–4

| Item | Status | Evidence |
|---|---|---|
| Logo/wordmark, favicon set | Partly | self-hosted shield PNG (`public/brand/knk-shield.png`), favicon/PWA icons replaced (`d100d84`); no SVG wordmark, no social share image |
| Dark public theme, brand font | Still open | — |

**Recommendation:** keep it as one rebrand epic with #95 (or make it a sub-issue of #95). **Priority: low.**

### #139 KNG-159: email verification

| Item | Status | Evidence |
|---|---|---|
| `EmailVerifiedAt` field | Done | API `Models/User.cs:309` (kept in step with `EmailVerified` until KNG-159 retires the bool) |
| Verified by invite link | Done | `Services/Invitations/InvitationService.cs:525-526` |
| Email template | Done | `Services/Email/EmailKind.cs:13,42` (`EmailVerification`) |
| Verify/resend endpoints, re-verify on change, banner | Still open | no verify endpoint in `Controllers/`; email change clears verification (`UserService.cs:1395-1396`) but nothing re-verifies |
| Real SMTP | Done | 2026-10-24 Phase 9: Postfix relay to Gmail, `Email__Transport=Smtp` |

Stale text: "The alpha runs `Email:Provider=Log` because the NAS backend network has no egress" is **wrong now** (a mail relay has run since 2026-10-24).
"An `EmailVerifiedAt` field" already exists.
**Recommendation:** keep it, and update the text: what's left is endpoints + token store + resend + re-verify on change + web banner/page.
**Priority: medium** (before open beta; invite-only sign-up already verifies most emails).

### #64 KNG-160: cleanup tiers 2–3

| Tier 2 item | Status | Evidence |
|---|---|---|
| 1 RegisterSuccess/link-code leftovers | Done | no `RegisterSuccess` in `src/` |
| 2 ImageUploadModal | Done | gone |
| 3 `objectConfigs` dead sections | Still open | `config/objectConfigs.tsx` 1,213 lines |
| 4 duplicate `useEnrichedFormContext` | Likely done | `hooks/useEntityMetadata.ts` is 305 lines (was ~576); no copy inside |
| 6 `gateCoordinates.ts` | Still open | `utils/gateCoordinates.ts` present |
| 7 `ConfigurationHealthPanel.test.simplified.tsx` | Still open | present |
| 8 Cypress broken | Still open (not re-run) | `cypress/`, `cypress.config.ts` present |
| Tier 3 logging/rxjs | Still open | `rxjs` in `utils/logging/index.ts:2`, `services/cloudflareAccess.ts:1` |
| Tier 3 UI duplicates | Still open | overlaps #33 |
| §5 debug logs | Partly | 58 `console.log` in 13 files (was 78); the hard-coded `isDebugField = Number(field.id) === 4` block is still at `FormWizard.tsx:2798`; 39 `// changed:`/`// added:` markers left |
| Tier 3 bugs | Partly | `/form/` fixed; `userId = '1'` still at `FormWizardPage.tsx:163` (belongs to #109) |

Stale text: none, though the issue should drop Tier 2 items 1, 2 and 4.
**Recommendation:** keep as low-priority hygiene, but **do the `FormWizard.tsx` debug-log removal before or with #109**, since it is the same file.
**Priority: low.**

### #83 KNG-161: think-aloud validation

Status: **still open** (no report under `docs/reports/`). Some tasks are now partly moot: "create a Grade with 0
stars" (CRUD-7 fixed) and "log out on a phone" (NAV-2 fixed) can become quick regression checks.
**Recommendation:** keep it, and run it **after** the CRUD hub ships, so the sessions test the new flow rather than known-broken ones. Swap the
fixed tasks for "edit one field on step 3 of a Town and get back to where you were" and "build a Tag form and try it". **Priority: medium.**

---

## 3. Related, not sub-issues (one line each)

- **#58 KNG-60 return to origin:** still fully open. Its "quick win" `location.state` is still ignored (`ObjectDashboard.tsx`
  has no `useLocation`). Its stale bits: the `/form/` route bug it describes is fixed, and FormWizard now has Cancel (KNG-162)
  but no `onCancel` return. `utils/returnTo.ts` already has the sanitizer it asks for (built for login, reusable).
- **#68 KNG-184 click step to jump:** still open; it is the concrete spec for #109's CRUD-5 "clickable steps". Treat it as the owner.
- **#73 KNG-183 M2M direct pick:** still open; touches `ManyToManyRelationshipEditor.tsx`/`FormWizard.tsx`; independent of the hub.
- **#88 KNG-274 step conditions:** still open; overlaps #71 (builder `StepEditor`) and #109 (inline failure message, CRUD-8) and
  #68 (jump check must run Entry conditions).
- **#44 KNG-185 FeedbackModal "Show details":** still open; touches `FeedbackModal.tsx`, so sequence it after #33a's Dialog
  rewrite (or build it into the new Dialog).
- **#50 KNG-62 group permission nodes:** still open; a natural first "custom panel on the detail page" for #81.
- **#63 `tsc` errors:** test-file only; unrelated to UX.
- **#72 / #148 User form:** both still open; they block "edit any entity from the dashboard" for User rows. Decide whether User
  leaves the generic CRUD hub (the player profile already edits users).

---

## 4. New UX problems not covered by any issue (verified in code)

1. **N1. 10 pages have no page title.** `RoadsAdminPage`, `EmailLogPage`, `InvitationsPage`, `MinecraftCatalogAdminPage`,
   `LeaderboardsPage`, `OwnerAnalyticsPage`, `OwnerPrivacyPage`, `OwnerTelemetryPage`, `LocationRetentionPage`,
   `PublicPlayerProfilePage` (0 `usePageTitle`). The ones that have one are generic ("Dashboard", "Details", "Player profile"), so tabs
   can't be told apart. Fits #30 (route-meta table).
2. **N2. The Create New menu offers a type with no API mapping and misses about 15 that have one.** `config/objectConfigs.tsx`
   lists 19 types, including `itemType`, which has no case in `utils/entityApiMapping.ts`. Mapped types such as
   `itemblueprint`, `kit`, `grade`, `tag`, `titlebracket`, `enchantmentdefinition`, the siege set and `domainsubregion` are absent. Fits #39 CRUD-2 (metadata-driven menu).
3. **N3. Game Settings and Siege are gated on the wrong node** (detail under #26 MOD-6). A moderator sees an editable page, an
   outage-style message for a 403 ("could not be loaded … Reload the page"), and a refusal on Save. MOD-6 covers the idea, but no issue names these two routes.
4. **N4. Detail page heading shows the display configuration's name, not the entity's** (`DisplayWizard.tsx:182`), e.g. a seed
   config name instead of "Town Cinix". Fits #81 (header).
5. **N5. FormWizard free-text label not tied to its field.** `<label htmlFor={field.fieldName}>` with an id-less `<textarea>`
   (`FieldRenderers.tsx:434,458`). This affects the most common field type in every admin form (screen readers, click-to-focus). Fits #33/#109.
6. **N6. Every `FeedbackModal` confirm button and the auth/account primary CTAs have no hover state** (`hover:bg-primary-dark`
   undefined; `FeedbackModal.tsx:166`, 28 uses). #38 mentions the class, but not that it hits every confirm dialog and the login button.
7. **N7. "Leave this form?" is asked even when nothing changed** (`FormCancelAction.tsx`, no dirty flag), and Cancel/Submit
   land in different places (Forms page vs Dashboard). Partly in #109/#58, but the always-on prompt is new with KNG-162.
8. **N8. Logged-out visitors on public pages (`/leaderboards`, `/players/:username`, `/link`, `/join`) get no header, logo or
   login link** (`App.tsx:86`). MKT-4 mentioned it for the landing page only; with invitations, `/join` and `/link` are now real entry points.
9. **N9. Hard-coded debug logging in production builds.** `isDebugField = Number(field.id) === 4` + `console.log` in
   `FormWizard.tsx:2798-2825`, plus 58 `console.log` calls overall. That means console noise for staff and a field-id-4 special case. Fits #64.
10. **N10. Drafts of all admins are stored as user 1 on the server** (`FormWizardPage.tsx:163`, API trusts the body). CRUD-10 says
    "shared", but the audit/data-ownership angle (it misattributes drafts and provenance `CreatedEntitiesJson`) is new since KNG-64 added real users.
    Fits #109, as an API change.

---

## 5. Overlap map: dashboard as CRUD hub + form wizard

Components the hub and wizard work will touch, and which issues also touch them:

| Component / file | Hub/wizard change | Other issues touching it | Sequencing |
|---|---|---|---|
| `components/ObjectDashboard/ObjectDashboard.tsx` | URL state, "New X", returnTo on Edit/View, refresh after return, success toast | #39, #58, #30 (breadcrumb/title), #72/#148 (User rows) | Hub first; #30 adds breadcrumbs on top |
| `components/PagedEntityTable/PagedEntityTable.tsx` | controlled `query`/`onQueryChange`, toolbar actions, page-size selector, rows as links, `aria-sort` | #39 CRUD-3/4, #33b DataTable, FormWizard pickers (`FieldRenderers.tsx:1136,1435`), #109 CRUD-9 | Add the controlled mode *without* breaking the picker use; DataTable extraction (#33b) later |
| `components/ObjectTypeExplorer/ObjectTypeExplorer.tsx` | selection from URL | #30 (grouped nav) | low conflict |
| `components/Navigation.tsx` + `config/objectConfigs.tsx` | metadata-driven Create New, fix double navigate, arrow keys | #30 (grouped sidebar), #38 | Do the Create New rewrite in the hub; #30 restructures the rest |
| `pages/FormWizardPage.tsx` | returnTo on complete/cancel, open form in URL (`?config=`/`?progress=`), success toast instead of modal, per-user drafts | #58, #109 (CRUD-10), #71 (builder links), #64 (console logs) | Hub/#58 first; #109 next |
| `components/FormWizard/FormWizard.tsx` | `onCancel` prop, sticky footer, dirty flag, blur validation, Save in edit mode | #109, #68 (step jump), #88 (Entry conditions + inline message), #73 (M2M), #64 (debug block) | One owner at a time. Suggested order: #64 debug cleanup → #109 footer/guard → #68 → #88 |
| `components/FormWizard/WizardStepHeader.tsx` | (none for the hub) | #68, #109 | — |
| `components/FormWizard/FormCancelAction.tsx` | move into the wizard footer, dirty-aware, `navigateBack(returnTo)` | #109, #58 | together |
| `components/ToastRegion.tsx` + `utils/logging` | add a success/info variant and a `toast()` API | #33a, #64 (rxjs → pub/sub) | **#33a before the hub's success toast** |
| `components/FeedbackModal.tsx` / `hooks/useConfirm.tsx` | delete confirm with name, unsaved-changes prompt | #33a (Dialog a11y, reason), #44 (Show details), #119 (MOD-2) | #33a Dialog first, then #44 builds on it |
| `utils/returnTo.ts` | reuse `sanitizeReturnTo`, add `buildReturnTo`/`navigateBack` | #58, #30 (breadcrumb "back") | hub |
| `pages/DisplayWizardPage.tsx`, `components/DisplayWizard/*` | page header (name, Edit/Delete/Back with returnTo), entity title | #81, #30 (breadcrumb), #50 (group panel) | do #81(a) with the hub |
| `components/FormConfigBuilder/*`, `components/DisplayConfigBuilder/*` | Back to origin (returnTo), save in place + toast | #71, #88 (`StepEditor`), #33a | after #33a |
| `App.tsx` | route params, maybe layout routes | #30, #122 (lazy), #26 (route gates) | #26a is a two-line change; #30 layout routes after the hub |

Key dependencies:
- **#33 → hub:** the success toast and accessible confirm are needed by the hub (replacing `FeedbackModal` + `autoCloseMs: 3000`
  redirects). Only the small "feedback primitives" half (#33a) is a blocker.
- **#109 ↔ hub:** Cancel, the unsaved guard and the success landing overlap directly. Either the hub issue owns `onCancel` + returnTo and
  #109 owns footer, dirty flag and guard, or one change does both. Don't run them in parallel branches on `FormWizard.tsx`.
- **#30 ↔ hub:** the hub should expose a simple `{label, to}[]` trail (Dashboard › Town › Edit "Cinix") that #30's breadcrumb
  component later renders. The route-meta table (#30) should also own page titles (N1).
- **#81(a) ↔ hub:** the detail header is the hub's "View" destination; do it in the same pass.

---

## 6. Suggested priorities (closed alpha, a handful of admins and players)

| Issue | Recommendation | Priority |
|---|---|---|
| #177 + #58 + #39 (dashboard CRUD hub) | first; see the plan | **high** |
| #33 component kit | split: (a) toast/Dialog/confirm-with-reason, (b) DataTable/format/Field/Settings shell | (a) **high**, (b) medium |
| #109 FormWizard edit mode | re-scope: move clickable steps to #68; keep footer/Cancel/guard/blur/per-user drafts/single-line input; CRUD-9 separate | **high** |
| #30 admin IA | keep; add page titles (N1), grouping, shared breadcrumbs | **high** |
| #81 detail page | split: (a) header with the hub, (b) link/unlink, (c) polish | (a) high, (b) medium, (c) low |
| #26 settings | split: (a) MOD-6 route gates now, (b) SET-5/6, (c) SET-3 | (a) **high**, (b) medium, (c) low–medium |
| #71 builders | keep, re-scoped (save in place first; Duplicate; then generate/preview; server-side default) | medium-high |
| #38 styling quick wins | do now as one tiny PR; token bits → #95, lootbox bits → #26 | medium |
| #83 think-aloud | keep; run after the hub ships; refresh the task list | medium |
| #119 profile for staff | keep; add MOD-2 confirms and Moderation overflow | medium |
| #108 `/me` | keep; pull PLY-4 + AUTH-5 `<form>` into a quick PR | medium (quick bits) / low |
| #139 email verification | keep; fix the stale SMTP text, narrow the scope | medium |
| #95 tokens | keep; absorb #38 tokens; after #33a | low–medium |
| #64 cleanup | keep; do the FormWizard debug-log part before #109 | low |
| #122 perf/responsive | keep; KNG-94 part done; Moderation overflow → #119 | low |
| #112 insights | keep; reuse KNG-34 aggregates | low |
| #104 public site | re-scope to a separate site (the app is behind Access) | low |
| #92 rebrand 2–4 | merge under #95 as one rebrand track | low |
| #98 content | keep, blocked on #104 | low |
| #117 support cases | keep parked | low |

---

## 7. Stale text in the parent issue #24

- "The alpha safety quick wins (in progress)": KNG-141 was **merged 2026-10-18** (web-app `5404801`, ACTIVE_SESSIONS row 112).
- Related issues KNG-82, KNG-39, KNG-137, KNG-53 and KNG-40 are **all Done** (ACTIVE_SESSIONS rows 119, 116; CHANGELOG 2026-10-09/10/17).
- "Already done" should also list: the form wizard chain (Cancel form, step names, export/import, refusal messages,
  confirmations in-app), KNG-61/94 (explorer), and Display Draft/Publish.
- Also outdated: `docs/architecture/web-app-architecture.md:19,168,222` still says the toasts are plumbed in `App.tsx` lines 40–58. They are now
  `components/ToastRegion.tsx`.
