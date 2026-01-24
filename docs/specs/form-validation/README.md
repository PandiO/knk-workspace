# Form Validation - Inter-Field Dependencies Documentation

**Feature:** Cross-field validation dependencies for FormConfiguration system  
**Created:** January 18, 2026  
**Status:** Requirements Complete ✅

---

## Overview

This feature enables administrators to configure validation rules where one form field's value is used as a constraint or validation parameter for another field. This is critical for maintaining data integrity in scenarios like:

- **Spatial Containment:** Validate that a Location is inside a parent entity's WorldGuard region
- **Region Hierarchy:** Ensure child regions are fully contained within parent regions
- **Conditional Validation:** Apply validation rules based on other field values

---

## Documentation Files

### 📋 [SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md)
**Comprehensive requirements specification**

**Contents:**
- Part A: Business Requirements (scenarios, workflows, validation types)
- Part B: Technical Specifications - Backend (entity models, DTOs, services, controllers)
- Part C: Technical Specifications - Frontend (components, API client, UI integration)
- Part D: Implementation Questions & Design Decisions
- Part E: Success Criteria
- Part F: Future Enhancements

**Use this for:** Understanding the complete feature scope, business logic, and technical architecture

---

### 🗺️ [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md)
**Step-by-step implementation guide**

**Contents:**
- 8 phases with detailed tasks and effort estimates
- Code examples for each component
- Database migration instructions
- Testing strategies
- Total effort: 40-45 hours (~5-6 days)

**Phases:**
1. Backend Foundation (Data Model & Infrastructure)
2. Repository & Service Layer
3. Validation Method Implementations
4. API Controllers
5. Frontend - DTOs & API Client
6. Frontend - UI Components
7. Testing & Validation
8. Documentation & Deployment

**Use this for:** Implementing the feature step-by-step

---

### 📖 [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
**Fast lookup guide for developers and admins**

**Contents:**
- Design decisions summary table
- Entity model reference
- Validation types & ConfigJson schemas
- API endpoint reference
- Frontend integration examples
- Admin workflow instructions
- Troubleshooting guide
- Common patterns

**Use this for:** Quick lookups during development or configuration

---

## Quick Start

### For Developers (Backend)
1. Read [SPEC Part B](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md#part-b-technical-specifications---backend-knk-web-api-v2) for backend architecture
2. Follow [Implementation Roadmap Phases 1-4](IMPLEMENTATION_ROADMAP.md#phase-1-backend-foundation-data-model--infrastructure)
3. Reference [Quick Reference - API Endpoints](QUICK_REFERENCE.md#api-endpoints) for contract details

### For Developers (Frontend)
1. Read [SPEC Part C](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md#part-c-technical-specifications---frontend-knk-web-app) for frontend architecture
2. Follow [Implementation Roadmap Phases 5-6](IMPLEMENTATION_ROADMAP.md#phase-5-frontend---dtos--api-client)
3. Reference [Quick Reference - Frontend Integration](QUICK_REFERENCE.md#frontend-integration) for code examples

### For Admins
1. Read [SPEC Part A](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md#part-a-business-requirements) for feature overview
2. Follow [Quick Reference - Admin Workflow](QUICK_REFERENCE.md#admin-workflow-creating-validation-rules)
3. Use [Quick Reference - Common Patterns](QUICK_REFERENCE.md#common-patterns) for configuration examples

---

## Key Concepts

### Validation Rule
A configuration that validates a field's value based on another field's value.

**Example:** District's Location must be inside the Town's WorldGuard region
- **Validated Field:** District.LocationId
- **Dependency Field:** District.TownId
- **Validation Type:** LocationInsideRegion
- **Config:** Extract Town's WgRegionId, check if Location is inside

### Dependency Field Ordering
For validation to work, dependency fields **must** come before dependent fields in the form flow.

**System Behavior:**
- ✅ **Valid:** Town field (Step 1) → Location field (Step 2)
- ⚠️ **Warning:** Location field → Town field (both in same step, wrong order)
- ❌ **Error:** Dependency field deleted/missing

### Blocking vs Non-Blocking
- **Blocking (IsBlocking=true):** Validation failure prevents form submission
- **Non-Blocking (IsBlocking=false):** Validation failure shows warning but allows submission

---

## Validation Types (v1)

### 1. LocationInsideRegion
Validates that a Location's coordinates fall within a WorldGuard region.

**Use Case:** District's spawn location must be inside Town's region

**Config:**
```json
{
  "regionPropertyPath": "WgRegionId",
  "allowBoundary": false
}
```

---

### 2. RegionContainment
Validates that a child WorldGuard region is fully contained within a parent region.

**Use Case:** District's region must be inside Town's region

**Config:**
```json
{
  "parentRegionPath": "WgRegionId",
  "requireFullContainment": true
}
```

---

### 3. ConditionalRequired
Makes a field required only when another field meets a condition.

**Use Case:** Public structures require a public access point

**Config:**
```json
{
  "condition": {
    "operator": "equals",
    "value": true
  }
}
```

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Backend Entity Model** | ⬜ Not Started | FieldValidationRule entity |
| **Backend Repository** | ⬜ Not Started | CRUD + dependency analysis |
| **Backend Service** | ⬜ Not Started | Validation execution logic |
| **Validation Methods** | ⬜ Not Started | LocationInsideRegion, RegionContainment, ConditionalRequired |
| **API Controller** | ⬜ Not Started | REST endpoints |
| **Database Migration** | ⬜ Not Started | Add FieldValidationRules table |
| **Frontend DTOs** | ⬜ Not Started | TypeScript types |
| **Frontend API Client** | ⬜ Not Started | API wrapper |
| **ValidationRuleBuilder UI** | ⬜ Not Started | Admin configuration component |
| **FieldEditor Updates** | ⬜ Not Started | Show/manage validation rules |
| **FieldRenderer Updates** | ⬜ Not Started | Execute validations on change |
| **ConfigurationHealthPanel** | ⬜ Not Started | Display dependency issues |
| **Testing** | ⬜ Not Started | Unit, integration, E2E tests |
| **Documentation** | ✅ Complete | SPEC, Roadmap, Quick Reference |

---

## Dependencies & Prerequisites

### Required
- ✅ FormField entity (already exists)
- ✅ FormConfiguration system (already functional)
- ✅ FormConfigBuilder UI (already exists)

### Needed (Implementation)
- ⚠️ **WorldGuard Region API:** Integration for checking coordinate containment
  - Option 1: REST API from Minecraft plugin
  - Option 2: Database view with region boundaries
  - Option 3: Sync region data to API database
- ⚠️ **IRegionService:** Backend service for region operations

### Blockers
- WorldGuard integration approach needs to be decided (see [SPEC Part D.1](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md#d1-questions-for-user-input))

---

## Questions for User

Before implementation begins, the following questions need answers:

### 1. WorldGuard Region API Integration
**Question:** How should the backend API query WorldGuard region boundaries and check coordinate containment?

**Options:**
- A) Create REST API endpoints in Minecraft plugin (e.g., `GET /api/regions/{id}/contains?x={x}&z={z}`)
- B) Sync region boundary data to API database via scheduled task
- C) Query WorldEdit/WorldGuard directly from API (requires plugin integration)

**Recommendation:** Option A (REST API from plugin) - Clean separation of concerns

---

### 2. Validation Method Extensibility
**Question:** Should v1 include UI for admins to register custom validation methods?

**Options:**
- A) Hardcode 3 validation types (LocationInsideRegion, RegionContainment, ConditionalRequired)
- B) Add plugin architecture for custom validators in v1

**Recommendation:** Option A (hardcoded for v1) - Simpler, faster implementation

---

### 3. Circular Dependency Handling
**Question:** Should the system prevent Field A → Field B → Field A circular dependencies?

**Options:**
- A) Block at creation time with error message
- B) Allow but warn admin in health check
- C) Allow without restriction

**Recommendation:** Option A (block at creation) - Prevents runtime issues

---

### 4. Validation Timing
**Question:** When should validation execute in the frontend?

**Options:**
- A) **Eager:** On every field change (300ms debounce)
- B) **Lazy:** Only when field loses focus or on "Next" button
- C) **Hybrid:** Eager for some validation types, lazy for others

**Recommendation:** Option A (eager with debounce) - Best UX, immediate feedback

---

### 5. Validation Rule Versioning
**Question:** If admin updates a FieldValidationRule, should all FormConfigurations inherit the update?

**Options:**
- A) Auto-update all configurations (shared rule)
- B) Copy-on-reuse (each configuration gets independent copy)

**Recommendation:** Option B (copy-on-reuse) - Matches FormStep/FormField pattern, maximum flexibility

---

## Next Steps

1. **User:** Answer questions above
2. **Developer:** Start Phase 1 (Backend Foundation) from [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md)
3. **Team:** Review SPEC for any additional questions
4. **QA:** Prepare test scenarios from [SPEC Part E](SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md#e3-testing-scenarios)

---

## Related Documentation

- [FormConfiguration Entity](../../../Repository/knk-web-api-v2/Models/FormConfiguration.cs)
- [FormField Entity](../../../Repository/knk-web-api-v2/Models/FormField.cs)
- [FormConfigBuilder Component](../../../Repository/knk-web-app/src/components/FormConfigBuilder/FormConfigBuilder.tsx)
- [Hybrid Workflow Requirements](../towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md) (Section 23 - original validation framework proposal)

---

## Contact

**Questions or Feedback?**  
Open an issue or contact the development team.

---

**Last Updated:** January 18, 2026
