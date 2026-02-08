# Phase 1 Commit Messages: Placeholder Resolution Implementation

**Feature:** interpolation-strategy  
**Phase:** 1 - Backend Placeholder Resolution API  
**Completion Date:** February 7, 2026

---

## knk-web-api-v2

**Subject:** `feat(validation): implement placeholder resolution api`

**Description:**
```
Add backend API for resolving validation message placeholders across
multiple entity navigation layers to support dynamic form validation
feedback and WorldTask message interpolation.

This phase implements Task A from the placeholder-resolution spec,
enabling the system to resolve placeholders like {Name}, {Town.Name},
and {District.Town.Name} for use in validation error/success messages
across the web app and Minecraft plugin.

Components added:
- PlaceholderResolutionService: core service implementing 4-layer
  resolution strategy (Layer 0: direct props, Layer 1: single nav,
  Layer 2: multi-level nav, Layer 3: aggregates like .Count)
- IPlaceholderResolutionService: service interface contract
- ResolvePlaceholdersRequestDto: request model with currentEntityType,
  currentEntityId, placeholderPaths, and currentEntityPlaceholders
- ResolvePlaceholdersResponseDto: response model with resolvedPlaceholders
  map, unresolvedPlaceholders list, and resolutionErrors for debugging
- POST /api/field-validation-rules/resolve-placeholders: controller
  endpoint with input validation and error handling
- Dependency injection registration for scoped service lifetime

Technical approach:
- Uses reflection to discover entity types from DbContext at runtime
- Builds dynamic LINQ queries via Expression trees and MakeGenericMethod
- Resolves single navigation via FK lookups from current entity
- Resolves multi-level navigation via dynamic EF Include chains
- Supports collection aggregates (Count) on navigation properties
- Returns templates with unresolved placeholders map for point-of-use
  interpolation (web app or plugin)

Why this design:
Backend resolves DB-dependent values but does not interpolate, allowing
each consumer (FormWizard, Minecraft plugin) to format messages for
their own context (HTML, chat codes) while maintaining consistency.

Build: verified successful compilation with dotnet build
Next: Phase 2 - FormWizard integration for placeholder extraction

Related: docs/specs/form-validation/implementation-prompts/
placeholder-resolution-implementation-prompt.md
```

---

## knk-web-app

**Subject:** `feat(validation): add placeholder resolution dtos and client`

**Description:**
```
Add TypeScript DTOs and API client method for placeholder resolution
to enable frontend integration with backend placeholder resolution API.

This phase implements the frontend foundation for Task C from the
placeholder-resolution spec, preparing for FormWizard to resolve
navigation placeholders before creating WorldTasks.

Components added:
- ResolvePlaceholdersRequestDto: TypeScript interface matching backend
  request model with currentEntityType, currentEntityId, placeholderPaths,
  and currentEntityPlaceholders fields
- ResolvePlaceholdersResponseDto: TypeScript interface matching backend
  response model with resolvedPlaceholders, unresolvedPlaceholders, and
  resolutionErrors fields
- FieldValidationRuleOperation.ResolvePlaceholders: enum value for
  operation routing
- fieldValidationRuleClient.resolvePlaceholders(): API client method
  wrapping POST /api/field-validation-rules/resolve-placeholders call

Why these changes:
These DTOs and client method establish type-safe contracts between
frontend and backend for placeholder resolution, ensuring proper data
flow when FormWizard needs to resolve navigation placeholders like
{Town.Name} or {District.Town.Name} before creating WorldTasks.

Usage will be in FormWizard to:
1. Extract Layer 0 placeholders from form data (buildPlaceholderContext)
2. Parse placeholder paths from validation rule messages (regex {…})
3. Call resolvePlaceholders() to get navigation values
4. Merge resolved placeholders into WorldTask InputJson

Build: verified TypeScript types compile successfully
Next: Phase 2 - actual FormWizard integration with placeholder extraction

Related: docs/specs/form-validation/implementation-prompts/
placeholder-resolution-implementation-prompt.md
```

---

## docs

**Subject:** `docs(validation): add placeholder resolution spec and analysis`

**Description:**
```
Add comprehensive documentation for placeholder variable interpolation
strategy and implementation guidance for form validation messages.

This documentation provides the foundation for implementing placeholder
resolution across the web app, backend API, and Minecraft plugin,
ensuring consistent behavior in validation feedback.

Documents added:
- PLACEHOLDER_INTERPOLATION_STRATEGY.md: analysis of where and when to
  interpolate placeholders, comparing three design options and selecting
  dual strategy (backend prepares, point-of-use interpolates) for
  separation of concerns
- placeholder-resolution-implementation-prompt.md: actionable tasks
  (A-E) for implementing 4-layer placeholder resolution with acceptance
  criteria and API contracts
- PHASE_1_IMPLEMENTATION_COMPLETE.md: completion report documenting all
  Phase 1 deliverables with technical implementation details, API
  contract examples, and next steps

Why this documentation:
The interpolation strategy doc establishes the architectural decision
to have backend return templates + placeholder maps rather than
interpolated messages, enabling each consumer (web app, plugin) to
format for their context. The implementation prompt breaks down the
work into concrete tasks across backend, frontend, and plugin. The
completion report provides evidence of successful Phase 1 delivery
and guides Phase 2 development.

Key decisions documented:
- Layer 0: direct entity properties (frontend extracts from form data)
- Layer 1: single navigation (backend resolves via FK lookup)
- Layer 2: multi-level navigation (backend uses dynamic EF Include)
- Layer 3: aggregates (backend supports .Count on collections)
- Point-of-use interpolation strategy for formatting flexibility

Next: Phase 2 - FormWizard integration using these documented patterns

Related: docs/specs/form-validation/ (parent directory)
```

---

## Summary

**Repositories with changes:**
- ✅ knk-web-api-v2 (backend placeholder resolution service + API)
- ✅ knk-web-app (frontend DTOs + API client)
- ✅ docs (strategy analysis + implementation spec)
- ⏸️ knk-plugin-v2 (no changes in Phase 1)

**Phase 1 scope:** Backend Placeholder Resolution API (Task A)

**Next phase:** FormWizard Integration (Tasks C, D)
