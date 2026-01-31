# Gate Animation System Quick Start

**Status**: Ready for Implementation  
**Created**: January 30, 2026  
**Audience**: Developers implementing the gate animation system  

---

## 📋 Quick Reference

### Gate Types & Characteristics

| Type | Motion | Geometry | Rotation | Example |
|------|--------|----------|----------|---------|
| **SLIDING** | VERTICAL/LATERAL | PLANE_GRID | No | Portcullis, sliding wall |
| **TRAP** | VERTICAL | PLANE_GRID | No | Trap door, pit cover |
| **DRAWBRIDGE** | ROTATION | PLANE_GRID | Yes (90°) | Castle bridge |
| **DOUBLE_DOORS** | ROTATION | FLOOD_FILL | Yes (90°, mirrored) | Large entrance |

---

### FaceDirection Values (8 directions)

```
north, north-east, east, south-east, south, south-west, west, north-west
```

**Vector Mappings:**
```csharp
north      → (0, 0, -1)
north-east → (+0.707, 0, -0.707)
east       → (+1, 0, 0)
south-east → (+0.707, 0, +0.707)
south      → (0, 0, +1)
south-west → (-0.707, 0, +0.707)
west       → (-1, 0, 0)
north-west → (-0.707, 0, -0.707)
```

---

### GateStructure Entity (Key Fields)

**Existing Fields:**
```csharp
public int Id { get; set; }
public string Name { get; set; }
public int DomainId { get; set; }
public int DistrictId { get; set; }
public int? StreetId { get; set; }
public bool IsActive { get; set; } = false;
public bool IsOpened { get; set; } = false;
public bool IsDestroyed { get; set; } = false;
public bool IsInvincible { get; set; } = true;
public bool CanRespawn { get; set; } = true;
public double HealthCurrent { get; set; } = 500.0;
public double HealthMax { get; set; } = 500.0;
public string FaceDirection { get; set; } = "north";
public int RespawnRateSeconds { get; set; } = 300;
public string RegionClosedId { get; set; } = string.Empty;
public string RegionOpenedId { get; set; } = string.Empty;
```

**New Animation Fields:**
```csharp
// Gate Type & Geometry
public string GateType { get; set; } = "SLIDING";
public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
public string MotionType { get; set; } = "VERTICAL";
public int AnimationDurationTicks { get; set; } = 60;
public int AnimationTickRate { get; set; } = 1;

// PLANE_GRID
public string AnchorPoint { get; set; } = string.Empty;  // JSON: {x,y,z}
public string ReferencePoint1 { get; set; } = string.Empty;
public string ReferencePoint2 { get; set; } = string.Empty;
public int GeometryWidth { get; set; } = 0;
public int GeometryHeight { get; set; } = 0;
public int GeometryDepth { get; set; } = 0;

// FLOOD_FILL
public string SeedBlocks { get; set; } = string.Empty;  // JSON: [{x,y,z}, ...]
public int ScanMaxBlocks { get; set; } = 500;
public int ScanMaxRadius { get; set; } = 20;

// Block Management
public int? FallbackMaterialRefId { get; set; }
public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";

// Rotation
public int RotationMaxAngleDegrees { get; set; } = 90;

// Double Doors
public bool MirrorRotation { get; set; } = true;
```

---

### GateBlockSnapshot Entity

```csharp
public class GateBlockSnapshot
{
    public int Id { get; set; }
    public int GateStructureId { get; set; }
    public GateStructure GateStructure { get; set; }
    
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    
    public int? MinecraftBlockRefId { get; set; }
    public MinecraftBlockRef? BlockRef { get; set; }
    
    public int SortOrder { get; set; }  // Hinge → outward
}
```

---

### Animation States

```
CLOSED    → IsOpened=false, gate fully closed
OPENING   → Animation in progress (closed → open)
OPEN      → IsOpened=true, gate fully open
CLOSING   → Animation in progress (open → closed)
JAMMED    → Blocked by obstacle (future)
BROKEN    → IsDestroyed=true, HealthCurrent=0
```

**State Transitions:**
```
CLOSED → OPENING  (trigger: /gate open)
OPENING → OPEN    (completion: frame = totalFrames)
OPEN → CLOSING    (trigger: /gate close)
CLOSING → CLOSED  (completion: frame = 0)
Any → BROKEN      (health = 0)
BROKEN → CLOSED   (respawn after RespawnRateSeconds)
```

---

## 🚀 Backend Implementation (C# / .NET)

### Step 1: Update GateStructure Entity

**File**: `Repository/knk-web-api-v2/Models/GateStructure.cs`

```csharp
[FormConfigurableEntity("GateStructure")]
public class GateStructure : Structure
{
    // ... existing fields ...
    
    // Animation System Fields
    public string GateType { get; set; } = "SLIDING";
    public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
    public string MotionType { get; set; } = "VERTICAL";
    public int AnimationDurationTicks { get; set; } = 60;
    public int AnimationTickRate { get; set; } = 1;
    
    public string AnchorPoint { get; set; } = string.Empty;
    public string ReferencePoint1 { get; set; } = string.Empty;
    public string ReferencePoint2 { get; set; } = string.Empty;
    public int GeometryWidth { get; set; } = 0;
    public int GeometryHeight { get; set; } = 0;
    public int GeometryDepth { get; set; } = 0;
    
    public string SeedBlocks { get; set; } = string.Empty;
    public int ScanMaxBlocks { get; set; } = 500;
    public int ScanMaxRadius { get; set; } = 20;
    public string ScanMaterialWhitelist { get; set; } = string.Empty;
    public string ScanMaterialBlacklist { get; set; } = string.Empty;
    public bool ScanPlaneConstraint { get; set; } = false;
    
    public int? FallbackMaterialRefId { get; set; }
    [RelatedEntityField(typeof(MinecraftMaterialRef))]
    public MinecraftMaterialRef? FallbackMaterial { get; set; } = null;
    
    public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";
    public int RotationMaxAngleDegrees { get; set; } = 90;
    public string HingeAxis { get; set; } = string.Empty;
    public string LeftDoorSeedBlock { get; set; } = string.Empty;
    public string RightDoorSeedBlock { get; set; } = string.Empty;
    public bool MirrorRotation { get; set; } = true;
    
    // Navigation
    public ICollection<GateBlockSnapshot> BlockSnapshots { get; set; } = new List<GateBlockSnapshot>();
}
```

---

### Step 2: Create GateBlockSnapshot Entity

**File**: `Repository/knk-web-api-v2/Models/GateBlockSnapshot.cs`

```csharp
using knkwebapi_v2.Attributes;

namespace knkwebapi_v2.Models;

public class GateBlockSnapshot
{
    public int Id { get; set; }
    
    public int GateStructureId { get; set; }
    public GateStructure GateStructure { get; set; } = null!;
    
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    
    [RelatedEntityField(typeof(MinecraftBlockRef))]
    public int? MinecraftBlockRefId { get; set; }
    
    [RelatedEntityField(typeof(MinecraftBlockRef))]
    public MinecraftBlockRef? BlockRef { get; set; } = null;
    
    public int SortOrder { get; set; }
}
```

---

### Step 3: Create DTOs

**File**: `Repository/knk-web-api-v2/DTOs/GateStructureDtos.cs`

```csharp
namespace knkwebapi_v2.DTOs;

public class GateStructureReadDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int DomainId { get; set; }
    public int DistrictId { get; set; }
    public int? StreetId { get; set; }
    
    public bool IsActive { get; set; }
    public bool IsOpened { get; set; }
    public bool IsDestroyed { get; set; }
    public bool IsInvincible { get; set; }
    public bool CanRespawn { get; set; }
    public double HealthCurrent { get; set; }
    public double HealthMax { get; set; }
    public string FaceDirection { get; set; } = string.Empty;
    public int RespawnRateSeconds { get; set; }
    
    public string GateType { get; set; } = string.Empty;
    public string GeometryDefinitionMode { get; set; } = string.Empty;
    public string MotionType { get; set; } = string.Empty;
    public int AnimationDurationTicks { get; set; }
    public int AnimationTickRate { get; set; }
    
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
    public int GeometryWidth { get; set; }
    public int GeometryHeight { get; set; }
    public int GeometryDepth { get; set; }
    
    public int AnimationDurationTicks { get; set; } = 60;
    public int? FallbackMaterialRefId { get; set; }
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
}

public class GateStructureNavDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string GateType { get; set; } = string.Empty;
    public bool IsOpened { get; set; }
}

public class GateBlockSnapshotDto
{
    public int Id { get; set; }
    public int GateStructureId { get; set; }
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    public int? MinecraftBlockRefId { get; set; }
    public int SortOrder { get; set; }
}
```

---

### Step 4: Database Migration

**File**: `Repository/knk-web-api-v2/Migrations/{Timestamp}_AddGateAnimation.cs`

```sql
ALTER TABLE GateStructures ADD COLUMN GateType VARCHAR(50) DEFAULT 'SLIDING';
ALTER TABLE GateStructures ADD COLUMN GeometryDefinitionMode VARCHAR(50) DEFAULT 'PLANE_GRID';
-- ... (add all new columns)

CREATE TABLE GateBlockSnapshots (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    GateStructureId INT NOT NULL,
    RelativeX INT NOT NULL,
    RelativeY INT NOT NULL,
    RelativeZ INT NOT NULL,
    MinecraftBlockRefId INT NULL,
    SortOrder INT NOT NULL,
    FOREIGN KEY (GateStructureId) REFERENCES GateStructures(Id) ON DELETE CASCADE,
    INDEX idx_gate_id (GateStructureId),
    INDEX idx_sort_order (GateStructureId, SortOrder)
);
```

---

### Step 5: Repository & Service (Follow Backend Instructions)

**Repository**: `Repository/knk-web-api-v2/Repositories/GateStructureRepository.cs`  
**Service**: `Repository/knk-web-api-v2/Services/GateStructureService.cs`  
**Controller**: `Repository/knk-web-api-v2/Controllers/GateStructuresController.cs`

**Follow Pattern From**: Similar to `UserRepository`, `UserService`, `UsersController`

---

## 🎨 Frontend Implementation (React/TypeScript)

### Gate Type Definitions

**File**: `Repository/knk-web-app/src/types/gate.ts`

```typescript
export interface GateStructure {
  id: number;
  name: string;
  domainId: number;
  districtId: number;
  streetId?: number;
  
  isActive: boolean;
  isOpened: boolean;
  isDestroyed: boolean;
  isInvincible: boolean;
  canRespawn: boolean;
  healthCurrent: number;
  healthMax: number;
  faceDirection: FaceDirection;
  respawnRateSeconds: number;
  
  gateType: GateType;
  geometryDefinitionMode: GeometryDefinitionMode;
  motionType: MotionType;
  animationDurationTicks: number;
  animationTickRate: number;
  
  anchorPoint: string;
  referencePoint1: string;
  referencePoint2: string;
  geometryWidth: number;
  geometryHeight: number;
  geometryDepth: number;
  
  seedBlocks: string;
  scanMaxBlocks: number;
  scanMaxRadius: number;
  
  fallbackMaterialRefId?: number;
  fallbackMaterial?: MinecraftMaterialRefNav;
  
  tileEntityPolicy: TileEntityPolicy;
  rotationMaxAngleDegrees: number;
  mirrorRotation: boolean;
  
  regionClosedId: string;
  regionOpenedId: string;
  
  createdAt: string;
  updatedAt: string;
}

export type GateType = 'SLIDING' | 'TRAP' | 'DRAWBRIDGE' | 'DOUBLE_DOORS';
export type GeometryDefinitionMode = 'PLANE_GRID' | 'FLOOD_FILL';
export type MotionType = 'VERTICAL' | 'LATERAL' | 'ROTATION';
export type FaceDirection = 'north' | 'north-east' | 'east' | 'south-east' 
                          | 'south' | 'south-west' | 'west' | 'north-west';
export type TileEntityPolicy = 'NONE' | 'DECORATIVE_ONLY' | 'ALL';

export interface GateCreateRequest {
  name: string;
  domainId: number;
  districtId: number;
  streetId?: number;
  gateType: GateType;
  geometryDefinitionMode: GeometryDefinitionMode;
  motionType: MotionType;
  faceDirection: FaceDirection;
  anchorPoint: string;
  referencePoint1: string;
  referencePoint2: string;
  geometryWidth: number;
  geometryHeight: number;
  geometryDepth: number;
  animationDurationTicks: number;
  fallbackMaterialRefId?: number;
}
```

---

## 🎮 Plugin Implementation (Java / Paper API)

### Core Data Structures

**File**: `Repository/knk-plugin-v2/knk-paper/src/main/java/com/knockoffrealms/knk/gate/CachedGate.java`

```java
package com.knockoffrealms.knk.gate;

import org.bukkit.util.Vector;
import java.util.List;

public class CachedGate {
    // Metadata
    public int id;
    public String name;
    public GateType gateType;
    public AnimationState currentState;
    
    // Runtime State
    public int currentFrame;
    public long animationStartTime;
    public int totalFrames;
    
    // Geometry (precomputed)
    public Vector anchorPoint;
    public Vector uAxis, vAxis, nAxis;  // Local coordinate basis
    public Vector motionVector;         // For VERTICAL/LATERAL
    public Vector hingeAxis;            // For ROTATION
    
    // Configuration
    public int animationDurationTicks;
    public int animationTickRate;
    public MotionType motionType;
    public int rotationMaxAngleDegrees;
    
    // Blocks (sorted by SortOrder)
    public List<BlockSnapshot> blocks;
}

public enum GateType {
    SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
}

public enum AnimationState {
    CLOSED, OPENING, OPEN, CLOSING, JAMMED, BROKEN
}

public enum MotionType {
    VERTICAL, LATERAL, ROTATION
}

public class BlockSnapshot {
    public Vector relativePos;
    public BlockData blockData;
    public int sortOrder;
}
```

---

### Animation Tick Task

**File**: `Repository/knk-plugin-v2/knk-paper/src/main/java/com/knockoffrealms/knk/gate/GateAnimationTask.java`

```java
package com.knockoffrealms.knk.gate;

import org.bukkit.scheduler.BukkitRunnable;
import org.bukkit.Server;

public class GateAnimationTask extends BukkitRunnable {
    
    private final GateManager gateManager;
    private final Server server;
    
    public GateAnimationTask(GateManager gateManager, Server server) {
        this.gateManager = gateManager;
        this.server = server;
    }
    
    @Override
    public void run() {
        long currentTick = server.getCurrentTick();
        
        for (CachedGate gate : gateManager.getAllGates()) {
            if (gate.currentState != AnimationState.OPENING 
                && gate.currentState != AnimationState.CLOSING) {
                continue;  // Skip idle gates
            }
            
            // Calculate current frame
            long elapsedTicks = currentTick - gate.animationStartTime;
            int currentFrame = (int) (elapsedTicks / gate.animationTickRate);
            
            // Clamp to valid range
            if (currentFrame >= gate.totalFrames) {
                gateManager.finishAnimation(gate);
                continue;
            }
            
            gate.currentFrame = currentFrame;
            updateGateBlocks(gate, currentFrame);
            checkEntityCollisions(gate, currentFrame);
        }
    }
    
    private void updateGateBlocks(CachedGate gate, int currentFrame) {
        // Implementation depends on MotionType
        if (gate.motionType == MotionType.VERTICAL || gate.motionType == MotionType.LATERAL) {
            updateLinearMotion(gate, currentFrame);
        } else if (gate.motionType == MotionType.ROTATION) {
            updateRotationMotion(gate, currentFrame);
        }
    }
    
    private void checkEntityCollisions(CachedGate gate, int currentFrame) {
        // Predict collisions and push entities
        // (See full spec for implementation)
    }
}
```

---

## 🔧 Common Code Patterns

### Parse JSON Coordinate

**C#:**
```csharp
using System.Text.Json;

public Vector3 ParseCoordinate(string json) {
    var obj = JsonSerializer.Deserialize<Dictionary<string, double>>(json);
    return new Vector3(obj["x"], obj["y"], obj["z"]);
}
```

**Java:**
```java
import org.bukkit.util.Vector;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

public Vector parseCoordinate(String json) {
    JsonObject obj = JsonParser.parseString(json).getAsJsonObject();
    return new Vector(
        obj.get("x").getAsDouble(),
        obj.get("y").getAsDouble(),
        obj.get("z").getAsDouble()
    );
}
```

---

### Calculate Local Coordinate Basis

**Java:**
```java
public void calculateLocalBasis(CachedGate gate, Vector p0, Vector p1, Vector p2) {
    // u = width axis (along hinge)
    gate.uAxis = p1.clone().subtract(p0).normalize();
    
    // forward = temporary forward direction
    Vector forward = p2.clone().subtract(p0).normalize();
    
    // n = normal (perpendicular to gate plane)
    gate.nAxis = gate.uAxis.clone().crossProduct(forward).normalize();
    
    // v = depth axis (corrected forward)
    gate.vAxis = gate.nAxis.clone().crossProduct(gate.uAxis).normalize();
}
```

---

### Frame-to-Position (Linear Motion)

**Java:**
```java
public Vector calculateBlockPosition(CachedGate gate, BlockSnapshot block, int frame) {
    Vector closedPos = gate.anchorPoint.clone()
        .add(gate.uAxis.clone().multiply(block.relativePos.getX()))
        .add(gate.nAxis.clone().multiply(block.relativePos.getY()))
        .add(gate.vAxis.clone().multiply(block.relativePos.getZ()));
    
    Vector stepVector = gate.motionVector.clone().multiply(1.0 / gate.totalFrames);
    Vector offset = stepVector.multiply(frame);
    
    return closedPos.add(offset);
}
```

---

### Rotation Around Axis

**Java:**
```java
public Vector rotateAroundAxis(Vector v, Vector axis, double angleDegrees) {
    double angleRad = Math.toRadians(angleDegrees);
    double cos = Math.cos(angleRad);
    double sin = Math.sin(angleRad);
    
    // Rodrigues' rotation formula
    Vector vRot = v.clone().multiply(cos)
        .add(axis.clone().crossProduct(v).multiply(sin))
        .add(axis.clone().multiply(axis.dot(v)).multiply(1 - cos));
    
    return vRot;
}
```

---

## 🧪 Testing Checklist

### Unit Tests (Backend)
- [ ] GateStructure entity validation
- [ ] DTO mapping (AutoMapper)
- [ ] Repository CRUD operations
- [ ] Service cascade rules (delete gate → delete snapshots)
- [ ] Controller endpoints (GET, POST, PUT, DELETE)

### Unit Tests (Frontend)
- [ ] Gate type selector
- [ ] Coordinate input parsing
- [ ] Form validation (wizard steps)
- [ ] API client methods

### Unit Tests (Plugin)
- [ ] Coordinate parsing
- [ ] Local basis calculation
- [ ] Frame-to-position calculation (linear)
- [ ] Frame-to-position calculation (rotation)
- [ ] Collision prediction

### Integration Tests
- [ ] Gate creation (web app → API → database)
- [ ] Block snapshot capture (plugin → API)
- [ ] Animation state sync (plugin → API)
- [ ] Gate open/close (command → animation → state update)

### Performance Tests
- [ ] 100 gates loaded < 50 MB memory
- [ ] 10 gates animating: TPS ≥ 18
- [ ] 20 gates animating: TPS ≥ 15

---

## 📚 Reference Examples

### Example: Portcullis (SLIDING, VERTICAL, PLANE_GRID)

```json
{
  "name": "Main Gate Portcullis",
  "domainId": 1,
  "districtId": 5,
  "gateType": "SLIDING",
  "geometryDefinitionMode": "PLANE_GRID",
  "motionType": "VERTICAL",
  "faceDirection": "north",
  "anchorPoint": "{\"x\":100,\"y\":64,\"z\":100}",
  "referencePoint1": "{\"x\":106,\"y\":64,\"z\":100}",
  "referencePoint2": "{\"x\":100,\"y\":64,\"z\":99}",
  "geometryWidth": 7,
  "geometryHeight": 8,
  "geometryDepth": 1,
  "animationDurationTicks": 60,
  "healthMax": 1000.0,
  "isInvincible": false,
  "canRespawn": true,
  "respawnRateSeconds": 600
}
```

### Example: Drawbridge (DRAWBRIDGE, ROTATION, PLANE_GRID)

```json
{
  "name": "Castle Drawbridge",
  "domainId": 1,
  "districtId": 5,
  "gateType": "DRAWBRIDGE",
  "geometryDefinitionMode": "PLANE_GRID",
  "motionType": "ROTATION",
  "faceDirection": "south",
  "anchorPoint": "{\"x\":200,\"y\":64,\"z\":200}",
  "referencePoint1": "{\"x\":208,\"y\":64,\"z\":200}",
  "referencePoint2": "{\"x\":200,\"y\":64,\"z\":201}",
  "geometryWidth": 9,
  "geometryHeight": 1,
  "geometryDepth": 6,
  "animationDurationTicks": 80,
  "rotationMaxAngleDegrees": 90
}
```

### Example: Double Doors (DOUBLE_DOORS, ROTATION, FLOOD_FILL)

```json
{
  "name": "Throne Room Entrance",
  "domainId": 1,
  "districtId": 5,
  "gateType": "DOUBLE_DOORS",
  "geometryDefinitionMode": "FLOOD_FILL",
  "motionType": "ROTATION",
  "faceDirection": "east",
  "leftDoorSeedBlock": "{\"x\":300,\"y\":64,\"z\":300}",
  "rightDoorSeedBlock": "{\"x\":300,\"y\":64,\"z\":305}",
  "scanMaxBlocks": 200,
  "scanMaxRadius": 10,
  "mirrorRotation": true,
  "animationDurationTicks": 40
}
```

---

**End of Quick Start**
