Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 6 — KNG-138: "FormConfiguration export/import (portable JSON), bundled seeds endpoints, web-app
buttons" end to end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9, progress report, Linear,
handoff) as link 6 of the chain.

State you start from (2026-10-12): knk-web-app feature branch `22cb588` (trunk `main` `38854ba` + links 1-4 up to
`8ae5a66` + link 5 `94e3a6e`, `22cb588`); knk-web-api feature branch `959bc11` (`master` `917537a` + link 3 `7b01458`,
`29f65b3` + link 5 `af7ed5d`, `959bc11`, including two additive migrations: `20261012075746_AddFormFieldSelectionLimits`
and `20261012085922_AddFormSubmissionProgressCreatedEntities`); knk-plugin `1b3e06c2` (= `main`, unchanged,
read-only); knk-workspace feature branch carries charter, specs, report (link 1-5 blocks) and this handoff; tracker
row on workspace `main`.
Tests after link 5: web app 792 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2574 passed / 4 failed (known-red:
ClientActivityStoreTests, 2x PathResolutionServiceTests, FieldValidationServiceTests). Re-measure before changing
anything. `npm ci` needs npm 11: `npx -y npm@11 ci`. `dotnet build` on the `.sln` fails on Linux (it references
`tests\…` lowercase): build `knkwebapi_v2.csproj` and run `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`.
If you edit API files while a build runs, `touch` them before the next test run. If you need `dotnet ef` (only for a
schema change; export/import should need none): `dotnet-ef` is in `~/.dotnet/tools`; run it with
`Database__MySqlServerVersion=8.0.36 ConnectionStrings__MySqlDbConnection="Server=localhost;Database=x;User=x;Password=x"`
so the design-time host doesn't try to reach MySQL.

What earlier links left for this link:
- Link 3 (KNG-164): `FormField` now stores `MinSelection`, `MaxSelection`, `CanCreate`, `IncrementValue` (nullable).
  `FormConfigurationRepository.UpdateAsync` and `FormTemplateReusableService` copy fields property by property, so
  the export/import format and the import's copy code must carry these four too (and any other `FormField` column).
- Link 3 also showed which wizard features the seeds will rely on (step names, Boolean descriptions, required List
  with `minSelection`): see the link 3 block in the report.
- Links 4-5 don't touch form configurations. Link 5 added `GET api/FormSubmissionProgress/entity-references/...`
  and a global DELETE `DbUpdateException` → 409 filter (`Attributes/DeleteConstraintExceptionFilter.cs`); an import
  that deletes/replaces steps or fields goes through it only for DELETE requests.
- Access rules: every new write endpoint needs an explicit rule (`knk.admin.content` for form configuration
  endpoints); `EndpointAccessRulesTests` must stay green. `FormConfigurationsController` currently has no
  `DbUpdateException` handling.

Link-specific reading: charter "Link specifics" for link 6; Linear KNG-138 (acceptance list);
docs/specs/form-configurations/DEFAULT_FORM_SEEDS.md (all of it; §3 is the mechanism and the portable format, S1 = A:
files imported on request, no startup seeder); docs/specs/siege-minigame/PHASE_3_FORMCONFIGS.md (shape of the
round-trip test config); the link 3 block in docs/reports/2026-10-11-form-wizard-chain.md. Code: knk-web-api
`Controllers/FormConfigurationsController.cs`, `Services/FormConfiguration*`, `Repositories/FormConfigurationRepository.cs`,
`Services/FormTemplateReusableService.cs`, `Dtos/FormDtos.cs` (`FormConfigurationDto` lacks `configurationGuid`; the
charter asks to add it to the export format), `Mapping/FormMappingProfile.cs`, `Models/FormConfiguration.cs`,
`FormStep.cs`, `FormField.cs`, display conditions and validations; knk-web-app the form configuration list
(`components/FormWizard/FormConfigurationTable.tsx`, `pages/FormWizardPage.tsx`, admin form-configuration pages) and
`apiClients/formConfigClient.ts`.

Open flags that affect this link:
- Seeds live in knk-web-api `Data/FormConfigurationSeeds/` (charter table, link 7 fills them). Link 6 builds the
  mechanism (export, import with dry-run, list/import bundled seeds) and the web-app buttons; link 7 writes the seed
  files and must be able to dry-run each one in a test.
- Import must be additive/non-destructive by default (charter §3 "do nothing the developer can't easily review or
  undo"): decide how an import treats an existing configuration with the same `configurationGuid` (e.g. refuse unless
  "replace" is chosen, or import as a new copy) — take the most reversible default and flag it `L6-<n>`.
- No schema change is expected; if one is needed it must be additive and generated with `dotnet ef`.
- Round-trip tests on an in-memory/test DB using a config shaped like `PHASE_3_FORMCONFIGS.md` (charter).

Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 (`claude/loving-johnson-dlshrc`) are still
unmerged; KNG-132 carries an earlier-dated data migration (`f40ce73`) that seeds GateDoor field descriptions — an
import of a GateDoor seed must not fight it (describe the interplay in the report). `claude/api-vulnerable-packages`
(knk-web-api AutoMapper/OpenTelemetry upgrades, [PR #9](https://github.com/PandiO/knk-web-api/pull/9), unmerged) may
change `new MapperConfiguration(...)` call sites in tests (links 3 and 5 added test files using it). Merge order stays
API (migrations) before web app; the dev DB needs links 3 and 5 migrations applied before the branch runs.

Next after you: link 7 (KNG-139 + final write-up: seed files for GateStructure/GateDoor and the siege set, each
passing the link-6 dry-run in a test; chain summary, merge order, combined live checklist).
