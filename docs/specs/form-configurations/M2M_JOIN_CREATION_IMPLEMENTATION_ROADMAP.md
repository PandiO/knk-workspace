# Many-to-Many Join Entity Creation - Implementation Roadmap

**Status**: Planning  
**Created**: February 8, 2026

This document provides a step-by-step implementation plan organized by component and priority, aligned with the improvement spec.

---

## Phase 1: Requirements & Contracts (Foundation)

### Priority: CRITICAL - Blocks all other work

#### 1.1 Confirm FK Mapping Rule (Metadata-based)
- [ ] Use join-entity metadata to locate the related entity field that is NOT the parent entity.
- [ ] Map selected related entity ID into `{RelatedEntityType}Id` field on join object.
- [ ] Define fallback behavior if metadata is missing (block submission with error).

**Files**: 
- [Repository/knk-web-app/src/apiClients/metadataClient.ts](Repository/knk-web-app/src/apiClients/metadataClient.ts) (usage only)
- [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)

**Effort**: 30 minutes

---

#### 1.2 Define Join-Entity Form Source of Truth
- [ ] Allow **either** child steps **or** linked FormConfiguration.
- [ ] Prefer linked FormConfiguration when provided.
- [ ] Document how child steps are used as fallback.

**Files**:
- [Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx)
- [docs/specs/form-configurations/m2m-join-creation-improvement-spec.md](docs/specs/form-configurations/m2m-join-creation-improvement-spec.md)

**Effort**: 30 minutes

---

## Phase 2: Form Configuration Enhancements (Builder)

### Priority: HIGH

#### 2.1 Extend Step Configuration for Join Entity Form
- [x] Add UI support in the builder to select or link a join-entity FormConfiguration.
- [x] Store the linked configuration ID on the many-to-many step (e.g., `subConfigurationId`).
- [x] Ensure linked config is only available for join entity type.

**Files**:
- [Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx)
- [Repository/knk-web-app/src/types/dtos/forms/FormModels.ts](Repository/knk-web-app/src/types/dtos/forms/FormModels.ts)

**Effort**: 2-3 hours

---

#### 2.2 Validation for Many-to-Many Steps
- [x] Validate `joinEntityType` is set when `isManyToManyRelationship` is true.
- [x] Validate presence of join field definition:
  - Either child steps exist, **or** linked join config is set.
- [x] Surface validation errors in UI.

**Files**:
- [Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/StepEditor.tsx)
- [Repository/knk-web-app/src/components/FormConfigBuilder/ConfigurationHealthPanel.tsx](Repository/knk-web-app/src/components/FormConfigBuilder/ConfigurationHealthPanel.tsx)

**Effort**: 1-2 hours

---

## Phase 3: Wizard UX & Join Entity Creation

### Priority: HIGH

#### 3.1 Join Entity Modal Workflow
- [ ] Add a "Create Join Entry" action near the selection table for many-to-many steps.
- [ ] When invoked, launch a join-entity modal using linked FormConfiguration.
- [ ] Save join entity data into relationship card state.
- [ ] Support multi-step join forms.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)
- [Repository/knk-web-app/src/components/FormWizard/ChildFormModal.tsx](Repository/knk-web-app/src/components/FormWizard/ChildFormModal.tsx)
- [Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx](Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx)

**Effort**: 4-6 hours

---

#### 3.2 Persist Join Entries as Child Progress
- [ ] Store join entity entries as child progress (using parent progress ID).
- [ ] Ensure join data survives refresh/draft save.
- [ ] On resume, rehydrate join entries into relationship cards.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx](Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx)
- [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)

**Effort**: 3-4 hours

---

## Phase 4: Submission & Payload Normalization

### Priority: HIGH

#### 4.1 Preserve Join Entity Objects in Submission Payload
- [ ] Detect many-to-many steps and keep join objects rather than collapsing to ID arrays.
- [ ] Map selected related entity to the correct FK field using metadata.
- [ ] Include join fields (e.g., `Level`) in payload.

**Files**:
- [Repository/knk-web-app/src/utils/forms/normalizeFormSubmission.ts](Repository/knk-web-app/src/utils/forms/normalizeFormSubmission.ts)

**Effort**: 2-3 hours

---

#### 4.2 End-to-End Payload Validation
- [ ] Ensure payload matches backend DTO expectations (`defaultEnchantments` array).
- [ ] Block form completion with clear error if join mapping fails.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx](Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx)

**Effort**: 1-2 hours

---

## Phase 5: Validation & Error UX

### Priority: MEDIUM

#### 5.1 Join-Entity Validation Rules
- [ ] Apply existing validation rules to join-entity fields.
- [ ] Display inline validation errors per relationship card.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)
- [Repository/knk-web-app/src/components/FormWizard/FieldRenderers.tsx](Repository/knk-web-app/src/components/FormWizard/FieldRenderers.tsx)

**Effort**: 2-3 hours

---

#### 5.2 Conflict Handling
- [ ] If related entity is missing/deleted, block completion with clear message.
- [ ] Provide guidance to re-select or reconfigure the relationship.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx](Repository/knk-web-app/src/components/FormWizard/ManyToManyRelationshipEditor.tsx)

**Effort**: 1-2 hours

---

## Phase 6: Testing

### Priority: HIGH

#### 6.1 Unit Tests (Form Normalization)
- [ ] Many-to-many payload retains join objects.
- [ ] Mapping uses metadata and resolves correct FK.
- [ ] Missing metadata produces blocked submission.

**Files**:
- [Repository/knk-web-app/src/utils/forms/__tests__/normalizeFormSubmission.test.ts](Repository/knk-web-app/src/utils/forms/__tests__/normalizeFormSubmission.test.ts)

**Effort**: 2-3 hours

---

#### 6.2 UI Integration Tests (Wizard)
- [ ] Create relationship + join fields saved.
- [ ] Join entity modal flow with multi-step configs.
- [ ] Draft resume restores join entries.

**Files**:
- [Repository/knk-web-app/src/components/FormWizard/__tests__](Repository/knk-web-app/src/components/FormWizard/__tests__)

**Effort**: 3-5 hours

---

## Phase 7: Documentation & Rollout

### Priority: MEDIUM

#### 7.1 Documentation
- [ ] Update improvement spec with final decisions.
- [ ] Add a short developer guide for configuring join-entity forms.

**Files**:
- [docs/specs/form-configurations/m2m-join-creation-improvement-spec.md](docs/specs/form-configurations/m2m-join-creation-improvement-spec.md)
- [docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md](docs/specs/form-configurations/M2M_JOIN_CREATION_IMPLEMENTATION_ROADMAP.md)

**Effort**: 1-2 hours

---

## Implementation Priority Matrix

| Phase | Component | Duration | Risk | Blocker | Status |
|------|-----------|----------|------|---------|--------|
| 1 | Requirements & Contracts | 1h | Low | None | Not Started |
| 2 | Builder Enhancements | 3-5h | Med | Phase 1 | Not Started |
| 3 | Wizard UX + Join Creation | 7-10h | Med | Phase 2 | Not Started |
| 4 | Payload Normalization | 3-5h | Med | Phase 3 | Not Started |
| 5 | Validation + Error UX | 3-5h | Med | Phase 3 | Not Started |
| 6 | Testing | 5-8h | Med | Phase 4-5 | Not Started |
| 7 | Documentation | 1-2h | Low | Phase 6 | Not Started |

**Total Estimated Effort**: ~23-36 hours

---

## ✅ DESIGN DECISIONS CONFIRMED

| Decision | Confirmed Choice |
|---------|------------------|
| Scope of on-the-fly creation | Join entities only |
| Join form source of truth | Prefer linked FormConfiguration; child steps fallback |
| Multi-step join forms | Allowed |
| FK mapping rule | Metadata-based mapping |
| Validation behavior | Use existing validation rules |
| Draft persistence | Save join entries as child progress |
| Conflict handling | Block completion; instruct reconfiguration |
| Permissions/RBAC | Admin-only in future |
| Auditing/traceability | Use user ID/auth |
| Error UX | Implement with existing patterns |

---

## Getting Started Checklist

- [ ] Confirm metadata contains join-entity related field names
- [ ] Decide storage field for linked join config (e.g., `subConfigurationId` on step)
- [ ] Add UX entry point for join entity creation in wizard
- [ ] Implement normalization preserving join payload
- [ ] Add tests for join payload and draft persistence

