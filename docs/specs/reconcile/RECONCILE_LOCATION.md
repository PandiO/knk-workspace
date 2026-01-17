# Reconcile – Location

Bronnen:
- knk/spec/SOURCES_LOCATION.md
- spec/api/API_CONTRACT_LOCATION.md (met spec/api/swagger.json)

## MVP Scope (Now)
**READ-only**: GET location via embedded DTOs in Town/District/Structure; no direct Location endpoints in scope.

**Out of scope**: POST/PUT/DELETE /api/Locations, world→Location binding, Bukkit Location construction in-game.

## Confirmed Mapping

- API `LocationDto` ↔ Plugin (legacy) `Location` ↔ Bukkit `org.bukkit.Location`
  - `id` ↔ legacy `Location.id` (int) ↔ not present in Bukkit Location (managed by persistence)
  - `name` ↔ legacy `Location.getName()` returns "Location {id}"; no explicit name field persisted in legacy (DTO name is nullable)
  - `x` ↔ legacy `Location.X` (double) ↔ `org.bukkit.Location#getX()`
  - `y` ↔ legacy `Location.Y` (double) ↔ `org.bukkit.Location#getY()`
  - `z` ↔ legacy `Location.Z` (double) ↔ `org.bukkit.Location#getZ()`
  - `yaw` ↔ legacy `Location.Yaw` (float) ↔ `org.bukkit.Location#getYaw()`
  - `pitch` ↔ legacy `Location.Pitch` (float) ↔ `org.bukkit.Location#getPitch()`
  - `world` (string) ↔ legacy `Location.world` (org.bukkit.World, stored via `WorldConverter` using `World.getName()`) ↔ `org.bukkit.Location#getWorld().getName()`

- Endpoints using `LocationDto` (CRUD + search) align with legacy usage where many entities reference `location_id` and rebuild Bukkit `Location` on-demand from stored primitives.

## Normalization Rules

- World identifier:
  - API uses `world: string` only. Legacy stores world by name via converter.
  - No UUID or server identifier in swagger. If multiple servers/world instances are possible, this is a design gap (see TBD).

- Coordinate precision:
  - API `x/y/z` are `double`; legacy fields are `double`. No rounding specified in swagger.
  - Suggested normalization: preserve full precision; avoid rounding unless explicitly required by downstream logic. Mark as TBD for contract-level rounding rules.

- Rotation:
  - API `yaw/pitch` are `float` (nullable). Legacy `Yaw/Pitch` are stored as `float` and are required in DB but Bukkit allows default 0.
  - If API omits `yaw/pitch` (null), plugin must decide defaults when constructing Bukkit Location (likely 0f). This is a behavioral choice and should be confirmed (see TBD).

- Nullability handling:
  - API `LocationDto` marks all fields as `nullable: true`.
  - Legacy `Location` entity requires `world/x/y/z/yaw/pitch` in DB.
  - On ingest: plugin should validate required fields before persisting; reject incomplete DTOs or apply explicit defaults (to be decided; see TBD).

## TBD Questions

- World identity:
  - Swagger has only `world: string`. No `worldId`/`worldUuid`/`serverId`. Should the API add a canonical world identifier (UUID or namespace) to avoid ambiguity across servers or renamed worlds?

- Required fields:
  - API marks `x/y/z/yaw/pitch/world` as nullable. Should the API declare a required set for persisted locations? If not, what defaults should the plugin apply on missing values?

- Rotation defaults:
  - When `yaw/pitch` are null, should the plugin default to `0f` or reject the DTO? Document expected behavior and update API validation if needed.

- Name semantics:
  - `name` is nullable. Should name be optional metadata (display only), or enforced by API? Define constraints and usage (e.g., human-readable label).

- Cross-entity references:
  - Town/District/Domain DTOs include `locationId` and/or embedded `location`. When both are present, which source of truth should the client use? Confirm API behavior.

- Precision and serialization:
  - Any constraints on decimal precision for `x/y/z` over the wire? Should API standardize number formats to prevent locale issues?

Design gaps are explicitly noted above where swagger lacks a world concept beyond name.