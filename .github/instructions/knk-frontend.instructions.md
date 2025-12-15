---
name: KnK Frontend Rules
applyTo: "Repository/knk-web-app/src/**/*.{ts,tsx}"
---

## DTO/type conventions
- Add DTO types in the existing DTO/types location used by the project.
- DTOs must match the API contract (names and fields).
- Prefer generated or shared types if the project already uses them; do not introduce a new approach.

## API client conventions
- All network calls go through the existing API client layer.
- Add CRUD functions for the new entity to the appropriate client module.
- Do not spread fetch/axios calls across UI components.

## UI conventions
- Reuse existing generic entity components (tables, detail views, form renderer) wherever possible.
- New custom components only if the generic framework cannot support the requirements.
- Avoid duplicating form logic; prefer FormConfig/DisplayConfig-driven rendering where applicable.
