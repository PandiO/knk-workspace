---
name: KnK Backend Rules
applyTo: "Repository/knk-web-api-v2/**/*.cs"
---

## Folder + naming conventions
- Repositories go in: Repository/knk-web-api-v2/Repositories
- Repository interfaces go in: Repository/knk-web-api-v2/Repositories/Interfaces
- Services go in: Repository/knk-web-api-v2/Services
- Service interfaces go in: Repository/knk-web-api-v2/Services/Interfaces
- AutoMapper profiles go in: Repository/knk-web-api-v2/Mapping
- Controllers go in the existing Controllers folder used by the project

## DTO conventions
- Provide: {Entity}ReadDto, {Entity}CreateDto, {Entity}UpdateDto
- Provide Navigation DTOs for relationships to avoid circular references and heavy joins:
  - {RelatedEntity}NavDto with only required primitive/display fields
- Never return EF entities directly from controllers.

## Service vs repository responsibilities
- Repository: data access (query shaping, includes, persistence), no business rules.
- Service: business rules, cascade create/update behavior, validation, orchestration.

## AutoMapper
- Add mappings for all DTOs.
- Keep mapping rules consistent with the reference entity patterns.

## Controllers
- Use the existing controller patterns (routing, status codes, validation, error handling).
- Keep endpoints consistent with existing naming conventions.
- Ensure related entities are handled according to cascade rules described by the user or mirrored from reference entities.

## Metadata
- Ensure entities that must be manageable from the web app have EntityMetadata annotations required by FormConfig/DisplayConfig features.
## WorldTask Integration Pattern
When a feature involves Minecraft-captured data (e.g., Location coordinates) via WorldTasks:

1. **Plugin Layer**: Capture raw data (e.g., coordinates) and send as JSON output.
2. **Workflow Coordination**: `WorkflowService.FinalizeAsync()` validates all workflow steps are complete but does NOT create related entities.
3. **Entity Services**: Extract task output data using `WorkflowService.ExtractLocationDataFromTaskOutput()` (or similar) ONLY when creating/updating the parent entity.
4. **Database**: Related entities (Location, etc.) are persisted ONLY when the parent entity is successfully created.

**Rationale**: Prevents orphaned records from abandoned workflows. Location data remains ephemeral in `WorldTask.OutputJson` until the complete workflow is finalized and the parent entity is created.