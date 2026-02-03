# WorldTask Validation Integration

**Feature:** Real-time validation during WorldTask execution in Minecraft  
**Created:** February 3, 2026  
**Status:** In Implementation  

---

## Overview

This specification describes the integration of inter-field validation rules into the WorldTask feature. When admins capture world-bound data (locations, regions) through the Minecraft plugin, the system validates against configured validation rules in real-time and **blocks task completion** if validation fails.

**Primary Use Case:**  
When creating a District, the admin must define a Location and WorldGuard region. Both must be validated against the parent Town's region to ensure spatial containment before the data is saved.

---

## Architecture Flow

```
┌────────────────────────────────────────────────────────────────┐
│ FormWizard (Web App)                                            │
│                                                                 │
│ 1. Loads FormConfiguration with FieldValidationRules           │
│ 2. Resolves dependency field values from current form data     │
│ 3. Creates WorldTask with validation context in InputJson      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ POST /api/worldtasks
                           │ InputJson contains validationContext
                           ↓
┌────────────────────────────────────────────────────────────────┐
│ WorldTask API (Backend)                                         │
│                                                                 │
│ 1. Receives validation rules embedded in InputJson             │
│ 2. Stores WorldTask with validation context                    │
│ 3. Plugin fetches task via GET /api/worldtasks/{id}            │
│ 4. On complete: Re-validates OutputJson against rules          │
│ 5. Rejects completion if validation fails                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Plugin fetches task + validation
                           ↓
┌────────────────────────────────────────────────────────────────┐
│ WorldTask Handler (Minecraft Plugin)                            │
│                                                                 │
│ 1. Parses validation context from InputJson                    │
│ 2. During handleSave(): Validates captured data                │
│ 3. If validation fails:                                        │
│    - Display detailed error message to player                  │
│    - Block task completion                                     │
│    - Instruct user to fix issue or cancel                      │
│ 4. If validation passes: Proceed with API completion           │
└────────────────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Validation Failure Behavior: **BLOCKING**

**Decision:** Validation failures **block** task completion. Users cannot proceed with invalid data.

**Rationale:**  
- Prevents erroneous data from entering the production database
- Ensures spatial containment rules are enforced at capture time
- Reduces need for post-creation cleanup and data corrections

**User Experience:**
```
Player: save
§c[WorldTask] Validation Failed:
§c Location is outside region 'town_springfield'
§e
§e Your location (125.5, 64.0, -350.2) is not inside the parent region.
§e Please move inside the region and type 'save' again, or 'cancel' to abort.
§e If you believe this is an error, contact a developer.
```

---

### 2. Validation Execution Point: **handleSave()**

**Decision:** Validation executes in the plugin's `handleSave()` method **before** the API call.

**Rationale:**  
- Immediate feedback to the user in-game
- Avoids unnecessary API calls for invalid data
- User can retry immediately without waiting for API response

**Implementation Location:**
- `LocationTaskHandler.handleSave()` - Validates location coordinates
- `WgRegionIdTaskHandler.handleSave()` - Validates region containment

---

### 3. Double Validation: Plugin + API

**Decision:** Validate in **both** plugin (pre-save) and API (on complete).

**Rationale:**  
- **Plugin validation:** Provides immediate UX feedback
- **API validation:** Ensures data integrity (defense-in-depth)
- Protects against modified/malicious clients
- API is source of truth for validation logic

---

### 4. Dependency Resolution: Web App

**Decision:** Web app resolves dependency field values before creating WorldTask.

**Rationale:**  
- Plugin doesn't have access to full form context
- Web app already has all form data loaded
- Simplifies plugin logic - just receives resolved values
- Reduces API calls from plugin

**Example:**  
District form has selected `TownId = 5`. Web app:
1. Fetches Town entity with ID 5
2. Extracts `WgRegionId = "town_springfield"`
3. Passes resolved value in validation context to plugin

---

### 5. Error Message Placeholders: **Supported**

**Decision:** Support placeholder replacement in error messages.

**Placeholders:**
- `{regionName}` - Parent region name
- `{coordinates}` - Captured location/region points
- `{violations}` - List of violating coordinates
- `{entityName}` - Parent entity name (e.g., Town name)

**Example Configuration:**
```json
{
  "errorMessage": "Location is outside region '{regionName}'. Coordinates: {coordinates}"
}
```

**Plugin Output:**
```
Location is outside region 'town_springfield'. Coordinates: (125.5, 64.0, -350.2)
```

---

## Data Structures

### 1. WorldTask InputJson Structure

When a WorldTask is created with validation rules, the InputJson contains:

```json
{
  "fieldName": "Location",
  "validationContext": {
    "validationRules": [
      {
        "validationType": "LocationInsideRegion",
        "configJson": "{\"regionPropertyPath\":\"WgRegionId\"}",
        "errorMessage": "Location is outside region '{regionName}'",
        "isBlocking": true,
        "dependencyFieldValue": {
          "id": 5,
          "name": "Springfield",
          "wgRegionId": "town_springfield"
        }
      }
    ],
    "formContext": {
      "townId": 5,
      "name": "Downtown District",
      "... other form fields": "..."
    }
  }
}
```

**Key Fields:**
- `validationRules[]`: Array of validation rules to execute
- `dependencyFieldValue`: Resolved parent entity (Town) with region ID
- `formContext`: All form data for additional validation needs

---

### 2. Plugin Validation DTOs (Java)

**File:** `knk-core/src/main/java/net/knightsandkings/knk/core/domain/validation/`

```java
public class WorldTaskValidationRule {
    private String validationType;        // "LocationInsideRegion", "RegionContainment"
    private String configJson;            // Type-specific configuration
    private String errorMessage;          // User-facing error message
    private boolean isBlocking;           // If true, blocks task completion
    private JsonElement dependencyFieldValue; // Resolved parent entity
    
    // Getters/setters
}

public class WorldTaskValidationContext {
    private List<WorldTaskValidationRule> validationRules;
    private Map<String, Object> formContext;
    
    // Getters/setters
}

public class ValidationResult {
    private final boolean isValid;
    private final String message;
    private final boolean isBlocking;
    
    public ValidationResult(boolean isValid, String message, boolean isBlocking) {
        this.isValid = isValid;
        this.message = message;
        this.isBlocking = isBlocking;
    }
    
    // Getters
}
```

---

## Validation Types

### 1. LocationInsideRegion

**Purpose:** Validate that a captured Location is inside a WorldGuard region.

**Use Case:** District Location must be inside Town region.

**ConfigJson Schema:**
```json
{
  "regionPropertyPath": "WgRegionId",
  "allowBoundary": false
}
```

**Validation Logic (Plugin):**
1. Extract `dependencyFieldValue` (Town entity with WgRegionId)
2. Get `regionPropertyPath` from configJson ("WgRegionId")
3. Extract parent region ID: `town.wgRegionId`
4. Use WorldGuard API: `parentRegion.contains(BlockVector3.at(x, y, z))`
5. Return validation result

**Error Message Example:**
```
Location is outside region 'town_springfield'. 
Your location (125.5, 64.0, -350.2) is not inside the parent region.
Please move inside the region and type 'save' again, or 'cancel' to abort.
```

---

### 2. RegionContainment

**Purpose:** Validate that a defined region is fully contained within a parent region.

**Use Case:** District region must be inside Town region.

**ConfigJson Schema:**
```json
{
  "parentRegionPath": "WgRegionId",
  "requireFullContainment": true
}
```

**Validation Logic (Plugin):**
1. Extract parent region ID from `dependencyFieldValue`
2. Iterate all points in child region selection
3. Check each point: `parentRegion.contains(point)`
4. If any point is outside: validation fails
5. List violating points in error message

**Error Message Example:**
```
Region extends outside parent region 'town_springfield'.
Violating points: (100, 64, 200), (105, 64, 210), (110, 64, 215)
Please adjust your selection to fit within the parent region.
```

---

## Implementation Checklist

### Phase 1: Backend (knk-web-api-v2)

- [ ] **1.1** Create `WorldTaskValidationDtos.cs`
  - `WorldTaskValidationRuleDto`
  - `WorldTaskValidationContextDto`
  - Location: `Dtos/WorldTaskValidationDtos.cs`

- [ ] **1.2** Update `WorldTaskService.cs`
  - Add `ValidateTaskOutputAsync()` method
  - Modify `CompleteAsync()` to validate before completion
  - Reject completion with ValidationException if blocking validation fails

- [ ] **1.3** Create `IWorldTaskValidationService` interface
  - `ValidateLocationInsideRegionAsync()`
  - `ValidateRegionContainmentAsync()`
  - Location: `Services/Interfaces/IWorldTaskValidationService.cs`

- [ ] **1.4** Implement `WorldTaskValidationService`
  - Integrate with WorldGuard service for region checks
  - Location: `Services/WorldTaskValidationService.cs`

---

### Phase 2: Web App (knk-web-app)

- [ ] **2.1** Update `FormWizard.tsx`
  - When creating WorldTask, load validation rules for field
  - Resolve dependency field values from `allStepsData`
  - Build `validationContext` and embed in InputJson
  - Pass to `worldTaskClient.create()`

- [ ] **2.2** Update `WorldTaskCta.tsx`
  - Display validation errors from task.errorMessage
  - Show retry instructions to user
  - Highlight blocking vs. warning validations

- [ ] **2.3** Create helper function `resolveValidationRules()`
  - Input: Field ID, validation rules, form context
  - Output: Validation rules with resolved dependency values
  - Location: `utils/validationHelpers.ts`

---

### Phase 3: Plugin (knk-plugin-v2)

- [ ] **3.1** Create plugin validation DTOs
  - `WorldTaskValidationRule.java`
  - `WorldTaskValidationContext.java`
  - `ValidationResult.java`
  - Location: `knk-core/src/main/java/net/knightsandkings/knk/core/domain/validation/`

- [ ] **3.2** Update `LocationTaskHandler.handleSave()`
  - Add `validateLocation()` method
  - Implement `validateLocationInsideRegion()` using WorldGuard API
  - Block save if validation fails (return early)
  - Display detailed error message to player

- [ ] **3.3** Update `WgRegionIdTaskHandler.handleSave()`
  - Add `validateRegion()` method
  - Implement `validateRegionContainment()` using WorldGuard API
  - Check all region points against parent region
  - Block save if validation fails
  - List violating coordinates in error message

- [ ] **3.4** Add helper method `extractParentRegionId()`
  - Parse dependency field value (Town entity)
  - Extract region ID using configJson path
  - Handle both JSON object and string formats

---

### Phase 4: Testing

- [ ] **4.1** Unit Tests - Backend
  - Test `WorldTaskValidationService.ValidateLocationInsideRegionAsync()`
  - Test `WorldTaskValidationService.ValidateRegionContainmentAsync()`
  - Test `WorldTaskService.ValidateTaskOutputAsync()` parsing

- [ ] **4.2** Integration Test - District Creation Flow
  - Create FormConfiguration for District with validation rules
  - Start workflow, select Town with region
  - Create WorldTask for Location
  - In Minecraft: Stand outside Town region and save
  - **Expected:** Validation blocks, error displayed
  - Move inside Town region and save
  - **Expected:** Validation passes, task completes

- [ ] **4.3** Integration Test - Region Containment
  - Create WorldTask for District WgRegionId
  - Define region extending outside Town
  - **Expected:** Validation blocks with violating points
  - Adjust selection to be inside Town
  - **Expected:** Validation passes

---

## Error Handling

### 1. Validation Parsing Errors

**Scenario:** InputJson is malformed or validation context is missing.

**Behavior:** 
- **Plugin:** Log warning, skip validation, allow task to proceed
- **API:** Log error, allow completion (fail-open for parsing errors only)

**Rationale:** Don't block users due to system errors in validation configuration.

---

### 2. Parent Region Not Found

**Scenario:** Parent region ID is invalid or region doesn't exist.

**Behavior:**
- **Plugin:** Display error to player with region ID
- Block task completion
- Instruct user to contact developer

**Error Message:**
```
§c[WorldTask] Validation Error:
§c Parent region 'town_nonexistent' not found.
§e This may be a configuration issue. Please contact a developer.
§e Task not completed. Type 'cancel' to abort.
```

---

### 3. WorldGuard Service Unavailable

**Scenario:** WorldGuard plugin not loaded or RegionManager unavailable.

**Behavior:**
- Log error
- Display generic error to player
- Block task completion
- Suggest server restart

**Error Message:**
```
§c[WorldTask] Validation Error:
§c WorldGuard service unavailable. Cannot validate region containment.
§e Please notify a server administrator.
```

---

## User Experience Examples

### Success Flow: Location Inside Region

```
Player: save
§a[WorldTask] Location captured!
§7Position: (100.5, 64.0, 200.3)
§7Rotation: yaw=45.00, pitch=-15.00
§7World: world
§7Validating location...
§a✓ Location is inside region: town_springfield
§7Completing task...
§a[WorldTask] ✓ Task completed! Location captured.
```

---

### Failure Flow: Location Outside Region

```
Player: save
§a[WorldTask] Location captured!
§7Position: (125.5, 64.0, -350.2)
§7Rotation: yaw=90.00, pitch=0.00
§7World: world
§7Validating location...
§c✗ Validation Failed:
§c Location is outside region 'town_springfield'
§e
§e Your location (125.5, 64.0, -350.2) is not inside the parent region.
§e Please move inside the region and type 'save' again.
§e Or type 'cancel' to abort the task.
§e If you believe this is an error, contact a developer.
```

---

### Failure Flow: Region Containment

```
Player: save
§7Validating region selection...
§7Checking 24 region points against parent region 'town_springfield'...
§c✗ Validation Failed:
§c Region extends outside parent region 'town_springfield'
§c Violating points (first 5): 
§c   (100, 64, 250)
§c   (105, 64, 250)
§c   (110, 64, 250)
§c   (115, 64, 250)
§c   (120, 64, 250)
§e
§e Please adjust your WorldEdit selection to fit within the parent region.
§e Type 'cancel' to start over, or adjust and type 'save' again.
```

---

## Performance Considerations

### 1. Region Containment Checks

**Challenge:** Large regions with many points can slow validation.

**Optimization:**
- Check bounding box first (min/max points)
- Sample points for very large polygonal regions (e.g., every 10th point)
- Cache parent region lookups during task execution
- Limit violation reporting to first 10 points

---

### 2. API Re-validation

**Challenge:** Re-validating on API complete adds latency.

**Optimization:**
- Execute validation asynchronously where possible
- Cache WorldGuard region data in API service
- Use in-memory region representation for containment checks
- Consider validation result caching for identical checks

---

## Future Enhancements

1. **Validation Preview:**  
   Show validation status in real-time as player moves (for Location tasks)

2. **Visual Indicators:**  
   Display region boundaries using particles when task starts

3. **Auto-correction:**  
   Suggest nearest valid point when validation fails

4. **Batch Validation:**  
   Validate multiple fields in one WorldTask (e.g., Location + Region)

5. **Custom Validation Rules:**  
   Allow plugins to register custom validation handlers

---

## Migration & Rollout

### Step 1: Backend Deployment
- Deploy WorldTaskValidationService
- Update WorldTaskService with validation
- **No breaking changes** - existing tasks without validation continue to work

### Step 2: Web App Deployment
- Update FormWizard to pass validation context
- Only affects new WorldTasks - existing in-progress tasks unaffected

### Step 3: Plugin Deployment
- Update task handlers with validation logic
- Existing tasks without validationContext continue to work (graceful degradation)

### Step 4: Configuration
- Create FormConfigurations with validation rules for District
- Test thoroughly before production use

---

## Troubleshooting Guide

### Issue: Validation always passes

**Check:**
1. Is `validationContext` present in WorldTask.InputJson?
2. Are validation rules configured in FormConfiguration?
3. Is dependency field value resolved correctly?
4. Check plugin logs for parsing errors

### Issue: Validation always fails

**Check:**
1. Is parent region ID correct?
2. Does parent region exist in WorldGuard?
3. Are coordinates in the correct world?
4. Check WorldGuard region bounds using `/rg info {regionId}`

### Issue: Error message placeholders not replaced

**Check:**
1. Plugin validation implementation - ensure placeholders are replaced
2. Check error message format in FormConfiguration
3. Verify dependency field value contains required properties

---

## Related Documentation

- [SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md](./SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md) - Core validation specification
- [IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md) - Validation implementation guide
- [../../world-tasks/HANDLER_DEVELOPMENT_GUIDE.md](../../world-tasks/HANDLER_DEVELOPMENT_GUIDE.md) - Handler development guide
- [../../world-tasks/API_CONTRACT.md](../../world-tasks/API_CONTRACT.md) - WorldTask API reference

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 3, 2026 | System | Initial specification |
