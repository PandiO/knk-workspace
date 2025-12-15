# Knights & Kings – Copilot Workspace Instructions

## Objective
Help implement Knights & Kings features by extending the existing architecture across:
- Repository/knk-web-api-v2 (.NET Web API)
- Repository/knk-web-app (React/TypeScript web app)
- Repository/knk-plugin-v2 (Minecraft plugin)

## Global rules (apply always)
- Prefer existing patterns. Before creating anything new, locate a “reference implementation” in the codebase and follow it.
- Do not invent new architectural layers, naming schemes, or folder structures unless explicitly requested.
- Keep changes minimal and incremental: add only what is required for the requested feature.
- Avoid duplicate code: reuse existing generic components/utilities/services whenever possible.
- When unsure, make the smallest reasonable assumption and add a short TODO in code rather than stalling.

## Entity scaffolding rule
When the user says: “I created the model/entity, now scaffold the rest”
you must implement the full scaffold using:
- docs/ai/ENTITY_SCAFFOLD_CHECKLIST.md

Deliverable must include:
- API DTOs + Navigation DTOs (no circular refs)
- Repository + interface
- Service + interface (including cascade rules where applicable)
- AutoMapper mapping profile
- Controller CRUD endpoints
- EntityMetadata annotations (for FormConfig/DisplayConfig)
- Web app DTO/types + API client wiring
- Reuse existing generic UI (forms/lists/details) where applicable

## Search strategy
- First, find a similar entity that already has the full pipeline (DTOs, mapping, repo/service, controller, webapp types).
- Copy the pattern and adapt it; keep conventions consistent.
