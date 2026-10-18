# API connectivity (plugin ↔ knk-web-api)

**Status:** Live · **Last updated:** 2026-10-11 — merged after a developer live test
([KNG-115](https://linear.app/kngpandi/issue/KNG-115)): knk-web-api `master` `17ee730`, knk-plugin
`main` `b5eee6e`. All decisions below were accepted by the developer on 2026-10-11.
2026-10-15: first consumer of the state, [KNG-171](https://linear.app/kngpandi/issue/KNG-171) — reads
skip the API while it is DOWN (§ "Reads skip the API while DOWN"). Implemented on knk-plugin branch
`wt/kng-171`; live-tested by the developer and merged 2026-10-17 ([knk-plugin #14](https://github.com/PandiO/knk-plugin/pull/14)).

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

## Reads skip the API while DOWN (KNG-171)

Before KNG-171 every cache miss during an outage still called the API: three attempts (100 ms then
200 ms backoff) plus each connection attempt, and only then the fallback. `/knk help`, `/msg` and
`/tpa` answered about 1 s late (KNG-123 live test, 2026-10-12). Now:

- **Port.** `knk-core/.../core/connectivity/ApiOutageSignal` (`isApiDown()`), implemented by
  `ApiConnectivity` (true only in DOWN; UNKNOWN is not down). Core never sees Bukkit.
- **Wiring.** `KnKPlugin#isApiSkippedWhileDown()` = `api.connectivity.skip-api-while-down` (default
  `true`) and the current monitor's state is DOWN. `DataAccessFactory` puts it into every gateway's
  `DataAccessSettings.apiOutage()`, except `HealthDataAccess` (a health read is how an operator
  checks whether the API is back). The probe itself never goes through a gateway, so it keeps
  probing.
- **Gate.** `DataAccessExecutor` reads the signal before the first attempt and again before every
  retry. While DOWN no call is made: the read ends at once the way a failed call would, with an
  `ApiDownException` (an `ApiException`, no stack trace) in place of the connection error. A fresh
  cache hit is answered as always; `CACHE_FIRST`/`API_ONLY` give `ERROR` on a miss; `STALE_OK`
  serves a stale entry; `API_THEN_CACHE_REFRESH` serves a fresh cached entry. Sync
  (`fetchBlocking`) and async reads alike.
- **Permissions.** A miss reads as UNAVAILABLE at once, and `KnkPermissible` answers it from the
  offline store ([offline-security-cache.md](offline-security-cache.md) § 3). The rules are
  unchanged: a last-known deny stays a deny, an answer past its max age counts as unknown (no).
  A skipped check is logged at FINE, not as a warning per check. Since KNG-107 the plugin loads one
  permission set per player instead of one check per node; while DOWN a loaded set still answers
  listings for `effective-set-stale-seconds` ([plugin-permission-checks.md](plugin-permission-checks.md)).
- **Writes** (`*CommandApi`, currency, ignore changes, ...) don't go through the executor and
  still call the API; they fail during an outage as before.
- **Back UP.** The next read calls the API as before; nothing was cached from skipped reads, so
  the first misses refill the caches. Nothing listens for the event for this.
- **Flapping.** The hysteresis smooths it: reads keep calling the API until the state is DOWN
  (about 20-35 s into an outage with defaults), and keep skipping it until the state is UP again
  (about 10-15 s after the API returns). A retry that was already scheduled when the state turned
  DOWN is not sent.
- `/knk health` adds a line while DOWN: "reads skip the API until UP". With
  `skip-api-while-down: false` the plugin calls (and retries) the API during an outage as before,
  and `/knk health` says so.

Decisions for developer review (KNG-171, 2026-10-15):

1. The gate is generic (every `DataAccessExecutor` read), not only permission checks: a skipped
   read ends exactly as a failed call would, so each caller's existing fallback applies unchanged.
2. Only DOWN skips the API. UNKNOWN (startup, or `api.connectivity.enabled: false`) calls it as
   before, so a disabled or misbehaving probe can't silence the API before its first verdict.
3. Kill switch `api.connectivity.skip-api-while-down`, default `true`, in case the probe reports
   DOWN while the API is usable (e.g. a wrong `health-root-url`).
4. `HealthDataAccess` is never gated.
5. Permissions use only a fresh in-memory answer while DOWN; an expired one goes to the offline
   store, which applies `permission-max-age-hours`. Stale-on-error for `CACHE_FIRST` reads in
   general stays KNG-123's open item.

Not covered (no `DataAccessExecutor`, one attempt, no retries): `TeleportPolicyDataAccess`,
`TeleportDestinationsDataAccess`, `TitleBracketsDataAccess`, `PermissionGroupsDataAccess`, the
ignore-list load and other direct API calls. A refused connection fails fast there; an API that
hangs still costs a read timeout.

## API background services during a database outage

While MySQL is down, the API's own background loops fail on every iteration. They log that
once instead of a stack trace each time (knk-web-api `master` `f409271`).
`Services/ConnectivityAwareFailureLogger.cs` is the same once-per-change idea as the readiness
logging above:

- **Connectivity failure** (a `MySqlException` anywhere in the inner-exception chain with an
  unreachable, shutdown or too-many-connections code such as `UnableToConnectToHost`, or a
  socket/IO cause): one Warning without a stack trace when it starts (`<operation>: database
  unreachable (...); retrying quietly until it is back`), nothing while it continues, one
  Information line (`<operation>: database reachable again`) on the next successful iteration.
- **Any other failure**, including other MySQL errors such as a duplicate key or an unknown
  column, still logs `LogError(ex, ...)` on every iteration, also during an outage.

Used by `RankExpirySweepService` (every 30 s), `CurrencyMonitorService` (one state per step,
because the signals step only touches the database when it has signals to store) and
`LocationRetentionScheduler` (every 5 min). `RetentionPolicyService` runs daily and still logs
each failure. A new background loop that retries on a timer should use the helper: one instance
per loop, `Succeeded()` after each good iteration, `Failed(ex, message, args)` in the catch.

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

Subscribers of the state:

| Consumer | Use | Status |
|---|---|---|
| `DataAccessExecutor` gateway reads, incl. permission checks (KNG-171) | synchronous `ApiOutageSignal`, not the event: while DOWN no call, answer from the caches and the offline store | branch `wt/kng-171`, not merged |

Not subscribed yet (by design, KNG-115 scope):

| Consumer | Intended use |
|---|---|
| KNG-58 offline security / `ModeService` refresh | on `isRecovery()`, re-fetch permissions/users instead of its own ad-hoc retry (KNG-171 already stops the calls while DOWN) |
| Hub outage actions and portals (KNG-109/114) | on `isOutage()`, gate portals / move players to the hub; on recovery, reopen |
| Siege containment (KNG-117) | on `isOutage()` during a match, apply the pause/abort decision |
| Spools (siege results etc.), `PlayerNotificationPoller`, PM log shipper | keep their own retry; optionally trigger an immediate replay on `isRecovery()` |
