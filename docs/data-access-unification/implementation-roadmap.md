# Unified Data Access Implementation Roadmap

## Phase 1 — Discovery and Design Finalization ✅ COMPLETE (January 17, 2026)

### Decisions Made

**Entity Coverage (Priority Order):**
1. **Users** (High Priority) - Pilot implementation, most critical for PlayerListener
2. **Towns, Districts, Structures** (High Priority) - Core gameplay entities
3. **Streets** (Medium Priority) - Less frequently accessed
4. **WorldTasks** (Medium Priority) - Hybrid workflow support, read-only initially
5. **Health** (Low Priority) - Minimal gateway, mostly pass-through
6. **Domains** (Deferred) - Not clearly defined in current spec; defer to Phase 4
7. **Locations** (Via Parent Entities) - Dependent entity; access via Towns/Districts/Structures initially

**Cache TTL Defaults:**
- Users: 15 minutes (max: 1 hour)
- Towns/Districts: 30 minutes (max: 4 hours)
- Structures: 20 minutes (max: 2 hours)
- Streets: 1 hour (max: 8 hours)
- WorldTasks: 5 minutes (max: 15 minutes)
- Health: 30 seconds (max: 2 minutes)

**Configuration Override Mechanism:**
1. Global defaults in CacheManager (hardcoded fallbacks)
2. Paper config (config.yml) overrides per entity type
3. Runtime overrides via per-call FetchPolicy parameters

**FetchPolicy Shape:**
- CACHE_ONLY - Only check cache; never hit API
- CACHE_FIRST - Check cache first; on miss, fetch from API and write-through
- API_ONLY - Always fetch from API; ignore cache for read, write-through on success
- API_THEN_CACHE_REFRESH - Fetch from API first; on failure try cache as fallback
- STALE_OK - Check cache first (even if stale); on API failure return stale if available

**FetchResult Shape:**
```kotlin
data class FetchResult<T>(
	val status: FetchStatus,        // HIT, MISS_FETCHED, NOT_FOUND, ERROR, STALE_SERVED
	val value: T?,
	val error: Throwable?,
	val isStale: Boolean = false,
	val source: DataSource          // CACHE, API, UNKNOWN
)
```

**Package Location:** `knk-core/src/main/kotlin/net/knightsandkings/core/dataaccess/`

**Async Contract Decision:**
- Primary API: Async (CompletableFuture)
- Optional sync wrappers with explicit "Blocking" suffix for async-safe contexts
- Clear documentation: "Never call sync methods on Paper main thread"

**Retry Policy (Optional):**
- Max attempts: 3
- Initial delay: 100ms
- Backoff multiplier: 2.0
- Max delay: 5000ms
- Retryable exceptions: SocketTimeoutException, ConnectException

## Phase 2 — Foundations
- Add shared types: FetchPolicy enum, FetchResult<T> (status, value, error, isStale flag).
- Add DataAccessExecutor helper that implements policy flow: tryCache, tryApi, writeThrough, stale fallback, metrics.
- Add simple RetryPolicy (optional, configurable attempts/backoff) reused by gateways.

## Phase 3 — Users Gateway (Pilot)
- Implement UsersDataAccess using UserCache + UsersQueryApi (+ UsersCommandApi for create/refresh when needed).
- Expose methods: getByUuid, getByUsername, getOrCreate(UserDetail seed), refresh, invalidate, invalidateAll.
- Integrate metrics/logging consistent with CacheManager.
- Update PlayerListener to use UsersDataAccess (async pre-login) and simplify logic.
- Add unit tests for UsersDataAccess (happy path, not found, API failure, stale fallback, invalidation).

## Phase 4 — Extend to Other Domains
- Implement gateways for Towns, Districts, Structures, Domains, Locations, Streets, WorldTasks, Health (read-only).
- Provide bulk fetch where API supports it; ensure cache.putAll is used.
- Wire gateways into CacheManager or a new GatewayProvider that consumes CacheManager + KnkApiClient.
- Add lightweight integration tests per gateway with API stubs.

## Phase 5 — Configuration and Observability
- Add configuration keys (paper config) for per-entity default policy, TTL, retry attempts, and stale-allowed toggle.
- Extend CacheManager to construct gateways with configured TTL and policies.
- Expose metrics via existing cache metrics logging and optionally a debug command.

## Phase 6 — Migration and Hardening
- Incrementally migrate listeners/commands/services to use gateways (PlayerListener first, then other consumers).
- Add background refresh hook for STALE_OK responses (execute on executor, avoid main thread).
- Document usage patterns and anti-patterns in docs; add code examples.
- Run performance smoke tests on dev server; validate cache hit rates and login latency.

## Definition of Done
- UsersDataAccess in production usage by PlayerListener with reduced custom logic.
- All gateways available and configurable; caches remain single source of truth for in-plugin reads.
- Tests passing: unit (gateways), integration (API stub + cache), manual smoke (login flow).
- Metrics/logging confirm cache-first behavior and safe fallbacks.
