Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 4 — KNG-136: "Form session registry; pickers pin entities created in this form session ('New')" end to
end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9, progress report, Linear, handoff) as link 4 of
the chain.

State you start from (2026-10-12): knk-web-app feature branch `a1c5896` (trunk `main` `38854ba` + link 1 `8e44800`,
`ff12c8f` + link 2 `b75ce07`, `7b7199f`, `602db8e` + link 3 `ee214a4`, `18f3d7c`, `a1c5896`); knk-web-api feature branch
`29f65b3` (`master` `917537a` + link 3 `7b01458`, `29f65b3`, including the additive migration
`20261012075746_AddFormFieldSelectionLimits`); knk-plugin `1b3e06c2` (= `main`, unchanged, read-only); knk-workspace
feature branch carries charter, specs, report (link 1-3 blocks) and this handoff; tracker row on workspace `main`.
Tests after link 3: web app 729 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2556 passed / 4 failed (known-red: ClientActivityStoreTests, 2x PathResolutionServiceTests,
FieldValidationServiceTests). Re-measure before changing anything. `npm ci` needs npm 11: `npx -y npm@11 ci`.
`dotnet build` on the `.sln` fails on Linux (it references `tests\…` lowercase): build `knkwebapi_v2.csproj` and run
`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. If you edit API files while a build runs, `touch` them
before the next test run (an incremental build can keep the stale dll).

What earlier links left for this link:
- Link 1 (KNG-133): `src/utils/forms/childPersistence.ts` (`shouldPersistChildOnComplete`) — every List child and every
  non-Location Object child is saved when its form completes, in `handleChildFormComplete`'s `persistIndependently`
  branch. That branch (and `ManyToManyRelationshipEditor.handleCreateRelatedEntity`, :377-449) is where the registry
  entries are registered (spec §3.2).
- Link 2 (KNG-134): `ChildFormState.initialValues`/`editingInMemory`, `src/utils/forms/childEditSeed.ts`,
  `src/utils/forms/listItemKeys.ts` (ListField keys id-less items by a client key). **Left for you:**
  `PagedEntityTable` matches selection by `id` only and keys rows by array index (spec §2.3 last bullet, §3.3 stable
  keys); its selection-sync effect treats all id-less items as equal.
- Link 3 (KNG-135/137/164): edit load yields `{ id, … }` objects for List fields from either side of `XIds`/`Xs`
  (`objectFieldEditValue.ts`); `src/utils/forms/listFieldValidation.ts` enforces required/min/max List counts at
  Next/Submit (PagedEntityTable still also refuses to deselect below `min`); `WizardStepHeader.tsx` holds the progress
  bar/title. None of it changes how pickers fetch rows.

Link-specific reading: charter "Link specifics" for link 4; Linear KNG-136 (acceptance list);
docs/specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md §2.1, §2.3 (picker bullet), §3.2, §3.3, §5 item 4;
the link 1-3 blocks in docs/reports/2026-10-11-form-wizard-chain.md. Code (knk-web-app):
`src/components/PagedEntityTable/PagedEntityTable.tsx` (selection by id ~284-292, :454, :486; row keys :713;
New/Existing badge styling ~737-749), `FieldRenderers.tsx` `ObjectField`/`ListField` picker props, `ChildFormModal.tsx`
(how a nested FormWizard is mounted, so the provider reaches it), `FormWizardPage.tsx` (root wizard),
`ManyToManyRelationshipEditor.tsx`. Template UI tests: `FormWizard.siegeNesting.ui.test.tsx` (two-level nesting),
`FormWizard.listCreateNewPersist.ui.test.tsx` (real ChildFormModal, PagedEntityTable stubbed — for KNG-136 you need the
real PagedEntityTable with a mocked search client).

Open flags that affect this link:
- L1-1: List children of any type, a List of Locations included, are saved on completion → they get ids and can be
  registered. Single Object Location stays embedded and is not offered in pickers (spec §3.3 last paragraph).
- L2-1: children saved through their own API reload from the DB on Edit instance; the registry's `display` must not
  overwrite a fuller DB record.
- D3 (spec §4): the registry is not persisted in drafts in this link; KNG-162 (link 5) adds `CreatedEntitiesJson`.
  Design the registry so link 5 can read "what this root form created" from it (entity type, id, origin).

Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) are still unmerged
and edit `FormWizard.tsx` — keep your edits there to a provider wrap / one hook call / registration calls; put the
registry in `src/contexts/FormSessionContext.tsx` (+ hook) as the charter says. `PagedEntityTable` has no tests yet —
add them (pinned rows, de-duplication by id, stable keys, search-term filtering of pinned rows). A re-run of the search
with the session ids as a filter needs an API filter that may not exist for every entity: fall back to client-side
filtering (spec §3.3) and record which. The dev DB needs link 3's migration applied before the branch runs
(report, link 3 checklist item 0) — not your task, but mention it if you write a live checklist.

Next after you: link 5 (KNG-162, cancel / delete-draft prompt: keep or delete what child forms saved; provenance
`CreatedEntitiesJson`).
