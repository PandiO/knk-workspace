# Summary: What Was Updated

This document summarizes the changes made to the requirements and new files created.

---

## Files Created

### 1. `FieldValidationRule.cs`
**Location:** `Repository/knk-web-api-v2/Models/FormConfiguration/FieldValidationRule.cs`

**Purpose:** Entity model for field-level validation rules

**Key Properties:**
- `ValidationType`: "LocationInsideRegion", "RegionContainment", etc.
- `DependsOnFieldId`: FK to the field this rule depends on
- `ConfigJson`: Generic rule configuration (varies by type)
- `ErrorMessage` / `SuccessMessage`: User-facing messages with placeholder support
- `IsBlocking`: If true, validation failure prevents progression

---

### 2. `FieldValidationRuleDtos.cs`
**Location:** `Repository/knk-web-api-v2/Dtos/Forms/FieldValidationRuleDtos.cs`

**Contains:**
- `FieldValidationRuleDto`: Read DTO
- `CreateFieldValidationRuleDto`: Create DTO
- `UpdateFieldValidationRuleDto`: Update DTO
- `ValidateFieldDto`: Request DTO (validate field value)
- `ValidationResultDto`: Response DTO (validation result)
- `ValidationIssueDto`: Configuration health check result

---

### 3. `IMPLEMENTATION_ROADMAP.md`
**Location:** `Repository/knk-plugin-v2/spec/IMPLEMENTATION_ROADMAP.md`

**Purpose:** Clear separation of Workstream A (Hybrid Workflow) and Workstream B (Validation Framework)

**Contains:**
- What gets implemented in each workstream
- What does NOT get implemented (to avoid scope creep)
- Acceptance criteria for each phase
- Suggested sprint timeline
- Database migration notes
- Instruction examples for assigning work to Copilot
- Cross-workstream integration points
- Testing strategy

---

## Files Modified

### 1. `REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md`

**Added Sections:**
- Section 23: Conditional Validation Framework (full specification with DTOs, API contract, UI components, examples)
- Section 23.2 - 23.9: Detailed validation framework requirements

**Added References:**
- Section 0 (How to Use): Added workstream description and link to IMPLEMENTATION_ROADMAP.md
- Section 14, 20, 23: Added 🔄 workstream labels

**Key Changes:**
1. Complete validation framework section with:
   - Entity model specification
   - API contract and endpoints
   - DTO shapes with examples
   - Validation method registry (hardcoded for v1)
   - Frontend integration details
   - Updated Town v1 template with validation rule example
   - Breaking dependency detection logic
   - Implementation separation guidance

2. Updated Section 16 (Town v1 FormConfig Template):
   - Added validation rule configuration example
   - Showed how admin configures LocationId field with validation
   - Explained dependency on WgRegionId field

3. Clarified:
   - Admin's responsibility for field ordering (enforcement via UI warnings, not blocking)
   - System's flexibility to allow out-of-order field completion
   - Validation execution timing (real-time for game tasks, on-submit for web forms)
   - Dependency resolution from form context data
   - Error message placeholder support

---

### 2. `FormField.cs`

**Added Property:**
```csharp
public List<FieldValidationRule> ValidationRules { get; set; } = new();
```

**With Documentation:**
- Explains that validation rules execute on field value change
- Shows example of Location field with containment validation
- References the parent-child dependency model

---

## Key Design Decisions Implemented

Based on your answers to Q1-Q6:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Q1: Validation Level | Field-only for v1 | Simpler scope; step/entity added later if needed |
| Q2: Dependency Reference | FieldId with dropdown + validation | FieldName more semantic; FieldId acceptable with good feedback |
| Q3: Validation Methods | Hardcoded registry | Simpler for v1; new methods require code changes |
| Q4: Timing | Hybrid approach | Game tasks: real-time; web forms: on-submit |
| Q5: Dependency Resolution | Admin responsible for ordering | Freedom + warnings; system auto-validates once dependency filled |
| Q6: API Method Registry | Option A (switch statement) | Type-safe; extensible for v2 |

---

## How to Use These Outputs

### For Implementing Workstream A (Hybrid Workflow):

```
Use sections 14-20 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md
Reference: IMPLEMENTATION_ROADMAP.md → "Workstream A: Hybrid Create/Edit Workflow"

Example instruction to Copilot:
"Please implement Workstream A per section 20 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md.
Focus on WorkflowSession, WorldTask entities; WizardStepContainer, WorldBoundFieldRenderer components; 
and plugin task handlers. Do NOT implement FieldValidationRule or validation framework (Section 23)."
```

### For Implementing Workstream B (Validation Framework):

```
Use section 23 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md + created entity/DTO files
Reference: IMPLEMENTATION_ROADMAP.md → "Workstream B: Conditional Validation Framework"

Example instruction to Copilot:
"Please implement Workstream B per section 23 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md.
Create FieldValidationRule model, DTOs (see FieldValidationRuleDtos.cs), 
ValidationService with LocationInsideRegionValidator and RegionContainmentValidator,
API endpoints, and ValidationRuleBuilder UI component."
```

---

## Next Steps

1. **Review** the requirements document Section 23 and IMPLEMENTATION_ROADMAP.md
2. **Validate** that design decisions match your intent (Q1-Q6 answers)
3. **Assign** Workstream A to one team/sprint
4. **Assign** Workstream B to another team/sprint (can start after A completes or in parallel)
5. **Adjust** timeline based on team capacity
6. **Create** database migrations for both workstreams
7. **Integrate** the two workstreams once both are feature-complete

---

## Validation Checklist

- [ ] Section 23 covers all aspects of field-level validation
- [ ] FieldValidationRule entity model is clear and extensible
- [ ] DTOs are complete and match backend/frontend contract
- [ ] API endpoints clearly specified
- [ ] UI components (ValidationRuleBuilder, FieldRenderer updates) documented
- [ ] Examples (Town + Location validation) are concrete and understandable
- [ ] Workstreams A and B are clearly separated
- [ ] Integration points between workstreams are documented
- [ ] Dependency detection (Q2 feedback mechanism) is specified
- [ ] Admin responsibility for field ordering is clear (with system warnings)

---

**Status:** Requirements document and supporting materials are complete and ready for implementation.
