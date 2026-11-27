# spec/api/

API contracts and specifications for v2 services.

## Purpose
Define public API contracts (domain ports, DTOs, endpoints) that abstract the implementation from legacy.

## Contents
- `swagger.json`: OpenAPI 3.0 spec for Web API endpoints (if backend service exists).
- `health.yaml` / `health.json`: Per-endpoint OpenAPI schemas.
- `API_CONTRACT_STOCK.md`: stock core (`api/Storages`, `api/StockTransactions`), current for knk-web-api `next`.
- `API_CONTRACT_LANDMARKS.md`: landmarks as a Domain subtype (#976: `api/landmarks`, the landmark parts of `api/Domains` with the `domainType` and `excludeSubtreeOf` search filters and the guarded writes, the `Landmark` discovery rule, warps and realtime type, the region task's `bounds`), current for knk-web-api `next`.
- `API_CONTRACT_ITEM_DELIVERY.md`: item delivery and the reward inbox P7 (`api/ItemDeliveries`, `api/Inbox` with claim, stash deposit/withdraw and sweep, the `InboxUpdated` notification, game settings `production.delivery`), current for knk-web-api `next`.
- `API_CONTRACT_HARVESTING.md`: player harvesting P8a (`api/HarvestRules` with the net-output check `balance`, `api/ResourcePools`, `api/PlayerHarvests`, `GET api/Harvest/catalog`, `POST api/Harvest/reports`, game settings `production.harvest`), current for knk-web-api `next`.
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
