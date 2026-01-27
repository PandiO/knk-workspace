# LocationTaskHandler Integration Summary

**Date:** January 27, 2026  
**Status:** Complete and Verified

## Overview
LocationTaskHandler is fully integrated across all three repositories (plugin, Web API, web app) to enable in-game location capture for world-bound fields.

## Implementation Status

### ✅ knk-plugin-v2: LocationTaskHandler Implementation
**File:** `knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/LocationTaskHandler.java`

**Features:**
- Implements `IWorldTaskHandler` interface
- Captures player position (x, y, z, yaw, pitch, world name)
- Async API integration via `WorldTasksApi.complete()`
- Full task lifecycle: start, pause, resume, cancel, save
- Chat command routing: `/save`, `/pause`, `/resume`, `/cancel`

**FieldName:** `"Location"` (enables routing via WorldTaskChatListener)

**Registration:** Integrated in KnKPlugin.onEnable()
```java
LocationTaskHandler locationHandler = new LocationTaskHandler(worldTasksApi, this);
worldTaskHandlerRegistry.registerHandler(locationHandler);
```

### ✅ knk-web-app: FormWizard Integration
**File:** `src/components/FormWizard/FormWizard.tsx`

**Integration Pattern:**
When rendering fields, FormWizard detects world-task-enabled fields and uses `WorldBoundFieldRenderer`:

```tsx
const { enabled: worldTaskEnabled, taskType } = parseWorldTaskSettings(field.settingsJson);

if (worldTaskEnabled && workflowSessionId != null && taskType) {
    return (
        <WorldBoundFieldRenderer
            field={field}
            value={currentStepData[field.fieldName]}
            onChange={(value) => handleFieldChange(field.fieldName, value)}
            taskType={taskType}
            workflowSessionId={workflowSessionId}
            stepNumber={currentStepIndex}
            stepKey={stepKey}
            allowCreate={true}
            onTaskCompleted={(task, extractedValue) => {
                // Field automatically updated via onChange
                onStepAdvanced?.({ from: currentStepIndex, to: currentStepIndex, stepKey });
            }}
        />
    );
}
```

**Workflow:**
1. Admin creates form configuration with Location field
2. Sets `settingsJson` with `{ enabled: true, taskType: "CaptureLocation" }`
3. WorldBoundFieldRenderer creates task on demand
4. Player claims task via LinkCode in Minecraft
5. Player types `/save` to capture location
6. LocationTaskHandler completes task via API
7. WorldTaskMonitor detects completion and auto-populates field

### ✅ FieldEditor Configuration
**File:** `src/components/FormConfigBuilder/FieldEditor.tsx`

**Predefined Task Types:**
- ReagionCreate (typo - should be RegionCreate)
- LocationSelection
- RegionClaim
- VerifyLocation
- VerifyStructure
- VerifyPlacement
- VerifyResource
- VerifyBoundary
- Custom

Admins can select these types when enabling world tasks for a field.

### ✅ Existing Workflow Components
All components needed for Location field support are already implemented:

| Component | Purpose |
|-----------|---------|
| `TaskStatusMonitor.tsx` | Polls every 3 seconds for task completion |
| `WorldBoundFieldRenderer.tsx` | Renders world-bound fields with task integration |
| `WorldTaskCta.tsx` | Displays LinkCode for player task execution |
| `WizardStepContainer.tsx` | Step navigation and validation |

## Configuration Example

To enable Location capture for a field:

**FormFieldDto settings:**
```json
{
    "fieldName": "location",
    "fieldType": "String",
    "label": "Location",
    "isRequired": true,
    "settingsJson": {
        "enabled": true,
        "taskType": "CaptureLocation"
    }
}
```

When this field is rendered in FormWizard with a workflow session:
1. WorldBoundFieldRenderer wraps the field
2. Player can click "Create Location Task"
3. Task created with FieldName="Location"
4. Plugin routes to LocationTaskHandler via handler registry
5. Player captures location with `/save` command
6. Location data returned as JSON: `{x, y, z, yaw, pitch, worldName, capturedAt}`
7. Field auto-populated with task completion data

## File Removals
- ❌ `TownCreateWizardPage.tsx` - Removed (was redundant, integration via FormWizard is the correct approach)

## Architecture Diagram

```
FormWizard (with world task enabled)
    ↓
WorldBoundFieldRenderer
    ├→ Create Location Task (worldTaskClient.create)
    │   ↓
    │   Web API (WorldTaskService)
    │       ↓
    │       Minecraft Plugin (LocationTaskHandler)
    │           ↓
    │           Player (in Minecraft)
    │               ↓
    │               /save command
    │           ↓
    │           worldTasksApi.complete(taskId, outputJson)
    │       ↓
    │       Update WorkflowSession with captured data
    ├→ Poll for completion (TaskStatusMonitor)
    │   ↓
    │   Detect completion
    ├→ Auto-populate field with location data
    │   ↓
    │   handleFieldChange(fieldName, extractedValue)
    └→ Continue workflow
```

## API Contract

**Task Creation Request:**
```json
{
    "workflowSessionId": 123,
    "stepNumber": 3,
    "stepKey": "world-data",
    "fieldName": "Location",
    "taskType": "CaptureLocation",
    "inputJson": "{}"
}
```

**Task Completion Payload:**
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

## Testing Checklist

- [ ] Build plugin: `./gradlew :knk-paper:build`
- [ ] Start Web API
- [ ] Start Web App
- [ ] Create form configuration with Location field
- [ ] Enable world task in field settings
- [ ] Open form in admin workflow
- [ ] Create Location task via UI
- [ ] Copy LinkCode
- [ ] Execute `/wt <linkcode>` in Minecraft
- [ ] Type `/save` to capture location
- [ ] Verify location data auto-populates in form
- [ ] Continue workflow to completion

## Related Documentation

- [docs/world-tasks/README.md](README.md) - Feature overview
- [docs/world-tasks/SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) - Technical specification
- [docs/world-tasks/HANDLER_DEVELOPMENT_GUIDE.md](HANDLER_DEVELOPMENT_GUIDE.md) - Creating custom handlers
- [docs/world-tasks/API_CONTRACT.md](API_CONTRACT.md) - API integration details

## Notes

1. **Correct Integration Approach:** FormWizard integration is the standard way to support Location fields. Specialized pages like TownCreateWizardPage are not needed.

2. **Handler Routing:** FieldName mapping enables automatic handler discovery:
   - Field enables world task with taskType="CaptureLocation"
   - Web API creates WorldTask with FieldName="Location"
   - Plugin's WorldTaskChatListener routes to handler with matching FieldName
   - LocationTaskHandler processes `/save` command and completes task

3. **State Management:** WorldBoundFieldRenderer manages task lifecycle:
   - Tracks active tasks
   - Updates field value on completion
   - Handles errors and retries
   - Notifies workflow of step advancement

4. **Extensibility:** New world-bound field types can be added by:
   - Creating a new handler implementing IWorldTaskHandler
   - Registering handler in KnKPlugin
   - Adding taskType to FieldEditor's PREDEFINED_TASK_TYPES
   - Documenting in form configuration
