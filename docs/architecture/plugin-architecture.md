---
status: active
last_updated: 2026-09-21
---

# knk-plugin Architecture

Spigot/Paper Minecraft plugin for Knights and Kings V3. Multi-module Gradle
(Kotlin DSL), Java 21 toolchain, targets Paper API `1.21.10-R0.1-SNAPSHOT`.
This document describes structure and data flow as verified by a read-only
codebase scan on 2026-09-21 — see `docs/reports/plugin-scan-2026-09-21.md`
for the full inventory this was drawn from, and
`docs/guides/plugin-reading-guide.md` for a practical onboarding path.

## Modules

Three Gradle modules (`settings.gradle.kts`): `knk-core`, `knk-api-client`,
`knk-paper`.

### `knk-core` — domain model, ports, gate-geometry math

Intended as the framework-free shared domain/ports layer. **Not fully
framework-free in practice**: it declares `compileOnly` on `paper-api`
(`knk-core/build.gradle.kts:8`) because several classes genuinely import
`org.bukkit.util.Vector` for geometry math — `domain/gates/CachedGateDoor.java:4`,
`domain/gates/BlockSnapshot.java:3`, `gates/{GateSpatialIndex,GateBlockPairing,
GateFrameCalculator,GateManager,RigidTransform}.java`, `util/CoordinateParser.java:6`.
No HTTP dependency (no OkHttp/`java.net.http` usage) — the Bukkit `Vector`
leak is the only boundary violation.

| Package | Purpose |
|---|---|
| `cache/` | In-memory TTL caches (`BaseCache`, `TownCache`, `DistrictCache`, `StructureCache`, `UserCache`, `StreetCache`, `DomainCache`, `BaseRegionCache`) |
| `dataaccess/` | Cache/API gateway abstractions: `FetchPolicy`, `DataAccessSettings`, `RetryPolicy`, `DataAccessExecutor`, per-entity `XDataAccess` classes |
| `domain/` | Domain model types by entity (`common/`, `districts/`, `domains/`, `enchantment(s)/`, `gates/`, `item/`, `location/`, `material/`, `streets/`, `structures/`, `towns/`, `users/`, `validation/`) plus `HealthStatus.java` |
| `eventHandlers/` | `RegionEventHandler.java` — domain-level region event handling |
| `exception/` | `ApiException.java` — shared exception thrown by API impls |
| `gates/` | Pure gate-geometry/animation math (`GateFrameCalculator`, `GateManager`, `GateSpatialIndex`, `GateBlockPairing`, `RigidTransform`) — the package that leaks `org.bukkit.util.Vector` |
| `ports/` | Outbound-dependency interfaces: `ports/api/` (14 REST port interfaces implemented by `knk-api-client`), `ports/enchantment/`, `ports/gates/` |
| `regions/` | `RegionDomainResolver`, `RegionTransitionService`, `RegionTransitionDecision`, `SimpleRegionTransitionService` |
| `services/` | A second `RegionTransitionService.java` + `iRegionTransitionService.java` — same class name as `regions/RegionTransitionService.java` in a different package; likely duplicate/dead, see scan report |
| `util/` | `CoordinateParser.java` (Jackson-based), `VectorMath.java` |

### `knk-api-client` — REST client to knk-web-api

Package `net.knightsandkings.knk.api.*`. Uses OkHttp 4.12.0 +
Jackson (`jackson-databind:2.17.2`, `jackson-datatype-jsr310:2.17.2`) —
`knk-api-client/build.gradle.kts:4-6`.

- `KnkApiClient.java` — composition root: one shared `OkHttpClient`, one
  shared Jackson `ObjectMapper` (`FAIL_ON_UNKNOWN_PROPERTIES=false` +
  `JavaTimeModule` + custom `LenientOffsetDateTimeDeserializer`, lines
  264-269), one `AuthProvider`, one `ExecutorService`; constructs all 16 API
  impl instances (lines 95-110). Supports a dev-only "trust all SSL" mode
  (lines 236-238, 291-317) driven by `config.yml`'s `allow-untrusted-ssl`.
- `impl/BaseApiImpl.java` — shared request plumbing: `newRequest()` (45-51)
  attaches the auth header; `get`/`postJson`/`putJson` (94-124) build verbs
  with JSON headers; `execute()` (59-92) runs synchronously (wrapped in
  `CompletableFuture` by callers), treats HTTP 204 as empty-body success,
  throws `ApiException` on non-2xx/empty body; `parse()` (126-140)
  deserializes via the shared `ObjectMapper`. A few impls build `Request`
  objects directly for verbs the base class doesn't wrap (PUT in
  `GateDoorsApiImpl.java`, PATCH in `GateStructuresApiImpl.java:158`). No
  `DELETE` helper exists anywhere in the module.
- `api/auth/` — `AuthProvider` interface + three strategies:
  `BearerAuthProvider` (static token supplied at construction, attaches
  `Authorization: Bearer <token>`; **no refresh/expiry/401-retry logic
  anywhere in the class or package**), `ApiKeyAuthProvider`,
  `NoAuthProvider`. Selected by `config.yml`'s `api.auth.type`
  (`none|bearer|apikey`); the shipped default is `none`.

**16 REST resource clients** (`impl/*ApiImpl.java`) cover Health, Towns,
Districts, Structures, Streets, Locations, EnchantmentDefinitions,
ItemBlueprints, MinecraftMaterialRefs, Domains, Users (query + command),
UserAccount (link/merge/lifecycle), WorldTasks, GateStructures, GateDoors,
and outbound Regions (rename). Full endpoint-by-endpoint table is in
`docs/reports/plugin-scan-2026-09-21.md`.

**Inconsistency to flag:** `GateStructuresApi`/`GateDoorsApi` interfaces
live directly in `knk-api-client`'s own `net.knightsandkings.knk.api`
package (`GateStructuresApi.java:1,20`, `GateDoorsApi.java:1,15`), while
every other port interface lives in `knk-core`'s
`net.knightsandkings.knk.core.ports.api` and is only *implemented* in
`knk-api-client`. The two newest (gate-related) resources break the
otherwise-consistent ports/adapters pattern.

### `knk-paper` — the Bukkit/Paper plugin itself

Entry point: `KnKPlugin` (`extends JavaPlugin`,
`knk-paper/.../KnKPlugin.java:86`; declared as `main:` in `plugin.yml:5`).

**`onEnable()` (`KnKPlugin.java:127-478`)**, in order: build the API client
+ all query/command API wiring → init gate subsystem (`GateManager`,
`GateStateSyncTask`, `DistrictGateLoader`, `GateDisplayManager`, initial
load) → init `CacheManager`/`UserManager`/`ChatCaptureManager`/
`CommandCooldownManager` → register `ChatCaptureListener` inline → set up
`WorldTaskHandlerRegistry` (`WgRegionIdTaskHandler`, `LocationTaskHandler`),
start `RegionHttpServer`, `TempRegionRetentionTask`,
`HeadlessWorldTaskPoller` → build `DataAccessFactory`-backed data access
objects → `initializeEnchantmentRuntime()` → `EnchantmentBootstrap.initialize()`
(registers 4 enchantment listeners + the `/ce` executor) → `registerCommands()`
(`/knk`, `/account`) → build region-tracking pipeline and call the private
`registerEvents(WorldGuardRegionTracker)` helper (registers only 3 of the
14 listeners: `WorldGuardRegionListener`, `PlayerListener`,
`UserAccountListener` — despite the generic name, don't assume it's the
single listener-registration entry point) → build `HealthSystem`/
`GateDoorHitService`/`GateFireSystem`, register `GateEventListener` +
`GateDamageConsequenceListener` → build `GatePassThroughService`, register
`GatePassThroughConsequenceListener` → schedule gate animation/fire/display
tasks → conditionally register `RegionTaskEventListener` → register
`WorldTaskChatListener` and `WorldTaskLocationSelectionListener`.

**`onDisable()` (`KnKPlugin.java:480-512`)**: stop/persist gate-state-sync,
remove gate displays, stop the headless poller and temp-region-retention
task, log/clear cache metrics, shut down the API client, stop the region
HTTP server.

Structure under `knk-paper/src/main/java/net/knightsandkings/knk/paper/`:
`commands/` (+ `commands/enchantment/`), `listeners/`, `events/`, `gates/`
(22 files, ~4,546 lines — the largest single package), `cache/`,
`dataaccess/`, `http/`, `integration/`, `regions/`, `tasks/`, `config/`,
`user/`. No `gui/`/`menus/` package exists (confirmed, see below).

## Data flow

```
Player action / command
        │
        ▼
knk-paper (command or listener)
        │  cache-first lookup
        ▼
knk-core DataAccessExecutor  ──cache hit──▶ in-memory TTL cache (knk-core cache/)
        │ cache miss / API_ONLY / refresh
        ▼
knk-api-client (impl/*ApiImpl.java, via BearerAuthProvider/NoAuthProvider)
        │  HTTPS + JSON (OkHttp + Jackson)
        ▼
knk-web-api (ASP.NET Core)  ──▶  shared MySQL
```

### Auth

Bearer JWT via `BearerAuthProvider`, matching `knk-web-api`'s JWT setup —
but the token is a **static value read once from `config.yml`
(`api.auth.bearer-token`)**, not fetched or refreshed. There is no
401-triggered re-auth anywhere in `knk-api-client`. If tokens expire
server-side, the plugin has no automatic recovery path — worth a look
before relying on long-lived server sessions.

### Data access / caching (`DataAccessFactory`)

`knk-paper/.../dataaccess/DataAccessFactory.java` wires 11 entity gateways:
Users, Towns, Districts, Structures, Streets, Locations,
EnchantmentDefinitions, ItemBlueprints, MinecraftMaterialRefs, Domains,
**and Health** (11, not 10 — Health is easy to miss since it's tuned very
differently, see below). Each is built from `config.yml`'s
`cache.entities.*` block (`config.yml:175-262`), which independently sets
per entity: TTL, max-TTL, default `FetchPolicy`, `allow-stale`, retry
attempts, retry backoff. `Health` is the outlier: 30s TTL (vs. 15-60
minutes for everything else) and `allow-stale: false` — the only entity
that refuses to serve stale cache data.

`FetchPolicy` (`knk-core/.../dataaccess/FetchPolicy.java`, 5 values):
`CACHE_ONLY`, `CACHE_FIRST` (default), `API_ONLY`, `API_THEN_CACHE_REFRESH`,
`STALE_OK` (downgraded to `CACHE_FIRST` at runtime if the entity's
`allow-stale` is false — `DataAccessSettings.resolvePolicy()` lines 65-73).

Caching itself is purely in-memory (`knk-core/cache/BaseCache.java` wraps a
TTL-keyed map, no disk persistence); `CacheManager.java`
(`knk-paper/.../cache/CacheManager.java`) is the Paper-side lifecycle owner.

### Local storage — migration complete

Repo-wide search across all three modules for embedded DBs (SQLite/H2,
`jdbc:` strings), on-disk serialization (`ObjectOutputStream`,
`FileOutputStream`), or YAML/JSON used as a data store found **nothing**
beyond ordinary Bukkit `config.yml` settings and the in-memory TTL cache.
All persistent domain data — Users, Towns, Districts, Structures, Streets,
Locations, EnchantmentDefinitions, ItemBlueprints, MinecraftMaterialRefs,
Domains, WorldTasks, GateStructures, GateDoors — flows through the REST API
to the shared MySQL DB. This confirms the V2→V3 storage migration is
complete for every entity type the plugin touches.

### Sync/polling model — mixed, not purely on-demand

- **Outbound polling (tech debt, self-flagged):**
  `HeadlessWorldTaskPoller.java` calls `worldTasksApi.listByStatus("Pending")`
  on a backing-off interval (5s → up to 60s, `config.yml:60,65`). Its own
  Javadoc (lines 14-23) says this is a placeholder for a future
  push/SignalR notification.
- **Outbound push (periodic):** `GateStateSyncTask` pushes in-memory gate
  state back to the API every `gates.state-sync-interval-seconds`
  (default 120s, `config.yml:73`) as a safety net, plus a periodic
  diagnostic health-check pass. `GateFireDamageTask` ticks fire damage in
  memory and relies on the sync task for eventual DB persistence rather
  than writing every tick.
- **Inbound HTTP (API → plugin):** `RegionHttpServer.java` runs a
  `com.sun.net.httpserver.HttpServer` inside the plugin, exposing
  `POST /Regions/rename` and region-containment queries
  (`GET /api/regions/{id}/contains-location|contains-region`) so
  `knk-web-api` can ask the plugin WorldGuard/WorldEdit questions it can't
  answer itself. This is a distinct channel from both the REST client and
  the poller — the only place the API calls *into* the plugin.
- Everything else (commands, player-triggered lookups) is on-demand via the
  cache-first data access layer.

## Gate-structure subsystem (the most mature feature in the repo)

Spans `knk-core/.../gates/` (pure geometry, unit-tested) and
`knk-paper/.../gates/` (22 files, animation/health/fire/display runtime).
Key core classes: `RigidTransform` (Kabsch-algorithm best-fit rotation via
Jacobi SVD, 339 lines), `GateFrameCalculator` (885 lines — per-frame block
positions for VERTICAL/LATERAL/ROTATION motion, box and polygon/`REGION`
geometry clipping, rasterized gap-fill for diagonal-hinge rotation),
`GateBlockPairing` (Hungarian-algorithm bipartite matching for
closed↔open block correspondence, replacing an earlier greedy approach),
`GateManager` + `GateSpatialIndex` (in-memory cache + O(1) hit lookup),
`CachedGateDoor` (744-line mutable animation/health/fire/pass-through/
respawn state model).

WorldGuard 7.0.10 / WorldEdit 7.2.13 (`compileOnly`,
`knk-paper/build.gradle.kts`) are genuinely used — real `RegionManager`/
`RegionContainer`/`BukkitAdapter`/`LocalSession` calls in
`WorldGuardRegionTracker.java`, `tasks/WgRegionIdTaskHandler.java`,
`tasks/GateDoorRegionCaptureHandler.java`, `tasks/GateBlockScanTaskHandler.java`
— **except** `integration/WorldGuardIntegration.java`, which is instantiated
and wired through (`KnKPlugin.java:427`) but whose only method
(`regionExists()`) has no production call site — `GateAnimationTask.java`
documents in its own comments that the WG region-sync it used to do "was
removed in item 6.2." Treat this one class as live-wired but currently
dormant.

A separate, easily-confused concept: `PaperGateControlAdapter`
(`knk-paper/.../gates/PaperGateControlAdapter.java`) implements a simpler
`GateControlPort` used by `SimpleRegionTransitionService` for a
"region-entry triggers a gate" idea — its `openGate`/`closeGate` are pure
stubs that just log (`// TODO: Implement actual gate opening/closing
logic`, lines 29-51). Don't conflate this with the fully-implemented
gate-structure-animation system above; they're unrelated code paths that
happen to share the word "gate."

Siege-specific fields exist on the model (`CachedGateStructure.currentSiegeId`,
`animateDuringSiege`, `isSiegeObjective`) but are inert data — there is no
siege service, capture logic, or team/scoring system anywhere in the repo.
See the parity table in `docs/reports/plugin-scan-2026-09-21.md` for the
full picture.

## Talks to

- **knk-web-api**: direct REST calls from `knk-api-client`, bearer-token
  authenticated (`BearerAuthProvider`) — matches the API's JWT setup, but
  see the no-refresh caveat above. The API also calls **into** the plugin
  via `RegionHttpServer` for region queries.
- **knk-web-app**: no direct integration — the web app talks to
  `knk-web-api` only; the plugin and web app never call each other
  directly (all cross-component state is mediated through the API + shared
  MySQL).

## Known architectural inconsistencies (see scan report for full detail)

- `GateStructuresApi`/`GateDoorsApi` port interfaces live in
  `knk-api-client` instead of `knk-core` (breaks the ports/adapters
  pattern used everywhere else).
- `knk-core` leaks `org.bukkit.util.Vector` into gate-geometry/coordinate
  code, requiring a `compileOnly` Paper dependency in a module meant to be
  framework-free.
- Two `RegionTransitionService` classes with the same name in different
  `knk-core` packages (`regions/` vs `services/`) — likely duplicate/dead,
  not yet resolved.
- JSON library split: Jackson does all REST DTO (de)serialization
  (`knk-api-client`); Gson is used only for ad-hoc JSON blobs in
  `knk-paper` (region/task payloads) and one field type in `knk-core`.
  `knk-core`'s Gson dependency is close to dead weight (single type
  reference, no real Gson API calls). `knk-paper` declares Jackson
  directly but never imports it (it arrives transitively via
  `knk-api-client` and is shadow-relocated) — and pins a different Jackson
  version (2.15.2) than `knk-api-client` (2.17.2).
