Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 3 — KNG-135 + KNG-137 + KNG-164: "List relationships load in edit mode; wizard shows step names, keeps
them in edit mode, renders Boolean descriptions; required List fields reject an empty list and minSelection/canCreate
get real columns" end to end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9, progress report,
Linear, handoff) as link 3 of the chain. Three issues in one link: commit them separately, one Linear comment each.

State you start from (2026-10-12): knk-web-app feature branch `602db8e` (trunk `main` `38854ba` + link 1 `8e44800`,
`ff12c8f` + link 2 `b75ce07`, `7b7199f`, `602db8e`); knk-web-api `917537a` (= `master`, unchanged so far — this link
is the first to change it); knk-plugin `1b3e06c2` (= `main`, unchanged, read-only); knk-workspace feature branch
carries charter, specs, report (link 1 and 2 blocks) and this handoff; tracker row on workspace `main`. Tests after
link 2: web app 698 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2550 passed / 4 failed (known red:
ClientActivityStoreTests, 2x PathResolutionServiceTests, FieldValidationServiceTests). Re-measure both before
changing anything. `npm ci` needs npm 11: `npx -y npm@11 ci` (node_modules is already installed in the container).

What earlier links left for this link:
- Link 1 (KNG-133): `src/utils/forms/childPersistence.ts` (`shouldPersistChildOnComplete`), `normalizeFormSubmission`
  throws `UnsavedRelationshipValueError`. Its finding became KNG-164: `FormWizard.validateField` (~2331) treats `[]`
  as present for a required List and never reads `minSelection`; only `PagedEntityTable` refuses to deselect below
  `min`. `FormFieldDto.MinSelection`/`MaxSelection`/`CanCreate` exist in `api/Dtos/FormDtos.cs:92-96` but
  `api/Models/FormField.cs` has no columns (silently dropped on save; check `IncrementValue` too, seeds spec §2.1).
- Link 2 (KNG-134): new `src/utils/forms/childEditSeed.ts` — `buildChildEditSeedValues` runs every field through
  `resolveObjectFieldValueForEdit`, so extending that function (or a sibling it calls) to List `XIds`/`Xs` pairs
  fixes both the edit-mode load (`loadExistingEntityData` ~908) and seeding a child from held values. ListField now
  keys/removes/edits by position (`src/utils/forms/listItemKeys.ts`). Template UI tests with the real ChildFormModal:
  `FormWizard.listCreateNewPersist.ui.test.tsx`, `FormWizard.childEditSeed.ui.test.tsx`.

Link-specific reading: charter "Link specifics" for link 3; Linear KNG-135, KNG-137, KNG-164 (acceptance lists);
docs/specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md §2.3 (List bullet), §3.5, §5 item 3;
docs/specs/form-configurations/DEFAULT_FORM_SEEDS.md §2.1, §2.3; the link 1 and link 2 blocks in
docs/reports/2026-10-11-form-wizard-chain.md. Code (knk-web-app): `src/utils/forms/objectFieldEditValue.ts` (+ its
test), FormWizard.tsx progress bar (~2660-2690; edit-mode title `{entityId ? \`Edit ${entityName}\` :
currentStep.stepName}` at ~2696) and `validateField` (~2331), FieldRenderers.tsx `BooleanField` (:740). Code
(knk-web-api): `Mapping/StreetMappingProfile.cs` (fills `Districts`, never `DistrictIds`), other `*MappingProfile.cs`
with input-only `*Ids` lists (audit all DTOs used by List fields, record the list in the report), `Models/FormField.cs`,
`Mapping/FormMappingProfile.cs`, `Properties/KnKDbContext.cs`, `Migrations/` (additive migration via
`dotnet ef migrations add`, charter §3), `Tests/knkwebapi_v2.Tests/` (Street read returns `districtIds`; FormField
round-trip of the new columns). If `dotnet` is missing: `sudo apt-get install -y dotnet-sdk-8.0`.

Open flags that affect this link:
- L1-2 / L2-3: an id-less single Location without x/y/z is still dropped without error (follow-up, not this link).
- L2-1: Edit instance of a child saved on completion loads from the database only — so KNG-135's API fix is what makes
  a reopened Street show its Districts.
- KNG-164 schema: new columns must be nullable (null = no limit / creatable), mapped both ways; existing rows stay null.
  Step validation for required/min/max List belongs in a new module (e.g. `src/utils/forms/listFieldValidation.ts`)
  with a thin call in `validateField`; the message names the field.
- KNG-137 is UI only (no API); keep the progress-bar change small and test it (renderer/UI tests for the three cases).

Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) are still unmerged
and edit FormWizard.tsx — KNG-137's progress-bar/title change is in FormWizard.tsx too, so keep it a thin edit (a small
component, e.g. `src/components/FormWizard/WizardStepProgress.tsx`, is fine). KNG-132 also adds a knk-web-api data
migration for GateDoor field descriptions: if it reaches `master` before you finish, the trunk merge brings it in;
regenerate nothing by hand, keep your migration additive and later-dated. `EndpointAccessRulesTests` must stay green
(no new endpoints expected). The API has 4 known-red tests; record, don't fix.

Next after you: link 4 (KNG-136, form session registry + pinned "New" rows in pickers; also owns PagedEntityTable's
id-only selection, left by link 2).
