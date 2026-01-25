# UsersDataAccess Quick Reference Guide

## Overview

`UsersDataAccess` is a cache-aware gateway for user retrieval in knk-plugin-v2. It provides a clean, async-first API that handles cache-first retrieval with automatic API fallback and write-through caching.

## Basic Usage

### 1. Initialize the Gateway

```java
// In your dependency injection or initialization code
UsersDataAccess usersDataAccess = new UsersDataAccess(
    userCache,           // UserCache instance
    usersQueryApi,       // UsersQueryApi port from KnkApiClient
    usersCommandApi      // UsersCommandApi port from KnkApiClient
);
```

### 2. Retrieve a User by UUID

```java
// Simple cache-first lookup (recommended for player login)
gateway.getByUuidAsync(uuid)
    .thenAccept(result -> {
        if (result.isSuccess()) {
            UserSummary user = result.value().orElseThrow();
            // Use user data...
        } else if (result.status() == FetchStatus.NOT_FOUND) {
            // Handle new player: create account
        } else {
            // Handle API error: log warning, use stale if available
        }
    })
    .exceptionally(e -> {
        logger.error("Unexpected error fetching user", e);
        return null;
    });

// With explicit fetch policy
gateway.getByUuidAsync(uuid, FetchPolicy.API_ONLY)
    .thenAccept(result -> { /* ... */ });
```

### 3. Retrieve a User by Username

```java
// Note: Always hits API (cache is UUID-keyed), but caches result by UUID
gateway.getByUsernameAsync("PlayerName")
    .thenAccept(result -> {
        if (result.isSuccess()) {
            UserSummary user = result.value().orElseThrow();
            // Can now use UUID for faster future lookups
        }
    });
```

### 4. Get or Create User

```java
// Create user if not found
UserDetail seed = new UserDetail(
    0,              // id (auto-generated on creation)
    "Player123",    // username
    uuid,           // uuid
    "player@example.com", // email
    250,            // initial coins
    new Date()      // createdAt
);

gateway.getOrCreateAsync(uuid, true, seed)
    .thenAccept(result -> {
        UserSummary user = result.value().orElseThrow();
        // User now guaranteed to exist in system
    });
```

### 5. Refresh User Data

```java
// Force fresh fetch from API, bypassing cache
gateway.refreshAsync(uuid)
    .thenAccept(result -> {
        UserSummary fresh = result.value().orElseThrow();
        // User data updated with latest from API
    });
```

### 6. Cache Invalidation

```java
// Invalidate single user
gateway.invalidate(uuid);

// Clear all cached users
gateway.invalidateAll();
```

## Result Handling

Each method returns a `CompletableFuture<FetchResult<UserSummary>>`:

```java
FetchResult<UserSummary> result = future.get();

// Check status
FetchStatus status = result.status();
// Possible values:
// - HIT: Fresh cache hit
// - MISS_FETCHED: Cache miss, fetched from API
// - NOT_FOUND: Not in cache or API (404)
// - ERROR: API call failed
// - STALE_SERVED: Stale cache returned due to API failure

// Get value safely
Optional<UserSummary> user = result.value();

// Check source
DataSource source = result.source(); // CACHE, API, or UNKNOWN

// Check if successful
boolean success = result.isSuccess();

// Check if stale
boolean isStale = result.isStale();
```

## Real-World Example: Async Player Login

```java
@EventHandler
public void onAsyncPlayerPreLogin(AsyncPlayerPreLoginEvent event) {
    UUID uuid = event.getUniqueId();
    String username = event.getName();
    
    usersDataAccess.getByUuidAsync(uuid)
        .thenAccept(result -> {
            if (result.isSuccess()) {
                // Player exists
                UserSummary user = result.value().orElseThrow();
                cachePlayerSession(uuid, user);
                
            } else if (result.status() == FetchStatus.NOT_FOUND) {
                // New player - create account
                UserDetail newUser = new UserDetail(
                    0, username, uuid, null, 250, new Date()
                );
                usersDataAccess.getOrCreateAsync(uuid, true, newUser)
                    .thenAccept(createResult -> {
                        UserSummary created = createResult.value().orElseThrow();
                        cachePlayerSession(uuid, created);
                    });
                    
            } else {
                // API error - log and allow connection with degraded experience
                logger.warn("Failed to fetch user {}: {}", uuid, result.status());
                allowLoginWithoutUserData(uuid);
            }
        })
        .exceptionally(e -> {
            logger.error("Unexpected error during user fetch", e);
            event.disallow(AsyncPlayerPreLoginEvent.Result.KICK_OTHER, 
                "Server error connecting account");
            return null;
        });
}
```

## Fetch Policies

Available fetch policies (from Phase 2):

| Policy | Behavior |
|--------|----------|
| **CACHE_FIRST** (default) | Try cache first; on miss, fetch from API; on error return error |
| **CACHE_ONLY** | Only check cache; never hit API; return NOT_FOUND on miss |
| **API_ONLY** | Always fetch from API; ignore cache for read |
| **API_THEN_CACHE_REFRESH** | Fetch from API first; on error try stale cache as fallback |
| **STALE_OK** | Try cache first; on API error return stale data if available |

```java
// Example: Use stale data as fallback
gateway.getByUuidAsync(uuid, FetchPolicy.STALE_OK)
    .thenAccept(result -> {
        if (result.status() == FetchStatus.STALE_SERVED) {
            logger.info("Served stale user data for {}", uuid);
            // Schedule background refresh
            scheduledExecutor.schedule(
                () -> gateway.refreshAsync(uuid),
                5, TimeUnit.SECONDS
            );
        }
    });
```

## Performance Characteristics

| Operation | Cache Hit | Cache Miss | Not Found |
|-----------|-----------|-----------|-----------|
| getByUuidAsync (CACHE_FIRST) | <1ms | ~50-200ms | ~50-200ms |
| getByUsernameAsync | N/A (always API) | ~50-200ms | ~50-200ms |
| refreshAsync | N/A (bypasses) | ~50-200ms | ~50-200ms |

## Best Practices

1. **Use CACHE_FIRST for player login** - Minimizes latency for returning players
2. **Handle NOT_FOUND explicitly** - Create account or kick with message
3. **Never block main thread** - Always use async methods in event handlers
4. **Cache invalidate on updates** - If user data changes server-side, invalidate cache
5. **Log errors appropriately** - Help debugging with clear error messages
6. **Test with stub APIs** - Use StubUsersQueryApi for unit tests (provided in test file)

## Testing

```java
@Test
void testPlayerLogin_CacheHit() throws Exception {
    // Pre-populate cache
    cache.put(expectedUser);
    
    // Fetch should return immediately
    FetchResult<UserSummary> result = 
        gateway.getByUuidAsync(uuid).get();
    
    assertEquals(FetchStatus.HIT, result.status());
    assertEquals(expectedUser, result.value().orElseThrow());
}
```

## Troubleshooting

**Q: My getByUsernameAsync is not using the cache?**  
A: Username lookups intentionally always hit the API because the cache is UUID-keyed. After the first lookup, future UUID-based lookups will be cached.

**Q: How do I force a fresh fetch?**  
A: Use `refreshAsync(uuid)` which enforces `API_ONLY` policy, or call `getByUuidAsync(uuid, FetchPolicy.API_ONLY)`.

**Q: When should I use STALE_OK?**  
A: Use for non-critical operations where serving outdated data is acceptable (e.g., leaderboard display) if the API is temporarily unavailable.

**Q: Can I customize TTL?**  
A: TTL is configured per cache instance when constructing `UserCache`. Phase 4 will add Paper config support for runtime configuration.

## See Also

- [Phase 3 Implementation Summary](./PHASE_3_IMPLEMENTATION_COMPLETE.md)
- [Implementation Roadmap](./implementation-roadmap.md)
- [Requirements](./requirements.md)
- [Spec](./spec.md)
