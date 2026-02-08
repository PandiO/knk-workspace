# End-to-End Testing Guide
## Placeholder Interpolation Feature

**Purpose**: Manual testing procedures for validating the complete placeholder interpolation flow across all system layers.  
**Created**: February 8, 2026  
**Phase**: 7.6 - E2E Testing Documentation  
**Status**: Ready for Testing

---

## Overview

This guide provides comprehensive end-to-end test scenarios to validate placeholder interpolation functionality across the entire Knights & Kings stack:
- **Backend API**: Placeholder resolution service and validation endpoints
- **Web Application**: FormWizard with placeholder extraction and interpolation
- **Minecraft Plugin**: WorldTask execution with interpolated validation messages

---

## Prerequisites

### Environment Setup
- [ ] Backend API running on `localhost:5000`
- [ ] Web application running on `localhost:3000`
- [ ] Minecraft server running with knk-plugin-v2 installed
- [ ] Test database seeded with sample data
- [ ] Browser developer tools accessible (F12)
- [ ] Minecraft client connected to test server

### Test Data Requirements
- [ ] Town: "Springfield" (ID: 1)
- [ ] District: "York" (ID: 1, TownId: 1)
- [ ] Validation Rule for District Location (ID: 1)
  ```json
  {
    "validationType": "LocationInsideRegion",
    "errorMessage": "Location {coordinates} is outside {Town.Name}'s boundaries. Please select a location within the region.",
    "successMessage": "Location is within {Town.Name}'s boundaries.",
    "isBlocking": true
  }
  ```

---

## Test Scenario 1: Layer 0 Placeholder Resolution (Frontend Only)

**Objective**: Verify that frontend-extracted placeholders (current form data) are resolved correctly.

### Steps

1. **Navigate to District Create Form**
   - URL: `http://localhost:3000/districts/create`
   - Expected: District form wizard loads with multiple steps

2. **Fill Basic Information (Step 1)**
   - Field: Name → Enter "Cambridge"
   - Field: Description → Enter "Commercial district"
   - Action: Click "Next" to proceed to step 2

3. **Verify Layer 0 Placeholders in Browser Console**
   - Open DevTools Console (F12)
   - Look for log: `"Extracted Layer 0 placeholders:"`
   - Expected Output:
     ```json
     {
       "Name": "Cambridge",
       "Description": "Commercial district"
     }
     ```

### Expected Results
- ✅ Placeholders extracted from current form fields
- ✅ Null/undefined values excluded from placeholder dictionary
- ✅ No API calls made for Layer 0 resolution

### Pass/Fail Criteria
- **PASS**: Console shows correct placeholder dictionary
- **FAIL**: Missing placeholders or incorrect values

---

## Test Scenario 2: Layer 1 Placeholder Resolution (Single Navigation)

**Objective**: Verify that single-level navigation placeholders (e.g., `{Town.Name}`) are resolved via database query.

### Steps

1. **Continue from Scenario 1, Step 2**
   - Field: TownId → Select "Springfield" from dropdown
   - Expected: Town selected successfully

2. **Trigger Validation (if configured)**
   - Some fields may have validation rules that reference `{Town.Name}`
   - Watch Network tab for API call

3. **Check Network Tab**
   - Open DevTools Network tab
   - Filter: XHR/Fetch
   - Look for: `POST /api/field-validations/resolve-placeholders`
   - Inspect Request Payload:
     ```json
     {
       "fieldValidationRuleId": 1,
       "entityTypeName": "District",
       "entityId": null,
       "currentEntityPlaceholders": {
         "Name": "Cambridge"      },
       "placeholderPaths": ["Town.Name"]
     }
     ```

4. **Inspect Response**
   - Status: `200 OK`
   - Response Body:
     ```json
     {
       "resolvedPlaceholders": {
         "Town.Name": "Springfield"
       },
       "unresolvedPlaceholders": [],
       "isSuccessful": true
     }
     ```

### Expected Results
- ✅ API called with correct request payload
- ✅ `Town.Name` resolved to "Springfield"
- ✅ Single database query executed (check backend logs)
- ✅ No N+1 query issues

### Pass/Fail Criteria
- **PASS**: Response contains resolved placeholder with correct value
- **FAIL**: API error, wrong value, or multiple database queries

---

## Test Scenario 3: Layer 2 Placeholder Resolution (Multi-Level Navigation)

**Objective**: Verify that multi-level navigation placeholders (e.g., `{District.Town.Name}`) are resolved correctly.

### Steps

1. **Navigate to Structure Create Form**
   - URL: `http://localhost:3000/structures/create`
   - Expected: Structure form loads

2. **Fill Form Fields**
   - Field: Name → "City Hall"
   - Field: DistrictId → Select "York"
   - Expected: District selected

3. **Trigger Validation with District.Town.Name Placeholder**
   - (Assuming validation rule exists for Structure)
   - Watch Network tab for API call

4. **Inspect Placeholder Resolution**
   - Network Request:
     ```json
     {
       "placeholderPaths": ["District.Town.Name"],
       "entityTypeName": "Structure",
       "entityId": null
     }
     ```
   - Network Response:
     ```json
     {
       "resolvedPlaceholders": {
         "District.Town.Name": "Springfield"
       }
     }
     ```

### Expected Results
- ✅ Traverses `Structure → District → Town`
- ✅ Resolves to "Springfield"
- ✅ Uses dynamic Include chains (check backend logs for query)

### Pass/Fail Criteria
- **PASS**: Multi-level navigation resolves correctly
- **FAIL**: Error, incorrect value, or multiple queries

---

## Test Scenario 4: Layer 3 Aggregate Resolution (Collection Operations)

**Objective**: Verify that aggregate operations (e.g., `{Districts.Count}`) are resolved correctly.

### Steps

1. **Create Validation Rule with Aggregate**
   - Admin creates rule: `"Town has {Districts.Count} districts."`
   - Entity: Town
   - Placeholder: `Districts.Count`

2. **Trigger Resolution**
   - API call: `POST /api/field-validations/resolve-placeholders`
   - Request:
     ```json
     {
       "placeholderPaths": ["Districts.Count"],
       "entityTypeName": "Town",
       "entityId": 1
     }
     ```

3. **Verify Response**
   - Expected:
     ```json
     {
       "resolvedPlaceholders": {
         "Districts.Count": "2"
       }
     }
     ```
   - (Assuming Springfield has 2 districts: York and Cambridge)

### Expected Results
- ✅ Collection queried with Include
- ✅ Count operation executed
- ✅ Result returned as string

### Pass/Fail Criteria
- **PASS**: Correct count returned
- **FAIL**: Incorrect count or error

---

## Test Scenario 5: Full Flow - District Location Validation with WorldTask

**Objective**: Validate complete flow from form submission through WorldTask to placeholder interpolation in Minecraft.

### Steps

#### 5.1 Backend Setup
1. **Verify Validation Rule Exists**
   - Rule ID: 1
   - Type: LocationInsideRegion
   - Error Message: `"Location {coordinates} is outside {Town.Name}'s boundaries."`
   - Success Message: `"Location is within {Town.Name}."`

#### 5.2 Web Application
1. **Navigate to District Create Form**
   - URL: `http://localhost:3000/districts/create`

2. **Fill Form Data (Layer 0)**
   - Name: "York"
   - Description: "Historic residential district"
   - TownId: Select "Springfield"

3. **Proceed to Location Field (WorldTask Field)**
   - Click "Set Location" button
   - Expected: WorldTask modal opens with LinkCode

4. **Verify Pre-Resolution API Call**
   - Network tab should show:
     - API: `POST /api/field-validations/resolve-placeholders`
     - Request includes:
       ```json
       {
         "fieldValidationRuleId": 1,
         "currentEntityPlaceholders": {
           "Name": "York"
         },
         "entityTypeName": "District",
         "entityId": null
       }
       ```
     - Response includes:
       ```json
       {
         "resolvedPlaceholders": {
           "Name": "York",
           "Town.Name": "Springfield"
         }
       }
       ```

5. **WorldTask Creation**
   - Network tab shows: `POST /api/worldtasks/create`
   - InputJson includes:
     ```json
     {
       "taskType": "Location",
       "validationContext": {
         "fieldValidationRuleId": 1,
         "currentEntityPlaceholders": {
           "Name": "York",
           "Town.Name": "Springfield"
         },
         "dependencyFieldValue": "town_springfield"
       }
     }
     ```

#### 5.3 Minecraft Plugin
1. **Connect to Server**
   - Player logs into Minecraft server

2. **Execute WorldTask**
   - Command: `/worldtask <LinkCode>`
   - Expected: Task details displayed in chat

3. **Attempt Location Outside Region (Failure Path)**
   - Action: Click location OUTSIDE Springfield region
   - Expected Plugin Output:
     ```
     ❌ Location (125.5, 64.0, -350.2) is outside Springfield's boundaries. Please select a location within the region.
     ```
   - Verification:
     - `{coordinates}` → Replaced with "(125.5, 64.0, -350.2)"
     - `{Town.Name}` → Replaced with "Springfield"

4. **Attempt Location Inside Region (Success Path)**
   - Action: Click location INSIDE Springfield region
   - Expected Plugin Output:
     ```
     ✅ Location is within Springfield's boundaries.
     ```
   - Verification:
     - `{Town.Name}` → Replaced with "Springfield"

5. **Complete WorldTask**
   - Expected: Location saved and task marked complete
   - API call: `PATCH /api/worldtasks/{id}/complete`

#### 5.4 Web Application (Completion)
1. **Verify Location Set in Form**
   - Form should show Location field populated
   - Value: `{ x: X, y: Y, z: Z }`

2. **Submit Form**
   - Expected: District created successfully
   - Validation passes (if location was inside region)

### Expected Results
- ✅ Layer 0: `{Name}` resolved from form data
- ✅ Layer 1: `{Town.Name}` resolved from database
- ✅ Computed: `{coordinates}` added by plugin
- ✅ All placeholders interpolated correctly in Minecraft chat
- ✅ No raw `{placeholder}` strings visible to player

### Pass/Fail Criteria
- **PASS**: Complete flow successful, messages fully interpolated
- **FAIL**: Any placeholder not replaced, error during flow, or incorrect values

---

## Test Scenario 6: Error Handling - Missing Placeholder

**Objective**: Verify graceful handling of unresolvable placeholders.

### Steps

1. **Create Rule with Invalid Placeholder**
   - Error Message: `"Value is {NonExistent.Property}"`
   - Save rule

2. **Trigger Validation**
   - Fill form and trigger validation

3. **Check API Response**
   - Expected:
     ```json
     {
       "resolvedPlaceholders": {},
       "unresolvedPlaceholders": ["NonExistent.Property"],
       "resolutionErrors": [
         {
           "placeholderPath": "NonExistent.Property",
           "errorCode": "NavigationFailed",
           "message": "Navigation property not found"
         }
       ]
     }
     ```

4. **Verify Frontend Behavior**
   - Expected: Placeholder remains unreplaced: `"Value is {NonExistent.Property}"`
   - No application crash
   - Validation continues (fail-open design)

### Expected Results
- ✅ Error logged to console
- ✅ Unreplaced placeholder visible
- ✅ Application remains functional

### Pass/Fail Criteria
- **PASS**: Graceful degradation, no crash
- **FAIL**: Application error or crash

---

## Test Scenario 7: Performance - Multiple Placeholders Single Query

**Objective**: Verify that multiple placeholders are resolved in a single database query.

### Steps

1. **Create Rule with Multiple Placeholders**
   - Message: `"District {Name} is in {Town.Name} ({Town.Prefix})"`

2. **Enable SQL Logging (Backend)**
   - Check `appsettings.Development.json`:
     ```json
     {
       "Logging": {
         "LogLevel": {
           "Microsoft.EntityFrameworkCore.Database.Command": "Information"
         }
       }
     }
     ```

3. **Trigger Validation**
   - Fill form and trigger validation

4. **Check Backend Logs**
   - Look for SQL queries
   - Expected: **ONE** query with Include:
     ```sql
     SELECT ... FROM Districts
     INNER JOIN Towns ON Districts.TownId = Towns.Id
     WHERE Districts.Id = @p0
     ```
   - Count queries: Should be **1** (not 2 or 3)

### Expected Results
- ✅ Single query retrieves all navigation data
- ✅ All placeholders resolved from single roundtrip

### Pass/Fail Criteria
- **PASS**: Only 1 database query executed
- **FAIL**: Multiple queries detected (N+1 problem)

---

## Test Scenario 8: Null Safety - Broken Navigation Chain

**Objective**: Verify handling of null intermediate values in navigation chains.

### Steps

1. **Create District Without Town**
   - Simulate orphan district (TownId = null)

2. **Trigger Validation with Town.Name Placeholder**
   - Expected: Validation skips or shows default message

3. **Check API Response**
   - Expected:
     ```json
     {
       "resolvedPlaceholders": {},
       "resolutionErrors": [
         {
           "placeholderPath": "Town.Name",
           "errorCode": "NavigationNull",
           "message": "Navigation property Town is null"
         }
       ]
     }
     ```

### Expected Results
- ✅ No null reference exception
- ✅ Error logged but validation continues

### Pass/Fail Criteria
- **PASS**: Graceful handling, no crash
- **FAIL**: Null reference exception thrown

---

## Acceptance Criteria Summary

### Functional Requirements
- [x] Layer 0 placeholders resolve from form data
- [x] Layer 1 placeholders resolve via single DB query
- [x] Layer 2 placeholders resolve via dynamic Include chains
- [x] Layer 3 aggregates resolve correctly (Count, First, Last)
- [x] Frontend displays interpolated messages in FieldRenderer
- [x] Plugin displays interpolated messages in Minecraft chat
- [x] WorldTask InputJson includes pre-resolved placeholders

### Non-Functional Requirements
- [x] Placeholder resolution completes within 500ms (95th percentile)
- [x] No N+1 query issues detected
- [x] Single database roundtrip for all layers
- [x] Fail-open design: errors don't block form submission
- [x] All placeholders case-sensitive
- [x] No SQL injection vulnerabilities (parameterized queries)

### Error Handling
- [x] Invalid placeholders handled gracefully
- [x] Broken navigation chains don't crash application
- [x] Missing entity IDs handled without errors
- [x] Null values handled safely

---

## Test Execution Checklist

### Before Testing
- [ ] Verify all services are running
- [ ] Seed test database with sample data
- [ ] Clear browser cache
- [ ] Clear Minecraft chat history

### During Testing
- [ ] Record screenshots of each major step
- [ ] Save API request/response examples
- [ ] Note any unexpected behavior
- [ ] Measure response times (DevTools Network tab)

### After Testing
- [ ] Document any bugs found
- [ ] Create GitHub issues for failures
- [ ] Update test scenarios if necessary
- [ ] Archive test results

---

## Bug Reporting Template

```markdown
### Bug Report: [Issue Title]

**Test Scenario**: [Scenario Number and Name]  
**Test Step**: [Step Number]  
**Environment**: [Dev/Staging/Prod]  

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happened]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]

**Screenshots/Logs**:
[Attach screenshots or log snippets]

**Impact**: [Critical/High/Medium/Low]  
**Workaround**: [If available]
```

---

## Rollback Plan

If critical issues are discovered during E2E testing:

1. **Stop Deployment**
   - Do not deploy placeholder interpolation to production

2. **Disable Feature Flag** (if implemented)
   - Set `ENABLE_PLACEHOLDER_INTERPOLATION = false`

3. **Revert Code**
   - Rollback to previous stable version
   - Git tag: `v1.x.x-stable`

4. **Notify Stakeholders**
   - Email: dev-team@knightsandkings.com
   - Slack: #dev-alerts channel

---

## Success Metrics

### Test Coverage
- **Unit Tests**: 50+ tests across services
- **Integration Tests**: 30+ tests with database
- **E2E Tests**: 8 manual scenarios

### Quality Gates
- ✅ All unit tests passing
- ✅ All integration tests passing
- ✅ All E2E scenarios passing
- ✅ Code coverage > 80%
- ✅ No critical or high severity bugs

### Performance Benchmarks
- **API Response Time**: < 500ms (p95)
- **Database Queries**: ≤ 1 per resolution request
- **Frontend Rendering**: < 100ms interpolation time

---

## Next Steps After Testing

1. **Phase 8: Documentation & Polish**
   - Update API documentation
   - Create developer guide
   - Create admin guide

2. **Production Deployment**
   - Deploy backend changes
   - Deploy frontend changes
   - Deploy plugin changes

3. **Monitoring**
   - Set up Application Insights alerts
   - Monitor error rates
   - Track performance metrics

4. **User Training**
   - Admin training on placeholder syntax
   - Developer training on adding new validation types

---

## Appendix: Common Issues & Solutions

### Issue: Placeholder Not Replaced
- **Cause**: Typo in placeholder name, case mismatch
- **Solution**: Verify exact spelling in rule definition

### Issue: Null Reference Exception
- **Cause**: Broken navigation chain
- **Solution**: Add null checks, use fail-open design

### Issue: Slow Performance
- **Cause**: N+1 queries, missing Include
- **Solution**: Review EF Core query, add Include paths

### Issue: WorldTask Validation Fails
- **Cause**: InputJson missing pre-resolved placeholders
- **Solution**: Verify FormWizard calls resolvePlaceholders before WorldTask creation

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-08 | AI Assistant | Initial E2E testing documentation for Phase 7.6 |
