# Gate Animation System - Architecture Decisions

**Last Updated**: January 31, 2026

---

## Decision 1: Frontend UI - Generic Framework vs Custom Components

### Context
Phase 5 required implementing gate list, details, creation, and editing workflows in the web app.

### Options Considered

#### Option A: Custom Pages (Rejected ❌)
Create dedicated React components:
- `GateListPage.tsx` - Custom list component
- `GateDetailsPage.tsx` - Custom detail view
- `GateWizardPage.tsx` - Custom 6-step creation wizard
- `GateEditPage.tsx` - Custom edit form

**Pros**:
- Full control over UX/UI
- Specialized features for gates only

**Cons**:
- ~600+ lines of custom component code
- Duplicates existing FormWizardPage, DisplayWizard, PagedEntityTable functionality
- Maintenance burden - any bug fixes or UX improvements to those components don't apply
- Inconsistent with KnK architecture principle of reusable generic components
- Sets bad precedent - every entity type gets custom pages
- Violates DRY principle

#### Option B: Generic Framework (Accepted ✅)
Reuse existing FormWizardPage and DisplayWizard components via ObjectConfig configuration:
- Create `GateStructureConfig` with form field definitions
- Register gate entity in `entityApiMapping.ts`
- Add column definitions to `columnDefinitionsRegistry`
- All gate workflows handled by generic components

**Pros**:
- ~130 lines of configuration vs 600+ lines of custom code
- Reuses proven, tested components (FormWizardPage, DisplayWizard, PagedEntityTable)
- Single source of truth for UI rendering
- Consistent with KnK architecture
- Automatically benefits from improvements to generic components
- Follows "don't repeat yourself" principle
- Easier maintenance and updates

**Cons**:
- Less customization for gate-specific features (but not needed for Phase 5)
- Requires understanding ObjectConfig pattern (documented in codebase)

### Decision: **Option B - Generic Framework**

### Rationale
The KnK codebase already has robust generic components that handle all CRUD operations for any entity type. Creating custom pages for gates would:
1. Waste implementation time (unnecessary duplication)
2. Create maintenance burden
3. Deviate from established architecture patterns
4. Set bad precedent for future entities

The ObjectConfig pattern is flexible enough to support all gate workflows while keeping code DRY and maintainable.

### Implementation
- Phase 5 implementation time: **4-6 hours** (instead of 32-40 hours for custom pages)
- Configuration files: `objectConfigs.tsx`, `entityApiMapping.ts`
- No custom React components created
- All workflows work automatically:
  - Create: `/forms/gatestructure` → FormWizardPage
  - Edit: `/forms/gatestructure/edit/:id` → FormWizardPage
  - View: `/display/gatestructure/:id` → DisplayWizard
  - List: PagedEntityTable with configured columns

### Future Implications
**For developers implementing future features:**
- Follow this pattern for all new entity types
- Do NOT create custom [EntityName]ListPage, [EntityName]DetailPage components
- Use ObjectConfig + entityApiMapping registration instead
- This keeps the codebase consistent and maintainable

### References
- FormWizardPage: `Repository/knk-web-app/src/pages/FormWizardPage.tsx`
- DisplayWizard: `Repository/knk-web-app/src/components/DisplayWizard/`
- PagedEntityTable: `Repository/knk-web-app/src/components/PagedEntityTable.tsx`
- ObjectConfig pattern: `Repository/knk-web-app/src/config/objectConfigs.tsx`
- Entity routing: `Repository/knk-web-app/src/utils/entityApiMapping.ts`
- Copilot instructions: `.github/copilot-instructions.md` (Global rules section)

---

## Decision 2: Gate Type System Architecture

### Context
Gates can be SLIDING, TRAP, DRAWBRIDGE, or DOUBLE_DOORS with different motion types and geometry requirements.

### Decision: Enum-based Type System with DTOs for Each Combination

### Rationale
- TypeScript enums ensure compile-time safety
- Database stores enum as string (database-agnostic)
- API contracts use enum values in DTOs
- Frontend dropdowns constrain selection to valid types
- Each combination (GateType + MotionType) is validated server-side

### Implementation
- `GateType` enum: SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS
- `MotionType` enum: VERTICAL, LATERAL, ROTATION
- `GeometryDefinitionMode` enum: PLANE_GRID, FLOOD_FILL
- Database validation prevents invalid combinations
- API accepts only valid type combinations

---

## Decision 3: Block Snapshot Storage

### Context
Gates can encompass hundreds or thousands of blocks. How to efficiently store and retrieve block geometry?

### Decision: Separate GateBlockSnapshot Entity with Bulk Operations

### Rationale
- **Separation of concerns**: Gate metadata separate from block data
- **Scalability**: Snapshots loaded only when needed (optional parameter)
- **Bulk operations**: `clearSnapshots`, `addSnapshots` for efficiency
- **Query optimization**: Index on GateId for fast lookups

### Implementation
- `GateBlockSnapshot` entity with: GateId, X, Y, Z, Material, BlockData, SortOrder
- API endpoints: `GET /gates/{id}/snapshots`, `POST /gates/{id}/snapshots`, `DELETE /gates/{id}/snapshots`
- Pagination support for large snapshot sets
- DTO mapping for API contracts

---

## Decision 4: API Response Format for Gate State

### Context
Clients need to know if a gate is OPEN, CLOSED, DESTROYED, or ACTIVE. How to represent state?

### Decision: Separate Boolean Fields (IsOpened, IsDestroyed, IsActive)

### Rationale
- **Flexibility**: Each state independently toggleable
- **Database efficiency**: Simple boolean columns
- **Explicit over implicit**: Clear what each field means
- **Extensibility**: Can add more states without breaking schema

### Implementation
- `IsOpened` (bool): Whether gate is currently open or closed
- `IsDestroyed` (bool): Whether gate has been destroyed
- `IsActive` (bool): Whether gate can animate (health > 0)
- State transition logic in service layer (not in database)

---

## Decision 5: Health and Respawn System

### Context
Gates should be destructible by players and possibly self-repair. How to implement?

### Decision: Configurable Health Pool with Optional Respawn

### Rationale
- **Health**: Simple numeric value (current vs max)
- **Invincible flag**: Server-side gate (cannot be destroyed)
- **Respawn**: Optional auto-repair after N seconds
- **Plugin integration**: Animation engine respects health states

### Implementation
- `HealthCurrent`, `HealthMax` (floats): Current and maximum health
- `IsInvincible` (bool): If true, gate cannot take damage
- `CanRespawn` (bool): If true, gate respawns after destruction
- `RespawnRateSeconds` (int): Time to respawn (e.g., 300 = 5 minutes)
- Plugin respects these settings when calculating damage

---

## References

- `.github/copilot-instructions.md` - Global architectural rules
- `docs/CODEMAP.md` - KnK codebase architecture overview
- `Repository/knk-web-app/src/config/objectConfigs.tsx` - ObjectConfig pattern examples
- `Repository/knk-web-app/src/pages/FormWizardPage.tsx` - Generic form wizard
- `Repository/knk-web-app/src/components/DisplayWizard/` - Generic display component
