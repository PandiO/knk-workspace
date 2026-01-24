# Inter-Field Validation Dependencies - Implementation Roadmap

**Status**: Phase 7 ✅ COMPLETE | Phase 8 In Planning  
**Created**: January 18, 2026  
**Last Updated**: January 24, 2026

This document provides a step-by-step implementation plan organized by component and priority.

**Current Progress:**
- Phase 1: Backend Foundation ✅ COMPLETE
- Phase 2: Repository & Service ✅ COMPLETE  
- Phase 3: Validation Methods ✅ COMPLETE
- Phase 4: API Controllers ✅ COMPLETE
- Phase 5: Frontend DTOs & Client ✅ COMPLETE
- Phase 6: Frontend UI Components ✅ COMPLETE
- Phase 7: Testing & Validation ✅ COMPLETE (124 tests, 20 QA scenarios)
- Phase 8: Documentation & Deployment ⏳ PENDING

---

## Overview

**Estimated Total Effort:** 3-4 days (1 developer)

**Key Deliverables:**
1. Backend: FieldValidationRule entity, repositories, services, controllers
2. Backend: Validation method implementations (LocationInsideRegion, RegionContainment, ConditionalRequired)
3. Frontend: ValidationRuleBuilder UI component
4. Frontend: Validation execution in FieldRenderer
5. Frontend: Configuration health check display
6. Database migration

**Dependencies:**
- ✅ FormField entity already exists
- ✅ FormConfiguration system already functional
- ⚠️ WorldGuard region API integration (see Phase 3 for details)

---

## Phase 1: Backend Foundation (Data Model & Infrastructure)

### Priority: CRITICAL - Blocks all other work

#### 1.1 Create FieldValidationRule Entity
**Effort:** 30 minutes

**File:** `Repository/knk-web-api-v2/Models/FieldValidationRule.cs`

**Tasks:**
- [ ] Create FieldValidationRule class
- [ ] Add properties: Id, FormFieldId, ValidationType, DependsOnFieldId, ConfigJson, ErrorMessage, SuccessMessage, IsBlocking, RequiresDependencyFilled, CreatedAt
- [ ] Add navigation properties: FormField, DependsOnField
- [ ] Add XML documentation for all properties
- [ ] Follow existing model patterns (see FormField.cs, FormStep.cs for reference)

**Code Example:**
```csharp
public class FieldValidationRule
{
    public int Id { get; set; }
    public int FormFieldId { get; set; }
    public FormField FormField { get; set; } = null!;
    public string ValidationType { get; set; } = string.Empty;
    public int? DependsOnFieldId { get; set; }
    public FormField? DependsOnField { get; set; }
    public string ConfigJson { get; set; } = "{}";
    public string ErrorMessage { get; set; } = string.Empty;
    public string? SuccessMessage { get; set; }
    public bool IsBlocking { get; set; } = true;
    public bool RequiresDependencyFilled { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

---

#### 1.2 Update FormField Entity
**Effort:** 10 minutes

**File:** `Repository/knk-web-api-v2/Models/FormField.cs`

**Tasks:**
- [ ] Add `ValidationRules` navigation property
- [ ] Add XML documentation

**Code:**
```csharp
/// <summary>
/// Validation rules that depend on other fields for cross-field validation.
/// </summary>
public List<FieldValidationRule> ValidationRules { get; set; } = new();
```

---

#### 1.3 Update DbContext
**Effort:** 15 minutes

**File:** `Repository/knk-web-api-v2/Data/ApplicationDbContext.cs`

**Tasks:**
- [ ] Add `DbSet<FieldValidationRule> FieldValidationRules { get; set; }`
- [ ] Configure relationships in OnModelCreating:
  - FormField → ValidationRules (one-to-many, cascade delete)
  - ValidationRule → DependsOnField (many-to-one, NO ACTION delete to prevent cascade issues)

**Code Example:**
```csharp
modelBuilder.Entity<FieldValidationRule>()
    .HasOne(r => r.FormField)
    .WithMany(f => f.ValidationRules)
    .HasForeignKey(r => r.FormFieldId)
    .OnDelete(DeleteBehavior.Cascade);

modelBuilder.Entity<FieldValidationRule>()
    .HasOne(r => r.DependsOnField)
    .WithMany()
    .HasForeignKey(r => r.DependsOnFieldId)
    .OnDelete(DeleteBehavior.NoAction);
```

---
- [ ] Run: `dotnet ef migrations add AddFieldValidationRule --project Repository/knk-web-api-v2`
    #### 1.1 Create FieldValidationRule Entity
    **Effort:** 30 minutes
    **Status:** ✅ COMPLETE

    **File:** `Repository/knk-web-api-v2/Models/FieldValidationRule.cs`

    **Tasks:**
    - [x] Create FieldValidationRule class
    - [x] Add properties: Id, FormFieldId, ValidationType, DependsOnFieldId, ConfigJson, ErrorMessage, SuccessMessage, IsBlocking, RequiresDependencyFilled, CreatedAt
    - [x] Add navigation properties: FormField, DependsOnField
    - [x] Add XML documentation for all properties
    - [x] Follow existing model patterns (see FormField.cs, FormStep.cs for reference)
- [ ] Verify migration includes:
  - FieldValidationRules table creation
  - FK to FormFields (cascade delete)
  - FK to FormFields for DependsOnFieldId (NO ACTION)
  - Indexes on FormFieldId, DependsOnFieldId
- [ ] Review generated SQL
- [ ] Apply: `dotnet ef database update --project Repository/knk-web-api-v2`
**Files:** `Repository/knk-web-api-v2/Migrations/[timestamp]_AddFieldValidationRule.cs`
    #### 1.2 Update FormField Entity
    **Effort:** 10 minutes
    **Status:** ✅ COMPLETE

    - [x] Add `ValidationRules` navigation property
#### 2.1 Create IFieldValidationRuleRepository Interface
**Effort:** 20 minutes
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/Repositories/Interfaces/IFieldValidationRuleRepository.cs`

**Tasks:**
- [x] Define repository interface
- [x] Add methods: GetByIdAsync, GetByFormFieldIdAsync, GetByFormConfigurationIdAsync, CreateAsync, UpdateAsync, DeleteAsync
- [x] Add dependency analysis methods: GetRulesDependingOnFieldAsync, HasCircularDependencyAsync
    - [x] Add XML documentation

---

#### 1.5 Create DTOs
**Effort:** 30 minutes

    #### 1.3 Update DbContext
#### 2.2 Implement FieldValidationRuleRepository
**Effort:** 1.5 hours
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/Repositories/FieldValidationRuleRepository.cs`

**Tasks:**
- [x] Implement all interface methods
- [x] Use EF Core Include() for navigation properties
- [x] Implement circular dependency detection logic (BFS algorithm)
- [x] Add error handling
    **Effort:** 15 minutes
    **Status:** ✅ COMPLETE

    **File:** `Repository/knk-web-api-v2/Data/ApplicationDbContext.cs`

    **Tasks:**
    - [x] Add `DbSet<FieldValidationRule> FieldValidationRules { get; set; }`
- [ ] Create ValidateFieldRequestDto
#### 2.3 Create IValidationMethod Interface
**Effort:** 15 minutes
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationMethod.cs`

**Tasks:**
- [x] Define interface for validation method implementations
- [x] Add ValidationType property
- [x] Add ValidateAsync method signature
- [x] Define ValidationMethodResult class with placeholders support
- [ ] Create ValidationResultDto
- [ ] Create ValidationMetadataDto
- [ ] Create ValidationIssueDto
- [ ] Add XML documentation

---

    #### 1.4 Create Database Migration
    **Effort:** 20 minutes
    **Status:** ✅ COMPLETE
#### 2.4 Create IValidationService Interface
**Effort:** 20 minutes
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationService.cs`

**Tasks:**
- [x] Define service interface
- [x] Add validation execution methods (ValidateFieldAsync, ValidateMultipleFieldsAsync)
- [x] Add configuration health check method (PerformConfigurationHealthCheckAsync)
- [x] Add dependency analysis method (GetDependentFieldIdsAsync)

**Reference:** See SPEC Part B.5 for complete interface

    **Tasks:**
    - [x] Run: `dotnet ef migrations add AddFieldValidationRule --project Repository/knk-web-api-v2`
    - [x] Verify migration includes:
        - FieldValidationRules table creation
        - FK to FormFields (cascade delete)
        - FK to FormFields for DependsOnFieldId (RESTRICT)
  - FieldValidationRule → FieldValidationRuleDto
#### 2.5 Implement ValidationService
**Effort:** 2 hours
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/Services/ValidationService.cs`

**Tasks:**
- [x] Implement ValidateFieldAsync with rule execution orchestration
- [x] Implement ValidateMultipleFieldsAsync for batch validation
- [x] Implement PerformConfigurationHealthCheckAsync with issue detection:
    - Broken dependencies
    - Field ordering validation
    - Circular dependency detection
    - Unknown validation methods
- [x] Implement GetDependentFieldIdsAsync
- [x] Add comprehensive error handling with try-catch
- [x] Support message placeholder interpolation
  - CreateFieldValidationRuleDto → FieldValidationRule
  - UpdateFieldValidationRuleDto → FieldValidationRule
- [ ] Handle navigation properties (FormField, DependsOnField)

---
## Phase 2: Repository & Service Layer

    **Status:** ✅ COMPLETE
#### 2.6 Register Services in DI Container
**Effort:** 10 minutes
**Status:** ✅ COMPLETE

**File:** `Repository/knk-web-api-v2/DependencyInjection/ServiceCollectionExtensions.cs`

**Tasks:**
- [x] Register IFieldValidationRuleRepository → FieldValidationRuleRepository (Scoped)
- [x] Register IValidationService → ValidationService (Scoped)
- [x] Register IValidationMethod implementations (Phase 3)

    **Files:** 
    **Tasks:**
### Phase 2 Summary
**Status:** ✅ COMPLETE
- **Total Effort:** ~5 hours (Actual: ~2.5 hours due to existing Phase 1 foundation)
- **Risk:** Medium (circular dependency detection requires careful testing)
- **Blockers:** None
- **Completion Date:** January 24, 2026
- **Build Status:** SUCCESS (0 errors, 10 pre-existing warnings)
    - [x] Create FieldValidationRuleDto
**Components Implemented:**
1. IFieldValidationRuleRepository interface - Full CRUD and dependency analysis
2. FieldValidationRuleRepository implementation - BFS circular dependency detection
3. IValidationMethod interface - Validation method contract
4. ValidationService implementation - Rule orchestration and health checks
5. DI registrations - Services wired into container
    - [x] Create CreateFieldValidationRuleDto
    - [x] Create UpdateFieldValidationRuleDto
    - [x] Create ValidateFieldRequestDto
    - [x] Create ValidationResultDto
    - [x] Create ValidationMetadataDto
    - [x] Create ValidationIssueDto
    - [x] Add XML documentation

    **Reference:** See SPEC Part B.3 for complete DTO definitions

#### 2.1 Create IFieldValidationRuleRepository Interface
**Effort:** 20 minutes

**File:** `Repository/knk-web-api-v2/Repositories/Interfaces/IFieldValidationRuleRepository.cs`

**Tasks:**
- [ ] Add dependency analysis methods: GetRulesDependingOnFieldAsync, HasCircularDependencyAsync

**Code Example:**
public interface IFieldValidationRuleRepository
    #### 1.6 Create AutoMapper Profile
    **Effort:** 15 minutes
    **Status:** ✅ COMPLETE

    **File:** `Repository/knk-web-api-v2/Mapping/FieldValidationRuleProfile.cs`

    **Tasks:**
    - [x] Create FieldValidationRuleProfile class
    - [x] Add mappings:
        - FieldValidationRule → FieldValidationRuleDto
        - CreateFieldValidationRuleDto → FieldValidationRule
        - UpdateFieldValidationRuleDto → FieldValidationRule
    - [x] Handle navigation properties (FormField, DependsOnField)
{
    Task<FieldValidationRule?> GetByIdAsync(int id);
    Task UpdateAsync(FieldValidationRule rule);
    ### Phase 1 Summary
    **Status:** ✅ COMPLETE
    - **Total Effort:** ~2 hours
    - **Risk:** Low (standard EF Core entity setup)
    - **Blockers:** None
    - **Completion Date:** January 24, 2026 (All components already implemented from prior work)
    Task DeleteAsync(int id);
    Task<IEnumerable<FieldValidationRule>> GetRulesDependingOnFieldAsync(int fieldId);
    Task<bool> HasCircularDependencyAsync(int fieldId, int dependsOnFieldId);
}
```

---

#### 2.2 Implement FieldValidationRuleRepository
**Effort:** 1.5 hours

**File:** `Repository/knk-web-api-v2/Repositories/FieldValidationRuleRepository.cs`

**Tasks:**
- [ ] Implement all interface methods
- [ ] Use EF Core Include() for navigation properties
- [ ] Implement circular dependency detection logic
- [ ] Add error handling

**Key Implementation Notes:**

**GetByFormConfigurationIdAsync:**
```csharp
public async Task<IEnumerable<FieldValidationRule>> GetByFormConfigurationIdAsync(int formConfigurationId)
{
    // Need to query all fields in the configuration first
    var fieldIds = await _context.FormSteps
        .Where(s => s.FormConfigurationId == formConfigurationId)
        .SelectMany(s => s.Fields)
        .Select(f => f.Id)
        .ToListAsync();
    
    return await _context.FieldValidationRules
        .Include(r => r.FormField)
        .Include(r => r.DependsOnField)
        .Where(r => fieldIds.Contains(r.FormFieldId))
        .ToListAsync();
}
```

**HasCircularDependencyAsync:**
```csharp
public async Task<bool> HasCircularDependencyAsync(int fieldId, int dependsOnFieldId)
{
    var visited = new HashSet<int>();
    var stack = new Stack<int>();
    stack.Push(dependsOnFieldId);
    
    while (stack.Count > 0)
    {
        var currentId = stack.Pop();
        if (currentId == fieldId) return true; // Circular dependency found
        if (visited.Contains(currentId)) continue;
        visited.Add(currentId);
        
        var dependencies = await _context.FieldValidationRules
            .Where(r => r.FormFieldId == currentId && r.DependsOnFieldId.HasValue)
            .Select(r => r.DependsOnFieldId!.Value)
            .ToListAsync();
        
        foreach (var dep in dependencies)
        {
            stack.Push(dep);
        }
    }
    
    return false;
}
```

---

#### 2.3 Create IValidationMethod Interface
**Effort:** 15 minutes

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationMethod.cs`

**Tasks:**
- [ ] Define interface for validation method implementations
- [ ] Add ValidationType property
- [ ] Add ValidateAsync method signature

**Code:**
```csharp
public interface IValidationMethod
{
    string ValidationType { get; }
    Task<ValidationResultDto> ValidateAsync(
        FieldValidationRule rule, 
        object? fieldValue, 
        Dictionary<string, object?> formContextData
    );
}
```

---

#### 2.4 Create IValidationService Interface
**Effort:** 20 minutes

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationService.cs`

**Tasks:**
- [ ] Define service interface
- [ ] Add CRUD methods for validation rules
- [ ] Add validation execution methods
- [ ] Add configuration health check method

**Reference:** See SPEC Part B.5 for complete interface

---

#### 2.5 Implement ValidationService
**Effort:** 2 hours

**File:** `Repository/knk-web-api-v2/Services/ValidationService.cs`

**Tasks:**
- [ ] Implement CRUD operations (use repository)
- [ ] Implement ValidateFieldAsync (dispatch to appropriate IValidationMethod)
- [ ] Implement ValidateAllFieldRulesAsync
- [ ] Implement ValidateConfigurationHealthAsync
- [ ] Add error handling and logging

**Key Implementation - ValidateFieldAsync:**
```csharp
public async Task<ValidationResultDto> ValidateFieldAsync(ValidateFieldRequestDto request)
{
    // 1. Fetch field with validation rules
    var field = await _fieldRepository.GetByIdAsync(request.FieldId);
    if (field == null) throw new KeyNotFoundException($"Field {request.FieldId} not found");
    
    // 2. Execute all validation rules for the field
    var results = new List<ValidationResultDto>();
    foreach (var rule in field.ValidationRules)
    {
        // 3. Find appropriate validation method
        var validationMethod = _validationMethods.FirstOrDefault(m => m.ValidationType == rule.ValidationType);
        if (validationMethod == null)
        {
            throw new NotImplementedException($"Validation type '{rule.ValidationType}' is not implemented");
        }
        
        // 4. Execute validation
        var result = await validationMethod.ValidateAsync(rule, request.FieldValue, request.FormContextData);
        results.Add(result);
        
        // 5. If blocking validation fails, return immediately
        if (!result.IsValid && result.IsBlocking)
        {
            return result;
        }
    }
    
    // 6. Return first failure or success
    return results.FirstOrDefault(r => !r.IsValid) ?? new ValidationResultDto { IsValid = true };
}
```

**Configuration Health Check Implementation:**
```csharp
public async Task<IEnumerable<ValidationIssueDto>> ValidateConfigurationHealthAsync(int formConfigurationId)
{
    var issues = new List<ValidationIssueDto>();
    var config = await _configRepository.GetByIdAsync(formConfigurationId);
    if (config == null) throw new KeyNotFoundException($"Configuration {formConfigurationId} not found");
    
    // Build field lookup with step/order info
    var fieldLookup = config.Steps
        .SelectMany((step, stepIdx) => step.Fields.Select(field => new
        {
            Field = field,
            StepIndex = stepIdx,
            Order = field.Order ?? 0
        }))
        .ToDictionary(x => x.Field.Id);
    
    foreach (var step in config.Steps)
    {
        foreach (var field in step.Fields)
        {
            foreach (var rule in field.ValidationRules)
            {
                // Check 1: Dependency field exists?
                if (rule.DependsOnFieldId.HasValue && !fieldLookup.ContainsKey(rule.DependsOnFieldId.Value))
                {
                    issues.Add(new ValidationIssueDto
                    {
                        Severity = "Error",
                        Message = $"Field '{field.Label}' has validation rule depending on deleted field (ID: {rule.DependsOnFieldId})",
                        FieldId = field.Id,
                        RuleId = rule.Id,
                        FieldLabel = field.Label
                    });
                }
                
                // Check 2: Dependency comes BEFORE this field?
                if (rule.DependsOnFieldId.HasValue && fieldLookup.ContainsKey(rule.DependsOnFieldId.Value))
                {
                    var depInfo = fieldLookup[rule.DependsOnFieldId.Value];
                    var currentInfo = fieldLookup[field.Id];
                    
                    if (depInfo.StepIndex > currentInfo.StepIndex ||
                        (depInfo.StepIndex == currentInfo.StepIndex && depInfo.Order > currentInfo.Order))
                    {
                        issues.Add(new ValidationIssueDto
                        {
                            Severity = "Warning",
                            Message = $"Field '{field.Label}' depends on '{depInfo.Field.Label}' which comes AFTER it. Reorder fields for proper validation.",
                            FieldId = field.Id,
                            RuleId = rule.Id,
                            FieldLabel = field.Label
                        });
                    }
                }
            }
        }
    }
    
    return issues;
}
```

---

#### 2.6 Register Services in DI Container
**Effort:** 10 minutes

**File:** `Repository/knk-web-api-v2/Program.cs` or `Startup.cs`

**Tasks:**
- [ ] Register IFieldValidationRuleRepository → FieldValidationRuleRepository
- [ ] Register IValidationService → ValidationService
- [ ] Register IValidationMethod implementations (next phase)

**Code:**
```csharp
builder.Services.AddScoped<IFieldValidationRuleRepository, FieldValidationRuleRepository>();
builder.Services.AddScoped<IValidationService, ValidationService>();

// Validation methods (added in Phase 3)
builder.Services.AddScoped<IValidationMethod, LocationInsideRegionValidator>();
builder.Services.AddScoped<IValidationMethod, RegionContainmentValidator>();
builder.Services.AddScoped<IValidationMethod, ConditionalRequiredValidator>();
```

---

### Phase 2 Summary
- **Total Effort:** ~5 hours
- **Risk:** Medium (circular dependency detection requires careful testing)
- **Blockers:** None

---

## Phase 3: Validation Method Implementations

### Priority: HIGH - Core business logic

**Important Decision Point:** This phase requires WorldGuard region integration. See questions in SPEC Part D.1.

#### 3.1 Implement LocationInsideRegionValidator
**Effort:** 2 hours (+ integration time for WorldGuard API)

**File:** `Repository/knk-web-api-v2/Services/ValidationMethods/LocationInsideRegionValidator.cs`

**Tasks:**
- [x] Implement IValidationMethod interface
- [x] Parse ConfigJson for regionPropertyPath
- [x] Fetch dependency field value from formContextData
- [x] Fetch dependency entity from database
- [x] Extract region ID using property path
- [x] Fetch Location coordinates from fieldValue
- [x] Call region validation service/API
- [x] Build ValidationResultDto with placeholders
- [x] Handle edge cases (dependency not filled, entity not found, etc.)

**Code Structure:**
```csharp
public class LocationInsideRegionValidator : IValidationMethod
{
    public string ValidationType => "LocationInsideRegion";
    
    private readonly ILocationRepository _locationRepo;
    private readonly IRegionService _regionService; // TO BE IMPLEMENTED
    private readonly IGenericEntityService _entityService;
    
    public async Task<ValidationResultDto> ValidateAsync(
        FieldValidationRule rule, 
        object? fieldValue, 
        Dictionary<string, object?> formContextData)
    {
        // 1. Parse ConfigJson
        var config = JsonSerializer.Deserialize<LocationInsideRegionConfig>(rule.ConfigJson);
        var regionPropertyPath = config?.RegionPropertyPath ?? "WgRegionId";
        
        // 2. Check if dependency field is filled
        var dependsOnFieldName = GetFieldName(rule.DependsOnFieldId);
        if (!formContextData.TryGetValue(dependsOnFieldName, out var parentEntityId) || parentEntityId == null)
        {
            if (rule.RequiresDependencyFilled)
            {
                return new ValidationResultDto 
                { 
                    IsValid = false, 
                    Message = rule.ErrorMessage,
                    IsBlocking = rule.IsBlocking
                };
            }
            return new ValidationResultDto 
            { 
                IsValid = true,  // Pass validation if dependency not required
                Message = $"Validation pending until {dependsOnFieldName} is filled.",
                IsBlocking = false
            };
        }
        
        // 3. Fetch parent entity to get region ID
        var parentEntity = await _entityService.GetByIdAsync(GetEntityType(rule.DependsOnFieldId), (int)parentEntityId);
        if (parentEntity == null)
        {
            return new ValidationResultDto { IsValid = false, Message = "Parent entity not found", IsBlocking = true };
        }
        
        var regionId = ExtractPropertyValue(parentEntity, regionPropertyPath);
        if (regionId == null)
        {
            return new ValidationResultDto { IsValid = false, Message = "Parent entity has no region defined", IsBlocking = true };
        }
        
        // 4. Fetch Location coordinates
        var locationId = Convert.ToInt32(fieldValue);
        var location = await _locationRepo.GetByIdAsync(locationId);
        if (location == null)
        {
            return new ValidationResultDto { IsValid = false, Message = "Location not found", IsBlocking = true };
        }
        
        // 5. Call region validation service
        var isInside = await _regionService.IsLocationInsideRegion(regionId.ToString(), location);
        
        // 6. Build result with placeholders
        if (isInside)
        {
            return new ValidationResultDto
            {
                IsValid = true,
                Message = rule.SuccessMessage,
                IsBlocking = false,
                Placeholders = new Dictionary<string, string>
                {
                    { "entityName", GetEntityDisplayName(parentEntity) },
                    { "regionName", regionId.ToString() }
                }
            };
        }
        else
        {
            return new ValidationResultDto
            {
                IsValid = false,
                Message = rule.ErrorMessage,
                IsBlocking = rule.IsBlocking,
                Placeholders = new Dictionary<string, string>
                {
                    { "entityName", GetEntityDisplayName(parentEntity) },
                    { "coordinates", $"(X: {location.X}, Z: {location.Z})" },
                    { "regionName", regionId.ToString() }
                }
            };
        }
    }
}

public class LocationInsideRegionConfig
{
    public string RegionPropertyPath { get; set; } = "WgRegionId";
    public bool AllowBoundary { get; set; } = false;
}
```

**Blockers:**
- ⚠️ **IRegionService** needs to be implemented
- ⚠️ **WorldGuard region API integration** required

**Recommended Approach:**
1. Create IRegionService interface with IsLocationInsideRegion method
2. Implement RegionService that calls Minecraft plugin API endpoint
3. Plugin exposes REST endpoint: `/api/regions/{regionId}/contains?x={x}&z={z}`
4. Alternative: Store region boundaries in database and do calculation in API

---

#### 3.2 Implement RegionContainmentValidator
**Effort:** 2 hours

**File:** `Repository/knk-web-api-v2/Services/ValidationMethods/RegionContainmentValidator.cs`

**Tasks:**
- [x] Similar structure to LocationInsideRegionValidator
- [x] Parse ConfigJson for parentRegionPath, requireFullContainment
- [x] Fetch child region boundaries
- [x] Fetch parent region boundaries
- [x] Validate all child boundary points are inside parent region
- [x] Build detailed error message with violating coordinates

**Blockers:**
- Same as LocationInsideRegionValidator (IRegionService integration)

---

#### 3.3 Implement ConditionalRequiredValidator
**Effort:** 1 hour

**File:** `Repository/knk-web-api-v2/Services/ValidationMethods/ConditionalRequiredValidator.cs`

**Tasks:**
- [x] Parse ConfigJson for condition (operator, value)
- [x] Fetch dependency field value
- [x] Evaluate condition
- [x] If condition TRUE and field empty: fail validation
- [x] If condition FALSE: pass validation
- [x] Build result message

**Code Structure:**
```csharp
public class ConditionalRequiredValidator : IValidationMethod
{
    public string ValidationType => "ConditionalRequired";
    
    public async Task<ValidationResultDto> ValidateAsync(
        FieldValidationRule rule, 
        object? fieldValue, 
        Dictionary<string, object?> formContextData)
    {
        var config = JsonSerializer.Deserialize<ConditionalRequiredConfig>(rule.ConfigJson);
        var dependsOnFieldName = GetFieldName(rule.DependsOnFieldId);
        
        if (!formContextData.TryGetValue(dependsOnFieldName, out var dependencyValue))
        {
            // Dependency not filled, validation passes
            return new ValidationResultDto { IsValid = true, IsBlocking = false };
        }
        
        bool conditionMet = EvaluateCondition(config.Condition, dependencyValue);
        
        if (conditionMet && (fieldValue == null || string.IsNullOrWhiteSpace(fieldValue.ToString())))
        {
            return new ValidationResultDto
            {
                IsValid = false,
                Message = rule.ErrorMessage,
                IsBlocking = rule.IsBlocking,
                Placeholders = new Dictionary<string, string>
                {
                    { "dependencyFieldName", dependsOnFieldName }
                }
            };
        }
        
        return new ValidationResultDto
        {
            IsValid = true,
            Message = rule.SuccessMessage,
            IsBlocking = false
        };
    }
    
    private bool EvaluateCondition(ConditionConfig condition, object? value)
    {
        return condition.Operator switch
        {
            "equals" => Equals(value, condition.Value),
            "notEquals" => !Equals(value, condition.Value),
            "greaterThan" => Convert.ToDouble(value) > Convert.ToDouble(condition.Value),
            "lessThan" => Convert.ToDouble(value) < Convert.ToDouble(condition.Value),
            "in" => condition.Values?.Contains(value) ?? false,
            _ => false
        };
    }
}

public class ConditionalRequiredConfig
{
    public ConditionConfig Condition { get; set; } = new();
}

public class ConditionConfig
{
    public string Operator { get; set; } = "equals"; // "equals", "notEquals", "greaterThan", "lessThan", "in"
    public object? Value { get; set; }
    public List<object>? Values { get; set; } // For "in" operator
}
```

---

### Phase 3 Summary
- **Total Effort:** ~5 hours (+ WorldGuard integration time)
- **Risk:** HIGH (depends on external WorldGuard API)
- **Blockers:** IRegionService implementation

---

## Phase 4: API Controllers

### Priority: HIGH - Exposes functionality to frontend

#### 4.1 Create FieldValidationRulesController
**Effort:** 1 hour

**File:** `Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs`

**Tasks:**
- [x] Implement all CRUD endpoints
- [x] Add validation execution endpoint
- [x] Add configuration health check endpoint
- [x] Add proper error handling
- [ ] Add XML documentation for Swagger

**Reference:** See SPEC Part B.7 for complete controller code

**Endpoints:**
- `GET /api/field-validation-rules/{id}`
- `GET /api/field-validation-rules/by-field/{fieldId}`
- `GET /api/field-validation-rules/by-configuration/{configId}`
- `POST /api/field-validation-rules`
- `PUT /api/field-validation-rules/{id}`
- `DELETE /api/field-validation-rules/{id}`
- `POST /api/field-validation-rules/validate`
- `GET /api/field-validation-rules/health-check/configuration/{configId}`

---

#### 4.2 Test API Endpoints
**Effort:** 1 hour

**Tasks:**
- [ ] Test CRUD operations via Postman/Swagger
- [ ] Test validation execution with sample data
- [ ] Test configuration health check
- [ ] Verify error handling
- [ ] Document sample requests/responses

---

### Phase 4 Summary
- **Total Effort:** ~2 hours
- **Risk:** Low
- **Blockers:** Phase 2 completion

---

## Phase 5: Frontend - DTOs & API Client

### Priority: HIGH - Needed for UI components

#### 5.1 Create TypeScript DTOs
**Effort:** 30 minutes

**File:** `Repository/knk-web-app/src/types/fieldValidationRuleDtos.ts`

**Tasks:**
- [x] Create all DTO interfaces
- [x] Match backend DTO structure exactly
- [x] Export all types

**Reference:** See SPEC Part C.1 for complete type definitions

---

#### 5.2 Create API Client
**Effort:** 30 minutes

**File:** `Repository/knk-web-app/src/api/fieldValidationRuleClient.ts`

**Tasks:**
- [x] Create client with all CRUD methods
- [x] Add validateField method
- [x] Add validateConfigurationHealth method
- [x] Use existing axios patterns
- [x] Add error handling

**Reference:** See SPEC Part C.2 for complete client code

---

### Phase 5 Summary
- **Total Effort:** ~1 hour
- **Risk:** Low
- **Blockers:** None

---

## Phase 6: Frontend - UI Components

### Priority: HIGH - Admin interface for configuring validation

#### 6.1 Create ValidationRuleBuilder Component
**Effort:** 3 hours

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/ValidationRuleBuilder.tsx`

**Tasks:**
- [ ] Create component with form for rule configuration
- [ ] Add validation type dropdown
- [ ] Add dependency field selector
- [ ] Add ConfigJson editor (textarea with JSON validation)
- [ ] Add error/success message inputs
- [ ] Add IsBlocking and RequiresDependencyFilled checkboxes
- [ ] Auto-generate ConfigJson templates based on validation type
- [ ] Add save/cancel handlers
- [ ] Style with existing component patterns

**Reference:** See SPEC Part C.3 for complete component code

**Key Features:**
- Auto-populate ConfigJson when validation type changes
- Filter dependency field options (exclude current field)
- Validate JSON before save
- Show field ordering warning

---

#### 6.2 Update FieldEditor Component
**Effort:** 2 hours

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/FieldEditor.tsx`

**Tasks:**
- [ ] Add "Cross-Field Validation Rules" section
- [ ] Load validation rules for current field
- [ ] Display list of existing rules with summary info
- [ ] Add "+ Add Rule" button to show ValidationRuleBuilder
- [ ] Add delete rule functionality
- [ ] Handle rule CRUD operations
- [ ] Update UI when rules change

**Reference:** See SPEC Part C.4 for code examples

**UI Structure:**
```
Field Editor
├── Basic Settings (existing)
├── Validations (existing)
└── Cross-Field Validation Rules (NEW)
    ├── Rule 1: LocationInsideRegion [Blocking] Depends on: TownId
    ├── Rule 2: ...
    └── [+ Add Rule] button
```

---

#### 6.3 Update FieldRenderer Component
**Effort:** 3 hours

**File:** `Repository/knk-web-app/src/components/FormWizard/FieldRenderers.tsx`

**Tasks:**
- [ ] Add validation execution logic
- [ ] Call validation API when field value changes
- [ ] Store validation results in component state
- [ ] Display validation feedback (success/error/pending)
- [ ] Implement placeholder interpolation
- [ ] Handle blocking vs non-blocking validations
- [ ] Add debouncing (300ms delay)
- [ ] Re-validate dependent fields when dependency changes

**Reference:** See SPEC Part C.5 for complete implementation

**Validation Feedback UI:**
- ✅ Success: Green checkmark + message
- ❌ Blocking Error: Red X + message + field highlight
- ⚠️ Warning: Yellow triangle + message
- ⏳ Pending: Gray icon + "Validation pending..."

---

#### 6.4 Create ConfigurationHealthPanel Component
**Effort:** 1.5 hours

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/ConfigurationHealthPanel.tsx`

**Tasks:**
- [ ] Create component to display configuration health issues
- [ ] Load issues from API on mount
- [ ] Display issues grouped by severity
- [ ] Show field labels and rule details
- [ ] Add refresh functionality
- [ ] Style with appropriate colors (red for errors, yellow for warnings)

**Reference:** See SPEC Part C.6 for complete component code

---

#### 6.5 Integrate ConfigurationHealthPanel into FormConfigBuilder
**Effort:** 30 minutes

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/FormConfigBuilder.tsx`

**Tasks:**
- [ ] Import ConfigurationHealthPanel
- [ ] Add to UI (bottom of form, before save button)
- [ ] Refresh health check when fields/rules change
- [ ] Display issues count in header

**UI Location:**
```
FormConfigBuilder
├── Configuration Settings
├── Steps Sidebar
├── Step Editor
├── [Configuration Health Panel] ← NEW
└── Save/Cancel Buttons
```

---

### Phase 6 Summary
- **Total Effort:** ~10 hours
- **Risk:** Medium (complex UI logic)
- **Blockers:** Phase 5 completion

---

## Phase 7: Testing & Validation

### Priority: CRITICAL - Ensure feature works end-to-end

#### 7.1 Backend Unit Tests
**Effort:** 3 hours

**File:** `Repository/knkwebapi_v2.Tests/Services/ValidationServiceTests.cs`

**Tasks:**
- [ ] Test FieldValidationRuleRepository CRUD operations
- [ ] Test circular dependency detection
- [ ] Test ValidationService validation execution
- [ ] Test configuration health check
- [ ] Test each validation method implementation
- [ ] Mock dependencies (IRegionService, etc.)

**Test Cases:**
- Create validation rule → Success
- Create circular dependency → Error
- Validate field with passing rule → Success
- Validate field with failing rule → Error with message
- Validate field with missing dependency → Pending message
- Configuration health check with valid config → No issues
- Configuration health check with broken dependency → Error issue
- Configuration health check with wrong field order → Warning issue

---

#### 7.2 Frontend Component Tests
**Effort:** 2 hours

**Tasks:**
- [ ] Test ValidationRuleBuilder component
- [ ] Test FieldEditor validation rule management
- [ ] Test FieldRenderer validation execution
- [ ] Test ConfigurationHealthPanel display

**Test Framework:** React Testing Library + Jest

---

#### 7.3 Integration Tests
**Effort:** 2 hours

**Tasks:**
- [ ] Test end-to-end flow: Create rule → Validate field → Display result
- [ ] Test District creation with Location validation
- [ ] Test configuration health check with real data
- [ ] Test field reordering impact on validation

---

#### 7.4 Manual QA Testing
**Effort:** 2 hours

**Test Scenarios:**
1. **Happy Path:**
   - Create District form configuration
   - Add TownId field
   - Add LocationId field
   - Add LocationInsideRegion rule to LocationId depending on TownId
   - Fill out form: Select Town → Select Location inside town → Success message

2. **Validation Failure:**
   - Fill out form: Select Town → Select Location outside town → Error message + blocked

3. **Dependency Missing:**
   - Fill out form: Skip Town → Fill Location → "Pending" message

4. **Field Reordering:**
   - Create rule with dependency on later field → Warning in health check

5. **Multiple Rules:**
   - Add 2 rules to same field → Both execute, both messages display

6. **Circular Dependency:**
   - Try to create Field A depends on B, Field B depends on A → Blocked with error

---

### Phase 7 Summary
- **Total Effort:** ~9 hours
- **Risk:** Medium
- **Blockers:** All previous phases

---

## Phase 8: Documentation & Deployment

### Priority: MEDIUM - Essential for maintainability

#### 8.1 Update API Documentation
**Effort:** 1 hour

**Tasks:**
- [ ] Ensure Swagger docs are complete for new endpoints
- [ ] Add example requests/responses
- [ ] Document validation types and ConfigJson schemas
- [ ] Update API reference guide

---

#### 8.2 Create User Guide
**Effort:** 2 hours

**File:** `docs/user-guides/FORM_VALIDATION_CONFIGURATION.md`

**Tasks:**
- [ ] Document how to create validation rules in FormConfigBuilder
- [ ] Provide examples for each validation type
- [ ] Explain dependency field ordering
- [ ] Show configuration health check usage
- [ ] Include screenshots

---

#### 8.3 Deploy to Dev Environment
**Effort:** 1 hour

**Tasks:**
- [ ] Apply database migration
- [ ] Deploy backend changes
- [ ] Deploy frontend changes
- [ ] Smoke test on dev server
- [ ] Notify team for testing

---

### Phase 8 Summary
- **Total Effort:** ~4 hours
- **Risk:** Low
- **Blockers:** Phase 7 completion

---

## Total Project Summary

**Total Estimated Effort:** 40-45 hours (~5-6 days for 1 developer)

**Phase Breakdown:**
- Phase 1: Backend Foundation → 2 hours
- Phase 2: Repository & Service → 5 hours
- Phase 3: Validation Methods → 5 hours (+ WorldGuard integration)
- Phase 4: API Controllers → 2 hours
- Phase 5: Frontend DTOs/Client → 1 hour
- Phase 6: Frontend UI → 10 hours
- Phase 7: Testing → 9 hours
- Phase 8: Documentation → 4 hours

**Critical Path:**
1. Phase 1 (Foundation) → Phase 2 (Services) → Phase 3 (Validators) → Phase 4 (API) → Phase 5 (Frontend DTOs) → Phase 6 (UI) → Phase 7 (Testing) → Phase 8 (Deploy)

**Parallel Work Opportunities:**
- Phase 5 (Frontend DTOs) can start once Phase 2 (DTOs defined) is complete
- Phase 6.1 (ValidationRuleBuilder UI) can be developed independently with mock data
- Documentation (Phase 8.2) can be written during testing phase

**Key Risks:**
1. **WorldGuard Integration (Phase 3):** Unknown effort, may require plugin development
2. **Complex Validation Logic:** Edge cases may require additional development time
3. **UI Complexity:** FieldRenderer validation execution has many moving parts

**Mitigation Strategies:**
- Start WorldGuard integration investigation early (parallel with Phase 1-2)
- Add extra buffer time (20%) for unexpected issues
- Break down Phase 6 into smaller incremental deliverables

---

## Implementation Checklist

### Week 1: Backend Foundation
- [ ] Phase 1: Data Model (Day 1)
- [ ] Phase 2: Repository & Service (Day 1-2)
- [x] Phase 3: Validation Methods (Day 2-3)
- [ ] Phase 4: API Controllers (Day 3)

### Week 2: Frontend & Testing
- [ ] Phase 5: Frontend DTOs/Client (Day 1)
- [ ] Phase 6: UI Components (Day 1-3)
- [ ] Phase 7: Testing (Day 3-4)
- [ ] Phase 8: Documentation & Deploy (Day 4-5)

---

**End of Implementation Roadmap**
