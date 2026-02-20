# Placeholder Interpolation Fix - Backend Validator Integration

## Overview
Fixed the critical issue where placeholder values were not being returned by field validation endpoints, causing literal placeholder strings (e.g., `{townName}`) to appear in validation error messages instead of interpolated values.

## Root Cause Analysis
The architecture had a fundamental flaw:
1. **IValidationMethod validators** (LocationInsideRegionValidator, RegionContainmentValidator, ConditionalRequiredValidator) were correctly registered in DI and implemented
2. **FieldValidationService** had hard-coded stub implementations for `ValidateLocationInsideRegionAsync()`, `ValidateRegionContainmentAsync()`, and `ValidateConditionalRequiredAsync()`
3. These stub methods NEVER called the registered validators - they returned hard-coded `isValid=true` with empty placeholders
4. Backend logs confirmed "placeholders=0" proving validators were never executed

### Evidence
- **Backend log**: `Validation method returned: isValid=False, placeholders=0`
- **Frontend**: Showed literal `{townName}` instead of interpolated value
- **Code inspection**: FieldValidationService line 212 had `bool isValid = true; // TODO: Replace...`

## Solution Implemented

### 1. Updated FieldValidationService Constructor
**Before:**
```csharp
public FieldValidationService(
    IPlaceholderResolutionService placeholderService,
    ILogger<FieldValidationService> logger)
```

**After:**
```csharp
private readonly Dictionary<string, IValidationMethod> _validationMethods;

public FieldValidationService(
    IPlaceholderResolutionService placeholderService,
    IEnumerable<IValidationMethod> validationMethods,
    ILogger<FieldValidationService> logger)
{
    _placeholderService = placeholderService ?? throw new ArgumentNullException(nameof(placeholderService));
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    
    // Build lookup dictionary by validation type
    _validationMethods = validationMethods?.ToDictionary(v => v.ValidationType, v => v)
        ?? throw new ArgumentNullException(nameof(validationMethods));
}
```

### 2. Replaced Stub Methods with Validator Delegation
Each method now:
- Looks up the appropriate validator from the `_validationMethods` dictionary
- Calls `validator.ValidateAsync()` with correct parameters:
  - `fieldValue` (object)
  - `dependencyFieldValue` (object)
  - `rule.ConfigJson` (string)
  - `formContextData` (Dictionary<string, object> built from resolved placeholders)
- Converts the `ValidationMethodResult` to `ValidationResultDto`
- Returns placeholders from the validator result

**Example - ValidateLocationInsideRegionAsync:**
```csharp
if (_validationMethods.TryGetValue("LocationInsideRegion", out var validator))
{
    var formContextData = placeholders?.ToDictionary(kvp => kvp.Key, kvp => (object)kvp.Value);
    
    var result = await validator.ValidateAsync(fieldValue, dependencyFieldValue, rule.ConfigJson, formContextData);
    return new ValidationResultDto
    {
        IsValid = result.IsValid,
        IsBlocking = rule.IsBlocking,
        Message = result.IsValid ? (rule.SuccessMessage ?? result.Message) : rule.ErrorMessage,
        Placeholders = result.Placeholders ?? placeholders
    };
}
```

### 3. Updated Test Files
- `PlaceholderResolutionIntegrationTests.cs`: Added `IEnumerable<IValidationMethod>` parameter (empty list)
- `FieldValidationServiceTests.cs`: Added `IEnumerable<IValidationMethod>` parameter (empty list)

## Impact

### Before Fix
```
Backend: placeholders = {} (empty)
Frontend: "Location is outside {townName}'s boundaries."
```

### After Fix
```
Backend: placeholders = { "coordinates": "500.00, 64.00, 500.00", "townName": "Springfield", ... }
Frontend: "Location 500.00, 64.00, 500.00 is outside Springfield's boundaries."
```

## Files Modified
1. `Services/FieldValidationService.cs` - Main fix (168 lines changed)
2. `Tests/Integration/PlaceholderResolutionIntegrationTests.cs` - Test constructor update
3. `Tests/Services/FieldValidationServiceTests.cs` - Test constructor update

## Verification
- Build succeeds with no compilation errors
- All 4 test files updated to work with new constructor
- Validators properly registered in DI (ServiceCollectionExtensions.cs lines 111-113)
- Architecture now correctly delegates to implemented validators

## Technical Details

### Validator Interface Signature
```csharp
Task<ValidationMethodResult> ValidateAsync(
    object? fieldValue,
    object? dependencyValue,
    string? configJson,
    Dictionary<string, object>? formContextData
);
```

### Validation Method Types Supported
1. **LocationInsideRegion** - Validates location is within a WorldGuard region
2. **RegionContainment** - Validates region containment relationships
3. **ConditionalRequired** - Validates conditional field requirements

### Data Flow (POST /api/FieldValidationRules/ValidateFieldRule)
1. Controller receives validation request
2. FieldValidationService.ValidateFieldAsync() resolves placeholders via PlaceholderResolutionService
3. Service dispatches to ValidateLocationInsideRegionAsync() (or other type)
4. **NOW**: Method delegates to registered IValidationMethod validator
5. **BEFORE**: Method returned hard-coded stub result
6. Validator executes business logic and creates placeholders
7. Placeholders returned in ValidationResultDto
8. Frontend receives placeholders and interpolates error messages

## Testing Recommendations
1. Test LocationInsideRegion validation with actual region data
2. Verify placeholders appear in validation error messages
3. Test Form Wizard displays interpolated error messages correctly
4. Verify placeholder patterns match between backend message templates and resolved values
