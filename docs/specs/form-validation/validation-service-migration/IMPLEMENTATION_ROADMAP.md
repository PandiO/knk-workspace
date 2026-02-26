# Migration Option B - Implementation Roadmap

**Status**: Ready to Execute  
**Timeline**: 15 days (3 weeks)  
**Start Date**: [TBD]  
**Decisions Made**:
- ✅ Q1: ValidationService.cs multi-rule logic (production-tested)
- ✅ Q2: Option B - standardized resolution pattern
- ✅ Q3: Controller verified - both services injected
- ✅ Q4: Frontend uses `/api/field-validation-rules/validate`
- ✅ Q5: Backend aggregates (Option A)
- ✅ Q6: In-place update (Option A)

---

## Quick Navigation

> 🎯 **START HERE**: For step-by-step implementation with exact line numbers and code changes, go to [MASTER_CHECKLIST.md](./MASTER_CHECKLIST.md)

**Documentation Structure**:

1. **[MASTER_CHECKLIST.md](./MASTER_CHECKLIST.md)** ⭐ PRIMARY IMPLEMENTATION GUIDE
   - 450+ checkboxes with exact line numbers
   - All 8 phases with code snippets
   - File-by-file changes documented
   - Tests and verification criteria
   - **Use this**: For Copilot-assisted implementation

2. **[FRONTEND_BACKEND_WIRING_GUIDE.md](./FRONTEND_BACKEND_WIRING_GUIDE.md)** 🔌 INTEGRATION DETAILS
   - Complete API endpoint mapping (18 endpoints)
   - Type mapping (C# ↔ TypeScript)
   - Data flow diagrams
   - Before/after code patterns
   - Deprecated code removal (27 items)
   - Plugin integration specifics
   - **Use this**: When implementing data contracts

3. **[MIGRATION_OPTION_B_QUICK_REFERENCE.md](./MIGRATION_OPTION_B_QUICK_REFERENCE.md)** 📋 HIGH-LEVEL OVERVIEW
   - Decision summary (Q1-Q6)
   - Files affected (backend, frontend, plugin)
   - Risk matrix
   - Key takeaways
   - **Use this**: For stakeholder communication

4. **[IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md)** 📅 THIS DOCUMENT
   - Phase-by-phase timeline
   - Phase-specific details (Days 1-15)
   - Success criteria
   - **Use this**: For project tracking

5. **[MIGRATION_PROGRESS_TRACKER.md](./MIGRATION_PROGRESS_TRACKER.md)** ✅ DAILY TRACKING
   - 112 checkpoints across 15 days
   - Daily progress tracking
   - Sign-off checklist
   - **Use this**: For daily stand-ups

---

## Phase Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ PREPARATION (Days 1-2)                                          │
│ ├─ Setup git feature branch                                     │
│ ├─ Baseline current state (commit + tag)                        │
│ └─ Document current architecture                                │
├─────────────────────────────────────────────────────────────────┤
│ BACKEND TRANSFORMATION (Days 3-8)                               │
│ ├─ Phase A: Extract CRUD → FieldValidationRuleService          │
│ ├─ Phase B: Enhance ValidationService with placeholders         │
│ ├─ Phase C: Update controller & DI                              │
│ └─ Phase D: Comprehensive testing                               │
├─────────────────────────────────────────────────────────────────┤
│ CLEANUP (Day 9)                                                 │
│ ├─ Delete FieldValidationService (both files)                   │
│ └─ Final build verification                                     │
├─────────────────────────────────────────────────────────────────┤
│ FRONTEND MIGRATION (Days 10-11)                                 │
│ ├─ Update API client calls                                      │
│ ├─ Update form components                                       │
│ └─ Frontend testing                                             │
├─────────────────────────────────────────────────────────────────┤
│ PLUGIN ALIGNMENT (Days 12-13)                                   │
│ ├─ Update ValidationContext DTOs (if needed)                    │
│ ├─ Update LocationTaskHandler validation logic                  │
│ └─ Update PlaceholderInterpolationUtil                          │
├─────────────────────────────────────────────────────────────────┤
│ DEPLOYMENT & VALIDATION (Days 14-15)                            │
│ ├─ Staging deployment                                           │
│ ├─ Integration testing                                          │
│ ├─ Production deployment                                        │
│ └─ Monitoring & rollback readiness                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Implementation Phases

### PHASE 1: PREPARATION (Days 1-2)

#### 1.1 Git Setup (Day 1 - 30 min)

```bash
# Create feature branch
git checkout -b feature/validation-service-consolidation
git push -u origin feature/validation-service-consolidation

# Create backup tag
git tag backup-before-validation-consolidation
git push origin backup-before-validation-consolidation
```

**Verification**: `git branch -a` shows feature branch, `git tag -l` shows backup

#### 1.2 Baseline Documentation (Day 1 - 1 hour)

Create `docs/specs/form-validation/validation-service-migration/BASELINE_SNAPSHOT.md`:

```markdown
## Current State Snapshot (Pre-Migration)

### Services Count
- ValidationService: 663 lines, 23 public methods
- FieldValidationService: 278 lines, 8 public methods
- Total validation LOC: 941 lines

### Test Coverage
- ValidationServiceTests: XX tests, XX% coverage
- FieldValidationServiceTests: XX tests, XX% coverage  
- PlaceholderResolutionIntegrationTests: XX tests, XX% coverage

### API Endpoints
- POST /api/field-validation-rules/validate
- Accepts: {fieldId, rules, formContextData}
- Returns: {isValid, placeholders, errors[]}

### Frontend API Calls
- Unique endpoints used: 1
- Call frequency: Per field on blur-validate

### Plugin Integration
- LocationTaskHandler: Executes receieved validation rules
- PlaceholderInterpolationUtil: Merges + interpolates placeholders
- Coupled via: WorldTaskValidationContext (InputJson)
```

**Deliverable**: Baseline snapshot document with metrics

#### 1.3 Architecture Review Meeting (Day 2 - 1 hour)

**Meeting checklist**:
- [ ] Review current architecture diagram
- [ ] Confirm target architecture (FieldValidationRuleService + enhanced ValidationService)
- [ ] Approve rollback criteria
- [ ] Assign owners for backend/frontend/plugin
- [ ] Schedule daily standups (recommended)

**Output**: Meeting notes, signed decision log

---

### PHASE 2A: CREATE FieldValidationRuleService (Days 3-4)

#### 2A.1 Create Interface (Day 3 - 30 min)

**File**: `Services/Interfaces/IFieldValidationRuleService.cs`

```csharp
public interface IFieldValidationRuleService
{
    // CRUD Operations (moved from ValidationService)
    Task<FieldValidationRuleReadDto> GetByIdAsync(int ruleId);
    Task<IEnumerable<FieldValidationRuleReadDto>> GetByFieldAsync(int fieldId);
    Task<FieldValidationRuleReadDto> CreateAsync(FieldValidationRuleCreateDto dto);
    Task<FieldValidationRuleReadDto> UpdateAsync(int ruleId, FieldValidationRuleUpdateDto dto);
    Task DeleteAsync(int ruleId);
    
    // Health Check Methods (moved from ValidationService)
    Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId);
    Task<bool> ValidateDraftConfigurationAsync(int draftId);
    
    // Dependency Analysis (moved from ValidationService)
    Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData);
}
```

**Source reference**: Extract from ValidationService.cs lines 40-124, 426-540

#### 2A.2 Create Implementation (Day 3 - 2 hours)

**File**: `Services/FieldValidationRuleService.cs`

```csharp
public class FieldValidationRuleService : IFieldValidationRuleService
{
    private readonly IFieldValidationRuleRepository _repository;
    private readonly IFieldRepository _fieldRepository;
    private readonly ILogger<FieldValidationRuleService> _logger;
    
    public FieldValidationRuleService(
        IFieldValidationRuleRepository repository,
        IFieldRepository fieldRepository,
        ILogger<FieldValidationRuleService> logger)
    {
        _repository = repository;
        _fieldRepository = fieldRepository;
        _logger = logger;
    }
    
    // Copy GetByIdAsync, GetByFieldAsync, CreateAsync, UpdateAsync, DeleteAsync
    // from ValidationService.cs (lines 40-124)
    
    // Copy ValidateConfigurationHealthAsync, ValidateDraftConfigurationAsync
    // from ValidationService.cs (lines 426-540)
    
    // Copy ResolveDependenciesAsync from ValidationService.cs (around line 256)
}
```

**Extraction guide**:
- Copy lines 40-124 (CRUD methods)
- Copy lines 426-540 (Health checks + ValidateDraftConfigurationAsync)
- Copy dependency resolution logic (identify in ValidationService)
- Inject only: `IFieldValidationRuleRepository`, `IFieldRepository`, `ILogger`

**Line count target**: ~300 lines ✓

#### 2A.3 Create Unit Tests (Day 4 - 3 hours)

**File**: `Tests/Services/FieldValidationRuleServiceTests.cs`

Test structure (target 25+ tests, 80%+ coverage):

```csharp
public class FieldValidationRuleServiceTests
{
    // CRUD Tests (8 tests)
    [Fact] public Task GetByIdAsync_WithValidId_ReturnsRule() { }
    [Fact] public Task GetByIdAsync_WithInvalidId_ThrowsNotFoundException() { }
    [Fact] public Task GetByFieldAsync_ReturnsAllRulesForField() { }
    [Fact] public Task CreateAsync_WithValidDto_ReturnsCreatedRule() { }
    [Fact] public Task CreateAsync_WithDuplicateRule_ThrowsConflictException() { }
    [Fact] public Task UpdateAsync_WithValidDto_ReturnsUpdatedRule() { }
    [Fact] public Task DeleteAsync_WithValidId_RemovesRule() { }
    [Fact] public Task DeleteAsync_WithReferencedRule_ThrowsDependencyException() { }
    
    // Health Check Tests (6 tests)
    [Fact] public Task ValidateConfigurationHealthAsync_AllRulesHealthy_ReturnsHealthy() { }
    [Fact] public Task ValidateConfigurationHealthAsync_WithOrphanedRules_ReturnsWarning() { }
    [Fact] public Task ValidateConfigurationHealthAsync_WithBrokenReferences_ReturnsFailed() { }
    [Fact] public Task ValidateDraftConfigurationAsync_ValidDraft_ReturnsTrue() { }
    [Fact] public Task ValidateDraftConfigurationAsync_InvalidDraft_ReturnsFalse() { }
    [Fact] public Task ValidateDraftConfigurationAsync_EmptyDraft_ReturnsTrue() { }
    
    // Dependency Resolution Tests (6+ tests)
    [Fact] public Task ResolveDependenciesAsync_WithMatchingDependencies_ReturnsResolved() { }
    [Fact] public Task ResolveDependenciesAsync_WithMissingDependencies_ThrowsMissingDependencyException() { }
    // ... more tests for edge cases
}
```

**Coverage tool**: 
```bash
cd Repository/knk-web-api-v2
dotnet test Tests/Services/FieldValidationRuleServiceTests.cs --collect:"XPlat Code Coverage"
```

**Target**: 80%+ coverage before moving to Phase 2B

**Checkpoint**: ✅ New service extracted, tested, and compiling

---

### PHASE 2B: ENHANCE ValidationService (Days 5-7)

#### 2B.1 Analyze Placeholder Resolution Implementation (Day 5 - 1 hour)

**Study files**:
- `Services/PlaceholderResolutionService.cs` - How does it resolve placeholders?
- `Services/FieldValidationService.cs` (lines 38-127) - How does it pre-resolve?
- `Tests/Integration/PlaceholderResolutionIntegrationTests.cs` - What patterns exist?

**Document**: Placeholder resolution algorithm in new method stub

#### 2B.2 Remove CRUD from ValidationService (Day 5 - 30 min)

**File**: `Services/ValidationService.cs`

Delete these methods (they're now in FieldValidationRuleService):
- `GetByIdAsync(int ruleId)`
- `GetByFieldAsync(int fieldId)`
- `CreateAsync(FieldValidationRuleCreateDto dto)`
- `UpdateAsync(int ruleId, FieldValidationRuleUpdateDto dto)`
- `DeleteAsync(int ruleId)`
- `ValidateConfigurationHealthAsync(...)`
- `ValidateDraftConfigurationAsync(...)`
- `ResolveDependenciesAsync(...)`

**Remaining in ValidationService**:
- `ValidateFieldAsync()` - Main validation orchestration
- `ExecuteValidationRuleAsync()` - Single rule execution
- Helper methods for validation

**New line count**: ~400-500 lines (down from 663)

#### 2B.3 Enhance ExecuteValidationRuleAsync with Placeholders (Day 6 - 2 hours)

**Current signature**:
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule, 
    object fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null)
```

**New signature**:
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule,
    object fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null,
    Dictionary<string, object>? resolvedPlaceholders = null)  // NEW
```

**Implementation steps**:
1. At start of method: resolve placeholders for this rule
2. Pass resolved placeholders to validator
3. Validator uses placeholders for error message interpolation
4. Return placeholders in ValidationResultDto

**Code pattern** (Days 6-7):
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(...)
{
    var resolvedPlaceholders = new Dictionary<string, object>();
    
    // Step 1: Resolve placeholders if validator needs them
    if (rule.RequiresDependencyFilled) {
        resolvedPlaceholders = await _placeholderResolutionService
            .ResolveAllLayersAsync(rule.FieldId, formContextData);
    }
    
    // Step 2: Execute validator
    var validator = validators.FirstOrDefault(v => v.ValidationMethod == rule.ValidationType);
    if (validator == null) {
        return new ValidationResultDto { IsValid = false, Error = "Unknown validation type" };
    }
    
    var result = await validator.ValidateAsync(fieldValue, rule.Config, resolvedPlaceholders);
    
    // Step 3: Return with placeholders
    return new ValidationResultDto {
        IsValid = result.IsValid,
        Error = result.Error,
        Placeholders = resolvedPlaceholders
    };
}
```

#### 2B.4 Add ValidateFieldWithPlaceholdersAsync (Day 6 - 1 hour)

**New public method** in ValidationService:

```csharp
public async Task<FieldValidationResultDto> ValidateFieldWithPlaceholdersAsync(
    int fieldId,
    object fieldValue,
    Dictionary<string, object> contextData)
{
    // Combine both ValidateFieldAsync + placeholder resolution
    var rules = await _repository.GetValidationRulesForFieldAsync(fieldId);
    var allPlaceholders = new Dictionary<string, object>();
    
    foreach (var rule in rules) {
        var result = await ExecuteValidationRuleAsync(
            rule, fieldValue, _validators, contextData, null);
        
        // Merge placeholders
        foreach (var kv in result.Placeholders ?? new()) {
            if (!allPlaceholders.ContainsKey(kv.Key)) {
                allPlaceholders[kv.Key] = kv.Value;
            }
        }
        
        if (!result.IsValid) {
            return new FieldValidationResultDto {
                IsValid = false,
                Error = result.Error,
                Placeholders = allPlaceholders
            };
        }
    }
    
    return new FieldValidationResultDto {
        IsValid = true,
        Placeholders = allPlaceholders
    };
}
```

#### 2B.5 Enhanced ValidationService Tests (Day 7 - 3 hours)

**Update file**: `Tests/Services/ValidationServiceTests.cs`

**New tests** (add to existing suite, target 30+ tests):

```csharp
public class ValidationServiceTests
{
    // Existing tests (keep all)
    [Fact] public Task ValidateFieldAsync_SingleRuleValid_ReturnsSuccess() { }
    [Fact] public Task ValidateFieldAsync_MultiRuleWithFailure_ReturnsFirstFailure() { }
    // ... existing tests ...
    
    // NEW: Placeholder Resolution Tests
    [Fact] 
    public async Task ExecuteValidationRuleAsync_WithPlaceholders_ReturnsInterpolatedError() 
    {
        // Given: A rule that requires placeholders
        var rule = new FieldValidationRuleReadDto { 
            ValidationType = "ConditionalRequired",
            RequiresDependencyFilled = true 
        };
        var placeholders = new Dictionary<string, object> { { "townName", "Springfield" } };
        
        // When: ExecuteValidationRuleAsync called with placeholders
        var result = await _service.ExecuteValidationRuleAsync(
            rule, "", _validators, null, placeholders);
        
        // Then: Error message contains interpolated placeholder
        Assert.Contains("Springfield", result.Error);
    }
    
    [Fact]
    public async Task ValidateFieldWithPlaceholdersAsync_AllRulesPass_ReturnsAllPlaceholders()
    {
        // Given: Multiple rules with different placeholder requirements
        var fieldId = 1;
        var contextData = new Dictionary<string, object> { /* ... */ };
        
        // When: ValidateFieldWithPlaceholdersAsync called
        var result = await _service.ValidateFieldWithPlaceholdersAsync(fieldId, "value", contextData);
        
        // Then: All placeholders from all rules merged
        Assert.True(result.IsValid);
        Assert.Contains("key1", result.Placeholders.Keys);
        Assert.Contains("key2", result.Placeholders.Keys);
    }
    
    [Fact]
    public async Task ValidateFieldWithPlaceholdersAsync_FirstRuleFails_ReturnsPartialPlaceholders()
    {
        // Given: First rule fails before all placeholders resolved
        // When: ValidateFieldWithPlaceholdersAsync called
        // Then: Returns placeholders from failed rule only
    }
}
```

**Checkpoint**: ✅ ValidationService enhanced with placeholder support, 80%+ coverage

---

### PHASE 2C: UPDATE CONTROLLER & DI (Days 7-8)

#### 2C.1 Update DI Registration (Day 7 - 30 min)

**File**: `DependencyInjection/ServiceCollectionExtensions.cs`

```csharp
public static IServiceCollection AddValidationServices(this IServiceCollection services)
{
    // OLD: Both ValidationService and FieldValidationService
    // services.AddScoped<IValidationService, ValidationService>();
    // services.AddScoped<IFieldValidationService, FieldValidationService>();
    
    // NEW: Only ValidationService (handles both rule CRUD and validation)
    // + New FieldValidationRuleService for rule management
    services.AddScoped<IValidationService, ValidationService>();
    services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>();
    
    // Other validation-related services
    services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>();
    services.AddScoped<IDependencyResolutionService, DependencyResolutionService>();
    services.AddScoped<IFieldValidationRuleRepository, FieldValidationRuleRepository>();
    
    // Register validators
    services.AddScoped<IEnumerable<IValidationMethod>>(
        provider => new IValidationMethod[] {
            provider.GetRequiredService<LocationInsideRegionValidator>(),
            provider.GetRequiredService<RegionContainmentValidator>(),
            provider.GetRequiredService<ConditionalRequiredValidator>(),
            // ... other validators
        });
    
    return services;
}
```

**Verification**:
```bash
# Search for old interface registrations
Select-String -Pattern "IFieldValidationService" -Path "**/*.cs"
# Result: Should be ZERO matches after deletion
```

#### 2C.2 Update Controller (Day 8 - 1 hour)

**File**: `Controllers/FieldValidationRulesController.cs`

**Current constructor**:
```csharp
public FieldValidationRulesController(
    IValidationService service,
    IPlaceholderResolutionService placeholderService,
    IFieldValidationService fieldValidationService,  // REMOVE
    IFieldValidationRuleRepository ruleRepository,
    IDependencyResolutionService dependencyService)
```

**New constructor**:
```csharp
public FieldValidationRulesController(
    IValidationService validationService,
    IFieldValidationRuleService ruleService,  // ADD
    IPlaceholderResolutionService placeholderService,
    IDependencyResolutionService dependencyService)
{
    _validationService = validationService;
    _ruleService = ruleService;  // ADD
    _placeholderService = placeholderService;
    _dependencyService = dependencyService;
}
```

**Update endpoints**:

| Endpoint | Old Logic | New Logic |
|----------|-----------|-----------|
| `GET /api/field-validation-rules/{id}` | `_fieldValidationService.GetByIdAsync()` | `_ruleService.GetByIdAsync()` |
| `GET /api/field-validation-rules?fieldId={id}` | `_fieldValidationService.GetByFieldAsync()` | `_ruleService.GetByFieldAsync()` |
| `POST /api/field-validation-rules` | `_fieldValidationService.CreateAsync()` | `_ruleService.CreateAsync()` |
| `PUT /api/field-validation-rules/{id}` | `_fieldValidationService.UpdateAsync()` | `_ruleService.UpdateAsync()` |
| `DELETE /api/field-validation-rules/{id}` | `_fieldValidationService.DeleteAsync()` | `_ruleService.DeleteAsync()` |
| `POST /api/field-validation-rules/validate` | `_validationService.ValidateFieldAsync()` | `_validationService.ValidateFieldAsync()` (unchanged) |

**Test updates** (Day 8 - 1 hour):
- Update controller test mocks to inject `IFieldValidationRuleService` instead of `IFieldValidationService`
- Verify all 5+ controller tests pass

**Checkpoint**: ✅ Controller refactored, DI updated, tests passing

---

### PHASE 3: DELETE & CLEANUP (Day 9)

#### 3.1 Delete FieldValidationService (Day 9 - 30 min)

```bash
# Delete both files
rm Repository/knk-web-api-v2/Services/FieldValidationService.cs
rm Repository/knk-web-api-v2/Services/Interfaces/IFieldValidationService.cs

# Search for any remaining references (should be zero)
Select-String -Pattern "IFieldValidationService|FieldValidationService" -Path "**/*.cs"
```

**Expected**: Zero references found

#### 3.2 Verify Build & Tests (Day 9 - 1 hour)

```bash
cd Repository/knk-web-api-v2

# Clean build
dotnet clean
dotnet build

# Run all validation-related tests
dotnet test Tests/Services/ValidationServiceTests.cs
dotnet test Tests/Services/FieldValidationRuleServiceTests.cs
dotnet test Tests/Controllers/FieldValidationRulesControllerTests.cs
dotnet test Tests/Integration/PlaceholderResolutionIntegrationTests.cs

# Code coverage
dotnet test --collect:"XPlat Code Coverage"
```

**Success criteria**:
- ✅ Build: 0 errors
- ✅ Tests: All pass
- ✅ Coverage: 80%+ for validation services
- ✅ No references to deleted service

**Checkpoint**: ✅ Backend refactoring complete, ready for frontend

---

### PHASE 4: FRONTEND MIGRATION (Days 10-11)

#### 4.1 Identify Frontend Usage (Day 10 - 30 min)

**Search for all validation API calls**:
```bash
cd Repository/knk-web-app

# Find all imports
grep -r "fieldValidationRule" src/

# Find all API calls
grep -r "/field-validation-rules" src/

# Find all usages
grep -r "ValidationResult\|ValidationDto" src/
```

**Expected files affected**:
1. `src/services/fieldValidationRuleClient.ts` - API client
2. `src/components/FormWizard.tsx` - Form component
3. `src/components/Workflow/WorldBoundFieldRenderer.tsx` - Field renderer

#### 4.2 Update API Client (Day 10 - 1 hour)

**File**: `src/services/fieldValidationRuleClient.ts`

**Current methods** (likely):
```typescript
export const fieldValidationRuleClient = {
    validate: (fieldId: number, rules: ValidationRule[], context: any) => 
        api.post('/field-validation-rules/validate', { fieldId, rules, context }),
    
    getRules: (fieldId: number) =>
        api.get(`/field-validation-rules?fieldId=${fieldId}`),
    
    createRule: (rule: CreateValidationRuleDto) =>
        api.post('/field-validation-rules', rule),
    
    updateRule: (id: number, rule: UpdateValidationRuleDto) =>
        api.put(`/field-validation-rules/${id}`, rule),
    
    deleteRule: (id: number) =>
        api.delete(`/field-validation-rules/${id}`),
};
```

**Expected changes**:
- Method signatures should remain the same (API contract unchanged)
- Response format should include placeholders dictionary
- Update TypeScript types to match backend DTOs

**New types**:
```typescript
interface ValidationResultDto {
    isValid: boolean;
    error?: string;
    placeholders?: Record<string, any>;  // NEW
    isBlocking?: boolean;
}
```

#### 4.3 Update Form Component (Day 10 - 1 hour)

**File**: `src/components/FormWizard.tsx`

**Areas to update**:
1. Validation call integration
2. Placeholder interpolation in error messages
3. Multi-rule display (if applicable)

**Example changes**:
```typescript
// OLD pattern
const result = await fieldValidationRuleClient.validate(fieldId, rules, context);
setError(result.error);

// NEW pattern
const result = await fieldValidationRuleClient.validate(fieldId, rules, context);
const interpolatedError = interpolatePlaceholders(result.error, result.placeholders);
setError(interpolatedError);
setPlaceholders(result.placeholders);
```

#### 4.4 Update Field Renderer (Day 10 - 30 min)

**File**: `src/components/Workflow/WorldBoundFieldRenderer.tsx`

Update any direct validation calls or references.

#### 4.5 Frontend Testing (Day 11 - 2 hours)

```bash
cd Repository/knk-web-app

# Build
npm run build

# Run validation-related tests
npm test -- --testPathPattern="validation|fieldValidation"

# Manual testing checklist
# [ ] Form validates correctly
# [ ] Placeholders interpolate in error messages
# [ ] Multiple rule validation works
# [ ] Error handling for network failure
```

**Checkpoint**: ✅ Frontend compiles, tests pass, placeholders display

---

### PHASE 5: PLUGIN ALIGNMENT (Days 12-13)

#### 5.1 Analyze Backend DTO Changes (Day 12 - 30 min)

**Review**:
- Does `WorldTaskValidationRule` structure match `FieldValidationRule` backend DTO?
- Are there new fields or types the plugin doesn't support?
- Has placeholder format changed?

**File**: `knk-core/src/main/java/net/knightsandkings/knk/core/domain/validation/WorldTaskValidationRule.java`

**Check**:
```java
// Do these fields exist in backend FieldValidationRule?
- validationType (maps to ValidationType enum)
- configJson (JSON config for rule)
- errorMessage (error message template)
- successMessage (optional)
- requiresDependencyFilled (for placeholder resolution)
```

#### 5.2 Update LocationTaskHandler (Day 12 - 2 hours)

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java`

**Current validation flow** (lines 317-370):
```java
private ValidationResult validateLocation(Player player, Location location, TaskContext context) {
    // Parse validation context from InputJson
    WorldTaskValidationContext validationContext = 
        context.getValidationContext();
    
    // Execute each rule
    for (WorldTaskValidationRule rule : validationContext.getValidationRules()) {
        switch (rule.getValidationType()) {
            case "LocationInsideRegion":
                return validateLocationInsideRegion(player, location, rule);
            case "RegionContainment":
                // ... handle other types
        }
    }
    return ValidationResult.success("Location valid");
}
```

**Changes needed**:
1. If backend added new validation types, add corresponding handlers
2. If placeholder resolution pattern changed, update merge logic
3. If rule structure changed, update parsing

**Expected minimal changes**: ValidationLocation handler signatures may need adjustment to accept placeholder data

```java
// OLD signature
private ValidationResult validateLocationInsideRegion(Player player, Location location, JsonObject rule)

// NEW signature (if placeholders are passed)
private ValidationResult validateLocationInsideRegion(
    Player player, Location location, JsonObject rule, JsonObject placeholders)
```

#### 5.3 Update PlaceholderInterpolationUtil (Day 12-13 - 1 hour)

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/utils/PlaceholderInterpolationUtil.java`

**Check current implementation**:
```java
public static JsonObject mergePlaceholders(JsonObject... objects) {
    // Merges multiple placeholder maps
}

public static String interpolate(String template, JsonObject placeholders) {
    // Replaces {key} with value from placeholders map
}
```

**Potential updates**:
1. If backend placeholder format changed (e.g., nested structure), update merge logic
2. If placeholder keys changed (e.g., `townName` → `town.name`), update interpolation
3. Add any new placeholder types backend now supports

#### 5.4 Plugin Testing (Day 13 - 1 hour)

```bash
cd Repository/knk-plugin-v2

# Build
./gradlew build

# Run plugin validation tests
./gradlew :knk-core:test --tests "*Validation*"
./gradlew :knk-paper:test --tests "*LocationTaskHandler*"

# Manual testing
# [ ] LocationTaskHandler executes rules correctly
# [ ] Error messages show interpolated placeholders
# [ ] New validation types (if any) are recognized
```

**Checkpoint**: ✅ Plugin updated, tests pass, validation logic aligned

---

### PHASE 6: DEPLOYMENT (Days 14-15)

#### 6.1 Staging Deployment (Day 14 - 4 hours)

**Preparation**:
1. Build backend
2. Build frontend
3. Build plugin
4. Tag staging release

```bash
# Backend
cd Repository/knk-web-api-v2
dotnet publish -c Release

# Frontend
cd Repository/knk-web-app
npm run build

# Plugin
cd Repository/knk-plugin-v2
./gradlew :knk-paper:build
```

**Deploy to staging**:
```bash
# Deploy backend to staging
scp -r bin/Release/net8.0/publish/* staging:/var/www/knk-api/

# Deploy frontend
scp -r dist/* staging:/var/www/knk-app/

# Deploy plugin
scp knk-paper/build/libs/*.jar staging:/var/plugins/
```

**Smoke Test Checklist**:
- [ ] Backend API responds to health checks
- [ ] Frontend loads without errors
- [ ] Validation endpoint accepts requests
- [ ] Placeholder interpolation works
- [ ] Error messages display correctly
- [ ] Multi-rule validation passes/fails appropriately
- [ ] Plugin loads without errors
- [ ] LocationTaskHandler executes validation

**Monitoring**:
```
- API error rate (target: < 1% increase)
- Validation latency (target: within 10% baseline)
- Frontend console errors (target: 0 new)
- Plugin logs (target: no ERRORS)
```

#### 6.2 Production Deployment (Day 15 - 4 hours)

**Coordination**:
1. Schedule production window (off-peak)
2. Notify users of brief service interruption
3. Deploy backend first
4. Verify API health
5. Deploy frontend
6. Verify frontend loads
7. Deploy plugin updates to Minecraft server
8. Monitor production metrics

**Rollback Criteria** (when to activate backup tag):
```
IMMEDIATE ROLLBACK IF:
- API error rate > 5%
- Validation latency > 50% of baseline
- Critical validation rules failing unexpectedly
- Plugin crash on load
- Database corruption detected
```

**Rollback process**:
```bash
# If rollback needed:
git reset --hard backup-before-validation-consolidation
git push -f origin main

# Redeploy previous release
cd Repository/knk-web-api-v2
git checkout main
dotnet publish -c Release
# ... redeploy artifacts
```

**Post-Deployment Verification (Day 15)**:
- [ ] All endpoints respond
- [ ] Validation works end-to-end
- [ ] Placeholders interpolate correctly
- [ ] No error spikes in logs
- [ ] Performance metrics acceptable
- [ ] User feedback positive
- [ ] Plugin working on all servers

**Checkpoint**: ✅ Production deployment successful, migration complete

---

## Critical Path & Dependencies

```
Day 1-2: Preparation
    ↓
Day 3: Create IFieldValidationRuleService + Tests (BLOCKING)
    ↓
Day 4: Create FieldValidationRuleService (depends on Day 3)
    ↓
Day 5: Remove CRUD from ValidationService (depends on Day 4)
    ↓
Day 6-7: Enhance ValidationService + tests (depends on Day 5)
    ↓
Day 8: Update Controller & DI (depends on Day 7)
    ↓
Day 9: Delete FieldValidationService (depends on Day 8) ← All backend tests must pass
    ├─────────────────────────────────┐
    ↓                                 ↓
Day 10-11: Frontend Migration    Day 12-13: Plugin Update (parallel)
    ↓                                 ↓
    └─────────────────────────────────┘
                   ↓
            Day 14-15: Deployment
```

**Slack days**: None - timeline is tight but achievable

---

## Success Metrics

### Code Quality
- ✅ FieldValidationRuleService < 300 lines
- ✅ ValidationService < 600 lines  
- ✅ Test coverage 80%+
- ✅ Zero code duplication
- ✅ Zero compiler errors

### Functionality
- ✅ All CRUD ops work
- ✅ Validation execution works
- ✅ Placeholder interpolation works
- ✅ Multi-rule aggregation works
- ✅ Health checks work

### Performance
- ✅ API error rate: < 1% increase
- ✅ Validation latency: within 10% baseline
- ✅ Database queries: no N+1 issues
- ✅ Memory usage: acceptable

### Deployment
- ✅ Staging passes smoke tests
- ✅ Production deployment successful
- ✅ No critical post-deploy issues
- ✅ Rollback plan tested & ready

---

## Daily Stand-Up Template

```markdown
## Day [N] Standup - [Date]

### Completed
- [ ] Phase X.Y: [Task description]
- [ ] Phase X.Y: [Task description]

### In Progress
- [ ] Phase X.Y: [Task description]

### Blockers
- [ ] [Issue]: Blocking [Phase]

### Next Day
- [ ] Phase X.Y: [Task description]

### Metrics
- Build Status: [PASS/FAIL]
- Test Coverage: [%]
- Lines of Code: [Delta]
```

---

## Rollback Decision Matrix

| Severity | Metric | Threshold | Action |
|----------|--------|-----------|--------|
| CRITICAL | API error rate | > 5% | Immediate rollback |
| CRITICAL | Validation logic failure | > 0 | Immediate rollback |
| CRITICAL | Plugin crash | On startup | Immediate rollback |
| MAJOR | Latency increase | > 50% | Evaluate, possibly rollback |
| MAJOR | Test coverage drop | < 75% | Hold, fix, retry |
| MINOR | New compiler warning | Any | Document, continue |
| MINOR | Frontend console warning | Any | Document, continue |

---

## Post-Migration Documentation

After successful deployment, create:

1. **MIGRATION_COMPLETION_REPORT.md**
   - What was accomplished
   - Timeline actual vs planned
   - Issues encountered + resolutions
   - Lessons learned

2. **ARCHITECTURE_DIAGRAM_POST_MIGRATION.md**
   - New service boundaries
   - Dependencies
   - API contract changes (if any)

3. **DEVELOPER_ONBOARDING_UPDATE.md**
   - New service orientation
   - Rule management workflow
   - Validation execution flow
   - Common issues & troubleshooting

---

## Contact & Escalation

| Role | Name | Contact | Availability |
|------|------|---------|--------------|
| Migration Lead | [TBD] | [TBD] | [TBD] |
| Backend Owner | [TBD] | [TBD] | [TBD] |
| Frontend Owner | [TBD] | [TBD] | [TBD] |
| Plugin Owner | [TBD] | [TBD] | [TBD] |
| DevOps | [TBD] | [TBD] | [TBD] |

**Escalation Path**:
- Day 1-5 issues → Migration Lead
- Code review issues → Backend/Frontend/Plugin Owner
- Deployment issues → DevOps
- Go/no-go decisions → Tech lead + Product

---

## Appendix: Command Reference

### Git Commands
```bash
# Feature branch
git checkout -b feature/validation-service-consolidation
git push -u origin feature/validation-service-consolidation
git tag backup-before-validation-consolidation
git push origin backup-before-validation-consolidation

# Rollback (if needed)
git reset --hard backup-before-validation-consolidation
git push -f origin main
```

### Build Commands
```bash
# Backend
cd Repository/knk-web-api-v2
dotnet clean
dotnet build
dotnet test
dotnet publish -c Release

# Frontend
cd Repository/knk-web-app
npm install
npm run build
npm test

# Plugin
cd Repository/knk-plugin-v2
./gradlew clean build
./gradlew :knk-paper:build
./gradlew :knk-core:test
```

### Search Commands
```bash
# Find all IFieldValidationService references
Select-String -Pattern "IFieldValidationService" -Path "**/*.cs" -Recurse

# Find all validation test files
Get-ChildItem -Path "**/*ValidationTests.cs" -Recurse

# Find all API calls
grep -r "field-validation-rules" Repository/knk-web-app/src/
```

### Code Coverage
```bash
# Generate coverage report
dotnet test /p:CollectCoverage=true /p:CoverageFormat=opencover

# View coverage
# Open: Repository/knk-web-api-v2/coverage.opencover.xml in coverage viewer
```

---

**Last Updated**: February 16, 2026  
**Status**: Ready for execution  
**Approval Status**: ⏳ Awaiting sign-off
