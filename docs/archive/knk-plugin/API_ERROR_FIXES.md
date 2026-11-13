# API Error Fixes - Region Enter/Exit System

**Status:** Stale · **Last updated:** 2026-11-13 (moved into knk-workspace, PandiO/knk-workspace#304)
**Moved from:** `knk-plugin/docs/API_ERROR_FIXES.md` at `b8aa582f7a` ([source](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/docs/API_ERROR_FIXES.md)); the text below is unchanged apart from links.
**Note:** Fix report for the region enter/exit lookups while the API is down; the current outage behaviour is in [offline security cache](../../architecture/offline-security-cache.md) and [API connectivity](../../architecture/api-connectivity.md).


## Problem

When the plugin starts, it attempts to resolve WorldGuard region IDs to domain entities (Towns, Districts, Structures) by calling the backend API. The logs showed:

```
[23:31:28 WARN]: Failed to resolve structure for WG region town_1: net.knightsandkings.knk.core.exception.ApiException: API error [0]: IO error during search structures
[23:31:28 WARN]: Failed to resolve district for WG region district_1000004: net.knightsandkings.knk.core.exception.ApiException: API error [0]: IO error during search districts
[23:31:28 WARN]: Failed to resolve town for WG region town_1: net.knightsandkings.knk.core.exception.ApiException: API error [0]: IO error during search towns
```

### Root Cause

The backend API server at `http://localhost:5294/api` is **not running or unreachable**. The plugin's region enter/exit system depends on this API to:
1. Resolve WG region IDs → entity metadata (names, allowEntry, allowExit flags)
2. Determine message priority and entry denial rules

When API calls fail, the system was **suppressing player movement decisions**, waiting indefinitely for metadata that would never arrive.

## Fixes Applied

### 1. **Failed Lookup Tracking** ([WorldGuardRegionTracker.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/java/net/knightsandkings/knk/paper/regions/WorldGuardRegionTracker.java))

Added a cooldown mechanism to avoid hammering a down API:

```java
private final Map<String, Long> failedRegionLookups = new ConcurrentHashMap<>();
private static final long FAILED_LOOKUP_COOLDOWN_MS = 5000;  // 5 second cooldown

private void recordFailedLookup(Set<String> regionIds) {
    long now = System.currentTimeMillis();
    for (String id : regionIds) {
        failedRegionLookups.put(id, now);
    }
}
```

**Behavior**: After an API call fails for a region, don't retry for 5 seconds.

### 2. **Graceful Fallback on API Failures** ([WorldGuardRegionTracker.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/java/net/knightsandkings/knk/paper/regions/WorldGuardRegionTracker.java))

Modified `handleMove()` to allow player movement even if metadata isn't cached:

```java
if (needsLookup) {
    // ... start async prefetch ...
    
    // Still allow movement even if metadata isn't cached yet (fallback behavior)
    if (logger != null) {
        logger.info("[KnK Tracker] " + player.getName() + " allowing movement (metadata fetch in progress)");
    }
    return null;  // Allow movement without messages
}
```

**Behavior**:
- Players can move freely through regions
- No entry/exit messages are displayed (messages require cached metadata)
- Entry/exit denials are not enforced (allowEntry/allowExit checks skipped)
- After 5 seconds, the system will retry the API call

### 3. **Better Error Tracking in Async Lookup**

The async prefetch now properly tracks when lookups fail:

```java
try {
    regionResolver.resolveRegionsFromApi(lookupIds).get();  // Block until complete
    // ...
} catch (Exception ex) {
    if (logger != null) {
        logger.severe("[KnK Tracker] " + player.getName() + " async prefetch FAILED: " + ex.getMessage());
    }
    recordFailedLookup(lookupIds);  // Mark as failed to avoid retry spam
}
```

## Configuration Issue

The plugin is configured to connect to:

**[knk-paper/src/main/resources/config.yml](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/resources/config.yml)**:
```yaml
api:
  base-url: "http://localhost:5294/api"
```

### To Fix This Issue

**Option 1**: Start the backend API server on port 5294
- The backend must be running and listening at `http://localhost:5294/api`
- Endpoints needed:
  - `POST /api/Towns/search`
  - `POST /api/Districts/search`
  - `POST /api/Structures/search`

**Option 2**: Update the config to point to a running API
- Change `base-url` in config.yml to your actual API endpoint
- Restart the plugin

**Option 3**: Use stub API responses (for testing/development)
- Mock the HTTP responses if you don't have a backend running

## Current Behavior After Fixes

| Scenario | Behavior |
|----------|----------|
| **API running** | Region messages display normally; entry denials enforced |
| **API down (first call)** | Player can move; no messages; API retry scheduled |
| **API down (within 5 sec)** | Player can move; no messages; no API retry (cooldown active) |
| **API down (after 5 sec)** | Player can move; no messages; API retry attempted again |
| **Intermittent API failures** | Graceful degradation; no player movement blocking |

## Migration: API-Backed Region Resolution

The system design follows the migration mode requirement:
- **READ-ONLY**: Only calls GET/POST search endpoints (no mutations)
- **Async**: All API calls run on dedicated executor, never on main thread
- **Resilient**: Handles network failures gracefully
- **Fallback**: Allows gameplay even if metadata isn't available

### Future Enhancements

1. **Pre-cache regions on startup**: Load all active regions before players join
2. **Batch API requests**: Group multiple region lookups into fewer API calls
3. **Long-lived cache**: Persist cached metadata across server restarts
4. **Health checks**: Periodically check API availability; log warnings if down
5. **Configurable fallback behavior**: Allow server admins to choose:
   - Deny all movement if API is unavailable
   - Allow all movement with partial enforcement
   - Cache-only mode (no API calls)

## Testing Checklist

- [ ] Start plugin with API down → no errors in console, players can move
- [ ] Start plugin with API running → region messages appear when entering/exiting
- [ ] Kill API mid-game → players continue playing without messages
- [ ] Restart API → messages resume on next region transition
- [ ] Test entry denial (allowEntry=false) with API running
- [ ] Test exit denial (allowExit=false) with API running

## Related Files

- [WorldGuardRegionListener.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/java/net/knightsandkings/knk/paper/listeners/WorldGuardRegionListener.java) - Event listener
- [WorldGuardRegionTracker.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/java/net/knightsandkings/knk/paper/regions/WorldGuardRegionTracker.java) - Region tracking and API calls
- [RegionDomainResolver.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-core/src/main/java/net/knightsandkings/knk/core/regions/RegionDomainResolver.java) - Entity resolution and caching
- [SimpleRegionTransitionService.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-core/src/main/java/net/knightsandkings/knk/core/regions/SimpleRegionTransitionService.java) - Message logic
- [config.yml](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/resources/config.yml) - Configuration
