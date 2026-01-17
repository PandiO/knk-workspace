# SPEC: Towns / Settlement System (Source-Grounded)

This specification is derived exclusively from:
- **SOURCES_TOWNS.md**: Confirmed entity fields from legacy code
- **Legacy implementation code**: Town.java, District.java, RegionListener.java, SelectionListener.java, creation stages

All domain concepts are grounded in actual source code. TBD sections identify gaps requiring stakeholder confirmation.

---

## Part A: Confirmed Domain Concepts

All fields and relations listed below are sourced from actual legacy codebase entities.

### Town (Source: `knk/src/main/java/net/knightsandkings/model/dominion/Town.java`)

**Confirmed Fields:**
- `id: Integer` (inherited from Dominion; @Id)
- `name: String` (inherited from Dominion; max 32 chars; set during creation stage)
- `description: String` (inherited from Dominion; max 256 chars; optional during creation stage)
- `created: Calendar` (inherited from Dominion; set at creation time)
- `allowEntry: Boolean` (inherited from Dominion; default true; set during creation stage; controls entry behavior)
- `location: Location` (inherited from Dominion; one-to-one, cascaded; set during creation stage)
- `regionName: String` (inherited from Dominion; unique natural key; WorldGuard region identifier; set at creation)
- `requiredTitle: Integer` (declared in Town; defaults to 1; set during creation stage as string input)
- `districts: List<District>` (@Transient; lazy-loaded via DistrictRepository; not directly persisted)
- `structures: List<Structure>` (@Transient, @Deprecated; cache/UI helper; not authoritative)

**Confirmed Relations:**
- One-to-one with `Location` (cascaded)
- One-to-many with `District` (soft relationship; loaded on demand)
- One-to-many with `Structure` (deprecated; unreliable)
- Reference to WorldGuard `ProtectedRegion` (transient; loaded via `regionName`)

**Constraints (from code):**
- Name must be unique (enforced via creation framework)
- Region name is a natural ID (unique, required; @NaturalId)

---

### District (Source: `knk/src/main/java/net/knightsandkings/model/dominion/District.java`)

**Confirmed Fields:**
- `id: Integer` (inherited from Dominion; @Id)
- `name: String` (inherited from Dominion; max 32 chars)
- `description: String` (inherited from Dominion; max 256 chars; optional)
- `created: Calendar` (inherited from Dominion; persisted timestamp)
- `allowEntry: Boolean` (inherited from Dominion; default true; set during creation stage)
- `location: Location` (inherited from Dominion; one-to-one, cascaded)
- `regionName: String` (inherited from Dominion; unique natural key)
- `town: Town` (declared in District; @ManyToOne(optional=false); required parent)
- `streets: List<Street>` (@Transient; many-to-many relationship via Street entity; lazy-loaded via StreetRepository)

**Confirmed Relations:**
- Many-to-one with `Town` (required parent; set during creation stage as selection)
- Many-to-many with `Street` (mapped in Street via join table `Street_Districts`)

**Constraints:**
- Must belong to a `Town`
- Name is unique within the database

---

### Street (Source: `knk/src/main/java/net/knightsandkings/model/dominion/Street.java`)

**Confirmed Fields:**
- `id: Integer` (@Id; persisted)
- `name: String` (@Column, nullable=false, unique=true)
- `districts: List<District>` (@ManyToMany via join table `Street_Districts`; persisted; can be selected/updated during creation)
- `towns: List<Town>` (@Deprecated, @Transient; derived from districts; not reliable)
- `structures: List<Structure>` (@Deprecated, @Transient; not persisted; unreliable)

**Confirmed Relations:**
- Many-to-many with `District` (via join table `Street_Districts`; bidirectional)
- Transient references to `Town` and `Structure` (deprecated; not authoritative)

**Constraints:**
- Name must be unique (enforced via @UniqueConstraint(columnNames={"name"}))

---

### Structure (Source: `knk/src/main/java/net/knightsandkings/model/dominion/Structure.java`)

**Confirmed Fields:**
- `id: Integer` (inherited from Dominion; @Id)
- `name: String` (inherited from Dominion; max 32 chars)
- `description: String` (inherited from Dominion; max 256 chars; optional)
- `created: Calendar` (inherited from Dominion; persisted timestamp)
- `allowEntry: Boolean` (inherited from Dominion; default true)
- `location: Location` (inherited from Dominion; one-to-one, cascaded)
- `regionName: String` (inherited from Dominion; unique natural key)
- `town: Town` (declared in Structure; @ManyToOne(optional=true); optional; set during structure creation/editing)
- `district: District` (declared in Structure; @ManyToOne(optional=true); optional; set during structure creation/editing)
- `street: Street` (declared in Structure; @ManyToOne(optional=true); optional; set during structure creation/editing)
- `streetNumber: Integer` (declared in Structure; optional; indicates position on a street)
- `storages: List<Storage>` (one-to-many, persisted; mapped by Structure; cascaded)
- `deliveryStorage: Storage` (one-to-one, optional; single designated storage for delivery)

**Confirmed Relations:**
- Optional many-to-one with `Town` (can be used for wilderness structures)
- Optional many-to-one with `District`
- Optional many-to-one with `Street` (with `streetNumber` for position)
- One-to-many with `Storage` (persisted, cascaded)
- One-to-one with `Storage` (designated delivery storage)

**Constraints:**
- Unique constraint: `(street_id, streetNumber)` — a structure can appear once per street at a given number
- Code comment (Structure.java, line 63): "A Structure can have a Town reference even without a District, for 'wilderness' structures controlled by a town"

---

### Location (Source: `knk/src/main/java/net/knightsandkings/model/location/Location.java`)

**Confirmed Fields:**
- `id: Integer` (@Id)
- `world: World` (Bukkit World; persisted via WorldConverter; non-nullable)
- `X: Double` (persisted)
- `Y: Double` (persisted)
- `Z: Double` (persisted)
- `Pitch: Float` (persisted; rotation pitch)
- `Yaw: Float` (persisted; rotation yaw)

**Purpose:**
- Central spawn/reference location for Dominion entities (Town, District, Structure)
- Supports safe teleportation logic (checks air/snow blocks; avoids occupied spaces)

---

## Part B: Confirmed User Flows (LEGACY-ONLY — Will Be Replaced)

**Status:** This section documents legacy creation flows for reference. These flows will be replaced by the **Hybrid Create Flow (Part B.1)** in target architecture.

**Rationale for Change:** 
- Legacy flows combine business logic and world-bound operations in a single blocking flow, executed entirely in the Minecraft plugin
- New hybrid architecture separates concerns: Web API orchestrates business data, Plugin executes only world-bound operations (WorldGuard region binding, Minecraft Location setup)
- Benefits: async API, reusable by external tools, cleaner separation, non-blocking plugin UX

Flows derived from legacy `getCreationStages()` methods and event handlers.

### Town Creation Flow (Legacy)
**Source: Town.java, getCreationStages() (line 285+), createInstance() (line 73+)**

Stages (in order):
1. **Name Input** (mandatory)
   - Player types town name
   - Field: `name: String` (Dominion.NAME_LENGTH = 32)
   - Source: CreationStageString

2. **Description Input** (optional)
   - Player types town description
   - Field: `description: String` (Dominion.DESCRIPTION_LENGTH = 256)
   - Source: CreationStageString

3. **Region Selection** (mandatory)
   - Player uses WorldEdit wand to define region (polygonal/cuboid)
   - Saves region to WorldGuard
   - Field: `regionName: String` (persisted as natural ID)
   - Source: CreationStageRegion

4. **Entry Permission** (optional)
   - Player chooses: allow/deny other players to enter
   - Field: `allowEntry: Boolean` (default Dominion.ALLOW_ENTRY_DEF = true)
   - Source: CreationStageBoolean

5. **Required Title** (optional)
   - Player enters minimum title level to enter town
   - Field: `requiredTitle: Integer` (default Town.REQUIRED_TITLE_DEF = 1)
   - Source: CreationStageString (input as string, converted to int)

6. **Location Selection** (mandatory)
   - Player stands at desired location and confirms
   - Field: `location: Location` (one-to-one, cascaded)
   - Source: CreationStageLocation

**Creation Execution (createInstance):**
- Generates new `id` via `createId()`
- Creates WorldGuard region named `town_<id>` (priority 11)
- Persists Town record to database
- On update: modifies existing Town, updates region if needed

**Observed Behavior:**
- Region creation uses Polygonal2DRegion (polygonal shapes)
- WorldGuard region is removed and re-added during creation
- Location is persisted with cascaded storage

---

### District Creation Flow (Legacy)
**Source: District.java, getCreationStages() (line 253+)**

Stages (in order):
1. **Town Selection** (mandatory)
   - Player selects parent Town from list
   - Field: `town: Town` (@ManyToOne(optional=false))
   - Source: CreationStageSelect

2. **Name Input** (mandatory)
   - Player types district name
   - Field: `name: String`
   - Source: CreationStageString

3. **Description Input** (optional)
   - Player types description
   - Field: `description: String`
   - Source: CreationStageString

4. **Region Selection** (mandatory)
   - Player defines region (similar to Town)
   - Field: `regionName: String`
   - Source: CreationStageRegion

5. **Entry Permission** (optional)
   - Same as Town
   - Field: `allowEntry: Boolean`
   - Source: CreationStageBoolean

6. **Location Selection** (mandatory)
   - Player stands at location and confirms
   - Field: `location: Location`
   - Source: CreationStageLocation

---

### Street Creation Flow (Legacy)
**Source: Street.java, getCreationStages() (line 314+)**

Stages (in order):
1. **Name Input** (mandatory)
   - Player types street name
   - Field: `name: String` (unique)
   - Source: CreationStageString

2. **District Selection** (optional, multiple)
   - Player selects 1+ districts this street passes through
   - Field: `districts: List<District>` (many-to-many)
   - Source: CreationStageSelect (max 10 districts)

---

### Region Entry/Exit Flow
**Source: Town.java onRegionEntered() (line 334+), onRegionLeft() (line 345+); RegionListener.java**

**On Player Region Entry:**
- Event: RegionEnteredEvent (from WorldGuard/wgevents)
- Lookup town/district by regionName
- Check `allowEntry: Boolean` field
- If allowed: send welcome message to player
- If denied: send denial message; cancel event (player cannot enter)
- Async execution via BukkitRunnable

**On Player Region Exit:**
- Event: RegionLeftEvent
- Lookup dominion by regionName
- Send farewell message
- Execution: async via BukkitRunnable

---

## Part B.1: Hybrid Create Flow (Target Architecture)

**Status:** Proposed new architecture for v2. See [CREATE_FLOW_SPLIT_TOWNS.md](CREATE_FLOW_SPLIT_TOWNS.md) for detailed specification.

**Core Principle:**
- **Web App / Web API**: Orchestrates creation workflow, validates business logic, persists to database
- **Minecraft Plugin**: Executes only world-bound operations (WorldGuard region creation, Minecraft Location binding)
- **Async Coordination**: Via `PendingWorldBinding` status and `WorldTask` queue

**Rationale:**
1. **Separation of Concerns**: Business logic (name, description, relationships) decoupled from world-bound logic (region creation, location setup)
2. **Non-Blocking API**: Web API can respond immediately; world-bound work handled asynchronously
3. **Reusability**: API endpoints can be consumed by external tools (web portal, admin CLI) without requiring Minecraft plugin
4. **Scalability**: Plugin doesn't block on API/DB operations; can queue world tasks and execute in batches
5. **Testability**: API layer testable without Minecraft; Plugin world operations testable in isolation

### Hybrid Town Creation Flow

**Step 1: API Create (POST /api/Towns)**
- **Input**: Business data from Web App
  - `name: String` (from Swagger `TownDto`)
  - `description: String` (optional)
  - `allowEntry: Boolean` (optional)
  - `allowExit: Boolean` (optional, from Swagger)
  - `streetIds: Array<int>` (optional, pre-existing streets)
  - `districtIds: Array<int>` (optional, pre-existing districts)
- **API Action**:
  - Validate `name` uniqueness
  - Validate `name` length (max 32 chars, from Dominion.NAME_LENGTH)
  - Validate `description` length (max 256 chars, from Dominion.DESCRIPTION_LENGTH)
  - Create `Town` entity in database with status `PendingWorldBinding`
  - Initialize `location: Location` as null (to be filled by Plugin)
  - Initialize `regionName: String` as null (to be filled by Plugin)
- **Response**: `TownDto` with:
  - `id: int` (generated by API)
  - `wgRegionId: null` (pending plugin binding)
  - `locationId: null` (pending plugin binding)
  - `location: null` (pending plugin binding)
  - Status: `PendingWorldBinding`

**Step 2: WorldTask Created**
- **Type**: `CreateTownWorldBinding`
- **Entity**: Town with id from Step 1
- **Required Plugin Inputs**:
  - `worldEditSelection: Geometry` (from player WorldEdit wand, TBD format)
  - OR explicit `minCoord`, `maxCoord` (TBD in swagger)
  - OR default location from player standing location

**Step 3: Plugin Execute (Minecraft)**
- **Input**:
  - Town id
  - Minecraft world context
  - Player selection (from WorldEdit or default)
  - Player location (standing location)
- **Processing**:
  - Create `ProtectedRegion` in WorldGuard using player's selection
    - Name: `town_{id}` (convention from legacy)
    - Priority: 11 (from legacy)
    - Return: `wgRegionId` (region key from WorldGuard)
  - Create `Location` object capturing player's Minecraft location
    - Fields: `world`, `x`, `y`, `z`, `yaw`, `pitch` (from Swagger `LocationDto`)
    - Store to database via API call
    - Return: `locationId` (generated by API)
- **Output**:
  - `wgRegionId: String` (region identifier from WorldGuard)
  - `locationId: int` (location record id)

**Step 4: API Finalize (PUT /api/Towns/{id})**
- **Input**: World-bound data from Plugin
  - `wgRegionId: String` (region key from WorldGuard)
  - `locationId: int` (location id)
- **API Action**:
  - Validate `wgRegionId` not null
  - Validate `locationId` corresponds to valid Location entity
  - Update `Town` entity:
    - Set `regionName = wgRegionId`
    - Set `location.id = locationId`
    - Set status `Active`
- **Response**: `TownDto` with status `Active`

**Step 5: Done**
- Town is fully created with:
  - Business data (name, description, allowEntry, etc.)
  - WorldGuard region binding (`regionName` / `wgRegionId`)
  - Minecraft Location binding (`location` / `locationId`)
  - Status: `Active`

---

### Hybrid District Creation Flow

**Step 1: API Create (POST /api/Districts)**
- **Input**: Business data
  - `name: String` (from Swagger `DistrictDto`)
  - `description: String` (optional)
  - `allowEntry: Boolean` (optional)
  - `allowExit: Boolean` (optional, from Swagger)
  - `townId: int` (required, foreign key from Swagger)
  - `streetIds: Array<int>` (optional, many-to-many via Street)
- **API Action**:
  - Validate `townId` exists
  - Validate `name` uniqueness
  - Validate field lengths
  - Create `District` entity with status `PendingWorldBinding`
  - Initialize `regionName` and `location` as null
- **Response**: `DistrictDto` with `wgRegionId: null`, `locationId: null`, status `PendingWorldBinding`

**Step 2: WorldTask Created**
- **Type**: `CreateDistrictWorldBinding`
- **Entity**: District with id from Step 1
- **Required Plugin Inputs**: Same as Town (WorldEdit selection or explicit coords)

**Step 3: Plugin Execute**
- **Processing** (similar to Town):
  - Create `ProtectedRegion` in WorldGuard
    - Name: `district_{id}` (convention)
    - Optional: Set parent region to parent Town's `wgRegionId` (hierarchical nesting)
    - Return: `wgRegionId`
  - Create `Location` from player standing location
    - Return: `locationId`

**Step 4: API Finalize (PUT /api/Districts/{id})**
- **Input**: `wgRegionId`, `locationId`
- **Action**: Update District, set status `Active`
- **Response**: `DistrictDto` with status `Active`

---

### Hybrid Street Creation Flow

**Note from Legacy Context:**
- Street.java has NO `regionName` or `location` fields (SOURCES_TOWNS.md: Street is purely data-level)
- Street is purely organizational entity linking to Districts via many-to-many
- No world-bound requirements in legacy code

**Step 1: API Create (POST /api/Streets)**
- **Input**: Business data
  - `name: String` (from Swagger `StreetDto`, must be unique)
  - `districtIds: Array<int>` (optional, many-to-many via join table `Street_Districts`)
- **API Action**:
  - Validate `name` uniqueness
  - Create `Street` entity in database
  - Link to Districts via `Street_Districts` join table
  - Set status `Active` (no world-bound binding required)
- **Response**: `StreetDto` with status `Active`

**Step 2 onward:**
- **No WorldTask created** (Street requires no world binding)
- **No Plugin execution** needed
- **No finalize step**

**Summary**: Street creation is API-only in v2.

---

### Hybrid Structure Creation Flow

**Step 1: API Create (POST /api/Structures)**
- **Input**: Business data
  - `name: String` (from Swagger `StructureDto`)
  - `description: String` (optional)
  - `allowEntry: Boolean` (optional)
  - `allowExit: Boolean` (optional)
  - `streetId: int` (required, from Swagger)
  - `districtId: int` (required, from Swagger)
  - `houseNumber: int` (required, from Swagger, indicates street position)
- **API Action**:
  - Validate `streetId` and `districtId` exist
  - Validate uniqueness: `(streetId, houseNumber)` (legacy constraint from Structure.java)
  - Create `Structure` entity with status `PendingWorldBinding`
  - Initialize `regionName` and `location` as null
- **Response**: `StructureDto` with `wgRegionId: null`, `locationId: null`, status `PendingWorldBinding`

**Step 2: WorldTask Created**
- **Type**: `CreateStructureWorldBinding`
- **Entity**: Structure with id from Step 1
- **Required Plugin Inputs**: WorldEdit selection or explicit coords

**Step 3: Plugin Execute**
- **Processing** (similar to District):
  - Create `ProtectedRegion` in WorldGuard
    - Name: `structure_{id}` (convention)
    - Optional: Set parent region to parent District's `wgRegionId` (hierarchical)
    - Return: `wgRegionId`
  - Create `Location` from player location (e.g., main door or center block)
    - Return: `locationId`

**Step 4: API Finalize (PUT /api/Structures/{id})**
- **Input**: `wgRegionId`, `locationId`
- **Action**: Update Structure, set status `Active`
- **Response**: `StructureDto` with status `Active`

---

### Region Entity (Implicit, Not Standalone)

**Legacy Context:**
- No standalone `Region` model class (SOURCES_TOWNS.md: "NOT FOUND")
- Region represented indirectly as `regionName: String` (natural ID) on Dominion subclasses
- Swagger: `wgRegionId` field appears in `TownDto`, `DistrictDto`, `StructureDto`

**v2 Architecture:**
- Regions are **ephemeral**, managed by WorldGuard plugin
- Not created via dedicated API endpoint
- Implicitly created during Town/District/Structure world-binding steps
- Only referenced by `wgRegionId` in entity DTOs
- **No separate Region create flow**

---

### World-Bound Output Fields (From Swagger Contract)

All fields below are explicitly defined in Swagger `swagger.json`:

| Entity | Field | Type | Source | Filled By | Purpose |
|---|---|---|---|---|---|
| Town | `wgRegionId` | string | Swagger `TownDto` | Plugin | WorldGuard region identifier |
| Town | `locationId` | int | Swagger `TownDto` | Plugin | Location entity id |
| Town | `location` | LocationDto | Swagger `TownDto` | API (join) | Minecraft coordinates + world |
| District | `wgRegionId` | string | Swagger `DistrictDto` | Plugin | WorldGuard region identifier |
| District | `locationId` | int | Swagger `DistrictDto` | Plugin | Location entity id |
| District | `location` | LocationDto | Swagger `DistrictDto` | API (join) | Minecraft coordinates + world |
| Structure | `wgRegionId` | string | Swagger `StructureDto` | Plugin | WorldGuard region identifier |
| Structure | `locationId` | int | Swagger `StructureDto` | Plugin | Location entity id |
| Location | `world` | string | Swagger `LocationDto` | Plugin | Minecraft world name |
| Location | `x`, `y`, `z` | double | Swagger `LocationDto` | Plugin | Minecraft coordinates |
| Location | `yaw`, `pitch` | float | Swagger `LocationDto` | Plugin | Rotation (direction) |

**Note**: All fields listed above are explicitly defined in Swagger contract (spec/api/swagger.json). No fields invented; only those present in swagger are used.

---

## Region Entry/Exit Flow (Unchanged from Legacy)

## Part C: Confirmed Business Rules

Rules inferred from code logic and creation stage constraints.

### Region Management
- **Unique Region Names:** Each dominion has exactly one `regionName` (natural ID), mapped to a WorldGuard region
- **Region Creation:** Town creation auto-generates region named `town_<id>`; district generates `district_<id>`
- **Region Boundaries:** Derived from WorldEdit selection (polygonal or cuboid)
- **Entry Control:** Governed by `allowEntry: Boolean` field; checked at RegionEnteredEvent

### Hierarchy
- **Town > District:** A District must belong to exactly one Town (@ManyToOne(optional=false))
- **District > Street:** A Street can pass through multiple Districts (many-to-many)
- **Town/District/Street > Structure:** A Structure optionally references one of each

### Name Uniqueness
- **Town name:** Unique (enforced via creation framework)
- **District name:** Unique (enforced via creation framework)
- **Street name:** Unique (@UniqueConstraint(columnNames={"name"}))
- **Structure name:** Not explicitly constrained in code

### Location & Region
- **Mandatory:** Every dominion requires a `location` and `regionName`
- **Location persistence:** Cascaded; loaded with dominion
- **Region persistence:** `regionName` persisted; actual ProtectedRegion transient (loaded from WorldGuard at runtime)

### Structure Storage
- **Storages:** List<Storage> (one-to-many, cascaded); persisted in database
- **Delivery Storage:** Single designated Storage (@OneToOne, optional); used for delivery operations

---

## Part D: Confirmed Edge Cases & Behaviors

### Region Entry Denial
- **Scenario:** Player enters region of town with `allowEntry=false`
- **Behavior:** RegionEnteredEvent cancelled; player prevented from entering; denial message sent
- **Source:** Town.onRegionEntered() (line 339+)

### Deprecated/Transient Relations
- **Structure.structures:** Marked @Deprecated; not authoritative (can be null)
- **Street.towns:** Derived from districts; @Transient; not reliable for reverse lookups
- **Street.structures:** @Deprecated, @Transient; unreliable
- **Source:** Town.java (line 133), Street.java (line 81, 112)
- **Impact:** v2 must not rely on these for canonical data

### Optional District/Street in Structure
- **Town.structures:** Optional; marked deprecated
- **Structure.district:** Optional (@ManyToOne(optional=true)); structure can exist in Town without District (wilderness structures)
- **Structure.street:** Optional (@ManyToOne(optional=true)); street position is optional
- **Source:** Structure.java (line 73, 82, 92); comment (line 63-64)

### Creation as Async Operation
- **Town/District/Structure creation:** Processed via `createInstance()` method during creation session
- **WorldGuard interaction:** Synchronous (creates/removes WG regions during createInstance)
- **Database save:** Synchronous (Hibernate blocking)
- **Source:** Town.java createInstance() (line 73+), Dominion.java createInstance() (line 105+)

---

## Part E: TBD / Requires Confirmation

Concepts NOT found in source code; require stakeholder decision before v2 implementation.

### Player Ownership & Co-Ownership (NOT FOUND)
- **Issue:** No `ownerId`, `ownerUUID`, or `coOwners` field in Town
- **Current Implementation:** None in legacy code
- **Questions:**
  - Who can create/delete a town?
  - Can towns be transferred between players?
  - Is there a co-owner model (multiple players with admin rights)?
  - Is ownership tracked at all, or only via `requiredTitle` threshold?

### Explicit Role/Permission Model (NOT FOUND)
- **Issue:** No `Role`, `Permission`, or `RoleAssignment` entity
- **Related Concept Found:** `Grade` class exists (separate entity; field `requiredTitle` gates entry)
- **Questions:**
  - Does `requiredTitle` represent a "minimum rank" or something else?
  - Are there builder/visitor/banned roles within a town?
  - How are block-level build permissions enforced (WorldGuard flags, custom logic)?

### Town Expansion / Multi-Region Support (NOT FOUND)
- **Issue:** Town.java has only single `regionName` (not a list)
- **Current Implementation:** One region per town
- **Questions:**
  - Can a town expand by adding additional regions?
  - Is there a tier/level system limiting town size?
  - Should districts be used as expansion mechanism instead?

### Town Statistics (NOT FOUND)
- **Issue:** No `stats`, `level`, `score`, or `populationEstimate` field
- **Current Implementation:** None in code
- **Questions:**
  - Are metrics (area, district count, structure count) computed on-the-fly or persisted?
  - Is there a ranking/scoring system?

### Audit Trail (NOT FOUND)
- **Issue:** No audit log or change history entity
- **Current Implementation:** None in code
- **Questions:**
  - Should town mutations (create/expand/delete) be logged?
  - Should actor/timestamp be captured for debugging and compliance?

### Deletion Behavior (NOT FOUND)
- **Issue:** No explicit deletion confirmation or cascade behavior defined
- **Current Implementation:** Unknown
- **Questions:**
  - What happens to districts/structures when a town is deleted?
  - Is there a soft-delete (mark inactive) or hard-delete?
  - Should there be a two-step confirmation for delete?

---

## Part F: Non-Functional Observations (Legacy Patterns)

**Threading Model (Anti-Pattern in Legacy):**
- Town creation: Blocking (Hibernate ORM, WorldGuard API)
- Region entry/exit: Async via BukkitRunnable (but still blocking on DB lookup)
- No CompletableFuture or structured async boundary

**Caching:**
- Hibernate 2nd-level cache attempted but disabled (ProtectedRegion not serializable)
- District/Street lists lazy-loaded on demand (N+1 query risk)

**WorldGuard Coupling:**
- Direct ProtectedRegion manipulation in createInstance()
- Region state loaded transient at runtime (decouples persistence from WG)

---

## Summary

This spec is entirely grounded in confirmed source entities and flows. All 5 major entities (Town, District, Street, Structure, Location) are documented with verbatim fields and relationships from legacy code. User flows are extracted from creation stage definitions and event handlers. Gaps (Ownership, Roles, Expansion, Stats, Audit, Deletion) have been identified as TBD and must be clarified with stakeholders before v2 implementation.
