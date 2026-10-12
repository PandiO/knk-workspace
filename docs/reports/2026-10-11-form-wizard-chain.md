# Form wizard chain — progress report

**Status:** Running — links 1-6 done (2026-10-12); link 7 (KNG-139 + write-up) next.
**Last updated:** 2026-10-12 (link 6 done)
**Charter:** [FORM_WIZARD_CHAIN.md](../ai-agents/handoffs/FORM_WIZARD_CHAIN.md). Append-only below the Summary.

## Summary

| Link | Issue(s) | Status | Heads (web-app / web-api / workspace) |
|---|---|---|---|
| 1 | KNG-133 | **Done** (In Review, live test pending); first attempt blocked (§4.1), restarted 2026-10-12 | `ff12c8f` / unchanged `917537a` / docs + handoff |
| 2 | KNG-134 | **Done** (In Review, live test pending) | `602db8e` / unchanged `917537a` / docs + handoff |
| 3 | KNG-135 + KNG-137 + KNG-164 | **Done** (In Review, live test pending; dev DB needs the migration) | `a1c5896` / `29f65b3` / docs + handoff |
| 4 | KNG-136 | **Done** (In Review, live test pending) | `8ae5a66` / unchanged `29f65b3` / docs + handoff |
| 5 | KNG-162 | **Done** (In Review, live test pending; dev DB needs links 3 and 5 migrations) | `22cb588` / `959bc11` / docs + handoff |
| 6 | KNG-138 | **Done** (In Review, live test pending; no migration) | `1c3e835` / `b62cdce` / docs + handoff |
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

## Coordinator — 2026-10-12: after link 1

- Verified link 1's pushes (web-app `ff12c8f`, workspace `ccff609`). Filed its follow-up as [KNG-164](https://linear.app/kngpandi/issue/KNG-164) (required List accepts empty; `minSelection`/`canCreate` have no column) and added it to link 3. Link 2 started as a coordinator subagent (Opus, high effort).

## Link 2 — KNG-134: Edit instance opens a blank or stale child form (2026-10-12)

Started by the coordinator as a fresh subagent (charter §6). Trunks had not moved (web-app `main` `38854ba`, web-api
`master` `917537a`); trunk merges at start and end were no-ops. Push dry-run passed (knk-web-app, knk-workspace).
Tracker claim pushed to workspace `main` (`183b61b`).

- **Commits (knk-web-app, branch `claude/jolly-archimedes-urhio9`):** `b75ce07` List items without an id get their own
  key, remove and edit; `7b7199f` Edit instance seeds the child form from the value the parent holds; `602db8e`
  Replace via Minecraft keeps the Location id, inherited capture fills the form (head `602db8e`). knk-web-api and
  knk-plugin unchanged (`917537a`, `1b3e06c2`).
- **What changed:**
  - New `src/utils/forms/childEditSeed.ts`: `buildChildEditSeedValues(cfg, instance)` (field values by
    case-insensitive name through `resolveObjectFieldValueForEdit`; many-to-many steps skipped) and
    `overlayChildEditValues(cfg, stepsData, seed)`.
  - `FormWizard`: `ChildFormState` gains `initialValues` (the held instance) and `editingInMemory`
    (`!shouldPersistChildOnComplete(field)`, i.e. an embedded Location); new prop `overlayFieldValues`, laid over the
    database load in `loadExistingEntityData`. `ChildFormModal`: new props `initialValues`, `overlayInitialValues`;
    without an id it seeds the form (merged over the parent-link prefill) and titles it "Edit …" ("… (not saved
    yet)"); with an id it passes the overlay only for `editingInMemory`.
  - `handleChildFormComplete` unchanged: it already replaced in place at `listItemIndex` and kept the id
    (KNG-130 branch / persisted update). The wrong index came from `ListField`'s `findIndex(c => c.id === item.id)`.
  - `ListField`: keys from new `src/utils/forms/listItemKeys.ts` (id, else a client key per item object, unique per
    list); remove and Edit instance use the item's position; an id-less item shows "Not saved yet".
  - `WorldBoundFieldRenderer`: a Location capture replacing a value with an id keeps that id
    (`keepLocationIdOnReplace`, new `src/utils/forms/worldTaskFieldValue.ts`).
  - **Spec §2.3 verified and confirmed:** a child opened from a world-task field inherits `worldTaskHint`; with no
    world-task field and no field named like the parent field (Location form: Name/X/Y/Z/World vs "Location"), the
    panel binds to the first visible field, and a Location capture was written as one object into `Name`. Fixed: for
    that inherited first-field binding an object result is spread over the current step's fields of the same name
    (`spreadTaskValueOntoFields` → `applyMultipleFieldChanges`); a scalar result or no matching key writes the bound
    field as before.
- **Tests:** web app 698 passed / 5 failed (baseline 669 / 5; +29 new: 11 `childEditSeed`, 6 `worldTaskFieldValue`,
  4 `listItemKeys`, 3 ListField, 3 FormWizard UI, 2 WorldBoundFieldRenderer — the UI ones were run against the
  unfixed code and all failed there); the 5 failures are the same 4 known-red suites as `main`. New UI tests
  `FormWizard.childEditSeed.ui.test.tsx` (captured Location edit twice, saved Location edited twice, inherited capture
  fills X/Y/Z), `FieldRenderers.listIdlessItems.test.tsx`, `Workflow/__tests__/WorldBoundFieldRenderer.replaceKeepsId.test.tsx`
  (real 2 s poll, ~2 s each). `npm run build` compiles with the same single `FormWizard.tsx` warning as before. API
  not rerun (unchanged; baseline 2550 / 4).
- **Flagged decisions:**
  - **L2-1** The in-memory overlay is used only for children that aren't saved on completion (a single Location). A
    child saved through its own API (L1-4) loads from the database only: its edit is already saved, and a held value
    can be a picker row with fewer columns than the record, which must not overwrite it.
  - **L2-2** Edit instance on an id-less item of a field whose children are saved on completion (an old draft's
    District) seeds the form, and completing it **creates** the entity and puts it in place of the id-less item. That
    is the way out of KNG-133's "never saved" refusal for such items.
  - **L2-3** L1-2 stays: an id-less single Location without x/y/z keys is still left out without error. Seeding
    doesn't change it: a world-task capture always has coordinates and the Location form's X/Y/Z fields always
    produce the keys. Making it an error risks blocking forms whose Location field holds an odd default; follow-up.
  - **L2-4** §2.3 fixed by spreading the result (keeps the "capture inside the child" feature) rather than switching
    inheritance off. Only fields of the current step are filled.
  - **L2-5** Replace keeps the id only for Location task types (`isLocationTask`) and only when the held value has a
    real id (not `-1`/`0`) and the capture none.
- **Discrepancies with the design:** none in substance. `handleChildFormComplete` needed no change (§3.4's "replace in
  place, keep id" already held; the bug was ListField's index). `PagedEntityTable` still matches selection by id only
  (§2.3 last bullet) — left for KNG-136 (link 4, §3.3 stable keys) as the handoff said.
- **Live checklist (developer):**
  1. Town or GateStructure form, Location **Send to Minecraft**, capture → **Edit instance**: title "Edit Location",
     captured name/x/y/z/world shown. Change the name, submit, Edit instance again: the new name. Submit the parent:
     the Location is saved with that name.
  2. Edit an existing Town: Edit instance on its Location, change name/X, submit; Edit instance again shows the
     change (not the database value). Submit the Town: the same Location id is updated.
  3. Existing Town with a Location: **Replace via Minecraft**, then submit the Town: no new row in `locations`; the
     Town's LocationId is unchanged and has the new coordinates.
  4. If the dev-DB Location form has no world-task field of its own: from a world-task Location field open the child
     Location form and use its Send to Minecraft: X/Y/Z/World filled, Name is not "[object Object]".
  5. A draft holding two unsaved Districts (if any exists): remove one → only that one goes; Edit instance on the
     second opens the second; completing it saves it (it gets an id).
  6. Regression: Edit instance on a saved Street (Object) or District (List item) still loads the saved record and
     saving updates it; GateDoors (owned collection) unchanged.
- **Follow-ups (not fixed, scope):** L2-3 (id-less Location without coordinates dropped silently);
  `PagedEntityTable` selection sync (`selectedItems.some(item => !internalSelection.some(sel => sel.id === item.id))`)
  treats all id-less items as equal (KNG-136); the spread via `applyMultipleFieldChanges` skips value projections and
  display-condition reconcile that `handleFieldChange` does (same as ItemScan today).
- **Risks:** `FormWizard.tsx` edits are thin (2 imports, 1 prop, 2 state fields, overlay line in
  `loadExistingEntityData`, the world-task `onChange` and one boolean) for the KNG-120/KNG-132 merges. Held values
  in form-field shape (PascalCase, from a completed child) and DTO shape (camelCase, from an edit load) both seed by
  case-insensitive name.
- **Next link must know:** link 3 = KNG-135 + KNG-137 + KNG-164. For KNG-135, `buildChildEditSeedValues` goes through
  `resolveObjectFieldValueForEdit`, so extending that function to List `XIds`/`Xs` pairs also fixes seeding from
  held values. KNG-164 touches `FormWizard.validateField` (required List `[]`) — keep the logic in a new module.
- **How the next link is started:** by the coordinator as a fresh subagent with
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-3.md` (charter §6).

## Coordinator — 2026-10-12: after link 2

- Verified link 2's pushes (web-app `602db8e`, workspace `26e815f`).
- Access test session `session_01JqTqe6mbu3Yazp8WwLc4Ex`: started with knk-workspace only, its prompt asked it to `add_repo` knk-web-app and knk-web-api with push; both were attached and `git push --dry-run` succeeded on both. Charter §6 changed: from link 3, each link is a session started by the coordinator with the `add_repo` step in its prompt; subagent fallback if refused.
- Link 3 started as session (see next block).

## Link 3 — KNG-135 + KNG-137 + KNG-164: List edit load, step names, required/min List (2026-10-12)

Started by the coordinator as a **session** (`session_01SZ9c7pGMwGfvHR3dHAmWgQ` relayed the developer's request in the
prompt, charter §6). `add_repo` (push) for knk-web-app, knk-web-api and knk-plugin was accepted; `git push --dry-run`
on `claude/jolly-archimedes-urhio9` passed in all three and in knk-workspace. Trunks had not moved (web-app `main`
`38854ba`, web-api `master` `917537a`), so the trunk merges at start and end were no-ops. Tracker claim pushed to
workspace `main` (`8ca64fb`); Linear KNG-135/137/164 set In Progress.

- **Commits (branch `claude/jolly-archimedes-urhio9`):**
  - knk-web-app: `ee214a4` KNG-135 List XIds/Xs edit load; `18f3d7c` KNG-137 step header + Boolean description;
    `a1c5896` KNG-164 required/min/max List validation (head `a1c5896`).
  - knk-web-api (first change in this chain): `7b01458` KNG-135 `DistrictIds` on read; `29f65b3` KNG-164 FormField
    columns + additive migration (head `29f65b3`).
  - knk-plugin unchanged (`1b3e06c2`).
- **What changed:**
  - **KNG-135** web-app: `resolveObjectFieldValueForEdit` (`utils/forms/objectFieldEditValue.ts`) now also handles
    List fields with an `objectType`: an `XIds`-authored field takes the DTO's `Xs` objects (they carry names), else
    turns bare ids into `{ id }`; an `Xs`-authored field with no (or an empty) `Xs` array falls back to `{ id }`s from
    `XIds`. `-y`/`-ies` pairs (`CategoryIds`/`Categories`) are matched. Held objects (seeding a child from the parent)
    pass through unchanged. Both the edit load (`loadExistingEntityData`) and `buildChildEditSeedValues` use it, so
    no `FormWizard.tsx` change was needed.
  - **KNG-135** API: `StreetMappingProfile` and `TownMappingProfile` fill `DistrictIds` on read.
    **DTO audit** (every `List<int> *Ids` in `Dtos/`): already filled on read: `DistrictDto.StreetIds`,
    `TownDto.StreetIds`, `GateStructureDto.GuardSpawnLocationIds`, `RoadProfileDto.ScopeTownIds`; fixed:
    `StreetDto.DistrictIds`, `TownDto.DistrictIds`; not form entities (request/result/runtime DTOs, left alone):
    `DiscoveryGrantRequestDto.DomainIds`, `SiegeRuntimeDto.AreaGateStructureIds`, `RoadEdgeDto`/`RoadTileGraphEdgeDto`/
    `RoadEdgeRecordDto` `GateDoorIds`+`DomainIds`, `RoadTileUpsertResultDto.BumpedTileIds`,
    `RoadEdgeUpdateResultDto.ChangedEdgeIds`/`EdgeIds`, `RoadEdgePruneResultDto.DeletedNodeIds`,
    `LootboxRuntimeAreaDto.AllowedTypeIds`, `LootboxInGameAreaDeleteResultDto.RemovedSpawnIds`,
    `LootboxWorldChangedNotificationDto.RemovedSpawnIds`, `PrivacyDeletionResultDto.UserIds`,
    `TelemetryClientConfigDto.*Ids`, `SiegeMatchAbortUnfinishedResultDto.AbortedMatchIds`,
    `SiegeGateRestoreResultDto.ClearedGateStructureIds`.
  - **KNG-137**: new `src/components/FormWizard/WizardStepHeader.tsx` (`WizardStepProgress`, `WizardStepTitle`).
    Progress bar: step name under each number (`max-w-[7rem] truncate`, full name in `title`, `hidden md:block`, so
    numbers only on narrow screens), `aria-current="step"`, `aria-label="Step n: name"`. Title: the step name stays
    the `h2` in edit mode, "Edit {entity}" becomes a small heading above it (falls back to the `h2` for a step without
    a name). `FormWizard.tsx` only swaps its inline header markup for the two components. `BooleanField` renders
    `field.description` under the label, linked with `aria-describedby`.
  - **KNG-164** web-app: new `src/utils/forms/listFieldValidation.ts` (`validateListFieldCount`); `validateField`
    sends List fields there (one call; the old generic "is required" check no longer applies to Lists). A required
    List needs ≥ 1 item (`minSelection` raises it); `minSelection` on an optional list applies once it has items;
    `maxSelection` caps it; null/0/negative = no limit; null/''/undefined entries don't count. Messages name the field,
    e.g. `Districts is required: select at least 1 District`, `Districts needs at least 2 Districts (1 selected)`.
    `handleNext` validates before Next and before Submit, so both are blocked.
  - **KNG-164** API: `FormField` gets nullable `MinSelection`, `MaxSelection`, `CanCreate`, `IncrementValue`;
    `FormMappingProfile` maps them both ways; `FormConfigurationRepository.UpdateAsync` (both step levels, create and
    update branches) and `FormTemplateReusableService` (copy + link) copy them. Migration
    `20261012075746_AddFormFieldSelectionLimits` (generated with `dotnet ef migrations add`; four `AddColumn`s on
    `FormFields`, nullable, nothing else; snapshot updated). **The API does not migrate on startup: the dev DB needs
    `dotnet ef database update` before running this branch** (see risks).
- **Tests:** web app **729 passed / 5 failed** (baseline re-measured before changes: 698 / 5; +31 new: 8
  `objectFieldEditValue`, 1 `childEditSeed`, 7 `WizardStepHeader`, 2 Boolean renderer, 8 `listFieldValidation`, 5
  `FormWizard.requiredList.ui`); the 5 failures are the same 4 known-red suites (`FormWizard.m2mJoinPrefill.ui`,
  `ManyToManyRelationshipEditor.ui`, `useEnrichedFormContext`, `RoadsAdminPage`). The new UI test run against the
  unfixed `FormWizard.tsx`: 4 of 5 fail there (the fifth is the KNG-135 edit-load pass case). API **2556 passed / 4 failed** (baseline re-measured: 2550 / 4; +6 new: 1
  `StreetServiceTests` (GetById returns `districtIds`, serialized as `districtIds`), 1 `TownMappingProfileTests`, 4
  `FormFieldSelectionLimitsTests` (mapping both ways, null stays null, repository create + update merge, migration is
  four nullable AddColumns only)); the 4 failures are the known-red ones; `EndpointAccessRulesTests` green (no new
  endpoints). `dotnet build knkwebapi_v2.csproj` succeeds. `npm run build` compiles with the same single
  `FormWizard.tsx` warning as before (line 302, pre-existing).
- **Flagged decisions:**
  - **L3-1** `IncrementValue` added in the same migration: it is DTO-only like the other three, and the builder
    (`FieldEditor`) and wizard (Integer step) use it, so it was dropped on save the same way.
  - **L3-2** Owned child collections (`ownedChildCollection`, e.g. GateDoors) are exempt from the required/min check
    while the parent isn't saved: their items can only be added after it ("Save this record first"), so the check
    would block creating the parent. In edit mode they are checked. Before this link a required owned collection with
    a `null` value was already blocked by the generic check; now it isn't in create mode.
  - **L3-3** An optional List with `minSelection` may stay empty; the minimum applies once it has items. `0` = no limit
    (the builder writes `0` when unset).
  - **L3-4** An `XIds`-authored field prefers the DTO's navigation objects over bare ids when both are present (names
    for display); the ids are the same, `normalizeFormSubmission` sends ids either way.
  - **L3-5** `TownDto.DistrictIds` is filled on read but `TownService` ignores it on write (a District belongs to a
    Town through `District.TownId`). Pre-existing; a Town form field on it would show Districts but changing it does
    nothing. Follow-up, not fixed.
  - **L3-6** Step names are hidden below the `md` breakpoint (numbers only), per the issue; screen readers get the name
    from `aria-label`.
- **Discrepancies with the design:** none in substance. KNG-135 needed no `FormWizard.tsx` change (both paths already
  go through `resolveObjectFieldValueForEdit`).
- **Live checklist (developer):**
  0. **First apply the migration** to the dev DB (`dotnet ef database update` in knk-web-api on this branch). Without
     it every FormField query fails (unknown columns `CanCreate`/`IncrementValue`/`MaxSelection`/`MinSelection`).
  1. Edit a Street that has Districts: the Districts are shown selected, whichever name the field uses (`DistrictIds`
     or `Districts`). Submit unchanged: the Street keeps its Districts.
  2. GateStructure → Street → **Edit instance**: the Street's Districts are shown (L2-1: loads from the DB).
  3. Street form with a required Districts field and none picked: Next (or Submit) shows "Districts is required:
     select at least 1 District" and stays.
  4. Form builder: set Min selection 2 on the Street's Districts field, save, reload the builder: 2 is still there.
     In the wizard with one District picked: "Districts needs at least 2 Districts (1 selected)".
  5. GateStructure create with its GateDoors field (if marked required): not blocked by the empty GateDoors list.
  6. GateStructure and SiegeScenario forms, desktop and narrow width: step names under the progress-bar numbers
     (truncated, full name on hover), numbers only when narrow. Edit an existing GateStructure: the step name is the
     title, "EDIT GATESTRUCTURE" small above it.
  7. A Boolean field with a description (e.g. a GateStructure checkbox): the description shows under the label.
- **Follow-ups (not fixed, scope):** `canCreate` has no control in `FieldEditor` (settable only through the API/seed
  files until a builder toggle is added); `StreetRepository.GetAllAsync` doesn't include Districts, so the Street list
  read returns empty `districts`/`districtIds` (unchanged); L3-5; `knkwebapi_v2.sln` references
  `tests\knkwebapi_v2.Tests\…` (lowercase), so `dotnet build` on the solution fails on Linux; build the project file.
- **Risks:** the migration must be applied before the branch runs (checklist 0); merge order API (migration) before
  the web app. `FormWizard.tsx` edits are thin (2 imports, header markup → 2 components, one `if` in
  `validateField`) for the KNG-120/KNG-132 merges. KNG-132's GateDoor-description data migration
  (`f40ce73`, unmerged) is earlier-dated than `AddFormFieldSelectionLimits` and touches no columns, so either order
  works; a later trunk merge only needs the snapshot to stay consistent (regenerate nothing by hand).
  New tracker claim (2026-10-11, `claude/api-vulnerable-packages`, knk-web-api): an AutoMapper upgrade that may change
  `new MapperConfiguration(...)` call sites; this link adds two test files using that constructor
  (`Mapping/TownMappingProfileTests.cs`, `Repositories/FormFieldSelectionLimitsTests.cs`), so whichever merges second
  adjusts them.
- **Next link must know:** link 4 = KNG-136 (form session registry, pinned "New" rows in pickers, `PagedEntityTable`
  stable keys and first tests). `PagedEntityTable` still enforces `min` only on deselect; the wizard now enforces the
  count at Next/Submit. List values are objects with `id` (edit load now yields `{ id }` for bare ids), which is what
  the picker's id-based selection matches.
- **How the next link is started:** by the coordinator (charter §6), from
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-4.md`.

## Link 4 — KNG-136: Form session registry; pickers pin entities created in this form session (2026-10-12)

Started by the coordinator as a new session (charter §6) with `add_repo` for knk-web-app, knk-web-api and knk-plugin
in its prompt: all three attached with push, cloned, feature branch checked out, `git push --dry-run` passed in all
three and in knk-workspace. Trunks had not moved (web-app `main` `38854ba`, web-api `master` `917537a`), so the trunk
merges at start and end were no-ops. Tracker claim pushed to workspace `main` (`fe9f104`); Linear KNG-136 set In
Progress.

- **Commits (knk-web-app, branch `claude/jolly-archimedes-urhio9`):** `d0d805d` registry + pinned-row rules;
  `89b4476` PagedEntityTable pinned rows, stable keys, id-based selection, first tests; `8ae5a66` wiring (FormWizard
  wrapper + registration, ManyToManyRelationshipEditor registration, ObjectField/ListField pinned rows) (head
  `8ae5a66`). knk-web-api unchanged (`29f65b3`), knk-plugin unchanged (`1b3e06c2`).
- **What changed (all knk-web-app):**
  - `src/contexts/FormSessionContext.tsx` (new): `FormSessionScope` + `useFormSession()`. The first scope with no
    registry above it creates one (`RootRegistry`); nested scopes share it and append their form name to
    `formPath`. `SessionEntity` = `key` (`<type lower-case>:<id>`, or `concept:<n>` for an embedded value without
    id), `entityTypeName`, `id`, `display` (the DTO the child returned), `origin { formPath, fieldName }`, `status`
    (`created`/`updated`; an entity created then edited stays `created`), `embedded`, `sequence` (registration
    order), `revision`. `register()` upserts by key; `entitiesOfType()`; `createdEntities()` = created, not
    embedded, oldest first (**for link 5**). Pure `upsertSessionEntity` exported for tests.
  - `src/hooks/useSessionPinnedRows.ts` (new): created, non-embedded entries of one `objectType` as `PinnedRow`s
    (newest first, `{ ...display, id }`) plus a `refreshKey` (`key@revision` list) that changes on every
    registration or edit of that type. Never Locations (L4-2).
  - `src/utils/forms/sessionPinnedRows.ts` (new): `matchesSearchTerm`, `matchesPickerFilters`, `tableRowKey`,
    `isSameSelection`, `buildPinnedSection` (L4-1).
  - `PagedEntityTable`: `pinnedRows` prop → "Created in this form" section with a **New** badge (the hybrid
    New/Existing pill extracted into `RowBadge`, same styling) and a "Search results" divider; a pinned row the
    page also holds is shown once, pinned, with the **page's** data (database wins over the registry's `display`,
    flag L2-1). Rows keyed `id:<id>` / `ns:<namespaceKey>` / `pinned:<key>` (was the array index). Row selection,
    deselection and the selectedItems sync use `isSameSelection` (enchantment refs by namespaceKey, others by id,
    id-less only by identity) — the sync effect no longer treats all id-less items as equal (left by link 2).
  - `FormWizard.tsx` (thin, for the KNG-120/KNG-132 merges): the component body is renamed `FormWizardBody`; the
    exported `FormWizard` is a 5-line wrapper `<FormSessionScope formName={entityName}>`; one
    `useFormSession()` call; one `formSession?.register(...)` in `handleChildFormComplete` after the child's
    entity is saved/updated (or, for an embedded Location, with `embedded: true`).
  - `ManyToManyRelationshipEditor.tsx`: `handleCreateRelatedEntity` registers an entity it created (L4-4).
  - `FieldRenderers.tsx`: `ObjectField` and `ListField` call `useSessionPinnedRows(field.objectType)` and pass
    `pinnedRows` + `refreshKey` to their `PagedEntityTable`. Many-to-many steps pick related entities through the
    join-entry form's `ObjectField` (a nested wizard in the same session), so they are covered too.
- **Tests:** web app **764 passed / 5 failed** (baseline re-measured before changes: 729 / 5; +35 new: 16
  `sessionPinnedRows`, 8 `FormSessionContext` (incl. `useSessionPinnedRows`), 9 `PagedEntityTable` (its first
  tests: pinned section + badge, de-duplication with page data, search box and `pickerFilters` on pinned rows,
  pinned selection by id, id-less selection sync, stable keys, `refreshKey` refetch, empty state), 1
  `ManyToManyRelationshipEditor.sessionRegistry`, 1 `FormWizard.sessionPinnedRows.ui` (GateStructure → Street →
  District through the real ChildFormModal at both depths and the real PagedEntityTable with a mocked search
  client: the District is pinned and New in the GateStructure District picker without reopening, the search box
  hides/shows it, it is selectable, the GateStructure submits `DistrictIds: [501]`, `StreetId: 77`)). The UI test
  fails against the unchanged components ("Created in this form" never appears). The 5 failures are the same 4
  known-red suites (`FormWizard.m2mJoinPrefill.ui`, `ManyToManyRelationshipEditor.ui`, `useEnrichedFormContext`,
  `RoadsAdminPage`). `npm run build` compiles with no new warnings (the
  `PagedEntityTable` effects keep their pre-existing exhaustive-deps warnings; the selection-sync effect's deps now
  include `entityTypeName`). API not rerun (unchanged).
- **Flagged decisions:**
  - **L4-1** No paged search endpoint filters by a list of ids (the only id-ish filters are entity-specific:
    `Id`/`id` on two repositories, `excludeIds` on Category), so pinned rows are filtered **on the client**: the
    search term against `name`/`displayName`/`title`/`label`/`key`/`resolvedName` (substring) or the exact id; each
    `pickerFilters` entry against the row's `x`, `xId` or `x.id` (case-insensitive); `prefer…` filters are ignored
    (they only order results); `excludeIds` is applied; a filter the row can't answer **hides** the pinned row (the
    server might have excluded it) unless the current page holds the row (then the server accepted it). Reversible:
    an `ids` filter on the search endpoints would let the table re-query instead.
  - **L4-2** Pinned are only entities the session **created**, never embedded values and **never Locations** (a
    Location belongs to one owner, `architecture/location-retention.md`; a List of Locations is saved per L1-1 but
    is still not offered elsewhere). Entities only edited in the session are already in the search results.
  - **L4-3** The registry is created by the exported `FormWizard` itself (the first one without a session above it),
    not by `FormWizardPage`, so every root wizard gets one with no page change. It lives as long as that root
    `FormWizard` is mounted: navigating away or the page remounting the wizard starts a new, empty registry (D3:
    not kept in drafts). `formPath` uses each wizard's `entityName` prop, which can be the lower-case route segment
    (`gatestructure`); use `entityTypeName` on the entries, not `formPath`, for API calls.
  - **L4-4** `ManyToManyRelationshipEditor`'s own "create related" `ChildFormModal` is never opened today (nothing
    calls `setShowCreateRelatedModal(true)`); the registration there follows the spec and is tested by completing
    the stubbed modal directly. Many-to-many steps create related entities through the join-entry form's Object
    field, which registers through `handleChildFormComplete`.
  - **L4-5** Pinned rows sit outside the pagination (not counted in "Showing x of y"), and "select all" still acts
    on the page rows only.
- **Discrepancies with the design:** none in substance. The spec suggested re-running the search with the session ids
  as a filter where possible; no endpoint supports it, so all filtering is client-side (L4-1). The provider is the
  `FormWizard` wrapper rather than `FormWizardPage` (spec allowed either; L4-3).
- **Live checklist (developer):** (the dev DB needs link 3's migration first — link 3 checklist item 0)
  1. GateStructure create → Street **Create New** → in the Street form, Districts **Create New** → District
     "Oostwijk", Submit. Without closing anything, the Street form's own Districts picker and (behind the modal) the
     GateStructure's District picker show "Created in this form" with **Oostwijk** and a **New** badge.
  2. Submit the Street. In the GateStructure form, the District picker still pins Oostwijk; type part of its name in
     the picker's search box: it stays; type something else: it disappears; clear: it's back. Select it: it shows
     under "Selected" with its id. Submit: the GateStructure is saved with that District.
  3. If a District with the same id is also on the first page of results, it is shown once (pinned).
  4. Open the GateStructure's Street "Select instance": the new Street is pinned there too.
  5. A Location made in a child form is never pinned in another picker.
  6. Reload the page / reopen the form: nothing is pinned any more (the registry isn't kept in drafts yet; KNG-162).
- **Follow-ups (not fixed, scope):** an `ids` filter on the paged search endpoints (would replace L4-1's client-side
  filtering); the dead "create related" modal in `ManyToManyRelationshipEditor` (L4-4) — remove or wire a button.
- **Risks:** `FormWizard.tsx` edits are thin (an import, the component renamed to `FormWizardBody`, one hook call, one
  `register` call, a wrapper at the end of the file). A KNG-120/KNG-132 merge that touches the
  `export const FormWizard: React.FC<FormWizardProps> = ({` line conflicts mechanically: keep their body changes and
  the rename. Tests that `jest.mock('../FormWizard')` are unaffected; code that relied on `FormWizard` being the body
  component itself (none found) would now get the wrapper.
- **Next link must know:** link 5 = KNG-162. `useFormSession()?.createdEntities()` lists what this root form's
  child forms saved, oldest first, with `entityTypeName`, `id`, `origin`, `sequence`; delete in **reverse
  `sequence`** (a later entity can reference an earlier one: the Street references the District it was created
  with). The registry is only reachable inside the root `FormWizard` (its wrapper is the provider); a cancel prompt
  rendered by `FormWizardPage` outside the wizard needs the scope lifted: wrap that part of the page in
  `<FormSessionScope formName=…>` — the inner `FormWizard` then joins it instead of creating its own. Persisting it
  (`CreatedEntitiesJson`) and re-seeding the registry from a resumed draft (D3) needs a way to seed entries
  (`upsertSessionEntity` is the pure core; a `seed(entries)` on the root registry is the natural addition).
- **How the next link is started:** by the coordinator (charter §6), from
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-5.md`.

## Link 5 — KNG-162: Cancel / delete-draft prompt; provenance `CreatedEntitiesJson` (2026-10-12)

Started by the coordinator as a new session (charter §6) with `add_repo` for knk-web-app, knk-web-api and knk-plugin
in its prompt: all three attached with push, cloned, feature branch checked out, `git push --dry-run` passed in all
three and in knk-workspace. Trunks had not moved (web-app `main` `38854ba`, web-api `master` `917537a`), so the code
trunk merges at start and end were no-ops; workspace `main` had only the tracker commits (merged). Tracker claim
pushed to workspace `main` (`613e498`); Linear KNG-162 set In Progress.

- **Commits:** knk-web-api `af7ed5d` `FormSubmissionProgress.CreatedEntitiesJson` (model, DTOs, mapping, service,
  migration); `959bc11` entity reference check + DELETE constraint filter (head `959bc11`). knk-web-app `94e3a6e`
  provenance + registry seed + resume; `22cb588` cancel / delete-draft prompt (head `22cb588`). knk-plugin unchanged
  (`1b3e06c2`).
- **What changed:**
  - **API** `Models/FormSubmissionProgress.cs`: nullable `CreatedEntitiesJson` (longtext). Migration
    `20261012085922_AddFormSubmissionProgressCreatedEntities` (generated with `dotnet ef migrations add`, one
    `AddColumn`, nothing else; snapshot updated; design-time run with `Database__MySqlServerVersion=8.0.36` and a dummy
    connection string, no DB touched). On `FormSubmissionProgressDto` **and** `FormSubmissionProgressSummaryDto`
    (Saved Progress uses summaries). `UpdateProgressAsync` overwrites it only when sent (null = keep, `"[]"` clears).
  - **API** `Services/EntityReferenceService.cs` (new) + `GET api/FormSubmissionProgress/entity-references/{type}/{id}
    ?ignore=Type:id` (controller-level `knk.admin.content`, read-only): for every FK in the EF model targeting the
    type (base types included, owned types excluded), counts referencing rows; join rows are labelled
    "Street (link)", plain FKs "Structure.DistrictId". A row that is, or links to, an entity in `ignore` doesn't count.
    Unknown type / unparsable id → 404.
  - **API** `Attributes/DeleteConstraintExceptionFilter.cs` (new, registered globally in `Program.cs`): a
    `DbUpdateException` (also wrapped) thrown from any DELETE action answers 409 `{code: "DbConstraint"}`. 34
    controllers with DELETE actions didn't catch it (e.g. `StreetsController`), so a referenced Street gave a 500.
  - **Web** `utils/forms/createdEntities.ts` (records, label fields only, tolerant parse, newest-first order),
    `utils/forms/deleteCreatedEntities.ts` (the delete run + result text), `utils/forms/createdEntityDeleteDeps.ts`
    (real API calls), `hooks/useCreatedEntitiesProvenance.ts`, `components/FormWizard/CreatedEntitiesPrompt.tsx`,
    `components/FormWizard/FormCancelAction.tsx`; `FormSessionContext.tsx` gains `seed()`, `seedSessionEntities`
    (pure) and `FormSessionRoot`; `formSubmissionClient.getEntityReferences`; `SavedProgressList` delete button gets
    an aria-label.
  - **Web** `FormWizard.tsx` (thin): an import, one hook call, `seedFromProgress(progress)` after loading an existing
    progress, `createdEntitiesJson` in `getProgressData`. Only the root wizard of a session sends it.
  - **Web** `FormWizardPage.tsx`: the wizard is wrapped in `FormSessionRoot` with "Cancel form" above it;
    `handleLeaveForm` closes the wizard and reloads configs + drafts (or returns to the parent display page when
    opened with a parent context); `handleDeleteProgress` shows the prompt when the draft's summary has a record,
    else the old `window.confirm`.
- **Tests:** web app **792 passed / 5 failed** (baseline re-measured before changes: 764 / 5; +28 new: 6
  `createdEntities`, 6 `deleteCreatedEntities`, 6 `FormSessionContext.seed` (seed, `FormSessionRoot`, provenance
  hook), 6 `FormWizard.cancelCreatedEntities.ui` (GateStructure → Street → District through the real wizard and
  ChildFormModals: Cancel lists both, Keep deletes nothing, Delete = Street then District with the right ignore lists
  and a report, in-use skip message, nothing-created confirm, Save Draft records both, a resumed draft pins and
  lists them), 4 `FormWizardPage.deleteDraft` (prompt from Saved Progress, Keep = draft only, close = nothing,
  plain confirm without a record)). The two provenance UI tests fail with the `FormWizard.tsx` call sites removed.
  The 5 failures are the same 4 known-red suites. `npm run build` compiles with no new warnings (the two
  `FormWizardPage` exhaustive-deps warnings are the existing init/auto-open effects, shifted lines). API **2574
  passed / 4 failed** (baseline re-measured: 2556 / 4; +18 new: 8 `EntityReferenceService` on the in-memory provider,
  5 `DeleteConstraintExceptionFilter`, 5 `FormSubmissionProgressCreatedEntities`; `EndpointAccessRulesTests` green);
  the 4 failures are the known-red `ClientActivityStoreTests`, 2x `PathResolutionServiceTests`,
  `FieldValidationServiceTests`.
- **Flagged decisions:**
  - **L5-1 "Explicit cancel".** There was no Cancel on the wizard. Added **Cancel form** above the root wizard on
    `FormWizardPage` (outside `FormWizard.tsx`). It leaves the form and **never deletes the draft** (most reversible);
    with nothing created it only asks "Leave this form?". Child forms (`ChildFormModal`) keep their own close
    behaviour; the prompt is for the root form only. After **Delete** on cancel, a draft left in Saved Progress still
    lists those entities (and its field values may point at them); deleting that draft later reports them
    "already deleted".
  - **L5-2 Delete order.** Newest first (reverse registration order). The issue says "deepest-first", but the
    District (deepest form) is saved before the Street that references it, so it must go second.
  - **L5-3 "In use".** Any referencing row counts, including cascade FKs (a cascade would silently delete the
    referencing row) and many-to-many links. Conservative: a new Street linked to an **existing** District is
    "in use (District (link))" and is kept; the admin deletes it by hand if wanted. Links to entities still pending in
    the same run are ignored (`ignore`), ones already handled are not (a skipped Street keeps its District). False
    "in use" keeps data, which is the reversible side.
  - **L5-4 409 everywhere.** The global DELETE filter changes a 500 into a 409 for every delete action that let a
    constraint error escape; delete actions that already caught it are unchanged.
  - **L5-5 When provenance is written.** With the root form's next save (Next, Save Draft, Submit). An entity a child
    saves after the last save is known in memory (Cancel sees it) but not by the draft until the next save; closing
    the tab then leaves it unrecorded (silent abandonment deletes nothing anyway).
  - **L5-6 Endpoint placement.** The reference check is on `FormSubmissionProgressController` (same
    `knk.admin.content` rule as drafts) rather than a new controller, and is generic over the EF model.
  - **L5-7 Delete-draft with Delete** deletes the draft even when some entities were skipped or failed (they are
    complete records; the report lists them). The prompt's names come from the label fields recorded at creation and
    may be stale (L2-1); the delete itself uses type + id.
  - **L5-8 Types without a web delete.** `getDeleteFunctionForEntity` covers about 20 types; an entity of another type
    is reported "not deleted (the web app has no delete for X)" and kept.
- **Discrepancies with the design:** "deepest-first" read as reverse creation order (L5-2). Otherwise as D2/D3.
- **Live checklist (developer):**
  0. **Apply both migrations** to the dev DB before running the branch: link 3's `AddFormFieldSelectionLimits` and
     this link's `AddFormSubmissionProgressCreatedEntities` (`dotnet ef database update` in knk-web-api on this
     branch). Both additive.
  1. GateStructure create → Street **Create New** "Gatestraat" → inside it Districts **Create New** "Oostwijk",
     Submit both. Click **Cancel form**: the prompt lists `District 'Oostwijk'` and `Street 'Gatestraat'`, **Keep
     them** focused. Keep → back to the configuration list; both rows exist.
  2. Repeat, **Delete them** → "Deleted 2 of 2", Street and District gone (Street deleted first).
  3. Repeat, but before cancelling pick Oostwijk in another, existing Street or Structure (other tab) → Delete → the
     District is "skipped: in use (used by …)", the Street is deleted.
  4. Repeat steps 1, **Save Draft**, Cancel → Keep. In Saved Progress click the trash icon: the prompt lists both;
     **Delete draft, keep them** removes only the draft. On another such draft, **Delete draft and them** removes the
     entities (report) and the draft.
  5. Resume such a draft: the GateStructure's District picker pins Oostwijk as **New**; Cancel lists it.
  6. A draft that created nothing: trash shows the old browser confirm. Cancel with nothing created: "Leave this
     form?"; Close stays in the form.
  7. Close the tab without cancelling: nothing is deleted; the retention cleanup is untouched.
- **Follow-ups (not fixed, scope):** update or clear the draft's `CreatedEntitiesJson` after a Delete on cancel
  (L5-1); write provenance right after a child saves instead of with the next save (L5-5); `tsc --noEmit` reports
  type errors in link 4's `utils/forms/__tests__/sessionPinnedRows.test.ts` (Jest doesn't type-check; build is
  unaffected); a cancel for the ChildFormModal level is not part of D2.
- **Risks:** `FormWizard.tsx` edits are 4 lines (import, hook call, two call sites) — mechanical against KNG-120 /
  KNG-132. The API migration is dated after link 3's and after KNG-132's `f40ce73`; all additive. The DELETE filter
  is global: a client that relied on a 500 for a constraint failure now gets 409 (none found in the web app; it
  reports any error). `claude/api-vulnerable-packages` (AutoMapper/OpenTelemetry) is unaffected by these files; the
  new mapping test uses `new MapperConfiguration(...)` like link 3's.
- **Next link must know:** link 6 = KNG-138 (FormConfiguration export/import, seeds endpoints, web-app buttons).
  Nothing in link 5 touches form configurations. New API pieces it may reuse: none needed; keep new write endpoints
  under explicit access rules (`knk.admin.content` for form configuration endpoints).
- **How the next link is started:** by the coordinator (charter §6), from
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-6.md`.

## Link 6 — KNG-138: FormConfiguration export/import, bundled seeds, web-app buttons (2026-10-12)

Started by the coordinator as a new session (charter §6) with `add_repo` for knk-web-app, knk-web-api and knk-plugin
in its prompt: all three attached with push, cloned, feature branch checked out, `git push --dry-run` passed in all
three and in knk-workspace. Trunks had not moved (web-app `main` `38854ba`, web-api `master` `917537a`), so the code
trunk merges at start and end were no-ops; workspace `main` had only tracker commits (merged). Tracker claim pushed to
workspace `main` (`762ef75`); Linear KNG-138 set In Progress. No other "In progress" row claims these files.

- **Commits:** knk-web-api `b62cdce` export/import service, endpoints, seed folder, tests (head `b62cdce`).
  knk-web-app `1c3e835` Export JSON + Import / Seeds dialog, client, tests (head `1c3e835`). knk-plugin unchanged
  (`1b3e06c2`). **No schema change, no migration.**
- **What changed:**
  - **API** `Dtos/FormConfigurationPortableDtos.cs` (format `knk-formconfig/1`, import result, seed list entry) and
    `Services/FormConfigurationPortabilityService.cs` (+ interface, registered with a `FormConfigurationSeedOptions`
    pointing at `<content root>/Data/FormConfigurationSeeds`). Export: `configurationGuid` (KNG-138's missing DTO
    field, now in the file), steps/fields in their `StepOrderJson`/`FieldOrderJson` order, every `FormField` column
    incl. the KNG-164 four, `settingsJson` verbatim, display conditions by `sourceFieldGuid`, step conditions, simple
    field validations, inline child steps, `subConfigurationRef {configurationGuid, entityTypeName, name}`, and
    `validationRules` with `dependsOn {fieldGuid}` (same file) or `{fieldGuid, configurationGuid}` (a field of another
    configuration — the siege "parent form" rules). `notes` lists what isn't carried (reusable links → copies, legacy
    `DependsOnFieldId`).
  - Import (`ImportAsync`/`ImportJsonAsync`): structure checks → **never overwrite** (existing `configurationGuid` →
    `AlreadyImported`, nothing written) → build the model keeping the file's step/field GUIDs → resolve every
    reference (sub configurations by GUID, display-condition sources, rule fields and `dependsOn`) → world-task type
    check, `settingsJson` must be a JSON object → `FormTemplateValidationService` (runs even when references failed,
    so a dry run lists drift and unresolved references together) → default handling → write. The write is one
    transaction on MySQL: unset the old default (only with `makeDefault`), `FormConfigurationRepository.AddAsync`
    (the API's own create path: display-condition source ids), then the `FieldValidationRules` with the new field ids.
    An unresolved reference to a configuration that a bundled seed provides says "It is the bundled seed 'X'".
  - **Endpoints** on `FormConfigurationsController`: `GET {id}/export` (JSON), `POST import?dryRun=&makeDefault=`
    (body = the file), `GET seeds`, `POST seeds/{name}/import?dryRun=&makeDefault=`. Results: dry run passed 200,
    imported 201, already imported 409, invalid 400 (body = result with `errors`/`warnings` always); concurrent
    duplicate (unique index) 409. Writes (incl. dry runs, which are POSTs) are behind `knk.admin.content` via the
    controller's existing `RequireServiceOrPermissionForWrites` rule; `EndpointAccessRulesTests` green.
  - **API** `Data/FormConfigurationSeeds/README.md` (folder for link 7; `*.json` there are content files, copied to
    the build/publish output like the other `Data/` catalogs).
  - **Web app** `FormConfigurationTable`: **Export JSON** in the row menu, **Import / Seeds** in the header (both
    optional props). New `FormConfigurationImportPanel` (dialog): "make default" checkbox; **Import a file** (reads
    the file, header check, automatic dry run, result banner with problems/warnings/counts, Import only after a
    passing dry run with the current checkbox state); **Available seeds** (the selected entity's seeds, "Show all";
    Imported (#id) badge, Unreadable + error, Check → Import). `formConfigClient`: `exportConfiguration`, `getSeeds`,
    `importConfiguration`, `importSeed`; a 400/409 with a result body resolves (no global error toast), other
    failures reject. `utils/forms/formConfigPortability.ts`: file name, download, header check, result texts.
    `FormWizardPage`: one state, one export handler, the two props and the dialog (reloads the list after an import).
- **Tests:** web app **813 passed / 5 failed** (baseline re-measured: 792 / 5; +21: 5 client, 3 helpers, 3 table,
  10 panel UI); the 5 failures are the same 4 known-red suites (`FormWizard.m2mJoinPrefill.ui`,
  `ManyToManyRelationshipEditor.ui`, `useEnrichedFormContext`, `RoadsAdminPage`). API **2613 passed / 4 failed**
  (baseline re-measured: 2574 / 4; +39: 27 `FormConfigurationPortabilityServiceTests`, 9
  `FormConfigurationsPortabilityControllerTests`, 3 `FormConfigurationSeedFilesTests`); the 4 failures are the
  known-red ones. The round-trip test authors a PHASE_3-shaped set (SiegeScenarioDistrict join entry, SiegeScenario
  with an M2M step on it, owned-child list, readiness panel, KNG-164 limits, a step condition and a field validation;
  SiegeObjective with a step and a field display condition on `GateStructureId`, world tasks, an enum subset; a same-form
  rule and a parent-form rule) through `FormConfigurationService.CreateAsync` (the POST path), exports, imports into
  an empty in-memory DB in dependency order and checks the re-export is byte-identical and the wizard DTO matches
  (steps, order, fields, settings, the M2M step pointing at the new join id). Mutation check: dropping
  `RequiresDependencyFilled` from the import made 2 tests fail. `dotnet build knkwebapi_v2.csproj` clean (no new
  warnings); `npm run build` compiles with the same pre-existing warnings (`FormWizardPage.tsx` 2 hook-deps warnings
  exist on the base too).
- **Flagged decisions:**
  - **L6-1** Same `configurationGuid` = always "already imported", nothing written; there is no replace or
    "import as copy" option (most reversible; spec §3.2 rule 1). To ship a changed seed: new GUID and name.
  - **L6-2** Import keeps the file's step and field GUIDs (references need them). Field GUIDs aren't unique in the
    DB, so a copy imported under a new `configurationGuid` reuses them; cross-configuration `dependsOn` is scoped by
    `configurationGuid`, so nothing becomes ambiguous.
  - **L6-3** A missing step/field GUID in a file is generated with a warning (nothing can refer to it); an invalid
    one is an error. An unknown world-task type is a warning (settings verbatim); `settingsJson` that isn't a JSON
    object is an error.
  - **L6-4** A `subConfigurationRef` with only an entity name resolves to that entity's default (warning).
  - **L6-5** Export and the seed list are reads (any logged-in user, like the rest of the controller's GETs); every
    import, including a dry run, is a POST behind `knk.admin.content`.
  - **L6-6** No "import all seeds": dependency order is the admin's (the error names the seed to import first).
  - **L6-7** Display conditions inside inline child steps are refused by the import (the create path only resolves
    top-level ones). No such configuration is known.
  - **L6-8** Validation rules from a file are not checked for circular dependencies (the rule service checks one rule
    at a time against the DB; a file with A→B and B→A would import). Follow-up.
  - **L6-9** The import is one transaction on relational providers only (MySQL); the in-memory test DB has none.
- **Discrepancies with the design (spec §3.4 records them):** `subConfigurationRef` is an object; parent-form rules
  carry `dependsOn.configurationGuid`; rule 6 (warn on DTO-only properties) is moot since KNG-164 made them columns;
  statuses 200/201/409/400. The acceptance item "export 9 and 12 from the dev DB, import into an empty DB" can only be
  done live (no dev DB here); the automated round trip uses the siege shape instead (charter).
- **KNG-132 interplay** (unmerged `claude/loving-johnson-dlshrc`, migration `f40ce73`
  `DescribeGateDoorGeometryFields`): it fills only **empty** descriptions of the GateDoor form's anchor/reference/
  geometry/motion fields, on every configuration whose `EntityTypeName = 'GateDoor'`, and keeps any text already
  there; its Down clears only fields whose text equals its own. So a GateDoor seed imported before that migration
  runs gets those descriptions filled when they are empty and keeps its own otherwise; a seed that reuses the exact
  KNG-132 text would lose it on that migration's Down. No conflict; link 7 should write those descriptions itself.
- **Live checklist (developer):**
  0. Links 3 and 5 migrations applied (this link has none). Log in as an admin with `knk.admin.content`.
  1. Form wizard page → GateStructure → ⋮ on configuration 9 → **Export JSON**: a file
     `GateStructure-<name>.json` downloads; it starts with `"format": "knk-formconfig/1"` and the configuration's
     `configurationGuid`, has no `"id"`s, steps in wizard order, world-task `settingsJson`, validation rules with
     `dependsOn`. Same for GateDoor 12.
  2. **Import / Seeds** → choose the GateStructure file: "Already imported as configuration 9. Nothing was changed."
  3. In a copy of the file change `configurationGuid` (any new UUID) and `name` ("Gate Structure (copy)"), choose it:
     "Dry run passed. Importing will add it as a non-default configuration." → **Import**: a new, non-default row.
     **Use** it: same steps, order, descriptions, conditions, world tasks and rules as 9. Delete the copy after.
  4. Tick **Make … the default**: the dry run now says "replacing 'Gate Structure …'" (import only if you then set 9
     back as default).
  5. In the copy change one `fieldName` to `NoSuchField` and a `subConfigurationRef.configurationGuid` (if any) to a
     new UUID: the dry run lists both problems; nothing is written.
  6. **Available seeds**: "No bundled seeds for GateStructure." until link 7's files exist; then each lists with
     **Check** / **Import**.
  7. (Acceptance) On a scratch DB with the branch's migrations, import the exported GateStructure, then GateDoor
     (parent-form rules need GateStructure first; the dry run says so otherwise) and compare the wizards with dev.
  8. As a user without `knk.admin.content`: Export works, any Check/Import shows "Forbidden"/403 in the dialog.
- **Follow-ups (not fixed, scope):** L6-8 (circular rules in a file); a builder toggle for `canCreate` (from link 3);
  an "import all seeds in dependency order" button if link 7's set proves tedious (L6-6); `tsc --noEmit` errors in
  link 4's `sessionPinnedRows.test.ts` (from link 5's list, unchanged).
- **Risks:** `FormWizardPage.tsx` gets ~25 added lines (import, state, handler, two props, dialog), `FormWizard.tsx`
  untouched — nothing for KNG-120/KNG-132 to collide with. A new `FormField` column must now also be added to
  `FormConfigurationPortabilityService` (noted in `web-api-architecture.md`). `claude/api-vulnerable-packages`
  (AutoMapper upgrade): the new service tests use `new MapperConfiguration(...)` like links 3 and 5.
- **Next link must know:** link 7 = KNG-139 + final write-up. Seed files go in knk-web-api
  `Data/FormConfigurationSeeds/*.json` (format: spec §3.2 + §3.4; the easiest model is an export — see
  `FormConfigurationPortabilityServiceTests.AuthorSiegeSetAsync` for the shapes, `"fieldType": "Object"` etc. as
  strings, `settingsJson` as a JSON *string*). `FormConfigurationSeedFilesTests` picks up every file automatically:
  readable, unique GUIDs, dry run passes and imports on an empty DB in dependency order. Give every seed, step and
  field a fixed GUID; join entries need their own seed and a `subConfigurationRef.configurationGuid` in the parent.
  Run `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter FullyQualifiedName~FormConfigurationSeed`.
- **How the next link is started:** by the coordinator (charter §6), from
  `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-7.md`.
