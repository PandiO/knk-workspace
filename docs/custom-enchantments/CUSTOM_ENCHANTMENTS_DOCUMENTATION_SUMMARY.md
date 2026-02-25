# Custom Enchantments Integration – Documentation Summary

**Generated**: January 11, 2026  
**Updated**: February 24, 2026  
**For**: Knights & Kings v2 unified ability/enchantment model  
**Source Analysis**: CustomEnchantments-1.0.3.jar legacy behavior + v2 integration requirements  

---

## What Was Created

Three comprehensive specification documents are maintained in `docs/custom-enchantments`:

### 1. **SPEC_CUSTOM_ENCHANTMENTS.md** (Primary Specification)
**Length**: ~700 lines  
**Purpose**: Comprehensive feature specification and requirements

**Includes**:
- Feature overview (12 abilities/enchantments with detailed specs)
- Unified architecture & integration points (API + web app + plugin runtime adapter)
- Detailed effect specifications (triggering, probability, duration, effects)
- Runtime adapter storage format (lore-based with color codes)
- Permission system (`customenchantments.*`)
- Runtime/admin commands (`/ce ...`)
- Configuration structure (messages, settings)
- Implementation priorities and open decisions

### 2. **IMPLEMENTATION_ROADMAP.md** (Execution Plan)
**Length**: ~800 lines  
**Purpose**: Step-by-step implementation roadmap with effort estimates

**Includes**:
- Module-level implementation breakdown
- 8 implementation phases with deliverables and acceptance criteria
- Sequencing, dependencies, and risk assessment
- Notes for Copilot implementation

### 3. **QUICK_REFERENCE_CUSTOM_ENCHANTMENTS.md** (Quick Lookup)
**Length**: ~300 lines  
**Purpose**: Fast developer reference during implementation

**Includes**:
- Ability/enchantment stats table (all 12)
- Core port signatures and domain models
- Key files and implementation checklist
- Threading rules, storage notes, config template
- Common pitfalls and test checklist

---

## Critical Requirement (v2 Integration)

Custom enchantments are documented as **abilities** that can be exposed through multiple contexts:

1. As an enchantment in `EnchantmentDefinition` with `IsCustom = true`
2. As optional custom metadata in an extension entity linked to `EnchantmentDefinition`
3. As assignments to `ItemBlueprint` instances (e.g., default enchantment/ability loadouts)
4. As future personal skills attached to user instances (skill feature not yet implemented)

`EnchantmentDefinition` is the canonical model for both vanilla and custom enchantments.  
Custom entries are identified by `IsCustom = true`.

The extension entity is optional, so vanilla enchantments remain first-class without custom metadata rows.

---

## Key Findings from Analysis

### Ability Set Identified

**Passive attack-triggered abilities**:
1. Poison (3 levels)
2. Wither (3 levels)
3. Freeze (3 levels)
4. Blindness (3 levels)
5. Confusion (3 levels)
6. Strength (2 levels)

**Active use-triggered abilities**:
7. Chaos (1 level)
8. Flash Chaos (1 level)
9. Health Boost (1 level)
10. Armor Repair (1 level)
11. Resistance (2 levels)
12. Invisibility (1 level)

### Architecture Patterns

- **Canonical persistence**: Web API entity model (`EnchantmentDefinition` and related assignment entities)
- **Optional extension**: custom-only metadata hangs off `EnchantmentDefinition` via optional 1:1 extension
- **Runtime adapter**: Plugin lore/event handling for in-game execution
- **Threading**: Events → async parsing/checks → main thread effects
- **Permissions**: Per-ability permission nodes
- **Cooldowns**: Per-player per-ability tracking

### Design Decisions

1. **Unified Ability Model**: custom enchantments are modeled as abilities in the shared domain.
2. **Optional Extension Pattern**: custom-only metadata is kept in an optional extension linked to `EnchantmentDefinition`.
3. **Dual Attachment Targets**: ability links are required for `ItemBlueprint`, and planned for user skills.
4. **Canonical Entity Flag**: custom definitions must set `EnchantmentDefinition.IsCustom = true`.
4. **Runtime Compatibility**: plugin execution keeps command/listener patterns for in-game behavior.

---

## Integration with v2 Architecture

✅ **Layered Ownership**:
- `knk-web-api-v2`: canonical ability/enchantment definitions and relationships
- `knk-web-app`: management UI for definitions and assignments
- `knk-plugin-v2`: runtime effect execution adapter

✅ **Async Pattern**:
- Asynchronous service boundaries where applicable
- Bukkit effects scheduled on main thread
- API-backed metadata and assignment persistence

✅ **Documentation Source**:
- `docs/custom-enchantments` is the shared source for this feature’s cross-project design.

---

## File Locations

```
/Users/Pandi/Documents/Werk/KnightsAndKings/docs/custom-enchantments/
├── SPEC_CUSTOM_ENCHANTMENTS.md
├── IMPLEMENTATION_ROADMAP.md
├── QUICK_REFERENCE_CUSTOM_ENCHANTMENTS.md
└── CUSTOM_ENCHANTMENTS_DOCUMENTATION_SUMMARY.md
```

---

## Next Steps

1. ✅ Phase 1 core/plugin infrastructure implemented in `knk-plugin-v2` (models, ports, registry, lore adapter, cooldown manager, tests).
2. ✅ Finalized API model details for ability attachments to `ItemBlueprint` through `EnchantmentDefinition` + extension DTO contracts.
3. ✅ Implemented optional extension entity mapping from `EnchantmentDefinition` (`AbilityDefinition`, optional 1:1).
4. ✅ Reserved user-instance attachment contract placeholder via `FutureUserAssignmentContract` on `AbilityDefinition`.
5. ✅ Implemented `IsCustom = true` enforcement for custom `EnchantmentDefinition` records.
6. ✅ Phase 4 active support runtime implemented in `knk-paper` (support effects, right-click listener, cooldown messaging, and tests).
7. Continue with roadmap Phase 5+ command/config expansion.

---

## Summary

✅ Legacy behavior has been analyzed and preserved where needed.  
✅ Documentation now reflects the v2 unified ability model.  
✅ Optional extension model is defined without replacing `EnchantmentDefinition`.  
✅ Custom abilities are explicitly tied to `EnchantmentDefinition.IsCustom = true`.  
✅ Attachment strategy now covers `ItemBlueprint` and future user skills.  
✅ Docs are ready for implementation across API, web app, and plugin layers.

