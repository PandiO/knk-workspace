# Frontend-to-Backend Wiring Documentation

**For**: Migration Option B - Validation Service Consolidation  
**Status**: Detailed Integration Guide  
**Last Updated**: February 16, 2026

---

## Table of Contents

1. [API Endpoint Mapping](#api-endpoint-mapping)
2. [Complete Type Mapping](#complete-type-mapping)
3. [Data Flow Diagrams](#data-flow-diagrams)
4. [Integration Points](#integration-points)
5. [Comprehensive File Changes](#comprehensive-file-changes)
6. [Before/After Code Patterns](#beforeafter-code-patterns)
7. [Deprecated Code Removal Checklist](#deprecated-code-removal-checklist)
8. [Service Method Mapping](#service-method-mapping)
9. [Validation Execution Flow](#validation-execution-flow)
10. [Plugin Integration Points](#plugin-integration-points)

---

## API Endpoint Mapping

### Current State (Pre-Migration)

#### Rule CRUD Endpoints (Currently in ValidationService)
```
GET    /api/field-validation-rules/{id}                          → ValidationService.GetByIdAsync()
GET    /api/field-validation-rules/by-field/{fieldId}             → ValidationService.GetByFormFieldIdAsync()
GET    /api/field-validation-rules/by-configuration/{configId}   → ValidationService.GetByFormConfigurationIdAsync()
POST   /api/field-validation-rules                                 → ValidationService.CreateAsync()
PUT    /api/field-validation-rules/{id}                            → ValidationService.UpdateAsync()
DELETE /api/field-validation-rules/{id}                            → ValidationService.DeleteAsync()
```

**Source**: [FieldValidationRulesController.cs](Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs) (lines 40-94)

**Backend Implementation**: [ValidationService.cs](Repository/knk-web-api-v2/Services/ValidationService.cs) (lines 40-124)

#### Validation Endpoints (Currently split between Services)
```
POST   /api/field-validation-rules/validate                    → ValidationService.ValidateFieldAsync()
POST   /api/field-validation-rules/resolve-placeholders        → PlaceholderResolutionService.ResolveAllLayersAsync()
POST   /api/field-validations/validate-field                   → FieldValidationService.ValidateFieldAsync() ❌ DEPRECATED
GET    /api/field-validations/rules/{ruleId}/placeholders      → PlaceholderResolutionService.ExtractPlaceholdersAsync()
```

**Source**: [FieldValidationRulesController.cs](Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs) (lines 96-220)

**Validation Service**: [ValidationService.cs](Repository/knk-web-api-v2/Services/ValidationService.cs) (lines 132-225)

**Field Validation Service** (DEPRECATED): [FieldValidationService.cs](Repository/knk-web-api-v2/Services/FieldValidationService.cs) (lines 38-127)

#### Health Check & Utility Endpoints (Currently in ValidationService)
```
GET    /api/field-validation-rules/health-check/configuration/{configId}      → ValidationService.ValidateConfigurationHealthAsync()
POST   /api/field-validation-rules/health-check/configuration/draft           → ValidationService.ValidateDraftConfigurationAsync()
POST   /api/field-validation-rules/resolve-dependencies                       → DependencyResolutionService.ResolveDependenciesAsync()
POST   /api/field-validation-rules/validate-path                              → PathResolutionService.ValidatePathAsync()
GET    /api/field-validation-rules/entity/{entityName}/properties             → PathResolutionService.GetEntityPropertiesAsync()
```

**Source**: [FieldValidationRulesController.cs](Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs) (lines 221-329)

**Backend Implementation**: [ValidationService.cs](Repository/knk-web-api-v2/Services/ValidationService.cs) (lines 426-540)

### Post-Migration (No API Changes)

**All endpoints remain unchanged** - API contract is stable  
**Internal routing changes**:
```
OLD:  POST /api/field-validation-rules/{id}   → _service.UpdateAsync()        [ValidationService]
NEW:  POST /api/field-validation-rules/{id}   → _ruleService.UpdateAsync()    [FieldValidationRuleService]

OLD:  POST /api/field-validations/validate-field → _fieldValidationService.ValidateFieldAsync()
NEW:  ❌ ENDPOINT DELETED (consolidate to /validate endpoint)
```

---

## Complete Type Mapping

### Backend → Frontend Type Mappings

#### FieldValidationRule DTO
```csharp
// Backend (C#)
public class FieldValidationRuleDto
{
    public int Id { get; set; }
    public int FormFieldId { get; set; }
    public string ValidationType { get; set; }
    public int? DependsOnFieldId { get; set; }
    public string? DependencyPath { get; set; }
    public string ConfigJson { get; set; }
    public string ErrorMessage { get; set; }
    public string? SuccessMessage { get; set; }
    public bool IsBlocking { get; set; }
    public bool RequiresDependencyFilled { get; set; }
    public DateTime CreatedAt { get; set; }
    public FormFieldNavDto? FormField { get; set; }
    public FormFieldNavDto? DependsOnField { get; set; }
}

// Frontend (TypeScript)
export interface FieldValidationRuleDto {
    id: number;
    formFieldId: number;
    validationType: string;
    dependsOnFieldId?: number;
    dependencyPath?: string;
    configJson: string;
    errorMessage: string;
    successMessage?: string;
    isBlocking: boolean;
    requiresDependencyFilled: boolean;
    createdAt: string;
    formField?: FormFieldNavDto;
    dependsOnField?: FormFieldNavDto;
}
```

**File Locations**:
- Backend: `Services/ValidationService.cs` → AutoMapper profile: `Mapping/ValidationProfile.cs`
- Frontend: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (lines 7-21)

#### Validation Result DTO
```csharp
// Backend (C#)
public class ValidationResultDto
{
    public bool IsValid { get; set; }
    public bool IsBlocking { get; set; }
    public string? Message { get; set; }
    public string? SuccessMessage { get; set; }
    public Dictionary<string, object>? Placeholders { get; set; }  // ← NEW: Placeholder aggregation
    public ValidationMetadataDto? Metadata { get; set; }
}

// Frontend (TypeScript)
export interface ValidationResultDto {
    isValid: boolean;
    isBlocking: boolean;
    message?: string;
    successMessage?: string;
    placeholders?: { [key: string]: string };  // ← NEW: Matches backend
    metadata?: ValidationMetadataDto;
}
```

**Critical Match Points**:
- Backend C# property casing: `PascalCase`
- Frontend JSON parsing: `camelCase` (automatic via HttpClient)
- **Placeholder structure MUST match** between services

**Files**:
- Backend: `Dtos/ValidationResultDto.cs` (determine exact line numbers)
- Frontend: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (lines 60-66)

#### Request DTOs
```csharp
// Backend - ValidateFieldRequestDto
public class ValidateFieldRequestDto
{
    public int FieldId { get; set; }
    public object? FieldValue { get; set; }
    public object? DependencyValue { get; set; }
    public Dictionary<string, object>? FormContextData { get; set; }
}

// Frontend - ValidateFieldRequestDto
export interface ValidateFieldRequestDto {
    fieldId: number;
    fieldValue: any;
    dependencyValue?: any;
    formContextData?: { [fieldName: string]: any };
}
```

**Files**:
- Backend: `Dtos/ValidateFieldRequestDto.cs`
- Frontend: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (lines 46-50)

### Placeholder Resolution DTOs

```csharp
// Backend - PlaceholderResolutionRequest
public class PlaceholderResolutionRequest
{
    public int? FieldValidationRuleId { get; set; }
    public string[]? PlaceholderPaths { get; set; }
    public Dictionary<string, object>? FormContextData { get; set; }
}

// Backend - PlaceholderResolutionResponse
public class PlaceholderResolutionResponse
{
    public Dictionary<string, object> ResolvedPlaceholders { get; set; }
    public Dictionary<string, string>? Errors { get; set; }
}

// Frontend - PlaceholderResolutionRequest
export interface PlaceholderResolutionRequest {
    fieldValidationRuleId?: number;
    placeholderPaths?: string[];
    formContextData?: Record<string, any>;
}

// Frontend - PlaceholderResolutionResponse
export interface PlaceholderResolutionResponse {
    resolvedPlaceholders: Record<string, any>;
    errors?: Record<string, string>;
}
```

**Files**:
- Backend: `Dtos/PlaceholderResolutionRequest.cs`, `Dtos/PlaceholderResolutionResponse.cs`
- Frontend: `src/types/dtos/forms/PlaceholderResolutionDtos.ts`

---

## Data Flow Diagrams

### Current Data Flow (Pre-Migration)

```
Frontend Component
    ↓
FormWizard.tsx (validation call)
    ↓
fieldValidationRuleClient.validateField()
    ↓
POST /api/field-validation-rules/validate
    ↓
FieldValidationRulesController.ValidateField()
    ├─→ ValidationService.ValidateFieldAsync()  ← Multi-rule aggregation
    │        ├─→ Loop: for each rule
    │        │        ├─→ Get ValidationType
    │        │        ├─→ Find matching IValidationMethod
    │        │        └─→ Execute: validator.ValidateAsync()
    │        └─→ Return: First failure OR all pass
    │
    └─→ Response: ValidationResultDto (isValid, message, placeholders=EMPTY ❌)

Plugin Flow:
    ↓
LocationTaskHandler.validateLocation()
    ├─→ Parse WorldTaskValidationContext from InputJson
    ├─→ Loop: for each validation rule
    │        ├─→ Switch on validationType
    │        ├─→ Call specific handler (e.g., validateLocationInsideRegion)
    │        ├─→ Call PlaceholderInterpolationUtil.interpolate() ← SEPARATE RESOLUTION
    │        └─→ Return: ValidationResult with interpolated message
    │
    └─→ Send to player
```

**Problem**: Placeholders resolved separately in plugin, not returned from backend

### Post-Migration Data Flow

```
Frontend Component
    ↓
FormWizard.tsx (validation call - UNCHANGED)
    ↓
fieldValidationRuleClient.validateField()
    ↓
POST /api/field-validation-rules/validate
    ↓
FieldValidationRulesController.ValidateField()
    ↓
ValidationService.ValidateFieldAsync() ← Enhanced with placeholder aggregation
    ├─→ Loop: for each rule
    │        ├─→ Get ValidationType
    │        ├─→ Resolve placeholders NEEDED FOR THIS RULE
    │        ├─→ Find matching IValidationMethod
    │        ├─→ Execute: validator.ValidateAsync(fieldValue, config, resolvedPlaceholders)
    │        └─→ Merge placeholders into aggregation
    └─→ Return: ValidationResultDto WITH placeholders ✅

Frontend Component (Enhanced)
    ↓
FormWizard.tsx
    ├─→ Receive: ValidationResultDto with placeholders
    ├─→ Call: interpolatePlaceholders(message, placeholders)
    └─→ Display: Interpolated error message ✅

Plugin Flow (Aligned)
    ↓
LocationTaskHandler.validateLocation() ← Rules now include placeholder data
    ├─→ Parse WorldTaskValidationContext from InputJson
    ├─→ Loop: for each validation rule
    │        ├─→ Switch on validationType
    │        ├─→ Call specific handler
    │        ├─→ Handler receives BACKEND-RESOLVED placeholders
    │        ├─→ Apply any remaining resolution
    │        └─→ Return: ValidationResult with message
    │
    └─→ Send to player ✅
```

**Improvement**: Backend aggregates placeholders, frontend interpolates, plugin uses backend resolution

---

## Integration Points

### 1. Service Constructor Injection

#### Current State
```csharp
// FieldValidationRulesController.cs - Lines 23-31
public FieldValidationRulesController(
    IValidationService service,
    IPlaceholderResolutionService placeholderService,
    IFieldValidationService fieldValidationService,  // ← DEPRECATED SERVICE
    IFieldValidationRuleRepository ruleRepository,
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _service = service;
    _placeholderService = placeholderService;
    _fieldValidationService = fieldValidationService;  // ← STORE
    _ruleRepository = ruleRepository;
    _dependencyService = dependencyService;
    _pathService = pathService;
}
```

#### New State (Post-Migration)
```csharp
// FieldValidationRulesController.cs - Lines 23-30
public FieldValidationRulesController(
    IValidationService validationService,
    IFieldValidationRuleService ruleService,          // ← NEW SERVICE
    IPlaceholderResolutionService placeholderService,
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _validationService = validationService;
    _ruleService = ruleService;                       // ← NEW STORE
    _placeholderService = placeholderService;
    _dependencyService = dependencyService;
    _pathService = pathService;
}
```

**Changes**:
- Remove `IFieldValidationService fieldValidationService` parameter
- Add `IFieldValidationRuleService ruleService` parameter
- Remove `IFieldValidationRuleRepository ruleRepository` (moved to IFieldValidationRuleService)
- Remove unused local `_ruleRepository` field

**Verification Commands**:
```bash
# Find all constructor injections
Select-String -Pattern "IFieldValidationService" -Path "Controllers/*.cs"
Select-String -Pattern "IFieldValidationRuleService" -Path "Controllers/*.cs"
```

### 2. Endpoint Method Routing

#### CRUD Endpoints (No Handler Changes)
```csharp
// These methods delegate to _service, which will NOW route to _ruleService
[HttpGet("{id:int}")]
public async Task<IActionResult> GetById(int id)
{
    var rule = await _service.GetByIdAsync(id);  // ← Routes to FieldValidationRuleService.GetByIdAsync()
    if (rule == null) return NotFound();
    return Ok(rule);
}

[HttpPost]
public async Task<IActionResult> Create([FromBody] CreateFieldValidationRuleDto dto)
{
    // ... validation ...
    var created = await _service.CreateAsync(dto);  // ← Routes to FieldValidationRuleService.CreateAsync()
    return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
}

[HttpPut("{id:int}")]
public async Task<IActionResult> Update(int id, [FromBody] UpdateFieldValidationRuleDto dto)
{
    // ... validation ...
    await _service.UpdateAsync(id, dto);  // ← Routes to FieldValidationRuleService.UpdateAsync()
    return NoContent();
}

[HttpDelete("{id:int}")]
public async Task<IActionResult> Delete(int id)
{
    await _service.DeleteAsync(id);  // ← Routes to FieldValidationRuleService.DeleteAsync()
    return NoContent();
}
```

**Action**: No code changes to controller methods - IValidationService interface will be split

#### Validation Endpoints (Handler Changes Required)
```csharp
// CURRENT: Uses FieldValidationService (DEPRECATED ENDPOINT)
[HttpPost("/api/field-validations/validate-field")]
public async Task<IActionResult> ValidateFieldRule([FromBody] ValidateFieldRuleRequestDto request)
{
    // ...
    var result = await _fieldValidationService.ValidateFieldAsync(
        rule,
        request.FieldValue,
        request.DependencyFieldValue,
        request.CurrentEntityPlaceholders,
        request.EntityId);
    return Ok(result);
}
// DELETE THIS ENTIRE ENDPOINT (lines 172-200 approximately)

// KEEP: Uses ValidationService (consolidation target)
[HttpPost("validate")]
public async Task<IActionResult> ValidateField([FromBody] ValidateFieldRequestDto request)
{
    var result = await _service.ValidateFieldAsync(request);  // ← This is the canonical endpoint
    return Ok(result);
}
```

**Actions**:
1. DELETE endpoint: `POST /api/field-validations/validate-field`
2. ENHANCE endpoint: `POST /api/field-validation-rules/validate` with placeholder aggregation

#### Health Check Endpoints (Routing Updates)
```csharp
// BEFORE
[HttpGet("health-check/configuration/{configId:int}")]
public async Task<IActionResult> ValidateConfigurationHealth(int configId)
{
    var issues = await _service.ValidateConfigurationHealthAsync(configId);  // ← ValidationService
    return Ok(issues);
}

// AFTER  
[HttpGet("health-check/configuration/{configId:int}")]
public async Task<IActionResult> ValidateConfigurationHealth(int configId)
{
    var issues = await _ruleService.ValidateConfigurationHealthAsync(configId);  // ← FieldValidationRuleService
    return Ok(issues);
}
```

**Line Changes**: Update 3-4 health-check handler methods to use `_ruleService` instead of `_service`

---

## Comprehensive File Changes

### Backend Files (C#/.NET)

#### Service Interface Changes

**File**: `Services/Interfaces/IValidationService.cs` (ENHANCE)
```csharp
// KEEP THESE METHODS
Task<ValidationResultDto?> GetByIdAsync(int id);
Task<IEnumerable<ValidationResultDto>> GetByFormFieldIdAsync(int fieldId);
Task<IEnumerable<ValidationResultDto>> GetByFormConfigurationIdAsync(int configId);
Task<ValidationResultDto> CreateAsync(CreateFieldValidationRuleDto dto);
Task UpdateAsync(int id, UpdateFieldValidationRuleDto dto);
Task DeleteAsync(int id);

Task<ValidationResultDto> ValidateFieldAsync(ValidateFieldRequestDto request);
Task<ValidationResultDto> ValidateFieldAsync(int fieldId, object? fieldValue, object? dependencyValue, Dictionary<string, object>? formContextData);

// ADD THESE METHODS (placeholder support)
Task<ValidationResultDto> ValidateFieldWithPlaceholdersAsync(int fieldId, object? fieldValue, Dictionary<string, object> contextData);
private Task<Dictionary<string, object>> ResolvePlaceholdersForRuleAsync(FieldValidationRule rule, Dictionary<string, object> contextData);

// MOVE THESE TO IFieldValidationRuleService
// Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId);
// Task<bool> ValidateDraftConfigurationAsync(int draftId);
// Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData);
```

**File**: `Services/Interfaces/IFieldValidationRuleService.cs` (CREATE)
```csharp
public interface IFieldValidationRuleService
{
    // CRUD Operations (MOVED from IValidationService)
    Task<FieldValidationRuleReadDto> GetByIdAsync(int ruleId);
    Task<IEnumerable<FieldValidationRuleReadDto>> GetByFieldAsync(int fieldId);
    Task<FieldValidationRuleReadDto> CreateAsync(FieldValidationRuleCreateDto dto);
    Task<FieldValidationRuleReadDto> UpdateAsync(int ruleId, FieldValidationRuleUpdateDto dto);
    Task DeleteAsync(int ruleId);
    
    // Health Check Methods (MOVED from IValidationService)
    Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId);
    Task<bool> ValidateDraftConfigurationAsync(int draftId);
    
    // Dependency Analysis (MOVED from IValidationService)
    Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData);
}
```

**Files to Update**:
- `Services/Interfaces/IValidationService.cs` - Remove 3 methods
- `Services/Interfaces/IFieldValidationRuleService.cs` - Create new interface

---

#### Service Implementation Changes

**File**: `Services/FieldValidationRuleService.cs` (CREATE)
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
    { /* ... */ }
    
    // Copy from ValidationService.cs lines 40-124 (CRUD methods)
    public async Task<FieldValidationRuleReadDto> GetByIdAsync(int ruleId) { }
    public async Task<IEnumerable<FieldValidationRuleReadDto>> GetByFieldAsync(int fieldId) { }
    public async Task<FieldValidationRuleReadDto> CreateAsync(FieldValidationRuleCreateDto dto) { }
    public async Task<FieldValidationRuleReadDto> UpdateAsync(int ruleId, FieldValidationRuleUpdateDto dto) { }
    public async Task DeleteAsync(int ruleId) { }
    
    // Copy from ValidationService.cs lines 426-540 (Health checks)
    public async Task<ConfigurationHealthCheckDto> ValidateConfigurationHealthAsync(int formConfigId) { }
    public async Task<bool> ValidateDraftConfigurationAsync(int draftId) { }
    
    // Copy dependency resolution logic
    public async Task<DependencyResolutionDto> ResolveDependenciesAsync(int ruleId, Dictionary<string, object> contextData) { }
}
```

**File**: `Services/ValidationService.cs` (ENHANCE)
```csharp
public class ValidationService : IValidationService
{
    // REMOVE THESE METHOD BODIES (will delegate or not implement)
    // GetByIdAsync, GetByFieldAsync, GetByFormConfigurationIdAsync
    // CreateAsync, UpdateAsync, DeleteAsync
    // ValidateConfigurationHealthAsync, ValidateDraftConfigurationAsync
    // ResolveDependenciesAsync
    
    // KEEP & ENHANCE THESE
    public async Task<ValidationResultDto> ValidateFieldAsync(
        int fieldId,
        object? fieldValue,
        object? dependencyValue,
        Dictionary<string, object>? formContextData)
    {
        // EXISTING: Multi-rule loop logic
        var rules = await _ruleRepository.GetByFormFieldIdAsync(fieldId);
        var allPlaceholders = new Dictionary<string, object>();
        
        foreach (var rule in rules)
        {
            // NEW: Resolve placeholders for this rule
            var rulePlaceholders = await ResolvePlaceholdersForRuleAsync(rule, formContextData);
            
            // EXISTING: Execute validator
            var result = await ExecuteValidationRuleAsync(
                rule, fieldValue, validators, formContextData, rulePlaceholders);  // ← Add placeholder param
            
            // NEW: Aggregate placeholders
            foreach (var kv in rulePlaceholders)
            {
                if (!allPlaceholders.ContainsKey(kv.Key))
                    allPlaceholders[kv.Key] = kv.Value;
            }
            
            // EXISTING: Check failure
            if (!result.IsValid && result.IsBlocking)
                return new ValidationResultDto { 
                    IsValid = false, 
                    Message = result.Message,
                    Placeholders = allPlaceholders  // ← Include aggregated placeholders
                };
        }
        
        return new ValidationResultDto { 
            IsValid = true,
            Placeholders = allPlaceholders  // ← Return all placeholders
        };
    }
    
    // NEW METHOD
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
}
```

**File**: `Services/FieldValidationService.cs` (DELETE ENTIRE FILE)
- Reason: Consolidated into ValidationService
- Lines: All 278 lines

---

#### Dependency Injection Changes

**File**: `DependencyInjection/ServiceCollectionExtensions.cs` (UPDATE)

```csharp
// BEFORE
public static IServiceCollection AddValidationServices(this IServiceCollection services)
{
    services.AddScoped<IValidationService, ValidationService>();
    services.AddScoped<IFieldValidationService, FieldValidationService>();  // ← REMOVE
    // ...
    return services;
}

// AFTER
public static IServiceCollection AddValidationServices(this IServiceCollection services)
{
    services.AddScoped<IValidationService, ValidationService>();
    services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>();  // ← ADD
    // (keep others)
    services.AddScoped<IFieldValidationRuleRepository, FieldValidationRuleRepository>();
    services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>();
    // ...
    return services;
}
```

---

#### Controller Changes

**File**: `Controllers/FieldValidationRulesController.cs` (UPDATE)

```csharp
// Constructor - Lines 23-31
// BEFORE
public FieldValidationRulesController(
    IValidationService service,
    IPlaceholderResolutionService placeholderService,
    IFieldValidationService fieldValidationService,
    IFieldValidationRuleRepository ruleRepository,
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _service = service;
    _placeholderService = placeholderService;
    _fieldValidationService = fieldValidationService;
    _ruleRepository = ruleRepository;  // ← Now part of IFieldValidationRuleService
    _dependencyService = dependencyService;
    _pathService = pathService;
}

// AFTER
public FieldValidationRulesController(
    IValidationService validationService,
    IFieldValidationRuleService ruleService,
    IPlaceholderResolutionService placeholderService,
    IDependencyResolutionService dependencyService,
    IPathResolutionService pathService)
{
    _validationService = validationService;
    _ruleService = ruleService;  // ← NEW FIELD
    _placeholderService = placeholderService;
    _dependencyService = dependencyService;
    _pathService = pathService;
    // _ruleRepository removed
}
```

**Endpoint Changes**:

```csharp
// DELETE: Lines 172-200 (approximately)
// [HttpPost("/api/field-validations/validate-field")]
// public async Task<IActionResult> ValidateFieldRule(...)
// {
//     var result = await _fieldValidationService.ValidateFieldAsync(...);
// }

// UPDATE: Lines 221-230
[HttpGet("health-check/configuration/{configId:int}")]
public async Task<IActionResult> ValidateConfigurationHealth(int configId)
{
    try
    {
        var issues = await _ruleService.ValidateConfigurationHealthAsync(configId);  // ← Change service
        return Ok(issues);
    }
    // ...
}

// UPDATE: Lines 234-250
[HttpPost("health-check/configuration/draft")]
public async Task<IActionResult> ValidateDraftConfiguration([FromBody] FormConfigurationDto configDto)
{
    try
    {
        // ...
        var issues = await _ruleService.ValidateDraftConfigurationAsync(configDto);  // ← Change service
        return Ok(issues);
    }
    // ...
}
```

---

### Frontend Files (TypeScript/React)

#### API Client Changes

**File**: `src/apiClients/fieldValidationRuleClient.ts` (MINIMAL CHANGES)

```typescript
// NO CHANGES TO METHOD SIGNATURES - API contract is stable
// Changes are INTERNAL to handler routing only

// BEFORE
validateField(request: ValidateFieldRequestDto): Promise<ValidationResultDto> {
    return this.invokeServiceCall(
        request, 
        FieldValidationRuleOperation.Validate, 
        Controllers.FieldValidationRules, 
        HttpMethod.Post);
}

// AFTER (NO CHANGE - response will now include placeholders)
validateField(request: ValidateFieldRequestDto): Promise<ValidationResultDto> {
    return this.invokeServiceCall(
        request, 
        FieldValidationRuleOperation.Validate, 
        Controllers.FieldValidationRules, 
        HttpMethod.Post);
}

// Type update automatically picks up new ValidationResultDto.placeholders field
```

**Key Point**: Client methods unchanged - only response type enhancements

---

#### Type Definition Changes

**File**: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (UPDATE)

```typescript
// BEFORE
export interface ValidationResultDto {
    isValid: boolean;
    isBlocking: boolean;
    message?: string;
    successMessage?: string;
    metadata?: ValidationMetadataDto;
    // placeholders field MISSING
}

// AFTER
export interface ValidationResultDto {
    isValid: boolean;
    isBlocking: boolean;
    message?: string;
    successMessage?: string;
    placeholders?: { [key: string]: any };  // ← ADD THIS
    metadata?: ValidationMetadataDto;
}
```

**File Location**: `src/types/dtos/forms/FieldValidationRuleDtos.ts` (lines 60-66)

---

#### Component Changes

**File**: `src/components/FormWizard.tsx` (INTEGRATE PLACEHOLDERS)

```typescript
// USAGE EXAMPLE - Find and update validation call handler

// BEFORE
const handleFieldValidation = async (fieldId: number, value: any) => {
    const result = await fieldValidationRuleClient.validateField({
        fieldId,
        fieldValue: value,
        formContextData: formContext
    });
    
    setFieldError(fieldId, result.message);  // ← Direct message, no interpolation
};

// AFTER
const handleFieldValidation = async (fieldId: number, value: any) => {
    const result = await fieldValidationRuleClient.validateField({
        fieldId,
        fieldValue: value,
        formContextData: formContext
    });
    
    // NEW: Interpolate placeholders if present
    let displayMessage = result.message || '';
    if (result.placeholders && result.message) {
        displayMessage = interpolatePlaceholders(result.message, result.placeholders);
    }
    
    setFieldError(fieldId, displayMessage);
    // OPTIONAL: Store placeholders for other components
    setResolvedPlaceholders(result.placeholders || {});
};

// Helper function
function interpolatePlaceholders(template: string, placeholders: Record<string, any>): string {
    let result = template;
    for (const [key, value] of Object.entries(placeholders)) {
        result = result.replace(`{${key}}`, String(value));
    }
    return result;
}
```

**Search for in FormWizard.tsx**:
- `fieldValidationRuleClient.validateField(`
- Any placeholder interpolation logic already present
- Error message display/storage

---

#### Component Changes (Field Renderer)

**File**: `src/components/Workflow/WorldBoundFieldRenderer.tsx` (INTEGRATE PLACEHOLDERS)

```typescript
// BEFORE
const renderValidationResult = (result: ValidationResultDto) => {
    return <div className="error">{result.message}</div>;
};

// AFTER
const renderValidationResult = (result: ValidationResultDto) => {
    let displayMessage = result.message;
    if (result.placeholders && result.message) {
        displayMessage = interpolatePlaceholders(result.message, result.placeholders);
    }
    return <div className="error">{displayMessage}</div>;
};
```

---

### Plugin Files (Java)

#### DTO Alignment (knk-core)

**File**: `knk-core/src/main/java/net/knightsandkings/knk/core/domain/validation/WorldTaskValidationRule.java` (VERIFY)

```java
// BEFORE & AFTER (likely no changes - structure should match backend)
public class WorldTaskValidationRule {
    private String validationType;
    private String configJson;
    private String errorMessage;
    private String successMessage;
    private boolean isBlocking;
    private boolean requiresDependencyFilled;  // ← Should already exist
    // + other fields
}
```

**Action**: Verify all fields match backend `FieldValidationRule` DTO

---

#### Handler Updates (knk-paper)

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java` (UPDATE)

```java
// CURRENT: Line ~317-370
private ValidationResult validateLocation(Player player, Location location, TaskContext context) {
    WorldTaskValidationContext validationContext = context.getValidationContext();
    
    for (WorldTaskValidationRule rule : validationContext.getValidationRules()) {
        switch (rule.getValidationType()) {
            case "LocationInsideRegion":
                // Call without placeholders
                return validateLocationInsideRegion(player, location, rule);
            // ... other types
        }
    }
    return ValidationResult.success("Location valid");
}

// AFTER: Add placeholder data
private ValidationResult validateLocation(Player player, Location location, TaskContext context) {
    WorldTaskValidationContext validationContext = context.getValidationContext();
    // NEW: Extract placeholders from context if present
    JsonObject placeholders = validationContext.getPlaceholders();  // ← Assume this field exists
    
    for (WorldTaskValidationRule rule : validationContext.getValidationRules()) {
        switch (rule.getValidationType()) {
            case "LocationInsideRegion":
                // Call WITH placeholders
                return validateLocationInsideRegion(player, location, rule, placeholders);
            // ... other types
        }
    }
    return ValidationResult.success("Location valid");
}

// Update handler signature to accept placeholders
private ValidationResult validateLocationInsideRegion(
    Player player, 
    Location location, 
    JsonObject rule,
    JsonObject placeholders)  // ← ADD
{
    // ... existing logic ...
    // Placeholders now available for interpolation
}
```

---

#### Placeholder Utility Updates (knk-paper)

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/utils/PlaceholderInterpolationUtil.java` (UPDATE)

```java
// Verify these methods exist and work with new placeholder structure
public static JsonObject mergePlaceholders(JsonObject... objects) {
    JsonObject result = new JsonObject();
    for (JsonObject obj : objects) {
        if (obj != null) {
            obj.entrySet().forEach(entry -> result.add(entry.getKey(), entry.getValue()));
        }
    }
    return result;
}

public static String interpolate(String template, JsonObject placeholders) {
    String result = template;
    if (placeholders != null) {
        for (String key : placeholders.keySet()) {
            String value = placeholders.get(key).getAsString();
            result = result.replace("{" + key + "}", value);
        }
    }
    return result;
}
```

---

## Before/After Code Patterns

### Pattern 1: CRUD Operation Call Chain

**Before (Confused Ownership)**
```
Component Call
    ↓
fieldValidationRuleClient.update(id, dto)
    ↓
POST /api/field-validation-rules/{id}
    ↓
FieldValidationRulesController.Update()
    ↓
_service.UpdateAsync()  [IValidationService]
    ↓
ValidationService.UpdateAsync()  ← Also has {Create, Read, Delete methods mixed in}
```

**After (Clear Ownership)**
```
Component Call
    ↓
fieldValidationRuleClient.update(id, dto)
    ↓
POST /api/field-validation-rules/{id}
    ↓
FieldValidationRulesController.Update()
    ↓
_ruleService.UpdateAsync()  [IFieldValidationRuleService]
    ↓
FieldValidationRuleService.UpdateAsync()  ← Dedicated service for CRUD
```

---

### Pattern 2: Validation Execution with Placeholder Aggregation

**Before**
```csharp
var result = await _service.ValidateFieldAsync(fieldId, value, null, context);
// result.placeholders EMPTY
// Frontend must call separate endpoint for placeholders
```

**After**
```csharp
var result = await _service.ValidateFieldAsync(fieldId, value, null, context);
// result.placeholders POPULATED via ExecuteValidationRuleAsync()
// Frontend receives everything in one call
```

---

### Pattern 3: Plugin Integration

**Before**
```java
// Plugin receives rules WITHOUT placeholder resolution from backend
ValidationResult result = validateLocationInsideRegion(player, location, rule);
// Must interpolate locally
errorMsg = PlaceholderInterpolationUtil.interpolate(errorMsg, localPlaceholders);
```

**After**
```java
// Plugin receives rules WITH backend-resolved placeholders
ValidationResult result = validateLocationInsideRegion(
    player, location, rule, backendResolvedPlaceholders);
// Can use backend resolution + local refinement
errorMsg = PlaceholderInterpolationUtil.interpolate(
    errorMsg, 
    mergePlaceholders(backendPlaceholders, localPlaceholders));
```

---

## Deprecated Code Removal Checklist

### Interfaces & Classes to Delete

**Services (Delete Completely)**:
- [ ] `Services/FieldValidationService.cs` (278 lines)
- [ ] `Services/Interfaces/IFieldValidationService.cs`

**Testing**:
- [ ] `Tests/Services/FieldValidationServiceTests.cs` (all tests)

---

### Methods to Delete from ValidationService

**From**: `Services/ValidationService.cs`

- [ ] Line 40-45: `GetByIdAsync(int id)` 
- [ ] Line 47-51: `GetByFormFieldIdAsync(int fieldId)`
- [ ] Line 53-57: `GetByFormConfigurationIdAsync(int formConfigurationId)`
- [ ] Line 59-80: `GetByFormFieldIdWithDependenciesAsync(...)`
- [ ] Line 82-90: `CreateAsync(CreateFieldValidationRuleDto dto)`
- [ ] Line 92-115: `UpdateAsync(int id, UpdateFieldValidationRuleDto dto)`
- [ ] Line 117-124: `DeleteAsync(int id)`
- [ ] Line 426-540: `ValidateConfigurationHealthAsync(...)` and `ValidateDraftConfigurationAsync(...)`
- [ ] Line [TBD]: `ResolveDependenciesAsync(...)`

**Total Lines to Remove**: ~200 lines

---

### Methods to Delete from Controller

**From**: `Controllers/FieldValidationRulesController.cs`

- [ ] Line 40-48: `GetById(int id)` → routing to wrong service method
- [ ] Line 50-55: `GetByFormField(int fieldId)` → routing to wrong service method
- [ ] Line 57-62: `GetByConfiguration(int configId)` → routing to wrong service method
- [ ] Line 64-74: `Create(...)` → routing to wrong service method
- [ ] Line 76-90: `Update(...)` → routing to wrong service method
- [ ] Line 92-105: `Delete(...)` → routing to wrong service method
- [ ] Line 172-200: `ValidateFieldRule(...)` → DEPRECATED ENDPOINT (uses FieldValidationService)

**UPDATE**:
- [ ] Line 40-50: Constructor - remove `IFieldValidationService` param, add `IFieldValidationRuleService` param
- [ ] Line 221-230: `ValidateConfigurationHealth()` - change `_service.ValidateConfigurationHealthAsync()` to `_ruleService.ValidateConfigurationHealthAsync()`
- [ ] Line 234-251: `ValidateDraftConfiguration()` - change `_service.ValidateDraftConfigurationAsync()` to `_ruleService.ValidateDraftConfigurationAsync()`

**ACTION**: Update endpoints to call `_ruleService` instead of `_service` for CRUD/Health operations

---

### Endpoints to Delete

**From**: `Controllers/FieldValidationRulesController.cs`

- [ ] `POST /api/field-validations/validate-field` (Lines 172-200) 
  - **Reason**: Duplicates `/api/field-validation-rules/validate` functionality
  - **Migration**: Use `/validate` endpoint from ValidationService instead

---

### DI Registration Changes

**File**: `DependencyInjection/ServiceCollectionExtensions.cs`

- [ ] Remove: `services.AddScoped<IFieldValidationService, FieldValidationService>();`
- [ ] Add: `services.AddScoped<IFieldValidationRuleService, FieldValidationRuleService>();`

---

### Frontend Code to Remove

**File**: `src/apiClients/fieldValidationRuleClient.ts`

- Check if this method exists and is used:
  ```typescript
  // If this method exists, verify it's not used before removing
  validateFieldRule(...): Promise<ValidationResultDto> { }
  ```

**Action**: Delete if present (maps to deprecated `/api/field-validations/validate-field`)

---

### Test Files to Update/Delete

**Delete**:
- [ ] `Tests/Services/FieldValidationServiceTests.cs` - Entire file

**Update**:
- [ ] `Tests/Services/ValidationServiceTests.cs` 
  - Remove any tests for deleted CRUD methods (GetByIdAsync, CreateAsync, etc.)
  - Keep tests for ValidateFieldAsync
  - Add tests for ValidateFieldWithPlaceholdersAsync (NEW)
  
- [ ] `Tests/Services/FieldValidationRuleServiceTests.cs`
  - Create entirely new test file
  - 25+ tests for CRUD operations and health checks
  - Target 80%+ coverage

- [ ] `Tests/Controllers/FieldValidationRulesControllerTests.cs`
  - Update mock registrations
  - Replace `Mock<IFieldValidationService>` with `Mock<IValidationService>` for validation tests
  - Replace mocking of CRUD methods in controller

---

## Service Method Mapping

### Methods Moving to FieldValidationRuleService

| Method | Current (ValidationService) | New (FieldValidationRuleService) | Lines |
|--------|------------------------------|-----------------------------------|-------|
| GetByIdAsync | ✅ Keep | ✅ Move | ~5 |
| GetByFormFieldIdAsync | ✅ Keep | ✅ Move | ~5 |
| GetByFormConfigurationIdAsync | ✅ Keep | ✅ Move | ~5 |
| CreateAsync | ✅ Keep | ✅ Move | ~20 |
| UpdateAsync | ✅ Keep | ✅ Move | ~25 |
| DeleteAsync | ✅ Keep | ✅ Move | ~10 |
| ValidateConfigurationHealthAsync | ✅ Keep | ✅ Move | ~80 |
| ValidateDraftConfigurationAsync | ✅ Keep | ✅ Move | ~50 |
| ResolveDependenciesAsync | ✅ Keep | ✅ Move | ~25 |

**Total Lines Moving**: ~225 lines

### Methods Staying in ValidationService

| Method | Purpose | Current | New |
|--------|---------|---------|-----|
| ValidateFieldAsync | Multi-rule validation | Enhance ✅ | Enhanced ✅ |
| ExecuteValidationRuleAsync | Single rule execution | Enhance ✅ | Enhanced ✅ |
| ResolvePlaceholdersForRuleAsync | Placeholder resolution | New | ✅ Create |

### Methods to Create in FieldValidationRuleService

| Method | Purpose |
|--------|---------|
| GetByIdAsync | CRUD - Read single |
| GetByFormFieldIdAsync | CRUD - Read by field |
| GetByFormConfigurationIdAsync | CRUD - Read by config |
| CreateAsync | CRUD - Create |
| UpdateAsync | CRUD - Update |
| DeleteAsync | CRUD - Delete |
| ValidateConfigurationHealthAsync | Health - Full config |
| ValidateDraftConfigurationAsync | Health - Draft config |
| ResolveDependenciesAsync | Analysis - Dependency resolution |

---

## Validation Execution Flow

### Current Flow (ValidationService)

```csharp
ValidateFieldAsync(fieldId, value, dependencyValue, formContextData)
  ├─ Load rules: GetByFormFieldIdAsync(fieldId)
  ├─ For each rule:
  │   ├─ Find validator by rule.ValidationType
  │   └─ Call validator.ValidateAsync(value, config)
  │        ├─ Execute validation logic
  │        └─ Return ValidationResult
  │   ├─ If failed & blocking: Return failure
  │   └─ If passed: Continue to next rule
  └─ Return: ValidationResultDto with IsValid=true, Placeholders=EMPTY ❌
```

### New Flow (Enhanced ValidationService)

```csharp
ValidateFieldAsync(fieldId, value, dependencyValue, formContextData)
  ├─ Load rules: GetByFormFieldIdAsync(fieldId)
  ├─ Initialize aggregated placeholders: Dictionary<string, object>
  ├─ For each rule:
  │   ├─ NEW: Resolve placeholders
  │   │   └─ Call _placeholderService.ResolveAllLayersAsync(fieldId, formContextData)
  │   │       └─ Returns: { "townName": "Springfield", ... }
  │   ├─ Find validator by rule.ValidationType
  │   └─ Call validator.ValidateAsync(value, config, resolvedPlaceholders)  ← PASS PLACEHOLDERS
  │        ├─ Execute validation logic
  │        ├─ Use placeholders in error message interpolation
  │        └─ Return ValidationResult with interpolated message
  │   ├─ NEW: Merge placeholders into aggregation
  │   │   └─ Add all resolved placeholders to aggregated dict
  │   ├─ If failed & blocking: Return failure WITH placeholders
  │   └─ If passed: Continue to next rule
  └─ Return: ValidationResultDto with IsValid=true, Placeholders=MERGED ✅
```

### ExecuteValidationRuleAsync Signature

**Before**:
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule,
    object? fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null)
```

**After**:
```csharp
private async Task<ValidationResultDto> ExecuteValidationRuleAsync(
    FieldValidationRuleReadDto rule,
    object? fieldValue,
    IEnumerable<IValidationMethod> validators,
    Dictionary<string, object>? formContextData = null,
    Dictionary<string, object>? resolvedPlaceholders = null)  // ← NEW PARAM
```

---

## Plugin Integration Points

### Data Flow: Backend → Plugin

**1. WorldTask Creation**
```
Frontend sends form data to backend
    ↓
Backend creates WorldTask with OutputJson containing:
    {
      "validationContext": {
        "validationRules": [
          {
            "validationType": "LocationInsideRegion",
            "configJson": "{...}",
            "errorMessage": "Location {townName} is outside allowed regions",
            "requiresDependencyFilled": true
          }
        ],
        "placeholders": {  // ← NEW in migration
          "townName": "Springfield"
        }
      }
    }
    ↓
Plugin receives WorldTask via LocationTaskHandler
```

### Plugin Handler Updates

**LocationTaskHandler.validateLocation() Signature Update**:

```java
// BEFORE
private ValidationResult validateLocation(Player player, Location location, TaskContext context)

// AFTER
private ValidationResult validateLocation(Player player, Location location, TaskContext context) {
    WorldTaskValidationContext validationContext = context.getValidationContext();
    JsonObject backendPlaceholders = validationContext.getPlaceholders();  // ← EXTRACT
    
    // Use backendPlaceholders in validation logic
}
```

### PlaceholderInterpolationUtil Alignment

```java
// Ensure these methods handle new placeholder structure
public static JsonObject mergePlaceholders(JsonObject backend, JsonObject local) {
    // Merge both backend (pre-resolved) and local (plugin-specific) placeholders
    JsonObject result = new JsonObject();
    
    // Add backend placeholders (higher priority)
    if (backend != null) {
        backend.entrySet().forEach(e -> result.add(e.getKey(), e.getValue()));
    }
    
    // Add local placeholders (don't override backend)
    if (local != null) {
        local.entrySet().forEach(e -> {
            if (!result.has(e.getKey())) {
                result.add(e.getKey(), e.getValue());
            }
        });
    }
    
    return result;
}

public static String interpolate(String template, JsonObject allPlaceholders) {
    String result = template;
    if (allPlaceholders != null && allPlaceholders.size() > 0) {
        for (String key : allPlaceholders.keySet()) {
            String value = allPlaceholders.get(key).getAsString();
            result = result.replace("{" + key + "}", value);
        }
    }
    return result;
}
```

---

## Summary: File Change Inventory

### Create (2 files)
- `Services/FieldValidationRuleService.cs` (~300 lines)
- `Services/Interfaces/IFieldValidationRuleService.cs` (~20 lines)

### Delete (2 files)
- `Services/FieldValidationService.cs` (278 lines)
- `Services/Interfaces/IFieldValidationService.cs`

### Modify (7+ files)

**Backend**:
- `Services/ValidationService.cs` - Remove CRUD, enhance validation, add placeholder aggregation
- `Services/Interfaces/IValidationService.cs` - Remove 3 method signatures
- `Controllers/FieldValidationRulesController.cs` - Update constructor, delete 1 endpoint, update 3 endpoint handlers
- `DependencyInjection/ServiceCollectionExtensions.cs` - Update service registration

**Frontend**:
- `src/types/dtos/forms/FieldValidationRuleDtos.ts` - Add placeholders field to ValidationResultDto
- `src/components/FormWizard.tsx` - Integrate placeholder interpolation in validation handler
- `src/components/Workflow/WorldBoundFieldRenderer.tsx` - Integrate placeholder interpolation in field rendering

**Plugin**:
- `knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java` - Update handler signatures
- `knk-paper/src/main/java/net/knightsandkings/knk/paper/utils/PlaceholderInterpolationUtil.java` - Verify/enhance methods

### Test Files Update (4 files)

- `Tests/Services/FieldValidationServiceTests.cs` - DELETE
- `Tests/Services/FieldValidationRuleServiceTests.cs` - CREATE (25+ tests)
- `Tests/Services/ValidationServiceTests.cs` - UPDATE (remove CRUD tests, add placeholder tests)
- `Tests/Controllers/FieldValidationRulesControllerTests.cs` - UPDATE (fix dependency injection mocks)

---

## Verification Checklist

After implementing all changes:

- [ ] **Compilation**: `dotnet build` returns 0 errors
- [ ] **Tests**: `dotnet test` passes 100%
- [ ] **Coverage**: 80%+ for all validation services
- [ ] **No Orphaned Code**: `Select-String -Pattern "IFieldValidationService|FieldValidationService" -Path "**/*.cs"` returns 0 matches
- [ ] **No Orphaned Endpoints**: API responds correctly to all validation endpoints
- [ ] **Placeholder Integration**: Frontend displays interpolated error messages
- [ ] **Plugin Alignment**: Plugin receives and uses backend-resolved placeholders
- [ ] **Type Safety**: No TypeScript errors in frontend
- [ ] **Database Consistency**: No orphaned validation rules in database
- [ ] **Backward Compatibility**: All existing validations continue to work

---

**Document Version**: 1.0  
**Last Updated**: February 16, 2026  
**Status**: Ready for Implementation
