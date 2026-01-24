# SPEC: Inter-Field Validation Dependencies for FormConfiguration

**Status:** Requirements Definition  
**Created:** January 18, 2026  
**Last Updated:** January 18, 2026

## Overview

This specification defines the inter-field validation dependency framework for the FormConfiguration system. It enables administrators to configure cross-field validation rules where one field's value is used as a constraint, filter, or validation parameter for another field. This is critical for maintaining data integrity when form fields have hierarchical or spatial relationships.

**Primary Use Cases:**
- **Spatial Containment:** Validate that a Location is inside a parent entity's WorldGuard region
- **Region Hierarchy:** Ensure a child region (District, Street) is fully contained within a parent region (Town, District)
- **Conditional Validation:** Apply validation rules based on the value of another field
- **Data Consistency:** Prevent invalid relationships between related entities

---

## Part A: Business Requirements

### A.1 Core Scenarios

#### Scenario 1: District Creation - Location Must Be Inside Town Region
**Context:**  
When creating a District entity, the admin must select:
1. `Town` - The parent town the district belongs to
2. `WgRegionId` - The WorldGuard region defining the district boundaries
3. `Location` - The spawn point for the district

**Requirement:**  
The `Location` coordinates MUST be inside the `Town`'s WorldGuard region. The system must:
- Detect when both `Town` and `Location` are filled
- Fetch the `Town` entity to extract its `WgRegionId`
- Validate that the `Location` coordinates fall within that region's boundaries
- Display clear success/error feedback to the user
- Block form submission if validation fails (configurable)

**Configuration by Admin:**
1. Admin creates FormConfiguration for "District"
2. In the FormConfigBuilder, admin adds fields in order:
   - Step 1: `TownId` (relationship field)
   - Step 2: `LocationId` (relationship field)
3. Admin adds a FieldValidationRule to `LocationId`:
   - **ValidationType:** "LocationInsideRegion"
   - **DependsOnFieldId:** `TownId` field
   - **ConfigJson:** `{ "regionPropertyPath": "WgRegionId" }`
   - **ErrorMessage:** "Location is outside the town boundaries. Please select a location within {townName}."
   - **SuccessMessage:** "Location is within town boundaries ✓"
   - **IsBlocking:** true

#### Scenario 2: District Creation - Region Must Be Inside Town Region
**Context:**  
When creating a District, the `WgRegionId` (district boundaries) must be fully contained within the parent `Town`'s region.

**Requirement:**  
All coordinates defining the district's WorldGuard region must fall within the town's region boundaries. The system must:
- Extract all boundary points of the district region
- Fetch the parent town's region boundaries
- Validate complete containment (no overlap allowed outside parent)
- Provide detailed error messages indicating which coordinates violate the constraint

**Configuration by Admin:**
1. Admin adds `WgRegionId` field to District form
2. Admin adds FieldValidationRule to `WgRegionId`:
   - **ValidationType:** "RegionContainment"
   - **DependsOnFieldId:** `TownId` field
   - **ConfigJson:** `{ "parentRegionPath": "WgRegionId", "requireFullContainment": true }`
   - **ErrorMessage:** "District region extends outside town boundaries. All district boundaries must be within {townName}."
   - **IsBlocking:** true

#### Scenario 3: Conditional Validation Based on Field Value
**Context:**  
Some validation rules should only apply when another field meets certain criteria.

**Example:**  
- Field: `IsPublic` (boolean)
- Field: `PublicAccessPoint` (Location)
- Rule: If `IsPublic` is true, then `PublicAccessPoint` is required AND must be inside the main region

**Configuration by Admin:**
1. Admin adds both fields to form
2. Admin adds FieldValidationRule to `PublicAccessPoint`:
   - **ValidationType:** "ConditionalRequired"
   - **DependsOnFieldId:** `IsPublic` field
   - **ConfigJson:** `{ "condition": { "operator": "equals", "value": true } }`
   - **ErrorMessage:** "Public structures require a public access point."
   - **IsBlocking:** true
3. Admin adds second FieldValidationRule to `PublicAccessPoint`:
   - **ValidationType:** "LocationInsideRegion"
   - **DependsOnFieldId:** `WgRegionId` field
   - (Additional region validation)

### A.2 Field Dependency Resolution

**Field Ordering Constraint:**  
For validation to execute properly, dependency fields MUST be filled before dependent fields. This is an **admin responsibility** during FormConfiguration setup.

**System Behavior:**
1. **Dependency Detection:** System analyzes all FieldValidationRules and identifies field dependencies
2. **Order Validation:** System checks if dependency fields appear BEFORE dependent fields in the form flow
3. **Feedback to Admin:**
   - ✅ **Valid Order:** Dependency field is in a previous step OR earlier in the same step
   - ⚠️ **Warning:** Dependency field is later in the same step OR in a future step
   - ❌ **Error:** Dependency field does not exist (deleted/invalid reference)
4. **Runtime Handling:**
   - If dependency field is not yet filled: Display informational message "Validation will execute when [Field Name] is filled"
   - If dependency field is filled: Execute validation immediately
   - If validation fails: Display error message and optionally block progression

**Configuration Health Check:**  
The FormConfigBuilder UI displays a "Configuration Health" panel showing:
- All validation rules
- Their dependency status
- Any ordering issues that need admin attention

### A.3 Validation Execution Flow

**When Validation Executes:**
1. **On Field Change:** When the dependent field value changes
2. **On Dependency Change:** When the dependency field value changes (re-validate all dependent fields)
3. **Before Step Progression:** Validate all fields in current step before allowing "Next"
4. **Before Form Submission:** Final validation of all fields with rules

**Validation Process:**
```
1. User updates Field A (dependent field)
2. System checks if Field A has FieldValidationRules
3. For each rule:
   a. Check if DependsOnFieldId is specified
   b. If yes, check if that field is filled in form context
   c. If not filled AND RequiresDependencyFilled = false:
      - Skip validation (show "pending" message)
   d. If filled OR RequiresDependencyFilled = true:
      - Call validation service with field value + form context
      - Receive ValidationResultDto
      - Display result (success/error message)
      - If IsBlocking = true AND IsValid = false:
        * Mark field as invalid
        * Prevent step progression
```

### A.4 Validation Types (v1 Scope)

#### LocationInsideRegion
**Purpose:** Validate that a Location's coordinates fall within a WorldGuard region

**Required Dependency Field:** Field containing entity reference with `WgRegionId` property

**ConfigJson Schema:**
```json
{
  "regionPropertyPath": "WgRegionId",  // Path to region ID in dependency entity
  "allowBoundary": false  // Optional: whether coordinates ON boundary are valid
}
```

**Validation Logic:**
1. Extract `regionPropertyPath` from ConfigJson
2. Fetch dependency field value (entity ID)
3. Fetch entity from database
4. Extract region ID using property path
5. Fetch Location coordinates from field value
6. Call region validation service: `IsLocationInsideRegion(regionId, coordinates)`
7. Return success/failure with contextual message

**Example Error Message:**  
"Location (X: 1234, Z: 5678) is outside {townName}'s boundaries. Please select a location within the town region."

#### RegionContainment
**Purpose:** Validate that a child WorldGuard region is fully contained within a parent region

**Required Dependency Field:** Field containing entity reference with region property

**ConfigJson Schema:**
```json
{
  "parentRegionPath": "WgRegionId",  // Path to parent region in dependency entity
  "requireFullContainment": true,  // If false, allows partial overlap
  "maxOverlapPercentage": 0  // If requireFullContainment=false, max allowed overlap %
}
```

**Validation Logic:**
1. Extract child region boundaries from field value
2. Fetch parent entity from dependency field
3. Extract parent region ID using property path
4. Fetch parent region boundaries
5. Check containment: All child boundary points within parent region
6. Return success/failure with details on violating coordinates

**Example Error Message:**  
"District region extends outside town boundaries at 3 points. All boundaries must be within {townName}."

#### ConditionalRequired
**Purpose:** Make a field required only when another field meets a condition

**Required Dependency Field:** Field to evaluate condition against

**ConfigJson Schema:**
```json
{
  "condition": {
    "operator": "equals" | "notEquals" | "greaterThan" | "lessThan" | "in",
    "value": <any> | "values": [<any>]  // For 'in' operator
  }
}
```

**Validation Logic:**
1. Evaluate condition against dependency field value
2. If condition is TRUE and field is empty: Validation fails
3. If condition is FALSE: Validation passes (field not required)
4. If condition is TRUE and field is filled: Validation passes

**Example Error Message:**  
"Public structures require a public access point location."

### A.5 Validation Result Handling

**ValidationResultDto Structure:**
```typescript
{
  isValid: boolean;
  message: string;  // Success or error message
  placeholders?: { [key: string]: string };  // For message interpolation
  isBlocking: boolean;  // From FieldValidationRule config
  metadata?: {
    validationType: string;
    executedAt: string;  // ISO timestamp
    dependencyFieldName?: string;
    dependencyFieldValue?: any;
  }
}
```

**Message Placeholder Interpolation:**  
Admin-configured messages can contain placeholders that are replaced at runtime:
- `{townName}` - Display name of dependency entity
- `{regionName}` - Name of the region
- `{coordinates}` - Location coordinates that failed validation
- `{fieldLabel}` - Label of the dependent field
- Custom placeholders based on validation type

**Example:**
```
ErrorMessage Template: "Location {coordinates} is outside {townName}'s boundaries."
Placeholders: { "coordinates": "(X: 1234, Z: 5678)", "townName": "Kingsport" }
Final Message: "Location (X: 1234, Z: 5678) is outside Kingsport's boundaries."
```

### A.6 Blocking vs Non-Blocking Validation

**IsBlocking = true (Default):**
- Validation failure prevents:
  - Field from being marked as complete
  - Step progression ("Next" button disabled)
  - Form submission
- User must resolve the issue before proceeding
- Use for: Critical data integrity constraints

**IsBlocking = false:**
- Validation failure shows warning but allows progression
- Field marked with warning indicator (⚠️)
- User can proceed but is informed of the issue
- Use for: Recommendations, best practices, soft constraints

**UI Feedback:**
- ✅ **Success:** Green checkmark, success message (if provided)
- ❌ **Blocking Error:** Red X, error message, field highlighted, "Next" disabled
- ⚠️ **Warning:** Yellow triangle, warning message, field marked, "Next" enabled
- ⏳ **Pending:** Gray icon, "Validation pending until [dependency] is filled"

---

## Part B: Technical Specifications - Backend (knk-web-api-v2)

### B.1 Data Model: FieldValidationRule Entity

**File:** `Repository/knk-web-api-v2/Models/FieldValidationRule.cs`

```csharp
using System;

namespace knkwebapi_v2.Models
{
    /// <summary>
    /// Represents a validation rule attached to a FormField that depends on another field's value.
    /// Enables cross-field validation scenarios like spatial containment and conditional requirements.
    /// </summary>
    public class FieldValidationRule
    {
        public int Id { get; set; }
        
        /// <summary>
        /// Foreign key to the FormField this rule validates.
        /// </summary>
        public int FormFieldId { get; set; }
        public FormField FormField { get; set; } = null!;
        
        /// <summary>
        /// Type of validation to perform.
        /// v1 Supported: "LocationInsideRegion", "RegionContainment", "ConditionalRequired"
        /// Extensible for future types without schema changes.
        /// </summary>
        public string ValidationType { get; set; } = string.Empty;
        
        /// <summary>
        /// Foreign key to the FormField this rule depends on for data retrieval.
        /// NULL if validation does not depend on another field.
        /// 
        /// EXAMPLE: LocationId field depends on TownId field
        /// - At validation time, fetch TownId value from form context
        /// - Use TownId to fetch Town entity with WgRegionId
        /// - Validate Location coordinates against Town's region
        /// </summary>
        public int? DependsOnFieldId { get; set; }
        public FormField? DependsOnField { get; set; }
        
        /// <summary>
        /// JSON configuration specific to the validation type.
        /// Structure varies by ValidationType (see ConfigJson schemas in spec).
        /// 
        /// EXAMPLES:
        /// LocationInsideRegion: { "regionPropertyPath": "WgRegionId", "allowBoundary": false }
        /// RegionContainment: { "parentRegionPath": "WgRegionId", "requireFullContainment": true }
        /// ConditionalRequired: { "condition": { "operator": "equals", "value": true } }
        /// </summary>
        public string ConfigJson { get; set; } = "{}";
        
        /// <summary>
        /// Error message displayed when validation fails.
        /// Supports placeholders: {townName}, {regionName}, {coordinates}, {fieldLabel}
        /// Backend returns placeholder values in ValidationResultDto.Placeholders
        /// </summary>
        public string ErrorMessage { get; set; } = string.Empty;
        
        /// <summary>
        /// Optional success message displayed when validation passes.
        /// NULL = just clear error state without showing success message.
        /// </summary>
        public string? SuccessMessage { get; set; }
        
        /// <summary>
        /// If true, validation failure blocks field completion and step progression.
        /// If false, validation is informational/warning only.
        /// Default: true (enforce data integrity)
        /// </summary>
        public bool IsBlocking { get; set; } = true;
        
        /// <summary>
        /// If false (default), validation is skipped if dependency field is not filled.
        /// If true, validation failure is shown even when dependency is empty.
        /// Default: false (better UX - don't show errors before dependencies are ready)
        /// </summary>
        public bool RequiresDependencyFilled { get; set; } = false;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
```

### B.2 Data Model Updates: FormField Entity

**File:** `Repository/knk-web-api-v2/Models/FormField.cs`

**New Property to Add:**
```csharp
/// <summary>
/// Validation rules that depend on other fields for cross-field validation.
/// Executed when field value changes or when dependency field changes.
/// </summary>
public List<FieldValidationRule> ValidationRules { get; set; } = new();
```

**Note:** The `FieldValidation` property (existing) handles simple field-level validations (required, min/max length, regex). The new `ValidationRules` property handles complex inter-field validations.

### B.3 DTOs - FieldValidationRule

**File:** `Repository/knk-web-api-v2/Dtos/FieldValidationRuleDtos.cs`

```csharp
namespace knkwebapi_v2.Dtos
{
    public class FieldValidationRuleDto
    {
        public int Id { get; set; }
        public int FormFieldId { get; set; }
        public string ValidationType { get; set; } = string.Empty;
        public int? DependsOnFieldId { get; set; }
        public string ConfigJson { get; set; } = "{}";
        public string ErrorMessage { get; set; } = string.Empty;
        public string? SuccessMessage { get; set; }
        public bool IsBlocking { get; set; } = true;
        public bool RequiresDependencyFilled { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        
        // Navigation DTOs for display
        public FormFieldNavDto? FormField { get; set; }
        public FormFieldNavDto? DependsOnField { get; set; }
    }
    
    public class CreateFieldValidationRuleDto
    {
        public int FormFieldId { get; set; }
        public string ValidationType { get; set; } = string.Empty;
        public int? DependsOnFieldId { get; set; }
        public string ConfigJson { get; set; } = "{}";
        public string ErrorMessage { get; set; } = string.Empty;
        public string? SuccessMessage { get; set; }
        public bool IsBlocking { get; set; } = true;
        public bool RequiresDependencyFilled { get; set; } = false;
    }
    
    public class UpdateFieldValidationRuleDto
    {
        public string ValidationType { get; set; } = string.Empty;
        public int? DependsOnFieldId { get; set; }
        public string ConfigJson { get; set; } = "{}";
        public string ErrorMessage { get; set; } = string.Empty;
        public string? SuccessMessage { get; set; }
        public bool IsBlocking { get; set; } = true;
        public bool RequiresDependencyFilled { get; set; } = false;
    }
    
    public class ValidateFieldRequestDto
    {
        public int FieldId { get; set; }
        public object? FieldValue { get; set; }
        public Dictionary<string, object?> FormContextData { get; set; } = new();
    }
    
    public class ValidationResultDto
    {
        public bool IsValid { get; set; }
        public string? Message { get; set; }
        public Dictionary<string, string>? Placeholders { get; set; }
        public bool IsBlocking { get; set; }
        public ValidationMetadataDto? Metadata { get; set; }
    }
    
    public class ValidationMetadataDto
    {
        public string ValidationType { get; set; } = string.Empty;
        public DateTime ExecutedAt { get; set; }
        public string? DependencyFieldName { get; set; }
        public object? DependencyFieldValue { get; set; }
    }
    
    public class ValidationIssueDto
    {
        public string Severity { get; set; } = "Warning"; // "Error", "Warning", "Info"
        public string Message { get; set; } = string.Empty;
        public int? FieldId { get; set; }
        public int? RuleId { get; set; }
        public string? FieldLabel { get; set; }
    }
}
```

### B.4 Repository Interface: IFieldValidationRuleRepository

**File:** `Repository/knk-web-api-v2/Repositories/Interfaces/IFieldValidationRuleRepository.cs`

```csharp
using knkwebapi_v2.Models;

namespace knkwebapi_v2.Repositories.Interfaces
{
    public interface IFieldValidationRuleRepository
    {
        Task<FieldValidationRule?> GetByIdAsync(int id);
        Task<IEnumerable<FieldValidationRule>> GetByFormFieldIdAsync(int formFieldId);
        Task<IEnumerable<FieldValidationRule>> GetByFormConfigurationIdAsync(int formConfigurationId);
        Task<FieldValidationRule> CreateAsync(FieldValidationRule rule);
        Task UpdateAsync(FieldValidationRule rule);
        Task DeleteAsync(int id);
        
        // Dependency analysis
        Task<IEnumerable<FieldValidationRule>> GetRulesDependingOnFieldAsync(int fieldId);
        Task<bool> HasCircularDependencyAsync(int fieldId, int dependsOnFieldId);
    }
}
```

### B.5 Service Interface: IValidationService

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationService.cs`

```csharp
using knkwebapi_v2.Dtos;

namespace knkwebapi_v2.Services.Interfaces
{
    public interface IValidationService
    {
        // Rule CRUD
        Task<FieldValidationRuleDto> GetByIdAsync(int id);
        Task<IEnumerable<FieldValidationRuleDto>> GetByFormFieldIdAsync(int formFieldId);
        Task<IEnumerable<FieldValidationRuleDto>> GetByFormConfigurationIdAsync(int formConfigurationId);
        Task<FieldValidationRuleDto> CreateAsync(CreateFieldValidationRuleDto dto);
        Task UpdateAsync(int id, UpdateFieldValidationRuleDto dto);
        Task DeleteAsync(int id);
        
        // Validation execution
        Task<ValidationResultDto> ValidateFieldAsync(ValidateFieldRequestDto request);
        Task<IEnumerable<ValidationResultDto>> ValidateAllFieldRulesAsync(
            int fieldId, 
            object? fieldValue, 
            Dictionary<string, object?> formContextData
        );
        
        // Configuration health checks
        Task<IEnumerable<ValidationIssueDto>> ValidateConfigurationHealthAsync(int formConfigurationId);
    }
}
```

### B.6 Validation Method Interface: IValidationMethod

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IValidationMethod.cs`

```csharp
using knkwebapi_v2.Models;
using knkwebapi_v2.Dtos;

namespace knkwebapi_v2.Services.Interfaces
{
    /// <summary>
    /// Interface for validation method implementations.
    /// Each validation type (LocationInsideRegion, RegionContainment, etc.) 
    /// implements this interface.
    /// </summary>
    public interface IValidationMethod
    {
        /// <summary>
        /// The validation type this method handles.
        /// Must match FieldValidationRule.ValidationType values.
        /// </summary>
        string ValidationType { get; }
        
        /// <summary>
        /// Execute the validation logic.
        /// </summary>
        /// <param name="rule">The validation rule configuration</param>
        /// <param name="fieldValue">The value to validate</param>
        /// <param name="formContextData">All form field values for dependency resolution</param>
        /// <returns>Validation result with success/failure and messages</returns>
        Task<ValidationResultDto> ValidateAsync(
            FieldValidationRule rule, 
            object? fieldValue, 
            Dictionary<string, object?> formContextData
        );
    }
}
```

### B.7 Controller: FieldValidationRulesController

**File:** `Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using knkwebapi_v2.Services.Interfaces;
using knkwebapi_v2.Dtos;

namespace KnKWebAPI.Controllers
{
    [ApiController]
    [Route("api/field-validation-rules")]
    public class FieldValidationRulesController : ControllerBase
    {
        private readonly IValidationService _service;

        public FieldValidationRulesController(IValidationService service)
        {
            _service = service;
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var rule = await _service.GetByIdAsync(id);
            if (rule == null) return NotFound();
            return Ok(rule);
        }

        [HttpGet("by-field/{fieldId:int}")]
        public async Task<IActionResult> GetByFormField(int fieldId)
        {
            var rules = await _service.GetByFormFieldIdAsync(fieldId);
            return Ok(rules);
        }

        [HttpGet("by-configuration/{configId:int}")]
        public async Task<IActionResult> GetByConfiguration(int configId)
        {
            var rules = await _service.GetByFormConfigurationIdAsync(configId);
            return Ok(rules);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateFieldValidationRuleDto dto)
        {
            if (dto == null) return BadRequest();
            try
            {
                var created = await _service.CreateAsync(dto);
                return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateFieldValidationRuleDto dto)
        {
            if (dto == null) return BadRequest();
            try
            {
                await _service.UpdateAsync(id, dto);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                await _service.DeleteAsync(id);
                return NoContent();
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpPost("validate")]
        public async Task<IActionResult> ValidateField([FromBody] ValidateFieldRequestDto request)
        {
            if (request == null) return BadRequest();
            try
            {
                var result = await _service.ValidateFieldAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Validation execution failed", error = ex.Message });
            }
        }

        [HttpGet("health-check/configuration/{configId:int}")]
        public async Task<IActionResult> ValidateConfigurationHealth(int configId)
        {
            try
            {
                var issues = await _service.ValidateConfigurationHealthAsync(configId);
                return Ok(issues);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }
    }
}
```

### B.8 AutoMapper Profile

**File:** `Repository/knk-web-api-v2/Mapping/FieldValidationRuleProfile.cs`

```csharp
using AutoMapper;
using knkwebapi_v2.Models;
using knkwebapi_v2.Dtos;

namespace knkwebapi_v2.Mapping
{
    public class FieldValidationRuleProfile : Profile
    {
        public FieldValidationRuleProfile()
        {
            CreateMap<FieldValidationRule, FieldValidationRuleDto>()
                .ForMember(dest => dest.FormField, opt => opt.MapFrom(src => src.FormField))
                .ForMember(dest => dest.DependsOnField, opt => opt.MapFrom(src => src.DependsOnField));
            
            CreateMap<CreateFieldValidationRuleDto, FieldValidationRule>();
            CreateMap<UpdateFieldValidationRuleDto, FieldValidationRule>();
        }
    }
}
```

### B.9 Database Migration

**File:** `Repository/knk-web-api-v2/Migrations/[timestamp]_AddFieldValidationRule.cs`

```sql
-- FieldValidationRule table
CREATE TABLE FieldValidationRules (
    Id INT PRIMARY KEY IDENTITY(1,1),
    FormFieldId INT NOT NULL,
    ValidationType NVARCHAR(100) NOT NULL,
    DependsOnFieldId INT NULL,
    ConfigJson NVARCHAR(MAX) NOT NULL DEFAULT '{}',
    ErrorMessage NVARCHAR(500) NOT NULL,
    SuccessMessage NVARCHAR(500) NULL,
    IsBlocking BIT NOT NULL DEFAULT 1,
    RequiresDependencyFilled BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    CONSTRAINT FK_FieldValidationRule_FormField 
        FOREIGN KEY (FormFieldId) REFERENCES FormFields(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FieldValidationRule_DependsOnField 
        FOREIGN KEY (DependsOnFieldId) REFERENCES FormFields(Id) ON DELETE NO ACTION
);

CREATE INDEX IX_FieldValidationRule_FormFieldId ON FieldValidationRules(FormFieldId);
CREATE INDEX IX_FieldValidationRule_DependsOnFieldId ON FieldValidationRules(DependsOnFieldId);
```

**Important:** Use `ON DELETE NO ACTION` for `DependsOnFieldId` to prevent cascading deletes that could break dependency chains.

---

## Part C: Technical Specifications - Frontend (knk-web-app)

### C.1 DTOs/Types

**File:** `Repository/knk-web-app/src/types/fieldValidationRuleDtos.ts`

```typescript
export interface FieldValidationRuleDto {
    id: number;
    formFieldId: number;
    validationType: string;
    dependsOnFieldId?: number;
    configJson: string;
    errorMessage: string;
    successMessage?: string;
    isBlocking: boolean;
    requiresDependencyFilled: boolean;
    createdAt: string;
    formField?: FormFieldNavDto;
    dependsOnField?: FormFieldNavDto;
}

export interface CreateFieldValidationRuleDto {
    formFieldId: number;
    validationType: string;
    dependsOnFieldId?: number;
    configJson: string;
    errorMessage: string;
    successMessage?: string;
    isBlocking: boolean;
    requiresDependencyFilled: boolean;
}

export interface UpdateFieldValidationRuleDto {
    validationType: string;
    dependsOnFieldId?: number;
    configJson: string;
    errorMessage: string;
    successMessage?: string;
    isBlocking: boolean;
    requiresDependencyFilled: boolean;
}

export interface ValidateFieldRequestDto {
    fieldId: number;
    fieldValue: any;
    formContextData: { [fieldName: string]: any };
}

export interface ValidationResultDto {
    isValid: boolean;
    message?: string;
    placeholders?: { [key: string]: string };
    isBlocking: boolean;
    metadata?: ValidationMetadataDto;
}

export interface ValidationMetadataDto {
    validationType: string;
    executedAt: string;
    dependencyFieldName?: string;
    dependencyFieldValue?: any;
}

export interface ValidationIssueDto {
    severity: 'Error' | 'Warning' | 'Info';
    message: string;
    fieldId?: number;
    ruleId?: number;
    fieldLabel?: string;
}
```

### C.2 API Client

**File:** `Repository/knk-web-app/src/api/fieldValidationRuleClient.ts`

```typescript
import axios from 'axios';
import {
    FieldValidationRuleDto,
    CreateFieldValidationRuleDto,
    UpdateFieldValidationRuleDto,
    ValidateFieldRequestDto,
    ValidationResultDto,
    ValidationIssueDto
} from '../types/fieldValidationRuleDtos';

const BASE_URL = '/api/field-validation-rules';

export const fieldValidationRuleClient = {
    getById: async (id: number): Promise<FieldValidationRuleDto> => {
        const response = await axios.get(`${BASE_URL}/${id}`);
        return response.data;
    },

    getByFormField: async (fieldId: number): Promise<FieldValidationRuleDto[]> => {
        const response = await axios.get(`${BASE_URL}/by-field/${fieldId}`);
        return response.data;
    },

    getByConfiguration: async (configId: number): Promise<FieldValidationRuleDto[]> => {
        const response = await axios.get(`${BASE_URL}/by-configuration/${configId}`);
        return response.data;
    },

    create: async (dto: CreateFieldValidationRuleDto): Promise<FieldValidationRuleDto> => {
        const response = await axios.post(BASE_URL, dto);
        return response.data;
    },

    update: async (id: number, dto: UpdateFieldValidationRuleDto): Promise<void> => {
        await axios.put(`${BASE_URL}/${id}`, dto);
    },

    delete: async (id: number): Promise<void> => {
        await axios.delete(`${BASE_URL}/${id}`);
    },

    validateField: async (request: ValidateFieldRequestDto): Promise<ValidationResultDto> => {
        const response = await axios.post(`${BASE_URL}/validate`, request);
        return response.data;
    },

    validateConfigurationHealth: async (configId: number): Promise<ValidationIssueDto[]> => {
        const response = await axios.get(`${BASE_URL}/health-check/configuration/${configId}`);
        return response.data;
    }
};
```

### C.3 Component: ValidationRuleBuilder

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/ValidationRuleBuilder.tsx`

```typescript
import React, { useState, useEffect } from 'react';
import { FormFieldDto } from '../../types/formConfigDtos';
import { CreateFieldValidationRuleDto } from '../../types/fieldValidationRuleDtos';

interface ValidationRuleBuilderProps {
    field: FormFieldDto;
    availableFields: FormFieldDto[];  // All fields in the form for dependency selection
    onSave: (rule: CreateFieldValidationRuleDto) => void;
    onCancel: () => void;
}

export const ValidationRuleBuilder: React.FC<ValidationRuleBuilderProps> = ({
    field,
    availableFields,
    onSave,
    onCancel
}) => {
    const [validationType, setValidationType] = useState<string>('LocationInsideRegion');
    const [dependsOnFieldId, setDependsOnFieldId] = useState<number | null>(null);
    const [configJson, setConfigJson] = useState<string>('{}');
    const [errorMessage, setErrorMessage] = useState<string>('');
    const [successMessage, setSuccessMessage] = useState<string>('');
    const [isBlocking, setIsBlocking] = useState<boolean>(true);
    const [requiresDependencyFilled, setRequiresDependencyFilled] = useState<boolean>(false);

    // Filter out current field and only show fields that can be dependencies
    const availableDependencyFields = availableFields.filter(f => f.id !== field.id);

    useEffect(() => {
        // Auto-generate ConfigJson based on validation type
        switch (validationType) {
            case 'LocationInsideRegion':
                setConfigJson(JSON.stringify({ regionPropertyPath: 'WgRegionId', allowBoundary: false }, null, 2));
                setErrorMessage('Location is outside {entityName}\'s boundaries. Please select a location within the region.');
                setSuccessMessage('Location is within region boundaries ✓');
                break;
            case 'RegionContainment':
                setConfigJson(JSON.stringify({ parentRegionPath: 'WgRegionId', requireFullContainment: true }, null, 2));
                setErrorMessage('Region extends outside parent boundaries. All boundaries must be within {entityName}.');
                setSuccessMessage('Region is fully contained within parent ✓');
                break;
            case 'ConditionalRequired':
                setConfigJson(JSON.stringify({ condition: { operator: 'equals', value: true } }, null, 2));
                setErrorMessage('This field is required when {dependencyFieldName} is set.');
                setSuccessMessage('');
                break;
        }
    }, [validationType]);

    const handleSave = () => {
        const rule: CreateFieldValidationRuleDto = {
            formFieldId: parseInt(field.id!),
            validationType,
            dependsOnFieldId: dependsOnFieldId || undefined,
            configJson,
            errorMessage,
            successMessage: successMessage || undefined,
            isBlocking,
            requiresDependencyFilled
        };
        onSave(rule);
    };

    return (
        <div className="bg-white border rounded-lg p-6">
            <h3 className="text-lg font-medium mb-4">Add Validation Rule</h3>
            <div className="space-y-4">
                {/* Validation Type */}
                <div>
                    <label className="block text-sm font-medium mb-1">Validation Type *</label>
                    <select
                        value={validationType}
                        onChange={e => setValidationType(e.target.value)}
                        className="w-full border rounded px-3 py-2"
                    >
                        <option value="LocationInsideRegion">Location Inside Region</option>
                        <option value="RegionContainment">Region Containment</option>
                        <option value="ConditionalRequired">Conditional Required</option>
                    </select>
                </div>

                {/* Dependency Field */}
                <div>
                    <label className="block text-sm font-medium mb-1">Depends On Field</label>
                    <select
                        value={dependsOnFieldId || ''}
                        onChange={e => setDependsOnFieldId(Number(e.target.value) || null)}
                        className="w-full border rounded px-3 py-2"
                    >
                        <option value="">-- Select dependency field --</option>
                        {availableDependencyFields.map(f => (
                            <option key={f.id} value={f.id}>
                                {f.label || f.fieldName}
                            </option>
                        ))}
                    </select>
                    <p className="text-xs text-gray-600 mt-1">
                        ⚠️ Ensure the dependency field comes BEFORE this field in the form order
                    </p>
                </div>

                {/* Config JSON */}
                <div>
                    <label className="block text-sm font-medium mb-1">Configuration (JSON)</label>
                    <textarea
                        value={configJson}
                        onChange={e => setConfigJson(e.target.value)}
                        rows={5}
                        className="w-full border rounded px-3 py-2 font-mono text-sm"
                        placeholder='{ "regionPropertyPath": "WgRegionId" }'
                    />
                </div>

                {/* Error Message */}
                <div>
                    <label className="block text-sm font-medium mb-1">Error Message *</label>
                    <textarea
                        value={errorMessage}
                        onChange={e => setErrorMessage(e.target.value)}
                        rows={2}
                        className="w-full border rounded px-3 py-2"
                        placeholder="Use placeholders like {entityName}, {coordinates}, {fieldLabel}"
                    />
                </div>

                {/* Success Message */}
                <div>
                    <label className="block text-sm font-medium mb-1">Success Message (Optional)</label>
                    <input
                        type="text"
                        value={successMessage}
                        onChange={e => setSuccessMessage(e.target.value)}
                        className="w-full border rounded px-3 py-2"
                        placeholder="Optional success message"
                    />
                </div>

                {/* Is Blocking */}
                <div className="flex items-center">
                    <input
                        type="checkbox"
                        id="isBlocking"
                        checked={isBlocking}
                        onChange={e => setIsBlocking(e.target.checked)}
                        className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                    />
                    <label htmlFor="isBlocking" className="ml-2 text-sm text-gray-900">
                        Block step progression on validation failure
                    </label>
                </div>

                {/* Requires Dependency Filled */}
                <div className="flex items-center">
                    <input
                        type="checkbox"
                        id="requiresDependencyFilled"
                        checked={requiresDependencyFilled}
                        onChange={e => setRequiresDependencyFilled(e.target.checked)}
                        className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                    />
                    <label htmlFor="requiresDependencyFilled" className="ml-2 text-sm text-gray-900">
                        Show error even if dependency field is not filled
                    </label>
                </div>
            </div>

            {/* Actions */}
            <div className="mt-6 flex justify-end space-x-3">
                <button onClick={onCancel} className="btn-secondary">
                    Cancel
                </button>
                <button 
                    onClick={handleSave} 
                    disabled={!errorMessage.trim() || !validationType}
                    className="btn-primary"
                >
                    Add Rule
                </button>
            </div>
        </div>
    );
};
```

### C.4 Component Updates: FieldEditor

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/FieldEditor.tsx`

Add a new section to display and manage validation rules:

```typescript
// Add to imports
import { ValidationRuleBuilder } from './ValidationRuleBuilder';
import { fieldValidationRuleClient } from '../../api/fieldValidationRuleClient';
import { FieldValidationRuleDto, CreateFieldValidationRuleDto } from '../../types/fieldValidationRuleDtos';

// Add to component state
const [validationRules, setValidationRules] = useState<FieldValidationRuleDto[]>([]);
const [showRuleBuilder, setShowRuleBuilder] = useState(false);

// Add effect to load validation rules
useEffect(() => {
    if (field.id) {
        loadValidationRules();
    }
}, [field.id]);

const loadValidationRules = async () => {
    if (!field.id) return;
    try {
        const rules = await fieldValidationRuleClient.getByFormField(parseInt(field.id));
        setValidationRules(rules);
    } catch (error) {
        console.error('Failed to load validation rules:', error);
    }
};

const handleAddRule = async (rule: CreateFieldValidationRuleDto) => {
    try {
        await fieldValidationRuleClient.create(rule);
        await loadValidationRules();
        setShowRuleBuilder(false);
    } catch (error) {
        console.error('Failed to create validation rule:', error);
    }
};

const handleDeleteRule = async (ruleId: number) => {
    if (!window.confirm('Delete this validation rule?')) return;
    try {
        await fieldValidationRuleClient.delete(ruleId);
        await loadValidationRules();
    } catch (error) {
        console.error('Failed to delete validation rule:', error);
    }
};

// Add to JSX (after validations section)
<div className="mt-6">
    <div className="flex items-center justify-between mb-3">
        <h4 className="font-medium text-gray-900">Cross-Field Validation Rules</h4>
        <button
            onClick={() => setShowRuleBuilder(true)}
            className="btn-secondary text-sm"
        >
            + Add Rule
        </button>
    </div>

    {validationRules.length === 0 ? (
        <p className="text-sm text-gray-500 italic">No validation rules configured</p>
    ) : (
        <div className="space-y-2">
            {validationRules.map(rule => (
                <div key={rule.id} className="border rounded p-3 bg-gray-50">
                    <div className="flex items-start justify-between">
                        <div className="flex-1">
                            <div className="flex items-center space-x-2">
                                <span className="font-medium text-sm">{rule.validationType}</span>
                                {rule.isBlocking && (
                                    <span className="px-2 py-0.5 bg-red-100 text-red-800 text-xs rounded">Blocking</span>
                                )}
                            </div>
                            {rule.dependsOnField && (
                                <p className="text-xs text-gray-600 mt-1">
                                    Depends on: {rule.dependsOnField.label || rule.dependsOnField.fieldName}
                                </p>
                            )}
                            <p className="text-xs text-gray-700 mt-1">{rule.errorMessage}</p>
                        </div>
                        <button
                            onClick={() => handleDeleteRule(rule.id)}
                            className="text-red-600 hover:text-red-800 text-sm"
                        >
                            Delete
                        </button>
                    </div>
                </div>
            ))}
        </div>
    )}

    {showRuleBuilder && (
        <div className="mt-4">
            <ValidationRuleBuilder
                field={field}
                availableFields={allFieldsInConfiguration}
                onSave={handleAddRule}
                onCancel={() => setShowRuleBuilder(false)}
            />
        </div>
    )}
</div>
```

### C.5 Component Updates: FieldRenderer (Validation Execution)

**File:** `Repository/knk-web-app/src/components/FormWizard/FieldRenderers.tsx`

Add validation execution logic when field value changes:

```typescript
// Add to imports
import { fieldValidationRuleClient } from '../../api/fieldValidationRuleClient';
import { ValidationResultDto } from '../../types/fieldValidationRuleDtos';

// Add to component state (or props from parent)
const [validationResults, setValidationResults] = useState<{ [fieldId: string]: ValidationResultDto }>({});

// Add validation execution function
const executeFieldValidations = async (
    field: FormFieldDto,
    fieldValue: any,
    formContextData: { [fieldName: string]: any }
) => {
    if (!field.id || !field.validationRules || field.validationRules.length === 0) {
        return;
    }

    const results: { [fieldId: string]: ValidationResultDto } = {};

    for (const rule of field.validationRules) {
        try {
            const result = await fieldValidationRuleClient.validateField({
                fieldId: parseInt(field.id),
                fieldValue,
                formContextData
            });

            // Store result for display
            results[field.id] = result;

            // If blocking validation failed, mark field as invalid
            if (!result.isValid && result.isBlocking) {
                // Trigger error state in parent component
                onValidationError?.(field.id, result.message || 'Validation failed');
            }
        } catch (error) {
            console.error(`Validation execution failed for field ${field.id}:`, error);
        }
    }

    setValidationResults(prev => ({ ...prev, ...results }));
};

// Call validation on field change
const handleFieldChange = (fieldName: string, value: any) => {
    // Update form value
    onChange?.(fieldName, value);

    // Execute validations
    const formContext = buildFormContextData(); // Helper to collect all current form values
    executeFieldValidations(field, value, formContext);
};

// Display validation result
const renderValidationFeedback = (field: FormFieldDto) => {
    const result = validationResults[field.id!];
    if (!result) return null;

    if (result.isValid) {
        return result.message ? (
            <div className="mt-1 flex items-center text-green-600 text-sm">
                <svg className="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                {interpolatePlaceholders(result.message, result.placeholders)}
            </div>
        ) : null;
    } else {
        const severity = result.isBlocking ? 'error' : 'warning';
        const color = result.isBlocking ? 'red' : 'yellow';
        
        return (
            <div className={`mt-1 flex items-start text-${color}-600 text-sm`}>
                <svg className="h-4 w-4 mr-1 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>{interpolatePlaceholders(result.message || 'Validation failed', result.placeholders)}</span>
            </div>
        );
    }
};

const interpolatePlaceholders = (message: string, placeholders?: { [key: string]: string }) => {
    if (!placeholders) return message;
    let result = message;
    Object.entries(placeholders).forEach(([key, value]) => {
        result = result.replace(`{${key}}`, value);
    });
    return result;
};
```

### C.6 Component: Configuration Health Display

**File:** `Repository/knk-web-app/src/components/FormConfigBuilder/ConfigurationHealthPanel.tsx`

```typescript
import React, { useEffect, useState } from 'react';
import { fieldValidationRuleClient } from '../../api/fieldValidationRuleClient';
import { ValidationIssueDto } from '../../types/fieldValidationRuleDtos';

interface ConfigurationHealthPanelProps {
    configurationId: number;
}

export const ConfigurationHealthPanel: React.FC<ConfigurationHealthPanelProps> = ({ configurationId }) => {
    const [issues, setIssues] = useState<ValidationIssueDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadHealthCheck();
    }, [configurationId]);

    const loadHealthCheck = async () => {
        try {
            setLoading(true);
            const result = await fieldValidationRuleClient.validateConfigurationHealth(configurationId);
            setIssues(result);
        } catch (error) {
            console.error('Failed to load configuration health:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return <div className="text-sm text-gray-500">Checking configuration health...</div>;
    }

    if (issues.length === 0) {
        return (
            <div className="bg-green-50 border border-green-200 rounded-md p-4 flex items-center">
                <svg className="h-5 w-5 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                <span className="text-sm text-green-800 font-medium">Configuration is healthy ✓</span>
            </div>
        );
    }

    return (
        <div className="border-t pt-4 mt-4">
            <h4 className="font-medium mb-3">Configuration Health Issues</h4>
            <div className="space-y-2">
                {issues.map((issue, idx) => (
                    <div
                        key={idx}
                        className={`border rounded-md p-3 ${
                            issue.severity === 'Error' ? 'bg-red-50 border-red-200' :
                            issue.severity === 'Warning' ? 'bg-yellow-50 border-yellow-200' :
                            'bg-blue-50 border-blue-200'
                        }`}
                    >
                        <div className="flex items-start">
                            <span className={`px-2 py-0.5 rounded text-xs font-medium mr-2 ${
                                issue.severity === 'Error' ? 'bg-red-200 text-red-800' :
                                issue.severity === 'Warning' ? 'bg-yellow-200 text-yellow-800' :
                                'bg-blue-200 text-blue-800'
                            }`}>
                                {issue.severity}
                            </span>
                            <div className="flex-1">
                                <p className="text-sm">{issue.message}</p>
                                {issue.fieldLabel && (
                                    <p className="text-xs text-gray-600 mt-1">Field: {issue.fieldLabel}</p>
                                )}
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};
```

---

## Part D: Implementation Questions & Design Decisions

### D.1 Questions for User Input

1. **WorldGuard Region API Integration:**
   - Do we have an existing service/API for querying WorldGuard region boundaries and checking coordinate containment?
   - If not, should this be implemented in the Minecraft plugin with API endpoints exposed to knk-web-api-v2?
   - What is the preferred integration pattern: REST API, database view, or direct plugin integration?

2. **Validation Method Extensibility:**
   - Should v1 include a UI for admins to register custom validation methods, or keep it hardcoded to the 3 types (LocationInsideRegion, RegionContainment, ConditionalRequired)?
   - Future consideration: Plugin architecture for custom validators?

3. **Circular Dependency Detection:**
   - Should the system prevent Field A → Field B → Field A circular dependencies?
   - Recommendation: YES - block circular dependencies at creation time with clear error message.

4. **Performance Considerations:**
   - For forms with many validation rules, should validation be:
     - **Eager:** Execute on every field change (better UX, more API calls)
     - **Lazy:** Execute only when field loses focus or on "Next" button (fewer API calls, delayed feedback)
   - Recommendation: Eager validation with debouncing (300ms delay after typing stops)

5. **Validation Rule Versioning:**
   - If an admin updates a FieldValidationRule that's used in multiple FormConfigurations, should:
     - All configurations inherit the update automatically?
     - Each configuration get a copy that can be customized independently (copy-on-reuse pattern)?
   - Recommendation: Copy-on-reuse (same pattern as FormStep/FormField templates) for maximum flexibility

### D.2 Design Decisions (Implemented Unless User Objects)

1. **Validation Execution Location:**
   - **Decision:** Validation logic executes in **backend services only**
   - **Rationale:** Security (never trust client), consistency, centralized business logic
   - Frontend calls API endpoint, displays results from backend

2. **Placeholder Interpolation:**
   - **Decision:** Backend returns placeholder values in `ValidationResultDto.Placeholders`
   - **Rationale:** Backend has entity context, frontend just does string replacement
   - Example: Backend fetches Town entity, extracts name, returns `{ "townName": "Kingsport" }`

3. **Validation Rule Ordering:**
   - **Decision:** Rules execute in order they were added (by `CreatedAt`)
   - **Rationale:** Simple, predictable, no additional ordering complexity
   - If multiple rules fail, all failure messages are collected and displayed

4. **Configuration Health Check Timing:**
   - **Decision:** Run on FormConfigBuilder load and after any field/rule changes
   - **Rationale:** Give immediate feedback to admins about broken dependencies
   - Non-blocking warning display (doesn't prevent saving, but warns admin)

5. **Soft Delete Handling:**
   - **Decision:** If dependency field is soft-deleted, treat as "dependency missing" (error severity)
   - **Rationale:** Prevent silent failures, force admin to fix dependency or remove rule

---

## Part E: Success Criteria

### E.1 Functional Requirements (Must Have)

- [ ] Admin can create FieldValidationRule for a FormField
- [ ] Admin can specify dependency on another FormField
- [ ] Admin can configure validation type, error/success messages, blocking behavior
- [ ] System validates field ordering and warns if dependency comes after dependent field
- [ ] Frontend executes validation when field value changes
- [ ] Frontend displays validation results with placeholder interpolation
- [ ] Blocking validation prevents step progression
- [ ] Non-blocking validation shows warning but allows progression
- [ ] Configuration health check identifies missing/broken dependencies
- [ ] LocationInsideRegion validation works for District → Town scenario
- [ ] RegionContainment validation works for child region → parent region scenario

### E.2 Non-Functional Requirements

- [ ] Validation API response time < 500ms for simple validations
- [ ] Frontend debounces validation calls (300ms delay)
- [ ] Validation errors display within 1 second of field change
- [ ] Configuration health check completes within 2 seconds
- [ ] Database queries optimized (proper indexes on FormFieldId, DependsOnFieldId)
- [ ] Error messages are clear, actionable, and user-friendly

### E.3 Testing Scenarios

1. **Happy Path:** Create District with valid Location inside Town region → Success message
2. **Validation Failure:** Create District with Location outside Town region → Error message, blocked
3. **Dependency Missing:** Try to validate Location before Town is selected → "Pending" message
4. **Field Reordering:** Admin puts dependent field before dependency → Warning in health check
5. **Circular Dependency:** Try to create Field A depends on B, Field B depends on A → Blocked with error
6. **Multiple Rules:** Field has 2 rules, one passes, one fails → Both messages displayed
7. **Non-Blocking Warning:** Field has non-blocking rule that fails → Warning shown, can proceed

---

## Part F: Future Enhancements (Post-v1)

1. **Dynamic Validation Methods:**
   - Admin can register custom validation methods via plugin system
   - Custom validators implement IValidationMethod interface
   - UI for configuring custom validator parameters

2. **Complex Dependency Logic:**
   - Support for AND/OR conditions: "Depends on (Field A AND Field B) OR Field C"
   - Nested dependency trees

3. **Async Validation with Caching:**
   - Cache validation results for expensive operations
   - Invalidate cache when dependency field changes

4. **Validation History/Audit:**
   - Track when validations were executed
   - Log validation failures for analytics

5. **Server-Side Validation on Form Submission:**
   - Re-validate all fields on backend before entity creation
   - Prevent data integrity issues if client-side validation was bypassed

6. **Validation Rule Templates:**
   - Reusable validation rules that can be applied to multiple fields
   - "LocationInRegion_StandardTemplate" can be reused across all region-based entities

---

**End of Specification**
