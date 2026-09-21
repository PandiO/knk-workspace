---
status: active
last_updated: 2026-09-21
---

# knk-plugin Reading Guide

Practical onboarding for a new session or contributor picking up
`knk-plugin` cold. Pairs with `docs/architecture/plugin-architecture.md`
(structure/data-flow reference) and
`docs/reports/plugin-scan-2026-09-21.md` (detailed findings, legacy/stub
inventory, V1/V2 parity table). Read `CLAUDE.md` in the plugin repo first
for build commands and conventions — this guide doesn't repeat those.

## Start here, in order

1. **`KnKPlugin.java`** (`knk-paper/src/main/java/net/knightsandkings/knk/paper/KnKPlugin.java`) —
   the entry point. `onEnable()` (lines 127-478) is a linear tour of every
   subsystem the plugin wires up, in dependency order: API client → gate
   subsystem → cache/user managers → chat capture → world-task handlers →
   data access factory → enchantment runtime → commands → region tracking
   → gate event/damage listeners → gate pass-through → scheduled tasks →
   remaining listeners. If you're not sure where something is initialized,
   it's almost certainly in this method. Note the private
   `registerEvents()` helper (lines 514-522) only registers 3 of the 14
   listeners despite its generic name — don't assume it's the whole
   listener story.
2. **`config.yml`** (`knk-paper/src/main/resources/config.yml`) — every
   tunable in the plugin lives here: API base URL/auth/timeouts, per-entity
   cache TTL/retry/fetch-policy (`cache.entities.*`), gate animation/fire/
   pass-through/sync timings, world-task poll intervals, enchantment
   messages. Reading this end to end tells you what's configurable before
   you go looking for magic numbers in code.
3. **`plugin.yml`** — the 3 top-level commands (`knk`, `account`, `ce`) and
   their permission nodes. Everything else is subcommand dispatch inside
   those three (see the scan report's command table for the full list).
4. Pick your subsystem and go to its package (see map below) — you
   shouldn't need to read the whole codebase for a single feature change.

## Module map (what lives where)

- **`knk-core`** — domain model + ports + gate-geometry math. Read here
  when you need to understand a domain type (`domain/*`), an outbound-port
  interface (`ports/api/*` — implemented by `knk-api-client`), or the pure
  math behind gate animation (`gates/{RigidTransform,GateFrameCalculator,
  GateBlockPairing}.java` — these have real unit tests, read the tests
  alongside the implementation to understand intended behavior). Caveat:
  it's not fully framework-free — several gate classes import
  `org.bukkit.util.Vector`, so don't assume you can use this module outside
  a Bukkit classpath.
- **`knk-api-client`** — the REST client. `impl/BaseApiImpl.java` is the
  shared request/response plumbing; every `impl/*ApiImpl.java` is one
  resource. If you're adding a new API endpoint call, copy an existing
  `*ApiImpl.java` for a similar resource — but note `GateStructuresApi`/
  `GateDoorsApi` interfaces live in this module instead of `knk-core/ports/api`
  like every other resource; follow the *majority* pattern (interface in
  `knk-core`, impl here) for anything new rather than copying the gate
  interfaces' placement.
- **`knk-paper`** — the actual plugin: `commands/`, `listeners/`, `events/`
  (custom Bukkit events), `gates/` (largest package, animation/health/fire/
  display runtime), `dataaccess/` (`DataAccessFactory` — wires cache+API
  gateways per entity), `cache/` (`CacheManager`), `tasks/` (scheduled
  jobs and world-task handlers), `http/` (`RegionHttpServer` — the one
  place the web API calls *into* the plugin), `config/`, `user/`,
  `integration/`/`regions/` (WorldGuard/WorldEdit glue).

## How data gets fetched (read this before touching any feature)

Every entity (towns, districts, structures, streets, locations,
enchantment definitions, item blueprints, material refs, domains, users,
health) goes through the same pattern: a `knk-core` `XDataAccess` class,
built by `DataAccessFactory` (`knk-paper/.../dataaccess/DataAccessFactory.java`),
resolves a `FetchPolicy` (`CACHE_FIRST` by default) from `config.yml`,
checks the in-memory TTL cache, and falls back to the matching
`knk-api-client` REST call on a miss. If you're adding a new entity type,
follow this exact chain: `knk-core/ports/api` interface →
`knk-api-client/impl` implementation → `knk-core` cache + data-access
class → wire it into `DataAccessFactory`. Skipping the cache layer (e.g.
calling an `*ApiImpl` directly from a command) works but bypasses the
TTL/retry/stale-read policy the rest of the codebase relies on — avoid it
unless you have a specific reason (see `HealthDataAccess`'s especially
short TTL and `allow-stale: false` for an example of an entity that
deliberately opts out of normal caching behavior).

There is no local database or file-based data store to worry about —
everything durable lives behind the REST API in the shared MySQL DB. The
plugin's only local state is the in-memory cache (cleared on restart) and
`config.yml` settings.

## Auth gotcha

`BearerAuthProvider` holds a static token read once from `config.yml` at
startup. There is no refresh or 401-retry logic anywhere in
`knk-api-client`. If you're debugging intermittent auth failures after the
server's been up a long time, this is the first place to look — the fix
isn't in this codebase yet, it would need to be built.

## Known rough edges (see the scan report for full citations)

- `PlayerListener` and `UserAccountListener` both fire on player
  join/quit and both send welcome messages — a player currently gets two.
  `PlayerListener`'s own class comment says it's legacy and
  `UserAccountListener` is the current path.
- `PlayerListener.onItemPickup` cancels *all* item pickup server-wide,
  unconditionally, with no explanation. Don't assume this is intentional
  game design without checking with the developer first.
- `PlayerListener.onPlayerRespawn` is a TODO'd stub — it fetches data but
  never actually sets a custom respawn location.
- `PaperGateControlAdapter` (a *different*, simpler gate concept than the
  main gate-structure-animation system) has stub `openGate`/`closeGate`
  methods that just log. Don't confuse it with the real gate system in
  `gates/GateManager.java` and friends, which is fully implemented.
- `WorldGuardManagementCommand` exists but is never registered anywhere —
  don't spend time trying to find how to invoke it; it's dead.
- There's a stray committed `.class` file at repo root
  (`net/knightsandkings/knk/api/client/KnkApiClient.class`) — ignore it,
  it's a build-artifact accident, not something you should reference or
  build against.

## Where the siege minigame actually stands

Gate structures (breakable/animated doors with health, fire, pass-through)
are fully implemented and the most mature subsystem in the plugin — but
that is not the siege minigame. There is no capture-point, team, scoring,
or win-condition code anywhere in this repo; `CachedGateStructure` has
inert `currentSiegeId`/`isSiegeObjective` fields and nothing else. If
you're picking up siege-minigame work, gate structures are the foundation
to build on, not a feature to check off — see the parity table in
`docs/reports/plugin-scan-2026-09-21.md` §2 before scoping siege work.

## Building, testing, deploying

See `CLAUDE.md` for the authoritative command list. Quick reference:
`./gradlew build` / `./gradlew test` (integration/`requires-bukkit` tests
excluded by default) / `./gradlew :knk-paper:dev` to build+deploy the
shadow jar to the local dev server (path set by `devServerDirectory` in
`gradle.properties`).

## Also check

- `docs/specs/` in this workspace for feature-specific design docs (e.g.
  `gate-structure-animation/PHASE_STATUS.md` tracks per-phase completion
  for the gate work in far more detail than this guide).
- `docs/ACTIVE_SESSIONS.md` before starting — most features here span
  `knk-web-api` and sometimes `knk-web-app` too, so check for overlapping
  in-flight work before claiming a task.
- The plugin repo's own root-level status docs (`ARCHITECTURE_AUDIT.md`,
  `PHASE_1_COMPLETION.md`, `STATUS_V2_BASELINE.md`, etc.) are self-authored
  progress notes — useful for history, but treat their claims as claims to
  verify against current code rather than ground truth (this scan found at
  least one stale doc, `.github/copilot-instructions.md`, making that
  exact mistake about GUI/menu support).
