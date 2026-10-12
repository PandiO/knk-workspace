# Default FormConfigurations — agent-authored seeds

**Status:** Design decided (2026-10-11: S1 = A, developer). Being implemented by the
[form wizard chain](../../ai-agents/handoffs/FORM_WIZARD_CHAIN.md).
**Last updated:** 2026-10-12 (§2.1, §2.3: KNG-164 columns and KNG-137 renderer gaps fixed on the chain branch; §3: KNG-138 implemented on the chain branch, §3.4 records where it differs)
**Linear:** [KNG-138](https://linear.app/kngpandi/issue/KNG-138) (export/import),
[KNG-139](https://linear.app/kngpandi/issue/KNG-139) (author the default forms),
[KNG-137](https://linear.app/kngpandi/issue/KNG-137) (wizard shows step names and all descriptions)
**Sources:** knk-web-api `master` `917537a`, knk-web-app `main` `38854ba`; `docs/specs/items/IMPLEMENTATION_PLAN.md`
§4.3/§7.2; `docs/guides/production-installation.md` §7; the `…_FORMCONFIGS.md` records listed in §5.
**Related:** [FORM_WIZARD_SESSION_CONCEPTS.md](FORM_WIZARD_SESSION_CONCEPTS.md).

## 1. The question

Complex forms (GateStructure + GateDoor, the siege scenario set) need good step names, step descriptions, step
order and field labels/descriptions. Can an agent produce sensible default forms for the current entities from the
docs, the code and past sessions?

**Yes**, with two things in place: a portable file format the agent can write and the developer can import and
review (§3), and an authoring guide so the text is consistent (§4). The agent cannot reach the dev DB, so it either
starts from the developer's exported configs or from the payloads recorded in the docs. A few renderer gaps (§2.3)
should be fixed so the descriptions actually show.

## 2. What exists today (verified)

### 2.1 Model

- `api/Models/FormConfiguration.cs`: `ConfigurationGuid` (unique index), `Name`, `EntityTypeName`, `IsDefault`,
  `Description`, `StepOrderJson`.
- `api/Models/FormStep.cs`: `StepGuid`, `StepName`, `Description`, `FieldOrderJson`, reuse (`IsReusable`,
  `SourceStepId`, `IsLinkedToSource`), many-to-many (`IsManyToManyRelationship`, `RelatedEntityPropertyName`,
  `JoinEntityType`, `SubConfigurationId`), `DisplayConditionGroups`.
- `api/Models/FormField.cs`: `FieldGuid`, `FieldName` (C# property), `Label`, `Placeholder`, `Description` (the
  only help text), `FieldType`/`ElementType`/`ObjectType`/`EnumType`, `DefaultValue`, `Required`, `ReadOnly`,
  `SubConfigurationId`, `SettingsJson` (`worldTask`, `ownedChildCollection`, `pickerFilters`, `enumValues`,
  `displayPanel`, `valueProjection`, …), `DisplayConditionGroups`.
- Validation rules (`FieldValidationRule`) are **not** part of the config DTO graph; they are created separately at
  `api/field-validation-rules`, keyed by int `FormFieldId`/`DependsOnFieldId`. Display conditions reference their
  source by `SourceFormFieldGuid`.
- `FormConfigurationDto` has no `ConfigurationGuid`. `CanCreate`, `MinSelection` and `IncrementValue` are DTO-only
  and silently dropped (no column).
  **2026-10-12 (KNG-164, branch `claude/jolly-archimedes-urhio9`, knk-web-api `29f65b3`, not merged):** `MinSelection`,
  `MaxSelection`, `CanCreate` and `IncrementValue` are nullable `FormFields` columns now (null = no limit /
  creatable / step 1), so seed files can carry them.
- `FormConfigurationService.CreateAsync` runs `FormTemplateValidationService` (field exists on the entity, types
  match metadata, non-nullable fields required, display-condition sources come earlier). Default uniqueness per
  entity is enforced only by `FormConfigBuilder.handleSave` in the web app, not by the API.

### 2.2 Seeding

- **No FormConfiguration seeder, import or export exists.** No "generate a form from metadata" feature either; the
  metadata (`api/Services/MetadataService.cs`) carries property names, types and relations but **no labels or
  descriptions**.
- Developer decision (items plan §7.2, 2026-09): "author live via FormConfigBuilder — no seeder".
- Production gets forms as a **dev-DB data export** (`production-installation.md` §7.1-7.3). §7.7 already names the
  next step: "an export/import feature for single FormConfigurations in the API: ask for it as a feature".
- Startup seed precedent for code-owned content: `Program.cs` runs `*Seed.SeedCanonicalAsync` classes, create-only
  by key (`MenuTemplateSeed`, `SiegeLobbySeed`, `KitSeed`).
- Payload records ("not a seeder"): `items/PHASE_2_FORMCONFIGS.md`, `kits/PHASE_3_FORMCONFIGS.md`,
  `lootboxes/PHASE_4_FORMCONFIGS.md`, `siege-minigame/PHASE_3_FORMCONFIGS.md` (configs 23-33),
  `teleport/KNG41_FORMCONFIGS.md`. GateStructure (id 9) and GateDoor (id 12) have **no checked-in payload**; their
  layout is described in `gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` §5.10-5.11.

### 2.3 What the wizard actually shows

| Text | Shown? | Where |
|---|---|---|
| Step name | Only as the step title, **replaced by "Edit {entity}" in edit mode**; the progress bar shows numbers only | `FormWizard.tsx:2650-2677`, :2683 |
| Step description | Yes, under the title | `FormWizard.tsx:2685-2687` |
| Field label / placeholder | Yes | `FieldRenderers.tsx` |
| Field description | Yes for String, Integer, Decimal, DateTime, Enum, Object, List, hybrid pickers, M2M child fields; **not for Boolean** | `FieldRenderers.tsx:739-755` |

Caveat for authors: a `placeholder`/`defaultValue` on a free-text String field with `enumValues` is comma-split into
options (`siege-minigame/PHASE_3_FORMCONFIGS.md:46`).

KNG-137 fixes the three gaps (step names in the progress bar, step name kept in edit mode as a subtitle, Boolean
descriptions).
**2026-10-12:** fixed on `claude/jolly-archimedes-urhio9` (knk-web-app `18f3d7c`, not merged): step names under the
progress-bar numbers (hidden on narrow screens), the step name stays the title in edit mode under a small
"Edit {entity}" heading, Boolean descriptions render under the checkbox label.

## 3. Proposed mechanism

### 3.1 Decision S1 — seeds as files, imported on request (decided 2026-10-11: A)

| Option | Pros | Cons |
|---|---|---|
| **A. Export/import endpoints + seed files in the repo, imported on request (proposed)** | Reviewable in PRs; never overwrites hand edits; also solves production §7.7; agents can author offline | Needs a small API + UI feature (KNG-138) |
| B. Create-only startup seeder (like `MenuTemplateSeed`) | Fresh DBs get forms automatically | Conflicts with the "data, not code" decision and the dev-DB-is-golden production flow; never updates an existing DB, so it doesn't improve the dev DB's configs 9/12 |
| C. SQL scripts | No code | Hard-coded ids, bypasses `FormTemplateValidationService`, rules keyed by int ids |

**Developer decision 2026-10-11: A.** Seed files live in knk-web-api `Data/FormConfigurationSeeds/{EntityTypeName}.json` (shipped with
the API, like the other `Data/` catalogs). B can be added later on top of the same files if a fresh-DB bootstrap is
wanted. This narrows the items §7.2 decision rather than reversing it: forms remain data, edited live in the builder;
seed files are a reviewed starting point.

### 3.2 Portable format

One file per configuration, close to `FormConfigurationDto` so export and import share code:

```jsonc
{
  "format": "knk-formconfig/1",
  "configurationGuid": "…",            // stable; the key for "already imported?"
  "entityTypeName": "GateStructure",
  "name": "Gate Structure",
  "description": "…",
  "steps": [                            // array order = step order
    {
      "stepGuid": "…", "stepName": "General information", "description": "…",
      "isManyToManyRelationship": false,
      "subConfigurationRef": null,      // symbolic: configurationGuid or entity name of a sibling seed
      "fields": [                       // array order = field order
        { "fieldGuid": "…", "fieldName": "Name", "label": "Gate name", "description": "…",
          "fieldType": "String", "isRequired": true, "settingsJson": null,
          "displayConditionGroups": [ { "sourceFieldGuid": "…", "…": "…" } ] }
      ]
    }
  ],
  "validationRules": [                  // applied after the config exists
    { "fieldGuid": "…", "validationType": "LocationInsideRegion",
      "dependsOn": { "fieldGuid": "…" }, "dependencyPath": "GateStructure.WgRegionId",
      "configJson": "…", "errorMessage": "…", "isBlocking": true }
  ]
}
```

Rules for the importer:

1. **Never overwrite.** Import creates a new configuration. If one with the same `configurationGuid` exists, report
   "already imported" and stop (a re-import of a changed seed gets a new name, e.g. "Gate Structure (seed v2)").
2. **Default only when asked or when none exists.** `IsDefault=true` only if the entity has no default yet, or the
   caller asks to replace it; then the old default is unset in the same transaction (moves the uniqueness rule into
   the API).
3. **Dry run** (`?dryRun=true`) validates with `FormTemplateValidationService`, resolves every symbolic reference and
   returns the problems without writing. Metadata drift (a field that no longer exists) fails loudly.
4. **Symbolic references**: `subConfigurationRef` and rule `dependsOn` resolve by GUID within the file, or to another
   seed's `configurationGuid` (join/child configs are imported first, in dependency order — as done by hand in
   `siege-minigame/PHASE_3_FORMCONFIGS.md:29-34`). Reusable steps are inlined as copies, not linked.
5. **Settings verbatim**: `settingsJson` is stored as written; world-task types are checked against the known list
   (`FieldEditor.tsx:63-78`, including the legacy `ReagionCreate` spelling).
6. **DTO-only properties** (`canCreate`, `minSelection`, `incrementValue`) produce a warning, not silent loss.

Endpoints (writes behind `knk.admin.content`, like the rest of `FormConfigurationsController`):

- `GET api/FormConfigurations/{id}/export` → the file above (GUIDs, no database ids).
- `POST api/FormConfigurations/import?dryRun=&makeDefault=` → body = the file.
- `GET api/FormConfigurations/seeds` / `POST api/FormConfigurations/seeds/{name}/import` → list and import the
  bundled files from `Data/FormConfigurationSeeds/`.

Web app: Export / Import buttons on the form configuration list, and an "Available seeds" panel showing which
bundled seeds are imported, with a dry-run result before importing.

### 3.3 Workflow with an agent

1. Developer exports the current configs worth keeping (e.g. GateStructure 9, GateDoor 12, siege 23-33) and commits
   them to the seed folder, or the agent starts from the doc payloads where no export exists.
2. The agent rewrites names, descriptions, order and step split following §4, using the sources in §5, and opens a PR
   with the seed files and a short "what changed per step" table.
3. Developer imports the seed as a **non-default** config, walks through it in the wizard, edits in the builder if
   needed, then makes it the default (or re-exports the tuned version into the PR).

### 3.4 Status (KNG-138, 2026-10-12)

**Implemented** on `claude/jolly-archimedes-urhio9` (form wizard chain link 6; knk-web-api `b62cdce`, knk-web-app
`1c3e835`; not merged, live test pending). Differences from §3.2, all small:

- `subConfigurationRef` is an object `{ configurationGuid, entityTypeName, name }`; only the GUID is used to resolve
  it (entity/name are for readers; an entity name alone resolves to that entity's default, with a warning).
- Validation rules depending on a field of **another** configuration (the siege "parent form" rules) write
  `dependsOn: { fieldGuid, configurationGuid }`; that configuration must be imported first.
- Rule 6 is moot: since KNG-164 `canCreate`, `minSelection`, `maxSelection` and `incrementValue` are columns and are
  carried, so there is nothing to warn about.
- Also carried: step conditions (`conditions`), simple field validations (`validations`), `dependencyConditionJson`,
  inline `childFormSteps` (without display conditions). Not carried (export `notes` say so): reusable-step links
  (exported as copies), the legacy `FormField.DependsOnFieldId`.
- Statuses: dry run passed → 200, imported → 201, already imported → 409, invalid → 400; the body is always the
  result (`errors`, `warnings`, default handling). An unknown world-task type is a warning, not an error
  (settings stay verbatim).
- Seed files: any `*.json` name in `Data/FormConfigurationSeeds/` (the `{name}` in `seeds/{name}/import` is the file
  name without `.json`). The API's `FormConfigurationSeedFilesTests` dry-runs and imports every file there, in
  dependency order.

## 4. Authoring guide (for agents and the developer)

**Steps**

- 3-8 fields per step; one decision or one place in the world per step. Order: identity → placement/world → rules
  and behaviour → relations/children → review.
- Step name: 1-4 words, sentence case, a noun phrase ("Region and rules", "Gate doors"). No numbering; the wizard
  numbers steps.
- Step description: 1-2 sentences saying what this step decides and anything the admin must do in game first
  ("Stand at the gate and use Send to Minecraft for each point. Points must be inside the gate's region.").
- World-task steps say which in-game action is expected and in what order.
- Conditional steps (display conditions) say in their description when they appear ("Only for sliding doors.").

**Fields**

- Label: what it is in the admin's terms, sentence case, no type suffix ("Region", not "WgRegionId"; "Street", not
  "Street Id").
- Description: one sentence on *why* or *effect*, plus units/limits ("Seconds the gate stays open after a pass.
  0 = closes immediately."). Don't repeat the label. Mention defaults that apply when left empty.
- Placeholder only for examples of format; never on String fields with `enumValues`.
- Relationship fields say whether "Create New" is expected here, and what the child form will ask.
- Booleans get a description too (shown once KNG-137 lands).
- Runtime-only properties (`CurrentSiegeId`, `IsSiegeObjective`, override fields set by dedicated endpoints) are not
  put on default forms; say so in the PR.

**Checks before a PR**: the dry-run import passes; every required non-nullable property is on the form; display
conditions only refer to earlier fields; descriptions read correctly when the step is reached via a child form.

### 4.1 Example outline — GateStructure (illustrative, to be refined in KNG-139)

Based on the current layout (§5.10-5.11 of the GateStructure QOL plan) and `api/Models/GateStructure.cs` →
`Structure` → `Domain`:

| # | Step | Description (draft) | Fields |
|---|---|---|---|
| 1 | General information | Name the gate. The name is shown in game and used by `/gate` commands. | Name, Description, Icon material |
| 2 | Address | Where the gate stands. Create the street or district here if it doesn't exist yet. | District, Street, House number |
| 3 | Region and rules | The WorldGuard region of the whole gate, and who may pass. Create the region in game first, or with Send to Minecraft. | Region, World, Allow entry, Allow exit |
| 4 | Locations | The gate's own Location (capture it in game), and where guards spawn. | Location, Guard spawn locations, Guard count |
| 5 | Siege behaviour | How the gate behaves during a siege. | Animate during siege, Can be overridden |
| 6 | Gate doors | The doors that open and close. Save the gate first; each door has its own form. | Gate doors (owned) |

## 5. Content inventory and sources

| Priority | Configurations | Sources |
|---|---|---|
| 1 | GateStructure, GateDoor | `gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` §5.10-5.11, `SPEC.md`, `REQUIREMENTS_GATE_FRONTEND.md`, `GATE_FORMCONFIG.md` (Dutch, predates the GateDoor split — stale), `guides/gate-smoke-test.md`, `architecture/gate-commands.md`, dev-DB export of 9/12 |
| 1 | Siege ("minigame"): SiegeScenario, SiegeScenarioDistrict, SiegeScenarioGate, SiegeTeam, SiegeSpawnpoint, SiegeObjective, SiegeLobby, SiegeLobbyScenario | `siege-minigame/PHASE_3_FORMCONFIGS.md` (full payloads, configs 23-33), `siege-minigame/DESIGN.md`, `guides/authoring-a-siege-scenario.md` |
| 2 | Domain family: Town, District, Street, Structure, Location | `towns/`, `navigation/IMPLEMENTATION_PLAN.md` (Street "Road" step), `architecture/location-retention.md`, `domain-discovery/` |
| 3 | Items, kits, lootboxes, enchantments, teleport, permission groups | the `…_FORMCONFIGS.md` records above, `user-features/` |

There is no `Minigame` model; the siege configuration is the `Models/Siege/` set above.

## 6. Order of work

1. **KNG-137** (small, web app): show step names and Boolean descriptions — makes the authored text visible.
2. **KNG-138** (API + web app): export/import + bundled seeds, with tests for GUID resolution, dry run, default
   handling and "never overwrite".
3. **KNG-139** (content): per §5 priority. Each group is its own PR of seed files; the developer imports and reviews
   live.
