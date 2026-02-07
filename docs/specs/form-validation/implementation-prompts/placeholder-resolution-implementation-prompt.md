# Implementation Prompt: Placeholder Resolution Across Validation + WorldTasks

## Goal
Implement a robust placeholder-resolution system for form validation messages that supports:
- Direct current-entity fields (Layer 0): `{Name}`
- Single navigation (Layer 1): `{Town.Name}`
- Multi-navigation (Layer 2): `{District.Town.Name}`
- Aggregates (Layer 3): `{Town.Districts.Count}`
- Computed, local-only placeholders (e.g., `{coordinates}` in Minecraft)

This must work consistently across:
- Web app validation (FormWizard + FieldRenderer)
- WorldTask creation (web app)
- WorldTask validation in Minecraft plugin
- Backend re-validation on task completion

## Context
- Placeholder names for Layer 0 match `FormField.fieldName` in the FormConfiguration.
- Validation rules are configured by admins in `FieldValidationRules`.
- Messages include placeholders like `{Name}`, `{Town.Name}`, `{District.Town.Name}`.
- WorldTasks must include resolved placeholder values in `InputJson` so the plugin can interpolate without extra API calls.

## Summary of Required Behavior
1. **Web App (FormWizard)**
   - Extract Layer 0 placeholders from `allStepsData` by scanning `FormConfiguration.steps[].fields[].fieldName`.
   - Resolve navigation placeholders by calling a backend placeholder-resolution endpoint.
   - Create WorldTask with `validationContext.currentEntityPlaceholders` set to the merged resolved values.
   - Validation feedback in UI should interpolate message templates using `placeholders` returned from backend.

2. **Backend (API)**
   - Provide a placeholder-resolution endpoint that accepts:
     - `currentEntityType`
     - `currentEntityId` (nullable)
     - `currentEntityPlaceholders` (Layer 0)
     - `placeholderPaths` (from error/success messages)
   - Resolve Layer 1/2/3 placeholders using EF Core includes or dynamic navigation.
   - Return a map of resolved placeholder values.
   - Validation endpoints should return `ValidationResultDto` containing:
     - `message` (template)
     - `placeholders` (resolved values)
     - `isValid`, `isBlocking`

3. **Minecraft Plugin**
   - Read `validationContext.currentEntityPlaceholders` from `InputJson`.
   - Perform string replacement for any placeholders present in that map.
   - Compute local-only placeholders like `{coordinates}` in plugin during validation.

4. **WorldTask Re-Validation (Backend)**
   - On completion, re-validate using same rule and placeholder-resolution logic for defense-in-depth.

## Implementation Tasks

### Task A — Backend: Placeholder Resolution API
- Add endpoint: `POST /api/field-validations/resolve-placeholders`
- Request model should include:
  - `currentEntityType` (string)
  - `currentEntityId` (int?)
  - `placeholderPaths` (string[])
  - `currentEntityPlaceholders` (dictionary)
- Response should include:
  - `resolvedPlaceholders` (dictionary)
  - `unresolvedPlaceholders` (string[])
  - `resolutionErrors` (string[])

**Resolution logic:**
- Layer 0: already provided from request.
- Layer 1 (single navigation): resolve from current entity nav property.
- Layer 2 (multi navigation): resolve via dynamic include chain.
- Layer 3 (aggregates): support `.Count` at minimum.

### Task B — Backend: Validation Result DTO
- Ensure `ValidationResultDto` includes:
  - `message` (template)
  - `placeholders` (dictionary)
  - `isValid`, `isBlocking`

### Task C — Web App: Placeholder Extraction
- Add helper `buildPlaceholderContext(config, allStepsData)` to extract Layer 0 placeholders.
- Parse placeholders from rule messages (regex `{...}`) to build `placeholderPaths`.
- Call placeholder-resolution endpoint before creating WorldTask.
- Merge placeholder maps and send in `validationContext.currentEntityPlaceholders`.

### Task D — Web App: Validation Feedback
- Continue using existing `interpolatePlaceholders(message, placeholders)` for UI.

### Task E — Plugin: Interpolation + Local Placeholders
- Update validation logic to:
  - Replace any `{key}` where key exists in `currentEntityPlaceholders`.
  - Replace local-only placeholders like `{coordinates}`.

## Acceptance Criteria
- `{Name}` resolves from current form data for create flows.
- `{Town.Name}` resolves in both web validation and world-task validation.
- `{District.Town.Name}` resolves for entities with multi-level navigation.
- Plugin can display final message without additional API calls.
- Validation results remain consistent between web app and plugin.

## Notes
- Use existing patterns and utilities. Do not introduce new architecture layers.
- Keep placeholder parsing minimal and predictable (regex on `{...}`).
- For collections, only implement `.Count` initially; document unsupported aggregates.
