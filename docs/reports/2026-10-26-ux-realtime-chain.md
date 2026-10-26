# Dashboard, form wizard and realtime chain — progress report

**Status:** In progress — link 1 in review (2026-10-26)
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
| 2 | #185, #38, #192 | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | waiting: link 1 done | — | — | — |
| 3 | #177 (link 2), #81, #39 (menu) | `claude/kng-60-dashboard-hub` | waiting: link 1 done | — | — | — |
| 4 | #178 | `claude/realtime-signalr` | waiting: link 1 done (then together with link 3) | — | — | — |
| 5 | #64 (FormWizard), #109, #186 | `claude/form-wizard-edit-mode` | waiting: links 1 and 3 merged | — | — | — |
| 6 | #179 | `claude/realtime-signalr` | waiting: link 4 done | — | — | — |
| 7 | #180 | `claude/world-task-hardening` | waiting: link 5 merged | — | — | — |
| 8 | #181 | `claude/realtime-signalr` | waiting: link 6 done, link 7 merged | — | — | — |
| 9 | #39 (rest), #177 follow-up | `claude/entity-lists-url-state` | waiting: link 3 merged | — | — | — |
| 10 | #182 | `claude/realtime-signalr` | waiting: link 8 done | — | — | — |

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that unblock a gate,
flagged decisions.)

- **Link 1 in review:** live checklist [guides/dashboard-return-smoke-test.md](../guides/dashboard-return-smoke-test.md) on
  workspace branch `claude/kng-60-dashboard-hub` (web-app branch of the same name). Flagged decisions L1-1…L1-7 in the
  link 1 block. Link 3 and link 4 gates are open (link 1 done); link 5's gate needs link 1 **merged**.

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

