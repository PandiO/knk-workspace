# Unified Data Access Implementation Roadmap

## Phase 1 — Discovery and Design Finalization
- Confirm entity coverage: users, towns, districts, structures, domains, locations, streets, world tasks, health checks.
- Review knk-core cache TTL defaults and CacheManager configuration surface; define per-entity defaults and override mechanism.
- Finalize FetchPolicy and FetchResult shape; decide on package location (knk-core dataaccess?).
- Decide on async contract (CompletableFuture) and whether sync adapters are needed.

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
