# spec/api/

API contracts and specifications for v2 services.

## Purpose
Define public API contracts (domain ports, DTOs, endpoints) that abstract the implementation from legacy.

## Contents
- `swagger.json`: OpenAPI 3.0 spec for Web API endpoints (if backend service exists).
- `health.yaml` / `health.json`: Per-endpoint OpenAPI schemas.
- `API_CONTRACT_STOCK.md`: stock core (`api/Storages`, `api/StockTransactions`), current for knk-web-api `next`.
- `API_CONTRACT_PRODUCTION_WORLD.md`: production world P2 (`api/Warehouses`, `api/ProductionStructures`, the structure placement fields and search, `InsideTerritory`, the game server's territory lookup), current for knk-web-api and knk-plugin `next`.
- `API_CONTRACT_PRODUCTION_ENGINE.md`: production engine P3 (`api/ProductionKinds`, `ProductionKindLevels`, `ProductionLines`, `ProductionModifiers`, `ClimateZones`, `WeatherTypes`, `ProductionCycleRecords`, `POST api/Production/run-now`, `ProductionStructures/{id}/production|workers|upgrade`, game setting `production.engine`), current for knk-web-api `next`.
- Port contracts: Interfaces in `knk-core` defining service boundaries.
- DTO schemas: Request/response shapes for each endpoint.

## Principles
- **Contract-first:** API defined before implementation.
- **Decoupled:** Core ports abstracted from Paper/HTTP details.
- **Versioned:** Changes tracked; backward compatibility noted.
- **Validated:** Schemas tied to unit tests.

## Audience
Backend engineers, API clients, frontend/plugin developers integrating with services.
