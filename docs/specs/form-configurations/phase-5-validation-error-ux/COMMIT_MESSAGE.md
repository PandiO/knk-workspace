# Phase 5: Validation & Error UX - Git Commit Message

**Date**: February 16, 2026  
**Feature**: m2m-join-creation  
**Phase**: 5 - Validation & Error UX

---

## Consolidated Single Commit

All Phase 5 changes should be committed atomically as one commit.

### Subject Line (50 characters)

```
feat(form): implement m2m join validation & conflict detection
```

### Full Description

```
Implement Phase 5 of many-to-many join creation: comprehensive validation
and error handling for join entity fields.

This phase adds real-time validation for join entity fields within
many-to-many relationships, including missing entity detection and clear
user guidance for error resolution.

VALIDATION RULES (Phase 5.1)
- Apply existing validation rules to join entity fields
- Display inline validation errors per field and per card
- Integrate with FormWizard validation pipeline
- Support both required field and async rule-based validation

Changes in ManyToManyRelationshipEditor:
- Add validation props: validationRules, validationResults, onValidateField
- Implement relationshipErrors state for tracking field errors per card
- Create validateJoinEntityField() to validate individual join fields
- Enhance renderJoinEntityFields() to display inline validation errors
- Add card-level error summary banner for validation issues
- Implement findFieldInChildSteps() helper for metadata resolution

CONFLICT HANDLING (Phase 5.2)
- Detect missing or deleted related entities in relationships
- Display warning banners with clear, actionable guidance
- Implement dynamic card border coloring for visual feedback:
  * Red (border-red-300) for missing entities
  * Yellow (border-yellow-300) for field validation errors
  * Gray (border-gray-200) for valid cards

Changes in ManyToManyRelationshipEditor:
- Add missingEntityWarnings state to track entity conflicts per card
- Create useEffect to validate all relationships when value changes
- Detect missing relatedEntity objects (deleted entities)
- Detect missing relatedEntityId values (corrupted data)
- Display warning banner with AlertTriangle icon and guidance

FORM WIZARD INTEGRATION
- Create handleValidateJoinEntityField() async handler in FormWizard
- Wire validation props to ManyToManyRelationshipEditor
- Enable join entity fields to use existing validation infrastructure
- Support form context and dependent field references in rules

Files Modified:
- Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx
- Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx
- docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md

Related: docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md
See: Phase 5 - Validation & Error UX
```

---

## How to Apply

### Method 1: Using Git Commit with Message

```bash
git commit -m "feat(form): implement m2m join validation & conflict detection" \
  -m "Implement Phase 5 of many-to-many join creation: comprehensive validation
and error handling for join entity fields.

This phase adds real-time validation for join entity fields within
many-to-many relationships, including missing entity detection and clear
user guidance for error resolution.

VALIDATION RULES (Phase 5.1)
- Apply existing validation rules to join entity fields
- Display inline validation errors per field and per card
- Integrate with FormWizard validation pipeline
- Support both required field and async rule-based validation

Changes in ManyToManyRelationshipEditor:
- Add validation props: validationRules, validationResults, onValidateField
- Implement relationshipErrors state for tracking field errors per card
- Create validateJoinEntityField() to validate individual join fields
- Enhance renderJoinEntityFields() to display inline validation errors
- Add card-level error summary banner for validation issues
- Implement findFieldInChildSteps() helper for metadata resolution

CONFLICT HANDLING (Phase 5.2)
- Detect missing or deleted related entities in relationships
- Display warning banners with clear, actionable guidance
- Implement dynamic card border coloring for visual feedback:
  * Red (border-red-300) for missing entities
  * Yellow (border-yellow-300) for field validation errors
  * Gray (border-gray-200) for valid cards

Changes in ManyToManyRelationshipEditor:
- Add missingEntityWarnings state to track entity conflicts per card
- Create useEffect to validate all relationships when value changes
- Detect missing relatedEntity objects (deleted entities)
- Detect missing relatedEntityId values (corrupted data)
- Display warning banner with AlertTriangle icon and guidance

FORM WIZARD INTEGRATION
- Create handleValidateJoinEntityField() async handler in FormWizard
- Wire validation props to ManyToManyRelationshipEditor
- Enable join entity fields to use existing validation infrastructure
- Support form context and dependent field references in rules

Files Modified:
- Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx
- Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx
- docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md

Related: docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md
See: Phase 5 - Validation & Error UX"
```

### Method 2: Using Git Editor

```bash
git commit
# Then paste the full message (subject + description) into the editor
```

---

## Verify Commit

After committing, verify with:

```bash
git log --oneline -1
# Should show: feat(form): implement m2m join validation & conflict detection

git show
# Verify all changes are included
```

---

## Commit Statistics

| Metric | Value |
|--------|-------|
| Repository | knk-web-app |
| Type | feat |
| Scope | form |
| Files Changed | 3 |
| Lines Added/Modified | ~240 |
| Breaking Changes | None |

---

## Convention Compliance

✅ Follows [docs/GIT_COMMIT_CONVENTIONS.md](../../GIT_COMMIT_CONVENTIONS.md):
- Type: `feat` for new feature
- Scope: `form` for form wizard
- Subject: Lowercase, imperative, no period, <50 chars
- Body: Wrapped at 72 chars, explains what and why
- Footer: References implementation roadmap

