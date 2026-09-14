# WorldTask API Contract

## Overview

This document defines the complete API contract for WorldTask operations across the Web API endpoints that the plugin and web app interact with.

## Base URL

```
https://api.knightsandkings.local/api
```

## Endpoints

### 1. Get Task Details

**Endpoint:** `GET /worldtasks/{id}`

**Description:** Retrieve full details of a WorldTask by ID

**Path Parameters:**
- `id` (integer, required): WorldTask ID

**Response: 200 OK**

```json
{
  "id": 1,
  "workflowSessionId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "fieldName": "WgRegionId",
  "taskType": "DefineRegion",
  "status": "InProgress",
  "linkCode": "ABC123",
  "assignedUserId": 5,
  "claimedByServerId": "main-server",
  "claimedByMinecraftUsername": "PlayerName",
  "inputJson": "{\"parentRegionId\": \"town_main\"}",
  "outputJson": null,
  "errorMessage": null,
  "createdAt": "2025-01-27T10:30:00Z",
  "claimedAt": "2025-01-27T10:35:00Z",
  "updatedAt": "2025-01-27T10:35:00Z",
  "completedAt": null
}
```

**Error Responses:**
- `404 Not Found`: Task with given ID does not exist
- `500 Internal Server Error`: Unexpected error retrieving task

---

### 2. Get Task by LinkCode

**Endpoint:** `GET /worldtasks/by-link-code/{linkCode}`

**Description:** Retrieve task by LinkCode (used by plugin to claim tasks)

**Path Parameters:**
- `linkCode` (string, required): 6-character unique code

**Query Parameters:**
- None

**Response: 200 OK**

```json
{
  "id": 1,
  "workflowSessionId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "fieldName": "WgRegionId",
  "taskType": "DefineRegion",
  "status": "Pending",
  "linkCode": "ABC123",
  "assignedUserId": null,
  "claimedByServerId": null,
  "claimedByMinecraftUsername": null,
  "inputJson": "{\"parentRegionId\": \"town_main\"}",
  "outputJson": null,
  "errorMessage": null,
  "createdAt": "2025-01-27T10:30:00Z",
  "claimedAt": null,
  "updatedAt": null,
  "completedAt": null
}
```

**Error Responses:**
- `404 Not Found`: Task with given LinkCode does not exist
- `400 Bad Request`: Invalid LinkCode format
- `500 Internal Server Error`: Unexpected error

**Plugin Usage:**
```java
worldTasksApi.getByLinkCode("ABC123")
    .thenAccept(task -> {
        String fieldName = task.getFieldName();  // "Location", "WgRegionId", etc.
        String inputJson = task.getInputJson();  // Constraints
        registry.startTask(player, fieldName, task.getId(), inputJson);
    });
```

---

### 3. List Tasks by Status

**Endpoint:** `GET /worldtasks/status/{status}`

**Description:** List tasks with a specific status (used by plugin for discovery)

**Path Parameters:**
- `status` (string, required): One of: `Pending`, `InProgress`, `Completed`, `Failed`, `Cancelled`

**Query Parameters:**
- `serverId` (string, optional): Filter by server ID claiming the task
- `pageNumber` (integer, optional, default: 1): Pagination page
- `pageSize` (integer, optional, default: 20): Items per page

**Response: 200 OK**

```json
{
  "items": [
    {
      "id": 1,
      "workflowSessionId": 42,
      "stepNumber": 1,
      "stepKey": "region-selection",
      "fieldName": "WgRegionId",
      "taskType": "DefineRegion",
      "status": "Pending",
      "linkCode": "ABC123",
      "assignedUserId": null,
      "claimedByServerId": null,
      "claimedByMinecraftUsername": null,
      "inputJson": "{\"parentRegionId\": \"town_main\"}",
      "outputJson": null,
      "errorMessage": null,
      "createdAt": "2025-01-27T10:30:00Z",
      "claimedAt": null,
      "updatedAt": null,
      "completedAt": null
    }
  ],
  "totalCount": 1,
  "pageNumber": 1,
  "pageSize": 20
}
```

**Plugin Usage:**
```java
worldTasksApi.listByStatus("Pending")
    .thenAccept(tasks -> {
        for (WorldTaskDto task : tasks) {
            player.sendMessage("LinkCode: " + task.getLinkCode() + 
                             " - " + task.getFieldName());
        }
    });
```

---

### 4. Claim Task

**Endpoint:** `POST /worldtasks/{id}/claim`

**Description:** Claim a task (transition Pending → InProgress)

**Path Parameters:**
- `id` (integer, required): WorldTask ID

**Request Body:**

```json
{
  "linkCode": "ABC123",
  "serverId": "main-server",
  "minecraftUsername": "PlayerName"
}
```

**Request Fields:**
- `linkCode` (string, required): Must match the task's LinkCode
- `serverId` (string, required): Minecraft server ID handling the claim
- `minecraftUsername` (string, required): Player who claimed the task

**Response: 200 OK**

```json
{
  "id": 1,
  "workflowSessionId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "fieldName": "WgRegionId",
  "taskType": "DefineRegion",
  "status": "InProgress",
  "linkCode": "ABC123",
  "assignedUserId": null,
  "claimedByServerId": "main-server",
  "claimedByMinecraftUsername": "PlayerName",
  "inputJson": "{\"parentRegionId\": \"town_main\"}",
  "outputJson": null,
  "errorMessage": null,
  "createdAt": "2025-01-27T10:30:00Z",
  "claimedAt": "2025-01-27T10:35:00Z",
  "updatedAt": "2025-01-27T10:35:00Z",
  "completedAt": null
}
```

**Error Responses:**
- `404 Not Found`: Task does not exist
- `400 Bad Request`: LinkCode mismatch or invalid state (must be Pending)
- `409 Conflict`: Task already claimed by another player
- `500 Internal Server Error`: Unexpected error

**Plugin Usage:**
```java
worldTasksApi.claim(taskId, "main-server", "PlayerName")
    .thenAccept(claimedTask -> {
        String fieldName = claimedTask.getFieldName();
        registry.startTask(player, fieldName, taskId, 
                          claimedTask.getInputJson());
    });
```

---

### 5. Complete Task

**Endpoint:** `POST /worldtasks/{id}/complete`

**Description:** Mark task as completed with captured data

**Path Parameters:**
- `id` (integer, required): WorldTask ID

**Request Body:**

```json
{
  "outputJson": "{\"fieldName\": \"Location\", \"x\": 100.5, \"y\": 64.0, \"z\": -200.3, \"yaw\": 45.0, \"pitch\": -25.0, \"worldName\": \"world\", \"capturedAt\": 1674845123456}"
}
```

**Request Fields:**
- `outputJson` (string, required): JSON containing captured data
  - Must be valid JSON
  - Must include `fieldName` matching the task's FieldName
  - Schema varies by handler type

**Response: 200 OK**

```json
{
  "id": 1,
  "workflowSessionId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "fieldName": "Location",
  "taskType": "CaptureLocation",
  "status": "Completed",
  "linkCode": "ABC123",
  "assignedUserId": null,
  "claimedByServerId": "main-server",
  "claimedByMinecraftUsername": "PlayerName",
  "inputJson": null,
  "outputJson": "{\"fieldName\": \"Location\", \"x\": 100.5, \"y\": 64.0, \"z\": -200.3, \"yaw\": 45.0, \"pitch\": -25.0, \"worldName\": \"world\", \"capturedAt\": 1674845123456}",
  "errorMessage": null,
  "createdAt": "2025-01-27T10:30:00Z",
  "claimedAt": "2025-01-27T10:35:00Z",
  "updatedAt": "2025-01-27T10:40:00Z",
  "completedAt": "2025-01-27T10:40:00Z"
}
```

**Side Effects:**
- Task status transitions to `Completed`
- Task `CompletedAt` timestamp is set
- Corresponding `StepProgress` record is marked `Completed`
- Workflow is checked for completion (if all steps done, ready for finalization)

**Error Responses:**
- `404 Not Found`: Task does not exist
- `400 Bad Request`: Invalid OutputJson (must be valid JSON)
- `409 Conflict`: Task not in InProgress state
- `500 Internal Server Error`: Unexpected error

**Plugin Usage:**
```java
JsonObject output = new JsonObject();
output.addProperty("fieldName", "Location");
output.addProperty("x", location.getX());
output.addProperty("y", location.getY());
output.addProperty("z", location.getZ());
output.addProperty("yaw", location.getYaw());
output.addProperty("pitch", location.getPitch());
output.addProperty("worldName", world.getName());
output.addProperty("capturedAt", System.currentTimeMillis());

worldTasksApi.complete(taskId, output.toString())
    .thenAccept(completedTask -> {
        player.sendMessage("§a✓ Task completed!");
    });
```

---

### 6. Fail Task

**Endpoint:** `POST /worldtasks/{id}/fail`

**Description:** Mark task as failed with error message

**Path Parameters:**
- `id` (integer, required): WorldTask ID

**Request Body:**

```json
{
  "errorMessage": "Parent region not found: town_main"
}
```

**Request Fields:**
- `errorMessage` (string, required): Description of failure reason
  - Must not be empty
  - Should be player-friendly if possible
  - Max 500 characters

**Response: 200 OK**

```json
{
  "id": 1,
  "workflowSessionId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "fieldName": "WgRegionId",
  "taskType": "DefineRegion",
  "status": "Failed",
  "linkCode": "ABC123",
  "assignedUserId": null,
  "claimedByServerId": "main-server",
  "claimedByMinecraftUsername": "PlayerName",
  "inputJson": "{\"parentRegionId\": \"town_main\"}",
  "outputJson": null,
  "errorMessage": "Parent region not found: town_main",
  "createdAt": "2025-01-27T10:30:00Z",
  "claimedAt": "2025-01-27T10:35:00Z",
  "updatedAt": "2025-01-27T10:40:00Z",
  "completedAt": null
}
```

**Error Responses:**
- `404 Not Found`: Task does not exist
- `400 Bad Request`: Empty error message
- `409 Conflict`: Task not in InProgress state
- `500 Internal Server Error`: Unexpected error

**Plugin Usage:**
```java
worldTasksApi.fail(taskId, "Selection is not inside parent region: town_main")
    .thenAccept(failedTask -> {
        player.sendMessage("§c✗ Task failed: " + failedTask.getErrorMessage());
    });
```

---

### 7. Update Workflow Step

**Endpoint:** `PUT /api/workflows/{id}/steps/{stepNumber}`

**Description:** Update step progress (called by WorkflowService when task completes)

**Path Parameters:**
- `id` (integer, required): Workflow ID
- `stepNumber` (integer, required): Step number to update

**Request Body:**

```json
{
  "status": "Completed",
  "completedAt": "2025-01-27T10:40:00Z"
}
```

**Response: 200 OK**

```json
{
  "id": 101,
  "workflowId": 42,
  "stepNumber": 1,
  "stepKey": "region-selection",
  "status": "Completed",
  "completedAt": "2025-01-27T10:40:00Z"
}
```

---

### 8. Finalize Workflow

**Endpoint:** `POST /api/workflows/{id}/finalize`

**Description:** Finalize workflow and create/update entity

**Path Parameters:**
- `id` (integer, required): Workflow ID

**Request Body:**

```json
{}
```

**Response: 200 OK**

```json
{
  "id": 1,
  "name": "New Town",
  "description": "A thriving settlement",
  "allowEntry": true,
  "allowExit": true,
  "regionId": "domain_1",
  "locationId": 42,
  // ... other entity fields
}
```

**Side Effects:**
- All completed task data is extracted
- Data is mapped to entity properties
- Entity is created or updated
- Workflow status transitions to Completed

---

## Data Types

### WorldTaskDto

```typescript
interface WorldTaskDto {
  id: number;
  workflowSessionId: number;
  stepNumber?: number;
  stepKey?: string;
  fieldName?: string;
  taskType: string;
  status: "Pending" | "InProgress" | "Completed" | "Failed" | "Cancelled";
  linkCode?: string;
  assignedUserId?: number;
  claimedByServerId?: string;
  claimedByMinecraftUsername?: string;
  inputJson?: string;
  outputJson?: string;
  errorMessage?: string;
  createdAt: string;  // ISO 8601 timestamp
  claimedAt?: string;
  updatedAt?: string;
  completedAt?: string;
}
```

### ClaimTaskDto

```typescript
interface ClaimTaskDto {
  linkCode: string;
  serverId: string;
  minecraftUsername: string;
}
```

### CompleteTaskDto

```typescript
interface CompleteTaskDto {
  outputJson: string;  // Must be valid JSON
}
```

### FailTaskDto

```typescript
interface FailTaskDto {
  errorMessage: string;  // 1-500 characters
}
```

---

## OutputJson Schemas by FieldName

### Location

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

### WgRegionId

```json
{
  "fieldName": "WgRegionId",
  "regionId": "domain_12345",
  "createdAt": 1674845123456,
  "worldName": "world",
  "parentRegionId": "town_main"
}
```

---

## Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad Request | Check request format, required fields, or constraint violations |
| 404 | Not Found | Task/resource doesn't exist; verify ID/LinkCode |
| 409 | Conflict | Task state invalid for operation (e.g., claim non-Pending task) |
| 500 | Internal Server Error | Server error; check logs, retry with exponential backoff |

---

## Rate Limiting

- No explicit rate limiting documented
- Plugin should implement client-side backoff for retries
- Web app polling at 3-second intervals is acceptable

---

## Caching

- LinkCode lookups should not be cached (consistency critical)
- Status list queries can be cached for 5 seconds
- Task details can be cached for 1 second

---

## Examples

### Complete Plugin Flow

```java
// 1. Admin creates task from web app
// LinkCode "ABC123" is generated

// 2. Player joins Minecraft server
// 3. Player claims task
/worldtask claim ABC123

// Plugin:
worldTasksApi.getByLinkCode("ABC123")
    .thenAccept(task -> {
        worldTasksApi.claim(task.getId(), "main-server", "PlayerName")
            .thenAccept(claimedTask -> {
                registry.startTask(player, claimedTask.getFieldName(), 
                                 claimedTask.getId(), 
                                 claimedTask.getInputJson());
                player.sendMessage("Task started: " + 
                                 claimedTask.getFieldName());
            });
    });

// 4. Player executes task
// /say save

// Handler:
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

worldTasksApi.complete(taskId, output.toString())
    .thenAccept(completedTask -> {
        player.sendMessage("§a✓ Location captured and saved!");
    });

// 5. Web app polls and detects completion
// GET /worldtasks/{id} returns status: "Completed"

// 6. Admin clicks "Create" button
// POST /workflows/{id}/finalize
// → Entity is created with location data
```

