# Handoff: API connectivity — health probe, DB readiness, ApiConnectivity state (KNG-115)

**Date:** 2026-10-10
**Status:** Implemented and unit-tested; **awaiting live test**. Not merged, no PR, not deployed.
**Issue:** [KNG-115](https://linear.app/kngpandi/issue/KNG-115) (leave In Progress until the live test)
**Source:** `docs/reports/2026-10-10-multiworld-capability-audit.md` rows C1-C5, §5 (workspace branch `claude/blissful-fermat-b7ihrz`)
**Living doc:** `docs/architecture/api-connectivity.md` (design, defaults, how to subscribe)

## Branches

| Repo | Branch | Commit | Base |
|---|---|---|---|
| knk-web-api | `claude/kng-115-api-health` | `860c2e9` | `master` `8cce48d0` |
| knk-plugin | `claude/kng-115-api-health` | `f88d686` | `main` `973aa68b` |
| knk-workspace | `claude/kng-115-api-health` | this commit | `claude/compassionate-darwin-86zbpy` `38f22c0` (carries the claim) |

## What changed

**API**: `Services/DatabaseHealthCheck.cs` (EF `CanConnectAsync`, tag `ready`, 3 s timeout)
registered next to `self` in `Program.cs` (health-check lines only — KNG-64 also edits
`Program.cs`, the auth part; expect an easy merge). `/health/ready` answers 503 only for
`unhealthy` (was: anything not `healthy`); its per-request log line moved to Debug, an unhealthy
result logs a warning. `/health/live` unchanged (no checks).

**Plugin**: `HealthApiImpl` probes `<root>/health/ready` with its own timeout; `HealthStatus`
reads `healthy`/`degraded`/`unhealthy`; new `ApiConnectivity` (core) + `ApiConnectivityMonitor`,
`ApiConnectivitySettings`, `ApiConnectivityChangedEvent` (paper); `config.yml`
`api.connectivity.*`; health data-access `default-policy: API_ONLY` and a Javadoc warning on
`HealthDataAccess`; `/knk health` shows the live state. `KnKPlugin`: settings line, two builder
lines, monitor start, stop in `onDisable`, getter. `KnkAdminCommand` untouched.

## Correction to the issue text

The issue says `/api/health` doesn't exist. It does: `Controllers/HealthController.cs`
(`api/[controller]`, case-insensitive routing) returns `{"status":"ok"}`, which the old
`isHealthy()` accepted. So the old probe *worked* but checked nothing: no DB, no readiness. The
fix is the same; `HealthController` is left in place (unused by the plugin now — decision for
review whether to remove it later).

## Tests

- Plugin `./gradlew test`: 3501 tests, 0 failures, 20 skipped (new: `ApiConnectivityTest` 11,
  `ApiConnectivityMonitorTest` 9, `HealthApiImplTest` 8, `HealthStatusTest` +1).
  `./gradlew build -x deployToDevServer` OK.
- API `dotnet build knkwebapi_v2.csproj` OK (0 errors). `dotnet build` on the `.sln` fails on
  Linux on `master` too: the solution references `tests/...` but the folder is `Tests/` —
  pre-existing, unrelated.
- API `dotnet test`: `master` 4 failed / 1969 passed / 54 skipped; branch 4 failed / 1976 passed /
  54 skipped. **Same 4 failures** (pre-existing: `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
  `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`,
  two `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` cases). +7 new
  `HealthCheckControllerTests`, all passing (incl. a real Pomelo context on a refused port → unhealthy).

## Decisions for review

1. **`degraded` counts as UP** (plugin) and answers **200** (API). No check reports degraded today.
2. **Health root derived** from `api.base-url` by stripping a trailing `/api`; override with
   `api.connectivity.health-root-url`.
3. **Defaults**: probe every 10 s, 5 s timeout, DOWN after 3 failures, UP after 2 successes.
4. **Initial state UNKNOWN**, first result decides at once (fires `UNKNOWN -> UP` at a normal
   start). Subscribers use `isRecovery()` (DOWN→UP) to avoid acting on startup.
5. The probe still sends the API key header (harmless; the route is anonymous).
6. `/knk health`'s on-demand probe does not feed the state machine (keeps hysteresis timing
   purely interval-based).

## Live checklist

Setup: build both branches; deploy the plugin jar (`./gradlew :knk-paper:dev`), run the API from
`claude/kng-115-api-health`. Existing `config.yml` files don't get the new section — defaults
apply; add `api.connectivity` from the jar's `config.yml` to tune.

1. `curl -i http://localhost:5294/health/ready` → 200, `"status":"healthy"`, checks `self` and
   `database` healthy. `curl -i .../health/live` → 200.
2. Start the server. Log shows `API connectivity probe every 10s ...` then
   `API connectivity UNKNOWN -> UP (healthy)`.
3. `/knk health` → `API connectivity: UP (for Ns ...)`, last probe ok, then `✓ API is healthy`.
4. **Stop MySQL** (API keeps running). `curl -i .../health/ready` → 503 `unhealthy`,
   `database: unhealthy` within ~3 s. Within ~35 s the server logs
   `WARN API connectivity UP -> DOWN (unhealthy)`; `/knk health` shows DOWN and
   `⚠ API status: unhealthy`. Confirm only **one** DOWN line (no repeat while it stays down).
5. **Start MySQL.** Within ~15-25 s: `API connectivity DOWN -> UP (healthy)`.
6. **Stop the API process.** Within ~35 s: `UP -> DOWN (ConnectException: ...)`; `/knk health`
   shows DOWN with the connection error, and the on-demand probe's error block.
7. **Start the API.** `DOWN -> UP` after two passing probes.
8. **Restart the server with the API down**: `UNKNOWN -> DOWN` on the first probe; then start the
   API → `DOWN -> UP`.
9. Flap test: one quick API restart (< 20 s) should **not** produce DOWN (hysteresis).
10. Watch the API log: no Info line per probe (moved to Debug); a warning per unhealthy probe
    while MySQL is down is expected.

## Next steps

- Developer live test; then PRs (API first or together — the plugin with the old API would get
  `/health/ready` without a DB check, which still works).
- Subscribers in their own issues (see the table in `docs/architecture/api-connectivity.md`):
  KNG-58 refresh on `isRecovery()`, KNG-109/114 hub outage actions on `isOutage()`, KNG-117 Siege
  containment, optional immediate replay for spools / notification poller / PM shipper.
