# WorldTask Technical Specification

## 1. Data Model

### WorldTask Entity

```csharp
public class WorldTask
{
    // Identity
    public int Id { get; set; }

    // Workflow Association
    public int WorkflowSessionId { get; set; }
    public WorkflowSession WorkflowSession { get; set; }

    // Step Mapping
    public int? StepNumber { get; set; }           // Which step in the workflow
    public string? StepKey { get; set; }           // Step identifier (e.g., "region-config")
    public string? FieldName { get; set; }         // Target field (e.g., "Location", "WgRegionId")

    // Task Definition
    public string TaskType { get; set; }           // e.g., "CaptureLocation", "DefineRegion"
    public string Status { get; set; }             // Pending | InProgress | Completed | Failed | Cancelled

    // Claiming & Execution
    public string? LinkCode { get; set; }          // 6-char unique code for in-game claiming
    public int? AssignedUserId { get; set; }       // API user who created the task
    public string? ClaimedByServerId { get; set; } // Server that handled the claim
    public string? ClaimedByMinecraftUsername { get; set; } // Player who claimed it

    // Data Payloads
    public string? InputJson { get; set; }         // Task input (constraints, parent region, etc.)
    public string? OutputJson { get; set; }        // Task output (captured data)
    public string? ErrorMessage { get; set; }      // Failure reason if status is Failed

    // Timestamps
    public DateTime CreatedAt { get; set; }
    public DateTime? ClaimedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}
```

### Task Lifecycle States

```
Pending ──[claim]──> InProgress ──[complete]──> Completed
                          ├─────[fail]────────> Failed
                          └─────[cancel]─────> Cancelled
```

**State Transitions:**
- **Pending**: Initial state, awaiting claim in Minecraft
- **InProgress**: Claimed and player is executing the task
- **Completed**: Task data captured and validated successfully
- **Failed**: Task execution failed (error captured in ErrorMessage)
- **Cancelled**: Task abandoned before completion

## 2. Input/Output JSON Schemas

### Location Task

**InputJson:**
```json
{
  "fieldName": "Location",
  // Additional constraints can be added here
}
```

**OutputJson:**
```json
{
  "fieldName": "Location",
  "x": 100.5,
  "y": 64.0,
  "z": -200.3,
  "yaw": 45.0,
  "pitch": -25.0,
  "worldName": "world",
  "capturedAt": 1674845123456
}
```

### WgRegionId Task

**InputJson:**
```json
{
  "parentRegionId": "town_main",  // Optional: region must be inside this parent
  "priority": 0                    // Optional: region priority
}
```

**OutputJson:**
```json
{
  "fieldName": "WgRegionId",
  "regionId": "domain_12345",
  "createdAt": 1674845123456,
  "worldName": "world",
  "parentRegionId": "town_main"  // If applicable
}
```

## 3. LinkCode Generation

- **Format**: 6-character alphanumeric string (A-Z, 0-9)
- **Uniqueness**: Database unique constraint
- **Generation**: Random with collision detection
- **Usage**: Player claims task via `/worldtask claim {linkCode}`
- **Security**: Non-sequential, non-guessable

Example LinkCodes: `ABC123`, `XYZ789`, `K9P2WQ`

## 4. API DTOs

### WorldTaskReadDto

```csharp
public class WorldTaskReadDto
{
    public int Id { get; set; }
    public int WorkflowSessionId { get; set; }
    public int? StepNumber { get; set; }
    public string? StepKey { get; set; }
    public string? FieldName { get; set; }
    public string TaskType { get; set; }
    public string Status { get; set; }
    public string? LinkCode { get; set; }
    public int? AssignedUserId { get; set; }
    public string? ClaimedByServerId { get; set; }
    public string? ClaimedByMinecraftUsername { get; set; }
    public string? InputJson { get; set; }
    public string? OutputJson { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ClaimedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}
```

### WorldTaskCreateDto

```csharp
public class WorldTaskCreateDto
{
    public int WorkflowSessionId { get; set; }
    public int? StepNumber { get; set; }
    public string? StepKey { get; set; }
    public string FieldName { get; set; }
    public string TaskType { get; set; }
    public string? InputJson { get; set; }
    public string? PayloadJson { get; set; }  // Legacy, prefer InputJson
}
```

### ClaimTaskDto

```csharp
public class ClaimTaskDto
{
    public string LinkCode { get; set; }
    public string? ServerId { get; set; }
    public string? MinecraftUsername { get; set; }
}
```

### CompleteTaskDto

```csharp
public class CompleteTaskDto
{
    public string OutputJson { get; set; }
}
```

### FailTaskDto

```csharp
public class FailTaskDto
{
    public string ErrorMessage { get; set; }
}
```

## 5. Workflow Step Association

When a WorldTask is created:
1. It references a `StepKey` (e.g., "region-config") and `StepNumber` (e.g., 2)
2. Upon task completion:
   - The corresponding `StepProgress` record is marked as `Completed`
   - The `OutputJson` is stored for the workflow to process
3. When the workflow is finalized:
   - Workflow service retrieves completed task data
   - Data is mapped to entity properties
   - Entity is created or updated

## 6. Idempotency & Concurrency

### LinkCode Generation
- Unique constraint prevents duplicates
- Collision detection with retry loop
- Multiple task creations for same field are separate tasks

### State Transitions
- Each state change updates `UpdatedAt` timestamp
- Claim operation is idempotent if re-claimed by same player
- Completion stores `CompletedAt` timestamp
- Row version (RowVersion on WorkflowSession) prevents stale updates

### Error Handling
- Validation errors throw exceptions before entity creation
- Runtime errors during processing set task to `Failed` status
- ErrorMessage field captures error details for debugging
- Player receives feedback in-game with error description

## 7. Plugin Integration Points

### Handler Registry Pattern

```java
// Register handlers during plugin initialization
WorldTaskHandlerRegistry registry = new WorldTaskHandlerRegistry();
registry.registerHandler(new WgRegionIdTaskHandler(worldTasksApi, plugin));
registry.registerHandler(new LocationTaskHandler(worldTasksApi, plugin));

// Route incoming tasks to appropriate handler
registry.startTask(player, fieldName, taskId, inputJson);

// Monitor active tasks
if (registry.isHandlingAnyTask(player)) {
    // Player is in a world task
}
```

### Chat Command Integration

```java
// Admin claims a task
/worldtask claim ABC123
  → Plugin looks up task by LinkCode
  → Calls handler.startTask(player, taskId, inputJson)
  → Task enters "InProgress" state

// Player executes task command
/say save
  → Chat listener intercepts
  → Finds active handler for player
  → Calls handler.onPlayerChat(player, "save")
  → Handler captures data and calls worldTasksApi.complete(taskId, outputJson)
```

### Event Listeners

```java
// Player events that might affect tasks
- PlayerQuitEvent: Cancel active tasks for player
- RegionEnterEvent: Can trigger region claim callbacks (deprecated)
- BlockBreakEvent: Could validate region selection changes
```

## 8. Minecraft Server Integration

### WorldTasksApi (Plugin-side interface)

```java
public interface WorldTasksApi {
    // Get a task by LinkCode
    CompletableFuture<WorldTaskDto> getByLinkCode(String linkCode);
    
    // Get all tasks with a status
    CompletableFuture<List<WorldTaskDto>> listByStatus(String status);
    
    // Claim a task (transition Pending → InProgress)
    CompletableFuture<WorldTaskDto> claim(int taskId, String serverId, String username);
    
    // Complete a task with output data
    CompletableFuture<WorldTaskDto> complete(int taskId, String outputJson);
    
    // Fail a task with error message
    CompletableFuture<WorldTaskDto> fail(int taskId, String errorMessage);
}
```

### WorldTasksApiImpl

HTTP client implementation that calls the Web API endpoints:
- Handles async request/response (CompletableFuture)
- JSON serialization/deserialization
- Error handling and retry logic
- Integrates with existing KnkApiClient infrastructure

