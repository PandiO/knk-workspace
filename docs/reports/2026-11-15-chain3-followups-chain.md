# Chain 3 follow-ups chain — progress report

**Status:** Running (2026-11-15) · **Last updated:** 2026-11-15

**Issue:** [PandiO/knk-workspace#564](https://github.com/PandiO/knk-workspace/issues/564), links
[#399](https://github.com/PandiO/knk-workspace/issues/399) (L1),
[#290](https://github.com/PandiO/knk-workspace/issues/290) (L2),
[#289](https://github.com/PandiO/knk-workspace/issues/289) (L3),
[#291](https://github.com/PandiO/knk-workspace/issues/291) (L4),
[#288](https://github.com/PandiO/knk-workspace/issues/288) (L5),
[#565](https://github.com/PandiO/knk-workspace/issues/565) (L6, part of #119),
[#574](https://github.com/PandiO/knk-workspace/issues/574) (L7)
**Charter:** [handoffs/CHAIN3_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/CHAIN3_FOLLOWUPS_CHAIN.md).

## 1. Waiting for the developer

1. Nothing. (Kick/ban decided 2026-11-15, see decision 10.)

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Temp region releases | #399 | Merged into next (2026-11-15) | knk-web-api `a0b5ff3f`, knk-workspace `86adf724`; next: api `3b36edc6`, ws `5dafabac` | [knk-web-api#33](https://github.com/PandiO/knk-web-api/pull/33), [knk-workspace#572](https://github.com/PandiO/knk-workspace/pull/572) | green (runs 43702385149, 43702462646) | create_session session_01R1w2Uvbubw539aKYxgnvjR |
| L2 List field cards at 390 px | #290 | Merged into next (2026-11-15) | web-app `8cb616b`, workspace `080a4bdf`; next: app `9b5f9ddf`, ws `9eeb29ff` | [web-app#38](https://github.com/PandiO/knk-web-app/pull/38), [#571](https://github.com/PandiO/knk-workspace/pull/571) | green (PR run; push-run e2e flake #573, re-run green) | create_session session_01R1w2UswAebrDAEEFqUHA3e |
| L3 "Show what uses it" for more refusals | #289 | Merged into next (2026-11-15) | api `98f0c91`, web-app `41c75ca`, workspace `d833cb0a`; next: api `378921c6`, app `2dfd5883`, ws `e8a4e1e8` | [web-api#34](https://github.com/PandiO/knk-web-api/pull/34), [web-app#39](https://github.com/PandiO/knk-web-app/pull/39), [#579](https://github.com/PandiO/knk-workspace/pull/579) | green (PR runs); next: app run 43707033299 pending | subagent (decision 13) |
| L4 Builder rules and templates into the draft | #291 | Merged into next (2026-11-15) | api `a851436`, web-app `0d604fe`, workspace `4fa25605`; next: api `93c3d50f`, app `cd730f29`, ws `0ca9b1b6` | [web-api#35](https://github.com/PandiO/knk-web-api/pull/35), [web-app#40](https://github.com/PandiO/knk-web-app/pull/40), [#583](https://github.com/PandiO/knk-workspace/pull/583) | green (PR runs 43711458740/43711458686 api, 43711488807/43711488760 web) | subagent (two component repos, § 4.1.4); resumed once after a usage-limit stop |
| L5 Lookup applies picker filters | #288 | Merged into next (2026-11-15) | api `95a2954`, web-app `9d82786`, workspace `b1d270f1`; next: api `d8514ed4`, app `990af482`, ws `c6e017ad` | [web-api#36](https://github.com/PandiO/knk-web-api/pull/36), [web-app#41](https://github.com/PandiO/knk-web-app/pull/41), [#587](https://github.com/PandiO/knk-workspace/pull/587) | green (PR runs 43714699624/43714699597 api, 43714715547/43714715574 web) | subagent (two component repos, § 4.1.4) |
| L6 Player profile API part | #565 | Done, in review (2026-11-15) | api `9442502`, web-app `7051b52`, workspace `27d3065a` | [web-api#37](https://github.com/PandiO/knk-web-api/pull/37), [web-app#42](https://github.com/PandiO/knk-web-app/pull/42), [#595](https://github.com/PandiO/knk-workspace/pull/595) | green (PR runs 43720314230/43720314231 api, 43720332163/43720332129 web) | subagent (two component repos, § 4.1.4) |
| L7 Plugin carries out web kick/ban | #574 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs into `next`, the coordinator merges),
   because `.github/workflows/ci.yml` is on `origin/main` of knk-web-api and knk-web-app (checked 2026-11-15).
   Alternatives: (a) old rules, developer merges: no longer apply once CI runs on both trunks.
2. **Bookkeeping on `main`.** Chosen: push bookkeeping commits directly to knk-workspace `main`, because global
   instructions "Branches" rules 9–10 (on `main` `d0a9baf9`) say the knk-workspace ruleset only blocks deletion and
   force pushes and a push dry run to `main` succeeds. Alternatives: (a) a bookkeeping PR merged by me, as the chain
   prompt suggested in case direct pushes are refused: the fallback if a real push is refused.
3. **#119 as a link.** Chosen: a new sub-issue #565 for the API part, because #119 is already a sub-issue of #24 and an
   issue has one parent; moving it would drop it from the UX roadmap. Alternatives: (a) re-parent #119 to #564;
   (b) link #119 without a sub-issue: the chain rules scope every link by its sub-issue.
4. **Tiers.** Chosen: as the developer listed them (#399, #290, #289 `tier:1`; #291, #288, #565 `tier:2`); parent
   #564 `tier:2` (highest of its links).
5. **Decisions in the developer's go.** Recorded on #291 (rules and add-from-template into the draft, option 2) and
   #288 (lookup applies narrowing filters, labels only), so the links don't ask again. Kick/ban for L6 is not settled
   by the go ("ask the developer before building anything that changes moderation behaviour beyond the issue"): asked
   in § 1, default without an answer is to leave it out. Alternatives: (a) let L6 ask: subagent links cannot ask
   (staff chain lesson, decision 11 of its report).
6. **Order and parallelism.** Chosen: L1 ∥ L2, then L3, L4, L5, L6 in the developer's order, because L1 is API-only
   and L2 web-only; L3 is web-only and waits for L2; L4–L6 change both repos. Alternatives: (a) run L3 in parallel
   with L1 if it needs no API: L1 holds knk-web-api only briefly, so the gain is small and L3 may need the API.
7. **Overlap check (2026-11-15).** No open PRs in knk-web-api or knk-web-app; no unmerged `claude/*` branch changes
   `TempRegionReleaseService` or `FormWizard/FieldRenderers.tsx`. The staff chain's L3 (#407) is running on
   `PlayerProfilePage.tsx`: not a blocker for L1–L5; L6 rechecks it and keeps to separate lines. Alternatives: (a) hold
   L6 until the staff chain finishes: decided at L6's start.
8. **Route.** Chosen: `create_session` (variant A) for L1 and L2 with model `claude-opus-5-5`, because each needs one
   component repo; subagents for L4–L6 (two component repos, coordinator skill § 4.1.4). Fallback a subagent.
9. **#387.** Not merged (PR #553 into `next` open): links use today's nodes and say so.
10. **Kick and ban from the web (developer, 2026-11-15).** The developer said yes. Checking knk-plugin `next`
    (`5dc88cf`) showed no handler for a kick or ban sent from the API (in-game `users.kick`/`users.ban` run Paper's
    `/kick`/`/ban` as the viewer), so I asked three questions. Answers: a separate plugin link L7 (#574) with push to
    knk-plugin for that link only; a web ban works like in-game `/ban` (Paper's ban list, permanent, unban by
    `/pardon`); new nodes `knk.kick` and `knk.ban`, both seeded on Staff. Recorded on #565 and in the charter.
    Alternatives offered: (a) all inside L6; (b) no plugin part now; (c) a timed, API-stored ban; (d) `knk.ban`
    Admin-only or both Admin-only.
11. **L1 check and merge (2026-11-15).** Chosen: merge knk-web-api#33 and knk-workspace#572 into `next` with merge
    commits, because every § 6 check held: heads match, both branches contain `next`, CI green on the API PR
    (`build-and-test`, `fresh-database`), scope inside #399 (service, controller route, tests, two docs and the
    CHANGELOG), 6 new xUnit tests (4169 → 4175 passed), decisions logged, no review threads, Codex at its usage limit
    (noted on both PRs). I read the paging loop: it reads due rows by id past the ones it looked at until `max` are
    listed, bounded by the 30-day keep period. Alternatives: (a) ask for a page cap: would bring the starvation back.
12. **L2 check (2026-11-15).** Code and docs pass § 6 (CI green on the PR run, Playwright 110 → 112, scope inside
    #290). The ruleset refused the web-app merge because the push run's `e2e` failed on the flaky
    `data-table.spec.ts:36` (filed by L2 as #573, passed in the PR run): I re-ran the failed job rather than merge
    around it. knk-workspace#571 conflicted with `next` (CHANGELOG entries; the guide header after the #511 full-steps
    change): I merged `origin/next` into the branch (`080a4bdf`), kept both entries, took `next`'s header format with
    the two new automated steps counted (21 of 26) and wrote § 6.2–6.3's tags in the new `[automated: <test>]` form.
    Codex is at its usage limit, so no re-review of that push. Alternatives: (a) send L2 back for the merge: slower for
    a mechanical conflict.
13. **Route for L3.** Chosen: a subagent from the start, because "Show what uses it" for a form configuration needs
    references that are not dashboard types (form steps, fields, sessions), so L3 very likely changes knk-web-api as
    well as knk-web-app (coordinator skill § 4.1.4). L3 has no open developer decision. Alternatives: (a)
    `create_session` and fall back on an `add_repo` refusal: the charter's first plan, changed now that the API part
    looks needed.
14. **L2 merged (2026-11-15).** The re-run of the failed `e2e` job passed; merged knk-web-app#38 (`9b5f9ddf`) and
    knk-workspace#571 (`9eeb29ff`) into `next`. CI on knk-web-api `next` after L1 (`3b36edc6`) is green (build and
    test, fresh-database migrations). Gate for L3 open (both L2 branches 0 commits ahead of `next`). L3 started as a
    subagent.
15. **L3 check and merge (2026-11-15).** Chosen: merge knk-web-api#34, knk-web-app#39 and knk-workspace#579 into `next`
    with merge commits, because § 6 held: heads match; the API branch contains `next`; the web-app branch was 2 commits
    behind (`next` gained the staff chain's #407 on `PlayerProfilePage.tsx`, no shared file) and merged cleanly; CI
    green on both code PRs; no review threads; Codex at its usage limit (noted on the PRs); scope inside #289 (the API
    part was needed: form configurations are not dashboard types); 12 new xUnit, 7 Jest and 5 Playwright tests. I read
    the API access change: `FormConfiguration` references need `knk.admin.content` (Entity setup's node), the per-type
    trimming of V6 is kept, `?all=true` only widens to cascades. Docs PR conflicted (CHANGELOG, two architecture
    headers): merged `origin/next` into it (`d833cb0a`), kept both sides, marked the code as in `next`. Deploy note
    from L3: API before or with the web app (an older API answers 404 for a form configuration). Alternatives: (a) send
    L3 back for the docs merge: slower for a mechanical conflict.
16. **L4 start.** Gate open (L1 and L3 0 commits ahead of `next` in every repo they changed). Subagent route (knk-web-api
    and knk-web-app). The developer's #291 decision is in the prompt. Started while knk-web-app `next` CI after L3 was
    still running; a red result would stop the next merge, not the link.
17. **L4 usage-limit stop (2026-11-15).** The L4 subagent stopped at the 5-hour usage limit after pushing its API and
    web-app commits; I resumed it with a message after the reset (11:56 UTC) instead of starting a new one, so it kept
    its context. Alternatives: (a) a fresh subagent continuing from the pushed branches: loses the link's decisions.
18. **L4 check and merge (2026-11-15).** Chosen: merge knk-web-api#35, knk-web-app#40 and knk-workspace#583 into `next`,
    because § 6 held: heads match, all three branches contain `next`, CI green on both code PRs, no review threads,
    Codex at its usage limit (noted), scope inside #291 and the developer's decision (rules in `DraftJson` by field
    GUID, applied on Publish; add-from-template removed after checking web app, knk-plugin `next` and scripts for
    callers, which the decision allowed), 12 new xUnit tests, 9 Jest, a Playwright spec. I read the Publish apply:
    rule ids from the draft only match rules of this form's own published fields (no cross-form update), refusals for
    dangling fields and circular dependencies, old drafts without the list keep the published rules. One knk-workspace
    merge commit (`4fa25605`) lacks the session trailers (git's default message); not rewritten, since that needs a
    force push. Filed by L4: #582 (draft health check reads published rules). Deploy: API first or together.
    Alternatives: (a) send L4 back to keep the endpoints writing into the draft: no caller exists.
19. **L5 start.** Gate open (L4 0 commits ahead of `next` in all three repos). #387's PR #553 is still open, so today's
    nodes hold. Subagent route.
20. **L5 check and merge (2026-11-15).** Chosen: merge knk-web-api#36, knk-web-app#41 and knk-workspace#587 into
    `next`, because § 6 held (heads match, branches contain `next`, CI green on both code PRs, no review threads, Codex
    at its usage limit, scope inside #288, 16 xUnit, 5 Jest, 2 Playwright tests) and `next` was green after L4 in both
    repos. I read the filter check: per-type allow-list of keys in the type's spelling, ids and flags only, unknown keys
    400 `LookupFilterNotAllowed`, `prefer…` passed only where configured; results stay labels. The charter's note on
    `[EnableRateLimiting("lookup")]` was wrong (none on `LookupController`); L5 left it. Filed by L5: #585. Deploy:
    API first or together. Alternatives: none needed.
21. **L6 start.** Gate open (L5 0 commits ahead of `next`). Overlap recheck: no open PRs in either repo; the group
    colours branch (#260), which claims `UsersController`/`UserService`/`UserDtos`, is fully in `next` (0 ahead), and
    the staff chain's #407 is merged. Subagent route; the developer's kick/ban decisions are in the prompt, and L6 must
    write the realtime event contract for L7.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Temp region releases: serverId required, no starvation (#399)

1. **Scope done.**
    1. knk-web-api `Controllers/WorldTasksController.cs`: `GET api/WorldTasks/temp-region-releases` answers 400 `{ error: "serverId is required." }` for a blank or missing `serverId`, as `GET open` does.
    2. knk-web-api `Services/TempRegionReleaseService.cs`: `ListDueAsync` reads the due rows by id in pages of `ScanLimit` (200) until `max` are listed or no due row is left; an Information log when more than a page waited. `ScanLimit` is now `public const` for the tests.
    3. knk-workspace docs: `architecture/managed-worldguard-regions.md` §7, `specs/world-tasks/README.md` endpoint table, `CHANGELOG.md` "Unreleased" entry. Plugin contract unchanged.
2. **Commits and heads.** knk-web-api `claude/temp-region-releases-399` at `a0b5ff3f` (1 commit, base `next` at `dcbb1f8`); knk-workspace `claude/temp-region-releases-399` at `86adf724` (1 commit plus a merge of `origin/next` for the CHANGELOG, both entries kept).
3. **PRs.** [knk-web-api#33](https://github.com/PandiO/knk-web-api/pull/33) (Part of #399), [knk-workspace#572](https://github.com/PandiO/knk-workspace/pull/572) (Closes #399), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `dcbb1f8`: build 0 errors, 4169 passed, 98 skipped (MySQL, no `KNK_TEST_MYSQL`); result: 4175 passed, 98 skipped, 0 failed (6 new: `ListTempRegionReleases_NeedsAServerId` ×3, `ListTempRegionReleases_PassesTheServerAndMax`, `ListDue_MoreThanAPageOfWaitingRows_DoesNotHideALaterRelease` (checked red on the old service), `ListDue_StopsAtMax_AcrossPages`; own/unassigned releases still covered by `ListDue_ReleasesOfAnotherServerAreLeftOut_UnknownServerGoesToAll`). CI runs 43702385149 / 43702462646 (build-and-test, fresh-database) green.
    2. Known reds: none.
    3. Smoke guide: no step changes.
    4. Codex: at its code-review usage limit on both PRs (said so on each); no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Starvation fix.* Chosen: page by id past the rows looked at, in one call, because it needs no migration and keeps the oldest-first order. Alternatives: (a) "last checked" column ordering: a migration and a write per poll; (b) an in-memory cursor across calls: a release can still wait several polls, lost on restart.
    2. *Cost bound.* Chosen: no page cap, because the 30-day keep period bounds the table. Alternatives: (a) a cap of N pages: starvation again past N×200 waiting rows.
    3. *Where the 400 lives.* Chosen: the controller only, like `GET open`. Alternatives: (a) throw in the service: no other caller, more churn.
6. **Out of scope, noted.** None.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging (no settings, migrations or plugin `config.yml` keys).
9. **Notes for later links.** None; permission nodes not needed (#387 not merged).

### 4.2 L2 — List field cards at 390 px (#290)

1. **Scope done.**
    1. knk-web-app `components/FormWizard/FieldRenderers.tsx` `ListField`: the "Selected (n):" cards wrap at narrow
       widths. The name block keeps at least 12rem and the first line; × and **Edit instance** move to their own line
       under it; a long name wraps (`break-words`) instead of being truncated. Desktop: one row as before. The cards
       are a labelled list (`<ul aria-label="Selected <field label>">`); the name uses `text-success-strong` instead
       of the raw `text-green-900`.
    2. knk-web-app `e2e/form-wizard-list-field.spec.ts` (new, mocked API) and `structureForm` / `structureMetadata`
       in `e2e/fixtures/forms.ts`: 390 px (name fully visible, buttons on screen and not over the name, no sideways
       scroll, × still removes) and 1280 px (one row: name, ×, Edit instance).
    3. knk-workspace: smoke guide `relation-picker-and-delete-details-smoke-test.md` § 6.2–6.3 (both `[automated]`),
       `docs/CHANGELOG.md` entry under Unreleased.
2. **Commits and heads.** knk-web-app `claude/list-field-cards-290` at `8cb616b` (1 commit, base `next` at
   `4278102`); knk-workspace `claude/list-field-cards-290` at `b61c6456` (1 commit, base `next`).
3. **PRs.** [PandiO/knk-web-app#38](https://github.com/PandiO/knk-web-app/pull/38) (Part of #290),
   [PandiO/knk-workspace#571](https://github.com/PandiO/knk-workspace/pull/571) (Closes #290), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app: baseline on `next` `4278102` Jest 304 suites / 2615 tests passed, `tsc` clean, build compiled,
       Playwright 110 passed, `lint:colors` 2389; result on the branch Jest 2615 passed, `tsc` and `typecheck:e2e`
       clean, build compiled, Playwright 112 passed (2 new), `lint:colors` 2388. The new 390 px test fails on the old
       layout (name 26 px wide for 187 px of text); the desktop test passes on old and new. CI: PR run [43702120631](https://github.com/PandiO/knk-web-app/actions/runs/43702120631) e2e and
       build-and-test green; the push run [43702068462](https://github.com/PandiO/knk-web-app/actions/runs/43702068462) e2e red in the
       untouched `e2e/data-table.spec.ts:36` (Enter on a header, try and retry), green in the PR run of the same commit
       and 15/15 locally: a flake, filed as [#573](https://github.com/PandiO/knk-workspace/issues/573).
    2. Known reds (also red on the base): none.
5. **Decisions (DESIGN § 4.3).**
    1. *Wrap or icon button.* Chosen: wrap (buttons on their own line), because the "Edit instance" label stays
       readable and the Jest tests that find it by name keep working. Alternatives: (a) icon-only Edit button: hides
       the label, needs an aria-label, changes desktop too; (b) hide the ID line on phones: frees no width.
    2. *Long names.* Chosen: wrap instead of truncate at every width, because a typical name looks the same and a
       long one stays readable. Alternatives: (a) keep `truncate`: a name longer than the row is still cut;
       (b) wrap on phones only: a breakpoint rule for no gain.
    3. *Colour.* Chosen: `text-success-strong` (text on success tints) for the name. Alternatives: (a) keep
       `text-green-900`: a raw colour in a line already changed.
    4. *Picker list in the spec.* Chosen: the spec presses Escape to close the picker's result list before using the
       card, and #570 tracks the picker bug. Alternatives: (a) fix the picker here: `RelationPicker.tsx` is outside the
       charter's `ListField` scope; (b) click × twice: hides the bug in the test.
6. **Out of scope, noted.** [#570](https://github.com/PandiO/knk-workspace/issues/570): in a relation picker, the first
   tap outside the open result list misses (the in-flow list closes on blur, the page shrinks and moves under the
   pointer).
7. **Blockers.** None. Codex: at its code-review usage limit on both PRs (said so on each); no findings handled.
8. **At merge / what the developer must do.** Nothing beyond merging. No settings, migrations or permission nodes
   (#387 not needed).
9. **Notes for later links.** L3 (knk-web-app): `FieldRenderers.tsx` `ListField` changed only in the selected-cards
   block; the e2e fixture `structureForm` (Structure form with a Districts list field) and the `Districts/search` mock
   in `e2e/form-wizard-list-field.spec.ts` can be reused. Open the picker list and press Escape before clicking near it
   (#570).

### 4.3 L3 — "Show what uses it" for more refusals (#289)

1. **Scope done.**
    1. knk-web-api: `GET api/EntityReferences/{type}/{id}/rows` also takes `FormConfiguration` (new `Services/ReferenceRecordTypes.cs`, read node `knk.admin.content`; used by `RequireReferenceReadAttribute` and the controller). Its blocking references (form fields and form steps that open it as a sub-form) are named by the new `Services/ConfigurationReferenceLabelService.cs` (label or step name, detail line with form, entity type, step, "draft", or "Reusable … template"), `readable: false`, no nodes; without `knk.admin.content` only counted. New `?all=true`: every reference, cascades included (the KNG-162 in-use check's rule). `EntityReferenceRowsService` changed accordingly.
    2. knk-web-app: Entity setup's form configuration Delete (`pages/FormWizardPage.tsx`) passes `refusedDeleteDetails('FormConfiguration', id)` to the "Delete failed" `FeedbackModal` for a 409 `DbConstraint`. New hook `useReferenceDetailsToggle` (`components/ReferenceDetails.tsx`: button + panel for one row) used by `BulkDeleteResultDialog` (replaces its inline toggle) and by `FormWizard/CreatedEntitiesPrompt.tsx` for "skipped: in use" lines (with `all: true`; following a row ends the prompt like Done). `entityReferenceClient.getRows` takes `all`; `ReferenceDetails` takes `emptyText`.
    3. knk-workspace: smoke guide `relation-picker-and-delete-details-smoke-test.md` § 4.8–4.12, § 5.3 (27 of 32 steps automated, one partly), web-api architecture § 5.4, web-app architecture "Show details", CHANGELOG Unreleased entry.
2. **Commits and heads.** knk-web-api `claude/show-what-uses-it-289` at `98f0c91` (1 commit, base `next` at `3b36edc`); knk-web-app at `41c75ca` (1 commit, base `next` at `9b5f9dd`); knk-workspace at `42f40e3d` (1 commit, base `next` at `116b47de`).
3. **PRs.** [PandiO/knk-web-api#34](https://github.com/PandiO/knk-web-api/pull/34) (Part of #289), [PandiO/knk-web-app#39](https://github.com/PandiO/knk-web-app/pull/39) (Part of #289), [PandiO/knk-workspace#579](https://github.com/PandiO/knk-workspace/pull/579) (Closes #289), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `3b36edc` build 0 errors, 4175 passed, 98 skipped (MySQL, no `KNK_TEST_MYSQL`); result 4187 passed, 98 skipped, 0 failed (12 new: 7 in `EntityReferencesControllerTests` incl. `AFormConfiguration_NeedsKnkAdminContent`, `FormFieldsAndSteps_WithoutKnkAdminContent_AreOnlyCounted`, `All_AsksForEveryReference_CascadesIncluded`, `TheController_PassesAllThrough` ×2; 5 in new `ConfigurationReferenceLabelServiceTests`, in-memory DB). Checked red with `FormConfiguration` unlisted and `all` ignored. CI PR runs 43706535991 (build-and-test), 43706535990 (fresh-database) green.
    2. knk-web-app: baseline on `next` `9b5f9dd` Jest 304 suites / 2615 tests (one load flake in a parallel run, 2615/2615 on rerun), `tsc` clean, build compiled, Playwright 114 passed; result Jest 305 / 2622, `tsc` and `typecheck:e2e` clean, build compiled, Playwright 119 passed (new `e2e/entity-setup-delete-details.spec.ts` ×4 with strict mocks: configuration delete refused, other failure, deleted draft's skipped entity, cancelled resumed form's skipped entity; `e2e/dashboard-access.spec.ts` +1 bulk delete in-use row), `lint:colors` 2388 unchanged. New specs failed with the feature removed. CI PR runs 43706550931 (build-and-test), 43706550951 (e2e) green; the #573 flake did not show.
    3. Known reds: none.
    4. Codex: at its code-review usage limit on all three PRs (said so on each); no inline findings.
5. **Decisions (DESIGN § 4.3).**
    1. *Bulk delete.* Chosen: keep AM3's per-row "Show what uses it" (already built), move it into a shared hook and add the e2e proof, because the charter's item was already done in AM3 (LAM3-5) without a Playwright test. Alternatives: (a) leave it untouched: no end-to-end proof; (b) rewrite it on `FeedbackModal`: a modal in a modal.
    2. *Form fields and steps: links.* Chosen: named with a detail line (form, entity type, step), not linked, because they have no page of their own and the detail line says where to change them. Alternatives: (a) link to the form builder of the owning configuration (`/admin/form-configurations/edit/:id`): needs an extra id per row in the DTO (`openAs`/`openId`), additive later; (b) counts only (V6's state): the gap the issue names.
    3. *Read node of a form configuration.* Chosen: `knk.admin.content` (Entity setup and the builders' node; the delete itself also needs `knk.admin.delete`). Alternatives: (a) any area node, as `GET api/FormConfigurations` reads: wider than the page that offers the delete; (b) `knk.admin.delete`: a delete node as a read rule.
    4. *References for "skipped: in use".* Chosen: new `?all=true` (cascades included), because the in-use check counts every reference and the common case (a district held by a street link, a cascading join row) would otherwise show "Nothing blocks the delete any more". Alternatives: (a) blocking only: contradicts the "in use" line; (b) a new endpoint on `FormSubmissionProgress`: two routes for one list.
    5. *Following a row in the created-entities report.* Chosen: ends the prompt as Done does (cancel: leaves the form), then opens the row. Alternatives: (a) open the row and keep the form open underneath: the cancelled form would stay half-closed.
    6. *E2E for the cancelled form.* Chosen: a resumed draft (it pins its recorded entities, so Cancel lists them like a form filled now). Alternatives: (a) create Street and District in child forms in the browser: many more mocks for the same prompt.
    7. *Optional candidates of #44* (readiness errors, import dry-run problems). Chosen: left out, because neither is trivial (no reference list behind them; they need their own detail shape). Alternatives: (a) do them here: outside the charter's must-haves.
    8. *Display configuration delete.* Chosen: not covered, because nothing blocks it (no restricting reference to a display configuration). Alternatives: (a) register it anyway: an empty list.
6. **Out of scope, noted.** None filed.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge knk-web-api#34 and knk-web-app#39 together (API first when deploying; an older API answers 404 for a form configuration, shown as an error line under the button), then knk-workspace#579.
    2. No settings, migrations, nodes or plugin `config.yml` keys. Permission nodes of #387 not needed.
    3. Optional by hand: smoke guide § 4.11 against a real database (the only path where cascade references appear) and § 5.3.
9. **Notes for later links.** `ReferenceRecordTypes.Find` is the place to add another record type to "Show what uses it"; `useReferenceDetailsToggle` gives a per-row button and panel for any list. L4 (#291) touches the builder's draft: `ConfigurationReferenceLabelService` names published rows only (draft-only fields in `DraftJson` are not rows and never block a delete).

### 4.4 L4 — Builder rules and templates into the draft (#291)

1. **Scope done.**
    1. knk-web-api: `FormConfigurationDto.validationRules` (`FormDraftValidationRuleDto`, keyed by field GUID) stored in
       `DraftJson`; `FormConfigurationDraftService` fills it in the builder state (draft list, else the published rules)
       and applies it on Publish (checks first, then delete dropped / clear kept dependencies, `UpdateAsync`, write by GUID,
       all in Publish's transaction); a draft without the list keeps the published rules. Removed the two
       add-from-template endpoints, `FormTemplateReusableService` and the request DTOs.
    2. knk-web-app: `utils/forms/draftValidationRules.ts`; `FieldEditor` keeps the field's rules locally and hands them back
       with Save Field (no `api/field-validation-rules` writes); `ValidationRuleBuilder` picks dependencies by GUID (parent
       form fields by id); `FormConfigBuilder` holds `config.validationRules`, prunes rules of removed fields on save, refuses
       Publish on a dangling dependency; the Publish question names rule changes; dead add-from-template client methods and
       types removed; field edit button gets an accessible name.
    3. knk-workspace (docs branch): smoke test § 11, CHANGELOG, web-api architecture § 5.5, web-app architecture, guides
       index.
2. **Commits and heads.** knk-web-api `claude/builder-draft-rules-291` at `a851436` (1 commit, base `next` at `378921c`);
   knk-web-app at `0d604fe` (1 commit, base `next` at `2dfd588`); knk-workspace at `4fa25605` (docs commit `0ceb9574` plus a
   merge of `origin/next`, base `next` at `e8a4e1e8`).
3. **PRs.** [knk-web-api#35](https://github.com/PandiO/knk-web-api/pull/35), [knk-web-app#40](https://github.com/PandiO/knk-web-app/pull/40),
   [knk-workspace#583](https://github.com/PandiO/knk-workspace/pull/583) (closes #291), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4187 passed / 98 skipped (MySQL tests skipped, no `KNK_TEST_MYSQL`); branch 4199 /
       98; 12 new in `Services/FormConfigurationDraftRulesTests.cs` (draft carries rules; Publish adds/updates/deletes by
       GUID incl. a draft-only field; published-only form keeps its rules; draft without rules keeps the published ones;
       Discard drops rule changes; refusals; parent-form dependency by id; add-from-template gone), checked failing with
       the apply step removed. CI runs 43711458740, 43711458686 green.
    2. knk-web-app: baseline Jest 306 suites / 2631, tsc clean; branch 307 / 2640, tsc clean, build ok, `typecheck:e2e` ok;
       Playwright 133 passed incl. new `e2e/form-builder-draft-rules.spec.ts` (strict API, 2 tests). CI runs 43711488807,
       43711488760 green.
    3. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *add-from-template.* Chosen: remove the two form endpoints (and the service), because no caller exists in the web
       app (since #71), knk-plugin `next` or scripts; the API has no display equivalents (only dead web-app client
       methods, also removed). Alternatives: (a) rewrite them to write into the draft: code for no caller; (b) keep them:
       they still wrote straight into the published rows, against the decision.
    2. *When a rule change reaches the working copy.* Chosen: with the field editor's Save Field (Cancel drops it), like the
       field's other edits in that dialog. Alternatives: (a) apply each rule change at once: Cancel would not undo it.
    3. *Rules of removed fields / dangling dependencies.* Chosen: rules of a field no longer in the form are dropped on save
       (they could not be seen); a rule whose dependency left stays and blocks Publish with a message (web and API).
       Alternatives: (a) drop those silently too: loses a rule without saying so; (b) clear the dependency: the rule's
       path would no longer make sense.
    4. *Draft rule shape.* Chosen: GUIDs for the field and same-form dependencies, an id for a parent form's field, the
       published rule's `id` to edit in place (rule ids stay stable). Alternatives: (a) recreate every rule on Publish:
       simpler, but ids change on every Publish; (b) a rule GUID column: needs a migration.
    5. *Restrict on `DependsOnFieldId`.* Chosen: before `UpdateAsync`, delete dropped rules and clear kept rules'
       dependency, set again after (inside Publish's transaction), so a removed or moved field is never held. Alternatives:
       (a) only clear dependencies that point at removed fields: the repository also re-creates moved fields, so the
       exact set is fragile.
    6. *Missing list.* Chosen: `validationRules` absent in `DraftJson` = the published rules, unchanged; the builder state
       then shows the published rules. Alternatives: none that keep old drafts working.
    7. *Permission nodes.* Today's: form content is `knk.admin.content` (#387 not merged); no new node, no new endpoint.
6. **Out of scope, noted.** [#582](https://github.com/PandiO/knk-workspace/issues/582): the builder's draft health check
   still reads the published rules.
7. **Blockers.** None. Codex at its usage limit on all three PRs (said on each PR); no findings to handle.
8. **At merge / what the developer must do.**
    1. Deploy knk-web-api and knk-web-app together, **API first** (an older API ignores the draft's rules, so they would be
       lost on Save). No migration, no setting.
    2. Optional by-hand check: the real-wizard parts of smoke test § 11.2 and § 11.4.
    3. The knk-workspace merge commit `4fa25605` (merge of `origin/next`) has git's default message without the session
       trailers; it was pushed before I noticed and is not rewritten (no force push).
9. **Notes for later links.** L5 does not touch the builder. `FormConfigurationsController`'s constructor lost four
   parameters (tests build it with five now).

### 4.5 L5 — Lookup applies picker filters (#288)

1. **Scope done.**
    1. knk-web-api: `LookupSearchRequestDto.Filters`; `DashboardLookup.Filters` (`LookupFilter` key + kind `Id`/`Flag`/`Prefer`)
       declared per type in `DashboardLookups.cs` (a subset of the keys each type's repository reads, in its spelling);
       `LookupService.CheckFilters` checks keys (case-insensitive) and values and passes them to the type's own search;
       `LookupController.Search` answers 400 `LookupFilterNotAllowed` / `LookupFilterInvalid` with `filters`. Results stay
       `{ id, label, detail? }`; access rule unchanged.
    2. knk-web-app: `lookupFilterPlan` returns the filters to send (all with a value, `prefer…` included; `excludeIds` kept
       for the page), new `lookupFilterRefusal`; `lookupClient.search(…, filters?)`; `RelationPicker` searches the lookup
       with the filters and shows "This list is narrowed by …" only on a 400 `LookupFilterNotAllowed`.
    3. knk-workspace (docs branch): smoke test § 2.4–2.5, CHANGELOG, web-api and web-app architecture, access model DESIGN
       § 4.6.3.
2. **Commits and heads.** knk-web-api `claude/lookup-picker-filters-288` at `95a2954` (1 commit, base `next` at `93c3d50`);
   knk-web-app at `9d82786` (1 commit, base `next` at `cd730f2`); knk-workspace at `b1d270f1` (1 commit, base `next` at
   `0ca9b1b6`, `next` unchanged since, no merge needed).
3. **PRs.** [knk-web-api#36](https://github.com/PandiO/knk-web-api/pull/36), [knk-web-app#41](https://github.com/PandiO/knk-web-app/pull/41),
   [knk-workspace#587](https://github.com/PandiO/knk-workspace/pull/587) (closes #288), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4199 passed / 98 skipped (MySQL tests skipped, no `KNK_TEST_MYSQL`); branch 4215 / 98;
       16 new in `Api/LookupFiltersTests.cs` (siege teams narrowed by `siegeScenarioId` on the real repository; labels only;
       case-insensitive keys forwarded in the search's spelling; unknown key 400 and no search, e.g. a user's `email`;
       `excludeIds` refused; invalid ids/flags 400; `prefer…`; users still username-only; filter list pinned per type;
       access rule unchanged), 3 checked failing with the filters dropped. CI: PR runs 43714699624 / 43714699597, push
       runs 43713637449 / 43713637401.
    2. knk-web-app: baseline Jest 307 suites / 2640, tsc clean, Playwright 133; branch Jest 307 / 2645, tsc clean,
       `typecheck:e2e` ok, build ok, Playwright 135 incl. new `e2e/relation-picker-lookup-filters.spec.ts` (strict API, 2
       tests; the first fails on the old picker). CI: PR runs 43714715547 / 43714715574, push runs 43714471627 / 43714471565.
    3. Known reds: none. Smoke guide: 28 of 33 steps automated.
5. **Decisions (DESIGN § 4.3).**
    1. *Unknown filter key.* Chosen: 400 `LookupFilterNotAllowed` naming the keys, because ignoring it would hand the
       picker a wider list than the form accepts (what LV6-3 avoided). Alternatives: (a) ignore it: silent widening.
    2. *Which keys per type.* Chosen: an explicit allowlist per type next to its label (one place, the search still applies
       the filter), ids and flags only. Alternatives: (a) pass every key to the search: `email`/`uuid` would let a lookup
       find a user by what a label never shows; (b) also enum/text keys (`gateType`, `openedState`, `world`, `name`): a
       search skips an unparsable enum, so they need their own check; easy to add when a form uses them.
    3. *Unusable values.* Chosen: 400 `LookupFilterInvalid` for a non-positive/non-numeric id, a non-boolean flag or a
       blank value, because the searches skip those and would list every row. Alternatives: (a) pass through: widening.
    4. *`prefer…` filters.* Chosen: passed on where the type's search takes them (Clan `preferTownId`), otherwise left out
       without an error (they only order). Alternatives: (a) 400: refuses a picker over an ordering hint; (b) drop all as
       before: loses the town ordering for no reason.
    5. *`excludeIds`.* Chosen: not a lookup filter; the picker keeps applying it on the page. Alternatives: (a) send it:
       only Category's search reads it, so it would 400 elsewhere.
    6. *Refusal in the web app.* Chosen: send all filters and show the old "narrowed by" message only on the API's 400,
       so the API stays the single source of truth. Alternatives: (a) publish the allowlist in the metadata and refuse
       before calling: a second copy of the list and a metadata change.
    7. *Rate limit.* The charter assumed `[EnableRateLimiting("lookup")]` on the lookup; `LookupController` has none on
       `next` (the architecture doc says "No rate limit"). Left as it was ("stay as they are"). Alternatives: (a) add it:
       outside the scope.
    8. *Permission nodes.* Today's (#387 not merged); no new node or endpoint.
6. **Out of scope, noted.** [#585](https://github.com/PandiO/knk-workspace/issues/585): the picker runs the type's full
   search once before the metadata is loaded (an extra 403 for lookup-mode viewers; the answer is never shown). #570 lines
   not touched.
7. **Blockers.** None. Codex at its usage limit on all three PRs (said on each PR); no findings to handle.
8. **At merge / what the developer must do.**
    1. Deploy knk-web-api **first** (or together): an older API ignores `filters` and would answer with the unfiltered
       list, which the new picker would show. No migration, no setting, no node.
    2. Optional by-hand check: smoke test § 2.4 with a real siege scenario as staff without `knk.siege.admin.manage`.
    3. Follow-up docs (documentation sub-issue): `guides/admin/staff-web-app-guide.md` relation picker paragraph,
       `guides/README.md` row of the smoke test.
9. **Notes for later links.** L6 (player profile API): the lookup's filter list lives in `DashboardLookups.cs`
   (`filters:` on `Of<…>`); `LookupFiltersTests.LookupFilters_ArePinnedPerType_AndNeverOnUsers` must change with it. L5
   did not touch `PlayerProfilePage.tsx` or the user search.

### 4.6 L6 — Player profile API part, kick and ban from the web (#565)

1. **Scope done.**
    1. knk-web-api: `PUT api/Users/{id}/unfreeze` optional `{ reason }` into the `PlayerUnfrozen` audit entry (empty body
       still allowed for the plugin); `ProfileAccountDto` (`UserDto` + `frozenAt`, `frozenByUserId`, `frozenByUsername`)
       as the profile summary's account; `GET api/statistics/users/{id}/sessions` (`knk.admin.user.manage`, newest first,
       paged, merged accounts included); `POST api/Users/search` filters `online` / `frozen` / `paymentsLocked`, sort keys
       `lastseenat` / `experiencepoints`, UUID with or without dashes, `UserListDto.isFrozen` / `paymentsLocked` /
       `createdAt`; `PlayerModerationController` + `PlayerModerationService`: `POST api/Users/{id}/kick` (`knk.kick`) and
       `/ban` (`knk.ban`), audited (`PlayerKicked` 63, `PlayerBanned` 64), realtime `PlayerKick` / `PlayerBan` v1 to every
       game server; `PermissionEscalationGuard.CanModerateUserAsync`; `StaffPermissions.Kick` / `.Ban`; migration
       `20261115125459_SeedStaffKickBanNodes` (Staff gets both, data only).
    2. knk-web-app: `usePlayerFreeze` reads the frozen state from the summary (no `GET api/Users/{id}`, no audit lookup),
       `UNFREEZE_TAKES_REASON = true`; game sessions as the third `TimelineSource` (chip "Game sessions");
       `usePlayerKickBan` with Kick / Ban in the status strip and a Kick and ban card on the Moderation tab (replaces the
       LV3-7 note), "Requires knk.kick / knk.ban" without the node; moderation search: Online / Frozen / Payments selects
       (in the URL), Last seen and XP sortable, Frozen / Payments locked chips, Created column.
    3. knk-workspace (docs branch): smoke test § 7 (18 steps, 15 tagged, 5 partly) and § 2.2, 2.5, 3.1; realtime DESIGN
       § 6.10 (the event contract); web-api architecture § 5.7; web-app architecture; CHANGELOG.
2. **Commits and heads.** knk-web-api `claude/player-profile-api-119` at `9442502` (1 commit, base `next` at `d8514ed`);
   knk-web-app at `7051b52` (1 commit, base `next` at `990af48`); knk-workspace at `27d3065a` (2 commits incl. a merge of
   `origin/next` at `fd53a7d6`, CHANGELOG both sides kept; base `next` at `c6e017ad`).
3. **PRs.** [knk-web-api#37](https://github.com/PandiO/knk-web-api/pull/37), [knk-web-app#42](https://github.com/PandiO/knk-web-app/pull/42),
   [knk-workspace#595](https://github.com/PandiO/knk-workspace/pull/595) (closes #565), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4215 passed / 98 skipped; branch 4277 / 100 (MySQL tests skipped without
       `KNK_TEST_MYSQL`). New: `Api/PlayerModerationTests.cs` (incl. `ModerateRankGuardTests`), `Api/PlayerProfileApiTests.cs`,
       `Migrations/SeedStaffKickBanNodesTests.cs`, MySQL `SeedStaffKickBanNodesMySqlTests`, `UserSearchFiltersMySqlTests`
       (both run locally on MySQL 8.0 and green; the whole `requires-mysql` category 99/100). New tests checked failing with
       the behaviour broken. CI: push runs 43718315480 / 43718315464 green; PR runs 43720314230 / 43720314231 green.
    2. knk-web-app: baseline Jest 307 suites / 2645, tsc clean, Playwright 135; branch Jest 308 / 2672, tsc clean,
       `typecheck:e2e` ok, `CI=true npm run build` ok, Playwright 146 (new `e2e/player-profile-moderation.spec.ts`, 11
       tests). CI: push runs 43719938142 / 43719938215 green; PR runs 43720332163 / 43720332129 green.
    3. Known reds: MySQL `MinecraftCatalogMySqlTests.UpgradePath…` (also red on `next`, issue #285; CI does not run MySQL tests).
5. **Decisions (DESIGN § 4.3).**
    1. *Kick and ban reasons.* Chosen: kick reason optional, ban reason required (both at most 200 characters), because a
       ban is permanent and shown on the ban screen, a kick is a quick removal. Alternatives: (a) both required, as
       freeze: slows a routine kick; (b) both optional: a permanent ban without a reason.
    2. *Kick of an offline player.* Chosen: 409 `PlayerNotOnline` (by `User.IsOnline`), nothing audited or sent, because
       there is nothing to kick and an audited no-op misleads. Alternatives: (a) accept and audit: an entry for an action
       that did nothing.
    3. *Delivery when no game server is connected.* Chosen: 503 `NoGameServerConnected` (counted on `RealtimeConnections`),
       nothing audited, because the realtime layer has no outbox and does not replay events on reconnect, and a ban lives
       only in the game server's ban list, so a resync cannot recover it. A server that connects later or a lost message
       still misses the event (documented in DESIGN § 6.10.6); staff repeat the action or use `/ban`. Alternatives: (a)
       accept and audit anyway: silent loss; (b) also queue it in the player notification queue (polled while the hub is
       down): a second delivery path L7 must acknowledge, not offered by the realtime layer as designed; (c) store ban
       state on the user and apply on join: a schema change and a second ban list; (d) an outbox (§ 4.3 option C): new
       mechanism, not built.
    4. *Rank check.* Chosen: `CanModerateUserAsync`: the target's highest group weight must be below the caller's; a
       player in no group can always be acted on; `*` holders may act on anyone and nobody else may act on them; 403
       `EscalationRefused`. Freeze has no rank check, so this follows the group escalation rules (#280) and the plugin's
       in-game freeze rank rule. Alternatives: (a) no rank check, as the API's freeze: Staff could ban an Admin from the
       web; (b) also require holding every node the target holds: too strict for moderation.
    5. *Who may call kick/ban.* Chosen: web users only (`RequirePermission`), because the game server has its own
       `/kick` and `/ban`, and an echo would loop. Alternatives: (a) `RequireServiceOrPermission` like freeze: no caller.
    6. *Event targets.* Chosen: both events to every game server (`ServerId` null): each bans in its own ban list, a kick
       is a no-op where the player is not online. Alternatives: (a) kick only to the presence registry's server: misses a
       stale presence; still possible later in v1 (receivers ignore what is not theirs).
    7. *Idempotency key.* Chosen: `actionId` (GUID) in the payload and the audit details, so L7 can act once on a
       duplicate. Alternatives: (a) the audit entry id: `RecordAsync` returns none.
    8. *Frozen fields shape.* Chosen: a `ProfileAccountDto : UserDto` only on the profile summary, the three fields always
       written (null while not frozen), so `GET api/Users/{id}` and the player's own reads do not expose who froze them.
       Web fallback for an older API: none needed (it still sends `isFrozen` / `frozenReason`; the banner then has no
       since/by), logged here. Alternatives: (a) add the fields to `UserDto`: every user read would carry the staff name;
       (b) keep the old `GET api/Users/{id}` + audit lookup as fallback: two extra calls the API-first deploy avoids.
    9. *Sessions `serverId`.* Chosen: `PlayerStatSession.ServerName` (the plugin's server name), the only server field
       the table has. Alternatives: (a) a new column: no source for another id.
    10. *Sessions and merged accounts.* Chosen: include merged identities (`IdentityIdsAsync`), as every statistics
        read. Alternatives: (a) the account only: loses history after a merge.
    11. *Search `lastseenat` order.* Chosen: id as tie-break; never-seen players first ascending, last descending (MySQL
        NULL order). Alternatives: (a) NULLs always last: needs a computed sort column.
    12. *Unfreeze reason in `UserFrozenChanged`.* Chosen: unchanged (null on unfreeze); the reason is only audited.
        Alternatives: (a) send it: a contract change for no game-side use.
    13. *Permission nodes.* Today's nodes plus `knk.kick` / `knk.ban` (#387 not merged). They are not children of
        `knk.admin`, so `knk.admin.*` does not match them; Admin gets them by inheriting from Staff or through `*`
        (the developer's note said "through knk.admin.* / *"; on the alpha Admin inherits Staff, so the effect is the same).
6. **Out of scope, noted.** Known red #285 (MySQL upgrade-path test) unchanged. No new issue.
7. **Blockers.** None. Codex at its usage limit on all three PRs (review "Failed", said on each PR); no inline findings.
8. **At merge / what the developer must do.**
    1. Apply the migration `SeedStaffKickBanNodes` (Staff gets `knk.kick`, `knk.ban`; data only).
    2. Deploy knk-web-api **first** (or together): an older API has no sessions, kick or ban endpoints.
    3. Kick and ban only take effect in game once L7 (#574) is in `next` and deployed, with the plugin's
       `realtime.enabled: true` (the API answers 503 while no game server is connected to the hub).
    4. By hand: smoke test § 7 steps 3, 8–10, 12, 13, 17, 18 (real game server; 8–10, 13, 18 need L7).
    5. Follow-up docs (documentation sub-issue): staff web app guide (Kick/Ban, search filters), guides index row.
9. **Notes for later links.** L7 (#574): the contract is realtime DESIGN § 6.10 on knk-workspace
   `claude/player-profile-api-119` (and in the report block above). Summary: types `PlayerKick` and `PlayerBan`, `v` 1,
   to every game server, `actor { userId, source: "web" }`; payload `{ actionId, userId, uuid, username, reason,
   staffUserId, staffUsername, at }` (camelCase; `reason` null only on a kick without one; act on `uuid`; dedupe by
   `actionId`). Kick: kick the online player with the reason or the default message. Ban: add the profile to Paper's
   profile ban list, permanent, reason, `staffUsername` as source, online or not; kick if online; idempotent. Register
   both with max version 1 in the `UserStateSync` pattern (`knk-api-client` `UserStateEvents` constants + parse records).
