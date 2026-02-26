# Placeholder Interpolation - Implementation Roadmap

**Feature**: Multi-layer placeholder variable resolution for validation error messages  
**Status**: Planning  
**Created**: February 8, 2026

This document provides a step-by-step implementation plan for the placeholder interpolation system across backend API, frontend web app, and Minecraft plugin.

---

## Overview

The placeholder interpolation feature enables dynamic error/success messages in field validation rules by resolving variables like `{Name}`, `{Town.Name}`, `{District.Town.Name}`, and `{Town.Districts.Count}` from multiple data sources across four layers of complexity.

### Placeholder Layers

| Layer | Example | Source | Complexity |
|-------|---------|--------|------------|
| **Layer 0** | `{Name}` | Current form data | Simple (frontend extraction) |
| **Layer 1** | `{Town.Name}` | Single navigation | Medium (DB query with Include) |
| **Layer 2** | `{District.Town.Name}` | Multi-level navigation | High (dynamic Include chain) |
| **Layer 3** | `{Town.Districts.Count}` | Aggregate operations | High (collection navigation) |

---

## Global Design Principles

### 1. Component Reuse & Pattern Consistency
- **Follow existing patterns**: Locate reference implementations in the codebase first (FormConfiguration system, FieldValidationRule entity, FormWizard component)
- **Reuse generic services**: Leverage existing `IDbContext`, logging infrastructure, and dependency injection patterns
- **Extend, don't reinvent**: Update existing DTOs and controllers rather than creating parallel structures
- **Shared utilities**: All layers (Backend, Frontend, Plugin) must use the same placeholder path parsing logic to ensure consistency
- **Single source of truth**: PlaceholderResolutionService is the authoritative resolver; other components consume its results

### 2. Layer-Based Architecture
The placeholder interpolation system is built on **four independent resolution layers** that work in sequence:

**Layer 0 (Frontend)**: Direct entity properties from FormWizard state
- Responsibility: Extract current form field values
- Who: Frontend FormWizard component
- Cost: O(1) - no external queries
- Example: `{Name}` → "York" from form.Name

**Layer 1 (Backend)**: Single-level navigation with single DB query
- Responsibility: Query related entity and extract properties
- Who: PlaceholderResolutionService.ResolveLayer1Async()
- Cost: O(1) DB query + property navigation
- Pattern: Use EF Core `FindAsync()` + reflection navigation
- Example: `{Town.Name}` → Query Town, get Name property

**Layer 2 (Backend)**: Multi-level navigation with dynamic Include chains
- Responsibility: Build and execute Include chains for deep navigation
- Who: PlaceholderResolutionService.ResolveLayer2Async()
- Cost: O(1) optimized DB query with all needed Includes
- Pattern: Build Include paths dynamically, use string-based Include
- Example: `{District.Town.Name}` → Include("District").Include("District.Town"), navigate chain

**Layer 3 (Backend)**: Aggregate operations on collections
- Responsibility: Navigate to collections and perform aggregates
- Who: PlaceholderResolutionService.ResolveLayer3Async()
- Cost: O(1) DB query + collection iteration (no additional queries)
- Pattern: Navigate to collection, execute aggregate in-memory
- Example: `{Town.Districts.Count}` → Load Town with Districts Include, count collection

**Key Principle**: Each layer is **independent and testable** but the backend **combines all layers** in a single database roundtrip to avoid N+1 queries.

### 3. Placeholder Resolution Flow

```
Frontend FormWizard
├─ Extract Layer 0 (current form data)
│  └─ buildPlaceholderContext(config, allStepsData)
│
├─ Call Backend Resolution API
│  └─ POST /api/field-validations/resolve-placeholders
│     {
│       fieldValidationRuleId: 3,
│       currentEntityPlaceholders: { Name: "York" },  ← Layer 0
│       placeholderPaths: [all extracted from rule.ErrorMessage]
│     }
│
└─ Receive PlaceholderResolutionResponse
   {
     resolvedPlaceholders: {
       Name: "York",                    ← Layer 0 (passed through)
       Town.Name: "Springfield",        ← Layer 1 (DB query)
       District.Town.Name: "...",       ← Layer 2 (DB query with Include)
       Town.Districts.Count: "5"        ← Layer 3 (DB query with Include)
     },
     unresolvedPlaceholders: [],
     resolutionErrors: []
   }
```

### 4. Database Query Optimization
- **Single roundtrip principle**: All DB queries needed for all layers execute in one roundtrip via strategically used `Include()` paths
- **No N+1 queries**: Avoid sequential queries for each navigation; use Include chains instead
- **Fail-safe design**: If resolution fails for any placeholder, return error details but don't block the form (fail-open)
- **Caching strategy** (future): Cache resolved values per entity type + ID during form session

### 5. Frontend-Plugin Contract
- **Pre-resolution responsibility**: FormWizard resolves ALL layers (0-3) before creating WorldTask
- **Plugin receives**: InputJson with `currentEntityPlaceholders` dictionary already fully resolved
- **Plugin interpolates**: Only performs simple string replacement, no DB queries
- **Data format**: JSON allows plugin to interpolate any placeholder format without parse logic

---

## Layer Resolution Architecture (Detailed)

### Layer 0: Frontend Direct Properties
```
Source: FormWizard state (allStepsData)
Pattern: buildPlaceholderContext() utility
Example: All FormField.fieldName values from form

// Frontend code
const layer0 = buildPlaceholderContext(config, allStepsData);
// Result: { Name: "York", Description: "A historic district", ... }
```

### Layer 1: Single Navigation (DB Query)
```
Pattern: navigation.Property
Source: Related entity accessed via foreign key + Include

// Backend code
1. Get navigation property metadata: entityType.GetProperty("Town")
2. Get foreign key value: entity.TownId = 5
3. Fetch related entity: await dbContext.Towns.FindAsync(5)
4. Extract property: town.Name = "Springfield"
Result: { Town.Name: "Springfield" }
```

### Layer 2: Multi-Level Navigation (Dynamic Include Chain)
```
Pattern: navigation1.navigation2.Property
Source: Related entities accessed via dynamic Include chains

// Backend code
1. Parse path: ["District", "Town", "Name"]
2. Build Includes: ["District", "District.Town"]
3. Fetch with chain: dbContext.Structures
   .Include("District")
   .Include("District.Town")
   .FirstAsync(s => s.Id == id)
4. Navigate chain: entity.District.Town.Name = "Springfield"
Result: { District.Town.Name: "Springfield" }
```

### Layer 3: Aggregates (Collection Navigation)
```
Pattern: navigation.Collection.Operator
Source: Collections accessed via Include + LINQ operations

// Backend code
1. Identify aggregate: "Town.Districts.Count"
2. Build Include chain: ["Town", "Town.Districts"]
3. Navigate: entity.Town → Navigate to Districts collection
4. Execute aggregate: districts.Count() = 5
Result: { Town.Districts.Count: "5" }
```

---

## Phase 1: Backend Foundation (Data Model & Infrastructure)

### Priority: CRITICAL - Blocks all other work

#### 1.1 Create PlaceholderPath Utility Class
Create `Models/PlaceholderPath.cs`:

- [ ] Add properties:
  - `string FullPath` - Full placeholder string without braces (e.g., "Town.Name")
  - `int Depth` - Number of navigation steps (0 for direct, 1+ for navigation)
  - `List<string> Segments` - Path segments (e.g., ["Town", "Name"])
  - `string NavigationChain` - All segments except final property
  - `string FinalProperty` - Last segment (the property to extract)
  - `bool IsNavigationRequired` - True if Depth > 0
  - `bool IsAggregateOperation` - True if final segment is Count/First/Last
- [ ] Add static parser method:
  - `ParsePlaceholder(string placeholder)` - Parses "{Town.Name}" → PlaceholderPath
  - Handle braces removal
  - Split by dots
  - Validate format
- [ ] Add unit tests for edge cases:
  - Single property: `{Name}` → Depth 0
  - Single navigation: `{Town.Name}` → Depth 1
  - Multi navigation: `{District.Town.Name}` → Depth 2
  - Aggregates: `{Town.Districts.Count}` → IsAggregateOperation = true
  - Invalid formats: empty, no property, malformed

**File**: `Models/PlaceholderPath.cs` (new)

**Effort**: 1 hour

---

#### 1.2 Create PlaceholderResolutionRequest DTO
Create `Dtos/PlaceholderResolutionDtos.cs`:

- [ ] Create `PlaceholderResolutionRequest`:
  - `int? FieldValidationRuleId` - Optional rule to extract placeholders from
  - `string? EntityTypeName` - Type of entity being created/edited (e.g., "District")
  - `int? EntityId` - Entity ID (null for create, value for edit)
  - `List<string>? PlaceholderPaths` - Explicit paths to resolve (overrides rule)
  - `Dictionary<string, string>? CurrentEntityPlaceholders` - Layer 0 values from frontend
  
- [ ] Create `PlaceholderResolutionResponse`:
  - `Dictionary<string, string> ResolvedPlaceholders` - All resolved placeholders
  - `List<string> UnresolvedPlaceholders` - Paths that failed to resolve
  - `List<PlaceholderResolutionError> ResolutionErrors` - Detailed error info
  
- [ ] Create `PlaceholderResolutionError`:
  - `string PlaceholderPath` - Which placeholder failed
  - `string ErrorCode` - Error type (e.g., "NavigationFailed", "PropertyNotFound")
  - `string ErrorMessage` - Human-readable message
  - `string? StackTrace` - Optional debug info

- [ ] Create `ValidationResultDto` (if not exists):
  - `bool IsValid` - Validation passed/failed
  - `string Message` - Template with unreplaced placeholders
  - `Dictionary<string, string> Placeholders` - Key-value pairs for interpolation
  - `bool IsBlocking` - Block progression if invalid
  - `string? SuccessMessage` - Optional success message template

**File**: `Dtos/PlaceholderResolutionDtos.cs` (new)

**Effort**: 45 minutes

---

#### 1.3 Update FieldValidationRuleDtos
Update `Dtos/FieldValidationRuleDtos.cs`:

- [ ] Review existing `FieldValidationRuleDto` structure
- [ ] Ensure `ErrorMessage` and `SuccessMessage` fields exist
- [ ] Add XML documentation explaining placeholder syntax:
  - Layer 0: Direct properties (`{Name}`, `{Description}`)
  - Layer 1: Single navigation (`{Town.Name}`)
  - Layer 2: Multi-level (`{District.Town.Name}`)
  - Layer 3: Aggregates (`{Town.Districts.Count}`)
- [ ] Add validation attributes if needed (MaxLength for messages)

**File**: `Dtos/FieldValidationRuleDtos.cs`

**Effort**: 15 minutes

---

### Phase 1 Summary
- **Total Effort**: ~2 hours
- **Risk**: Low (foundational utilities, no complex logic)
- **Deliverables**: PlaceholderPath parser, PlaceholderResolution DTOs, updated validation DTOs

---

## Phase 2: Backend Services (Business Logic)

### Priority: HIGH - Core placeholder resolution logic

#### 2.1 Create IPlaceholderResolutionService Interface
Create `Services/Interfaces/IPlaceholderResolutionService.cs`:

```csharp
public interface IPlaceholderResolutionService
{
    // Extract placeholder paths from message templates
    Task<List<string>> ExtractPlaceholdersAsync(string messageTemplate);
    
    // Resolve all layers of placeholders
    Task<PlaceholderResolutionResponse> ResolveAllLayersAsync(
        PlaceholderResolutionRequest request);
    
    // Layer-specific resolution
    Task<Dictionary<string, string>> ResolveLayer0Async(
        Dictionary<string, string> currentEntityPlaceholders);
    
    Task<Dictionary<string, string>> ResolveLayer1Async(
        Type entityType,
        object entityId,
        List<string> singleNavPlaceholders);
    
    Task<Dictionary<string, string>> ResolveLayer2Async(
        Type entityType,
        object entityId,
        List<string> multiNavPlaceholders);
    
    Task<Dictionary<string, string>> ResolveLayer3Async(
        Type entityType,
        object entityId,
        List<string> aggregatePlaceholders);
    
    // Interpolation utility
    string InterpolatePlaceholders(
        string messageTemplate,
        Dictionary<string, string> placeholders);
}
```

**File**: `Services/Interfaces/IPlaceholderResolutionService.cs` (new)

**Effort**: 20 minutes

---

#### 2.2 Implement PlaceholderResolutionService
Create `Services/PlaceholderResolutionService.cs`:

- [ ] Inject `IDbContext` dependency for database queries
- [ ] Inject `ILogger<PlaceholderResolutionService>` for logging
- [ ] Implement `ExtractPlaceholdersAsync`:
  - Use Regex pattern `\{([^}]+)\}` to find all placeholders
  - Return list of placeholder paths (without braces)
  - Handle edge cases: empty message, no placeholders, malformed syntax
  
- [ ] Implement `ResolveAllLayersAsync`:
  - Parse placeholders from request or extract from rule's ErrorMessage
  - Categorize by layer (0, 1, 2, 3) using PlaceholderPath.Depth
  - Call layer-specific resolution methods
  - Merge results into single dictionary
  - Collect errors for unresolved placeholders
  - Return PlaceholderResolutionResponse
  
- [ ] Implement `ResolveLayer0Async`:
  - Simply return currentEntityPlaceholders as-is
  - Validate keys match expected format (no dots for Layer 0)
  
- [ ] Implement `ResolveLayer1Async`:
  - Group placeholders by navigation property (e.g., "Town" in "{Town.Name}")
  - For each navigation property:
    - Get entity type's navigation property metadata via reflection
    - Get foreign key value (e.g., District.TownId)
    - Fetch related entity using `_dbContext.Set<T>().FindAsync(foreignKeyValue)`
    - Extract requested properties from related entity
  - Handle errors: property not found, navigation failed, null values
  - Return dictionary with resolved values
  
- [ ] Implement `ResolveLayer2Async`:
  - Parse multi-level navigation chains (e.g., "District.Town.Name")
  - Build dynamic Include expression chains
  - Use EF Core's `Include()` method with string paths
  - Fetch entity with all required related entities in single query
  - Navigate property chain using reflection
  - Extract final property value
  - Handle errors: navigation chain broken, null intermediate values
  
- [ ] Implement `ResolveLayer3Async`:
  - Parse aggregate operations (Count, First, Last)
  - Navigate to collection property
  - Execute aggregate operation:
    - `Count` → Cast to IEnumerable, call Count()
    - `First` → Get first element's ToString()
    - `Last` → Get last element's ToString()
  - Handle errors: collection null, collection empty (for First/Last)
  
- [ ] Implement `InterpolatePlaceholders`:
  - Iterate `placeholders` dictionary
  - Replace `{key}` with value in messageTemplate
  - Use case-insensitive replacement
  - Return interpolated message
  
- [ ] Add comprehensive logging:
  - Log each layer resolution start/end
  - Log errors with placeholder path + exception
  - Log successful resolutions with value (debug level)

**File**: `Services/PlaceholderResolutionService.cs` (new)

**Effort**: 4-5 hours

---

#### 2.3 Create/Update IFieldValidationService Interface
Update `Services/Interfaces/IFieldValidationService.cs`:

```csharp
public interface IFieldValidationService
{
    // Execute validation with placeholder resolution
    Task<ValidationResultDto> ValidateFieldAsync(
        FieldValidationRule rule,
        object fieldValue,
        object? dependencyFieldValue = null,
        Dictionary<string, string>? currentEntityPlaceholders = null,
        int? entityId = null);
    
    // Resolve placeholders for a given rule
    Task<PlaceholderResolutionResponse> ResolvePlaceholdersForRuleAsync(
        FieldValidationRule rule,
        int? entityId = null,
        Dictionary<string, string>? currentEntityPlaceholders = null);
    
    // Validation type implementations
    Task<ValidationResultDto> ValidateLocationInsideRegionAsync(
        FieldValidationRule rule,
        object fieldValue,
        object? dependencyFieldValue,
        Dictionary<string, string> placeholders);
    
    Task<ValidationResultDto> ValidateRegionContainmentAsync(
        FieldValidationRule rule,
        object fieldValue,
        object? dependencyFieldValue,
        Dictionary<string, string> placeholders);
    
    Task<ValidationResultDto> ValidateConditionalRequiredAsync(
        FieldValidationRule rule,
        object fieldValue,
        object? dependencyFieldValue,
        Dictionary<string, string> placeholders);
}
```

**File**: `Services/Interfaces/IFieldValidationService.cs` (new or update)

**Effort**: 15 minutes

---

#### 2.4 Implement FieldValidationService
Create `Services/FieldValidationService.cs`:

- [ ] Inject `IPlaceholderResolutionService` dependency
- [ ] Inject `ILogger<FieldValidationService>` for logging
- [ ] Inject validation-specific services (e.g., IRegionService for WorldGuard checks)
  
- [ ] Implement `ValidateFieldAsync`:
  - Build PlaceholderResolutionRequest from parameters
  - Call `_placeholderService.ResolveAllLayersAsync()`
  - Get resolved placeholders dictionary
  - Determine validation type from rule.ValidationType
  - Dispatch to type-specific validation method:
    - "LocationInsideRegion" → ValidateLocationInsideRegionAsync
    - "RegionContainment" → ValidateRegionContainmentAsync
    - "ConditionalRequired" → ValidateConditionalRequiredAsync
  - Return ValidationResultDto with:
    - Message template (unreplaced)
    - Placeholders dictionary
    - IsValid flag
    - IsBlocking from rule
  
- [ ] Implement `ResolvePlaceholdersForRuleAsync`:
  - Extract placeholders from rule.ErrorMessage and rule.SuccessMessage
  - Build PlaceholderResolutionRequest
  - Call `_placeholderService.ResolveAllLayersAsync()`
  - Return response
  
- [ ] Implement `ValidateLocationInsideRegionAsync`:
  - Parse ConfigJson for regionPropertyPath
  - Extract region ID from dependencyFieldValue using property path
  - Parse fieldValue as Location coordinates
  - Call IRegionService to check if coordinates inside region
  - Add computed placeholders:
    - `{coordinates}` → Format as "(X, Y, Z)"
    - `{regionName}` → From region ID
  - Merge with existing placeholders
  - Return ValidationResultDto
  
- [ ] Implement `ValidateRegionContainmentAsync`:
  - (Placeholder implementation for now)
  - Parse ConfigJson for parentRegionPath
  - Check child region fully contained in parent
  - Add computed placeholders:
    - `{violationCount}` → Number of out-of-bounds points
  - Return ValidationResultDto
  
- [ ] Implement `ValidateConditionalRequiredAsync`:
  - Parse ConfigJson for condition (operator, value)
  - Evaluate dependency field value against condition
  - If condition met and field empty → validation fails
  - Return ValidationResultDto
  
- [ ] Add error handling:
  - Catch exceptions from validation logic
  - Log errors with context (rule ID, field value)
  - Return "fail-open" result (validation skipped) vs "fail-closed" (block)

**File**: `Services/FieldValidationService.cs` (new)

**Effort**: 3-4 hours

---

#### 2.5 Register Services in DI Container
Update `DependencyInjection/ServiceCollectionExtensions.cs`:

- [ ] Add `services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>();`
- [ ] Add `services.AddScoped<IFieldValidationService, FieldValidationService>();`
- [ ] Verify dependencies are registered (IDbContext, ILogger, etc.)

**File**: `DependencyInjection/ServiceCollectionExtensions.cs`

**Effort**: 5 minutes

---

### Phase 2 Summary
- **Total Effort**: ~8-9 hours
- **Risk**: High (complex business logic with reflection, dynamic queries)
- **Deliverables**: PlaceholderResolutionService, FieldValidationService, DI registration
- **Testing**: Critical to unit test each layer independently

---

## Phase 3: Backend API (Controllers & Endpoints)

### Priority: HIGH - Exposes functionality to frontend and plugin

#### 3.1 Create FieldValidationController (or extend existing)
Check if `Controllers/FieldValidationRulesController.cs` exists and extend, or create new `Controllers/FieldValidationController.cs`:

- [ ] Add `POST /api/field-validations/resolve-placeholders`:
  - Request: `PlaceholderResolutionRequest`
  - Response: `200 OK` with `PlaceholderResolutionResponse`
  - Errors:
    - `400 Bad Request` - Invalid request (no rule ID or placeholder paths)
    - `404 Not Found` - Rule not found (if FieldValidationRuleId provided)
  - Call `_placeholderService.ResolveAllLayersAsync(request)`
  - Return response
  
- [ ] Add `POST /api/field-validations/validate-field`:
  - Request:
    ```json
    {
      "fieldValidationRuleId": 3,
      "fieldValue": { "x": 100, "y": 64, "z": -200 },
      "dependencyFieldValue": "town_springfield",
      "currentEntityPlaceholders": { "Name": "York" },
      "entityId": null
    }
    ```
  - Response: `200 OK` with `ValidationResultDto`
  - Errors:
    - `400 Bad Request` - Invalid request
    - `404 Not Found` - Rule not found
  - Fetch rule from repository
  - Call `_validationService.ValidateFieldAsync()`
  - Return ValidationResultDto
  
- [ ] Add `GET /api/field-validations/rules/{ruleId}/placeholders`:
  - Response: `200 OK` with list of placeholder paths in rule's ErrorMessage/SuccessMessage
  - Errors:
    - `404 Not Found` - Rule not found
  - Fetch rule from repository
  - Call `_placeholderService.ExtractPlaceholdersAsync(rule.ErrorMessage)`
  - Return list

**File**: `Controllers/FieldValidationController.cs` (new or extend existing)

**Effort**: 2 hours

---

#### 3.2 Add Swagger Documentation
Update controller methods with XML comments:

- [ ] Add `<summary>` for each endpoint
- [ ] Add `<remarks>` with examples of placeholder syntax
- [ ] Add `<param>` documentation for request bodies
- [ ] Add `<response>` documentation for status codes
- [ ] Include example requests/responses in Swagger UI

**File**: `Controllers/FieldValidationController.cs`

**Effort**: 30 minutes

---

### Phase 3 Summary
- **Total Effort**: ~2.5 hours
- **Risk**: Low (straightforward API layer)
- **Dependencies**: Phase 2 (services must exist)
- **Deliverables**: 3 new API endpoints, Swagger documentation

---

## Phase 4: Frontend Foundation (Utilities & DTOs)

### Priority: HIGH - Needed for FormWizard integration

#### 4.1 Create TypeScript DTOs
Create `src/types/dtos/forms/PlaceholderResolutionDtos.ts`:

- [ ] Create `PlaceholderResolutionRequest` interface:
  - `fieldValidationRuleId?: number`
  - `entityTypeName?: string`
  - `entityId?: number | null`
  - `placeholderPaths?: string[]`
  - `currentEntityPlaceholders?: Record<string, string>`
  
- [ ] Create `PlaceholderResolutionResponse` interface:
  - `resolvedPlaceholders: Record<string, string>`
  - `unresolvedPlaceholders: string[]`
  - `resolutionErrors: PlaceholderResolutionError[]`
  
- [ ] Create `PlaceholderResolutionError` interface:
  - `placeholderPath: string`
  - `errorCode: string`
  - `errorMessage: string`
  - `stackTrace?: string`
  
- [ ] Update `ValidationResultDto` interface (if not exists):
  - `isValid: boolean`
  - `message: string`
  - `placeholders: Record<string, string>`
  - `isBlocking: boolean`
  - `successMessage?: string`

**File**: `src/types/dtos/forms/PlaceholderResolutionDtos.ts` (new)

**Effort**: 30 minutes

---

#### 4.2 Create Placeholder Interpolation Utility
Create `src/utils/placeholderInterpolation.ts`:

- [ ] Create `interpolatePlaceholders` function:
  ```typescript
  export const interpolatePlaceholders = (
    message: string | undefined,
    placeholders?: { [key: string]: string }
  ): string => {
    if (!message) return '';
    if (!placeholders) return message;
    
    let result = message;
    Object.entries(placeholders).forEach(([key, value]) => {
      result = result.replace(new RegExp(`\\{${key}\\}`, 'g'), value || '');
    });
    return result;
  };
  ```
- [ ] Add unit tests for edge cases:
  - No placeholders → return message as-is
  - Undefined message → return empty string
  - Multiple occurrences of same placeholder → replace all
  - Placeholder not in dictionary → remain unreplaced
  
- [ ] Export function

**File**: `src/utils/placeholderInterpolation.ts` (new)

**Effort**: 30 minutes

---

#### 4.3 Create Placeholder Extraction Utility
Create `src/utils/placeholderExtraction.ts`:

- [ ] Create `extractPlaceholders` function:
  ```typescript
  export const extractPlaceholders = (messageTemplate: string): string[] => {
    const regex = /\{([^}]+)\}/g;
    const matches: string[] = [];
    let match;
    while ((match = regex.exec(messageTemplate)) !== null) {
      matches.push(match[1]);
    }
    return matches;
  };
  ```
  
- [ ] Create `buildPlaceholderContext` function:
  ```typescript
  export const buildPlaceholderContext = (
    config: FormConfigurationDto,
    allStepsData: AllStepsData
  ): Record<string, string> => {
    const placeholders: Record<string, string> = {};
    
    config.steps.forEach((step, stepIndex) => {
      step.fields.forEach(field => {
        const value = allStepsData[stepIndex]?.[field.fieldName];
        if (value !== null && value !== undefined) {
          placeholders[field.fieldName] = String(value);
        }
      });
    });
    
    return placeholders;
  };
  ```
  
- [ ] Add TypeScript types for parameters
- [ ] Add JSDoc comments
- [ ] Export functions

**File**: `src/utils/placeholderExtraction.ts` (new)

**Effort**: 45 minutes

---

#### 4.4 Create Validation API Client
Create `src/apiClients/fieldValidationClient.ts`:

- [ ] Create client class or functions:
  ```typescript
  export const fieldValidationApi = {
    resolvePlaceholders: async (
      request: PlaceholderResolutionRequest
    ): Promise<PlaceholderResolutionResponse> => {
      const response = await fetch('/api/field-validations/resolve-placeholders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request)
      });
      if (!response.ok) throw new Error('Failed to resolve placeholders');
      return response.json();
    },
    
    validateField: async (request: {
      fieldValidationRuleId: number;
      fieldValue: unknown;
      dependencyFieldValue?: unknown;
      currentEntityPlaceholders?: Record<string, string>;
      entityId?: number | null;
    }): Promise<ValidationResultDto> => {
      const response = await fetch('/api/field-validations/validate-field', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request)
      });
      if (!response.ok) throw new Error('Validation request failed');
      return response.json();
    }
  };
  ```
  
- [ ] Add error handling
- [ ] Add TypeScript types
- [ ] Export client

**File**: `src/apiClients/fieldValidationClient.ts` (new)

**Effort**: 45 minutes

---

### Phase 4 Summary
- **Total Effort**: ~2.5 hours
- **Risk**: Low (straightforward utilities and API client)
- **Deliverables**: TypeScript DTOs, interpolation utility, extraction utility, API client
- **Dependencies**: None (can be developed in parallel with backend)

---

## Phase 5: Frontend Integration (FormWizard & FieldRenderer)

### Priority: HIGH - Core user-facing functionality

#### 5.1 Update FormWizard - Placeholder Extraction
Update `src/components/FormWizard/FormWizard.tsx`:

- [ ] Import utilities:
  - `buildPlaceholderContext` from placeholderExtraction
  - `fieldValidationApi` from fieldValidationClient
  
- [ ] Update `triggerFieldValidation` method:
  - Extract Layer 0 placeholders: `const currentEntityPlaceholders = buildPlaceholderContext(config, allStepsData);`
  - Check if field has validation rules
  - For each rule, call validation API:
    ```typescript
    const result = await fieldValidationApi.validateField({
      fieldValidationRuleId: rule.id,
      fieldValue: fieldValue,
      dependencyFieldValue: formContext[rule.dependsOnFieldId],
      currentEntityPlaceholders: currentEntityPlaceholders,
      entityId: entityId || null
    });
    ```
  - Store result in validation state: `setValidationResults(prev => ({ ...prev, [field.id]: result }))`
  - Handle errors: log and display generic error message
  
- [ ] Add debouncing (300ms) to avoid excessive API calls
- [ ] Update validation loading state management

**File**: `src/components/FormWizard/FormWizard.tsx`

**Effort**: 2 hours

---

#### 5.2 Update FormWizard - WorldTask Integration
Update `src/components/FormWizard/FormWizard.tsx`:

- [ ] Add `handleStartWorldTask` method:
  - Check if field has validation rules
  - If yes, pre-resolve all placeholders:
    ```typescript
    const layer0 = buildPlaceholderContext(config, allStepsData);
    const rule = findValidationRuleForField(field.id);
    
    const resolution = await fieldValidationApi.resolvePlaceholders({
      fieldValidationRuleId: rule.id,
      entityTypeName: entityName,
      entityId: existingEntityId || null,
      currentEntityPlaceholders: layer0
    });
    
    const allPlaceholders = {
      ...layer0,
      ...resolution.resolvedPlaceholders
    };
    ```
  - Include allPlaceholders in WorldTask InputJson:
    ```typescript
    const worldTask = await worldTasksApi.create({
      fieldName: field.fieldName,
      inputJson: JSON.stringify({
        validationContext: {
          currentEntityPlaceholders: allPlaceholders,
          validationRules: [{
            validationType: rule.validationType,
            errorMessage: rule.errorMessage,
            successMessage: rule.successMessage,
            configJson: rule.configJson,
            dependencyFieldValue: allStepsData[depStepIndex][depField.fieldName],
            isBlocking: rule.isBlocking
          }]
        }
      })
    });
    ```
  - Open WorldTask modal with LinkCode
  
- [ ] Handle resolution errors:
  - Log unresolved placeholders
  - Show warning to user (optional)
  - Proceed with task creation (fail-open)

**File**: `src/components/FormWizard/FormWizard.tsx`

**Effort**: 2 hours

---

#### 5.3 Update FieldRenderer - Interpolation
Update `src/components/FormWizard/FieldRenderer.tsx`:

- [ ] Import `interpolatePlaceholders` utility
- [ ] Update `ValidationFeedback` component:
  - Interpolate message before display:
    ```typescript
    const finalMessage = interpolatePlaceholders(
      validationResult.message,
      validationResult.placeholders
    );
    ```
  - Interpolate success message if present:
    ```typescript
    const successMsg = validationResult.successMessage
      ? interpolatePlaceholders(validationResult.successMessage, validationResult.placeholders)
      : null;
    ```
  - Display final interpolated message to user
  
- [ ] Ensure placeholder keys are case-sensitive matched

**File**: `src/components/FormWizard/FieldRenderer.tsx`

**Effort**: 30 minutes

---

#### 5.4 Update FieldRenderer - Validation Display
Update `src/components/FormWizard/FieldRenderer.tsx`:

- [ ] Verify validation result display logic:
  - ✅ Valid → Green with CheckCircle2 icon
  - ❌ Blocking error → Red with AlertTriangle icon
  - ⚠️ Non-blocking warning → Yellow with Info icon
  - ⏳ Pending → Gray spinner with "Validating..." text
  
- [ ] Handle missing placeholders gracefully:
  - If placeholder not resolved, show with braces: `{UnknownPlaceholder}`
  - Log warning to console
  
- [ ] Add tooltip with technical details (optional):
  - Show raw message template
  - Show placeholder dictionary
  - Show resolution errors (if any)

**File**: `src/components/FormWizard/FieldRenderer.tsx`

**Effort**: 1 hour

---

### Phase 5 Summary
- **Total Effort**: ~5.5 hours
- **Risk**: Medium (integration complexity, state management)
- **Dependencies**: Phase 3 (API must exist), Phase 4 (utilities must exist)
- **Deliverables**: FormWizard with placeholder resolution, FieldRenderer with interpolation

---

## Phase 6: Minecraft Plugin Updates

### Priority: MEDIUM - Plugin already has partial implementation

#### 6.1 Update LocationTaskHandler - Interpolation
Update `LocationTaskHandler.java`:

- [ ] Review existing `validateLocationInsideRegion` method
- [ ] Update placeholder interpolation logic:
  ```java
  // Get pre-resolved placeholders from InputJson
  JsonObject currentEntityPlaceholders = validationContext
      .getAsJsonObject("currentEntityPlaceholders");
  
  // Interpolate all pre-resolved placeholders
  for (String key : currentEntityPlaceholders.keySet()) {
      String value = currentEntityPlaceholders.get(key).getAsString();
      errorMsg = errorMsg.replace("{" + key + "}", value);
  }
  
  // Interpolate computed placeholders (plugin-only)
  errorMsg = errorMsg.replace("{coordinates}", 
      String.format("(%.2f, %.2f, %.2f)", location.getX(), location.getY(), location.getZ()));
  ```
  
- [ ] Update success message interpolation similarly
- [ ] Test with various placeholder combinations:
  - Layer 0: `{Name}`
  - Layer 1: `{Town.Name}`
  - Computed: `{coordinates}`

**File**: `knk-plugin-v2/knk-paper/src/main/java/.../tasks/LocationTaskHandler.java`

**Effort**: 1 hour

---

#### 6.2 Update WgRegionIdTaskHandler - Interpolation
Update `WgRegionIdTaskHandler.java` (if exists):

- [ ] Apply same interpolation pattern as LocationTaskHandler
- [ ] Handle region-specific placeholders:
  - `{regionName}` - Current region being created
  - `{parentRegionName}` - Parent region (from dependency)
  
- [ ] Test validation with pre-resolved placeholders

**File**: `knk-plugin-v2/knk-paper/src/main/java/.../tasks/WgRegionIdTaskHandler.java`

**Effort**: 1 hour

---

#### 6.3 Add Placeholder Interpolation Utility
Create `PlaceholderInterpolationUtil.java`:

- [ ] Create static utility class:
  ```java
  public class PlaceholderInterpolationUtil {
      public static String interpolate(
          String message,
          JsonObject placeholders) {
          
          String result = message;
          for (String key : placeholders.keySet()) {
              String value = placeholders.get(key).getAsString();
              result = result.replace("{" + key + "}", value);
          }
          return result;
      }
  }
  ```
  
- [ ] Add null/empty checks
- [ ] Add logging for unresolved placeholders (debug mode)
- [ ] Use in both LocationTaskHandler and WgRegionIdTaskHandler

**File**: `knk-plugin-v2/knk-paper/src/main/java/.../util/PlaceholderInterpolationUtil.java` (new)

**Effort**: 30 minutes

---

### Phase 6 Summary
- **Total Effort**: ~2.5 hours
- **Risk**: Low (plugin already has partial implementation)
- **Dependencies**: Frontend must create WorldTasks with pre-resolved placeholders
- **Deliverables**: Updated task handlers, interpolation utility

---

## Phase 7: Testing

### Priority: CRITICAL - Ensures reliability across all layers

#### 7.1 Backend Unit Tests - PlaceholderResolutionService
Create `Tests/Services/PlaceholderResolutionServiceTests.cs`:

- [ ] Test `ExtractPlaceholdersAsync`:
  - Message with no placeholders → returns empty list
  - Message with single placeholder → returns one item
  - Message with multiple placeholders → returns all
  - Malformed placeholders → ignores or handles gracefully
  
- [ ] Test `ResolveLayer0Async`:
  - Valid dictionary → returns as-is
  - Empty dictionary → returns empty
  - Null input → handles gracefully
  
- [ ] Test `ResolveLayer1Async`:
  - Valid single navigation → resolves correctly
  - Multiple navigations → resolves all
  - Navigation property not found → returns error
  - Foreign key null → returns error
  - Related entity not found → returns error
  
- [ ] Test `ResolveLayer2Async`:
  - Valid multi-level navigation → resolves correctly
  - Broken navigation chain → returns error
  - Null intermediate value → returns error
  
- [ ] Test `ResolveLayer3Async`:
  - Count operation on collection → returns count
  - Count on empty collection → returns 0
  - First on collection → returns first element
  - First on empty collection → returns error
  
- [ ] Test `InterpolatePlaceholders`:
  - All placeholders resolved → fully interpolated message
  - Some placeholders missing → partial interpolation
  - No placeholders → returns message as-is

**File**: `Tests/Services/PlaceholderResolutionServiceTests.cs` (new)

**Effort**: 3 hours

---

#### 7.2 Backend Unit Tests - FieldValidationService
Create `Tests/Services/FieldValidationServiceTests.cs`:

- [ ] Test `ValidateFieldAsync`:
  - Valid location inside region → isValid = true
  - Location outside region → isValid = false
  - Missing dependency value → validation skipped
  
- [ ] Test `ResolvePlaceholdersForRuleAsync`:
  - Rule with placeholders → resolves all layers
  - Rule with no placeholders → returns empty
  
- [ ] Test `ValidateLocationInsideRegionAsync`:
  - Computed placeholders included → `{coordinates}` present
  - Navigation placeholders included → `{Town.Name}` present
  
- [ ] Mock IPlaceholderResolutionService for isolated testing

**File**: `Tests/Services/FieldValidationServiceTests.cs` (new)

**Effort**: 2 hours

---

#### 7.3 Backend Integration Tests - API Endpoints
Create `Tests/Integration/FieldValidationApiTests.cs`:

- [ ] Test `POST /api/field-validations/resolve-placeholders`:
  - Layer 0 only → resolves from request
  - Layer 1 navigation → queries DB and resolves
  - Layer 2 multi-nav → resolves with Include chains
  - Invalid entity type → returns error
  
- [ ] Test `POST /api/field-validations/validate-field`:
  - Valid field value → returns ValidationResultDto with placeholders
  - Invalid field value → returns isValid = false
  - Missing rule → returns 404
  
- [ ] Use in-memory database for testing
- [ ] Seed test data: District with Town relation

**File**: `Tests/Integration/FieldValidationApiTests.cs` (new)

**Effort**: 3 hours

---

#### 7.4 Frontend Unit Tests - Utilities
Create `src/utils/__tests__/placeholderInterpolation.test.ts`:

- [ ] Test `interpolatePlaceholders`:
  - All keys present → fully replaced
  - Some keys missing → partial replacement
  - No placeholders in message → returns message
  - Undefined message → returns empty string
  
- [ ] Test multiple occurrences of same placeholder → all replaced

**File**: `src/utils/__tests__/placeholderInterpolation.test.ts` (new)

Create `src/utils/__tests__/placeholderExtraction.test.ts`:

- [ ] Test `extractPlaceholders`:
  - Message with placeholders → extracts all
  - Message without placeholders → returns empty
  
- [ ] Test `buildPlaceholderContext`:
  - Multi-step form → extracts all fields
  - Missing step data → skips gracefully
  - Null/undefined values → skips those fields

**File**: `src/utils/__tests__/placeholderExtraction.test.ts` (new)

**Effort**: 2 hours

---

#### 7.5 Frontend Integration Tests - FormWizard
Create `src/components/FormWizard/__tests__/FormWizard.placeholder.test.tsx`:

- [ ] Test validation trigger with placeholders:
  - Field change → calls validation API with Layer 0 placeholders
  - Validation result → displays interpolated message
  
- [ ] Test WorldTask creation with pre-resolution:
  - Start task → calls resolvePlaceholders API
  - InputJson includes all resolved placeholders
  
- [ ] Mock API responses
- [ ] Use React Testing Library

**File**: `src/components/FormWizard/__tests__/FormWizard.placeholder.test.tsx` (new)

**Effort**: 3 hours

---

#### 7.6 End-to-End Test - Complete Flow
Create manual test scenario:

- [ ] Create District entity with validation rule:
  - ErrorMessage: "Location is outside {Name}'s boundaries. Please select a location within the region."
  - DependsOnFieldId: WgRegionId
  
- [ ] Fill District form:
  - Name: "York"
  - Town: Select existing town "Springfield"
  - Location: Capture via WorldTask
  
- [ ] Verify:
  - FormWizard extracts `{Name}` → "York" (Layer 0)
  - FormWizard calls resolvePlaceholders → `{Town.Name}` → "Springfield" (Layer 1)
  - WorldTask InputJson includes both placeholders
  - Plugin interpolates message correctly
  - Player sees: "Location is outside York's boundaries..."
  
- [ ] Test both success and failure paths

**Effort**: 2 hours (manual testing + documentation)

---

### Phase 7 Summary
- **Total Effort**: ~15 hours
- **Risk**: Medium (comprehensive testing across all layers)
- **Dependencies**: All previous phases must be complete
- **Deliverables**: 
  - 25+ backend unit tests
  - 15+ frontend unit tests
  - 10+ integration tests
  - E2E test documentation

---

## Phase 8: Documentation & Polish

### Priority: MEDIUM

#### 8.1 Update API Documentation
Update Swagger/OpenAPI specs:

- [ ] Document placeholder syntax in API comments
- [ ] Add examples for each layer:
  - Layer 0: `{Name}`
  - Layer 1: `{Town.Name}`
  - Layer 2: `{District.Town.Name}`
  - Layer 3: `{Town.Districts.Count}`
  
- [ ] Document error codes and resolution errors
- [ ] Add response examples with resolved placeholders

**Files**: `Controllers/FieldValidationController.cs` (XML comments)

**Effort**: 1 hour

---

#### 8.2 Create Developer Guide
Create `docs/specs/form-validation/placeholder-interpolation/DEVELOPER_GUIDE.md`:

- [ ] Explain placeholder syntax and layers
- [ ] Provide code examples for each layer
- [ ] Document how to add new validation types with placeholders
- [ ] Include troubleshooting section for common issues:
  - Placeholder not resolving
  - Navigation chain broken
  - Performance issues with deep navigation
  
- [ ] Add decision tree for choosing placeholder layer

**File**: `docs/specs/form-validation/placeholder-interpolation/DEVELOPER_GUIDE.md` (new)

**Effort**: 2 hours

---

#### 8.3 Update Form Validation Documentation
Update `docs/specs/form-validation/README.md`:

- [ ] Add section on placeholder interpolation
- [ ] Link to PLACEHOLDER_INTERPOLATION_STRATEGY.md
- [ ] Update quick reference with placeholder examples
- [ ] Add to implementation status table

**File**: `docs/specs/form-validation/README.md`

**Effort**: 30 minutes

---

#### 8.4 Create Admin Guide
Create `docs/specs/form-validation/placeholder-interpolation/ADMIN_GUIDE.md`:

- [ ] Explain how to use placeholders in error messages
- [ ] Provide examples for common scenarios:
  - District location validation
  - Structure location validation
  - Region containment
  
- [ ] Document placeholder naming conventions
- [ ] Add best practices:
  - Keep messages concise
  - Use meaningful placeholder names
  - Test with real data
  
- [ ] Include FAQ section

**File**: `docs/specs/form-validation/placeholder-interpolation/ADMIN_GUIDE.md` (new)

**Effort**: 1.5 hours

---

### Phase 8 Summary
- **Total Effort**: ~5 hours
- **Risk**: Low
- **Deliverables**: Updated API docs, developer guide, admin guide, updated README

---

## Implementation Priority Matrix

| Phase | Component | Duration | Risk | Blocker | Status |
|-------|-----------|----------|------|---------|--------|
| 1 | Backend Foundation | 2h | Low | None | Not Started |
| 2 | Backend Services | 8-9h | High | Phase 1 | Not Started |
| 3 | Backend API | 2.5h | Low | Phase 2 | Not Started |
| 4 | Frontend Foundation | 2.5h | Low | None (parallel) | Not Started |
| 5 | Frontend Integration | 5.5h | Med | Phase 3-4 | Not Started |
| 6 | Plugin Updates | 2.5h | Low | Phase 5 | Not Started |
| 7 | Testing | 15h | Med | Phase 1-6 | Not Started |
| 8 | Documentation | 5h | Low | Phase 1-7 | Not Started |

**Total Estimated Effort**: ~43 hours (development + testing + documentation)

**Recommended Timeline**: 
- **Week 1**: Phases 1-2 (Backend foundation + services) - 10 hours
- **Week 2**: Phases 3-4 (Backend API + Frontend foundation) - 5 hours
- **Week 3**: Phase 5-6 (Frontend integration + Plugin) - 8 hours
- **Week 4**: Phase 7 (Comprehensive testing) - 15 hours
- **Week 5**: Phase 8 (Documentation + polish) - 5 hours

---

## Critical Dependencies

### External Dependencies
- ✅ Entity Framework Core (for dynamic queries and Include chains)
- ✅ System.Reflection (for property navigation)
- ✅ JSON parsing libraries (System.Text.Json or Newtonsoft.Json)

### Internal Dependencies
- ✅ FormConfiguration system (already exists)
- ✅ FieldValidationRule entity (already exists)
- ✅ FormWizard component (already exists)
- ✅ WorldTask feature (already exists)
- ⚠️ IRegionService (for WorldGuard integration) - may need implementation

### Database Schema
- ✅ No new tables required
- ✅ No migrations required
- ✅ Existing FieldValidationRules table supports placeholder templates

---

## Risk Mitigation

| Risk | Mitigation Strategy |
|------|---------------------|
| **Reflection Performance** | Cache PropertyInfo objects, limit navigation depth to 3 |
| **Database Query N+1** | Use Include() eagerly, batch queries where possible |
| **Placeholder Resolution Failure** | Fail-open design (validation skips on error), log warnings |
| **Frontend API Call Overhead** | Debounce validation triggers (300ms), cache resolution results |
| **Plugin InputJson Size** | Limit pre-resolved placeholders to used ones only |
| **Circular Navigation References** | Detect and reject circular paths during parsing |
| **Type Safety in Reflection** | Validate property types before casting, handle null gracefully |

---

## Performance Considerations

### Backend Optimization
- [ ] Implement caching for placeholder resolution (per entity type + ID)
- [ ] Use `AsNoTracking()` for read-only queries
- [ ] Batch Include() paths to minimize roundtrips
- [ ] Add query timeout protection (5 seconds max)
- [ ] Monitor slow queries via logging

### Frontend Optimization
- [ ] Debounce validation API calls (300ms)
- [ ] Cache resolution results during form session
- [ ] Avoid re-resolving unchanged fields
- [ ] Show loading indicator during resolution

### Plugin Optimization
- [ ] Pre-resolve all placeholders in FormWizard (avoid plugin API calls)
- [ ] Use simple string replacement (no regex)
- [ ] Log interpolation errors to server logs only

---

## Testing Checklist

### Unit Tests
- [ ] PlaceholderPath parser (edge cases, malformed input)
- [ ] PlaceholderResolutionService (all 4 layers independently)
- [ ] FieldValidationService (validation logic + placeholder integration)
- [ ] Frontend utilities (interpolation, extraction)

### Integration Tests
- [ ] API endpoints (request/response contracts)
- [ ] Database queries (Include chains, navigation)
- [ ] FormWizard validation flow (end-to-end)

### Manual/E2E Tests
- [ ] Create District with validation rule
- [ ] Verify placeholder resolution in all layers
- [ ] Test WorldTask flow with pre-resolved placeholders
- [ ] Verify plugin displays interpolated messages
- [ ] Test error handling (missing placeholders, broken navigation)

---

## Rollout Strategy

### Phase 1: Backend-Only Release
- Deploy PlaceholderResolutionService and API endpoints
- No frontend changes yet
- Test via Postman/API client
- Monitor performance and logs

### Phase 2: Frontend Integration
- Deploy FormWizard placeholder extraction
- Deploy FieldRenderer interpolation
- Test with existing validation rules (no placeholders)
- Gradually add placeholders to error messages

### Phase 3: Plugin Update
- Deploy plugin interpolation logic
- Test WorldTask flow with pre-resolved placeholders
- Monitor player experience in-game

### Phase 4: Full Feature Activation
- Update all validation rules with placeholder templates
- Enable for all form configurations
- Monitor error rates and performance
- Collect user feedback

---

## Success Criteria

### Functional Requirements
- ✅ Layer 0 placeholders resolve from form data
- ✅ Layer 1 placeholders resolve via single DB query
- ✅ Layer 2 placeholders resolve via dynamic Include chains
- ✅ Layer 3 aggregates resolve correctly (Count, First, Last)
- ✅ Frontend displays interpolated messages in FieldRenderer
- ✅ Plugin displays interpolated messages in Minecraft chat
- ✅ WorldTask InputJson includes pre-resolved placeholders

### Non-Functional Requirements
- ✅ Placeholder resolution completes within 500ms (95th percentile)
- ✅ No N+1 query issues (max 2 queries per validation)
- ✅ Frontend validation debouncing reduces API calls by 80%
- ✅ Plugin interpolation has zero API calls (all pre-resolved)
- ✅ 95%+ test coverage for placeholder logic

### User Experience
- ✅ Error messages are contextual and helpful
- ✅ Placeholders resolve without user interaction
- ✅ Validation feedback is instant (< 1 second)
- ✅ Plugin messages are readable and formatted correctly

---

## Component Reuse Checklist

To comply with the "Global Design Principles" section above, this checklist identifies existing components that should be **extended** rather than recreated. Each phase should reference these components before implementing new ones.

### Backend Services to Reuse/Extend

| Component | Location | How to Extend | Phase |
|-----------|----------|---------------|-------|
| **IFieldValidationService** | `Services/Interfaces/IFieldValidationService.cs` | Add `ResolvePlaceholdersForRuleAsync` method | Phase 2 |
| **FieldValidationService** | `Services/FieldValidationService.cs` | Implement placeholder resolution in `ValidateFieldAsync`, add layer-specific methods | Phase 2 |
| **IRepository<FieldValidationRule>** | `Repositories/Interfaces/IGenericRepository.cs` | Use existing generic repo for fetching rules (no changes needed) | Phase 1-2 |
| **AutoMapper IMapper** | `DependencyInjection/ServiceCollectionExtensions.cs` | Register DTOs in existing mapping profiles | Phase 1-3 |
| **DbContext** | `Data/KnightsAndKingsDbContext.cs` | Use existing context for all queries (no schema changes) | Phase 2-3 |
| **ILogger<T>** | Built-in .NET logging | Inject into all new services for debugging | All phases |

### Frontend Utilities to Reuse/Extend

| Component | Location | How to Extend | Phase |
|-----------|----------|---------------|-------|
| **FormWizard component** | `src/components/FormWizard/FormWizard.tsx` | Add placeholder extraction before validation, worldtask integration | Phase 5 |
| **FieldRenderer component** | `src/components/FormWizard/FieldRenderer.tsx` | Add placeholder interpolation before display | Phase 5 |
| **ValidationResultDto** | `src/types/dtos/forms/ValidationResultDtos.ts` | Extend with `placeholders` property | Phase 4 |
| **Existing API client pattern** | `src/apiClients/` (see other clients) | Create `fieldValidationClient.ts` following same pattern | Phase 4 |
| **FormContextType** | `src/context/FormContext.tsx` | Extend with `validationResults` state if not exists | Phase 5 |
| **useFormWizard hook** | `src/hooks/useFormWizard.ts` | Add `handleValidateField` hook for validation trigger | Phase 5 |

### Database & Models (No Changes)

| Component | Status | Notes |
|-----------|--------|-------|
| **FieldValidationRule entity** | ✅ Use as-is | Already has `ErrorMessage`, `SuccessMessage` fields |
| **Domain entity base class** | ✅ Use as-is | No changes needed for placeholder resolution |
| **Navigation properties** | ✅ Use as-is | Reflection handles navigation automatically |

### Plugin Components to Update

| Component | Location | How to Update | Phase |
|-----------|----------|---------------|-------|
| **LocationTaskHandler** | `knk-plugin-v2/knk-paper/src/main/java/.../tasks/LocationTaskHandler.java` | Update interpolation logic in `validateLocationInsideRegion` method | Phase 6 |
| **WgRegionIdTaskHandler** | `knk-plugin-v2/knk-paper/src/main/java/.../tasks/WgRegionIdTaskHandler.java` | Apply same interpolation pattern as LocationTaskHandler | Phase 6 |
| **TaskValidationContext** | `knk-plugin-v2/knk-paper/src/main/java/.../tasks/` | Use to pass pre-resolved placeholders from InputJson | Phase 6 |

### Testing Utilities to Leverage

| Component | Location | How to Use | Phase |
|-----------|----------|-----------|-------|
| **xUnit/Moq** | Project references | Use for backend unit tests | Phase 7 |
| **React Testing Library** | `package.json` | Use for frontend component tests | Phase 7 |
| **InMemoryDatabase** | EF Core testing | Use for integration tests | Phase 7 |
| **Existing test fixtures** | `Tests/` | Follow established patterns for mocking and seeding | Phase 7 |

### Framework & Infrastructure (Already Available)

| Technology | Version | Usage | Notes |
|------------|---------|-------|-------|
| **Entity Framework Core** | Latest | Dynamic Include chains, reflection | No upgrade needed |
| **System.Reflection** | Built-in | Property navigation, metadata extraction | No additions needed |
| **System.Text.Json** | Built-in | JSON parsing for ConfigJson | Use instead of Newtonsoft.Json if possible |
| **TypeScript interfaces** | TypeScript 4.5+ | Type-safe DTOs on frontend | Follow existing patterns |
| **Git/GitHub** | Current repo | Create feature branch, follow conventional commits | See DOCUMENTATION_INDEX.md |

---

## How to Find Reference Implementations

When implementing each phase, **locate a similar existing feature** and use it as your template:

### Backend Example: Finding Service Pattern
1. Open `Services/` directory
2. Look for a service with similar complexity (e.g., `LocationService` for queries)
3. Copy the pattern:
   - Interface in `Services/Interfaces/I<ServiceName>Service.cs`
   - Implementation in `Services/<ServiceName>Service.cs`
   - Dependency injection in `DependencyInjection/ServiceCollectionExtensions.cs`
   - Unit tests in `Tests/Services/<ServiceName>ServiceTests.cs`
4. Adapt for PlaceholderResolutionService

### Frontend Example: Finding Component Pattern
1. Open `src/components/` directory
2. Look at existing form components (e.g., `FormWizard`, `FieldRenderer`)
3. Copy the pattern:
   - Component file with hooks and state management
   - Props interface definition
   - CSS module for styling
   - Unit tests in `__tests__/` subdirectory
4. Adapt for placeholder-related changes

### API Example: Finding Endpoint Pattern
1. Open `Controllers/` directory
2. Look at `FieldValidationRulesController` or similar
3. Copy the pattern:
   - Public async method with HttpPost/HttpGet attribute
   - Parameter binding from body/query
   - Service injection and call
   - Error handling and logging
   - XML summary documentation
4. Add new validation endpoints

---

## Don't Create New Components For

| What | What to Do Instead | Example |
|------|-------------------|---------|
| Generic repository | Use existing `IGenericRepository<T>` | Phase 2: Fetch FieldValidationRule using existing repo |
| DTO mapper | Add mapping in existing `AutoMapper` profile | Phase 1: Register PlaceholderResolutionDtos in existing profiles |
| API client base | Extend existing client pattern | Phase 4: Create fieldValidationClient following existing apiClients |
| Validation utilities | Extend FieldValidationService | Phase 2: Add layer methods to existing service, don't create new |
| Form state management | Use existing FormContext/useFormWizard | Phase 5: Store validation results in existing context |
| Logging infrastructure | Use injected ILogger<T> | All phases: Use existing .NET logging, no custom logger |
| Error handling | Follow existing error patterns | All phases: Return DTOs with error details, no new exception types |

---

## Future Enhancements (Out of Scope for MVP)

- [ ] Support for conditional placeholders: `{if:Town.IsActive}{Town.Name}{else}Inactive Town{endif}`
- [ ] Support for formatting: `{Town.CreatedAt:dd/MM/yyyy}`
- [ ] Support for string operations: `{Name.ToUpper()}`
- [ ] Support for arithmetic: `{Town.Districts.Count + 1}`
- [ ] Admin UI for testing placeholder resolution
- [ ] Placeholder autocomplete in error message editor
- [ ] Validation of circular navigation paths at configuration time
- [ ] Performance monitoring dashboard for resolution times

---

**Document Version**: 1.0  
**Created**: February 8, 2026  
**Status**: Ready for Implementation  
**Total Effort**: ~43 hours
