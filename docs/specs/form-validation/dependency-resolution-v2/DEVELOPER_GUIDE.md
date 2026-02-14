# Multi-Layer Dependency Resolution v2.0 - Developer Guide

**Version:** 1.0  
**Date:** February 14, 2026  
**Audience:** Backend developers, frontend developers, architects  
**Last Updated:** February 14, 2026

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Services](#core-services)
3. [Backend Integration](#backend-integration)
4. [Frontend Integration](#frontend-integration)
5. [API Reference](#api-reference)
6. [Testing Guide](#testing-guide)
7. [Performance Tuning](#performance-tuning)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)

---

## Architecture Overview

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Form Wizard Component                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ useEnrichedFormContext Hook                            │     │
│  │  • Loads form metadata                                 │     │
│  │  • Manages form context state                          │     │
│  │  • Triggers dependency resolution                      │     │
│  └────────────────────────────────────────────────────────┘     │
│           ↓                                       ↓               │
│  ┌──────────────────┐              ┌─────────────────────────┐  │
│  │ FormFieldRenderer│              │ fieldValidationClient   │  │
│  │ Components       │──────────────→ (API calls)              │  │
│  └──────────────────┘              └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
         ↓
         ↓ HTTP Requests
         ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Backend API Endpoints                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ FieldValidationRulesController                         │     │
│  │  POST /api/field-validations/resolve-dependencies     │     │
│  │  POST /api/field-validations/validate                │     │
│  │  GET /api/field-validations/configuration-health     │     │
│  └───────────────┬────────────────────────────────────────┘     │
│                  ↓                                               │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ DependencyResolutionService                            │     │
│  │  • ResolveDependenciesAsync()                          │     │
│  │  • ValidateFormConfigurationAsync()                    │     │
│  └───────────────┬────────────────────────────────────────┘     │
│                  ↓                                               │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ PathResolutionService (Shared)                         │     │
│  │  • ResolvePathAsync()                                  │     │
│  │  • ValidatePathAsync()                                 │     │
│  │  • GetIncludePathsForNavigation()                      │     │
│  └───────────────┬────────────────────────────────────────┘     │
│                  ↓                                               │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ Repositories & EF Core                                 │     │
│  │  • FieldValidationRuleRepository                       │     │
│  │  • FormFieldRepository                                 │     │
│  │  • Database access                                     │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Responsibility | Location |
|-----------|---|---|
| **IPathResolutionService** | Navigate entity relationships and resolve paths | `/Services/PathResolutionService.cs` |
| **IDependencyResolutionService** | Batch resolve dependencies and validate configurations | `/Services/DependencyResolutionService.cs` |
| **FieldValidationRulesController** | HTTP endpoints for dependency operations | `/Controllers/FieldValidationRulesController.cs` |
| **useEnrichedFormContext** | Frontend hook for form state and dependencies | `/hooks/useEnrichedFormContext.ts` |
| **fieldValidationRuleClient** | Frontend API client | `/apiClients/fieldValidationRuleClient.ts` |

---

## Core Services

### IPathResolutionService

Responsible for navigating entity relationships and extracting values from entities.

```csharp
public interface IPathResolutionService
{
    /// <summary>
    /// Navigate a path on an entity and resolve its value.
    /// </summary>
    /// <param name="entityTypeName">The entity type (e.g., "Town")</param>
    /// <param name="path">The property to navigate (e.g., "wgRegionId")</param>
    /// <param name="currentValue">The current entity instance</param>
    /// <returns>The resolved value or null if not found</returns>
    Task<object?> ResolvePathAsync(
        string entityTypeName,
        string path,
        object? currentValue
    );

    /// <summary>
    /// Validate that a path is syntactically correct and references exist.
    /// </summary>
    Task<PathValidationResult> ValidatePathAsync(
        string entityTypeName,
        string path
    );

    /// <summary>
    /// Get EF Core Include paths needed to load related data.
    /// </summary>
    string[] GetIncludePathsForNavigation(string path);
}
```

**Example Usage:**

```csharp
// Resolve "Town.wgRegionId" given a Town instance
var town = new Town { Id = 1, WgRegionId = "town_1" };
var regionId = await _pathResolutionService.ResolvePathAsync(
    "Town",
    "wgRegionId",
    town
);
// Result: "town_1"
```

### IDependencyResolutionService

Higher-level service for batch resolving dependencies and validating forms.

```csharp
public interface IDependencyResolutionService
{
    /// <summary>
    /// Resolve multiple dependencies in a single request.
    /// </summary>
    Task<DependencyResolutionResponse> ResolveDependenciesAsync(
        DependencyResolutionRequest request,
        Dictionary<string, object> formContext
    );

    /// <summary>
    /// Validate a form's configuration for issues.
    /// </summary>
    Task<FormConfigurationHealthCheckResult> ValidateFormConfigurationAsync(
        int formConfigurationId
    );
}
```

**Example Usage:**

```csharp
var request = new DependencyResolutionRequest
{
    FieldIds = new List<int> { 3, 5, 7 },
    FormConfigurationId = 42
};

var formContext = new Dictionary<string, object>
{
    { "Town", new { Id = 1, WgRegionId = "town_1" } }
};

var response = await _dependencyResolutionService.ResolveDependenciesAsync(
    request,
    formContext
);

foreach (var resolved in response.ResolvedDependencies)
{
    Console.WriteLine($"Rule {resolved.RuleId}: {resolved.Status}");
    if (resolved.Status == "resolved")
    {
        Console.WriteLine($"  Value: {resolved.DependencyFieldValue}");
    }
}
```

---

## Backend Integration

### Setup & Dependency Injection

**In Startup.cs or Program.cs:**

```csharp
services.AddScoped<IPathResolutionService, PathResolutionService>();
services.AddScoped<IDependencyResolutionService, DependencyResolutionService>();

// Also required:
services.AddScoped<IFieldValidationRuleRepository, FieldValidationRuleRepository>();
services.AddScoped<IFormFieldRepository, FormFieldRepository>();
services.AddScoped<IFormConfigurationRepository, FormConfigurationRepository>();
services
    .AddMemoryCache(); // For dependency caching
```

### Using IPathResolutionService in Custom Validators

If you're creating a custom validation method that needs dependencies:

```csharp
public class CustomLocationValidator : IValidationMethod
{
    private readonly IPathResolutionService _pathResolutionService;

    public CustomLocationValidator(IPathResolutionService pathResolutionService)
    {
        _pathResolutionService = pathResolutionService;
    }

    public async Task<ValidationResult> ValidateAsync(
        FieldValidationRule rule,
        object fieldValue,
        Dictionary<string, object> formContext
    )
    {
        // Extract the dependency path from rule
        string dependencyPath = rule.DependencyPath; // e.g., "Town.wgRegionId"

        // Resolve the dependency
        if (!formContext.TryGetValue("Town", out var town))
        {
            return new ValidationResult { IsValid = false, Message = "Town required" };
        }

        var regionId = await _pathResolutionService.ResolvePathAsync(
            "Town",
            "wgRegionId",
            town
        );

        // Use the resolved value in validation
        if (regionId == null)
        {
            return new ValidationResult { IsValid = false, Message = "Region not found" };
        }

        // Validate location is inside region...
        var location = fieldValue as Location;
        bool isInside = CheckLocationInRegion(location, regionId.ToString());

        return new ValidationResult
        {
            IsValid = isInside,
            Message = isInside ? null : $"Location outside region {regionId}"
        };
    }

    private bool CheckLocationInRegion(Location loc, string regionId)
    {
        // Implementation here
        return true;
    }
}
```

### Database Schema Notes

The `FieldValidationRule` entity has a new property:

```csharp
public class FieldValidationRule
{
    // ... existing properties ...

    /// <summary>
    /// The path to navigate from dependency entity to extract value.
    /// Format: Entity.Property (v1 single-hop only)
    /// Example: "Town.wgRegionId"
    /// </summary>
    public string? DependencyPath { get; set; }

    // ... other properties ...
}
```

**Database Column:**
```sql
ALTER TABLE dbo.FieldValidationRules ADD DependencyPath NVARCHAR(500) NULL;
CREATE INDEX IX_FieldValidationRules_DependencyPath 
  ON dbo.FieldValidationRules(FormFieldId, DependencyPath);
```

---

## Frontend Integration

### Setup

**Install dependencies (if needed):**
```bash
npm install
# All required dependencies are already included
```

### Using useEnrichedFormContext Hook

The hook loads form metadata and manages dependency resolution automatically.

```typescript
import { useEnrichedFormContext } from '../hooks/useEnrichedFormContext';
import { FormConfigurationDto } from '../types/dtos';

interface MyFormProps {
  config: FormConfigurationDto;
}

export const MyFormComponent: React.FC<MyFormProps> = ({ config }) => {
  // Hook automatically:
  // 1. Loads form metadata
  // 2. Manages form context state
  // 3. Resolves dependencies
  // 4. Provides entity metadata
  const formContext = useEnrichedFormContext(config);

  const {
    values,           // Current form field values
    errors,           // Validation errors
    loading,          // Loading state
    entityMetadata,   // Entity property information
    resolvedDependencies,  // Resolved dependency values
    setValue,         // Update a field value
    addError,         // Add a validation error
    clearError        // Clear an error
  } = formContext;

  return (
    <div>
      {loading && <p>Loading form...</p>}

      {errors.fieldValidation && (
        <div className="error">
          {errors.fieldValidation.map((err, idx) => (
            <p key={idx}>{err}</p>
          ))}
        </div>
      )}

      {/* Your form fields here */}
    </div>
  );
};
```

### Manual API Calls

If you need more control, use the API client directly:

```typescript
import { fieldValidationRuleClient } from '../apiClients/fieldValidationRuleClient';

// Resolve multiple dependencies
const request: DependencyResolutionRequest = {
  fieldIds: [3, 5, 7],
  formConfigurationId: 42
};

const response = await fieldValidationRuleClient.resolveDependencies(request);

response.resolvedDependencies.forEach(resolved => {
  console.log(`Rule ${resolved.ruleId}: ${resolved.status}`);
  if (resolved.status === 'resolved') {
    console.log(`  Value: ${resolved.dependencyFieldValue}`);
  }
});
```

### Displaying Validation Errors with Resolved Placeholders

Backend returns pre-interpolated error messages:

```typescript
interface FieldValidationResult {
  isValid: boolean;
  message: string;              // Already has placeholders interpolated
  placeholders?: Record<string, string>;  // Original values (for debugging)
  isBlocking: boolean;
}

// In your component:
const [validationResult, setValidationResult] = useState<FieldValidationResult | null>(null);

const handleFieldValidation = async (fieldId: number, fieldValue: any) => {
  const result = await fieldValidationRuleClient.validateField({
    fieldId,
    fieldValue,
    formContext: currentFormState
  });

  setValidationResult(result);

  if (!result.isValid) {
    // Message is already interpolated:
    // "Location (100, 64, -200) is outside Springfield region"
    console.error(result.message);
  }
};
```

---

## API Reference

### POST /api/field-validations/resolve-dependencies

Batch resolve dependencies for multiple fields.

**Request:**
```json
{
  "fieldIds": [1, 2, 3],
  "formConfigurationId": 42
}
```

**Request Body (DTO):**
```csharp
public class DependencyResolutionRequest
{
    public List<int> FieldIds { get; set; }     // Fields to resolve
    public int FormConfigurationId { get; set; } // Form context
}
```

**Response:**
```json
{
  "resolvedDependencies": [
    {
      "ruleId": 1,
      "fieldId": 3,
      "status": "resolved",
      "dependencyFieldValue": "town_1",
      "errorDetail": null
    },
    {
      "ruleId": 2,
      "fieldId": 5,
      "status": "pending",
      "dependencyFieldValue": null,
      "errorDetail": "Dependency field not populated"
    }
  ],
  "hasErrors": false,
  "errorSummary": null
}
```

**Status Codes:**
- `200 OK` - Successful resolution
- `400 Bad Request` - Invalid request
- `404 Not Found` - Configuration not found
- `500 Internal Server Error` - Server error

### POST /api/field-validations/validate

Validate a single field with its dependencies.

**Request:**
```json
{
  "fieldId": 3,
  "fieldValue": { "x": 100, "y": 64, "z": -200 },
  "formContext": {
    "Town": { "id": 1, "wgRegionId": "town_1" }
  }
}
```

**Response:**
```json
{
  "isValid": false,
  "message": "Location (100, 64, -200) is outside town_1 region",
  "placeholders": {
    "coordinates": "(100, 64, -200)",
    "regionName": "town_1"
  },
  "isBlocking": true
}
```

### GET /api/field-validations/configuration-health/{configId}

Get health check results for a form configuration.

**Response:**
```json
{
  "formConfigurationId": 42,
  "isHealthy": true,
  "propertyExistenceIssues": [],
  "fieldOrderingIssues": [],
  "circularDependencyIssues": [],
  "requiredFieldIssues": [],
  "collectionWarnings": []
}
```

---

## Testing Guide

### Unit Testing Paths

```csharp
[TestClass]
public class PathResolutionServiceTests
{
    [TestMethod]
    public async Task ResolvePathAsync_SingleProperty_ReturnsValue()
    {
        // Arrange
        var service = new PathResolutionService(...);
        var town = new Town { Id = 1, WgRegionId = "town_1" };

        // Act
        var result = await service.ResolvePathAsync("Town", "wgRegionId", town);

        // Assert
       Assert.AreEqual("town_1", result);
    }

    [TestMethod]
    public async Task ValidatePathAsync_InvalidProperty_ReturnsError()
    {
        // Arrange
        var service = new PathResolutionService(...);

        // Act
        var result = await service.ValidatePathAsync("Town", "nonExistent");

        // Assert
        Assert.IsFalse(result.IsValid);
        Assert.IsTrue(result.ErrorMessage.Contains("nonExistent"));
    }
}
```

### Integration Testing

```csharp
[TestClass]
public class DependencyResolutionIntegrationTests
{
    [TestMethod]
    public async Task ResolveDependencies_WithNullValue_ReturnsError()
    {
        // Arrange
        var context = new ApplicationDbContext(...);
        var service = new DependencyResolutionService(...);

        var rule = new FieldValidationRule
        {
            Id = 1,
            FormFieldId = 3,
            DependencyPath = "Town.wgRegionId"
        };
        context.FieldValidationRules.Add(rule);
        await context.SaveChangesAsync();

        var formContext = new Dictionary<string, object>
        {
            { "Town", null }  // Null value
        };

        // Act
        var response = await service.ResolveDependenciesAsync(
            new DependencyResolutionRequest { FieldIds = new List<int> { 3 } },
            formContext
        );

        // Assert
        Assert.AreEqual("pending", response.ResolvedDependencies[0].Status);
    }
}
```

### E2E Testing

See `PHASE_8_E2E_TESTS.md` for comprehensive end-to-end test examples.

---

## Performance Tuning

### Caching Strategy

Dependency resolution uses in-memory caching with configurable TTL:

```csharp
// In DependencyResolutionService
private const int CacheTTL_Minutes = 5;

var cacheKey = $"{formConfigId}_{fieldId}_{pathHash}";
if (_memoryCache.TryGetValue(cacheKey, out var cachedValue))
{
    // Return cached value
    return cachedValue;
}

// Otherwise resolve, then cache
var resolved = await ResolveAsync(...);
var cacheOptions = new MemoryCacheEntryOptions
    .SetAbsoluteExpiration(TimeSpan.FromMinutes(CacheTTL_Minutes));
_memoryCache.Set(cacheKey, resolved, cacheOptions);
```

### Optimization Tips

**1. Lazy Load Metadata**
```csharp
// Load metadata only when needed
var metadata = await _metadataService.GetEntityMetadataAsync("Town");
```

**2. Batch Resolutions**
```csharp
// Good: Single batch request with many rules
POST /api/field-validations/resolve-dependencies
{
  "fieldIds": [1, 2, 3, 4, 5]  // Batch resolves all at once
}

// Bad: Multiple individual requests
POST /api/field-validations/resolve-dependencies { "fieldIds": [1] }
POST /api/field-validations/resolve-dependencies { "fieldIds": [2] }
POST /api/field-validations/resolve-dependencies { "fieldIds": [3] }
```

**3. Include Path Optimization**
```csharp
// Use GetIncludePathsForNavigation to inform EF queries
var includePaths = _pathResolutionService.GetIncludePathsForNavigation("Town.wgRegionId");
// Then use in EF: query.Include(includePaths[0])...
```

### Load Test Results

See `PHASE_8_LOAD_TESTING_REPORT.md` for detailed performance metrics.

**Key Numbers:**
- Batch resolution (100 rules): **187ms p95**
- Individual validation: **12ms p95**
- Throughput: **1,240+ req/sec**
- Memory: **<150MB sustained**

---

## Error Handling

### Common Errors & Recovery

| Error | Cause | Recovery |
|-------|-------|----------|
| `PathNotFoundError` | Property doesn't exist on entity | Check path spelling, use metadata API to list properties |
| `EntityNotFoundError` | Entity doesn't exist | Verify entity name, check entity metadata |
| `CircularDependencyError` | Cycle detected (A→B→A) | Remove one dependency |
| `FieldOrderingError` | Dependency comes after dependent | Reorder form steps |

### Error Response Format

```json
{
  "error": "PathNotFoundError",
  "message": "Property 'invalidProp' not found on entity 'Town'",
  "availableProperties": [
    "id",
    "name",
    "wgRegionId",
    "description"
  ],
  "suggestion": "Did you mean 'wgR egionId'?"
}
```

### Handling Errors in Code

```csharp
try
{
    var result = await _pathResolutionService.ResolvePathAsync(
        "Town", 
        "wgRegionId", 
        town
    );
}
catch (PathNotFoundException ex)
{
    _logger.LogError($"Invalid path: {ex.Message}");
    _logger.LogInformation($"Available properties: {string.Join(", ", ex.AvailableProperties)}");
}
catch (Exception ex)
{
    _logger.LogError($"Unexpected error: {ex}");
    // Return user-friendly error message
}
```

---

## Best Practices

### 1. Always Use PathBuilder UI

Don't manually type dependency paths. Use PathBuilder to:
- Avoid typos
- See available properties
- Get instant validation

### 2. Validate Paths on Save

Check paths immediately when a rule is created:

```csharp
[HttpPost("rules")]
public async Task<IActionResult> CreateRule(CreateRuleRequest req)
{
    // Validate path before saving
    var validation = await _pathResolutionService.ValidatePathAsync(
        req.EntityType,
        req.DependencyPath
    );

    if (!validation.IsValid)
    {
        return BadRequest(new
        {
            error = validation.ErrorMessage,
            suggestion = validation.Suggestion
        });
    }

    // Only save if valid
    // ...
}
```

### 3. Use Batch Resolution Strategically

```typescript
// Good: Resolve all dependencies once per form load
const response = await fieldValidationRuleClient.resolveDependencies({
  fieldIds: [1, 2, 3, 4, 5],
  formConfigurationId: 42
});

// Store in state for later use
setResolvedDeps(response.resolvedDependencies);
```

### 4. Handle Pending Dependencies

```typescript
if (resolved.status === "pending") {
  // Show "waiting for input" message
  setFieldError(fieldId, "Waiting for dependency field to be filled");
}
```

### 5. Test Circular Dependencies

```csharp
[TestMethod]
public async Task ValidateConfiguration_WithCircularDeps_ReturnsError()
{
    // Test that circular dependencies are detected
    // ...
}
```

### 6. Cache Invalidation

```csharp
// When a dependency field value changes, invalidate cache
_memoryCache.Remove($"{formConfigId}_{fieldId}_*");  // Pattern-based removal
```

---

## Troubleshooting for Developers

**Issue:** Path resolution always returns null

**Debug Steps:**
```csharp
var logData = new
{
    EntityType = "Town",
    Path = "wgRegionId",
    CurrentValue = town,
    EntityProperties = town?.GetType().GetProperties().Select(p => p.Name)
};
_logger.LogDebug($"Resolving: {JsonConvert.SerializeObject(logData)}");

var result = await _pathResolutionService.ResolvePathAsync("Town", "wgRegionId", town);
_logger.LogDebug($"Result: {result}");
```

**Issue:** Performance degradation after recent changes

**Check:**
1. Enable caching: ` services.AddMemoryCache()`
2. Verify batch requests (not individual calls)
3. Run load tests: `dotnet test --filter "LoadTest"`

---

**Documentation Version:** 1.0  
**Last Updated:** February 14, 2026  
**Next Review:** August 2026
