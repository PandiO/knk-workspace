Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 7 — KNG-139: "Author the default FormConfigurations as seed files" + the chain's final write-up, end to
end (seed files, tests, docs, commits, push to claude/jolly-archimedes-urhio9, progress report incl. the final
summary, Linear, tracker row to "Recently completed") as the **last** link of the chain. Stop after the write-up.

State you start from (2026-10-12): knk-web-app feature branch `1c3e835` (trunk `main` `38854ba` + links 1-5 up to
`22cb588` + link 6 `1c3e835`); knk-web-api feature branch `b62cdce` (`master` `917537a` + link 3 `7b01458`, `29f65b3`
+ link 5 `af7ed5d`, `959bc11` + link 6 `b62cdce`; two additive migrations from links 3 and 5, none from link 6);
knk-plugin `1b3e06c2` (= `main`, unchanged, read-only); knk-workspace feature branch carries charter, specs, report
(links 1-6) and this handoff; tracker row on workspace `main`.
Tests after link 6: web app 813 passed / 5 failed (same 4 known-red suites as `main`: FormWizard.m2mJoinPrefill.ui,
ManyToManyRelationshipEditor.ui, useEnrichedFormContext, RoadsAdminPage); API 2613 passed / 4 failed (known-red:
ClientActivityStoreTests, 2x PathResolutionServiceTests, FieldValidationServiceTests). Re-measure before changing
anything. `npm ci` needs npm 11: `npx -y npm@11 ci`. Build `knkwebapi_v2.csproj` (the `.sln` fails on Linux) and run
`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. Link 7 is mostly data: the web app should not
need changes (re-run its tests only if you touch it).

What earlier links left for this link:
- Link 6 (KNG-138) built the mechanism: knk-web-api `Services/FormConfigurationPortabilityService.cs`, format in
  `Dtos/FormConfigurationPortableDtos.cs` (spec `DEFAULT_FORM_SEEDS.md` §3.2 as amended by §3.4). Seed files go in
  `Data/FormConfigurationSeeds/*.json` (README there). The file name without `.json` is the seed's name.
- `Tests/knkwebapi_v2.Tests/Services/FormConfigurationSeedFilesTests.cs` already covers every file you add: readable,
  unique `configurationGuid`s, dry run passes and the import succeeds on an empty in-memory DB, in dependency order
  (it retries until nothing new resolves). It uses the real `MetadataService` + `FormTemplateValidationService`, so
  every `fieldName` must be a real property of the entity, types must match, non-nullable properties on the form
  must be required, display conditions may only read earlier fields. Run it alone with
  `--filter FullyQualifiedName~FormConfigurationSeed`.
- Format tips: enums as strings (`"fieldType": "Object"`, `"operator": "IsNotEmpty"`); `settingsJson` is a JSON
  **string** (escaped), stored verbatim; array order = step/field/group order; give the seed, every step and every
  field a fixed GUID (generate them once, never reuse across seeds); join entries / child forms are their own seed and
  the parent's M2M step names them with `subConfigurationRef: { "configurationGuid": "…", "entityTypeName": "…",
  "name": "…" }`; a rule on a parent form's field uses `dependsOn: { "fieldGuid": "…", "configurationGuid": "<parent
  seed>" }`. `FormConfigurationPortabilityServiceTests.AuthorSiegeSetAsync` shows a siege-shaped set end to end, and
  an export of it is the exact file shape (`FormConfigurationPortabilityService.Serialize`).
- Link 3 showed what the wizard renders (step names in the progress bar, Boolean descriptions, required List +
  `minSelection`); see its report block and the authoring guide (spec §4).
- No dev-DB export of GateStructure (9) / GateDoor (12) is available in a cloud session: derive them from
  `gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` §5.10-5.11 and the models, and **say so in the
  report**. The siege set converts `siege-minigame/PHASE_3_FORMCONFIGS.md` (configs 23-33; Location rules optional).

Link-specific reading: charter "Link specifics" for link 7 and §5 step 4-7; Linear KNG-139 (acceptance list);
docs/specs/form-configurations/DEFAULT_FORM_SEEDS.md §3.4, §4 (authoring guide), §5 (inventory); the link 6 block of
docs/reports/2026-10-11-form-wizard-chain.md; the sources in spec §5 for GateStructure/GateDoor and the siege set.

Open flags that affect this link:
- L6-1: a seed is "already imported" by `configurationGuid`; once the developer imports a seed, a changed version
  needs a new GUID and name. Seeds import as **non-default** when the entity already has a default (the dev DB has
  defaults for GateStructure, GateDoor and the siege set) — that is the intended review flow (spec §3.3 step 3).
- L6-6: there is no "import all"; write the import order into the report's live checklist (join entries and owned
  children before parents, parents before forms whose rules read a parent field).
- KNG-132 (`claude/loving-johnson-dlshrc`, unmerged) migration `f40ce73` fills only **empty** descriptions of the
  GateDoor fields AnchorPointId, ReferencePoint1Id/2Id, GeometryWidth/Height/Depth, MotionDistanceBlocks: write those
  descriptions in the GateDoor seed yourself (don't copy its exact text, or its Down would clear them).
- Runtime-only properties (`IsSiegeObjective`, `CurrentSiegeId`, …) stay off the default forms (spec §4).

Known risks: KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132 are still unmerged; `claude/api-vulnerable-packages`
([PR #9](https://github.com/PandiO/knk-web-api/pull/9)) may change `new MapperConfiguration(...)` call sites in tests.
Merge order for the final summary: knk-web-api (links 3 and 5 migrations) before knk-web-app; the dev DB needs both
migrations before the branch runs; KNG-132's data migration is earlier-dated and independent.

Final write-up (charter §5 "Link 7"): in the progress report's Summary/final section — what was built per issue
(links 1-7), decisions to review ranked (L1-… to L7-…), one combined live checklist, merge order, KNG-120/KNG-132
interplay, follow-up list; Linear comments; move the tracker row to "Recently completed" (nothing merged).

Next after you: none — last link. Stop after the write-up (do not call create_session).
