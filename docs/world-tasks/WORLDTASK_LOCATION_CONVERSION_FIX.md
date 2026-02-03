# WorldTask Location Data Conversion Fix

## Problem Summary

The Location field was not being properly converted when a WorldTask was completed by the `LocationTaskHandler`. The data flow had three critical gaps:

1. **Plugin → API**: `LocationTaskHandler.completeTask()` returned raw location coordinates but didn't indicate that these should be converted to a Location entity
2. **API Backend**: `WorkflowService.FinalizeAsync()` had TODOs but didn't actually process task output to create Location entities
3. **Web App → Form**: `WorldBoundFieldRenderer.tsx` tried to extract a non-existent `locationId` field, causing extraction failures

## Solution Implemented

### 1. Plugin Side: LocationTaskHandler.java

**File**: `Repository/knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java`

**Changes**:
- Enhanced `completeTask()` to include detailed documentation
- Added `createLocationAndCompleteTask()` method for future API integration
- Added `completeTaskWithLocationData()` method with clearer semantics

**Output JSON Format**:
```json
{
  "fieldName": "Location",
  "x": 100.5,
  "y": 64.0,
  "z": -200.5,
  "yaw": 45.0,
  "pitch": 0.0,
  "worldName": "world",
  "capturedAt": 1706359200000
}
```

**Key Point**: The handler now sends raw location data to the API. The backend is responsible for processing this data into a Location entity during workflow finalization.

---

### 2. Web API Backend: WorkflowService.cs

**File**: `Repository/knk-web-api-v2/Services/WorkflowService.cs`

**Changes**:

#### Constructor Enhancement
- Added `IWorldTaskRepository _taskRepo` dependency
- Added `ILocationService _locationService` dependency
- Updated constructor to inject these services

```csharp
public WorkflowService(IWorkflowRepository workflowRepo, IWorldTaskRepository taskRepo, 
    ILocationService locationService, IMapper mapper)
{
    _workflowRepo = workflowRepo;
    _taskRepo = taskRepo;
    _locationService = locationService;
    _mapper = mapper;
}
```

#### FinalizeAsync() Implementation
Replaced TODO placeholders with actual implementation:

1. **Fetch all tasks** for the workflow session
2. **Iterate completed tasks** with non-empty outputJson
3. **Route by field type**: Handle Location tasks specially
4. **Process Location data**: Extract coordinates, world name, create Location entity
5. **Return locationId** for later use in entity finalization

**New Methods**:
- `ProcessLocationTaskOutput()`: Parses Location task JSON, creates Location entity via LocationService

**Error Handling**:
- Gracefully handles JSON parsing errors
- Continues processing even if one task fails
- Provides debug logging for troubleshooting

---

### 3. Web App Frontend: WorldBoundFieldRenderer.tsx

**File**: `Repository/knk-web-app/src/components/Workflow/WorldBoundFieldRenderer.tsx`

**Changes**:

#### Task Output Field Mapping
Updated `TASK_OUTPUT_FIELD_MAP` to distinguish Location handling:

```typescript
const TASK_OUTPUT_FIELD_MAP: Record<string, string> = {
    'RegionCreate': 'regionId',
    'LocationCapture': 'location',    // ← Extract raw data
    'CaptureLocation': 'location',    // Alternative naming
    'Location': 'location',            // Field name based
    'WgRegionId': 'regionId',
};
```

#### Enhanced extractTaskResult() Function
- Added `isLocationTask()` helper to detect Location captures
- **Special handling for Location tasks**:
  - Extracts raw coordinates (x, y, z, yaw, pitch, worldName)
  - Converts to location object: `{ x, y, z, yaw, pitch, worldName }`
  - Returns structured object instead of looking for non-existent ID
- **Fallback handling**: For Region tasks, still extracts regionId as before

```typescript
function isLocationTask(taskType: string, actualTaskType?: string): boolean {
    const types = [taskType, actualTaskType].filter(Boolean).map(t => t?.toLowerCase() || '');
    return types.some(t => t.includes('location') || t.includes('capture'));
}
```

---

### 4. WgRegionIdTaskHandler.java - Verification

**File**: `Repository/knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/WgRegionIdTaskHandler.java`

**Status**: ✅ Already correctly implemented

The handler already returns `regionId` in its output JSON:
```json
{
  "fieldName": "WgRegionId",
  "regionId": "town_123",
  "createdAt": 1706359200000,
  "worldName": "world",
  "parentRegionId": "parent_region" // optional
}
```

This pattern is correctly extracted by the frontend.

---

## Data Flow After Fix

```
┌─ Plugin: LocationTaskHandler ────────────────────┐
│                                                   │
│  Player executes: /say save                      │
│  Handler captures: x, y, z, yaw, pitch, world    │
│  Sends to API: {                                  │
│    fieldName: "Location",                         │
│    x, y, z, yaw, pitch,                           │
│    worldName, capturedAt                          │
│  }                                                │
│                                                   │
└─────────────────────┬──────────────────────────────┘
                      │
                      ▼
┌─ Web API: WorldTaskService ──────────────────────┐
│                                                   │
│  POST /worldtasks/{id}/complete                  │
│  Status: Pending → Completed                     │
│  OutputJson stored in WorldTask entity            │
│                                                   │
└─────────────────────┬──────────────────────────────┘
                      │
                      ▼
┌─ Web App: Polling ───────────────────────────────┐
│                                                   │
│  GET /worldtasks/{id}                            │
│  Detects status: Completed                       │
│  Extracts outputJson                             │
│  Calls extractTaskResult()                       │
│  Gets: { x, y, z, yaw, pitch, worldName }        │
│                                                   │
└─────────────────────┬──────────────────────────────┘
                      │
                      ▼
┌─ Web App: Form Binding ──────────────────────────┐
│                                                   │
│  onChange(locationObject) triggered              │
│  Form field populated with location data         │
│  User can now finalize workflow                  │
│                                                   │
└──────────────────────────────────────────────────┘
                      │
                      ▼
┌─ API: Workflow Finalization ─────────────────────┐
│                                                   │
│  POST /workflows/{id}/finalize                   │
│  FinalizeAsync() processes all completed tasks   │
│  ProcessLocationTaskOutput() creates Location    │
│  entity via LocationService.CreateAsync()        │
│  Returns locationId for entity linking           │
│                                                   │
└──────────────────────────────────────────────────┘
```

---

## Testing Checklist

- [ ] Verify `WorkflowService` has access to `IWorldTaskRepository` and `ILocationService` (DI already configured)
- [ ] Test Location capture flow end-to-end:
  1. Create task in web app
  2. Player claims and completes in Minecraft
  3. Web app receives completion notification
  4. extractTaskResult() returns location object
  5. Form field is populated
  6. Workflow can be finalized
- [ ] Verify Location entity is created in database during finalization
- [ ] Confirm Region tasks still work (WgRegionIdTaskHandler)
- [ ] Check error handling for malformed JSON outputs

---

## Files Modified

1. **[LocationTaskHandler.java](Repository/knk-plugin-v2/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java)** (Plugin)
   - Enhanced completeTask() method structure
   - Improved code clarity and documentation

2. **[WorkflowService.cs](Repository/knk-web-api-v2/Services/WorkflowService.cs)** (Web API)
   - Added dependencies: IWorldTaskRepository, ILocationService
   - Implemented FinalizeAsync() with task output processing
   - Added ProcessLocationTaskOutput() helper method

3. **[WorldBoundFieldRenderer.tsx](Repository/knk-web-app/src/components/Workflow/WorldBoundFieldRenderer.tsx)** (Web App)
   - Updated TASK_OUTPUT_FIELD_MAP
   - Enhanced extractTaskResult() with Location handling
   - Added isLocationTask() helper

---

## Architecture Notes

### Responsibility Distribution

| Layer | Responsibility |
|-------|-----------------|
| **Plugin** | Capture raw location data, serialize to JSON |
| **API** | Parse task output, create entities, manage relationships |
| **Web App** | Extract structured data from task output, bind to form |

### Why This Approach

1. **Separation of Concerns**: Plugin focuses on data capture, API handles persistence
2. **Flexibility**: Plugin doesn't need to know about entity creation logic
3. **Testability**: Each layer can be tested independently
4. **Maintainability**: Changes to entity structure don't affect plugin

---

## Related Documentation

- [WorldTask Requirements](docs/world-tasks/REQUIREMENTS_WORLDTASK.md)
- [WorldTask API Contract](docs/world-tasks/API_CONTRACT.md)
- [LocationTaskHandler Integration](docs/world-tasks/LOCATION_HANDLER_INTEGRATION.md)
- [Hybrid Create Flow](docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md)

---

## Future Enhancements

1. **Direct Location API Call**: Plugin could call POST /api/Locations directly to get locationId before completing task
2. **Batch Processing**: Workflow finalization could batch-create multiple entities from task outputs
3. **Validation**: Add JSON Schema validation for task outputs
4. **Versioning**: Support multiple output JSON formats for backward compatibility
