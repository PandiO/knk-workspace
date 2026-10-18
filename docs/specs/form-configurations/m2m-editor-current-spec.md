# Many-to-Many Relationship Editor (Current) — Requirements & Specs

**Status:** Current — describes `knk-web-app` as of branch `claude/bold-goodall-7eg00l` (2026-10-06; unmerged at
time of writing). Rewritten from the February 2026 version, which still described the related-entity picker table
that `c3b77a6` removed.
**Last updated:** 2026-10-06

## Overview
How a many-to-many (M2M) step behaves in the form wizard: `FormWizard` renders `ManyToManyRelationshipEditor` for
the step, holds the relationship rows in the step data, and opens the join-entry form for adding or editing a row.
Configuring such steps is covered by
[m2m-join-creation-developer-guide.md](m2m-join-creation-developer-guide.md).

## User Story
As an admin filling out a form (e.g. an ItemBlueprint), I can add, edit, reorder and remove the entity's
many-to-many relationships (e.g. its default enchantments), filling the join entity's own fields (e.g. `Level`)
for each, and have them saved with the entity.

## Configuration Contract
- `steps[].isManyToManyRelationship`: `true`.
- `steps[].relatedEntityPropertyName`: the collection property on the parent entity (e.g. `DefaultEnchantments`).
  The step's relationship rows live in the step data under this key (`relationships` if unset).
- `steps[].joinEntityType`: the join entity type (e.g. `ItemBlueprintDefaultEnchantment`). Required.
- Join fields come from one of:
  - `steps[].subConfigurationId` — a linked join-entity FormConfiguration (the preferred mode); or
  - `steps[].childFormSteps` — inline child steps whose fields are edited directly on each card.
- A List field named after `relatedEntityPropertyName` (`objectType` = the join entity type). Authored configs carry
  it (see the `PHASE_*_FORMCONFIGS.md` payloads under `docs/specs/`). It is optional: when a step lacks it,
  `FormWizard` adds it on load (`withManyToManyCarrierFields`, `src/utils/forms/manyToManyCarrierField.ts`), since
  the wizard keeps, flattens and submits step data per declared field. Before that fix, a step without the field
  silently dropped every relationship change.

`FormConfigBuilder` refuses to save an M2M step without `joinEntityType` or without a join-field source
(`getManyToManyStepIssues`, `src/utils/forms/manyToManyStepValidation.ts`).

## Functional Requirements
1. The editor loads the join entity's metadata and resolves the related entity type and its FK field as the related
   field that is not the parent's side. If that fails, it shows a configuration warning.
2. Each relationship row renders as a card showing the related entity (or a "Missing Entity" warning when it can't be
   resolved; pending rows are exempt until their join entry completes).
   - With a linked join configuration, the card summarises the join entity's scalar values and offers
     **Edit Join Entry**.
   - With inline child steps, the card renders the child-step fields for in-place editing, with per-field validation.
3. **Create New Join Entry** (linked join configuration only) appends a pending row seeded with the child-step
   defaults and opens the join-entry form for it. That form picks the related entity — its picker offers inline
   **Create New** for a related entity that doesn't exist yet — and fills the join fields. On completion the wizard
   writes the related entity, its FK and the join values back onto the row.
4. **Edit Join Entry** opens the join-entry form seeded from the row's saved values (edit mode hydrates saved join
   rows from the read DTO via `hydrateJoinRowsForEdit` / `joinFieldSeedValues`,
   `src/utils/forms/manyToManyEditLoad.ts`).
5. Opening a join entry first saves a draft of the parent form. Unfinished join-entry drafts for this parent are
   listed under the cards and can be resumed.
6. Rows can be removed.
7. When the join entity has a `SequenceNumber` field, rows can be reordered by drag and drop, and the editor keeps
   `SequenceNumber` equal to each row's position (0 = first).
8. On submit, each row is normalised to a join DTO: the related FK is set from the row, the parent-side fields and the
   UI-only keys (`relatedEntity`, `relatedEntityId`, `__childProgressId`) are dropped, and the join fields are kept
   (`normalizeManyToManyRelationshipField`, `src/utils/forms/normalizeFormSubmission.ts`).

## Non-Goals
- Creating a related entity directly from the editor (it happens inside the join-entry form's picker instead). The
  editor's never-reachable code for that was removed on 2026-10-06.
- Selecting related entities from a table inside the editor (removed in `c3b77a6`).

## Known Limitations
- With **inline child steps** (no linked join configuration) there is no way to add a row: **Create New Join Entry**
  needs a linked join configuration, and the picker table that used to add rows in this mode is gone. Existing rows
  can still be edited, reordered and removed. Either link a join configuration or restore an add path for this mode.
- Related-type resolution depends on join-entity metadata; with metadata missing, the editor can only show its
  warning.

## Acceptance Criteria
- Create New Join Entry adds a pending row and opens the join-entry form for it; completing that form fills the row.
- Edit Join Entry opens the join-entry form with the row's saved values.
- Removing and reordering rows is kept in the wizard's step data and in the saved draft, with or without an authored
  List field for the step.
- The editor warns when the related entity type cannot be resolved.

## History
- 2026-02-23 `c3b77a6` — replaced the related-entity picker table with the Create New Join Entry flow.
- 2026-10-06 — fieldless M2M steps keep their relationships; unreachable create-related-entity code removed; this
  spec rewritten.

## References (knk-web-app)
- Editor: `src/components/FormWizard/ManyToManyRelationshipEditor.tsx`
- Wizard integration (`handleOpenJoinEntry`, `handleJoinEntryComplete`): `src/components/FormWizard/FormWizard.tsx`
- Builder step settings: `src/components/FormConfigBuilder/StepEditor.tsx`
- Tests: `src/components/FormWizard/__tests__/ManyToManyRelationshipEditor*.test.tsx`,
  `FormWizard.m2mJoinPrefill.ui.test.tsx`, `FormWizard.siegeGatesJoin.ui.test.tsx`,
  `src/utils/forms/__tests__/manyToManyCarrierField.test.ts`
