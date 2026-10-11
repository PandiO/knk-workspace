# API connectivity (plugin ↔ knk-web-api)

**Status:** Live · **Last updated:** 2026-10-11 — merged after a developer live test
([KNG-115](https://linear.app/kngpandi/issue/KNG-115)): knk-web-api `master` `17ee730`, knk-plugin
`main` `b5eee6e`. All decisions below were accepted by the developer on 2026-10-11.

## What decides "the API is up"

1. **API readiness** — `GET /health/ready` (`Controllers/HealthCheckController.cs`) runs every
   registered health check: `self` (always healthy) and `database`
   (`Services/DatabaseHealthCheck.cs`, EF Core `CanConnectAsync` on `KnKDbContext`, resolved
   inside the check so a DbContext that can't be built reads as unhealthy; tag `ready`, 3 s
   timeout). 200 for `healthy`/`degraded`, 503 for `unhealthy` (also when the check service
   throws). The body is PascalCase (`"Status"`, `"Checks"`, `"Version"`). `GET /health/live` runs
   no checks (process only). `GET /api/Health` (`HealthController`) still exists, process only;
   nothing in the plugin uses it any more.
   Logging: the controller logs once when readiness changes (warning on unhealthy, info on
   recovery); `appsettings.json` sets `DefaultHealthCheckService` to `Critical` so the framework
   doesn't log every failed probe. The MySQL server version is resolved once per process
   (`Configuration/MySqlServerVersionResolver.cs`, optional `Database:MySqlServerVersion`), so
   building a DbContext never connects just to learn it.
2. **Plugin probe** — `HealthApiImpl` (knk-api-client) calls `<health root>/health/ready`.
   Health root = `api.connectivity.health-root-url`, or `api.base-url` without its trailing
   `/api`. Own call timeout (`probe-timeout-seconds`, default 5 s). HTTP status first: 2xx reads
   `status` from the body, 503 → `unhealthy`, other codes → `ApiException`.
   `HealthStatus.isHealthy()` accepts `healthy`/`degraded` (and legacy `UP`/`OK`),
   case-insensitive.
3. **State machine** — `knk-core/.../core/connectivity/ApiConnectivity`: `UNKNOWN` at enable; the
   first probe result decides UP or DOWN at once; then UP → DOWN after `failures-to-down`
   consecutive failures (default 3), DOWN → UP after `successes-to-up` consecutive successes
   (default 2). A probe that keeps the state produces no transition.
4. **Monitor** — `knk-paper/.../paper/connectivity/ApiConnectivityMonitor`: async Bukkit timer
   (`probe-interval-seconds`, default 10), never overlaps probes, always calls `HealthApi`
   directly (never `HealthDataAccess` or any cache). On a transition it logs and fires
   `ApiConnectivityChangedEvent` **on the main thread**.

`/knk health` prints the live state, how long it has held, the last probe, then runs one direct
on-demand probe. Config: `config.yml` → `api.connectivity.*`.

Worst-case detection with defaults: DOWN about 20–35 s after the API or MySQL goes away
(3 probes, 10 s apart, each up to 5 s); UP about 10–15 s after it returns.

## Subscribing (how later features should use it)

```java
@EventHandler
public void onApi(ApiConnectivityChangedEvent e) {
    if (e.isRecovery()) { /* DOWN -> UP: refresh, replay */ }
    else if (e.isOutage()) { /* UP or UNKNOWN -> DOWN: contain */ }
}
```

- Ignore `UNKNOWN -> UP` (normal startup) unless the feature needs a "first time reachable" hook.
  `UNKNOWN -> DOWN` means the server started without the API.
- For a synchronous check use `KnKPlugin#getApiConnectivity()` (`isUp()`, `state()`,
  `snapshot()`); it is null when `api.connectivity.enabled: false`.
- The event is advisory: a single request can still fail while the state is UP. Keep per-call
  error handling.

Not subscribed yet (by design, KNG-115 scope):

| Consumer | Intended use |
|---|---|
| KNG-58 offline security / `ModeService` refresh | on `isRecovery()`, re-fetch permissions/users instead of its own ad-hoc retry |
| Hub outage actions and portals (KNG-109/114) | on `isOutage()`, gate portals / move players to the hub; on recovery, reopen |
| Siege containment (KNG-117) | on `isOutage()` during a match, apply the pause/abort decision |
| Spools (siege results etc.), `PlayerNotificationPoller`, PM log shipper | keep their own retry; optionally trigger an immediate replay on `isRecovery()` |
