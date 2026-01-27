# WorldTask Implementation Checklist

## Backend (knk-web-api-v2)

### Data Model & Database

- [x] WorldTask entity with all properties (Id, WorkflowSessionId, LinkCode, Status, InputJson, OutputJson, etc.)
- [x] WorkflowSession extended with RowVersion for concurrency
- [x] Database migrations for WorldTask table
- [x] Unique constraint on LinkCode
- [x] Indexes: LinkCode (unique), WorkflowSessionId, Status, CreatedAt

### Service Layer

- [x] IWorldTaskService interface with all methods
- [x] WorldTaskService implementation:
  - [x] CreateAsync with LinkCode generation
  - [x] GetByIdAsync
  - [x] GetByLinkCodeAsync (indexed query)
  - [x] ListByStatusAsync (for plugin discovery)
  - [x] UpdateStatusAsync
  - [x] ClaimAsync (Pending → InProgress)
  - [x] CompleteAsync (InProgress → Completed, update StepProgress)
  - [x] FailAsync (InProgress → Failed)
- [x] WorkflowService enhancements:
  - [x] CreateTask method
  - [x] UpdateStep when task completes
  - [x] Finalize method (create/update entity)

### Repository Layer

- [x] IWorldTaskRepository interface
- [x] WorldTaskRepository implementation:
  - [x] GetByLinkCodeAsync
  - [x] ListByStatusAsync
- [x] WorkflowRepository extensions:
  - [x] StepProgress CRUD
  - [x] GetBySessionAsync

### DTOs

- [x] WorldTaskCreateDto
- [x] WorldTaskReadDto
- [x] WorldTaskUpdateDto
- [x] ClaimTaskDto
- [x] CompleteTaskDto
- [x] FailTaskDto
- [x] AutoMapper profiles for all DTOs

### API Controllers

- [x] WorldTasksController with endpoints:
  - [x] GET /api/worldtasks/{id}
  - [x] GET /api/worldtasks/by-link-code/{linkCode}
  - [x] GET /api/worldtasks/status/{status}
  - [x] POST /api/worldtasks/{id}/claim
  - [x] POST /api/worldtasks/{id}/complete
  - [x] POST /api/worldtasks/{id}/fail
- [x] WorkflowsController extensions:
  - [x] PUT /api/workflows/{id}/steps/{stepNumber}
  - [x] POST /api/workflows/{id}/finalize

### Validation & Error Handling

- [x] Input validation in CreateAsync
- [x] State transition validation in Claim/Complete/Fail
- [x] LinkCode collision detection
- [x] OutputJson format validation
- [x] Concurrency error handling

---

## Frontend (knk-web-app)

### Type Definitions

- [x] WorkflowState enum (InProgress, Paused, Completed, Abandoned, Cancelled)
- [x] TaskStatus enum (Pending, InProgress, Completed, Failed, Cancelled)
- [x] StepStatus enum (Pending, InProgress, Completed)
- [x] WorldTaskDto type
- [x] StepDefinition interface
- [x] WorkflowContext interface
- [x] ClaimTaskDto type
- [x] CompleteTaskDto type
- [x] FailTaskDto type

### API Clients

- [x] worldTaskClient:
  - [x] create(dto): Promise<WorldTaskReadDto>
  - [x] getById(id): Promise<WorldTaskReadDto>
  - [x] getByLinkCode(linkCode): Promise<WorldTaskReadDto>
  - [x] listByStatus(status): Promise<WorldTaskReadDto[]>
  - [x] claim(id, dto): Promise<WorldTaskReadDto>
  - [x] complete(id, dto): Promise<WorldTaskReadDto>
  - [x] fail(id, dto): Promise<WorldTaskReadDto>
- [x] workflowClient:
  - [x] updateStep(workflowId, stepNumber, data): Promise<any>
  - [x] finalize(workflowId): Promise<EntityDto>

### Components

- [x] TaskStatusMonitor:
  - [x] Poll task status every 3 seconds
  - [x] Display status (Pending, InProgress, Completed, Failed)
  - [x] Visual feedback (spinner, checkmark, error icon)
  - [x] Callback on completion
  - [x] Error display

- [x] WizardStepContainer:
  - [x] Step navigation (prev, next)
  - [x] Step validation gating
  - [x] Progress indicator
  - [x] Support for multiple step types

- [x] WorldBoundFieldRenderer:
  - [x] Detect world-bound fields
  - [x] Create WorldTask for field
  - [x] Embed TaskStatusMonitor
  - [x] Display LinkCode
  - [x] Show Minecraft instructions

- [x] WorldTaskCta:
  - [x] Display LinkCode clearly
  - [x] Copy-to-clipboard button
  - [x] Minecraft instructions
  - [x] Expected data type

### Pages

- [x] TownCreateWizardPage:
  - [x] Step 1: General Info (name, description)
  - [x] Step 2: Rules (allowEntry, allowExit)
  - [x] Step 3: World Data (Region & Location via tasks)
  - [x] Form validation per step
  - [x] Error handling and retry

- [x] Route: /towns/create

### Utilities

- [x] Task status helpers
- [x] LinkCode formatting
- [x] Polling interval management

---

## Minecraft Plugin (knk-plugin-v2)

### Core API Integration

- [x] WorldTasksApi interface (async with CompletableFuture)
- [x] WorldTasksApiImpl HTTP client implementation
- [x] KnkApiClient integration
- [x] DTOs:
  - [x] WorldTaskDto
  - [x] ClaimTaskDto
  - [x] CompleteTaskDto
  - [x] FailTaskDto

### Task Handler Infrastructure

- [x] IWorldTaskHandler interface
- [x] WorldTaskHandlerRegistry:
  - [x] registerHandler(IWorldTaskHandler)
  - [x] getHandler(fieldName)
  - [x] startTask(player, fieldName, taskId, inputJson)
  - [x] cancelAllTasks(player)
  - [x] isHandlingAnyTask(player)
  - [x] getActiveHandler(player)

### Task Handlers

- [x] WgRegionIdTaskHandler:
  - [x] Support region creation via WorldEdit selection
  - [x] Support region selection by name
  - [x] Parent region validation
  - [x] Region priority and flags
  - [x] Temporary region tracking and cleanup
  - [x] Region renaming (temp → final)
  - [x] Chat commands: save, select, cancel, pause, resume

- [x] LocationTaskHandler (NEW):
  - [x] Capture player location (x, y, z)
  - [x] Capture player rotation (yaw, pitch)
  - [x] World name tracking
  - [x] Chat commands: save, cancel, pause, resume
  - [x] Task completion via API

### Commands

- [x] /worldtask claim {linkCode}
  - [x] Fetch task by LinkCode
  - [x] Claim task
  - [x] Route to appropriate handler
  - [x] Start task mode

- [x] /worldtask list
  - [x] List pending tasks
  - [x] Show LinkCode and field type
  - [x] Filter by optional player/server

- [x] /worldtask status
  - [x] Show current task status
  - [x] Show elapsed time
  - [x] Show field data if available

### Event Listeners

- [x] RegionTaskEventListener:
  - [x] Listen for player events during tasks
  - [x] Cleanup on PlayerQuitEvent
  - [x] Chat event routing to handlers

### Plugin Integration

- [x] KnKPlugin main class:
  - [x] Initialize WorldTaskHandlerRegistry
  - [x] Register all handlers
  - [x] Register commands
  - [x] Register listeners
  - [x] Inject WorldTasksApi

- [x] Logging throughout plugin code
- [x] Error handling and player feedback

### Temporary Resource Management

- [x] TempRegionRetentionTask (if needed for cleanup)
- [x] Cleanup on task cancellation
- [x] Cleanup on task failure
- [x] Region renaming on task success

---

## Cross-System Integration

### Web App → API → Plugin Flow

- [x] Admin creates entity form in web app
- [x] Wizard detects world-bound fields
- [x] Creates WorldTask via API
- [x] Displays LinkCode to admin
- [x] Polls task status every 3 seconds
- [x] Detects completion and updates form
- [x] Finalizes workflow and creates entity

### Plugin → API → Web App Flow

- [x] Player claims task via /worldtask claim
- [x] Plugin fetches task from API
- [x] Routes to appropriate handler
- [x] Player executes handler commands
- [x] Handler captures data
- [x] Handler calls complete() API
- [x] API updates task and StepProgress
- [x] Web app polls and detects completion

### Data Consistency

- [x] LinkCode uniqueness enforced
- [x] Task state machine validation
- [x] Concurrency safety via RowVersion
- [x] OutputJson persisted atomically
- [x] StepProgress updated idempotently

---

## Documentation

- [x] README.md (Overview and quick start)
- [x] SPEC_WORLDTASK.md (Technical specification)
- [x] REQUIREMENTS_WORLDTASK.md (Functional and technical requirements)
- [x] ARCHITECTURE.md (System design and data flow)
- [x] HANDLER_DEVELOPMENT_GUIDE.md (How to create handlers)
- [x] API_CONTRACT.md (Complete API reference)
- [x] IMPLEMENTATION_CHECKLIST.md (This file)

---

## Testing

### Unit Tests

- [ ] WorldTaskService creation tests
- [ ] WorldTaskService state transition tests
- [ ] LinkCode generation tests
- [ ] Handler registry tests
- [ ] LocationTaskHandler tests
- [ ] WgRegionIdTaskHandler tests

### Integration Tests

- [ ] Full workflow: create task → claim → complete
- [ ] Failure scenario: task creation → fail
- [ ] Concurrency: multiple players claiming tasks
- [ ] API endpoint tests with various payloads
- [ ] WorldTask-to-StepProgress linking

### Manual/QA Tests

- [ ] Create Town with Location and Region tasks
- [ ] Admin gets LinkCode and shares with player
- [ ] Player claims task and executes commands
- [ ] Task completes and form updates
- [ ] Entity is created with correct data
- [ ] Error scenarios and recovery
- [ ] Multi-step workflow completion

---

## Known Limitations & TODOs

### Phase 1 (Complete)
- [x] Basic WorldTask CRUD
- [x] Claim/Complete/Fail transitions
- [x] LocationTaskHandler
- [x] WgRegionIdTaskHandler
- [x] Basic validation

### Phase 2 (Planned)
- [ ] Advanced input validation
- [ ] Task retry logic with backoff
- [ ] Task timeouts and auto-cleanup
- [ ] Task permissions and access control
- [ ] Batch task operations
- [ ] Task history and audit trail

### Phase 3 (Future)
- [ ] Task templates
- [ ] Conditional task execution
- [ ] WebSocket real-time updates
- [ ] Mobile-friendly monitoring
- [ ] Task scheduling

### Technical Debt
- [ ] Cache invalidation for task lists
- [ ] Connection pooling in plugin API client
- [ ] Metrics and monitoring for task lifecycle
- [ ] Load testing for concurrent claims

---

## Deployment Checklist

### Pre-Deployment

- [ ] All code reviewed and merged
- [ ] Unit tests passing (90%+ coverage)
- [ ] Integration tests passing
- [ ] API contract validation
- [ ] Database migrations tested on staging
- [ ] Performance benchmarks acceptable

### Deployment

- [ ] Database migration applied
- [ ] API service deployed
- [ ] Web app deployed
- [ ] Plugin JAR built and deployed
- [ ] Configuration updated (API endpoints, etc.)
- [ ] Smoke tests passed

### Post-Deployment

- [ ] Monitor API logs for errors
- [ ] Monitor plugin logs for connection issues
- [ ] Test full end-to-end flow
- [ ] Verify task LinkCode generation
- [ ] Verify task status polling works
- [ ] Check database query performance

---

## Rollback Plan

- [ ] Revert database migration if critical issue
- [ ] Rollback API to previous version
- [ ] Rollback web app to previous version
- [ ] Rollback plugin JAR
- [ ] Test rollback flow end-to-end

