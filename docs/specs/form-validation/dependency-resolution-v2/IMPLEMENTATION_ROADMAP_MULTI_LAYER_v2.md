# Implementation Roadmap: Multi-Layer Dependency Resolution v2.0

**Document Version:** 1.0  
**Created:** February 9, 2026  
**Timeline:** 9 weeks (estimated)  
**Total Effort:** 60-70 hours

---

## Quick Reference

| Phase | Duration | Focus | Status |
|-------|----------|-------|--------|
| **Phase 1** | Week 1-2 | Backend entities & path resolution | 🔴 Not Started |
| **Phase 2** | Week 2-3 | Dependency resolution API | 🔴 Not Started |
| **Phase 3** | Week 3-4 | Health checks & entity validation | 🔴 Not Started |
| **Phase 4** | Week 4-5 | Frontend data layer (DTOs, hooks) | 🔴 Not Started |
| **Phase 5** | Week 5-6 | PathBuilder component | 🔴 Not Started |
| **Phase 6** | Week 6-7 | UI integration & validation | 🔴 Not Started |
| **Phase 7** | Week 7-8 | WorldTask integration | 🔴 Not Started |
| **Phase 8** | Week 8-9 | Testing & documentation | 🔴 Not Started |
| **Phase 9** | Ongoing | v2 planning (collections) | 🔴 Planned |

---

## Phase 1: Backend Foundation - Entity Model & Path Resolution

**Duration:** 2 weeks  
**Effort:** 8-10 hours  
**Team:** Backend developers (1-2)

### Tasks

#### 1.1 Update FieldValidationRule Entity Model
**Time:** 1 hour

```csharp
// File: Repository/knk-web-api-v2/Models/FormConfiguration/FieldValidationRule.cs

// ADD:
/// <summary>
/// The path to navigate from dependency entity to extract value.
/// Format: Entity.Property (v1 single-hop only)
/// Example: "Town.wgRegionId"
/// </summary>
public string? DependencyPath { get; set; }
```

**Acceptance Criteria:**
- ✅ Property added to entity
- ✅ Nullable (backward compatible)
- ✅ Includes documentation
- ✅ Compiles without errors

---

#### 1.2 Create Database Migration Script
**Time:** 1 hour

```sql
-- File: Repository/knk-web-api-v2/Migrations/[date]_AddDependencyPathToFieldValidationRules.cs

CREATE MIGRATION: AddDependencyPathToFieldValidationRules
  ALTER TABLE dbo.FieldValidationRules
  ADD DependencyPath NVARCHAR(500) NULL;
  
  CREATE INDEX IX_FieldValidationRules_DependencyPath 
  ON dbo.FieldValidationRules(FormFieldId, DependencyPath);
```

**Acceptance Criteria:**
- ✅ Migration script tested locally
- ✅ Can be applied/reverted cleanly
- ✅ Index created for performance
- ✅ Backward compatible (nullable field)

---

#### 1.3 Implement IPathResolutionService Interface
**Time:** 2 hours

**File:** `Repository/knk-web-api-v2/Services/Interfaces/IPathResolutionService.cs`

```csharp
public interface IPathResolutionService
{
    /// <summary>
    /// Resolves a path against form context data.
    /// Supports single-hop paths only in v1: "Entity.Property"
    /// </summary>
    Task<PathResolutionResult> ResolvePathAsync(
        string path,
        Dictionary<string, object?> formContext,
        int? formConfigurationId = null
    );

    /// <summary>
    /// Validates that a path is syntactically correct and consistent with metadata.
    /// </summary>
    Task<PathValidationResult> ValidatePathAsync(
        string path,
        string entityTypeName
    );

    /// <summary>
    /// Get all available properties on an entity for UI suggestions.
    /// </summary>
    Task<EntityPropertySuggestion[]> GetAvailablePropertiesAsync(
        string entityTypeName
    );

    /// <summary>
    /// Check for circular dependencies: A → B → A
    /// </summary>
    Task<CircularDependencyCheckResult> CheckCircularDependencyAsync(
        int formFieldId,
        int dependsOnFieldId,
        int formConfigurationId
    );
}
```

**Implementation File:** `Repository/knk-web-api-v2/Services/PathResolutionService.cs`

**Key Methods:**

```csharp
public class PathResolutionService : IPathResolutionService
{
    private readonly IFormFieldRepository _fieldRepository;
    private readonly IEntityMetadataService _metadataService;
    private readonly ILogger<PathResolutionService> _logger;

    /// <summary>
    /// Implementation logic:
    /// 1. Split path by dots: "Town.wgRegionId" → ["Town", "wgRegionId"]
    /// 2. Validate v1 constraint: exactly 2 parts
    /// 3. Look up first part in formContext
    /// 4. Extract second part as property
    /// 5. Return value or error
    /// </summary>
    public async Task<PathResolutionResult> ResolvePathAsync(
        string path,
        Dictionary<string, object?> formContext,
        int? formConfigurationId = null
    )
    {
        try
        {
            // Validation: v1 - exactly one dot
            var parts = path.Split('.');
            if (parts.Length != 2)
            {
                return new PathResolutionResult
                {
                    Success = false,
                    Error = $"v1 supports single-hop paths only. Path '{path}' has {parts.Length - 1} dots.",
                    ResolvedPath = path
                };
            }

            var entityKey = parts[0];
            var propertyName = parts[1];

            // Step 1: Get entity from formContext
            if (!formContext.TryGetValue(entityKey, out var entityValue))
            {
                return new PathResolutionResult
                {
                    Success = false,
                    Error = $"Entity '{entityKey}' not found in form context.",
                    ResolvedPath = path
                };
            }

            if (entityValue == null)
            {
                return new PathResolutionResult
                {
                    Success = false,
                    Error = $"Entity '{entityKey}' is null. Fill this field before validation can execute.",
                    ResolvedPath = path
                };
            }

            // Step 2: Extract property from entity
            var extractedValue = ExtractPropertyValue(entityValue, propertyName);

            if (extractedValue == null)
            {
                return new PathResolutionResult
                {
                    Success = false,
                    Error = $"Property '{propertyName}' not found or is null on '{entityKey}'.",
                    ResolvedPath = path
                };
            }

            return new PathResolutionResult
            {
                Success = true,
                Value = extractedValue,
                ResolvedPath = path
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error resolving path '{path}'");
            return new PathResolutionResult
            {
                Success = false,
                Error = "Internal error during path resolution.",
                ResolvedPath = path
            };
        }
    }

    private object? ExtractPropertyValue(object entity, string propertyName)
    {
        var type = entity.GetType();
        var property = type.GetProperty(propertyName, System.Reflection.BindingFlags.IgnoreCase | System.Reflection.BindingFlags.Public);
        
        if (property == null)
            return null;

        return property.GetValue(entity);
    }

    public async Task<PathValidationResult> ValidatePathAsync(
        string path,
        string entityTypeName
    )
    {
        // Syntax validation
        var parts = path.Split('.');
        if (parts.Length != 2)
        {
            return new PathValidationResult
            {
                IsValid = false,
                Error = $"Invalid path syntax. Expected 'Entity.Property', got '{path}'.",
                DetailedError = $"Path contains {parts.Length - 1} dots; v1 requires exactly 1 dot."
            };
        }

        // Get entity metadata
        var metadata = await _metadataService.GetEntityMetadataAsync(entityTypeName);
        if (metadata == null)
        {
            return new PathValidationResult
            {
                IsValid = false,
                Error = $"Entity '{entityTypeName}' not found in metadata."
            };
        }

        var propertyName = parts[1];
        var property = metadata.Properties?.FirstOrDefault(p => 
            p.Name.Equals(propertyName, StringComparison.OrdinalIgnoreCase)
        );

        if (property == null)
        {
            var availableProps = string.Join(", ", metadata.Properties?.Select(p => p.Name) ?? Array.Empty<string>());
            return new PathValidationResult
            {
                IsValid = false,
                Error = $"Property '{propertyName}' not found on {entityTypeName}.",
                DetailedError = $"Available properties: {availableProps}"
            };
        }

        return new PathValidationResult
        {
            IsValid = true
        };
    }

    public async Task<EntityPropertySuggestion[]> GetAvailablePropertiesAsync(
        string entityTypeName
    )
    {
        var metadata = await _metadataService.GetEntityMetadataAsync(entityTypeName);
        if (metadata?.Properties == null)
            return Array.Empty<EntityPropertySuggestion>();

        return metadata.Properties
            .Select(p => new EntityPropertySuggestion
            {
                PropertyName = p.Name,
                PropertyType = p.Type,
                IsRequired = p.IsRequired,
                IsNavigable = p.IsNavigable,  // Can be followed by another dot (v2)
                Description = p.Description
            })
            .ToArray();
    }

    public async Task<CircularDependencyCheckResult> CheckCircularDependencyAsync(
        int formFieldId,
        int dependsOnFieldId,
        int formConfigurationId
    )
    {
        // Implementation:
        // 1. Get all rules for formFieldId
        // 2. Recursively check if any rule's DependsOnFieldId creates cycle
        // 3. Return cycle path if found
        
        var cycles = await _fieldRepository.FindDependencyCyclesAsync(
            formConfigurationId,
            formFieldId,
            dependsOnFieldId
        );

        return new CircularDependencyCheckResult
        {
            HasCycle = cycles.Any(),
            CyclePath = cycles.FirstOrDefault()
        };
    }
}
```

**Acceptance Criteria:**
- ✅ Interface defined with all methods
- ✅ Implementation handles all v1 constraints
- ✅ Returns detailed error messages
- ✅ Logging implemented for debugging
- ✅ No external dependencies beyond existing services

---

#### 1.4 Implement Path Validation Logic
**Time:** 2 hours

**Test Cases to Cover:**
- ✅ Valid single-hop path: "Town.wgRegionId"
- ✅ Invalid multi-hop path: "Town.District.wgRegionId" → Error
- ✅ Invalid no-dot path: "Town" → Error
- ✅ Missing entity in context: "InvalidEntity.property" → Error
- ✅ Missing property on entity: "Town.invalidProperty" → Error
- ✅ Null entity value: "Town" = null → Error with message
- ✅ Whitespace in path: "Town . property" → Error
- ✅ Case-insensitive property matching: "Town.WGREGIONID" → Success
- ✅ Circular dependency detection: A→B→A → Error

---

#### 1.5 Write Unit Tests for PathResolutionService
**Time:** 2 hours

**Test File:** `Repository/knk-web-api-v2.Tests/Services/PathResolutionServiceTests.cs`

```csharp
[TestClass]
public class PathResolutionServiceTests
{
    private PathResolutionService _service;
    private Mock<IFormFieldRepository> _fieldRepoMock;
    private Mock<IEntityMetadataService> _metadataMock;

    [TestMethod]
    public async Task ResolvePathAsync_ValidSingleHopPath_ReturnsValue()
    {
        // Arrange
        var path = "Town.wgRegionId";
        var formContext = new Dictionary<string, object?>
        {
            ["Town"] = new { id = 4, wgRegionId = "town_1" }
        };

        // Act
        var result = await _service.ResolvePathAsync(path, formContext);

        // Assert
        Assert.IsTrue(result.Success);
        Assert.AreEqual("town_1", result.Value);
    }

    [TestMethod]
    public async Task ResolvePathAsync_MultiHopPath_ReturnsError()
    {
        // v1 limitation test
        var path = "Town.District.wgRegionId";
        var formContext = new Dictionary<string, object?>();

        var result = await _service.ResolvePathAsync(path, formContext);

        Assert.IsFalse(result.Success);
        Assert.IsTrue(result.Error.Contains("single-hop"));
    }

    [TestMethod]
    public async Task ResolvePathAsync_NullEntity_ReturnsError()
    {
        var path = "Town.wgRegionId";
        var formContext = new Dictionary<string, object?> { ["Town"] = null };

        var result = await _service.ResolvePathAsync(path, formContext);

        Assert.IsFalse(result.Success);
        Assert.IsTrue(result.Error.Contains("null"));
    }

    [TestMethod]
    public async Task CheckCircularDependencyAsync_DetectsACycle()
    {
        // Setup: Field A depends on B, B depends on A
        // Should return cycle detected

        var result = await _service.CheckCircularDependencyAsync(
            formFieldId: 1,
            dependsOnFieldId: 2,
            formConfigurationId: 1
        );

        // Assert based on mock setup
    }

    // Additional tests for all edge cases...
}
```

**Target Coverage:** 80%+ (all public methods, main paths)

---

### Deliverables

- ✅ Updated FieldValidationRule entity (with backward-compatibility notes)
- ✅ Database migration script (tested locally)
- ✅ IPathResolutionService interface
- ✅ PathResolutionService implementation
- ✅ Unit test suite (80%+ coverage)
- ✅ Code review checklist completed

---

## Phase 2: Backend Dependency Resolution API

**Duration:** 1.5 weeks  
**Effort:** 8-10 hours  
**Team:** Backend developers (1-2)

### Tasks

#### 2.1 Implement IDependencyResolutionService
**Time:** 2 hours

**File:** `Services/Interfaces/IDependencyResolutionService.cs`

```csharp
public interface IDependencyResolutionService
{
    /// <summary>
    /// Batch resolve all dependencies for validation rules on specified fields.
    /// </summary>
    Task<DependencyResolutionResponse> ResolveDependenciesAsync(
        DependencyResolutionRequest request
    );

    /// <summary>
    /// Perform comprehensive health checks on FormConfiguration.
    /// </summary>
    Task<ValidationIssueDto[]> CheckConfigurationHealthAsync(
        int formConfigurationId
    );
}
```

**File:** `Services/DependencyResolutionService.cs`

```csharp
public class DependencyResolutionService : IDependencyResolutionService
{
    private readonly IPathResolutionService _pathResolutionService;
    private readonly IFieldValidationRuleRepository _ruleRepository;
    private readonly IFieldRepository _fieldRepository;
    private readonly IEntityMetadataService _metadataService;

    public async Task<DependencyResolutionResponse> ResolveDependenciesAsync(
        DependencyResolutionRequest request
    )
    {
        var resolved = new Dictionary<int, ResolvedDependency>();

        // Get all rules for the specified fields
        var rules = await _ruleRepository.GetByFieldIdsAsync(request.FieldIds);

        // Resolve each rule's dependency
        foreach (var rule in rules.Where(r => r.DependsOnFieldId.HasValue))
        {
            var dependencyPath = rule.DependencyPath ?? ExtractPathFromConfigJson(rule.ConfigJson);

            if (string.IsNullOrEmpty(dependencyPath))
            {
                resolved[rule.Id] = new ResolvedDependency
                {
                    RuleId = rule.Id,
                    Status = "error",
                    Message = "No dependency path configured",
                    ErrorDetail = "DependencyPath is required for multi-layer resolution"
                };
                continue;
            }

            var pathResolution = await _pathResolutionService.ResolvePathAsync(
                dependencyPath,
                request.FormContextSnapshot,
                request.FormConfigurationId
            );

            resolved[rule.Id] = new ResolvedDependency
            {
                RuleId = rule.Id,
                Status = pathResolution.Success ? "success" : (
                    pathResolution.Error.Contains("null") ? "pending" : "error"
                ),
                ResolvedValue = pathResolution.Value,
                DependencyPath = dependencyPath,
                ResolvedAt = DateTime.UtcNow,
                Message = pathResolution.Error,
                ErrorDetail = null
            };
        }

        return new DependencyResolutionResponse
        {
            Resolved = resolved,
            ResolvedAt = DateTime.UtcNow
        };
    }

    public async Task<ValidationIssueDto[]> CheckConfigurationHealthAsync(
        int formConfigurationId
    )
    {
        var issues = new List<ValidationIssueDto>();
        var config = await _formConfigRepository.GetByIdAsync(formConfigurationId);

        if (config == null)
            return Array.Empty<ValidationIssueDto>();

        // Perform all health checks
        issues.AddRange(await CheckFieldEntityAlignmentAsync(config));
        issues.AddRange(await CheckPropertyExistenceAsync(config));
        issues.AddRange(await CheckRequiredFieldCompletenessAsync(config));
        issues.AddRange(await CheckCircularDependenciesAsync(config));
        issues.AddRange(await CheckFieldOrderingAsync(config));

        return issues.ToArray();
    }

    private async Task<List<ValidationIssueDto>> CheckFieldEntityAlignmentAsync(
        FormConfigurationDto config
    )
    {
        var issues = new List<ValidationIssueDto>();
        var metadata = await _metadataService.GetEntityMetadataAsync(config.EntityTypeName);

        if (metadata == null)
        {
            issues.Add(new ValidationIssueDto
            {
                Severity = "Error",
                Message = $"Entity '{config.EntityTypeName}' not found in system metadata."
            });
            return issues;
        }

        // Check each field's expected entity type exists
        foreach (var field in GetAllFields(config.Steps))
        {
            // Logic to check field references valid entity
        }

        return issues;
    }

    // ... other health check methods
}
```

**Acceptance Criteria:**
- ✅ Batch resolution implemented
- ✅ Handles multiple rules efficiently
- ✅ Returns detailed status for each rule
- ✅ Distinguishes "pending" from "error" states
- ✅ Caching if applicable

---

#### 2.2 Create API Endpoints
**Time:** 2 hours

**File:** `Controllers/FieldValidationRulesController.cs`

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FieldValidationRulesController : ControllerBase
{
    private readonly IDependencyResolutionService _dependencyService;
    private readonly IPathResolutionService _pathService;

    /// <summary>
    /// POST /api/field-validation-rules/resolve-dependencies
    /// Batch resolve all dependencies for validation rules.
    /// </summary>
    [HttpPost("resolve-dependencies")]
    [ProducesResponseType(typeof(DependencyResolutionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DependencyResolutionResponse>> ResolveDependencies(
        [FromBody] DependencyResolutionRequest request
    )
    {
        if (request?.FieldIds == null || request.FieldIds.Length == 0)
            return BadRequest("FieldIds cannot be empty");

        var response = await _dependencyService.ResolveDependenciesAsync(request);
        return Ok(response);
    }

    /// <summary>
    /// POST /api/field-validation-rules/validate-path
    /// Validate a dependency path syntax and entity compatibility.
    /// </summary>
    [HttpPost("validate-path")]
    [ProducesResponseType(typeof(PathValidationResult), StatusCodes.Status200OK)]
    public async Task<ActionResult<PathValidationResult>> ValidatePath(
        [FromBody] ValidatePathRequest request
    )
    {
        var result = await _pathService.ValidatePathAsync(request.Path, request.EntityTypeName);
        return Ok(result);
    }

    /// <summary>
    /// GET /api/field-validation-rules/entity/{entityName}/properties
    /// Get all properties of an entity for UI suggestions.
    /// </summary>
    [HttpGet("entity/{entityName}/properties")]
    [ProducesResponseType(typeof(EntityPropertySuggestion[]), StatusCodes.Status200OK)]
    public async Task<ActionResult<EntityPropertySuggestion[]>> GetEntityProperties(
        string entityName
    )
    {
        var properties = await _pathService.GetAvailablePropertiesAsync(entityName);
        return Ok(properties);
    }
}
```

**Acceptance Criteria:**
- ✅ All 3 endpoints implemented
- ✅ Proper HTTP status codes
- ✅ Input validation on requests
- ✅ Swagger/OpenAPI documentation
- ✅ Authorization checks

---

#### 2.3 Add Placeholder Interpolation Logic
**Time:** 2 hours

**File:** `Services/PlaceholderInterpolationService.cs`

```csharp
public interface IPlaceholderInterpolationService
{
    /// <summary>
    /// Interpolate placeholders in error/success messages.
    /// </summary>
    string InterpolatePlaceholders(
        string template,
        Dictionary<string, string> placeholders
    );

    /// <summary>
    /// Generate placeholders for a specific validation type.
    /// </summary>
    Task<Dictionary<string, string>> GeneratePlaceholdersAsync(
        FieldValidationRuleDto rule,
        object dependencyValue,
        object fieldValue
    );
}

public class PlaceholderInterpolationService : IPlaceholderInterpolationService
{
    public string InterpolatePlaceholders(
        string template,
        Dictionary<string, string> placeholders
    )
    {
        var result = template;
        foreach (var (key, value) in placeholders)
        {
            result = result.Replace($"{{{key}}}", value ?? "");
        }
        return result;
    }

    public async Task<Dictionary<string, string>> GeneratePlaceholdersAsync(
        FieldValidationRuleDto rule,
        object dependencyValue,
        object fieldValue
    )
    {
        var placeholders = new Dictionary<string, string>();

        // Extract entity name from dependency value
        if (dependencyValue is IDictionary dict && dict.Contains("name"))
        {
            placeholders["entityName"] = dict["name"]?.ToString() ?? "";
        }

        // Extract coordinates if location field
        if (fieldValue is IDictionary locDict &&
            locDict.Contains("x") && locDict.Contains("z"))
        {
            var x = locDict["x"];
            var z = locDict["z"];
            placeholders["coordinates"] = $"(X: {x}, Z: {z})";
        }

        // Add validation-type-specific placeholders
        if (rule.ValidationType == "LocationInsideRegion")
        {
            // Add location-specific placeholders
        }

        return placeholders;
    }
}
```

**Acceptance Criteria:**
- ✅ Placeholder interpolation working
- ✅ Handles missing values gracefully
- ✅ Validation-type-specific placeholders generated
- ✅ Complex objects parsed correctly

---

#### 2.4 Implement Batch Resolution with Caching
**Time:** 1 hour

**Strategy:**
- Cache resolved values in `MemoryCache` with 5-minute TTL
- Cache key: `{formConfigId}_{fieldId}_{pathHash}`
- Invalidate cache when field value changes

```csharp
public class CachedDependencyResolutionService : IDependencyResolutionService
{
    private readonly IMemoryCache _cache;
    private readonly IDependencyResolutionService _innerService;

    public async Task<DependencyResolutionResponse> ResolveDependenciesAsync(
        DependencyResolutionRequest request
    )
    {
        var cacheKey = GenerateCacheKey(request);
        
        if (_cache.TryGetValue(cacheKey, out DependencyResolutionResponse cached))
            return cached;

        var result = await _innerService.ResolveDependenciesAsync(request);
        
        _cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));
        return result;
    }
}
```

**Acceptance Criteria:**
- ✅ Caching implemented
- ✅ TTL set appropriately
- ✅ Cache invalidation strategy defined
- ✅ Performance improved for repeated requests

---

#### 2.5 Write Integration Tests
**Time:** 2 hours

**Test File:** `Repository/knk-web-api-v2.Tests/Controllers/FieldValidationRulesControllerTests.cs`

```csharp
[TestClass]
public class FieldValidationRulesControllerTests
{
    private FieldValidationRulesController _controller;
    private Mock<IDependencyResolutionService> _serviceMock;

    [TestMethod]
    public async Task ResolveDependencies_ValidRequest_Returns200()
    {
        var request = new DependencyResolutionRequest
        {
            FieldIds = new[] { 60, 61 },
            FormContextSnapshot = new Dictionary<string, object?>
            {
                ["Town"] = new { id = 4, wgRegionId = "town_1" }
            }
        };

        var result = await _controller.ResolveDependencies(request);

        Assert.IsInstanceOfType(result.Result, typeof(OkObjectResult));
    }

    [TestMethod]
    public async Task ResolveDependencies_EmptyFieldIds_ReturnsBadRequest()
    {
        var request = new DependencyResolutionRequest { FieldIds = Array.Empty<int>() };

        var result = await _controller.ResolveDependencies(request);

        Assert.IsInstanceOfType(result.Result, typeof(BadRequestObjectResult));
    }

    // Additional tests...
}
```

**Target Coverage:** 70%+ (API layer)

---

### Deliverables

- ✅ IDependencyResolutionService interface
- ✅ DependencyResolutionService implementation
- ✅ API endpoints (3 new endpoints)
- ✅ PlaceholderInterpolationService
- ✅ Caching strategy implemented
- ✅ Integration test suite
- ✅ Swagger documentation updated

---

## Phase 3: Enhanced Configuration Health Checks

**Duration:** 1.5 weeks  
**Effort:** 8-10 hours  
**Team:** Backend developers (1-2)

### Tasks

#### 3.1-3.5 Health Check Implementations

**Health checks to implement:**

1. **Field-Entity Alignment Check**
   - Verify referenced entities exist in metadata
   - Time: 1.5 hours

2. **Property Existence Check**
   - Verify paths reference valid properties
   - Time: 1.5 hours

3. **Required Field Completeness Check**
   - Compare entity's required fields with form configuration
   - Time: 2 hours

4. **Collection Warning (v1)**
   - Detect if path resolves to array/collection
   - Time: 1.5 hours

5. **Circular Dependency Detection**
   - Use graph algorithm to detect cycles
   - Time: 2 hours

6. **Field Ordering Validation**
   - Verify dependency fields come before dependent fields
   - Time: 1.5 hours

**Acceptance Criteria:**
- ✅ All 6 checks implemented
- ✅ Tests for each check type
- ✅ Clear error/warning messages
- ✅ Correct severity levels assigned

---

### Deliverables

- ✅ Enhanced ConfigurationHealthService
- ✅ 6 validation check implementations
- ✅ Unit test suite (70%+ coverage)
- ✅ Test data fixtures for health check scenarios

---

## Phase 4: Frontend Data Layer - DTOs & Hooks

**Duration:** 1.5 weeks  
**Effort:** 8-10 hours  
**Team:** Frontend developers (1-2)

### Tasks

#### 4.1 Create TypeScript DTOs
**Time:** 2 hours

**File:** `Repository/knk-web-app/src/types/dtos/forms/FieldValidationRuleDtos.ts`

Extend existing DTOs with:
```typescript
export interface FieldValidationRuleDto {
  // Existing fields...
  
  // [NEW] Multi-layer support
  dependencyPath?: string;  // e.g., "Town.wgRegionId"
}

// [NEW] Request/Response types
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

// ... additional types per spec
```

**Acceptance Criteria:**
- ✅ All new DTOs defined
- ✅ Type-safe and properly exported
- ✅ Documentation added
- ✅ Backward-compatible with existing types

---

#### 4.2 Update fieldValidationRuleClient
**Time:** 2 hours

Add methods to `Repository/knk-web-app/src/apiClients/fieldValidationRuleClient.ts`:

```typescript
resolveDependencies(request: DependencyResolutionRequest): 
  Promise<DependencyResolutionResponse> { ... }

getEntityProperties(entityTypeName: string): 
  Promise<EntityPropertySuggestion[]> { ... }

validatePath(path: string, entityTypeName: string): 
  Promise<PathValidationResult> { ... }
```

**Acceptance Criteria:**
- ✅ All 3 methods implemented
- ✅ Error handling in place
- ✅ Type-safe parameters and returns
- ✅ Logging for debugging

---

#### 4.3 Implement useEnrichedFormContext Hook
**Time:** 3 hours

**File:** `Repository/knk-web-app/src/hooks/useEnrichedFormContext.ts`

```typescript
export const useEnrichedFormContext = (
  config: FormConfigurationDto
): EnrichedFormContextType => {
  const [values, setValues] = useState<Record<string, any>>({});
  const [fieldMetadata, setFieldMetadata] = useState<Map<number, FormFieldMetadata>>(new Map());
  const [entityMetadata, setEntityMetadata] = useState<EntityMetadataMap>(new Map());
  const [resolvedDependencies, setResolvedDependencies] = useState<Map<number, ResolvedDependency>>(new Map());
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // On mount: Load field metadata and entity metadata
  useEffect(() => {
    const loadMetadata = async () => {
      try {
        setIsLoading(true);
        const fieldMeta = await buildFieldMetadataMap(config);
        const entityMeta = await metadataClient.getAllEntityMetadata();
        setFieldMetadata(fieldMeta);
        setEntityMetadata(new Map(entityMeta.map(e => [e.entityName, e])));
      } catch (err) {
        setError(`Failed to load metadata: ${err}`);
      } finally {
        setIsLoading(false);
      }
    };

    loadMetadata();
  }, [config.id]);

  const setFieldValue = (fieldName: string, value: any) => {
    setValues(prev => ({...prev, [fieldName]: value}));
    // Trigger dependency resolution
    resolveDependenciesBatch([...fieldMetadata.keys()]);
  };

  const resolveDependency = async (ruleId: number): Promise<ResolvedDependency> => {
    // Implementation
  };

  const resolveDependenciesBatch = async (fieldIds: number[]): Promise<DependencyResolutionResponse> => {
    // Implementation
  };

  return {
    values,
    fieldMetadata,
    entityMetadata,
    resolvedDependencies,
    isLoading,
    error,
    setFieldValue,
    resolveDependency,
    resolveDependenciesBatch
  };
};
```

**Acceptance Criteria:**
- ✅ Hook manages all form context state
- ✅ Metadata loaded on mount
- ✅ Dependency resolution integrated
- ✅ Error handling and loading states
- ✅ Proper cleanup (dependencies array)

---

#### 4.4 Add Caching & Error Handling
**Time:** 1 hour

Implement caching layer using `useMemo` and `useCallback`:

```typescript
const cachedFieldMetadata = useMemo(() => fieldMetadata, [fieldMetadata]);
const cachedResolvedDependencies = useMemo(() => resolvedDependencies, [resolvedDependencies]);

const setFieldValueWithErrorHandling = useCallback(async (fieldName: string, value: any) => {
  try {
    setFieldValue(fieldName, value);
  } catch (err) {
    setError(`Failed to set field value: ${err}`);
    // Notify user
  }
}, [setFieldValue]);
```

**Acceptance Criteria:**
- ✅ Caching prevents unnecessary re-renders
- ✅ Error boundaries in place
- ✅ User feedback on errors
- ✅ Recovery mechanism implemented

---

#### 4.5 Write Hook Tests
**Time:** 1.5 hours

**Test File:** `Repository/knk-web-app/src/hooks/__tests__/useEnrichedFormContext.test.ts`

```typescript
describe('useEnrichedFormContext', () => {
  it('loads field and entity metadata on mount', async () => {
    const {result} = renderHook(() => useEnrichedFormContext(mockConfig));
    
    await waitFor(() => {
      expect(result.current.fieldMetadata.size).toBeGreaterThan(0);
      expect(result.current.entityMetadata.size).toBeGreaterThan(0);
    });
  });

  it('resolves dependencies batch', async () => {
    const {result} = renderHook(() => useEnrichedFormContext(mockConfig));
    
    const response = await result.current.resolveDependenciesBatch([60, 61]);
    
    expect(response.resolved[123].status).toBe('success');
  });

  // Additional tests...
});
```

**Target Coverage:** 75%+

---

### Deliverables

- ✅ Extended DTO types with multi-layer support
- ✅ Updated fieldValidationRuleClient
- ✅ useEnrichedFormContext hook with caching
- ✅ Error handling and recovery
- ✅ Hook test suite

---

## Phase 5: Frontend - PathBuilder Component

**Duration:** 1.5 weeks  
**Effort:** 10-12 hours  
**Team:** Frontend developers (1-2)

### Tasks

#### 5.1 Implement PathBuilder Component
**Time:** 5 hours

**File:** `Repository/knk-web-app/src/components/PathBuilder/PathBuilder.tsx`

Features:
- Dropdown for entity field selection
- Dropdown for property selection (with suggestions)
- Real-time validation
- Visual path preview
- Responsive design

```tsx
export const PathBuilder: React.FC<PathBuilderProps> = ({
  initialPath,
  entityTypeName,
  onPathChange,
  onValidationStatusChange,
  fieldMetadata,
  entityMetadata,
  disabled
}) => {
  const [selectedEntity, setSelectedEntity] = useState<string>("");
  const [selectedProperty, setSelectedProperty] = useState<string>("");
  const [validationStatus, setValidationStatus] = useState<PathValidationStatus>("pending");
  const [suggestions, setSuggestions] = useState<EntityPropertySuggestion[]>([]);

  // Load suggestions when entity selected
  useEffect(() => {
    if (selectedEntity) {
      const entity = Array.from(entityMetadata.values()).find(e => e.entityName === selectedEntity);
      if (entity?.properties) {
        const sugg = entity.properties.map(p => ({
          propertyName: p.name,
          propertyType: p.type,
          isRequired: p.isRequired,
          isNavigable: false,  // v1 only
          description: p.description
        }));
        setSuggestions(sugg);
      }
    }
  }, [selectedEntity, entityMetadata]);

  // Validate path on change
  useEffect(() => {
    const validateAndNotify = async () => {
      if (selectedEntity && selectedProperty) {
        const path = `${selectedEntity}.${selectedProperty}`;
        const validation = await fieldValidationRuleClient.validatePath(path, entityTypeName);
        setValidationStatus(validation.isValid ? "success" : "error");
        onValidationStatusChange?.(validation);
      }
    };

    validateAndNotify();
  }, [selectedEntity, selectedProperty]);

  // Notify parent of path change
  useEffect(() => {
    if (selectedEntity && selectedProperty) {
      onPathChange(`${selectedEntity}.${selectedProperty}`);
    }
  }, [selectedEntity, selectedProperty]);

  return (
    <div className="space-y-4">
      {/* Entity Selection */}
      <div>
        <label className="block text-sm font-medium">Dependency Field</label>
        <select
          value={selectedEntity}
          onChange={(e) => setSelectedEntity(e.target.value)}
          disabled={disabled}
          className="mt-1 w-full"
        >
          <option value="">Select field...</option>
          {Array.from(entityMetadata.values()).map((entity) => (
            <option key={entity.entityName} value={entity.entityName}>
              {entity.displayName || entity.entityName}
            </option>
          ))}
        </select>
      </div>

      {/* Property Selection */}
      {suggestions.length > 0 && (
        <div>
          <label className="block text-sm font-medium">Property</label>
          <select
            value={selectedProperty}
            onChange={(e) => setSelectedProperty(e.target.value)}
            disabled={disabled}
            className="mt-1 w-full"
          >
            <option value="">Select property...</option>
            {suggestions.map((s) => (
              <option key={s.propertyName} value={s.propertyName}>
                {s.propertyName} ({s.propertyType})
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Path Preview */}
      {selectedEntity && selectedProperty && (
        <div className="bg-blue-50 border border-blue-200 rounded p-3">
          <p className="text-sm font-mono">
            {selectedEntity}.{selectedProperty}
          </p>
          {validationStatus === "success" && (
            <p className="text-xs text-green-600 mt-1">✓ Valid path</p>
          )}
          {validationStatus === "error" && (
            <p className="text-xs text-red-600 mt-1">✗ Invalid path</p>
          )}
        </div>
      )}
    </div>
  );
};
```

**Acceptance Criteria:**
- ✅ Component renders correctly
- ✅ Dropdowns function (entity, property)
- ✅ Real-time validation
- ✅ Error messages displayed
- ✅ Responsive design (desktop, tablet, mobile)

---

#### 5.2 Add Autocomplete/Suggestions
**Time:** 2 hours

Enhance PathBuilder with:
- Searchable dropdown (case-insensitive)
- Property type display
- Keyboard navigation

```tsx
// Use library like `react-select` or custom implementation
<Select
  options={suggestions.map(s => ({
    value: s.propertyName,
    label: `${s.propertyName} (${s.propertyType})`
  }))}
  onChange={(option) => setSelectedProperty(option?.value || "")}
  isClearable
  isSearchable
  classNamePrefix="property-select"
/>
```

**Acceptance Criteria:**
- ✅ Searchable dropdowns
- ✅ Quick shortcuts (keyboard)
- ✅ Clear visual hierarchy

---

#### 5.3 Responsive Design
**Time:** 2 hours

Ensure mobile/tablet compatibility:

**Desktop (>1024px):**
- Side-by-side dropdowns
- Full suggestions list visible

**Tablet (768px-1024px):**
- Stacked dropdowns
- Scroll for suggestions

**Mobile (<768px):**
- Full-width dropdowns
- Modal/drawer for suggestions

**Acceptance Criteria:**
- ✅ Works on all breakpoints
- ✅ Touch-friendly (large tap targets)
- ✅ No horizontal scroll
- ✅ Tested on real devices

---

#### 5.4 Add Storybook Stories
**Time:** 1 hour

**File:** `src/components/PathBuilder/PathBuilder.stories.tsx`

```tsx
export default {
  title: 'Forms/PathBuilder',
  component: PathBuilder
};

export const Default = () => <PathBuilder {...defaultProps} />;
export const WithInitialPath = () => <PathBuilder {...propsWithPath} />;
export const Disabled = () => <PathBuilder {...defaultProps} disabled />;
export const Mobile = () => <PathBuilder {...defaultProps} />;  // Set viewport to mobile
```

---

#### 5.5 Write Component Tests
**Time:** 2 hours

**Test File:** `src/components/PathBuilder/__tests__/PathBuilder.test.tsx`

```tsx
describe('PathBuilder', () => {
  it('renders entity dropdown', () => {
    render(<PathBuilder {...mockProps} />);
    expect(screen.getByText('Dependency Field')).toBeInTheDocument();
  });

  it('loads property suggestions when entity selected', async () => {
    render(<PathBuilder {...mockProps} />);
    
    const entitySelect = screen.getByDisplayValue('Select field...');
    await userEvent.click(entitySelect);
    await userEvent.click(screen.getByText('Town'));

    await waitFor(() => {
      expect(screen.getByText(/wgRegionId/)).toBeInTheDocument();
    });
  });

  it('validates path on selection', async () => {
    const { getByDisplayValue } = render(<PathBuilder {...mockProps} />);
    
    // Select path...
    
    await waitFor(() => {
      expect(screen.getByText('✓ Valid path')).toBeInTheDocument();
    });
  });

  // Additional tests...
});
```

**Target Coverage:** 80%+

---

### Deliverables

- ✅ PathBuilder component (fully functional)
- ✅ Autocomplete/suggestions implemented
- ✅ Responsive design tested across devices
- ✅ Storybook stories for documentation
- ✅ Component test suite (80%+ coverage)

---

## Phase 6: Frontend - UI Integration & Validation

**Duration:** 1 week  
**Effort:** 10-12 hours  
**Team:** Frontend developers + UX (1-2)

### Tasks

#### 6.1 Update ValidationRuleBuilder
**Time:** 3 hours

Replace free-text path input with PathBuilder component.

#### 6.2 Update ConfigurationHealthPanel
**Time:** 4 hours

Add:
- 7 new validation check sections
- Recommended actions (Quick Fix buttons)
- Collapsible detailed error messages
- Icons and color coding (error/warning/info)

```tsx
<div className="space-y-3">
  {/* Field Alignment Check */}
  <HealthCheckSection
    title="Field Alignment"
    severity="error"
    passed={3}
    total={3}
    issues={fieldAlignmentIssues}
    canAutoFix={false}
  />

  {/* Property Validation Check */}
  <HealthCheckSection
    title="Property Validation"
    severity="error"
    passed={5}
    total={5}
    issues={propertyIssues}
    canAutoFix={false}
  />

  {/* Required Field Completeness Check */}
  <HealthCheckSection
    title="Required Field Completeness"
    severity="warning"
    passed={3}
    total={4}
    issues={requiredFieldIssues}
    canAutoFix={true}
    onAutoFix={handleAutoFix}
  />

  {/* ... additional sections ... */}
</div>
```

#### 6.3 Responsive Design Testing
**Time:** 2 hours

Test on:
- Chrome (Windows, Mac, Linux)
- Firefox (latest)
- Safari (macOS, iOS)
- Edge (Windows)
- Mobile browsers (Chrome, Safari, Firefox)

#### 6.4 Accessibility Testing
**Time:** 2 hours

- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader testing
- Color contrast verification

#### 6.5 Visual Regression Testing
**Time:** 1 hour

Set up visual regression tests using Percy or similar:

```tsx
it('PathBuilder matches screenshot', () => {
  cy.mount(<PathBuilder {...props} />);
  cy.percySnapshot('PathBuilder - Default');
});
```

---

### Deliverables

- ✅ Updated ValidationRuleBuilder with PathBuilder
- ✅ Enhanced ConfigurationHealthPanel (7+ checks)
- ✅ Responsive design verified
- ✅ Accessibility compliance (WCAG 2.1 AA)
- ✅ Visual regression tests

---

## Phase 7: Frontend - WorldTask Integration

**Duration:** 1.5 weeks  
**Effort:** 8-10 hours  
**Team:** Frontend developers (1-2)

### Tasks

#### 7.1 Update WorldBoundFieldRenderer
**Time:** 2 hours

Update the `WorldBoundFieldRenderer` component (the active component used by FormWizard) to use resolved dependencies from useEnrichedFormContext:

```tsx
const formContext = useEnrichedFormContext(formConfiguration);

const handleCreateInMinecraft = async () => {
  // Build validation context with RESOLVED dependencies
  const inputData = {
    fieldName: field.fieldName,
    currentValue: value,
    validationContext: {
      validationRules: rules.map(rule => ({
        ...rule,
        // Use pre-resolved value
        dependencyFieldValue: formContext.resolvedDependencies.get(rule.id)?.resolvedValue,
        preResolvedPlaceholders: {}  // Backend will interpolate
      })),
      formContext: formContext.values  // Include full formContext for plugin
    }
  };

  // Submit to API...
};
```

**Acceptance Criteria:**
- ✅ Uses resolved dependencies from useEnrichedFormContext
- ✅ Passes dehydrated payload with validation context
- ✅ Backward compatible with existing tasks
- ✅ **Note:** `WorldTaskCta.tsx` is dead code (not imported anywhere) and should be deleted as cleanup

#### 7.2 Test with Minecraft Plugin
**Time:** 3 hours

- Connect to running Minecraft server
- Create test fixtures (Town, Location, etc.)
- Execute WorldTasks and verify:
  - Validation rules execute correctly
  - Error messages display as pre-interpolated
  - Multi-layer paths resolve properly
- Log any discrepancies

#### 7.3 Validation Message Interpolation
**Time:** 2 hours

Verify backend pre-interpolation working:
- Message received is fully resolved
- Placeholders replaced with actual values
- Plugin displays without additional processing

#### 7.4 E2E Test Scenarios
**Time:** 2 hours

Create comprehensive E2E tests:

```tsx
describe('Multi-Layer Dependency Validation E2E', () => {
  it('validates location inside town region', async () => {
    cy.visit('/form-builder/district');
    
    // Step 1: Select Town
    cy.selectField('Town', 'Cinix');
    cy.expectResolved('dependency-town', 'Cinix');

    // Step 2: Select Location
    cy.selectField('Location', fixtures.locationInsideTown);
    cy.expectValidationMessage('Location is within region boundaries ✓');

    // Step 3: Submit
    cy.submitForm();
    cy.expectWorldTaskCreated();

    // Step 4: Minecraft validation
    cy.minecraft.claimTask();
    cy.minecraft.completeTask();
    cy.expectDistrictCreated();
  });

  it('rejects location outside town region', async () => {
    cy.visit('/form-builder/district');
    cy.selectField('Town', 'Cinix');
    cy.selectField('Location', fixtures.locationOutsideTown);
    cy.expectValidationMessage('Location is outside Cinix's boundaries...');
    cy.expectSubmitButtonDisabled();
  });
});
```

---

### Deliverables

- ✅ Updated WorldBoundFieldRenderer with resolved dependencies integration
- ✅ Minecraft integration tested
- ✅ E2E test scenarios passing
- ✅ Message interpolation verified
- ℹ️ **Cleanup Note:** Delete `WorldTaskCta.tsx` (dead code - not imported anywhere, safe to remove)

---

## Phase 8: Testing & Documentation

**Duration:** 1.5 weeks  
**Effort:** 10-12 hours  
**Team:** QA + Documentation (2)

### Tasks

#### 8.1 E2E Test Suite
**Time:** 3 hours

Create comprehensive end-to-end tests covering:
- Path creation and validation workflows
- Circular dependency detection
- Field ordering requirements
- Multi-step form flows
- Error recovery
- Plugin execution

#### 8.2 Load Testing
**Time:** 2 hours

Test batch dependency resolution with:
- 100+ validation rules
- Large form context data
- Concurrent requests

```
Tool: Apache JMeter or LoadRunner
Scenario: POST /api/field-validation-rules/resolve-dependencies
Users: 10-100 concurrent
Requests: 100-500 per second
Target Response Time: <200ms p95
```

#### 8.3 Feature Documentation
**Time:** 4 hours

Write:
- **Admin Guide:** How to create multi-layer dependencies
- **Developer Guide:** API reference and integration
- **API Docs:** Endpoint specifications
- **Troubleshooting:** Common issues and solutions
- **Release Notes:** What's new in v2.0

#### 8.4 Training Materials
**Time:** 2 hours

- Video walkthrough (3-5 min)
- Interactive examples
- Checklists for common configurations
- FAQ document

#### 8.5 Create Test Report
**Time:** 1 hour

Summarize:
- Test execution results
- Coverage percentages
- Performance metrics
- Known issues (if any)

---

### Deliverables

- ✅ E2E test suite (passing)
- ✅ Load test results
- ✅ Feature documentation (complete)
- ✅ Training materials
- ✅ Test execution report

---

## Phase 9: v2 Planning (Post-Release)

**Duration:** 2-3 weeks (planning only, no implementation in v1)  
**Effort:** 8 hours planning

### Topics to Define

1. **Collection Operator Implementation**
   - [first], [last], [all], [user] syntax
   - Multi-item validation results
   - UI for collection operator selection

2. **Multi-Hop Path Navigation**
   - Full "A.B.C.D" path support
   - Circular dependency detection algorithm
   - Performance implications

3. **Smart Property Filtering**
   - Validation-type-specific suggestions
   - Mark properties as "region" vs "location" vs "scalar"
   - Auto-suggest based on validation type

4. **FormConfiguration Versioning**
   - Version tracking in database
   - Migration strategy
   - Backwards compatibility approach

5. **Advanced Error Reporting**
   - Collection item breakdowns
   - Failure root cause analysis
   - Automated remediation suggestions

---

## Appendix: Dependency Map

```
Phase 1
  ↓
Phase 2 ← depends on Phase 1
  ↓
Phase 3 ← depends on Phase 2
  ↓
Phase 4 ← depends on Phase 2
  ↓
Phase 5 ← depends on Phase 4
  ↓
Phase 6 ← depends on Phase 5
  ↓
Phase 7 ← depends on Phase 6 + Phase 2
  ↓
Phase 8 ← depends on Phase 7 (can start partially during Phase 7)

Phase 9 ← independent (planning only)
```

**Parallelization Opportunity:**
- Phase 4 can start once Phase 2 endpoints are stubbed
- Phase 5 can start once Phase 4 DTOs are finalized
- Phase 8 can start writing tests once Phase 7 components exist

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Backend API delays Phase 4 | Medium | High | Start Phase 4 with mock APIs |
| PathBuilder complex to build | Medium | Medium | Use existing library (react-select) |
| Minecraft plugin incompatibility | Low | High | Early integration testing (Phase 7) |
| Performance degradation | Low | Medium | Load tests in Phase 8 |

---

**Total Estimated Timeline:** 9 weeks  
**Total Estimated Effort:** 60-70 hours (1.5 developers full-time)

---

**Last Updated:** February 9, 2026
