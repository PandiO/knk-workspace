# Dashboard, form wizard and realtime chain — progress report

**Status:** In progress — links 1–3 merged; links 4, 5 and 6 in review (2026-10-26)
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
| 1 | #177 (link 1), #58 | `claude/kng-60-dashboard-hub` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | create_session session_01Lr2FyBpZG3fDCq51LuFgSM, 2026-10-26 (a first subagent run was stopped by the developer before pushing anything) | — / `df78e73` / — / `7143596` | web-app 1232/1232 (baseline 1214/1214), suites 195 (193); `tsc` 9 errors = baseline; build OK, same warnings |
| 2 | #185, #38, #192 | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — / route-gates `0d14806`, styling `918f6b7`, claim-code `e2a5521` / — / route-gates `6d181c2`, styling `262bca9`, claim-code `4496485` | web-app 1218 / 1218 / 1240, all passed (baseline 1214/1214), suites 194 (193); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 3 | #177 (link 2), #81, #39 (menu) | `claude/kng-60-dashboard-hub` | merged: knk-web-app `main` `7ba0f4b`, knk-workspace `main` `78bf6a3` (2026-10-26, by the coordinator at the developer's request) | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | — / `9a203f8` / — / `186c851` | web-app 1270/1270 (baseline 1232/1232), suites 201 (195); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 3b | #194, #195, #196 (follow-ups of links 1–3) | `claude/dashboard-explorer-194`, `claude/dashboard-header-195`, `claude/claim-code-dash-196` | in review | subagent, 2026-10-26 | — / explorer `29a6883`, header `be4adab`, claim-code `b8138e3` / — / explorer `3aea976`, header `61dcf23`, claim-code `31c41bd` | web-app 1315 / 1305 / 1311, all passed (baseline 1304/1304, suites 205 / 204 / 204 (204)); `tsc` 9 errors = baseline; build OK, same 24 warnings |
| 4 | #178 | `claude/realtime-signalr` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | `b8a29d7` / — / `a64b7f83` / `e878ee2` | API 3338 passed, 4 failed (#99, = baseline reds), 87 skipped (baseline 3296/4/87); plugin core 2319 (2312), api-client 290 (280), paper 2149 (2140), 0 failures |
| 5 | #64 (FormWizard), #109, #186 | `claude/form-wizard-edit-mode` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | `09305ef` / `6b3fd8b` / — / `5d8a28c` | web-app 1330/1330, suites 209 (baseline 1304/1304, 204); `tsc` 9 errors = baseline; build OK, same 24 warnings; API 3356 passed, 4 failed (#99, = baseline reds), 88 skipped (baseline on the merged `master` `4d7a806`: 3339/4/88) |
| 6 | #179 | `claude/realtime-signalr` | in review | subagent (fallback: add_repo needed in-session approval), 2026-10-26 | `38b0466` / — / `b48f1484` / `ae949bd` | API 3361 passed, 4 failed (#99, = baseline reds), 87 skipped (baseline 3338/4/87); plugin core 2323 (2319), api-client 298 (290), paper 2163 (2149), 0 failures |
| 7 | #180 | `claude/world-task-hardening` | waiting: link 5 merged | — | — | — |
| 8 | #181 | `claude/realtime-signalr` | waiting: link 6 done, link 7 merged | — | — | — |
| 9 | #39 (rest), #177 follow-up | `claude/entity-lists-url-state` | waiting: link 5 merged (same web-app files: wizard pickers, coordinator default) | — | — | — |
| 10 | #182 | `claude/realtime-signalr` | waiting: link 8 done | — | — | — |

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that unblock a gate,
flagged decisions.)

- **Links 1, 2 and 3 live-tested by the developer on 2026-10-26:** every step works or accepted. Follow-ups filed:
  #194 (explorer: one scrollbar, favourites on top), #195 (dashboard entity header styling), #196 (claim code field shows
  the dash from the start), #197 (remove "Entity setup" from the nav; not scheduled). #194–#196 run as follow-up link 3b.
- **Test and merge link 5** (#64 FormWizard part, #109, #186): `claude/form-wizard-edit-mode` web-app `6b3fd8b`, API
  `09305ef`, workspace `5d8a28c`; live checklist `guides/form-wizard-edit-mode-smoke-test.md` sections 1–7 on the workspace
  branch. Deploy web app and API together (an old API refuses a draft without `userId`), then back up and run
  `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql` once (alpha-go-live § 4.3). **Its merge opens links 7
  and 9; every remaining link waits on it** (8 on 7, 10 on 8). Flags L5-1…L5-14; L5-1 (any `knk.admin.content` holder can
  open a draft by id), L5-3 (no user = 401).
- **Test link 4** (#178, SignalR S1): API `claude/realtime-signalr` `b8a29d7`, plugin `a64b7f83`; live checklist
  `docs/guides/realtime-smoke-test.md` § S1 on workspace `claude/realtime-signalr` `e878ee2`. `realtime.enabled` is off by
  default. Links 6, 8 and 10 continue this branch, so it is best merged once later unless you want S1 live earlier.
  Flags L4-1…L4-11; the startup-only siege work (#31) stays with link 10 as the charter says.
- **Test link 6** (#179, SignalR S2, same branch): API `38b0466`, plugin `b48f1484`; live checklist
  `docs/guides/realtime-smoke-test.md` § S2 on workspace `claude/realtime-signalr` `ae949bd` (run § S1 first). Flags
  L6-1…L6-12 (link 6 block). L6-1: the ×4 slowdown applies only to the social-spy re-check for now; the notification
  poll stops while connected; the other timers slow down when S3 pushes their changes.

## Coordinator notes

- 2026-10-26: the developer pre-approved attaching `PandiO/knk-plugin`, `knk-web-app`, `knk-web-api`, `knk-dev-db-seed` and `knk-workspace` with `add_repo` (access push) for the coordinator and every link session it creates for this chain. Link prompts carry this as one appended sentence; it was also sent to link 1's session.

## Follow-ups filed by links

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

**Notes for later links**
- Link 9 (#177 follow-up, "Drafts (n)" / "New with: {config}"): they go into the `data-testid="dashboard-header"` row's
  button group (`flex min-w-0 max-w-full items-center gap-2`, buttons `h-9`) on `claude/dashboard-header-195`; merge it
  first.
- `ObjectTypeExplorer` rows are now `li.flex` with two buttons when `favourites` is set; tests reading `li` text content
  are unaffected (the star has only an `aria-label`).
- `ClaimCodeInput`'s mask needs the input to keep a fixed-pitch font (`font-mono`) for the slots to line up; both call
  sites have it.
