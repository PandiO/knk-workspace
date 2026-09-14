# Gate Animation System Documentation Index

**Location**: `docs/ai/gate-animation/`  
**Status**: Ready for Review & Implementation Planning  
**Created**: January 30, 2026  
**Last Updated**: January 30, 2026

---

## 📋 Quick Navigation

All gate animation system documentation is organized in this directory. Start with the file that matches your current needs:

| Document | Best For | Read Time |
|----------|----------|-----------|
| **[GATE_REQUIREMENTS_SUMMARY.md](GATE_REQUIREMENTS_SUMMARY.md)** | **START HERE** - Complete feature set overview and master checklist | 30-40 min |
| **[REQUIREMENTS_GATE_ANIMATION.md](REQUIREMENTS_GATE_ANIMATION.md)** | Complete base animation requirements and specifications | 60-90 min |
| **[REQUIREMENTS_GATE_ADVANCED_FEATURES.md](REQUIREMENTS_GATE_ADVANCED_FEATURES.md)** | Advanced features (pass-through, guards, siege, health display) | 45-60 min |
| **[REQUIREMENTS_GATE_FRONTEND.md](REQUIREMENTS_GATE_FRONTEND.md)** | Frontend FormWizard, WorldTasks, and 3D preview implementation | 45-60 min |
| **[SPEC_GATE_ANIMATION.md](SPEC_GATE_ANIMATION.md)** | Technical specification grounded in architecture | 60-90 min |
| **[GATE_ANIMATION_QUICK_START.md](./GATE_ANIMATION_QUICK_START.md)** | Quick reference during coding; cheat sheet | 15-20 min |
| **[GATE_ANIMATION_IMPLEMENTATION_ROADMAP.md](./GATE_ANIMATION_IMPLEMENTATION_ROADMAP.md)** | Understanding full scope, phases, and detailed planning | 45-60 min |
| **[VISUAL_SUMMARY_GATE_ANIMATION.md](./VISUAL_SUMMARY_GATE_ANIMATION.md)** | Quick visual reference of architecture, flows, and diagrams | 20-30 min |
| **[IMPLEMENTATION_CHECKLIST.md](./IMPLEMENTATION_CHECKLIST.md)** | Tracking progress during implementation | Ongoing |

---

## 🚀 Getting Started (5 Minutes)

1. **First Time?** Read [GATE_REQUIREMENTS_SUMMARY.md](GATE_REQUIREMENTS_SUMMARY.md) for complete feature matrix
2. **Need Details?** Read [REQUIREMENTS_GATE_ANIMATION.md](REQUIREMENTS_GATE_ANIMATION.md) for base animation system
3. **Advanced Features?** Read [REQUIREMENTS_GATE_ADVANCED_FEATURES.md](REQUIREMENTS_GATE_ADVANCED_FEATURES.md) for pass-through, guards, siege integration
4. **Frontend Work?** Read [REQUIREMENTS_GATE_FRONTEND.md](REQUIREMENTS_GATE_FRONTEND.md) for FormWizard and WorldTask specifications
3. **Advanced Features?** Read [REQUIREMENTS_GATE_ADVANCED_FEATURES.md](REQUIREMENTS_GATE_ADVANCED_FEATURES.md) for pass-through, siege, guards
4. **Starting to Code?** Open [GATE_ANIMATION_QUICK_START.md](./GATE_ANIMATION_QUICK_START.md) in a second window
5. **Planning Implementation?** Use [GATE_ANIMATION_IMPLEMENTATION_ROADMAP.md](./GATE_ANIMATION_IMPLEMENTATION_ROADMAP.md)
6. **Tracking Progress?** Copy [IMPLEMENTATION_CHECKLIST.md](./IMPLEMENTATION_CHECKLIST.md) and check off as you go

---

## 📁 What This Feature Includes

### Core Components
47 total fields: 13 existing + 34 new)
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
- Siege integration (gate locking, override, objective mechanics)e open, /gate close, /gate admin, etc.)
- Event handlers (block break, explosion, etc.)
- WorldGuard integration

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

- **Current Entity**: [GateStructure.cs](../../../Repository/knk-web-api/Models/GateStructure.cs)
- **Architecture Overview**: [docs/CODEMAP.md](../../guides/developer/CODEMAP.md)
- **Project Structure**: [docs/specs/project-overview/SOURCES_LOCATION.md](../../specs/project-overview/SOURCES_LOCATION.md)
- **Minecraft Data**: [Repository/knk-minecraft-data/minecraft-materials.json](../../../Repository/knk-minecraft-data/minecraft-materials.json)
- **Backend Instructions**: [.github/instructions/knk-backend.instructions.md](../../../.github/instructions/knk-backend.instructions.md)
- **Plugin Architecture**: [Repository/knk-plugin/ARCHITECTURE_AUDIT.md](../../../Repository/knk-plugin/ARCHITECTURE_AUDIT.md)

---

## ❓ Common Questions

**Q: Where do I start?**  
A: Read [REQUIREMENTS_GATE_ANIMATION.md](REQUIREMENTS_GATE_ANIMATION.md) first (60-90 min), then decide if you need the quick start or full roadmap.

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

---

## 📝 Implementation Notes

**Critical Paths:**
1. Backend entity extensions must be completed before frontend UI
2. Plugin development depends on backend API completion
3. Snapshot capture logic requires MinecraftBlockRef integration
4. WorldGuard integration requires region management understanding

**Dependencies:**
- MinecraftBlockRef entity (existing)
- MinecraftMaterialRef entity (existing)
- Structure entity (existing - GateStructure extends this)
- Domain/District/Street entities (existing)
- WorldGuard plugin (external - Paper API)

**Risk Areas:**
- Diagonal gate geometry calculation (complex math)
- Block collision during rotation (stable sort order critical)
- Entity push prediction (performance impact)
- Server restart mid-animation (state recovery)
- Fluid/gravity physics during animation (side effects)

**Testing Priorities:**
1. Basic open/close (SLIDING, PLANE_GRID)
2. Diagonal gates (all 8 directions)
3. Rotation (DRAWBRIDGE, DOUBLE_DOORS)
4. Entity push (collision prediction)
5. Performance (100 gates, 10 animating)
6. Edge cases (chunk unload, server restart, block break)

---

## 🎯 Success Criteria

**Functional:**
- ✅ All 4 gate types (SLIDING, TRAP, DRAWBRIDGE, DOUBLE_DOORS) work correctly
- ✅ Diagonal gates (all 8 FaceDirection values) animate correctly
- ✅ Block snapshots captured and restored accurately
- ✅ Entity push occurs only when collision imminent (not premature)
- ✅ Health & respawn system functional
- ✅ WorldGuard integration working (dual regions)
- ✅ Admin wizard allows gate creation/editing

**Performance:**
- ✅ 100 gates loaded < 50 MB plugin memory
- ✅ 10 gates animating simultaneously: TPS ≥ 18
- ✅ 20 gates animating simultaneously: TPS ≥ 15
- ✅ No server crash under stress

**Quality:**
- ✅ All unit tests passing (backend, frontend, plugin)
- ✅ Integration tests passing (API ↔ plugin sync)
- ✅ Edge cases handled (chunk unload, server restart, etc.)
- ✅ Documentation complete and accurate

---

## 📅 Recommended Phases

**Phase 1: Foundation (Backend + Basic Frontend)**
- Database schema migration
- Entity extensions (GateStructure, GateBlockSnapshot)
- DTOs, Repository, Service, Controller
- Basic web app UI (list, details)
- **Deliverable**: Gates can be created/edited via API + web app

**Phase 2: Geometry Capture (Plugin Foundation)**
- Plugin API client (load gates from API)
- PLANE_GRID geometry capture logic
- FLOOD_FILL geometry capture logic
- Snapshot storage via API
- **Deliverable**: Admin can capture gate blocks in Minecraft

**Phase 3: Animation Engine (Plugin Core)**
- Frame calculation (linear, rotation)
- Block placement system
- Animation tick task
- State machine implementation
- **Deliverable**: Gates can open/close with animation

**Phase 4: Entity Interaction (Plugin Polish)**
- Collision prediction
- Entity push system
- WorldGuard region sync
- Command handlers (/gate open, /gate close)
- **Deliverable**: Complete gate interaction system

**Phase 5: Advanced Features (Full Feature Set)**
- Health & respawn system
- Web app wizard (6-step)
- 3D preview widget
- Admin commands (/gate admin)
- Event handlers (block break, explosion)
- **Deliverable**: Production-ready feature

**Phase 6: Testing & Optimization**
- Unit tests (all layers)
- Integration tests (API ↔ plugin)
- Performance testing (100 gates)
- Edge case testing (chunk unload, server restart)
- **Deliverable**: Stable, tested, optimized system

---

**End of Index**
