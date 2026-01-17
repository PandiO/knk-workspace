## 0. How to Use This Document

**Two independent workstreams are defined:**

1. **Workstream A: Hybrid Create/Edit Workflow (Phase 1 - Sections 14-20)**
   - Multi-step form progression with world-bound tasks
   - No validation framework needed
   - Can be implemented independently
   - Acceptance: Admin creates Town → completes world tasks → entity finalizes

2. **Workstream B: Conditional Validation Framework (Phase 2 - Section 23)**
   - Cross-field validation rules
   - Depends on FormField (already exists)
   - Can be implemented in parallel or after Phase 1
   - Acceptance: Admin configures validation rule → validation executes on field change

**For implementation:**
- See [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) for detailed Sprint plan and instruction examples
- Each workstream can be assigned to separate teams
- Sections marked "🔄 Workstream A" or "🔄 Workstream B" show dependencies

---

# Knights & Kings — Requirements: Hybrid Create/Edit Flow (Web App ⇄ Minecraft ⇄ Web API)

**Document ID:** KKNK-REQ-HYBRID-FLOW  
**Status:** Draft (living document)  
**Scope:** Hybrid create/edit workflow for KnK entities where *business/data* is handled via Web App + Web API and *Minecraft-world dependent* data is captured/validated inside the Minecraft plugin and persisted through the Web API.

---

## 1. Context and Problem Statement

Historically, the legacy Knights & Kings Minecraft plugin handled full entity creation (e.g., Town, District, Street, Structure, Regions) directly inside Minecraft, including persistence via Hibernate/MySQL.

In the new ecosystem, **the Web API is the system of record** and **the Web App is the primary admin UI**. However, certain entity properties can only be determined inside Minecraft (e.g., WorldGuard region identifiers, world locations, selections). Therefore, entity creation/editing must be a **hybrid** workflow spanning:

- **Web App**: primary data entry, orchestration, admin UX
- **Web API**: persistence, validation, workflow state, audit/diagnostics, task coordination
- **Minecraft Plugin**: world-bound actions (WorldGuard/WorldEdit/location capture), in-game guidance, returning results to the API

---

## 2. Goals

1. **Hybrid Create & Edit**: Support creating and editing KnK entities where some steps require Minecraft-world interaction.
2. **API-First Persistence**: Web API remains the authoritative store for entities and workflow state.
3. **Non-Blocking Gameplay**: Plugin must never perform blocking I/O on the main thread; all API calls are async.
4. **Administrator UX**: Admins can complete entity workflows by switching between Web App and Minecraft using a guided, resumable process.
5. **Draft/Resumable**: Partial progress is persisted; a failure does not force redoing complex Minecraft selections/regions.
6. **Auditability & Diagnostics**: API and Web App provide visibility into in-progress steps, task assignment, failures, and results.

---

## 3. Non-Goals (for initial implementation)

- Player-facing Web App flows (future scope).
- Fully automated world edits beyond the specific step being requested (e.g., mass region generation).
- Real-time collaborative editing between multiple admins (can be added later).
- Full state reconciliation if external plugins manually change WorldGuard regions (only detect/report in v1).

---

## 4. Actors and Roles

- **Admin (Web App user)**: Initiates and completes create/edit workflows.
- **Minecraft Admin (in-game)**: Same identity as Admin, authenticated/linked to Web App account (see Identity section).
- **Web API**: Orchestrates workflow, validates inputs, persists entities and tasks.
- **Minecraft Plugin Client**: Performs world-bound steps; can be one or multiple Minecraft servers/instances.
- **Web App (Admin UI)**: Wizard-style UX, showing steps and status.

---

## 5. Key Concepts

### 5.1 Hybrid Workflow Session (Wizard)
A create/edit flow is modeled as a **multi-step workflow**. Steps can be:

- **Web-only step**: field entry/validation; no Minecraft dependency.
- **World-bound step**: requires Minecraft plugin involvement and produces/validates Minecraft-specific outputs.

### 5.2 Draft Entity / Pending State
During create (and sometimes edit), the entity exists in a **draft/pending** state in the API until required world-bound steps are completed.

### 5.3 World Task (World-bound Work Item)
A world-bound step is represented by a **task** assigned to (or claimable by) a Minecraft plugin client. Examples:
- Create or link a WorldGuard region
- Capture a location (spawn/center/etc.)
- Validate region shape/constraints

Tasks must be trackable, retryable, and fail-safe.

### 5.4 Identity Linking (Admin ⇄ Minecraft)
The system must support mapping a Web App admin to an in-game identity to allow "continue your flow in Minecraft". A coupling mechanism may be:
- short-lived **link code**
- logged-in session token (if plugin can authenticate)
- explicit "claim task" by in-game user

**Requirement:** The design must allow secure association without exposing secrets in chat/logs.

---

## 6. Workflow States

### 6.1 Entity lifecycle states (example)
- `Draft` / `PendingWorldBinding` — entity created but missing world-bound data
- `Active` — fully created and usable
- `EditPending` — edit started but missing required world-bound updates
- `Archived/Deleted` — if applicable

### 6.2 Task lifecycle states
- `Pending` — created by API, awaiting claim
- `InProgress` — claimed by a plugin client (optionally with a lease/timeout)
- `Completed` — result submitted and accepted
- `Failed` — result could not be produced (error captured, can be retried)
- `Cancelled` — workflow aborted

---

## 7. Functional Requirements

### 7.1 Web App Requirements (Admin Wizard)

**WA-01 — Wizard-based create/edit**
- Provide step-by-step create/edit for supported entities (Town first; others later).
- Persist step progress via API; refresh-safe and resumable.

**WA-02 — World-bound step UX**
- For world-bound steps, present clear instructions:
  - what to do in Minecraft
  - how to use link code / how to claim task
  - current status (Pending/InProgress/Completed/Failed)
- Show task output once completed (e.g., region name/id, location coordinates).

**WA-03 — Choose existing vs create new**
- For fields like a WorldGuard/WorldCard region:
  - Option A: select existing region (from API list)
  - Option B: create new region via Minecraft step
- Similar pattern for world locations.

**WA-04 — Retry & recovery**
- If a world-bound step fails, allow retry without losing already-completed steps.
- Display meaningful failure reasons and suggested actions.

**WA-05 — Admin diagnostics**
- Provide a “workflow status” panel:
  - entity state
  - tasks list
  - claimed by which server/client and when
  - error messages and history

### 7.2 Web API Requirements (Orchestration & Source of Truth)

**API-01 — Draft create**
- Support creating a draft entity with business fields.
- Persist immediately; return entity id and workflow state.

**API-02 — World task creation**
- For each world-bound step, create an associated task:
  - correlated to entity id and step id
  - includes required input parameters (e.g., desired region type)
  - supports claim/complete/fail

**API-03 — Validation**
- Perform all cross-client business validation in the API:
  - unique names (where applicable)
  - referential integrity
  - permission checks
  - invariant constraints that do not require Minecraft world inspection

**API-04 — Finalization**
- Once all required tasks complete, allow finalization:
  - update entity with world-bound outputs (e.g., `WgRegionId`, `LocationId` or contract-accurate equivalents)
  - transition entity state to `Active`

**API-05 — Edit workflow**
- Support edit workflows similarly:
  - start edit session
  - update business fields
  - create tasks for world-bound changes when needed
  - finalize edit to apply changes atomically

**API-06 — Idempotency**
- Task completion endpoints must be idempotent:
  - duplicate submissions should not corrupt state
  - allow safe retry from plugin after transient errors

**API-07 — Concurrency control**
- Prevent conflicting edits:
  - optimistic concurrency (ETag/row version) or workflow-level locking.
- One active create/edit workflow per entity (configurable).

**API-08 — Audit trail**
- Record:
  - who initiated create/edit
  - step transitions
  - task lifecycle events
  - world-bound outputs and approvals

**API-09 — Contract-first**
- Swagger/OpenAPI is the primary contract for clients.
- Any new fields and endpoints must be reflected in swagger and used by plugin/web app generation.

### 7.3 Minecraft Plugin Requirements (World-bound Execution)

**PL-01 — Task intake**
- Plugin can list/claim tasks relevant to it.
- The plugin identifies itself to API as a distinct client (server id/instance id).

**PL-02 — Guided in-game flows**
- For a claimed task, the plugin guides the admin:
  - prompts and confirmations
  - providing tools (e.g., WorldEdit wand) if appropriate
  - validations (selection present, shape type, constraints)

**PL-03 — WorldGuard/WorldCard region creation/linking**
- For tasks requiring regions:
  - create region based on selection
  - or validate/link an existing region
- Return a stable identifier to API (e.g., region id/name/UUID depending on strategy).

**PL-04 — Location capture**
- For tasks requiring locations:
  - capture player position or selection-derived point
- Return a stable identifier (`LocationId`) and/or details as required by the API contract.

**PL-05 — Async networking**
- All API calls async (CompletableFuture + executor).
- Any Bukkit/Paper world changes are performed on the main thread.

**PL-06 — Resume and retry**
- If plugin crashes/restarts, tasks can be re-listed and resumed/failed gracefully.
- Re-claim behavior should be safe under leases/timeouts.

**PL-07 — Commands (minimum)**
- `/knk tasks list`
- `/knk task claim <id>` (optional if automatic claim exists)
- `/knk task status <id>`
- `/knk health` (already present)

---

## 8. Data Requirements (example: Town)

> Field names below are examples and must match the current swagger contract in implementation.

**Business fields (Web App/API)**
- Name, Description
- Ownership / role assignments (admin-defined)
- Relations (districts/structures, etc.)

**World-bound fields (Plugin-produced)**
- `WgRegionId` (WorldGuard/WorldCard region reference)
- `LocationId` and/or Location payload (world + x/y/z + yaw/pitch, depending on API design)

---

## 9. Security Requirements

**SEC-01 — Auth & authorization**
- Web App uses admin auth.
- Plugin uses service auth (API key / bearer).
- Task claim/complete must enforce authorization and proper correlation to admin identity (as designed).

**SEC-02 — Secret handling**
- Never log auth tokens or API keys in plugin logs.
- Link codes must be short-lived and single-use (recommended).

**SEC-03 — Least privilege**
- Plugin credentials should be scoped to world-task operations and required reads.

---

## 10. Reliability & Error Handling

**REL-01 — Fail-safe partial progress**
- Completed steps remain saved if later steps fail.

**REL-02 — Clear failure modes**
- Task failure records: reason + actionable message.
- Web App shows failure and allows retry.

**REL-03 — Timeouts and retries**
- API client applies reasonable timeouts and limited retries for idempotent calls.
- Task lease expiration should allow re-claim.

---

## 11. Observability

**OBS-01 — Workflow visibility**
- Web App can show live-ish status (polling is acceptable initially).

**OBS-02 — Structured logging**
- API logs include correlation ids (entity id, task id).
- Plugin logs include task id and endpoint.

**OBS-03 — Metrics (optional v1)**
- Count tasks by status, avg completion time, failure rate.

---

## 12. UX Requirements (Admin)

- The Web App wizard must clearly indicate when Minecraft input is required.
- Provide a “copy code” button and simple in-game instruction text.
- Provide a “Verify completion” / refresh action that polls status.
- Avoid forcing admins to reselect regions if steps later fail.

---

## 13. Testing & Acceptance Criteria

### 13.1 Minimum acceptance (v1 for Town)
- Web App can start Town create with business fields -> API stores Draft/Pending state.
- Web App can trigger a world-bound step and show a link code / instruction.
- Plugin can claim the relevant task and complete it by producing `WgRegionId` and `LocationId` (or contract-accurate equivalents).
- API finalizes Town -> state Active.
- Web App reflects final state; audit trail shows step/task history.
- No blocking I/O on Paper main thread.

### 13.2 Regression checks
- Restart plugin mid-task -> task remains recoverable.
- Duplicate completion request -> idempotent behavior.
- Unauthorized claim/complete -> rejected and logged.

---

---

## 14. FormConfig Architecture Snapshot

🔄 **Workstream A:** Hybrid workflow uses existing FormConfig infrastructure

### Current Implementation (as discovered in codebase)

**Core Components:**

1. **Entity Metadata System** ([Repository/knk-web-api-v2/Attributes](Repository/knk-web-api-v2/Attributes))
   - `[FormConfigurableEntity(string entityName)]` - marks entities as form-capable
   - `[RelatedEntityField(Type relatedType)]` - marks navigation/FK properties
   - `[NavigationPair(string navigationPropertyName)]` - pairs FK int with navigation object
   - These attributes drive reflection-based form generation

2. **Generic UI Components** ([Repository/knk-web-app/src/components](Repository/knk-web-app/src/components))
   - `GenericEntityForm` - renders create/edit forms from metadata
   - `GenericEntityList` - renders entity tables
   - `GenericEntityDetail` - renders detail views
   - Uses type introspection + API-provided schema to build UI

3. **API Contract Pattern**
   - DTOs: `{Entity}ReadDto`, `{Entity}CreateDto`, `{Entity}UpdateDto`
   - Navigation DTOs: `{RelatedEntity}NavDto` (prevents circular refs)
   - Controllers: standard CRUD endpoints with consistent routing
   - AutoMapper profiles for all mappings

4. **Current Limitations (for hybrid workflows):**
   - ❌ No explicit "Step" or "Wizard" entity/model
   - ❌ No workflow state tracking (Draft/Pending/Active)
   - ❌ No task/world-bound step concept
   - ❌ No field-level "requires Minecraft" metadata
   - ❌ No progress persistence across multi-step flows

**Extension Points:**

- **New Attributes**: Can add `[WorldBoundField]`, `[RequiresMinecraftTask]`, `[WorkflowStep(int order)]`
- **New DTOs**: `WorkflowSessionDto`, `WorldTaskDto`, `StepProgressDto`
- **New Entities**: `WorkflowSession`, `WorldTask`, `StepDefinition`, `TaskResult`
- **UI Components**: `WizardStepContainer`, `WorldBoundFieldRenderer`, `TaskStatusMonitor`

---

## 15. Hybrid Flow → FormConfig Mapping

| Hybrid Flow Concept | FormConfig Implementation | Notes |
|---------------------|---------------------------|-------|
| **Hybrid Workflow Session** | New: `WorkflowSession` entity + `WorkflowSessionDto` | Tracks multi-step create/edit; references target entity (polymorphic or by entity type name) |
| **Workflow Steps** | New: `StepDefinition` entity (or JSON config in `WorkflowSession`) | Order, name, field list, validation rules, completion criteria |
| **Web-only Step** | Uses existing `GenericEntityForm` with subset of fields | No Minecraft dependency; standard validation |
| **World-bound Step** | New field attribute: `[WorldBoundField(TaskType)]` + `WorldTask` entity | Field renders with "Start Task" button; polls task status; binds result to entity field |
| **Step Status (Pending/InProgress/Completed/Failed)** | `StepProgress` tracked in `WorkflowSession.StepsJson` or separate `StepProgress` entity | Persisted per step; drives UI "continue/retry" logic |
| **World Task** | New: `WorldTask` entity (Id, WorkflowSessionId, StepId, FieldName, Status, Input, Output, Error) | Created by API when step requires Minecraft; claimed/completed by plugin |
| **Choose existing vs create new (WA-03)** | Field metadata extension: `allowExisting: bool, allowCreate: bool` | UI renders dropdown (existing) + "Create New" button (starts task) |
| **Link Code / Claim** | `WorldTask.LinkCode` (short-lived GUID or 6-digit code) + claim endpoint | Web app shows code; plugin `/knk task claim <code>` or auto-poll by server ID |
| **Task Output → Entity Field** | `WorldTask.OutputJson` → deserialized and mapped to target field (e.g., `WgRegionId`, `LocationId`) | AutoMapper or manual mapping in finalize logic |
| **Audit/Diagnostics (WA-05)** | New UI component: `WorkflowStatusPanel` (lists tasks, shows history, errors) | Queries `WorkflowSession` + `WorldTask[]` via API |
| **Finalization** | `POST /api/workflows/{id}/finalize` → validates all steps complete → creates/updates entity → sets state Active | Idempotent; returns final entity DTO |

---

## 16. Town v1 FormConfig Template (Steps/Fields/Metadata)

### Step 1: General Information (Web-only)

**Fields:**
```csharp
[WorkflowStep(order: 1, name: "General Information")]
public class TownCreateDto_Step1
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;

    [RelatedEntityField(typeof(User))]
    public int? OwnerUserId { get; set; } // nullable until assigned
}
```

**Validation:**
- Name: unique across Towns (API validates)
- OwnerUserId: must exist (FK validation)

**Definition of Done:** Fields pass validation; saved as Draft Town entity.

---

### Step 2: Town Rules (Web-only)

**Fields:**
```csharp
[WorkflowStep(order: 2, name: "Town Rules")]
public class TownCreateDto_Step2
{
    public bool AllowEntry { get; set; } = true;
    public bool AllowExit { get; set; } = true;
    public bool PvpEnabled { get; set; } = false;
    public bool MobSpawningEnabled { get; set; } = false;
    // ...additional flags from Town entity
}
```

**Validation:** None (defaults acceptable).

**Definition of Done:** Values persisted to Draft Town.

---

### Step 3: World Data (World-bound)

**Fields:**
```csharp
[WorkflowStep(order: 3, name: "World Data", requiresMinecraft: true)]
public class TownCreateDto_Step3
{
    [WorldBoundField(TaskType = "CaptureLocation", fieldLabel: "Spawn Location")]
    public int? SpawnLocationId { get; set; }

    [WorldBoundField(TaskType = "DefineRegion", fieldLabel: "Town Region (WorldGuard/WorldCard)")]
    public string? WgRegionId { get; set; } // or int if we store WG regions in DB
}
```

**Metadata per field:**

| Field | Task Type | Input (to plugin) | Output (from plugin) | Validation (plugin-side) |
|-------|-----------|-------------------|---------------------|--------------------------|
| `SpawnLocationId` | `CaptureLocation` | `{ requiredWorld: "world", locationType: "spawn" }` | `{ locationId: 123, world: "world", x, y, z, yaw, pitch }` | Location must be within Town region (if region defined first) OR defer to post-finalize check |
| `WgRegionId` | `DefineRegion` | `{ regionType: "cuboid", allowExisting: true, allowCreate: true, parentRegionId: null }` | `{ wgRegionId: "town_example_123", bounds: {...} }` | Must be valid cuboid/polygon; if parentRegion configured (see REG-01..06), must be fully contained |

**UI Flow:**
1. For each world-bound field:
   - If `allowExisting`: show dropdown of existing regions/locations from API
   - If `allowCreate`: show "Create in Minecraft" button
2. On "Create in Minecraft":
   - API creates `WorldTask` with `LinkCode`
   - Web app shows: "Go to Minecraft, use `/knk task claim <code>` or server auto-claims"
   - Polls `GET /api/worldtasks/{id}` for status
   - On `Completed`: maps `OutputJson` → field value; shows checkmark
   - On `Failed`: shows error; allows retry

**Definition of Done:** Both fields populated (either from existing or task completion); all validations pass.

---

### Workflow Finalization

**Endpoint:** `POST /api/workflows/{workflowSessionId}/finalize`

**Logic:**
1. Validate all steps complete (StepProgress.Status == Completed for all)
2. Validate all world tasks complete (no Pending/InProgress/Failed tasks)
3. Create final `Town` entity from Draft + task outputs
4. Set `Town.State = Active`
5. Delete or archive `WorkflowSession` and `WorldTask` records (or mark completed)
6. Return `TownReadDto`

**Idempotency:** If already finalized, return existing Town (409 Conflict or 200 OK with existing data).

---

## 17. API Contract (Wizard/Tasks) + DTO Shapes

### Workflow Endpoints

```csharp
// Start create workflow
POST /api/workflows/town/create
Body: TownCreateDto_Step1
Response: WorkflowSessionDto { id, entityType, entityId (draft), currentStep, steps[], tasks[] }

// Update step
PUT /api/workflows/{workflowSessionId}/steps/{stepNumber}
Body: TownCreateDto_Step2 (or Step3, etc.)
Response: WorkflowSessionDto (updated)

// Finalize
POST /api/workflows/{workflowSessionId}/finalize
Response: TownReadDto (final entity)

// Get status
GET /api/workflows/{workflowSessionId}
Response: WorkflowSessionDto
```

### World Task Endpoints

```csharp
// Create task (usually called by workflow step update)
POST /api/worldtasks
Body: CreateWorldTaskDto { workflowSessionId, stepId, fieldName, taskType, inputJson }
Response: WorldTaskDto { id, linkCode, status, ... }

// List tasks (for plugin polling or web app diagnostics)
GET /api/worldtasks?status=Pending&serverId={serverId}
Response: WorldTaskDto[]

// Claim task
POST /api/worldtasks/{id}/claim
Body: ClaimTaskDto { serverId?, minecraftUsername? }
Response: WorldTaskDto (status → InProgress, claimedAt, claimedBy)

// Complete task
POST /api/worldtasks/{id}/complete
Body: CompleteTaskDto { outputJson }
Response: WorldTaskDto (status → Completed, output mapped)

// Fail task
POST /api/worldtasks/{id}/fail
Body: FailTaskDto { errorMessage }
Response: WorldTaskDto (status → Failed, retryable)

// Get task status (polling)
GET /api/worldtasks/{id}
Response: WorldTaskDto
```

### DTO Shapes

```csharp
public class WorkflowSessionDto
{
    public int Id { get; set; }
    public string EntityType { get; set; } = string.Empty; // "Town"
    public int? EntityId { get; set; } // Draft entity ID
    public string State { get; set; } = string.Empty; // "Draft", "Active", "Cancelled"
    public int CurrentStep { get; set; }
    public List<StepProgressDto> Steps { get; set; } = new();
    public List<WorldTaskDto> Tasks { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public int CreatedByUserId { get; set; }
}

public class StepProgressDto
{
    public int StepNumber { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool RequiresMinecraft { get; set; }
    public string Status { get; set; } = string.Empty; // "Pending", "InProgress", "Completed"
    public DateTime? CompletedAt { get; set; }
}

public class WorldTaskDto
{
    public int Id { get; set; }
    public int WorkflowSessionId { get; set; }
    public int StepNumber { get; set; }
    public string FieldName { get; set; } = string.Empty;
    public string TaskType { get; set; } = string.Empty; // "CaptureLocation", "DefineRegion"
    public string Status { get; set; } = string.Empty; // "Pending", "InProgress", "Completed", "Failed"
    public string? LinkCode { get; set; }
    public string InputJson { get; set; } = "{}";
    public string? OutputJson { get; set; }
    public string? ErrorMessage { get; set; }
    public string? ClaimedByServerId { get; set; }
    public string? ClaimedByMinecraftUsername { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ClaimedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class CreateWorldTaskDto
{
    public int WorkflowSessionId { get; set; }
    public int StepNumber { get; set; }
    public string FieldName { get; set; } = string.Empty;
    public string TaskType { get; set; } = string.Empty;
    public string InputJson { get; set; } = "{}";
}

public class ClaimTaskDto
{
    public string? ServerId { get; set; }
    public string? MinecraftUsername { get; set; }
}

public class CompleteTaskDto
{
    public string OutputJson { get; set; } = "{}";
}

public class FailTaskDto
{
    public string ErrorMessage { get; set; } = string.Empty;
}
```

### Concurrency Control (API-07)

**Strategy:** Optimistic concurrency using `RowVersion` on `WorkflowSession` entity.

- Each update endpoint accepts `If-Match: {etag}` header or `rowVersion` in body
- API returns `409 Conflict` if version mismatch
- Web app refetches and prompts admin to retry

**Alternative (simpler v1):** Single active workflow per entity type + user; API rejects if duplicate create started.

### Audit Trail (API-08)

**Logged Events:**
- Workflow created (who, when, entity type)
- Step completed (step number, when)
- Task created/claimed/completed/failed (who, when, output/error)
- Finalization (when, resulting entity ID)

**Storage:** `AuditLog` entity or structured logs (JSON) queryable via diagnostics endpoint.

---

## 18. Plugin Task Handlers + Commands

### Task Handler Architecture

**Pattern:** Each `TaskType` has a handler class implementing `IWorldTaskHandler`:

```java
public interface IWorldTaskHandler {
    String getTaskType();
    CompletableFuture<TaskResult> execute(WorldTaskDto task, Player admin);
}
```

**Implementations:**

1. **CaptureLocationHandler**
   - Prompts admin to stand at desired location
   - Captures world + x/y/z + yaw/pitch
   - Returns `{ locationId: ... }` (after API persist or inline)

2. **DefineRegionHandler**
   - If `allowExisting`: list regions via API + prompt selection
   - If `allowCreate`: guide WorldEdit selection → create WG region → validate containment (if configured) → return `{ wgRegionId: ... }`

3. **ValidateRegionContainmentHandler** (generic, reusable for REG-01..06)
   - Input: `{ childRegionId, parentRegionId }`
   - Checks WG API: child fully within parent
   - Returns success or error with detailed message

### Commands

```
/knk tasks list [status]
  - Lists tasks claimable by current player or server
  - Shows: ID, Type, Entity, Status, Link Code

/knk task claim <id|linkCode>
  - Claims task (calls POST /api/worldtasks/{id}/claim)
  - Starts guided flow (handler.execute())

/knk task status <id>
  - Shows current task status from API

/knk task cancel <id>
  - Fails task with "Cancelled by admin" message
  - (Optional) Allows retry from Web App

/knk health
  - (Already exists) Shows API connectivity
```

### Async Networking (PL-05)

**Pattern:**
```java
CompletableFuture.supplyAsync(() -> apiClient.claimTask(taskId), executorService)
    .thenApplyAsync(task -> {
        // Perform world changes on main thread
        return Bukkit.getScheduler().callSyncMethod(plugin, () -> {
            handler.execute(task, player);
        }).get();
    }, executorService)
    .thenAcceptAsync(result -> {
        apiClient.completeTask(taskId, result);
    }, executorService)
    .exceptionally(ex -> {
        apiClient.failTask(taskId, ex.getMessage());
        return null;
    });
```

**Key Points:**
- API calls on async executor
- World/Bukkit calls on main thread via `callSyncMethod`
- No blocking waits on main thread

### Containment Validation (REG-01..06)

**Configuration (API-side):**

```csharp
public class RegionContainmentRule
{
    public int Id { get; set; }
    public string EntityType { get; set; } = string.Empty; // "District", "Street", etc.
    public string ChildRegionFieldName { get; set; } = "WgRegionId";
    public string ParentEntityNavigationPath { get; set; } = "Town.WgRegionId"; // e.g., "District.Town.WgRegionId"
    public bool IsRequired { get; set; } = true;
}
```

**Runtime (Plugin):**
- Before completing `DefineRegion` task, query `/api/regioncontainmentrules?entityType={entityType}`
- For each rule:
  - Fetch parent region ID from API (via workflow context or explicit query)
  - Validate child region bounds fully within parent (WG API)
  - If fails: return error, block completion

**Error Message:**
> "The selected region extends outside the required parent region '{parentName}'. Please adjust your selection to fit within the bounds."

---

## 19. Open Questions (Resolved with Defaults)

1. **Location storage strategy:**
   - **Default for v1:** Option A (normalized `Location` entity with Id, World, X, Y, Z, Yaw, Pitch + `Town.SpawnLocationId FK`)
   - Rationale: reusable, queryable, follows existing FK patterns

2. **WorldGuard region reference:**
   - **Default for v1:** Option A (store region name as string; `WgRegionId` = region name)
   - Rationale: simpler; WorldGuard is source of truth; no sync issues

3. **Link code lifetime:**
   - **Default:** 15 minutes; single-use; expires on claim or timeout
   - Rationale: balances security with UX (admin has time to switch contexts)

4. **Multiple Minecraft servers:**
   - **v1 assumption:** Single dev server; `ServerId` optional (defaults to "primary")
   - **v2 scope:** Multi-server task routing (admin selects target world/server in Web App)

5. **Edit workflow vs create:**
   - **v1:** Edit uses same `WorkflowSession` pattern; creates tasks for changed world-bound fields only
   - Immediate apply on finalize (no staging/approval unless explicitly added later)

6. **Wizard UI: custom vs generic form:**
   - **Default:** Extend `GenericEntityForm` with `WizardStepContainer` wrapper; reuse field rendering
   - If generic proves insufficient, create Town-specific wizard component

7. **Task polling interval (Web App):**
   - **Default:** Poll every 3 seconds while task status is `InProgress`; stop on `Completed`/`Failed`

8. **Concurrent workflows:**
   - **v1 rule:** One active create workflow per entity type per user (DB unique constraint)
   - **Edit:** One active edit workflow per entity instance (lock at entity level)

9. **Task claim model:**
   - **v1:** Manual claim via `/knk task claim <code>` (link code displayed in Web App)
   - **v2 (optional):** Auto-claim by server polling if configured

10. **Region selection UX:**
    - **v1:** Cuboid only (WorldEdit selection → WG region creation)
    - **v2:** Polygon support (if WG/WorldCard supports and plugin implements)

---

## 20. What to Implement Next (Ordered Checklist)

🔄 **Workstream A — Phase 1 Implementation**

### Backend (API)

1. **Create entities:** `WorkflowSession`, `StepProgress`, `WorldTask`, `RegionContainmentRule`, `Location`
2. **Create DTOs:** `WorkflowSessionDto`, `StepProgressDto`, `WorldTaskDto`, `CreateWorldTaskDto`, `ClaimTaskDto`, `CompleteTaskDto`, `FailTaskDto`
3. **Implement repositories + interfaces:** `IWorkflowSessionRepository`, `IWorldTaskRepository`, `ILocationRepository`
4. **Implement services + interfaces:** `IWorkflowService` (create/update/finalize), `IWorldTaskService` (create/claim/complete/fail)
5. **Create AutoMapper profiles** for all new DTOs ↔ entities
6. **Implement controllers:** `WorkflowsController`, `WorldTasksController` with full CRUD + finalize/claim/complete endpoints
7. **Add validation:** workflow step completion checks, task idempotency, concurrency control (RowVersion or lock)
8. **Seed `RegionContainmentRule`** for Town/District example (District.WgRegionId must be within District.Town.WgRegionId)
9. **Add audit logging** for workflow events (create/step/task/finalize)
10. **Update Swagger/OpenAPI** and test all endpoints via Swagger UI

### Web App

1. **Generate TypeScript types** from updated Swagger (DTOs for workflow/tasks)
2. **Create API client methods** in existing API service (workflow CRUD, task status polling)
3. **Create `WizardStepContainer` component** (wraps `GenericEntityForm`; adds step navigation, progress indicator)
4. **Create `WorldBoundFieldRenderer` component** (shows "Choose existing" dropdown + "Create in Minecraft" button; polls task status; displays output)
5. **Create `WorkflowStatusPanel` component** (diagnostics: shows steps, tasks, errors)
6. **Implement Town Create Wizard** using `WizardStepContainer` + 3 steps (General, Rules, World Data)
7. **Add task status polling hook** (`useTaskStatus(taskId)` → polls every 3s until complete)
8. **Add link code display + copy button** (when task created)
9. **Add error handling + retry logic** (failed task → show error + "Retry" button)
10. **Test end-to-end** Town create flow (Web App → API → manual task completion via API test → finalize)

### Plugin

1. **Create DTO classes** matching API contract (`WorldTaskDto`, `ClaimTaskDto`, `CompleteTaskDto`, etc.)
2. **Implement `ApiClient` methods:** `listTasks()`, `claimTask(id)`, `completeTask(id, output)`, `failTask(id, error)`
3. **Create `IWorldTaskHandler` interface + handler registry**
4. **Implement `CaptureLocationHandler`** (prompt player, capture coords, persist Location via API, return locationId)
5. **Implement `DefineRegionHandler`** (guide WorldEdit selection, create WG region, validate containment if configured, return regionId)
6. **Implement `/knk tasks list` command** (queries API, displays tasks)
7. **Implement `/knk task claim <code>` command** (claims task, starts handler flow)
8. **Implement `/knk task status <id>` command** (queries API, shows status)
9. **Add async executor pattern** for all API calls (no main thread blocking)
10. **Test end-to-end:** claim task in-game → complete DefineRegion → verify API receives output → finalize in Web App

---

For each entity (Town, District, Street, Structure, …), the feature is "Done" when:

- [ ] Backend: All entities/DTOs/services/controllers implemented and tested
- [ ] Backend: Swagger contract includes all workflow/task endpoints
- [ ] Web App: Entity Create Wizard functional with all required steps
- [ ] Web App: World-bound fields show task status + link code
- [ ] Plugin: Can claim and complete all required task types (`CaptureLocation`, `DefineRegion`, etc.)
- [ ] Plugin: Containment validation blocks invalid region definitions (if configured)
- [ ] End-to-end test: Admin creates entity via Web App → completes world tasks in Minecraft → finalizes → entity is Active
- [ ] Audit trail visible in diagnostics panel (all steps/tasks logged)
- [ ] No blocking I/O on Minecraft main thread (verified via profiler or logs)
- [ ] Documentation: Updated with workflow usage guide for admins

---

## 23. Conditional Validation Framework (Field-Level Validations)

🔄 **Workstream B — Phase 2 Implementation** (Independent from Workstream A)

### 23.1 Overview

The **Conditional Validation Framework** enables administrators to define dynamic, cross-field validation rules that execute at **field-level** (not step-level or entity-level in v1). These rules can validate field values against related entity data via API calls.

**Primary Use Cases (v1):**
- Validate Location coordinates are **inside** a WorldGuard region (defined earlier in the form)
- Validate a child region is **fully contained** within a parent region (from related entity)
- Extensible for future validators (e.g., "check name is unique", "coordinate within world bounds")

**Key Constraint:** Field validations assume that dependency fields are filled out before validation executes. Admin is responsible for field ordering in FormConfiguration. System provides warnings if dependency not yet filled; once filled, validations execute automatically.

---

### 23.2 Entity Models: FieldValidationRule

#### FieldValidationRule.cs
```csharp
using System;
using System.Collections.Generic;

namespace knkwebapi_v2.Models
{
    /// <summary>
    /// Represents a validation rule attached to a FormField.
    /// 
    /// SCENARIO:
    /// - Field: District's SpawnLocationId
    /// - Rule: Location must be inside the District's Town's WorldGuard region
    /// - Config: depends on district TownId field; fetches Town's WgRegionId; validates Location inside region
    /// 
    /// EXECUTION FLOW (Frontend):
    /// 1. User fills District.TownId field (selects a Town)
    /// 2. System stores selected Town entity (at least {id, WgRegionId})
    /// 3. User fills District.SpawnLocationId (selects or creates Location)
    /// 4. On location selection/creation:
    ///    a. Check if dependency field (TownId) is filled → if not, show warning "Cannot validate until Town selected"
    ///    b. If filled, fetch Town data from form context
    ///    c. Invoke validation API (regions.validateLocationInside) with {townWgRegionId, locationCoords}
    ///    d. Show result: ✅ success or ❌ failure with error message
    /// 5. If IsBlocking = true and validation failed, prevent step progression
    /// </summary>
    public class FieldValidationRule
    {
        public int Id { get; set; }

        /// <summary>
        /// Foreign key to the FormField this rule is attached to.
        /// </summary>
        public int FormFieldId { get; set; }
        public FormField FormField { get; set; } = null!;

        /// <summary>
        /// Type of validation to perform.
        /// 
        /// Supported types (v1):
        /// - "LocationInsideRegion": Validates Location coordinates are inside a WorldGuard region
        /// - "RegionContainment": Validates child region is fully contained within parent region
        /// 
        /// Future types:
        /// - "UniqueInEntity": Field value is unique within entity scope
        /// - "CustomApiCall": Invoke arbitrary validation API endpoint
        /// </summary>
        public string ValidationType { get; set; } = string.Empty;

        /// <summary>
        /// Foreign key to the FormField this rule depends on (for data retrieval).
        /// 
        /// EXAMPLE:
        /// - This rule is on LocationId field
        /// - DependsOnFieldId = TownId field
        /// - At validation time, system fetches the TownId value from form context
        /// - Uses TownId to fetch Town entity
        /// - Extracts Town.WgRegionId for validation
        /// 
        /// If NULL, rule does not depend on another field (e.g., "check email is unique")
        /// </summary>
        public int? DependsOnFieldId { get; set; }
        public FormField? DependsOnField { get; set; }

        /// <summary>
        /// Generic JSON configuration for this validation rule.
        /// Structure varies by ValidationType.
        /// 
        /// EXAMPLE ConfigJson for "LocationInsideRegion":
        /// {
        ///   "validationApiMethod": "regions.validateLocationInside",
        ///   "dependencyPath": "TownId",           // Path to fetch dependency (field name or nav property)
        ///   "parentEntityRegionProperty": "WgRegionId",  // Which property on parent entity holds region ID
        ///   "childCoordinatesFromField": "SpawnLocationId",  // Field containing location data
        ///   "successMessage": "Location is within town boundaries.",
        ///   "failMessage": "Location is outside town boundaries. Select a location within {parentEntityName}."
        /// }
        /// 
        /// EXAMPLE ConfigJson for "RegionContainment":
        /// {
        ///   "validationApiMethod": "regions.validateRegionContained",
        ///   "dependencyPath": "TownId",
        ///   "parentEntityRegionProperty": "WgRegionId",
        ///   "childRegionIdFromField": "WgRegionId",  // Field on current entity containing child region
        ///   "successMessage": "District region is fully contained within town region.",
        ///   "failMessage": "District region extends outside town region. Adjust your selection."
        /// }
        /// </summary>
        public string ConfigJson { get; set; } = "{}";

        /// <summary>
        /// Error message displayed to user if validation fails.
        /// Supports placeholders: {parentEntityName}, {regionName}, {fieldLabel}
        /// Backend validation API returns placeholder values.
        /// </summary>
        public string ErrorMessage { get; set; } = string.Empty;

        /// <summary>
        /// Success message displayed if validation passes.
        /// Optional; if empty, just clears error state.
        /// </summary>
        public string? SuccessMessage { get; set; }

        /// <summary>
        /// If true, validation failure blocks field completion and step progression.
        /// If false, validation is informational only (warning badge shown but no blocking).
        /// </summary>
        public bool IsBlocking { get; set; } = true;

        /// <summary>
        /// If false, validation is skipped if the dependency field is not yet filled.
        /// If true, validation failure message shown even if dependency not filled.
        /// Default: false (more forgiving UX).
        /// </summary>
        public bool RequiresDependencyFilled { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
```

---

### 23.3 API Contract: Validation Rule Management

#### Endpoints (for FormConfiguration admin UI)

```csharp
// List validation rules for a field
GET /api/forms/fields/{fieldId}/validationrules
Response: FieldValidationRuleDto[]

// Get a specific validation rule
GET /api/forms/validationrules/{ruleId}
Response: FieldValidationRuleDto

// Create validation rule
POST /api/forms/validationrules
Body: CreateFieldValidationRuleDto { formFieldId, validationType, dependsOnFieldId, configJson, errorMessage, successMessage, isBlocking }
Response: FieldValidationRuleDto

// Update validation rule
PUT /api/forms/validationrules/{ruleId}
Body: UpdateFieldValidationRuleDto { validationType, configJson, errorMessage, successMessage, isBlocking }
Response: FieldValidationRuleDto

// Delete validation rule
DELETE /api/forms/validationrules/{ruleId}
Response: 204 No Content

// Validate a field value against all its rules (used by form wizard)
POST /api/forms/validationrules/validate
Body: ValidateFieldDto { 
  fieldId, 
  fieldValue, 
  formContextData // all step data collected so far
}
Response: ValidationResultDto { 
  isValid, 
  message, 
  placeholders, 
  isBlocking 
}
```

#### DTO Shapes

```csharp
public class FieldValidationRuleDto
{
    public int Id { get; set; }
    public int FormFieldId { get; set; }
    public string ValidationType { get; set; } = string.Empty;
    public int? DependsOnFieldId { get; set; }
    public string ConfigJson { get; set; } = "{}";
    public string ErrorMessage { get; set; } = string.Empty;
    public string? SuccessMessage { get; set; }
    public bool IsBlocking { get; set; } = true;
    public bool RequiresDependencyFilled { get; set; } = false;
}

public class CreateFieldValidationRuleDto
{
    public int FormFieldId { get; set; }
    public string ValidationType { get; set; } = string.Empty;
    public int? DependsOnFieldId { get; set; }
    public string ConfigJson { get; set; } = "{}";
    public string ErrorMessage { get; set; } = string.Empty;
    public string? SuccessMessage { get; set; }
    public bool IsBlocking { get; set; } = true;
}

public class UpdateFieldValidationRuleDto
{
    public string ValidationType { get; set; } = string.Empty;
    public int? DependsOnFieldId { get; set; }
    public string ConfigJson { get; set; } = "{}";
    public string ErrorMessage { get; set; } = string.Empty;
    public string? SuccessMessage { get; set; }
    public bool IsBlocking { get; set; } = true;
}

public class ValidateFieldDto
{
    public int FieldId { get; set; }
    public object? FieldValue { get; set; }
    public Dictionary<string, object?> FormContextData { get; set; } = new();  // {fieldName: value}
}

public class ValidationResultDto
{
    public bool IsValid { get; set; }
    public string? Message { get; set; }
    public Dictionary<string, string>? Placeholders { get; set; }  // {placeholderName: value}
    public bool IsBlocking { get; set; }
}
```

---

### 23.4 Validation Methods (Hardcoded for v1)

**Validation Method Registry (Backend):**

```csharp
// In a new ValidationMethodRegistry.cs or ValidationService.cs
public interface IValidationMethod
{
    string MethodName { get; }
    Task<ValidationResultDto> ExecuteAsync(
        FieldValidationRule rule,
        object? fieldValue,
        Dictionary<string, object?> formContextData
    );
}

// Implementation: regions.validateLocationInside
public class LocationInsideRegionValidator : IValidationMethod
{
    public string MethodName => "regions.validateLocationInside";

    public async Task<ValidationResultDto> ExecuteAsync(
        FieldValidationRule rule,
        object? fieldValue,
        Dictionary<string, object?> formContextData
    )
    {
        // 1. Parse ConfigJson
        var config = JsonSerializer.Deserialize<LocationInsideRegionConfig>(rule.ConfigJson);
        
        // 2. Fetch dependency field value (e.g., TownId from form context)
        if (!formContextData.TryGetValue(config!.DependencyPath, out var parentEntityId) || parentEntityId == null)
        {
            return new ValidationResultDto 
            { 
                IsValid = rule.RequiresDependencyFilled == false,  // Pass if dependency not required
                Message = $"Validation pending until {config.DependencyPath} is filled.",
                IsBlocking = false
            };
        }

        // 3. Fetch parent entity to get region ID (e.g., Town with WgRegionId)
        var parentEntity = await entityService.GetByIdAsync("Town", (int)parentEntityId);
        if (parentEntity == null)
        {
            return new ValidationResultDto 
            { 
                IsValid = false,
                Message = "Parent entity not found.",
                IsBlocking = rule.IsBlocking
            };
        }

        var regionId = parentEntity.GetProperty(config.ParentEntityRegionProperty) as string;
        if (string.IsNullOrEmpty(regionId))
        {
            return new ValidationResultDto 
            { 
                IsValid = false,
                Message = $"Parent entity has no {config.ParentEntityRegionProperty} defined.",
                IsBlocking = rule.IsBlocking
            };
        }

        // 4. Validate location inside region (call WorldGuard API)
        var location = fieldValue as Location;
        if (location == null)
        {
            return new ValidationResultDto 
            { 
                IsValid = false,
                Message = "Invalid location data.",
                IsBlocking = rule.IsBlocking
            };
        }

        var isInside = await regionService.IsLocationInsideAsync(regionId, location);

        return new ValidationResultDto 
        { 
            IsValid = isInside,
            Message = isInside ? rule.SuccessMessage : rule.ErrorMessage,
            Placeholders = isInside ? null : new Dictionary<string, string>
            {
                { "parentEntityName", parentEntity.Name },
                { "regionName", regionId }
            },
            IsBlocking = rule.IsBlocking
        };
    }
}

// Implementation: regions.validateRegionContained
public class RegionContainmentValidator : IValidationMethod
{
    public string MethodName => "regions.validateRegionContained";

    public async Task<ValidationResultDto> ExecuteAsync(
        FieldValidationRule rule,
        object? fieldValue,
        Dictionary<string, object?> formContextData
    )
    {
        // Similar pattern: fetch parent region, validate child region inside
        // ... implementation
    }
}

// Service to dispatch to correct validator
public class ValidationService
{
    private readonly Dictionary<string, IValidationMethod> _validators;

    public ValidationService()
    {
        _validators = new Dictionary<string, IValidationMethod>
        {
            { "regions.validateLocationInside", new LocationInsideRegionValidator(...) },
            { "regions.validateRegionContained", new RegionContainmentValidator(...) }
        };
    }

    public async Task<ValidationResultDto> ValidateFieldAsync(
        FieldValidationRule rule,
        object? fieldValue,
        Dictionary<string, object?> formContextData
    )
    {
        var config = JsonSerializer.Deserialize<dynamic>(rule.ConfigJson);
        var methodName = config?["validationApiMethod"]?.ToString();

        if (!_validators.TryGetValue(methodName, out var validator))
        {
            return new ValidationResultDto 
            { 
                IsValid = false,
                Message = $"Unknown validation method: {methodName}",
                IsBlocking = false
            };
        }

        return await validator.ExecuteAsync(rule, fieldValue, formContextData);
    }
}
```

---

### 23.5 Frontend Integration: Validation Rule Builder UI

**New Component: `ValidationRuleBuilder.tsx`**

Located in: `Repository/knk-web-app/src/components/FormConfigBuilder/ValidationRuleBuilder.tsx`

```tsx
export interface ValidationRuleBuilderProps {
    field: FormFieldDto;
    otherFields: FormFieldDto[];  // Fields available in this form
    onSave: (rule: FieldValidationRuleDto) => void;
    onCancel: () => void;
}

/**
 * UI for admin to configure validation rules on a FormField.
 * 
 * Flow:
 * 1. Admin selects ValidationType (e.g., "LocationInsideRegion")
 * 2. System shows form fields specific to that type
 * 3. Admin selects DependsOnField from dropdown (e.g., "TownId")
 * 4. Admin enters error/success messages
 * 5. Admin toggles IsBlocking
 * 6. On save, generate ConfigJson and POST to API
 */
export const ValidationRuleBuilder: React.FC<ValidationRuleBuilderProps> = ({
    field,
    otherFields,
    onSave,
    onCancel
}) => {
    const [ruleType, setRuleType] = useState<'LocationInsideRegion' | 'RegionContainment'>('LocationInsideRegion');
    const [dependsOnFieldId, setDependsOnFieldId] = useState<number | null>(null);
    const [errorMessage, setErrorMessage] = useState('');
    const [successMessage, setSuccessMessage] = useState('');
    const [isBlocking, setIsBlocking] = useState(true);

    const availableDependencyFields = otherFields.filter(f => f.id !== field.id);

    const handleSave = () => {
        if (!dependsOnFieldId || !errorMessage.trim()) {
            alert('Please fill all required fields');
            return;
        }

        const configJson = {
            validationApiMethod: ruleType === 'LocationInsideRegion'
                ? 'regions.validateLocationInside'
                : 'regions.validateRegionContained',
            dependencyPath: otherFields.find(f => f.id === dependsOnFieldId)?.fieldName,
            parentEntityRegionProperty: 'WgRegionId',  // TODO: Make configurable
            childCoordinatesFromField: field.fieldName,
            successMessage
        };

        onSave({
            validationType: ruleType,
            dependsOnFieldId,
            errorMessage,
            successMessage,
            isBlocking,
            configJson: JSON.stringify(configJson)
        });
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg p-6 max-w-md">
                <h3 className="text-lg font-medium mb-4">Add Validation Rule</h3>

                <div className="space-y-4">
                    {/* Rule Type Selection */}
                    <div>
                        <label className="block text-sm font-medium mb-1">Rule Type</label>
                        <select
                            value={ruleType}
                            onChange={(e) => setRuleType(e.target.value as any)}
                            className="w-full border rounded px-2 py-1"
                        >
                            <option value="LocationInsideRegion">Location Inside Region</option>
                            <option value="RegionContainment">Region Contained in Parent Region</option>
                        </select>
                    </div>

                    {/* Dependency Field Selection */}
                    <div>
                        <label className="block text-sm font-medium mb-1">
                            Depends on Field *
                        </label>
                        <select
                            value={dependsOnFieldId || ''}
                            onChange={(e) => setDependsOnFieldId(Number(e.target.value))}
                            className="w-full border rounded px-2 py-1"
                        >
                            <option value="">-- Select dependency field --</option>
                            {availableDependencyFields.map(f => (
                                <option key={f.id} value={f.id}>
                                    {f.label || f.fieldName}
                                </option>
                            ))}
                        </select>
                        <p className="text-xs text-gray-600 mt-1">
                            ⚠️ Admin must order fields so this field comes after dependency field
                        </p>
                    </div>

                    {/* Error Message */}
                    <div>
                        <label className="block text-sm font-medium mb-1">
                            Error Message *
                        </label>
                        <textarea
                            value={errorMessage}
                            onChange={(e) => setErrorMessage(e.target.value)}
                            placeholder="e.g., Location is outside the region bounds. Select a location within {parentEntityName}."
                            rows={2}
                            className="w-full border rounded px-2 py-1"
                        />
                        <p className="text-xs text-gray-600 mt-1">
                            Supported placeholders: {'{parentEntityName}'}, {'{regionName}'}, {'{fieldLabel}'}
                        </p>
                    </div>

                    {/* Success Message (optional) */}
                    <div>
                        <label className="block text-sm font-medium mb-1">Success Message (optional)</label>
                        <input
                            type="text"
                            value={successMessage}
                            onChange={(e) => setSuccessMessage(e.target.value)}
                            placeholder="e.g., Location is within region bounds."
                            className="w-full border rounded px-2 py-1"
                        />
                    </div>

                    {/* Blocking Toggle */}
                    <div className="flex items-center">
                        <input
                            type="checkbox"
                            checked={isBlocking}
                            onChange={(e) => setIsBlocking(e.target.checked)}
                            id="blocking"
                        />
                        <label htmlFor="blocking" className="ml-2 text-sm">
                            Block form progress if validation fails
                        </label>
                    </div>
                </div>

                <div className="flex justify-end space-x-2 mt-6">
                    <button onClick={onCancel} className="btn-secondary">Cancel</button>
                    <button onClick={handleSave} className="btn-primary">Add Rule</button>
                </div>
            </div>
        </div>
    );
};
```

---

### 23.6 Frontend Integration: FieldRenderer Validation Execution

**Updates to [FieldRenderer.tsx](FieldRenderers.tsx):**

Field renderers need to accept validation rules and execute them. The component already has:
- `allStepsData` prop (currently unused) — provides form context for dependency resolution
- `currentStepIndex` prop (currently unused)
- `errors` prop (currently unused)

```tsx
// In FieldRenderer or in wrapper component (e.g., FormWizardStep)

const executeValidationRules = async (
    field: FormFieldDto,
    fieldValue: any,
    formContextData: { [fieldName: string]: any }
) => {
    const rules = field.validationRules || [];
    const results: ValidationResultDto[] = [];

    for (const rule of rules) {
        try {
            const result = await validationClient.validateField({
                fieldId: field.id!,
                fieldValue,
                formContextData
            });
            results.push(result);
        } catch (error) {
            console.error('Validation error:', error);
        }
    }

    return results;
};

// On field value change:
const handleFieldChange = async (newValue: any) => {
    onChange(newValue);
    
    // Execute validations
    if (field.validationRules && field.validationRules.length > 0) {
        const results = await executeValidationRules(field, newValue, allStepsData);
        
        // Show validation results
        const failedBlockingRules = results.filter(r => !r.isValid && r.isBlocking);
        const failedWarnings = results.filter(r => !r.isValid && !r.isBlocking);
        const successes = results.filter(r => r.isValid);

        setValidationStatus({
            isValid: failedBlockingRules.length === 0,
            messages: {
                success: successes.map(r => r.message).filter(m => m),
                error: failedBlockingRules.map(r => r.message).filter(m => m),
                warning: failedWarnings.map(r => r.message).filter(m => m)
            }
        });
    }
};
```

**Display in Field:**

```tsx
// After field input, show validation status
{validationStatus.messages.success.length > 0 && (
    <div className="mt-2 p-2 bg-green-50 border border-green-200 rounded text-xs text-green-800">
        ✅ {validationStatus.messages.success.join(' ')}
    </div>
)}

{validationStatus.messages.warning.length > 0 && (
    <div className="mt-2 p-2 bg-yellow-50 border border-yellow-200 rounded text-xs text-yellow-800">
        ⚠️ {validationStatus.messages.warning.join(' ')}
    </div>
)}

{validationStatus.messages.error.length > 0 && (
    <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-xs text-red-800">
        ❌ {validationStatus.messages.error.join(' ')}
    </div>
)}
```

---

### 23.7 Updated Town v1 FormConfig Template with Validation Rules

#### Step 3: World Data (Updated)

```csharp
[WorkflowStep(order: 3, name: "World Data", requiresMinecraft: true)]
public class TownCreateDto_Step3
{
    [WorldBoundField(TaskType = "DefineRegion", fieldLabel: "Town Region")]
    public string? WgRegionId { get; set; }

    [WorldBoundField(TaskType = "CaptureLocation", fieldLabel: "Spawn Location")]
    [ValidationRule(ValidationType = "LocationInsideRegion", DependsOnField = "WgRegionId")]
    public int? SpawnLocationId { get; set; }
}
```

**Configuration in FormConfigBuilder UI:**

1. Admin creates FormField for `WgRegionId` (order 1)
2. Admin creates FormField for `SpawnLocationId` (order 2)
3. Admin adds ValidationRule to `SpawnLocationId`:
   - **ValidationType:** LocationInsideRegion
   - **DependsOnField:** WgRegionId
   - **ErrorMessage:** "Location is outside town region boundaries. Select a location within the town."
   - **SuccessMessage:** "Location is within town boundaries."
   - **IsBlocking:** true

4. Admin saves FormConfiguration

**Runtime Flow (Form Filler):**

1. User fills `WgRegionId` (selects or creates town region)
2. User fills `SpawnLocationId` (selects or creates location)
3. On location selection:
   - Frontend checks: is `WgRegionId` filled? → Yes
   - Frontend fetches form context: `{ WgRegionId: "town_main_123" }`
   - Frontend calls validation API: `POST /api/forms/validationrules/validate`
   - Backend validator runs: `IsLocationInsideAsync("town_main_123", {x,y,z})`
   - Result: Valid ✅ → shows success message
4. User can proceed to next step

**If User Fills in Different Order:**

1. User tries to fill `SpawnLocationId` first (before `WgRegionId`)
2. On location selection:
   - Frontend checks: is `WgRegionId` filled? → No
   - Shows warning: "⚠️ Validation pending until Town Region is defined"
   - Does NOT validate (RequiresDependencyFilled = false)
   - User can continue
3. Later, user fills `WgRegionId`
4. Frontend automatically re-validates `SpawnLocationId` against new region
5. Shows success/failure accordingly

---

### 23.8 Implementation Separation: Hybrid Workflow vs Validation Framework

**These are TWO INDEPENDENT WORKSTREAMS:**

#### **Workstream A: Hybrid Create/Edit Workflow**
- Entities: `WorkflowSession`, `StepProgress`, `WorldTask`
- Services: `IWorkflowService`, `IWorldTaskService`
- Controllers: `WorkflowsController`, `WorldTasksController`
- UI: `WizardStepContainer`, `WorldBoundFieldRenderer`
- **Does NOT depend on:** FieldValidationRule, validation framework
- **Can be implemented independently:** Yes
- **Prerequisite for:** Basic multi-step form progression, task polling, finalization
- **Acceptance:** Admin can create Town in 3 steps; regions/locations captured via game tasks

#### **Workstream B: Conditional Validation Framework**
- Entities: `FieldValidationRule`
- Services: `IValidationService`, `IValidationMethod` implementations
- Controllers: `/api/forms/validationrules/*`
- UI: `ValidationRuleBuilder`, updates to `FieldRenderer`
- **Depends on:** FormField already existing (✅ already in codebase)
- **Does NOT depend on:** Workstream A (Hybrid workflow)
- **Can be implemented independently:** Yes, in parallel or after Workstream A
- **Can be tested independently:** Yes, via standalone form validation API tests
- **Acceptance:** Admin can configure validation rule on Location field; rule executes and blocks invalid locations

---

**RECOMMENDATION:** Implement in order:
1. **Phase 1 (Workstream A):** Hybrid Workflow (sections 17-20)
2. **Phase 2 (Workstream B):** Validation Framework (this section 23)

This allows Phase 1 to ship without validation, then Phase 2 can add smart validations retroactively.

---

### 23.9 Breaking Dependency Detection & Feedback

To address Q2 (good feedback for broken dependencies):

**On FieldValidationRule Load (FormConfiguration UI):**

```csharp
public class FormConfigurationService
{
    public async Task<List<ValidationIssue>> ValidateConfigurationAsync(FormConfiguration config)
    {
        var issues = new List<ValidationIssue>();

        foreach (var step in config.Steps)
        {
            foreach (var field in step.Fields)
            {
                foreach (var rule in field.ValidationRules)
                {
                    // Check 1: Does dependency field exist?
                    if (rule.DependsOnFieldId != null)
                    {
                        var depField = config.Steps
                            .SelectMany(s => s.Fields)
                            .FirstOrDefault(f => f.Id == rule.DependsOnFieldId);

                        if (depField == null)
                        {
                            issues.Add(new ValidationIssue
                            {
                                Severity = IssueSeverity.Error,
                                Message = $"Field '{field.Label}' has validation rule depending on deleted field (ID: {rule.DependsOnFieldId})",
                                FieldId = field.Id,
                                RuleId = rule.Id
                            });
                        }
                    }

                    // Check 2: Does dependency come BEFORE this field in form flow?
                    if (rule.DependsOnFieldId != null)
                    {
                        var depField = config.Steps
                            .SelectMany((s, stepIdx) => s.Fields.Select(f => (Field: f, StepIndex: stepIdx, Field.Order)))
                            .FirstOrDefault(x => x.Field.Id == rule.DependsOnFieldId);

                        var currentField = step.Fields.FirstOrDefault(f => f.Id == field.Id);
                        var currentStepIndex = config.Steps.IndexOf(step);

                        if (depField.StepIndex > currentStepIndex || 
                            (depField.StepIndex == currentStepIndex && depField.Order > currentField?.Order))
                        {
                            issues.Add(new ValidationIssue
                            {
                                Severity = IssueSeverity.Warning,
                                Message = $"Field '{field.Label}' depends on '{depField.Field.Label}' which comes AFTER it. Admin should reorder fields.",
                                FieldId = field.Id,
                                RuleId = rule.Id
                            });
                        }
                    }
                }
            }
        }

        return issues;
    }
}
```

**Display in FormConfigBuilder UI:**

```tsx
// Show validation issues as "Configuration Health"
<div className="mt-4 border-t pt-4">
    <h4 className="font-medium mb-2">Configuration Health</h4>
    {validationIssues.length === 0 ? (
        <p className="text-sm text-green-600">✅ No issues found</p>
    ) : (
        <div className="space-y-2">
            {validationIssues.map((issue) => (
                <div
                    key={issue.RuleId}
                    className={`p-2 rounded text-sm ${
                        issue.Severity === 'Error'
                            ? 'bg-red-50 border border-red-200 text-red-800'
                            : 'bg-yellow-50 border border-yellow-200 text-yellow-800'
                    }`}
                >
                    {issue.Severity === 'Error' ? '❌' : '⚠️'} {issue.Message}
                </div>
            ))}
        </div>
    )}
</div>
```

---

## 22. Generic Requirement: Region Containment Validation (WorldCard/WorldGuard Regions)

### 22.1 Summary

For any entity that uses a WorldCard/WorldGuard region, the system must support **configurable containment validation**: a region for one entity must be fully contained within a specified "parent" region (belonging to another entity).

This rule must be **configurable by administrators** (not hard-coded to Town/District only) and must apply to both **create** and **edit** flows when configured.

### 22.2 Administrator-configurable rules

**REG-01 — Configurable containment rule**
- An administrator can configure, per entity type (and/or per workflow step), whether containment validation is required.

**REG-02 — Select parent region source**
- An administrator can specify which region is the “parent” region to validate against.
- The rule must support scenarios where the parent region comes from a related entity (e.g., “District region must be within its owning Town region”), but must not be limited to that example.

**REG-03 — Multiple containment checks**
- The system must support multiple containment validations for the same workflow if needed (e.g., validate against multiple constraints, or nested parents).

### 16.3 Runtime validation behavior (Plugin)

**REG-04 — Immediate feedback**
- During in-game region definition (selection/editing), the plugin must validate containment and provide immediate/near-immediate feedback when any part lies outside the configured parent region.

**REG-05 — Blocking invalid completion**
- The plugin must prevent completion of the region-definition task if containment validation fails.

**REG-06 — Error messaging**
- Error feedback must clearly indicate that some selected points/edges are outside the parent region and instruct the admin to adjust the selection.
- Messaging must be generic and not tied to specific entity names.

### 16.4 Acceptance criteria

- It is impossible to finalize a world-bound region task when configured containment rules are violated.
- Admins can configure which containment checks apply and which parent region(s) are used.
- The same mechanism applies to any entity that uses regions (not only Town/District).
