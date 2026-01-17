# Unified Data Access Requirements

## Purpose
Provide a consistent, cache-aware data access strategy for knk-plugin-v2 that minimizes repetitive code, prefers cache when possible, falls back to the Web API, and maintains alignment with existing core caches and API client.

## In-Scope
- Reads for player/user, towns, districts, structures, domains, locations, streets, world tasks (entities already exposed by KnkApiClient and caches).
- Cache-first, API-fallback retrieval with optional stale reads.
- Consistency controls (cache invalidation, refresh triggers) within plugin boundaries.
- Observability of cache hit/miss/error metrics.
- Error-handling and resilience (timeouts, retries where appropriate, degraded-mode behavior).

## Out-of-Scope (for now)
- Database persistence changes in the Web API.
- New entity types not already supported by knk-core caches or knk-api-client.
- Cross-service transactions or distributed locks.

## Functional Requirements
1. Provide a single entrypoint per domain (e.g., UsersDataAccess) that exposes cache-first API-fallback retrieval methods.
2. Support fetch policies: CACHE_ONLY, CACHE_FIRST, API_ONLY, API_THEN_CACHE_REFRESH, and STALE_OK (serve stale if fresh fails).
3. On API success, write-through to cache (respect TTL) and return the fresh value.
4. On cache hit, return immediately without API call (unless policy demands refresh).
5. Allow bulk fetches to reduce API chatter where endpoints exist.
6. Expose invalidation hooks: invalidate by key, invalidate all for domain.
7. Provide optional background refresh hook after serving stale data.
8. Provide typed results using existing domain DTOs (e.g., UserSummary/UserDetail) without new DTO schemas.
9. Provide consistent error surface: typed outcome (Success, NotFound, Error with cause), no unchecked exceptions leaking into listeners.
10. Safe for async/event threads: avoid blocking main thread; offer async variants (CompletableFuture).

## Non-Functional Requirements
- **Configurability:** Per-entity TTL and fetch policy defaults configurable via plugin config (paper layer), with defaults:
	- Users: 15min TTL, CACHE_FIRST
	- Towns/Districts: 30min TTL, CACHE_FIRST
	- Structures: 20min TTL, CACHE_FIRST
	- Streets: 1hr TTL, CACHE_FIRST
	- WorldTasks: 5min TTL, CACHE_FIRST
	- Health: 30sec TTL, API_ONLY

## Constraints and Standards
- Follow knk-core cache abstractions (BaseCache, DomainCache); no new heavy dependencies.
- All Web API access must go through KnkApiClient ports (HealthApi, UsersQueryApi, etc.).
- DTOs must remain aligned with shared contracts; avoid new schema definitions.
- Keep Bukkit/Paper-specific logic out of core data access components.
- Respect existing TTL semantics; do not bypass DomainCache expiration checks unless using STALE_OK.

## Acceptance Criteria
- Demonstrable example: PlayerListener login flow reduced to a single data-access call (cache-first, API fallback) with clear logging.
- Metrics show cache hits when player rejoins; cache miss followed by API hit when first seen.
- Unit tests cover: cache hit, cache miss with API success, API failure with stale allowed, invalidation behavior.
