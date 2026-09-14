# SPEC: Gate Animation System (Source-Grounded)

This specification is derived from:
- **Current entity model**: GateStructure.cs
- **Game requirements**: Block-based animation, diagonal support, multi-gate types
- **Technical constraints**: Minecraft Paper API, server performance, deterministic behavior
- **Integration points**: Web API, WorldGuard, Structure/Domain system

All domain concepts are grounded in actual requirements and existing architecture. TBD sections identify implementation decisions requiring stakeholder confirmation.

---

## Part A: Core Entity Architecture

### GateStructure Entity (Confirmed from GateStructure.cs)

**Confirmed Fields (v2 Architecture):**
- `Id: int` (Primary Key, auto-generated)
- `DomainId: int` (Foreign Key → Domain; inherited from Structure)
- `Name: string` (gate display name)
- `DistrictId: int` (Foreign Key → District)
- `StreetId: int?` (Optional Foreign Key → Street)
- `IsActive: bool` (gate animation system enabled; default false)
- `CanRespawn: bool` (auto-repair after destruction; default true)
- `IsDestroyed: bool` (health reached zero; default false)
- `IsInvincible: bool` (cannot take damage; default true)
- `IsOpened: bool` (current state: false=CLOSED, true=OPEN; default false)
- `HealthCurrent: double` (current hit points; default 500.0)
- `HealthMax: double` (maximum hit points; default 500.0)
- `FaceDirection: string` (orientation: north, north-east, east, etc.; default "north")
- `RespawnRateSeconds: int` (auto-repair delay; default 300 = 5 minutes)
- `IconMaterialRefId: int?` (Foreign Key → MinecraftMaterialRef; nullable)
- `RegionClosedId: string` (WorldGuard region ID when closed; default empty)
- `RegionOpenedId: string` (WorldGuard region ID when open; default empty)

**Architectural Context:**
- GateStructure extends Structure (inherits DomainId, DistrictId, StreetId)
- Structure extends Domain (inherits world position, ownership, permissions)
- Gates are specialized structures within the Knights & Kings domain system
- Integration with WorldGuard for access control per state

**Use-Cases:**
- Define animated gates at strategic locations (city walls, bridges, dungeons)
- Control access based on gate state (closed = no entry, open = passage)
- Implement siege mechanics (damage gates, trigger respawn)
- Support diagonal city layouts (north-east oriented walls, etc.)

**Constraints:**
- `Id` is immutable once created
- `DomainId` is immutable (gate cannot change ownership domain)
- `FaceDirection` must be one of 8 cardinal/diagonal directions
- `IsOpened` reflects final state only (CLOSED or OPEN, not mid-animation)
- `HealthCurrent` cannot exceed `HealthMax`
- `HealthCurrent` cannot go below 0 (floor at zero)

---

### Required Entity Extensions (v2 Animation System)

**Gate Type & Geometry Fields:**
```csharp
public string GateType { get; set; } = "SLIDING";    
// Enum: SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
// Determines animation behavior and recommended geometry mode

public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
// Enum: PLANE_GRID, FLOOD_FILL
// How moving blocks are identified
```

**Motion Configuration:**
```csharp
public string MotionType { get; set; } = "VERTICAL";
// Enum: VERTICAL, LATERAL, ROTATION
// Direction/type of animation

public int AnimationDurationTicks { get; set; } = 60;
// Animation length in server ticks (default 60 = 3 seconds @ 20 TPS)

public int AnimationTickRate { get; set; } = 1;
// Frames per tick (1 = every tick, 2 = every other tick, etc.)
```

**PLANE_GRID Geometry Definition:**
```csharp
public string AnchorPoint { get; set; } = string.Empty;     
// JSON: {x, y, z} - p0 (hinge-left/top-left corner)

public string ReferencePoint1 { get; set; } = string.Empty; 
// JSON: {x, y, z} - p1 (hinge-right/top-right corner)

public string ReferencePoint2 { get; set; } = string.Empty; 
// JSON: {x, y, z} - p2 (forward reference point)

public int GeometryWidth { get; set; } = 0;          // Grid width (blocks)
public int GeometryHeight { get; set; } = 0;         // Grid height (blocks)
public int GeometryDepth { get; set; } = 0;          // Grid depth (blocks)
```

**FLOOD_FILL Geometry Definition:**
```csharp
public string SeedBlocks { get; set; } = string.Empty;      
// JSON array: [{x,y,z}, ...] - starting points for flood fill

public int ScanMaxBlocks { get; set; } = 500;        // Safety limit
public int ScanMaxRadius { get; set; } = 20;         // Max Manhattan distance from seed
public string ScanMaterialWhitelist { get; set; } = string.Empty; 
// JSON array of material IDs (empty = all materials)

public string ScanMaterialBlacklist { get; set; } = string.Empty; 
// JSON array of material IDs to exclude

public bool ScanPlaneConstraint { get; set; } = false; 
// Restrict to single Y-plane
```

**Block Management:**
```csharp
public int? FallbackMaterialRefId { get; set; }      
// Foreign Key → MinecraftMaterialRef
// Used when snapshot restoration fails

public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";
// Enum: NONE, DECORATIVE_ONLY, ALL
// Controls which tile entities are preserved
```

**Rotation-Specific (Drawbridge, Double Doors):**
```csharp
public int RotationMaxAngleDegrees { get; set; } = 90; 
// Max rotation angle (default 90°)

public string HingeAxis { get; set; } = string.Empty;  
// JSON: {x,y,z} - rotation axis vector (p0→p1)
```

**Double Doors Specific:**
```csharp
public string LeftDoorSeedBlock { get; set; } = string.Empty;  
// JSON: {x,y,z} - left door hinge

public string RightDoorSeedBlock { get; set; } = string.Empty; 
// JSON: {x,y,z} - right door hinge

public bool MirrorRotation { get; set; } = true;      
// Doors open in opposite directions
```

---

### GateBlockSnapshot Entity (New - Block Storage)

**Purpose:**
- Store exact block state for each block in gate's closed position
- Support accurate restoration during close animation
- Enable block-based (not entity-based) animation

**Confirmed Fields:**
```csharp
public class GateBlockSnapshot
{
    public int Id { get; set; }                      // Primary Key
    public int GateStructureId { get; set; }         // Foreign Key → GateStructure
    public GateStructure GateStructure { get; set; } // Navigation property
    
    public int RelativeX { get; set; }               // Position relative to anchor
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    
    public int? MinecraftBlockRefId { get; set; }    // Foreign Key → MinecraftBlockRef
    public MinecraftBlockRef? BlockRef { get; set; }
    
    public int SortOrder { get; set; }               // Animation sequence order
}
```

**Use-Cases:**
- Capture gate blocks when gate is first defined (closed state)
- Restore blocks during close animation
- Deterministic animation order (prevent block collision conflicts)

**Constraints:**
- One GateStructure has many GateBlockSnapshots (1:N relationship)
- Snapshots are immutable once captured (recapture to update)
- RelativeX/Y/Z are relative to AnchorPoint (not world coordinates)
- SortOrder is calculated during capture (hinge → outward)

---

## Part B: Gate Type System (Confirmed Behavior)

### Supported Gate Types (v1)

**SLIDING:**
- **Motion**: Vertical lift (portcullis) or lateral slide
- **Geometry Mode**: PLANE_GRID (recommended)
- **Rotation**: No
- **Typical Use**: City gate portcullis, sliding wall section
- **Motion Type**: VERTICAL (lift) or LATERAL (slide)

**TRAP:**
- **Motion**: Vertical drop or lift
- **Geometry Mode**: PLANE_GRID (recommended)
- **Rotation**: No
- **Typical Use**: Trap door over pit, floor hatch
- **Motion Type**: VERTICAL

**DRAWBRIDGE:**
- **Motion**: Rotation around hinge line
- **Geometry Mode**: PLANE_GRID (recommended)
- **Rotation**: Yes (around p0→p1 axis)
- **Typical Use**: Castle drawbridge over moat
- **Motion Type**: ROTATION
- **Rotation Angle**: 0° (closed) → 90° (open, default)

**DOUBLE_DOORS:**
- **Motion**: Two independent rotations around individual hinges
- **Geometry Mode**: FLOOD_FILL (recommended)
- **Rotation**: Yes (mirrored)
- **Typical Use**: Large entrance doors, throne room gates
- **Motion Type**: ROTATION
- **Rotation Angle**: 0° (closed) → 90° (open, default)

---

### Motion Type Characteristics

**VERTICAL:**
- Direction: +Y (lift) or -Y (drop)
- Axis: World Y-axis or local normal (if diagonal)
- Calculation: `motionVector = new Vector(0, GeometryHeight, 0)`
- Used by: SLIDING (portcullis), TRAP

**LATERAL:**
- Direction: Perpendicular to FaceDirection in horizontal plane
- Axis: Local U or V axis (depends on FaceDirection)
- Calculation: `motionVector = uAxis * GeometryWidth` or `vAxis * GeometryDepth`
- Used by: SLIDING (sliding wall variant)

**ROTATION:**
- Direction: Rotation around hinge line (p0→p1)
- Axis: Normalized vector from p0 to p1
- Calculation: `rotateAroundAxis(relativePos, hingeAxis, currentAngle)`
- Used by: DRAWBRIDGE, DOUBLE_DOORS

---

## Part C: Geometry Definition Modes (Detailed Specification)

### PLANE_GRID Mode

**Concept:**
- Define gate using 3 reference points (p0, p1, p2)
- Construct local coordinate system (u, v, n)
- Generate rectangular grid in local space
- Map grid to world block positions

**Input Requirements:**
```
AnchorPoint (p0):     {x: 100, y: 64, z: 100}  // Hinge-left / top-left
ReferencePoint1 (p1): {x: 105, y: 64, z: 100}  // Hinge-right / top-right
ReferencePoint2 (p2): {x: 100, y: 64, z: 99}   // Forward reference
GeometryWidth:  6  // Blocks along p0→p1
GeometryHeight: 8  // Blocks along vertical/normal
GeometryDepth:  1  // Blocks along forward direction
```

**Local Coordinate System Construction:**
```java
// u = width axis (along hinge)
Vector u = p1.subtract(p0).normalize();

// forward = temporary forward direction
Vector forward = p2.subtract(p0).normalize();

// n = normal (perpendicular to gate plane)
Vector n = u.crossProduct(forward).normalize();

// v = depth axis (corrected forward)
Vector v = n.crossProduct(u).normalize();
```

**Grid Generation Algorithm:**
```java
List<BlockSnapshot> snapshots = new ArrayList<>();
int sortOrder = 0;

for (int h = 0; h < GeometryHeight; h++) {
    for (int w = 0; w < GeometryWidth; w++) {
        for (int d = 0; d < GeometryDepth; d++) {
            // Calculate world position
            Vector worldPos = p0.clone()
                .add(u.multiply(w))
                .add(n.multiply(h))
                .add(v.multiply(d));
            
            // Round to nearest block coordinate
            int x = (int) Math.round(worldPos.getX());
            int y = (int) Math.round(worldPos.getY());
            int z = (int) Math.round(worldPos.getZ());
            
            // Capture block at this position
            Block block = world.getBlockAt(x, y, z);
            
            // Store snapshot
            GateBlockSnapshot snapshot = new GateBlockSnapshot();
            snapshot.RelativeX = w;
            snapshot.RelativeY = h;
            snapshot.RelativeZ = d;
            snapshot.MinecraftBlockRefId = getOrCreateBlockRef(block);
            snapshot.SortOrder = sortOrder++;
            
            snapshots.add(snapshot);
        }
    }
}
```

**Diagonal Support:**
- Local basis vectors (u, v, n) automatically handle diagonal orientation
- Example: Gate facing north-east
  - p0: {100, 64, 100}
  - p1: {105, 64, 95} (diagonal line)
  - u = normalize({5, 0, -5}) = {0.707, 0, -0.707}
  - Grid blocks follow diagonal orientation

**Validation:**
- p0, p1, p2 must not be collinear (would result in zero normal vector)
- GeometryWidth must match distance(p0, p1) ± tolerance
- All world positions must be valid block coordinates (integer after rounding)

---

### FLOOD_FILL Mode

**Concept:**
- Start from one or more seed blocks
- Use breadth-first search (BFS) to find connected blocks
- Apply material filters and distance limits
- Ideal for irregular shapes (doors, decorative gates)

**Input Requirements:**
```
SeedBlocks: [
  {x: 100, y: 64, z: 100},  // Left door hinge
  {x: 105, y: 64, z: 100}   // Right door hinge (for double doors)
]
ScanMaxBlocks: 500          // Safety limit
ScanMaxRadius: 20           // Max Manhattan distance from seed
ScanMaterialWhitelist: []   // Empty = all materials
ScanMaterialBlacklist: [9, 10, 11]  // Water, lava, air IDs
ScanPlaneConstraint: false  // Allow 3D scan
```

**Flood Fill Algorithm:**
```java
List<BlockSnapshot> snapshots = new ArrayList<>();
Queue<Block> queue = new LinkedList<>();
Set<Block> visited = new HashSet<>();

// Initialize with seed blocks
for (Vector seed : seedBlocks) {
    Block seedBlock = world.getBlockAt(
        (int) seed.getX(), 
        (int) seed.getY(), 
        (int) seed.getZ()
    );
    queue.add(seedBlock);
    visited.add(seedBlock);
}

while (!queue.isEmpty() && snapshots.size() < ScanMaxBlocks) {
    Block current = queue.poll();
    
    // Check distance from nearest seed
    int minDist = Integer.MAX_VALUE;
    for (Vector seed : seedBlocks) {
        int dist = manhattanDistance(current.getLocation(), seed);
        minDist = Math.min(minDist, dist);
    }
    
    if (minDist > ScanMaxRadius) {
        continue;  // Too far from seed
    }
    
    // Check plane constraint
    if (ScanPlaneConstraint) {
        int seedY = (int) seedBlocks.get(0).getY();
        if (current.getY() != seedY) {
            continue;  // Not on same Y-plane
        }
    }
    
    // Check material filters
    int materialId = getMaterialId(current.getType());
    if (!ScanMaterialWhitelist.isEmpty() && 
        !ScanMaterialWhitelist.contains(materialId)) {
        continue;  // Not in whitelist
    }
    if (ScanMaterialBlacklist.contains(materialId)) {
        continue;  // In blacklist
    }
    
    // Add to snapshot
    GateBlockSnapshot snapshot = new GateBlockSnapshot();
    snapshot.RelativeX = current.getX() - (int) seedBlocks.get(0).getX();
    snapshot.RelativeY = current.getY() - (int) seedBlocks.get(0).getY();
    snapshot.RelativeZ = current.getZ() - (int) seedBlocks.get(0).getZ();
    snapshot.MinecraftBlockRefId = getOrCreateBlockRef(current);
    snapshot.SortOrder = snapshots.size();
    snapshots.add(snapshot);
    
    // Enqueue neighbors (6-connectivity: ±X, ±Y, ±Z)
    for (BlockFace face : CARDINAL_FACES) {
        Block neighbor = current.getRelative(face);
        if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
        }
    }
}

// Post-process: Sort by distance from hinge (for animation order)
Vector hingePos = seedBlocks.get(0);
snapshots.sort((a, b) -> {
    double distA = distance(a.getWorldPosition(), hingePos);
    double distB = distance(b.getWorldPosition(), hingePos);
    return Double.compare(distA, distB);
});

// Update SortOrder after sorting
for (int i = 0; i < snapshots.size(); i++) {
    snapshots.get(i).SortOrder = i;
}
```

**Double Doors Usage:**
- Two seed blocks (left hinge, right hinge)
- Two separate flood fills
- Each door stored as separate snapshot group (via additional field or logic)
- Alternative: Store as two separate GateStructures with shared parent

**Validation:**
- At least one seed block required
- ScanMaxBlocks > 0
- ScanMaxRadius > 0
- If whitelist provided, must not be empty

---

## Part D: Block Management & Material System

### MinecraftBlockRef Integration (Confirmed from Existing Entity)

**Entity:**
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

**Use-Cases:**
- Store exact block state (orientation, hinge side, open/closed, waterlogged, etc.)
- Enable accurate restoration during animation
- Support complex multi-state blocks (doors, stairs, slabs, fence gates)

**BlockStateString Format:**
```
minecraft:oak_door[facing=north,half=upper,hinge=left,open=false,powered=false]
minecraft:oak_stairs[facing=east,half=bottom,shape=straight,waterlogged=false]
minecraft:stone_slab[type=top,waterlogged=false]
```

**Snapshot Capture Logic:**
```java
MinecraftBlockRef getOrCreateBlockRef(Block block) {
    // Serialize block state
    String namespaceKey = block.getType().getKey().toString();
    String blockStateString = block.getBlockData().getAsString();
    String logicalType = determineLogicalType(block.getType());
    
    // Check if this block ref already exists in database
    MinecraftBlockRef existing = blockRefRepository.findByKeyAndState(
        namespaceKey, 
        blockStateString
    );
    
    if (existing != null) {
        return existing;
    }
    
    // Create new block ref
    MinecraftBlockRef newRef = new MinecraftBlockRef();
    newRef.NamespaceKey = namespaceKey;
    newRef.BlockStateString = blockStateString;
    newRef.LogicalType = logicalType;
    newRef.IconUrl = generateIconUrl(block.getType());
    
    return blockRefRepository.save(newRef);
}
```

---

### Fallback Material System

**Purpose:**
- Handle snapshot restoration failures (corrupted data, version mismatch, etc.)
- Provide sensible default material for gate

**MinecraftMaterialRef (Existing Entity):**
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
```java
void restoreBlock(GateBlockSnapshot snapshot, Location worldPos) {
    try {
        // Attempt to restore from snapshot
        MinecraftBlockRef blockRef = snapshot.BlockRef;
        BlockData blockData = Bukkit.createBlockData(
            blockRef.NamespaceKey + blockRef.BlockStateString
        );
        world.setBlockData(worldPos, blockData);
    } catch (Exception e) {
        // Restoration failed; use fallback
        MinecraftMaterialRef fallback = gate.FallbackMaterial;
        Material material = Material.matchMaterial(fallback.NamespaceKey);
        
        if (material != null) {
            world.setType(worldPos, material);
            logWarning("Gate " + gate.Name + ": Block restoration failed at " 
                + worldPos + ", used fallback " + material);
        } else {
            // Ultimate fallback: stone
            world.setType(worldPos, Material.STONE);
            logError("Gate " + gate.Name + ": Fallback material invalid, used STONE");
        }
    }
}
```

**Recommended Fallback Materials:**
- SLIDING: Stone Bricks, Iron Blocks
- TRAP: Oak Planks, Stone
- DRAWBRIDGE: Oak Planks, Stone Bricks
- DOUBLE_DOORS: Oak Door (single material, not full state)

---

### Tile Entity Policy

**Tile Entity Categories:**

**DECORATIVE:**
- Signs (wall/standing)
- Banners (wall/floor)
- Skulls/heads
- Item frames (TBD)

**INVENTORY:**
- Chests
- Barrels
- Furnaces
- Hoppers
- Shulker boxes

**TileEntityPolicy Enum:**
```
NONE               - No tile entities (replaced with fallback)
DECORATIVE_ONLY    - Preserve decorative, replace inventory (default)
ALL                - All tile entities (future - requires inventory serialization)
```

**Implementation (v1):**
```java
GateBlockSnapshot captureBlock(Block block, TileEntityPolicy policy) {
    BlockState state = block.getState();
    
    if (state instanceof TileState) {
        // Check policy
        if (policy == NONE) {
            // Replace with fallback
            return createFallbackSnapshot(block.getLocation());
        } else if (policy == DECORATIVE_ONLY) {
            if (isInventoryTileEntity(state)) {
                // Replace inventory with solid block
                return createFallbackSnapshot(block.getLocation());
            } else if (isDecorativeTileEntity(state)) {
                // Preserve decorative
                return createSnapshotWithTileEntity(block, state);
            }
        } else if (policy == ALL) {
            // Not supported in v1
            throw new UnsupportedOperationException(
                "TileEntityPolicy.ALL not implemented in v1"
            );
        }
    }
    
    // Normal block (no tile entity)
    return createNormalSnapshot(block);
}

boolean isDecorativeTileEntity(BlockState state) {
    return state instanceof Sign 
        || state instanceof Banner 
        || state instanceof Skull;
}

boolean isInventoryTileEntity(BlockState state) {
    return state instanceof Chest 
        || state instanceof Barrel 
        || state instanceof Furnace 
        || state instanceof Hopper;
}
```

**Rationale:**
- Moving chests with items is complex (inventory duplication exploits)
- Decorative tile entities have minimal state (text, pattern, rotation)
- Default to DECORATIVE_ONLY for safety and simplicity

---

## Part E: Animation System (Detailed Specification)

### Animation State Machine

**States:**
```
CLOSED    - Gate fully closed; blocks in closed position; IsOpened=false
OPENING   - Animation in progress (closed → open)
OPEN      - Gate fully open; blocks in open position; IsOpened=true
CLOSING   - Animation in progress (open → closed)
JAMMED    - Animation blocked by obstacle (future - not implemented v1)
BROKEN    - Gate destroyed; HealthCurrent=0; IsDestroyed=true
```

**State Transitions:**
```
CLOSED → OPENING  
  Trigger: /gate open command + permission check
  Action: Set currentFrame=0, animationStartTime=currentTick

OPENING → OPEN    
  Trigger: currentFrame >= totalFrames
  Action: Set IsOpened=true, persist to DB, sync WorldGuard region

OPEN → CLOSING    
  Trigger: /gate close command + permission check
  Action: Set currentFrame=totalFrames, animationStartTime=currentTick

CLOSING → CLOSED  
  Trigger: currentFrame <= 0
  Action: Set IsOpened=false, persist to DB, sync WorldGuard region

Any State → BROKEN 
  Trigger: HealthCurrent reaches 0
  Action: Set IsDestroyed=true, IsActive=false, remove all blocks

BROKEN → CLOSED   
  Trigger: Respawn timer expires (after RespawnRateSeconds)
  Action: Set HealthCurrent=HealthMax, IsDestroyed=false, IsActive=true, 
          restore blocks, set IsOpened=false
```

**State Storage:**
- **Persisted**: `IsOpened` (bool - CLOSED or OPEN only)
- **Runtime (plugin memory)**: Current animation state, currentFrame, animationStartTime
- **Implication**: Server restart mid-animation → gate resets to persisted state (CLOSED or OPEN)

---

### Frame Calculation (Server-Tick Deterministic)

**Parameters:**
```java
int totalFrames = gate.AnimationDurationTicks / gate.AnimationTickRate;
// Example: 60 ticks / 1 tick = 60 frames
// Example: 60 ticks / 2 ticks = 30 frames (slower, choppier animation)

int currentFrame = (currentTick - animationStartTime) / gate.AnimationTickRate;
// Linear progression; clamped to [0, totalFrames]
```

**Linear Interpolation (VERTICAL/LATERAL):**
```java
// Example: Vertical lift (portcullis)
Vector motionVector = new Vector(0, gate.GeometryHeight, 0);  // Total movement
Vector stepVector = motionVector.divide(totalFrames);         // Movement per frame

for (GateBlockSnapshot snapshot : gate.blocks) {
    Vector closedPos = snapshot.getWorldPosition(gate.AnchorPoint);
    Vector offset = stepVector.multiply(currentFrame);
    Vector newPos = closedPos.add(offset);
    
    // Round to nearest block coordinate
    int x = (int) Math.round(newPos.getX());
    int y = (int) Math.round(newPos.getY());
    int z = (int) Math.round(newPos.getZ());
    
    Location blockLoc = new Location(world, x, y, z);
    
    // Place or remove block
    if (state == OPENING) {
        if (currentFrame == 0) {
            // First frame: remove from closed position
            world.setType(closedPos.toLocation(world), Material.AIR);
        }
        // Place at new position
        restoreBlock(snapshot, blockLoc);
    } else if (state == CLOSING) {
        if (currentFrame == totalFrames) {
            // First frame of closing: remove from open position
            Vector openPos = closedPos.add(motionVector);
            world.setType(openPos.toLocation(world), Material.AIR);
        }
        // Place at new position (moving back toward closed)
        restoreBlock(snapshot, blockLoc);
    }
}
```

**Rotation (DRAWBRIDGE, DOUBLE_DOORS):**
```java
// Example: Drawbridge rotation around hinge
Vector hingeAxis = gate.HingeAxis;  // Normalized vector p0→p1
double totalAngle = gate.RotationMaxAngleDegrees;  // e.g., 90°
double currentAngle = (currentFrame / (double) totalFrames) * totalAngle;

// Sort blocks by distance from hinge (stable order)
List<GateBlockSnapshot> sortedBlocks = gate.blocks.stream()
    .sorted(Comparator.comparingInt(GateBlockSnapshot::getSortOrder))
    .collect(Collectors.toList());

for (GateBlockSnapshot snapshot : sortedBlocks) {
    Vector closedPos = snapshot.getWorldPosition(gate.AnchorPoint);
    Vector relativePos = closedPos.subtract(gate.AnchorPoint);
    
    // Rotate around hinge axis
    Vector rotatedPos = rotateAroundAxis(relativePos, hingeAxis, currentAngle);
    Vector newWorldPos = gate.AnchorPoint.add(rotatedPos);
    
    // Round to nearest block coordinate
    int x = (int) Math.round(newWorldPos.getX());
    int y = (int) Math.round(newWorldPos.getY());
    int z = (int) Math.round(newWorldPos.getZ());
    
    Location blockLoc = new Location(world, x, y, z);
    
    // Last-write-wins: overwrite if collision
    restoreBlock(snapshot, blockLoc);
}

// Rotation helper
Vector rotateAroundAxis(Vector v, Vector axis, double angleDegrees) {
    double angleRad = Math.toRadians(angleDegrees);
    double cos = Math.cos(angleRad);
    double sin = Math.sin(angleRad);
    
    // Rodrigues' rotation formula
    Vector vRot = v.multiply(cos)
        .add(axis.crossProduct(v).multiply(sin))
        .add(axis.multiply(axis.dot(v)).multiply(1 - cos));
    
    return vRot;
}
```

---

### Block Placement Strategy (Collision Handling)

**Problem:**
- During rotation, multiple blocks may map to same world position
- Example: Drawbridge outer blocks overlap inner blocks mid-rotation

**Solution: Stable Sort Order + Last-Write-Wins**

**SortOrder Calculation (during snapshot capture):**
```java
// For PLANE_GRID: Sort by distance from hinge
snapshots.sort((a, b) -> {
    double distA = a.getRelativePosition().length();  // Distance from anchor
    double distB = b.getRelativePosition().length();
    return Double.compare(distA, distB);
});

// For FLOOD_FILL: Sort by distance from seed
snapshots.sort((a, b) -> {
    double distA = distance(a.getWorldPosition(), seedBlock);
    double distB = distance(b.getWorldPosition(), seedBlock);
    return Double.compare(distA, distB);
});

// Update SortOrder field
for (int i = 0; i < snapshots.size(); i++) {
    snapshots.get(i).SortOrder = i;
}
```

**Animation Loop (respects SortOrder):**
```java
// Blocks placed in order: hinge → outward
for (GateBlockSnapshot snapshot : sortedBlocks) {
    Location targetLoc = calculateBlockPosition(snapshot, currentFrame);
    restoreBlock(snapshot, targetLoc);  // Always overwrites
}
```

**Result:**
- Outer blocks (higher SortOrder) overwrite inner blocks
- Consistent animation regardless of server tick jitter
- No "holes" or missing blocks during rotation

---

### Performance Optimization (Target: ~100 Gates)

**Lazy Animation Updates:**
```java
@Override
public void run() {  // Tick task
    for (CachedGate gate : gates.values()) {
        if (gate.currentState != OPENING && gate.currentState != CLOSING) {
            continue;  // Skip gates in CLOSED/OPEN/BROKEN state
        }
        
        updateGateAnimation(gate);
    }
}
```

**Precomputed Data (loaded once on plugin startup):**
```java
class CachedGate {
    // Precomputed
    Vector uAxis, vAxis, nAxis;  // Local coordinate basis
    Vector motionVector;         // Total movement (for VERTICAL/LATERAL)
    Vector hingeAxis;            // Rotation axis (for ROTATION)
    List<BlockSnapshot> blocks;  // Sorted snapshots
    
    // Runtime state
    AnimationState currentState;
    int currentFrame;
    long animationStartTime;
}

void loadGateFromAPI(GateStructureDto dto) {
    CachedGate gate = new CachedGate();
    
    // Parse anchor point, reference points
    Vector p0 = parseJson(dto.AnchorPoint);
    Vector p1 = parseJson(dto.ReferencePoint1);
    Vector p2 = parseJson(dto.ReferencePoint2);
    
    // Precompute local basis
    gate.uAxis = p1.subtract(p0).normalize();
    Vector forward = p2.subtract(p0).normalize();
    gate.nAxis = gate.uAxis.crossProduct(forward).normalize();
    gate.vAxis = gate.nAxis.crossProduct(gate.uAxis).normalize();
    
    // Precompute motion vector
    if (dto.MotionType == "VERTICAL") {
        gate.motionVector = new Vector(0, dto.GeometryHeight, 0);
    } else if (dto.MotionType == "ROTATION") {
        gate.hingeAxis = gate.uAxis;
    }
    
    // Load snapshots
    gate.blocks = loadSnapshots(dto.Id).stream()
        .sorted(Comparator.comparingInt(s -> s.SortOrder))
        .collect(Collectors.toList());
    
    gates.put(dto.Id, gate);
}
```

**Batched Block Updates (by chunk):**
```java
Map<Chunk, List<BlockUpdate>> chunkUpdates = new HashMap<>();

for (GateBlockSnapshot snapshot : sortedBlocks) {
    Location loc = calculateBlockPosition(snapshot, currentFrame);
    Chunk chunk = loc.getChunk();
    
    chunkUpdates.computeIfAbsent(chunk, k -> new ArrayList<>())
        .add(new BlockUpdate(loc, snapshot.BlockRef));
}

// Apply updates per chunk
for (Map.Entry<Chunk, List<BlockUpdate>> entry : chunkUpdates.entrySet()) {
    Chunk chunk = entry.getKey();
    
    for (BlockUpdate update : entry.getValue()) {
        chunk.getBlock(update.loc.getBlockX(), update.loc.getBlockY(), update.loc.getBlockZ())
            .setBlockData(update.blockData, false);  // false = no physics update
    }
}
```

**Chunk Loading Check:**
```java
void updateGateAnimation(CachedGate gate) {
    // Check if gate chunk is loaded
    Location anchorLoc = gate.AnchorPoint.toLocation(world);
    if (!anchorLoc.getChunk().isLoaded()) {
        // Pause animation until chunk loads
        return;
    }
    
    // Proceed with animation
    // ...
}
```

**Frame Skip on Lag:**
```java
void updateGateAnimation(CachedGate gate) {
    long currentTick = server.getCurrentTick();
    int expectedFrame = (int) ((currentTick - gate.animationStartTime) / gate.AnimationTickRate);
    
    // Check server TPS
    double tps = server.getTPS()[0];  // 1-minute average
    
    if (tps < 15.0 && expectedFrame > gate.currentFrame + 5) {
        // Severe lag detected; jump to final position
        logWarning("Gate " + gate.Name + " skipping frames due to lag (TPS: " + tps + ")");
        gate.currentFrame = gate.totalFrames;  // Force completion
        finishAnimation(gate);
        return;
    }
    
    gate.currentFrame = Math.min(expectedFrame, gate.totalFrames);
    // ...
}
```

**Memory Footprint Estimate:**
- Per gate: 500 blocks × 64 bytes (BlockSnapshot + BlockData) = 32 KB
- 100 gates: 3.2 MB
- Plugin total memory: ~10-50 MB (including other features)
- Acceptable for modern Minecraft servers (8+ GB RAM)

---

## Part F: Entity & Player Interaction (Physics)

### Push Policy (Anti-Premature Push)

**Problem:**
- Players should not be pushed when gate starts opening far away
- Push should occur only when collision is imminent (1-2 frames away)

**Solution: Collision Prediction**

```java
void checkEntityCollisions(CachedGate gate, int currentFrame) {
    // Get entities within 5-block radius of gate
    Collection<Entity> nearbyEntities = gate.AnchorPoint.toLocation(world)
        .getNearbyEntities(5, 5, 5);
    
    for (Entity entity : nearbyEntities) {
        int framesToCollision = predictCollision(gate, entity, currentFrame);
        
        if (framesToCollision <= 2) {  // 2 frames = ~100ms warning
            pushEntity(entity, gate);
        }
    }
}

int predictCollision(CachedGate gate, Entity entity, int currentFrame) {
    BoundingBox entityBox = entity.getBoundingBox();
    
    // Check next N frames
    for (int futureFrame = currentFrame; futureFrame <= gate.totalFrames; futureFrame++) {
        // Calculate block positions at future frame
        Set<Location> blockPositions = calculateAllBlockPositions(gate, futureFrame);
        
        // Check intersection
        for (Location blockLoc : blockPositions) {
            BoundingBox blockBox = BoundingBox.of(blockLoc, blockLoc.clone().add(1, 1, 1));
            
            if (entityBox.overlaps(blockBox)) {
                return futureFrame - currentFrame;  // Frames until collision
            }
        }
    }
    
    return Integer.MAX_VALUE;  // No collision
}
```

**Push Direction Calculation:**
```java
void pushEntity(Entity entity, CachedGate gate) {
    Vector pushDirection = calculatePushDirection(gate);
    Vector pushForce = pushDirection.multiply(0.5);  // 0.5 blocks/tick
    
    entity.setVelocity(pushForce);
}

Vector calculatePushDirection(CachedGate gate) {
    // Base direction from FaceDirection
    Vector baseDirection = faceDirectionToVector(gate.FaceDirection);
    // Example: NORTH → (0, 0, -1)
    
    // For DRAWBRIDGE, push is perpendicular to hinge
    if (gate.GateType == DRAWBRIDGE) {
        baseDirection = gate.hingeAxis.crossProduct(gate.nAxis);
    }
    
    // Always push "outward" (away from gate structure)
    return baseDirection.normalize();
}

Vector faceDirectionToVector(String faceDirection) {
    switch (faceDirection) {
        case "north": return new Vector(0, 0, -1);
        case "north-east": return new Vector(0.707, 0, -0.707);
        case "east": return new Vector(1, 0, 0);
        case "south-east": return new Vector(0.707, 0, 0.707);
        case "south": return new Vector(0, 0, 1);
        case "south-west": return new Vector(-0.707, 0, 0.707);
        case "west": return new Vector(-1, 0, 0);
        case "north-west": return new Vector(-0.707, 0, -0.707);
        default: return new Vector(0, 0, -1);  // Default to north
    }
}
```

---

### Safety & Physics Handling

**Falling Blocks (gravity):**
```java
void placeBlock(Location loc, BlockData blockData) {
    // Disable physics to prevent gravel/sand falling
    world.setBlockData(loc, blockData, false);  // false = no physics update
}
```

**Fluid Flow:**
```java
void checkAdjacentFluids(Location loc) {
    BlockFace[] faces = {BlockFace.NORTH, BlockFace.SOUTH, BlockFace.EAST, 
                         BlockFace.WEST, BlockFace.UP, BlockFace.DOWN};
    
    for (BlockFace face : faces) {
        Block adjacent = loc.getBlock().getRelative(face);
        
        if (adjacent.isLiquid()) {
            // Place temporary barrier (e.g., glass)
            // TODO: Implement fluid containment logic
        }
    }
}
```

**Redstone Side Effects:**
```java
@EventHandler
public void onBlockRedstone(BlockRedstoneEvent event) {
    // Check if this block is part of a gate
    if (isGateBlock(event.getBlock())) {
        // Cancel redstone state change
        event.setNewCurrent(event.getOldCurrent());
    }
}

boolean isGateBlock(Block block) {
    // Check all active gates
    for (CachedGate gate : gates.values()) {
        if (gate.blocks.stream().anyMatch(s -> s.matchesLocation(block.getLocation()))) {
            return true;
        }
    }
    return false;
}
```

---

## Part G: Integration with Existing Systems

### Structure Inheritance (Domain System)

**GateStructure extends Structure:**
- Inherits: `DomainId`, `DistrictId`, `StreetId`
- Inherits: `CreatedAt`, `UpdatedAt` timestamps
- Inherits: Owner/permissions (if Structure supports this)
- Inherits: World position (if Structure has this - TBD)

**Access Control via Domain Hierarchy:**
```java
boolean canOpenGate(Player player, GateStructure gate) {
    // Check explicit permission
    if (player.hasPermission("knk.gate.open." + gate.Id)) return true;
    if (player.hasPermission("knk.gate.open.*")) return true;
    if (player.hasPermission("knk.gate.admin")) return true;
    
    // Check domain ownership
    Domain domain = domainRepository.findById(gate.DomainId);
    if (domain.isOwner(player)) return true;
    
    // Check district membership
    District district = districtRepository.findById(gate.DistrictId);
    if (district.isMember(player)) return true;
    
    // Check street membership (if applicable)
    if (gate.StreetId != null) {
        Street street = streetRepository.findById(gate.StreetId);
        if (street.isMember(player)) return true;
    }
    
    return false;
}
```

---

### WorldGuard Integration

**Purpose:**
- Different protection regions when gate is CLOSED vs. OPEN
- Example: Block entry when closed, allow passage when open

**Implementation:**
```java
void onGateStateChange(GateStructure gate, AnimationState newState) {
    WorldGuardPlugin worldGuard = getWorldGuard();
    RegionManager regionManager = worldGuard.getRegionManager(world);
    
    if (newState == OPEN) {
        // Disable closed region
        if (!gate.RegionClosedId.isEmpty()) {
            ProtectedRegion closedRegion = regionManager.getRegion(gate.RegionClosedId);
            if (closedRegion != null) {
                closedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.ALLOW);
            }
        }
        
        // Enable opened region
        if (!gate.RegionOpenedId.isEmpty()) {
            ProtectedRegion openedRegion = regionManager.getRegion(gate.RegionOpenedId);
            if (openedRegion != null) {
                openedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.ALLOW);
            }
        }
    } else if (newState == CLOSED) {
        // Enable closed region
        if (!gate.RegionClosedId.isEmpty()) {
            ProtectedRegion closedRegion = regionManager.getRegion(gate.RegionClosedId);
            if (closedRegion != null) {
                closedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.DENY);
            }
        }
        
        // Disable opened region
        if (!gate.RegionOpenedId.isEmpty()) {
            ProtectedRegion openedRegion = regionManager.getRegion(gate.RegionOpenedId);
            if (openedRegion != null) {
                openedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.ALLOW);
            }
        }
    }
}
```

**Region Creation (Admin Workflow):**
1. Admin creates gate in web app
2. Plugin captures block positions
3. Admin creates WorldGuard regions manually (via `/rg define <regionId>`)
4. Admin enters region IDs in web app (RegionClosedId, RegionOpenedId)
5. Plugin syncs region flags on gate state change

**Alternative (Auto-Create Regions - Future):**
```java
void autoCreateRegions(GateStructure gate) {
    // Calculate bounding box from block snapshots
    BoundingBox bounds = calculateBoundingBox(gate.blocks);
    
    // Create closed region
    String closedRegionId = "gate_" + gate.Id + "_closed";
    ProtectedCuboidRegion closedRegion = new ProtectedCuboidRegion(
        closedRegionId,
        bounds.getMin(),
        bounds.getMax()
    );
    closedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.DENY);
    regionManager.addRegion(closedRegion);
    
    // Create opened region (same bounds or slightly different)
    String openedRegionId = "gate_" + gate.Id + "_opened";
    ProtectedCuboidRegion openedRegion = new ProtectedCuboidRegion(
        openedRegionId,
        bounds.getMin(),
        bounds.getMax()
    );
    openedRegion.setFlag(DefaultFlag.ENTRY, StateFlag.State.ALLOW);
    regionManager.addRegion(openedRegion);
    
    // Update gate
    gate.RegionClosedId = closedRegionId;
    gate.RegionOpenedId = openedRegionId;
    gateRepository.save(gate);
}
```

---

### Health & Respawn System

**Damage Mechanics (Future):**
```java
@EventHandler
public void onEntityExplode(EntityExplodeEvent event) {
    for (Block block : event.blockList()) {
        GateStructure gate = findGateByBlock(block);
        
        if (gate != null) {
            if (gate.IsInvincible) {
                // Cancel explosion for this block
                event.blockList().remove(block);
            } else {
                // Apply damage
                double damage = 100.0;  // Example: TNT does 100 damage
                gate.HealthCurrent = Math.max(0, gate.HealthCurrent - damage);
                
                if (gate.HealthCurrent == 0) {
                    destroyGate(gate);
                }
                
                gateRepository.save(gate);
            }
        }
    }
}
```

**Respawn Logic:**
```java
void destroyGate(GateStructure gate) {
    gate.IsDestroyed = true;
    gate.IsOpened = false;
    gate.IsActive = false;
    
    // Remove all gate blocks
    for (GateBlockSnapshot snapshot : gate.blocks) {
        Location loc = snapshot.getWorldPosition(gate.AnchorPoint).toLocation(world);
        world.setType(loc, Material.AIR);
    }
    
    gateRepository.save(gate);
    
    if (gate.CanRespawn) {
        // Schedule respawn
        long delay = gate.RespawnRateSeconds * 20L;  // Convert to ticks
        
        scheduler.runTaskLater(plugin, () -> {
            respawnGate(gate);
        }, delay);
    }
}

void respawnGate(GateStructure gate) {
    gate.HealthCurrent = gate.HealthMax;
    gate.IsDestroyed = false;
    gate.IsActive = true;
    gate.IsOpened = false;
    
    // Restore all blocks
    for (GateBlockSnapshot snapshot : gate.blocks) {
        Location loc = snapshot.getWorldPosition(gate.AnchorPoint).toLocation(world);
        restoreBlock(snapshot, loc);
    }
    
    gateRepository.save(gate);
    
    // Notify admins
    broadcast("Gate " + gate.Name + " has respawned!");
}
```

---

## Part H: Storage & Persistence (MySQL via Web API)

### Database Schema (Confirmed)

**GateStructures Table:**
```sql
CREATE TABLE GateStructures (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- Inherited from Structure
    DomainId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    DistrictId INT NOT NULL,
    StreetId INT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Gate-specific (existing fields)
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
    
    -- Animation system (new fields)
    GateType VARCHAR(50) DEFAULT 'SLIDING',
    GeometryDefinitionMode VARCHAR(50) DEFAULT 'PLANE_GRID',
    MotionType VARCHAR(50) DEFAULT 'VERTICAL',
    AnimationDurationTicks INT DEFAULT 60,
    AnimationTickRate INT DEFAULT 1,
    
    -- PLANE_GRID geometry
    AnchorPoint TEXT,
    ReferencePoint1 TEXT,
    ReferencePoint2 TEXT,
    GeometryWidth INT DEFAULT 0,
    GeometryHeight INT DEFAULT 0,
    GeometryDepth INT DEFAULT 0,
    
    -- FLOOD_FILL geometry
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
    
    FOREIGN KEY (DomainId) REFERENCES Domains(Id) ON DELETE CASCADE,
    FOREIGN KEY (DistrictId) REFERENCES Districts(Id) ON DELETE CASCADE,
    FOREIGN KEY (StreetId) REFERENCES Streets(Id) ON DELETE SET NULL,
    FOREIGN KEY (IconMaterialRefId) REFERENCES MinecraftMaterialRefs(Id) ON DELETE SET NULL,
    FOREIGN KEY (FallbackMaterialRefId) REFERENCES MinecraftMaterialRefs(Id) ON DELETE SET NULL,
    
    INDEX idx_gate_type (GateType),
    INDEX idx_is_active (IsActive),
    INDEX idx_is_opened (IsOpened),
    INDEX idx_domain_id (DomainId),
    INDEX idx_district_id (DistrictId),
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
    FOREIGN KEY (MinecraftBlockRefId) REFERENCES MinecraftBlockRefs(Id) ON DELETE SET NULL,
    
    INDEX idx_gate_id (GateStructureId),
    INDEX idx_sort_order (GateStructureId, SortOrder)
);
```

---

### API Endpoints (Web API - C#)

**CRUD Operations:**
```
GET    /api/gates                    - List all gates (with filtering, pagination)
GET    /api/gates/{id}               - Get gate by ID
POST   /api/gates                    - Create new gate
PUT    /api/gates/{id}               - Update gate
DELETE /api/gates/{id}               - Delete gate
GET    /api/gates/domain/{domainId}  - Get gates by domain
```

**State Management:**
```
PUT    /api/gates/{id}/state         - Update IsOpened state
  Request: { "isOpened": true }
  Response: GateReadDto
```

**Snapshot Operations:**
```
GET    /api/gates/{id}/snapshots     - Get all snapshots for gate
POST   /api/gates/{id}/snapshots/bulk - Create snapshots in bulk
  Request: [ { "relativeX": 0, "relativeY": 0, "relativeZ": 0, ... }, ... ]
DELETE /api/gates/{id}/snapshots     - Clear all snapshots (for recapture)
POST   /api/gates/{id}/recapture     - Trigger recapture (plugin-initiated)
```

**Bulk Operations:**
```
POST   /api/gates/bulk-recapture     - Recapture all gates (admin tool)
```

---

### Plugin-API Synchronization

**Plugin Startup:**
```java
void loadGatesFromAPI() {
    // Query API for active gates
    List<GateStructureDto> gates = apiClient.getGates("isActive=true");
    
    for (GateStructureDto dto : gates) {
        // Load into memory
        CachedGate cachedGate = loadGateFromDto(dto);
        
        // Load snapshots
        List<GateBlockSnapshotDto> snapshots = apiClient.getGateSnapshots(dto.Id);
        cachedGate.blocks = snapshots.stream()
            .sorted(Comparator.comparingInt(s -> s.SortOrder))
            .map(this::convertToBlockSnapshot)
            .collect(Collectors.toList());
        
        gates.put(dto.Id, cachedGate);
    }
    
    logInfo("Loaded " + gates.size() + " gates from API");
}
```

**State Sync (on animation complete):**
```java
void finishAnimation(CachedGate gate) {
    if (gate.currentState == OPENING) {
        gate.currentState = OPEN;
        gate.IsOpened = true;
    } else if (gate.currentState == CLOSING) {
        gate.currentState = CLOSED;
        gate.IsOpened = false;
    }
    
    // Persist to API
    apiClient.updateGateState(gate.Id, gate.IsOpened);
    
    // Sync WorldGuard regions
    onGateStateChange(gate, gate.currentState);
}
```

---

## Part I: Testing & Validation (Test Scenarios)

### Functional Testing

**TC-001: Basic Gate Open/Close (SLIDING)**
```
Preconditions: 
  - SLIDING gate created (PLANE_GRID mode)
  - GeometryHeight: 8 blocks
  - AnimationDurationTicks: 60
Steps:
  1. Execute /gate open <gateName>
  2. Observe animation over 3 seconds
  3. Verify blocks move upward 8 blocks
  4. Verify IsOpened=true in DB
  5. Execute /gate close <gateName>
  6. Observe animation over 3 seconds
  7. Verify blocks return to original positions
  8. Verify IsOpened=false in DB
Expected: Animation smooth, deterministic, no missing blocks
```

**TC-002: Diagonal Gate (PLANE_GRID)**
```
Preconditions: 
  - SLIDING gate created with FaceDirection: "north-east"
  - AnchorPoint: {100, 64, 100}
  - ReferencePoint1: {105, 64, 95} (diagonal)
Steps:
  1. Execute /gate open <gateName>
  2. Verify local basis vectors calculated correctly (u, v, n)
  3. Verify blocks animate along correct axis (perpendicular to hinge)
Expected: Blocks move along diagonal axis, no deviation
```

**TC-003: Drawbridge Rotation**
```
Preconditions: 
  - DRAWBRIDGE gate created
  - RotationMaxAngleDegrees: 90
Steps:
  1. Execute /gate open <gateName>
  2. Observe blocks rotate around hinge line
  3. Verify final angle is 90° (horizontal)
  4. Verify no block collision errors
Expected: Smooth rotation, outer blocks overwrite inner blocks
```

**TC-004: Double Doors (FLOOD_FILL)**
```
Preconditions: 
  - DOUBLE_DOORS gate created
  - LeftDoorSeedBlock: {100, 64, 100}
  - RightDoorSeedBlock: {105, 64, 100}
  - MirrorRotation: true
Steps:
  1. Execute /gate open <gateName>
  2. Verify two separate door leaves detected
  3. Verify doors open in opposite directions
  4. Verify final positions are symmetrical
Expected: Doors mirror each other, no overlap
```

**TC-005: Entity Push**
```
Preconditions: 
  - SLIDING gate created
  - Player standing in gate path (5 blocks above closed position)
Steps:
  1. Execute /gate open <gateName>
  2. Verify player NOT pushed immediately
  3. Wait until gate is 2 frames from collision
  4. Verify player pushed upward
Expected: Push occurs only when collision imminent
```

**TC-006: Health & Respawn**
```
Preconditions: 
  - Gate created with HealthMax: 500, CanRespawn: true, RespawnRateSeconds: 60
Steps:
  1. Manually set gate.HealthCurrent = 0 via API
  2. Verify gate.IsDestroyed = true
  3. Verify all gate blocks removed
  4. Wait 60 seconds
  5. Verify gate respawns (blocks restored, HealthCurrent = 500)
Expected: Gate respawns exactly after 60 seconds
```

---

### Performance Testing

**TC-101: Load Test (100 Gates)**
```
Preconditions: 
  - 100 SLIDING gates created across map
  - All gates IsActive: true
Steps:
  1. Start server
  2. Measure plugin memory usage
  3. Verify memory < 50 MB
  4. Open 10 gates simultaneously
  5. Monitor server TPS over 1 minute
Expected: TPS ≥ 18, memory ≤ 50 MB
```

**TC-102: Stress Test (20 Animating Gates)**
```
Preconditions: 
  - 20 SLIDING gates created
Steps:
  1. Execute /gate open for all 20 gates at once
  2. Monitor server TPS during animation
  3. Measure tick duration (ms)
Expected: TPS ≥ 15, tick duration < 50ms, no server crash
```

---

### Edge Cases

**TC-201: Chunk Unload During Animation**
```
Steps:
  1. Start gate animation
  2. Teleport far away (unload chunk)
  3. Wait 10 seconds
  4. Teleport back (reload chunk)
Expected: Animation resumes or completes gracefully (no stuck state)
```

**TC-202: Server Restart Mid-Animation**
```
Steps:
  1. Start gate animation
  2. Stop server (mid-animation)
  3. Restart server
  4. Check gate state
Expected: Gate resets to CLOSED or OPEN (not mid-frame)
```

**TC-203: Block Break in Gate Area**
```
Steps:
  1. Break gate block (while gate is CLOSED)
Expected: Block break prevented OR gate.HealthCurrent decreases
```

**TC-204: Concurrent Access**
```
Steps:
  1. Two players execute /gate open simultaneously
Expected: Only one animation triggered, no duplicate state
```

---

## Part J: Migration & Deployment (v1 → v2)

### Existing GateStructure Migration

**Current State (v1):**
- GateStructure.cs exists with basic fields (IsActive, IsOpened, Health, etc.)
- No animation system deployed
- No block snapshots

**Migration Steps:**

**Step 1: Database Schema Update**
```sql
ALTER TABLE GateStructures ADD COLUMN GateType VARCHAR(50) DEFAULT 'SLIDING';
ALTER TABLE GateStructures ADD COLUMN GeometryDefinitionMode VARCHAR(50) DEFAULT 'PLANE_GRID';
ALTER TABLE GateStructures ADD COLUMN MotionType VARCHAR(50) DEFAULT 'VERTICAL';
ALTER TABLE GateStructures ADD COLUMN AnimationDurationTicks INT DEFAULT 60;
ALTER TABLE GateStructures ADD COLUMN AnimationTickRate INT DEFAULT 1;
ALTER TABLE GateStructures ADD COLUMN AnchorPoint TEXT;
ALTER TABLE GateStructures ADD COLUMN ReferencePoint1 TEXT;
ALTER TABLE GateStructures ADD COLUMN ReferencePoint2 TEXT;
ALTER TABLE GateStructures ADD COLUMN GeometryWidth INT DEFAULT 0;
ALTER TABLE GateStructures ADD COLUMN GeometryHeight INT DEFAULT 0;
ALTER TABLE GateStructures ADD COLUMN GeometryDepth INT DEFAULT 0;
ALTER TABLE GateStructures ADD COLUMN SeedBlocks TEXT;
ALTER TABLE GateStructures ADD COLUMN ScanMaxBlocks INT DEFAULT 500;
ALTER TABLE GateStructures ADD COLUMN ScanMaxRadius INT DEFAULT 20;
ALTER TABLE GateStructures ADD COLUMN ScanMaterialWhitelist TEXT;
ALTER TABLE GateStructures ADD COLUMN ScanMaterialBlacklist TEXT;
ALTER TABLE GateStructures ADD COLUMN ScanPlaneConstraint BOOLEAN DEFAULT FALSE;
ALTER TABLE GateStructures ADD COLUMN FallbackMaterialRefId INT NULL;
ALTER TABLE GateStructures ADD COLUMN TileEntityPolicy VARCHAR(50) DEFAULT 'DECORATIVE_ONLY';
ALTER TABLE GateStructures ADD COLUMN RotationMaxAngleDegrees INT DEFAULT 90;
ALTER TABLE GateStructures ADD COLUMN HingeAxis TEXT;
ALTER TABLE GateStructures ADD COLUMN LeftDoorSeedBlock TEXT;
ALTER TABLE GateStructures ADD COLUMN RightDoorSeedBlock TEXT;
ALTER TABLE GateStructures ADD COLUMN MirrorRotation BOOLEAN DEFAULT TRUE;

CREATE TABLE GateBlockSnapshots (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    GateStructureId INT NOT NULL,
    RelativeX INT NOT NULL,
    RelativeY INT NOT NULL,
    RelativeZ INT NOT NULL,
    MinecraftBlockRefId INT NULL,
    SortOrder INT NOT NULL,
    FOREIGN KEY (GateStructureId) REFERENCES GateStructures(Id) ON DELETE CASCADE,
    FOREIGN KEY (MinecraftBlockRefId) REFERENCES MinecraftBlockRefs(Id) ON DELETE SET NULL,
    INDEX idx_gate_id (GateStructureId),
    INDEX idx_sort_order (GateStructureId, SortOrder)
);
```

**Step 2: Backfill Existing Gates**
- Admin uses web app to configure each gate:
  - Select GateType (SLIDING recommended for existing portcullises)
  - Define geometry (PLANE_GRID: set AnchorPoint, ReferencePoint1, ReferencePoint2)
  - Set dimensions (GeometryWidth, GeometryHeight, GeometryDepth)
  - Capture block snapshot (via "Capture Blocks" button in web app)

**Step 3: Deploy Plugin Update**
- Deploy new plugin version with animation system
- Plugin loads gates from API on startup
- Animation tick task begins

**Step 4: Test & Validate**
- Open/close each gate manually
- Verify animation correctness
- Monitor server performance

---

### Rollback Plan (if issues arise)

**Option 1: Disable Animation System**
```sql
UPDATE GateStructures SET IsActive = FALSE;
```
- Gates remain static, no animation

**Option 2: Revert Plugin**
- Deploy previous plugin version without animation
- Gates function as static structures

**Option 3: Database Rollback**
```sql
-- Drop animation columns (if needed)
ALTER TABLE GateStructures DROP COLUMN GateType;
-- (etc. for all animation columns)
DROP TABLE GateBlockSnapshots;
```

---

**End of Specification Document**
