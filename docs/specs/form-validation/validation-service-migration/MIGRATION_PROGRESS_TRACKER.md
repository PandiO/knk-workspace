# Migration Progress Tracker - Validation Service Consolidation

## Pre-Migration Setup

### User Input Required (BLOCKING)
- [ ] **Q1**: Which validation logic? ValidationService multi-rule ☐ | FieldValidationService single-rule ☐ | Hybrid ☐
- [ ] **Q2**: Placeholder pre-resolution required? Yes ☐ | No ☐ | Depends ☐
- [ ] **Q3**: Run controller usage search (paste results): _____________
- [ ] **Q4**: Frontend endpoints used: `/validate` ☐ | `/validate-with-placeholders` ☐ | Both ☐
- [ ] **Q5**: Multi-rule aggregation? Backend ☐ | Frontend ☐
- [ ] **Q6**: API versioning? In-place ☐ | v2 endpoints ☐

### Git Setup
- [ ] Create feature branch: `feature/validation-service-consolidation`
- [ ] Create backup tag: `backup-before-validation-consolidation`
- [ ] Document current HEAD commit: _____________

---

## Phase 1: Analysis (Days 1-2)

### Affected Components Discovery
- [ ] List all files referencing `IFieldValidationService`
- [ ] List all files referencing `IValidationService`
- [ ] Identify controller injection points
- [ ] Map test file dependencies
- [ ] Document API endpoints in use

### Data Flow Documentation
- [ ] Document current ValidationService flow
- [ ] Document current FieldValidationService flow
- [ ] Identify differences
- [ ] Choose canonical implementation

---

## Phase 2: Create FieldValidationRuleService (Days 3-4)

### Implementation
- [ ] Create `IFieldValidationRuleService.cs` interface
- [ ] Create `FieldValidationRuleService.cs` implementation
- [ ] Move CRUD methods from ValidationService
  - [ ] GetByIdAsync
  - [ ] GetByFormFieldIdAsync
  - [ ] GetByFormConfigurationIdAsync
  - [ ] GetByFormFieldIdWithDependenciesAsync
  - [ ] CreateAsync
  - [ ] UpdateAsync
  - [ ] DeleteAsync
- [ ] Move health check methods
  - [ ] ValidateConfigurationHealthAsync
  - [ ] ValidateDraftConfigurationAsync
- [ ] Move dependency analysis
  - [ ] GetDependentFieldIdsAsync
- [ ] Add logging for CRUD operations

### Testing
- [ ] Create `FieldValidationRuleServiceTests.cs`
- [ ] Test CRUD operations (7 tests)
- [ ] Test health checks (5 tests)
- [ ] Test circular dependency detection (3 tests)
- [ ] Achieve 80%+ code coverage

### Verification
- [ ] Service compiles without errors
- [ ] All tests pass
- [ ] No breaking changes to DTOs

---

## Phase 3: Enhance ValidationService (Days 5-7)

### Add Placeholder Support
- [ ] Inject `IPlaceholderResolutionService` in constructor
- [ ] Add `ResolvePlaceholdersForRuleAsync()` method
- [ ] Update `ExecuteValidationRuleAsync()` to accept `resolvedPlaceholders`
- [ ] Add `ValidateFieldWithPlaceholdersAsync()` method
- [ ] Merge placeholder logic from FieldValidationService

### Preserve Existing Logic
- [ ] Keep multi-rule loop in `ValidateFieldAsync()`
- [ ] Keep aggregation logic (blocking failures first)
- [ ] Keep console debug logging
- [ ] Keep formContextData dependency extraction
- [ ] Keep RequiresDependencyFilled logic

### Testing Enhancement
- [ ] Add placeholder resolution tests (5 tests)
- [ ] Add placeholder merge tests (3 tests)
- [ ] Add multi-rule placeholder tests (4 tests)
- [ ] Verify existing tests still pass
- [ ] Achieve 85%+ code coverage

### Verification
- [ ] ValidationService compiles without errors
- [ ] All existing tests pass
- [ ] New placeholder tests pass
- [ ] No performance degradation (run benchmarks)

---

## Phase 4: Update Controller (Days 7-8)

### Update Dependencies
- [ ] Add `IFieldValidationRuleService` injection
- [ ] Keep `IValidationService` injection
- [ ] Remove `IFieldValidationService` injection
- [ ] Update constructor signature

### Update CRUD Endpoints
- [ ] Update `GetById()` → call `_ruleService.GetByIdAsync()`
- [ ] Update `GetByFieldId()` → call `_ruleService.GetByFormFieldIdAsync()`
- [ ] Update `Create()` → call `_ruleService.CreateAsync()`
- [ ] Update `Update()` → call `_ruleService.UpdateAsync()`
- [ ] Update `Delete()` → call `_ruleService.DeleteAsync()`

### Update Validation Endpoints
- [ ] Keep `/validate` endpoint → call `_validationService.ValidateFieldAsync()`
- [ ] Add `/validate-with-placeholders` endpoint (OPTIONAL)
- [ ] OR Update `/validate` to use new placeholder-aware method

### API Versioning (if chosen)
- [ ] Add `/v2/validate` endpoint
- [ ] Keep `/validate` as v1 (deprecated)
- [ ] Add deprecation warnings to v1
- [ ] Update Swagger docs

### Testing
- [ ] Update controller tests to mock new services
- [ ] Test CRUD endpoints return 200
- [ ] Test validation endpoints work
- [ ] Test placeholder data in response

---

## Phase 5: Update DI Registration (Day 8)

### ServiceCollectionExtensions.cs
- [ ] Remove `services.AddScoped<IFieldValidationService, FieldValidationService>()`
- [ ] Add `services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>()`
- [ ] Verify `services.AddScoped<IValidationService, ValidationService>()` exists
- [ ] Verify `services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>()` exists

### Verification
- [ ] Run `dotnet build` → 0 errors
- [ ] Run `dotnet test` → all pass
- [ ] Check for circular dependency warnings

---

## Phase 6: Update Tests (Days 9-11)

### Unit Tests
- [ ] Split `ValidationServiceTests.cs` into:
  - [ ] `FieldValidationRuleServiceTests.cs` (CRUD/health checks)
  - [ ] `ValidationServiceTests.cs` (validation + placeholders)
- [ ] Delete `FieldValidationServiceTests.cs`
- [ ] Update all test mocks

### Integration Tests
- [ ] Update `PlaceholderResolutionIntegrationTests.cs`
- [ ] Update `FieldValidationRulesControllerTests.cs`
- [ ] Add end-to-end placeholder interpolation test

### Test Execution
- [ ] Run `dotnet test` → all pass
- [ ] Run code coverage → >= 80%
- [ ] Fix any flaky tests

---

## Phase 7: Delete Deprecated Service (Day 11)

### File Deletion
- [ ] Delete `Services/FieldValidationService.cs`
- [ ] Delete `Services/Interfaces/IFieldValidationService.cs`

### Verification
- [ ] Search codebase for `IFieldValidationService` → 0 results
- [ ] Search codebase for `FieldValidationService` → 0 results (except tests)
- [ ] Run `dotnet build` → 0 errors
- [ ] Run `dotnet test` → all pass

---

## Phase 8: Frontend Migration (Days 12-13)

### API Client Update
- [ ] Update `fieldValidationRuleClient.ts`
- [ ] Add `validateFieldV2()` method (if using versioning)
- [ ] Keep `validateField()` for backward compatibility

### Component Updates
- [ ] Update `FormWizard.tsx` validation calls
- [ ] Update `WorldBoundFieldRenderer.tsx` validation calls
- [ ] Update `FieldRenderers.tsx` validation calls
- [ ] Search for all `validateField()` calls

### Frontend Testing
- [ ] Run `npm run build` → 0 errors
- [ ] Run `npm test` (if tests exist)
- [ ] Manual test Town entity edit form
- [ ] Verify placeholder interpolation works
- [ ] Check browser console for errors

---

## Phase 9: Staging Deployment (Day 14)

### Pre-Deployment
- [ ] Run full test suite → all pass
- [ ] Review code changes one more time
- [ ] Create deployment checklist
- [ ] Notify team of deployment window

### Backend Deploy
- [ ] Build release: `dotnet publish -c Release`
- [ ] Deploy to staging
- [ ] Restart application
- [ ] Check application logs

### Backend Smoke Test
- [ ] Test health check endpoint: `GET /health`
- [ ] Test rule retrieval: `GET /api/field-validation-rules/{id}`
- [ ] Test validation: `POST /api/field-validation-rules/validate`
- [ ] Test placeholder data in response
- [ ] Check logs for errors

### Frontend Deploy
- [ ] Build frontend: `npm run build`
- [ ] Deploy to staging
- [ ] Clear browser cache
- [ ] Reload application

### E2E Staging Test
- [ ] Login to staging
- [ ] Navigate to Town entity form
- [ ] Trigger validation
- [ ] Verify placeholder interpolation
- [ ] Check browser console logs
- [ ] Test multiple validation scenarios

---

## Phase 10: Production Deployment (Day 15)

### Pre-Production Checklist
- [ ] Staging smoke test passed
- [ ] All team members notified
- [ ] Rollback plan documented
- [ ] Database backup taken (if needed)
- [ ] Monitoring dashboards open

### Production Deploy
- [ ] Deploy backend to production
- [ ] Verify backend health check
- [ ] Deploy frontend to production
- [ ] Monitor error rates for 30 minutes

### Post-Deploy Verification
- [ ] API error rate: ___% (should not increase)
- [ ] Validation endpoint P95 latency: ___ms (should be similar)
- [ ] Frontend console errors: ___ (should not increase)
- [ ] Test critical user flow: Login → Town edit → Validation

### Rollback Decision
- [ ] NO ISSUES → Mark migration as successful
- [ ] ISSUES FOUND → Execute rollback plan

---

## Post-Migration (Week 2)

### Monitoring
- [ ] Review application logs daily (Week 1)
- [ ] Check error rates and latency metrics
- [ ] Gather user feedback
- [ ] Address any issues promptly

### Documentation
- [ ] Update API documentation
- [ ] Update developer onboarding docs
- [ ] Document new service architecture
- [ ] Create architecture diagram

### Cleanup (if using API versioning)
- [ ] Add deprecation warning to v1 endpoints (Week 3)
- [ ] Monitor v1 endpoint usage
- [ ] Remove v1 endpoints (Month 2)

---

## Success Metrics

- [ ] **Zero breaking changes** (if using versioning strategy)
- [ ] **API error rate**: No increase from baseline
- [ ] **Validation latency**: Within 10% of baseline
- [ ] **Test coverage**: >= 80% overall
- [ ] **Placeholder interpolation**: Works end-to-end
- [ ] **Code complexity**: FieldValidationRuleService < 300 lines, ValidationService < 700 lines
- [ ] **Team confidence**: 4+ devs can explain new architecture

---

## Risk Log

| Date | Risk Identified | Mitigation | Status |
|------|----------------|------------|--------|
| ___ | _______________ | __________ | ______ |

---

## Decision Log

| Date | Decision | Rationale | Decided By |
|------|----------|-----------|------------|
| ___ | Chose Option B | Clean separation of concerns | Team |
| ___ | API versioning strategy: _____ | _____________ | _____ |
| ___ | Placeholder resolution: ______ | _____________ | _____ |

---

## Rollback Log

| Date | Component | Reason | Action Taken |
|------|-----------|--------|--------------|
| ___ | ________ | ______ | ___________ |

