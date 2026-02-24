# Custom Enchantments System – Specification & Implementation Guide

**Document Version**: 1.1  
**Date**: January 11, 2026  
**Updated**: February 24, 2026  
**Status**: DRAFT  
**Source**: CustomEnchantments-1.0.3.jar legacy analysis + v2 unified integration requirements  

---

## Overview

This specification defines the **Custom Enchantments** system for Knights & Kings v2 as a **shared ability model**. Abilities can be used as item enchantments and are planned to also be used as user-bound personal skills.

The canonical entity is `EnchantmentDefinition`, which stores both vanilla and custom enchantments. Custom abilities must be represented with `EnchantmentDefinition.IsCustom = true`.

Attachment targets:
- `EnchantmentDefinition` (canonical definition)
- `ItemBlueprint` (default item-side assignments)
- User instances (future skill system; not implemented yet)

Plugin lore/event logic remains a runtime adapter and must not be treated as the source of truth.

---

## 1. Feature Summary

### 1.1 Enchantment Types

The feature currently includes **12 distinct custom abilities/enchantments**, categorized by trigger type:

#### **Attack Enchantments** (trigger on hit)
Triggered when the player deals melee damage to an entity:

| Enchantment | Max Level | Trigger | Probability | Effect |
|---|---|---|---|---|
| **Poison** | 3 | Melee hit | 15% per level | Applies Poison II for (level × 60) ticks |
| **Wither** | 3 | Melee hit | 15% per level | Applies Poison II for (level × 40) ticks + witch particle effect |
| **Freeze** | 3 | Melee hit | 15% per level | Prevents target player movement for (level × 60) ticks; ice particle effects |
| **Blindness** | 3 | Melee hit | 100% (always) | Applies Blindness I for (level × 60) ticks + wither sound |
| **Confusion** | 3 | Melee hit | 15% per level | Applies Nausea III for (level × 60) ticks |
| **Strength** | 2 | Melee hit | 15% per level | Grants attacker Strength (level) for 15 seconds; cooldown: 120s |
| **Chaos** | 1 | Right-click activation | — | AoE ability; cooldown: 90s; see section 1.2 |
| **Flash Chaos** | 1 | Right-click activation | — | Enhanced Chaos variant; cooldown: 90s; see section 1.2 |

#### **Defense/Support Enchantments** (trigger on interaction or item equip)

| Enchantment | Max Level | Trigger | Cooldown | Effect |
|---|---|---|---|---|
| **Health Boost** | 1 | Right-click activation | 120s | Restores (level) health to the player over 5 ticks; max 20 HP |
| **Armor Repair** | 1 | Right-click activation | 120s | Fully repairs all worn armor pieces; plays anvil sound |
| **Resistance** | 2 | Right-click activation | 120s | Grants Damage Resistance (level) for (level × 100 + 100) ticks |
| **Invisibility** | 1 | Right-click activation | 90s | Grants Invisibility for 200 ticks (10 seconds) |

---

### 1.2 Activation Modes

#### **A. Passive Enchantments** (auto-trigger on hit)
- **Poison, Wither, Freeze, Blindness, Confusion, Strength**
- Triggered automatically when the enchanted weapon deals damage to a target
- Damage event listener detects enchanted item in attacker's hand
- Probability-based: `Math.random() < 0.15D * level` (except Blindness: always triggers)
- Visual/audio effects play at impact location

#### **B. Active Enchantments** (right-click activation)
- **Chaos, Flash Chaos, Health Boost, Armor Repair, Resistance, Invisibility**
- Triggered by player interaction (right-click with item in hand)
- Cooldown enforced per enchantment per player
- Cooldown messages shown to player: "XX seconds remaining"
- Some enchantments affect nearby entities (Chaos variants)

---

## 2. Architecture & Integration Points

### 2.1 Core Ports (knk-core)

Define interfaces for enchantment persistence, execution, and state management:

```
knk-core/src/main/java/net/knightsandkings/knk/core/ports/enchantment/
├── EnchantmentRepository.java       # Load/save enchantments on items
├── EnchantmentExecutor.java         # Dispatch enchantment effects
└── CooldownManager.java             # Track & enforce cooldowns per player
```

#### **EnchantmentRepository.java** (Port)
```java
public interface EnchantmentRepository {
    /**
     * Retrieve all enchantments applied to an item.
     * @return Map of enchantment ID -> level
     */
    CompletableFuture<Map<String, Integer>> getEnchantments(ItemStack item);
    
    /**
     * Check if an item has any custom enchantment.
     */
    CompletableFuture<Boolean> hasAnyEnchantment(ItemStack item);
    
    /**
     * Check if an item has a specific enchantment.
     */
    CompletableFuture<Boolean> hasEnchantment(ItemStack item, String enchantmentId);
    
    /**
     * Apply an enchantment to an item (updates item lore).
     * @param enchantmentId e.g., "poison", "health_boost"
     * @param level 1-3
     */
    CompletableFuture<ItemStack> applyEnchantment(
        ItemStack item, 
        String enchantmentId, 
        Integer level
    );
    
    /**
     * Remove an enchantment from an item.
     */
    CompletableFuture<ItemStack> removeEnchantment(ItemStack item, String enchantmentId);
}
```

#### **EnchantmentExecutor.java** (Port)
```java
public interface EnchantmentExecutor {
    /**
     * Execute all enchantments on a weapon for a melee hit.
     * @param weapon Item in attacker's hand
     * @param attacker The player dealing damage
     * @param target The entity taking damage
     * @param damageDealt Original damage amount (for scaling effects)
     */
    CompletableFuture<Void> executeOnMeleeHit(
        ItemStack weapon,
        Player attacker,
        LivingEntity target,
        double damageDealt
    );
    
    /**
     * Execute enchantments on right-click interaction.
     * @param item Item being used
     * @param player Player activating the enchantment
     * @return true if an active enchantment was triggered
     */
    CompletableFuture<Boolean> executeOnInteract(ItemStack item, Player player);
    
    /**
     * Execute enchantments when bow is shot.
     * @param bow Enchanted bow
     * @param shooter Player shooting
     * @param projectile Arrow/projectile entity
     */
    CompletableFuture<Void> executeOnBowShoot(
        ItemStack bow,
        Player shooter,
        Entity projectile
    );
}
```

#### **CooldownManager.java** (Port)
```java
public interface CooldownManager {
    /**
     * Check if player can execute an enchantment (not on cooldown).
     * @param playerId Player UUID
     * @param enchantmentId e.g., "strength", "chaos"
     * @return remaining cooldown in ms, or 0 if ready
     */
    CompletableFuture<Long> getRemainingCooldown(UUID playerId, String enchantmentId);
    
    /**
     * Start cooldown for an enchantment for a player.
     * @param durationMs Cooldown duration in milliseconds
     */
    CompletableFuture<Void> applyCooldown(
        UUID playerId,
        String enchantmentId,
        long durationMs
    );
    
    /**
     * Clear all cooldowns for a player.
     */
    CompletableFuture<Void> clearCooldowns(UUID playerId);
}
```

---

### 2.2 Core Domain Models (knk-core)

Define immutable domain objects for enchantments and effects:

```
knk-core/src/main/java/net/knightsandkings/knk/core/domain/enchantment/
├── Enchantment.java               # Record: enchantment definition
├── EnchantmentEffect.java         # Interface for effect execution
├── EnchantmentInstance.java       # Record: enchantment + level on an item
└── CooldownState.java             # Record: player UUID + remaining ms
```

#### **Enchantment.java** (Domain Model)
```java
public record Enchantment(
    String id,                      // e.g., "poison"
    String displayName,             // e.g., "Poison"
    int maxLevel,
    int cooldownMs,                 // 0 = no cooldown
    EnchantmentType type,           // ATTACK, SUPPORT, etc.
    double triggerProbability       // 0.0-1.0; null = always trigger
) {}

public enum EnchantmentType {
    ATTACK,                         // Melee hit trigger
    SUPPORT,                        // Right-click activation
    UTILITY                         // Special (armor, bow, etc.)
}
```

#### **EnchantmentInstance.java** (Domain Model)
```java
public record EnchantmentInstance(
    String enchantmentId,
    Integer level
) {}
```

---

### 2.3 API Client (knk-api-client)

**v2 Requirement**: The canonical persistence model is the Web API (`EnchantmentDefinition` + assignment relations). Plugin lore is a runtime compatibility format for in-game execution.

API client implementations should resolve definitions/assignments from API-backed data, while still supporting lore parsing/writing where needed for runtime compatibility:

```
knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/enchantment/
└── LocalEnchantmentRepositoryImpl.java  # Runtime lore adapter (not canonical persistence)
```

---

### 2.4 Paper Adapter Layer (knk-paper)

Implement listener-based event handling and command interfaces:

```
knk-paper/src/main/java/net/knightsandkings/knk/paper/
├── enchantment/
│   ├── EnchantmentManager.java                 # Core service
│   ├── EnchantmentRegistry.java                # Define all 12 enchantments
│   └── effects/
│       ├── AttackEnchantmentEffect.java        # Base for poison, wither, etc.
│       ├── SupportEnchantmentEffect.java       # Base for health boost, armor, etc.
│       ├── ChaosEnchantmentEffect.java         # Special AoE logic
│       └── /* individual effect classes */
├── listeners/
│   ├── EnchantmentCombatListener.java          # EntityDamageByEntityEvent
│   ├── EnchantmentInteractListener.java        # PlayerInteractEvent
│   ├── EnchantmentBowListener.java             # EntityShootBowEvent
│   └── EnchantmentEnchantTableListener.java    # Prevent re-enchanting
└── commands/
    ├── EnchantCommandHandler.java              # /ce add, /ce remove, /ce info
    └── EnchantCooldownDebugCommand.java        # /ce cooldown clear
```

#### **Key Listeners**

##### EnchantmentCombatListener (EntityDamageByEntityEvent)
- Fires on LOWEST priority (before damage reduction)
- Detects enchanted weapon in attacker's hand
- Respects Creative mode + permission bypass
- Calls `EnchantmentExecutor.executeOnMeleeHit()`

##### EnchantmentInteractListener (PlayerInteractEvent)
- Fires on RIGHT_CLICK_AIR and RIGHT_CLICK_BLOCK
- Calls `EnchantmentExecutor.executeOnInteract()`
- Consumes event if active enchantment triggers

##### EnchantmentEnchantTableListener
- Cancels PrepareItemEnchantEvent if item has custom enchantment
- Cancels EnchantItemEvent if item has custom enchantment
- Prevents vanilla enchanting UI from appearing on custom items

---

### 2.5 Threading & Async Pattern

**Critical Rule**: All enchantment effects must respect Paper threading:

1. **Enchantment Detection & Parsing**: Can run async (reads ItemStack lore)
2. **Cooldown Checks**: Async via `CooldownManager` port
3. **Potion Effects & Particle Effects**: **MUST** run on main thread via Bukkit scheduler
4. **HTTP calls (if API integration later)**: Async via CompletableFuture

**Pattern**:
```java
// In listener
@EventHandler(priority = EventPriority.LOWEST)
public void onEntityDamage(EntityDamageByEntityEvent event) {
    // ... validation ...
    
    // Async: parse enchantments from item lore
    enchantmentExecutor.executeOnMeleeHit(weapon, attacker, target, event.getDamage())
        .thenRunAsync(() -> {
            // Already scheduled on main thread by executor impl
        }, Bukkit.getScheduler().getMainThreadExecutor(plugin));
}
```

---

## 3. Detailed Enchantment Specifications

### 3.1 Attack Enchantments

#### **Poison**
- **Max Level**: 3
- **Trigger**: Melee hit
- **Probability**: 15% per level (0.15 * level)
- **Effect**: Applies Poison II potion effect for (level × 60) ticks
  - Level 1: 60 ticks = 3 seconds
  - Level 2: 120 ticks = 6 seconds
  - Level 3: 180 ticks = 9 seconds
- **Visual**: Potion break particle at target location
- **Cooldown**: None (0ms)

**Implementation**:
```java
public class PoisonEnchantmentEffect implements AttackEnchantmentEffect {
    @Override
    public void execute(ItemStack weapon, Player attacker, LivingEntity target, int level) {
        if (shouldTrigger(0.15 * level)) {
            target.getWorld().playEffect(target.getLocation(), Effect.POTION_BREAK, 0);
            target.addPotionEffect(
                new PotionEffect(PotionEffectType.POISON, level * 60, 1)
            );
        }
    }
    
    private boolean shouldTrigger(double probability) {
        return Math.random() < probability;
    }
}
```

#### **Wither**
- **Max Level**: 3
- **Trigger**: Melee hit
- **Probability**: 15% per level
- **Effect**: Applies Poison II for (level × 40) ticks + witch particle effect
- **Visual**: WITCH_MAGIC particles at attacker location (player position + Y offset 1.5)
- **Cooldown**: None

**Difference from Poison**: 
- Shorter duration (×40 vs ×60)
- Different particle (witch vs potion break)
- Particle emits from attacker, not target

#### **Freeze**
- **Max Level**: 3
- **Trigger**: Melee hit
- **Probability**: 15% per level
- **Effect**: Prevents target player movement for (level × 60) ticks
  - Only affects Player entities (check `instanceof Player`)
  - Non-player entities: no effect
- **Visual**: STEP_SOUND (ice particle) every 20 ticks at target location + 0.5 Y offset
- **Cooldown**: None
- **Special**: Registers listener to intercept PlayerMoveEvent
  - If frozen player moves, revert location to previous location
  - Check: only revert if player didn't "look around" (camera rotation)

**Implementation Note**: 
Freeze uses a HashSet<UUID> to track frozen players and prevents movement via event.setTo(event.getFrom()).

#### **Blindness**
- **Max Level**: 3
- **Trigger**: Melee hit
- **Probability**: 100% (always triggers, no randomness)
- **Effect**: Applies Blindness I for (level × 60) ticks
- **Visual**: Wither spawn sound at target location
- **Cooldown**: None

#### **Confusion**
- **Max Level**: 3
- **Trigger**: Melee hit
- **Probability**: 15% per level
- **Effect**: Applies Nausea III for (level × 60) ticks
- **Visual**: Potion break particle at target location
- **Cooldown**: None

#### **Strength**
- **Max Level**: 2
- **Trigger**: Melee hit
- **Probability**: 15% per level
- **Effect**: Grants attacker (not target!) Strength (level) for 15 seconds (300 ticks)
  - Level 1: Strength I
  - Level 2: Strength II
- **Visual**: Potion break particle at attacker location
- **Cooldown**: 120 seconds (120000ms)

**Critical**: Potion effect applies to **attacker** (player), not the entity being hit.

---

### 3.2 Active Enchantments (Right-Click)

#### **Chaos**
- **Max Level**: 1
- **Trigger**: Right-click with item in hand (PlayerInteractEvent)
- **Cooldown**: 90 seconds
- **AoE Radius**: 
  - Damage radius: 3 blocks
  - Knockback radius: 5 blocks
- **Effects**:
  - **Damage**: 40 damage to all LivingEntities within 3 blocks (except player)
    - Fires custom EntityDamageByEntityEvent with LIGHTNING cause
    - Can be cancelled by other plugins
  - **Knockback**: Applies velocity (away from player) to all entities within 5 blocks
    - Direction: `target.vec - player.vec` normalized, with Y=0.4
  - **Attacker immunity**: Removes fire ticks from attacker
  - **Sound**: AMBIENCE_THUNDER at attacker location
  - **Particles**: FIREWORKS_SPARK at attacker location (Y+1) with count 75

#### **Flash Chaos**
- **Max Level**: 1
- **Trigger**: Right-click with item in hand
- **Cooldown**: 90 seconds
- **AoE Radius**: 
  - Damage radius: 3 blocks
  - Knockback + potion radius: 5 blocks
- **Effects**:
  - **Damage**: 60 damage to LivingEntities within 3 blocks
  - **Knockback**: Same as Chaos
  - **Additional**: Applies Slowness I (100 ticks) and Nausea II (250 ticks) to Players in 5-block radius
  - **Attacker immunity**: Removes fire ticks
  - **Sound & Particles**: Same as Chaos

**Key Difference**: Flash Chaos deals more damage (60 vs 40) and also applies debuffs to player targets.

#### **Health Boost**
- **Max Level**: 1
- **Trigger**: Right-click
- **Cooldown**: 120 seconds
- **Duration**: 5 ticks (executes 6 times over 25 ticks)
- **Effect**: Restores (level) health per tick, capped at 20 HP max
  - Loops: runs every 5 ticks for 6 iterations = 30 ticks total (1.5 seconds)
  - Each iteration: `newHealth = currentHealth + level`
  - Cap: `if (newHealth > 20) newHealth = 20`
- **Visual**: HEART particles at player location (Y+1.5) every tick
- **Cooldown**: 120 seconds (120000ms)

**Note**: Max level is 1, so always restores exactly 1 HP per tick (6 HP total over 1.5s).

#### **Armor Repair**
- **Max Level**: 1
- **Trigger**: Right-click
- **Cooldown**: 120 seconds
- **Effect**: Fully repairs (sets durability to 0) all worn armor pieces
  - Iterates through `player.getInventory().getArmorContents()`
  - Sets durability of each piece to 0 (full HP)
  - Calls `player.updateInventory()`
- **Sound**: ANVIL_USE at player location
- **Cooldown**: 120 seconds

#### **Resistance**
- **Max Level**: 2
- **Trigger**: Right-click
- **Cooldown**: 120 seconds
- **Effect**: Applies Damage Resistance potion effect
  - Duration: (level × 100 + 100) ticks
    - Level 1: 200 ticks = 10 seconds
    - Level 2: 300 ticks = 15 seconds
  - Amplifier: level (level I for level 1, level II for level 2)
- **Visual**: None specified (standard potion effect visual)
- **Cooldown**: 120 seconds

#### **Invisibility**
- **Max Level**: 1
- **Trigger**: Right-click
- **Cooldown**: 90 seconds
- **Effect**: Applies Invisibility potion effect for 200 ticks (10 seconds)
  - Amplifier: 1
- **Visual**: Standard invisibility particle/effect
- **Cooldown**: 90 seconds

---

## 4. Enchantment Storage & Runtime Lore Format

### 4.1 Lore-Based Storage

Runtime item instances may include lore lines as an execution adapter, but canonical definitions and assignments belong to API entities:

- `EnchantmentDefinition` (custom entries have `IsCustom = true`)
- `ItemBlueprint` assignment relationship(s)
- User-instance skill assignments (future)

Lore format remains supported for plugin-side runtime behavior:

**Format**:
```
§7<Enchantment Name> <Roman Numeral Level>
```

**Examples**:
```
§7Poison I
§7Poison II
§7Poison III
§7Chaos I
§7Health Boost I
§7Strength II
```

**Roman Numeral Mapping**:
- 1 → I
- 2 → II
- 3 → III

**Detection**:
- Parse each lore line
- Strip color codes
- Match against enchantment names + level pattern
- Extract level from parsed string

---

### 4.2 Implementation Strategy

1. **Item Metadata**: Use `ItemStack.getItemMeta().getLore()`
2. **Add Enchantment**: Append new lore line to existing lore
3. **Remove Enchantment**: Filter out lore line containing enchantment name
4. **Check Existence**: Search lore for enchantment name prefix with color code `§7`

---

## 5. Permission System

### 5.1 Permission Structure

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

### 5.2 Permission Enforcement

- **Check before execution**: Call `player.hasPermission(ench.getPermission())`
- **No silent skip**: Show message if player lacks permission
- **Cooldown**: Rate-limit permission denied messages (60 ticks default)
  - Show message only once per 60 ticks even if player keeps triggering

### 5.3 Default Configuration

```yaml
settings:
  disable-for-creative: false  # If true, enchantments don't work in Creative mode
  permission-message-timeout: 60  # Ticks between permission denial messages
```

---

## 6. Commands

### 6.1 /ce (CustomEnchantments Root Command)

Base command with subcommands:

```
/ce help                              # Show help
/ce add <enchantment> <level>        # Add enchantment to held item
/ce remove <enchantment>              # Remove enchantment from held item
/ce info [player]                     # Show enchantments on held item
/ce cooldown clear [player]           # Admin: clear cooldowns
/ce reload                            # Reload config
```

#### **/ce add <enchantment> <level>**
- Adds enchantment to item in hand
- Validates level ≤ max level for enchantment
- Error: "Cannot add <ench>, max level is X"
- Success: "Enchantment was added to item successfully"
- Requires permission: `customenchantments.command`

#### **/ce remove <enchantment>**
- Removes enchantment from item in hand
- Success: "Enchantment was removed from item successfully"
- Requires permission: `customenchantments.command`

#### **/ce info**
- Lists all enchantments on held item with levels
- Also works on other players' items (if held by them)

#### **/ce cooldown clear [player]**
- Admin command to clear all active cooldowns
- Success: "Removed cooldowns for <player>"

#### **/ce reload**
- Reloads config.yml
- Success: "Plugin configuration was reloaded"

---

## 7. Error Messages & Configuration

### 7.1 Message Keys (config.yml)

```yaml
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

### 7.2 Configuration Structure

```yaml
settings:
  disable-for-creative: false
  permission-message-timeout: 60
messages:
  # ... as above ...
```

---

## 8. Implementation Priorities & Sequencing

### Phase 1: Core Infrastructure
1. Define enchantment domain models and ports in `knk-core`
2. Create `EnchantmentRegistry` (list all 12 enchantments with metadata)
3. Implement `LocalEnchantmentRepositoryImpl` (lore-based storage)
4. Implement `CooldownManager` (in-memory per-player tracking)

### Phase 2: Passive Enchantments (Attack)
1. Create effect base classes: `AttackEnchantmentEffect`
2. Implement: Poison, Wither, Freeze, Blindness, Confusion, Strength
3. Create `EnchantmentCombatListener` (EntityDamageByEntityEvent)
4. Create `EnchantmentEnchantTableListener` (prevent re-enchanting)

### Phase 3: Active Enchantments (Right-Click)
1. Implement: Health Boost, Armor Repair, Resistance, Invisibility
2. Implement: Chaos, Flash Chaos
3. Create `EnchantmentInteractListener` (PlayerInteractEvent)

### Phase 4: Commands & Admin
1. Implement `/ce add`, `/ce remove`, `/ce info`
2. Implement `/ce cooldown clear`
3. Add permission checks

### Phase 5: Polish & Documentation
1. Improve particle/sound selection for better visuals
2. Add configuration options for cooldown durations
3. Create in-game help system
4. Document all features in wiki/in-game help

---

## 9. Known Limitations & Future Improvements

### 9.1 Current Limitations
- **Skill Attachment Not Implemented Yet**: User-instance personal skill attachment is planned but not yet available.
- **No Enchantment Trading**: No market/auction system for enchanted items
- **No Durability Loss**: Enchanted weapons don't lose durability faster
- **Limited Scaling**: Max levels capped at 1-3; no dynamic balance
- **Bow Enchantments**: Not yet designed (hooks exist in code but no implementations)

### 9.2 Future Enhancements
1. **Enchantment Combining**: Combine lower-level enchantments into higher levels
2. **Enchantment Books**: Separate enchantments into books for trading
3. **Durability Trade-off**: Enchantments consume additional durability
4. **Rarity Tiers**: Common, Rare, Epic, Legendary enchantment rarities
5. **Player Statistics**: Track enchantment usage (most-used, most-valuable, etc.)
6. **Armor Enchantments**: Enchantments that trigger when wearing armor (passive defense)
7. **Bow Enchantments**: Poison arrows, fire arrows, teleport arrows, etc.

---

## 10. Testing Strategy

### 10.1 Unit Tests (knk-core)
- `EnchantmentRepositoryTest`: Test lore parsing and enchantment detection
- `CooldownManagerTest`: Test cooldown application and expiration
- `EnchantmentRegistryTest`: Verify all 12 enchantments registered correctly

### 10.2 Integration Tests (knk-paper)
- `EnchantmentCombatListenerTest`: Verify effects trigger on hit
- `EnchantmentInteractListenerTest`: Verify right-click activation
- `CooldownEnforcementTest`: Verify cooldown prevents repeated activation
- `PermissionEnforcementTest`: Verify permission checks block unauthorized use

### 10.3 Manual Testing Checklist
- [ ] Apply all 12 enchantments to test items
- [ ] Verify passive enchantments trigger on melee hit
- [ ] Verify active enchantments trigger on right-click
- [ ] Test cooldown messages appear correctly
- [ ] Test permission denial messages
- [ ] Test `/ce add`, `/ce remove`, `/ce info` commands
- [ ] Test `/ce cooldown clear` command
- [ ] Test Freeze: movement prevention and cancel with look
- [ ] Test Chaos: proper knockback radius and direction
- [ ] Test Flash Chaos: debuff application to players only
- [ ] Test Armor Repair: all armor pieces fully repaired
- [ ] Test with Creative mode enabled and disabled

---

## 11. References & Source Materials

- **Original Plugin**: CustomEnchantments-1.0.3.jar (decompiled source)
- **KnK Architecture**: knk-plugin-v2 design (see ARCHITECTURE_AUDIT.md, MIGRATION_MODE_READONLY.md)
- **Threading Guidance**: docs/API_CLIENT_PATTERN.md
- **Configuration Pattern**: knk-paper Paper plugin adapter layer

---

## 12. Questions & TODOs

### 12.1 Open Questions
1. **Bow Enchantments**: Should enchanted bows have special projectile effects? (Not in original plugin)
2. **Armor Enchantments**: Should wearing armor with enchantments grant passive effects? (Original only has interact-based)
3. **API Persistence Detail**: Confirm exact API assignment contracts for `ItemBlueprint` and future user skills.
4. **Stacking**: Can a single item have multiple different enchantments? (Original: yes)
5. **Level Caps**: Should there be a global max enchantment level or per-enchantment caps? (Original: per-enchantment)

### 12.2 Implementation TODOs
- [ ] Add enchantment ID constants (e.g., `"poison"`, `"chaos"`)
- [ ] Design Enchantment UI/inventory menu for easier selection
- [ ] Create sound effect customization in config
- [ ] Add particle effect customization in config
- [ ] Design cooldown notification UI (actionbar, title, or chat)
- [ ] Consider ProtocolLib integration for better packet-level effects
- [ ] Define migration/backfill strategy from legacy plugin-only enchantment lore into `EnchantmentDefinition` (`IsCustom = true`) and assignment entities.

