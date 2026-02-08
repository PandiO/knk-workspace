# Phase 1 Implementation Complete: Backend Placeholder Resolution API

## Summary
Successfully implemented the backend placeholder resolution API for form validation messages. The system supports dynamic placeholder variable resolution across multiple navigation layers.

## Implemented Components

### 1. Service Layer
- **File**: [PlaceholderResolutionService.cs](Repository/knk-web-api-v2/Services/PlaceholderResolutionService.cs)
- **Interface**: [IPlaceholderResolutionService.cs](Repository/knk-web-api-v2/Services/Interfaces/IPlaceholderResolutionService.cs)
- **Functionality**:
  - Layer 0: Direct properties (handled by client)
  - Layer 1: Single navigation (e.g., `Town.Name`) via FK lookups
  - Layer 2: Multi-level navigation (e.g., `District.Town.Name`) via dynamic EF Include chains
  - Layer 3: Aggregates (e.g., `Town.Districts.Count`) via collection operations
- **Technical Approach**: Uses reflection and Expression trees for dynamic type resolution

### 2. DTOs
- **File**: [FieldValidationRuleDtos.cs](Repository/knk-web-api-v2/Dtos/FieldValidationRuleDtos.cs)
- **Added**:
  - `ResolvePlaceholdersRequestDto`:
    - `CurrentEntityType` - Entity type name (e.g., "District")
    - `CurrentEntityId` - Entity ID for database lookup
    - `PlaceholderPaths` - List of paths to resolve (e.g., ["Town.Name", "District.Town.Name"])
    - `CurrentEntityPlaceholders` - Layer 0 placeholders from form data
  - `ResolvePlaceholdersResponseDto`:
    - `ResolvedPlaceholders` - Dictionary of path → value
    - `UnresolvedPlaceholders` - Paths that couldn't be resolved
    - `ResolutionErrors` - Error messages for debugging

### 3. Controller Endpoint
- **File**: [FieldValidationRulesController.cs](Repository/knk-web-api-v2/Controllers/FieldValidationRulesController.cs)
- **Endpoint**: `POST /api/field-validation-rules/resolve-placeholders`
- **Features**:
  - Input validation (entityType and placeholderPaths required)
  - Error handling with descriptive messages
  - Returns 200 OK with ResolvePlaceholdersResponseDto

### 4. Dependency Injection
- **File**: [ServiceCollectionExtensions.cs](Repository/knk-web-api-v2/DependencyInjection/ServiceCollectionExtensions.cs)
- **Registration**: `services.AddScoped<IPlaceholderResolutionService, PlaceholderResolutionService>()`

### 5. Frontend TypeScript
- **File**: [FieldValidationRuleDtos.ts](Repository/knk-web-app/src/types/dtos/forms/FieldValidationRuleDtos.ts)
- **Added**: TypeScript interfaces matching C# DTOs
- **File**: [fieldValidationRuleClient.ts](Repository/knk-web-app/src/apiClients/fieldValidationRuleClient.ts)
- **Added**: `resolvePlaceholders()` method for calling the API

## Build Status
✅ **Backend builds successfully** (verified with `dotnet build`)

## Technical Implementation Details

### Dynamic Entity Resolution
The service uses reflection to resolve entity types at runtime:
```csharp
var dbSetProperties = _dbContext.GetType()
    .GetProperties()
    .Where(p => p.PropertyType.IsGenericType &&
               p.PropertyType.GetGenericTypeDefinition() == typeof(DbSet<>));
```

### Dynamic Query Building
Uses `MakeGenericMethod` to build queries without compile-time type knowledge:
```csharp
var setMethod = typeof(DbContext).GetMethod(nameof(DbContext.Set), Array.Empty<Type>())!
    .MakeGenericMethod(entityType);
var dbSet = setMethod.Invoke(_dbContext, null);
```

### Expression Tree Construction
Builds LINQ expressions dynamically for `FirstOrDefaultAsync`:
```csharp
var parameter = Expression.Parameter(entityType, "e");
var idProperty = Expression.Property(parameter, "Id");
var constant = Expression.Constant(entityId.Value);
var equals = Expression.Equal(idProperty, constant);
var lambda = Expression.Lambda(equals, parameter);
```

## Next Steps (Phases 2-4)

### Phase 2: FormWizard Integration
- Add `buildPlaceholderContext()` helper to extract Layer 0 placeholders from form data
- Extract placeholder paths from validation rule messages using regex
- Call `fieldValidationRuleClient.resolvePlaceholders()` before creating WorldTask
- Merge resolved placeholders into `validationContext.currentEntityPlaceholders`

### Phase 3: WorldTask Creation Integration
- Modify WorldTask creation to include resolved placeholders in `InputJson`
- Update WorldTask input JSON structure with `validationContext.currentEntityPlaceholders`

### Phase 4: Minecraft Plugin Update
- Modify `LocationTaskHandler.validateLocationInsideRegion()` to read `currentEntityPlaceholders` from `InputJson`
- Implement interpolation loop for all pre-resolved placeholders
- Keep existing computed placeholder logic for `{coordinates}`

## API Contract Example

### Request
```json
{
  "currentEntityType": "District",
  "currentEntityId": 42,
  "placeholderPaths": ["Name", "Town.Name", "District.Town.Name"],
  "currentEntityPlaceholders": {
    "Name": "Market District"
  }
}
```

### Response
```json
{
  "resolvedPlaceholders": {
    "Town.Name": "Silverpine",
    "District.Town.Name": "Silverpine"
  },
  "unresolvedPlaceholders": [],
  "resolutionErrors": []
}
```

Note: `"Name"` is not in `resolvedPlaceholders` because it was already provided in `currentEntityPlaceholders` (Layer 0).

## References
- Design Document: [PLACEHOLDER_INTERPOLATION_STRATEGY.md](PLACEHOLDER_INTERPOLATION_STRATEGY.md)
- Implementation Prompt: [placeholder-resolution-implementation-prompt.md](docs/specs/form-validation/implementation-prompts/placeholder-resolution-implementation-prompt.md)
