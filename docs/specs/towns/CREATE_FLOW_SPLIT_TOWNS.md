# Create Flow Split: Towns/Districts/Streets/Structures/Regions

**Purpose**: Document the split between Web App/API orchestration and Plugin world-bound execution for domination entity creation.

**Status**: TBD – Specification outline awaiting implementation detail.

---

## Overview

### Architecture Principle
- **Web App / Web API**: Orchestrates creation workflow, manages business/data state, database persistence
- **Minecraft Plugin**: Executes world-bound operations only (WorldGuard region creation, Bukkit Location binding)
- **Async Coordination**: API creates record in `PendingWorldBinding` status → Plugin executes `WorldTask` → API finalizes to `Active`

### Entities in Scope
1. **Town**
2. **District**
3. **Street**
4. **Structure**
5. **Region** (indirectly via `wgRegionId` / `regionName` in parent Dominion)

---

## 1. Input Split Per Entity

### 1.1 Town

#### A) Business/Data Inputs (Web App → API POST /api/Towns)

**From Swagger `TownDto`:**
- `name` (required, string)
- `description` (string)
- `allowEntry` (boolean)
- `allowExit` (boolean)
- `streetIds` (array of int, optional foreign keys)
- `districtIds` (array of int, optional foreign keys)

**API-side actions:**
- Validate name uniqueness (if required by contract)
- Create/update `Town` entity
- Persist to database

**Status after API create**: `PendingWorldBinding`

#### B) World-Bound Inputs/Outputs (Plugin)

**WorldGuard Region Binding:**
- **Input**: Minecraft Selection (from WorldEdit, or predefined coords)
- **Processing**: 
  - Create WorldGuard `ProtectedRegion` in the Minecraft world
  - Return: `wgRegionId` (region key/name from WorldGuard)
- **Output**: Store `wgRegionId` in Town record (maps to legacy `regionName` / Dominion.`wg_region_id`)

**Minecraft Location Binding:**
- **Input**: Minecraft Location (world, x, y, z, yaw, pitch) from player position or explicit input
- **Processing**:
  - Create or reuse `Location` entity (from Swagger `LocationDto`)
  - Populate: `world`, `x`, `y`, `z`, `yaw`, `pitch`
- **Output**: Store `locationId` in Town record

**Optional: WorldEdit Selection Handling**
- If user selects region in WorldEdit before plugin interaction: parse selection geometry (TBD – no swagger field yet)

---

### 1.2 District

#### A) Business/Data Inputs (Web App → API POST /api/Districts)

**From Swagger `DistrictDto`:**
- `name` (required, string)
- `description` (string)
- `allowEntry` (boolean)
- `allowExit` (boolean)
- `townId` (required, int – foreign key to Town)
- `streetIds` (array of int, optional – many-to-many via Street)

**API-side actions:**
- Validate `townId` exists
- Validate name uniqueness within town (if required)
- Create/update `District` entity
- Link to parent `Town`
- Persist to database

**Status after API create**: `PendingWorldBinding`

#### B) World-Bound Inputs/Outputs (Plugin)

**WorldGuard Region Binding:**
- **Input**: Minecraft Selection (from WorldEdit, or predefined coords)
- **Processing**:
  - Create WorldGuard `ProtectedRegion` in the Minecraft world
  - Optionally set parent region to parent Town's `wgRegionId` (hierarchical)
  - Return: `wgRegionId`
- **Output**: Store `wgRegionId` in District record

**Minecraft Location Binding:**
- **Input**: Minecraft Location (typically center or spawn point of district)
- **Processing**:
  - Create or reuse `Location` entity
  - Populate: `world`, `x`, `y`, `z`, `yaw`, `pitch`
- **Output**: Store `locationId` in District record

---

### 1.3 Street

#### A) Business/Data Inputs (Web App → API POST /api/Streets)

**From Swagger `StreetDto`:**
- `name` (required, string)
- `districtIds` (array of int – many-to-many with District)

**API-side actions:**
- Validate name uniqueness (if required)
- Create/update `Street` entity
- Link to Districts via join table (`Street_Districts`)
- Persist to database

**Status after API create**: `PendingWorldBinding` (if world-bound features required, else `Active`)

#### B) World-Bound Inputs/Outputs (Plugin)

**Legacy note**: Street does not explicitly hold `regionName` or `Location` in legacy code (SOURCES_TOWNS.md). 
- **Current assumption**: Street is purely data-level organizational entity, not tied to world regions.
- **TBD**: Clarify if Streets require WorldGuard region binding or Location binding in v2 spec.

**If world-bound is needed**:
- Repeat region/location pattern as District

---

### 1.4 Structure

#### A) Business/Data Inputs (Web App → API POST /api/Structures)

**From Swagger `StructureDto`:**
- `name` (required, string)
- `description` (string)
- `allowEntry` (boolean)
- `allowExit` (boolean)
- `districtId` (required, int – foreign key)
- `streetId` (required, int – foreign key)
- `houseNumber` (int – optional street number)

**API-side actions:**
- Validate `districtId`, `streetId` exist
- Validate uniqueness of `(streetId, houseNumber)` (legacy constraint from Dominion)
- Create/update `Structure` entity
- Link to District, Street, and optionally Town (if computed)
- Persist to database

**Status after API create**: `PendingWorldBinding`

#### B) World-Bound Inputs/Outputs (Plugin)

**WorldGuard Region Binding:**
- **Input**: Minecraft Selection (from WorldEdit, or explicit coords)
- **Processing**:
  - Create WorldGuard `ProtectedRegion` in the Minecraft world
  - Optionally set parent region to parent District's `wgRegionId` (hierarchical)
  - Return: `wgRegionId`
- **Output**: Store `wgRegionId` in Structure record

**Minecraft Location Binding:**
- **Input**: Minecraft Location (e.g., main door or center block)
- **Processing**:
  - Create or reuse `Location` entity
  - Populate: `world`, `x`, `y`, `z`, `yaw`, `pitch`
- **Output**: Store `locationId` in Structure record

---

### 1.5 Region

#### A) Business/Data Inputs

**Legacy context**: 
- No standalone `Region` entity class in legacy (SOURCES_TOWNS.md: "NOT FOUND").
- Region is represented as `regionName` (String, `@NaturalId`) on each `Dominion` subclass.
- In Swagger: `wgRegionId` (string) field appears in `TownDto`, `DistrictDto`, `StructureDto`.

**Assumption**: 
- Regions are ephemeral, managed by WorldGuard plugin.
- Not created via API; only referenced by `wgRegionId`.

#### B) World-Bound

- Region creation handled implicitly when Town/District/Structure create their WorldGuard regions (see sections above).
- No separate "Region" entity to create in API; only binding of region IDs.

---

## 2. Hybrid Create Flow Per Entity

### Generic Flow Template

```
User in Web App
      ↓
[1] Web App sends POST /api/{Entity} with business/data fields
      ↓
[2] API validates, creates record with status PendingWorldBinding
      ↓
[3] API returns entity with id + empty wgRegionId / locationId fields
      ↓
[4] Plugin receives WorldTask (via queue, WebSocket, or polling)
      ↓
[5] Plugin executes world-bound steps:
    - Create WorldGuard region from user selection/input
    - Create Minecraft Location from player position / explicit coords
    - Populate wgRegionId, locationId
      ↓
[6] Plugin calls API PUT /api/{Entity}/{id} with wgRegionId + locationId
      ↓
[7] API validates, finalizes record status → Active
      ↓
[8] Done
```

### 2.1 Town Creation Flow

```
Sequence:
  1. API Create
     - POST /api/Towns { name, description, allowEntry, allowExit, streetIds, districtIds }
     - → Town created in database with status=PendingWorldBinding, wgRegionId=null, locationId=null
     - Response: { id, name, description, allowEntry, allowExit, wgRegionId: null, locationId: null, ... }

  2. WorldTask Created
     - Type: CreateTownWorldBinding
     - Entity ID: town.id
     - Required inputs: worldEditSelection (from plugin user, TBD)

  3. Plugin Execute
     - User in Minecraft makes WorldEdit selection (or plugin provides default)
     - Plugin creates WorldGuard ProtectedRegion named town.id (or derived name)
     - Plugin records returned wgRegionId from WorldGuard
     - Plugin resolves Minecraft Location (e.g., player standing location or region center)
     - Plugin calls API PUT /api/Towns/{id} { wgRegionId: "town_123", locationId: 456 }

  4. API Finalize
     - PUT /api/Towns/{id}
     - Validate wgRegionId + locationId provided
     - Update Town: status=Active
     - Response: { id, name, ..., wgRegionId, locationId, ..., status: "Active" }

  5. Done
     - Town now has both worldguard and location bindings
```

### 2.2 District Creation Flow

Similar to Town:
```
  1. API Create → PendingWorldBinding
  2. WorldTask for region + location binding
  3. Plugin:
     - Create ProtectedRegion (optionally as child of parent Town's region)
     - Create Location
     - PUT /api/Districts/{id} { wgRegionId, locationId }
  4. API Finalize → Active
```

### 2.3 Street Creation Flow

**TBD**: Clarify if Street needs world-bound binding.

**If NO world-bound binding**:
```
  1. API Create → Active (no PendingWorldBinding)
  2. No WorldTask
```

**If YES** (future): Repeat Town/District pattern.

### 2.4 Structure Creation Flow

Similar to Town:
```
  1. API Create → PendingWorldBinding
  2. WorldTask for region + location binding
  3. Plugin:
     - Create ProtectedRegion (optionally as child of parent District's region)
     - Create Location
     - PUT /api/Structures/{id} { wgRegionId, locationId }
  4. API Finalize → Active
```

---

## 3. Legacy Mapping: Where Do Existing Steps Go?

### From Legacy Creation Flow (SOURCES_TOWNS.md context)

**Legacy Town Creation** (inferred from class structure):
1. **UI Step**: User enters name, description, allowEntry, requiredTitle
2. **World Step**: User makes WorldEdit selection
3. **Plugin Step**: Create ProtectedRegion in WorldGuard
4. **Plugin Step**: Bukkit Location setup (from player or explicit coords)
5. **Persist Step**: Save Town + Location + regionName to database

### Mapping to New Split

| Legacy Step | New Location | Notes |
|---|---|---|
| User enters name, description, allowEntry | **API (business input)** | Web Form → POST /api/Towns |
| User makes WorldEdit selection | **Plugin (world input)** | Captured during Plugin WorldTask execution |
| Create ProtectedRegion in WorldGuard | **Plugin (world execution)** | WorldTask handler, calls WorldGuard API |
| Bukkit Location setup | **Plugin (world execution)** | WorldTask handler, captures player location or coords |
| Save to database | **API (finalize)** | PUT /api/Towns/{id} with wgRegionId + locationId |

### Validation Distribution

| Validation | API or Plugin? | Rationale |
|---|---|---|
| Name uniqueness | **API** | Database constraint, checked before PendingWorldBinding |
| Name length | **API** | Swagger `TownDto` schema validation |
| allowEntry/allowExit valid (boolean) | **API** | Type validation in DTO |
| wgRegionId format valid | **Plugin + API** | Plugin verifies during creation; API verifies during finalize |
| Location coords valid (world exists, coords in bounds) | **Plugin** | Minecraft-world specific, plugin checks with Bukkit API |
| Town must not be deleted while pending | **API** | Soft-delete or lock during PendingWorldBinding |

---

## 4. API Endpoints & DTOs

### 4.1 Create Endpoints

**POST /api/Towns**
- **Request**: `TownDto` (business inputs)
- **Response**: `TownDto` + status `PendingWorldBinding`

**POST /api/Districts**
- **Request**: `DistrictDto` (business inputs)
- **Response**: `DistrictDto` + status `PendingWorldBinding`

**POST /api/Streets**
- **Request**: `StreetDto`
- **Response**: `StreetDto` + status (depends on world-bound requirement: TBD)

**POST /api/Structures**
- **Request**: `StructureDto` (business inputs)
- **Response**: `StructureDto` + status `PendingWorldBinding`

### 4.2 Finalize Endpoints

**PUT /api/Towns/{id}**
- **Request**: `TownDto` with wgRegionId + locationId populated
- **Response**: `TownDto` + status `Active`

**PUT /api/Districts/{id}**
- Similar pattern

**PUT /api/Structures/{id}**
- Similar pattern

### 4.3 DTO Fields (Swagger Contract)

**TownDto** (from swagger.json):
```
{
  id: int (nullable, generated by API)
  name: string (required)
  description: string (nullable)
  createdAt: datetime (nullable, generated by API)
  allowEntry: boolean (nullable)
  allowExit: boolean (nullable)
  wgRegionId: string (nullable, filled by Plugin)
  locationId: int (nullable, filled by Plugin)
  location: LocationDto (nullable, populated by API on read)
  streetIds: array<int> (nullable, client provides or API fills)
  streets: array<TownStreetDto> (nullable, API-populated)
  districtIds: array<int> (nullable, client provides or API fills)
  districts: array<TownDistrictDto> (nullable, API-populated)
}

LocationDto:
{
  id: int (nullable, generated by API)
  name: string (nullable)
  x: double (nullable)
  y: double (nullable)
  z: double (nullable)
  yaw: float (nullable)
  pitch: float (nullable)
  world: string (nullable)
}
```

**DistrictDto** (similar pattern):
```
{
  id: int
  name: string
  description: string
  createdAt: datetime
  allowEntry: boolean
  allowExit: boolean
  wgRegionId: string (nullable, filled by Plugin)
  locationId: int (nullable, filled by Plugin)
  location: LocationDto (nullable)
  townId: int (required)
  streetIds: array<int> (nullable)
  town: DistrictTownDto (API-populated)
  streets: array<DistrictStreetDto> (API-populated)
  structures: array<DistrictStructureDto> (API-populated)
}
```

**StructureDto** (similar pattern):
```
{
  id: int
  name: string
  description: string
  createdAt: datetime
  allowEntry: boolean
  allowExit: boolean
  wgRegionId: string (nullable, filled by Plugin)
  locationId: int (nullable, filled by Plugin)
  streetId: int (required)
  districtId: int (required)
  houseNumber: int (required)
}
```

---

## 5. Status Enum (TBD)

**Proposed Status values** (for Dominion/Town/District/Structure):
- `PendingWorldBinding`: Created via API, waiting for Plugin to execute world steps
- `Active`: Fully created, worldguard + location bound
- `Archived` or `Deleted`: (future, out of scope for creation)

**Question**: Should status be a field on each DTO, or implicit? → TBD in API contract.

---

## 6. WorldTask Queue (TBD)

**Conceptual model**:
```
WorldTask {
  id: UUID
  entityType: enum { Town, District, Structure, ... }
  entityId: int
  taskType: enum { CreateBinding, UpdateBinding, DeleteBinding, ... }
  inputData: { 
    worldEditSelectionGeometry?: TBD
    suggestedLocationId?: int
    ... 
  }
  status: enum { Pending, InProgress, Completed, Failed }
  createdAt: datetime
  completedAt: datetime (nullable)
  errorMessage: string (nullable)
}
```

**Handoff mechanism**: TBD
- Option A: Plugin polls `/api/WorldTasks?status=Pending`
- Option B: API pushes via WebSocket
- Option C: Plugin cache/queue (local Minecraft persistence)

---

## 7. Remaining Unknowns & TBDs

### 7.1 Street World-Bound Binding
- **Question**: Does Street need wgRegionId / locationId in v2?
- **Legacy**: Street class has no regionName or Location fields
- **Action**: Clarify v2 spec. If no, mark Street as API-only create (status = Active immediately).

### 7.2 Region Entity in v2
- **Question**: Is there a standalone `/api/Regions` endpoint?
- **Legacy**: No Region model class; only regionName on Dominion.
- **Action**: Confirm Region is only managed implicitly via wgRegionId binding.

### 7.3 WorldEdit Selection Format
- **Question**: How does Plugin receive WorldEdit selection geometry from Web App?
- **Swagger**: No selection geometry field in DTOs yet.
- **Options**:
  - User provides coords directly in API: add minCoord, maxCoord to DTO
  - Plugin captures selection in Minecraft: use existing WorldEdit session
  - Hybrid: API stores region bounds, Plugin refines with selection
- **Action**: Define in next iteration.

### 7.4 Location ID Generation
- **Question**: Does API generate locationId, or does Plugin?
- **Current assumption**: API generates on first read after finalize; Plugin populates data.
- **Action**: Clarify contract.

### 7.5 Hierarchical Region Parenting
- **Question**: Should District ProtectedRegion be child of Town's ProtectedRegion in WorldGuard?
- **Legacy**: Not explicit in code.
- **Action**: Define world structure hierarchy in SPEC_TOWNS.md.

### 7.6 Concurrent World Operations
- **Question**: What if two plugins/users try to create overlapping regions?
- **Action**: Define locking / conflict resolution strategy (TBD).

### 7.7 Timezone Handling
- **Swagger**: `createdAt` is ISO 8601 datetime. Confirm UTC.

### 7.8 allowExit Field
- **Swagger**: DistrictDto has `allowExit`; legacy Dominion does not explicitly show this.
- **Action**: Verify field exists in legacy or is new in v2.

---

## 8. Testing Strategy (TBD)

### Unit Tests (API)
- POST /api/Towns with valid DTO → status=PendingWorldBinding ✓
- POST /api/Towns with invalid name (duplicate, too long) → 400/409 ✓
- PUT /api/Towns/{id} without wgRegionId → 400 ✓
- PUT /api/Towns/{id} with wgRegionId + locationId → status=Active ✓

### Integration Tests (Plugin)
- Plugin receives WorldTask → creates ProtectedRegion ✓
- Plugin calls PUT /api/Towns/{id} → API finalizes ✓
- Concurrent world task execution → correct region hierarchy (TBD)

### E2E Tests
- User flow: Web App → API create → Plugin world binding → API finalize → Town visible in Minecraft ✓

---

## Appendix: Field Reference Summary

### Fields from Swagger vs. Legacy

| Entity | Field | Swagger Type | Legacy Source | API/Plugin |
|---|---|---|---|---|
| Town | id | int | Dominion.id | API (generated) |
| Town | name | string | Dominion.name | API |
| Town | description | string | Dominion.description | API |
| Town | createdAt | datetime | Dominion.created | API (generated) |
| Town | allowEntry | boolean | Dominion.allowEntry | API |
| Town | allowExit | boolean | TBD – Swagger only | API (TBD) |
| Town | wgRegionId | string | Dominion.regionName | Plugin |
| Town | locationId | int | Dominion.location (FK) | Plugin |
| Town | location | LocationDto | Dominion.location (entity) | API (join) |
| Town | requiredTitle | int | Town.requiredTitle | TBD – not in Swagger |
| District | id | int | Dominion.id | API (generated) |
| District | name | string | Dominion.name | API |
| District | wgRegionId | string | Dominion.regionName | Plugin |
| District | locationId | int | Dominion.location (FK) | Plugin |
| District | townId | int | District.town (FK) | API |
| Street | id | int | Street.id | API (generated) |
| Street | name | string | Street.name | API |
| Street | districtIds | array<int> | Street.districts (M2M) | API |
| Street | (no regionName) | N/A | Not in legacy | TBD |
| Structure | id | int | Dominion.id | API (generated) |
| Structure | name | string | Dominion.name | API |
| Structure | description | string | Dominion.description | API |
| Structure | wgRegionId | string | Dominion.regionName | Plugin |
| Structure | locationId | int | Dominion.location (FK) | Plugin |
| Structure | districtId | int | Structure.district (FK) | API |
| Structure | streetId | int | Structure.street (FK) | API |
| Structure | houseNumber | int | Structure.streetNumber | API |

---

**Document Version**: 0.1  
**Last Updated**: 2025-12-14  
**Status**: Draft – Awaiting implementation detail & v2 spec alignment
