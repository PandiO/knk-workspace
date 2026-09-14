# Gate System Requirements - Complete Feature Set Summary

**Date**: January 31, 2026  
**Status**: Comprehensive Requirements Complete

This document summarizes all gate system requirements across base animation and advanced features, serving as a master checklist for implementation.

---

## Document Structure

The gate system requirements are split across multiple documents:

1. **[REQUIREMENTS_GATE_ANIMATION.md](./REQUIREMENTS_GATE_ANIMATION.md)** - Base animation system (CORE)
2. **[REQUIREMENTS_GATE_ADVANCED_FEATURES.md](./REQUIREMENTS_GATE_ADVANCED_FEATURES.md)** - Advanced features discovered from legacy analysis
3. **[SPEC_GATE_ANIMATION.md](./SPEC_GATE_ANIMATION.md)** - Technical specification grounded in architecture

---

## Complete Feature Matrix

### Core Animation System (Base Requirements)

| Feature | Entity Fields | API Endpoints | Plugin Components | Web UI | Priority |
|---------|--------------|---------------|-------------------|--------|----------|
| **Gate Types** | GateType, MotionType | GET/POST/PUT gates | Type-specific animation logic | Type selector wizard | HIGH |
| **Geometry Definition** | GeometryDefinitionMode, AnchorPoint, ReferencePoint1/2, Width/Height/Depth | POST geometry/capture | Geometry calculator, block scanner | 3D preview, coordinate inputs | HIGH |
| **Block Snapshots** | GateBlockSnapshot entity | GET/POST/DELETE snapshots | Snapshot storage, restoration | Snapshot viewer, recapture button | HIGH |
| **Animation Engine** | AnimationDurationTicks, AnimationTickRate | - | Tick task, frame calculator | Duration slider, preview playback | HIGH |
| **Diagonal Support** | FaceDirection | - | Local coordinate system (u,v,n axes) | 8-way compass selector | HIGH |
| **Rotation** | RotationMaxAngleDegrees, HingeAxis | - | Rotation math (Rodrigues formula) | Angle slider | MEDIUM |
| **Double Doors** | LeftDoorSeedBlock, RightDoorSeedBlock, MirrorRotation | - | Dual door animation | Seed block selectors | MEDIUM |
| **Health System** | HealthCurrent, HealthMax, IsDestroyed, CanRespawn, RespawnRateSeconds | PUT health | Damage handlers, respawn timer | Health sliders, respawn config | HIGH |
| **WorldGuard Regions** | RegionClosedId, RegionOpenedId | - | Region sync on state change | Region ID inputs | MEDIUM |
| **Tile Entities** | TileEntityPolicy | - | Snapshot with/without tile entities | Policy dropdown | LOW |
| **Fallback Material** | FallbackMaterialRefId | - | Restoration fallback logic | Material selector | LOW |

### Advanced Features (Extended Requirements)

| Feature | Entity Fields | API Endpoints | Plugin Components | Web UI | Priority |
|---------|--------------|---------------|-------------------|--------|----------|
| **Pass-Through System** | AllowPassThrough, PassThroughDurationSeconds, PassThroughConditionsJson | PUT passthrough, POST passthrough/test | Proximity detector, condition evaluator, auto-open/close timer | Conditions editor, test modal | MEDIUM |
| **Guard Spawn** | GuardSpawnLocationsJson, GuardCount, GuardNpcTemplateId | PUT guards | Guard spawner (future - NPC system) | Guard config panel (placeholder) | LOW (Phase 3) |
| **Health Display** | ShowHealthDisplay, HealthDisplayMode, HealthDisplayYOffset | PUT display | ArmorStand manager, display updater | Display mode dropdown, offset slider | HIGH |
| **Siege Integration** | IsOverridable, AnimateDuringSiege, CurrentSiegeId, IsSiegeObjective | PUT siege, DELETE siege, GET sieges/{id}/gates | Siege event handlers, override commands, damage multipliers | Siege assignment table, live monitor | HIGH (Current Sprint) |
| **Continuous Damage** | AllowContinuousDamage, ContinuousDamageMultiplier, ContinuousDamageDurationSeconds | PUT continuous-damage | ContinuousGateDamage class, fire effects, tick damage | Damage config panel, weapon preview | HIGH |

---

## Entity Field Additions Required

### GateStructure.cs (Current → Extended)

**Current fields (already implemented):**
```csharp
public bool IsActive { get; set; } = false;
public bool CanRespawn { get; set; } = true;
public bool IsDestroyed { get; set; } = false;
public bool IsInvincible { get; set; } = true;
public bool IsOpened { get; set; } = false;
public double HealthCurrent { get; set; } = 500.0;
public double HealthMax { get; set; } = 500.0;
public string FaceDirection { get; set; } = "north";
public int RespawnRateSeconds { get; set; } = 300;
public int? IconMaterialRefId { get; set; }
public MinecraftMaterialRef? IconMaterial { get; set; } = null;
public string RegionClosedId { get; set; } = string.Empty;
public string RegionOpenedId { get; set; } = string.Empty;
```

**Required additions (30+ fields):**

```csharp
// Gate Type & Geometry (CRITICAL)
public string GateType { get; set; } = "SLIDING";
public string GeometryDefinitionMode { get; set; } = "PLANE_GRID";
public string MotionType { get; set; } = "VERTICAL";
public int AnimationDurationTicks { get; set; } = 60;
public int AnimationTickRate { get; set; } = 1;

// PLANE_GRID Geometry
public string AnchorPoint { get; set; } = string.Empty;
public string ReferencePoint1 { get; set; } = string.Empty;
public string ReferencePoint2 { get; set; } = string.Empty;
public int GeometryWidth { get; set; } = 0;
public int GeometryHeight { get; set; } = 0;
public int GeometryDepth { get; set; } = 0;

// FLOOD_FILL Geometry
public string SeedBlocks { get; set; } = string.Empty;
public int ScanMaxBlocks { get; set; } = 500;
public int ScanMaxRadius { get; set; } = 20;
public string ScanMaterialWhitelist { get; set; } = string.Empty;
public string ScanMaterialBlacklist { get; set; } = string.Empty;
public bool ScanPlaneConstraint { get; set; } = false;

// Block Management
public int? FallbackMaterialRefId { get; set; }
public MinecraftMaterialRef? FallbackMaterial { get; set; } = null;
public string TileEntityPolicy { get; set; } = "DECORATIVE_ONLY";

// Rotation (Drawbridge/Doors)
public int RotationMaxAngleDegrees { get; set; } = 90;
public string HingeAxis { get; set; } = string.Empty;

// Double Doors
public string LeftDoorSeedBlock { get; set; } = string.Empty;
public string RightDoorSeedBlock { get; set; } = string.Empty;
public bool MirrorRotation { get; set; } = true;

// Pass-Through System
public bool AllowPassThrough { get; set; } = false;
public int PassThroughDurationSeconds { get; set; } = 4;
public string PassThroughConditionsJson { get; set; } = string.Empty;

// Guard System (Future)
public string GuardSpawnLocationsJson { get; set; } = string.Empty;
public int GuardCount { get; set; } = 0;
public int? GuardNpcTemplateId { get; set; }

// Health Display
public bool ShowHealthDisplay { get; set; } = true;
public string HealthDisplayMode { get; set; } = "ALWAYS";
public int HealthDisplayYOffset { get; set; } = 2;

// Siege Integration
public bool IsOverridable { get; set; } = true;
public bool AnimateDuringSiege { get; set; } = true;
public int? CurrentSiegeId { get; set; }
public Siege? CurrentSiege { get; set; } = null;
public bool IsSiegeObjective { get; set; } = false;

// Continuous Damage
public bool AllowContinuousDamage { get; set; } = true;
public double ContinuousDamageMultiplier { get; set; } = 1.0;
public int ContinuousDamageDurationSeconds { get; set; } = 5;

// Navigation property
public ICollection<GateBlockSnapshot> BlockSnapshots { get; set; } = new List<GateBlockSnapshot>();
```

### New Entity: GateBlockSnapshot

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
    
    public int SortOrder { get; set; }
}
```

---

## Implementation Phases

### Phase 1: Core Animation System (Current Sprint)

**Goal**: Implement base animation system with 4 gate types, geometry definition, and block snapshots.

**Deliverables:**
- [ ] GateStructure entity with animation fields
- [ ] GateBlockSnapshot entity
- [ ] DTOs (Read, Create, Update, Navigation)
- [ ] Repository + Service (with snapshot management)
- [ ] Controller CRUD + snapshot endpoints
- [ ] AutoMapper profiles
- [ ] Web app: Gate wizard (6 steps), list/details views
- [ ] Plugin: Gate loader, animation tick task, frame calculator

**Duration**: 25-32 days (full-time developer)

**Priority Features**:
- Gate types: SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
- Geometry: PLANE_GRID (primary), FLOOD_FILL (secondary)
- Animation: VERTICAL, LATERAL, ROTATION
- Diagonal support (8 directions)
- Health system integration

---

### Phase 2: Advanced Features - Part 1 (Next Sprint)

**Goal**: Add health display, siege integration, continuous damage.

**Deliverables:**
- [ ] Health display system (ArmorStand entity)
- [ ] Siege integration (gate locking, damage rules, override)
- [ ] Continuous damage system (fire effects, damage-over-time)
- [ ] Updated DTOs with new fields
- [ ] Web app: Health display config, siege assignment UI
- [ ] Plugin: Display manager, siege handlers, continuous damage class

**Duration**: 10-15 days

**Priority Features**:
- Health display modes (ALWAYS, DAMAGED_ONLY, SIEGE_ONLY)
- Siege objective vs obstacle mechanics
- Continuous damage from fire weapons
- Animation during siege (configurable)

---

### Phase 3: Advanced Features - Part 2 (Future)

**Goal**: Pass-through system with advanced conditions.

**Deliverables:**
- [ ] Pass-through condition evaluator
- [ ] Player stats integration (XP, ethics, clan, donator rank)
- [ ] Proximity detector + auto-open/close timer
- [ ] Web app: Conditions editor, test modal
- [ ] Plugin: Pass-through handlers

**Duration**: 8-12 days

**Dependencies**:
- Player stats system (XP, ethics)
- Clan system
- Donator rank system

---

### Phase 4: Future Features (TBD)

**Goal**: Guard spawn system (requires full NPC framework).

**Deliverables:**
- [ ] NPC system framework
- [ ] Guard spawn logic
- [ ] Guard AI behaviors (patrol, defend, attack)
- [ ] Web app: Guard configuration UI
- [ ] Plugin: Guard spawner, AI controller

**Duration**: 20-30 days

**Dependencies**:
- NPC entity system
- AI pathfinding framework
- Combat system for NPCs

---

## Migration from Legacy System

### Legacy Gate.java → GateStructure.cs Field Mapping

| Legacy Field | Current Field | Notes |
|--------------|---------------|-------|
| `material` (Itemtype) | `FallbackMaterialRefId` | Single material → fallback only; snapshots store per-block materials |
| `gateBlocksOpened` | `BlockSnapshots` (where IsOpened=true) | ManyToMany → OneToMany GateBlockSnapshot |
| `gateBlocksClosed` | `BlockSnapshots` (where IsOpened=false) | ManyToMany → OneToMany GateBlockSnapshot |
| `faceDirection` | `FaceDirection` | Same (string, 8 directions) |
| `originalHealth` | `HealthMax` | Same |
| `currentHealth` | `HealthCurrent` | Same |
| `gateRegionClosed` | `RegionClosedId` | Same |
| `gateRegionOpen` | `RegionOpenedId` | Same |
| `opened` | `IsOpened` | Same (bool) |
| `guardLocations` | `GuardSpawnLocationsJson` | List<Location> → JSON array |
| `respawnRate` | `RespawnRateSeconds` | Same (int seconds) |
| `invincible` | `IsInvincible` | Same |
| `destroyed` | `IsDestroyed` | Same |
| `active` | `IsActive` | Same |
| `canRespawn` | `CanRespawn` | Same |
| `gateStatsEntity` | N/A (runtime) | ArmorStand managed by plugin (transient) |
| `overridden` | N/A (runtime) | Transient field in plugin cache |
| `gateAnimation` | N/A (runtime) | Plugin animation state (transient) |
| `continuousDamageList` | N/A (runtime) | Plugin damage trackers (transient) |

### Legacy Features NOT Migrated

- Direct Hibernate/JPA persistence (replaced by API-based plugin sync)
- `Creation` system fields (replaced by web app wizard)
- Hardcoded animation (replaced by configurable animation system)

---

## Testing Checklist

### Unit Tests (Backend)

- [ ] GateStructure entity validation
- [ ] GateBlockSnapshot relationship
- [ ] Pass-through condition evaluation
- [ ] Continuous damage calculation
- [ ] Siege damage multipliers
- [ ] Health display text formatting

### Integration Tests (Backend)

- [ ] Gate CRUD operations
- [ ] Snapshot capture/restore
- [ ] Siege gate linking
- [ ] Pass-through test endpoint
- [ ] Cascade delete (gate → snapshots)

### Plugin Tests

- [ ] Gate loader (fetch from API)
- [ ] Animation tick task (all gate types)
- [ ] Frame calculation (VERTICAL, LATERAL, ROTATION)
- [ ] Entity push system
- [ ] Health display creation/update
- [ ] Continuous damage tick
- [ ] Siege event handlers
- [ ] Pass-through proximity detection

### Web App Tests

- [ ] Gate wizard (all 6 steps)
- [ ] 3D preview rendering
- [ ] Geometry validation
- [ ] Conditions editor (pass-through)
- [ ] Live siege monitor
- [ ] Health display preview

### End-to-End Tests

- [ ] Create gate via web app → appears in-game
- [ ] Open/close gate in-game → animates correctly
- [ ] Damage gate → health updates in real-time
- [ ] Siege starts → gates lock
- [ ] Pass-through → auto-open/close
- [ ] Continuous damage → fire effects visible

---

## Known Limitations & Future Work

### v1 Limitations

- No inventory tile entities (chests, furnaces) in gates
- No obstacle detection (JAMMED state future work)
- No dynamic gate creation in-game (admin must use web app)
- No gate sound customization (fixed sounds)
- Guard spawn system placeholder only (requires NPC framework)

### v2+ Planned Features

- Dynamic gate creation tool (in-game WorldEdit-style)
- Advanced collision detection (prevent crushing players)
- Custom sound packs per gate
- Fire resistance based on block materials
- Repair kits for defenders (instant heal during siege)
- Toll system for pass-through (cost gold/items to use)
- Gate network system (linked gates, portcullis chains)

---

## Summary

**Total Entity Fields**: 47 (current 13 + required 34)  
**New Entities**: 1 (GateBlockSnapshot)  
**API Endpoints**: ~20 (CRUD + snapshots + passthrough + siege + display + damage)  
**Plugin Classes**: ~15 (loader, manager, animation, damage, display, siege, commands)  
**Web App Components**: ~25 (wizard, forms, lists, details, preview, monitors)

**Estimated Effort**: 50-65 developer days (animation + advanced features combined)

**Current Status**:
- ✅ Base entity defined (GateStructure.cs - 13 fields)
- ❌ Animation fields missing (34 fields to add)
- ❌ GateBlockSnapshot entity missing
- ❌ DTOs not created
- ❌ Repository/Service not created
- ❌ Controller not created
- ❌ Web app UI not created
- ❌ Plugin implementation not started

**Next Immediate Steps**:
1. Update GateStructure.cs with animation fields (see field list above)
2. Create GateBlockSnapshot.cs entity
3. Follow entity scaffold checklist (docs/ai/ENTITY_SCAFFOLD_CHECKLIST.md)
4. Begin Phase 1 implementation (core animation system)

---

**Document maintained by**: AI Agent  
**Last updated**: January 31, 2026  
**Review status**: Ready for stakeholder review
