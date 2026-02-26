# Phase 8: Region Containment Validation - Test Guide

**Feature:** dependency-resolution-v2  
**Phase:** 8 - Bug Fixes and Integration Tests  
**Date:** February 16, 2026

---

## Overview

This guide covers the standardized, repeatable tests for the District creation scenario with region containment validation that was manually tested and fixed in Phase 8.

## Manual Test Scenario (Original)

The following 11-step scenario was used to identify the bugs:

### Prerequisites
1. Backend API running (`api: watch` task)
2. Frontend web app running (`npm: start` task)
3. Minecraft server with plugin running
4. Database seeded with:
   - FormConfiguration ID 2 (District Management)
   - FormStep ID 5 (Location & Region)
   - FormField ID 11 (Town - select)
   - FormField ID 9 (WgRegionId - worldtask)
   - FormField ID 10 (Location - worldtask)
   - Existing Town with ID 3 ("Cinix") having WgRegionId "tempregion_worldtask_17"

### Steps
1. Admin user navigates to District creation form
2. Proceeds through steps 1-4 (basic info, etc.)
3. Reaches Step 5: Location & Region
4. **Validation 1:** All fields empty → Validation pending (expected)
5. Fills **Town** field, selecting existing town "Cinix" (ID 3)
6. **Validation 2:** WgRegionId empty → Field validation runs, fails correctly
7. Clicks WorldTask button for **WgRegionId** field
8. In Minecraft, creates region "tempregion_worldtask_74" inside parent region
9. **Validation 3:** WgRegionId filled with "tempregion_worldtask_74" → Should validate region is inside "tempregion_worldtask_17" → **PASSES** ✓
10. Fills **Location** field using WorldTask (sets X/Y/Z coordinates)
11. **Validation 4:** WgRegionId re-validates → **BUG: FAILS** with `dependencyValue: null` ❌

### Expected Behavior
All validations after step 9 should continue to pass, as the Town dependency data remains in formContextData.

### Actual Behavior (Before Fix)
Validation failed at step 11 because:
- Frontend sends only `formContextData` without extracting `dependencyValue`
- Backend's `ValidationService.ExecuteValidationRuleAsync()` didn't extract dependency from context
- Result: `dependencyValue` was null despite Town object present in formContextData

---

## Automated Integration Tests

### Test Location
```
Repository/knkwebapi_v2.Tests/Integration/DependencyResolutionE2ETests.cs
```

### Test Cases Added

#### 1. `DistrictCreation_WithRegionContainment_ValidatesDependencyConsistently`

**Purpose:** Replicates the exact 11-step manual scenario as an automated test.

**What It Tests:**
- Validation 1: WgRegionId empty with Town filled → Should fail
- Validation 2: WgRegionId filled → Should pass with region containment check
- Validation 3: After filling Location field → Should **still pass** (critical regression test)
- Verifies backend auto-extracts dependency value from formContextData

**Assertions:**
```csharp
validation3.IsValid.Should().BeTrue(
    "Dependency value should be auto-extracted from formContextData"
);
```

#### 2. `DependencyExtraction_WithCaseInsensitiveProperties_ExtractsCorrectly`

**Purpose:** Tests case-insensitive property path resolution.

**What It Tests:**
- JSON data uses camelCase: `"wgRegionId"`
- Config specifies PascalCase: `"WgRegionId"`
- Backend should extract property regardless of case mismatch

**Assertions:**
```csharp
result.IsValid.Should().BeTrue(
    "Case-insensitive property extraction should succeed"
);
```

---

## Running the Tests

### From Command Line

```powershell
# Navigate to test project
cd Repository/knkwebapi_v2.Tests

# Run all Phase 8 tests
dotnet test --filter "FullyQualifiedName~DependencyResolutionE2ETests" --logger "console;verbosity=detailed"

# Run specific test
dotnet test --filter "FullyQualifiedName~DistrictCreation_WithRegionContainment_ValidatesDependencyConsistently"

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"
```

### From Visual Studio

1. Open Test Explorer (Test → Test Explorer)
2. Navigate to: `knkwebapi_v2.Tests → Integration → DependencyResolutionE2ETests`
3. Right-click test class → "Run"
4. Or run individual tests

### From VS Code

1. Install .NET Test Explorer extension
2. Open Test Explorer sidebar
3. Expand `knkwebapi_v2.Tests → Integration`
4. Click play button next to desired test

---

## Test Data Setup

Tests use in-memory database with auto-seeded data via `SeedDistrictFormWithRegionValidation()`:

```csharp
FormConfiguration ID 2: "District Management"
├── FormStep ID 5: "Step 5: Location & Region"
    ├── FormField ID 11: "Town" (select, depends on nothing)
    ├── FormField ID 9: "WgRegionId" (worldtask, depends on Town.WgRegionId)
    └── FormField ID 10: "Location" (worldtask, depends on nothing)

FieldValidationRule ID 99:
- Field: 9 (WgRegionId)
- Type: "RegionContainment"
- DependsOnFieldId: 11 (Town)
- DependencyPath: "Town.WgRegionId"
- RequiresDependencyFilled: true
```

Mock data:
```json
{
  "Town": {
    "id": 3,
    "name": "Cinix",
    "description": "Test Town",
    "wgRegionId": "tempregion_worldtask_17"
  },
  "WgRegionId": "tempregion_worldtask_74",
  "Location": {
    "x": 100,
    "y": 64,
    "z": 200,
    "world": "world"
  }
}
```

---

## Verification Checklist

After running tests, verify:

- [x] **Test 1 passes:** All three validations execute with correct IsValid state
- [x] **Test 2 passes:** Case-insensitive property extraction works
- [x] **No null reference exceptions** in ValidationService
- [x] **Mock validator called** with non-null dependency value (3rd validation)
- [x] **Test coverage** shows ValidationService.ExecuteValidationRuleAsync lines 509-530 covered

---

## Debugging Failed Tests

### Common Failures

**1. "Dependency not extracted"**
- Cause: ValidationService not extracting from formContextData
- Fix: Check ValidationService.cs lines 509-520 for extraction logic
- Verify: `rule.DependsOnField.FieldName` matches formContextData key

**2. "Wrong region extracted"**
- Cause: Case-sensitive property lookup
- Fix: Ensure RegionContainmentValidator uses `StringComparison.OrdinalIgnoreCase`
- Verify: `ExtractPropertyValue()` method logic

**3. "Test timeout"**
- Cause: Infinite loop in dependency resolution
- Fix: Check for circular dependency detection
- Verify: DependencyResolutionService circular dependency logic

### Enable Debug Logging

In test code, add:
```csharp
// Before Act section
Console.WriteLine($"[TEST] FormContextData: {JsonSerializer.Serialize(formContextData)}");
Console.WriteLine($"[TEST] Validation starting for field {wgRegionField.Id}");
```

Backend already has trace logging (look for `[VALIDATION_TRACE_BACKEND]` in output).

---

## Continuous Integration

### GitHub Actions (Future)

```yaml
name: Backend Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      - name: Run Phase 8 Tests
        run: |
          cd Repository/knkwebapi_v2.Tests
          dotnet test --filter "FullyQualifiedName~DependencyResolutionE2ETests" --logger trx
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: '**/*.trx'
```

### Pre-Commit Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
cd Repository/knkwebapi_v2.Tests
dotnet test --filter "FullyQualifiedName~DependencyResolutionE2ETests" --no-build
if [ $? -ne 0 ]; then
    echo "Phase 8 tests failed. Commit aborted."
    exit 1
fi
```

---

## Test Maintenance

### When to Update Tests

Update these tests when:
1. **FormField structure changes** → Update `SeedDistrictFormWithRegionValidation()`
2. **Validation logic changes** → Update mock validator behavior
3. **New dependency extraction edge cases** → Add new test cases
4. **API contract changes** → Update ValidateFieldAsync calls

### Adding New Test Cases

Follow this pattern:
```csharp
[Fact]
public async Task YourScenarioName_WithCondition_ExpectedOutcome()
{
    // Arrange - Seed data
    var config = SeedDistrictFormWithRegionValidation();
    var formContextData = new Dictionary<string, object>();
    
    // Act - Execute validation
    var result = await _validationService.ValidateFieldAsync(...);
    
    // Assert - Verify behavior
    result.IsValid.Should().BeTrue("reason why it should pass");
}
```

---

## Related Documentation

- [PHASE_8_IMPLEMENTATION_SUMMARY.md](./PHASE_8_IMPLEMENTATION_SUMMARY.md) - Full implementation details
- [Backend Instructions](../../../.github/instructions/knk-backend.instructions.md) - Backend conventions
- [Git Conventions](../../../GIT_COMMIT_CONVENTIONS.md) - Commit message format

---

## Summary

**Standardized Test Suite:**
- ✅ Automated end-to-end test for 11-step District creation scenario
- ✅ Case-insensitive property extraction regression test
- ✅ Mock-based validation for isolated unit testing
- ✅ In-memory database for fast execution
- ✅ Detailed documentation for maintenance

**Run Command:**
```powershell
dotnet test --filter "FullyQualifiedName~DependencyResolutionE2ETests"
```

**Expected Output:**
```
Test Run Successful.
Total tests: 2
     Passed: 2
```
