# WorldTask Feature Documentation

**Status:** Living reference for the lifecycle (§ "Lifecycle and endpoints" below, as built by PandiO/knk-workspace#180 on
the `claude/world-task-hardening` branches, not merged yet). The other files in this folder are older design notes:
where they differ from that section, the section is current.
**Last updated:** 2026-11-01 (world-task hardening and tasks anchored to the draft, #180; design
[realtime-signalr/DESIGN.md](../realtime-signalr/DESIGN.md) §8.2, §8.7)

## Overview

The **WorldTask** feature enables administrators to capture Minecraft-specific data (world coordinates, regions, locations) directly from the game world while filling out creation/edit forms in the Knights & Kings web application. This bridges the gap between the web admin interface and in-game data collection through a claim-and-execute workflow.

## Key Concepts

### WorldTask
A task that captures world-bound data from a Minecraft player's current context. Each task:
- Is linked to a specific form field (e.g., `Location`, `WgRegionId`) and, since #180, to the form's draft
- Has a 6-character **task code** (the column is still called `LinkCode`; "claim code" now means the invitation claim
  code, #57) that a player types in game: `/knk task <code>`
- Can be claimed by one Minecraft player at a time to collect data
- Moves through `Pending` → `InProgress` → `Completed` / `Failed`, and can end `Cancelled` or `Expired` (§ below)
- Contains input/output JSON for field-specific data

### Workflow Integration
WorldTasks are embedded within **Workflows** (multi-step entity creation/edit processes):
- Each workflow step can have world-bound fields that require WorldTasks
- The task captures data specific to that field
- Upon completion, the captured data updates the workflow's step progress
- When all steps are complete, the workflow finalizes and creates/updates the entity

## Feature Scope

This documentation covers:
1. **Architecture & Design** - System design, data flow, and component relationships
2. **API Contract** - .NET Web API endpoints, DTOs, and request/response formats
3. **UI/UX** - React web app components, wizard integration, task monitoring
4. **Plugin Implementation** - Minecraft plugin handlers, chat commands, event listeners
5. **Handler Development Guide** - How to create new task handlers (e.g., `LocationTaskHandler`)

## Related Documents

- [SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) - Detailed technical specification
- [REQUIREMENTS_WORLDTASK.md](REQUIREMENTS_WORLDTASK.md) - Functional and technical requirements
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and data flow
- [HANDLER_DEVELOPMENT_GUIDE.md](HANDLER_DEVELOPMENT_GUIDE.md) - Creating custom task handlers
- [API_CONTRACT.md](API_CONTRACT.md) - Complete API endpoint reference

## Quick Start

### Creating a Town with WorldTask

1. **Web App**: Admin navigates to `/towns/create` and starts the creation wizard
2. **Step 1**: Admin fills in basic info (name, description)
3. **Step 2**: Admin configures rules (allow entry/exit)
4. **Step 3**: Admin selects world data via Minecraft tasks:
   - System generates a `Location` task with a LinkCode (e.g., `ABC123`)
   - System generates a `WgRegionId` task with a LinkCode (e.g., `XYZ789`)
5. **Minecraft**: Admin joins the server and claims each task with its task code: `/knk task {code}`
6. **In-Game**: Admin executes the task:
   - For Location: Stand where you want and type `save` in chat
   - For WgRegionId: Define a region and type `save` in chat
7. **Web App**: the field panel polls the task every 2 s and fills the field when it completes
8. **Finalization**: Admin clicks "Create" to finalize the workflow and entity is created

## Architecture Layers

```
Web App Layer (knk-web-app)
├── FormWizardPage & FormWizard (one workflow session per draft)
├── WorldBoundFieldRenderer (task panel; polls every 2 s while the task is open)
└── worldTaskClient / workflowClient

Web API Layer (knk-web-api)
├── WorldTasksController (endpoints)
├── WorldTaskService (state machine, task codes, claims, leases)
├── WorldTaskSweepService (expiry, lease release, abandoned sessions)
├── WorkflowService (workflow orchestration)
└── WorldTask Repository (data access)

Minecraft Plugin Layer (knk-plugin)
├── WorldTaskHandlerRegistry (routing), WorldTaskLeases (heartbeat, hand back)
├── Task Handlers (IWorldTaskHandler implementations)
│   ├── WgRegionIdTaskHandler
│   └── LocationTaskHandler (new)
├── Chat Command Listeners
└── Event Listeners
```

## Commits Reference

Implementation across three repositories:

**knk-web-api:**
- `3a64c0d` - Hybrid workflow with task integration (models, services, API)
- `b6fdad2` - WorldTask implementation (expanded controller, service logic)

**knk-web-app:**
- `324fc4b` - Multi-step wizard UI and task monitoring components
- `c5d3cf5`, `b7cdc4b` - Improvements and functional testing

**knk-plugin:**
- `08bb1de` - WorldTask foundation (API client, DTO, commands, listeners)
- `a471b55` - WgRegionIdTaskHandler implementation
- `9164782` - Improved claiming and execution
- `5286cef` - Region renaming finalization

## Lifecycle and endpoints (PandiO/knk-workspace#180)

As built on `claude/world-task-hardening` (knk-web-api, knk-plugin, knk-web-app), 2026-11-01. Design:
[DESIGN.md §8.2 and §8.7](../realtime-signalr/DESIGN.md); decisions Q10, Q11, Q17–Q19 (§12). WT2 (#181) adds the
SignalR offer ("Send to Minecraft" = auto-claim) on top of this; nothing here needs the hub.

### State machine (`WorldTaskStatuses`, enforced in `WorldTaskService`)

```
Pending ──claim──► InProgress ──complete──► Completed
   │                  ├──fail────────────► Failed
   │                  ├──release/lease───► Pending      (keeps its task code, fresh expiry)
   ├──cancel──────────┴─────────────────► Cancelled
   └──ExpiresAt passed──────────────────► Expired
```

- Every write is conditional on the status it read (concurrency token) and the row version: a second claimer, a
  complete after a cancel, a sweep after a heartbeat lose with **409** (`{code, message, status}` with the current status).
- **Claim** only from Pending. The same player (uuid) repeating it on the same server is idempotent and renews the
  lease. Claim modes: `code` (the API checks the task code), `id` (the game server checked `knk.tasks.any`),
  `headless` (gate and catalogue scans, no player), `offer` (#181, the task's `TargetUserId`).
- **Complete / fail** only from InProgress and only by the server holding the claim (when it sends `serverId`). A result
  the API refuses (validation, a gate scan that can't be applied) fails the task and answers **422** (was 500).
- **Task codes:** 6 characters A-Z0-9 from `RandomNumberGenerator`, unique among open tasks (retry on a clash). A
  lookup by code (`GET by-link-code/{code}`, case and dashes ignored) only finds open tasks: a closed task's code is dead.
- **Lifetimes** (section `WorldTasks`, all optional): `PendingTtlMinutes` 30, `LeaseMinutes` 3, `SweepIntervalSeconds`
  30, `SessionRetentionDays` 7, `SweepEnabled` true.
- **Sweep** (`WorldTaskSweepService`, every 30 s): Pending past `ExpiresAt` → Expired; InProgress past `LeaseUntil` →
  released to Pending; workflow sessions no draft points at and with no activity for 7 days → removed with their tasks,
  except sessions with a Completed task (its output is still read, e.g. a region's world) and catalogue-scan sessions.
  Rows from before #180 without `ExpiresAt`/`LeaseUntil` count from their last update.

### Endpoints (`api/WorldTasks`)

| Endpoint | Who | What |
|---|---|---|
| `POST /` | `knk.admin.world` or game server | create; the creator is the JWT caller (the session owner for the game server); body may name `formSubmissionProgressId`; a field's previous open task is cancelled |
| `GET {id}`, `GET by-link-code/{code}`, `GET status/{status}`, `GET session/{id}` | logged in or game server | reads (`by-link-code` finds open tasks only) |
| `GET session/{id}/open` | logged in or game server | the session's open tasks |
| `POST {id}/claim` | game server | `{taskCode, claimedByServerId, claimedByMinecraftUsername, claimedByUuid, claimMode}` |
| `POST {id}/complete`, `{id}/fail` | game server | `{outputJson \| errorMessage, serverId}` |
| `POST {id}/release` | game server | InProgress → Pending (in-game `cancel`, quit, restart, plugin disable) |
| `POST {id}/heartbeat` | game server | renews the lease (every 60 s); 409 = the task is no longer this server's |
| `GET open?serverId=` | game server | the tasks this server holds (resync after a restart) |
| `POST {id}/cancel` | `knk.admin.world` or game server | Pending/InProgress → Cancelled (`{reason}`) |
| `POST {id}/applied` | `knk.admin.world` or game server | the completed result is in the draft (`AppliedAt`) |
| `POST {id}/status` | `knk.admin.world` or game server | only known statuses and allowed transitions (nobody calls it) |
| `GET api/FormSubmissionProgress/{id}/world-tasks` | `knk.admin.content` | the latest task per field of a draft |

### Tasks anchored to the draft (DESIGN §8.7)

- One workflow session per draft (`FormSubmissionProgress.WorkflowSessionId`); resuming a draft reuses it. Child forms
  resume their own child draft's session the same way.
- The first world task of a form without a draft saves the draft silently (status InProgress, no message; the
  "Leave this form?" question stays, as after Next). The task stores `FormSubmissionProgressId`.
- On mount the field panel reattaches to its latest task: a waiting or claimed task is followed again; a task that
  completed while the form was closed fills the field, the draft is saved and the task is marked applied.
- Capture again / Try again / Start again reset the panel; an open task is cancelled. Leaving the form (Cancel, a link,
  closing a child form) cancels its open tasks; a reload doesn't, so the panel reattaches.
- The panel shows Pending (task code, `/knk task <code>`, expiry time, "Cancel task"), InProgress (claimed by, "Cancel
  task"), Completed, Failed ("Try Again"), Cancelled and Expired ("Start again"); polling stops once the task is closed.

### In game (knk-plugin)

- `/knk task <code>` (alias `/knk task-claim`; `/knk itemscan claim`, `/knk kitscan claim` too). By numeric id only with
  `knk.tasks.any` (not given to any rank by a seed). A claimed task whose type has no handler on the server is failed
  with the reason.
- In chat during a task: `cancel` hands it back (Pending, same code), `discard` cancels it for good.
- The server heartbeats every task it holds (`world-tasks.heartbeat-interval-seconds`, 60). A 409 (cancelled in the web
  app, released, taken over) stops the player's handler with a message. Quit, plugin disable and a restart hand the
  tasks back. The server id is `realtime.server-id` (default `localhost`).
- The headless poller claims a scan before running it, so two servers don't scan twice.
- Handler state is keyed by UUID; task chat is handled on the main thread.

The form builder offers only task types with a handler: `LocationSelection` (the default), `ReagionCreate` and
`RegionClaim` (on a `WgRegionId` field), `ItemScan`, `KitScan`, `GateBlockScan`, `GateOpenedBlockScan`.
