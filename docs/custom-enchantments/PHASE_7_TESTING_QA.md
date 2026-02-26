# Custom Enchantments – Phase 7 Testing & QA

**Feature**: custom-enchantments  
**Phase**: 7 – Testing & Quality Assurance  
**Status**: Implemented (automated coverage expanded; manual checklist prepared)  
**Date**: 2026-02-26

---

## Scope from Roadmap

Phase 7 from `docs/custom-enchantments/IMPLEMENTATION_ROADMAP.md` requires:

1. Unit tests for registry/repository/cooldown manager
2. Integration tests for combat/interact/effects flow
3. Manual testing checklist and bug-fix pass

---

## Deliverables Implemented

### Unit Tests (Task 6.1)

Already present and validated in the plugin modules:

- `knk-core/src/test/java/net/knightsandkings/knk/core/domain/enchantment/EnchantmentRegistryTest.java`
- `knk-api-client/src/test/java/net/knightsandkings/knk/api/impl/enchantment/LocalEnchantmentRepositoryImplTest.java`
- `knk-paper/src/test/java/net/knightsandkings/knk/paper/enchantment/InMemoryCooldownManagerTest.java`

### Integration Tests (Task 6.2)

Added and aligned to roadmap intent:

- `knk-paper/src/test/java/net/knightsandkings/knk/paper/listeners/EnchantmentCombatListenerTest.java`
  - Verifies listener contract wiring (`@EventHandler` priority + `ignoreCancelled`)
  - Verifies constructor dependency/flag wiring

- `knk-paper/src/test/java/net/knightsandkings/knk/paper/integration/EnchantmentEffectsIntegrationTest.java`
  - Verifies passive effect dispatch integration through executor port
  - Verifies active support trigger flow for eligible enchantments
  - Verifies cooldown enforcement behavior for active effects
  - Verifies permission-based filtering for active effects

### Manual Testing & Bug Fixes (Task 6.3)

Manual checklist prepared for in-game verification:

- [ ] Apply all 12 enchantments to test items
- [ ] Verify each passive enchantment triggers on hit
- [ ] Verify each active enchantment triggers on right-click
- [ ] Verify cooldown messages display
- [ ] Verify permission denial messages
- [ ] Test all `/ce` commands
- [ ] Test in Creative mode (enabled and disabled)
- [ ] Verify Freeze prevents movement but allows looking
- [ ] Verify Chaos knockback radius and direction
- [ ] Verify Flash Chaos debuffs only apply to players
- [ ] Verify Armor Repair fully repairs all pieces
- [ ] Test with multiple enchantments on same item
- [ ] Test permission/cooldown edge cases

---

## Repository Impact

- `knk-web-api-v2`: no code changes required for Phase 7 scope
- `knk-web-app`: no code changes required for Phase 7 scope
- `knk-plugin-v2`: test and QA coverage expanded

---

## Validation Notes

- Automated verification should run focused plugin tests for the new/affected test classes.
- Listener runtime execution paths that depend on full Bukkit/Paper registry initialization should be validated by manual in-server testing.
- Full in-game behavior validation still depends on manual server-side execution for gameplay effects.
