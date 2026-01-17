# Implementation Roadmap: Hybrid Workflow vs Validation Framework

**Document:** Clarifies how to implement these two workstreams independently.

---

## Workstream A: Hybrid Create/Edit Workflow (Phase 1)

**Focus:** Multi-step form progression with world-bound tasks

### What Gets Implemented

**Backend (Section 20 of requirements):**
1. Entities: `WorkflowSession`, `StepProgress`, `WorldTask`, `Location`, `RegionContainmentRule`
2. DTOs: `WorkflowSessionDto`, `StepProgressDto`, `WorldTaskDto`, `CreateWorldTaskDto`, `ClaimTaskDto`, `CompleteTaskDto`, `FailTaskDto`
3. Repositories & Services: `IWorkflowService`, `IWorldTaskService`
4. Controllers: `WorkflowsController` (POST/PUT/GET /api/workflows/*), `WorldTasksController` (POST/GET /api/worldtasks/*)
5. AutoMapper profiles for all DTOs
6. Audit logging for workflow events

**Frontend (Section 20 of requirements):**
1. API client methods for workflow CRUD and task polling
2. `WizardStepContainer` component (step navigation, progress indicator)
3. `WorldBoundFieldRenderer` component (task trigger, status polling, output display)
4. `WorkflowStatusPanel` component (diagnostics)
5. Town Create Wizard using 3 steps (General, Rules, World Data)
6. Task polling hook (`useTaskStatus`)

**Plugin:**
1. `WorldTask` DTO classes
2. `ApiClient` methods for task operations
3. `IWorldTaskHandler` interface + handler registry
4. `CaptureLocationHandler` and `DefineRegionHandler` implementations
5. Commands: `/knk tasks list`, `/knk task claim <code>`, `/knk task status <id>`
6. Async executor pattern for API calls

### What Does NOT Get Implemented
- ❌ FieldValidationRule entities or validation framework
- ❌ ValidationRuleBuilder UI
- ❌ Validation API endpoints (/api/forms/validationrules/*)
- ❌ Cross-field validation logic
- ❌ Configuration health checking

### Acceptance Criteria (Phase 1)
- [ ] Admin can create Town in Web App with 3 steps
- [ ] Step 1 & 2 fields save to Draft entity
- [ ] Step 3 triggers WorldTask for region definition
- [ ] Plugin can claim task, complete DefineRegion, location capture
- [ ] API finalizes Town (state → Active)
- [ ] No validation rules needed (basic workflow only)

---

## Workstream B: Conditional Validation Framework (Phase 2)

**Focus:** Cross-field, cross-entity validation rules

### What Gets Implemented

**Backend (Section 23 of requirements):**
1. Entity: `FieldValidationRule`
2. DTOs: `FieldValidationRuleDto`, `CreateFieldValidationRuleDto`, `UpdateFieldValidationRuleDto`, `ValidateFieldDto`, `ValidationResultDto`, `ValidationIssueDto`
3. Repositories & Services: `IValidationService`, `IValidationMethod` interface, validator implementations (`LocationInsideRegionValidator`, `RegionContainmentValidator`)
4. Controllers: `FieldValidationRuleController` (CRUD + validate endpoint)
5. Validation dispatch logic
6. Configuration health check service

**Frontend (Section 23 of requirements):**
1. `ValidationRuleBuilder.tsx` component
2. Updates to `FieldEditor.tsx` (add "Validation Rules" section)
3. Updates to `FieldRenderer.tsx` (execute validations on field change)
4. Validation status display (success/error/warning messages)
5. Dependency broken detection warnings
6. Configuration health panel UI

**Plugin:**
- No changes needed (validation happens on API/Web App side)

### What Does NOT Get Implemented
- ❌ Step-level or entity-level validations (field-level only for Phase 1)
- ❌ New validation methods beyond "LocationInsideRegion" and "RegionContainment"
- ❌ Real-time validation result caching (API called every field change)

### Prerequisites for Workstream B
- ✅ FormField model (already exists)
- ✅ FormConfiguration UI (already exists)
- ✅ API structure (from Workstream A or existing FormConfig endpoints)

### Acceptance Criteria (Phase 2)
- [ ] Admin can add validation rule to LocationId field in FormConfigBuilder
- [ ] Rule configured to depend on WgRegionId field
- [ ] Rule type: "LocationInsideRegion"
- [ ] On location selection, validation executes
- [ ] If dependency not filled, warning shown
- [ ] If dependency filled and location invalid, error shown and step blocked (if IsBlocking = true)
- [ ] Configuration health check detects broken dependencies

---

## Implementation Timeline Suggestion

### Sprint 1 (Workstream A - 2-3 weeks)
**Backend (1 week):**
- Day 1-2: Create entities (WorkflowSession, StepProgress, WorldTask, Location)
- Day 3: Create DTOs and AutoMapper profiles
- Day 4: Implement repositories and services
- Day 5: Implement controllers, test via Swagger

**Frontend (1 week):**
- Day 1-2: Generate TypeScript types from Swagger
- Day 3-4: Implement WizardStepContainer, WorldBoundFieldRenderer, WorkflowStatusPanel
- Day 5: Implement Town Create Wizard, test end-to-end with mock API

**Plugin (1 week):**
- Day 1-2: DTO classes, ApiClient methods
- Day 3-4: Handlers (CaptureLocationHandler, DefineRegionHandler)
- Day 5: Commands, test with dev server

### Sprint 2 (Workstream B - 1-2 weeks)
**Backend (3 days):**
- Day 1: FieldValidationRule entity, DTOs
- Day 2: ValidationService, validators (LocationInsideRegion, RegionContainment)
- Day 3: Controllers, test via Swagger

**Frontend (2 days):**
- Day 1: ValidationRuleBuilder, FieldEditor updates
- Day 2: FieldRenderer integration, Configuration health panel

---

## Database Migration Notes

### Workstream A Migrations
```sql
-- WorkflowSession table
-- StepProgress table
-- WorldTask table
-- Location table
-- RegionContainmentRule table
-- Add FK: Town.LocationId → Location.Id (optional, depends on design)
```

### Workstream B Migrations
```sql
-- FieldValidationRule table
-- Add FK: FieldValidationRule.FormFieldId → FormField.Id
-- Add FK: FieldValidationRule.DependsOnFieldId → FormField.Id
```

**Key Point:** No migration dependency between workstreams. They can be added independently.

---

## Instruction Examples for Copilot

### For Workstream A:
```
Please implement Workstream A: Hybrid Create/Edit Workflow per section 20 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md.
Focus on:
1. Backend: WorkflowSession, StepProgress, WorldTask entities and services
2. Frontend: WizardStepContainer, WorldBoundFieldRenderer, Town Create Wizard
3. Plugin: Task handlers and commands
Do NOT implement validation framework yet (Section 23).
```

### For Workstream B:
```
Please implement Workstream B: Conditional Validation Framework per section 23 of REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md.
Prerequisites: Workstream A completed or FormField model already exists.
Focus on:
1. Backend: FieldValidationRule entity, validators, API endpoints
2. Frontend: ValidationRuleBuilder, FieldEditor/FieldRenderer integration
3. Configuration health check
```

---

## Cross-Workstream Integration Points

**Where they meet:**

1. **Step Completion Check (Frontend):**
   - Workstream A: Check all fields filled before proceeding
   - Workstream B: Also check all field validations passed before proceeding
   - Integration: In `WizardStepContainer`, before `onNext()`, execute validation checks

2. **Form Context Data:**
   - Workstream A: Collects form data per step (for finalization)
   - Workstream B: Uses form context for dependency resolution
   - Integration: Pass `formContextData` from Workstream A to validation methods

3. **Field Update Handler (Frontend):**
   - Workstream A: `handleFieldChange()` updates form state
   - Workstream B: Same handler also triggers validation execution
   - Integration: `handleFieldChange()` calls both state update and validation async

4. **API Endpoints:**
   - Workstream A: POST /api/workflows/*/complete, /api/worldtasks/*/complete
   - Workstream B: POST /api/forms/validationrules/validate
   - Integration: Independent endpoints, no conflict

---

## Testing Strategy

### Workstream A Tests
- Unit: Workflow service logic, task claim/complete idempotency
- Integration: Create workflow → update step → create task → claim → complete → finalize
- E2E: Admin creates Town in Web App → claims task in-game → finalizes → Town is Active

### Workstream B Tests
- Unit: Validators (LocationInsideRegionValidator, RegionContainmentValidator)
- Integration: Configure rule → fill dependency field → fill target field → validation executes
- E2E: Admin configures validation rule in FormConfigBuilder → fills form → validation blocks/allows progression

### No Conflict Testing
- Workstream A + B: Admin creates Town with validation rules configured
- Step 1-2: Web form (no validation needed)
- Step 3: WorldBoundField with validation
- On location selection: validation executes (depends on WgRegionId) → shows result
- If valid: allow next step; if invalid and IsBlocking=true: block

---

## Known Unknowns (Clarification Needed)

**For Workstream A:**
- [ ] How to handle Location creation from Web Form vs Game Task?
- [ ] Should Location be globally reusable or entity-scoped?
- [ ] How to handle edit workflow: create new tasks or reuse existing?

**For Workstream B:**
- [ ] Should validation run synchronously or asynchronously?
- [ ] How to handle validation API timeouts (show warning)?
- [ ] Should failed validations be persisted in audit log?
