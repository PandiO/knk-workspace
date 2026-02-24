# Custom Enchantments – Quick Reference

**For**: Copilot Implementation Guide  
**Status**: Ready to implement  
**Date**: January 11, 2026

---

## v2 Requirement Snapshot (Critical)

- Custom abilities are represented as `EnchantmentDefinition` entries with `IsCustom = true`.
- Abilities must be attachable to `ItemBlueprint` instances.
- Abilities are planned to be attachable to user instances as personal skills (skill feature pending).
- Plugin lore/event logic is a runtime adapter and not the canonical persistence source.

---

## Enchantment Quick Stats

| # | Name | Max Lvl | Type | Cooldown | Trigger | Effect |
|---|---|---|---|---|---|---|
| 1 | Poison | 3 | Attack | 0s | Hit (15%) | Poison II × (lvl × 60t) |
| 2 | Wither | 3 | Attack | 0s | Hit (15%) | Poison II × (lvl × 40t) |
| 3 | Freeze | 3 | Attack | 0s | Hit (15%) | Block movement (lvl × 60t) |
| 4 | Blindness | 3 | Attack | 0s | Hit (100%) | Blindness I × (lvl × 60t) |
| 5 | Confusion | 3 | Attack | 0s | Hit (15%) | Nausea III × (lvl × 60t) |
| 6 | Strength | 2 | Attack | 120s | Hit (15%) | Strength lvl × 15s (attacker) |
| 7 | Chaos | 1 | Support | 90s | Click | AoE 40dmg (3b) + knockback (5b) |
| 8 | FlashChaos | 1 | Support | 90s | Click | AoE 60dmg (3b) + debuffs (5b) |
| 9 | HealthBoost | 1 | Support | 120s | Click | +1 health × 6 (max 20) |
| 10 | ArmorRepair | 1 | Support | 120s | Click | Full repair armor |
| 11 | Resistance | 2 | Support | 120s | Click | Resistance lvl × (lvl × 100 + 100t) |
| 12 | Invisibility | 1 | Support | 90s | Click | Invisibility × 200t |

---

## Core Ports (knk-core)

### EnchantmentRepository
```java
CompletableFuture<Map<String, Integer>> getEnchantments(ItemStack item)
CompletableFuture<Boolean> hasAnyEnchantment(ItemStack item)
CompletableFuture<Boolean> hasEnchantment(ItemStack item, String id)
CompletableFuture<ItemStack> applyEnchantment(ItemStack item, String id, Integer level)
CompletableFuture<ItemStack> removeEnchantment(ItemStack item, String id)
```

### EnchantmentExecutor
```java
CompletableFuture<Void> executeOnMeleeHit(ItemStack weapon, Player attacker, LivingEntity target, double damageDealt)
CompletableFuture<Boolean> executeOnInteract(ItemStack item, Player player)
CompletableFuture<Void> executeOnBowShoot(ItemStack bow, Player shooter, Entity projectile)
```

### CooldownManager
```java
CompletableFuture<Long> getRemainingCooldown(UUID playerId, String enchantmentId)
CompletableFuture<Void> applyCooldown(UUID playerId, String enchantmentId, long durationMs)
CompletableFuture<Void> clearCooldowns(UUID playerId)
```

---

## Domain Models (knk-core)

```java
public record Enchantment(
    String id,
    String displayName,
    int maxLevel,
    int cooldownMs,
    EnchantmentType type,
    Double triggerProbability  // null = always
) {}

public enum EnchantmentType {
    ATTACK,    // onHit
    SUPPORT    // onClick
}
```

---

## Key Files to Create

### knk-core
- `core/domain/enchantment/Enchantment.java` (record)
- `core/domain/enchantment/EnchantmentInstance.java` (record)
- `core/domain/enchantment/EnchantmentType.java` (enum)
- `core/domain/enchantment/EnchantmentRegistry.java` (singleton)
- `core/ports/enchantment/EnchantmentRepository.java`
- `core/ports/enchantment/EnchantmentExecutor.java`
- `core/ports/enchantment/CooldownManager.java`

### knk-api-client
- `api/impl/enchantment/LocalEnchantmentRepositoryImpl.java`

### knk-paper
- `paper/enchantment/EnchantmentManager.java` (facade)
- `paper/enchantment/effects/EnchantmentEffect.java`
- `paper/enchantment/effects/AttackEnchantmentEffect.java`
- `paper/enchantment/effects/SupportEnchantmentEffect.java`
- `paper/enchantment/effects/impl/*.java` (12 effect implementations)
- `paper/listeners/EnchantmentCombatListener.java`
- `paper/listeners/EnchantmentInteractListener.java`
- `paper/listeners/EnchantmentEnchantTableListener.java`
- `paper/listeners/FreezeMovementListener.java`
- `paper/commands/EnchantmentCommandHandler.java` + subcommands
- `paper/bootstrap/EnchantmentBootstrap.java`
- `paper/config/EnchantmentConfigManager.java`

---

## Threading Rules (Critical!)

```java
// ✅ CAN be async
enchantmentRepository.getEnchantments(item)
cooldownManager.getRemainingCooldown(...)

// ❌ MUST be on main thread
player.addPotionEffect(...)
world.playEffect(...)
world.playSound(...)
target.setVelocity(...)

// Pattern:
CompletableFuture<Void> executeOnMeleeHit(...) {
    return CompletableFuture.runAsync(() -> {
        // Parse lore (async-safe)
        Map<String, Integer> enchantments = getEnchantments(weapon);
        
        // Schedule effects on main thread
        Bukkit.getScheduler().runTask(plugin, () -> {
            for (var ench : enchantments.entrySet()) {
                effect.execute(...);  // Potion + particle
            }
        });
    }, asyncExecutor);
}
```

---

## Lore Format

**Storage (runtime adapter)**: Item lore, color-coded

**Canonical model**:
- `EnchantmentDefinition` (custom rows set `IsCustom = true`)
- `ItemBlueprint` attachment support
- Future user-instance skill attachments

```
§7<Name> <Roman Level>
§7Poison I
§7Poison II
§7Chaos I
```

**Parsing Helper**:
```java
// Parse one lore line
if (line.contains("§7")) {
    String clean = ChatColor.stripColor(line);  // "Poison I"
    for (Enchantment e : EnchantmentRegistry.getAll()) {
        if (clean.startsWith(e.displayName + " ")) {
            String levelStr = clean.split(" ")[1];  // "I"
            int level = stringToLevel(levelStr);
            return Map.entry(e.id, level);
        }
    }
}
```

---

## Config Structure

```yaml
# config.yml
settings:
  disable-for-creative: false
  permission-message-timeout: 60

messages:
  cmd-player-only: '&cThis command can only be executed by players.'
  cmd-reload: '&aPlugin configuration was reloaded.'
  cmd-add-success: '&aEnchantment was added to item successfully.'
  cmd-add-level: '&cCannot add %enchantment%, max level is %lvl%.'
  cmd-remove-success: '&aEnchantment was removed from item successfully.'
  cmd-hand: '&cPlease put an item in your hand and run the command.'
  cmd-player-not-found: '&cCould not find player %player%.'
  cmd-clear: '&aRemoved cooldowns for %player%.'
  ench-use: '&cYou cannot use %enchantment%.'
  ench-perm: '&cThis item contains enchantments you don''t have permission for.'
```

---

## Special Cases

### Freeze (Complex!)
- Registers separate PlayerMoveEvent listener
- Tracks frozen players in HashSet<UUID>
- Prevents movement: `event.setTo(event.getFrom())`
- Exception: Allow if "only looked around" (check camera rotation via PlayerLookEvent)
- Clears after duration via scheduler

### Chaos / FlashChaos
- Fire custom EntityDamageByEntityEvent
- Check if event cancelled before knockback
- FlashChaos: debuffs only to Player targets, not mobs

### Strength
- Effect applies to **attacker**, not target!
- Cooldown per player (not per enemy hit)

### Health Boost
- Runs 6 times, 5 ticks apart (25 tick total duration)
- Cap at 20 HP max
- Max level = 1, so always +1 HP per tick

---

## Commands

```
/ce help                    - Show help
/ce add <ench> <level>     - Add to held item
/ce remove <ench>          - Remove from held item
/ce info [player]          - Show enchantments
/ce cooldown clear [player] - Clear cooldowns (admin)
/ce reload                 - Reload config
```

---

## Permissions

```
customenchantments.poison
customenchantments.wither
customenchantments.freeze
customenchantments.blindness
customenchantments.confusion
customenchantments.strength
customenchantments.chaos
customenchantments.flash_chaos
customenchantments.health_boost
customenchantments.armor_repair
customenchantments.resistance
customenchantments.invisibility
```

---

## Test Checklist

### Passive Effects
- [ ] Poison triggers on hit, applies correct duration
- [ ] Wither triggers on hit, applies potion + witch particle
- [ ] Freeze prevents movement, allows camera rotation
- [ ] Blindness always triggers (no RNG)
- [ ] Confusion triggers on hit
- [ ] Strength grants to attacker, enforces cooldown

### Active Effects
- [ ] Health Boost heals +1 HP × 6, capped at 20
- [ ] Armor Repair fully repairs all armor
- [ ] Resistance applies with correct duration
- [ ] Invisibility applies for 10 seconds
- [ ] Chaos damages within 3 blocks, knockbacks within 5
- [ ] FlashChaos damages 60, applies debuffs to players only

### System
- [ ] All 12 enchantments can be added/removed
- [ ] Cooldowns prevent spam
- [ ] Permissions enforce correctly
- [ ] Creative mode setting works
- [ ] Config loads without errors

---

## Implementation Tips

1. **Start with domain models**: Get Enchantment and EnchantmentRegistry solid first
2. **Test lore parsing**: This is error-prone; write comprehensive unit tests
3. **Build one effect at a time**: Start with Poison (simplest), then iterate
4. **Threading first**: Make sure ExecutorImpl schedules on main thread correctly
5. **Test listeners early**: Verify they fire in the right order/priority
6. **Cooldown debugging**: Use `/ce info` command to show remaining cooldown
7. **Permission messages**: Rate-limit to avoid spam (use 60-tick timeout)

---

## Common Pitfalls to Avoid

❌ **Don't**: Import Bukkit in knk-core  
✅ **Do**: Define ports/interfaces in knk-core; implement in knk-paper

❌ **Don't**: Run potions/particles async  
✅ **Do**: Schedule with `Bukkit.getScheduler().runTask(plugin, ...)` on main thread

❌ **Don't**: Hardcode messages  
✅ **Do**: Load from config.yml via ConfigManager

❌ **Don't**: Forget to check permissions  
✅ **Do**: Check `player.hasPermission(...)` before executing

❌ **Don't**: Apply potion effects directly to entity without checking type  
✅ **Do**: Check `instanceof Player` for effects that only affect players (Freeze)

❌ **Don't**: Use `event.getDamager()` assuming it's a player  
✅ **Do**: Check `instanceof Player` and `getItemInHand()`

---

## Related Documents

- **Full Spec**: SPEC_CUSTOM_ENCHANTMENTS.md
- **Roadmap**: IMPLEMENTATION_ROADMAP_CUSTOM_ENCHANTMENTS.md
- **Architecture**: ARCHITECTURE_AUDIT.md
- **Threading Pattern**: docs/API_CLIENT_PATTERN.md
- **Legacy Behavior Baseline**: CustomEnchantments-1.0.3.jar (analyzed)

