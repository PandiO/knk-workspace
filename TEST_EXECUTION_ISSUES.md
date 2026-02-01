# Test Execution Issues - Summary

## Problem
Running `npm test` in the knk-web-app directory results in test failures. After investigation, I found that the Phase 7 test files have mismatches with the actual component implementations.

## Root Causes Identified

### 1. **Default vs Named Exports**
The test files import components as default exports, but the actual components use named exports:

**Files Affected:**
- ✗ `ValidationRuleBuilder.test.tsx` - imports as default, but component exports as `export const ValidationRuleBuilder`
- ✗ `ConfigurationHealthPanel.test.tsx` - imports as default, but component exports as `export const ConfigurationHealthPanel`  
- ✗ `FieldRenderer.validation.test.tsx` - imports as default from non-existent file

**Status:** FIXED for first two files (updated imports to use named exports)

### 2. **Non-existent Component Files**
- ✗ Test tries to import `FieldRenderer` from `../FieldRenderer` 
- ✓ Actual file is `FieldRenderers.tsx` (plural)

**Status:** Test file references wrong component name

### 3. **Component Props Mismatch**
The tests use different prop names/signatures than the actual components:

**ValidationRuleBuilder:**
- Test expects: `currentFieldId`, `formFields` (simple objects)
- Component expects: `field`, `availableFields` (FormFieldDto objects)

**ConfigurationHealthPanel:**
- Test expects: `formConfigurationId` (number)
- Component expects: `configurationId` (string)

**Status:** Props don't match between tests and components

### 4. **Mock Issues**
The tests try to spy on module functions that aren't properly exported:
- Mock setup: `jest.spyOn(fieldValidationRuleClient, 'validateConfigurationHealth')`
- Issue: Function may not be exported in the way the test expects

**Status:** Requires verification of actual export pattern

## Quick Fixes Applied

✅ Fixed `ValidationRuleBuilder.test.tsx` - Changed import from default to named export
✅ Fixed `ConfigurationHealthPanel.test.tsx` - Changed import from default to named export

## Remaining Issues

❌ `FieldRenderer.validation.test.tsx` - References non-existent component
❌ Component prop mismatches - Tests don't match actual component APIs
❌ Mock object exports - Need to verify actual client module exports

## Recommended Next Steps

### Option 1: Skip Phase 7 Tests (Quickest)
Delete the problematic test files and rely on manual testing:
```bash
rm src/components/FormConfigBuilder/__tests__/ValidationRuleBuilder.test.tsx
rm src/components/FormConfigBuilder/__tests__/ConfigurationHealthPanel.test.tsx
rm src/components/FormWizard/__tests__/FieldRenderer.validation.test.tsx
npm test
```

### Option 2: Fix Tests to Match Components (Recommended)
1. Update test props to match actual component APIs
2. Fix FieldRenderer.validation test to import correct component (`FieldRenderers` not `FieldRenderer`)
3. Ensure mock exports match actual client module structure
4. Run tests to validate

### Option 3: Rewrite Components to Match Tests
Requires:
- Changing component APIs to match test expectations
- Renaming components and file
- Updating all other code that imports these components

## Current Status

| Test File | Issue | Fix Needed |
|-----------|-------|-----------|
| ValidationRuleBuilder.test.tsx | Export mismatch + prop mismatch | Update props to match component API |
| ConfigurationHealthPanel.test.tsx | Export mismatch + prop mismatch | Update configurationId prop usage |
| FieldRenderer.validation.test.tsx | Wrong component name | Import FieldRenderers instead |

## What to Do Now

If you want to run tests:

```bash
cd Repository/knk-web-app

# Option A: Remove broken tests and run others
rm src/components/FormConfigBuilder/__tests__/*.test.tsx
rm src/components/FormWizard/__tests__/*.test.tsx  
npm test -- --watchAll=false

# Option B: Try to run just the ValidationRuleBuilder test
npm test -- ValidationRuleBuilder --watchAll=false
```

Would you like me to:
1. **Remove the problematic test files** so the remaining tests run? 
2. **Fix the tests** to match the actual component APIs?
3. **Rewrite the components** to match the test expectations?
4. **Check what other tests exist** that might work without changes?
