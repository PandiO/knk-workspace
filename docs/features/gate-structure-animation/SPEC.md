# Gate Animation System - Technical Specification

**Status**: Ready for Implementation  
**Created**: January 30, 2026  
**Last Updated**: January 31, 2026  
**Consolidated From**: `docs/ai/gate-animation/GATE_ANIMATION_QUICK_START.md`

---

## 📋 Quick Reference Summary

### Architecture Overview

The Gate Animation System is a server-tick-based animation framework that:
1. **Stores gate geometry** in the database (relative block coordinates via GateBlockSnapshot)
2. **Calculates animation frames at runtime** (no stored frames - computed from elapsed ticks)
3. **Places/removes blocks** based on current animation frame
4. **Predicts entity collisions** and moves entities away from animated blocks
5. **Syncs state bidirectionally** between plugin and API (IsOpened, HealthCurrent, IsDestroyed)

### Gate Type Reference

| Type | Motion | Geometry | Rotation | Best For |
|------|--------|----------|----------|----------|
| SLIDING | VERTICAL or LATERAL | PLANE_GRID | None | Portcullis, sliding walls |
| TRAP | VERTICAL | PLANE_GRID | None | Trap doors, pit covers |
| DRAWBRIDGE | ROTATION | PLANE_GRID | 90° | Castle drawbridges |
| DOUBLE_DOORS | ROTATION | FLOOD_FILL | 90° (mirrored) | Large doorways |

---

## 🔧 Detailed Component Specifications

### 1. Backend: Entity & Database Schema

#### GateStructure (Extended)

**Purpose**: Represents a single gate structure with all configuration needed for animation.

**Fields** (34 new fields + 13 existing):

```csharp
// === Core Identity (existing) ===
public int Id { get; set; }
public string Name { get; set; }
public int DomainId { get; set; }
public int DistrictId { get; set; }
public int? StreetId { get; set; }

// === State (existing) ===
public bool IsActive { get; set; } = false;  // Gate active in world?
public bool IsOpened { get; set; } = false;  // Currently open (persisted)
public bool IsDestroyed { get; set; } = false;  // Currently destroyed
public bool IsInvincible { get; set; } = true;  // Can be damaged?
public bool CanRespawn { get; set; } = true;  // Auto-repair?
public double HealthCurrent { get; set; } = 500.0;
public double HealthMax { get; set; } = 500.0;
public int RespawnRateSeconds { get; set; } = 300;  // Auto-repair delay

// === Orientation (existing + new) ===
public string FaceDirection { get; set; } = "north";  // 8 cardinal/diagonal directions

// === Gate Type Configuration (new) ===
public string GateType { get; set; } = "SLIDING";  // SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
public string MotionType { get; set; } = "VERTICAL";  // VERTICAL, LATERAL, ROTATION
public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";  // PLANE_GRID, FLOOD_FILL

// === Animation Timing (new) ===
public int AnimationDurationTicks { get; set; } = 60;  // Total frames (3 sec @ 20 TPS)
public int AnimationTickRate { get; set; } = 1;  // Update frequency (1=every tick, 2=every other)

// === PLANE_GRID Geometry (new) ===
public string AnchorPoint { get; set; } = string.Empty;  // JSON: "{x:100, y:64, z:100}"
public string ReferencePoint1 { get; set; } = string.Empty;  // JSON: "{x:105, y:64, z:100}"
public string ReferencePoint2 { get; set; } = string.Empty;  // JSON: "{x:100, y:69, z:100}"
public int GeometryWidth { get; set; } = 0;  // Blocks along u-axis (ReferencePoint1)
public int GeometryHeight { get; set; } = 0;  // Blocks along v-axis (ReferencePoint2)
public int GeometryDepth { get; set; } = 0;  // Blocks along n-axis (motion axis)

// === FLOOD_FILL Geometry (new) ===
public string SeedBlocks { get; set; } = string.Empty;  // JSON: "[{x:100,y:64,z:100}, ...]"
public int ScanMaxBlocks { get; set; } = 500;  // Limit on flood-fill scan
public int ScanMaxRadius { get; set; } = 20;  // Maximum distance from seed
public string ScanMaterialWhitelist { get; set; } = string.Empty;  // Only these blocks
public string ScanMaterialBlacklist { get; set; } = string.Empty;  // Exclude these blocks
public bool ScanPlaneConstraint { get; set; } = false;  // Scan only in plane?

// === Block Rendering (new) ===
public int? FallbackMaterialRefId { get; set; }  // Default block type if snapshot corrupted
public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";  // DECORATIVE_ONLY, CONTAINER_SAFE (v2)

// === Rotation (new - for DRAWBRIDGE/DOUBLE_DOORS) ===
public int RotationMaxAngleDegrees { get; set; } = 90;  // Max pivot angle
public string HingeAxis { get; set; } = string.Empty;  // JSON: "{x:0, y:0, z:1}" (normal vector)

// === Double Doors (new) ===
public string LeftDoorSeedBlock { get; set; } = string.Empty;  // JSON: "{x:100, y:64, z:100}"
public string RightDoorSeedBlock { get; set; } = string.Empty;  // JSON: "{x:102, y:64, z:100}"
public bool MirrorRotation { get; set; } = true;  // Left door: CCW, Right door: CW?

// === WorldGuard Integration (existing) ===
public string RegionClosedId { get; set; } = string.Empty;  // WG region when gate closed
public string RegionOpenedId { get; set; } = string.Empty;  // WG region when gate open

// === Relationships (existing + new) ===
public Domain Domain { get; set; } = null!;
public District District { get; set; } = null!;
public Street? Street { get; set; } = null;
public ICollection<GateBlockSnapshot> BlockSnapshots { get; set; } = new List<GateBlockSnapshot>();
```

**Database Table** (`GateStructures`):
```sql
-- Existing columns remain unchanged
-- New columns added:
GateType NVARCHAR(50) NOT NULL DEFAULT 'SLIDING'
MotionType NVARCHAR(50) NOT NULL DEFAULT 'VERTICAL'
GeometryDefinitionMode NVARCHAR(50) NOT NULL DEFAULT 'PLANE_GRID'
AnimationDurationTicks INT NOT NULL DEFAULT 60
AnimationTickRate INT NOT NULL DEFAULT 1
AnchorPoint NVARCHAR(MAX) NOT NULL DEFAULT ''
ReferencePoint1 NVARCHAR(MAX) NOT NULL DEFAULT ''
ReferencePoint2 NVARCHAR(MAX) NOT NULL DEFAULT ''
GeometryWidth INT NOT NULL DEFAULT 0
GeometryHeight INT NOT NULL DEFAULT 0
GeometryDepth INT NOT NULL DEFAULT 0
SeedBlocks NVARCHAR(MAX) NOT NULL DEFAULT ''
ScanMaxBlocks INT NOT NULL DEFAULT 500
ScanMaxRadius INT NOT NULL DEFAULT 20
ScanMaterialWhitelist NVARCHAR(MAX) NOT NULL DEFAULT ''
ScanMaterialBlacklist NVARCHAR(MAX) NOT NULL DEFAULT ''
ScanPlaneConstraint BIT NOT NULL DEFAULT 0
FallbackMaterialRefId INT NULL
TileEntityPolicy NVARCHAR(50) NOT NULL DEFAULT 'DECORATIVE_ONLY'
RotationMaxAngleDegrees INT NOT NULL DEFAULT 90
HingeAxis NVARCHAR(MAX) NOT NULL DEFAULT ''
LeftDoorSeedBlock NVARCHAR(MAX) NOT NULL DEFAULT ''
RightDoorSeedBlock NVARCHAR(MAX) NOT NULL DEFAULT ''
MirrorRotation BIT NOT NULL DEFAULT 1

-- Add foreign key
FOREIGN KEY (FallbackMaterialRefId) REFERENCES MinecraftMaterialRef(Id)

-- Add indexes
CREATE INDEX idx_gate_domain ON GateStructures(DomainId) WHERE IsActive=1
CREATE INDEX idx_gate_district ON GateStructures(DistrictId) WHERE IsActive=1
CREATE INDEX idx_gate_type ON GateStructures(GateType) WHERE IsActive=1
```

---

#### GateBlockSnapshot (New)

**Purpose**: Stores the relative block coordinates that make up a gate's structure.

**Fields**:
```csharp
public int Id { get; set; }

// Foreign key & navigation
public int GateStructureId { get; set; }
public GateStructure GateStructure { get; set; } = null!;

// Relative position (origin at AnchorPoint or seed block)
public int RelativeX { get; set; }
public int RelativeY { get; set; }
public int RelativeZ { get; set; }

// Block type (reference to MinecraftBlockRef for material/state)
[RelatedEntityField(typeof(MinecraftBlockRef))]
public int? MinecraftBlockRefId { get; set; }
public MinecraftBlockRef? BlockRef { get; set; } = null;

// Rendering order (important for hinge blocks in drawbridges)
public int SortOrder { get; set; }
```

**Database Table** (`GateBlockSnapshots`):
```sql
CREATE TABLE GateBlockSnapshots (
    Id INT PRIMARY KEY IDENTITY(1,1),
    GateStructureId INT NOT NULL,
    RelativeX INT NOT NULL,
    RelativeY INT NOT NULL,
    RelativeZ INT NOT NULL,
    MinecraftBlockRefId INT NULL,
    SortOrder INT NOT NULL DEFAULT 0,
    
    FOREIGN KEY (GateStructureId) REFERENCES GateStructures(Id) ON DELETE CASCADE,
    FOREIGN KEY (MinecraftBlockRefId) REFERENCES MinecraftBlockRef(Id) ON DELETE SET NULL
);

CREATE INDEX idx_snapshot_gate ON GateBlockSnapshots(GateStructureId)
CREATE CLUSTERED INDEX idx_snapshot_sort ON GateBlockSnapshots(GateStructureId, SortOrder)
```

**Relationships**:
- **One-to-Many**: One GateStructure has many GateBlockSnapshots
- **Cascade Delete**: Deleting a gate automatically deletes all its snapshots
- **Optional Reference**: MinecraftBlockRefId can be NULL (uses FallbackMaterial)

---

### 2. DTO Specifications

#### GateStructureReadDto
```csharp
public class GateStructureReadDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int DomainId { get; set; }
    public int DistrictId { get; set; }
    public int? StreetId { get; set; }
    
    // State
    public bool IsActive { get; set; }
    public bool IsOpened { get; set; }
    public bool IsDestroyed { get; set; }
    public bool IsInvincible { get; set; }
    public bool CanRespawn { get; set; }
    public double HealthCurrent { get; set; }
    public double HealthMax { get; set; }
    public string FaceDirection { get; set; } = string.Empty;
    public int RespawnRateSeconds { get; set; }
    
    // Animation
    public string GateType { get; set; } = string.Empty;
    public string GeometryDefinitionMode { get; set; } = string.Empty;
    public string MotionType { get; set; } = string.Empty;
    public int AnimationDurationTicks { get; set; }
    public int AnimationTickRate { get; set; }
    
    // Geometry
    public string AnchorPoint { get; set; } = string.Empty;
    public string ReferencePoint1 { get; set; } = string.Empty;
    public string ReferencePoint2 { get; set; } = string.Empty;
    public int GeometryWidth { get; set; }
    public int GeometryHeight { get; set; }
    public int GeometryDepth { get; set; }
    
    public string SeedBlocks { get; set; } = string.Empty;
    public int ScanMaxBlocks { get; set; }
    public int ScanMaxRadius { get; set; }
    public string ScanMaterialWhitelist { get; set; } = string.Empty;
    public string ScanMaterialBlacklist { get; set; } = string.Empty;
    public bool ScanPlaneConstraint { get; set; }
    
    public int? FallbackMaterialRefId { get; set; }
    public MinecraftMaterialRefNavDto? FallbackMaterial { get; set; }
    
    public string TileEntityPolicy { get; set; } = string.Empty;
    public int RotationMaxAngleDegrees { get; set; }
    public bool MirrorRotation { get; set; }
    
    public string RegionClosedId { get; set; } = string.Empty;
    public string RegionOpenedId { get; set; } = string.Empty;
    
    // Metadata
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class GateStructureCreateDto
{
    public string Name { get; set; } = string.Empty;
    public int DomainId { get; set; }
    public int DistrictId { get; set; }
    public int? StreetId { get; set; }
    
    public string GateType { get; set; } = "SLIDING";
    public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
    public string MotionType { get; set; } = "VERTICAL";
    public string FaceDirection { get; set; } = "north";
    
    public string AnchorPoint { get; set; } = string.Empty;
    public string ReferencePoint1 { get; set; } = string.Empty;
    public string ReferencePoint2 { get; set; } = string.Empty;
    public int GeometryWidth { get; set; } = 0;
    public int GeometryHeight { get; set; } = 0;
    public int GeometryDepth { get; set; } = 0;
    
    public string SeedBlocks { get; set; } = string.Empty;
    public int ScanMaxBlocks { get; set; } = 500;
    public int ScanMaxRadius { get; set; } = 20;
    
    public int AnimationDurationTicks { get; set; } = 60;
    public int AnimationTickRate { get; set; } = 1;
    
    public int? FallbackMaterialRefId { get; set; }
    public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";
    
    public double HealthMax { get; set; } = 500.0;
    public bool IsInvincible { get; set; } = true;
    public bool CanRespawn { get; set; } = true;
    public int RespawnRateSeconds { get; set; } = 300;
}

public class GateStructureUpdateDto
{
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public double HealthMax { get; set; }
    public bool IsInvincible { get; set; }
    public bool CanRespawn { get; set; }
    public int RespawnRateSeconds { get; set; }
    public int AnimationDurationTicks { get; set; }
    public int AnimationTickRate { get; set; }
    public string RegionClosedId { get; set; } = string.Empty;
    public string RegionOpenedId { get; set; } = string.Empty;
}

public class GateStructureNavDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string GateType { get; set; } = string.Empty;
    public bool IsOpened { get; set; }
    public double HealthCurrent { get; set; }
}
```

#### GateBlockSnapshotDto

```csharp
public class GateBlockSnapshotDto
{
    public int Id { get; set; }
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    public int? MinecraftBlockRefId { get; set; }
    public MinecraftBlockRefNavDto? BlockRef { get; set; }
    public int SortOrder { get; set; }
}

public class GateBlockSnapshotCreateDto
{
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    public int? MinecraftBlockRefId { get; set; }
    public int SortOrder { get; set; } = 0;
}
```

---

### 3. API Endpoints

#### Gate CRUD Operations

```
GET    /api/gates                           → List all gates (paginated, filtered)
GET    /api/gates/{id}                      → Get single gate by ID
POST   /api/gates                           → Create new gate
PUT    /api/gates/{id}                      → Update gate
DELETE /api/gates/{id}                      → Delete gate

GET    /api/gates/domain/{domainId}         → List gates in domain
GET    /api/gates/district/{districtId}     → List gates in district
GET    /api/gates/by-type/{gateType}        → List gates by type
```

#### Gate State Management

```
PUT    /api/gates/{id}/state                → Update IsOpened state
GET    /api/gates/{id}/state                → Get current state (IsOpened, HealthCurrent, IsDestroyed)
POST   /api/gates/{id}/trigger-respawn      → Force respawn (if CanRespawn=true)
```

#### Snapshot Operations

```
GET    /api/gates/{id}/snapshots            → Get all snapshots for gate
POST   /api/gates/{id}/snapshots/bulk       → Create/replace snapshots
DELETE /api/gates/{id}/snapshots            → Clear all snapshots
```

#### Request/Response Examples

**GET /api/gates/{id}** (200 OK)
```json
{
  "id": 1,
  "name": "Main Gate",
  "domainId": 1,
  "gateType": "SLIDING",
  "isOpened": false,
  "isDestroyed": false,
  "healthCurrent": 500.0,
  "healthMax": 500.0,
  "animationDurationTicks": 60,
  "anchorPoint": "{\"x\":100,\"y\":64,\"z\":100}",
  "referencePoint1": "{\"x\":105,\"y\":64,\"z\":100}",
  "referencePoint2": "{\"x\":100,\"y\":69,\"z\":100}",
  "geometryWidth": 3,
  "geometryHeight": 5,
  "geometryDepth": 2
}
```

**POST /api/gates** (201 Created)
```json
{
  "name": "New Gate",
  "domainId": 1,
  "districtId": 1,
  "gateType": "SLIDING",
  "geometryDefinitionMode": "PLANE_GRID",
  "motionType": "VERTICAL",
  "faceDirection": "north",
  "anchorPoint": "{\"x\":100,\"y\":64,\"z\":100}",
  "referencePoint1": "{\"x\":105,\"y\":64,\"z\":100}",
  "referencePoint2": "{\"x\":100,\"y\":69,\"z\":100}",
  "geometryWidth": 3,
  "geometryHeight": 5,
  "geometryDepth": 2,
  "healthMax": 500.0
}
```

---

### 4. Frontend: Types & Components

#### TypeScript Types

```typescript
// Gate types
type GateType = 'SLIDING' | 'TRAP' | 'DRAWBRIDGE' | 'DOUBLE_DOORS';
type MotionType = 'VERTICAL' | 'LATERAL' | 'ROTATION';
type GeometryDefinitionMode = 'PLANE_GRID' | 'FLOOD_FILL';
type FaceDirection = 'north' | 'north-east' | 'east' | 'south-east' | 'south' | 'south-west' | 'west' | 'north-west';
type TileEntityPolicy = 'DECORATIVE_ONLY' | 'CONTAINER_SAFE';

interface Coordinate3D {
  x: number;
  y: number;
  z: number;
}

interface GateStructure {
  id: number;
  name: string;
  domainId: number;
  districtId: number;
  streetId?: number;
  isActive: boolean;
  isOpened: boolean;
  isDestroyed: boolean;
  gateType: GateType;
  motionType: MotionType;
  faceDirection: FaceDirection;
  geometryDefinitionMode: GeometryDefinitionMode;
  animationDurationTicks: number;
  animationTickRate: number;
  anchorPoint: Coordinate3D;
  referencePoint1: Coordinate3D;
  referencePoint2: Coordinate3D;
  geometryWidth: number;
  geometryHeight: number;
  geometryDepth: number;
  seedBlocks?: Coordinate3D[];
  healthCurrent: number;
  healthMax: number;
  isInvincible: boolean;
  canRespawn: boolean;
  respawnRateSeconds: number;
  fallbackMaterialRefId?: number;
  tileEntityPolicy: TileEntityPolicy;
  regionClosedId: string;
  regionOpenedId: string;
  createdAt: string;
  updatedAt: string;
}

interface GateBlockSnapshot {
  id: number;
  gateStructureId: number;
  relativeX: number;
  relativeY: number;
  relativeZ: number;
  minecraftBlockRefId?: number;
  sortOrder: number;
}
```

#### UI Components

```
GateListPage
├── GateTable (lists all gates)
│   ├── Column: Name
│   ├── Column: Type
│   ├── Column: Status (Open/Closed/Broken)
│   ├── Column: Health
│   └── Column: Actions (View, Edit, Delete, Open/Close)
├── FilterPanel (by domain, type, status)
├── Pagination
└── Create Gate Button

GateDetailsPage
├── GateInfo (read-only details)
├── SnapshotCount
├── CurrentState
└── Actions: Edit, Delete, Open/Close, Recapture

GateWizardPage (6 steps)
├── Step 1: Basic Info (name, domain, district, health)
├── Step 2: Type & Orientation (gate type, face direction)
├── Step 3: Geometry (PLANE_GRID or FLOOD_FILL config)
├── Step 4: Animation (duration, tick rate, rotation)
├── Step 5: Advanced (fallback material, regions)
├── Step 6: Review & Create
└── Navigation: Previous, Next, Cancel, Create

GatePreviewWidget (3D visualization with Three.js)
├── Block visualization
├── Animation playback
└── Block selection/highlighting
```

---

### 5. Plugin: Animation Engine

#### Animation Frame Calculation

**Algorithm**: `CalculateFrame(currentElapsedTicks, totalAnimationTicks, animationTickRate)`

```
1. Calculate progress: progress = currentElapsedTicks / totalAnimationTicks
2. Clamp: progress = min(1.0, max(0.0, progress))
3. Determine direction: direction = isOpening ? 1 : -1
4. Adjust for AnimationTickRate: displayFrame = floor(progress * totalAnimationTicks / animationTickRate)
5. Return: {progress, displayFrame, isComplete}
```

**Linear Motion** (VERTICAL/LATERAL):
```
For each block in snapshot:
  - Calculate relative offset: offset = snapshot.relativePosition
  - Calculate motion vector: motionVector = normalize(FaceDirection) * GeometryDepth * BlockSize
  - Calculate animated position: animatedPos = AnchorPoint + offset + (motionVector * progress)
  - Place block at animatedPos (if progress > 0) or remove (if progress = 0)
```

**Rotational Motion** (ROTATION):
```
For each block in snapshot:
  - Calculate relative position from hinge axis
  - Rotate around hinge by: angle = RotationMaxAngleDegrees * progress
  - Use rotation matrix: rotated = rotate(relative, hinge, angle)
  - Calculate animated position: animatedPos = HingeBlock + rotated
  - Place block at animatedPos
```

#### Entity Push System

**Algorithm**: `PredictAndPushEntities(gateFrames, nextFrame, affectedBlocks)`

```
1. Get all entities within gate bounding box + buffer
2. For each entity:
   a. Check if entity will collide with nextFrame blocks
   b. If collision imminent:
      - Calculate push direction (away from gate)
      - Apply velocity: entity.velocity += pushDirection * PUSH_FORCE
   c. Apply damage if entity in closing gate (future)
3. Update entity positions
```

**Collision Prediction**:
- Calculate entity AABB (bounding box)
- Calculate block AABBs for previous + next frame
- Use swept AABB test (predict 1 tick ahead)
- Only push if collision is imminent (next tick) OR already colliding

---

## 🔑 Performance Targets

| Metric | Target | Method |
|--------|--------|--------|
| Max Active Gates | 100 | Lazy updates (only OPENING/CLOSING) |
| Memory per Gate | <500 KB | Snapshots indexed on disk, loaded on-demand |
| Animating Gates (no TPS loss) | ≥10 @ TPS 18 | Batched chunk updates, frame skip on lag |
| Animation Frame Lag | <1 tick | Pre-computed motion vectors |
| Entity Push Latency | <1 tick | Swept AABB collision check |

---

## 🔗 References & Related Files

- **Backend Entity**: [Models/GateStructure.cs](../../../../Repository/knk-web-api-v2/Models/GateStructure.cs)
- **Backend Instructions**: [.github/instructions/knk-backend.instructions.md](../../../../.github/instructions/knk-backend.instructions.md)
- **Plugin Architecture**: [Repository/knk-plugin-v2/ARCHITECTURE_AUDIT.md](../../../../Repository/knk-plugin-v2/ARCHITECTURE_AUDIT.md)
- **CODEMAP**: [docs/CODEMAP.md](../../CODEMAP.md)

