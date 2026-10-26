# Dashboard, form wizard and realtime chain — progress report

**Status:** In progress — link 1 in review; links 3 and 4 running (2026-10-26)
**Last updated:** 2026-10-26
**Charter:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) · **Coordinator prompt:**
[2026-10-26-ux-realtime-coordinator-prompt.md](../ai-agents/handoffs/2026-10-26-ux-realtime-coordinator-prompt.md)
**Base at start:** knk-web-app `main` `0d61270`, knk-web-api `master` `6f08383`, knk-plugin `main` `ee35fb1` (re-check:
later merges on the trunks happen; each link records its own base).

## Summary

Status values: `ready` (gate open), `waiting: <gate>`, `in progress`, `in review` (pushed, waiting for the developer's
test), `merged`, `blocked: <reason>`.

| Link | Issues | Branch | Status | Started | Heads (api / web-app / plugin / workspace) | Tests vs baseline |
|---|---|---|---|---|---|---|
| 1 | #177 (link 1), #58 | `claude/kng-60-dashboard-hub` | in review | create_session session_01Lr2FyBpZG3fDCq51LuFgSM, 2026-10-26 (a first subagent run was stopped by the developer before pushing anything) | — / `df78e73` / — / `7143596` | web-app 1232/1232 (baseline 1214/1214), suites 195 (193); `tsc` 9 errors = baseline; build OK, same warnings |
| 2 | #185, #38, #192 | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | in progress | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — | — |
| 3 | #177 (link 2), #81, #39 (menu) | `claude/kng-60-dashboard-hub` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — / `9a203f8` / — / `186c851` | web-app 1270/1270 (baseline 1232/1232), suites 201 (195); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 4 | #178 | `claude/realtime-signalr` | in progress | create_session session_01CKkjS6mCCEw1VUWVwZJqnA, 2026-10-26 | — | — |
| 5 | #64 (FormWizard), #109, #186 | `claude/form-wizard-edit-mode` | waiting: links 1 and 3 merged | — | — | — |
| 6 | #179 | `claude/realtime-signalr` | waiting: link 4 done | — | — | — |
| 7 | #180 | `claude/world-task-hardening` | waiting: link 5 merged | — | — | — |
| 8 | #181 | `claude/realtime-signalr` | waiting: link 6 done, link 7 merged | — | — | — |
| 9 | #39 (rest), #177 follow-up | `claude/entity-lists-url-state` | waiting: link 3 merged | — | — | — |
| 10 | #182 | `claude/realtime-signalr` | waiting: link 8 done | — | — | — |

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that unblock a gate,
flagged decisions.)

- **Links 1 and 3 together:** one branch, one test pass, one merge.
- **Test link 1** (#177 link 1, #58): web-app `claude/kng-60-dashboard-hub` `df78e73`; live checklist
  [guides/dashboard-return-smoke-test.md](../guides/dashboard-return-smoke-test.md) on workspace branch
  `claude/kng-60-dashboard-hub` `7143596`. Link 3 continues the same branch, so links 1 and 3 can be tested and merged
  together.
- **Test link 3** (#177 link 2, #81, #39 menu): web-app `claude/kng-60-dashboard-hub` `9a203f8`; live checklist
  [guides/dashboard-return-smoke-test.md](../guides/dashboard-return-smoke-test.md) sections 8–14 on workspace branch
  `claude/kng-60-dashboard-hub` `186c851`. Flags L3-1…L3-9 (link 3 block) are reversible defaults.
- **Merge links 1 + 3** (web-app and workspace `claude/kng-60-dashboard-hub`) to open link 5 (form wizard) and link 9.
- **Flags L1-1…L1-7** (link 1 block) are reversible defaults; answer only if you disagree. L1-1: a Submit without
  `returnTo` lands on `/dashboard/{type}`, not `/forms/{type}`.

## Coordinator notes

- 2026-10-26: the developer pre-approved attaching `PandiO/knk-plugin`, `knk-web-app`, `knk-web-api`, `knk-dev-db-seed` and `knk-workspace` with `add_repo` (access push) for the coordinator and every link session it creates for this chain. Link prompts carry this as one appended sentence; it was also sent to link 1's session.

## Follow-ups filed by links

- Link 1: comment on [#63](https://github.com/PandiO/knk-workspace/issues/63): `tsc --noEmit` on web-app `main` has 9
  test-file errors, not 2 (adds `categoryTree.test.ts` ×5 and `cloudflareAccess.test.ts` ×1).

---

<!-- Link blocks are appended below, in the order the links finish. -->

## Link 1 — #177 (link 1), #58: dashboard type in the URL, returnTo, submit pending state, success toast

**Started:** create_session `session_01Lr2FyBpZG3fDCq51LuFgSM`, 2026-10-26; finished 2026-10-26. `add_repo` for knk-web-app
was refused once (the request came from an automated message), then allowed after the developer approved it in the
session.
**Base:** knk-web-app `main` `0d61270` (unchanged at the end; nothing to merge in). knk-workspace branch from `main` `bc367b5`.

**Commits**
- knk-web-app `claude/kng-60-dashboard-hub`: `2ee08cc` success toasts on `ToastRegion`; `05cc2c8` dashboard type in the
  URL + Edit carries `returnTo`; `df78e73` submit pending state, entity saved before the draft is Completed. Head **`df78e73`**.
- knk-workspace `claude/kng-60-dashboard-hub`: `7143596` web-app architecture, CHANGELOG (Unreleased), smoke test
  `guides/dashboard-return-smoke-test.md` + guides README row.

**What changed (web-app)**
- `/dashboard/:entityName` route (App.tsx); `ObjectDashboard` takes the type from the URL (case-insensitive), puts an
  explorer pick in the URL, reopens the last viewed type on bare `/dashboard` (`utils/lastDashboardType.ts`, localStorage
  `knk.dashboard.lastEntityType`), else the default as before; an unknown type is replaced and gets no table meanwhile.
- `utils/returnTo.ts`: `readReturnTo`, `buildReturnTo`, `withReturnTo`, `dashboardPath`, `editFormPath`, `newFormPath` on
  the existing sanitizer. Dashboard Edit and the category "Reassign Parent" action carry `returnTo`.
- `FormWizard`: the last step saves the progress as `InProgress`, **awaits** `onComplete`, and marks it `Completed` only
  after a successful save (`false` or a throw keeps it `InProgress`), then calls the new `onCompleted`. One pending state
  (`submitting` + a ref guard): Submit "Submitting…" disabled, Previous/Save Draft disabled, "Saving {Type}…" status line,
  `onSubmittingChange` for the page's Cancel. `saveProgress(status, knownId)` so the second save updates the same row.
- `FormWizardPage.handleComplete` returns `true`/`false`; after `onCompleted` it navigates to the parent display page,
  else `returnTo`, else `/dashboard/{type}`, with `toast.success("{Type} created./updated.")`; the 3 s modal is gone.
  Cancel goes to `returnTo` when there is one. `FormCancelAction` gets `disabled`. `ChildFormModal` returns `false` on a
  failed child save.
- `ToastRegion`: a `success` kind fed by `utils/toast.ts` (`toast.success`, `toast.error` = `logging.errorHandler`).
- `Navigation`: the Dashboard link is no longer `exact`, so it stays highlighted on `/dashboard/{type}`.

**Tests vs baseline** (Node 22, `npx npm@11 ci`; plain `npm ci` (npm 10) rejects the lock file as documented)
- `npm run test:ci`: **1232/1232 passed, 195 suites** (baseline 1214/1214, 193). New: `FormWizard.submitPending.ui.test.tsx`
  (4), `FormWizardPage.returnTo.test.tsx` (4), 5 dashboard URL cases, 4 `returnTo` cases, 1 toast case.
- `npx tsc --noEmit`: 9 errors, identical to baseline (all in test files; see #63 comment).
- `npm run build`: compiles with warnings; same warnings as baseline (line numbers shifted only).

**Flagged decisions (reversible)**
- **L1-1** No `returnTo` (form opened on the Forms page): Submit goes to `/dashboard/{type}` (before: `/dashboard` on its
  first type); Cancel stays on the Forms page as before. #177's fallback order lists `/forms/{type}` second; a Forms-page
  submit landing on the dashboard type matches today's behaviour better.
- **L1-2** If marking the draft `Completed` fails after the entity was saved, the page still leaves with the success toast
  (the entity exists); that draft stays `InProgress` in Saved Progress and the error toast says the progress save failed.
- **L1-3** Success toast stays 5 s (errors 8 s), text "{Type} created." / "{Type} updated." (type from metadata
  `displayName`).
- **L1-4** A failed parent-relationship update after a child create is now a red toast instead of a modal (the page
  leaves for the parent at once; the old modal was overwritten by the success modal anyway).
- **L1-5** "Step strip disabled while submitting": the strip has no clickable steps yet (#68), so only its disclosure
  button stays usable; nothing to disable.
- **L1-6** "New" with `returnTo`: `newFormPath` is ready, but today's only New entry point is the hard-coded nav "Create
  New" menu, which link 3 replaces (metadata-driven menu + dashboard "New {Type}"); not wired in link 1.
- **L1-7** One line outside the claimed files: `Navigation.tsx` Dashboard link `exact` dropped (see above).

**Deviations:** none from the plan; three `console.log`s in the submit path were kept (removed by link 5, #64).

**Live checklist:** [guides/dashboard-return-smoke-test.md](../guides/dashboard-return-smoke-test.md) (feature branch
`claude/kng-60-dashboard-hub` until merged).

**Deploy notes:** web app only. No API, plugin, migration, setting or script.

**Follow-ups:** #63 comment (tsc errors beyond the 2 known). Nothing else filed.

**Notes for later links**
- Link 3: use `newFormPath(type, buildReturnTo(location))` for "New {Type}" and the empty state, and
  `editFormPath`/`withReturnTo` for the detail page header; the breadcrumb can read `readReturnTo(searchParams)` on the
  Forms page. The dashboard's `selectType` and `selectedIsKnown` are the hooks for the flat explorer.
- Link 5 (#109/#64): the submit window now lives in `FormWizard` (`submitting`, `advancingRef`, `onSubmittingChange`); a
  sticky footer should reuse it. `onComplete` must keep returning `false` on a refused save.
- Link 9: `buildReturnTo(location)` already includes the query, so page/search/sort in the URL come back for free.
- Tests mocking `useEntityMetadata` must return one stable object; a fresh array per render makes `FormWizardPage`'s column
  effect loop forever.

## Link 3 — #177 (link 2), #81, #39 (Create New menu): dashboard as the CRUD hub

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-10-26; finished 2026-10-26. Ran at the same
time as link 4 (other repos).
**Base:** link 1's head, knk-web-app `claude/kng-60-dashboard-hub` `df78e73` (web-app `main` `0d61270` already in it, no
merge needed). knk-workspace `claude/kng-60-dashboard-hub` `7143596` with `origin/main` `999fe1d` merged in (`be1499d`).

**Commits**
- knk-web-app `claude/kng-60-dashboard-hub`: `d524f51` open form without the explorer + breadcrumb, Entity setup title,
  decision-3 notice; `0d5ee6a` dashboard header New/Configure, flat explorer with marker, empty state, View disabled,
  User Edit → player profile; `6c77f27` detail page header (#81); `9a203f8` metadata-driven Create New menu, nav
  "Entity setup". Head **`9a203f8`**.
- knk-workspace `claude/kng-60-dashboard-hub`: `be1499d` merge of `main`; `9234f3f` architecture, reading guide, "Entity
  setup" in two smoke tests, CHANGELOG, smoke test sections 8–14, guides README; `186c851` proposal status. Head **`186c851`**.

**What changed (web-app)**
- `ObjectDashboard`: "New {Type}" (`newFormPath(type, returnTo)`) and a cogwheel "Configure {Type}" (`/forms/{type}`)
  next to the title; "New {Type}" in the empty table (`PagedEntityTable` `emptyState`, only without a search/filter).
  One flat explorer list; types without a published default display configuration are marked (`ObjectTypeExplorer`
  `marked`, crossed-out eye + hint) and their View / row click are disabled with the hint. View carries `returnTo`
  (`displayPath`). Edit on a User row → `/admin/users/{id}` (`entityEditPath`).
- `FormWizardPage`: an open form hides the explorer and shows `components/Breadcrumbs.tsx` with `utils/breadcrumbs.ts`
  `formTrail` (`{label, to?}[]`, from `returnTo`; else "Entity setup › {Type} › New {Type}"); `hooks/useEntityLabel.ts`
  names the edited entity. "New" without a default form configuration shows a notice (decision 3). Title "Entity setup".
- `DisplayWizardPage` + `DisplayWizard/EntityDetailHeader.tsx` (#81): entity name (`utils/entityLabel.ts`) instead of the
  display configuration's, type label, breadcrumb (`detailTrail`), Back (`returnTo`, else `/dashboard/{type}`), Edit
  (coming back to the page), Delete (danger confirm naming the entity, toast, back); tab title "{name} · {Type}";
  section actions carry `returnTo`. `DisplayWizard` takes `renderHeader`.
- `components/CreateNewMenu.tsx` (#39 CRUD-2): every metadata type with a create client
  (`entityApiMapping.hasCreateFunctionForEntity`), A–Z, icons from `objectConfigs`; one `navigate()`; filter box with
  ArrowUp/Down, Enter, Escape. `Navigation`: the old dropdown and its double `navigate()` removed; "Forms" → "Entity setup".

**Tests vs baseline** (Node 22, `npx npm@11 ci`)
- `npm run test:ci`: **1270/1270 passed, 201 suites** (baseline 1232/1232, 195). New suites: `breadcrumbs`, `entityLabel`,
  `CreateNewMenu`, `FormWizardPage.entitySetup`, `DisplayWizardPage.header`, `DisplayWizard.header`; new cases in
  `ObjectDashboard` (6, 4 updated for the flat list), `ObjectTypeExplorer` (1), `PagedEntityTable` (1), `returnTo` (3).
- `npx tsc --noEmit`: 9 errors, identical to baseline (test files, #63).
- `npm run build`: compiles; same 24 warnings in the same 15 files as baseline.

**Flagged decisions (reversible)**
- **L3-1** Create New (nav) comes back to `/dashboard/{type}` (Submit and Cancel), not to the page it was opened from, so
  the new entity is visible.
- **L3-2** Breadcrumb crumbs leave an open form without the "Leave this form?" question, like the nav links; the
  unsaved-changes guard (`useBlocker`) is link 5 (#109).
- **L3-3** The cogwheel opens `/forms/{type}` without `returnTo` (acceptance: builders still return to `/forms/X`).
- **L3-4** Decision 3: the dashboard doesn't pre-check for a default form; New always goes to
  `/forms/{type}?autoOpen=true`, which opens the form or, without a default, shows the notice on the setup page.
- **L3-5** Detail page Delete: a refusal is a red toast (stays on the page); the category "View children / Reassign
  parent" help stays on the dashboard only.
- **L3-6** User Edit → player profile needs `knk.admin.user.manage` (its route); a content-only admin is refused there.
- **L3-7** Create New lists every creatable metadata type (also child types such as BannerLayer, SiegeTeam, and User);
  `EntityTypeConfiguration.isVisible` is not applied (the dashboard doesn't either).
- **L3-8** The entity-metadata box stays above an open form; only the explorer is hidden.
- **L3-9** `ObjectTypeExplorer` keeps its `groups` support (no caller now); `objectConfigs` keeps its `itemType` entry
  (fallback list only).

**Deviations:** none from the plan. The "Edit {name}" crumb costs one extra GET of the entity per edit form.

**Live checklist:** [guides/dashboard-return-smoke-test.md](../guides/dashboard-return-smoke-test.md) sections 8–14
(feature branch `claude/kng-60-dashboard-hub` until merged); sections 1–7 are link 1.

**Deploy notes:** web app only. No API, plugin, migration, setting or script.

**Follow-ups:** none filed; nothing found outside the scope that isn't already an issue (#109 guard, #30 breadcrumbs in the
admin layout, #72/#148 User form).

**Notes for later links**
- Link 5 (#109): the breadcrumb (`handleBreadcrumbNavigate` in `FormWizardPage`) and Cancel both leave the form; the
  `useBlocker` guard should cover the crumbs too. `FormWizardPage` doesn't use `useLocation` (its tests mock the router
  without it).
- Link 9 (#39 rest, #177 follow-up): "Drafts (n)" and "New with: {config}" go next to the dashboard's New button
  (`ObjectDashboard` header). `PagedEntityTable` has the new `emptyState` prop; controlled mode should keep it.
- #30: `utils/breadcrumbs.ts` (`trailTo`, `formTrail`, `detailTrail`) and `components/Breadcrumbs.tsx` are the trail to
  reuse in the admin layout.
