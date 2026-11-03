# Dashboard, form wizard and realtime chain — progress report

**Status:** Chain complete — links 1–3, 3b, 5 and 9 merged; links 4, 6, 7, 8 and 10 and follow-up link 3c (#225–#229) in review, waiting for the developer (2026-11-03)
**Last updated:** 2026-11-03
**Charter:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) · **Coordinator prompt:**
[2026-10-26-ux-realtime-coordinator-prompt.md](../ai-agents/handoffs/2026-10-26-ux-realtime-coordinator-prompt.md)
**Base at start:** knk-web-app `main` `0d61270`, knk-web-api `master` `6f08383`, knk-plugin `main` `ee35fb1` (re-check:
later merges on the trunks happen; each link records its own base).

## Summary

Status values: `ready` (gate open), `waiting: <gate>`, `in progress`, `in review` (pushed, waiting for the developer's
test), `merged`, `blocked: <reason>`.

| Link | Issues | Branch | Status | Started | Heads (api / web-app / plugin / workspace) | Tests vs baseline |
|---|---|---|---|---|---|---|
| 1 | #177 (link 1), #58 | `claude/kng-60-dashboard-hub` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | create_session session_01Lr2FyBpZG3fDCq51LuFgSM, 2026-10-26 (a first subagent run was stopped by the developer before pushing anything) | — / `df78e73` / — / `7143596` | web-app 1232/1232 (baseline 1214/1214), suites 195 (193); `tsc` 9 errors = baseline; build OK, same warnings |
| 2 | #185, #38, #192 | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — / route-gates `0d14806`, styling `918f6b7`, claim-code `e2a5521` / — / route-gates `6d181c2`, styling `262bca9`, claim-code `4496485` | web-app 1218 / 1218 / 1240, all passed (baseline 1214/1214), suites 194 (193); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 3 | #177 (link 2), #81, #39 (menu) | `claude/kng-60-dashboard-hub` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — / `9a203f8` / — / `186c851` | web-app 1270/1270 (baseline 1232/1232), suites 201 (195); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 3b | #194, #195, #196 (follow-ups of links 1–3) | `claude/dashboard-explorer-194`, `claude/dashboard-header-195`, `claude/claim-code-dash-196` | merged: knk-web-app `main` `c3c0c9f` (2026-10-26, by the coordinator at the developer's request) | subagent, 2026-10-26 | — / explorer `29a6883`, header `be4adab`, claim-code `b8138e3` / — / explorer `3aea976`, header `61dcf23`, claim-code `31c41bd` | web-app 1315 / 1305 / 1311, all passed (baseline 1304/1304, suites 205 / 204 / 204 (204)); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 3c | #225, #226, #227, #228, #229 (follow-ups of link 3b's live test, 2026-11-03) | `claude/explorer-favourite-copies-225`, `claude/explorer-filter-226`, `claude/form-hide-type-card-227`, `claude/code-entry-centred-228`, `claude/register-code-mask-229`; all five together: `claude/link-3c-combined` (testing only) | in review | subagent of the coordinator, 2026-11-03 (update after #95 the same day) | — / favourites `9c364a5`, filter `64bc998`, type card `66de410`, centred `439c8ed`, register mask `f604c99`, combined `cea6b6a` / — / `175f484`, `67662ae`, `2efb802`, `b7376f3`, `95c7150` | after merging `main` `c02b365` (#95): web-app 1775 / 1782 / 1775 / 1776 / 1776, combined 1792, all passed, 223 suites (baseline `main` 1773/1773); `tsc` 0; `CI=true` build OK; `lint:colors` adds no raw colour (the two files over the baseline are `main`'s own); first run on `44f9395`: 1424 / 1431 / 1424 / 1425 / 1425 (baseline 1422) |
| 4 | #178 | `claude/realtime-signalr` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | `b8a29d7` / — / `a64b7f83` / `e878ee2` | API 3338 passed, 4 failed (#99, = baseline reds), 87 skipped (baseline 3296/4/87); plugin core 2319 (2312), api-client 290 (280), paper 2149 (2140), 0 failures |
| 5 | #64 (FormWizard), #109, #186 | `claude/form-wizard-edit-mode` | merged: web-app `main` `b3b415d`, API `master` `8df59b7`, workspace `main` `6e2b98c` (2026-11-01, by the coordinator at the developer's request) | subagent (fallback: add_repo needed in-session approval), 2026-10-26; fix round subagent 2026-10-27 | `09305ef` / `ff58c83` / — / `1e21ee2` | fix round: web-app 1359/1359, suites 212 (baseline on the merged `main` `c3c0c9f`: 1349/1349, 210); link 5: web-app 1330/1330, suites 209 (baseline 1304/1304, 204); `tsc` 9 errors = baseline; build OK, same 24 warnings; API 3356 passed, 4 failed (#99, = baseline reds), 88 skipped (baseline on the merged `master` `4d7a806`: 3339/4/88) |
| 6 | #179 | `claude/realtime-signalr` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | `38b0466` / — / `b48f1484` / `ae949bd` | API 3361 passed, 4 failed (#99, = baseline reds), 87 skipped (baseline 3338/4/87); plugin core 2323 (2319), api-client 298 (290), paper 2163 (2149), 0 failures |
| 7 | #180 | `claude/world-task-hardening` | in review | subagent (fallback: add_repo needed in-session approval), 2026-11-01 | `115c418` / `d7a0896` / `21de734e` / `e06c1e0` | API 3448 passed, 4 failed (#99, = baseline reds), 88 skipped (baseline 3397/4/88); web-app 1378 passed, 1 failed (#204 base red), suites 216 (baseline 1364/1, 213); `tsc` 9 = baseline; build OK, same 24 warnings; plugin core 2401 (2401), api-client 291 (288), paper 2364 (2343), 0 failures |
| 8 | #181 | `claude/realtime-signalr` | in review (stacked on unmerged link 7: the branch contains `claude/world-task-hardening` in all four repos, see coordinator notes 2026-11-02 and the link 8 block) | subagent (fallback: add_repo needed in-session approval), 2026-11-02 | `a27f61e` / `c7a3e85` / `8fa35148` / `3e8a71b` | API 3562 passed, 4 failed (#99, = baseline reds), 88 skipped (baseline on the merged branch 3513/4/88); web-app 1407 passed, 1 failed (#204 base red), suites 221 (baseline 1392/1, 218); `tsc` 9 = baseline; build OK, 24 warnings; plugin core 2412 (2412), api-client 313 (309), paper 2406 (2387), 0 failures |
| 9 | #39 (rest), #177 follow-up | `claude/entity-lists-url-state` | merged: web-app `main` `44f9395`, workspace `main` `1507b7d` (2026-11-03, by the coordinator at the developer's request after the live test) | subagent (fallback: add_repo needed in-session approval), 2026-11-01; fix round subagent 2026-11-03 | — / `d72194b` / — / `fb27146` | fix round: web-app 1403 passed, 1 failed (#204 base red), suites 217; `tsc` 9 = baseline; build OK, 22 warnings; link 9: web-app 1402 passed, 1 failed (#204 base red), suites 217 (baseline 1364/1, 213); `tsc` 9 = baseline; build OK, 22 warnings (baseline 24: two `PagedEntityTable` hook warnings gone) |
| 10 | #182 | `claude/realtime-signalr` | in review (same branch as links 4, 6 and 8, so also stacked on unmerged link 7) | subagent (fallback: add_repo needed in-session approval), 2026-11-02 | `e769c4c` / — (unchanged `c7a3e85`) / `eb22a655` / `c04d3df` | API 3580 passed, 4 failed (#99, = baseline reds), 88 skipped (baseline 3562/4/88); plugin core 2420 (2412), api-client 317 (313), paper 2414 (2406), 0 failures |

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that unblock a gate,
flagged decisions.)

- **Links 1, 2 and 3 live-tested by the developer on 2026-10-26:** every step works or accepted. Follow-ups filed:
  #194 (explorer: one scrollbar, favourites on top), #195 (dashboard entity header styling), #196 (claim code field shows
  the dash from the start), #197 (remove "Entity setup" from the nav; not scheduled). #194–#196 run as follow-up link 3b.
- **Link 3b live-tested 2026-11-03** (#194, #195, #196; on web-app `main`): every step works. The developer's feedback
  became #225 (favourites as copies), #226 (explorer filter), #227 (no type card above an open form), #228 (centred code
  entry cards), #229 (masked link-code field on `/auth/register`, L2-9 / L3b-9); they run as follow-up link 3c.
- **Test link 3c** (#225–#229, web app only; no API, plugin, migration or setting). **All five in one checkout:**
  knk-web-app `claude/link-3c-combined` `cea6b6a` (`main` `c02b365` + the five branches; for testing only, merge per
  branch). Per issue (each branch has `main` `c02b365`, #95, merged in); full steps on the workspace branches of the same names:
  - #225 `claude/explorer-favourite-copies-225` web-app `9c364a5`, workspace `175f484`: `guides/dashboard-return-smoke-test.md` § 9b.
  - #226 `claude/explorer-filter-226` web-app `64bc998`, workspace `67662ae`: same guide § 9c.
  - #227 `claude/form-hide-type-card-227` web-app `66de410`, workspace `2efb802`: same guide § 10a.
  - #228 `claude/code-entry-centred-228` web-app `439c8ed`, workspace `b7376f3`: `guides/invitations-smoke-test.md` § 4 step 17b.
  - #229 `claude/register-code-mask-229` web-app `f604c99`, workspace `95c7150`: same guide § 4 steps 16 and 17c.
  Check the changed screens in the `brand` and `current` themes too (`?theme=brand`). The branches merge cleanly with
  each other, `claude/world-task-hardening` and `claude/realtime-signalr`. Flags L3c-1…L3c-8; #230 (broken
  `field-error-strong` classes from #95's codemod, also in `/link`'s error box) is a separate fix.
- **Link 5 merged** on 2026-11-01 at the developer's request after the re-test: web-app `main` `b3b415d`, API `master`
  `8df59b7`, workspace `main` `6e2b98c`. **After deploying web app and API together:** back up, then run
  `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql` once (smoke test section 7, alpha-go-live § 4.3).
- **Test link 4** (#178, SignalR S1): API `claude/realtime-signalr` `b8a29d7`, plugin `a64b7f83`; live checklist
  `docs/guides/realtime-smoke-test.md` § S1 on workspace `claude/realtime-signalr` `e878ee2`. `realtime.enabled` is off by
  default. Links 6, 8 and 10 continue this branch, so it is best merged once later unless you want S1 live earlier.
  Flags L4-1…L4-11; the startup-only siege work (#31) stays with link 10 as the charter says.
- **Test link 7** (#180, WT1): `claude/world-task-hardening` API `115c418`, web-app `d7a0896`, plugin `21de734e`; live
  checklist `docs/guides/world-task-hardening-smoke-test.md` on workspace `claude/world-task-hardening` `e06c1e0`.
  Deploy API, plugin and web app together; one additive migration. **Before the first sweep read L7-8:** old sessions
  without a draft and without a Completed task, older than 7 days, are deleted (back up). Flags L7-1…L7-18. Its merge
  opens link 8 (with link 6 done) and frees knk-web-app for link 9. Coordinator check 2026-11-01: heads match, migration additive, access rules and sweep spot-checked.
- **Link 9 merged** on 2026-11-03 at the developer's request after the live test (all steps pass after the 4.2 fix `d72194b`): web-app `main` `44f9395` (conflict in `PagedEntityTable.tsx`: kept main's #218 comments; merged result 1422/1422 tests, `tsc` 0, `CI=true` build OK), workspace `main` `1507b7d`.
- **Test link 8** (#181, WT2, same branch, **stacked on link 7**): API `claude/realtime-signalr` `a27f61e`, plugin `8fa35148`,
  web-app `c7a3e85`; live checklist `docs/guides/realtime-smoke-test.md` § WT2 on workspace `claude/realtime-signalr`
  `3e8a71b` (run § S1 and link 7's checklist first). Deploy the three together; the branch contains link 7 (its migration,
  L7-8). Flags L8-1…L8-20; deviations L8-2 (poll 2 s while the web hub is down, 10 s safety net while up), L8-4, L8-15. Coordinator check 2026-11-02: heads match, link 7 is an ancestor of `claude/realtime-signalr` in all four repos, Presence/active-for-me access rules spot-checked.
- **Test link 10** (#182, S3, same branch as links 4, 6 and 8, so it contains link 7 too): API `claude/realtime-signalr`
  `e769c4c`, plugin `eb22a655` (web app unchanged at `c7a3e85`); live checklist `docs/guides/realtime-smoke-test.md` § S3
  on workspace `claude/realtime-signalr` `c04d3df` (run § S1 first). No new setting, no migration of its own. Decisions to
  see: L10-1 (GateChanged only for definition edits), L10-5 (only gates a running match holds wait), L10-8 (#31 retried
  on the hub reconnect only; the abort never once this run created a match). Flags L10-1…L10-15. Coordinator check 2026-11-02: heads match; the entity-change interceptor sends on SavedChanges and drops on SaveChangesFailed/Canceled.
- **Test link 6** (#179, SignalR S2, same branch): API `38b0466`, plugin `b48f1484`; live checklist
  `docs/guides/realtime-smoke-test.md` § S2 on workspace `claude/realtime-signalr` `ae949bd` (run § S1 first). Flags
  L6-1…L6-12 (link 6 block). L6-1: the ×4 slowdown applies only to the social-spy re-check for now; the notification
  poll stops while connected; the other timers slow down when S3 pushes their changes.

## Chain end (coordinator, 2026-11-02)

Every link has run. **Merged:** links 1–3, 3b, 5. **In review, waiting for the developer's live test and merge:**

| Branch | Links | Checklist (workspace feature branch) | Contains |
|---|---|---|---|
| `claude/world-task-hardening` | 7 | `docs/guides/world-task-hardening-smoke-test.md` | — |
| `claude/entity-lists-url-state` | 9 | `docs/guides/entity-lists-url-state-smoke-test.md` | — (merges cleanly with link 7) |
| `claude/realtime-signalr` | 4, 6, 8, 10 | `docs/guides/realtime-smoke-test.md` § S1, S2, WT2, S3 | link 7 (stacked, waiver 2026-11-02) |

Suggested test and merge order: link 9 (web app only, independent); link 7 (one additive migration; read L7-8 and back up
before the first sweep); then the realtime branch (S1 → S2 → WT2 → S3; `realtime.enabled` off by default, so merging it
is safe before the hub is switched on). Fixes found while testing link 7 go to its branch and are merged into
`claude/realtime-signalr` again. Deploy API, plugin and web app together for links 7 and 8.

Base reds the links worked around, still open: #99 (4 API tests), #204 (InvitePage fixture), #63 (9 `tsc` errors),
#106 (`.sln` path case).

### Proposed next chain (for the developer to approve; nothing started)

Two lanes that share no component repo, as in this chain:

**Lane W, web app (sequential):**
1. Quick fixes: #204 (test fixture), #197 (drop "Entity setup" from the nav).
2. #95 token layer (contrast rules), then #33 feedback primitives (toast API, Dialog, danger/required-reason confirm),
   then #187 data and format primitives (DataTable/Pager, `format.ts`, SettingsPage shell). Everything below builds on these.
3. #30 admin information architecture (route-meta table, grouped sidebar, breadcrumbs).
4. Screens on the primitives: #119 player profile (needs #33), #26 settings help and confirms (needs #187), #188 then #189
   entity detail page (#188 needs an API part), #191 relation picker, #205 bulk actions (open decisions in the issue).
5. #71 form and display builders.

**Lane R, API + plugin (after the realtime branch is merged):**
1. #184 S5 account-erasure push (GDPR; priority medium).
2. #31 rest: siege startup work on API recovery when the hub is off (link 10 fixed only the hub path).
3. #34 lootbox spawn-area region renames.
4. #183 S4 live updates in the web app (touches web app: runs after lane W step 3, or between its steps).

**Separate, before an open beta:** #139 email verification (API + web app; needs real SMTP). **Needs decisions first:**
#92 rebrand phases 2–4 (Q6 font licence, Q7 light admin / dark public), #190 settings audit (low).

## Coordinator notes


- **2026-11-02, link 8 gate waived (reversible default):** the developer is busy this week and asked to continue
  implementation and test later. Link 8's gate ("link 7 merged") is replaced by stacking: link 8 merges
  `claude/world-task-hardening` (link 7, in review) and the current trunks into `claude/realtime-signalr`, merges only,
  no rebase. Nothing untested goes to a trunk. Consequences: merging `claude/realtime-signalr` later also merges link 7;
  fixes from the link 7 test go to `claude/world-task-hardening` and are merged into `claude/realtime-signalr` again.
  Link 10 follows link 8 on the same branch. To undo: stop link 8 and leave the branch as it was.
- 2026-10-26: the developer pre-approved attaching `PandiO/knk-plugin`, `knk-web-app`, `knk-web-api`, `knk-dev-db-seed` and `knk-workspace` with `add_repo` (access push) for the coordinator and every link session it creates for this chain. Link prompts carry this as one appended sentence; it was also sent to link 1's session.

## Follow-ups filed by links

- Link 3c: #225–#229 were filed from the developer's link 3b live test (sub-issues of #24). While merging #95: #230 (the #95
  codemod turned `text-danger-strong` into a non-existent `field-error-strong` / stray `-strong` class on 12 lines in 8
  files on `main`; the error text in those boxes loses its colour).
- Link 10: no new issue; comments on [#182](https://github.com/PandiO/knk-workspace/issues/182) (heads, tests, checklist, flags L10-1…L10-15) and [#31](https://github.com/PandiO/knk-workspace/issues/31) (startup work retried on the hub reconnect; the hub-off path stays open).
- Link 8: no new issue; comment on [#181](https://github.com/PandiO/knk-workspace/issues/181) (heads, tests, checklist, flags L8-1…L8-20).
- Link 9: #205 (bulk actions on the dashboard table, split from #39). Comments on [#39](https://github.com/PandiO/knk-workspace/issues/39) and [#177](https://github.com/PandiO/knk-workspace/issues/177).
- Link 7: no new issue; comments on [#34](https://github.com/PandiO/knk-workspace/issues/34) (temp regions of completed tasks for abandoned forms) and [#181](https://github.com/PandiO/knk-workspace/issues/181) (WT2 notes).
- From the coordinator's link 5 merge check (2026-11-01): #204 (web-app `InvitePage.test.tsx` fixture expired on 2026-10-28; red on `main`, recorded as a base red by later links).
- From the developer's live test of links 1–3 (2026-10-26, filed by the coordinator): #194, #195, #196, #197.

- Link 4: no new issue (API reds = #99, `.sln` path case = #106); WT2 notes as a comment on [#181](https://github.com/PandiO/knk-workspace/issues/181).
- Link 6: comment on [#76](https://github.com/PandiO/knk-workspace/issues/76): with the hub the display symptom should be
  gone (set reloaded before the redraw; live check pending); with the hub down the `RankChanged` poll path still
  doesn't drop the permission set (left as is: channel off = today's behaviour). No new issue.
- Link 5: comment on [#95](https://github.com/PandiO/knk-workspace/issues/95): fields in their error state (`border-red-300`) have no border width (the #38 base rule covers `border-gray-300` only); fixed for the wizard's String field only. Comment on [#64](https://github.com/PandiO/knk-workspace/issues/64): FormWizard part done, the JoinEntityFormModal / ManyToManyRelationshipEditor debug logs and the rest stay. No new issue.
- Link 1: comment on [#63](https://github.com/PandiO/knk-workspace/issues/63): `tsc --noEmit` on web-app `main` has 9
  test-file errors, not 2 (adds `categoryTree.test.ts` ×5 and `cloudflareAccess.test.ts` ×1).
- Link 2: comment on [#95](https://github.com/PandiO/knk-workspace/issues/95): about 104 form fields set `focus:ring-primary` without a ring width, so they have no focus ring (#38 only gives them their border).

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

## Link 4 — #178 (S1): SignalR foundation

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-10-26; finished 2026-10-26. Ran at the same
time as link 3 (other component repos).
**Base:** knk-web-api `master` `6f08383`, knk-plugin `main` `ee35fb1d` (both unchanged at the end, nothing to merge);
knk-workspace branch created from `main` `ead2aa4`, `origin/main` `1bcd876` merged in before the last push (`e878ee2`).

**Commits**
- knk-web-api `claude/realtime-signalr`: `b8a29d7` hubs, envelope, publisher, presence registry + tests. Head **`b8a29d7`**.
- knk-plugin `claude/realtime-signalr`: `e01254f5` core/api-client realtime client (backoff, seq, resync hooks, stats,
  SignalR transport); `a64b7f83` paper wiring, `realtime.*` config, `realtime.server-id`, `/knk health`, metrics, shadow
  relocations. Head **`a64b7f83`**.
- knk-workspace `claude/realtime-signalr`: `72f79f0` DESIGN/plan status (+ DESIGN §4.6 "as built"), architecture
  (plugin, web-api §6, api-connectivity), production-installation + alpha-go-live (`realtime:` block, nginx
  `/api/hubs/`), new `guides/realtime-smoke-test.md`, guides README, CHANGELOG; `e878ee2` merge of `main`. Head **`e878ee2`**.

**What was built**
- **API** (`Realtime/`): `/api/hubs/game` (policy `KnkRealtimeGameServer` = the `[RequirePluginService]` key check, constant
  time; `X-Knk-Server-Id` required, 1–64 of `[A-Za-z0-9._-]`; groups `servers`, `server:{id}`; first message `Welcome`
  seq 1) and `/api/hubs/web` (JWT incl. the TokenVersion check; `access_token` query string read in `OnMessageReceived`
  for this path only; closes when the token expires; group `user:{id}`; no client methods). Envelope `{v, seq, type, at,
  actor, payload}`. `IRealtimePublisher` → bounded channel (1000, drop-oldest, logged) → `RealtimeDispatchService`
  (one reader, `seq` per connection). `PresenceRegistry` + `PresenceStore` (`User.IsOnline`/`LastSeenAt`):
  `ReportRoster` reconciles every row, `PlayerJoined`/`PlayerLeft`, `PresenceSweepService` marks a server's players
  offline after 60 s without reconnect. Meter `Knk.Realtime`. Optional settings section `Realtime`.
- **Plugin:** `knk-core/.../core/realtime/` (`ReconnectBackoff` 1/2/5/10/30 s ±20 %, `SequenceTracker`, `ResyncHooks`,
  `RealtimeState`, `RealtimeStats` as a metrics collector; package added to the Bukkit-free guard),
  `knk-api-client/.../api/realtime/` (`RealtimeClient` on one executor thread: reconnect, pause/resume, fresh seq per
  connection, fire-and-forget `send`; `SignalRHubTransport` on `com.microsoft.signalr` 10.0.13, Gson 2.11.0;
  `RealtimeEnvelope`), `knk-paper/.../paper/realtime/` (`RealtimeService`: roster + resync on the main thread on every
  (re)connect and after a gap, `PlayerJoined`/`PlayerLeft`, paused on `ApiConnectivityChangedEvent` DOWN, resumed on UP;
  `RealtimeDispatcher`; `RealtimeSettings`). `config.yml` `realtime:` (`enabled: false`, `server-id: "localhost"`,
  `hub-url`, `hub-path`, `backoff-seconds`, `backoff-jitter`). `realtime.server-id` replaces the hard-coded
  `"localhost"` passed to world-task claims. `/knk health` line; `knk_realtime_*` on the KNG-232 endpoint. Shadow jar
  relocates RxJava, reactive-streams and Gson; slf4j comes from Paper.

**Tests vs baseline**
- API: **3338 passed, 4 failed, 87 skipped of 3429** (baseline 3296 / 4 / 87 of 3387). +42 new in `Tests/.../Realtime/`
  (registry, store, publisher/dispatcher, both hubs end to end on a test server with the .NET SignalR client over long
  polling). The 4 reds are #99 (PathResolution ×2, FieldValidation, ClientActivityStore; the last one also red on a clean
  `master` worktree today). `dotnet build` at the repo root fails on the `.sln` path case (#106); built with the csproj.
- Plugin (`./gradlew build -x deployToDevServer`, JDK 25 toolchain): core **2319** (2312), api-client **290** (280, 2
  skipped both), paper **2149** (2140, 18 skipped both); 0 failures. Shadow jar checked: SignalR inside, RxJava/Gson
  relocated, no slf4j.
- Interop (not committed): the Java client against the API branch's hubs in a scratch host over WebSockets: `Welcome`
  seq 1, roster reconcile (stale online row set offline), join/leave, a published message as seq 2, grace expiry, and a
  reconnect after killing and restarting the API (backoff 1/2/5/10/30 s; roster corrected the rows again).
- `[MySqlFact]` tests: none written (presence uses plain EF reads/writes; covered on InMemory).

**Flagged decisions (reversible)**
- **L4-1** `realtime.server-id` defaults to `"localhost"` (the old hard-coded value), so a server without the key claims
  tasks exactly as before. `game-settings.server-id` and `lootboxes.server-id` (default `"default"`) stay separate keys;
  unifying them is not in S1.
- **L4-2** Per-connection `seq` (DESIGN §4.2) is done by the API's own connection/group registry (`RealtimeConnections`);
  SignalR's group feature is not used, because it can't number per connection.
- **L4-3** A `Welcome {serverId, presenceGraceSeconds}` event (seq 1) was added so S1 has one message to verify the path
  end to end; documented in DESIGN §4.6.
- **L4-4** A game-hub connection without a valid `X-Knk-Server-Id` is closed (not filed under a default id).
  `Realtime:AllowedServerIds` exists (empty = any id, logged), per DESIGN §7.3.
- **L4-5** A roster reconciles **all** users: anyone marked online in the database but on no connected (or in-grace)
  server's roster is set offline. Correct while every game server that shares the API uses the hub (one server today).
- **L4-6** The REST `PUT api/users/{id}/presence` on join/quit is kept even while the hub is connected (a second,
  idempotent write) instead of being skipped; less risk, no listener change.
- **L4-7** The resync also runs on the first connect at startup (DESIGN: every (re)connect); it re-reads caches loaded
  moments earlier, which is harmless.
- **L4-8** S1 resync hooks: the `/knk cache refresh` hooks, `DomainAccessFlagSync.syncNow()`, `LootboxRuntime.refresh()`.
  Not in S1: the user-cache re-read and the notification drain (S2, #179), open world tasks (WT2, #181), and the
  startup-only siege work (#31): the issue text names it for S1, but the charter's link table and the plan put it in S3
  (link 10, #182). The hook list is where it goes.
- **L4-9** `realtime.fallback-poll-multiplier` (DESIGN §4.4) is not added yet: nothing slows down in S1; S2 adds the key
  with the slower re-syncs (plan S2, Q4).
- **L4-10** `scripts/alpha-web/nginx.conf` is unchanged: the plugin connects straight to `http://api:5000` and the web
  hub has no browser client before WT2. `production-installation.md` documents a `/api/hubs/` location with
  `access_log off` (the browser's JWT is in the query string); the alpha config needs the same when WT2 lands.
- **L4-11** SignalR Java client **10.0.13** (2026-10-13), not 10.0.14 (released 2026-10-25); Gson pinned to 2.11.0.

**Deviations from the plan/design:** L4-8 (siege startup work left to link 10 as the charter says) and L4-3 (one extra
event type). `RealtimeDispatcher` is in knk-paper as designed; the pure pieces (backoff, sequence, hooks, stats) are in
knk-core so they are unit-tested without Bukkit.

**Live checklist:** [guides/realtime-smoke-test.md](../guides/realtime-smoke-test.md) § S1 (workspace branch
`claude/realtime-signalr` until merged): off changes nothing, connect, presence on join/quit, API restart (paused while
DOWN, immediate reconnect on UP), reconcile after a crash, 60 s grace, resync, world-task server id, no waiting, wrong
key/id.

**Deploy notes:** API: no migration, no new secret; optional section `Realtime` (`ChannelCapacity`,
`PresenceGraceSeconds`, `PresenceSweepSeconds`, `KeepAliveSeconds`, `ClientTimeoutSeconds`, `AllowedServerIds`); keep
`Microsoft.AspNetCore` logging at Warning (request URLs with `access_token` are logged at Information). Plugin: add the
`realtime:` block to an existing `config.yml` (the bundled one has it, `enabled: false`); the hub needs
`api.auth.type: apikey`. The plugin jar grows by the SignalR client, RxJava 3 and Gson (about 3.5 MB, mostly RxJava; shadow jar 14.2 MB).

**Follow-ups filed:** none new; the reds are #99 and the `.sln` path is #106. Comment on #181 with the WT2 notes below.

**Notes for later links**
- Link 6 (S2, #179): publish with `IRealtimePublisher.PublishToGameServers(type, payload, actor: new RealtimeActor(userId,
  "web"))` after `SaveChangesAsync`; on the plugin register handlers with `realtimeService.dispatcher().register(type, v,
  executor, handler)` **before** `start()` in `KnKPlugin.initializeRealtime()` (the client listens for the registered
  types on each connect). Add the user-cache re-read and the notification drain as `ResyncHooks`, and
  `realtime.fallback-poll-multiplier` to `RealtimeSettings`. `RealtimeService.isConnected()` tells the pollers to slow down.
- Link 8 (WT2, #181): `PresenceRegistry.ServerOf(uuid)` answers "is the initiator online"; `RealtimeConnection.Groups` is
  fixed at connect, so `task:{id}` joins need a mutating method on `RealtimeConnections`; the web hub has no client
  methods yet (add join/leave with the `CreatedByUserId` / `knk.admin.world` check, DESIGN §7.3); add `/api/hubs/` with
  `access_log off` to `scripts/alpha-web/nginx.conf`.
- Link 10 (S3, #182): the startup-only siege work goes into `ResyncHooks` (`initializeRealtime`); the entity events go
  through one `IRealtimeEventSink` in front of `IRealtimePublisher`.
- Hub tests: `Tests/.../Realtime/RealtimeHubTests.cs` builds a test server with `AddKnkRealtime` +
  `MapKnkRealtimeHubs` and connects with long polling; reuse it for new hub methods.

## Link 2 — #185, #38, #192: route gates, styling quick wins, claim code field

**Started:** subagent (fallback: add_repo needed in-session approval), 2026-10-26; finished 2026-10-26.
**Base:** knk-web-app `main` `0d61270` for all three branches (unchanged at the end; nothing to merge in). knk-workspace
branches from `main` `a46e8fd` (current at the end). One branch per issue; nothing in knk-web-api or knk-plugin.

**Commits**
- knk-web-app `claude/route-gates-185`: `0d14806` route gates + nav entries + test. Head **`0d14806`**.
- knk-web-app `claude/styling-quick-wins-38`: `918f6b7` Tailwind config, `index.css`, style test. Head **`918f6b7`**.
- knk-web-app `claude/claim-code-field-192`: `b82dad6` `ClaimCodeInput` + separator constant; `e2a5521` the pages.
  Head **`e2a5521`**.
- knk-workspace `claude/route-gates-185` **`6d181c2`**: CHANGELOG, `guides/game-settings.md`,
  `guides/authoring-a-siege-scenario.md` § 4, `guides/alpha-hardening-smoke-test.md` step 27a.
- knk-workspace `claude/styling-quick-wins-38` **`262bca9`**: CHANGELOG, `architecture/web-app-architecture.md` (styling).
- knk-workspace `claude/claim-code-field-192` **`4496485`**: CHANGELOG, `architecture/account-identity-and-admission.md`
  § 4, `guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md` step 4, `guides/invitations-smoke-test.md` steps 16–17.

**What changed (web-app)**
- **#185:** `/admin/game-settings` and its nav link need `knk.admin.config` (`SERVER_CONFIG_PERMISSION_NODE`, the API's
  `StaffPermissions.ServerConfig`), `/admin/siege-configuration` and its link `knk.siege.admin.manage`
  (`SIEGE_ADMIN_PERMISSION_NODE`, `StaffPermissions.SiegeManage`); both constants in `hooks/useStaffAccess.ts`. Before:
  the moderator node. Without the node: no nav link, and the page says "Staff only" naming the node.
- **#38:** `primary.dark` `#1d4ed8` in `tailwind.config.js` (28 `hover:*-primary-dark` uses get a hover state);
  `.btn` is `inline-flex items-center justify-center gap-2` and `.btn > svg` drops its own `mx` margin; `.btn-tertiary`
  (transparent, primary text, light primary hover) for Save Draft; `.input` gets `border`; a zero-specificity base rule
  (`:where(input…, select, textarea):where([class*=border-gray-300], [class*=border-slate-300])`) gives fields that set a
  border colour but no width their 1px (preflight sets 0 and `@tailwindcss/forms` isn't installed).
  `src/__tests__/tailwindStyles.test.ts` compiles `index.css` with the project config and checks all of it.
- **#192:** `components/auth/ClaimCodeInput.tsx`: one labelled input holding the 8 characters and showing `XXXX-XXXX`;
  the separator appears once the first group is full; typed/pasted separators (dash, en dash, space) are ignored; the
  caret is kept; Backspace/Delete on the separator remove the character beyond it. `utils/claimCode.ts`:
  `CLAIM_CODE_SEPARATOR` (one constant, `-`), `CLAIM_CODE_SHAPE`, `CLAIM_CODE_EXAMPLE`, `CLAIM_CODE_SEPARATOR_NAME`,
  `claimCodeChars`; `looksLikeClaimCode` also takes a space between the groups. Used on `/link` (folds look-alikes) and
  `/account/link` (takes link codes too: keeps O/I/L, sends the 8 characters unfolded; `ValidateLinkCodeAsync` already
  tries the link code, then the folded claim form). Register page, invitation step: 8 plain characters without a U are
  checked with `claim/check` first; a live claim code is kept (`knk.pendingClaim`) and the player lands on `/link`
  verified; otherwise the link-code step opens as before. Help texts and placeholders use the constants.

**Tests vs baseline** (Node 22, `npx npm@11 ci`)
- Baseline `main` `0d61270`: 1214/1214, 193 suites; `tsc --noEmit` 9 errors (#63); build OK, 24 warning lines.
- `claude/route-gates-185`: **1218/1218, 194 suites** (+4: `Navigation.settingsGates.test.tsx`); tsc 9; build OK, 24.
- `claude/styling-quick-wins-38`: **1218/1218, 194 suites** (+4: `tailwindStyles.test.ts`); tsc 9; build OK, 24;
  the production CSS holds the new rules (checked in `build/static/css`).
- `claude/claim-code-field-192`: **1240/1240, 194 suites** (+26: `ClaimCodeInput.test.tsx` 15, `claimCode` 3, `LinkPage`
  3, `AccountLinkPage` +2 net, `RegisterForm` +3; 3 existing cases rewritten for the new field); tsc 9; build OK, 24.
- The three branches merge into each other cleanly (trial merge of all three on `main`).

**Merge notes**
- **`claude/route-gates-185` vs links 1+3 (`claude/kng-60-dashboard-hub`): one mechanical conflict** in
  `src/components/Navigation.tsx` `NAV_LINKS` (link 3 renamed "Forms" on the line just above the Game Settings entry).
  Resolution: keep links 1+3's Dashboard / "Entity setup" lines and this branch's Game Settings / Siege Settings lines
  (`node: SERVER_CONFIG_PERMISSION_NODE` / `node: SIEGE_ADMIN_PERMISSION_NODE`). The import line and `nodeAccess` merge
  cleanly. The other two branches merge cleanly with links 1+3.
- knk-workspace: each of the three branches, links 1+3 and link 4 add an entry under CHANGELOG "Unreleased" (keep all);
  nothing else conflicts (the header lines that links 1+3 also edit were left alone; dates are inline).

**Flagged decisions (reversible)**
- **L2-1** (#185) No read-only view: there is no read node for either page, and the API's GETs only need a login. A
  holder of neither node sees "Staff only". A read-only mode can follow with #26 if wanted.
- **L2-2** (#185) The siege node is not matched by `knk.admin.*` (only `knk.siege.*`, `knk.siege.admin.*`, `*`), so an
  admin with `knk.admin.*` but no siege node no longer sees Siege Settings; that matches what the API refuses.
- **L2-3** (#38) `.btn > svg` drops the icon's own `mr-2`/`ml-*` (about 41 call sites) so the new `gap-2` doesn't double
  the spacing; every button icon is 8 px from its label.
- **L2-4** (#38) The border rule reaches beyond Game Settings: about 104 fields in 25 files written as
  `rounded-md border-gray-300 …` (builders, wizard field renderers, lootbox filters, paged-table category filter) now
  show a 1px border. That is the same bug everywhere; a field that sets `border-0`/`border-2` keeps its own. Their missing
  focus ring is commented on #95.
- **L2-5** (#38) `primary-dark` = `#1d4ed8` (Tailwind blue-700, one step darker than `primary`); `btn-tertiary` =
  text button in primary blue. Both move to tokens with #95.
- **L2-6** (#192) The field shows the separator as soon as the first group is full (`ABCD-`), so the player sees it
  before typing the 5th character; a typed dash then changes nothing.
- **L2-7** (#192) `/account/link` takes both codes in one field, so link codes are shown `ABCD-OLIL` too (the API ignores
  hyphens). Its "Recognised as the code from the server's disconnect screen" note is gone (the field always shows that
  shape); the 15-minute note on a refusal now shows for a code without I, L, O or U (the #57 rule) or the kept one.
- **L2-8** (#192) The invitation step's `claim/check` probe for 8 plain characters costs one anonymous lookup (per-IP
  lookup limit, 20 a minute); a failed probe falls back to the link-code step.
- **L2-9** (#192) The register page's link-code field is unchanged (no mask): it keeps a typed dash, which is what lets
  the #57 detection route a claim code to `/link`. The issue's optional "link-code fields with their own pattern" is not
  done.
- **L2-10** (#192) **Dash or space is still the testers' call.** Today everything uses a dash, so no API or plugin change
  was needed. If they choose a space: change `CLAIM_CODE_SEPARATOR` (web; texts and fields follow), the API's
  `LinkCodeService.FormatClaimCode` (the plugin's disconnect screen shows the API's string; check its message text
  for a hard-coded example), and let the
  register page's link-code field keep a typed space (`normalizeLinkCodeInput` keeps only dashes). The API already
  ignores spaces when reading a code.

**Deviations:** none from the plan. Per issue, one branch from `main`, as the charter says.

**Live checklist**
- #185: `guides/alpha-hardening-smoke-test.md` step 27a (workspace `claude/route-gates-185`).
- #192: `guides/invitations-smoke-test.md` step 17 (and the updated step 16) (workspace `claude/claim-code-field-192`).
- #38 (web-app `claude/styling-quick-wins-38`, no guide of its own):
  1. Log in page: hover **Log in** → the button turns darker blue; the "Forgot password?" link darkens too. Open a
     non-danger confirm or message dialog (`FeedbackModal` / `useConfirm`, e.g. an error message on the dashboard) →
     its blue button darkens on hover.
  2. Game Settings: **Refresh** and **Save** show the icon left of the label, not above it. Text fields and dropdowns have
     a visible grey border that turns blue on focus.
  3. A form in the wizard: **Previous / Save Draft / Next** have their icons beside the label with normal spacing;
     **Save Draft** is blue text on no background, light blue on hover.
  4. Entity setup → edit a form configuration (field editor) and a display configuration: every input shows one border
     (no double border, no thicker one). Lootboxes → Drop log filters: same.
  5. Buttons that span the width on a phone (login, register, `/link`) keep their label centred.

**Deploy notes:** web app only, per branch. No API, plugin, migration, setting or script.

**Follow-ups:** comment on [#95](https://github.com/PandiO/knk-workspace/issues/95): the ~104 colour-only bordered fields
have no focus ring (`focus:ring-primary` without a width). Nothing else filed.

**Notes for later links**
- Tests that render `Navigation` must open the menu (`Open menu`): jsdom measures every width as 0, so the links live in
  the menu panel (`Navigation.settingsGates.test.tsx`).
- `src/__tests__/tailwindStyles.test.ts` compiles `index.css` with the real config (node environment, `raw` content);
  reuse it for the #95 tokens.
- New permission-node constants for web pages go next to `CONTENT_PERMISSION_NODE` in `hooks/useStaffAccess.ts`; a nav
  entry with `node:` also needs its `usePermission` line in `Navigation`'s `nodeAccess`.

## Link 6 — #179 (S2): user state pushed to the game server

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-10-26; finished 2026-10-26. Ran while link 2
was finishing in knk-web-app (no shared component repo).
**Base:** link 4's heads, knk-web-api `claude/realtime-signalr` `b8a29d7` (API `master` `6f08383` already in it, unchanged)
and knk-plugin `a64b7f83` (plugin `main` `ee35fb1d` already in it, unchanged). knk-workspace `claude/realtime-signalr`
`e878ee2` with `origin/main` merged in at the start (`9b0e507`) and before the last push (`ae949bd`, CHANGELOG
conflict resolved by keeping both sides).

**Commits**
- knk-web-api `claude/realtime-signalr`: `38b0466` user-state events, event sink (after commit), hub-backed notification
  queue + tests. Head **`38b0466`**.
- knk-plugin `claude/realtime-signalr`: `0a188d1b` payload records, offline answers, `FallbackPolling`; `b48f1484`
  `UserStateSync` handlers, pushed notifications, resync steps, `realtime.fallback-poll-multiplier`. Head **`b48f1484`**.
- knk-workspace `claude/realtime-signalr`: `9b0e507` merge of `main`; `b0eeaa7` DESIGN status + §6.7 "S2 as built", plan
  status, plugin and web-api architecture, smoke test § S2 (and S1's step count), guides README, alpha-go-live and
  production-installation (`fallback-poll-multiplier`), CHANGELOG; `ae949bd` merge of `main`. Head **`ae949bd`**.

**What was built**
- **API events** (`Realtime/UserStateEvents.cs`, contracts in `Realtime/Contracts/RealtimeEnvelope.cs`):
  `UserPermissionsChanged {userId, uuid, reason}` from `UserPermissionGroupService` (upsert, delete, rank-expiry sweep;
  the `RankChanged` notification stays) and `PermissionGrantService` (user holder); `PermissionGroupChanged {groupId,
  op}` from `PermissionGroupService` (Created/Updated/Deleted) and group-held grants (GrantsChanged; a grant moved
  between holders tells both); `UserBalancesChanged {userId, uuid, coins, gems, xp}` from `CurrencyService.ExecuteAsync`
  (every non-replayed posting, committed balances); `UserFrozenChanged {frozen, reason, by}`; `UserModeChanged {mode}`
  (only on a change); `UserChanged {fields}` (multipliers, gate method, link, merge).
- **After commit** (`Realtime/RealtimeEventSink.cs`): scoped `IRealtimeEventSink`; `AfterCommitRealtimeEventSink` sends at
  once or, while a transaction is open on the scope's `KnKDbContext`, when it commits. `RealtimeTransactionEvents` is an
  EF Core transaction interceptor (`Program.cs`, next to the KNG-232 one): commit = send held events in order; rollback,
  failure or a new transaction = drop. Actor source from the request: plugin key → `plugin`, user → `web`, none →
  `system`. This is the sink DESIGN §4.3 asks for; S3's interceptor and option C plug in behind it.
- **Hub-backed notification queue** (`Realtime/HubPlayerNotificationQueue.cs`): replaces the `IPlayerNotificationQueue`
  registration, decorates `InMemoryPlayerNotificationQueue` (still the store behind `GET pending` / `POST acknowledge`).
  Pushes `PlayerNotification` (payload = the REST DTO) to the player's server when the presence registry has them
  online, to every server for server-wide ones; `PlayerJoined` pushes what waited for that player plus server-wide ones.
- **Plugin** (`paper/realtime/UserStateSync`, `BukkitUserStateDisplay`; `api/realtime/UserStateEvents`): handlers as in
  DESIGN §6.1 (see §6.7 on the branch). Permissions: drop effective set + offline answers (#76), then for an online
  player reload the set, re-read the user, redraw the tab list, re-check visibility, the "/" list, social spy and the
  mode (a lost mode node drops the mode). Group change: online players whose cached effective groups contain it.
  Balances: into the user cache; XP change → re-read (title, prestige). Freeze/mode: at once, idempotent. `UserChanged`:
  re-read (online) or drop. Pushed notifications go through the poller's delivery and are acknowledged over REST.
  Resync gets two steps after S1's: re-read every online player, then drain the notification queue once.
  `PlayerNotificationPoller` makes no HTTP call while connected. In-game `/freeze` and `/unfreeze` tell the player once.
- **`realtime.fallback-poll-multiplier`** (default 4, 1–60) + `core/realtime/FallbackPolling` (`throttle`, `interval`).

**Tests vs baseline**
- API (`dotnet test`, built with the csproj as in link 4): **3361 passed, 4 failed, 87 skipped of 3452** (baseline 3338 /
  4 / 87 of 3429, re-run at the start). +23 in `Tests/.../Realtime/` (`UserStateEventTests` 16: sink held/flushed/dropped,
  source, every publish point incl. a real ledger posting and its replay; `HubPlayerNotificationQueueTests` 5;
  `RealtimeHubTests` +2: `PlayerJoined` pushes the waiting notification, a scope's sink event reaches the game hub as
  seq 2). The 4 reds are #99, as at baseline.
- Plugin (`./gradlew build -x deployToDevServer`, JDK 25 toolchain): core **2323** (2319), api-client **298** (290, 2
  skipped both), paper **2163** (2149, 18 skipped both); 0 failures. New: `UserStateCoreTest` 4, `UserStateEventsTest`
  8, `UserStateSyncTest` 13, `RealtimeSettingsTest` +1.
- Not run: a Java-client-against-API interop host as in link 4 (the API hub test asserts the JSON the Java parse tests
  read); `[MySqlFact]` tests (none written: the transaction path is covered with the sink's transaction switch, not a
  real MySQL transaction).

**Flagged decisions (reversible)**
- **L6-1** The ×4 slowdown (`realtime.fallback-poll-multiplier`) applies in S2 only to the re-sync whose changes S2
  pushes: the social-spy re-check (60 s → 4 min). Domain access, game settings, lootbox runtime, grades, roads and
  telemetry config keep their interval until S3 (#182) pushes their changes; slowing them now would delay those changes
  with nothing in their place. The notification poll stops entirely while connected (DESIGN §4.3: drains only while
  the hub is down and once on reconnect). The permission (30 s) and user (60 s) TTLs are unchanged.
- **L6-2** No event for a user without a Minecraft UUID (nothing on a game server to update).
- **L6-3** After-commit by an EF Core transaction interceptor, built now as the `IRealtimeEventSink` of §4.3 (S3 reuses
  it). A transaction disposed without commit or rollback has its held events dropped at the context's next transaction
  (or with the context).
- **L6-4** `UserBalancesChanged` is published from the one posting choke point (`CurrencyService.ExecuteAsync`) rather
  than from each of the methods DESIGN lists; it covers them all, plus transfers, salary, rewards and merges.
  Coins/gems-only changes update the cache without a redraw (the tab list doesn't show them); an XP change re-reads.
  Two concurrent postings for one user could arrive out of commit order; the cache then holds the older values until
  the next event or the 60 s TTL.
- **L6-5** Notifications: pushed only when the presence registry has the player online (server-wide ones to every
  server); re-pushed on `PlayerJoined`; while nobody is online a pushed one stays queued. The plugin remembers the last
  512 acknowledged ids so a push and an overlapping drain never show one twice. The store is still in memory (lost on
  an API restart, as before; not in #179's scope).
- **L6-6** Group fan-out uses the cached effective groups (parents included); an empty list (older API) counts as a
  member; a player with no cached summary is skipped (their join loads everything fresh).
- **L6-7** A mode set in the web app for a player without its node: they stay visible and the stored mode goes back to
  None (as a join does). Permission UNAVAILABLE (API down, no last answer): the mode is applied (hidden is the safe side,
  KNG-58).
- **L6-8** `StatisticsVisibilityChanged` (a DESIGN §6.1 row, not in #179's scope) was not built: the plugin's menus
  re-read the setting.
- **L6-9** The generic user edit (`UserService.UpdateAsync`, form wizard/dashboard) sends no `UserChanged`: User is on
  S3's `EntityChanged` allow-list (§6.3).
- **L6-10** No echo suppression: a change made in game comes back as an event and the handlers are idempotent (the
  in-game freeze message now shows once whichever arrives first).
- **L6-11** The `RankChanged` notification is still queued next to `UserPermissionsChanged`, so with the hub both
  redraw (harmless); with the hub down it is the only path, unchanged.
- **L6-12** The #76 display symptom: with the hub the set is reloaded before the redraw, so the tab-list team should be
  right without a rejoin; live check § S2 step 1. Comment on #76.

**Deviations from the plan/design:** L6-1 (slowdown scope), L6-4 (publish point), L6-8 (one §6.1 row not built). DESIGN
§6.7 on the branch records the as-built state.

**Live checklist:** [guides/realtime-smoke-test.md](../guides/realtime-smoke-test.md) § S2 (workspace branch
`claude/realtime-signalr` until merged; run § S1 first): rank, group node edit, direct grant, offline answers (#76),
group fan-out, balances, freeze, mode, other user fields, pushed notifications, hub-down fallback, resync.

**Deploy notes:** API: no migration, no new setting or secret. Plugin: optional `realtime.fallback-poll-multiplier: 4`
in the `realtime:` block (missing = 4). Still `realtime.enabled: false` by default.

**Follow-ups filed:** none new; comment on #76 (above).

**Notes for later links**
- Link 8 (WT2, #181): `IRealtimeEventSink` sends to game servers only (`RealtimeEvent.ServerId` null = all); add a web
  target (or call `IRealtimePublisher.PublishToWebUser`) for `WorldTaskUpdated`, through the sink so it waits for the
  commit. `HubPlayerNotificationQueue.PushPendingTo` (called from `GameServerHub.PlayerJoined`) is the pattern for
  offering a queued task when its player joins.
- Link 10 (S3, #182): the after-commit sink is in place; the `SaveChangesInterceptor` should hand `RealtimeEvent`s to
  `IRealtimeEventSink` and needs no commit handling of its own. When an event lands, wrap its timer with
  `KnKPlugin.fallbackPolling` (`throttle(...)` for fixed-rate timers, `interval(...)` for self-rescheduling ones). A
  generic `EntityChanged(User)` can call `UserStateSync`'s re-read path. Resync steps are registered in
  `KnKPlugin.registerUserStateSync`/`initializeRealtime`.

## Link 5 — #64 (FormWizard part), #109, #186: form wizard footer, leave guard, validation, Save on any step; drafts per admin

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-10-26; finished 2026-10-26. Nothing else ran at
the same time. Worktrees under `/home/user/wt-link5/` (the coordinator's checkouts untouched).
**Base:** knk-web-app `main` `7ba0f4b` (links 1–3 merged), knk-web-api `master` `6f08383`, knk-workspace `main` `baf99a4`.
Before the final push the trunks had moved (alpha run 1 merges): web-app `main` `6b02bb0`, API `master` `4d7a806` and
workspace `main` merged in, no conflicts.

**Commits**
- knk-web-app `claude/form-wizard-edit-mode`: `f4cea8d` FormWizard debug block and console logs removed (#64, first, as
  the charter says); `ffd8a2e` debug logs in FormWizardPage and FieldRenderers; `dd8f973` no `userId = '1'` (#186 web);
  `9c69576` sticky footer, dirty flag, blur validation + error summary, Save on any step in edit mode, single-line input
  (#109); `4a054a9` data router, `useLeaveGuard` (`useBlocker` + `beforeunload`), Cancel in the footer, breadcrumb asks
  (#109); `ca1f238` String field border/padding; `6b3fd8b` merge of `main` `6b02bb0`. Head **`6b3fd8b`**.
- knk-web-api `claude/form-wizard-edit-mode`: `0b55731` drafts and workflow sessions owned by the JWT caller (#186);
  `09305ef` merge of `master` `4d7a806`. Head **`09305ef`**.
- knk-workspace `claude/form-wizard-edit-mode`: `64be9d9` cleanup script, web-app and web-api architecture, smoke test +
  guides README, alpha-go-live § 4.3, CHANGELOG; `5d8a28c` merge of `main`. Head **`5d8a28c`**.

**What changed**
- API (#186): `POST api/FormSubmissionProgress` takes the owner from the JWT and ignores the body's `userId` (401 without
  a user). `GET .../entity?mine=true` (new) or the old `userId` parameter (any value) and `GET .../user` list the caller's
  rows only; without `mine`/`userId` every owner's rows are listed (the relationship-drafts view). `POST api/Workflows`:
  a logged-in caller owns the session; a game-server call without a user keeps the body's owner and must name one (400).
  No migration.
- Web app (#186): the `userId = '1'` constant and the `userId` prop chain (FormWizard, ChildFormModal,
  JoinEntityFormModal, ManyToManyRelationshipEditor) are gone; drafts and sessions are created without a user id; Saved
  Progress sends `mine=true`.
- Web app (#109): footer sticking to the bottom of the window with the page's Cancel (`footerStart`), Previous, Save
  Draft, **Save changes** (edit mode, every step but the last) and Next/Submit; the card lost `overflow-hidden` (it
  stopped `sticky`). Dirty flag (any change; cleared by a successful progress save) → `onDirtyChange` →
  `hooks/useLeaveGuard.tsx`: links, Back/Forward and URL changes ask "Leave this form?" (Stay / Leave form) through
  `useBlocker`; reload/close gets `beforeunload`; the breadcrumb asks through `confirmLeave` (closes L3-2); submit and a
  confirmed Cancel pass (`allowLeave`). `App.tsx` now mounts a data router (`createBrowserRouter`, one catch-all route
  around the existing `<Routes>`) because `useBlocker` needs one. Cancel leaves at once when nothing was created or
  changed. Blur validation shows/clears the field's message; the field's own validations run
  (`utils/forms/fieldRuleValidation.ts`); a refused Next/Save shows `FormErrorSummary` (focus, links that focus the field);
  failed completion conditions and blocking rules are also shown on the form. Save changes checks the current step like
  Next, then every other visible step (`findInvalidOtherStep`), jumps to a step that would refuse the save, else submits
  through the normal submit path. String fields are an `<input>` tied to their label; a text area by setting
  (`multiline`, field editor toggle "Multi-line text"), by name (…Description/…Lore) or when the value has a line break.
- Workspace: `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql` (developer decision 2026-10-26: delete,
  script after a backup, not a migration).

**Tests vs baseline** (Node 22, `npx npm@11 ci`; .NET 8.0.132)
- Web app `npm run test:ci` equivalent (`react-scripts test --watchAll=false`): **1330/1330, 209 suites** (baseline
  1304/1304, 204). New suites: `FormWizard.editModeFooter.ui` (7: footer, input/textarea, blur, summary + focus, dirty,
  edit-mode Save from step 1, Save refused by a later step), `hooks/useLeaveGuard` (5, with a real memory data router:
  link asks / Stay / Leave, own action, allowLeave, beforeunload), `fieldRuleValidation` (5), `stringFieldMultiline` (4),
  `formSubmissionClient.owner` (3); new cases in `FormWizardPage.returnTo` (dirty flag + breadcrumb asks),
  `cancelCreatedEntities` (Cancel without changes), `ChildFormModal.workflowSession` (no userId); updated: shared-field
  test finds the input by its label, required-list test also checks the summary link, "Close" → "Stay".
- `npx tsc --noEmit`: 9 errors, identical to baseline (#63). `npm run build`: compiles, same 24 warnings in the same files
  as `main` (line numbers shifted).
- API: **3356 passed, 4 failed, 88 skipped**; the merged `master` `4d7a806` alone gives 3339/4/88 (the 4 = #99 reds:
  PathResolution ×2, ClientActivityStore, FieldValidationService). New: `Api/DraftAndWorkflowOwnershipTests` (17). The
  root `.sln` still fails `dotnet build` on the `tests/` path case (#106); built the `.csproj` as before.
- Browser check (not a substitute for the live test): the production build served locally with a stubbed API, driven by
  Cypress (Electron): footer is `position: sticky`; Name is an input, Description a text area; blur message; summary link
  focuses Name; nav link and breadcrumb ask, Stay keeps the typed value; Back from an in-app navigation asks; Save Draft
  clears the question; Leave form follows the link; the draft POST has no `userId`. Spec kept out of the repo.
- Cleanup script: run twice on MySQL 8.0 against a database built from all migrations, with seeded rows (owner as a
  variable): user-1 drafts deleted, another user's child draft unlinked and kept, a draft after `@fixed_since` kept;
  plain session deleted with its steps and task; catalog-scan session, session whose task region is a domain's region
  and one whose region is a sub-region's kept with the reason; second run changed nothing. Road-edge/spawn-area
  branches ran but had no rows.

**Flagged decisions (reversible)**
- **L5-1** Ownership is enforced on create and on "my drafts" lists only. Read/update/delete by id stay open to every
  `knk.admin.content` holder, because the relationship-drafts view (`useRelationshipDrafts`) deliberately lets staff
  resume a colleague's draft; an update keeps the stored owner. Without `mine`/`userId` the entity list still shows all
  owners.
- **L5-2** The old `userId` query parameter means "mine" whatever its value (an older client sent `1`); `mine=true` is
  the new spelling. `GET .../user` ignores its parameter.
- **L5-3** A draft POST without a logged-in user answers 401; `POST api/Workflows` from the game server (no user) keeps
  the body's owner and needs one (the plugin doesn't call it today; the API's own catalog-scan sessions are unaffected).
- **L5-4** Cleanup script: lives in knk-workspace `scripts/maintenance/` next to `remove-seeded-examples.sql` (the
  precedent the decision names). Besides deleting, it keeps catalog-scan sessions (server-created for the real admin) and
  sessions whose world task's `tempregion_worldtask_<id>` is still a region of a domain, sub-region, spawn area or road
  edge (DomainWorldResolver reads the world from that task), with the reason; `@fixed_since` (default now, UTC) protects
  user 1's own rows created after the deploy; other users' child drafts of a deleted draft lose the parent link.
- **L5-5** Data router: `createBrowserRouter([{ path: '*', element: <AppContent/> }])` around the existing `<Routes>`
  (smallest change). The guard blocks a change of path or query (not hash) while dirty.
- **L5-6** Dirty = changed since the form opened or the last successful progress save. Next saves the progress, so after
  Next nothing asks (the draft holds the values); a world-task result counts as a change.
- **L5-7** Save changes is a separate button in edit mode on every step but the last (the last keeps Submit). It checks
  the other steps with the local rules and the stored blocking API results; API rules of steps never opened are not run
  live (they run on the API's save as before).
- **L5-8** Blur shows "X is required" also when the field was only tabbed through.
- **L5-9** String fields: one line unless `multiline: true` in settings, the name ends in Description/Lore (and no
  setting), or the value has a line break. The toggle writes `true`/`false` explicitly.
- **L5-10** No `<form>` element: a submit inside a child form modal would bubble through React's portal to the parent's
  form. Enter in a field does not submit.
- **L5-11** The wizard's field validations (MinLength/MaxLength/Range/Regex/Email, parameters `min`/`max`/`minLength`/
  `maxLength`/`pattern`) run client-side now; no builder UI authors them yet, so today they only matter for imported
  configurations.
- **L5-12** The leave dialog's buttons are "Stay" / "Leave form" (Cancel's own "Leave this form?" too; it said "Close").
- **L5-13** #64 scope: `FormWizard.tsx` plus `FormWizardPage.tsx` (link 1 left its logs for this link) and
  `FieldRenderers.tsx` (changed anyway). JoinEntityFormModal / ManyToManyRelationshipEditor debug logs stay (#64 comment).
- **L5-14** The String field got `border px-3 py-2`: in its error state it had no border width (#95 comment for the
  other field types).

**Deviations:** none from the plan. The error summary lists the current step's fields (Save jumps to the failing step
first).

**Live checklist:** [guides/form-wizard-edit-mode-smoke-test.md](../guides/form-wizard-edit-mode-smoke-test.md) (workspace
branch `claude/form-wizard-edit-mode` until merged), sections 1–7.

**Deploy notes:** deploy web app **and** API from `claude/form-wizard-edit-mode` together (the web app no longer sends a
user id; an old API would refuse the draft with "UserId is required"). No migration, no setting. Afterwards, once, after a
backup: `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql` (alpha-go-live § 4.3 on the workspace
branch).

**Follow-ups:** comments on #95 (error-state border width) and #64 (remaining debug logs). No new issue.

**Notes for later links**
- Link 7 (#180): drafts and workflow sessions now carry the real caller (`WorkflowsController.Create` sets `UserId` from
  the JWT). Session reads/resume/delete are not owner-checked yet, and `POST api/Workflows` needs `knk.admin.world` (or
  the game server): a content-only admin gets no session (the web app swallows the refusal), so world-task panels don't
  show for them. A silent draft save on the first task (DESIGN §8.7) clears the dirty flag, which is right. FormWizard
  props now include `onDirtyChange` and `footerStart`.
- Link 9: `App.tsx` mounts a data router. The leave guard blocks any path **or query** change while a form is dirty; keep
  page/search/sort URL state away from an open form, or narrow `shouldBlock` in `hooks/useLeaveGuard.tsx`.
- Tests: Jest 27 can't resolve `react-router-dom` v7 directly; blocker tests use
  `jest.mock('react-router-dom', () => jest.requireActual('react-router'), { virtual: true })` with `createMemoryRouter`
  (see `hooks/__tests__/useLeaveGuard.test.tsx`). Components rendered under a mocked router or a `MemoryRouter` skip
  `useBlocker` (no data router context).

### Link 5 — fix round (2026-10-27)

**Started:** subagent of the coordinator, 2026-10-27, after the developer's live test (sections 1, 2, 3, 5 work; 6.1–6.2
work, 6.3–6.4 accepted; 4: steps 1, 2, 4–9 work, step 3 works with two bugs). Own worktrees under `/home/user/wt-link5fix/`.
**Base:** web-app `main` `c3c0c9f` (link 3b) merged into `claude/form-wizard-edit-mode` (`839f284`, clean); workspace `main`
`6216787` merged into the feature branch (`52fa9c0`; one mechanical conflict, the "Last updated" line of
`architecture/web-app-architecture.md`: both notes kept). No API change.

**Bugs, cause, fix** (web-app `ff58c83`, `FormWizard.tsx` + new `utils/forms/formValuesSnapshot.ts`)
1. **Typing then clearing still asked "Leave this form?".** Cause: the dirty flag was set by any change
   (`setDirty(true)` in the change handlers) and never looked at the values. Fix: unsaved changes are the form's values
   compared with a baseline snapshot: every step (hidden-stash values included), '' / null / undefined / [] and an object
   without values are the same empty value, a number equals its text, key order doesn't matter, gate geometry is
   re-derived on both sides. The baseline is taken just before the first change (nothing the load does counts; in edit
   mode it holds the loaded entity, in a resumed draft the draft).
2. **After Next the guard forgot.** Cause: `saveProgress` cleared the dirty flag after **every** successful save,
   including the automatic `InProgress` save behind Next, so step 1's values counted as saved and the nav link,
   breadcrumb and Cancel ("nothing created or changed") let the form go. Fix: only an explicit **Save Draft**
   (`Paused`) and a successful Submit / Save changes re-take the baseline; Cancel uses the same comparison.
3. Found in the browser check (same feature, #109): on a short form, **Cancel right after clearing Name did nothing** —
   the mousedown blurred Name, its "Name is required" message pushed the footer (which sits right under a short form)
   24 px down, and the mouseup missed the button. Fix: a mousedown on a footer button no longer takes the focus from the
   field (`preventDefault` on the footer for button targets); Next/Save still validate the step themselves.

**Tests vs baseline** (Node 22, `npx npm@11 ci`)
- Baseline (branch with `main` `c3c0c9f` merged, before the fix): `npm run test:ci` **1349/1349, 210 suites**;
  `npx tsc --noEmit` 9 errors (#63); `npm run build` compiles, 24 warning lines in 15 files.
- After: **1359/1359, 212 suites** (+10: `formValuesSnapshot` 4; `FormWizard.leaveGuardValues.ui` 6 — with the real
  `useLeaveGuard` in a memory data router and the real `FormCancelAction`: type+clear → nav link and Cancel leave at once;
  fill step 1, Next, then nav link / breadcrumb / Cancel on step 2 all ask; back on step 1 with the name cleared → no
  question; Save Draft → no question, one more change → question, back to the saved value → none; edit mode change and
  revert → Cancel leaves at once; footer mousedown keeps the focus). The 5 guard cases fail on the unfixed code. tsc 9
  (= baseline); build compiles, the same 24 warnings (one line number shifted).

**Browser check** (Chromium via Playwright; production build served locally, API stubbed with `page.route`: a 2-step
Category form Name*/Description → Notes, entity 4 for edit mode). Unfixed build (`839f284`): type+clear then nav link
and breadcrumb **asked**; fill step 1, Next, nav link from step 2 **did not ask**. Fixed build: type+clear (Name and
Description) → nav link, breadcrumb and Cancel leave at once, no question; fill step 1 → Next (one POST, status
InProgress) → nav link, breadcrumb and Cancel each ask, Stay keeps step 2; Previous shows the name, clearing it → nav
leaves without a question; Save Draft (PUT status Paused) → one more letter → asks, back to the saved value → leaves;
edit mode `/forms/Category/edit/4` (Name "Weapons"): changed name → Cancel asks, changed back + Description typed and
cleared → nav leaves. Also: tab out of Name shows "Name is required"; Next with Name cleared shows the summary; a reload
after typing gets the browser's question, and after typing and clearing the `beforeunload` handler is gone again (a
dispatched `beforeunload` is no longer cancelled; a reload a few ms after the clear can still race the effect);
Submit from step 2 goes to the dashboard without a question.

**Workspace** `claude/form-wizard-edit-mode` `1e21ee2`: smoke test Findings for sections 1–7 (developer's results; 4: the
two bugs, fixed in `ff58c83`), new steps **4.3a** (type then clear, also Cancel/breadcrumb and edit mode → no question)
and **4.3b** (fill step 1, Next, leave from step 2 via nav/breadcrumb/Cancel → question), Status/Last updated, guides
README row; web-app architecture (#109 paragraph); CHANGELOG entry.

**Flags:** **L5-6** is replaced: unsaved = the values differ from the baseline (opened with, or last Save Draft / successful
submit); the progress save behind Next keeps the question. **L5-15** A footer button press keeps the focus in the field
(no blur message on mousedown); keyboard users tabbing to a button still get the blur message.

**Notes for later links:** link 7 (#180): a silent draft save on the first task (DESIGN §8.7, `InProgress`) no longer
clears the unsaved state (link 5's note said it did); if it should, call it with `Paused` semantics or re-take the
baseline explicitly. Automated value changes (scan results, world-task results) count as changes because they move the
values away from the baseline.

## Link 3b — #194, #195, #196: dashboard explorer, dashboard header, claim code dash

**Started:** subagent of the coordinator, 2026-10-26; finished 2026-10-26. Follow-up link for the developer's live test
of links 1–3 (merged into knk-web-app `main`).
**Base:** knk-web-app `main` `6b02bb0` for all three branches (unchanged at the end, nothing to merge in); knk-workspace
branches of the same names from `main` `d91fd63` (current at the end). One branch per issue, web app only; nothing in
knk-web-api or knk-plugin. Own worktrees under `/home/user/wt-link3b/`.

**Commits**
- knk-web-app `claude/dashboard-explorer-194`: `29a6883` one scrollbar + favourites. Head **`29a6883`**.
- knk-web-app `claude/dashboard-header-195`: `be4adab` header row spacing. Head **`be4adab`**.
- knk-web-app `claude/claim-code-dash-196`: `b8138e3` mask with the dash from the start. Head **`b8138e3`**.
- knk-workspace `claude/dashboard-explorer-194` **`3aea976`**: web-app architecture, smoke test § 9a, CHANGELOG.
- knk-workspace `claude/dashboard-header-195` **`61dcf23`** (`7dbf061` + wording fix): web-app architecture, smoke
  test § 8a, CHANGELOG.
- knk-workspace `claude/claim-code-dash-196` **`31c41bd`**: account identity architecture § 4, player account guide
  step 4, invitations smoke test step 17a, CHANGELOG.

**What changed (web-app)**
- **#194:** the dashboard's sidebar column scrolled itself as well as the explorer's list (the explorer's `aside` grew to
  its content because a flex item's `min-height: auto`), so a long list showed two vertical scrollbars and a horizontal
  one. Now `.dashboard-sidebar` is `overflow: hidden` and the `aside` is `min-h-0`: only the list under the search box
  scrolls. `ObjectTypeExplorer` takes an optional `favourites` prop (`{ entityNames, onToggle }`): a star button per type
  (`aria-pressed`, "Add/Remove {Type} to/from favourites"), favourites first under a "Favourites" heading, the rest
  below a divider; both parts follow the A–Z / Z–A toggle and the search. `ObjectDashboard` keeps them with
  `utils/dashboardFavourites.ts` (localStorage `knk.dashboard.favouriteEntityTypes`, JSON array, try/catch, corrupt or
  blocked storage = none).
- **#195:** the page wrapper's top padding (`pt-16`) is exactly the app header's height, so the dashboard started flush
  against it; the buttons showed that, the title's line height hid it. `ObjectDashboard` root gets `pt-6` (explorer,
  title row and table start 24 px lower, level with each other); the title row is one flex row, items centred,
  `min-h-9`; title `leading-9 text-gray-900` (explicit, see `index.css` h1–h3); "New {Type}" `h-9`; cogwheel `h-9 w-9`
  (was 38 × 38). On a phone a long "New {Type}" label truncates (full name in `title`) so ⚙ stays on screen (it was
  pushed off before).
- **#196:** `ClaimCodeInput` draws an `aria-hidden`, pointer-events-none mask over the input: the empty field shows
  `____-____`, typing keeps the dash and the remaining slots visible (`K7__-____`); from the 4th character the input's
  value holds the dash itself as before. The mask copies the input's computed font, letter spacing, padding and border
  widths and its box (re-aligned on resize via `ResizeObserver`, follows `scrollLeft`), so the typed characters sit on
  the slots. Value, paste, autofill, uppercase, caret and Backspace/Delete across the separator unchanged.
  `CLAIM_CODE_MASK` / `CLAIM_CODE_SLOT` are built from `CLAIM_CODE_SEPARATOR` (still the one constant). The example
  placeholder `K7QH-M2XA` gives way to the mask (the help and error texts keep the example). Used on `/link` and
  `/account/link` (the only two call sites). Fix found in the browser check: selecting the whole field and pasting the
  **same** code without its dash lost the last character (the "only the separator was deleted" rule fired on a paste,
  since #192); that rule now needs a deletion (`inputType` `delete*`, or Backspace/Delete when there is no `inputType`).

**Tests vs baseline** (Node 22, `npx npm@11 ci`)
- Baseline `main` `6b02bb0`: `npm run test:ci` 1304/1304, 204 suites; `npx tsc --noEmit` 9 errors (#63; test files only);
  `npm run build` compiles with the same 24 warning lines in 15 files.
- `claude/dashboard-explorer-194`: **1315/1315, 205 suites** (+11: `dashboardFavourites` 4, `ObjectTypeExplorer` 5,
  `ObjectDashboard` 2); tsc 9; build OK, 24 warnings.
- `claude/dashboard-header-195`: **1305/1305, 204 suites** (+1 `ObjectDashboard` header row); tsc 9; build OK, 24.
- `claude/claim-code-dash-196`: **1311/1311, 204 suites** (+7 in `ClaimCodeInput.test.tsx`: mask 6, same-code paste 1;
  the placeholder case updated); tsc 9; build OK, 24.
- Trial merge of all three and link 5's `claude/form-wizard-edit-mode` on `main`: clean; the dashboard, explorer, auth,
  link and util suites on the result 539/539.

**Browser check** (Chromium via Playwright, each branch's production build served by a small Node stub of the API: an
admin with every node, 40 entity types, 23 rows per table; scrollbars shown with `--hide-scrollbars` off)
- #194, 1280 × 800: before, the explorer showed two vertical scrollbars plus a horizontal one (`.dashboard-sidebar`
  scrollHeight 1652 / clientHeight 704 and the list 1674 / 659); after, one scrollbar in the list, the sidebar no longer
  scrolls, wheel over the explorer moves only the list (header and search stay). Starring Town, Siege, Category put
  them under "Favourites" (gold stars) A–Z, the rest A–Z below a line; stored `["Town","Siege","Category"]`; the same
  order after a reload. At 390 px the drawer shows the stars and scrolls in one place.
- #195, 1280 × 800: before, title, New Town and ⚙ all at y = 65, against the header (bottom 66); ⚙ 38 px, New 36 px.
  After: explorer, title, New Town and ⚙ all at y = 88, both buttons 36 px, title box 36 px on the same row; title left
  edge 304 = table 305 (border), ⚙ right edge 1232 = table 1231. At 390 px ⚙ was off-screen before (x 368–406); after,
  "New Minecraft Ench…" truncates and ⚙ sits at 306–342 inside the content.
- #196, `/link` (logged out) and `/account/link` (unlinked admin), field value → mask: empty `____-____`; `k` → `K` /
  `K___-____`; `7q` → `K7Q_-____`; `h` → `K7QH-` / `K7QH-____`, caret 5; `m2` → `K7QH-M2__`; three Backspaces → `K7Q`,
  `K7Q_-____`; insert in the middle keeps the caret; paste `k7qh m2xa` → `K7QH-M2XA`; select all + paste `K7QHM2XA` →
  `K7QH-M2XA` (baseline build: `K7QH-M2X`, the bug above); Backspace right after the dash → `K7QM-2XA`, caret 3; Delete
  right before it → `K7QM-XA`; programmatic fill `ab12cd34` → `AB12-CD34`; `autocomplete=one-time-code` kept, no
  placeholder. Screenshots at 2× (desktop and 360 px): the typed glyphs sit exactly on the mask's slots, no doubling.

**Flagged decisions (reversible)**
- **L3b-1** (#194) Favourites are **per browser** in localStorage `knk.dashboard.favouriteEntityTypes` (the issue's
  default, like `knk.dashboard.lastEntityType`); per account on the API can come later. Another browser or a cleared
  site starts without favourites.
- **L3b-2** (#194) The sort toggle applies to both parts (Z–A sorts favourites and the rest Z–A); favourites stay on top
  during a search, and their section hides when no favourite matches.
- **L3b-3** (#194) Stars only on the dashboard's explorer; the Entity setup page's explorer has none (the `favourites`
  prop is optional).
- **L3b-4** (#194) The star is always visible (grey outline; gold and filled for a favourite) rather than on hover, so it
  works on touch screens; favourites get a "Favourites" heading and a divider.
- **L3b-5** (#195) The top spacing is on the whole dashboard (`pt-6`: explorer, title row and table), not only on the
  title row, so the columns stay level. Other pages under the same wrapper were not checked (out of scope).
- **L3b-6** (#195) On narrow screens "New {Type}" truncates with "…"; the header row isn't sticky (scrolls with the
  table as before).
- **L3b-7** (#196) Overlay mask with `_` slots in grey and the dash in the text colour, rather than putting slots into the
  input's value (that would break paste, autofill and screen readers). The example placeholder is gone from the field
  (the mask shows the shape; help and error texts keep `K7QH-M2XA`); a caller's own `placeholder` hides the mask while
  empty.
- **L3b-8** (#196) The same-code paste fix (a pre-existing #192 bug in the same component, a few lines) was made on this
  branch rather than filed, as the issue asks to keep paste working.
- **L3b-9** (#196) The register page's link-code field is still unmasked (L2-9); dash or space is still the testers'
  call (L2-10), and the mask follows `CLAIM_CODE_SEPARATOR`.

**Deviations:** none from the issues.

**Merge notes**
- knk-web-app: the three branches merge cleanly into `main` and with each other (#194 and #195 both touch
  `ObjectDashboard.tsx` and its test file, in different places), and with `claude/form-wizard-edit-mode`.
- knk-workspace: mechanical conflicts only — `docs/CHANGELOG.md` "Unreleased" (each branch replaces "(Nothing at the
  moment.)" with its entry: keep all three), and for #194 + #195 the "Last updated" lines of
  `architecture/web-app-architecture.md` and `guides/dashboard-return-smoke-test.md` (keep both notes). The smoke-test
  sections (9a, 8a) and the architecture paragraph edits don't overlap.

**Live checklist**
- **#194** (web-app `claude/dashboard-explorer-194`; full text `guides/dashboard-return-smoke-test.md` § 9a on the
  workspace branch of the same name):
  1. `/dashboard/Town`, window lower than the type list: one vertical scrollbar, inside the panel under the search box;
     none at the panel's edge, no horizontal one. Wheel or drag: only the list moves.
  2. Star Town, Category and one further down: they move to "Favourites" at the top, A–Z; the rest A–Z below; the
     table doesn't change.
  3. Reload / new tab: same favourites; another browser or private window: none.
  4. Z–A: both parts Z–A, favourites on top. Search: favourites that match stay on top.
  5. Unstar: back in the list; no favourites left → no heading.
  6. Phone width: drawer with stars, one scroll area; picking a type closes it, a star doesn't. `/forms`: no stars.
- **#195** (web-app `claude/dashboard-header-195`; § 8a):
  1. `/dashboard/Town`: a gap between the app header and the dashboard; explorer, title and buttons start at the same
     height.
  2. Title and buttons on one row, centred on each other; New Town and ⚙ the same height.
  3. Title left edge = table left edge; ⚙ right edge = table right edge.
  4. Long type name: buttons wrap below the title together. Phone width: long "New {Type}" cut off with "…", ⚙ on
     screen.
- **#196** (web-app `claude/claim-code-dash-196`; `guides/invitations-smoke-test.md` step 17a on the workspace branch):
  1. `/link`, logged out: empty field shows `____-____`.
  2. Type `k`, `7`, `q`: `K___-____` … `K7Q_-____`, the dash always visible, letters on the slots.
  3. 4th character: `K7QH-____`, caret after the dash; finish: `K7QH-M2XA`.
  4. Backspace back across the dash; paste with dash, without, with a space; select all + paste the same code without
     its dash → stays complete; Backspace after / Delete before the dash remove the character beyond; capitals on a
     phone; one-time-code / password-manager fill.
  5. Same on `/account/link` as an unlinked account (a link code with O/L too). Screen reader: one field, label and hint,
     no underscores read.

**Deploy notes:** web app only, per branch. No API, plugin, migration, setting or script.

**Follow-ups:** none filed. The same-code paste bug was fixed on `claude/claim-code-dash-196` (L3b-8).

**Live test (developer, 2026-11-03, on web-app `main`):** every step of #194, #195 and #196 works. Feedback, filed as
new issues and run as follow-up link 3c: #225 (starred types also stay in the normal list: favourites as copies), #226
(a filter button next to sort: has display / form configuration), #227 (hide the entity type overview card above an
open form), #228 (centre all text of the code entry card on `/link` and the invitation code page), #229 (the
`/auth/register` link-code field gets the masked claim-code input: L2-9 / L3b-9 resolved).

**Notes for later links**
- Link 9 (#177 follow-up, "Drafts (n)" / "New with: {config}"): they go into the `data-testid="dashboard-header"` row's
  button group (`flex min-w-0 max-w-full items-center gap-2`, buttons `h-9`) on `claude/dashboard-header-195`; merge it
  first.
- `ObjectTypeExplorer` rows are now `li.flex` with two buttons when `favourites` is set; tests reading `li` text content
  are unaffected (the star has only an `aria-label`).
- `ClaimCodeInput`'s mask needs the input to keep a fixed-pitch font (`font-mono`) for the slots to line up; both call
  sites have it.

## Link 7 — #180 (WT1): world-task hardening and tasks anchored to the draft

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-11-01; finished 2026-11-01. Nothing else ran at
the same time. Own worktrees under `/home/user/wt-link7/` (the coordinator's checkouts untouched).
**Base:** knk-web-api `master` `8df59b7`, knk-web-app `main` `b3b415d` (link 5 merged), knk-plugin `main` `c8232607`,
knk-workspace `main` `b7563d0` (fast-forward). The component trunks had not moved at the end; nothing to merge in.

**Commits**
- knk-web-api `claude/world-task-hardening`: `fed9a9a` schema + migration `20261101153314_AddWorldTaskHardening`
  (`dotnet ef`); `115c418` state machine, task codes, cancel/release/heartbeat/open/applied, draft link, sweep, tests.
  Head **`115c418`**.
- knk-plugin `claude/world-task-hardening`: `0fbbf720` api-client (claim body with the API's field names, claim modes,
  release/cancel/heartbeat/open, task code redacted from logged URLs); `58d6012f` paper (leases + heartbeat, hand back on
  cancel/quit/disable/restart, main-thread chat, UUID keys, `/knk task`, `knk.tasks.any`, headless claim-before-run,
  fail without handler); `21de734e` DTO read test. Head **`21de734e`**.
- knk-web-app `claude/world-task-hardening`: `d7a0896` draft anchoring, reattach/apply, cancel on leave and on Capture
  again/Try again, Cancel task, Cancelled/Expired + Start again, task code, builder task types. Head **`d7a0896`**.
- knk-workspace `claude/world-task-hardening`: `e06c1e0` `specs/world-tasks/README.md` § Lifecycle (as built) + the other
  world-task docs marked historical where they contradict it, API_CONTRACT claim section, web-api/web-app/plugin
  architecture, `guides/world-task-hardening-smoke-test.md` + guides README, CHANGELOG (Unreleased), DESIGN/plan status.
  Head **`e06c1e0`**.

**What was built**
- **API.** `WorldTaskStatuses` (Pending, InProgress, Completed, Failed, Cancelled, Expired; `CanTransition`). `Status` is
  a concurrency token next to a new `RowVersion`, so every write is conditional: a second claimer, a claim that loses a
  race, a complete after a cancel answer **409** `{code, message, status}`; a refused result (validation, gate scan
  apply) fails the task and answers **422** (was 500). Claim only from Pending; the same uuid on the same server is
  idempotent (renews the lease); modes `code` (code checked), `id` (game server checked `knk.tasks.any`), `headless`
  (scan types only), `offer` (#181, `TargetUserId`). The plugin's old claim field names (`serverId`,
  `minecraftUsername`, `linkCode`) are read too: **before, the API stored neither server nor player** (names didn't
  match). Complete/fail/release/heartbeat only from InProgress and by the claiming server (when `serverId` is sent).
  Task codes: `RandomNumberGenerator`, unique among open tasks (retry), lookups ignore closed tasks, case/dashes ignored.
  Creator from the JWT (session owner for the game server). New endpoints: `POST {id}/cancel`, `{id}/release`,
  `{id}/heartbeat`, `{id}/applied`, `GET open?serverId=`, `GET session/{id}/open`,
  `GET api/FormSubmissionProgress/{id}/world-tasks` (latest per field). `POST {id}/status` only takes known statuses and
  allowed transitions. A new task for a field cancels the field's open one; the first task of a draft links the draft to
  its session (`FormSubmissionProgress.WorkflowSessionId`, also saved by the web app). `WorldTaskSweepService` (30 s,
  section `WorldTasks`, optional): Pending past `ExpiresAt` → Expired; InProgress past `LeaseUntil` → Pending (code
  kept, fresh expiry, `ReleaseCount`+1); sessions with no draft and no activity for 7 days → removed with their tasks,
  except sessions with a Completed task or a catalogue scan. Catalogue scan: creator set, an Expired task fails the scan.
- **Plugin.** `tasks/WorldTaskLeases` + `tasks/LeaseTrackingWorldTasksApi` (the `WorldTasksApi` every handler, command and
  the poller use): sends the server id, holds each claim and heartbeats it (`world-tasks.heartbeat-interval-seconds`,
  60); a 409/404 stops the player's handler ("was cancelled in the web app" / "is no longer yours"). Chat `cancel` hands
  the task back (release), `discard` cancels it. Quit (`listeners/WorldTaskQuitListener`), plugin disable (bounded 5 s)
  and startup (`GET open?serverId=`, release what no handler holds) hand tasks back. Handler state in
  `ConcurrentHashMap<UUID,…>`; `WorldTaskChatListener` checks off-thread whether the player has a task and only then
  routes on the main thread (waits up to 2 s to hide the command). `/knk task <code>` with `task-claim` as alias; id
  claims need `knk.tasks.any` (plugin.yml, default op, not seeded); a lost race says who has it; a claimed task without a
  handler is failed with the reason. Headless poller claims (`headless`) before running; a scan whose result can't be
  sent and an item/kit scan that didn't complete go back to Pending. `/knk tasks` / `task-status` know the new statuses.
- **Web app.** `FormWizard` keeps `fieldTasks` (latest task per field; loaded from the draft on resume, updated by the
  panels), `ensureWorldTaskAnchor` saves the draft silently (InProgress) before the first task, applied results trigger
  a draft save + `POST {id}/applied`, unmount (leaving the form, closing a child form) cancels open tasks.
  `utils/forms/worldTaskLifecycle.ts` (`resolveWorkflowSessionId`: a resumed draft or child draft reuses its session).
  `WorldBoundFieldRenderer`: reattaches (`initialTask`), applies a result finished while the form was closed, stops
  polling once closed, "Cancel task" on Pending/InProgress, Cancelled/Expired banners with "Start again", Capture again
  / Try again cancel an open task, "Task code" and `/knk task <code>` with the expiry time. Form builder: only
  `LocationSelection` (default), `ReagionCreate`, `RegionClaim`, `ItemScan`, `KitScan`, `GateBlockScan`,
  `GateOpenedBlockScan` (`utils/forms/worldTaskTypes.ts`); a stored other type shows "(no handler in game)".

**Tests vs baseline** (.NET 8.0.132, Node 22 + `npx npm@11 ci`, JDK 25 toolchain under Gradle on JDK 21)
- API: **3448 passed, 4 failed, 88 skipped of 3540** (baseline 3397 / 4 / 88 of 3489; the 4 = #99: PathResolution ×2,
  FieldValidationService, ClientActivityStore). +51: `Services/WorldTasks/WorldTaskStateMachineTests` (33, real
  repositories on EF InMemory, incl. a two-context claim race), `WorldTaskSweeperTests` (4), `Api/WorldTasksControllerTests`
  (7), draft keeps its session (1), six routes added to `RequireServiceOrPermissionAttributeTests.ProtectedRoutes`;
  `WorldTaskServiceGateScanTests` set up a session. Built with the `.csproj` (root `.sln` path case, #106). No `[MySqlFact]`
  tests written (the conditional update is EF's concurrency token; checked on InMemory only).
- Web app `react-scripts test --watchAll=false`: **1378 passed, 1 failed, 216 suites** (baseline 1364 passed / 1 failed,
  213 suites; the red is `InvitePage.test.tsx`, #204, base red). New: `WorldBoundFieldRenderer.lifecycle` (7),
  `FormWizard.worldTaskDraft.ui` (2: silent draft save → task for the draft → unmount cancels; resumed draft applies a
  finished result, saves, marks applied), `utils/forms/worldTaskLifecycle` (5); phase7 test updated to `/knk task`.
  `npx tsc --noEmit` 9 errors = baseline (#63). `npm run build` compiles, 24 warning lines in the same 15 files.
- Plugin `./gradlew build -x deployToDevServer`: core **2401** (2401), api-client **291** (288; 2 skipped both), paper
  **2364** (2343; 18 skipped both), 0 failures. New: `WorldTaskLeasesTest` (9), `KnkTaskClaimCommandFlowTest` (6),
  `WorldTaskChatListenerTest` (3), `HeadlessWorldTaskPollerClaimTest` (1), registry and Location handler cases,
  `WorldTaskCodeRedactionTest` (3).

**Flagged decisions (reversible)**
- **L7-1** Task codes are unique among open tasks by a check-and-retry, not a unique index: `LinkCode` is `longtext`
  and closed rows hold duplicate codes, so an index needs a type change (not additive). Closed tasks keep their code for
  the record; lookups and claims ignore it. A same-millisecond create race could still pair two codes (36^6 space).
- **L7-2** No "Failed after N releases" (DESIGN §8.2 mentions it as an option): a lapsed lease always releases (Q10);
  `ReleaseCount` is recorded and shown ("handed back in game").
- **L7-3** Id claims: the plugin checks `knk.tasks.any` and sends `claimMode: id`; the API trusts the game server (it
  can't see Bukkit permissions; ops). `knk.tasks.any` is `default: op` in plugin.yml and no seed gives it to a rank.
- **L7-4** `claim`, `complete`, `fail`, `release`, `heartbeat` and `GET open` are game-server only now
  (`[RequirePluginService]`); a web user with `knk.admin.world` could call claim/complete/fail before (nobody did).
- **L7-5** The "only the claiming server" check runs when `serverId` is sent (the new plugin always sends it).
- **L7-6** `POST {id}/cancel` keeps the controller's rule (`knk.admin.world` or the game server): the creator needs
  `knk.admin.world` to create a task at all, so "creator or knk.admin.world" is the same set today.
- **L7-7** In game `cancel` = hand back (release), `discard` = cancel for good (DESIGN: "release, or cancel if the player
  says so").
- **L7-8** The sweep keeps sessions with a Completed task (its output is read later, e.g. a temp region's world) and
  catalogue-scan sessions. Rows from before #180 count from their last update: on the first sweep after the deploy, old
  Pending tasks older than 30 min expire, old InProgress tasks are released (and expire 30 min later), and **every old
  session without a draft link and without a Completed task, older than 7 days, is deleted** (no session had a draft
  link before). Intended (Q18); back up first.
- **L7-9** Draft ↔ session: `FormSubmissionProgress.WorkflowSessionId` (the design's first option); the web app saves
  it and the API also sets it on a draft's first task. Child forms: a child FormWizard anchors its tasks to its own
  child draft; a child that inherits the parent's session (world-task hint) links its draft to the parent's session.
- **L7-10** The silent draft save (first task) and the save after an applied result are InProgress saves: the
  "Leave this form?" question stays (link 5 fix round semantics), although the draft holds the value.
- **L7-11** Leaving the form (FormWizard unmount: Cancel, a link, closing a child form, Save Draft then leave) cancels
  its open tasks (DESIGN §8.6); a reload doesn't, so the draft reattaches. ItemScan/KitScan are marked applied after
  their fan-out finished.
- **L7-12** Reattach shows Pending, InProgress, Failed and Expired; an applied Completed task and a Cancelled one show
  nothing (the field holds the value / the task is history).
- **L7-13** Orphan temp regions: no API-driven deletion. Cancelled/released region tasks never complete, and the region
  handler deletes its temp region when the API refuses the completion or the heartbeat stops the handler. A region
  task that completed for an abandoned form keeps its temp region until `TempRegionRetentionTask` (comment on #34).
- **L7-14** The server id comes from `realtime.server-id` (default `localhost`) without adding link 4's `realtime:`
  block to `config.yml` (avoids a conflict); merging `claude/realtime-signalr` gives one mechanical conflict in
  `KnKPlugin.registerCommands()`.
- **L7-15** Form builder: "Custom" and the Verify*/LocationCapture types are gone from the list; a stored one is shown
  with "(no handler in game)" and kept. `ReagionCreate`/`RegionClaim` stay (the plugin finds the region handler by the
  `WgRegionId` field name).
- **L7-16** A headless scan whose result can't reach the API, and an item/kit scan that didn't complete, go back to
  Pending; a Location/region session whose `save` couldn't be sent keeps its session (the player saves again).
- **L7-17** Task codes are redacted from the plugin's logged URLs and no longer in its log messages; with
  `api.debug-logging` on, response bodies still show `linkCode`. On the API, `by-link-code/{code}` appears in request
  logs at Information: keep `Microsoft.AspNetCore` at Warning outside Development (as L4 noted for the hub).
- **L7-18** `GET by-link-code` answers only open tasks, so `/knk task-status <code>` of a closed task says "not found"
  (use the id).

**Deviations from the plan/design:** L7-2 (no fail after N releases) and L7-13 (no API-driven temp region deletion; the
handler cleanup covers cancelled/released tasks). Otherwise as DESIGN §8.2/§8.7.

**Live checklist:** [guides/world-task-hardening-smoke-test.md](../guides/world-task-hardening-smoke-test.md) (workspace
branch `claude/world-task-hardening` until merged), sections 0–6.

**Deploy notes:** deploy **API, plugin and web app together** (the old plugin runs scans without claiming them, which
the new API refuses; the old web app doesn't link drafts). API: back up, then migration `AddWorldTaskHardening`
(additive: 13 columns on `world_tasks`, `WorkflowSessionId` on `FormSubmissionProgresses`, indexes and FKs); optional
section `WorldTasks` (`PendingTtlMinutes` 30, `LeaseMinutes` 3, `SweepEnabled`, `SweepIntervalSeconds` 30,
`SessionRetentionDays` 7, `SweepBatchSize` 200); no secret. Read L7-8 before the first sweep. Plugin: optional
`world-tasks.heartbeat-interval-seconds` (bundled `config.yml` has it), `realtime.server-id` (default `localhost`);
`knk.tasks.any` for whoever may claim by id. No cleanup script.

**Follow-ups filed:** none new. Comments on [#34](https://github.com/PandiO/knk-workspace/issues/34) (temp regions of
completed tasks for abandoned forms) and [#181](https://github.com/PandiO/knk-workspace/issues/181) (WT2 notes below).

**Notes for later links**
- Link 8 (WT2, #181): schema, `WorldTaskOfferStates` and claim mode `offer` are in place (comment on #181). Merging
  `claude/realtime-signalr` into knk-plugin: `KnKPlugin.registerCommands()` serverId line (both read
  `realtime.server-id`; keep one); a trial merge also conflicts in `user/UserAdminService.java`, which is the realtime
  branch against today's `main`, not this link. knk-web-api: no file is changed by both branches. Register
  `WorldTaskLeases.releaseOrphans()` as a `ResyncHooks` step; `WorldTaskCancelled` can reuse `WorldTaskLeases` `onLost`.
  Web: feed `WorldTaskUpdated` into the panel's `onTaskChange`/state instead of the 2 s poll.
- Link 9 (`PagedEntityTable` URL state): this link changed `FormWizard.tsx` (world-task state, effects), `FormWizardPage.tsx`
  (`handleOpenConfiguration`), `ChildFormModal.tsx`, `FieldEditor.tsx`; merge after this link or expect conflicts there.
- The API sweep runs in every API process (one API instance today, DESIGN §11).

## Link 9 — #39 (rest), #177 follow-up: entity lists URL state, rows as links, "Drafts (n)" and "New with"

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-11-01; finished 2026-11-01. Nothing else ran at
the same time. Own worktrees under `/home/user/wt-link9/` (the coordinator's checkouts untouched).
**Base:** knk-web-app `main` `b3b415d` (links 3 and 5 merged; unchanged at the end, nothing to merge in). knk-workspace
branch from `main` `4d1f3aa`, `main` `50c2c45` (this link's claim) merged in. Not based on link 7's unmerged
`claude/world-task-hardening`.

**Commits**
- knk-web-app `claude/entity-lists-url-state`: `3bc8f22` lootbox and moderation tabs in the URL, player names as profile
  links; `9a15c28` `PagedEntityTable` controlled mode, rows as links, `aria-sort`, `utils/tableQueryParams.ts`; `f77ebff`
  dashboard table state in the URL, row links, "Drafts (n)", "New with", Entity setup opens `?configId=` / `?resume=`;
  `6b2a4eb` merge-safe test (see notes). Head **`6b2a4eb`**.
- knk-workspace `claude/entity-lists-url-state`: `52eac9c` web-app architecture, new
  `guides/entity-lists-url-state-smoke-test.md` + guides README row, CHANGELOG (Unreleased), dashboard hub proposal status;
  `015e5c1` merge of `main`. Head **`015e5c1`**.

**What changed (web-app)**
- `PagedEntityTable`: optional **controlled mode** `query` + `onQueryChange` (page, search, sort, filters from the caller;
  one stable object per distinct value, so no refetch loop; every change goes to `onQueryChange`); the search box follows
  an outside change (Back/Forward); a page past the end moves to the last page (both modes). **`rowHref`**: the first
  cell is an `<a href>` (middle-click, Ctrl/Cmd-click, keyboard); a plain click calls `onRowClick` (the app navigates);
  Ctrl-click and middle-click elsewhere on the row `window.open` the address; ignored while rows are selectable. Sortable
  headers are `<button>`s inside the `th` (keyboard) and the `th` has **`aria-sort`**. No `react-router-dom` import (the
  pickers' tests render it without a router). Without `query` the table works as before.
- `utils/tableQueryParams.ts`: `readTableQuery` / `writeTableQuery` / `toSearch` for `?page=&q=&sort=&dir=desc&f.<key>=`
  (defaults left out, other parameters kept).
- `ObjectDashboard`: the table is controlled from `location.search`; changes `navigate({pathname, search}, {replace:
  true})`; another type opens its bare URL. View, Edit and the row links take their `returnTo` from the location, so they
  come back to the same page/search/sort (link 1's note: free). Rows link to `displayPath(...)` only when View works.
- #177 follow-up: `hooks/useDashboardFormOptions.ts` (the type's form configurations other than the default, A–Z; the
  caller's drafts without Completed/Abandoned, newest first) and `ObjectDashboard/DashboardHeaderMenu.tsx` (popover:
  focus on the first item, ArrowUp/Down, Escape back to the button, click outside closes). A ▾ attached to "New {Type}"
  ("New with", hidden without other configurations) and a "Drafts (n)" chip (hidden without drafts; footer "All saved
  progress (Entity setup)"). `utils/returnTo.ts` `newFormWithConfigPath` (`/forms/{type}?configId=…`) and
  `resumeDraftPath` (`?resume=…`), both with `returnTo`. `FormWizardPage`: `configsLoadedFor` (set when the
  configuration and progress lists finished loading) and one effect that opens the named configuration
  (`handleOpenConfiguration`) or resumes the draft (`handleResumeProgress`) once per request; an unknown configuration
  gives the error toast "That form configuration was not found. Pick one from the list below." and stays on the lists.
- `hooks/useTabParam.ts` (`useSearchParams`, `?tab=`, default left out, unknown = default, `replace`): `LootboxesPage`
  (`initialTab` stays the default) and `UserModerationPage`. Moderation player names are `Link`s to `/admin/users/{id}`
  (row click kept, the link stops the row's second navigate).

**Tests vs baseline** (Node 22, `npx npm@11 ci`)
- Baseline `main` `b3b415d`: `npm run test:ci` **1364 passed, 1 failed, 213 suites** (the red = `InvitePage.test.tsx`
  "keeps the invitation for the tab…", #204); `npx tsc --noEmit` 9 errors (#63); `npm run build` compiles, 24 warning lines.
- After: **1402 passed, 1 failed (#204), 217 suites** (+38). New suites: `PagedEntityTable.controlled` (12: controlled fetch,
  page/sort to `onQueryChange`, debounced search, outside search change, no refetch on an equal query, clamp; `aria-sort` and
  header buttons in both modes; links: plain click, modified clicks left to the browser, row Ctrl/middle-click, none
  without `rowHref` or while selectable), `tableQueryParams` (5), `FormWizardPage.openFromUrl` (4), `UserModerationPage.urlState`
  (3). New cases: `ObjectDashboard` (+11: URL → table query, changes → replace navigate, no navigate for the same query,
  row links with the query in `returnTo`, none without a display configuration; New with / Drafts: hidden, A–Z + keyboard +
  Escape, drafts filtered and sorted + resume, footer link, click outside, failed requests), `LootboxesPage` (+2),
  `returnTo` (+1); the #195 header test follows the split-button wrapper. `tsc` 9 = baseline. Build compiles, **22**
  warning lines: the two `PagedEntityTable` `react-hooks/exhaustive-deps` warnings of the baseline are gone (explicit
  disables with a reason), nothing new.
- Trial merge with link 7 (`origin/claude/world-task-hardening` + this branch): clean (`FormWizardPage.tsx` auto-merged);
  `src/pages`, `ObjectDashboard`, `PagedEntityTable`, `FormWizard`, `Workflow` suites on the result 465/466 (the red =
  #204) after `6b2a4eb`.
- No browser check: no Chromium/Playwright in this environment. The live checklist covers it.

**Flagged decisions (reversible)**
- **L9-1** Table changes (page, sort, search, filter) **replace** the history entry: Back leaves the dashboard type rather
  than stepping back through pages; the URL still holds the view for refresh, sharing and `returnTo`.
- **L9-2** Parameter names `page`, `q`, `sort`, `dir=desc`, `f.<key>` (the item blueprint Category filter: `f.CategoryId`);
  defaults left out; the page size (fixed 10) is not in the URL; an unknown `sort` key goes to the API as before (no
  client-side check).
- **L9-3** Only the dashboard's table is controlled. The wizard's pickers and the Minecraft pickers stay uncontrolled, so
  they never change the URL and link 5's leave guard (blocks query changes while a form is dirty) needed no change.
- **L9-4** Rows as links: the link is the first cell's content; the rest of the row keeps the click, and Ctrl/Cmd-click or
  middle-click on it opens a new tab via `window.open(href, '_blank', 'noopener')`. Types without a published default
  display configuration get no links (as View). The link takes the first column's text colour `text-gray-900`.
- **L9-5** Sortable headers became buttons (keyboard), beyond the `aria-sort` the issue names; their name is the column
  label (no "Sort by" label, so the column header reads as before).
- **L9-6** A page past the end (shared link, rows deleted) moves to the last page, in both modes.
- **L9-7** "Drafts (n)" = the caller's Saved Progress of the type (#186, `mine=true`) **without Completed and Abandoned**,
  child drafts of that type included, newest first (`updatedAt`); no delete from the chip (Entity setup keeps it).
- **L9-8** "New with" is a ▾ split button on New listing every configuration but the default, A–Z (all of them when there
  is no default); hidden when there are none. The ▾ has the accessible name "New {Type} with another form".
- **L9-9** `?configId=` / `?resume=` are handled once per type and value after the lists loaded; they stay in the URL
  while the form is open (a later Cancel without `returnTo` doesn't reopen it). A draft whose configuration is gone does
  nothing, as Resume on the Entity setup page.
- **L9-10** Tabs: `?tab=`, default tab left out, an unknown value reads as the default, switching **replaces** the entry.
  The lootbox Odds tab's selected type is not in the URL.
- **L9-11** Moderation: only the tab is in the URL, not the "All players" search and page (the issue names the tab).
- **L9-12** Bulk actions (#39 CRUD-4, "where they make sense") are not in this link's charter row or plan step A4: split
  into **#205**; #39 moved to `status:in-review` for the rest.
- **L9-13** The header requests (form configurations, drafts) are extras: a failure leaves them out (the API client's usual
  failure toast still shows).

**Deviations:** none from the charter row; bulk actions split off (L9-12).

**Live checklist:** [guides/entity-lists-url-state-smoke-test.md](../guides/entity-lists-url-state-smoke-test.md)
(workspace branch `claude/entity-lists-url-state` until merged), sections 1–6.

**Deploy notes:** web app only. No API, plugin, migration, setting or script.

**Follow-ups filed:** #205 (bulk actions). Comments on #39 and #177.

**Notes for later links**
- **Merge order with link 7:** this branch changes `FormWizardPage.tsx` (a `configsLoadedFor` state + `useRef` next to
  `autoOpenForm`, one effect after the auto-open effect, one line in `loadConfigurationsAndProgress`'s `finally`); link 7
  changes the same file elsewhere (`handleOpenConfiguration`, an import). Either order merges cleanly (trial merge). With
  link 7, resuming a draft from "Drafts (n)" also reuses the draft's workflow session (`resolveWorkflowSessionId` reads the
  draft once more); `FormWizardPage.openFromUrl.test.tsx` therefore doesn't count `getById` calls. `FormWizard.tsx`,
  `ChildFormModal.tsx`, `FieldEditor.tsx`: not touched.
- #183 (web live updates): the dashboard table refreshes through `refreshKey`; `useDashboardFormOptions` reloads per type
  only (add a refresh trigger when drafts are pushed).
- #30 (admin IA): `hooks/useTabParam.ts` is reusable for other tabbed admin pages; #33: `DashboardHeaderMenu` is a small
  popover, not the planned accessible `Dialog`.
- The moderation tab buttons have no `role="tab"` / `aria-selected` (the lootbox page has them); left as is.

**Developer test 2026-11-03 and fix round:** the developer ran the live checklist on 2026-11-03: every step works or is
accepted. § 1 (9 steps), § 2 (5), § 3 (9) and § 6 (5) work; § 4: 4.1 and 4.5 work, 4.3 and 4.4 accepted, 4.2 works but
long form configuration names were cut off in the "New with" menu and hovering didn't show the full name (most
configurations differ only at the end of their name); § 5: 5.1–5.4 work, 5.5 and 5.6 accepted. Fix (subagent,
2026-11-03): knk-web-app `d72194b` — `DashboardHeaderMenu` lets labels and details wrap (no `truncate`) in a menu that
grows with its content between 18rem and 28rem (never wider than the viewport), and every item has a `title` with the
full name and description; the "Drafts (n)" menu shares the component, so draft configuration names wrap too. New
`ObjectDashboard` test for the full name, the wrap and the title in both menus; keyboard navigation unchanged. Checks:
`npm run test:ci` 1403 passed, 1 failed (#204 base red), 217 suites; `tsc` 9 = baseline; build OK, 22 warnings (as
before). Findings filled in the smoke test, workspace `fb27146`. New heads: web-app **`d72194b`**, workspace
**`fb27146`**. Ready to merge.

## Link 8 — #181 (WT2): world tasks over SignalR

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-11-02; finished 2026-11-02. Nothing else ran at
the same time. Own worktrees under `/home/user/wt-link8/` (the coordinator's `/home/user/knk-workspace` untouched).
**Gate waived (coordinator notes 2026-11-02):** link 7 (`claude/world-task-hardening`, #180) is in review, not merged. Link 8
is **stacked on it**: in every repo the current trunk and then `origin/claude/world-task-hardening` were merged into
`claude/realtime-signalr` (merges only, `--no-ff`, no rebase, no force-push, nothing pushed to link 7's branch or a trunk).
**`claude/realtime-signalr` now contains link 7 in all four repos**: merging it later also merges link 7; fixes from the
link 7 test go to `claude/world-task-hardening` and are merged in again.
**Base:** knk-web-api `master` `8df59b7`, knk-plugin `main` `c8232607`, knk-web-app `main` `1c9524d` (branch created from
it; no realtime branch existed in knk-web-app), knk-workspace `main` `33073da`; link 7 heads API `115c418`, plugin
`21de734e`, web-app `d7a0896`, workspace `e06c1e0`. Trunks unchanged at the end (re-checked before the last push).

**Merge commits**
- knk-web-api: `1df2350` (master, no conflict), `8876926` (link 7, no conflict).
- knk-plugin: `f47e3b9c` (main; conflict in `UserAdminService.setFrozen`: kept main's freezer name, #170, and the realtime
  branch's tell-once check, #179), `96b42971` (link 7; conflict in `KnKPlugin.registerCommands()`: both read
  `realtime.server-id` with the same validation, kept link 7's `worldTaskServerId()`).
- knk-web-app: `0f2887e` (link 7, no conflict; main was the branch's base).
- knk-workspace: `8eb3ffe` (main; Last updated lines only), `af281c8` (link 7; status lines of DESIGN/plan/architecture,
  the web-api §6 bullet and the CHANGELOG list, both sides kept).

**Commits (heads)**
- knk-web-api `claude/realtime-signalr`: `11f0e0e` delivery/offers/queue/presence endpoints/hub events + tests; `c8a89ca`
  hand-off picker leaves out the caller; `a27f61e` Replace reason text. Head **`a27f61e`**.
- knk-plugin `claude/realtime-signalr`: `8fa35148` api-client events/offer claim/hand-back, paper `WorldTaskRealtimeSync`,
  accept/decline, poller push. Head **`8fa35148`**.
- knk-web-app `claude/realtime-signalr` (new): `c7a3e85` `@microsoft/signalr`, `RealtimeProvider`, renderer, scan card.
  Head **`c7a3e85`**.
- knk-workspace `claude/realtime-signalr`: `3e8a71b` DESIGN §8.8 + status, plan status, smoke test § WT2 (+ guides
  README), plugin/web-api/web-app architecture, `specs/world-tasks/README.md` § "Over the realtime channel", CHANGELOG,
  `scripts/alpha-web/nginx.conf` `location /api/hubs/`, production-installation note. Head **`3e8a71b`**.

**What was built** (DESIGN §8.8 on the branch is the as-built reference)
- **API.** `POST api/WorldTasks` takes `deliver`: `auto` (default; offered to the creator when their UUID is on a
  *connected* game server, Busy when they hold a task), `code`, `queue`, `replace` (their held task is released with its
  code, Declined, and its handler stopped), `{userId}` (hand-off, Accept/Decline; not online → Declined). New
  `OfferState` strings `Queued` and `Busy` (no migration). `Services/WorldTaskRealtime` publishes through the after-commit
  sink: game hub `WorldTaskOffered`, `WorldTaskCancelled` (web cancel, expiry, Replace, field replaced, scan cancelled),
  `WorldTaskOfferWithdrawn`, `WorldTaskCreated` (headless); web hub `WorldTaskUpdated` to `task:{id}` + `user:{creator}`
  (once per connection: `RealtimeEvent.WebGroups`, `IRealtimePublisher.PublishToWebGroups`) and `CatalogScanUpdated` to the
  starter. Game hub invocation `WorldTaskOfferResult`; `ReportRoster`/`PlayerJoined` offer what waits for those players.
  Web hub `JoinTask`/`LeaveTask` (creator or `knk.admin.world`; `RealtimeConnection.Join/Leave`). Offer claim only while
  Offered; a code claim by someone else withdraws the offer; `release {handBack: true}` = Declined; the queue advances on
  complete/fail/cancel/hand-back. Sweep: offers unanswered after `WorldTasks:OfferTimeoutSeconds` (120) time out. New reads
  `GET api/WorldTasks/active-for-me`, `GET api/Presence/me`, `GET api/Presence/online-staff` (`knk.admin.world`).
- **Plugin.** `paper/realtime/WorldTaskRealtimeSync` (+ `api/realtime/WorldTaskEvents`): auto-claim (checks online,
  `knk.tasks`, nothing open; claims with mode `offer`, starts the handler through `KnkTaskClaimCommand.startClaimed`),
  hand-off `[Accept] [Decline]` (`/knk task accept|decline <id>`, local timeout), answers over the hub, stops a held task at
  once on `WorldTaskCancelled`, runs the headless poll at once on `WorldTaskCreated` (60 s safety net while connected),
  resync step "world tasks" (`releaseOrphans`). In-game `cancel` releases with `handBack`.
- **Web app.** `src/realtime/RealtimeProvider.tsx` (`@microsoft/signalr` 10.0.11; one connection per logged-in tab,
  reconnect, task groups re-joined, re-read on reconnect). `WorldBoundFieldRenderer`: busy check before "Send to Minecraft"
  (Queue / Hand off… / Replace / Cancel, naming the form), "Hand off to…" picker, offer state above the task code (folded
  while an offer is out), live status from `WorldTaskUpdated`. `MinecraftCatalogScanCard` on `CatalogScanUpdated`.

**Tests vs baseline** (baselines re-run on the merged branches before any change; .NET 8.0.132, Node 22 + `npx npm@11 ci`,
JDK 25 toolchain under Gradle on JDK 21)
- API: **3562 passed, 4 failed, 88 skipped of 3654** (baseline 3513 / 4 / 88 of 3605). The 4 = #99 (PathResolution ×2,
  FieldValidationService conditional required, ClientActivityStore), as at baseline. +49: `Services/WorldTasks/WorldTaskDeliveryTests`
  (35: parse, auto/offline/busy/code/headless, queue + offer on completion and on join, replace, hand-off online/offline/unknown
  user, offer claim and every offer answer, code beats the offer, cancel event, quit vs hand-back, rejoin re-offer, busy
  check, sweep offer timeout and expiry event), `Realtime/WorldTaskHubTests` (9: `JoinTask` own/foreign/staff, one update
  per connection, no task code in the payload, offer to the player's server + `WorldTaskOfferResult`, roster/join re-offer,
  headless/cancel to every server, connection groups, web-group sink, `ConnectedServerOf`), `Api/PresenceControllerTests` (4),
  one `ProtectedRoutes` row. Built with the `.csproj` (root `.sln`, #106). No `[MySqlFact]` tests written (offer state
  changes use the #180 concurrency token; InMemory only).
- Web app `npm run test:ci`: **1407 passed, 1 failed, 221 suites** (baseline 1392 / 1, 218 suites; the red is
  `InvitePage.test.tsx`, #204). New: `realtime/RealtimeProvider` (6), `WorldBoundFieldRenderer.realtime` (8),
  `MinecraftCatalogScanCard.realtime` (1). `npx tsc --noEmit` 9 errors = baseline (#63). `npm run build` compiles, 24
  warning lines (none in the changed files).
- Plugin `./gradlew build -x deployToDevServer`: core **2412** (2412), api-client **313** (309; 2 skipped both), paper
  **2406** (2387; 18 skipped both), 0 failures. New: `WorldTaskRealtimeSyncTest` (15), `WorldTaskEventsTest` (4), claim
  command accept/decline (2), poller interval (1), leases hand-back/take (+1).
- Not run: a browser or Java client against a live API (the API hub tests use the .NET client over long polling; the
  plugin parse tests read the JSON the API tests assert).

**Flagged decisions (reversible)**
- **L8-1** Gate waived by the coordinator at the developer's request: stacked on unmerged link 7 (above).
- **L8-2** Web poll **2 s while the web hub is not connected** (the #180 poll, unchanged, so realtime off = today) and a
  **10 s safety poll while connected**. DESIGN §8.5/§8.6 said 10 s only while disconnected and none while connected.
- **L8-3** The busy check (`presence/me` + `active-for-me`) runs only while the web hub is connected and you are online in
  game; otherwise "Send to Minecraft" sends `auto` straight away (the API re-checks: Busy). "Hand off to…" skips it (your
  held task doesn't matter for someone else's), and is shown only while the web hub is connected.
- **L8-4** A busy *race* (API or plugin says busy after the check) shows the task code with a notice instead of the four
  choices again: the task exists already, and Queue/Replace for an existing task would need a new endpoint. Start again
  re-runs the check.
- **L8-5** `WorldTaskOfferResult` only over the hub (DESIGN §6.4), no REST twin; a lost answer ends as TimedOut by the sweep.
  The 120 s timeout also covers auto-claim offers whose server never answers.
- **L8-6** `OfferState` gains `Queued` and `Busy` (string column, 20 chars; no migration).
- **L8-7** Queued tasks keep the 30 min Pending expiry (Q10); a long first task can let a queued one expire (its code shows
  the whole time).
- **L8-8** In-game `cancel` = hand back for good (`handBack`, Declined, not offered again); quit/restart/disable releases keep
  Accepted and are offered again on join/roster (DESIGN §8.6). The queue moves on complete, fail, cancel and a hand-back,
  not on a quit or restart release (the player is gone).
- **L8-9** Replace sets the released task's `OfferState` to Declined (not offered to the same player again; its form shows
  the code) and tells the game server with `WorldTaskCancelled {status: Pending}`.
- **L8-10** `WorldTaskCancelled`, `WorldTaskOfferWithdrawn` and `WorldTaskCreated` go to every game server; a server ignores
  a task it doesn't hold or show (one server today).
- **L8-11** Payloads never carry the task code or the output; the web app reads `GET {id}` once a task is Completed.
- **L8-12** Online for offers = on a **connected** server (`ConnectedServerOf`); a server in its 60 s grace period doesn't
  count (the offer couldn't reach it). `presence/me` uses the same rule.
- **L8-13** `online-staff`: `knk.admin.world` only; `node` limited to `knk.tasks` (default) and `knk.admin.world`; the
  caller is left out.
- **L8-14** A code/id claim by someone else while Offered/Queued/Busy resets `OfferState` to None (no re-offer later) and
  withdraws an open Accept/Decline line.
- **L8-15** `CatalogScanUpdated {scanId, worldTaskId, taskStatus}` has no `progress` (DESIGN §6.5 named it; the scan has no
  progress value); the card reads the scan on each event and polls 15 s while connected (3 s while not).
- **L8-16** The plugin answers `busy` to a second offer while the player has an Accept/Decline line open.
- **L8-17** `@microsoft/signalr` **10.0.11** (2026-08-04), exact; same major as the Java client (10.0.13). Lock change is
  additions only (npm 11).
- **L8-18** Web hub token: the stored access token, one `refreshSession()` when there is none; after a close (the API closes
  on token expiry) the provider restarts with 1/2/5/10/30 s backoff and a fresh token.
- **L8-19** Headless poll: its idle interval (60 s) while connected; `WorldTaskCreated` runs one poll at once.
- **L8-20** Headless tasks are never offered; `WorldTaskCreated` on create and whenever one goes back to Pending (release,
  lease lapse).

**Deviations from the plan/design:** L8-2 (poll intervals), L8-4 (busy race shows the code), L8-15 (no scan progress).
Otherwise as DESIGN §8.3–§8.6.

**Live checklist:** [guides/realtime-smoke-test.md](../guides/realtime-smoke-test.md) **§ WT2** (workspace branch
`claude/realtime-signalr` `3e8a71b` until merged; run § S1 first, and link 7's `world-task-hardening-smoke-test.md`): web hub,
auto-claim, offline = code, busy Queue/Replace, hand-off Accept/Decline/timeout, code beats the offer, web cancel stops at
once, in-game cancel / quit / restart, pushed scans, hub-down fallback.

**Deploy notes:** deploy API, plugin **and web app** from `claude/realtime-signalr` together (they contain link 7: run its
additive migration `AddWorldTaskHardening` after a backup and read L7-8 first). API: no new migration or secret; optional
`WorldTasks:OfferTimeoutSeconds` (120). Proxy: `location /api/hubs/` with `access_log off` (alpha:
`scripts/alpha-web/nginx.conf` on the branch; production: `guides/production-installation.md`); keep
`Microsoft.AspNetCore` logging at Warning (the browser's JWT is in the hub URL). Plugin: nothing new in `config.yml`;
offers need `realtime.enabled: true` and `knk.tasks`. Web app: new dependency `@microsoft/signalr` (`npm ci`).

**Follow-ups filed:** none new.

**Notes for later links**
- Link 9 (`claude/entity-lists-url-state`, in review): a trial merge into this branch's web-app head `c7a3e85` is clean
  (`FormWizardPage.tsx` auto-merges, as with link 7). Link 8 changed none of link 9's files (`PagedEntityTable`, dashboard
  pages); its web-app files are `App.tsx` (provider), `WorldBoundFieldRenderer.tsx`, `MinecraftCatalogScanCard.tsx`,
  `worldTaskClient.ts`, `WorkflowDtos.ts`, `utils/enums.ts`, new `src/realtime/`.
- Link 10 (S3, #182): web events go through `RealtimeEvent.ToWeb(type, payload, groups)` on the same sink; the web client
  listens to the types in `WEB_EVENT_TYPES` (`src/realtime/RealtimeProvider.tsx`): add a type there for #183's
  `EntityChanged`/`PresenceChanged`. `RealtimeConnection.Join/Leave` is ready for `staff`/`entity:{type}` groups (decided by
  the API, DESIGN §7.3). Startup-only siege work (#31) still waits for its `ResyncHooks` step.
- #183 (web live updates): `useRealtimeEvent` + `useRealtimeReconnected` are the consumer pattern; the dashboard's
  `refreshKey` can be bumped from an event.

## Link 10 — #182 (S3): config and entity push

**Started:** subagent (fallback: `add_repo` needed in-session approval), 2026-11-02; finished 2026-11-02. Nothing else ran
at the same time. Own worktrees under `/home/user/wt-link10/` (the link 8 worktrees detached; the coordinator's
`/home/user/knk-workspace` untouched).
**Base:** link 8's heads, knk-web-api `claude/realtime-signalr` `a27f61e`, knk-plugin `8fa35148` (knk-web-app `c7a3e85`
not changed). `origin/master` (API, `8df59b7`), `origin/main` (plugin, `c8232607`) and `origin/claude/world-task-hardening`
(API `115c418`, plugin `21de734e`) were already in the branch, at the start and before the last push: nothing to merge.
knk-workspace `claude/realtime-signalr` `3e8a71b` with `origin/main` `85340ae` merged in at the start (`b934e6b`, no conflict).
Push dry-run passed in all four repos before any change.

**Commits (heads)**
- knk-web-api `claude/realtime-signalr`: `e769c4c` entity interceptor and map, config events, `GateChanged`, `ReportWorlds`
  + tests. Head **`e769c4c`**.
- knk-plugin `claude/realtime-signalr`: `30530a4c` api-client `ConfigEvents`, core `Coalescer`/`EntityChangeRouter`/
  `PendingStartupWork`, recorder retry, gate removal; `eb22a655` paper `ConfigRealtimeSync`, `GateRealtimeSync`, worlds over
  the hub, siege startup retry, slower timers. Head **`eb22a655`**.
- knk-workspace `claude/realtime-signalr`: `b934e6b` merge of `main`; `c04d3df` DESIGN §6.8 + status, plan status, smoke test
  § S3, guides README, plugin and web-api architecture, CHANGELOG. Head **`c04d3df`**.

**What was built** (DESIGN §6.8 on the branch is the as-built reference)
- **API.** `Realtime/RealtimeEntityChangeInterceptor` (EF Core save interceptor, singleton, in `Program.cs` next to the S2
  transaction interceptor) notes watched entities before a save and their modified properties; after a successful save
  it maps them (`Realtime/RealtimeEntityChangeMap`, pure) and hands the events to the after-commit `IRealtimeEventSink`
  (held until an explicit transaction commits, dropped on rollback or a failed save; option C swaps only the sink).
  Events: `EntityChanged {type, id, op, key}` for the DESIGN §6.3 allow-list; `DomainAccessChanged {domainId}`;
  `GameSettingsChanged {scope}` (game, hub); `SiegeConfigChanged`, `LootboxConfigChanged`, `TeleportDestinationsChanged`,
  `NavigationSettingsChanged`, `TelemetryConfigChanged` `{scope}`; `RoadNetworkChanged {world}`. `GateChanged
  {gateStructureId, op}` from `GateStructureService`/`GateDoorService` definition edits. Game hub `ReportWorlds` =
  `PUT api/GameSettings/runtime-worlds` over the hub. No new endpoint, setting or migration.
- **Plugin.** `paper/realtime/ConfigRealtimeSync` (each event → its existing refresh path, merged per section for 500 ms
  by `core/realtime/Coalescer`; `EntityChanged` → `core/realtime/EntityChangeRouter` → the data-access caches of that type,
  the region→domain cache, the grade catalogue, the siege title ranks, the S2 user re-read). `paper/realtime/GateRealtimeSync`
  (one structure reloaded, doors the API no longer has dropped, a deleted structure removed; a gate a running match holds
  waits for `SiegeGateController`'s after-release hook). `GameSettingsManager` reports worlds over the hub while connected.
  Resync step "siege startup work" (`core/realtime/PendingStartupWork`, #31): abort unfinished matches
  (`SiegeMatchRecorder.retryRecovery`), restore stale gates (`SiegeGateController.retryRecovery`), runtime config + title
  brackets (`SiegeService.retryStartup`), each only when it failed at startup. Slower while connected: domain access sync,
  game settings, lootbox runtime, roads, telemetry config, grade catalogue (`setFallbackPolling`).

**Tests vs baseline** (baselines on the branch before any change; .NET 8.0.132, JDK 25 toolchain under Gradle on JDK 21)
- API (`dotnet test`, built with the `.csproj`, #106): **3580 passed, 4 failed, 88 skipped of 3672** (baseline 3562 / 4 / 88
  of 3654). The 4 = #99 (PathResolution ×2, FieldValidationService conditional required, ClientActivityStore), as at
  baseline. +18: `Realtime/ConfigEntityEventTests` (17: map rules per event, collapse, dedupe, ignored user columns,
  runtime-worlds and dirty-flag echoes; the interceptor on an InMemory context: generated id, modified properties,
  delete, unwatched entity, transaction commit/rollback; gate services definition vs runtime writes) and
  `RealtimeHubTests.GameHub_ReportWorlds_RecordsTheReportLikeTheRestEndpoint` (1). No `[MySqlFact]` tests (the
  transaction path uses the sink's transaction switch, as in S2).
- Plugin (`./gradlew build -x deployToDevServer`): core **2420** (2412), api-client **317** (313; 2 skipped both), paper
  **2414** (2406; 18 skipped both), 0 failures. New: `ConfigSyncCoreTest` (5), `SiegeMatchRecorderTest` +2,
  `GateManagerTest` +1, `ConfigEventsTest` (4), `ConfigRealtimeSyncTest` (8).
- Web app: not changed (no tests run).
- Not run: a Java client against a live API, a dev server.

**Flagged decisions (reversible)**
- **L10-1** `GateChanged` is sent explicitly by the gate services for definition edits (create/update/delete, overrides,
  region data, block snapshots), not derived by the interceptor: the game server's own runtime writes (health, open
  state, operational toggles) and the siege lockdown/restore send nothing (no reload loop, no reload in a match).
  Plugin-originated definition writes (region capture, block scans) do send one.
- **L10-2** The other §6.2 events come from the interceptor's map (entity type + modified properties) instead of explicit
  calls in each service listed in DESIGN §6.2: every write path is covered without touching ~20 services. Echo filters:
  the runtime worlds report alone, a road tile's dirty flag alone, a user's presence/password/token/email/salary-payout
  columns alone.
- **L10-3** `EntityChanged` gains an optional `key` (user UUID, region id, menu template key: the keys the plugin caches by)
  and `id: null` = "drop the whole type" when one save touches more than 50 entities of a type (catalogue maintenance,
  seeders).
- **L10-4** `EntityChanged` handlers invalidate caches (and re-read an online user); "refresh open menus that show it"
  (§6.3) was not built: menus re-read on open and their auto-refresh.
- **L10-5** Q12 applied per gate: only a structure a running match holds (`SiegeGateController.isLocked`) waits; other
  gates reload at once. The waiting edit is applied after the round's gates were restored and the API restore answered
  (new after-release hook); a delete stays a delete.
- **L10-6** Bursts are merged per section for 500 ms (one save often sends several events: a structure and its doors, a
  scenario and its spawnpoints, a survey's tiles). A gate reload is one structure via `getByIdWithSnapshots` (not
  `/gate reload` of all gates); a deleted structure leaves the cache, its blocks stay in the world.
- **L10-7** `ReportWorlds` over the hub while connected, no answer (REST returned the settings; a world that adds a world
  settings entry comes back as `GameSettingsChanged`); REST when not connected. The body carries
  `game-settings.server-id` as REST does (not `realtime.server-id`; L4-1 keeps them separate).
- **L10-8** #31's startup work is retried on the hub (re)connect only (DESIGN §4.4 step 3): with `realtime.enabled:
  false` nothing changes, so #31 stays open for that path (comment there). Steps run in order (abort, gates, config),
  each after the previous finished; a failed one does not block the later ones (they were independent at startup too).
  The abort is never retried once this run created a match row (it would end the live match); the gate restore waits
  while a lockdown of this run is active.
- **L10-9** Slower while connected (×`realtime.fallback-poll-multiplier`, L6-1's follow-up): domain access sync (5 → 20
  min), game settings (30 s → 2 min), lootbox runtime (60 s → 4 min; it also re-reads active boxes, which keep their
  `LootboxWorldChanged` notification), road tiles/meta, telemetry config poll, grade catalogue. Not slowed: the entity
  cache TTLs (#121), permission/user TTLs, the headless poll (WT2).
- **L10-10** Teleport: a warp domain's teleport columns, name, location id or world (or a domain becoming/ceasing to be a
  warp) send `TeleportDestinationsChanged`; moving the warp's Location row itself sends nothing (Location is not
  watched; TTL as before). `Domain.IsHub` → `GameSettingsChanged {scope: hub}`.
- **L10-11** `TelemetryConfigChanged` on enhanced target / test run rows; a target's time-based expiry sends nothing (poll).
- **L10-12** No echo suppression by actor: plugin-originated writes that pass the filters (in-game lootbox areas, gate
  captures and scans, road surveys) come back as events; handlers are idempotent and merged.
- **L10-13** `EntityChanged(PermissionGroup)` duplicates S2's `PermissionGroupChanged` (the group list is dropped twice;
  harmless).
- **L10-14** `SiegeMatch*`, `LootboxSpawn`/claims/tokens and the road surveys/seeds/proposals are not watched (runtime
  data the plugin writes or doesn't cache).
- **L10-15** No new config keys and no migration; `realtime.enabled` stays `false` by default and with it off every
  timer, report and startup path is as before.

**Deviations from the plan/design:** L10-2 (config events from the interceptor map rather than per-service calls),
L10-3 (`key`, id-less collapse), L10-4 (no open-menu refresh), L10-8 (#31 retried on the hub path only). Otherwise as
DESIGN §6.2–§6.4.

**Live checklist:** [guides/realtime-smoke-test.md](../guides/realtime-smoke-test.md) **§ S3** (workspace branch
`claude/realtime-signalr` `c04d3df` until merged; run § S1 first): off changes nothing, gate edit, gate edit during a
match, domain access, game/hub settings, siege, lootbox, teleport/navigation, roads, telemetry, cached entities, worlds
over the hub, siege startup work after an API outage at start, slower safety nets.

**Deploy notes:** deploy API and plugin from `claude/realtime-signalr` together (the branch contains links 4, 6, 7 and 8:
see their deploy notes, link 7's migration first). Link 10 itself: no migration, no new setting or secret, nothing new
in `config.yml`; the events need `realtime.enabled: true`.

**Follow-ups filed:** none new; comments on #182 and #31.

**Notes for later links**
- #183 (web live updates): the interceptor's `EntityChanged` can go to a `staff` web group too: add a `RealtimeEvent.ToWeb`
  twin in `RealtimeEntityChangeMap.Map` (the web client listens to `WEB_EVENT_TYPES` in `src/realtime/RealtimeProvider.tsx`).
- #121: with the hub up the entity TTLs only matter for missed events; the TTL work can assume that.
- Option C (outbox): replace the sink factory in `RealtimeSetup` (`RealtimeEntityChangeInterceptor`'s `sinkFor`) with one
  that writes outbox rows in the transaction; the map stays.

## Link 3c — #225, #226, #227, #228, #229: explorer favourites and filter, open form without the type card, code entry pages

**Started:** subagent of the coordinator, 2026-11-03; finished 2026-11-03. Follow-up link for the developer's live test
of link 3b (all steps passed). Issues filed by this link as sub-issues of #24 (label `improvement`).
**Base:** knk-web-app `main` `44f9395` for all five branches; knk-workspace branches of the same names from `main`
`657311e`. Web app only. Own worktrees under `/home/user/wt-link3c/`.

**Commits** (web-app / workspace heads)
- `claude/explorer-favourite-copies-225`: `35486dd` / `53d93fc` (smoke test § 9b, web-app architecture, CHANGELOG).
- `claude/explorer-filter-226`: `f9f5e25` / `c7e4f45` (smoke test § 9c, web-app architecture, CHANGELOG).
- `claude/form-hide-type-card-227`: `d86c4e6` / `a35fb07` (smoke test § 10a, web-app architecture, CHANGELOG).
- `claude/code-entry-centred-228`: `31e4b68` / `593a908` (invitations smoke test 17b, CHANGELOG).
- `claude/register-code-mask-229`: `940bedd` / `e7576df` (invitations smoke test 16 + 17c, account identity § 4, player
  account guide, CHANGELOG).

**What changed (web-app)**
- **#225:** `ObjectTypeExplorer` no longer removes favourites from the list: "Favourites" on top, then "All entity
  types" (heading only while favourites show) with every type; with groups, every type is bucketed as before. Both
  copies are starred and highlighted when selected.
- **#226:** `ObjectTypeExplorer` `filters` prop (`{ id, label, entityNames | null }[]`): a filter button (ListFilter
  icon, `aria-expanded`, badge with the count) right of the sort toggle opens an inline panel under the search row with
  Any / Yes / No radio groups per filter, Clear filters and Done (Escape closes, focus back on the button). Set filters
  narrow favourites and the list; "No entity types match" offers Clear filters. Stored in localStorage
  `objectTypeExplorer.<storageKey>.filters` (`{"displayConfiguration":"no"}`; corrupt = none). `ObjectDashboard` passes
  "Display configuration" (the existing marker's set) and "Form configuration" (new call to
  `formConfigClient.getEntityNames()` = `GET api/FormConfigurations/entity-names`).
- **#227:** `FormWizardPage` renders `EntityMetadataNavigator` only while no wizard is open.
- **#228:** `/link` code step: the form gets `text-center` (intro, label, hint) and so does the error box while the code
  step shows; `/join` code step: the form gets `text-center` (label, hint, the invalid-invitation box).
- **#229:** `RegisterForm`'s link-code field is `ClaimCodeInput foldLookAlikes={false}` with the format hint; state is
  the 8 characters. "Check code" asks `validate-link-code`; on a refusal of a code without U it asks `claim/check`
  (folded) and a live claim code is kept (`savePendingClaim`) and goes to `/link`. The "That's the code from the
  server's disconnect screen" note and the "Continue with this code" label are gone (the shape no longer tells);
  the refusal hint for a possible claim code stays. `normalizeLinkCodeInput` (only used there) removed.

**Tests vs baseline** (Node 22, `npx npm@11 ci`, per branch)
- Baseline `main` `44f9395`: `npm run test:ci` 1422/1422, 220 suites; `npx tsc --noEmit` 0 errors; `CI=true npm run
  build` compiles.
- #225 1424/1424 (+2 explorer, dashboard tests updated for the copies); #226 1431/1431 (+7 explorer, +2 dashboard);
  #227 1424/1424 (+2 `FormWizardPage.entitySetup`); #228 1425/1425 (+2 LinkPage, +1 JoinPage); #229 1425/1425 (+5,
  −2 replaced/removed in `RegisterForm.test.tsx`). All 220 suites, `tsc` 0, `CI=true` build OK on every branch.
- All five merged together on `main`: 1441/1441, `tsc` 0.
- No browser check this time (unit tests only); the mask of #229 copies the input's font and spacing like on `/link`.

**Flagged decisions (reversible)**
- **L3c-1** (#225) Under the favourites the list gets an "All entity types" heading (only while favourites show), so the
  second copy reads as the full list rather than a duplicate.
- **L3c-2** (#226) "Form configuration: Yes" = at least one form configuration (not necessarily a default); "Display
  configuration: Yes" = a published default display configuration, the same rule as the crossed-out eye.
- **L3c-3** (#226) Filters apply to favourites too (a hidden favourite is hidden in both places); dashboard only (the
  Entity setup explorer has no filter button), like the stars.
- **L3c-4** (#226) The panel is inline under the search row, not a popover, so the scrolling list can't clip it; a
  filter whose data is still loading or failed is not offered and its stored choice waits.
- **L3c-5** (#227) The card is hidden for every open form on the Entity setup route (from the dashboard or from the
  setup page), not only for forms opened from the dashboard.
- **L3c-6** (#228) Centred only while the code entry is the whole card: `/link` before verification and `/join` before a
  valid code. `/account/link` (numbered instructions), `/auth/register` and the `/link` verified step stay left-aligned.
- **L3c-7** (#229) Without the dash as a signal, a refused link code without U costs one extra anonymous `claim/check`
  (per-IP lookup limit, as L2-8 for the invitation step); a 429 or network error on `validate-link-code` asks nothing more.
- **L3c-8** (#229) Look-alikes are not folded in the field (O, I, L stay, like `/account/link`); the claim probe folds them.

**Merge notes**
- knk-web-app: the five branches merge cleanly into `main`, with each other (#225 and #226 both edit
  `ObjectTypeExplorer.tsx` and its tests in different places) and with `claude/world-task-hardening` (`d7a0896`) and
  `claude/realtime-signalr` (`c7a3e85`) (#227's one-line `FormWizardPage.tsx` change merges cleanly with both).
- With `claude/design-tokens-95` (#95, `64feecc`): every branch conflicts in `src/components/PagedEntityTable/PagedEntityTable.tsx`,
  which already conflicts between `main` and #95 (not from link 3c). Own conflicts, one hunk each: #226
  `src/components/ObjectTypeExplorer/ObjectTypeExplorer.tsx` (the "No entity types match" block), #228
  `src/pages/auth/LinkPage.tsx` (the error box classes), #229 `src/components/auth/RegisterForm.tsx` (the link-code field's
  classes). #225 and #227 have no own conflict with #95. Suggested order: merge link 3c first (small), then resolve #95's
  token classes onto these lines when #95 is brought up to date with `main`.
- knk-workspace: mechanical conflicts only — `docs/CHANGELOG.md` "Unreleased" (each branch replaces "(Nothing at the
  moment.)": keep all), the "Last updated" lines of `guides/dashboard-return-smoke-test.md`,
  `architecture/web-app-architecture.md` (#225–#227) and `guides/invitations-smoke-test.md` (#228, #229): keep every
  note; #225 and #226 both insert a section after § 9a step 8 (keep § 9b, then § 9c) and edit the favourites sentence
  of the architecture paragraph (keep both).

**Live checklist** (short; full text in the guides named above)
- **#225** (§ 9b): 1. star Town and Category → in Favourites **and** still in "All entity types" at their place;
  2. unstar from either copy → only leaves Favourites; 3. selected favourite highlighted in both places; 4. Z–A and
  search apply to both parts; 5. no favourites → no headings.
- **#226** (§ 9c): 1. filter button right of sort opens Any/Yes/No for Display and Form configuration; 2. Display No →
  only types with the crossed-out eye, badge "1"; 3. Form No/Yes → types without/with a form configuration; 4. nothing
  left → "No entity types match" + Clear filters; 5. Escape/Done closes, table unchanged; 6. reload keeps the filters;
  `/forms` has no filter button.
- **#227** (§ 10a): 1. Dashboard › EnchantmentDefinition › Edit Sharpness → breadcrumb then form, no type card; 2. same
  for New, New with, a draft; 3. `/forms/<Type>` without a form still shows the card; open + Cancel → card back.
- **#228** (step 17b): 1. `/link` code step: all text, label, hint and error centred; 2. verified step left-aligned;
  3. `/join` code entry and its invalid box centred; sign-up form left-aligned.
- **#229** (steps 16, 17c): 1. `/auth/register` link-code field shows `____-____` and the hint; 2. typing, paste,
  Backspace/Delete as on `/link`, O/I/L kept; 3. a valid `/account link` code → "This code belongs to …"; 4. a live claim
  code → `/link` "Verified"; 5. invitation step `ABCD1234` → link-code step filled in as `ABCD-1234`.

**Deploy notes:** web app only, per branch. No API, plugin, migration, setting or script.

### Link 3c — update after #95 (2026-11-03)

At the coordinator's request, after #95 was merged (knk-web-app `main` `c02b365`, knk-workspace `main`):
- **Main merged into every branch** (`--no-ff`, no rebase). Web-app heads: #225 `9c364a5` (merge `4e941c8`, then the
  "All entity types" heading `text-gray-500` → `text-muted`), #226 `64bc998`, #227 `66de410`, #228 `439c8ed`, #229 `f604c99`.
  Workspace heads (main merged, the architecture "Last updated" conflict kept both notes; smoke-test branch lines name
  the new base and the combined branch): `175f484`, `67662ae`, `2efb802`, `b7376f3`, `95c7150`.
- **Conflicts resolved with #95's tokens:** #226 `ObjectTypeExplorer.tsx` (kept the filter's empty state; the whole
  filter UI now uses `border-field`, `text-muted`, `bg-surface(-alt|-hover)`, `border-line`, `border-primary` /
  `text-primary`, badge `bg-primary text-primary-fg`, `ring-focus`), #228 `LinkPage.tsx` (main's `border-danger-line
  bg-danger-soft` box plus the centring; main's broken `field-error-strong` left as is, #230), #229 `RegisterForm.tsx`
  (kept the masked field; its format hint `text-muted`).
- **`claude/link-3c-combined` `cea6b6a`:** `main` `c02b365` plus the five branches (`--no-ff` each, no conflicts), for one
  test checkout; merging into `main` stays per branch.
- **Checks** (Node 22, `npx npm@11 ci`): `main` baseline 1773/1773. #225 1775, #226 1782, #227 1775, #228 1776, #229 1776,
  combined 1792 — all passed, 223 suites; `tsc --noEmit` 0 everywhere; `CI=true npm run build` OK everywhere. `npm run
  lint:colors`: no file of link 3c over the baseline; the report lists only `DashboardHeaderMenu.tsx` (10) and
  `PagedEntityTable.tsx` (6 vs 5), the same on `main` (not from link 3c).
- **Theme check** (combined build, Chromium, stub API, `?theme=current` and `?theme=brand`): explorer favourites +
  "All entity types", the filter panel (active button and badge blue/white in `current`, orange with black text in
  `brand`), `/forms/Town` with the type card, `/link` and `/join` centred (computed `text-align: center` on the label
  and the error box), `/auth/register` masked field `ABCD-1___`. No page errors. The `/link` error text renders in the
  default text colour instead of dark red: #230.
