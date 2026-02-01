# WorldTask Handler Activation Guide

## Overview

This guide explains how the WorldTask feature is activated from the web app when creating or editing entities, and what specific types/IDs need to be provided from the web app to the API.

## Handler Activation Flow

### 1. Web App: Identify World-Bound Fields

When a form wizard is rendered, the system checks each field's configuration:

```typescript
// In TownCreateWizardPage or FormWizardPage
const formConfig: FormConfigurationReadDto = { /* ... */ };
const formFields: FormFieldReadDto[] = formConfig.fields;

const worldBoundFields = formFields.filter(field => 
  field.requiresMinecraft === true  // Key property!
);

if (worldBoundFields.length > 0) {
  // This step requires Minecraft tasks
}
```

**Key Property:** `requiresMinecraft: boolean` on FormFieldReadDto

This property indicates that a field needs world-bound data captured via Minecraft.

---

### 2. Web App: Determine Field Type/Handler Name

Each world-bound field maps to a specific task handler via its `fieldName`:

```typescript
interface WorldBoundField {
  id: number;
  fieldName: string;      // "Location" | "WgRegionId" | custom
  displayName: string;    // "Player Location" | "Territory Region"
  requiresMinecraft: true;
  taskType: string;       // "CaptureLocation" | "DefineRegion"
  inputConstraints?: {    // Optional constraints
    parentRegionId?: string;
    priority?: number;
  };
}
```

**Supported FieldNames:**
- `"Location"` → LocationTaskHandler
- `"WgRegionId"` → WgRegionIdTaskHandler
- (Extensible for custom handlers)

---

### 3. Web App: Create WorldTask

The web app creates a task by calling the API with the FieldName:

```typescript
// POST /api/worldtasks
const createTaskRequest = {
  workflowSessionId: workflow.id,          // Which workflow
  stepNumber: currentStep,                  // Which step
  stepKey: "world-data-collection",        // Step identifier
  fieldName: "Location",                   // Handler selector: "Location" or "WgRegionId"
  taskType: "CaptureLocation",             // Task type
  inputJson: JSON.stringify({              // Handler-specific constraints
    // For Location: usually empty
    // For WgRegionId: { parentRegionId?: string, priority?: number }
  })
};

const task = await worldTaskClient.create(createTaskRequest);
// Returns: { id: 1, linkCode: "ABC123", ... }
```

**Critical Field:** `fieldName`
- This determines which handler is invoked on the plugin side
- Must match a registered handler's getFieldName() return value
- Case-sensitive

---

### 4. Web App: Display LinkCode

The generated LinkCode is displayed to the admin:

```typescript
export const TownCreateWizardPage = () => {
  const [task, setTask] = useState<WorldTaskReadDto | null>(null);

  useEffect(() => {
    // Create task when reaching world-data step
    if (currentStep === 3) {
      createTask("Location", "CaptureLocation", {}).then(setTask);
    }
  }, [currentStep]);

  return (
    <>
      {task && (
        <WorldBoundFieldRenderer
          task={task}
          instructions="Stand where you want to mark this location and type 'save' in Minecraft"
        >
          <TaskStatusMonitor 
            taskId={task.id} 
            onCompleted={handleLocationCaptured}
          />
        </WorldBoundFieldRenderer>
      )}
    </>
  );
};
```

Display output to admin:
```
LinkCode: ABC123
Minecraft Instructions:
1. Join the server
2. Type: /worldtask claim ABC123
3. Type: save
```

---

### 5. Plugin: Handler Routing

When the player claims the task, the plugin routes it:

```java
// Player types: /worldtask claim ABC123
// Plugin calls:

worldTasksApi.getByLinkCode("ABC123")
    .thenAccept(task -> {
        String fieldName = task.getFieldName();  // e.g., "Location"
        String inputJson = task.getInputJson();   // e.g., "{}"
        
        // Route to handler by fieldName
        if (registry.startTask(player, fieldName, task.getId(), inputJson)) {
            // Handler found and started
            player.sendMessage("§6Task started: " + fieldName);
        } else {
            // No handler registered for this fieldName
            player.sendMessage("§cError: No handler for field: " + fieldName);
        }
    });
```

**Handler Discovery:**
The FieldName value is used as a key to find the handler:
```java
public boolean startTask(String fieldName, ...) {
    IWorldTaskHandler handler = handlers.get(fieldName);  // "Location" lookup
    if (handler != null) {
        handler.startTask(player, taskId, inputJson);
        return true;
    }
    return false;
}
```

---

### 6. Plugin: Handler Execution

The handler executes its logic:

```java
// LocationTaskHandler.startTask() is called
public void startTask(Player player, int taskId, String inputJson) {
    player.sendMessage("§6[WorldTask] Capture your current location.");
    player.sendMessage("§eType 'save' to capture...");
}

// Player types "save"
// LocationTaskHandler.onPlayerChat() is called
public boolean onPlayerChat(Player player, String message) {
    if (message.trim().toLowerCase().equals("save")) {
        // Capture location
        Location loc = player.getLocation();
        JsonObject output = new JsonObject();
        output.addProperty("fieldName", "Location");
        output.addProperty("x", loc.getX());
        output.addProperty("y", loc.getY());
        output.addProperty("z", loc.getZ());
        output.addProperty("yaw", loc.getYaw());
        output.addProperty("pitch", loc.getPitch());
        output.addProperty("worldName", loc.getWorld().getName());
        output.addProperty("capturedAt", System.currentTimeMillis());
        
        // Complete task with output
        completeTask(player, context, output.toString());
        return true;
    }
    return false;
}
```

---

### 7. API: Update StepProgress

When task completes, the API updates the workflow:

```csharp
// WorldTaskService.CompleteAsync()
public async Task<WorldTaskReadDto> CompleteAsync(int taskId, string outputJson)
{
    var task = await _taskRepo.GetByIdAsync(taskId);
    task.Status = "Completed";
    task.OutputJson = outputJson;
    task.CompletedAt = DateTime.UtcNow;
    
    // Link to step progress
    if (!string.IsNullOrWhiteSpace(task.StepKey))
    {
        var step = await _workflowRepo.GetStepAsync(
            task.WorkflowSessionId, 
            task.StepKey
        );
        if (step != null)
        {
            step.Status = "Completed";
            step.CompletedAt = DateTime.UtcNow;
            await _workflowRepo.UpdateStepAsync(step);
        }
    }
    
    await _taskRepo.UpdateAsync(task);
    return _mapper.Map<WorldTaskReadDto>(task);
}
```

---

### 8. Web App: Detect Completion

The TaskStatusMonitor polls and detects completion:

```typescript
// TaskStatusMonitor component
useEffect(() => {
  const interval = setInterval(() => {
    worldTaskClient.getById(taskId).then(task => {
      setStatus(task.status);
      
      if (task.status === "Completed") {
        // Task complete!
        setData(JSON.parse(task.outputJson));
        onCompleted(task);  // Callback to form
      } else if (task.status === "Failed") {
        setError(task.errorMessage);
      }
    });
  }, 3000);  // Poll every 3 seconds
  
  return () => clearInterval(interval);
}, [taskId]);
```

---

### 9. Web App: Finalize Entity

When all world-bound fields are captured, admin clicks "Create":

```typescript
const handleCreate = async () => {
  // All tasks completed, all field data captured
  const payload = {
    workflowSessionId: workflow.id,
    // Gathered data from all steps:
    // - Step 1 data (name, description)
    // - Step 2 data (rules)
    // - Step 3 data from tasks (location, region)
  };
  
  // Create the entity
  const town = await workflowClient.finalize(workflow.id);
  
  // Town now has:
  // - name, description (from step 1)
  // - allowEntry, allowExit (from step 2)
  // - locationId, regionId (from captured tasks)
};
```

---

## Summary: What to Provide from Web App

### To Activate a Handler

When creating a WorldTask, provide:

```json
{
  "workflowSessionId": <number>,           // Required: Links to workflow
  "stepNumber": <number>,                  // Required: Which step
  "stepKey": <string>,                     // Required: Step identifier
  "fieldName": "Location",                 // Required: Handler selector
  "taskType": "CaptureLocation",           // Required: Task type
  "inputJson": "{}"                        // Optional: Handler-specific input
}
```

### FieldName Values (Handler Selectors)

| FieldName | Handler Class | Data Captured | InputJson Schema |
|-----------|---------------|---------------|------------------|
| `Location` | `LocationTaskHandler` | x, y, z, yaw, pitch, worldName | `{}` or custom constraints |
| `WgRegionId` | `WgRegionIdTaskHandler` | regionId, worldName, parentRegionId | `{ parentRegionId?, priority? }` |

### How Handlers Are Selected

```
FieldName property value
    ↓
[Used as key in handler registry]
    ↓
handler.getFieldName() must return same string
    ↓
Handler instantiated and startTask() called
```

---

## Extending with New Handlers

To add a new handler (e.g., for a new field type):

### 1. Web App: Add FieldName to Forms

```typescript
// In form configuration
const formField = {
  fieldName: "CustomData",           // New FieldName
  displayName: "Custom World Data",
  requiresMinecraft: true,
  taskType: "CaptureCustomData",
  inputConstraints: { /* ... */ }
};
```

### 2. Plugin: Create Handler

```java
public class CustomDataTaskHandler implements IWorldTaskHandler {
    @Override
    public String getFieldName() {
        return "CustomData";  // Must match FieldName from web app
    }
    // ... implement interface methods
}
```

### 3. Plugin: Register Handler

```java
registry.registerHandler(new CustomDataTaskHandler(worldTasksApi, plugin));
```

### 4. Web App: Create Task with New FieldName

```typescript
const task = await worldTaskClient.create({
  // ...
  fieldName: "CustomData",  // Must match getFieldName()
  taskType: "CaptureCustomData"
});
```

---

## Common Issues & Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "No handler registered for field" | FieldName doesn't match any handler | Check FieldName spelling, ensure handler is registered |
| Plugin doesn't route to handler | Case mismatch in FieldName | Ensure case matches exactly (e.g., "Location" not "location") |
| Task created but never claimed | LinkCode not shared | Check web app displays LinkCode to admin |
| Handler never receives chat commands | Chat listener not registered | Verify PlayerChatEvent listener is enabled in plugin |
| Web app doesn't detect completion | TaskStatusMonitor polling stopped | Check browser console for JS errors, verify API endpoint |
| OutputJson missing data | Handler didn't capture all fields | Check handler's completeTask() method captures all properties |

---

## API Endpoint for Web App

### Create WorldTask

**Endpoint:** `POST /api/worldtasks`

**Request:**
```json
{
  "workflowSessionId": 42,
  "stepNumber": 2,
  "stepKey": "world-data",
  "fieldName": "Location",
  "taskType": "CaptureLocation",
  "inputJson": null
}
```

**Response:**
```json
{
  "id": 1,
  "workflowSessionId": 42,
  "linkCode": "ABC123",
  "status": "Pending",
  "fieldName": "Location",
  "createdAt": "2025-01-27T10:30:00Z"
}
```

Display `linkCode` to admin → admin shares with player → player claims in Minecraft → handler executes → task completes → web app detects and updates form.

