# REQUIREMENTS: Gate Animation System (v2 API-aligned)

This document integrates:
- **Current entity model**: GateStructure.cs (extends Structure → Domain)
- **Game mechanics**: Minecraft Paper plugin animation requirements
- **Business requirements**: Multi-type gate support, diagonal orientation, block-based animation
- **Architecture**: Web API + Web App + Paper Plugin integration

---

## Part A: GateStructure Entity Model (v2 Architecture)

### Core Identity & Inheritance

**Model Fields (from GateStructure.cs - extends Structure):**
```csharp
// Inherited from Structure → Domain
public int Id { get; set; }                          // Primary key; auto-generated
public int DomainId { get; set; }                    // Parent domain reference
public string Name { get; set; }                     // Gate display name
public int DistrictId { get; set; }                  // District reference
public int? StreetId { get; set; }                   // Optional street reference

// Gate-specific fields (existing)
public bool IsActive { get; set; } = false;          // Gate system enabled
public bool CanRespawn { get; set; } = true;         // Auto-repair after destruction
public bool IsDestroyed { get; set; } = false;       // Current health state
public bool IsInvincible { get; set; } = true;       // Cannot be damaged
public bool IsOpened { get; set; } = false;          // Current open/closed state
public double HealthCurrent { get; set; } = 500.0;   // Current HP
public double HealthMax { get; set; } = 500.0;       // Maximum HP
public string FaceDirection { get; set; } = "north"; // Orientation (cardinal/diagonal)
public int RespawnRateSeconds { get; set; } = 300;   // Auto-repair delay (5 min default)
public int? IconMaterialRefId { get; set; }          // Icon material reference
public MinecraftMaterialRef? IconMaterial { get; set; } = null;
public string RegionClosedId { get; set; } = string.Empty;  // WorldGuard region (closed)
public string RegionOpenedId { get; set; } = string.Empty;  // WorldGuard region (opened)
```

**Key Architectural Decisions:**

1. **Inheritance from Structure**
   - Gates are specialized structures within the domain system
   - Inherits district/street location, world position, ownership
   - Integrates with existing WorldGuard protection
   - Benefits from existing access control and permissions

2. **Dual State Management**
   - `IsOpened`: Current animation state (CLOSED/OPEN)
   - `IsActive`: Gate system enabled (can animate)
   - Both required: gate can be inactive but open, or active but closed

3. **Health System Integration**
   - `HealthCurrent / HealthMax`: Damage tracking
   - `IsDestroyed`: Triggers respawn logic
   - `IsInvincible`: Admin protection override
   - `CanRespawn`: Auto-repair feature toggle
   - `RespawnRateSeconds`: Delay before auto-repair

4. **Orientation System**
   - `FaceDirection`: Authoritative for all gate behavior
   - Supports: north, north-east, east, south-east, south, south-west, west, north-west
   - Drives animation axis, entity push direction, geometry calculations
   - **Critical**: Must support diagonal gates natively

5. **WorldGuard Integration**
   - `RegionClosedId`: Protection region when gate is closed
   - `RegionOpenedId`: Protection region when gate is open
   - Allows different access rules per state
   - Empty strings mean no region defined

---

### Required Entity Extensions (New Fields)

**Animation System Fields:**
```csharp
// Gate Type & Geometry
public string GateType { get; set; } = "SLIDING";    // SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";  // PLANE_GRID, FLOOD_FILL

// Motion Configuration
public string MotionType { get; set; } = "VERTICAL"; // VERTICAL, LATERAL, ROTATION
public int AnimationDurationTicks { get; set; } = 60; // Animation length (default 3 sec @ 20 TPS)
public int AnimationTickRate { get; set; } = 1;      // Frames per tick (1 = every tick)

// Geometry Definition (PLANE_GRID mode)
public string AnchorPoint { get; set; } = string.Empty;     // JSON: {x, y, z} - p0 (hinge-left/top-left)
public string ReferencePoint1 { get; set; } = string.Empty; // JSON: {x, y, z} - p1 (hinge-right)
public string ReferencePoint2 { get; set; } = string.Empty; // JSON: {x, y, z} - p2 (forward reference)
public int GeometryWidth { get; set; } = 0;          // Grid width (blocks)
public int GeometryHeight { get; set; } = 0;         // Grid height (blocks)
public int GeometryDepth { get; set; } = 0;          // Grid depth (blocks)

// Geometry Definition (FLOOD_FILL mode)
public string SeedBlocks { get; set; } = string.Empty;      // JSON array: [{x,y,z}, ...] - scan start points
public int ScanMaxBlocks { get; set; } = 500;        // Safety limit for flood fill
public int ScanMaxRadius { get; set; } = 20;         // Max distance from seed
public string ScanMaterialWhitelist { get; set; } = string.Empty; // JSON: [materialIds] - allowed materials
public string ScanMaterialBlacklist { get; set; } = string.Empty; // JSON: [materialIds] - excluded materials
public bool ScanPlaneConstraint { get; set; } = false; // Restrict to single plane

// Block Management
public int? FallbackMaterialRefId { get; set; }      // Default material if snapshot restoration fails
public MinecraftMaterialRef? FallbackMaterial { get; set; } = null;
public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY"; // NONE, DECORATIVE_ONLY, ALL

// Runtime State (not persisted - managed by plugin)
// NOTE: These are managed in-memory by the Paper plugin during animation
// Current animation state: CLOSED, OPENING, OPEN, CLOSING, JAMMED, BROKEN
// Current frame index
// Animation start timestamp
// Entity push cache
```

**Rotation-Specific Fields (Drawbridge, Double Doors):**
```csharp
public int RotationMaxAngleDegrees { get; set; } = 90; // Max rotation angle (default 90°)
public string HingeAxis { get; set; } = string.Empty;  // JSON: {x,y,z} - rotation axis vector (p0→p1)
```

**Double Doors Specific:**
```csharp
public string LeftDoorSeedBlock { get; set; } = string.Empty;  // JSON: {x,y,z}
public string RightDoorSeedBlock { get; set; } = string.Empty; // JSON: {x,y,z}
public bool MirrorRotation { get; set; } = true;      // Doors open in opposite directions
```

---

### Block Snapshot Storage (Separate Entity)

**GateBlockSnapshot** (new entity - one-to-many with GateStructure):
```csharp
public class GateBlockSnapshot
{
    public int Id { get; set; }                      // Primary key
    public int GateStructureId { get; set; }         // Foreign key → GateStructure
    public GateStructure GateStructure { get; set; } // Navigation property
    
    public int RelativeX { get; set; }               // Position relative to anchor
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    
    public int? MinecraftBlockRefId { get; set; }    // Material + state reference
    public MinecraftBlockRef? BlockRef { get; set; }
    
    public int SortOrder { get; set; }               // Animation sequence order (hinge→outward)
}
```

**Relationship:**
- One GateStructure has many GateBlockSnapshots
- Snapshots are captured when gate is defined (closed state)
- BlockRef contains: NamespaceKey, BlockStateString, LogicalType, IconUrl
- SortOrder ensures deterministic animation (prevents collision conflicts)

---

### Indexing & Lookup Strategy

**Indexes:**
- Primary: `Id` (clustered index)
- Foreign Key: `DomainId` (inherited from Structure)
- Foreign Key: `DistrictId` (inherited from Structure)
- Foreign Key: `StreetId` (inherited from Structure)
- Index: `GateType` (for filtering by gate type)
- Index: `IsActive` (for active gates query)
- Index: `IsOpened` (for state queries)
- Unique Index: `Name + DomainId` (prevents duplicate gate names in domain)

**Query Patterns:**
- `GetGateById(int id)` → direct lookup
- `GetGatesByDomain(int domainId)` → all gates in domain
- `GetActiveGates()` → gates with `IsActive = true`
- `GetGatesInAnimation()` → plugin queries gates in OPENING/CLOSING state
- `GetGatesByType(string gateType)` → filter by SLIDING, TRAP, etc.

---

## Part B: Gate Type System

### Supported Gate Types (v1)

**GateType Enum Values:**
```
SLIDING        - Vertical lift (portcullis) or lateral slide
TRAP           - Vertical drop or lift
DRAWBRIDGE     - Rotation around hinge line
DOUBLE_DOORS   - Two mirrored door leaves
```

### Gate Type Characteristics

| Gate Type | Default Motion | Geometry Mode | Rotation | Typical Use Case |
|-----------|----------------|---------------|----------|------------------|
| SLIDING | VERTICAL | PLANE_GRID | No | Portcullis, sliding wall |
| TRAP | VERTICAL | PLANE_GRID | No | Trap door, pit cover |
| DRAWBRIDGE | ROTATION | PLANE_GRID | Yes | Castle bridge, rampart |
| DOUBLE_DOORS | ROTATION | FLOOD_FILL | Yes | Large entrance doors |

### Motion Type Details

**VERTICAL:**
- Motion along world Y-axis (or local normal if diagonal)
- Direction: +Y (lift) or -Y (drop)
- Used by: SLIDING (portcullis), TRAP

**LATERAL:**
- Motion along horizontal plane (local U or V axis)
- Direction: perpendicular to FaceDirection
- Used by: SLIDING (sliding wall variant)

**ROTATION:**
- Rotation around hinge line (p0→p1)
- Angle: 0° (closed) → RotationMaxAngleDegrees° (open)
- Used by: DRAWBRIDGE, DOUBLE_DOORS

---

## Part C: Geometry Definition System

### GeometryDefinitionMode

**Two modes supported:**

1. **PLANE_GRID** (Recommended for rectangular gates)
   - Uses 3 reference points to define local coordinate system
   - Generates rectangular grid of blocks
   - Fully supports diagonal orientation
   - Best for: SLIDING, TRAP, DRAWBRIDGE

2. **FLOOD_FILL** (Recommended for irregular shapes)
   - Starts from seed block(s) and scans connected blocks
   - Supports material filtering
   - Can constrain to single plane
   - Best for: DOUBLE_DOORS, decorative gates

---

### PLANE_GRID Mode (Detailed Specification)

**Input Requirements:**
- `AnchorPoint` (p0): Hinge-left / top-left corner
- `ReferencePoint1` (p1): Hinge-right / top-right corner
- `ReferencePoint2` (p2): Forward reference (defines depth direction)
- `GeometryWidth`: Blocks along hinge line (p0→p1)
- `GeometryHeight`: Blocks along vertical/normal
- `GeometryDepth`: Blocks along forward direction

**Local Coordinate System Construction:**
```
u = normalize(p1 - p0)         // Width axis (along hinge)
forward = normalize(p2 - p0)    // Temporary forward
n = normalize(cross(u, forward)) // Normal (perpendicular to gate plane)
v = normalize(cross(n, u))      // Depth axis (corrected forward)

// Grid generation
for (h in 0..GeometryHeight):
    for (w in 0..GeometryWidth):
        for (d in 0..GeometryDepth):
            worldPos = p0 + w*u + h*n + d*v
            captureBlock(worldPos)
```

**Diagonal Support:**
- Local basis vectors (u, v, n) automatically handle diagonal orientation
- FaceDirection determines initial forward vector
- Resulting grid is rotated to match orientation
- Block positions are rounded to nearest integer coordinates

**Example (Portcullis facing north-east):**
```
FaceDirection: "north-east"
p0: {x: 100, y: 64, z: 100}  // Bottom-left hinge
p1: {x: 105, y: 64, z: 95}   // Bottom-right hinge (diagonal)
p2: {x: 100, y: 64, z: 99}   // Forward reference (1 block toward NE)
GeometryWidth: 6
GeometryHeight: 8
GeometryDepth: 1
```

---

### FLOOD_FILL Mode (Detailed Specification)

**Input Requirements:**
- `SeedBlocks`: One or more starting positions (JSON array)
- `ScanMaxBlocks`: Safety limit (default 500)
- `ScanMaxRadius`: Max Manhattan distance from seed (default 20)
- `ScanMaterialWhitelist`: Optional material filter (empty = all)
- `ScanMaterialBlacklist`: Excluded materials
- `ScanPlaneConstraint`: If true, restrict to Y-plane of seed

**Scan Algorithm:**
```
1. Start from seed block(s)
2. BFS (breadth-first search) to adjacent blocks (6-connectivity: ±X, ±Y, ±Z)
3. For each candidate block:
   - Check distance from nearest seed (Manhattan) ≤ ScanMaxRadius
   - Check total blocks scanned < ScanMaxBlocks
   - Check material whitelist/blacklist
   - If ScanPlaneConstraint: check Y == seedY
   - If valid: add to snapshot, enqueue neighbors
4. Sort blocks by distance from hinge (for animation order)
```

**Double Doors Usage:**
```json
{
  "GateType": "DOUBLE_DOORS",
  "GeometryDefinitionMode": "FLOOD_FILL",
  "LeftDoorSeedBlock": "{\"x\":100,\"y\":64,\"z\":100}",
  "RightDoorSeedBlock": "{\"x\":105,\"y\":64,\"z\":100}",
  "ScanMaxBlocks": 200,
  "ScanMaxRadius": 10,
  "ScanPlaneConstraint": false,
  "MirrorRotation": true
}
```
- Two separate flood fills (left/right door)
- Each door rotates around its own hinge (left seed, right seed)
- MirrorRotation: doors open in opposite directions

---

## Part D: Block Management & Materials

### MinecraftBlockRef Integration

**Entity (existing):**
```csharp
public class MinecraftBlockRef
{
    public int Id { get; set; }
    public string NamespaceKey { get; set; }      // e.g., "minecraft:oak_door"
    public string BlockStateString { get; set; }   // e.g., "facing=north,half=upper,open=false"
    public string LogicalType { get; set; }        // e.g., "DOOR", "FENCE_GATE", "SLAB"
    public string IconUrl { get; set; }
}
```

**Usage in Gate System:**
- Each GateBlockSnapshot references a MinecraftBlockRef
- BlockRef stores EXACT block state (preserves orientation, hinge side, etc.)
- Snapshot restoration uses BlockRef to recreate exact block + state
- Supports complex blocks: doors, stairs, slabs, fence gates, etc.

---

### Fallback Material System

**Purpose:**
- If BlockRef restoration fails (corrupted data, plugin version mismatch, etc.)
- Use `FallbackMaterial` (MinecraftMaterialRef) as default

**MinecraftMaterialRef (existing):**
```csharp
public class MinecraftMaterialRef
{
    public int Id { get; set; }
    public string NamespaceKey { get; set; }  // e.g., "minecraft:stone_bricks"
    public string Category { get; set; }      // e.g., "BUILDING_BLOCKS"
    public string IconUrl { get; set; }
}
```

**Fallback Logic:**
```
1. Attempt to restore from GateBlockSnapshot.BlockRef
2. If fails:
   - Use GateStructure.FallbackMaterial.NamespaceKey
   - Place with default block state
   - Log warning to admin console
```

---

### Tile Entity Policy

**TileEntityPolicy Enum:**
```
NONE               - No tile entities allowed (replaced with fallback)
DECORATIVE_ONLY    - Signs, banners, skulls allowed (default)
ALL                - All tile entities allowed (including inventories - future)
```

**Implementation (v1):**
- `NONE`: Replace all tile entities with solid blocks during snapshot
- `DECORATIVE_ONLY`: Preserve signs, banners, skulls; replace chests/furnaces
- `ALL`: Not supported in v1 (requires inventory serialization)

**Rationale:**
- Moving chests with items is complex (inventory serialization, dupe exploits)
- Decorative tile entities (signs, banners) have minimal state
- Default to DECORATIVE_ONLY for safety

---

### Supported Block Types (v1)

**Core Blocks:**
- Solid blocks (stone, wood, etc.)
- Transparent blocks (glass, iron bars)
- Slabs, stairs, walls
- Doors (including double doors)
- Fence gates
- Trapdoors

**Decorative (if TileEntityPolicy allows):**
- Signs (wall/standing)
- Banners
- Skulls/heads

**Not Supported (v1):**
- Inventory tile entities (chests, barrels, furnaces, hoppers)
- Redstone components (pistons, repeaters, comparators - causes side effects)
- Liquids (water, lava - causes physics issues)

---

## Part E: Animation System

### Animation States (State Machine)

**Primary States:**
```
CLOSED    - Gate fully closed; blocks in closed position
OPENING   - Animation in progress (closed → open)
OPEN      - Gate fully open; blocks in open position
CLOSING   - Animation in progress (open → closed)
JAMMED    - Animation blocked by obstacle (future)
BROKEN    - Gate destroyed (HealthCurrent = 0)
```

**State Transitions:**
```
CLOSED → OPENING  (trigger: open command)
OPENING → OPEN    (completion: frame = totalFrames)
OPEN → CLOSING    (trigger: close command)
CLOSING → CLOSED  (completion: frame = 0)

Any state → BROKEN  (health reaches 0)
BROKEN → CLOSED     (respawn triggered after RespawnRateSeconds)

Any OPENING/CLOSING → JAMMED (future: obstacle detected)
```

**State Storage:**
- Runtime state managed by Paper plugin (in-memory)
- Persisted state: `IsOpened` (true = OPEN, false = CLOSED)
- Plugin tracks current animation frame, start time, etc.

---

### Animation Frame Calculation

**Parameters:**
- `AnimationDurationTicks`: Total animation length (default 60 ticks = 3 seconds @ 20 TPS)
- `AnimationTickRate`: Frames per tick (default 1 = every tick)
- `MotionType`: VERTICAL, LATERAL, ROTATION
- `FaceDirection`: north, north-east, etc.

**Frame Computation (VERTICAL/LATERAL):**
```java
// Example: Vertical sliding gate
totalFrames = AnimationDurationTicks / AnimationTickRate;  // e.g., 60 / 1 = 60 frames
currentFrame = 0 to totalFrames

// Motion vector (example: vertical lift)
motionVector = new Vector(0, GeometryHeight, 0);  // Lift by gate height
stepVector = motionVector / totalFrames;           // Movement per frame

for (GateBlockSnapshot block : blocks) {
    offset = stepVector * currentFrame;            // Linear interpolation
    newWorldPos = block.getWorldPosition() + offset;
    
    // Round to nearest block coordinate
    finalX = Math.round(newWorldPos.x);
    finalY = Math.round(newWorldPos.y);
    finalZ = Math.round(newWorldPos.z);
    
    placeBlock(finalX, finalY, finalZ, block.BlockRef);
}
```

**Frame Computation (ROTATION - Drawbridge):**
```java
// Rotation around hinge line (p0→p1)
hingeAxis = normalize(p1 - p0);                     // Rotation axis
totalAngle = RotationMaxAngleDegrees;               // e.g., 90°
currentAngle = (currentFrame / totalFrames) * totalAngle;

for (GateBlockSnapshot block : blocks) {
    // Relative position from hinge
    relativePos = block.getWorldPosition() - p0;
    
    // Rotate around hinge axis by currentAngle
    rotatedPos = rotateAroundAxis(relativePos, hingeAxis, currentAngle);
    
    // Translate back to world
    newWorldPos = p0 + rotatedPos;
    
    // Round to nearest block coordinate
    finalX = Math.round(newWorldPos.x);
    finalY = Math.round(newWorldPos.y);
    finalZ = Math.round(newWorldPos.z);
    
    // Handle block collision (stable sort order)
    placeBlockIfEmpty(finalX, finalY, finalZ, block.BlockRef);
}
```

**Deterministic Rounding:**
- All floating-point calculations rounded to nearest integer
- Ensures blocks always snap to valid world coordinates
- Prevents "half-block" positions

---

### Block Placement Strategy

**Stable Sort Order (prevents collisions):**
- Blocks sorted by distance from hinge (SortOrder field)
- During rotation, blocks furthest from hinge placed first
- Last-write-wins: if two blocks map to same position, outer block wins
- Ensures consistent animation regardless of server tick jitter

**Collision Handling:**
```java
// Example: Drawbridge rotation
sortedBlocks = blocks.sortBy(b => b.SortOrder);  // Hinge → outward

for (block in sortedBlocks) {
    targetPos = calculateBlockPosition(block, currentFrame);
    
    // Last-write-wins: always overwrite
    world.setBlock(targetPos, block.BlockRef.toBlockData());
}
```

---

### Performance Optimization

**Target: ~100 active gates**

**Optimization Strategies:**

1. **Lazy Animation Updates**
   - Only gates in OPENING/CLOSING state perform per-tick updates
   - CLOSED/OPEN gates are idle (no CPU usage)

2. **Precomputed Data**
   - Local basis vectors (u, v, n) computed once during gate initialization
   - Block snapshots loaded once on plugin startup
   - Motion vectors cached per gate

3. **Batched Block Updates**
   - Group block updates by chunk
   - Use chunk.setBlockData() batch API
   - Reduces chunk lighting recalculations

4. **Chunk Loading Check**
   - Skip animation if gate chunk is unloaded
   - Resume when chunk loads (track current frame in database)

5. **Frame Skip Option**
   - If server TPS drops, allow frame skipping
   - Jump to final position if lag detected
   - Prevents animation "stutter"

**Memory Footprint:**
- Per gate: ~500 blocks × 64 bytes = 32 KB
- 100 gates: ~3.2 MB total
- Acceptable for modern Minecraft servers (8+ GB RAM)

---

## Part F: Entity & Player Interaction

### Push Policy (Anti-Premature Push)

**Problem:**
- Players should not be pushed when gate starts opening 10 blocks away
- Push should occur only when collision is imminent

**Solution:**
```java
// During animation frame update
for (Entity entity : nearbyEntities) {
    // Calculate collision prediction
    int framesToCollision = calculateFramesToCollision(entity, currentFrame);
    
    if (framesToCollision <= 2) {  // 2 frames = ~100ms warning
        pushEntity(entity, getPushDirection());
    }
}

int calculateFramesToCollision(Entity entity, int currentFrame) {
    // For each future frame, check if block will occupy entity's position
    for (int futureFrame = currentFrame; futureFrame <= totalFrames; futureFrame++) {
        blockPositions = calculateBlockPositions(futureFrame);
        
        if (blockPositions.intersects(entity.getBoundingBox())) {
            return futureFrame - currentFrame;  // Frames until collision
        }
    }
    
    return Integer.MAX_VALUE;  // No collision
}
```

**Push Direction:**
- Always toward the "outside" of the gate
- Derived from FaceDirection + GateType
- Example: North-facing portcullis → push entities north (away from gate)

**Push Calculation:**
```java
Vector getPushDirection(GateStructure gate) {
    // Use FaceDirection to determine outward direction
    Vector baseDirection = FaceDirection.toVector();  // e.g., NORTH → (0, 0, -1)
    
    // For DRAWBRIDGE, push is perpendicular to hinge
    if (gate.GateType == DRAWBRIDGE) {
        baseDirection = crossProduct(hingeAxis, normalVector);
    }
    
    // Normalize and scale by push force
    return baseDirection.normalize().multiply(0.5);  // 0.5 blocks/tick
}
```

---

### Safety & Physics Handling

**Falling Blocks:**
- When gate blocks are removed, adjacent gravel/sand may fall
- Solution: Disable block physics during animation
  ```java
  world.setBlockData(pos, blockData, false);  // false = no physics update
  ```

**Fluid Flow:**
- Removing gate blocks may allow water/lava to flow
- Solution: Check for fluids in adjacent blocks; place temporary barriers
  ```java
  if (adjacentBlock.isLiquid()) {
      placeTemporaryBarrier(adjacentBlockPos);
  }
  ```

**Redstone Side Effects:**
- Gate blocks may trigger redstone updates
- Solution: Disable redstone events during animation
  ```java
  Bukkit.getPluginManager().registerEvents(new Listener() {
      @EventHandler
      public void onBlockRedstone(BlockRedstoneEvent event) {
          if (isGateBlock(event.getBlock())) {
              event.setNewCurrent(event.getOldCurrent());  // Cancel change
          }
      }
  }, plugin);
  ```

---

## Part G: Integration with Existing Systems

### Structure Inheritance

**GateStructure extends Structure:**
- Inherits: DomainId, DistrictId, StreetId
- Inherits: WorldPosition, Dimensions (if applicable)
- Inherits: CreatedAt, UpdatedAt timestamps
- Inherits: Owner / permissions (if Structure has this)

**Domain → District → Street → Structure Hierarchy:**
- Gates belong to a specific district (military, residential, etc.)
- Optional street assignment (gate at street entrance)
- Access rules inherit from domain/district/street
- Example: Only kingdom members can open castle gates

---

### WorldGuard Integration

**Purpose:**
- Different access rules when gate is open vs. closed
- Example: No entry when closed; passage allowed when open

**Implementation:**
- `RegionClosedId`: WorldGuard region ID when gate is CLOSED
- `RegionOpenedId`: WorldGuard region ID when gate is OPEN
- Plugin updates active region based on current state

**Example Workflow:**
```java
void onGateStateChange(GateStructure gate, AnimationState newState) {
    if (newState == OPEN) {
        worldGuard.disableRegion(gate.RegionClosedId);
        worldGuard.enableRegion(gate.RegionOpenedId);
    } else if (newState == CLOSED) {
        worldGuard.disableRegion(gate.RegionOpenedId);
        worldGuard.enableRegion(gate.RegionClosedId);
    }
}
```

**Region Definitions (admin-created):**
- Closed region: Tight bounding box around gate blocks
- Open region: May be same size or smaller (allow passage)
- Flags: `entry: deny` (closed), `entry: allow` (open)

---

### Health & Respawn System

**Health Mechanics:**
- `HealthCurrent`: Decremented when gate takes damage (TNT, siege weapons, etc.)
- `HealthMax`: Maximum HP; can be upgraded
- `IsInvincible`: If true, gate cannot be damaged
- `IsDestroyed`: Set to true when HealthCurrent reaches 0

**Damage Sources (future):**
- TNT explosions
- Siege weapons (catapults, battering rams - if implemented)
- Player attacks (if configured)

**Respawn Logic:**
```java
void onGateDestroyed(GateStructure gate) {
    gate.IsDestroyed = true;
    gate.IsOpened = false;  // Forced to closed state
    gate.IsActive = false;  // Disable animation
    
    // Remove all gate blocks
    removeGateBlocks(gate);
    
    if (gate.CanRespawn) {
        // Schedule respawn
        scheduler.runTaskLater(() -> {
            gate.HealthCurrent = gate.HealthMax;
            gate.IsDestroyed = false;
            gate.IsActive = true;
            restoreGateBlocks(gate);
            notifyAdmins("Gate " + gate.Name + " has respawned");
        }, gate.RespawnRateSeconds * 20);  // Convert seconds to ticks
    }
}
```

---

### Access Control & Permissions

**Permission Nodes (Paper plugin):**
```
knk.gate.open.<gateId>       - Can open specific gate
knk.gate.open.*              - Can open all gates
knk.gate.close.<gateId>      - Can close specific gate
knk.gate.admin               - Full gate management
knk.gate.admin.create        - Create new gates
knk.gate.admin.delete        - Delete gates
knk.gate.admin.configure     - Edit gate settings
```

**Permission Sources:**
- Domain ownership (gate owner can always open)
- District/street membership (faction members can open)
- Explicit permission grants (custom access lists)
- Temporary access (guest pass, timed access)

**Example Check:**
```java
boolean canOpenGate(Player player, GateStructure gate) {
    // Admin override
    if (player.hasPermission("knk.gate.admin")) return true;
    
    // Specific gate permission
    if (player.hasPermission("knk.gate.open." + gate.Id)) return true;
    
    // Wildcard permission
    if (player.hasPermission("knk.gate.open.*")) return true;
    
    // Domain ownership
    if (isOwner(player, gate.DomainId)) return true;
    
    // District membership
    if (isMember(player, gate.DistrictId)) return true;
    
    return false;
}
```

---

## Part H: Storage & Database Schema

### MySQL Schema (v2 API)

**GateStructures Table (extends Structures):**
```sql
CREATE TABLE GateStructures (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    -- Inherited from Structure
    DomainId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    DistrictId INT NOT NULL,
    StreetId INT NULL,
    CreatedAt DATETIME NOT NULL,
    UpdatedAt DATETIME NOT NULL,
    
    -- Gate-specific fields
    IsActive BOOLEAN DEFAULT FALSE,
    CanRespawn BOOLEAN DEFAULT TRUE,
    IsDestroyed BOOLEAN DEFAULT FALSE,
    IsInvincible BOOLEAN DEFAULT TRUE,
    IsOpened BOOLEAN DEFAULT FALSE,
    HealthCurrent DOUBLE DEFAULT 500.0,
    HealthMax DOUBLE DEFAULT 500.0,
    FaceDirection VARCHAR(20) DEFAULT 'north',
    RespawnRateSeconds INT DEFAULT 300,
    IconMaterialRefId INT NULL,
    RegionClosedId VARCHAR(255) DEFAULT '',
    RegionOpenedId VARCHAR(255) DEFAULT '',
    
    -- Animation system fields
    GateType VARCHAR(50) DEFAULT 'SLIDING',
    GeometryDefinitionMode VARCHAR(50) DEFAULT 'PLANE_GRID',
    MotionType VARCHAR(50) DEFAULT 'VERTICAL',
    AnimationDurationTicks INT DEFAULT 60,
    AnimationTickRate INT DEFAULT 1,
    
    -- PLANE_GRID mode
    AnchorPoint TEXT,
    ReferencePoint1 TEXT,
    ReferencePoint2 TEXT,
    GeometryWidth INT DEFAULT 0,
    GeometryHeight INT DEFAULT 0,
    GeometryDepth INT DEFAULT 0,
    
    -- FLOOD_FILL mode
    SeedBlocks TEXT,
    ScanMaxBlocks INT DEFAULT 500,
    ScanMaxRadius INT DEFAULT 20,
    ScanMaterialWhitelist TEXT,
    ScanMaterialBlacklist TEXT,
    ScanPlaneConstraint BOOLEAN DEFAULT FALSE,
    
    -- Block management
    FallbackMaterialRefId INT NULL,
    TileEntityPolicy VARCHAR(50) DEFAULT 'DECORATIVE_ONLY',
    
    -- Rotation-specific
    RotationMaxAngleDegrees INT DEFAULT 90,
    HingeAxis TEXT,
    
    -- Double doors
    LeftDoorSeedBlock TEXT,
    RightDoorSeedBlock TEXT,
    MirrorRotation BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (DomainId) REFERENCES Domains(Id),
    FOREIGN KEY (DistrictId) REFERENCES Districts(Id),
    FOREIGN KEY (StreetId) REFERENCES Streets(Id),
    FOREIGN KEY (IconMaterialRefId) REFERENCES MinecraftMaterialRefs(Id),
    FOREIGN KEY (FallbackMaterialRefId) REFERENCES MinecraftMaterialRefs(Id),
    
    INDEX idx_gate_type (GateType),
    INDEX idx_is_active (IsActive),
    INDEX idx_is_opened (IsOpened),
    UNIQUE INDEX idx_name_domain (Name, DomainId)
);
```

**GateBlockSnapshots Table:**
```sql
CREATE TABLE GateBlockSnapshots (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    GateStructureId INT NOT NULL,
    
    RelativeX INT NOT NULL,
    RelativeY INT NOT NULL,
    RelativeZ INT NOT NULL,
    
    MinecraftBlockRefId INT NULL,
    SortOrder INT NOT NULL,
    
    FOREIGN KEY (GateStructureId) REFERENCES GateStructures(Id) ON DELETE CASCADE,
    FOREIGN KEY (MinecraftBlockRefId) REFERENCES MinecraftBlockRefs(Id),
    
    INDEX idx_gate_id (GateStructureId),
    INDEX idx_sort_order (GateStructureId, SortOrder)
);
```

---

## Part I: Web App Configuration UI

### Admin Wizard Requirements

**Wizard Steps (Gate Creation):**

1. **Step 1: Basic Info**
   - Gate name (required)
   - Domain / District / Street selection (dropdown)
   - Icon material (searchable dropdown)
   - Health settings (HealthMax, IsInvincible, CanRespawn, RespawnRateSeconds)

2. **Step 2: Gate Type & Orientation**
   - Gate type selection (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS)
   - Face direction (8-way compass selector)
   - Show recommended geometry mode per gate type
   - Motion type (VERTICAL, LATERAL, ROTATION) - auto-selected based on gate type

3. **Step 3: Geometry Definition**
   - **If PLANE_GRID:**
     - 3D coordinate inputs for p0, p1, p2 (with visual preview)
     - Width/Height/Depth sliders
     - Live block count estimate
   - **If FLOOD_FILL:**
     - Seed block coordinate(s)
     - Scan limits (maxBlocks, maxRadius)
     - Material whitelist/blacklist (searchable)
     - Plane constraint toggle

4. **Step 4: Animation Settings**
   - Duration (seconds) → converted to ticks
   - Tick rate (1-5)
   - Rotation angle (if DRAWBRIDGE/DOUBLE_DOORS)
   - Preview animation (visual simulation)

5. **Step 5: Advanced Options**
   - Fallback material selection
   - Tile entity policy (dropdown)
   - WorldGuard region IDs (text input)
   - Access permissions (permission list)

6. **Step 6: Review & Create**
   - Summary of all settings
   - Block snapshot preview (list of materials)
   - "Create Gate" button
   - API call: POST /api/gates

**Visual Enhancements:**
- 3D preview widget (using Three.js or similar)
- Highlight selected blocks in preview
- Animation playback simulation
- Color-coded gate type icons

---

### Edit Gate UI

**Edit Form:**
- Load existing gate via GET /api/gates/{id}
- Populate wizard with current values
- Allow changing all fields except:
  - Id (immutable)
  - DomainId (immutable - gate ownership cannot change)
  - GateType (changing type requires recapture - admin warning)
- Save changes: PUT /api/gates/{id}

**Recapture Geometry:**
- Button: "Recapture Blocks"
- Triggers DELETE /api/gates/{id}/snapshots + recapture logic
- Use case: Gate structure modified in-game

---

## Part J: Paper Plugin Architecture

### Plugin Responsibilities

**Core Functions:**
1. **Load Gate Definitions**
   - On plugin startup, query API for active gates
   - Cache gate definitions + block snapshots in memory
   - Index by gateId for fast lookup

2. **Animation Execution**
   - Per-tick task: iterate gates in OPENING/CLOSING state
   - Calculate current frame based on elapsed ticks
   - Place/remove blocks at calculated positions
   - Check collision prediction; push entities if needed

3. **State Synchronization**
   - Update API when gate state changes (CLOSED ↔ OPEN)
   - Persist IsOpened field via PUT /api/gates/{id}

4. **Command Handling**
   - `/gate open <name>` - Open gate
   - `/gate close <name>` - Close gate
   - `/gate info <name>` - Show gate status
   - `/gate reload` - Reload gates from API

5. **Event Handling**
   - Block break in gate area → prevent/damage gate
   - Player interact → trigger open/close
   - Entity spawn in gate area → push away

---

### Plugin Data Structures

**In-Memory Gate Cache:**
```java
class CachedGate {
    int id;
    String name;
    GateType gateType;
    AnimationState currentState;  // CLOSED, OPENING, OPEN, CLOSING
    int currentFrame;
    long animationStartTime;
    
    // Geometry
    List<BlockSnapshot> blocks;
    Vector anchorPoint;
    Vector hingeAxis;
    
    // Configuration
    int animationDurationTicks;
    int animationTickRate;
    MotionType motionType;
    
    // Precomputed data
    Vector uAxis, vAxis, nAxis;  // Local coordinate basis
    Vector motionVector;
}

class BlockSnapshot {
    Vector relativePos;
    BlockData blockData;
    int sortOrder;
}
```

**Animation Tick Task:**
```java
@Override
public void run() {
    long currentTick = server.getCurrentTick();
    
    for (CachedGate gate : gates.values()) {
        if (gate.currentState != OPENING && gate.currentState != CLOSING) {
            continue;  // Skip idle gates
        }
        
        // Calculate current frame
        long elapsedTicks = currentTick - gate.animationStartTime;
        int currentFrame = (int) (elapsedTicks / gate.animationTickRate);
        
        // Clamp to valid range
        if (currentFrame >= gate.totalFrames) {
            // Animation complete
            finishAnimation(gate);
            continue;
        }
        
        // Update gate
        gate.currentFrame = currentFrame;
        updateGateBlocks(gate, currentFrame);
        checkEntityCollisions(gate, currentFrame);
    }
}
```

---

## Part K: Performance Requirements

### Target Metrics

**Gate Count:**
- Target: ~100 active gates
- Maximum: 200 gates (design limit)

**Animation Performance:**
- 20 TPS maintained with 10 gates animating simultaneously
- 18+ TPS with 20 gates animating simultaneously
- Acceptable lag: <50ms per tick

**Memory:**
- Per gate: 32 KB (500 blocks × 64 bytes)
- 100 gates: 3.2 MB total
- Maximum plugin memory: 50 MB (includes other features)

**Block Update Rate:**
- Single gate: 500 blocks / 60 frames = ~8 blocks/tick
- 10 gates: ~80 blocks/tick
- Batched chunk updates: <5ms per chunk

---

### Optimization Checklist

✅ **Lazy Updates**: Only animate gates in OPENING/CLOSING  
✅ **Precomputed Data**: Cache local basis, motion vectors  
✅ **Batched Block Updates**: Group by chunk  
✅ **Chunk Load Check**: Skip if chunk unloaded  
✅ **Frame Skip on Lag**: Jump to final position if TPS < 15  
✅ **Indexed Queries**: Fast gate lookup by ID/name  
✅ **Collision Prediction**: Check only entities within 5-block radius  
✅ **Stable Sort**: Deterministic block placement order  

---

## Part L: Non-Goals (v1)

The following features are **explicitly excluded** from v1:

❌ **Visual-Only Animation** (client-side packets)  
- Reason: Requires complex packet management; no collision
- Future: Consider for decorative gates only

❌ **Moving Inventory Tile Entities** (chests, barrels)  
- Reason: Inventory serialization, dupe exploits
- Future: May support in v2 with strict controls

❌ **Redstone Simulation During Animation**  
- Reason: Complex side effects, performance cost
- Future: May allow basic redstone if requested

❌ **Damage to Entities During Animation**  
- Reason: Gate should push, not damage (current design)
- Future: Optional damage mode for siege warfare

❌ **Sound Effects / Particle Effects**  
- Reason: Focus on core mechanics first
- Future: Add in polish phase

❌ **Multi-Gate Synchronization**  
- Reason: Complex timing coordination
- Example: Open 3 portcullises simultaneously
- Future: Admin-triggered gate groups

---

## Part M: Admin UX Guidelines

### Recommended Defaults Per Gate Type

| Gate Type | Geometry Mode | Motion Type | Duration | Angle |
|-----------|---------------|-------------|----------|-------|
| SLIDING | PLANE_GRID | VERTICAL | 3 sec | N/A |
| TRAP | PLANE_GRID | VERTICAL | 1 sec | N/A |
| DRAWBRIDGE | PLANE_GRID | ROTATION | 4 sec | 90° |
| DOUBLE_DOORS | FLOOD_FILL | ROTATION | 2 sec | 90° |

### Wizard Tips

**PLANE_GRID Mode:**
- Show helper text: "Stand at hinge-left corner, note coordinates (p0)"
- Visual indicator: Red particle at p0, green at p1, blue at p2
- Auto-calculate width from p0→p1 distance
- Validate: Ensure p0, p1, p2 form valid coordinate basis

**FLOOD_FILL Mode:**
- Show helper text: "Click seed block (e.g., bottom-left door hinge)"
- Live preview: Highlight blocks that will be scanned
- Warning if scan exceeds maxBlocks: "Selection too large, increase limit or add material filter"

**Animation Preview:**
- Render animation in 3D widget
- Show motion path (arrows/trajectory)
- Display frame count, duration, block count

---

## Part N: Migration & Deployment

### Existing GateStructure Migration

**Current State:**
- GateStructure.cs exists with basic fields
- No animation system deployed

**Migration Steps:**

1. **Database Schema Update**
   ```sql
   ALTER TABLE GateStructures ADD COLUMN GateType VARCHAR(50) DEFAULT 'SLIDING';
   ALTER TABLE GateStructures ADD COLUMN GeometryDefinitionMode VARCHAR(50) DEFAULT 'PLANE_GRID';
   -- (Add all new columns with sensible defaults)
   ```

2. **Create GateBlockSnapshots Table**
   ```sql
   CREATE TABLE GateBlockSnapshots (...);
   ```

3. **Backfill Existing Gates**
   - Admin must recapture block geometry for existing gates
   - Provide bulk "Recapture All" tool in web app
   - API endpoint: POST /api/gates/bulk-recapture

4. **Plugin Update**
   - Deploy new plugin version with animation system
   - Load gate definitions from API on startup
   - Begin animation tick task

---

### Rollback Plan

**If issues arise:**

1. **Disable Animation System**
   - Set `IsActive = false` for all gates via SQL
   - Plugin skips all animation (gates remain static)

2. **Revert to Static Gates**
   - Keep CLOSED state blocks in place
   - Remove OPEN state blocks (force all gates closed)

3. **Plugin Rollback**
   - Deploy previous plugin version without animation
   - Gates remain as static structures

---

## Part O: Testing & Validation

### Test Scenarios

**Functional Testing:**

1. **Basic Gate Open/Close**
   - Create SLIDING gate (PLANE_GRID)
   - Trigger `/gate open`
   - Verify: Blocks move upward over 3 seconds
   - Trigger `/gate close`
   - Verify: Blocks restore to original positions

2. **Diagonal Gate**
   - Create gate facing north-east
   - Verify: Local basis calculated correctly
   - Verify: Blocks animate along correct axis

3. **Drawbridge Rotation**
   - Create DRAWBRIDGE gate
   - Verify: Blocks rotate around hinge line
   - Verify: No block collision errors

4. **Double Doors**
   - Create DOUBLE_DOORS gate (FLOOD_FILL)
   - Verify: Two separate door leaves detected
   - Verify: Doors open in opposite directions

5. **Entity Push**
   - Stand in gate path
   - Trigger open
   - Verify: Player pushed away when collision imminent (not immediately)

6. **Health & Respawn**
   - Damage gate to 0 HP
   - Verify: Gate destroyed, blocks removed
   - Wait RespawnRateSeconds
   - Verify: Gate respawns with full HP

**Performance Testing:**

1. **Load Test: 100 Gates**
   - Create 100 SLIDING gates
   - Measure plugin memory usage (target: <50 MB)
   - Open 10 gates simultaneously
   - Verify: Server TPS ≥ 18

2. **Stress Test: 20 Animating Gates**
   - Open 20 gates at once
   - Measure TPS, tick duration
   - Verify: No server crash, acceptable lag

**Edge Cases:**

1. **Chunk Unload During Animation**
   - Start animation
   - Unload chunk (teleport far away)
   - Reload chunk
   - Verify: Animation resumes or completes gracefully

2. **Server Restart During Animation**
   - Start animation
   - Restart server (mid-animation)
   - Verify: Gate resets to CLOSED or OPEN (not stuck mid-frame)

3. **Block Break in Gate Area**
   - Break gate block
   - Verify: Gate health decreases or block prevented

4. **Concurrent Access**
   - Two players trigger `/gate open` simultaneously
   - Verify: No duplicate animation, state consistency

---

## Appendices

### Appendix A: FaceDirection Values

**Supported Values:**
```
north, north-east, east, south-east, south, south-west, west, north-west
```

**Vector Mappings:**
```
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

### Appendix B: Example JSON Payloads

**Create SLIDING Gate (PLANE_GRID):**
```json
{
  "name": "Castle Portcullis",
  "domainId": 1,
  "districtId": 5,
  "streetId": null,
  "gateType": "SLIDING",
  "geometryDefinitionMode": "PLANE_GRID",
  "motionType": "VERTICAL",
  "faceDirection": "north",
  "anchorPoint": "{\"x\":100,\"y\":64,\"z\":100}",
  "referencePoint1": "{\"x\":105,\"y\":64,\"z\":100}",
  "referencePoint2": "{\"x\":100,\"y\":64,\"z\":99}",
  "geometryWidth": 6,
  "geometryHeight": 8,
  "geometryDepth": 1,
  "animationDurationTicks": 60,
  "animationTickRate": 1,
  "healthMax": 1000.0,
  "isInvincible": false,
  "canRespawn": true,
  "respawnRateSeconds": 600,
  "fallbackMaterialRefId": 42,
  "tileEntityPolicy": "DECORATIVE_ONLY"
}
```

**Create DOUBLE_DOORS Gate (FLOOD_FILL):**
```json
{
  "name": "Grand Entrance",
  "domainId": 1,
  "districtId": 5,
  "gateType": "DOUBLE_DOORS",
  "geometryDefinitionMode": "FLOOD_FILL",
  "motionType": "ROTATION",
  "faceDirection": "south",
  "leftDoorSeedBlock": "{\"x\":100,\"y\":64,\"z\":100}",
  "rightDoorSeedBlock": "{\"x\":105,\"y\":64,\"z\":100}",
  "scanMaxBlocks": 200,
  "scanMaxRadius": 10,
  "mirrorRotation": true,
  "rotationMaxAngleDegrees": 90,
  "animationDurationTicks": 40,
  "healthMax": 500.0,
  "fallbackMaterialRefId": 43
}
```

---

### Appendix C: API Endpoints (Summary)

**GateStructures:**
- `GET /api/gates` - List all gates
- `GET /api/gates/{id}` - Get gate by ID
- `POST /api/gates` - Create new gate
- `PUT /api/gates/{id}` - Update gate
- `DELETE /api/gates/{id}` - Delete gate
- `PUT /api/gates/{id}/state` - Update IsOpened state
- `POST /api/gates/{id}/recapture` - Recapture block snapshot
- `DELETE /api/gates/{id}/snapshots` - Clear snapshots
- `GET /api/gates/domain/{domainId}` - Get gates by domain

**GateBlockSnapshots:**
- `GET /api/gates/{id}/snapshots` - Get all snapshots for gate
- `POST /api/gates/{id}/snapshots/bulk` - Create snapshots in bulk

---

### Appendix D: Plugin Commands

**Player Commands:**
```
/gate open <name>      - Open gate (requires permission)
/gate close <name>     - Close gate (requires permission)
/gate info <name>      - Show gate status and health
/gate list             - List nearby gates (within 50 blocks)
```

**Admin Commands:**
```
/gate admin create <name> <type>  - Start gate creation wizard
/gate admin delete <name>         - Delete gate
/gate admin reload                - Reload gates from API
/gate admin recapture <name>      - Recapture block snapshot
/gate admin health <name> <amount> - Set gate health
/gate admin repair <name>         - Instant repair (full HP)
/gate admin tp <name>             - Teleport to gate anchor
```

---

### Appendix E: Permission Nodes (Complete List)

**Player Permissions:**
```
knk.gate.open.<gateId>       - Open specific gate
knk.gate.open.*              - Open all gates
knk.gate.close.<gateId>      - Close specific gate
knk.gate.close.*             - Close all gates
knk.gate.info                - View gate information
knk.gate.list                - List nearby gates
```

**Admin Permissions:**
```
knk.gate.admin               - Full admin access (implies all below)
knk.gate.admin.create        - Create gates
knk.gate.admin.delete        - Delete gates
knk.gate.admin.configure     - Edit gate settings
knk.gate.admin.reload        - Reload gate definitions
knk.gate.admin.recapture     - Recapture snapshots
knk.gate.admin.health        - Modify gate health
knk.gate.admin.bypass        - Bypass all access checks
```

---

**End of Requirements Document**
