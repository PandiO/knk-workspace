# WorldTask Feature Documentation

## Overview

The **WorldTask** feature enables administrators to capture Minecraft-specific data (world coordinates, regions, locations) directly from the game world while filling out creation/edit forms in the Knights & Kings web application. This bridges the gap between the web admin interface and in-game data collection through a claim-and-execute workflow.

## Key Concepts

### WorldTask
A task that captures world-bound data from a Minecraft player's current context. Each task:
- Is linked to a specific form field (e.g., `Location`, `WgRegionId`)
- Has a unique 6-character **LinkCode** for claiming in-game
- Can be claimed by a Minecraft player to collect data
- Transitions through states: `Pending` → `InProgress` → `Completed` (or `Failed`)
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
5. **Minecraft**: Admin joins the server and claims the tasks using `/worldtask claim {linkCode}`
6. **In-Game**: Admin executes the task:
   - For Location: Stand where you want and type `save` in chat
   - For WgRegionId: Define a region and type `save` in chat
7. **Web App**: Real-time polling detects task completion and updates the form
8. **Finalization**: Admin clicks "Create" to finalize the workflow and entity is created

## Architecture Layers

```
Web App Layer (knk-web-app)
├── TownCreateWizardPage & WizardStepContainer
├── TaskStatusMonitor (polling)
├── WorldBoundFieldRenderer
└── Workflow API Client

Web API Layer (knk-web-api-v2)
├── WorldTasksController (endpoints)
├── WorldTaskService (lifecycle management)
├── WorkflowService (workflow orchestration)
└── WorldTask Repository (data access)

Minecraft Plugin Layer (knk-plugin-v2)
├── WorldTaskHandlerRegistry (routing)
├── Task Handlers (IWorldTaskHandler implementations)
│   ├── WgRegionIdTaskHandler
│   └── LocationTaskHandler (new)
├── Chat Command Listeners
└── Event Listeners
```

## Commits Reference

Implementation across three repositories:

**knk-web-api-v2:**
- `3a64c0d` - Hybrid workflow with task integration (models, services, API)
- `b6fdad2` - WorldTask implementation (expanded controller, service logic)

**knk-web-app:**
- `324fc4b` - Multi-step wizard UI and task monitoring components
- `c5d3cf5`, `b7cdc4b` - Improvements and functional testing

**knk-plugin-v2:**
- `08bb1de` - WorldTask foundation (API client, DTO, commands, listeners)
- `a471b55` - WgRegionIdTaskHandler implementation
- `9164782` - Improved claiming and execution
- `5286cef` - Region renaming finalization

