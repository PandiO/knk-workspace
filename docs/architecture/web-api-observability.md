# Web API observability and client registry

**Status:** Current · **Last updated:** 2026-11-13 (moved into knk-workspace and checked against knk-web-api `next` `51c3086e26`, PandiO/knk-workspace#304)
**Moved from:** `knk-web-api/OBSERVABILITY.md` at `51c3086e26` ([source](https://github.com/PandiO/knk-web-api/blob/51c3086e26/OBSERVABILITY.md)). Corrected on the move: the admin endpoints are gated by the `knk.admin.config` node (there is no `RequireAdmin` policy), the lootbox meter is `Knk.Lootboxes`, and the `Knk.Realtime` meter was missing. How to use the numbers: [performance metrics and capacity](../guides/performance-metrics-and-capacity.md); the bigger picture: [web API architecture](web-api-architecture.md).

## Header Contract
- **X-Knk-Client-Id**: unique app instance id (GUID/string)
- **X-Knk-Client-Type**: `paper-plugin` | `web-admin` | `web-player` | `worker` | `unknown`
- **X-Knk-Client-Version**: semver/build string
- **X-Knk-Client-Name**: optional human label

Rules:
- Missing headers → grouped under `unknown`
- Application-level identity only (no player/user identity)
- Do not log secrets (auth tokens/api keys)
- Do not store request bodies

## Endpoints
- Health:
  - GET `/health/live` → liveness (anonymous, process only)
  - GET `/health/ready` → readiness + dependency statuses (anonymous, includes the database check)
  - GET `/api/health` → simple `{"status":"ok","version":…}` for a baseUrl ending with `/api` (anonymous)
- Admin (`[RequirePermission(StaffPermissions.ServerConfig)]`, node `knk.admin.config`; `AdminClientsController`):
  - GET `/api/admin/clients?activeWithinMinutes=60` → list of active clients
  - GET `/api/admin/clients/{clientType}/{clientId}` → client detail snapshot
  - GET `/api/admin/clients/all` → all known clients
  - POST `/api/admin/clients/cleanup?inactiveForHours=24` → remove inactive clients

## Telemetry (OpenTelemetry)
- Config via `Telemetry` in appsettings (the client registry via `ClientActivity`: `Enabled`, `MaxClients`, `InactivityThreshold`, `CleanupInterval`, `RollingWindowMinutes`)
  - `Enabled`: true/false (master switch for all metrics/tracing below)
  - `Exporter`: `otlp` (current default)
  - `Otlp.Endpoint`: e.g. `http://localhost:4317` (nothing listens there unless you run a collector)
  - `Prometheus.Enabled` (default **false**), `Prometheus.Endpoint` (default `/metrics`),
    `Prometheus.BearerToken` (KNG-232, see below)
- Tracing: HTTP server spans
- Metrics:
  - ASP.NET Core: `http.server.request.duration` (and active requests)
  - .NET runtime (OpenTelemetry runtime instrumentation): GC collections/pause, heap size, allocations,
    thread pool, lock contention, assemblies
  - Outbound `HttpClient` calls
  - `Knk.Process`: `knk.process.cpu.time`, `knk.process.memory.working_set`, and the container's cgroup counters
    `knk.cgroup.memory.{usage,working_set,limit}`, `knk.cgroup.cpu.{time,throttled_time}` (cgroup v2, v1 for memory;
    absent outside a container). Compare the *working set* with the limit: usage includes reclaimable file cache.
  - `Knk.Db`: `knk.db.command.duration` histogram (seconds; `kind` = reader|write|scalar|command, `outcome` = ok|error;
    a reader's time ends when the reader is returned, not when its rows are read)
  - Feature meters: `Knk.Lootboxes`, `Knk.Currency`, `Knk.Statistics`, `Knk.Telemetry` (diagnostic-event queue depth etc.),
    `Knk.Realtime` (SignalR hub)
- Logging: structured logs with trace correlation (future)

### Prometheus scrape endpoint (KNG-232)
Off by default. To enable on a host, set in the environment (not in git):
```
Telemetry__Enabled=true
Telemetry__Prometheus__Enabled=true
Telemetry__Prometheus__BearerToken=<openssl rand -hex 32>
```
Outside Development the API **refuses to start** with the endpoint enabled and no token. The scraper sends
`Authorization: Bearer <token>`. The endpoint is not an MVC action (the default-deny filter does not apply), so
this token is its only gate: never route `/metrics` through nginx/Cloudflare, keep the API's published port on the
private network. Prometheus names come from the OpenTelemetry names: dots become underscores and the unit is a
suffix (`knk.db.command.duration` -> `knk_db_command_duration_seconds_bucket`). The exporter package is
prerelease (`OpenTelemetry.Exporter.Prometheus.AspNetCore` has no stable version) and is pinned in the csproj.
How to use the numbers: [performance metrics and capacity](../guides/performance-metrics-and-capacity.md).

## Privacy Rules
- No user/player identifiers in labels or logs
- Labels allowed: clientType, clientId, route template
- Avoid high-cardinality labels (no query values)

## Client Registry
- In-memory store with rolling 60-minute buckets
- Data per client:
  - `lastSeenUtc`
  - `lastRequest` summary (method, route template, status code, duration, timestamp)
  - Counters: total/success/error, durations
- Extensible interface: allows future Redis implementation

## Enable OTLP locally
Run an OTLP collector (e.g., OpenTelemetry Collector) listening on `http://localhost:4317`.

## Future
- Dashboards and alert rules as code
