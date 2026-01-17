# BACKLOG API: Towns World Tasks

## Overview
This document outlines the necessary API extensions for managing towns within the PendingWorldBinding state and the associated WorldTask endpoints.

## Required API Extensions

### 1. Town Creation in PendingWorldBinding State
- **Endpoint**: `POST /towns`
- **Description**: Creates a new town in the PendingWorldBinding state.
- **Payload**:
  - `name`: string (required)
  - `description`: string (optional)
  - `wgRegionId`: string (optional)
  - `locationId`: integer (optional)

### 2. WorldTask Endpoints
- **Create Task**: `POST /worldtasks`
  - **Payload**: TBD
- **List Tasks**: `GET /worldtasks`
- **Claim Task**: `POST /worldtasks/{taskId}/claim`
- **Complete Task**: `POST /worldtasks/{taskId}/complete`
- **Fail Task**: `POST /worldtasks/{taskId}/fail`

### 3. Payloads for Plugin Outputs
- **wgRegionId**: string (only if mentioned in Swagger)
- **locationId**: integer (only if mentioned in Swagger)

### 4. Finalize Endpoint / Transition to Active
- **Endpoint**: `POST /towns/{townId}/finalize`
- **Description**: Finalizes the town and transitions it to the Active state.

### 5. Authentication and Roles
- **Access Control**: Admin only

## Notes
- All fields not explicitly defined are marked as TBD.
- Ensure compliance with existing API contracts and legacy systems where applicable.
