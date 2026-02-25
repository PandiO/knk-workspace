# Custom Enchantments – Implementation Roadmap

**Document Version**: 1.1  
**Date**: January 11, 2026  
**Updated**: February 25, 2026  
**Status**: DRAFT  
**Target Release**: Knights & Kings v2 Phase 2

---

## Overview

This roadmap outlines the step-by-step implementation plan for integrating the **Custom Enchantments** system as a **shared ability model** across v2.

Canonical rules for this roadmap:
- Custom abilities are represented by `EnchantmentDefinition` rows with `IsCustom = true`.
- Custom ability metadata should be modeled as an optional extension entity (e.g., `AbilityDefinition`) linked 1:1 to `EnchantmentDefinition`.
- Ability assignments must support `ItemBlueprint` attachment.
- Ability assignments must support future user-instance personal skill attachment (feature planned, not implemented).
- Plugin lore/event logic is runtime adapter behavior, not canonical persistence.

### Implementation Progress (as of 2026-02-25)

- ✅ Phase 1.1 completed: Domain models added in `knk-core` under `core/domain/enchantment`.
- ✅ Phase 1.2 completed: Port interfaces added in `knk-core` under `core/ports/enchantment` with `CompletableFuture` contracts and no Bukkit imports.
- ✅ Phase 1.3 completed: `EnchantmentRegistry` implemented with all 12 roadmap enchantments and type/level lookup helpers.
- ✅ Phase 1.4 completed: `LocalEnchantmentRepositoryImpl` added in `knk-api-client` as lore runtime adapter.
- ✅ Phase 1.5 completed: `InMemoryCooldownManager` added in `knk-paper`.
- ✅ Unit tests added for registry, lore parsing/apply/remove behavior, and cooldown logic.
- ✅ Phase 2.1 completed: optional `AbilityDefinition` extension entity added with 1:1 navigation to `EnchantmentDefinition`.
- ✅ Phase 2.2 completed: custom-only invariant checks implemented in `EnchantmentDefinitionService` and DB uniqueness/FK constraints added.
- ✅ Phase 2.3 completed: user-assignment hook placeholder added via `AbilityDefinition.FutureUserAssignmentContract` and DTO contract updates.
- ✅ Phase 3 completed (passive attack runtime): added `EnchantmentEffect`/`AttackEnchantmentEffect` contract and passive effect implementations (`Poison`, `Wither`, `Freeze`, `Blindness`, `Confusion`, `Strength`) in `knk-paper`.
- ✅ Phase 3 completed (event integration): added `EnchantmentCombatListener`, `EnchantmentEnchantTableListener`, `FreezeMovementListener`, and runtime wiring in `KnKPlugin`.
- ✅ Phase 3 unit coverage added: deterministic probability and effect application tests for passive effects in `knk-paper` test module.

---

## Project Structure & Modules

### knk-core
**Responsibility**: Domain models, port interfaces, business logic (no Bukkit imports)

```
src/main/java/net/knightsandkings/knk/core/
├── domain/
│   └── enchantment/
│       ├── Enchantment.java                    # record: id, displayName, maxLevel, cooldownMs, type, probability
│       ├── EnchantmentInstance.java            # record: enchantmentId, level
│       ├── EnchantmentType.java                # enum: ATTACK, SUPPORT, UTILITY
│       ├── CooldownState.java                  # record: playerId, enchantmentId, expiryTimeMs
│       └── EnchantmentRegistry.java            # singleton with all 12 enchantment definitions
├── ports/
│   └── enchantment/
│       ├── EnchantmentRepository.java          # Port: load/save/check enchantments on items
│       ├── EnchantmentExecutor.java            # Port: dispatch enchantment effects
│       └── CooldownManager.java                # Port: track & enforce cooldowns per player
└── services/
    └── enchantment/
        └── EnchantmentValidationService.java   # Validate enchantment levels, permissions, etc.
```

### knk-api-client
**Responsibility**: API-backed definition/assignment access + runtime adapter implementations

```
src/main/java/net/knightsandkings/knk/api/
└── impl/
    └── enchantment/
        └── LocalEnchantmentRepositoryImpl.java  # Lore-based runtime adapter (non-canonical)
```

### knk-paper
**Responsibility**: Bukkit/Paper runtime execution (effects/listeners/commands/bootstrap)

### knk-web-api-v2 (required alignment)
**Responsibility**: Canonical definitions and attachment relationships
- `EnchantmentDefinition` (custom abilities: `IsCustom = true`)
- Optional `AbilityDefinition` extension entity linked to `EnchantmentDefinition`
- `ItemBlueprint` assignment compatibility
- User-instance skill assignment contract (placeholder until skill feature is built)

### knk-web-app (required alignment)
**Responsibility**: CRUD/management surfaces for custom ability definitions and attachments

```
src/main/java/net/knightsandkings/knk/paper/
├── enchantment/
│   ├── EnchantmentManager.java                 # Facade: wires together all enchantment services
│   ├── EnchantmentRegistry.java                # Builds map of enchantment ID → effect handler
│   ├── effects/
│   │   ├── EnchantmentEffect.java              # Base interface for all effects
│   │   ├── AttackEnchantmentEffect.java        # Base for passive on-hit effects
│   │   ├── SupportEnchantmentEffect.java       # Base for right-click active effects
│   │   ├── impl/
│   │   │   ├── PoisonEffect.java
│   │   │   ├── WitherEffect.java
│   │   │   ├── FreezeEffect.java
│   │   │   ├── BlindnessEffect.java
│   │   │   ├── ConfusionEffect.java
│   │   │   ├── StrengthEffect.java
│   │   │   ├── HealthBoostEffect.java
│   │   │   ├── ArmorRepairEffect.java
│   │   │   ├── ResistanceEffect.java
│   │   │   ├── InvisibilityEffect.java
│   │   │   ├── ChaosEffect.java
│   │   │   └── FlashChaosEffect.java
│   │   └── FrozenPlayerTracker.java            # Tracks frozen players (Freeze enchantment)
│   └── ExecutorImpl.java                        # Implements EnchantmentExecutor port
├── listeners/
│   ├── EnchantmentCombatListener.java          # EntityDamageByEntityEvent
│   ├── EnchantmentInteractListener.java        # PlayerInteractEvent
│   ├── EnchantmentEnchantTableListener.java    # Prevent re-enchanting
│   └── FreezeMovementListener.java             # PlayerMoveEvent for Freeze effect
├── commands/
│   ├── EnchantmentCommandHandler.java          # /ce dispatcher
│   ├── subcommands/
│   │   ├── AddEnchantmentCommand.java          # /ce add
│   │   ├── RemoveEnchantmentCommand.java       # /ce remove
│   │   ├── InfoEnchantmentCommand.java         # /ce info
│   │   ├── ReloadEnchantmentCommand.java       # /ce reload
│   │   └── ClearCooldownCommand.java           # /ce cooldown clear
│   └── EnchantmentCommandValidator.java        # Shared validation
├── bootstrap/
│   └── EnchantmentBootstrap.java               # Wires up all listeners, commands, port impls
└── config/
    └── EnchantmentConfigManager.java           # Loads config.yml, provides messages
```

---

## Phase 1: Core Infrastructure & Models

### Task 1.1: Define Domain Models (knk-core)

**Deliverables**:
- `Enchantment.java` (record)
- `EnchantmentInstance.java` (record)
- `EnchantmentType.java` (enum)
- `CooldownState.java` (record)

**Acceptance Criteria**:
- All records are immutable
- Enums are properly defined with no Bukkit imports
- Can create instances without errors

**Estimated Effort**: 2 hours

---

### Task 1.2: Define Port Interfaces (knk-core)

**Deliverables**:
- `EnchantmentRepository.java` (port interface with CompletableFuture methods)
- `EnchantmentExecutor.java` (port interface)
- `CooldownManager.java` (port interface)

**Acceptance Criteria**:
- All methods return `CompletableFuture<T>`
- No Bukkit imports in ports
- JavaDoc clearly describes contract for each method
- Matches async pattern from docs/API_CLIENT_PATTERN.md

**Estimated Effort**: 3 hours

---

### Task 1.3: Create EnchantmentRegistry (knk-core)

**Deliverables**:
- `EnchantmentRegistry.java` singleton class

**Responsibility**:
- Defines all 12 enchantments as static `Enchantment` records
- Provides getters: `getById(id)`, `getAll()`, `getByType(type)`
- Validates enchantment exists and level is ≤ max

**Enchantments to Define**:
```
1. poison          (max: 3, type: ATTACK, cooldown: 0ms, probability: 0.15)
2. wither          (max: 3, type: ATTACK, cooldown: 0ms, probability: 0.15)
3. freeze          (max: 3, type: ATTACK, cooldown: 0ms, probability: 0.15)
4. blindness       (max: 3, type: ATTACK, cooldown: 0ms, probability: null/always)
5. confusion       (max: 3, type: ATTACK, cooldown: 0ms, probability: 0.15)
6. strength        (max: 2, type: ATTACK, cooldown: 120000ms, probability: 0.15)
7. chaos           (max: 1, type: SUPPORT, cooldown: 90000ms, probability: null)
8. flash_chaos     (max: 1, type: SUPPORT, cooldown: 90000ms, probability: null)
9. health_boost    (max: 1, type: SUPPORT, cooldown: 120000ms, probability: null)
10. armor_repair   (max: 1, type: SUPPORT, cooldown: 120000ms, probability: null)
11. resistance     (max: 2, type: SUPPORT, cooldown: 120000ms, probability: null)
12. invisibility   (max: 1, type: SUPPORT, cooldown: 90000ms, probability: null)
```

**Acceptance Criteria**:
- All 12 enchantments registered
- Lookups by ID return correct metadata
- No Bukkit imports

**Estimated Effort**: 2 hours

---

### Task 1.4: Implement LocalEnchantmentRepositoryImpl (knk-api-client)

**Deliverables**:
- `LocalEnchantmentRepositoryImpl.java`

**Responsibility**:
- Implements `EnchantmentRepository` port
- Adapts runtime enchantments to/from item lore (format: `§7<Name> <RomanLevel>`)
- Adds/removes enchantments from lore for plugin runtime compatibility
- Returns CompletableFuture (complete immediately, no actual async I/O)

**Important**:
- This is not canonical persistence.
- Canonical custom ability definitions are `EnchantmentDefinition` with `IsCustom = true`.

**Key Methods**:
```java
// Parse lore and extract all enchantments
CompletableFuture<Map<String, Integer>> getEnchantments(ItemStack item)

// Check if any custom enchantment exists on item
CompletableFuture<Boolean> hasAnyEnchantment(ItemStack item)

// Check specific enchantment
CompletableFuture<Boolean> hasEnchantment(ItemStack item, String enchantmentId)

// Add enchantment to lore
CompletableFuture<ItemStack> applyEnchantment(ItemStack item, String enchantmentId, Integer level)

// Remove from lore
CompletableFuture<ItemStack> removeEnchantment(ItemStack item, String enchantmentId)
```

**Helper Utilities**:
- `stringToLevel(s)`: "I" → 1, "II" → 2, "III" → 3
- `levelToString(i)`: 1 → "I", 2 → "II", 3 → "III"
- `stripColor(s)`: Remove color codes from lore string
- `parseEnchantmentName(s)`: Extract enchantment ID and level from lore line

**Acceptance Criteria**:
- Correctly parses all lore formats
- Adds/removes without corrupting other lore
- Returns CompletableFuture (async pattern)
- Unit tests pass for all parsing scenarios

**Estimated Effort**: 4 hours

---

### Task 1.5: Implement in-memory CooldownManager (knk-paper)

**Deliverables**:
- `InMemoryCooldownManager.java` (implements `CooldownManager` port)

**Responsibility**:
- Track active cooldowns per player per enchantment
- `getRemainingCooldown(playerId, enchantmentId)`: returns ms remaining or 0
- `applyCooldown(playerId, enchantmentId, durationMs)`: start cooldown
- `clearCooldowns(playerId)`: remove all cooldowns for player

**Implementation**:
- Use `HashMap<UUID, Map<String, Long>>` for `playerId → enchantmentId → expiryTimeMs`
- Check `System.currentTimeMillis()` against expiry to determine remaining time
- Auto-cleanup: remove entries when expired (or lazy-cleanup on lookup)

**Acceptance Criteria**:
- Cooldowns correctly tracked per player
- Expiry times correctly calculated
- Thread-safe (use concurrent maps if needed)
- Unit tests verify cooldown logic

**Estimated Effort**: 2 hours

---

## Phase 2: Optional Ability Extension Model (API-first)

### Task 2.1: Add Ability Extension Entity (knk-web-api-v2)

**Deliverables**:
- `AbilityDefinition` (or similarly named) model entity
- Optional 1:1 navigation: `EnchantmentDefinition -> AbilityDefinition?`
- Reverse navigation: `AbilityDefinition -> EnchantmentDefinition`

**Responsibility**:
- Keep `EnchantmentDefinition` as canonical parent for vanilla and custom entries
- Store custom-only behavior metadata in the extension entity
- Ensure the extension remains optional and non-breaking for vanilla enchantments

**Acceptance Criteria**:
- Vanilla `EnchantmentDefinition` rows work without extension rows
- Custom entries can include extension metadata via navigation
- ORM mapping supports optional 1:1 relationship cleanly

**Estimated Effort**: 3 hours

---

### Task 2.2: Enforce Domain Invariants (knk-web-api-v2)

**Deliverables**:
- Service/repository validation rules
- DB-level uniqueness/foreign-key constraints for 1:1 mapping

**Responsibility**:
- Enforce `AbilityDefinition` allowed only when `EnchantmentDefinition.IsCustom = true`
- Prevent multiple extension rows for the same enchantment definition

**Acceptance Criteria**:
- Invalid custom/non-custom combinations are rejected
- 1:1 uniqueness is enforced

**Estimated Effort**: 2 hours

---

### Task 2.3: Prepare User-Based Relationship Hooks (knk-web-api-v2)

**Deliverables**:
- Placeholder assignment contract (entity or documented stub) for future user-skill linking
- Updated relationship notes for `ItemBlueprint` and user-side assignment parity

**Responsibility**:
- Keep implementation scope minimal (no full skill feature)
- Define the attach-point so user-based system can integrate without schema refactor

**Acceptance Criteria**:
- Roadmap/spec references are aligned on future user assignment shape
- No regression in current `ItemBlueprint` assignment behavior

**Estimated Effort**: 1 hour

---

## Phase 3: Passive Attack Enchantments

### Task 2.1: Create Effect Base Classes (knk-paper)

**Deliverables**:
- `EnchantmentEffect.java` (interface)
- `AttackEnchantmentEffect.java` (base class)

**Responsibility**:
- Define contract for all effect implementations
- `execute(weapon, attacker, target, level)` method signature
- Helper methods for particle/sound effects

**Acceptance Criteria**:
- Clear contract for implementations
- Proper Bukkit imports

**Estimated Effort**: 1 hour

---

### Task 2.2: Implement Poison Effect (knk-paper)

**Deliverables**:
- `PoisonEffect.java`

**Specs**:
- Trigger probability: 15% per level
- Effect: Poison II for (level × 60) ticks
- Particle: POTION_BREAK at target location
- Cooldown: None

**Unit Tests**:
- Verify probability calculation
- Verify potion effect duration
- Verify particle plays

**Estimated Effort**: 1.5 hours

---

### Task 2.3: Implement Wither Effect (knk-paper)

**Deliverables**:
- `WitherEffect.java`

**Specs**:
- Trigger probability: 15% per level
- Effect: Poison II for (level × 40) ticks
- Particle: WITCH_MAGIC at attacker location (Y+1.5)
- Cooldown: None

**Estimated Effort**: 1.5 hours

---

### Task 2.4: Implement Freeze Effect (knk-paper)

**Deliverables**:
- `FreezeEffect.java`
- `FrozenPlayerTracker.java` (tracks frozen players)
- `FreezeMovementListener.java` (intercepts PlayerMoveEvent)

**Specs**:
- Trigger probability: 15% per level
- Only affects Player entities
- Prevent movement for (level × 60) ticks
- Particle: STEP_SOUND every 20 ticks at target location (Y+0.5)
- Handle "look around" exception (don't block if only camera rotates)

**Special Implementation Note**:
- Register separate listener for PlayerMoveEvent
- Use HashSet<UUID> to track frozen players
- Check PlayerLookEvent or similar to allow camera rotation without movement cancellation

**Acceptance Criteria**:
- Player can't move while frozen
- Camera rotation doesn't break freeze
- Freezing expires correctly

**Estimated Effort**: 3 hours

---

### Task 2.5: Implement Blindness Effect (knk-paper)

**Deliverables**:
- `BlindnessEffect.java`

**Specs**:
- Always triggers (100%, no probability)
- Effect: Blindness I for (level × 60) ticks
- Sound: WITHER_SPAWN at target location
- Cooldown: None

**Estimated Effort**: 1 hour

---

### Task 2.6: Implement Confusion Effect (knk-paper)

**Deliverables**:
- `ConfusionEffect.java`

**Specs**:
- Trigger probability: 15% per level
- Effect: Nausea III for (level × 60) ticks
- Particle: POTION_BREAK at target location
- Cooldown: None

**Estimated Effort**: 1 hour

---

### Task 2.7: Implement Strength Effect (knk-paper)

**Deliverables**:
- `StrengthEffect.java`

**Specs**:
- Trigger probability: 15% per level
- Effect: Strength (level) for 300 ticks (15 seconds) applied to **attacker**
- Particle: POTION_BREAK at attacker location
- Cooldown: 120 seconds (enforced via CooldownManager)

**Critical**: Effect applies to attacker, not target!

**Estimated Effort**: 1.5 hours

---

### Task 2.8: Create EntityDamageByEntityEvent Listener (knk-paper)

**Deliverables**:
- `EnchantmentCombatListener.java`

**Responsibility**:
- Listens to EntityDamageByEntityEvent (priority: LOWEST)
- Validates attacker is Player with item in hand
- Checks Creative mode setting
- Calls EnchantmentExecutor to dispatch passive effects

**Flow**:
1. Get attacker's held item
2. Parse enchantments from item lore
3. For each enchantment: check permission, then execute
4. All effect execution via main thread scheduler

**Acceptance Criteria**:
- Listens to correct event
- Properly filters by attacker + item
- Dispatches to executor correctly
- No memory leaks from listeners

**Estimated Effort**: 2 hours

---

### Task 2.9: Create EnchantmentEnchantTableListener (knk-paper)

**Deliverables**:
- `EnchantmentEnchantTableListener.java`

**Responsibility**:
- Listens to PrepareItemEnchantEvent + EnchantItemEvent
- Prevents vanilla enchanting on items with custom enchantments
- Cancels both events if custom enchantment detected

**Acceptance Criteria**:
- Custom items can't be re-enchanted
- Vanilla items can still be enchanted normally

**Estimated Effort**: 1 hour

---

## Phase 4: Active Support Enchantments

### Task 3.1: Create SupportEnchantmentEffect Base (knk-paper)

**Deliverables**:
- `SupportEnchantmentEffect.java` (base class)

**Responsibility**:
- Extends `EnchantmentEffect`
- Provides helper methods for right-click activation

**Estimated Effort**: 1 hour

---

### Task 3.2: Implement Support Enchantment Effects (knk-paper)

**Deliverables**:
- `HealthBoostEffect.java`
- `ArmorRepairEffect.java`
- `ResistanceEffect.java`
- `InvisibilityEffect.java`

**Implementation Strategy**: Similar to attack effects, but with:
- No target entity (only affects player)
- Uses Bukkit scheduler for delayed/repeated effects (Health Boost)
- Checks cooldown before execution

**HealthBoost Specs**:
- Runs 6 iterations, 5 ticks apart
- Each iteration: `health += level` (max 20)
- Particle: HEART at player location (Y+1.5)
- Cooldown: 120s

**ArmorRepair Specs**:
- Set durability to 0 for all armor pieces
- Sound: ANVIL_USE
- Update inventory
- Cooldown: 120s

**ResistanceEffect Specs**:
- Applies Damage Resistance (level) for (level × 100 + 100) ticks
- Cooldown: 120s

**InvisibilityEffect Specs**:
- Applies Invisibility for 200 ticks
- Cooldown: 90s

**Estimated Effort**: 4 hours total

---

### Task 3.3: Implement Chaos Effects (knk-paper)

**Deliverables**:
- `ChaosEffect.java`
- `FlashChaosEffect.java`

**Specs**:

**Chaos**:
- AoE: damage 3 blocks, knockback 5 blocks
- Damage: 40 to LivingEntities within 3 blocks (fire EntityDamageByEntityEvent)
- Knockback: Apply velocity to entities within 5 blocks (dir: away from player, Y: 0.4)
- Remove fire ticks from attacker
- Sound: AMBIENCE_THUNDER
- Particle: FIREWORKS_SPARK at player location (Y+1), count 75
- Cooldown: 90s

**Flash Chaos**:
- AoE: damage 3 blocks, debuff 5 blocks
- Damage: 60 to LivingEntities within 3 blocks
- Debuff: Slowness I (100 ticks) + Nausea II (250 ticks) to Players only
- Knockback: Same as Chaos
- Same sound & particles
- Cooldown: 90s

**Special Notes**:
- Fire EntityDamageByEntityEvent that other plugins can cancel
- Check event.isCancelled() before applying knockback
- Only apply debuffs to Player targets (check instanceof)

**Estimated Effort**: 3 hours

---

### Task 3.4: Create PlayerInteractEvent Listener (knk-paper)

**Deliverables**:
- `EnchantmentInteractListener.java`

**Responsibility**:
- Listens to PlayerInteractEvent (RIGHT_CLICK_AIR + RIGHT_CLICK_BLOCK)
- Gets item in player's hand
- Parses enchantments
- For each active enchantment: check permission + cooldown, then execute
- Consumes event if enchantment triggered

**Cooldown Message Format**:
```
&cXX seconds remaining
```

**Acceptance Criteria**:
- Detects right-click correctly
- Enforces cooldowns with messages
- Prevents repeated activation on cooldown
- Consumes event when enchantment triggers

**Estimated Effort**: 2 hours

---

## Phase 5: Commands & Administration

### Task 4.1: Design Command Structure (knk-paper)

**Deliverables**:
- Command class hierarchy
- Validation framework

**Responsibility**:
- `/ce add <enchantment> <level>`
- `/ce remove <enchantment>`
- `/ce info`
- `/ce cooldown clear [player]`
- `/ce reload`

**Estimated Effort**: 1 hour (design only)

---

### Task 4.2: Implement Command Handler & Subcommands (knk-paper)

**Deliverables**:
- `EnchantmentCommandHandler.java` (dispatcher)
- `AddEnchantmentCommand.java`
- `RemoveEnchantmentCommand.java`
- `InfoEnchantmentCommand.java`
- `ClearCooldownCommand.java`
- `ReloadCommand.java`
- `EnchantmentCommandValidator.java`

**Key Features**:
- Player-only checks
- Item-in-hand validation
- Enchantment ID validation
- Level range validation
- Permission checks
- Error message localization from config

**Acceptance Criteria**:
- All commands functional and tested
- Error messages match config
- Permission checks work
- Subcommand dispatching works

**Estimated Effort**: 4 hours

---

## Phase 6: Configuration & Bootstrap

### Task 5.1: Design Configuration Format

**Deliverables**:
- `EnchantmentConfigManager.java`
- `config.yml` template

**Responsibility**:
- Load messages from config.yml
- Provide `getMessage(key, varargs)` with placeholder replacement
- Load settings (creative mode, permission timeout)

**Acceptance Criteria**:
- Config loads without errors
- All message keys populated
- Placeholders replaced correctly

**Estimated Effort**: 1 hour

---

### Task 5.2: Create Bootstrap Wiring (knk-paper)

**Deliverables**:
- `EnchantmentBootstrap.java`

**Responsibility**:
- Called from main `KnKPlugin.onEnable()`
- Instantiates all listeners, commands, managers
- Wires up executor port implementations
- Registers event handlers with Bukkit
- Registers commands with plugin command executor

**Flow**:
```java
public void initialize(Plugin plugin) {
    // 1. Load config
    EnchantmentConfigManager configMgr = new EnchantmentConfigManager(plugin);
    
    // 2. Create in-memory implementations
    EnchantmentRepository repo = new LocalEnchantmentRepositoryImpl();
    CooldownManager cooldowns = new InMemoryCooldownManager();
    
    // 3. Create executor
    EnchantmentExecutor executor = new ExecutorImpl(
        repo, cooldowns, configMgr, plugin.getLogger()
    );
    
    // 4. Register listeners
    plugin.getPluginManager().registerEvents(
        new EnchantmentCombatListener(executor, configMgr), 
        plugin
    );
    plugin.getPluginManager().registerEvents(
        new EnchantmentInteractListener(executor, configMgr, cooldowns),
        plugin
    );
    // ... more listeners ...
    
    // 5. Register commands
    plugin.getCommand("ce").setExecutor(
        new EnchantmentCommandHandler(repo, cooldowns, configMgr)
    );
}
```

**Acceptance Criteria**:
- All components initialized correctly
- No null pointer exceptions
- Listeners registered to correct events
- Commands accessible via `/ce`

**Estimated Effort**: 1 hour

---

## Phase 7: Testing & Quality Assurance

### Task 6.1: Unit Tests (knk-core)

**Deliverables**:
- `EnchantmentRegistryTest.java`
- `LocalEnchantmentRepositoryImplTest.java`
- `InMemoryCooldownManagerTest.java`

**Coverage**:
- Enchantment registry: all 12 registered, metadata correct
- Repository: parse lore correctly, add/remove without corruption
- Cooldown manager: track expiry, calculate remaining time

**Estimated Effort**: 4 hours

---

### Task 6.2: Integration Tests (knk-paper)

**Deliverables**:
- `EnchantmentCombatListenerTest.java`
- `EnchantmentInteractListenerTest.java`
- `EnchantmentEffectsIntegrationTest.java`

**Coverage**:
- Passive effects trigger on hit
- Active effects trigger on right-click
- Cooldowns enforced correctly
- Permissions respected

**Estimated Effort**: 5 hours

---

### Task 6.3: Manual Testing & Bug Fixes

**Checklist**:
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

**Estimated Effort**: 8 hours

---

## Phase 8: Documentation & Release

### Task 7.1: Create In-Game Help System

**Deliverables**:
- `/ce help` command output
- In-game enchantment guide (inventory menu or book)

**Estimated Effort**: 2 hours

---

### Task 7.2: Write Implementation Documentation

**Deliverables**:
- Developer guide: how to add new enchantments
- Admin guide: config options, permission setup
- Player guide: how to use enchantments

**Estimated Effort**: 2 hours

---

## Summary Table

| Phase | Task | Estimated Hours | Status |
|---|---|---|---|
| 1 | Domain Models | 2 | Completed |
| 1 | Port Interfaces | 3 | Completed |
| 1 | EnchantmentRegistry | 2 | Completed |
| 1 | LocalEnchantmentRepositoryImpl | 4 | Completed |
| 1 | CooldownManager | 2 | Completed |
| **Phase 1 Total** | | **13** | |
| 2 | Ability extension entity | 3 | Completed |
| 2 | Domain invariants + constraints | 2 | Completed |
| 2 | User assignment hooks | 1 | Completed |
| **Phase 2 Total** | | **6** | |
| 3 | Effect Base Classes | 1 | Not Started |
| 3 | Poison Effect | 1.5 | Not Started |
| 3 | Wither Effect | 1.5 | Not Started |
| 3 | Freeze Effect | 3 | Not Started |
| 3 | Blindness Effect | 1 | Not Started |
| 3 | Confusion Effect | 1 | Not Started |
| 3 | Strength Effect | 1.5 | Not Started |
| 3 | Combat Listener | 2 | Not Started |
| 3 | Enchant Table Listener | 1 | Not Started |
| **Phase 3 Total** | | **14.5** | |
| 4 | Support Effect Base | 1 | Not Started |
| 4 | Support Effects (4) | 4 | Not Started |
| 4 | Chaos Effects (2) | 3 | Not Started |
| 4 | Interact Listener | 2 | Not Started |
| **Phase 4 Total** | | **10** | |
| 5 | Command Design | 1 | Not Started |
| 5 | Command Implementation | 4 | Not Started |
| **Phase 5 Total** | | **5** | |
| 6 | Config Manager | 1 | Not Started |
| 6 | Bootstrap | 1 | Not Started |
| **Phase 6 Total** | | **2** | |
| 7 | Unit Tests | 4 | Not Started |
| 7 | Integration Tests | 5 | Not Started |
| 7 | Manual Testing | 8 | Not Started |
| **Phase 7 Total** | | **17** | |
| 8 | Help System | 2 | Not Started |
| 8 | Documentation | 2 | Not Started |
| **Phase 8 Total** | | **4** | |
| | | | |
| **Grand Total** | | **71.5 hours** | |

---

## Dependency Graph

```
Phase 1 (Core Infrastructure)
    ↓
Phase 2 (Optional Ability Extension Model)
    ↓
Phase 3 (Passive Enchantments) + Phase 4 (Active Enchantments) [can run in parallel]
    ↓
Phase 5 (Commands)
    ↓
Phase 6 (Bootstrap)
    ↓
Phase 7 (Testing)
    ↓
Phase 8 (Documentation & Release)
```

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Freeze effect interferes with normal movement | Medium | High | Implement "look-around" exception; extensive manual testing |
| Chaos knockback doesn't work correctly | Low | Medium | Test knockback vector math; adjust if needed |
| Cooldown timing inaccurate | Low | Medium | Use System.currentTimeMillis(); add unit tests |
| Performance issues with many enchanted items | Low | Medium | Profile effect execution; use async patterns |
| Lore parsing breaks with edge cases | Medium | Medium | Add comprehensive unit tests for all lore formats |

---

## Notes for Copilot Implementation

When implementing the Custom Enchantments system, keep these guidelines in mind:

1. **Architecture Compliance**: Follow knk-plugin-v2 patterns from ARCHITECTURE_AUDIT.md
2. **No Bukkit in Core**: knk-core must have zero Bukkit imports
3. **Async Pattern**: Use CompletableFuture throughout; schedule Bukkit effects on main thread
4. **Threading**: All potion/particle effects on main thread via Bukkit scheduler
5. **Testing**: Write unit tests in knk-core; integration tests in knk-paper
6. **Configuration**: Use config.yml for messages and settings; no hardcoded strings
7. **API Canonical Model**: Treat `EnchantmentDefinition` + assignments as the source of truth; use lore only as runtime adapter.
8. **Logging**: Use plugin.getLogger() for debug/info messages

---

## Questions for Stakeholder

1. What exact API contract should represent `ItemBlueprint` ↔ custom ability assignments?
2. What exact API contract should represent user-instance skill assignments once skills are implemented?
3. Should we support enchanted armor with passive effects (beyond interact)?
4. Should enchanted weapons lose durability faster?
5. Should there be an in-game enchantment shop or only `/ce` commands?

