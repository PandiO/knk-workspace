# Gate Animation System - Complete Requirements & Specification

**Location**: `docs/features/gate-structure-animation/`  
**Status**: Ready for Implementation  
**Created**: January 30, 2026  
**Last Updated**: January 31, 2026  
**Consolidated From**: `docs/ai/gate-animation/` (legacy location)

---

## 📋 Quick Navigation

| Document | Best For | Read Time |
|----------|----------|-----------|
| **[REQUIREMENTS.md](./REQUIREMENTS.md)** (this file) | Complete requirements, specifications, and quick reference | 90-120 min |
| **[IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md)** | Detailed phase-by-phase implementation plan | 60-90 min |
| **[SPEC.md](./SPEC.md)** | Technical specification and architecture details | 45-60 min |
| **[PHASE_STATUS.md](./PHASE_STATUS.md)** | Current implementation status and progress tracking | 5-10 min |
| **[DECISIONS.md](./DECISIONS.md)** | Key design decisions and rationale | 30-45 min |
| **[COMMIT_HISTORY.md](./COMMIT_HISTORY.md)** | Git commit history and version tracking | 15-20 min |

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

// Rotation Gap-Fill (see ROTATION_GAP_FILL_DESIGN.md) - optional second physical anchor for a
// separately-scanned, fully-open shape. Null means "no manual open scan" (the default, and
// still the case for every gate that predates this feature).
public int? OpenAnchorPointId { get; set; }
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

### GateOpenedBlockSnapshot Entity (Rotation Gap-Fill)

Optional, mirrors `GateBlockSnapshot` exactly, keyed to `OpenAnchorPointId` instead of
`AnchorPointId`. Its rows (if any) are a gate's manually-scanned, fully-open shape - see
[ROTATION_GAP_FILL_DESIGN.md](ROTATION_GAP_FILL_DESIGN.md). A gate with none of these rows
falls back to procedural animation (optionally with automatic diagonal-hinge gap-fill,
Mechanism 1) exactly as before this feature existed - there is no mode flag, the presence of
`OpenedBlockSnapshots` rows is the trigger.

```csharp
public class GateOpenedBlockSnapshot
{
    public int Id { get; set; }
    public int GateStructureId { get; set; }
    public GateStructure GateStructure { get; set; }

    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }

    public string MaterialName { get; set; }
    public string BlockDataJson { get; set; } = "{}";
    public string TileEntityJson { get; set; } = "{}";

    public int SortOrder { get; set; }
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

**File**: `Repository/knk-web-api/Models/GateStructure.cs`

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

**File**: `Repository/knk-web-api/Models/GateBlockSnapshot.cs`

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

## 📁 What This Feature Includes

### Complete Deliverables

**Backend (C# / .NET Web API):**
- 47 total fields: 13 existing + 34 new
- GateBlockSnapshot entity (new)
- Gate DTOs (Read, Create, Update, Navigation)
- Gate Repository + interface
- Gate Service + interface (cascade rules, snapshot management)
- GateStructuresController (CRUD + state management + snapshot operations + advanced features)
- AutoMapper mapping profile
- EntityMetadata annotations (for FormConfig/DisplayConfig)

**Frontend (Web App - React/TypeScript):**
- Gate management UI (list, details, create, edit)
- Gate configuration wizard (6-step)
  - Basic info
  - Gate type & orientation
  - Geometry definition (PLANE_GRID or FLOOD_FILL)
  - Animation settings
  - Advanced options (pass-through, siege, guards, health display)
  - Review & create
- 3D preview widget (Three.js)
- Pass-through conditions editor
- Siege assignment UI
- Health display configurator
- Gate DTOs/types + API client wiring
- Reuse existing generic UI (forms/lists/details)

**Paper Plugin (Minecraft - Java):**
- Gate definition loader (API client)
- Animation engine (tick task)
- Frame calculator (linear, rotation)
- Block placement system
- Entity push system (collision prediction)
- State synchronization (plugin ↔ API)
- Command handlers (/gate open, /gate close, /gate admin, /gate passthrough, etc.)
- Event handlers (block break, explosion, player damage)
- WorldGuard integration
- Health display manager (ArmorStand entities)
- Continuous damage system (fire effects, damage-over-time)
- Pass-through proximity detector (future)
- Guard spawn system (future - placeholder)
- Siege integration (gate locking, override, objective mechanics)

---

## ⏱️ Implementation Timeline (Estimated)

| Phase | Focus | Backend | Frontend | Plugin | Total Effort | Days |
|-------|-------|---------|----------|--------|--------------|------|
| 1 | Data Model & Entities | 16-20 hrs | - | - | 16-20 hrs | 2-2.5 |
| 2 | DTOs, Repo, Service | 20-24 hrs | - | - | 20-24 hrs | 2.5-3 |
| 3 | Controller & API | 12-16 hrs | - | - | 12-16 hrs | 1.5-2 |
| 4 | Web App Types & Client | - | 12-16 hrs | - | 12-16 hrs | 1.5-2 |
| 5 | Web App Wizard UI | - | 32-40 hrs | - | 32-40 hrs | 4-5 |
| 6 | Plugin Core (Loader, Cache) | - | - | 20-24 hrs | 20-24 hrs | 2.5-3 |
| 7 | Plugin Animation Engine | - | - | 32-40 hrs | 32-40 hrs | 4-5 |
| 8 | Plugin Commands & Events | - | - | 16-20 hrs | 16-20 hrs | 2-2.5 |
| 9 | WorldGuard & Permissions | - | - | 12-16 hrs | 12-16 hrs | 1.5-2 |
| 10 | Testing & Polish | 8-12 hrs | 8-12 hrs | 16-20 hrs | 32-44 hrs | 4-5.5 |
| **Total** | | **56-72 hrs** | **52-68 hrs** | **96-120 hrs** | **204-260 hrs** | **25.5-32.5 days** |

**Notes:**
- Assumes one developer working full-time (8 hrs/day)
- Backend and frontend can be developed in parallel
- Plugin development depends on backend API completion
- Testing overlaps with all phases

---

## 🔑 Key Design Decisions (Already Made)

✅ **Gate Types: SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS** (v1 - extensible for v2)  
✅ **Geometry Modes: PLANE_GRID, FLOOD_FILL** (automatic or manual block selection)  
✅ **Diagonal Support: Full support** (FaceDirection: 8 cardinal/diagonal directions)  
✅ **Motion Types: VERTICAL, LATERAL, ROTATION** (deterministic, server-tick based)  
✅ **Block Storage: GateBlockSnapshot entity** (one-to-many with GateStructure)  
✅ **Animation: Runtime frame calculation** (no stored frames, precomputed data)  
✅ **Entity Push: Collision prediction** (push only when collision imminent, not premature)  
✅ **State Machine: CLOSED, OPENING, OPEN, CLOSING, JAMMED, BROKEN** (persisted: IsOpened only)  
✅ **Health & Respawn: Auto-repair after RespawnRateSeconds** (default 300s = 5 min)  
✅ **WorldGuard Integration: Dual regions** (RegionClosedId, RegionOpenedId)  
✅ **Performance Target: ~100 gates, 20 TPS with 10 animating** (lazy updates, batched chunks)  
✅ **Tile Entity Policy: DECORATIVE_ONLY (v1)** (no inventory tile entities)  

---

## 🔗 Related Documentation

- **Rotation Gap-Fill**: [ROTATION_GAP_FILL_DESIGN.md](ROTATION_GAP_FILL_DESIGN.md) — automatic diagonal-hinge gap-fill and the optional `GateOpenedBlockSnapshot` manual override
- **Gate World/DB Sync**: [GATE_WORLD_SYNC_DESIGN.md](GATE_WORLD_SYNC_DESIGN.md) — keeping physical world blocks converged on DB-persisted gate state
- **Current Entity**: [GateStructure.cs](../../../../Repository/knk-web-api/Models/GateStructure.cs)
- **Architecture Overview**: [docs/CODEMAP.md](../../guides/developer/CODEMAP.md)
- **Project Structure**: [docs/specs/project-overview/SOURCES_LOCATION.md](../../specs/project-overview/SOURCES_LOCATION.md)
- **Minecraft Data**: [Repository/knk-minecraft-data/minecraft-materials.json](../../../../Repository/knk-minecraft-data/minecraft-materials.json)
- **Backend Instructions**: [.github/instructions/knk-backend.instructions.md](../../../../.github/instructions/knk-backend.instructions.md)
- **Plugin Architecture**: [Repository/knk-plugin/ARCHITECTURE_AUDIT.md](../../../../Repository/knk-plugin/ARCHITECTURE_AUDIT.md)

---

## ❓ Common Questions

**Q: Where do I start?**  
A: Read this document (REQUIREMENTS.md) first (90-120 min), then review [IMPLEMENTATION_ROADMAP.md](./IMPLEMENTATION_ROADMAP.md) for detailed phase breakdown.

**Q: What's the difference between PLANE_GRID and FLOOD_FILL?**  
A: PLANE_GRID is for rectangular gates (portcullis, drawbridge) using 3 reference points. FLOOD_FILL is for irregular shapes (double doors, decorative gates) using seed blocks and BFS.

**Q: How are diagonal gates handled?**  
A: PLANE_GRID mode constructs a local coordinate system (u, v, n) from the 3 reference points. This system automatically handles diagonal orientation. Blocks are placed along these local axes, not world axes.

**Q: How does the animation work?**  
A: Frames are calculated at runtime (not stored). Each tick, the plugin:
1. Checks gates in OPENING/CLOSING state
2. Calculates current frame based on elapsed ticks
3. Computes block positions using linear interpolation (VERTICAL/LATERAL) or rotation (DRAWBRIDGE)
4. Places/removes blocks at calculated positions
5. Predicts entity collisions and pushes entities if needed

**Q: How are performance targets met?**  
A: 
- Lazy updates (only OPENING/CLOSING gates update per tick)
- Precomputed data (local basis, motion vectors)
- Batched chunk updates (reduce lighting recalculations)
- Chunk loading checks (skip if unloaded)
- Frame skip on lag (jump to final position if TPS < 15)

**Q: What's the migration path for existing gates?**  
A: Database schema update → backfill existing gates (admin configures geometry) → deploy plugin update → test & validate. Rollback: disable IsActive or revert plugin.

**Q: How do I test diagonal gates?**  
A: Create a gate with FaceDirection="north-east" and set ReferencePoint1 diagonally from AnchorPoint (e.g., p0={100,64,100}, p1={105,64,95}). Verify blocks animate along diagonal axis.

**Q: What's the difference between HealthCurrent and IsDestroyed?**  
A: HealthCurrent is the current HP (0 to HealthMax). IsDestroyed is set to true when HealthCurrent reaches 0, triggering respawn logic if CanRespawn=true.

**Q: Can gates have different open/close speeds?**  
A: Yes. AnimationDurationTicks controls total animation length (default 60 ticks = 3 seconds). AnimationTickRate controls frames per tick (1 = every tick, 2 = every other tick).

**Q: How do I create a drawbridge vs. a portcullis?**  
A: Drawbridge: GateType=DRAWBRIDGE, MotionType=ROTATION, GeometryDefinitionMode=PLANE_GRID. Portcullis: GateType=SLIDING, MotionType=VERTICAL, GeometryDefinitionMode=PLANE_GRID.

