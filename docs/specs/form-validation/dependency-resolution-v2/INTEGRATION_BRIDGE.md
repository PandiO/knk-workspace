# Integration Bridge: Multi-Layer Dependency Resolution + Placeholder Interpolation

**Purpose:** Show how the two form-validation features work together  
**Audience:** Architects, backend/frontend developers, tech leads  
**Date:** February 9, 2026  
**Status:** Complete blueprint for implementation

---

## Overview: Two Systems, One Mission

The form-validation feature consists of **two complementary subsystems** that work independently but share architectural patterns:

| Subsystem | Purpose | When It Runs | Owners |
|-----------|---------|------|--------|
| **Dependency Resolution** | Resolve field values for validation setup | Form load + field change | Feb 2026 (NEW) |
| **Placeholder Interpolation** | Substitute variables in error messages | Validation execution | Aug 2025 (EXISTING) |

**Key Point:** These are **independent features** that shouldn't interfere with each other, but **share the path navigation logic** via `IPathResolutionService`.

---

## Architecture: One Shared Service

```
┌───────────────────────────────────────────────────────────────────┐
│                   IPathResolutionService (Shared)                 │
│  ├─ ResolvePathAsync()                                            │
│  ├─ ValidatePathAsync()                                           │
│  └─ GetIncludePathsForNavigation()                               │
└───────────────────────────────────────────────────────────────────┘
         △                                              △
         │                                              │
    Uses │                                              │ Uses
         │                                              │
┌─────────────────────────┐                ┌──────────────────────────┐
│  Dependency Resolution  │                │ Placeholder Interpolation│
│  (v2.0 - NEW)          │                │ (Phases 1-7 - EXISTING) │
│                         │                │                          │
│ Service Layer:          │                │ Service Layer:           │
│ PathResolutionService   │                │ PlaceholderResolution... │
│ DependencyResolution... │                │ Service                  │
│                         │                │                          │
│ Validates: "Town.wg..."│                │ Resolves: "{Town.Name}" │
│ Resolves: Field values  │                │ Resolves: Variable values│
└─────────────────────────┘                └──────────────────────────┘
```

---

## Data Flow: Complete Request Lifecycle

### Scenario: User Creates District with Location Validation

**Rule Configuration:**
```json
{
  "validationType": "LocationInsideRegion",
  "dependsOnFieldId": 61,          // Dependency: WgRegionId (Town)
  "dependencyPath": "Town.wgRegionId",  // Single-hop path
  "errorMessage": "Location {coordinates} is outside {townName}'s region.",
  "configJson": { ... }
}
```

### Step 1: Form Load - Dependency Resolution

```
┌─────────────────┐
│  FormWizard     │
│  Component      │
└────────┬────────┘
         │ Load form configuration
         │
         ▼
┌─────────────────────────────────────────────────┐
│ 1. Load validation rules                        │
│    - Find all rules for this form               │
│    - Identify which rules have dependencies     │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ 2. Batch resolve dependencies (optional API)    │
│    POST /api/field-validations/resolve-batch    │
│    {                                             │
│      "rules": [{ id: 123, path: "Town.wg..." }] │
│    }                                             │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ Backend: DependencyResolutionService            │
│                                                 │
│ For each rule:                                  │
│   1. Call _pathResolutionService                │
│      .ResolvePathAsync("Town", "wgRegionId")   │
│   2. Get resolved value from form context       │
│   3. Return in response                         │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ Response: Resolved dependencies                 │
│ {                                               │
│   "123": {                                      │
│     "dependencyFieldValue": "town_1",           │
│     "status": "resolved"                        │
│   }                                             │
│ }                                               │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ Frontend stores │
│ in state        │
└─────────────────┘
```

**Backend Code (Phase 1-2):**
```csharp
public async Task<ResolveDependenciesResponse> ResolveDependenciesAsync(
    ResolveDependenciesRequest request)
{
    var response = new ResolveDependenciesResponse();
    
    foreach (var rule in request.Rules)
    {
        try
        {
            // Use shared service - SAME service placeholder interpolation uses
            var resolvedValue = await _pathResolutionService.ResolvePathAsync(
                entityTypeName: "Town",  // Extracted from dependencyPath
                path: "wgRegionId",      // Extracted from dependencyPath
                currentValue: request.FormContext["Town"]  // From form data
            );
            
            response.ResolvedDependencies[rule.Id] = new {
                value = resolvedValue,
                status = "resolved"
            };
        }
        catch (Exception ex)
        {
            response.ResolvedDependencies[rule.Id] = new {
                status = "error",
                message = ex.Message
            };
        }
    }
    
    return response;
}
```

---

### Step 2: Field Change - Validation Trigger

```
┌──────────────────────────┐
│ User enters Location     │
│ or selects Town          │
└────────┬─────────────────┘
         │ onChange event
         │
         ▼
┌──────────────────────────────────────────────┐
│ FormWizard: triggerFieldValidation()         │
│   - Get validation rules for field           │
│   - Prepare form context                     │
│   - Call backend validation endpoint         │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ POST /api/field-validations/validate         │
│ {                                             │
│   "fieldId": 60,                             │
│   "fieldValue": { x: 100, y: 64, z: -200 },  │
│   "formContext": {                            │
│     "Town": { id: 4, wgRegionId: "town_1" }, │
│     "Location": { ... },                      │
│     ...                                       │
│   }                                           │
│ }                                             │
└────────┬────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Backend: FieldValidationService.ValidateAsync() │
│                                                  │
│ 1. Get validation rules for field 60            │
│ 2. For LocationInsideRegion rule:               │
│    a. Get dependency field value:               │
│       _pathResolutionService.ResolvePathAsync(  │
│         "Town", "wgRegionId"  // Uses "Town"    │
│       ) → "town_1"            // from form ctx  │
│    b. Check if location inside region "town_1" │
│    c. Extract placeholder values:               │
│       - {coordinates}: "(100, 64, -200)"        │
│       - {townName}: "Springfield" (from DB)     │
│       - {regionName}: "town_1"                  │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Return ValidationResultDto                      │
│ {                                                │
│   "isValid": false,                             │
│   "message": "Location {coordinates}...",       │
│   "placeholders": {                             │
│     "coordinates": "(100, 64, -200)",           │
│     "townName": "Springfield",                  │
│     "regionName": "town_1"                      │
│   },                                            │
│   "isBlocking": true                            │
│ }                                                │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ Frontend: FieldRenderer.tsx          │
│                                      │
│ 1. Receive ValidationResultDto       │
│ 2. Call interpolatePlaceholders()    │
│    message + placeholders            │
│    → "Location (100, 64, -200)..."   │
│ 3. Display red error message         │
│ 4. Store in validationResults state  │
└──────────────────────────────────────┘
```

**Backend Code (Phase 2-3):**
```csharp
public async Task<ValidationResultDto> ValidateAsync(
    FieldValidationRule rule,
    object fieldValue,
    Dictionary<string, object> formContext)
{
    var result = new ValidationResultDto
    {
        IsValid = true,
        Message = rule.ErrorMessage,
        Placeholders = new Dictionary<string, string>()
    };
    
    // Step 1: Resolve dependency field value for validation
    if (rule.DependsOnFieldId > 0 && rule.DependencyPath != null)
    {
        var depValue = await _pathResolutionService.ResolvePathAsync(
            entityTypeName: "Town",  // For "Town.wgRegionId"
            path: "wgRegionId",
            currentValue: formContext["Town"]
        );
        
        // Use depValue in validation logic...
    }
    
    // Step 2: Extract placeholder values for error message
    // (Uses SAME service for path navigation)
    var town = formContext["Town"] as Town;
    if (town != null)
    {
        result.Placeholders["townName"] = town.DisplayName;
        
        // For nested paths, use service:
        var parentName = await _pathResolutionService.ResolvePathAsync(
            "Town", "ParentDistrict.Name",  // Placeholder path
            town
        );
        result.Placeholders["parentName"] = parentName?.ToString() ?? "";
    }
    
    // Add coordinates from location value
    var location = fieldValue as Location;
    if (location != null)
    {
        result.Placeholders["coordinates"] = 
            $"({location.X:F1}, {location.Y:F1}, {location.Z:F1})";
    }
    
    return result;
}
```

---

### Step 3: Plugin Receives Task with Validation Context

```
FormWizard → Create WorldTask → Plugin Receives:

{
  "inputJson": {
    "fieldName": "Location",
    "currentValue": { x: 100, y: 64, z: -200 },
    "validationContext": {
      "validationRules": [
        {
          "validationType": "LocationInsideRegion",
          "errorMessage": "Location {coordinates} is outside {townName}...",
          "dependencyFieldValue": {
            "id": 4,
            "name": "Springfield",
            "wgRegionId": "town_1"  // ← Already resolved by backend
          },
          "placeholders": {
            "coordinates": "(100, 64, -200)",
            "townName": "Springfield",
            "regionName": "town_1"
          }
        }
      ]
    }
  }
}
```

**Plugin Code (Unchanged):**
```java
public void validateLocationInsideRegion(WorldTask task, Player player) {
    // Plugin receives already-resolved values
    String errorMsg = rule.get("errorMessage").getAsString();
    
    // Would ideally use pre-resolved placeholders from top-level
    // Optional: Use provided placeholders
    if (task.inputJson.has("placeholders")) {
        Map<String, String> placeholders = 
            task.inputJson.getAsJsonObject("placeholders").asMap();
        
        // Replace all available placeholders
        for (String key : placeholders.keySet()) {
            errorMsg = errorMsg.replace("{" + key + "}", 
                placeholders.get(key));
        }
    }
    
    // For local context (coordinates), do inline replacement
    Location playerLoc = player.getLocation();
    errorMsg = errorMsg.replace("{coordinates}", 
        String.format("(%.1f, %.1f, %.1f)", 
            playerLoc.getX(), playerLoc.getY(), playerLoc.getZ()));
    
    player.sendMessage("§c" + errorMsg);
}
```

---

## Shared Service Definition

### IPathResolutionService Interface

```csharp
public interface IPathResolutionService
{
    /// <summary>
    /// Resolve a path on an entity to get the final value
    /// Used by: Dependency resolution, Placeholder interpolation
    /// </summary>
    Task<object?> ResolvePathAsync(
        string entityTypeName,      // e.g., "Town"
        string path,                // e.g., "wgRegionId", "Parent.Name"
        object? entityInstance      // Current entity value from form context
    );
    
    /// <summary>
    /// Validate that a path is syntactically correct and properties exist
    /// Used by: Both systems for validation
    /// </summary>
    Task<PathValidationResult> ValidatePathAsync(
        string entityTypeName,
        string path
    );
    
    /// <summary>
    /// Get EF Core Include paths needed to fetch all required properties
    /// Used by: Placeholder interpolation for optimization
    /// </summary>
    string[] GetIncludePathsForNavigation(string path);
}

public class PathValidationResult
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
    public string? Suggestion { get; set; }
    public List<string> MissingProperties { get; set; } = new();
}
```

### When Each System Uses the Service

| Operation | Dependency Resolution | Placeholder Interpolation |
|-----------|----------------------|--------------------------|
| **Resolve path** | `ResolvePathAsync()` to get dependency value | `ResolvePathAsync()` to get placeholder value |
| **Validate path** | `ValidatePathAsync()` on rule save | `ValidatePathAsync()` in health checks |
| **Optimize DB** | N/A (single entity) | `GetIncludePathsForNavigation()` for Layer 1-3 |
| **Example** | "Town.wgRegionId" → "town_1" | "Town.Name" → "Springfield" |

---

## Error Handling: Unified Approach

Both systems handle path resolution failures gracefully:

### Dependency Resolution Error
```
Issue: Rule references non-existent property
Response: 400 Bad Request (immediate feedback)
Message: "Property 'invalidProp' not found on entity 'Town'"
Fix: Admin corrects path via PathBuilder dropdown
```

### Placeholder Interpolation Error
```
Issue: Message variable references non-existent property
Response: 200 OK (non-blocking)
Message displays with placeholder unresolved: "Location {townName} is outside..."
Panel shows: "Missing property: 'townName' on 'Town'"
Fix: Admin corrects placeholder in message template
```

---

## Testing Strategy: Unified Test Suite

### Shared Service Tests
```typescript
describe("IPathResolutionService", () => {
  it("resolves single-level paths", async () => {
    const value = await service.ResolvePathAsync("Town", "wgRegionId", town);
    expect(value).toBe("town_1");
  });
  
  it("resolves multi-level paths with Include chains", async () => {
    const includes = service.GetIncludePathsForNavigation("District.Town.Name");
    expect(includes).toEqual(["District", "District.Town"]);
  });
  
  it("detects invalid properties", async () => {
    const result = await service.ValidatePathAsync("Town", "invalidProp");
    expect(result.IsValid).toBe(false);
  });
});
```

### Integration Tests
```csharp
[TestClass]
public class FormValidationIntegrationTests
{
    [TestMethod]
    public async Task DependencyResolutionAndInterpolationSharePathLogic()
    {
        // Create rule: Depends on "Town.wgRegionId"
        var rule = new FieldValidationRule 
        { 
            DependencyPath = "Town.wgRegionId",
            ErrorMessage = "Outside {townName}" 
        };
        
        // Resolve dependency
        var depValue = await _dependencyResolver.ResolveAsync(rule, formContext);
        
        // Resolve placeholder using SAME logic
        var placeholderValue = await _placeholderResolver.ResolveAsync("Town.wgRegionId", formContext);
        
        // Both should resolve identically
        Assert.AreEqual(depValue, placeholderValue);
    }
}
```

---

## Documentation Updates Required

### Files to Update
1. **IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md**
   - Update Phase 1: Create shared IPathResolutionService
   - Update Phase 2: Use service in both systems
   - Add parallelization opportunities

2. **PLACEHOLDER_INTERPOLATION_STRATEGY.md**
   - Add section: "Shared Service Integration (v2 Update)"
   - Show how Phase 2-3 code refactors to use service

3. **Developer Guide** (new file)
   - When to use IPathResolutionService
   - How to extend for future operators
   - Common path resolution patterns

### Files to CREATE (This Bridge)
✅ This document (INTEGRATION_BRIDGE.md)
- Visual architecture
- Complete lifecycle flows
- Code examples
- Testing approach

---

## Timeline Impact

**Original:** 9 weeks (Phases 1-9)  
**With Pre-Completed Placeholder Work:** 6 weeks  
**Impact of Shared Service Design:** +2 days refactoring (net: still 6 weeks)

```
Week 1: Planning + Integration Design (NEW)
        - Create shared IPathResolutionService interface
        - Design error handling
        - Plan refactoring strategy

Week 2-3: Phase 1-2 (Backend)
         - Implement shared service (4 days)
         - Add DependencyPath to entity
         - Both systems operational

Week 3-4: Phase 2 Completion
         - Refactor placeholder interpolation to use service
         - Ensure consistency
         - Comprehensive testing

Week 4-5: Phase 3-6 (Health Checks + UI)
Week 5-6: Phase 7-8 (Integration + Testing)
```

---

## Success Criteria

- ✅ Dependency resolution and placeholder interpolation use identical path navigation
- ✅ Both systems share `IPathResolutionService`
- ✅ No code duplication between systems
- ✅ Path validation happens at both save and panel review (Q2)
- ✅ Plugin receives template messages (Q3)
- ✅ Zero breaking changes to existing placeholder interpolation code
- ✅ All tests pass (unit + integration + E2E)
- ✅ Timeline: 6 weeks

---

## Next Steps

1. ✅ Review this bridge document
2. ⏳ Begin Phase 1 implementation (Week 2)
   - Create IPathResolutionService
   - Add DependencyPath property
   - Implement shared logic
3. ⏳ Phase 2: Use service across both systems
4. ⏳ Full integration testing

---

## Reference Documents

- [ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md) - Q1/Q2/Q3 decisions
- [SPEC_MULTI_LAYER_DEPENDENCIES_v2.md](./SPEC_MULTI_LAYER_DEPENDENCIES_v2.md) - Full specification
- [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md) - Phase breakdown
- [PLACEHOLDER_INTERPOLATION_STRATEGY.md](./placeholder-interpolation/PLACEHOLDER_INTERPOLATION_STRATEGY.md) - Existing system
- [ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md](./ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md) - Alignment details
