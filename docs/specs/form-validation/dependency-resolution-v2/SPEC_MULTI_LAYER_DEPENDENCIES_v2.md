# SPEC: Multi-Layer Dependency Resolution for Field Validation Rules v2.0

**Status:** Requirements Definition  
**Created:** February 9, 2026  
**Version:** 2.0 (Extends v1 single-hop validation)  
**Scope:** v1 (single-hop only), v2 (multi-hop collections)

---

## Executive Summary

This specification extends the Inter-Field Validation Dependencies feature (v1) to support **multi-layer entity relationships** while maintaining simplicity and usability. It enables validation across entity hierarchies (e.g., Structure → District → Town → WgRegionId) through an intuitive path builder UI and hybrid pre-resolution strategy.

**Key Features:**
- ✅ Dot-notation path syntax (Entity.Property.NestedProperty)
- ✅ Smart field mapping with auto-suggestions (all properties visible; smart filters future-ready)
- ✅ Hybrid pre-resolution (batch endpoint for web app, pre-interpolated messages for plugins)
- ✅ Dehydrated payloads (minimize data transmission)
- ✅ Enhanced ConfigurationHealthPanel with entity metadata validation
- ✅ v1 scope: Single-hop only; v2 scope: Multi-hop with collection operators

---

## Part A: Design Decisions & Rationale

### A.1 Path Notation: Dot Notation with Entity-First References

**Decision:** Use **dot notation** with entity-centric navigation

**Notation Standard:**
```
Entity.Property.NestedProperty

Examples:
  Town.wgRegionId                    (single-hop: v1)
  Town.district.boundaries           (multi-hop: v2)
  PublicAccessPoint.coordinates       (scalar property)
  Towns[first].wgRegionId            (collection: v2)
```

**Rationale:**
- Industry standard across JSON, GraphQL, JavaScript object notation
- Most intuitive for non-technical administrators
- Clear visual hierarchy in dropdown UI
- Deterministic parsing and validation
- Easily extensible to collections (v2)

**v1 Scope:** Single-hop paths only
```
Entity.Property
  ↓
Formulas: Only ONE dot allowed
```

**v2 Scope:** Multi-hop and collections
```
Entity.Relation.Relation.Property
  ↓
Formulas: Multiple dots + [operator] notation
```

**Banned v1:**
- Spaces: `"Town . wgRegionId"`
- Brackets: `"Town[0].wgRegionId"`
- Underscores: `"town_region"`
- Functions: `"Town.getWgRegion()"`

---

### A.2 Field vs Property References

**Decision:** Entity-first references (matches admin mental model)

**When admin selects "Town" field in path builder:**
- System interprets as: "The Town entity related to current form"
- Path becomes: `"Town.wgRegionId"`
- Resolves in formContext as: `formContext['Town'].wgRegionId`

**Why not field-centric (`TownId.wgRegionId`)?**
- Confuses admins (TownId is an ID, not an entity)
- Error-prone (if field renamed, path breaks)
- Harder to visualize in UI

**Entity Resolution:**
1. Admin selects field name from dropdown (e.g., "Town")
2. System looks up field's expected entity type from metadata (e.g., "District" entity has field City which references "Town" entity)
3. System knows Town entity properties (from entity metadata API)
4. System suggests properties from Town entity

---

### A.3 Array/Collection Handling Strategy

**v1 (Current Release):** **Exclude collections entirely**

**v1 Behavior:**
- If dependency path resolves to array/collection → ERROR
- ConfigurationHealthPanel warns: "Field 'XYZ' resolves to collection; not supported in v1. Planned for v2."
- Admin must select single-entity relationship field

**v2 (Future Enhancement):** Support collections with explicit operators

**v2 Notation:**
```
Entity.Collection[OPERATOR].Property

Supported Operators:
  [first]     → Validate against first item in collection
  [last]      → Validate against last item
  [all]       → Validate against ALL items (must pass for each)
  [any]       → Validate against ANY item (pass if one succeeds)
  [user:{n}]  → User-selected index (validated in UI)
```

**v2 Error Reporting Example:**
```
ValidationResultDto.Message = 
  "Location is outside X of Y regions: 
   - Outside Region[0] 'Kingsport': (X: 1234, Z: 5678)
   - Outside Region[2] 'Harbor': (X: 1234, Z: 5678)"

Metadata includes per-item results:
  collectionResults: [
    { index: 0, regionName: "Kingsport", isValid: false },
    { index: 1, regionName: "Westport", isValid: true },
    { index: 2, regionName: "Harbor", isValid: false }
  ]
```

**Documentation Task (v1 release):** Document collection approach and prepare v2 design doc.

---

### A.4 FormContext Dehydration Strategy

**Decision:** Pragmatic hybrid dehydration (context-aware)

**For Web App Form Rendering:**
```typescript
interface EnrichedFormContext {
  // Core field values (always present)
  [fieldName: string]: any;
  
  // Hydrated related entities (for validation UI, error messages)
  // Loaded on-demand when field changes
  // Example: User selects Town → load full Town entity
  
  // Metadata (for resolution support)
  _fieldMetadata?: FormFieldMetadata[];
  _entityMetadata?: EntityMetadataMap;
  
  // Resolved dependencies cache (updated on each validation)
  _resolvedDependencies?: {
    [ruleId: number]: ResolvedDependency;
  };
}

// Concrete example after user selects Town (ID: 4)
{
  Town: {
    id: 4,
    name: "Cinix",
    description: "Bordertown of the Free World",
    wgRegionId: "town_1"
  },
  WgRegionId: null,
  Location: null,
  
  _fieldMetadata: [
    {fieldId: 68, fieldName: "Town", expectedEntityType: "Town", label: "Parent Town"},
    {fieldId: 61, fieldName: "WgRegionId", expectedEntityType: null, label: "Region ID"},
    {fieldId: 60, fieldName: "Location", expectedEntityType: "Location", label: "Spawn Location"}
  ],
  
  _resolvedDependencies: {
    123: {
      ruleId: 123,
      dependencyPath: "Town.wgRegionId",
      resolvedValue: "town_1",
      status: "success"
    }
  }
}
```

**For WorldTask Submission (Minecraft Plugin):**
```typescript
// Minimal payload sent to plugin
inputJson: {
  fieldName: "Location",
  currentValue: null,
  validationContext: {
    validationRules: [{
      validationType: "LocationInsideRegion",
      configJson: "{...}",
      errorMessage: "Location is outside Cinix's boundaries...",
      successMessage: "Location is within region boundaries ✓",
      isBlocking: true,
      dependencyFieldValue: {           // ← Pre-resolved, not entity
        id: 4,
        name: "Cinix",
        wgRegionId: "town_1"
      },
      preResolvedPlaceholders: {}
    }],
    formContext: {
      Town: {id: 4, name: "Cinix", wgRegionId: "town_1"},
      WgRegionId: null,
      Location: null
    }
  }
}
```

**For Error Message Generation:**

Backend pre-interpolates placeholders:
```json
{
  "isValid": false,
  "message": "Location (X: 1234, Z: 5678) is outside Cinix's boundaries. Please select a location within the town region.",
  "placeholders": {
    "entityName": "Cinix",
    "entityId": "4",
    "coordinates": "(X: 1234, Z: 5678)",
    "regionName": "town_1"
  }
}
```

**Dehydration Rules:**
| Context | Hydration Level | Rationale |
|---------|-----------------|-----------|
| Web App formContext | **Full entity** | Need for validation UI, error display, suggestions |
| WorldTask inputJson | **Entity reference only** | Plugin doesn't need full data; reduces payload |
| Error messages | **Pre-interpolated string** | Plugin just displays; no variable substitution needed |
| formContext in plugin | **Minimal** | Keep only data required for validation |

---

### A.5 Resolution Strategy: Hybrid Pre-Resolution with Batch Endpoint

**Decision:** Combine frontend eager-loading with batch backend resolution

**Architecture:**
```
1. Admin configures dependency path in FormBuilder
2. Form loads → fetch field metadata
3. Admin selects form field → formContext populates with field value
4. If field value changes:
   a. Call batch resolution endpoint with all rules + current formContext
   b. Backend resolves paths, extracts values, returns mapping
   c. Frontend caches resolved values
   d. UI updates immediately with validation feedback
5. On form submission:
   a. Include resolved values in WorldTask inputJson
   b. Plugin executes validation with pre-resolved data
```

**When Resolution Happens:**

| Event | Who Resolves | Scope |
|-------|--------------|-------|
| Form mount | Frontend (eager) | Load all dependency fields' entities |
| Field value change | Backend (on-demand) | Resolve all rules depending on that field |
| Validation execution | Backend | Extract specific dependency value for rule |
| Error interpolation | Backend | Pre-interpolate placeholders into message |
| Plugin execution | Frontend (embedded) | Use pre-resolved values from WorldTask |

**Caching Strategy:**
- Resolved values cached in `formContext._resolvedDependencies`
- Cache invalidated when dependency field changes
- Re-fetch only affected rules (batch endpoint returns diffs)

---

### A.6 Entity Metadata for Property Suggestions

**Decision:** Show ALL entity properties initially; design smart-filter for future

**v1 Behavior:** When admin selects entity in path builder dropdown:
- Display: ALL properties of that entity (scalars, relationships, computed)
- Format: `Property (Type)`, e.g., "wgRegionId (string), coordinates (object)"
- Search: Case-insensitive string search across property names

**v1 Documentation Task:** Add section on "Smart-Filter for Future Releases" explaining:
- How to extend with validation-type-specific suggestions
- Which properties are valid for each validation type (LocationInsideRegion, RegionContainment, etc.)
- How to mark properties as "validation-compatible" in entity metadata

**Future Smart-Filter Criteria:**
```typescript
interface EntityPropertyMetadata {
  name: string;
  type: "string" | "number" | "boolean" | "object" | "array";
  isValidationCompatible?: {
    LocationInsideRegion?: boolean;      // Only region properties
    RegionContainment?: boolean;          // Only region properties
    ConditionalRequired?: boolean;        // Any property
    CustomType?: boolean;                 // Future types
  };
  description?: string;
}

// Smart filter: Show only LocationInsideRegion-compatible properties
const suggestions = properties.filter(p => p.isValidationCompatible?.LocationInsideRegion);
```

---

### A.7 Enhancement: Configuration Health Panel with Entity Metadata Validation

**Decision:** Expand ConfigurationHealthPanel to validate against entity metadata

**New Validation Checks:**

1. **Field-Entity Alignment Check**
   - Form field "Town" references entity "Town"
   - Check: Does "Town" entity exist in metadata?
   - Error: "Entity 'Town' not found in system metadata. Rebuilding FormConfiguration may be needed."

2. **Property Existence Check**
   - Rule specifies path: "Town.wgRegionId"
   - Check: Does Town entity have property "wgRegionId"?
   - Error: "Property 'wgRegionId' not found on Town entity. (Available: id, name, description, boundaryPoints, ...)"

3. **Required Field Completeness Check**
   - Town entity has required property "name"
   - Check: Is "name" field set to required in FormConfiguration?
   - Warning: "Town.name is required by entity but not marked required in form."

4. **Relationship Type Validation**
   - Dependency path attempts multi-hop: "Town.District.wgRegionId"
   - Check: Is this v1 or v2? v1 → Error. v2 → Pass.
   - Error (v1): "Multi-hop paths not supported in v1. Please contact support to enable v2 features."

5. **Collection Warning (v1)**
   - Dependency field resolves to array: "Towns[*]"
   - Warning: "This field is a collection. v1 only supports single-entity relationships. Planned for v2."

6. **Circular Dependency Detection**
   - Field A depends on Field B, Field B depends on Field A
   - Error: "Circular dependency detected: Field A → Field B → Field A. Remove one dependency."

7. **Field Order Validation**
   - Dependency field comes AFTER dependent field
   - Warning: "Dependency field 'Town' is in Step 3, but dependent field 'Location' is in Step 2. Reorder for correct execution."

**Enhanced ConfigurationHealthPanel Output:**
```
Configuration Health Check Results:
─────────────────────────────────────

✅ Field Alignment (3/3 fields valid)
  ✓ Field 68 'Town' references entity Town

✅ Property Existence (5/5 paths valid)
  ✓ Town.wgRegionId exists
  ✓ Town.name exists
  ✓ Location.coordinates exists

⚠️  Required Field Completeness  (1 warning)
  ⚠ Town.name is required by entity but not enforced in form

✅ Collection Support (0 collections detected)

✅ Circular Dependencies (none detected)

✅ Field Ordering (correct)

Status: HEALTHY ✓ (1 warning)
```

---

## Part B: Technical Specifications - Backend (knk-web-api-v2)

### B.1 Entity Model Updates

#### FieldValidationRule (Updated)

```csharp
public class FieldValidationRule
{
    public int Id { get; set; }

    /// <summary>
    /// Foreign key to the FormField this rule is attached to (the field being validated).
    /// </summary>
    public int FormFieldId { get; set; }
    public FormField FormField { get; set; } = null!;

    /// <summary>
    /// Type of validation to perform.
    /// Supported v1 types:
    ///   - LocationInsideRegion
    ///   - RegionContainment
    ///   - ConditionalRequired
    /// </summary>
    public string ValidationType { get; set; } = string.Empty;

    /// <summary>
    /// [NEW] For multi-layer support: The path to navigate from dependency entity to extract value.
    /// Format: Entity.Property.NestedProperty (v1: single-hop only)
    /// 
    /// Examples:
    ///   - "Town.wgRegionId" → Navigate to related Town, extract wgRegionId
    ///   - "PublicAccessPoint.coordinates" → Navigate to related PublicAccessPoint, extract coordinates
    /// 
    /// REQUIRED for v2+ (v1 can still use ConfigJson)
    /// If present, takes precedence over ConfigJson.regionPropertyPath
    /// </summary>
    public string? DependencyPath { get; set; }

    /// <summary>
    /// Foreign key to the FormField this rule depends on.
    /// Example: LocationId field depends on TownId field
    /// </summary>
    public int? DependsOnFieldId { get; set; }
    public FormField? DependsOnField { get; set; }

    /// <summary>
    /// Generic JSON configuration for this validation rule.
    /// Structure varies by ValidationType.
    /// 
    /// v1 ConfigJson (legacy, deprecated in favor of DependencyPath):
    /// {
    ///   "regionPropertyPath": "WgRegionId",
    ///   "allowBoundary": false
    /// }
    /// 
    /// v2+ ConfigJson (RECOMMENDED):
    /// {
    ///   "validationType": "LocationInsideRegion",
    ///   "dependencyPath": "Town.wgRegionId",  // Replaces regionPropertyPath
    ///   "allowBoundary": false
    /// }
    /// </summary>
    public string ConfigJson { get; set; } = "{}";

    /// <summary>
    /// Error message displayed to user if validation fails.
    /// Supports placeholders: {entityName}, {entityId}, {fieldLabel}, {coordinates}, etc.
    /// Backend resolves placeholders before sending to frontend/plugin.
    /// </summary>
    public string ErrorMessage { get; set; } = string.Empty;

    /// <summary>
    /// Success message displayed if validation passes.
    /// </summary>
    public string? SuccessMessage { get; set; }

    /// <summary>
    /// If true, validation failure blocks field completion and step progression.
    /// </summary>
    public bool IsBlocking { get; set; } = true;

    /// <summary>
    /// If false (default), skip validation if dependency field is not yet filled.
    /// If true, show validation failure even if dependency not filled.
    /// </summary>
    public bool RequiresDependencyFilled { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

#### Database Migration

```sql
-- Add new columns to FieldValidationRules table
ALTER TABLE dbo.FieldValidationRules
ADD DependencyPath NVARCHAR(500) NULL;

-- Create index for frequent lookups
CREATE INDEX IX_FieldValidationRules_DependencyPath 
ON dbo.FieldValidationRules(FormFieldId, DependencyPath);

-- Note: All v1 rules have NULL DependencyPath (backward compatible)
-- Future migration job will populate DependencyPath from ConfigJson for v1 rules
```

---

### B.2 New DTOs

#### DependencyResolutionRequest

```typescript
/// <summary>
/// Request to pre-resolve all dependencies for a set of fields in a form.
/// Used by frontend to get resolved values for validation rules.
/// </summary>
public class DependencyResolutionRequest
{
    /// <summary>
    /// IDs of form fields that have validation rules depending on other fields.
    /// </summary>
    public int[] FieldIds { get; set; } = Array.Empty<int>();

    /// <summary>
    /// Current snapshot of form context data.
    /// Example: { "Town": { "id": 4, "name": "Cinix", "wgRegionId": "town_1" }, "WgRegionId": null }
    /// </summary>
    public Dictionary<string, object?> FormContextSnapshot { get; set; } = new();

    /// <summary>
    /// Optional: Form configuration ID for field name resolution.
    /// If provided, backend uses form structure to map field IDs to names.
    /// </summary>
    public int? FormConfigurationId { get; set; }
}
```

#### ResolvedDependency

```typescript
public class ResolvedDependency
{
    /// <summary>
    /// ID of the validation rule being resolved.
    /// </summary>
    public int RuleId { get; set; }

    /// <summary>
    /// Status of resolution: "success", "pending", "error"
    /// - success: Dependency field found and value extracted
    /// - pending: Dependency field not yet filled
    /// - error: Path invalid or entity not found
    /// </summary>
    public string Status { get; set; } = "pending";

    /// <summary>
    /// The extracted value to be used in validation.
    /// 
    /// For LocationInsideRegion with path "Town.wgRegionId":
    ///   resolvedValue = "town_1"
    /// </summary>
    public object? ResolvedValue { get; set; }

    /// <summary>
    /// The full path that was resolved.
    /// Example: "Town.wgRegionId"
    /// </summary>
    public string DependencyPath { get; set; } = "";

    /// <summary>
    /// Timestamp of resolution.
    /// </summary>
    public DateTime ResolvedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Human-readable reason if status is not "success".
    /// Example: "Dependency field 'Town' not yet filled"
    /// </summary>
    public string? Message { get; set; }

    /// <summary>
    /// For error status: Details on what went wrong.
    /// Example: "Property 'wgRegionId' not found on Town entity"
    /// </summary>
    public string? ErrorDetail { get; set; }
}
```

#### DependencyResolutionResponse

```typescript
public class DependencyResolutionResponse
{
    /// <summary>
    /// Map of RuleId → ResolvedDependency
    /// </summary>
    public Dictionary<int, ResolvedDependency> Resolved { get; set; } = new();

    /// <summary>
    /// Timestamp of resolution.
    /// </summary>
    public DateTime ResolvedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Optional: Validation issues detected during resolution.
    /// Example: Circular dependencies, missing paths, etc.
    /// </summary>
    public ValidationIssueDto[]? Issues { get; set; }
}
```

#### Enhanced ValidationResultDto

```typescript
public class ValidationResultDto
{
    public bool IsValid { get; set; }

    /// <summary>
    /// Final message displayed to user (placeholders already interpolated).
    /// </summary>
    public string? Message { get; set; }

    /// <summary>
    /// For error display purposes: structured placeholder values.
    /// Used by frontend for detailed error rendering.
    /// </summary>
    public Dictionary<string, string>? Placeholders { get; set; }

    public bool IsBlocking { get; set; }

    /// <summary>
    /// [NEW] Metadata about dependency resolution for this validation.
    /// </summary>
    public ValidationMetadataDto? Metadata { get; set; }
}

public class ValidationMetadataDto
{
    public string ValidationType { get; set; } = "";
    public DateTime ExecutedAt { get; set; }
    
    /// <summary>
    /// [NEW] The dependency path that was resolved.
    /// Example: "Town.wgRegionId"
    /// </summary>
    public string? DependencyPath { get; set; }

    /// <summary>
    /// [NEW] The field name that this rule depends on.
    /// Example: "Town"
    /// </summary>
    public string? DependencyFieldName { get; set; }

    /// <summary>
    /// The extracted value used for validation.
    /// </summary>
    public object? DependencyValue { get; set; }

    /// <summary>
    /// For collection results (v2): Per-item validation details.
    /// </summary>
    public CollectionValidationResult[]? CollectionResults { get; set; }
}

public class CollectionValidationResult
{
    public int Index { get; set; }
    public bool IsValid { get; set; }
    public string? EntityName { get; set; }
    public string? Message { get; set; }
}
```

---

### B.3 API Endpoints

#### NEW: Batch Dependency Resolution

```http
POST /api/field-validation-rules/resolve-dependencies

Content-Type: application/json

Request:
{
  "fieldIds": [60, 61, 62],
  "formContextSnapshot": {
    "Town": {
      "id": 4,
      "name": "Cinix",
      "description": "Bordertown of the Free World",
      "wgRegionId": "town_1"
    },
    "WgRegionId": null,
    "Location": null
  },
  "formConfigurationId": 1
}

Response:
{
  "resolved": {
    "123": {
      "ruleId": 123,
      "status": "success",
      "dependencyPath": "Town.wgRegionId",
      "resolvedValue": "town_1",
      "resolvedAt": "2026-02-09T10:30:00Z",
      "message": null,
      "errorDetail": null
    },
    "124": {
      "ruleId": 124,
      "status": "pending",
      "dependencyPath": "WgRegionId.boundaries",
      "resolvedValue": null,
      "resolvedAt": "2026-02-09T10:30:00Z",
      "message": "Dependency field 'WgRegionId' not yet filled",
      "errorDetail": null
    },
    "125": {
      "ruleId": 125,
      "status": "error",
      "dependencyPath": "Town.invalidProperty",
      "resolvedValue": null,
      "resolvedAt": "2026-02-09T10:30:00Z",
      "message": "Property not found",
      "errorDetail": "Town entity does not have property 'invalidProperty'"
    }
  },
  "resolvedAt": "2026-02-09T10:30:00Z",
  "issues": null
}
```

**Status Codes:**
- `200 OK` - Resolution completed (check individual status fields)
- `400 Bad Request` - Invalid request format
- `404 Not Found` - FormConfiguration not found
- `500 Internal Server Error` - Backend error

---

#### UPDATED: Validation Endpoint

```http
POST /api/field-validation-rules/validate

Request:
{
  "fieldId": 60,
  "fieldValue": 456,
  "dependsOnFieldId": 68,
  "formContextData": {
    "Town": {
      "id": 4,
      "name": "Cinix",
      "wgRegionId": "town_1"
    },
    "WgRegionId": null,
    "Location": null
  }
}

Response:
{
  "isValid": false,
  "message": "Location (X: 1234, Z: 5678) is outside Cinix's boundaries. Please select a location within the town region.",
  "placeholders": {
    "entityName": "Cinix",
    "entityId": "4",
    "coordinates": "(X: 1234, Z: 5678)",
    "regionName": "town_1"
  },
  "isBlocking": true,
  "metadata": {
    "validationType": "LocationInsideRegion",
    "executedAt": "2026-02-09T10:35:00Z",
    "dependencyPath": "Town.wgRegionId",
    "dependencyFieldName": "Town",
    "dependencyValue": "town_1",
    "collectionResults": null
  }
}
```

---

### B.4 Service Layer

#### PathResolutionService

Responsible for navigating dependency paths and extracting values.

```csharp
public interface IPathResolutionService
{
    /// <summary>
    /// Resolves a path against form context data.
    /// Handles multi-layer navigation: "Town.wgRegionId", "Town.boundary.points[0]", etc.
    /// </summary>
    /// <param name="path">Path like "Town.wgRegionId" or "Town.District.wgRegionId"</param>
    /// <param name="formContext">Form data snapshot</param>
    /// <returns>Extracted value or null if path invalid/incomplete</returns>
    Task<PathResolutionResult> ResolvePathAsync(
        string path,
        Dictionary<string, object?> formContext,
        int? formConfigurationId = null
    );

    /// <summary>
    /// Validates that a path is syntactically correct and consistent with entity metadata.
    /// Used by ConfigurationHealthPanel.
    /// </summary>
    Task<PathValidationResult> ValidatePathAsync(
        string path,
        int formConfigurationId
    );

    /// <summary>
    /// Get all available properties on an entity for UI suggestions.
    /// </summary>
    Task<EntityPropertySuggestion[]> GetAvailablePropertiesAsync(
        string entityTypeName
    );
}

public class PathResolutionResult
{
    public bool Success { get; set; }
    public object? Value { get; set; }
    public string? Error { get; set; }
    public string ResolvedPath { get; set; } = "";
}

public class PathValidationResult
{
    public bool IsValid { get; set; }
    public string? Error { get; set; }
    public string? DetailedError { get; set; }
}

public class EntityPropertySuggestion
{
    public string PropertyName { get; set; } = "";
    public string PropertyType { get; set; } = "";
    public bool IsRequired { get; set; }
    public bool IsNavigable { get; set; }  // Can be followed by another dot
    public string? Description { get; set; }
}
```

#### DependencyResolutionService

```csharp
public interface IDependencyResolutionService
{
    /// <summary>
    /// Batch resolve all dependencies for multiple validation rules.
    /// Used by frontend to pre-fetch all required values.
    /// </summary>
    Task<DependencyResolutionResponse> ResolveDependenciesAsync(
        DependencyResolutionRequest request
    );

    /// <summary>
    /// Perform configuration health checks including dependency analysis.
    /// </summary>
    Task<ValidationIssueDto[]> CheckConfigurationHealthAsync(
        int formConfigurationId
    );
}
```

---

## Part C: Technical Specifications - Frontend (knk-web-app)

### C.1 Frontend Architecture

#### New Component: PathBuilder

```tsx
interface PathBuilderProps {
  initialPath?: string;
  dependencyFieldId?: number;
  entityTypeName: string;
  onPathChange: (path: string) => void;
  onValidationStatusChange?: (status: PathValidationStatus) => void;
  fieldMetadata: FormFieldMetadata[];
  entityMetadata: EntityMetadataMap;
  disabled?: boolean;
}

/**
 * Interactive path builder with dropdown suggestions.
 * 
 * Usage:
 * User clicks "Town" dropdown → "wgRegionId" dropdown → path: "Town.wgRegionId"
 * 
 * Features:
 * - Autocomplete entity/property selection
 * - Visual path preview: "Town.wgRegionId" with icons
 * - Real-time validation against entity metadata
 * - Resolves example value from current formContext
 * - Error messages for invalid paths
 */
export const PathBuilder: React.FC<PathBuilderProps> = ({...}) => {
  // Implementation in later phase
};
```

#### Updated Component: EnrichedFormContext Hook

```tsx
interface EnrichedFormContextType {
  values: Record<string, any>;
  fieldMetadata: Map<number, FormFieldMetadata>;
  entityMetadata: EntityMetadataMap;
  resolvedDependencies: Map<number, ResolvedDependency>;
  isLoading: boolean;
  error: string | null;
  setFieldValue: (fieldName: string, value: any) => void;
  resolveDependency: (ruleId: number) => Promise<ResolvedDependency>;
  resolveDependenciesBatch: (ruleIds: number[]) => Promise<DependencyResolutionResponse>;
}

/**
 * Custom hook for managing enriched form context with dependency resolution.
 * 
 * Usage in FormRenderer:
 * const formContext = useEnrichedFormContext(formConfiguration);
 * 
 * Provides:
 * - Real-time field value tracking
 * - Batch dependency resolution
 * - Metadata loading and caching
 * - Error handling and recovery
 */
export const useEnrichedFormContext = (config: FormConfigurationDto): EnrichedFormContextType => {
  // Implementation in later phase
};
```

#### Updated Component: ValidationRuleBuilder

```tsx
interface ValidationRuleBuilderProps {
  rule: FieldValidationRuleDto;
  formConfiguration: FormConfigurationDto;
  fieldMetadata: FormFieldMetadata[];
  entityMetadata: EntityMetadataMap;
  onRuleChange: (rule: FieldValidationRuleDto) => void;
}

/**
 * Modal dialog for creating/editing validation rules.
 * 
 * New features:
 * - PathBuilder for dependency path configuration
 * - Visual path preview with resolved example value
 * - Real-time validation indicators
 * - Collection handling UI (v2 only)
 * - Message builder with placeholder suggestions
 */
export const ValidationRuleBuilder: React.FC<ValidationRuleBuilderProps> = ({...}) => {
  // Updated in later phase
};
```

#### Updated Component: ConfigurationHealthPanel

```tsx
interface ConfigurationHealthPanelProps {
  configurationId?: string;
  draftConfig?: FormConfigurationDto;
  entityMetadata?: EntityMetadataMap;  // [NEW]
  refreshToken?: number;
  onIssuesLoaded?: (count: number) => void;
}

/**
 * Enhanced health panel with entity metadata validation.
 * 
 * New checks:
 * - Field-entity alignment (entity exists in metadata)
 * - Property existence checks (properties exist on entities)
 * - Required field completeness (required entity fields marked required in form)
 * - Collection warnings (v1 vs v2)
 * - Circular dependency detection
 * - Field ordering validation
 */
export const ConfigurationHealthPanel: React.FC<ConfigurationHealthPanelProps> = ({...}) => {
  // Updated in later phase
};
```

---

### C.2 API Client Updates

#### fieldValidationRuleClient - New Methods

```typescript
export class FieldValidationRuleClient extends ObjectManager {
  /**
   * [NEW] Batch resolve dependencies for multiple validation rules.
   * Called by FormRenderer when field values change.
   */
  resolveDependencies(request: DependencyResolutionRequest): Promise<DependencyResolutionResponse> {
    return this.invokeServiceCall(
      request,
      "resolve-dependencies",
      Controllers.FieldValidationRules,
      HttpMethod.Post
    );
  }

  /**
   * Get all available properties on an entity for path builder suggestions.
   */
  getEntityProperties(entityTypeName: string): Promise<EntityPropertySuggestion[]> {
    return this.invokeServiceCall(
      null,
      `entity/${entityTypeName}/properties`,
      Controllers.FieldValidationRules,
      HttpMethod.Get
    );
  }

  /**
   * Validate a path against entity metadata.
   */
  validatePath(path: string, entityTypeName: string): Promise<PathValidationResult> {
    return this.invokeServiceCall(
      { path, entityTypeName },
      "validate-path",
      Controllers.FieldValidationRules,
      HttpMethod.Post
    );
  }
}
```

#### metadataClient - New Methods (if needed)

```typescript
export class MetadataClient extends ObjectManager {
  /**
   * Get metadata for specific entity including all properties and relationships.
   * Used by PathBuilder and validation components.
   */
  getEntityMetadataDetailed(entityName: string): Promise<DetailedEntityMetadataDto> {
    return this.invokeServiceCall(
      null,
      `${MetadataOperation.Entities}/${entityName}/detailed`,
      Controllers.Metadata,
      HttpMethod.Get
    );
  }
}
```

---

### C.3 TypeScript DTOs

```typescript
// Extend FieldValidationRuleDto
export interface FieldValidationRuleDto {
  id: number;
  formFieldId: number;
  validationType: string;
  dependsOnFieldId?: number;
  
  // [NEW] Multi-layer support
  dependencyPath?: string;  // e.g., "Town.wgRegionId"
  
  configJson: string;
  errorMessage: string;
  successMessage?: string;
  isBlocking: boolean;
  requiresDependencyFilled: boolean;
  createdAt: string;
  formField?: FormFieldNavDto;
  dependsOnField?: FormFieldNavDto;
}

// [NEW] Request/Response DTOs
export interface DependencyResolutionRequest {
  fieldIds: number[];
  formContextSnapshot: Record<string, any>;
  formConfigurationId?: number;
}

export interface ResolvedDependency {
  ruleId: number;
  status: "success" | "pending" | "error";
  resolvedValue?: any;
  dependencyPath: string;
  resolvedAt: string;
  message?: string;
  errorDetail?: string;
}

export interface DependencyResolutionResponse {
  resolved: Record<number, ResolvedDependency>;
  resolvedAt: string;
  issues?: ValidationIssueDto[];
}

// [NEW] Suggestions
export interface EntityPropertySuggestion {
  propertyName: string;
  propertyType: string;
  isRequired: boolean;
  isNavigable: boolean;
  description?: string;
}

// [NEW] Form field metadata
export interface FormFieldMetadata {
  fieldId: number;
  fieldName: string;
  label: string;
  expectedEntityType?: string;  // e.g., "Town"
  formStepIndex: number;
}
```

---

### C.4 UI/UX Design

#### Path Builder Modal Dialog (Responsive)

**Desktop (>1024px):**
```
┌─────────────────────────────────────────────────────────┐
│ Configure Dependency Path                           [X] │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Dependency Field:  [Town ▼]                             │
│                                                          │
│ Property Path:                                           │
│   [Town ▼] . [wgRegionId ▼]                             │
│                                                          │
│ Example Value (current form): "town_1"                  │
│ Property Type: string                                   │
│                                                          │
│ ✓ Valid path for LocationInsideRegion                   │
│                                                          │
│                                [Cancel]  [Save Path]     │
└─────────────────────────────────────────────────────────┘
```

**Mobile (<768px):**
```
┌──────────────────────────────────┐
│ Dependency Path Configuration [X] │
├──────────────────────────────────┤
│                                  │
│ Dependency Field:                │
│ [Town                         ▼] │
│                                  │
│ Property:                        │
│ [wgRegionId                   ▼] │
│                                  │
│ Example: "town_1"               │
│ Type: string                     │
│                                  │
│ [Cancel]    [Save]               │
└──────────────────────────────────┘
```

**Tablet (768px-1024px):** Intermediate sizing

---

#### ConfigurationHealthPanel Enhancements

**New Section: Entity Metadata Validation**

```
Configuration Health Check Results:
─────────────────────────────────────────────────────────────

✅ Field Alignment (3/3 valid)
   ✓ Field 68 'Town' → Entity: Town (exists)
   ✓ Field 61 'WgRegionId' → Scalar field
   ✓ Field 60 'Location' → Entity: Location (exists)

✅ Property Validation (5/5 valid)
   ✓ Town.wgRegionId ← string (entity property)
   ✓ Town.name ← string (entity property) [Required]
   ✓ Location.coordinates ← object (entity property)
   ✓ Region.boundaryPoints ← array (entity property)
   ✓ PublicAccessPoint.x ← number (entity property)

⚠️  Required Field Completeness (1 warning)
   ⚠ Town.name is required by entity metadata but form field 
     'Town' is marked optional. [Fix]
   Action: Mark 'Town' field as required

✅ Collection Support (0 collections detected - v1 compatible)

✅ Circular Dependencies (none detected)

✅ Field Ordering
   ✓ All dependency fields appear before dependent fields

Status: HEALTHY with warnings (1)
Actions Recommended: 1
```

**Clickable Actions:**
- `[Fix]` → Quick action to mark field required
- `[More Details]` → Expand error details
- `[Rebuild Suggestions]` → Suggest FormConfiguration updates

---

## Part D: Implementation Roadmap

### Phase 1: Backend Foundation (Weeks 1-2)

**Tasks:**
1. Update FieldValidationRule entity model with DependencyPath property
2. Create database migration script
3. Implement IPathResolutionService interface
4. Implement path validation logic (syntax, circular dependencies)
5. Write unit tests for path resolution

**Deliverables:**
- ✅ Updated models
- ✅ Database migration
- ✅ PathResolutionService implementation
- ✅ Unit tests (80% coverage)

---

### Phase 2: Backend Dependency Resolution API (Weeks 2-3)

**Tasks:**
1. Implement IDependencyResolutionService
2. Create API endpoints:
   - POST /api/field-validation-rules/resolve-dependencies
   - POST /api/field-validation-rules/validate-path
   - GET /api/field-validation-rules/entity/{entityName}/properties
3. Add placeholder interpolation logic
4. Implement batch resolution with caching
5. Write integration tests

**Deliverables:**
- ✅ Dependency resolution service
- ✅ API endpoints
- ✅ Integration tests

---

### Phase 3: Enhanced Configuration Health Checks (Weeks 3-4)

**Tasks:**
1. Implement entity metadata validation checks
2. Update ConfigurationHealthPanel backend
3. Add field-entity alignment validation
4. Add property existence checks
5. Add required field completeness checks
6. Write tests for health checks

**Deliverables:**
- ✅ Enhanced health check service
- ✅ Validation issue detection
- ✅ Tests

---

### Phase 4: Frontend - Data Layer & Hooks (Weeks 4-5)

**Tasks:**
1. Create enhanced TypeScript DTOs/types
2. Update fieldValidationRuleClient with new methods
3. Implement useEnrichedFormContext hook
4. Implement batch dependency resolution hook
5. Add caching and error handling
6. Write tests for hooks

**Deliverables:**
- ✅ Updated API client
- ✅ Custom hooks
- ✅ Type definitions
- ✅ Tests

---

### Phase 5: Frontend - PathBuilder Component (Weeks 5-6)

**Tasks:**
1. Implement PathBuilder component with:
   - Entity dropdown selector
   - Property multiselect dropdowns
   - Real-time validation
   - Example value preview
   - Responsive design
2. Integrate with FormFieldMetadata
3. Add error messaging
4. Implement property suggestions
5. Write component tests

**Deliverables:**
- ✅ PathBuilder component
- ✅ Component tests
- ✅ Storybook stories

---

### Phase 6: Frontend - UI Integration (Weeks 6-7)

**Tasks:**
1. Update ValidationRuleBuilder to use PathBuilder
2. Update ConfigurationHealthPanel with new checks/visuals
3. Integrate entityMetadata into health checks
4. Add recommended actions (Quick Fix buttons)
5. Responsive design testing across devices
6. Accessibility testing (WCAG 2.1 AA)

**Deliverables:**
- ✅ Updated UI components
- ✅ Responsive designs
- ✅ Accessibility tests
- ✅ Visual regression tests

---

### Phase 7: Frontend - WorldTask Integration (Weeks 7-8)

**Tasks:**
1. Update WorldBoundFieldRenderer to use resolved values
2. Update WorldTaskCta for multi-layer dependencies
3. Ensure proper dehydration in WorldTask payload
4. Test with actual Minecraft plugin
5. Validate placeholder interpolation in messages

**Deliverables:**
- ✅ Updated WorldTask components
- ✅ Integration tests with plugin
- ✅ E2E test scenarios

---

### Phase 8: Testing & Documentation (Weeks 8-9)

**Tasks:**
1. End-to-end testing scenarios:
   - Single-hop dependencies (v1)
   - Path validation workflows
   - Error cases and error messages
   - Plugin execution with pre-resolved values
2. Load testing (batch resolution with 100+ rules)
3. Write comprehensive feature documentation:
   - User guide for admins
   - Developer guide
   - API documentation
   - Troubleshooting guide
4. Create training materials

**Deliverables:**
- ✅ E2E test suite
- ✅ Test results report
- ✅ Documentation
- ✅ Training materials

---

### Phase 9: v2 Planning (v2 Release - Future)

**Document for Future Implementation:**
1. Collection operator syntax and UI
2. Multi-hop path navigation
3. Smart property filtering
4. FormConfiguration versioning and migration
5. Advanced error reporting for collections

---

## Part E: Data Dehydration Examples

### Example 1: Web App Form Renderer (Full Hydration)

```typescript
// User selects Town (ID: 4)
const formContext: EnrichedFormContext = {
  // Raw values
  Town: {
    id: 4,
    name: "Cinix",
    description: "Bordertown of the Free World",
    wgRegionId: "town_1"
  },
  WgRegionId: null,
  Location: null,
  
  // Metadata for resolution
  _fieldMetadata: [
    {
      fieldId: 68,
      fieldName: "Town",
      label: "Parent Town",
      expectedEntityType: "Town",
      formStepIndex: 0
    }
  ],
  
  // Resolved dependencies
  _resolvedDependencies: {
    123: {
      ruleId: 123,
      status: "success",
      dependencyPath: "Town.wgRegionId",
      resolvedValue: "town_1",
      message: null
    }
  }
};

// UI renders:
// ✓ Validation passed
// Location preview shows "Must be inside town_1"
```

---

### Example 2: WorldTask Submission (Dehydrated)

```json
{
  "workflowSessionId": 68,
  "stepNumber": 1,
  "stepKey": "Spawn Location",
  "fieldName": "Location",
  "taskType": "LocationCapture",
  "inputJson": {
    "fieldName": "Location",
    "currentValue": null,
    "validationContext": {
      "validationRules": [
        {
          "validationType": "LocationInsideRegion",
          "configJson": "{\"regionPropertyPath\":\"WgRegionId\"}",
          "errorMessage": "Location is outside {townName}'s boundaries...",
          "successMessage": "Location is within region boundaries ✓",
          "isBlocking": true,
          "dependencyFieldValue": {
            "id": 4,
            "name": "Cinix",
            "wgRegionId": "town_1"
          },
          "preResolvedPlaceholders": {}
        }
      ],
      "formContext": {
        "Town": {
          "id": 4,
          "name": "Cinix",
          "wgRegionId": "town_1"
        },
        "WgRegionId": null,
        "Location": null
      }
    }
  }
}
```

Note: Only `dependencyFieldValue` sent, not full entity metadata.

---

### Example 3: Plugin Error Message (Pre-Interpolated)

```json
{
  "isValid": false,
  "message": "Location (X: 1234, Z: -553,883) is outside Cinix's boundaries. Please select a location within the town region.",
  "placeholders": {
    "townName": "Cinix",
    "townId": "4",
    "coordinates": "(X: 1234, Z: -553.883)",
    "regionId": "town_1"
  },
  "isBlocking": true
}
```

Plugin displays `message` directly; doesn't need to resolve placeholders.

---

## Part F: Frequently Asked Questions (FAQ)

### Migration from v1 to v2

**Q: How will existing v1 rules be handled?**  
A: All current rules are legacy (no production rules exist per your note). New rules created in v2 must use DependencyPath. Backwards compatibility maintained through ConfigJson fallback.

---

### Circular Dependency Prevention

**Q: What happens if admin creates Field A → Field B → Field A?**  
A: Blocked at rule creation time with error: "Circular dependency detected. Field A depends on B, which depends on A."

---

### Multi-Hop Path Examples (for v2 Planning)

```
Structure → Structure.Districts[0] → District.Town → Town.wgRegionId
Path: "Districts[first].Town.wgRegionId"

Validates: "Location must be inside first district's town region"
```

---

### Error Message Customization

**Q: Can admin include dynamic data in error messages?**  
A: Yes, via placeholders. Supported placeholders:
- `{entityName}` - Display name of dependency entity
- `{entityId}` - Internal ID of dependency entity
- `{fieldLabel}` - Label of dependent field
- `{coordinates}` - For Location fields
- `{regionName}` - For region validation
- Custom placeholders registered per validation type

---

## Part G: Success Criteria

### v1 Release Criteria

- ✅ Single-hop paths working end-to-end
- ✅ Path builder UI tested across devices (desktop, tablet, mobile)
- ✅ ConfigurationHealthPanel showing 7+ validation checks
- ✅ WorldTask integration with dehydrated payloads working
- ✅ Error messages pre-interpolated on backend
- ✅ 80%+ code coverage (unit + integration tests)
- ✅ Zero breaking changes to existing functionality
- ✅ Documentation complete and accessible

### v2 Release Criteria (Future)

- Collection operators ([first], [last], [all], [user]) implemented
- Multi-hop paths fully supported
- Smart property filtering based on validation type
- FormConfiguration versioning (sidenote feature)
- Performance tested with 500+ rules

---

## Part H: Glossary & Terminology

| Term | Definition |
|------|-----------|
| **Path** | Navigation expression like "Town.wgRegionId" |
| **DependencyPath** | Formal name of the path expression stored in database |
| **Hop** | One step in path navigation (e.g., "Town.wgRegionId" = 1 hop) |
| **Collection** | Array-type property (v2 feature) |
| **Operator** | Collection filter ([first], [all], etc.) |
| **Dehydration** | Removing unnecessary data before transmission |
| **Interpolation** | Replacing placeholders with actual values |
| **Health Check** | Validation of FormConfiguration against entity metadata |
| **Pre-resolution** | Resolving dependencies before form submission |

---

## Appendix A: Configuration Examples

### Example 1: District form - Location inside Town region

```json
{
  "formConfigurationId": 1,
  "entityTypeName": "District",
  "steps": [
    {
      "stepName": "Basic Info",
      "fields": [
        {
          "id": 68,
          "fieldName": "Town",
          "expectedEntityType": "Town",
          "label": "Parent Town",
          "order": 0
        }
      ]
    },
    {
      "stepName": "Spawn Location",
      "fields": [
        {
          "id": 60,
          "fieldName": "Location",
          "label": "Spawn Location",
          "order": 1,
          "validations": [
            {
              "validationType": "LocationInsideRegion",
              "dependsOnFieldId": 68,
              "dependencyPath": "Town.wgRegionId",
              "configJson": "{}",
              "errorMessage": "Location {coordinates} is outside {townName}'s boundaries.",
              "successMessage": "Location is within region boundaries ✓",
              "isBlocking": true
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Appendix B: Path Validation Rules (v1)

1. **Must contain exactly one dot (single-hop)**
   - Valid: `"Town.wgRegionId"`
   - Invalid: `"Town"` (no dot), `"Town.District.wgRegionId"` (multiple dots)

2. **No whitespace**
   - Valid: `"Town.wgRegionId"`
   - Invalid: `"Town . wgRegionId"`

3. **PascalCase for entities, camelCase for properties (recommended)**
   - Valid: `"Town.wgRegionId"` (admin will see this pattern)
   - Invalid: `"TOWN.WGREGIONID"` (parsing allows, but discouraged)

4. **No special characters except dots**
   - Valid: `"Town.wgRegionId"`
   - Invalid: `"Town->wgRegionId"`, `"Town[0]"`

5. **Left side must be valid entity field name from form**
   - Invalid: `"InvalidField.wgRegionId"` → must match form field name

6. **Right side must be valid property on entity**
   - Invalid: `"Town.invalidProperty"` → must exist in Town metadata

---

**Last Updated:** February 9, 2026  
**Status:** Ready for Implementation
