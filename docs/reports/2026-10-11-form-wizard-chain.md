# Form wizard chain — progress report

**Status:** Running — link 1 (KNG-133) done 2026-10-12 (restarted as a coordinator subagent); link 2 next.
**Last updated:** 2026-10-12 (link 1 done)
**Charter:** [FORM_WIZARD_CHAIN.md](../ai-agents/handoffs/FORM_WIZARD_CHAIN.md). Append-only below the Summary.

## Summary

| Link | Issue(s) | Status | Heads (web-app / web-api / workspace) |
|---|---|---|---|
| 1 | KNG-133 | **Done** (In Review, live test pending); first attempt blocked (§4.1), restarted 2026-10-12 | `ff12c8f` / unchanged `917537a` / docs + handoff |
| 2 | KNG-134 | Not started | — |
| 3 | KNG-135 + KNG-137 | Not started | — |
| 4 | KNG-136 | Not started | — |
| 5 | KNG-162 | Not started | — |
| 6 | KNG-138 | Not started | — |
| 7 | KNG-139 + write-up | Not started | — |

## Link 0 — chain setup (coordinator)

- Developer decisions 2026-10-11: D1 = A (child forms save their entity as soon as they complete), S1 = A
  (FormConfiguration export/import + seed files imported on request). D2 (what happens to child-saved entities when
  the main form is abandoned) answered with a reversible default and filed as KNG-162: never deleted automatically;
  on an explicit cancel or draft delete the admin chooses Keep (default) or Delete.
- Feature branch `claude/jolly-archimedes-urhio9` created in knk-web-app (`38854ba`), knk-web-api (`917537a`) and
  knk-plugin (`1b3e06c2`) at their trunk heads; knk-workspace carries the specs, this report and the charter.
- Known overlap: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) change
  `FormWizard.tsx`, unmerged. Links keep their own `FormWizard.tsx` edits thin (charter §1.2).
- Link 1 started as a new Claude Code Remote session (charter §6, option 1).

## Link 1 — KNG-133: List "Create New" child never saved — BLOCKED (charter §4.1)

- **Blocker:** the link-1 session was started with only `PandiO/knk-workspace` in its repository sources.
  `add_repo` for `knk-web-app` and `knk-web-api` (access `push`) was refused by the session's permission policy.
  A read-only clone of `knk-web-app` worked (branch at `38854ba`), but
  `git push --dry-run origin claude/jolly-archimedes-urhio9` returned 403 from the git proxy ("not in this
  session's authorized repository set"). Charter §1.3 / §4.1: can't push a repo the link must change = stop.
- **Done:** nothing in code. No baselines measured, no commits in knk-web-app/knk-web-api/knk-plugin, Linear
  KNG-133 left as is. Tracker row on `main` set to "Blocked".
- **Next link:** not started (charter §4: start no further link at a blocker).
- **To resume:** start a new Claude Code session whose sources include knk-workspace, knk-web-app and knk-web-api
  (or allow `add_repo` in this environment's permissions), then run
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-1.md` again unchanged — its starting state is still valid.

## Coordinator — 2026-10-12: link 1 restart

- Cause confirmed from the link-1 session record (`session_01ApK9K3q2Sgm9dW3pwvzvwY`): it ran in the "Default
  Correct" environment (the account's only environment) on Opus 5.5, but `create_session` attaches only one
  repository, so it had knk-workspace alone; `add_repo` (push) was denied by the auto-mode permission check and the git
  proxy refused knk-web-app (403). The tool also has no effort setting, so the session ran at the default effort.
- Fix: charter §6 changed. Links now run as fresh subagents of the coordinator session, which has all four repos
  attached with push, Opus 5.5 at high effort. The link-1 handoff is unchanged and still valid.

## Link 1 — KNG-133: List "Create New" child never saved (restart, 2026-10-12)

Started by the coordinator as a fresh subagent (charter §6). Trunks had not moved (web-app `main` `38854ba`, web-api
`master` `917537a`), so the trunk merges at start and end were no-ops. Push dry-run passed in all four repos.

- **Commits (knk-web-app, branch `claude/jolly-archimedes-urhio9`):** `8e44800` normalizeFormSubmission refuses
  entities that were never saved; `ff12c8f` save a List "Create New" child when its form completes (head `ff12c8f`).
  knk-web-api and knk-plugin unchanged (`917537a`, `1b3e06c2`): the API needed no change, `StreetService` already
  reads `DistrictIds`.
- **What changed:**
  - New `src/utils/forms/childPersistence.ts` → `shouldPersistChildOnComplete(field)`: true for every List field with
    an `objectType` (owned or not) and every Object field except a single Location. `FormWizard.handleOpenChildForm`
    and `handleContinueDraft` use it (replacing the inline `ownedChildCollection || (Object && !Location)`); the
    existing `persistIndependently` branch of `handleChildFormComplete` then creates/updates the entity.
  - `normalizeFormSubmission` throws the new exported `UnsavedRelationshipValueError` (with `fieldName`,
    `unsavedCount`) for an id-less object with content in an Object (not Location) or List relationship field, and
    for a filled-in object held by a List field instead of an array. Message, e.g.: `"Districts" holds 1 District
    that was never saved, so it can't be submitted and would be lost. Remove it and select or create it again, then
    submit.` The wizard shows it in its error banner (existing catch at the final submit).
  - Final submit in `FormWizard.handleNext` now normalizes **before** `saveProgress(Completed)`, so a refused submit
    leaves the progress In Progress (before, a thrown many-to-many error had already marked it Completed).
- **Tests:** web app 669 passed / 5 failed (baseline before changes 654 / 5; +15 new: 7 normalize, 6 helper, 2 UI);
  the 5 failures are the same 4 suites as on `main` (`FormWizard.m2mJoinPrefill.ui`, `ManyToManyRelationshipEditor.ui`,
  `useEnrichedFormContext`, `RoadsAdminPage`). New UI test `FormWizard.listCreateNewPersist.ui.test.tsx` uses the
  real `ChildFormModal` + nested `FormWizard` (only `PagedEntityTable` stubbed); both its tests fail without the fix.
  `npm run build` compiles with the same warnings as before (FormWizard.tsx warnings unchanged; `CI=true` turns the
  existing warnings in untouched files into errors, as on trunk). API baseline 2550 passed / 4 failed (the known
  `ClientActivityStoreTests`, 2× `PathResolutionServiceTests`, `FieldValidationServiceTests`), not rerun since the
  API is unchanged. `npm ci` with the default npm 10 fails on the lock file; `npx npm@11 ci` works (known, repo
  CLAUDE.md).
- **Flagged decisions:**
  - **L1-1** A List child of *any* type is saved on completion, a Location included. The design says "Location stays
    embedded", which holds for the single Object Location field; a List of Locations (e.g.
    `GateStructure.GuardSpawnLocations`, sent as `GuardSpawnLocationIds`) can only reach the API as ids, so leaving
    it embedded would keep losing it.
  - **L1-2** An empty object (`{}` or only empty values) counts as "no value" and is left out as before, not an error.
    An id-less single Location without coordinates is also still left out without error (embedded value; link 2's
    area).
  - **L1-3** Normalize before marking the progress Completed (see above).
  - **L1-4** Consequence of D1-A: **Edit instance** on an already-saved item of a non-owned List now saves the edit
    through the entity's update API. Before, the edited values were held locally and then reduced to the id, so the
    edit was lost.
  - **L1-5** Parent-link prefill unchanged. In create mode the child's link field back to the parent
    (`findParentLinkField`, Object fields only) gets the unsaved parent snapshot (`id: -1`); saving such a child at
    once fails with the API's error, shown in the child modal (loud, the modal stays open), as Object fields already
    did. Owned collections stay gated ("Save this record first"). Street → District is not affected: District links
    to Streets through a List (many-to-many), which `findParentLinkField` ignores.
- **Discrepancies / findings:**
  - Many-to-many path confirmed: `ManyToManyRelationshipEditor.handleCreateRelatedEntity` (:377-449) creates the
    entity at once. Whether the developer's Street form uses a List field or a many-to-many step for Districts is
    still unknown; both now save (live checklist item 4).
  - **Districts minimum:** nothing enforces "at least one District" for an empty list. `FormWizard.validateField`
    treats `[]` as present for a required List and never reads `minSelection` (only `PagedEntityTable` refuses to
    deselect below `min`); `StreetService` has no minimum. With KNG-133 an unsaved item can no longer count towards
    a minimum and then vanish (the submit is refused). Follow-up below.
  - `normalizeFormSubmission`'s "copy leftover keys" pass re-adds the navigation array (`Districts`) next to
    `DistrictIds`; `StreetService` ignores it. Pre-existing, left as is.
- **Live checklist (developer):**
  1. GateStructure form → Street **Create New** → in the Street form, Districts **Create New** → submit the District:
     the District exists (District list, or search it in the GateStructure's District picker).
  2. Submit the Street: the Street has the District (Street display page or DB `street_districts`). Edit instance on
     the Street may still show no District until KNG-135 (link 3) if the field is authored as `DistrictIds`.
  3. Top-level Street form with a Create New District: the saved Street has the District.
  4. Note whether the dev-DB Street form uses a List field or a many-to-many step for Districts.
  5. Resume an old draft that holds an id-less District (if any): Submit shows the "never saved" message naming the
     field and the draft stays in Saved Progress.
  6. Regression: a GateStructure's single Location (Create New / world task) still saves with the GateStructure;
     GateDoors (owned collection) still save on completion.
- **Follow-ups (not fixed, scope):** required List fields accept `[]` and `minSelection` isn't validated in the wizard
  (comment on KNG-133); the normalize leftover pass re-adds navigation arrays.
- **Risks:** entities saved by List child forms of a cancelled root form now stay in the DB (same as Object fields;
  KNG-162, link 5). `FormWizard.tsx` edits are small (one import, two call sites, ~10 lines moved in `handleNext`) for
  the KNG-120/KNG-132 merges.
- **Next link must know:** `shouldPersistChildOnComplete` decides persistence; `handleChildFormComplete` itself is
  unchanged; normalize throws `UnsavedRelationshipValueError`; the new UI test is a ready template for nested-form
  tests with the real `ChildFormModal`.
- **How the next link is started:** by the coordinator as a fresh subagent with
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-2.md` (charter §6).
