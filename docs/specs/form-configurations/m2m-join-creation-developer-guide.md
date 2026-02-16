# Many-to-Many Join Entity Creation — Developer Guide

## Purpose
This guide explains how to configure join-entity creation for many-to-many steps, how the wizard behaves, and how payloads are normalized.

## Configuration (FormConfigBuilder)
1. Create or open the parent FormConfiguration.
2. Add a step with **Is many-to-many relationship** enabled.
3. Set **Join entity type** (required for many-to-many steps).
4. Choose one join-field source:
   - **Linked join FormConfiguration** (preferred): set the join configuration on the step.
   - **Child steps** (fallback): define inline child steps for join fields.

### Validation rules
- `joinEntityType` must be set when `isManyToManyRelationship` is true.
- At least one join-field source must exist: **linked join config** or **child steps**.

## Wizard Behavior
- Users select related entities as usual.
- For each selection, users can edit join fields:
  - Inline (child steps), or
  - In the **Join Entity** modal when a linked FormConfiguration is present.
- Join entries are stored as child progress to support draft saves and resume.

## Payload Normalization
- Many-to-many steps preserve **join objects** (not only ID arrays).
- The selected related entity ID is mapped to the join entity FK using **join-entity metadata**.
- UI-only fields are stripped before submission (e.g., `relatedEntity`, `relatedEntityId`, `__childProgressId`).
- If metadata mapping fails, submission is blocked with a clear error message.

### Example payload shape
```
{
  "defaultEnchantments": [
    {
      "enchantmentDefinitionId": 3,
      "level": 2
    }
  ]
}
```

## Troubleshooting
- **Missing metadata**: Ensure metadata for the join entity is available and includes the related FK field.
- **No join fields**: Verify the step has either a linked join config or child steps.
- **Draft lost join data**: Confirm join entries are saved as child progress and that the parent progress ID is preserved.

## Related Docs
- Improvement spec: [docs/specs/form-configurations/m2m-join-creation-improvement-spec.md](docs/specs/form-configurations/m2m-join-creation-improvement-spec.md)
- Roadmap: [docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md](docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md)
