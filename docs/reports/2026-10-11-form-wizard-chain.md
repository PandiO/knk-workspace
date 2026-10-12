# Form wizard chain — progress report

**Status:** Running — links 1-3 done (2026-10-12); link 4 (KNG-136) next.
**Last updated:** 2026-10-12 (link 3 done)
**Charter:** [FORM_WIZARD_CHAIN.md](../ai-agents/handoffs/FORM_WIZARD_CHAIN.md). Append-only below the Summary.

## Summary

| Link | Issue(s) | Status | Heads (web-app / web-api / workspace) |
|---|---|---|---|
| 1 | KNG-133 | **Done** (In Review, live test pending); first attempt blocked (§4.1), restarted 2026-10-12 | `ff12c8f` / unchanged `917537a` / docs + handoff |
| 2 | KNG-134 | **Done** (In Review, live test pending) | `602db8e` / unchanged `917537a` / docs + handoff |
| 3 | KNG-135 + KNG-137 + KNG-164 | **Done** (In Review, live test pending; dev DB needs the migration) | `a1c5896` / `29f65b3` / docs + handoff |
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
