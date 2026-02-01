# WorldTask Requirements

## Functional Requirements

### FR-1: Task Lifecycle Management

**FR-1.1:** System shall create WorldTask records linked to workflow steps
- Each task must have a unique LinkCode (6-char alphanumeric)
- Task must specify FieldName to identify which form field it populates
- Task must reference WorkflowSessionId for workflow context
- Task must initialize in "Pending" state

**FR-1.2:** System shall support task claiming by Minecraft players
- Player claims task via `/worldtask claim {linkCode}` command
- Claiming transitions task from Pending → InProgress
- Claiming records player username, server ID, and timestamp
- Claiming is idempotent: same player re-claiming updates timestamp only

**FR-1.3:** System shall support task execution and completion
- Handler-specific logic executes in Minecraft client (plugin-side)
- Player provides data through chat commands (e.g., `save`, `cancel`, `pause`, `resume`)
- Handler validates captured data against input constraints
- Upon success, task transitions from InProgress → Completed
- Handler sends OutputJson to Web API with captured data

**FR-1.4:** System shall support task failure and error handling
- If task execution fails, task transitions to Failed status
- ErrorMessage field captures reason for failure
- Player receives in-game feedback explaining the error
- Failed tasks can be retried (new task creation)

**FR-1.5:** System shall allow task cancellation
- Player can cancel active task via `cancel` command
- Cancelled tasks do not complete workflow steps
- Temporary resources (e.g., temp regions) are cleaned up

### FR-2: Workflow Step Integration

**FR-2.1:** WorldTask completion shall update workflow step progress
- When task status changes to Completed:
  - Corresponding StepProgress record is marked as Completed
  - OutputJson is stored for workflow processing
  - CompletedAt timestamp is recorded

**FR-2.2:** Workflow shall track completion of all required steps
- Workflow can proceed to next step only if current step is completed
- Form wizard UI reflects step completion status
- Workflow can be finalized only when all steps are completed

**FR-2.3:** Task output data shall be available to workflow for entity creation
- Workflow service retrieves OutputJson from completed tasks
- Data is extracted and mapped to entity properties
- Mapping follows field-specific rules (e.g., Location → LocationX, LocationY, LocationZ)

### FR-3: Minecraft Plugin Integration

**FR-3.1:** Plugin shall support multiple task handlers
- System shall have a handler registry for routing tasks by FieldName
- Each handler implements IWorldTaskHandler interface
- Handlers are registered during plugin initialization
- System supports extending handlers without modifying core code

**FR-3.2:** Plugin shall support Location task handler
- LocationTaskHandler captures player's current position and rotation
- Captures X, Y, Z coordinates with floating-point precision
- Captures yaw and pitch (rotation angles)
- Captures world name for multi-world support
- Player executes via `save` command in chat

**FR-3.3:** Plugin shall support WgRegionId task handler
- WgRegionIdTaskHandler allows two modes:
  - Mode 1: Create new region from WorldEdit selection
  - Mode 2: Select existing WorldGuard region by name
- Supports parent region validation (child must be inside parent)
- Supports region priority configuration
- Supports region flag preservation
- Player executes via `save` command for creation or `select {regionname}` for selection

**FR-3.4:** Plugin shall manage temporary resources
- Temporary regions created during task execution are tracked
- Regions are cleaned up on task cancellation
- Regions are renamed to permanent names on entity creation
- Cleanup handles cascade deletions properly

**FR-3.5:** Plugin shall provide task management commands
- `/worldtask claim {linkCode}` - Claim a pending task
- `/worldtask list` - List available pending tasks
- `/worldtask status` - Show current task status
- All commands provide feedback to player in chat

### FR-4: Web API Services

**FR-4.1:** WorldTaskService shall manage task lifecycle
- CreateAsync: Create task with validation (FieldName, StepKey, WorkflowSessionId required)
- GetByIdAsync: Retrieve task by ID
- GetByLinkCodeAsync: Retrieve task by LinkCode (for plugin claiming)
- ListByStatusAsync: List tasks by status (for plugin discovery)
- UpdateStatusAsync: Transition task between states
- ClaimAsync: Handle claim operation
- CompleteAsync: Handle completion with OutputJson
- FailAsync: Handle failure with ErrorMessage

**FR-4.2:** API shall expose WorldTask endpoints
- GET /api/worldtasks/{id} - Get task details
- GET /api/worldtasks/by-link-code/{linkCode} - Get task by LinkCode (plugin endpoint)
- GET /api/worldtasks/status/{status} - List tasks by status (plugin endpoint)
- POST /api/worldtasks/{id}/claim - Claim task (plugin endpoint)
- POST /api/worldtasks/{id}/complete - Complete task (plugin endpoint)
- POST /api/worldtasks/{id}/fail - Fail task (plugin endpoint)

**FR-4.3:** WorkflowService shall coordinate task completion
- When task completes, update corresponding StepProgress
- When all steps complete, finalize workflow
- Extract and map task OutputJson to entity properties
- Create/update entity based on accumulated step data

### FR-5: Web App UI Integration

**FR-5.1:** Wizard shall embed world-bound fields
- Form wizard identifies fields marked as "requires minecraft"
- When reaching world-bound step, create WorldTask and display task interface
- Display LinkCode to user for Minecraft player to use

**FR-5.2:** UI shall monitor task progress
- TaskStatusMonitor component polls task status every 3 seconds
- Display task status: Pending, InProgress, Completed, Failed
- Show visual feedback: spinner for InProgress, checkmark for Completed, error for Failed
- Update form data when task completes

**FR-5.3:** UI shall handle task failures gracefully
- Display error message from task
- Allow retry: Create new task with same field
- Prevent form progression while task is in error state

**FR-5.4:** UI shall display task LinkCode clearly
- Show LinkCode in easy-to-read format
- Allow copy-to-clipboard functionality
- Display instructions for Minecraft player
- Show world name and expected data type

## Technical Requirements

### TR-1: Data Integrity

**TR-1.1:** LinkCode Uniqueness
- Each LinkCode must be globally unique
- Database constraint enforces uniqueness
- Generation includes collision detection

**TR-1.2:** Concurrency Safety
- Task state transitions are atomic
- Row version prevents stale updates
- Claim operation is idempotent

**TR-1.3:** Data Consistency
- OutputJson format must match field-specific schema
- Input validation occurs before state transition
- Task data is immutable after completion

### TR-2: Performance

**TR-2.1:** Response Times
- Create task: < 100ms
- Get task by LinkCode: < 50ms (plugin endpoint, critical path)
- Claim task: < 200ms
- Complete task: < 500ms (includes step update)

**TR-2.2:** Polling Efficiency
- Web app polls at 3-second intervals
- Endpoints are optimized for fast retrieval
- No full workflow loads on status polling

**TR-2.3:** Plugin Communication
- Async/await pattern for non-blocking operations
- Connection timeouts: 5 seconds
- Retry logic for transient failures

### TR-3: Security

**TR-3.1:** LinkCode Security
- LinkCodes are non-sequential and non-guessable
- LinkCodes are not exposed in logs
- LinkCodes can only be used once (after claiming)

**TR-3.2:** Access Control
- Only assigned users can view their workflow tasks
- Plugin server identity is verified (ServerId)
- Task data is accessible only to owners and admins

**TR-3.3:** Input Validation
- All InputJson and OutputJson parsed as valid JSON
- FieldName values restricted to known handlers
- TaskType values validated against registry

### TR-4: Extensibility

**TR-4.1:** Handler Plugin Architecture
- New handlers implement IWorldTaskHandler interface
- Handlers registered via registry pattern
- No modification to core code required for new handlers

**TR-4.2:** FieldName Registry
- Supported FieldNames: Location, WgRegionId, (extensible)
- Each FieldName maps to one handler
- New FieldNames added via registration

**TR-4.3:** Task Type Flexibility
- TaskType is free-form string for future extension
- Current types: "CaptureLocation", "DefineRegion"
- New types can be added without schema changes

### TR-5: Error Handling & Logging

**TR-5.1:** Error Messages
- All errors logged with context: taskId, playerId, stacktrace
- Error messages returned to player in-game
- API errors include correlation IDs for debugging

**TR-5.2:** Logging
- Creation, claim, completion, and failure are logged
- Logs include timestamps and responsible user/server
- LinkCode generation collisions logged as warnings

**TR-5.3:** Recovery
- Transient failures trigger retries
- Failed tasks can be recreated
- Cleanup operations are resilient

## Non-Functional Requirements

### NFR-1: Reliability
- Task data is durable (persisted immediately)
- No loss of completed task data
- Temporary resources are cleaned up reliably

### NFR-2: Scalability
- System supports thousands of concurrent tasks
- Plugin can handle multiple players claiming tasks simultaneously
- Web API can handle high polling rates from multiple clients

### NFR-3: Maintainability
- Handler code is modular and testable
- Clear interfaces between plugin and API
- DTOs provide version stability

### NFR-4: Usability
- In-game instructions are clear and actionable
- Web UI provides visual feedback on task status
- Error messages guide player to resolution

## Implementation Priorities

### Phase 1 (Complete)
- [x] WorldTask data model and migrations
- [x] Basic CRUD operations (create, get, list)
- [x] Claim/Complete/Fail state transitions
- [x] LinkCode generation
- [x] WgRegionIdTaskHandler
- [x] LocationTaskHandler
- [x] Plugin commands and listeners
- [x] Web API endpoints
- [x] Basic wizard UI integration

### Phase 2 (In Progress/Planned)
- [ ] Advanced input validation (parent region checking, etc.)
- [ ] Task retry logic with exponential backoff
- [ ] Task timeouts and automatic cleanup
- [ ] Task permissions and access control enhancements
- [ ] Batch task operations (create multiple for entity)
- [ ] Task history and audit trail

### Phase 3 (Future)
- [ ] Task templates for common patterns
- [ ] Conditional task execution based on entity type
- [ ] Advanced region creation (custom shapes, flags)
- [ ] Location picker UI enhancements
- [ ] Mobile-friendly task monitoring
- [ ] WebSocket-based real-time updates (instead of polling)

