# Inter-Field Validation Dependencies - Quick Reference Guide

**Last Updated:** January 18, 2026  
**Status:** Ready for Implementation ✅

---

## Design Decisions Summary

| Decision Area | Confirmed Choice |
|---------------|------------------|
| **Validation Execution** | Backend-only (API endpoint), frontend calls and displays results |
| **Validation Types (v1)** | 3 types: LocationInsideRegion, RegionContainment, ConditionalRequired |
| **Field Dependency** | Admin responsibility to order fields correctly; system warns if wrong order |
| **Blocking Behavior** | IsBlocking=true prevents progression; IsBlocking=false shows warning only |
| **Dependency Not Filled** | Default: skip validation, show "pending" message; configurable via RequiresDependencyFilled |
| **Circular Dependencies** | Blocked at creation time with error message |
| **Message Interpolation** | Backend returns placeholders, frontend replaces (e.g., {townName}, {coordinates}) |
| **Validation Timing** | On field change (debounced 300ms), on dependency change, before step progression |
| **Configuration Health** | Auto-check on FormConfigBuilder load; warns about broken dependencies and wrong field order |

---

## Entity Model: FieldValidationRule

### Properties

```csharp
public class FieldValidationRule
{
    public int Id { get; set; }
    public int FormFieldId { get; set; }                    // Field being validated
    public string ValidationType { get; set; }              // "LocationInsideRegion", "RegionContainment", "ConditionalRequired"
    public int? DependsOnFieldId { get; set; }             // Field this rule depends on
    public string ConfigJson { get; set; } = "{}";         // Validation-specific config
    public string ErrorMessage { get; set; }               // Shown on validation failure
    public string? SuccessMessage { get; set; }            // Shown on validation success (optional)
    public bool IsBlocking { get; set; } = true;           // If true, blocks progression
    public bool RequiresDependencyFilled { get; set; }     // If false, skip validation when dependency empty
    public DateTime CreatedAt { get; set; }
    
    // Navigation
    public FormField FormField { get; set; }
    public FormField? DependsOnField { get; set; }
}
```

---

## Validation Types & ConfigJson Schemas

### LocationInsideRegion
**Purpose:** Validate Location coordinates are inside a WorldGuard region

**ConfigJson:**
```json
{
  "regionPropertyPath": "WgRegionId",
  "allowBoundary": false
}
```

**Example Use Case:**
- Field: `District.LocationId`
- Depends On: `District.TownId`
- Validation: Location must be inside Town's WgRegionId

**Error Message Template:**
```
"Location {coordinates} is outside {townName}'s boundaries. Please select a location within the region."
```

**Placeholders Returned:**
- `{townName}` - Display name of parent entity
- `{coordinates}` - Location coordinates (X, Z)
- `{regionName}` - Region identifier

---

### RegionContainment
**Purpose:** Validate child region is fully contained within parent region

**ConfigJson:**
```json
{
  "parentRegionPath": "WgRegionId",
  "requireFullContainment": true
}
```

**Example Use Case:**
- Field: `District.WgRegionId`
- Depends On: `District.TownId`
- Validation: District region must be inside Town region

**Error Message Template:**
```
"District region extends outside town boundaries at {violationCount} points. All boundaries must be within {townName}."
```

**Placeholders Returned:**
- `{townName}` - Display name of parent entity
- `{violationCount}` - Number of boundary points outside parent
- `{regionName}` - Parent region identifier

---

### ConditionalRequired
**Purpose:** Make field required only when another field meets a condition

**ConfigJson:**
```json
{
  "condition": {
    "operator": "equals",
    "value": true
  }
}
```

**Operators:**
- `"equals"` - Dependency field equals value
- `"notEquals"` - Dependency field does not equal value
- `"greaterThan"` - Dependency field > value (numeric)
- `"lessThan"` - Dependency field < value (numeric)
- `"in"` - Dependency field is in values array

**Example Use Case:**
- Field: `Structure.PublicAccessPoint`
- Depends On: `Structure.IsPublic`
- ConfigJson: `{ "condition": { "operator": "equals", "value": true } }`
- Validation: If IsPublic is true, PublicAccessPoint is required

**Error Message Template:**
```
"Public structures require a public access point location."
```

---

## API Endpoints

### CRUD Operations

```http
GET    /api/field-validation-rules/{id}
GET    /api/field-validation-rules/by-field/{fieldId}
GET    /api/field-validation-rules/by-configuration/{configId}
POST   /api/field-validation-rules
PUT    /api/field-validation-rules/{id}
DELETE /api/field-validation-rules/{id}
```

### Validation Execution

```http
POST   /api/field-validation-rules/validate
```

**Request:**
```json
{
  "fieldId": 123,
  "fieldValue": 456,
  "formContextData": {
    "TownId": 789,
    "WgRegionId": "town-region-001"
  }
}
```

**Response:**
```json
{
  "isValid": false,
  "message": "Location (X: 1234, Z: 5678) is outside Kingsport's boundaries. Please select a location within the region.",
  "placeholders": {
    "townName": "Kingsport",
    "coordinates": "(X: 1234, Z: 5678)",
    "regionName": "town-region-001"
  },
  "isBlocking": true,
  "metadata": {
    "validationType": "LocationInsideRegion",
    "executedAt": "2026-01-18T10:30:00Z",
    "dependencyFieldName": "TownId",
    "dependencyFieldValue": 789
  }
}
```

### Configuration Health Check

```http
GET    /api/field-validation-rules/health-check/configuration/{configId}
```

**Response:**
```json
[
  {
    "severity": "Warning",
    "message": "Field 'Location' depends on 'Town' which comes AFTER it. Reorder fields for proper validation.",
    "fieldId": 123,
    "ruleId": 456,
    "fieldLabel": "Spawn Location"
  }
]
```

**Severity Levels:**
- `"Error"` - Broken dependency (field deleted), must fix
- `"Warning"` - Wrong field order, should reorder
- `"Info"` - Informational message

---

## Frontend Integration

### TypeScript Types

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
}

export interface ValidationResultDto {
    isValid: boolean;
    message?: string;
    placeholders?: { [key: string]: string };
    isBlocking: boolean;
    metadata?: ValidationMetadataDto;
}
```

### API Client Usage

```typescript
import { fieldValidationRuleClient } from '../api/fieldValidationRuleClient';

// Create validation rule
const rule: CreateFieldValidationRuleDto = {
    formFieldId: 123,
    validationType: 'LocationInsideRegion',
    dependsOnFieldId: 456,
    configJson: JSON.stringify({ regionPropertyPath: 'WgRegionId' }),
    errorMessage: 'Location is outside {townName}.',
    successMessage: 'Location is within region boundaries ✓',
    isBlocking: true,
    requiresDependencyFilled: false
};
await fieldValidationRuleClient.create(rule);

// Validate field
const result = await fieldValidationRuleClient.validateField({
    fieldId: 123,
    fieldValue: locationId,
    formContextData: { TownId: townId, WgRegionId: regionId }
});

if (!result.isValid && result.isBlocking) {
    // Show error, prevent progression
    showError(interpolate(result.message, result.placeholders));
}
```

### Validation in FieldRenderer

```typescript
// Execute validation on field change
const handleFieldChange = async (fieldName: string, value: any) => {
    // Update form state
    updateFormData(fieldName, value);
    
    // Build form context (all current field values)
    const formContext = buildFormContextData();
    
    // Execute validations for this field
    if (field.validationRules && field.validationRules.length > 0) {
        for (const rule of field.validationRules) {
            const result = await fieldValidationRuleClient.validateField({
                fieldId: field.id,
                fieldValue: value,
                formContextData: formContext
            });
            
            // Display result
            setValidationResult(field.id, result);
            
            // Block progression if needed
            if (!result.isValid && result.isBlocking) {
                setFieldInvalid(field.id, true);
            }
        }
    }
};
```

---

## Admin Workflow: Creating Validation Rules

### Step 1: Create Form Configuration
1. Navigate to Admin → Form Configurations
2. Click "Create New Configuration"
3. Select entity type (e.g., "District")
4. Add form steps

### Step 2: Add Fields in Correct Order
1. Add dependency field FIRST (e.g., "Town" field)
2. Add dependent field SECOND (e.g., "Location" field)
3. **Important:** Dependency must come before dependent field

### Step 3: Add Validation Rule
1. Select dependent field (e.g., "Location")
2. Scroll to "Cross-Field Validation Rules" section
3. Click "+ Add Rule"
4. Configure rule:
   - **Validation Type:** Select from dropdown (LocationInsideRegion, RegionContainment, ConditionalRequired)
   - **Depends On Field:** Select dependency field (e.g., "Town")
   - **Configuration (JSON):** Auto-populated, customize if needed
   - **Error Message:** Enter message with placeholders (e.g., `{townName}`, `{coordinates}`)
   - **Success Message:** Optional success message
   - **Block Progression:** Check if validation failure should prevent form submission
5. Click "Add Rule"

### Step 4: Verify Configuration Health
1. Scroll to "Configuration Health" panel at bottom
2. Check for warnings/errors:
   - ✅ Green: Configuration is healthy
   - ⚠️ Yellow: Warnings (e.g., field order issues)
   - ❌ Red: Errors (e.g., broken dependencies)
3. Fix any issues before saving

### Step 5: Save Configuration
1. Click "Save Configuration"
2. Configuration is now ready for use

---

## Form Filler Workflow: Using Forms with Validation

### Scenario: Creating a District

1. **Fill Town Field:**
   - User selects Town from dropdown
   - Form stores Town entity data (id, name, WgRegionId)

2. **Fill Location Field:**
   - User enters location coordinates OR selects from map
   - **Validation executes immediately** (300ms debounce)
   - System calls API: `/api/field-validation-rules/validate`
   - API checks if Location is inside Town's WgRegionId
   - Result displayed:
     - ✅ Success: "Location is within town boundaries ✓" (green checkmark)
     - ❌ Error: "Location (X: 1234, Z: 5678) is outside Kingsport's boundaries." (red X, field highlighted)

3. **If Validation Fails (Blocking):**
   - "Next" button is disabled
   - User must select a different location
   - Validation re-executes on each change until valid

4. **If Validation Passes:**
   - "Next" button is enabled
   - User can proceed to next step

5. **If Dependency Not Filled:**
   - User fills Location before Town
   - System shows: ⏳ "Validation pending until Town is selected"
   - No blocking, no error
   - Once Town is selected, validation executes automatically

---

## Troubleshooting

### Issue: Validation never executes
**Check:**
- Is dependency field filled in form context?
- Is field's `validationRules` property populated?
- Check browser console for API errors

### Issue: Wrong dependency field order warning
**Fix:**
- Reorder fields in FormConfigBuilder
- Dependency field must come BEFORE dependent field
- Use drag-and-drop or order numbers

### Issue: Validation passes but should fail
**Check:**
- ConfigJson is correct for validation type
- Dependency field value is correct in form context
- Backend validation logic is implemented correctly
- Check API response in browser dev tools

### Issue: Circular dependency error
**Fix:**
- Field A depends on Field B
- Field B depends on Field A
- Remove one of the dependencies
- Redesign validation logic

### Issue: Placeholders not replaced in message
**Check:**
- Backend returns `placeholders` object in ValidationResultDto
- Frontend calls `interpolatePlaceholders()` function
- Placeholder names match exactly (case-sensitive)

---

## Database Schema

```sql
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

**Important:** `DependsOnFieldId` has `ON DELETE NO ACTION` to prevent cascading deletes that could break dependency chains.

---

## Example: District Form Configuration

### Fields (in order)
1. **Name** (string) - District name
2. **Description** (string) - District description
3. **Town** (relationship) - Parent town
4. **WgRegionId** (string) - WorldGuard region for district
5. **Location** (relationship) - Spawn point

### Validation Rules

**Rule 1: WgRegionId must be inside Town's region**
```json
{
  "formFieldId": 4,
  "validationType": "RegionContainment",
  "dependsOnFieldId": 3,
  "configJson": "{\"parentRegionPath\":\"WgRegionId\",\"requireFullContainment\":true}",
  "errorMessage": "District region extends outside {townName}'s boundaries.",
  "successMessage": "District region is fully contained within {townName} ✓",
  "isBlocking": true
}
```

**Rule 2: Location must be inside Town's region**
```json
{
  "formFieldId": 5,
  "validationType": "LocationInsideRegion",
  "dependsOnFieldId": 3,
  "configJson": "{\"regionPropertyPath\":\"WgRegionId\"}",
  "errorMessage": "Location {coordinates} is outside {townName}'s boundaries.",
  "successMessage": "Location is within town boundaries ✓",
  "isBlocking": true
}
```

---

## Performance Considerations

### Frontend
- **Debouncing:** 300ms delay after typing stops before validation executes
- **Caching:** Store validation results to avoid redundant API calls
- **Batching:** If multiple rules on same field, batch API calls

### Backend
- **Eager Loading:** Use EF Core `.Include()` to load dependencies in one query
- **Caching:** Cache region boundary data (invalidate on region updates)
- **Indexing:** Ensure indexes on FormFieldId, DependsOnFieldId

### Expected Performance
- Validation API response: < 500ms
- Frontend validation execution: < 1 second (including debounce)
- Configuration health check: < 2 seconds

---

## Testing Checklist

### Backend
- [ ] Create FieldValidationRule → Success
- [ ] Create circular dependency → Blocked with error
- [ ] Validate field with passing rule → ValidationResultDto.IsValid = true
- [ ] Validate field with failing rule → ValidationResultDto.IsValid = false
- [ ] Validate field with missing dependency → "Pending" message
- [ ] Configuration health check with valid config → No issues
- [ ] Configuration health check with wrong field order → Warning
- [ ] LocationInsideRegion validator → Correctly validates coordinates
- [ ] RegionContainment validator → Correctly validates region boundaries
- [ ] ConditionalRequired validator → Correctly evaluates conditions

### Frontend
- [ ] ValidationRuleBuilder creates rule → API call succeeds
- [ ] FieldEditor displays validation rules → Rules load correctly
- [ ] FieldRenderer executes validation on change → API called, result displayed
- [ ] Blocking validation prevents step progression → "Next" button disabled
- [ ] Non-blocking validation shows warning → Yellow triangle displayed
- [ ] ConfigurationHealthPanel displays issues → Errors/warnings shown correctly
- [ ] Placeholder interpolation → Messages display correctly

### Integration
- [ ] End-to-end: Create District with valid Location → Success
- [ ] End-to-end: Create District with invalid Location → Blocked
- [ ] Dependency field changes → Re-validate dependent fields
- [ ] Field reordering → Health check updates

---

## Common Patterns

### Pattern 1: Spatial Containment (Location in Region)
```json
{
  "validationType": "LocationInsideRegion",
  "dependsOnFieldId": <parent-entity-field-id>,
  "configJson": "{\"regionPropertyPath\":\"WgRegionId\"}",
  "errorMessage": "Location is outside {entityName}'s boundaries.",
  "isBlocking": true
}
```

### Pattern 2: Hierarchical Regions (Child region in parent)
```json
{
  "validationType": "RegionContainment",
  "dependsOnFieldId": <parent-entity-field-id>,
  "configJson": "{\"parentRegionPath\":\"WgRegionId\",\"requireFullContainment\":true}",
  "errorMessage": "Region extends outside {entityName}'s boundaries.",
  "isBlocking": true
}
```

### Pattern 3: Conditional Requirement
```json
{
  "validationType": "ConditionalRequired",
  "dependsOnFieldId": <boolean-field-id>,
  "configJson": "{\"condition\":{\"operator\":\"equals\",\"value\":true}}",
  "errorMessage": "This field is required when {dependencyFieldName} is enabled.",
  "isBlocking": true
}
```

---

## Future Enhancements (Post-v1)

1. **Custom Validation Methods:** Plugin architecture for admin-registered validators
2. **Complex Dependency Logic:** AND/OR conditions, nested dependencies
3. **Async Validation with Caching:** Cache expensive validation results
4. **Validation History:** Track when validations were executed, log failures
5. **Server-Side Re-Validation:** Re-validate all fields on backend before entity creation
6. **Validation Rule Templates:** Reusable validation rules across configurations

---

**End of Quick Reference Guide**
