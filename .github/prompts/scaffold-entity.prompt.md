---
name: scaffold-entity
description: "Scaffold a new entity across API + Web App following KnK conventions"
argument-hint: "entity=District reference=Town relations='many-to-one:Town' cascade='create:Street|update:District'"
---

You are implementing a full entity scaffold for Knights & Kings.

Inputs:
- Entity name: ${input:entity}
- Reference entity to mimic: ${input:reference:Town}
- Relations: ${input:relations}
- Cascade rules: ${input:cascade}

Hard requirements:
- Follow .github/copilot-instructions.md and docs/ai/ENTITY_SCAFFOLD_CHECKLIST.md
- Reuse existing patterns by cloning the reference entity approach.

In Repository/knk-web-api-v2:
1) Create DTOs:
   - {Entity}ReadDto, {Entity}CreateDto, {Entity}UpdateDto
   - Navigation DTOs for related entities (avoid circular refs; only include necessary primitive fields)
2) Create repository + interface in the established folders.
3) Create service + interface, implement cascade behavior per rules above.
4) Add AutoMapper mapping profile in Mapping folder.
5) Add controller with CRUD endpoints following existing conventions.
6) Add/extend EntityMetadata annotations to enable FormConfig/DisplayConfig.

In Repository/knk-web-app:
1) Add matching DTO types in the existing DTO/types location.
2) Extend the API client layer with CRUD functions for this entity.
3) Reuse the generic UI/form framework; add minimal glue code only where required.

Deliverable:
- Implement all files and wiring changes required so the solution compiles.
- If any detail is ambiguous, choose the smallest reasonable assumption and leave a TODO comment in code.
