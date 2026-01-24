# Field Validation System - Manual QA Testing Guide

**Version:** 1.0  
**Created:** January 24, 2026  
**Purpose:** Comprehensive manual testing guide for cross-field validation features

---

## Table of Contents
1. [Test Environment Setup](#test-environment-setup)
2. [Test Scenarios](#test-scenarios)
3. [Success Criteria](#success-criteria)
4. [Bug Reporting Template](#bug-reporting-template)

---

## Test Environment Setup

### Prerequisites
- Local development environment running with both backend API and frontend app
- Access to FormConfigBuilder and FormWizard components
- Database with test form configurations
- Postman or similar tool for API testing (optional)

### Initial Data
Execute the following steps to create test data:

1. **Create Test Form Configuration:**
   - Name: "District Creation Test"
   - Steps: Basic Info, Location Details
   
2. **Create Test Fields (Basic Info Step):**
   - Field 1: "District Name" (text, required, order 0)
   - Field 2: "Town" (dropdown/number, required, order 1)
   - Field 3: "Town Ruler" (text, optional, order 2)

3. **Create Test Fields (Location Details Step):**
   - Field 4: "Location ID" (number, optional, order 0)
   - Field 5: "Coordinates" (text, optional, order 1)

---

## Test Scenarios

### Scenario 1: Create ConditionalRequired Validation Rule

**Objective:** Verify ability to create and configure conditional required validation

**Steps:**
1. Navigate to FormConfigBuilder
2. Open "District Creation Test" configuration
3. Edit "Town Ruler" field (Field 3)
4. Click "+ Add Validation Rule"
5. ValidationRuleBuilder opens
6. Select validation type: "ConditionalRequired"
7. Select dependency field: "Town"
8. In ConfigJson editor, verify template auto-populated:
   ```json
   {
     "condition": {
       "operator": "equals",
       "value": ""
     }
   }
   ```
9. Set value to "CityTown"
10. Enter error message: "Town Ruler is required when Town is CityTown"
11. Click Save

**Success Criteria:**
- ✅ Rule created successfully
- ✅ Rule appears in "Town Ruler" field's validation list
- ✅ ConfigJson is valid JSON
- ✅ All fields populated correctly

**Expected Result:** ConditionalRequired validation rule created and associated with Town Ruler field

---

### Scenario 2: Create LocationInsideRegion Validation Rule

**Objective:** Verify location-constrained validation setup

**Steps:**
1. Navigate to FormConfigBuilder
2. Open "District Creation Test" configuration
3. Edit "Location ID" field (Field 4)
4. Click "+ Add Validation Rule"
5. Select validation type: "LocationInsideRegion"
6. Select dependency field: "Town"
7. Verify ConfigJson template:
   ```json
   {
     "regionPropertyPath": "WgRegionId",
     "allowBoundary": false
   }
   ```
8. Set error message: "Location must be within the Town's region"
9. Check "Is Blocking" checkbox
10. Click Save

**Success Criteria:**
- ✅ Rule created and saved
- ✅ Rule associated with Location ID field
- ✅ Is Blocking checkbox is checked
- ✅ Configuration Health Panel shows no errors

**Expected Result:** LocationInsideRegion validation rule configured

---

### Scenario 3: Field Dependency Ordering Validation

**Objective:** Verify Configuration Health Panel detects incorrect field ordering

**Steps:**
1. In FormConfigBuilder, reorder fields in Basic Info step:
   - Change "Town Ruler" order to 0
   - Change "Town" order to 1
   - Change "District Name" order to 2
2. Open Configuration Health Panel at bottom
3. Observe health check results
4. Click "Refresh" button

**Success Criteria:**
- ✅ Health Panel displays warning:
  "Field 'Town Ruler' depends on 'Town' which comes AFTER it. Reorder fields for proper validation."
- ✅ Warning severity is "Warning" (yellow)
- ✅ Field and rule IDs are displayed

**Expected Result:** Health check detects and reports field ordering issue

---

### Scenario 4: Circular Dependency Detection

**Objective:** Verify system prevents circular validation dependencies

**Steps:**
1. In FormConfigBuilder, create test setup:
   - Field A with validation rule depending on Field B
2. Try to add validation rule to Field B depending on Field A
3. Attempt to save

**Success Criteria:**
- ✅ System shows error: "Circular dependency detected between fields"
- ✅ Rule is not saved
- ✅ User is prompted to fix dependency

**Expected Result:** Circular dependencies are prevented

---

### Scenario 5: Validation Execution - ConditionalRequired (Happy Path)

**Objective:** Verify conditional required validation works during form filling

**Steps:**
1. Open FormWizard with "District Creation Test" configuration
2. Fill "District Name" field with: "New District"
3. Fill "Town" field with: "CityTown"
4. Click on "Town Ruler" field
5. Leave it empty
6. Tab out of field or trigger change event

**Success Criteria:**
- ✅ Validation API is called
- ✅ Error message displays: "Town Ruler is required when Town is CityTown"
- ✅ Field has red border
- ✅ Red X icon displays next to field
- ✅ Submit button is disabled

**Expected Result:** Conditional required validation triggers and blocks submission

---

### Scenario 6: Validation Execution - ConditionalRequired (Condition Not Met)

**Objective:** Verify validation passes when condition is not met

**Steps:**
1. Open FormWizard with same configuration
2. Fill "District Name": "New District"
3. Fill "Town" with: "VillageTown" (different value)
4. Leave "Town Ruler" empty
5. Tab out of field

**Success Criteria:**
- ✅ Validation API called
- ✅ Validation passes (no error message)
- ✅ No red border on field
- ✅ Field is optional (no validation error)
- ✅ Submit button remains enabled

**Expected Result:** Validation passes when condition not met

---

### Scenario 7: Validation Execution - LocationInsideRegion (Valid Location)

**Objective:** Verify location validation accepts valid locations

**Steps:**
1. Navigate to Step 2 (Location Details)
2. In previous step, select valid Town
3. Enter Location ID: 1 (location inside selected town's region)
4. Tab out of field

**Success Criteria:**
- ✅ Validation executes
- ✅ Success message displays: "Location is valid"
- ✅ Green checkmark icon shows
- ✅ Field has green border
- ✅ No submission blocking

**Expected Result:** Valid location passes validation

---

### Scenario 8: Validation Execution - LocationInsideRegion (Invalid Location)

**Objective:** Verify location validation rejects invalid locations

**Steps:**
1. Navigate to Step 2 (Location Details)
2. In previous step, select valid Town
3. Enter Location ID: 999 (location outside region)
4. Tab out of field

**Success Criteria:**
- ✅ Validation executes
- ✅ Error message displays: "Location must be within the Town's region"
- ✅ Red X icon shows
- ✅ Field has red border
- ✅ Submit button is disabled
- ✅ Placeholder interpolation works (shows coordinates if available)

**Expected Result:** Invalid location is rejected with clear error message

---

### Scenario 9: Dependency Not Filled - Pending State

**Objective:** Verify validation displays pending message when dependency is empty

**Steps:**
1. Open FormWizard
2. Leave "Town" field empty (dependency)
3. Fill "Location ID" field
4. Tab out of Location ID field

**Success Criteria:**
- ✅ Validation shows pending message: "Validation pending until Town is filled"
- ✅ Gray icon displays
- ✅ No error message
- ✅ Field is not highlighted in red
- ✅ Submission is not blocked

**Expected Result:** Validation gracefully handles missing dependency

---

### Scenario 10: Multiple Validation Rules on Single Field

**Objective:** Verify multiple rules execute on same field

**Steps:**
1. Add second validation rule to "Location ID" field
2. Rule type: RegionContainment
3. Configure both rules (LocationInsideRegion and RegionContainment)
4. Fill Location ID field
5. Tab out

**Success Criteria:**
- ✅ Both validation rules execute
- ✅ All validation messages display
- ✅ If any blocking rule fails, submission blocked
- ✅ If all pass, submission allowed
- ✅ Results displayed in clear order

**Expected Result:** Multiple validations execute sequentially

---

### Scenario 11: Validation with Placeholder Interpolation

**Objective:** Verify error messages correctly interpolate placeholders

**Steps:**
1. Create validation rule with placeholder in error message:
   "Location {coordinates} is outside region {regionName}"
2. Trigger validation failure
3. Observe error message

**Success Criteria:**
- ✅ Placeholders are replaced with actual values
- ✅ Message reads correctly: "Location (X: 100, Z: 200) is outside region Town Square"
- ✅ No curly braces remain in message

**Expected Result:** Placeholders correctly interpolated in error messages

---

### Scenario 12: Configuration Health Check - Complete Analysis

**Objective:** Verify health check identifies all issues comprehensively

**Steps:**
1. Create scenario with multiple issues:
   - Rule with deleted dependency field
   - Rule with wrong field ordering
   - Valid rule
2. Open Configuration Health Panel
3. Click "Refresh"
4. Review all issues

**Success Criteria:**
- ✅ Issues grouped by severity (Errors first, then Warnings)
- ✅ Error count displayed: "2 errors"
- ✅ Warning count displayed: "1 warning"
- ✅ Red status icon shown (unhealthy)
- ✅ Each issue shows field label and rule ID
- ✅ Valid rules not listed as issues

**Expected Result:** Health check comprehensively identifies all configuration issues

---

### Scenario 13: Debounced Validation (Performance Test)

**Objective:** Verify validation is debounced to avoid excessive API calls

**Steps:**
1. Open FormWizard
2. Open browser DevTools (Network tab)
3. In a field with validation rules, type rapidly: "1234567890"
4. Monitor Network tab for API calls

**Success Criteria:**
- ✅ Only 1 API call made (not 10 for each character)
- ✅ Call happens ~300ms after typing stops
- ✅ No excessive network traffic
- ✅ UI remains responsive

**Expected Result:** Validation calls are debounced and optimized

---

### Scenario 14: Non-Blocking Validation Warning

**Objective:** Verify non-blocking validation shows warning but allows submission

**Steps:**
1. Create validation rule with IsBlocking = false
2. Set error message: "Warning: Location is near region boundary"
3. Trigger validation failure
4. Attempt to submit form

**Success Criteria:**
- ✅ Warning message displays in yellow
- ✅ Yellow triangle icon shows
- ✅ Field is not highlighted in red
- ✅ Submit button is NOT disabled
- ✅ Form can be submitted despite warning

**Expected Result:** Non-blocking warnings allow form submission

---

### Scenario 15: Blocking Validation Error

**Objective:** Verify blocking validation prevents form submission

**Steps:**
1. Ensure validation rule has IsBlocking = true
2. Trigger validation failure
3. Fill all other required fields
4. Attempt to submit form

**Success Criteria:**
- ✅ Error message displays in red
- ✅ Red X icon shows
- ✅ Field has red border
- ✅ Submit button is DISABLED
- ✅ Form cannot be submitted
- ✅ Tooltip/message explains why submit is disabled

**Expected Result:** Blocking validation prevents form submission

---

### Scenario 16: Field Value Change - Re-validation

**Objective:** Verify dependent fields re-validate when dependency changes

**Steps:**
1. Fill "Town" field with value A
2. Validation passes for dependent fields
3. Change "Town" to value B
4. Observe dependent fields re-validate

**Success Criteria:**
- ✅ Dependent fields re-validate automatically
- ✅ Validation results update based on new context
- ✅ Error messages update if needed
- ✅ UI refreshes with new validation state

**Expected Result:** Changing dependency triggers re-validation of dependent fields

---

### Scenario 17: Edit Existing Rule

**Objective:** Verify ability to modify existing validation rules

**Steps:**
1. In FormConfigBuilder, find existing validation rule
2. Click "Edit" button
3. ValidationRuleBuilder opens with existing data
4. Change error message
5. Modify ConfigJson
6. Click Save

**Success Criteria:**
- ✅ Form pre-populated with existing rule data
- ✅ All fields editable
- ✅ Changes saved to database
- ✅ Configuration Health Check re-validates
- ✅ Rule immediately reflects changes in FormWizard

**Expected Result:** Existing rules can be edited and updated

---

### Scenario 18: Delete Validation Rule

**Objective:** Verify ability to remove validation rules

**Steps:**
1. In FormConfigBuilder, find validation rule
2. Click "Delete" button
3. Confirm deletion
4. Navigate to Configuration Health Panel

**Success Criteria:**
- ✅ Confirmation dialog shown
- ✅ Rule removed from database
- ✅ Rule no longer appears in field's rule list
- ✅ Validation no longer triggers for field
- ✅ Health check updates if applicable

**Expected Result:** Validation rules can be deleted

---

### Scenario 19: Error Handling - API Failure

**Objective:** Verify graceful handling of validation API errors

**Steps:**
1. Simulate API failure (mock or network issue)
2. Trigger validation
3. Observe error handling

**Success Criteria:**
- ✅ User-friendly error message displays
- ✅ No console errors
- ✅ Form does not lock up
- ✅ User can retry validation
- ✅ "Retry" button appears (if applicable)

**Expected Result:** API errors handled gracefully with user feedback

---

### Scenario 20: Invalid JSON in ConfigJson Editor

**Objective:** Verify JSON validation prevents invalid configurations

**Steps:**
1. Open ValidationRuleBuilder
2. Manually enter invalid JSON in ConfigJson: `{invalid}`
3. Try to save rule

**Success Criteria:**
- ✅ Validation error shown: "Invalid JSON"
- ✅ Save button disabled or form rejected
- ✅ Error message points to JSON syntax issue
- ✅ User can correct and retry

**Expected Result:** Invalid JSON is caught and prevented from saving

---

## Success Criteria Summary

### Backend Validation Logic
- [ ] ConditionalRequired validator executes correctly
- [ ] LocationInsideRegion validator executes correctly
- [ ] RegionContainment validator executes correctly
- [ ] Circular dependencies detected and prevented
- [ ] Field ordering issues detected in health check
- [ ] Broken dependencies reported in health check

### Frontend UI/UX
- [ ] ValidationRuleBuilder component renders correctly
- [ ] ConfigJson auto-templates for each validation type
- [ ] FieldRenderer displays validation feedback
- [ ] Validation debouncing working (300ms)
- [ ] Success/error/warning/pending states display correctly
- [ ] Configuration Health Panel shows all issues
- [ ] Placeholder interpolation working

### Form Submission
- [ ] Blocking validations prevent submission
- [ ] Non-blocking validations allow submission
- [ ] Submit button disabled when validation fails
- [ ] Form submission allowed when all validations pass

### Error Handling
- [ ] API errors handled gracefully
- [ ] JSON validation prevents invalid configs
- [ ] Dependency not found handled
- [ ] Missing fields handled appropriately

---

## Bug Reporting Template

### Bug Report

**Title:** [Brief description of bug]

**Severity:** 
- [ ] Critical (blocks usage)
- [ ] High (major feature broken)
- [ ] Medium (minor feature broken)
- [ ] Low (cosmetic issue)

**Scenario:**
[Which test scenario triggered the bug?]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots/Videos:**
[Attach if applicable]

**Environment:**
- Browser: [Chrome/Firefox/Edge/etc]
- Backend: [URL/Environment]
- Frontend: [URL/Environment]
- Test Data: [Configuration ID/Field IDs used]

**Browser Console Errors:**
[Copy any console errors here]

**Network Errors:**
[Any failed API calls? Show details]

**Frequency:**
- [ ] Always
- [ ] Intermittent
- [ ] Rare

**Related Issues:**
[Link to similar issues if any]

---

## Test Execution Checklist

- [ ] Test Environment Setup Complete
- [ ] All Prerequisites Met
- [ ] Test Data Created
- [ ] Scenario 1: Create ConditionalRequired Rule ✅
- [ ] Scenario 2: Create LocationInsideRegion Rule ✅
- [ ] Scenario 3: Field Dependency Ordering ✅
- [ ] Scenario 4: Circular Dependency Detection ✅
- [ ] Scenario 5: Validation Execution - Happy Path ✅
- [ ] Scenario 6: Validation Execution - Condition Not Met ✅
- [ ] Scenario 7: LocationInsideRegion Valid ✅
- [ ] Scenario 8: LocationInsideRegion Invalid ✅
- [ ] Scenario 9: Dependency Not Filled ✅
- [ ] Scenario 10: Multiple Rules on Field ✅
- [ ] Scenario 11: Placeholder Interpolation ✅
- [ ] Scenario 12: Health Check Analysis ✅
- [ ] Scenario 13: Debounced Validation ✅
- [ ] Scenario 14: Non-Blocking Warning ✅
- [ ] Scenario 15: Blocking Error ✅
- [ ] Scenario 16: Field Re-validation ✅
- [ ] Scenario 17: Edit Existing Rule ✅
- [ ] Scenario 18: Delete Rule ✅
- [ ] Scenario 19: API Error Handling ✅
- [ ] Scenario 20: Invalid JSON ✅

**Overall Result:** 
- [ ] All Tests Passed
- [ ] Some Tests Failed (details below)
- [ ] Tests Blocked by Issues

**Sign-off:**
- Tester Name: _________________
- Date: _________________
- Notes: _________________

---

**End of Manual QA Testing Guide**
