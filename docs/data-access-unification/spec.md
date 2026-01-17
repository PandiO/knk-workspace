# Unified Data Access Spec

## Current State Analysis
- **Legacy DAL (knk-legacy-plugin / dal):** DAO + Repository layers provided policy-driven fetch (AUTO, ONLY_CACHE, ONLY_DAO) and write controls, with cache integration and generic managers. Provides patterns for policy enums, write-through, and validation.
- **Current Plugin (knk-plugin-v2):**
  - **Caches (knk-core/cache):** BaseCache/DomainCache with TTL, metrics, invalidate, putAll; concrete caches (UserCache, TownCache, DistrictCache, StructureCache).
  - **API Client (knk-api-client):** KnkApiClient exposes typed ports (UsersQueryApi, UsersCommandApi, etc.) using OkHttp + Jackson.
  - **Paper Layer (knk-paper):** CacheManager wires caches with TTL; PlayerListener manually orchestrates cache then API with repeated code.

## Proposed Architecture
- **DataAccessGateway (per domain):** A small service class per domain (e.g., UsersDataAccess) living in knk-core or knk-paper-core, injected with the domain cache and the corresponding API port(s).
- **FetchPolicy enum:** CACHE_ONLY, CACHE_FIRST, API_ONLY, API_THEN_CACHE_REFRESH, STALE_OK (serve stale if API fails), mirroring/modernizing legacy Repository.FetchMode.
- **Result wrapper:** `FetchResult<T>` with status (HIT, MISS_FETCHED, NOT_FOUND, ERROR), value (optional), and error cause. Avoid unchecked exceptions in listeners.
- **Async-first API:** Methods return `CompletableFuture<FetchResult<T>>`, with sync convenience wrappers where needed (blocking on async thread only).
- **Write-through behavior:** On API success, cache.put(key, value) respecting TTL. Bulk variants use cache.putAll.
- **Invalidation hooks:** invalidate(key), invalidateAll() delegating to cache; optional refresh(key) that re-fetches from API and updates cache.
- **Metrics integration:** Expose DomainCache metrics, plus per-gateway counters (hits, misses, stale-served, api-calls, failures). Log policy path at FINE level.
- **Config surface:** Default fetch policy and TTL provided by CacheManager config; allow per-call override.
- **Threading:** No blocking on Paper main thread. DataAccessGateway methods are async; sync wrappers must be used only on async events.

## Component Responsibilities
- **UsersDataAccess (pattern template):**
  - Dependencies: UserCache, UsersQueryApi, UsersCommandApi (for create/refresh when needed).
  - Methods: getByUuid(UUID, FetchPolicy), getByUsername(String, FetchPolicy), refreshByUuid(UUID), invalidate(UUID), invalidateAll().
- **Other domain gateways:** Towns, Districts, Structures, Domains, Locations, Streets, WorldTasks, Health (read-only). Each wired to matching cache + API port.
- **CacheManager extension:** Provide factory/getters for the new gateways or pass caches to a gateway factory (keeps cache lifecycle centralized).
- **Policy Engine:** Shared helper to execute policy steps: try cache (fresh), if miss then API, if API success then write-through, optionally return stale on error.

## Data and DTOs
- Reuse existing DTOs from knk-core domain (UserSummary, UserDetail, etc.).
- No new DTO schemas; mapping remains identical to API responses.

## Error and Resilience
- Timeouts: rely on KnkApiClient defaults; allow override per gateway via constructor parameter.
- Retries: optional simple retry for transient network errors (configurable attempt count, backoff).
- Fallback: When policy is STALE_OK and cache has stale data, serve it and schedule background refresh.
- Logging: WARN on API failures, INFO on cache miss + API fetch, FINE on cache hits; include UUID/keys for traceability.

## Sample Flow (Player login)
1. PlayerListener calls `usersDataAccess.getByUuid(uuid, CACHE_FIRST)` (async) on async pre-login thread.
2. If cache hit -> return FetchResult HIT; listener uses value.
3. If miss -> call UsersQueryApi -> on success cache.put and return MISS_FETCHED.
4. If API not found -> NOT_FOUND; listener may create user via UsersCommandApi or let gateway offer `getOrCreate` helper.
5. If API error and STALE_OK and stale entry exists -> return stale with status STALE_SERVED; log and optionally refresh in background.

## Testing Strategy (spec-level)
- Unit tests per gateway: cache hit, cache miss + API success, API 404 -> NOT_FOUND, API failure + stale fallback, invalidate and refresh.
- Concurrency test: simultaneous fetches return same cached value without duplicate API calls (dedupe optional but recommended).
- Integration test: wire KnkApiClient stub + real DomainCache to verify write-through.

## Deliverables
- FetchPolicy + FetchResult types.
- DataAccessGateway base helper (shared policy executor).
- UsersDataAccess implemented and adopted in PlayerListener as first consumer.
- Documentation and usage examples in docs folder.
