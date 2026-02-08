# Many-to-Many Relationship Editor (Current) — Requirements & Specs

## Overview
Defines current behavior for many-to-many relationship editing inside the form wizard based on the existing implementation.

## Scope
- Applies to the Many-to-Many Relationship Editor used by the form wizard.
- Uses join-entity metadata to resolve the related entity type.
- Uses child steps to render join-entity extra fields.

## User Story
As an admin, I can configure a form step to represent a many-to-many relationship so end users can select related entities and set join-entity fields (e.g., `Level`).

## Functional Requirements
1. A form step can be marked as many-to-many via `isManyToManyRelationship = true`.
2. The step must specify `joinEntityType` and `relatedEntityPropertyName`.
3. The UI must resolve the related entity type by loading join entity metadata and selecting the related entity that is not the parent entity.
4. Users can select related entities from a paged table.
5. Upon selection, a join entity instance is added to the form state with:
   - `relatedEntityId` set to the selected entity ID.
   - `relatedEntity` object stored for display.
   - Default join fields applied from child step defaults.
6. Users can remove a selected relationship.
7. Users can edit join-entity fields defined in `childFormSteps` (e.g., `Level`) in-place.

## Non-Goals
- Creating new related entities from the many-to-many editor.
- Creating new join entities without selecting a related entity first.
- Persisting join-entity values outside of the standard form submission pipeline.

## Configuration Contract
### FormConfiguration
- `steps[].isManyToManyRelationship`: true
- `steps[].relatedEntityPropertyName`: name of collection property on parent entity (e.g., `DefaultEnchantments`)
- `steps[].joinEntityType`: join entity type name (e.g., `ItemBlueprintDefaultEnchantment`)
- `steps[].childFormSteps`: list of child steps for join entity fields

### Child Steps
- `childFormSteps[].fields` define join-entity fields, such as:
  - `Level` (Integer)

## UI Behavior
- When the step is marked as many-to-many:
  - The wizard renders a selection table for the related entity.
  - Selected entities render as cards with editable join-entity fields.
- If `joinEntityType` or resolved related entity type is missing, the UI shows a configuration warning.

## Data Flow (Current)
1. Wizard renders `ManyToManyRelationshipEditor` for the step.
2. Editor loads join entity metadata and resolves related entity type.
3. Selection table loads related entities via `PagedEntityTable`.
4. On selection, editor creates join entities in local state.
5. On submit, form data is normalized by the existing form submission normalization.

## Known Limitations
- The normalization step currently collapses list relationships into ID arrays, which may drop join-entity fields for many-to-many payloads.
- The editor relies on join-entity metadata to resolve related entity type; missing metadata causes an empty table.

## Acceptance Criteria
- Selecting related entities displays them as cards with join-entity fields.
- Editing join fields updates local form state.
- Removing a relationship removes its card.
- The editor shows a warning when the related entity type cannot be resolved.

## References
- Many-to-many editor implementation: [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)
- Form wizard integration: [Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx](Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx)
- Form builder child-step support: [Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx)
