# Phase 1 Checklist: Shared Service Foundation

**Phase:** 1 (Weeks 2-3)  
**Owner:** Backend Team  
**Duration:** 8-10 hours  
**Estimated Days:** 1-1.5 developer days  
**Blocker:** None - Can start immediately

---

## 🎯 Phase 1 Objective

Create `IPathResolutionService` shared interface + implement PathResolutionService class.

**Success Criteria:**
- Service interface designed and approved
- PathResolutionService class implemented
- At least 20 unit tests passing (80%+ coverage)
- Database migration for new `DependencyPath` property
- Zero breaking changes to existing code
- Both systems (dependency resolution + placeholder interpolation) can use this service

---

## 📝 Pre-Implementation Tasks (Day 0 - 2 hours)

- [ ] Backend lead reviews [ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md) section "Decision 1"
- [ ] Backend lead reviews [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md) section "Shared Service Definition"
- [ ] Confirm namespaces with team (suggest: `KnK.Core.Services`, `KnK.Core.Shared`)
- [ ] Assign code reviewer(s)
- [ ] Create feature branch: `feature/phase-1-path-resolution-service`
- [ ] Update IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md with actual start date

---

## 🔧 Implementation Tasks (Day 1 - 6 hours)

### Task 1: Create IPathResolutionService Interface
**Time:** 1 hour  
**File:** `KnK.Core/Services/PathResolution/IPathResolutionService.cs`

```csharp
namespace KnK.Core.Services.PathResolution
{
    public interface IPathResolutionService
    {
        /// <summary>
        /// Resolves a dot-notation path (e.g., "Town.wgRegionId") 
        /// to its actual value from an entity instance.
        /// </summary>
        Task<object?> ResolvePathAsync(
            string entityTypeName,      // e.g., "Location"
            string path,                // e.g., "Town.wgRegionId"
            object? entityInstance      // e.g., location object
        );

        /// <summary>
        /// Validates that a path is valid for the given entity type.
        /// Returns detailed error information if invalid.
        /// </summary>
        Task<PathValidationResult> ValidatePathAsync(
            string entityTypeName,      // e.g., "Location"
            string path                 // e.g., "Town.wgRegionId"
        );

        /// <summary>
        /// Returns array of navigation paths needed for Entity Framework
        /// Include() statements to efficiently load related data.
        /// </summary>
        string[] GetIncludePathsForNavigation(string path);
    }

    public class PathValidationResult
    {
        public bool IsValid { get; set; }
        public string? PropertyType { get; set; }  // e.g., "int", "string"
        public string? EntityType { get; set; }     // Final entity type
        public string? ErrorMessage { get; set; }   // If invalid
        public string[]? SuggestedPaths { get; set; } // Autocomplete suggestions
    }
}
```

**Checklist:**
- [ ] Interface added to KnK.Core project
- [ ] XML doc comments complete for all methods
- [ ] Namespace correct
- [ ] DTO classes (PathValidationResult) added
- [ ] Code compiles

### Task 2: Implement PathResolutionService Class

**Time:** 3-4 hours  
**File:** `KnK.Core/Services/PathResolution/PathResolutionService.cs`

**Key Methods to Implement:**

```csharp
public class PathResolutionService : IPathResolutionService
{
    private readonly IEntityMetadataProvider _entityMetadata;
    private readonly IRepositoryFactory _repositories;
    private readonly ILogger<PathResolutionService> _logger;

    public async Task<object?> ResolvePathAsync(
        string entityTypeName, 
        string path, 
        object? entityInstance)
    {
        // Parse the path: "Town.wgRegionId" → ["Town", "wgRegionId"]
        var segments = path.Split('.');
        var current = entityInstance;

        foreach (var segment in segments)
        {
            // Navigate to next level (reflection-based)
            // Handle null checks
            // Support both properties and navigation properties
        }

        return current;
    }

    public async Task<PathValidationResult> ValidatePathAsync(
        string entityTypeName, 
        string path)
    {
        // Validate path exists for entity type
        // Check all properties in chain exist
        // Return type information
        // Detect circular references (prepare for v2)
    }

    public string[] GetIncludePathsForNavigation(string path)
    {
        // Return EF Include paths for efficient loading
        // E.g., "Town.wgRegionId" → ["Town"]
    }
}
```

**Checklist:**
- [ ] Service class created
- [ ] Dependency injection (IEntityMetadataProvider, etc.) added
- [ ] All three interface methods implemented
- [ ] Error handling (null paths, non-existent properties)
- [ ] Logging added for debugging

### Task 3: Add DependencyPath Property to Entity

**Time:** 1 hour  
**File:** `KnK.Core/Entities/FieldValidationRule.cs`

```csharp
public class FieldValidationRule
{
    // Existing properties...
    public int Id { get; set; }
    public int FormFieldId { get; set; }
    public string? ValidationPattern { get; set; }
    
    // NEW: Property that specifies the dependency path
    public string? DependencyPath { get; set; }  // e.g., "Town.wgRegionId"
    
    public FormField? FormField { get; set; }
    
    // Existing navigation properties...
}
```

**Checklist:**
- [ ] Property added to FieldValidationRule entity
- [ ] Property marked as nullable (backward compatibility)
- [ ] Updated entity mapping (if using Fluent API)
- [ ] Code compiles

### Task 4: Create Database Migration

**Time:** 30 minutes  
**File:** `KnK.Data/Migrations/AddDependencyPathToFieldValidationRule.cs`

```shell
# In Package Manager Console, run:
Add-Migration AddDependencyPathToFieldValidationRule -Project KnK.Data
```

**Migration content should:**
- [ ] Add `DependencyPath` column to `FieldValidationRules` table
- [ ] Set column as nullable VARCHAR(256) or similar
- [ ] Create non-clustered index on DependencyPath (for health checks)
- [ ] Include default value handling
- [ ] Include rollback logic

**Checklist:**
- [ ] Migration file created
- [ ] `Up()` method adds column
- [ ] `Down()` method removes column
- [ ] Migration applies successfully (`Update-Database`)
- [ ] Database schema verified

### Task 5: Unit Tests (20+ tests)

**Time:** 2-3 hours  
**File:** `KnK.Tests/Services/PathResolution/PathResolutionServiceTests.cs`

**Test Categories:**

**Positive Tests (6 tests):**
- [ ] Resolve single-property path (e.g., "wgRegionId")
- [ ] Resolve multi-level path (e.g., "Town.wgRegionId")
- [ ] Return correct type information
- [ ] Handle null entity instance gracefully
- [ ] Return correct Include paths for EF navigation
- [ ] Handle different property types (int, string, DateTime)

**Negative Tests (8 tests):**
- [ ] Invalid property name in path
- [ ] Non-existent entity type
- [ ] Null/empty path
- [ ] Circular reference detection (prepare v2)
- [ ] Missing middle navigation property
- [ ] Invalid path syntax
- [ ] Type mismatch in path segment
- [ ] Collection property in middle of path

**Edge Cases (6 tests):**
- [ ] Path with leading/trailing spaces
- [ ] Path with special characters
- [ ] Very long paths (5+ segments)
- [ ] Case sensitivity handling
- [ ] Unicode characters in property names
- [ ] Performance: 1000 resolutions in <100ms

**Checklist:**
- [ ] Test class created
- [ ] All 20+ tests written
- [ ] All tests passing (0 failures)
- [ ] Coverage: 80%+ for service class
- [ ] Mocks for dependencies (IEntityMetadataProvider, etc.)

---

## ✅ Quality Assurance (Day 2 - 2 hours)

### Code Review
- [ ] Reviewer checks interface design
- [ ] Reviewer checks implementation logic
- [ ] Reviewer verifies error handling
- [ ] Reviewer checks performance (no N+1 queries)
- [ ] Reviewer approves for merge

### Testing
- [ ] All unit tests passing locally
- [ ] Run unit tests in CI/CD pipeline ✅
- [ ] Coverage report: 80%+
- [ ] No warnings or code analysis issues
- [ ] Performance acceptable (<100ms for typical paths)

### Documentation
- [ ] XML doc comments complete
- [ ] README.md updated with service explanation
- [ ] Architecture diagram updated
- [ ] Code examples in docs
- [ ] Troubleshooting guide (common errors)

### Integration Check
- [ ] Verify no breaking changes to existing code
- [ ] Check that placeholder interpolation still works
- [ ] Verify database migration applied successfully
- [ ] Test backward compatibility (rules without DependencyPath)

---

## 📋 Submission Checklist

Before marking Phase 1 COMPLETE, ensure:

- [ ] Code merged to develop branch
- [ ] All tests passing in CI/CD
- [ ] Code review approved
- [ ] Database migration deployed successfully
- [ ] Documentation updated
- [ ] IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md updated with actual completion date
- [ ] Team slack: notify that Phase 1 complete, Phase 2 ready to start

---

## 🚨 Known Gotchas

### Issue 1: Entity Framework Navigation Properties
**Problem:** Some entities might have `[JsonIgnore]` on navigation properties  
**Solution:** PathResolutionService needs to use reflection, not JSON serialization

### Issue 2: Circular References in Entity Relationships
**Problem:** Town → District → Town could cause infinite loop  
**Solution:** Phase 1 doesn't support this (v1 is single-hop), prepare detection for Phase 8

### Issue 3: Collection Properties Early
**Problem:** Path might include collection (e.g., "Person.Locations[0].Region")  
**Solution:** Phase 1 doesn't support collections, reject with clear error message

### Issue 4: Backward Compatibility
**Problem:** Existing rules don't have DependencyPath set  
**Solution:** Fallback to old heuristic if DependencyPath is null (don't break existing deployments)

---

## 📞 Phase 1 Success Contact

If you get stuck on:

- **Service Design Questions:** Review [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md) section "Shared Service"
- **Implementation Examples:** See code examples in [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md) Phase 1 section
- **Architecture Alignment:** Check [ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md) Decision Q1
- **Database Schema:** Look at existing FieldValidationRule entity mapping
- **Test Strategy:** Review similar service tests in KnK.Tests project

---

## 📊 Phase 1 Deliverables Summary

```
IPathResolutionService Interface
├─ ResolvePathAsync() method
├─ ValidatePathAsync() method
├─ GetIncludePathsForNavigation() method
└─ PathValidationResult DTO

PathResolutionService Implementation
├─ Full implementation of 3 interface methods
├─ Error handling (7 exception types)
├─ Performance optimization (caching metadata)
├─ Circular reference detection (v1 fallback)
└─ Logging/diagnostics

FieldValidationRule Entity Update
├─ DependencyPath property added
└─ Backward compatible (nullable)

Database Migration
├─ Column added to table
├─ Index created
└─ Rollback supported

Unit Tests
├─ 6 positive tests
├─ 8 negative tests
├─ 6 edge case tests
├─ 80%+ code coverage
└─ All passing ✅

Documentation
├─ XML doc comments
├─ README with examples
├─ Architecture diagram update
└─ Troubleshooting guide
```

---

**Next Phase:** Phase 2 - Dependency Resolution API (uses this service)

**Timeline:** 1-1.5 developer days (can complete in ~8-10 hours)

**Status:** ✅ Ready to start immediately

Good luck! 🚀
