# Display Configuration: Related Entity Support

## Overview
Display configurations now support displaying fields from related entities (navigation properties) without requiring separate sections. This allows you to show related entity data inline with the main entity.

## Feature Description

### Problem Solved
Previously, to display fields from a related entity (e.g., showing `ParentCategory.Name` on a Category), you needed to create a separate section with `relatedEntityPropertyName`. Now you can dedicate individual **fields** to related entities, making it easier to mix main entity fields and related entity fields in the same section.

### Example Use Cases

#### Category Entity
```csharp
public class Category
{
    public int Id { get; set; }
    public string Name { get; set; }
    
    // Related entities
    public int? IconMaterialRefId { get; set; }
    public MinecraftMaterialRef? IconMaterialRef { get; set; }
    
    public int? ParentCategoryId { get; set; }
    public Category? ParentCategory { get; set; }
}
```

You can now create display fields that show:
- `Name` from the main Category
- `IconMaterialRef.NamespaceKey` from the related MinecraftMaterialRef
- `ParentCategory.Name` from the related parent Category

All in the same section!

## How It Works

### Backend Changes

#### 1. DisplayField Model
Added two new properties to `Models/DisplayField.cs`:
```csharp
/// <summary>
/// The navigation property name this field is dedicated to (e.g., "ParentCategory", "IconMaterialRef").
/// When set, FieldName refers to a property on the related entity, not the main entity.
/// </summary>
public string? RelatedEntityPropertyName { get; set; }

/// <summary>
/// The type name of the related entity (e.g., "Category", "MinecraftMaterialRef").
/// Used for metadata lookup. Set automatically when RelatedEntityPropertyName is provided.
/// </summary>
public string? RelatedEntityTypeName { get; set; }
```

#### 2. Database Migration
Created migration `DisplayFieldRelatedEntitySupport` which adds:
- `RelatedEntityPropertyName` column (varchar 200, nullable)
- `RelatedEntityTypeName` column (varchar 200, nullable)

#### 3. DTO Updates
Updated `Dtos/DisplayDtos.cs` to include the new properties:
```csharp
[JsonPropertyName("relatedEntityPropertyName")]
public string? RelatedEntityPropertyName { get; set; }

[JsonPropertyName("relatedEntityTypeName")]
public string? RelatedEntityTypeName { get; set; }
```

### Frontend Changes

#### 1. TypeScript Interface
Updated `DisplayModels.ts`:
```typescript
export interface DisplayFieldDto {
  // ... existing properties
  relatedEntityPropertyName?: string; // e.g., "ParentCategory", "IconMaterialRef"
  relatedEntityTypeName?: string; // e.g., "Category", "MinecraftMaterialRef"
  fieldName?: string;
  // ... other properties
}
```

#### 2. FieldEditor Component
Enhanced `DisplayConfigBuilder/FieldEditor.tsx` with:

**New "Dedicated to Related Entity" dropdown:**
- Shows all navigation properties from the main entity
- Displays as: "PropertyName (EntityType)" (e.g., "ParentCategory (Category)")
- When selected:
  - Fetches metadata for the related entity
  - Updates Field Name dropdown to show related entity fields
  - Auto-populates relatedEntityTypeName

**Grouped Field Configuration Section:**
- Field Name and Field Type are now visually grouped
- Shows indicator when dedicated to related entity
- Dynamic loading of related entity metadata

**Example UI Flow:**
1. User selects "ParentCategory (Category)" from "Dedicated to Related Entity"
2. Component fetches Category metadata
3. Field Name dropdown populates with Category fields (Id, Name, IconMaterialRefId, etc.)
4. User selects "Name" field
5. Field Type auto-populates based on metadata

#### 3. DisplayField Component
Updated `DisplayWizard/DisplayField.tsx` to:
- Navigate to related entity data first if `relatedEntityPropertyName` is set
- Access field from the related entity's data
- Show visual indicator in label: "(from Category)" or "(from MinecraftMaterialRef)"

**Data Navigation:**
```typescript
// If field is dedicated to a related entity, navigate to that entity first
if (field.relatedEntityPropertyName && data) {
  sourceData = getNestedValue(data, field.relatedEntityPropertyName);
}

// Then access the field from the related entity
displayValue = getNestedValue(sourceData, field.fieldName);
```

## Usage Guide

### Creating a Field for a Related Entity

1. **Open DisplayConfigBuilder** for an entity (e.g., Category)

2. **Add or edit a field** in a section

3. **Select Related Entity:**
   - Click "Dedicated to Related Entity" dropdown
   - Choose from available navigation properties:
     - `ParentCategory (Category)` - to show parent category fields
     - `IconMaterialRef (MinecraftMaterialRef)` - to show icon material fields

4. **Select Field from Related Entity:**
   - The "Field Name" dropdown now shows fields from the selected related entity
   - Choose the field you want to display (e.g., "Name", "NamespaceKey")
   - Field Type auto-populates

5. **Configure Label and Description:**
   - Set a user-friendly label (e.g., "Parent Category Name")
   - Add optional description

6. **Save the field**

### Example Configuration

**Display Category with Related Entities:**

Section: "Category Information"
- Field 1: "Category Name"
  - Related Entity: None (main entity)
  - Field Name: Name
  - Field Type: String

- Field 2: "Parent Category"
  - Related Entity: ParentCategory (Category)
  - Field Name: Name
  - Field Type: String

- Field 3: "Icon Material"
  - Related Entity: IconMaterialRef (MinecraftMaterialRef)
  - Field Name: NamespaceKey
  - Field Type: String

**Result:** All three fields display in the same section, pulling data from different entities.

## Technical Details

### Data Flow

1. **DisplayWizard** fetches main entity data (e.g., Category with ID 5)
2. **DisplaySection** passes entity data to each DisplayField
3. **DisplayField**:
   - Checks if `relatedEntityPropertyName` is set
   - If yes: navigates to `data[relatedEntityPropertyName]` (e.g., `data.ParentCategory`)
   - Then accesses `fieldName` from the related entity data
   - Formats and displays the value

### Case Sensitivity Handling
Both `getNestedValue` in DisplayField and property access handle multiple casing conventions:
- Original casing (as provided)
- PascalCase (first letter uppercase)
- camelCase (first letter lowercase)

This ensures compatibility with both DTO (camelCase) and entity (PascalCase) property names.

### Metadata Integration
The FieldEditor component:
- Uses main entity metadata by default
- Fetches related entity metadata when a navigation property is selected
- Uses `metadataClient.getEntityMetadata(entityTypeName)` to get fields
- Caches related metadata to avoid repeated API calls

## Benefits

1. **Flexibility:** Mix main and related entity fields in one section
2. **User Experience:** Intuitive dropdown selection with type information
3. **Type Safety:** Auto-population of field types from metadata
4. **Consistency:** Same casing handling as FormWizard FieldRenderers
5. **Maintainability:** Centralized related entity logic in DisplayField component

## Future Enhancements

Potential improvements:
- Support for nested related entities (e.g., `ParentCategory.IconMaterialRef.NamespaceKey`)
- Template text support for related entity fields
- Validation of related entity property existence
- Visual grouping of fields by related entity in the UI
- Bulk field addition from related entities
