# Gate Animation System - Architecture Decisions

**Last Updated**: 2026-11-03 (Decision 6: animated rebuild of destroyed gates)

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

## Decision 6: Animated rebuild of destroyed gate doors (confirmed 2026-11-03)

### Context
Rebuilding a destroyed door today is instant: `HealthSystem.respawnGate` → `restoreGateBlocks` places the closed blocks at once, with no entity collision handling, and broadcasts "Gate '…' has been restored!" to the whole server ([Siege Survival implementation checks](../../reports/2026-11-03-siege-survival-implementation-checks.md) §5). Siege Survival repairs need a rebuild that can't trap players or mobs.

### Decision (developer, 2026-11-03)
One rebuild mechanic for **every** destroyed-door rebuild: normal world gates (`CanRespawn` timer), Siege and Siege Survival repairs.

1. **Rebuild state setting.** Each GateDoor gets an optional enum setting for the state it is rebuilt in: **open** or **closed**, default **open**. (Conceptual name, e.g. `RebuildState`; not an implemented field.)
2. **Rebuild animation.** The door's blocks are placed in the rebuild state's position, showing the block-break overlay at its most damaged stage. The overlay then steps through all 10 break stages from most damaged to undamaged. The door is not damageable while rebuilding.
3. **Return to the normal state.** When all blocks are rebuilt, the door returns to its normal state, its `OpenedState`. If that differs from the rebuild state (e.g. rebuilt open, normally closed), the normal open/close animation runs, including entity collision handling and jam reporting.
4. **Rebuild complete.** When that animation finishes (or immediately, when the states match) the door reaches **rebuild complete**, a lifecycle state/event, and health is full.
5. **Notifications.** Rebuild complete notifies a **subscriber list** of groups/players. Siege and Siege Survival subscribe the team that controls the gate. There is **no server-wide announcement**. The list is customizable and meant to be built upon later.

### Notes for implementation (proposed, not decided)
- Replaces the instant `respawnGate` placement and its server-wide broadcast; rebuilds should not bypass the animation path.
- Placing the rebuild-state blocks should evacuate entities from those cells the same way an animation step does, so a rebuild in the closed state can't enclose anyone. Default open keeps the doorway clear while the cracks heal.
- The break overlay is a per-viewer block-damage display (Paper `Player#sendBlockDamage`); `GateCrackVisuals` already renders health-based cracks and can be reused. Stage duration is configurable (proposal: 10 ticks per stage, 5 s total).
- Subscribers: a configured static list (players, groups) plus runtime contributors such as Siege's controlling team. Default for world gates: empty, so no message. Persistence shape and message wording open.
- A jam during the return animation keeps the door out of rebuild complete until it actually reaches its state; report the real state.
- Survival's damaged-door repair (no rebuild needed) restores health in one step and closes through the normal animation if open (Siege Survival DESIGN §5).

---

## References

- `.github/copilot-instructions.md` - Global architectural rules
- `docs/CODEMAP.md` - KnK codebase architecture overview
- `Repository/knk-web-app/src/config/objectConfigs.tsx` - ObjectConfig pattern examples
- `Repository/knk-web-app/src/pages/FormWizardPage.tsx` - Generic form wizard
- `Repository/knk-web-app/src/components/DisplayWizard/` - Generic display component
