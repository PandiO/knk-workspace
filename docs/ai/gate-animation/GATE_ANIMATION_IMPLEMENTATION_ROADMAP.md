# Gate Animation System Implementation Roadmap

**Status**: Ready for Implementation  
**Created**: January 30, 2026  
**Total Estimated Effort**: 204-260 hours (25.5-32.5 days @ 8 hrs/day)

---

## Executive Summary

This roadmap provides a complete implementation plan for the Gate Animation System, a comprehensive feature that enables animated, block-based gates in Knights & Kings with support for multiple gate types (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS), diagonal orientations, and full integration with the existing domain/structure system, WorldGuard, and health/respawn mechanics.

**Key Deliverables:**
- ✅ Backend: Extended GateStructure entity + GateBlockSnapshot entity + full CRUD API
- ✅ Frontend: 6-step wizard for gate creation/editing + 3D preview widget
- ✅ Plugin: Animation engine + entity push system + WorldGuard sync + commands

**Success Criteria:**
- Functional: All 4 gate types work correctly, diagonal gates supported, entity push working
- Performance: 100 gates < 50 MB memory, 10 animating gates ≥ 18 TPS
- Quality: All tests passing, documentation complete

---

## Implementation Phases

### Phase 1: Foundation (Backend Data Model)
**Focus**: Database schema, entities, migrations  
**Effort**: 16-20 hours  
**Duration**: 2-2.5 days  
**Dependencies**: None

#### Tasks

**1.1 Database Schema Migration**
- [ ] Create migration file `{Timestamp}_AddGateAnimation.cs`
- [ ] Add new columns to `GateStructures` table:
  - `GateType`, `GeometryDefinitionMode`, `MotionType`
  - `AnimationDurationTicks`, `AnimationTickRate`
  - `AnchorPoint`, `ReferencePoint1`, `ReferencePoint2`
  - `GeometryWidth`, `GeometryHeight`, `GeometryDepth`
  - `SeedBlocks`, `ScanMaxBlocks`, `ScanMaxRadius`
  - `ScanMaterialWhitelist`, `ScanMaterialBlacklist`, `ScanPlaneConstraint`
  - `FallbackMaterialRefId`, `TileEntityPolicy`
  - `RotationMaxAngleDegrees`, `HingeAxis`
  - `LeftDoorSeedBlock`, `RightDoorSeedBlock`, `MirrorRotation`
- [ ] Create `GateBlockSnapshots` table with indexes
- [ ] Test migration (up and down)

**1.2 Update GateStructure Entity**
- [ ] Add all new properties to `GateStructure.cs`
- [ ] Add navigation property: `ICollection<GateBlockSnapshot> BlockSnapshots`
- [ ] Add EntityMetadata annotations for web app forms
- [ ] Add FallbackMaterial navigation property

**1.3 Create GateBlockSnapshot Entity**
- [ ] Create `GateBlockSnapshot.cs` in `Models/`
- [ ] Add properties: `Id`, `GateStructureId`, `RelativeX/Y/Z`, `MinecraftBlockRefId`, `SortOrder`
- [ ] Add navigation properties: `GateStructure`, `BlockRef`
- [ ] Add EntityMetadata annotations

**1.4 Update DbContext**
- [ ] Add `DbSet<GateBlockSnapshot> GateBlockSnapshots`
- [ ] Configure relationships (GateStructure → GateBlockSnapshot: 1:N)
- [ ] Configure cascade delete (delete gate → delete snapshots)

**Deliverable**: Database schema ready, entities defined, migration tested

---

### Phase 2: Backend Logic (Repository, Service, DTOs)
**Focus**: Data access layer, business logic, AutoMapper  
**Effort**: 20-24 hours  
**Duration**: 2.5-3 days  
**Dependencies**: Phase 1

#### Tasks

**2.1 Create DTOs**
- [ ] Create `GateStructureDtos.cs` in `DTOs/`:
  - `GateStructureReadDto` (all fields)
  - `GateStructureCreateDto` (creation fields)
  - `GateStructureUpdateDto` (editable fields)
  - `GateStructureNavDto` (minimal for navigation)
- [ ] Create `GateBlockSnapshotDtos.cs`:
  - `GateBlockSnapshotDto` (read)
  - `GateBlockSnapshotCreateDto` (bulk create)

**2.2 Create Repository**
- [ ] Create `IGateStructureRepository.cs` interface in `Repositories/Interfaces/`
- [ ] Implement `GateStructureRepository.cs` in `Repositories/`:
  - `GetAllAsync()` with filtering (by domain, district, gate type, isActive)
  - `GetByIdAsync(int id)`
  - `GetByNameAsync(string name, int domainId)`
  - `CreateAsync(GateStructure gate)`
  - `UpdateAsync(GateStructure gate)`
  - `DeleteAsync(int id)`
  - `GetSnapshotsAsync(int gateId)`
- [ ] Add unit tests for repository

**2.3 Create Service**
- [ ] Create `IGateStructureService.cs` interface in `Services/Interfaces/`
- [ ] Implement `GateStructureService.cs` in `Services/`:
  - Business logic for create/update/delete
  - Cascade rules: delete gate → delete snapshots
  - Validation: ensure valid FaceDirection, GateType, etc.
  - Snapshot management: bulk create, clear all
- [ ] Add unit tests for service

**2.4 AutoMapper Profile**
- [ ] Create `GateStructureMappingProfile.cs` in `Mapping/`
- [ ] Add mappings:
  - `GateStructure` ↔ `GateStructureReadDto`
  - `GateStructure` ↔ `GateStructureCreateDto`
  - `GateStructure` ↔ `GateStructureUpdateDto`
  - `GateBlockSnapshot` ↔ `GateBlockSnapshotDto`
- [ ] Include navigation properties (FallbackMaterial, etc.)

**Deliverable**: Repository, service, DTOs, AutoMapper profiles complete

---

### Phase 3: Backend API (Controller & Endpoints)
**Focus**: REST API endpoints, validation, error handling  
**Effort**: 12-16 hours  
**Duration**: 1.5-2 days  
**Dependencies**: Phase 2

#### Tasks

**3.1 Create Controller**
- [ ] Create `GateStructuresController.cs` in `Controllers/`
- [ ] Implement CRUD endpoints:
  - `GET /api/gates` (list with pagination, filtering)
  - `GET /api/gates/{id}` (get by ID)
  - `POST /api/gates` (create)
  - `PUT /api/gates/{id}` (update)
  - `DELETE /api/gates/{id}` (delete)
  - `GET /api/gates/domain/{domainId}` (get by domain)
- [ ] Implement state management:
  - `PUT /api/gates/{id}/state` (update IsOpened)
- [ ] Implement snapshot operations:
  - `GET /api/gates/{id}/snapshots` (get all snapshots)
  - `POST /api/gates/{id}/snapshots/bulk` (create snapshots)
  - `DELETE /api/gates/{id}/snapshots` (clear snapshots)

**3.2 Add Validation**
- [ ] Validate FaceDirection (must be one of 8 values)
- [ ] Validate GateType (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS)
- [ ] Validate MotionType (VERTICAL, LATERAL, ROTATION)
- [ ] Validate AnimationDurationTicks > 0
- [ ] Validate HealthCurrent ≤ HealthMax

**3.3 Error Handling**
- [ ] Add try-catch blocks with appropriate status codes
- [ ] Return 404 for not found
- [ ] Return 400 for validation errors
- [ ] Return 500 for server errors

**3.4 Integration Tests**
- [ ] Test gate creation (POST /api/gates)
- [ ] Test gate retrieval (GET /api/gates/{id})
- [ ] Test gate update (PUT /api/gates/{id})
- [ ] Test gate deletion (DELETE /api/gates/{id})
- [ ] Test snapshot operations

**Deliverable**: Fully functional API endpoints with validation and error handling

---

### Phase 4: Frontend Types & API Client
**Focus**: TypeScript types, API client methods  
**Effort**: 12-16 hours  
**Duration**: 1.5-2 days  
**Dependencies**: Phase 3

#### Tasks

**4.1 Create Types**
- [ ] Create `Repository/knk-web-app/src/types/gate.ts`:
  - `GateStructure` interface
  - `GateType` union type
  - `GeometryDefinitionMode` union type
  - `MotionType` union type
  - `FaceDirection` union type
  - `TileEntityPolicy` union type
  - `GateCreateRequest`, `GateUpdateRequest` interfaces
  - `GateBlockSnapshot` interface

**4.2 Create API Client**
- [ ] Create `Repository/knk-web-app/src/api/gateClient.ts`:
  - `getGates()` - fetch all gates
  - `getGateById(id)` - fetch by ID
  - `createGate(data)` - create new gate
  - `updateGate(id, data)` - update gate
  - `deleteGate(id)` - delete gate
  - `getGatesByDomain(domainId)` - filter by domain
  - `updateGateState(id, isOpened)` - update state
  - `getGateSnapshots(id)` - fetch snapshots
  - `createGateSnapshots(id, snapshots)` - bulk create
  - `clearGateSnapshots(id)` - clear all

**4.3 Test API Client**
- [ ] Unit tests for each API client method
- [ ] Mock API responses
- [ ] Test error handling

**Deliverable**: TypeScript types and API client ready for UI development

---

### Phase 5: Frontend UI (Wizard, List, Details)
**Focus**: React components for gate management  
**Effort**: 32-40 hours  
**Duration**: 4-5 days  
**Dependencies**: Phase 4

#### Tasks

**5.1 Gate List Page**
- [ ] Create `GateListPage.tsx` in `pages/`
- [ ] Display gates in table/grid format
- [ ] Columns: Name, Gate Type, Status (Open/Closed), Health, Actions
- [ ] Filter by domain, district, gate type
- [ ] Pagination
- [ ] Actions: View, Edit, Delete, Open/Close

**5.2 Gate Details Page**
- [ ] Create `GateDetailsPage.tsx` in `pages/`
- [ ] Display all gate properties
- [ ] Show block snapshot count
- [ ] Show current state (CLOSED/OPEN/DESTROYED)
- [ ] Actions: Edit, Delete, Open/Close, Recapture

**5.3 Gate Creation Wizard (6 Steps)**

**Step 1: Basic Info**
- [ ] Create `GateWizardStep1.tsx`
- [ ] Fields: Name, Domain, District, Street (optional)
- [ ] Icon material selector (searchable dropdown)
- [ ] Health settings: HealthMax, IsInvincible, CanRespawn, RespawnRateSeconds

**Step 2: Gate Type & Orientation**
- [ ] Create `GateWizardStep2.tsx`
- [ ] Gate type selector (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS)
- [ ] Face direction selector (8-way compass widget)
- [ ] Show recommended geometry mode per gate type
- [ ] Motion type selector (auto-selected based on gate type, editable)

**Step 3: Geometry Definition**
- [ ] Create `GateWizardStep3.tsx`
- [ ] **If PLANE_GRID:**
  - 3D coordinate inputs for AnchorPoint, ReferencePoint1, ReferencePoint2
  - Width/Height/Depth sliders
  - Live block count estimate
- [ ] **If FLOOD_FILL:**
  - Seed block coordinate(s) input
  - Scan limits: MaxBlocks, MaxRadius
  - Material whitelist/blacklist (searchable)
  - Plane constraint toggle

**Step 4: Animation Settings**
- [ ] Create `GateWizardStep4.tsx`
- [ ] Duration (seconds) → convert to ticks
- [ ] Tick rate (1-5)
- [ ] Rotation angle (if DRAWBRIDGE/DOUBLE_DOORS)
- [ ] Preview animation (visual simulation - future)

**Step 5: Advanced Options**
- [ ] Create `GateWizardStep5.tsx`
- [ ] Fallback material selector
- [ ] Tile entity policy dropdown
- [ ] WorldGuard region IDs (text input)

**Step 6: Review & Create**
- [ ] Create `GateWizardStep6.tsx`
- [ ] Summary of all settings
- [ ] Block snapshot preview (estimated count)
- [ ] "Create Gate" button
- [ ] API call: POST /api/gates

**5.4 Gate Edit Form**
- [ ] Create `GateEditPage.tsx`
- [ ] Load existing gate via GET /api/gates/{id}
- [ ] Populate form with current values
- [ ] Allow editing: Name, IsActive, HealthMax, AnimationDurationTicks, etc.
- [ ] Restrict editing: Id, DomainId, GateType (require recapture)
- [ ] Save changes: PUT /api/gates/{id}

**5.5 3D Preview Widget (Optional - Future)**
- [ ] Create `GatePreviewWidget.tsx` using Three.js
- [ ] Render gate blocks based on geometry definition
- [ ] Highlight selected blocks
- [ ] Animate preview (playback simulation)

**Deliverable**: Complete web app UI for gate management

---

### Phase 6: Plugin Core (API Client, Cache, Loader)
**Focus**: Load gates from API, cache in memory  
**Effort**: 20-24 hours  
**Duration**: 2.5-3 days  
**Dependencies**: Phase 3 (API must be ready)

#### Tasks

**6.1 API Client (Java)**
- [ ] Create `GateApiClient.java` in `knk-paper/src/main/java/com/knockoffrealms/knk/api/`
- [ ] Methods:
  - `getGates()` - fetch all gates
  - `getGate(int id)` - fetch by ID
  - `updateGateState(int id, boolean isOpened)` - persist state change
  - `getGateSnapshots(int id)` - fetch block snapshots

**6.2 Data Models (Java)**
- [ ] Create `GateStructureDto.java` in `dto/`
- [ ] Create `GateBlockSnapshotDto.java` in `dto/`
- [ ] Add JSON deserialization (Gson)

**6.3 CachedGate Model**
- [ ] Create `CachedGate.java` in `gate/`
- [ ] Fields: id, name, gateType, currentState, currentFrame, animationStartTime
- [ ] Precomputed: uAxis, vAxis, nAxis, motionVector, hingeAxis
- [ ] Blocks: List<BlockSnapshot>

**6.4 GateManager**
- [ ] Create `GateManager.java` in `gate/`
- [ ] Load gates from API on plugin startup
- [ ] Cache gates in memory (HashMap<Integer, CachedGate>)
- [ ] Precompute local basis vectors (u, v, n)
- [ ] Precompute motion vectors
- [ ] Load block snapshots and sort by SortOrder

**6.5 Coordinate Parsing**
- [ ] Create `CoordinateParser.java` in `util/`
- [ ] Parse JSON: `{x, y, z}` → `Vector`
- [ ] Handle arrays: `[{x,y,z}, ...]` → `List<Vector>`

**6.6 Plugin Startup**
- [ ] Hook `onEnable()` in main plugin class
- [ ] Initialize GateManager
- [ ] Load gates from API
- [ ] Log: "Loaded X gates from API"

**Deliverable**: Plugin can load and cache gates from API

---

### Phase 7: Plugin Animation Engine
**Focus**: Frame calculation, block placement, tick task  
**Effort**: 32-40 hours  
**Duration**: 4-5 days  
**Dependencies**: Phase 6

#### Tasks

**7.1 Frame Calculator**
- [ ] Create `GateFrameCalculator.java` in `gate/`
- [ ] Method: `calculateBlockPosition(CachedGate, BlockSnapshot, int frame)`
- [ ] **For VERTICAL/LATERAL:**
  - Linear interpolation: `closedPos + stepVector * frame`
- [ ] **For ROTATION:**
  - Rotation around hinge axis: `rotateAroundAxis(relativePos, hingeAxis, currentAngle)`

**7.2 Rotation Utility**
- [ ] Create `VectorMath.java` in `util/`
- [ ] Method: `rotateAroundAxis(Vector v, Vector axis, double angleDegrees)`
- [ ] Implement Rodrigues' rotation formula

**7.3 Block Placement System**
- [ ] Create `GateBlockPlacer.java` in `gate/`
- [ ] Method: `placeBlock(Location, BlockData)`
- [ ] Disable physics: `world.setBlockData(loc, blockData, false)`
- [ ] Handle fallback material if restoration fails

**7.4 Animation Tick Task**
- [ ] Create `GateAnimationTask.java` extends `BukkitRunnable`
- [ ] Run every tick (20 TPS)
- [ ] Iterate gates in OPENING/CLOSING state
- [ ] Calculate current frame based on elapsed ticks
- [ ] Update block positions using `GateFrameCalculator`
- [ ] Check if animation complete → finish animation

**7.5 State Machine**
- [ ] Implement state transitions in `GateManager`:
  - `openGate(int id)` → CLOSED → OPENING
  - `closeGate(int id)` → OPEN → CLOSING
  - `finishAnimation(CachedGate)` → OPENING → OPEN or CLOSING → CLOSED
- [ ] Persist state change to API: `updateGateState(id, isOpened)`

**7.6 Chunk Loading Check**
- [ ] Skip animation if gate chunk is unloaded
- [ ] Resume when chunk loads

**7.7 Frame Skip on Lag**
- [ ] Check server TPS
- [ ] If TPS < 15 and lag detected, jump to final position

**Deliverable**: Gates can open/close with smooth animation

---

### Phase 8: Plugin Entity Interaction
**Focus**: Entity push, collision prediction  
**Effort**: 16-20 hours  
**Duration**: 2-2.5 days  
**Dependencies**: Phase 7

#### Tasks

**8.1 Collision Predictor**
- [ ] Create `CollisionPredictor.java` in `gate/`
- [ ] Method: `predictCollision(CachedGate, Entity, int currentFrame) → int framesToCollision`
- [ ] Check next N frames
- [ ] Calculate block positions at each future frame
- [ ] Check if block bounding box intersects entity bounding box
- [ ] Return frames until collision (or MAX_VALUE if no collision)

**8.2 Entity Push System**
- [ ] Create `EntityPusher.java` in `gate/`
- [ ] Method: `pushEntity(Entity, CachedGate)`
- [ ] Calculate push direction from FaceDirection + GateType
- [ ] Apply velocity to entity: `entity.setVelocity(pushForce)`

**8.3 Integration in Animation Task**
- [ ] In `GateAnimationTask.run()`:
  - Get nearby entities (5-block radius)
  - For each entity, predict collision
  - If framesToCollision ≤ 2, push entity

**8.4 Testing**
- [ ] Test player push during gate opening
- [ ] Verify push occurs only when collision imminent
- [ ] Test multiple entities simultaneously

**Deliverable**: Entities are pushed away when gate collision imminent

---

### Phase 9: Plugin Commands & Events
**Focus**: Player commands, admin commands, event handlers  
**Effort**: 16-20 hours  
**Duration**: 2-2.5 days  
**Dependencies**: Phase 7

#### Tasks

**9.1 Player Commands**
- [ ] `/gate open <name>` - Open gate
  - Permission check: `knk.gate.open.<gateId>` or `knk.gate.open.*`
  - Trigger: `gateManager.openGate(id)`
- [ ] `/gate close <name>` - Close gate
  - Permission check: `knk.gate.close.<gateId>` or `knk.gate.close.*`
  - Trigger: `gateManager.closeGate(id)`
- [ ] `/gate info <name>` - Show gate status
  - Display: Name, Type, State, Health, IsActive
- [ ] `/gate list` - List nearby gates (within 50 blocks)

**9.2 Admin Commands**
- [ ] `/gate admin reload` - Reload gates from API
- [ ] `/gate admin health <name> <amount>` - Set gate health
- [ ] `/gate admin repair <name>` - Instant repair (HealthCurrent = HealthMax)
- [ ] `/gate admin tp <name>` - Teleport to gate anchor

**9.3 Event Handlers**
- [ ] `BlockBreakEvent` - Prevent break or damage gate
- [ ] `EntityExplodeEvent` - Apply damage if not invincible
- [ ] `PlayerInteractEvent` - Trigger open/close on click (optional)

**9.4 Permission Nodes**
- [ ] Register permissions in `plugin.yml`:
  - `knk.gate.open.*`
  - `knk.gate.close.*`
  - `knk.gate.admin`

**Deliverable**: Complete command system and event handling

---

### Phase 10: WorldGuard & Health System
**Focus**: Region integration, health/respawn  
**Effort**: 12-16 hours  
**Duration**: 1.5-2 days  
**Dependencies**: Phase 7

#### Tasks

**10.1 WorldGuard Integration**
- [ ] Add WorldGuard dependency to `build.gradle.kts`
- [ ] Create `WorldGuardIntegration.java` in `integration/`
- [ ] Method: `syncRegions(CachedGate, AnimationState newState)`
  - If OPEN: Disable RegionClosedId, Enable RegionOpenedId
  - If CLOSED: Enable RegionClosedId, Disable RegionOpenedId
- [ ] Hook in `finishAnimation()`

**10.2 Health System**
- [ ] Implement damage handling in `EntityExplodeEvent`:
  - Find gate by block
  - If IsInvincible, cancel explosion
  - Else, apply damage: `HealthCurrent -= damageAmount`
  - If HealthCurrent ≤ 0, destroy gate
- [ ] Method: `destroyGate(CachedGate)`:
  - Set IsDestroyed=true, IsActive=false, IsOpened=false
  - Remove all gate blocks
  - Persist to API
  - If CanRespawn, schedule respawn

**10.3 Respawn System**
- [ ] Schedule task after `RespawnRateSeconds * 20` ticks
- [ ] Method: `respawnGate(CachedGate)`:
  - Set HealthCurrent=HealthMax, IsDestroyed=false, IsActive=true
  - Restore all blocks
  - Persist to API
  - Broadcast: "Gate <name> has respawned!"

**Deliverable**: WorldGuard integration and health/respawn system complete

---

### Phase 11: Testing & Optimization
**Focus**: Unit tests, integration tests, performance testing  
**Effort**: 32-44 hours  
**Duration**: 4-5.5 days  
**Dependencies**: All phases

#### Tasks

**11.1 Backend Unit Tests**
- [ ] Test GateStructure entity validation
- [ ] Test DTO mapping (AutoMapper)
- [ ] Test repository CRUD operations
- [ ] Test service cascade rules
- [ ] Test controller endpoints

**11.2 Frontend Unit Tests**
- [ ] Test gate type selector
- [ ] Test coordinate input parsing
- [ ] Test form validation (wizard steps)
- [ ] Test API client methods

**11.3 Plugin Unit Tests**
- [ ] Test coordinate parsing
- [ ] Test local basis calculation
- [ ] Test frame-to-position calculation (linear)
- [ ] Test frame-to-position calculation (rotation)
- [ ] Test collision prediction
- [ ] Test entity push direction calculation

**11.4 Integration Tests**
- [ ] Test gate creation (web app → API → database)
- [ ] Test animation state sync (plugin → API)
- [ ] Test gate open/close (command → animation → state update)
- [ ] Test WorldGuard region sync

**11.5 Functional Testing (In-Game)**
- [ ] TC-001: Basic gate open/close (SLIDING)
- [ ] TC-002: Diagonal gate (PLANE_GRID)
- [ ] TC-003: Drawbridge rotation
- [ ] TC-004: Double doors (FLOOD_FILL)
- [ ] TC-005: Entity push
- [ ] TC-006: Health & respawn

**11.6 Performance Testing**
- [ ] TC-101: Load 100 gates, measure memory (<50 MB)
- [ ] TC-102: Animate 10 gates, measure TPS (≥18)
- [ ] TC-103: Animate 20 gates, measure TPS (≥15)

**11.7 Edge Case Testing**
- [ ] TC-201: Chunk unload during animation
- [ ] TC-202: Server restart mid-animation
- [ ] TC-203: Block break in gate area
- [ ] TC-204: Concurrent access (two players open simultaneously)

**11.8 Optimization**
- [ ] Profile plugin memory usage
- [ ] Optimize block placement (batched chunk updates)
- [ ] Optimize collision detection (reduce entity scan radius if needed)

**Deliverable**: Fully tested and optimized gate animation system

---

## Risk Management

### High-Risk Areas

**1. Diagonal Gate Geometry Calculation**
- **Risk**: Local basis vectors calculated incorrectly
- **Mitigation**: Unit tests with known inputs/outputs, visual preview in web app
- **Fallback**: Manual geometry definition if auto-calculation fails

**2. Block Collision During Rotation**
- **Risk**: Multiple blocks map to same position, causing "holes" or missing blocks
- **Mitigation**: Stable sort order (SortOrder field), last-write-wins strategy
- **Testing**: Rotate large drawbridge, verify no missing blocks

**3. Entity Push Performance**
- **Risk**: Collision prediction too expensive, causes lag
- **Mitigation**: Limit entity scan radius (5 blocks), optimize prediction algorithm
- **Fallback**: Disable entity push if TPS < 15

**4. Server Restart Mid-Animation**
- **Risk**: Gate stuck in mid-frame position
- **Mitigation**: Persist only IsOpened (CLOSED/OPEN), reset to final state on restart
- **Testing**: Restart server during animation, verify gate state

**5. Fluid/Gravity Physics During Animation**
- **Risk**: Water flows or gravel falls when gate blocks removed
- **Mitigation**: Disable physics during block updates, check adjacent fluids
- **Testing**: Place gate near water, verify no flooding

---

## Success Metrics

### Functional Success
- ✅ All 4 gate types (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS) functional
- ✅ Diagonal gates (all 8 FaceDirection values) working correctly
- ✅ Block snapshots captured and restored accurately
- ✅ Entity push occurs only when collision imminent
- ✅ Health & respawn system functional
- ✅ WorldGuard integration working

### Performance Success
- ✅ 100 gates loaded: Plugin memory < 50 MB
- ✅ 10 gates animating: Server TPS ≥ 18
- ✅ 20 gates animating: Server TPS ≥ 15
- ✅ No server crash under stress

### Quality Success
- ✅ All unit tests passing (backend, frontend, plugin)
- ✅ All integration tests passing
- ✅ All edge case tests passing
- ✅ Documentation complete and accurate

---

## Rollback Plan

**If critical issues arise during deployment:**

1. **Disable Animation System**
   ```sql
   UPDATE GateStructures SET IsActive = FALSE;
   ```
   - Gates remain static, no animation

2. **Revert Plugin**
   - Deploy previous plugin version without animation
   - Gates function as static structures

3. **Database Rollback (if necessary)**
   ```sql
   ALTER TABLE GateStructures DROP COLUMN GateType;
   -- (drop all animation columns)
   DROP TABLE GateBlockSnapshots;
   ```

---

## Documentation Deliverables

- ✅ **Requirements**: [REQUIREMENTS_GATE_ANIMATION.md](../../specs/gate-structure/REQUIREMENTS_GATE_ANIMATION.md)
- ✅ **Specification**: [SPEC_GATE_ANIMATION.md](../../specs/gate-structure/SPEC_GATE_ANIMATION.md)
- ✅ **Quick Start**: [GATE_ANIMATION_QUICK_START.md](./GATE_ANIMATION_QUICK_START.md)
- ✅ **Roadmap**: This document
- ✅ **Index**: [INDEX.md](./INDEX.md)
- ⏳ **Visual Summary**: [VISUAL_SUMMARY_GATE_ANIMATION.md](./VISUAL_SUMMARY_GATE_ANIMATION.md) (future)
- ⏳ **Implementation Checklist**: [IMPLEMENTATION_CHECKLIST.md](./IMPLEMENTATION_CHECKLIST.md) (future)

---

**End of Roadmap**
