# Validation Feedback and Metadata Improvements

## Overview
This document outlines the improvements made to the form configuration validation system to provide better feedback and handle default values correctly.

## Problems Solved

### 1. **Vague Error Messages**
**Before:** "FormConfiguration has 2 incompatible field(s) for entity 'Town'."
- User had no way to know which fields were incompatible or why
- Debugging required manual inspection of the payload and metadata

**After:** "FormConfiguration has 2 incompatible field(s) for entity 'Town': 'AllowEntry' (Field 'AllowEntry' is non-nullable on entity (no default value) but marked as not required in form. Either make it required or add a default value to the model.); 'AllowExit' (Field 'AllowExit' is non-nullable on entity (no default value) but marked as not required in form. Either make it required or add a default value to the model.)"
- Exact field names are listed
- Specific reasons for incompatibility are explained
- Clear guidance on how to fix the issue

### 2. **Missing Parent Class Fields**
**Before:** Metadata only included fields from the specific entity class (e.g., Town's own fields)
- Inherited fields from parent classes (e.g., Domain) were not included
- Validation rejected valid fields that belonged to parent classes

**After:** `MetadataService.GetFieldMetadata()` now uses `BindingFlags.FlattenHierarchy`
- All fields from the inheritance chain are included
- Town's metadata includes both Town-specific fields (Streets, Districts) AND Domain fields (Name, Description, Location, AllowEntry, AllowExit, WgRegionId, CreatedAt)

### 3. **Incorrect Nullability Validation**
**Before:** Non-nullable fields were always required to be marked as required in forms
- This didn't account for fields with default values in the model class
- Example: `public bool AllowEntry { get; set; } = true;` was flagged as invalid even when marked optional

**After:** Validation now checks if a field has a default value
- If a field has a default value, it can be optional in the form
- Only flags non-nullable, non-required fields that DON'T have defaults as errors
- Allows flexible form design while maintaining data integrity

## Implementation Details

### Enhanced `EntityMetadataDto`
Added two new properties to `FieldMetadataDto`:

```csharp
/// <summary>
/// Indicates if this field has a default value defined in the model class.
/// If true, the field can be optional in forms even if non-nullable on the entity.
/// </summary>
public bool HasDefaultValue { get; set; }

/// <summary>
/// The default value as a string representation, if one exists.
/// Examples: "True", "False", "null", "DateTime.Now", "0", "true"
/// </summary>
public string? DefaultValue { get; set; }
```

### Default Value Detection
Added `ExtractDefaultValue()` and `DetectDefaultValueFromConstructor()` methods to `MetadataService`:

- Creates an instance of the entity type
- Inspects property values to detect defaults
- Handles value types (int, bool, DateTime, etc.)
- Handles reference types (strings, collections)
- Gracefully handles instantiation failures

Example detection for:
- `public bool AllowEntry { get; set; } = true;` → `HasDefaultValue: true, DefaultValue: "True"`
- `public ICollection<Street> Streets { get; set; } = new Collection<Street>();` → `HasDefaultValue: true, DefaultValue: "new Collection()"`

### Improved Validation Logic
Updated `ValidateField()` in `FormTemplateValidationService`:

```csharp
// Before: Always flagged non-nullable optional fields as errors
if (!metadataField.IsNullable && !field.Required)
{
    result.Issues.Add($"Field '{field.FieldName}' is non-nullable on entity but marked as not required in form.");
}

// After: Checks for default values
if (!metadataField.IsNullable && !field.Required && !metadataField.HasDefaultValue)
{
    result.Issues.Add($"Field '{field.FieldName}' is non-nullable on entity (no default value) but marked as not required in form. Either make it required or add a default value to the model.");
}
else if (!metadataField.IsNullable && !field.Required && metadataField.HasDefaultValue)
{
    // This is valid - field has a default value, so it can be optional in the form
}
```

### Detailed Error Messages
Updated `ValidateConfigurationAsync()` to provide field-specific feedback:

```csharp
// Before
result.Summary = $"FormConfiguration has {incompatibleCount} incompatible field(s) for entity '{config.EntityTypeName}'.";

// After
var incompatibleFields = result.StepResults
    .SelectMany(s => s.FieldResults)
    .Where(f => !f.IsCompatible)
    .ToList();

var details = string.Join("; ", incompatibleFields.Select(f => 
    $"'{f.FieldName}' ({string.Join(", ", f.Issues)})"));

result.Summary = $"FormConfiguration has {incompatibleFields.Count} incompatible field(s) for entity '{config.EntityTypeName}': {details}";
```

## Benefits

1. **Clear Debugging:** Developers immediately see which fields are problematic and why
2. **Inheritance Support:** Forms work correctly with inherited entity hierarchies
3. **Flexible Form Design:** Fields with defaults can be optional, improving UX
4. **Better Error Guidance:** Messages suggest how to fix validation failures
5. **Comprehensive Metadata:** API consumers can inspect default values via the metadata endpoint

## Example: Town Entity

The `Town` class inherits from `Domain`:
- Domain has: Id, Name, Description, CreatedAt, AllowEntry, AllowExit, WgRegionId, Location
- Town adds: Streets, Districts

**Before improvement:**
- Metadata only included Streets and Districts
- Validation rejected forms that included "Name", "Description", etc.
- Error message didn't explain which fields were problematic

**After improvement:**
- Metadata includes all 10 fields (8 from Domain + 2 from Town)
- Field-level details show that AllowEntry and AllowExit have `HasDefaultValue: true` (because they default to `true` in the model)
- Forms can mark AllowEntry and AllowExit as optional since they have defaults
- Error message lists exact field names and provides actionable guidance

## Testing

To test the improved validation:

1. Create a form configuration for "Town" with the following field setup:
   - Name: required (valid)
   - Description: optional (valid, inherited from Domain)
   - AllowEntry: optional (valid, has default value `= true` in model)
   - AllowExit: optional (valid, has default value `= true` in model)
   - Streets: optional (valid)
   - Districts: optional (valid)

2. Try creating one with invalid field names (e.g., "InvalidField")
   - You'll get a detailed error explaining exactly which field doesn't exist

3. Try marking a non-nullable field without defaults as optional
   - You'll get a helpful error message suggesting to either make it required or add a default to the model
