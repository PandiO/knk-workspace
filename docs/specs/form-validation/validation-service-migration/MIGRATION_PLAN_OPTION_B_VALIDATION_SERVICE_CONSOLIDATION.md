# Migration Plan: Option B - Separate FieldValidationRuleService + Enhanced ValidationService

## Executive Summary

**Goal**: Refactor validation architecture to achieve clean separation of concerns by:
1. Moving rule CRUD operations to new `FieldValidationRuleService`
2. Enhancing `ValidationService` with placeholder resolution capabilities
3. Deprecating and removing `FieldValidationService` and `IFieldValidationService`
4. Consolidating all validation execution logic in `ValidationService`

**Timeline**: 2-3 weeks (10-15 working days)

**Risk Level**: HIGH (Breaking changes to API contracts)

---

## Phase 0: Pre-Migration Analysis & Setup

### 0.1 Source Logic Priority Assessment

**CRITICAL QUESTION FOR USER:**

We have two different validation execution paths:

#### **Path A: ValidationService.cs (Current Production)**
```csharp
// Location: Lines 132-656
public async Task<ValidationResultDto> ValidateFieldAsync(...)
{
    // 1. Gets all rules for field
    var rules = await _ruleRepository.GetByFormFieldIdAsync(fieldId);
    
    // 2. Loops through each rule
    foreach (var rule in rules)
    {
        // 3. Calls ExecuteValidationRuleAsync()
        var result = await ExecuteValidationRuleAsync(rule, fieldValue, dependencyValue, formContextData);
        
        // 4. ExecuteValidationRuleAsync() has:
        //    - Dependency extraction from formContextData (lines 572-582)
        //    - RequiresDependencyFilled check (lines 585-598)
        //    - Finds IValidationMethod implementation (line 601)
        //    - Calls validator.ValidateAsync() (lines 608-616)
        //    - Returns ValidationResultDto with placeholders (lines 618-631)
    }
    
    // 5. Aggregates results (blocking failures first, warnings second)
}
```

**Features:**
- ✅ Console debug logging
- ✅ Extracts dependency from formContextData if not provided
- ✅ Handles RequiresDependencyFilled logic
- ✅ Aggregates multiple rule results
- ✅ Returns first blocking failure or first warning
- ❌ No built-in placeholder resolution (but validators create placeholders)

#### **Path B: FieldValidationService.cs (Recently Fixed)**
```csharp
// Location: Lines 38-127
public async Task<ValidationResultDto> ValidateFieldAsync(...)
{
    // 1. Resolves placeholders FIRST
    var placeholderResponse = await ResolvePlaceholdersForRuleAsync(rule, entityId, currentEntityPlaceholders);
    
    // 2. Dispatches to type-specific method
    ValidationResultDto result = rule.ValidationType switch
    {
        "LocationInsideRegion" => await ValidateLocationInsideRegionAsync(...),
        "RegionContainment" => await ValidateRegionContainmentAsync(...),
        "ConditionalRequired" => await ValidateConditionalRequiredAsync(...),
        _ => new ValidationResultDto { IsValid = false, Message = "Unknown type" }
    };
    
    // 3. Type-specific methods (e.g., ValidateLocationInsideRegionAsync):
    //    - Looks up validator from _validationMethods dictionary
    //    - Converts placeholders to formContextData
    //    - Calls validator.ValidateAsync()
    //    - Returns single ValidationResultDto
}
```

**Features:**
- ✅ Pre-resolves placeholders via PlaceholderResolutionService
- ✅ Enriches metadata (ExecutedAt, DependencyValue)
- ✅ Type-specific method routing
- ❌ No multi-rule aggregation (validates one rule at a time)
- ❌ No console debug logging
- ❌ No formContextData dependency extraction

---

### **USER INPUT REQUIRED:**

**Question 1: Which validation execution logic is correct?**
- [ ] **ValidationService.cs** - Multi-rule loop with aggregation (seems production-tested)
- [ ] **FieldValidationService.cs** - Single-rule with pre-resolution (seems newer/experimental)
- [ ] **Hybrid** - Merge both approaches (describe which parts from each)

**Question 2: Is placeholder pre-resolution required?**
- FieldValidationService calls `PlaceholderResolutionService.ResolveAllLayersAsync()` BEFORE validation
- ValidationService lets validators create placeholders during execution
- Which is the correct flow?

**Question 3: Controller usage verification**
Please run this to see which service is actually being called:
```powershell
cd Repository/knk-web-api-v2
# Find all controller usages
Select-String -Pattern "IValidationService|IFieldValidationService" -Path "Controllers/*.cs" -Context 2,2

# Find all service instantiations
Select-String -Pattern "ValidationService|FieldValidationService" -Path "**/*.cs" -Exclude "*Test*.cs"
```

**Question 4: Frontend API client**
Which endpoints does the frontend actually call?
- `/api/field-validation-rules/validate` (ValidationService)
- `/api/field-validation-rules/validate-field-rule` (FieldValidationService)
- Both?

---

## Phase 1: Impact Analysis & Discovery (Days 1-2)

### 1.1 Affected Components Inventory

#### **Services**
| Component | Action | Reason |
|-----------|--------|--------|
| `ValidationService.cs` | **ENHANCE** | Add placeholder resolution, keep validation logic |
| `IValidationService.cs` | **ENHANCE** | Add placeholder-related methods |
| `FieldValidationService.cs` | **DELETE** | Logic merged into ValidationService |
| `IFieldValidationService.cs` | **DELETE** | Interface no longer needed |
| `FieldValidationRuleService.cs` | **CREATE** | Extract rule CRUD from ValidationService |
| `IFieldValidationRuleService.cs` | **CREATE** | New interface for rule management |
| `PlaceholderResolutionService.cs` | **KEEP** | Used by enhanced ValidationService |
| `DependencyResolutionService.cs` | **KEEP** | Already used by ValidationService |

#### **Controllers**
| Controller | Action | Changes |
|------------|--------|---------|
| `FieldValidationRulesController.cs` | **REFACTOR** | Update DI, split CRUD vs validation endpoints |
| (Possibly others) | **UPDATE** | Find all controllers injecting IFieldValidationService |

#### **Repositories**
| Repository | Action | Changes |
|------------|--------|---------|
| `FieldValidationRuleRepository.cs` | **KEEP** | No changes (used by new service) |
| `IFieldValidationRuleRepository.cs` | **KEEP** | No changes |

#### **DTOs**
| DTO | Action | Changes |
|-----|--------|---------|
| `ValidationResultDto` | **REVIEW** | Ensure has Placeholders property |
| `PlaceholderResolutionRequest` | **REVIEW** | Ensure compatible with ValidationService |
| `PlaceholderResolutionResponse` | **REVIEW** | Ensure compatible with ValidationService |
| `FieldValidationRuleDto` | **KEEP** | No changes |
| `CreateFieldValidationRuleDto` | **KEEP** | No changes |
| `UpdateFieldValidationRuleDto` | **KEEP** | No changes |

#### **Tests**
| Test File | Action | Scope |
|-----------|--------|-------|
| `ValidationServiceTests.cs` | **ENHANCE** | Add placeholder resolution tests |
| `FieldValidationServiceTests.cs` | **DELETE** | Logic moved to ValidationServiceTests |
| `FieldValidationRuleServiceTests.cs` | **CREATE** | Test new CRUD service |
| `PlaceholderResolutionIntegrationTests.cs` | **UPDATE** | Update to use ValidationService |
| `FieldValidationRulesControllerTests.cs` | **UPDATE** | Update controller dependency mocking |
| (Integration tests) | **UPDATE** | Any tests calling validation endpoints |

#### **DI Registration**
| File | Action | Changes |
|------|--------|---------|
| `ServiceCollectionExtensions.cs` | **UPDATE** | Register new services, remove old |
| `Program.cs` | **REVIEW** | Verify DI wiring correct |

---

## Phase 2: Create Migration Branches & Backup (Day 2)

### 2.1 Git Strategy
```bash
# Create feature branch
git checkout -b feature/validation-service-consolidation

# Create backup tags
git tag backup-before-validation-consolidation
git tag backup-validation-service-state
```

### 2.2 Database State Verification
```sql
-- Verify no data migration needed (validation rules stored in DB, not code)
SELECT COUNT(*) FROM FieldValidationRules;
SELECT DISTINCT ValidationType FROM FieldValidationRules;
```

---

## Phase 3: Create New FieldValidationRuleService (Days 3-4)

### 3.1 Create Service Interface

**File**: `Services/Interfaces/IFieldValidationRuleService.cs`

```csharp
namespace knkwebapi_v2.Services.Interfaces;

/// <summary>
/// Service for managing field validation rule lifecycle (CRUD operations).
/// Separated from validation execution for clean separation of concerns.
/// </summary>
public interface IFieldValidationRuleService
{
    // Rule CRUD
    Task<FieldValidationRuleDto?> GetByIdAsync(int id);
    Task<IEnumerable<FieldValidationRuleDto>> GetByFormFieldIdAsync(int fieldId);
    Task<IEnumerable<FieldValidationRuleDto>> GetByFormConfigurationIdAsync(int formConfigurationId);
    Task<IEnumerable<FieldValidationRuleDto>> GetByFormFieldIdWithDependenciesAsync(int fieldId, Dictionary<string, object>? formContext = null);
    Task<FieldValidationRuleDto> CreateAsync(CreateFieldValidationRuleDto dto);
    Task UpdateAsync(int id, UpdateFieldValidationRuleDto dto);
    Task DeleteAsync(int id);
    
    // Configuration health
    Task<IEnumerable<ValidationIssueDto>> ValidateConfigurationHealthAsync(int formConfigurationId);
    Task<IEnumerable<ValidationIssueDto>> ValidateDraftConfigurationAsync(FormConfigurationDto configDto);
    
    // Dependency analysis
    Task<IEnumerable<int>> GetDependentFieldIdsAsync(int fieldId);
}
```

### 3.2 Create Service Implementation

**File**: `Services/FieldValidationRuleService.cs`

**Source**: Copy from `ValidationService.cs` lines 40-124, 426-663 (all non-validation methods)

**Changes needed**:
- Remove validation-related methods
- Keep CRUD operations
- Keep health check methods
- Keep dependency analysis methods
- Add logging for auditing
- Update constructor to remove validation-specific dependencies

### 3.3 Unit Tests

**File**: `Tests/Services/FieldValidationRuleServiceTests.cs`

**Source**: Copy relevant tests from `ValidationServiceTests.cs`

Tests to include:
- CRUD operations
- Circular dependency detection
- Health check scenarios
- Field ordering validation

---

## Phase 4: Enhance ValidationService with Placeholder Resolution (Days 5-7)

### 4.1 Update IValidationService Interface

**File**: `Services/Interfaces/IValidationService.cs`

Add placeholder-aware methods:
```csharp
// Add these methods
Task<PlaceholderResolutionResponse> ResolvePlaceholdersForRuleAsync(
    FieldValidationRule rule,
    int? entityId = null,
    Dictionary<string, string>? currentEntityPlaceholders = null);

Task<ValidationResultDto> ValidateFieldWithPlaceholdersAsync(
    FieldValidationRule rule,
    object? fieldValue,
    object? dependencyFieldValue = null,
    Dictionary<string, string>? currentEntityPlaceholders = null,
    int? entityId = null);

// Keep existing methods (no breaking changes)
```

### 4.2 Enhance ValidationService Implementation

**File**: `Services/ValidationService.cs`

**Changes**:

1. **Add IPlaceholderResolutionService dependency**
```csharp
private readonly IPlaceholderResolutionService _placeholderService;

public ValidationService(
    ...,
    IPlaceholderResolutionService placeholderService,  // NEW
    ...)
{
    _placeholderService = placeholderService;
}
```

2. **Add placeholder resolution method** (copy from FieldValidationService lines 130-171)
```csharp
public async Task<PlaceholderResolutionResponse> ResolvePlaceholdersForRuleAsync(...)
{
    // Copy implementation from FieldValidationService
}
```

3. **Enhance ExecuteValidationRuleAsync()** (lines 558-643)
```csharp
// OPTION A: Add placeholder resolution inline
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRule rule,
    object? fieldValue,
    object? dependencyValue,
    Dictionary<string, object>? formContextData,
    Dictionary<string, string>? resolvedPlaceholders = null)  // NEW PARAMETER
{
    // Existing logic...
    
    var result = await validationMethod.ValidateAsync(...);
    
    // MERGE placeholders from validator + pre-resolved
    var allPlaceholders = new Dictionary<string, string>(resolvedPlaceholders ?? new());
    if (result.Placeholders != null)
    {
        foreach (var kvp in result.Placeholders)
        {
            allPlaceholders[kvp.Key] = kvp.Value;
        }
    }
    
    return new ValidationResultDto
    {
        Placeholders = allPlaceholders,  // Return merged placeholders
        // ... rest of properties
    };
}
```

4. **Create placeholder-aware validation method**
```csharp
public async Task<ValidationResultDto> ValidateFieldWithPlaceholdersAsync(
    FieldValidationRule rule,
    object? fieldValue,
    object? dependencyFieldValue = null,
    Dictionary<string, string>? currentEntityPlaceholders = null,
    int? entityId = null)
{
    // 1. Resolve placeholders (from FieldValidationService pattern)
    var placeholderResponse = await ResolvePlaceholdersForRuleAsync(
        rule, entityId, currentEntityPlaceholders);
    
    // 2. Execute validation with resolved placeholders
    return await ExecuteValidationRuleAsync(
        rule,
        fieldValue,
        dependencyFieldValue,
        formContextData: null,
        resolvedPlaceholders: placeholderResponse.ResolvedPlaceholders);
}
```

### 4.3 Decision Point: Multi-Rule vs Single-Rule

**CURRENT STATE:**
- `ValidationService.ValidateFieldAsync()` loops through ALL rules for a field
- `FieldValidationService.ValidateFieldAsync()` validates ONE rule at a time

**OPTIONS:**

**Option 4.3.A: Keep Multi-Rule Loop (RECOMMENDED)**
- Frontend still calls once per field
- Backend handles aggregation
- Matches current production behavior

**Option 4.3.B: Change to Single-Rule**
- Frontend must loop through rules
- More API calls
- Matches FieldValidationService pattern

**USER INPUT REQUIRED**: Which option?

---

## Phase 5: Update Controller (Days 7-8)

### 5.1 Update FieldValidationRulesController

**File**: `Controllers/FieldValidationRulesController.cs`

**Changes**:

1. **Update constructor dependencies**
```csharp
public FieldValidationRulesController(
    IFieldValidationRuleService ruleService,           // NEW
    IValidationService validationService,              // KEEP (enhanced)
    IPlaceholderResolutionService placeholderService,  // KEEP
    // REMOVE: IFieldValidationService fieldValidationService
    ...)
```

2. **Update CRUD endpoint handlers**
```csharp
// Change from _service.GetByIdAsync() to _ruleService.GetByIdAsync()
[HttpGet("{id}")]
public async Task<ActionResult<FieldValidationRuleDto>> GetById(int id)
{
    var result = await _ruleService.GetByIdAsync(id);  // Changed
    // ...
}
```

3. **Update validation endpoint**
```csharp
[HttpPost("validate")]
public async Task<ActionResult<ValidationResultDto>> ValidateField(ValidateFieldRequestDto request)
{
    // Keep using _validationService (now enhanced with placeholders)
    var result = await _validationService.ValidateFieldAsync(request);
    return Ok(result);
}
```

4. **Add new placeholder-aware validation endpoint (optional for migration)**
```csharp
[HttpPost("validate-with-placeholders")]
public async Task<ActionResult<ValidationResultDto>> ValidateFieldWithPlaceholders(
    [FromBody] ValidateFieldWithPlaceholdersRequestDto request)
{
    // Use new method from enhanced ValidationService
    var result = await _validationService.ValidateFieldWithPlaceholdersAsync(
        request.Rule,
        request.FieldValue,
        request.DependencyFieldValue,
        request.CurrentEntityPlaceholders,
        request.EntityId);
    
    return Ok(result);
}
```

### 5.2 API Versioning Strategy

**Breaking Change Management**:

**Option 5.2.A: In-Place Update (RISKY)**
- Update existing endpoints
- Coordinate frontend deploy
- Rollback plan required

**Option 5.2.B: Add v2 Endpoints (SAFER)**
- Keep `/api/field-validation-rules/validate` (legacy)
- Add `/api/v2/field-validation-rules/validate` (new)
- Gradual frontend migration
- Deprecate v1 after 2-3 months

**USER INPUT REQUIRED**: Which versioning strategy?

---

## Phase 6: Update Dependency Injection (Day 8)

### 6.1 Update ServiceCollectionExtensions

**File**: `DependencyInjection/ServiceCollectionExtensions.cs`

```csharp
// REMOVE these lines
services.AddScoped<IFieldValidationService, FieldValidationService>();

// ADD these lines
services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>();

// KEEP (but verify enhanced with placeholder support)
services.AddScoped<IValidationService, ValidationService>();
```

### 6.2 Verify No Circular Dependencies
```bash
# Use dependency analyzer tool
dotnet list package --include-transitive
```

---

## Phase 7: Update Tests (Days 9-11)

### 7.1 Create FieldValidationRuleServiceTests

**Source**: Extract from `ValidationServiceTests.cs`

Tests:
- [ ] GetByIdAsync returns correct rule
- [ ] CreateAsync validates dependencies
- [ ] UpdateAsync prevents circular dependencies
- [ ] DeleteAsync removes rule
- [ ] ValidateConfigurationHealthAsync finds ordering issues
- [ ] ValidateDraftConfigurationAsync validates draft states
- [ ] GetDependentFieldIdsAsync returns correct dependents

### 7.2 Enhance ValidationServiceTests

**Add tests**:
- [ ] ResolvePlaceholdersForRuleAsync resolves all layers
- [ ] ValidateFieldWithPlaceholdersAsync includes placeholders in result
- [ ] ExecuteValidationRuleAsync merges validator + pre-resolved placeholders
- [ ] ValidateFieldAsync with multiple rules aggregates correctly
- [ ] Placeholder resolution errors handled gracefully

### 7.3 Delete FieldValidationServiceTests

```bash
rm Tests/Services/FieldValidationServiceTests.cs
```

### 7.4 Update Integration Tests

**Files**:
- `PlaceholderResolutionIntegrationTests.cs`
- `FieldValidationRulesControllerTests.cs`
- Any API client tests

**Changes**:
- Update mocks to use `IFieldValidationRuleService` + `IValidationService`
- Remove `IFieldValidationService` mocks
- Verify placeholder resolution in end-to-end scenarios

### 7.5 Test Coverage Verification
```bash
cd Repository/knk-web-api-v2
dotnet test --collect:"XPlat Code Coverage"
# Ensure coverage >= 80% for new/modified services
```

---

## Phase 8: Delete Deprecated Service (Day 11)

### 8.1 Delete Files
```bash
rm Services/FieldValidationService.cs
rm Services/Interfaces/IFieldValidationService.cs
```

### 8.2 Verify No References
```powershell
# Should return 0 results
Select-String -Pattern "IFieldValidationService|FieldValidationService" -Path "**/*.cs"
```

---

## Phase 9: Frontend Migration (Days 12-13)

### 9.1 Update API Client

**File**: `Repository/knk-web-app/src/services/fieldValidationRuleClient.ts`

**Changes**:
```typescript
// IF using v2 endpoints strategy:
export const validateFieldV2 = async (request: ValidateFieldRequest): Promise<ValidationResultDto> => {
  const response = await apiClient.post<ValidationResultDto>(
    '/api/v2/field-validation-rules/validate',  // NEW ENDPOINT
    request
  );
  return response.data;
};

// Keep v1 for backward compatibility during migration
export const validateField = async (request: ValidateFieldRequest): Promise<ValidationResultDto> => {
  const response = await apiClient.post<ValidationResultDto>(
    '/api/field-validation-rules/validate',  // OLD ENDPOINT
    request
  );
  return response.data;
};
```

### 9.2 Update Components

**Files to update**:
- `FormWizard.tsx`
- `WorldBoundFieldRenderer.tsx`
- `FieldRenderers.tsx`
- Any component calling validation endpoints

**Changes**:
```typescript
// Update import
import { validateFieldV2 } from '../services/fieldValidationRuleClient';

// Update call
const result = await validateFieldV2({
  fieldId,
  fieldValue,
  dependencyValue,
  formContextData
});
```

### 9.3 Test Frontend E2E

**Scenarios**:
- [ ] Town entity edit with location validation
- [ ] Placeholder interpolation works in error messages
- [ ] Console shows non-empty placeholders dictionary
- [ ] Blocking vs non-blocking validation behavior correct

---

## Phase 10: Deployment (Days 14-15)

### 10.1 Pre-Deployment Checklist

- [ ] All unit tests pass (backend)
- [ ] All integration tests pass (backend)
- [ ] Frontend compiles without errors
- [ ] Manual testing completed for critical flows
- [ ] Database migration script reviewed (if any)
- [ ] Rollback plan documented
- [ ] Monitoring dashboards configured

### 10.2 Deployment Sequence

**Step 1: Backend Deploy**
```bash
cd Repository/knk-web-api-v2
dotnet publish -c Release
# Deploy to staging first
```

**Step 2: Smoke Test Staging**
- Test `/api/field-validation-rules/validate` endpoint
- Test `/api/v2/field-validation-rules/validate` endpoint (if using v2)
- Verify placeholder resolution
- Check logs for errors

**Step 3: Frontend Deploy**
```bash
cd Repository/knk-web-app
npm run build
# Deploy to staging
```

**Step 4: Staging E2E Test**
- [ ] Login flow works
- [ ] Town entity form loads
- [ ] Validation triggers correctly
- [ ] Placeholders interpolate in error messages

**Step 5: Production Deploy**
- Backend first (backward compatible if using v2 strategy)
- Frontend second
- Monitor error rates

### 10.3 Post-Deployment Verification

**Metrics to monitor**:
- API error rate (should not increase)
- Validation endpoint latency (should be similar)
- Frontend console errors (should not increase)
- Database query count (watch for N+1 issues)

### 10.4 Rollback Plan

**If issues occur:**
```bash
# Backend rollback
git revert <commit-hash>
dotnet publish -c Release
# Deploy previous version

# Frontend rollback
git revert <commit-hash>
npm run build
# Deploy previous version
```

---

## Risk Mitigation Strategies

### Risk 1: Breaking API Contract
**Mitigation**: Use API versioning (/api/v2/...) during migration

### Risk 2: Performance Degradation
**Mitigation**: 
- Add caching layer for placeholder resolution
- Use database query profiling
- Load test before production

### Risk 3: Placeholder Resolution Errors
**Mitigation**:
- Fail-open design (validation passes if placeholders fail)
- Extensive error logging
- Fallback to non-placeholder validation

### Risk 4: Test Coverage Gaps
**Mitigation**:
- Require 80%+ code coverage
- Add integration tests for critical paths
- Manual QA checklist

---

## Rollback Decision Criteria

**ROLLBACK IF:**
- API error rate increases > 5%
- Validation endpoint P95 latency increases > 50%
- Critical validation logic fails (e.g., region checks not working)
- Frontend placeholder interpolation completely broken
- Database connection pool exhausted

**DO NOT ROLLBACK IF:**
- Minor logging issues
- Non-critical placeholder resolution errors (fail-open)
- Test environment issues

---

## Success Criteria

**Migration is successful when:**
- [ ] FieldValidationRuleService handles all CRUD operations
- [ ] ValidationService handles all validation with placeholders
- [ ] FieldValidationService and IFieldValidationService deleted
- [ ] All unit tests pass (>=80% coverage)
- [ ] All integration tests pass
- [ ] Frontend uses new API endpoints
- [ ] No increase in API error rates
- [ ] Placeholder interpolation works end-to-end
- [ ] Documentation updated
- [ ] Team trained on new architecture

---

## Post-Migration Cleanup (Month 2)

### Week 1-2: Monitoring & Optimization
- Review application logs for errors
- Optimize slow queries
- Add caching where beneficial

### Week 3: Deprecate v1 Endpoints (if using versioning)
- Add deprecation warnings to v1 endpoints
- Update documentation to use v2

### Week 4: Remove v1 Endpoints
- Delete legacy controller methods
- Update OpenAPI/Swagger docs

---

## Open Questions Requiring User Input

1. **Which validation execution logic is correct?** (ValidationService multi-rule loop vs FieldValidationService single-rule)
2. **Is placeholder pre-resolution required?** (Before validation vs during validation)
3. **Which service is production-proven?** (Run the controller usage search commands)
4. **Multi-rule vs single-rule endpoint?** (Aggregation backend vs frontend)
5. **API versioning strategy?** (In-place update vs v2 endpoints)
6. **Placeholder resolution timing?** (Before validation loop vs during each rule execution)

---

## Estimated Effort Breakdown

| Phase | Duration | Complexity |
|-------|----------|------------|
| Phase 0: Analysis | 0.5 days | Low |
| Phase 1: Impact Analysis | 1.5 days | Medium |
| Phase 2: Git Setup | 0.5 days | Low |
| Phase 3: Create FieldValidationRuleService | 2 days | Medium |
| Phase 4: Enhance ValidationService | 3 days | High |
| Phase 5: Update Controller | 1.5 days | Medium |
| Phase 6: Update DI | 0.5 days | Low |
| Phase 7: Update Tests | 3 days | High |
| Phase 8: Delete Deprecated | 0.5 days | Low |
| Phase 9: Frontend Migration | 2 days | Medium |
| Phase 10: Deployment | 1.5 days | High |
| **TOTAL** | **16.5 days** | **2-3 weeks** |

---

## Next Steps

**IMMEDIATE:**
1. **User provides answers to 6 open questions above**
2. Review and approve this migration plan
3. Schedule team meeting to discuss timeline
4. Create GitHub project/issues for tracking

**AFTER APPROVAL:**
5. Execute Phase 0 (analysis with user's answers)
6. Create feature branch
7. Begin Phase 3 (create FieldValidationRuleService)

