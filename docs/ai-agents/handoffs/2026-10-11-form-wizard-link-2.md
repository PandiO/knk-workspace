Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 2 — KNG-134: "Form wizard: Edit instance opens a blank or stale child form (world-task Location,
in-session edits, id-less list items)" end to end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9,
progress report, Linear, handoff) as link 2 of the chain.

State you start from (2026-10-12): knk-web-app feature branch `ff12c8f` (trunk `main` `38854ba` + link 1's `8e44800`,
`ff12c8f`); knk-web-api `917537a` (= `master`, unchanged); knk-plugin `1b3e06c2` (= `main`, unchanged, read-only);
knk-workspace feature branch carries charter, specs, report (link 1 block) and this handoff. Tests after link 1:
web app 669 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2550 passed / 4 failed (known red).
Re-measure before changing anything. `npm ci` needs npm 11: `npx -y npm@11 ci`.
What earlier links left for this link: link 1 (KNG-133) made every List child and every Object child except a single
Location save on completion (`src/utils/forms/childPersistence.ts` → `shouldPersistChildOnComplete`, used by
`FormWizard.handleOpenChildForm` ~1795 and `handleContinueDraft`), and `normalizeFormSubmission` now throws
`UnsavedRelationshipValueError` for id-less entities in Object (not Location) / List fields. `handleChildFormComplete`
(~1880) is otherwise unchanged. New template for nested-form UI tests with the real ChildFormModal:
`src/components/FormWizard/__tests__/FormWizard.listCreateNewPersist.ui.test.tsx`.
Link-specific reading: docs/specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md §2.3, §3.4, §5 item 2; Linear
KNG-134; the link 1 block in docs/reports/2026-10-11-form-wizard-chain.md (L1-2, L1-4). Code (knk-web-app):
FormWizard.tsx `handleOpenChildForm` (~1795, passes only `entityId`), `handleChildFormComplete` (~1880; KNG-130 id
branch), `loadExistingEntityData` (~899), `applyInitialFieldValuesToSteps` (~299), world-task panel binding
(~2790-2805, `worldTaskHint` inheritance ~1824 and ~3006); ChildFormModal.tsx (`isEditMode` :181, prefill memo
:189-195, title :207); FieldRenderers.tsx ListField (keys `item.id` :1311, remove :1202, edit index :1340);
components/Workflow/WorldBoundFieldRenderer.tsx (`extractTaskResult` :270, "Replace via Minecraft" :838);
tests next to `FormWizard.locationChildEdit.ui.test.tsx`.
Open flags that affect this link: D1 = A decided. L1-2: an id-less single Location without coordinates is still left
out of the payload without error — decide whether seeding/editing changes that. With link 1, an id-less List item can
only come from old drafts (List children are saved now), but ListField's stable keys are still in scope. Charter link
specifics: also verify the inherited `worldTaskHint` "first field" binding (spec §2.3) and fix it if confirmed.
Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) still unmerged and
edit FormWizard.tsx — keep edits there thin, new logic in new modules. Edit instance on a persisted List item now saves
the edit through the update API (L1-4); in-memory overlay must not fight that. KNG-135 (link 3) owns List
relationships loading in edit mode (`XIds`/`Xs`); don't fix that here.
Next after you: link 3 (KNG-135 + KNG-137).
