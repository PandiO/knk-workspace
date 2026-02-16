# Migration Master Checklist & Reference Guide

**For**: Migration Option B - Validation Service Consolidation  
**Users**: Copilot, Backend Engineer, Frontend Engineer, Plugin Developer  
**Purpose**: Single source of truth for implementation, preventing missed files/code/orphaned logic

---

## Pre-Implementation: Setup & Planning

### Day 1: Git & Planning
- [ ] Create feature branch: `git checkout -b feature/validation-service-consolidation`
- [ ] Create backup tag: `git tag backup-before-validation-consolidation`
- [ ] Review [FRONTEND_BACKEND_WIRING_GUIDE.md](./FRONTEND_BACKEND_WIRING_GUIDE.md) - Complete wiring documentation
- [ ] Review [IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md) - Phase-by-phase guide
- [ ] Assign owners: Backend, Frontend, Plugin, DevOps
- [ ] Create baseline snapshot document

---

## Phase 1: Backend Extraction (Days 3-4)

### 1.1 Create FieldValidationRuleService Interface

**File**: `Services/Interfaces/IFieldValidationRuleService.cs` (CREATE)

```csharp
public interface IFieldValidationRuleService
{
    // CRUD Operations
    Task<FieldValidationRuleReadDto> GetByIdAsync(int ruleId);
    Task<IEnumerable<FieldValidationRuleReadDto>> GetByFieldAsync(int fieldId);
    Task<FieldValidationRuleReadDto> CreateAsync(FieldValidationRuleCreateDto dto);
    Task<FieldValidationRuleReadDto> UpdateAsync(int ruleId, FieldValidationRuleUpdateDto dto);
    Task DeleteAsync(int ruleId);
    
    // Health Check Methods
    Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId);
    Task<bool> ValidateDraftConfigurationAsync(int draftId);
    
    // Dependency Analysis
    Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData);
}
```

**Verification**:
- [ ] File created at correct path
- [ ] All method signatures match source (ValidationService.cs)
- [ ] DTOs imported correctly

---

### 1.2 Create FieldValidationRuleService Implementation

**File**: `Services/FieldValidationRuleService.cs` (CREATE)

**Source Code Location**: Extract from [ValidationService.cs](../../../Repository/knk-web-api-v2/Services/ValidationService.cs)

**Methods to Extract** (Copy these exact line ranges):
- [ ] Lines 40-45: `GetByIdAsync(int id)`
- [ ] Lines 47-51: `GetByFormFieldIdAsync(int fieldId)`  
- [ ] Lines 53-57: `GetByFormConfigurationIdAsync(int formConfigurationId)`
- [ ] Lines 82-90: `CreateAsync(CreateFieldValidationRuleDto dto)`
- [ ] Lines 92-115: `UpdateAsync(int id, UpdateFieldValidationRuleDto dto)`
- [ ] Lines 117-124: `DeleteAsync(int id)`
- [ ] Lines 426-540: `ValidateConfigurationHealthAsync(...)` and `ValidateDraftConfigurationAsync(...)`
- [ ] Dependency resolution method (identify exact lines in ValidationService)

**Constructor Signature**:
```csharp
public FieldValidationRuleService(
    IFieldValidationRuleRepository repository,
    IFieldRepository fieldRepository,
    ILogger<FieldValidationRuleService> logger)
```

**Field Declarations**:
```csharp
private readonly IFieldValidationRuleRepository _repository;
private readonly IFieldRepository _fieldRepository;
private readonly ILogger<FieldValidationRuleService> _logger;
```

**Verification**:
- [ ] All methods copied accurately
- [ ] Constructor signature correct
- [ ] All dependencies injected
- [ ] Compiles with no errors
- [ ] Target: < 300 lines

---

### 1.3 Create Unit Tests for FieldValidationRuleService

**File**: `Tests/Services/FieldValidationRuleServiceTests.cs` (CREATE)

**Test Coverage** (25+ tests, target 80%+ coverage):

**CRUD Tests** (8 tests):
- [ ] `GetByIdAsync_WithValidId_ReturnsRule`
- [ ] `GetByIdAsync_WithInvalidId_ThrowsNotFoundException`
- [ ] `GetByFieldAsync_ReturnsAllRulesForField`
- [ ] `CreateAsync_WithValidDto_ReturnsCreatedRule`
- [ ] `CreateAsync_WithDuplicateRule_ThrowsConflictException`
- [ ] `UpdateAsync_WithValidDto_ReturnsUpdatedRule`
- [ ] `DeleteAsync_WithValidId_RemovesRule`
- [ ] `DeleteAsync_WithReferencedRule_ThrowsDependencyException`

**Health Check Tests** (6 tests):
- [ ] `ValidateConfigurationHealthAsync_AllRulesHealthy_ReturnsHealthy`
- [ ] `ValidateConfigurationHealthAsync_WithOrphanedRules_ReturnsWarning`
- [ ] `ValidateConfigurationHealthAsync_WithBrokenReferences_ReturnsFailed`
- [ ] `ValidateDraftConfigurationAsync_ValidDraft_ReturnsTrue`
- [ ] `ValidateDraftConfigurationAsync_InvalidDraft_ReturnsFalse`
- [ ] `ValidateDraftConfigurationAsync_EmptyDraft_ReturnsTrue`

**Dependency Resolution Tests** (6+ tests):
- [ ] `ResolveDependenciesAsync_WithMatchingDependencies_ReturnsResolved`
- [ ] `ResolveDependenciesAsync_WithMissingDependencies_ThrowsMissingDependencyException`
- [ ] Add tests for circular dependencies
- [ ] Add tests for missing repository data

**Verification**:
- [ ] Run: `dotnet test Tests/Services/FieldValidationRuleServiceTests.cs`
- [ ] All tests pass
- [ ] Coverage >= 80% (check with: `dotnet test --collect:"XPlat Code Coverage"`)

---

## Phase 2: Backend Enhancement (Days 5-7)

### 2.1 Remove CRUD from IValidationService

**File**: `Services/Interfaces/IValidationService.cs` (MODIFY)

**Methods to DELETE** from interface:
```csharp
// DELETE THESE:
Task<FieldValidationRuleReadDto> GetByIdAsync(int id);
Task<IEnumerable<FieldValidationRuleReadDto>> GetByFormFieldIdAsync(int fieldId);
Task<IEnumerable<FieldValidationRuleReadDto>> GetByFormConfigurationIdAsync(int formConfigId);
Task<FieldValidationRuleReadDto> CreateAsync(CreateFieldValidationRuleCreateDto dto);
Task UpdateAsync(int id, UpdateFieldValidationRuleDto dto);
Task DeleteAsync(int id);
Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId);
Task<bool> ValidateDraftConfigurationAsync(int draftId);
Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData);

// KEEP THESE:
Task<ValidationResultDto> ValidateFieldAsync(...);
```

**Verification**:
- [ ] Only 2-3 methods remain in IValidationService
- [ ] Compiles with no errors
- [ ] Methods moved to IFieldValidationRuleService

---

### 2.2 Remove CRUD Methods from ValidationService Implementation

**File**: `Services/ValidationService.cs` (MODIFY)

**Line Ranges to DELETE**:
- [ ] Lines 40-57: All GetBy* methods (~18 lines)
- [ ] Lines 82-90: CreateAsync (~10 lines)
- [ ] Lines 92-115: UpdateAsync (~25 lines)
- [ ] Lines 117-124: DeleteAsync (~10 lines)
- [ ] Lines 426-540: Health check methods (~115 lines)
- [ ] Dependency resolution method (~25 lines)

**Total Deletion**: ~200 lines

**After**:
- ValidationService should be ~400-500 lines (down from 663)
- Focus: Validation execution only

**Verification**:
- [ ] No compile errors
- [ ] Method count: ~5-8 methods (was 23)
- [ ] All CRUD logic removed

---

### 2.3 Enhance ValidationService.ExecuteValidationRuleAsync

**File**: `Services/ValidationService.cs` (MODIFY)

**Current Method** (locate exact lines):
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule,
    object? fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null)
```

**Updated Signature**:
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule,
    object? fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null,
    Dictionary<string, object>? resolvedPlaceholders = null)  // ← ADD
```

**Implementation Changes**:
- [ ] Add parameter to method
- [ ] Pass `resolvedPlaceholders` to validator
- [ ] Return placeholders in result

**Verification**:
- [ ] Method compiles
- [ ] Validators receive placeholder parameter
- [ ] Tests pass

---

### 2.4 Enhance ValidationService.ValidateFieldAsync with Placeholder Aggregation

**File**: `Services/ValidationService.cs` (MODIFY)

**Current Implementation** (locate):
```csharp
public async Task<ValidationResultDto> ValidateFieldAsync(
    int fieldId,
    object? fieldValue,
    object? dependencyValue,
    Dictionary<string, object>? formContextData)
{
    var rules = await _ruleRepository.GetByFormFieldIdAsync(fieldId);
    foreach (var rule in rules)
    {
        var result = await ExecuteValidationRuleAsync(rule, fieldValue, _validators, formContextData);
        if (!result.IsValid && result.IsBlocking)
            return result;
    }
    return new ValidationResultDto { IsValid = true };
}
```

**Enhanced Implementation**:
```csharp
public async Task<ValidationResultDto> ValidateFieldAsync(
    int fieldId,
    object? fieldValue,
    object? dependencyValue,
    Dictionary<string, object>? formContextData)
{
    var rules = await _ruleRepository.GetByFormFieldIdAsync(fieldId);
    var allPlaceholders = new Dictionary<string, object>();  // ← ADD
    
    foreach (var rule in rules)
    {
        // NEW: Resolve placeholders for this rule
        var rulePlaceholders = await ResolvePlaceholdersForRuleAsync(rule, formContextData);
        
        // ENHANCED: Pass placeholders to executor
        var result = await ExecuteValidationRuleAsync(
            rule, fieldValue, _validators, formContextData, rulePlaceholders);  // ← PASS PLACEHOLDERS
        
        // NEW: Aggregate placeholders
        foreach (var kv in rulePlaceholders)  // ← MERGE
        {
            if (!allPlaceholders.ContainsKey(kv.Key))
                allPlaceholders[kv.Key] = kv.Value;
        }
        
        // ENHANCED: Include placeholders in failure
        if (!result.IsValid && result.IsBlocking)
            return new ValidationResultDto 
            { 
                IsValid = false, 
                Message = result.Message,
                Placeholders = allPlaceholders  // ← INCLUDE
            };
    }
    
    // ENHANCED: Return aggregated placeholders
    return new ValidationResultDto 
    { 
        IsValid = true,
        Placeholders = allPlaceholders  // ← INCLUDE
    };
}
```

**Verification**:
- [ ] Method compiles
- [ ] Placeholders aggregated correctly
- [ ] Tests verify placeholder inclusion

---

### 2.5 Create ResolvePlaceholdersForRuleAsync Method

**File**: `Services/ValidationService.cs` (ADD NEW METHOD)

```csharp
private async Task<Dictionary<string, object>> ResolvePlaceholdersForRuleAsync(
    FieldValidationRule rule,
    Dictionary<string, object>? contextData)
{
    if (!rule.RequiresDependencyFilled)
        return new Dictionary<string, object>();
    
    return await _placeholderResolutionService.ResolveAllLayersAsync(
        rule.FieldId,
        contextData);
}
```

**Verification**:
- [ ] Method compiles
- [ ] Correctly resolves placeholders only when needed
- [ ] Handles null contextData gracefully

---

### 2.6 Add ValidateFieldWithPlaceholdersAsync to IValidationService & Implementation

**File**: `Services/Interfaces/IValidationService.cs` (ADD)

```csharp
Task<FieldValidationResultDto> ValidateFieldWithPlaceholdersAsync(
    int fieldId,
    object? fieldValue,
    Dictionary<string, object> contextData);
```

**File**: `Services/ValidationService.cs` (ADD)

```csharp
public async Task<FieldValidationResultDto> ValidateFieldWithPlaceholdersAsync(
    int fieldId,
    object? fieldValue,
    Dictionary<string, object> contextData)
{
    var rules = await _ruleRepository.GetByFormFieldIdAsync(fieldId);
    var allPlaceholders = new Dictionary<string, object>();
    
    foreach (var rule in rules)
    {
        var rulePlaceholders = await ResolvePlaceholdersForRuleAsync(rule, contextData);
        var result = await ExecuteValidationRuleAsync(rule, fieldValue, _validators, contextData, rulePlaceholders);
        
        foreach (var kv in rulePlaceholders)
        {
            if (!allPlaceholders.ContainsKey(kv.Key))
                allPlaceholders[kv.Key] = kv.Value;
        }
        
        if (!result.IsValid)
            return new FieldValidationResultDto 
            { 
                IsValid = false, 
                Error = result.Message,
                Placeholders = allPlaceholders 
            };
    }
    
    return new FieldValidationResultDto 
    { 
        IsValid = true,
        Placeholders = allPlaceholders 
    };
}
```

**Verification**:
- [ ] Method compiles
- [ ] Tests verify placeholder aggregation

---

### 2.7 Update ValidationService Tests

**File**: `Tests/Services/ValidationServiceTests.cs` (MODIFY)

**Tests to DELETE** (CRUD operations moved to FieldValidationRuleService):
- [ ] GetByIdAsync_*
- [ ] GetByFormFieldIdAsync_*
- [ ] CreateAsync_*
- [ ] UpdateAsync_*
- [ ] DeleteAsync_*
- [ ] ValidateConfigurationHealthAsync_*
- [ ] ValidateDraftConfigurationAsync_*

**Tests to KEEP** (Validation execution):
- [ ] ValidateFieldAsync_SingleRulePass_ReturnsSuccess
- [ ] ValidateFieldAsync_MultiRuleFirstFails_ReturnsFirstFailure
- [ ] ValidateFieldAsync_AllRulesFail_ReturnsFirstBlocking
- [ ] (keep all existing validation tests)

**Tests to ADD** (Placeholder aggregation):
- [ ] ValidateFieldAsync_WithPlaceholders_ReturnsInterpolatedMessage
- [ ] ValidateFieldAsync_MultiRule_AggregatesAllPlaceholders
- [ ] ValidateFieldAsync_FirstRuleFails_ReturnsPartialPlaceholders
- [ ] ValidateFieldWithPlaceholdersAsync_AllRulesPass_CollectsAllPlaceholders
- [ ] ResolvePlaceholdersForRuleAsync_RequiresDependency_Resolves
- [ ] ResolvePlaceholdersForRuleAsync_NoRequirement_ReturnsEmpty
- [ ] ExecuteValidationRuleAsync_WithPlaceholders_PassesToValidator

**Target**: 30+ tests, 80%+ coverage

**Verification**:
- [ ] Run: `dotnet test Tests/Services/ValidationServiceTests.cs`
- [ ] All tests pass
- [ ] Coverage >= 80%

---

## Phase 3: Dependency Injection Update (Day 7)

### 3.1 Update ServiceCollectionExtensions

**File**: `DependencyInjection/ServiceCollectionExtensions.cs` (MODIFY)

**Find location**: Search for `AddValidationServices` method

**Current**:
```csharp
services.AddScoped<IValidationService, ValidationService>();
services.AddScoped<IFieldValidationService, FieldValidationService>();  // ← DELETE
```

**Updated**:
```csharp
services.AddScoped<IValidationService, ValidationService>();
services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>();  // ← ADD
services.AddScoped<IFieldValidationRuleRepository, FieldValidationRuleRepository>();
services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>();
services.AddScoped<IDependencyResolutionService, DependencyResolutionService>();
services.AddScoped<IPathResolutionService, IPathResolutionService>();
```

**Verification**:
- [ ] Compile: `dotnet build`
- [ ] No errors about missing services
- [ ] IFieldValidationRuleService properly registered

---

## Phase 4: Controller Update (Day 8)

### 4.1 Update FieldValidationRulesController Constructor

**File**: `Controllers/FieldValidationRulesController.cs` (MODIFY)

**Current Constructor** (lines ~23-31):
```csharp
public FieldValidationRulesController(
    IValidationService service,
    IPlaceholderResolutionService placeholderService,
    IFieldValidationService fieldValidationService,  // ← REMOVE
    IFieldValidationRuleRepository ruleRepository,   // ← REMOVE
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _service = service;
    _placeholderService = placeholderService;
    _fieldValidationService = fieldValidationService;  // ← REMOVE
    _ruleRepository = ruleRepository;  // ← REMOVE
    _dependencyService = dependencyService;
    _pathService = pathService;
}
```

**Updated Constructor**:
```csharp
public FieldValidationRulesController(
    IValidationService validationService,
    IFieldValidationRuleService ruleService,  // ← ADD
    IPlaceholderResolutionService placeholderService,
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _validationService = validationService;
    _ruleService = ruleService;  // ← ADD
    _placeholderService = placeholderService;
    _dependencyService = dependencyService;
    _pathService = pathService;
}
```

**Field Members**:
- [ ] Remove: `private IFieldValidationService _fieldValidationService;`
- [ ] Remove: `private IFieldValidationRuleRepository _ruleRepository;`
- [ ] Add: `private IFieldValidationRuleService _ruleService;`

**Verification**:
- [ ] Compile: `dotnet build`
- [ ] Constructor signature correct
- [ ] All fields initialized

---

### 4.2 Update Health Check Endpoints

**File**: `Controllers/FieldValidationRulesController.cs` (MODIFY - 2 endpoints)

**Endpoint 1**: ValidateConfigurationHealth (locate ~line 221)

**Current**:
```csharp
[HttpGet("health-check/configuration/{configId:int}")]
public async Task<IActionResult> ValidateConfigurationHealth(int configId)
{
    try
    {
        var issues = await _service.ValidateConfigurationHealthAsync(configId);  // ← CHANGE
        return Ok(issues);
    }
    //...
}
```

**Updated**:
```csharp
[HttpGet("health-check/configuration/{configId:int}")]
public async Task<IActionResult> ValidateConfigurationHealth(int configId)
{
    try
    {
        var issues = await _ruleService.ValidateConfigurationHealthAsync(configId);  // ← CHANGE
        return Ok(issues);
    }
    //...
}
```

**Endpoint 2**: ValidateDraftConfiguration (locate ~line 234)

**Current**:
```csharp
[HttpPost("health-check/configuration/draft")]
public async Task<IActionResult> ValidateDraftConfiguration([FromBody] FormConfigurationDto configDto)
{
    try
    {
        if (configDto == null) return BadRequest(new { message = "Configuration data is required" });
        
        var issues = await _service.ValidateDraftConfigurationAsync(configDto);  // ← CHANGE
        return Ok(issues);
    }
    //...
}
```

**Updated**:
```csharp
[HttpPost("health-check/configuration/draft")]
public async Task<IActionResult> ValidateDraftConfiguration([FromBody] FormConfigurationDto configDto)
{
    try
    {
        if (configDto == null) return BadRequest(new { message = "Configuration data is required" });
        
        var issues = await _ruleService.ValidateDraftConfigurationAsync(configDto);  // ← CHANGE
        return Ok(issues);
    }
    //...
}
```

**Verification**:
- [ ] Compile: `dotnet build`
- [ ] Both endpoints route to correct service
- [ ] Tests verify routing

---

### 4.3 DELETE Deprecated Endpoint

**File**: `Controllers/FieldValidationRulesController.cs` (DELETE)

**Endpoint**: ValidateFieldRule (locate ~lines 172-200)

```csharp
// DELETE ENTIRE METHOD:
[HttpPost("/api/field-validations/validate-field")]
public async Task<IActionResult> ValidateFieldRule([FromBody] ValidateFieldRuleRequestDto request)
{
    // ... delete all lines
}
```

**Reason**: Duplicates functionality - use `/api/field-validation-rules/validate` instead

**Verification**:
- [ ] Endpoint removed
- [ ] Compile: `dotnet build`
- [ ] No remaining references to this endpoint

---

### 4.4 Update Controller Tests

**File**: `Tests/Controllers/FieldValidationRulesControllerTests.cs` (MODIFY)

**Test Setup Changes**:
```csharp
// BEFORE
var mockFieldValidationService = new Mock<IFieldValidationService>();

// AFTER
var mockRuleService = new Mock<IFieldValidationRuleService>();
```

**Constructor Mock Setup**:
```csharp
// BEFORE
var controller = new FieldValidationRulesController(
    mockValidationService.Object,
    mockPlaceholderService.Object,
    mockFieldValidationService.Object,  // ← REMOVE
    mockRuleRepository.Object,  // ← REMOVE
    mockDependencyService.Object,
    mockPathService.Object);

// AFTER
var controller = new FieldValidationRulesController(
    mockValidationService.Object,
    mockRuleService.Object,  // ← ADD
    mockPlaceholderService.Object,
    mockDependencyService.Object,
    mockPathService.Object);
```

**Tests to Update/Delete**:
- [ ] ValidateConfigurationHealth_CallsService - update to use `mockRuleService`
- [ ] ValidateDraftConfiguration_CallsService - update to use `mockRuleService`
- [ ] ValidateFieldRule_* - DELETE (endpoint removed)

**Verification**:
- [ ] Run: `dotnet test Tests/Controllers/FieldValidationRulesControllerTests.cs`
- [ ] All tests pass

---

## Phase 5: Cleanup & Verification (Day 9)

### 5.1 Delete FieldValidationService

**File**: `Services/FieldValidationService.cs` (DELETE ENTIRE FILE)

```bash
# Verify before deleting:
Select-String -Pattern "FieldValidationService" -Path "**/*.cs" -Exclude "FieldValidationRuleService*"
# Should only show this file

# Delete
Remove-Item Services/FieldValidationService.cs
```

**Verification**:
- [ ] File deleted
- [ ] No compile errors

---

### 5.2 Delete IFieldValidationService Interface

**File**: `Services/Interfaces/IFieldValidationService.cs` (DELETE ENTIRE FILE)

```bash
Remove-Item Services/Interfaces/IFieldValidationService.cs
```

**Verification**:
- [ ] File deleted
- [ ] No compile errors

---

### 5.3 Delete FieldValidationService Tests

**File**: `Tests/Services/FieldValidationServiceTests.cs` (DELETE ENTIRE FILE)

```bash
Remove-Item Tests/Services/FieldValidationServiceTests.cs
```

**Verification**:
- [ ] File deleted
- [ ] No test runner errors

---

### 5.4 Verify Zero References to Deleted Code

```bash
cd Repository/knk-web-api-v2

# Search for deprecated service (should return 0 matches)
Select-String -Pattern "IFieldValidationService|FieldValidationService" -Path "**/*.cs" -Recurse

# Result should be: No matches found

# Also verify ValidateFieldRule endpoint is deleted
Select-String -Pattern "ValidateFieldRule" -Path "**/*.cs"

# Result should be: No matches
```

**Verification Checklist**:
- [ ] `IFieldValidationService`: 0 references remaining
- [ ] `FieldValidationService`: 0 references remaining (except class name itself)
- [ ] `/api/field-validations/validate-field`: 0 references remaining
- [ ] `ValidateFieldRule` method: 0 references

---

### 5.5 Full Build & Test Verification

```bash
cd Repository/knk-web-api-v2

# Clean build
dotnet clean
dotnet build

# Run all validation tests
dotnet test Tests/Services/ValidationServiceTests.cs
dotnet test Tests/Services/FieldValidationRuleServiceTests.cs
dotnet test Tests/Controllers/FieldValidationRulesControllerTests.cs
dotnet test Tests/Integration/PlaceholderResolutionIntegrationTests.cs

# Code coverage (all validation)
dotnet test /p:CollectCoverage=true

# Check test results
dotnet test -v q  # quiet mode - just pass/fail
```

**Success Criteria**:
- [ ] Build: 0 errors, 0 warnings (regarding validation code)
- [ ] Tests: All pass (100%)
- [ ] Coverage: 80%+ for validation services
- [ ] No orphaned code

---

## Phase 6: Frontend Migration (Days 10-11)

### 6.1 Update ValidationResultDto Type

**File**: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (MODIFY)

**Current** (lines ~60-66):
```typescript
export interface ValidationResultDto {
    isValid: boolean;
    isBlocking: boolean;
    message?: string;
    successMessage?: string;
    metadata?: ValidationMetadataDto;
}
```

**Updated**:
```typescript
export interface ValidationResultDto {
    isValid: boolean;
    isBlocking: boolean;
    message?: string;
    successMessage?: string;
    placeholders?: { [key: string]: any };  // ← ADD THIS LINE
    metadata?: ValidationMetadataDto;
}
```

**Verification**:
- [ ] Type updated
- [ ] Frontend: `npm run build` - 0 TypeScript errors
- [ ] No breaking changes to existing code

---

### 6.2 Update FormWizard Component

**File**: `src/components/FormWizard.tsx` (INTEGRATE PLACEHOLDERS)

**Locate**: Validation call handler (search for `fieldValidationRuleClient.validateField`)

**Current Pattern**:
```typescript
const result = await fieldValidationRuleClient.validateField({
    fieldId,
    fieldValue: value,
    formContextData: context
});
setFieldError(fieldId, result.message);
```

**Updated Pattern**:
```typescript
const result = await fieldValidationRuleClient.validateField({
    fieldId,
    fieldValue: value,
    formContextData: context
});

// NEW: Interpolate placeholders
let displayMessage = result.message || '';
if (result.placeholders && result.message) {
    displayMessage = interpolatePlaceholders(result.message, result.placeholders);
}

setFieldError(fieldId, displayMessage);

// OPTIONAL: Store for other components
if (result.placeholders) {
    setResolvedPlaceholders(result.placeholders);
}
```

**Helper Function** (add to FormWizard.tsx):
```typescript
function interpolatePlaceholders(template: string, placeholders: Record<string, any>): string {
    let result = template;
    for (const [key, value] of Object.entries(placeholders)) {
        result = result.replace(`{${key}}`, String(value));
    }
    return result;
}
```

**Verification**:
- [ ] Build: `npm run build` - 0 errors
- [ ] Tests: Validation tests pass
- [ ] Manual: Placeholders display correctly in errors

---

### 6.3 Update WorldBoundFieldRenderer Component

**File**: `src/components/Workflow/WorldBoundFieldRenderer.tsx` (INTEGRATE PLACEHO LDERS)

**Locate**: Validation result rendering (search for `ValidationResultDto`)

**Current Pattern**:
```typescript
const renderValidationResult = (result: ValidationResultDto) => {
    return <div className="error">{result.message}</div>;
};
```

**Updated Pattern**:
```typescript
const renderValidationResult = (result: ValidationResultDto) => {
    let displayMessage = result.message;
    if (result.placeholders && result.message) {
        displayMessage = interpolatePlaceholders(result.message, result.placeholders);
    }
    return <div className="error">{displayMessage}</div>;
};

function interpolatePlaceholders(template: string, placeholders: Record<string, any>): string {
    let result = template;
    for (const [key, value] of Object.entries(placeholders)) {
        result = result.replace(`{${key}}`, String(value));
    }
    return result;
}
```

**Verification**:
- [ ] Build: `npm run build` - 0 errors
- [ ] Component renders correctly
- [ ] Placeholders display in messages

---

### 6.4 Frontend Build & Test

```bash
cd Repository/knk-web-app

# Build
npm run build

# Tests
npm test -- --testPathPattern="validation|fieldValidation"

# Manual
npm start  # Test in browser
```

**Verification**:
- [ ] Zero TypeScript errors
- [ ] Zero build errors
- [ ] All tests pass
- [ ] No console errors

---

## Phase 7: Plugin Alignment (Days 12-13)

### 7.1 Verify Plugin DTO Alignment

**File**: `knk-core/src/main/java/net/knightsandkings/knk/core/domain/validation/WorldTaskValidationRule.java` (VERIFY)

**Check Fields**:
- [ ] `validationType`: String - ✅ exists
- [ ] `configJson`: String - ✅ exists
- [ ] `errorMessage`: String - ✅ exists
- [ ] `successMessage`: String - ✅ exists
- [ ] `isBlocking`: boolean - ✅ exists
- [ ] `requiresDependencyFilled`: boolean - ✅ exists

**Verification**:
- [ ] All fields match backend `FieldValidationRule`
- [ ] No additional backend fields missing
- [ ] JSON serialization works

---

### 7.2 Update LocationTaskHandler

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java` (UPDATE)

**Locate**: `validateLocation()` method (~line 317)

**Current Signature**:
```java
private ValidationResult validateLocation(Player player, Location location, TaskContext context)
```

**Updated Signature**:
```java
private ValidationResult validateLocation(Player player, Location location, TaskContext context) {
    WorldTaskValidationContext validationContext = context.getValidationContext();
    
    // NEW: Extract backend-resolved placeholders
    JsonObject backendPlaceholders = validationContext.getPlaceholders();
    
    for (WorldTaskValidationRule rule : validationContext.getValidationRules()) {
        switch (rule.getValidationType()) {
            case "LocationInsideRegion":
                // UPDATED: Pass placeholders
                return validateLocationInsideRegion(player, location, rule, backendPlaceholders);
            // ... other cases updated similarly
        }
    }
    return ValidationResult.success("Location valid");
}
```

**Update Handler Methods** - All validation methods should accept placeholders:

```java
// BEFORE
private ValidationResult validateLocationInsideRegion(
    Player player, Location location, JsonObject rule)

// AFTER
private ValidationResult validateLocationInsideRegion(
    Player player, Location location, JsonObject rule, JsonObject backendPlaceholders)  // ← ADD
{
    // Use backendPlaceholders in validation logic
    // ...
}
```

**Update ALL Handler Method Signatures**:
- [ ] `validateLocationInsideRegion()`
- [ ] `validateLocationInsideRegionAsync()` (if exists)
- [ ] `validateRegionContainment()`
- [ ] Any other validation handlers

**Verification**:
- [ ] All handler signatures updated
- [ ] Compile: `./gradlew build`
- [ ] No errors

---

### 7.3 Update PlaceholderInterpolationUtil

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/utils/PlaceholderInterpolationUtil.java` (VERIFY/ENHANCE)

**Current Methods**:
```java
public static JsonObject mergePlaceholders(JsonObject... objects)
public static String interpolate(String template, JsonObject placeholders)
```

**Verify Implementation**:
- [ ] `mergePlaceholders()` handles multiple sources correctly
- [ ] `interpolate()` replaces all `{key}` patterns
- [ ] Both handle null/empty objects gracefully

**Possible Enhancement** (if needed):
```java
public static String interpolate(String template, JsonObject... placeholderSources) {
    if (template == null || template.isEmpty()) return template;
    
    // Merge all placeholder sources with priority
    JsonObject allPlaceholders = new JsonObject();
    for (JsonObject obj : placeholderSources) {
        if (obj != null) {
            mergePlaceholders(allPlaceholders, obj);
        }
    }
    
    // Interpolate
    String result = template;
    for (String key : allPlaceholders.keySet()) {
        String value = allPlaceholders.get(key).getAsString();
        result = result.replace("{" + key + "}", value);
    }
    return result;
}

private static JsonObject mergePlaceholders(JsonObject target, JsonObject source) {
    source.entrySet().forEach(entry -> {
        if (!target.has(entry.getKey())) {
            target.add(entry.getKey(), entry.getValue());
        }
    });
    return target;
}
```

**Verification**:
- [ ] Methods work with new placeholder structure
- [ ] Handles backend + local placeholders
- [ ] No null pointer exceptions

---

### 7.4 Plugin Build & Test

```bash
cd Repository/knk-plugin-v2

# Build
./gradlew clean build

# Plugin tests
./gradlew :knk-core:test --tests "*Validation*"
./gradlew :knk-paper:test --tests "*LocationTaskHandler*"
./gradlew :knk-paper:test --tests "*PlaceholderInterpolation*"
```

**Verification**:
- [ ] Build: 0 errors
- [ ] All tests pass
- [ ] No regressions

---

## Phase 8: Deployment (Days 14-15)

### 8.1 Staging Deployment

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

# Deploy and smoke test (see IMPLEMENTATION_ROADMAP for details)
```

**Smoke Test Checklist**:
- [ ] Backend API health check passes
- [ ] POST /api/field-validation-rules/validate returns ValidationResultDto with placeholders
- [ ] Frontend loads without console errors
- [ ] Validation messages display with interpolated placeholders
- [ ] Plugin loads on Minecraft server
- [ ] LocationTaskHandler executes without errors

---

### 8.2 Production Deployment

**Pre-deployment**:
- [ ] All staging tests pass
- [ ] Performance baseline established
- [ ] Rollback plan reviewed with team
- [ ] Deployment window scheduled

**Deployment**:
- [ ] Deploy backend
- [ ] Verify API health
- [ ] Deploy frontend
- [ ] Verify frontend loads
- [ ] Restart Minecraft servers with updated plugin

**Monitoring**:
- [ ] API error rate: < 1% increase
- [ ] Validation latency: within 10% baseline
- [ ] No critical console errors
- [ ] Plugin logs clean

---

## Post-Implementation Verification

### Code Quality Checks
- [ ] `dotnet build` returns 0 errors (backend)
- [ ] `npm run build` returns 0 errors (frontend)
- [ ] `./gradlew build` returns 0 errors (plugin)
- [ ] Code coverage: 80%+ for validation services
- [ ] No warnings in build output (validation code only)

### Functional Verification
- [ ] All CRUD endpoints work (GET, POST, PUT, DELETE)
- [ ] Validation execution works (multi-rule aggregation)
- [ ] Placeholder interpolation works (frontend & plugin)
- [ ] Health checks work (configuration validation)
- [ ] Dependency resolution works

### Database Verification
- [ ] No orphaned validation rules
- [ ] All rules referenced by fields
- [ ] No broken circular dependencies

### Reference Search Verification
```bash
# Should return 0 matches:
Select-String -Pattern "IFieldValidationService|FieldValidationService" -Path "**/*.cs" -Recurse
Select-String -Pattern "ValidateFieldRule" -Path "**/*.cs" -Recurse
Select-String -Pattern "/api/field-validations/validate-field" -Path "**/*" -Recurse

# Should return matches only in new service:
Select-String -Pattern "IFieldValidationRuleService|FieldValidationRuleService" -Path "**/*.cs" -Recurse
```

---

## Documentation Updates (Post-Migration)

- [ ] Create MIGRATION_COMPLETION_REPORT.md
- [ ] Update ARCHITECTURE_DIAGRAM_POST_MIGRATION.md
- [ ] Update DEVELOPER_ONBOARDING_UPDATE.md
- [ ] Update API documentation (if exists)
- [ ] Document lessons learned

---

## Sign-Off

- [ ] Backend Engineer: Code review completed
- [ ] Frontend Engineer: Code review completed
- [ ] Plugin Developer: Code review completed
- [ ] QA: Testing completed
- [ ] DevOps: Deployment successful
- [ ] Product: Feature sign-off

---

**Document Version**: 1.0  
**Created**: February 16, 2026  
**Last Updated**: February 16, 2026  
**Status**: Ready for Implementation

**Related Documents**:
- [IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md) - Phase-by-phase timeline
- [FRONTEND_BACKEND_WIRING_GUIDE.md](./FRONTEND_BACKEND_WIRING_GUIDE.md) - Detailed wiring guide
- [MIGRATION_OPTION_B_QUICK_REFERENCE.md](./MIGRATION_OPTION_B_QUICK_REFERENCE.md) - High-level overview
- [MIGRATION_PLAN_OPTION_B_VALIDATION_SERVICE_CONSOLIDATION.md](./MIGRATION_PLAN_OPTION_B_VALIDATION_SERVICE_CONSOLIDATION.md) - Full plan
