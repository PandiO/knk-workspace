# ADR: Towns Implementation Plan (Vertical Slice)

**Status:** Superseded (proposed 2025-12-14; towns, world tasks and the hybrid create flow were since built, see [docs/specs/towns](../../specs/towns/) and [docs/specs/world-tasks](../../specs/world-tasks/)) · **Last updated:** 2026-11-13 (moved into knk-workspace, PandiO/knk-workspace#304)

_Moved from `knk-plugin/docs/adr/ADR_TOWNS_IMPLEMENTATION.md` at `b8aa582f7a` ([source](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/docs/adr/ADR_TOWNS_IMPLEMENTATION.md)). The text below is unchanged apart from links; it was not rewritten._


Date: 2025-12-14
Status: Proposed

Source inputs:
- spec/reconcile/RECONCILE_TOWNS.md (data/flow/logic mapping)
- spec/api/API_CONTRACT_TOWNS.md (+ swagger.json)
- spec/SPEC_TOWNS.md (Hybrid Create Flow)
- spec/LOGIC_CANDIDATES_TOWNS.md

## MVP Scope (Now)
**READ-only**: Town/District/Street/Structure list/get/search via API client; Paper commands for display only.

**Out of scope**: Create/Update/Delete, WorldTasks, WorldBinding (region+location), CreationStages, ownership/permissions.

---

## Decision Summary

- Start with a **READ-only vertical slice** for Towns: list and get by id.
- Target create architecture is **hybrid**: API create → PendingWorldBinding → WorldTask → plugin executes world-bound steps → API finalize → Active.
- Define missing API endpoints/backlog for create and world tasks.
- Plugin scope for the first iteration is minimal: **no create UI** or blocking flows; focus on read, and prepare scaffolding for world task execution.

---

## Phase 1: Vertical Slice — READ Only (Towns)

**Scope**:
- Implement API client calls for Towns:
  - `GET /api/Towns` (list)
  - `GET /api/Towns/{id}` (details)
  - `POST /api/Towns/search` (paged list)
- Render in Paper plugin: admin/debug command to list towns and show details.

**Rationale**:
- Swagger endpoints exist and are sufficient for read operations.
- Validates project structure (core ⇄ api-client ⇄ paper) without touching world-bound flows.
- Low-risk entry into the vertical.

**Acceptance**:
- Paper command `knk towns list` shows list (name, wgRegionId when present).
- Paper command `knk towns get <id>` shows details including `location` (if present) and linked streets/districts (if included by API).

---

## Target Architecture: Hybrid Create Flow

As summarized in spec/SPEC_TOWNS.md (Part B.1) and spec/CREATE_FLOW_SPLIT_TOWNS.md.

**Per entity (Town, District, Structure):**
1. **API Create**: POST with business fields only (e.g., `name`, `description`, `allowEntry`, FKs), return entity with `wgRegionId=null`, `locationId=null` and status PendingWorldBinding.
2. **WorldTask**: Create coordination record for world-bound execution (region + location binding).
3. **Plugin Execute**: Create WorldGuard region and capture Minecraft location.
   - Outputs: `wgRegionId` (WorldGuard region id), `locationId`.
4. **API Finalize**: PUT to update entity with `wgRegionId` and `locationId`, set status Active.

Street creation is API-only (no world-bound outputs) until clarified otherwise.

---

## API Backlog: Missing/Needed Endpoints

Based on spec/api/API_CONTRACT_TOWNS.md and swagger.json:

- **WorldTask endpoints** (NOT IN CONTRACT):
  - `POST /api/WorldTasks` (create task for entity world-binding)
  - `GET /api/WorldTasks?status=Pending` (polling)
  - `PUT /api/WorldTasks/{id}/complete` (report results: `wgRegionId`, `locationId`)

- **Finalize endpoints** (contract re-use or clarify):
  - Use existing `PUT /api/Towns/{id}` / `PUT /api/Districts/{id}` / `PUT /api/Structures/{id}` to supply `wgRegionId` + `locationId`.
  - If a dedicated finalize route is preferred, add:
    - `POST /api/Towns/{id}/finalize`
    - `POST /api/Districts/{id}/finalize`
    - `POST /api/Structures/{id}/finalize`
  - Status field for lifecycle (PendingWorldBinding → Active): NOT IN CONTRACT; needs addition or implicit handling.

- **Location persistence** (optional convenience):
  - `POST /api/Locations` to create and return `LocationDto`/`id` (NOT IN CONTRACT).
  - Alternatively, embed location data in the entity PUT.

- **Include-field toggles**:
  - District GET supports `townFields`, `streetFields`, `structureFields` query params (observed). Clarify usage/document allowed values.

- **Roles/Permissions**:
  - Roles endpoints are NOT IN CONTRACT for Towns vertical; defer.

---

## Plugin Scope (Non-Goals for Initial Slice)

- **No create flows in plugin**: No interactive CreationStages; no blocking I/O.
- **No WorldGuard region creation yet**: World-bound steps will be implemented after API world task model exists.
- **No Location persistence yet**: Avoid write calls until finalize pathway is defined.
- **No ownership/permission model**: Out of scope; not present in current swagger for this vertical.

---

## Implementation Notes

- Maintain architectural rules: core services no Bukkit/Paper; api-client implements ports; paper only adapter.
- All HTTP calls must be async via CompletableFuture and dedicated ExecutorService.
- Error handling per ApiException guidelines.

---

## Next Steps

1. Implement API client methods for Towns list/get/search.
2. Add minimal Paper commands to display results.
3. Draft API spec for WorldTask endpoints (server-side backlog).
4. Prepare plugin WorldTask executor scaffold (no-op until endpoints exist).

---

## Risks & TBDs

- `allowExit` semantics (present in DTOs, not in legacy): clarify usage.
- Status field for lifecycle (PendingWorldBinding/Active): add to contract or treat implicit.
- Street world-binding: confirm if required in v2.
- Region overlap policy: define for plugin execution.
