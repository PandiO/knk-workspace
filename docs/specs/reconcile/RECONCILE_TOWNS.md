# Reconcile: TOWNS Subsystem

Source-grounded reconciliation across legacy and API contract.
Inputs:
- Legacy sources: knk/spec/SOURCES_TOWNS.md
- Legacy spec: knk-plugin-v2/spec/SPEC_TOWNS.md (with Hybrid Create Flow)
- Logic classification: knk-plugin-v2/spec/LOGIC_CANDIDATES_TOWNS.md
- API contract: knk-plugin-v2/spec/api/API_CONTRACT_TOWNS.md (+ swagger.json)

No assumptions or invented fields. All items are either in legacy sources or swagger. Otherwise marked TBD/NOT IN CONTRACT.

## MVP Scope (Now)
**READ-only**: GET list, GET by id, POST search for Town/District/Street/Structure via API client + Paper display commands.

**Out of scope**: Create/Update/Delete flows, WorldTasks/WorldBinding (region+location), interactive CreationStages, ownership/permissions.

---

## 1) Data Mapping (Per Entity)

### Town
- CONFIRMED-BY-API (from TownDto):
  - `id: integer(int32), nullable`
  - `name: string, nullable`
  - `description: string, nullable`
  - `createdAt: string(date-time), nullable`
  - `allowEntry: boolean, nullable`
  - `allowExit: boolean, nullable`
  - `wgRegionId: string, nullable`
  - `locationId: integer(int32), nullable`
  - `location: LocationDto`
  - `streetIds: array<int32>, nullable`
  - `streets: array<TownStreetDto>, nullable`
  - `districtIds: array<int32>, nullable`
  - `districts: array<TownDistrictDto>, nullable`
- LEGACY-ONLY (in SOURCES_TOWNS.md but NOT in TownDto):
  - `requiredTitle: Integer` (Town.java @Column)
  - `districts: List<District>` transient (legacy helper)
  - `structures: List<Structure>` transient deprecated (legacy helper)
  - `regionName: String` (Dominion natural id) — note: API uses `wgRegionId` instead
  - `created: Calendar` (legacy type) — note: API uses `createdAt` ISO string
- API-ONLY (in TownDto but NOT in SOURCES_TOWNS.md):
  - `allowExit: Boolean`
  - `streetIds`, `streets`, `districtIds`, `districts` (explicit DTO lists)
- TBD:
  - Relationship completeness for streets/districts on create (linking semantics)

### District
- CONFIRMED-BY-API (from DistrictDto):
  - `id: integer(int32), nullable`
  - `name: string, nullable`
  - `description: string, nullable`
  - `createdAt: string(date-time), nullable`
  - `allowEntry: boolean, nullable`
  - `allowExit: boolean, nullable`
  - `wgRegionId: string, nullable`
  - `locationId: integer(int32), nullable`
  - `location: LocationDto`
  - `townId: integer(int32)`
  - `streetIds: array<int32>, nullable`
  - `town: DistrictTownDto`
  - `streets: array<DistrictStreetDto>, nullable`
  - `structures: array<DistrictStructureDto>, nullable`
- LEGACY-ONLY:
  - `created: Calendar` (legacy type)
  - `regionName: String` (Dominion natural id) — API uses `wgRegionId`
  - `streets: List<Street>` transient
- API-ONLY:
  - `allowExit: Boolean`
  - DTO projections (`DistrictTownDto`, etc.)
- TBD:
  - Field inclusion toggles (`townFields`, `streetFields`, `structureFields`) behavior

### Street
- CONFIRMED-BY-API (from StreetDto):
  - `id: integer(int32), nullable`
  - `name: string, nullable`
  - `districtIds: array<int32>, nullable`
  - `districts: array<StreetDistrictDto>, nullable`
  - `structures: array<StreetStructureDto>, nullable`
- LEGACY-ONLY:
  - `towns: List<Town>` transient deprecated
  - `structures: List<Structure>` transient deprecated
- API-ONLY:
  - DTO projections (`StreetDistrictDto`, `StreetStructureDto`)
- TBD:
  - None (Street has no region/location fields in legacy or API)

### Structure
- CONFIRMED-BY-API (from StructureDto):
  - `id: integer(int32), nullable`
  - `name: string, nullable`
  - `description: string, nullable`
  - `createdAt: string(date-time), nullable`
  - `allowEntry: boolean, nullable`
  - `allowExit: boolean, nullable`
  - `wgRegionId: string, nullable`
  - `locationId: integer(int32), nullable`
  - `streetId: integer(int32)`
  - `districtId: integer(int32)`
  - `houseNumber: integer(int32)`
- LEGACY-ONLY:
  - `streetNumber: Integer` (legacy field name; maps to API `houseNumber`)
  - `town: Town` optional FK (legacy) — NOT present in StructureDto
  - `storages: List<Storage>` (one-to-many)
  - `deliveryStorage: Storage` (one-to-one)
  - `created: Calendar` (legacy type)
  - `regionName: String` — API uses `wgRegionId`
- API-ONLY:
  - `allowExit: Boolean`
- TBD:
  - Relationship enforcement for wilderness structures (town without district)

### Location
- CONFIRMED-BY-API (from LocationDto):
  - `id: integer(int32), nullable`
  - `name: string, nullable`
  - `x: number(double), nullable`
  - `y: number(double), nullable`
  - `z: number(double), nullable`
  - `yaw: number(float), nullable`
  - `pitch: number(float), nullable`
  - `world: string, nullable`
- LEGACY-ONLY:
  - Bukkit `World` type (legacy); API uses string world name
- API-ONLY:
  - None (fields map conceptually)
- TBD:
  - Location CRUD endpoints (not present)

### Region / Roles
- Regions: No standalone endpoints/schemas; represented by `wgRegionId` string on entities → CONFIRMED as field usage only
- Roles: NOT IN CONTRACT for Towns vertical (no relevant endpoints/schemas)

---

## 2) Flow Mapping (Hybrid Create)

### Town
- API Create (Step 1):
  - Set business fields: `name`, `description`, `allowEntry`, `allowExit` (if used), `streetIds`, `districtIds`
  - System fields: `createdAt` (server-generated)
  - World-bound placeholders: `wgRegionId=null`, `locationId=null`, `location=null`
- Plugin World-Bound Outputs (Step 3):
  - `wgRegionId` (WorldGuard region identifier) — from plugin region creation
  - `locationId` — from plugin location capture persisted via API
- API Finalize (Step 4):
  - Accept `wgRegionId`, `locationId`; set status Active

### District
- API Create (Step 1): `name`, `description`, `allowEntry`, `allowExit`, `townId`, `streetIds`; set `createdAt`; placeholders for `wgRegionId/location`
- Plugin Outputs (Step 3): `wgRegionId`, `locationId`
- API Finalize (Step 4): update with world-bound fields → Active

### Street
- API Create (Step 1): `name`, `districtIds`
- Plugin Outputs (Step 3): None (no world-bound fields)
- API Finalize (Step 4): None; Active at create

### Structure
- API Create (Step 1): `name`, `description`, `allowEntry`, `allowExit`, `streetId`, `districtId`, `houseNumber`; set `createdAt`; placeholders `wgRegionId/location`
- Plugin Outputs (Step 3): `wgRegionId`, `locationId`
- API Finalize (Step 4): update with world-bound fields → Active

---

## 3) Logic Mapping

### API-Candidate Rules Missing in API (Backlog)
- Name uniqueness on create for Town/District/Street (database/contract enforcement)
- Composite uniqueness `(streetId, houseNumber)` for Structure
- FK validation: `townId` (District), `districtId`/`streetId` (Structure)
- Input validation: name length (32), description length (256), requiredTitle (Town, legacy-only → confirm API adoption)
- Status handling: `PendingWorldBinding` → `Active` lifecycle (status field not in swagger → TBD if implicit)
- AllowExit behavior: present in DTOs; define validation/enforcement

### Plugin-Only Rules
- WorldGuard region creation from WorldEdit selection; naming `{entity}_{id}`; priority 11; flags (PVP=DENY, DENY_MESSAGE="")
- Location capture from player: `world`, `x`, `y`, `z`, `yaw`, `pitch`
- Region entry enforcement: deny/allow based on `allowEntry`
- Optional: Region overlap checks (WorldguardUtil.checkUniqueRegion) — policy TBD

### Shared Rules
- Location persistence handshake: Plugin captures, API stores, entity links on finalize

---

## Notes
- All data points are grounded in SOURCES_TOWNS.md and swagger.json.
- Fields not present in swagger are marked LEGACY-ONLY; fields not present in legacy are marked API-ONLY.
- Status fields and WorldTask are process concepts; not present in swagger → lifecycle handling is architectural (TBD in API if a status property is introduced).
