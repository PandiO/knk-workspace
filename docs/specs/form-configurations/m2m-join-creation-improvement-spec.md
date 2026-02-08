# Many-to-Many Join Entity Creation — Improvement Spec

## Overview
Enhance many-to-many editing to support on-the-fly creation of **join entity instances** (and optionally related entities) during form wizard flows, using the existing FormConfiguration model and builder.

## Baseline User Story
As an admin, I want to be able to configure a m2m relationship with a join entity in a FormConfiguration through the form configuration builder. I want to be able to configure or link a new or existing FormStep or FormConfiguration for the join entity. Next, as admin I want to be able to use this FormConfiguration and m2m config in the form wizard and related components to create a new instance of a m2m join entity during create/edit operations of new or existing entities containing this m2m relationship. For example: I want to be able to define new join entities (ItemBlueprintDefaultEnchantment) during filling out of the ItemBlueprint form.

## Goals
1. Enable join entity creation in the wizard without requiring pre-existing related entities beyond the selected related item.
2. Allow admins to configure join entity forms via existing FormConfiguration/Step mechanisms.
3. Preserve join entity field values through normalization and submission.
4. Maintain backward compatibility with existing many-to-many configurations.

## Non-Goals
- Replacing the existing selection flow for related entities.
- Changing backend join-entity persistence beyond what’s required for the payload.

## Proposed Functional Requirements
### Builder (FormConfigBuilder / StepEditor)
1. A many-to-many step must allow linking a **join entity form configuration** (optional) in addition to child steps.
2. Admins can choose one of:
   - Use child steps (inline join fields) **or**
   - Link an existing FormConfiguration (full join-entity form)
3. Builder must validate:
   - `joinEntityType` is set when `isManyToManyRelationship` is true.
   - At least one join-field definition exists (child steps or linked join config).
4. The builder should surface metadata hints (join entity fields) for guidance.

### Wizard (FormWizard / ManyToManyRelationshipEditor)
5. Users can add a relationship by selecting a related entity from the table (current behavior remains).
6. For each selected relationship, users can:
   - Edit join fields inline (child steps), or
   - Open a **join entity modal** (linked form configuration) to create/edit join fields.
7. The join-entity form data must persist within the relationship card state.
8. On submit, the payload must include `defaultEnchantments` (or the configured property name) with full join objects:
   - `enchantmentDefinitionId`
   - `level`
   - Additional join fields configured by the join form

## Data Contract / Payload Expectations
- For `ItemBlueprint.DefaultEnchantments`:
  ```
  defaultEnchantments: [
    { enchantmentDefinitionId: 3, level: 2 }
  ]
  ```
- Related entity selection should map to the correct FK on the join entity:
  - `relatedEntityId` → `enchantmentDefinitionId`

## Required Changes (Conceptual)
1. **Normalization** must detect many-to-many steps and preserve join-entity objects rather than collapsing to ID arrays.
2. **Join entity mapping** must map `relatedEntityId` into the correct FK name based on join entity metadata.
3. **Join entity modal** should be wired similarly to the existing child form modal but scoped to join-entity creation.
4. **Configuration model** should support an optional `subConfigurationId` or equivalent pointer for join entity forms.

## Suggested Enhancements
- Add a “Create new related entity” action in the selection table when none exists.
- Add a “Clone join entry” action for repeated configurations (e.g., same enchantment with different levels).
- Add validation rules at the join-entity level (e.g., `Level` within bounds).
- Show inline validation summary per relationship card.

## Open Questions
1. Should join entity modal be required, or only optional when no child steps exist?
2. Should the join entity configuration be limited to one form step or allow multi-step flows?
3. How should the related entity FK field be determined?
   - By metadata lookup?
   - By a new explicit config field?
4. Should “create new related entity” be allowed for all types or only for specific types (e.g., EnchantmentDefinition)?
5. Should join entity entries be saved as draft progress (child progress) like current child forms?

## Acceptance Criteria
- Admin can configure a many-to-many step with either inline join fields or a linked join configuration.
- Wizard allows creating join entities with fields like `Level` and includes them in submission payload.
- Submission payload matches backend DTO expectations for join entities.
- Existing many-to-many configurations continue to function without changes.

## References
- Many-to-many editor: [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)
- Form wizard: [Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx](Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx)
- Builder support for child steps: [Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx)
- Backend DTO expectation for join entities: [Repository/knk-web-api-v2/Dtos/ItemBlueprintDtos.cs](Repository/knk-web-api-v2/Dtos/ItemBlueprintDtos.cs)
