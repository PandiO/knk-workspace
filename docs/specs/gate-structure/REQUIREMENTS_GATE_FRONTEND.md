# REQUIREMENTS: Gate Structure Frontend (FormWizard & WorldTasks)

**Status**: Draft - Frontend implementation requirements  
**Created**: January 31, 2026  
**Parent Documents**: 
- REQUIREMENTS_GATE_ANIMATION.md
- REQUIREMENTS_GATE_ADVANCED_FEATURES.md

This document specifies frontend implementation requirements for GateStructure entity creation and editing through the FormConfiguration/FormWizard system with WorldTask integration.

---

## Overview

GateStructure entities require extensive Minecraft world data capture during creation and editing. The frontend must provide admin-friendly workflows that seamlessly integrate in-game data collection through WorldTasks while maintaining data integrity and providing clear visual feedback.

**Key Challenges**:
- 40+ entity fields (many requiring in-game data capture)
- Complex geometry definition (3D coordinates, regions, seed blocks)
- Multi-step wizard with conditional logic
- Real-time validation of Minecraft world data
- Visual preview of gate configuration (3D rendering)

**Solution Components**:
1. **FormConfigBuilder**: Configure gate creation/edit forms with WorldTask field bindings
2. **FormWizard**: Multi-step wizard for gate creation/editing with embedded WorldTask launchers
3. **WorldBoundFieldRenderer**: UI component for capturing Minecraft world data
4. **TaskStatusMonitor**: Real-time feedback on WorldTask execution
5. **3D Preview Widget**: Visual representation of gate geometry (future enhancement)

---

## Part A: FormConfiguration Design for GateStructure

### Recommended Wizard Structure (6 Steps)

**Step 1: Basic Information**
- **Title**: "Gate Basic Info"
- **Description**: "Define the gate name, location, and parent domain/district/street"
- **Fields**:
  - `Name` (string, required, 3-50 chars)
  - `DomainId` (int, required, dropdown - existing domains)
  - `DistrictId` (int, required, dropdown - filtered by DomainId)
  - `StreetId` (int, optional, dropdown - filtered by DistrictId)
  - `IconMaterialRefId` (int, optional, searchable dropdown - Minecraft materials)

**Step 2: Gate Type & Orientation**
- **Title**: "Gate Type & Configuration"
- **Description**: "Select the gate type and orientation (determines animation behavior)"
- **Fields**:
  - `GateType` (enum, required, radio buttons: SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS)
    - Conditional help text per type
  - `MotionType` (enum, required, dropdown: VERTICAL, LATERAL, ROTATION)
    - Auto-populated based on GateType (can override)
  - `FaceDirection` (enum, required, 8-way compass selector: north, north-east, east, south-east, south, south-west, west, north-west)
    - Visual compass widget
  - `AnimationDurationTicks` (int, default 60, range 20-200)
    - With helper: "Duration in ticks (20 ticks = 1 second)"
  - `AnimationTickRate` (int, default 1, range 1-5)
    - Helper: "Frames per tick (1 = smoothest, 5 = choppiest)"

**Step 3: Geometry Definition**
- **Title**: "Gate Geometry"
- **Description**: "Define which blocks make up the gate using PLANE_GRID or FLOOD_FILL mode"
- **Conditional Fields** (based on `GateType`):

  **If PLANE_GRID mode** (default for SLIDING, TRAP, DRAWBRIDGE):
  - `GeometryDefinitionMode` (hidden, auto-set to "PLANE_GRID")
  - **`AnchorPoint` (JSON string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_LOCATION`
    - **In-Game Action**: Player clicks block in Minecraft → captures {x, y, z}
    - **Display**: Shows coordinates after capture, button to re-capture
    - **Validation**: Must be valid world coordinates
  - **`ReferencePoint1` (JSON string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_LOCATION`
    - **In-Game Action**: Player clicks second block (defines hinge line)
    - **Display**: Shows coordinates + calculated distance from AnchorPoint
  - **`ReferencePoint2` (JSON string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_LOCATION`
    - **In-Game Action**: Player clicks third block (defines forward direction)
    - **Validation**: Cannot be collinear with AnchorPoint and ReferencePoint1
  - `GeometryWidth` (int, required, range 1-50)
    - Auto-calculated from AnchorPoint → ReferencePoint1 distance (can override)
  - `GeometryHeight` (int, required, range 1-50)
    - Manual input or auto-detect from region
  - `GeometryDepth` (int, required, range 1-10)
    - Default 1 for flat gates, increase for thick gates

  **If FLOOD_FILL mode** (default for DOUBLE_DOORS, optional for others):
  - `GeometryDefinitionMode` (hidden, auto-set to "FLOOD_FILL")
  - **`SeedBlocks` (JSON array, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_MULTIPLE_LOCATIONS`
    - **In-Game Action**: Player clicks multiple blocks → builds array [{x,y,z}, ...]
    - **Display**: List of captured coordinates, add/remove buttons
    - **For DOUBLE_DOORS**: Two seed blocks required (left door, right door)
  - `ScanMaxBlocks` (int, default 500, range 50-2000)
  - `ScanMaxRadius` (int, default 20, range 5-50)
  - `ScanMaterialWhitelist` (JSON array, optional, multi-select dropdown - Minecraft materials)
  - `ScanMaterialBlacklist` (JSON array, optional, multi-select dropdown - Minecraft materials)
  - `ScanPlaneConstraint` (bool, default false, checkbox)

**Step 4: WorldGuard Regions & Animation**
- **Title**: "Regions & Animation Settings"
- **Description**: "Define WorldGuard regions for gate states and advanced animation settings"
- **Fields**:
  - **`RegionClosedId` (string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `SELECT_WORLDGUARD_REGION` or `CREATE_WORLDGUARD_REGION`
    - **In-Game Action**: 
      - Option A: Player selects from list of existing regions in current world
      - Option B: Player uses WorldEdit to define region → creates new region
    - **Display**: Shows region name + bounds preview
    - **Validation**: Region must exist, must not overlap with other gates
  - **`RegionOpenedId` (string, required, WorldTask)** ⚙️
    - Same as RegionClosedId
    - **Validation**: Must be different from RegionClosedId
  - `FallbackMaterialRefId` (int, optional, searchable dropdown - Minecraft materials)
  - `TileEntityPolicy` (enum, default "DECORATIVE_ONLY", dropdown: NONE, DECORATIVE_ONLY, ALL)
  
  **If MotionType = ROTATION**:
  - `RotationMaxAngleDegrees` (int, default 90, range 0-180)
  - **`HingeAxis` (JSON string, auto-calculated from AnchorPoint → ReferencePoint1)** (read-only, info display)

  **If GateType = DOUBLE_DOORS**:
  - **`LeftDoorSeedBlock` (JSON string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_LOCATION`
  - **`RightDoorSeedBlock` (JSON string, required, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_LOCATION`
  - `MirrorRotation` (bool, default true, checkbox)

**Step 5: Health, Display & Combat**
- **Title**: "Health & Combat Settings"
- **Description**: "Configure gate health, damage, respawn, and health display"
- **Fields**:
  - `HealthMax` (double, default 500, range 1-10000)
  - `HealthCurrent` (double, auto-set to HealthMax on creation, range 0-HealthMax)
  - `IsInvincible` (bool, default true, checkbox)
  - `CanRespawn` (bool, default true, checkbox)
  - `RespawnRateSeconds` (int, default 300, range 10-3600)
    - Helper: "Time until gate auto-repairs after destruction (seconds)"
  - `AllowContinuousDamage` (bool, default true, checkbox)
  - `ContinuousDamageMultiplier` (double, default 1.0, range 0.1-5.0)
  - `ContinuousDamageDurationSeconds` (int, default 5, range 1-30)
  - `ShowHealthDisplay` (bool, default true, checkbox)
  - `HealthDisplayMode` (enum, default "ALWAYS", dropdown: ALWAYS, DAMAGED_ONLY, NEVER, SIEGE_ONLY)
  - `HealthDisplayYOffset` (int, default 2, range -5 to 20)

**Step 6: Advanced Features (Pass-Through, Guards, Siege)**
- **Title**: "Advanced Features"
- **Description**: "Configure pass-through, guard spawn, and siege integration (optional)"
- **Fields**:
  
  **Pass-Through System**:
  - `AllowPassThrough` (bool, default false, checkbox)
  - `PassThroughDurationSeconds` (int, default 4, range 1-30, conditional: shown only if AllowPassThrough = true)
  - `PassThroughConditionsJson` (JSON string, optional, custom JSON editor - see schema below)
  
  **Guard System** (Future):
  - **`GuardSpawnLocationsJson` (JSON array, optional, WorldTask)** ⚙️
    - **WorldTask Type**: `CAPTURE_MULTIPLE_LOCATIONS_WITH_ROTATION`
    - **In-Game Action**: Player clicks blocks → captures [{x, y, z, yaw, pitch}, ...]
    - **Display**: List of spawn points with facing direction indicators
  - `GuardCount` (int, default 0, range 0-10)
  - `GuardNpcTemplateId` (int, optional, dropdown - NPC templates, future)
  
  **Siege Integration**:
  - `IsSiegeObjective` (bool, default false, checkbox)
  - `IsOverridable` (bool, default true, checkbox)
  - `AnimateDuringSiege` (bool, default true, checkbox)
  
  **Activation**:
  - `IsActive` (bool, default false, checkbox)
    - **Warning**: "Gate will not function in-game until activated"

---

## Part B: WorldTask Field Configuration

### WorldTask-Enabled Fields

The following GateStructure fields require WorldTask integration for Minecraft world data capture:

| Field Name | WorldTask Type | Priority | In-Game Action Description |
|------------|----------------|----------|----------------------------|
| `AnchorPoint` | `CAPTURE_LOCATION` | CRITICAL | Player clicks block → captures {x, y, z} as JSON string |
| `ReferencePoint1` | `CAPTURE_LOCATION` | CRITICAL | Player clicks block → captures {x, y, z} as JSON string |
| `ReferencePoint2` | `CAPTURE_LOCATION` | CRITICAL | Player clicks block → captures {x, y, z} as JSON string |
| `SeedBlocks` | `CAPTURE_MULTIPLE_LOCATIONS` | HIGH | Player clicks multiple blocks → captures array [{x,y,z},...] |
| `RegionClosedId` | `SELECT_WORLDGUARD_REGION` or `CREATE_WORLDGUARD_REGION` | CRITICAL | Player selects/creates WG region → captures region ID |
| `RegionOpenedId` | `SELECT_WORLDGUARD_REGION` or `CREATE_WORLDGUARD_REGION` | CRITICAL | Player selects/creates WG region → captures region ID |
| `LeftDoorSeedBlock` | `CAPTURE_LOCATION` | MEDIUM | Player clicks block → captures {x, y, z} as JSON string |
| `RightDoorSeedBlock` | `CAPTURE_LOCATION` | MEDIUM | Player clicks block → captures {x, y, z} as JSON string |
| `GuardSpawnLocationsJson` | `CAPTURE_MULTIPLE_LOCATIONS_WITH_ROTATION` | LOW (Future) | Player clicks blocks + sets facing → captures [{x,y,z,yaw,pitch},...] |

### WorldTask Type Definitions

**CAPTURE_LOCATION**
```typescript
{
  taskType: "CAPTURE_LOCATION",
  inputJson: JSON.stringify({
    fieldName: "AnchorPoint",
    fieldLabel: "Anchor Point (Gate Hinge Left/Top-Left)",
    instructions: "Click the block at the bottom-left hinge of the gate"
  }),
  outputJson: JSON.stringify({
    x: 100,
    y: 64,
    z: 200
  })
}
```

**CAPTURE_MULTIPLE_LOCATIONS**
```typescript
{
  taskType: "CAPTURE_MULTIPLE_LOCATIONS",
  inputJson: JSON.stringify({
    fieldName: "SeedBlocks",
    fieldLabel: "Seed Blocks for Flood Fill",
    instructions: "Click all blocks to include in flood fill scan. Right-click to finish.",
    minBlocks: 1,
    maxBlocks: 10
  }),
  outputJson: JSON.stringify([
    { x: 100, y: 64, z: 200 },
    { x: 105, y: 64, z: 200 }
  ])
}
```

**SELECT_WORLDGUARD_REGION**
```typescript
{
  taskType: "SELECT_WORLDGUARD_REGION",
  inputJson: JSON.stringify({
    fieldName: "RegionClosedId",
    fieldLabel: "WorldGuard Region (Closed State)",
    instructions: "Select the region that defines the closed gate area",
    worldName: "world"
  }),
  outputJson: JSON.stringify({
    regionId: "castle_main_gate_closed",
    bounds: {
      min: { x: 100, y: 64, z: 200 },
      max: { x: 110, y: 72, z: 205 }
    }
  })
}
```

**CREATE_WORLDGUARD_REGION**
```typescript
{
  taskType: "CREATE_WORLDGUARD_REGION",
  inputJson: JSON.stringify({
    fieldName: "RegionClosedId",
    fieldLabel: "WorldGuard Region (Closed State)",
    instructions: "Use WorldEdit to select region, then type region name in chat",
    suggestedName: "gate_{gateName}_closed",
    priority: 12
  }),
  outputJson: JSON.stringify({
    regionId: "castle_main_gate_closed",
    bounds: {
      min: { x: 100, y: 64, z: 200 },
      max: { x: 110, y: 72, z: 205 }
    }
  })
}
```

**CAPTURE_MULTIPLE_LOCATIONS_WITH_ROTATION**
```typescript
{
  taskType: "CAPTURE_MULTIPLE_LOCATIONS_WITH_ROTATION",
  inputJson: JSON.stringify({
    fieldName: "GuardSpawnLocationsJson",
    fieldLabel: "Guard Spawn Locations",
    instructions: "Stand at spawn location facing desired direction, then click block. Right-click to finish.",
    minLocations: 1,
    maxLocations: 10
  }),
  outputJson: JSON.stringify([
    { x: 100, y: 64, z: 200, yaw: 180.0, pitch: 0.0 },
    { x: 105, y: 64, z: 200, yaw: 0.0, pitch: 0.0 }
  ])
}
```

---

## Part C: FormWizard Integration

### WorldBoundFieldRenderer Enhancements

**Current Implementation** (from WorldBoundFieldRenderer.tsx):
- Supports select existing vs create new
- Creates WorldTask on button click
- Monitors task status via TaskStatusMonitor
- Populates field value on task completion

**Required Enhancements for GateStructure**:

1. **Coordinate Display & Validation**
   - Display captured coordinates in human-readable format
   - Show calculated distance between points (e.g., AnchorPoint → ReferencePoint1)
   - Validate non-collinearity (for ReferencePoint2)
   - Button to re-capture if coordinates are invalid

2. **Visual Feedback**
   - Show 3D preview of captured geometry (future enhancement)
   - Highlight captured blocks in-game (plugin feature)
   - Display calculated gate dimensions (width, height, depth)

3. **Multi-Step Coordination**
   - Ensure sequential capture (AnchorPoint → ReferencePoint1 → ReferencePoint2)
   - Pre-fill subsequent fields based on captured data
   - Auto-calculate HingeAxis from AnchorPoint + ReferencePoint1

4. **WorldGuard Region Integration**
   - Fetch existing regions from plugin via API
   - Display region bounds preview (min/max coordinates)
   - Validate region does not overlap with existing gates

### FormWizard Step Logic

**Step 3 (Geometry Definition) - Conditional Rendering**:

```typescript
// FormWizard.tsx - renderField function
const renderField = (field: FormFieldDto) => {
  // Check if field requires WorldTask
  if (field.worldTaskSettings?.enabled) {
    const settings = parseWorldTaskSettings(field.worldTaskSettings);
    
    return (
      <WorldBoundFieldRenderer
        fieldName={field.fieldName}
        fieldLabel={field.label}
        workflowSessionId={workflowSessionId}
        stepNumber={currentStepIndex}
        taskType={settings.taskType}
        value={currentStepData[field.fieldName]}
        onChange={(value) => handleFieldChange(field.fieldName, value)}
        allowExisting={settings.allowExisting ?? true}
        allowCreate={settings.allowCreate ?? true}
        existingOptions={settings.existingOptions || []}
      />
    );
  }
  
  // Standard field rendering
  return <StandardFieldRenderer field={field} />;
};
```

**Step Validation with WorldTask Data**:

```typescript
// FormWizard.tsx - validateStep function
const validateStep = (): boolean => {
  const newErrors: { [fieldName: string]: string } = {};
  
  orderedFields.forEach(field => {
    const value = currentStepData[field.fieldName];
    
    // WorldTask field validation
    if (field.worldTaskSettings?.enabled) {
      if (field.isRequired && !value) {
        newErrors[field.fieldName] = `${field.label} must be captured in-game`;
        return;
      }
      
      // Validate JSON structure for coordinate fields
      if (field.fieldName.includes('Point') || field.fieldName.includes('SeedBlocks')) {
        try {
          const parsed = JSON.parse(value);
          if (!validateCoordinates(parsed)) {
            newErrors[field.fieldName] = `Invalid coordinates format`;
          }
        } catch {
          newErrors[field.fieldName] = `Invalid JSON format for coordinates`;
        }
      }
    }
    
    // Standard field validation
    // ...
  });
  
  return Object.keys(newErrors).length === 0;
};

const validateCoordinates = (coords: any): boolean => {
  // Single coordinate: {x, y, z}
  if (coords.x !== undefined && coords.y !== undefined && coords.z !== undefined) {
    return Number.isFinite(coords.x) && Number.isFinite(coords.y) && Number.isFinite(coords.z);
  }
  
  // Array of coordinates: [{x, y, z}, ...]
  if (Array.isArray(coords)) {
    return coords.every(c => validateCoordinates(c));
  }
  
  return false;
};
```

**Auto-Calculation Logic**:

```typescript
// FormWizard.tsx - handleFieldChange function (enhanced)
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
      
      // Calculate HingeAxis from AnchorPoint → ReferencePoint1
      if (fieldName === 'ReferencePoint1' && updated.AnchorPoint) {
        try {
          const p0 = JSON.parse(updated.AnchorPoint as string);
          const p1 = JSON.parse(value as string);
          const axis = {
            x: p1.x - p0.x,
            y: p1.y - p0.y,
            z: p1.z - p0.z
          };
          // Normalize
          const length = Math.sqrt(axis.x ** 2 + axis.y ** 2 + axis.z ** 2);
          const normalized = {
            x: axis.x / length,
            y: axis.y / length,
            z: axis.z / length
          };
          updated.HingeAxis = JSON.stringify(normalized);
        } catch {}
      }
      
      // Auto-populate HealthCurrent when HealthMax changes (on creation only)
      if (fieldName === 'HealthMax' && !entityId) {
        updated.HealthCurrent = value;
      }
    }
    
    return updated;
  });
  
  // Clear error
  if (errors[fieldName]) {
    setErrors(prev => {
      const updated = { ...prev };
      delete updated[fieldName];
      return updated;
    });
  }
};
```

---

## Part D: Pass-Through Conditions JSON Editor

### Custom Editor Component

**PassThroughConditionsEditor.tsx** (new component):

```typescript
interface PassThroughCondition {
  minExperience?: number;
  requiredClanId?: number;
  minEthicsLevel?: number;
  requiredDonatorRank?: number;
  requiredPermissions?: string[];
  allowedUserIds?: number[];
  deniedUserIds?: number[];
}

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
      <div className="form-group">
        <label>Minimum Experience</label>
        <input
          type="number"
          value={conditions.minExperience || ''}
          onChange={e => handleChange('minExperience', parseInt(e.target.value))}
          placeholder="Leave empty to disable"
        />
      </div>
      
      <div className="form-group">
        <label>Required Clan ID</label>
        <input
          type="number"
          value={conditions.requiredClanId || ''}
          onChange={e => handleChange('requiredClanId', parseInt(e.target.value))}
          placeholder="Leave empty to allow any clan"
        />
      </div>
      
      <div className="form-group">
        <label>Minimum Ethics Level (0-5)</label>
        <input
          type="number"
          min="0"
          max="5"
          value={conditions.minEthicsLevel || ''}
          onChange={e => handleChange('minEthicsLevel', parseInt(e.target.value))}
        />
      </div>
      
      <div className="form-group">
        <label>Required Donator Rank (0=none, 1=bronze, 2=silver, 3=gold, 4=platinum)</label>
        <select
          value={conditions.requiredDonatorRank || 0}
          onChange={e => handleChange('requiredDonatorRank', parseInt(e.target.value))}
        >
          <option value="0">None (Free players allowed)</option>
          <option value="1">Bronze or higher</option>
          <option value="2">Silver or higher</option>
          <option value="3">Gold or higher</option>
          <option value="4">Platinum only</option>
        </select>
      </div>
      
      <div className="form-group">
        <label>Required Permissions (comma-separated)</label>
        <input
          type="text"
          value={conditions.requiredPermissions?.join(', ') || ''}
          onChange={e => handleChange('requiredPermissions', e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
          placeholder="e.g., knk.gate.vip, knk.gate.passthrough.castle_gate"
        />
      </div>
      
      <div className="form-group">
        <label>Allowed User IDs (whitelist, comma-separated)</label>
        <input
          type="text"
          value={conditions.allowedUserIds?.join(', ') || ''}
          onChange={e => handleChange('allowedUserIds', e.target.value.split(',').map(s => parseInt(s.trim())).filter(n => !isNaN(n)))}
          placeholder="e.g., 1, 2, 3"
        />
      </div>
      
      <div className="form-group">
        <label>Denied User IDs (blacklist, comma-separated)</label>
        <input
          type="text"
          value={conditions.deniedUserIds?.join(', ') || ''}
          onChange={e => handleChange('deniedUserIds', e.target.value.split(',').map(s => parseInt(s.trim())).filter(n => !isNaN(n)))}
          placeholder="e.g., 99, 100"
        />
      </div>
    </div>
  );
};
```

**Integration in FormWizard**:

```typescript
// FormWizard.tsx - renderField function (enhanced)
const renderField = (field: FormFieldDto) => {
  // Custom editor for PassThroughConditionsJson
  if (field.fieldName === 'PassThroughConditionsJson') {
    return (
      <PassThroughConditionsEditor
        value={currentStepData[field.fieldName] as string || ''}
        onChange={value => handleFieldChange(field.fieldName, value)}
      />
    );
  }
  
  // ... rest of rendering logic
};
```

---

## Part E: 3D Preview Widget (Future Enhancement)

### Requirements

**Purpose**: Visual representation of gate geometry before saving, helping admins verify configuration.

**Technologies**:
- Three.js for 3D rendering
- React Three Fiber (react-three-fiber) for React integration
- OrbitControls for camera manipulation

**Features**:
1. **Geometry Visualization**:
   - Render gate blocks in 3D space
   - Color-code by gate state (closed = red, open = green)
   - Show anchor point, reference points (highlighted spheres)
   - Display hinge axis line (for rotation gates)

2. **Animation Preview**:
   - Play button to preview gate animation
   - Slider to scrub through animation frames
   - Speed control (1x, 2x, 4x)

3. **Camera Controls**:
   - Orbit camera (drag to rotate)
   - Zoom (scroll)
   - Pan (right-click drag)
   - Reset camera button

**Component Structure**:

```typescript
// GatePreview3D.tsx (new component)
import { Canvas } from '@react-three/fiber';
import { OrbitControls, Grid } from '@react-three/drei';

interface GatePreview3DProps {
  anchorPoint: { x: number; y: number; z: number };
  referencePoint1: { x: number; y: number; z: number };
  referencePoint2: { x: number; y: number; z: number };
  geometryWidth: number;
  geometryHeight: number;
  geometryDepth: number;
  gateType: string;
  motionType: string;
  blockSnapshots?: Array<{ relativeX: number; relativeY: number; relativeZ: number }>;
}

export const GatePreview3D: React.FC<GatePreview3DProps> = ({
  anchorPoint,
  referencePoint1,
  referencePoint2,
  geometryWidth,
  geometryHeight,
  geometryDepth,
  gateType,
  motionType,
  blockSnapshots
}) => {
  // Calculate local coordinate system (u, v, n axes)
  const calculateAxes = () => {
    const u = normalize(subtract(referencePoint1, anchorPoint));
    const forward = normalize(subtract(referencePoint2, anchorPoint));
    const n = normalize(cross(u, forward));
    const v = normalize(cross(n, u));
    return { u, v, n };
  };
  
  // Generate block positions
  const generateBlocks = () => {
    const blocks: { x: number; y: number; z: number }[] = [];
    const { u, v, n } = calculateAxes();
    
    for (let h = 0; h < geometryHeight; h++) {
      for (let w = 0; w < geometryWidth; w++) {
        for (let d = 0; d < geometryDepth; d++) {
          const pos = add(
            anchorPoint,
            scale(u, w),
            scale(n, h),
            scale(v, d)
          );
          blocks.push(pos);
        }
      }
    }
    
    return blocks;
  };
  
  return (
    <Canvas camera={{ position: [10, 10, 10], fov: 50 }}>
      <ambientLight intensity={0.5} />
      <directionalLight position={[10, 10, 5]} />
      <Grid args={[100, 100]} />
      
      {/* Render anchor point */}
      <mesh position={[anchorPoint.x, anchorPoint.y, anchorPoint.z]}>
        <sphereGeometry args={[0.3, 16, 16]} />
        <meshStandardMaterial color="blue" />
      </mesh>
      
      {/* Render reference points */}
      <mesh position={[referencePoint1.x, referencePoint1.y, referencePoint1.z]}>
        <sphereGeometry args={[0.3, 16, 16]} />
        <meshStandardMaterial color="green" />
      </mesh>
      
      <mesh position={[referencePoint2.x, referencePoint2.y, referencePoint2.z]}>
        <sphereGeometry args={[0.3, 16, 16]} />
        <meshStandardMaterial color="yellow" />
      </mesh>
      
      {/* Render gate blocks */}
      {generateBlocks().map((block, idx) => (
        <mesh key={idx} position={[block.x, block.y, block.z]}>
          <boxGeometry args={[0.9, 0.9, 0.9]} />
          <meshStandardMaterial color="gray" wireframe />
        </mesh>
      ))}
      
      <OrbitControls />
    </Canvas>
  );
};
```

**Integration in FormWizard (Step 3)**:

```typescript
// FormWizard.tsx - Step 3 rendering
{currentStepIndex === 2 && (
  <div className="gate-preview-panel">
    <h3>Gate Preview</h3>
    {currentStepData.AnchorPoint && 
     currentStepData.ReferencePoint1 && 
     currentStepData.ReferencePoint2 ? (
      <GatePreview3D
        anchorPoint={JSON.parse(currentStepData.AnchorPoint)}
        referencePoint1={JSON.parse(currentStepData.ReferencePoint1)}
        referencePoint2={JSON.parse(currentStepData.ReferencePoint2)}
        geometryWidth={currentStepData.GeometryWidth || 5}
        geometryHeight={currentStepData.GeometryHeight || 8}
        geometryDepth={currentStepData.GeometryDepth || 1}
        gateType={currentStepData.GateType || 'SLIDING'}
        motionType={currentStepData.MotionType || 'VERTICAL'}
      />
    ) : (
      <div className="alert alert-info">
        Capture all three reference points to see preview
      </div>
    )}
  </div>
)}
```

---

## Part F: FormConfiguration Builder Setup

### Configuring WorldTask Fields in FormConfigBuilder

**FieldEditor.tsx Enhancements**:

```typescript
// FieldEditor.tsx - Add WorldTask settings section
const [worldTaskSettings, setWorldTaskSettings] = useState<{
  enabled: boolean;
  taskType: string;
  allowExisting: boolean;
  allowCreate: boolean;
  instructions: string;
}>({
  enabled: false,
  taskType: '',
  allowExisting: true,
  allowCreate: true,
  instructions: ''
});

// Render WorldTask settings section
<div className="form-section">
  <h4>WorldTask Settings</h4>
  
  <div className="form-group">
    <label>
      <input
        type="checkbox"
        checked={worldTaskSettings.enabled}
        onChange={e => setWorldTaskSettings(prev => ({ 
          ...prev, 
          enabled: e.target.checked 
        }))}
      />
      Enable WorldTask for this field
    </label>
  </div>
  
  {worldTaskSettings.enabled && (
    <>
      <div className="form-group">
        <label>Task Type</label>
        <select
          value={worldTaskSettings.taskType}
          onChange={e => setWorldTaskSettings(prev => ({ 
            ...prev, 
            taskType: e.target.value 
          }))}
        >
          <option value="">Select task type...</option>
          <option value="CAPTURE_LOCATION">Capture Single Location</option>
          <option value="CAPTURE_MULTIPLE_LOCATIONS">Capture Multiple Locations</option>
          <option value="SELECT_WORLDGUARD_REGION">Select WorldGuard Region</option>
          <option value="CREATE_WORLDGUARD_REGION">Create WorldGuard Region</option>
          <option value="CAPTURE_MULTIPLE_LOCATIONS_WITH_ROTATION">Capture Locations with Rotation</option>
        </select>
      </div>
      
      <div className="form-group">
        <label>In-Game Instructions</label>
        <textarea
          value={worldTaskSettings.instructions}
          onChange={e => setWorldTaskSettings(prev => ({ 
            ...prev, 
            instructions: e.target.value 
          }))}
          placeholder="Instructions shown to player in Minecraft"
          rows={3}
        />
      </div>
      
      <div className="form-group">
        <label>
          <input
            type="checkbox"
            checked={worldTaskSettings.allowExisting}
            onChange={e => setWorldTaskSettings(prev => ({ 
              ...prev, 
              allowExisting: e.target.checked 
            }))}
          />
          Allow selecting existing (if applicable)
        </label>
      </div>
      
      <div className="form-group">
        <label>
          <input
            type="checkbox"
            checked={worldTaskSettings.allowCreate}
            onChange={e => setWorldTaskSettings(prev => ({ 
              ...prev, 
              allowCreate: e.target.checked 
            }))}
          />
          Allow creating new via WorldTask
        </label>
      </div>
    </>
  )}
</div>

// Save worldTaskSettings to field.worldTaskSettings (JSON string)
const saveField = () => {
  const updatedField: FormFieldDto = {
    ...field,
    worldTaskSettings: worldTaskSettings.enabled 
      ? JSON.stringify(worldTaskSettings) 
      : undefined
  };
  onUpdate(updatedField);
};
```

### Pre-configured GateStructure FormConfiguration Template

**Admin Tool**: "Create from Template" button in FormConfigBuilder

**Template**: GateStructure Default Configuration

```json
{
  "entityTypeName": "GateStructure",
  "configurationName": "Gate Creation Wizard (Default)",
  "description": "Standard 6-step wizard for creating animated gates with WorldTask integration",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "basic-info",
      "title": "Gate Basic Info",
      "description": "Define the gate name, location, and parent domain/district/street",
      "order": 0,
      "fields": [
        {
          "fieldName": "Name",
          "label": "Gate Name",
          "dataType": "string",
          "isRequired": true,
          "order": 0,
          "validations": [
            { "type": "minLength", "value": "3", "errorMessage": "Gate name must be at least 3 characters" },
            { "type": "maxLength", "value": "50", "errorMessage": "Gate name cannot exceed 50 characters" }
          ]
        },
        {
          "fieldName": "DomainId",
          "label": "Domain",
          "dataType": "int",
          "inputType": "dropdown",
          "isRequired": true,
          "order": 1,
          "optionsSourceEntity": "Domain"
        },
        {
          "fieldName": "DistrictId",
          "label": "District",
          "dataType": "int",
          "inputType": "dropdown",
          "isRequired": true,
          "order": 2,
          "optionsSourceEntity": "District",
          "dependsOn": "DomainId"
        },
        {
          "fieldName": "StreetId",
          "label": "Street (Optional)",
          "dataType": "int",
          "inputType": "dropdown",
          "isRequired": false,
          "order": 3,
          "optionsSourceEntity": "Street",
          "dependsOn": "DistrictId"
        },
        {
          "fieldName": "IconMaterialRefId",
          "label": "Icon Material",
          "dataType": "int",
          "inputType": "searchable-dropdown",
          "isRequired": false,
          "order": 4,
          "optionsSourceEntity": "MinecraftMaterialRef"
        }
      ]
    },
    {
      "stepName": "gate-type",
      "title": "Gate Type & Configuration",
      "description": "Select the gate type and orientation",
      "order": 1,
      "fields": [
        {
          "fieldName": "GateType",
          "label": "Gate Type",
          "dataType": "string",
          "inputType": "radio",
          "isRequired": true,
          "order": 0,
          "options": [
            { "value": "SLIDING", "label": "Sliding (Portcullis/Wall)", "description": "Vertical or lateral lift gate" },
            { "value": "TRAP", "label": "Trap Door", "description": "Vertical drop or lift" },
            { "value": "DRAWBRIDGE", "label": "Drawbridge", "description": "Rotation around hinge line" },
            { "value": "DOUBLE_DOORS", "label": "Double Doors", "description": "Two mirrored door leaves" }
          ]
        },
        {
          "fieldName": "MotionType",
          "label": "Motion Type",
          "dataType": "string",
          "inputType": "dropdown",
          "isRequired": true,
          "order": 1,
          "options": [
            { "value": "VERTICAL", "label": "Vertical (Up/Down)" },
            { "value": "LATERAL", "label": "Lateral (Side to Side)" },
            { "value": "ROTATION", "label": "Rotation (Hinge)" }
          ]
        },
        {
          "fieldName": "FaceDirection",
          "label": "Face Direction",
          "dataType": "string",
          "inputType": "compass-selector",
          "isRequired": true,
          "order": 2,
          "options": [
            { "value": "north", "label": "North" },
            { "value": "north-east", "label": "North-East" },
            { "value": "east", "label": "East" },
            { "value": "south-east", "label": "South-East" },
            { "value": "south", "label": "South" },
            { "value": "south-west", "label": "South-West" },
            { "value": "west", "label": "West" },
            { "value": "north-west", "label": "North-West" }
          ]
        },
        {
          "fieldName": "AnimationDurationTicks",
          "label": "Animation Duration (ticks)",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 3,
          "defaultValue": "60",
          "helperText": "Duration in server ticks (20 ticks = 1 second)",
          "validations": [
            { "type": "min", "value": "20" },
            { "type": "max", "value": "200" }
          ]
        },
        {
          "fieldName": "AnimationTickRate",
          "label": "Animation Tick Rate",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 4,
          "defaultValue": "1",
          "helperText": "Frames per tick (1 = smoothest, 5 = choppiest)",
          "validations": [
            { "type": "min", "value": "1" },
            { "type": "max", "value": "5" }
          ]
        }
      ]
    },
    {
      "stepName": "geometry",
      "title": "Gate Geometry",
      "description": "Define which blocks make up the gate",
      "order": 2,
      "fields": [
        {
          "fieldName": "GeometryDefinitionMode",
          "label": "Geometry Mode",
          "dataType": "string",
          "inputType": "radio",
          "isRequired": true,
          "order": 0,
          "defaultValue": "PLANE_GRID",
          "options": [
            { "value": "PLANE_GRID", "label": "Plane Grid (Rectangular)" },
            { "value": "FLOOD_FILL", "label": "Flood Fill (Irregular)" }
          ]
        },
        {
          "fieldName": "AnchorPoint",
          "label": "Anchor Point (Hinge Left/Top-Left)",
          "dataType": "string",
          "inputType": "text",
          "isRequired": true,
          "order": 1,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "worldTaskSettings": "{\"enabled\":true,\"taskType\":\"CAPTURE_LOCATION\",\"instructions\":\"Click the block at the bottom-left hinge of the gate\",\"allowCreate\":true,\"allowExisting\":false}"
        },
        {
          "fieldName": "ReferencePoint1",
          "label": "Reference Point 1 (Hinge Right/Top-Right)",
          "dataType": "string",
          "inputType": "text",
          "isRequired": true,
          "order": 2,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "worldTaskSettings": "{\"enabled\":true,\"taskType\":\"CAPTURE_LOCATION\",\"instructions\":\"Click the block at the bottom-right hinge of the gate\",\"allowCreate\":true,\"allowExisting\":false}"
        },
        {
          "fieldName": "ReferencePoint2",
          "label": "Reference Point 2 (Forward Reference)",
          "dataType": "string",
          "inputType": "text",
          "isRequired": true,
          "order": 3,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "worldTaskSettings": "{\"enabled\":true,\"taskType\":\"CAPTURE_LOCATION\",\"instructions\":\"Click a block in front of the gate to define depth direction\",\"allowCreate\":true,\"allowExisting\":false}"
        },
        {
          "fieldName": "GeometryWidth",
          "label": "Width (blocks)",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 4,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "helperText": "Auto-calculated from AnchorPoint → ReferencePoint1 (can override)",
          "validations": [
            { "type": "min", "value": "1" },
            { "type": "max", "value": "50" }
          ]
        },
        {
          "fieldName": "GeometryHeight",
          "label": "Height (blocks)",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 5,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "validations": [
            { "type": "min", "value": "1" },
            { "type": "max", "value": "50" }
          ]
        },
        {
          "fieldName": "GeometryDepth",
          "label": "Depth (blocks)",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 6,
          "defaultValue": "1",
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "PLANE_GRID"
          },
          "helperText": "Default 1 for flat gates, increase for thick gates",
          "validations": [
            { "type": "min", "value": "1" },
            { "type": "max", "value": "10" }
          ]
        },
        {
          "fieldName": "SeedBlocks",
          "label": "Seed Blocks (Flood Fill Start Points)",
          "dataType": "string",
          "inputType": "text",
          "isRequired": true,
          "order": 7,
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "FLOOD_FILL"
          },
          "worldTaskSettings": "{\"enabled\":true,\"taskType\":\"CAPTURE_MULTIPLE_LOCATIONS\",\"instructions\":\"Click all blocks to include in scan. Right-click to finish.\",\"allowCreate\":true,\"allowExisting\":false}"
        },
        {
          "fieldName": "ScanMaxBlocks",
          "label": "Max Blocks to Scan",
          "dataType": "int",
          "inputType": "number",
          "isRequired": true,
          "order": 8,
          "defaultValue": "500",
          "conditionalDisplay": {
            "field": "GeometryDefinitionMode",
            "operator": "equals",
            "value": "FLOOD_FILL"
          },
          "validations": [
            { "type": "min", "value": "50" },
            { "type": "max", "value": "2000" }
          ]
        }
      ]
    }
    // ... Steps 4-6 omitted for brevity (see earlier sections)
  ]
}
```

---

## Part G: Error Handling & User Feedback

### WorldTask Failure Scenarios

1. **Task Creation Failed** (API error)
   - **Display**: Error modal with retry button
   - **Message**: "Failed to create world task. Please try again."
   - **Action**: Allow user to retry or skip field (if not required)

2. **Task Execution Failed** (Plugin error)
   - **Display**: Error banner in WorldBoundFieldRenderer
   - **Message**: "Task failed: [error reason from plugin]"
   - **Action**: Clear task, allow re-creation

3. **Invalid Coordinates Captured**
   - **Display**: Validation error below field
   - **Message**: "Invalid coordinates: [specific issue]"
   - **Examples**:
     - "ReferencePoint2 is collinear with AnchorPoint and ReferencePoint1"
     - "Coordinates are outside world bounds"
     - "Region overlaps with existing gate"
   - **Action**: Highlight field in red, prevent step advancement

4. **WorldGuard Region Not Found**
   - **Display**: Validation error
   - **Message**: "Region 'castle_gate_closed' not found in world 'world'"
   - **Action**: Offer to create region or select different region

5. **Player Not in Minecraft** (Task timeout)
   - **Display**: Warning banner
   - **Message**: "Waiting for player to complete task in Minecraft. Task will expire in 5:00"
   - **Action**: Show countdown timer, allow task cancellation

### Success Feedback

1. **Task Completed Successfully**
   - **Display**: Success badge on field + visual checkmark
   - **Message**: "✓ [Field Label] captured successfully"
   - **Action**: Auto-populate field, enable step advancement

2. **Auto-Calculation Triggered**
   - **Display**: Info banner
   - **Message**: "GeometryWidth auto-calculated as 6 blocks based on AnchorPoint → ReferencePoint1 distance"
   - **Action**: Show calculated value, allow override

3. **Gate Created Successfully**
   - **Display**: Success modal
   - **Message**: "Gate '[Gate Name]' created successfully! Activate it to enable in-game?"
   - **Actions**: 
     - "Activate Now" → Sets IsActive = true, redirects to gate detail page
     - "Configure Later" → Redirects to gate list

---

## Part H: Testing Checklist

### FormConfiguration Setup

- [ ] Admin can create GateStructure FormConfiguration from template
- [ ] Admin can configure WorldTask settings for coordinate fields
- [ ] Admin can configure WorldTask settings for WorldGuard region fields
- [ ] FormConfiguration validation prevents missing required fields
- [ ] FormConfiguration saves WorldTask settings correctly

### FormWizard - Step 1 (Basic Info)

- [ ] Name field validates min/max length
- [ ] Domain dropdown populates correctly
- [ ] District dropdown filters by selected Domain
- [ ] Street dropdown filters by selected District
- [ ] Icon material searchable dropdown works

### FormWizard - Step 2 (Gate Type)

- [ ] GateType radio buttons display with descriptions
- [ ] MotionType auto-populates based on GateType selection
- [ ] FaceDirection compass selector displays all 8 directions
- [ ] AnimationDurationTicks validates range (20-200)
- [ ] AnimationTickRate validates range (1-5)

### FormWizard - Step 3 (Geometry)

- [ ] GeometryDefinitionMode toggles between PLANE_GRID and FLOOD_FILL fields
- [ ] AnchorPoint WorldTask button creates task successfully
- [ ] AnchorPoint WorldTask completion populates field with JSON coordinates
- [ ] ReferencePoint1 WorldTask captures coordinates
- [ ] ReferencePoint2 WorldTask captures coordinates
- [ ] GeometryWidth auto-calculates from AnchorPoint → ReferencePoint1
- [ ] HingeAxis auto-calculates from AnchorPoint → ReferencePoint1
- [ ] SeedBlocks WorldTask captures multiple locations (FLOOD_FILL mode)
- [ ] Invalid coordinates display validation errors
- [ ] Collinear ReferencePoint2 displays error

### FormWizard - Step 4 (Regions)

- [ ] RegionClosedId WorldTask lists existing WorldGuard regions
- [ ] RegionOpenedId WorldTask lists existing WorldGuard regions
- [ ] Creating new region via WorldTask works
- [ ] Region overlap validation prevents conflicts
- [ ] FallbackMaterialRefId searchable dropdown works
- [ ] TileEntityPolicy dropdown displays all options
- [ ] RotationMaxAngleDegrees visible only if MotionType = ROTATION
- [ ] LeftDoorSeedBlock visible only if GateType = DOUBLE_DOORS
- [ ] RightDoorSeedBlock visible only if GateType = DOUBLE_DOORS

### FormWizard - Step 5 (Health)

- [ ] HealthCurrent auto-populates to HealthMax on creation
- [ ] HealthCurrent cannot exceed HealthMax
- [ ] IsInvincible checkbox works
- [ ] CanRespawn checkbox works
- [ ] RespawnRateSeconds validates range
- [ ] AllowContinuousDamage checkbox works
- [ ] ContinuousDamageMultiplier validates range
- [ ] ShowHealthDisplay checkbox works
- [ ] HealthDisplayMode dropdown displays all options

### FormWizard - Step 6 (Advanced)

- [ ] AllowPassThrough checkbox toggles PassThroughDurationSeconds visibility
- [ ] PassThroughConditionsJson editor saves/loads JSON correctly
- [ ] GuardSpawnLocationsJson WorldTask captures locations with rotation
- [ ] GuardCount validates range (0-10)
- [ ] IsSiegeObjective checkbox works
- [ ] IsActive checkbox displays warning when unchecked

### WorldTask Integration

- [ ] WorldTask creation API call succeeds
- [ ] TaskStatusMonitor displays task status (Pending, InProgress, Completed, Failed)
- [ ] Task completion updates field value
- [ ] Task failure displays error message
- [ ] Multiple WorldTasks can run concurrently (different fields)
- [ ] WorldTask timeout displays warning
- [ ] Task cancellation works

### Data Submission

- [ ] Form submission sends all fields to API
- [ ] Nested JSON fields parse correctly (coordinates, regions, conditions)
- [ ] Entity creation succeeds with all required fields
- [ ] Entity creation fails with validation errors if fields missing
- [ ] Success modal displays after creation
- [ ] Redirect to entity detail page works

### Edit Mode

- [ ] Loading existing gate populates all fields correctly
- [ ] JSON fields parse and display in WorldBoundFieldRenderer
- [ ] Editing coordinates re-triggers auto-calculations
- [ ] Saving updates preserves all field values
- [ ] WorldTask recapture works (replaces existing coordinates)

---

## Part I: Performance Considerations

### FormWizard Load Time

**Challenge**: GateStructure has 47 fields across 6 steps, some requiring API calls for options.

**Optimizations**:
1. **Lazy Load Step Data**: Only fetch field options when step becomes active
2. **Cache Dropdown Options**: Store Domain/District/Street/Material lists in React context
3. **Debounce WorldTask Validation**: Wait 500ms after task completion before validating
4. **Preload Next Step**: Fetch next step's dropdown options while user fills current step

### 3D Preview Rendering

**Challenge**: Three.js rendering can be CPU-intensive, especially for large gates.

**Optimizations**:
1. **Lazy Render**: Only render 3D preview when step 3 is active AND all coordinates captured
2. **Level of Detail (LOD)**: Use lower-poly meshes for distant blocks
3. **Instanced Rendering**: Render multiple identical blocks using instanced meshes
4. **Throttle Updates**: Update preview max once per 200ms (not on every field change)

### WorldTask Polling

**Challenge**: TaskStatusMonitor polls API every 2 seconds, can strain server with many concurrent tasks.

**Optimizations**:
1. **WebSocket Integration** (future): Replace polling with WebSocket push notifications
2. **Exponential Backoff**: Increase poll interval (2s → 4s → 8s) if task remains in same state
3. **Auto-Stop Polling**: Stop after task completion or 5 minutes timeout

---

## Summary

**Frontend Components Required**:
- ✅ FormConfigBuilder enhancements (WorldTask settings editor)
- ✅ WorldBoundFieldRenderer enhancements (coordinate display, validation)
- ✅ PassThroughConditionsEditor (new component)
- ⏳ GatePreview3D (new component - future)
- ✅ Compass selector widget (new component - or use existing)
- ✅ FormWizard auto-calculation logic (enhance existing)

**Total Implementation Effort (Frontend)**:
- FormConfiguration template: 4-6 hours
- WorldTask field integration: 16-20 hours
- PassThroughConditionsEditor: 4-6 hours
- Validation & auto-calculation logic: 8-12 hours
- 3D preview widget (future): 20-30 hours
- Testing: 12-16 hours

**Total**: 44-60 hours (excluding 3D preview)

**Dependencies**:
- WorldTask API functional
- GateStructure entity scaffold complete (backend)
- MinecraftMaterialRef, Domain, District, Street entities exist
- WorldGuard plugin integration in Paper plugin

**Next Steps**:
1. Create GateStructure FormConfiguration template (JSON)
2. Enhance WorldBoundFieldRenderer for coordinate display
3. Implement PassThroughConditionsEditor component
4. Add auto-calculation logic to FormWizard
5. Test end-to-end flow (create gate → WorldTasks → save)

---

**Document maintained by**: AI Agent  
**Last updated**: January 31, 2026  
**Review status**: Ready for frontend development
