# Gate Structure Animation System - Implementation Roadmap

**Status**: Planning → Phase 1  
**Created**: January 31, 2026  
**Components**: Backend (.NET API), Frontend (React), Plugin (Minecraft)  
**Current Sprint Goal**: Implement Siege minigame with functional Gates

---

## Executive Summary

This document provides a comprehensive step-by-step implementation plan for the complete GateStructure animation system across all three components (backend, frontend, plugin). The system enables creation, configuration, and animation of complex multi-block gate structures in Minecraft.

**Key Architecture Components**:
1. **Backend** (.NET): Entity model, repositories, services, DTOs, controllers, animations
2. **Frontend** (React): FormConfiguration builder, FormWizard multi-step form, WorldTask integration
3. **Plugin** (Kotlin): Animation execution, event handling, WorldTask support, player commands

**Reference Documents**:
- [GATE_REQUIREMENTS_SUMMARY.md](GATE_REQUIREMENTS_SUMMARY.md) - Complete feature matrix (47 fields, 5 phases)
- [REQUIREMENTS_GATE_ANIMATION.md](REQUIREMENTS_GATE_ANIMATION.md) - Base animation system
- [REQUIREMENTS_GATE_ADVANCED_FEATURES.md](REQUIREMENTS_GATE_ADVANCED_FEATURES.md) - Advanced features (pass-through, guards, siege)
- [REQUIREMENTS_GATE_FRONTEND.md](REQUIREMENTS_GATE_FRONTEND.md) - Frontend implementation details

**Implementation Timeline**: ~25-35 weeks (all phases) | Phase 1 Sprint: 2-3 weeks

---

## Part A: Architecture Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                     Frontend (knk-web-app - React)                 │
│                                                                    │
│  FormConfigBuilder → GateStructure FormConfiguration (6 steps)    │
│  ↓                                                                 │
│  FormWizard → Multi-step gate creation wizard with auto-calc      │
│  ↓                                                                 │
│  WorldBoundFieldRenderer → In-game data capture (coordinates, etc)│
│  ↓                                                                 │
│  AdminUI → List, edit, activate gates                             │
└─────────────────┬──────────────────────────────────────────────────┘
                  │ HTTPS (JSON)
                  ▼
┌────────────────────────────────────────────────────────────────────┐
│                   Backend API (knk-web-api-v2 - .NET)             │
│                                                                    │
│  POST   /api/gatestructures              (Create gate)           │
│  GET    /api/gatestructures/{id}         (Get gate details)      │
│  PUT    /api/gatestructures/{id}         (Update gate)           │
│  DELETE /api/gatestructures/{id}         (Delete gate)           │
│  GET    /api/gatestructures/list         (List by domain)        │
│  POST   /api/gatestructures/{id}/animate (Trigger animation)     │
│  POST   /api/gatestructures/{id}/damage  (Apply damage)          │
│  PUT    /api/gatestructures/{id}/health  (Update health)         │
│  POST   /api/gatestructures/{id}/activate (Set active)           │
│                                                                    │
│  Services:                                                         │
│  - GateStructureService (CRUD, validation, cascade rules)        │
│  - GateAnimationService (geometry calculation, animation logic)  │
│  - GateDamageService (health system, continuous damage)          │
│  - GateBlockSnapshotService (block state management)             │
│                                                                    │
│  Entities:                                                         │
│  - GateStructure (47 fields, relationships to Domain/District)   │
│  - GateBlockSnapshot (block coordinates, materials, metadata)    │
│  - GateAnimationEvent (audit trail of animations)                │
└─────────────────┬──────────────────────────────────────────────────┘
                  │ HTTPS (JSON)
                  ▼
┌────────────────────────────────────────────────────────────────────┐
│                Plugin (knk-plugin-v2 - Kotlin/Paper)              │
│                                                                    │
│  GateAnimationManager → Execute animations in Minecraft world    │
│  ├─ AnimationExecutor (block changes, particle effects)          │
│  ├─ BlockSnapshotLoader (load gate blocks from DB)               │
│  └─ AnimationStateTracker (track open/closed state)              │
│                                                                    │
│  GateDamageManager → Health system, damage application           │
│  ├─ DamageCalculator (damage reduction, invincibility checks)    │
│  ├─ ContinuousDamageApplier (fire damage over time)              │
│  └─ HealthDisplayManager (ArmorStand health indicator)           │
│                                                                    │
│  Commands:                                                         │
│  /gate animate {gateId} {state}       (Open/close gate)          │
│  /gate info {gateId}                  (View gate status)         │
│  /gate damage {gateId} {amount}       (Apply damage)             │
│  /gate repair {gateId}                (Full repair)              │
│  /gate reload                         (Reload from API)          │
│                                                                    │
│  Event Handlers:                                                   │
│  - PlayerInteractEvent (gate activation by proximity/click)      │
│  - EntityDamageEvent (incoming damage redirected to gate)        │
│  - BlockChangeEvent (prevent manual modification)                │
│  - WorldLoadEvent (sync gate states on startup)                  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Part B: Phase Breakdown & Effort Estimation

| Phase | Name | Duration | Effort | Priority | Status |
|-------|------|----------|--------|----------|--------|
| **1** | Backend Foundation | 5-7 days | 40-50h | 🔴 CRITICAL | Not Started |
| **2** | Frontend FormConfiguration | 4-5 days | 30-40h | 🔴 CRITICAL | Not Started |
| **3** | Frontend FormWizard | 5-7 days | 40-50h | 🔴 CRITICAL | Not Started |
| **4** | Plugin Foundation | 3-4 days | 24-30h | 🔴 CRITICAL | Not Started |
| **5** | Core Animation System | 8-10 days | 60-80h | 🔴 CRITICAL | Not Started |
| **6** | Health & Damage System | 4-5 days | 30-40h | 🟠 HIGH | Not Started |
| **7** | Frontend WorldTask Integration | 5-6 days | 40-50h | 🟠 HIGH | Not Started |
| **8** | Pass-Through System | 5-6 days | 30-40h | 🟡 MEDIUM | Not Started |
| **9** | Siege Integration | 4-5 days | 25-35h | 🟡 MEDIUM | Not Started |
| **10** | Guard System (Future) | 6-7 days | 40-50h | 🟢 LOW | Future |

**Total Implementation**: ~25-35 weeks (assuming 1 phase per sprint)  
**Current Sprint Focus**: Phase 1 (Backend Foundation)

---

## Phase 1: Backend Foundation (Entity, DTOs, Repositories)

### Priority: 🔴 CRITICAL - Blocks all other work
### Duration: 5-7 days | Effort: 40-50 hours

### 1.1 Extend GateStructure Entity

**File**: `knk-web-api-v2/Models/Structures/GateStructure.cs`

**Current State**: 13 fields (minimal)  
**Target State**: 47 fields (complete)

**Tasks**:

- [ ] Update existing fields with validation & constraints
  - `Name` (required, 3-50 chars, unique within domain)
  - `IconMaterialRefId` (optional, FK to MinecraftMaterialRef)
  - `DomainId` (required, FK)
  
- [ ] Add Gate Type & Animation Configuration (14 new fields)
  - `GateType` enum (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS)
  - `MotionType` enum (VERTICAL, LATERAL, ROTATION)
  - `FaceDirection` (8 cardinal directions: N, NE, E, SE, S, SW, W, NW)
  - `AnimationDurationTicks` (int, range 20-200, default 60)
  - `AnimationTickRate` (int, range 1-5, default 1)
  - `RotationMaxAngleDegrees` (int, range 0-180, default 90)
  - `MirrorRotation` (bool, default true for DOUBLE_DOORS)
  - `FallbackMaterialRefId` (optional, FK to MinecraftMaterialRef)
  - `TileEntityPolicy` enum (NONE, DECORATIVE_ONLY, ALL)
  - `IsOverridable` (bool, default true)
  - `AnimateDuringSiege` (bool, default true)
  - `CurrentSiegeId` (int?, optional FK to Siege)
  - `IsSiegeObjective` (bool, default false)

- [ ] Add Geometry Definition Fields (15 new fields)
  - `GeometryDefinitionMode` enum (PLANE_GRID, FLOOD_FILL)
  - `AnchorPoint` (JSON string: {x, y, z})
  - `ReferencePoint1` (JSON string: {x, y, z})
  - `ReferencePoint2` (JSON string: {x, y, z})
  - `HingeAxis` (JSON string: {x, y, z} normalized vector, auto-calculated)
  - `GeometryWidth` (int, range 1-50)
  - `GeometryHeight` (int, range 1-50)
  - `GeometryDepth` (int, range 1-10, default 1)
  - `SeedBlocks` (JSON array: [{x,y,z}, ...])
  - `ScanMaxBlocks` (int, default 500, range 50-2000)
  - `ScanMaxRadius` (int, default 20, range 5-50)
  - `ScanMaterialWhitelist` (JSON array of material names)
  - `ScanMaterialBlacklist` (JSON array of material names)
  - `ScanPlaneConstraint` (bool, default false)
  - `LeftDoorSeedBlock` (JSON string: {x,y,z}, for DOUBLE_DOORS)
  - `RightDoorSeedBlock` (JSON string: {x,y,z}, for DOUBLE_DOORS)

- [ ] Add Health & Combat System (7 new fields)
  - `HealthMax` (double, default 500, range 1-10000)
  - `HealthCurrent` (double, default = HealthMax)
  - `IsInvincible` (bool, default true)
  - `CanRespawn` (bool, default true)
  - `RespawnRateSeconds` (int, default 300, range 10-3600)
  - `AllowContinuousDamage` (bool, default true)
  - `ContinuousDamageMultiplier` (double, default 1.0, range 0.1-5.0)
  - `ContinuousDamageDurationSeconds` (int, default 5, range 1-30)

- [ ] Add Pass-Through System (3 new fields)
  - `AllowPassThrough` (bool, default false)
  - `PassThroughDurationSeconds` (int, default 4, range 1-30)
  - `PassThroughConditionsJson` (JSON string: complex conditions schema)

- [ ] Add Health Display System (3 new fields)
  - `ShowHealthDisplay` (bool, default true)
  - `HealthDisplayMode` enum (ALWAYS, DAMAGED_ONLY, NEVER, SIEGE_ONLY)
  - `HealthDisplayYOffset` (int, default 2, range -5 to 20)

- [ ] Add Guard System (3 new fields, future)
  - `GuardSpawnLocationsJson` (JSON array: [{x,y,z,yaw,pitch}, ...])
  - `GuardCount` (int, default 0, range 0-10)
  - `GuardNpcTemplateId` (int?, optional FK to NpcTemplate)

- [ ] Add WorldGuard Integration (2 new fields)
  - `RegionClosedId` (string, FK to WorldGuard region)
  - `RegionOpenedId` (string, FK to WorldGuard region)

- [ ] Add Activation & Status (1 new field)
  - `IsActive` (bool, default false)

- [ ] Add Audit & Navigation (2 new fields, inherited or new)
  - `CreatedAt` (DateTime, set on creation)
  - `UpdatedAt` (DateTime, updated on modification)

- [ ] Add Navigation Properties
  - `Domain` (navigation to parent domain)
  - `GateBlockSnapshots` (collection of block snapshots)
  - `AnimationEvents` (audit trail collection)

**Entity Validation Rules**:
```csharp
// In OnModelCreating (DbContext)
modelBuilder.Entity<GateStructure>()
    .HasKey(g => g.Id);
    
modelBuilder.Entity<GateStructure>()
    .Property(g => g.Name)
    .IsRequired()
    .HasMaxLength(50);
    
modelBuilder.Entity<GateStructure>()
    .HasIndex(g => new { g.DomainId, g.Name })
    .IsUnique();
    
// Validate HealthCurrent <= HealthMax
modelBuilder.Entity<GateStructure>()
    .Property(g => g.HealthCurrent)
    .IsRequired();

// Ensure coordinate fields are valid JSON
// (validation in service layer)
```

**Effort**: 2-3 hours

---

### 1.2 Create GateBlockSnapshot Entity

**File**: `knk-web-api-v2/Models/Structures/GateBlockSnapshot.cs` (NEW)

**Purpose**: Store immutable snapshot of block state at time of gate creation  
**Related to**: Legacy `blockSnapshots` field mapping

**Fields**:
```csharp
public class GateBlockSnapshot
{
    public int Id { get; set; }
    public int GateStructureId { get; set; }
    
    // Block position (relative to anchor point or absolute)
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    
    // Block state
    public string MaterialName { get; set; } = string.Empty; // e.g., "OAK_PLANKS"
    public string BlockDataJson { get; set; } = "{}"; // Metadata: rotation, type, etc
    public bool IsTileEntity { get; set; } = false;
    public string? TileEntityJson { get; set; } // Serialized NBT data
    
    // Metadata
    public DateTime CreatedAt { get; set; }
    
    // Navigation
    public GateStructure GateStructure { get; set; } = null!;
}
```

**Validation Rules**:
- RelativeX, Y, Z must be within reasonable bounds (-50 to 50)
- MaterialName must be valid Minecraft material (validated against enum)
- MaxLength on BlockDataJson and TileEntityJson (e.g., 1000 chars)

**Effort**: 1 hour

---

### 1.3 Create EF Core Migration

**File**: `knk-web-api-v2/Migrations/[timestamp]_AddGateStructureAnimationFields.cs` (auto-generated)

**Tasks**:

- [ ] Run: `dotnet ef migrations add AddGateStructureAnimationFields`
  ```bash
  cd knk-web-api-v2
  dotnet ef migrations add AddGateStructureAnimationFields \
    --context ApplicationDbContext \
    --output-dir Migrations
  ```

- [ ] Verify migration includes:
  - GateBlockSnapshot table creation (Id, GateStructureId, coordinates, material, metadata)
  - Foreign key: GateStructureId → GateStructure(Id)
  - GateStructure column additions (all 34 new fields)
  - Indexes on GateStructure(DomainId, Name) and GateStructureId in GateBlockSnapshot
  - Default values (HealthMax=500, IsActive=false, etc)
  - JSON column types for PostgeSQL/SQL Server compatibility

- [ ] Review generated SQL:
  ```sql
  ALTER TABLE GateStructures ADD GateType INT NOT NULL DEFAULT 0;
  ALTER TABLE GateStructures ADD MotionType INT NOT NULL DEFAULT 0;
  -- ... more columns ...
  CREATE TABLE GateBlockSnapshots (
      Id INT PRIMARY KEY IDENTITY,
      GateStructureId INT NOT NULL,
      RelativeX INT NOT NULL,
      RelativeY INT NOT NULL,
      RelativeZ INT NOT NULL,
      MaterialName NVARCHAR(50) NOT NULL,
      BlockDataJson NVARCHAR(1000),
      IsTileEntity BIT DEFAULT 0,
      TileEntityJson NVARCHAR(MAX),
      CreatedAt DATETIME2 DEFAULT GETDATE(),
      FOREIGN KEY (GateStructureId) REFERENCES GateStructures(Id)
  );
  ```

- [ ] Test rollback: `dotnet ef migrations remove`
- [ ] Apply migration: `dotnet ef database update`
- [ ] Verify tables created: Check SSMS or DB viewer

**Effort**: 1-1.5 hours

---

### 1.4 Create DTOs

**Files**:
- `knk-web-api-v2/Dtos/Structures/GateStructureDtos.cs` (NEW)
- `knk-web-api-v2/Dtos/Structures/GateBlockSnapshotDtos.cs` (NEW)

**Create DTOs**:

```csharp
// GateStructureDtos.cs
public class GateStructureCreateDto
{
    public string Name { get; set; } = string.Empty;
    public int DomainId { get; set; }
    public int? DistrictId { get; set; }
    public int? StreetId { get; set; }
    public int? IconMaterialRefId { get; set; }
    
    // Gate type
    public string GateType { get; set; } = "SLIDING"; // enum as string
    public string MotionType { get; set; } = "VERTICAL";
    public string FaceDirection { get; set; } = "north";
    public int AnimationDurationTicks { get; set; } = 60;
    public int AnimationTickRate { get; set; } = 1;
    
    // Geometry
    public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
    public string? AnchorPoint { get; set; } // JSON
    public string? ReferencePoint1 { get; set; } // JSON
    public string? ReferencePoint2 { get; set; } // JSON
    public int GeometryWidth { get; set; }
    public int GeometryHeight { get; set; }
    public int GeometryDepth { get; set; } = 1;
    public string? SeedBlocks { get; set; } // JSON array
    
    // Health
    public double HealthMax { get; set; } = 500;
    public bool IsInvincible { get; set; } = true;
    public bool AllowContinuousDamage { get; set; } = true;
    
    // Regions
    public string? RegionClosedId { get; set; }
    public string? RegionOpenedId { get; set; }
}

public class GateStructureDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int DomainId { get; set; }
    // ... all 47 fields ...
    public double HealthCurrent { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<GateBlockSnapshotDto> GateBlockSnapshots { get; set; } = new();
}

public class GateBlockSnapshotDto
{
    public int Id { get; set; }
    public int RelativeX { get; set; }
    public int RelativeY { get; set; }
    public int RelativeZ { get; set; }
    public string MaterialName { get; set; } = string.Empty;
    public string BlockDataJson { get; set; } = "{}";
}
```

**Effort**: 1.5-2 hours

---

### 1.5 Extend IStructureRepository & GateStructureRepository

**File**: `knk-web-api-v2/Repositories/StructureRepository.cs`

**Add Methods**:

```csharp
// In IStructureRepository interface
Task<GateStructure?> GetGateByIdAsync(int id);
Task<IEnumerable<GateStructure>> GetGatesByDomainAsync(int domainId);
Task<bool> IsGateNameUniqueAsync(string name, int domainId, int? excludeId = null);
Task<GateStructure?> FindGateByRegionAsync(string regionId);
Task UpdateGateHealthAsync(int id, double newHealth);
Task UpdateGateAnimationStateAsync(int id, bool isOpen);
Task<IEnumerable<GateBlockSnapshot>> GetGateBlocksAsync(int gateId);
Task CreateGateBlockSnapshotsAsync(int gateId, List<GateBlockSnapshot> blocks);
Task DeleteGateBlocksAsync(int gateId);
```

**Implementation**:

```csharp
public async Task<GateStructure?> GetGateByIdAsync(int id)
{
    return await _context.GateStructures
        .Include(g => g.GateBlockSnapshots)
        .FirstOrDefaultAsync(g => g.Id == id);
}

public async Task<IEnumerable<GateStructure>> GetGatesByDomainAsync(int domainId)
{
    return await _context.GateStructures
        .Where(g => g.DomainId == domainId)
        .Include(g => g.GateBlockSnapshots)
        .OrderBy(g => g.Name)
        .ToListAsync();
}

public async Task<bool> IsGateNameUniqueAsync(string name, int domainId, int? excludeId = null)
{
    var query = _context.GateStructures
        .Where(g => g.DomainId == domainId && g.Name == name);
    
    if (excludeId.HasValue)
        query = query.Where(g => g.Id != excludeId.Value);
    
    return !await query.AnyAsync();
}

public async Task UpdateGateHealthAsync(int id, double newHealth)
{
    var gate = await _context.GateStructures.FindAsync(id);
    if (gate == null) throw new KeyNotFoundException($"Gate {id} not found");
    
    gate.HealthCurrent = Math.Max(0, Math.Min(newHealth, gate.HealthMax));
    gate.UpdatedAt = DateTime.UtcNow;
    await _context.SaveChangesAsync();
}

// ... other methods
```

**Effort**: 2-2.5 hours

---

### 1.6 Create AutoMapper Mapping Profile

**File**: `knk-web-api-v2/Mapping/GateStructureMappingProfile.cs` (NEW)

**Tasks**:

- [ ] Create mapping profile with AutoMapper
- [ ] GateStructure → GateStructureDto (include nested blocks)
- [ ] GateStructureCreateDto → GateStructure
- [ ] GateBlockSnapshot → GateBlockSnapshotDto
- [ ] Handle JSON fields (serialize/deserialize coordinates, seed blocks)
- [ ] Set default values (HealthCurrent = HealthMax on creation)
- [ ] Map enums (GateType, MotionType, etc to strings)

```csharp
public class GateStructureMappingProfile : Profile
{
    public GateStructureMappingProfile()
    {
        // Create mapping
        CreateMap<GateStructureCreateDto, GateStructure>()
            .ForMember(dest => dest.HealthCurrent, opt => opt.MapFrom(src => src.HealthMax))
            .ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(_ => DateTime.UtcNow))
            .ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(_ => DateTime.UtcNow));
        
        // Read mapping
        CreateMap<GateStructure, GateStructureDto>()
            .ForMember(dest => dest.GateBlockSnapshots, opt => opt.MapFrom(src => src.GateBlockSnapshots));
        
        // Block snapshot mapping
        CreateMap<GateBlockSnapshot, GateBlockSnapshotDto>();
        CreateMap<GateBlockSnapshotDto, GateBlockSnapshot>();
    }
}
```

**Effort**: 1 hour

---

### 1.7 Register Services in Dependency Injection

**File**: `knk-web-api-v2/Program.cs`

**Tasks**:

- [ ] Register GateStructureService (to be created in Phase 2)
- [ ] Register repositories if using separate GateRepository
- [ ] Add to ConfigureServices:

```csharp
services.AddScoped<IGateStructureRepository, GateStructureRepository>();
services.AddScoped<IGateStructureService, GateStructureService>();
services.AddAutoMapper(typeof(GateStructureMappingProfile));
```

**Effort**: 30 minutes

---

### Phase 1 Summary

- **Total Effort**: 40-50 hours
- **Risk**: Low (standard CRUD, EF Core operations)
- **Deliverables**: 
  - Extended GateStructure entity (47 fields)
  - GateBlockSnapshot entity
  - EF Core migration
  - DTOs (Create, Read, Block Snapshot)
  - Mapping profile
  - Repository methods
  - DI registration

- **Blockers**: None
- **Testing**: Unit tests for repository methods, validation

- **Completion Criteria**:
  - ✅ Migration applies cleanly
  - ✅ Database schema matches entity definitions
  - ✅ Mapping tests pass
  - ✅ Repository methods return correct data

---

## Phase 2: Backend Service Layer (Business Logic)

### Priority: 🔴 CRITICAL
### Duration: 5-6 days | Effort: 40-50 hours

### 2.1 Create GateStructureService Interface & Implementation

**Files**:
- `knk-web-api-v2/Services/Interfaces/IGateStructureService.cs` (NEW)
- `knk-web-api-v2/Services/GateStructureService.cs` (NEW)

**Service Methods**:

```csharp
public interface IGateStructureService
{
    // CRUD
    Task<GateStructureDto> CreateGateAsync(GateStructureCreateDto dto, int userId);
    Task<GateStructureDto> GetGateAsync(int id);
    Task<IEnumerable<GateStructureDto>> GetGatesByDomainAsync(int domainId);
    Task<GateStructureDto> UpdateGateAsync(int id, GateStructureUpdateDto dto, int userId);
    Task DeleteGateAsync(int id, int userId);
    
    // Geometry calculation
    Task<GateGeometryDto> CalculateGeometryAsync(GateStructureCreateDto dto);
    Task<List<GateBlockSnapshot>> GenerateBlockSnapshotsAsync(GateStructureCreateDto dto);
    
    // Health & damage
    Task ApplyDamageAsync(int gateId, double damage, string reason);
    Task RepairGateAsync(int gateId);
    Task UpdateHealthAsync(int gateId, double health);
    
    // Animation state
    Task SetAnimationStateAsync(int gateId, bool isOpen);
    Task<bool> GetAnimationStateAsync(int gateId);
    
    // Validation
    Task ValidateGateCreationAsync(GateStructureCreateDto dto);
    Task<(bool IsValid, string? Error)> ValidateCoordinatesAsync(string? anchorPoint, string? refPoint1, string? refPoint2);
    
    // Activation
    Task ActivateGateAsync(int gateId);
    Task DeactivateGateAsync(int gateId);
}
```

**Key Implementation Details**:

1. **CreateGateAsync**: 
   - Validate input
   - Generate block snapshots
   - Save gate and blocks
   - Return DTO

2. **CalculateGeometryAsync**:
   - Parse JSON coordinates
   - Calculate hinge axis
   - Compute gate dimensions
   - Validate non-collinearity

3. **GenerateBlockSnapshotsAsync**:
   - Parse AnchorPoint, ReferencePoint1/2
   - Generate grid of blocks (PLANE_GRID mode)
   - Query Minecraft materials
   - Create snapshot records

4. **ApplyDamageAsync**:
   - Check IsInvincible
   - Reduce health
   - Record damage in audit trail
   - Handle destruction (HealthCurrent == 0)

5. **ValidateGateCreationAsync**:
   - Name length (3-50)
   - Unique name in domain
   - Valid domain/district/street IDs
   - Coordinate validation
   - Health range

**Effort**: 8-10 hours

---

### 2.2 Create Geometry Calculation Utilities

**File**: `knk-web-api-v2/Services/Utilities/GeometryCalculator.cs` (NEW)

**Purpose**: Math operations for gate geometry

**Methods**:

```csharp
public static class GeometryCalculator
{
    // Coordinate operations
    public static (double x, double y, double z) ParseCoordinate(string json);
    public static string SerializeCoordinate(double x, double y, double z);
    
    // Vector operations
    public static Vector3 Normalize(Vector3 v);
    public static Vector3 CrossProduct(Vector3 a, Vector3 b);
    public static double DotProduct(Vector3 a, Vector3 b);
    public static double Distance(Vector3 from, Vector3 to);
    
    // Geometry validation
    public static bool ArePointsCollinear(Vector3 p0, Vector3 p1, Vector3 p2, double tolerance = 0.01);
    public static Vector3 CalculateHingeAxis(Vector3 anchorPoint, Vector3 referencePoint1);
    
    // Grid generation (PLANE_GRID mode)
    public static List<(int x, int y, int z)> GeneratePlaneGrid(
        Vector3 anchorPoint, Vector3 axis1, Vector3 axis2,
        int width, int height, int depth);
    
    // Flood fill (FLOOD_FILL mode)
    public static List<(int x, int y, int z)> FloodFill(
        IEnumerable<(int x, int y, int z)> seedBlocks,
        int maxBlocks, int maxRadius,
        List<string>? materialWhitelist = null,
        List<string>? materialBlacklist = null);
}

public record Vector3(double X, double Y, double Z);
```

**Effort**: 3-4 hours

---

### 2.3 Create GateDamageService

**Files**:
- `knk-web-api-v2/Services/Interfaces/IGateDamageService.cs` (NEW)
- `knk-web-api-v2/Services/GateDamageService.cs` (NEW)

**Methods**:

```csharp
public interface IGateDamageService
{
    Task<double> CalculateDamageAsync(int gateId, double baseDamage, string damageType);
    Task ApplyContinuousDamageAsync(int gateId, double damage);
    Task StopContinuousDamageAsync(int gateId);
    Task<bool> IsContinuousDamageActiveAsync(int gateId);
}
```

**Implementation**:
- Check IsInvincible flag
- Apply ContinuousDamageMultiplier
- Handle continuous damage expiry
- Record damage events

**Effort**: 2-3 hours

---

### 2.4 Create GateAnimationService

**Files**:
- `knk-web-api-v2/Services/Interfaces/IGateAnimationService.cs` (NEW)
- `knk-web-api-v2/Services/GateAnimationService.cs` (NEW)

**Methods**:

```csharp
public interface IGateAnimationService
{
    Task<GateAnimationDto> TriggerAnimationAsync(int gateId, bool open, string initiatedBy);
    Task<GateAnimationStateDto> GetAnimationStateAsync(int gateId);
    Task SetAnimationStateAsync(int gateId, bool isOpen);
    Task<int> GetEstimatedDurationTicksAsync(int gateId);
}
```

**Implementation**:
- Query gate configuration
- Calculate animation parameters (duration, tick rate)
- Record animation event
- Notify plugin via API or message queue
- Track state (open, opening, closed, closing, stuck)

**Effort**: 3-4 hours

---

### Phase 2 Summary

- **Total Effort**: 40-50 hours
- **Risk**: Medium (complex geometry calculations, damage logic)
- **Deliverables**:
  - GateStructureService (CRUD, validation)
  - GateDamageService
  - GateAnimationService
  - GeometryCalculator utility
  - Service tests

**Testing**: Unit tests for geometry calculations, damage application, state transitions

**Completion Criteria**:
- ✅ All services instantiate with DI
- ✅ Geometry calculations produce valid block grids
- ✅ Damage respects invincibility and multipliers
- ✅ Animation state transitions are correct

---

## Phase 3: Backend Controllers & API Endpoints

### Priority: 🔴 CRITICAL
### Duration: 3-4 days | Effort: 25-30 hours

### 3.1 Create GateStructureController

**File**: `knk-web-api-v2/Controllers/GateStructureController.cs` (NEW)

**Endpoints**:

```csharp
[ApiController]
[Route("api/[controller]")]
public class GateStructureController : ControllerBase
{
    // CRUD
    [HttpPost]
    public async Task<ActionResult<GateStructureDto>> CreateGate(GateStructureCreateDto dto)
    
    [HttpGet("{id}")]
    public async Task<ActionResult<GateStructureDto>> GetGate(int id)
    
    [HttpGet("list/domain/{domainId}")]
    public async Task<ActionResult<IEnumerable<GateStructureDto>>> GetGatesByDomain(int domainId)
    
    [HttpPut("{id}")]
    public async Task<ActionResult<GateStructureDto>> UpdateGate(int id, GateStructureUpdateDto dto)
    
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteGate(int id)
    
    // Animation
    [HttpPost("{id}/animate")]
    public async Task<ActionResult<GateAnimationDto>> AnimateGate(int id, [FromBody] GateAnimationRequestDto request)
    
    [HttpGet("{id}/animation-state")]
    public async Task<ActionResult<GateAnimationStateDto>> GetAnimationState(int id)
    
    // Health & Damage
    [HttpPost("{id}/damage")]
    public async Task<ActionResult<GateStructureDto>> ApplyDamage(int id, [FromBody] DamageRequestDto request)
    
    [HttpPost("{id}/repair")]
    public async Task<ActionResult<GateStructureDto>> RepairGate(int id)
    
    [HttpPut("{id}/health")]
    public async Task<ActionResult<GateStructureDto>> UpdateHealth(int id, [FromBody] HealthUpdateDto request)
    
    // Activation
    [HttpPost("{id}/activate")]
    public async Task<ActionResult<GateStructureDto>> ActivateGate(int id)
    
    [HttpPost("{id}/deactivate")]
    public async Task<ActionResult<GateStructureDto>> DeactivateGate(int id)
    
    // Geometry
    [HttpPost("calculate-geometry")]
    public async Task<ActionResult<GateGeometryDto>> CalculateGeometry([FromBody] GateStructureCreateDto dto)
}
```

**Effort**: 4-5 hours

---

### 3.2 Create Supporting DTOs

**File**: `knk-web-api-v2/Dtos/Structures/GateAnimationDtos.cs` (NEW)

**DTOs**:

```csharp
public class GateAnimationRequestDto
{
    public bool Open { get; set; }
    public string? Reason { get; set; }
}

public class GateAnimationDto
{
    public int GateId { get; set; }
    public bool IsOpen { get; set; }
    public int DurationTicks { get; set; }
    public DateTime InitiatedAt { get; set; }
    public string InitiatedBy { get; set; } = string.Empty;
}

public class DamageRequestDto
{
    public double Amount { get; set; }
    public string DamageType { get; set; } = "melee"; // melee, fire, magic
    public int? AttackerId { get; set; }
    public string? Reason { get; set; }
}

public class HealthUpdateDto
{
    public double NewHealth { get; set; }
    public string? Reason { get; set; }
}

public class GateGeometryDto
{
    public int Width { get; set; }
    public int Height { get; set; }
    public int Depth { get; set; }
    public int TotalBlocks { get; set; }
    public List<GateBlockSnapshotDto> Blocks { get; set; } = new();
}
```

**Effort**: 1.5-2 hours

---

### 3.3 Add Validation & Error Handling

**File**: `knk-web-api-v2/Controllers/GateStructureController.cs` (update)

**Tasks**:

- [ ] Add authorization checks (admin-only creation, user owns gate for updates)
- [ ] Add try-catch blocks for service exceptions
- [ ] Return appropriate HTTP status codes:
  - 201 Created (POST)
  - 200 OK (GET, PUT, DELETE success)
  - 400 Bad Request (validation)
  - 404 Not Found
  - 409 Conflict (duplicate name)
  - 500 Internal Server Error

- [ ] Add error response DTOs:

```csharp
public class ErrorResponseDto
{
    public int StatusCode { get; set; }
    public string Message { get; set; } = string.Empty;
    public Dictionary<string, string[]>? Errors { get; set; }
}
```

**Effort**: 2-3 hours

---

### Phase 3 Summary

- **Total Effort**: 25-30 hours
- **Risk**: Low (standard REST endpoints)
- **Deliverables**:
  - GateStructureController (9 endpoints)
  - Supporting DTOs
  - Error handling
  - API documentation (Swagger)

**Testing**: Integration tests for all endpoints

**Completion Criteria**:
- ✅ All endpoints return correct status codes
- ✅ Validation errors are descriptive
- ✅ Authorization checks work
- ✅ Swagger documentation is complete

---

## Phase 4: Frontend FormConfiguration Setup

### Priority: 🔴 CRITICAL
### Duration: 4-5 days | Effort: 30-40 hours

### 4.1 Create Pre-configured FormConfiguration Template

**Task**: Create GateStructure FormConfiguration using FormConfigBuilder admin UI

**Template Name**: "Gate Creation Wizard (Default)"

**Structure**: 6-step form (from REQUIREMENTS_GATE_FRONTEND.md)

**Steps**:
1. Basic Info (name, domain, district, street, icon)
2. Gate Type & Orientation (type, motion, direction, animation duration/rate)
3. Geometry Definition (PLANE_GRID vs FLOOD_FILL, coordinates, dimensions)
4. Regions & Animation (WorldGuard regions, fall back material, tile entity policy)
5. Health & Combat (health max/current, invincible, respawn, continuous damage)
6. Advanced Features (pass-through, guards, siege, activation)

**Field Count**: 40+ fields across 6 steps

**Auto-Calculation Triggers**:
- GeometryWidth ← AnchorPoint + ReferencePoint1 distance
- HingeAxis ← Coordinate vectors
- HealthCurrent ← HealthMax (on creation only)

**Conditional Visibility**:
- GeometryDefinitionMode switches between PLANE_GRID and FLOOD_FILL fields
- MotionType = ROTATION shows RotationMaxAngleDegrees
- GateType = DOUBLE_DOORS shows left/right door seed blocks
- AllowPassThrough = true shows PassThroughDurationSeconds
- Siege fields appear in Step 6

**Effort**: 6-8 hours (manual UI work + JSON creation)

**Manual Steps**:
1. Login to admin dashboard
2. Navigate to Form Configurations
3. Click "Create from Template" → Select "Gate Creation Wizard"
4. Configure each step with appropriate fields
5. Set validation rules and defaults
6. Mark as "Default" for GateStructure entity
7. Publish configuration

---

### 4.2 Extend FormConfigBuilder Components

**Files**:
- `knk-web-app/src/components/FormConfigBuilder/FieldEditor.tsx` (update)
- `knk-web-app/src/components/FormConfigBuilder/FormConfigBuilder.tsx` (update)

**Enhancements**:

1. **FieldEditor.tsx**:
   - Add "WorldTask Settings" section
   - New inputs:
     - Enable WorldTask checkbox
     - Task Type dropdown (CAPTURE_LOCATION, CAPTURE_MULTIPLE_LOCATIONS, SELECT_WORLDGUARD_REGION, CREATE_WORLDGUARD_REGION)
     - Instructions textarea
     - Allow Existing checkbox
     - Allow Create checkbox

2. **FormConfigBuilder.tsx**:
   - Add "Save as Template" button
   - Add "Create from Template" modal
   - Pre-fill entity type from template

**Effort**: 4-5 hours

---

### 4.3 Create Compass Selector Widget

**File**: `knk-web-app/src/components/Common/CompassSelector.tsx` (NEW)

**Purpose**: Visual 8-direction selector for FaceDirection field

**Features**:
- Visual compass rose (N, NE, E, SE, S, SW, W, NW)
- Click to select direction
- Highlight selected direction
- Return direction string to FormWizard

**Example**:
```tsx
<CompassSelector
  value="north"
  onChange={(direction) => handleFieldChange('FaceDirection', direction)}
  disabled={false}
/>
```

**Effort**: 2-3 hours

---

### Phase 4 Summary

- **Total Effort**: 30-40 hours
- **Risk**: Medium (requires manual FormConfiguration creation, UI testing)
- **Deliverables**:
  - GateStructure FormConfiguration template (6 steps, 40+ fields)
  - Enhanced FormConfigBuilder with WorldTask support
  - Compass selector widget
  - Admin documentation

**Testing**: Test form wizard with template, verify all fields are editable

**Completion Criteria**:
- ✅ FormConfiguration saves without errors
- ✅ FormWizard loads template correctly
- ✅ All 6 steps display correctly
- ✅ Compass selector works
- ✅ Field validation triggers on appropriate fields

---

## Phase 5: Frontend FormWizard Integration

### Priority: 🔴 CRITICAL
### Duration: 5-7 days | Effort: 40-50 hours

### 5.1 Enhance FormWizard Auto-Calculation Logic

**File**: `knk-web-app/src/components/FormWizard/FormWizard.tsx` (update)

**Tasks**:

- [ ] Add entity-specific auto-calculation for GateStructure:

```typescript
const handleFieldChange = (fieldName: string, value: unknown) => {
  setCurrentStepData(prev => {
    const updated = { ...prev, [fieldName]: value };
    
    // Auto-calculate derived fields for GateStructure
    if (entityName === 'GateStructure') {
      // Calculate GeometryWidth from AnchorPoint → ReferencePoint1
      if (fieldName === 'ReferencePoint1' && updated.AnchorPoint) {
        try {
          const p0 = JSON.parse(updated.AnchorPoint as string);
          const p1 = JSON.parse(value as string);
          const width = Math.round(Math.sqrt(
            Math.pow(p1.x - p0.x, 2) + 
            Math.pow(p1.z - p0.z, 2)
          )) + 1;
          updated.GeometryWidth = width;
        } catch {}
      }
      
      // Calculate HingeAxis
      if (fieldName === 'ReferencePoint1' && updated.AnchorPoint) {
        try {
          const p0 = JSON.parse(updated.AnchorPoint as string);
          const p1 = JSON.parse(value as string);
          const axis = normalize({
            x: p1.x - p0.x,
            y: p1.y - p0.y,
            z: p1.z - p0.z
          });
          updated.HingeAxis = JSON.stringify(axis);
        } catch {}
      }
      
      // Auto-populate HealthCurrent
      if (fieldName === 'HealthMax' && !entityId) {
        updated.HealthCurrent = value;
      }
    }
    
    return updated;
  });
};

// Helper functions
const normalize = (v: { x: number; y: number; z: number }) => {
  const len = Math.sqrt(v.x ** 2 + v.y ** 2 + v.z ** 2);
  return { x: v.x / len, y: v.y / len, z: v.z / len };
};
```

- [ ] Add step-specific validation for Gate Geometry step:

```typescript
const validateStep = (): boolean => {
  const newErrors: { [fieldName: string]: string } = {};
  
  if (currentStepIndex === 2 && entityName === 'GateStructure') {
    // Validate geometry fields
    const anchorStr = currentStepData.AnchorPoint;
    const ref1Str = currentStepData.ReferencePoint1;
    const ref2Str = currentStepData.ReferencePoint2;
    
    // Validate collinearity
    if (anchorStr && ref1Str && ref2Str) {
      try {
        const p0 = JSON.parse(anchorStr as string);
        const p1 = JSON.parse(ref1Str as string);
        const p2 = JSON.parse(ref2Str as string);
        
        if (arePointsCollinear(p0, p1, p2)) {
          newErrors.ReferencePoint2 = "ReferencePoint2 cannot be collinear with AnchorPoint and ReferencePoint1";
        }
      } catch {
        newErrors.AnchorPoint = "Invalid coordinate format";
      }
    }
  }
  
  // ... standard validation
  
  setErrors(newErrors);
  return Object.keys(newErrors).length === 0;
};

const arePointsCollinear = (
  p0: { x: number; y: number; z: number },
  p1: { x: number; y: number; z: number },
  p2: { x: number; y: number; z: number },
  tolerance = 0.01
): boolean => {
  const v1 = { x: p1.x - p0.x, y: p1.y - p0.y, z: p1.z - p0.z };
  const v2 = { x: p2.x - p0.x, y: p2.y - p0.y, z: p2.z - p0.z };
  
  const cross = {
    x: v1.y * v2.z - v1.z * v2.y,
    y: v1.z * v2.x - v1.x * v2.z,
    z: v1.x * v2.y - v1.y * v2.x
  };
  
  const magnitude = Math.sqrt(cross.x ** 2 + cross.y ** 2 + cross.z ** 2);
  return magnitude < tolerance;
};
```

**Effort**: 4-5 hours

---

### 5.2 Enhance WorldBoundFieldRenderer

**File**: `knk-web-app/src/components/Workflow/WorldBoundFieldRenderer.tsx` (update)

**Enhancements**:

- [ ] Add coordinate display (human-readable format):

```typescript
const renderCoordinateDisplay = (value: any) => {
  if (!value) return null;
  
  try {
    const coords = typeof value === 'string' ? JSON.parse(value) : value;
    if (Array.isArray(coords)) {
      // Multiple coordinates
      return (
        <div className="coordinate-list">
          {coords.map((coord, idx) => (
            <div key={idx} className="coordinate-item">
              [{coord.x}, {coord.y}, {coord.z}]
            </div>
          ))}
        </div>
      );
    } else {
      // Single coordinate
      return <div className="coordinate">[{coords.x}, {coords.y}, {coords.z}]</div>;
    }
  } catch {
    return <div className="invalid-coordinate">Invalid coordinate data</div>;
  }
};
```

- [ ] Add distance calculation display (for ReferencePoint1):

```typescript
const calculateDistance = () => {
  if (!value || !previousFields?.AnchorPoint) return null;
  
  try {
    const p1 = JSON.parse(value as string);
    const p0 = JSON.parse(previousFields.AnchorPoint as string);
    const dist = Math.sqrt(
      Math.pow(p1.x - p0.x, 2) +
      Math.pow(p1.y - p0.y, 2) +
      Math.pow(p1.z - p0.z, 2)
    );
    return dist.toFixed(2);
  } catch {
    return null;
  }
};
```

- [ ] Add region bounds preview (for RegionClosedId):

```typescript
const renderRegionBounds = () => {
  if (!value || !regionMetadata) return null;
  
  return (
    <div className="region-bounds">
      <strong>Region Bounds:</strong>
      <ul>
        <li>Min: [{regionMetadata.minX}, {regionMetadata.minY}, {regionMetadata.minZ}]</li>
        <li>Max: [{regionMetadata.maxX}, {regionMetadata.maxY}, {regionMetadata.maxZ}]</li>
      </ul>
    </div>
  );
};
```

- [ ] Add re-capture button (allow replacing captured data)

**Effort**: 3-4 hours

---

### 5.3 Create PassThroughConditionsEditor Component

**File**: `knk-web-app/src/components/FormWizard/PassThroughConditionsEditor.tsx` (NEW)

**Purpose**: Custom JSON editor for pass-through permission rules

**Features**:
- Min experience input
- Required clan dropdown
- Min ethics level (0-5)
- Donator rank dropdown (None, Bronze, Silver, Gold, Platinum)
- Comma-separated permissions
- Comma-separated user IDs (whitelist/blacklist)

**Example Implementation** (from REQUIREMENTS_GATE_FRONTEND.md):

```typescript
export const PassThroughConditionsEditor: React.FC<{
  value: string;
  onChange: (value: string) => void;
}> = ({ value, onChange }) => {
  const [conditions, setConditions] = useState<PassThroughCondition>(() => {
    try {
      return value ? JSON.parse(value) : {};
    } catch {
      return {};
    }
  });
  
  const handleChange = (key: keyof PassThroughCondition, val: any) => {
    const updated = { ...conditions, [key]: val };
    setConditions(updated);
    onChange(JSON.stringify(updated));
  };
  
  return (
    <div className="pass-through-conditions-editor">
      {/* Min Experience */}
      <div className="form-group">
        <label>Minimum Experience</label>
        <input
          type="number"
          value={conditions.minExperience || ''}
          onChange={e => handleChange('minExperience', parseInt(e.target.value))}
          placeholder="Leave empty to disable"
        />
      </div>
      
      {/* Required Clan */}
      <div className="form-group">
        <label>Required Clan ID</label>
        <input type="number" />
      </div>
      
      {/* Min Ethics Level */}
      <div className="form-group">
        <label>Minimum Ethics Level (0-5)</label>
        <input type="number" min="0" max="5" />
      </div>
      
      {/* Donator Rank */}
      <div className="form-group">
        <label>Required Donator Rank</label>
        <select value={conditions.requiredDonatorRank || 0}>
          <option value="0">None (Free players allowed)</option>
          <option value="1">Bronze or higher</option>
          <option value="2">Silver or higher</option>
          <option value="3">Gold or higher</option>
          <option value="4">Platinum only</option>
        </select>
      </div>
      
      {/* Permissions */}
      <div className="form-group">
        <label>Required Permissions (comma-separated)</label>
        <input
          type="text"
          value={conditions.requiredPermissions?.join(', ') || ''}
          onChange={e => handleChange('requiredPermissions', e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
          placeholder="e.g., knk.gate.vip, knk.gate.passthrough.castle_gate"
        />
      </div>
      
      {/* Whitelist/Blacklist */}
      <div className="form-group">
        <label>Allowed User IDs (whitelist, comma-separated)</label>
        <input type="text" placeholder="e.g., 1, 2, 3" />
      </div>
      
      <div className="form-group">
        <label>Denied User IDs (blacklist, comma-separated)</label>
        <input type="text" placeholder="e.g., 99, 100" />
      </div>
    </div>
  );
};
```

**Effort**: 2-3 hours

---

### 5.4 Create GatePreview3D Component (Future)

**File**: `knk-web-app/src/components/FormWizard/GatePreview3D.tsx` (NEW) - *Optional for Phase 5*

**Note**: Can defer to Phase 5 extension or Phase 10 (future)

**Technologies**:
- Three.js
- react-three-fiber
- @react-three/drei

**Features** (when implemented):
- Render gate geometry in 3D
- Show anchor point and reference points
- Display hinge axis
- Play animation preview
- Camera controls (orbit, zoom, pan)

**Effort**: 20-30 hours (defer to future)

---

### Phase 5 Summary

- **Total Effort**: 40-50 hours
- **Risk**: Medium (coordinate validation, auto-calculation logic)
- **Deliverables**:
  - Enhanced FormWizard (auto-calculation, validation)
  - Enhanced WorldBoundFieldRenderer (coordinate display, distance calc)
  - PassThroughConditionsEditor component
  - GatePreview3D component (optional, can defer)

**Testing**: Test all auto-calculations, validate collinearity checks, test WorldTask capture

**Completion Criteria**:
- ✅ GeometryWidth auto-calculates from points
- ✅ HingeAxis auto-calculates from vectors
- ✅ Collinearity validation works
- ✅ Coordinate display shows human-readable format
- ✅ PassThroughConditionsEditor saves/loads JSON
- ✅ Distance calculation displays for reference points

---

## Phase 6: Plugin Foundation (API Client, Commands, Event Handlers)

### Priority: 🔴 CRITICAL
### Duration: 3-4 days | Effort: 24-30 hours

### 6.1 Create Gate Animation Manager

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/GateAnimationManager.kt` (NEW)

**Responsibilities**:
- Load gate blocks from database
- Execute animations (change blocks, play sounds, particles)
- Track animation state (open, opening, closed, closing, stuck)
- Handle interruptions

**Key Methods**:

```kotlin
class GateAnimationManager(
    private val plugin: KnkPlugin,
    private val gateApi: GateStructureApiClient
) {
    private val activeAnimations = ConcurrentHashMap<Int, AnimationState>()
    
    suspend fun animateGate(gateId: Int, openGate: Boolean): Boolean
    suspend fun stopAnimation(gateId: Int): Boolean
    fun isAnimating(gateId: Int): Boolean
    fun getAnimationState(gateId: Int): GateState
    private suspend fun loadGateBlocks(gateId: Int): List<GateBlockSnapshot>
    private fun executeBlockChanges(gateId: Int, blocks: List<GateBlockSnapshot>)
    private fun playAnimationEffects(gateId: Int, world: World)
}

enum class GateState { OPEN, OPENING, CLOSED, CLOSING, STUCK, UNKNOWN }

data class AnimationState(
    val gateId: Int,
    val state: GateState,
    val startTime: Long,
    val estimatedDurationMs: Long
)
```

**Effort**: 6-8 hours

---

### 6.2 Create Gate Damage Manager

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/GateDamageManager.kt` (NEW)

**Responsibilities**:
- Apply damage via API
- Calculate damage reduction
- Handle continuous damage effects
- Display health above gate

**Key Methods**:

```kotlin
class GateDamageManager(
    private val plugin: KnkPlugin,
    private val gateApi: GateStructureApiClient
) {
    suspend fun applyDamage(gateId: Int, damage: Double, reason: String): Boolean
    suspend fun repairGate(gateId: Int): Boolean
    suspend fun getGateHealth(gateId: Int): Double
    private fun displayHealthAboveGate(gateId: Int, health: Double, maxHealth: Double)
}
```

**Effort**: 4-5 hours

---

### 6.3 Create Gate Commands

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/commands/GateCommand.kt` (NEW)

**Commands**:
- `/gate animate {gateId} {open|close}` - Manually animate gate
- `/gate info {gateId}` - Show gate status
- `/gate damage {gateId} {amount}` - Apply damage
- `/gate repair {gateId}` - Full repair
- `/gate reload` - Reload gates from API

**Implementation**:

```kotlin
class GateCommand(
    private val animationManager: GateAnimationManager,
    private val damageManager: GateDamageManager,
    private val logger: Logger
) : CommandExecutor {
    
    override fun onCommand(sender: CommandSender, cmd: Command, label: String, args: Array<String>): Boolean {
        if (args.isEmpty()) {
            sender.sendMessage("§cUsage: /gate <animate|info|damage|repair|reload>")
            return false
        }
        
        return when (args[0].lowercase()) {
            "animate" -> handleAnimate(sender, args)
            "info" -> handleInfo(sender, args)
            "damage" -> handleDamage(sender, args)
            "repair" -> handleRepair(sender, args)
            "reload" -> handleReload(sender, args)
            else -> {
                sender.sendMessage("§cUnknown subcommand: ${args[0]}")
                false
            }
        }
    }
    
    private fun handleAnimate(sender: CommandSender, args: Array<String>): Boolean {
        if (args.size < 3) {
            sender.sendMessage("§cUsage: /gate animate <gateId> <open|close>")
            return false
        }
        // Implementation
        return true
    }
    
    // ... other handlers
}
```

**Effort**: 3-4 hours

---

### 6.4 Create Gate Event Listeners

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/listeners/GateEventListener.kt` (NEW)

**Events to Handle**:
- `PlayerInteractEvent` - Player clicks gate block
- `EntityDamageEvent` - Damage redirected to gate
- `BlockBreakEvent` - Prevent manual modification
- `BlockPlaceEvent` - Prevent manual modification

**Implementation Sketch**:

```kotlin
class GateEventListener(
    private val animationManager: GateAnimationManager,
    private val damageManager: GateDamageManager
) : Listener {
    
    @EventHandler(priority = EventPriority.NORMAL)
    fun onPlayerInteract(event: PlayerInteractEvent) {
        val block = event.clickedBlock ?: return
        val gateId = findGateByBlock(block) ?: return
        
        event.isCancelled = true
        // Trigger animation
    }
    
    @EventHandler(priority = EventPriority.NORMAL)
    fun onEntityDamage(event: EntityDamageEvent) {
        val entity = event.entity as? Damageable ?: return
        val gateId = findGateByEntity(entity) ?: return
        
        event.isCancelled = true
        // Apply damage to gate instead
    }
    
    @EventHandler(priority = EventPriority.HIGHEST)
    fun onBlockBreak(event: BlockBreakEvent) {
        if (isGateBlock(event.block)) {
            event.isCancelled = true
            event.player.sendMessage("§cYou cannot modify gate blocks")
        }
    }
    
    private fun findGateByBlock(block: Block): Int? {
        // Query loaded gates by coordinates
        return null
    }
}
```

**Effort**: 3-4 hours

---

### 6.5 Create Gate API Client

**File**: `knk-plugin-v2/knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/client/GateStructureApiClient.kt` (NEW)

**Endpoints Called**:
- GET `/api/gatestructures/{id}` - Get gate details
- POST `/api/gatestructures/{id}/animate` - Trigger animation
- POST `/api/gatestructures/{id}/damage` - Apply damage
- POST `/api/gatestructures/{id}/repair` - Repair gate
- GET `/api/gatestructures/list/domain/{domainId}` - Get gates in domain

**Implementation**:

```kotlin
class GateStructureApiClient(
    private val baseUrl: String,
    private val apiKey: String? = null
) {
    private val client = OkHttpClient()
    private val gson = Gson()
    
    suspend fun getGate(gateId: Int): GateStructureDto? = withContext(Dispatchers.IO) {
        // HTTP GET request
    }
    
    suspend fun animateGate(gateId: Int, open: Boolean): AnimationDto? = withContext(Dispatchers.IO) {
        // HTTP POST request
    }
    
    suspend fun applyDamage(gateId: Int, damage: Double, reason: String): GateStructureDto? = withContext(Dispatchers.IO) {
        // HTTP POST request
    }
}
```

**Effort**: 3-4 hours

---

### Phase 6 Summary

- **Total Effort**: 24-30 hours
- **Risk**: Low to Medium (Bukkit API usage, async operations)
- **Deliverables**:
  - GateAnimationManager
  - GateDamageManager
  - Gate commands (4 subcommands)
  - Event listeners (4 event types)
  - API client

**Testing**: Manual testing in dev server, verify animations execute, commands work

**Completion Criteria**:
- ✅ `/gate animate` command works
- ✅ `/gate info` command displays gate status
- ✅ Player interactions with gate blocks trigger animation
- ✅ API calls succeed and return expected data
- ✅ Events are properly handled (no player errors)

---

## Phase 7: Core Animation System (Execution & State Management)

### Priority: 🔴 CRITICAL
### Duration: 8-10 days | Effort: 60-80 hours

### 7.1 Implement Block Change Engine

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/BlockChangeEngine.kt` (NEW)

**Responsibilities**:
- Load gate block snapshots from API
- Calculate intermediate block states for animation
- Apply block changes to world
- Handle rollback on cancellation

**Key Methods**:

```kotlin
class BlockChangeEngine(
    private val plugin: KnkPlugin,
    private val world: World
) {
    fun generateAnimationFrames(
        blocks: List<GateBlockSnapshot>,
        startState: GateState,
        endState: GateState,
        durationTicks: Int,
        tickRate: Int
    ): List<AnimationFrame>
    
    suspend fun applyFrame(frame: AnimationFrame)
    
    fun rollbackAnimation(gateId: Int)
}

data class AnimationFrame(
    val frameNumber: Int,
    val totalFrames: Int,
    val blockChanges: List<BlockChange>
)

data class BlockChange(
    val x: Int,
    val y: Int,
    val z: Int,
    val material: Material,
    val blockData: BlockData
)
```

**Effort**: 10-12 hours

---

### 7.2 Implement Animation State Machine

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/AnimationStateMachine.kt` (NEW)

**State Transitions**:

```
CLOSED ──animate(open)──→ OPENING ──duration elapsed──→ OPEN
  ▲                                                      │
  │                                                      │
  └──────────────animate(close)──← CLOSING ←──duration elapsed
  
Error states:
  any state ──error──→ STUCK ──repair()──→ CLOSED
```

**Implementation**:

```kotlin
class AnimationStateMachine(
    private val animationManager: GateAnimationManager
) {
    private val stateTransitions = mapOf(
        GateState.CLOSED to mapOf(
            AnimationAction.OPEN to GateState.OPENING
        ),
        GateState.OPENING to mapOf(
            AnimationAction.COMPLETE to GateState.OPEN,
            AnimationAction.CANCEL to GateState.CLOSED,
            AnimationAction.ERROR to GateState.STUCK
        ),
        // ... more transitions
    )
    
    fun transitionState(currentState: GateState, action: AnimationAction): GateState {
        return stateTransitions[currentState]?.get(action) ?: currentState
    }
    
    fun isValidTransition(from: GateState, to: GateState): Boolean {
        // Check if transition exists
    }
}

enum class AnimationAction { OPEN, CLOSE, COMPLETE, CANCEL, ERROR }
```

**Effort**: 4-5 hours

---

### 7.3 Implement Geometry-Based Animation Calculation

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/GeometryAnimator.kt` (NEW)

**Responsibilities**:
- Calculate block movements based on gate type
- Generate rotation matrices (for ROTATION gates)
- Generate translation vectors (for SLIDING/LATERAL gates)
- Interpolate intermediate positions

**Key Methods**:

```kotlin
class GeometryAnimator(
    private val gate: GateStructure
) {
    fun calculateFrames(
        blocks: List<GateBlockSnapshot>,
        durationFrames: Int
    ): List<List<Vector3>> {
        return when (gate.motionType) {
            MotionType.VERTICAL -> calculateVerticalSlide(blocks, durationFrames)
            MotionType.LATERAL -> calculateLateralSlide(blocks, durationFrames)
            MotionType.ROTATION -> calculateRotation(blocks, durationFrames)
        }
    }
    
    private fun calculateVerticalSlide(
        blocks: List<GateBlockSnapshot>,
        durationFrames: Int
    ): List<List<Vector3>> {
        val direction = when (gate.gateType) {
            GateType.SLIDING -> Vector3(0, 1, 0) // Up for sliding
            GateType.TRAP -> Vector3(0, -1, 0) // Down for trap door
            else -> Vector3(0, 0, 0)
        }
        
        val frames = mutableListOf<List<Vector3>>()
        for (frame in 0..durationFrames) {
            val progress = frame.toDouble() / durationFrames
            val offset = direction * progress * 10 // 10 blocks max travel
            frames.add(blocks.map { Vector3(
                it.relativeX.toDouble() + offset.x,
                it.relativeY.toDouble() + offset.y,
                it.relativeZ.toDouble() + offset.z
            ) })
        }
        return frames
    }
    
    private fun calculateRotation(
        blocks: List<GateBlockSnapshot>,
        durationFrames: Int
    ): List<List<Vector3>> {
        // Rotate around hinge axis
        val hingeAxis = parseVector3(gate.hingeAxis!!)
        val maxAngle = gate.rotationMaxAngleDegrees.toDouble()
        
        val frames = mutableListOf<List<Vector3>>()
        for (frame in 0..durationFrames) {
            val progress = frame.toDouble() / durationFrames
            val angle = progress * maxAngle
            frames.add(blocks.map { block ->
                val pos = Vector3(block.relativeX.toDouble(), block.relativeY.toDouble(), block.relativeZ.toDouble())
                rotateAroundAxis(pos, hingeAxis, angle)
            })
        }
        return frames
    }
    
    private fun rotateAroundAxis(point: Vector3, axis: Vector3, angleDegrees: Double): Vector3 {
        // Rodrigues' rotation formula
        val angle = Math.toRadians(angleDegrees)
        val cos = kotlin.math.cos(angle)
        val sin = kotlin.math.sin(angle)
        
        // Implementation of rotation formula
        return point // Simplified
    }
}

data class Vector3(val x: Double, val y: Double, val z: Double) {
    operator fun times(scalar: Double) = Vector3(x * scalar, y * scalar, z * scalar)
    operator fun plus(other: Vector3) = Vector3(x + other.x, y + other.y, z + other.z)
}
```

**Effort**: 8-10 hours (complex math)

---

### 7.4 Implement Animation Executor

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/AnimationExecutor.kt` (NEW)

**Responsibilities**:
- Execute animation frames sequentially
- Apply block changes with tick rate
- Play sound effects and particles
- Handle completion/cancellation

**Implementation**:

```kotlin
class AnimationExecutor(
    private val plugin: KnkPlugin,
    private val blockChangeEngine: BlockChangeEngine
) : Runnable {
    
    private var currentFrameIndex = 0
    private var taskId: Int = -1
    
    fun executeAnimation(
        frames: List<AnimationFrame>,
        tickRate: Int,
        onComplete: () -> Unit
    ) {
        taskId = plugin.server.scheduler.scheduleSyncRepeatingTask(
            plugin,
            {
                if (currentFrameIndex >= frames.size) {
                    plugin.server.scheduler.cancelTask(taskId)
                    onComplete()
                    return@scheduleSyncRepeatingTask
                }
                
                val frame = frames[currentFrameIndex]
                // Apply block changes for this frame
                runBlocking { blockChangeEngine.applyFrame(frame) }
                
                currentFrameIndex++
            },
            0,
            tickRate.toLong()
        )
    }
    
    fun cancel() {
        plugin.server.scheduler.cancelTask(taskId)
    }
}
```

**Effort**: 3-4 hours

---

### Phase 7 Summary

- **Total Effort**: 60-80 hours
- **Risk**: High (complex geometry calculations, timing/sync issues)
- **Deliverables**:
  - BlockChangeEngine
  - AnimationStateMachine
  - GeometryAnimator (VERTICAL, LATERAL, ROTATION)
  - AnimationExecutor
  - Tests for all components

**Testing**: Unit tests for geometry calculations, integration tests for frame generation, manual testing of animations

**Completion Criteria**:
- ✅ SLIDING gates move vertically smoothly
- ✅ DRAWBRIDGE gates rotate correctly around hinge
- ✅ TRAP gates fall/rise correctly
- ✅ DOUBLE_DOORS open symmetrically
- ✅ Animation duration respects configuration
- ✅ Animations can be interrupted and resumed

---

## Phase 8: Health & Damage System

### Priority: 🟠 HIGH
### Duration: 4-5 days | Effort: 30-40 hours

### 8.1 Implement Damage Calculator

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/DamageCalculator.kt` (NEW)

**Responsibilities**:
- Check invincibility
- Apply damage multipliers
- Handle continuous damage duration
- Validate damage amount

**Implementation**:

```kotlin
class DamageCalculator {
    fun calculateDamage(
        baseDamage: Double,
        gate: GateStructure,
        damageType: String
    ): Double {
        if (gate.isInvincible) return 0.0
        
        val multiplier = when {
            damageType == "fire" && gate.allowContinuousDamage -> gate.continuousDamageMultiplier
            else -> 1.0
        }
        
        return baseDamage * multiplier
    }
    
    fun calculateContinuousDuration(gate: GateStructure): Long {
        return gate.continuousDamageDurationSeconds * 20L // Convert to ticks
    }
}
```

**Effort**: 2-3 hours

---

### 8.2 Implement Health Display Manager

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/HealthDisplayManager.kt` (NEW)

**Responsibilities**:
- Create ArmorStand for health display
- Update display text based on health
- Show/hide based on display mode (ALWAYS, DAMAGED_ONLY, NEVER, SIEGE_ONLY)
- Clean up displays on gate destruction

**Implementation Sketch**:

```kotlin
class HealthDisplayManager(
    private val plugin: KnkPlugin,
    private val world: World
) {
    private val displays = mutableMapOf<Int, ArmorStand>()
    
    fun createDisplay(gate: GateStructure, anchorPoint: Location): ArmorStand {
        val display = world.spawn(anchorPoint.clone().add(0.0, gate.healthDisplayYOffset.toDouble(), 0.0), ArmorStand::class.java)
        display.isCustomNameVisible = true
        display.customName = formatHealth(gate.healthCurrent, gate.healthMax)
        display.isMarker = true
        
        displays[gate.id] = display
        return display
    }
    
    fun updateDisplay(gate: GateStructure) {
        val display = displays[gate.id] ?: return
        
        val shouldShow = when (gate.healthDisplayMode) {
            "ALWAYS" -> true
            "DAMAGED_ONLY" -> gate.healthCurrent < gate.healthMax
            "NEVER" -> false
            "SIEGE_ONLY" -> gate.currentSiegeId != null
            else -> true
        }
        
        display.customNameVisible = shouldShow
        display.customName = formatHealth(gate.healthCurrent, gate.healthMax)
    }
    
    fun removeDisplay(gateId: Int) {
        displays[gateId]?.remove()
        displays.remove(gateId)
    }
    
    private fun formatHealth(current: Double, max: Double): String {
        val percent = (current / max * 100).toInt()
        val bar = "█".repeat(percent / 10) + "░".repeat(10 - percent / 10)
        return "§c§l[$bar] $current / $max HP"
    }
}
```

**Effort**: 3-4 hours

---

### 8.3 Implement Continuous Damage System

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/ContinuousDamageSystem.kt` (NEW)

**Responsibilities**:
- Track active continuous damage effects
- Apply damage per tick
- Handle expiry
- Play visual effects

**Implementation**:

```kotlin
class ContinuousDamageSystem(
    private val plugin: KnkPlugin,
    private val damageManager: GateDamageManager
) {
    private val activeDamage = mutableMapOf<Int, ContinuousDamageEffect>()
    
    fun startContinuousDamage(gateId: Int, dps: Double, durationTicks: Long) {
        val effect = ContinuousDamageEffect(gateId, dps, durationTicks, System.currentTimeMillis())
        activeDamage[gateId] = effect
        
        // Start repeating task
        plugin.server.scheduler.scheduleSyncRepeatingTask(plugin, {
            if (effect.isExpired()) {
                stopContinuousDamage(gateId)
                return@scheduleSyncRepeatingTask
            }
            
            val tickDamage = dps / 20 // 20 ticks per second
            runBlocking { damageManager.applyDamage(gateId, tickDamage, "continuous-damage") }
        }, 0, 1)
    }
    
    fun stopContinuousDamage(gateId: Int) {
        activeDamage.remove(gateId)
    }
    
    data class ContinuousDamageEffect(
        val gateId: Int,
        val dps: Double,
        val durationTicks: Long,
        val startTime: Long
    ) {
        fun isExpired() = System.currentTimeMillis() - startTime > durationTicks * 50 // 20 ticks/sec
    }
}
```

**Effort**: 2-3 hours

---

### 8.4 Integrate Health System into GateDamageManager

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/gate/GateDamageManager.kt` (update)

**Updates**:
- Use DamageCalculator for damage calculation
- Call HealthDisplayManager for updates
- Trigger ContinuousDamageSystem for fire damage
- Handle gate destruction (HealthCurrent == 0)

**Effort**: 1-2 hours

---

### Phase 8 Summary

- **Total Effort**: 30-40 hours
- **Risk**: Medium (ArmorStand syncing, tick-based calculations)
- **Deliverables**:
  - DamageCalculator
  - HealthDisplayManager (with ArmorStand rendering)
  - ContinuousDamageSystem (DPS tracking)
  - Integration with GateDamageManager

**Testing**: Test damage calculation, verify health displays update, test continuous damage expiry

**Completion Criteria**:
- ✅ Gates take damage correctly
- ✅ Invincible gates ignore damage
- ✅ Health display shows above gate (if enabled)
- ✅ Continuous damage applies per second
- ✅ Gate destruction triggers when HealthCurrent == 0

---

## Phase 9: Siege Integration

### Priority: 🟡 MEDIUM
### Duration: 4-5 days | Effort: 25-35 hours

### 9.1 Integrate Siege Events

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/siege/SiegeGateIntegration.kt` (NEW)

**Responsibilities**:
- Listen for siege start/end events
- Update gate `CurrentSiegeId`
- Handle animation during siege
- Track objectives

**Implementation Sketch**:

```kotlin
class SiegeGateIntegration(
    private val plugin: KnkPlugin,
    private val gateApi: GateStructureApiClient,
    private val animationManager: GateAnimationManager
) : Listener {
    
    @EventHandler
    fun onSiegeStart(event: SiegeStartEvent) {
        val siege = event.siege
        for (gateId in siege.objectiveGateIds) {
            // Update gate in API
            runBlocking {
                gateApi.updateGate(gateId, UpdateGateDto(
                    currentSiegeId = siege.id,
                    isSiegeObjective = true
                ))
            }
        }
    }
    
    @EventHandler
    fun onSiegeEnd(event: SiegeEndEvent) {
        val siege = event.siege
        for (gateId in siege.objectiveGateIds) {
            // Clear siege assignment
            runBlocking {
                gateApi.updateGate(gateId, UpdateGateDto(
                    currentSiegeId = null
                ))
            }
        }
    }
    
    @EventHandler
    fun onGateDamaged(event: GateDamagedEvent) {
        val gate = event.gate
        if (gate.isSiegeObjective && gate.currentSiegeId != null) {
            // Notify siege system
            plugin.logger.info("Gate ${gate.id} (siege objective) damaged during siege")
        }
    }
}
```

**Effort**: 4-5 hours

---

### 9.2 Create Siege-Specific Gate Behaviors

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/siege/SiegeGateBehavior.kt` (NEW)

**Behaviors**:
- Gates animate during siege (if `AnimateDuringSiege` = true)
- Gates can be overridden during siege (if `IsOverridable` = true)
- Health display shows only in SIEGE_ONLY mode during active siege
- Damage multipliers apply to siege damage

**Implementation**:

```kotlin
class SiegeGateBehavior(
    private val gate: GateStructure
) {
    fun canAnimateDuringSiege(): Boolean = gate.animateDuringSiege
    fun canBeOverriddenDuringSiege(): Boolean = gate.isOverridable
    fun shouldShowHealthInSiege(): Boolean = gate.healthDisplayMode == "SIEGE_ONLY"
}
```

**Effort**: 2-3 hours

---

### 9.3 Create Siege Damage Tracker

**File**: `knk-plugin-v2/knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/siege/SiegeDamageTracker.kt` (NEW)

**Responsibilities**:
- Track damage dealt to gates during siege
- Record attacker IDs
- Calculate siege progress
- Notify siege system of objectives completed

**Implementation Sketch**:

```kotlin
class SiegeDamageTracker(
    private val plugin: KnkPlugin
) {
    private val siegeDamage = mutableMapOf<Int, MutableMap<Int, Double>>() // siegeId → gateId → damage
    
    fun recordDamage(siegeId: Int, gateId: Int, damage: Double) {
        siegeDamage.getOrPut(siegeId) { mutableMapOf() }[gateId] = damage
    }
    
    fun getSiegeDamage(siegeId: Int, gateId: Int): Double {
        return siegeDamage[siegeId]?.get(gateId) ?: 0.0
    }
    
    fun getSiegeProgress(siegeId: Int, objectives: List<GateStructure>): Double {
        val totalHealth = objectives.sumOf { it.healthMax }
        val totalDamage = objectives.sumOf { getSiegeDamage(siegeId, it.id) }
        return (totalDamage / totalHealth * 100).toInt().toDouble()
    }
}
```

**Effort**: 2-3 hours

---

### Phase 9 Summary

- **Total Effort**: 25-35 hours
- **Risk**: Medium (siege system integration, event coupling)
- **Deliverables**:
  - SiegeGateIntegration event listeners
  - SiegeGateBehavior logic
  - SiegeDamageTracker for progress reporting

**Testing**: Integration tests with siege system, verify gate behaviors during siege

**Completion Criteria**:
- ✅ Gates are assigned to sieges correctly
- ✅ Animation/override behaviors respect siege configuration
- ✅ Health display shows only in SIEGE_ONLY mode during siege
- ✅ Damage is tracked and reported to siege system
- ✅ Gates clear siege assignment after siege ends

---

## Phase 10: Advanced Features (Pass-Through, Guards)

### Priority: 🟢 LOW (Future)
### Duration: 10-12 days | Effort: 70-100 hours
### Status: Future Sprint

**Scope**: Implementation deferred to future sprint  
**Dependencies**: All prior phases complete

**Sub-phases**:
- 10.A: Pass-Through System (5-6 days)
- 10.B: Guard Spawn System (6-7 days) - *Requires NPC system*

**Summary**: See REQUIREMENTS_GATE_ADVANCED_FEATURES.md for detailed specifications

---

## Implementation Tracking

### Milestone 1: Backend MVP (Phases 1-3)
- **Target Duration**: 2 weeks
- **Deliverables**: Entity, DTOs, Services, Controllers, API endpoints
- **Exit Criteria**: API is functional, all CRUD operations work, can create/edit gates

### Milestone 2: Frontend Core (Phases 2-5)
- **Target Duration**: 3 weeks
- **Deliverables**: FormConfiguration, FormWizard, WorldTask integration
- **Exit Criteria**: Admins can create gates via web UI with full wizard flow

### Milestone 3: Plugin Foundation (Phases 4-6)
- **Target Duration**: 2 weeks
- **Deliverables**: Commands, event handlers, API client
- **Exit Criteria**: Gates can be animated in-game, health/damage works

### Milestone 4: Polish & Testing (Phases 7-9)
- **Target Duration**: 3 weeks
- **Deliverables**: Full animation system, health display, siege integration
- **Exit Criteria**: Complete system works end-to-end

**Total Implementation Timeline**: ~10 weeks (assuming serial phases, 1 per week with buffer)

---

## Risk Assessment & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| **Geometry calculations errors** | High | High | Comprehensive unit tests, reference legacy code, peer review |
| **Animation timing/sync issues** | High | Medium | Test with various tick rates, use NanoTime for precision |
| **Database migration blocker** | High | Low | Test on dev DB first, have rollback plan |
| **Plugin crash on animation** | High | Medium | Extensive error handling, catch exceptions, log to file |
| **WorldTask integration delay** | Medium | Medium | Define clear API contract early, mock in tests |
| **Scope creep (guards, complex pass-through)** | Medium | High | Defer to Phase 10, strict phase boundaries |
| **Frontend performance (3D preview)** | Medium | Medium | Defer 3D preview, use React suspense for loading |
| **Siege system integration complexity** | Medium | Medium | Simple event-based coupling, loosely coupled |

---

## Testing Strategy

### Unit Testing
- Geometry calculations (coordinate parsing, vector math, collinearity checks)
- Damage calculations (multipliers, invincibility, continuous damage)
- Service methods (CRUD, validation)
- State machine transitions

### Integration Testing
- Full CRUD flow (create → read → update → delete gate)
- Animation execution end-to-end
- Health and damage system
- API client endpoints
- WorldTask capture flow

### Manual Testing
- Admin creates gate via web UI
- Gate animates in Minecraft
- Damage application and health display
- Siege integration
- Pass-through system (Phase 10)

### Performance Testing
- Load test with multiple concurrent gates
- Monitor plugin tick rate during animation
- Test with large block snapshots (100+ blocks)

---

## Code Quality Standards

- **Coverage**: Minimum 70% for services, 50% for controllers
- **Documentation**: XML docs on all public methods, README for major classes
- **Logging**: Debug, Info, Warning, Error levels appropriately used
- **Error Handling**: No silent failures; all exceptions logged
- **Naming**: Clear, descriptive names; no abbreviations unless standard
- **Formatting**: Follow project conventions (C# for backend, Kotlin for plugin, TSX for frontend)

---

## Rollout & Deployment

**Dev Environment**: Test all phases on local dev server  
**Staging**: Full system test in staging before prod  
**Production**: Phased rollout (Phase 1-6 for base animation, Phase 7-9 for full features)

**Cutover Plan**:
1. Deploy backend API changes
2. Run EF Core migrations
3. Deploy plugin JAR
4. Update web app
5. Test end-to-end
6. Enable feature flag for gates
7. Monitor for errors

---

## References

- **GATE_REQUIREMENTS_SUMMARY.md**: Feature matrix, field mapping, phases
- **REQUIREMENTS_GATE_ANIMATION.md**: Base animation system specs
- **REQUIREMENTS_GATE_ADVANCED_FEATURES.md**: Advanced features specs
- **REQUIREMENTS_GATE_FRONTEND.md**: Frontend implementation details
- **USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md**: Example format/structure
- **PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md**: Plugin roadmap example
- **FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md**: Frontend roadmap example

---

**Document Status**: Ready for implementation planning  
**Last Updated**: January 31, 2026  
**Maintainers**: Development Team  
**Next Review**: After Phase 1 completion
