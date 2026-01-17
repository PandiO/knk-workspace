# Logic Candidates: TOWNS Subsystem

**Purpose**: Identify legacy business logic for the TOWNS subsystem (Town, District, Street, Structure) and classify each rule/feature as:
- **A) Web API**: Cross-client rules, persistence invariants, validation, permissions/ownership, uniqueness constraints
- **B) Plugin-Only**: Minecraft world interactions (WorldGuard/WorldEdit, block checks, world state)
- **C) Shared Core Service**: Pure domain logic usable by both Plugin and API

**Scope**: Legacy knk repository → knk-plugin-v2 architecture
**Based On**: SOURCES_TOWNS.md, legacy code, SPEC_TOWNS.md

---

## Part 1: Field/Property Constraints & Validation

### 1.1 Name Field (All Entities)

| Entity | Field | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town | `name: String` | Dominion.java, line 192 | Max 32 chars (NAME_LENGTH constant) | **A) API** — Validate length; enforce uniqueness at API level via database constraint |
| District | `name: String` | Dominion.java, line 192 | Max 32 chars | **A) API** — Validate length; enforce uniqueness at API level |
| Street | `name: String` | Street.java | Max 32 chars (inferred); unique (enforced via @UniqueConstraint) | **A) API** — Validate length; enforce unique constraint at API level |
| Structure | `name: String` | Dominion.java, line 192 | Max 32 chars | **A) API** — Validate length; uniqueness NOT enforced (unlike Streets) |

**Rationale**:
- Legacy constraints are declarative (column length, @UniqueConstraint) → database-level responsibility
- In v2, API layer must validate before persisting
- Plugin never validates names (doesn't create them; only receives via API)

**Implication for Hybrid Flow**:
- API create (Step 1): Validate name length + uniqueness
- No plugin involvement in validation

---

### 1.2 Description Field (Town, District, Structure)

| Entity | Field | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town | `description: String` | Dominion.java, line 193 | Max 256 chars (DESCRIPTION_LENGTH) | **A) API** — Validate length |
| District | `description: String` | Dominion.java, line 193 | Max 256 chars | **A) API** — Validate length |
| Street | `description: String` | Street.java | NOT FOUND in swagger or legacy code | **A) API TBD** — Clarify if Street has description in v2 |
| Structure | `description: String` | Dominion.java, line 193 | Max 256 chars | **A) API** — Validate length |

**Rationale**:
- Simple string length validation; applicable pre-persistence
- No world dependency

**Implication for Hybrid Flow**:
- API create: Validate description length
- Plugin: Never touches description

---

### 1.3 Entry/Exit Permissions

| Entity | Fields | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town, District, Structure | `allowEntry: Boolean` | Dominion.java, line 196 | Defaults to true (ALLOW_ENTRY_DEF = true) | **A) API** — Validate boolean type; store default |
| Town, District, Structure | `allowExit: Boolean` (nullable) | Swagger `TownDto`, `DistrictDto`, `StructureDto` | Presence in swagger; not in legacy code | **A) API TBD** — Clarify if allowExit is new in v2 or computed |
| Town, District, Structure | **Entry enforcement** | Town.onRegionEntered() (line 334+) | Check `allowEntry` flag; deny/allow based on flag | **B) Plugin** — Intercept RegionEnteredEvent; check allowEntry flag |

**Rationale**:
- `allowEntry` is data (boolean flag) → API layer stores/validates
- **Entry enforcement logic** is world-bound (Bukkit event listener) → Plugin layer

**Implication for Hybrid Flow**:
- API create: Accept allowEntry, store in PendingWorldBinding entity
- API finalize: allowEntry already persisted; no change during finalize
- Plugin: **Doesn't create/validate allowEntry**, only enforces it at runtime via RegionEnteredEvent listener

---

### 1.4 Required Title (Town-Specific)

| Entity | Field | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town | `requiredTitle: Integer` | Town.java, line 167 (@Column, default=1) | Default: 1; set as string input in CreationStageString (line 268) | **A) API** — Validate integer; accept from user; store default if omitted |

**Rationale**:
- `requiredTitle` is a permission threshold (Grade-based entry)
- Legacy input: CreationStageString (string → int conversion)
- No world dependency; purely business logic

**Implication for Hybrid Flow**:
- API create: Accept requiredTitle; validate integer
- Plugin: Ignores requiredTitle during world-binding
- Plugin runtime: May enforce requiredTitle during region entry (if implemented) — separate from create flow

---

### 1.5 Created Timestamp

| Entity | Field | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town, District, Structure | `created: Calendar` | Dominion.java, line 194 (@Column, non-nullable) | Set at creation time via Calendar.getInstance() | **A) API** — Generate timestamp server-side; never accept from client |

**Rationale**:
- Timestamp is system-generated at creation; no user input
- Prevents backdating/falsification

**Implication for Hybrid Flow**:
- API create: Generate `created = Calendar.getInstance()` (UTC)
- Plugin: Never involved with timestamps

---

## Part 2: Relationship Constraints

### 2.1 District → Town (Foreign Key)

| Relationship | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| District.town | District.java, line 115 (@ManyToOne(optional=false)) | Required; must reference existing Town | **A) API** — Validate townId exists; reject if null |

**Rationale**:
- A District cannot exist without a parent Town (enforced by @ManyToOne(optional=false))
- Referential integrity check → database responsibility

**Implication for Hybrid Flow**:
- API create (Step 1): Validate townId exists; fail if not
- Plugin: Receives town_id in WorldTask; no validation needed

---

### 2.2 Structure → District, Street, Town (Optional Foreign Keys)

| Relationship | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Structure.district | Structure.java, line 82 (@ManyToOne(optional=true)) | Optional; structure can exist without district (wilderness structures) | **A) API** — Validate districtId exists if provided |
| Structure.street | Structure.java, line 92 (@ManyToOne(optional=true)) | Optional; structure can exist without street | **A) API** — Validate streetId exists if provided |
| Structure.town | Structure.java, line 73 (@ManyToOne(optional=true)); comment line 63+ | Optional; used for wilderness structures (NOT in dominion of a district) | **A) API** — Validate townId exists if provided |

**Rationale**:
- Flexibility for wilderness structures (e.g., farms, mines outside town boundaries)
- Each FK must reference valid entity if provided

**Implication for Hybrid Flow**:
- API create (Step 1): Validate all provided FKs exist
- Plugin: Receives FKs; no validation needed

---

### 2.3 Street ↔ District (Many-to-Many)

| Relationship | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Street.districts (M2M via join table `Street_Districts`) | Street.java, line 88 (@ManyToMany) | Streets can pass through multiple Districts; a District can have multiple Streets | **A) API** — Validate districtIds exist; manage join table via API |

**Rationale**:
- Join table is purely relational (no extra fields)
- Validation → referential integrity check

**Implication for Hybrid Flow**:
- API create (Street): Validate districtIds; populate join table
- API create (District): Can reference streetIds (if needed for initial linking)
- Plugin: Never modifies relationships

---

### 2.4 Structure ↔ Storage (One-to-Many + One-to-One)

| Relationship | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Structure.storages (1:N, cascaded) | Structure.java, line 140+ (@OneToMany, cascaded) | A Structure can have multiple Storages for different purposes | **A) API** — Out of scope for CREATE flow; relevant for post-creation operations |
| Structure.deliveryStorage (1:1, optional, cascaded) | Structure.java, line 150+ (@OneToOne, optional, cascaded) | A Structure can designate one Storage as delivery target | **A) API** — Out of scope for CREATE flow |

**Rationale**:
- Storage is a separate concern (inventory management)
- Not part of dominion creation flow; populated post-create

**Implication for Hybrid Flow**:
- Not involved in create steps
- Listed for completeness; creation flow skips this

---

## Part 3: Uniqueness & Natural Keys

### 3.1 Region Name (Natural ID)

| Entity | Field | Legacy Source | Constraint | Recommendation |
|---|---|---|---|---|
| Town, District, Structure | `regionName: String` (@NaturalId) | Dominion.java, line 219 (@NaturalId, @Column(name="wg_region_id")) | Unique across all dominions; maps to WorldGuard region ID | **A) API + B) Plugin split** |

**Legacy Behavior**:
- Town create: generates `town_<id>` and stores in `regionName`
- District create: generates `district_<id>` and stores in `regionName`
- Structure create: generates `structure_<id>` (inferred) and stores in `regionName`

**Implication for Hybrid Flow**:
- **API create (Step 1)**: Initialize `regionName = null` (not yet assigned)
- **Plugin execute (Step 3)**: Create WorldGuard region in Minecraft; return `wgRegionId` (e.g., "town_123")
- **API finalize (Step 4)**: Store `wgRegionId` → `regionName` (make it the natural key)
- **Constraint**: Must be unique; API layer enforces via database unique constraint on `regionName`

---

### 3.2 (Street ID, Structure Number) Composite Uniqueness

| Constraint | Legacy Source | Description | Recommendation |
|---|---|---|---|
| (street_id, streetNumber) unique | Structure.java, line 61 (@UniqueConstraint) | A structure can occupy at most one number on a given street | **A) API** — Validate composite uniqueness at API level before create |

**Rationale**:
- Ensures street addresses are unique (e.g., no two structures at "Main Street #5")
- Database constraint in legacy code

**Implication for Hybrid Flow**:
- API create (Step 1): If streetId + streetNumber provided, validate no duplicate exists
- Plugin: Never involved with this constraint

---

## Part 4: WorldGuard Region Management

### 4.1 Region Creation & Naming Convention

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| Town region | Town.java, line 85 (createInstance) | Generates `town_<id>`, Polygonal2DRegion, priority=11, flags={} | **B) Plugin** — Create region in Step 3 of hybrid flow |
| District region | District.java, line 85 (createInstance) | Generates `district_<id>`, Polygonal2DRegion, priority=11, flags={} | **B) Plugin** — Create region in Step 3 |
| Structure region | Structure.java (not found) | Inferred: `structure_<id>` (following pattern) | **B) Plugin** — Create region in Step 3 (TBD exact naming) |
| Dominion region flags | Dominion.java, line 150 (WG_REGION_FLAGS) | PVP=DENY, DENY_MESSAGE="" | **B) Plugin** — Apply flags during region creation |

**Region Priority Levels**:
- Dominion: priority 10
- Town: priority 11 (subclass override)
- District: priority 11

**Implication for Hybrid Flow**:
- **Plugin execute (Step 3)**:
  - Receive WorldEdit selection from player (or default from bounds)
  - Create ProtectedRegion (Polygonal2DRegion) with:
    - Name: `{entityType}_{id}` (e.g., "town_42")
    - Priority: 11 (for Town/District); 10 (for Dominion base)
    - Flags: PVP=DENY, DENY_MESSAGE=""
  - Add region to WorldGuard RegionManager
  - Return `wgRegionId`

---

### 4.2 Region Removal & Replacement

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| Replace on update | Town.java, line 82 (createInstance, update path) | If updating existing entity: removeRegion(old_id), then addRegion(new_region) | **B) Plugin** — Relevant for edit/update, NOT for create |

**Implication for Hybrid Flow**:
- **Create flow**: Region is new; no removal needed
- **Update flow** (future): Would involve removal + recreation

---

### 4.3 Region Intersection/Overlap Checks

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| checkUniqueRegion() | WorldguardUtil.java, line 177 | Checks if new region has no overlapping regions with given criteria (e.g., "town_", "structure_") | **B) Plugin TBD** — Should plugin check for region overlaps during creation? |

**Question**:
- Should Town creation fail if player selection overlaps existing Town region?
- Legacy code doesn't show explicit overlap check in creation flow (only checkUniqueRegion method exists)

**Recommendation for v2**:
- **TBD**: Define overlap policy in hybrid flow
- **Option 1**: Soft validation (warn user, allow override)
- **Option 2**: Hard validation (fail creation if overlap detected)
- **Option 3**: No validation (allow overlaps; WorldGuard will manage)

---

## Part 5: WorldEdit Selection & Location Binding

### 5.1 WorldEdit Selection (Region Geometry)

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| Region selection | Town.java, CreationStageRegion (line 285+) | Player uses WorldEdit wand to select; saved as ProtectedRegion | **B) Plugin** — Capture selection during Step 3 (WorldTask execution) |
| Selection type | Dominion.java, createInstance (line 113) | Polygonal2DRegion (can be cuboid or polygonal) | **B) Plugin** — Accept any WorldEdit selection type; convert to ProtectedRegion |

**Implication for Hybrid Flow**:
- **API create (Step 1)**: No selection involved; user hasn't selected yet
- **WorldTask (Step 2)**: Mark pending world-binding; wait for plugin
- **Plugin execute (Step 3)**:
  - Player provides WorldEdit selection (or plugin suggests default)
  - Create ProtectedRegion from geometry
  - Return `wgRegionId`

**TBD**: How does API/Plugin communicate selection?
- **Option A**: Player selects in Minecraft; plugin reads from WorldEdit API directly
- **Option B**: API stores selection geometry in WorldTask; plugin reads from there
- **Current assumption**: Option A (plugin has direct WorldEdit access)

---

### 5.2 Minecraft Location Binding

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| Location selection | Town.java, CreationStageLocation (line 287+) | Player stands at desired location and confirms | **B) Plugin** — Capture location during Step 3 |
| Location fields | Location.java | `world`, `X`, `Y`, `Z`, `Yaw`, `Pitch` | **B) Plugin** — Capture all fields from player location |
| Location persistence | Dominion.java, line 147 (@OneToOne, cascaded) | Location cascaded with Dominion entity | **A) API** — Store Location via API PUT call; return `locationId` |

**Implication for Hybrid Flow**:
- **Plugin execute (Step 3)**:
  - Capture player's current location: `world`, `x`, `y`, `z`, `yaw`, `pitch`
  - Create Location object with these values
  - **Call API POST /api/Locations** (or PUT as part of entity) to persist Location
  - Receive `locationId` from API
  - Return `locationId` to API finalize step
- **API finalize (Step 4)**:
  - Receive `locationId`
  - Link Location to Town/District/Structure via `location` one-to-one relationship

---

## Part 6: Region Entry/Exit Enforcement (Runtime Behavior)

**Note**: This is NOT part of the create flow, but documented for completeness.

### 6.1 Region Entry Event Handling

| Feature | Legacy Source | Behavior | Recommendation |
|---|---|---|---|
| RegionEnteredEvent | Town.java, onRegionEntered() (line 334+); RegionListener.java | Fired by WorldGuard when player enters region | **B) Plugin** — Intercept event, check allowEntry, send message/deny |
| allowEntry check | Town.java, onRegionEntered() (line 339+) | Read allowEntry flag from Dominion; if false, deny entry, send message | **B) Plugin** — Runtime enforcement |
| Message logic | Town.java, RG_ENTER_MSG_DEF, RG_ENTER_DENY_MSG_DEF | Format messages with color codes | **B) Plugin** — Send formatted messages to player |
| Async execution | Town.java, onRegionEntered() uses BukkitRunnable | Run event handling async to avoid blocking server | **B) Plugin** — Ensure async execution |

**Implication for Create Flow**:
- Create flow doesn't involve entry enforcement
- Enforcement only happens **post-create**, at runtime
- Data (`allowEntry` flag) is set during create; enforcement happens later

---

## Part 7: Creation Workflow (Legacy vs. Hybrid)

### 7.1 Legacy Creation Stages

| Stage | Legacy Source | Type | Business Logic | World Interaction |
|---|---|---|---|---|
| 1. Name Input | Town.java, getCreationStages() line 285+ (CreationStageString) | User Input | Capture name | None |
| 2. Description Input | line 286+ (CreationStageString) | User Input | Capture description | None |
| 3. Region Selection | line 287+ (CreationStageRegion) | User Input + World | Capture selection; validate region | **WorldEdit** |
| 4. Entry Permission | line 288+ (CreationStageBoolean) | User Input | Capture allowEntry flag | None |
| 5. Required Title | line 289+ (CreationStageString) | User Input | Capture and convert to int | None |
| 6. Location Selection | line 290+ (CreationStageLocation) | User Input + World | Capture player location | **Bukkit Location API** |
| 7. createInstance() | Town.java, line 73+ | Execution | Create WG region, persist to DB | **WorldGuard API, Database** |

### 7.2 Hybrid Create Flow (Proposed)

| Step | Layer | Type | Business Logic | World Interaction |
|---|---|---|---|---|
| 1. API Create | Web API | User Input (via HTTP) | Validate name, description, flags; create entity with status PendingWorldBinding | None |
| 2. WorldTask | Coordination | Queue Record | Create task record; wait for plugin | None |
| 3a. Plugin Region | Plugin | World Execution | Create ProtectedRegion from WorldEdit selection | **WorldEdit API, WorldGuard API** |
| 3b. Plugin Location | Plugin | World Execution | Capture player location; call API to persist | **Bukkit Location API, HTTP** |
| 4. API Finalize | Web API | Execution | Link region + location to entity; set status Active | None |

**Key Differences**:
- **Legacy**: All steps in one blocking flow in plugin
- **Hybrid**: Business steps (1) in API; world steps (3) in plugin; coordination (2, 4) between layers
- **Async**: Plugin doesn't block on API; can queue multiple world tasks

---

## Part 8: Classification Summary Table

| Feature | Legacy Location | Classification | Reasoning |
|---|---|---|---|
| Name validation (length) | Dominion.java:192 | **A) API** | Data constraint; no world dependency |
| Name uniqueness (Town/District) | Column DDL | **A) API** | Database constraint; cross-client rule |
| Street name uniqueness | Street.java @UniqueConstraint | **A) API** | Database constraint |
| Description validation (length) | Dominion.java:193 | **A) API** | Data constraint |
| allowEntry flag storage | Dominion.java:196 | **A) API** | Data; API stores, Plugin enforces at runtime |
| allowEntry enforcement | Town.onRegionEntered():339+ | **B) Plugin** | Bukkit event listener; world-bound |
| requiredTitle storage | Town.java:167 | **A) API** | Data; API stores |
| requiredTitle enforcement | TBD | **B) Plugin** | Runtime enforcement in region entry (if implemented) |
| Created timestamp | Dominion.java:194 | **A) API** | System-generated; server-side responsibility |
| District.town FK validation | District.java:115 | **A) API** | Referential integrity; API enforces |
| Structure.district/street/town FK validation | Structure.java:73,82,92 | **A) API** | Referential integrity; API enforces |
| (street_id, streetNumber) uniqueness | Structure.java:61 | **A) API** | Composite uniqueness constraint |
| Region name generation | Town.java:85 (town_<id>) | **B) Plugin** | World identifier; plugin creates region |
| Region flags (PVP=DENY) | Dominion.java:150 | **B) Plugin** | WorldGuard flags; plugin applies during region creation |
| Region creation (ProtectedRegion) | Dominion.createInstance():113+ | **B) Plugin** | World-bound; WorldGuard API |
| WorldEdit selection | CreationStageRegion | **B) Plugin** | World-bound; WorldEdit API |
| Location capture | CreationStageLocation | **B) Plugin** | World-bound; Bukkit Location |
| Location persistence | Dominion.java:147 | **C) Shared** | Data persistence; API stores, but Plugin initiates via API call |
| Region overlap checking | WorldguardUtil:177 | **B) Plugin TBD** | World-bound; policy TBD |
| Many-to-many (Street ↔ District) | Street.java:88 | **A) API** | Relational constraint; API manages join table |

---

## Part 9: Implications for Hybrid Create Flow

### 9.1 API Responsibilities (Step 1: Create)

1. **Validate name**: Length (32 chars max), uniqueness (for Town/District/Street)
2. **Validate description**: Length (256 chars max)
3. **Validate allowEntry**: Boolean type
4. **Validate requiredTitle**: Integer type (Town only)
5. **Validate FKs**: townId (District), districtId/streetId (Structure), etc.
6. **Validate composite keys**: (street_id, streetNumber) for Structure
7. **Create entity**: Set `regionName = null`, `location = null`, status = `PendingWorldBinding`
8. **Return**: EntityDto with pending world-bound fields

### 9.2 Plugin Responsibilities (Step 3: Execute)

1. **Create WorldGuard region**: From WorldEdit selection or default
   - Name: `{type}_{id}` (e.g., "town_42")
   - Priority: 11
   - Flags: PVP=DENY, DENY_MESSAGE=""
   - Return: `wgRegionId`
2. **Capture Minecraft location**: Player standing location or explicit coords
   - Fields: world, x, y, z, yaw, pitch
   - Persist via API call (POST /api/Locations or PUT entity)
   - Return: `locationId`
3. **Call API finalize**: PUT /api/{Entity}/{id} with `wgRegionId`, `locationId`

### 9.3 API Responsibilities (Step 4: Finalize)

1. **Validate inputs**: `wgRegionId` not null, `locationId` exists
2. **Link to entity**: Set `regionName = wgRegionId`, `location.id = locationId`
3. **Update status**: `PendingWorldBinding` → `Active`
4. **Return**: Full EntityDto with status Active

---

## Part 10: TBDs & Unknowns

| Item | Legacy Status | v2 Status | Impact |
|---|---|---|---|
| Street world-bound binding | No regionName/location in legacy | TBD in v2 | Does Street need wgRegionId/locationId? |
| Region overlap validation policy | No explicit check in legacy create | TBD in v2 | Allow overlaps? Warn? Fail? |
| allowExit field | Not in legacy code | Present in Swagger DTOs | New feature? Computed? Where enforced? |
| Explicit coords for region selection | Not in legacy (always player-driven) | TBD in v2 | Should API accept minCoord/maxCoord instead of player selection? |
| Structure region naming | Inferred as structure_<id> | TBD in v2 | Confirm naming convention from legacy or define in v2 spec |
| Wilderness structure validation | Optional district/town | TBD in v2 | Any special rules for structures outside districts? |
| WorldEdit selection geometry storage | Ephemeral (not persisted) | TBD in v2 | Should WorldTask store selection geometry for plugin? Or plugin reads directly from WorldEdit? |

---

## Summary

This document classifies TOWNS subsystem logic across three categories:

- **A) Web API** (15+ items): Name/description/flag validation, FK constraints, uniqueness, timestamps, relationship management
- **B) Plugin-Only** (8+ items): Region creation, location capture, WorldEdit interaction, entry enforcement, overlap checking (TBD)
- **C) Shared** (1 item): Location persistence (API stores; Plugin initiates)

The **hybrid create flow** cleanly separates:
- **Business logic** (API Step 1): Validation, entity creation, persistence
- **World-bound logic** (Plugin Step 3): Region/location setup, WorldEdit/Bukkit interaction
- **Coordination** (API Step 4): Linking and finalization

All classifications are grounded in legacy source code; no new rules invented.

---

**Document Version**: 0.1  
**Last Updated**: 2025-12-14  
**Status**: Draft – Ready for architecture review & implementation planning
