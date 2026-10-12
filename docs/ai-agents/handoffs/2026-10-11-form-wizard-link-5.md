Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 5 — KNG-162: "Cancel / delete-draft prompt: keep or delete what child forms saved; provenance
`CreatedEntitiesJson`" end to end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9, progress report,
Linear, handoff) as link 5 of the chain.

State you start from (2026-10-12): knk-web-app feature branch `8ae5a66` (trunk `main` `38854ba` + link 1 `8e44800`,
`ff12c8f` + link 2 `b75ce07`, `7b7199f`, `602db8e` + link 3 `ee214a4`, `18f3d7c`, `a1c5896` + link 4 `d0d805d`,
`89b4476`, `8ae5a66`); knk-web-api feature branch `29f65b3` (`master` `917537a` + link 3 `7b01458`, `29f65b3`,
including the additive migration `20261012075746_AddFormFieldSelectionLimits`); knk-plugin `1b3e06c2` (= `main`,
unchanged, read-only); knk-workspace feature branch carries charter, specs, report (link 1-4 blocks) and this handoff;
tracker row on workspace `main`.
Tests after link 4: web app 764 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2556 passed / 4 failed (known-red:
ClientActivityStoreTests, 2x PathResolutionServiceTests, FieldValidationServiceTests; not rerun by link 4, API
unchanged). Re-measure before changing anything. `npm ci` needs npm 11: `npx -y npm@11 ci`. `dotnet build` on the
`.sln` fails on Linux (it references `tests\…` lowercase): build `knkwebapi_v2.csproj` and run
`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. If you edit API files while a build runs, `touch` them
before the next test run (an incremental build can keep the stale dll).

What earlier links left for this link:
- Link 4 (KNG-136): `src/contexts/FormSessionContext.tsx`. `useFormSession()?.createdEntities()` = what this root
  form's child forms saved (status `created`, not embedded), oldest first; each entry has `entityTypeName`, `id`,
  `display`, `origin { formPath, fieldName }`, `sequence`. **Delete in reverse `sequence`** (a later entity can
  reference an earlier one: the Street references the District created inside it). Use `entityTypeName`, not
  `formPath` (it holds the `entityName` prop, which can be the lower-case route segment). The pure core
  `upsertSessionEntity` is exported; to re-seed the registry from a resumed draft (D3) add a `seed(entries)` to the
  root registry (`RootRegistry` in that file).
- The registry provider is the exported `FormWizard` itself (a wrapper `<FormSessionScope formName={entityName}>`
  around `FormWizardBody`): it exists only while the root wizard is mounted and only inside it. A prompt rendered by
  `FormWizardPage` outside the wizard needs the scope lifted: wrap that part of the page in `<FormSessionScope …>`
  and the inner `FormWizard` joins it instead of creating its own.
- Link 1 (KNG-133): every List child and every non-Location Object child is saved when its form completes
  (`utils/forms/childPersistence.ts`), so those are what the prompt lists; a single Object Location is embedded
  (saved with its parent), never listed.

Link-specific reading: charter "Link specifics" for link 5; Linear KNG-162 (acceptance list);
docs/specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md §4 (D2, D3) and §2.4 (progress tree limits); the link
1-4 blocks in docs/reports/2026-10-11-form-wizard-chain.md. Code: knk-web-app `src/pages/FormWizardPage.tsx`
(`handleDeleteProgress` ~:489, `SavedProgressList` ~:1092), `src/components/FormWizard/SavedProgressList.tsx`,
`src/components/FeedbackModal.tsx` (confirm pattern; also see how `components/admin/roads/RoadProfilesCard.tsx` asks
for confirmation), `utils/entityApiMapping.ts` (`getDeleteFunctionForEntity`), `FormWizard.tsx` `saveProgress` (where a
progress is created/updated - the place to send `CreatedEntitiesJson`); knk-web-api `Models/FormSubmissionProgress.cs`,
its DTO in `Dtos/FormDtos.cs`, `Mapping/FormMappingProfile.cs`, the FormSubmissions controller/service.

Open flags that affect this link:
- **There is no explicit "Cancel" button on the wizard today** (link 4 found only the scan-conflict and world-prompt
  cancels). Decide what "explicit cancel of the main form" is (e.g. a Cancel/Discard action on the root wizard or
  page that leaves the form) - take the most reversible default consistent with D2 and flag it.
- D2 (spec §4): Keep is the default; Delete goes deepest-first through the normal delete endpoints; anything in use is
  skipped and reported (FK/reference errors become "skipped: in use", not a 500 - charter link specifics). No
  automatic deletion anywhere; the KNG-43 90-day cleanup stays as is.
- D3: `CreatedEntitiesJson` (additive nullable column on the **root** progress; `dotnet ef migrations add`, snapshot
  consistent) lets the delete-draft prompt work later from Saved Progress and lets a resumed draft pin the entities
  again. A wizard only has a `progressId` after Next or Save Draft (spec §2.4).
- L2-1: children saved through their own API reload from the DB on Edit instance; the registry's `display` may be
  stale - show names from it but don't overwrite DB data with it.
- L4-3: navigating away / remounting the root wizard empties the in-memory registry; after this link the draft's
  `CreatedEntitiesJson` is the durable record.

Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) are still unmerged
and edit `FormWizard.tsx` — keep your edits there thin; put new logic in new modules. KNG-132 also carries an
earlier-dated data migration (`f40ce73`); your migration must be additive and generated with `dotnet ef`. Merge order
stays API (migrations) before web app; the dev DB needs link 3's migration and yours applied before the branch runs
(mention both in your live checklist). New write/delete endpoints need explicit access rules
(`EndpointAccessRulesTests` must stay green). Also on the tracker: `claude/api-vulnerable-packages` (knk-web-api
AutoMapper/OpenTelemetry upgrades, unmerged) may change `new MapperConfiguration(...)` call sites (link 3 added two
test files using it; report, link 3 risks).

Next after you: link 6 (KNG-138, FormConfiguration export/import (portable JSON), bundled seeds endpoints, web-app
buttons).
