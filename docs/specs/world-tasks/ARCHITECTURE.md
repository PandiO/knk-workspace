# WorldTask System Architecture

## High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     KNIGHTS & KINGS WORKFLOW                     │
└─────────────────────────────────────────────────────────────────┘

┌─ Web App (React/TypeScript) ──────────────────────────────────┐
│                                                                 │
│  1. Admin creates entity (e.g., Town)                          │
│  2. Form wizard identified world-bound fields                  │
│  3. Create WorldTask via API                                   │
│  4. Display LinkCode to admin                                  │
│  5. Poll task status every 3 seconds                           │
│  6. When complete, extract OutputJson                          │
│  7. Finalize workflow & create entity                          │
│                                                                 │
│  Components: TownCreateWizardPage                              │
│             TaskStatusMonitor                                  │
│             WorldBoundFieldRenderer                            │
│             WizardStepContainer                                │
└─────────────────────────────────────────────────────────────────┘
          ↓                    ↓                    ↓
    POST /api/worldtasks    GET /api/worldtasks   POST /api/workflows/.../finalize
    POST /api/workflows       /by-link-code
    /steps/{n}/complete     GET /api/worldtasks
                             /status/{status}

┌─ Web API (.NET 6 C#) ─────────────────────────────────────────┐
│                                                                 │
│  Controllers:                                                  │
│  ├─ WorldTasksController (CRUD + lifecycle endpoints)          │
│  └─ WorkflowsController (step updates, finalization)           │
│                                                                 │
│  Services:                                                     │
│  ├─ WorldTaskService                                           │
│  │  ├─ Create (generate LinkCode, validate fields)             │
│  │  ├─ GetByLinkCode (plugin lookup)                           │
│  │  ├─ Claim (Pending → InProgress)                            │
│  │  ├─ Complete (InProgress → Completed, update StepProgress)  │
│  │  └─ Fail (InProgress → Failed)                              │
│  └─ WorkflowService                                            │
│     ├─ UpdateStep (when task completes)                        │
│     └─ Finalize (create entity from step data)                 │
│                                                                 │
│  Data Access:                                                  │
│  ├─ WorldTaskRepository                                        │
│  │  ├─ GetByLinkCode (indexed for perf)                        │
│  │  └─ ListByStatus (for plugin discovery)                     │
│  └─ WorkflowRepository                                         │
│     └─ StepProgress CRUD                                       │
│                                                                 │
│  Models:                                                       │
│  ├─ WorldTask                                                  │
│  ├─ WorkflowSession                                            │
│  └─ StepProgress                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
          ↑                    ↑                    ↓
    HTTP POST              HTTP GET            HTTP POST
    JSON payload         JSON response         JSON payload

┌─ Minecraft Plugin (Java) ──────────────────────────────────────┐
│                                                                 │
│  1. Player receives LinkCode from web                          │
│  2. Player joins server and types: /worldtask claim {code}     │
│  3. Plugin fetches task via GET /api/worldtasks/{id}           │
│  4. Router identifies handler by FieldName                     │
│  5. Handler initializes task mode                              │
│  6. Handler listens for chat commands (save, cancel, etc.)     │
│  7. Player executes task (e.g., stands at location and saves)  │
│  8. Handler validates data and calls:                          │
│     POST /api/worldtasks/{id}/complete with OutputJson        │
│  9. Player gets success/failure message                        │
│                                                                 │
│  Components:                                                   │
│  ├─ KnkAdminCommand (entry point)                              │
│  ├─ KnkTaskClaimCommand (claim logic)                          │
│  ├─ KnkTaskListCommand (show pending tasks)                    │
│  ├─ KnkTaskStatusCommand (show current task)                   │
│  ├─ WorldTaskHandlerRegistry (IWorldTaskHandler routing)       │
│  ├─ WgRegionIdTaskHandler (region capture)                     │
│  ├─ LocationTaskHandler (location capture)                     │
│  ├─ RegionTaskEventListener (Minecraft events)                 │
│  ├─ WorldTasksApiImpl (HTTP client)                             │
│  └─ KnkApiClient (base HTTP client)                            │
│                                                                 │
│  Data Flow:                                                    │
│  /worldtask claim ABC123                                       │
│    → KnkTaskClaimCommand.execute()                             │
│    → WorldTasksApiImpl.getByLinkCode("ABC123")                  │
│    → WorldTaskHandlerRegistry.startTask(player, "Location"...) │
│    → LocationTaskHandler.startTask(player, taskId, inputJson)  │
│    → Player sees: "Type 'save' to capture location"            │
│    → Player types: save                                        │
│    → LocationTaskHandler.onPlayerChat("save")                  │
│    → Gets player location (x, y, z, yaw, pitch)               │
│    → WorldTasksApiImpl.complete(taskId, outputJson)            │
│    → Player sees: "Task completed!"                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Web App Architecture

```
App.tsx
├─ TownCreateWizardPage (or other entity forms)
│  ├─ WizardStepContainer
│  │  ├─ Step 1: General Info
│  │  ├─ Step 2: Configuration
│  │  └─ Step 3: World Data
│  │     └─ WorldBoundFieldRenderer (detects world fields)
│  │        ├─ TaskStatusMonitor (polls every 3s)
│  │        │  ├─ Shows LinkCode
│  │        │  └─ Shows status: Pending → InProgress → Completed
│  │        └─ WorldTaskCta (calls to action)
│  │           └─ "Copy LinkCode" button
│  └─ Submit button (finalize workflow)
└─ FormWizardPage (for form configuration)
```

**Key Components:**

- **WizardStepContainer**: Manages step navigation, validates before advancing
- **TaskStatusMonitor**: Polls `/api/worldtasks/{id}` and calls callback on completion
- **WorldBoundFieldRenderer**: Wraps world-bound fields, creates tasks, renders monitor
- **WorldTaskCta**: Instructions and copy-to-clipboard for LinkCode

**API Clients:**

- **workflowClient**: createWorkflow, updateStep, finalize
- **worldTaskClient**: create, getByLinkCode, listByStatus, claim, complete, fail

### Web API Architecture

```
WorldTasksController
├─ GET /api/worldtasks/{id}
├─ GET /api/worldtasks/by-link-code/{linkCode}
├─ GET /api/worldtasks/status/{status}
├─ POST /api/worldtasks/{id}/claim
├─ POST /api/worldtasks/{id}/complete
└─ POST /api/worldtasks/{id}/fail

WorldTaskService
├─ Create(dto)
│  ├─ Validate fields
│  ├─ Generate LinkCode
│  └─ Persist entity
├─ Claim(id, serverId, username)
│  ├─ Fetch task
│  ├─ Validate state
│  └─ Update to InProgress
├─ Complete(id, outputJson)
│  ├─ Validate OutputJson
│  ├─ Update task to Completed
│  └─ Update StepProgress
└─ Fail(id, errorMessage)
   ├─ Update task to Failed
   └─ Store error

WorkflowService
├─ UpdateStep(workflowId, stepNumber, data)
├─ CreateTask(workflowId, stepKey, fieldName, taskType, inputJson)
└─ Finalize(workflowId)
   └─ Collect all completed task outputs
   └─ Map to entity properties
   └─ Create/update entity
```

**Data Layer:**

- WorldTaskRepository: GetByIdAsync, GetByLinkCodeAsync, ListByStatusAsync
- WorkflowRepository: StepProgress CRUD, GetBySessionAsync
- Entity Framework Core with migrations

### Plugin Architecture

```
KnKPlugin (Main Plugin Class)
├─ Initialize handlers
├─ Register commands
├─ Register listeners
└─ Inject services

Commands
├─ /worldtask claim {linkCode}
│  └─ KnkTaskClaimCommand
│     ├─ Fetch task from API
│     ├─ Call handler.startTask()
│     └─ Transition to InProgress
├─ /worldtask list
│  └─ KnkTaskListCommand
│     └─ Show pending tasks for player
└─ /worldtask status
   └─ KnkTaskStatusCommand
      └─ Show current task details

Listeners
├─ RegionTaskEventListener
│  └─ Listen for player events during tasks
└─ (PlayerChatEvent handled by handlers)

WorldTaskHandlerRegistry
├─ registerHandler(IWorldTaskHandler)
├─ startTask(player, fieldName, taskId, inputJson)
├─ isHandling(player)
└─ cancel(player)

IWorldTaskHandler (Interface)
├─ getFieldName()
├─ startTask(player, taskId, inputJson)
├─ onPlayerChat(player, message) → boolean
├─ isHandling(player)
└─ cancel(player)

Implementations
├─ LocationTaskHandler
│  ├─ startTask: Instruct player
│  ├─ onPlayerChat: Handle "save", "pause", "resume", "cancel"
│  ├─ handleSave: Capture x,y,z,yaw,pitch
│  └─ completeTask: Call API with OutputJson
└─ WgRegionIdTaskHandler
   ├─ startTask: Enable WorldEdit
   ├─ onPlayerChat: Handle "save", "select", "pause", "resume", "cancel"
   ├─ handleSave: Create region from selection
   ├─ handleSelect: Select existing region
   └─ completeTask: Call API with OutputJson
```

## Data Models & Relationships

```
┌─────────────────────────┐
│   WorkflowSession       │
│─────────────────────────│
│ Id (PK)                 │
│ UserId (FK)             │
│ EntityType              │
│ Status                  │
│ RowVersion              │
└────────────┬────────────┘
             │ 1
             │
             │ N
    ┌────────▼────────┐
    │  StepProgress   │
    ├─────────────────┤
    │ Id (PK)         │
    │ SessionId (FK)  │
    │ StepNumber      │
    │ StepKey         │
    │ Status          │
    │ CompletedAt     │
    └─────┬───────────┘
          │
          │
    ┌─────▼────────────┐
    │   WorldTask      │
    ├──────────────────┤
    │ Id (PK)          │
    │ SessionId (FK)   │
    │ StepKey          │
    │ FieldName        │
    │ TaskType         │
    │ Status           │
    │ LinkCode (UQ)    │
    │ InputJson        │
    │ OutputJson       │
    │ ErrorMessage     │
    │ ClaimedAt        │
    │ CompletedAt      │
    └──────────────────┘
```

**Relationships:**

- WorkflowSession → StepProgress (one-to-many)
- StepProgress → WorldTask (one-to-many, via StepKey/StepNumber)
- WorldTask → OutputJson contains entity property values

## State Diagrams

### Task Lifecycle

```
       ┌─────────┐
       │ Pending │
       └────┬────┘
            │ /worldtask claim {code}
            │ OR
            │ Plugin calls claim()
            ▼
       ┌──────────────┐
       │  InProgress  │◄──────────────────┐
       └────┬─────────┘                   │
            │                             │
       ┌────┴──────┬──────────┐          │
       │           │          │          │
       ▼           ▼          ▼          │
  ┌─────────┐ ┌────────┐ ┌─────────┐   │
  │Completed│ │ Failed │ │Cancelled│   │
  └─────────┘ └────────┘ └─────────┘   │
              (error)      (player)     │
                                        │
    Retry: Create new task ─────────────┘
```

### Workflow Step Lifecycle

```
 ┌──────────────────────────────────────────────────────┐
 │ All Steps Complete → Ready for Finalization          │
 └──────────────────┬─────────────────────────────────┘
                    │
                    ▼
 ┌────────────────────────────────────────────────────┐
 │ Workflow → Finalize                                │
 │ Extract task OutputJson → Map to entity props       │
 │ Create/Update entity                               │
 └────────────────────────────────────────────────────┘
```

## Synchronization Points

### Web App ↔ Web API

1. **Create Task** (POST /api/worldtasks)
   - Request: WorldTaskCreateDto with fieldName, inputJson, etc.
   - Response: WorldTaskReadDto with generated LinkCode
   - Timing: User initiates from form wizard

2. **Poll Task Status** (GET /api/worldtasks/{id})
   - Request: Task ID
   - Response: Current status, OutputJson if completed
   - Timing: Every 3 seconds while task InProgress

3. **Finalize Workflow** (POST /api/workflows/{id}/finalize)
   - Request: Workflow ID
   - Response: Created/updated entity
   - Timing: User clicks "Create" button

### Web API ↔ Plugin

1. **Claim Task** (POST /api/worldtasks/{id}/claim)
   - Request: LinkCode, ServerId, MinecraftUsername
   - Response: Task details (FieldName, InputJson for handler)
   - Timing: Plugin calls on `/worldtask claim` command

2. **Complete Task** (POST /api/worldtasks/{id}/complete)
   - Request: OutputJson with captured data
   - Response: Confirmed completion
   - Timing: Handler calls when player executes task

3. **List Pending Tasks** (GET /api/worldtasks/status/Pending)
   - Request: Query filter
   - Response: List of pending tasks
   - Timing: Plugin calls on `/worldtask list` command

## Error Handling & Recovery

```
┌─────────────────┐
│ Task Execution  │
└────────┬────────┘
         │
         ├─ Valid input
         │  └─ Proceed
         │
         └─ Invalid input
            ├─ Input validation failed
            │  └─ API returns 400 Bad Request
            │  └─ Plugin shows error in chat
            │  └─ Player can retry (new task)
            │
            └─ Plugin handler error
               ├─ Handler catches exception
               ├─ Handler calls fail(taskId, errorMsg)
               ├─ Task transitions to Failed
               └─ Player sees error in chat
               └─ Admin can retry from web UI
```

## Performance Considerations

### Polling Optimization
- TaskStatusMonitor polls every 3 seconds (configurable)
- Single endpoint call: GET /api/worldtasks/{id}
- Response includes only essential fields (no full workflow)

### Database Indexes
- LinkCode: Unique index for fast lookup (critical for plugin)
- WorkflowSessionId + Status: Index for filtering
- CreatedAt: For retention policies

### Async Operations
- Plugin uses CompletableFuture for non-blocking API calls
- Web API uses async/await throughout
- Web app async state updates with useEffect

