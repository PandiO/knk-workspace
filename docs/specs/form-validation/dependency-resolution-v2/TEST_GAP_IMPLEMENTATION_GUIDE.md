# Test Gap Implementation Guide - Step-by-Step

**Date:** February 16, 2026  
**Objective:** Practical guide to fill critical test gaps using AI assistance  
**Estimated Total Time:** 25 hours

---

## How to Use This Guide

For each gap, you'll find:
1. ✅ **Context to gather** - Files and data to prepare
2. 🤖 **Copilot prompt** - Exact instructions to provide
3. 📝 **Validation steps** - How to verify the generated tests work
4. 🔄 **Iteration tips** - Common issues and fixes

---

## Priority 1: PathBuilder Component Tests (CRITICAL)

**Why Critical:** Phase 5 docs claim complete but tests are missing. Component is user-facing.  
**Estimated Time:** 4 hours  
**Files Affected:** 2 new test files

### Step 1.1: Gather Context

**Files to have open or reference:**

1. Component implementation:
   ```
   Repository/knk-web-app/src/components/PathBuilder/PathBuilder.tsx
   Repository/knk-web-app/src/components/PathBuilder/SearchablePathBuilder.tsx
   Repository/knk-web-app/src/components/PathBuilder/index.ts
   ```

2. Existing test examples:
   ```
   Repository/knk-web-app/src/components/FormConfigBuilder/__tests__/ValidationRuleBuilder.test.tsx
   Repository/knk-web-app/src/components/FormWizard/__tests__/FieldRenderer.validation.test.tsx
   ```

3. Test utilities:
   ```
   Repository/knk-web-app/src/test-utils/test-helpers.tsx
   Repository/knk-web-app/src/test-utils/mockAuthClient.ts
   Repository/knk-web-app/src/setupTests.ts
   ```

4. Documentation reference:
   ```
   docs/specs/form-validation/dependency-resolution-v2/PHASE_5_IMPLEMENTATION_COMPLETE.md
   docs/specs/form-validation/dependency-resolution-v2/PHASE_5_VERIFICATION_CHECKLIST.md
   ```

### Step 1.2: Copilot Prompt Template

```
I need to create comprehensive tests for the PathBuilder component. Here's the context:

COMPONENT PURPOSE:
PathBuilder allows admins to select an entity and property to create dependency paths 
like "Town.WgRegionId". It validates paths in real-time via API and shows success/error states.

COMPONENT LOCATION: 
Repository/knk-web-app/src/components/PathBuilder/PathBuilder.tsx

TEST REQUIREMENTS (from Phase 5 docs):
1. Component rendering tests (all form elements present)
2. Entity/property dropdown selection
3. Real-time path validation (debounced 300ms)
4. Success/error/pending state display
5. Keyboard navigation support
6. Responsive design (mobile, tablet, desktop)
7. Error recovery scenarios
8. Props validation (required, disabled, onChange)

SIMILAR TEST PATTERN TO FOLLOW:
[Paste ValidationRuleBuilder.test.tsx as reference]

API MOCKS NEEDED:
- GET /api/metadata/entities - returns list of entities
- GET /api/metadata/entities/{entityName}/properties - returns properties
- POST /api/validation/validate-path - validates dependency path

PLEASE GENERATE:
Create PathBuilder.test.tsx with 13 test cases covering all requirements above.
Use React Testing Library, Jest, and MSW for API mocking.
Follow the existing test patterns in the codebase.
```

### Step 1.3: Review Generated Code

**Check these items:**

✅ Test file structure matches existing patterns  
✅ All 13 test cases present  
✅ API mocks use MSW (or similar)  
✅ Imports are correct  
✅ Test utilities are used correctly  
✅ Assertions use `screen`, `waitFor`, `userEvent`

### Step 1.4: Run and Validate

```bash
# Navigate to web app
cd Repository/knk-web-app

# Run specific test file
npm test PathBuilder.test.tsx

# Expected output:
# PASS  src/components/PathBuilder/__tests__/PathBuilder.test.tsx
#   PathBuilder Component
#     ✓ renders entity and property dropdowns (45ms)
#     ✓ validates path on selection (312ms)
#     ... (11 more tests)
# 
# Tests: 13 passed, 13 total
```

### Step 1.5: Iteration Tips

**Common Issue 1: API mocks not working**
```typescript
// Fix: Ensure MSW handlers are setup correctly
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/metadata/entities', (req, res, ctx) => {
    return res(ctx.json([
      { name: 'Town', displayName: 'Town' },
      { name: 'District', displayName: 'District' }
    ]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Common Issue 2: Debounce not working in tests**
```typescript
// Fix: Use fake timers
jest.useFakeTimers();

// After user input
await userEvent.type(screen.getByRole('combobox'), 'Town');
jest.advanceTimersByTime(300); // Advance past debounce

await waitFor(() => {
  expect(mockValidateApi).toHaveBeenCalled();
});

jest.useRealTimers();
```

**Common Issue 3: Component not rendering**
```typescript
// Fix: Check if component needs props
render(<PathBuilder 
  value=""
  onChange={mockOnChange}
  formConfigId={1}
/>);
```

### Step 1.6: Repeat for SearchablePathBuilder

Use the same process for `SearchablePathBuilder.test.tsx` with 8 tests.

---

## Priority 2: Cypress E2E Tests (CRITICAL)

**Why Critical:** Zero E2E coverage = high regression risk  
**Estimated Time:** 8 hours  
**Files Affected:** 5-6 new Cypress test files

### Step 2.1: Setup Cypress Infrastructure

**First, verify Cypress is configured:**

```bash
cd Repository/knk-web-app
npm ls cypress
# If not installed:
# npm install --save-dev cypress @testing-library/cypress
```

**Create Cypress folder structure:**

```bash
mkdir -p cypress/e2e/form-validation
mkdir -p cypress/support
mkdir -p cypress/fixtures
```

### Step 2.2: Gather Context

**Files needed:**

1. Manual test scenario documentation:
   ```
   docs/specs/form-validation/dependency-resolution-v2/PHASE_8_TEST_GUIDE.md
   (Section: Manual Test Scenario - 11 steps)
   ```

2. API endpoints to interact with:
   ```
   POST /api/auth/login
   GET /api/form-configurations/{id}
   GET /api/form-steps?configId={id}
   GET /api/form-fields?stepId={id}
   POST /api/validation/validate-field
   POST /api/world-tasks
   PUT /api/world-tasks/{id}/complete
   POST /api/districts
   ```

3. Database seed data needed:
   ```
   - FormConfiguration ID 2 (District Management)
   - FormStep ID 5 (Location & Region)
   - FormField IDs 9, 10, 11
   - Town ID 3 ("Cinix" with WgRegionId)
   - Validation rules for region containment
   ```

4. Existing Cypress examples (if any):
   ```
   cypress/e2e/ (check for any existing tests as patterns)
   ```

### Step 2.3: Copilot Prompt for District Creation E2E

```
I need to create a Cypress E2E test for the District creation workflow with validation.

TEST SCENARIO (from manual testing):
An admin user creates a new District with the following flow:
1. Login as admin
2. Navigate to /districts/create
3. Fill basic info in steps 1-4 (Name, Description, etc.)
4. Reach Step 5: Location & Region
5. Select "Town" field → Choose existing town "Cinix" (ID 3)
   - Town has WgRegionId: "tempregion_worldtask_17"
6. Click WorldTask button for "WgRegionId" field
   - Modal opens showing pending task
   - Admin completes task in Minecraft (simulated)
   - Task completes with value: "tempregion_worldtask_74"
7. Backend validates: "tempregion_worldtask_74" is inside "tempregion_worldtask_17"
   - Validation passes ✓
   - Success message shows
8. Fill "Location" field via WorldTask
   - Value: {x: 100, y: 64, z: 200, world: "world"}
9. **CRITICAL:** Re-validation of WgRegionId should still pass
   - Bug found: dependency value became null
   - Fix implemented: backend extracts from formContextData
10. Click "Next" button
11. Form progresses to Step 6

FILE LOCATION: cypress/e2e/form-validation/district-creation-flow.cy.ts

CYPRESS COMMANDS NEEDED:
- cy.login() - custom command for auth
- cy.visit()
- cy.get/findByRole/findByLabelText
- cy.type()
- cy.select() or cy.click() for dropdowns
- cy.intercept() for API mocking/monitoring
- cy.wait() for API calls
- cy.url().should() for navigation assertions

API INTERCEPTS:
- POST /api/validation/validate-field (monitor validation calls)
- POST /api/world-tasks (create WorldTask)
- PUT /api/world-tasks/{id}/complete (complete task)
- GET /api/regions/*/contains-region/* (region validation)

ASSERTIONS:
- Validation indicator shows success (green checkmark)
- Error messages appear/disappear correctly
- Next button enabled/disabled based on validation
- Form data persists across steps
- URL changes on successful navigation

PLEASE GENERATE:
Complete Cypress test file with proper setup, teardown, and all 11 steps.
Include API intercepts for monitoring and assertions.
Use Cypress best practices (data-testid attributes, proper waiting).
```

### Step 2.4: Custom Commands Setup

Before running E2E tests, you'll need custom commands. Provide this prompt:

```
Create Cypress custom commands file for common operations:

FILE: cypress/support/commands.ts

COMMANDS NEEDED:
1. cy.login(email, password) - Authenticates user, stores token
2. cy.selectDropdown(label, value) - Clicks dropdown and selects value
3. cy.clickWorldTask(fieldName) - Opens WorldTask modal for field
4. cy.completeWorldTask(taskId, outputValue) - Simulates task completion
5. cy.waitForValidation(fieldId, expectedState) - Waits for validation result
6. cy.fillFormStep(stepNumber, data) - Fills all fields in a form step

EXAMPLE IMPLEMENTATION for cy.login():
Cypress.Commands.add('login', (email: string, password: string) => {
  cy.request({
    method: 'POST',
    url: '/api/auth/login',
    body: { email, password }
  }).then((response) => {
    window.localStorage.setItem('authToken', response.body.token);
    window.localStorage.setItem('user', JSON.stringify(response.body.user));
  });
});

PLEASE GENERATE:
All 6 custom commands with TypeScript types and proper error handling.
```

### Step 2.5: Run E2E Tests

```bash
cd Repository/knk-web-app

# Option 1: Interactive mode (with UI)
npm run cypress:open

# Option 2: Headless mode (CI-friendly)
npm run cypress:run

# Option 3: Specific test file
npx cypress run --spec "cypress/e2e/form-validation/district-creation-flow.cy.ts"
```

### Step 2.6: Iteration Tips for Cypress

**Common Issue 1: Element not found**
```typescript
// Bad: Too generic
cy.get('button').click();

// Good: Use data-testid
cy.get('[data-testid="next-button"]').click();

// Better: Use semantic queries
cy.findByRole('button', { name: /next/i }).click();
```

**Common Issue 2: Timing issues**
```typescript
// Bad: Arbitrary wait
cy.wait(2000);

// Good: Wait for specific condition
cy.wait('@validateField'); // Waits for intercepted API call
cy.get('[data-testid="validation-success"]').should('be.visible');
```

**Common Issue 3: Test data not reset**
```typescript
// Add before hook to reset database
beforeEach(() => {
  cy.request('POST', '/api/test/reset-database');
  cy.request('POST', '/api/test/seed-test-data');
});
```

### Step 2.7: Additional E2E Tests

**Repeat the process for:**

1. **Form Builder Workflow** (4 hours)
   - Create FormConfig → Add Steps → Add Fields → Add Validation Rules
   
2. **Health Panel Integration** (2 hours)
   - Open health panel → View issues → Auto-refresh on changes

3. **Error Recovery** (2 hours)
   - Network error → Retry → Success
   - Invalid dependency → Fix → Validate

---

## Priority 3: Plugin HTTP Endpoint Tests (CRITICAL)

**Why Critical:** New Phase 8 endpoint has zero tests  
**Estimated Time:** 3 hours  
**Files Affected:** 2 new test files

### Step 3.1: Gather Context

**Files needed:**

1. Implementation to test:
   ```
   Repository/knk-plugin-v2/knk-paper/src/main/java/.../tasks/RegionHttpServer.java
   Repository/knk-plugin-v2/knk-paper/src/main/java/.../tasks/WgRegionIdTaskHandler.java
   ```

2. Existing test examples:
   ```
   Repository/knk-plugin-v2/knk-core/src/test/java/... (any existing tests)
   ```

3. Test dependencies (check build.gradle.kts):
   ```
   JUnit 5
   Mockito
   MockBukkit (if available)
   ```

### Step 3.2: Copilot Prompt for Plugin Tests

```
I need to create unit tests for the RegionContainmentHandler HTTP endpoint.

IMPLEMENTATION CONTEXT:
- File: RegionHttpServer.java (lines 120-165)
- Endpoint: GET /api/regions/{parentId}/contains-region/{childId}?requireFullContainment=true
- Handler: RegionContainmentHandler class
- Delegates to: WgRegionIdTaskHandler.checkRegionContainment()
- Returns: Plain text "true" or "false"
- Thread safety: Uses Bukkit scheduler for WorldGuard API calls

CODE SNIPPET:
[Paste RegionContainmentHandler class]

TEST REQUIREMENTS:
1. Valid parent and child regions → Returns "true" (200 OK)
2. Child region NOT contained → Returns "false" (200 OK)
3. Parent region not found → Returns 404 with error message
4. Child region not found → Returns 404 with error message
5. Invalid region IDs (special characters) → Returns 400
6. requireFullContainment parameter variations
7. Thread safety (concurrent requests)
8. World not found error handling

TEST FILE: 
Repository/knk-plugin-v2/knk-paper/src/test/java/.../tasks/RegionContainmentHandlerTest.java

MOCKING NEEDED:
- WorldGuardPlugin (mock WorldGuard API)
- RegionManager (mock region lookups)
- ProtectedRegion (mock region containment checks)
- Bukkit Scheduler (mock sync task execution)

TESTING FRAMEWORK:
Use JUnit 5 with Mockito. If MockBukkit is available, use it for Bukkit mocking.

PLEASE GENERATE:
Complete test class with @BeforeEach setup, all 8 test cases, and proper assertions.
Use parameterized tests where appropriate for multiple similar scenarios.
```

### Step 3.3: Copilot Prompt for Integration Test

```
I need an integration test that verifies the complete validation flow from backend to plugin.

SCENARIO:
1. Backend ValidationService calls RegionContainmentValidator
2. RegionContainmentValidator extracts parent region ID from dependency (Town.WgRegionId)
3. RegionContainmentValidator extracts child region ID from field value (District.WgRegionId)
4. RegionContainmentValidator calls IRegionService.IsRegionContainedAsync()
5. RegionService makes HTTP GET to plugin: /api/regions/{parent}/contains-region/{child}
6. Plugin's RegionContainmentHandler processes request
7. WgRegionIdTaskHandler checks WorldGuard region containment
8. Result returned through chain: Plugin → Backend → Validator → ValidationService

TEST FILE:
Repository/knk-plugin-v2/knk-paper/src/test/java/.../integration/ValidationIntegrationTest.java

SETUP REQUIRED:
- Embedded HTTP server for plugin endpoint
- Mock WorldGuard with test regions
- Test regions: "parent_region" (10x10 area), "child_region" (5x5 inside parent)

TEST CASES:
1. Happy path: child fully inside parent → Returns true
2. Partial overlap: child partially outside → Returns false (when requireFullContainment=true)
3. No overlap: child completely outside → Returns false
4. Parent doesn't exist → Returns 404
5. Child doesn't exist → Returns 404

PLEASE GENERATE:
Integration test class with embedded server setup and all 5 test cases.
Use real HTTP calls (not mocked) to test the full stack.
```

### Step 3.4: Run Plugin Tests

```bash
cd Repository/knk-plugin-v2

# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests "RegionContainmentHandlerTest"

# Run with detailed output
./gradlew test --info

# Generate coverage report
./gradlew test jacocoTestReport
# Report at: build/reports/jacoco/test/html/index.html
```

### Step 3.5: Iteration Tips for Plugin Tests

**Common Issue 1: Bukkit API not mockable**
```java
// Use MockBukkit for Bukkit server simulation
@BeforeEach
void setUp() {
    server = MockBukkit.mock();
    plugin = MockBukkit.load(YourPlugin.class);
}

@AfterEach
void tearDown() {
    MockBukkit.unmock();
}
```

**Common Issue 2: WorldGuard dependency**
```java
// Mock WorldGuard plugin
WorldGuardPlugin wg = mock(WorldGuardPlugin.class);
RegionManager rm = mock(RegionManager.class);
when(wg.getRegionManager(any())).thenReturn(rm);
```

**Common Issue 3: Async task execution**
```java
// Use Mockito's ArgumentCaptor for scheduler tasks
ArgumentCaptor<Callable<Boolean>> taskCaptor = 
    ArgumentCaptor.forClass(Callable.class);
    
verify(scheduler).callSyncMethod(eq(plugin), taskCaptor.capture());

// Execute captured task synchronously
Boolean result = taskCaptor.getValue().call();
```

---

## Priority 4: Performance Test Automation (IMPORTANT)

**Why Important:** Manual tests exist but no CI automation  
**Estimated Time:** 4 hours  
**Files Affected:** 2 new projects/scripts

### Step 4.1: Setup Benchmark.NET (Backend)

**Create benchmark project:**

```bash
cd Repository
dotnet new console -n knkwebapi_v2.Benchmarks
cd knkwebapi_v2.Benchmarks
dotnet add package BenchmarkDotNet
dotnet add reference ../knk-web-api-v2/knkwebapi_v2.csproj
```

### Step 4.2: Copilot Prompt for Benchmark Tests

```
I need to create Benchmark.NET performance tests for validation services.

BENCHMARKS NEEDED:
1. Single field validation (target: <50ms p95)
2. Batch validation of 10 rules (target: <100ms p95)
3. Batch validation of 100 rules (target: <200ms p95)
4. Path resolution single-hop (target: <10ms p95)
5. Dependency resolution with 5 dependencies (target: <50ms p95)

PROJECT: Repository/knkwebapi_v2.Benchmarks/Program.cs

SERVICES TO BENCHMARK:
- IValidationService.ValidateFieldAsync()
- IValidationService.ValidateBatchAsync()
- IPathResolutionService.ResolvePathAsync()
- IDependencyResolutionService.ResolveDependenciesAsync()

SETUP REQUIREMENTS:
- In-memory database for realistic data access
- Mock validation methods for consistency
- Realistic form context data (1KB-10KB JSON)

BENCHMARK CONFIGURATION:
- Warmup: 3 iterations
- Iterations: 10
- Invocation count: Auto
- Memory diagnoser: Enabled
- Statistics: Mean, StdDev, P95, P99

EXAMPLE STRUCTURE:
```csharp
[MemoryDiagnoser]
[SimpleJob(warmupCount: 3, iterationCount: 10)]
public class ValidationBenchmarks
{
    private IValidationService _service;
    private Dictionary<string, object> _formContext;

    [GlobalSetup]
    public void Setup()
    {
        // Initialize services
        // Create realistic test data
    }

    [Benchmark]
    public async Task<ValidationResultDto> ValidateField_SingleRule()
    {
        return await _service.ValidateFieldAsync(9, "test-value", null, _formContext);
    }
}
```

PLEASE GENERATE:
Complete benchmark program with all 5 benchmarks and proper setup/teardown.
Include comments explaining each benchmark's purpose and target performance.
```

### Step 4.3: Setup K6 Load Testing (HTTP Endpoints)

**Install K6:**

```bash
# Windows (via Chocolatey)
choco install k6

# Or download from: https://k6.io/docs/getting-started/installation/
```

### Step 4.4: Copilot Prompt for K6 Scripts

```
I need to create K6 load test scripts for the validation API endpoints.

ENDPOINTS TO TEST:
1. POST /api/validation/validate-field
2. POST /api/validation/validate-batch
3. GET /api/validation/rules?formConfigId={id}
4. POST /api/validation/health-check

LOAD TEST SCENARIOS:
1. Ramp-up: 0 → 50 → 100 users over 2 minutes
2. Sustained: 100 users for 5 minutes
3. Spike: 0 → 200 users in 10 seconds, hold 30s, ramp down

TARGET THRESHOLDS:
- p95 latency < 200ms
- p99 latency < 500ms
- Error rate < 1%
- Successful requests > 95%

FILE: tests/load/validation-load-test.js

EXAMPLE STRUCTURE:
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const payload = JSON.stringify({
    fieldId: 9,
    fieldValue: 'test-value',
    formContextData: { /* ... */ }
  });

  const response = http.post('http://localhost:5000/api/validation/validate-field', payload);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);
}
```

PLEASE GENERATE:
Complete K6 script with all 4 endpoints, realistic payloads, and proper thresholds.
Include comments for configuration options and how to run the test.
```

### Step 4.5: Run Performance Tests

**Benchmark.NET:**
```bash
cd Repository/knkwebapi_v2.Benchmarks
dotnet run -c Release

# Output:
# | Method                    | Mean      | StdDev   | P95    | Allocated |
# |-------------------------- |----------:|---------:|-------:|----------:|
# | ValidateField_SingleRule  | 12.34 ms  | 1.2 ms   | 14 ms  | 2.1 KB    |
# | ValidateBatch_100Rules    | 187.5 ms  | 8.3 ms   | 195 ms | 45.2 KB   |
```

**K6:**
```bash
# Ensure API is running
cd Repository/knk-web-api-v2
dotnet run

# In another terminal
cd tests/load
k6 run validation-load-test.js

# Output:
# ✓ status is 200
# ✓ response time < 200ms
# 
# checks.........................: 100.00% ✓ 12450 ✗ 0
# http_req_duration..............: avg=89ms min=12ms med=78ms max=245ms p(95)=187ms
```

### Step 4.6: CI Integration

**Add to GitHub Actions workflow:**

```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests

on:
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  benchmark:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Run Benchmarks
        run: |
          cd Repository/knkwebapi_v2.Benchmarks
          dotnet run -c Release -- --exporters json
      
      - name: Check Performance Regression
        run: |
          # Compare results with baseline
          # Fail if p95 > 200ms for batch validation
```

---

## Validation Checklist

After generating each test suite, validate:

### Backend Tests
- [ ] All tests pass: `dotnet test`
- [ ] Coverage ≥ 80%: Check Coverlet report
- [ ] No flaky tests: Run 3 times, all pass
- [ ] CI passes: Push to branch, check GitHub Actions

### Frontend Tests  
- [ ] All tests pass: `npm test`
- [ ] Coverage ≥ 70%: `npm run test:coverage`
- [ ] No console errors during tests
- [ ] Snapshots (if any) are intentional

### E2E Tests
- [ ] All tests pass: `npm run cypress:run`
- [ ] Tests run in < 5 minutes total
- [ ] No flaky tests: Run 3 times, all pass
- [ ] Screenshots/videos captured on failure

### Plugin Tests
- [ ] All tests pass: `./gradlew test`
- [ ] Coverage report generated: `./gradlew jacocoTestReport`
- [ ] Integration tests connect to real HTTP endpoint
- [ ] No Bukkit warnings in test output

### Performance Tests
- [ ] Benchmarks complete without errors
- [ ] p95 latencies meet targets
- [ ] K6 tests achieve > 95% success rate
- [ ] Results exported for tracking

---

## Common Pitfalls & Solutions

### Pitfall 1: Generated Tests Don't Match Existing Patterns

**Problem:** Copilot generates tests in a different style than your codebase.

**Solution:**
```
Add to your prompt:
"IMPORTANT: Follow the exact patterns from this existing test file:
[Paste 50-100 lines of a good existing test as example]
Match:
- Import statements
- Test structure (describe/it vs [Fact])
- Assertion library (expect() vs .Should())
- Mock setup patterns
- Before/after hooks
"
```

### Pitfall 2: API Mocks Don't Work

**Problem:** Tests fail because API calls aren't mocked.

**Solution:**
```
For backend (C#):
- Use Moq: mock.Setup(x => x.Method()).ReturnsAsync(result)

For frontend (React):
- Use MSW: setupServer(rest.get('/api/...', (req, res, ctx) => res(ctx.json(data))))

For E2E (Cypress):
- Use cy.intercept(): cy.intercept('POST', '/api/validation/*', { fixture: 'validation-success.json' })
```

### Pitfall 3: Tests Are Too Slow

**Problem:** Test suite takes > 10 minutes.

**Solution:**
- Use in-memory databases (backend)
- Mock expensive operations (API calls, file I/O)
- Run tests in parallel where possible
- Use test.only() during development, remove before commit

### Pitfall 4: Flaky Tests (Sometimes Pass, Sometimes Fail)

**Problem:** E2E tests fail randomly.

**Solution:**
```typescript
// Bad: Race condition
cy.click('[data-testid="submit"]');
cy.url().should('include', '/success');

// Good: Wait for specific condition
cy.intercept('POST', '/api/submit').as('submitRequest');
cy.click('[data-testid="submit"]');
cy.wait('@submitRequest');
cy.url().should('include', '/success');
```

---

## Time Estimates by Role

### If You're a Backend Developer:
- PathBuilder tests: 6 hours (unfamiliar with React Testing Library)
- E2E tests: 10 hours (learning Cypress)
- Plugin tests: **2 hours** ✅ (fastest)
- Performance tests: **3 hours** ✅ (familiar with .NET)

### If You're a Frontend Developer:
- PathBuilder tests: **2 hours** ✅ (fastest)
- E2E tests: **4 hours** ✅ (familiar with Cypress)
- Plugin tests: 8 hours (learning Java/Bukkit)
- Performance tests: 6 hours (unfamiliar with Benchmark.NET)

### If You're a Full-Stack Developer:
- PathBuilder tests: **3 hours**
- E2E tests: **5 hours**
- Plugin tests: **4 hours**
- Performance tests: **4 hours**

---

## Quick Start Recommendations

**Week 1 Focus** (if you only have 10-15 hours):

1. **Day 1 (3h):** PathBuilder.test.tsx + SearchablePathBuilder.test.tsx
2. **Day 2 (4h):** District creation E2E test
3. **Day 3 (3h):** Plugin RegionContainmentHandler tests
4. **Day 4 (2h):** Run all tests, fix issues
5. **Day 5 (3h):** Documentation and CI integration

This covers the absolute critical gaps and gives you ~70% risk reduction.

**Week 2 Focus** (if you have another 10-15 hours):

1. Form Builder E2E test
2. Health Panel E2E test  
3. Performance test automation
4. Additional frontend hook tests

---

## Getting Help from Copilot

### For Best Results:

1. **Provide Context:**
   - Paste the component/function you're testing
   - Show 1-2 similar existing tests as examples
   - Specify the testing framework and libraries used

2. **Be Specific:**
   - "Generate 13 test cases" not "generate tests"
   - List exact scenarios to cover
   - Specify assertion patterns to use

3. **Iterate:**
   - Start with 2-3 tests, review, adjust prompt
   - Then generate the full suite
   - Don't accept all suggestions blindly

4. **Validate:**
   - Always run the generated tests
   - Check coverage reports
   - Review for logic errors, not just syntax

### Example Workflow:

```
You: "Generate PathBuilder.test.tsx following this example: [paste existing test]"
Copilot: [Generates 13 tests]
You: Run tests → 11 pass, 2 fail
You: "Fix tests 5 and 7, they fail with 'element not found'. The dropdown is a custom component, not a native select."
Copilot: [Provides fixes]
You: Run tests → All 13 pass ✅
You: "Add one more test for keyboard focus management"
Copilot: [Adds test #14]
```

---

## Summary

**Total Estimated Time to Fill Critical Gaps:** 15-25 hours  
**ROI:** High - Reduces regression risk by ~70%, eliminates most manual testing needs  
**Complexity:** Medium - Requires learning 2-3 new testing tools  
**Copilot Assistance:** High - Can generate 60-80% of code with good prompts  

**Start here:** PathBuilder tests (easiest win, 2-4 hours)  
**Then:** District creation E2E (highest risk reduction, 4 hours)  
**Finally:** Plugin tests (closes all critical gaps, 3 hours)

After these 3 items, you'll have raised test coverage from "good" to "excellent" and can deploy with confidence.
