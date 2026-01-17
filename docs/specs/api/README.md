# spec/api/

API contracts and specifications for v2 services.

## Purpose
Define public API contracts (domain ports, DTOs, endpoints) that abstract the implementation from legacy.

## Contents
- `swagger.json`: OpenAPI 3.0 spec for Web API endpoints (if backend service exists).
- `health.yaml` / `health.json`: Per-endpoint OpenAPI schemas.
- Port contracts: Interfaces in `knk-core` defining service boundaries.
- DTO schemas: Request/response shapes for each endpoint.

## Principles
- **Contract-first:** API defined before implementation.
- **Decoupled:** Core ports abstracted from Paper/HTTP details.
- **Versioned:** Changes tracked; backward compatibility noted.
- **Validated:** Schemas tied to unit tests.

## Audience
Backend engineers, API clients, frontend/plugin developers integrating with services.
